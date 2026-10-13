package com.moolsocial.app

import android.content.ContentValues
import android.content.Context
import android.app.Activity
import android.content.pm.PackageManager
import android.graphics.pdf.PdfRenderer
import android.os.Bundle
import android.os.CancellationSignal
import android.os.ParcelFileDescriptor
import android.print.PageRange
import android.print.PrintAttributes
import android.print.PrintDocumentAdapter
import android.print.PrintDocumentInfo
import android.print.PrintJob
import android.print.PrintJobInfo
import android.print.PrintManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.io.File
import java.io.FileOutputStream
import java.util.UUID
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

/** Saves only generated stock exports; never accepts a destination path or existing URI. */
class StoreStockDownloadBridge(context: Context, messenger: BinaryMessenger) {
    private val printer = StoreDocumentPrintBridge(context, messenger)
    private val resolver = context.applicationContext.contentResolver
    private val channel = MethodChannel(messenger, "com.moolsocial.app/store_stock_download")
    private val main = Handler(Looper.getMainLooper())
    private val io = Executors.newSingleThreadExecutor()
    private val busy = AtomicBoolean(false)
    private val closed = AtomicBoolean(false)

    init {
        channel.setMethodCallHandler { call, result ->
            if (call.method != "save") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val args = call.arguments as? Map<*, *>
            val name = args?.get("fileName") as? String
            val mime = args?.get("mimeType") as? String
            val bytes = args?.get("bytes") as? ByteArray
            if (args?.keys != setOf("fileName", "mimeType", "bytes") ||
                name == null || mime == null || bytes == null ||
                !validPayload(name, mime, bytes)
            ) {
                result.error("invalid_stock_export", "The stock file is invalid.", null)
            } else if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                // Do not silently substitute a picker or request broad storage access.
                result.error("stock_download_unsupported", "Direct downloads require Android 10 or later.", null)
            } else if (closed.get() || !busy.compareAndSet(false, true)) {
                result.error("stock_download_busy", "A stock download is already active.", null)
            } else {
                io.execute {
                    var uri: Uri? = null
                    var published = false
                    try {
                        check(!closed.get())
                        val uniqueName = name.substringBeforeLast('.') + "-" +
                            UUID.randomUUID().toString().take(8) + "." + name.substringAfterLast('.')
                        val values = ContentValues().apply {
                            put(MediaStore.Downloads.DISPLAY_NAME, uniqueName)
                            put(MediaStore.Downloads.MIME_TYPE, mime)
                            put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS + "/MoolSocial")
                            put(MediaStore.Downloads.IS_PENDING, 1)
                        }
                        val target = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                            ?: throw IOException("No download destination")
                        uri = target
                        val stream = resolver.openOutputStream(target, "w")
                            ?: throw IOException("Download stream unavailable")
                        stream.use { output ->
                            var offset = 0
                            while (offset < bytes.size) {
                                check(!closed.get())
                                val count = minOf(64 * 1024, bytes.size - offset)
                                output.write(bytes, offset, count)
                                offset += count
                            }
                            output.flush()
                        }
                        check(!closed.get())
                        val ready = ContentValues().apply { put(MediaStore.Downloads.IS_PENDING, 0) }
                        if (resolver.update(target, ready, null, null) != 1) {
                            throw IOException("Download not published")
                        }
                        published = true
                        main.post { busy.set(false); result.success(true) }
                    } catch (_: Exception) {
                        main.post {
                            busy.set(false)
                            result.error("stock_download_failed", "Could not save to Downloads. Please try again.", null)
                        }
                    } finally {
                        // Only remove the incomplete row created by this attempt.
                        if (!published && uri != null) {
                            runCatching { resolver.delete(uri!!, null, null) }
                        }
                    }
                }
            }
        }
    }

    fun close() {
        printer.close()
        closed.set(true)
        channel.setMethodCallHandler(null)
        io.shutdown()
    }

    companion object {
        fun validPayload(name: String, mime: String, bytes: ByteArray): Boolean {
            val commercePdf = Regex("""^commerce-document-[A-Za-z0-9-]{1,128}\.pdf$""").matches(name)
            val statement = Regex("""^(stock-ledger-[A-Za-z0-9_-]{1,128}-[0-9]{4}-[0-9]{2}-[0-9]{2}|customer-statement-[A-Za-z0-9_-]{1,128})\.(pdf|xlsx|csv)$""").matches(name)
            if ((!Regex("""^stock-snapshot-[0-9]{14,20}\.(pdf|xlsx|csv)$""").matches(name) &&
                name != "store-products-template.csv" && !commercePdf && !statement) ||
                ((commercePdf || (statement && name.endsWith(".pdf"))) && bytes.size > 10 * 1024 * 1024) ||
                bytes.size !in 1..(64 * 1024 * 1024)
            ) return false
            return when (name.substringAfterLast('.')) {
                "pdf" -> mime == "application/pdf" && bytes.size >= 5 &&
                    bytes.copyOfRange(0, 5).contentEquals("%PDF-".toByteArray(Charsets.US_ASCII))
                "xlsx" -> mime == "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" &&
                    bytes.size >= 4 && bytes[0] == 0x50.toByte() && bytes[1] == 0x4b.toByte()
                "csv" -> mime == "text/csv"
                else -> false
            }
        }
    }
}

