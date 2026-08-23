[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)
$gate = Join-Path $root 'scripts\check-personal-android-navigation-device-bounds-c28d.ps1'
$contractPath = Join-Path $root 'config\mvp-personal-android-navigation-device-bounds-c28d.json'
if (-not (Test-Path -LiteralPath $gate -PathType Leaf)) { throw 'C28D bounds gate is missing.' }
if (-not (Test-Path -LiteralPath $contractPath -PathType Leaf)) { throw 'C28D bounds contract is missing.' }
$contract = Get-Content -Raw -LiteralPath $contractPath | ConvertFrom-Json

$selfTestRoot = Join-Path $root ("tmp\c28d-bounds-self-test-{0}" -f [Guid]::NewGuid().ToString('N'))
[void](New-Item -ItemType Directory -Path $selfTestRoot)
try {
  $passingPath = Join-Path $selfTestRoot 'passing-social-320dpi.xml'
  $passingXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>
<hierarchy rotation="0">
  <node index="0" package="com.moolsocial.app" bounds="[0,0][720,1612]">
    <node index="0" text="" content-desc="Open MoolSocial main menu" clickable="true" bounds="[0,1496][108,1612]" package="com.moolsocial.app" />
    <node index="1" text="" content-desc="Open Social home" clickable="true" bounds="[112,1496][220,1612]" package="com.moolsocial.app" />
    <node index="2" text="" content-desc="YouTube Shorts, current" selected="true" bounds="[224,1496][345,1612]" package="com.moolsocial.app" />
    <node index="3" text="" content-desc="Open YouTube Videos" clickable="true" bounds="[349,1496][470,1612]" package="com.moolsocial.app" />
    <node index="4" text="" content-desc="Open Feed" clickable="true" bounds="[474,1496][595,1612]" package="com.moolsocial.app" />
    <node index="5" text="" content-desc="Open Create" clickable="true" bounds="[599,1496][720,1612]" package="com.moolsocial.app" />
  </node>
</hierarchy>
'@
  [IO.File]::WriteAllText($passingPath, $passingXml, [Text.UTF8Encoding]::new($false))
  $passOutput = & $gate -RepositoryRoot $root -XmlPath $passingPath -DensityDpi 320
  if (-not $? -or ($passOutput -join "`n") -notmatch 'targets=6; densityDpi=320; minimumLogical=54x58') {
    throw "C28D positive 320-dpi self-test did not pass with six normalized targets: $passOutput"
  }

  $wrongDensityRejected = $false
  try {
    & $gate -RepositoryRoot $root -XmlPath $passingPath -DensityDpi 480 *> $null
  } catch {
    $wrongDensityRejected = $_.Exception.Message -match 'navigation bounds rejected' -and
      $_.Exception.Message -match 'densityDpi=480'
  }
  if (-not $wrongDensityRejected) {
    throw 'C28D density-normalization negative self-test did not reject 320-dpi physical bounds interpreted at 480 dpi.'
  }

  $missingPath = Join-Path $selfTestRoot 'missing-local.xml'
  $missingXml = $passingXml.Replace('    <node index="5" text="" content-desc="Open Create" clickable="true" bounds="[599,1496][720,1612]" package="com.moolsocial.app" />' + "`r`n", '')
  if ($missingXml -ceq $passingXml) {
    $missingXml = $passingXml.Replace('    <node index="5" text="" content-desc="Open Create" clickable="true" bounds="[599,1496][720,1612]" package="com.moolsocial.app" />' + "`n", '')
  }
  [IO.File]::WriteAllText($missingPath, $missingXml, [Text.UTF8Encoding]::new($false))
  $missingRejected = $false
  try {
    & $gate -RepositoryRoot $root -XmlPath $missingPath -DensityDpi 320 *> $null
  } catch {
    $missingRejected = $_.Exception.Message -match "local rail node for 'Create'; found 0"
  }
  if (-not $missingRejected) {
    throw 'C28D missing-local negative self-test did not reject an incomplete visible family rail.'
  }

  $rejection = $contract.preservedRejectionFixture
  $rejectionPath = [IO.Path]::GetFullPath((Join-Path $root ([string]$rejection.path)))
  if (-not (Test-Path -LiteralPath $rejectionPath -PathType Leaf) -or
      (Get-FileHash -Algorithm SHA256 -LiteralPath $rejectionPath).Hash -cne [string]$rejection.sha256) {
    throw 'C28D preserved C27F rejection fixture is missing or changed.'
  }
  $c27fRejected = $false
  try {
    & $gate -RepositoryRoot $root -XmlPath $rejectionPath -DensityDpi ([int]$rejection.densityDpi) *> $null
  } catch {
    $expectedHeight = [string]$rejection.expectedLogicalHeight
    $c27fRejected = $_.Exception.Message -match 'navigation bounds rejected' -and
      $_.Exception.Message -match "logical=54x$expectedHeight" -and
      $_.Exception.Message -match 'minimum=44x44'
  }
  if (-not $c27fRejected) {
    throw 'C28D preserved C27F 19-logical-pixel rejection fixture was not rejected truthfully.'
  }
} finally {
  if (Test-Path -LiteralPath $selfTestRoot -PathType Container) {
    $resolvedSelfTestRoot = [IO.Path]::GetFullPath($selfTestRoot)
    $resolvedTmpRoot = [IO.Path]::GetFullPath((Join-Path $root 'tmp'))
    if (-not $resolvedSelfTestRoot.StartsWith($resolvedTmpRoot, [StringComparison]::OrdinalIgnoreCase)) {
      throw "C28D self-test cleanup target escaped the repository temp root: $resolvedSelfTestRoot"
    }
    Remove-Item -LiteralPath $resolvedSelfTestRoot -Recurse -Force
  }
}

Write-Output 'C28D density-normalized bounds gate self-tests passed: positive=1; negative=3; preservedC27F=rejected.'
