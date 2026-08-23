[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C32I([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C32I gate rejected: $Message" }
}

function Read-C32I([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C32I ($path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) "owner escaped repository: $RelativePath"
  Assert-C32I (Test-Path -LiteralPath $path -PathType Leaf) "owner missing: $RelativePath"
  return [IO.File]::ReadAllText($path)
}

function Assert-C32ISequence([string]$Text, [string[]]$Items, [string]$Owner) {
  $cursor = -1
  foreach ($item in $Items) {
    $cursor = $Text.IndexOf($item, $cursor + 1, [StringComparison]::Ordinal)
    Assert-C32I ($cursor -ge 0) "$Owner order/member missing after previous item: $item"
  }
}

$ticket = Read-C32I 'config/uaw-c32i-personal-mvp-c27d-social-home-first-gate-successor-reconciliation-ticket.json' | ConvertFrom-Json
$c29eTicket = Read-C32I 'config/uaw-personal-mvp-social-youtube-native-ownership-redesign-c29e-ticket.json' | ConvertFrom-Json
$scope = Read-C32I 'config/mvp-scope-gate-state.json' | ConvertFrom-Json
$navigation = Read-C32I 'apps/mobile/lib/ui_v2/universal/mool_global_navigation_v2.dart'
$c27dGate = Read-C32I 'scripts/check-personal-uniform-navigation-six-family-conformance-c27d.ps1'
$c29eTest = Read-C32I 'apps/mobile/test/ui_v2/social/uaw_personal_mvp_social_youtube_native_home_dock_c29e_test.dart'
$c27dTest = Read-C32I 'apps/mobile/test/ui_v2/universal/mool_uniform_navigation_six_family_conformance_c27d_test.dart'

Assert-C32I ([string]$ticket.ticketId -ceq 'UAW-C32I-PERSONAL-MVP-C27D-SOCIAL-HOME-FIRST-GATE-SUCCESSOR-RECONCILIATION') 'ticket id changed'
Assert-C32I ([string]$ticket.classification -ceq 'mvp_supporting') 'ticket classification changed'
Assert-C32I ([bool]$ticket.authority.testAndGateWriteAuthorized) 'test/gate source authority is closed'
Assert-C32I (-not [bool]$ticket.authority.runtimeSourceWriteAuthorized) 'runtime source authority opened'
Assert-C32I (-not [bool]$ticket.authority.backendSourceWriteAuthorized) 'backend source authority opened'
Assert-C32I (-not [bool]$ticket.authority.buildAuthorized) 'build authority opened'
Assert-C32I (-not [bool]$ticket.authority.deviceMutationAuthorized) 'device authority opened'
Assert-C32I (-not [bool]$ticket.authority.externalCommunicationAuthorized) 'external communication authority opened'
Assert-C32I ([string]$scope.ticket.id -ceq [string]$ticket.ticketId) 'scope ticket differs'
Assert-C32I ([bool]$scope.execution.testOrGateWriteAuthorized) 'scope test/gate authority is closed'
Assert-C32I (-not [bool]$scope.execution.runtimeWriteAuthorized) 'scope runtime authority opened'
Assert-C32I (-not [bool]$scope.execution.backendWriteAuthorized) 'scope backend authority opened'
Assert-C32I (-not [bool]$scope.execution.buildAuthorized) 'scope build authority opened'
Assert-C32I (-not [bool]$scope.execution.deviceInstallAuthorized) 'scope device authority opened'
Assert-C32I ([string]$c29eTicket.state -like 'source_qualified*') 'C29E Home-first predecessor is not source-qualified'

$familyStart = $navigation.IndexOf('const moolActionFamilies = <MoolActionFamilySpec>[', [StringComparison]::Ordinal)
$familyEnd = $navigation.IndexOf('final personalMoolRootActions', $familyStart, [StringComparison]::Ordinal)
Assert-C32I ($familyStart -ge 0 -and $familyEnd -gt $familyStart) 'current canonical family owner missing'
$families = $navigation.Substring($familyStart, $familyEnd - $familyStart)
Assert-C32ISequence $families @(
  "id: 'social'", "id: 'videos'", "label: 'Home'",
  "id: 'shorts'", "label: 'Shorts'",
  "id: 'create'", "label: 'Create'",
  "id: 'feed'", "label: 'Feed'",
  "id: 'buy'", "id: 'eat'", "id: 'ride'", "id: 'book'", "id: 'work'"
) 'current C29E Home-first family projection'

$currentGateSequence = '"id: ''social''", "id: ''videos''", "id: ''shorts''", "id: ''create''", "id: ''feed''"'
$supersededGateSequence = '"id: ''social''", "id: ''shorts''", "id: ''videos''", "id: ''feed''", "id: ''create''"'
Assert-C32I ($c27dGate.Contains($currentGateSequence)) 'C27D does not require the current Home-first Social order'
Assert-C32I (-not $c27dGate.Contains($supersededGateSequence)) 'C27D still contains the superseded Shorts-first Social order'
foreach ($literal in @(
  '"label: ''Home''", "label: ''Shorts''", "label: ''Create''", "label: ''Feed''"',
  'C29EHomeFirst=true',
  '"id: ''buy''", "id: ''wholesale''", "id: ''orders''"',
  '"id: ''eat''", "id: ''order''", "id: ''table''"',
  '"id: ''ride''", "id: ''bike''", "id: ''auto''", "id: ''cab''", "id: ''bus''"',
  '"id: ''book''", "id: ''doctor''", "id: ''medicine''", "id: ''salon''"',
  '"id: ''work''", "id: ''earn''", "id: ''workspace''"'
)) {
  Assert-C32I ($c27dGate.Contains($literal)) "C27D retained contract missing: $literal"
}

Assert-C32I ($c29eTest.Contains("for (final id in const ['videos', 'shorts', 'create', 'feed'])")) 'C29E focused test does not bind the accepted Social order'
Assert-C32I ($c29eTest.Contains("find.byKey(const Key('screen04-youtube-home-header'))")) 'C29E focused Home owner assertion missing'
Assert-C32I ($c27dTest.Contains('C27D all real family and subaction states share one system')) 'C27D focused six-family acceptance owner missing'

Write-Output 'C32I C27D successor gate passed: actor=Personal user; Social=Home,Shorts,Create,Feed; runtimeChanged=false; build=false; device=false.'
