[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

$predecessorGate = Join-Path $root 'scripts\check-personal-subaction-disclosure-overflow-c20b.ps1'
$parentPath = Join-Path $root 'config\uaw-personal-mvp-global-subaction-founder-gallery-professional-recovery-fix3-c20-ticket.json'
$ticketPath = Join-Path $root 'config\uaw-personal-mvp-shared-neutral-brand-glass-control-fix3-c20c-ticket.json'
$regressionPath = Join-Path $root 'config\mvp-personal-subaction-professional-recovery-regression-c20.json'
$scopePath = Join-Path $root 'config\mvp-scope-gate-state.json'
$designPath = Join-Path $root 'apps\mobile\lib\core\design\mool_design_system.dart'
$navigationPath = Join-Path $root 'apps\mobile\lib\ui_v2\universal\mool_global_navigation_v2.dart'
$testPath = Join-Path $root 'apps\mobile\test\core\design\mool_neutral_brand_glass_local_navigation_c20c_test.dart'

foreach ($path in @($predecessorGate, $parentPath, $ticketPath, $regressionPath, $scopePath, $designPath, $navigationPath, $testPath)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "C20C required owner is missing: $path"
  }
}

& $predecessorGate -RepositoryRoot $root

$parent = Get-Content -Raw -LiteralPath $parentPath | ConvertFrom-Json
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$regression = Get-Content -Raw -LiteralPath $regressionPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$expected = 'UAW-PERSONAL-MVP-SHARED-NEUTRAL-BRAND-GLASS-CONTROL-FIX3-C20C'

if ([int]$ticket.schemaVersion -ne 1 -or
    [string]$ticket.ticketId -cne $expected -or
    [string]$ticket.parentTicket -cne [string]$parent.ticketId -or
    [string]$ticket.classification -cne 'mvp_required') {
  throw 'C20C ticket identity or MVP classification is invalid.'
}
if (-not [bool]$ticket.reuseInventory.complete -or
    -not [bool]$ticket.reuseInventory.duplicateSearchComplete -or
    @($ticket.reuseInventory.familyConsumers).Count -ne 6 -or
    @($ticket.reuseInventory.newScreens).Count -ne 0 -or
    @($ticket.reuseInventory.newRoutes).Count -ne 0 -or
    @($ticket.reuseInventory.newBackendOwners).Count -ne 0 -or
    @($ticket.reuseInventory.newSubactions).Count -ne 0) {
  throw 'C20C reuse, duplicate-search, six-family or zero-new-owner contract is incomplete.'
}
if (-not [bool]$ticket.execution.referenceWriteAuthorized -or
    -not [bool]$ticket.execution.runtimeSourceWriteAuthorized -or
    -not [bool]$ticket.execution.testAndGateWriteAuthorized -or
    [bool]$ticket.execution.backendWriteAuthorized -or
    [bool]$ticket.execution.buildAuthorized -or
    [bool]$ticket.execution.installAuthorized -or
    [bool]$ticket.execution.externalServiceWriteAuthorized) {
  throw 'C20C execution authority has been weakened or expanded.'
}

$sequence = @($parent.implementationSequence)
$expectedIndex = [Array]::IndexOf($sequence, $expected)
$current = [string]$scope.ticket.id
$currentIndex = [Array]::IndexOf($sequence, $current)
if ([string]$parent.ticketId -cne 'UAW-PERSONAL-MVP-GLOBAL-SUBACTION-FOUNDER-GALLERY-PROFESSIONAL-RECOVERY-FIX3-C20' -or
    $expectedIndex -lt 0 -or $currentIndex -lt $expectedIndex -or
    [string]$scope.preTicketSelectionCheckpoint.currentTicketId -cne $current -or
    [string]$scope.state -cne 'ticket_disclosed_and_authorized') {
  throw 'C20C sequential MVP selection and disclosure gate is not active.'
}
if ([bool]$scope.execution.buildAuthorized -or
    [bool]$scope.execution.deviceInstallAuthorized -or
    [bool]$scope.execution.backendWriteAuthorized -or
    [bool]$scope.execution.externalServiceWriteAuthorized) {
  throw 'C20C host gate refuses build, install, backend and external authority.'
}

