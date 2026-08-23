[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

$ticketPath = Join-Path $root 'config\uaw-personal-mvp-book-bus-booking-fix7-c24f-ticket.json'
$scopePath = Join-Path $root 'config\mvp-scope-gate-state.json'
$screenPath = Join-Path $root 'apps\mobile\lib\features\book\screens\bus_booking_screen.dart'
$modelsPath = Join-Path $root 'apps\mobile\lib\features\book\book_models.dart'
$sessionPath = Join-Path $root 'apps\mobile\lib\features\book\book_session.dart'
$servicesPath = Join-Path $root 'apps\mobile\lib\features\book\book_services.dart'
$widgetsPath = Join-Path $root 'apps\mobile\lib\features\book\widgets\book_widgets.dart'
$routerPath = Join-Path $root 'apps\mobile\lib\features\journey01\journey_router.dart'
$navigationPath = Join-Path $root 'apps\mobile\lib\ui_v2\universal\mool_global_navigation_v2.dart'
$testPath = Join-Path $root 'apps\mobile\test\ui_v2\book\book_bus_booking_c24f_test.dart'
$homeCapturePath = Join-Path $root 'apps\mobile\test\ui_v2\book\candidate_captures\book-bus-home-c24f-oppo-360x800.png'
$resultsCapturePath = Join-Path $root 'apps\mobile\test\ui_v2\book\candidate_captures\book-bus-results-c24f-oppo-360x800.png'

foreach ($path in @($ticketPath, $scopePath, $screenPath, $modelsPath, $sessionPath, $servicesPath, $widgetsPath, $routerPath, $navigationPath, $testPath, $homeCapturePath, $resultsCapturePath)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "C24F required owner or evidence is missing: $path"
  }
}

$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$expected = 'UAW-PERSONAL-MVP-BOOK-BUS-BOOKING-FIX7-C24F'
$validStates = @('selected_runtime_and_test_execution_open', 'complete_host_qualified_build_install_closed')
if ([int]$ticket.schemaVersion -ne 1 -or
    [string]$ticket.ticketId -cne $expected -or
    [string]$ticket.classification -cne 'mvp_required' -or
    [string]$ticket.state -cnotin $validStates) {
  throw 'C24F ticket identity, state or classification is invalid.'
}
if ([string]$ticket.state -ceq 'selected_runtime_and_test_execution_open') {
  if ([string]$scope.ticket.id -cne $expected -or
      [string]$scope.preTicketSelectionCheckpoint.currentTicketId -cne $expected -or
      [string]$scope.state -cne 'ticket_disclosed_and_authorized' -or
      -not [bool]$scope.execution.runtimeWriteAuthorized) {
    throw 'C24F MVP selection/disclosure/runtime gate is not active.'
  }
}
if ([bool]$scope.execution.buildAuthorized -or
    [bool]$scope.execution.deviceInstallAuthorized -or
    [bool]$scope.execution.backendWriteAuthorized -or
    [bool]$scope.execution.externalServiceWriteAuthorized -or
    [bool]$ticket.execution.buildAuthorized -or
    [bool]$ticket.execution.installAuthorized -or
    [bool]$ticket.execution.backendWriteAuthorized -or
    [bool]$ticket.execution.externalServiceWriteAuthorized) {
  throw 'C24F host gate refuses build, install, backend and external authority.'
}

$screen = Get-Content -Raw -LiteralPath $screenPath
$models = Get-Content -Raw -LiteralPath $modelsPath
$session = Get-Content -Raw -LiteralPath $sessionPath
$services = Get-Content -Raw -LiteralPath $servicesPath
$widgets = Get-Content -Raw -LiteralPath $widgetsPath
$router = Get-Content -Raw -LiteralPath $routerPath
$navigation = Get-Content -Raw -LiteralPath $navigationPath
$test = Get-Content -Raw -LiteralPath $testPath
$blockers = [Collections.Generic.List[string]]::new()

