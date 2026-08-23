[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)
$gate = Join-Path $root 'scripts\check-personal-capsule-system-c22g.ps1'
if (-not (Test-Path -LiteralPath $gate -PathType Leaf)) { throw 'C22G capsule-system gate is missing.' }

& $gate -RepositoryRoot $root
$negativeRejected = $false
try {
  & $gate -RepositoryRoot $root -ProbeStructuralMutation
} catch {
  if ($_.Exception.Message -notmatch 'capsule system does not match') {
    throw "C22G mutation probe failed for the wrong reason: $($_.Exception.Message)"
  }
  $negativeRejected = $true
}
if (-not $negativeRejected) { throw 'C22G gate accepted a 71 px capsule mutation.' }

Write-Output 'C22G gate proof passed: positive=currentContractAccepted; negative=71pxCapsuleRejected; runtimeBuildInstall=closed.'
