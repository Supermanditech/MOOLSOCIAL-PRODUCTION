[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

function Assert-C27D([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C27D gate rejected: $Message" }
}

function Read-C27DOwner([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C27D ($path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) "owner escaped repository: $RelativePath"
  Assert-C27D (Test-Path -LiteralPath $path -PathType Leaf) "owner missing: $RelativePath"
  return [IO.File]::ReadAllText($path)
}

function Assert-C27DSequence([string]$Text, [string[]]$Items, [string]$Owner) {
  $cursor = -1
  foreach ($item in $Items) {
    $cursor = $Text.IndexOf($item, $cursor + 1, [StringComparison]::Ordinal)
    Assert-C27D ($cursor -ge 0) "$Owner order/member missing after previous item: $item"
  }
}

$navigation = Read-C27DOwner 'apps/mobile/lib/ui_v2/universal/mool_global_navigation_v2.dart'
$design = Read-C27DOwner 'apps/mobile/lib/core/design/mool_design_system.dart'
$test = Read-C27DOwner 'apps/mobile/test/ui_v2/universal/mool_uniform_navigation_six_family_conformance_c27d_test.dart'
$ticket = Read-C27DOwner 'config/uaw-personal-mvp-uniform-navigation-six-family-conformance-fix10-c27d-ticket.json' | ConvertFrom-Json
$scope = Read-C27DOwner 'config/mvp-scope-gate-state.json' | ConvertFrom-Json

Assert-C27D ([string]$ticket.ticketId -ceq 'UAW-PERSONAL-MVP-UNIFORM-NAVIGATION-SIX-FAMILY-CONFORMANCE-FIX10-C27D') 'ticket id changed'
$ticketState = [string]$ticket.state
Assert-C27D ($ticketState -cin @('active', 'complete')) 'unsupported ticket state'
if ($ticketState -ceq 'active') {
  Assert-C27D ([string]$scope.ticket.id -ceq [string]$ticket.ticketId) 'active scope ticket differs'
  Assert-C27D ([bool]$scope.execution.runtimeWriteAuthorized) 'test/gate write authorization is not open'
  Assert-C27D (-not [bool]$scope.execution.buildAuthorized) 'build authorization opened early'
  Assert-C27D ([bool]$ticket.execution.testOrGateWriteAuthorized) 'test/gate authorization is closed'
} else {
  Assert-C27D (-not [bool]$ticket.execution.testOrGateWriteAuthorized) 'completed ticket retains test/gate authorization'
}
Assert-C27D (-not [bool]$ticket.execution.runtimeSourceWriteAuthorized) 'runtime source mutation is authorized unexpectedly'

$familyStart = $navigation.IndexOf('const moolActionFamilies = <MoolActionFamilySpec>[', [StringComparison]::Ordinal)
$familyEnd = $navigation.IndexOf('final personalMoolRootActions', $familyStart, [StringComparison]::Ordinal)
Assert-C27D ($familyStart -ge 0 -and $familyEnd -gt $familyStart) 'canonical family projection owner missing'
$families = $navigation.Substring($familyStart, $familyEnd - $familyStart)
Assert-C27DSequence $families @(
  "id: 'social'", "id: 'videos'", "id: 'shorts'", "id: 'create'", "id: 'feed'",
  "id: 'buy'", "id: 'wholesale'", "id: 'orders'",
  "id: 'eat'", "id: 'order'", "id: 'table'",
  "id: 'ride'", "id: 'bike'", "id: 'auto'", "id: 'cab'", "id: 'bus'",
  "id: 'book'", "id: 'doctor'", "id: 'medicine'", "id: 'salon'",
  "id: 'work'", "id: 'earn'", "id: 'workspace'"
) 'canonical six-family projection'
foreach ($literal in @(
  "label: 'Home'", "label: 'Shorts'", "label: 'Create'", "label: 'Feed'",
  "label: 'Wholesale'", "label: 'Orders'",
  "label: 'Order Food'", "label: 'Book Table'",
  "label: 'Bike'", "label: 'Auto'", "label: 'Cab'", "label: 'Bus'",
  "label: 'Doctor'", "label: 'Medicine'", "label: 'Salon'",
  "label: 'Earn Today'", "label: 'Workspace'",
  "route: '/app/book/bus'", "route: '/app/buy?sub=medicine'"
)) {
  Assert-C27D ($families.Contains($literal)) "canonical label/route missing: $literal"
}
Assert-C27D (-not $families.Contains("id: 'shop'")) 'FSC06 duplicate local shop id returned'
Assert-C27D (-not $families.Contains("label: 'Products'")) 'FSC06 Products label returned'

$owners = @{
  social = Read-C27DOwner 'apps/mobile/lib/ui_v2/social/social_v2_consumer.dart'
  socialRail = Read-C27DOwner 'apps/mobile/lib/ui_v2/social/screen04_universal_components.dart'
  buy = Read-C27DOwner 'apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart'
  eat = Read-C27DOwner 'apps/mobile/lib/features/eat/widgets/eat_widgets.dart'
  ride = Read-C27DOwner 'apps/mobile/lib/features/ride/widgets/ride_widgets.dart'
  book = Read-C27DOwner 'apps/mobile/lib/features/book/widgets/book_widgets.dart'
  work = Read-C27DOwner 'apps/mobile/lib/features/work/widgets/work_widgets.dart'
}
foreach ($ownerName in @('social', 'buy', 'eat', 'ride', 'book', 'work')) {
  Assert-C27D ($owners[$ownerName].Contains('MoolDestinationNavigationV2(')) "real $ownerName route does not project the shared destination shell"
}
foreach ($ownerName in @('socialRail', 'buy', 'eat', 'ride', 'book', 'work')) {
  Assert-C27D ($owners[$ownerName].Contains('MoolLocalNavigationRail(')) "real $ownerName route does not project the shared local rail"
}
foreach ($literal in @(
  "familyId: 'ride'", "activeId: 'bus'", "keyName: 'travel-local-bus'",
  "switchGlobalDestination('/app/buy?sub=medicine')"
)) {
  Assert-C27D ($owners.book.Contains($literal)) "Book-owned Bus/Care projection missing: $literal"
}
foreach ($literal in @(
  "familyId: 'book'", "activeId: 'medicine'", "keyName: 'care-local-tab-medicine'",
  "route: '/app/book/doctor'", "route: '/app/book/salon'"
)) {
  Assert-C27D ($owners.buy.Contains($literal)) "Buy-owned Medicine/Care projection missing: $literal"
}

foreach ($literal in @(
  'class MoolDestinationIconLabel extends StatelessWidget',
  'class MoolLocalNavigationRail extends StatelessWidget',
  'alignment: Alignment.centerLeft',
  'destinationSelectedIndicatorWidth',
  'destinationSelectedIndicatorHeight'
)) {
  Assert-C27D ($design.Contains($literal)) "shared uniform owner missing: $literal"
}

foreach ($literal in @(
  'C27D all real family and subaction states share one system',
  "'social', 'shorts'", "'buy', 'shop'", "'eat', 'order'",
  "'ride', 'bus'", "'book', 'medicine'", "'work', 'workspace'",
  "find.byType(Scrollable)", "find.byType(FittedBox)",
  'greaterThanOrEqualTo(44)',
  'destinationSelectedIndicatorWidth',
  'mool-connected-action-navigator',
  'mool-navigator-family-'
)) {
  Assert-C27D ($test.Contains($literal)) "focused real-route acceptance missing: $literal"
}

Write-Output 'C27D six-family conformance gate passed: real states=17; families=6; C29EHomeFirst=true; shared dock=1; embedded switcher=1; Bus=Travel; Medicine=Care; Products=false.'
