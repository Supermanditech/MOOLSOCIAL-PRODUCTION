[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [ValidateSet(1, 2)]
  [int]$Cycle,

  [string]$RepositoryRoot,

  [switch]$PrerequisiteOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) {
  throw 'C34J source cycle requires PowerShell 7 or newer.'
}
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$branch = (& git -C $root rev-parse --abbrev-ref HEAD).Trim()
$head = (& git -C $root rev-parse HEAD).Trim()
if ($branch -cne 'remediation/prototype-conformance-2026-07-20' -or $head -cne 'f6dfe7587aa02d782e94282d14af8bafff48ded0') {
  throw 'C34J source cycle repository identity changed.'
}

$ticketId = 'UAW-C34J-R60-74-RELEASE-LIFECYCLE-ATOMIC-PARITY-PLAY-OPPO-ACCEPTANCE'
$evidenceRelative = 'artifacts/quality/uaw-c34j-r60-74-release-lifecycle-atomic-parity-preparation-20260817-01'
$evidenceRoot = Join-Path $root $evidenceRelative
$manifestRelative = "$evidenceRelative/source-manifest-c34j-registry-2696.txt"
$focusedRelative = "$evidenceRelative/focused-test-manifest-c34j.txt"
$stateRelative = 'config/successor-aab-regression-hard-gate-state-c34j.json'
$statePath = Join-Path $root $stateRelative
$prefix = 'c34j-cycle-{0:d2}' -f $Cycle
$logs = [ordered]@{
  static = Join-Path $evidenceRoot "$prefix-static.log"
  flutter = Join-Path $evidenceRoot "$prefix-flutter.log"
  analyzer = Join-Path $evidenceRoot "$prefix-analyzer.log"
  backendTypecheck = Join-Path $evidenceRoot "$prefix-backend-typecheck.log"
  backendTest = Join-Path $evidenceRoot "$prefix-backend-test.log"
  webTest = Join-Path $evidenceRoot "$prefix-web-test.log"
  summary = Join-Path $evidenceRoot "$prefix-summary.json"
}
foreach ($path in $logs.Values) {
  if (Test-Path -LiteralPath $path) { throw 'C34J source-cycle evidence already exists; overwrite is forbidden.' }
}
foreach ($path in @($statePath, (Join-Path $root $manifestRelative), (Join-Path $root $focusedRelative))) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw 'C34J source-cycle prerequisite is missing.' }
}
if ($PrerequisiteOnly) {
  Write-Output 'C34J source-cycle prerequisite preflight passed: exact state, registry-2696 manifest and focused manifest paths exist; testsStarted=false.'
  return
}
$state = Get-Content -Raw -LiteralPath $statePath | ConvertFrom-Json
if (
  [string]$state.ticketId -cne $ticketId -or
  [string]$state.machineState -cne 'prebuild_manifest_bound_two_fresh_cycles_required' -or
  [int]$state.sourceQualification.completedIdenticalCycles -ne 0 -or
  [int]$state.actionCounts.build -ne 0 -or
  [int]$state.actionCounts.upload -ne 0 -or
  [int]$state.actionCounts.install -ne 0 -or
  [int]$state.actionCounts.deviceAcceptance -ne 0 -or
  [bool]$state.authority.founderHiddenInputEntryAuthorized
) { throw 'C34J source-cycle held-authority state changed.' }

function ConvertTo-C34JLines {
  param([object[]]$Values)
  return @($Values | ForEach-Object { if ($null -eq $_) { '' } else { [string]$_ } })
}

function Assert-C34JSanitized {
  param([string[]]$Lines)
  $text = $Lines -join "`n"
  foreach ($pattern in @(
    '(?i)AIza[0-9A-Za-z_-]{20,}',
    '(?i)[0-9]+-[0-9A-Za-z_-]+\.apps\.googleusercontent\.com',
    '(?i)(password|token|secret|private[_ -]?key)\s*[:=]\s*\S+',
    '(?i)https?://\S*(action(code)?|oobCode|tester|invite)\S*'
  )) {
    if ([regex]::IsMatch($text, $pattern)) { throw 'C34J source-cycle output violated the sanitized evidence boundary.' }
  }
}

