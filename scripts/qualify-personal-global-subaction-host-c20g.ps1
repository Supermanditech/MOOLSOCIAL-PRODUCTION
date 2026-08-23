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
$ticketPath = Join-Path $root 'config\uaw-personal-mvp-global-subaction-host-qualification-fix3-c20g-ticket.json'
$scopePath = Join-Path $root 'config\mvp-scope-gate-state.json'
$regressionPath = Join-Path $root 'config\mvp-personal-subaction-professional-recovery-regression-c20.json'
$aggregateGate = Join-Path $root 'scripts\check-personal-subaction-professional-regression-c20f.ps1'

foreach ($path in @($mobileRoot, $ticketPath, $scopePath, $regressionPath, $aggregateGate)) {
  if (-not (Test-Path -LiteralPath $path)) { throw "C20G required owner is missing: $path" }
}

function Get-C20SourceFingerprint {
  param([Parameter(Mandatory = $true)][string]$Root)

  $relativeRoots = @('apps/mobile/lib', 'apps/mobile/test', 'scripts')
  $files = foreach ($relativeRoot in $relativeRoots) {
    $resolvedRoot = [IO.Path]::GetFullPath((Join-Path $Root $relativeRoot))
    if (-not $resolvedRoot.StartsWith($Root, [StringComparison]::OrdinalIgnoreCase) -or
        -not (Test-Path -LiteralPath $resolvedRoot -PathType Container)) {
      throw "C20G fingerprint root is missing or outside the repository: $relativeRoot"
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
$regression = Get-Content -Raw -LiteralPath $regressionPath | ConvertFrom-Json
$expected = 'UAW-PERSONAL-MVP-GLOBAL-SUBACTION-HOST-QUALIFICATION-FIX3-C20G'
if ([int]$ticket.schemaVersion -ne 1 -or [string]$ticket.ticketId -cne $expected -or
    [string]$scope.ticket.id -cne $expected -or
    [string]$scope.preTicketSelectionCheckpoint.currentTicketId -cne $expected -or
    [string]$scope.state -cne 'ticket_disclosed_and_authorized') {
  throw 'C20G ticket or active scope identity is invalid.'
}
$contract = $ticket.hostQualificationContract
if ([int]$contract.requiredConsecutiveCycles -ne 2 -or
    [string]$contract.sourceFingerprintAlgorithm -cne 'SHA256_OF_SORTED_PER_FILE_SHA256_AND_REPOSITORY_RELATIVE_PATH_USING_LF' -or
    (@($contract.sourceFingerprintScope) -join ',') -cne 'apps/mobile/lib,apps/mobile/test,scripts' -or
    -not [bool]$contract.formatMustBeClean -or
    -not [bool]$contract.analysisMustBeClean -or
    -not [bool]$contract.completeRequiredTestsMustPass -or
    -not [bool]$contract.completeContinuityTestsMustPass -or
    -not [bool]$contract.allRequiredGatesMustPass -or
    [bool]$contract.sourceMutationBetweenCyclesAllowed -or
    [bool]$contract.runtimeMutationAuthorized -or
    [bool]$contract.buildAuthorized -or
    [bool]$contract.installAuthorized) {
  throw 'C20G host qualification contract has drifted.'
}
if ([bool]$scope.execution.runtimeWriteAuthorized -or
    [bool]$scope.execution.buildAuthorized -or
    [bool]$scope.execution.deviceInstallAuthorized -or
    [bool]$scope.execution.backendWriteAuthorized -or
    [bool]$scope.execution.externalServiceWriteAuthorized -or
    [bool]$regression.buildAuthorized -or [bool]$regression.installAuthorized) {
  throw 'C20G refuses runtime, build, install, backend, external or device authority.'
}

$fingerprintBefore = Get-C20SourceFingerprint -Root $root

$formatFiles = @(
  'lib/core/design/mool_design_system.dart',
  'lib/ui_v2/universal/mool_global_navigation_v2.dart',
  'test/core/design/mool_adaptive_local_navigation_c16a_test.dart',
  'test/core/design/mool_clear_glass_local_navigation_c17b_test.dart',
  'test/core/design/mool_clear_glass_selected_state_matrix_c17e_test.dart',
  'test/core/design/mool_neutral_brand_glass_local_navigation_c20c_test.dart',
  'test/core/design/mool_remaining_family_clear_glass_conformance_c17d_test.dart',
  'test/ui_v2/universal/uaw_personal_mvp_social_buy_clear_glass_conformance_c17c_test.dart',
  'test/ui_v2/universal/uaw_personal_mvp_subaction_disclosure_overflow_c20b_test.dart',
  'test/ui_v2/universal/uaw_personal_mvp_social_buy_four_action_conformance_c20d_test.dart',
  'test/ui_v2/universal/uaw_personal_mvp_eat_ride_book_work_adaptive_conformance_c20e_test.dart',
  'test/ui_v2/universal/uaw_personal_mvp_subaction_professional_regression_c20f_test.dart',
  'test/ui_v2/universal/uaw_personal_mvp_global_navigation_motion_containment_c10e_test.dart',
  'test/uaw_personal_mvp_eat_subaction_professional_conformance_c16d_test.dart',
  'test/uaw_personal_mvp_ride_subaction_professional_conformance_c16e_test.dart',
  'test/uaw_personal_mvp_book_subaction_professional_conformance_c16f_test.dart',
  'test/uaw_personal_mvp_work_subaction_professional_conformance_c16g_test.dart',
  'test/ui_v2/buy/buy_v2_navigation_motion_test.dart'
)
foreach ($relative in $formatFiles) {
  if (-not (Test-Path -LiteralPath (Join-Path $mobileRoot $relative) -PathType Leaf)) {
    throw "C20G affected format/analysis file is missing: $relative"
  }
}

$requiredTests = @(
  @($regression.requiredTests) +
  @($regression.requiredContinuityTests) +
  @('apps/mobile/test/ui_v2/universal/uaw_personal_mvp_subaction_professional_regression_c20f_test.dart') |
    Select-Object -Unique
)
$mobileTests = foreach ($relative in $requiredTests) {
  $prefix = 'apps/mobile/'
  if (-not ([string]$relative).StartsWith($prefix, [StringComparison]::Ordinal)) {
    throw "C20G test path is outside apps/mobile: $relative"
  }
  ([string]$relative).Substring($prefix.Length)
}

Push-Location $mobileRoot
try {
  & dart format --output=none --set-exit-if-changed @formatFiles
  if ($LASTEXITCODE -ne 0) { throw "C20G cycle $Cycle format check rejected with exit $LASTEXITCODE." }

  & flutter analyze @formatFiles
  if ($LASTEXITCODE -ne 0) { throw "C20G cycle $Cycle analysis rejected with exit $LASTEXITCODE." }

  & flutter test @mobileTests --reporter compact
  if ($LASTEXITCODE -ne 0) { throw "C20G cycle $Cycle complete required suite rejected with exit $LASTEXITCODE." }
} finally {
  Pop-Location
}

& $aggregateGate -RepositoryRoot $root
& (Join-Path $root 'scripts\check-personal-subaction-disclosure-overflow-c20b.ps1') -RepositoryRoot $root
& (Join-Path $root 'scripts\check-personal-shared-neutral-brand-glass-control-c20c.ps1') -RepositoryRoot $root
& (Join-Path $root 'scripts\check-personal-social-buy-four-action-conformance-c20d.ps1') -RepositoryRoot $root
& (Join-Path $root 'scripts\check-personal-eat-ride-book-work-adaptive-conformance-c20e.ps1') -RepositoryRoot $root
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

$fingerprintAfter = Get-C20SourceFingerprint -Root $root
if ($fingerprintAfter -cne $fingerprintBefore) {
  throw "C20G cycle $Cycle source fingerprint changed during qualification: before=$fingerprintBefore after=$fingerprintAfter"
}

Write-Output "C20G host cycle passed: cycle=$Cycle; sourceFingerprint=$fingerprintAfter; format=clean; analysis=clean; requiredAndContinuityTests=$($mobileTests.Count); requiredGates=15; runtimeBuildInstall=closed."
