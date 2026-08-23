[CmdletBinding()]
param(
  [string]$RepositoryRoot,
  [switch]$ProbeTokenOnlyDelta
)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)
$predecessorGate = Join-Path $root 'scripts\check-personal-subaction-disclosure-selection-motion-refinement-c21f.ps1'
$parentPath = Join-Path $root 'config\uaw-personal-mvp-global-subaction-optical-liquid-glass-recovery-fix4-c21-ticket.json'
$ticketPath = Join-Path $root 'config\uaw-personal-mvp-global-subaction-optical-delta-host-qualification-fix4-c21g-ticket.json'
$deltaPath = Join-Path $root 'config\mvp-personal-subaction-optical-delta-c21.json'
$successorPath = Join-Path $root 'config\mvp-personal-subaction-optical-liquid-glass-regression-c21.json'
$predecessorPath = Join-Path $root 'config\uaw-personal-mvp-shared-neutral-brand-glass-control-fix3-c20c-ticket.json'
$scopePath = Join-Path $root 'config\mvp-scope-gate-state.json'
$designPath = Join-Path $root 'apps\mobile\lib\core\design\mool_design_system.dart'
$pixelTestPath = Join-Path $root 'apps\mobile\test\core\design\mool_optical_delta_device_pixel_proxy_c21g_test.dart'
$matrixTestPath = Join-Path $root 'apps\mobile\test\core\design\mool_clear_glass_selected_state_matrix_c17e_test.dart'

foreach ($path in @($predecessorGate, $parentPath, $ticketPath, $deltaPath, $successorPath, $predecessorPath, $scopePath, $designPath, $pixelTestPath, $matrixTestPath)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "C21G required owner is missing: $path" }
}
& $predecessorGate -RepositoryRoot $root

$parent = Get-Content -Raw -LiteralPath $parentPath | ConvertFrom-Json
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$delta = Get-Content -Raw -LiteralPath $deltaPath | ConvertFrom-Json
$successor = Get-Content -Raw -LiteralPath $successorPath | ConvertFrom-Json
$predecessorTicket = Get-Content -Raw -LiteralPath $predecessorPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$expected = 'UAW-PERSONAL-MVP-GLOBAL-SUBACTION-OPTICAL-DELTA-HOST-QUALIFICATION-FIX4-C21G'
$sequence = @($parent.implementationSequence)
$expectedIndex = [Array]::IndexOf($sequence, $expected)
$current = [string]$scope.ticket.id
$currentIndex = [Array]::IndexOf($sequence, $current)
if ([int]$ticket.schemaVersion -ne 1 -or [string]$ticket.ticketId -cne $expected -or
    [string]$ticket.parentTicket -cne [string]$parent.ticketId -or [string]$ticket.classification -cne 'mvp_required' -or
    $expectedIndex -lt 0 -or $currentIndex -lt $expectedIndex -or
    [string]$scope.preTicketSelectionCheckpoint.currentTicketId -cne $current -or
    [string]$scope.state -cne 'ticket_disclosed_and_authorized') {
  throw 'C21G ticket identity, sequence or scope disclosure is invalid.'
}
if (-not [bool]$ticket.reuseInventory.complete -or -not [bool]$ticket.reuseInventory.duplicateSearchComplete -or
    @($ticket.reuseInventory.newScreens).Count -ne 0 -or @($ticket.reuseInventory.newRoutes).Count -ne 0 -or
    @($ticket.reuseInventory.newBackendOwners).Count -ne 0 -or @($ticket.reuseInventory.newSubactions).Count -ne 0 -or
    [bool]$scope.execution.runtimeWriteAuthorized -or [bool]$scope.execution.buildAuthorized -or
    [bool]$scope.execution.deviceInstallAuthorized -or [bool]$scope.execution.backendWriteAuthorized -or
    [bool]$scope.execution.externalServiceWriteAuthorized -or [bool]$delta.runtimeMutationAuthorized -or
    [bool]$delta.buildAuthorized -or [bool]$delta.installAuthorized -or
    [bool]$successor.buildAuthorized -or [bool]$successor.installAuthorized) {
  throw 'C21G reuse or runtime/build/install/device boundary has been weakened.'
}

$predecessor = $delta.predecessorContract
$next = $delta.successorContract
if ($ProbeTokenOnlyDelta) {
  $next.surfaceModel = $predecessor.surfaceModel
  $next.controlRadius = $predecessor.controlRadius
  $next.itemGap = $predecessor.itemGap
  $next.backdropBlurSigma = $predecessor.backdropBlurSigma
  $next.controlledGradientRequired = $false
  $next.specularInnerEdgeRequired = $false
  $next.perActionShadowRequired = $false
  $next.selectedElevationRequired = $false
  $next.selectedIndicatorWidth = $predecessor.selectedIndicatorWidth
  $next.pressedScale = $predecessor.pressedScale
  $next.providerGlyphSize = $predecessor.providerGlyphSize
}

