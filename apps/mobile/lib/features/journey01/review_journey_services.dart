import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, kDebugMode, visibleForTesting;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:permission_handler/permission_handler.dart'
    as permission_handler
    show openAppSettings;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/auth/facebook_login_contract.dart';
import '../../core/auth/instagram_oauth_network_adapter.dart';
import '../../core/auth/public_auth_failure.dart';
import '../../core/auth/x_oauth2_pkce_network_adapter.dart';
import '../../data/generated/mobile.dart';
import 'journey_services.dart';

const reviewAuthenticatedUserPreferenceKey =
    'journey01.review_authenticated_user';

class SharedPreferencesJourneyStore implements JourneyStore {
  SharedPreferencesJourneyStore(this._preferences);

  static const _languageKey = 'journey01.language';
  static const _areaModeKey = 'journey01.area_mode';
  static const _areaLabelKey = 'journey01.area_label';
  static const _currentAreaLabelKey = 'journey01.current_area_label';
  static const _homeOrWorkAreaLabelKey = 'journey01.home_or_work_area_label';
  static const _setupCompleteKey = 'journey01.setup_complete';
  static const _setupExperienceVersionKey =
      'journey01.setup_experience_version';
  static const _pendingRouteKey = 'journey01.pending_route';
  static const _pendingAuthenticationCancelRouteKey =
      'journey01.pending_authentication_cancel_route';
  static const _pendingAuthenticationPurposeKey =
      'journey01.pending_authentication_purpose';
  static const _lastReadyRouteKey = 'journey01.last_ready_route';

  final SharedPreferences _preferences;

  @override
  Future<JourneySnapshot?> read() async {
    final hasState =
        _preferences.containsKey(_languageKey) ||
        _preferences.containsKey(_setupCompleteKey);
    if (!hasState) return null;

    return JourneySnapshot(
      languageCode: _preferences.getString(_languageKey) ?? 'en',
      areaMode: _preferences.getString(_areaModeKey),
      areaLabel: _preferences.getString(_areaLabelKey),
      currentAreaLabel: _preferences.getString(_currentAreaLabelKey),
      homeOrWorkAreaLabel: _preferences.getString(_homeOrWorkAreaLabelKey),
      setupComplete: _preferences.getBool(_setupCompleteKey) ?? false,
      pendingRoute: _preferences.getString(_pendingRouteKey),
      pendingAuthenticationCancelRoute: _preferences.getString(
        _pendingAuthenticationCancelRouteKey,
      ),
      pendingAuthenticationPurpose: _preferences.getString(
        _pendingAuthenticationPurposeKey,
      ),
      lastReadyRoute: _preferences.getString(_lastReadyRouteKey),
      setupExperienceVersion:
          _preferences.getInt(_setupExperienceVersionKey) ?? 1,
    );
  }

  @override
  Future<void> write(JourneySnapshot snapshot) async {
    await _preferences.setString(_languageKey, snapshot.languageCode);
    await _preferences.setBool(_setupCompleteKey, snapshot.setupComplete);
    await _preferences.setInt(
      _setupExperienceVersionKey,
      snapshot.setupExperienceVersion,
    );
    await _setNullable(_areaModeKey, snapshot.areaMode);
    await _setNullable(_areaLabelKey, snapshot.areaLabel);
    await _setNullable(_currentAreaLabelKey, snapshot.currentAreaLabel);
    await _setNullable(_homeOrWorkAreaLabelKey, snapshot.homeOrWorkAreaLabel);
    await _setNullable(_pendingRouteKey, snapshot.pendingRoute);
    await _setNullable(
      _pendingAuthenticationCancelRouteKey,
      snapshot.pendingAuthenticationCancelRoute,
    );
    await _setNullable(
      _pendingAuthenticationPurposeKey,
      snapshot.pendingAuthenticationPurpose,
    );
    await _setNullable(_lastReadyRouteKey, snapshot.lastReadyRoute);
  }

  Future<void> _setNullable(String key, String? value) async {
    if (value == null || value.isEmpty) {
      await _preferences.remove(key);
    } else {
      await _preferences.setString(key, value);
    }
  }
}

class SecurePendingEmailLinkAddressStore
    implements PendingEmailLinkAddressStore {
  SecurePendingEmailLinkAddressStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(storageNamespace: 'moolsocial_email_link'),
          );

  static const _addressKey = 'pending_address';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _addressKey);

  @override
  Future<void> write(String emailAddress) =>
      _storage.write(key: _addressKey, value: emailAddress);

  @override
  Future<void> clear() => _storage.delete(key: _addressKey);
}

class FirebaseOtpGateway implements OtpGateway {
  FirebaseOtpGateway(
    this._auth, {
    this.emulatorHost,
    this.emulatorFallbackHost,
    this.emulatorProjectId,
    this.emulatorApiKey = 'demo-moolsocial-local-key',
    this.emulatorPort = 9099,
    this.directEmulatorAuth = false,
    this.reviewPreferences,
  });

  final FirebaseAuth _auth;
  final String? emulatorHost;
  final String? emulatorFallbackHost;
  final String emulatorApiKey;
  final int emulatorPort;
  final String? emulatorProjectId;
  final bool directEmulatorAuth;
  final SharedPreferences? reviewPreferences;

  String? _verificationId;
  int? _resendToken;
  String? _directEmulatorUserId;
  final PhoneVerificationCompletionGate _phoneVerificationGate =
      PhoneVerificationCompletionGate();

  @override
  Future<bool> hasAuthenticatedUser() async =>
      _directEmulatorUserId != null ||
      (reviewPreferences
              ?.getString(reviewAuthenticatedUserPreferenceKey)
              ?.isNotEmpty ??
          false) ||
      _auth.currentUser != null;

  @override
  Future<OtpRequestResult> requestCode(String phoneNumber) async {
    if (_usesDirectEmulatorAuth) {
      return _requestEmulatorCode(phoneNumber);
    }

    final previousEmulatorSession = _usesEmulatorReview
        ? (await _latestEmulatorVerification(phoneNumber))?.sessionInfo
        : null;
    final completer = Completer<OtpRequestResult>();
    final requestGeneration = _phoneVerificationGate.beginAttempt();

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      forceResendingToken: _resendToken,
      verificationCompleted: (credential) async {
        if (!_phoneVerificationGate.claimTerminal(requestGeneration)) return;
        try {
          final result = await _auth.signInWithCredential(credential);
          if (!completer.isCompleted) {
            completer.complete(
              OtpRequestResult(
                automaticallyVerified: true,
                userId: result.user?.uid,
              ),
            );
          }
        } on FirebaseAuthException catch (error) {
          if (!completer.isCompleted) {
            completer.completeError(_friendlyAuthError(error));
          }
        } on Object {
          if (!completer.isCompleted) {
            completer.completeError(
              const JourneyServiceException(
                'Verification could not be completed. Please retry.',
                code: 'auth-unknown',
              ),
            );
          }
        }
      },
      verificationFailed: (error) {
        if (!_phoneVerificationGate.claimTerminal(requestGeneration)) return;
        if (!completer.isCompleted) {
          completer.completeError(_friendlyAuthError(error));
        }
      },
      codeSent: (verificationId, resendToken) {
        if (!_phoneVerificationGate.claimTerminal(requestGeneration)) return;
        _verificationId = verificationId;
        _resendToken = resendToken;
        if (!completer.isCompleted) {
          completer.complete(const OtpRequestResult());
        }
      },
      codeAutoRetrievalTimeout: (verificationId) {
        if (!_phoneVerificationGate.isCurrent(requestGeneration)) return;
        _verificationId = verificationId;
      },
    );

