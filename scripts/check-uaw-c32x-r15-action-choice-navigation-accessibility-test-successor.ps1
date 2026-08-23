[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar
function Assert-C32X([bool]$Condition, [string]$Message) { if (-not $Condition) { throw "C32X gate rejected: $Message" } }
function Resolve-C32X([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C32X ($path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) "owner escaped repository: $RelativePath"
  Assert-C32X (Test-Path -LiteralPath $path -PathType Leaf) "owner missing: $RelativePath"
  return $path
}
function Read-C32X([string]$RelativePath) { return [IO.File]::ReadAllText((Resolve-C32X $RelativePath)) }

$ticketPath = Resolve-C32X 'config/uaw-c32x-personal-mvp-r15-action-choice-navigation-accessibility-test-successor-ticket.json'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Read-C32X 'config/mvp-scope-gate-state.json' | ConvertFrom-Json
$c32wGate = Read-C32X 'scripts/check-uaw-c32w-r15-current-mool-home-accessibility-test-successor.ps1'
$testPath = Resolve-C32X 'apps/mobile/test/ui_v2/universal/uaw_r15_personal_copy_fitment_accessibility_test.dart'
$test = [IO.File]::ReadAllText($testPath)
$runtimePath = Resolve-C32X 'apps/mobile/lib/ui_v2/universal/mvp_action_choice_root_v2.dart'
$authorityPath = Resolve-C32X 'apps/mobile/test/ui_v2/universal/uaw_personal_mvp_action_wording_wiring_navigation_fix2_test.dart'
$statePath = Resolve-C32X 'config/post-youtube-r15-action-choice-navigation-accessibility-state-c32x.json'
$state = Get-Content -Raw -LiteralPath $statePath | ConvertFrom-Json
Resolve-C32X 'docs/quality/UAW-C32X-R15-ACTION-CHOICE-NAVIGATION-ACCESSIBILITY-TEST-SUCCESSOR-QUALIFICATION-20260815.md' | Out-Null

Assert-C32X ([string]$ticket.ticketId -ceq 'UAW-C32X-PERSONAL-MVP-R15-ACTION-CHOICE-NAVIGATION-ACCESSIBILITY-TEST-SUCCESSOR') 'ticket id changed'
Assert-C32X ([string]$ticket.parentOutcome -ceq 'UAW-C32W-PERSONAL-MVP-R15-CURRENT-MOOL-HOME-ACCESSIBILITY-TEST-SUCCESSOR') 'parent outcome changed'
Assert-C32X ([string]$ticket.classification -ceq 'mvp_supporting') 'classification changed'
Assert-C32X (-not [bool]$ticket.authority.runtimeSourceWriteAuthorized) 'ticket runtime authority opened'
Assert-C32X ([bool]$ticket.authority.testAndGateWriteAuthorized) 'ticket test/gate authority closed'
Assert-C32X (-not [bool]$ticket.authority.backendSourceWriteAuthorized) 'ticket backend authority opened'
Assert-C32X (-not [bool]$ticket.authority.buildAuthorized) 'ticket build authority opened'
Assert-C32X (-not [bool]$ticket.authority.deviceMutationAuthorized) 'ticket device authority opened'
Assert-C32X (-not [bool]$ticket.authority.externalCommunicationAuthorized) 'ticket external authority opened'
Assert-C32X (-not [bool]$ticket.authority.secretValueAccessAuthorized) 'ticket secret authority opened'

$selected = $scope.preTicketSelectionCheckpoint.selectedTicketAssessment
$activeScope = [string]$scope.ticket.id -ceq [string]$ticket.ticketId
$assessment = if ($activeScope) {
  Assert-C32X ([string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq [string]$ticket.ticketId) 'pre-ticket current ticket differs'
  $selected
} else {
  $scope.preTicketSelectionCheckpoint.priorC32XQualifiedAssessment
}
Assert-C32X ($null -ne $assessment) 'active or preserved qualified C32X assessment is missing'
Assert-C32X ([string]$assessment.ticketId -ceq [string]$ticket.ticketId) 'C32X assessment ticket differs'
Assert-C32X ([string]$assessment.manifestSha256 -ceq 'C921671592E354C9634B454F8C066AB306C58101B1A617A5027D2E774FAE0AE0') 'C32X assessment ticket hash differs'
Assert-C32X ((Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash -ceq [string]$assessment.manifestSha256) 'C32X assessment ticket bytes differ'
Assert-C32X ([string]$assessment.implementationState -ceq 'test_only_successor_qualified_R15_16_FIX2_25_R03_11_C24B2_4_plus_1_declared_skip_zero_warnings_runtime_unchanged') 'C32X assessment implementation state differs'
Assert-C32X ([string]$assessment.evidencePath -ceq 'docs/quality/UAW-C32X-R15-ACTION-CHOICE-NAVIGATION-ACCESSIBILITY-TEST-SUCCESSOR-QUALIFICATION-20260815.md') 'C32X assessment evidence path differs'

$priorC32W = $scope.preTicketSelectionCheckpoint.priorC32WPartialAssessment
Assert-C32X ($null -ne $priorC32W) 'prior C32W assessment missing'
Assert-C32X ([string]$priorC32W.ticketId -ceq 'UAW-C32W-PERSONAL-MVP-R15-CURRENT-MOOL-HOME-ACCESSIBILITY-TEST-SUCCESSOR') 'prior C32W ticket differs'
Assert-C32X ([string]$priorC32W.manifestSha256 -ceq 'BF9E3F4695ABF55CB8D082E968FDD71244F16C0BA6EE3F3382235AA3937A610A') 'prior C32W hash differs'
Assert-C32X ($c32wGate.Contains('priorC32WPartialAssessment')) 'C32W historical scope binding is not enforced'
Assert-C32X ($c32wGate.Contains('scopeBinding=')) 'C32W truthful lifecycle output is missing'
Assert-C32X ((Get-FileHash -Algorithm SHA256 -LiteralPath $testPath).Hash -ceq 'F0AD3D0E6DCBE68C8C6BFEBD0AE19CF184A59DADA5118C3A165E0DA716A3DC88') 'C32X migrated R15 bytes differ'
Assert-C32X ($test.Contains("Key('mool-home-launcher')")) 'standalone Mool launcher assertion missing'
Assert-C32X ($test.Contains("Key('mool-connected-action-navigator')")) 'connected menu assertion missing'
Assert-C32X (([regex]::Matches($test, [regex]::Escape('tester.tap(find.byKey(launcherKey))'))).Count -eq 1) 'launcher open assertion differs'
Assert-C32X ($test.Contains("Key('mool-switcher-outside-dismiss')")) 'explicit outside-dismiss assertion missing'
Assert-C32X ($test.Contains('tester.tapAt(')) 'explicit outside-dismiss tap missing'
Assert-C32X ($test.Contains('outsideDismissRect.right - 8')) 'outside-dismiss coordinate assertion missing'
Assert-C32X ($test.Contains("expect(back, 0)")) 'outside-dismiss callback isolation assertion missing'
Assert-C32X ($test.Contains("expect(back, 1)")) 'root Back callback assertion missing'
Assert-C32X ($test.Contains("expect(mool, 0)")) 'removed direct Mool callback rejection missing'
Assert-C32X ($test.Contains("expect(chat, 0)")) 'removed Chat callback rejection missing'
Assert-C32X ((Get-FileHash -Algorithm SHA256 -LiteralPath $runtimePath).Hash -ceq '1D6D9664E832D3C149101E2F205376A52A48EC6C2888EE9BAFEC20D22F496C2C') 'action-choice runtime changed'
Assert-C32X ((Get-FileHash -Algorithm SHA256 -LiteralPath $authorityPath).Hash -ceq 'B73E73EDE9DF343B9DF37596472354683CD327FE89869CB759723156C2D6324B') 'current FIX2 authority changed'
Assert-C32X ((Get-FileHash -Algorithm SHA256 -LiteralPath $statePath).Hash -ceq '1E5A5B7DE020A6247F97210F5012A36F808391A1BB80BF84C7F3F72066189DBE') 'C32X machine state changed'
Assert-C32X ([string]$state.ticketId -ceq [string]$ticket.ticketId) 'C32X machine-state ticket differs'
Assert-C32X ([string]$state.state -ceq 'test_only_successor_qualified_zero_warning_runtime_unchanged') 'C32X machine-state qualification differs'
Assert-C32X ([int]$state.validation.R15.passed -eq 16 -and [int]$state.validation.R15.failed -eq 0 -and [int]$state.validation.R15.warnings -eq 0) 'C32X R15 machine result differs'
Assert-C32X ([int]$state.validation.FIX2.passed -eq 25 -and [int]$state.validation.FIX2.failed -eq 0) 'C32X FIX2 machine result differs'
Assert-C32X ([int]$state.validation.combinedC32STUVXR15SuccessorBatch.files -eq 5 -and [int]$state.validation.combinedC32STUVXR15SuccessorBatch.passed -eq 36 -and [int]$state.validation.combinedC32STUVXR15SuccessorBatch.failed -eq 0 -and [int]$state.validation.combinedC32STUVXR15SuccessorBatch.warnings -eq 0) 'C32X combined successor batch result differs'
Assert-C32X (-not [bool]$state.authority.runtimeChanged -and -not [bool]$state.authority.buildAuthorized -and -not [bool]$state.authority.deviceMutationAuthorized -and -not [bool]$state.authority.externalServiceWriteAuthorized) 'C32X machine-state authority opened'

Assert-C32X (-not [bool]$scope.execution.runtimeWriteAuthorized) 'scope runtime authority opened'
Assert-C32X ([bool]$scope.execution.testOrGateWriteAuthorized) 'scope test/gate authority closed'
Assert-C32X (-not [bool]$scope.execution.backendWriteAuthorized) 'scope backend authority opened'
Assert-C32X (-not [bool]$scope.execution.buildAuthorized) 'scope build authority opened'
Assert-C32X (-not [bool]$scope.execution.deviceInstallAuthorized) 'scope device authority opened'
Assert-C32X (-not [bool]$scope.execution.externalServiceWriteAuthorized) 'scope external authority opened'
Assert-C32X (-not [bool]$scope.execution.secretValueAccessAuthorized) 'scope secret authority opened'

Write-Output "C32X R15 action-choice navigation accessibility test successor gate passed: scopeBinding=$(if ($activeScope) { 'active' } else { 'preservedPrior' }); R15=16/16; warnings=0; FIX2=25/25; runtime=false; backend=false; build=false; device=false; external=false."
