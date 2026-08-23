[CmdletBinding()]
param(
  [string]$RepositoryRoot,
  [switch]$RequireImplemented
)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)
$contractPath = Join-Path $root 'config\mvp-personal-global-mool-bottom-rail-navigation-fix1.json'
$auditPath = Join-Path $root 'docs\quality\UAW-PERSONAL-MVP-GLOBAL-MOOL-BOTTOM-RAIL-NAVIGATION-AUDIT-20260806.md'
$scenarioPath = Join-Path $root 'config\mvp-personal-global-mool-navigation-scenario-ledger-v3.json'
$placementGatePath = Join-Path $root 'scripts\check-personal-subaction-placement-regression.ps1'
if (-not (Test-Path -LiteralPath $contractPath -PathType Leaf)) { throw 'Global Mool navigation contract is missing.' }
if (-not (Test-Path -LiteralPath $auditPath -PathType Leaf)) { throw 'Global Mool navigation audit is missing.' }
if (-not (Test-Path -LiteralPath $scenarioPath -PathType Leaf)) { throw 'Global Mool navigation scenario ledger is missing.' }
if (-not (Test-Path -LiteralPath $placementGatePath -PathType Leaf)) { throw 'Sub-action placement regression gate is missing.' }
& $placementGatePath -RepositoryRoot $root -RequireImplemented:$RequireImplemented
$contract = Get-Content -Raw -LiteralPath $contractPath | ConvertFrom-Json
if ([int]$contract.schemaVersion -ne 3 -or
    [string]$contract.contractId -cne 'UAW-PERSONAL-MVP-GLOBAL-MOOL-BOTTOM-RAIL-NAVIGATION-FIX1-CONTRACT-V3' -or
    [string]$contract.parentTicketId -cne 'UAW-PERSONAL-MVP-GLOBAL-MOOL-BOTTOM-RAIL-NAVIGATION-FIX1') {
  throw 'Global Mool navigation contract identity is invalid.'
}
if (-not [bool]$contract.rules.moolIsStableHub -or
    [bool]$contract.rules.moolMayAliasSocial -or
    [bool]$contract.rules.moolMayOpenModalMenu -or
    [bool]$contract.rules.moolMayToggleMainActionRibbon -or
    [bool]$contract.rules.moolMayBeNavigationOnlyLauncher -or
    -not [bool]$contract.rules.moolRequiresDurableHomeContent -or
    -not [bool]$contract.rules.mainActionsLiveInPersistentHubRail -or
    [bool]$contract.rules.hubBodyMayRenderOriginReturnSheet -or
    -not [bool]$contract.rules.hubBodyUsesTruthfulSelectedArea -or
    [bool]$contract.rules.moolVisibleHeaderBackAllowed -or
    [bool]$contract.rules.moolSelectedRetapHasSideEffects -or
    -not [bool]$contract.rules.systemBackRestoresExactOrigin -or
    -not [bool]$contract.rules.mainRailOverflowCueRequired -or
    -not [bool]$contract.rules.finiteDirectionalMotionRequired -or
    -not [bool]$contract.rules.reducedMotionRequired -or
    [bool]$contract.rules.backMayOpenMoolMenu -or
    [bool]$contract.rules.activeLifecycleMayReset) {
  throw 'Global Mool navigation contract has been weakened.'
}
if (@($contract.rules.mainActionsLiveOnHub) -join ',' -cne 'social,buy,eat,ride,book,work') {
  throw 'Global Mool main-action projection changed.'
}
if (@($contract.childrenInOrder).Count -ne 9 -or
    [string]$contract.childrenInOrder[6] -cne 'UAW-PERSONAL-MVP-GLOBAL-MOOL-BOTTOM-RAIL-NAVIGATION-FIX1-C07-DURABLE-MOOL-HOME-PERSISTENT-ROOT-RAIL' -or
    [string]$contract.childrenInOrder[7] -cne 'UAW-PERSONAL-MVP-GLOBAL-MOOL-BOTTOM-RAIL-NAVIGATION-FIX1-C08-DURABLE-HOME-CUMULATIVE-OPPO' -or
    [string]$contract.childrenInOrder[8] -cne 'UAW-PERSONAL-MVP-GLOBAL-MOOL-BOTTOM-RAIL-NAVIGATION-FIX1-C09-MOOL-HOME-RESELECT-BACK-STACK-MOTION') {
  throw 'Sequential child-ticket list is incomplete.'
}

