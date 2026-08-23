[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

$predecessorGate = Join-Path $root 'scripts\check-personal-social-buy-four-action-conformance-c20d.ps1'
$parentPath = Join-Path $root 'config\uaw-personal-mvp-global-subaction-founder-gallery-professional-recovery-fix3-c20-ticket.json'
$ticketPath = Join-Path $root 'config\uaw-personal-mvp-eat-ride-book-work-adaptive-conformance-fix3-c20e-ticket.json'
$regressionPath = Join-Path $root 'config\mvp-personal-subaction-professional-recovery-regression-c20.json'
$scopePath = Join-Path $root 'config\mvp-scope-gate-state.json'
$testPath = Join-Path $root 'apps\mobile\test\ui_v2\universal\uaw_personal_mvp_eat_ride_book_work_adaptive_conformance_c20e_test.dart'
$families = @{
  eat = @{
    path = Join-Path $root 'apps\mobile\lib\features\eat\widgets\eat_widgets.dart'
    count = 2
    tokens = @("keyName: 'eat-local-order'", "id: 'order'", "label: 'Order Food'", "keyName: 'eat-local-table'", "id: 'table'", "label: 'Book Table'")
    legacyTest = Join-Path $root 'apps\mobile\test\uaw_personal_mvp_eat_subaction_professional_conformance_c16d_test.dart'
  }
  ride = @{
    path = Join-Path $root 'apps\mobile\lib\features\ride\widgets\ride_widgets.dart'
    count = 3
    tokens = @('for (final type in RideType.values', "keyName: 'ride-local-`${type.name}'", 'id: type.name', 'label: type.label')
    legacyTest = Join-Path $root 'apps\mobile\test\uaw_personal_mvp_ride_subaction_professional_conformance_c16e_test.dart'
  }
  book = @{
    path = Join-Path $root 'apps\mobile\lib\features\book\widgets\book_widgets.dart'
    count = 2
    tokens = @("keyName: 'book-local-doctor'", "id: 'doctor'", "label: 'Doctor'", "keyName: 'book-local-salon'", "id: 'salon'", "label: 'Salon'")
    legacyTest = Join-Path $root 'apps\mobile\test\uaw_personal_mvp_book_subaction_professional_conformance_c16f_test.dart'
  }
  work = @{
    path = Join-Path $root 'apps\mobile\lib\features\work\widgets\work_widgets.dart'
    count = 2
    tokens = @("keyName: 'work-local-earn'", "id: 'earn'", "label: 'Earn Today'", "keyName: 'work-local-workspace'", "id: 'workspace'", "label: 'Workspace'")
    legacyTest = Join-Path $root 'apps\mobile\test\uaw_personal_mvp_work_subaction_professional_conformance_c16g_test.dart'
  }
}

foreach ($path in @($predecessorGate, $parentPath, $ticketPath, $regressionPath, $scopePath, $testPath) + @($families.Values | ForEach-Object { $_.path; $_.legacyTest })) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "C20E required owner is missing: $path"
  }
}

& $predecessorGate -RepositoryRoot $root

$parent = Get-Content -Raw -LiteralPath $parentPath | ConvertFrom-Json
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$regression = Get-Content -Raw -LiteralPath $regressionPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$expected = 'UAW-PERSONAL-MVP-EAT-RIDE-BOOK-WORK-ADAPTIVE-CONFORMANCE-FIX3-C20E'

