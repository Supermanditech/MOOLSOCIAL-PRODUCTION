[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)
$qualificationPath = Join-Path $root 'config\mvp-personal-service-home-host-qualification-c24h.json'
$serviceContractPath = Join-Path $root 'config\mvp-reference-service-home-contract-c24.json'
$ticketPath = Join-Path $root 'config\uaw-personal-mvp-service-home-host-qualification-fix7-c24h-ticket.json'
$parentPath = Join-Path $root 'config\uaw-personal-mvp-reference-service-home-recovery-fix7-c24-ticket.json'
$scopePath = Join-Path $root 'config\mvp-scope-gate-state.json'
$apkPath = Join-Path $root 'config\apk-regression-gate-state.json'
$homePath = Join-Path $root 'apps\mobile\lib\ui_v2\universal\personal_mool_root_v2.dart'
$navigationPath = Join-Path $root 'apps\mobile\lib\ui_v2\universal\mool_global_navigation_v2.dart'
$serviceDesignPath = Join-Path $root 'apps\mobile\lib\core\design\mool_service_home.dart'
$routerPath = Join-Path $root 'apps\mobile\lib\features\journey01\journey_router.dart'
$requiredOwners = @(
  $qualificationPath, $serviceContractPath, $ticketPath, $parentPath, $scopePath,
  $apkPath, $homePath, $navigationPath, $serviceDesignPath, $routerPath
)
foreach ($path in $requiredOwners) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "C24H required owner is missing: $path"
  }
}

$qualification = Get-Content -Raw -LiteralPath $qualificationPath | ConvertFrom-Json
$service = Get-Content -Raw -LiteralPath $serviceContractPath | ConvertFrom-Json
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$parent = Get-Content -Raw -LiteralPath $parentPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$apk = Get-Content -Raw -LiteralPath $apkPath | ConvertFrom-Json
$expectedTicket = 'UAW-PERSONAL-MVP-SERVICE-HOME-HOST-QUALIFICATION-FIX7-C24H'
$actualTicketSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash
if ([string]$qualification.contractId -cne 'UAW-PERSONAL-MVP-SERVICE-HOME-HOST-QUALIFICATION-C24H-20260809' -or
    [string]$qualification.ticketId -cne $expectedTicket -or
    [string]$ticket.ticketId -cne $expectedTicket -or
    [string]$ticket.state -cne 'selected_host_qualification_execution_open' -or
    [string]$scope.ticket.id -cne $expectedTicket -or
    [string]$scope.preTicketSelectionCheckpoint.currentTicketId -cne $expectedTicket -or
    [string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -cne $actualTicketSha -or
    [string]$qualification.ticketManifestSha256 -cne $actualTicketSha -or
    [string]$parent.execution.currentChild -cne $expectedTicket -or
    [bool]$scope.execution.runtimeWriteAuthorized -or
    [bool]$scope.execution.buildAuthorized -or
    [bool]$scope.execution.deviceInstallAuthorized -or
    [bool]$qualification.authority.runtimeMutationAuthorized -or
    [bool]$qualification.authority.buildAuthorized -or
    [bool]$qualification.authority.installAuthorized -or
    [bool]$qualification.authority.externalWriteAuthorized) {
  throw 'C24H ticket identity, manifest hash or closed runtime/build/install authority is invalid.'
}

$children = @($parent.children)
foreach ($childId in @(
  'UAW-PERSONAL-MVP-FOUNDER-REFERENCE-AND-PLACEMENT-CONTRACT-FIX7-C24A',
  'UAW-PERSONAL-MVP-SHARED-SERVICE-HOME-AND-ACCESSIBILITY-PRIMITIVES-FIX7-C24B',
  'UAW-PERSONAL-MVP-FOUNDER-OPPO-HOME-NAVIGATION-CONTRACT-FIX7-C24B1',
  'UAW-PERSONAL-MVP-FIXED-VIEWPORT-HOME-HUB-FIX7-C24B2',
  'UAW-PERSONAL-MVP-CONNECTED-ACTION-NAVIGATOR-BRAND-FOCAL-POINT-FIX7-C24B3',
  'UAW-PERSONAL-MVP-EAT-DISCOVERY-HOME-FIX7-C24C',
  'UAW-PERSONAL-MVP-RIDE-DESTINATION-HOME-FIX7-C24D',
  'UAW-PERSONAL-MVP-BOOK-DOCTOR-SALON-HOME-FIX7-C24E',
  'UAW-PERSONAL-MVP-BOOK-BUS-BOOKING-FIX7-C24F',
  'UAW-PERSONAL-MVP-WORK-OPPORTUNITY-HOME-FIX7-C24G'
)) {
  $child = @($children | Where-Object { [string]$_.ticketId -ceq $childId })
  if ($child.Count -ne 1 -or -not ([string]$child[0].state).StartsWith('complete', [StringComparison]::Ordinal)) {
    throw "C24H refuses incomplete predecessor child: $childId"
  }
}

if ([string]$service.contractId -cne 'MOOLSOCIAL-MVP-REFERENCE-SERVICE-HOME-CONTRACT-C24-20260809' -or
    (@($service.placement.Social.actions) -join ',') -cne 'Shorts,Videos,Feed,Create' -or
    (@($service.placement.Buy.actions) -join ',') -cne 'Shop,Wholesale,Medicine,Orders' -or
    [string]$service.placement.Buy.medicineDecision -cne 'retain_as_regulated_pharmacy_commerce' -or
    (@($service.placement.Eat.actions) -join ',') -cne 'Order Food,Book Table' -or
    (@($service.placement.Ride.actions) -join ',') -cne 'Bike,Auto,Cab' -or
    (@($service.placement.Book.actions) -join ',') -cne 'Doctor,Salon,Bus' -or
    [string]$service.placement.Book.doctorDecision -cne 'retain_as_appointment_service' -or
    (@($service.placement.Work.actions) -join ',') -cne 'Earn Today,Workspace' -or
    [string]$service.routeOwners.'Book/Bus' -cne '/app/book/bus') {
  throw 'C24H service placement, Doctor/Medicine decision or Bus route contract has drifted.'
}
$homeContract = $service.founderOppoHomeAmendment.homeViewport
$navigatorContract = $service.founderOppoHomeAmendment.destinationNavigator
if (@($homeContract.scrollOwnersAllowed).Count -ne 0 -or
    [string]$homeContract.mainFamilyLayout -cne 'six_equal_choices_in_fixed_three_by_two_grid' -or
    [string]$homeContract.detailLayout -cne 'only_selected_family_two_to_four_direct_actions_in_fixed_two_column_grid' -or
    [int]$homeContract.maximumTapCountFromHome -ne 2 -or
    [string]$navigatorContract.launcherLabel -cne 'MoolSocial' -or
    -not [bool]$navigatorContract.preserveDestinationUnderlay -or
    -not [bool]$navigatorContract.intermediateHomeRouteForbidden) {
  throw 'C24H fixed Home, connected navigator or tap-budget contract has drifted.'
}
$adaptation = $service.founderOppoHomeAmendment.adaptation
if ([int]$adaptation.minimumTapTarget -ne 44) {
  throw "C24H minimum tap target drifted: $($adaptation.minimumTapTarget)"
}
if ([double]$adaptation.maximumTextScale -ne [double]1.4) {
  throw "C24H maximum text scale drifted: $($adaptation.maximumTextScale)"
}

if (@($qualification.requiredTests).Count -ne 38 -or
    @($qualification.requiredGates).Count -ne 12 -or
    @($qualification.protectedTestManifests).Count -ne 2 -or
    [int]$qualification.hostQualification.requiredConsecutiveCycles -ne 2 -or
    -not [bool]$qualification.hostQualification.unchangedSourceFingerprintRequired -or
    -not [bool]$qualification.hostQualification.completeAnalysisRequired -or
    -not [bool]$qualification.hostQualification.completeRequiredSuiteRequired) {
  throw 'C24H required suite, gate or two-cycle inventory has drifted.'
}
foreach ($relative in @($qualification.requiredTests) + @($qualification.requiredGates) + @($qualification.formatOwners)) {
  if (-not (Test-Path -LiteralPath (Join-Path $root ([string]$relative)))) {
    throw "C24H required test, gate or format owner is missing: $relative"
  }
}
foreach ($manifest in @($qualification.protectedTestManifests)) {
  $manifestPath = Join-Path $root ([string]$manifest.path)
  if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "C24H protected test manifest is missing: $($manifest.path)"
  }
  $manifestFiles = @(Get-Content -LiteralPath $manifestPath | Where-Object { $_.Trim() })
  if ($manifestFiles.Count -ne [int]$manifest.expectedFiles) {
    throw "C24H protected $($manifest.id) test manifest count drifted."
  }
}