$documented = $predecessorTicket.neutralBrandGlassContract
if ([string]$delta.contractId -cne 'UAW-PERSONAL-MVP-GLOBAL-SUBACTION-OPTICAL-DELTA-C21' -or
    [string]$delta.ticketId -cne $expected -or
    [string]$delta.founderRejectedPredecessor.versionName -cne '1.0.0-r60.19' -or
    [string]$delta.founderRejectedPredecessor.versionCode -cne '2026080819' -or
    [string]$delta.founderRejectedPredecessor.apkSha256 -cne 'D97E4F8B28EAA7DDBF9C74DF7FE4BBBC1204CD118B2DEC07F85C75559A91F0F0' -or
    [double]$documented.controlHeight -ne [double]$predecessor.controlHeight -or
    [double]$documented.controlRadius -ne [double]$predecessor.controlRadius -or
    [double]$documented.itemGap -ne [double]$predecessor.itemGap -or
    [double]$documented.selectedIndicatorWidth -ne [double]$predecessor.selectedIndicatorWidth -or
    [double]$documented.pressedScale -ne [double]$predecessor.pressedScale) {
  throw 'C21G predecessor identity or documented C20C baseline has drifted.'
}

$successorRules = $successor.visualRules
if ([double]$next.controlHeight -ne [double]$successorRules.controlHeight -or
    [double]$next.controlRadius -ne [double]$successorRules.controlRadius -or
    [double]$next.itemGap -ne [double]$successorRules.itemGap -or
    [double]$next.backdropBlurSigma -ne [double]$successorRules.backdropBlurSigma -or
    [bool]$next.controlledGradientRequired -ne [bool]$successorRules.controlledNeutralGradientRequired -or
    [bool]$next.specularInnerEdgeRequired -ne [bool]$successorRules.specularInnerEdgeRequired -or
    [bool]$next.perActionShadowRequired -ne [bool]$successorRules.perActionShadowRequired -or
    [bool]$next.selectedElevationRequired -ne [bool]$successorRules.selectedElevationRequired -or
    [double]$next.selectedIndicatorWidth -ne [double]$successorRules.selectedIndicatorWidth -or
    [double]$next.pressedScale -ne [double]$successorRules.pressedScale -or
    [double]$next.providerGlyphSize -ne [double]$successorRules.providerGlyphSize) {
  throw 'C21G successor optical contract does not match the implemented C21 contract.'
}

$observedDelta = [Collections.Generic.List[string]]::new()
if ([string]$predecessor.surfaceModel -cne [string]$next.surfaceModel) { $observedDelta.Add('surfaceModel') }
if ([double]$predecessor.controlRadius -ne [double]$next.controlRadius) { $observedDelta.Add('controlRadius') }
if ([double]$predecessor.itemGap -ne [double]$next.itemGap) { $observedDelta.Add('itemGap') }
if ([double]$predecessor.backdropBlurSigma -ne [double]$next.backdropBlurSigma) { $observedDelta.Add('backdropBlurSigma') }
if ([bool]$predecessor.controlledGradientRequired -ne [bool]$next.controlledGradientRequired) { $observedDelta.Add('controlledGradient') }
if ([bool]$predecessor.specularInnerEdgeRequired -ne [bool]$next.specularInnerEdgeRequired) { $observedDelta.Add('specularInnerEdge') }
if ([bool]$predecessor.perActionShadowRequired -ne [bool]$next.perActionShadowRequired) { $observedDelta.Add('perActionShadow') }
if ([bool]$predecessor.selectedElevationRequired -ne [bool]$next.selectedElevationRequired) { $observedDelta.Add('selectedElevation') }
if ([double]$predecessor.selectedIndicatorWidth -ne [double]$next.selectedIndicatorWidth) { $observedDelta.Add('selectedIndicatorWidth') }
if ([double]$predecessor.pressedScale -ne [double]$next.pressedScale) { $observedDelta.Add('pressedScale') }
if ([double]$predecessor.providerGlyphSize -ne [double]$next.providerGlyphSize) { $observedDelta.Add('providerGlyphSize') }
if ($observedDelta.Count -lt [int]$delta.requiredStructuralDelta.minimumChangedDimensions -or
    @($delta.requiredStructuralDelta.changedDimensions).Count -lt 10 -or
    -not [bool]$delta.requiredStructuralDelta.allChangedDimensionsMustBeMachineChecked -or
    [bool]$delta.requiredStructuralDelta.tokenOnlyDeltaIsSufficient -or
    -not [bool]$delta.requiredStructuralDelta.renderedPixelProxyRequired) {
  throw "C21G rejects token-only or structurally insufficient optical delta: observed=$($observedDelta.Count)."
}

