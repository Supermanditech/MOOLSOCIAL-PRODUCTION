[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar
function Assert-C33A([bool]$Condition, [string]$Message) { if (-not $Condition) { throw "C33A gate rejected: $Message" } }
function Resolve-C33A([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C33A ($path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) "owner escaped repository: $RelativePath"
  Assert-C33A (Test-Path -LiteralPath $path -PathType Leaf) "owner missing: $RelativePath"
  return $path
}
function Read-C33A([string]$RelativePath) { return [IO.File]::ReadAllText((Resolve-C33A $RelativePath)) }

$ticketPath = Resolve-C33A 'config/uaw-c33a-personal-mvp-c20e-current-local-destination-rail-test-successor-ticket.json'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Read-C33A 'config/mvp-scope-gate-state.json' | ConvertFrom-Json
$c32xGate = Read-C33A 'scripts/check-uaw-c32x-r15-action-choice-navigation-accessibility-test-successor.ps1'
$testPath = Resolve-C33A 'apps/mobile/test/ui_v2/universal/uaw_personal_mvp_eat_ride_book_work_adaptive_conformance_c20e_test.dart'
$test = [IO.File]::ReadAllText($testPath)
$designPath = Resolve-C33A 'apps/mobile/lib/core/design/mool_design_system.dart'
$c27bPath = Resolve-C33A 'apps/mobile/test/ui_v2/universal/mool_uniform_navigation_design_system_c27b_test.dart'
$c27dPath = Resolve-C33A 'apps/mobile/test/ui_v2/universal/mool_uniform_navigation_six_family_conformance_c27d_test.dart'
$r06Path = Resolve-C33A 'apps/mobile/test/ui_v2/universal/uaw_r06_personal_eat_exposure_test.dart'
$c17dPath = Resolve-C33A 'apps/mobile/test/core/design/mool_remaining_family_clear_glass_conformance_c17d_test.dart'
$statePath = Resolve-C33A 'config/post-youtube-c20e-current-local-destination-rail-state-c33a.json'
$state = Get-Content -Raw -LiteralPath $statePath | ConvertFrom-Json
Resolve-C33A 'docs/quality/POST-SEAL-C20E-ADAPTIVE-FAMILY-CONTRACT-FAILURE-20260815.md' | Out-Null
Resolve-C33A 'docs/quality/POST-SEAL-C17D-C21E-REMAINING-FAMILY-GLASS-CONTRACT-FAILURE-20260815.md' | Out-Null
Resolve-C33A 'docs/quality/UAW-C33A-C20E-CURRENT-LOCAL-DESTINATION-RAIL-TEST-SUCCESSOR-QUALIFICATION-20260815.md' | Out-Null

Assert-C33A ([string]$ticket.ticketId -ceq 'UAW-C33A-PERSONAL-MVP-C20E-CURRENT-LOCAL-DESTINATION-RAIL-TEST-SUCCESSOR') 'ticket id changed'
Assert-C33A ([string]$ticket.classification -ceq 'mvp_supporting') 'classification changed'
Assert-C33A (-not [bool]$ticket.authority.runtimeSourceWriteAuthorized) 'ticket runtime authority opened'
Assert-C33A ([bool]$ticket.authority.testAndGateWriteAuthorized) 'ticket test/gate authority closed'
Assert-C33A (-not [bool]$ticket.authority.backendSourceWriteAuthorized -and -not [bool]$ticket.authority.buildAuthorized -and -not [bool]$ticket.authority.deviceMutationAuthorized -and -not [bool]$ticket.authority.externalCommunicationAuthorized -and -not [bool]$ticket.authority.secretValueAccessAuthorized) 'ticket live authority opened'

$selected = $scope.preTicketSelectionCheckpoint.selectedTicketAssessment
$activeScope = [string]$scope.ticket.id -ceq [string]$ticket.ticketId
$c33bTicketId = 'UAW-C33B-PERSONAL-MVP-C17D-C21E-CURRENT-LOCAL-DESTINATION-RAIL-TEST-SUCCESSOR'
$c33bActive = [string]$scope.ticket.id -ceq $c33bTicketId
$c33cTicketId = 'UAW-C33C-PERSONAL-MVP-RIDE-COMPACT-FOUR-ACTION-DESTINATION-RAIL-RECOVERY'
$c33cActive = [string]$scope.ticket.id -ceq $c33cTicketId
$c33dTicketId = 'UAW-C33D-PERSONAL-MVP-FOUR-ACTION-EXACT-FIT-DESTINATION-RAIL-RECOVERY'
$c33dActive = [string]$scope.ticket.id -ceq $c33dTicketId
$assessment = if ($activeScope) {
  Assert-C33A ([string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq [string]$ticket.ticketId) 'pre-ticket current ticket differs'
  $selected
} else {
  $scope.preTicketSelectionCheckpoint.priorC33AQualifiedAssessment
}
Assert-C33A ($null -ne $assessment) 'active or preserved qualified C33A assessment is missing'
Assert-C33A ([string]$assessment.ticketId -ceq [string]$ticket.ticketId) 'C33A assessment ticket differs'
Assert-C33A ([string]$assessment.manifestSha256 -ceq '9A5BE524089D65E0904D2714BA2D795D44BB152099733BA4593A5618BA94D1F4') 'C33A ticket hash differs'
Assert-C33A ((Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash -ceq [string]$assessment.manifestSha256) 'C33A ticket bytes differ'
Assert-C33A ([string]$assessment.implementationState -ceq 'C20E_test_only_successor_qualified_C20E_6_C27B_5_C27D_1_R06_12_passed_analyzer_clean_runtime_unchanged_C17D_separate_failure_preserved') 'C33A implementation state differs'
Assert-C33A ([string]$assessment.evidencePath -ceq 'docs/quality/UAW-C33A-C20E-CURRENT-LOCAL-DESTINATION-RAIL-TEST-SUCCESSOR-QUALIFICATION-20260815.md') 'C33A evidence path differs'

$priorC32X = $scope.preTicketSelectionCheckpoint.priorC32XQualifiedAssessment
Assert-C33A ($null -ne $priorC32X) 'prior C32X qualified assessment missing'
Assert-C33A ([string]$priorC32X.ticketId -ceq 'UAW-C32X-PERSONAL-MVP-R15-ACTION-CHOICE-NAVIGATION-ACCESSIBILITY-TEST-SUCCESSOR') 'prior C32X ticket differs'
Assert-C33A ([string]$priorC32X.manifestSha256 -ceq 'C921671592E354C9634B454F8C066AB306C58101B1A617A5027D2E774FAE0AE0') 'prior C32X hash differs'
Assert-C33A ($c32xGate.Contains('priorC32XQualifiedAssessment')) 'C32X lifecycle binding missing'
if (-not $activeScope) {
  $c33bAssessment = if ($c33bActive) {
    $selected
  } else {
    $scope.preTicketSelectionCheckpoint.priorC33BQualifiedAssessment
  }
  Assert-C33A ($null -ne $c33bAssessment) 'active or preserved qualified C33B assessment missing'
  Assert-C33A ([string]$c33bAssessment.ticketId -ceq $c33bTicketId) 'C33B assessment ticket differs'
  Assert-C33A ([string]$c33bAssessment.manifestSha256 -ceq 'B3B52E5E5742FE8CA17D1DCA70DB8CE49A3CE239719C49583AA9AE081F221D8A') 'C33B assessment hash differs'
}
$c33cAssessment = if ($c33cActive) {
  Assert-C33A ([string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq $c33cTicketId) 'C33C pre-ticket current ticket differs'
  $selected
} else {
  $scope.preTicketSelectionCheckpoint.priorC33CQualifiedAssessment
}
$c33cBound = $null -ne $c33cAssessment
if ($c33cBound) {
  $c33cTicketPath = Resolve-C33A 'config/uaw-c33c-personal-mvp-ride-compact-four-action-destination-rail-recovery-ticket.json'
  Assert-C33A ([string]$c33cAssessment.ticketId -ceq $c33cTicketId) 'C33C assessment ticket differs'
  Assert-C33A ([string]$c33cAssessment.manifestSha256 -ceq 'C8721DB35BB6D145024F2CD45465D30CE2C1735F3DF5D60C23FFC01F5ACA046C') 'C33C assessment hash differs'
  Assert-C33A ((Get-FileHash -Algorithm SHA256 -LiteralPath $c33cTicketPath).Hash -ceq [string]$c33cAssessment.manifestSha256) 'C33C ticket bytes differ'
}
$c33dAssessment = if ($c33dActive) {
  Assert-C33A ([string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq $c33dTicketId) 'C33D pre-ticket current ticket differs'
  $selected
} else {
  $scope.preTicketSelectionCheckpoint.priorC33DQualifiedAssessment
}
$c33dBound = $null -ne $c33dAssessment
if ($c33dBound) {
  $c33dTicketPath = Resolve-C33A 'config/uaw-c33d-personal-mvp-four-action-exact-fit-destination-rail-recovery-ticket.json'
  Assert-C33A ([string]$c33dAssessment.ticketId -ceq $c33dTicketId) 'C33D assessment ticket differs'
  Assert-C33A ([string]$c33dAssessment.manifestSha256 -ceq '651EC79E221CB12025A988F61AB927AAAF85B240F95CEEA05BDFE6FDDD3148B7') 'C33D assessment hash differs'
  Assert-C33A ((Get-FileHash -Algorithm SHA256 -LiteralPath $c33dTicketPath).Hash -ceq [string]$c33dAssessment.manifestSha256) 'C33D ticket bytes differ'
}

Assert-C33A ((Get-FileHash -Algorithm SHA256 -LiteralPath $testPath).Hash -ceq '9F5E461291133081B64CD34D4886E7874DBB24C93A4AB96627AC16EFCBF35382') 'migrated C20E bytes differ'
foreach ($token in @(
  'compact leading destination actions',
  'tester.getTopLeft(cluster).dx',
  'MoolLocalNavigationTokens.destinationRailHeight',
  'MoolLocalNavigationTokens.destinationLabelSize',
  'MoolLocalNavigationTokens.destinationFontFamily',
  "Key('moolsocial-local-`$`{action.id`}-selected-indicator')",
  'widget<SizedBox>',
  'MoolColors.muted'
)) { Assert-C33A ($test.Contains($token)) "current C20E assertion missing: $token" }
Assert-C33A (-not $test.Contains('tester.getRect(cluster).center.dx')) 'obsolete centered-cluster assertion remains'
Assert-C33A (-not $test.Contains('widget<AnimatedOpacity>')) 'obsolete inner-chroma widget cast remains'
$expectedDesignHash = if ($c33dBound) {
  '9E0CEE1AB94C162AC76B35F130D6788EA10C599572AED737825DF4BB995B0758'
} elseif ($c33cBound) {
  '6430044F7DA73EB54634A6EE54F9664D7CF362B64D073DF58201CA0CE98E9832'
} else {
  'D66C9A8E34E49FF58DF25EF6DC0694B22DB91E5C33B6A04CA5CD7A63C7F76BFE'
}
Assert-C33A ((Get-FileHash -Algorithm SHA256 -LiteralPath $designPath).Hash -ceq $expectedDesignHash) 'C33A/C33C lifecycle-bound production design owner changed'
Assert-C33A ((Get-FileHash -Algorithm SHA256 -LiteralPath $c27bPath).Hash -ceq '6AFDEFE148F0E36A6EEBAE77F214A415344606157471C8D847E004D4F8DE54AD') 'C27B authority changed'
Assert-C33A ((Get-FileHash -Algorithm SHA256 -LiteralPath $c27dPath).Hash -ceq '7E156B6EA30F099E27236998A6ADCFAADAFE8C5E6356C37D687C04EF512FDCFC') 'C27D authority changed'
Assert-C33A ((Get-FileHash -Algorithm SHA256 -LiteralPath $r06Path).Hash -ceq '9E77FDC5CA5259740C7F4B8AB3A5F4EE2A116EABDD3B79CAFF921B591DCF23A6') 'R06 authority changed'
$expectedC17DHash = if ($activeScope) {
  'BE49A30A02272D7DD91477A4211F2825D39F8C6B0301C51BDA64DD9EEA25F954'
} else {
  '9C3C6F199E3D082B54CAE3325E5CE064BA19209FDAA91034924F4DAD83A76BF1'
}
Assert-C33A ((Get-FileHash -Algorithm SHA256 -LiteralPath $c17dPath).Hash -ceq $expectedC17DHash) 'C33A/C33B lifecycle-bound C17D owner changed'
Assert-C33A ((Get-FileHash -Algorithm SHA256 -LiteralPath $statePath).Hash -ceq '37F6044342991FDA91198AD2E032C61CD246D3AFBC317A3D6D60D5BB9C6118C0') 'C33A machine state changed'
Assert-C33A ([string]$state.ticketId -ceq [string]$ticket.ticketId) 'C33A machine-state ticket differs'
Assert-C33A ([string]$state.state -ceq 'test_only_successor_qualified_runtime_unchanged_C17D_separate_finding_preserved') 'C33A machine-state qualification differs'
Assert-C33A ([int]$state.validation.C20E.passed -eq 6 -and [int]$state.validation.C20E.failed -eq 0) 'C33A C20E result differs'
Assert-C33A ([int]$state.validation.C27B.passed -eq 5 -and [int]$state.validation.C27D.passed -eq 1 -and [int]$state.validation.R06.passed -eq 12) 'C33A current-authority result differs'
Assert-C33A ([int]$state.validation.combinedCurrentAuthorityBatch.files -eq 4 -and [int]$state.validation.combinedCurrentAuthorityBatch.passed -eq 24 -and [int]$state.validation.combinedCurrentAuthorityBatch.failed -eq 0 -and [int]$state.validation.combinedCurrentAuthorityBatch.warnings -eq 0) 'C33A combined authority batch result differs'
Assert-C33A ([int]$state.separatePendingFinding.result.passed -eq 0 -and [int]$state.separatePendingFinding.result.failed -eq 10 -and -not [bool]$state.separatePendingFinding.includedInC33A) 'C17D separate-finding state differs'
Assert-C33A (-not [bool]$state.authority.runtimeChanged -and -not [bool]$state.authority.buildAuthorized -and -not [bool]$state.authority.deviceMutationAuthorized -and -not [bool]$state.authority.externalServiceWriteAuthorized) 'C33A machine authority opened'

$expectedTestOrGateAuthority = $activeScope -or $c33bActive
if ($activeScope -or $c33bActive) {
  Assert-C33A (-not [bool]$scope.execution.runtimeWriteAuthorized) 'test-only predecessor scope opened runtime authority'
}
if ($c33cActive) {
  $c33cQualified = [string]$c33cAssessment.implementationState -ceq 'source_repair_qualified_48_passed_1_declared_skip_analyzer_17_clean_dual_host_gate_passed_device_and_release_held'
  Assert-C33A ([bool]$scope.execution.runtimeWriteAuthorized -eq (-not $c33cQualified)) 'active C33C runtime authority does not match implementation lifecycle'
  $expectedTestOrGateAuthority = -not $c33cQualified
}
if ($c33dActive) {
  $c33dQualified = [string]$c33dAssessment.implementationState -ceq 'source_repair_qualified_61_passed_4_declared_skips_whole_mobile_analyzer_clean_dual_host_gate_passed_device_and_release_held'
  Assert-C33A ([bool]$scope.execution.runtimeWriteAuthorized -eq (-not $c33dQualified)) 'active C33D runtime authority does not match implementation lifecycle'
  $expectedTestOrGateAuthority = -not $c33dQualified
}
if (-not ($activeScope -or $c33bActive -or $c33cActive -or $c33dActive)) {
  Assert-C33A (-not [bool]$scope.execution.runtimeWriteAuthorized) 'preserved successor scope reopened runtime authority'
}
Assert-C33A ([bool]$scope.execution.testOrGateWriteAuthorized -eq $expectedTestOrGateAuthority) 'scope test/gate authority differs'
Assert-C33A (-not [bool]$scope.execution.backendWriteAuthorized -and -not [bool]$scope.execution.buildAuthorized -and -not [bool]$scope.execution.deviceInstallAuthorized -and -not [bool]$scope.execution.externalServiceWriteAuthorized -and -not [bool]$scope.execution.secretValueAccessAuthorized) 'scope live authority differs'

$c17dState = if ($activeScope) { 'separate0/10' } else { 'C33B-successor10/10' }
Write-Output "C33A C20E current local destination rail test successor gate passed: scopeBinding=$(if ($activeScope) { 'active' } else { 'preservedPrior' }); C33C=$(if ($c33cBound) { 'bound' } else { 'absent' }); C33D=$(if ($c33dBound) { 'bound' } else { 'absent' }); C20E=6; C27B=5; C27D=1; R06=12; C17D=$c17dState; backend=false; build=false; device=false; external=false."