$scenario = Get-Content -Raw -LiteralPath $scenarioPath | ConvertFrom-Json
if ([int]$scenario.schemaVersion -ne 3 -or
    [string]$scenario.ledgerId -cne 'UAW-PERSONAL-MVP-GLOBAL-MOOL-NAVIGATION-SCENARIOS-V3' -or
    [string]$scenario.status -cne 'blocking_until_host_and_oppo_green') {
  throw 'Global Mool navigation scenario-ledger identity is invalid.'
}
$expectedScenarioIds = 1..22 | ForEach-Object { 'U{0:d2}' -f $_ }
$actualScenarioIds = @($scenario.scenarios | ForEach-Object { [string]$_.id })
if ($actualScenarioIds.Count -ne 22 -or ($actualScenarioIds -join ',') -cne ($expectedScenarioIds -join ',')) {
  throw 'Global Mool navigation scenario ledger must contain ordered U01-U22 exactly once.'
}
foreach ($case in @($scenario.scenarios)) {
  foreach ($field in @('entry', 'action', 'visibleDestination', 'backResult', 'forwardReturnResult', 'hostAssertion')) {
    if ([string]::IsNullOrWhiteSpace([string]$case.$field)) {
      throw "Global Mool navigation scenario $($case.id) is missing $field."
    }
  }
  if (@($case.forbiddenAlternatives).Count -lt 1) {
    throw "Global Mool navigation scenario $($case.id) has no forbidden alternatives."
  }
}
if (@($scenario.productionOutcome.moolRail) -join ',' -cne 'mool,social,buy,eat,ride,book,work,chat' -or
    [string]$scenario.productionOutcome.moolDestination -cne 'first_class_durable_mool_home' -or
    [string]$scenario.productionOutcome.focusedRail -cne 'one_global_mool_main_actions_chat_rail_with_local_destination_subactions') {
  throw 'Global Mool production outcome projection changed.'
}

