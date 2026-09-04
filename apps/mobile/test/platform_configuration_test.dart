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

  test(
    'Android sharing keeps MoolSocial and the destination in separate tasks',
    () {
      final activity = File(
        'android/app/src/main/kotlin/com/moolsocial/app/MainActivity.kt',
      ).readAsStringSync();
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      final shareStart = activity.indexOf('private fun shareInSeparateTask');
      final shareEnd = activity.indexOf(
        'private fun shareMimeType',
        shareStart,
      );

      expect(shareStart, greaterThanOrEqualTo(0));
      expect(shareEnd, greaterThan(shareStart));
      final shareOwner = activity.substring(shareStart, shareEnd);
      expect(activity, contains('"dev.fluttercommunity.plus/share"'));
      expect(activity, contains('"share" -> shareInSeparateTask'));
      expect(shareOwner, contains('Intent.createChooser(sendIntent, title)'));
      expect(shareOwner, contains('Intent.FLAG_ACTIVITY_NEW_TASK'));
      expect(shareOwner, contains('startActivity(chooserIntent)'));
      expect(shareOwner, isNot(contains('startActivityForResult')));
      expect(shareOwner, contains('Intent.EXTRA_TEXT'));
      expect(shareOwner, contains('Intent.EXTRA_STREAM'));
      expect(shareOwner, contains('Intent.FLAG_GRANT_READ_URI_PERMISSION'));
      expect(activity, contains('externalShareLeftActivity = true'));
      expect(activity, contains('override fun onResume()'));
      expect(
        activity,
        contains('window.decorView.post { result.success("") }'),
      );
      expect(manifest, contains('android:launchMode="singleTop"'));
      expect(manifest, contains('android:taskAffinity=""'));
    },
  );

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

    expect(mainSource, contains("const _useEmulators = bool.fromEnvironment("));
    expect(mainSource, contains('defaultValue: kDebugMode'));
    expect(mainSource, contains('if (_useEmulators)'));
    expect(mainSource, contains('MOOLSOCIAL_DEVICE_REVIEW'));
    expect(
      mainSource,
      contains('isQualifiedDeviceReviewRuntimeMode('),
      reason:
          'Device review must continue through the shared qualified-runtime gate.',
    );
    expect(mainSource, contains('MOOLSOCIAL_FIREBASE_API_KEY'));
    expect(mainSource, contains('MOOLSOCIAL_FIREBASE_APP_ID'));
    expect(mainSource, contains('MOOLSOCIAL_FIREBASE_MESSAGING_SENDER_ID'));
    expect(mainSource, contains('MOOLSOCIAL_FIREBASE_PROJECT_ID'));
    expect(
      mainSource,
      contains('if (!_releaseRuntimeConfiguration.isComplete)'),
      reason:
          'A release must fail closed instead of silently using demo services.',
    );
    expect(
      mainSource,
      contains("_showReleaseBootstrapFailure('release_configuration')"),
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
