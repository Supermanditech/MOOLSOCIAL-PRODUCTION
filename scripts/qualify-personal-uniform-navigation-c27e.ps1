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
$contractPath = Join-Path $root 'config\mvp-personal-uniform-navigation-host-qualification-c27e.json'
$ticketPath = Join-Path $root 'config\uaw-personal-mvp-uniform-navigation-host-qualification-fix10-c27e-ticket.json'
$scopePath = Join-Path $root 'config\mvp-scope-gate-state.json'
$apkPath = Join-Path $root 'config\apk-regression-gate-state.json'
if (-not $EvidenceDirectory) {
  $EvidenceDirectory = Join-Path $root 'artifacts\quality\uaw-c27e-host-qualification-20260810-01'
}
$evidenceRoot = [IO.Path]::GetFullPath($EvidenceDirectory)
$allowedEvidenceRoot = [IO.Path]::GetFullPath((Join-Path $root 'artifacts\quality'))
if (-not $evidenceRoot.StartsWith($allowedEvidenceRoot, [StringComparison]::OrdinalIgnoreCase)) {
  throw 'C27E evidence directory must remain inside artifacts/quality.'
}
foreach ($path in @($mobileRoot, $contractPath, $ticketPath, $scopePath, $apkPath)) {
  if (-not (Test-Path -LiteralPath $path)) { throw "C27E host required owner is missing: $path" }
}

