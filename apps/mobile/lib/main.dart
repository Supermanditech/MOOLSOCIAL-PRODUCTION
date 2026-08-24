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
import 'features/shared/social_content_gateway.dart';

const _localFirebaseOptions = FirebaseOptions(
  apiKey: 'demo-moolsocial-local-key',
  appId: '1:100000000001:android:moolsocial-local',
  messagingSenderId: '100000000001',
  projectId: 'demo-moolsocial-local',
);
const _releaseFirstFrameTimeout = Duration(seconds: 5);
const _releasePlatformStageTimeout = Duration(seconds: 15);

const _useEmulators = bool.fromEnvironment(
  'MOOLSOCIAL_USE_EMULATORS',
  defaultValue: kDebugMode,
);
const _deviceReviewMode = bool.fromEnvironment('MOOLSOCIAL_DEVICE_REVIEW');
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
}) => <SocialAuthProvider>{
  if (configuration.googleAndYoutubeAvailable) SocialAuthProvider.google,
  if (!googleOnlyForensicMode && configuration.googleAndYoutubeAvailable)
    SocialAuthProvider.youtube,
  if (!googleOnlyForensicMode && configuration.appleAvailable)
    SocialAuthProvider.apple,
  if (!googleOnlyForensicMode && configuration.xAvailable) SocialAuthProvider.x,
  if (!googleOnlyForensicMode && configuration.instagramAvailable)
    SocialAuthProvider.instagram,
  if (!googleOnlyForensicMode && configuration.facebookAvailable)
    SocialAuthProvider.facebook,
};

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
          accountBootstrapGateway: DataConnectAccountBootstrapGateway(),
          locationGateway: DeviceLocationPermissionGateway(),
          currentAreaGateway: DeviceCurrentAreaGateway(),
          allowGuestReady: true,
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
              ? FirebaseAuthenticatedSessionBootstrapGateway(
                  FirebaseAuth.instance,
                )
              : DataConnectAccountBootstrapGateway(
                  emulatorHost: _useEmulators ? emulatorHost : null,
                ),
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
      disposeSession: true,
      disposeChatSession: true,
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
  return isQualifiedDeviceReviewRuntimeMode(
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
