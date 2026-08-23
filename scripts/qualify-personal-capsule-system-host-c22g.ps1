[CmdletBinding()]
param(
  [string]$RepositoryRoot,
  [Parameter(Mandatory = $true)]
  [ValidateSet(1, 2)]
  [int]$Cycle
)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)
$mobileRoot = Join-Path $root 'apps\mobile'
$ticketPath = Join-Path $root 'config\uaw-personal-mvp-capsule-system-host-qualification-fix5-c22g-ticket.json'
$scopePath = Join-Path $root 'config\mvp-scope-gate-state.json'
$contractPath = Join-Path $root 'config\mvp-personal-capsule-system-regression-c22.json'
$apkPath = Join-Path $root 'config\apk-regression-gate-state.json'
$aggregateGate = Join-Path $root 'scripts\check-personal-capsule-system-c22g.ps1'

foreach ($path in @($mobileRoot, $ticketPath, $scopePath, $contractPath, $apkPath, $aggregateGate)) {
  if (-not (Test-Path -LiteralPath $path)) { throw "C22G host required owner is missing: $path" }
}

function Get-C22SourceFingerprint {
  param([Parameter(Mandatory = $true)][string]$Root)
  $files = foreach ($relativeRoot in @('apps/mobile/lib', 'apps/mobile/test', 'scripts')) {
    $resolvedRoot = [IO.Path]::GetFullPath((Join-Path $Root $relativeRoot))
    if (-not $resolvedRoot.StartsWith($Root, [StringComparison]::OrdinalIgnoreCase) -or
        -not (Test-Path -LiteralPath $resolvedRoot -PathType Container)) {
      throw "C22G fingerprint root is missing or outside repository: $relativeRoot"
    }
    Get-ChildItem -LiteralPath $resolvedRoot -Recurse -File
  }
  $records = foreach ($file in @($files | Sort-Object FullName)) {
    $relativePath = [IO.Path]::GetRelativePath($Root, $file.FullName).Replace('\', '/')
    "$((Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName).Hash)  $relativePath"
  }
  $bytes = [Text.Encoding]::UTF8.GetBytes(($records -join "`n"))
  $sha = [Security.Cryptography.SHA256]::Create()
  try { return [Convert]::ToHexString($sha.ComputeHash($bytes)) } finally { $sha.Dispose() }
}

$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$contract = Get-Content -Raw -LiteralPath $contractPath | ConvertFrom-Json
$apk = Get-Content -Raw -LiteralPath $apkPath | ConvertFrom-Json
$expected = 'UAW-PERSONAL-MVP-CAPSULE-SYSTEM-HOST-QUALIFICATION-FIX5-C22G'
if ([string]$ticket.ticketId -cne $expected -or [string]$scope.ticket.id -cne $expected -or
    [string]$scope.preTicketSelectionCheckpoint.currentTicketId -cne $expected -or
    [string]$scope.state -cne 'ticket_disclosed_and_authorized') {
  throw 'C22G host ticket or active scope identity is invalid.'
}
$hostQualificationContract = $contract.hostQualification
if ([int]$hostQualificationContract.requiredConsecutiveCycles -ne 2 -or
    [string]$hostQualificationContract.sourceFingerprintAlgorithm -cne 'SHA256_OF_SORTED_PER_FILE_SHA256_AND_REPOSITORY_RELATIVE_PATH_USING_LF' -or
    (@($hostQualificationContract.sourceFingerprintScope) -join ',') -cne 'apps/mobile/lib,apps/mobile/test,scripts' -or
    -not [bool]$hostQualificationContract.unchangedSourceFingerprintRequired -or -not [bool]$hostQualificationContract.completeRequiredSuiteRequired -or
    @($contract.requiredTests).Count -ne 15 -or [int]$contract.requiredGateCount -ne 12 -or
    [bool]$scope.execution.runtimeWriteAuthorized -or [bool]$scope.execution.buildAuthorized -or
    [bool]$scope.execution.deviceInstallAuthorized -or [bool]$contract.runtimeMutationAuthorized -or
    [bool]$contract.buildAuthorized -or [bool]$contract.installAuthorized) {
  throw 'C22G host qualification or closed-authority contract has drifted.'
}
if ([string]$apk.machineState -cne 'r60_20_founder_rejected_installed_checksum_identity_preserved_successor_build_closed' -or
    [string]$apk.buildAuthorization -cne 'consumed_no_second_build' -or
    [string]$apk.installResult.installedBaseSha256 -cne 'FF3932D84794BA8802946CBB04F8A346F34386F4A5C8321F3970AD8E6228EF8A' -or
    [bool]$apk.founderDeviceReview.successorBuildAuthorized -or [bool]$apk.founderDeviceReview.successorInstallAuthorized) {
  throw 'C22G host qualification refuses changed r60.20 identity or open successor authority.'
}

$fingerprintBefore = Get-C22SourceFingerprint -Root $root
$mobileTests = foreach ($relative in @($contract.requiredTests)) {
  $prefix = 'apps/mobile/'
  if (-not ([string]$relative).StartsWith($prefix, [StringComparison]::Ordinal)) {
    throw "C22G required test path is outside apps/mobile: $relative"
  }
  ([string]$relative).Substring($prefix.Length)
}
$formatFiles = @(
  'lib/core/design/mool_design_system.dart',
  'lib/ui_v2/universal/mool_global_navigation_v2.dart'
) + $mobileTests
foreach ($relative in $formatFiles) {
  if (-not (Test-Path -LiteralPath (Join-Path $mobileRoot $relative) -PathType Leaf)) {
    throw "C22G affected format file is missing: $relative"
  }
}

Push-Location $mobileRoot
try {
  & dart format --output=none --set-exit-if-changed @formatFiles
  if ($LASTEXITCODE -ne 0) { throw "C22G cycle $Cycle format check rejected with exit $LASTEXITCODE." }
  & flutter analyze
  if ($LASTEXITCODE -ne 0) { throw "C22G cycle $Cycle complete analysis rejected with exit $LASTEXITCODE." }
  & flutter test @mobileTests --reporter compact
  if ($LASTEXITCODE -ne 0) { throw "C22G cycle $Cycle complete required suite rejected with exit $LASTEXITCODE." }
} finally {
  Pop-Location
}

& $aggregateGate -RepositoryRoot $root
& (Join-Path $root 'scripts\check-personal-subaction-placement-regression.ps1') -RepositoryRoot $root -RequireImplemented
& (Join-Path $root 'scripts\check-personal-mool-global-navigation-contract.ps1') -RepositoryRoot $root -RequireImplemented
& (Join-Path $root 'scripts\check-personal-mool-global-navigation-motion-containment-c10e.ps1') -RepositoryRoot $root
& (Join-Path $root 'scripts\check-approved-ui-locks.ps1')
& (Join-Path $root 'scripts\check-brand-integrity.ps1') -Surface App
& (Join-Path $root 'scripts\check-user-facing-copy.ps1')
& (Join-Path $root 'scripts\check-interaction-contracts.ps1')
& (Join-Path $root 'scripts\check-mvp-personal-action-projection.ps1') -RepositoryRoot $root
& (Join-Path $root 'scripts\check-mvp-delivery-discipline-lock.ps1') -RepositoryRoot $root -RequireTicketSelectionAssessment
& (Join-Path $root 'scripts\check-mvp-scope-gate-state.ps1') -RepositoryRoot $root
& (Join-Path $root 'scripts\check-codex-development-regression-memory.ps1') -Phase implementation -BuildMode none -RepositoryRoot $root

$fingerprintAfter = Get-C22SourceFingerprint -Root $root
if ($fingerprintAfter -cne $fingerprintBefore) {
  throw "C22G cycle $Cycle source fingerprint changed: before=$fingerprintBefore after=$fingerprintAfter"
}

Write-Output "C22G host cycle passed: cycle=$Cycle; sourceFingerprint=$fingerprintAfter; format=clean; completeAnalysis=clean; requiredTestFiles=$($mobileTests.Count); requiredGates=12; installedR60.20Preserved=true; runtimeBuildInstall=closed."