    if (_usesEmulatorReview) {
      unawaited(
        _completeFromEmulator(phoneNumber, completer, previousEmulatorSession),
      );
    }
    return completer.future.timeout(
      const Duration(seconds: 70),
      onTimeout: () {
        _phoneVerificationGate.invalidate(requestGeneration);
        throw const JourneyServiceException(
          'The verification service did not respond. Check the connection and retry.',
        );
      },
    );
  }

  @override
  Future<String> verifyCode(String code) async {
    if (_usesDirectEmulatorAuth) {
      return _verifyEmulatorCode(code);
    }

    final verificationId = _verificationId;
    if (verificationId == null) {
      throw const JourneyServiceException(
        'Request a new verification code and try again.',
      );
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: code,
      );
      final result = await _auth.signInWithCredential(credential);
      final user = result.user;
      if (user == null) {
        throw const JourneyServiceException(
          'We could not finish verification. Please retry.',
        );
      }
      return user.uid;
    } on FirebaseAuthException catch (error) {
      throw _friendlyAuthError(error);
    }
  }

  @override
  Future<String?> reviewCodeFor(String phoneNumber) async {
    if (!_usesEmulatorReview) return null;
    final verification = await _latestEmulatorVerification(phoneNumber);
    return verification?.code;
  }

  bool get _usesEmulatorReview =>
      emulatorHost != null && emulatorProjectId != null;
  bool get _usesDirectEmulatorAuth => _usesEmulatorReview && directEmulatorAuth;
  Iterable<String> get _emulatorHosts sync* {
    final primary = emulatorHost?.trim();
    if (primary != null && primary.isNotEmpty) yield primary;
    final fallback = emulatorFallbackHost?.trim();
    if (fallback != null && fallback.isNotEmpty && fallback != primary) {
      yield fallback;
    }
  }

  Future<void> _completeFromEmulator(
    String phoneNumber,
    Completer<OtpRequestResult> completer,
    String? previousSessionInfo,
  ) async {
    for (var attempt = 0; attempt < 12 && !completer.isCompleted; attempt++) {
      final verification = await _latestEmulatorVerification(phoneNumber);
      if (verification != null &&
          verification.sessionInfo != previousSessionInfo) {
        _verificationId = verification.sessionInfo;
        completer.complete(const OtpRequestResult());
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  Future<OtpRequestResult> _requestEmulatorCode(String phoneNumber) async {
    if (_emulatorHosts.isEmpty) {
      throw const JourneyServiceException(
        'The verification service is unavailable. Please retry.',
      );
    }

    for (final host in _emulatorHosts) {
      final client = HttpClient();
      try {
        final uri = Uri.http(
          '$host:$emulatorPort',
          '/identitytoolkit.googleapis.com/v1/accounts:sendVerificationCode',
          {'key': emulatorApiKey},
        );
        final request = await client
            .postUrl(uri)
            .timeout(const Duration(seconds: 5));
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode({'phoneNumber': phoneNumber}));
        final response = await request.close().timeout(
          const Duration(seconds: 10),
        );
        final body = await utf8.decoder.bind(response).join();
        if (response.statusCode != HttpStatus.ok) {
          throw const JourneyServiceException(
            'The verification service could not send a code. Please retry.',
          );
        }
        final payload = jsonDecode(body) as Map<String, dynamic>;
        final sessionInfo = payload['sessionInfo'] as String?;
        if (sessionInfo == null || sessionInfo.isEmpty) {
          throw const JourneyServiceException(
            'The verification service did not return a valid code. Please retry.',
          );
        }
        _verificationId = sessionInfo;
        return const OtpRequestResult();
      } on JourneyServiceException {
        rethrow;
      } on SocketException {
        continue;
      } on TimeoutException {
        continue;
      } on HttpException {
        continue;
      } on Object {
        throw const JourneyServiceException(
          'The verification service did not respond. Please retry.',
        );
      } finally {
        client.close(force: true);
      }
    }

    throw const JourneyServiceException(
      'Mobile sign-in could not connect. Check your connection and try again.',
    );
  }

  Future<String> _verifyEmulatorCode(String code) async {
    final sessionInfo = _verificationId;
    if (_emulatorHosts.isEmpty || sessionInfo == null) {
      throw const JourneyServiceException(
        'Request a new verification code and try again.',
      );
    }

    for (final host in _emulatorHosts) {
      final client = HttpClient();
      try {
        final uri = Uri.http(
          '$host:$emulatorPort',
          '/identitytoolkit.googleapis.com/v1/accounts:signInWithPhoneNumber',
          {'key': emulatorApiKey},
        );
        final request = await client
            .postUrl(uri)
            .timeout(const Duration(seconds: 5));
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode({'sessionInfo': sessionInfo, 'code': code}));
        final response = await request.close().timeout(
          const Duration(seconds: 10),
        );
        final body = await utf8.decoder.bind(response).join();
        if (response.statusCode != HttpStatus.ok) {
          final payload = jsonDecode(body) as Map<String, dynamic>;
          final message =
              ((payload['error'] as Map<String, dynamic>?)?['message']
                      as String?)
                  ?.toUpperCase();
          if (message?.contains('INVALID_CODE') ?? false) {
            throw const JourneyServiceException(
              'That code is not valid. Check it and try again.',
            );
          }
          throw const JourneyServiceException(
            'We could not finish verification. Please retry.',
          );
        }
        final payload = jsonDecode(body) as Map<String, dynamic>;
        final userId = payload['localId'] as String?;
        if (userId == null || userId.isEmpty) {
          throw const JourneyServiceException(
            'We could not finish verification. Please retry.',
          );
        }
        _directEmulatorUserId = userId;
        await reviewPreferences?.setString(
          reviewAuthenticatedUserPreferenceKey,
          userId,
        );
        return userId;
      } on JourneyServiceException {
        rethrow;
      } on SocketException {
        continue;
      } on TimeoutException {
        continue;
      } on HttpException {
        continue;
      } on Object {
        throw const JourneyServiceException(
          'Verification could not be completed. Please retry.',
        );
      } finally {
        client.close(force: true);
      }
    }

    throw const JourneyServiceException(
      'Mobile sign-in could not connect. Check your connection and try again.',
    );
  }

  Future<({String code, String sessionInfo})?> _latestEmulatorVerification(
    String phoneNumber,
  ) async {
    final projectId = emulatorProjectId;
    if (_emulatorHosts.isEmpty || projectId == null) return null;

    for (final host in _emulatorHosts) {
      final client = HttpClient();
      try {
        final request = await client
            .getUrl(
              Uri.parse(
                'http://$host:$emulatorPort/emulator/v1/projects/$projectId/'
                'verificationCodes',
              ),
            )
            .timeout(const Duration(seconds: 5));
        final response = await request.close().timeout(
          const Duration(seconds: 10),
        );
        if (response.statusCode != HttpStatus.ok) continue;
        final body = await utf8.decoder.bind(response).join();
        final payload = jsonDecode(body) as Map<String, dynamic>;
        final codes =
            payload['verificationCodes'] as List<dynamic>? ?? const [];
        for (final item in codes.reversed) {
          final code = item as Map<String, dynamic>;
          if (code['phoneNumber'] == phoneNumber) {
            final value = (code['code'] ?? code['sessionCode']) as String?;
            final sessionInfo =
                (code['sessionInfo'] ?? code['sessionCode']) as String?;
            if (value != null && sessionInfo != null) {
              return (code: value, sessionInfo: sessionInfo);
            }
          }
        }
      } on Object {
        continue;
      } finally {
        client.close(force: true);
      }
    }
    return null;
  }

  @override
  Future<void> signOut() async {
    _directEmulatorUserId = null;
    await reviewPreferences?.remove(reviewAuthenticatedUserPreferenceKey);
    await _auth.signOut();
  }

  JourneyServiceException _friendlyAuthError(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-verification-code' => const JourneyServiceException(
        'That code is not valid. Check it and try again.',
      ),
      'session-expired' => const JourneyServiceException(
        'That code has expired. Request a new code.',
      ),
      'too-many-requests' => const JourneyServiceException(
        'Too many attempts. Wait a moment before retrying.',
      ),
      'network-request-failed' => const JourneyServiceException(
        'Mobile sign-in could not connect. Check your connection and try again.',
      ),
      'invalid-phone-number' => const JourneyServiceException(
        'Enter a valid 10-digit mobile number.',
      ),
      'app-not-authorized' ||
      'captcha-check-failed' ||
      'invalid-app-credential' ||
      'missing-app-credential' => const JourneyServiceException(
        'Mobile sign-in is not available right now. Choose another method.',
        code: 'auth-provider-configuration',
      ),
      'quota-exceeded' => const JourneyServiceException(
        'Mobile sign-in has reached its temporary limit. Try again later.',
        code: 'auth-throttled',
      ),
      _ => const JourneyServiceException(
        'Verification could not be completed. Please retry.',
        code: 'auth-unknown',
      ),
    };
  }
}

