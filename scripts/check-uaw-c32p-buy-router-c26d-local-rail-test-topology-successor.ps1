[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C32P([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C32P gate rejected: $Message" }
}

function Resolve-C32P([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C32P ($path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) "owner escaped repository: $RelativePath"
  Assert-C32P (Test-Path -LiteralPath $path -PathType Leaf) "owner missing: $RelativePath"
  return $path
}

function Read-C32P([string]$RelativePath) {
  return [IO.File]::ReadAllText((Resolve-C32P $RelativePath))
}

$ticketPath = Resolve-C32P 'config/uaw-c32p-personal-mvp-buy-router-c26d-local-rail-test-topology-successor-ticket.json'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Read-C32P 'config/mvp-scope-gate-state.json' | ConvertFrom-Json
$buyTest = Read-C32P 'apps/mobile/test/ui_v2/buy/buy_v2_router_test.dart'
$c26dTest = Read-C32P 'apps/mobile/test/ui_v2/universal/mool_family_pair_navigation_conformance_c26d_test.dart'
$buy = Read-C32P 'apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart'
$c32oGate = Read-C32P 'scripts/check-uaw-c32o-buy-router-compact-mool-launcher-test-successor.ps1'

Assert-C32P ([string]$ticket.ticketId -ceq 'UAW-C32P-PERSONAL-MVP-BUY-ROUTER-C26D-LOCAL-RAIL-TEST-TOPOLOGY-SUCCESSOR') 'ticket id changed'
Assert-C32P ([string]$ticket.classification -ceq 'mvp_supporting') 'ticket classification changed'
Assert-C32P ([bool]$ticket.authority.testAndGateWriteAuthorized) 'ticket test/gate authority closed'
Assert-C32P (-not [bool]$ticket.authority.runtimeSourceWriteAuthorized) 'ticket runtime authority opened'
Assert-C32P (-not [bool]$ticket.authority.backendSourceWriteAuthorized) 'ticket backend authority opened'
Assert-C32P (-not [bool]$ticket.authority.referenceWriteAuthorized) 'ticket reference authority opened'
Assert-C32P (-not [bool]$ticket.authority.baselineReplacementAuthorized) 'ticket baseline authority opened'
Assert-C32P (-not [bool]$ticket.authority.buildAuthorized) 'ticket build authority opened'
Assert-C32P (-not [bool]$ticket.authority.deviceMutationAuthorized) 'ticket device authority opened'
Assert-C32P (-not [bool]$ticket.authority.externalCommunicationAuthorized) 'ticket communication authority opened'

$selected = $scope.preTicketSelectionCheckpoint.selectedTicketAssessment
$activeScope = [string]$scope.ticket.id -ceq [string]$ticket.ticketId
if ($activeScope) {
  Assert-C32P ([string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq [string]$ticket.ticketId) 'pre-ticket current ticket differs'
  Assert-C32P ([string]$selected.ticketId -ceq [string]$ticket.ticketId) 'selected assessment ticket differs'
  Assert-C32P ([string]$selected.manifestSha256 -ceq 'B1FE1E74112AD663D5733B25859A5EB7772E914179D2B95755B01E3E05B8651B') 'selected ticket manifest hash differs'
  Assert-C32P ((Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash -ceq [string]$selected.manifestSha256) 'selected ticket bytes differ'
} else {
  $priorC32P = $scope.preTicketSelectionCheckpoint.priorC32PFocusedTicketAssessment
  Assert-C32P ($null -ne $priorC32P) 'preserved prior C32P assessment is missing'
  Assert-C32P ([string]$priorC32P.ticketId -ceq [string]$ticket.ticketId) 'preserved prior C32P ticket differs'
  Assert-C32P ([string]$priorC32P.manifestSha256 -ceq 'B1FE1E74112AD663D5733B25859A5EB7772E914179D2B95755B01E3E05B8651B') 'preserved prior C32P manifest hash differs'
  Assert-C32P ([string]$priorC32P.implementationState -ceq 'C32N_attribution_and_C32O_C32P_test_successors_implemented_two_focused_cycles_passed_full_preflight_Buy_protected_baseline_hold_no_qualification_claim') 'preserved prior C32P implementation state differs'
  Assert-C32P ((Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash -ceq [string]$priorC32P.manifestSha256) 'preserved prior C32P ticket bytes differ'
}

$priorC32O = $scope.preTicketSelectionCheckpoint.priorC32OBlockedTicketAssessment
Assert-C32P ($null -ne $priorC32O) 'prior C32O assessment missing'
Assert-C32P ([string]$priorC32O.ticketId -ceq 'UAW-C32O-PERSONAL-MVP-BUY-ROUTER-COMPACT-MOOL-LAUNCHER-TEST-SUCCESSOR') 'prior C32O ticket differs'
Assert-C32P ([string]$priorC32O.manifestSha256 -ceq '6D87CCF16EF817407D33C323D07D1F7E442A3CB83E09BF573C33C08359568A18') 'prior C32O manifest hash differs'
Assert-C32P ([string]$priorC32O.implementationState -ceq 'compact_launcher_test_successor_implemented_focused_test_blocked_only_at_obsolete_C26D_local_rail_topology_all_runtime_and_baseline_holds_preserved') 'prior C32O state differs'
Assert-C32P ($c32oGate.Contains('priorC32OBlockedTicketAssessment')) 'C32O historical scope property is not enforced'
Assert-C32P ($c32oGate.Contains('scopeBinding=')) 'C32O truthful lifecycle pass identity missing'

Assert-C32P ($buyTest.Contains("if (action != 'shop')")) 'Buy root/nonroot topology branch missing'
Assert-C32P ($buyTest.Contains("ValueKey('buy-local-tab-`$action')")) 'Buy nonroot local action key missing'
Assert-C32P ($buyTest.Contains("find.byKey(const Key('buy-local-destination-tabs')), findsOneWidget")) 'Buy local rail presence assertion missing'
Assert-C32P ($buyTest.Contains("find.byKey(const Key('mool-navigator-buy-shop')), findsNothing")) 'obsolete direct Shop chooser key rejection missing'
Assert-C32P ($buyTest.Contains("find.byKey(const Key('mool-navigator-buy-orders')), findsNothing")) 'obsolete direct Orders chooser key rejection missing'
Assert-C32P (-not $buyTest.Contains("ValueKey('mool-navigator-`$family-`$action')")) 'obsolete generic chooser action dispatch remains'
Assert-C32P ($c26dTest.Contains("find.byKey(const Key('buy-local-tab-wholesale'))")) 'C26D local rail authority missing'
Assert-C32P ($c26dTest.Contains("find.byKey(const Key('mool-navigator-buy-shop')), findsNothing")) 'C26D family-only chooser authority missing'
Assert-C32P ($buy.Contains("key: const ValueKey('buy-local-destination-tabs')")) 'runtime Buy local rail owner missing'
Assert-C32P ($buy.Contains("keyName: 'buy-local-tab-orders'")) 'runtime Orders local action missing'

Assert-C32P ([bool]$scope.execution.testOrGateWriteAuthorized) 'scope test/gate authority closed'
Assert-C32P (-not [bool]$scope.execution.referenceWriteAuthorized) 'scope reference authority opened'
if ($activeScope) {
  Assert-C32P (-not [bool]$scope.execution.runtimeWriteAuthorized) 'scope runtime authority opened'
}
Assert-C32P (-not [bool]$scope.execution.backendWriteAuthorized) 'scope backend authority opened'
Assert-C32P (-not [bool]$scope.execution.buildAuthorized) 'scope build authority opened'
Assert-C32P (-not [bool]$scope.execution.deviceInstallAuthorized) 'scope device authority opened'
Assert-C32P (-not [bool]$scope.execution.externalServiceWriteAuthorized) 'scope external authority opened'
Assert-C32P (-not [bool]$scope.execution.secretValueAccessAuthorized) 'scope secret authority opened'
Assert-C32P (-not [bool]$scope.protectedCandidateState.protectedBaselineUpdated) 'protected baseline was changed'
Assert-C32P ([bool]$scope.protectedCandidateState.founderAcceptancePending) 'protected founder hold was removed'

Write-Output "C32P Buy router C26D local-rail test successor passed: scopeBinding=$(if ($activeScope) { 'active' } else { 'preservedPrior' }); familyChooser=BuyRoot; localActions=Wholesale,Orders; runtimeChanged=false; baselineUpdate=false."
