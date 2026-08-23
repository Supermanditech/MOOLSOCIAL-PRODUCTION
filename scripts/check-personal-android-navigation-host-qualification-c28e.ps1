[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

function Assert-C28EHost([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C28E host gate rejected: $Message" }
}

function Resolve-C28EHostFile([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C28EHost ($path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) "owner escaped repository: $RelativePath"
  Assert-C28EHost (Test-Path -LiteralPath $path -PathType Leaf) "owner missing: $RelativePath"
  return $path
}

$contractPath = Resolve-C28EHostFile 'config/mvp-personal-android-navigation-host-qualification-c28e.json'
$contract = Get-Content -Raw -LiteralPath $contractPath | ConvertFrom-Json
$ticketPath = Resolve-C28EHostFile ([string]$contract.ticketManifestPath)
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath (Resolve-C28EHostFile 'config/mvp-scope-gate-state.json') | ConvertFrom-Json
$basePath = Resolve-C28EHostFile ([string]$contract.baseTopology.path)
$base = Get-Content -Raw -LiteralPath $basePath | ConvertFrom-Json
$c28cPath = Resolve-C28EHostFile ([string]$contract.reusedC28CTopology.path)
$cycleOnePath = Resolve-C28EHostFile (Join-Path ([string]$contract.hostQualification.evidenceDirectory) 'qualifying-cycle-1.json')
$cycleTwoPath = Resolve-C28EHostFile (Join-Path ([string]$contract.hostQualification.evidenceDirectory) 'qualifying-cycle-2.json')
$cycleOne = Get-Content -Raw -LiteralPath $cycleOnePath | ConvertFrom-Json
$cycleTwo = Get-Content -Raw -LiteralPath $cycleTwoPath | ConvertFrom-Json

Assert-C28EHost ([string]$contract.contractId -ceq 'UAW-PERSONAL-MVP-ANDROID-NAVIGATION-HOST-QUALIFICATION-C28E-20260810') 'contract id changed'
Assert-C28EHost ((Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash -ceq [string]$contract.ticketManifestSha256) 'ticket manifest seal changed'
Assert-C28EHost ((Get-FileHash -Algorithm SHA256 -LiteralPath $basePath).Hash -ceq [string]$contract.baseTopology.sha256) 'C27E base topology changed'
Assert-C28EHost ((Get-FileHash -Algorithm SHA256 -LiteralPath $c28cPath).Hash -ceq [string]$contract.reusedC28CTopology.sha256) 'C28C topology evidence changed'
Assert-C28EHost ((Get-FileHash -Algorithm SHA256 -LiteralPath $cycleOnePath).Hash -ceq [string]$contract.hostQualification.cycleOneEvidenceSha256) 'C28E qualifying cycle 1 evidence changed'
Assert-C28EHost ((Get-FileHash -Algorithm SHA256 -LiteralPath $cycleTwoPath).Hash -ceq [string]$contract.hostQualification.cycleTwoEvidenceSha256) 'C28E qualifying cycle 2 evidence changed'
Assert-C28EHost (@($base.requiredTests).Count -eq [int]$contract.baseTopology.requiredTestCount) 'base test inventory changed'
Assert-C28EHost (@($base.requiredGates).Count -eq [int]$contract.baseTopology.requiredGateCount) 'base gate inventory changed'

$ticketState = [string]$ticket.state
Assert-C28EHost ($ticketState -cin @('active', 'complete')) 'unsupported ticket state'
if ($ticketState -ceq 'active') {
  Assert-C28EHost ([string]$scope.ticket.id -ceq [string]$ticket.ticketId) 'active scope ticket differs'
  Assert-C28EHost ([string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq [string]$ticket.ticketId) 'preselection ticket differs'
  Assert-C28EHost ([bool]$ticket.execution.referenceWriteAuthorized) 'active evidence authorization is closed'
  Assert-C28EHost ([bool]$ticket.execution.runtimeSourceWriteAuthorized) 'active runtime authorization is closed'
  Assert-C28EHost ([bool]$ticket.execution.testOrGateWriteAuthorized) 'active test authorization is closed'
}

foreach ($closed in @(
  [bool]$ticket.execution.buildAuthorized,
  [bool]$ticket.execution.installAuthorized,
  [bool]$ticket.execution.backendWriteAuthorized,
  [bool]$ticket.execution.externalServiceWriteAuthorized,
  [bool]$scope.execution.buildAuthorized,
  [bool]$scope.execution.deviceInstallAuthorized,
  [bool]$scope.execution.backendWriteAuthorized,
  [bool]$scope.execution.externalServiceWriteAuthorized
)) {
  Assert-C28EHost (-not $closed) 'build, install, backend or external authority opened before qualification'
}

$tests = @($base.requiredTests) + @($contract.addedTests)
$gates = @($base.requiredGates | Where-Object { [string]$_ -cne [string]$contract.baseTopology.replacedGate }) + @($contract.addedGates)
$formatOwners = @($base.formatOwners) + @($contract.addedFormatOwners)
$uniqueTests = @($tests | Sort-Object -Unique)
$uniqueGates = @($gates | Sort-Object -Unique)
$uniqueFormat = @($formatOwners | Sort-Object -Unique)
Assert-C28EHost ($uniqueTests.Count -eq [int]$contract.expectedTotals.requiredTests) '53-file required suite drifted'
Assert-C28EHost ($uniqueGates.Count -eq [int]$contract.expectedTotals.requiredGates) '22-gate inventory drifted'
Assert-C28EHost ($uniqueFormat.Count -eq [int]$contract.expectedTotals.formatOwners) '4-owner format inventory drifted'
foreach ($relative in @($uniqueTests) + @($uniqueGates) + @($uniqueFormat)) {
  [void](Resolve-C28EHostFile ([string]$relative))
}
foreach ($predecessorSpec in @($contract.predecessorStates)) {
  $predecessor = Get-Content -Raw -LiteralPath (Resolve-C28EHostFile ([string]$predecessorSpec.path)) | ConvertFrom-Json
  Assert-C28EHost ([string]$predecessor.state -ceq [string]$predecessorSpec.state) "predecessor state changed: $($predecessorSpec.path)"
}
foreach ($seal in @($contract.protectedRuntimeSeals)) {
  $sealPath = Resolve-C28EHostFile ([string]$seal.path)
  if ($seal.PSObject.Properties.Name -ccontains 'manifestSha256') {
    Assert-C28EHost ((Get-FileHash -Algorithm SHA256 -LiteralPath $sealPath).Hash -ceq [string]$seal.manifestSha256) "protected manifest changed: $($seal.id)"
  }
}

$expected = $contract.expectedInstalledPredecessor
Assert-C28EHost ([int]$contract.hostQualification.requiredConsecutiveCycles -eq 2) 'two-cycle requirement changed'
Assert-C28EHost ([bool]$contract.hostQualification.unchangedSourceFingerprintRequired) 'stable fingerprint requirement closed'
foreach ($cycleSpec in @(
  [pscustomobject]@{ cycle = $cycleOne; number = 1 },
  [pscustomobject]@{ cycle = $cycleTwo; number = 2 }
)) {
  $cycle = $cycleSpec.cycle
  Assert-C28EHost ([string]$cycle.ticketId -ceq [string]$contract.ticketId) "qualifying cycle $($cycleSpec.number) ticket changed"
  Assert-C28EHost ([int]$cycle.cycle -eq [int]$cycleSpec.number) "qualifying cycle $($cycleSpec.number) number changed"
  Assert-C28EHost ([string]$cycle.sourceFingerprint -ceq [string]$contract.hostQualification.qualifiedSourceFingerprint) "qualifying cycle $($cycleSpec.number) source fingerprint changed"
  Assert-C28EHost ([string]$cycle.fingerprintAlgorithm -ceq [string]$contract.hostQualification.sourceFingerprintAlgorithm) "qualifying cycle $($cycleSpec.number) fingerprint algorithm changed"
  Assert-C28EHost ([int]$cycle.requiredTestFiles -eq [int]$contract.expectedTotals.requiredTests) "qualifying cycle $($cycleSpec.number) test count changed"
  Assert-C28EHost ([int]$cycle.requiredGateCount -eq [int]$contract.expectedTotals.requiredGates) "qualifying cycle $($cycleSpec.number) gate count changed"
  Assert-C28EHost ([string]$cycle.format -ceq 'clean') "qualifying cycle $($cycleSpec.number) format result changed"
  Assert-C28EHost ([string]$cycle.completeAnalysis -ceq 'clean') "qualifying cycle $($cycleSpec.number) analyzer result changed"
  Assert-C28EHost ([string]$cycle.completeRequiredSuite -ceq 'passed') "qualifying cycle $($cycleSpec.number) suite result changed"
  Assert-C28EHost ([string]$cycle.installedVersionName -ceq [string]$expected.versionName) "qualifying cycle $($cycleSpec.number) installed version name changed"
  Assert-C28EHost ([string]$cycle.installedVersionCode -ceq [string]$expected.versionCode) "qualifying cycle $($cycleSpec.number) installed version code changed"
  Assert-C28EHost ([string]$cycle.installedApkSha256 -ceq [string]$expected.apkSha256) "qualifying cycle $($cycleSpec.number) installed checksum changed"
  Assert-C28EHost ([string]$cycle.runtimeBuildInstall -ceq 'closed') "qualifying cycle $($cycleSpec.number) runtime/build/install boundary changed"
}

Write-Output 'C28E aggregate host gate passed: tests=53; gates=22; formatOwners=4; cycles=2; r60.27 immutable evidence preserved; current APK pointer independent; buildInstall=false.'
