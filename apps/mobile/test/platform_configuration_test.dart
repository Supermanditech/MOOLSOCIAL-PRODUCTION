import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
    'Android sharing delegates attachments and results to the registered plugin',
    () {
      final activity = File(
        'android/app/src/main/kotlin/com/moolsocial/app/MainActivity.kt',
      ).readAsStringSync();
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      final registrant = File(
        'android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java',
      ).readAsStringSync();
      expect(
        registrant,
        contains('new dev.fluttercommunity.plus.share.SharePlusPlugin()'),
      );
      expect(activity, contains('super.configureFlutterEngine(flutterEngine)'));
      expect(
        activity,
        contains('super.onActivityResult(requestCode, resultCode, data)'),
      );
      expect(
        activity,
        isNot(contains('dev.fluttercommunity.plus/share')),
        reason: 'Do not replace the plugin result and attachment handler.',
      );
      expect(manifest, contains('android:launchMode="singleTop"'));
      expect(manifest, contains('android:taskAffinity=""'));
    },
  );

  group('Native share API contract', () {
    const channel = MethodChannel('dev.fluttercommunity.plus/share');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final calls = <MethodCall>[];
    String? nativeResult;

    setUp(() {
      calls.clear();
      nativeResult = null;
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return nativeResult;
      });
    });

    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    for (final scenario in <(String?, ShareResultStatus)>[
      (
        'com.google.android.gm/.ComposeActivityGmail',
        ShareResultStatus.success,
      ),
      ('com.whatsapp/.ContactPicker', ShareResultStatus.success),
      ('', ShareResultStatus.dismissed),
      (
        'dev.fluttercommunity.plus/share/unavailable',
        ShareResultStatus.unavailable,
      ),
      (null, ShareResultStatus.unavailable),
    ]) {
      test('preserves native result ${scenario.$1 ?? "null"}', () async {
        nativeResult = scenario.$1;
        final result = await SharePlus.instance.share(
          ShareParams(
            text:
                'Aashirvaad Atta 5 kg https://moolsocial.app/product/atta-5kg',
            subject: 'Your purchase invoice',
            title: 'Share product',
          ),
        );

        expect(result.status, scenario.$2);
        expect(
          result.raw,
          scenario.$1 ?? 'dev.fluttercommunity.plus/share/unavailable',
        );
        expect(calls, hasLength(1));
        expect(calls.single.method, 'share');
        expect(calls.single.arguments, {
          'text':
              'Aashirvaad Atta 5 kg https://moolsocial.app/product/atta-5kg',
          'subject': 'Your purchase invoice',
          'title': 'Share product',
        });
      });
    }

    test(
      'passes invoice and photo paths and MIME types without losing context',
      () async {
        nativeResult = 'com.whatsapp/.ContactPicker';
        final result = await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile('/picked/invoice.pdf', mimeType: 'application/pdf'),
              XFile('/picked/product.jpg', mimeType: 'image/jpeg'),
            ],
            text: 'Invoice MS-101',
          ),
        );

        expect(result.status, ShareResultStatus.success);
        expect(calls, hasLength(1));
        expect(calls.single.arguments, {
          'paths': ['/picked/invoice.pdf', '/picked/product.jpg'],
          'mimeTypes': ['application/pdf', 'image/jpeg'],
          'text': 'Invoice MS-101',
        });
      },
    );

    test(
      'does not turn native share errors into dismissal or success',
      () async {
        messenger.setMockMethodCallHandler(channel, (_) async {
          throw PlatformException(code: 'Share failed');
        });
        await expectLater(
          SharePlus.instance.share(ShareParams(text: 'Invoice MS-101')),
          throwsA(
            isA<PlatformException>().having(
              (error) => error.code,
              'code',
              'Share failed',
            ),
          ),
        );
      },
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
