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
$contractPath = Join-Path $root 'config\mvp-personal-android-navigation-host-qualification-c28e.json'
$contract = Get-Content -Raw -LiteralPath $contractPath | ConvertFrom-Json
if (-not $EvidenceDirectory) {
  $EvidenceDirectory = Join-Path $root ([string]$contract.hostQualification.evidenceDirectory)
}
$evidenceRoot = [IO.Path]::GetFullPath($EvidenceDirectory)
$allowedEvidenceRoot = [IO.Path]::GetFullPath((Join-Path $root 'artifacts\quality'))
if (-not $evidenceRoot.StartsWith($allowedEvidenceRoot, [StringComparison]::OrdinalIgnoreCase)) {
  throw 'C28E evidence directory must remain inside artifacts/quality.'
}

function Get-C28ERelativePath([string]$BasePath, [string]$FullPath) {
  $baseWithSeparator = $BasePath.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
  $baseUri = [Uri]::new($baseWithSeparator)
  $fileUri = [Uri]::new($FullPath)
  return [Uri]::UnescapeDataString($baseUri.MakeRelativeUri($fileUri).ToString()).Replace('\', '/')
}

function Convert-C28EBytesToHex([byte[]]$Bytes) {
  return ([BitConverter]::ToString($Bytes)).Replace('-', '')
}

function Get-C28ESourceFingerprint([string]$Root, [object[]]$RelativeRoots) {
  $files = foreach ($relativeValue in $RelativeRoots) {
    $relative = [string]$relativeValue
    $resolved = [IO.Path]::GetFullPath((Join-Path $Root $relative))
    if (-not $resolved.StartsWith($Root, [StringComparison]::OrdinalIgnoreCase) -or
        -not (Test-Path -LiteralPath $resolved -PathType Container)) {
      throw "C28E fingerprint root is missing or outside repository: $relative"
    }
    Get-ChildItem -LiteralPath $resolved -Recurse -File
  }
  $records = foreach ($file in @($files | Sort-Object FullName -Unique)) {
    $relativePath = Get-C28ERelativePath -BasePath $Root -FullPath $file.FullName
    "$((Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName).Hash)  $relativePath"
  }
  $sha = [Security.Cryptography.SHA256]::Create()
  try {
    return Convert-C28EBytesToHex $sha.ComputeHash([Text.Encoding]::UTF8.GetBytes(($records -join "`n")))
  } finally {
    $sha.Dispose()
  }
}

function Invoke-C28EGate([string]$RelativePath, [hashtable]$Parameters = @{}) {
  & (Join-Path $root $RelativePath) @Parameters
}

function Invoke-C28EGateSet {
  Invoke-C28EGate 'scripts\check-personal-android-navigation-host-qualification-c28e.ps1' @{ RepositoryRoot = $root }
  Invoke-C28EGate 'scripts\check-personal-android-navigation-exported-semantics-c28e.ps1' @{ RepositoryRoot = $root }
  Invoke-C28EGate 'scripts\check-personal-uniform-navigation-design-system-c27b.ps1' @{ RepositoryRoot = $root }
  Invoke-C28EGate 'scripts\check-personal-uniform-embedded-switcher-c27c.ps1' @{ RepositoryRoot = $root }
  Invoke-C28EGate 'scripts\check-personal-uniform-navigation-six-family-conformance-c27d.ps1' @{ RepositoryRoot = $root }
  Invoke-C28EGate 'scripts\check-personal-transparent-unboxed-destination-rail-c26b.ps1' @{ RepositoryRoot = $root }
  Invoke-C28EGate 'scripts\check-personal-embedded-vertical-mool-switcher-c26c.ps1' @{ RepositoryRoot = $root }
  Invoke-C28EGate 'scripts\check-personal-social-shop-navigation-conformance-c26d.ps1' @{ RepositoryRoot = $root }
  Invoke-C28EGate 'scripts\check-personal-food-travel-navigation-conformance-c26e.ps1' @{ RepositoryRoot = $root }
  Invoke-C28EGate 'scripts\check-personal-care-work-navigation-conformance-c26f.ps1' @{ RepositoryRoot = $root }
  Invoke-C28EGate 'scripts\check-personal-domain-navigation-contract-c25a.ps1' @{ RepositoryRoot = $root }
  Invoke-C28EGate 'scripts\check-personal-subaction-placement-regression.ps1' @{ RepositoryRoot = $root }
  Invoke-C28EGate 'scripts\check-approved-ui-locks.ps1'
  Invoke-C28EGate 'scripts\check-brand-integrity.ps1' @{ Surface = 'App' }
  Invoke-C28EGate 'scripts\check-user-facing-copy.ps1'
  Invoke-C28EGate 'scripts\check-interaction-contracts.ps1'
  Invoke-C28EGate 'scripts\check-mvp-personal-action-projection.ps1' @{ RepositoryRoot = $root }
  Invoke-C28EGate 'scripts\check-mvp-delivery-discipline-lock.ps1' @{ RepositoryRoot = $root; RequireTicketSelectionAssessment = $true }
  Invoke-C28EGate 'scripts\check-mvp-scope-gate-state.ps1' @{ RepositoryRoot = $root }
  Invoke-C28EGate 'scripts\check-codex-development-regression-memory.ps1' @{ Phase = 'implementation'; BuildMode = 'none'; RepositoryRoot = $root }
  Invoke-C28EGate 'scripts\check-buy-protected-baseline.ps1' @{ RepositoryRoot = $root }
  $c28eSocialSeal = @($contract.protectedRuntimeSeals | Where-Object { [string]$_.id -ceq 'social' })[0]
  Invoke-C28EGate 'scripts\check-social-protected-baseline.ps1' @{
    RepositoryRoot = $root
    BaselinePath = Join-Path $root ([string]$c28eSocialSeal.path)
  }
}

$base = Get-Content -Raw -LiteralPath (Join-Path $root ([string]$contract.baseTopology.path)) | ConvertFrom-Json
$tests = @($base.requiredTests) + @($contract.addedTests)
$gates = @($base.requiredGates | Where-Object { [string]$_ -cne [string]$contract.baseTopology.replacedGate }) + @($contract.addedGates)
$formatOwners = @($base.formatOwners) + @($contract.addedFormatOwners)
if (@($tests | Sort-Object -Unique).Count -ne [int]$contract.expectedTotals.requiredTests -or
    @($gates | Sort-Object -Unique).Count -ne [int]$contract.expectedTotals.requiredGates -or
    @($formatOwners | Sort-Object -Unique).Count -ne [int]$contract.expectedTotals.formatOwners) {
  throw 'C28E qualification inventory drifted.'
}

Invoke-C28EGateSet
if ($GatePreflightOnly) {
  Write-Output 'C28E gate-only qualifier preflight passed: tests=53; gates=22; no cycle counted.'
  return
}

$evidencePath = Join-Path $evidenceRoot "qualifying-cycle-$Cycle.json"
if (Test-Path -LiteralPath $evidencePath) {
  throw "C28E refuses to overwrite existing qualifying evidence: $evidencePath"
}
$fingerprintBefore = Get-C28ESourceFingerprint -Root $root -RelativeRoots @($contract.hostQualification.sourceFingerprintScope)
if ($Cycle -eq 2) {
  $cycleOnePath = Join-Path $evidenceRoot 'qualifying-cycle-1.json'
  if (-not (Test-Path -LiteralPath $cycleOnePath -PathType Leaf)) {
    throw 'C28E cycle 2 requires immutable qualifying-cycle-1 evidence.'
  }
  $cycleOne = Get-Content -Raw -LiteralPath $cycleOnePath | ConvertFrom-Json
  if ([int]$cycleOne.cycle -ne 1 -or
      [string]$cycleOne.ticketId -cne [string]$contract.ticketId -or
      [string]$cycleOne.sourceFingerprint -cne $fingerprintBefore) {
    throw 'C28E cycle 2 source fingerprint does not match qualifying cycle 1.'
  }
}

$mobileTests = foreach ($relativeValue in @($tests | Sort-Object -Unique)) {
  $relative = ([string]$relativeValue).Replace('\', '/')
  if (-not $relative.StartsWith('apps/mobile/', [StringComparison]::Ordinal)) {
    throw "C28E required test is outside apps/mobile: $relative"
  }
  $relative.Substring('apps/mobile/'.Length)
}
$mobileFormat = foreach ($relativeValue in @($formatOwners | Sort-Object -Unique)) {
  $relative = ([string]$relativeValue).Replace('\', '/')
  if (-not $relative.StartsWith('apps/mobile/', [StringComparison]::Ordinal)) {
    throw "C28E format owner is outside apps/mobile: $relative"
  }
  $relative.Substring('apps/mobile/'.Length)
}

Push-Location $mobileRoot
try {
  & dart format --output=none --set-exit-if-changed @mobileFormat @mobileTests
  if ($LASTEXITCODE -ne 0) { throw "C28E cycle $Cycle format rejected with exit $LASTEXITCODE." }
  & flutter analyze
  if ($LASTEXITCODE -ne 0) { throw "C28E cycle $Cycle analysis rejected with exit $LASTEXITCODE." }
  & flutter test @mobileTests --reporter compact
  if ($LASTEXITCODE -ne 0) { throw "C28E cycle $Cycle tests rejected with exit $LASTEXITCODE." }
} finally {
  Pop-Location
}

Invoke-C28EGateSet
$fingerprintAfter = Get-C28ESourceFingerprint -Root $root -RelativeRoots @($contract.hostQualification.sourceFingerprintScope)
if ($fingerprintAfter -cne $fingerprintBefore) {
  throw "C28E cycle $Cycle source fingerprint changed: before=$fingerprintBefore after=$fingerprintAfter"
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
Write-Output "C28E host cycle passed: cycle=$Cycle; sourceFingerprint=$fingerprintAfter; tests=$($mobileTests.Count); gates=$(@($gates | Sort-Object -Unique).Count); r60.27Preserved=true; evidence=$evidencePath; evidenceSha256=$evidenceSha."