$homeSource = Get-Content -Raw -LiteralPath $homePath
$navigation = Get-Content -Raw -LiteralPath $navigationPath
$serviceDesign = Get-Content -Raw -LiteralPath $serviceDesignPath
$router = Get-Content -Raw -LiteralPath $routerPath
foreach ($forbidden in @('ListView(', 'SingleChildScrollView(', 'CustomScrollView(', 'GridView(', 'PageView(')) {
  if ($homeSource.Contains($forbidden)) { throw "C24H fixed Home contains a forbidden scroll owner: $forbidden" }
}
foreach ($required in @(
  "key: const Key('mool-home-dashboard')",
  "keyPrefix: 'mool-home'",
  "key: const Key('mool-home-chat')",
  "class MoolConnectedActionNavigator extends StatelessWidget",
  "key: const Key('mool-connected-action-navigator')",
  "key: const Key('mool-connected-navigator-chat')",
  "key: const Key('mool-home-launcher')",
  "'MoolSocial'",
  "if (activeId == 'mool')",
  "class MoolServiceSearchField extends StatelessWidget",
  "class MoolServiceCard extends StatefulWidget",
  "class MoolServicePrimaryButton extends StatelessWidget",
  "path: '/app/book/bus'"
)) {
  if (-not ($homeSource.Contains($required) -or $navigation.Contains($required) -or
      $serviceDesign.Contains($required) -or $router.Contains($required))) {
    throw "C24H required production owner is missing: $required"
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
  throw 'C24H refuses changed r60.22 identity or open successor build/install authority.'
}

Write-Output 'C24H aggregate gate passed: Home=fixed_no_scroll; connectedNavigator=one_MoolSocial_launcher; services=Eat,Ride,BookDoctorSalonBus,Work; decisions=DoctorBook_MedicineBuy; focusedAffectedTests=38; protectedManifests=53+34; requiredGates=12; cycles=2; r60.22Preserved=true; runtimeBuildInstall=closed.'
