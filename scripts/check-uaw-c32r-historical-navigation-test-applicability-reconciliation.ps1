[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C32R([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C32R gate rejected: $Message" }
}

function Resolve-C32R([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C32R ($path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) "owner escaped repository: $RelativePath"
  Assert-C32R (Test-Path -LiteralPath $path -PathType Leaf) "owner missing: $RelativePath"
  return $path
}

function Read-C32R([string]$RelativePath) {
  return [IO.File]::ReadAllText((Resolve-C32R $RelativePath))
}

function Assert-HashC32R([string]$RelativePath, [string]$ExpectedHash) {
  $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath (Resolve-C32R $RelativePath)).Hash
  Assert-C32R ($actual -ceq $ExpectedHash) "owner bytes changed: $RelativePath"
}

$ticketPath = Resolve-C32R 'config/uaw-c32r-personal-mvp-historical-navigation-test-applicability-reconciliation-ticket.json'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Read-C32R 'config/mvp-scope-gate-state.json' | ConvertFrom-Json
$state = Read-C32R 'config/post-youtube-historical-navigation-test-applicability-state-c32r.json' | ConvertFrom-Json
$c32qGate = Read-C32R 'scripts/check-uaw-c32q-retailer-business-services-compact-accessibility-overflow.ps1'

Assert-C32R ([string]$ticket.ticketId -ceq 'UAW-C32R-PERSONAL-MVP-HISTORICAL-NAVIGATION-TEST-APPLICABILITY-RECONCILIATION') 'ticket id changed'
Assert-C32R ([string]$ticket.parentOutcome -ceq 'UAW-C32Q-PERSONAL-MVP-RETAILER-BUSINESS-SERVICES-COMPACT-ACCESSIBILITY-OVERFLOW') 'parent outcome changed'
Assert-C32R ([string]$ticket.classification -ceq 'mvp_supporting') 'classification changed'
Assert-C32R (-not [bool]$ticket.authority.runtimeSourceWriteAuthorized) 'ticket runtime authority opened'
Assert-C32R (-not [bool]$ticket.authority.backendSourceWriteAuthorized) 'ticket backend authority opened'
Assert-C32R ([bool]$ticket.authority.testAndGateWriteAuthorized) 'ticket test/gate authority closed'
Assert-C32R (-not [bool]$ticket.authority.referenceWriteAuthorized) 'ticket reference authority opened'
Assert-C32R (-not [bool]$ticket.authority.baselineReplacementAuthorized) 'ticket baseline authority opened'
Assert-C32R (-not [bool]$ticket.authority.buildAuthorized) 'ticket build authority opened'
Assert-C32R (-not [bool]$ticket.authority.deviceMutationAuthorized) 'ticket device authority opened'
Assert-C32R (-not [bool]$ticket.authority.externalCommunicationAuthorized) 'ticket external communication authority opened'
Assert-C32R (-not [bool]$ticket.authority.secretValueAccessAuthorized) 'ticket secret authority opened'

$selected = $scope.preTicketSelectionCheckpoint.selectedTicketAssessment
$activeScope = [string]$scope.ticket.id -ceq [string]$ticket.ticketId
if ($activeScope) {
  Assert-C32R ([string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq [string]$ticket.ticketId) 'pre-ticket current ticket differs'
  Assert-C32R ([string]$selected.ticketId -ceq [string]$ticket.ticketId) 'selected assessment ticket differs'
  Assert-C32R ([string]$selected.manifestSha256 -ceq '0F2E3CB70DCD4BD62747204211A68B258E3CCFAA9454A3FABAA6A86C91B767B2') 'selected ticket manifest hash differs'
  Assert-C32R ((Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash -ceq [string]$selected.manifestSha256) 'selected ticket bytes differ'
  Assert-C32R ([string]$selected.implementationState -ceq 'five_historical_files_individually_audited_6_passed_30_failed_seven_current_authorities_33_passed_one_declared_skip_zero_runtime_defects_five_test_successors_required') 'selected implementation state differs'
} else {
  $priorC32R = $scope.preTicketSelectionCheckpoint.priorC32RAuditAssessment
  Assert-C32R ($null -ne $priorC32R) 'preserved prior C32R assessment is missing'
  Assert-C32R ([string]$priorC32R.ticketId -ceq [string]$ticket.ticketId) 'preserved prior C32R ticket differs'
  Assert-C32R ([string]$priorC32R.manifestSha256 -ceq '0F2E3CB70DCD4BD62747204211A68B258E3CCFAA9454A3FABAA6A86C91B767B2') 'preserved prior C32R manifest hash differs'
  Assert-C32R ([string]$priorC32R.implementationState -ceq 'five_historical_files_individually_audited_6_passed_30_failed_seven_current_authorities_33_passed_one_declared_skip_zero_runtime_defects_five_test_successors_required') 'preserved prior C32R implementation state differs'
  Assert-C32R ((Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash -ceq [string]$priorC32R.manifestSha256) 'preserved prior C32R ticket bytes differ'
}

Assert-C32R ([string]$state.ticketId -ceq [string]$ticket.ticketId) 'audit state ticket differs'
Assert-C32R ([int]$state.historicalAudit.passed -eq 6) 'historical pass count differs'
Assert-C32R ([int]$state.historicalAudit.failed -eq 30) 'historical failure count differs'
Assert-C32R ([int]$state.currentAuthority.passed -eq 33) 'current-authority pass count differs'
Assert-C32R ([int]$state.currentAuthority.declaredSkips -eq 1) 'current-authority declared skip count differs'
Assert-C32R ([int]$state.currentAuthority.failed -eq 0) 'current-authority failure count differs'

$priorC32Q = $scope.preTicketSelectionCheckpoint.priorC32QSourceQualifiedTicketAssessment
Assert-C32R ($null -ne $priorC32Q) 'prior C32Q assessment missing'
Assert-C32R ([string]$priorC32Q.ticketId -ceq 'UAW-C32Q-PERSONAL-MVP-RETAILER-BUSINESS-SERVICES-COMPACT-ACCESSIBILITY-OVERFLOW') 'prior C32Q ticket differs'
Assert-C32R ([string]$priorC32Q.manifestSha256 -ceq 'A82E652697645BDBAA5DF71B374C2EACB8B0ABB9EAF99FD312F10AFDF806523C') 'prior C32Q manifest hash differs'
Assert-C32R ([string]$priorC32Q.implementationState -ceq 'exact_shared_dock_owner_repaired_two_identical_acceptance_cycles_and_final_state_rebind_cycle_passed_source_qualified') 'prior C32Q implementation state differs'
Assert-C32R ($c32qGate.Contains('priorC32QSourceQualifiedTicketAssessment')) 'C32Q historical scope binding is not enforced'
Assert-C32R ($c32qGate.Contains('scopeBinding=')) 'C32Q truthful lifecycle output is missing'

Assert-HashC32R 'apps/mobile/lib/core/design/mool_design_system.dart' 'D66C9A8E34E49FF58DF25EF6DC0694B22DB91E5C33B6A04CA5CD7A63C7F76BFE'
if ($activeScope) {
  Assert-HashC32R 'apps/mobile/test/core/design/mool_inner_chroma_emission_c22f_test.dart' ([string]$state.historicalAudit.preMigrationHashes.'apps/mobile/test/core/design/mool_inner_chroma_emission_c22f_test.dart')
  Assert-HashC32R 'apps/mobile/test/ui_v2/universal/mool_single_home_launcher_shell_c23c_test.dart' ([string]$state.historicalAudit.preMigrationHashes.'apps/mobile/test/ui_v2/universal/mool_single_home_launcher_shell_c23c_test.dart')
  Assert-HashC32R 'apps/mobile/test/ui_v2/universal/uaw_personal_mvp_global_mool_navigation_c07_test.dart' ([string]$state.historicalAudit.preMigrationHashes.'apps/mobile/test/ui_v2/universal/uaw_personal_mvp_global_mool_navigation_c07_test.dart')
  Assert-HashC32R 'apps/mobile/test/ui_v2/universal/uaw_personal_mvp_subaction_professional_regression_c20f_test.dart' ([string]$state.historicalAudit.preMigrationHashes.'apps/mobile/test/ui_v2/universal/uaw_personal_mvp_subaction_professional_regression_c20f_test.dart')
  Assert-HashC32R 'apps/mobile/test/ui_v2/universal/uaw_r15_personal_copy_fitment_accessibility_test.dart' ([string]$state.historicalAudit.preMigrationHashes.'apps/mobile/test/ui_v2/universal/uaw_r15_personal_copy_fitment_accessibility_test.dart')
}

Assert-C32R (-not [bool]$scope.execution.runtimeWriteAuthorized) 'scope runtime authority opened'
Assert-C32R ([bool]$scope.execution.testOrGateWriteAuthorized) 'scope test/gate authority closed'
Assert-C32R (-not [bool]$scope.execution.referenceWriteAuthorized) 'scope reference authority opened'
Assert-C32R (-not [bool]$scope.execution.backendWriteAuthorized) 'scope backend authority opened'
Assert-C32R (-not [bool]$scope.execution.buildAuthorized) 'scope build authority opened'
Assert-C32R (-not [bool]$scope.execution.deviceInstallAuthorized) 'scope device authority opened'
Assert-C32R (-not [bool]$scope.execution.externalServiceWriteAuthorized) 'scope external authority opened'
Assert-C32R (-not [bool]$scope.execution.secretValueAccessAuthorized) 'scope secret authority opened'
Assert-C32R (-not [bool]$scope.protectedCandidateState.protectedBaselineUpdated) 'Buy protected baseline was changed'
Assert-C32R ([bool]$scope.protectedCandidateState.founderAcceptancePending) 'Buy protected founder hold was removed'

Write-Output "C32R historical navigation applicability reconciliation gate passed: scopeBinding=$(if ($activeScope) { 'active' } else { 'preservedPrior' }); historical=6/30; current=33/0/1skip; runtimeChanged=false; C32Q=preservedPrior; backend=false; build=false; device=false; external=false."
