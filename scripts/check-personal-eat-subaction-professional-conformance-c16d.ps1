[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

$ticketPath = Join-Path $root 'config\uaw-personal-mvp-global-subaction-professional-design-system-fix1-c16-ticket.json'
$scopePath = Join-Path $root 'config\mvp-scope-gate-state.json'
$eatPath = Join-Path $root 'apps\mobile\lib\features\eat\widgets\eat_widgets.dart'
$tablePath = Join-Path $root 'apps\mobile\lib\features\eat\screens\eat_table_screen.dart'
$testPath = Join-Path $root 'apps\mobile\test\uaw_personal_mvp_eat_subaction_professional_conformance_c16d_test.dart'
$assessmentPath = Join-Path $root 'docs\quality\UAW-PERSONAL-MVP-EAT-SUBACTION-PROFESSIONAL-CONFORMANCE-FIX1-C16D-PRESELECTION-ASSESSMENT-20260808.md'

foreach ($path in @($ticketPath, $scopePath, $eatPath, $tablePath, $testPath, $assessmentPath)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "C16D required owner is missing: $path"
  }
}

$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$expected = 'UAW-PERSONAL-MVP-EAT-SUBACTION-PROFESSIONAL-CONFORMANCE-FIX1-C16D'
$sequence = @($ticket.implementationSequence)
$expectedIndex = [Array]::IndexOf($sequence, $expected)
$current = [string]$scope.ticket.id
$currentIndex = [Array]::IndexOf($sequence, $current)
if ($expectedIndex -lt 0 -or
    $currentIndex -lt $expectedIndex -or
    [string]$scope.preTicketSelectionCheckpoint.currentTicketId -cne $current -or
    [string]$scope.state -cne 'ticket_disclosed_and_authorized') {
  throw 'C16D MVP selection/disclosure gate is not active or has not been passed sequentially.'
}
if ([bool]$scope.execution.buildAuthorized -or
    [bool]$scope.execution.deviceInstallAuthorized -or
    [bool]$scope.execution.backendWriteAuthorized -or
    [bool]$scope.execution.referenceWriteAuthorized -or
    [bool]$scope.execution.externalServiceWriteAuthorized) {
  throw 'C16D host gate refuses build, install, backend, reference or external write authority.'
}

$eat = Get-Content -Raw -LiteralPath $eatPath
$table = Get-Content -Raw -LiteralPath $tablePath
$test = Get-Content -Raw -LiteralPath $testPath
$blockers = [Collections.Generic.List[string]]::new()

foreach ($token in @(
  'localNavigation: MoolLocalNavigationRail(',
  "key: const Key('eat-local-navigation')",
  "familyId: 'eat'",
  "keyName: 'eat-local-order'",
  "label: 'Order Food'",
  "keyName: 'eat-local-table'",
  "label: 'Book Table'",
  "openLocal('/app/eat/home')",
  "openLocal('/app/eat/table')",
  "activeLocalAction == 'order'",
  "activeLocalAction == 'table'"
)) {
  if (-not $eat.Contains($token)) { $blockers.Add("Eat shared owner mapping is missing: $token") }
}

$mappingStart = $eat.IndexOf('localNavigation: MoolLocalNavigationRail(')
$mappingEnd = $eat.IndexOf('onOpenMool:', $mappingStart)
if ($mappingStart -lt 0 -or $mappingEnd -le $mappingStart) {
  $blockers.Add('Eat shared action-mapping bounds are invalid')
} else {
  $mapping = $eat.Substring($mappingStart, $mappingEnd - $mappingStart)
  foreach ($forbidden in @('SingleChildScrollView(', 'ScrollController(', 'Expanded(', 'distributeEvenly', 'eat-local-tiffin')) {
    if ($mapping.Contains($forbidden)) { $blockers.Add("Eat action mapping retains forbidden lane or filler state: $forbidden") }
  }
}

foreach ($ownerToken in @(
  'class EatPageScaffold extends StatelessWidget',
  'final EatSession session;',
  'context.push(route);',
  'context.pop();',
  'context.go(fallbackBackRoute);',
  'Expanded(child: body)'
)) {
  if (-not $eat.Contains($ownerToken)) { $blockers.Add("Eat route/content owner changed or disappeared: $ownerToken") }
}

foreach ($adaptiveToken in @(
  'final restaurantCardHeight =',
  'MediaQuery.textScalerOf(context).scale(14)',
  '.clamp(124.0, 180.0)',
  "key: const Key('eat-table-restaurant-lane')",
  'height: restaurantCardHeight'
)) {
  if (-not $table.Contains($adaptiveToken)) { $blockers.Add("Eat large-text table adaptation is missing: $adaptiveToken") }
}

foreach ($token in @(
  'Eat two-action family is compact, shared, one tap and Back continuous',
  'Eat shared selection settles immediately under reduced motion',
  'isA<MoolLocalNavigationRail>()',
  'closeTo(180, .01)',
  'find.byType(Scrollable)',
  'find.byType(Expanded)',
  'greaterThanOrEqualTo(44)',
  "expect(node.label, 'Order Food, current')",
  "expect(node.label, 'Open Book Table')",
  "find.byKey(const Key('eat-table-screen'))",
  "find.byKey(const Key('eat-home-screen'))",
  "find.byKey(const Key('eat-home-search')).hitTestable()",
  'tester.binding.handlePopRoute()',
  'expect(selection.duration, Duration.zero)'
)) {
  if (-not $test.Contains($token)) { $blockers.Add("C16D focused coverage is missing: $token") }
}

if ($blockers.Count -gt 0) {
  throw ('C16D Eat professional conformance is not implemented: ' + ($blockers -join '; ') + '.')
}

Write-Output 'C16D Eat professional conformance passed: actions=Order Food,Book Table; sharedOwner=1; compactCluster=180px; horizontalLane=absent; routeBackContent=preserved; target=44px; reducedMotion=immediate; buildInstall=closed.'