if ([int]$ticket.schemaVersion -ne 1 -or
    [string]$ticket.ticketId -cne $expected -or
    [string]$ticket.parentTicket -cne [string]$parent.ticketId -or
    [string]$ticket.classification -cne 'mvp_required') {
  throw 'C20E ticket identity or MVP classification is invalid.'
}
if (-not [bool]$ticket.reuseInventory.complete -or
    -not [bool]$ticket.reuseInventory.duplicateSearchComplete -or
    @($ticket.reuseInventory.newScreens).Count -ne 0 -or
    @($ticket.reuseInventory.newRoutes).Count -ne 0 -or
    @($ticket.reuseInventory.newBackendOwners).Count -ne 0 -or
    @($ticket.reuseInventory.newSubactions).Count -ne 0) {
  throw 'C20E reuse, duplicate-search or zero-new-owner contract is incomplete.'
}
foreach ($family in @('eat', 'ride', 'book', 'work')) {
  if (@($ticket.reuseInventory.existingActions.$family).Count -ne [int]$families[$family].count) {
    throw "C20E existing action inventory is invalid: $family"
  }
}
if (-not [bool]$ticket.execution.referenceWriteAuthorized -or
    -not [bool]$ticket.execution.runtimeSourceWriteAuthorized -or
    -not [bool]$ticket.execution.testAndGateWriteAuthorized -or
    [bool]$ticket.execution.backendWriteAuthorized -or
    [bool]$ticket.execution.buildAuthorized -or
    [bool]$ticket.execution.installAuthorized -or
    [bool]$ticket.execution.externalServiceWriteAuthorized) {
  throw 'C20E execution authority has been weakened or expanded.'
}

$sequence = @($parent.implementationSequence)
$expectedIndex = [Array]::IndexOf($sequence, $expected)
$current = [string]$scope.ticket.id
$currentIndex = [Array]::IndexOf($sequence, $current)
if ([string]$parent.ticketId -cne 'UAW-PERSONAL-MVP-GLOBAL-SUBACTION-FOUNDER-GALLERY-PROFESSIONAL-RECOVERY-FIX3-C20' -or
    $expectedIndex -lt 0 -or $currentIndex -lt $expectedIndex -or
    [string]$scope.preTicketSelectionCheckpoint.currentTicketId -cne $current -or
    [string]$scope.state -cne 'ticket_disclosed_and_authorized') {
  throw 'C20E sequential MVP selection and disclosure gate is not active.'
}
if ([bool]$scope.execution.buildAuthorized -or
    [bool]$scope.execution.deviceInstallAuthorized -or
    [bool]$scope.execution.backendWriteAuthorized -or
    [bool]$scope.execution.externalServiceWriteAuthorized) {
  throw 'C20E host gate refuses build, install, backend and external authority.'
}

$contract = $ticket.adaptiveContract
if ((@($contract.families) -join ',') -cne 'eat,ride,book,work' -or
    [int]$contract.actionCounts.eat -ne 2 -or
    [int]$contract.actionCounts.ride -ne 3 -or
    [int]$contract.actionCounts.book -ne 2 -or
    [int]$contract.actionCounts.work -ne 2 -or
    [int]$contract.selectedStateCount -ne 9 -or
    [string]$contract.surfaceTone -cne 'light' -or
    [double]$contract.controlHeight -ne 48 -or
    [double]$contract.minimumTapTarget -ne 48 -or
    [double]$contract.controlRadius -ne 16 -or
    [double]$contract.labelFontSize -ne 13 -or
    [int]$contract.labelFontWeight -ne 700 -or
    [double]$contract.maximumNavigationTextScale -ne 1.3 -or
    [double]$contract.iconOpticalBox -ne 20 -or
    [double]$contract.minimumCompositedLabelContrast -ne 4.5 -or
    (@($contract.supportedWidths) -join ',') -cne '320,360,390,412,430' -or
    [double]$contract.preferredClusterWidthAt412.two -ne 212 -or
    [double]$contract.preferredClusterWidthAt412.three -ne 272 -or
    [double]$contract.compactClusterWidthAt320.two -ne 212 -or
    [double]$contract.compactClusterWidthAt320.three -ne 272 -or
    [bool]$contract.horizontalScrollOrPanelAllowed -or
    [bool]$contract.distributedSparseCellsAllowed -or
    [bool]$contract.blockingBandOrTrapezoidAllowed -or
    [bool]$contract.familyTintedFillAllowed -or
    [bool]$contract.fillerActionAllowed -or
    -not [bool]$contract.selectedActionInert -or
    -not [bool]$contract.availableActionOneTap -or
    [int]$contract.normalStateMotionMilliseconds -ne 160 -or
    -not [bool]$contract.reducedMotionImmediate) {
  throw 'C20E adaptive-family contract has drifted.'
}
if ([bool]$regression.installedRejectedCandidate.mustRemainInstalledUntilQualifiedSuccessor -ne $true -or
    [bool]$regression.buildAuthorized -or [bool]$regression.installAuthorized -or
    @($regression.families.eat).Count -ne 2 -or
    @($regression.families.ride).Count -ne 3 -or
    @($regression.families.book).Count -ne 2 -or
    @($regression.families.work).Count -ne 2) {
  throw 'C20E preserved installed candidate or permanent adaptive-family matrix has drifted.'
}

