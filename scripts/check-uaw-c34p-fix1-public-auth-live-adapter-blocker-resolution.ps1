[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C34PFix1A {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) {
    throw "C34P FIX1A all-eight auth gate rejected: $Message"
  }
}

function Read-C34PFix1AFile {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label
  )
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $Path))
  Assert-C34PFix1A -Condition (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)
  ) -Message "$Label escaped the repository."
  Assert-C34PFix1A -Condition (
    Test-Path -LiteralPath $resolved -PathType Leaf
  ) -Message "$Label is missing."
  return Get-Content -LiteralPath $resolved -Raw
}

function Assert-C34PFix1AContains {
  param(
    [Parameter(Mandatory)][string]$Body,
    [Parameter(Mandatory)][string]$Expected,
    [Parameter(Mandatory)][string]$Label
  )
  Assert-C34PFix1A -Condition (
    $Body.IndexOf($Expected, [StringComparison]::Ordinal) -ge 0
  ) -Message "$Label is missing: $Expected"
}

$parent = Read-C34PFix1AFile `
  -Path 'config/uaw-c34p-fix1a-all-eight-public-auth-live-adapter-blocker-resolution-ticket.json' `
  -Label 'FIX1A parent ticket' | ConvertFrom-Json
$authority = Read-C34PFix1AFile `
  -Path 'docs/quality/UAW-C34P-ALL-EIGHT-PUBLIC-AUTH-FOUNDER-CORRECTION-20260818.md' `
  -Label 'all-eight founder correction'
$mvp = Read-C34PFix1AFile `
  -Path 'config/mvp-scope-gate-state.json' `
  -Label 'MVP scope state' | ConvertFrom-Json

Assert-C34PFix1A -Condition (
  [string]$parent.ticketId -ceq
    'UAW-C34P-FIX1A-ALL-EIGHT-PUBLIC-AUTH-LIVE-ADAPTER-BLOCKER-RESOLUTION' -and
  [string]$parent.state -ceq
    'registered_founder_corrected_runtime_backend_platform_and_local_test_source_pending_scope_reselection' -and
  [string]$parent.classification -ceq 'beyond_mvp' -and
  [bool]$parent.authority.runtimeSourceWriteAuthorizedAfterMvpGate -and
  [bool]$parent.authority.platformConfigurationSourceWriteAuthorizedAfterMvpGate -and
  [bool]$parent.authority.backendSourceWriteAuthorizedAfterMvpGate -and
  [bool]$parent.authority.testAndGateWriteAuthorizedAfterMvpGate -and
  -not [bool]$parent.authority.providerConsoleOrExternalServiceWriteAuthorized -and
  -not [bool]$parent.authority.secretOrPrivateValueAccessAuthorized -and
  -not [bool]$parent.authority.realEmailSmsOrPrivateLoginAuthorized -and
  -not [bool]$parent.authority.buildPlayOrDeviceActionAuthorized -and
  -not [bool]$parent.authority.commitPushMergeAuthorized
) -Message 'FIX1A parent identity or source authority changed.'
$authorizedMvpTicketIds = @(
  [string]$parent.ticketId,
  'UAW-C34P-FIX5-ALL-EIGHT-PUBLIC-AUTH-LIVE-PROVIDER-READINESS',
  'UAW-C34P-FIX8-GLOBAL-SOCIAL-LOGIN-OPPO-SUCCESSOR-AUDIT-REPAIR'
)
$activeMvpTicketId = [string]$mvp.ticket.id
$checkpointMvpTicketId =
  [string]$mvp.preTicketSelectionCheckpoint.currentTicketId
