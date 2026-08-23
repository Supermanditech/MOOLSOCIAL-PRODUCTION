[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C32T([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C32T gate rejected: $Message" }
}

function Resolve-C32T([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C32T ($path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) "owner escaped repository: $RelativePath"
  Assert-C32T (Test-Path -LiteralPath $path -PathType Leaf) "owner missing: $RelativePath"
  return $path
}

function Read-C32T([string]$RelativePath) {
  return [IO.File]::ReadAllText((Resolve-C32T $RelativePath))
}

$ticketPath = Resolve-C32T 'config/uaw-c32t-personal-mvp-c23c-compact-destination-shell-test-successor-ticket.json'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Read-C32T 'config/mvp-scope-gate-state.json' | ConvertFrom-Json
$c32sGate = Read-C32T 'scripts/check-uaw-c32s-c22f-current-navigation-visual-contract-test-successor.ps1'
$testPath = Resolve-C32T 'apps/mobile/test/ui_v2/universal/mool_single_home_launcher_shell_c23c_test.dart'
$test = [IO.File]::ReadAllText($testPath)
$navigationPath = Resolve-C32T 'apps/mobile/lib/ui_v2/universal/mool_global_navigation_v2.dart'

Assert-C32T ([string]$ticket.ticketId -ceq 'UAW-C32T-PERSONAL-MVP-C23C-COMPACT-DESTINATION-SHELL-TEST-SUCCESSOR') 'ticket id changed'
Assert-C32T ([string]$ticket.parentOutcome -ceq 'UAW-C32R-PERSONAL-MVP-HISTORICAL-NAVIGATION-TEST-APPLICABILITY-RECONCILIATION') 'parent outcome changed'
Assert-C32T ([string]$ticket.classification -ceq 'mvp_supporting') 'classification changed'
Assert-C32T (-not [bool]$ticket.authority.runtimeSourceWriteAuthorized) 'ticket runtime authority opened'
Assert-C32T ([bool]$ticket.authority.testAndGateWriteAuthorized) 'ticket test/gate authority closed'
Assert-C32T (-not [bool]$ticket.authority.backendSourceWriteAuthorized) 'ticket backend authority opened'
Assert-C32T (-not [bool]$ticket.authority.referenceWriteAuthorized) 'ticket reference authority opened'
Assert-C32T (-not [bool]$ticket.authority.baselineReplacementAuthorized) 'ticket baseline authority opened'
Assert-C32T (-not [bool]$ticket.authority.buildAuthorized) 'ticket build authority opened'
Assert-C32T (-not [bool]$ticket.authority.deviceMutationAuthorized) 'ticket device authority opened'
Assert-C32T (-not [bool]$ticket.authority.externalCommunicationAuthorized) 'ticket external authority opened'
Assert-C32T (-not [bool]$ticket.authority.secretValueAccessAuthorized) 'ticket secret authority opened'

$selected = $scope.preTicketSelectionCheckpoint.selectedTicketAssessment
$activeScope = [string]$scope.ticket.id -ceq [string]$ticket.ticketId
if ($activeScope) {
  Assert-C32T ([string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq [string]$ticket.ticketId) 'pre-ticket current ticket differs'
  Assert-C32T ([string]$selected.ticketId -ceq [string]$ticket.ticketId) 'selected assessment ticket differs'
  Assert-C32T ([string]$selected.manifestSha256 -ceq '260B8D51CC0D1A03A0B68872958ADE211155CB16C319C4ABC9B1C90FF415418F') 'selected ticket hash differs'
  Assert-C32T ((Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash -ceq [string]$selected.manifestSha256) 'selected ticket bytes differ'
  Assert-C32T ([string]$selected.implementationState -ceq 'C23C_test_only_successor_implemented_C23C_2_C26D_1_C27B_5_C27D_1_passed_analyzer_clean_runtime_unchanged') 'selected implementation state differs'
} else {
  $priorC32T = $scope.preTicketSelectionCheckpoint.priorC32TQualifiedAssessment
  Assert-C32T ($null -ne $priorC32T) 'preserved prior C32T assessment is missing'
  Assert-C32T ([string]$priorC32T.ticketId -ceq [string]$ticket.ticketId) 'preserved prior C32T ticket differs'
  Assert-C32T ([string]$priorC32T.manifestSha256 -ceq '260B8D51CC0D1A03A0B68872958ADE211155CB16C319C4ABC9B1C90FF415418F') 'preserved prior C32T hash differs'
  Assert-C32T ([string]$priorC32T.implementationState -ceq 'C23C_test_only_successor_implemented_C23C_2_C26D_1_C27B_5_C27D_1_passed_analyzer_clean_runtime_unchanged') 'preserved prior C32T implementation state differs'
  Assert-C32T ((Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash -ceq [string]$priorC32T.manifestSha256) 'preserved prior C32T ticket bytes differ'
}

$priorC32S = $scope.preTicketSelectionCheckpoint.priorC32SQualifiedAssessment
Assert-C32T ($null -ne $priorC32S) 'prior C32S assessment missing'
Assert-C32T ([string]$priorC32S.ticketId -ceq 'UAW-C32S-PERSONAL-MVP-C22F-CURRENT-NAVIGATION-VISUAL-CONTRACT-TEST-SUCCESSOR') 'prior C32S ticket differs'
Assert-C32T ([string]$priorC32S.manifestSha256 -ceq 'B32AC9753DB5FE397E79D8D6F2A27077C0BD3A5957C4496A744C083B494AD616') 'prior C32S hash differs'
Assert-C32T ($c32sGate.Contains('priorC32SQualifiedAssessment')) 'C32S historical scope binding is not enforced'
Assert-C32T ($c32sGate.Contains('scopeBinding=')) 'C32S truthful lifecycle output is missing'
Assert-C32T ((Get-FileHash -Algorithm SHA256 -LiteralPath $testPath).Hash -ceq '399B77D0D7DD95A3AAE0D23460817CCE3C850B0626FFE84979C2F5418A1C45F7') 'C32T migrated C23C bytes differ'
Assert-C32T ($test.Contains('C32T destination shell renders compact Mool, local rail and Chat')) 'current destination-shell case missing'
Assert-C32T ($test.Contains("Key('mool-compact-launcher')")) 'compact Mool launcher assertion missing'
Assert-C32T ($test.Contains("Key('accepted-local-rail')")) 'destination-local navigation assertion missing'
Assert-C32T ($test.Contains("Key('mool-global-chat')")) 'Chat edge anchor assertion missing'
Assert-C32T ($test.Contains("Key('moolsocial-home-has-no-bottom-navigation')")) 'Mool Home no-bottom-control assertion missing'
Assert-C32T (-not $test.Contains("Key('rejected-local-rail')")) 'obsolete rejected local rail remains'
Assert-C32T ((Get-FileHash -Algorithm SHA256 -LiteralPath $navigationPath).Hash -ceq '591D92DDB791E3EED2D5B3967E7FAA75A63087126A8965C45D070A3357F1DD62') 'production navigation owner changed'

Assert-C32T (-not [bool]$scope.execution.runtimeWriteAuthorized) 'scope runtime authority opened'
Assert-C32T ([bool]$scope.execution.testOrGateWriteAuthorized) 'scope test/gate authority closed'
Assert-C32T (-not [bool]$scope.execution.referenceWriteAuthorized) 'scope reference authority opened'
Assert-C32T (-not [bool]$scope.execution.backendWriteAuthorized) 'scope backend authority opened'
Assert-C32T (-not [bool]$scope.execution.buildAuthorized) 'scope build authority opened'
Assert-C32T (-not [bool]$scope.execution.deviceInstallAuthorized) 'scope device authority opened'
Assert-C32T (-not [bool]$scope.execution.externalServiceWriteAuthorized) 'scope external authority opened'
Assert-C32T (-not [bool]$scope.execution.secretValueAccessAuthorized) 'scope secret authority opened'

Write-Output "C32T C23C compact destination shell test successor gate passed: scopeBinding=$(if ($activeScope) { 'active' } else { 'preservedPrior' }); C23C=2; C26D=1; C27B=5; C27D=1; analyzer=clean; runtime=false; backend=false; build=false; device=false; external=false."