/** Private document handoff only: no discovery sockets, URLs or external paths. */
private class StoreDocumentPrintBridge(
    private val context: Context,
    private val messenger: BinaryMessenger,
) {
    private val channel = MethodChannel(messenger, "com.moolsocial.app/store_document_print")
    private val main = Handler(Looper.getMainLooper())
    private val io = Executors.newSingleThreadExecutor()
    private var active: Job? = null
    @Volatile private var closed = false

    init {
        channel.setMethodCallHandler { call, result ->
            val args = call.arguments as? Map<*, *>
            if (call.method == "cancel") {
                if (args?.get("id") == active?.id) active?.cancel()
                result.success(null)
            } else if (call.method != "print") {
                result.notImplemented()
            } else if (closed || active != null || context !is Activity ||
                !context.packageManager.hasSystemFeature(PackageManager.FEATURE_PRINTING)) {
                result.error("print_unavailable", "Printing is unavailable.", null)
            } else {
                val id = args?.get("id") as? String
                val name = args?.get("name") as? String
                val width = (args?.get("width") as? Number)?.toDouble()
                val height = (args?.get("height") as? Number)?.toDouble()
                if (id == null || !Regex("store-print-[0-9]+-[0-9]+").matches(id) ||
                    name.isNullOrBlank() || name.length > 160 || name.any { it.code < 32 } ||
                    width == null || height == null || !width.isFinite() || !height.isFinite() ||
                    width !in 136.0..936.0 || height !in 283.0..2835.0) {
                    result.error("invalid_print_request", "Invalid print request.", null)
                } else {
                    val manager = context.getSystemService(Context.PRINT_SERVICE) as? PrintManager
                    if (manager == null) result.error("print_unavailable", "Printing is unavailable.", null)
                    else {
                        val job = Job(id, name, result)
                        active = job
                        try {
                            val media = PrintAttributes.MediaSize("store-paper", "Document paper",
                                (width * 1000 / 72).toInt(), (height * 1000 / 72).toInt())
                            job.native = manager.print(name, job, PrintAttributes.Builder().setMediaSize(media).build())
                        } catch (_: Exception) { job.finish("unavailable") }
                    }
                }
            }
        }
    }

    private inner class Job(val id: String, val name: String, val result: MethodChannel.Result) : PrintDocumentAdapter() {
        var native: PrintJob? = null
        private val requests = MethodChannel(messenger, "com.moolsocial.app/store_document_print/$id")
        private var done = false
        private var epoch = 0
        private var attributes: PrintAttributes? = null
        private var pageCount = 0

        fun finish(state: String) {
            if (done) return
            done = true
            epoch++
            if (active === this) active = null
            result.success(state)
        }
        fun cancel() { native?.cancel(); finish("cancelled") }

        private fun render(pages: List<Int>?, signal: CancellationSignal,
            success: (ByteArray, Int) -> Unit, failure: () -> Unit) {
            val attrs = attributes
            val size = attrs?.mediaSize
            val margins = attrs?.minMargins
            if (done || size == null || margins == null) { failure(); return }
            val generation = epoch
            requests.invokeMethod("render", mapOf(
                "id" to id, "width" to size.widthMils * 72.0 / 1000,
                "height" to size.heightMils * 72.0 / 1000,
                "left" to margins.leftMils * 72.0 / 1000,
                "top" to margins.topMils * 72.0 / 1000,
                "right" to margins.rightMils * 72.0 / 1000,
                "bottom" to margins.bottomMils * 72.0 / 1000, "pages" to pages,
            ), object : MethodChannel.Result {
                override fun success(value: Any?) {
                    if (done || closed || signal.isCanceled || epoch != generation) { failure(); return }
                    val bytes = value as? ByteArray
                    if (bytes == null || bytes.size !in 8..(10 * 1024 * 1024) ||
                        !bytes.copyOfRange(0, 5).contentEquals("%PDF-".toByteArray())) { failure(); return }
                    io.execute {
                        var file: File? = null
                        val count = try {
                            file = File.createTempFile("store-print-", ".pdf", context.cacheDir)
                            file.writeBytes(bytes)
                            ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY).use { fd ->
                                PdfRenderer(fd).use { it.pageCount }
                            }
                        } catch (_: Exception) { 0 } finally { file?.delete() }
                        main.post {
                            if (done || signal.isCanceled || epoch != generation || count !in 1..100) failure()
                            else success(bytes, count)
                        }
                    }
                }
                override fun error(code: String, message: String?, details: Any?) { failure() }
                override fun notImplemented() { failure() }
            })
        }

        override fun onLayout(old: PrintAttributes?, next: PrintAttributes,
            signal: CancellationSignal, callback: LayoutResultCallback, extras: Bundle?) {
            if (signal.isCanceled || done) { callback.onLayoutCancelled(); return }
            epoch++
            attributes = next
            render(null, signal, { _, count ->
                pageCount = count
                callback.onLayoutFinished(PrintDocumentInfo.Builder(name)
                    .setContentType(PrintDocumentInfo.CONTENT_TYPE_DOCUMENT).setPageCount(count).build(), old != next)
            }, {
                if (signal.isCanceled || done) callback.onLayoutCancelled()
                else callback.onLayoutFailed("Cannot prepare this paper size. Choose another size or retry.")
            })
        }

        override fun onWrite(ranges: Array<out PageRange>, destination: ParcelFileDescriptor,
            signal: CancellationSignal, callback: WriteResultCallback) {
            val selected = (0 until pageCount).filter { p -> ranges.any { p in it.start..it.end } }
            if (signal.isCanceled || done) { callback.onWriteCancelled(); return }
            if (selected.isEmpty()) { callback.onWriteFailed("Select at least one page."); return }
            render(selected, signal, { bytes, count ->
                if (count != selected.size) { callback.onWriteFailed("Selected pages could not be prepared."); return@render }
                io.execute {
                    val written = try {
                        FileOutputStream(destination.fileDescriptor).use { output ->
                            var offset = 0
                            while (offset < bytes.size) {
                                check(!signal.isCanceled && !closed)
                                val length = minOf(65536, bytes.size - offset)
                                output.write(bytes, offset, length)
                                offset += length
                            }
                            output.flush()
                        }; true
                    } catch (_: Exception) { false }
                    main.post {
                        if (signal.isCanceled || done) callback.onWriteCancelled()
                        else if (written) callback.onWriteFinished(selected.map { PageRange(it, it) }.toTypedArray())
                        else callback.onWriteFailed("The document could not be sent. Retry printing.")
                    }
                }
            }, {
                if (signal.isCanceled || done) callback.onWriteCancelled()
                else callback.onWriteFailed("The document could not be prepared. Retry printing.")
            })
        }

        override fun onFinish() {
            val state = native?.info?.state
            finish(when (state) {
                PrintJobInfo.STATE_COMPLETED -> "completed"
                PrintJobInfo.STATE_CANCELED -> "cancelled"
                PrintJobInfo.STATE_FAILED -> "failed"
                PrintJobInfo.STATE_BLOCKED -> "blocked"
                PrintJobInfo.STATE_QUEUED, PrintJobInfo.STATE_STARTED -> "submitted"
                else -> "unknown"
            })
        }
    }

    fun close() {
        closed = true
        active?.cancel()
        channel.setMethodCallHandler(null)
        io.shutdown()
    }
}
