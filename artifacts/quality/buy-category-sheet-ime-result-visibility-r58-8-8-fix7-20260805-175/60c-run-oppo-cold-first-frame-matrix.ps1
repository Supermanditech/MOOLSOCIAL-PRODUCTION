[CmdletBinding()]
param([string]$Serial = '2b3e0f71')

$ErrorActionPreference = 'Stop'
$root = Join-Path $PSScriptRoot 'oppo-cold-first-frame-matrix-normal-harness3'
if (Test-Path -LiteralPath $root) {
  throw "Refusing to overwrite cold first-frame evidence: $root"
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
  for ($attempt = 1; $attempt -le 6; $attempt++) {
    try {
      Invoke-DeviceAdb -Arguments @(
        'shell', 'uiautomator', 'dump', $RemoteName
      ) | Out-Null
      $raw = (
        Invoke-DeviceAdb -Arguments @('shell', 'cat', $RemoteName)
      ) -join ''
      if ($raw.Contains('<hierarchy')) {
        return [xml]$raw
      }
    } catch {
      if ($attempt -eq 6) { throw }
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
  $bounds = Get-Bounds -Node $Node -Label $Label
  $x = [int](($bounds.left + $bounds.right) / 2)
  $y = [int](($bounds.top + $bounds.bottom) / 2)
  Invoke-DeviceAdb -Arguments @(
    'shell', 'input', 'tap', "$x", "$y"
  ) | Out-Null
  Start-Sleep -Milliseconds 850
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
}

function Get-ImeTop([string]$WindowPath) {
  $line = Select-String -LiteralPath $WindowPath -Pattern (
    'InsetsSource type=ITYPE_IME frame=\[0,(\d+)\]\[\d+,\d+\] ' +
    'visibleFrame=.* visible=true'
  ) | Select-Object -First 1
  if ($null -eq $line) { throw "Visible IME frame missing: $WindowPath" }
  $match = [regex]::Match($line.Line, 'ITYPE_IME frame=\[0,(\d+)\]')
  if (-not $match.Success) { throw "IME top parse failed: $WindowPath" }
  return [int]$match.Groups[1].Value
}

function Wait-DestinationRoot([string]$Destination) {
  for ($attempt = 1; $attempt -le 15; $attempt++) {
    Start-Sleep -Seconds 1
    $ui = Get-Ui -RemoteName (
      "/sdcard/r58-fix7-$Destination-ready-$attempt.xml"
    )
    $owner = $ui.SelectNodes('//node') |
      Where-Object {
        if ($_.GetAttribute('clickable') -ne 'true') { return $false }
        if (-not $_.GetAttribute('content-desc').Contains($Destination)) {
          return $false
        }
        $bounds = Get-Bounds -Node $_ -Label "$Destination readiness"
        return $bounds.top -ge 1300
      } |
      Select-Object -First 1
    if ($null -ne $owner) {
      return $ui
    }
  }
  throw "$Destination bottom destination did not become ready."
}

$identity = (
  Invoke-DeviceAdb -Arguments @('shell', 'dumpsys', 'package', $package)
) -join "`n"
if ($identity -notmatch 'versionName=1\.0\.0-r58\.23' -or
    $identity -notmatch 'versionCode=2026080419') {
  throw 'Cold matrix requires checksum-matched r58.23.'
}
$scales = @(
  (Invoke-DeviceAdb -Arguments @(
    'shell', 'settings', 'get', 'global', 'window_animation_scale'
  ) | Select-Object -First 1).Trim(),
  (Invoke-DeviceAdb -Arguments @(
    'shell', 'settings', 'get', 'global', 'transition_animation_scale'
  ) | Select-Object -First 1).Trim(),
  (Invoke-DeviceAdb -Arguments @(
    'shell', 'settings', 'get', 'global', 'animator_duration_scale'
  ) | Select-Object -First 1).Trim()
)
if (($scales -join '/') -cne '1/1/1') {
  throw "Cold matrix requires normal animation scales: $($scales -join '/')"
}

$cases = @(
  [pscustomobject]@{ destination = 'Shop'; query = 'shop supplies'; label = 'Shop supplies' },
  [pscustomobject]@{ destination = 'Wholesale'; query = 'retail supplies'; label = 'Retail supplies' },
  [pscustomobject]@{ destination = 'Medicine'; query = 'diabetes'; label = 'Diabetes' }
)
$assertions = [Collections.Generic.List[string]]::new()
$assertions.Add('state=passed')
$assertions.Add('candidate=BUY-R58-CATEGORY-SHEET-IME-RESULT-VISIBILITY-FIX7')
$assertions.Add('profile=1.0.0-r58.23 (2026080419)')
$assertions.Add('scales=1/1/1')

foreach ($case in $cases) {
  Invoke-DeviceAdb -Arguments @('shell', 'am', 'force-stop', $package) | Out-Null
  Start-Sleep -Milliseconds 700
  Invoke-DeviceAdb -Arguments @(
    'shell', 'monkey', '-p', $package,
    '-c', 'android.intent.category.LAUNCHER', '1'
  ) | Out-Null
  $ui = Wait-DestinationRoot -Destination $case.destination
  $destinationNode = $ui.SelectNodes('//node') |
    Where-Object {
      if ($_.GetAttribute('clickable') -ne 'true') { return $false }
      $description = $_.GetAttribute('content-desc')
      if (-not $description.Contains($case.destination)) { return $false }
      $bounds = Get-Bounds -Node $_ -Label "$($case.destination) destination"
      return $bounds.top -ge 1300
    } |
    Select-Object -First 1
  Tap-Node -Node $destinationNode -Label "$($case.destination) destination"
  $ui = Get-Ui -RemoteName "/sdcard/r58-fix7-$($case.destination)-selected.xml"
  $picker = $ui.SelectNodes('//node') |
    Where-Object {
      $_.GetAttribute('clickable') -eq 'true' -and
      $_.GetAttribute('content-desc').Contains("$($case.destination) categories") -and
      $_.GetAttribute('bounds') -ne '[0,0][0,0]'
    } |
    Select-Object -First 1
  Tap-Node -Node $picker -Label "$($case.destination) category picker"
  $ui = Get-Ui -RemoteName "/sdcard/r58-fix7-$($case.destination)-sheet.xml"
  $edit = $ui.SelectSingleNode('//node[@class="android.widget.EditText"]')
  Tap-Node -Node $edit -Label "$($case.destination) category search"
  $encoded = $case.query.Replace(' ', '%s')
  Invoke-DeviceAdb -Arguments @('shell', 'input', 'text', $encoded) | Out-Null

  foreach ($second in 1..3) {
    Start-Sleep -Seconds 1
    $name = "$($case.destination.ToLowerInvariant())-$second-second"
    Save-State -Name $name
    [xml]$captured = Get-Content -Raw -LiteralPath (Join-Path $root "$name.xml")
    $target = $captured.SelectNodes('//node') |
      Where-Object {
        $_.GetAttribute('content-desc').Contains(
          "$($case.destination) category, $($case.label)"
        )
      } |
      Select-Object -First 1
    $targetBounds = Get-Bounds -Node $target -Label "$name target"
    $imeTop = Get-ImeTop -WindowPath (Join-Path $root "$name-window.txt")
    if ($targetBounds.bottom -gt $imeTop) {
      throw "$name target bottom $($targetBounds.bottom) exceeds IME top $imeTop"
    }
    $assertions.Add(
      "$name=passed target=$($targetBounds.left),$($targetBounds.top)," +
      "$($targetBounds.right),$($targetBounds.bottom) imeTop=$imeTop " +
      "clearance=$($imeTop - $targetBounds.bottom)"
    )
  }
}

Invoke-DeviceAdb -Arguments @('shell', 'am', 'force-stop', $package) | Out-Null
Start-Sleep -Milliseconds 700
Invoke-DeviceAdb -Arguments @(
  'shell', 'monkey', '-p', $package,
  '-c', 'android.intent.category.LAUNCHER', '1'
) | Out-Null
$ui = Wait-DestinationRoot -Destination 'Shop'
$shopNode = $ui.SelectNodes('//node') |
  Where-Object {
    if ($_.GetAttribute('clickable') -ne 'true') { return $false }
    if (-not $_.GetAttribute('content-desc').Contains('Shop')) { return $false }
    $bounds = Get-Bounds -Node $_ -Label 'final Shop destination'
    return $bounds.top -ge 1300
  } |
  Select-Object -First 1
Tap-Node -Node $shopNode -Label 'final Shop destination'
Save-State -Name 'final-clean-shop'
$assertions.Add('processRecreation=passed_all_three')
$assertions.Add('finalState=clean Shop root')
$assertions | Set-Content -LiteralPath (
  Join-Path $root '90-cold-first-frame-assertions.txt'
) -Encoding utf8
Write-Output 'R58.8.8 FIX7 cold first-frame matrix passed.'
