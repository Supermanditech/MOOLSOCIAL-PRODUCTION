[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'C30T release readiness requires PowerShell 7.' }
$PSNativeCommandUseErrorActionPreference = $false
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))

function Assert-C30TReadiness {
  param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
  if (-not $Condition) { throw "C30T release readiness rejected: $Message" }
}
function Read-RepoFile {
  param([Parameter(Mandatory)][string]$RelativePath)
  $path = Join-Path $root $RelativePath
  Assert-C30TReadiness -Condition (Test-Path -LiteralPath $path -PathType Leaf) -Message "missing $RelativePath"
  return Get-Content -Raw -LiteralPath $path
}

& (Join-Path $root 'scripts/check-play-internal-aab-regression-gate-state-c30t.ps1') -Phase reconcile -RepositoryRoot $root

$settings = Read-RepoFile 'apps/mobile/android/settings.gradle.kts'
$gradle = Read-RepoFile 'apps/mobile/android/app/build.gradle.kts'
$main = Read-RepoFile 'apps/mobile/lib/main.dart'
$pubspec = Read-RepoFile 'apps/mobile/pubspec.yaml'
$registrant = Read-RepoFile 'apps/mobile/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java'
$registrantRestore = Read-RepoFile 'scripts/restore-release-generated-plugin-registrant-c30t.ps1'
$qualifier = Read-RepoFile 'scripts/qualify-play-internal-live-read-recovery-c30t.ps1'
$manifest = Read-RepoFile 'apps/mobile/android/app/src/main/AndroidManifest.xml'
$youtubeGradle = Read-RepoFile 'apps/mobile/packages/youtube_embedded_player_private_dev/android/build.gradle.kts'
$chatServices = Read-RepoFile 'apps/mobile/lib/features/chat/chat_services.dart'
$socialGateway = Read-RepoFile 'apps/mobile/lib/features/shared/social_content_gateway.dart'
$state = (Read-RepoFile 'config/play-internal-aab-regression-gate-state-c30t.json') | ConvertFrom-Json

foreach ($pattern in @(
  'id("com.google.gms.google-services") version "4.5.0" apply false',
  'id("com.google.firebase.crashlytics") version "3.0.7" apply false'
)) {
  Assert-C30TReadiness -Condition $settings.Contains($pattern, [StringComparison]::Ordinal) -Message "Android settings missing $pattern"
}
foreach ($pattern in @(
  'id("com.google.gms.google-services")',
  'id("com.google.firebase.crashlytics")',
  'configure<CrashlyticsExtension>',
  'mappingFileUploadEnabled = false',
  'applicationId = "com.moolsocial.app"',
  'signingConfig = signingConfigs.findByName("release")',
  '(assemble|bundle|package|install|validateSigning).*release.*'
)) {
  Assert-C30TReadiness -Condition $gradle.Contains($pattern, [StringComparison]::Ordinal) -Message "app Gradle contract missing $pattern"
}
foreach ($forbidden in @('signingConfig = signingConfigs.getByName("debug")', 'minifyEnabled = true', 'isMinifyEnabled = true', 'shrinkResources = true', 'isShrinkResources = true')) {
  Assert-C30TReadiness -Condition (-not $gradle.Contains($forbidden, [StringComparison]::OrdinalIgnoreCase)) -Message "forbidden release setting $forbidden"
}
Assert-C30TReadiness -Condition (-not $youtubeGradle.Contains('srcDirs', [StringComparison]::Ordinal)) -Message 'repository-owned YouTube Gradle still uses deprecated srcDirs.'

$initialize = $main.IndexOf('await Firebase.initializeApp(options: firebaseOptions);', [StringComparison]::Ordinal)
$flutterHandler = $main.IndexOf('FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;', [StringComparison]::Ordinal)
$platformHandler = $main.IndexOf('PlatformDispatcher.instance.onError = (error, stack)', [StringComparison]::Ordinal)
$appCheck = $main.IndexOf('await activateYouTubePrivateDevAppCheckIfEnabled(', [StringComparison]::Ordinal)
$runApp = $main.IndexOf('runApp(', [StringComparison]::Ordinal)
Assert-C30TReadiness -Condition ($initialize -ge 0 -and $flutterHandler -gt $initialize -and $platformHandler -gt $flutterHandler -and $appCheck -gt $platformHandler -and $runApp -gt $appCheck) -Message 'Firebase, Crashlytics, App Check and first-app-frame initialization order changed.'
Assert-C30TReadiness -Condition $main.Contains('fatal: true', [StringComparison]::Ordinal) -Message 'fatal asynchronous Flutter error capture is missing.'
Assert-C30TReadiness -Condition ($main.Contains('ChatSession.production()', [StringComparison]::Ordinal) -and $chatServices.Contains("String.fromEnvironment('MOOLSOCIAL_CHAT_URL')", [StringComparison]::Ordinal) -and $socialGateway.Contains("'MOOLSOCIAL_SOCIAL_CONTENT_URL'", [StringComparison]::Ordinal)) -Message 'production Social or Chat runtime owner changed.'

