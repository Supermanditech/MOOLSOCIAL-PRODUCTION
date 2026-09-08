package com.moolsocial.app

import android.app.Service
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.pdf.PdfRenderer
import android.os.Bundle
import android.os.Handler
import android.os.HandlerThread
import android.os.IBinder
import android.os.Message
import android.os.Messenger
import android.os.ParcelFileDescriptor
import android.os.Process
import kotlin.math.min
import kotlin.math.sqrt

/** Parses only explicitly supplied document descriptors in a permission-free process. */
class WorkDocumentRenderService : Service() {
    private lateinit var worker: HandlerThread
    private lateinit var endpoint: Messenger

    override fun onCreate() {
        super.onCreate()
        worker = HandlerThread("work-document-page").also { it.start() }
        endpoint = Messenger(Handler(worker.looper) { message ->
            render(message)
            true
        })
    }

    override fun onBind(intent: Intent): IBinder = endpoint.binder

    @Suppress("DEPRECATION")
    private fun render(message: Message) {
        val data = message.data
        val input = data.getParcelable<ParcelFileDescriptor>("input")
        val output = data.getParcelable<ParcelFileDescriptor>("output")
        val response = Bundle()
        try {
            require(message.what == 1 && input != null && output != null)
            require(input.statSize in 1..(10L * 1024 * 1024))
            val index = data.getInt("page", -1)
            val requestedWidth = data.getInt("width", 0)
            require(index in 0..499 && requestedWidth in 256..1280)
            PdfRenderer(input).use { document ->
                require(document.pageCount in 1..500 && index < document.pageCount)
                document.openPage(index).use { page ->
                    require(page.width > 0 && page.height > 0)
                    val aspect = page.height.toDouble() / page.width
                    val width = min(
                        requestedWidth.toDouble(),
                        min(2048.0 / aspect, sqrt(2_000_000.0 / aspect)),
                    ).toInt().coerceAtLeast(1)
                    val height = (width * aspect).toInt().coerceIn(1, 2048)
                    val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                    try {
                        bitmap.eraseColor(Color.WHITE)
                        page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                        val png = WorkDocumentPageFrame.encode { stream ->
                            check(bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream))
                        }
                        ParcelFileDescriptor.AutoCloseOutputStream(output).use { stream ->
                            WorkDocumentPageFrame.write(stream, png)
                        }
                        response.putInt("page", index)
                        response.putInt("pages", document.pageCount)
                        response.putInt("width", width)
                        response.putInt("height", height)
                    } finally {
                        bitmap.recycle()
                    }
                }
            }
        } catch (_: SecurityException) {
            response.putString("error", "protected_pdf")
        } catch (_: Exception) {
            response.putString("error", "invalid_pdf")
        } catch (_: OutOfMemoryError) {
            response.putString("error", "preview_unavailable")
        } finally {
            runCatching { input?.close() }
            runCatching { output?.close() }
        }
        runCatching {
            message.replyTo?.send(Message.obtain(null, 1).apply { this.data = response })
        }
    }

    override fun onDestroy() {
        worker.quitSafely()
        super.onDestroy()
        // The dedicated isolated worker must not retain a hung or malicious parser.
        if (Process.myUid() != applicationInfo.uid) Process.killProcess(Process.myPid())
    }
}
