[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar
function Assert-C32W([bool]$Condition, [string]$Message) { if (-not $Condition) { throw "C32W gate rejected: $Message" } }
function Resolve-C32W([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C32W ($path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) "owner escaped repository: $RelativePath"
  Assert-C32W (Test-Path -LiteralPath $path -PathType Leaf) "owner missing: $RelativePath"
  return $path
}
function Read-C32W([string]$RelativePath) { return [IO.File]::ReadAllText((Resolve-C32W $RelativePath)) }

$ticketPath = Resolve-C32W 'config/uaw-c32w-personal-mvp-r15-current-mool-home-accessibility-test-successor-ticket.json'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Read-C32W 'config/mvp-scope-gate-state.json' | ConvertFrom-Json
$c32vGate = Read-C32W 'scripts/check-uaw-c32v-c20f-c20h-aggregate-contract-test-successor.ps1'
$testPath = Resolve-C32W 'apps/mobile/test/ui_v2/universal/uaw_r15_personal_copy_fitment_accessibility_test.dart'
$test = [IO.File]::ReadAllText($testPath)
$rootPath = Resolve-C32W 'apps/mobile/lib/ui_v2/universal/personal_mool_root_v2.dart'

Assert-C32W ([string]$ticket.ticketId -ceq 'UAW-C32W-PERSONAL-MVP-R15-CURRENT-MOOL-HOME-ACCESSIBILITY-TEST-SUCCESSOR') 'ticket id changed'
Assert-C32W ([string]$ticket.classification -ceq 'mvp_supporting') 'classification changed'
Assert-C32W (-not [bool]$ticket.authority.runtimeSourceWriteAuthorized) 'ticket runtime authority opened'
Assert-C32W ([bool]$ticket.authority.testAndGateWriteAuthorized) 'ticket test/gate authority closed'
Assert-C32W (-not [bool]$ticket.authority.backendSourceWriteAuthorized) 'ticket backend authority opened'
Assert-C32W (-not [bool]$ticket.authority.buildAuthorized) 'ticket build authority opened'
Assert-C32W (-not [bool]$ticket.authority.deviceMutationAuthorized) 'ticket device authority opened'
Assert-C32W (-not [bool]$ticket.authority.externalCommunicationAuthorized) 'ticket external authority opened'
Assert-C32W (-not [bool]$ticket.authority.secretValueAccessAuthorized) 'ticket secret authority opened'

$selected = $scope.preTicketSelectionCheckpoint.selectedTicketAssessment
$activeScope = [string]$scope.ticket.id -ceq [string]$ticket.ticketId
$c32xTicketId = 'UAW-C32X-PERSONAL-MVP-R15-ACTION-CHOICE-NAVIGATION-ACCESSIBILITY-TEST-SUCCESSOR'
$c32xActive = [string]$scope.ticket.id -ceq $c32xTicketId
if ($activeScope) {
  Assert-C32W ([string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq [string]$ticket.ticketId) 'pre-ticket current ticket differs'
  Assert-C32W ([string]$selected.ticketId -ceq [string]$ticket.ticketId) 'selected ticket differs'
  Assert-C32W ([string]$selected.manifestSha256 -ceq 'BF9E3F4695ABF55CB8D082E968FDD71244F16C0BA6EE3F3382235AA3937A610A') 'selected ticket hash differs'
  Assert-C32W ((Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash -ceq [string]$selected.manifestSha256) 'selected ticket bytes differ'
  Assert-C32W ([string]$selected.implementationState -ceq 'known_R15_Mool_Home_root_portions_migrated_15_passed_one_hidden_action_choice_failure_preserved_separate_C32X_required') 'selected implementation state differs'
} else {
  $priorC32W = $scope.preTicketSelectionCheckpoint.priorC32WPartialAssessment
  Assert-C32W ($null -ne $priorC32W) 'preserved prior C32W assessment is missing'
  Assert-C32W ([string]$priorC32W.ticketId -ceq [string]$ticket.ticketId) 'preserved prior C32W ticket differs'
  Assert-C32W ([string]$priorC32W.manifestSha256 -ceq 'BF9E3F4695ABF55CB8D082E968FDD71244F16C0BA6EE3F3382235AA3937A610A') 'preserved prior C32W hash differs'
  Assert-C32W ([string]$priorC32W.implementationState -ceq 'known_R15_Mool_Home_root_portions_migrated_15_passed_one_hidden_action_choice_failure_preserved_separate_C32X_required') 'preserved prior C32W implementation state differs'
  Assert-C32W ((Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash -ceq [string]$priorC32W.manifestSha256) 'preserved prior C32W ticket bytes differ'

  $c32xAssessment = if ($c32xActive) {
    $selected
  } else {
    $scope.preTicketSelectionCheckpoint.priorC32XQualifiedAssessment
  }
  Assert-C32W ($null -ne $c32xAssessment) 'active or preserved qualified C32X assessment is missing'
  Assert-C32W ([string]$c32xAssessment.ticketId -ceq $c32xTicketId) 'C32X assessment ticket differs'
  Assert-C32W ([string]$c32xAssessment.manifestSha256 -ceq 'C921671592E354C9634B454F8C066AB306C58101B1A617A5027D2E774FAE0AE0') 'C32X assessment hash differs'
}

$priorC32V = $scope.preTicketSelectionCheckpoint.priorC32VQualifiedAssessment
Assert-C32W ($null -ne $priorC32V) 'prior C32V assessment missing'
Assert-C32W ([string]$priorC32V.ticketId -ceq 'UAW-C32V-PERSONAL-MVP-C20F-C20H-AGGREGATE-CONTRACT-TEST-SUCCESSOR') 'prior C32V ticket differs'
Assert-C32W ([string]$priorC32V.manifestSha256 -ceq '04C4ADAEA414053B8C0CFE45C35B74E8A40D7E383E5FF6FEE62DA8FD97AE9A8B') 'prior C32V hash differs'
Assert-C32W ($c32vGate.Contains('priorC32VQualifiedAssessment')) 'C32V historical scope binding is not enforced'
Assert-C32W ($c32vGate.Contains('scopeBinding=')) 'C32V truthful lifecycle output is missing'
$expectedTestHash = if ($activeScope) {
  '0331232117ACAC11D3D0B431CD828D927A0EC8A6066A87830A179B484E5B7262'
} else {
  'F0AD3D0E6DCBE68C8C6BFEBD0AE19CF184A59DADA5118C3A165E0DA716A3DC88'
}
Assert-C32W ((Get-FileHash -Algorithm SHA256 -LiteralPath $testPath).Hash -ceq $expectedTestHash) 'C32W/C32X lifecycle-bound R15 bytes differ'
Assert-C32W ($test.Contains("ValueKey('mool-home-family-`$`{family.id`}')")) 'fixed Mool Home family assertion missing'
Assert-C32W ($test.Contains("Key('mool-home-chat')")) 'current Mool Home Chat assertion missing'
Assert-C32W ($test.Contains('onOpenRoute: openedMool.add')) 'current Mool Home route callback coverage missing'
Assert-C32W (-not $test.Contains("Key('mool-root-main-actions')")) 'obsolete root action rail remains'
Assert-C32W ((Get-FileHash -Algorithm SHA256 -LiteralPath $rootPath).Hash -ceq 'F73F8CC73417ED07B2816B41E5B8E3FA7015D5584E7769DC967F61EDF2573FDA') 'production Mool Home owner changed'

Assert-C32W (-not [bool]$scope.execution.runtimeWriteAuthorized) 'scope runtime authority opened'
Assert-C32W ([bool]$scope.execution.testOrGateWriteAuthorized) 'scope test/gate authority closed'
Assert-C32W (-not [bool]$scope.execution.backendWriteAuthorized) 'scope backend authority opened'
Assert-C32W (-not [bool]$scope.execution.buildAuthorized) 'scope build authority opened'
Assert-C32W (-not [bool]$scope.execution.deviceInstallAuthorized) 'scope device authority opened'
Assert-C32W (-not [bool]$scope.execution.externalServiceWriteAuthorized) 'scope external authority opened'
Assert-C32W (-not [bool]$scope.execution.secretValueAccessAuthorized) 'scope secret authority opened'

$r15State = if ($activeScope) { '15pass/1hiddenFail' } else { 'C32X-successor-16pass' }
Write-Output "C32W R15 current Mool Home accessibility test successor gate passed: scopeBinding=$(if ($activeScope) { 'active' } else { 'preservedPrior' }); knownRootPortions=migrated; R15=$r15State; runtime=false; backend=false; build=false; device=false; external=false."
