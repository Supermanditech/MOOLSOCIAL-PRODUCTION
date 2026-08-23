[CmdletBinding()]
param(
  [Parameter(Mandatory)][ValidateSet(1, 2)][int]$Cycle,
  [ValidateRange(1, 20)][int]$Attempt = 1,
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'C30V qualification requires PowerShell 7.' }
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$mobileRoot = Join-Path $root 'apps/mobile'
$backendRoot = Join-Path $root 'backend/functions'
$statePath = Join-Path $root 'config/play-internal-aab-regression-gate-state-c30v.json'
$aggregatePath = Join-Path $root 'config/play-internal-seal-recovery-acceptance-gate-state-c30v.json'
$artifactRelative = 'artifacts/quality/uaw-c30v-r60-47-seal-recovery-play-internal-acceptance-20260814-01'
$artifactRoot = Join-Path $root $artifactRelative
$sourceManifestRelative = "$artifactRelative/07-source-aggregate-manifest-accepted-v7.txt"
$sourceManifestPath = Join-Path $root $sourceManifestRelative
$cycleRelative = if ($Cycle -eq 1) { "$artifactRelative/08-qualifying-cycle-1-v6.json" } else { "$artifactRelative/09-qualifying-cycle-2-v6.json" }
$cyclePath = Join-Path $root $cycleRelative
$logStem = if ($Attempt -eq 1) { "cycle$Cycle" } else { "cycle$Cycle-attempt-$Attempt" }

function Assert-C30VQualification {
  param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
  if (-not $Condition) { throw "C30V qualification rejected: $Message" }
}

