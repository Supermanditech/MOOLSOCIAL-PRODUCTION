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
$contractPath = Join-Path $root 'config\mvp-personal-domain-navigation-host-qualification-c25g.json'
$ticketPath = Join-Path $root 'config\uaw-personal-mvp-domain-navigation-host-qualification-fix8-c25g-ticket.json'
$parentPath = Join-Path $root 'config\uaw-personal-mvp-domain-navigation-and-destination-rail-recovery-fix8-c25-ticket.json'
$scopePath = Join-Path $root 'config\mvp-scope-gate-state.json'
$apkPath = Join-Path $root 'config\apk-regression-gate-state.json'
if (-not $EvidenceDirectory) {
  $EvidenceDirectory = Join-Path $root 'artifacts\quality\uaw-c25g-host-qualification-20260809-01'
}
$evidenceRoot = [IO.Path]::GetFullPath($EvidenceDirectory)
$allowedEvidenceRoot = [IO.Path]::GetFullPath((Join-Path $root 'artifacts\quality'))
if (-not $evidenceRoot.StartsWith($allowedEvidenceRoot, [StringComparison]::OrdinalIgnoreCase)) {
  throw 'C25G evidence directory must remain inside artifacts/quality.'
}
foreach ($path in @($mobileRoot, $contractPath, $ticketPath, $parentPath, $scopePath, $apkPath)) {
  if (-not (Test-Path -LiteralPath $path)) { throw "C25G host required owner is missing: $path" }
}

