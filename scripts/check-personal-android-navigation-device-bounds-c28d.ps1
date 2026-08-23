[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string]$XmlPath,

  [ValidateRange(0, 1000)]
  [int]$DensityDpi = 0,

  [ValidatePattern('^[A-Za-z0-9._-]+$')]
  [string]$Serial,

  [string]$RepositoryRoot
)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)
$contractPath = Join-Path $root 'config\mvp-personal-android-navigation-device-bounds-c28d.json'
$expectedContractSha256 = '31027CCC493BE4FBADA0DB0AFCB20224CFA86735991A9FC6353724DAD979FA1F'

if (-not (Test-Path -LiteralPath $contractPath -PathType Leaf)) {
  throw 'C28D density-normalized bounds contract is missing.'
}
if ((Get-FileHash -Algorithm SHA256 -LiteralPath $contractPath).Hash -cne $expectedContractSha256) {
  throw 'C28D density-normalized bounds contract checksum changed.'
}
$contract = Get-Content -Raw -LiteralPath $contractPath | ConvertFrom-Json
if ([int]$contract.schemaVersion -ne 1 -or
    [string]$contract.contractId -cne 'MOOLSOCIAL-PERSONAL-ANDROID-NAVIGATION-DEVICE-BOUNDS-C28D-001' -or
    [string]$contract.ticketId -cne 'UAW-PERSONAL-MVP-ANDROID-NAVIGATION-OPPO-QUALIFICATION-FIX11-C28D' -or
    [string]$contract.packageName -cne 'com.moolsocial.app' -or
    [int]$contract.densityBaseDpi -ne 160 -or
    [double]$contract.minimumLogicalSize.width -ne 44 -or
    [double]$contract.minimumLogicalSize.height -ne 44) {
  throw 'C28D density-normalized bounds contract identity or minimum changed.'
}
$families = @($contract.families)
$familyIds = @($families | ForEach-Object { [string]$_.id })
if ($families.Count -ne 6 -or
    $familyIds.Count -ne @($familyIds | Select-Object -Unique).Count -or
    (Compare-Object @('social', 'buy', 'eat', 'ride', 'book', 'work') $familyIds)) {
  throw 'C28D family inventory is incomplete, duplicated or changed.'
}
$localLabels = @($families | ForEach-Object { @($_.localLabels) } | ForEach-Object { [string]$_ })
if ($localLabels.Count -ne 18 -or $localLabels.Count -ne @($localLabels | Select-Object -Unique).Count) {
  throw 'C28D 18-action local navigation inventory is incomplete or duplicated.'
}
if (@($contract.moolSemantics).Count -ne 2 -or
    @($contract.moolSemantics) -cnotcontains 'Open MoolSocial main menu' -or
    @($contract.moolSemantics) -cnotcontains 'Close MoolSocial main menu') {
  throw 'C28D Mool semantic inventory changed.'
}

$resolvedXmlPath = [IO.Path]::GetFullPath($XmlPath)
if (-not $resolvedXmlPath.StartsWith($root, [StringComparison]::OrdinalIgnoreCase) -or
    -not (Test-Path -LiteralPath $resolvedXmlPath -PathType Leaf)) {
  throw "C28D UIAutomator XML is missing or outside the repository: $resolvedXmlPath"
}

$hasSuppliedDensity = $DensityDpi -gt 0
$hasLiveDensity = -not [string]::IsNullOrWhiteSpace($Serial)
if ($hasSuppliedDensity -eq $hasLiveDensity) {
  throw 'Provide exactly one density source: -DensityDpi or -Serial.'
}
if ($hasLiveDensity) {
  $adb = (Get-Command adb -ErrorAction Stop).Source
  $densityOutput = & $adb -s $Serial shell wm density 2>&1
  $densityExit = $LASTEXITCODE
  if ($densityExit -ne 0) { throw "Unable to read live Android density: $densityOutput" }
  $densityText = $densityOutput -join "`n"
  $overrideMatch = [regex]::Match($densityText, '(?m)^Override density:\s*(\d+)\s*$')
  $physicalMatch = [regex]::Match($densityText, '(?m)^Physical density:\s*(\d+)\s*$')
  if ($overrideMatch.Success) {
    $DensityDpi = [int]$overrideMatch.Groups[1].Value
  } elseif ($physicalMatch.Success) {
    $DensityDpi = [int]$physicalMatch.Groups[1].Value
  } else {
    throw "Live Android density is not parseable: $densityText"
  }
}
if ($DensityDpi -lt 72 -or $DensityDpi -gt 1000) {
  throw "C28D density is outside the supported Android range: $DensityDpi"
}

try {
  [xml]$hierarchy = Get-Content -Raw -LiteralPath $resolvedXmlPath
} catch {
  throw "C28D UIAutomator XML is invalid: $($_.Exception.Message)"
}
$visiblePackageNodes = @($hierarchy.SelectNodes('//node') | Where-Object {
  [string]$_.package -ceq [string]$contract.packageName -and
  [string]$_.'visible-to-user' -cne 'false'
})
if ($visiblePackageNodes.Count -eq 0) {
  throw 'C28D UIAutomator XML has no visible MoolSocial nodes.'
}