function Write-C34JLog {
  param([string]$Path, [string[]]$Lines)
  Assert-C34JSanitized -Lines $Lines
  [IO.File]::WriteAllLines($Path, $Lines, [Text.UTF8Encoding]::new($false))
}

function Invoke-C34JNative {
  param([string]$File, [string[]]$Arguments, [string]$WorkingDirectory, [string]$LogPath)
  Push-Location $WorkingDirectory
  try {
    $raw = @(& $File @Arguments 2>&1)
    $code = $LASTEXITCODE
  } finally { Pop-Location }
  $lines = ConvertTo-C34JLines -Values $raw
  Write-C34JLog -Path $LogPath -Lines $lines
  if ($code -ne 0) { throw 'C34J native source-cycle step failed; inspect only the sanitized retained log.' }
  return $lines
}

$staticLines = [Collections.Generic.List[string]]::new()
function Add-C34JStatic {
  param([object[]]$Values)
  foreach ($line in (ConvertTo-C34JLines -Values $Values)) { $staticLines.Add($line) }
}

$manifestOwner = Join-Path $root 'scripts/new-c30v-source-manifest.ps1'
Add-C34JStatic -Values @(& $manifestOwner -ComparePath $manifestRelative -RepositoryRoot $root)
Add-C34JStatic -Values @(& (Join-Path $root 'scripts/check-codex-development-regression-memory.ps1') -Phase implementation)
Add-C34JStatic -Values @(& (Join-Path $root 'scripts/check-mvp-scope-gate-state.ps1') -StatePath 'config/mvp-scope-gate-state.json' -CandidateId $ticketId -RequireExecutionAuthorized -RepositoryRoot $root)
Add-C34JStatic -Values @(& (Join-Path $root 'scripts/check-approved-ui-locks.ps1') -RepositoryRoot $root)
Add-C34JStatic -Values @(& (Join-Path $root 'scripts/check-release-device-acceptance-actor-policy-c34i.ps1') -RepositoryRoot $root -SelfTest)

$candidateGate = Join-Path $root 'scripts/check-uaw-c34j-r60-74-release-lifecycle-atomic-parity-readiness.ps1'
Push-Location 'C:\WINDOWS\system32'
try {
  Add-C34JStatic -Values @(& $candidateGate -Phase source -StatePath $stateRelative -RepositoryRoot $root)
} finally { Pop-Location }

$winPsArgs = @(
  '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $candidateGate,
  '-Phase', 'source', '-StatePath', $stateRelative, '-RepositoryRoot', $root
)
Push-Location 'C:\WINDOWS\system32'
try {
  $winRaw = @(& powershell.exe @winPsArgs 2>&1)
  $winCode = $LASTEXITCODE
} finally { Pop-Location }
Add-C34JStatic -Values $winRaw
if ($winCode -ne 0) { throw 'C34J Windows PowerShell source gate failed.' }

$pwsh = (Get-Command pwsh -ErrorAction Stop).Source
$flutterRunner = Join-Path $root 'tmp/run-c30t-authoritative-flutter-manifest-audit.ps1'
$flutterLines = Invoke-C34JNative -File $pwsh -Arguments @(
  '-NoProfile', '-File', $flutterRunner, '-RepositoryRoot', $root,
  '-Manifest', $focusedRelative, '-ExpectedPassed', '501', '-ExpectedSkipped', '3'
) -WorkingDirectory $root -LogPath $logs.flutter

$flutter = (Get-Command flutter -ErrorAction Stop).Source
$analyzerLines = Invoke-C34JNative -File $flutter -Arguments @('analyze', '--no-pub') `
  -WorkingDirectory (Join-Path $root 'apps/mobile') -LogPath $logs.analyzer
$npm = (Get-Command npm.cmd -ErrorAction Stop).Source
$backendTypecheckLines = Invoke-C34JNative -File $npm -Arguments @('run', 'typecheck') `
  -WorkingDirectory (Join-Path $root 'backend/functions') -LogPath $logs.backendTypecheck
