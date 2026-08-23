[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

$ticketPath = Join-Path $root 'config\uaw-personal-mvp-buy-local-tabs-global-dock-fix1-c10c-ticket.json'
$buyPath = Join-Path $root 'apps\mobile\lib\ui_v2\buy\buy_v2_screen.dart'
$cataloguePath = Join-Path $root 'apps\mobile\lib\ui_v2\buy\buy_v2_catalogue.dart'
$buyFlowPath = Join-Path $root 'apps\mobile\lib\features\buy\widgets\buy_widgets.dart'
$globalPath = Join-Path $root 'apps\mobile\lib\ui_v2\universal\mool_global_navigation_v2.dart'
$designPath = Join-Path $root 'apps\mobile\lib\core\design\mool_design_system.dart'
$journeyTestPath = Join-Path $root 'apps\mobile\test\ui_v2\buy\uaw_personal_mvp_buy_local_tabs_global_dock_c10c_test.dart'
$fitmentTestPath = Join-Path $root 'apps\mobile\test\ui_v2\buy\buy_v2_screen_test.dart'
foreach ($path in @($ticketPath, $buyPath, $cataloguePath, $buyFlowPath, $globalPath, $designPath, $journeyTestPath, $fitmentTestPath)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "C10C required owner is missing: $path"
  }
}

$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
if ([string]$ticket.ticketId -cne 'UAW-PERSONAL-MVP-BUY-LOCAL-TABS-GLOBAL-DOCK-FIX1-C10C' -or
    [string]$ticket.parentTicket -cne 'UAW-PERSONAL-MVP-UNIFIED-PERSISTENT-BOTTOM-NAVIGATION-SHELL-FIX1-C10') {
  throw 'C10C ticket identity is invalid.'
}

$buy = Get-Content -Raw -LiteralPath $buyPath
$catalogue = Get-Content -Raw -LiteralPath $cataloguePath
$buyFlow = Get-Content -Raw -LiteralPath $buyFlowPath
$global = Get-Content -Raw -LiteralPath $globalPath
$design = Get-Content -Raw -LiteralPath $designPath
$journeyTest = Get-Content -Raw -LiteralPath $journeyTestPath
$fitmentTest = Get-Content -Raw -LiteralPath $fitmentTestPath
$blockers = [Collections.Generic.List[string]]::new()

foreach ($token in @(
  'bottomNavigationBar: MoolDestinationNavigationV2(',
  "activeId: 'buy'",
  'onOpenMool: _openGlobalMool',
  'onOpenAction: _openGlobalAction',
  'onOpenChat: _openGlobalChat',
  'localNavigation: _buildBuyLocalNavigation(session)',
  'localActionCount: 4',
  'Widget _buildBuyLocalNavigation(BuyV2Session session)',
  'return MoolLocalNavigationRail(',
  "key: const ValueKey('buy-local-destination-tabs')",
  "familyId: 'buy'",
  "keyName: 'buy-local-tab-shop'",
  'id: BuyV2Destination.shop.name',
  "keyName: 'buy-local-tab-wholesale'",
  'id: BuyV2Destination.wholesale.name',
  "keyName: 'buy-local-tab-medicine'",
  'id: BuyV2Destination.medicine.name',
  "keyName: 'buy-local-tab-orders'",
  'id: BuyV2Destination.orders.name',
  'active == BuyV2Destination.shop',
  'active == BuyV2Destination.wholesale',
  'active == BuyV2Destination.medicine',
  'active == BuyV2Destination.orders',
  '? null',
  'session.openDestination(BuyV2Destination.shop)',
  'session.openDestination(BuyV2Destination.wholesale)',
  'session.openDestination(BuyV2Destination.medicine)',
  'session.openOrders()'
)) {
  if (-not $buy.Contains($token)) {
    $blockers.Add("Buy shared/local navigation contract is missing: $token")
  }
}

