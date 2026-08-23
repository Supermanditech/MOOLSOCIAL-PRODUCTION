[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C32M([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C32M gate rejected: $Message" }
}

function Resolve-C32M([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C32M ($path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) "owner escaped repository: $RelativePath"
  Assert-C32M (Test-Path -LiteralPath $path -PathType Leaf) "owner missing: $RelativePath"
  return $path
}

function Read-C32M([string]$RelativePath) {
  return [IO.File]::ReadAllText((Resolve-C32M $RelativePath))
}

$ticketPath = Resolve-C32M 'config/uaw-c32m-personal-mvp-chained-successor-gate-historical-scope-binding-ticket.json'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Read-C32M 'config/mvp-scope-gate-state.json' | ConvertFrom-Json
$c32jGate = Read-C32M 'scripts/check-uaw-c32j-c28e-immutable-r60-27-evidence-binding.ps1'
$c32kGate = Read-C32M 'scripts/check-uaw-c32k-c26c-c29n-left-edge-switcher-gate.ps1'
$c32lGate = Read-C32M 'scripts/check-uaw-c32l-c26d-c29n-specialized-social-dock-gate.ps1'

Assert-C32M ([string]$ticket.ticketId -ceq 'UAW-C32M-PERSONAL-MVP-CHAINED-SUCCESSOR-GATE-HISTORICAL-SCOPE-BINDING') 'ticket id changed'
Assert-C32M ([string]$ticket.classification -ceq 'mvp_supporting') 'ticket classification changed'
Assert-C32M ([bool]$ticket.authority.testAndGateWriteAuthorized) 'ticket test/gate authority closed'
Assert-C32M (-not [bool]$ticket.authority.runtimeSourceWriteAuthorized) 'ticket runtime authority opened'
Assert-C32M (-not [bool]$ticket.authority.backendSourceWriteAuthorized) 'ticket backend authority opened'
Assert-C32M (-not [bool]$ticket.authority.referenceWriteAuthorized) 'ticket reference authority opened'
Assert-C32M (-not [bool]$ticket.authority.buildAuthorized) 'ticket build authority opened'
Assert-C32M (-not [bool]$ticket.authority.deviceMutationAuthorized) 'ticket device authority opened'
Assert-C32M (-not [bool]$ticket.authority.externalCommunicationAuthorized) 'ticket communication authority opened'

$selected = $scope.preTicketSelectionCheckpoint.selectedTicketAssessment
$activeScope = [string]$scope.ticket.id -ceq [string]$ticket.ticketId
if ($activeScope) {
  Assert-C32M ([string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq [string]$ticket.ticketId) 'pre-ticket current ticket differs'
  Assert-C32M ([string]$selected.ticketId -ceq [string]$ticket.ticketId) 'selected assessment ticket differs'
  Assert-C32M ([string]$selected.manifestSha256 -ceq '8881FE40683A31FAE3C7EE3B87D85294E3FBC66F2C86E7DFB263D3C1BD71658A') 'selected C32M manifest hash differs'
  Assert-C32M ((Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash -ceq [string]$selected.manifestSha256) 'selected C32M ticket bytes differ'
  Assert-C32M (Test-Path -LiteralPath (Resolve-C32M ([string]$selected.evidencePath)) -PathType Leaf) 'C32M selected evidence is missing'
} else {
  $priorC32M = $scope.preTicketSelectionCheckpoint.priorC32MFocusedTicketAssessment
  Assert-C32M ($null -ne $priorC32M) 'preserved prior C32M assessment is missing'
  Assert-C32M ([string]$priorC32M.ticketId -ceq [string]$ticket.ticketId) 'preserved prior C32M ticket differs'
  Assert-C32M ([string]$priorC32M.manifestSha256 -ceq '8881FE40683A31FAE3C7EE3B87D85294E3FBC66F2C86E7DFB263D3C1BD71658A') 'preserved prior C32M manifest hash differs'
  Assert-C32M ([string]$priorC32M.implementationState -ceq 'source_gate_chain_repair_implemented_two_focused_cycles_passed_full_preflight_Buy_protected_baseline_hold_no_qualification_claim') 'preserved prior C32M implementation state differs'
  Assert-C32M ((Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash -ceq [string]$priorC32M.manifestSha256) 'preserved prior C32M ticket bytes differ'
  Assert-C32M (Test-Path -LiteralPath (Resolve-C32M ([string]$priorC32M.evidencePath)) -PathType Leaf) 'preserved prior C32M evidence is missing'
}

$priorSpecifications = @(
  [pscustomobject]@{
    property = 'priorC32JBlockedTicketAssessment'
    id = 'UAW-C32J-PERSONAL-MVP-C28E-IMMUTABLE-R60-27-EVIDENCE-BINDING-RECONCILIATION'
    hash = '787C6D2E413CFBA3BBCC53B82EAD9EA456D4B6EC7A4D6A757883507E805783DB'
    state = 'host_gate_repair_implemented_C28E_preflight_reaches_Buy_protected_baseline_hold'
    gate = $c32jGate
  },
  [pscustomobject]@{
    property = 'priorC32KBlockedTicketAssessment'
    id = 'UAW-C32K-PERSONAL-MVP-C26C-C29N-LEFT-EDGE-SWITCHER-GATE-RECONCILIATION'
    hash = '6E012C083CCF2B42FC584DFFF2EC982CB880EF7BDEB3D3AA6BF3F0AB1C7ADFDF'
    state = 'gate_repair_implemented_C28E_preflight_reaches_Buy_protected_baseline_hold'
    gate = $c32kGate
  },
  [pscustomobject]@{
    property = 'priorC32LHeldTicketAssessment'
    id = 'UAW-C32L-PERSONAL-MVP-C26D-C29N-SPECIALIZED-SOCIAL-DOCK-GATE-RECONCILIATION'
    hash = '2BF8ECA4968CF76007CC55603F8C281809A1E53948DFB4C17F9249A3C265328B'
    state = 'gate_repair_implemented_full_preflight_Buy_protected_baseline_hold_no_qualification_claim'
    gate = $c32lGate
  }
)

foreach ($spec in $priorSpecifications) {
  $prior = $scope.preTicketSelectionCheckpoint.($spec.property)
  Assert-C32M ($null -ne $prior) "preserved assessment missing: $($spec.property)"
  Assert-C32M ([string]$prior.ticketId -ceq [string]$spec.id) "preserved ticket differs: $($spec.property)"
  Assert-C32M ([string]$prior.manifestSha256 -ceq [string]$spec.hash) "preserved manifest hash differs: $($spec.property)"
  Assert-C32M ([string]$prior.implementationState -ceq [string]$spec.state) "preserved implementation state differs: $($spec.property)"
  Assert-C32M ((Get-FileHash -Algorithm SHA256 -LiteralPath (Resolve-C32M ([string]$prior.manifestPath))).Hash -ceq [string]$prior.manifestSha256) "preserved ticket bytes differ: $($spec.property)"
  Assert-C32M ($spec.gate.Contains([string]$spec.property)) "historical scope property is not enforced by its gate: $($spec.property)"
  Assert-C32M ($spec.gate.Contains([string]$spec.hash)) "historical manifest hash is not enforced by its gate: $($spec.property)"
  Assert-C32M ($spec.gate.Contains([string]$spec.state)) "historical implementation state is not enforced by its gate: $($spec.property)"
}

Assert-C32M ([bool]$scope.execution.testOrGateWriteAuthorized) 'scope test/gate authority closed'
Assert-C32M (-not [bool]$scope.execution.referenceWriteAuthorized) 'scope reference authority opened'
Assert-C32M (-not [bool]$scope.execution.runtimeWriteAuthorized) 'scope runtime authority opened'
Assert-C32M (-not [bool]$scope.execution.backendWriteAuthorized) 'scope backend authority opened'
Assert-C32M (-not [bool]$scope.execution.buildAuthorized) 'scope build authority opened'
Assert-C32M (-not [bool]$scope.execution.deviceInstallAuthorized) 'scope device authority opened'
Assert-C32M (-not [bool]$scope.execution.externalServiceWriteAuthorized) 'scope external authority opened'
Assert-C32M (-not [bool]$scope.execution.secretValueAccessAuthorized) 'scope secret authority opened'
if ($activeScope) {
  Assert-C32M ([string]$scope.protectedCandidateState.successorPreselection -ceq [string]$ticket.ticketId) 'protected successor preselection differs'
}
Assert-C32M (-not [bool]$scope.protectedCandidateState.protectedBaselineUpdated) 'protected baseline was changed'
Assert-C32M ([bool]$scope.protectedCandidateState.founderAcceptancePending) 'protected founder hold was removed'

Write-Output "C32M chained successor scope gate passed: scopeBinding=$(if ($activeScope) { 'active' } else { 'preservedPrior' }); prior=C32J,C32K,C32L exact; manifestHashes=4; BuyHold=true; build=false; device=false."
