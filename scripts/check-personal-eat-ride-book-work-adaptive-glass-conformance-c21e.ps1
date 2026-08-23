[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

$predecessorGate = Join-Path $root 'scripts\check-personal-buy-commerce-glass-conformance-c21d.ps1'
$parentPath = Join-Path $root 'config\uaw-personal-mvp-global-subaction-optical-liquid-glass-recovery-fix4-c21-ticket.json'
$ticketPath = Join-Path $root 'config\uaw-personal-mvp-eat-ride-book-work-adaptive-glass-conformance-fix4-c21e-ticket.json'
$contractPath = Join-Path $root 'config\mvp-personal-subaction-optical-liquid-glass-regression-c21.json'
$scopePath = Join-Path $root 'config\mvp-scope-gate-state.json'
$matrixTestPath = Join-Path $root 'apps\mobile\test\core\design\mool_remaining_family_clear_glass_conformance_c17d_test.dart'
$sourcePaths = @{
  eat = Join-Path $root 'apps\mobile\lib\features\eat\widgets\eat_widgets.dart'
  ride = Join-Path $root 'apps\mobile\lib\features\ride\widgets\ride_widgets.dart'
  book = Join-Path $root 'apps\mobile\lib\features\book\widgets\book_widgets.dart'
  work = Join-Path $root 'apps\mobile\lib\features\work\widgets\work_widgets.dart'
}
$continuityTests = @(
  'apps\mobile\test\uaw_personal_mvp_eat_subaction_professional_conformance_c16d_test.dart',
  'apps\mobile\test\uaw_personal_mvp_ride_subaction_professional_conformance_c16e_test.dart',
  'apps\mobile\test\uaw_personal_mvp_book_subaction_professional_conformance_c16f_test.dart',
  'apps\mobile\test\uaw_personal_mvp_work_subaction_professional_conformance_c16g_test.dart'
)

foreach ($path in @($predecessorGate, $parentPath, $ticketPath, $contractPath, $scopePath, $matrixTestPath) + $sourcePaths.Values + @($continuityTests | ForEach-Object { Join-Path $root $_ })) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "C21E required owner is missing: $path" }
}
& $predecessorGate -RepositoryRoot $root

$parent = Get-Content -Raw -LiteralPath $parentPath | ConvertFrom-Json
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$contract = Get-Content -Raw -LiteralPath $contractPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$expected = 'UAW-PERSONAL-MVP-EAT-RIDE-BOOK-WORK-ADAPTIVE-GLASS-CONFORMANCE-FIX4-C21E'
$sequence = @($parent.implementationSequence)
$expectedIndex = [Array]::IndexOf($sequence, $expected)
$current = [string]$scope.ticket.id
$currentIndex = [Array]::IndexOf($sequence, $current)
if ([int]$ticket.schemaVersion -ne 1 -or [string]$ticket.ticketId -cne $expected -or
    [string]$ticket.parentTicket -cne [string]$parent.ticketId -or
    [string]$ticket.classification -cne 'mvp_required' -or
    $expectedIndex -lt 0 -or $currentIndex -lt $expectedIndex -or
    [string]$scope.preTicketSelectionCheckpoint.currentTicketId -cne $current -or
    [string]$scope.state -cne 'ticket_disclosed_and_authorized') {
  throw 'C21E ticket identity, sequence or scope disclosure is invalid.'
}
if (-not [bool]$ticket.reuseInventory.complete -or -not [bool]$ticket.reuseInventory.duplicateSearchComplete -or
    @($ticket.reuseInventory.newScreens).Count -ne 0 -or @($ticket.reuseInventory.newRoutes).Count -ne 0 -or
    @($ticket.reuseInventory.newBackendOwners).Count -ne 0 -or @($ticket.reuseInventory.newSubactions).Count -ne 0 -or
    [bool]$scope.execution.buildAuthorized -or [bool]$scope.execution.deviceInstallAuthorized -or
    [bool]$scope.execution.backendWriteAuthorized -or [bool]$scope.execution.externalServiceWriteAuthorized) {
  throw 'C21E reuse or execution boundary has been weakened.'
}

