[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C32S([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C32S gate rejected: $Message" }
}

function Resolve-C32S([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C32S ($path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) "owner escaped repository: $RelativePath"
  Assert-C32S (Test-Path -LiteralPath $path -PathType Leaf) "owner missing: $RelativePath"
  return $path
}

function Read-C32S([string]$RelativePath) {
  return [IO.File]::ReadAllText((Resolve-C32S $RelativePath))
}

$ticketPath = Resolve-C32S 'config/uaw-c32s-personal-mvp-c22f-current-navigation-visual-contract-test-successor-ticket.json'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Read-C32S 'config/mvp-scope-gate-state.json' | ConvertFrom-Json
$state = Read-C32S 'config/post-youtube-historical-navigation-test-applicability-state-c32r.json' | ConvertFrom-Json
$c32rGate = Read-C32S 'scripts/check-uaw-c32r-historical-navigation-test-applicability-reconciliation.ps1'
$testPath = Resolve-C32S 'apps/mobile/test/core/design/mool_inner_chroma_emission_c22f_test.dart'
$test = [IO.File]::ReadAllText($testPath)
$designPath = Resolve-C32S 'apps/mobile/lib/core/design/mool_design_system.dart'

Assert-C32S ([string]$ticket.ticketId -ceq 'UAW-C32S-PERSONAL-MVP-C22F-CURRENT-NAVIGATION-VISUAL-CONTRACT-TEST-SUCCESSOR') 'ticket id changed'
Assert-C32S ([string]$ticket.parentOutcome -ceq 'UAW-C32R-PERSONAL-MVP-HISTORICAL-NAVIGATION-TEST-APPLICABILITY-RECONCILIATION') 'parent outcome changed'
Assert-C32S ([string]$ticket.classification -ceq 'mvp_supporting') 'classification changed'
Assert-C32S (-not [bool]$ticket.authority.runtimeSourceWriteAuthorized) 'ticket runtime authority opened'
Assert-C32S ([bool]$ticket.authority.testAndGateWriteAuthorized) 'ticket test/gate authority closed'
Assert-C32S (-not [bool]$ticket.authority.backendSourceWriteAuthorized) 'ticket backend authority opened'
Assert-C32S (-not [bool]$ticket.authority.referenceWriteAuthorized) 'ticket reference authority opened'
Assert-C32S (-not [bool]$ticket.authority.baselineReplacementAuthorized) 'ticket baseline authority opened'
Assert-C32S (-not [bool]$ticket.authority.buildAuthorized) 'ticket build authority opened'
Assert-C32S (-not [bool]$ticket.authority.deviceMutationAuthorized) 'ticket device authority opened'
Assert-C32S (-not [bool]$ticket.authority.externalCommunicationAuthorized) 'ticket external authority opened'
Assert-C32S (-not [bool]$ticket.authority.secretValueAccessAuthorized) 'ticket secret authority opened'

$selected = $scope.preTicketSelectionCheckpoint.selectedTicketAssessment
$activeScope = [string]$scope.ticket.id -ceq [string]$ticket.ticketId
if ($activeScope) {
  Assert-C32S ([string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq [string]$ticket.ticketId) 'pre-ticket current ticket differs'
  Assert-C32S ([string]$selected.ticketId -ceq [string]$ticket.ticketId) 'selected assessment ticket differs'
  Assert-C32S ([string]$selected.manifestSha256 -ceq 'B32AC9753DB5FE397E79D8D6F2A27077C0BD3A5957C4496A744C083B494AD616') 'selected ticket hash differs'
  Assert-C32S ((Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash -ceq [string]$selected.manifestSha256) 'selected ticket bytes differ'
  Assert-C32S ([string]$selected.implementationState -ceq 'C22F_test_only_successor_implemented_C22F_9_C27B_5_C27D_1_passed_analyzer_clean_runtime_unchanged') 'selected implementation state differs'
} else {
  $priorC32S = $scope.preTicketSelectionCheckpoint.priorC32SQualifiedAssessment
  Assert-C32S ($null -ne $priorC32S) 'preserved prior C32S assessment is missing'
  Assert-C32S ([string]$priorC32S.ticketId -ceq [string]$ticket.ticketId) 'preserved prior C32S ticket differs'
  Assert-C32S ([string]$priorC32S.manifestSha256 -ceq 'B32AC9753DB5FE397E79D8D6F2A27077C0BD3A5957C4496A744C083B494AD616') 'preserved prior C32S manifest hash differs'
  Assert-C32S ([string]$priorC32S.implementationState -ceq 'C22F_test_only_successor_implemented_C22F_9_C27B_5_C27D_1_passed_analyzer_clean_runtime_unchanged') 'preserved prior C32S implementation state differs'
  Assert-C32S ((Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash -ceq [string]$priorC32S.manifestSha256) 'preserved prior C32S ticket bytes differ'
}

$priorC32R = $scope.preTicketSelectionCheckpoint.priorC32RAuditAssessment
Assert-C32S ($null -ne $priorC32R) 'prior C32R assessment missing'
Assert-C32S ([string]$priorC32R.ticketId -ceq 'UAW-C32R-PERSONAL-MVP-HISTORICAL-NAVIGATION-TEST-APPLICABILITY-RECONCILIATION') 'prior C32R ticket differs'
Assert-C32S ([string]$priorC32R.manifestSha256 -ceq '0F2E3CB70DCD4BD62747204211A68B258E3CCFAA9454A3FABAA6A86C91B767B2') 'prior C32R manifest hash differs'
Assert-C32S ($c32rGate.Contains('priorC32RAuditAssessment')) 'C32R historical scope binding is not enforced'
Assert-C32S ($c32rGate.Contains('scopeBinding=')) 'C32R truthful lifecycle output is missing'
Assert-C32S ([string]$state.historicalAudit.preMigrationHashes.'apps/mobile/test/core/design/mool_inner_chroma_emission_c22f_test.dart' -ceq 'EB2580A21C3BF3635AAD5D5DDA412E8E6CE250EB94AA4A4C02C2BC59104E08BD') 'C22F historical hash evidence differs'
Assert-C32S ((Get-FileHash -Algorithm SHA256 -LiteralPath $testPath).Hash -ceq 'F7BA34082DED2366B668E56E9E6F5D1985FDC00C4163A69E9F31CE86A287865D') 'C32S migrated C22F bytes differ'
Assert-C32S ($test.Contains("package:moolsocial/core/design/mool_theme.dart")) 'Mool theme test import missing'
Assert-C32S ($test.Contains('C32S ${family.$2} local indicator and dock chroma use current owners')) 'current family visual contract cases missing'
Assert-C32S ($test.Contains('MoolLocalNavigationTokens.destinationRailHeight')) 'current local destination height assertion missing'
Assert-C32S ($test.Contains('MoolLocalNavigationTokens.controlHeight')) 'dock capsule height assertion missing'
Assert-C32S ($test.Contains("ValueKey('moolsocial-local-primary-selected-indicator')")) 'local selected indicator assertion missing'
Assert-C32S ($test.Contains("ValueKey('moolsocial-local-secondary-pressed-scale')")) 'local press scale assertion missing'
Assert-C32S ($test.Contains("ValueKey('mool-action-`$`{family.`$1`}-selected-inner-chroma')")) 'dock inner chroma assertion missing'
Assert-C32S ($test.Contains('findsNothing')) 'removed local inner chroma rejection missing'
Assert-C32S ((Get-FileHash -Algorithm SHA256 -LiteralPath $designPath).Hash -ceq 'D66C9A8E34E49FF58DF25EF6DC0694B22DB91E5C33B6A04CA5CD7A63C7F76BFE') 'production design owner changed'

Assert-C32S (-not [bool]$scope.execution.runtimeWriteAuthorized) 'scope runtime authority opened'
Assert-C32S ([bool]$scope.execution.testOrGateWriteAuthorized) 'scope test/gate authority closed'
Assert-C32S (-not [bool]$scope.execution.referenceWriteAuthorized) 'scope reference authority opened'
Assert-C32S (-not [bool]$scope.execution.backendWriteAuthorized) 'scope backend authority opened'
Assert-C32S (-not [bool]$scope.execution.buildAuthorized) 'scope build authority opened'
Assert-C32S (-not [bool]$scope.execution.deviceInstallAuthorized) 'scope device authority opened'
Assert-C32S (-not [bool]$scope.execution.externalServiceWriteAuthorized) 'scope external authority opened'
Assert-C32S (-not [bool]$scope.execution.secretValueAccessAuthorized) 'scope secret authority opened'
Assert-C32S (-not [bool]$scope.protectedCandidateState.protectedBaselineUpdated) 'Buy protected baseline was changed'
Assert-C32S ([bool]$scope.protectedCandidateState.founderAcceptancePending) 'Buy protected founder hold was removed'

Write-Output "C32S C22F current navigation visual test successor gate passed: scopeBinding=$(if ($activeScope) { 'active' } else { 'preservedPrior' }); C22F=9; C27B=5; C27D=1; analyzer=clean; runtime=false; backend=false; build=false; device=false; external=false."
