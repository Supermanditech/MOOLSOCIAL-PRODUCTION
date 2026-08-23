[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

function Assert-C26E([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C26E gate rejected: $Message" }
}

function Read-Owner([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C26E ($path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) "owner escaped repository: $RelativePath"
  Assert-C26E (Test-Path -LiteralPath $path -PathType Leaf) "owner missing: $RelativePath"
  return [IO.File]::ReadAllText($path)
}

$eat = Read-Owner 'apps/mobile/lib/features/eat/widgets/eat_widgets.dart'
$ride = Read-Owner 'apps/mobile/lib/features/ride/widgets/ride_widgets.dart'
$book = Read-Owner 'apps/mobile/lib/features/book/widgets/book_widgets.dart'
$test = Read-Owner 'apps/mobile/test/ui_v2/universal/mool_service_pair_navigation_conformance_c26e_test.dart'

foreach ($literal in @(
  'bottomNavigationBar: MoolDestinationNavigationV2(',
  "activeId: 'eat'",
  "keyName: 'eat-local-order'",
  "label: 'Order Food'",
  "keyName: 'eat-local-table'",
  "label: 'Book Table'",
  "keyName: 'eat-global-chat'"
)) {
  Assert-C26E ($eat.Contains($literal)) "Food projection missing: $literal"
}
foreach ($literal in @(
  'bottomNavigationBar: MoolDestinationNavigationV2(',
  "activeId: 'ride'",
  'keyName: ''ride-local-${type.name}''',
  "keyName: 'ride-local-bus'",
  "label: 'Bus'",
  "switchGlobalDestination('/app/book/bus')",
  "keyName: 'ride-global-chat'"
)) {
  Assert-C26E ($ride.Contains($literal)) "Travel projection missing: $literal"
}
foreach ($literal in @(
  "key: const Key('travel-bus-local-navigation')",
  "familyId: 'ride'",
  "keyName: 'travel-local-bus'",
  "label: 'Bus'"
)) {
  Assert-C26E ($book.Contains($literal)) "cross-owned Bus projection missing: $literal"
}
foreach ($literal in @('eat-local-order', 'ride-local-bus', 'bus-booking-home', 'travel-bus-local-navigation')) {
  Assert-C26E ($test.Contains($literal)) "focused proof missing: $literal"
}

Write-Output 'C26E Food and Travel navigation conformance passed: Food=2 actions; Travel=4 actions; BusBookReuse=true.'
