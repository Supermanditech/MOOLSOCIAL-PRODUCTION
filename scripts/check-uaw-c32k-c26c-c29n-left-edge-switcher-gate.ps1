[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C32K([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C32K gate rejected: $Message" }
}

function Read-C32K([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C32K ($path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) "owner escaped repository: $RelativePath"
  Assert-C32K (Test-Path -LiteralPath $path -PathType Leaf) "owner missing: $RelativePath"
  return [IO.File]::ReadAllText($path)
}

function Get-C32KSlice([string]$Text, [string]$Start, [string]$End) {
  $startIndex = $Text.IndexOf($Start, [StringComparison]::Ordinal)
  Assert-C32K ($startIndex -ge 0) "start marker missing: $Start"
  $endIndex = $Text.IndexOf($End, $startIndex + $Start.Length, [StringComparison]::Ordinal)
  Assert-C32K ($endIndex -gt $startIndex) "end marker missing: $End"
  return $Text.Substring($startIndex, $endIndex - $startIndex)
}

function Assert-C32KSequence([string]$Text, [string[]]$Items, [string]$Owner) {
  $cursor = -1
  foreach ($item in $Items) {
    $cursor = $Text.IndexOf($item, $cursor + 1, [StringComparison]::Ordinal)
    Assert-C32K ($cursor -ge 0) "$Owner order/member missing after previous item: $item"
  }
}

$ticket = Read-C32K 'config/uaw-c32k-personal-mvp-c26c-c29n-left-edge-switcher-gate-reconciliation-ticket.json' | ConvertFrom-Json
$scope = Read-C32K 'config/mvp-scope-gate-state.json' | ConvertFrom-Json
$c29nTicket = Read-C32K 'config/uaw-personal-mvp-social-creator-ergonomics-global-edge-consistency-c29n-ticket.json' | ConvertFrom-Json
$navigation = Read-C32K 'apps/mobile/lib/ui_v2/universal/mool_global_navigation_v2.dart'
$social = Read-C32K 'apps/mobile/lib/ui_v2/social/social_v2_consumer.dart'
$c29nTest = Read-C32K 'apps/mobile/test/ui_v2/social/uaw_personal_mvp_social_creator_ergonomics_global_edge_consistency_c29n_test.dart'
$c26cGate = Read-C32K 'scripts/check-personal-embedded-vertical-mool-switcher-c26c.ps1'
$c27cGate = Read-C32K 'scripts/check-personal-uniform-embedded-switcher-c27c.ps1'

Assert-C32K ([string]$ticket.ticketId -ceq 'UAW-C32K-PERSONAL-MVP-C26C-C29N-LEFT-EDGE-SWITCHER-GATE-RECONCILIATION') 'ticket id changed'
Assert-C32K ([string]$ticket.classification -ceq 'mvp_supporting') 'ticket classification changed'
Assert-C32K ([bool]$ticket.authority.testAndGateWriteAuthorized) 'test/gate source authority is closed'
Assert-C32K (-not [bool]$ticket.authority.runtimeSourceWriteAuthorized) 'runtime source authority opened'
Assert-C32K (-not [bool]$ticket.authority.backendSourceWriteAuthorized) 'backend source authority opened'
Assert-C32K (-not [bool]$ticket.authority.buildAuthorized) 'build authority opened'
Assert-C32K (-not [bool]$ticket.authority.deviceMutationAuthorized) 'device authority opened'
Assert-C32K (-not [bool]$ticket.authority.externalCommunicationAuthorized) 'communication authority opened'
$activeScope = [string]$scope.ticket.id -ceq [string]$ticket.ticketId
if (-not $activeScope) {
  $prior = $scope.preTicketSelectionCheckpoint.priorC32KBlockedTicketAssessment
  Assert-C32K ($null -ne $prior) 'preserved prior C32K assessment is missing'
  Assert-C32K ([string]$prior.ticketId -ceq [string]$ticket.ticketId) 'preserved prior C32K ticket differs'
  Assert-C32K ([string]$prior.manifestSha256 -ceq '6E012C083CCF2B42FC584DFFF2EC982CB880EF7BDEB3D3AA6BF3F0AB1C7ADFDF') 'preserved prior C32K manifest hash differs'
  Assert-C32K ([string]$prior.implementationState -ceq 'gate_repair_implemented_C28E_preflight_reaches_Buy_protected_baseline_hold') 'preserved prior C32K implementation state differs'
  Assert-C32K ((Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $root ([string]$prior.manifestPath))).Hash -ceq [string]$prior.manifestSha256) 'preserved prior C32K ticket bytes differ'
}
Assert-C32K ([bool]$scope.execution.testOrGateWriteAuthorized) 'scope test/gate authority is closed'
Assert-C32K (-not [bool]$scope.execution.referenceWriteAuthorized) 'scope reference authority opened'
Assert-C32K (-not [bool]$scope.execution.runtimeWriteAuthorized) 'scope runtime authority opened'
Assert-C32K (-not [bool]$scope.execution.backendWriteAuthorized) 'scope backend authority opened'
Assert-C32K (-not [bool]$scope.execution.buildAuthorized) 'scope build authority opened'
Assert-C32K (-not [bool]$scope.execution.deviceInstallAuthorized) 'scope device authority opened'
Assert-C32K (-not [bool]$scope.execution.externalServiceWriteAuthorized) 'scope external authority opened'
Assert-C32K (-not [bool]$scope.execution.secretValueAccessAuthorized) 'scope secret authority opened'
Assert-C32K ([string]$c29nTicket.state -ceq 'source_qualified_provider_gate_pending') 'C29N authority is not source-qualified'
Assert-C32K ([string]$c29nTicket.customerOutcome -like '*Mool at the left edge*Chat at the right edge*') 'C29N edge outcome changed'

$global = Get-C32KSlice $navigation 'class MoolGlobalNavigationV2 extends StatefulWidget' 'class _MoolHomeLauncher extends StatefulWidget'
foreach ($literal in @(
  'targetAnchor: widget.compact && widget.compactOverlayAlignEnd',
  '? Alignment.topRight',
  ': Alignment.topLeft',
  'followerAnchor: widget.compact && widget.compactOverlayAlignEnd',
  '? Alignment.bottomRight',
  ': Alignment.bottomLeft'
)) {
  Assert-C32K ($global.Contains($literal)) "conditional runtime alignment missing: $literal"
  Assert-C32K ($c26cGate.Contains("'$literal'")) "C26C conditional contract missing: $literal"
}
Assert-C32K (-not $c26cGate.Contains("'targetAnchor: Alignment.topLeft'")) 'C26C still requires obsolete direct target anchor'
Assert-C32K (-not $c26cGate.Contains("'followerAnchor: Alignment.bottomLeft'")) 'C26C still requires obsolete direct follower anchor'
Assert-C32K ($c26cGate.Contains('conditionalAlignment=true; defaultLeft=true')) 'C26C successor pass identity missing'
Assert-C32K ($c27cGate.Contains('C27C uniform embedded switcher gate passed')) 'C27C successor owner missing'

$socialDock = Get-C32KSlice $social "key: const Key('screen04-context-tabs')" 'class _SocialOwnershipDockItem extends StatelessWidget'
Assert-C32KSequence $socialDock @(
  'MoolGlobalNavigationV2(',
  "controlKey: const Key('screen04-rail-videos')",
  "controlKey: const Key('screen04-rail-shorts')",
  "controlKey: const Key('screen04-rail-create')",
  "controlKey: const Key('screen04-rail-feed')",
  'MoolGlobalChatNavigationV2('
) 'C29N Social edge and middle order'
Assert-C32K (-not $socialDock.Contains('compactOverlayAlignEnd: true')) 'current left-edge Social unexpectedly opts into end alignment'

foreach ($literal in @(
  'C29N keeps white Mool left and white Chat right globally',
  "find.byKey(const Key('mool-compact-launcher'))",
  "find.byKey(const Key('mool-global-chat'))",
  'lessThan(tester.getCenter(chat).dx)'
)) {
  Assert-C32K ($c29nTest.Contains($literal)) "C29N focused edge acceptance missing: $literal"
}

Write-Output 'C32K C26C/C29N successor gate passed: Mool=left; Chat=right; Social=middle; conditionalAlignment=true; runtimeChanged=false.'
