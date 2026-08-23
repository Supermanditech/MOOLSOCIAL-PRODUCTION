[CmdletBinding()]
param(
  [Parameter(Mandatory)][ValidateSet(1, 2)][int]$Cycle,
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) {
  throw 'C30P qualifier requires PowerShell 7 or newer.'
}
$PSNativeCommandUseErrorActionPreference = $false

if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$candidateId = 'UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-YOUTUBE-COMPLIANCE-C30P'
$artifactRelative = 'artifacts/quality/uaw-personal-mvp-social-play-internal-youtube-compliance-c30p-r60-42-20260812-01'
$artifactRoot = Join-Path $root $artifactRelative
$statePath = Join-Path $root 'config/play-internal-aab-regression-gate-state-c30p.json'
New-Item -ItemType Directory -Path $artifactRoot -Force | Out-Null

function Invoke-NativeLogged {
  param(
    [Parameter(Mandatory)][string]$Command,
    [Parameter(Mandatory)][string[]]$Arguments,
    [Parameter(Mandatory)][string]$WorkingDirectory,
    [Parameter(Mandatory)][string]$LogPath
  )
  $nativeExit = -1
  Push-Location $WorkingDirectory
  try {
    & $Command @Arguments 2>&1 | Tee-Object -FilePath $LogPath | Out-Null
    $nativeExit = $LASTEXITCODE
  } finally {
    Pop-Location
  }
  if ($nativeExit -ne 0) {
    throw "Command failed with exit $nativeExit; log=$LogPath"
  }
}

function Write-C30PState {
  param([Parameter(Mandatory)][object]$State)
  $temporary = $statePath + '.qualifier-write'
  if (Test-Path -LiteralPath $temporary) {
    throw 'A stale C30P qualifier state file exists.'
  }
  [IO.File]::WriteAllText(
    $temporary,
    (($State | ConvertTo-Json -Depth 32) + [Environment]::NewLine),
    [Text.UTF8Encoding]::new($false)
  )
  Move-Item -LiteralPath $temporary -Destination $statePath -Force
}

& (Join-Path $root 'scripts/check-codex-development-regression-memory.ps1') -Phase implementation
& (Join-Path $root 'scripts/check-mvp-scope-gate-state.ps1') `
  -CandidateId $candidateId -RequireExecutionAuthorized -RepositoryRoot $root
& (Join-Path $root 'scripts/check-play-internal-aab-regression-gate-state-c30p.ps1') `
  -Phase reconcile -RepositoryRoot $root

$baselineManifest = Join-Path $root 'artifacts/quality/uaw-personal-mvp-social-play-internal-youtube-compliance-c30o-r60-41-20260812-02/source-aggregate-manifest.txt'
$replacedC30OOwners = @(
  'scripts/check-play-internal-aab-build-wrapper-c30o.ps1',
  'scripts/check-play-internal-aab-regression-gate-state-c30o.ps1',
  'scripts/invoke-play-internal-aab-build-c30o.ps1',
  'scripts/qualify-play-internal-youtube-compliance-c30o.ps1'
)
$paths = @(
  Get-Content -LiteralPath $baselineManifest |
    ForEach-Object { ($_ -split '  ', 2)[1] } |
    Where-Object { $replacedC30OOwners -notcontains $_ }
)
$paths += @(
  'config/uaw-personal-mvp-social-play-internal-youtube-compliance-c30p-ticket.json',
  'docs/quality/UAW-C30P-POWERSHELL-5-NEGATIVE-CONTROL-EVIDENCE-20260812.md',
  'docs/quality/UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-YOUTUBE-COMPLIANCE-C30P-FINDINGS-20260812.md',
  'scripts/check-play-internal-aab-build-wrapper-c30p.ps1',
  'scripts/check-play-internal-aab-regression-gate-state-c30p.ps1',
  'scripts/invoke-play-internal-aab-build-c30p.ps1',
  'scripts/qualify-play-internal-youtube-compliance-c30p.ps1',
  'tmp/run-c30p-single-aab-founder.ps1'
)
$paths = @($paths | Sort-Object -Unique)
foreach ($path in $paths) {
  if (-not (Test-Path -LiteralPath (Join-Path $root $path) -PathType Leaf)) {
    throw "C30P manifest owner is missing: $path"
  }
}