$contract = $ticket.neutralBrandGlassContract
if ([double]$contract.railSurfaceOpacity -ne 0 -or
    -not [bool]$contract.backgroundVisibleBetweenAndBehindControls -or
    -not [bool]$contract.individualNeutralGlassControlsRequired -or
    [bool]$contract.customFamilyAccentMapAllowed -or
    [bool]$contract.familyTintedFillAllowed -or
    [string]$contract.selectedColorLight -cne 'MoolBrand.identityNavy' -or
    [string]$contract.selectedColorMedia -cne 'MoolBrand.identityWhite' -or
    [bool]$contract.selectedFillUsesBrandColour -or
    -not [bool]$contract.neutralStateOpacityMayChange -or
    [double]$contract.minimumCompositedLabelContrast -ne 4.5 -or
    [double]$contract.controlHeight -ne 48 -or
    [double]$contract.controlRadius -ne 16 -or
    [double]$contract.labelFontSize -ne 13 -or
    [int]$contract.labelFontWeight -ne 700 -or
    [bool]$contract.selectedLabelFontWeightMayDiffer -or
    [double]$contract.maximumNavigationTextScale -ne 1.3 -or
    [double]$contract.iconOpticalBox -ne 20 -or
    [double]$contract.providerIconOpticalBox -ne 20 -or
    [double]$contract.itemGap -ne 4 -or
    [double]$contract.selectedIndicatorWidth -ne 18 -or
    [double]$contract.selectedIndicatorHeight -ne 2 -or
    [bool]$contract.selectedShadowAllowed -or
    [double]$contract.pressedScale -ne .985 -or
    [int]$contract.normalStateMotionMilliseconds -ne 160 -or
    -not [bool]$contract.reducedMotionImmediate -or
    (@($contract.supportedActionCounts) -join ',') -cne '2,3,4' -or
    [bool]$contract.horizontalScrollOrPanelAllowed -or
    [bool]$contract.distributedSparseCellsAllowed -or
    [bool]$contract.fillerActionAllowed -or
    [bool]$contract.fullWidthBandPanelOrTrapezoidAllowed) {
  throw 'C20C neutral brand-glass contract has drifted.'
}
if ([int]$regression.schemaVersion -ne 1 -or
    [string]$regression.contractId -cne 'UAW-PERSONAL-MVP-SUBACTION-PROFESSIONAL-RECOVERY-REGRESSION-C20' -or
    [bool]$regression.installedRejectedCandidate.mustRemainInstalledUntilQualifiedSuccessor -ne $true -or
    [bool]$regression.buildAuthorized -or [bool]$regression.installAuthorized -or
    [double]$regression.visualRules.railSurfaceOpacity -ne 0 -or
    -not [bool]$regression.visualRules.individualNeutralGlassRequired -or
    [bool]$regression.visualRules.familyTintedFillAllowed -or
    -not [bool]$regression.visualRules.brandPaletteOnlyForSelection -or
    [double]$regression.visualRules.minimumCompositedContrast -ne 4.5 -or
    [double]$regression.visualRules.controlHeight -ne 48 -or
    [double]$regression.visualRules.commonRadiusTarget -ne 16 -or
    [double]$regression.visualRules.labelFontSizeTarget -ne 13 -or
    [int]$regression.visualRules.labelFontWeightTarget -ne 700 -or
    [double]$regression.visualRules.iconOpticalBoxTarget -ne 20 -or
    (@($regression.visualRules.supportedCounts) -join ',') -cne '2,3,4' -or
    [bool]$regression.visualRules.backgroundBlockingBandAllowed -or
    [bool]$regression.visualRules.horizontalSubactionScrollAllowed -or
    [bool]$regression.visualRules.fillerActionAllowed) {
  throw 'C20C permanent visual-regression rules or preserved installed candidate have been weakened.'
}

$design = Get-Content -Raw -LiteralPath $designPath
$navigation = Get-Content -Raw -LiteralPath $navigationPath
$test = Get-Content -Raw -LiteralPath $testPath
$blockers = [Collections.Generic.List[string]]::new()

