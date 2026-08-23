[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

$ticketPath = Join-Path $root 'config\uaw-personal-mvp-global-subaction-professional-design-system-fix1-c16-ticket.json'
$scopePath = Join-Path $root 'config\mvp-scope-gate-state.json'
$bookPath = Join-Path $root 'apps\mobile\lib\features\book\widgets\book_widgets.dart'
$doctorPath = Join-Path $root 'apps\mobile\lib\features\book\screens\doctor_screens.dart'
$salonPath = Join-Path $root 'apps\mobile\lib\features\book\screens\salon_screens.dart'
$testPath = Join-Path $root 'apps\mobile\test\uaw_personal_mvp_book_subaction_professional_conformance_c16f_test.dart'
$assessmentPath = Join-Path $root 'docs\quality\UAW-PERSONAL-MVP-BOOK-SUBACTION-PROFESSIONAL-CONFORMANCE-FIX1-C16F-PRESELECTION-ASSESSMENT-20260808.md'

foreach ($path in @($ticketPath, $scopePath, $bookPath, $doctorPath, $salonPath, $testPath, $assessmentPath)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "C16F required owner is missing: $path"
  }
}

$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$expected = 'UAW-PERSONAL-MVP-BOOK-SUBACTION-PROFESSIONAL-CONFORMANCE-FIX1-C16F'
$sequence = @($ticket.implementationSequence)
$expectedIndex = [Array]::IndexOf($sequence, $expected)
$current = [string]$scope.ticket.id
$currentIndex = [Array]::IndexOf($sequence, $current)
if ($expectedIndex -lt 0 -or
    $currentIndex -lt $expectedIndex -or
    [string]$scope.preTicketSelectionCheckpoint.currentTicketId -cne $current -or
    [string]$scope.state -cne 'ticket_disclosed_and_authorized') {
  throw 'C16F MVP selection/disclosure gate is not active or has not been passed sequentially.'
}
if ([bool]$scope.execution.buildAuthorized -or
    [bool]$scope.execution.deviceInstallAuthorized -or
    [bool]$scope.execution.backendWriteAuthorized -or
    [bool]$scope.execution.referenceWriteAuthorized -or
    [bool]$scope.execution.externalServiceWriteAuthorized) {
  throw 'C16F host gate refuses build, install, backend, reference or external write authority.'
}

$book = Get-Content -Raw -LiteralPath $bookPath
$doctor = Get-Content -Raw -LiteralPath $doctorPath
$salon = Get-Content -Raw -LiteralPath $salonPath
$test = Get-Content -Raw -LiteralPath $testPath
$blockers = [Collections.Generic.List[string]]::new()

foreach ($token in @(
  'localNavigation: MoolLocalNavigationRail(',
  "key: const Key('book-local-navigation')",
  "familyId: 'book'",
  "keyName: 'book-local-doctor'",
  "label: 'Doctor'",
  "openLocal('/app/book/doctor')",
  "keyName: 'book-local-salon'",
  "label: 'Salon'",
  "openLocal('/app/book/salon')",
  "activeSubAction == 'doctor'",
  "activeSubAction == 'salon'"
)) {
  if (-not $book.Contains($token)) { $blockers.Add("Book shared owner mapping is missing: $token") }
}

$mappingStart = $book.IndexOf('localNavigation: MoolLocalNavigationRail(')
$mappingEnd = $book.IndexOf('onOpenMool:', $mappingStart)
if ($mappingStart -lt 0 -or $mappingEnd -le $mappingStart) {
  $blockers.Add('Book shared action-mapping bounds are invalid')
} else {
  $mapping = $book.Substring($mappingStart, $mappingEnd - $mappingStart)
  foreach ($forbidden in @('SingleChildScrollView(', 'ScrollController(', 'Expanded(', 'distributeEvenly')) {
    if ($mapping.Contains($forbidden)) { $blockers.Add("Book action mapping retains forbidden lane state: $forbidden") }
  }
}

foreach ($ownerToken in @(
  'class BookPageScaffold extends StatelessWidget',
  'final BookSession session;',
  'context.push(route);',
  'context.pop();',
  'context.go(fallbackBackRoute);',
  'class DoctorBookingScreen extends StatelessWidget',
  'children: DoctorCare.values',
  'key: Key(''doctor-care-${care.name}'')',
  "context.go('/app/book/doctor/details')",
  'class SalonBookingScreen extends StatelessWidget',
  'key: Key(''salon-service-${service.toLowerCase()}'')'
)) {
  if (-not ($book.Contains($ownerToken) -or $doctor.Contains($ownerToken) -or $salon.Contains($ownerToken))) {
    $blockers.Add("Book route/content owner changed or disappeared: $ownerToken")
  }
}

foreach ($token in @(
  'Book two-action family is compact, shared, one tap and Back continuous',
  'Book shared selection settles immediately under reduced motion',
  'isA<MoolLocalNavigationRail>()',
  'closeTo(180, .01)',
  'find.byType(Scrollable)',
  'find.byType(Expanded)',
  'greaterThanOrEqualTo(44)',
  "expect(node.label, 'Doctor, current')",
  "expect(node.label, 'Open Salon')",
  "find.byKey(const Key('salon-service-haircut'))",
  'tester.binding.handlePopRoute()',
  "find.byKey(const Key('doctor-care-clinic')).hitTestable()",
  'expect(selection.duration, Duration.zero)'
)) {
  if (-not $test.Contains($token)) { $blockers.Add("C16F focused coverage is missing: $token") }
}

if ($blockers.Count -gt 0) {
  throw ('C16F Book professional conformance is not implemented: ' + ($blockers -join '; ') + '.')
}

Write-Output 'C16F Book professional conformance passed: actions=Doctor,Salon; sharedOwner=1; compactCluster=180px; horizontalLane=absent; routeBackContent=preserved; target=44px; reducedMotion=immediate; buildInstall=closed.'
