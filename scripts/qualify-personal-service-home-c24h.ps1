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
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)
$mobileRoot = Join-Path $root 'apps\mobile'
$contractPath = Join-Path $root 'config\mvp-personal-service-home-host-qualification-c24h.json'
$ticketPath = Join-Path $root 'config\uaw-personal-mvp-service-home-host-qualification-fix7-c24h-ticket.json'
$scopePath = Join-Path $root 'config\mvp-scope-gate-state.json'
$apkPath = Join-Path $root 'config\apk-regression-gate-state.json'
if (-not $EvidenceDirectory) {
  $EvidenceDirectory = Join-Path $root 'artifacts\quality\uaw-c24h-host-qualification-20260809'
}
$evidenceRoot = [IO.Path]::GetFullPath($EvidenceDirectory)
$allowedEvidenceRoot = [IO.Path]::GetFullPath((Join-Path $root 'artifacts\quality'))
if (-not $evidenceRoot.StartsWith($allowedEvidenceRoot, [StringComparison]::OrdinalIgnoreCase)) {
  throw 'C24H evidence directory must remain inside artifacts/quality.'
}
foreach ($path in @($mobileRoot, $contractPath, $ticketPath, $scopePath, $apkPath)) {
  if (-not (Test-Path -LiteralPath $path)) { throw "C24H host required owner is missing: $path" }
}

