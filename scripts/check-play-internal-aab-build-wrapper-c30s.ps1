[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)
$wrapperPath = Join-Path $root 'scripts/invoke-play-internal-aab-build-c30s.ps1'
$launcherPath = Join-Path $root 'tmp/run-c30s-single-aab-founder.ps1'
foreach ($path in @($wrapperPath, $launcherPath)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "C30S wrapper gate rejected: missing $path" }
}
$wrapper = Get-Content -Raw -LiteralPath $wrapperPath
$launcher = Get-Content -Raw -LiteralPath $launcherPath
$requiredWrapper = @(
  '$PSVersionTable.PSVersion.Major -lt 7',
  "'apk',", "'--release',", "'--config-only'",
  '$pubspecHashBefore', '$lockHashBefore', '$releaseApkBefore', '$releaseAabBefore',
  '$preflightAttempt -le 5', '$attemptSuffix', '$attemptOutputs', '$attemptOccupied',
  'return $LASTEXITCODE', '$releaseConfigExitCode = Invoke-FlutterCaptured',
  'IntegrationTestPlugin', 'injectCrashlyticsMappingFileIdRelease', 'processReleaseGoogleServices',
  'com.google.android.providers.gsf.permission.READ_GSERVICES', 'recaptcha:18\.7\.1',
  'releaseManifestMergerBlame',
  'GenericIdpActivity', 'RecaptchaActivity', 'RevocationBoundService', 'ProfileInstallReceiver',
  'com.google.android.gms.auth.api.signin.permission.REVOCATION_NOTIFICATION', 'android.permission.DUMP',
  'genericidp', 'firebase.auth', 'androidx.profileinstaller.action.INSTALL_PROFILE',
  'firebase-auth:24\.1\.0', 'play-services-auth:20\.7\.0', 'profileinstaller:1\.4\.0',
  'preflightAttempt = $preflightAttempt',
  "'appbundle',", "'--build-name=1.0.0-r60.44',", "'--build-number=2026081244',",
  '$PSNativeCommandUseErrorActionPreference = $false', "`$ErrorActionPreference = 'Continue'",
  'release_config_manifest_and_single_AAB_build_in_progress_authority_consumed',
  '-printcert', '-jarfile', 'bundletool-all-1.18.3.jar',
  'string/google_app_id', 'string/com_crashlytics_build_id',
  'packageVersionManifestProved', 'splitAndArm64PayloadProved', 'mergedReleaseManifestProved',
  '-Phase postbuild'
)
foreach ($pattern in $requiredWrapper) {
  if (-not $wrapper.Contains($pattern, [StringComparison]::Ordinal)) { throw "C30S wrapper gate rejected: missing $pattern" }
}
$requiredLauncher = @(
  '$PSVersionTable.PSVersion.Major -lt 7', 'Read-Host', '-AsSecureString',
  'c30s-firebase-defines.transient.json', 'google-services.json',
  '$secretParent -ceq $privateRoot', '$googleServicesParent -ceq $expectedGoogleServicesParent',
  '[IO.Directory]::CreateDirectory($googleServicesParent)',
  'Android key (auto created by Firebase)', 'for ($firebaseAttempt = 1; $firebaseAttempt -le 3; $firebaseAttempt++)',
  'full 39-character Firebase Android client API key beginning AIza',
  'MOOLSOCIAL_GOOGLE_SERVICES_JSON', 'invoke-play-internal-aab-build-c30s.ps1',
  'googleServicesFileQualifiedByFounder', 'source_qualified_founder_secret_prompt_required'
)
foreach ($pattern in $requiredLauncher) {
  if (-not $launcher.Contains($pattern, [StringComparison]::Ordinal)) { throw "C30S launcher gate rejected: missing $pattern" }
}
$appBundleMatches = [regex]::Matches($wrapper, "'appbundle'").Count
if ($appBundleMatches -ne 1) { throw "C30S wrapper gate rejected: appbundle invocation count is $appBundleMatches." }
foreach ($pattern in @('flutter build apk', '--debug', '--profile', 'bundleProduction', 'Get-Content -Raw -LiteralPath $secretDefinePath', 'Get-Content -Raw -LiteralPath $googleServicesPath', 'MOOLSOCIAL_UPLOAD_STORE_PASSWORD=', 'MOOLSOCIAL_FIREBASE_API_KEY=')) {
  if ($wrapper.Contains($pattern, [StringComparison]::OrdinalIgnoreCase) -or $launcher.Contains($pattern, [StringComparison]::OrdinalIgnoreCase)) { throw "C30S wrapper gate rejected: forbidden $pattern" }
}
Write-Output 'C30S PowerShell-7, founder-secret-safe, fresh-manifest, single-AAB, postbuild-resource wrapper gate passed.'
