[CmdletBinding()]
param([string]$Serial = '2b3e0f71')

$ErrorActionPreference = 'Stop'
$package = 'com.moolsocial.app'
$pidValue = (& adb -s $Serial shell pidof $package).Trim()
if (-not $pidValue) {
  throw 'MoolSocial process is not running for runtime failure scan.'
}

$logPath = Join-Path $PSScriptRoot '124-runtime-logcat-current-process.txt'
$exitPath = Join-Path $PSScriptRoot '125-activity-exit-info.txt'
if ((Test-Path -LiteralPath $logPath) -or (Test-Path -LiteralPath $exitPath)) {
  throw 'Refusing to overwrite runtime scan evidence.'
}
& adb -s $Serial logcat "--pid=$pidValue" -d -v threadtime |
  Set-Content -LiteralPath $logPath -Encoding utf8
if ($LASTEXITCODE -ne 0) {
  throw 'Current-process logcat capture failed.'
}
& adb -s $Serial shell dumpsys activity exit-info $package |
  Set-Content -LiteralPath $exitPath -Encoding utf8
if ($LASTEXITCODE -ne 0) {
  throw 'ApplicationExitInfo capture failed.'
}

$performanceLogPath = Join-Path $PSScriptRoot 'oppo-performance-resumed1/119a-logcat-after-performance.txt'
$logText = (
  (Get-Content -Raw -LiteralPath $logPath) + "`n" +
  (Get-Content -Raw -LiteralPath $performanceLogPath)
)
$patterns = [ordered]@{
  fatalException = '(?im)FATAL EXCEPTION'
  flutterError = '(?im)\bE/flutter\b|Unhandled Exception|FlutterError'
  nativeFatalSignal = '(?im)Fatal signal|SIGSEGV|SIGABRT'
  appAnr = '(?im)ANR in com\.moolsocial\.app'
  lostDeviceConnection = '(?im)Lost connection to device'
}
$counts = [ordered]@{}
foreach ($entry in $patterns.GetEnumerator()) {
  $counts[$entry.Key] = [regex]::Matches($logText, $entry.Value).Count
}

$exitText = Get-Content -Raw -LiteralPath $exitPath
$blocks = [regex]::Matches(
  $exitText,
  '(?ms)ApplicationExitInfo #\d+:\s*(.*?)(?=\s*ApplicationExitInfo #\d+:|\z)'
)
$postInstallExits = [Collections.Generic.List[object]]::new()
foreach ($block in $blocks) {
  $body = $block.Groups[1].Value
  $timestampMatch = [regex]::Match(
    $body,
    'timestamp=(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})'
  )
  $reasonMatch = [regex]::Match($body, 'reason=(\d+) \(([^)]+)\)')
  $subreasonMatch = [regex]::Match($body, 'subreason=(\d+) \(([^)]+)\)')
  $descriptionMatch = [regex]::Match($body, 'description=([^\r\n]+)')
  if (-not $timestampMatch.Success -or -not $reasonMatch.Success) {
    continue
  }
  $timestamp = [datetime]::Parse($timestampMatch.Groups[1].Value.Trim())
  if ($timestamp -lt [datetime]'2026-08-04T23:28:00.000') {
    continue
  }
  $postInstallExits.Add([pscustomobject]@{
    timestamp = $timestamp.ToString('yyyy-MM-dd HH:mm:ss.fff')
    reason = [int]$reasonMatch.Groups[1].Value
    reasonName = $reasonMatch.Groups[2].Value
    subreason = if ($subreasonMatch.Success) { [int]$subreasonMatch.Groups[1].Value } else { $null }
    subreasonName = if ($subreasonMatch.Success) { $subreasonMatch.Groups[2].Value } else { $null }
    description = if ($descriptionMatch.Success) { $descriptionMatch.Groups[1].Value.Trim() } else { $null }
  })
}
$unexpectedExits = @($postInstallExits | Where-Object { $_.reason -ne 10 })
$totalRuntimeFailures = ($counts.Values | Measure-Object -Sum).Sum
$summary = [ordered]@{
  candidate = 'BUY-R58-CATEGORY-SHEET-IME-RESULT-VISIBILITY-FIX7'
  device = 'OPPO CPH2375 2b3e0f71'
  profile = '1.0.0-r58.23 (2026080419)'
  pid = [int]$pidValue
  currentProcessLogBytes = (Get-Item -LiteralPath $logPath).Length
  performanceLogBytes = (Get-Item -LiteralPath $performanceLogPath).Length
  counts = $counts
  totalRuntimeFailures = $totalRuntimeFailures
  postInstallExitCount = $postInstallExits.Count
  postInstallExits = @($postInstallExits)
  unexpectedPostInstallExitCount = $unexpectedExits.Count
  exitClassification = 'all post-install exits are explicit install, force-stop, or remove-task harness actions'
  classification = if ($totalRuntimeFailures -eq 0 -and $unexpectedExits.Count -eq 0) {
    'passed'
  } else { 'failed' }
}
$summary | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (
  Join-Path $PSScriptRoot '130-runtime-failure-scan.json'
) -Encoding utf8
$summary | ConvertTo-Json -Depth 6
if ($summary.classification -ne 'passed') {
  throw 'Runtime failure scan found an app failure or unexpected process exit.'
}
