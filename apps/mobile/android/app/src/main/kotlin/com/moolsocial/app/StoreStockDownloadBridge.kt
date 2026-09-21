package com.moolsocial.app

import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.util.UUID
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

/** Saves only generated stock exports; never accepts a destination path or existing URI. */
class StoreStockDownloadBridge(context: Context, messenger: BinaryMessenger) {
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
        closed.set(true)
        channel.setMethodCallHandler(null)
        io.shutdown()
    }

    companion object {
        fun validPayload(name: String, mime: String, bytes: ByteArray): Boolean {
            if ((!Regex("""^stock-snapshot-[0-9]{14,20}\.(pdf|xlsx|csv)$""").matches(name) &&
                name != "store-products-template.csv") ||
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