$rules = $contract.visualRules
if ([string]$contract.state -notlike 'c21[e-h]*' -or
    [string]$contract.familyQualification.eat -cne 'c21e_two_action_adaptive_and_content_reachability_passed' -or
    [string]$contract.familyQualification.ride -cne 'c21e_three_action_adaptive_and_content_reachability_passed' -or
    [string]$contract.familyQualification.book -cne 'c21e_two_action_adaptive_and_content_reachability_passed' -or
    [string]$contract.familyQualification.work -cne 'c21e_two_action_adaptive_and_content_reachability_passed' -or
    [double]$rules.clusterWidthsAt320.twoActions -ne 200 -or
    [double]$rules.clusterWidthsAt320.threeActions -ne 268 -or
    [double]$rules.itemGap -ne 8 -or [double]$rules.controlHeight -ne 48 -or
    [bool]$rules.horizontalScrollAllowed -or [bool]$rules.distributedSparseCellsAllowed -or
    [bool]$rules.fillerActionAllowed -or [bool]$contract.buildAuthorized -or [bool]$contract.installAuthorized) {
  throw 'C21E adaptive family regression contract has drifted.'
}

$expectedActions = @{
  eat = @("id: 'order'", "label: 'Order Food'", "id: 'table'", "label: 'Book Table'")
  ride = @('for (final type in RideType.values)', 'RideType.bike', 'RideType.auto', 'RideType.cab')
  book = @("id: 'doctor'", "label: 'Doctor'", "id: 'salon'", "label: 'Salon'")
  work = @("id: 'earn'", "label: 'Earn Today'", "id: 'workspace'", "label: 'Workspace'")
}
$blockers = [Collections.Generic.List[string]]::new()
foreach ($family in @('eat', 'ride', 'book', 'work')) {
  $source = Get-Content -Raw -LiteralPath $sourcePaths.$family
  foreach ($token in @(
    "familyId: '$family'",
    'surfaceTone: MoolLocalNavigationSurfaceTone.light',
    'MoolLocalNavigationRail('
  ) + $expectedActions.$family) {
    if (-not $source.Contains($token)) { $blockers.Add("C21E $family owner is missing: $token") }
  }
  $navStart = $source.IndexOf('localNavigation: MoolLocalNavigationRail')
  $navEnd = $source.IndexOf('onOpenMool:', $navStart)
  if ($navStart -lt 0 -or $navEnd -le $navStart) {
    $blockers.Add("C21E $family local-navigation bounds are invalid")
  } else {
    $nav = $source.Substring($navStart, $navEnd - $navStart)
    foreach ($forbidden in @('SingleChildScrollView(', 'Expanded(', 'ListView(')) {
      if ($nav.Contains($forbidden)) { $blockers.Add("C21E $family retains a strip or sparse expansion: $forbidden") }
    }
  }
}

$matrixTest = Get-Content -Raw -LiteralPath $matrixTestPath
foreach ($token in @(
  "_FamilyCase('eat', [('order', 'Order Food'), ('table', 'Book Table')])",
  "_FamilyCase('ride', [('bike', 'Bike'), ('auto', 'Auto'), ('cab', 'Cab')])",
  "_FamilyCase('book', [('doctor', 'Doctor'), ('salon', 'Salon')])",
  "_FamilyCase('work', [('earn', 'Earn Today'), ('workspace', 'Workspace')])",
  'for (final selectedAction in family.actions)',
  'compact optical glass actions',
  'find.byType(BackdropFilter)',
  'find.byType(ColoredBox)',
  'greaterThanOrEqualTo(48)',
  'decoration.color, isNull',
  'glassGradient(',
  'specular-edge',
  'clusterWidth(412, 2), 200',
  'clusterWidth(412, 3), 268',
  'hasLength(9)'
)) {
  if (-not $matrixTest.Contains($token)) { $blockers.Add("C21E nine-state matrix coverage is missing: $token") }
}
foreach ($relative in $continuityTests) {
  $test = Get-Content -Raw -LiteralPath (Join-Path $root $relative)
  foreach ($token in @('greaterThanOrEqualTo(48)', 'hitTestable()', 'Duration.zero')) {
    if (-not $test.Contains($token)) { $blockers.Add("C21E continuity coverage is missing from ${relative}: $token") }
  }
  $navigationToken = if ($relative -like '*ride*') {
    'changes booking in place'
  } else {
    'Back continuous'
  }
  if (-not $test.Contains($navigationToken)) {
    $blockers.Add("C21E family navigation coverage is missing from ${relative}: $navigationToken")
  }
}

if ($blockers.Count -gt 0) { throw ('C21E remaining-family adaptive glass is not qualified: ' + ($blockers -join '; ') + '.') }
Write-Output 'C21E Eat/Ride/Book/Work adaptive conformance passed: families=4; outcomes=9; selectedStates=9; counts=2,3; clustersAt320=200,268px; controls=48px; gap=8px; tone=lightNeutral; fillerScrollSparseExpansion=absent; gradientSpecularDepth=true; oneTapBackContentReachability=true; reducedMotion=immediate; buildInstall=closed.'
