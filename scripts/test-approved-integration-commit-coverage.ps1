[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot)
$gate = Join-Path $root 'scripts/check-approved-integration-commit-coverage.ps1'
$manifest = Join-Path $root 'config/approved-integration-commit-coverage-20260901.json'
$builder = Get-Content -Raw -LiteralPath (
  Join-Path $root 'scripts/build-buy-device-review.ps1'
)
if (
  -not $builder.Contains('check-approved-integration-commit-coverage.ps1') -or
  -not $builder.Contains('-CandidateHead HEAD') -or
  -not $builder.Contains('Approved integration commit coverage gate failed.')
) {
  throw 'Device-review wrapper does not require approved commit coverage.'
}

& $gate -RepositoryRoot $root -ManifestPath $manifest -CandidateHead HEAD |
  Out-Null

function Assert-Rejected(
  [string]$Candidate,
  [string]$ExpectedMessage
) {
  $rejected = $false
  try {
    & $gate -RepositoryRoot $root -ManifestPath $manifest `
      -CandidateHead $Candidate | Out-Null
  } catch {
    if (-not $_.Exception.Message.Contains($ExpectedMessage)) {
      throw
    }
    $rejected = $true
  }
  if (-not $rejected) {
    throw "Expected coverage rejection was not observed: $Candidate"
  }
}

Assert-Rejected `
  -Candidate 'f79adb396fe25c6b05c1c1118aed1ac4fe412d1a' `
  -ExpectedMessage 'approved tip is omitted from candidate: codex-social-create-composer'
Assert-Rejected `
  -Candidate '0df24cc11f06ec5032a0f6def454c03b41c09e30' `
  -ExpectedMessage 'rejected tip is present in candidate: cursor-rejected-product-discovery'

Write-Output (
  'Approved integration commit coverage fixtures passed: ' +
  'positive=1; omitted=1; rejected=1.'
)