$proxy = $delta.renderedPixelProxy
$matrix = $delta.familyStateMatrix
$hostQualificationContract = $delta.hostQualification
if ((@($proxy.tones) -join ',') -cne 'light,media' -or [double]$proxy.canvasSize.width -ne 320 -or
    [double]$proxy.canvasSize.height -ne 52 -or [int]$proxy.actionCount -ne 4 -or
    [double]$proxy.minimumChangedPixelRatio -lt .08 -or [double]$proxy.minimumMeanAbsoluteChannelDelta -lt 6 -or
    -not [bool]$proxy.predecessorProxyIsDocumentedContractNotProductionCopy -or
    -not [bool]$proxy.oppoPixelAcceptanceStillRequiredInC21H -or
    (@($matrix.families) -join ',') -cne 'social,buy,eat,ride,book,work' -or
    [int]$matrix.selectedStateCount -ne 17 -or -not [bool]$matrix.buyCompositingIsExplicitRejectionFixture -or
    [int]$hostQualificationContract.requiredConsecutiveCycles -ne 2 -or
    -not [bool]$hostQualificationContract.unchangedSourceFingerprintRequired -or
    -not [bool]$hostQualificationContract.completeRequiredSuiteRequired) {
  throw 'C21G pixel-proxy, family matrix or two-cycle host contract has drifted.'
}

$design = Get-Content -Raw -LiteralPath $designPath
$pixelTest = Get-Content -Raw -LiteralPath $pixelTestPath
$matrixTest = Get-Content -Raw -LiteralPath $matrixTestPath
$blockers = [Collections.Generic.List[string]]::new()
foreach ($token in @('glassGradient(', 'specularGradient(', 'controlShadows(', 'BackdropFilter(', 'selectedIndicatorWidth = 12', 'itemGap = MoolSpacing.xs', 'controlRadius = 15')) {
  if (-not $design.Contains($token)) { $blockers.Add("C21G implemented optical owner is missing: $token") }
}
foreach ($token in @('_DocumentedR6019FlatProxy', 'RepaintBoundary(', 'toImage(pixelRatio: 1)', 'ImageByteFormat.rawRgba', 'runAsync<Uint8List>', 'changedRatio, greaterThanOrEqualTo(.08)', 'meanAbsoluteChannelDelta, greaterThanOrEqualTo(6)', 'MoolLocalNavigationRail(')) {
  if (-not $pixelTest.Contains($token)) { $blockers.Add("C21G rendered-pixel proxy is missing: $token") }
}
foreach ($token in @('hasLength(17)', 'for (final state in selectedStates)', 'glassGradient(', 'greaterThanOrEqualTo(4.5)', 'MoolLocalNavigationSurfaceTone.media', 'MoolLocalNavigationSurfaceTone.light')) {
  if (-not $matrixTest.Contains($token)) { $blockers.Add("C21G seventeen-state matrix is missing: $token") }
}
$evolvedTests = @(
  'apps\mobile\test\core\design\mool_clear_glass_local_navigation_c17b_test.dart',
  'apps\mobile\test\core\design\mool_clear_glass_selected_state_matrix_c17e_test.dart',
  'apps\mobile\test\ui_v2\universal\uaw_personal_mvp_social_buy_clear_glass_conformance_c17c_test.dart',
  'apps\mobile\test\ui_v2\universal\uaw_personal_mvp_social_buy_four_action_conformance_c20d_test.dart',
  'apps\mobile\test\ui_v2\universal\uaw_personal_mvp_eat_ride_book_work_adaptive_conformance_c20e_test.dart'
)
foreach ($relative in $evolvedTests) {
  $source = Get-Content -Raw -LiteralPath (Join-Path $root $relative)
  foreach ($retired in @('MoolLocalNavigationTokens.glassFill', '.985', ' 212)', ' 272)')) {
    if ($source.Contains($retired)) { $blockers.Add("C21G evolved test retains predecessor expectation ${relative}: $retired") }
  }
}
if ($blockers.Count -gt 0) { throw ('C21G optical delta is not qualified: ' + ($blockers -join '; ') + '.') }

Write-Output "C21G optical delta passed: predecessor=r60.19/D97E4F8B...; structuralDimensions=$($observedDelta.Count); flatToGradient=true; specular=true; perActionShadow=true; selectedElevation=true; gap=4to8; radius=16to15; indicator=18to12; press=.985to.975; blur=16to20; providerGlyph=20to18; pixelProxy=light+media/8%/6MAD; selectedStates=17; BuyFixture=true; hostCycles=$($hostQualificationContract.completedConsecutiveCycles)/2; runtimeBuildInstall=closed."
