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
$ticketPath = Join-Path $root 'config\uaw-personal-mvp-global-subaction-optical-delta-host-qualification-fix4-c21g-ticket.json'
$scopePath = Join-Path $root 'config\mvp-scope-gate-state.json'
$deltaPath = Join-Path $root 'config\mvp-personal-subaction-optical-delta-c21.json'
$apkStatePath = Join-Path $root 'config\apk-regression-gate-state.json'
$aggregateGate = Join-Path $root 'scripts\check-personal-global-subaction-optical-delta-c21g.ps1'

foreach ($path in @($mobileRoot, $ticketPath, $scopePath, $deltaPath, $apkStatePath, $aggregateGate)) {
  if (-not (Test-Path -LiteralPath $path)) { throw "C21G host required owner is missing: $path" }
}

function Get-C21SourceFingerprint {
  param([Parameter(Mandatory = $true)][string]$Root)

  $relativeRoots = @('apps/mobile/lib', 'apps/mobile/test', 'scripts')
  $files = foreach ($relativeRoot in $relativeRoots) {
    $resolvedRoot = [IO.Path]::GetFullPath((Join-Path $Root $relativeRoot))
    if (-not $resolvedRoot.StartsWith($Root, [StringComparison]::OrdinalIgnoreCase) -or
        -not (Test-Path -LiteralPath $resolvedRoot -PathType Container)) {
      throw "C21G fingerprint root is missing or outside the repository: $relativeRoot"
    }
    Get-ChildItem -LiteralPath $resolvedRoot -Recurse -File
  }
  $records = foreach ($file in @($files | Sort-Object FullName)) {
    $relativePath = [IO.Path]::GetRelativePath($Root, $file.FullName).Replace('\', '/')
    "$((Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName).Hash)  $relativePath"
  }
  $bytes = [Text.Encoding]::UTF8.GetBytes(($records -join "`n"))
  $sha = [Security.Cryptography.SHA256]::Create()
  try {
    return [Convert]::ToHexString($sha.ComputeHash($bytes))
  } finally {
    $sha.Dispose()
  }
}

$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$delta = Get-Content -Raw -LiteralPath $deltaPath | ConvertFrom-Json
$apkState = Get-Content -Raw -LiteralPath $apkStatePath | ConvertFrom-Json
$expected = 'UAW-PERSONAL-MVP-GLOBAL-SUBACTION-OPTICAL-DELTA-HOST-QUALIFICATION-FIX4-C21G'
if ([int]$ticket.schemaVersion -ne 1 -or [string]$ticket.ticketId -cne $expected -or
    [string]$scope.ticket.id -cne $expected -or
    [string]$scope.preTicketSelectionCheckpoint.currentTicketId -cne $expected -or
    [string]$scope.state -cne 'ticket_disclosed_and_authorized') {
  throw 'C21G host ticket or active scope identity is invalid.'
}
$hostQualificationContract = $delta.hostQualification
if ([int]$hostQualificationContract.requiredConsecutiveCycles -ne 2 -or
    [string]$hostQualificationContract.sourceFingerprintAlgorithm -cne 'SHA256_OF_SORTED_PER_FILE_SHA256_AND_REPOSITORY_RELATIVE_PATH_USING_LF' -or
    (@($hostQualificationContract.sourceFingerprintScope) -join ',') -cne 'apps/mobile/lib,apps/mobile/test,scripts' -or
    -not [bool]$hostQualificationContract.unchangedSourceFingerprintRequired -or
    -not [bool]$hostQualificationContract.completeRequiredSuiteRequired -or
    @($delta.requiredTests).Count -ne 20 -or @($delta.requiredGates).Count -ne 12 -or
    [bool]$scope.execution.runtimeWriteAuthorized -or [bool]$scope.execution.buildAuthorized -or
    [bool]$scope.execution.deviceInstallAuthorized -or [bool]$scope.execution.backendWriteAuthorized -or
    [bool]$scope.execution.externalServiceWriteAuthorized -or [bool]$delta.runtimeMutationAuthorized -or
    [bool]$delta.buildAuthorized -or [bool]$delta.installAuthorized) {
  throw 'C21G host qualification or closed-authority contract has drifted.'
}
if ([string]$apkState.contractId -cne 'APK-BUILD-REGRESSION-GATES-001' -or
    [string]$apkState.machineState -cne 'r60_19_founder_rejected_installed_checksum_identity_preserved_successor_build_closed' -or
    [string]$apkState.buildAuthorization -cne 'consumed' -or
    [string]$apkState.installResult.installedBaseSha256 -cne 'D97E4F8B28EAA7DDBF9C74DF7FE4BBBC1204CD118B2DEC07F85C75559A91F0F0' -or
    [bool]$apkState.founderDeviceReview.successorBuildAuthorized -or
    [bool]$apkState.founderDeviceReview.successorInstallAuthorized) {
  throw 'C21G host qualification refuses changed r60.19 identity or open successor build/install authority.'
}

$fingerprintBefore = Get-C21SourceFingerprint -Root $root
$formatFiles = @(
  'lib/core/design/mool_design_system.dart',
  'lib/ui_v2/universal/mool_global_navigation_v2.dart',
  'lib/ui_v2/social/screen04_universal_components.dart',
  'lib/ui_v2/buy/buy_v2_screen.dart',
  'lib/features/eat/widgets/eat_widgets.dart',
  'lib/features/ride/widgets/ride_widgets.dart',
  'lib/features/book/widgets/book_widgets.dart',
  'lib/features/work/widgets/work_widgets.dart'
)
$mobileTests = foreach ($relative in @($delta.requiredTests)) {
  $prefix = 'apps/mobile/'
  if (-not ([string]$relative).StartsWith($prefix, [StringComparison]::Ordinal)) {
    throw "C21G required test path is outside apps/mobile: $relative"
  }
  ([string]$relative).Substring($prefix.Length)
}
$formatFiles += $mobileTests
foreach ($relative in $formatFiles) {
  if (-not (Test-Path -LiteralPath (Join-Path $mobileRoot $relative) -PathType Leaf)) {
    throw "C21G affected format file is missing: $relative"
  }
}

Push-Location $mobileRoot
try {
  & dart format --output=none --set-exit-if-changed @formatFiles
  if ($LASTEXITCODE -ne 0) { throw "C21G cycle $Cycle format check rejected with exit $LASTEXITCODE." }

  & flutter analyze
  if ($LASTEXITCODE -ne 0) { throw "C21G cycle $Cycle complete analysis rejected with exit $LASTEXITCODE." }

  & flutter test @mobileTests --reporter compact
  if ($LASTEXITCODE -ne 0) { throw "C21G cycle $Cycle complete required suite rejected with exit $LASTEXITCODE." }
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

$fingerprintAfter = Get-C21SourceFingerprint -Root $root
if ($fingerprintAfter -cne $fingerprintBefore) {
  throw "C21G cycle $Cycle source fingerprint changed during qualification: before=$fingerprintBefore after=$fingerprintAfter"
}

Write-Output "C21G host cycle passed: cycle=$Cycle; sourceFingerprint=$fingerprintAfter; format=clean; completeAnalysis=clean; requiredTestFiles=$($mobileTests.Count); requiredGates=12; opticalDelta=11Dimensions+lightMediaRawPixels; installedR60.19Preserved=true; runtimeBuildInstall=closed."
