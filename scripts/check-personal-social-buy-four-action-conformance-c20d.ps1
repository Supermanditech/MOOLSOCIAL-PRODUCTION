[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

$predecessorGate = Join-Path $root 'scripts\check-personal-shared-neutral-brand-glass-control-c20c.ps1'
$parentPath = Join-Path $root 'config\uaw-personal-mvp-global-subaction-founder-gallery-professional-recovery-fix3-c20-ticket.json'
$ticketPath = Join-Path $root 'config\uaw-personal-mvp-social-buy-four-action-conformance-fix3-c20d-ticket.json'
$regressionPath = Join-Path $root 'config\mvp-personal-subaction-professional-recovery-regression-c20.json'
$scopePath = Join-Path $root 'config\mvp-scope-gate-state.json'
$socialPath = Join-Path $root 'apps\mobile\lib\ui_v2\social\screen04_universal_components.dart'
$buyPath = Join-Path $root 'apps\mobile\lib\ui_v2\buy\buy_v2_screen.dart'
$navigationPath = Join-Path $root 'apps\mobile\lib\ui_v2\universal\mool_global_navigation_v2.dart'
$testPath = Join-Path $root 'apps\mobile\test\ui_v2\universal\uaw_personal_mvp_social_buy_four_action_conformance_c20d_test.dart'

foreach ($path in @($predecessorGate, $parentPath, $ticketPath, $regressionPath, $scopePath, $socialPath, $buyPath, $navigationPath, $testPath)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "C20D required owner is missing: $path"
  }
}

& $predecessorGate -RepositoryRoot $root

$parent = Get-Content -Raw -LiteralPath $parentPath | ConvertFrom-Json
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$regression = Get-Content -Raw -LiteralPath $regressionPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$expected = 'UAW-PERSONAL-MVP-SOCIAL-BUY-FOUR-ACTION-CONFORMANCE-FIX3-C20D'

if ([int]$ticket.schemaVersion -ne 1 -or
    [string]$ticket.ticketId -cne $expected -or
    [string]$ticket.parentTicket -cne [string]$parent.ticketId -or
    [string]$ticket.classification -cne 'mvp_required') {
  throw 'C20D ticket identity or MVP classification is invalid.'
}
if (-not [bool]$ticket.reuseInventory.complete -or
    -not [bool]$ticket.reuseInventory.duplicateSearchComplete -or
    (@($ticket.reuseInventory.existingActions.social) -join ',') -cne 'shorts,videos,feed,create' -or
    (@($ticket.reuseInventory.existingActions.buy) -join ',') -cne 'shop,wholesale,medicine,orders' -or
    @($ticket.reuseInventory.newScreens).Count -ne 0 -or
    @($ticket.reuseInventory.newRoutes).Count -ne 0 -or
    @($ticket.reuseInventory.newBackendOwners).Count -ne 0 -or
    @($ticket.reuseInventory.newSubactions).Count -ne 0) {
  throw 'C20D reuse, duplicate-search, eight-action or zero-new-owner contract is incomplete.'
}
if (-not [bool]$ticket.execution.referenceWriteAuthorized -or
    -not [bool]$ticket.execution.runtimeSourceWriteAuthorized -or
    -not [bool]$ticket.execution.testAndGateWriteAuthorized -or
    [bool]$ticket.execution.backendWriteAuthorized -or
    [bool]$ticket.execution.buildAuthorized -or
    [bool]$ticket.execution.installAuthorized -or
    [bool]$ticket.execution.externalServiceWriteAuthorized) {
  throw 'C20D execution authority has been weakened or expanded.'
}

