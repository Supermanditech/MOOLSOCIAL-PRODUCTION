import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/moolsocial_app.dart';
import 'features/journey01/journey_session.dart';
import 'features/journey01/review_journey_services.dart';

const _localFirebaseOptions = FirebaseOptions(
  apiKey: 'demo-moolsocial-local-key',
  appId: '1:100000000001:android:moolsocial-local',
  messagingSenderId: '100000000001',
  projectId: 'demo-moolsocial-local',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: _localFirebaseOptions);

  const emulatorHost = String.fromEnvironment(
    'MOOLSOCIAL_EMULATOR_HOST',
    defaultValue: '127.0.0.1',
  );
  await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);

  final preferences = await SharedPreferences.getInstance();
  final session = JourneySession(
    store: SharedPreferencesJourneyStore(preferences),
    otpGateway: FirebaseEmulatorOtpGateway(
      FirebaseAuth.instance,
      host: emulatorHost,
      projectId: _localFirebaseOptions.projectId,
    ),
    accountBootstrapGateway: DataConnectAccountBootstrapGateway(
      host: emulatorHost,
    ),
    locationGateway: DeviceLocationPermissionGateway(),
  );

  runApp(MoolSocialApp(session: session, disposeSession: true));
}
