[CmdletBinding()]
param([string]$Serial = '2b3e0f71')

$ErrorActionPreference = 'Stop'
$root = Join-Path $PSScriptRoot 'oppo-reduced-motion'
if (Test-Path -LiteralPath $root) {
  throw "Refusing to overwrite reduced-motion harness7 evidence: $root"
}
New-Item -ItemType Directory -Path $root | Out-Null

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

function Save-State([string]$Name) {
  $remotePng = "/sdcard/$Name.png"
  $remoteXml = "/sdcard/$Name.xml"
  Invoke-R587Adb -Arguments @('shell', 'screencap', '-p', $remotePng) | Out-Null
  Invoke-R587Adb -Arguments @('shell', 'uiautomator', 'dump', $remoteXml) | Out-Null
  Invoke-R587Adb -Arguments @('pull', $remotePng, (Join-Path $root "$Name.png")) | Out-Null
  Invoke-R587Adb -Arguments @('pull', $remoteXml, (Join-Path $root "$Name.xml")) | Out-Null
  return Get-Content -Raw -LiteralPath (Join-Path $root "$Name.xml")
}

function Get-LiveXml {
  Invoke-R587Adb -Arguments @(
    'shell', 'uiautomator', 'dump', '/sdcard/r58-8-8-fix7-rm-live.xml'
  ) | Out-Null
  return ((Invoke-R587Adb -Arguments @(
    'shell', 'cat', '/sdcard/r58-8-8-fix7-rm-live.xml'
  )) -join '')
}

function Wait-ForDescription([string]$DescriptionPattern) {
  for ($attempt = 0; $attempt -lt 20; $attempt++) {
    $xml = Get-LiveXml
    if ($xml -match ('content-desc="' + $DescriptionPattern + '"')) {
      return
    }
    Start-Sleep -Milliseconds 500
  }
  throw "Timed out waiting for content description: $DescriptionPattern"
}

function Get-DescriptionBounds([string]$Xml, [string]$DescriptionPattern) {
  $pattern = (
    '<node[^>]+content-desc="' + $DescriptionPattern +
    '"[^>]+bounds="\[([0-9]+),([0-9]+)\]\[([0-9]+),([0-9]+)\]"[^>]*/>'
  )
  $match = [regex]::Match($Xml, $pattern)
  if (-not $match.Success) {
    throw "No node matched content description: $DescriptionPattern"
  }
  return @(
    [int]$match.Groups[1].Value,
    [int]$match.Groups[2].Value,
    [int]$match.Groups[3].Value,
    [int]$match.Groups[4].Value
  )
}

function Get-ClassBounds([string]$Xml, [string]$ClassName) {
  $pattern = (
    '<node[^>]+class="' + [regex]::Escape($ClassName) +
    '"[^>]+bounds="\[([0-9]+),([0-9]+)\]\[([0-9]+),([0-9]+)\]"[^>]*/>'
  )
  $match = [regex]::Match($Xml, $pattern)
  if (-not $match.Success) {
    throw "No node matched class: $ClassName"
  }
  return @(
    [int]$match.Groups[1].Value,
    [int]$match.Groups[2].Value,
    [int]$match.Groups[3].Value,
    [int]$match.Groups[4].Value
  )
}

function Get-VisibleImeTop([string]$EvidenceName) {
  $window = Invoke-R587Adb -Arguments @('shell', 'dumpsys', 'window')
  $path = Join-Path $root "$EvidenceName-window.txt"
  $window | Set-Content -LiteralPath $path -Encoding utf8
  $line = $window | Where-Object {
    $_ -match 'InsetsSource type=ITYPE_IME frame=\[0,([0-9]+)\].*visible=true'
  } | Select-Object -First 1
  if ($null -eq $line) {
    throw "Visible IME frame missing: $EvidenceName"
  }
  return [int]([regex]::Match(
    $line,
    'ITYPE_IME frame=\[0,([0-9]+)\]'
  ).Groups[1].Value)
}

