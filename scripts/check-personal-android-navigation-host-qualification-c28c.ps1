[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

function Assert-C28C([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C28C gate rejected: $Message" }
}

function Resolve-C28CFile([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C28C ($path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) "owner escaped repository: $RelativePath"
  Assert-C28C (Test-Path -LiteralPath $path -PathType Leaf) "owner missing: $RelativePath"
  return $path
}

$contractPath = Resolve-C28CFile 'config/mvp-personal-android-navigation-host-qualification-c28c.json'
$contract = Get-Content -Raw -LiteralPath $contractPath | ConvertFrom-Json
$ticketPath = Resolve-C28CFile ([string]$contract.ticketManifestPath)
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath (Resolve-C28CFile 'config/mvp-scope-gate-state.json') | ConvertFrom-Json
$apk = Get-Content -Raw -LiteralPath (Resolve-C28CFile 'config/apk-regression-gate-state.json') | ConvertFrom-Json
$basePath = Resolve-C28CFile ([string]$contract.baseContract.path)
$base = Get-Content -Raw -LiteralPath $basePath | ConvertFrom-Json

Assert-C28C ([string]$contract.contractId -ceq 'UAW-PERSONAL-MVP-ANDROID-NAVIGATION-HOST-QUALIFICATION-C28C-20260810') 'contract id changed'
Assert-C28C ([string]$contract.ticketId -ceq 'UAW-PERSONAL-MVP-ANDROID-NAVIGATION-HOST-QUALIFICATION-FIX11-C28C') 'contract ticket changed'
Assert-C28C ((Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash -ceq [string]$contract.ticketManifestSha256) 'ticket manifest seal changed'
Assert-C28C ((Get-FileHash -Algorithm SHA256 -LiteralPath $basePath).Hash -ceq [string]$contract.baseContract.sha256) 'C27E base contract changed'
Assert-C28C (@($base.requiredTests).Count -eq [int]$contract.baseContract.requiredTestCount) 'base test inventory changed'
Assert-C28C (@($base.requiredGates).Count -eq [int]$contract.baseContract.requiredGateCount) 'base gate inventory changed'

$ticketState = [string]$ticket.state
Assert-C28C ($ticketState -cin @('active', 'complete')) 'unsupported ticket state'
if ($ticketState -ceq 'active') {
  Assert-C28C ([string]$scope.ticket.id -ceq [string]$ticket.ticketId) 'active scope ticket differs'
  Assert-C28C ([string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq [string]$ticket.ticketId) 'preselection ticket differs'
  Assert-C28C ([bool]$ticket.execution.referenceWriteAuthorized) 'active evidence authorization is closed'
  Assert-C28C ([bool]$ticket.execution.testOrGateWriteAuthorized) 'active test authorization is closed'
}
foreach ($closed in @(
  [bool]$ticket.execution.runtimeSourceWriteAuthorized,
  [bool]$ticket.execution.buildAuthorized,
  [bool]$ticket.execution.installAuthorized,
  [bool]$ticket.execution.backendWriteAuthorized,
  [bool]$ticket.execution.externalServiceWriteAuthorized,
  [bool]$scope.execution.buildAuthorized,
  [bool]$scope.execution.deviceInstallAuthorized,
  [bool]$scope.execution.backendWriteAuthorized,
  [bool]$scope.execution.externalServiceWriteAuthorized
)) {
  Assert-C28C (-not $closed) 'runtime, backend, build, install or external authority opened'
}

$tests = @($base.requiredTests) + @($contract.addedTests)
$gates = @($base.requiredGates | Where-Object { [string]$_ -cne [string]$contract.baseContract.replacedGate }) + @($contract.addedGates)
$formatOwners = @($base.formatOwners) + @($contract.addedFormatOwners)
$uniqueTests = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$uniqueGates = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$uniqueFormat = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($value in $tests) { [void]$uniqueTests.Add(([string]$value).Replace('\', '/')) }
foreach ($value in $gates) { [void]$uniqueGates.Add(([string]$value).Replace('\', '/')) }
foreach ($value in $formatOwners) { [void]$uniqueFormat.Add(([string]$value).Replace('\', '/')) }
Assert-C28C ($uniqueTests.Count -eq [int]$contract.expectedTotals.requiredTests) '53-file required suite drifted'
Assert-C28C ($uniqueGates.Count -eq [int]$contract.expectedTotals.requiredGates) '22-gate inventory drifted'
Assert-C28C ($uniqueFormat.Count -eq [int]$contract.expectedTotals.formatOwners) '4-owner format inventory drifted'
foreach ($relative in @($uniqueTests) + @($uniqueGates) + @($uniqueFormat)) {
  [void](Resolve-C28CFile ([string]$relative))
}
foreach ($relative in @($contract.completedPredecessorTickets)) {
  $predecessor = Get-Content -Raw -LiteralPath (Resolve-C28CFile ([string]$relative)) | ConvertFrom-Json
  Assert-C28C ([string]$predecessor.state -ceq 'complete') "predecessor ticket is not complete: $relative"
}

$expected = $contract.expectedInstalledPredecessor
Assert-C28C ([string]$apk.machineState -ceq [string]$expected.machineState) 'r60.26 machine state changed'
Assert-C28C ([string]$apk.buildAuthorization -ceq [string]$expected.buildAuthorization) 'r60.26 build authorization changed'
Assert-C28C ([string]$apk.installResult.installedVersionName -ceq [string]$expected.versionName) 'installed version name changed'
Assert-C28C ([string]$apk.installResult.installedVersionCode -ceq [string]$expected.versionCode) 'installed version code changed'
Assert-C28C ([string]$apk.installResult.installedBaseSha256 -ceq [string]$expected.apkSha256) 'installed checksum changed'
Assert-C28C (-not [bool]$apk.founderDeviceReview.successorBuildAuthorized) 'successor build authority opened early'
Assert-C28C (-not [bool]$apk.founderDeviceReview.successorInstallAuthorized) 'successor install authority opened early'
Assert-C28C ([int]$contract.hostQualification.requiredConsecutiveCycles -eq 2) 'two-cycle requirement changed'
Assert-C28C ([bool]$contract.hostQualification.unchangedSourceFingerprintRequired) 'unchanged fingerprint requirement closed'

Write-Output 'C28C aggregate host gate passed: tests=53; gates=22; formatOwners=4; cycles=2; r60.26 preserved; runtime/build/install closed.'