foreach ($token in @(
  'static const double controlHeight = MoolMetrics.compactTapTarget',
  'static const double controlRadius = 16',
  'static const double iconSize = 20',
  'static const double providerIconWidth = 20',
  'static const double providerIconHeight = 20',
  'static const double labelFontSize = 13',
  'static const FontWeight labelFontWeight = FontWeight.w700',
  'static const double maximumTextScale = 1.3',
  'static const double selectedIndicatorWidth = 18',
  'static const double selectedIndicatorHeight = 2',
  'static const Color lightGlassFill = Color(0x8FFFFFFF)',
  'static const Color mediaGlassFill = Color(0x9E081225)',
  'static MoolLocalNavigationSurfaceTone surfaceToneForFamily(String familyId)',
  'static Color selectionColor(MoolLocalNavigationSurfaceTone tone)',
  'static Color selectionColorForFamily(String familyId)',
  'static Color glassFill({',
  'static Color borderColor({',
  'static Color pressedOverlay(MoolLocalNavigationSurfaceTone tone)',
  'final stateAlpha = (base.a + (selected ? .04 : 0) + (pressed ? .08 : 0))',
  'child: BackdropFilter(',
  'scale: _pressed ? .985 : 1',
  'child: FittedBox(',
  'fit: BoxFit.scaleDown',
  '.labelFontWeight',
  'MoolMotion.accessible(context, MoolMotion.quick)'
)) {
  if (-not $design.Contains($token)) { $blockers.Add("shared neutral brand-glass owner is missing: $token") }
}

$tokenStart = $design.IndexOf('abstract final class MoolLocalNavigationTokens')
$railStart = $design.IndexOf('class MoolLocalNavigationRail extends StatelessWidget')
$railEnd = $design.IndexOf('class MoolOutcomeDock extends StatelessWidget', $railStart)
if ($tokenStart -lt 0 -or $railStart -le $tokenStart -or $railEnd -le $railStart) {
  $blockers.Add('shared neutral token or local-navigation owner bounds are invalid')
} else {
  $localOwner = $design.Substring($tokenStart, $railEnd - $tokenStart)
  foreach ($forbidden in @(
    'familyAccent(',
    'controlAccent(',
    "'social' => const Color(",
    "'buy' => const Color(",
    "'eat' => const Color(",
    "'ride' => const Color(",
    "'book' => const Color(",
    "'work' => const Color(",
    'SingleChildScrollView(',
    'Expanded(',
    'ListView(',
    'boxShadow:'
  )) {
    if ($localOwner.Contains($forbidden)) { $blockers.Add("shared owner retains rejected family tint, strip, expansion or selected shadow: $forbidden") }
  }
  if ([regex]::Matches($localOwner, 'child:\s*BackdropFilter\(').Count -ne 1) {
    $blockers.Add('shared owner must declare exactly one reusable per-action BackdropFilter')
  }
}

foreach ($token in @(
  'Color get _familySelectionColor',
  'MoolLocalNavigationTokens.selectionColorForFamily(widget.activeId)',
  'accent: _familySelectionColor',
  'MoolLocalNavigationTokens.connectionLineMaximumOpacity',
  'MoolLocalNavigationTokens.connectionLineStrokeWidth'
)) {
  if (-not $navigation.Contains($token)) { $blockers.Add("neutral family-connection owner is missing: $token") }
}
foreach ($forbidden in @('_familyAccent', 'familyAccent(', 'controlAccent(')) {
  if ($navigation.Contains($forbidden)) { $blockers.Add("navigation retains rejected custom family accent owner: $forbidden") }
}

foreach ($token in @(
  'tokens use one neutral Mool identity grammar',
  'for (final actionCount in const [2, 3, 4])',
  '$actionCount actions stay centered, individual and 48px',
  'light and media states stay neutral with readable contrast',
  'selected stays inert and neutral press is finite',
  'provider icon uses the same 20px optical box',
  'reduced motion settles every shared state immediately',
  'MoolLocalNavigationTokens.selectionColorForFamily(family)',
  'MoolLocalNavigationTokens.selectionColor(tone)',
  'greaterThanOrEqualTo(4.5)',
  'find.byType(FittedBox)',
  'FontWeight.w700',
  'hasAction(SemanticsAction.tap)'
)) {
  if (-not $test.Contains($token)) { $blockers.Add("C20C focused coverage is missing: $token") }
}

if ($blockers.Count -gt 0) {
  throw ('C20C shared neutral brand-glass control is not qualified: ' + ($blockers -join '; ') + '.')
}

Write-Output 'C20C shared neutral brand-glass control passed: families=6; states=17; railSurface=transparent; controls=individualNeutralGlass; familyTintedFill=absent; selection=identityNavyLight_identityWhiteMedia; control=48x16px; icon=20px; provider=20px; label=13px/700; counts=2,3,4; selectedShadow=absent; contrast>=4.5; normalMotion=160ms; reducedMotion=immediate; buildInstall=closed.'
