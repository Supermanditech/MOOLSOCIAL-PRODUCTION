[CmdletBinding()]
param(
  [string]$RepositoryRoot,
  [Parameter(Mandatory = $true)]
  [ValidateSet(1, 2)]
  [int]$Cycle,
  [string]$EvidenceDirectory,
  [switch]$GatePreflightOnly
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)
$mobileRoot = Join-Path $root 'apps\mobile'
$contractPath = Join-Path $root 'config\mvp-personal-android-navigation-host-qualification-c28c.json'
if (-not $EvidenceDirectory) {
  $EvidenceDirectory = Join-Path $root 'artifacts\quality\uaw-c28c-host-qualification-20260810-01'
}
$evidenceRoot = [IO.Path]::GetFullPath($EvidenceDirectory)
$allowedEvidenceRoot = [IO.Path]::GetFullPath((Join-Path $root 'artifacts\quality'))
if (-not $evidenceRoot.StartsWith($allowedEvidenceRoot, [StringComparison]::OrdinalIgnoreCase)) {
  throw 'C28C evidence directory must remain inside artifacts/quality.'
}

function Get-C28CSourceFingerprint {
  param([string]$Root, [object[]]$RelativeRoots)
  $files = foreach ($relativeValue in $RelativeRoots) {
    $relative = [string]$relativeValue
    $resolved = [IO.Path]::GetFullPath((Join-Path $Root $relative))
    if (-not $resolved.StartsWith($Root, [StringComparison]::OrdinalIgnoreCase) -or
        -not (Test-Path -LiteralPath $resolved -PathType Container)) {
      throw "C28C fingerprint root is missing or outside repository: $relative"
    }
    Get-ChildItem -LiteralPath $resolved -Recurse -File
  }
  $records = foreach ($file in @($files | Sort-Object FullName -Unique)) {
    $relativePath = [IO.Path]::GetRelativePath($Root, $file.FullName).Replace('\', '/')
    "$((Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName).Hash)  $relativePath"
  }
  $sha = [Security.Cryptography.SHA256]::Create()
  try {
    return [Convert]::ToHexString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes(($records -join "`n"))))
  } finally {
    $sha.Dispose()
  }
}

function Invoke-C28CGate([string]$RelativePath, [hashtable]$Parameters = @{}) {
  & (Join-Path $root $RelativePath) @Parameters
}

function Invoke-C28CGateSet {
  Invoke-C28CGate 'scripts\check-personal-android-navigation-host-qualification-c28c.ps1' @{ RepositoryRoot = $root }
  Invoke-C28CGate 'scripts\check-personal-android-navigation-viewport-c28b.ps1' @{ RepositoryRoot = $root }
  Invoke-C28CGate 'scripts\check-personal-uniform-navigation-design-system-c27b.ps1' @{ RepositoryRoot = $root }
  Invoke-C28CGate 'scripts\check-personal-uniform-embedded-switcher-c27c.ps1' @{ RepositoryRoot = $root }
  Invoke-C28CGate 'scripts\check-personal-uniform-navigation-six-family-conformance-c27d.ps1' @{ RepositoryRoot = $root }
  Invoke-C28CGate 'scripts\check-personal-transparent-unboxed-destination-rail-c26b.ps1' @{ RepositoryRoot = $root }
  Invoke-C28CGate 'scripts\check-personal-embedded-vertical-mool-switcher-c26c.ps1' @{ RepositoryRoot = $root }
  Invoke-C28CGate 'scripts\check-personal-social-shop-navigation-conformance-c26d.ps1' @{ RepositoryRoot = $root }
  Invoke-C28CGate 'scripts\check-personal-food-travel-navigation-conformance-c26e.ps1' @{ RepositoryRoot = $root }
  Invoke-C28CGate 'scripts\check-personal-care-work-navigation-conformance-c26f.ps1' @{ RepositoryRoot = $root }
  Invoke-C28CGate 'scripts\check-personal-domain-navigation-contract-c25a.ps1' @{ RepositoryRoot = $root }
  Invoke-C28CGate 'scripts\check-personal-subaction-placement-regression.ps1' @{ RepositoryRoot = $root }
  Invoke-C28CGate 'scripts\check-approved-ui-locks.ps1'
  Invoke-C28CGate 'scripts\check-brand-integrity.ps1' @{ Surface = 'App' }
  Invoke-C28CGate 'scripts\check-user-facing-copy.ps1'
  Invoke-C28CGate 'scripts\check-interaction-contracts.ps1'
  Invoke-C28CGate 'scripts\check-mvp-personal-action-projection.ps1' @{ RepositoryRoot = $root }
  Invoke-C28CGate 'scripts\check-mvp-delivery-discipline-lock.ps1' @{ RepositoryRoot = $root; RequireTicketSelectionAssessment = $true }
  Invoke-C28CGate 'scripts\check-mvp-scope-gate-state.ps1' @{ RepositoryRoot = $root }
  Invoke-C28CGate 'scripts\check-codex-development-regression-memory.ps1' @{ Phase = 'implementation'; BuildMode = 'none'; RepositoryRoot = $root }
  Invoke-C28CGate 'scripts\check-buy-protected-baseline.ps1' @{ RepositoryRoot = $root }
  Invoke-C28CGate 'scripts\check-social-protected-baseline.ps1' @{ RepositoryRoot = $root }
}

