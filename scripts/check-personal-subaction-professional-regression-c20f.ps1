[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

$predecessorGate = Join-Path $root 'scripts\check-personal-eat-ride-book-work-adaptive-conformance-c20e.ps1'
$parentPath = Join-Path $root 'config\uaw-personal-mvp-global-subaction-founder-gallery-professional-recovery-fix3-c20-ticket.json'
$ticketPath = Join-Path $root 'config\uaw-personal-mvp-subaction-professional-regression-gates-fix3-c20f-ticket.json'
$regressionPath = Join-Path $root 'config\mvp-personal-subaction-professional-recovery-regression-c20.json'
$scopePath = Join-Path $root 'config\mvp-scope-gate-state.json'
$testPath = Join-Path $root 'apps\mobile\test\ui_v2\universal\uaw_personal_mvp_subaction_professional_regression_c20f_test.dart'

foreach ($path in @($predecessorGate, $parentPath, $ticketPath, $regressionPath, $scopePath, $testPath)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "C20F required owner is missing: $path"
  }
}

& $predecessorGate -RepositoryRoot $root

$parent = Get-Content -Raw -LiteralPath $parentPath | ConvertFrom-Json
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$regression = Get-Content -Raw -LiteralPath $regressionPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$expected = 'UAW-PERSONAL-MVP-SUBACTION-PROFESSIONAL-REGRESSION-GATES-FIX3-C20F'

if ([int]$ticket.schemaVersion -ne 1 -or
    [string]$ticket.ticketId -cne $expected -or
    [string]$ticket.parentTicket -cne [string]$parent.ticketId -or
    [string]$ticket.classification -cne 'mvp_required') {
  throw 'C20F ticket identity or MVP classification is invalid.'
}
if (-not [bool]$ticket.reuseInventory.complete -or
    -not [bool]$ticket.reuseInventory.duplicateSearchComplete -or
    (@($ticket.reuseInventory.existingGates) -join ',') -cne 'C20B,C20C,C20D,C20E' -or
    [int]$ticket.reuseInventory.existingSelectedStateCount -ne 17 -or
    @($ticket.reuseInventory.newScreens).Count -ne 0 -or
    @($ticket.reuseInventory.newRoutes).Count -ne 0 -or
    @($ticket.reuseInventory.newBackendOwners).Count -ne 0 -or
    @($ticket.reuseInventory.newSubactions).Count -ne 0) {
  throw 'C20F reuse, duplicate-search, predecessor or zero-new-owner contract is incomplete.'
}
if (-not [bool]$ticket.execution.referenceWriteAuthorized -or
    [bool]$ticket.execution.runtimeSourceWriteAuthorized -or
    -not [bool]$ticket.execution.testAndGateWriteAuthorized -or
    [bool]$ticket.execution.backendWriteAuthorized -or
    [bool]$ticket.execution.buildAuthorized -or
    [bool]$ticket.execution.installAuthorized -or
    [bool]$ticket.execution.externalServiceWriteAuthorized) {
  throw 'C20F test/gate-only authority has been weakened or expanded.'
}

$sequence = @($parent.implementationSequence)
$expectedIndex = [Array]::IndexOf($sequence, $expected)
$current = [string]$scope.ticket.id
$currentIndex = [Array]::IndexOf($sequence, $current)
if ([string]$parent.ticketId -cne 'UAW-PERSONAL-MVP-GLOBAL-SUBACTION-FOUNDER-GALLERY-PROFESSIONAL-RECOVERY-FIX3-C20' -or
    $expectedIndex -lt 0 -or $currentIndex -lt $expectedIndex -or
    [string]$scope.preTicketSelectionCheckpoint.currentTicketId -cne $current -or
    [string]$scope.state -cne 'ticket_disclosed_and_authorized') {
  throw 'C20F sequential MVP selection and disclosure gate is not active.'
}
if ([bool]$scope.execution.runtimeWriteAuthorized -or
    [bool]$scope.execution.buildAuthorized -or
    [bool]$scope.execution.deviceInstallAuthorized -or
    [bool]$scope.execution.backendWriteAuthorized -or
    [bool]$scope.execution.externalServiceWriteAuthorized) {
  throw 'C20F scope must keep runtime, build, install, backend and external authority closed.'
}