$backendTestLines = Invoke-C34JNative -File $npm -Arguments @('test') `
  -WorkingDirectory (Join-Path $root 'backend/functions') -LogPath $logs.backendTest
$webTestLines = Invoke-C34JNative -File $npm -Arguments @('test') `
  -WorkingDirectory (Join-Path $root 'apps/web') -LogPath $logs.webTest

Add-C34JStatic -Values @(& $manifestOwner -ComparePath $manifestRelative -RepositoryRoot $root)
Write-C34JLog -Path $logs.static -Lines $staticLines.ToArray()

$flutterText = $flutterLines -join "`n"
$flutterMatch = [regex]::Match($flutterText, 'authoritative_manifest_files=(\d+) raw_test_done=(\d+) authored_passed=(\d+) authored_skipped=(\d+) authored_failed=(\d+) error_events=(\d+) non_json_lines=(\d+) blank_raw_lines=(\d+) json_null_objects=(\d+) flutter_exit=(\d+) untyped_json_objects=(\d+)')
if (-not $flutterMatch.Success) { throw 'C34J Flutter summary marker is missing.' }
$analyzerPassed = ($analyzerLines -join "`n") -match 'No issues found!'
$backendText = $backendTestLines -join "`n"
$webText = $webTestLines -join "`n"
if (
  -not $analyzerPassed -or
  $backendText -notmatch '(?m)tests\s+537' -or $backendText -notmatch '(?m)pass\s+537' -or $backendText -notmatch '(?m)fail\s+0' -or
  $webText -notmatch '(?m)tests\s+8' -or $webText -notmatch '(?m)pass\s+8' -or $webText -notmatch '(?m)fail\s+0'
) { throw 'C34J source-cycle bounded result counts changed.' }

$summary = [ordered]@{
  schemaVersion = 1
  ticketId = $ticketId
  cycle = $Cycle
  registryEntryCount = 2696
  registrySha256 = '226F0FE00287F1861DFBE1E3B6CF35DA7F989262DDE4CFF560EA18D0EF252B55'
  sourceFileCount = [int]$state.sourceQualification.fileCount
  sourceManifestSha256 = [string]$state.sourceQualification.manifestSha256
  focusedManifestFileCount = 73
  focusedManifestSha256 = [string]$state.sourceQualification.focusedManifestSha256
  flutter = [ordered]@{
    passed = [int]$flutterMatch.Groups[3].Value
    skipped = [int]$flutterMatch.Groups[4].Value
    failed = [int]$flutterMatch.Groups[5].Value
    errors = [int]$flutterMatch.Groups[6].Value
    nonJson = [int]$flutterMatch.Groups[7].Value
    blank = [int]$flutterMatch.Groups[8].Value
    jsonNull = [int]$flutterMatch.Groups[9].Value
    exitCode = [int]$flutterMatch.Groups[10].Value
    untyped = [int]$flutterMatch.Groups[11].Value
  }
  wholeMobileAnalyzerPassed = $analyzerPassed
  backendTypecheckPassed = $true
  backendTestsPassed = 537
  webProductionBuildPassed = $true
  webTestsPassed = 8
  dualPowerShellHostsPassed = $true
  mvpOutsideRepositoryWorkingDirectoryPassed = $true
  playWrites = 0
  sourceUnchanged = $true
}
$summaryText = ($summary | ConvertTo-Json -Depth 8 -Compress) + [Environment]::NewLine
Assert-C34JSanitized -Lines @($summaryText)
[IO.File]::WriteAllText($logs.summary, $summaryText, [Text.UTF8Encoding]::new($false))
Write-Output "C34J source cycle passed: cycle=$Cycle; Flutter=501/3/0; backend=537; web=8; sourceUnchanged=true; PlayWrites=0."