final class PhoneVerificationCompletionGate {
  int _generation = 0;
  bool _terminalClaimed = false;

  int beginAttempt() {
    _generation += 1;
    _terminalClaimed = false;
    return _generation;
  }

  bool isCurrent(int generation) => generation == _generation;

  bool claimTerminal(int generation) {
    if (!isCurrent(generation) || _terminalClaimed) return false;
    _terminalClaimed = true;
    return true;
  }

  void invalidate(int generation) {
    if (!isCurrent(generation)) return;
    _generation += 1;
    _terminalClaimed = true;
  }
}

typedef GoogleAuthStageObserver = void Function(String code);

const _googleAuthDeviceReviewMode = bool.fromEnvironment(
  'MOOLSOCIAL_DEVICE_REVIEW',
);

void _emitSanitizedGoogleAuthStage(String code) {
  if (kDebugMode || _googleAuthDeviceReviewMode) {
    debugPrint('MOOLSOCIAL_GOOGLE_AUTH code=$code');
  }
}

String _safeFirebaseAuthExceptionCode(String code) {
  const safeOneWordCodes = <String>{'canceled', 'cancelled', 'unknown'};
  if (code.length > 64 ||
      (!safeOneWordCodes.contains(code) &&
          !RegExp(r'^[a-z]+(?:-[a-z0-9]+){1,7}$').hasMatch(code))) {
    return 'unavailable';
  }
  return code;
}

String _safeFirebaseAuthCauseCategory({required String code, String? message}) {
  final normalizedCode = _safeFirebaseAuthExceptionCode(code);
  final normalizedMessage = message?.toLowerCase() ?? '';

  if (normalizedMessage.length <= 1024) {
    if (normalizedMessage.contains('app check') ||
        normalizedMessage.contains('appcheck') ||
        normalizedMessage.contains('app attestation')) {
      return 'app-check-rejected';
    }
    if (normalizedMessage.contains('api key') ||
        normalizedMessage.contains('api-key') ||
        normalizedMessage.contains('api_key') ||
        normalizedMessage.contains('android client application') &&
            normalizedMessage.contains('blocked')) {
      return 'api-key-restriction';
    }
    if (normalizedMessage.contains('identity toolkit') ||
        normalizedMessage.contains('identitytoolkit') ||
        normalizedMessage.contains('service_disabled') ||
        normalizedMessage.contains('service disabled')) {
      return 'identity-toolkit-unavailable';
    }
    if (normalizedMessage.contains('blocking function') ||
        normalizedMessage.contains('beforecreate') ||
        normalizedMessage.contains('beforesignin') ||
        normalizedMessage.contains('before-create') ||
        normalizedMessage.contains('before-sign-in')) {
      return 'blocking-function-rejected';
    }
    if (normalizedMessage.contains('tenant')) {
      return 'tenant-configuration';
    }
  }

  return switch (normalizedCode) {
    'canceled' || 'cancelled' => 'cancelled',
    'account-exists-with-different-credential' ||
    'credential-already-in-use' => 'account-collision',
    'network-request-failed' || 'web-network-request-failed' => 'network',
    'too-many-requests' => 'throttled',
    'user-disabled' => 'account-disabled',
    'operation-not-allowed' ||
    'provider-already-linked' ||
    'invalid-oauth-provider' => 'provider-configuration',
    'invalid-credential' ||
    'invalid-idp-response' ||
    'invalid-custom-token' ||
    'custom-token-mismatch' ||
    'missing-or-invalid-nonce' => 'credential-rejected',
    'expired-action-code' || 'session-expired' => 'credential-expired',
    'blocking-function-error-response' => 'blocking-function-rejected',
    'unknown' => 'firebase-unknown',
    _ => 'unavailable',
  };
}

