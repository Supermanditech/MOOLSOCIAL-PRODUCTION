[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C33JFix2 {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) {
    throw "C33J FIX2 same-device email-link gate rejected: $Message"
  }
}

function Resolve-C33JFix2File {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label
  )
  Assert-C33JFix2 -Condition (-not [IO.Path]::IsPathRooted($Path)) `
    -Message "$Label must be repository-relative."
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $Path))
  Assert-C33JFix2 -Condition (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $resolved -PathType Leaf)
  ) -Message "$Label is missing or escaped the repository."
  return $resolved
}

function Read-C33JFix2File {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label
  )
  return Get-Content -Raw -LiteralPath (
    Resolve-C33JFix2File -Path $Path -Label $Label
  )
}

function Get-C33JFix2GenericSuccessorMode {
  param(
    [Parameter(Mandatory)][object]$Scope,
    [Parameter(Mandatory)][string]$SelectedTicketSha256,
    [Parameter(Mandatory)][bool]$ParentEvidenceExists,
    [Parameter(Mandatory)][bool]$Fix1EvidenceExists,
    [Parameter(Mandatory)][bool]$Fix2EvidenceExists
  )
  $parentId = 'UAW-C33J-SCREEN03-PASSWORDLESS-EMAIL-LINK-NATIVE-PARITY'
  $fix1Id = 'UAW-C33J-FIX1-FOREGROUND-EMAIL-LINK-RETURN-HANDOFF'
  $fix2Id = 'UAW-C33J-FIX2-ANDROID-EMAIL-LINK-SAME-DEVICE-EXACT-RETURN'
  $checkpoint = $Scope.preTicketSelectionCheckpoint
  $currentId = [string]$checkpoint.currentTicketId
  if ($currentId -cne [string]$Scope.ticket.id) {
    throw 'C33J FIX2 current and top-level ticket identities differ.'
  }
  if (
    $currentId -ceq $fix2Id -and
    [string]$checkpoint.selectedTicketAssessment.manifestSha256 -ceq
      $SelectedTicketSha256 -and
    [string]$checkpoint.priorC33JFix1SelectedTicketAssessment.manifestSha256 -ceq
      '8C2B5075F2CFD4E711EA24A2064D789A8ACF2DB974C8B5211B3A4FE065EC261D' -and
    [string]$checkpoint.priorC33JSelectedTicketAssessment.manifestSha256 -ceq
      'C0181F1B56DCC1D070FD9F8E8048800F694C41007FBAEAE26219C7B2E764A00B'
  ) {
    return 'FIX2_active'
  }

  $selected = $checkpoint.selectedTicketAssessment
  $parent = $checkpoint.priorC33JSelectedTicketAssessment
  $fix1 = $checkpoint.priorC33JFix1SelectedTicketAssessment
  $fix2 = $checkpoint.priorC33JFix2SelectedTicketAssessment
  if (
    $currentId -cne [string]$selected.ticketId -or
    [string]$selected.manifestSha256 -cne $SelectedTicketSha256 -or
    [string]$parent.ticketId -cne $parentId -or
    [string]$parent.manifestSha256 -cne
      'C0181F1B56DCC1D070FD9F8E8048800F694C41007FBAEAE26219C7B2E764A00B' -or
    [string]$parent.implementationState -cne
      'native_v5_cold_and_foreground_email_link_source_qualified_10_parent_3_FIX1_68_affected_whole_mobile_analyzer_clean_dual_host_gates_passed_live_external_release_and_device_acceptance_held' -or
    [string]$parent.evidencePath -cne
      'docs/quality/UAW-C33J-SCREEN03-PASSWORDLESS-EMAIL-LINK-NATIVE-PARITY-QUALIFICATION-20260815.md' -or
    [string]$fix1.ticketId -cne $fix1Id -or
    [string]$fix1.manifestSha256 -cne
      '8C2B5075F2CFD4E711EA24A2064D789A8ACF2DB974C8B5211B3A4FE065EC261D' -or
    [string]$fix1.implementationState -cne
      'source_qualified_3_focused_68_affected_whole_mobile_analyzer_clean_dual_host_gates_passed_live_external_release_and_device_acceptance_held' -or
    [string]$fix1.evidencePath -cne
      'docs/quality/UAW-C33J-FIX1-FOREGROUND-EMAIL-LINK-RETURN-HANDOFF-QUALIFICATION-20260815.md' -or
    [string]$fix2.ticketId -cne $fix2Id -or
    [string]$fix2.manifestSha256 -cne
      '0DEF2CC05C15B8B6BD3113F4078B1EC2BEC2276010804A274C79050D88ECCA31' -or
    [string]$fix2.implementationState -cne
      'fix10_current_Firebase_Hosting_email_action_flow_local_source_qualified_default_linkDomain_omitted_latest_115_combined_focused_auth_and_analyzer_clean_live_email_external_release_and_device_acceptance_held' -or
    [string]$fix2.evidencePath -cne
      'docs/quality/UAW-C33J-FIX2-ANDROID-EMAIL-LINK-SAME-DEVICE-EXACT-RETURN-QUALIFICATION-20260815.md' -or
    -not $ParentEvidenceExists -or
    -not $Fix1EvidenceExists -or
    -not $Fix2EvidenceExists
  ) {
    throw 'C33J FIX2 generic successor qualification binding changed.'
  }
  return 'qualified_generic_successor_replay'
}

function Test-C33JFix2AppLinkFilter {
  param(
    [Parameter(Mandatory)][string]$Manifest,
    [Parameter(Mandatory)][string]$DomainHost,
    [Parameter(Mandatory)][string]$PathPrefix
  )
  $filters = [regex]::Matches(
    $Manifest,
    '<intent-filter android:autoVerify="true">[\s\S]*?</intent-filter>'
  )
  foreach ($filterMatch in $filters) {
    $filter = $filterMatch.Value
    if (
      $filter.IndexOf('android:scheme="https"', [StringComparison]::Ordinal) -ge 0 -and
      $filter.IndexOf(('android:host="{0}"' -f $DomainHost), [StringComparison]::Ordinal) -ge 0 -and
      $filter.IndexOf(('android:pathPrefix="{0}"' -f $PathPrefix), [StringComparison]::Ordinal) -ge 0
    ) {
      return $true
    }
  }
  return $false
}

$ticketPath = Resolve-C33JFix2File `
  -Path 'config/uaw-c33j-fix2-android-email-link-same-device-exact-return-ticket.json' `
  -Label 'FIX2 ticket'
$ticket = (Get-Content -Raw -LiteralPath $ticketPath) | ConvertFrom-Json
$ticketHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash
$scope = (Read-C33JFix2File `
  -Path 'config/mvp-scope-gate-state.json' `
  -Label 'MVP scope state') | ConvertFrom-Json
$manifest = Read-C33JFix2File `
  -Path 'apps/mobile/android/app/src/main/AndroidManifest.xml' `
  -Label 'Android manifest'
$runtime = Read-C33JFix2File `
  -Path 'apps/mobile/lib/core/config/email_link_runtime_configuration.dart' `
  -Label 'email-link runtime policy'
$main = Read-C33JFix2File -Path 'apps/mobile/lib/main.dart' -Label 'runtime wiring'
$test = Read-C33JFix2File `
  -Path 'apps/mobile/test/uaw_c33j_fix2_android_email_link_same_device_exact_return_test.dart' `
  -Label 'FIX2 focused matrix'
$assetLinks = (Read-C33JFix2File `
  -Path 'apps/web/public/.well-known/assetlinks.json' `
  -Label 'versioned assetlinks source') | ConvertFrom-Json

Assert-C33JFix2 -Condition (
  [string]$ticket.ticketId -ceq
    'UAW-C33J-FIX2-ANDROID-EMAIL-LINK-SAME-DEVICE-EXACT-RETURN' -and
  [string]$ticket.parentTicket -ceq
    'UAW-C33J-SCREEN03-PASSWORDLESS-EMAIL-LINK-NATIVE-PARITY' -and
  [string]$ticket.classification -ceq 'mvp_required' -and
  [string]$ticket.state -ceq
    'fix10_android_email_link_exact_return_and_default_firebase_hosting_flow_locally_qualified_live_email_and_oppo_reproof_pending_no_build' -and
  $ticketHash -ceq
    '0DEF2CC05C15B8B6BD3113F4078B1EC2BEC2276010804A274C79050D88ECCA31' -and
  [string]$ticket.sourceQualification.state -ceq
    'qualified_locally_not_live_email_or_device_success' -and
  [bool]$ticket.sourceQualification.officialFlutterFirebaseEmailLinkDocumentationApplied -and
  [bool]$ticket.sourceQualification.legacyFirebaseDynamicLinksFlowExcluded -and
  [bool]$ticket.sourceQualification.defaultFirebaseHostingLinkDomainOmitted -and
  [bool]$ticket.sourceQualification.exactAndroidEmailActionIntentFiltersRetained -and
  [int]$ticket.sourceQualification.latestCombinedFocusedAuthTerminalSuitePassed -eq 115 -and
  [int]$ticket.sourceQualification.flutterAnalyzerIssues -eq 0 -and
  -not [bool]$ticket.sourceQualification.functionalDeviceSuccessClaimed -and
  [bool]$ticket.sourceQualification.freshSourceSealRequiredBeforeAnyFutureArtifact -and
  [bool]$ticket.authority.androidManifestAndRuntimeSourceWriteAuthorized -and
  [bool]$ticket.authority.testAndGateWriteAuthorized -and
  -not [bool]$ticket.authority.backendWriteAuthorized -and
  -not [bool]$ticket.authority.firebaseHostingOrProviderWriteAuthorized -and
  -not [bool]$ticket.authority.liveEmailSendAuthorized -and
  -not [bool]$ticket.authority.buildPlayOrDeviceMutationAuthorized -and
  -not [bool]$ticket.authority.secretValueAccessAuthorized
) -Message 'ticket identity, seal, classification or closed authority changed.'

$selectedAssessment = $scope.preTicketSelectionCheckpoint.selectedTicketAssessment
$selectedManifestPath = [string]$selectedAssessment.manifestPath
$selectedManifestFullPath = Resolve-C33JFix2File `
  -Path $selectedManifestPath `
  -Label 'selected ticket manifest'
foreach ($assessment in @(
  $scope.preTicketSelectionCheckpoint.priorC33JSelectedTicketAssessment,
  $scope.preTicketSelectionCheckpoint.priorC33JFix1SelectedTicketAssessment,
  $scope.preTicketSelectionCheckpoint.priorC33JFix2SelectedTicketAssessment
)) {
  [void](Read-C33JFix2File `
    -Path ([string]$assessment.evidencePath) `
    -Label 'qualified C33J evidence')
}
$selectionMode = Get-C33JFix2GenericSuccessorMode `
  -Scope $scope `
  -SelectedTicketSha256 (
    Get-FileHash -Algorithm SHA256 -LiteralPath $selectedManifestFullPath
  ).Hash `
  -ParentEvidenceExists $true `
  -Fix1EvidenceExists $true `
  -Fix2EvidenceExists $true
