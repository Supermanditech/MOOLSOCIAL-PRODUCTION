import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart' as facebook;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app/moolsocial_app.dart';
import 'core/auth/facebook_native_sdk_adapter.dart';
import 'core/auth/instagram_oauth_network_adapter.dart';
import 'core/auth/public_auth_runtime_configuration.dart';
import 'core/auth/x_oauth2_pkce_network_adapter.dart';
import 'core/config/release_runtime_configuration.dart';
import 'core/config/email_link_runtime_configuration.dart';
import 'core/navigation/youtube_connect_return_route.dart';
import 'core/platform/mool_system_ui_viewport.dart';
import 'core/youtube/youtube_private_dev_app_check.dart';
import 'core/youtube/youtube_embedded_player_contract.dart';
import 'core/youtube/youtube_private_dev_client.dart';
import 'features/chat/chat_services.dart';
import 'features/chat/chat_session.dart';
import 'features/journey01/journey_services.dart';
import 'features/journey01/journey_session.dart';
import 'features/journey01/review_journey_services.dart';
import 'features/retailer/retailer_session.dart';
import 'features/shared/social_content_gateway.dart';
import 'features/shared/shared_session.dart';
import 'features/shared/social_create_draft_media_store.dart';
import 'features/shared/social_create_draft_repository.dart';
import 'features/shared/youtube_public_catalogue_repository.dart';
import 'features/shared/youtube_public_search_state_repository.dart';
import 'features/shared/youtube_public_short_state_repository.dart';
import 'features/shared/youtube_public_watch_state_repository.dart';
import 'features/work/work_session.dart';
import 'ui_v2/social/social_v2_youtube_public_runtime.dart';

const _localFirebaseOptions = FirebaseOptions(
  apiKey: 'demo-moolsocial-local-key',
  appId: '1:100000000001:android:moolsocial-local',
  messagingSenderId: '100000000001',
  projectId: 'demo-moolsocial-local',
);
const _releaseFirstFrameTimeout = Duration(seconds: 5);
const _releasePlatformStageTimeout = Duration(seconds: 15);
const _youtubeCatalogueCacheHydrationTimeout = Duration(seconds: 2);

const _useEmulators = bool.fromEnvironment(
  'MOOLSOCIAL_USE_EMULATORS',
  defaultValue: kDebugMode,
);
const _deviceReviewMode = bool.fromEnvironment('MOOLSOCIAL_DEVICE_REVIEW');
const _uiReviewOnlyMode = bool.fromEnvironment('MOOLSOCIAL_UI_REVIEW_ONLY');
const _youtubePublicReviewMode = bool.fromEnvironment(
  'MOOLSOCIAL_YOUTUBE_PUBLIC_REVIEW',
);
const _candidateId = String.fromEnvironment(
  'MOOLSOCIAL_CANDIDATE_ID',
  defaultValue: 'unidentified',
);

