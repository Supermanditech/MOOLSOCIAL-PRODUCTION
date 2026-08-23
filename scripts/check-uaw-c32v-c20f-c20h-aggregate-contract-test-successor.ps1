[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar
function Assert-C32V([bool]$Condition, [string]$Message) { if (-not $Condition) { throw "C32V gate rejected: $Message" } }
function Resolve-C32V([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C32V ($path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) "owner escaped repository: $RelativePath"
  Assert-C32V (Test-Path -LiteralPath $path -PathType Leaf) "owner missing: $RelativePath"
  return $path
}
function Read-C32V([string]$RelativePath) { return [IO.File]::ReadAllText((Resolve-C32V $RelativePath)) }

$ticketPath = Resolve-C32V 'config/uaw-c32v-personal-mvp-c20f-c20h-aggregate-contract-test-successor-ticket.json'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Read-C32V 'config/mvp-scope-gate-state.json' | ConvertFrom-Json
$c32uGate = Read-C32V 'scripts/check-uaw-c32u-c07-current-mool-home-dashboard-test-successor.ps1'
$testPath = Resolve-C32V 'apps/mobile/test/ui_v2/universal/uaw_personal_mvp_subaction_professional_regression_c20f_test.dart'
$test = [IO.File]::ReadAllText($testPath)
$statePath = Resolve-C32V 'config/mvp-personal-subaction-professional-recovery-regression-c20.json'
$c10ePath = Resolve-C32V 'apps/mobile/test/ui_v2/universal/uaw_personal_mvp_global_navigation_motion_containment_c10e_test.dart'

Assert-C32V ([string]$ticket.ticketId -ceq 'UAW-C32V-PERSONAL-MVP-C20F-C20H-AGGREGATE-CONTRACT-TEST-SUCCESSOR') 'ticket id changed'
Assert-C32V ([string]$ticket.classification -ceq 'mvp_supporting') 'classification changed'
Assert-C32V (-not [bool]$ticket.authority.runtimeSourceWriteAuthorized) 'ticket runtime authority opened'
Assert-C32V ([bool]$ticket.authority.testAndGateWriteAuthorized) 'ticket test/gate authority closed'
Assert-C32V (-not [bool]$ticket.authority.backendSourceWriteAuthorized) 'ticket backend authority opened'
Assert-C32V (-not [bool]$ticket.authority.buildAuthorized) 'ticket build authority opened'
Assert-C32V (-not [bool]$ticket.authority.deviceMutationAuthorized) 'ticket device authority opened'
Assert-C32V (-not [bool]$ticket.authority.externalCommunicationAuthorized) 'ticket external authority opened'
Assert-C32V (-not [bool]$ticket.authority.secretValueAccessAuthorized) 'ticket secret authority opened'

$selected = $scope.preTicketSelectionCheckpoint.selectedTicketAssessment
$activeScope = [string]$scope.ticket.id -ceq [string]$ticket.ticketId
if ($activeScope) {
  Assert-C32V ([string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq [string]$ticket.ticketId) 'pre-ticket current ticket differs'
  Assert-C32V ([string]$selected.ticketId -ceq [string]$ticket.ticketId) 'selected ticket differs'
  Assert-C32V ([string]$selected.manifestSha256 -ceq '04C4ADAEA414053B8C0CFE45C35B74E8A40D7E383E5FF6FEE62DA8FD97AE9A8B') 'selected ticket hash differs'
  Assert-C32V ((Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash -ceq [string]$selected.manifestSha256) 'selected ticket bytes differ'
  Assert-C32V ([string]$selected.implementationState -ceq 'C20F_test_only_successor_implemented_C20F_4_C10E_8_passed_analyzer_clean_machine_state_runtime_unchanged') 'selected implementation state differs'
} else {
  $priorC32V = $scope.preTicketSelectionCheckpoint.priorC32VQualifiedAssessment
  Assert-C32V ($null -ne $priorC32V) 'preserved prior C32V assessment is missing'
  Assert-C32V ([string]$priorC32V.ticketId -ceq [string]$ticket.ticketId) 'preserved prior C32V ticket differs'
  Assert-C32V ([string]$priorC32V.manifestSha256 -ceq '04C4ADAEA414053B8C0CFE45C35B74E8A40D7E383E5FF6FEE62DA8FD97AE9A8B') 'preserved prior C32V hash differs'
  Assert-C32V ([string]$priorC32V.implementationState -ceq 'C20F_test_only_successor_implemented_C20F_4_C10E_8_passed_analyzer_clean_machine_state_runtime_unchanged') 'preserved prior C32V implementation state differs'
  Assert-C32V ((Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash -ceq [string]$priorC32V.manifestSha256) 'preserved prior C32V ticket bytes differ'
}

$priorC32U = $scope.preTicketSelectionCheckpoint.priorC32UQualifiedAssessment
Assert-C32V ($null -ne $priorC32U) 'prior C32U assessment missing'
Assert-C32V ([string]$priorC32U.ticketId -ceq 'UAW-C32U-PERSONAL-MVP-C07-CURRENT-MOOL-HOME-DASHBOARD-TEST-SUCCESSOR') 'prior C32U ticket differs'
Assert-C32V ([string]$priorC32U.manifestSha256 -ceq 'F7EEEFE11F85C0C226DE267A0B0AF9937570CFA67E2EBBF103DE77B75A2BD20D') 'prior C32U hash differs'
Assert-C32V ($c32uGate.Contains('priorC32UQualifiedAssessment')) 'C32U historical scope binding is not enforced'
Assert-C32V ($c32uGate.Contains('scopeBinding=')) 'C32U truthful lifecycle output is missing'
Assert-C32V ((Get-FileHash -Algorithm SHA256 -LiteralPath $testPath).Hash -ceq '7DDEC307CD143DC428F409992526011B9B645E96C912BD5EA879F1D90103D2F9') 'C32V migrated C20F bytes differ'
Assert-C32V ($test.Contains('c20h_r60_19_installed_checksum_matched_device_matrix_and_founder_acceptance_pending')) 'exact C20H state assertion missing'
Assert-C32V ($test.Contains('deep Eat contextual switch and connected Work switch preserve one anchor')) 'current Eat/Work C10E token missing'
Assert-C32V ($test.Contains('Social connected self-route and Back keep exact ownership')) 'current Social C10E token missing'
Assert-C32V (-not $test.Contains("contains('c20f')")) 'obsolete partial C20F state assertion remains'
Assert-C32V ((Get-FileHash -Algorithm SHA256 -LiteralPath $statePath).Hash -ceq 'AD1A66DA763D988879A066AFA9440E27380ACADCFE0893D1F63045BD61E6F456') 'C20 machine state changed'
Assert-C32V ((Get-FileHash -Algorithm SHA256 -LiteralPath $c10ePath).Hash -ceq 'D581F87BF2335186AFE09B465DEF4C6E37EA25AB18B52A55010F2B9D321A765B') 'C10E authority changed'

Assert-C32V (-not [bool]$scope.execution.runtimeWriteAuthorized) 'scope runtime authority opened'
Assert-C32V ([bool]$scope.execution.testOrGateWriteAuthorized) 'scope test/gate authority closed'
Assert-C32V (-not [bool]$scope.execution.backendWriteAuthorized) 'scope backend authority opened'
Assert-C32V (-not [bool]$scope.execution.buildAuthorized) 'scope build authority opened'
Assert-C32V (-not [bool]$scope.execution.deviceInstallAuthorized) 'scope device authority opened'
Assert-C32V (-not [bool]$scope.execution.externalServiceWriteAuthorized) 'scope external authority opened'
Assert-C32V (-not [bool]$scope.execution.secretValueAccessAuthorized) 'scope secret authority opened'

Write-Output "C32V C20F C20H aggregate contract test successor gate passed: scopeBinding=$(if ($activeScope) { 'active' } else { 'preservedPrior' }); C20F=4; C10E=8; analyzer=clean; machineState=preserved; runtime=false; build=false; device=false; external=false."
