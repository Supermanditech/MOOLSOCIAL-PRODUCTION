[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

$expectedTicket = 'UAW-PERSONAL-MVP-DOMAIN-NAVIGATION-HOST-QUALIFICATION-FIX8-C25G'
$qualificationPath = Join-Path $root 'config\mvp-personal-domain-navigation-host-qualification-c25g.json'
$contractPath = Join-Path $root 'config\mvp-personal-domain-navigation-projection-c25.json'
$ticketPath = Join-Path $root 'config\uaw-personal-mvp-domain-navigation-host-qualification-fix8-c25g-ticket.json'
$parentPath = Join-Path $root 'config\uaw-personal-mvp-domain-navigation-and-destination-rail-recovery-fix8-c25-ticket.json'
$scopePath = Join-Path $root 'config\mvp-scope-gate-state.json'
$apkPath = Join-Path $root 'config\apk-regression-gate-state.json'

foreach ($path in @($qualificationPath, $contractPath, $ticketPath, $parentPath, $scopePath, $apkPath)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "C25G required owner is missing: $path"
  }
}

$qualification = Get-Content -Raw -LiteralPath $qualificationPath | ConvertFrom-Json
$contract = Get-Content -Raw -LiteralPath $contractPath | ConvertFrom-Json
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$parent = Get-Content -Raw -LiteralPath $parentPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$apk = Get-Content -Raw -LiteralPath $apkPath | ConvertFrom-Json
$actualTicketSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash
$expectedSuccessor = 'UAW-PERSONAL-MVP-DOMAIN-NAVIGATION-OPPO-QUALIFICATION-FIX8-C25H'
$completedSelfChild = @($parent.children | Where-Object {
  [string]$_.ticketId -ceq $expectedTicket
})
$activeState = (
  [string]$ticket.state -ceq 'selected_host_qualification_gate_writes_authorized' -and
  [string]$scope.ticket.id -ceq $expectedTicket -and
  [string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq $expectedTicket -and
  [string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -ceq $actualTicketSha -and
  [string]$qualification.ticketManifestSha256 -ceq $actualTicketSha -and
  [string]$parent.execution.currentChild -ceq $expectedTicket
)
$completedState = (
  [string]$ticket.state -ceq 'complete' -and
  $completedSelfChild.Count -eq 1 -and
  [string]$completedSelfChild[0].state -ceq 'complete' -and
  [string]$scope.ticket.id -ceq $expectedSuccessor -and
  [string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq $expectedSuccessor -and
  [string]$parent.execution.currentChild -ceq $expectedSuccessor
)

if ([string]$qualification.contractId -cne 'UAW-PERSONAL-MVP-DOMAIN-NAVIGATION-HOST-QUALIFICATION-C25G-20260809' -or
    [string]$qualification.ticketId -cne $expectedTicket -or
    [string]$qualification.state -cne 'selected_host_qualification_execution_open' -or
    [string]$ticket.ticketId -cne $expectedTicket -or
    -not ($activeState -or $completedState) -or
    [bool]$scope.execution.runtimeWriteAuthorized -or
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
  throw 'C25G ticket identity, manifest seal or closed runtime/backend/build/install/external authority is invalid.'
}

$children = @($parent.children)
foreach ($childId in @(
  'UAW-PERSONAL-MVP-FOUNDER-DOMAIN-NAMING-AND-PLACEMENT-CONTRACT-FIX8-C25A',
  'UAW-PERSONAL-MVP-SHARED-DOMAIN-ACTION-CATALOGUE-FIX8-C25B',
  'UAW-PERSONAL-MVP-PROFESSIONAL-MAIN-ONLY-MOOLSOCIAL-MENU-FIX8-C25C',
  'UAW-PERSONAL-MVP-COMPACT-DESTINATION-LOCAL-SUBACTION-RAIL-FIX8-C25D',
  'UAW-PERSONAL-MVP-SIX-DOMAIN-ROUTE-PROJECTION-CONTINUITY-FIX8-C25E',
  'UAW-PERSONAL-MVP-ADAPTIVE-ACCESSIBILITY-REACHABILITY-GATES-FIX8-C25F'
)) {
  $child = @($children | Where-Object { [string]$_.ticketId -ceq $childId })
  if ($child.Count -ne 1 -or [string]$child[0].state -cne 'complete') {
    throw "C25G refuses incomplete predecessor child: $childId"
  }
}
$selfChild = @($children | Where-Object { [string]$_.ticketId -ceq $expectedTicket })
$expectedSelfState = if ($activeState) { 'selected' } else { 'complete' }
if ($selfChild.Count -ne 1 -or [string]$selfChild[0].state -cne $expectedSelfState) {
  throw 'C25G parent child selection is invalid.'
}

if ([string]$contract.contractId -cne 'UAW-PERSONAL-MVP-DOMAIN-NAVIGATION-PROJECTION-FIX8-C25' -or
    (@($contract.domains | ForEach-Object { [string]$_.label }) -join ',') -cne 'Social,Shop,Food,Travel,Care,Work' -or
    (@($contract.domains | Where-Object { $_.id -ceq 'ride' } | ForEach-Object { $_.actions.label }) -join ',') -cne 'Bike,Auto,Cab,Bus' -or
    (@($contract.domains | Where-Object { $_.id -ceq 'book' } | ForEach-Object { $_.actions.label }) -join ',') -cne 'Doctor,Medicine,Salon' -or
    -not [bool]$contract.presentation.mainMenuMainActionsOnly -or
    -not [bool]$contract.presentation.destinationLocalSubactionsRequired -or
    [bool]$contract.presentation.horizontalActionScrollAllowed -or
    [bool]$contract.presentation.fullWidthOpaqueBottomStripeAllowed -or
    [int]$contract.presentation.minimumTapTarget -ne 44 -or
    -not [bool]$contract.presentation.reducedMotionImmediate) {
  throw 'C25G domain, local-rail, adaptive or placement contract drifted.'
}

$requiredTests = @($qualification.requiredTests | ForEach-Object { ([string]$_).Replace('\', '/') })
$uniqueTests = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($relative in $requiredTests) { [void]$uniqueTests.Add($relative) }
$requiredGates = @($qualification.requiredGates | ForEach-Object { ([string]$_).Replace('\', '/') })
$uniqueGates = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($relative in $requiredGates) { [void]$uniqueGates.Add($relative) }
if ($requiredTests.Count -ne 43 -or $uniqueTests.Count -ne 43 -or
    $requiredGates.Count -ne 14 -or $uniqueGates.Count -ne 14 -or
    @($qualification.formatOwners).Count -ne 8 -or
    @($qualification.protectedRuntimeSeals).Count -ne 2 -or
    [int]$qualification.hostQualification.requiredConsecutiveCycles -ne 2 -or
    -not [bool]$qualification.hostQualification.unchangedSourceFingerprintRequired -or
    -not [bool]$qualification.hostQualification.completeAnalysisRequired -or
    -not [bool]$qualification.hostQualification.completeRequiredSuiteRequired -or
    [string]$qualification.hostQualification.sourceFingerprintAlgorithm -cne 'SHA256_OF_SORTED_PER_FILE_SHA256_AND_REPOSITORY_RELATIVE_PATH_USING_LF') {
  throw 'C25G 43-test, 14-gate, format, seal or two-cycle inventory drifted.'
}
foreach ($relative in @($requiredTests) + @($requiredGates) + @($qualification.formatOwners)) {
  if (-not (Test-Path -LiteralPath (Join-Path $root ([string]$relative)))) {
    throw "C25G required test, gate or format owner is missing: $relative"
  }
}

$expectedSeal = @{
  social = @{ files = 178; sha = '9d79db1aa83d52d26e5f4a494315a7c213a504da6cba231346772aadac9af4e5' }
  buy = @{ files = 43; sha = '37d946cd050d378a9ee60fd8b19716f59acba25dbc0c0593a9136668fcd120e7' }
}
foreach ($sealSpec in @($qualification.protectedRuntimeSeals)) {
  $sealId = [string]$sealSpec.id
  if (-not $expectedSeal.ContainsKey($sealId)) { throw "C25G unexpected protected seal: $sealId" }
  $sealPath = Join-Path $root ([string]$sealSpec.path)
  if (-not (Test-Path -LiteralPath $sealPath -PathType Leaf)) { throw "C25G protected seal is missing: $sealId" }
  $seal = Get-Content -Raw -LiteralPath $sealPath | ConvertFrom-Json
  $expected = $expectedSeal[$sealId]
  if ([string]$seal.state -cne 'FOUNDER_AUTHORIZED_SUCCESSOR_PENDING_OPPO_ACCEPTANCE' -or
      [int]$seal.protectedRuntime.fileCount -ne [int]$expected.files -or
      [string]$seal.protectedRuntime.portableTreeSha256 -cne [string]$expected.sha -or
      [int]$sealSpec.expectedFiles -ne [int]$expected.files -or
      [string]$sealSpec.portableTreeSha256 -cne [string]$expected.sha) {
    throw "C25G protected $sealId successor seal drifted."
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
  throw 'C25G refuses changed r60.23 identity or open successor build/install authority.'
}

Write-Output 'C25G aggregate gate passed: domains=Social,Shop,Food,Travel,Care,Work; menu=main-only; destinationRails=local; tests=43; gates=14; cycles=2; SocialSeal=178; BuySeal=43; r60.23Preserved=true; runtimeBuildInstall=closed.'
