import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/moolsocial_app.dart';
import 'features/journey01/journey_services.dart';
import 'features/journey01/journey_session.dart';
import 'features/journey01/review_journey_services.dart';

const _localFirebaseOptions = FirebaseOptions(
  apiKey: 'demo-moolsocial-local-key',
  appId: '1:100000000001:android:moolsocial-local',
  messagingSenderId: '100000000001',
  projectId: 'demo-moolsocial-local',
);

const _useEmulators = bool.fromEnvironment(
  'MOOLSOCIAL_USE_EMULATORS',
  defaultValue: kDebugMode,
);
const _deviceReviewMode = bool.fromEnvironment('MOOLSOCIAL_DEVICE_REVIEW');

const _firebaseApiKey = String.fromEnvironment('MOOLSOCIAL_FIREBASE_API_KEY');
const _firebaseAppId = String.fromEnvironment('MOOLSOCIAL_FIREBASE_APP_ID');
const _firebaseMessagingSenderId = String.fromEnvironment(
  'MOOLSOCIAL_FIREBASE_MESSAGING_SENDER_ID',
);
const _firebaseProjectId = String.fromEnvironment(
  'MOOLSOCIAL_FIREBASE_PROJECT_ID',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _validateRuntimeMode();
  final firebaseOptions = _firebaseOptions();
  await Firebase.initializeApp(options: firebaseOptions);

  const emulatorHost = String.fromEnvironment(
    'MOOLSOCIAL_EMULATOR_HOST',
    defaultValue: '127.0.0.1',
  );
  if (_useEmulators) {
    await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
  }

  final preferences = await SharedPreferences.getInstance();
  final session = JourneySession(
    store: SharedPreferencesJourneyStore(preferences),
    otpGateway: FirebaseOtpGateway(
      FirebaseAuth.instance,
      emulatorHost: _useEmulators ? emulatorHost : null,
      emulatorProjectId: _useEmulators ? firebaseOptions.projectId : null,
      emulatorApiKey: firebaseOptions.apiKey,
      directEmulatorAuth: _deviceReviewMode,
    ),
    accountBootstrapGateway: _deviceReviewMode
        ? ReviewAccountBootstrapGateway()
        : DataConnectAccountBootstrapGateway(
            emulatorHost: _useEmulators ? emulatorHost : null,
          ),
    locationGateway: DeviceLocationPermissionGateway(),
  );

  runApp(MoolSocialApp(session: session, disposeSession: true));
}

void _validateRuntimeMode() {
  if (_deviceReviewMode && !_useEmulators) {
    throw StateError(
      'Device review mode requires the isolated local emulator environment.',
    );
  }
}

FirebaseOptions _firebaseOptions() {
  if (_useEmulators) return _localFirebaseOptions;

  final requiredValues = <String, String>{
    'MOOLSOCIAL_FIREBASE_API_KEY': _firebaseApiKey,
    'MOOLSOCIAL_FIREBASE_APP_ID': _firebaseAppId,
    'MOOLSOCIAL_FIREBASE_MESSAGING_SENDER_ID': _firebaseMessagingSenderId,
    'MOOLSOCIAL_FIREBASE_PROJECT_ID': _firebaseProjectId,
  };
  final missing = requiredValues.entries
      .where((entry) => entry.value.trim().isEmpty)
      .map((entry) => entry.key)
      .toList(growable: false);
  if (missing.isNotEmpty) {
    throw StateError(
      'Release configuration is incomplete. Missing: ${missing.join(', ')}.',
    );
  }

  return const FirebaseOptions(
    apiKey: _firebaseApiKey,
    appId: _firebaseAppId,
    messagingSenderId: _firebaseMessagingSenderId,
    projectId: _firebaseProjectId,
  );
}
