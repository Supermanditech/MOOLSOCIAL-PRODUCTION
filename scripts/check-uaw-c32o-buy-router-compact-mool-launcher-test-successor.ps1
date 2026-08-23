[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C32O([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C32O gate rejected: $Message" }
}

function Resolve-C32O([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C32O ($path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) "owner escaped repository: $RelativePath"
  Assert-C32O (Test-Path -LiteralPath $path -PathType Leaf) "owner missing: $RelativePath"
  return $path
}

function Read-C32O([string]$RelativePath) {
  return [IO.File]::ReadAllText((Resolve-C32O $RelativePath))
}

$ticketPath = Resolve-C32O 'config/uaw-c32o-personal-mvp-buy-router-compact-mool-launcher-test-successor-ticket.json'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Read-C32O 'config/mvp-scope-gate-state.json' | ConvertFrom-Json
$buyTest = Read-C32O 'apps/mobile/test/ui_v2/buy/buy_v2_router_test.dart'
$navigation = Read-C32O 'apps/mobile/lib/ui_v2/universal/mool_global_navigation_v2.dart'
$c26dTest = Read-C32O 'apps/mobile/test/ui_v2/universal/mool_family_pair_navigation_conformance_c26d_test.dart'
$c29nTest = Read-C32O 'apps/mobile/test/ui_v2/social/uaw_personal_mvp_social_creator_ergonomics_global_edge_consistency_c29n_test.dart'
$c32nGate = Read-C32O 'scripts/check-uaw-c32n-buy-protected-shared-router-delta-attribution-hold.ps1'

Assert-C32O ([string]$ticket.ticketId -ceq 'UAW-C32O-PERSONAL-MVP-BUY-ROUTER-COMPACT-MOOL-LAUNCHER-TEST-SUCCESSOR') 'ticket id changed'
Assert-C32O ([string]$ticket.classification -ceq 'mvp_supporting') 'ticket classification changed'
Assert-C32O ([bool]$ticket.authority.testAndGateWriteAuthorized) 'ticket test/gate authority closed'
Assert-C32O (-not [bool]$ticket.authority.runtimeSourceWriteAuthorized) 'ticket runtime authority opened'
Assert-C32O (-not [bool]$ticket.authority.backendSourceWriteAuthorized) 'ticket backend authority opened'
Assert-C32O (-not [bool]$ticket.authority.referenceWriteAuthorized) 'ticket reference authority opened'
Assert-C32O (-not [bool]$ticket.authority.baselineReplacementAuthorized) 'ticket baseline authority opened'
Assert-C32O (-not [bool]$ticket.authority.buildAuthorized) 'ticket build authority opened'
Assert-C32O (-not [bool]$ticket.authority.deviceMutationAuthorized) 'ticket device authority opened'
Assert-C32O (-not [bool]$ticket.authority.externalCommunicationAuthorized) 'ticket communication authority opened'

$selected = $scope.preTicketSelectionCheckpoint.selectedTicketAssessment
$activeScope = [string]$scope.ticket.id -ceq [string]$ticket.ticketId
if ($activeScope) {
  Assert-C32O ([string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq [string]$ticket.ticketId) 'pre-ticket current ticket differs'
  Assert-C32O ([string]$selected.ticketId -ceq [string]$ticket.ticketId) 'selected assessment ticket differs'
  Assert-C32O ([string]$selected.manifestSha256 -ceq '6D87CCF16EF817407D33C323D07D1F7E442A3CB83E09BF573C33C08359568A18') 'selected ticket manifest hash differs'
  Assert-C32O ((Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash -ceq [string]$selected.manifestSha256) 'selected ticket bytes differ'
} else {
  $priorC32O = $scope.preTicketSelectionCheckpoint.priorC32OBlockedTicketAssessment
  Assert-C32O ($null -ne $priorC32O) 'preserved prior C32O assessment missing'
  Assert-C32O ([string]$priorC32O.ticketId -ceq [string]$ticket.ticketId) 'preserved prior C32O ticket differs'
  Assert-C32O ([string]$priorC32O.manifestSha256 -ceq '6D87CCF16EF817407D33C323D07D1F7E442A3CB83E09BF573C33C08359568A18') 'preserved prior C32O manifest hash differs'
  Assert-C32O ([string]$priorC32O.implementationState -ceq 'compact_launcher_test_successor_implemented_focused_test_blocked_only_at_obsolete_C26D_local_rail_topology_all_runtime_and_baseline_holds_preserved') 'preserved prior C32O state differs'
  Assert-C32O ((Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash -ceq [string]$priorC32O.manifestSha256) 'preserved prior C32O ticket bytes differ'
}

$priorC32N = $scope.preTicketSelectionCheckpoint.priorC32NBlockedTicketAssessment
Assert-C32O ($null -ne $priorC32N) 'prior C32N assessment missing'
Assert-C32O ([string]$priorC32N.ticketId -ceq 'UAW-C32N-PERSONAL-MVP-BUY-PROTECTED-SHARED-ROUTER-DELTA-ATTRIBUTION-HOLD') 'prior C32N ticket differs'
Assert-C32O ([string]$priorC32N.manifestSha256 -ceq '258F5A287EEF5A2FF6F44294EBC4303184CF5EF7C1A4BB8E7D6A883547FCA526') 'prior C32N manifest hash differs'
Assert-C32O ([string]$priorC32N.implementationState -ceq 'source_gate_attribution_implemented_initial_cycle_blocked_only_at_stale_Buy_router_launcher_test_protected_baseline_hold_preserved') 'prior C32N state differs'
Assert-C32O ($c32nGate.Contains('priorC32NBlockedTicketAssessment')) 'C32N historical scope property is not enforced'
Assert-C32O ($c32nGate.Contains('scopeBinding=')) 'C32N truthful lifecycle pass identity missing'

Assert-C32O ([regex]::Matches($buyTest, 'mool-compact-launcher').Count -eq 3) 'Buy router compact launcher reference count differs'
Assert-C32O (-not $buyTest.Contains('mool-home-launcher')) 'Buy router test still uses the noncompact launcher key'
Assert-C32O ($navigation.Contains("key: const Key('mool-compact-launcher')")) 'compact runtime launcher key missing'
Assert-C32O ($navigation.Contains("key: const Key('mool-home-launcher')")) 'noncompact runtime launcher owner unexpectedly removed'
Assert-C32O ($c26dTest.Contains("find.byKey(const Key('mool-compact-launcher'))")) 'C26D compact launcher authority missing'
Assert-C32O ($c29nTest.Contains("find.byKey(const Key('mool-compact-launcher'))")) 'C29N compact launcher authority missing'

Assert-C32O ([bool]$scope.execution.testOrGateWriteAuthorized) 'scope test/gate authority closed'
Assert-C32O (-not [bool]$scope.execution.referenceWriteAuthorized) 'scope reference authority opened'
Assert-C32O (-not [bool]$scope.execution.runtimeWriteAuthorized) 'scope runtime authority opened'
Assert-C32O (-not [bool]$scope.execution.backendWriteAuthorized) 'scope backend authority opened'
Assert-C32O (-not [bool]$scope.execution.buildAuthorized) 'scope build authority opened'
Assert-C32O (-not [bool]$scope.execution.deviceInstallAuthorized) 'scope device authority opened'
Assert-C32O (-not [bool]$scope.execution.externalServiceWriteAuthorized) 'scope external authority opened'
Assert-C32O (-not [bool]$scope.execution.secretValueAccessAuthorized) 'scope secret authority opened'
Assert-C32O (-not [bool]$scope.protectedCandidateState.protectedBaselineUpdated) 'protected baseline was changed'
Assert-C32O ([bool]$scope.protectedCandidateState.founderAcceptancePending) 'protected founder hold was removed'

Write-Output "C32O Buy router compact-launcher test successor passed: scopeBinding=$(if ($activeScope) { 'active' } else { 'preservedPrior' }); replacements=3; staleHomeKey=0; runtimeChanged=false; baselineUpdate=false."
