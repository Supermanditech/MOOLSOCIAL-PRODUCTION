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
Set-StrictMode -Version Latest
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)
$contractPath = Join-Path $root 'config\mvp-personal-android-navigation-device-bounds-c28f.json'
$expectedContractSha256 = 'D5C441FA2815FC733396FA280252850A0FF4433AC779C5F1AD52F78D65167745'

function Assert-C28FBounds([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C28F navigation bounds rejected: $Message" }
}

Assert-C28FBounds (Test-Path -LiteralPath $contractPath -PathType Leaf) 'contract is missing'
Assert-C28FBounds ((Get-FileHash -Algorithm SHA256 -LiteralPath $contractPath).Hash -ceq $expectedContractSha256) 'contract checksum changed'
$contract = Get-Content -Raw -LiteralPath $contractPath | ConvertFrom-Json
Assert-C28FBounds ([int]$contract.schemaVersion -eq 1) 'schema changed'
Assert-C28FBounds ([string]$contract.contractId -ceq 'MOOLSOCIAL-PERSONAL-ANDROID-NAVIGATION-DEVICE-BOUNDS-C28F-001') 'contract id changed'
Assert-C28FBounds ([string]$contract.ticketId -ceq 'UAW-PERSONAL-MVP-ANDROID-NAVIGATION-EXPORTED-SEMANTICS-OPPO-QUALIFICATION-FIX12-C28F') 'ticket changed'
Assert-C28FBounds ([string]$contract.packageName -ceq 'com.moolsocial.app') 'package changed'
Assert-C28FBounds ([int]$contract.densityBaseDpi -eq 160) 'density base changed'
Assert-C28FBounds ([double]$contract.minimumLogicalSize.width -eq 44 -and [double]$contract.minimumLogicalSize.height -eq 44) '44 by 44 minimum changed'

$families = @($contract.families)
$familyIds = @($families | ForEach-Object { [string]$_.id })
Assert-C28FBounds ($families.Count -eq 6 -and -not (Compare-Object @('social','buy','eat','ride','book','work') $familyIds)) 'six-family inventory changed'
$localLabels = @($families | ForEach-Object { @($_.localLabels) } | ForEach-Object { [string]$_ })
Assert-C28FBounds ($localLabels.Count -eq 17 -and $localLabels.Count -eq @($localLabels | Select-Object -Unique).Count) '17-action local inventory changed or duplicated'
$socialSpec = @($families | Where-Object { [string]$_.id -ceq 'social' })[0]
$buySpec = @($families | Where-Object { [string]$_.id -ceq 'buy' })[0]
Assert-C28FBounds (-not [bool]$socialSpec.familyRootExpected -and [string]$socialSpec.familyRootSemantic -ceq 'Open Social home') 'FSC01 Social-root absence changed'
Assert-C28FBounds ([bool]$buySpec.familyRootExpected -and [string]$buySpec.familyRootSemantic -ceq 'Open Shop home') 'Shop family root changed'
Assert-C28FBounds ((@($buySpec.localLabels) -join '|') -ceq 'Wholesale|Orders') 'FSC06 Buy local catalogue changed'
Assert-C28FBounds ((@($buySpec.forbiddenLocalLabels) -join '|') -ceq 'Products|Shop') 'FSC06 forbidden catalogue changed'
Assert-C28FBounds (@($contract.moolSemantics).Count -eq 2) 'Mool semantic inventory changed'

$resolvedXmlPath = [IO.Path]::GetFullPath($XmlPath)
Assert-C28FBounds ($resolvedXmlPath.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) 'XML escaped repository'
Assert-C28FBounds (Test-Path -LiteralPath $resolvedXmlPath -PathType Leaf) 'XML is missing'

$hasSuppliedDensity = $DensityDpi -gt 0
$hasLiveDensity = -not [string]::IsNullOrWhiteSpace($Serial)
Assert-C28FBounds ($hasSuppliedDensity -ne $hasLiveDensity) 'provide exactly one density source'
if ($hasLiveDensity) {
  $adb = (Get-Command adb -ErrorAction Stop).Source
  $densityOutput = & $adb -s $Serial shell wm density 2>&1
  $densityExit = $LASTEXITCODE
  Assert-C28FBounds ($densityExit -eq 0) "live density read failed: $densityOutput"
  $densityText = $densityOutput -join "`n"
  $overrideMatch = [regex]::Match($densityText, '(?m)^Override density:\s*(\d+)\s*$')
  $physicalMatch = [regex]::Match($densityText, '(?m)^Physical density:\s*(\d+)\s*$')
  if ($overrideMatch.Success) { $DensityDpi = [int]$overrideMatch.Groups[1].Value }
  elseif ($physicalMatch.Success) { $DensityDpi = [int]$physicalMatch.Groups[1].Value }
  else { throw "C28F navigation bounds rejected: live density is not parseable: $densityText" }
}
Assert-C28FBounds ($DensityDpi -ge 72 -and $DensityDpi -le 1000) 'density is outside supported Android range'

try { [xml]$hierarchy = Get-Content -Raw -LiteralPath $resolvedXmlPath }
catch { throw "C28F navigation bounds rejected: XML is invalid: $($_.Exception.Message)" }
$visiblePackageNodes = @($hierarchy.SelectNodes('//node') | Where-Object {
  [string]$_.GetAttribute('package') -ceq [string]$contract.packageName -and
    [string]$_.GetAttribute('visible-to-user') -cne 'false'
})
Assert-C28FBounds ($visiblePackageNodes.Count -gt 0) 'XML has no visible MoolSocial nodes'

function Get-C28FExactSemanticNodes([string[]]$Semantics) {
  @($visiblePackageNodes | Where-Object {
    $Semantics -ccontains [string]$_.GetAttribute('content-desc') -or
      $Semantics -ccontains [string]$_.GetAttribute('text')
  })
}

function Get-C28FBounds($Node) {
  $rawBounds = [string]$Node.GetAttribute('bounds')
  if ($rawBounds -notmatch '^\[(\d+),(\d+)\]\[(\d+),(\d+)\]$') {
    throw "C28F navigation bounds rejected: invalid bounds $rawBounds"
  }
  $left = [int]$Matches[1]; $top = [int]$Matches[2]; $right = [int]$Matches[3]; $bottom = [int]$Matches[4]
  Assert-C28FBounds ($right -gt $left -and $bottom -gt $top) "empty bounds $rawBounds"
  [pscustomobject]@{ Raw=$rawBounds; PhysicalWidth=$right-$left; PhysicalHeight=$bottom-$top }
}

function Assert-C28FTargetBounds($Node, [string]$Semantic) {
  $bounds = Get-C28FBounds -Node $Node
  $scale = [double]$DensityDpi / [double]$contract.densityBaseDpi
  $logicalWidth = [double]$bounds.PhysicalWidth / $scale
  $logicalHeight = [double]$bounds.PhysicalHeight / $scale
  if ($logicalWidth -lt [double]$contract.minimumLogicalSize.width -or $logicalHeight -lt [double]$contract.minimumLogicalSize.height) {
    $invariant = [Globalization.CultureInfo]::InvariantCulture
    $widthText = $logicalWidth.ToString('0.##', $invariant)
    $heightText = $logicalHeight.ToString('0.##', $invariant)
    throw "C28F navigation bounds rejected: semantic='$Semantic'; bounds=$($bounds.Raw); physical=$($bounds.PhysicalWidth)x$($bounds.PhysicalHeight); logical=${widthText}x${heightText}; densityDpi=$DensityDpi; minimum=44x44."
  }
  [pscustomobject]@{ Semantic=$Semantic; Bounds=$bounds.Raw; LogicalWidth=$logicalWidth; LogicalHeight=$logicalHeight }
}

$moolNodes = @(Get-C28FExactSemanticNodes -Semantics @($contract.moolSemantics))
Assert-C28FBounds ($moolNodes.Count -eq 1) "expected exactly one visible Mool node; found $($moolNodes.Count)"
$results = @(Assert-C28FTargetBounds -Node $moolNodes[0] -Semantic ([string]$moolNodes[0].GetAttribute('content-desc')))

$matchedFamilies = @($families | Where-Object {
  $candidateLabels = @($_.localLabels | ForEach-Object { [string]$_ })
  @(Get-C28FExactSemanticNodes -Semantics @($candidateLabels | ForEach-Object { "Open $_"; "$_, current" })).Count -gt 0
})
Assert-C28FBounds ($matchedFamilies.Count -eq 1) "expected one active local family; found $($matchedFamilies.Count)"
$activeFamily = $matchedFamilies[0]
$familyRootNodes = @(Get-C28FExactSemanticNodes -Semantics @([string]$activeFamily.familyRootSemantic))
$expectedRootCount = if ([bool]$activeFamily.familyRootExpected) { 1 } else { 0 }
Assert-C28FBounds ($familyRootNodes.Count -eq $expectedRootCount) "family-root count for $($activeFamily.id) is $($familyRootNodes.Count), expected $expectedRootCount"
if ($expectedRootCount -eq 1) {
  $results += Assert-C28FTargetBounds -Node $familyRootNodes[0] -Semantic ([string]$activeFamily.familyRootSemantic)
}

$forbiddenLocalLabels = if ($activeFamily.PSObject.Properties.Name -ccontains 'forbiddenLocalLabels') {
  @($activeFamily.forbiddenLocalLabels)
} else {
  @()
}
foreach ($forbiddenLabelValue in $forbiddenLocalLabels) {
  $forbiddenLabel = [string]$forbiddenLabelValue
  $forbiddenNodes = @(Get-C28FExactSemanticNodes -Semantics @("Open $forbiddenLabel", "$forbiddenLabel, current"))
  Assert-C28FBounds ($forbiddenNodes.Count -eq 0) "forbidden local node '$forbiddenLabel' is visible"
}
foreach ($labelValue in @($activeFamily.localLabels)) {
  $label = [string]$labelValue
  $localNodes = @(Get-C28FExactSemanticNodes -Semantics @("Open $label", "$label, current"))
  Assert-C28FBounds ($localNodes.Count -eq 1) "expected exactly one local node for '$label'; found $($localNodes.Count)"
  $semantic = [string]$localNodes[0].GetAttribute('content-desc')
  if ([string]::IsNullOrWhiteSpace($semantic)) { $semantic = [string]$localNodes[0].GetAttribute('text') }
  $results += Assert-C28FTargetBounds -Node $localNodes[0] -Semantic $semantic
}

$minimumWidth = ($results | Measure-Object -Property LogicalWidth -Minimum).Minimum
$minimumHeight = ($results | Measure-Object -Property LogicalHeight -Minimum).Minimum
$invariant = [Globalization.CultureInfo]::InvariantCulture
$minimumWidthText = ([double]$minimumWidth).ToString('0.##', $invariant)
$minimumHeightText = ([double]$minimumHeight).ToString('0.##', $invariant)
Write-Output "C28F density-normalized navigation bounds passed: family=$($activeFamily.id); rootExpected=$([bool]$activeFamily.familyRootExpected); targets=$($results.Count); densityDpi=$DensityDpi; minimumLogical=${minimumWidthText}x${minimumHeightText}."
