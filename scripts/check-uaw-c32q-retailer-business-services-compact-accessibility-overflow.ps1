[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C32Q([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C32Q gate rejected: $Message" }
}

function Resolve-C32Q([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C32Q ($path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) "owner escaped repository: $RelativePath"
  Assert-C32Q (Test-Path -LiteralPath $path -PathType Leaf) "owner missing: $RelativePath"
  return $path
}

function Read-C32Q([string]$RelativePath) {
  return [IO.File]::ReadAllText((Resolve-C32Q $RelativePath))
}

$ticketPath = Resolve-C32Q 'config/uaw-c32q-personal-mvp-retailer-business-services-compact-accessibility-overflow-ticket.json'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$parentPath = Resolve-C32Q 'config/uaw-post-youtube-retailer-business-services-compact-overflow-ticket.json'
$parent = Get-Content -Raw -LiteralPath $parentPath | ConvertFrom-Json
$scope = Read-C32Q 'config/mvp-scope-gate-state.json' | ConvertFrom-Json
$design = Read-C32Q 'apps/mobile/lib/core/design/mool_design_system.dart'
$test = Read-C32Q 'apps/mobile/test/retailer_business_services_vertical_slice_test.dart'
$c32pGate = Read-C32Q 'scripts/check-uaw-c32p-buy-router-c26d-local-rail-test-topology-successor.ps1'

Assert-C32Q ([string]$ticket.ticketId -ceq 'UAW-C32Q-PERSONAL-MVP-RETAILER-BUSINESS-SERVICES-COMPACT-ACCESSIBILITY-OVERFLOW') 'ticket id changed'
Assert-C32Q ([string]$ticket.parentOutcome -ceq 'UAW-POST-YOUTUBE-RETAILER-BUSINESS-SERVICES-COMPACT-OVERFLOW') 'parent outcome changed'
Assert-C32Q ([string]$ticket.classification -ceq 'mvp_supporting') 'classification changed'
Assert-C32Q ([bool]$ticket.authority.runtimeSourceWriteAuthorized) 'runtime source authority closed'
Assert-C32Q ([bool]$ticket.authority.testAndGateWriteAuthorized) 'test and gate authority closed'
Assert-C32Q (-not [bool]$ticket.authority.backendSourceWriteAuthorized) 'backend authority opened'
Assert-C32Q (-not [bool]$ticket.authority.referenceWriteAuthorized) 'reference authority opened'
Assert-C32Q (-not [bool]$ticket.authority.baselineReplacementAuthorized) 'baseline authority opened'
Assert-C32Q (-not [bool]$ticket.authority.buildAuthorized) 'build authority opened'
Assert-C32Q (-not [bool]$ticket.authority.deviceMutationAuthorized) 'device authority opened'
Assert-C32Q (-not [bool]$ticket.authority.externalCommunicationAuthorized) 'external communication authority opened'
Assert-C32Q (-not [bool]$ticket.authority.secretValueAccessAuthorized) 'secret authority opened'

Assert-C32Q ((Get-FileHash -Algorithm SHA256 -LiteralPath $parentPath).Hash -ceq '19D9C779354DF912E77FF6842397D0C9E3ADCB106CABBF0A45B0F1456F68FEBD') 'historical parent finding bytes changed'
Assert-C32Q (-not [bool]$parent.scope.currentTicketMayImplement) 'historical parent disposition was rewritten'

$selected = $scope.preTicketSelectionCheckpoint.selectedTicketAssessment
$activeScope = [string]$scope.ticket.id -ceq [string]$ticket.ticketId
if ($activeScope) {
  Assert-C32Q ([string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq [string]$ticket.ticketId) 'pre-ticket current ticket differs'
  Assert-C32Q ([string]$selected.ticketId -ceq [string]$ticket.ticketId) 'selected assessment ticket differs'
  Assert-C32Q ([string]$selected.manifestSha256 -ceq 'A82E652697645BDBAA5DF71B374C2EACB8B0ABB9EAF99FD312F10AFDF806523C') 'selected ticket manifest hash differs'
  Assert-C32Q ((Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash -ceq [string]$selected.manifestSha256) 'selected ticket bytes differ'
} else {
  $priorC32Q = $scope.preTicketSelectionCheckpoint.priorC32QSourceQualifiedTicketAssessment
  Assert-C32Q ($null -ne $priorC32Q) 'preserved prior C32Q assessment is missing'
  Assert-C32Q ([string]$priorC32Q.ticketId -ceq [string]$ticket.ticketId) 'preserved prior C32Q ticket differs'
  Assert-C32Q ([string]$priorC32Q.manifestSha256 -ceq 'A82E652697645BDBAA5DF71B374C2EACB8B0ABB9EAF99FD312F10AFDF806523C') 'preserved prior C32Q manifest hash differs'
  Assert-C32Q ([string]$priorC32Q.implementationState -ceq 'exact_shared_dock_owner_repaired_two_identical_acceptance_cycles_and_final_state_rebind_cycle_passed_source_qualified') 'preserved prior C32Q implementation state differs'
  Assert-C32Q ((Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash -ceq [string]$priorC32Q.manifestSha256) 'preserved prior C32Q ticket bytes differ'
}

$priorC32P = $scope.preTicketSelectionCheckpoint.priorC32PFocusedTicketAssessment
Assert-C32Q ($null -ne $priorC32P) 'prior C32P focused assessment missing'
Assert-C32Q ([string]$priorC32P.ticketId -ceq 'UAW-C32P-PERSONAL-MVP-BUY-ROUTER-C26D-LOCAL-RAIL-TEST-TOPOLOGY-SUCCESSOR') 'prior C32P ticket differs'
Assert-C32Q ([string]$priorC32P.manifestSha256 -ceq 'B1FE1E74112AD663D5733B25859A5EB7772E914179D2B95755B01E3E05B8651B') 'prior C32P manifest hash differs'
Assert-C32Q ($c32pGate.Contains('priorC32PFocusedTicketAssessment')) 'C32P historical scope binding is not enforced'
Assert-C32Q ($c32pGate.Contains('scopeBinding=')) 'C32P truthful lifecycle output is missing'

Assert-C32Q ((Get-FileHash -Algorithm SHA256 -LiteralPath (Resolve-C32Q 'apps/mobile/lib/features/retailer/screens/retailer_business_services_screens.dart')).Hash -ceq '812185F7C96EBC1C60C7E6F46907CE767DE25DF7AD79639C8C590365288097A6') 'Retailer Business Services screen owner changed'
Assert-C32Q ($design -cmatch 'actions\.length <= 3[\s\S]*?Flexible\([\s\S]*?width: MoolLocalNavigationTokens[\s\S]*?\.capsuleWidth[\s\S]*?_MoolMiddleDockAction') 'adaptive three-action center capsules missing'
Assert-C32Q ($design -cmatch 'actions\.length <= 3[\s\S]*?mainAxisAlignment: MainAxisAlignment\.center') 'three-action center alignment changed'
Assert-C32Q ($design -cmatch 'actions\.length <= 3[\s\S]*?MoolLocalNavigationTokens\.itemGap') 'three-action item gap missing'
Assert-C32Q ($design -cmatch 'actions\.length <= 3[\s\S]*?SingleChildScrollView') 'four-plus action scroll fallback missing'
Assert-C32Q ($test.Contains("size: const Size(320, 700)")) 'exact compact viewport missing'
Assert-C32Q ($test.Contains('textScale: 1.3')) 'exact compact text scale missing'
Assert-C32Q ($test.Contains('The compact access-denied shell must not overflow.')) 'access-denied phase assertion missing'
Assert-C32Q ($test.Contains('The compact authorized service catalogue must not overflow.')) 'authorized catalogue phase assertion missing'
Assert-C32Q ($test.Contains('Offline activation must not introduce a compact overflow.')) 'offline activation phase assertion missing'
Assert-C32Q (-not $test.Contains('C32Q_OVERFLOW_')) 'diagnostic render-tree output remains'
Assert-C32Q (-not $test.Contains("package:flutter/rendering.dart")) 'diagnostic-only rendering import remains'

if ($activeScope) {
  Assert-C32Q ([bool]$scope.execution.runtimeWriteAuthorized) 'scope runtime authority closed'
}
Assert-C32Q ([bool]$scope.execution.testOrGateWriteAuthorized) 'scope test/gate authority closed'
Assert-C32Q (-not [bool]$scope.execution.referenceWriteAuthorized) 'scope reference authority opened'
Assert-C32Q (-not [bool]$scope.execution.backendWriteAuthorized) 'scope backend authority opened'
Assert-C32Q (-not [bool]$scope.execution.buildAuthorized) 'scope build authority opened'
Assert-C32Q (-not [bool]$scope.execution.deviceInstallAuthorized) 'scope device authority opened'
Assert-C32Q (-not [bool]$scope.execution.externalServiceWriteAuthorized) 'scope external authority opened'
Assert-C32Q (-not [bool]$scope.execution.secretValueAccessAuthorized) 'scope secret authority opened'
Assert-C32Q (-not [bool]$scope.protectedCandidateState.protectedBaselineUpdated) 'Buy protected baseline was changed'
Assert-C32Q ([bool]$scope.protectedCandidateState.founderAcceptancePending) 'Buy protected founder hold was removed'

Write-Output "C32Q Retailer Business Services compact accessibility gate passed: scopeBinding=$(if ($activeScope) { 'active' } else { 'preservedPrior' }); viewport=320x700; textScale=1.3; middleActions=adaptiveMax72; minimumTapTarget=preserved; backend=false; build=false; device=false."
