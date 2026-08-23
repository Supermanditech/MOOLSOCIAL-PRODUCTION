[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C33J {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) {
    throw "C33J Screen03 email-link native parity gate rejected: $Message"
  }
}

function Read-C33JFile {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label
  )
  Assert-C33J -Condition (-not [IO.Path]::IsPathRooted($Path)) `
    -Message "$Label must be repository-relative."
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $Path))
  Assert-C33J -Condition (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $resolved -PathType Leaf)
  ) -Message "$Label is missing or escaped the repository."
  return Get-Content -Raw -LiteralPath $resolved
}

function Get-C33JGenericSuccessorMode {
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
  $topId = [string]$Scope.ticket.id
  if ($currentId -cne $topId) {
    throw 'C33J current and top-level ticket identities differ.'
  }
  if ($currentId -ceq $parentId) { return 'parent_active' }
  if (
    $currentId -ceq $fix1Id -and
    [string]$checkpoint.priorC33JSelectedTicketAssessment.ticketId -ceq
      $parentId -and
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
    [string]$parent.manifestPath -cne
      'config/uaw-c33j-screen03-passwordless-email-link-native-parity-ticket.json' -or
    [string]$parent.manifestSha256 -cne
      'C0181F1B56DCC1D070FD9F8E8048800F694C41007FBAEAE26219C7B2E764A00B' -or
    [string]$parent.implementationState -cne
      'native_v5_cold_and_foreground_email_link_source_qualified_10_parent_3_FIX1_68_affected_whole_mobile_analyzer_clean_dual_host_gates_passed_live_external_release_and_device_acceptance_held' -or
    [string]$parent.evidencePath -cne
      'docs/quality/UAW-C33J-SCREEN03-PASSWORDLESS-EMAIL-LINK-NATIVE-PARITY-QUALIFICATION-20260815.md' -or
    [string]$fix1.ticketId -cne $fix1Id -or
    [string]$fix1.manifestPath -cne
      'config/uaw-c33j-fix1-foreground-email-link-return-handoff-ticket.json' -or
    [string]$fix1.manifestSha256 -cne
      '8C2B5075F2CFD4E711EA24A2064D789A8ACF2DB974C8B5211B3A4FE065EC261D' -or
    [string]$fix1.implementationState -cne
      'source_qualified_3_focused_68_affected_whole_mobile_analyzer_clean_dual_host_gates_passed_live_external_release_and_device_acceptance_held' -or
    [string]$fix1.evidencePath -cne
      'docs/quality/UAW-C33J-FIX1-FOREGROUND-EMAIL-LINK-RETURN-HANDOFF-QUALIFICATION-20260815.md' -or
    [string]$fix2.ticketId -cne $fix2Id -or
    [string]$fix2.manifestPath -cne
      'config/uaw-c33j-fix2-android-email-link-same-device-exact-return-ticket.json' -or
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
    throw 'C33J generic successor qualification binding changed.'
  }
  return 'qualified_generic_successor_replay'
}

$ticket = (Read-C33JFile `
  -Path 'config/uaw-c33j-screen03-passwordless-email-link-native-parity-ticket.json' `
  -Label 'ticket') | ConvertFrom-Json
$scope = (Read-C33JFile `
  -Path 'config/mvp-scope-gate-state.json' `
  -Label 'MVP scope state') | ConvertFrom-Json
$acceptance = (Read-C33JFile `
  -Path 'approved-references/screens/03-login-account-handoff/v5/production-acceptance.json' `
  -Label 'founder v5 acceptance') | ConvertFrom-Json
$services = Read-C33JFile `
  -Path 'apps/mobile/lib/features/journey01/journey_services.dart' `
  -Label 'journey services'
$session = Read-C33JFile `
  -Path 'apps/mobile/lib/features/journey01/journey_session.dart' `
  -Label 'JourneySession'
$firebase = Read-C33JFile `
  -Path 'apps/mobile/lib/features/journey01/review_journey_services.dart' `
  -Label 'Firebase gateway'
$screen = Read-C33JFile `
  -Path 'apps/mobile/lib/ui_v2/screens/screen03_login/login_screen_v5.dart' `
  -Label 'Screen03 v5 native owner'
$router = Read-C33JFile `
  -Path 'apps/mobile/lib/features/journey01/journey_router.dart' `
  -Label 'journey router'
$main = Read-C33JFile -Path 'apps/mobile/lib/main.dart' -Label 'runtime wiring'
$test = Read-C33JFile `
  -Path 'apps/mobile/test/uaw_c33j_screen03_passwordless_email_link_native_parity_test.dart' `
  -Label 'focused C33J matrix'

Assert-C33J -Condition (
  [string]$ticket.ticketId -ceq
    'UAW-C33J-SCREEN03-PASSWORDLESS-EMAIL-LINK-NATIVE-PARITY' -and
  [string]$ticket.classification -ceq 'mvp_required' -and
  [bool]$ticket.authority.nativeRuntimeSourceWriteAuthorized -and
  [bool]$ticket.authority.testAndGateWriteAuthorized -and
  -not [bool]$ticket.authority.backendWriteAuthorized -and
  -not [bool]$ticket.authority.hostingOrExternalServiceWriteAuthorized -and
  -not [bool]$ticket.authority.liveEmailSendAuthorized -and
  -not [bool]$ticket.authority.buildPlayOrDeviceMutationAuthorized -and
  -not [bool]$ticket.authority.secretValueAccessAuthorized
) -Message 'ticket identity, classification or closed live-action boundary changed.'
$selectedAssessment = $scope.preTicketSelectionCheckpoint.selectedTicketAssessment
$selectedManifestPath = [string]$selectedAssessment.manifestPath
[void](Read-C33JFile -Path $selectedManifestPath -Label 'selected ticket manifest')
$selectedManifestFullPath = [IO.Path]::GetFullPath((Join-Path $root $selectedManifestPath))
foreach ($assessment in @(
  $scope.preTicketSelectionCheckpoint.priorC33JSelectedTicketAssessment,
  $scope.preTicketSelectionCheckpoint.priorC33JFix1SelectedTicketAssessment,
  $scope.preTicketSelectionCheckpoint.priorC33JFix2SelectedTicketAssessment
)) {
  [void](Read-C33JFile `
    -Path ([string]$assessment.evidencePath) `
    -Label 'qualified C33J evidence')
}
$selectionMode = Get-C33JGenericSuccessorMode `
  -Scope $scope `
  -SelectedTicketSha256 (
    Get-FileHash -Algorithm SHA256 -LiteralPath $selectedManifestFullPath
  ).Hash `
  -ParentEvidenceExists $true `
  -Fix1EvidenceExists $true `
  -Fix2EvidenceExists $true
