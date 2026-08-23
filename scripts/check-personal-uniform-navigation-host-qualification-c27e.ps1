[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

function Assert-C27E([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C27E gate rejected: $Message" }
}

function Resolve-C27EFile([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C27E ($path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) "owner escaped repository: $RelativePath"
  Assert-C27E (Test-Path -LiteralPath $path -PathType Leaf) "owner missing: $RelativePath"
  return $path
}

$qualificationPath = Resolve-C27EFile 'config/mvp-personal-uniform-navigation-host-qualification-c27e.json'
$ticketPath = Resolve-C27EFile 'config/uaw-personal-mvp-uniform-navigation-host-qualification-fix10-c27e-ticket.json'
$scopePath = Resolve-C27EFile 'config/mvp-scope-gate-state.json'
$apkPath = Resolve-C27EFile 'config/apk-regression-gate-state.json'
$qualification = Get-Content -Raw -LiteralPath $qualificationPath | ConvertFrom-Json
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$apk = Get-Content -Raw -LiteralPath $apkPath | ConvertFrom-Json
$ticketSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash
$expectedTicket = 'UAW-PERSONAL-MVP-UNIFORM-NAVIGATION-HOST-QUALIFICATION-FIX10-C27E'

Assert-C27E ([string]$qualification.contractId -ceq 'UAW-PERSONAL-MVP-UNIFORM-NAVIGATION-HOST-QUALIFICATION-C27E-20260810') 'contract id changed'
Assert-C27E ([string]$qualification.ticketId -ceq $expectedTicket) 'contract ticket changed'
Assert-C27E ([string]$qualification.ticketManifestSha256 -ceq $ticketSha) 'ticket manifest seal changed'
Assert-C27E ([string]$qualification.state -ceq 'selected_host_qualification_execution_open') 'contract execution state changed'
Assert-C27E ([string]$ticket.ticketId -ceq $expectedTicket) 'ticket id changed'
$ticketState = [string]$ticket.state
Assert-C27E ($ticketState -cin @('active', 'complete')) 'unsupported ticket state'
if ($ticketState -ceq 'active') {
  Assert-C27E ([string]$scope.ticket.id -ceq $expectedTicket) 'active scope ticket differs'
  Assert-C27E ([string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq $expectedTicket) 'preselection ticket differs'
  Assert-C27E ([string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -ceq $ticketSha) 'preselection manifest seal changed'
  Assert-C27E ([bool]$ticket.execution.referenceWriteAuthorized) 'active evidence authorization is closed'
  Assert-C27E ([bool]$ticket.execution.testOrGateWriteAuthorized) 'active gate authorization is closed'
  Assert-C27E ([bool]$scope.execution.runtimeWriteAuthorized) 'active qualification write authorization is closed'
  Assert-C27E (-not [bool]$scope.execution.buildAuthorized) 'build authorization opened early'
  Assert-C27E (-not [bool]$scope.execution.deviceInstallAuthorized) 'install authorization opened early'
} else {
  Assert-C27E (-not [bool]$ticket.execution.referenceWriteAuthorized) 'completed ticket retains evidence authorization'
  Assert-C27E (-not [bool]$ticket.execution.testOrGateWriteAuthorized) 'completed ticket retains gate authorization'
}

foreach ($closed in @(
  [bool]$qualification.authority.runtimeMutationAuthorized,
  [bool]$qualification.authority.buildAuthorized,
  [bool]$qualification.authority.installAuthorized,
  [bool]$qualification.authority.externalWriteAuthorized,
  [bool]$ticket.execution.runtimeSourceWriteAuthorized,
  [bool]$ticket.execution.buildAuthorized,
  [bool]$ticket.execution.installAuthorized,
  [bool]$ticket.execution.backendWriteAuthorized,
  [bool]$ticket.execution.externalServiceWriteAuthorized
)) {
  Assert-C27E (-not $closed) 'runtime, backend, build, install or external authority opened'
}

foreach ($relative in @($qualification.completedPredecessorTickets)) {
  $predecessor = Get-Content -Raw -LiteralPath (Resolve-C27EFile ([string]$relative)) | ConvertFrom-Json
  Assert-C27E ([string]$predecessor.state -ceq 'complete') "predecessor ticket is not complete: $relative"
}

$requiredTests = @($qualification.requiredTests | ForEach-Object { ([string]$_).Replace('\', '/') })
$requiredGates = @($qualification.requiredGates | ForEach-Object { ([string]$_).Replace('\', '/') })
$uniqueTests = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$uniqueGates = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($relative in $requiredTests) { [void]$uniqueTests.Add($relative) }
foreach ($relative in $requiredGates) { [void]$uniqueGates.Add($relative) }
Assert-C27E ($requiredTests.Count -eq 51 -and $uniqueTests.Count -eq 51) '51-file required suite drifted'
Assert-C27E ($requiredGates.Count -eq 21 -and $uniqueGates.Count -eq 21) '21-gate inventory drifted'
Assert-C27E (@($qualification.formatOwners).Count -eq 2) 'format owner inventory drifted'
Assert-C27E (@($qualification.protectedRuntimeSeals).Count -eq 2) 'protected seal inventory drifted'
Assert-C27E ([int]$qualification.hostQualification.requiredConsecutiveCycles -eq 2) 'two-cycle requirement changed'
Assert-C27E ([bool]$qualification.hostQualification.unchangedSourceFingerprintRequired) 'unchanged fingerprint requirement closed'
Assert-C27E ([bool]$qualification.hostQualification.completeAnalysisRequired) 'complete analysis requirement closed'
Assert-C27E ([bool]$qualification.hostQualification.completeRequiredSuiteRequired) 'complete suite requirement closed'
Assert-C27E ([string]$qualification.hostQualification.sourceFingerprintAlgorithm -ceq 'SHA256_OF_SORTED_PER_FILE_SHA256_AND_REPOSITORY_RELATIVE_PATH_USING_LF') 'fingerprint algorithm changed'
foreach ($relative in @($requiredTests) + @($requiredGates) + @($qualification.formatOwners)) {
  [void](Resolve-C27EFile ([string]$relative))
}

$referencePath = Resolve-C27EFile ([string]$qualification.approvedReference.source)
$packagePath = [IO.Path]::GetFullPath((Join-Path $root ([string]$qualification.approvedReference.immutablePackage)))
Assert-C27E ((Get-FileHash -Algorithm SHA256 -LiteralPath $referencePath).Hash -ceq [string]$qualification.approvedReference.sourceSha256) 'approved HTML source seal changed'
Assert-C27E (Test-Path -LiteralPath $packagePath -PathType Container) 'immutable approved reference package is missing'

$expectedSeal = @{
  social = @{ files = 178; sha = '9d79db1aa83d52d26e5f4a494315a7c213a504da6cba231346772aadac9af4e5' }
  buy = @{ files = 43; sha = '37d946cd050d378a9ee60fd8b19716f59acba25dbc0c0593a9136668fcd120e7' }
}
foreach ($sealSpec in @($qualification.protectedRuntimeSeals)) {
  $sealId = [string]$sealSpec.id
  Assert-C27E ($expectedSeal.ContainsKey($sealId)) "unexpected protected seal: $sealId"
  $seal = Get-Content -Raw -LiteralPath (Resolve-C27EFile ([string]$sealSpec.path)) | ConvertFrom-Json
  $expected = $expectedSeal[$sealId]
  Assert-C27E ([int]$seal.protectedRuntime.fileCount -eq [int]$expected.files) "$sealId protected file count changed"
  Assert-C27E ([string]$seal.protectedRuntime.portableTreeSha256 -ceq [string]$expected.sha) "$sealId protected tree changed"
  Assert-C27E ([int]$sealSpec.expectedFiles -eq [int]$expected.files) "$sealId contract file count changed"
  Assert-C27E ([string]$sealSpec.portableTreeSha256 -ceq [string]$expected.sha) "$sealId contract tree changed"
}

$expectedApk = $qualification.expectedInstalledPredecessor
Assert-C27E ([string]$apk.machineState -ceq [string]$expectedApk.machineState) 'installed predecessor machine state changed'
Assert-C27E ([string]$apk.buildAuthorization -ceq [string]$expectedApk.buildAuthorization) 'predecessor build authorization changed'
Assert-C27E ([string]$apk.installResult.installedVersionName -ceq [string]$expectedApk.versionName) 'installed predecessor version name changed'
Assert-C27E ([string]$apk.installResult.installedVersionCode -ceq [string]$expectedApk.versionCode) 'installed predecessor version code changed'
Assert-C27E ([string]$apk.installResult.installedBaseSha256 -ceq [string]$expectedApk.apkSha256) 'installed predecessor checksum changed'
Assert-C27E (-not [bool]$apk.founderDeviceReview.successorBuildAuthorized) 'successor build authority opened early'
Assert-C27E (-not [bool]$apk.founderDeviceReview.successorInstallAuthorized) 'successor install authority opened early'

Write-Output 'C27E aggregate gate passed: C27A-D complete; tests=51; gates=21; cycles=2; SocialSeal=178; BuySeal=43; r60.25Preserved=true; runtimeBuildInstall=closed.'
