[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

$predecessorGate = Join-Path $root 'scripts\check-personal-eat-ride-book-work-adaptive-glass-conformance-c21e.ps1'
$parentPath = Join-Path $root 'config\uaw-personal-mvp-global-subaction-optical-liquid-glass-recovery-fix4-c21-ticket.json'
$ticketPath = Join-Path $root 'config\uaw-personal-mvp-subaction-disclosure-selection-motion-refinement-fix4-c21f-ticket.json'
$contractPath = Join-Path $root 'config\mvp-personal-subaction-optical-liquid-glass-regression-c21.json'
$placementPath = Join-Path $root 'config\mvp-personal-subaction-reachability-promotion-zone-regression.json'
$scopePath = Join-Path $root 'config\mvp-scope-gate-state.json'
$designPath = Join-Path $root 'apps\mobile\lib\core\design\mool_design_system.dart'
$navigationPath = Join-Path $root 'apps\mobile\lib\ui_v2\universal\mool_global_navigation_v2.dart'
$testPath = Join-Path $root 'apps\mobile\test\ui_v2\universal\uaw_personal_mvp_subaction_disclosure_overflow_c20b_test.dart'

foreach ($path in @($predecessorGate, $parentPath, $ticketPath, $contractPath, $placementPath, $scopePath, $designPath, $navigationPath, $testPath)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "C21F required owner is missing: $path" }
}
& $predecessorGate -RepositoryRoot $root

$parent = Get-Content -Raw -LiteralPath $parentPath | ConvertFrom-Json
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$contract = Get-Content -Raw -LiteralPath $contractPath | ConvertFrom-Json
$placement = Get-Content -Raw -LiteralPath $placementPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$expected = 'UAW-PERSONAL-MVP-SUBACTION-DISCLOSURE-SELECTION-MOTION-REFINEMENT-FIX4-C21F'
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
  throw 'C21F ticket identity, sequence or scope disclosure is invalid.'
}
if (-not [bool]$ticket.reuseInventory.complete -or -not [bool]$ticket.reuseInventory.duplicateSearchComplete -or
    @($ticket.reuseInventory.newScreens).Count -ne 0 -or @($ticket.reuseInventory.newRoutes).Count -ne 0 -or
    @($ticket.reuseInventory.newBackendOwners).Count -ne 0 -or @($ticket.reuseInventory.newSubactions).Count -ne 0 -or
    [bool]$scope.execution.buildAuthorized -or [bool]$scope.execution.deviceInstallAuthorized -or
    [bool]$scope.execution.backendWriteAuthorized -or [bool]$scope.execution.externalServiceWriteAuthorized) {
  throw 'C21F reuse or execution boundary has been weakened.'
}

$rules = $contract.visualRules
$professional = $placement.professionalDesignSystem
if ([string]$contract.state -notlike 'c21[f-h]*' -or [string]$placement.state -notlike 'c21[f-h]*' -or
    [double]$rules.disclosureBadgeSize -ne 18 -or [double]$rules.disclosureBadgeIconSize -ne 14 -or
    [double]$rules.selectedMainActionTapTargetHeight -ne 48 -or
    -not [bool]$rules.selectedMainActionOwnsDisclosureTap -or -not [bool]$rules.defaultExpanded -or
    -not [bool]$rules.selectedMainRetapHidesAndRestoresOwnFamily -or -not [bool]$rules.disclosureStateIsSessionOnly -or
    -not [bool]$rules.truthfulHideShowSemanticsRequired -or [double]$rules.connectionLineStrokeWidth -ne 1.25 -or
    [double]$rules.connectionLineMaximumOpacity -ne .24 -or [double]$rules.connectionDotRadius -ne 1.5 -or
    [bool]$rules.connectionOwnsHitTestingOrSemantics -or [int]$rules.connectionMotionMilliseconds -ne 200 -or
    [int]$rules.stateMotionMilliseconds -ne 160 -or -not [bool]$rules.reducedMotionImmediate -or
    [double]$professional.disclosureBadgeSize -ne 18 -or
    [double]$professional.connectionLineStrokeWidth -ne 1.25 -or
    [double]$professional.connectionLineMaximumOpacity -ne .24 -or
    [bool]$contract.buildAuthorized -or [bool]$contract.installAuthorized) {
  throw 'C21F disclosure, connector, selection or motion contract has drifted.'
}