abstract interface class GoogleIdentityGateway {
  Future<String?> authenticateIdToken();

  Future<void> signOut();
}

class NativeGoogleIdentityGateway implements GoogleIdentityGateway {
  NativeGoogleIdentityGateway({
    required this.serverClientId,
    this.authenticationTimeout = const Duration(seconds: 45),
    Future<void> Function(String serverClientId)? initialize,
    bool Function()? supportsAuthenticate,
    Future<String?> Function()? authenticateIdToken,
    Future<void> Function()? signOut,
    GoogleAuthStageObserver? stageObserver,
  }) : _initialize =
           initialize ??
           ((serverClientId) => GoogleSignIn.instance.initialize(
             serverClientId: serverClientId,
           )),
       _supportsAuthenticate =
           supportsAuthenticate ?? GoogleSignIn.instance.supportsAuthenticate,
       _authenticateIdToken =
           authenticateIdToken ??
           (() async {
             final account = await GoogleSignIn.instance.authenticate();
             return account.authentication.idToken;
           }),
       _signOut = signOut ?? GoogleSignIn.instance.signOut,
       _stageObserver = stageObserver ?? _emitSanitizedGoogleAuthStage;

  final String serverClientId;
  final Duration authenticationTimeout;
  final Future<void> Function(String serverClientId) _initialize;
  final bool Function() _supportsAuthenticate;
  final Future<String?> Function() _authenticateIdToken;
  final Future<void> Function() _signOut;
  final GoogleAuthStageObserver _stageObserver;
  Future<void>? _initialization;

  @override
  Future<String?> authenticateIdToken() async {
    final clientId = serverClientId.trim();
    if (clientId.isEmpty) {
      _stageObserver('auth-google-native-client-configuration');
      throw _googleFailure('clientConfigurationError');
    }
    try {
      _stageObserver('auth-google-native-initialize-started');
      await _ensureInitialized(clientId);
      _stageObserver('auth-google-native-initialize-complete');
      if (!_supportsAuthenticate()) {
        _stageObserver('auth-google-native-ui-unavailable');
        throw _googleFailure('uiUnavailable');
      }
      _stageObserver('auth-google-native-ui-requested');
      final idToken = await _authenticateIdToken().timeout(
        authenticationTimeout,
      );
      if (idToken == null || idToken.isEmpty) {
        _stageObserver('auth-google-native-identity-missing');
        throw _googleFailure('missing-id-token');
      }
      _stageObserver('auth-google-native-identity-returned');
      return idToken;
    } on TimeoutException {
      _stageObserver('auth-google-native-return-timeout');
      throw const JourneyServiceException(
        'Google sign-in took too long. Please try again.',
        code: 'auth-native-return-timeout',
      );
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        _stageObserver('auth-google-native-no-identity');
        return null;
      }
      _stageObserver('auth-google-native-provider-failed');
      throw _googleFailure(error.code.name);
    } on JourneyServiceException {
      rethrow;
    } on Object {
      _stageObserver('auth-google-native-unexpected');
      throw _googleFailure('nativeBridgeFailure');
    }
  }

  Future<void> _ensureInitialized(String clientId) async {
    final initialization = _initialization ??= _initialize(clientId);
    try {
      await initialization;
    } on Object {
      if (identical(_initialization, initialization)) {
        _initialization = null;
      }
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    if (_initialization == null) return;
    await _signOut();
  }

  JourneyServiceException _googleFailure(String code) {
    final failure = sanitizedGoogleIdentityFailure(code);
    return JourneyServiceException(failure.publicMessage, code: failure.code);
  }
}

abstract interface class FirebaseSocialAuthClient {
  String? get currentUserId;

  Future<String?> signInWithGoogleIdToken(String idToken);

  Future<String?> signInWithProvider(AuthProvider provider);

  Future<void> signOut();
}

class FirebaseAuthSocialClient implements FirebaseSocialAuthClient {
  FirebaseAuthSocialClient(this._auth);

  final FirebaseAuth _auth;

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  Future<String?> signInWithGoogleIdToken(String idToken) async {
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    return (await _auth.signInWithCredential(credential)).user?.uid;
  }

  @override
  Future<String?> signInWithProvider(AuthProvider provider) async {
    return (await _auth.signInWithProvider(provider)).user?.uid;
  }

  @override
  Future<void> signOut() => _auth.signOut();
}

class FirebaseAuthenticatedAccountIdentityGateway
    implements AuthenticatedAccountIdentityGateway {
  FirebaseAuthenticatedAccountIdentityGateway(this._auth);

  final FirebaseAuth _auth;

  @override
  Future<AuthenticatedAccountIdentity?> currentIdentity() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final providerLabels = user.providerData
        .map((provider) => _publicProviderLabel(provider.providerId))
        .whereType<String>()
        .toSet();
    try {
      final tokenResult = await user.getIdTokenResult();
      final customProvider = publicAuthenticatedProviderLabel(
        tokenResult.claims?['auth_provider'],
      );
      if (customProvider != null) providerLabels.add(customProvider);
    } on Object {
      // Firebase profile details remain usable without optional custom claims.
    }
    return AuthenticatedAccountIdentity(
      displayName: _nonEmpty(user.displayName),
      emailAddress:
          _nonEmpty(user.email) ??
          _firstNonEmpty(user.providerData.map((provider) => provider.email)),
      phoneNumber:
          _nonEmpty(user.phoneNumber) ??
          _firstNonEmpty(
            user.providerData.map((provider) => provider.phoneNumber),
          ),
      signInMethods: providerLabels.toList(growable: false),
    );
  }

  String? _firstNonEmpty(Iterable<String?> values) {
    for (final value in values) {
      final normalized = _nonEmpty(value);
      if (normalized != null) return normalized;
    }
    return null;
  }

  String? _nonEmpty(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  String? _publicProviderLabel(String providerId) =>
      publicAuthenticatedProviderLabel(providerId);
}

@visibleForTesting
String? publicAuthenticatedProviderLabel(Object? provider) =>
    switch (provider) {
      'google.com' || 'google' => 'Google',
      'facebook.com' || 'facebook' => 'Facebook',
      'twitter.com' || 'x' => 'X',
      'instagram' => 'Instagram',
      'apple.com' || 'apple' => 'Apple',
      'password' || 'email' || 'email_link' => 'Email',
      'phone' => 'Phone',
      _ => null,
    };