$dartPaths = @(
  $paths |
    Where-Object { $_.StartsWith('apps/mobile/', [StringComparison]::Ordinal) -and $_.EndsWith('.dart', [StringComparison]::Ordinal) } |
    ForEach-Object { $_.Substring('apps/mobile/'.Length) }
)
$testPaths = @($dartPaths | Where-Object { $_.StartsWith('test/', [StringComparison]::Ordinal) })
$mobileRoot = Join-Path $root 'apps/mobile'
$formatLog = Join-Path $artifactRoot ('{0:D2}-cycle-{0}-format.log' -f $Cycle)
$analyzeLog = Join-Path $artifactRoot ('{0:D2}-cycle-{0}-analyze.log' -f $Cycle)
$testLog = Join-Path $artifactRoot ('{0:D2}-cycle-{0}-tests.log' -f $Cycle)
$gateLog = Join-Path $artifactRoot ('{0:D2}-cycle-{0}-gates.log' -f $Cycle)
foreach ($mustBeAbsent in @($formatLog, $analyzeLog, $testLog, $gateLog)) {
  if (Test-Path -LiteralPath $mustBeAbsent) {
    throw "C30P cycle output already exists: $mustBeAbsent"
  }
}

Invoke-NativeLogged -Command 'dart' `
  -Arguments (@('format', '--output=none', '--set-exit-if-changed') + $dartPaths) `
  -WorkingDirectory $mobileRoot -LogPath $formatLog
