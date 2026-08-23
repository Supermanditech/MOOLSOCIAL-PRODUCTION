[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)
$gate = Join-Path $root 'scripts\check-personal-global-subaction-optical-delta-c21g.ps1'
if (-not (Test-Path -LiteralPath $gate -PathType Leaf)) { throw 'C21G optical-delta gate is missing.' }

& $gate -RepositoryRoot $root

$negativeRejected = $false
try {
  & $gate -RepositoryRoot $root -ProbeTokenOnlyDelta
} catch {
  if ($_.Exception.Message -notmatch 'successor optical contract does not match|token-only or structurally insufficient') {
    throw "C21G mutation probe failed for the wrong reason: $($_.Exception.Message)"
  }
  $negativeRejected = $true
}
if (-not $negativeRejected) { throw 'C21G gate accepted a token-only/structurally collapsed mutation probe.' }

Write-Output 'C21G optical-delta gate proof passed: positive=currentContractAccepted; negative=tokenOnlyStructuralCollapseRejected; buildInstall=closed.'