const _firebaseApiKey = String.fromEnvironment('MOOLSOCIAL_FIREBASE_API_KEY');
const _firebaseAppId = String.fromEnvironment('MOOLSOCIAL_FIREBASE_APP_ID');
const _firebaseMessagingSenderId = String.fromEnvironment(
  'MOOLSOCIAL_FIREBASE_MESSAGING_SENDER_ID',
);
const _firebaseProjectId = String.fromEnvironment(
  'MOOLSOCIAL_FIREBASE_PROJECT_ID',
);
const _authApiBaseUrl = String.fromEnvironment('MOOLSOCIAL_AUTH_API_BASE_URL');
const _xCallbackUrl = String.fromEnvironment('MOOLSOCIAL_X_CALLBACK_URL');
const _xAuthorizationEndpoint = String.fromEnvironment(
  'MOOLSOCIAL_X_AUTHORIZATION_ENDPOINT',
  defaultValue: 'https://x.com/i/oauth2/authorize',
);
const _instagramCallbackUrl = String.fromEnvironment(
  'MOOLSOCIAL_INSTAGRAM_CALLBACK_URL',
);
const _instagramAuthorizationEndpoint = String.fromEnvironment(
  'MOOLSOCIAL_INSTAGRAM_AUTHORIZATION_ENDPOINT',
  defaultValue: 'https://www.instagram.com/oauth/authorize',
);
const _emailLinkContinueUrl = String.fromEnvironment(
  'MOOLSOCIAL_EMAIL_LINK_CONTINUE_URL',
);
const _emailLinkDomain = String.fromEnvironment('MOOLSOCIAL_EMAIL_LINK_DOMAIN');
const _phoneOtpEnabled = bool.fromEnvironment('MOOLSOCIAL_PHONE_OTP_ENABLED');
const _googleProviderQualified = bool.fromEnvironment(
  'MOOLSOCIAL_GOOGLE_PROVIDER_QUALIFIED',
);
const _googlePlaySigningQualified = bool.fromEnvironment(
  'MOOLSOCIAL_GOOGLE_PLAY_SIGNING_QUALIFIED',
);
const _sideloadPreflightEnabled = bool.fromEnvironment(
  'MOOLSOCIAL_SIDELOAD_PREFLIGHT_ENABLED',
);
const _globalSocialLoginAuditMode = bool.fromEnvironment(
  'MOOLSOCIAL_GLOBAL_SOCIAL_LOGIN_AUDIT',
);
const _googleOnlyForensicMode = bool.fromEnvironment(
  'MOOLSOCIAL_GOOGLE_ONLY_FORENSIC_MODE',
);
const _googleSideloadSigningQualified = bool.fromEnvironment(
  'MOOLSOCIAL_GOOGLE_SIDELOAD_SIGNING_QUALIFIED',
);
const _mobileOtpAttestationQualified = bool.fromEnvironment(
  'MOOLSOCIAL_MOBILE_OTP_ATTESTATION_QUALIFIED',
);
const _appleEnabled = bool.fromEnvironment('MOOLSOCIAL_APPLE_ENABLED');
const _appleProviderQualified = bool.fromEnvironment(
  'MOOLSOCIAL_APPLE_PROVIDER_QUALIFIED',
);
const _applePlatformConfigurationQualified = bool.fromEnvironment(
  'MOOLSOCIAL_APPLE_PLATFORM_CONFIGURATION_QUALIFIED',
);
const _appleRevocationQualified = bool.fromEnvironment(
  'MOOLSOCIAL_APPLE_REVOCATION_QUALIFIED',
);
const _xPublicClientEnabled = bool.fromEnvironment(
  'MOOLSOCIAL_X_PUBLIC_CLIENT_ENABLED',
);
const _xClientIdConfigured = bool.fromEnvironment(
  'MOOLSOCIAL_X_CLIENT_ID_CONFIGURED',
);
const _xExactRedirectQualified = bool.fromEnvironment(
  'MOOLSOCIAL_X_EXACT_REDIRECT_QUALIFIED',
);
const _xFirebaseBrokerQualified = bool.fromEnvironment(
  'MOOLSOCIAL_X_FIREBASE_BROKER_QUALIFIED',
);
const _instagramEnabled = bool.fromEnvironment('MOOLSOCIAL_INSTAGRAM_ENABLED');
const _instagramProfessionalLoginQualified = bool.fromEnvironment(
  'MOOLSOCIAL_INSTAGRAM_PROFESSIONAL_LOGIN_QUALIFIED',
);
const _instagramExactRedirectQualified = bool.fromEnvironment(
  'MOOLSOCIAL_INSTAGRAM_EXACT_REDIRECT_QUALIFIED',
);
const _instagramBrokerQualified = bool.fromEnvironment(
  'MOOLSOCIAL_INSTAGRAM_FIREBASE_BROKER_QUALIFIED',
);
const _instagramRevocationQualified = bool.fromEnvironment(
  'MOOLSOCIAL_INSTAGRAM_REVOCATION_QUALIFIED',
);
const _facebookEnabled = bool.fromEnvironment('MOOLSOCIAL_FACEBOOK_ENABLED');
const _facebookProviderQualified = bool.fromEnvironment(
  'MOOLSOCIAL_FACEBOOK_PROVIDER_QUALIFIED',
);
const _facebookAndroidConfigurationQualified = bool.fromEnvironment(
  'MOOLSOCIAL_FACEBOOK_ANDROID_CONFIGURATION_QUALIFIED',
);
const _facebookRevocationQualified = bool.fromEnvironment(
  'MOOLSOCIAL_FACEBOOK_REVOCATION_QUALIFIED',
);
const _facebookDataDeletionQualified = bool.fromEnvironment(
  'MOOLSOCIAL_FACEBOOK_DATA_DELETION_QUALIFIED',
);
const _facebookGraphRevocationEndpoint = String.fromEnvironment(
  'MOOLSOCIAL_FACEBOOK_GRAPH_REVOCATION_ENDPOINT',
);
const _googleServerClientId = String.fromEnvironment(
  'MOOLSOCIAL_GOOGLE_SERVER_CLIENT_ID',
);
const _releaseRuntimeConfiguration = ReleaseRuntimeConfiguration(
  useEmulators: _useEmulators,
  firebaseApiKey: _firebaseApiKey,
  firebaseAppId: _firebaseAppId,
  firebaseMessagingSenderId: _firebaseMessagingSenderId,
  firebaseProjectId: _firebaseProjectId,
  googleServerClientId: _googleServerClientId,
);
Set<SocialAuthProvider> _productionSocialIdentityProviders(
  PublicAuthRuntimeConfiguration configuration, {
  bool googleOnlyForensicMode = false,
}) {
  return <SocialAuthProvider>{
    if (configuration.googleAndYoutubeAvailable) SocialAuthProvider.google,
    if (!googleOnlyForensicMode && configuration.googleAndYoutubeAvailable)
      SocialAuthProvider.youtube,
  };
}

Uri? _qualifiedHttpsUri(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment ||
      uri.pathSegments.any((segment) => segment == '.' || segment == '..')) {
    return null;
  }
  return uri;
}

Uri? _qualifiedPublicAuthCallbackUri(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null ||
      !uri.isAbsolute ||
      (uri.scheme != 'https' && uri.scheme != 'moolsocial') ||
      (uri.host.isEmpty && uri.path.isEmpty) ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment) {
    return null;
  }
  return uri;
}

Future<String> _publicAuthAppCheckToken() async {
  try {
    final token = await FirebaseAppCheck.instance.getLimitedUseToken().timeout(
      const Duration(seconds: 15),
    );
    if (token.trim().isEmpty) {
      throw const PublicAuthDependencyException(
        PublicAuthDependencyFailure.appCheckConfiguration,
      );
    }
    return token;
  } on PublicAuthDependencyException {
    rethrow;
  } on TimeoutException {
    throw const PublicAuthDependencyException(
      PublicAuthDependencyFailure.appCheckTimeout,
    );
  } on FirebaseException catch (error) {
    final failure = error.code.toLowerCase().contains('network')
        ? PublicAuthDependencyFailure.appCheckNetwork
        : PublicAuthDependencyFailure.appCheckConfiguration;
    throw PublicAuthDependencyException(failure);
  } on Object {
    throw const PublicAuthDependencyException(
      PublicAuthDependencyFailure.appCheckConfiguration,
    );
  }
}

