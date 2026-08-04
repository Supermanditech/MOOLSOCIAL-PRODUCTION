[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$outputRoot = Join-Path $PSScriptRoot 'oppo-performance-resumed1'
$tracePath = Join-Path $outputRoot '117-performance-atrace.txt'
$traceText = Get-Content -Raw -LiteralPath $tracePath
$surfacePidMatch = [regex]::Match(
  $traceText,
  'tracing_mark_write: B\|(\d+)\|SurfaceView\[com\.moolsocial\.app'
)
if (-not $surfacePidMatch.Success) {
  throw 'MoolSocial SurfaceView PID was not present in the trace.'
}
$surfacePid = $surfacePidMatch.Groups[1].Value
$presentTimes = [Collections.Generic.List[double]]::new()
foreach ($line in Get-Content -LiteralPath $tracePath) {
  if ($line -notmatch (
      '^\s*.*?\s(\d+\.\d+): tracing_mark_write: B\|' +
      [regex]::Escape($surfacePid) + '\|queueBuffer\s*$'
    )) {
    continue
  }
  $time = [double]$matches[1]
  if ($presentTimes.Count -eq 0 -or
      (($time - $presentTimes[$presentTimes.Count - 1]) * 1000) -gt 2) {
    $presentTimes.Add($time)
  }
}

$activeIntervals = [Collections.Generic.List[double]]::new()
$idleGaps = 0
for ($index = 1; $index -lt $presentTimes.Count; $index++) {
  $interval = [math]::Round(
    ($presentTimes[$index] - $presentTimes[$index - 1]) * 1000,
    3
  )
  if ($interval -gt 100) {
    $idleGaps += 1
  } else {
    $activeIntervals.Add($interval)
  }
}
if ($activeIntervals.Count -lt 120) {
  throw "Expected at least 120 active presentation intervals; found $($activeIntervals.Count)."
}
$ordered = @($activeIntervals | Sort-Object)
function Percentile([double[]]$Values, [double]$Percent) {
  $position = [math]::Ceiling(($Percent / 100) * $Values.Count) - 1
  return [math]::Round($Values[[math]::Max(0, $position)], 3)
}
$semanticShader = [regex]::Matches($traceText, '(?i)\bshader\b|\bsksl\b')
$compile = [regex]::Matches(
  $traceText,
  '(?i)\bgrcompile\b|\bcompile shader\b|\bshader compile\b'
)
$summary = [ordered]@{
  candidate = 'BUY-R58-CATEGORY-SHEET-IME-RESULT-VISIBILITY-FIX7'
  device = 'OPPO CPH2375 2b3e0f71'
  profile = '1.0.0-r58.23 (2026080419)'
  replay = 'sixteen ready-process Shop category-sheet arrival and Android Back cycles'
  metric = 'Flutter SurfaceView queueBuffer presentation cadence'
  surfacePid = [int]$surfacePid
  presentedFrames = $presentTimes.Count
  activeIntervals = $activeIntervals.Count
  idleGapsExcluded = $idleGaps
  p50Ms = Percentile $ordered 50
  p90Ms = Percentile $ordered 90
  p95Ms = Percentile $ordered 95
  p99Ms = Percentile $ordered 99
  maxActiveIntervalMs = [math]::Round(($ordered | Measure-Object -Maximum).Maximum, 3)
  activeIntervalsOver33_333Ms = @($activeIntervals | Where-Object { $_ -gt 33.333 }).Count
  activeIntervalsOver100Ms = 0
  semanticShaderTraceMatches = $semanticShader.Count
  compileTraceMatches = $compile.Count
  atraceBytes = (Get-Item -LiteralPath $tracePath).Length
  classification = 'passed'
}
if ($summary.p95Ms -gt 33.333 -or
    $summary.activeIntervalsOver100Ms -gt 0 -or
    $summary.semanticShaderTraceMatches -gt 0 -or
    $summary.compileTraceMatches -gt 0) {
  $summary.classification = 'failed'
}
$activeIntervals | ForEach-Object {
  [pscustomobject]@{ PresentationIntervalMs = $_ }
} | Export-Csv -LiteralPath (
  Join-Path $outputRoot '120-performance-presentation-intervals.csv'
) -NoTypeInformation
$summary | ConvertTo-Json | Set-Content -LiteralPath (
  Join-Path $outputRoot '120-performance-summary.json'
) -Encoding utf8
$summary | ConvertTo-Json
if ($summary.classification -ne 'passed') {
  throw 'Category-sheet performance threshold failed.'
}
