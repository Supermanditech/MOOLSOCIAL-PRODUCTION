[CmdletBinding()]
param(
  [string]$RepositoryRoot,
  [string]$ScopePath = 'config/mvp-scope-gate-state.json'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C30Z {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) {
    throw "C30Z authentication truth gate rejected: $Message"
  }
}

function Resolve-C30ZFile {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label
  )
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $Path))
  Assert-C30Z -Condition (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $resolved -PathType Leaf)
  ) -Message "$Label is missing or escaped the repository: $Path"
  return $resolved
}

$historicalGate = Resolve-C30ZFile `
  -Path 'scripts/check-screen03-v4-production-acceptance-c30x-fix1.ps1' `
  -Label 'historical Screen03 v4 gate'
Assert-C30Z -Condition (
  (Get-FileHash -Algorithm SHA256 -LiteralPath $historicalGate).Hash -ceq
    '0430BDCC2D6C9F9C9A439C5D5889F190D72365A22183A08B5735229F02E7C6FC'
) -Message 'historical Screen03 v4 gate changed.'

$approvedUiGate = Resolve-C30ZFile `
  -Path 'scripts/check-approved-ui-locks.ps1' `
  -Label 'approved UI lock gate'
& $approvedUiGate -RepositoryRoot $root

$scopePath = Resolve-C30ZFile `
  -Path $ScopePath `
  -Label 'MVP scope state'
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$c30zTicketId =
  'UAW-C30Z-R60-48-AUTHENTICATION-METHOD-TRUTH-AND-GUEST-FEED-RECOVERY'
$c33eTicketId =
  'UAW-C33E-R60-48-PLAY-INSTALLED-AUTH-LOGIN-DEVICE-REPRODUCTION'
$c33eFix1TicketId =
  'UAW-C33E-FIX1-C30Z-QUALIFIED-SUCCESSOR-GATE-LIFECYCLE'
$c33eFix2TicketId =
  'UAW-C33E-FIX2-GOOGLE-AUTH-LIVE-PROVIDER-READINESS-HARD-GATE'
$c33eFix3TicketId =
  'UAW-C33E-FIX3-SOCIAL-AUTH-ROLLBACK-INDEPENDENT-CLEANUP'
$c33eFix4TicketId =
  'UAW-C33E-FIX4-PROTECTED-SOCIAL-ACTION-INTENT-RETURN-CONTINUITY'
$c33fTicketId =
  'UAW-C33F-R60-49-GOOGLE-AUTH-SUCCESSOR-AAB-PLAY-INTERNAL-OPPO-ACCEPTANCE'
