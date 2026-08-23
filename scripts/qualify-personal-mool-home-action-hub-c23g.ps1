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
$contractPath = Join-Path $root 'config\mvp-personal-mool-home-action-hub-regression-c23.json'
$ticketPath = Join-Path $root 'config\uaw-personal-mvp-home-hub-host-qualification-fix6-c23g-ticket.json'
$scopePath = Join-Path $root 'config\mvp-scope-gate-state.json'
$apkPath = Join-Path $root 'config\apk-regression-gate-state.json'
$aggregateGate = Join-Path $root 'scripts\check-personal-mool-home-action-hub-c23g.ps1'
foreach ($path in @($mobileRoot, $contractPath, $ticketPath, $scopePath, $apkPath, $aggregateGate)) {
  if (-not (Test-Path -LiteralPath $path)) { throw "C23G host required owner is missing: $path" }
}

function Get-C23SourceFingerprint {
  param([Parameter(Mandatory = $true)][string]$Root)
  $files = foreach ($relativeRoot in @('apps/mobile/lib', 'apps/mobile/test', 'scripts')) {
    $resolvedRoot = [IO.Path]::GetFullPath((Join-Path $Root $relativeRoot))
    if (-not $resolvedRoot.StartsWith($Root, [StringComparison]::OrdinalIgnoreCase) -or
        -not (Test-Path -LiteralPath $resolvedRoot -PathType Container)) {
      throw "C23G fingerprint root is missing or outside repository: $relativeRoot"
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

$contract = Get-Content -Raw -LiteralPath $contractPath | ConvertFrom-Json
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$apk = Get-Content -Raw -LiteralPath $apkPath | ConvertFrom-Json
$expected = 'UAW-PERSONAL-MVP-HOME-HUB-HOST-QUALIFICATION-FIX6-C23G'
if ([string]$ticket.ticketId -cne $expected -or [string]$scope.ticket.id -cne $expected -or
    [string]$scope.preTicketSelectionCheckpoint.currentTicketId -cne $expected -or
    [bool]$scope.execution.runtimeWriteAuthorized -or [bool]$scope.execution.buildAuthorized -or
    [bool]$scope.execution.deviceInstallAuthorized) {
  throw 'C23G host ticket identity or closed authority is invalid.'
}
$hostContract = $contract.hostQualification
if ([int]$hostContract.requiredConsecutiveCycles -ne 2 -or
    [string]$hostContract.sourceFingerprintAlgorithm -cne 'SHA256_OF_SORTED_PER_FILE_SHA256_AND_REPOSITORY_RELATIVE_PATH_USING_LF' -or
    (@($hostContract.sourceFingerprintScope) -join ',') -cne 'apps/mobile/lib,apps/mobile/test,scripts' -or
    -not [bool]$hostContract.unchangedSourceFingerprintRequired -or
    -not [bool]$hostContract.completeAnalysisRequired -or
    -not [bool]$hostContract.completeRequiredSuiteRequired -or
    @($contract.requiredTests).Count -ne 13 -or [int]$contract.requiredGateCount -ne 10) {
  throw 'C23G host qualification contract has drifted.'
}
if ([string]$apk.machineState -cne 'r60_21_founder_rejected_installed_checksum_identity_preserved_successor_build_install_closed' -or
    [string]$apk.installResult.installedBaseSha256 -cne '17AF5DC2353E7195A597555C88AA42B345AFFDA0EC160900B55B0D3E822691BE' -or
    [bool]$apk.founderDeviceReview.successorBuildAuthorized -or
    [bool]$apk.founderDeviceReview.successorInstallAuthorized) {
  throw 'C23G host qualification refuses changed r60.21 identity or open successor authority.'
}

$fingerprintBefore = Get-C23SourceFingerprint -Root $root
$mobileTests = foreach ($relative in @($contract.requiredTests)) {
  $prefix = 'apps/mobile/'
  if (-not ([string]$relative).StartsWith($prefix, [StringComparison]::Ordinal)) {
    throw "C23G required test is outside apps/mobile: $relative"
  }
  ([string]$relative).Substring($prefix.Length)
}
$formatFiles = @(
  'lib/core/design/mool_design_system.dart',
  'lib/ui_v2/universal/mool_global_navigation_v2.dart',
  'lib/ui_v2/universal/personal_mool_root_v2.dart',
  'lib/features/journey01/journey_router.dart'
) + $mobileTests
foreach ($relative in $formatFiles) {
  if (-not (Test-Path -LiteralPath (Join-Path $mobileRoot $relative) -PathType Leaf)) {
    throw "C23G affected format file is missing: $relative"
  }
}

Push-Location $mobileRoot
try {
  & dart format --output=none --set-exit-if-changed @formatFiles
  if ($LASTEXITCODE -ne 0) { throw "C23G cycle $Cycle format check rejected with exit $LASTEXITCODE." }
  & flutter analyze
  if ($LASTEXITCODE -ne 0) { throw "C23G cycle $Cycle complete analysis rejected with exit $LASTEXITCODE." }
  & flutter test @mobileTests --reporter compact
  if ($LASTEXITCODE -ne 0) { throw "C23G cycle $Cycle complete required suite rejected with exit $LASTEXITCODE." }
} finally {
  Pop-Location
}

& $aggregateGate -RepositoryRoot $root
& (Join-Path $root 'scripts\check-personal-subaction-placement-regression.ps1') -RepositoryRoot $root -RequireImplemented
& (Join-Path $root 'scripts\check-approved-ui-locks.ps1')
& (Join-Path $root 'scripts\check-brand-integrity.ps1') -Surface App
& (Join-Path $root 'scripts\check-user-facing-copy.ps1')
& (Join-Path $root 'scripts\check-interaction-contracts.ps1')
& (Join-Path $root 'scripts\check-mvp-personal-action-projection.ps1') -RepositoryRoot $root
& (Join-Path $root 'scripts\check-mvp-delivery-discipline-lock.ps1') -RepositoryRoot $root -RequireTicketSelectionAssessment
& (Join-Path $root 'scripts\check-mvp-scope-gate-state.ps1') -RepositoryRoot $root
& (Join-Path $root 'scripts\check-codex-development-regression-memory.ps1') -Phase implementation -BuildMode none -RepositoryRoot $root

$fingerprintAfter = Get-C23SourceFingerprint -Root $root
if ($fingerprintAfter -cne $fingerprintBefore) {
  throw "C23G cycle $Cycle source fingerprint changed: before=$fingerprintBefore after=$fingerprintAfter"
}

Write-Output "C23G host cycle passed: cycle=$Cycle; sourceFingerprint=$fingerprintAfter; format=clean; completeAnalysis=clean; requiredTestFiles=$($mobileTests.Count); requiredGates=10; installedR60.21Preserved=true; runtimeBuildInstall=closed."
