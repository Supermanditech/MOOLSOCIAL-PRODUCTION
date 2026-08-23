[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

$predecessorGate = Join-Path $root 'scripts\check-personal-social-buy-clear-glass-conformance-c17c.ps1'
$ticketPath = Join-Path $root 'config\uaw-personal-mvp-global-subaction-clear-glass-action-controls-fix2-c17-ticket.json'
$c20ParentPath = Join-Path $root 'config\uaw-personal-mvp-global-subaction-founder-gallery-professional-recovery-fix3-c20-ticket.json'
$scopePath = Join-Path $root 'config\mvp-scope-gate-state.json'
$testPath = Join-Path $root 'apps\mobile\test\core\design\mool_remaining_family_clear_glass_conformance_c17d_test.dart'
$families = @{
  eat = @{
    path = Join-Path $root 'apps\mobile\lib\features\eat\widgets\eat_widgets.dart'
    count = 2
    tokens = @("keyName: 'eat-local-order'", "label: 'Order Food'", "keyName: 'eat-local-table'", "label: 'Book Table'")
    legacyTest = Join-Path $root 'apps\mobile\test\uaw_personal_mvp_eat_subaction_professional_conformance_c16d_test.dart'
  }
  ride = @{
    path = Join-Path $root 'apps\mobile\lib\features\ride\widgets\ride_widgets.dart'
    count = 3
    tokens = @('for (final type in RideType.values', "keyName: 'ride-local-`${type.name}'", 'label: type.label')
    legacyTest = Join-Path $root 'apps\mobile\test\uaw_personal_mvp_ride_subaction_professional_conformance_c16e_test.dart'
  }
  book = @{
    path = Join-Path $root 'apps\mobile\lib\features\book\widgets\book_widgets.dart'
    count = 2
    tokens = @("keyName: 'book-local-doctor'", "label: 'Doctor'", "keyName: 'book-local-salon'", "label: 'Salon'")
    legacyTest = Join-Path $root 'apps\mobile\test\uaw_personal_mvp_book_subaction_professional_conformance_c16f_test.dart'
  }
  work = @{
    path = Join-Path $root 'apps\mobile\lib\features\work\widgets\work_widgets.dart'
    count = 2
    tokens = @("keyName: 'work-local-earn'", "label: 'Earn Today'", "keyName: 'work-local-workspace'", "label: 'Workspace'")
    legacyTest = Join-Path $root 'apps\mobile\test\uaw_personal_mvp_work_subaction_professional_conformance_c16g_test.dart'
  }
}

foreach ($path in @($predecessorGate, $ticketPath, $scopePath, $testPath) + @($families.Values | ForEach-Object { $_.path; $_.legacyTest })) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "C17D required owner is missing: $path" }
}

$earlyScope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$earlyCurrent = [string]$earlyScope.ticket.id
if (Test-Path -LiteralPath $c20ParentPath -PathType Leaf) {
  $earlyParent = Get-Content -Raw -LiteralPath $c20ParentPath | ConvertFrom-Json
  $earlySequence = @($earlyParent.implementationSequence)
  $earlyStart = [Array]::IndexOf($earlySequence, 'UAW-PERSONAL-MVP-SHARED-NEUTRAL-BRAND-GLASS-CONTROL-FIX3-C20C')
  $earlyIndex = [Array]::IndexOf($earlySequence, $earlyCurrent)
  if ([string]$earlyParent.ticketId -ceq 'UAW-PERSONAL-MVP-GLOBAL-SUBACTION-FOUNDER-GALLERY-PROFESSIONAL-RECOVERY-FIX3-C20' -and
      $earlyStart -ge 0 -and $earlyIndex -ge $earlyStart) {
    $c20cGate = Join-Path $root 'scripts\check-personal-shared-neutral-brand-glass-control-c20c.ps1'
    if (-not (Test-Path -LiteralPath $c20cGate -PathType Leaf)) { throw 'C17D C20C successor gate is missing.' }
    & $c20cGate -RepositoryRoot $root
    Write-Output 'C17D historical Eat/Ride/Book/Work conformance passed through the exact C20C neutral brand-glass successor; buildInstall=closed.'
    return
  }
}

& $predecessorGate -RepositoryRoot $root

