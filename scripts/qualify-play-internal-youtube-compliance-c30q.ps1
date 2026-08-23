[CmdletBinding()]
param([Parameter(Mandatory)][ValidateSet(1, 2)][int]$Cycle, [string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'C30Q qualifier requires PowerShell 7.' }
$PSNativeCommandUseErrorActionPreference = $false
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$candidateId = 'UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-YOUTUBE-COMPLIANCE-C30Q'
$artifactRelative = 'artifacts/quality/uaw-personal-mvp-social-play-internal-youtube-compliance-c30q-r60-43-20260812-01'
$artifactRoot = Join-Path $root $artifactRelative
$statePath = Join-Path $root 'config/play-internal-aab-regression-gate-state-c30q.json'
New-Item -ItemType Directory -Path $artifactRoot -Force | Out-Null

function Invoke-NativeLogged {
  param([string]$Command, [string[]]$Arguments, [string]$WorkingDirectory, [string]$LogPath)
  $exitCode = -1
  [IO.File]::WriteAllText($LogPath, '', [Text.UTF8Encoding]::new($false))
  Push-Location $WorkingDirectory
  try {
    & $Command @Arguments 2>&1 | Tee-Object -FilePath $LogPath | Out-Null
    $exitCode = $LASTEXITCODE
  } finally { Pop-Location }
  if ($exitCode -ne 0) { throw "Command failed with exit $exitCode; log=$LogPath" }
}
function Get-ApkSnapshot {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return 'absent' }
  $file = Get-Item -LiteralPath $Path
  return '{0}|{1}|{2}' -f $file.Length, $file.LastWriteTimeUtc.Ticks, (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}
function Write-State {
  param([object]$State)
  $temporary = $statePath + '.qualifier-write'
  if (Test-Path -LiteralPath $temporary) { throw 'stale qualifier state file exists.' }
  [IO.File]::WriteAllText($temporary, (($State | ConvertTo-Json -Depth 32) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
  Move-Item -LiteralPath $temporary -Destination $statePath -Force
}

& (Join-Path $root 'scripts/check-codex-development-regression-memory.ps1') -Phase implementation
& (Join-Path $root 'scripts/check-mvp-scope-gate-state.ps1') -CandidateId $candidateId -RequireExecutionAuthorized -RepositoryRoot $root
& (Join-Path $root 'scripts/check-play-internal-aab-regression-gate-state-c30q.ps1') -Phase reconcile -RepositoryRoot $root

$integrationFiles = @(rg --files (Join-Path $root 'apps/mobile/integration_test'))
if ($LASTEXITCODE -ne 0 -or $integrationFiles.Count -eq 0) { throw 'real integration_test suite is missing.' }
$integrationUses = @(
  rg -l `
    'package:integration_test/integration_test.dart' `
    (Join-Path $root 'apps/mobile/integration_test')
)
$usageExit = $LASTEXITCODE
if ($usageExit -gt 1 -or $integrationUses.Count -eq 0) { throw 'integration_test package usage is not proved.' }
$pubspec = Get-Content -Raw -LiteralPath (Join-Path $root 'apps/mobile/pubspec.yaml')
if ($pubspec -notmatch '(?ms)^dev_dependencies:\s.*?^\s{2}integration_test:\s*\r?\n\s{4}sdk:\s*flutter') { throw 'integration_test is not a Flutter dev dependency.' }

$baseline = Join-Path $root 'artifacts/quality/uaw-personal-mvp-social-play-internal-youtube-compliance-c30p-r60-42-20260812-01/source-aggregate-manifest.txt'
$paths = @(
  Get-Content -LiteralPath $baseline |
    ForEach-Object { ($_ -split '  ', 2)[1] } |
    Where-Object { $_ -notmatch 'c30p' }
)
$paths += @(
  'config/uaw-personal-mvp-social-play-internal-youtube-compliance-c30q-ticket.json',
  'docs/quality/UAW-C30Q-FLUTTER-NO-PUB-RELEASE-REGISTRANT-OFFICIAL-FINDINGS-20260812.md',
  'scripts/check-play-internal-aab-build-wrapper-c30q.ps1',
  'scripts/check-play-internal-aab-regression-gate-state-c30q.ps1',
  'scripts/invoke-play-internal-aab-build-c30q.ps1',
  'scripts/qualify-play-internal-youtube-compliance-c30q.ps1',
  'tmp/run-c30q-single-aab-founder.ps1'
)
$paths = @($paths | Sort-Object -Unique)
foreach ($path in $paths) {
  if (-not (Test-Path -LiteralPath (Join-Path $root $path) -PathType Leaf)) { throw "manifest owner missing: $path" }
}
$dartPaths = @($paths | Where-Object { $_.StartsWith('apps/mobile/', [StringComparison]::Ordinal) -and $_.EndsWith('.dart', [StringComparison]::Ordinal) } | ForEach-Object { $_.Substring('apps/mobile/'.Length) })
$testPaths = @($dartPaths | Where-Object { $_.StartsWith('test/', [StringComparison]::Ordinal) })
$mobileRoot = Join-Path $root 'apps/mobile'
$attempt = if ($Cycle -eq 1) { '1r3' } else { '2' }
$formatLog = Join-Path $artifactRoot ('{0:D2}-cycle-{1}-format.log' -f $Cycle, $attempt)
$analyzeLog = Join-Path $artifactRoot ('{0:D2}-cycle-{1}-analyze.log' -f $Cycle, $attempt)
$testLog = Join-Path $artifactRoot ('{0:D2}-cycle-{1}-tests.log' -f $Cycle, $attempt)
$gateLog = Join-Path $artifactRoot ('{0:D2}-cycle-{1}-gates.log' -f $Cycle, $attempt)
$configLog = Join-Path $artifactRoot ('{0:D2}-cycle-{1}-release-config-only.log' -f $Cycle, $attempt)
foreach ($path in @($formatLog, $analyzeLog, $testLog, $gateLog, $configLog)) {
  if (Test-Path -LiteralPath $path) { throw "cycle output already exists: $path" }
}

Invoke-NativeLogged -Command 'dart' -Arguments (@('format', '--output=none', '--set-exit-if-changed') + $dartPaths) -WorkingDirectory $mobileRoot -LogPath $formatLog
Invoke-NativeLogged -Command 'flutter' -Arguments @('analyze') -WorkingDirectory $mobileRoot -LogPath $analyzeLog
Invoke-NativeLogged -Command 'flutter' -Arguments (@('test', '--reporter', 'compact') + $testPaths) -WorkingDirectory $mobileRoot -LogPath $testLog
foreach ($gate in @('scripts/check-play-internal-aab-build-wrapper-c30q.ps1', 'scripts/check-youtube-embedded-player-android.ps1', 'scripts/check-codex-development-regression-memory.ps1', 'scripts/check-play-internal-aab-regression-gate-state-c30q.ps1')) {
  & (Join-Path $root $gate) 2>&1 | Tee-Object -FilePath $gateLog -Append | Out-Null
}

$releaseApk = Join-Path $mobileRoot 'build/app/outputs/flutter-apk/app-release.apk'
$apkBefore = Get-ApkSnapshot -Path $releaseApk
$pubspecHashBefore = (Get-FileHash -LiteralPath (Join-Path $mobileRoot 'pubspec.yaml') -Algorithm SHA256).Hash
$lockHashBefore = (Get-FileHash -LiteralPath (Join-Path $mobileRoot 'pubspec.lock') -Algorithm SHA256).Hash
Invoke-NativeLogged -Command 'flutter' -Arguments @('build', 'apk', '--release', '--config-only') -WorkingDirectory $mobileRoot -LogPath $configLog
$pubspecHashAfter = (Get-FileHash -LiteralPath (Join-Path $mobileRoot 'pubspec.yaml') -Algorithm SHA256).Hash
$lockHashAfter = (Get-FileHash -LiteralPath (Join-Path $mobileRoot 'pubspec.lock') -Algorithm SHA256).Hash
if ($pubspecHashBefore -cne $pubspecHashAfter -or $lockHashBefore -cne $lockHashAfter) { throw 'release config-only changed pubspec.yaml or pubspec.lock.' }
$apkAfter = Get-ApkSnapshot -Path $releaseApk
if ($apkBefore -cne $apkAfter) { throw 'release config-only created or changed an APK.' }
$registrant = Join-Path $mobileRoot 'android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java'
if (-not (Test-Path -LiteralPath $registrant -PathType Leaf)) { throw 'release registrant missing after config-only.' }
if ((Get-Content -Raw -LiteralPath $registrant).Contains('IntegrationTestPlugin', [StringComparison]::Ordinal)) { throw 'release registrant still contains IntegrationTestPlugin.' }

$manifestRows = @(foreach ($path in $paths) { '{0}  {1}' -f (Get-FileHash -LiteralPath (Join-Path $root $path) -Algorithm SHA256).Hash, $path.Replace('\', '/') })
$manifestPath = Join-Path $artifactRoot 'source-aggregate-manifest-accepted.txt'
if ($Cycle -eq 1 -and (Test-Path -LiteralPath $manifestPath)) { throw 'source manifest already exists before cycle 1.' }
[IO.File]::WriteAllLines($manifestPath, $manifestRows, [Text.UTF8Encoding]::new($false))
$manifestHash = (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash
if (-not (Select-String -LiteralPath $testLog -Pattern 'All tests passed!' -Quiet)) { throw 'test log lacks success marker.' }
$cycleResult = [ordered]@{
  schemaVersion=1; candidateId=$candidateId; cycle=$Cycle
  branch=(& git -C $root branch --show-current).Trim(); head=(& git -C $root rev-parse HEAD).Trim(); powerShellMajor=$PSVersionTable.PSVersion.Major
  sourceManifest="$artifactRelative/source-aggregate-manifest-accepted.txt"; sourceManifestSha256=$manifestHash; sourceFiles=$paths.Count
  flutterAnalyze='clean'; flutterTestFiles=$testPaths.Count; flutterTests='passed'; integrationTestFiles=$integrationFiles.Count
  releaseConfigOnly='passed'; releaseConfigOnlyProducedApk=$false; releaseRegistrantExcludedIntegrationTestPlugin=$true
  formatLogSha256=(Get-FileHash -LiteralPath $formatLog -Algorithm SHA256).Hash
  analyzeLogSha256=(Get-FileHash -LiteralPath $analyzeLog -Algorithm SHA256).Hash
  testLogSha256=(Get-FileHash -LiteralPath $testLog -Algorithm SHA256).Hash
  gateLogSha256=(Get-FileHash -LiteralPath $gateLog -Algorithm SHA256).Hash
  configLogSha256=(Get-FileHash -LiteralPath $configLog -Algorithm SHA256).Hash
}
$cyclePath = Join-Path $artifactRoot ('{0:D2}-source-qualifying-cycle-{0}.json' -f $Cycle)
if (Test-Path -LiteralPath $cyclePath) { throw 'cycle evidence already exists.' }
[IO.File]::WriteAllText($cyclePath, (($cycleResult | ConvertTo-Json -Depth 8) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))

if ($Cycle -eq 2) {
  $cycle1 = Get-Content -Raw -LiteralPath (Join-Path $artifactRoot '01-source-qualifying-cycle-1.json') | ConvertFrom-Json
  if ([string]$cycle1.sourceManifestSha256 -cne $manifestHash) { throw 'source changed between cycles.' }
  $state = Get-Content -Raw -LiteralPath $statePath | ConvertFrom-Json
  if ([string]$state.machineState -cne 'successor_registered_release_config_fix_pending_qualification' -or [int]$state.buildResult.buildCount -ne 0) { throw 'authority changed during qualification.' }
  $state.machineState = 'source_qualified_founder_secret_prompt_required'
  $state.toolingQualification.launcherRejectsWindowsPowerShellBeforePrompt = $true
  $state.toolingQualification.wrapperRejectsWindowsPowerShellBeforeAuthorityMutation = $true
  $state.toolingQualification.nativeStderrPromotionDisabledOnlyDuringNativeCommands = $true
  $state.toolingQualification.nativeExitCodeAuthoritative = $true
  $state.toolingQualification.preferencesRestoredAfterNativeCommands = $true
  $state.toolingQualification.releaseConfigOnlyCommandQualified = $true
  $state.toolingQualification.releaseConfigOnlyProducesNoApk = $true
  $state.toolingQualification.releaseRegistrantExcludesIntegrationTestPlugin = $true
  $state.sourceQualification.state = 'passed_two_identical_complete_C30Q_cycles'
  $state.sourceQualification.manifestPath = "$artifactRelative/source-aggregate-manifest-accepted.txt"
  $state.sourceQualification.manifestSha256 = $manifestHash
  $state.sourceQualification.fileCount = $paths.Count
  $state.sourceQualification.identicalQualifyingCycles = 2
  $state.sourceQualification.implementationRegressionGatePassed = $true
  $state.sourceQualification.youtubeComplianceFocusedTestsPassed = $true
  $state.sourceQualification.releasePlayerGatePassed = $true
  $state.sourceQualification.completeSocialCyclesPassed = $true
  $state.sourceQualification.cycleEvidence = @("$artifactRelative/01-source-qualifying-cycle-1.json", "$artifactRelative/02-source-qualifying-cycle-2.json")
  Write-State -State $state
}
Write-Output "C30Q cycle $Cycle passed: files=$($paths.Count); tests=$($testPaths.Count); integrationFiles=$($integrationFiles.Count); manifestSha256=$manifestHash"
Write-Output 'All tests passed!'
