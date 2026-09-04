// MOOLSOCIAL_GOOGLE_IDENTITY_BRIDGE_FILE_BEGIN
// Official google_sign_in owns the Android Credential Manager integration.
// MOOLSOCIAL_GOOGLE_IDENTITY_BRIDGE_FILE_END
package com.moolsocial.app

import android.Manifest
import android.app.Activity
import android.content.ClipData
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.graphics.pdf.PdfDocument
import android.location.Geocoder
import android.location.Location
import android.location.LocationManager
import android.os.Build
import android.os.CancellationSignal
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import androidx.core.content.FileProvider
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.android.gms.common.api.ApiException
// MOOLSOCIAL_GOOGLE_IDENTITY_BRIDGE_IMPORTS_BEGIN
// Credential Manager stays primary; these imports support only the bounded
// debug fallback selected by the Dart gateway.
// MOOLSOCIAL_GOOGLE_IDENTITY_BRIDGE_IMPORTS_END
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.Locale
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

class MainActivity : FlutterActivity() {
    private val areaChannel = "com.moolsocial.app/current_area"
    private val invoiceChannel = "com.moolsocial.app/invoice"
    private val createInvoiceRequestCode = 6108
    private val googleIdentityChannel = "com.moolsocial.app/google_identity_fallback"
    private val googleIdentityRequestCode = 6110
    private val externalShareChannel = "dev.fluttercommunity.plus/share"
    // MOOLSOCIAL_GOOGLE_IDENTITY_BRIDGE_STATE_BEGIN
    // Google identity state is owned by the registered google_sign_in plugin.
    // MOOLSOCIAL_GOOGLE_IDENTITY_BRIDGE_STATE_END
    private val geocodingExecutor = Executors.newSingleThreadExecutor()
    private val invoiceExecutor = Executors.newSingleThreadExecutor()
    private var pendingInvoiceResult: MethodChannel.Result? = null
    private var pendingInvoiceBytes: ByteArray? = null
    private var pendingGoogleIdentityResult: MethodChannel.Result? = null
    private var pendingExternalShareResult: MethodChannel.Result? = null
    private var externalShareLeftActivity = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            externalShareChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "share" -> shareInSeparateTask(call.arguments, result)
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            areaChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "resolveCurrentArea" -> resolveCurrentArea(result)
                "openLocationServicesSettings" -> {
                    startActivity(Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            invoiceChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveInvoice" -> saveInvoice(call.arguments, result)
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            googleIdentityChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "authenticateIdToken" -> {
                    val serverClientId = call.argument<String>("serverClientId")?.trim()
                    if (serverClientId.isNullOrEmpty()) {
                        result.error(
                            "google_identity_configuration",
                            "Google sign-in is not configured.",
                            null,
                        )
                    } else {
                        authenticateGoogleIdToken(serverClientId, result)
                    }
                }
                "signOut" -> signOutGoogleIdentity(result)
                else -> result.notImplemented()
            }
        }
        // MOOLSOCIAL_GOOGLE_IDENTITY_BRIDGE_REGISTRATION_BEGIN
        // Credential Manager remains primary; the Play Services bridge handles
        // only devices that falsely return cancellation before showing identity UI.
        // MOOLSOCIAL_GOOGLE_IDENTITY_BRIDGE_REGISTRATION_END
    }

    @Suppress("DEPRECATION")
    private fun shareInSeparateTask(
        arguments: Any?,
        result: MethodChannel.Result,
    ) {
        val values = arguments as? Map<*, *>
        if (values == null) {
            result.error("Share failed", "Share content is invalid.", null)
            return
        }

        pendingExternalShareResult?.success(
            "dev.fluttercommunity.plus/share/unavailable",
        )
        pendingExternalShareResult = null
        externalShareLeftActivity = false

        try {
            val text = (values["uri"] as? String) ?: (values["text"] as? String)
            val subject = values["subject"] as? String
            val title = values["title"] as? String
            val rawPaths = values["paths"] as? List<*>
            val paths = rawPaths?.mapNotNull { it as? String }
            val rawMimeTypes = values["mimeTypes"] as? List<*>
            val mimeTypes = rawMimeTypes?.mapNotNull { it as? String }

            if (
                (text.isNullOrBlank() && paths.isNullOrEmpty()) ||
                (rawPaths != null && paths?.size != rawPaths.size) ||
                (rawMimeTypes != null && mimeTypes?.size != rawMimeTypes.size)
            ) {
                result.error("Share failed", "Share content is invalid.", null)
                return
            }

            val sendIntent = Intent().apply {
                action = if ((paths?.size ?: 0) > 1) {
                    Intent.ACTION_SEND_MULTIPLE
                } else {
                    Intent.ACTION_SEND
                }
                type = shareMimeType(mimeTypes)
                if (!text.isNullOrBlank()) putExtra(Intent.EXTRA_TEXT, text)
                if (!subject.isNullOrBlank()) putExtra(Intent.EXTRA_SUBJECT, subject)
                if (!title.isNullOrBlank()) putExtra(Intent.EXTRA_TITLE, title)
            }

            if (!paths.isNullOrEmpty()) {
                val authority = "$packageName.flutter.share_provider"
                val fileUris = ArrayList(
                    paths.map { path ->
                        FileProvider.getUriForFile(this, authority, File(path))
                    },
                )
                sendIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                sendIntent.clipData = ClipData.newRawUri(
                    "MoolSocial shared content",
                    fileUris.first(),
                ).apply {
                    fileUris.drop(1).forEach { uri -> addItem(ClipData.Item(uri)) }
                }
                if (fileUris.size == 1) {
                    sendIntent.putExtra(Intent.EXTRA_STREAM, fileUris.first())
                } else {
                    sendIntent.putParcelableArrayListExtra(
                        Intent.EXTRA_STREAM,
                        fileUris,
                    )
                }
                packageManager.queryIntentActivities(
                    sendIntent,
                    PackageManager.MATCH_DEFAULT_ONLY,
                ).forEach { target ->
                    fileUris.forEach { uri ->
                        grantUriPermission(
                            target.activityInfo.packageName,
                            uri,
                            Intent.FLAG_GRANT_READ_URI_PERMISSION,
                        )
                    }
                }
            }

            val chooserIntent = Intent.createChooser(sendIntent, title).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                if (!paths.isNullOrEmpty()) {
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
            }
            pendingExternalShareResult = result
            startActivity(chooserIntent)
        } catch (_: Exception) {
            pendingExternalShareResult = null
            externalShareLeftActivity = false
            result.error(
                "Share failed",
                "Sharing is unavailable right now.",
                null,
            )
        }
    }

    private fun shareMimeType(mimeTypes: List<String>?): String {
        val values = mimeTypes?.filter { it.isNotBlank() }.orEmpty()
        if (values.isEmpty()) return "text/plain"
        if (values.distinct().size == 1) return values.first()
        val families = values.map { it.substringBefore('/') }.distinct()
        return if (families.size == 1) "${families.first()}/*" else "*/*"
    }

    override fun onPause() {
        if (pendingExternalShareResult != null) {
            externalShareLeftActivity = true
        }
        super.onPause()
    }

    override fun onResume() {
        super.onResume()
        if (!externalShareLeftActivity) return
        val result = pendingExternalShareResult ?: return
        pendingExternalShareResult = null
        externalShareLeftActivity = false
        window.decorView.post { result.success("") }
    }

    @Suppress("DEPRECATION")
    private fun authenticateGoogleIdToken(
        serverClientId: String,
        result: MethodChannel.Result,
    ) {
        if (pendingGoogleIdentityResult != null) {
            result.error("google_identity_busy", "Google sign-in is already active.", null)
            return
        }
        val options = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
            .requestIdToken(serverClientId)
            .requestEmail()
            .build()
        pendingGoogleIdentityResult = result
        try {
            Log.i("MoolSocialGoogle", "fallback_started")
            startActivityForResult(
                GoogleSignIn.getClient(this, options).signInIntent,
                googleIdentityRequestCode,
            )
        } catch (_: Exception) {
            pendingGoogleIdentityResult = null
            result.error(
                "google_identity_ui_unavailable",
                "Google account selection is unavailable.",
                null,
            )
        }
    }

    @Suppress("DEPRECATION")
    private fun signOutGoogleIdentity(result: MethodChannel.Result) {
        val options = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
            .requestEmail()
            .build()
        GoogleSignIn.getClient(this, options).signOut()
            .addOnCompleteListener { result.success(null) }
    }

    @Suppress("DEPRECATION")
    private fun saveInvoice(arguments: Any?, result: MethodChannel.Result) {
        if (pendingInvoiceResult != null) {
            result.error("invoice_busy", "Another invoice save is active.", null)
            return
        }
        val values = arguments as? Map<*, *>
        if (values == null || values.keys != setOf("fileName", "lines")) {
            result.error("invalid_invoice", "Invoice data is invalid.", null)
            return
        }
        val fileName = values["fileName"] as? String
        val rawLines = values["lines"] as? List<*>
        val lines = rawLines?.mapNotNull { it as? String }
        if (
            fileName == null ||
            !Regex("^[A-Za-z0-9._-]{1,120}\\.pdf$", RegexOption.IGNORE_CASE)
                .matches(fileName) ||
            rawLines == null ||
            lines == null ||
            lines.size != rawLines.size ||
            lines.isEmpty() ||
            lines.size > 200 ||
            lines.any { line ->
                line.length > 500 || line.any { character ->
                    character.code < 0x20 && character != '\t'
                }
            }
        ) {
            result.error("invalid_invoice", "Invoice data is invalid.", null)
            return
        }

        val bytes = try {
            renderInvoicePdf(lines)
        } catch (_: Exception) {
            result.error(
                "invoice_generation_failed",
                "The invoice could not be prepared.",
                null,
            )
            return
        }
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "application/pdf"
            putExtra(Intent.EXTRA_TITLE, fileName)
        }
        pendingInvoiceResult = result
        pendingInvoiceBytes = bytes
        try {
            startActivityForResult(intent, createInvoiceRequestCode)
        } catch (_: Exception) {
            pendingInvoiceResult = null
            pendingInvoiceBytes = null
            result.success("unavailable")
        }
    }

    private fun renderInvoicePdf(lines: List<String>): ByteArray {
        val document = PdfDocument()
        return try {
            val bodyPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.BLACK
                textSize = 10.5f
                typeface = Typeface.create("sans", Typeface.NORMAL)
            }
            val titlePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.rgb(16, 8, 95)
                textSize = 16f
                typeface = Typeface.create("sans", Typeface.BOLD)
            }
            val footerPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.DKGRAY
                textSize = 8f
                typeface = Typeface.create("sans", Typeface.NORMAL)
            }
            val renderedLines = lines.flatMap { line ->
                wrapInvoiceLine(line, bodyPaint, 507f)
            }
            val pages = renderedLines.chunked(50).ifEmpty { listOf(listOf("")) }
            pages.forEachIndexed { index, pageLines ->
                val page = document.startPage(
                    PdfDocument.PageInfo.Builder(595, 842, index + 1).create(),
                )
                val canvas = page.canvas
                canvas.drawText("MoolSocial", 44f, 38f, titlePaint)
                var y = 64f
                for (line in pageLines) {
                    if (line.isNotEmpty()) canvas.drawText(line, 44f, y, bodyPaint)
                    y += 14f
                }
                canvas.drawText(
                    "Page ${index + 1} of ${pages.size}",
                    44f,
                    815f,
                    footerPaint,
                )
                document.finishPage(page)
            }
            ByteArrayOutputStream().use { output ->
                document.writeTo(output)
                output.toByteArray()
            }
        } finally {
            document.close()
        }
    }

    private fun wrapInvoiceLine(
        value: String,
        paint: Paint,
        maximumWidth: Float,
    ): List<String> {
        if (value.isEmpty()) return listOf("")
        val output = mutableListOf<String>()
        var remaining = value
        while (remaining.isNotEmpty()) {
            var count = paint.breakText(remaining, true, maximumWidth, null)
                .coerceAtLeast(1)
            if (count < remaining.length) {
                val whitespace = remaining.substring(0, count).lastIndexOf(' ')
                if (whitespace > 0) count = whitespace
            }
            output.add(remaining.substring(0, count).trimEnd())
            remaining = remaining.substring(count).trimStart()
        }
        return output
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == googleIdentityRequestCode) {
            Log.i("MoolSocialGoogle", "fallback_result_$resultCode")
            val result = pendingGoogleIdentityResult
            pendingGoogleIdentityResult = null
            if (result == null) return
            if (resultCode != Activity.RESULT_OK || data == null) {
                result.success(null)
                return
            }
            try {
                val account = GoogleSignIn.getSignedInAccountFromIntent(data)
                    .getResult(ApiException::class.java)
                val idToken = account.idToken
                if (idToken.isNullOrEmpty()) {
                    result.error(
                        "google_identity_missing_token",
                        "Google did not return an identity token.",
                        null,
                    )
                } else {
                    result.success(idToken)
                }
            } catch (error: ApiException) {
                Log.i("MoolSocialGoogle", "fallback_status_${error.statusCode}")
                result.error(
                    "google_identity_status_${error.statusCode}",
                    "Google account selection could not be completed.",
                    null,
                )
            }
            return
        }
        if (requestCode != createInvoiceRequestCode) {
            super.onActivityResult(requestCode, resultCode, data)
            return
        }
        val result = pendingInvoiceResult
        val bytes = pendingInvoiceBytes
        pendingInvoiceResult = null
        pendingInvoiceBytes = null
        if (result == null || bytes == null) return
        val destination = data?.data
        if (resultCode != Activity.RESULT_OK || destination == null) {
            result.success("cancelled")
            return
        }

        invoiceExecutor.execute {
            val saved = try {
                contentResolver.openOutputStream(destination, "w")?.use { output ->
                    output.write(bytes)
                    output.flush()
                } != null
            } catch (_: Exception) {
                false
            }
            runOnUiThread { result.success(if (saved) "saved" else "failed") }
        }
    }
    // MOOLSOCIAL_GOOGLE_IDENTITY_BRIDGE_CALLBACK_BEGIN
    // Credential Manager callbacks are owned by the official Flutter plugin.
    // MOOLSOCIAL_GOOGLE_IDENTITY_BRIDGE_CALLBACK_END

    private fun resolveCurrentArea(result: MethodChannel.Result) {
        if (
            checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) !=
                PackageManager.PERMISSION_GRANTED &&
            checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) !=
                PackageManager.PERMISSION_GRANTED
        ) {
            result.error("permission_denied", "Location permission is unavailable.", null)
            return
        }

        val manager = getSystemService(LOCATION_SERVICE) as LocationManager
        val providers = manager.getProviders(true)
        val lastKnown = providers
            .mapNotNull { provider ->
                try {
                    manager.getLastKnownLocation(provider)
                } catch (_: SecurityException) {
                    null
                }
            }
            .maxByOrNull(Location::getTime)

        if (lastKnown != null) {
            reverseGeocode(lastKnown, result)
            return
        }

        val provider = providers.firstOrNull {
            it == LocationManager.NETWORK_PROVIDER
        } ?: providers.firstOrNull {
            it == LocationManager.GPS_PROVIDER
        }
        if (provider == null) {
            result.error("location_services_off", "Location Services are off.", null)
            return
        }

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            result.error("location_unavailable", "A recent location is unavailable.", null)
            return
        }

        val completed = AtomicBoolean(false)
        val cancellation = CancellationSignal()
        val handler = Handler(Looper.getMainLooper())
        val timeout = Runnable {
            if (completed.compareAndSet(false, true)) {
                cancellation.cancel()
                result.error("location_timeout", "The current area is taking too long.", null)
            }
        }
        handler.postDelayed(timeout, 12_000)

        try {
            manager.getCurrentLocation(
                provider,
                cancellation,
                mainExecutor,
            ) { location ->
                if (!completed.compareAndSet(false, true)) return@getCurrentLocation
                handler.removeCallbacks(timeout)
                if (location == null) {
                    result.error(
                        "location_unavailable",
                        "A current location is unavailable.",
                        null,
                    )
                } else {
                    reverseGeocode(location, result)
                }
            }
        } catch (_: SecurityException) {
            handler.removeCallbacks(timeout)
            if (completed.compareAndSet(false, true)) {
                result.error("permission_denied", "Location permission is unavailable.", null)
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun reverseGeocode(location: Location, result: MethodChannel.Result) {
        geocodingExecutor.execute {
            try {
                val address = Geocoder(this, Locale.getDefault())
                    .getFromLocation(location.latitude, location.longitude, 1)
                    ?.firstOrNull()
                if (address == null) {
                    runOnUiThread {
                        result.error(
                            "address_unavailable",
                            "The area name is unavailable.",
                            null,
                        )
                    }
                    return@execute
                }

                val area = mapOf(
                    "subLocality" to address.subLocality,
                    "locality" to address.locality,
                    "subAdminArea" to address.subAdminArea,
                    "adminArea" to address.adminArea,
                    "postalCode" to address.postalCode,
                    "countryCode" to address.countryCode,
                )
                runOnUiThread { result.success(area) }
            } catch (_: Exception) {
                runOnUiThread {
                    result.error(
                        "address_unavailable",
                        "The area name is unavailable.",
                        null,
                    )
                }
            }
        }
    }

    override fun onDestroy() {
        // MOOLSOCIAL_GOOGLE_IDENTITY_BRIDGE_DESTROY_BEGIN
        // The Flutter engine disposes the official Google identity plugin.
        // MOOLSOCIAL_GOOGLE_IDENTITY_BRIDGE_DESTROY_END
        geocodingExecutor.shutdownNow()
        invoiceExecutor.shutdownNow()
        pendingInvoiceResult?.error(
            "activity_destroyed",
            "The invoice save was interrupted.",
            null,
        )
        pendingInvoiceResult = null
        pendingInvoiceBytes = null
        pendingGoogleIdentityResult?.error(
            "google_identity_interrupted",
            "Google account selection was interrupted.",
            null,
        )
        pendingGoogleIdentityResult = null
        pendingExternalShareResult?.success(
            "dev.fluttercommunity.plus/share/unavailable",
        )
        pendingExternalShareResult = null
        externalShareLeftActivity = false
        super.onDestroy()
    }
}
// MOOLSOCIAL_GOOGLE_IDENTITY_BRIDGE_IMPLEMENTATION_BEGIN
// Play Services fallback is bounded to false Credential Manager cancellations.
// MOOLSOCIAL_GOOGLE_IDENTITY_BRIDGE_IMPLEMENTATION_END
