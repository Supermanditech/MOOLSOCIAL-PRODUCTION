[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

$parentPath = Join-Path $root 'config\uaw-personal-mvp-global-subaction-founder-gallery-professional-recovery-fix3-c20-ticket.json'
$ticketPath = Join-Path $root 'config\uaw-personal-mvp-subaction-disclosure-and-overflow-affordance-fix3-c20b-ticket.json'
$regressionPath = Join-Path $root 'config\mvp-personal-subaction-professional-recovery-regression-c20.json'
$scopePath = Join-Path $root 'config\mvp-scope-gate-state.json'
$navigationPath = Join-Path $root 'apps\mobile\lib\ui_v2\universal\mool_global_navigation_v2.dart'
$designPath = Join-Path $root 'apps\mobile\lib\core\design\mool_design_system.dart'
$testPath = Join-Path $root 'apps\mobile\test\ui_v2\universal\uaw_personal_mvp_subaction_disclosure_overflow_c20b_test.dart'

foreach ($path in @($parentPath, $ticketPath, $regressionPath, $scopePath, $navigationPath, $designPath, $testPath)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "C20B required owner is missing: $path"
  }
}

$parent = Get-Content -Raw -LiteralPath $parentPath | ConvertFrom-Json
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$regression = Get-Content -Raw -LiteralPath $regressionPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$expected = 'UAW-PERSONAL-MVP-SUBACTION-DISCLOSURE-AND-OVERFLOW-AFFORDANCE-FIX3-C20B'

if ([int]$ticket.schemaVersion -ne 1 -or [string]$ticket.ticketId -cne $expected -or
    [string]$ticket.parentTicket -cne [string]$parent.ticketId -or
    [string]$ticket.classification -cne 'mvp_required') {
  throw 'C20B ticket identity or MVP classification is invalid.'
}
if (-not [bool]$ticket.reuseInventory.complete -or
    -not [bool]$ticket.reuseInventory.duplicateSearchComplete -or
    @($ticket.reuseInventory.newScreens).Count -ne 0 -or
    @($ticket.reuseInventory.newRoutes).Count -ne 0 -or
    @($ticket.reuseInventory.newBackendOwners).Count -ne 0 -or
    @($ticket.reuseInventory.newSubactions).Count -ne 0) {
  throw 'C20B reuse, duplicate-search or zero-new-owner contract is incomplete.'
}
if (-not [bool]$ticket.execution.referenceWriteAuthorized -or
    -not [bool]$ticket.execution.runtimeSourceWriteAuthorized -or
    -not [bool]$ticket.execution.testAndGateWriteAuthorized -or
    [bool]$ticket.execution.backendWriteAuthorized -or
    [bool]$ticket.execution.buildAuthorized -or
    [bool]$ticket.execution.installAuthorized -or
    [bool]$ticket.execution.externalServiceWriteAuthorized) {
  throw 'C20B execution authority has been weakened or expanded.'
}

$sequence = @($parent.implementationSequence)
$expectedIndex = [Array]::IndexOf($sequence, $expected)
$current = [string]$scope.ticket.id
$currentIndex = [Array]::IndexOf($sequence, $current)
if ($expectedIndex -lt 0 -or $currentIndex -lt $expectedIndex -or
    [string]$scope.preTicketSelectionCheckpoint.currentTicketId -cne $current -or
    [string]$scope.state -cne 'ticket_disclosed_and_authorized') {
  throw 'C20B sequential MVP selection and disclosure gate is not active.'
}
if ([bool]$scope.execution.buildAuthorized -or
    [bool]$scope.execution.deviceInstallAuthorized -or
    [bool]$scope.execution.backendWriteAuthorized -or
    [bool]$scope.execution.externalServiceWriteAuthorized) {
  throw 'C20B host gate refuses build, install, backend and external authority.'
}

if ([int]$regression.schemaVersion -ne 1 -or
    [string]$regression.contractId -cne 'UAW-PERSONAL-MVP-SUBACTION-PROFESSIONAL-RECOVERY-REGRESSION-C20' -or
    [bool]$regression.installedRejectedCandidate.mustRemainInstalledUntilQualifiedSuccessor -ne $true -or
    [bool]$regression.buildAuthorized -or [bool]$regression.installAuthorized -or
    -not [bool]$regression.disclosureRules.defaultExpanded -or
    [string]$regression.disclosureRules.owner -cne 'selected_main_action' -or
    [double]$regression.disclosureRules.targetMinimum -ne 48 -or
    [double]$regression.disclosureRules.collapsedLayoutHeight -ne 0 -or
    [bool]$regression.disclosureRules.contentOrRouteResetAllowed -or
    [bool]$regression.disclosureRules.historyEntryAllowed -or
    [bool]$regression.disclosureRules.systemBackOverrideAllowed -or
    -not [bool]$regression.disclosureRules.reducedMotionImmediate -or
    [double]$regression.overflowRules.minimumTapTargetWhenArrowShown -ne 44 -or
    [bool]$regression.overflowRules.arrowGlyphMayBeIgnorePointer -or
    [bool]$regression.overflowRules.mayOverlapMainActionHitTargets -or
    -not [bool]$regression.overflowRules.exactPreviousNextSemanticsRequiredForInteractiveCue) {
  throw 'C20B disclosure, overflow or preserved-installed-candidate rules have been weakened.'
}