Assert-C33JFix2 -Condition (
  [bool]$scope.execution.testOrGateWriteAuthorized -and
  (
    ($selectionMode -ceq 'FIX2_active' -and
      -not [bool]$scope.execution.backendWriteAuthorized) -or
    ($selectionMode -ceq 'qualified_generic_successor_replay' -and
      [string]$scope.ticket.id -ceq
        'UAW-C34P-FIX8-GLOBAL-SOCIAL-LOGIN-OPPO-SUCCESSOR-AUDIT-REPAIR' -and
      [bool]$scope.execution.runtimeWriteAuthorized -and
      [bool]$scope.execution.backendWriteAuthorized)
  ) -and
  -not [bool]$scope.execution.externalServiceWriteAuthorized -and
  -not [bool]$scope.execution.firebaseEmailPasswordAndEmailLinkEnablementAuthorizedOnce -and
  -not [bool]$scope.execution.firebaseMoolSocialAuthorizedDomainAdditionAuthorizedOnce -and
  -not [bool]$scope.execution.hostingDeploymentAuthorized -and
  -not [bool]$scope.execution.liveEmailSendAuthorized -and
  -not [bool]$scope.execution.buildAuthorized -and
  -not [bool]$scope.execution.deviceInstallAuthorized
) -Message 'active or generic successor selection and closed execution boundary changed.'