$ticketHashes = @{
  $c30zTicketId = '5A03AD26DAE2AAA9CD724A1F05AE1D0CE0FB4F0D5DFEEFB05AF3DDE58F7B1AD8'
  $c33eTicketId = '64441D2ED89084C33AD57DAF3BA40CF5E355B18B2120C0D541CE079F01D6EAAE'
  $c33eFix1TicketId = 'E828DACE4821ECBFAC43737617B976286258F29BEF4EBC8FA4173691A3A359F0'
  $c33eFix2TicketId = 'DFECEF0BBBC320472AB0267BE293CC836FBD1C12FEDF6B61C8048FF0ED1A74F1'
  $c33eFix3TicketId = 'C0DC198E6CB37F1AFB8D8EF73D05390F1EF0E9BB089E0FB4A218F4975C07CFD9'
  $c33eFix4TicketId = 'E243C28BEEB4732C8F512053146C41229AAD9E3109C87A3C99D041FA79499047'
  $c33fTicketId = '815C70015058DE27B0F117517FB7599F6D7D99D340A217D65F9BFF3E163660C2'
}
$ticketPaths = @{
  $c30zTicketId = 'config/uaw-c30z-r60-48-authentication-method-truth-and-guest-feed-recovery-ticket.json'
  $c33eTicketId = 'config/uaw-c33e-r60-48-play-installed-auth-login-device-reproduction-ticket.json'
  $c33eFix1TicketId = 'config/uaw-c33e-fix1-c30z-qualified-successor-gate-lifecycle-ticket.json'
  $c33eFix2TicketId = 'config/uaw-c33e-fix2-google-auth-live-provider-readiness-hard-gate-ticket.json'
  $c33eFix3TicketId = 'config/uaw-c33e-fix3-social-auth-rollback-independent-cleanup-ticket.json'
  $c33eFix4TicketId = 'config/uaw-c33e-fix4-protected-social-action-intent-return-continuity-ticket.json'
  $c33fTicketId = 'config/uaw-c33f-r60-49-google-auth-successor-aab-play-internal-oppo-acceptance-ticket.json'
}
foreach ($ticketId in @(
  $c30zTicketId,
  $c33eTicketId,
  $c33eFix1TicketId,
  $c33eFix2TicketId,
  $c33eFix3TicketId,
  $c33eFix4TicketId,
  $c33fTicketId
)) {
  $ticketPath = Resolve-C30ZFile -Path $ticketPaths[$ticketId] `
    -Label "$ticketId ticket"
  Assert-C30Z -Condition (
    (Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash -ceq
      $ticketHashes[$ticketId]
  ) -Message "$ticketId ticket bytes changed."
}
$c30zTicket = Get-Content -Raw -LiteralPath (
  Resolve-C30ZFile -Path $ticketPaths[$c30zTicketId] -Label 'C30Z ticket'
) | ConvertFrom-Json
Assert-C30Z -Condition (
  [string]$c30zTicket.state -ceq
    'unlocked_source_two_identical_cycles_qualified_locked_presentation_live_provider_and_successor_release_pending' -and
  [string]$c30zTicket.sourceQualification.state -ceq
    'two_identical_cycles_passed_partial_ticket_qualification' -and
  [int]$c30zTicket.sourceQualification.flutterPassedPerCycle -eq 418 -and
  [int]$c30zTicket.sourceQualification.flutterFailedPerCycle -eq 0 -and
  [string]$c30zTicket.sourceQualification.historicalR60_48CountsPreserved -ceq '1/1/1' -and
  [string]$c30zTicket.sourceQualification.newReleaseActions -ceq '0/0/0'
) -Message 'preserved C30Z qualification changed.'
$c33eTicket = Get-Content -Raw -LiteralPath (
  Resolve-C30ZFile -Path $ticketPaths[$c33eTicketId] -Label 'C33E ticket'
) | ConvertFrom-Json
$c33eFix1Ticket = Get-Content -Raw -LiteralPath (
  Resolve-C30ZFile -Path $ticketPaths[$c33eFix1TicketId] -Label 'C33E FIX1 ticket'
) | ConvertFrom-Json
$c33eFix2Ticket = Get-Content -Raw -LiteralPath (
  Resolve-C30ZFile -Path $ticketPaths[$c33eFix2TicketId] -Label 'C33E FIX2 ticket'
) | ConvertFrom-Json
$c33eFix3Ticket = Get-Content -Raw -LiteralPath (
  Resolve-C30ZFile -Path $ticketPaths[$c33eFix3TicketId] -Label 'C33E FIX3 ticket'
) | ConvertFrom-Json
$c33eFix4Ticket = Get-Content -Raw -LiteralPath (
  Resolve-C30ZFile -Path $ticketPaths[$c33eFix4TicketId] -Label 'C33E FIX4 ticket'
) | ConvertFrom-Json
$c33fTicket = Get-Content -Raw -LiteralPath (
  Resolve-C30ZFile -Path $ticketPaths[$c33fTicketId] -Label 'C33F ticket'
) | ConvertFrom-Json
Assert-C30Z -Condition (
  [string]$c33eTicket.state -ceq
    'founder_authorized_existing_play_client_reproduction_selected_no_build_install_provider_or_secret_authority' -and
  [bool]$c33eTicket.authority.existingPlayClientLaunchAndTapAuthorized -and
  -not [bool]$c33eTicket.authority.deviceInstallOrUpdateAuthorized -and
  -not [bool]$c33eTicket.authority.successorBuildOrPlayAuthorized -and
  -not [bool]$c33eTicket.authority.secretValueAccessAuthorized
) -Message 'C33E parent ticket or authority changed.'
Assert-C30Z -Condition (
  [string]$c33eFix1Ticket.state -ceq
    'test_gate_repair_qualified_dual_host_exact_lifecycle_and_negative_drift_cases_passed_all_runtime_live_device_and_secret_actions_held' -and
  [string]$c33eFix1Ticket.qualification.powerShell7 -ceq 'passed' -and
  [string]$c33eFix1Ticket.qualification.windowsPowerShell51 -ceq 'passed' -and
  [int]$c33eFix1Ticket.qualification.temporaryFixtureResidue -eq 0 -and
  -not [bool]$c33eFix1Ticket.authority.runtimeSourceWriteAuthorized -and
  -not [bool]$c33eFix1Ticket.authority.buildPlayOrDeviceInstallAuthorized -and
  -not [bool]$c33eFix1Ticket.authority.secretValueAccessAuthorized
) -Message 'C33E FIX1 qualification or authority changed.'
Assert-C30Z -Condition (
  [string]$c33eFix2Ticket.state -ceq
    'founder_authorized_test_gate_implementation_selected_no_build_provider_device_or_secret_authority' -and
  [string]$c33eFix2Ticket.classification -ceq 'mvp_required' -and
  [bool]$c33eFix2Ticket.authority.testAndGateWriteAuthorized -and
  -not [bool]$c33eFix2Ticket.authority.runtimeSourceWriteAuthorized -and
  -not [bool]$c33eFix2Ticket.authority.buildPlayOrDeviceInstallAuthorized -and
  -not [bool]$c33eFix2Ticket.authority.providerOrExternalServiceAuthorized -and
  -not [bool]$c33eFix2Ticket.authority.secretValueAccessAuthorized
) -Message 'C33E FIX2 ticket or authority changed.'
Assert-C30Z -Condition (
  [string]$c33eFix3Ticket.state -ceq
    'founder_authorized_runtime_and_test_repair_selected_no_build_provider_device_external_or_secret_authority' -and
  [string]$c33eFix3Ticket.classification -ceq 'mvp_required' -and
  [bool]$c33eFix3Ticket.authority.runtimeSourceWriteAuthorized -and
  [bool]$c33eFix3Ticket.authority.testAndGateWriteAuthorized -and
  -not [bool]$c33eFix3Ticket.authority.buildPlayOrDeviceInstallAuthorized -and
  -not [bool]$c33eFix3Ticket.authority.providerOrExternalServiceAuthorized -and
  -not [bool]$c33eFix3Ticket.authority.secretValueAccessAuthorized
) -Message 'C33E FIX3 ticket or authority changed.'
Assert-C30Z -Condition (
  [string]$c33eFix4Ticket.state -ceq
    'founder_authorized_runtime_and_test_repair_selected_no_build_provider_device_external_or_secret_authority' -and
  [string]$c33eFix4Ticket.classification -ceq 'mvp_required' -and
  [bool]$c33eFix4Ticket.authority.runtimeSourceWriteAuthorized -and
  [bool]$c33eFix4Ticket.authority.testAndGateWriteAuthorized -and
  -not [bool]$c33eFix4Ticket.authority.backendSourceWriteAuthorized -and
  -not [bool]$c33eFix4Ticket.authority.buildPlayOrDeviceInstallAuthorized -and
  -not [bool]$c33eFix4Ticket.authority.providerOrExternalServiceAuthorized -and
  -not [bool]$c33eFix4Ticket.authority.secretValueAccessAuthorized
) -Message 'C33E FIX4 ticket or authority changed.'
Assert-C30Z -Condition (
  [string]$c33fTicket.state -ceq
    'founder_authorized_exact_candidate_registered_live_readiness_and_source_requalification_required' -and
  [string]$c33fTicket.classification -ceq 'mvp_required' -and
  [string]$c33fTicket.candidate.versionName -ceq '1.0.0-r60.49' -and
  [string]$c33fTicket.candidate.versionCode -ceq '2026081349' -and
  [bool]$c33fTicket.authority.oneAabBuildAuthorizedAfterAllGates -and
  -not [bool]$c33fTicket.authority.agentSecretValueAccessAuthorized -and
  -not [bool]$c33fTicket.authority.otherTrackAuthorized -and
  -not [bool]$c33fTicket.authority.adbOrSideloadAuthorized -and
  -not [bool]$c33fTicket.authority.backendOrHostingDeploymentAuthorized -and
  -not [bool]$c33fTicket.authority.providerDeploymentAuthorized -and
  -not [bool]$c33fTicket.authority.emailOrQuotaSubmissionAuthorized
) -Message 'C33F successor ticket, candidate or authority changed.'

$activeTicketId = [string]$scope.ticket.id
Assert-C30Z -Condition (
  @(
    $c30zTicketId,
    $c33eTicketId,
    $c33eFix1TicketId,
    $c33eFix2TicketId,
    $c33eFix3TicketId,
    $c33eFix4TicketId,
    $c33fTicketId
  ) -ccontains
    $activeTicketId
) -Message 'active ticket is outside the exact C30Z/C33E lifecycle.'
Assert-C30Z -Condition (
  [string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq
    $activeTicketId -and
  [string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.ticketId -ceq
    $activeTicketId -and
  [string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -ceq
    $ticketHashes[$activeTicketId]
) -Message 'active ticket selection assessment changed.'
$commonHeld = (
  -not [bool]$scope.execution.referenceWriteAuthorized -and
  -not [bool]$scope.execution.backendWriteAuthorized -and
  -not [bool]$scope.execution.buildAuthorized -and
  -not [bool]$scope.execution.deviceInstallAuthorized -and
  -not [bool]$scope.execution.externalServiceWriteAuthorized -and
  -not [bool]$scope.execution.secretValueAccessAuthorized -and
  -not [bool]$scope.providerGate.externalServiceWriteAuthorized -and
  -not [bool]$scope.providerGate.secretValueAccessAuthorized -and
  -not [bool]$scope.providerGate.apkBuildOrInstallAuthorized -and
  -not [bool]$scope.providerGate.productionOrProviderDeploymentAuthorized -and
  -not [bool]$scope.providerGate.DevProviderDeploymentAuthorized -and
  -not [bool]$scope.providerGate.emailOrQuotaSubmissionAuthorized
)
$activeC30Z = $activeTicketId -ceq $c30zTicketId
$activeC33E = $activeTicketId -ceq $c33eTicketId
$activeC33EFix1 = $activeTicketId -ceq $c33eFix1TicketId
$activeC33EFix2 = $activeTicketId -ceq $c33eFix2TicketId
$activeC33EFix3 = $activeTicketId -ceq $c33eFix3TicketId
$activeC33EFix4 = $activeTicketId -ceq $c33eFix4TicketId
$activeC33F = $activeTicketId -ceq $c33fTicketId
$lifecycleAuthorityValid = if ($activeC30Z) {
  [bool]$scope.execution.runtimeWriteAuthorized -and
  [bool]$scope.execution.testOrGateWriteAuthorized -and
  -not [bool]$scope.providerGate.existingProtectedClientLaunchAndTapAuthorized
} elseif ($activeC33E) {
  -not [bool]$scope.execution.runtimeWriteAuthorized -and
  [bool]$scope.execution.testOrGateWriteAuthorized -and
  [bool]$scope.providerGate.existingProtectedClientLaunchAndTapAuthorized -and
  [string]$scope.providerGate.nextTicket -ceq $c33eTicketId
} elseif ($activeC33EFix1) {
  -not [bool]$scope.execution.runtimeWriteAuthorized -and
  [bool]$scope.execution.testOrGateWriteAuthorized -and
  -not [bool]$scope.providerGate.existingProtectedClientLaunchAndTapAuthorized -and
  [string]$scope.providerGate.nextTicket -ceq $c33eFix1TicketId
} elseif ($activeC33EFix2) {
  -not [bool]$scope.execution.runtimeWriteAuthorized -and
  [bool]$scope.execution.testOrGateWriteAuthorized -and
  -not [bool]$scope.providerGate.existingProtectedClientLaunchAndTapAuthorized -and
  [string]$scope.providerGate.nextTicket -ceq $c33eFix2TicketId
} elseif ($activeC33EFix3) {
  [bool]$scope.execution.runtimeWriteAuthorized -and
  [bool]$scope.execution.testOrGateWriteAuthorized -and
  -not [bool]$scope.providerGate.existingProtectedClientLaunchAndTapAuthorized -and
  [string]$scope.providerGate.nextTicket -ceq $c33eFix3TicketId
} elseif ($activeC33EFix4) {
  [bool]$scope.execution.runtimeWriteAuthorized -and
  [bool]$scope.execution.testOrGateWriteAuthorized -and
  -not [bool]$scope.providerGate.existingProtectedClientLaunchAndTapAuthorized -and
  [string]$scope.providerGate.nextTicket -ceq $c33eFix4TicketId
} else {
  $activeC33F -and
  -not [bool]$scope.execution.runtimeWriteAuthorized -and
  [bool]$scope.execution.testOrGateWriteAuthorized -and
  -not [bool]$scope.providerGate.existingProtectedClientLaunchAndTapAuthorized -and
  [string]$scope.providerGate.nextTicket -ceq $c33fTicketId
}
Assert-C30Z -Condition ($commonHeld -and $lifecycleAuthorityValid) `
  -Message 'active ticket or source/test/device authority boundary changed.'

$releaseStatePath = Resolve-C30ZFile `
  -Path 'config/successor-aab-regression-hard-gate-state-c30x.json' `
  -Label 'r60.48 release state'
$release = Get-Content -Raw -LiteralPath $releaseStatePath | ConvertFrom-Json
Assert-C30Z -Condition (
  [string]$release.machineState -ceq
    'acceptance_failed_r60_48_social_auth_and_action_journey_defects_successor_required' -and
  [int]$release.buildResult.buildCount -eq 1 -and
  [int]$release.playResult.uploadCount -eq 1 -and
  [int]$release.installResult.installCount -eq 1 -and
  [string]$release.installAuthorization -ceq 'consumed' -and
  [string]$release.deviceAuthorization -ceq 'consumed' -and
  -not [bool]$release.installResult.acceptanceSucceeded
) -Message 'failed r60.48 identity, counts or consumed device authority changed.'

$owners = [ordered]@{
  main = Resolve-C30ZFile -Path 'apps/mobile/lib/main.dart' -Label 'mobile main'
  runtime = Resolve-C30ZFile -Path 'apps/mobile/lib/core/config/release_runtime_configuration.dart' -Label 'runtime configuration'
  services = Resolve-C30ZFile -Path 'apps/mobile/lib/features/journey01/journey_services.dart' -Label 'journey services'
  session = Resolve-C30ZFile -Path 'apps/mobile/lib/features/journey01/journey_session.dart' -Label 'journey session'
  sessionTest = Resolve-C30ZFile -Path 'apps/mobile/test/screen03_session_test.dart' -Label 'session tests'
  feedTest = Resolve-C30ZFile -Path 'apps/mobile/test/c30t_social_auth_and_feed_gateway_test.dart' -Label 'guest Feed tests'
  runtimeTest = Resolve-C30ZFile -Path 'apps/mobile/test/release_runtime_configuration_test.dart' -Label 'runtime configuration tests'
}
$source = [ordered]@{}
foreach ($entry in $owners.GetEnumerator()) {
  $source[$entry.Key] = Get-Content -Raw -LiteralPath $entry.Value
}

foreach ($required in @(
  "String.fromEnvironment('MOOLSOCIAL_AUTH_API_BASE_URL')",
  "bool.fromEnvironment('MOOLSOCIAL_PHONE_OTP_ENABLED'",
  'emailOtpAvailable: isQualifiedHttpsRuntimeEndpoint(_authApiBaseUrl)',
  'mobileOtpAvailable: _phoneOtpEnabled',
  'availableSocialAuthProviders: _productionSocialIdentityProviders'
)) {
  Assert-C30Z -Condition $source.main.Contains($required) `
    -Message "main availability binding is missing: $required"
}
foreach ($required in @(
  'bool isQualifiedHttpsRuntimeEndpoint(String value)',
  "uri.scheme == 'https'",
  'uri.host.isNotEmpty'
)) {
  Assert-C30Z -Condition $source.runtime.Contains($required) `
    -Message "runtime endpoint qualification is missing: $required"
}
foreach ($required in @(
  'isSocialAuthProviderAvailable(SocialAuthProvider provider)',
  'if (!mobileOtpAvailable)',
  'if (!emailOtpAvailable)',
  'await _rollbackIncompleteSocialAuthentication();',
  'await _socialAuthGateway.signOut();'
)) {
  Assert-C30Z -Condition $source.session.Contains($required) `
    -Message "session method-truth or rollback invariant is missing: $required"
}
Assert-C30Z -Condition $source.services.Contains('int signOutCount = 0;') `
  -Message 'review social rollback observation is missing.'
foreach ($required in @(
  'unavailable auth methods fail before gateway dispatch',
  'account bootstrap failure rolls back partial social identity'
)) {
  Assert-C30Z -Condition $source.sessionTest.Contains($required) `
    -Message "session regression is missing: $required"
}
foreach ($required in @(
  'C30T guest remains ready for public reads and can begin real sign-in',
  'C30T guest Create rail starts sign-in with exact return',
  'C30T public media and Share stay guest-readable while account actions gate'
)) {
  Assert-C30Z -Condition $source.feedTest.Contains($required) `
    -Message "guest Feed/write-return regression is missing: $required"
}
Assert-C30Z -Condition (
  $source.runtimeTest.Contains(
    'external auth endpoints require an exact HTTPS authority'
  )
) -Message 'HTTPS endpoint regression is missing.'

Write-Output (
  'C30Z authentication method truth gate passed: ' +
  "lifecycle=$activeTicketId; " +
  'lockedScreen03Changed=false; providerDispatchUnified=true; ' +
  'emailOtpQualifiedHttps=true; phoneOtpExplicitEnable=true; ' +
  'partialSocialAuthRollback=true; guestFeedRead=true; ' +
  'build=false; deviceInstall=false; ' +
  "existingClientTap=$([bool]$scope.providerGate.existingProtectedClientLaunchAndTapAuthorized); " +
  'external=false.'
)
