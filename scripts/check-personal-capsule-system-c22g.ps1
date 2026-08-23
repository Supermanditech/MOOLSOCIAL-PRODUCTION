[CmdletBinding()]
param(
  [string]$RepositoryRoot,
  [switch]$ProbeStructuralMutation
)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

$parentPath = Join-Path $root 'config\uaw-personal-mvp-global-capsule-subaction-recovery-fix5-c22-ticket.json'
$ticketPath = Join-Path $root 'config\uaw-personal-mvp-capsule-system-host-qualification-fix5-c22g-ticket.json'
$contractPath = Join-Path $root 'config\mvp-personal-capsule-system-regression-c22.json'
$scopePath = Join-Path $root 'config\mvp-scope-gate-state.json'
$apkPath = Join-Path $root 'config\apk-regression-gate-state.json'
$designPath = Join-Path $root 'apps\mobile\lib\core\design\mool_design_system.dart'
$navigationPath = Join-Path $root 'apps\mobile\lib\ui_v2\universal\mool_global_navigation_v2.dart'

foreach ($path in @($parentPath, $ticketPath, $contractPath, $scopePath, $apkPath, $designPath, $navigationPath)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "C22G required owner is missing: $path" }
}

$parent = Get-Content -Raw -LiteralPath $parentPath | ConvertFrom-Json
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$contract = Get-Content -Raw -LiteralPath $contractPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$apk = Get-Content -Raw -LiteralPath $apkPath | ConvertFrom-Json
$expected = 'UAW-PERSONAL-MVP-CAPSULE-SYSTEM-HOST-QUALIFICATION-FIX5-C22G'
$sequence = @($parent.implementationSequence)
$expectedIndex = [Array]::IndexOf($sequence, $expected)
$currentIndex = [Array]::IndexOf($sequence, [string]$scope.ticket.id)
if ([int]$ticket.schemaVersion -ne 1 -or [string]$ticket.ticketId -cne $expected -or
    [string]$ticket.parentTicket -cne [string]$parent.ticketId -or $expectedIndex -lt 0 -or
    $currentIndex -lt $expectedIndex -or [string]$scope.preTicketSelectionCheckpoint.currentTicketId -cne [string]$scope.ticket.id -or
    [string]$scope.state -cne 'ticket_disclosed_and_authorized') {
  throw 'C22G ticket identity, sequence or scope disclosure is invalid.'
}
if (-not [bool]$ticket.reuseInventory.complete -or -not [bool]$ticket.reuseInventory.duplicateSearchComplete -or
    @($ticket.reuseInventory.newScreens).Count -ne 0 -or @($ticket.reuseInventory.newRoutes).Count -ne 0 -or
    @($ticket.reuseInventory.newBackendOwners).Count -ne 0 -or @($ticket.reuseInventory.newSubactions).Count -ne 0 -or
    [bool]$scope.execution.runtimeWriteAuthorized -or [bool]$scope.execution.buildAuthorized -or
    [bool]$scope.execution.deviceInstallAuthorized -or [bool]$scope.execution.backendWriteAuthorized -or
    [bool]$scope.execution.externalServiceWriteAuthorized) {
  throw 'C22G closed runtime/build/install authority or reuse boundary has drifted.'
}

$rules = $contract.visualRules
if ([int]$contract.schemaVersion -ne 1 -or [string]$contract.contractId -cne 'UAW-PERSONAL-MVP-CAPSULE-SYSTEM-REGRESSION-C22' -or
    (@($rules.families) -join ',') -cne 'social,buy,eat,ride,book,work' -or [int]$rules.selectedStateCount -ne 17 -or
    (@($rules.supportedActionCounts) -join ',') -cne '2,3,4' -or [double]$rules.capsuleWidth -ne 72 -or
    [double]$rules.controlHeight -ne 48 -or [double]$rules.controlRadius -ne 24 -or [double]$rules.itemGap -ne 8 -or
    [double]$rules.clusterWidthsAt320.twoActions -ne 152 -or [double]$rules.clusterWidthsAt320.threeActions -ne 232 -or
    [double]$rules.clusterWidthsAt320.fourActions -ne 312 -or [double]$rules.iconSize -ne 18 -or
    [double]$rules.labelFontSize -ne 12 -or [int]$rules.labelFontWeight -ne 800 -or
    [string]$rules.neutralGlassTopArgb -cne 'B30D1326' -or [string]$rules.neutralGlassBottomArgb -cne 'AB050816' -or
    [double]$rules.minimumNeutralDestinationTransmission -ne 0.29 -or
    [double]$rules.minimumCompositeWhiteForegroundContrast -ne 4.5 -or
    [double]$rules.maximumSelectedEmissionAlpha -ne 0.28 -or
    [double]$rules.selectedEmissionCenterAlpha -ne 0.27 -or
    [double]$rules.selectedEmissionMiddleAlpha -ne 0.135 -or
    [double]$rules.pressedEmissionLayerOpacity -ne 0.62 -or
    -not [bool]$rules.neutralWhiteForegroundRequired -or [bool]$rules.familySurfaceToneAffectsBase -or
    [bool]$rules.fullWidthBandPanelTrapezoidOrSegmentedStripAllowed -or
    -not [bool]$rules.destinationPixelsVisibleOutsideAndBetweenCapsules -or [bool]$rules.localRailConsumesBottomLayoutHeight -or
    -not [bool]$rules.reverseUFirstToLastCapsuleCentersRequired -or -not [bool]$rules.reverseUSelectedMainStemRequired -or
    [bool]$rules.connectorOwnsHitTestingOrSemantics -or -not [bool]$rules.sixUniqueInternalEmissionAccentsRequired -or
    -not [bool]$rules.internalRadialEmissionRequired -or -not [bool]$rules.emissionClippedToCapsule -or
    [int]$rules.pressMotionMilliseconds -ne 100 -or [int]$rules.selectionMotionMilliseconds -ne 180 -or
    [int]$rules.disclosureMotionMilliseconds -ne 180 -or -not [bool]$rules.reducedMotionImmediate -or
    -not [bool]$rules.selectedSemanticsRequired -or -not [bool]$rules.selectedOpticalElevationRequired -or
    [double]$rules.minimumTapTarget -ne 44 -or [double]$rules.actualTapTarget.width -ne 72 -or
    [double]$rules.actualTapTarget.height -ne 48 -or -not [bool]$rules.globalRailOrderPositionMeaningPreserved -or
    -not [bool]$rules.moolChatEndpointGeometryPreserved -or [bool]$rules.fillerActionAllowed -or
    @($contract.requiredTests).Count -ne 15 -or [int]$contract.requiredGateCount -ne 12 -or
    [bool]$contract.runtimeMutationAuthorized -or [bool]$contract.buildAuthorized -or [bool]$contract.installAuthorized) {
  throw 'C22G machine-readable capsule contract has drifted.'
}