function Get-C24SourceFingerprint {
  param(
    [Parameter(Mandatory = $true)][string]$Root,
    [Parameter(Mandatory = $true)][object[]]$RelativeRoots
  )
  $files = foreach ($relativeRootValue in $RelativeRoots) {
    $relativeRoot = [string]$relativeRootValue
    $resolvedRoot = [IO.Path]::GetFullPath((Join-Path $Root $relativeRoot))
    if (-not $resolvedRoot.StartsWith($Root, [StringComparison]::OrdinalIgnoreCase) -or
        -not (Test-Path -LiteralPath $resolvedRoot -PathType Container)) {
      throw "C24H fingerprint root is missing or outside repository: $relativeRoot"
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

function Invoke-C24Gate {
  param(
    [Parameter(Mandatory = $true)][string]$RelativePath,
    [hashtable]$Parameters = @{}
  )
  $path = Join-Path $root $RelativePath
  & $path @Parameters
}

function Invoke-C24GateSet {
  Invoke-C24Gate -RelativePath 'scripts\check-personal-service-home-host-qualification-c24h.ps1' -Parameters @{ RepositoryRoot = $root }
  Invoke-C24Gate -RelativePath 'scripts\check-personal-subaction-placement-regression.ps1' -Parameters @{ RepositoryRoot = $root }
  Invoke-C24Gate -RelativePath 'scripts\check-approved-ui-locks.ps1'
  Invoke-C24Gate -RelativePath 'scripts\check-brand-integrity.ps1' -Parameters @{ Surface = 'App' }
  Invoke-C24Gate -RelativePath 'scripts\check-user-facing-copy.ps1'
  Invoke-C24Gate -RelativePath 'scripts\check-interaction-contracts.ps1'
  Invoke-C24Gate -RelativePath 'scripts\check-mvp-personal-action-projection.ps1' -Parameters @{ RepositoryRoot = $root }
  Invoke-C24Gate -RelativePath 'scripts\check-mvp-delivery-discipline-lock.ps1' -Parameters @{ RepositoryRoot = $root; RequireTicketSelectionAssessment = $true }
  Invoke-C24Gate -RelativePath 'scripts\check-mvp-scope-gate-state.ps1' -Parameters @{ RepositoryRoot = $root }
  Invoke-C24Gate -RelativePath 'scripts\check-codex-development-regression-memory.ps1' -Parameters @{ Phase = 'implementation'; BuildMode = 'none'; RepositoryRoot = $root }
  Invoke-C24Gate -RelativePath 'scripts\check-buy-protected-baseline.ps1' -Parameters @{ RepositoryRoot = $root }
  Invoke-C24Gate -RelativePath 'scripts\check-social-protected-baseline.ps1' -Parameters @{ RepositoryRoot = $root }
}

$contract = Get-Content -Raw -LiteralPath $contractPath | ConvertFrom-Json
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$apk = Get-Content -Raw -LiteralPath $apkPath | ConvertFrom-Json
$expectedTicket = 'UAW-PERSONAL-MVP-SERVICE-HOME-HOST-QUALIFICATION-FIX7-C24H'
if ([string]$ticket.ticketId -cne $expectedTicket -or
    [string]$ticket.state -cne 'selected_host_qualification_execution_open' -or
    [string]$scope.ticket.id -cne $expectedTicket -or
    [string]$scope.preTicketSelectionCheckpoint.currentTicketId -cne $expectedTicket -or
    [bool]$scope.execution.runtimeWriteAuthorized -or
    [bool]$scope.execution.buildAuthorized -or
    [bool]$scope.execution.deviceInstallAuthorized) {
  throw 'C24H host ticket identity or closed authority is invalid.'
}
$hostContract = $contract.hostQualification
if ([int]$hostContract.requiredConsecutiveCycles -ne 2 -or
    [string]$hostContract.sourceFingerprintAlgorithm -cne 'SHA256_OF_SORTED_PER_FILE_SHA256_AND_REPOSITORY_RELATIVE_PATH_USING_LF' -or
    -not [bool]$hostContract.unchangedSourceFingerprintRequired -or
    -not [bool]$hostContract.completeAnalysisRequired -or
    -not [bool]$hostContract.completeRequiredSuiteRequired -or
    @($contract.requiredTests).Count -ne 38 -or
    @($contract.requiredGates).Count -ne 12) {
  throw 'C24H host qualification contract has drifted.'
}
$expectedApk = $contract.expectedInstalledPredecessor
if ([string]$apk.machineState -cne [string]$expectedApk.machineState -or
    [string]$apk.installResult.installedBaseSha256 -cne [string]$expectedApk.apkSha256 -or
    [bool]$apk.founderDeviceReview.successorBuildAuthorized -or
    [bool]$apk.founderDeviceReview.successorInstallAuthorized) {
  throw 'C24H host qualification refuses changed r60.22 identity or open successor authority.'
}
if ($GatePreflightOnly) {
  Invoke-C24GateSet
  Write-Output 'C24H gate-only qualifier preflight passed: requiredGates=12; no format, analyze, test, fingerprint seal or evidence cycle counted.'
  return
}

$fingerprintBefore = Get-C24SourceFingerprint -Root $root -RelativeRoots @($hostContract.sourceFingerprintScope)
$allTests = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($relativeValue in @($contract.requiredTests)) {
  [void]$allTests.Add(([string]$relativeValue).Replace('\', '/'))
}
foreach ($manifest in @($contract.protectedTestManifests)) {
  $manifestPath = Join-Path $root ([string]$manifest.path)
  $manifestEntries = @(Get-Content -LiteralPath $manifestPath | Where-Object { $_.Trim() })
  if ($manifestEntries.Count -ne [int]$manifest.expectedFiles) {
    throw "C24H protected $($manifest.id) manifest count drifted."
  }
  foreach ($entry in $manifestEntries) { [void]$allTests.Add(([string]$entry).Replace('\', '/')) }
}
$repositoryTests = @($allTests | Sort-Object)
$mobileTests = foreach ($relative in $repositoryTests) {
  $prefix = 'apps/mobile/'
  if (-not $relative.StartsWith($prefix, [StringComparison]::Ordinal)) {
    throw "C24H required test is outside apps/mobile: $relative"
  }
  if (-not (Test-Path -LiteralPath (Join-Path $root $relative) -PathType Leaf)) {
    throw "C24H required test is missing: $relative"
  }
  $relative.Substring($prefix.Length)
}
$formatOwners = foreach ($relativeValue in @($contract.formatOwners)) {
  $relative = ([string]$relativeValue).Replace('\', '/')
  $prefix = 'apps/mobile/'
  if (-not $relative.StartsWith($prefix, [StringComparison]::Ordinal)) {
    throw "C24H format owner is outside apps/mobile: $relative"
  }
  $relative.Substring($prefix.Length)
}
$formatTests = foreach ($relative in @($contract.requiredTests)) {
  ([string]$relative).Substring('apps/mobile/'.Length)
}

Push-Location $mobileRoot
try {
  & dart format --output=none --set-exit-if-changed @formatOwners @formatTests
  if ($LASTEXITCODE -ne 0) { throw "C24H cycle $Cycle format check rejected with exit $LASTEXITCODE." }
  & flutter analyze
  if ($LASTEXITCODE -ne 0) { throw "C24H cycle $Cycle complete analysis rejected with exit $LASTEXITCODE." }
  & flutter test @mobileTests --reporter compact
  if ($LASTEXITCODE -ne 0) { throw "C24H cycle $Cycle complete required suite rejected with exit $LASTEXITCODE." }
} finally {
  Pop-Location
}

Invoke-C24GateSet

$fingerprintAfter = Get-C24SourceFingerprint -Root $root -RelativeRoots @($hostContract.sourceFingerprintScope)
if ($fingerprintAfter -cne $fingerprintBefore) {
  throw "C24H cycle $Cycle source fingerprint changed: before=$fingerprintBefore after=$fingerprintAfter"
}

[IO.Directory]::CreateDirectory($evidenceRoot) | Out-Null
$evidencePath = Join-Path $evidenceRoot "qualifying-cycle-$Cycle.json"
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

Write-Output "C24H host cycle passed: cycle=$Cycle; sourceFingerprint=$fingerprintAfter; format=clean; completeAnalysis=clean; requiredTestFiles=$($mobileTests.Count); requiredGates=$(@($contract.requiredGates).Count); installedR60.22Preserved=true; runtimeBuildInstall=closed; evidence=$evidencePath; evidenceSha256=$evidenceSha."