$blockers = [Collections.Generic.List[string]]::new()
foreach ($entry in $families.GetEnumerator()) {
  $family = $entry.Key
  $spec = $entry.Value
  $source = Get-Content -Raw -LiteralPath $spec.path
  if ([regex]::Matches($source, 'MoolLocalNavigationRail\(').Count -ne 1) {
    $blockers.Add("$family must consume exactly one shared local-navigation renderer")
  }
  foreach ($token in @(
    'MoolDestinationNavigationV2(',
    "familyId: '$family'",
    "localActionCount: $($spec.count)",
    'MoolLocalNavigationRail('
  ) + $spec.tokens) {
    if (-not $source.Contains($token)) { $blockers.Add("$family adaptive owner is missing: $token") }
  }
  foreach ($forbidden in @('SingleChildScrollView(', 'distributeEvenly: true', 'localActionCount: 4')) {
    if ($source.Contains($forbidden)) { $blockers.Add("$family retains scroll, sparse distribution or filler: $forbidden") }
  }
  $legacy = Get-Content -Raw -LiteralPath $spec.legacyTest
  foreach ($token in @(
    "MoolLocalNavigationTokens.clusterWidth(320, $($spec.count))",
    'greaterThanOrEqualTo(48)',
    'hasAction(SemanticsAction.tap)',
    'hitTestable()',
    'Duration.zero'
  )) {
    if (-not $legacy.Contains($token)) { $blockers.Add("$family real-consumer coverage is missing: $token") }
  }
}

$test = Get-Content -Raw -LiteralPath $testPath
foreach ($token in @(
  'const _widths = [320.0, 360.0, 390.0, 412.0, 430.0]',
  'const _textScales = [1.0, 1.3]',
  'adaptive inventory owns four real families and nine selected states',
  'all four families keep inert selection one-tap outcomes and immediate reduced motion',
  "_FamilySpec('eat'",
  "_FamilySpec('ride'",
  "_FamilySpec('book'",
  "_FamilySpec('work'",
  "_ActionSpec('order', 'Order Food'",
  "_ActionSpec('table', 'Book Table'",
  "_ActionSpec('bike', 'Bike'",
  "_ActionSpec('auto', 'Auto'",
  "_ActionSpec('cab', 'Cab'",
  "_ActionSpec('doctor', 'Doctor'",
  "_ActionSpec('salon', 'Salon'",
  "_ActionSpec('earn', 'Earn Today'",
  "_ActionSpec('workspace', 'Workspace'",
  'MoolLocalNavigationTokens.clusterWidth(width, family.actions.length)',
  'find.byType(Scrollable)',
  'find.byType(Expanded)',
  'find.byType(BackdropFilter)',
  'find.byType(FittedBox)',
  'greaterThanOrEqualTo(48)',
  'flagsCollection.isSelected',
  'hasAction(SemanticsAction.tap)',
  'MoolLocalNavigationTokens.glassFill(',
  'greaterThanOrEqualTo(4.5)',
  'Duration.zero'
)) {
  if (-not $test.Contains($token)) { $blockers.Add("C20E focused coverage is missing: $token") }
}

if ($blockers.Count -gt 0) {
  throw ('C20E Eat/Ride/Book/Work adaptive conformance is not qualified: ' + ($blockers -join '; ') + '.')
}

Write-Output 'C20E adaptive conformance passed: families=Eat,Ride,Book,Work; actions=2,3,2,2; selectedStates=9; widths=320,360,390,412,430; textScales=1.0,1.3; clusters=212px,272px; target=48px; label=13px/700; fillerScrollExpansion=absent; contrast>=4.5; realContentReachability=covered; reducedMotion=immediate; buildInstall=closed.'