foreach ($relative in @($contract.requiredTests)) {
  $resolved = [IO.Path]::GetFullPath((Join-Path $root ([string]$relative)))
  if (-not $resolved.StartsWith($root, [StringComparison]::OrdinalIgnoreCase) -or
      -not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
    throw "C22G required test is missing or outside repository: $relative"
  }
}
if ([string]$apk.machineState -cne 'r60_20_founder_rejected_installed_checksum_identity_preserved_successor_build_closed' -or
    [string]$apk.buildAuthorization -cne 'consumed_no_second_build' -or
    [string]$apk.installResult.installedBaseSha256 -cne 'FF3932D84794BA8802946CBB04F8A346F34386F4A5C8321F3970AD8E6228EF8A' -or
    [bool]$apk.founderDeviceReview.successorBuildAuthorized -or [bool]$apk.founderDeviceReview.successorInstallAuthorized) {
  throw 'C22G refuses changed r60.20 identity or open successor build/install authority.'
}

$design = Get-Content -Raw -LiteralPath $designPath
$navigation = Get-Content -Raw -LiteralPath $navigationPath
if ($ProbeStructuralMutation) {
  $design = $design.Replace('static const double capsuleWidth = 72;', 'static const double capsuleWidth = 71;')
}
$blockers = [Collections.Generic.List[string]]::new()
foreach ($token in @(
  'static const double capsuleWidth = 72;',
  'static const double controlRadius = 24;',
  'static const double iconSize = 18;',
  'static const double labelFontSize = 12;',
  'static const Color neutralGlassTop = Color(0xB30D1326);',
  'static const Color neutralGlassBottom = Color(0xAB050816);',
  'static const double innerEmissionCenterAlpha = .27;',
  'static const double innerEmissionMiddleAlpha = .135;',
  'static const Duration pressDuration = Duration(milliseconds: 100);',
  'static const Duration selectionDuration = Duration(milliseconds: 180);',
  'static const Duration disclosureDuration = Duration(milliseconds: 180);',
  "'social' => const Color(0xFF7C5CFF)",
  "'buy' => const Color(0xFFFFB347)",
  "'eat' => const Color(0xFFFF6B7A)",
  "'ride' => const Color(0xFF41C7FF)",
  "'book' => const Color(0xFF3DDC97)",
  "'work' => const Color(0xFF6EA8FF)",
  'static RadialGradient innerEmissionGradient',
  'moolsocial-local-${action.id}',
  'mool-action-${action.id}',
  '_MoolInnerChromaEmission(',
  'selected: selected,',
  'pressed: _pressed,'
)) {
  if (-not $design.Contains($token)) { $blockers.Add("C22G capsule/emission owner is missing: $token") }
}
foreach ($token in @(
  'OverlayPortal(',
  'CompositedTransformFollower(',
  'moolDestinationFamilyBridgeHeight',
  'Path reverseUPath(Size size)',
  'Path mainStemPath(Size size)',
  'familyFirstAnchor(Size size)',
  'familyLastAnchor(Size size)',
  'IgnorePointer(',
  'ExcludeSemantics(',
  'duration: MoolLocalNavigationTokens.disclosureDuration'
)) {
  if (-not $navigation.Contains($token)) { $blockers.Add("C22G overlay/bridge owner is missing: $token") }
}
if ($blockers.Count -gt 0) {
  throw ('C22G capsule system does not match the frozen contract: ' + ($blockers -join '; ') + '.')
}

Write-Output 'C22G capsule-system gate passed: families=6; actions=17; capsule=72x48-r24; glass=B3/AB; compositeContrast=4.5; zeroStrap=true; reverseU=true; innerChroma=6; motion=100/180/180ms; reducedMotion=immediate; routes=preserved; r60.20=preserved; buildInstall=closed.'