Assert-C33J -Condition (
  [bool]$scope.execution.testOrGateWriteAuthorized -and
  (
    ($selectionMode -cin @('parent_active', 'FIX1_active', 'FIX2_active') -and
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
) -Message 'active MVP selection, qualified FIX1/FIX2 succession or execution boundary changed.'
Assert-C33J -Condition (
  [string]$acceptance.status -ceq 'Accepted' -and
  [string]$acceptance.verification.founderDecision -ceq 'FINAL' -and
  [string]$acceptance.approval.sourceSha256 -ceq
    '1E4DB8FA47E42FD065E8A404D78C17DA2A0023D39F724C6A55A1562467F1A6AB' -and
  [string]$acceptance.verification.nativeFlutterParity -ceq
    'pending separate successor qualification'
) -Message 'founder v5 acceptance identity changed or was silently relabelled.'

foreach ($required in @(
  'abstract interface class EmailLinkGateway',
  'class UnavailableEmailLinkGateway implements EmailLinkGateway',
  'class ReviewEmailLinkGateway implements EmailLinkGateway',
  'Future<void> sendSignInLink(String emailAddress)',
  'Future<String> signInWithEmailLink({'
)) {
  Assert-C33J -Condition (
    $services.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "email-link gateway contract is missing: $required"
}
foreach ($required in @(
  'enum EmailLinkState',
  'this.emailLinkAvailable = false',
  'Future<bool> requestEmailLink(String value)',
  'Future<bool> resendEmailLink()',
  'Future<bool> prepareEmailLinkReturn(String emailLink)',
  'Future<bool> completeEmailLink(String value)',
  'await _rollbackIncompleteEmailLinkAuthentication();',
  'Future<void> _rollbackIncompleteEmailLinkAuthentication()',
  "'expired-action-code' => EmailLinkState.expired",
  "'invalid-action-code' => EmailLinkState.invalid"
)) {
  Assert-C33J -Condition (
    $session.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "JourneySession email-link state owner is missing: $required"
}
$snapshotMatch = [regex]::Match(
  $services,
  '(?s)class JourneySnapshot(?<body>.*?)abstract interface class JourneyStore'
)
Assert-C33J -Condition $snapshotMatch.Success `
  -Message 'JourneySnapshot persistence boundary is missing.'
$snapshotBody = $snapshotMatch.Groups['body'].Value
Assert-C33J -Condition (
  $snapshotBody.IndexOf('emailLink', [StringComparison]::OrdinalIgnoreCase) -lt 0 -and
  $snapshotBody.IndexOf('emailAddress', [StringComparison]::OrdinalIgnoreCase) -lt 0
) -Message 'email link or address appears in the persisted JourneySnapshot schema.'

foreach ($required in @(
  'class FirebaseEmailLinkGateway implements EmailLinkGateway',
  'handleCodeInApp: true',
  "androidPackageName: 'com.moolsocial.app'",
  'await _auth.sendSignInLinkToEmail(',
  '_auth.isSignInWithEmailLink(emailLink)',
  'await _auth.signInWithEmailLink('
)) {
  Assert-C33J -Condition (
    $firebase.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "Firebase email-link adapter is missing: $required"
}

foreach ($required in @(
  "screenKey: const Key('screen03-login-v5')",
  "title: 'Email link'",
  'subtitle: widget.session.emailLinkAvailable',
  "? 'Use any email address'",
  ": 'Not available on this build'",
  "title: 'Mobile OTP'",
  'for (final provider in SocialAuthProvider.values)',
  "findsNothing"
)) {
  $owner = if ($required -ceq 'findsNothing') { $test } else { $screen }
  Assert-C33J -Condition (
    $owner.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "native reference parity anchor is missing: $required"
}
Assert-C33J -Condition (
  $screen.IndexOf("title: 'Email OTP'", [StringComparison]::Ordinal) -lt 0 -and
  $screen.IndexOf('requestEmailOtp(', [StringComparison]::Ordinal) -lt 0 -and
  $screen.IndexOf('IntrinsicHeight', [StringComparison]::Ordinal) -lt 0
) -Message 'numeric Email OTP or rejected intrinsic layout re-entered Screen03 v5.'

foreach ($required in @(
  "'MOOLSOCIAL_EMAIL_LINK_CONTINUE_URL'",
  "'MOOLSOCIAL_EMAIL_LINK_DOMAIN'",
  'emailLinkRuntimeAvailable = isQualifiedEmailLinkRuntimeConfiguration(',
  'continueUrl: _emailLinkContinueUrl',
  'linkDomain: _emailLinkDomain',
  'emailLinkQualified: emailLinkRuntimeAvailable,',
  'final emailLinkGatewaySelection = resolveEmailLinkGatewaySelection(',
  'runtimeConfigurationAvailable: emailLinkRuntimeAvailable,',
  'publicAuthRuntimeConfiguration.passwordlessEmailAvailable,',
  'await session',
  '.prepareEmailLinkReturn(platformRouteName)',
  '.timeout(_releasePlatformStageTimeout);'
)) {
  Assert-C33J -Condition (
    $main.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "runtime email-link fail-closed wiring is missing: $required"
}
Assert-C33J -Condition (
  $router.IndexOf(
    "import '../../ui_v2/screens/screen03_login/login_screen_v5.dart';",
    [StringComparison]::Ordinal
  ) -ge 0 -and
  $router.IndexOf('LoginScreenV5(session: session)', [StringComparison]::Ordinal) -ge 0 -and
  $router.IndexOf('LoginScreenV2(session: session)', [StringComparison]::Ordinal) -ge 0
) -Message 'versioned sign-in route selection changed.'

foreach ($required in @(
  'founder-final chooser preserves exact method structure',
  'product sign-in route selects v5 without changing v4 owner',
  'visible unavailable provider is physically non-actionable',
  'email link validates, masks and never claims early success',
  'resend is fail-closed until cooldown ends',
  'same-session valid link completes exact pending destination',
  'unclassified Firebase send failure remains stage-specific',
  'process return asks for matching email before completion',
  'expired link and bootstrap failure stay recoverable',
  'small viewport and 140 percent text remain scroll-safe',
  'Mobile OTP keeps the existing verified route contract'
)) {
  Assert-C33J -Condition (
    $test.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "focused C33J matrix is missing: $required"
}
Assert-C33J -Condition (
  ([regex]::Matches($test, '\btest(?:Widgets)?\(')).Count -eq 11
) -Message 'focused C33J matrix count changed from eleven.'

Write-Output (
  'C33J Screen03 email-link native parity gate passed: reference=FINAL-v5; ' +
  "selectionMode=$selectionMode; " +
  'focusedMatrix=11; providerGrid=6; MobileOTP=preserved; opaqueLinkPersisted=false; ' +
  'externalWrites=false; liveEmail=false; buildPlayDevice=false.'
)
