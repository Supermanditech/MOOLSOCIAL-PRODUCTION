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

class FirebaseEmulatorOtpGateway implements OtpGateway {
  FirebaseEmulatorOtpGateway(
    this._auth, {
    required this.host,
    required this.projectId,
    this.port = 9099,
  });

  final FirebaseAuth _auth;
  final String host;
  final int port;
  final String projectId;

  String? _verificationId;
  int? _resendToken;

  @override
  Future<bool> hasAuthenticatedUser() async => _auth.currentUser != null;

  @override
  Future<OtpRequestResult> requestCode(String phoneNumber) async {
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

    return completer.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () => throw const JourneyServiceException(
        'The verification service did not respond. Check the connection and retry.',
      ),
    );
  }

  @override
  Future<String> verifyCode(String code) async {
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
    final client = HttpClient();
    try {
      final request = await client.getUrl(
        Uri.parse(
          'http://$host:$port/emulator/v1/projects/$projectId/'
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
          return (code['code'] ?? code['sessionCode']) as String?;
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
  Future<void> signOut() => _auth.signOut();

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
  DataConnectAccountBootstrapGateway({required String host, this.port = 9399}) {
    MobileConnector.instance.dataConnect.useDataConnectEmulator(host, port);
  }

  final int port;

  @override
  Future<void> prepareAuthenticatedAccount() async {
    await MobileConnector.instance.upsertMyAccount().execute();
  }
}
