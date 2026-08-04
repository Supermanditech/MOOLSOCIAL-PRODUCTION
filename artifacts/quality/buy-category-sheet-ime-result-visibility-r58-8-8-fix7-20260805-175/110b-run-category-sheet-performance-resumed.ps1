[CmdletBinding()]
param([string]$Serial = '2b3e0f71')

$ErrorActionPreference = 'Stop'
$outputRoot = Join-Path $PSScriptRoot 'oppo-performance-resumed1'
if (Test-Path -LiteralPath $outputRoot) {
  throw "Refusing to overwrite performance evidence: $outputRoot"
}
New-Item -ItemType Directory -Path $outputRoot | Out-Null

function Invoke-R587Adb {
  param(
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
  )
  $previousPreference = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try {
    $output = & adb -s $Serial @Arguments 2>&1
    $nativeExit = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $previousPreference
  }
  if ($nativeExit -ne 0) {
    throw "adb failed: $($Arguments -join ' ')`n$($output -join "`n")"
  }
  return $output
}

function Capture-Ui([string]$Name) {
  $remote = "/sdcard/r58_8_8_fix7_perf_$Name.xml"
  Invoke-R587Adb -Arguments @('shell', 'uiautomator', 'dump', $remote) | Out-Null
  $local = Join-Path $outputRoot "$Name.xml"
  Invoke-R587Adb -Arguments @('pull', $remote, $local) | Out-Null
  return Get-Content -Raw -LiteralPath $local
}

function Get-Bounds([string]$Xml, [string]$DescriptionPattern) {
  $match = [regex]::Match(
    $Xml,
    '<node[^>]+content-desc="' + $DescriptionPattern +
    '"[^>]+bounds="\[([0-9]+),([0-9]+)\]\[([0-9]+),([0-9]+)\]"'
  )
  if (-not $match.Success) {
    throw "No node matched: $DescriptionPattern"
  }
  return @(
    [int]$match.Groups[1].Value,
    [int]$match.Groups[2].Value,
    [int]$match.Groups[3].Value,
    [int]$match.Groups[4].Value
  )
}

function Tap-Bounds([int[]]$Bounds, [int]$WaitMilliseconds = 700) {
  Invoke-R587Adb -Arguments @(
    'shell', 'input', 'tap',
    [string]([int](($Bounds[0] + $Bounds[2]) / 2)),
    [string]([int](($Bounds[1] + $Bounds[3]) / 2))
  ) | Out-Null
  Start-Sleep -Milliseconds $WaitMilliseconds
}

function Tap([int]$X, [int]$Y, [int]$WaitMilliseconds = 700) {
  Invoke-R587Adb -Arguments @(
    'shell', 'input', 'tap', [string]$X, [string]$Y
  ) | Out-Null
  Start-Sleep -Milliseconds $WaitMilliseconds
}

$identity = (Invoke-R587Adb -Arguments @(
  'shell', 'dumpsys', 'package', 'com.moolsocial.app'
)) -join "`n"
if ($identity -notmatch 'versionName=1\.0\.0-r58\.23' -or
    $identity -notmatch 'versionCode=2026080419') {
  throw 'Installed OPPO package is not the registered R58.8.8 FIX7 profile.'
}
$scales = @(
  ((Invoke-R587Adb -Arguments @('shell', 'settings', 'get', 'global', 'window_animation_scale')) -join '').Trim(),
  ((Invoke-R587Adb -Arguments @('shell', 'settings', 'get', 'global', 'transition_animation_scale')) -join '').Trim(),
  ((Invoke-R587Adb -Arguments @('shell', 'settings', 'get', 'global', 'animator_duration_scale')) -join '').Trim()
)
if (($scales -join '/') -ne '1/1/1') {
  throw "Performance capture requires normal scales: $($scales -join '/')"
}

Invoke-R587Adb -Arguments @(
  'shell', 'am', 'force-stop', 'com.moolsocial.app'
) | Out-Null
Invoke-R587Adb -Arguments @(
  'shell', 'monkey', '-p', 'com.moolsocial.app',
  '-c', 'android.intent.category.LAUNCHER', '1'
) | Set-Content -LiteralPath (Join-Path $outputRoot '111-normal-launch.txt') -Encoding utf8
Start-Sleep -Seconds 7

$ready = Capture-Ui '112-launch-ready'
Tap-Bounds (Get-Bounds $ready 'Shop&#10;Shop')
$shop = Capture-Ui '113-shop-ready'
Tap-Bounds (Get-Bounds $shop 'Shop categories[^"]*For you')
$sheet = Capture-Ui '114-shop-category-sheet-ready'
if ($sheet -notmatch 'content-desc="Close categories"') {
  throw 'Shop category sheet was not ready before performance warm-up.'
}
Tap 360 845 650
Invoke-R587Adb -Arguments @('shell', 'input', 'text', 'shop%ssupplies') | Out-Null
Start-Sleep -Milliseconds 900
$filtered = Capture-Ui '115-shop-category-filter-ready'
if ($filtered -notmatch 'Shop category, Shop supplies' -or
    $filtered -match 'Shop category, Dairy &amp; bakery') {
  throw 'Exact category filter was not ready before performance warm-up.'
}
Invoke-R587Adb -Arguments @('shell', 'input', 'keyevent', 'BACK') | Out-Null
Start-Sleep -Milliseconds 500
Invoke-R587Adb -Arguments @('shell', 'input', 'keyevent', 'BACK') | Out-Null
Start-Sleep -Milliseconds 650

# Warm the already-qualified category-sheet route before measuring.
for ($warmPass = 1; $warmPass -le 3; $warmPass++) {
  Tap 56 385 500
  Invoke-R587Adb -Arguments @('shell', 'input', 'keyevent', 'BACK') | Out-Null
  Start-Sleep -Milliseconds 500
}
$pretrace = Capture-Ui '116-pretrace-shop-root'
if ($pretrace -notmatch 'Shop categories' -or
    $pretrace -match 'content-desc="Close categories"') {
  throw 'Pretrace state is not the exact clean Shop root.'
}

Invoke-R587Adb -Arguments @('logcat', '-c') | Out-Null
Invoke-R587Adb -Arguments @(
  'shell', 'atrace', '--async_start', '-c', '-b', '16384',
  'gfx', 'view', 'sched', 'freq', 'am', 'wm'
) | Set-Content -LiteralPath (Join-Path $outputRoot '116a-atrace-start.log') -Encoding utf8

$cycles = [Collections.Generic.List[string]]::new()
try {
  for ($cycle = 1; $cycle -le 16; $cycle++) {
    Tap 56 385 450
    Invoke-R587Adb -Arguments @('shell', 'input', 'keyevent', 'BACK') | Out-Null
    Start-Sleep -Milliseconds 450
    $cycles.Add("cycle=$cycle category_sheet_arrival_and_android_back=true")
  }
} finally {
  Invoke-R587Adb -Arguments @(
    'shell', 'atrace', '--async_stop',
    'gfx', 'view', 'sched', 'freq', 'am', 'wm'
  ) | Set-Content -LiteralPath (Join-Path $outputRoot '117-performance-atrace.txt') -Encoding utf8
}
$cycles | Set-Content -LiteralPath (Join-Path $outputRoot '118-performance-cycles.txt') -Encoding utf8

$posttrace = Capture-Ui '119-posttrace-shop-root'
if ($posttrace -notmatch 'Shop categories' -or
    $posttrace -match 'content-desc="Close categories"') {
  throw 'Posttrace state lost the exact clean Shop root.'
}
Invoke-R587Adb -Arguments @('logcat', '-d', '-v', 'threadtime') |
  Set-Content -LiteralPath (Join-Path $outputRoot '119a-logcat-after-performance.txt') -Encoding utf8
$cycles
