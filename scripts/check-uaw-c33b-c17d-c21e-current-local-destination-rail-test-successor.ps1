[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar
function Assert-C33B([bool]$Condition, [string]$Message) { if (-not $Condition) { throw "C33B gate rejected: $Message" } }
function Resolve-C33B([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C33B ($path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) "owner escaped repository: $RelativePath"
  Assert-C33B (Test-Path -LiteralPath $path -PathType Leaf) "owner missing: $RelativePath"
  return $path
}
function Read-C33B([string]$RelativePath) { return [IO.File]::ReadAllText((Resolve-C33B $RelativePath)) }

$ticketPath = Resolve-C33B 'config/uaw-c33b-personal-mvp-c17d-c21e-current-local-destination-rail-test-successor-ticket.json'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Read-C33B 'config/mvp-scope-gate-state.json' | ConvertFrom-Json
$c33aGate = Read-C33B 'scripts/check-uaw-c33a-c20e-current-local-destination-rail-test-successor.ps1'
$testPath = Resolve-C33B 'apps/mobile/test/core/design/mool_remaining_family_clear_glass_conformance_c17d_test.dart'
$test = [IO.File]::ReadAllText($testPath)
$designPath = Resolve-C33B 'apps/mobile/lib/core/design/mool_design_system.dart'
$c20ePath = Resolve-C33B 'apps/mobile/test/ui_v2/universal/uaw_personal_mvp_eat_ride_book_work_adaptive_conformance_c20e_test.dart'
$c27bPath = Resolve-C33B 'apps/mobile/test/ui_v2/universal/mool_uniform_navigation_design_system_c27b_test.dart'
$c27dPath = Resolve-C33B 'apps/mobile/test/ui_v2/universal/mool_uniform_navigation_six_family_conformance_c27d_test.dart'
$statePath = Resolve-C33B 'config/post-youtube-c17d-c21e-current-local-destination-rail-state-c33b.json'
$state = Get-Content -Raw -LiteralPath $statePath | ConvertFrom-Json
Resolve-C33B 'docs/quality/POST-SEAL-C17D-C21E-REMAINING-FAMILY-GLASS-CONTRACT-FAILURE-20260815.md' | Out-Null
Resolve-C33B 'docs/quality/UAW-C33B-C17D-C21E-CURRENT-LOCAL-DESTINATION-RAIL-TEST-SUCCESSOR-QUALIFICATION-20260815.md' | Out-Null

Assert-C33B ([string]$ticket.ticketId -ceq 'UAW-C33B-PERSONAL-MVP-C17D-C21E-CURRENT-LOCAL-DESTINATION-RAIL-TEST-SUCCESSOR') 'ticket id changed'
Assert-C33B ([string]$ticket.parentOutcome -ceq 'UAW-C33A-PERSONAL-MVP-C20E-CURRENT-LOCAL-DESTINATION-RAIL-TEST-SUCCESSOR') 'parent outcome changed'
Assert-C33B ([string]$ticket.classification -ceq 'mvp_supporting') 'classification changed'
Assert-C33B (-not [bool]$ticket.authority.runtimeSourceWriteAuthorized -and [bool]$ticket.authority.testAndGateWriteAuthorized -and -not [bool]$ticket.authority.backendSourceWriteAuthorized -and -not [bool]$ticket.authority.buildAuthorized -and -not [bool]$ticket.authority.deviceMutationAuthorized -and -not [bool]$ticket.authority.externalCommunicationAuthorized -and -not [bool]$ticket.authority.secretValueAccessAuthorized) 'ticket authority differs'

$selected = $scope.preTicketSelectionCheckpoint.selectedTicketAssessment
$activeScope = [string]$scope.ticket.id -ceq [string]$ticket.ticketId
$assessment = if ($activeScope) {
  Assert-C33B ([string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq [string]$ticket.ticketId) 'pre-ticket current ticket differs'
  $selected
} else {
  $scope.preTicketSelectionCheckpoint.priorC33BQualifiedAssessment
}
Assert-C33B ($null -ne $assessment) 'active or preserved qualified C33B assessment missing'
Assert-C33B ([string]$assessment.ticketId -ceq [string]$ticket.ticketId) 'C33B assessment ticket differs'
Assert-C33B ([string]$assessment.manifestSha256 -ceq 'B3B52E5E5742FE8CA17D1DCA70DB8CE49A3CE239719C49583AA9AE081F221D8A') 'C33B ticket hash differs'
Assert-C33B ((Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash -ceq [string]$assessment.manifestSha256) 'C33B ticket bytes differ'
Assert-C33B ([string]$assessment.implementationState -ceq 'C17D_C21E_test_only_successor_qualified_C17D_10_C20E_6_C27B_5_C27D_1_combined_22_passed_analyzer_clean_runtime_unchanged') 'C33B implementation state differs'
Assert-C33B ([string]$assessment.evidencePath -ceq 'docs/quality/UAW-C33B-C17D-C21E-CURRENT-LOCAL-DESTINATION-RAIL-TEST-SUCCESSOR-QUALIFICATION-20260815.md') 'C33B evidence path differs'

$c33cTicketId = 'UAW-C33C-PERSONAL-MVP-RIDE-COMPACT-FOUR-ACTION-DESTINATION-RAIL-RECOVERY'
$c33cActive = [string]$scope.ticket.id -ceq $c33cTicketId
$c33dTicketId = 'UAW-C33D-PERSONAL-MVP-FOUR-ACTION-EXACT-FIT-DESTINATION-RAIL-RECOVERY'
$c33dActive = [string]$scope.ticket.id -ceq $c33dTicketId
$c33cAssessment = if ($c33cActive) {
  Assert-C33B ([string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq $c33cTicketId) 'C33C pre-ticket current ticket differs'
  $selected
} else {
  $scope.preTicketSelectionCheckpoint.priorC33CQualifiedAssessment
}
$c33cBound = $null -ne $c33cAssessment
if ($c33cBound) {
  $c33cTicketPath = Resolve-C33B 'config/uaw-c33c-personal-mvp-ride-compact-four-action-destination-rail-recovery-ticket.json'
  Assert-C33B ([string]$c33cAssessment.ticketId -ceq $c33cTicketId) 'C33C assessment ticket differs'
  Assert-C33B ([string]$c33cAssessment.manifestSha256 -ceq 'C8721DB35BB6D145024F2CD45465D30CE2C1735F3DF5D60C23FFC01F5ACA046C') 'C33C assessment hash differs'
  Assert-C33B ((Get-FileHash -Algorithm SHA256 -LiteralPath $c33cTicketPath).Hash -ceq [string]$c33cAssessment.manifestSha256) 'C33C ticket bytes differ'
}
$c33dAssessment = if ($c33dActive) {
  Assert-C33B ([string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq $c33dTicketId) 'C33D pre-ticket current ticket differs'
  $selected
} else {
  $scope.preTicketSelectionCheckpoint.priorC33DQualifiedAssessment
}
$c33dBound = $null -ne $c33dAssessment
if ($c33dBound) {
  $c33dTicketPath = Resolve-C33B 'config/uaw-c33d-personal-mvp-four-action-exact-fit-destination-rail-recovery-ticket.json'
  Assert-C33B ([string]$c33dAssessment.ticketId -ceq $c33dTicketId) 'C33D assessment ticket differs'
  Assert-C33B ([string]$c33dAssessment.manifestSha256 -ceq '651EC79E221CB12025A988F61AB927AAAF85B240F95CEEA05BDFE6FDDD3148B7') 'C33D assessment hash differs'
  Assert-C33B ((Get-FileHash -Algorithm SHA256 -LiteralPath $c33dTicketPath).Hash -ceq [string]$c33dAssessment.manifestSha256) 'C33D ticket bytes differ'
}

$priorC33A = $scope.preTicketSelectionCheckpoint.priorC33AQualifiedAssessment
Assert-C33B ($null -ne $priorC33A) 'prior C33A qualified assessment missing'
Assert-C33B ([string]$priorC33A.ticketId -ceq 'UAW-C33A-PERSONAL-MVP-C20E-CURRENT-LOCAL-DESTINATION-RAIL-TEST-SUCCESSOR') 'prior C33A ticket differs'
Assert-C33B ([string]$priorC33A.manifestSha256 -ceq '9A5BE524089D65E0904D2714BA2D795D44BB152099733BA4593A5618BA94D1F4') 'prior C33A ticket hash differs'
Assert-C33B ($c33aGate.Contains('priorC33AQualifiedAssessment')) 'C33A lifecycle binding missing'

Assert-C33B ((Get-FileHash -Algorithm SHA256 -LiteralPath $testPath).Hash -ceq '9C3C6F199E3D082B54CAE3325E5CE064BA19209FDAA91034924F4DAD83A76BF1') 'migrated C17D bytes differ'
foreach ($token in @(
  'compact leading destination actions',
  'tester.getTopLeft(cluster).dx',
  'MoolLocalNavigationTokens.destinationRailHeight',
  'MoolLocalNavigationTokens.destinationLabelSize',
  'MoolLocalNavigationTokens.destinationFontFamily',
  "Key('moolsocial-local-`$`{action.`$1`}-selected-indicator')",
  'widget<SizedBox>',
  'MoolColors.muted',
  'clusterWidth(412, 2), 152',
  'clusterWidth(412, 3), 232'
)) { Assert-C33B ($test.Contains($token)) "current C17D assertion missing: $token" }
Assert-C33B (-not $test.Contains('tester.getRect(cluster).center.dx')) 'obsolete centered-cluster assertion remains'
Assert-C33B (-not $test.Contains('widget<AnimatedOpacity>')) 'obsolete inner-chroma widget cast remains'
$expectedDesignHash = if ($c33dBound) {
  '9E0CEE1AB94C162AC76B35F130D6788EA10C599572AED737825DF4BB995B0758'
} elseif ($c33cBound) {
  '6430044F7DA73EB54634A6EE54F9664D7CF362B64D073DF58201CA0CE98E9832'
} else {
  'D66C9A8E34E49FF58DF25EF6DC0694B22DB91E5C33B6A04CA5CD7A63C7F76BFE'
}
Assert-C33B ((Get-FileHash -Algorithm SHA256 -LiteralPath $designPath).Hash -ceq $expectedDesignHash) 'C33B/C33C lifecycle-bound production design owner changed'
Assert-C33B ((Get-FileHash -Algorithm SHA256 -LiteralPath $c20ePath).Hash -ceq '9F5E461291133081B64CD34D4886E7874DBB24C93A4AB96627AC16EFCBF35382') 'qualified C33A C20E owner changed'
Assert-C33B ((Get-FileHash -Algorithm SHA256 -LiteralPath $c27bPath).Hash -ceq '6AFDEFE148F0E36A6EEBAE77F214A415344606157471C8D847E004D4F8DE54AD') 'C27B authority changed'
Assert-C33B ((Get-FileHash -Algorithm SHA256 -LiteralPath $c27dPath).Hash -ceq '7E156B6EA30F099E27236998A6ADCFAADAFE8C5E6356C37D687C04EF512FDCFC') 'C27D authority changed'
Assert-C33B ((Get-FileHash -Algorithm SHA256 -LiteralPath $statePath).Hash -ceq '8B85E8F9E99E25A3177689AD8FBB33143C8925E6DB474C5362425542774F2F7C') 'C33B machine state changed'
Assert-C33B ([string]$state.ticketId -ceq [string]$ticket.ticketId) 'C33B machine-state ticket differs'
Assert-C33B ([string]$state.state -ceq 'test_only_successor_qualified_runtime_unchanged') 'C33B machine-state qualification differs'
Assert-C33B ([int]$state.validation.C17D.passed -eq 10 -and [int]$state.validation.C17D.failed -eq 0) 'C33B C17D result differs'
Assert-C33B ([int]$state.validation.C20E.passed -eq 6 -and [int]$state.validation.C27B.passed -eq 5 -and [int]$state.validation.C27D.passed -eq 1) 'C33B preserved authority results differ'
Assert-C33B ([int]$state.validation.combinedCurrentAuthorityBatch.files -eq 4 -and [int]$state.validation.combinedCurrentAuthorityBatch.passed -eq 22 -and [int]$state.validation.combinedCurrentAuthorityBatch.failed -eq 0 -and [int]$state.validation.combinedCurrentAuthorityBatch.warnings -eq 0) 'C33B combined batch result differs'
Assert-C33B (-not [bool]$state.authority.runtimeChanged -and -not [bool]$state.authority.buildAuthorized -and -not [bool]$state.authority.deviceMutationAuthorized -and -not [bool]$state.authority.externalServiceWriteAuthorized) 'C33B machine authority opened'
$expectedTestOrGateAuthority = $activeScope
if ($activeScope) {
  Assert-C33B (-not [bool]$scope.execution.runtimeWriteAuthorized) 'active C33B scope opened runtime authority'
}
if ($c33cActive) {
  $c33cQualified = [string]$c33cAssessment.implementationState -ceq 'source_repair_qualified_48_passed_1_declared_skip_analyzer_17_clean_dual_host_gate_passed_device_and_release_held'
  Assert-C33B ([bool]$scope.execution.runtimeWriteAuthorized -eq (-not $c33cQualified)) 'active C33C runtime authority does not match implementation lifecycle'
  $expectedTestOrGateAuthority = -not $c33cQualified
}
if ($c33dActive) {
  $c33dQualified = [string]$c33dAssessment.implementationState -ceq 'source_repair_qualified_61_passed_4_declared_skips_whole_mobile_analyzer_clean_dual_host_gate_passed_device_and_release_held'
  Assert-C33B ([bool]$scope.execution.runtimeWriteAuthorized -eq (-not $c33dQualified)) 'active C33D runtime authority does not match implementation lifecycle'
  $expectedTestOrGateAuthority = -not $c33dQualified
}
if (-not ($activeScope -or $c33cActive -or $c33dActive)) {
  Assert-C33B (-not [bool]$scope.execution.runtimeWriteAuthorized) 'preserved successor scope reopened runtime authority'
}
Assert-C33B ([bool]$scope.execution.testOrGateWriteAuthorized -eq $expectedTestOrGateAuthority) 'scope test/gate authority differs'
Assert-C33B (-not [bool]$scope.execution.backendWriteAuthorized -and -not [bool]$scope.execution.buildAuthorized -and -not [bool]$scope.execution.deviceInstallAuthorized -and -not [bool]$scope.execution.externalServiceWriteAuthorized -and -not [bool]$scope.execution.secretValueAccessAuthorized) 'scope live authority differs'

Write-Output "C33B C17D/C21E current local destination rail test successor gate passed: scopeBinding=$(if ($activeScope) { 'active' } else { 'preservedPrior' }); C33C=$(if ($c33cBound) { 'bound' } else { 'absent' }); C33D=$(if ($c33dBound) { 'bound' } else { 'absent' }); C17D=10; C20E=6; C27B=5; C27D=1; combined=22; backend=false; build=false; device=false; external=false."