class FirebaseSocialAuthGateway
    implements SocialAuthGateway, SocialAuthCallbackGateway {
  FirebaseSocialAuthGateway(
    FirebaseAuth auth, {
    required String googleServerClientId,
    Duration firebaseCredentialTimeout = const Duration(seconds: 30),
    GoogleIdentityGateway? googleIdentityGateway,
    GoogleAuthStageObserver? googleStageObserver,
    XOAuth2PkceNetworkAdapter? xAdapter,
    InstagramOAuthNetworkAdapter? instagramAdapter,
    FacebookNativeSdkAdapter? facebookAdapter,
  }) : this._(
         FirebaseAuthSocialClient(auth),
         googleIdentityGateway ??
             NativeGoogleIdentityGateway(
               serverClientId: googleServerClientId,
               stageObserver:
                   googleStageObserver ?? _emitSanitizedGoogleAuthStage,
             ),
         xAdapter,
         instagramAdapter,
         facebookAdapter,
         firebaseCredentialTimeout,
         googleStageObserver ?? _emitSanitizedGoogleAuthStage,
       );

  FirebaseSocialAuthGateway.forTesting({
    required FirebaseSocialAuthClient authClient,
    required GoogleIdentityGateway googleIdentityGateway,
    Duration firebaseCredentialTimeout = const Duration(seconds: 30),
    GoogleAuthStageObserver? googleStageObserver,
    XOAuth2PkceNetworkAdapter? xAdapter,
    InstagramOAuthNetworkAdapter? instagramAdapter,
    FacebookNativeSdkAdapter? facebookAdapter,
  }) : this._(
         authClient,
         googleIdentityGateway,
         xAdapter,
         instagramAdapter,
         facebookAdapter,
         firebaseCredentialTimeout,
         googleStageObserver ?? _emitSanitizedGoogleAuthStage,
       );

  FirebaseSocialAuthGateway._(
    this._authClient,
    this._googleIdentityGateway,
    this._xAdapter,
    this._instagramAdapter,
    this._facebookAdapter,
    this.firebaseCredentialTimeout,
    this._googleStageObserver,
  );

  final FirebaseSocialAuthClient _authClient;
  final GoogleIdentityGateway _googleIdentityGateway;
  final XOAuth2PkceNetworkAdapter? _xAdapter;
  final InstagramOAuthNetworkAdapter? _instagramAdapter;
  final FacebookNativeSdkAdapter? _facebookAdapter;
  final Duration firebaseCredentialTimeout;
  final GoogleAuthStageObserver _googleStageObserver;

  @override
  Future<bool> hasAuthenticatedUser() async =>
      _authClient.currentUserId != null;

  @override
  Future<SocialAuthResult> signIn(SocialAuthProvider provider) async {
    try {
      if (provider == SocialAuthProvider.x) {
        final adapter = _xAdapter;
        if (adapter == null) throw _configurationFailure('X');
        return _brokeredResult(
          await adapter.beginAuthorization(),
          allowAuthorizationPending: true,
        );
      }
      if (provider == SocialAuthProvider.instagram) {
        final adapter = _instagramAdapter;
        if (adapter == null) throw _configurationFailure('Instagram');
        return _brokeredResult(
          await adapter.beginAuthorization(),
          allowAuthorizationPending: true,
        );
      }
      if (provider == SocialAuthProvider.facebook) {
        final adapter = _facebookAdapter;
        if (adapter == null || !adapter.isConfigured) {
          throw _configurationFailure('Facebook');
        }
        return _facebookResult(await adapter.signIn());
      }

      final String? userId;
      if (provider == SocialAuthProvider.google ||
          provider == SocialAuthProvider.youtube) {
        userId = await _signInWithGoogleIdentity();
        if (userId == null) {
          return SocialAuthResult.cancelled(
            code: provider == SocialAuthProvider.google
                ? 'auth-google-native-no-identity'
                : 'auth-youtube-shared-google-native-no-identity',
          );
        }
      } else {
        userId = switch (provider) {
          SocialAuthProvider.apple => await _authClient.signInWithProvider(
            AppleAuthProvider(),
          ),
          SocialAuthProvider.google ||
          SocialAuthProvider.youtube ||
          SocialAuthProvider.x ||
          SocialAuthProvider.instagram ||
          SocialAuthProvider.facebook => throw StateError('Handled above.'),
        };
      }
      if (userId == null) return const SocialAuthResult.cancelled();
      final authenticatedUserId = userId;
      if (authenticatedUserId.isEmpty) {
        throw const JourneyServiceException(
          'Sign-in could not be completed. Please try again.',
          code: 'auth-firebase-session-missing',
        );
      }
      final completionCode = switch (provider) {
        SocialAuthProvider.google => 'auth-google-firebase-credential-complete',
        SocialAuthProvider.youtube =>
          'auth-youtube-shared-google-firebase-credential-complete',
        SocialAuthProvider.apple => 'auth-apple-firebase-credential-complete',
        SocialAuthProvider.x ||
        SocialAuthProvider.instagram ||
        SocialAuthProvider.facebook => throw StateError('Handled above.'),
      };
      return SocialAuthResult.authenticated(
        authenticatedUserId,
        code: completionCode,
      );
    } on FirebaseAuthException catch (error) {
      final failure = sanitizedFirebaseAuthFailure(
        error.code,
        providerLabel: _providerLabel(provider),
      );
      if (provider == SocialAuthProvider.google ||
          provider == SocialAuthProvider.youtube) {
        _googleStageObserver(
          'auth-google-firebase-exception-code-'
          '${_safeFirebaseAuthExceptionCode(error.code)}',
        );
        _googleStageObserver(
          'auth-google-firebase-cause-'
          '${_safeFirebaseAuthCauseCategory(code: error.code, message: error.message)}',
        );
      }
      if (failure.failureClass == PublicAuthFailureClass.cancelled) {
        if (provider == SocialAuthProvider.google ||
            provider == SocialAuthProvider.youtube) {
          _googleStageObserver('auth-google-firebase-cancelled');
        }
        return SocialAuthResult.cancelled(code: failure.code);
      }
      if (provider == SocialAuthProvider.google ||
          provider == SocialAuthProvider.youtube) {
        _googleStageObserver('auth-google-firebase-credential-failed');
      }
      throw JourneyServiceException(failure.publicMessage, code: failure.code);
    } on JourneyServiceException {
      rethrow;
    } on Object {
      throw JourneyServiceException(
        'The account provider did not respond. Check the connection and try again.',
        code: 'auth-${provider.name}-unexpected',
      );
    }
  }

  @override
  SocialAuthProvider? providerForCallback(Uri callbackUri) {
    final xRecognized = _xAdapter?.recognizesCallback(callbackUri) ?? false;
    final instagramRecognized =
        _instagramAdapter?.recognizesCallback(callbackUri) ?? false;
    if (xRecognized == instagramRecognized) return null;
    return xRecognized ? SocialAuthProvider.x : SocialAuthProvider.instagram;
  }

  @override
  Future<SocialAuthResult> completeForegroundCallback(Uri callbackUri) =>
      _completeBrokeredCallback(callbackUri, coldStart: false);

  @override
  Future<SocialAuthResult> completeColdStartCallback(Uri callbackUri) =>
      _completeBrokeredCallback(callbackUri, coldStart: true);

  Future<SocialAuthResult> _completeBrokeredCallback(
    Uri callbackUri, {
    required bool coldStart,
  }) async {
    final provider = providerForCallback(callbackUri);
    if (provider == null) {
      throw _configurationFailure('The account provider');
    }
    final result = switch (provider) {
      SocialAuthProvider.x =>
        coldStart
            ? await _xAdapter!.completeColdStartCallback(callbackUri)
            : await _xAdapter!.completeForegroundCallback(callbackUri),
      SocialAuthProvider.instagram =>
        coldStart
            ? await _instagramAdapter!.completeColdStartCallback(callbackUri)
            : await _instagramAdapter!.completeForegroundCallback(callbackUri),
      SocialAuthProvider.google ||
      SocialAuthProvider.youtube ||
      SocialAuthProvider.apple ||
      SocialAuthProvider.facebook => throw StateError(
        'Only brokered providers own callbacks.',
      ),
    };
    return _brokeredResult(result, allowAuthorizationPending: false);
  }

  SocialAuthResult _brokeredResult(
    BrokeredPublicAuthResult result, {
    required bool allowAuthorizationPending,
  }) {
    switch (result.outcome) {
      case BrokeredPublicAuthOutcome.browserOpened:
        if (allowAuthorizationPending) {
          return SocialAuthResult.authorizationPending(code: result.code);
        }
        throw _configurationFailure('The account provider');
      case BrokeredPublicAuthOutcome.authenticated:
        final userId = result.userId;
        if (userId == null || userId.isEmpty) {
          throw const JourneyServiceException(
            'Sign-in could not be completed. Please try again.',
            code: 'auth-invalid-credential',
          );
        }
        return SocialAuthResult.authenticated(userId, code: result.code);
      case BrokeredPublicAuthOutcome.cancelled:
        return SocialAuthResult.cancelled(code: result.code);
      case BrokeredPublicAuthOutcome.denied:
      case BrokeredPublicAuthOutcome.expired:
      case BrokeredPublicAuthOutcome.replayRejected:
      case BrokeredPublicAuthOutcome.accountIneligible:
      case BrokeredPublicAuthOutcome.configurationFailure:
      case BrokeredPublicAuthOutcome.networkFailure:
      case BrokeredPublicAuthOutcome.timeout:
      case BrokeredPublicAuthOutcome.providerFailure:
        throw JourneyServiceException(result.publicMessage, code: result.code);
    }
  }

  SocialAuthResult _facebookResult(FacebookLoginResult result) {
    final outcome = result.outcome;
    if (outcome == FacebookLoginOutcome.cancelled) {
      return SocialAuthResult.cancelled(code: result.safeCode);
    }
    if (outcome == FacebookLoginOutcome.success) {
      final userId = _authClient.currentUserId;
      if (userId != null && userId.isNotEmpty) {
        return SocialAuthResult.authenticated(userId, code: result.safeCode);
      }
      throw const JourneyServiceException(
        'Facebook sign-in could not confirm the account. Please try again.',
        code: 'auth-facebook-session-missing',
      );
    }
    throw JourneyServiceException(outcome.safeMessage, code: result.safeCode);
  }

  JourneyServiceException _configurationFailure(String providerLabel) =>
      JourneyServiceException(
        '$providerLabel sign-in is not available right now. '
        'Choose another method.',
        code: 'auth-provider-configuration',
      );

  @override
  Future<void> signOut() async {
    Object? firstFailure;
    StackTrace? firstFailureStackTrace;
    try {
      await _authClient.signOut();
    } on Object catch (error, stackTrace) {
      firstFailure = error;
      firstFailureStackTrace = stackTrace;
    }
    try {
      await _googleIdentityGateway.signOut();
    } on Object catch (error, stackTrace) {
      firstFailure ??= error;
      firstFailureStackTrace ??= stackTrace;
    }
    final facebookAdapter = _facebookAdapter;
    if (facebookAdapter != null && facebookAdapter.isConfigured) {
      try {
        final outcome = await facebookAdapter.logOut();
        if (outcome != FacebookLoginOutcome.success) {
          throw JourneyServiceException(
            outcome.safeMessage,
            code: 'auth-provider-unavailable',
          );
        }
      } on Object catch (error, stackTrace) {
        firstFailure ??= error;
        firstFailureStackTrace ??= stackTrace;
      }
    }
    if (firstFailure case final failure?) {
      Error.throwWithStackTrace(failure, firstFailureStackTrace!);
    }
  }

  Future<String?> _signInWithGoogleIdentity() async {
    try {
      _googleStageObserver('auth-google-native-request-started');
      final idToken = await _googleIdentityGateway.authenticateIdToken();
      if (idToken == null) {
        _googleStageObserver('auth-google-native-no-identity');
        return null;
      }
      _googleStageObserver('auth-google-firebase-credential-started');
      final userId = await _authClient
          .signInWithGoogleIdToken(idToken)
          .timeout(firebaseCredentialTimeout);
      _googleStageObserver('auth-google-firebase-credential-complete');
      return userId;
    } on TimeoutException {
      _googleStageObserver('auth-google-firebase-credential-timeout');
      throw const JourneyServiceException(
        'Google sign-in could not confirm the account in time. Please try again.',
        code: 'auth-firebase-credential-timeout',
      );
    } on FirebaseAuthException {
      rethrow;
    } on JourneyServiceException {
      _googleStageObserver('auth-google-native-request-failed');
      rethrow;
    }
  }

  String _providerLabel(SocialAuthProvider provider) => switch (provider) {
    SocialAuthProvider.google || SocialAuthProvider.youtube => 'Google',
    SocialAuthProvider.apple => 'Apple',
    SocialAuthProvider.x => 'X',
    SocialAuthProvider.instagram => 'Instagram',
    SocialAuthProvider.facebook => 'Facebook',
  };
}

