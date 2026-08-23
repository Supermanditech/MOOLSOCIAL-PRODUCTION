[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

$ticketPath = Join-Path $root 'config\uaw-personal-mvp-global-subaction-professional-design-system-fix1-c16-ticket.json'
$scopePath = Join-Path $root 'config\mvp-scope-gate-state.json'
$buyPath = Join-Path $root 'apps\mobile\lib\ui_v2\buy\buy_v2_screen.dart'
$testPath = Join-Path $root 'apps\mobile\test\ui_v2\buy\uaw_personal_mvp_buy_subaction_professional_conformance_c16c_test.dart'
$assessmentPath = Join-Path $root 'docs\quality\UAW-PERSONAL-MVP-BUY-SUBACTION-PROFESSIONAL-CONFORMANCE-FIX1-C16C-PRESELECTION-ASSESSMENT-20260808.md'

foreach ($path in @($ticketPath, $scopePath, $buyPath, $testPath, $assessmentPath)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "C16C required owner is missing: $path"
  }
}

$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$expected = 'UAW-PERSONAL-MVP-BUY-SUBACTION-PROFESSIONAL-CONFORMANCE-FIX1-C16C'
$sequence = @($ticket.implementationSequence)
$expectedIndex = [Array]::IndexOf($sequence, $expected)
$current = [string]$scope.ticket.id
$currentIndex = [Array]::IndexOf($sequence, $current)
if ($expectedIndex -lt 0 -or
    $currentIndex -lt $expectedIndex -or
    [string]$scope.preTicketSelectionCheckpoint.currentTicketId -cne $current -or
    [string]$scope.state -cne 'ticket_disclosed_and_authorized') {
  throw 'C16C MVP selection/disclosure gate is not active or has not been passed sequentially.'
}
if ([bool]$scope.execution.buildAuthorized -or
    [bool]$scope.execution.deviceInstallAuthorized -or
    [bool]$scope.execution.backendWriteAuthorized -or
    [bool]$scope.execution.referenceWriteAuthorized -or
    [bool]$scope.execution.externalServiceWriteAuthorized) {
  throw 'C16C host gate refuses build, install, backend, reference or external write authority.'
}

$buy = Get-Content -Raw -LiteralPath $buyPath
$test = Get-Content -Raw -LiteralPath $testPath
$blockers = [Collections.Generic.List[string]]::new()

foreach ($token in @(
  'localNavigation: _buildBuyLocalNavigation(session)',
  'Widget _buildBuyLocalNavigation(BuyV2Session session)',
  'return MoolLocalNavigationRail(',
  "key: const ValueKey('buy-local-destination-tabs')",
  "familyId: 'buy'",
  "keyName: 'buy-local-tab-shop'",
  "keyName: 'buy-local-tab-wholesale'",
  "keyName: 'buy-local-tab-medicine'",
  "keyName: 'buy-local-tab-orders'",
  'session.openDestination(BuyV2Destination.shop)',
  'session.openDestination(BuyV2Destination.wholesale)',
  'session.openDestination(BuyV2Destination.medicine)',
  'session.openOrders()'
)) {
  if (-not $buy.Contains($token)) { $blockers.Add("Buy shared owner mapping is missing: $token") }
}

foreach ($forbidden in @(
  'class _BuyDestinationTabs',
  'class _BuyDestinationTabsState',
  'class _BuyLocalRailCue',
  'buy-local-destination-tabs-scroll',
  'buy-local-destination-tabs-overflow-cue'
)) {
  if ($buy.Contains($forbidden)) { $blockers.Add("duplicate Buy lane/cue owner remains: $forbidden") }
}

$mappingStart = $buy.IndexOf('Widget _buildBuyLocalNavigation(BuyV2Session session)')
$mappingEnd = $buy.IndexOf('bool _showsMiniCart(BuyV2Session session)', $mappingStart)
if ($mappingStart -lt 0 -or $mappingEnd -le $mappingStart) {
  $blockers.Add('Buy shared action-mapping bounds are invalid')
} else {
  $mapping = $buy.Substring($mappingStart, $mappingEnd - $mappingStart)
  foreach ($forbidden in @('SingleChildScrollView(', 'ScrollController(', 'LayoutBuilder(', 'Expanded(', '_itemWidth', '_canScrollBack', '_canScrollForward')) {
    if ($mapping.Contains($forbidden)) { $blockers.Add("Buy action mapping retains forbidden lane state: $forbidden") }
  }
}

foreach ($businessToken in @(
  'BuyV2SearchResultsView(',
  '_currentView(session)',
  '_showsMiniCart(session)',
  '_BuyMiniCartBar(session: session)',
  'session.itemCount > 0',
  'scannerLauncher',
  'BuyV2Destination.wholesale',
  'BuyV2Destination.medicine',
  'BuyV2Destination.orders'
)) {
  if (-not $buy.Contains($businessToken)) { $blockers.Add("Buy commercial/content owner changed or disappeared: $businessToken") }
}

foreach ($token in @(
  'Buy four-action family is compact, shared and never a horizontal lane',
  'Buy shared selection settles immediately under reduced motion',
  'isA<MoolLocalNavigationRail>()',
  'find.byType(Scrollable)',
  'find.byType(Expanded)',
  'greaterThanOrEqualTo(44)',
  "expect(node.label, 'Shop, current')",
  "expect(node.label, 'Open Wholesale')",
  'expect(session.destination, BuyV2Destination.wholesale)',
  'expect(product.hitTestable(), findsOneWidget)',
  'lessThanOrEqualTo(tester.getRect(rail).top)',
  'expect(selection.duration, Duration.zero)'
)) {
  if (-not $test.Contains($token)) { $blockers.Add("C16C focused coverage is missing: $token") }
}

if ($blockers.Count -gt 0) {
  throw ('C16C Buy professional conformance is not implemented: ' + ($blockers -join '; ') + '.')
}

Write-Output 'C16C Buy professional conformance passed: actions=Shop,Wholesale,Medicine,Orders; sharedOwner=1; horizontalLane=absent; overflowCues=absent; commercialOwners=preserved; target=44px; reducedMotion=immediate; buildInstall=closed.'