foreach ($expectedFilter in @(
  @{ Host = 'moolsocial-dev-503018.firebaseapp.com'; Path = '/__/auth/links' },
  @{ Host = 'moolsocial.com'; Path = '/__/auth/links' },
  @{ Host = 'moolsocial.com'; Path = '/app' }
)) {
  Assert-C33JFix2 -Condition (Test-C33JFix2AppLinkFilter `
    -Manifest $manifest `
    -DomainHost $expectedFilter.Host `
    -PathPrefix $expectedFilter.Path) `
    -Message "exact App Link filter is missing: $($expectedFilter.Host)$($expectedFilter.Path)"
}
Assert-C33JFix2 -Condition (
  $manifest.IndexOf(
    'android:launchMode="singleTop"',
    [StringComparison]::Ordinal
  ) -ge 0
) -Message 'MainActivity no longer preserves singleTop foreground delivery.'

foreach ($required in @(
  "'moolsocial-dev-503018.firebaseapp.com'",
  "'moolsocial.com'",
  "path == '/app' || path.startsWith('/app/')",
  'normalizedLinkDomain.isEmpty',
  'supportedEmailLinkDomains.contains(normalizedLinkDomain)'
)) {
  Assert-C33JFix2 -Condition (
    $runtime.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "runtime domain policy is missing: $required"
}
foreach ($required in @(
  "import 'core/config/email_link_runtime_configuration.dart';",
  'isQualifiedEmailLinkRuntimeConfiguration(',
  'continueUrl: _emailLinkContinueUrl',
  'linkDomain: _emailLinkDomain'
)) {
  Assert-C33JFix2 -Condition (
    $main.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "runtime wiring is missing: $required"
}
Assert-C33JFix2 -Condition (
  $main.IndexOf(
    'final emailLinkRuntimeAvailable = isQualifiedHttpsRuntimeEndpoint(',
    [StringComparison]::Ordinal
  ) -lt 0
) -Message 'continue URL alone still enables email-link runtime without manifest host parity.'

foreach ($required in @(
  'runtime email-link domain and continue URL fail closed',
  'Android manifest catches exact Firebase email action links',
  'existing Social App Link and singleTop activity stay preserved',
  "ValueKey('social-v2-create-workbench')"
)) {
  $testOwner = if ($required.StartsWith('ValueKey')) {
    Read-C33JFix2File `
      -Path 'apps/mobile/test/uaw_c33j_fix1_foreground_email_link_return_handoff_test.dart' `
      -Label 'FIX1 exact-return matrix'
  } else {
    $test
  }
  Assert-C33JFix2 -Condition (
    $testOwner.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "focused composition is missing: $required"
}
Assert-C33JFix2 -Condition (
  ([regex]::Matches($test, '\btest\(')).Count -eq 3
) -Message 'FIX2 focused matrix count changed from three.'
Assert-C33JFix2 -Condition (
  [string]$assetLinks[0].target.package_name -ceq 'com.moolsocial.app' -and
  @($assetLinks[0].relation) -contains 'delegate_permission/common.handle_all_urls'
) -Message 'versioned web association no longer owns the Android package relation.'

Write-Output (
  'C33J FIX2 same-device email-link gate passed: manifestFilters=3; ' +
  "selectionMode=$selectionMode; " +
  'defaultHosting=true; customHosting=true; exactReturn=true; ' +
  'unknownDomainFailClosed=true; liveFirebaseHostingEmail=false; ' +
  'buildPlayDevice=false; secretValuesObserved=false.'
)
