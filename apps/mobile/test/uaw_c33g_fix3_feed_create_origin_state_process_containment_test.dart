import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/creator/creator_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/retailer/retailer_session.dart';
import 'package:moolsocial/features/shared/shared_session.dart';
import 'package:moolsocial/ui_v2/social/social_v2_consumer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('guest public Feed opens without authentication or exception', (
    tester,
  ) async {
    final harness = await _mountSocial(tester, initialSubAction: 'feed');

    expect(harness.journey.stage, JourneyStage.ready);
    expect(harness.journey.isAuthenticated, isFalse);
    expect(
      find.byKey(const Key('screen04-moolsocial-feed-brand')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('screen04-rail-feed')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final origin in const <String, String>{
    'home': 'videos',
    'feed': 'feed',
  }.entries) {
    testWidgets(
      'guest Create from ${origin.key} preserves exact sign-in and cancel origins',
      (tester) async {
        final harness = await _mountSocial(
          tester,
          initialSubAction: origin.key,
        );

        await tester.tap(find.byKey(const Key('screen04-rail-create')));
        await tester.pump();

        expect(harness.journey.stage, JourneyStage.signIn);
        expect(harness.journey.isAuthenticated, isFalse);
        expect(harness.journey.returnTo, '/app/social?sub=create');
        expect(harness.journey.canCancelSignIn, isTrue);
        expect(
          find.byKey(const Key('screen04-create-workbench')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);

        harness.journey.cancelSignIn();
        await tester.pump();
        expect(harness.journey.stage, JourneyStage.ready);
        expect(harness.journey.readyRoute(), '/app/social?sub=${origin.value}');
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'authenticated direct Create renders and closes without exception',
    (tester) async {
      final harness = await _mountSocial(
        tester,
        initialSubAction: 'create',
        authenticated: true,
      );

      expect(harness.journey.isAuthenticated, isTrue);
      expect(find.byKey(const Key('screen04-create-home')), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('screen04-create-post-entry')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('screen04-create-workbench')),
        findsOneWidget,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('screen04-create-home')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'shared-post Create intent survives restart then supports cancel retry success',
    () async {
      final store = MemoryJourneyStore(snapshot: _readySnapshot);
      final first = JourneySession(store: store, allowGuestReady: true);
      await first.start();
      first.beginSignIn(
        returnLocation:
            '/app/social?sub=create&state=shared-post&item=c33g-post',
        cancelLocation: '/app/social?sub=feed&item=c33g-post',
      );
      await _waitFor(
        () =>
            store.snapshot?.pendingAuthenticationCancelRoute ==
            '/app/social?sub=feed&item=c33g-post',
      );
      expect(
        store.snapshot?.pendingAuthenticationPurpose,
        JourneyAuthenticationPurpose.general.name,
      );
      first.dispose();

      final gateway = ReviewSocialAuthGateway(
        defaultResult: const SocialAuthResult.authenticated('c33g-user'),
      );
      final resumed = JourneySession(
        store: store,
        socialAuthGateway: gateway,
        allowGuestReady: true,
      );
      addTearDown(resumed.dispose);
      await resumed.start();

      expect(resumed.stage, JourneyStage.signIn);
      expect(
        resumed.returnTo,
        '/app/social?sub=create&state=shared-post&item=c33g-post',
      );
      expect(resumed.canCancelSignIn, isTrue);
      resumed.cancelSignIn();
      expect(resumed.readyRoute(), '/app/social?sub=feed&item=c33g-post');
      await _waitFor(() => store.snapshot?.pendingRoute == null);
      expect(store.snapshot?.pendingAuthenticationCancelRoute, isNull);
      expect(store.snapshot?.pendingAuthenticationPurpose, isNull);

      resumed.beginSignIn(
        returnLocation:
            '/app/social?sub=create&state=shared-post&item=c33g-post',
        cancelLocation: '/app/social?sub=feed&item=c33g-post',
      );
      await _waitFor(
        () =>
            store.snapshot?.pendingRoute ==
            '/app/social?sub=create&state=shared-post&item=c33g-post',
      );
      expect(await resumed.signInWithSocial(SocialAuthProvider.google), isTrue);
      expect(resumed.isAuthenticated, isTrue);
      expect(
        resumed.readyRoute(),
        '/app/social?sub=create&state=shared-post&item=c33g-post',
      );
      expect(gateway.signInCount, 1);
    },
  );
}

Future<void> _waitFor(bool Function() condition) async {
  for (var attempt = 0; attempt < 20; attempt += 1) {
    if (condition()) return;
    await Future<void>.delayed(Duration.zero);
  }
  throw StateError('Journey persistence did not settle within 20 microtasks.');
}

Future<_SocialHarness> _mountSocial(
  WidgetTester tester, {
  required String initialSubAction,
  bool authenticated = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);
  final journey = JourneySession(
    store: MemoryJourneyStore(snapshot: _readySnapshot),
    otpGateway: ReviewOtpGateway(signedIn: authenticated),
    allowGuestReady: true,
  );
  final creator = CreatorSession();
  final retailer = RetailerSession();
  final shared = SharedSession();
  addTearDown(journey.dispose);
  addTearDown(creator.dispose);
  addTearDown(retailer.dispose);
  addTearDown(shared.dispose);
  await journey.start();

  await tester.pumpWidget(
    MaterialApp(
      home: SocialUniversalV2(
        session: journey,
        creatorSession: creator,
        retailerSession: retailer,
        sharedSession: shared,
        initialSubAction: initialSubAction,
        initialState: initialSubAction == 'create' ? 'home' : null,
        youtubePublicAccessOverride: false,
        youtubeCreatorAccessOverride: false,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _SocialHarness(journey);
}

class _SocialHarness {
  const _SocialHarness(this.journey);

  final JourneySession journey;
}

const _readySnapshot = JourneySnapshot(
  languageCode: 'en',
  areaMode: 'current',
  currentAreaLabel: 'Jodhpur, Rajasthan',
  setupComplete: true,
  setupExperienceVersion: approvedSetupExperienceVersion,
);
