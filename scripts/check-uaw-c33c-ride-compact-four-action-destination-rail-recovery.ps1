[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar
function Assert-C33C([bool]$Condition, [string]$Message) { if (-not $Condition) { throw "C33C gate rejected: $Message" } }
function Resolve-C33C([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C33C ($path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) "owner escaped repository: $RelativePath"
  Assert-C33C (Test-Path -LiteralPath $path -PathType Leaf) "owner missing: $RelativePath"
  return $path
}
function Hash-C33C([string]$RelativePath) { return (Get-FileHash -Algorithm SHA256 -LiteralPath (Resolve-C33C $RelativePath)).Hash }
function Read-C33C([string]$RelativePath) { return [IO.File]::ReadAllText((Resolve-C33C $RelativePath)) }

$ticketRelative = 'config/uaw-c33c-personal-mvp-ride-compact-four-action-destination-rail-recovery-ticket.json'
$ticketPath = Resolve-C33C $ticketRelative
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Read-C33C 'config/mvp-scope-gate-state.json' | ConvertFrom-Json
$stateRelative = 'config/post-youtube-ride-compact-four-action-destination-rail-state-c33c.json'
$state = Read-C33C $stateRelative | ConvertFrom-Json
$designRelative = 'apps/mobile/lib/core/design/mool_design_system.dart'
$testRelative = 'apps/mobile/test/uaw_personal_mvp_ride_subaction_professional_conformance_c16e_test.dart'
$design = Read-C33C $designRelative
$test = Read-C33C $testRelative

Assert-C33C ([string]$ticket.ticketId -ceq 'UAW-C33C-PERSONAL-MVP-RIDE-COMPACT-FOUR-ACTION-DESTINATION-RAIL-RECOVERY') 'ticket id changed'
Assert-C33C ([string]$ticket.classification -ceq 'mvp_required') 'classification changed'
Assert-C33C ([bool]$ticket.authority.runtimeSourceWriteAuthorized -and [bool]$ticket.authority.testAndGateWriteAuthorized) 'bounded source authority closed'
Assert-C33C (-not [bool]$ticket.authority.backendSourceWriteAuthorized -and -not [bool]$ticket.authority.buildAuthorized -and -not [bool]$ticket.authority.deviceMutationAuthorized -and -not [bool]$ticket.authority.externalCommunicationAuthorized -and -not [bool]$ticket.authority.secretValueAccessAuthorized) 'ticket live authority opened'
Assert-C33C ((Hash-C33C $ticketRelative) -ceq 'C8721DB35BB6D145024F2CD45465D30CE2C1735F3DF5D60C23FFC01F5ACA046C') 'ticket bytes differ'

$activeScope = [string]$scope.ticket.id -ceq [string]$ticket.ticketId
$assessment = if ($activeScope) {
  Assert-C33C ([string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq [string]$ticket.ticketId) 'pre-ticket current ticket differs'
  $scope.preTicketSelectionCheckpoint.selectedTicketAssessment
} else {
  $scope.preTicketSelectionCheckpoint.priorC33CQualifiedAssessment
}
Assert-C33C ($null -ne $assessment) 'active or preserved C33C assessment missing'
Assert-C33C ([string]$assessment.ticketId -ceq [string]$ticket.ticketId) 'assessment ticket differs'
Assert-C33C ([string]$assessment.manifestSha256 -ceq 'C8721DB35BB6D145024F2CD45465D30CE2C1735F3DF5D60C23FFC01F5ACA046C') 'assessment ticket hash differs'
Assert-C33C ([string]$assessment.implementationState -ceq 'source_repair_qualified_48_passed_1_declared_skip_analyzer_17_clean_dual_host_gate_passed_device_and_release_held') 'qualified assessment state differs'

$c33dTicketId = 'UAW-C33D-PERSONAL-MVP-FOUR-ACTION-EXACT-FIT-DESTINATION-RAIL-RECOVERY'
$c33dActive = [string]$scope.ticket.id -ceq $c33dTicketId
$c33dAssessment = if ($c33dActive) {
  Assert-C33C ([string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq $c33dTicketId) 'C33D pre-ticket current ticket differs'
  $scope.preTicketSelectionCheckpoint.selectedTicketAssessment
} else {
  $scope.preTicketSelectionCheckpoint.priorC33DQualifiedAssessment
}
$c33dBound = $null -ne $c33dAssessment
if ($c33dBound) {
  $c33dTicketRelative = 'config/uaw-c33d-personal-mvp-four-action-exact-fit-destination-rail-recovery-ticket.json'
  Assert-C33C ([string]$c33dAssessment.ticketId -ceq $c33dTicketId) 'C33D assessment ticket differs'
  Assert-C33C ([string]$c33dAssessment.manifestSha256 -ceq '651EC79E221CB12025A988F61AB927AAAF85B240F95CEEA05BDFE6FDDD3148B7') 'C33D assessment hash differs'
  Assert-C33C ((Hash-C33C $c33dTicketRelative) -ceq [string]$c33dAssessment.manifestSha256) 'C33D ticket bytes differ'
}
$expectedDesignHash = if ($c33dBound) { '9E0CEE1AB94C162AC76B35F130D6788EA10C599572AED737825DF4BB995B0758' } else { '6430044F7DA73EB54634A6EE54F9664D7CF362B64D073DF58201CA0CE98E9832' }
$expectedC16EHash = if ($c33dBound) { '714EA27B2E19D623B8D7EB4A955B893547F9C2109684A457BED9488DCAF9D695' } else { '4895CECEC1214FDF8C982F6A96BC2545B2591A52DA0A6BDCA00DDBA3D5437381' }
Assert-C33C ((Hash-C33C $designRelative) -ceq $expectedDesignHash) 'C33C/C33D lifecycle-bound design owner differs'
Assert-C33C ((Hash-C33C $testRelative) -ceq $expectedC16EHash) 'C33C/C33D lifecycle-bound C16E owner differs'
foreach ($token in @('minimumClusterWidth', 'requiresOverflow', 'MoolMetrics.minimumTapTarget', 'SingleChildScrollView', 'moolsocial-local-navigation-compact-overflow')) {
  Assert-C33C ($design.Contains($token)) "bounded overflow source token missing: $token"
}
Assert-C33C ($test.Contains('moolsocial-local-navigation-compact-overflow')) 'C16E overflow acceptance missing'
Assert-C33C ($test.Contains('greaterThanOrEqualTo(44)')) 'C16E minimum target acceptance missing'

$hashes = @{
  'apps/mobile/lib/ui_v2/universal/mool_global_navigation_v2.dart' = '591D92DDB791E3EED2D5B3967E7FAA75A63087126A8965C45D070A3357F1DD62'
  'apps/mobile/lib/features/ride/ride_session.dart' = 'B6BAC2FB9C1427ACD10A97DF1DDB8BBE40E0752BD4FBD99734BFEDAAE5B976F8'
  'apps/mobile/lib/features/ride/widgets/ride_widgets.dart' = 'BA0CE8592D7FF813EBFC2841715FAA7F36E08829A924A0E1E6120420642C1B06'
  'apps/mobile/test/ui_v2/universal/uaw_personal_mvp_eat_ride_book_work_adaptive_conformance_c20e_test.dart' = '9F5E461291133081B64CD34D4886E7874DBB24C93A4AB96627AC16EFCBF35382'
  'apps/mobile/test/core/design/mool_remaining_family_clear_glass_conformance_c17d_test.dart' = '9C3C6F199E3D082B54CAE3325E5CE064BA19209FDAA91034924F4DAD83A76BF1'
  'apps/mobile/test/ui_v2/universal/mool_uniform_navigation_design_system_c27b_test.dart' = '6AFDEFE148F0E36A6EEBAE77F214A415344606157471C8D847E004D4F8DE54AD'
  'apps/mobile/test/ui_v2/universal/mool_uniform_navigation_six_family_conformance_c27d_test.dart' = '7E156B6EA30F099E27236998A6ADCFAADAFE8C5E6356C37D687C04EF512FDCFC'
}
foreach ($entry in $hashes.GetEnumerator()) { Assert-C33C ((Hash-C33C $entry.Key) -ceq $entry.Value) "preserved owner differs: $($entry.Key)" }

$failureLog = Read-C33C 'artifacts/quality/uaw-personal-mvp-ride-source-audit-c33c-20260815-01/01-c16e-focused-flutter-test.log'
Assert-C33C ($failureLog.Contains('00:02 +0 -2: Some tests failed.')) 'preserved C16E failure summary missing'
Assert-C33C ((Read-C33C 'artifacts/quality/uaw-personal-mvp-ride-source-audit-c33c-20260815-01/01-c16e-focused-flutter-test.exit.txt').Trim() -ceq '1') 'preserved C16E failure exit differs'
$successEvidence = @(
  @('02-c16e-post-repair-flutter-test.log', '00:02 +2: All tests passed!'),
  @('03-c24d-ride-destination-home.log', '00:02 +6 ~1: All tests passed!'),
  @('04-r07-personal-ride-exposure.log', '00:02 +8: All tests passed!'),
  @('05-ride-vertical-slice.log', '00:06 +10: All tests passed!'),
  @('06-c20e-shared-adaptive.log', '00:02 +6: All tests passed!'),
  @('07-c17d-shared-family.log', '00:01 +10: All tests passed!'),
  @('08-c27b-uniform-navigation.log', '00:01 +5: All tests passed!'),
  @('09-c27d-six-family.log', '00:08 +1: All tests passed!')
)
foreach ($evidence in $successEvidence) {
  $base = 'artifacts/quality/uaw-personal-mvp-ride-source-audit-c33c-20260815-01/'
  Assert-C33C ((Read-C33C ($base + $evidence[0])).Contains($evidence[1])) "success summary missing: $($evidence[0])"
  Assert-C33C ((Read-C33C ($base + $evidence[0].Replace('.log', '.exit.txt'))).Trim() -ceq '0') "success exit differs: $($evidence[0])"
}

Assert-C33C ([string]$state.ticketId -ceq [string]$ticket.ticketId) 'machine-state ticket differs'
Assert-C33C ((Hash-C33C $stateRelative) -ceq 'A61DCA1D73E1D0314CCF3C159647557ADD22E5B93874A5EB0BEA4B3F58CA0AD9') 'machine-state bytes differ'
Assert-C33C ([string]$state.state -ceq 'source_repair_qualified_device_and_release_acceptance_held') 'qualified machine state differs'
Assert-C33C ([int]$state.finding.result.passed -eq 0 -and [int]$state.finding.result.failed -eq 2) 'preserved finding result differs'
Assert-C33C ([int]$state.validation.combined.files -eq 8 -and [int]$state.validation.combined.passed -eq 48 -and [int]$state.validation.combined.failed -eq 0 -and [int]$state.validation.combined.declaredSkips -eq 1) 'combined source result differs'
Assert-C33C ([int]$state.validation.analyzer.owners -eq 17 -and [string]$state.validation.analyzer.state -ceq 'clean' -and [string]$state.validation.dualHostGate -ceq 'passed') 'analyzer or dual-host gate state differs'
Assert-C33C ([bool]$state.authority.runtimeChanged -and [int]$state.authority.newScreens -eq 0 -and [int]$state.authority.newRoutes -eq 0 -and [int]$state.authority.newBackendOwners -eq 0) 'bounded runtime scope differs'
Assert-C33C (-not [bool]$state.authority.backendChanged -and -not [bool]$state.authority.buildAuthorized -and -not [bool]$state.authority.deviceMutationAuthorized -and -not [bool]$state.authority.externalServiceWriteAuthorized -and -not [bool]$state.authority.secretValueAccessAuthorized) 'machine live authority opened'
$expectedTestOrGateAuthority = $false
if ($activeScope) {
  Assert-C33C (-not [bool]$scope.execution.runtimeWriteAuthorized) 'completed C33C scope reopened runtime authority'
}
if ($c33dActive) {
  $c33dQualified = [string]$c33dAssessment.implementationState -ceq 'source_repair_qualified_61_passed_4_declared_skips_whole_mobile_analyzer_clean_dual_host_gate_passed_device_and_release_held'
  Assert-C33C ([bool]$scope.execution.runtimeWriteAuthorized -eq (-not $c33dQualified)) 'active C33D runtime authority does not match implementation lifecycle'
  $expectedTestOrGateAuthority = -not $c33dQualified
}
if (-not ($activeScope -or $c33dActive)) {
  Assert-C33C (-not [bool]$scope.execution.runtimeWriteAuthorized) 'preserved successor scope reopened runtime authority'
}
Assert-C33C ([bool]$scope.execution.testOrGateWriteAuthorized -eq $expectedTestOrGateAuthority) 'scope test/gate authority differs'
Assert-C33C (-not [bool]$scope.execution.backendWriteAuthorized -and -not [bool]$scope.execution.buildAuthorized -and -not [bool]$scope.execution.deviceInstallAuthorized -and -not [bool]$scope.execution.externalServiceWriteAuthorized -and -not [bool]$scope.execution.secretValueAccessAuthorized) 'scope live authority differs'
Resolve-C33C 'docs/quality/UAW-C33C-RIDE-COMPACT-FOUR-ACTION-DESTINATION-RAIL-CONTRACT-20260815.md' | Out-Null
Resolve-C33C 'docs/quality/UAW-C33C-RIDE-COMPACT-FOUR-ACTION-DESTINATION-RAIL-RECOVERY-QUALIFICATION-20260815.md' | Out-Null

Write-Output "C33C Ride compact four-action destination rail qualification gate passed: C33D=$(if ($c33dBound) { 'bound' } else { 'absent' }); source=48 passed + 1 declared skip; analyzer=17 clean; new screens/routes/backend=0/0/0; build=false; device=false; external=false."
