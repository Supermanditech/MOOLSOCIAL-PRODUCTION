import com.google.firebase.crashlytics.buildtools.gradle.CrashlyticsExtension

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

val uploadStoreFile = providers.environmentVariable(
    "MOOLSOCIAL_UPLOAD_STORE_FILE",
).orNull
val uploadStorePassword = providers.environmentVariable(
    "MOOLSOCIAL_UPLOAD_STORE_PASSWORD",
).orNull
val uploadKeyAlias = providers.environmentVariable(
    "MOOLSOCIAL_UPLOAD_KEY_ALIAS",
).orNull
val uploadKeyPassword = providers.environmentVariable(
    "MOOLSOCIAL_UPLOAD_KEY_PASSWORD",
).orNull
val facebookAppId = providers.environmentVariable(
    "MOOLSOCIAL_FACEBOOK_APP_ID",
).orNull?.trim()?.takeIf { it.isNotEmpty() }
val facebookClientToken = providers.environmentVariable(
    "MOOLSOCIAL_FACEBOOK_CLIENT_TOKEN",
).orNull?.trim()?.takeIf { it.isNotEmpty() }
val androidDebugPackage = providers.environmentVariable(
    "MOOLSOCIAL_ANDROID_DEBUG_PACKAGE",
).orNull?.trim()?.takeIf { it.isNotEmpty() } ?: "runtime"
if (androidDebugPackage !in setOf("runtime", "cursorreview")) {
    throw GradleException(
        "Android debug package must be runtime or cursorreview.",
    )
}
val debugApplicationIdSuffix = ".$androidDebugPackage"
val debugVersionNameSuffix = "-$androidDebugPackage"
val debugAppName = if (androidDebugPackage == "cursorreview") {
    "MoolSocial Cursor Review"
} else {
    "MoolSocial Runtime"
}
if ((facebookAppId == null) != (facebookClientToken == null)) {
    throw GradleException(
        "Facebook Login requires both founder-controlled Android configuration values.",
    )
}
val facebookAutoInitEnabled = facebookAppId != null && facebookClientToken != null
val uploadSigningConfigured = listOf(
    uploadStoreFile,
    uploadStorePassword,
    uploadKeyAlias,
    uploadKeyPassword,
).all { !it.isNullOrBlank() }
val releasePackagingTaskRequested = gradle.startParameter.taskNames.any { taskName ->
    val leafTaskName = taskName.substringAfterLast(':')
    leafTaskName.matches(
        Regex(
            pattern = "(assemble|bundle|package|install|validateSigning).*release.*",
            option = RegexOption.IGNORE_CASE,
        ),
    )
}

if (releasePackagingTaskRequested && !uploadSigningConfigured) {
    throw GradleException(
        "Release signing requires the complete founder-controlled upload-key environment.",
    )
}

val generatedPluginRegistrant = file(
    "src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java",
)
val sanitizeReleaseGeneratedPluginRegistrant by tasks.registering {
    doLast {
        if (!generatedPluginRegistrant.isFile) {
            throw GradleException(
                "Flutter generated plugin registrant is missing for release.",
            )
        }
        var source = generatedPluginRegistrant.readText()
        val integrationStartMarker =
            "flutterEngine.getPlugins().add(new " +
                "dev.flutter.plugins.integration_test.IntegrationTestPlugin());"
        val integrationLineIndex = source.indexOf(integrationStartMarker)
        if (integrationLineIndex >= 0) {
            val blockStart = source.lastIndexOf("    try {", integrationLineIndex)
            val nextBlock = source.indexOf("    try {", integrationLineIndex + 1)
            if (blockStart < 0 || nextBlock < 0) {
                throw GradleException(
                    "Integration-test registrant block could not be bounded.",
                )
            }
            source = source.removeRange(blockStart, nextBlock)
            generatedPluginRegistrant.writeText(source)
        }
        if (!source.contains("FlutterFirebaseCorePlugin")) {
            throw GradleException(
                "Firebase Core is missing from the release plugin registrant.",
            )
        }
        if (!source.contains("dev.fluttercommunity.plus.share.SharePlusPlugin")) {
            throw GradleException(
                "Share Plus is missing from the release plugin registrant.",
            )
        }
        if (source.contains("IntegrationTestPlugin")) {
            throw GradleException(
                "Integration test plugin remains in the release registrant.",
            )
        }
    }
}
tasks.matching { it.name == "compileReleaseJavaWithJavac" }.configureEach {
    dependsOn(sanitizeReleaseGeneratedPluginRegistrant)
}