function Tap-Description([string]$DescriptionPattern) {
  $bounds = Get-DescriptionBounds (Get-LiveXml) $DescriptionPattern
  Invoke-R587Adb -Arguments @(
    'shell', 'input', 'tap',
    [string]([int](($bounds[0] + $bounds[2]) / 2)),
    [string]([int](($bounds[1] + $bounds[3]) / 2))
  ) | Out-Null
  Start-Sleep -Milliseconds 800
}

function Assert-Selected([string]$Xml, [string]$Vertical, [string]$State) {
  $pattern = 'content-desc="' + $Vertical + '&#10;' + $Vertical + '"[^>]+selected="true"'
  if ($Xml -notmatch $pattern) {
    throw "$State did not select $Vertical"
  }
}

function Get-Scales {
  return @(
    ((Invoke-R587Adb -Arguments @('shell', 'settings', 'get', 'global', 'window_animation_scale')) -join '').Trim(),
    ((Invoke-R587Adb -Arguments @('shell', 'settings', 'get', 'global', 'transition_animation_scale')) -join '').Trim(),
    ((Invoke-R587Adb -Arguments @('shell', 'settings', 'get', 'global', 'animator_duration_scale')) -join '').Trim()
  )
}

function Open-RemoveAnimationsRow {
  Invoke-R587Adb -Arguments @(
    'shell', 'am', 'start', '-a', 'android.settings.ACCESSIBILITY_SETTINGS'
  ) | Out-Null
  Start-Sleep -Seconds 2
  $xml = Get-LiveXml
  if ($xml -notmatch 'text="Remove animations"') {
    Invoke-R587Adb -Arguments @('shell', 'input', 'tap', '255', '245') | Out-Null
    Start-Sleep -Milliseconds 700
    for ($attempt = 0; $attempt -lt 4; $attempt++) {
      $xml = Get-LiveXml
      if ($xml -match 'text="Remove animations"') { break }
      Invoke-R587Adb -Arguments @(
        'shell', 'input', 'swipe', '360', '1300', '360', '500', '500'
      ) | Out-Null
      Start-Sleep -Milliseconds 700
    }
  }
  $xml = Get-LiveXml
  $titleMatch = [regex]::Match(
    $xml,
    '<node[^>]+text="Remove animations"[^>]+bounds="\[([0-9]+),([0-9]+)\]\[([0-9]+),([0-9]+)\]"[^>]*/>'
  )
  if (-not $titleMatch.Success) {
    throw 'Visible Remove animations row was not found.'
  }
  $switchMatches = [regex]::Matches(
    $xml,
    '<node[^>]+resource-id="android:id/switch_widget"[^>]+bounds="\[([0-9]+),([0-9]+)\]\[([0-9]+),([0-9]+)\]"[^>]*/>'
  )
  $titleTop = [int]$titleMatch.Groups[2].Value
  $switchMatch = $switchMatches | Where-Object {
    [int]$_.Groups[2].Value -ge ($titleTop - 40)
  } | Select-Object -First 1
  if ($null -eq $switchMatch) {
    throw 'Remove animations switch control was not found beside the visible row.'
  }
  return @(
    [int]$switchMatch.Groups[1].Value,
    [int]$switchMatch.Groups[2].Value,
    [int]$switchMatch.Groups[3].Value,
    [int]$switchMatch.Groups[4].Value
  )
}

function Toggle-RemoveAnimations([string[]]$ExpectedBefore) {
  $switchBounds = Open-RemoveAnimationsRow
  $before = Get-Scales
  if (($before -join '/') -ne ($ExpectedBefore -join '/')) {
    throw "Unexpected pre-toggle animation scales: $($before -join '/')"
  }
  Invoke-R587Adb -Arguments @(
    'shell', 'input', 'tap',
    [string]([int](($switchBounds[0] + $switchBounds[2]) / 2)),
    [string]([int](($switchBounds[1] + $switchBounds[3]) / 2))
  ) | Out-Null
  Start-Sleep -Milliseconds 900
  return Get-Scales
}

