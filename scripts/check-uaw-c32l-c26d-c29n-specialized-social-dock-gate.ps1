[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C32L([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C32L gate rejected: $Message" }
}

function Read-C32L([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C32L ($path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) "owner escaped repository: $RelativePath"
  Assert-C32L (Test-Path -LiteralPath $path -PathType Leaf) "owner missing: $RelativePath"
  return [IO.File]::ReadAllText($path)
}

function Get-C32LSlice([string]$Text, [string]$Start, [string]$End) {
  $startIndex = $Text.IndexOf($Start, [StringComparison]::Ordinal)
  Assert-C32L ($startIndex -ge 0) "start marker missing: $Start"
  $endIndex = $Text.IndexOf($End, $startIndex + $Start.Length, [StringComparison]::Ordinal)
  Assert-C32L ($endIndex -gt $startIndex) "end marker missing: $End"
  return $Text.Substring($startIndex, $endIndex - $startIndex)
}

function Assert-C32LSequence([string]$Text, [string[]]$Items, [string]$Owner) {
  $cursor = -1
  foreach ($item in $Items) {
    $cursor = $Text.IndexOf($item, $cursor + 1, [StringComparison]::Ordinal)
    Assert-C32L ($cursor -ge 0) "$Owner order/member missing after previous item: $item"
  }
}

$ticket = Read-C32L 'config/uaw-c32l-personal-mvp-c26d-c29n-specialized-social-dock-gate-reconciliation-ticket.json' | ConvertFrom-Json
$scope = Read-C32L 'config/mvp-scope-gate-state.json' | ConvertFrom-Json
$c29n = Read-C32L 'config/uaw-personal-mvp-social-creator-ergonomics-global-edge-consistency-c29n-ticket.json' | ConvertFrom-Json
$social = Read-C32L 'apps/mobile/lib/ui_v2/social/social_v2_consumer.dart'
$buy = Read-C32L 'apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart'
$c26dGate = Read-C32L 'scripts/check-personal-social-shop-navigation-conformance-c26d.ps1'
$c29nTest = Read-C32L 'apps/mobile/test/ui_v2/social/uaw_personal_mvp_social_creator_ergonomics_global_edge_consistency_c29n_test.dart'
$c26dTest = Read-C32L 'apps/mobile/test/ui_v2/universal/mool_family_pair_navigation_conformance_c26d_test.dart'

Assert-C32L ([string]$ticket.ticketId -ceq 'UAW-C32L-PERSONAL-MVP-C26D-C29N-SPECIALIZED-SOCIAL-DOCK-GATE-RECONCILIATION') 'ticket id changed'
Assert-C32L ([string]$ticket.classification -ceq 'mvp_supporting') 'classification changed'
Assert-C32L ([bool]$ticket.authority.testAndGateWriteAuthorized) 'test/gate authority closed'
Assert-C32L (-not [bool]$ticket.authority.runtimeSourceWriteAuthorized) 'runtime authority opened'
Assert-C32L (-not [bool]$ticket.authority.backendSourceWriteAuthorized) 'backend authority opened'
Assert-C32L (-not [bool]$ticket.authority.buildAuthorized) 'build authority opened'
Assert-C32L (-not [bool]$ticket.authority.deviceMutationAuthorized) 'device authority opened'
$activeScope = [string]$scope.ticket.id -ceq [string]$ticket.ticketId
if (-not $activeScope) {
  $prior = $scope.preTicketSelectionCheckpoint.priorC32LHeldTicketAssessment
  Assert-C32L ($null -ne $prior) 'preserved prior C32L assessment is missing'
  Assert-C32L ([string]$prior.ticketId -ceq [string]$ticket.ticketId) 'preserved prior C32L ticket differs'
  Assert-C32L ([string]$prior.manifestSha256 -ceq '2BF8ECA4968CF76007CC55603F8C281809A1E53948DFB4C17F9249A3C265328B') 'preserved prior C32L manifest hash differs'
  Assert-C32L ([string]$prior.implementationState -ceq 'gate_repair_implemented_full_preflight_Buy_protected_baseline_hold_no_qualification_claim') 'preserved prior C32L implementation state differs'
  Assert-C32L ((Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $root ([string]$prior.manifestPath))).Hash -ceq [string]$prior.manifestSha256) 'preserved prior C32L ticket bytes differ'
}
Assert-C32L ([bool]$scope.execution.testOrGateWriteAuthorized) 'scope test/gate authority closed'
Assert-C32L (-not [bool]$scope.execution.referenceWriteAuthorized) 'scope reference authority opened'
Assert-C32L (-not [bool]$scope.execution.runtimeWriteAuthorized) 'scope runtime authority opened'
Assert-C32L (-not [bool]$scope.execution.backendWriteAuthorized) 'scope backend authority opened'
Assert-C32L (-not [bool]$scope.execution.buildAuthorized) 'scope build authority opened'
Assert-C32L (-not [bool]$scope.execution.deviceInstallAuthorized) 'scope device authority opened'
Assert-C32L (-not [bool]$scope.execution.externalServiceWriteAuthorized) 'scope external authority opened'
Assert-C32L (-not [bool]$scope.execution.secretValueAccessAuthorized) 'scope secret authority opened'
Assert-C32L ([string]$c29n.state -ceq 'source_qualified_provider_gate_pending') 'C29N authority is not source-qualified'

$socialGate = Get-C32LSlice $c26dGate 'foreach ($literal in @(' 'foreach ($literal in @("''shorts''"'
Assert-C32L ($socialGate.Contains('"key: const Key(''screen04-context-tabs'')"')) 'C26D specialized Social dock assertion missing'
Assert-C32L (-not $socialGate.Contains("'bottomNavigationBar: MoolDestinationNavigationV2('")) 'C26D Social gate still requires the generic wrapper'
Assert-C32L ($c26dGate.Contains('Social=specialized C29N dock')) 'C26D successor identity missing'

$socialDock = Get-C32LSlice $social "key: const Key('screen04-context-tabs')" 'class _SocialOwnershipDockItem extends StatelessWidget'
Assert-C32LSequence $socialDock @(
  'MoolGlobalNavigationV2(',
  "controlKey: const Key('screen04-rail-videos')",
  "controlKey: const Key('screen04-rail-shorts')",
  "controlKey: const Key('screen04-rail-create')",
  "controlKey: const Key('screen04-rail-feed')",
  'MoolGlobalChatNavigationV2('
) 'C29N specialized Social dock'

foreach ($literal in @(
  'bottomNavigationBar: MoolDestinationNavigationV2(',
  "activeId: careNavigation ? 'book' : 'buy'",
  "label: 'Wholesale'",
  "label: 'Orders'",
  "keyName: 'buy-global-chat'"
)) {
  Assert-C32L ($buy.Contains($literal)) "Buy contract changed: $literal"
  Assert-C32L ($c26dGate.Contains($literal)) "C26D Buy assertion removed: $literal"
}
foreach ($literal in @(
  'C29N keeps white Mool left and white Chat right globally',
  "find.byKey(const Key('mool-compact-launcher'))",
  "find.byKey(const Key('mool-global-chat'))"
)) {
  Assert-C32L ($c29nTest.Contains($literal)) "C29N focused acceptance missing: $literal"
}
foreach ($literal in @('moolsocial-compact-destination-rail', 'mool-navigator-family-buy', 'buy-local-tab-wholesale', 'screen04-context-tabs')) {
  Assert-C32L ($c26dTest.Contains($literal)) "C26D focused proof missing: $literal"
}

Write-Output 'C32L C26D/C29N successor gate passed: Social=Mool,Home,Shorts,Create,Feed,Chat; Shop assertions retained; runtimeChanged=false.'
