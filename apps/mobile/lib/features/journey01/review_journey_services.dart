import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/generated/mobile.dart';
import 'journey_services.dart';

class SharedPreferencesJourneyStore implements JourneyStore {
  SharedPreferencesJourneyStore(this._preferences);

  static const _languageKey = 'journey01.language';
  static const _areaModeKey = 'journey01.area_mode';
  static const _areaLabelKey = 'journey01.area_label';
  static const _setupCompleteKey = 'journey01.setup_complete';
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
      setupComplete: _preferences.getBool(_setupCompleteKey) ?? false,
      pendingRoute: _preferences.getString(_pendingRouteKey),
    );
  }

  @override
  Future<void> write(JourneySnapshot snapshot) async {
    await _preferences.setString(_languageKey, snapshot.languageCode);
    await _preferences.setBool(_setupCompleteKey, snapshot.setupComplete);
    await _setNullable(_areaModeKey, snapshot.areaMode);
    await _setNullable(_areaLabelKey, snapshot.areaLabel);
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
    this.emulatorProjectId,
    this.emulatorApiKey = 'demo-moolsocial-local-key',
    this.emulatorPort = 9099,
    this.directEmulatorAuth = false,
  });

  final FirebaseAuth _auth;
  final String? emulatorHost;
  final String emulatorApiKey;
  final int emulatorPort;
  final String? emulatorProjectId;
  final bool directEmulatorAuth;

  String? _verificationId;
  int? _resendToken;
  String? _directEmulatorUserId;

  @override
  Future<bool> hasAuthenticatedUser() async =>
      _directEmulatorUserId != null || _auth.currentUser != null;

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
    final host = emulatorHost;
    if (host == null) {
      throw const JourneyServiceException(
        'The verification service is unavailable. Please retry.',
      );
    }

    final client = HttpClient();
    try {
      final uri = Uri.http(
        '$host:$emulatorPort',
        '/identitytoolkit.googleapis.com/v1/accounts:sendVerificationCode',
        {'key': emulatorApiKey},
      );
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({'phoneNumber': phoneNumber}));
      final response = await request.close();
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
      throw const JourneyServiceException(
        'You appear to be offline. Reconnect and retry.',
      );
    } on Object {
      throw const JourneyServiceException(
        'The verification service did not respond. Please retry.',
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<String> _verifyEmulatorCode(String code) async {
    final host = emulatorHost;
    final sessionInfo = _verificationId;
    if (host == null || sessionInfo == null) {
      throw const JourneyServiceException(
        'Request a new verification code and try again.',
      );
    }

    final client = HttpClient();
    try {
      final uri = Uri.http(
        '$host:$emulatorPort',
        '/identitytoolkit.googleapis.com/v1/accounts:signInWithPhoneNumber',
        {'key': emulatorApiKey},
      );
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({'sessionInfo': sessionInfo, 'code': code}));
      final response = await request.close();
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode != HttpStatus.ok) {
        final payload = jsonDecode(body) as Map<String, dynamic>;
        final message =
            ((payload['error'] as Map<String, dynamic>?)?['message'] as String?)
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
      return userId;
    } on JourneyServiceException {
      rethrow;
    } on SocketException {
      throw const JourneyServiceException(
        'You appear to be offline. Reconnect and retry.',
      );
    } on Object {
      throw const JourneyServiceException(
        'Verification could not be completed. Please retry.',
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<({String code, String sessionInfo})?> _latestEmulatorVerification(
    String phoneNumber,
  ) async {
    final host = emulatorHost;
    final projectId = emulatorProjectId;
    if (host == null || projectId == null) return null;

    final client = HttpClient();
    try {
      final request = await client.getUrl(
        Uri.parse(
          'http://$host:$emulatorPort/emulator/v1/projects/$projectId/'
          'verificationCodes',
        ),
      );
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) return null;
      final body = await utf8.decoder.bind(response).join();
      final payload = jsonDecode(body) as Map<String, dynamic>;
      final codes = payload['verificationCodes'] as List<dynamic>? ?? const [];
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
      return null;
    } on Object {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<void> signOut() async {
    _directEmulatorUserId = null;
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
        'You appear to be offline. Reconnect and retry.',
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

class DeviceLocationPermissionGateway implements LocationPermissionGateway {
  @override
  Future<LocationPermissionResult> requestWhenInUse() async {
    final status = await Permission.locationWhenInUse.request();
    if (status.isGranted || status.isLimited) {
      return LocationPermissionResult.granted;
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      return LocationPermissionResult.permanentlyDenied;
    }
    return LocationPermissionResult.denied;
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