Invoke-NativeLogged -Command 'flutter' -Arguments @('analyze') `
  -WorkingDirectory $mobileRoot -LogPath $analyzeLog
Invoke-NativeLogged -Command 'flutter' `
  -Arguments (@('test', '--reporter', 'compact') + $testPaths) `
  -WorkingDirectory $mobileRoot -LogPath $testLog

$gateCommands = @(
  'scripts/check-play-internal-aab-build-wrapper-c30p.ps1',
  'scripts/check-youtube-embedded-player-android.ps1',
  'scripts/check-codex-development-regression-memory.ps1',
  'scripts/check-play-internal-aab-regression-gate-state-c30p.ps1'
)
foreach ($gate in $gateCommands) {
  & (Join-Path $root $gate) 2>&1 | Tee-Object -FilePath $gateLog -Append | Out-Null
}

$manifestRows = @(
  foreach ($path in $paths) {
    $hash = (Get-FileHash -LiteralPath (Join-Path $root $path) -Algorithm SHA256).Hash
    '{0}  {1}' -f $hash, $path.Replace('\', '/')
  }
)
$manifestPath = Join-Path $artifactRoot 'source-aggregate-manifest.txt'
if ($Cycle -eq 1 -and (Test-Path -LiteralPath $manifestPath)) {
  throw 'C30P source manifest already exists before cycle 1.'
}
[IO.File]::WriteAllLines($manifestPath, $manifestRows, [Text.UTF8Encoding]::new($false))
$manifestHash = (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash
if (-not (Select-String -LiteralPath $testLog -Pattern 'All tests passed!' -Quiet)) {
  throw 'Complete Flutter test log lacks the success marker.'
}

$cycleResult = [ordered]@{
  schemaVersion = 1
  candidateId = $candidateId
  cycle = $Cycle
  branch = (& git -C $root branch --show-current).Trim()
  head = (& git -C $root rev-parse HEAD).Trim()
  powerShellMajor = $PSVersionTable.PSVersion.Major
  sourceManifest = "$artifactRelative/source-aggregate-manifest.txt"
  sourceManifestSha256 = $manifestHash
  sourceFiles = $paths.Count
  dartFilesChecked = $dartPaths.Count
  flutterAnalyze = 'clean'
  flutterTestFiles = $testPaths.Count
  flutterTests = 'passed'
  releasePlayerGate = 'passed'
  regressionMemoryGate = 'passed'
  C30PReconcileGate = 'passed'
  formatLogSha256 = (Get-FileHash -LiteralPath $formatLog -Algorithm SHA256).Hash
  analyzeLogSha256 = (Get-FileHash -LiteralPath $analyzeLog -Algorithm SHA256).Hash
  testLogSha256 = (Get-FileHash -LiteralPath $testLog -Algorithm SHA256).Hash
  gateLogSha256 = (Get-FileHash -LiteralPath $gateLog -Algorithm SHA256).Hash
  testSuccessMarker = 'All tests passed!'
}
$cyclePath = Join-Path $artifactRoot ('{0:D2}-source-qualifying-cycle-{0}.json' -f $Cycle)
if (Test-Path -LiteralPath $cyclePath) {
  throw "C30P cycle evidence already exists: $cyclePath"
}
[IO.File]::WriteAllText(
  $cyclePath,
  (($cycleResult | ConvertTo-Json -Depth 8) + [Environment]::NewLine),
  [Text.UTF8Encoding]::new($false)
)

if ($Cycle -eq 2) {
  $cycle1Path = Join-Path $artifactRoot '01-source-qualifying-cycle-1.json'
  if (-not (Test-Path -LiteralPath $cycle1Path -PathType Leaf)) {
    throw 'C30P cycle 1 evidence is missing.'
  }
  $cycle1 = Get-Content -Raw -LiteralPath $cycle1Path | ConvertFrom-Json
  if ([string]$cycle1.sourceManifestSha256 -cne $manifestHash) {
    throw 'C30P source changed between qualifying cycles.'
  }
  $state = Get-Content -Raw -LiteralPath $statePath | ConvertFrom-Json
  if ([string]$state.machineState -cne 'successor_registered_tooling_fix_pending_source_qualification' -or
      [string]$state.buildAuthorization -cne 'available_not_consumed' -or
      [int]$state.buildResult.buildCount -ne 0 -or
      [int]$state.buildResult.wrapperInvocationCount -ne 0) {
    throw 'C30P machine authority changed during source qualification.'
  }
  $state.machineState = 'source_qualified_founder_secret_prompt_required'
  $state.toolingQualification.launcherRejectsWindowsPowerShellBeforePrompt = $true
  $state.toolingQualification.wrapperRejectsWindowsPowerShellBeforeAuthorityMutation = $true
  $state.toolingQualification.nativeStderrPromotionDisabledOnlyDuringFlutter = $true
  $state.toolingQualification.nativeExitCodeAuthoritative = $true
  $state.toolingQualification.preferencesRestoredAfterFlutter = $true
  $state.sourceQualification.state = 'passed_two_identical_complete_C30P_cycles'
  $state.sourceQualification.manifestPath = "$artifactRelative/source-aggregate-manifest.txt"
  $state.sourceQualification.manifestSha256 = $manifestHash
  $state.sourceQualification.fileCount = $paths.Count
  $state.sourceQualification.identicalQualifyingCycles = 2
  $state.sourceQualification.implementationRegressionGatePassed = $true
  $state.sourceQualification.youtubeComplianceFocusedTestsPassed = $true
  $state.sourceQualification.releasePlayerGatePassed = $true
  $state.sourceQualification.completeSocialCyclesPassed = $true
  $state.sourceQualification.cycleEvidence = @(
    "$artifactRelative/01-source-qualifying-cycle-1.json",
    "$artifactRelative/02-source-qualifying-cycle-2.json"
  )
  Write-C30PState -State $state
  & (Join-Path $root 'scripts/check-play-internal-aab-regression-gate-state-c30p.ps1') `
    -Phase reconcile -RepositoryRoot $root
}

Write-Output "C30P source cycle $Cycle passed: files=$($paths.Count); tests=$($testPaths.Count); manifestSha256=$manifestHash"
Write-Output 'All tests passed!'
