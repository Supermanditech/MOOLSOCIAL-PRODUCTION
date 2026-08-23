[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

function Assert-C30VSocialSeal {
  param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
  if (-not $Condition) { throw "C30V protected Social successor rejected: $Message" }
}

$c30uGate = Join-Path $root 'scripts/check-c30u-social-protected-successor.ps1'
$c30uStatePath = Join-Path $root 'config/play-internal-aab-regression-gate-state-c30u.json'
$c30uAggregatePath = Join-Path $root 'config/play-internal-social-repairs-acceptance-gate-state-c30u.json'
foreach ($required in @($c30uGate, $c30uStatePath, $c30uAggregatePath)) {
  Assert-C30VSocialSeal -Condition (Test-Path -LiteralPath $required -PathType Leaf) -Message "required C30U owner is missing: $required"
}

& $c30uGate -RepositoryRoot $root

$c30u = Get-Content -Raw -LiteralPath $c30uStatePath | ConvertFrom-Json
$c30uAggregate = Get-Content -Raw -LiteralPath $c30uAggregatePath | ConvertFrom-Json
Assert-C30VSocialSeal -Condition (
  [string]$c30u.machineState -ceq 'single_release_AAB_succeeded_authority_consumed' -and
  [string]$c30u.buildAuthorization -ceq 'consumed' -and
  [string]$c30u.candidate.versionName -ceq '1.0.0-r60.46' -and
  [string]$c30u.candidate.versionCode -ceq '2026081346' -and
  [int]$c30u.buildResult.buildCount -eq 1 -and
  [int]$c30u.playReleaseResult.uploadCount -eq 0 -and
  [int]$c30u.installResult.candidateInstallCount -eq 0 -and
  -not [bool]$c30u.buildResult.secondBuildPerformed
) -Message 'r60.46 abandoned-build identity or zero upload/install boundary changed.'
Assert-C30VSocialSeal -Condition (
  [string]$c30u.buildResult.artifactSha256 -ceq '105242061939B1557B3BCCCBFD40F8CEBBEDFB59BE3ED30839C3FFA90049D145' -and
  [long]$c30u.buildResult.artifactBytes -eq 94451855
) -Message 'r60.46 sealed AAB identity changed.'
$r60_46Artifact = Join-Path $root ([string]$c30u.buildResult.artifactPath)
Assert-C30VSocialSeal -Condition (
  (Test-Path -LiteralPath $r60_46Artifact -PathType Leaf) -and
  (Get-FileHash -LiteralPath $r60_46Artifact -Algorithm SHA256).Hash -ceq [string]$c30u.buildResult.artifactSha256 -and
  (Get-Item -LiteralPath $r60_46Artifact).Length -eq [long]$c30u.buildResult.artifactBytes
) -Message 'r60.46 AAB is missing or differs from its sealed checksum.'
Assert-C30VSocialSeal -Condition (
  [string]$c30uAggregate.machineState -ceq 'single_release_AAB_succeeded_authority_consumed' -and
  [int]$c30uAggregate.candidate.buildCount -eq 1 -and
  [int]$c30uAggregate.candidate.uploadCount -eq 0 -and
  [int]$c30uAggregate.candidate.installCount -eq 0
) -Message 'C30U aggregate abandoned-build state changed.'

Write-Output 'C30V protected Social successor passed: C30U runtime seal preserved; r60.46 AAB checksum exact; upload/install=0/0.'
