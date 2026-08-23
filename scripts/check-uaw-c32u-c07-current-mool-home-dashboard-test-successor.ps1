[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C32U([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C32U gate rejected: $Message" }
}
function Resolve-C32U([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C32U ($path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) "owner escaped repository: $RelativePath"
  Assert-C32U (Test-Path -LiteralPath $path -PathType Leaf) "owner missing: $RelativePath"
  return $path
}
function Read-C32U([string]$RelativePath) { return [IO.File]::ReadAllText((Resolve-C32U $RelativePath)) }

$ticketPath = Resolve-C32U 'config/uaw-c32u-personal-mvp-c07-current-mool-home-dashboard-test-successor-ticket.json'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Read-C32U 'config/mvp-scope-gate-state.json' | ConvertFrom-Json
$c32tGate = Read-C32U 'scripts/check-uaw-c32t-c23c-compact-destination-shell-test-successor.ps1'
$testPath = Resolve-C32U 'apps/mobile/test/ui_v2/universal/uaw_personal_mvp_global_mool_navigation_c07_test.dart'
$test = [IO.File]::ReadAllText($testPath)
$rootPath = Resolve-C32U 'apps/mobile/lib/ui_v2/universal/personal_mool_root_v2.dart'

Assert-C32U ([string]$ticket.ticketId -ceq 'UAW-C32U-PERSONAL-MVP-C07-CURRENT-MOOL-HOME-DASHBOARD-TEST-SUCCESSOR') 'ticket id changed'
Assert-C32U ([string]$ticket.parentOutcome -ceq 'UAW-C32R-PERSONAL-MVP-HISTORICAL-NAVIGATION-TEST-APPLICABILITY-RECONCILIATION') 'parent outcome changed'
Assert-C32U ([string]$ticket.classification -ceq 'mvp_supporting') 'classification changed'
Assert-C32U (-not [bool]$ticket.authority.runtimeSourceWriteAuthorized) 'ticket runtime authority opened'
Assert-C32U ([bool]$ticket.authority.testAndGateWriteAuthorized) 'ticket test/gate authority closed'
Assert-C32U (-not [bool]$ticket.authority.backendSourceWriteAuthorized) 'ticket backend authority opened'
Assert-C32U (-not [bool]$ticket.authority.referenceWriteAuthorized) 'ticket reference authority opened'
Assert-C32U (-not [bool]$ticket.authority.baselineReplacementAuthorized) 'ticket baseline authority opened'
Assert-C32U (-not [bool]$ticket.authority.buildAuthorized) 'ticket build authority opened'
Assert-C32U (-not [bool]$ticket.authority.deviceMutationAuthorized) 'ticket device authority opened'
Assert-C32U (-not [bool]$ticket.authority.externalCommunicationAuthorized) 'ticket external authority opened'
Assert-C32U (-not [bool]$ticket.authority.secretValueAccessAuthorized) 'ticket secret authority opened'

$selected = $scope.preTicketSelectionCheckpoint.selectedTicketAssessment
$activeScope = [string]$scope.ticket.id -ceq [string]$ticket.ticketId
if ($activeScope) {
  Assert-C32U ([string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq [string]$ticket.ticketId) 'pre-ticket current ticket differs'
  Assert-C32U ([string]$selected.ticketId -ceq [string]$ticket.ticketId) 'selected assessment ticket differs'
  Assert-C32U ([string]$selected.manifestSha256 -ceq 'F7EEEFE11F85C0C226DE267A0B0AF9937570CFA67E2EBBF103DE77B75A2BD20D') 'selected ticket hash differs'
  Assert-C32U ((Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash -ceq [string]$selected.manifestSha256) 'selected ticket bytes differ'
  Assert-C32U ([string]$selected.implementationState -ceq 'C07_test_only_successor_implemented_C07_5_R03_11_C24B2_4_C26D_1_C27D_1_passed_one_declared_skip_analyzer_clean_runtime_unchanged') 'selected implementation state differs'
} else {
  $priorC32U = $scope.preTicketSelectionCheckpoint.priorC32UQualifiedAssessment
  Assert-C32U ($null -ne $priorC32U) 'preserved prior C32U assessment is missing'
  Assert-C32U ([string]$priorC32U.ticketId -ceq [string]$ticket.ticketId) 'preserved prior C32U ticket differs'
  Assert-C32U ([string]$priorC32U.manifestSha256 -ceq 'F7EEEFE11F85C0C226DE267A0B0AF9937570CFA67E2EBBF103DE77B75A2BD20D') 'preserved prior C32U hash differs'
  Assert-C32U ([string]$priorC32U.implementationState -ceq 'C07_test_only_successor_implemented_C07_5_R03_11_C24B2_4_C26D_1_C27D_1_passed_one_declared_skip_analyzer_clean_runtime_unchanged') 'preserved prior C32U implementation state differs'
  Assert-C32U ((Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash -ceq [string]$priorC32U.manifestSha256) 'preserved prior C32U ticket bytes differ'
}

$priorC32T = $scope.preTicketSelectionCheckpoint.priorC32TQualifiedAssessment
Assert-C32U ($null -ne $priorC32T) 'prior C32T assessment missing'
Assert-C32U ([string]$priorC32T.ticketId -ceq 'UAW-C32T-PERSONAL-MVP-C23C-COMPACT-DESTINATION-SHELL-TEST-SUCCESSOR') 'prior C32T ticket differs'
Assert-C32U ([string]$priorC32T.manifestSha256 -ceq '260B8D51CC0D1A03A0B68872958ADE211155CB16C319C4ABC9B1C90FF415418F') 'prior C32T hash differs'
Assert-C32U ($c32tGate.Contains('priorC32TQualifiedAssessment')) 'C32T historical scope binding is not enforced'
Assert-C32U ($c32tGate.Contains('scopeBinding=')) 'C32T truthful lifecycle output is missing'
Assert-C32U ((Get-FileHash -Algorithm SHA256 -LiteralPath $testPath).Hash -ceq '45CC9BA9A62FF292FE5069B572801564CE55652A5AE24994568589283B56CFDB') 'C32U migrated C07 bytes differ'
Assert-C32U ($test.Contains('Social Feed Mool opens connected menu and Back restores Feed')) 'Social connected-menu case missing'
Assert-C32U ($test.Contains("Key('mool-connected-action-navigator')")) 'connected menu assertion missing'
Assert-C32U ($test.Contains("ValueKey('mool-home-family-`$`{family.id`}')")) 'fixed Home family assertion missing'
Assert-C32U ($test.Contains('compact fixed Home keeps all six families reachable')) 'compact fixed Home case missing'
Assert-C32U ($test.Contains("find.byType(Scrollable), findsNothing")) 'fixed Home no-scroll assertion missing'
Assert-C32U (-not $test.Contains("Key('mool-root-selected')")) 'obsolete root-selected assertion remains'
Assert-C32U (-not $test.Contains("Key('mool-root-main-actions')")) 'obsolete root rail assertion remains'
Assert-C32U ((Get-FileHash -Algorithm SHA256 -LiteralPath $rootPath).Hash -ceq 'F73F8CC73417ED07B2816B41E5B8E3FA7015D5584E7769DC967F61EDF2573FDA') 'production Mool Home owner changed'

Assert-C32U (-not [bool]$scope.execution.runtimeWriteAuthorized) 'scope runtime authority opened'
Assert-C32U ([bool]$scope.execution.testOrGateWriteAuthorized) 'scope test/gate authority closed'
Assert-C32U (-not [bool]$scope.execution.referenceWriteAuthorized) 'scope reference authority opened'
Assert-C32U (-not [bool]$scope.execution.backendWriteAuthorized) 'scope backend authority opened'
Assert-C32U (-not [bool]$scope.execution.buildAuthorized) 'scope build authority opened'
Assert-C32U (-not [bool]$scope.execution.deviceInstallAuthorized) 'scope device authority opened'
Assert-C32U (-not [bool]$scope.execution.externalServiceWriteAuthorized) 'scope external authority opened'
Assert-C32U (-not [bool]$scope.execution.secretValueAccessAuthorized) 'scope secret authority opened'

Write-Output "C32U C07 current Mool Home dashboard test successor gate passed: scopeBinding=$(if ($activeScope) { 'active' } else { 'preservedPrior' }); C07=5; currentAuthorities=17; declaredSkips=1; analyzer=clean; runtime=false; backend=false; build=false; device=false; external=false."
