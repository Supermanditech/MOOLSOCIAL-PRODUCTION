[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

$ticketPath = Join-Path $root 'config\uaw-personal-mvp-global-subaction-professional-design-system-fix1-c16-ticket.json'
$scopePath = Join-Path $root 'config\mvp-scope-gate-state.json'
$ridePath = Join-Path $root 'apps\mobile\lib\features\ride\widgets\ride_widgets.dart'
$modelPath = Join-Path $root 'apps\mobile\lib\features\ride\ride_models.dart'
$bookingPath = Join-Path $root 'apps\mobile\lib\features\ride\screens\ride_booking_screen.dart'
$testPath = Join-Path $root 'apps\mobile\test\uaw_personal_mvp_ride_subaction_professional_conformance_c16e_test.dart'
$assessmentPath = Join-Path $root 'docs\quality\UAW-PERSONAL-MVP-RIDE-SUBACTION-PROFESSIONAL-CONFORMANCE-FIX1-C16E-PRESELECTION-ASSESSMENT-20260808.md'

foreach ($path in @($ticketPath, $scopePath, $ridePath, $modelPath, $bookingPath, $testPath, $assessmentPath)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "C16E required owner is missing: $path"
  }
}

$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$expected = 'UAW-PERSONAL-MVP-RIDE-SUBACTION-PROFESSIONAL-CONFORMANCE-FIX1-C16E'
$sequence = @($ticket.implementationSequence)
$expectedIndex = [Array]::IndexOf($sequence, $expected)
$current = [string]$scope.ticket.id
$currentIndex = [Array]::IndexOf($sequence, $current)
if ($expectedIndex -lt 0 -or
    $currentIndex -lt $expectedIndex -or
    [string]$scope.preTicketSelectionCheckpoint.currentTicketId -cne $current -or
    [string]$scope.state -cne 'ticket_disclosed_and_authorized') {
  throw 'C16E MVP selection/disclosure gate is not active or has not been passed sequentially.'
}
if ([bool]$scope.execution.buildAuthorized -or
    [bool]$scope.execution.deviceInstallAuthorized -or
    [bool]$scope.execution.backendWriteAuthorized -or
    [bool]$scope.execution.referenceWriteAuthorized -or
    [bool]$scope.execution.externalServiceWriteAuthorized) {
  throw 'C16E host gate refuses build, install, backend, reference or external write authority.'
}

$ride = Get-Content -Raw -LiteralPath $ridePath
$model = Get-Content -Raw -LiteralPath $modelPath
$booking = Get-Content -Raw -LiteralPath $bookingPath
$test = Get-Content -Raw -LiteralPath $testPath
$blockers = [Collections.Generic.List[string]]::new()

foreach ($token in @(
  'localNavigation: MoolLocalNavigationRail(',
  "key: const Key('ride-local-navigation')",
  "familyId: 'ride'",
  'for (final type in RideType.values)',
  'keyName: ''ride-local-${type.name}''',
  'label: type.label',
  'onPressed: activeSubAction == type.name',
  ': () => openRideType(type)',
  'session.chooseType(type)',
  'context.push(''/app/ride/book?type=${type.name}'')'
)) {
  if (-not $ride.Contains($token)) { $blockers.Add("Ride shared owner mapping is missing: $token") }
}

foreach ($token in @(
  "RideType.bike => 'Bike'",
  "RideType.auto => 'Auto'",
  "RideType.cab => 'Cab'"
)) {
  if (-not $model.Contains($token)) { $blockers.Add("Ride action meaning changed or disappeared: $token") }
}

$mappingStart = $ride.IndexOf('localNavigation: MoolLocalNavigationRail(')
$mappingEnd = $ride.IndexOf('onOpenMool:', $mappingStart)
if ($mappingStart -lt 0 -or $mappingEnd -le $mappingStart) {
  $blockers.Add('Ride shared action-mapping bounds are invalid')
} else {
  $mapping = $ride.Substring($mappingStart, $mappingEnd - $mappingStart)
  foreach ($forbidden in @('SingleChildScrollView(', 'ScrollController(', 'Expanded(', 'distributeEvenly')) {
    if ($mapping.Contains($forbidden)) { $blockers.Add("Ride action mapping retains forbidden lane state: $forbidden") }
  }
}

foreach ($ownerToken in @(
  'class RidePageScaffold extends StatelessWidget',
  'final RideSession session;',
  'session.chooseType(type);',
  'context.pop();',
  'context.go(fallbackBackRoute);',
  'class RideBookingScreen extends StatefulWidget',
  'activeLocalAction: session.selectedType.name',
  "key: const Key('ride-booking-screen')",
  'key: Key(''ride-package-${package.id}'')'
)) {
  if (-not ($ride.Contains($ownerToken) -or $booking.Contains($ownerToken))) {
    $blockers.Add("Ride route/content owner changed or disappeared: $ownerToken")
  }
}

foreach ($token in @(
  'Ride three-action family is compact, shared and changes booking in place',
  'Ride shared selection settles immediately under reduced motion',
  'isA<MoolLocalNavigationRail>()',
  'closeTo(248, .01)',
  'find.byType(Scrollable)',
  'find.byType(Expanded)',
  'greaterThanOrEqualTo(44)',
  "expect(node.label, 'Auto, current')",
  "expect(node.label, 'Open Cab')",
  'expect(ride.selectedType, RideType.cab)',
  'expect(routeAfter, routeBefore)',
  'attempt < 10 && package.evaluate().isEmpty',
  "tester.drag(content, const Offset(0, -180))",
  'expect(package.hitTestable(), findsOneWidget)',
  'expect(selection.duration, Duration.zero)'
)) {
  if (-not $test.Contains($token)) { $blockers.Add("C16E focused coverage is missing: $token") }
}

if ($blockers.Count -gt 0) {
  throw ('C16E Ride professional conformance is not implemented: ' + ($blockers -join '; ') + '.')
}

Write-Output 'C16E Ride professional conformance passed: actions=Bike,Auto,Cab; sharedOwner=1; compactCluster=248px; horizontalLane=absent; inPlaceBookingState=preserved; target=44px; reducedMotion=immediate; buildInstall=closed.'
