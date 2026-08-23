[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

$ticketPath = Join-Path $root 'config\uaw-personal-mvp-eat-discovery-home-fix7-c24c-ticket.json'
$scopePath = Join-Path $root 'config\mvp-scope-gate-state.json'
$homePath = Join-Path $root 'apps\mobile\lib\features\eat\screens\eat_home_screen.dart'
$tablePath = Join-Path $root 'apps\mobile\lib\features\eat\screens\eat_table_screen.dart'
$modelPath = Join-Path $root 'apps\mobile\lib\features\eat\eat_models.dart'
$serviceHomePath = Join-Path $root 'apps\mobile\lib\core\design\mool_service_home.dart'
$testPath = Join-Path $root 'apps\mobile\test\ui_v2\eat\eat_discovery_home_c24c_test.dart'
$orderCapture = Join-Path $root 'apps\mobile\test\ui_v2\eat\candidate_captures\eat-discovery-home-c24c-oppo-360x800.png'
$tableCapture = Join-Path $root 'apps\mobile\test\ui_v2\eat\candidate_captures\eat-book-table-c24c-oppo-360x800.png'

foreach ($path in @($ticketPath, $scopePath, $homePath, $tablePath, $modelPath, $serviceHomePath, $testPath, $orderCapture, $tableCapture)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "C24C required owner or evidence is missing: $path"
  }
}

$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$expected = 'UAW-PERSONAL-MVP-EAT-DISCOVERY-HOME-FIX7-C24C'
if ([int]$ticket.schemaVersion -ne 1 -or
    [string]$ticket.ticketId -cne $expected -or
    [string]$ticket.classification -cne 'mvp_required' -or
    [string]$ticket.state -cne 'selected_runtime_and_test_execution_open') {
  throw 'C24C selected ticket identity, state or classification is invalid.'
}
if ([string]$scope.ticket.id -cne $expected -or
    [string]$scope.preTicketSelectionCheckpoint.currentTicketId -cne $expected -or
    [string]$scope.state -cne 'ticket_disclosed_and_authorized' -or
    -not [bool]$scope.execution.runtimeWriteAuthorized) {
  throw 'C24C MVP selection/disclosure/runtime gate is not active.'
}
if ([bool]$scope.execution.buildAuthorized -or
    [bool]$scope.execution.deviceInstallAuthorized -or
    [bool]$scope.execution.backendWriteAuthorized -or
    [bool]$scope.execution.externalServiceWriteAuthorized -or
    [bool]$ticket.execution.buildAuthorized -or
    [bool]$ticket.execution.installAuthorized -or
    [bool]$ticket.execution.backendWriteAuthorized -or
    [bool]$ticket.execution.externalServiceWriteAuthorized) {
  throw 'C24C host gate refuses build, install, backend and external authority.'
}

$homeSource = Get-Content -Raw -LiteralPath $homePath
$table = Get-Content -Raw -LiteralPath $tablePath
$model = Get-Content -Raw -LiteralPath $modelPath
$serviceHome = Get-Content -Raw -LiteralPath $serviceHomePath
$test = Get-Content -Raw -LiteralPath $testPath
$blockers = [Collections.Generic.List[string]]::new()

foreach ($token in @(
  "key: const Key('eat-home-discovery-list')",
  "fieldKey: const Key('eat-home-search')",
  "key: Key('eat-home-location')",
  "key: const Key('eat-home-table')",
  "key: const Key('eat-home-cuisine-filters')",
  "title: 'Food near you'",
  'MoolServiceSearchField(',
  'MoolServiceSectionHeader(',
  'MoolServiceChoice(',
  'MoolServiceCard(',
  'restaurant.orderStartingPrice',
  'restaurant.deliveryTime',
  "context.go('/app/eat/order')",
  "context.go('/app/eat/table')"
)) {
  if (-not $homeSource.Contains($token)) { $blockers.Add("Order Food discovery is missing: $token") }
}

foreach ($forbidden in @(
  "key: const Key('eat-context-qr')",
  "key: const Key('eat-context-offers')",
  "'Tiffin'",
  'scrollDirection: Axis.horizontal',
  'Available offer',
  'Know before you confirm'
)) {
  if ($homeSource.Contains($forbidden)) { $blockers.Add("Order Food retains forbidden clutter or horizontal presentation: $forbidden") }
}

foreach ($token in @(
  "key: const Key('eat-table-discovery-list')",
  "fieldKey: const Key('eat-table-search')",
  "key: Key('eat-table-location')",
  "title: 'Available restaurants'",
  'class _TableRestaurantChoice extends StatelessWidget',
  'restaurant.status',
  'restaurant.bookingPrice',
  "key: const Key('eat-book-table')",
  'MoolServiceChoice(',
  'MoolServiceHomeTokens.primaryActionHeight'
)) {
  if (-not $table.Contains($token)) { $blockers.Add("Book Table discovery is missing: $token") }
}

foreach ($forbidden in @(
  'scrollDirection: Axis.horizontal',
  "key: const Key('eat-table-saved')",
  "key: const Key('eat-table-parking')",
  'class _BeforeYouGo extends StatelessWidget',
  "color: const Color(0xFFEDEEFF)"
)) {
  if ($table.Contains($forbidden)) { $blockers.Add("Book Table retains forbidden rail, filler or blocking fill: $forbidden") }
}

foreach ($token in @('required this.orderStartingPrice', 'required this.deliveryTime', 'final int orderStartingPrice', 'final String deliveryTime')) {
  if (-not $model.Contains($token)) { $blockers.Add("Eat restaurant truth model is missing: $token") }
}
foreach ($token in @('this.fieldKey', 'this.onChanged', 'key: fieldKey', 'onChanged: onChanged')) {
  if (-not $serviceHome.Contains($token)) { $blockers.Add("Shared service search owner is missing: $token") }
}

foreach ($token in @(
  'Size(320, 568)',
  'Size(390, 844)',
  'Size(430, 932)',
  '1.4',
  'greaterThanOrEqualTo(44)',
  'greaterThanOrEqualTo(48)',
  'hasAction(SemanticsAction.tap)',
  "find.byKey(const Key('eat-context-qr')), findsNothing",
  "find.byKey(const Key('eat-context-offers')), findsNothing",
  "find.text('Tiffin'), findsNothing",
  "find.byKey(const Key('eat-order-screen'))",
  "find.byKey(const Key('eat-table-screen'))"
)) {
  if (-not $test.Contains($token)) { $blockers.Add("C24C focused coverage is missing: $token") }
}

foreach ($capture in @($orderCapture, $tableCapture)) {
  if ((Get-Item -LiteralPath $capture).Length -le 0) { $blockers.Add("C24C capture is empty: $capture") }
}

if ($blockers.Count -gt 0) {
  throw ('C24C Eat discovery home is not qualified: ' + ($blockers -join '; ') + '.')
}

Write-Output 'C24C Eat discovery gate passed: actions=Order Food,Book Table; locationSearch=first; restaurantTruth=rating,time,distance,price,availability; horizontalRails=absent; postponedTiffin=hidden; widths=320,390,430; textScale=1.4; targets=44-48px; captures=2; buildInstall=closed.'
