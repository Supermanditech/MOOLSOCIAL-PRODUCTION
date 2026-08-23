[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar
function Assert-C33D([bool]$Condition, [string]$Message) { if (-not $Condition) { throw "C33D gate rejected: $Message" } }
function Resolve-C33D([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C33D ($path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) "owner escaped repository: $RelativePath"
  Assert-C33D (Test-Path -LiteralPath $path -PathType Leaf) "owner missing: $RelativePath"
  return $path
}
function Hash-C33D([string]$RelativePath) { return (Get-FileHash -Algorithm SHA256 -LiteralPath (Resolve-C33D $RelativePath)).Hash }
function Read-C33D([string]$RelativePath) { return [IO.File]::ReadAllText((Resolve-C33D $RelativePath)) }

$ticketRelative = 'config/uaw-c33d-personal-mvp-four-action-exact-fit-destination-rail-recovery-ticket.json'
$ticket = Read-C33D $ticketRelative | ConvertFrom-Json
$scope = Read-C33D 'config/mvp-scope-gate-state.json' | ConvertFrom-Json
$stateRelative = 'config/post-youtube-four-action-exact-fit-destination-rail-state-c33d.json'
$state = Read-C33D $stateRelative | ConvertFrom-Json
$designRelative = 'apps/mobile/lib/core/design/mool_design_system.dart'
$c16eRelative = 'apps/mobile/test/uaw_personal_mvp_ride_subaction_professional_conformance_c16e_test.dart'
$c16fRelative = 'apps/mobile/test/uaw_personal_mvp_book_subaction_professional_conformance_c16f_test.dart'
$design = Read-C33D $designRelative
$c16e = Read-C33D $c16eRelative
$c16f = Read-C33D $c16fRelative

Assert-C33D ([string]$ticket.ticketId -ceq 'UAW-C33D-PERSONAL-MVP-FOUR-ACTION-EXACT-FIT-DESTINATION-RAIL-RECOVERY') 'ticket id changed'
Assert-C33D ([string]$ticket.classification -ceq 'mvp_required') 'classification changed'
Assert-C33D ((Hash-C33D $ticketRelative) -ceq '651EC79E221CB12025A988F61AB927AAAF85B240F95CEEA05BDFE6FDDD3148B7') 'ticket bytes differ'
Assert-C33D ([bool]$ticket.authority.runtimeSourceWriteAuthorized -and [bool]$ticket.authority.testAndGateWriteAuthorized) 'bounded source authority closed'
Assert-C33D (-not [bool]$ticket.authority.backendSourceWriteAuthorized -and -not [bool]$ticket.authority.buildAuthorized -and -not [bool]$ticket.authority.deviceMutationAuthorized -and -not [bool]$ticket.authority.externalCommunicationAuthorized -and -not [bool]$ticket.authority.secretValueAccessAuthorized) 'ticket live authority opened'

$activeScope = [string]$scope.ticket.id -ceq [string]$ticket.ticketId
$assessment = if ($activeScope) {
  Assert-C33D ([string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq [string]$ticket.ticketId) 'pre-ticket current ticket differs'
  $scope.preTicketSelectionCheckpoint.selectedTicketAssessment
} else {
  $scope.preTicketSelectionCheckpoint.priorC33DQualifiedAssessment
}
Assert-C33D ($null -ne $assessment) 'active or preserved C33D assessment missing'
Assert-C33D ([string]$assessment.ticketId -ceq [string]$ticket.ticketId) 'assessment ticket differs'
Assert-C33D ([string]$assessment.manifestSha256 -ceq '651EC79E221CB12025A988F61AB927AAAF85B240F95CEEA05BDFE6FDDD3148B7') 'assessment ticket hash differs'
$qualifiedAssessmentState = 'source_repair_qualified_61_passed_4_declared_skips_whole_mobile_analyzer_clean_dual_host_gate_passed_device_and_release_held'
$assessmentState = [string]$assessment.implementationState
$qualified = $assessmentState -ceq $qualifiedAssessmentState
Assert-C33D (@('selected_for_bounded_source_implementation', $qualifiedAssessmentState) -ccontains $assessmentState) 'assessment lifecycle state differs'
$expectedEvidencePath = if ($qualified) { 'docs/quality/UAW-C33D-FOUR-ACTION-EXACT-FIT-DESTINATION-RAIL-RECOVERY-QUALIFICATION-20260815.md' } else { $ticketRelative }
Assert-C33D ([string]$assessment.evidencePath -ceq $expectedEvidencePath) 'assessment evidence path differs'
if (-not $activeScope) { Assert-C33D $qualified 'preserved C33D assessment is not qualified' }

Assert-C33D ((Hash-C33D $designRelative) -ceq '9E0CEE1AB94C162AC76B35F130D6788EA10C599572AED737825DF4BB995B0758') 'design owner differs'
Assert-C33D ((Hash-C33D $c16eRelative) -ceq '714EA27B2E19D623B8D7EB4A955B893547F9C2109684A457BED9488DCAF9D695') 'C16E owner differs'
Assert-C33D ((Hash-C33D $c16fRelative) -ceq '72667A6F70006D690458AC8A83C792DF1512B2B52A4B7D899F3301480AC38B0D') 'C16F owner differs'
foreach ($token in @('requiresEdgeToEdgeMinimum', 'minimumClusterWidth > constraints.maxWidth', 'usesMinimumGeometry', 'SingleChildScrollView')) { Assert-C33D ($design.Contains($token)) "exact-fit token missing: $token" }
foreach ($test in @($c16e, $c16f)) {
  Assert-C33D ($test.Contains('tester.view.physicalSize = const Size(320, 568)')) '320x568 test View missing'
  Assert-C33D ($test.Contains('tester.view.devicePixelRatio = 1')) 'test DPR owner missing'
  Assert-C33D (-not $test.Contains('binding.setSurfaceSize')) 'stale surface-only harness remains'
  Assert-C33D (-not $test.Contains('C33D_DIAGNOSTIC')) 'diagnostic output remains'
}
Assert-C33D ($c16e.Contains('width: 181')) 'below-minimum overflow acceptance missing'
Assert-C33D ($c16e.Contains('action.hitTestable()')) 'exact-fit hit-test acceptance missing'

$preserved = Read-C33D 'artifacts/quality/uaw-personal-book-source-audit-20260815-01/02-c16f-book-subaction.log'
Assert-C33D ($preserved.Contains('00:03 +1 -1: Some tests failed.')) 'preserved C16F result missing'
$diagnostic = Read-C33D 'artifacts/quality/uaw-personal-book-source-audit-20260815-01/04-c16e-c33d-rendered-width-diagnostic.log'
Assert-C33D ($diagnostic.Contains('layout=152.0 cluster=182.0 mool=54.0 family=54.0 chat=54.0')) 'rendered-width diagnostic differs'
$successEvidence = @(
  @('05-c16e-c33d-corrected-view.log', '+3: All tests passed!'),
  @('06-c16f-c33d-corrected-view.log', '+2: All tests passed!'),
  @('07-c24e-doctor-salon.log', '+9 ~2: All tests passed!'),
  @('08-c24f-bus.log', '+6 ~2: All tests passed!'),
  @('09-r08-book-exposure.log', '+8: All tests passed!'),
  @('10-book-vertical-post-c33d.log', '+11: All tests passed!'),
  @('11-c20e-post-c33d.log', '+6: All tests passed!'),
  @('12-c17d-post-c33d.log', '+10: All tests passed!'),
  @('13-c27b-post-c33d.log', '+5: All tests passed!'),
  @('14-c27d-post-c33d.log', '+1: All tests passed!')
)
foreach ($evidence in $successEvidence) {
  $base = 'artifacts/quality/uaw-personal-book-source-audit-20260815-01/'
  Assert-C33D ((Read-C33D ($base + $evidence[0])).Contains($evidence[1])) "success summary missing: $($evidence[0])"
  Assert-C33D ((Read-C33D ($base + $evidence[0].Replace('.log', '.exit.txt'))).Trim() -ceq '0') "success exit differs: $($evidence[0])"
}

Assert-C33D ([string]$state.ticketId -ceq [string]$ticket.ticketId) 'machine-state ticket differs'
$expectedState = if ($qualified) { 'source_repair_qualified_device_and_release_acceptance_held' } else { 'source_tests_passed_dual_host_gate_pending' }
$expectedDualHost = if ($qualified) { 'passed' } else { 'pending' }
Assert-C33D ([string]$state.state -ceq $expectedState) 'machine-state lifecycle differs'
Assert-C33D ([int]$state.validation.combined.files -eq 10 -and [int]$state.validation.combined.passed -eq 61 -and [int]$state.validation.combined.failed -eq 0 -and [int]$state.validation.combined.declaredSkips -eq 4) 'combined result differs'
Assert-C33D ([string]$state.validation.wholeMobileAnalyzer -ceq 'clean' -and [string]$state.validation.dualHostGate -ceq $expectedDualHost) 'analyzer or dual-host state differs'
Assert-C33D ([bool]$state.authority.runtimeChanged -and [int]$state.authority.newScreens -eq 0 -and [int]$state.authority.newRoutes -eq 0 -and [int]$state.authority.newBackendOwners -eq 0) 'bounded runtime scope differs'
Assert-C33D (-not [bool]$state.authority.backendChanged -and -not [bool]$state.authority.buildAuthorized -and -not [bool]$state.authority.deviceMutationAuthorized -and -not [bool]$state.authority.externalServiceWriteAuthorized -and -not [bool]$state.authority.secretValueAccessAuthorized) 'machine live authority opened'
if ($activeScope) {
  Assert-C33D ([bool]$scope.execution.runtimeWriteAuthorized -eq (-not $qualified)) 'runtime authority does not match lifecycle'
  Assert-C33D ([bool]$scope.execution.testOrGateWriteAuthorized -eq (-not $qualified)) 'test/gate authority does not match lifecycle'
} else {
  Assert-C33D (-not [bool]$scope.execution.runtimeWriteAuthorized -and -not [bool]$scope.execution.testOrGateWriteAuthorized) 'preserved qualified scope reopened source authority'
}
Assert-C33D (-not [bool]$scope.execution.backendWriteAuthorized -and -not [bool]$scope.execution.buildAuthorized -and -not [bool]$scope.execution.deviceInstallAuthorized -and -not [bool]$scope.execution.externalServiceWriteAuthorized -and -not [bool]$scope.execution.secretValueAccessAuthorized) 'scope live authority opened'
foreach ($gate in @('scripts/check-uaw-c33a-c20e-current-local-destination-rail-test-successor.ps1', 'scripts/check-uaw-c33b-c17d-c21e-current-local-destination-rail-test-successor.ps1', 'scripts/check-uaw-c33c-ride-compact-four-action-destination-rail-recovery.ps1')) { Assert-C33D ((Read-C33D $gate).Contains('C33D')) "predecessor lacks C33D binding: $gate" }
Resolve-C33D 'docs/quality/UAW-C33D-FOUR-ACTION-EXACT-FIT-DESTINATION-RAIL-CONTRACT-20260815.md' | Out-Null
Resolve-C33D 'docs/quality/UAW-C33D-FOUR-ACTION-EXACT-FIT-DESTINATION-RAIL-RECOVERY-QUALIFICATION-20260815.md' | Out-Null

Write-Output "C33D four-action exact-fit destination rail qualification gate passed: lifecycle=$(if ($qualified) { 'qualified' } else { 'prequalification' }); source=61 passed + 4 declared skips; whole-mobile analyzer clean; runtime=$(if ($activeScope) { [bool]$scope.execution.runtimeWriteAuthorized } else { 'closed' }); new screens/routes/backend=0/0/0; build=false; device=false; external=false."