val localPropertiesFile = rootProject.file("local.properties")
val normalizeLocalPropertiesForLint by tasks.registering {
    doLast {
        if (!localPropertiesFile.isFile) {
            throw GradleException("Android local.properties is missing for lint.")
        }
        val normalizedLines = localPropertiesFile.readLines().map { line ->
            val separatorIndex = line.indexOf('=')
            if (separatorIndex <= 0) {
                return@map line
            }
            val key = line.substring(0, separatorIndex)
            if (key != "flutter.sdk" && key != "sdk.dir") {
                return@map line
            }
            val rawValue = line.substring(separatorIndex + 1)
            val decodedValue = rawValue
                .replace("\\:", ":")
                .replace("\\\\", "\\")
            if (!decodedValue.matches(Regex("^[A-Za-z]:[\\\\/].*"))) {
                return@map line
            }
            val escapedValue = decodedValue
                .replace("\\", "\\\\")
                .replaceFirst(":", "\\:")
            "$key=$escapedValue"
        }
        localPropertiesFile.writeText(
            normalizedLines.joinToString(System.lineSeparator()) +
                System.lineSeparator(),
        )
    }
}
tasks.matching {
    it.name.startsWith("lint") && it.name.contains("Release")
}.configureEach {
    dependsOn(normalizeLocalPropertiesForLint)
}

android {
    namespace = "com.moolsocial.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    buildFeatures {
        // Required by current AGP because app_name and the fail-closed Meta
        // resource placeholders are declared with defaultConfig.resValue.
        resValues = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Store identity is permanent after the first Play release.
        applicationId = "com.moolsocial.app"
        // Firebase is initialized from founder-supplied Dart defines. The
        // official Google Services plugin generates Android resource identity
        // from a founder-controlled transient configuration during the single
        // authorized release build; no API key is retained in this repository.
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Keep the SDK registered but fail-closed when the founder-controlled
        // Meta values are absent. Runtime availability remains false until the
        // separate provider/package/key-hash/redirect gate passes.
        resValue("string", "app_name", "MoolSocial")
        resValue("string", "facebook_app_id", facebookAppId ?: "0")
        resValue(
            "string",
            "fb_login_protocol_scheme",
            "fb${facebookAppId ?: "0"}",
        )
        resValue(
            "string",
            "facebook_client_token",
            facebookClientToken ?: "0",
        )
        resValue(
            "bool",
            "facebook_auto_init_enabled",
            facebookAutoInitEnabled.toString(),
        )
    }

    signingConfigs {
        if (uploadSigningConfigured) {
            create("release") {
                storeFile = file(uploadStoreFile!!)
                storePassword = uploadStorePassword
                keyAlias = uploadKeyAlias
                keyPassword = uploadKeyPassword
            }
        }
    }

    buildTypes {
        debug {
            applicationIdSuffix = debugApplicationIdSuffix
            versionNameSuffix = debugVersionNameSuffix
            resValue("string", "app_name", debugAppName)
        }
        getByName("profile") {
            applicationIdSuffix = debugApplicationIdSuffix
            versionNameSuffix = debugVersionNameSuffix
            resValue("string", "app_name", debugAppName)
        }
        release {
            signingConfig = signingConfigs.findByName("release")
            configure<CrashlyticsExtension> {
                // This variant is not obfuscated, so there is no mapping file
                // to upload. The Crashlytics build-ID resource remains enabled.
                mappingFileUploadEnabled = false
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Android Credential Manager can report a provider/configuration failure
    // as a user cancellation after account selection. Keep one explicit,
    // production-proven Play Services identity bridge for the Google button.
    implementation("com.google.android.gms:play-services-auth:21.6.0")
}