foreach ($dependency in @('firebase_core:', 'firebase_auth:', 'google_sign_in:', 'firebase_app_check:', 'firebase_crashlytics:', 'firebase_data_connect:', 'mobile_scanner:', 'speech_to_text:')) {
  Assert-C30TReadiness -Condition $pubspec.Contains($dependency, [StringComparison]::Ordinal) -Message "required dependency missing: $dependency"
}
foreach ($dependency in @('firebase_analytics:', 'firebase_messaging:', 'firebase_performance:', 'firebase_remote_config:', 'firebase_ui_auth:', 'desktop_webview_auth:', 'app_links:')) {
  Assert-C30TReadiness -Condition (-not $pubspec.Contains($dependency, [StringComparison]::Ordinal)) -Message "unused startup dependency remains: $dependency"
}

$expectedPlugins = @(
  'FirebaseAppCheckPlugin', 'FlutterFirebaseAuthPlugin', 'FlutterFirebaseCorePlugin',
  'FlutterFirebaseCrashlyticsPlugin', 'FlutterAndroidLifecyclePlugin', 'GoogleSignInPlugin', 'ImagePickerPlugin',
  'JniPlugin', 'JniFlutterPlugin', 'MobileScannerPlugin', 'PermissionHandlerPlugin',
  'SharedPreferencesPlugin', 'SpeechToTextPlugin', 'UrlLauncherPlugin',
  'VideoPlayerPlugin', 'YouTubeEmbeddedPlayerPrivateDevPlugin'
)
$registrations = [regex]::Matches($registrant, 'flutterEngine\.getPlugins\(\)\.add\(new\s+([^;]+)\(\)\);')
Assert-C30TReadiness -Condition ($registrations.Count -eq $expectedPlugins.Count) -Message "release registrant count is $($registrations.Count), expected $($expectedPlugins.Count)."
foreach ($plugin in $expectedPlugins) {
  Assert-C30TReadiness -Condition $registrant.Contains($plugin, [StringComparison]::Ordinal) -Message "release registrant missing $plugin"
}
foreach ($plugin in @('IntegrationTestPlugin', 'Analytics', 'Messaging', 'Performance', 'RemoteConfig', 'DesktopWebview', 'AppLinks')) {
  Assert-C30TReadiness -Condition (-not $registrant.Contains($plugin, [StringComparison]::OrdinalIgnoreCase)) -Message "release registrant contains forbidden $plugin"
}
foreach ($pattern in @('.flutter-plugins-dependencies', "name -ceq 'integration_test'", 'dev_dependency', '$releaseNativePlugins.Count -eq 16', '$registrations.Count -eq 16')) {
  Assert-C30TReadiness -Condition $registrantRestore.Contains($pattern, [StringComparison]::Ordinal) -Message "release registrant restore gate missing $pattern"
}
foreach ($pattern in @('$qualificationState.providerRevisions.youtubeprovider', '$qualificationState.providerRevisions.youtubeoauthcallback', '$youtubeRevision -ceq $youtubeExpectedRevision', '$callbackRevision -ceq $callbackExpectedRevision')) {
  Assert-C30TReadiness -Condition $qualifier.Contains($pattern, [StringComparison]::Ordinal) -Message "provider revision qualifier gate missing $pattern"
}
foreach ($pattern in @('pass 505\s*$', '505_of_505_passed', 'backendTests=505')) {
  Assert-C30TReadiness -Condition $qualifier.Contains($pattern, [StringComparison]::Ordinal) -Message "backend qualifier count gate missing $pattern"
}
Assert-C30TReadiness -Condition (-not $qualifier.Contains('503_of_503_passed', [StringComparison]::Ordinal)) -Message 'backend qualifier retains stale 503-test summary.'
Assert-C30TReadiness -Condition ([regex]::Matches($qualifier, [regex]::Escape('scripts/restore-release-generated-plugin-registrant-c30t.ps1')).Count -eq 3) -Message 'registrant restore helper is not owned by preflight, post-test and source-manifest qualification.'
Assert-C30TReadiness -Condition ([regex]::Matches($qualifier, [regex]::Escape("'test/shared_vertical_slice_test.dart'")).Count -eq 1) -Message 'shared global Chat and return-route suite is not owned exactly once by qualification.'
Assert-C30TReadiness -Condition ([regex]::Matches($qualifier, [regex]::Escape("'test/platform_release_signing_and_provenance_test.dart'")).Count -eq 1) -Message 'release signing and provenance suite is not owned exactly once by qualification.'
foreach ($forbidden in @("`$youtubeRevision -ceq 'youtubeprovider-00036-qer'", "`$callbackRevision -ceq 'youtubeoauthcallback-00035-cir'")) {
  Assert-C30TReadiness -Condition (-not $qualifier.Contains($forbidden, [StringComparison]::Ordinal)) -Message "provider qualifier retains stale revision hardcode $forbidden"
}