$design = Get-Content -Raw -LiteralPath $designPath
$navigation = Get-Content -Raw -LiteralPath $navigationPath
$test = Get-Content -Raw -LiteralPath $testPath
$blockers = [Collections.Generic.List[string]]::new()
foreach ($token in @(
  'static const double disclosureBadgeSize = 18',
  'static const double disclosureBadgeIconSize = 14',
  'static const double connectionLineStrokeWidth = 1.25',
  'static const double connectionLineMaximumOpacity = .24',
  'static const double connectionDotRadius = 1.5',
  'mool-action-${action.id}-subaction-disclosure-badge',
  'width: MoolLocalNavigationTokens.disclosureBadgeSize',
  'height: MoolLocalNavigationTokens.disclosureBadgeSize',
  'shape: BoxShape.circle',
  'Icons.keyboard_arrow_down_rounded',
  'Icons.keyboard_arrow_up_rounded',
  'minHeight: MoolMetrics.compactTapTarget'
)) {
  if (-not $design.Contains($token)) { $blockers.Add("C21F selected-main optical disclosure owner is missing: $token") }
}
foreach ($token in @(
  'static final Map<String, bool> _sessionDisclosureByFamily',
  'void _toggleLocalNavigation()',
  'duration: MoolMotion.quick',
  'duration: moolDestinationFamilyWaveDuration',
  'const Duration moolDestinationFamilyWaveDuration = Duration(milliseconds: 200)',
  'current. ',
  "localNavigationExpanded! ? 'Hide' : 'Show'",
  'onToggleLocalNavigation!()',
  'IgnorePointer(',
  'ExcludeSemantics(',
  'MoolLocalNavigationTokens.connectionLineStrokeWidth',
  'MoolLocalNavigationTokens.connectionLineMaximumOpacity',
  'MoolLocalNavigationTokens.connectionDotRadius',
  'AlwaysStoppedAnimation<double>(1)'
)) {
  if (-not $navigation.Contains($token)) { $blockers.Add("C21F destination disclosure/connector owner is missing: $token") }
}
if ($navigation -notmatch '\?\?\s*true') {
  $blockers.Add('C21F destination disclosure owner does not default expanded')
}
foreach ($forbidden in @('IconButton(', 'showModalBottomSheet(', 'showDialog(')) {
  $selectedActionStart = $design.IndexOf('class _MoolMiddleDockAction')
  if ($selectedActionStart -ge 0 -and $design.Substring($selectedActionStart).Contains($forbidden)) {
    $blockers.Add("C21F added a duplicate disclosure interaction owner: $forbidden")
  }
}
foreach ($token in @(
  "'social': 4", "'buy': 4", "'eat': 2", "'ride': 3", "'book': 2", "'work': 2",
  'defaults expanded and selected main action restores options',
  "const Size(18, 18)",
  'greaterThanOrEqualTo(48)',
  'Icons.keyboard_arrow_down_rounded',
  'Icons.keyboard_arrow_up_rounded',
  'normal disclosure is finite and reduced motion is immediate',
  'family connector stays restrained and owns no interaction',
  'collapsed family state is session-only and recoverable',
  'MoolLocalNavigationTokens.connectionLineStrokeWidth, 1.25',
  'MoolLocalNavigationTokens.connectionLineMaximumOpacity, .24',
  'MoolLocalNavigationTokens.connectionDotRadius, 1.5'
)) {
  if (-not $test.Contains($token)) { $blockers.Add("C21F focused coverage is missing: $token") }
}
if ($blockers.Count -gt 0) { throw ('C21F disclosure, selection and motion refinement is not qualified: ' + ($blockers -join '; ') + '.') }

Write-Output 'C21F disclosure/selection/motion refinement passed: families=6; selectedMainTap=62x48; disclosureBadge=18px; semantics=truthfulHideShow; default=expanded; retap=hideRestoreOwnFamily; state=sessionOnlyRecoverable; connector=1.25px@24%-dot1.5px; disclosure=160ms; wave=200ms; reducedMotion=immediate; duplicateControl=absent; buildInstall=closed.'
