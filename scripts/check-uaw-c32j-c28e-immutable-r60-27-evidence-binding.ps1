[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C32J([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C32J gate rejected: $Message" }
}

function Resolve-C32J([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C32J ($path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) "owner escaped repository: $RelativePath"
  Assert-C32J (Test-Path -LiteralPath $path -PathType Leaf) "owner missing: $RelativePath"
  return $path
}

function Read-C32J([string]$RelativePath) {
  return [IO.File]::ReadAllText((Resolve-C32J $RelativePath))
}

$ticket = Read-C32J 'config/uaw-c32j-personal-mvp-c28e-immutable-r60-27-evidence-binding-reconciliation-ticket.json' | ConvertFrom-Json
$scope = Read-C32J 'config/mvp-scope-gate-state.json' | ConvertFrom-Json
$contract = Read-C32J 'config/mvp-personal-android-navigation-host-qualification-c28e.json' | ConvertFrom-Json
$hostGate = Read-C32J 'scripts/check-personal-android-navigation-host-qualification-c28e.ps1'
$cycleOnePath = Resolve-C32J (Join-Path ([string]$contract.hostQualification.evidenceDirectory) 'qualifying-cycle-1.json')
$cycleTwoPath = Resolve-C32J (Join-Path ([string]$contract.hostQualification.evidenceDirectory) 'qualifying-cycle-2.json')
$cycleOne = Get-Content -Raw -LiteralPath $cycleOnePath | ConvertFrom-Json
$cycleTwo = Get-Content -Raw -LiteralPath $cycleTwoPath | ConvertFrom-Json

Assert-C32J ([string]$ticket.ticketId -ceq 'UAW-C32J-PERSONAL-MVP-C28E-IMMUTABLE-R60-27-EVIDENCE-BINDING-RECONCILIATION') 'ticket id changed'
Assert-C32J ([string]$ticket.classification -ceq 'mvp_supporting') 'ticket classification changed'
Assert-C32J ([bool]$ticket.authority.testAndGateWriteAuthorized) 'test/gate source authority is closed'
Assert-C32J (-not [bool]$ticket.authority.runtimeSourceWriteAuthorized) 'runtime source authority opened'
Assert-C32J (-not [bool]$ticket.authority.backendSourceWriteAuthorized) 'backend source authority opened'
Assert-C32J (-not [bool]$ticket.authority.buildAuthorized) 'build authority opened'
Assert-C32J (-not [bool]$ticket.authority.deviceMutationAuthorized) 'device authority opened'
Assert-C32J (-not [bool]$ticket.authority.externalCommunicationAuthorized) 'communication authority opened'
$activeScope = [string]$scope.ticket.id -ceq [string]$ticket.ticketId
if (-not $activeScope) {
  $prior = $scope.preTicketSelectionCheckpoint.priorC32JBlockedTicketAssessment
  Assert-C32J ($null -ne $prior) 'preserved prior C32J assessment is missing'
  Assert-C32J ([string]$prior.ticketId -ceq [string]$ticket.ticketId) 'preserved prior C32J ticket differs'
  Assert-C32J ([string]$prior.manifestSha256 -ceq '787C6D2E413CFBA3BBCC53B82EAD9EA456D4B6EC7A4D6A757883507E805783DB') 'preserved prior C32J manifest hash differs'
  Assert-C32J ([string]$prior.implementationState -ceq 'host_gate_repair_implemented_C28E_preflight_reaches_Buy_protected_baseline_hold') 'preserved prior C32J implementation state differs'
  Assert-C32J ((Get-FileHash -Algorithm SHA256 -LiteralPath (Resolve-C32J ([string]$prior.manifestPath))).Hash -ceq [string]$prior.manifestSha256) 'preserved prior C32J ticket bytes differ'
}
Assert-C32J ([bool]$scope.execution.testOrGateWriteAuthorized) 'scope test/gate authority is closed'
Assert-C32J (-not [bool]$scope.execution.referenceWriteAuthorized) 'scope reference authority opened'
Assert-C32J (-not [bool]$scope.execution.runtimeWriteAuthorized) 'scope runtime authority opened'
Assert-C32J (-not [bool]$scope.execution.backendWriteAuthorized) 'scope backend authority opened'
Assert-C32J (-not [bool]$scope.execution.buildAuthorized) 'scope build authority opened'
Assert-C32J (-not [bool]$scope.execution.deviceInstallAuthorized) 'scope device authority opened'
Assert-C32J (-not [bool]$scope.execution.externalServiceWriteAuthorized) 'scope external authority opened'
Assert-C32J (-not [bool]$scope.execution.secretValueAccessAuthorized) 'scope secret authority opened'

Assert-C32J (-not $hostGate.Contains("Resolve-C28EHostFile 'config/apk-regression-gate-state.json'")) 'historical host gate still reads the mutable current APK pointer'
foreach ($literal in @(
  'cycleOneEvidenceSha256',
  'cycleTwoEvidenceSha256',
  'qualifiedSourceFingerprint',
  'qualifying-cycle-1.json',
  'qualifying-cycle-2.json',
  'runtimeBuildInstall',
  'current APK pointer independent'
)) {
  Assert-C32J ($hostGate.Contains($literal)) "host gate evidence binding missing: $literal"
}

Assert-C32J ((Get-FileHash -Algorithm SHA256 -LiteralPath $cycleOnePath).Hash -ceq [string]$contract.hostQualification.cycleOneEvidenceSha256) 'cycle 1 evidence hash changed'
Assert-C32J ((Get-FileHash -Algorithm SHA256 -LiteralPath $cycleTwoPath).Hash -ceq [string]$contract.hostQualification.cycleTwoEvidenceSha256) 'cycle 2 evidence hash changed'
$expected = $contract.expectedInstalledPredecessor
foreach ($cycleSpec in @(
  [pscustomobject]@{ cycle = $cycleOne; number = 1 },
  [pscustomobject]@{ cycle = $cycleTwo; number = 2 }
)) {
  $cycle = $cycleSpec.cycle
  Assert-C32J ([int]$cycle.cycle -eq [int]$cycleSpec.number) "cycle $($cycleSpec.number) number changed"
  Assert-C32J ([string]$cycle.ticketId -ceq [string]$contract.ticketId) "cycle $($cycleSpec.number) ticket changed"
  Assert-C32J ([string]$cycle.sourceFingerprint -ceq [string]$contract.hostQualification.qualifiedSourceFingerprint) "cycle $($cycleSpec.number) source fingerprint changed"
  Assert-C32J ([int]$cycle.requiredTestFiles -eq 53) "cycle $($cycleSpec.number) test count changed"
  Assert-C32J ([int]$cycle.requiredGateCount -eq 22) "cycle $($cycleSpec.number) gate count changed"
  Assert-C32J ([string]$cycle.completeAnalysis -ceq 'clean') "cycle $($cycleSpec.number) analyzer result changed"
  Assert-C32J ([string]$cycle.completeRequiredSuite -ceq 'passed') "cycle $($cycleSpec.number) suite result changed"
  Assert-C32J ([string]$cycle.installedVersionName -ceq [string]$expected.versionName) "cycle $($cycleSpec.number) version name changed"
  Assert-C32J ([string]$cycle.installedVersionCode -ceq [string]$expected.versionCode) "cycle $($cycleSpec.number) version code changed"
  Assert-C32J ([string]$cycle.installedApkSha256 -ceq [string]$expected.apkSha256) "cycle $($cycleSpec.number) APK checksum changed"
  Assert-C32J ([string]$cycle.runtimeBuildInstall -ceq 'closed') "cycle $($cycleSpec.number) runtime/build/install boundary changed"
}

Write-Output 'C32J C28E immutable evidence gate passed: cycles=2; r60.27 exact; mutableApkPointer=false; build=false; device=false.'