foreach ($pattern in @('android:allowBackup="false"', 'android:fullBackupContent="false"', 'android:name=".MainActivity"', 'android:name=".YouTubeConnectReturnActivity"')) {
  Assert-C30TReadiness -Condition $manifest.Contains($pattern, [StringComparison]::Ordinal) -Message "main manifest missing $pattern"
}
Assert-C30TReadiness -Condition (-not $manifest.Contains('usesCleartextTraffic', [StringComparison]::OrdinalIgnoreCase)) -Message 'release source manifest enables or mentions cleartext traffic.'
$exportedTrue = [regex]::Matches($manifest, 'android:exported="true"').Count
Assert-C30TReadiness -Condition ($exportedTrue -eq 2) -Message "main manifest exported component count is $exportedTrue."
$sourcePermissions = @([regex]::Matches($manifest, '<uses-permission android:name="([^"]+)"') | ForEach-Object { $_.Groups[1].Value })
$expectedSourcePermissions = @('android.permission.ACCESS_COARSE_LOCATION', 'android.permission.ACCESS_FINE_LOCATION', 'android.permission.CAMERA', 'android.permission.INTERNET', 'android.permission.RECORD_AUDIO')
Assert-C30TReadiness -Condition ($sourcePermissions.Count -eq $expectedSourcePermissions.Count -and @($sourcePermissions | Where-Object { $_ -notin $expectedSourcePermissions }).Count -eq 0) -Message 'main manifest permission scope changed.'

$requiredDefines = $state.runtimeConfiguration.requiredNonSecretDefines
Assert-C30TReadiness -Condition ([string]$requiredDefines.MOOLSOCIAL_CANDIDATE_ID -ceq 'UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-LIVE-READ-RECOVERY-C30T') -Message 'candidate runtime define changed.'
Assert-C30TReadiness -Condition ([string]$requiredDefines.MOOLSOCIAL_YOUTUBE_PROVIDER_URL -ceq 'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/youtubeProvider') -Message 'YouTube provider URL changed.'
Assert-C30TReadiness -Condition ([string]$requiredDefines.MOOLSOCIAL_SOCIAL_CONTENT_URL -ceq 'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialContent') -Message 'Social provider URL changed.'
Assert-C30TReadiness -Condition ([string]$requiredDefines.MOOLSOCIAL_CHAT_URL -ceq 'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialChat') -Message 'Chat provider URL changed.'

$transientGoogleServices = Join-Path $root ([string]$state.runtimeConfiguration.transientGoogleServicesPath)
$transientDefine = Join-Path ([IO.Path]::GetDirectoryName([string]$state.signingQualification.uploadKeyStorePath)) 'c30t-firebase-defines.transient.json'
Assert-C30TReadiness -Condition (-not (Test-Path -LiteralPath $transientGoogleServices)) -Message 'transient google-services.json exists before founder launch.'
Assert-C30TReadiness -Condition (-not (Test-Path -LiteralPath $transientDefine)) -Message 'transient Dart define file exists before founder launch.'

$credentialPattern = '(AI' + 'za[0-9A-Za-z_-]{35}|-----BEGIN (RSA |EC |ENCRYPTED )?PRIVATE KEY-----|Bearer\s+[A-Za-z0-9._~+/-]+=*|ya29\.[A-Za-z0-9_-]+)'
$productionRoots = @(
  (Join-Path $root 'apps/mobile/lib'),
  (Join-Path $root 'apps/mobile/android'),
  (Join-Path $root 'backend/functions/src')
)
$productionSecretFiles = @(& rg -l --hidden --glob '!build/**' --glob '!local.properties' --glob '!google-services.json' --glob '!*.test.ts' $credentialPattern @productionRoots)
$productionSecretExit = $LASTEXITCODE
Assert-C30TReadiness -Condition ($productionSecretExit -in @(0, 1)) -Message "production credential scan execution failed with $productionSecretExit."
Assert-C30TReadiness -Condition ($productionSecretFiles.Count -eq 0) -Message "credential-shaped material exists in $($productionSecretFiles.Count) production source file(s)."

