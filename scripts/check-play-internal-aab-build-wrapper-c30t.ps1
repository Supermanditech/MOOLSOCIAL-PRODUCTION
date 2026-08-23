[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)
$wrapperPath = Join-Path $root 'scripts/invoke-play-internal-aab-build-c30t.ps1'
$launcherPath = Join-Path $root 'tmp/run-c30t-single-aab-founder.ps1'
$statePath = Join-Path $root 'config/play-internal-aab-regression-gate-state-c30t.json'
foreach ($path in @($wrapperPath, $launcherPath, $statePath)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "C30T wrapper gate rejected: missing $path" }
}
$wrapper = Get-Content -Raw -LiteralPath $wrapperPath
$launcher = Get-Content -Raw -LiteralPath $launcherPath
$state = Get-Content -Raw -LiteralPath $statePath | ConvertFrom-Json

$requiredWrapper = @(
  '$PSVersionTable.PSVersion.Major -lt 7',
  "'apk'", "'--release'", "'--config-only'",
  '$pubspecHashBefore', '$lockHashBefore', '$releaseApkBefore', '$releaseAabBefore',
  'restore-release-generated-plugin-registrant-c30t.ps1',
  '$preflightAttempt -le 5', '$attemptSuffix', '$attemptOutputs', '$attemptOccupied',
  'IntegrationTestPlugin', 'injectCrashlyticsMappingFileIdRelease', 'processReleaseGoogleServices',
  'com.google.android.providers.gsf.permission.READ_GSERVICES', 'recaptcha:18\.7\.1',
  'GenericIdpActivity', 'RecaptchaActivity', 'RevocationBoundService', 'ProfileInstallReceiver',
  "'appbundle'", '"--build-name=$versionName"', '"--build-number=$versionCode"',
  '$PSNativeCommandUseErrorActionPreference = $false', "`$ErrorActionPreference = 'Continue'",
  'release_config_manifest_and_single_AAB_build_in_progress_authority_consumed',
  '-printcert', '-jarfile', 'bundletool-all-1.18.3.jar',
  'string/google_app_id', 'string/com.google.firebase.crashlytics.mapping_file_id',
  'packageVersionManifestProved', 'splitAndArm64PayloadProved', 'mergedReleaseManifestProved',
  '-Phase postbuild', 'aggregate.candidate.buildCount = 1',
  'function Set-C30TAggregateBuildConsumed',
  '$Aggregate.actionCounts.build = 1',
  '$Aggregate.releaseAuthorities.build = ''consumed'''
)
foreach ($pattern in $requiredWrapper) {
  if ($wrapper.IndexOf($pattern, [StringComparison]::Ordinal) -lt 0) { throw "C30T wrapper gate rejected: missing $pattern" }
}
$requiredLauncher = @(
  '$PSVersionTable.PSVersion.Major -lt 7', 'Read-Host', '-AsSecureString',
  'c30t-firebase-defines.transient.json', 'google-services.json',
  '$secretParent -ceq $privateRoot', '$googleServicesParent -ceq $expectedGoogleServicesParent',
  '[IO.Directory]::CreateDirectory($googleServicesParent)',
  'Android key (auto created by Firebase)', 'for ($firebaseAttempt = 1; $firebaseAttempt -le 3; $firebaseAttempt++)',
  'full 39-character Firebase Android client API key beginning AIza',
  'MOOLSOCIAL_GOOGLE_SERVICES_JSON', 'invoke-play-internal-aab-build-c30t.ps1',
  'googleServicesFileQualifiedByFounder', 'source_qualified_founder_secret_prompt_required'
)
foreach ($pattern in $requiredLauncher) {
  if ($launcher.IndexOf($pattern, [StringComparison]::Ordinal) -lt 0) { throw "C30T launcher gate rejected: missing $pattern" }
}
$appBundleMatches = [regex]::Matches($wrapper, "'appbundle'").Count
if ($appBundleMatches -ne 1) { throw "C30T wrapper gate rejected: appbundle invocation count is $appBundleMatches." }
$aggregateTransitionCalls = [regex]::Matches(
  $wrapper,
  'Set-C30TAggregateBuildConsumed -Aggregate \$aggregate'
).Count
if ($aggregateTransitionCalls -ne 2) {
  throw "C30T wrapper gate rejected: aggregate build-consumption transition count is $aggregateTransitionCalls."
}
$consumeStart = $wrapper.IndexOf('$state.actionCounts.build = 1', [StringComparison]::Ordinal)
$consumeMirror = $wrapper.IndexOf(
  'Set-C30TAggregateBuildConsumed -Aggregate $aggregate',
  $consumeStart,
  [StringComparison]::Ordinal
)
$consumeStateWrite = $wrapper.IndexOf(
  "Write-JsonState -State `$state -Path `$stateFile -Suffix '.c30t-build-write'",
  [StringComparison]::Ordinal
)
$consumeAggregateWrite = $wrapper.IndexOf(
  "Write-JsonState -State `$aggregate -Path `$aggregateFile -Suffix '.c30t-build-write'",
  [StringComparison]::Ordinal
)
if (
  $consumeStart -lt 0 -or
  $consumeMirror -le $consumeStart -or
  $consumeStateWrite -le $consumeMirror -or
  $consumeAggregateWrite -le $consumeStateWrite
) {
  throw 'C30T wrapper gate rejected: build-consumption mirror or write order changed.'
}
$successHash = $wrapper.IndexOf('$aggregate.candidate.aabSha256 = $artifactHash', [StringComparison]::Ordinal)
$successMirror = $wrapper.IndexOf(
  'Set-C30TAggregateBuildConsumed -Aggregate $aggregate',
  $successHash,
  [StringComparison]::Ordinal
)
$successStateWrite = $wrapper.IndexOf(
  "Write-JsonState -State `$state -Path `$stateFile -Suffix '.c30t-success-write'",
  [StringComparison]::Ordinal
)
$successAggregateWrite = $wrapper.IndexOf(
  "Write-JsonState -State `$aggregate -Path `$aggregateFile -Suffix '.c30t-success-write'",
  [StringComparison]::Ordinal
)
if (
  $successHash -lt 0 -or
  $successMirror -le $successHash -or
  $successStateWrite -le $successMirror -or
  $successAggregateWrite -le $successStateWrite
) {
  throw 'C30T wrapper gate rejected: successful-build mirror or write order changed.'
}
foreach ($pattern in @('flutter build appbundle', 'flutter build apk', '--debug', '--profile', 'bundleProduction', 'Get-Content -Raw -LiteralPath $secretDefinePath', 'Get-Content -Raw -LiteralPath $googleServicesPath', 'MOOLSOCIAL_UPLOAD_STORE_PASSWORD=', 'MOOLSOCIAL_FIREBASE_API_KEY=')) {
  if ($wrapper.IndexOf($pattern, [StringComparison]::OrdinalIgnoreCase) -ge 0 -or $launcher.IndexOf($pattern, [StringComparison]::OrdinalIgnoreCase) -ge 0) { throw "C30T wrapper gate rejected: forbidden $pattern" }
}
if ([string]$state.runtimeConfiguration.requiredNonSecretDefines.MOOLSOCIAL_CHAT_URL -cne 'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialChat') { throw 'C30T wrapper gate rejected: Chat URL changed.' }
if ([string]$state.runtimeConfiguration.requiredNonSecretDefines.MOOLSOCIAL_SOCIAL_CONTENT_URL -cne 'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialContent') { throw 'C30T wrapper gate rejected: Social URL changed.' }
if ([string]$state.runtimeConfiguration.requiredNonSecretDefines.MOOLSOCIAL_YOUTUBE_PROVIDER_URL -cne 'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/youtubeProvider') { throw 'C30T wrapper gate rejected: YouTube URL changed.' }

Write-Output "C30T founder-secret-safe, fresh-manifest, exact-runtime, single-AAB, synchronized-state wrapper gate passed: hostPowerShellMajor=$($PSVersionTable.PSVersion.Major)."
