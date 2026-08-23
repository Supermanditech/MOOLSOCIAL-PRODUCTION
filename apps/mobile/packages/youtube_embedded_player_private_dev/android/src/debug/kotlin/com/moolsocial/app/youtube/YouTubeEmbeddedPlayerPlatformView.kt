package com.moolsocial.app.youtube

import android.annotation.SuppressLint
import android.annotation.TargetApi
import android.app.Activity
import android.app.Dialog
import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import android.content.pm.ActivityInfo
import android.graphics.Color
import android.net.Uri
import android.net.http.SslError
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Base64
import android.view.View
import android.view.ViewGroup
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.WindowManager
import android.webkit.GeolocationPermissions
import android.webkit.PermissionRequest
import android.webkit.RenderProcessGoneDetail
import android.webkit.SafeBrowsingResponse
import android.webkit.SslErrorHandler
import android.webkit.WebChromeClient
import android.webkit.WebMessage
import android.webkit.WebMessagePort
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.FrameLayout
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import com.moolsocial.youtube_embedded_player_private_dev.BuildConfig
import org.json.JSONObject
import java.nio.charset.StandardCharsets
import java.security.MessageDigest
import java.security.SecureRandom

class YouTubeEmbeddedPlayerPlatformView(
    private val context: Context,
    viewId: Int,
    messenger: BinaryMessenger,
) : PlatformView, MethodChannel.MethodCallHandler {
    private val root = FrameLayout(context).apply {
        setBackgroundColor(Color.BLACK)
    }
    private val channel = MethodChannel(
        messenger,
        "${YouTubeEmbeddedPlayerPlatformViewFactory.VIEW_TYPE}/$viewId",
    )
    private val mainHandler = Handler(Looper.getMainLooper())
    private val secureRandom = SecureRandom()

    private var webView: WebView? = null
    private var nativePort: WebMessagePort? = null
    private var portTransferred = false
    private var bootstrapLoadPending = false
    private var disposed = false
    private var connectionNonce: String? = null
    private var readyTimeout: Runnable? = null
    private var fullscreenDialog: Dialog? = null
    private var fullscreenCallback: WebChromeClient.CustomViewCallback? = null
    private var fullscreenActivity: Activity? = null
    private var previousRequestedOrientation: Int? = null

    init {
        channel.setMethodCallHandler(this)
    }

    override fun getView(): View = root

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (disposed) {
            result.error("disposed", "The provider player view is disposed.", null)
            return
        }
        when (call.method) {
            "mount" -> mount(call.arguments, result)
            "send" -> send(call.arguments, result)
            "detach" -> {
                if (call.arguments != null) {
                    result.error("invalid_detach", "Detach accepts no payload.", null)
                    return
                }
                destroyCurrentWebView()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    @SuppressLint("SetJavaScriptEnabled")
    private fun mount(arguments: Any?, result: MethodChannel.Result) {
        val values = arguments as? Map<*, *> ?: run {
            result.error("invalid_mount", "Mount payload is invalid.", null)
            return
        }
        if (values.keys != MOUNT_KEYS) {
            result.error("invalid_mount", "Mount payload keys are invalid.", null)
            return
        }
        val template = values["bootstrapHtml"] as? String
        val baseUrl = values["baseUrl"] as? String
        val width = (values["width"] as? Number)?.toDouble()
        val height = (values["height"] as? Number)?.toDouble()
        val aspect = values["aspect"] as? String
        if (
            template == null ||
            baseUrl != PLAYER_BASE_URL ||
            width == null ||
            height == null ||
            !width.isFinite() ||
            !height.isFinite() ||
            width < MINIMUM_PLAYER_DIMENSION ||
            height < MINIMUM_PLAYER_DIMENSION ||
            aspect !in PLAYER_ASPECTS
        ) {
            result.error("invalid_mount", "Mount payload values are invalid.", null)
            return
        }
        if (sha256(template) != EXPECTED_BOOTSTRAP_SHA256) {
            result.error("bootstrap_mismatch", "The player bootstrap is not approved.", null)
            return
        }
        if (
            template.indexOf(NONCE_MARKER) < 0 ||
            template.indexOf(NONCE_MARKER) != template.lastIndexOf(NONCE_MARKER)
        ) {
            result.error("bootstrap_nonce", "The player bootstrap nonce marker is invalid.", null)
            return
        }

        destroyCurrentWebView()
        val nonceBytes = ByteArray(32)
        secureRandom.nextBytes(nonceBytes)
        val nonce = Base64.encodeToString(
            nonceBytes,
            Base64.URL_SAFE or Base64.NO_WRAP or Base64.NO_PADDING,
        )
        check(NONCE_PATTERN.matches(nonce))
        connectionNonce = nonce
        val html = template.replace(NONCE_MARKER, nonce)

        val playerWebView = WebView(context)
        webView = playerWebView
        bootstrapLoadPending = true
        WebView.setWebContentsDebuggingEnabled(BuildConfig.DEBUG)
        playerWebView.setBackgroundColor(Color.BLACK)
        playerWebView.isHorizontalScrollBarEnabled = false
        playerWebView.isVerticalScrollBarEnabled = false
        with(playerWebView.settings) {
            javaScriptEnabled = true
            domStorageEnabled = true
            allowFileAccess = false
            allowContentAccess = false
            javaScriptCanOpenWindowsAutomatically = false
            setSupportMultipleWindows(false)
            mixedContentMode = WebSettings.MIXED_CONTENT_NEVER_ALLOW
            mediaPlaybackRequiresUserGesture = true
            builtInZoomControls = false
            displayZoomControls = false
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                safeBrowsingEnabled = true
            }
        }
        playerWebView.webChromeClient = ProviderWebChromeClient()
        playerWebView.webViewClient = ProviderWebViewClient()
        root.addView(
            playerWebView,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT,
            ),
        )
        playerWebView.loadDataWithBaseURL(
            PLAYER_BASE_URL,
            html,
            "text/html",
            "UTF-8",
            PLAYER_BASE_URL,
        )
        result.success(null)
    }

    private fun send(arguments: Any?, result: MethodChannel.Result) {
        val values = arguments as? Map<*, *> ?: run {
            result.error("invalid_command", "Command payload is invalid.", null)
            return
        }
        if (values.keys != SEND_KEYS) {
            result.error("invalid_command", "Command payload keys are invalid.", null)
            return
        }
        val message = values["message"] as? String
        if (
            message == null ||
            message.toByteArray(StandardCharsets.UTF_8).size > MAXIMUM_MESSAGE_BYTES ||
            !isValidCommand(message)
        ) {
            result.error("invalid_command", "Player command is invalid.", null)
            return
        }
        val port = nativePort
        if (port == null || !portTransferred) {
            result.error("port_unavailable", "The player port is unavailable.", null)
            return
        }
        try {
            port.postMessage(WebMessage(message))
            result.success(null)
        } catch (_: IllegalStateException) {
            result.error("port_closed", "The player port is closed.", null)
        }
    }

    private fun transferPort(playerWebView: WebView) {
        if (
            portTransferred ||
            !bootstrapLoadPending ||
            playerWebView !== webView
        ) {
            return
        }
        bootstrapLoadPending = false
        val nonce = connectionNonce ?: return
        val ports = try {
            playerWebView.createWebMessageChannel()
        } catch (_: RuntimeException) {
            failAndDetach(
                playerWebView,
                code = "port_creation_failed",
                message = "The provider player connection could not be created.",
            )
            return
        }
        val applicationPort = ports[0]
        applicationPort.setWebMessageCallback(
            object : WebMessagePort.WebMessageCallback() {
                override fun onMessage(port: WebMessagePort, message: WebMessage) {
                    if (playerWebView !== webView) return
                    val transferred = message.ports
                    val data = message.data
                    if (
                        !transferred.isNullOrEmpty() ||
                        data == null ||
                        data.toByteArray(StandardCharsets.UTF_8).size >
                        MAXIMUM_MESSAGE_BYTES ||
                        !isValidEvent(data)
                    ) {
                        failAndDetach(
                            playerWebView,
                            code = "invalid_bridge_event",
                            message = "The provider player returned an invalid event.",
                        )
                        return
                    }
                    if (JSONObject(data).getString("type") == "ready") {
                        cancelReadyTimeout()
                    }
                    channel.invokeMethod("playerEvent", data)
                }
            },
            mainHandler,
        )
        nativePort = applicationPort
        val connection = JSONObject()
            .put("version", 1)
            .put("kind", "connect")
            .put("type", "playerPort")
            .put("payload", JSONObject().put("nonce", nonce))
            .toString()
        portTransferred = true
        scheduleReadyTimeout(playerWebView)
        try {
            playerWebView.postWebMessage(
                WebMessage(connection, arrayOf(ports[1])),
                PLAYER_ORIGIN_URI,
            )
        } catch (_: RuntimeException) {
            try {
                applicationPort.close()
                ports[1].close()
            } catch (_: IllegalStateException) {
                // No endpoint remains available after a failed transfer.
            }
            nativePort = null
            portTransferred = false
            cancelReadyTimeout()
            failAndDetach(
                playerWebView,
                code = "port_transfer_failed",
                message = "The provider player connection could not be transferred.",
            )
            return
        }
    }

    private inner class ProviderWebViewClient : WebViewClient() {
        override fun shouldOverrideUrlLoading(
            view: WebView,
            request: WebResourceRequest,
        ): Boolean {
            if (!request.isForMainFrame) return false
            if (
                request.hasGesture() &&
                request.url.scheme.equals("https", ignoreCase = true)
            ) {
                openExternal(request.url)
            }
            return true
        }

        override fun onPageFinished(view: WebView, url: String?) {
            if (view !== webView || !bootstrapLoadPending) return
            if (url == null || !isPlayerDocument(Uri.parse(url))) {
                failAndDetach(
                    view,
                    code = "unexpected_main_document",
                    message = "The provider player document was rejected.",
                )
                return
            }
            transferPort(view)
        }

        override fun onReceivedError(
            view: WebView,
            request: WebResourceRequest,
            error: WebResourceError,
        ) {
            if (view === webView && request.isForMainFrame) {
                failAndDetach(
                    view,
                    code = "main_frame_error",
                    message = "The provider player could not load.",
                )
            }
        }

        override fun onReceivedSslError(
            view: WebView,
            handler: SslErrorHandler,
            error: SslError,
        ) {
            handler.cancel()
            if (view === webView) {
                failAndDetach(
                    view,
                    code = "ssl_error",
                    message = "The provider player connection was rejected.",
                )
            }
        }

        @TargetApi(Build.VERSION_CODES.O_MR1)
        override fun onSafeBrowsingHit(
            view: WebView,
            request: WebResourceRequest,
            threatType: Int,
            callback: SafeBrowsingResponse,
        ) {
            callback.backToSafety(true)
            if (view === webView) {
                failAndDetach(
                    view,
                    code = "safe_browsing",
                    message = "The provider player request was rejected.",
                )
            }
        }

        @TargetApi(Build.VERSION_CODES.O)
        override fun onRenderProcessGone(
            view: WebView,
            detail: RenderProcessGoneDetail,
        ): Boolean {
            if (view === webView) {
                destroyCurrentWebView(rendererGone = true)
                channel.invokeMethod(
                    "platformFailure",
                    mapOf(
                        "code" to "render_process_gone",
                        "message" to "The provider player stopped.",
                    ),
                )
            }
            return true
        }
    }

    private inner class ProviderWebChromeClient : WebChromeClient() {
        override fun onShowCustomView(
            view: View,
            callback: WebChromeClient.CustomViewCallback,
        ) {
            showProviderFullscreen(view, callback)
        }

        @Suppress("DEPRECATION")
        override fun onShowCustomView(
            view: View,
            requestedOrientation: Int,
            callback: WebChromeClient.CustomViewCallback,
        ) {
            showProviderFullscreen(view, callback, requestedOrientation)
        }

        override fun onHideCustomView() {
            hideProviderFullscreen()
        }

        override fun onPermissionRequest(request: PermissionRequest) {
            request.deny()
        }

        override fun onGeolocationPermissionsShowPrompt(
            origin: String,
            callback: GeolocationPermissions.Callback,
        ) {
            callback.invoke(origin, false, false)
        }
    }

    @Suppress("DEPRECATION")
    private fun showProviderFullscreen(
        view: View,
        callback: WebChromeClient.CustomViewCallback,
        requestedOrientation: Int? = null,
    ) {
        if (disposed || fullscreenDialog != null || view.parent != null) {
            callback.onCustomViewHidden()
            return
        }
        val activity = context.findActivity()
        if (activity == null || activity.isFinishing || activity.isDestroyed) {
            callback.onCustomViewHidden()
            return
        }

        val dialog = Dialog(
            activity,
            android.R.style.Theme_Black_NoTitleBar_Fullscreen,
        )
        dialog.setCancelable(true)
        dialog.setContentView(
            view,
            ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            ),
        )
        dialog.setOnCancelListener { hideProviderFullscreen() }
        dialog.setOnDismissListener {
            if (fullscreenDialog === dialog) hideProviderFullscreen()
        }
        dialog.window?.apply {
            setBackgroundDrawableResource(android.R.color.black)
            setFlags(
                WindowManager.LayoutParams.FLAG_FULLSCREEN,
                WindowManager.LayoutParams.FLAG_FULLSCREEN,
            )
            setLayout(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
            )
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                insetsController?.apply {
                    systemBarsBehavior =
                        WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
                    hide(WindowInsets.Type.systemBars())
                }
            } else {
                decorView.systemUiVisibility =
                    View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
                    View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                    View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
                    View.SYSTEM_UI_FLAG_FULLSCREEN or
                    View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
                    View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
            }
        }

        fullscreenDialog = dialog
        fullscreenCallback = callback
        fullscreenActivity = activity
        previousRequestedOrientation = activity.requestedOrientation
        if (
            requestedOrientation != null &&
            requestedOrientation != ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED
        ) {
            activity.requestedOrientation = requestedOrientation
        }
        root.visibility = View.INVISIBLE
        try {
            dialog.show()
            dialog.window?.apply {
                setLayout(
                    WindowManager.LayoutParams.MATCH_PARENT,
                    WindowManager.LayoutParams.MATCH_PARENT,
                )
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    insetsController?.apply {
                        systemBarsBehavior =
                            WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
                        hide(WindowInsets.Type.systemBars())
                    }
                }
            }
        } catch (_: RuntimeException) {
            hideProviderFullscreen()
        }
    }

    private fun hideProviderFullscreen() {
        val dialog = fullscreenDialog ?: return
        val callback = fullscreenCallback
        val activity = fullscreenActivity
        val priorOrientation = previousRequestedOrientation
        fullscreenDialog = null
        fullscreenCallback = null
        fullscreenActivity = null
        previousRequestedOrientation = null

        dialog.setOnCancelListener(null)
        dialog.setOnDismissListener(null)
        try {
            if (dialog.isShowing) dialog.dismiss()
        } catch (_: RuntimeException) {
            // The Activity window is already gone; native state still clears below.
        }
        if (
            activity != null &&
            priorOrientation != null &&
            !activity.isFinishing &&
            !activity.isDestroyed &&
            activity.requestedOrientation != priorOrientation
        ) {
            activity.requestedOrientation = priorOrientation
        }
        root.visibility = View.VISIBLE
        try {
            callback?.onCustomViewHidden()
        } catch (_: RuntimeException) {
            // The provider already released its custom view.
        }
    }

    private fun Context.findActivity(): Activity? {
        var current: Context? = this
        while (current != null) {
            when (current) {
                is Activity -> return current
                is ContextWrapper -> {
                    val base = current.baseContext
                    current = if (base === current) null else base
                }
                else -> current = null
            }
        }
        return null
    }

    private fun openExternal(uri: Uri) {
        try {
            val intent = Intent(Intent.ACTION_VIEW, uri)
            if (context !is Activity) {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
        } catch (_: Exception) {
            channel.invokeMethod(
                "platformFailure",
                mapOf(
                    "code" to "external_handoff_unavailable",
                    "message" to "The provider destination is unavailable.",
                ),
            )
        }
    }

    private fun failAndDetach(
        expectedWebView: WebView,
        code: String,
        message: String,
    ) {
        if (disposed) return
        mainHandler.post {
            if (disposed || expectedWebView !== webView) return@post
            destroyCurrentWebView()
            channel.invokeMethod(
                "platformFailure",
                mapOf("code" to code, "message" to message),
            )
        }
    }

    private fun scheduleReadyTimeout(expectedWebView: WebView) {
        cancelReadyTimeout()
        val timeout = Runnable {
            failAndDetach(
                expectedWebView,
                code = "ready_timeout",
                message = "The provider player did not become ready.",
            )
        }
        readyTimeout = timeout
        mainHandler.postDelayed(timeout, READY_TIMEOUT_MILLIS)
    }

    private fun cancelReadyTimeout() {
        readyTimeout?.let { mainHandler.removeCallbacks(it) }
        readyTimeout = null
    }

    private fun destroyCurrentWebView(rendererGone: Boolean = false) {
        hideProviderFullscreen()
        cancelReadyTimeout()
        connectionNonce = null
        portTransferred = false
        bootstrapLoadPending = false
        try {
            nativePort?.close()
        } catch (_: IllegalStateException) {
            // A transferred or already closed endpoint needs no further work.
        }
        nativePort = null
        val current = webView ?: return
        webView = null
        root.removeView(current)
        if (!rendererGone) {
            current.stopLoading()
            current.webChromeClient = WebChromeClient()
            current.webViewClient = WebViewClient()
        }
        current.destroy()
    }

    override fun dispose() {
        if (disposed) return
        disposed = true
        channel.setMethodCallHandler(null)
        destroyCurrentWebView()
    }

    companion object {
        private const val PLAYER_BASE_URL = "https://com.moolsocial.app/"
        private val PLAYER_ORIGIN_URI = Uri.parse("https://com.moolsocial.app")
        private const val NONCE_MARKER = "__MOOLSOCIAL_NATIVE_PORT_NONCE__"
        private val NONCE_PATTERN = Regex("^[A-Za-z0-9_-]{43}$")
        private const val EXPECTED_BOOTSTRAP_SHA256 =
            "F63983016541BF07FD5390EACB34B8CCA7B6A564957DCD647A643689B27D0FBB"
        private const val MINIMUM_PLAYER_DIMENSION = 200.0
        private const val MAXIMUM_MESSAGE_BYTES = 8192
        private const val READY_TIMEOUT_MILLIS = 15_000L
        private val MOUNT_KEYS = setOf(
            "bootstrapHtml",
            "baseUrl",
            "width",
            "height",
            "aspect",
        )
        private val SEND_KEYS = setOf("message")
        private val PLAYER_ASPECTS = setOf("standardVideo", "verifiedVerticalShort")
        private val EMPTY_PAYLOAD_COMMANDS = setOf(
            "play",
            "pause",
            "stop",
            "next",
            "previous",
            "mute",
            "unmute",
            "reloadCaptions",
            "requestCaptionOptions",
            "requestState",
            "requestSpherical",
            "dispose",
        )
        private val PLAYER_STATES = setOf(-1, 0, 1, 2, 3, 5)

        private fun sha256(value: String): String = MessageDigest
            .getInstance("SHA-256")
            .digest(value.toByteArray(StandardCharsets.UTF_8))
            .joinToString("") { byte -> "%02X".format(byte) }

        private fun isPlayerDocument(uri: Uri): Boolean =
            uri.scheme.equals("https", ignoreCase = true) &&
                uri.host.equals("com.moolsocial.app", ignoreCase = true) &&
                uri.port == -1 &&
                (uri.path.isNullOrEmpty() || uri.path == "/") &&
                uri.query == null &&
                uri.fragment == null

        private fun hasExactKeys(value: JSONObject, expected: Set<String>): Boolean {
            val keys = buildSet {
                val iterator = value.keys()
                while (iterator.hasNext()) add(iterator.next())
            }
            return keys == expected
        }

        private fun isEnvelope(
            value: JSONObject,
            kind: String,
        ): Boolean =
            hasExactKeys(value, setOf("version", "kind", "type", "payload")) &&
                value.optInt("version", -1) == 1 &&
                value.optString("kind", "") == kind &&
                value.opt("type") is String &&
                value.opt("payload") is JSONObject

        private fun isValidCommand(raw: String): Boolean = try {
            val value = JSONObject(raw)
            if (!isEnvelope(value, "command")) return false
            val type = value.getString("type")
            val payload = value.getJSONObject("payload")
            when (type) {
                in EMPTY_PAYLOAD_COMMANDS -> hasExactKeys(payload, emptySet())
                "cue", "load" ->
                    isValidVideoLoadPayload(payload)
                "cuePlaylist", "loadPlaylist" ->
                    isValidPlaylistPayload(payload)
                "seek" -> {
                    if (!hasExactKeys(payload, setOf("seconds"))) return false
                    val seconds = payload.opt("seconds") as? Number ?: return false
                    seconds.toDouble().isFinite() && seconds.toDouble() >= 0
                }
                "playAt" ->
                    hasExactKeys(payload, setOf("index")) &&
                        payload.opt("index") is Int &&
                        payload.getInt("index") in 0..99
                "setVolume" ->
                    hasExactKeys(payload, setOf("volume")) &&
                        payload.opt("volume") is Int &&
                        payload.getInt("volume") in 0..100
                "setPlaybackRate" -> {
                    if (!hasExactKeys(payload, setOf("playbackRate"))) {
                        return false
                    }
                    val rate = payload.opt("playbackRate") as? Number ?: return false
                    rate.toDouble().isFinite() &&
                        rate.toDouble() in 0.25..4.0
                }
                "setLoop", "setShuffle" ->
                    hasExactKeys(payload, setOf("enabled")) &&
                        payload.opt("enabled") is Boolean
                "setCaptionFontSize" ->
                    hasExactKeys(payload, setOf("fontSize")) &&
                        payload.opt("fontSize") is Int &&
                        payload.getInt("fontSize") in -1..3
                "setSpherical" ->
                    isValidSphericalPayload(payload)
                else -> false
            }
        } catch (_: Exception) {
            false
        }

        private fun isValidEvent(raw: String): Boolean = try {
            val value = JSONObject(raw)
            if (!isEnvelope(value, "event")) return false
            val type = value.getString("type")
            val payload = value.getJSONObject("payload")
            when (type) {
                "ready", "autoplayBlocked" -> hasExactKeys(payload, emptySet())
                "apiChanged" -> hasExactKeys(payload, emptySet())
                "state" ->
                    hasExactKeys(payload, setOf("code")) &&
                        payload.opt("code") is Int &&
                        payload.getInt("code") in PLAYER_STATES
                "error" ->
                    hasExactKeys(payload, setOf("code")) &&
                        payload.opt("code") is Int &&
                        payload.getInt("code") >= 0
                "playbackQualityChanged" ->
                    hasExactKeys(payload, setOf("quality")) &&
                        PLAYBACK_QUALITY_PATTERN.matches(
                            payload.optString("quality", ""),
                        )
                "playbackRateChanged" -> {
                    if (!hasExactKeys(payload, setOf("playbackRate"))) {
                        return false
                    }
                    val rate = payload.opt("playbackRate") as? Number ?: return false
                    rate.toDouble().isFinite() &&
                        rate.toDouble() in 0.25..4.0
                }
                "stateSnapshot" -> isValidStateSnapshot(payload)
                "captionOptionsSnapshot" -> isValidCaptionOptionsSnapshot(payload)
                "sphericalSnapshot" -> isValidSphericalPayload(payload)
                else -> false
            }
        } catch (_: Exception) {
            false
        }

        private val VIDEO_ID_PATTERN = Regex("^[A-Za-z0-9_-]{11}$")
        private val CAPTION_OPTION_PATTERN =
            Regex("^[A-Za-z][A-Za-z0-9_]{0,39}$")
        private val PLAYLIST_ID_PATTERN = Regex("^[A-Za-z0-9_-]{10,80}$")
        private val PLAYBACK_QUALITY_PATTERN =
            Regex("^(?:small|medium|large|hd720|hd1080|highres|default|auto)$")

        private fun isValidPlaylistPayload(payload: JSONObject): Boolean {
            val optionalStart = if (payload.has("startSeconds")) {
                setOf("startSeconds")
            } else {
                emptySet()
            }
            val expectedKeys = when {
                payload.has("videoIds") ->
                    setOf("videoIds", "index") + optionalStart
                payload.has("playlistId") ->
                    setOf("playlistId", "index") + optionalStart
                else -> return false
            }
            if (
                !hasExactKeys(payload, expectedKeys) ||
                payload.opt("index") !is Int ||
                payload.getInt("index") !in 0..99 ||
                (
                    payload.has("startSeconds") &&
                        !finiteInRange(
                            payload.opt("startSeconds"),
                            0.0,
                            Double.MAX_VALUE,
                        )
                    )
            ) {
                return false
            }
            if (payload.has("playlistId")) {
                return PLAYLIST_ID_PATTERN.matches(
                    payload.optString("playlistId", ""),
                )
            }
            val values = payload.optJSONArray("videoIds") ?: return false
            if (values.length() !in 1..100 || payload.getInt("index") >= values.length()) {
                return false
            }
            return (0 until values.length()).all { index ->
                VIDEO_ID_PATTERN.matches(values.optString(index, ""))
            }
        }

        private fun isValidVideoLoadPayload(payload: JSONObject): Boolean {
            val keys = buildSet {
                add("videoId")
                if (payload.has("startSeconds")) add("startSeconds")
                if (payload.has("endSeconds")) add("endSeconds")
            }
            if (
                !hasExactKeys(payload, keys) ||
                !VIDEO_ID_PATTERN.matches(payload.optString("videoId", "")) ||
                (
                    payload.has("startSeconds") &&
                        !finiteInRange(
                            payload.opt("startSeconds"),
                            0.0,
                            Double.MAX_VALUE,
                        )
                    ) ||
                (
                    payload.has("endSeconds") &&
                        !finiteInRange(
                            payload.opt("endSeconds"),
                            Double.MIN_VALUE,
                            Double.MAX_VALUE,
                        )
                    )
            ) {
                return false
            }
            val start = (payload.opt("startSeconds") as? Number)?.toDouble()
            val end = (payload.opt("endSeconds") as? Number)?.toDouble()
            return start == null || end == null || end > start
        }

        private fun finiteInRange(
            value: Any?,
            minimum: Double,
            maximum: Double,
        ): Boolean {
            val number = value as? Number ?: return false
            return number.toDouble().isFinite() &&
                number.toDouble() in minimum..maximum
        }

        private fun isValidSphericalPayload(payload: JSONObject): Boolean =
            (
                hasExactKeys(
                    payload,
                    setOf("yaw", "pitch", "roll", "fieldOfView"),
                ) ||
                    hasExactKeys(
                        payload,
                        setOf(
                            "yaw",
                            "pitch",
                            "roll",
                            "fieldOfView",
                            "enableOrientationSensor",
                        ),
                    )
                ) &&
                finiteInRange(payload.opt("yaw"), 0.0, 359.999999) &&
                finiteInRange(payload.opt("pitch"), -90.0, 90.0) &&
                finiteInRange(payload.opt("roll"), -180.0, 180.0) &&
                finiteInRange(payload.opt("fieldOfView"), 30.0, 120.0) &&
                (
                    !payload.has("enableOrientationSensor") ||
                        payload.opt("enableOrientationSensor") is Boolean
                    )

        private fun isValidCaptionOptionsSnapshot(payload: JSONObject): Boolean {
            if (
                !hasExactKeys(payload, setOf("fontSize", "availableOptions")) ||
                payload.opt("fontSize") !is Int ||
                payload.getInt("fontSize") !in -1..3
            ) {
                return false
            }
            val options = payload.optJSONArray("availableOptions") ?: return false
            return options.length() <= 16 &&
                (0 until options.length()).all { index ->
                    CAPTION_OPTION_PATTERN.matches(options.optString(index, ""))
                }
        }

        private fun isValidStateSnapshot(payload: JSONObject): Boolean {
            if (
                !hasExactKeys(
                    payload,
                    setOf(
                        "stateCode",
                        "muted",
                        "volume",
                        "currentTime",
                        "duration",
                        "loadedFraction",
                        "playbackRate",
                        "availablePlaybackRates",
                        "playlistIndex",
                        "playlist",
                        "playlistTruncated",
                    ),
                ) ||
                payload.opt("stateCode") !is Int ||
                payload.getInt("stateCode") !in PLAYER_STATES ||
                payload.opt("muted") !is Boolean ||
                payload.opt("volume") !is Int ||
                payload.getInt("volume") !in 0..100 ||
                !finiteInRange(payload.opt("currentTime"), 0.0, Double.MAX_VALUE) ||
                !finiteInRange(payload.opt("duration"), 0.0, Double.MAX_VALUE) ||
                !finiteInRange(payload.opt("loadedFraction"), 0.0, 1.0) ||
                !finiteInRange(payload.opt("playbackRate"), 0.25, 4.0) ||
                payload.opt("playlistIndex") !is Int ||
                payload.getInt("playlistIndex") < -1 ||
                payload.opt("playlistTruncated") !is Boolean
            ) {
                return false
            }
            val rates = payload.optJSONArray("availablePlaybackRates") ?: return false
            if (
                rates.length() > 16 ||
                !(0 until rates.length()).all { index ->
                    finiteInRange(rates.opt(index), 0.25, 4.0)
                }
            ) {
                return false
            }
            val playlist = payload.optJSONArray("playlist") ?: return false
            return playlist.length() <= 100 &&
                (0 until playlist.length()).all { index ->
                    VIDEO_ID_PATTERN.matches(playlist.optString(index, ""))
                }
        }
    }
}