$sequence = @($parent.implementationSequence)
$expectedIndex = [Array]::IndexOf($sequence, $expected)
$current = [string]$scope.ticket.id
$currentIndex = [Array]::IndexOf($sequence, $current)
if ([string]$parent.ticketId -cne 'UAW-PERSONAL-MVP-GLOBAL-SUBACTION-FOUNDER-GALLERY-PROFESSIONAL-RECOVERY-FIX3-C20' -or
    $expectedIndex -lt 0 -or $currentIndex -lt $expectedIndex -or
    [string]$scope.preTicketSelectionCheckpoint.currentTicketId -cne $current -or
    [string]$scope.state -cne 'ticket_disclosed_and_authorized') {
  throw 'C20D sequential MVP selection and disclosure gate is not active.'
}
if ([bool]$scope.execution.buildAuthorized -or
    [bool]$scope.execution.deviceInstallAuthorized -or
    [bool]$scope.execution.backendWriteAuthorized -or
    [bool]$scope.execution.externalServiceWriteAuthorized) {
  throw 'C20D host gate refuses build, install, backend and external authority.'
}

$contract = $ticket.fourActionContract
if ((@($contract.families) -join ',') -cne 'social,buy' -or
    [int]$contract.actionsPerFamily -ne 4 -or
    [int]$contract.selectedStateCount -ne 8 -or
    [string]$contract.surfaceToneSocial -cne 'media' -or
    [string]$contract.surfaceToneBuy -cne 'light' -or
    [double]$contract.controlHeight -ne 48 -or
    [double]$contract.minimumTapTarget -ne 48 -or
    [double]$contract.controlRadius -ne 16 -or
    [double]$contract.labelFontSize -ne 13 -or
    [int]$contract.labelFontWeight -ne 700 -or
    [double]$contract.maximumNavigationTextScale -ne 1.3 -or
    [double]$contract.iconOpticalBox -ne 20 -or
    [double]$contract.providerIconOpticalBox -ne 20 -or
    [double]$contract.minimumCompositedLabelContrast -ne 4.5 -or
    (@($contract.supportedWidths) -join ',') -cne '320,360,390,412,430' -or
    [bool]$contract.horizontalScrollOrPanelAllowed -or
    [bool]$contract.blockingBandOrTrapezoidAllowed -or
    [bool]$contract.familyTintedFillAllowed -or
    [bool]$contract.fillerActionAllowed -or
    -not [bool]$contract.selectedActionInert -or
    -not [bool]$contract.availableActionOneTap -or
    [int]$contract.normalStateMotionMilliseconds -ne 160 -or
    -not [bool]$contract.reducedMotionImmediate) {
  throw 'C20D Social/Buy four-action contract has drifted.'
}
if ([bool]$regression.installedRejectedCandidate.mustRemainInstalledUntilQualifiedSuccessor -ne $true -or
    [bool]$regression.buildAuthorized -or [bool]$regression.installAuthorized -or
    (@($regression.families.social) -join ',') -cne 'shorts,videos,feed,create' -or
    (@($regression.families.buy) -join ',') -cne 'shop,wholesale,medicine,orders') {
  throw 'C20D preserved installed candidate or permanent Social/Buy action matrix has drifted.'
}

$social = Get-Content -Raw -LiteralPath $socialPath
$buy = Get-Content -Raw -LiteralPath $buyPath
$navigation = Get-Content -Raw -LiteralPath $navigationPath
$test = Get-Content -Raw -LiteralPath $testPath
$blockers = [Collections.Generic.List[string]]::new()

$socialStart = $social.IndexOf('class Screen04ContextTabs extends StatelessWidget')
$socialEnd = $social.IndexOf('@immutable', $socialStart)
if ($socialStart -lt 0 -or $socialEnd -le $socialStart) {
  $blockers.Add('Social family wrapper bounds are invalid')
} else {
  $socialRail = $social.Substring($socialStart, $socialEnd - $socialStart)
  foreach ($token in @(
    'MoolLocalNavigationRail(',
    "familyId: 'social'",
    'surfaceTone: MoolLocalNavigationSurfaceTone.media',
    "'shorts' => Icons.play_circle_outline_rounded",
    "'videos' => Icons.ondemand_video_outlined",
    "'feed' => Icons.dynamic_feed_outlined",
    "'create' => Icons.add_circle_outline_rounded",
    'iconAsset: item.attributionAsset'
  )) {
    if (-not $socialRail.Contains($token)) { $blockers.Add("Social four-action owner is missing: $token") }
  }
}