class HttpEmailOtpGateway implements EmailOtpGateway {
  HttpEmailOtpGateway(
    this._auth, {
    required String apiBaseUrl,
    HttpClient? client,
  }) : _baseUri = Uri.tryParse(apiBaseUrl),
       _client = client ?? HttpClient();

  final FirebaseAuth _auth;
  final Uri? _baseUri;
  final HttpClient _client;
  String? _attemptId;

  @override
  Future<void> requestCode(String emailAddress) async {
    final payload = await _postJson('/v1/auth/otp/request', {
      'channel': 'email',
      'target': emailAddress,
    });
    final attemptId = payload['otpAttemptId']?.toString();
    if (attemptId == null || attemptId.isEmpty) {
      throw const JourneyServiceException(
        'The verification service did not return a valid request. Please try again.',
      );
    }
    _attemptId = attemptId;
  }

  @override
  Future<String?> reviewCodeFor(String emailAddress) async => null;

  @override
  Future<String> verifyCode(String code) async {
    final attemptId = _attemptId;
    if (attemptId == null) {
      throw const JourneyServiceException(
        'Request a new verification code and try again.',
      );
    }
    final payload = await _postJson('/v1/auth/otp/verify', {
      'otpAttemptId': attemptId,
      'code': code,
      'channel': 'email',
    });
    final customToken = payload['firebaseCustomToken']?.toString();
    if (customToken == null || customToken.isEmpty) {
      throw const JourneyServiceException(
        'We could not finish verification. Please try again.',
      );
    }
    try {
      final credential = await _auth.signInWithCustomToken(customToken);
      final user = credential.user;
      if (user == null) {
        throw const JourneyServiceException(
          'We could not finish verification. Please try again.',
        );
      }
      return user.uid;
    } on FirebaseAuthException catch (error) {
      final failure = sanitizedFirebaseAuthFailure(
        error.code,
        providerLabel: 'Email',
      );
      throw JourneyServiceException(failure.publicMessage, code: failure.code);
    }
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, Object?> body,
  ) async {
    final baseUri = _baseUri;
    if (baseUri == null || !baseUri.hasScheme || !baseUri.hasAuthority) {
      throw const JourneyServiceException(
        'Email OTP is not available right now. Choose another method.',
      );
    }
    try {
      final request = await _client
          .postUrl(baseUri.resolve(path))
          .timeout(const Duration(seconds: 10));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );
      final responseBody = await utf8.decoder.bind(response).join();
      final decoded = responseBody.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(responseBody) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const JourneyServiceException(
          'Email verification could not be completed. Please try again.',
          code: 'email-verification-rejected',
        );
      }
      return decoded;
    } on JourneyServiceException {
      rethrow;
    } on SocketException {
      throw const JourneyServiceException(
        'You appear to be offline. Reconnect and try again.',
      );
    } on TimeoutException {
      throw const JourneyServiceException(
        'The verification service did not respond. Please try again.',
      );
    } on Object {
      throw const JourneyServiceException(
        'Email verification could not be completed. Please try again.',
      );
    }
  }
}