function Get-C27ESourceFingerprint {
  param(
    [Parameter(Mandatory = $true)][string]$Root,
    [Parameter(Mandatory = $true)][object[]]$RelativeRoots
  )
  $files = foreach ($relativeRootValue in $RelativeRoots) {
    $relativeRoot = [string]$relativeRootValue
    $resolvedRoot = [IO.Path]::GetFullPath((Join-Path $Root $relativeRoot))
    if (-not $resolvedRoot.StartsWith($Root, [StringComparison]::OrdinalIgnoreCase) -or
        -not (Test-Path -LiteralPath $resolvedRoot -PathType Container)) {
      throw "C27E fingerprint root is missing or outside repository: $relativeRoot"
    }
    Get-ChildItem -LiteralPath $resolvedRoot -Recurse -File
  }
  $records = foreach ($file in @($files | Sort-Object FullName -Unique)) {
    $relativePath = [IO.Path]::GetRelativePath($Root, $file.FullName).Replace('\', '/')
    "$((Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName).Hash)  $relativePath"
  }
  $bytes = [Text.Encoding]::UTF8.GetBytes(($records -join "`n"))
  $sha = [Security.Cryptography.SHA256]::Create()
  try { return [Convert]::ToHexString($sha.ComputeHash($bytes)) } finally { $sha.Dispose() }
}

function Invoke-C27EGate {
  param(
    [Parameter(Mandatory = $true)][string]$RelativePath,
    [hashtable]$Parameters = @{}
  )
  & (Join-Path $root $RelativePath) @Parameters
}

function Invoke-C27EGateSet {
  Invoke-C27EGate -RelativePath 'scripts\check-personal-uniform-navigation-host-qualification-c27e.ps1' -Parameters @{ RepositoryRoot = $root }
  Invoke-C27EGate -RelativePath 'scripts\check-personal-uniform-navigation-design-system-c27b.ps1' -Parameters @{ RepositoryRoot = $root }
  Invoke-C27EGate -RelativePath 'scripts\check-personal-uniform-embedded-switcher-c27c.ps1' -Parameters @{ RepositoryRoot = $root }
  Invoke-C27EGate -RelativePath 'scripts\check-personal-uniform-navigation-six-family-conformance-c27d.ps1' -Parameters @{ RepositoryRoot = $root }
  Invoke-C27EGate -RelativePath 'scripts\check-personal-transparent-unboxed-destination-rail-c26b.ps1' -Parameters @{ RepositoryRoot = $root }
  Invoke-C27EGate -RelativePath 'scripts\check-personal-embedded-vertical-mool-switcher-c26c.ps1' -Parameters @{ RepositoryRoot = $root }
  Invoke-C27EGate -RelativePath 'scripts\check-personal-social-shop-navigation-conformance-c26d.ps1' -Parameters @{ RepositoryRoot = $root }
  Invoke-C27EGate -RelativePath 'scripts\check-personal-food-travel-navigation-conformance-c26e.ps1' -Parameters @{ RepositoryRoot = $root }
  Invoke-C27EGate -RelativePath 'scripts\check-personal-care-work-navigation-conformance-c26f.ps1' -Parameters @{ RepositoryRoot = $root }
  Invoke-C27EGate -RelativePath 'scripts\check-personal-domain-navigation-contract-c25a.ps1' -Parameters @{ RepositoryRoot = $root }
  Invoke-C27EGate -RelativePath 'scripts\check-personal-subaction-placement-regression.ps1' -Parameters @{ RepositoryRoot = $root }
  Invoke-C27EGate -RelativePath 'scripts\check-approved-ui-locks.ps1'
  Invoke-C27EGate -RelativePath 'scripts\check-brand-integrity.ps1' -Parameters @{ Surface = 'App' }
  Invoke-C27EGate -RelativePath 'scripts\check-user-facing-copy.ps1'
  Invoke-C27EGate -RelativePath 'scripts\check-interaction-contracts.ps1'
  Invoke-C27EGate -RelativePath 'scripts\check-mvp-personal-action-projection.ps1' -Parameters @{ RepositoryRoot = $root }
  Invoke-C27EGate -RelativePath 'scripts\check-mvp-delivery-discipline-lock.ps1' -Parameters @{ RepositoryRoot = $root; RequireTicketSelectionAssessment = $true }
  Invoke-C27EGate -RelativePath 'scripts\check-mvp-scope-gate-state.ps1' -Parameters @{ RepositoryRoot = $root }
  Invoke-C27EGate -RelativePath 'scripts\check-codex-development-regression-memory.ps1' -Parameters @{ Phase = 'implementation'; BuildMode = 'none'; RepositoryRoot = $root }
  Invoke-C27EGate -RelativePath 'scripts\check-buy-protected-baseline.ps1' -Parameters @{ RepositoryRoot = $root }
  Invoke-C27EGate -RelativePath 'scripts\check-social-protected-baseline.ps1' -Parameters @{ RepositoryRoot = $root }
}

$contract = Get-Content -Raw -LiteralPath $contractPath | ConvertFrom-Json
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$apk = Get-Content -Raw -LiteralPath $apkPath | ConvertFrom-Json
$expectedTicket = 'UAW-PERSONAL-MVP-UNIFORM-NAVIGATION-HOST-QUALIFICATION-FIX10-C27E'
$ticketSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash
if ([string]$ticket.ticketId -cne $expectedTicket -or
    [string]$ticket.state -cne 'active' -or
    [string]$contract.ticketManifestSha256 -cne $ticketSha -or
    [string]$scope.ticket.id -cne $expectedTicket -or
    [string]$scope.preTicketSelectionCheckpoint.currentTicketId -cne $expectedTicket -or
    [string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -cne $ticketSha -or
    [bool]$scope.execution.backendWriteAuthorized -or
    [bool]$scope.execution.buildAuthorized -or
    [bool]$scope.execution.deviceInstallAuthorized -or
    [bool]$scope.execution.externalServiceWriteAuthorized) {
  throw 'C27E host ticket identity, manifest seal or closed backend/build/install/external authority is invalid.'
}
$hostContract = $contract.hostQualification
if ([int]$hostContract.requiredConsecutiveCycles -ne 2 -or
    [string]$hostContract.sourceFingerprintAlgorithm -cne 'SHA256_OF_SORTED_PER_FILE_SHA256_AND_REPOSITORY_RELATIVE_PATH_USING_LF' -or
    -not [bool]$hostContract.unchangedSourceFingerprintRequired -or
    -not [bool]$hostContract.completeAnalysisRequired -or
    -not [bool]$hostContract.completeRequiredSuiteRequired -or
    @($contract.requiredTests).Count -ne 51 -or
    @($contract.requiredGates).Count -ne 21) {
  throw 'C27E host qualification contract has drifted.'
}
$expectedApk = $contract.expectedInstalledPredecessor
if ([string]$apk.machineState -cne [string]$expectedApk.machineState -or
    [string]$apk.buildAuthorization -cne [string]$expectedApk.buildAuthorization -or
    [string]$apk.installResult.installedBaseSha256 -cne [string]$expectedApk.apkSha256 -or
    [bool]$apk.founderDeviceReview.successorBuildAuthorized -or
    [bool]$apk.founderDeviceReview.successorInstallAuthorized) {
  throw 'C27E host qualification refuses changed r60.25 identity or open successor authority.'
}
if ($GatePreflightOnly) {
  Invoke-C27EGateSet
  Write-Output 'C27E gate-only qualifier preflight passed: requiredGates=21; no format, analyze, test, fingerprint seal or evidence cycle counted.'
  return
}

$evidencePath = Join-Path $evidenceRoot "qualifying-cycle-$Cycle.json"
if (Test-Path -LiteralPath $evidencePath) {
  throw "C27E refuses to overwrite existing qualifying evidence: $evidencePath"
}
$fingerprintBefore = Get-C27ESourceFingerprint -Root $root -RelativeRoots @($hostContract.sourceFingerprintScope)
if ($Cycle -eq 2) {
  $cycleOnePath = Join-Path $evidenceRoot 'qualifying-cycle-1.json'
  if (-not (Test-Path -LiteralPath $cycleOnePath -PathType Leaf)) {
    throw 'C27E cycle 2 requires immutable qualifying-cycle-1 evidence.'
  }
  $cycleOne = Get-Content -Raw -LiteralPath $cycleOnePath | ConvertFrom-Json
  if ([int]$cycleOne.cycle -ne 1 -or [string]$cycleOne.ticketId -cne $expectedTicket -or
      [string]$cycleOne.sourceFingerprint -cne $fingerprintBefore) {
    throw 'C27E cycle 2 source fingerprint does not match qualifying cycle 1.'
  }
}

$uniqueTests = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($relativeValue in @($contract.requiredTests)) {
  [void]$uniqueTests.Add(([string]$relativeValue).Replace('\', '/'))
}
$repositoryTests = @($uniqueTests | Sort-Object)
if ($repositoryTests.Count -ne 51) { throw 'C27E unique required test count drifted.' }
$mobileTests = foreach ($relative in $repositoryTests) {
  $prefix = 'apps/mobile/'
  if (-not $relative.StartsWith($prefix, [StringComparison]::Ordinal)) {
    throw "C27E required test is outside apps/mobile: $relative"
  }
  if (-not (Test-Path -LiteralPath (Join-Path $root $relative) -PathType Leaf)) {
    throw "C27E required test is missing: $relative"
  }
  $relative.Substring($prefix.Length)
}
$formatOwners = foreach ($relativeValue in @($contract.formatOwners)) {
  $relative = ([string]$relativeValue).Replace('\', '/')
  $prefix = 'apps/mobile/'
  if (-not $relative.StartsWith($prefix, [StringComparison]::Ordinal)) {
    throw "C27E format owner is outside apps/mobile: $relative"
  }
  $relative.Substring($prefix.Length)
}

Push-Location $mobileRoot
try {
  & dart format --output=none --set-exit-if-changed @formatOwners @mobileTests
  if ($LASTEXITCODE -ne 0) { throw "C27E cycle $Cycle format check rejected with exit $LASTEXITCODE." }
  & flutter analyze
  if ($LASTEXITCODE -ne 0) { throw "C27E cycle $Cycle complete analysis rejected with exit $LASTEXITCODE." }
  & flutter test @mobileTests --reporter compact
  if ($LASTEXITCODE -ne 0) { throw "C27E cycle $Cycle complete required suite rejected with exit $LASTEXITCODE." }
} finally {
  Pop-Location
}

Invoke-C27EGateSet
$fingerprintAfter = Get-C27ESourceFingerprint -Root $root -RelativeRoots @($hostContract.sourceFingerprintScope)
if ($fingerprintAfter -cne $fingerprintBefore) {
  throw "C27E cycle $Cycle source fingerprint changed: before=$fingerprintBefore after=$fingerprintAfter"
}

[IO.Directory]::CreateDirectory($evidenceRoot) | Out-Null
$evidence = [ordered]@{
  schemaVersion = 1
  ticketId = $expectedTicket
  cycle = $Cycle
  sourceFingerprint = $fingerprintAfter
  fingerprintAlgorithm = [string]$hostContract.sourceFingerprintAlgorithm
  requiredTestFiles = $mobileTests.Count
  requiredGateCount = @($contract.requiredGates).Count
  format = 'clean'
  completeAnalysis = 'clean'
  completeRequiredSuite = 'passed'
  installedVersionName = [string]$expectedApk.versionName
  installedVersionCode = [string]$expectedApk.versionCode
  installedApkSha256 = [string]$expectedApk.apkSha256
  runtimeBuildInstall = 'closed'
}
[IO.File]::WriteAllText($evidencePath, (($evidence | ConvertTo-Json -Depth 5) + "`n"), [Text.UTF8Encoding]::new($false))
$evidenceSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $evidencePath).Hash

Write-Output "C27E host cycle passed: cycle=$Cycle; sourceFingerprint=$fingerprintAfter; format=clean; completeAnalysis=clean; requiredTestFiles=$($mobileTests.Count); requiredGates=$(@($contract.requiredGates).Count); installedR60.25Preserved=true; runtimeBuildInstall=closed; evidence=$evidencePath; evidenceSha256=$evidenceSha."