$buyStart = $buy.IndexOf('Widget _buildBuyLocalNavigation(BuyV2Session session)')
$buyEnd = $buy.IndexOf('void _openGlobalMool()', $buyStart)
if ($buyStart -lt 0 -or $buyEnd -le $buyStart) {
  $blockers.Add('Buy family wrapper bounds are invalid')
} else {
  $buyRail = $buy.Substring($buyStart, $buyEnd - $buyStart)
  foreach ($token in @(
    'MoolLocalNavigationRail(',
    "familyId: 'buy'",
    "keyName: 'buy-local-tab-shop'",
    "keyName: 'buy-local-tab-wholesale'",
    "keyName: 'buy-local-tab-medicine'",
    "keyName: 'buy-local-tab-orders'",
    "label: 'Shop'",
    "label: 'Wholesale'",
    "label: 'Medicine'",
    "label: 'Orders'"
  )) {
    if (-not $buyRail.Contains($token)) { $blockers.Add("Buy four-action owner is missing: $token") }
  }
  foreach ($forbidden in @('surfaceTone: MoolLocalNavigationSurfaceTone.media', 'SingleChildScrollView(', 'Expanded(')) {
    if ($buyRail.Contains($forbidden)) { $blockers.Add("Buy retains rejected media tone, scroll or sparse expansion: $forbidden") }
  }
}

foreach ($token in @(
  'moolDestinationFamilyRailSurfaceOpacity = 0',
  'MoolLocalNavigationTokens.connectionLineMaximumOpacity',
  'MoolLocalNavigationTokens.connectionLineStrokeWidth'
)) {
  if (-not $navigation.Contains($token)) { $blockers.Add("transparent connection shell is missing: $token") }
}

foreach ($token in @(
  'const _widths = [320.0, 360.0, 390.0, 412.0, 430.0]',
  'const _textScales = [1.0, 1.3]',
  'Social qualifies four media-glass actions at five widths and two text scales',
  'Buy qualifies four light-glass actions at five widths and two text scales',
  'Social and Buy keep finite state motion and immediate reduced motion',
  "_ActionSpec('screen04-rail-shorts', 'shorts', 'Shorts')",
  "_ActionSpec('screen04-rail-videos', 'videos', 'Videos')",
  "_ActionSpec('screen04-rail-feed', 'feed', 'Feed')",
  "_ActionSpec('screen04-rail-create', 'create', 'Create')",
  "_ActionSpec('buy-local-tab-shop', 'shop', 'Shop')",
  "_ActionSpec('buy-local-tab-wholesale', 'wholesale', 'Wholesale')",
  "_ActionSpec('buy-local-tab-medicine', 'medicine', 'Medicine')",
  "_ActionSpec('buy-local-tab-orders', 'orders', 'Orders')",
  'findsNWidgets(2)',
  'moolDestinationFamilyRailSurfaceOpacity, 0',
  'MoolLocalNavigationTokens.clusterWidth(width, 4)',
  'greaterThanOrEqualTo(48)',
  'flagsCollection.isSelected',
  'hasAction(SemanticsAction.tap)',
  'find.byType(FittedBox)',
  'MoolLocalNavigationTokens.glassFill(',
  'greaterThanOrEqualTo(4.5)',
  'Duration.zero'
)) {
  if (-not $test.Contains($token)) { $blockers.Add("C20D focused coverage is missing: $token") }
}

if ($blockers.Count -gt 0) {
  throw ('C20D Social/Buy four-action conformance is not qualified: ' + ($blockers -join '; ') + '.')
}

Write-Output 'C20D Social/Buy four-action conformance passed: families=Social,Buy; actions=4,4; selectedStates=8; widths=320,360,390,412,430; textScales=1.0,1.3; tones=media,light; providerSvg=2; target=48px; label=13px/700; contrast>=4.5; railSurface=transparent; reducedMotion=immediate; buildInstall=closed.'
