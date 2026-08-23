import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  testWidgets('C26D real Social and Shop use the approved shared navigation', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final journey = JourneySession(
      store: MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'manual',
          areaLabel: 'Jodhpur',
          setupComplete: true,
        ),
      ),
      otpGateway: ReviewOtpGateway(signedIn: true),
    );
    await journey.start();
    addTearDown(journey.dispose);
    await tester.pumpWidget(
      MoolSocialApp(
        session: journey,
        initialLocation: '/app/social?sub=feed',
        disposeBookSession: true,
        disposeBuySession: true,
        disposeChatSession: true,
        disposeCreatorSession: true,
        disposeEatSession: true,
        disposeRideSession: true,
        disposeSharedSession: true,
        disposeWorkSession: true,
      ),
    );
    await tester.pumpAndSettle();

    _expectDestinationRailIsTransparentAndFixed(tester);
    for (final id in const ['shorts', 'videos', 'feed', 'create']) {
      expect(find.byKey(ValueKey('screen04-rail-$id')), findsOneWidget);
    }
    expect(find.byKey(const Key('social-global-chat')), findsOneWidget);

    await tester.tap(find.byKey(const Key('mool-compact-launcher')));
    await tester.pumpAndSettle();
    for (final family in const [
      'social',
      'buy',
      'eat',
      'ride',
      'book',
      'work',
    ]) {
      final row = find.byKey(ValueKey('mool-navigator-family-$family'));
      expect(row, findsOneWidget);
      expect(tester.getSize(row).height, 56);
    }
    expect(find.byKey(const Key('mool-navigator-buy-shop')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('mool-navigator-family-buy')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('buy-v2-screen')), findsOneWidget);
    _expectDestinationRailIsTransparentAndFixed(tester);
    for (final id in const ['wholesale', 'orders']) {
      expect(
        find.byKey(ValueKey('moolsocial-local-$id-selection')),
        findsOneWidget,
      );
    }
    expect(
      find.byKey(const ValueKey('moolsocial-local-shop-selection')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('moolsocial-family-root-buy')),
      findsOneWidget,
    );
    expect(find.text('Products'), findsNothing);
    expect(find.byKey(const Key('buy-local-tab-medicine')), findsNothing);
    expect(find.byKey(const Key('buy-global-chat')), findsOneWidget);

    await tester.tap(find.byKey(const Key('mool-compact-launcher')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsOneWidget,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-v2-screen')), findsOneWidget);
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('buy-local-tab-wholesale')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const ValueKey('moolsocial-local-wholesale-selected-indicator'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('mool-compact-launcher')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('mool-navigator-family-social')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen04-context-tabs')), findsOneWidget);
    expect(find.byKey(const Key('social-global-chat')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _expectDestinationRailIsTransparentAndFixed(WidgetTester tester) {
  final rail = find.byKey(const Key('moolsocial-compact-destination-rail'));
  expect(rail, findsOneWidget);
  expect(tester.getSize(rail).height, 58);
  expect(
    find.descendant(of: rail, matching: find.byType(SingleChildScrollView)),
    findsNothing,
  );
  expect(
    find.descendant(of: rail, matching: find.byType(BackdropFilter)),
    findsNothing,
  );
}
