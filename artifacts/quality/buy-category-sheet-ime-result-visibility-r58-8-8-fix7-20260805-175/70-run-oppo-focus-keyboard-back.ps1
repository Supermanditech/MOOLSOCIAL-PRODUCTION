[CmdletBinding()]
param([string]$Serial = '2b3e0f71')

$ErrorActionPreference = 'Stop'
$root = Join-Path $PSScriptRoot 'oppo-focus-keyboard-back-normal'
if (Test-Path -LiteralPath $root) {
  throw "Refusing to overwrite focus/keyboard/Back evidence: $root"
}
New-Item -ItemType Directory -Path $root | Out-Null
$package = 'com.moolsocial.app'

function Invoke-DeviceAdb {
  param([Parameter(Mandatory)][string[]]$Arguments)
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

function Get-Ui([string]$RemoteName) {
  for ($attempt = 1; $attempt -le 8; $attempt++) {
    try {
      Invoke-DeviceAdb -Arguments @(
        'shell', 'uiautomator', 'dump', $RemoteName
      ) | Out-Null
      $raw = (
        Invoke-DeviceAdb -Arguments @('shell', 'cat', $RemoteName)
      ) -join ''
      if ($raw.Contains('<hierarchy')) { return [xml]$raw }
    } catch {
      if ($attempt -eq 8) { throw }
    }
    Start-Sleep -Milliseconds 600
  }
  throw "No readable UI hierarchy: $RemoteName"
}

function Get-Bounds($Node, [string]$Label) {
  if ($null -eq $Node) { throw "Missing node: $Label" }
  $match = [regex]::Match(
    $Node.GetAttribute('bounds'),
    '\[(\d+),(\d+)\]\[(\d+),(\d+)\]'
  )
  if (-not $match.Success) { throw "Invalid bounds: $Label" }
  return [pscustomobject]@{
    left = [int]$match.Groups[1].Value
    top = [int]$match.Groups[2].Value
    right = [int]$match.Groups[3].Value
    bottom = [int]$match.Groups[4].Value
  }
}

function Tap-Node($Node, [string]$Label) {
  $bounds = Get-Bounds $Node $Label
  Invoke-DeviceAdb -Arguments @(
    'shell', 'input', 'tap',
    [string]([int](($bounds.left + $bounds.right) / 2)),
    [string]([int](($bounds.top + $bounds.bottom) / 2))
  ) | Out-Null
  Start-Sleep -Milliseconds 850
}

function Find-Description($Ui, [string]$Pattern, [string]$Label) {
  $node = $Ui.SelectNodes('//node') |
    Where-Object {
      $_.GetAttribute('content-desc') -match $Pattern -and
      $_.GetAttribute('bounds') -ne '[0,0][0,0]'
    } |
    Select-Object -First 1
  if ($null -eq $node) { throw "Missing description: $Label" }
  return $node
}

function Save-State([string]$Name) {
  $remotePng = "/sdcard/r58-fix7-$Name.png"
  $remoteXml = "/sdcard/r58-fix7-$Name.xml"
  Invoke-DeviceAdb -Arguments @(
    'shell', 'screencap', '-p', $remotePng
  ) | Out-Null
  Invoke-DeviceAdb -Arguments @(
    'shell', 'uiautomator', 'dump', $remoteXml
  ) | Out-Null
  Invoke-DeviceAdb -Arguments @(
    'pull', $remotePng, (Join-Path $root "$Name.png")
  ) | Out-Null
  Invoke-DeviceAdb -Arguments @(
    'pull', $remoteXml, (Join-Path $root "$Name.xml")
  ) | Out-Null
  Invoke-DeviceAdb -Arguments @('shell', 'dumpsys', 'window') |
    Set-Content -LiteralPath (Join-Path $root "$Name-window.txt") -Encoding utf8
  return Get-Content -Raw -LiteralPath (Join-Path $root "$Name.xml")
}

function Get-ImeTop([string]$WindowPath) {
  $line = Select-String -LiteralPath $WindowPath -Pattern (
    'InsetsSource type=ITYPE_IME frame=\[0,(\d+)\]' +
    '.*visible=true'
  ) | Select-Object -First 1
  if ($null -eq $line) { return $null }
  return [int]([regex]::Match(
    $line.Line,
    'ITYPE_IME frame=\[0,(\d+)\]'
  ).Groups[1].Value)
}

function Wait-ForDescription([string]$Pattern, [string]$Label) {
  for ($attempt = 1; $attempt -le 20; $attempt++) {
    $ui = Get-Ui "/sdcard/r58-fix7-wait-$attempt.xml"
    $node = $ui.SelectNodes('//node') |
      Where-Object {
        $_.GetAttribute('content-desc') -match $Pattern -and
        $_.GetAttribute('bounds') -ne '[0,0][0,0]'
      } |
      Select-Object -First 1
    if ($null -ne $node) { return $ui }
    Start-Sleep -Milliseconds 500
  }
  throw "Timed out waiting for $Label"
}

$identity = (
  Invoke-DeviceAdb -Arguments @('shell', 'dumpsys', 'package', $package)
) -join "`n"
if ($identity -notmatch 'versionName=1\.0\.0-r58\.23' -or
    $identity -notmatch 'versionCode=2026080419') {
  throw 'Focus/keyboard/Back harness requires checksum-matched r58.23.'
}
$scales = @(
  ((Invoke-DeviceAdb -Arguments @('shell', 'settings', 'get', 'global', 'window_animation_scale')) -join '').Trim(),
  ((Invoke-DeviceAdb -Arguments @('shell', 'settings', 'get', 'global', 'transition_animation_scale')) -join '').Trim(),
  ((Invoke-DeviceAdb -Arguments @('shell', 'settings', 'get', 'global', 'animator_duration_scale')) -join '').Trim()
)
if (($scales -join '/') -cne '1/1/1') {
  throw "Harness requires normal animation scales: $($scales -join '/')"
}

Invoke-DeviceAdb -Arguments @('shell', 'am', 'force-stop', $package) | Out-Null
Start-Sleep -Milliseconds 700
Invoke-DeviceAdb -Arguments @(
  'shell', 'monkey', '-p', $package,
  '-c', 'android.intent.category.LAUNCHER', '1'
) | Out-Null
$ui = Wait-ForDescription 'Shop\nShop' 'Shop destination'
Tap-Node (Find-Description $ui 'Shop\nShop' 'Shop destination') 'Shop destination'
$ui = Wait-ForDescription 'Shop categories' 'Shop category picker'
Tap-Node (Find-Description $ui 'Shop categories' 'Shop category picker') 'Shop category picker'
$ui = Wait-ForDescription '^Shop categories$' 'Shop category sheet'
$edit = $ui.SelectSingleNode('//node[@class="android.widget.EditText"]')
Tap-Node $edit 'Category search'
Invoke-DeviceAdb -Arguments @(
  'shell', 'input', 'text', 'shop%ssupplies'
) | Out-Null
Start-Sleep -Milliseconds 900

$focused = Save-State '71-focused-filtered'
[xml]$focusedUi = $focused
$target = Find-Description `
  $focusedUi 'Shop category, Shop supplies' 'Shop supplies filtered result'
$targetBounds = Get-Bounds $target 'Shop supplies filtered result'
$focusedImeTop = Get-ImeTop (Join-Path $root '71-focused-filtered-window.txt')
if ($null -eq $focusedImeTop -or $targetBounds.bottom -gt $focusedImeTop) {
  throw 'Focused filtered result was not clear of the visible IME.'
}

Invoke-DeviceAdb -Arguments @('shell', 'input', 'keyevent', 'BACK') | Out-Null
Start-Sleep -Milliseconds 850
$hidden = Save-State '72-keyboard-hidden-same-sheet'
[xml]$hiddenUi = $hidden
if ($null -eq $hiddenUi.SelectSingleNode('//node[@class="android.widget.EditText" and @text="shop supplies"]')) {
  throw 'Keyboard hide lost the query or sheet focus owner.'
}
if ($hidden -notmatch 'Shop category, Shop supplies') {
  throw 'Keyboard hide lost the filtered result.'
}
$hiddenImeTop = Get-ImeTop (Join-Path $root '72-keyboard-hidden-same-sheet-window.txt')
if ($null -ne $hiddenImeTop) { throw 'IME remained visible after Android Back.' }

$edit = $hiddenUi.SelectSingleNode('//node[@class="android.widget.EditText"]')
Tap-Node $edit 'Category search refocus'
Start-Sleep -Milliseconds 850
$refocused = Save-State '73-refocused-filtered'
[xml]$refocusedUi = $refocused
$target = Find-Description `
  $refocusedUi 'Shop category, Shop supplies' 'Refocused result'
$refocusedBounds = Get-Bounds $target 'Refocused result'
$refocusedImeTop = Get-ImeTop (Join-Path $root '73-refocused-filtered-window.txt')
if ($null -eq $refocusedImeTop -or $refocusedBounds.bottom -gt $refocusedImeTop) {
  throw 'Refocused filtered result was not clear of the visible IME.'
}

$close = Find-Description $refocusedUi '^Close categories$' 'Close categories'
Tap-Node $close 'Close categories'
$ui = Wait-ForDescription 'Shop categories' 'Shop root after Close'
$closed = Save-State '74-close-returned-shop-root'
if ($closed -match 'Close categories') { throw 'Close did not dismiss the sheet.' }

Tap-Node (Find-Description $ui 'Shop categories' 'Shop category picker') 'Shop category picker'
Wait-ForDescription '^Shop categories$' 'Reopened category sheet' | Out-Null
Invoke-DeviceAdb -Arguments @('shell', 'input', 'keyevent', 'BACK') | Out-Null
$ui = Wait-ForDescription 'Shop categories' 'Shop root after sheet Back'
$back = Save-State '75-android-back-returned-shop-root'
if ($back -match 'Close categories') { throw 'Android Back did not dismiss the sheet.' }

@(
  'state=passed',
  'candidate=BUY-R58-CATEGORY-SHEET-IME-RESULT-VISIBILITY-FIX7',
  'profile=1.0.0-r58.23 (2026080419)',
  'scales=1/1/1',
  "focusedTargetBottom=$($targetBounds.bottom)",
  "focusedImeTop=$focusedImeTop",
  "focusedClearance=$($focusedImeTop - $targetBounds.bottom)",
  'keyboardHideSameSheet=passed',
  'queryPreservedAfterKeyboardHide=passed',
  "refocusedTargetBottom=$($refocusedBounds.bottom)",
  "refocusedImeTop=$refocusedImeTop",
  "refocusedClearance=$($refocusedImeTop - $refocusedBounds.bottom)",
  'explicitClose=passed',
  'androidBack=passed',
  'finalState=clean Shop root'
) | Set-Content -LiteralPath (Join-Path $root '90-focus-keyboard-back-assertions.txt') -Encoding utf8

Write-Output 'R58.8.8 FIX7 focus, keyboard, Close and Back qualification passed.'