$contract = Get-Content -Raw -LiteralPath $contractPath | ConvertFrom-Json
$base = Get-Content -Raw -LiteralPath (Join-Path $root ([string]$contract.baseContract.path)) | ConvertFrom-Json
$tests = @($base.requiredTests) + @($contract.addedTests)
$gates = @($base.requiredGates | Where-Object { [string]$_ -cne [string]$contract.baseContract.replacedGate }) + @($contract.addedGates)
$formatOwners = @($base.formatOwners) + @($contract.addedFormatOwners)
if (@($tests | Sort-Object -Unique).Count -ne [int]$contract.expectedTotals.requiredTests -or
    @($gates | Sort-Object -Unique).Count -ne [int]$contract.expectedTotals.requiredGates -or
    @($formatOwners | Sort-Object -Unique).Count -ne [int]$contract.expectedTotals.formatOwners) {
  throw 'C28C qualification inventory drifted.'
}

Invoke-C28CGateSet
if ($GatePreflightOnly) {
  Write-Output 'C28C gate-only qualifier preflight passed: tests=53; gates=22; no cycle counted.'
  return
}

$evidencePath = Join-Path $evidenceRoot "qualifying-cycle-$Cycle.json"
if (Test-Path -LiteralPath $evidencePath) {
  throw "C28C refuses to overwrite existing qualifying evidence: $evidencePath"
}
$fingerprintBefore = Get-C28CSourceFingerprint -Root $root -RelativeRoots @($contract.hostQualification.sourceFingerprintScope)
if ($Cycle -eq 2) {
  $cycleOnePath = Join-Path $evidenceRoot 'qualifying-cycle-1.json'
  if (-not (Test-Path -LiteralPath $cycleOnePath -PathType Leaf)) {
    throw 'C28C cycle 2 requires immutable qualifying-cycle-1 evidence.'
  }
  $cycleOne = Get-Content -Raw -LiteralPath $cycleOnePath | ConvertFrom-Json
  if ([int]$cycleOne.cycle -ne 1 -or
      [string]$cycleOne.ticketId -cne [string]$contract.ticketId -or
      [string]$cycleOne.sourceFingerprint -cne $fingerprintBefore) {
    throw 'C28C cycle 2 source fingerprint does not match qualifying cycle 1.'
  }
}

$mobileTests = foreach ($relativeValue in @($tests | Sort-Object -Unique)) {
  $relative = ([string]$relativeValue).Replace('\', '/')
  if (-not $relative.StartsWith('apps/mobile/', [StringComparison]::Ordinal)) {
    throw "C28C required test is outside apps/mobile: $relative"
  }
  $relative.Substring('apps/mobile/'.Length)
}
$mobileFormat = foreach ($relativeValue in @($formatOwners | Sort-Object -Unique)) {
  $relative = ([string]$relativeValue).Replace('\', '/')
  if (-not $relative.StartsWith('apps/mobile/', [StringComparison]::Ordinal)) {
    throw "C28C format owner is outside apps/mobile: $relative"
  }
  $relative.Substring('apps/mobile/'.Length)
}

Push-Location $mobileRoot
try {
  & dart format --output=none --set-exit-if-changed @mobileFormat @mobileTests
  if ($LASTEXITCODE -ne 0) { throw "C28C cycle $Cycle format rejected with exit $LASTEXITCODE." }
  & flutter analyze
  if ($LASTEXITCODE -ne 0) { throw "C28C cycle $Cycle analysis rejected with exit $LASTEXITCODE." }
  & flutter test @mobileTests --reporter compact
  if ($LASTEXITCODE -ne 0) { throw "C28C cycle $Cycle tests rejected with exit $LASTEXITCODE." }
} finally {
  Pop-Location
}

Invoke-C28CGateSet
$fingerprintAfter = Get-C28CSourceFingerprint -Root $root -RelativeRoots @($contract.hostQualification.sourceFingerprintScope)
if ($fingerprintAfter -cne $fingerprintBefore) {
  throw "C28C cycle $Cycle source fingerprint changed: before=$fingerprintBefore after=$fingerprintAfter"
}

[IO.Directory]::CreateDirectory($evidenceRoot) | Out-Null
$expected = $contract.expectedInstalledPredecessor
$evidence = [ordered]@{
  schemaVersion = 1
  ticketId = [string]$contract.ticketId
  cycle = $Cycle
  sourceFingerprint = $fingerprintAfter
  fingerprintAlgorithm = [string]$contract.hostQualification.sourceFingerprintAlgorithm
  requiredTestFiles = $mobileTests.Count
  requiredGateCount = @($gates | Sort-Object -Unique).Count
  format = 'clean'
  completeAnalysis = 'clean'
  completeRequiredSuite = 'passed'
  installedVersionName = [string]$expected.versionName
  installedVersionCode = [string]$expected.versionCode
  installedApkSha256 = [string]$expected.apkSha256
  runtimeBuildInstall = 'closed'
}
[IO.File]::WriteAllText($evidencePath, (($evidence | ConvertTo-Json -Depth 5) + "`n"), [Text.UTF8Encoding]::new($false))
$evidenceSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $evidencePath).Hash
Write-Output "C28C host cycle passed: cycle=$Cycle; sourceFingerprint=$fingerprintAfter; tests=$($mobileTests.Count); gates=$(@($gates | Sort-Object -Unique).Count); r60.26Preserved=true; evidence=$evidencePath; evidenceSha256=$evidenceSha."
