[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

$expectedTicket = 'UAW-PERSONAL-MVP-APPROVED-NAVIGATION-HOST-QUALIFICATION-FIX9-C26G'
$expectedSuccessor = 'UAW-PERSONAL-MVP-APPROVED-NAVIGATION-OPPO-QUALIFICATION-FIX9-C26H'
$qualificationPath = Join-Path $root 'config\mvp-personal-approved-navigation-host-qualification-c26g.json'
$ticketPath = Join-Path $root 'config\uaw-personal-mvp-approved-navigation-host-qualification-fix9-c26g-ticket.json'
$parentPath = Join-Path $root 'config\uaw-personal-mvp-approved-html-embedded-navigation-shell-recovery-fix9-c26-ticket.json'
$scopePath = Join-Path $root 'config\mvp-scope-gate-state.json'
$apkPath = Join-Path $root 'config\apk-regression-gate-state.json'

foreach ($path in @($qualificationPath, $ticketPath, $parentPath, $scopePath, $apkPath)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "C26G required owner is missing: $path"
  }
}

$qualification = Get-Content -Raw -LiteralPath $qualificationPath | ConvertFrom-Json
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$parent = Get-Content -Raw -LiteralPath $parentPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$apk = Get-Content -Raw -LiteralPath $apkPath | ConvertFrom-Json
$ticketSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash
$selfChild = @($parent.children | Where-Object { [string]$_.ticketId -ceq $expectedTicket })
$activeState = (
  [string]$ticket.state -ceq 'selected_host_qualification_gate_writes_authorized' -and
  [string]$scope.ticket.id -ceq $expectedTicket -and
  [string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq $expectedTicket -and
  [string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -ceq $ticketSha -and
  [string]$parent.execution.currentChild -ceq $expectedTicket -and
  $selfChild.Count -eq 1 -and [string]$selfChild[0].state -ceq 'selected'
)
$completedState = (
  [string]$ticket.state -ceq 'complete' -and
  [string]$scope.ticket.id -ceq $expectedSuccessor -and
  [string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq $expectedSuccessor -and
  [string]$parent.execution.currentChild -ceq $expectedSuccessor -and
  $selfChild.Count -eq 1 -and [string]$selfChild[0].state -ceq 'complete'
)

if ([string]$qualification.contractId -cne 'UAW-PERSONAL-MVP-APPROVED-NAVIGATION-HOST-QUALIFICATION-C26G-20260810' -or
    [string]$qualification.ticketId -cne $expectedTicket -or
    [string]$qualification.ticketManifestSha256 -cne $ticketSha -or
    [string]$qualification.state -cne 'selected_host_qualification_execution_open' -or
    [string]$ticket.ticketId -cne $expectedTicket -or
    -not ($activeState -or $completedState) -or
    [bool]$scope.execution.backendWriteAuthorized -or
    [bool]$scope.execution.buildAuthorized -or
    [bool]$scope.execution.deviceInstallAuthorized -or
    [bool]$scope.execution.externalServiceWriteAuthorized -or
    [bool]$qualification.authority.runtimeMutationAuthorized -or
    [bool]$qualification.authority.buildAuthorized -or
    [bool]$qualification.authority.installAuthorized -or
    [bool]$qualification.authority.externalWriteAuthorized -or
    [bool]$ticket.execution.runtimeSourceWriteAuthorized -or
    [bool]$ticket.execution.buildAuthorized -or
    [bool]$ticket.execution.installAuthorized) {
  throw 'C26G identity, manifest seal or closed runtime/backend/build/install/external authority is invalid.'
}

foreach ($childId in @(
  'UAW-PERSONAL-MVP-APPROVED-HTML-NAVIGATION-REFERENCE-FREEZE-FIX9-C26A',
  'UAW-PERSONAL-MVP-TRANSPARENT-UNBOXED-DESTINATION-RAIL-FIX9-C26B',
  'UAW-PERSONAL-MVP-EMBEDDED-VERTICAL-MOOL-SWITCHER-FIX9-C26C',
  'UAW-PERSONAL-MVP-SOCIAL-SHOP-NAVIGATION-CONFORMANCE-FIX9-C26D',
  'UAW-PERSONAL-MVP-FOOD-TRAVEL-NAVIGATION-CONFORMANCE-FIX9-C26E',
  'UAW-PERSONAL-MVP-CARE-WORK-NAVIGATION-CONFORMANCE-FIX9-C26F'
)) {
  $child = @($parent.children | Where-Object { [string]$_.ticketId -ceq $childId })
  if ($child.Count -ne 1 -or [string]$child[0].state -cne 'complete') {
    throw "C26G refuses incomplete predecessor child: $childId"
  }
}

$requiredTests = @($qualification.requiredTests | ForEach-Object { ([string]$_).Replace('\', '/') })
$requiredGates = @($qualification.requiredGates | ForEach-Object { ([string]$_).Replace('\', '/') })
$uniqueTests = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$uniqueGates = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($relative in $requiredTests) { [void]$uniqueTests.Add($relative) }
foreach ($relative in $requiredGates) { [void]$uniqueGates.Add($relative) }
if ($requiredTests.Count -ne 48 -or $uniqueTests.Count -ne 48 -or
    $requiredGates.Count -ne 18 -or $uniqueGates.Count -ne 18 -or
    @($qualification.formatOwners).Count -ne 2 -or
    @($qualification.protectedRuntimeSeals).Count -ne 2 -or
    [int]$qualification.hostQualification.requiredConsecutiveCycles -ne 2 -or
    -not [bool]$qualification.hostQualification.unchangedSourceFingerprintRequired -or
    -not [bool]$qualification.hostQualification.completeAnalysisRequired -or
    -not [bool]$qualification.hostQualification.completeRequiredSuiteRequired -or
    [string]$qualification.hostQualification.sourceFingerprintAlgorithm -cne 'SHA256_OF_SORTED_PER_FILE_SHA256_AND_REPOSITORY_RELATIVE_PATH_USING_LF') {
  throw 'C26G 48-test, 18-gate, format, seal or two-cycle inventory drifted.'
}
foreach ($relative in @($requiredTests) + @($requiredGates) + @($qualification.formatOwners)) {
  if (-not (Test-Path -LiteralPath (Join-Path $root ([string]$relative)))) {
    throw "C26G required test, gate or format owner is missing: $relative"
  }
}

$referencePath = Join-Path $root ([string]$qualification.approvedReference.source)
$packagePath = Join-Path $root ([string]$qualification.approvedReference.immutablePackage)
if (-not (Test-Path -LiteralPath $referencePath -PathType Leaf) -or
    (Get-FileHash -Algorithm SHA256 -LiteralPath $referencePath).Hash -cne [string]$qualification.approvedReference.sourceSha256 -or
    -not (Test-Path -LiteralPath $packagePath -PathType Container)) {
  throw 'C26G approved HTML source or immutable reference package drifted.'
}

$expectedSeal = @{
  social = @{ files = 178; sha = '9d79db1aa83d52d26e5f4a494315a7c213a504da6cba231346772aadac9af4e5' }
  buy = @{ files = 43; sha = '37d946cd050d378a9ee60fd8b19716f59acba25dbc0c0593a9136668fcd120e7' }
}
foreach ($sealSpec in @($qualification.protectedRuntimeSeals)) {
  $sealId = [string]$sealSpec.id
  if (-not $expectedSeal.ContainsKey($sealId)) { throw "C26G unexpected protected seal: $sealId" }
  $sealPath = Join-Path $root ([string]$sealSpec.path)
  if (-not (Test-Path -LiteralPath $sealPath -PathType Leaf)) { throw "C26G protected seal is missing: $sealId" }
  $seal = Get-Content -Raw -LiteralPath $sealPath | ConvertFrom-Json
  $expected = $expectedSeal[$sealId]
  if ([int]$seal.protectedRuntime.fileCount -ne [int]$expected.files -or
      [string]$seal.protectedRuntime.portableTreeSha256 -cne [string]$expected.sha -or
      [int]$sealSpec.expectedFiles -ne [int]$expected.files -or
      [string]$sealSpec.portableTreeSha256 -cne [string]$expected.sha) {
    throw "C26G protected $sealId seal drifted."
  }
}

$expectedApk = $qualification.expectedInstalledPredecessor
if ([string]$apk.machineState -cne [string]$expectedApk.machineState -or
    [string]$apk.buildAuthorization -cne [string]$expectedApk.buildAuthorization -or
    [string]$apk.installResult.installedVersionName -cne [string]$expectedApk.versionName -or
    [string]$apk.installResult.installedVersionCode -cne [string]$expectedApk.versionCode -or
    [string]$apk.installResult.installedBaseSha256 -cne [string]$expectedApk.apkSha256 -or
    [bool]$apk.founderDeviceReview.successorBuildAuthorized -or
    [bool]$apk.founderDeviceReview.successorInstallAuthorized) {
  throw 'C26G refuses changed r60.24 identity or open successor build/install authority.'
}

Write-Output 'C26G aggregate gate passed: approvedReference=sealed; families=Social,Shop,Food,Travel,Care,Work; tests=48; gates=18; cycles=2; SocialSeal=178; BuySeal=43; r60.24Preserved=true; runtimeBuildInstall=closed.'
