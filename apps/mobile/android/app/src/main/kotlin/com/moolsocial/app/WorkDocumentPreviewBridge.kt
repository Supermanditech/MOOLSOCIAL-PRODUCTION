package com.moolsocial.app

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.Message
import android.os.Messenger
import android.os.ParcelFileDescriptor
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.concurrent.Executors

/** Local, single-page bridge. File names, paths, URLs and credentials are never accepted. */
class WorkDocumentPreviewBridge(
    private val context: Context,
    messenger: BinaryMessenger,
) {
    private val main = Handler(Looper.getMainLooper())
    private val io = Executors.newSingleThreadExecutor()
    private val channel = MethodChannel(messenger, "com.moolsocial.app/work_document_preview")
    private var active: Request? = null
    private var closed = false

    private class Descriptors(
        val input: ParcelFileDescriptor,
        val output: ParcelFileDescriptor,
        val reader: ParcelFileDescriptor,
    ) {
        fun close() {
            runCatching { input.close() }
            runCatching { output.close() }
            runCatching { reader.close() }
        }
    }

    private inner class Request(
        val id: String,
        val page: Int,
        val width: Int,
        val result: MethodChannel.Result,
    ) {
        var files: Descriptors? = null
        var connection: ServiceConnection? = null
        var bound = false
        var finished = false
        var metadata: Map<String, Int>? = null
        var renderedBytes: ByteArray? = null
        var outputFailed = false
        val timeout = Runnable { finish(this, "preview_timeout") }
    }

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "renderPage" -> {
                    val args = call.arguments as? Map<*, *>
                    val bytes = args?.get("bytes") as? ByteArray
                    val page = args?.get("page") as? Int
                    val width = args?.get("width") as? Int
                    val id = args?.get("requestId") as? String
                    if (closed || bytes == null || bytes.size !in 5..MAX_BYTES ||
                        !bytes.copyOfRange(0, 5).contentEquals("%PDF-".toByteArray(Charsets.US_ASCII)) ||
                        page == null || page !in 0..499 || width == null || width !in 256..1280 ||
                        id == null || !Regex("^[A-Za-z0-9_-]{1,80}$").matches(id)
                    ) {
                        result.error("invalid_pdf", "This PDF could not be opened.", null)
                    } else if (active != null) {
                        result.error("preview_busy", "A document page is still opening.", null)
                    } else {
                        val request = Request(id, page, width, result)
                        active = request
                        main.postDelayed(request.timeout, 20_000)
                        prepare(request, bytes)
                    }
                }
                "cancel" -> {
                    val request = active
                    if (request != null && (call.arguments as? Map<*, *>)?.get("requestId") == request.id) {
                        finish(request, "preview_cancelled")
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun prepare(request: Request, bytes: ByteArray) {
        io.execute {
            var inputFile: File? = null
            var input: ParcelFileDescriptor? = null
            var output: ParcelFileDescriptor? = null
            var reader: ParcelFileDescriptor? = null
            try {
                inputFile = File.createTempFile("work-preview-input-", ".bin", context.cacheDir)
                inputFile.outputStream().use { it.write(bytes) }
                input = ParcelFileDescriptor.open(inputFile, ParcelFileDescriptor.MODE_READ_ONLY)
                check(inputFile.delete())
                val pipe = ParcelFileDescriptor.createPipe()
                reader = pipe[0]
                output = pipe[1]
                val descriptors = Descriptors(input, output, reader)
                main.post {
                    if (active !== request || request.finished || closed) {
                        descriptors.close()
                    } else {
                        request.files = descriptors
                        readOutput(request, descriptors.reader)
                        bind(request)
                    }
                }
            } catch (_: Exception) {
                runCatching { input?.close() }
                runCatching { output?.close() }
                runCatching { reader?.close() }
                main.post { finish(request, "preview_unavailable") }
            } finally {
                // Only this request's private temporary files; never source documents.
                inputFile?.delete()
            }
        }
    }

    private fun bind(request: Request) {
        val receiver = Messenger(Handler(Looper.getMainLooper()) { message ->
            if (active === request && !request.finished) receive(request, message.data)
            true
        })
        val connection = object : ServiceConnection {
            override fun onServiceConnected(name: ComponentName, service: IBinder) {
                if (active !== request || request.finished) return
                try {
                    Messenger(service).send(Message.obtain(null, 1).apply {
                        replyTo = receiver
                        data = Bundle().apply {
                            putParcelable("input", request.files!!.input)
                            putParcelable("output", request.files!!.output)
                            putInt("page", request.page)
                            putInt("width", request.width)
                        }
                    })
                    request.files?.input?.close()
                    request.files?.output?.close()
                } catch (_: Exception) {
                    finish(request, "preview_unavailable")
                }
            }

            override fun onServiceDisconnected(name: ComponentName) {
                finish(request, "preview_unavailable")
            }

            override fun onBindingDied(name: ComponentName) {
                finish(request, "preview_unavailable")
            }

            override fun onNullBinding(name: ComponentName) {
                finish(request, "preview_unavailable")
            }
        }
        request.connection = connection
        try {
            request.bound = context.bindService(
                Intent(context, WorkDocumentRenderService::class.java),
                connection,
                Context.BIND_AUTO_CREATE,
            )
            if (!request.bound) finish(request, "preview_unavailable")
        } catch (_: Exception) {
            finish(request, "preview_unavailable")
        }
    }

    private fun receive(request: Request, data: Bundle) {
        val error = data.getString("error")
        if (error != null) {
            finish(request, if (error == "protected_pdf") error else "invalid_pdf")
            return
        }
        val page = data.getInt("page", -1)
        val count = data.getInt("pages", 0)
        val width = data.getInt("width", 0)
        val height = data.getInt("height", 0)
        if (page != request.page || count !in 1..500 || page >= count ||
            width !in 1..1280 || height !in 1..2048 || width.toLong() * height > 2_000_000
        ) {
            finish(request, "invalid_pdf")
            return
        }
        request.metadata = mapOf("page" to page, "pages" to count, "width" to width, "height" to height)
        completeIfReady(request)
    }

    private fun readOutput(request: Request, descriptor: ParcelFileDescriptor) {
        io.execute {
            try {
                val bytes = ParcelFileDescriptor.AutoCloseInputStream(descriptor).use { stream ->
                    val buffer = ByteArray(32 * 1024)
                    val collected = ByteArrayOutputStream()
                    while (true) {
                        val read = stream.read(buffer)
                        if (read < 0) break
                        check(collected.size() + read <= MAX_BYTES)
                        collected.write(buffer, 0, read)
                    }
                    collected.toByteArray()
                }
                check(bytes.size >= 24 && bytes.copyOfRange(0, 8).contentEquals(PNG_HEADER))
                main.post {
                    if (active === request && !request.finished) {
                        request.renderedBytes = bytes
                        completeIfReady(request)
                    }
                }
            } catch (_: Exception) {
                main.post {
                    if (active === request && !request.finished) {
                        request.outputFailed = true
                        completeIfReady(request)
                    }
                }
            }
        }
    }

    private fun completeIfReady(request: Request) {
        if (active !== request || request.finished) return
        val metadata = request.metadata ?: return
        if (request.outputFailed) {
            finish(request, "invalid_pdf")
            return
        }
        val bytes = request.renderedBytes ?: return
        fun dimension(offset: Int): Int =
            ((bytes[offset].toInt() and 255) shl 24) or
                ((bytes[offset + 1].toInt() and 255) shl 16) or
                ((bytes[offset + 2].toInt() and 255) shl 8) or
                (bytes[offset + 3].toInt() and 255)
        if (dimension(16) != metadata["width"] || dimension(20) != metadata["height"]) {
            finish(request, "invalid_pdf")
            return
        }
        cleanup(request)
        request.result.success(metadata + mapOf("bytes" to bytes))
    }

    private fun finish(request: Request, code: String) {
        if (request.finished || active !== request) return
        cleanup(request)
        request.result.error(code, "The PDF page could not be opened.", null)
    }

    private fun cleanup(request: Request) {
        request.finished = true
        main.removeCallbacks(request.timeout)
        if (active === request) active = null
        if (request.bound) {
            request.bound = false
            request.connection?.let { runCatching { context.unbindService(it) } }
        }
        request.files?.close()
        request.files = null
        request.renderedBytes = null
        request.metadata = null
    }

    fun close() {
        closed = true
        active?.let { finish(it, "preview_cancelled") }
        channel.setMethodCallHandler(null)
        io.shutdown()
    }

    companion object {
        private const val MAX_BYTES = 10 * 1024 * 1024
        private val PNG_HEADER = byteArrayOf(137.toByte(), 80, 78, 71, 13, 10, 26, 10)
    }
}