$aggregate = $ticket.aggregateContract
if ((@($aggregate.families) -join ',') -cne 'social,buy,eat,ride,book,work' -or
    [int]$aggregate.selectedStateCount -ne 17 -or
    (@($aggregate.supportedActionCounts) -join ',') -cne '2,3,4' -or
    -not [bool]$aggregate.defaultDisclosureExpanded -or
    [double]$aggregate.collapsedHeight -ne 0 -or
    [double]$aggregate.minimumDisclosureTarget -ne 48 -or
    [double]$aggregate.minimumOverflowTarget -ne 44 -or
    [double]$aggregate.railSurfaceOpacity -ne 0 -or
    [double]$aggregate.minimumCompositedContrast -ne 4.5 -or
    [double]$aggregate.controlHeight -ne 48 -or
    [double]$aggregate.controlRadius -ne 16 -or
    [double]$aggregate.labelFontSize -ne 13 -or
    [int]$aggregate.labelFontWeight -ne 700 -or
    [double]$aggregate.maximumNavigationTextScale -ne 1.3 -or
    [double]$aggregate.iconOpticalBox -ne 20 -or
    [int]$aggregate.normalControlMotionMilliseconds -ne 160 -or
    -not [bool]$aggregate.reducedMotionImmediate -or
    -not [bool]$aggregate.selectedActionInert -or
    -not [bool]$aggregate.availableActionOneTap -or
    -not [bool]$aggregate.BackMoolChatContinuityRequired -or
    -not [bool]$aggregate.contentReachabilityRequired -or
    [bool]$aggregate.familyTintedFillAllowed -or
    [bool]$aggregate.blockingBandOrTrapezoidAllowed -or
    [bool]$aggregate.horizontalScrollOrPanelAllowed -or
    [bool]$aggregate.distributedSparseCellsAllowed -or
    [bool]$aggregate.fillerActionAllowed -or
    [bool]$aggregate.selectedShadowAllowed) {
  throw 'C20F aggregate professional contract has drifted.'
}

$rules = $regression.professionalGateRules
if ((@($rules.childGateSequence) -join ',') -cne 'C20B,C20C,C20D,C20E' -or
    [int]$rules.familyCount -ne 6 -or
    [int]$rules.selectedStateCount -ne 17 -or
    (@($rules.supportedActionCounts) -join ',') -cne '2,3,4' -or
    -not [bool]$rules.selectedActionInert -or
    -not [bool]$rules.availableActionOneTap -or
    -not [bool]$rules.BackMoolChatContinuityRequired -or
    -not [bool]$rules.contentReachabilityRequired -or
    -not [bool]$rules.anchoredGlobalShellRequired -or
    [int]$rules.normalControlMotionMilliseconds -ne 160 -or
    -not [bool]$rules.reducedMotionImmediate -or
    -not [bool]$rules.twoConsecutiveUnchangedSourceHostCyclesRequiredBeforeBuild -or
    [int]$rules.singleSuccessorBuildMaximum -ne 1 -or
    [int]$regression.hostQualification.requiredConsecutiveCycles -ne 2 -or
    (@(0, 2) -notcontains [int]$regression.hostQualification.completedConsecutiveCycles) -or
    -not [bool]$regression.hostQualification.unchangedSourceFingerprintRequired -or
    -not [bool]$regression.hostQualification.completeRequiredSuiteRequired -or
    -not [bool]$regression.hostQualification.buildAndInstallRemainClosed -or
    [bool]$regression.buildAuthorized -or [bool]$regression.installAuthorized) {
  throw 'C20F permanent professional gate or host/build boundary has been weakened.'
}

$required = @($regression.requiredGates) + @($regression.requiredTests) + @($regression.requiredContinuityTests)
if ($required.Count -ne @($required | Select-Object -Unique).Count) {
  throw 'C20F required gate/test inventory contains a duplicate.'
}
foreach ($relative in $required) {
  $resolved = [IO.Path]::GetFullPath((Join-Path $root ([string]$relative)))
  if (-not $resolved.StartsWith($root, [StringComparison]::OrdinalIgnoreCase) -or
      -not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
    throw "C20F required gate/test is missing or outside the repository: $relative"
  }
}

$test = Get-Content -Raw -LiteralPath $testPath
$blockers = [Collections.Generic.List[string]]::new()
foreach ($token in @(
  'aggregate contract locks six families and seventeen selected states',
  'visual disclosure and overflow rules preserve professional grammar',
  'all required child gates tests and continuity owners exist',
  'required source coverage owns semantics motion continuity and reachability',
  "'social'",
  "'buy'",
  "'eat'",
  "'ride'",
  "'book'",
  "'work'",
  "['C20B', 'C20C', 'C20D', 'C20E']",
  'hasLength(17)',
  'BackMoolChatContinuityRequired',
  'contentReachabilityRequired',
  'current. Hide $label options',
  'current. Show $label options',
  'greaterThanOrEqualTo(4.5)',
  'flagsCollection.isSelected',
  'hasAction(SemanticsAction.tap)',
  'deep Eat local switch and global Work switch preserve one navigation frame',
  'Social Mool Social Mool uses one rail and exact history',
  "host['requiredConsecutiveCycles'], 2",
  "regression['buildAuthorized'], isFalse",
  "regression['installAuthorized'], isFalse"
)) {
  if (-not $test.Contains($token)) { $blockers.Add("C20F focused coverage is missing: $token") }
}
if ($blockers.Count -gt 0) {
  throw ('C20F professional aggregate regression is not qualified: ' + ($blockers -join '; ') + '.')
}

Write-Output "C20F professional aggregate regression passed: families=6; selectedStates=17; counts=2,3,4; childGates=4; requiredGates=$(@($regression.requiredGates).Count); requiredTests=$(@($regression.requiredTests).Count); continuityTests=$(@($regression.requiredContinuityTests).Count); disclosure=true; overflow=true; neutralGlass=true; contrast>=4.5; semantics=true; BackMoolChat=true; reachability=true; twoUnchangedHostCyclesPending=true; runtimeBuildInstall=closed."
