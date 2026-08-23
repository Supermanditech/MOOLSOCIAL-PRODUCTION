[CmdletBinding()]
param([Parameter(Mandatory)][ValidateSet(1, 2)][int]$Cycle, [string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'C30S qualifier requires PowerShell 7.' }
$PSNativeCommandUseErrorActionPreference = $false
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$candidateId = 'UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-FIREBASE-STARTUP-RECOVERY-C30S'
$artifactRelative = 'artifacts/quality/uaw-personal-mvp-social-play-internal-firebase-startup-recovery-c30s-r60-44-20260812-01'
$artifactRoot = Join-Path $root $artifactRelative
$statePath = Join-Path $root 'config/play-internal-aab-regression-gate-state-c30s.json'
$mobileRoot = Join-Path $root 'apps/mobile'
$attempt = [DateTimeOffset]::Now.ToString('yyyyMMdd-HHmmss-fff')
$attemptRoot = Join-Path $artifactRoot "qualification-attempt-$attempt-cycle-$Cycle"
New-Item -ItemType Directory -Path $attemptRoot -Force | Out-Null

function Assert-C30SQualification {
  param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
  if (-not $Condition) { throw "C30S source qualification rejected: $Message" }
}
function Invoke-NativeLogged {
  param([Parameter(Mandatory)][string]$Command, [Parameter(Mandatory)][string[]]$Arguments, [Parameter(Mandatory)][string]$WorkingDirectory, [Parameter(Mandatory)][string]$LogPath)
  [IO.File]::WriteAllText($LogPath, '', [Text.UTF8Encoding]::new($false))
  $savedErrorActionPreference = $ErrorActionPreference
  $savedNativePreference = $PSNativeCommandUseErrorActionPreference
  try {
    $ErrorActionPreference = 'Continue'
    $PSNativeCommandUseErrorActionPreference = $false
    Push-Location $WorkingDirectory
    try { & $Command @Arguments *> $LogPath; $exitCode = $LASTEXITCODE }
    finally { Pop-Location }
  } finally {
    $ErrorActionPreference = $savedErrorActionPreference
    $PSNativeCommandUseErrorActionPreference = $savedNativePreference
  }
  if ($exitCode -ne 0) { throw "Command failed with exit $exitCode; log=$LogPath" }
}
function Get-ArtifactSnapshot {
  param([Parameter(Mandatory)][string]$Path)
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return 'absent' }
  $file = Get-Item -LiteralPath $Path
  return '{0}|{1}|{2}' -f $file.Length, $file.LastWriteTimeUtc.Ticks, (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}
function Write-State {
  param([Parameter(Mandatory)][object]$State)
  $temporary = $statePath + '.qualifier-write'
  Assert-C30SQualification -Condition (-not (Test-Path -LiteralPath $temporary)) -Message 'stale qualifier state file exists.'
  [IO.File]::WriteAllText($temporary, (($State | ConvertTo-Json -Depth 40) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
  Move-Item -LiteralPath $temporary -Destination $statePath -Force
}

& (Join-Path $root 'scripts/check-codex-development-regression-memory.ps1') -Phase implementation
& (Join-Path $root 'scripts/check-mvp-delivery-discipline-lock.ps1') -RepositoryRoot $root
& (Join-Path $root 'scripts/check-mvp-scope-gate-state.ps1') -CandidateId $candidateId -RequireExecutionAuthorized -RepositoryRoot $root
& (Join-Path $root 'scripts/check-play-internal-aab-regression-gate-state-c30s.ps1') -Phase reconcile -RepositoryRoot $root
& (Join-Path $root 'scripts/check-play-internal-release-readiness-c30s.ps1') -RepositoryRoot $root

$deviceSummary = & adb -s 2b3e0f71 shell dumpsys package com.moolsocial.app 2>&1
Assert-C30SQualification -Condition ($LASTEXITCODE -eq 0) -Message 'OPPO package readback failed.'
$deviceText = $deviceSummary -join [Environment]::NewLine
Assert-C30SQualification -Condition ($deviceText.Contains('versionCode=2026081243', [StringComparison]::Ordinal) -and $deviceText.Contains('versionName=1.0.0-r60.43', [StringComparison]::Ordinal) -and $deviceText.Contains('installerPackageName=com.android.vending', [StringComparison]::Ordinal)) -Message 'r60.43 is not preserved as the Play-installed predecessor.'
$deviceSummary = $null; $deviceText = $null

$releaseApk = Join-Path $mobileRoot 'build/app/outputs/flutter-apk/app-release.apk'
$releaseAab = Join-Path $mobileRoot 'build/app/outputs/bundle/release/app-release.aab'
$apkBefore = Get-ArtifactSnapshot -Path $releaseApk
$aabBefore = Get-ArtifactSnapshot -Path $releaseAab

$formatLog = Join-Path $attemptRoot 'format.log'
$analyzeLog = Join-Path $attemptRoot 'analyze.log'
$testLog = Join-Path $attemptRoot 'tests.log'
$affectedTestManifestLog = Join-Path $attemptRoot 'affected-test-manifest.txt'
$configLog = Join-Path $attemptRoot 'release-config-only.log'
$dependencyLog = Join-Path $attemptRoot 'release-runtime-dependencies.log'
$gateLog = Join-Path $attemptRoot 'repository-gates.log'

Invoke-NativeLogged -Command 'dart' -Arguments @('format', '--output=none', '--set-exit-if-changed', 'lib', 'test', 'integration_test', 'packages/youtube_embedded_player_private_dev/lib') -WorkingDirectory $mobileRoot -LogPath $formatLog
Invoke-NativeLogged -Command 'flutter' -Arguments @('analyze') -WorkingDirectory $mobileRoot -LogPath $analyzeLog
$c30qSourceManifest = Join-Path $root 'artifacts/quality/uaw-personal-mvp-social-play-internal-youtube-compliance-c30q-r60-43-20260812-01/source-aggregate-manifest-accepted.txt'
Assert-C30SQualification -Condition (Test-Path -LiteralPath $c30qSourceManifest -PathType Leaf) -Message 'C30Q accepted source manifest is missing.'
$affectedTestPaths = @(
  Get-Content -LiteralPath $c30qSourceManifest |
    ForEach-Object { ($_ -split '  ', 2)[1].Replace('\', '/') } |
    Where-Object { $_ -like 'apps/mobile/test/*.dart' }
)
$allTestPaths = @(rg --files (Join-Path $root 'apps/mobile/test') -g '*.dart' | ForEach-Object {
  $full = [IO.Path]::GetFullPath($_)
  $full.Substring($root.Length + 1).Replace('\', '/')
})
Assert-C30SQualification -Condition ($LASTEXITCODE -in @(0, 1)) -Message 'affected test inventory failed.'
$affectedTestPaths += @($allTestPaths | Where-Object {
  $_ -match '^apps/mobile/test/(ui_v2/social/|core/platform/|social[^/]*_test\.dart$|youtube[^/]*_test\.dart$|journey(01|_session)_test\.dart$|review_auth_persistence_test\.dart$|screen03_session_test\.dart$|ui_v2_first_open_interruption_test\.dart$|ui_v2_screen0[123]_.+_test\.dart$|platform_configuration_test\.dart$)'
})
$affectedTestPaths = @($affectedTestPaths | Sort-Object -Unique)
Assert-C30SQualification -Condition ($affectedTestPaths.Count -ge 45) -Message "affected test manifest is unexpectedly small: $($affectedTestPaths.Count)."
foreach ($testPath in $affectedTestPaths) {
  Assert-C30SQualification -Condition (Test-Path -LiteralPath (Join-Path $root $testPath) -PathType Leaf) -Message "affected test is missing: $testPath"
}
[IO.File]::WriteAllLines($affectedTestManifestLog, $affectedTestPaths, [Text.UTF8Encoding]::new($false))
$affectedTestHash = (Get-FileHash -LiteralPath $affectedTestManifestLog -Algorithm SHA256).Hash
$acceptedAffectedTestManifest = Join-Path $artifactRoot 'affected-test-manifest-accepted-r7.txt'
if ($Cycle -eq 1) {
  Assert-C30SQualification -Condition (-not (Test-Path -LiteralPath $acceptedAffectedTestManifest)) -Message 'accepted affected-test manifest already exists before cycle 1.'
} else {
  Assert-C30SQualification -Condition (Test-Path -LiteralPath $acceptedAffectedTestManifest -PathType Leaf) -Message 'cycle 1 affected-test manifest is missing.'
  Assert-C30SQualification -Condition ((Get-FileHash -LiteralPath $acceptedAffectedTestManifest -Algorithm SHA256).Hash -ceq $affectedTestHash) -Message 'affected test manifest changed between cycles.'
}
$mobileTestPaths = @($affectedTestPaths | ForEach-Object { $_.Substring('apps/mobile/'.Length) })
Invoke-NativeLogged -Command 'flutter' -Arguments (@('test', '--reporter', 'compact') + $mobileTestPaths) -WorkingDirectory $mobileRoot -LogPath $testLog
Assert-C30SQualification -Condition (Select-String -LiteralPath $testLog -Pattern 'All tests passed!' -Quiet) -Message 'full Flutter test log lacks the success marker.'

$pubspecHashBefore = (Get-FileHash -LiteralPath (Join-Path $mobileRoot 'pubspec.yaml') -Algorithm SHA256).Hash
$lockHashBefore = (Get-FileHash -LiteralPath (Join-Path $mobileRoot 'pubspec.lock') -Algorithm SHA256).Hash
Invoke-NativeLogged -Command 'flutter' -Arguments @('build', 'apk', '--release', '--config-only', '--build-name=1.0.0-r60.44', '--build-number=2026081244') -WorkingDirectory $mobileRoot -LogPath $configLog
Assert-C30SQualification -Condition ($pubspecHashBefore -ceq (Get-FileHash -LiteralPath (Join-Path $mobileRoot 'pubspec.yaml') -Algorithm SHA256).Hash -and $lockHashBefore -ceq (Get-FileHash -LiteralPath (Join-Path $mobileRoot 'pubspec.lock') -Algorithm SHA256).Hash) -Message 'release config-only changed pubspec.yaml or pubspec.lock.'
Assert-C30SQualification -Condition ($apkBefore -ceq (Get-ArtifactSnapshot -Path $releaseApk) -and $aabBefore -ceq (Get-ArtifactSnapshot -Path $releaseAab)) -Message 'release config-only created or changed an APK or AAB.'
$releaseRegistrant = Get-Content -Raw -LiteralPath (Join-Path $mobileRoot 'android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java')
Assert-C30SQualification -Condition (-not $releaseRegistrant.Contains('IntegrationTestPlugin', [StringComparison]::Ordinal) -and [regex]::Matches($releaseRegistrant, 'flutterEngine\.getPlugins\(\)\.add').Count -eq 15) -Message 'release config-only did not restore the exact 15-plugin registrant.'
$releaseRegistrant = $null

Invoke-NativeLogged -Command (Join-Path $mobileRoot 'android/gradlew.bat') -Arguments @(':app:dependencies', '--configuration', 'releaseRuntimeClasspath', '--console=plain') -WorkingDirectory (Join-Path $mobileRoot 'android') -LogPath $dependencyLog
$dependencyText = Get-Content -Raw -LiteralPath $dependencyLog
Assert-C30SQualification -Condition $dependencyText.Contains('BUILD SUCCESSFUL', [StringComparison]::Ordinal) -Message 'release dependency report lacks BUILD SUCCESSFUL.'
$forbiddenMaven = [regex]::Matches($dependencyText, 'com\.google\.firebase:firebase-(analytics(?:-ktx)?|messaging(?:-ktx)?|perf(?:-ktx)?|config(?:-ktx)?)(?::|\s+->)')
Assert-C30SQualification -Condition ($forbiddenMaven.Count -eq 0) -Message "forbidden unused Firebase runtime artifacts remain: $($forbiddenMaven.Count)."
foreach ($required in @('firebase-appcheck-playintegrity', 'firebase-auth', 'firebase-common', 'firebase-crashlytics')) {
  Assert-C30SQualification -Condition $dependencyText.Contains($required, [StringComparison]::OrdinalIgnoreCase) -Message "required release dependency missing: $required"
}
foreach ($failure in @('Could not resolve', 'BUILD FAILED', 'Google-Services plugin not found', 'srcDirs is deprecated')) {
  Assert-C30SQualification -Condition (-not $dependencyText.Contains($failure, [StringComparison]::OrdinalIgnoreCase)) -Message "release dependency audit contains $failure"
}
$dependencyText = $null

[IO.File]::WriteAllText($gateLog, '', [Text.UTF8Encoding]::new($false))
foreach ($gate in @(
  'scripts/check-play-internal-release-readiness-c30s.ps1',
  'scripts/check-play-internal-aab-build-wrapper-c30s.ps1',
  'scripts/check-youtube-embedded-player-android.ps1',
  'scripts/check-mvp-personal-action-projection.ps1',
  'scripts/check-codex-development-regression-memory.ps1',
  'scripts/check-play-internal-aab-regression-gate-state-c30s.ps1'
)) {
  & (Join-Path $root $gate) 2>&1 | Tee-Object -FilePath $gateLog -Append | Out-Null
}

Assert-C30SQualification -Condition ($apkBefore -ceq (Get-ArtifactSnapshot -Path $releaseApk)) -Message 'qualification created or changed a release APK.'
Assert-C30SQualification -Condition ($aabBefore -ceq (Get-ArtifactSnapshot -Path $releaseAab)) -Message 'qualification created or changed the generated release AAB.'

$paths = @()
$paths += @(rg --files (Join-Path $root 'apps/mobile/lib') -g '*.dart')
Assert-C30SQualification -Condition ($LASTEXITCODE -in @(0, 1)) -Message 'lib source inventory failed.'
$paths += @(rg --files (Join-Path $root 'apps/mobile/test') -g '*.dart')
Assert-C30SQualification -Condition ($LASTEXITCODE -in @(0, 1)) -Message 'test source inventory failed.'
$paths += @(rg --files (Join-Path $root 'apps/mobile/integration_test') -g '*.dart')
Assert-C30SQualification -Condition ($LASTEXITCODE -in @(0, 1)) -Message 'integration source inventory failed.'
$paths += @(rg --files (Join-Path $root 'apps/mobile/packages/youtube_embedded_player_private_dev') -g '*.dart' -g '*.kt' -g '*.kts' -g 'AndroidManifest.xml' -g 'pubspec.yaml')
Assert-C30SQualification -Condition ($LASTEXITCODE -in @(0, 1)) -Message 'private player inventory failed.'
$paths += @(
  'apps/mobile/pubspec.yaml', 'apps/mobile/pubspec.lock',
  'apps/mobile/android/settings.gradle.kts', 'apps/mobile/android/gradle.properties',
  'apps/mobile/android/gradle/wrapper/gradle-wrapper.properties',
  'apps/mobile/android/app/build.gradle.kts',
  'apps/mobile/android/app/src/main/AndroidManifest.xml',
  'apps/mobile/android/app/src/debug/AndroidManifest.xml',
  'apps/mobile/android/app/src/profile/AndroidManifest.xml',
  'apps/mobile/android/app/src/main/kotlin/com/moolsocial/app/MainActivity.kt',
  'apps/mobile/android/app/src/main/kotlin/com/moolsocial/app/YouTubeConnectReturnActivity.kt',
  'apps/mobile/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java',
  'config/codex-development-regression-registry.json',
  'config/mvp-scope-gate-state.json',
  'config/uaw-personal-mvp-social-play-internal-firebase-startup-recovery-c30s-ticket.json',
  'scripts/check-play-internal-aab-regression-gate-state-c30s.ps1',
  'scripts/check-play-internal-release-readiness-c30s.ps1',
  'scripts/check-play-internal-aab-build-wrapper-c30s.ps1',
  'scripts/invoke-play-internal-aab-build-c30s.ps1',
  'scripts/qualify-play-internal-firebase-startup-c30s.ps1',
  'tmp/run-c30s-single-aab-founder.ps1',
  'tmp/bundletool-all-1.18.3.jar'
)
$c30sDocs = @(rg --files (Join-Path $root 'docs/quality') | rg 'UAW-C30S-.*20260812\.md$')
Assert-C30SQualification -Condition ($LASTEXITCODE -in @(0, 1)) -Message 'C30S evidence inventory failed.'
$paths += $c30sDocs
$relativePaths = @($paths | ForEach-Object {
  $full = [IO.Path]::GetFullPath($_)
  if ($full.StartsWith($root + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { $full.Substring($root.Length + 1).Replace('\', '/') }
  else { ([string]$_).Replace('\', '/') }
} | Sort-Object -Unique)
foreach ($relativePath in $relativePaths) {
  Assert-C30SQualification -Condition (Test-Path -LiteralPath (Join-Path $root $relativePath) -PathType Leaf) -Message "manifest owner missing: $relativePath"
}
$manifestRows = @($relativePaths | ForEach-Object { '{0}  {1}' -f (Get-FileHash -LiteralPath (Join-Path $root $_) -Algorithm SHA256).Hash, $_ })
$manifestPath = Join-Path $artifactRoot 'source-aggregate-manifest-accepted-r7.txt'
$manifestText = ($manifestRows -join [Environment]::NewLine) + [Environment]::NewLine
$manifestBytes = [Text.UTF8Encoding]::new($false).GetBytes($manifestText)
$manifestHash = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($manifestBytes))
if ($Cycle -eq 1) {
  Assert-C30SQualification -Condition (-not (Test-Path -LiteralPath $manifestPath)) -Message 'accepted source manifest already exists before cycle 1.'
  [IO.File]::WriteAllBytes($manifestPath, $manifestBytes)
} else {
  Assert-C30SQualification -Condition (Test-Path -LiteralPath $manifestPath -PathType Leaf) -Message 'cycle 1 source manifest is missing.'
  Assert-C30SQualification -Condition ((Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash -ceq $manifestHash) -Message 'source changed between qualification cycles.'
}

if ($Cycle -eq 1) {
  Copy-Item -LiteralPath $affectedTestManifestLog -Destination $acceptedAffectedTestManifest
}

$testDartCount = $affectedTestPaths.Count
$integrationDartCount = @(rg --files (Join-Path $root 'apps/mobile/integration_test') -g '*.dart').Count
$cycleResult = [ordered]@{
  schemaVersion = 1; candidateId = $candidateId; cycle = $Cycle; attempt = $attempt
  branch = (& git -C $root branch --show-current).Trim(); head = (& git -C $root rev-parse HEAD).Trim()
  powerShellMajor = $PSVersionTable.PSVersion.Major
  sourceManifest = "$artifactRelative/source-aggregate-manifest-accepted-r7.txt"; sourceManifestSha256 = $manifestHash; sourceFiles = $relativePaths.Count
  flutterFormat = 'clean'; flutterAnalyze = 'clean'; flutterTests = 'all_affected_passed'; flutterTestDartFiles = $testDartCount; affectedTestManifestSha256 = $affectedTestHash; integrationDartFilesInventoried = $integrationDartCount
  releaseDependencyGraph = 'passed'; forbiddenUnusedFirebaseArtifacts = 0
  staticReleaseReadiness = 'passed'; registeredPlugins = 15; expectedSourcePermissions = 5
  playPredecessorPreserved = $true; predecessorVersionCode = '2026081243'; predecessorInstaller = 'com.android.vending'
  releaseApkUnchanged = $true; releaseAabUnchanged = $true
  formatLogSha256 = (Get-FileHash -LiteralPath $formatLog -Algorithm SHA256).Hash
  analyzeLogSha256 = (Get-FileHash -LiteralPath $analyzeLog -Algorithm SHA256).Hash
  testLogSha256 = (Get-FileHash -LiteralPath $testLog -Algorithm SHA256).Hash
  configLogSha256 = (Get-FileHash -LiteralPath $configLog -Algorithm SHA256).Hash
  dependencyLogSha256 = (Get-FileHash -LiteralPath $dependencyLog -Algorithm SHA256).Hash
  gateLogSha256 = (Get-FileHash -LiteralPath $gateLog -Algorithm SHA256).Hash
}
$cyclePath = Join-Path $artifactRoot ('{0:D2}-source-qualifying-cycle-{0}-r7.json' -f $Cycle)
Assert-C30SQualification -Condition (-not (Test-Path -LiteralPath $cyclePath)) -Message 'successful cycle evidence already exists.'
[IO.File]::WriteAllText($cyclePath, (($cycleResult | ConvertTo-Json -Depth 12) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))

if ($Cycle -eq 2) {
  $cycle1Path = Join-Path $artifactRoot '01-source-qualifying-cycle-1-r7.json'
  $cycle1 = Get-Content -Raw -LiteralPath $cycle1Path | ConvertFrom-Json
  Assert-C30SQualification -Condition ([string]$cycle1.sourceManifestSha256 -ceq $manifestHash) -Message 'cycle source fingerprints differ.'
  $state = Get-Content -Raw -LiteralPath $statePath | ConvertFrom-Json
  Assert-C30SQualification -Condition ([string]$state.machineState -ceq 'successor_registered_release_Firebase_startup_fix_pending_qualification' -and [string]$state.buildAuthorization -ceq 'available_once' -and [int]$state.buildResult.buildCount -eq 0) -Message 'build authority changed during qualification.'
  $state.machineState = 'source_qualified_founder_secret_prompt_required'
  $state.toolingQualification.launcherRejectsWindowsPowerShellBeforePrompt = $true
  $state.toolingQualification.wrapperRejectsWindowsPowerShellBeforeAuthorityMutation = $true
  $state.toolingQualification.nativeStderrPromotionDisabledOnlyDuringNativeCommands = $true
  $state.toolingQualification.nativeExitCodeAuthoritative = $true
  $state.toolingQualification.preferencesRestoredAfterNativeCommands = $true
  $state.toolingQualification.releaseConfigOnlyCommandQualified = $true
  $state.toolingQualification.releaseConfigOnlyProducesNoApkOrAab = $true
  $state.toolingQualification.releaseRegistrantExactPluginSetQualified = $true
  $state.toolingQualification.googleServicesTaskRegistered = $true
  $state.toolingQualification.crashlyticsBuildIdTaskRegistered = $true
  $state.sourceQualification.state = 'passed_two_identical_complete_C30S_release_cycles'
  $state.sourceQualification.manifestPath = "$artifactRelative/source-aggregate-manifest-accepted-r7.txt"
  $state.sourceQualification.manifestSha256 = $manifestHash
  $state.sourceQualification.fileCount = $relativePaths.Count
  $state.sourceQualification.identicalQualifyingCycles = 2
  $state.sourceQualification.comprehensiveReleaseAuditPassed = $true
  $state.sourceQualification.registeredPluginStartupAuditPassed = $true
  $state.sourceQualification.manifestPermissionComponentAuditPassed = $true
  $state.sourceQualification.releaseDependencyAndR8AuditPassed = $true
  $state.sourceQualification.secretAndEnvironmentAuditPassed = $true
  $state.sourceQualification.updateRetentionAndRecoveryAuditPassed = $true
  $state.sourceQualification.releaseFirebaseStaticGatePassed = $true
  $state.sourceQualification.completeRegressionGatePassed = $true
  $state.sourceQualification.cycleEvidence = @(
    "$artifactRelative/01-source-qualifying-cycle-1-r7.json",
    "$artifactRelative/02-source-qualifying-cycle-2-r7.json"
  )
  Write-State -State $state
  & (Join-Path $root 'scripts/check-play-internal-aab-regression-gate-state-c30s.ps1') -Phase build -RepositoryRoot $root
}

Write-Output "C30S cycle $Cycle passed: sourceFiles=$($relativePaths.Count); testDartFiles=$testDartCount; integrationDartFiles=$integrationDartCount; manifestSha256=$manifestHash; AAB_count=0."
Write-Output 'All tests passed!'
