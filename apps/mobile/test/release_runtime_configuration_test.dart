import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/config/release_runtime_configuration.dart';

void main() {
  const completeConfiguration = ReleaseRuntimeConfiguration(
    useEmulators: false,
    firebaseApiKey: 'firebase-api-key-present',
    firebaseAppId: 'firebase-app-id-present',
    firebaseMessagingSenderId: 'firebase-sender-present',
    firebaseProjectId: 'firebase-project-present',
    googleServerClientId: 'google-server-client-id-present',
  );

  test('complete release configuration has no missing define names', () {
    expect(completeConfiguration.missingRequiredDefineNames, isEmpty);
    expect(completeConfiguration.isComplete, isTrue);
    expect(requiredReleaseRuntimeDefineNames, const <String>[
      'MOOLSOCIAL_FIREBASE_API_KEY',
      'MOOLSOCIAL_FIREBASE_APP_ID',
      'MOOLSOCIAL_FIREBASE_MESSAGING_SENDER_ID',
      'MOOLSOCIAL_FIREBASE_PROJECT_ID',
      'MOOLSOCIAL_GOOGLE_SERVER_CLIENT_ID',
    ]);
  });

  test('missing release values report every exact define name', () {
    const configuration = ReleaseRuntimeConfiguration(
      useEmulators: false,
      firebaseApiKey: '',
      firebaseAppId: 'firebase-app-id-present',
      firebaseMessagingSenderId: '   ',
      firebaseProjectId: 'firebase-project-present',
      googleServerClientId: '',
    );

    expect(configuration.missingRequiredDefineNames, const <String>[
      'MOOLSOCIAL_FIREBASE_API_KEY',
      'MOOLSOCIAL_FIREBASE_MESSAGING_SENDER_ID',
      'MOOLSOCIAL_GOOGLE_SERVER_CLIENT_ID',
    ]);
    expect(configuration.isComplete, isFalse);
  });

  test('local emulator mode does not require live release values', () {
    const configuration = ReleaseRuntimeConfiguration(
      useEmulators: true,
      firebaseApiKey: '',
      firebaseAppId: '',
      firebaseMessagingSenderId: '',
      firebaseProjectId: '',
      googleServerClientId: '',
    );

    expect(configuration.missingRequiredDefineNames, isEmpty);
    expect(configuration.isComplete, isTrue);
  });

  test('external auth endpoints require an exact HTTPS authority', () {
    expect(
      isQualifiedHttpsRuntimeEndpoint('https://auth.example.com/base'),
      isTrue,
    );
    expect(isQualifiedHttpsRuntimeEndpoint('http://auth.example.com'), isFalse);
    expect(isQualifiedHttpsRuntimeEndpoint('https:///missing-host'), isFalse);
    expect(isQualifiedHttpsRuntimeEndpoint('not-a-url'), isFalse);
    expect(isQualifiedHttpsRuntimeEndpoint('   '), isFalse);
  });

  test('live Android uses its native Firebase configuration', () {
    expect(
      shouldUseNativeAndroidFirebaseConfiguration(
        isAndroid: true,
        useEmulators: false,
      ),
      isTrue,
    );
    expect(
      shouldUseNativeAndroidFirebaseConfiguration(
        isAndroid: true,
        useEmulators: true,
      ),
      isFalse,
    );
    expect(
      shouldUseNativeAndroidFirebaseConfiguration(
        isAndroid: false,
        useEmulators: false,
      ),
      isFalse,
    );
  });

  test('live device review accepts only exact qualified profiles', () {
    expect(
      isQualifiedDeviceReviewRuntimeMode(
        deviceReview: true,
        useEmulators: false,
        youtubePublicReview: true,
        youtubePrivateDevProof: true,
        sideloadPreflightEnabled: false,
        googleSideloadSigningQualified: false,
      ),
      isTrue,
    );
    expect(
      isQualifiedDeviceReviewRuntimeMode(
        deviceReview: true,
        useEmulators: false,
        youtubePublicReview: false,
        youtubePrivateDevProof: false,
        sideloadPreflightEnabled: true,
        googleSideloadSigningQualified: true,
      ),
      isTrue,
    );
    expect(
      isQualifiedDeviceReviewRuntimeMode(
        deviceReview: true,
        useEmulators: false,
        youtubePublicReview: false,
        youtubePrivateDevProof: false,
        sideloadPreflightEnabled: true,
        googleSideloadSigningQualified: false,
      ),
      isFalse,
    );
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
    );
    expect(
      isQualifiedDeviceReviewRuntimeMode(
        deviceReview: false,
        useEmulators: false,
        youtubePublicReview: false,
        youtubePrivateDevProof: false,
        sideloadPreflightEnabled: true,
        googleSideloadSigningQualified: true,
      ),
      isFalse,
    );
  });

  test('global social login audit requires the exact qualified sideload', () {
    expect(
      isQualifiedDeviceReviewRuntimeMode(
        deviceReview: true,
        useEmulators: false,
        youtubePublicReview: false,
        youtubePrivateDevProof: false,
        sideloadPreflightEnabled: true,
        googleSideloadSigningQualified: true,
        globalSocialLoginAudit: true,
      ),
      isTrue,
    );
    for (final invalid in const [
      (deviceReview: false, useEmulators: false, sideload: true, signing: true),
      (deviceReview: true, useEmulators: true, sideload: true, signing: true),
      (deviceReview: true, useEmulators: false, sideload: false, signing: true),
      (deviceReview: true, useEmulators: false, sideload: true, signing: false),
    ]) {
      expect(
        isQualifiedDeviceReviewRuntimeMode(
          deviceReview: invalid.deviceReview,
          useEmulators: invalid.useEmulators,
          youtubePublicReview: false,
          youtubePrivateDevProof: false,
          sideloadPreflightEnabled: invalid.sideload,
          googleSideloadSigningQualified: invalid.signing,
          globalSocialLoginAudit: true,
        ),
        isFalse,
        reason: '$invalid',
      );
    }
  });

  test('social runtime candidate requires every live dependency', () {
    bool qualifies({
      bool globalSocialLoginAudit = true,
      bool useEmulators = false,
      String firebaseProjectId = socialRuntimeFirebaseProjectId,
      bool youtubePrivateDevProof = true,
      bool youtubeEmbeddedPlayerEnabled = true,
      String youtubeProviderUrl = socialRuntimeYouTubeProviderUrl,
      String socialContentUrl = socialRuntimeContentUrl,
      String chatUrl = socialRuntimeChatUrl,
    }) => isQualifiedSocialRuntimeDependencySet(
      globalSocialLoginAudit: globalSocialLoginAudit,
      useEmulators: useEmulators,
      firebaseProjectId: firebaseProjectId,
      youtubePrivateDevProof: youtubePrivateDevProof,
      youtubeEmbeddedPlayerEnabled: youtubeEmbeddedPlayerEnabled,
      youtubeProviderUrl: youtubeProviderUrl,
      socialContentUrl: socialContentUrl,
      chatUrl: chatUrl,
    );

    expect(qualifies(), isTrue);
    for (final invalid in <bool>[
      qualifies(useEmulators: true),
      qualifies(firebaseProjectId: 'wrong-project'),
      qualifies(youtubePrivateDevProof: false),
      qualifies(youtubeEmbeddedPlayerEnabled: false),
      qualifies(youtubeProviderUrl: ''),
      qualifies(socialContentUrl: ''),
      qualifies(chatUrl: ''),
    ]) {
      expect(invalid, isFalse);
    }
    expect(
      qualifies(
        globalSocialLoginAudit: false,
        useEmulators: true,
        firebaseProjectId: '',
        youtubePrivateDevProof: false,
        youtubeEmbeddedPlayerEnabled: false,
        youtubeProviderUrl: '',
        socialContentUrl: '',
        chatUrl: '',
      ),
      isTrue,
      reason: 'Normal non-audit builds retain their existing composition.',
    );
  });

  test('global social login audit selects only live shared auth owners', () {
    final audit = resolveGlobalSocialLoginAuditComposition(
      deviceReview: true,
      globalSocialLoginAudit: true,
    );
    expect(audit.useReviewAuthentication, isFalse);
    expect(audit.useProductionProviderAvailability, isTrue);
    expect(audit.useFirebaseSessionBootstrap, isTrue);
    expect(audit.activateDevAppCheck, isTrue);

    final ordinaryReview = resolveGlobalSocialLoginAuditComposition(
      deviceReview: true,
      globalSocialLoginAudit: false,
    );
    expect(ordinaryReview.useReviewAuthentication, isTrue);
    expect(ordinaryReview.useProductionProviderAvailability, isFalse);
    expect(ordinaryReview.useFirebaseSessionBootstrap, isFalse);
    expect(ordinaryReview.activateDevAppCheck, isFalse);
  });

  testWidgets('bootstrap renders a named Flutter-owned first frame', (
    tester,
  ) async {
    await tester.pumpWidget(const ReleaseBootstrapApp());

    expect(find.text('Starting MoolSocial'), findsOneWidget);
    expect(find.bySemanticsLabel('MoolSocial is starting'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('incomplete configuration renders a safe first frame', (
    tester,
  ) async {
    await tester.pumpWidget(const ReleaseConfigurationFailureApp());

    expect(find.text('MoolSocial needs an update'), findsOneWidget);
    expect(
      find.textContaining('Update MoolSocial from your app store'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Your account and content are safe'),
      findsOneWidget,
    );

    final renderedText = tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data ?? widget.textSpan?.toPlainText() ?? '')
        .join('\n');
    expect(renderedText, isNot(contains('MOOLSOCIAL_')));
    expect(renderedText, isNot(contains('AIza')));
    expect(renderedText, isNot(contains('googleusercontent.com')));
  });
}
