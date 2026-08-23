[CmdletBinding()]
param(
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot)

function Assert-C34P([bool]$Condition, [string]$Message) {
  if (-not $Condition) {
    throw "C34P public-authentication gate rejected: $Message"
  }
}

function Read-Owner([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C34P ($path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) `
    "owner escaped the repository: $RelativePath"
  Assert-C34P (Test-Path -LiteralPath $path -PathType Leaf) `
    "owner is missing: $RelativePath"
  return Get-Content -LiteralPath $path -Raw
}

function Test-C34PAuthorizedTicketSelection(
  [string]$CurrentTicketId,
  [string]$CheckpointTicketId,
  [string[]]$AuthorizedTicketIds
) {
  return (
    $CurrentTicketId -ceq $CheckpointTicketId -and
    $AuthorizedTicketIds -ccontains $CurrentTicketId
  )
}

$parentTicketPath = Join-Path $root `
  'config\uaw-c34p-fix1a-all-eight-public-auth-live-adapter-blocker-resolution-ticket.json'
$parentTicket = Get-Content -LiteralPath $parentTicketPath -Raw |
  ConvertFrom-Json
Assert-C34P (
  [string]$parentTicket.ticketId -ceq
  'UAW-C34P-FIX1A-ALL-EIGHT-PUBLIC-AUTH-LIVE-ADAPTER-BLOCKER-RESOLUTION'
) 'parent ticket identity changed.'
Assert-C34P ([string]$parentTicket.classification -ceq 'beyond_mvp') `
  'parent classification changed.'
Assert-C34P ([bool]$parentTicket.oneLogicalImplementationWave) `
  'parent no longer selects one implementation wave.'
Assert-C34P (@($parentTicket.acceptanceChildren).Count -eq 4) `
  'parent acceptance-child inventory changed.'
Assert-C34P ([bool]$parentTicket.authority.runtimeSourceWriteAuthorizedAfterMvpGate) `
  'runtime source authority is missing.'
Assert-C34P ([bool]$parentTicket.authority.testAndGateWriteAuthorizedAfterMvpGate) `
  'test/gate authority is missing.'
Assert-C34P ([bool]$parentTicket.authority.backendSourceWriteAuthorizedAfterMvpGate) `
  'backend source authority is missing.'
Assert-C34P (-not [bool]$parentTicket.authority.buildPlayOrDeviceActionAuthorized) `
  'build, Play or device authority was added.'
Assert-C34P (-not [bool]$parentTicket.authority.secretOrPrivateValueAccessAuthorized) `
  'secret access authority was added.'

$scopeState = Get-Content -LiteralPath (
  Join-Path $root 'config\mvp-scope-gate-state.json'
) -Raw | ConvertFrom-Json
$authorizedTicketIds = @(
  [string]$parentTicket.ticketId,
  'UAW-C34P-FIX5-ALL-EIGHT-PUBLIC-AUTH-LIVE-PROVIDER-READINESS',
  'UAW-C34P-FIX8-GLOBAL-SOCIAL-LOGIN-OPPO-SUCCESSOR-AUDIT-REPAIR'
)
Assert-C34P (
  Test-C34PAuthorizedTicketSelection `
    -CurrentTicketId ([string]$scopeState.ticket.id) `
    -CheckpointTicketId (
      [string]$scopeState.preTicketSelectionCheckpoint.currentTicketId
    ) `
    -AuthorizedTicketIds $authorizedTicketIds
) 'MVP scope state does not select an authorized C34P auth ticket.'
Assert-C34P (-not (
  Test-C34PAuthorizedTicketSelection `
    -CurrentTicketId 'UNRELATED-TICKET' `
    -CheckpointTicketId 'UNRELATED-TICKET' `
    -AuthorizedTicketIds $authorizedTicketIds
)) 'unrelated-ticket negative fixture was accepted.'
$selectedTicketId = [string]$scopeState.ticket.id
$fix8TicketId = 'UAW-C34P-FIX8-GLOBAL-SOCIAL-LOGIN-OPPO-SUCCESSOR-AUDIT-REPAIR'
$fix8RepairRetryAuthorized = $false
$fix8ExpectedBuildAuthorized = $false
$fix8ExpectedInstallAuthorized = $false
if ($selectedTicketId -ceq $fix8TicketId) {
  $fix8Relative = `
    'config/uaw-c34p-fix8-global-social-login-oppo-successor-audit-repair-ticket.json'
  $fix8Path = Join-Path $root $fix8Relative
  Assert-C34P (Test-Path -LiteralPath $fix8Path -PathType Leaf) `
    'FIX8 selected ticket is missing.'
  $fix8 = Get-Content -LiteralPath $fix8Path -Raw | ConvertFrom-Json
  $fix8Hash = (Get-FileHash -LiteralPath $fix8Path -Algorithm SHA256).Hash
  $assessment = $scopeState.preTicketSelectionCheckpoint.selectedTicketAssessment
  $fix8SourceOnlyHeld = (
    [bool]$fix8.authority.sourceAndTestRepairAuthorizedAfterMvpGate -and
    -not [bool]$fix8.authority.buildAuthorized -and
    -not [bool]$fix8.authority.installOrOppoMutationAuthorized -and
    -not [bool]$fix8.authority.privateProviderLoginAuthorized
  )
  $fix8RepairRetryState = `
    'r60_81_release_resource_repair_one_rebuild_and_in_place_sideload_authorized'
  $fix8LegacyRepairRetryAuthorized = (
    [string]$fix8.status -ceq $fix8RepairRetryState -and
    [string]$fix8.releaseAuthorization.state -ceq $fix8RepairRetryState -and
    [int]$fix8.releaseAuthorization.maximumBuildCount -eq 2 -and
    [int]$fix8.releaseAuthorization.buildCount -eq 1 -and
    [int]$fix8.releaseAuthorization.installCount -eq 0 -and
    [bool]$fix8.authority.sourceAndTestRepairAuthorizedAfterMvpGate -and
    [bool]$fix8.authority.buildAuthorized -and
    [bool]$fix8.authority.installOrOppoMutationAuthorized -and
    -not [bool]$fix8.authority.sqlConnectProvisioningOrMigrationAuthorized -and
    -not [bool]$fix8.authority.privateProviderLoginAuthorized -and
    -not [bool]$fix8.authority.realEmailOrSmsAuthorized -and
    -not [bool]$fix8.authority.playOrProductionAuthorized -and
    -not [bool]$fix8.authority.youtubeApiFinalSubmissionAuthorized -and
    -not [bool]$fix8.authority.commitPushMergeAuthorized
  )
  $fix8R6084PrebuildAuthorizationState = `
    'r60_84_full_social_one_build_and_one_in_place_install_authorized_fresh_source_seal_bound'
  $fix8R6084PrebuildTicketState = `
    'fix10_all_auth_local_implementation_and_pre_apk_contract_qualified_r60_84_one_build_and_one_in_place_oppo_sideload_authorized_device_provider_reproof_pending'
  $fix8SourceManifestPath = [IO.Path]::GetFullPath((Join-Path `
    $root `
    ([string]$fix8.releaseAuthorization.sourceManifestPath)
  ))
  $fix8R6084Common = (
    [string]$fix8.releaseAuthorization.versionName -ceq '1.0.0-r60.84' -and
    [string]$fix8.releaseAuthorization.versionCode -ceq '2026082184' -and
    [int]$fix8.releaseAuthorization.maximumBuildCount -eq 1 -and
    [int]$fix8.releaseAuthorization.maximumInstallCount -eq 1 -and
    (Test-Path -LiteralPath $fix8SourceManifestPath -PathType Leaf) -and
    (Get-FileHash -LiteralPath $fix8SourceManifestPath -Algorithm SHA256).Hash `
      -ceq [string]$fix8.releaseAuthorization.sourceManifestSha256 -and
    [bool]$fix8.authority.sourceAndTestRepairAuthorizedAfterMvpGate -and
    -not [bool]$fix8.authority.sqlConnectProvisioningOrMigrationAuthorized -and
    -not [bool]$fix8.authority.privateProviderLoginAuthorized -and
    -not [bool]$fix8.authority.realEmailOrSmsAuthorized -and
    -not [bool]$fix8.authority.playOrProductionAuthorized -and
    -not [bool]$fix8.authority.youtubeApiFinalSubmissionAuthorized -and
    -not [bool]$fix8.authority.commitPushMergeAuthorized
  )
  $fix8R6084PrebuildAuthorized = (
    $fix8R6084Common -and
    [string]$fix8.status -ceq $fix8R6084PrebuildTicketState -and
    [string]$fix8.releaseAuthorization.state -ceq
      $fix8R6084PrebuildAuthorizationState -and
    [int]$fix8.releaseAuthorization.buildCount -eq 0 -and
    [int]$fix8.releaseAuthorization.installCount -eq 0 -and
    [bool]$fix8.authority.buildAuthorized -and
    [bool]$fix8.authority.installOrOppoMutationAuthorized
  )
  $fix8R6084PostbuildAuthorized = (
    $fix8R6084Common -and
    [string]$fix8.status -ceq
      'fix10_all_auth_r60_84_built_postbuild_qualified_one_in_place_oppo_sideload_authorized_device_provider_reproof_pending' -and
    [string]$fix8.releaseAuthorization.state -ceq
      'r60_84_one_build_consumed_postbuild_qualified_one_in_place_install_authorized' -and
    [int]$fix8.releaseAuthorization.buildCount -eq 1 -and
    [int]$fix8.releaseAuthorization.installCount -eq 0 -and
    -not [bool]$fix8.authority.buildAuthorized -and
    [bool]$fix8.authority.installOrOppoMutationAuthorized
  )
  $fix8R6084PostinstallAuthorized = (
    $fix8R6084Common -and
    [string]$fix8.status -ceq
      'fix10_all_auth_r60_84_built_and_installed_founder_private_provider_acceptance_pending' -and
    [string]$fix8.releaseAuthorization.state -ceq
      'r60_84_one_build_and_one_install_consumed_founder_private_provider_acceptance_pending' -and
    [int]$fix8.releaseAuthorization.buildCount -eq 1 -and
    [int]$fix8.releaseAuthorization.installCount -eq 1 -and
    -not [bool]$fix8.authority.buildAuthorized -and
    -not [bool]$fix8.authority.installOrOppoMutationAuthorized
  )
  $fix8RepairRetryAuthorized = (
    $fix8LegacyRepairRetryAuthorized -or
    $fix8R6084PrebuildAuthorized -or
    $fix8R6084PostbuildAuthorized -or
    $fix8R6084PostinstallAuthorized
  )
  $fix8ExpectedBuildAuthorized = (
    $fix8LegacyRepairRetryAuthorized -or $fix8R6084PrebuildAuthorized
  )
  $fix8ExpectedInstallAuthorized = (
    $fix8LegacyRepairRetryAuthorized -or
    $fix8R6084PrebuildAuthorized -or
    $fix8R6084PostbuildAuthorized
  )
  Assert-C34P (
    [string]$fix8.ticketId -ceq $fix8TicketId -and
    [string]$assessment.manifestPath -ceq $fix8Relative -and
    [string]$assessment.manifestSha256 -ceq $fix8Hash -and
    ($fix8SourceOnlyHeld -or $fix8RepairRetryAuthorized)
  ) 'FIX8 manifest binding or held authority changed.'
}
$externalProviderWriteExpected = $selectedTicketId -ceq `
  'UAW-C34P-FIX5-ALL-EIGHT-PUBLIC-AUTH-LIVE-PROVIDER-READINESS'
Assert-C34P (
  [bool]$scopeState.execution.runtimeWriteAuthorized -and
  [bool]$scopeState.execution.testOrGateWriteAuthorized -and
  [bool]$scopeState.execution.backendWriteAuthorized -and
  [bool]$scopeState.execution.buildAuthorized -eq
    $fix8ExpectedBuildAuthorized -and
  [bool]$scopeState.execution.deviceInstallAuthorized -eq
    $fix8ExpectedInstallAuthorized -and
  [bool]$scopeState.execution.externalServiceWriteAuthorized -eq
    $externalProviderWriteExpected -and
  -not [bool]$scopeState.execution.secretValueAccessAuthorized
) 'MVP execution authority does not match the selected C34P auth ticket.'

$failureSource = Read-Owner 'apps/mobile/lib/core/auth/public_auth_failure.dart'
$runtimeSource = Read-Owner `
  'apps/mobile/lib/core/auth/public_auth_runtime_configuration.dart'
$gatewaySource = Read-Owner `
  'apps/mobile/lib/features/journey01/review_journey_services.dart'
$mainSource = Read-Owner 'apps/mobile/lib/main.dart'
$xSource = Read-Owner 'apps/mobile/lib/core/auth/x_oauth2_pkce.dart'
$facebookSource = Read-Owner `
  'apps/mobile/lib/core/auth/facebook_login_contract.dart'
$xTest = Read-Owner 'apps/mobile/test/uaw_c34p_x_oauth2_pkce_test.dart'
$facebookTest = Read-Owner `
  'apps/mobile/test/uaw_c34p_facebook_login_contract_test.dart'

foreach ($token in @(
  'sanitizedGoogleIdentityFailure',
  'sanitizedFirebaseAuthFailure',
  'PublicAuthFailureClass.accountCollision',
  "'auth-unknown'"
)) {
  Assert-C34P ($failureSource.Contains($token)) `
    "sanitized failure taxonomy is missing: $token"
}
Assert-C34P (-not $gatewaySource.Contains('error.message')) `
  'provider-authored Firebase messages can reach public copy.'
Assert-C34P (-not $gatewaySource.Contains('TwitterAuthProvider()')) `
  'X regressed to the Firebase OAuth 1 provider.'
Assert-C34P (-not $gatewaySource.Contains('FacebookAuthProvider()')) `
  'Facebook regressed to unsupported native Firebase provider dispatch.'
Assert-C34P (
  $gatewaySource.Contains('SocialAuthProvider.google ||') -and
  $gatewaySource.Contains(
    'SocialAuthProvider.youtube => await _signInWithGoogleIdentity()'
  )
) 'Google and YouTube no longer share one identity dispatch.'

foreach ($token in @(
  'googleAndYoutubeAvailable',
  'passwordlessEmailAvailable',
  'mobileOtpAvailable',
  'appleAvailable',
  'xAvailable',
  'instagramAvailable',
  'facebookAvailable',
  'xFirebaseBrokerQualified',
  'instagramBrokerQualified',
  'facebookDataDeletionQualified'
)) {
  Assert-C34P ($runtimeSource.Contains($token)) `
    "runtime availability contract is missing: $token"
}
Assert-C34P ($mainSource.Contains('xPkceAdapterInstalled: xAdapter != null')) `
  'X is not bound to the real PKCE adapter readiness.'
Assert-C34P (
  $mainSource.Contains('instagramBrokerAdapterInstalled: instagramAdapter != null')
) 'Instagram is not bound to the real broker adapter readiness.'
Assert-C34P (
  $mainSource.Contains('facebookNativeAdapterInstalled: facebookAdapter.isConfigured')
) 'Facebook is not bound to the real native adapter readiness.'
Assert-C34P ($mainSource.Contains('MOOLSOCIAL_MOBILE_OTP_ATTESTATION_QUALIFIED')) `
  'mobile OTP lacks candidate-specific attestation readiness.'
foreach ($token in @(
  'MOOLSOCIAL_GLOBAL_SOCIAL_LOGIN_AUDIT',
  'resolveGlobalSocialLoginAuditComposition(',
  'globalSocialLoginAuditComposition.useReviewAuthentication',
  'useProductionProviderAvailability',
  'globalSocialLoginAuditEnabled: _globalSocialLoginAuditMode',
  'FirebaseAuthenticatedSessionBootstrapGateway('
)) {
  Assert-C34P ($mainSource.Contains($token)) `
    "FIX8 main composition is missing: $token"
}
Assert-C34P (
  $gatewaySource.Contains('class FirebaseAuthenticatedSessionBootstrapGateway')
) 'FIX8 Firebase session bootstrap owner is missing.'

foreach ($token in @(
  "import 'package:crypto/crypto.dart' as crypto;",
  "'tweet.read'",
  "'users.read'",
  "'code_challenge_method': 'S256'",
  "const <String>['token', 'client_id']",
  'includesClientSecret => false',
  'executesNetwork => false',
  'persistsCredentials => false'
)) {
  Assert-C34P ($xSource.Contains($token)) "X PKCE contract is missing: $token"
}
Assert-C34P (-not $xSource.Contains('offline.access')) `
  'X pure contract contains forbidden offline access.'
Assert-C34P (-not $xSource.Contains('roundConstants')) `
  'X contains a duplicate hand-written SHA-256 primitive.'
Assert-C34P ($xTest.Contains('RFC 7636')) `
  'X tests lack the RFC 7636 known vector.'

foreach ($token in @(
  "'com.moolsocial.app'",
  "'com.moolsocial.app.MainActivity'",
  "<String>{'public_profile'}",
  'emailPermissionRequestedByDefault = false',
  'FacebookLoginConfigurationIssue.nativeAdapterUnavailable',
  'FacebookAccountRequestKind.revokeAccess',
  'FacebookAccountRequestKind.dataDeletion'
)) {
  Assert-C34P ($facebookSource.Contains($token)) `
    "Facebook contract is missing: $token"
}
foreach ($forbidden in @(
  'flutter_facebook_auth',
  'FacebookAuth.instance',
  'HttpClient(',
  'client_secret',
  'access_token'
)) {
  Assert-C34P (-not $facebookSource.Contains($forbidden)) `
    "Facebook contract crossed its fail-closed boundary: $forbidden"
}
Assert-C34P ($facebookTest.Contains('public_profile')) `
  'Facebook tests lack the minimum-permission proof.'

Write-Output (
  'C34P public-authentication shared-gateway gate passed: ' +
  'parent=FIX1A; activeTicket=' + $selectedTicketId + '; ' +
  'children=4; runtimeBackendTest=true; ' +
  'googleYoutubeShared=true; appleFirebase=true; xPkce=true; ' +
  'instagramProfessional=true; facebookNative=true; ' +
  'emailLink=true; mobileOtpAttested=true; newScreens=0; newRoutes=0; ' +
  'externalProviderWriteAuthority=' +
  $externalProviderWriteExpected.ToString().ToLowerInvariant() + '.'
)