function Get-C25GSourceFingerprint {
  param(
    [Parameter(Mandatory = $true)][string]$Root,
    [Parameter(Mandatory = $true)][object[]]$RelativeRoots
  )
  $files = foreach ($relativeRootValue in $RelativeRoots) {
    $relativeRoot = [string]$relativeRootValue
    $resolvedRoot = [IO.Path]::GetFullPath((Join-Path $Root $relativeRoot))
    if (-not $resolvedRoot.StartsWith($Root, [StringComparison]::OrdinalIgnoreCase) -or
        -not (Test-Path -LiteralPath $resolvedRoot -PathType Container)) {
      throw "C25G fingerprint root is missing or outside repository: $relativeRoot"
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

function Invoke-C25GGate {
  param(
    [Parameter(Mandatory = $true)][string]$RelativePath,
    [hashtable]$Parameters = @{}
  )
  $path = Join-Path $root $RelativePath
  & $path @Parameters
}

function Invoke-C25GGateSet {
  Invoke-C25GGate -RelativePath 'scripts\check-personal-domain-navigation-host-qualification-c25g.ps1' -Parameters @{ RepositoryRoot = $root }
  Invoke-C25GGate -RelativePath 'scripts\check-personal-domain-navigation-contract-c25a.ps1' -Parameters @{ RepositoryRoot = $root }
  Invoke-C25GGate -RelativePath 'scripts\check-personal-domain-navigation-adaptive-reachability-c25f.ps1' -Parameters @{ RepositoryRoot = $root }
  Invoke-C25GGate -RelativePath 'scripts\check-personal-subaction-placement-regression.ps1' -Parameters @{ RepositoryRoot = $root }
  Invoke-C25GGate -RelativePath 'scripts\check-approved-ui-locks.ps1'
  Invoke-C25GGate -RelativePath 'scripts\check-brand-integrity.ps1' -Parameters @{ Surface = 'App' }
  Invoke-C25GGate -RelativePath 'scripts\check-user-facing-copy.ps1'
  Invoke-C25GGate -RelativePath 'scripts\check-interaction-contracts.ps1'
  Invoke-C25GGate -RelativePath 'scripts\check-mvp-personal-action-projection.ps1' -Parameters @{ RepositoryRoot = $root }
  Invoke-C25GGate -RelativePath 'scripts\check-mvp-delivery-discipline-lock.ps1' -Parameters @{ RepositoryRoot = $root; RequireTicketSelectionAssessment = $true }
  Invoke-C25GGate -RelativePath 'scripts\check-mvp-scope-gate-state.ps1' -Parameters @{ RepositoryRoot = $root }
  Invoke-C25GGate -RelativePath 'scripts\check-codex-development-regression-memory.ps1' -Parameters @{ Phase = 'implementation'; BuildMode = 'none'; RepositoryRoot = $root }
  Invoke-C25GGate -RelativePath 'scripts\check-buy-protected-baseline.ps1' -Parameters @{ RepositoryRoot = $root }
  Invoke-C25GGate -RelativePath 'scripts\check-social-protected-baseline.ps1' -Parameters @{ RepositoryRoot = $root }
}

$contract = Get-Content -Raw -LiteralPath $contractPath | ConvertFrom-Json
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$parent = Get-Content -Raw -LiteralPath $parentPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$apk = Get-Content -Raw -LiteralPath $apkPath | ConvertFrom-Json
$expectedTicket = 'UAW-PERSONAL-MVP-DOMAIN-NAVIGATION-HOST-QUALIFICATION-FIX8-C25G'
$expectedSuccessor = 'UAW-PERSONAL-MVP-DOMAIN-NAVIGATION-OPPO-QUALIFICATION-FIX8-C25H'
$completedChild = @($parent.children | Where-Object { [string]$_.ticketId -ceq $expectedTicket })
$activeState = (
  [string]$ticket.state -ceq 'selected_host_qualification_gate_writes_authorized' -and
  [string]$scope.ticket.id -ceq $expectedTicket -and
  [string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq $expectedTicket -and
  [string]$parent.execution.currentChild -ceq $expectedTicket
)
$completedState = (
  [string]$ticket.state -ceq 'complete' -and
  $completedChild.Count -eq 1 -and
  [string]$completedChild[0].state -ceq 'complete' -and
  [string]$scope.ticket.id -ceq $expectedSuccessor -and
  [string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq $expectedSuccessor -and
  [string]$parent.execution.currentChild -ceq $expectedSuccessor
)
if ([string]$ticket.ticketId -cne $expectedTicket -or
    -not ($activeState -or $completedState) -or
    [bool]$scope.execution.runtimeWriteAuthorized -or
    [bool]$scope.execution.backendWriteAuthorized -or
    [bool]$scope.execution.buildAuthorized -or
    [bool]$scope.execution.deviceInstallAuthorized -or
    [bool]$scope.execution.externalServiceWriteAuthorized) {
  throw 'C25G host ticket identity or closed authority is invalid.'
}
$hostContract = $contract.hostQualification
if ([int]$hostContract.requiredConsecutiveCycles -ne 2 -or
    [string]$hostContract.sourceFingerprintAlgorithm -cne 'SHA256_OF_SORTED_PER_FILE_SHA256_AND_REPOSITORY_RELATIVE_PATH_USING_LF' -or
    -not [bool]$hostContract.unchangedSourceFingerprintRequired -or
    -not [bool]$hostContract.completeAnalysisRequired -or
    -not [bool]$hostContract.completeRequiredSuiteRequired -or
    @($contract.requiredTests).Count -ne 43 -or
    @($contract.requiredGates).Count -ne 14) {
  throw 'C25G host qualification contract has drifted.'
}
$expectedApk = $contract.expectedInstalledPredecessor
if ([string]$apk.machineState -cne [string]$expectedApk.machineState -or
    [string]$apk.installResult.installedBaseSha256 -cne [string]$expectedApk.apkSha256 -or
    [bool]$apk.founderDeviceReview.successorBuildAuthorized -or
    [bool]$apk.founderDeviceReview.successorInstallAuthorized) {
  throw 'C25G host qualification refuses changed r60.23 identity or open successor authority.'
}
if ($GatePreflightOnly) {
  Invoke-C25GGateSet
  Write-Output 'C25G gate-only qualifier preflight passed: requiredGates=14; no format, analyze, test, fingerprint seal or evidence cycle counted.'
  return
}

$evidencePath = Join-Path $evidenceRoot "qualifying-cycle-$Cycle.json"
if (Test-Path -LiteralPath $evidencePath) {
  throw "C25G refuses to overwrite existing qualifying evidence: $evidencePath"
}
$fingerprintBefore = Get-C25GSourceFingerprint -Root $root -RelativeRoots @($hostContract.sourceFingerprintScope)
if ($Cycle -eq 2) {
  $cycleOnePath = Join-Path $evidenceRoot 'qualifying-cycle-1.json'
  if (-not (Test-Path -LiteralPath $cycleOnePath -PathType Leaf)) {
    throw 'C25G cycle 2 requires immutable qualifying-cycle-1 evidence.'
  }
  $cycleOne = Get-Content -Raw -LiteralPath $cycleOnePath | ConvertFrom-Json
  if ([int]$cycleOne.cycle -ne 1 -or [string]$cycleOne.ticketId -cne $expectedTicket -or
      [string]$cycleOne.sourceFingerprint -cne $fingerprintBefore) {
    throw 'C25G cycle 2 source fingerprint does not match qualifying cycle 1.'
  }
}

$allTests = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($relativeValue in @($contract.requiredTests)) {
  [void]$allTests.Add(([string]$relativeValue).Replace('\', '/'))
}
$repositoryTests = @($allTests | Sort-Object)
if ($repositoryTests.Count -ne 43) { throw 'C25G unique required test count drifted.' }
$mobileTests = foreach ($relative in $repositoryTests) {
  $prefix = 'apps/mobile/'
  if (-not $relative.StartsWith($prefix, [StringComparison]::Ordinal)) {
    throw "C25G required test is outside apps/mobile: $relative"
  }
  if (-not (Test-Path -LiteralPath (Join-Path $root $relative) -PathType Leaf)) {
    throw "C25G required test is missing: $relative"
  }
  $relative.Substring($prefix.Length)
}
$formatOwners = foreach ($relativeValue in @($contract.formatOwners)) {
  $relative = ([string]$relativeValue).Replace('\', '/')
  $prefix = 'apps/mobile/'
  if (-not $relative.StartsWith($prefix, [StringComparison]::Ordinal)) {
    throw "C25G format owner is outside apps/mobile: $relative"
  }
  $relative.Substring($prefix.Length)
}

Push-Location $mobileRoot
try {
  & dart format --output=none --set-exit-if-changed @formatOwners @mobileTests
  if ($LASTEXITCODE -ne 0) { throw "C25G cycle $Cycle format check rejected with exit $LASTEXITCODE." }
  & flutter analyze
  if ($LASTEXITCODE -ne 0) { throw "C25G cycle $Cycle complete analysis rejected with exit $LASTEXITCODE." }
  & flutter test @mobileTests --reporter compact
  if ($LASTEXITCODE -ne 0) { throw "C25G cycle $Cycle complete required suite rejected with exit $LASTEXITCODE." }
} finally {
  Pop-Location
}

Invoke-C25GGateSet

$fingerprintAfter = Get-C25GSourceFingerprint -Root $root -RelativeRoots @($hostContract.sourceFingerprintScope)
if ($fingerprintAfter -cne $fingerprintBefore) {
  throw "C25G cycle $Cycle source fingerprint changed: before=$fingerprintBefore after=$fingerprintAfter"
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

Write-Output "C25G host cycle passed: cycle=$Cycle; sourceFingerprint=$fingerprintAfter; format=clean; completeAnalysis=clean; requiredTestFiles=$($mobileTests.Count); requiredGates=$(@($contract.requiredGates).Count); installedR60.23Preserved=true; runtimeBuildInstall=closed; evidence=$evidencePath; evidenceSha256=$evidenceSha."
