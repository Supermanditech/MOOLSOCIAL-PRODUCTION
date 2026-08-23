// MOOLSOCIAL_GOOGLE_IDENTITY_BRIDGE_FILE_BEGIN
// Official google_sign_in owns the Android Credential Manager integration.
// MOOLSOCIAL_GOOGLE_IDENTITY_BRIDGE_FILE_END
package com.moolsocial.app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Geocoder
import android.location.Location
import android.location.LocationManager
import android.os.Build
import android.os.CancellationSignal
import android.os.Handler
import android.os.Looper
import android.provider.Settings
// MOOLSOCIAL_GOOGLE_IDENTITY_BRIDGE_IMPORTS_BEGIN
// No custom Google identity imports: the registered Flutter plugin owns them.
// MOOLSOCIAL_GOOGLE_IDENTITY_BRIDGE_IMPORTS_END
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

class MainActivity : FlutterActivity() {
    private val areaChannel = "com.moolsocial.app/current_area"
    // MOOLSOCIAL_GOOGLE_IDENTITY_BRIDGE_STATE_BEGIN
    // Google identity state is owned by the registered google_sign_in plugin.
    // MOOLSOCIAL_GOOGLE_IDENTITY_BRIDGE_STATE_END
    private val geocodingExecutor = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
        // MOOLSOCIAL_GOOGLE_IDENTITY_BRIDGE_REGISTRATION_BEGIN
        // GeneratedPluginRegistrant registers the official Google identity plugin.
        // MOOLSOCIAL_GOOGLE_IDENTITY_BRIDGE_REGISTRATION_END
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
        super.onDestroy()
    }
}
// MOOLSOCIAL_GOOGLE_IDENTITY_BRIDGE_IMPLEMENTATION_BEGIN
// No legacy activity-result identity bridge is permitted in the FIX11 path.
// MOOLSOCIAL_GOOGLE_IDENTITY_BRIDGE_IMPLEMENTATION_END