function Get-C28DBounds {
  param([Parameter(Mandatory = $true)]$Node)
  $rawBounds = [string]$Node.bounds
  if ($rawBounds -notmatch '^\[(\d+),(\d+)\]\[(\d+),(\d+)\]$') {
    throw "C28D navigation semantic has invalid bounds: $rawBounds"
  }
  $left = [int]$Matches[1]
  $top = [int]$Matches[2]
  $right = [int]$Matches[3]
  $bottom = [int]$Matches[4]
  if ($right -le $left -or $bottom -le $top) {
    throw "C28D navigation semantic has empty bounds: $rawBounds"
  }
  [pscustomobject]@{
    Raw = $rawBounds
    PhysicalWidth = $right - $left
    PhysicalHeight = $bottom - $top
  }
}

function Assert-C28DTargetBounds {
  param(
    [Parameter(Mandatory = $true)]$Node,
    [Parameter(Mandatory = $true)][string]$Semantic
  )
  $bounds = Get-C28DBounds -Node $Node
  $scale = [double]$DensityDpi / [double]$contract.densityBaseDpi
  $logicalWidth = [double]$bounds.PhysicalWidth / $scale
  $logicalHeight = [double]$bounds.PhysicalHeight / $scale
  if ($logicalWidth -lt [double]$contract.minimumLogicalSize.width -or
      $logicalHeight -lt [double]$contract.minimumLogicalSize.height) {
    $invariant = [Globalization.CultureInfo]::InvariantCulture
    $widthText = $logicalWidth.ToString('0.##', $invariant)
    $heightText = $logicalHeight.ToString('0.##', $invariant)
    throw "C28D navigation bounds rejected: semantic='$Semantic'; bounds=$($bounds.Raw); physical=$($bounds.PhysicalWidth)x$($bounds.PhysicalHeight); logical=${widthText}x${heightText}; densityDpi=$DensityDpi; minimum=44x44."
  }
  [pscustomobject]@{
    Semantic = $Semantic
    Bounds = $bounds.Raw
    LogicalWidth = $logicalWidth
    LogicalHeight = $logicalHeight
  }
}

function Get-C28DExactSemanticNodes {
  param([Parameter(Mandatory = $true)][string[]]$Semantics)
  @($visiblePackageNodes | Where-Object {
    $description = [string]$_.'content-desc'
    $text = [string]$_.text
    $Semantics -ccontains $description -or $Semantics -ccontains $text
  })
}

$moolNodes = @(Get-C28DExactSemanticNodes -Semantics @($contract.moolSemantics))
if ($moolNodes.Count -ne 1) {
  throw "C28D expected exactly one visible Mool rail node; found $($moolNodes.Count)."
}
$results = @(
  Assert-C28DTargetBounds -Node $moolNodes[0] -Semantic ([string]$moolNodes[0].'content-desc')
)

$matchedFamilies = @($families | Where-Object {
  @(Get-C28DExactSemanticNodes -Semantics @([string]$_.familyRootSemantic)).Count -gt 0
})
if ($matchedFamilies.Count -ne 1) {
  throw "C28D expected exactly one visible family-root rail node; found $($matchedFamilies.Count)."
}
$activeFamily = $matchedFamilies[0]
$familyNodes = @(Get-C28DExactSemanticNodes -Semantics @([string]$activeFamily.familyRootSemantic))
if ($familyNodes.Count -ne 1) {
  throw "C28D expected exactly one '$($activeFamily.familyRootSemantic)' node; found $($familyNodes.Count)."
}
$results += Assert-C28DTargetBounds -Node $familyNodes[0] -Semantic ([string]$activeFamily.familyRootSemantic)

foreach ($labelValue in @($activeFamily.localLabels)) {
  $label = [string]$labelValue
  $validSemantics = @("Open $label", "$label, current")
  $localNodes = @(Get-C28DExactSemanticNodes -Semantics $validSemantics)
  if ($localNodes.Count -ne 1) {
    throw "C28D expected exactly one visible local rail node for '$label'; found $($localNodes.Count)."
  }
  $semantic = [string]$localNodes[0].'content-desc'
  if ([string]::IsNullOrWhiteSpace($semantic)) { $semantic = [string]$localNodes[0].text }
  $results += Assert-C28DTargetBounds -Node $localNodes[0] -Semantic $semantic
}

$minimumWidth = ($results | Measure-Object -Property LogicalWidth -Minimum).Minimum
$minimumHeight = ($results | Measure-Object -Property LogicalHeight -Minimum).Minimum
$invariant = [Globalization.CultureInfo]::InvariantCulture
$minimumWidthText = ([double]$minimumWidth).ToString('0.##', $invariant)
$minimumHeightText = ([double]$minimumHeight).ToString('0.##', $invariant)
Write-Output "C28D density-normalized navigation bounds passed: family=$($activeFamily.id); targets=$($results.Count); densityDpi=$DensityDpi; minimumLogical=${minimumWidthText}x${minimumHeightText}."