function Write-C30VJson {
  param([Parameter(Mandatory)][object]$State, [Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Suffix)
  $temporary = $Path + $Suffix
  Assert-C30VQualification -Condition (-not (Test-Path -LiteralPath $temporary)) -Message "stale temporary state exists: $temporary"
  [IO.File]::WriteAllText($temporary, (($State | ConvertTo-Json -Depth 50) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
  Move-Item -LiteralPath $temporary -Destination $Path -Force
}

function Invoke-C30VCaptured {
  param(
    [Parameter(Mandatory)][string]$Command,
    [Parameter(Mandatory)][string[]]$Arguments,
    [Parameter(Mandatory)][string]$WorkingDirectory,
    [Parameter(Mandatory)][string]$LogPath
  )
  Assert-C30VQualification -Condition (-not (Test-Path -LiteralPath $LogPath)) -Message "qualification log already exists: $LogPath"
  $savedErrorActionPreference = $ErrorActionPreference
  $savedNativePreference = $PSNativeCommandUseErrorActionPreference
  try {
    $ErrorActionPreference = 'Continue'
    $PSNativeCommandUseErrorActionPreference = $false
    Push-Location $WorkingDirectory
    try { & $Command @Arguments *> $LogPath; return $LASTEXITCODE }
    finally { Pop-Location }
  } finally {
    $ErrorActionPreference = $savedErrorActionPreference
    $PSNativeCommandUseErrorActionPreference = $savedNativePreference
  }
}

function Get-C30VArtifactSnapshot {
  param([Parameter(Mandatory)][string]$Path)
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return 'absent' }
  $item = Get-Item -LiteralPath $Path
  return '{0}|{1}|{2}' -f $item.Length, $item.LastWriteTimeUtc.Ticks, (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function Get-C30VTapCounts {
  param([Parameter(Mandatory)][string]$Path)
  $passRows = @(Select-String -LiteralPath $Path -Pattern '^(?:#|ℹ) pass ([0-9]+)$')
  $failRows = @(Select-String -LiteralPath $Path -Pattern '^(?:#|ℹ) fail ([0-9]+)$')
  Assert-C30VQualification -Condition ($passRows.Count -ge 1 -and $failRows.Count -ge 1) -Message "TAP summary missing: $Path"
  $pass = [int]([regex]::Match($passRows[-1].Line, '^(?:#|ℹ) pass ([0-9]+)$').Groups[1].Value)
  $fail = [int]([regex]::Match($failRows[-1].Line, '^(?:#|ℹ) fail ([0-9]+)$').Groups[1].Value)
  return [pscustomobject]@{ Passed = $pass; Failed = $fail }
}

function Get-C30VServiceRevision {
  param([Parameter(Mandatory)][string]$Service)
  $format = 'json(metadata.name,status.latestReadyRevisionName,status.latestCreatedRevisionName,status.traffic)'
  $output = & gcloud run services describe $Service --region=asia-south1 --project=moolsocial-dev-503018 --format=$format 2>$null
  Assert-C30VQualification -Condition ($LASTEXITCODE -eq 0) -Message "Cloud Run read failed: $Service"
  $value = ($output | Out-String) | ConvertFrom-Json
  $revision = [string]$value.status.latestReadyRevisionName
  $traffic = @($value.status.traffic)
  Assert-C30VQualification -Condition (
    [string]$value.metadata.name -ceq $Service -and
    [string]$value.status.latestCreatedRevisionName -ceq $revision -and
    $traffic.Count -eq 1 -and
    [int]$traffic[0].percent -eq 100 -and
    [string]$traffic[0].revisionName -ceq $revision
  ) -Message "$Service revision or traffic changed."
  return $revision
}

$qualifierSource = Get-Content -Raw -LiteralPath $PSCommandPath
Assert-C30VQualification -Condition ($qualifierSource -notmatch '&\s+adb\s+devices\s*\|') -Message 'qualifier still pipelines adb devices before native exit capture.'
Assert-C30VQualification -Condition (Test-Path -LiteralPath $artifactRoot -PathType Container) -Message 'evidence root is missing.'
Assert-C30VQualification -Condition (-not (Test-Path -LiteralPath $cyclePath)) -Message "cycle $Cycle evidence already exists and is immutable."
$state = Get-Content -Raw -LiteralPath $statePath | ConvertFrom-Json
$aggregate = Get-Content -Raw -LiteralPath $aggregatePath | ConvertFrom-Json
Assert-C30VQualification -Condition (
  [string]$state.machineState -ceq 'pre_aab_reconciliation_in_progress_authority_available' -and
  [string]$state.buildAuthorization -ceq 'available_once_after_two_identical_cycles' -and
  [int]$state.buildResult.buildCount -eq 0 -and
  [int]$state.playReleaseResult.uploadCount -eq 0 -and
  [int]$state.installResult.candidateInstallCount -eq 0 -and
  [int]$aggregate.candidate.buildCount -eq 0 -and
  [int]$aggregate.candidate.uploadCount -eq 0 -and
  [int]$aggregate.candidate.installCount -eq 0
) -Message 'release authority or zero counters changed before qualification.'
Assert-C30VQualification -Condition (
  -not [bool]$aggregate.providerAndHostingBoundary.deploymentRequired -and
  [string]$aggregate.providerAndHostingBoundary.deploymentState -ceq 'preserved_no_deployment_authorized' -and
  [int]$aggregate.providerAndHostingBoundary.deploymentAttemptCount -eq 0 -and
  [int]$aggregate.providerAndHostingBoundary.deploymentCount -eq 0 -and
  [string]$aggregate.providerAndHostingBoundary.deployedRevision -ceq 'moolsocialcontent-00005-lep' -and
  -not [bool]$state.providerRevisions.backendDeploymentCompleted -and
  -not [bool]$state.providerRevisions.additionalBackendDeploymentAuthorized -and
  [string]$state.providerRevisions.moolsocialcontent -ceq 'moolsocialcontent-00005-lep'
) -Message 'preserved Dev moolSocialContent revision or no-deployment boundary changed.'
Assert-C30VQualification -Condition (
  -not [bool]$state.runtimeConfiguration.googleServicesFileQualifiedByFounder -and
  -not [bool]$state.runtimeConfiguration.secretDefineFileQualifiedByFounder -and
  -not [bool]$state.runtimeConfiguration.googleServicesFileReadByAgent -and
  -not [bool]$state.runtimeConfiguration.secretDefineFileReadByAgent
) -Message 'founder secret-input state changed before the prompt.'
if ($Cycle -eq 1) {
  Assert-C30VQualification -Condition (-not (Test-Path -LiteralPath $sourceManifestPath)) -Message 'accepted source manifest already exists before cycle 1.'
  Assert-C30VQualification -Condition ([int]$state.sourceQualification.identicalQualifyingCycles -eq 0) -Message 'cycle count is not zero before cycle 1.'
} else {
  Assert-C30VQualification -Condition (Test-Path -LiteralPath $sourceManifestPath -PathType Leaf) -Message 'cycle 1 source manifest is missing.'
  Assert-C30VQualification -Condition ([int]$state.sourceQualification.identicalQualifyingCycles -eq 1) -Message 'cycle 1 is not sealed before cycle 2.'
}

& (Join-Path $root 'scripts/check-codex-development-regression-memory.ps1') -Phase implementation -BuildMode none -RepositoryRoot $root
& (Join-Path $root 'scripts/check-mvp-delivery-discipline-lock.ps1') -RepositoryRoot $root -RequireTicketSelectionAssessment
& (Join-Path $root 'scripts/check-mvp-scope-gate-state.ps1') -CandidateId ([string]$state.candidate.id) -RequireExecutionAuthorized -RepositoryRoot $root
& (Join-Path $root 'scripts/check-play-internal-aab-regression-gate-state-c30v.ps1') -Phase reconcile -RepositoryRoot $root
& (Join-Path $root 'scripts/check-approved-ui-locks.ps1')

$releaseApk = Join-Path $mobileRoot 'build/app/outputs/flutter-apk/app-release.apk'
$releaseAab = Join-Path $mobileRoot 'build/app/outputs/bundle/release/app-release.aab'
$apkBefore = Get-C30VArtifactSnapshot -Path $releaseApk
$aabBefore = Get-C30VArtifactSnapshot -Path $releaseAab
$pubspecBefore = (Get-FileHash -LiteralPath (Join-Path $mobileRoot 'pubspec.yaml') -Algorithm SHA256).Hash
$lockBefore = (Get-FileHash -LiteralPath (Join-Path $mobileRoot 'pubspec.lock') -Algorithm SHA256).Hash

$formatLog = Join-Path $artifactRoot "$logStem-flutter-format.log"
$formatExit = Invoke-C30VCaptured -Command 'dart' -Arguments @(
  'format', '--output=none', '--set-exit-if-changed', 'lib', 'test', 'integration_test', 'packages/youtube_embedded_player_private_dev'
) -WorkingDirectory $mobileRoot -LogPath $formatLog
Assert-C30VQualification -Condition ($formatExit -eq 0) -Message "Flutter/Dart format check failed with exit $formatExit."

$analyzeLog = Join-Path $artifactRoot "$logStem-flutter-analyze.log"
$analyzeExit = Invoke-C30VCaptured -Command 'flutter' -Arguments @('analyze') -WorkingDirectory $mobileRoot -LogPath $analyzeLog
Assert-C30VQualification -Condition ($analyzeExit -eq 0) -Message "whole mobile analyzer failed with exit $analyzeExit."

$flutterLog = Join-Path $artifactRoot "$logStem-authoritative-flutter.log"
$flutterExit = Invoke-C30VCaptured -Command 'pwsh' -Arguments @(
  '-NoProfile', '-File', (Join-Path $root 'tmp/run-c30t-authoritative-flutter-manifest-audit.ps1'), '-RepositoryRoot', $root
) -WorkingDirectory $root -LogPath $flutterLog
Assert-C30VQualification -Condition ($flutterExit -eq 0) -Message "authoritative 58-file Flutter audit failed with exit $flutterExit."
$flutterSummary = @(Select-String -LiteralPath $flutterLog -Pattern '^authoritative_manifest_files=58 raw_test_done=[0-9]+ authored_passed=405 authored_skipped=3 authored_failed=0 error_events=0 non_json_lines=[0-9]+ flutter_exit=0$')
Assert-C30VQualification -Condition ($flutterSummary.Count -eq 1) -Message 'authoritative Flutter counted summary changed.'

$backendLog = Join-Path $artifactRoot "$logStem-backend-verify.log"
$backendExit = Invoke-C30VCaptured -Command 'npm' -Arguments @('run', 'verify') -WorkingDirectory $backendRoot -LogPath $backendLog
Assert-C30VQualification -Condition ($backendExit -eq 0) -Message "backend verify failed with exit $backendExit."
$backendCounts = Get-C30VTapCounts -Path $backendLog
Assert-C30VQualification -Condition ($backendCounts.Passed -eq 516 -and $backendCounts.Failed -eq 0) -Message 'backend verify is not 516 passed and 0 failed.'

$hostingLog = Join-Path $artifactRoot "$logStem-hosting-tests.log"
$hostingExit = Invoke-C30VCaptured -Command 'node' -Arguments @('--test', 'apps/web/tests/firebase-public-site.test.mjs') -WorkingDirectory $root -LogPath $hostingLog
Assert-C30VQualification -Condition ($hostingExit -eq 0) -Message "Hosting static tests failed with exit $hostingExit."
$hostingCounts = Get-C30VTapCounts -Path $hostingLog
Assert-C30VQualification -Condition ($hostingCounts.Passed -eq 7 -and $hostingCounts.Failed -eq 0) -Message 'Hosting static tests are not 7 passed and 0 failed.'

$configLog = Join-Path $artifactRoot "$logStem-release-config-only.log"
$configExit = Invoke-C30VCaptured -Command 'flutter' -Arguments @(
  'build', 'apk', '--release', '--config-only', '--build-name=1.0.0-r60.47', '--build-number=2026081347'
) -WorkingDirectory $mobileRoot -LogPath $configLog
Assert-C30VQualification -Condition ($configExit -eq 0) -Message "r60.47 release config-only failed with exit $configExit."
$restoreLog = Join-Path $artifactRoot "$logStem-release-registrant-restore.log"
$restoreExit = Invoke-C30VCaptured -Command 'pwsh' -Arguments @(
  '-NoProfile', '-File', (Join-Path $root 'scripts/restore-release-generated-plugin-registrant-c30t.ps1'), '-RepositoryRoot', $root
) -WorkingDirectory $root -LogPath $restoreLog
Assert-C30VQualification -Condition ($restoreExit -eq 0) -Message 'release GeneratedPluginRegistrant restore failed.'
Assert-C30VQualification -Condition (
  $pubspecBefore -ceq (Get-FileHash -LiteralPath (Join-Path $mobileRoot 'pubspec.yaml') -Algorithm SHA256).Hash -and
  $lockBefore -ceq (Get-FileHash -LiteralPath (Join-Path $mobileRoot 'pubspec.lock') -Algorithm SHA256).Hash -and
  $apkBefore -ceq (Get-C30VArtifactSnapshot -Path $releaseApk) -and
  $aabBefore -ceq (Get-C30VArtifactSnapshot -Path $releaseAab)
) -Message 'release config-only changed dependencies or an APK/AAB.'

$gateLogs = [Collections.Generic.List[string]]::new()
foreach ($gate in @(
  'scripts/check-c30v-social-protected-successor.ps1',
  'scripts/check-youtube-embedded-player-android.ps1',
  'scripts/check-user-facing-copy.ps1',
  'scripts/check-play-internal-aab-build-wrapper-c30v.ps1',
  'scripts/check-play-internal-aab-regression-gate-state-c30v.ps1'
)) {
  $gateName = [IO.Path]::GetFileNameWithoutExtension($gate)
  $gateLog = Join-Path $artifactRoot "$logStem-$gateName.log"
  $gateExit = Invoke-C30VCaptured -Command 'pwsh' -Arguments @('-NoProfile', '-File', (Join-Path $root $gate)) -WorkingDirectory $root -LogPath $gateLog
  Assert-C30VQualification -Condition ($gateExit -eq 0) -Message "$gate failed with exit $gateExit."
  $gateLogs.Add($gateLog)
}

$youtubeRevision = Get-C30VServiceRevision -Service 'youtubeprovider'
$callbackRevision = Get-C30VServiceRevision -Service 'youtubeoauthcallback'
$contentRevision = Get-C30VServiceRevision -Service 'moolsocialcontent'
$chatRevision = Get-C30VServiceRevision -Service 'moolsocialchat'
Assert-C30VQualification -Condition (
  $youtubeRevision -ceq 'youtubeprovider-00038-cic' -and
  $callbackRevision -ceq 'youtubeoauthcallback-00035-cir' -and
  $contentRevision -ceq 'moolsocialcontent-00005-lep' -and
  $chatRevision -ceq 'moolsocialchat-00001-yaf'
) -Message 'post-deployment provider revisions differ from the exact C30V boundary.'

$hostingOutput = & firebase hosting:channel:list --site moolsocial-dev-503018 --project moolsocial-dev-503018 --json 2>$null
Assert-C30VQualification -Condition ($LASTEXITCODE -eq 0) -Message 'live Hosting channel read failed.'
$hostingState = ($hostingOutput | Out-String) | ConvertFrom-Json
$live = @($hostingState.result.channels | Where-Object {
  [string]$_.name -ceq 'projects/moolsocial-dev-503018/sites/moolsocial-dev-503018/channels/live'
})
Assert-C30VQualification -Condition ($live.Count -eq 1) -Message 'live Hosting channel identity changed.'
$hostingRelease = ([string]$live[0].release.name -split '/')[-1]
$hostingVersion = ([string]$live[0].release.version.name -split '/')[-1]
Assert-C30VQualification -Condition (
  $hostingRelease -ceq '1786609421461000' -and $hostingVersion -ceq '86a17ea7c0f4a41f'
) -Message 'live Hosting release or version changed.'

$deviceOutput = @(& adb devices 2>&1)
$deviceExit = $LASTEXITCODE
Assert-C30VQualification -Condition ($deviceExit -eq 0) -Message "adb devices failed with exit $deviceExit."
$deviceRows = @($deviceOutput | Select-Object -Skip 1 | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
Assert-C30VQualification -Condition ($deviceRows.Count -eq 1 -and [string]$deviceRows[0] -match '^2b3e0f71\s+device$') -Message 'exact OPPO is not the sole connected ready device.'
$packageDump = @(& adb -s 2b3e0f71 shell dumpsys package com.moolsocial.app)
Assert-C30VQualification -Condition ($LASTEXITCODE -eq 0) -Message 'OPPO package read failed.'
$versionCodeRows = @($packageDump | Where-Object { $_ -match 'versionCode=2026081345\b' })
$versionNameRows = @($packageDump | Where-Object { $_ -match 'versionName=1\.0\.0-r60\.45\b' })
Assert-C30VQualification -Condition ($versionCodeRows.Count -ge 1 -and $versionNameRows.Count -ge 1) -Message 'OPPO Play predecessor version changed before the one authorized update.'
$installSource = @(& adb -s 2b3e0f71 shell pm list packages -i com.moolsocial.app 2>&1)
$installSourceExit = $LASTEXITCODE
$playInstallerRows = @($installSource | Where-Object {
  [string]$_ -match '^package:com\.moolsocial\.app\s+installer=com\.android\.vending\s*$'
})
Assert-C30VQualification -Condition (
  $installSourceExit -eq 0 -and $playInstallerRows.Count -eq 1
) -Message 'OPPO installer is not exactly Google Play.'

Assert-C30VQualification -Condition (
  $apkBefore -ceq (Get-C30VArtifactSnapshot -Path $releaseApk) -and
  $aabBefore -ceq (Get-C30VArtifactSnapshot -Path $releaseAab)
) -Message 'qualification created or changed an APK/AAB.'

$manifestLog = Join-Path $artifactRoot "$logStem-source-manifest.log"
$provisionalManifestRelative = "$artifactRelative/$logStem-source-manifest-provisional.txt"
$provisionalManifestPath = Join-Path $root $provisionalManifestRelative
$manifestArguments = if ($Cycle -eq 1) {
  @('-NoProfile', '-File', (Join-Path $root 'scripts/new-c30v-source-manifest.ps1'), '-OutputPath', $provisionalManifestRelative, '-RepositoryRoot', $root)
} else {
  @('-NoProfile', '-File', (Join-Path $root 'scripts/new-c30v-source-manifest.ps1'), '-ComparePath', $sourceManifestRelative, '-RepositoryRoot', $root)
}
$manifestExit = Invoke-C30VCaptured -Command 'pwsh' -Arguments $manifestArguments -WorkingDirectory $root -LogPath $manifestLog
Assert-C30VQualification -Condition ($manifestExit -eq 0) -Message "source manifest cycle $Cycle failed with exit $manifestExit."
$manifestSummary = @(Select-String -LiteralPath $manifestLog -Pattern '^sourceFiles=([0-9]+); sourceFingerprintSha256=([0-9A-F]{64}); protectedSourceOwners=206; missingProtectedSourceOwners=0$')
Assert-C30VQualification -Condition ($manifestSummary.Count -eq 1) -Message 'source manifest protected-owner summary changed.'
$manifestMatch = [regex]::Match([string]$manifestSummary[0].Line, '^sourceFiles=([0-9]+); sourceFingerprintSha256=([0-9A-F]{64}); protectedSourceOwners=206; missingProtectedSourceOwners=0$')
$manifestEvidencePath = if ($Cycle -eq 1) { $provisionalManifestPath } else { $sourceManifestPath }
Assert-C30VQualification -Condition (Test-Path -LiteralPath $manifestEvidencePath -PathType Leaf) -Message 'source manifest evidence is missing.'
$manifestEvidenceHash = (Get-FileHash -LiteralPath $manifestEvidencePath -Algorithm SHA256).Hash
$manifestEvidenceCount = @(Get-Content -LiteralPath $manifestEvidencePath).Count
Assert-C30VQualification -Condition (
  [int]$manifestMatch.Groups[1].Value -eq $manifestEvidenceCount -and
  [string]$manifestMatch.Groups[2].Value -ceq $manifestEvidenceHash
) -Message 'source manifest counted summary does not match its exact evidence.'
if ($Cycle -eq 1) {
  Assert-C30VQualification -Condition (-not (Test-Path -LiteralPath $sourceManifestPath)) -Message 'accepted-v7 source manifest already exists before promotion.'
  Copy-Item -LiteralPath $provisionalManifestPath -Destination $sourceManifestPath
  Assert-C30VQualification -Condition (
    (Get-FileHash -LiteralPath $sourceManifestPath -Algorithm SHA256).Hash -ceq $manifestEvidenceHash
  ) -Message 'accepted-v7 source manifest differs from validated provisional evidence.'
}
Assert-C30VQualification -Condition (Test-Path -LiteralPath $sourceManifestPath -PathType Leaf) -Message 'accepted-v7 source manifest is missing.'
$manifestHash = (Get-FileHash -LiteralPath $sourceManifestPath -Algorithm SHA256).Hash
$manifestFileCount = @(Get-Content -LiteralPath $sourceManifestPath).Count
Assert-C30VQualification -Condition (
  $manifestFileCount -eq $manifestEvidenceCount -and $manifestHash -ceq $manifestEvidenceHash
) -Message 'accepted-v7 source manifest changed after validation.'
if ($Cycle -eq 2) {
  Assert-C30VQualification -Condition (
    [string]$state.sourceQualification.manifestSha256 -ceq $manifestHash -and
    [int]$state.sourceQualification.fileCount -eq $manifestFileCount
  ) -Message 'cycle 2 source manifest differs from sealed cycle 1 state.'
}

$cycleResult = [ordered]@{
  schemaVersion = 1
  candidateId = [string]$state.candidate.id
  cycle = $Cycle
  attempt = $Attempt
  branch = (& git -C $root rev-parse --abbrev-ref HEAD).Trim()
  head = (& git -C $root rev-parse HEAD).Trim()
  sourceManifest = $sourceManifestRelative
  sourceManifestSha256 = $manifestHash
  sourceFiles = $manifestFileCount
  authoritativeFocusedManifest = [string]$aggregate.sourceQualification.authoritativeFocusedManifestPath
  authoritativeFocusedManifestSha256 = [string]$aggregate.sourceQualification.authoritativeFocusedManifestSha256
  authoritativeFocusedManifestFiles = 58
  flutterPassed = 405
  flutterSkipped = 3
  flutterFailed = 0
  backendPassed = 516
  backendFailed = 0
  hostingPassed = 7
  hostingFailed = 0
  wholeMobileAnalyzer = 'clean'
  dartFormat = 'clean'
  releaseConfigurationAndManifestPreflight = 'passed_without_AAB_or_APK_mutation'
  buildUploadInstallCounts = '0/0/0'
  providerRevisions = [ordered]@{
    youtubeprovider = $youtubeRevision
    youtubeoauthcallback = $callbackRevision
    moolsocialcontent = $contentRevision
    moolsocialchat = $chatRevision
  }
  hostingRelease = $hostingRelease
  hostingVersion = $hostingVersion
  oppoPredecessor = [ordered]@{
    serial = '2b3e0f71'
    versionName = '1.0.0-r60.45'
    versionCode = '2026081345'
    installer = 'com.android.vending'
  }
  secretValuesReadOrRecordedByAgent = $false
  apiKeyPasswordTokenNoncePrivateVerdictOrAttestationPayloadInspected = $false
  logs = [ordered]@{
    format = [string]$formatLog.Substring($root.Length + 1).Replace('\', '/')
    analyze = [string]$analyzeLog.Substring($root.Length + 1).Replace('\', '/')
    flutter = [string]$flutterLog.Substring($root.Length + 1).Replace('\', '/')
    backend = [string]$backendLog.Substring($root.Length + 1).Replace('\', '/')
    hosting = [string]$hostingLog.Substring($root.Length + 1).Replace('\', '/')
    releaseConfig = [string]$configLog.Substring($root.Length + 1).Replace('\', '/')
    releaseRegistrantRestore = [string]$restoreLog.Substring($root.Length + 1).Replace('\', '/')
    sourceManifest = [string]$manifestLog.Substring($root.Length + 1).Replace('\', '/')
    gates = @($gateLogs | ForEach-Object { $_.Substring($root.Length + 1).Replace('\', '/') })
  }
  logSha256 = [ordered]@{
    format = (Get-FileHash -LiteralPath $formatLog -Algorithm SHA256).Hash
    analyze = (Get-FileHash -LiteralPath $analyzeLog -Algorithm SHA256).Hash
    flutter = (Get-FileHash -LiteralPath $flutterLog -Algorithm SHA256).Hash
    backend = (Get-FileHash -LiteralPath $backendLog -Algorithm SHA256).Hash
    hosting = (Get-FileHash -LiteralPath $hostingLog -Algorithm SHA256).Hash
    releaseConfig = (Get-FileHash -LiteralPath $configLog -Algorithm SHA256).Hash
    releaseRegistrantRestore = (Get-FileHash -LiteralPath $restoreLog -Algorithm SHA256).Hash
    sourceManifestLog = (Get-FileHash -LiteralPath $manifestLog -Algorithm SHA256).Hash
  }
  qualifiedAt = [DateTimeOffset]::Now.ToString('o')
}
[IO.File]::WriteAllText($cyclePath, (($cycleResult | ConvertTo-Json -Depth 20) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
$cycleHash = (Get-FileHash -LiteralPath $cyclePath -Algorithm SHA256).Hash

$state = Get-Content -Raw -LiteralPath $statePath | ConvertFrom-Json
$aggregate = Get-Content -Raw -LiteralPath $aggregatePath | ConvertFrom-Json
$state.sourceQualification.manifestPath = $sourceManifestRelative
$state.sourceQualification.manifestSha256 = $manifestHash
$state.sourceQualification.fileCount = $manifestFileCount
$state.sourceQualification.completeRegressionGatePassed = $true
$state.sourceQualification.backendVerifyPassed = $true
$state.sourceQualification.hostingVerifyPassed = $true
$state.sourceQualification.focusedSocialSuitePassed = $true
$state.sourceQualification.analyzerPassed = $true
$state.sourceQualification.deploymentPassed = $true
$state.sourceQualification.releasePreflightPassed = $true
$aggregate.sourceQualification.manifestPath = $sourceManifestRelative
$aggregate.sourceQualification.manifestSha256 = $manifestHash
$aggregate.sourceQualification.sourceFingerprintSha256 = $manifestHash
$aggregate.sourceQualification.fileCount = $manifestFileCount
$aggregate.sourceQualification.releaseConfigurationAndManifestPreflightPassed = $true
$aggregate.sourceQualification.secretAndEnvironmentAuditPassed = $true
$aggregate.sourceQualification.sourceUnchangedAfterDeployment = $true

if ($Cycle -eq 1) {
  $state.sourceQualification.state = 'cycle_1_passed_source_sealed_cycle_2_required'
  $state.sourceQualification.identicalQualifyingCycles = 1
  $state.sourceQualification.cycleEvidence = @($cycleRelative)
  $aggregate.sourceQualification.state = 'cycle_1_passed_source_sealed_cycle_2_required'
  $aggregate.sourceQualification.identicalQualifyingCycles = 1
  $aggregate.sourceQualification.cycleEvidence = @($cycleRelative)
} else {
  $cycle1Relative = "$artifactRelative/08-qualifying-cycle-1-v6.json"
  $cycle1Path = Join-Path $root $cycle1Relative
  Assert-C30VQualification -Condition (Test-Path -LiteralPath $cycle1Path -PathType Leaf) -Message 'cycle 1 evidence disappeared.'
  $cycle1 = Get-Content -Raw -LiteralPath $cycle1Path | ConvertFrom-Json
  Assert-C30VQualification -Condition (
    [string]$cycle1.sourceManifestSha256 -ceq $manifestHash -and
    [int]$cycle1.sourceFiles -eq $manifestFileCount -and
    [int]$cycle1.flutterPassed -eq 405 -and
    [int]$cycle1.flutterSkipped -eq 3 -and
    [int]$cycle1.backendPassed -eq 516 -and
    [int]$cycle1.hostingPassed -eq 7 -and
    [string]$cycle1.providerRevisions.moolsocialcontent -ceq 'moolsocialcontent-00005-lep' -and
    [string]$cycle1.hostingRelease -ceq '1786609421461000' -and
    [string]$cycle1.hostingVersion -ceq '86a17ea7c0f4a41f'
  ) -Message 'cycle 1 and cycle 2 qualification facts differ.'
  $state.sourceQualification.state = 'passed_two_identical_cycles_with_preserved_Dev_services'
  $state.sourceQualification.identicalQualifyingCycles = 2
  $state.sourceQualification.cycleEvidence = @($cycle1Relative, $cycleRelative)
  $state.machineState = 'source_qualified_founder_secret_prompt_required'
  $state.buildAuthorization = 'available_once'
  $aggregate.sourceQualification.state = 'passed_two_identical_cycles_with_preserved_Dev_services'
  $aggregate.sourceQualification.identicalQualifyingCycles = 2
  $aggregate.sourceQualification.cycleEvidence = @($cycle1Relative, $cycleRelative)
  $aggregate.machineState = 'source_qualified_founder_secret_prompt_required'
}
Write-C30VJson -State $state -Path $statePath -Suffix (".c30v-cycle{0}-write" -f $Cycle)
Write-C30VJson -State $aggregate -Path $aggregatePath -Suffix (".c30v-cycle{0}-write" -f $Cycle)

if ($Cycle -eq 2) {
  $summaryRelative = "$artifactRelative/10-final-pre-aab-qualification-summary-v6.json"
  $summaryPath = Join-Path $root $summaryRelative
  Assert-C30VQualification -Condition (-not (Test-Path -LiteralPath $summaryPath)) -Message 'final pre-AAB summary already exists.'
  $summary = [ordered]@{
    schemaVersion = 1
    candidateId = [string]$state.candidate.id
    state = 'source_qualified_founder_secret_prompt_required'
    sourceManifest = $sourceManifestRelative
    sourceManifestSha256 = $manifestHash
    sourceFiles = $manifestFileCount
    cycle1 = $cycle1Relative
    cycle1Sha256 = (Get-FileHash -LiteralPath $cycle1Path -Algorithm SHA256).Hash
    cycle2 = $cycleRelative
    cycle2Sha256 = $cycleHash
    qualifyingCycles = 2
    flutter = '405_passed_3_declared_skips_0_failed_each_cycle'
    backend = '516_passed_0_failed_each_cycle'
    hosting = '7_passed_0_failed_each_cycle'
    analyzer = 'clean_each_cycle'
    providerDeployment = 'preserved_moolsocialcontent-00005-lep_at_100_percent_no_C30V_deployment'
    preservedRevisions = @('youtubeprovider-00038-cic', 'youtubeoauthcallback-00035-cir', 'moolsocialchat-00001-yaf')
    preservedHosting = '1786609421461000/86a17ea7c0f4a41f'
    oppoPredecessor = '1.0.0-r60.45/2026081345/com.android.vending'
    buildUploadInstallCounts = '0/0/0'
    buildAuthorization = 'available_once'
    FirebasePhoneAndPasswordlessEmailLinkBlockPublicLaunchNotInternalCandidate = $true
    secretValuesReadOrRecordedByAgent = $false
    emailSent = $false
    quotaSubmitted = $false
  }
  [IO.File]::WriteAllText($summaryPath, (($summary | ConvertTo-Json -Depth 10) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
}

Write-Output "C30V qualifying cycle $Cycle passed: sourceFiles=$manifestFileCount; sourceFingerprint=$manifestHash; Flutter=405+3skip; backend=516; Hosting=7; build/upload/install=0/0/0."
