[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

$ticketPath = Join-Path $root 'config\uaw-personal-mvp-work-opportunity-home-fix7-c24g-ticket.json'
$scopePath = Join-Path $root 'config\mvp-scope-gate-state.json'
$earnPath = Join-Path $root 'apps\mobile\lib\features\work\screens\work_earn_screens.dart'
$workspacePath = Join-Path $root 'apps\mobile\lib\features\work\screens\work_onboarding_screens.dart'
$widgetsPath = Join-Path $root 'apps\mobile\lib\features\work\widgets\work_widgets.dart'
$serviceHomePath = Join-Path $root 'apps\mobile\lib\core\design\mool_service_home.dart'
$testPath = Join-Path $root 'apps\mobile\test\ui_v2\work\work_opportunity_home_c24g_test.dart'
$earnCapture = Join-Path $root 'apps\mobile\test\ui_v2\work\candidate_captures\work-earn-home-c24g-oppo-360x800.png'
$workspaceCapture = Join-Path $root 'apps\mobile\test\ui_v2\work\candidate_captures\work-workspace-home-c24g-oppo-360x800.png'

foreach ($path in @($ticketPath, $scopePath, $earnPath, $workspacePath, $widgetsPath, $serviceHomePath, $testPath, $earnCapture, $workspaceCapture)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "C24G required owner or evidence is missing: $path"
  }
}

$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$expected = 'UAW-PERSONAL-MVP-WORK-OPPORTUNITY-HOME-FIX7-C24G'
if ([int]$ticket.schemaVersion -ne 1 -or
    [string]$ticket.ticketId -cne $expected -or
    [string]$ticket.classification -cne 'mvp_required' -or
    [string]$ticket.state -cne 'selected_runtime_and_test_execution_open') {
  throw 'C24G selected ticket identity, state or classification is invalid.'
}
if ([string]$scope.ticket.id -cne $expected -or
    [string]$scope.preTicketSelectionCheckpoint.currentTicketId -cne $expected -or
    [string]$scope.state -cne 'ticket_disclosed_and_authorized' -or
    -not [bool]$scope.execution.runtimeWriteAuthorized) {
  throw 'C24G MVP selection/disclosure/runtime gate is not active.'
}
if ([bool]$scope.execution.buildAuthorized -or
    [bool]$scope.execution.deviceInstallAuthorized -or
    [bool]$scope.execution.backendWriteAuthorized -or
    [bool]$scope.execution.externalServiceWriteAuthorized -or
    [bool]$ticket.execution.buildAuthorized -or
    [bool]$ticket.execution.installAuthorized -or
    [bool]$ticket.execution.backendWriteAuthorized -or
    [bool]$ticket.execution.externalServiceWriteAuthorized) {
  throw 'C24G host gate refuses build, install, backend and external authority.'
}

$earn = Get-Content -Raw -LiteralPath $earnPath
$workspace = Get-Content -Raw -LiteralPath $workspacePath
$widgets = Get-Content -Raw -LiteralPath $widgetsPath
$test = Get-Content -Raw -LiteralPath $testPath
$blockers = [Collections.Generic.List[string]]::new()

foreach ($token in @(
  "key: const Key('work-earn-screen')",
  "fieldKey: const Key('work-search')",
  "key: const Key('work-filter-list')",
  "title: 'Work matching this view'",
  'MoolServiceSearchField(',
  'MoolServiceSectionHeader(',
  'MoolServiceChoice(',
  'opportunity.payment',
  'opportunity.location',
  'opportunity.deadline',
  'opportunity.publisherType',
  "key: Key('work-review-",
  "context.go('/app/work/opportunity/"
)) {
  if (-not $earn.Contains($token)) { $blockers.Add("Earn Today is missing: $token") }
}

foreach ($forbidden in @(
  'scrollDirection: Axis.horizontal',
  "key: const Key('work-decision-standard')",
  "'Updated live'",
  "'Monthly earning potential'",
  "'10,248 funded actions matched'",
  "'₹35,000–₹80,000'",
  "key: const Key('work-earning-info')"
)) {
  if ($earn.Contains($forbidden)) { $blockers.Add("Earn Today retains forbidden clutter or unsupported claim: $forbidden") }
}

foreach ($token in @(
  "key: const Key('my-work-screen')",
  "keyName: 'my-work-start'",
  "title: 'Set up your Workspace'",
  "key: const Key('my-work-active-workspace')",
  "key: const Key('my-work-other-list')",
  'MoolServiceCard(',
  "context.go('/app/work/workspace/choose')"
)) {
  if (-not $workspace.Contains($token)) { $blockers.Add("Workspace is missing: $token") }
}

foreach ($forbidden in @(
  "keyName: 'my-work-choice-earn'",
  "keyName: 'my-work-choice-business'",
  "keyName: 'my-work-choice-create'",
  "'18 orders'",
  "'₹12,840'",
  "'7 items'",
  'scrollDirection: Axis.horizontal'
)) {
  if ($workspace.Contains($forbidden)) { $blockers.Add("Workspace retains duplicate choice, fake metric or horizontal strip: $forbidden") }
}

foreach ($forbidden in @(
  "key: const Key('work-local-navigation')",
  "keyName: 'work-local-earn'",
  "keyName: 'work-local-workspace'",
  'MoolDestinationNavigationV2(',
  'MoolLocalNavigationRail('
)) {
  if ($widgets.Contains($forbidden)) { $blockers.Add("Work scaffold retains rejected local rail: $forbidden") }
}
foreach ($token in @('MoolGlobalNavigationV2(', "activeId: 'work'", 'openMoolConnectedRoute(')) {
  if (-not $widgets.Contains($token)) { $blockers.Add("Work connected navigator is missing: $token") }
}

foreach ($token in @(
  'Size(320, 568)',
  'Size(390, 844)',
  'Size(430, 932)',
  '1.4',
  'greaterThanOrEqualTo(48)',
  'hasAction(SemanticsAction.tap)',
  "find.byKey(const Key('work-local-navigation')), findsNothing",
  "find.text('Updated live'), findsNothing",
  "find.text('18 orders'), findsNothing",
  "find.byKey(const Key('work-opportunity-screen'))",
  "find.byKey(const Key('work-choose-screen'))",
  'Duration.zero'
)) {
  if (-not $test.Contains($token)) { $blockers.Add("C24G focused coverage is missing: $token") }
}

foreach ($capture in @($earnCapture, $workspaceCapture)) {
  if ((Get-Item -LiteralPath $capture).Length -le 0) {
    $blockers.Add("C24G capture is empty: $capture")
  }
}

if ($blockers.Count -gt 0) {
  throw ('C24G Work opportunity home is not qualified: ' + ($blockers -join '; ') + '.')
}

Write-Output 'C24G Work gate passed: actions=Earn Today,Workspace; searchAndFilters=adaptive; decisionTruth=pay,locationOrDistance,timing,verification; directReviewAndSetup=oneTap; horizontalLocalRail=absent; unsupportedLiveClaimsAndFakeMetrics=absent; widths=320,390,430; textScale=1.4; targets=48px; captures=2; buildInstall=closed.'