$controlRoots = @(
  (Join-Path $root 'scripts/check-play-internal-release-readiness-c30t.ps1'),
  (Join-Path $root 'scripts/check-play-internal-aab-regression-gate-state-c30t.ps1'),
  (Join-Path $root 'scripts/check-play-internal-aab-build-wrapper-c30t.ps1'),
  (Join-Path $root 'scripts/invoke-play-internal-aab-build-c30t.ps1'),
  (Join-Path $root 'scripts/qualify-play-internal-live-read-recovery-c30t.ps1'),
  (Join-Path $root 'tmp/run-c30t-single-aab-founder.ps1'),
  (Join-Path $root 'config/play-internal-aab-regression-gate-state-c30t.json'),
  (Join-Path $root 'config/uaw-personal-mvp-social-play-internal-live-read-recovery-c30t-ticket.json')
)
$controlSecretFiles = @(& rg -l $credentialPattern @controlRoots)
$controlSecretExit = $LASTEXITCODE
Assert-C30TReadiness -Condition ($controlSecretExit -in @(0, 1)) -Message "release-control credential scan execution failed with $controlSecretExit."
Assert-C30TReadiness -Condition ($controlSecretFiles.Count -eq 0) -Message "credential-shaped material exists in $($controlSecretFiles.Count) release-control file(s)."

$fixtureFiles = @(& rg -l --glob '*.test.ts' $credentialPattern (Join-Path $root 'backend/functions/src'))
$fixtureExit = $LASTEXITCODE
Assert-C30TReadiness -Condition ($fixtureExit -in @(0, 1)) -Message "credential-shaped test-fixture filename inventory failed with $fixtureExit."
$fixtureRelative = @($fixtureFiles | ForEach-Object {
  $full = [IO.Path]::GetFullPath($_)
  $full.Substring($root.Length + 1).Replace('\', '/')
} | Sort-Object -Unique)
$expectedFixtureRelative = @(
  'backend/functions/src/social/request_security.test.ts',
  'backend/functions/src/workspace/privileged_command_contract.test.ts',
  'backend/functions/src/youtube-private-dev/analytics-reporting/analytics_client.test.ts',
  'backend/functions/src/youtube/audit_store.test.ts',
  'backend/functions/src/youtube/creator_assets_client.test.ts',
  'backend/functions/src/youtube/owner_revalidation.test.ts',
  'backend/functions/src/youtube/redaction.test.ts'
) | Sort-Object
Assert-C30TReadiness -Condition ($fixtureRelative.Count -eq $expectedFixtureRelative.Count -and @(Compare-Object -ReferenceObject $expectedFixtureRelative -DifferenceObject $fixtureRelative).Count -eq 0) -Message 'credential-shaped test-fixture filename allowlist changed.'

$mobileAndroid = Join-Path $root 'apps/mobile/android'
Push-Location $mobileAndroid
try {
  $taskOutput = & .\gradlew.bat :app:tasks --all --console=plain 2>&1
  $taskExit = $LASTEXITCODE
} finally { Pop-Location }
Assert-C30TReadiness -Condition ($taskExit -eq 0) -Message "Gradle release task registration failed with $taskExit."
$taskText = $taskOutput -join [Environment]::NewLine
Assert-C30TReadiness -Condition $taskText.Contains('processReleaseGoogleServices', [StringComparison]::Ordinal) -Message 'processReleaseGoogleServices task is missing.'
Assert-C30TReadiness -Condition $taskText.Contains('injectCrashlyticsMappingFileIdRelease', [StringComparison]::Ordinal) -Message 'Crashlytics release build-ID task is missing.'
Assert-C30TReadiness -Condition (-not $taskText.Contains('Google-Services plugin not found', [StringComparison]::OrdinalIgnoreCase)) -Message 'Crashlytics still rejects the Google Services plugin.'

Assert-C30TReadiness -Condition ([string]$state.candidate.versionName -ceq '1.0.0-r60.45' -and [string]$state.candidate.versionCode -ceq '2026081345') -Message 'r60.45 identity changed.'
Assert-C30TReadiness -Condition ([string]$state.providerRevisions.moolsocialcontent -ceq 'moolsocialcontent-00004-gig' -and [string]$state.providerRevisions.moolsocialchat -ceq 'moolsocialchat-00001-yaf' -and [string]$state.providerRevisions.youtubeprovider -ceq 'youtubeprovider-00038-cic' -and [string]$state.providerRevisions.youtubeoauthcallback -ceq 'youtubeoauthcallback-00035-cir') -Message 'provider revisions changed.'
Assert-C30TReadiness -Condition (-not [bool]$state.providerRevisions.additionalBackendDeploymentAuthorized) -Message 'additional backend deployment became authorized.'

Write-Output "C30T static release readiness passed: plugins=$($registrations.Count); permissions=$($sourcePermissions.Count); providers=4; AAB_count=$($state.buildResult.buildCount)."
