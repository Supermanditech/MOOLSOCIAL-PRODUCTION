[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

$parentPath = Join-Path $root 'config\uaw-personal-mvp-global-subaction-optical-liquid-glass-recovery-fix4-c21-ticket.json'
$ticketPath = Join-Path $root 'config\uaw-personal-mvp-shared-optical-liquid-glass-control-fix4-c21b-ticket.json'
$contractPath = Join-Path $root 'config\mvp-personal-subaction-optical-liquid-glass-regression-c21.json'
$scopePath = Join-Path $root 'config\mvp-scope-gate-state.json'
$designPath = Join-Path $root 'apps\mobile\lib\core\design\mool_design_system.dart'
$testPath = Join-Path $root 'apps\mobile\test\core\design\mool_neutral_brand_glass_local_navigation_c20c_test.dart'

foreach ($path in @($parentPath, $ticketPath, $contractPath, $scopePath, $designPath, $testPath)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "C21B required owner is missing: $path"
  }
}

$parent = Get-Content -Raw -LiteralPath $parentPath | ConvertFrom-Json
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$contract = Get-Content -Raw -LiteralPath $contractPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$expected = 'UAW-PERSONAL-MVP-SHARED-OPTICAL-LIQUID-GLASS-CONTROL-FIX4-C21B'

if ([int]$ticket.schemaVersion -ne 1 -or
    [string]$ticket.ticketId -cne $expected -or
    [string]$ticket.parentTicket -cne [string]$parent.ticketId -or
    [string]$ticket.classification -cne 'mvp_required') {
  throw 'C21B ticket identity or MVP classification is invalid.'
}
if (-not [bool]$ticket.reuseInventory.complete -or
    -not [bool]$ticket.reuseInventory.duplicateSearchComplete -or
    @($ticket.reuseInventory.newScreens).Count -ne 0 -or
    @($ticket.reuseInventory.newRoutes).Count -ne 0 -or
    @($ticket.reuseInventory.newBackendOwners).Count -ne 0 -or
    @($ticket.reuseInventory.newSubactions).Count -ne 0) {
  throw 'C21B reuse, duplicate-search or zero-new-owner contract is incomplete.'
}
if (-not [bool]$ticket.execution.referenceWriteAuthorized -or
    -not [bool]$ticket.execution.runtimeSourceWriteAuthorized -or
    -not [bool]$ticket.execution.testOrGateWriteAuthorized -or
    [bool]$ticket.execution.backendWriteAuthorized -or
    [bool]$ticket.execution.buildAuthorized -or
    [bool]$ticket.execution.installAuthorized -or
    [bool]$ticket.execution.externalServiceWriteAuthorized) {
  throw 'C21B execution authority has been weakened or expanded.'
}

$sequence = @($parent.implementationSequence)
$expectedIndex = [Array]::IndexOf($sequence, $expected)
$current = [string]$scope.ticket.id
$currentIndex = [Array]::IndexOf($sequence, $current)
if ([string]$parent.ticketId -cne 'UAW-PERSONAL-MVP-GLOBAL-SUBACTION-OPTICAL-LIQUID-GLASS-RECOVERY-FIX4-C21' -or
    $expectedIndex -lt 0 -or $currentIndex -lt $expectedIndex -or
    [string]$scope.preTicketSelectionCheckpoint.currentTicketId -cne $current -or
    [string]$scope.state -cne 'ticket_disclosed_and_authorized') {
  throw 'C21B sequential MVP selection and disclosure gate is not active.'
}
if ([bool]$scope.execution.buildAuthorized -or
    [bool]$scope.execution.deviceInstallAuthorized -or
    [bool]$scope.execution.backendWriteAuthorized -or
    [bool]$scope.execution.externalServiceWriteAuthorized) {
  throw 'C21B refuses build, install, backend and external authority.'
}