Future<PublicAuthHttpResponse> _postPublicAuthJson(
  Uri uri, {
  required Map<String, String> headers,
  required Map<String, Object?> body,
}) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
  try {
    return await (() async {
      final request = await client
          .postUrl(uri)
          .timeout(const Duration(seconds: 15));
      headers.forEach(request.headers.set);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
      final response = await request.close().timeout(
        const Duration(seconds: 50),
      );
      final bytes = <int>[];
      await for (final chunk in response) {
        if (bytes.length + chunk.length > 65536) {
          throw const PublicAuthDependencyException(
            PublicAuthDependencyFailure.provider,
          );
        }
        bytes.addAll(chunk);
      }
      return PublicAuthHttpResponse(
        statusCode: response.statusCode,
        body: utf8.decode(bytes),
      );
    })().timeout(const Duration(seconds: 60));
  } on PublicAuthDependencyException {
    rethrow;
  } on TimeoutException {
    throw const PublicAuthDependencyException(
      PublicAuthDependencyFailure.timeout,
    );
  } on Object {
    throw const PublicAuthDependencyException(
      PublicAuthDependencyFailure.network,
    );
  } finally {
    client.close(force: true);
  }
}

Future<bool> _launchPublicAuthUrl(Uri uri) async {
  try {
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    ).timeout(const Duration(seconds: 20));
    if (!launched) {
      throw const PublicAuthDependencyException(
        PublicAuthDependencyFailure.browserUnavailable,
      );
    }
    return true;
  } on PublicAuthDependencyException {
    rethrow;
  } on TimeoutException {
    throw const PublicAuthDependencyException(
      PublicAuthDependencyFailure.browserTimeout,
    );
  } on Object {
    throw const PublicAuthDependencyException(
      PublicAuthDependencyFailure.browserUnavailable,
    );
  }
}

Future<String?> _signInWithBrokerCustomToken(String customToken) async {
  try {
    return (await FirebaseAuth.instance
            .signInWithCustomToken(customToken)
            .timeout(const Duration(seconds: 30)))
        .user
        ?.uid;
  } on TimeoutException {
    throw const PublicAuthDependencyException(
      PublicAuthDependencyFailure.firebaseTimeout,
    );
  } on FirebaseAuthException catch (error) {
    if (error.code == 'network-request-failed') {
      throw const PublicAuthDependencyException(
        PublicAuthDependencyFailure.firebaseNetwork,
      );
    }
    throw const PublicAuthDependencyException(
      PublicAuthDependencyFailure.firebaseCredential,
    );
  } on Object {
    throw const PublicAuthDependencyException(
      PublicAuthDependencyFailure.firebaseCredential,
    );
  }
}

void _recordReleaseBootstrapStage(String stage, String state) {
  if (kDebugMode || _deviceReviewMode) {
    debugPrint('MOOLSOCIAL_BOOTSTRAP stage=$stage state=$state');
  }
}

void _showReleaseBootstrapFailure(String stage) {
  _recordReleaseBootstrapStage(stage, 'failed');
  runApp(const ReleaseConfigurationFailureApp());
}