function Get-AppRegionFrameMd5([string]$Path) {
  $frameLine = & ffmpeg -v error -i $Path `
    -vf 'crop=720:1530:0:82,format=rgb24' -f framemd5 - 2>$null |
    Select-Object -Last 1
  if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($frameLine)) {
    throw "Unable to hash the app-region raster: $Path"
  }
  return (($frameLine -split ',')[-1]).Trim()
}

$removeAnimationsEnabled = $false
try {
  $scalesAtStart = Get-Scales
  if (($scalesAtStart -join '/') -ne '1/1/1') {
    throw "Harness requires normal starting scales: $($scalesAtStart -join '/')"
  }
  Save-State '91-remove-animations-before' | Out-Null
  $disabledScales = Toggle-RemoveAnimations @('1', '1', '1')
  if (($disabledScales -join '/') -ne '0/0/0') {
    throw "Visible Remove animations did not set 0/0/0: $($disabledScales -join '/')"
  }
  $removeAnimationsEnabled = $true
  Save-State '92-remove-animations-on' | Out-Null

  Invoke-R587Adb -Arguments @(
    'shell', 'am', 'force-stop', 'com.moolsocial.app'
  ) | Out-Null
  Invoke-R587Adb -Arguments @(
    'shell', 'monkey', '-p', 'com.moolsocial.app',
    '-c', 'android.intent.category.LAUNCHER', '1'
  ) | Out-Null
  Wait-ForDescription 'Shop&#10;Shop'
  Tap-Description 'Shop&#10;Shop'
  Wait-ForDescription 'Shop categories[^\"]*For you'
  Tap-Description 'Shop categories[^\"]*For you'

  $frame1 = Save-State '93-reduced-shop-category-sheet-frame1'
  Start-Sleep -Milliseconds 600
  $frame2 = Save-State '94-reduced-shop-category-sheet-frame2'
  if ($frame1 -notmatch 'content-desc="Shop categories"' -or
      $frame2 -notmatch 'content-desc="Shop categories"') {
    throw 'Reduced-motion category sheet was not visible in both frames.'
  }
  if ($frame1 -cne $frame2) {
    throw 'Reduced-motion category-sheet accessibility trees were not static.'
  }
  $png1 = Get-FileHash (Join-Path $root '93-reduced-shop-category-sheet-frame1.png') -Algorithm SHA256
  $png2 = Get-FileHash (Join-Path $root '94-reduced-shop-category-sheet-frame2.png') -Algorithm SHA256
  $appFrame1Md5 = Get-AppRegionFrameMd5 $png1.Path
  $appFrame2Md5 = Get-AppRegionFrameMd5 $png2.Path
  if ($appFrame1Md5 -cne $appFrame2Md5) {
    throw 'Reduced-motion category-sheet app-region rasters were not static.'
  }

  $editBounds = Get-ClassBounds (Get-LiveXml) 'android.widget.EditText'
  Invoke-R587Adb -Arguments @(
    'shell', 'input', 'tap',
    [string]([int](($editBounds[0] + $editBounds[2]) / 2)),
    [string]([int](($editBounds[1] + $editBounds[3]) / 2))
  ) | Out-Null
  Start-Sleep -Milliseconds 700
  Invoke-R587Adb -Arguments @(
    'shell', 'input', 'text', 'shop%ssupplies'
  ) | Out-Null
  Start-Sleep -Milliseconds 800
  $filtered = Save-State '95-reduced-shop-category-filtered'
  $imeTop = Get-VisibleImeTop '95-reduced-shop-category-filtered'
  $targetBounds = Get-DescriptionBounds `
    $filtered 'Shop category, Shop supplies[^\"]*'
  if ($targetBounds[3] -gt $imeTop) {
    throw (
      "Reduced-motion result bottom $($targetBounds[3]) exceeds " +
      "IME top $imeTop"
    )
  }
  if ($filtered -match 'Shop category, Dairy &amp; bakery') {
    throw 'Reduced-motion exact category filter leaked unrelated results.'
  }
  Tap-Description 'Shop category, Shop supplies[^\"]*'
  Wait-ForDescription 'Shop categories[^\"]*Shop supplies'
  $selected = Save-State '96-reduced-shop-supplies-root'
  Assert-Selected $selected 'Shop' 'Reduced-motion Shop supplies root'
  if ($selected -notmatch 'Current category Shop supplies') {
    throw 'Reduced-motion category selection did not reach Shop supplies.'
  }

  Tap-Description 'Shop categories[^\"]*Shop supplies'
  Invoke-R587Adb -Arguments @('shell', 'input', 'keyevent', 'BACK') | Out-Null
  Wait-ForDescription 'Shop categories[^\"]*Shop supplies'
  $backReturned = Save-State '97-reduced-category-back-return'
  if ($backReturned -match 'content-desc="Close categories"') {
    throw 'Reduced-motion Android Back did not close the category sheet.'
  }

  Tap-Description 'Shop categories[^\"]*Shop supplies'
  Tap-Description 'Shop category, For you[^\"]*'
  Wait-ForDescription 'Shop categories[^\"]*For you'
  $reducedClean = Save-State '98-reduced-clean-shop-for-you'
  Assert-Selected $reducedClean 'Shop' 'Reduced-motion clean Shop For you'

  $restoredScales = Toggle-RemoveAnimations @('0', '0', '0')
  if (($restoredScales -join '/') -ne '1/1/1') {
    throw "Visible Remove animations did not restore 1/1/1: $($restoredScales -join '/')"
  }
  $removeAnimationsEnabled = $false
  Save-State '99-remove-animations-restored' | Out-Null

  Invoke-R587Adb -Arguments @(
    'shell', 'monkey', '-p', 'com.moolsocial.app',
    '-c', 'android.intent.category.LAUNCHER', '1'
  ) | Out-Null
  Wait-ForDescription 'Shop&#10;Shop'
  Tap-Description 'Shop&#10;Shop'
  $final = Save-State '100-final-clean-shop'
  Assert-Selected $final 'Shop' 'Final normal Shop'
  if ($final -match 'View cart' -or $final -match 'Place order') {
    throw 'Final normal Shop was not clean.'
  }

  @(
    'state=passed',
    'visibleSettingsPath=Accessibility > Vision > Remove animations',
    'enabledScales=0/0/0',
    'candidate=BUY-R58-CATEGORY-SHEET-IME-RESULT-VISIBILITY-FIX7',
    'profile=1.0.0-r58.23 (2026080419)',
    'reducedCategorySheetSelected=Shop',
    "frame1WholePngSha256=$($png1.Hash)",
    "frame2WholePngSha256=$($png2.Hash)",
    "staticAppRegionFrameMd5=$appFrame1Md5",
    'statusBarExcludedFromStaticComparison=true',
    'staticAccessibilityTree=true',
    "filteredResultBottom=$($targetBounds[3])",
    "visibleImeTop=$imeTop",
    "filteredResultClearance=$($imeTop - $targetBounds[3])",
    'filteredResultVisibility=passed',
    'androidBackReturn=passed',
    'exactCategoryRestoration=passed',
    'restoredScales=1/1/1',
    'finalState=clean Shop root',
    'placeOrderInvoked=false',
    'providerOrBackendInvoked=false'
  ) | Set-Content -LiteralPath (Join-Path $root '110-reduced-motion-assertions.txt') -Encoding utf8
  @(
    'window=1',
    'transition=1',
    'animator=1',
    'restoredThroughVisibleSettings=true'
  ) | Set-Content -LiteralPath (Join-Path $root '112-normal-state-restored.txt') -Encoding utf8

  Write-Output 'R58.8.8 FIX7 visible reduced-motion OPPO qualification passed and restored.'
} finally {
  if ($removeAnimationsEnabled) {
    try {
      $emergencyScales = Toggle-RemoveAnimations @('0', '0', '0')
      if (($emergencyScales -join '/') -eq '1/1/1') {
        Save-State '199-emergency-normal-state-restored' | Out-Null
      }
    } catch {
      Write-Error "Emergency visible settings restoration failed: $($_.Exception.Message)"
    }
  }
}
