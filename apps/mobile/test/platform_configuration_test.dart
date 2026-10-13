import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/config/release_runtime_configuration.dart';

void main() {
  test('r66.8 PDF renderer remains private isolated and locally bounded', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final service = RegExp(
      r'<service\s[^>]*android:name="\.WorkDocumentRenderService"[\s\S]*?/>',
    ).firstMatch(manifest)?.group(0);
    expect(service, isNotNull);
    expect(service, contains('android:exported="false"'));
    expect(service, contains('android:isolatedProcess="true"'));
    expect(service, contains('android:process=":work_pdf_preview"'));
    expect(service, isNot(contains('intent-filter')));
    final root = 'android/app/src/main/kotlin/com/moolsocial/app/';
    final renderer = File(
      '${root}WorkDocumentRenderService.kt',
    ).readAsStringSync();
    final bridge = File(
      '${root}WorkDocumentPreviewBridge.kt',
    ).readAsStringSync();
    expect(renderer, contains('HandlerThread("work-document-page")'));
    expect(renderer, contains('PdfRenderer(input).use'));
    expect(renderer, contains('document.pageCount in 1..500'));
    expect(renderer, contains('2_000_000.0'));
    expect(renderer, contains('input?.close()'));
    expect(renderer, contains('bitmap.recycle()'));
    expect(bridge, contains('ParcelFileDescriptor.MODE_READ_ONLY'));
    expect(bridge, contains('check(inputFile.delete())'));
    expect(bridge, contains('ParcelFileDescriptor.createPipe()'));
    expect(bridge, contains('collected.size() + read <= MAX_BYTES'));
    expect(bridge, contains('main.postDelayed(request.timeout, 20_000)'));
    expect(bridge, contains('active !== request || request.finished'));
    expect(bridge, contains('context.unbindService(it)'));
    for (final source in [bridge, renderer]) {
      expect(source, isNot(contains('ACTION_VIEW')));
      expect(source, isNot(contains('Uri.parse')));
      expect(source, isNot(contains('java.net.')));
      expect(source, isNot(contains('Log.')));
    }
  });
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

    expect(mainSource, contains("const _useEmulators = bool.fromEnvironment("));
    expect(mainSource, contains('defaultValue: kDebugMode'));
    expect(mainSource, contains('if (_useEmulators)'));
    expect(mainSource, contains('MOOLSOCIAL_DEVICE_REVIEW'));
    expect(
      RegExp(
        r"if \(!_runtimeModeIsValid\(\)\)\s*\{\s*"
        r"_showReleaseBootstrapFailure\('runtime_mode'\);\s*return;",
      ).hasMatch(mainSource),
      isTrue,
      reason: 'Invalid runtime modes must stop before application startup.',
    );
    expect(mainSource, contains('isQualifiedUiReviewOnlyRuntimeMode('));
    expect(mainSource, contains('isQualifiedDeviceReviewRuntimeMode('));
    expect(
      isQualifiedDeviceReviewRuntimeMode(
        deviceReview: true,
        useEmulators: false,
        youtubePublicReview: false,
        youtubePrivateDevProof: false,
        sideloadPreflightEnabled: false,
        googleSideloadSigningQualified: false,
      ),
      isFalse,
      reason: 'Unqualified review mode cannot access live services.',
    );
    expect(mainSource, contains('MOOLSOCIAL_FIREBASE_API_KEY'));
    expect(mainSource, contains('MOOLSOCIAL_FIREBASE_APP_ID'));
    expect(mainSource, contains('MOOLSOCIAL_FIREBASE_MESSAGING_SENDER_ID'));
    expect(mainSource, contains('MOOLSOCIAL_FIREBASE_PROJECT_ID'));
    expect(
      RegExp(
        r"if \(!_releaseRuntimeConfiguration\.isComplete\)\s*\{\s*"
        r"_showReleaseBootstrapFailure\('release_configuration'\);\s*return;",
      ).hasMatch(mainSource),
      isTrue,
      reason:
          'A release must fail closed instead of silently using demo services.',
    );
    expect(
      mainSource,
      contains('runApp(const ReleaseConfigurationFailureApp())'),
    );
    const missingConfiguration = ReleaseRuntimeConfiguration(
      useEmulators: false,
      firebaseApiKey: '',
      firebaseAppId: '',
      firebaseMessagingSenderId: '',
      firebaseProjectId: '',
      googleServerClientId: '',
    );
    expect(missingConfiguration.isComplete, isFalse);
    expect(
      missingConfiguration.missingRequiredDefineNames,
      orderedEquals(requiredReleaseRuntimeDefineNames),
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
