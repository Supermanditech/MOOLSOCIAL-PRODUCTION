import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('successor release configuration fails closed before Firebase', () {
    final mainSource = File('lib/main.dart').readAsStringSync();
    final configurationSource = File(
      'lib/core/config/release_runtime_configuration.dart',
    ).readAsStringSync();

    expect(
      mainSource,
      contains('runApp(const ReleaseConfigurationFailureApp());'),
    );
    expect(configurationSource, contains('MOOLSOCIAL_FIREBASE_API_KEY'));
    expect(configurationSource, contains('MOOLSOCIAL_FIREBASE_APP_ID'));
    expect(
      configurationSource,
      contains('MOOLSOCIAL_FIREBASE_MESSAGING_SENDER_ID'),
    );
    expect(configurationSource, contains('MOOLSOCIAL_FIREBASE_PROJECT_ID'));
    expect(configurationSource, contains('MOOLSOCIAL_GOOGLE_SERVER_CLIENT_ID'));
    expect(
      mainSource.indexOf('runApp(const ReleaseConfigurationFailureApp());'),
      lessThan(mainSource.indexOf('Firebase.initializeApp')),
    );
  });

  test('UI review-only bootstrap reaches Buy without Firebase runtime', () {
    final mainSource = File('lib/main.dart').readAsStringSync();
    final reviewStart = mainSource.indexOf('void _runUiReviewOnlyApp()');
    final reviewEnd = mainSource.indexOf('Future<void> main()', reviewStart);
    final reviewBranch = mainSource.indexOf('if (_uiReviewOnlyMode)');
    final firebaseBootstrap = mainSource.indexOf('Firebase.initializeApp');

    expect(mainSource, contains('MOOLSOCIAL_UI_REVIEW_ONLY'));
    expect(reviewStart, greaterThanOrEqualTo(0));
    expect(reviewEnd, greaterThan(reviewStart));
    expect(reviewBranch, greaterThanOrEqualTo(0));
    expect(reviewBranch, lessThan(firebaseBootstrap));
    final reviewSource = mainSource.substring(reviewStart, reviewEnd);
    expect(reviewSource, isNot(contains('Firebase')));
    expect(reviewSource, contains('ChatSession()'));
    expect(reviewSource, contains("initialLocation: '/app/buy'"));
    expect(reviewSource, contains('allowGuestReady: true'));
    expect(reviewSource, contains('uiReviewOnly: true'));
    expect(reviewSource, contains('UiReviewSocialContentGateway()'));
  });

  test('device-review builds retain candidate provenance markers', () {
    final mainSource = File('lib/main.dart').readAsStringSync();
    final journeySource = File(
      'lib/features/journey01/journey_session.dart',
    ).readAsStringSync();

    expect(mainSource, contains('if (kDebugMode || _deviceReviewMode)'));
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
    );
  });

  test('locally signed-out users always leave authenticated routes', () {
    final routerSource = File(
      'lib/features/journey01/journey_router.dart',
    ).readAsStringSync();

    expect(
      RegExp(
        r'signedOut \|\| !session\.isAuthenticated',
      ).allMatches(routerSource).length,
      1,
      reason:
          'The shared redirect owner must leave authenticated UI after local invalidation.',
    );
  });
}