class FirebaseEmailLinkGateway implements EmailLinkGateway {
  FirebaseEmailLinkGateway(
    this._auth, {
    required String continueUrl,
    String? linkDomain,
  }) : _actionCodeSettings = ActionCodeSettings(
         url: continueUrl,
         handleCodeInApp: true,
         androidPackageName: 'com.moolsocial.app',
         androidInstallApp: true,
         androidMinimumVersion: '1',
         linkDomain: linkDomain?.trim().isEmpty == true
             ? null
             : linkDomain?.trim(),
       );

  final FirebaseAuth _auth;
  final ActionCodeSettings _actionCodeSettings;

  @override
  Future<void> sendSignInLink(String emailAddress) async {
    try {
      await _auth.sendSignInLinkToEmail(
        email: emailAddress,
        actionCodeSettings: _actionCodeSettings,
      );
    } on FirebaseAuthException catch (error) {
      throw _emailLinkError(error);
    } on PlatformException catch (error) {
      throw sanitizedEmailLinkFailure(error.code);
    } on Object {
      throw const JourneyServiceException(
        'Email sign-in could not reach the device authentication service.',
        code: 'email-link-bridge-failure',
      );
    }
  }

  @override
  bool isSignInLink(String emailLink) => _auth.isSignInWithEmailLink(emailLink);

