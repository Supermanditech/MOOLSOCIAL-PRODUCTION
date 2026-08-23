[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)
$gate = Join-Path $root 'scripts\check-personal-android-navigation-device-bounds-c28f.ps1'
$contractPath = Join-Path $root 'config\mvp-personal-android-navigation-device-bounds-c28f.json'
if (-not (Test-Path -LiteralPath $gate -PathType Leaf)) { throw 'C28F bounds gate is missing.' }
if (-not (Test-Path -LiteralPath $contractPath -PathType Leaf)) { throw 'C28F bounds contract is missing.' }
$contract = Get-Content -Raw -LiteralPath $contractPath | ConvertFrom-Json

$selfTestRoot = Join-Path $root ("tmp\c28f-bounds-self-test-{0}" -f [Guid]::NewGuid().ToString('N'))
[void](New-Item -ItemType Directory -Path $selfTestRoot)
try {
  $socialPassingPath = Join-Path $selfTestRoot 'passing-social-current-catalogue-320dpi.xml'
  $socialPassingXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>
<hierarchy rotation="0">
  <node index="0" package="com.moolsocial.app" bounds="[0,0][720,1612]">
    <node index="0" text="" content-desc="Open MoolSocial main menu" clickable="true" bounds="[0,1496][108,1612]" package="com.moolsocial.app" />
    <node index="1" text="" content-desc="YouTube Shorts, current" selected="true" bounds="[112,1496][260,1612]" package="com.moolsocial.app" />
    <node index="2" text="" content-desc="Open YouTube Videos" clickable="true" bounds="[264,1496][412,1612]" package="com.moolsocial.app" />
    <node index="3" text="" content-desc="Open Feed" clickable="true" bounds="[416,1496][564,1612]" package="com.moolsocial.app" />
    <node index="4" text="" content-desc="Open Create" clickable="true" bounds="[568,1496][716,1612]" package="com.moolsocial.app" />
  </node>
</hierarchy>
'@
  [IO.File]::WriteAllText($socialPassingPath, $socialPassingXml, [Text.UTF8Encoding]::new($false))
  $socialPassOutput = & $gate -RepositoryRoot $root -XmlPath $socialPassingPath -DensityDpi 320
  if (-not $? -or ($socialPassOutput -join "`n") -notmatch 'family=social; rootExpected=False; targets=5; densityDpi=320; minimumLogical=54x58') {
    throw "C28F Social positive self-test did not pass with five current targets: $socialPassOutput"
  }

  $buyPassingPath = Join-Path $selfTestRoot 'passing-buy-current-catalogue-320dpi.xml'
  $buyPassingXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>
<hierarchy rotation="0">
  <node index="0" package="com.moolsocial.app" bounds="[0,0][720,1612]">
    <node index="0" text="" content-desc="Open MoolSocial main menu" clickable="true" bounds="[0,1496][108,1612]" package="com.moolsocial.app" />
    <node index="1" text="" content-desc="Open Shop home" clickable="true" bounds="[112,1496][260,1612]" package="com.moolsocial.app" />
    <node index="2" text="" content-desc="Wholesale, current" selected="true" bounds="[264,1496][440,1612]" package="com.moolsocial.app" />
    <node index="3" text="" content-desc="Open Orders" clickable="true" bounds="[444,1496][620,1612]" package="com.moolsocial.app" />
  </node>
</hierarchy>
'@
  [IO.File]::WriteAllText($buyPassingPath, $buyPassingXml, [Text.UTF8Encoding]::new($false))
  $buyPassOutput = & $gate -RepositoryRoot $root -XmlPath $buyPassingPath -DensityDpi 320
  if (-not $? -or ($buyPassOutput -join "`n") -notmatch 'family=buy; rootExpected=True; targets=4; densityDpi=320; minimumLogical=54x58') {
    throw "C28F Buy positive self-test did not pass with four current targets: $buyPassOutput"
  }

  $wrongDensityRejected = $false
  try { & $gate -RepositoryRoot $root -XmlPath $socialPassingPath -DensityDpi 480 *> $null }
  catch { $wrongDensityRejected = $_.Exception.Message -match 'logical=36x38.67' -and $_.Exception.Message -match 'minimum=44x44' }
  if (-not $wrongDensityRejected) { throw 'C28F wrong-density negative self-test was not rejected.' }

  $redundantSocialRootPath = Join-Path $selfTestRoot 'redundant-social-root.xml'
  $redundantSocialRootXml = $socialPassingXml.Replace(
    '    <node index="1" text="" content-desc="YouTube Shorts, current"',
    '    <node index="5" text="" content-desc="Open Social home" clickable="true" bounds="[112,1496][220,1612]" package="com.moolsocial.app" />' + "`n" + '    <node index="1" text="" content-desc="YouTube Shorts, current"'
  )
  [IO.File]::WriteAllText($redundantSocialRootPath, $redundantSocialRootXml, [Text.UTF8Encoding]::new($false))
  $redundantSocialRootRejected = $false
  try { & $gate -RepositoryRoot $root -XmlPath $redundantSocialRootPath -DensityDpi 320 *> $null }
  catch { $redundantSocialRootRejected = $_.Exception.Message -match 'family-root count for social is 1, expected 0' }
  if (-not $redundantSocialRootRejected) { throw 'C28F redundant Social-root negative self-test was not rejected.' }

  $forbiddenProductsPath = Join-Path $selfTestRoot 'forbidden-buy-products.xml'
  $forbiddenProductsXml = $buyPassingXml.Replace(
    '    <node index="2" text="" content-desc="Wholesale, current"',
    '    <node index="4" text="" content-desc="Open Products" clickable="true" bounds="[624,1496][716,1612]" package="com.moolsocial.app" />' + "`n" + '    <node index="2" text="" content-desc="Wholesale, current"'
  )
  [IO.File]::WriteAllText($forbiddenProductsPath, $forbiddenProductsXml, [Text.UTF8Encoding]::new($false))
  $forbiddenProductsRejected = $false
  try { & $gate -RepositoryRoot $root -XmlPath $forbiddenProductsPath -DensityDpi 320 *> $null }
  catch { $forbiddenProductsRejected = $_.Exception.Message -match "forbidden local node 'Products' is visible" }
  if (-not $forbiddenProductsRejected) { throw 'C28F forbidden Products negative self-test was not rejected.' }

  $missingLocalPath = Join-Path $selfTestRoot 'missing-social-create.xml'
  $missingLocalXml = [regex]::Replace($socialPassingXml, '(?m)^\s*<node[^>]+content-desc="Open Create"[^>]*/>\r?\n?', '')
  [IO.File]::WriteAllText($missingLocalPath, $missingLocalXml, [Text.UTF8Encoding]::new($false))
  $missingLocalRejected = $false
  try { & $gate -RepositoryRoot $root -XmlPath $missingLocalPath -DensityDpi 320 *> $null }
  catch { $missingLocalRejected = $_.Exception.Message -match "local node for 'Create'; found 0" }
  if (-not $missingLocalRejected) { throw 'C28F missing-local negative self-test was not rejected.' }

  $rejection = $contract.preservedRejectionFixture
  $rejectionPath = [IO.Path]::GetFullPath((Join-Path $root ([string]$rejection.path)))
  if (-not (Test-Path -LiteralPath $rejectionPath -PathType Leaf) -or (Get-FileHash -Algorithm SHA256 -LiteralPath $rejectionPath).Hash -cne [string]$rejection.sha256) {
    throw 'C28F preserved C28D rejection fixture is missing or changed.'
  }
  [xml]$normalizedRejectedHierarchy = Get-Content -Raw -LiteralPath $rejectionPath
  $legacySocialRoot = $normalizedRejectedHierarchy.SelectSingleNode('//node[@content-desc="Open Social home"]')
  if ($null -eq $legacySocialRoot) { throw 'C28F preserved C28D fixture lacks its expected legacy Social root.' }
  [void]$legacySocialRoot.ParentNode.RemoveChild($legacySocialRoot)
  $normalizedRejectedPath = Join-Path $selfTestRoot 'c28d-height-rejection-current-catalogue.xml'
  $normalizedRejectedHierarchy.Save($normalizedRejectedPath)
  $c28dHeightRejected = $false
  try { & $gate -RepositoryRoot $root -XmlPath $normalizedRejectedPath -DensityDpi ([int]$rejection.densityDpi) *> $null }
  catch {
    $expectedHeight = [string]$rejection.expectedLogicalHeight
    $c28dHeightRejected = $_.Exception.Message -match "logical=54x$expectedHeight" -and $_.Exception.Message -match 'minimum=44x44'
  }
  if (-not $c28dHeightRejected) { throw 'C28F normalized preserved C28D 19-logical-pixel fixture was not rejected.' }
} finally {
  if (Test-Path -LiteralPath $selfTestRoot -PathType Container) {
    $resolvedSelfTestRoot = [IO.Path]::GetFullPath($selfTestRoot)
    $resolvedTmpRoot = [IO.Path]::GetFullPath((Join-Path $root 'tmp'))
    if (-not $resolvedSelfTestRoot.StartsWith($resolvedTmpRoot, [StringComparison]::OrdinalIgnoreCase)) {
      throw "C28F self-test cleanup target escaped repository temp root: $resolvedSelfTestRoot"
    }
    Remove-Item -LiteralPath $resolvedSelfTestRoot -Recurse -Force
  }
}

Write-Output 'C28F density-normalized bounds self-tests passed: positive=2; negative=5; currentSocialRoot=false; currentBuyProducts=false; preservedC28DHeight=rejected.'
