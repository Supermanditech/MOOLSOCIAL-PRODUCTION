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

  test('iOS identity, deployment target and permissions are aligned', () {
    final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();
    final project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    final frameworkInfo = File(
      'ios/Flutter/AppFrameworkInfo.plist',
    ).readAsStringSync();

    expect(infoPlist, contains('<key>NSCameraUsageDescription</key>'));
    expect(infoPlist, contains('<key>NSMicrophoneUsageDescription</key>'));
    expect(
      infoPlist,
      contains('<key>NSSpeechRecognitionUsageDescription</key>'),
    );
    expect(
      'PRODUCT_BUNDLE_IDENTIFIER = com.moolsocial.app;'
          .allMatches(project)
          .length,
      3,
    );
    expect(
      'IPHONEOS_DEPLOYMENT_TARGET = 15.0;'.allMatches(project).length,
      3,
      reason: 'Current Firebase Apple packages require iOS 15 or newer.',
    );
    expect(
      RegExp(
        r'<key>MinimumOSVersion</key>\s*<string>15\.0</string>',
      ).hasMatch(frameworkInfo),
      isTrue,
      reason: 'The framework minimum must be iOS 15 on every host newline.',
    );
  });

  test('release builds require live Firebase configuration', () {
    final mainSource = File('lib/main.dart').readAsStringSync();
    final configurationSource = File(
      'lib/core/config/release_runtime_configuration.dart',
    ).readAsStringSync();

    expect(mainSource, contains("const _useEmulators = bool.fromEnvironment("));
    expect(mainSource, contains('defaultValue: kDebugMode'));
    expect(mainSource, contains('if (_useEmulators)'));
    expect(mainSource, contains('MOOLSOCIAL_DEVICE_REVIEW'));
    expect(
      mainSource,
      contains('runApp(const ReleaseConfigurationFailureApp());'),
      reason: 'Invalid release setup must render a safe first frame.',
    );
    expect(configurationSource, contains('MOOLSOCIAL_FIREBASE_API_KEY'));
    expect(configurationSource, contains('MOOLSOCIAL_FIREBASE_APP_ID'));
    expect(
      configurationSource,
      contains('MOOLSOCIAL_FIREBASE_MESSAGING_SENDER_ID'),
    );
    expect(configurationSource, contains('MOOLSOCIAL_FIREBASE_PROJECT_ID'));
    expect(
      configurationSource,
      contains('MOOLSOCIAL_GOOGLE_SERVER_CLIENT_ID'),
      reason:
          'Google identity is part of the same fail-closed release contract.',
    );
    expect(
      mainSource.indexOf('runApp(const ReleaseConfigurationFailureApp());'),
      lessThan(mainSource.indexOf('Firebase.initializeApp')),
      reason: 'Configuration must be checked before Firebase bootstrap.',
    );
  });

  test('profile device-review builds retain candidate provenance markers', () {
    final mainSource = File('lib/main.dart').readAsStringSync();
    final journeySource = File(
      'lib/features/journey01/journey_session.dart',
    ).readAsStringSync();

    expect(
      mainSource,
      contains('if (kDebugMode || _deviceReviewMode)'),
      reason: 'Profile review builds must emit the exact candidate identity.',
    );
    expect(mainSource, contains('MOOLSOCIAL_CANDIDATE'));
    expect(
      journeySource,
      contains(
        "const _deviceReviewMode = bool.fromEnvironment('MOOLSOCIAL_DEVICE_REVIEW');",
      ),
    );
    expect(
      RegExp(
        r'if \(kDebugMode \|\| _deviceReviewMode\) \{\s*debugPrint\([\s\S]*?MOOLSOCIAL_STARTUP',
      ).allMatches(journeySource).length,
      2,
      reason: 'Ready and boot-failure startup outcomes must remain observable.',
    );
  });

  test('OTP and Data Connect emulators are optional production boundaries', () {
    final servicesSource = File(
      'lib/features/journey01/review_journey_services.dart',
    ).readAsStringSync();

    expect(servicesSource, contains('class FirebaseOtpGateway'));
    expect(servicesSource, contains('String? emulatorHost'));
    expect(servicesSource, contains('String? emulatorFallbackHost'));
    expect(servicesSource, contains('_requestEmulatorCode'));
    expect(servicesSource, contains('_verifyEmulatorCode'));
    expect(servicesSource, contains('if (!_usesEmulatorReview) return null'));
    expect(servicesSource, contains('if (emulatorHost != null)'));
  });

  test('mobile OTP never turns a review-route failure into an offline claim', () {
    final servicesSource = File(
      'lib/features/journey01/review_journey_services.dart',
    ).readAsStringSync();
    final mobileGatewaySource = servicesSource.substring(
      servicesSource.indexOf('class FirebaseOtpGateway'),
      servicesSource.indexOf('class FirebaseSocialAuthGateway'),
    );
    final mainSource = File('lib/main.dart').readAsStringSync();

    expect(
      mobileGatewaySource,
      isNot(contains('You appear to be offline')),
      reason:
          'A missing physical-device review route does not prove the customer is offline.',
    );
    expect(
      mobileGatewaySource,
      contains(
        'Mobile sign-in could not connect. Check your connection and try again.',
      ),
    );
    expect(mainSource, contains('MOOLSOCIAL_EMULATOR_FALLBACK_HOST'));
  });
}