$navigation = Get-Content -Raw -LiteralPath $navigationPath
$design = Get-Content -Raw -LiteralPath $designPath
$test = Get-Content -Raw -LiteralPath $testPath
$blockers = [Collections.Generic.List[string]]::new()

foreach ($token in @(
  'static final Map<String, bool> _sessionDisclosureByFamily',
  '._sessionDisclosureByFamily[_registeredActiveId] ??',
  'late final AnimationController _disclosureController',
  'duration: MoolMotion.quick',
  'void _toggleLocalNavigation()',
  'MoolDestinationNavigationV2',
  '._sessionDisclosureByFamily[_registeredActiveId] =',
  '_disclosureController.value = nextExpanded ? 1 : 0',
  'subaction-disclosure-region',
  'heightFactor: progress',
  'ignoring: !_localNavigationExpanded',
  'excluding: !_localNavigationExpanded',
  'localNavigationExpanded: _localNavigationExpanded',
  'onToggleLocalNavigation: _toggleLocalNavigation',
  'localNavigationExpanded! ? ''Hide'' : ''Show''',
  'onToggleLocalNavigation!()'
)) {
  if (-not $navigation.Contains($token)) { $blockers.Add("destination disclosure owner is missing: $token") }
}

$toggleStart = $navigation.IndexOf('void _toggleLocalNavigation()')
$toggleEnd = $navigation.IndexOf('void _scheduleMainAnchorMeasure()', $toggleStart)
if ($toggleStart -lt 0 -or $toggleEnd -le $toggleStart) {
  $blockers.Add('destination disclosure method bounds are invalid')
} else {
  $toggle = $navigation.Substring($toggleStart, $toggleEnd - $toggleStart)
  foreach ($forbidden in @('context.go(', 'context.push(', 'Navigator.', 'GoRouter.', 'pop(', 'push(', 'replace(')) {
    if ($toggle.Contains($forbidden)) { $blockers.Add("disclosure mutates navigation or history: $forbidden") }
  }
}

foreach ($token in @(
  'final bool? disclosureExpanded',
  'insetBorder: false',
  "key: const Key('mool-main-rail-overflow-back')",
  "key: const Key('mool-main-rail-overflow-cue')",
  "semanticLabel: 'Previous main actions'",
  "semanticLabel: 'Next main actions'",
  'width: MoolMetrics.minimumTapTarget',
  'height: MoolMetrics.compactTapTarget',
  'explicitChildNodes: true',
  'onTap: onPressed',
  'onTap: action.onPressed',
  'subaction-disclosure-badge',
  'Icons.keyboard_arrow_down_rounded',
  'Icons.keyboard_arrow_up_rounded'
)) {
  if (-not $design.Contains($token)) { $blockers.Add("shared disclosure or overflow owner is missing: $token") }
}
if ($design.Contains('width: 22')) { $blockers.Add('rejected 22px overflow cue remains') }

foreach ($token in @(
  "'social': 4",
  "'buy': 4",
  "'eat': 2",
  "'ride': 3",
  "'book': 2",
  "'work': 2",
  'defaults expanded and selected main action restores options',
  'greaterThanOrEqualTo(48)',
  'current. Hide $label options',
  'current. Show $label options',
  'normal disclosure is finite and reduced motion is immediate',
  'collapsed family state is session-only and recoverable',
  'overflow arrows are truthful 44px non-overlapping buttons',
  "find.bySemanticsLabel('Previous main actions')",
  "find.bySemanticsLabel('Next main actions')",
  'hasAction(SemanticsAction.tap)',
  'widgetList<ExcludeSemantics>',
  'widgetList<IgnorePointer>'
)) {
  if (-not $test.Contains($token)) { $blockers.Add("C20B focused coverage is missing: $token") }
}

if ($blockers.Count -gt 0) {
  throw ('C20B disclosure and overflow affordance is not qualified: ' + ($blockers -join '; ') + '.')
}

Write-Output 'C20B disclosure and overflow affordance passed: families=6; defaultExpanded=true; selectedMainTarget=48px; collapsedHeight=0px; sessionOnly=true; normalMotion=160ms; reducedMotion=immediate; overflowTargets=44x48px; exactSemantics=true; routeHistoryMutation=absent; buildInstall=closed.'
