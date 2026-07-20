import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:permission_handler/permission_handler.dart'
    as permission_handler
    show openAppSettings;
import 'package:shared_preferences/shared_preferences.dart';

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
  }

  Future<void> _setNullable(String key, String? value) async {
    if (value == null || value.isEmpty) {
      await _preferences.remove(key);
    } else {
      await _preferences.setString(key, value);
    }
  }
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

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      forceResendingToken: _resendToken,
      verificationCompleted: (credential) async {
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
        }
      },
      verificationFailed: (error) {
        if (!completer.isCompleted) {
          completer.completeError(_friendlyAuthError(error));
        }
      },
      codeSent: (verificationId, resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        if (!completer.isCompleted) {
          completer.complete(const OtpRequestResult());
        }
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
      },
    );

    if (_usesEmulatorReview) {
      unawaited(
        _completeFromEmulator(phoneNumber, completer, previousEmulatorSession),
      );
    }
    return completer.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () => throw const JourneyServiceException(
        'The verification service did not respond. Check the connection and retry.',
      ),
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
      _ => JourneyServiceException(
        error.message ?? 'Verification could not be completed. Please retry.',
      ),
    };
  }
}

class FirebaseSocialAuthGateway implements SocialAuthGateway {
  FirebaseSocialAuthGateway(this._auth);

  final FirebaseAuth _auth;

  @override
  Future<bool> hasAuthenticatedUser() async => _auth.currentUser != null;

  @override
  Future<SocialAuthResult> signIn(SocialAuthProvider provider) async {
    if (provider == SocialAuthProvider.instagram) {
      throw const JourneyServiceException(
        'Instagram sign-in is not available right now. Choose another method.',
      );
    }

    final authProvider = switch (provider) {
      SocialAuthProvider.google ||
      SocialAuthProvider.youtube => GoogleAuthProvider(),
      SocialAuthProvider.apple => AppleAuthProvider(),
      SocialAuthProvider.x => TwitterAuthProvider(),
      SocialAuthProvider.facebook => FacebookAuthProvider(),
      SocialAuthProvider.instagram => throw StateError('Handled above.'),
    };

    try {
      final credential = await _auth.signInWithProvider(authProvider);
      final user = credential.user;
      if (user == null) {
        throw const JourneyServiceException(
          'Sign-in could not be completed. Please try again.',
        );
      }
      return SocialAuthResult.authenticated(user.uid);
    } on FirebaseAuthException catch (error) {
      if (_isCancelled(error.code)) return const SocialAuthResult.cancelled();
      throw _friendlySocialAuthError(error);
    } on JourneyServiceException {
      rethrow;
    } on Object {
      throw const JourneyServiceException(
        'The account provider did not respond. Check the connection and try again.',
      );
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  bool _isCancelled(String code) {
    return const {
      'canceled',
      'cancelled',
      'popup-closed-by-user',
      'web-context-cancelled',
      'user-cancelled',
    }.contains(code);
  }

  JourneyServiceException _friendlySocialAuthError(
    FirebaseAuthException error,
  ) {
    return switch (error.code) {
      'account-exists-with-different-credential' => const JourneyServiceException(
        'This account already uses another sign-in method. Choose that method to continue.',
      ),
      'network-request-failed' => const JourneyServiceException(
        'You appear to be offline. Reconnect and try again.',
      ),
      'operation-not-allowed' ||
      'provider-already-linked' ||
      'invalid-oauth-provider' => const JourneyServiceException(
        'This sign-in method is not available right now. Choose another method.',
      ),
      'too-many-requests' => const JourneyServiceException(
        'Too many attempts. Wait a moment before trying again.',
      ),
      _ => JourneyServiceException(
        error.message ?? 'Sign-in could not be completed. Please try again.',
      ),
    };
  }
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
      throw JourneyServiceException(
        error.message ?? 'We could not finish verification. Please try again.',
      );
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
        final message =
            decoded['userMessage']?.toString() ??
            decoded['message']?.toString() ??
            'Email verification could not be completed. Please try again.';
        throw JourneyServiceException(message);
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
  Future<void> prepareAuthenticatedAccount() async {
    await MobileConnector.instance.upsertMyAccount().execute();
  }
}