$localTabsCallCount = [regex]::Matches(
  $buy,
  [regex]::Escape('localNavigation: _buildBuyLocalNavigation(session)')
).Count
if ($localTabsCallCount -ne 1) {
  $blockers.Add("Buy local tabs must have exactly one runtime call site; found $localTabsCallCount")
}
$destinationNavigationIndex = $buy.IndexOf('bottomNavigationBar: MoolDestinationNavigationV2(')
$localTabsIndex = $buy.IndexOf('localNavigation: _buildBuyLocalNavigation(session)')
if ($destinationNavigationIndex -lt 0 -or $localTabsIndex -le $destinationNavigationIndex) {
  $blockers.Add('Buy local destinations are not contained in the shared lower shelf owner')
}
if ($buy.Contains("id: 'help'") -or $buy.Contains("label: 'Help'")) {
  $blockers.Add('Buy Help has regressed into the primary destination shelf')
}
if (-not $global.Contains('class MoolDestinationNavigationV2') -or
    -not $global.Contains('MoolGlobalNavigationV2(')) {
  $blockers.Add('shared lower shelf does not terminate in the global rail')
}

foreach ($retired in @(
  'class _BuyDock',
  'buy-persistent-dock',
  'buy-dock-chat',
  'buy-mool-social',
  '_showPrimaryActions',
  'class _BuyDestinationTabs',
  'class _BuyDestinationTabsState',
  'class _BuyLocalRailCue',
  'buy-local-destination-tabs-scroll',
  'buy-local-destination-tabs-overflow-cue',
  '_scheduleSelectedReveal()'
)) {
  if ($buy.Contains($retired)) {
    $blockers.Add("retired Buy navigation owner remains reachable: $retired")
  }
}

foreach ($token in @(
  'bottomNavigationBar: MoolGlobalNavigationV2(',
  "activeId: 'buy'",
  "id: 'shop'",
  "id: 'basket'",
  "id: 'orders'",
  "Key(keyName ?? 'buy-local-flow-",
  'PopScope<Object?>('
)) {
  if (-not $buyFlow.Contains($token)) {
    $blockers.Add("reachable Buy flow navigation contract is missing: $token")
  }
}
foreach ($retired in @(
  'class BuyBottomDock',
  'BuyBottomDock(',
  'buy-dock-mool',
  'buy-dock-shop',
  'buy-dock-basket',
  'buy-dock-orders',
  'buy-dock-chat',
  "Key('buy-back')",
  'Icons.arrow_back_ios_new_rounded'
)) {
  if ($buyFlow.Contains($retired)) {
    $blockers.Add("reachable retired Buy flow navigation remains: $retired")
  }
}

if (-not $catalogue.Contains('bottom: MoolMetrics.compactTapTarget')) {
  $blockers.Add('Buy category sheet does not terminate against the shared compact dock token')
}
foreach ($token in @(
  "key: const Key('mool-outcome-dock-surface')",
  'height: MoolMetrics.compactTapTarget',
  'minHeight: MoolMetrics.minimumTapTarget'
)) {
  if (-not $design.Contains($token)) {
    $blockers.Add("shared compact dock accessibility contract is missing: $token")
  }
}
foreach ($token in @(
  "keyName: 'mool-root-chat'",
  "id: 'buy'",
  "route: '/app/buy'"
)) {
  if (-not $global.Contains($token)) {
    $blockers.Add("global Buy/Chat owner is missing: $token")
  }
}
foreach ($token in @(
  'Buy separates local destinations from global Chat and Mool',
  'Buy Medicine survives Mool and system Back exactly'
)) {
  if (-not $journeyTest.Contains($token)) {
    $blockers.Add("C10C journey coverage is missing: $token")
  }
}
foreach ($token in @(
  'purchase and navigation actions meet the 44 pixel target',
  '140 percent text fits every primary Buy state at 320 width',
  'category glass ends above the dock with compact heading and close'
)) {
  if (-not $fitmentTest.Contains($token)) {
    $blockers.Add("C10C Buy fitment coverage is missing: $token")
  }
}

if ($blockers.Count -gt 0) {
  throw ('C10C Buy global/local navigation is not implemented: ' + ($blockers -join '; ') + '.')
}

Write-Output 'C10C Buy navigation passed: one global bottom dock; four local shelf destinations; Help is contextual; Chat is global; compact targets and category seam are gated.'