$rules = $contract.visualRules
if ([int]$contract.schemaVersion -ne 1 -or
    [string]$contract.contractId -cne 'UAW-PERSONAL-MVP-SUBACTION-OPTICAL-LIQUID-GLASS-REGRESSION-C21' -or
    (@($rules.families) -join ',') -cne 'social,buy,eat,ride,book,work' -or
    [int]$rules.selectedStateCount -ne 17 -or
    (@($rules.supportedActionCounts) -join ',') -cne '2,3,4' -or
    [double]$rules.railHeight -ne 52 -or [double]$rules.railSurfaceOpacity -ne 0 -or
    [double]$rules.controlHeight -ne 48 -or [double]$rules.controlRadius -ne 15 -or
    [double]$rules.itemGap -ne 8 -or
    [double]$rules.clusterWidthsAt320.twoActions -ne 200 -or
    [double]$rules.clusterWidthsAt320.threeActions -ne 268 -or
    [double]$rules.clusterWidthsAt320.fourActions -ne 304 -or
    [double]$rules.backdropBlurSigma -ne 20 -or
    [string]$rules.lightGlassTopArgb -cne 'D6FFFFFF' -or
    [string]$rules.lightGlassBottomArgb -cne 'B8FFFFFF' -or
    [string]$rules.mediaGlassTopArgb -cne 'C4141C2D' -or
    [string]$rules.mediaGlassBottomArgb -cne 'B00A1120' -or
    -not [bool]$rules.controlledNeutralGradientRequired -or
    -not [bool]$rules.specularInnerEdgeRequired -or
    -not [bool]$rules.perActionShadowRequired -or
    -not [bool]$rules.selectedElevationRequired -or
    [bool]$rules.heavySelectedOutlineAllowed -or
    [double]$rules.selectedIndicatorWidth -ne 12 -or
    [double]$rules.selectedIndicatorHeight -ne 2 -or
    [double]$rules.iconOpticalBox -ne 20 -or
    [double]$rules.providerIconOpticalBox -ne 20 -or
    [double]$rules.providerGlyphSize -ne 18 -or
    [double]$rules.labelFontSize -ne 13 -or [int]$rules.labelFontWeight -ne 700 -or
    [double]$rules.maximumNavigationTextScale -ne 1.3 -or
    [double]$rules.pressedScale -ne .975 -or
    [int]$rules.pressMotionMilliseconds -ne 100 -or
    [int]$rules.stateMotionMilliseconds -ne 160 -or
    -not [bool]$rules.reducedMotionImmediate -or
    -not [bool]$rules.backgroundVisibleBetweenAndBehindControls -or
    [bool]$rules.fullWidthBandPanelTrapezoidOrSegmentedStripAllowed -or
    [bool]$rules.horizontalScrollAllowed -or
    [bool]$rules.distributedSparseCellsAllowed -or
    [bool]$rules.fillerActionAllowed -or
    [bool]$contract.buildAuthorized -or [bool]$contract.installAuthorized) {
  throw 'C21B optical liquid-glass regression contract has drifted.'
}

$design = Get-Content -Raw -LiteralPath $designPath
$test = Get-Content -Raw -LiteralPath $testPath
$blockers = [Collections.Generic.List[string]]::new()
foreach ($token in @(
  'static const double itemGap = MoolSpacing.xs',
  'static const double controlRadius = 15',
  'static const double backdropBlurSigma = 20',
  'static const double selectedIndicatorWidth = 12',
  'static const Duration pressDuration = Duration(milliseconds: 100)',
  'static const Color lightGlassTop = Color(0xD6FFFFFF)',
  'static const Color lightGlassBottom = Color(0xB8FFFFFF)',
  'static const Color mediaGlassTop = Color(0xC4141C2D)',
  'static const Color mediaGlassBottom = Color(0xB00A1120)',
  'static const double providerGlyphSize = 18',
  'static LinearGradient glassGradient({',
  'static LinearGradient specularGradient(',
  'static List<BoxShadow> controlShadows({',
  'scale: _pressed ? .975 : 1',
  'specular-edge',
  'gradient: MoolLocalNavigationTokens.glassGradient(',
  'boxShadow: MoolLocalNavigationTokens.controlShadows(',
  'width: 1'
)) {
  if (-not $design.Contains($token)) { $blockers.Add("shared optical owner is missing: $token") }
}

$railStart = $design.IndexOf('class MoolLocalNavigationRail extends StatelessWidget')
$railEnd = $design.IndexOf('class MoolOutcomeDock extends StatelessWidget', $railStart)
if ($railStart -lt 0 -or $railEnd -le $railStart) {
  $blockers.Add('shared local-navigation owner bounds are invalid')
} else {
  $localOwner = $design.Substring($railStart, $railEnd - $railStart)
  foreach ($forbidden in @('SingleChildScrollView(', 'Expanded(', 'ListView(', 'familyAccent(', 'controlAccent(')) {
    if ($localOwner.Contains($forbidden)) { $blockers.Add("shared owner retains a rejected strip, expansion or family accent: $forbidden") }
  }
  if ([regex]::Matches($localOwner, 'child:\s*BackdropFilter\(').Count -ne 1) {
    $blockers.Add('shared owner must declare exactly one reusable per-action BackdropFilter')
  }
}

foreach ($token in @(
  'tokens use one optical liquid-glass Mool identity grammar',
  'for (final actionCount in const [2, 3, 4])',
  '$actionCount actions stay centered, individual and 48px',
  'light and media lenses use gradients specular edges and readable contrast',
  'selected stays inert and neutral press is finite',
  'provider glyph is normalized inside the same 20px optical box',
  'reduced motion settles every shared state immediately',
  'MoolLocalNavigationTokens.itemGap, 8',
  'MoolLocalNavigationTokens.controlRadius, 15',
  'MoolLocalNavigationTokens.backdropBlurSigma, 20',
  'greaterThanOrEqualTo(4.5)',
  'find.byType(BackdropFilter)',
  'specular-edge'
)) {
  if (-not $test.Contains($token)) { $blockers.Add("C21B focused coverage is missing: $token") }
}

if ($blockers.Count -gt 0) {
  throw ('C21B shared optical liquid-glass control is not qualified: ' + ($blockers -join '; ') + '.')
}

Write-Output 'C21B shared optical liquid-glass control passed: families=6; states=17; counts=2,3,4; rail=52px/transparent; controls=48x15px/independent; gap=8px; blur=20px; neutralGradients=true; specular=true; selectedElevation=true; heavySelectedOutline=false; icon=20px; label=13px/700; press=100ms; state=160ms; reducedMotion=immediate; buildInstall=closed.'