void _runUiReviewOnlyApp() {
  final session = JourneySession(
    store: MemoryJourneyStore(
      snapshot: const JourneySnapshot(
        languageCode: 'en',
        areaMode: 'current',
        areaLabel: 'Jodhpur, Rajasthan',
        currentAreaLabel: 'Jodhpur, Rajasthan',
        setupComplete: true,
        pendingRoute: '/app/buy',
        lastReadyRoute: '/app/buy',
      ),
    ),
    allowGuestReady: true,
  );
  runApp(
    MoolSocialApp(
      session: session,
      chatSession: ChatSession(),
      sharedSession: SharedSession(
        socialContentGateway: UiReviewSocialContentGateway(),
      ),
      disposeSession: true,
      disposeChatSession: true,
      disposeSharedSession: true,
      uiReviewOnly: true,
      initialLocation: '/app/buy',
    ),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureMoolSystemUiViewport();
  if (kDebugMode || _deviceReviewMode) {
    debugPrint(
      'MOOLSOCIAL_CANDIDATE '
      'id=$_candidateId '
      'requiredSetupVersion=$approvedSetupExperienceVersion '
      'youtubePublicReview=$_youtubePublicReviewMode '
      'googleOnlyForensic=$_googleOnlyForensicMode',
    );
  }
  if (!_releaseRuntimeConfiguration.isComplete) {
    _showReleaseBootstrapFailure('release_configuration');
    return;
  }
  if (!_runtimeModeIsValid()) {
    _showReleaseBootstrapFailure('runtime_mode');
    return;
  }
  _recordReleaseBootstrapStage('first_flutter_frame', 'begin');
  runApp(const ReleaseBootstrapApp());
  try {
    await WidgetsBinding.instance.endOfFrame.timeout(_releaseFirstFrameTimeout);
  } on Object {
    _showReleaseBootstrapFailure('first_flutter_frame');
    return;
  }
  _recordReleaseBootstrapStage('first_flutter_frame', 'passed');
  if (_uiReviewOnlyMode) {
    _recordReleaseBootstrapStage('ui_review_runtime', 'begin');
    _runUiReviewOnlyApp();
    _recordReleaseBootstrapStage('ui_review_runtime', 'passed');
    return;
  }
  final firebaseOptions = _firebaseOptions();
  _recordReleaseBootstrapStage('firebase_initialize', 'begin');
  try {
    if (shouldUseNativeAndroidFirebaseConfiguration(
      isAndroid: Platform.isAndroid,
      useEmulators: _useEmulators,
    )) {
      await Firebase.initializeApp().timeout(_releasePlatformStageTimeout);
    } else {
      await Firebase.initializeApp(
        options: firebaseOptions,
      ).timeout(_releasePlatformStageTimeout);
    }
  } on Object {
    _showReleaseBootstrapFailure('firebase_initialize');
    return;
  }
  _recordReleaseBootstrapStage('firebase_initialize', 'passed');
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  _recordReleaseBootstrapStage('app_check_activation', 'begin');
  try {
    await activateYouTubePrivateDevAppCheckIfEnabled(
      useEmulators: _useEmulators,
      firebaseProjectId: firebaseOptions.projectId,
      globalSocialLoginAuditEnabled:
          _globalSocialLoginAuditMode && !_googleOnlyForensicMode,
    ).timeout(_releasePlatformStageTimeout);
  } on Object {
    _showReleaseBootstrapFailure('app_check_activation');
    return;
  }
  _recordReleaseBootstrapStage('app_check_activation', 'passed');

  const emulatorHost = String.fromEnvironment(
    'MOOLSOCIAL_EMULATOR_HOST',
    defaultValue: '127.0.0.1',
  );
  const emulatorFallbackHost = String.fromEnvironment(
    'MOOLSOCIAL_EMULATOR_FALLBACK_HOST',
  );
  if (_useEmulators) {
    _recordReleaseBootstrapStage('auth_emulator', 'begin');
    try {
      await FirebaseAuth.instance
          .useAuthEmulator(emulatorHost, 9099)
          .timeout(_releasePlatformStageTimeout);
    } on Object {
      _showReleaseBootstrapFailure('auth_emulator');
      return;
    }
    _recordReleaseBootstrapStage('auth_emulator', 'passed');
  }

  late final SharedPreferences preferences;
  _recordReleaseBootstrapStage('shared_preferences', 'begin');
  try {
    preferences = await SharedPreferences.getInstance().timeout(
      _releasePlatformStageTimeout,
    );
  } on Object {
    _showReleaseBootstrapFailure('shared_preferences');
    return;
  }
  _recordReleaseBootstrapStage('shared_preferences', 'passed');
  _recordReleaseBootstrapStage('youtube_catalogue_cache', 'begin');
  try {
    final hydration = await screen04YouTubeCatalogueSnapshots
        .configureDurability(
          DurableYouTubePublicCatalogueRepository(
            persistence: SharedPreferencesAsyncYouTubePublicCatalogueStore(
              SharedPreferencesAsync(),
            ),
            regionCode: screen04YouTubeRegionCode,
          ),
        )
        .timeout(_youtubeCatalogueCacheHydrationTimeout);
    _recordReleaseBootstrapStage(
      'youtube_catalogue_cache',
      hydration.degraded ? 'degraded' : 'passed',
    );
  } on Object {
    _recordReleaseBootstrapStage('youtube_catalogue_cache', 'degraded');
  }
  final platformRouteName =
      WidgetsBinding.instance.platformDispatcher.defaultRouteName;
  final youtubeInitialLocation = youtubeConnectReturnLocation(
    platformRouteName,
  );
  final emailLinkRuntimeAvailable = isQualifiedEmailLinkRuntimeConfiguration(
    continueUrl: _emailLinkContinueUrl,
    linkDomain: _emailLinkDomain,
  );
  final authApiBaseUri = _qualifiedHttpsUri(_authApiBaseUrl);
  final xCallbackUri = _qualifiedPublicAuthCallbackUri(_xCallbackUrl);
  final xAuthorizationUri = _qualifiedHttpsUri(_xAuthorizationEndpoint);
  final instagramCallbackUri = _qualifiedPublicAuthCallbackUri(
    _instagramCallbackUrl,
  );
  final instagramAuthorizationUri = _qualifiedHttpsUri(
    _instagramAuthorizationEndpoint,
  );
  final brokerCallbacksAreDistinct =
      xCallbackUri == null ||
      instagramCallbackUri == null ||
      xCallbackUri.toString() != instagramCallbackUri.toString();
  final XOAuth2PkceNetworkAdapter? xAdapter =
      authApiBaseUri != null &&
          xCallbackUri != null &&
          xAuthorizationUri != null &&
          brokerCallbacksAreDistinct
      ? XOAuth2PkceNetworkAdapter(
          authApiBaseUri: authApiBaseUri,
          callbackUri: xCallbackUri,
          authorizationEndpoint: xAuthorizationUri,
          appCheckTokenSupplier: _publicAuthAppCheckToken,
          postTransport: _postPublicAuthJson,
          externalUrlLauncher: _launchPublicAuthUrl,
          firebaseCustomTokenSignIn: _signInWithBrokerCustomToken,
        )
      : null;
  final InstagramOAuthNetworkAdapter? instagramAdapter =
      authApiBaseUri != null &&
          instagramCallbackUri != null &&
          instagramAuthorizationUri != null &&
          brokerCallbacksAreDistinct
      ? InstagramOAuthNetworkAdapter(
          authApiBaseUri: authApiBaseUri,
          callbackUri: instagramCallbackUri,
          authorizationEndpoint: instagramAuthorizationUri,
          appCheckTokenSupplier: _publicAuthAppCheckToken,
          postTransport: _postPublicAuthJson,
          externalUrlLauncher: _launchPublicAuthUrl,
          firebaseCustomTokenSignIn: _signInWithBrokerCustomToken,
        )
      : null;
  final facebookAuth = facebook.FacebookAuth.instance;
  final facebookRevocationUri =
      Uri.tryParse(_facebookGraphRevocationEndpoint.trim()) ?? Uri();
  final facebookPlatformReady =
      _facebookEnabled &&
      _facebookProviderQualified &&
      _facebookAndroidConfigurationQualified &&
      _facebookRevocationQualified &&
      _facebookDataDeletionQualified;
  final facebookAccessTokenSource = FlutterFacebookCurrentAccessTokenSource(
    facebookAuth: facebookAuth,
    nativeSdkReady: facebookPlatformReady,
  );
  final facebookRevocationSeam = FacebookGraphPermissionRevocationSeam(
    endpoint: facebookRevocationUri,
    accessTokenSource: facebookAccessTokenSource,
    deleteTransport: IoFacebookGraphDeleteTransport(),
  );
  final facebookAdapter = FlutterFacebookNativeSdkAdapter(
    nativeLoginClient: FlutterFacebookNativeLoginClient(
      facebookAuth: facebookAuth,
      nativeSdkReady: facebookPlatformReady,
    ),
    firebaseCredentialSeam: FirebaseFacebookCredentialSeam(
      firebaseAuth: FirebaseAuth.instance,
      firebaseReady: facebookPlatformReady,
    ),
    accessRevocationSeam: facebookRevocationSeam,
    platformConfigurationReady: facebookPlatformReady,
  );
  final publicAuthRuntimeConfiguration = PublicAuthRuntimeConfiguration(
    googleServerClientConfigured: _googleServerClientId.trim().isNotEmpty,
    googleProviderQualified: _googleProviderQualified,
    playSigningQualified: _googlePlaySigningQualified,
    sideloadPreflightEnabled: _sideloadPreflightEnabled,
    googleSideloadSigningQualified: _googleSideloadSigningQualified,
    emailLinkQualified: emailLinkRuntimeAvailable,
    mobileOtpEnabled: _phoneOtpEnabled,
    mobileAttestationQualified: _mobileOtpAttestationQualified,
    appleEnabled: _appleEnabled,
    appleProviderQualified: _appleProviderQualified,
    applePlatformConfigurationQualified: _applePlatformConfigurationQualified,
    appleRevocationQualified: _appleRevocationQualified,
    xPublicClientEnabled: _xPublicClientEnabled,
    xClientIdConfigured: _xClientIdConfigured,
    xExactRedirectQualified: _xExactRedirectQualified,
    xPkceAdapterInstalled: xAdapter != null,
    xFirebaseBrokerQualified: _xFirebaseBrokerQualified,
    instagramEnabled: _instagramEnabled,
    instagramProfessionalLoginQualified: _instagramProfessionalLoginQualified,
    instagramExactRedirectQualified: _instagramExactRedirectQualified,
    instagramBrokerAdapterInstalled: instagramAdapter != null,
    instagramBrokerQualified: _instagramBrokerQualified,
    instagramRevocationQualified: _instagramRevocationQualified,
    facebookEnabled: _facebookEnabled,
    facebookNativeAdapterInstalled: facebookAdapter.isConfigured,
    facebookProviderQualified: _facebookProviderQualified,
    facebookAndroidConfigurationQualified:
        _facebookAndroidConfigurationQualified,
    facebookRevocationQualified: _facebookRevocationQualified,
    facebookDataDeletionQualified: _facebookDataDeletionQualified,
  );
  final globalSocialLoginAuditComposition =
      resolveGlobalSocialLoginAuditComposition(
        deviceReview: _deviceReviewMode,
        globalSocialLoginAudit: _globalSocialLoginAuditMode,
      );
  final productionSocialIdentityProviders = _productionSocialIdentityProviders(
    publicAuthRuntimeConfiguration,
    googleOnlyForensicMode: _googleOnlyForensicMode,
  );
  final emailLinkGatewaySelection = resolveEmailLinkGatewaySelection(
    deviceReviewMode: globalSocialLoginAuditComposition.useReviewAuthentication,
    publicReviewMode: _youtubePublicReviewMode,
    runtimeConfigurationAvailable: emailLinkRuntimeAvailable,
  );
  final EmailLinkGateway emailLinkGateway = switch (emailLinkGatewaySelection) {
    EmailLinkGatewaySelection.review => ReviewEmailLinkGateway(),
    EmailLinkGatewaySelection.firebase => FirebaseEmailLinkGateway(
      FirebaseAuth.instance,
      continueUrl: _emailLinkContinueUrl,
      linkDomain: _emailLinkDomain,
    ),
    EmailLinkGatewaySelection.unavailable =>
      const UnavailableEmailLinkGateway(),
  };
  final pendingEmailLinkAddressStore = SecurePendingEmailLinkAddressStore();
  final accountIdentityGateway = FirebaseAuthenticatedAccountIdentityGateway(
    FirebaseAuth.instance,
  );
  final secureVerifiedPrincipalBindingStore =
      SecureVerifiedPrincipalBindingStore();
  final VerifiedPrincipalBindingStore verifiedPrincipalBindingStore =
      globalSocialLoginAuditComposition.useReviewAuthentication &&
          !_youtubePublicReviewMode
      ? MemoryVerifiedPrincipalBindingStore()
      : secureVerifiedPrincipalBindingStore;
  final searchPersistence = SecureStorageYouTubePublicSearchKeyValueStore();
  final watchPersistence = SecureStorageYouTubePublicWatchKeyValueStore();
  final shortPersistence = SecureStorageYouTubePublicShortKeyValueStore();
  final draftPersistence = SecureStorageSocialCreateDraftKeyValueStore();
  SocialCreateDraftMediaStore? draftMediaStore;
  try {
    final support = await getApplicationSupportDirectory().timeout(
      _youtubeCatalogueCacheHydrationTimeout,
    );
    draftMediaStore = SocialCreateDraftMediaStore(
      root: Directory('${support.path}${Platform.pathSeparator}create_drafts'),
    );
    configureSocialCreateDraftMediaStore(draftMediaStore);
  } on Object {
    draftMediaStore = null;
  }

  Future<bool> invalidateCreateDraftState() async {
    var envelopeInvalidated = false;
    var mediaPurged = draftMediaStore == null;
    try {
      await DurableSocialCreateDraftRepository.invalidateUnbound(
        draftPersistence,
      ).timeout(_youtubeCatalogueCacheHydrationTimeout);
      envelopeInvalidated = true;
    } on Object {
      // Media purge remains mandatory after an independent envelope failure.
    }
    try {
      final mediaStore = draftMediaStore;
      if (mediaStore != null) {
        mediaPurged = await mediaStore.disableStagingAndPurgeAll().timeout(
          _youtubeCatalogueCacheHydrationTimeout,
        );
      }
      if (mediaStore == null) mediaPurged = true;
    } on Object {
      // Envelope invalidation remains authoritative after media cleanup failure.
    }
    return envelopeInvalidated && mediaPurged;
  }

  Future<void> bindYouTubeSearchStateToCurrentPrincipal() async {
    _recordReleaseBootstrapStage('youtube_search_state', 'begin');
    _recordReleaseBootstrapStage('youtube_watch_state', 'begin');
    _recordReleaseBootstrapStage('youtube_short_state', 'begin');
    _recordReleaseBootstrapStage('social_create_draft', 'begin');
    final searchBindingAttempt = youtubePublicSearchState
        .beginPrincipalBindingAttempt();
    final watchBindingAttempt = youtubePublicWatchState
        .beginPrincipalBindingAttempt();
    final shortBindingAttempt = youtubePublicShortState
        .beginPrincipalBindingAttempt();
    final draftBindingAttempt = socialCreateDraftState
        .beginPrincipalBindingAttempt();
    try {
      final currentPrincipalId = FirebaseAuth.instance.currentUser?.uid;
      if (currentPrincipalId == null || currentPrincipalId.isEmpty) {
        final invalidated = await invalidateYouTubePublicRuntimeState(
          searchPersistence: searchPersistence,
          watchPersistence: watchPersistence,
          shortPersistence: shortPersistence,
          timeout: _youtubeCatalogueCacheHydrationTimeout,
        );
        final draftInvalidated = await invalidateCreateDraftState();
        _recordReleaseBootstrapStage(
          'youtube_search_state',
          invalidated.search ? 'passed' : 'degraded',
        );
        _recordReleaseBootstrapStage(
          'youtube_watch_state',
          invalidated.watch ? 'passed' : 'degraded',
        );
        _recordReleaseBootstrapStage(
          'youtube_short_state',
          invalidated.short ? 'passed' : 'degraded',
        );
        _recordReleaseBootstrapStage(
          'social_create_draft',
          draftInvalidated ? 'passed' : 'degraded',
        );
        return;
      }
      final storedBinding =
          identical(
            verifiedPrincipalBindingStore,
            secureVerifiedPrincipalBindingStore,
          )
          ? await secureVerifiedPrincipalBindingStore.read().timeout(
              _youtubeCatalogueCacheHydrationTimeout,
            )
          : null;
      if (storedBinding == null) {
        await invalidateYouTubePublicRuntimeState(
          searchPersistence: searchPersistence,
          watchPersistence: watchPersistence,
          shortPersistence: shortPersistence,
          timeout: _youtubeCatalogueCacheHydrationTimeout,
        );
        await invalidateCreateDraftState();
        _recordReleaseBootstrapStage('youtube_search_state', 'degraded');
        _recordReleaseBootstrapStage('youtube_watch_state', 'degraded');
        _recordReleaseBootstrapStage('youtube_short_state', 'degraded');
        _recordReleaseBootstrapStage('social_create_draft', 'degraded');
        return;
      }
      final currentBinding = await secureVerifiedPrincipalBindingStore
          .protect(currentPrincipalId)
          .timeout(_youtubeCatalogueCacheHydrationTimeout);
      if (!storedBinding.matches(currentBinding)) {
        await invalidateYouTubePublicRuntimeState(
          searchPersistence: searchPersistence,
          watchPersistence: watchPersistence,
          shortPersistence: shortPersistence,
          timeout: _youtubeCatalogueCacheHydrationTimeout,
        );
        await invalidateCreateDraftState();
        _recordReleaseBootstrapStage('youtube_search_state', 'degraded');
        _recordReleaseBootstrapStage('youtube_watch_state', 'degraded');
        _recordReleaseBootstrapStage('youtube_short_state', 'degraded');
        _recordReleaseBootstrapStage('social_create_draft', 'degraded');
        return;
      }
      YouTubePublicSearchFreshness? searchFreshness;
      try {
        searchFreshness = await youtubePublicSearchState
            .configureDurability(
              DurableYouTubePublicSearchStateRepository(
                persistence: searchPersistence,
                principalBinding: storedBinding,
                regionCode: screen04YouTubeRegionCode,
              ),
              bindingAttempt: searchBindingAttempt,
            )
            .timeout(_youtubeCatalogueCacheHydrationTimeout);
      } on Object {
        youtubePublicSearchState.beginPrincipalBindingAttempt();
      }
      YouTubePublicWatchFreshness? watchFreshness;
      try {
        watchFreshness = await youtubePublicWatchState
            .configureDurability(
              DurableYouTubePublicWatchStateRepository(
                persistence: watchPersistence,
                principalBinding: storedBinding,
                regionCode: screen04YouTubeRegionCode,
              ),
              bindingAttempt: watchBindingAttempt,
            )
            .timeout(_youtubeCatalogueCacheHydrationTimeout);
      } on Object {
        youtubePublicWatchState.beginPrincipalBindingAttempt();
      }
      YouTubePublicShortFreshness? shortFreshness;
      try {
        shortFreshness = await youtubePublicShortState
            .configureDurability(
              DurableYouTubePublicShortStateRepository(
                persistence: shortPersistence,
                principalBinding: storedBinding,
                regionCode: screen04YouTubeRegionCode,
              ),
              bindingAttempt: shortBindingAttempt,
            )
            .timeout(_youtubeCatalogueCacheHydrationTimeout);
      } on Object {
        youtubePublicShortState.beginPrincipalBindingAttempt();
      }
      SocialCreateDraftFreshness? draftFreshness;
      try {
        draftFreshness = await socialCreateDraftState
            .configureDurability(
              DurableSocialCreateDraftRepository(
                persistence: draftPersistence,
                principalBinding: storedBinding,
              ),
              bindingAttempt: draftBindingAttempt,
            )
            .timeout(_youtubeCatalogueCacheHydrationTimeout);
        final mediaStore = draftMediaStore;
        if (mediaStore != null) {
          mediaStore.enableStaging();
          final snapshot = socialCreateDraftState.snapshot;
          if (snapshot == null) {
            await mediaStore.purgeAll().timeout(
              _youtubeCatalogueCacheHydrationTimeout,
            );
          } else {
            await mediaStore
                .purgeExcept(<String>{
                  ...snapshot.media.map((item) => item.id),
                  ...snapshot.imagePollMedia
                      .whereType<SocialCreateDraftMediaReference>()
                      .map((item) => item.id),
                })
                .timeout(_youtubeCatalogueCacheHydrationTimeout);
          }
        }
      } on Object {
        socialCreateDraftState.beginPrincipalBindingAttempt();
      }
      _recordReleaseBootstrapStage(
        'youtube_search_state',
        youtubePublicSearchHydrationIsDegraded(searchFreshness)
            ? 'degraded'
            : 'passed',
      );
      _recordReleaseBootstrapStage(
        'youtube_watch_state',
        youtubePublicWatchHydrationIsDegraded(watchFreshness)
            ? 'degraded'
            : 'passed',
      );
      _recordReleaseBootstrapStage(
        'youtube_short_state',
        youtubePublicShortHydrationIsDegraded(shortFreshness)
            ? 'degraded'
            : 'passed',
      );
      _recordReleaseBootstrapStage(
        'social_create_draft',
        draftMediaStore != null &&
                (draftFreshness == SocialCreateDraftFreshness.fresh ||
                    draftFreshness == SocialCreateDraftFreshness.stale ||
                    draftFreshness == SocialCreateDraftFreshness.missing)
            ? 'passed'
            : 'degraded',
      );
    } on Object {
      youtubePublicSearchState.beginPrincipalBindingAttempt();
      youtubePublicWatchState.beginPrincipalBindingAttempt();
      youtubePublicShortState.beginPrincipalBindingAttempt();
      socialCreateDraftState.beginPrincipalBindingAttempt();
      await invalidateYouTubePublicRuntimeState(
        searchPersistence: searchPersistence,
        watchPersistence: watchPersistence,
        shortPersistence: shortPersistence,
        timeout: _youtubeCatalogueCacheHydrationTimeout,
      );
      await invalidateCreateDraftState();
      _recordReleaseBootstrapStage('youtube_search_state', 'degraded');
      _recordReleaseBootstrapStage('youtube_watch_state', 'degraded');
      _recordReleaseBootstrapStage('youtube_short_state', 'degraded');
      _recordReleaseBootstrapStage('social_create_draft', 'degraded');
    }
  }

  await bindYouTubeSearchStateToCurrentPrincipal();
  final firebaseSessionBootstrap = FirebaseAuthenticatedSessionBootstrapGateway(
    FirebaseAuth.instance,
    bindingProtector: secureVerifiedPrincipalBindingStore,
  );
  final session = _youtubePublicReviewMode
      ? JourneySession(
          store: SeededJourneyStore(
            delegate: SharedPreferencesJourneyStore(preferences),
            seed: const JourneySnapshot(
              languageCode: 'en',
              areaMode: 'current',
              areaLabel: 'Khema-Ka-Kuwa, Jodhpur, Rajasthan',
              setupComplete: true,
              setupExperienceVersion: approvedSetupExperienceVersion,
              pendingRoute: '/app/social?sub=videos',
            ),
          ),
          otpGateway: FirebaseOtpGateway(FirebaseAuth.instance),
          emailOtpGateway: HttpEmailOtpGateway(
            FirebaseAuth.instance,
            apiBaseUrl: _authApiBaseUrl,
          ),
          emailLinkGateway: emailLinkGateway,
          pendingEmailLinkAddressStore: pendingEmailLinkAddressStore,
          socialAuthGateway: FirebaseSocialAuthGateway(
            FirebaseAuth.instance,
            googleServerClientId: _googleServerClientId,
            xAdapter: xAdapter,
            instagramAdapter: instagramAdapter,
            facebookAdapter: facebookAdapter,
          ),
          availableSocialAuthProviders: productionSocialIdentityProviders,
          emailOtpAvailable: isQualifiedHttpsRuntimeEndpoint(_authApiBaseUrl),
          emailLinkAvailable:
              publicAuthRuntimeConfiguration.passwordlessEmailAvailable,
          mobileOtpAvailable: publicAuthRuntimeConfiguration.mobileOtpAvailable,
          accountBootstrapGateway: firebaseSessionBootstrap,
          verifiedPrincipalBindingStore: verifiedPrincipalBindingStore,
          accountIdentityGateway: accountIdentityGateway,
          locationGateway: DeviceLocationPermissionGateway(),
          currentAreaGateway: DeviceCurrentAreaGateway(),
          allowGuestReady: false,
        )
      : JourneySession(
          store: SharedPreferencesJourneyStore(preferences),
          otpGateway: FirebaseOtpGateway(
            FirebaseAuth.instance,
            emulatorHost: _useEmulators ? emulatorHost : null,
            emulatorFallbackHost:
                globalSocialLoginAuditComposition.useReviewAuthentication &&
                    emulatorFallbackHost.trim().isNotEmpty
                ? emulatorFallbackHost
                : null,
            emulatorProjectId: _useEmulators ? firebaseOptions.projectId : null,
            emulatorApiKey: firebaseOptions.apiKey,
            directEmulatorAuth:
                globalSocialLoginAuditComposition.useReviewAuthentication,
            reviewPreferences:
                globalSocialLoginAuditComposition.useReviewAuthentication
                ? preferences
                : null,
          ),
          emailOtpGateway:
              globalSocialLoginAuditComposition.useReviewAuthentication
              ? SharedPreferencesReviewEmailOtpGateway(preferences)
              : HttpEmailOtpGateway(
                  FirebaseAuth.instance,
                  apiBaseUrl: _authApiBaseUrl,
                ),
          emailLinkGateway: emailLinkGateway,
          pendingEmailLinkAddressStore: pendingEmailLinkAddressStore,
          socialAuthGateway:
              globalSocialLoginAuditComposition.useReviewAuthentication
              ? ReviewSocialAuthGateway(
                  responseDelay: const Duration(milliseconds: 650),
                )
              : FirebaseSocialAuthGateway(
                  FirebaseAuth.instance,
                  googleServerClientId: _googleServerClientId,
                  xAdapter: xAdapter,
                  instagramAdapter: instagramAdapter,
                  facebookAdapter: facebookAdapter,
                ),
          availableSocialAuthProviders:
              globalSocialLoginAuditComposition
                  .useProductionProviderAvailability
              ? productionSocialIdentityProviders
              : null,
          emailOtpAvailable:
              globalSocialLoginAuditComposition.useReviewAuthentication ||
              _useEmulators ||
              isQualifiedHttpsRuntimeEndpoint(_authApiBaseUrl),
          emailLinkAvailable:
              globalSocialLoginAuditComposition.useReviewAuthentication ||
              publicAuthRuntimeConfiguration.passwordlessEmailAvailable,
          mobileOtpAvailable:
              globalSocialLoginAuditComposition.useReviewAuthentication ||
              publicAuthRuntimeConfiguration.mobileOtpAvailable,
          accountBootstrapGateway:
              globalSocialLoginAuditComposition.useReviewAuthentication
              ? ReviewAccountBootstrapGateway()
              : globalSocialLoginAuditComposition.useFirebaseSessionBootstrap
              ? firebaseSessionBootstrap
              : DataConnectAccountBootstrapGateway(
                  principalGateway: firebaseSessionBootstrap,
                  emulatorHost: _useEmulators ? emulatorHost : null,
                ),
          verifiedPrincipalBindingStore: verifiedPrincipalBindingStore,
          accountIdentityGateway: accountIdentityGateway,
          locationGateway: DeviceLocationPermissionGateway(),
          currentAreaGateway: DeviceCurrentAreaGateway(),
        );

  late final bool socialAuthInitialLocation;
  _recordReleaseBootstrapStage('social_auth_return', 'begin');
  try {
    socialAuthInitialLocation =
        youtubeInitialLocation == null &&
        await session
            .prepareSocialAuthReturn(platformRouteName)
            .timeout(_releasePlatformStageTimeout);
  } on Object {
    _showReleaseBootstrapFailure('social_auth_return');
    return;
  }
  _recordReleaseBootstrapStage('social_auth_return', 'passed');
  late final bool emailLinkInitialLocation;
  _recordReleaseBootstrapStage('email_link_return', 'begin');
  try {
    emailLinkInitialLocation =
        youtubeInitialLocation == null &&
        !socialAuthInitialLocation &&
        await session
            .prepareEmailLinkReturn(platformRouteName)
            .timeout(_releasePlatformStageTimeout);
  } on Object {
    _showReleaseBootstrapFailure('email_link_return');
    return;
  }
  _recordReleaseBootstrapStage('email_link_return', 'passed');

  _recordReleaseBootstrapStage('normal_app', 'begin');
  runApp(
    MoolSocialApp(
      session: session,
      chatSession: ChatSession.production(),
      retailerSession: RetailerSession.production(),
      workSession: WorkSession.production(),
      disposeSession: true,
      disposeChatSession: true,
      disposeRetailerSession: true,
      disposeWorkSession: true,
      onAuthenticatedBoundary: bindYouTubeSearchStateToCurrentPrincipal,
      initialLocation:
          youtubeInitialLocation ??
          (socialAuthInitialLocation || emailLinkInitialLocation
              ? '/sign-in'
              : '/boot'),
    ),
  );
  _recordReleaseBootstrapStage('normal_app', 'passed');
}

bool _runtimeModeIsValid() {
  return isQualifiedUiReviewOnlyRuntimeMode(
        uiReviewOnly: _uiReviewOnlyMode,
        isDebugMode: kDebugMode,
        deviceReview: _deviceReviewMode,
        useEmulators: _useEmulators,
        youtubePublicReview: _youtubePublicReviewMode,
        youtubePrivateDevProof: youtubePrivateDevProofEnabled,
        sideloadPreflightEnabled: _sideloadPreflightEnabled,
        globalSocialLoginAudit: _globalSocialLoginAuditMode,
      ) &&
      isQualifiedDeviceReviewRuntimeMode(
        deviceReview: _deviceReviewMode,
        useEmulators: _useEmulators,
        youtubePublicReview: _youtubePublicReviewMode,
        youtubePrivateDevProof: youtubePrivateDevProofEnabled,
        sideloadPreflightEnabled: _sideloadPreflightEnabled,
        googleSideloadSigningQualified: _googleSideloadSigningQualified,
        globalSocialLoginAudit: _globalSocialLoginAuditMode,
      ) &&
      isQualifiedSocialRuntimeDependencySet(
        globalSocialLoginAudit: _globalSocialLoginAuditMode,
        useEmulators: _useEmulators,
        firebaseProjectId: _firebaseProjectId,
        youtubePrivateDevProof: youtubePrivateDevProofEnabled,
        youtubeEmbeddedPlayerEnabled: youtubeEmbeddedPlayerEnabled,
        youtubeProviderUrl: youtubePrivateDevProviderUrl,
        socialContentUrl: moolSocialContentUrl,
        chatUrl: moolSocialChatUrl,
      );
}

FirebaseOptions _firebaseOptions() {
  if (_useEmulators) return _localFirebaseOptions;
  return FirebaseOptions(
    apiKey: _releaseRuntimeConfiguration.firebaseApiKey,
    appId: _releaseRuntimeConfiguration.firebaseAppId,
    messagingSenderId: _releaseRuntimeConfiguration.firebaseMessagingSenderId,
    projectId: _releaseRuntimeConfiguration.firebaseProjectId,
  );
}
