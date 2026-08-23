[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

$ticketPath = Join-Path $root 'config\uaw-personal-mvp-book-doctor-salon-home-fix7-c24e-ticket.json'
$scopePath = Join-Path $root 'config\mvp-scope-gate-state.json'
$doctorPath = Join-Path $root 'apps\mobile\lib\features\book\screens\doctor_screens.dart'
$salonPath = Join-Path $root 'apps\mobile\lib\features\book\screens\salon_screens.dart'
$sessionPath = Join-Path $root 'apps\mobile\lib\features\book\book_session.dart'
$serviceHomePath = Join-Path $root 'apps\mobile\lib\core\design\mool_service_home.dart'
$testPath = Join-Path $root 'apps\mobile\test\ui_v2\book\book_doctor_salon_home_c24e_test.dart'
$doctorCapturePath = Join-Path $root 'apps\mobile\test\ui_v2\book\candidate_captures\book-doctor-home-c24e-oppo-360x800.png'
$salonCapturePath = Join-Path $root 'apps\mobile\test\ui_v2\book\candidate_captures\book-salon-home-c24e-oppo-360x800.png'

foreach ($path in @($ticketPath, $scopePath, $doctorPath, $salonPath, $sessionPath, $serviceHomePath, $testPath, $doctorCapturePath, $salonCapturePath)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "C24E required owner or evidence is missing: $path"
  }
}

$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$expected = 'UAW-PERSONAL-MVP-BOOK-DOCTOR-SALON-HOME-FIX7-C24E'
$validStates = @('selected_runtime_and_test_execution_open', 'complete_host_qualified_build_install_closed')
if ([int]$ticket.schemaVersion -ne 1 -or
    [string]$ticket.ticketId -cne $expected -or
    [string]$ticket.classification -cne 'mvp_required' -or
    [string]$ticket.state -cnotin $validStates) {
  throw 'C24E ticket identity, state or classification is invalid.'
}
if ([string]$ticket.state -ceq 'selected_runtime_and_test_execution_open') {
  if ([string]$scope.ticket.id -cne $expected -or
      [string]$scope.preTicketSelectionCheckpoint.currentTicketId -cne $expected -or
      [string]$scope.state -cne 'ticket_disclosed_and_authorized' -or
      -not [bool]$scope.execution.runtimeWriteAuthorized) {
    throw 'C24E MVP selection/disclosure/runtime gate is not active.'
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
  throw 'C24E host gate refuses build, install, backend and external authority.'
}

$doctor = Get-Content -Raw -LiteralPath $doctorPath
$salon = Get-Content -Raw -LiteralPath $salonPath
$session = Get-Content -Raw -LiteralPath $sessionPath
$serviceHome = Get-Content -Raw -LiteralPath $serviceHomePath
$test = Get-Content -Raw -LiteralPath $testPath
$blockers = [Collections.Generic.List[string]]::new()

foreach ($token in @(
  "key: const Key('doctor-discovery-home')",
  "fieldKey: const Key('doctor-search')",
  "key: Key('doctor-search-empty')",
  "key: const Key('doctor-top-provider')",
  "key: const Key('doctor-ask-clinic')",
  "key: const Key('book-doctor')",
  "title: 'How would you like care?'",
  "title: 'Specialties'",
  "'Available today'",
  "label: 'Registration verified'",
  "label: '₹300'",
  "label: 'Approx. 12 min wait'",
  'MoolServiceSearchField(',
  'MoolServiceSectionHeader(',
  'MoolServiceChoice(',
  'MoolServiceCard(',
  'MoolServicePrimaryButton('
)) {
  if (-not $doctor.Contains($token)) { $blockers.Add("Doctor discovery home is missing: $token") }
}

foreach ($token in @(
  "key: const Key('salon-discovery-home')",
  "fieldKey: const Key('salon-search')",
  "key: Key('salon-search-empty')",
  "key: const Key('salon-top-provider')",
  "key: const Key('salon-ask-provider')",
  "key: const Key('review-salon-slot')",
  "title: 'Services'",
  "title: 'Where should it happen?'",
  "title: 'Available today'",
  "label: 'Shop and photos verified'",
  "label: 'Free cancel until 5:10 PM'",
  'session.salonAmount',
  'MoolServiceSearchField(',
  'MoolServiceChoice(',
  'MoolServiceCard(',
  'MoolServicePrimaryButton('
)) {
  if (-not $salon.Contains($token)) { $blockers.Add("Salon discovery home is missing: $token") }
}

foreach ($forbidden in @(
  "title: 'Medicine'",
  "Text('Medicine')",
  "title: 'Get It Done'",
  "Text('Get It Done')",
  'scrollDirection: Axis.horizontal',
  'PageView(',
  'CarouselView('
)) {
  if ($doctor.Contains($forbidden) -or $salon.Contains($forbidden)) {
    $blockers.Add("Doctor/Salon retains forbidden scope or horizontal presentation: $forbidden")
  }
}

foreach ($token in @(
  "'Facial' => 499",
  "'Haircut' => 199",
  'void chooseDoctorCare(',
  'void chooseDoctorNeed(',
  'void chooseSalonService(',
  'void chooseSalonMode('
)) {
  if (-not $session.Contains($token)) { $blockers.Add("Retained Book truth owner is missing: $token") }
}

foreach ($token in @(
  'static const double searchHeight = 52',
  'static const double primaryActionHeight = 48',
  "fontFamily: 'Inter'",
  'Flexible(',
  'softWrap: true'
)) {
  if (-not $serviceHome.Contains($token)) { $blockers.Add("Shared service-home accessibility owner is missing: $token") }
}

foreach ($token in @(
  'Size(320, 568)',
  'Size(390, 844)',
  'Size(430, 932)',
  '1.4',
  'greaterThanOrEqualTo(44)',
  'greaterThanOrEqualTo(MoolServiceHomeTokens.searchHeight)',
  'hasAction(SemanticsAction.tap)',
  "contains('₹300')",
  "contains('₹499')",
  "find.text('Medicine'), findsNothing",
  "find.text('Get It Done'), findsNothing",
  "find.byKey(const Key('mool-home-launcher'))",
  'Duration.zero'
)) {
  if (-not $test.Contains($token)) { $blockers.Add("C24E focused coverage is missing: $token") }
}

foreach ($capturePath in @($doctorCapturePath, $salonCapturePath)) {
  if ((Get-Item -LiteralPath $capturePath).Length -le 0) {
    $blockers.Add("C24E capture is empty: $capturePath")
  }
}

if ($blockers.Count -gt 0) {
  throw ('C24E Doctor/Salon home is not qualified: ' + ($blockers -join '; ') + '.')
}

Write-Output 'C24E Doctor/Salon gate passed: search=2; verticalDiscovery=2; choices=care,specialty,service,mode; providerTruth=verification,availability,price,wait,cancellation; directBooking=2; widths=320,390,430; textScale=1.4; targets=44-52px; captures=2; Medicine=Buy-only; GetItDone=postponed; buildInstall=closed.'
