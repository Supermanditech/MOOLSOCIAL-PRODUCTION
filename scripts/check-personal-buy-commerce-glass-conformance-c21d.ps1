[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

$predecessorGate = Join-Path $root 'scripts\check-personal-social-media-glass-conformance-c21c.ps1'
$parentPath = Join-Path $root 'config\uaw-personal-mvp-global-subaction-optical-liquid-glass-recovery-fix4-c21-ticket.json'
$ticketPath = Join-Path $root 'config\uaw-personal-mvp-buy-commerce-glass-conformance-fix4-c21d-ticket.json'
$contractPath = Join-Path $root 'config\mvp-personal-subaction-optical-liquid-glass-regression-c21.json'
$scopePath = Join-Path $root 'config\mvp-scope-gate-state.json'
$buyPath = Join-Path $root 'apps\mobile\lib\ui_v2\buy\buy_v2_screen.dart'
$testPath = Join-Path $root 'apps\mobile\test\ui_v2\buy\uaw_personal_mvp_buy_subaction_professional_conformance_c16c_test.dart'

foreach ($path in @($predecessorGate, $parentPath, $ticketPath, $contractPath, $scopePath, $buyPath, $testPath)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "C21D required owner is missing: $path" }
}
& $predecessorGate -RepositoryRoot $root

$parent = Get-Content -Raw -LiteralPath $parentPath | ConvertFrom-Json
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$contract = Get-Content -Raw -LiteralPath $contractPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$expected = 'UAW-PERSONAL-MVP-BUY-COMMERCE-GLASS-CONFORMANCE-FIX4-C21D'
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
  throw 'C21D ticket identity, sequence or scope disclosure is invalid.'
}
if (-not [bool]$ticket.reuseInventory.complete -or
    -not [bool]$ticket.reuseInventory.duplicateSearchComplete -or
    @($ticket.reuseInventory.newScreens).Count -ne 0 -or
    @($ticket.reuseInventory.newRoutes).Count -ne 0 -or
    @($ticket.reuseInventory.newBackendOwners).Count -ne 0 -or
    @($ticket.reuseInventory.newSubactions).Count -ne 0 -or
    [bool]$scope.execution.buildAuthorized -or [bool]$scope.execution.deviceInstallAuthorized -or
    [bool]$scope.execution.backendWriteAuthorized -or [bool]$scope.execution.externalServiceWriteAuthorized) {
  throw 'C21D reuse or execution boundary has been weakened.'
}

$rules = $contract.visualRules
if ([string]$contract.state -notlike 'c21[d-h]*' -or
    [string]$contract.familyQualification.buy -cne 'c21d_light_compositing_and_content_dominance_passed' -or
    [string]$rules.lightGlassTopArgb -cne 'D6FFFFFF' -or
    [string]$rules.lightGlassBottomArgb -cne 'B8FFFFFF' -or
    [double]$rules.itemGap -ne 8 -or [double]$rules.controlHeight -ne 48 -or
    -not [bool]$rules.controlledNeutralGradientRequired -or
    -not [bool]$rules.backgroundVisibleBetweenAndBehindControls -or
    [bool]$rules.fullWidthBandPanelTrapezoidOrSegmentedStripAllowed -or
    [bool]$contract.buildAuthorized -or [bool]$contract.installAuthorized) {
  throw 'C21D Buy commerce-glass regression contract has drifted.'
}

$buy = Get-Content -Raw -LiteralPath $buyPath
$test = Get-Content -Raw -LiteralPath $testPath
$blockers = [Collections.Generic.List[string]]::new()
$navStart = $buy.IndexOf('Widget _buildBuyLocalNavigation')
$navEnd = $buy.IndexOf('bool _showsMiniCart', $navStart)
if ($navStart -lt 0 -or $navEnd -le $navStart) {
  $blockers.Add('C21D Buy local-navigation owner bounds are invalid')
} else {
  $nav = $buy.Substring($navStart, $navEnd - $navStart)
  foreach ($token in @(
    "familyId: 'buy'",
    'surfaceTone: MoolLocalNavigationSurfaceTone.light',
    "id: BuyV2Destination.shop.name",
    "id: BuyV2Destination.wholesale.name",
    "id: BuyV2Destination.medicine.name",
    "id: BuyV2Destination.orders.name",
    "label: 'Shop'",
    "label: 'Wholesale'",
    "label: 'Medicine'",
    "label: 'Orders'"
  )) {
    if (-not $nav.Contains($token)) { $blockers.Add("C21D actual Buy owner is missing: $token") }
  }
  if ([regex]::Matches($nav, 'MoolLocalNavigationAction\(').Count -ne 4) {
    $blockers.Add('C21D Buy must retain exactly four actual outcomes')
  }
  foreach ($forbidden in @("label: 'Trade'", "label: 'Refill'", 'SingleChildScrollView(', 'Expanded(')) {
    if ($nav.Contains($forbidden)) { $blockers.Add("C21D Buy local owner retains a filler or strip token: $forbidden") }
  }
}

foreach ($token in @(
  'Buy four-action family is compact, shared and never a horizontal lane',
  "for (final selectedId in const [",
  "'shop'",
  "'wholesale'",
  "'medicine'",
  "'orders'",
  'MoolLocalNavigationSurfaceTone.light',
  'find.byType(BackdropFilter)',
  'find.byType(ColoredBox)',
  'greaterThanOrEqualTo(48)',
  'specular-edge',
  'decoration.color, isNull',
  'glassGradient(',
  'product.hitTestable()',
  'lessThanOrEqualTo(tester.getRect(rail).top)',
  'Buy shared selection settles immediately under reduced motion'
)) {
  if (-not $test.Contains($token)) { $blockers.Add("C21D focused coverage is missing: $token") }
}

if ($blockers.Count -gt 0) { throw ('C21D Buy commerce glass is not qualified: ' + ($blockers -join '; ') + '.') }
Write-Output 'C21D Buy commerce-glass conformance passed: outcomes=Shop,Wholesale,Medicine,Orders; filler=absent; tone=lightNeutral; destinationColourFlood=blockedByControlledLens; controls=4x48px; gap=8px; labels=13px/700; contentDominance=true; productHitSafe=true; selectedStates=4; reducedMotion=immediate; buildInstall=closed.'