if ($RequireImplemented) {
  $personal = Get-Content -Raw -LiteralPath (Join-Path $root 'apps\mobile\lib\ui_v2\universal\personal_mool_root_v2.dart')
  $global = Get-Content -Raw -LiteralPath (Join-Path $root 'apps\mobile\lib\ui_v2\universal\mool_global_navigation_v2.dart')
  $choice = Get-Content -Raw -LiteralPath (Join-Path $root 'apps\mobile\lib\ui_v2\universal\mvp_action_choice_root_v2.dart')
  $social = Get-Content -Raw -LiteralPath (Join-Path $root 'apps\mobile\lib\ui_v2\social\social_v2_consumer.dart')
  $socialRail = Get-Content -Raw -LiteralPath (Join-Path $root 'apps\mobile\lib\ui_v2\social\screen04_universal_components.dart')
  $router = Get-Content -Raw -LiteralPath (Join-Path $root 'apps\mobile\lib\features\journey01\journey_router.dart')
  $buy = Get-Content -Raw -LiteralPath (Join-Path $root 'apps\mobile\lib\ui_v2\buy\buy_v2_screen.dart')
  $journey = Get-Content -Raw -LiteralPath (Join-Path $root 'apps\mobile\lib\features\journey01\journey_session.dart')
  $chatInbox = Get-Content -Raw -LiteralPath (Join-Path $root 'apps\mobile\lib\features\chat\screens\chat_inbox_screen.dart')
  $chatThread = Get-Content -Raw -LiteralPath (Join-Path $root 'apps\mobile\lib\features\chat\screens\chat_thread_screen.dart')
  $shared = Get-Content -Raw -LiteralPath (Join-Path $root 'apps\mobile\lib\features\shared\screens\shared_screens.dart')
  $productionNavigation = $personal + $global + $choice +
    (Get-Content -Raw -LiteralPath (Join-Path $root 'apps\mobile\lib\features\eat\widgets\eat_widgets.dart')) +
    (Get-Content -Raw -LiteralPath (Join-Path $root 'apps\mobile\lib\features\ride\widgets\ride_widgets.dart')) +
    (Get-Content -Raw -LiteralPath (Join-Path $root 'apps\mobile\lib\features\book\widgets\book_widgets.dart')) +
    (Get-Content -Raw -LiteralPath (Join-Path $root 'apps\mobile\lib\features\work\widgets\work_widgets.dart'))
  $blockers = [Collections.Generic.List[string]]::new()
  if ($productionNavigation -match 'showPersonalMoolActionPanel') { $blockers.Add('modal Mool action panel remains') }
  if ($social -match '_moolOpen') { $blockers.Add('Social Mool toggle state remains') }
  if ($socialRail -match 'moolOpen') { $blockers.Add('Social rail main-action mode remains') }
  if ($router -match "initialWorld:\s*state\.uri\.queryParameters\['world'\]") { $blockers.Add('Social world query can reactivate a removed main action') }
  if ($buy -match '_showPrimaryActions') { $blockers.Add('Buy rail main-action mode remains') }
  if ($journey -match '/app/social\?openMool=1') { $blockers.Add('Buy Social fallback remains') }
  if ($chatInbox -match "chat-open-mool[\s\S]{0,180}context\.go\('/app/mool'\)") { $blockers.Add('Chat inbox Mool route replacement remains') }
  if ($chatThread -match "chat-thread-mool[\s\S]{0,180}context\.go\('/app/mool'\)") { $blockers.Add('Chat thread Mool route replacement remains') }
  if ($shared -match "shared-dock-mool[\s\S]{0,260}context\.go\('/app/social'\)") { $blockers.Add('shared Mool Social alias remains') }
  foreach ($rejectedToken in @(
    'Where do you want to go?',
    'Choose once. Move forward instantly.',
    'Jump anywhere in one tap',
    'mool-root-action-grid',
    '_MoolOrbit',
    '_MoolActionArrival'
  )) {
    if ($personal.Contains($rejectedToken)) { $blockers.Add("rejected navigation-only launcher remains: $rejectedToken") }
  }
  foreach ($requiredToken in @(
    'mool-home-dashboard',
    'mool-home-area',
    'mool-home-primary-actions'
  )) {
    if (-not $personal.Contains($requiredToken)) { $blockers.Add("durable Mool home marker is missing: $requiredToken") }
  }
  foreach ($requiredGlobalToken in @(
    'mool-root-main-actions',
    'showOverflowCue: true',
    "keyName: 'mool-action-`$`{action.id`}'",
    "activeId == action.id",
    "'Open `$`{action.label`}'"
  )) {
    if (-not $global.Contains($requiredGlobalToken)) { $blockers.Add("shared global navigation marker is missing: $requiredGlobalToken") }
  }
  if (-not $global.Contains('MoolOutcomeDock(')) { $blockers.Add('global navigation does not reuse the persistent outcome dock') }
  if (-not $personal.Contains('MoolGlobalNavigationV2(')) { $blockers.Add('Mool Home does not use the shared global navigation owner') }
  if (-not $choice.Contains('MoolGlobalNavigationV2(') -or
      $choice.Contains('_ActionChoiceDock') -or
      $choice.Contains('Icons.arrow_back_ios_new_rounded')) {
    $blockers.Add('main-action chooser retains destination-owned or visible-Back navigation')
  }
  if (-not $social.Contains('MoolDestinationNavigationV2(') -or
      -not $social.Contains('Screen04ContextTabs(') -or
      $social.Contains('Screen04CapabilityRail(') -or
      $socialRail.Contains('class Screen04CapabilityRail')) {
    $blockers.Add('Social does not separate local options from the shared global navigation owner')
  }
  foreach ($rejectedHomeToken in @('mool-root-back', 'mool-home-continue', 'Continue ${origin.label}', 'originSection:')) {
    if ($personal.Contains($rejectedHomeToken)) { $blockers.Add("return-sheet Mool ownership remains: $rejectedHomeToken") }
  }
  if (-not $personal.Contains('areaLabel')) {
    $blockers.Add('Mool home does not receive truthful selected-area context')
  }
  $design = Get-Content -Raw -LiteralPath (Join-Path $root 'apps\mobile\lib\core\design\mool_design_system.dart')
  if (-not $design.Contains('actions.length <= 3') -or
      -not $design.Contains('SingleChildScrollView(') -or
      -not $design.Contains('MoolMetrics.minimumTapTarget') -or
      -not $design.Contains('scrollDirection: Axis.horizontal') -or
      -not $design.Contains('mool-main-rail-overflow-cue') -or
      -not $design.Contains('More MoolSocial options. Swipe horizontally to explore all')) {
    $blockers.Add('shared outcome dock has no readable persistent overflow rail contract')
  }
  if ($blockers.Count -gt 0) {
    throw ('Global Mool navigation is not implemented: ' + ($blockers -join '; ') + '.')
  }
}

Write-Output "Global Mool navigation contract passed: implementedRequired=$RequireImplemented; cases=22; children=9; home=first_class; rootRail=persistent."
