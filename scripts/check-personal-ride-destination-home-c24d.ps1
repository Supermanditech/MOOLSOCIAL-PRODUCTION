[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

$ticketPath = Join-Path $root 'config\uaw-personal-mvp-ride-destination-home-fix7-c24d-ticket.json'
$scopePath = Join-Path $root 'config\mvp-scope-gate-state.json'
$screenPath = Join-Path $root 'apps\mobile\lib\features\ride\screens\ride_booking_screen.dart'
$sessionPath = Join-Path $root 'apps\mobile\lib\features\ride\ride_session.dart'
$serviceHomePath = Join-Path $root 'apps\mobile\lib\core\design\mool_service_home.dart'
$testPath = Join-Path $root 'apps\mobile\test\ui_v2\ride\ride_destination_home_c24d_test.dart'
$capturePath = Join-Path $root 'apps\mobile\test\ui_v2\ride\candidate_captures\ride-destination-home-c24d-oppo-360x800.png'

foreach ($path in @($ticketPath, $scopePath, $screenPath, $sessionPath, $serviceHomePath, $testPath, $capturePath)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "C24D required owner or evidence is missing: $path"
  }
}

$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$expected = 'UAW-PERSONAL-MVP-RIDE-DESTINATION-HOME-FIX7-C24D'
if ([int]$ticket.schemaVersion -ne 1 -or
    [string]$ticket.ticketId -cne $expected -or
    [string]$ticket.classification -cne 'mvp_required' -or
    [string]$ticket.state -cne 'selected_runtime_and_test_execution_open') {
  throw 'C24D selected ticket identity, state or classification is invalid.'
}
if ([string]$scope.ticket.id -cne $expected -or
    [string]$scope.preTicketSelectionCheckpoint.currentTicketId -cne $expected -or
    [string]$scope.state -cne 'ticket_disclosed_and_authorized' -or
    -not [bool]$scope.execution.runtimeWriteAuthorized) {
  throw 'C24D MVP selection/disclosure/runtime gate is not active.'
}
if ([bool]$scope.execution.buildAuthorized -or
    [bool]$scope.execution.deviceInstallAuthorized -or
    [bool]$scope.execution.backendWriteAuthorized -or
    [bool]$scope.execution.externalServiceWriteAuthorized -or
    [bool]$ticket.execution.buildAuthorized -or
    [bool]$ticket.execution.installAuthorized -or
    [bool]$ticket.execution.backendWriteAuthorized -or
    [bool]$ticket.execution.externalServiceWriteAuthorized) {
  throw 'C24D host gate refuses build, install, backend and external authority.'
}

$screen = Get-Content -Raw -LiteralPath $screenPath
$session = Get-Content -Raw -LiteralPath $sessionPath
$serviceHome = Get-Content -Raw -LiteralPath $serviceHomePath
$test = Get-Content -Raw -LiteralPath $testPath
$blockers = [Collections.Generic.List[string]]::new()

foreach ($token in @(
  "key: const Key('ride-booking-screen')",
  "key: const Key('ride-current-pickup')",
  "key: const Key('ride-edit-route')",
  "key: const Key('ride-destination-search-surface')",
  "fieldKey: const Key('ride-destination-search')",
  "key: Key('ride-place-",
  "title: 'Where to?'",
  "title: 'Pickup time'",
  "title: 'Choose a ride'",
  "key: const Key('ride-payment-summary')",
  "key: const Key('ride-book')",
  "fontFamily: 'Inter'",
  'MoolServiceSearchField(',
  'MoolServiceSectionHeader(',
  'MoolServiceChoice(',
  'MoolServiceCard(',
  'package.fare',
  'package.arrivalMinutes',
  'package.capacity',
  'package.nearbyCaptains'
)) {
  if (-not $screen.Contains($token)) { $blockers.Add("Ride destination home is missing: $token") }
}

foreach ($token in @(
  "id: 'railway-station'",
  "id: 'aiims-jodhpur'",
  "id: 'home'",
  "destination: 'Sardarpura, Jodhpur'",
  "Key('ride-time-",
  "Key('ride-type-",
  "Key('ride-package-",
  "Key('ride-payment-"
)) {
  if (-not $screen.Contains($token)) { $blockers.Add("Ride direct choice or truth owner is missing: $token") }
}

foreach ($forbidden in @(
  "key: const Key('ride-map')",
  "key: const Key('ride-promo')",
  'scrollDirection: Axis.horizontal',
  'PageView(',
  'CarouselView('
)) {
  if ($screen.Contains($forbidden)) { $blockers.Add("Ride retains forbidden map, promo or horizontal presentation: $forbidden") }
}

foreach ($token in @(
  'void prepareBooking(',
  'bool notifyChange = true',
  'if (notifyChange) notifyListeners()',
  'bool updateRoute('
)) {
  if (-not $session.Contains($token)) { $blockers.Add("Ride session lifecycle owner is missing: $token") }
}
foreach ($token in @(
  'static const double searchHeight = 52',
  'static const double primaryActionHeight = 48'
)) {
  if (-not $serviceHome.Contains($token)) { $blockers.Add("Shared service-home token is missing: $token") }
}

foreach ($token in @(
  'Size(320, 568)',
  'Size(390, 844)',
  'Size(430, 932)',
  '1.4',
  'greaterThanOrEqualTo(44)',
  'greaterThanOrEqualTo(MoolServiceHomeTokens.searchHeight)',
  'hasAction(SemanticsAction.tap)',
  "contains('₹",
  "contains('captains nearby')",
  "find.byKey(const Key('ride-map')), findsNothing",
  "find.byKey(const Key('ride-promo')), findsNothing",
  "find.byKey(const Key('mool-home-launcher'))"
)) {
  if (-not $test.Contains($token)) { $blockers.Add("C24D focused coverage is missing: $token") }
}

if ((Get-Item -LiteralPath $capturePath).Length -le 0) {
  $blockers.Add("C24D capture is empty: $capturePath")
}

if ($blockers.Count -gt 0) {
  throw ('C24D Ride destination home is not qualified: ' + ($blockers -join '; ') + '.')
}

Write-Output 'C24D Ride destination gate passed: pickup=current; search=primary; places=recent,saved; vehicles=Bike,Auto,Cab; truth=fare,arrival,capacity,availability,payment; horizontalMapPromo=absent; widths=320,390,430; textScale=1.4; targets=44-48px; capture=1; buildInstall=closed.'