  @override
  Future<String> signInWithEmailLink({
    required String emailAddress,
    required String emailLink,
  }) async {
    try {
      final credential = await _auth.signInWithEmailLink(
        email: emailAddress,
        emailLink: emailLink,
      );
      final user = credential.user;
      if (user == null) {
        throw const JourneyServiceException(
          'Sign-in could not be completed. Request a new link.',
          code: 'email-link-missing-user',
        );
      }
      return user.uid;
    } on FirebaseAuthException catch (error) {
      throw _emailLinkError(error);
    } on PlatformException catch (error) {
      throw sanitizedEmailLinkFailure(error.code);
    } on Object {
      throw const JourneyServiceException(
        'Email sign-in could not reach the device authentication service.',
        code: 'email-link-bridge-failure',
      );
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  JourneyServiceException _emailLinkError(FirebaseAuthException error) {
    return sanitizedEmailLinkFailure(error.code);
  }
}

JourneyServiceException sanitizedEmailLinkFailure(String code) {
  final normalizedCode = code.trim().toLowerCase();
  final safeCode =
      normalizedCode.length <= 64 &&
          RegExp(r'^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$').hasMatch(normalizedCode)
      ? normalizedCode
      : null;
  if (safeCode == null) {
    return const JourneyServiceException(
      'Email sign-in could not be classified safely. Please try again.',
      code: 'email-link-firebase-unclassified',
    );
  }

  final message = switch (safeCode) {
    'expired-action-code' =>
      'This sign-in link has expired. Request a new link.',
    'invalid-action-code' =>
      'This sign-in link is invalid or has already been used. Request a new link.',
    'invalid-email' ||
    'invalid-recipient-email' ||
    'missing-email' => 'Enter the email address that received this link.',
    'user-disabled' =>
      'This account cannot sign in right now. Choose another method.',
    'operation-not-allowed' =>
      'Email link sign-in is not available right now. Choose another method.',
    'too-many-requests' =>
      'Too many attempts. Wait a moment before trying again.',
    'network-request-failed' || 'web-network-request-failed' =>
      'Email sign-in could not connect. Check your connection and retry.',
    'invalid-continue-uri' ||
    'missing-continue-uri' ||
    'unauthorized-continue-uri' ||
    'unauthorized-domain' ||
    'missing-android-pkg-name' ||
    'dynamic-link-not-activated' ||
    'invalid-dynamic-link-domain' =>
      'Email link sign-in is not available right now. Choose another method.',
    'internal-error' || 'web-internal-error' =>
      'Email sign-in is temporarily unavailable. Please try again.',
    _ => 'Email sign-in could not be completed. Please try again.',
  };
  return JourneyServiceException(message, code: safeCode);
}

class SharedPreferencesReviewEmailOtpGateway implements EmailOtpGateway {
  SharedPreferencesReviewEmailOtpGateway(
    this._preferences, {
    this.acceptedCode = '123456',
  });

  final SharedPreferences _preferences;
  final String acceptedCode;
  String? _emailAddress;

  @override
  Future<void> requestCode(String emailAddress) async {
    _emailAddress = emailAddress;
  }

  @override
  Future<String?> reviewCodeFor(String emailAddress) async => acceptedCode;

  @override
  Future<String> verifyCode(String code) async {
    if (_emailAddress == null) {
      throw const JourneyServiceException(
        'Request a new verification code and try again.',
      );
    }
    if (code != acceptedCode) {
      throw const JourneyServiceException(
        'That code is not valid. Check it and try again.',
      );
    }
    const userId = 'review-email-user';
    await _preferences.setString(reviewAuthenticatedUserPreferenceKey, userId);
    return userId;
  }
}

class DeviceLocationPermissionGateway implements LocationPermissionGateway {
  @override
  Future<LocationPermissionResult> requestWhenInUse() async {
    return _mapStatus(await Permission.locationWhenInUse.request());
  }

  @override
  Future<LocationPermissionResult> checkWhenInUse() async {
    return _mapStatus(await Permission.locationWhenInUse.status);
  }

  LocationPermissionResult _mapStatus(PermissionStatus status) {
    if (status.isGranted || status.isLimited) {
      return LocationPermissionResult.granted;
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      return LocationPermissionResult.permanentlyDenied;
    }
    return LocationPermissionResult.denied;
  }
}

class DeviceCurrentAreaGateway implements CurrentAreaGateway {
  DeviceCurrentAreaGateway({
    LocationPermissionGateway? permissionGateway,
    MethodChannel? channel,
  }) : _permissionGateway =
           permissionGateway ?? DeviceLocationPermissionGateway(),
       _channel =
           channel ?? const MethodChannel('com.moolsocial.app/current_area');

  final LocationPermissionGateway _permissionGateway;
  final MethodChannel _channel;

  @override
  Future<ResolvedCurrentArea> resolve({bool requestPermission = true}) async {
    final permission = requestPermission
        ? await _permissionGateway.requestWhenInUse()
        : await _permissionGateway.checkWhenInUse();
    switch (permission) {
      case LocationPermissionResult.granted:
        break;
      case LocationPermissionResult.denied:
        throw const CurrentAreaException(
          CurrentAreaFailureReason.permissionNotAllowed,
        );
      case LocationPermissionResult.permanentlyDenied:
        throw const CurrentAreaException(
          CurrentAreaFailureReason.permissionPermanentlyNotAllowed,
        );
    }

    Map<String, dynamic>? value;
    try {
      value = await _channel.invokeMapMethod<String, dynamic>(
        'resolveCurrentArea',
      );
    } on PlatformException catch (error) {
      if (error.code == 'location_services_off') {
        throw const CurrentAreaException(
          CurrentAreaFailureReason.locationServicesOff,
        );
      }
      throw const CurrentAreaException(CurrentAreaFailureReason.unavailable);
    }
    if (value == null) {
      throw const CurrentAreaException(CurrentAreaFailureReason.unavailable);
    }

    final subLocality = _clean(value['subLocality']);
    final locality = _clean(value['locality']);
    final district = _clean(value['subAdminArea']);
    final region = _clean(value['adminArea']);
    final primary = subLocality ?? locality ?? district ?? region;
    if (primary == null) {
      throw const CurrentAreaException(CurrentAreaFailureReason.unavailable);
    }

    final secondaryParts = <String>[
      if (locality != null && locality != primary) locality,
      if (region != null && region != primary) region,
    ];
    final secondary = secondaryParts.isEmpty
        ? 'Nearby results are ready'
        : secondaryParts.toSet().join(', ');
    final fullParts = <String>[primary, ...secondaryParts];

    return ResolvedCurrentArea(
      primaryLabel: primary,
      secondaryLabel: secondary,
      fullLabel: fullParts.toSet().join(', '),
    );
  }

  @override
  Future<void> openLocationServicesSettings() async {
    await _channel.invokeMethod<void>('openLocationServicesSettings');
  }

  @override
  Future<void> openAppSettings() async {
    await permission_handler.openAppSettings();
  }

  String? _clean(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}

class FirebaseAuthenticatedSessionBootstrapGateway
    implements AccountBootstrapGateway {
  FirebaseAuthenticatedSessionBootstrapGateway(FirebaseAuth auth)
    : this._(
        interactiveVerifiedUserId: () async {
          final user = auth.currentUser;
          if (user == null) return null;
          final token = await user.getIdToken();
          if (token == null || token.trim().isEmpty) return null;
          return user.uid;
        },
        revalidatedUserId: () async {
          final user = auth.currentUser;
          if (user == null) return null;
          await user.reload();
          final refreshed = auth.currentUser;
          if (refreshed == null) return null;
          final token = await refreshed.getIdToken();
          if (token == null || token.trim().isEmpty) return null;
          return refreshed.uid;
        },
      );

  @visibleForTesting
  FirebaseAuthenticatedSessionBootstrapGateway.forTesting({
    required Future<String?> Function() verifiedUserId,
    Future<String?> Function()? interactiveVerifiedUserId,
  }) : this._(
         interactiveVerifiedUserId: interactiveVerifiedUserId ?? verifiedUserId,
         revalidatedUserId: verifiedUserId,
       );

  FirebaseAuthenticatedSessionBootstrapGateway._({
    required this._interactiveVerifiedUserId,
    required this._revalidatedUserId,
  });

  final Future<String?> Function() _interactiveVerifiedUserId;
  final Future<String?> Function() _revalidatedUserId;

  @override
  Future<void> prepareAuthenticatedAccount({String? expectedUserId}) async {
    try {
      final expected = expectedUserId?.trim();
      final userId = expected == null || expected.isEmpty
          ? await _revalidatedUserId()
          : await _interactiveVerifiedUserId();
      if (userId == null || userId.trim().isEmpty) {
        throw const JourneyServiceException(
          'Your signed-in account could not be verified. Please sign in again.',
          code: 'auth-session-missing',
        );
      }
      if (expected != null && expected.isNotEmpty && userId != expected) {
        throw const JourneyServiceException(
          'Your signed-in account changed before it could be verified. Please sign in again.',
          code: 'auth-session-user-mismatch',
        );
      }
    } on JourneyServiceException {
      rethrow;
    } on Object {
      throw const JourneyServiceException(
        'Your account session could not be verified. '
        'Check the connection and try again.',
        code: 'auth-session-verification',
      );
    }
  }
}

class DataConnectAccountBootstrapGateway implements AccountBootstrapGateway {
  DataConnectAccountBootstrapGateway({String? emulatorHost, this.port = 9399}) {
    if (emulatorHost != null) {
      MobileConnector.instance.dataConnect.useDataConnectEmulator(
        emulatorHost,
        port,
      );
    }
  }

  final int port;

  @override
  Future<void> prepareAuthenticatedAccount({String? expectedUserId}) async {
    await MobileConnector.instance.upsertMyAccount().execute();
  }
}
