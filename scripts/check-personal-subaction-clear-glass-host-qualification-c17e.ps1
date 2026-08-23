[CmdletBinding()]
param(
  [string]$RepositoryRoot,
  [switch]$RequireTwoHostCycles
)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

function Get-C17SourceFingerprint {
  param([Parameter(Mandatory = $true)][string]$Root)

  $relativeRoots = @('apps/mobile/lib', 'apps/mobile/test', 'scripts')
  $files = foreach ($relativeRoot in $relativeRoots) {
    $resolvedRoot = [IO.Path]::GetFullPath((Join-Path $Root $relativeRoot))
    if (-not $resolvedRoot.StartsWith($Root, [StringComparison]::OrdinalIgnoreCase) -or
        -not (Test-Path -LiteralPath $resolvedRoot -PathType Container)) {
      throw "C17E fingerprint root is missing or outside the repository: $relativeRoot"
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

$contractPath = Join-Path $root 'config\mvp-personal-subaction-clear-glass-regression-c17.json'
$ticketPath = Join-Path $root 'config\uaw-personal-mvp-global-subaction-clear-glass-action-controls-fix2-c17-ticket.json'
$c20ParentPath = Join-Path $root 'config\uaw-personal-mvp-global-subaction-founder-gallery-professional-recovery-fix3-c20-ticket.json'
$scopePath = Join-Path $root 'config\mvp-scope-gate-state.json'
$designPath = Join-Path $root 'apps\mobile\lib\core\design\mool_design_system.dart'
$navigationPath = Join-Path $root 'apps\mobile\lib\ui_v2\universal\mool_global_navigation_v2.dart'

foreach ($path in @($contractPath, $ticketPath, $scopePath, $designPath, $navigationPath)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "C17E required owner is missing: $path" }
}

$earlyScope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$earlyCurrent = [string]$earlyScope.ticket.id
if (Test-Path -LiteralPath $c20ParentPath -PathType Leaf) {
  $earlyParent = Get-Content -Raw -LiteralPath $c20ParentPath | ConvertFrom-Json
  $earlySequence = @($earlyParent.implementationSequence)
  $earlyStart = [Array]::IndexOf($earlySequence, 'UAW-PERSONAL-MVP-SHARED-NEUTRAL-BRAND-GLASS-CONTROL-FIX3-C20C')
  $earlyIndex = [Array]::IndexOf($earlySequence, $earlyCurrent)
  if ([string]$earlyParent.ticketId -ceq 'UAW-PERSONAL-MVP-GLOBAL-SUBACTION-FOUNDER-GALLERY-PROFESSIONAL-RECOVERY-FIX3-C20' -and
      $earlyStart -ge 0 -and $earlyIndex -ge $earlyStart) {
    $c20cGate = Join-Path $root 'scripts\check-personal-shared-neutral-brand-glass-control-c20c.ps1'
    if (-not (Test-Path -LiteralPath $c20cGate -PathType Leaf)) { throw 'C17E C20C successor gate is missing.' }
    & $c20cGate -RepositoryRoot $root
    Write-Output 'C17E historical host-qualification contract passed through the exact C20C neutral brand-glass successor; host cycles remain owned by the C20 sequence; buildInstall=closed.'
    return
  }
}

$contract = Get-Content -Raw -LiteralPath $contractPath | ConvertFrom-Json
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
if ([int]$contract.schemaVersion -ne 1 -or
    [string]$contract.contractId -cne 'UAW-PERSONAL-MVP-CLEAR-GLASS-SUBACTION-REGRESSION-C17' -or
    [string]$contract.ticketId -cne 'UAW-PERSONAL-MVP-SUBACTION-LEGIBILITY-CONTRAST-OCCLUSION-MOTION-GATES-FIX2-C17E' -or
    [string]$contract.founderDirection -cne 'CLEAR-GLASS-COMPACT-INDIVIDUAL-ACTION-CONTROLS' -or
    [string]$contract.sharedOwner -cne 'MoolLocalNavigationRail') {
  throw 'C17E regression contract identity is invalid.'
}
$expected = [string]$contract.ticketId
$sequence = @($ticket.implementationSequence)
$current = [string]$scope.ticket.id
$c18dRefreshTicket = 'UAW-PERSONAL-MVP-C17-HOST-QUALIFICATION-REFRESH-AFTER-SCREEN01-LOCK-FIX1-C18D'
$isC18dRefresh = $current -ceq $c18dRefreshTicket
$isSequentialC17Ticket = (
  [Array]::IndexOf($sequence, $current) -ge
  [Array]::IndexOf($sequence, $expected)
)
if ((-not $isSequentialC17Ticket -and -not $isC18dRefresh) -or
    [string]$scope.preTicketSelectionCheckpoint.currentTicketId -cne $current -or
    [string]$scope.state -cne 'ticket_disclosed_and_authorized') {
  throw 'C17E sequential MVP scope gate is not active.'
}
if ([bool]$scope.execution.buildAuthorized -or [bool]$scope.execution.deviceInstallAuthorized -or
    [bool]$scope.execution.backendWriteAuthorized -or
    ([bool]$scope.execution.referenceWriteAuthorized -and -not $isC18dRefresh) -or
    [bool]$scope.execution.externalServiceWriteAuthorized -or
    [bool]$scope.execution.runtimeWriteAuthorized) {
  throw 'C17E host qualification refuses runtime, build, install, backend or external authority; reference writes are limited to the exact C18D refresh ticket.'
}

$inventoryCount = 0
foreach ($family in @('social', 'buy', 'eat', 'ride', 'book', 'work')) {
  $actions = @($contract.familyInventory.$family)
  if ($actions.Count -lt 2 -or [string]::IsNullOrWhiteSpace([string]$contract.surfaceToneByFamily.$family)) {
    throw "C17E family inventory is incomplete: $family"
  }
  $inventoryCount += $actions.Count
}
if ($inventoryCount -ne 17 -or [int]$contract.selectedStateCount -ne 17 -or
    (@($contract.adaptiveRules.supportedActionCounts) -join ',') -cne '2,3,4') {
  throw 'C17E selected-state or adaptive-count inventory is invalid.'
}
if ([string]$contract.hostQualification.sourceFingerprintAlgorithm -cne 'SHA256_OF_SORTED_PER_FILE_SHA256_AND_REPOSITORY_RELATIVE_PATH_USING_LF' -or
    (@($contract.hostQualification.sourceFingerprintScope) -join ',') -cne 'apps/mobile/lib,apps/mobile/test,scripts') {
  throw 'C17E source-fingerprint algorithm or scope has drifted.'
}
$currentSourceFingerprint = Get-C17SourceFingerprint -Root $root

$visual = $contract.visualRules
$adaptive = $contract.adaptiveRules
$interaction = $contract.interactionRules
if ([double]$visual.railSurfaceOpacity -ne 0 -or
    [double]$visual.lightGlassAlpha -ne .52 -or
    [double]$visual.mediaGlassAlpha -ne .58 -or
    [bool]$visual.selectedTintMayIncreaseAlpha -or
    [double]$visual.backdropBlurSigma -ne 16 -or
    [double]$visual.railHeight -ne 52 -or
    [double]$visual.controlHeight -ne 48 -or
    [double]$visual.minimumTapTarget -ne 48 -or
    [double]$visual.cornerRadius -ne 14 -or
    [double]$visual.iconSize -ne 20 -or
    [double]$visual.labelFontSize -ne 12 -or
    [int]$visual.minimumLabelFontWeight -ne 700 -or
    [double]$visual.maximumNavigationTextScale -ne 1.3 -or
    [double]$visual.minimumForegroundContrastRatio -ne 4.5 -or
    [double]$visual.selectedIndicatorWidth -ne 18 -or
    [double]$visual.selectedIndicatorHeight -ne 2 -or
    [double]$visual.connectionMaximumStrokeWidth -ne 1.5 -or
    [double]$visual.connectionMaximumOpacity -ne .35 -or
    -not [bool]$visual.individualControlBorderRequired -or
    [bool]$visual.filledFamilyBandOrTrapezoidAllowed -or
    [bool]$visual.horizontalScrollOrPanelAllowed -or
    [bool]$visual.distributedSparseCellsAllowed -or
    [bool]$visual.fillerActionsAllowed) {
  throw 'C17E professional visual rules have drifted.'
}
if ([double]$adaptive.preferredClusterWidthsAt412.twoActions -ne 212 -or
    [double]$adaptive.preferredClusterWidthsAt412.threeActions -ne 272 -or
    [double]$adaptive.preferredClusterWidthsAt412.fourActions -ne 316 -or
    [double]$adaptive.compactClusterWidthsAt320.twoActions -ne 212 -or
    [double]$adaptive.compactClusterWidthsAt320.threeActions -ne 272 -or
    [double]$adaptive.compactClusterWidthsAt320.fourActions -ne 312) {
  throw 'C17E compact adaptive widths have drifted.'
}
if ([int]$interaction.routineTapBudget -ne 1 -or
    -not [bool]$interaction.selectedActionIsInert -or
    -not [bool]$interaction.availableActionSemanticTapRequired -or
    [double]$interaction.pressedScale -ne .985 -or
    [int]$interaction.controlMotionMilliseconds -ne 160 -or
    [int]$interaction.connectionMotionMilliseconds -ne 200 -or
    [bool]$interaction.perpetualMotionAllowed -or
    -not [bool]$interaction.reducedMotionImmediate -or
    -not [bool]$interaction.BackMoolChatContinuityRequired -or
    -not [bool]$interaction.contentReachabilityRequired) {
  throw 'C17E interaction, continuity or motion rules have drifted.'
}

foreach ($relative in @($contract.requiredGates) + @($contract.requiredTests) + @($contract.founderAuthority)) {
  $resolved = [IO.Path]::GetFullPath((Join-Path $root ([string]$relative)))
  if (-not $resolved.StartsWith($root, [StringComparison]::OrdinalIgnoreCase) -or
      -not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
    throw "C17E required gate, test or authority is missing: $relative"
  }
}

$design = Get-Content -Raw -LiteralPath $designPath
$navigation = Get-Content -Raw -LiteralPath $navigationPath
foreach ($token in @(
  'static const double railHeight = 52',
  'static const double controlHeight = MoolMetrics.compactTapTarget',
  'static const double backdropBlurSigma = 16',
  'static const double iconSize = 20',
  'static const double labelFontSize = 12',
  'static const double maximumTextScale = 1.3',
  'static const Color lightGlassFill = Color(0x85FFFFFF)',
  'static const Color mediaGlassFill = Color(0x94081225)',
  'accent.withValues(alpha: base.a)',
  'foregroundDecoration: BoxDecoration(',
  'scale: _pressed ? .985 : 1'
)) {
  if (-not $design.Contains($token)) { throw "C17E shared source token is missing: $token" }
}
foreach ($token in @(
  'moolDestinationFamilyRailSurfaceOpacity = 0',
  'moolDestinationFamilyWaveDuration = Duration(milliseconds: 200)',
  'MoolLocalNavigationTokens.connectionLineStrokeWidth',
  'MoolLocalNavigationTokens.connectionLineMaximumOpacity',
  'IgnorePointer(',
  'ExcludeSemantics('
)) {
  if (-not $navigation.Contains($token)) { throw "C17E shell source token is missing: $token" }
}
if ($navigation.Contains('strokeWidth = 10')) { throw 'C17E shell retains the rejected broad connection stroke.' }

& (Join-Path $root 'scripts\check-personal-eat-ride-book-work-clear-glass-conformance-c17d.ps1') -RepositoryRoot $root
& (Join-Path $root 'scripts\check-personal-subaction-placement-regression.ps1') -RepositoryRoot $root -RequireImplemented
& (Join-Path $root 'scripts\check-codex-development-regression-memory.ps1') -RepositoryRoot $root -Phase implementation -BuildMode none

if ($RequireTwoHostCycles) {
  if ([string]$contract.state -cne 'c17e_host_qualified_two_consecutive_cycles' -or
      [string]$contract.hostQualification.status -cne 'passed' -or
      [int]$contract.hostQualification.completedConsecutiveCycles -ne 2 -or
      [string]$contract.hostQualification.sourceFingerprint -notmatch '^[A-F0-9]{64}$' -or
      [string]$contract.hostQualification.sourceFingerprint -cne $currentSourceFingerprint -or
      [string]::IsNullOrWhiteSpace([string]$contract.hostQualification.evidence)) {
    throw 'C17E two-cycle unchanged-source host qualification is not complete.'
  }
}

Write-Output "C17E clear-glass host contract passed: selectedStates=17; contrast=4.5; alpha=.52,.58; target=48px; counts=2,3,4; motion=160,200ms; reducedMotion=immediate; completedCycles=$($contract.hostQualification.completedConsecutiveCycles); sourceFingerprint=$currentSourceFingerprint; requireTwoCycles=$RequireTwoHostCycles; buildInstall=closed."