$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$expected = 'UAW-PERSONAL-MVP-EAT-RIDE-BOOK-WORK-CLEAR-GLASS-CONFORMANCE-FIX2-C17D'
$sequence = @($ticket.implementationSequence)
$current = [string]$scope.ticket.id
$isC18dRefresh = $current -ceq 'UAW-PERSONAL-MVP-C17-HOST-QUALIFICATION-REFRESH-AFTER-SCREEN01-LOCK-FIX1-C18D'
$isC20Successor = $false
if (Test-Path -LiteralPath $c20ParentPath -PathType Leaf) {
  $c20Parent = Get-Content -Raw -LiteralPath $c20ParentPath | ConvertFrom-Json
  $c20Sequence = @($c20Parent.implementationSequence)
  $c20Start = [Array]::IndexOf(
    $c20Sequence,
    'UAW-PERSONAL-MVP-SUBACTION-DISCLOSURE-AND-OVERFLOW-AFFORDANCE-FIX3-C20B'
  )
  $c20Current = [Array]::IndexOf($c20Sequence, $current)
  $isC20Successor =
    [string]$c20Parent.ticketId -ceq 'UAW-PERSONAL-MVP-GLOBAL-SUBACTION-FOUNDER-GALLERY-PROFESSIONAL-RECOVERY-FIX3-C20' -and
    $c20Start -ge 0 -and
    $c20Current -ge $c20Start
}
if (([Array]::IndexOf($sequence, $current) -lt [Array]::IndexOf($sequence, $expected) -and -not $isC18dRefresh -and -not $isC20Successor) -or
    [string]$scope.preTicketSelectionCheckpoint.currentTicketId -cne $current -or
    [string]$scope.state -cne 'ticket_disclosed_and_authorized') {
  throw 'C17D MVP selection and sequential disclosure gate is not active.'
}
if ([bool]$scope.execution.buildAuthorized -or [bool]$scope.execution.deviceInstallAuthorized -or
    [bool]$scope.execution.backendWriteAuthorized -or
    ([bool]$scope.execution.referenceWriteAuthorized -and -not $isC18dRefresh -and -not $isC20Successor) -or
    [bool]$scope.execution.externalServiceWriteAuthorized) {
  throw 'C17D host gate refuses build, install, backend or external authority; reference writes are limited to exact authorized successor tickets.'
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
    if (-not $source.Contains($token)) { $blockers.Add("$family conformance is missing: $token") }
  }
  foreach ($forbidden in @('SingleChildScrollView(', 'distributeEvenly: true', 'localActionCount: 4')) {
    if ($source.Contains($forbidden)) { $blockers.Add("$family retains scroll, distribution or filler: $forbidden") }
  }
  $legacy = Get-Content -Raw -LiteralPath $spec.legacyTest
  foreach ($token in @('MoolLocalNavigationTokens.clusterWidth(320', 'greaterThanOrEqualTo(48)')) {
    if (-not $legacy.Contains($token)) { $blockers.Add("$family durable journey coverage is missing successor token: $token") }
  }
  foreach ($stale in @('closeTo(180, .01)', 'closeTo(248, .01)', 'greaterThanOrEqualTo(44)')) {
    if ($legacy.Contains($stale)) { $blockers.Add("$family durable journey retains stale predecessor token: $stale") }
  }
}

$test = Get-Content -Raw -LiteralPath $testPath
foreach ($token in @(
  "_FamilyCase('eat'",
  "_FamilyCase('ride'",
  "_FamilyCase('book'",
  "_FamilyCase('work'",
  "('order', 'Order Food')",
  "('table', 'Book Table')",
  "('bike', 'Bike')",
  "('auto', 'Auto')",
  "('cab', 'Cab')",
  "('doctor', 'Doctor')",
  "('salon', 'Salon')",
  "('earn', 'Earn Today')",
  "('workspace', 'Workspace')",
  'MoolLocalNavigationTokens.clusterWidth(412, family.actions.length)',
  'find.byType(BackdropFilter)',
  'find.byType(Scrollable)',
  'find.byType(Expanded)',
  'greaterThanOrEqualTo(48)',
  'MoolLocalNavigationTokens.lightGlassFill.a',
  'hasLength(9)',
  'clusterWidth(412, 2), 212',
  'clusterWidth(412, 3), 272'
)) {
  if (-not $test.Contains($token)) { $blockers.Add("C17D focused coverage is missing: $token") }
}

if ($blockers.Count -gt 0) {
  throw ('C17D Eat/Ride/Book/Work conformance is not qualified: ' + ($blockers -join '; ') + '.')
}

Write-Output 'C17D Eat/Ride/Book/Work clear-glass conformance passed: families=4; realActions=9; compactCounts=2,3,2,2; preferredWidths=212,272; targets=48px; tone=light; filler=absent; scroll=absent; sparseExpansion=absent; realJourneys=updated; buildInstall=closed.'
