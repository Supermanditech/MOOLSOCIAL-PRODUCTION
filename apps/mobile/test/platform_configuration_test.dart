import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android package and native permissions are production aligned', () {
    final buildFile = File('android/app/build.gradle.kts').readAsStringSync();
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(buildFile, contains('namespace = "com.moolsocial.app"'));
    expect(buildFile, contains('applicationId = "com.moolsocial.app"'));
    expect(
      manifest,
      contains('android.permission.INTERNET'),
      reason: 'Firebase and connected journeys require network access.',
    );
    expect(
      manifest,
      contains('android.permission.CAMERA'),
      reason: 'Scan and Pay must be able to request camera access.',
    );
    expect(
      manifest,
      contains('android.permission.RECORD_AUDIO'),
      reason: 'Voice search must be able to request microphone access.',
    );
    expect(
      File(
        'android/app/src/main/kotlin/com/moolsocial/app/MainActivity.kt',
      ).existsSync(),
      isTrue,
    );
  });

  test('iOS declares camera, microphone and speech permissions', () {
    final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();

    expect(infoPlist, contains('<key>NSCameraUsageDescription</key>'));
    expect(infoPlist, contains('<key>NSMicrophoneUsageDescription</key>'));
    expect(
      infoPlist,
      contains('<key>NSSpeechRecognitionUsageDescription</key>'),
    );
  });

  test('release builds require live Firebase configuration', () {
    final mainSource = File('lib/main.dart').readAsStringSync();

    expect(mainSource, contains("const _useEmulators = bool.fromEnvironment("));
    expect(mainSource, contains('defaultValue: kDebugMode'));
    expect(mainSource, contains('if (_useEmulators)'));
    expect(mainSource, contains('MOOLSOCIAL_DEVICE_REVIEW'));
    expect(
      mainSource,
      contains('Device review mode requires the isolated local emulator'),
    );
    expect(mainSource, contains('MOOLSOCIAL_FIREBASE_API_KEY'));
    expect(mainSource, contains('MOOLSOCIAL_FIREBASE_APP_ID'));
    expect(mainSource, contains('MOOLSOCIAL_FIREBASE_MESSAGING_SENDER_ID'));
    expect(mainSource, contains('MOOLSOCIAL_FIREBASE_PROJECT_ID'));
    expect(
      mainSource,
      contains('Release configuration is incomplete. Missing:'),
      reason:
          'A release must fail closed instead of silently using demo services.',
    );
  });

  test('OTP and Data Connect emulators are optional production boundaries', () {
    final servicesSource = File(
      'lib/features/journey01/review_journey_services.dart',
    ).readAsStringSync();

    expect(servicesSource, contains('class FirebaseOtpGateway'));
    expect(servicesSource, contains('String? emulatorHost'));
    expect(servicesSource, contains('_requestEmulatorCode'));
    expect(servicesSource, contains('_verifyEmulatorCode'));
    expect(servicesSource, contains('if (!_usesEmulatorReview) return null'));
    expect(servicesSource, contains('if (emulatorHost != null)'));
  });
}
