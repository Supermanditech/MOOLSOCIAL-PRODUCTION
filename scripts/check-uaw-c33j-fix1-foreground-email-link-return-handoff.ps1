[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C33JFix1 {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) {
    throw "C33J FIX1 foreground email-link return gate rejected: $Message"
  }
}

function Read-C33JFix1File {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label
  )
  Assert-C33JFix1 -Condition (-not [IO.Path]::IsPathRooted($Path)) `
    -Message "$Label must be repository-relative."
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $Path))
  Assert-C33JFix1 -Condition (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $resolved -PathType Leaf)
  ) -Message "$Label is missing or escaped the repository."
  return Get-Content -Raw -LiteralPath $resolved
}

function Get-C33JFix1GenericSuccessorMode {
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
    throw 'C33J FIX1 current and top-level ticket identities differ.'
  }
  if (
    $currentId -ceq $fix1Id -and
    [string]$checkpoint.priorC33JSelectedTicketAssessment.manifestSha256 -ceq
      'C0181F1B56DCC1D070FD9F8E8048800F694C41007FBAEAE26219C7B2E764A00B'
  ) {
    return 'FIX1_active'
  }
  if (
    $currentId -ceq $fix2Id -and
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
    throw 'C33J FIX1 generic successor qualification binding changed.'
  }
  return 'qualified_generic_successor_replay'
}

$ticket = (Read-C33JFix1File `
  -Path 'config/uaw-c33j-fix1-foreground-email-link-return-handoff-ticket.json' `
  -Label 'FIX1 ticket') | ConvertFrom-Json
$scope = (Read-C33JFix1File `
  -Path 'config/mvp-scope-gate-state.json' `
  -Label 'MVP scope state') | ConvertFrom-Json
$app = Read-C33JFix1File `
  -Path 'apps/mobile/lib/app/moolsocial_app.dart' `
  -Label 'MoolSocial app lifecycle owner'
$test = Read-C33JFix1File `
  -Path 'apps/mobile/test/uaw_c33j_fix1_foreground_email_link_return_handoff_test.dart' `
  -Label 'FIX1 focused matrix'
[void](Read-C33JFix1File `
  -Path 'scripts/check-uaw-c33j-screen03-passwordless-email-link-native-parity.ps1' `
  -Label 'parent C33J gate')

Assert-C33JFix1 -Condition (
  [string]$ticket.ticketId -ceq
    'UAW-C33J-FIX1-FOREGROUND-EMAIL-LINK-RETURN-HANDOFF' -and
  [string]$ticket.parentTicket -ceq
    'UAW-C33J-SCREEN03-PASSWORDLESS-EMAIL-LINK-NATIVE-PARITY' -and
  [string]$ticket.classification -ceq 'mvp_required' -and
  [bool]$ticket.authority.nativeRuntimeSourceWriteAuthorized -and
  [bool]$ticket.authority.testAndGateWriteAuthorized -and
  -not [bool]$ticket.authority.backendWriteAuthorized -and
  -not [bool]$ticket.authority.hostingProviderOrAppLinkWriteAuthorized -and
  -not [bool]$ticket.authority.liveEmailSendAuthorized -and
  -not [bool]$ticket.authority.buildPlayOrDeviceMutationAuthorized -and
  -not [bool]$ticket.authority.secretValueAccessAuthorized
) -Message 'ticket identity, classification or authority boundary changed.'
$selectedAssessment = $scope.preTicketSelectionCheckpoint.selectedTicketAssessment
$selectedManifestPath = [string]$selectedAssessment.manifestPath
[void](Read-C33JFix1File `
  -Path $selectedManifestPath `
  -Label 'selected ticket manifest')
$selectedManifestFullPath = [IO.Path]::GetFullPath((Join-Path $root $selectedManifestPath))
foreach ($assessment in @(
  $scope.preTicketSelectionCheckpoint.priorC33JSelectedTicketAssessment,
  $scope.preTicketSelectionCheckpoint.priorC33JFix1SelectedTicketAssessment,
  $scope.preTicketSelectionCheckpoint.priorC33JFix2SelectedTicketAssessment
)) {
  [void](Read-C33JFix1File `
    -Path ([string]$assessment.evidencePath) `
    -Label 'qualified C33J evidence')
}
$selectionMode = Get-C33JFix1GenericSuccessorMode `
  -Scope $scope `
  -SelectedTicketSha256 (
    Get-FileHash -Algorithm SHA256 -LiteralPath $selectedManifestFullPath
  ).Hash `
  -ParentEvidenceExists $true `
  -Fix1EvidenceExists $true `
  -Fix2EvidenceExists $true
Assert-C33JFix1 -Condition (
  [bool]$scope.execution.testOrGateWriteAuthorized -and
  (
    ($selectionMode -cin @('FIX1_active', 'FIX2_active') -and
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
) -Message 'active FIX1/FIX2 succession, parent seal or closed external boundary changed.'

$callback = [regex]::Match(
  $app,
  '(?s)Future<bool> didPushRouteInformation\((?<body>.*?)\n  }\n\n  @override\n  void dispose'
)
Assert-C33JFix1 -Condition $callback.Success `
  -Message 'foreground route-information callback is missing.'
$callbackBody = $callback.Groups['body'].Value
foreach ($required in @(
  'routeInformation.uri.toString()',
  'await _session.prepareEmailLinkReturn(',
  'if (!handled) return false;',
  'final completedRoute = _session.takeCompletedEmailLinkReturnRoute();',
  'if (!mounted) return true;',
  'completedRoute ?? _session.readyRoute()',
  'return true;'
)) {
  Assert-C33JFix1 -Condition (
    $callbackBody.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "foreground handoff is missing: $required"
}
foreach ($prohibited in @(
  'debugPrint',
  'print(',
  'SharedPreferences',
  'write(',
  'setString(',
  'queryParameters'
)) {
  Assert-C33JFix1 -Condition (
    $callbackBody.IndexOf($prohibited, [StringComparison]::Ordinal) -lt 0
  ) -Message "foreground callback exposes or persists private link data: $prohibited"
}

foreach ($required in @(
  'foreground link completes once and opens exact destination',
  'foreground process return asks for the same email',
  'unrecognized route never reaches email-link completion',
  'binding.handlePushRoute(',
  "ValueKey('social-v2-create-workbench')",
  'router.routeInformationProvider.value.uri.toString()',
  'router.routerDelegate.currentConfiguration.uri.toString()',
  "expect(session.readyRoute(), '/app/social');",
  'expect(gateway.completionCount, 1)',
  'expect(bootstrap.prepareCount, 1)',
  'expect(gateway.completionCount, 0)'
)) {
  Assert-C33JFix1 -Condition (
    $test.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "FIX1 focused matrix is missing: $required"
}
Assert-C33JFix1 -Condition (
  ([regex]::Matches($test, '\btestWidgets\(')).Count -eq 3
) -Message 'FIX1 focused matrix count changed from three.'

Write-Output (
  'C33J FIX1 foreground email-link return gate passed: focusedMatrix=3; ' +
  "selectionMode=$selectionMode; " +
  'coldAndForegroundOwners=true; unrelatedRouteRejected=true; oneShot=true; ' +
  'opaqueLinkLoggedOrPersisted=false; externalWrites=false; liveEmail=false; ' +
  'buildPlayDevice=false.'
)
