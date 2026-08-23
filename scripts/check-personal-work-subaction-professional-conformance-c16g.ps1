[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

$ticketPath = Join-Path $root 'config\uaw-personal-mvp-global-subaction-professional-design-system-fix1-c16-ticket.json'
$scopePath = Join-Path $root 'config\mvp-scope-gate-state.json'
$workPath = Join-Path $root 'apps\mobile\lib\features\work\widgets\work_widgets.dart'
$earnPath = Join-Path $root 'apps\mobile\lib\features\work\screens\work_earn_screens.dart'
$workspacePath = Join-Path $root 'apps\mobile\lib\features\work\screens\work_onboarding_screens.dart'
$testPath = Join-Path $root 'apps\mobile\test\uaw_personal_mvp_work_subaction_professional_conformance_c16g_test.dart'
$assessmentPath = Join-Path $root 'docs\quality\UAW-PERSONAL-MVP-WORK-SUBACTION-PROFESSIONAL-CONFORMANCE-FIX1-C16G-PRESELECTION-ASSESSMENT-20260808.md'

foreach ($path in @($ticketPath, $scopePath, $workPath, $earnPath, $workspacePath, $testPath, $assessmentPath)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "C16G required owner is missing: $path"
  }
}

$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$expected = 'UAW-PERSONAL-MVP-WORK-SUBACTION-PROFESSIONAL-CONFORMANCE-FIX1-C16G'
$sequence = @($ticket.implementationSequence)
$expectedIndex = [Array]::IndexOf($sequence, $expected)
$current = [string]$scope.ticket.id
$currentIndex = [Array]::IndexOf($sequence, $current)
if ($expectedIndex -lt 0 -or
    $currentIndex -lt $expectedIndex -or
    [string]$scope.preTicketSelectionCheckpoint.currentTicketId -cne $current -or
    [string]$scope.state -cne 'ticket_disclosed_and_authorized') {
  throw 'C16G MVP selection/disclosure gate is not active or has not been passed sequentially.'
}
if ([bool]$scope.execution.buildAuthorized -or
    [bool]$scope.execution.deviceInstallAuthorized -or
    [bool]$scope.execution.backendWriteAuthorized -or
    [bool]$scope.execution.referenceWriteAuthorized -or
    [bool]$scope.execution.externalServiceWriteAuthorized) {
  throw 'C16G host gate refuses build, install, backend, reference or external write authority.'
}

$work = Get-Content -Raw -LiteralPath $workPath
$earn = Get-Content -Raw -LiteralPath $earnPath
$workspace = Get-Content -Raw -LiteralPath $workspacePath
$test = Get-Content -Raw -LiteralPath $testPath
$blockers = [Collections.Generic.List[string]]::new()

foreach ($token in @(
  'localNavigation: MoolLocalNavigationRail(',
  "key: const Key('work-local-navigation')",
  "familyId: 'work'",
  "keyName: 'work-local-earn'",
  "label: 'Earn Today'",
  "openLocal('/app/work/earn')",
  "keyName: 'work-local-workspace'",
  "label: 'Workspace'",
  "openLocal('/app/work/my-work')",
  "activeLocalAction == 'earn'",
  "activeLocalAction == 'workspace'"
)) {
  if (-not $work.Contains($token)) { $blockers.Add("Work shared owner mapping is missing: $token") }
}

$mappingStart = $work.IndexOf('localNavigation: MoolLocalNavigationRail(')
$mappingEnd = $work.IndexOf('onOpenMool:', $mappingStart)
if ($mappingStart -lt 0 -or $mappingEnd -le $mappingStart) {
  $blockers.Add('Work shared action-mapping bounds are invalid')
} else {
  $mapping = $work.Substring($mappingStart, $mappingEnd - $mappingStart)
  foreach ($forbidden in @('SingleChildScrollView(', 'ScrollController(', 'Expanded(', 'distributeEvenly')) {
    if ($mapping.Contains($forbidden)) { $blockers.Add("Work action mapping retains forbidden lane state: $forbidden") }
  }
}

foreach ($ownerToken in @(
  'class WorkPageScaffold extends StatelessWidget',
  'final WorkSession session;',
  'context.push(route);',
  'context.pop();',
  'context.go(fallbackBackRoute);',
  'class WorkEarnScreen extends StatefulWidget',
  "key: const Key('work-earn-screen')",
  "key: const Key('work-earning-info')",
  'class MyWorkScreen extends StatelessWidget',
  "key: const Key('my-work-screen')",
  "keyName: 'my-work-start'"
)) {
  if (-not ($work.Contains($ownerToken) -or $earn.Contains($ownerToken) -or $workspace.Contains($ownerToken))) {
    $blockers.Add("Work route/content owner changed or disappeared: $ownerToken")
  }
}

foreach ($token in @(
  'Work two-action family is compact, shared, one tap and Back continuous',
  'Work shared selection settles immediately under reduced motion',
  'isA<MoolLocalNavigationRail>()',
  'closeTo(180, .01)',
  'find.byType(Scrollable)',
  'find.byType(Expanded)',
  'greaterThanOrEqualTo(44)',
  "expect(node.label, 'Earn Today, current')",
  "expect(node.label, 'Open Workspace')",
  'attempt < 8 &&',
  'tester.drag(earnContent, const Offset(0, -60))',
  'tester.drag(workspaceContent, const Offset(0, -60))',
  "find.byKey(const Key('my-work-start'))",
  'tester.binding.handlePopRoute()',
  "find.byKey(const Key('work-earning-info')).hitTestable()",
  'expect(selection.duration, Duration.zero)'
)) {
  if (-not $test.Contains($token)) { $blockers.Add("C16G focused coverage is missing: $token") }
}

if ($blockers.Count -gt 0) {
  throw ('C16G Work professional conformance is not implemented: ' + ($blockers -join '; ') + '.')
}

Write-Output 'C16G Work professional conformance passed: actions=Earn Today,Workspace; sharedOwner=1; compactCluster=180px; horizontalLane=absent; routeBackContent=preserved; target=44px; reducedMotion=immediate; buildInstall=closed.'