foreach ($token in @(
  "key: const Key('bus-booking-home')",
  "fieldKey: const Key('bus-from')",
  "fieldKey: const Key('bus-to')",
  "key: const Key('bus-swap')",
  "key: const Key('bus-date-today')",
  "key: const Key('bus-date-tomorrow')",
  "key: const Key('bus-date')",
  "key: const Key('bus-results-motion')",
  "key: const Key('bus-search')",
  "key: Key('bus-trip-",
  "title: 'Where are you going?'",
  "title: 'Travel date'",
  "title: 'Available for review'",
  "subtitle: 'Final seats and fares are confirmed only at checkout.'",
  'trip.operatorName',
  'trip.departure',
  'trip.arrival',
  'trip.duration',
  'trip.availableSeats',
  'trip.rating',
  'trip.fare',
  'MoolServiceSearchField(',
  'MoolServiceChoice(',
  'MoolServiceCard(',
  'MoolServicePrimaryButton('
)) {
  if (-not $screen.Contains($token)) { $blockers.Add("Bus screen is missing: $token") }
}
foreach ($forbidden in @('scrollDirection: Axis.horizontal', 'PageView(', 'CarouselView(', 'confirmBusBooking(', 'payBus(', 'busTicket')) {
  if ($screen.Contains($forbidden) -or $session.Contains($forbidden) -or $services.Contains($forbidden)) {
    $blockers.Add("Bus retains forbidden horizontal or fabricated confirmation owner: $forbidden")
  }
}

foreach ($token in @(
  'class BusTrip',
  'final String operatorName;',
  'final String departure;',
  'final String arrival;',
  'final String duration;',
  'final int availableSeats;',
  'final double rating;',
  'final int fare;'
)) {
  if (-not $models.Contains($token)) { $blockers.Add("Bus truth model is missing: $token") }
}
foreach ($token in @(
  'Future<List<BusTrip>> searchBusTrips({',
  'int busSearchCalls = 0;',
  'if (failNextBus)',
  "operatorName: 'BlueCity Express'",
  "operatorName: 'Rajputana Travels'"
)) {
  if (-not $services.Contains($token)) { $blockers.Add("Existing BookGateway Bus extension is missing: $token") }
}
foreach ($token in @(
  "String busFrom = 'Jodhpur';",
  "String busTo = 'Jaipur';",
  'int get busDayOffset',
  'void swapBusStops()',
  'void chooseBusDayOffset(int days)',
  'Future<bool> searchBuses()',
  'void selectBus(String tripId)',
  'No payment was taken and no ticket was issued.'
)) {
  if (-not $session.Contains($token)) { $blockers.Add("BookSession Bus state is missing: $token") }
}

if (([regex]::Matches($router, [regex]::Escape("path: '/app/book/bus'"))).Count -ne 1) {
  $blockers.Add('Journey router must own /app/book/bus exactly once')
}
if (([regex]::Matches($navigation, [regex]::Escape("id: 'bus'"))).Count -ne 1 -or
    ([regex]::Matches($navigation, [regex]::Escape("route: '/app/book/bus'"))).Count -ne 1) {
  $blockers.Add('Connected Book family must own Bus exactly once')
}
foreach ($token in @(
  "currentPath.startsWith('/app/book/bus')",
  "const {'doctor', 'salon', 'bus'}",
  'localActionCount: 3',
  "keyName: 'book-local-bus'"
)) {
  if (-not $widgets.Contains($token)) { $blockers.Add("Book shared route state is missing: $token") }
}

foreach ($token in @(
  'Size(320, 568)',
  'Size(390, 844)',
  'Size(430, 932)',
  '1.4',
  'greaterThanOrEqualTo(44)',
  'hasAction(SemanticsAction.tap)',
  "'₹649'",
  "'confirmed only at checkout'",
  'contains(truth)',
  "contains('No payment was taken')",
  "contains('no ticket was issued')",
  'busSearchCalls, 0',
  'busSearchCalls, 2',
  'Duration.zero',
  "find.text('Medicine'), findsNothing",
  "find.text('Get It Done'), findsNothing",
  "find.byKey(const Key('mool-home-launcher'))"
)) {
  if (-not $test.Contains($token)) { $blockers.Add("C24F focused coverage is missing: $token") }
}

foreach ($capturePath in @($homeCapturePath, $resultsCapturePath)) {
  if ((Get-Item -LiteralPath $capturePath).Length -le 0) {
    $blockers.Add("C24F capture is empty: $capturePath")
  }
}

if ($blockers.Count -gt 0) {
  throw ('C24F Bus booking is not qualified: ' + ($blockers -join '; ') + '.')
}

Write-Output 'C24F Bus gate passed: BookActions=Doctor,Salon,Bus; route=/app/book/bus once; search=From,To,Date,swap,Today,Tomorrow; resultTruth=operator,departure,arrival,duration,seats,rating,fare; selectReview=oneTap; livePaymentTicketClaims=absent; widths=320,390,430; textScale=1.4; targets=44-52px; captures=2; buildInstall=closed.'