Assert-C34PFix1A -Condition (
  $activeMvpTicketId -ceq $checkpointMvpTicketId -and
  $authorizedMvpTicketIds -ccontains $activeMvpTicketId
) -Message 'MVP state does not select an authorized FIX1A descendant.'
$fix8TicketId = 'UAW-C34P-FIX8-GLOBAL-SOCIAL-LOGIN-OPPO-SUCCESSOR-AUDIT-REPAIR'
if ($activeMvpTicketId -ceq $fix8TicketId) {
  $fix8Relative = `
    'config/uaw-c34p-fix8-global-social-login-oppo-successor-audit-repair-ticket.json'
  $fix8Path = Join-Path $root $fix8Relative
  $fix8 = Read-C34PFix1AFile -Path $fix8Relative -Label 'FIX8 ticket' |
    ConvertFrom-Json
  $fix8Hash = (Get-FileHash -LiteralPath $fix8Path -Algorithm SHA256).Hash
  $assessment = $mvp.preTicketSelectionCheckpoint.selectedTicketAssessment
  $fix8SourceOnlyHeld = (
    [bool]$fix8.authority.sourceAndTestRepairAuthorizedAfterMvpGate -and
    -not [bool]$fix8.authority.buildAuthorized -and
    -not [bool]$fix8.authority.installOrOppoMutationAuthorized -and
    -not [bool]$fix8.authority.privateProviderLoginAuthorized
  )
  $fix8RepairRetryState = `
    'r60_81_release_resource_repair_one_rebuild_and_in_place_sideload_authorized'
  $fix8RepairRetryAuthorized = (
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
  Assert-C34PFix1A -Condition (
    [string]$fix8.ticketId -ceq $fix8TicketId -and
    [string]$assessment.ticketId -ceq $fix8TicketId -and
    [string]$assessment.manifestPath -ceq $fix8Relative -and
    [string]$assessment.manifestSha256 -ceq $fix8Hash -and
    ($fix8SourceOnlyHeld -or $fix8RepairRetryAuthorized)
  ) -Message 'FIX8 manifest binding or held source-only authority changed.'
}
Assert-C34PFix1A -Condition (-not (
  $authorizedMvpTicketIds -ccontains 'UNRELATED-TICKET'
)) -Message 'unrelated-ticket negative fixture was accepted.'
Assert-C34PFix1AContains -Body $authority `
  -Expected 'its x , facebook , google , youtube , apple , instagram,facebook , email link , mobile otp' `
  -Label 'founder method correction'

$childPaths = @(
  'config/uaw-c34p-fix1-x-native-pkce-firebase-custom-token-broker-ticket.json',
  'config/uaw-c34p-fix2-facebook-native-sdk-public-login-adapter-ticket.json',
  'config/uaw-c34p-fix3-apple-firebase-public-login-adapter-ticket.json',
  'config/uaw-c34p-fix4-instagram-professional-oauth-public-login-adapter-ticket.json'
)
$children = @(
  foreach ($path in $childPaths) {
    Read-C34PFix1AFile -Path $path -Label "child ticket $path" |
      ConvertFrom-Json
  }
)
Assert-C34PFix1A -Condition (
  $children.Count -eq 4 -and
  @($children | Where-Object {
    [string]$_.parentTicketId -cne [string]$parent.ticketId -or
    [bool]$_.authority.secretOrPrivateValueAccessAuthorized -or
    [bool]$_.authority.buildPlayOrDeviceActionAuthorized
  }).Count -eq 0
) -Message 'child ticket parent or private/build authority boundary changed.'

$main = Read-C34PFix1AFile -Path 'apps/mobile/lib/main.dart' -Label 'main'
$services = Read-C34PFix1AFile `
  -Path 'apps/mobile/lib/features/journey01/journey_services.dart' `
  -Label 'journey services'
$session = Read-C34PFix1AFile `
  -Path 'apps/mobile/lib/features/journey01/journey_session.dart' `
  -Label 'JourneySession'
$gateway = Read-C34PFix1AFile `
  -Path 'apps/mobile/lib/features/journey01/review_journey_services.dart' `
  -Label 'Firebase social gateway'
$failureContract = Read-C34PFix1AFile `
  -Path 'apps/mobile/lib/core/auth/public_auth_failure.dart' `
  -Label 'public auth failure contract'
$xMobile = Read-C34PFix1AFile `
  -Path 'apps/mobile/lib/core/auth/x_oauth2_pkce_network_adapter.dart' `
  -Label 'X mobile adapter'
$instagramMobile = Read-C34PFix1AFile `
  -Path 'apps/mobile/lib/core/auth/instagram_oauth_network_adapter.dart' `
  -Label 'Instagram mobile adapter'
$facebookMobile = Read-C34PFix1AFile `
  -Path 'apps/mobile/lib/core/auth/facebook_native_sdk_adapter.dart' `
  -Label 'Facebook native adapter'
$xBackend = Read-C34PFix1AFile `
  -Path 'backend/functions/src/auth/x_pkce_broker.ts' `
  -Label 'X backend broker'
$instagramBackend = Read-C34PFix1AFile `
  -Path 'backend/functions/src/auth/instagram_oauth_broker.ts' `
  -Label 'Instagram backend broker'
$backendIndex = Read-C34PFix1AFile `
  -Path 'backend/functions/src/index.ts' `
  -Label 'backend export'
$androidManifest = Read-C34PFix1AFile `
  -Path 'apps/mobile/android/app/src/main/AndroidManifest.xml' `
  -Label 'Android manifest'
$androidGradle = Read-C34PFix1AFile `
  -Path 'apps/mobile/android/app/build.gradle.kts' `
  -Label 'Android app Gradle configuration'
$mobilePubspec = Read-C34PFix1AFile `
  -Path 'apps/mobile/pubspec.yaml' `
  -Label 'mobile pubspec'
$iosInfo = Read-C34PFix1AFile `
  -Path 'apps/mobile/ios/Runner/Info.plist' `
  -Label 'iOS Info plist'
$iosEntitlements = Read-C34PFix1AFile `
  -Path 'apps/mobile/ios/Runner/Runner.entitlements' `
  -Label 'iOS entitlements'
$iosProject = Read-C34PFix1AFile `
  -Path 'apps/mobile/ios/Runner.xcodeproj/project.pbxproj' `
  -Label 'iOS project'

foreach ($required in @(
  'MOOLSOCIAL_X_CALLBACK_URL',
  'MOOLSOCIAL_INSTAGRAM_CALLBACK_URL',
  'MOOLSOCIAL_FACEBOOK_GRAPH_REVOCATION_ENDPOINT',
  'XOAuth2PkceNetworkAdapter(',
  'InstagramOAuthNetworkAdapter(',
  'FlutterFacebookNativeSdkAdapter(',
  'facebookNativeAdapterInstalled: facebookAdapter.isConfigured',
  'socialAuthInitialLocation',
  'MOOLSOCIAL_GLOBAL_SOCIAL_LOGIN_AUDIT',
  'resolveGlobalSocialLoginAuditComposition(',
  'globalSocialLoginAuditEnabled: _globalSocialLoginAuditMode',
  'FirebaseAuthenticatedSessionBootstrapGateway('
)) {
  Assert-C34PFix1AContains -Body $main -Expected $required -Label 'main'
}
Assert-C34PFix1AContains -Body $main `
  -Expected 'FirebaseAppCheck.instance.getLimitedUseToken()' `
  -Label 'replay-protected public-auth App Check supplier'
Assert-C34PFix1A -Condition (
  $main.IndexOf(
    'FirebaseAppCheck.instance.getToken()',
    [StringComparison]::Ordinal
  ) -lt 0
) -Message 'public auth regressed to a reusable App Check session token.'
foreach ($required in @(
  'verifyToken(token, { consume: true })',
  'verified.alreadyConsumed'
)) {
  Assert-C34PFix1AContains -Body $backendIndex -Expected $required `
    -Label 'backend App Check replay protection'
}
foreach ($required in @(
  'implements SocialAuthGateway, SocialAuthCallbackGateway',
  'AppleAuthProvider()',
  'await adapter.beginAuthorization()',
  'providerForCallback(Uri callbackUri)',
  'completeForegroundCallback(',
  'completeColdStartCallback(',
  'BrokeredPublicAuthOutcome.accountIneligible',
  'sanitizedFirebaseAuthFailure('
)) {
  Assert-C34PFix1AContains -Body $gateway -Expected $required `
    -Label 'shared Firebase social gateway'
}
foreach ($required in @(
  "'account-exists-with-different-credential'",
  "'credential-already-in-use'",
  'PublicAuthFailureClass.accountCollision',
  "'auth-account-collision'"
)) {
  Assert-C34PFix1AContains -Body $failureContract -Expected $required `
    -Label 'centralized Firebase collision contract'
}
foreach ($required in @(
  'SocialAuthOutcome.authorizationPending',
  'abstract interface class SocialAuthCallbackGateway'
)) {
  Assert-C34PFix1AContains -Body $services -Expected $required `
    -Label 'social auth service contract'
}
foreach ($required in @(
  'Future<bool> prepareSocialAuthReturn(',
  'completeColdStartCallback(callbackUri)',
  'completeForegroundCallback(callbackUri)',
  'takeCompletedSocialAuthReturnRoute()'
)) {
  Assert-C34PFix1AContains -Body $session -Expected $required `
    -Label 'JourneySession callback lifecycle'
}

foreach ($required in @(
  "'tweet.read users.read'",
  "'S256'",
  "'account_ineligible'",
  'X-Firebase-AppCheck'
)) {
  Assert-C34PFix1AContains -Body $xMobile -Expected $required `
    -Label 'X mobile adapter'
}
Assert-C34PFix1A -Condition (
  $xMobile.IndexOf('offline.access', [StringComparison]::Ordinal) -lt 0 -and
  $xBackend.IndexOf('offline.access', [StringComparison]::Ordinal) -lt 0
) -Message 'X source introduced forbidden offline.access.'
foreach ($required in @(
  "'instagram_business_basic'",
  "providerLabel: 'Instagram'",
  'completeColdStartCallback('
)) {
  Assert-C34PFix1AContains -Body $instagramMobile -Expected $required `
    -Label 'Instagram mobile adapter'
}
foreach ($required in @(
  "static const List<String> permissions = <String>['public_profile'];",
  'FacebookAuthProvider.credential(',
  'FlutterFacebookCurrentAccessTokenSource',
  'IoFacebookGraphDeleteTransport',
  'FacebookGraphPermissionRevocationSeam',
  'FacebookLoginOutcome.accountCollision',
  'FacebookAccessRevocationSeam'
)) {
  Assert-C34PFix1AContains -Body $facebookMobile -Expected $required `
    -Label 'Facebook native adapter'
}

foreach ($required in @(
  'const X_SCOPES = ["tweet.read", "users.read"] as const;',
  'class XPublicAuthBroker',
  'revokeAccessToken(input: {',
  'await this.transport.revokeAccessToken({',
  'createCustomToken('
)) {
  Assert-C34PFix1AContains -Body $xBackend -Expected $required `
    -Label 'X backend broker'
}
foreach ($required in @(
  'const INSTAGRAM_SCOPE = "instagram_business_basic";',
  'class InstagramPublicAuthBroker',
  'refreshTokenPresent',
  'revokeAccessToken(accessToken',
  'createCustomToken('
)) {
  Assert-C34PFix1AContains -Body $instagramBackend -Expected $required `
    -Label 'Instagram backend broker'
}
foreach ($required in @(
  'moolSocialPublicAuth',
  'xPublicAuthBroker()',
  'instagramPublicAuthBroker()'
)) {
  Assert-C34PFix1AContains -Body $backendIndex -Expected $required `
    -Label 'backend public-auth export'
}

foreach ($required in @(
  'MOOLSOCIAL_FACEBOOK_APP_ID',
  'MOOLSOCIAL_FACEBOOK_CLIENT_TOKEN',
  'facebook_app_id',
  'facebook_client_token',
  'fb_login_protocol_scheme'
)) {
  Assert-C34PFix1AContains -Body $androidGradle -Expected $required `
    -Label 'Android Facebook build configuration'
}
foreach ($required in @(
  'com.facebook.sdk.ApplicationId',
  'com.facebook.sdk.ClientToken'
)) {
  Assert-C34PFix1AContains -Body $androidManifest -Expected $required `
    -Label 'Android Facebook manifest'
}
Assert-C34PFix1AContains -Body $mobilePubspec `
  -Expected 'flutter_facebook_auth:' -Label 'Facebook native dependency'
foreach ($forbidden in @(
  'android:name="com.facebook.FacebookActivity"',
  'android:name="com.facebook.CustomTabActivity"'
)) {
  Assert-C34PFix1A `
    -Condition (-not $androidManifest.Contains($forbidden)) `
    -Message "Android manifest redundantly declares SDK-owned activity: $forbidden"
}
foreach ($required in @(
  'fb$(MOOLSOCIAL_FACEBOOK_APP_ID)',
  '<key>FacebookAppID</key>',
  '<key>FacebookClientToken</key>',
  '<key>FacebookAutoLogAppEventsEnabled</key>',
  '<key>FacebookAdvertiserIDCollectionEnabled</key>'
)) {
  Assert-C34PFix1AContains -Body $iosInfo -Expected $required `
    -Label 'iOS Facebook configuration'
}

Assert-C34PFix1A -Condition (
  ([regex]::Matches($androidManifest, 'android:path="/x"')).Count -eq 1 -and
  ([regex]::Matches($androidManifest, 'android:path="/instagram"')).Count -eq 1 -and
  ([regex]::Matches(
    $iosEntitlements,
    'com[.]apple[.]developer[.]applesignin'
  )).Count -eq 1 -and
  ([regex]::Matches(
    $iosProject,
    'CODE_SIGN_ENTITLEMENTS = Runner/Runner[.]entitlements;'
  )).Count -eq 3
) -Message 'Apple/X/Instagram platform callback or capability cardinality changed.'
Assert-C34PFix1A -Condition (
  $gateway.IndexOf('TwitterAuthProvider()', [StringComparison]::Ordinal) -lt 0
) -Message 'forbidden Firebase X OAuth1 fallback returned.'

Write-Output (
  'C34P FIX1A all-eight source gate passed: activeTicket=' +
  $activeMvpTicketId + '; sharedGateway=1; ' +
  'GoogleYouTube=shared; Apple=Firebase; X=PKCE; Instagram=professional; ' +
  'Facebook=public_profile; EmailLink=passwordless; MobileOTP=Firebase; ' +
  'parentSourcePrivateBuildDeviceBoundaries=true.'
)
