import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  testWidgets('C26E real Food and Travel keep direct actions and Bus owner', (
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
        initialLocation: '/app/eat/home',
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

    _expectFixedRail(tester);
    _expectActions(const ['order', 'table']);
    expect(find.byKey(const Key('eat-local-order')), findsOneWidget);
    expect(find.byKey(const Key('eat-local-table')), findsOneWidget);
    expect(find.byKey(const Key('eat-global-chat')), findsOneWidget);
    expect(find.byKey(const Key('eat-global-profile')), findsOneWidget);

    await tester.tap(find.byKey(const Key('eat-global-profile')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('global-profile-panel-v2')), findsOneWidget);
    expect(
      find.byKey(const Key('global-profile-context-food-table-discovery')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(
        const Key('global-profile-context-action-food-table-discovery'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('eat-table-screen')), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('eat-home-screen')), findsOneWidget);

    await _openFamily(tester, 'ride');
    _expectFixedRail(tester);
    _expectActions(const ['bike', 'auto', 'cab', 'bus']);
    for (final id in const ['bike', 'auto', 'cab', 'bus']) {
      expect(find.byKey(Key('ride-local-$id')), findsOneWidget);
    }
    expect(find.byKey(const Key('ride-global-chat')), findsOneWidget);
    expect(find.byKey(const Key('ride-global-profile')), findsOneWidget);

    await tester.tap(find.byKey(const Key('ride-global-profile')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('global-profile-context-travel-bus-discovery')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(
        const Key('global-profile-context-action-travel-bus-discovery'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bus-booking-home')), findsOneWidget);

    await tester.tap(find.byKey(const Key('travel-global-profile')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('global-profile-context-travel-cab-discovery')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(
        const Key('global-profile-context-action-travel-cab-discovery'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ride-local-navigation')), findsOneWidget);

    await tester.tap(find.byKey(const Key('mool-compact-launcher')));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ride-local-navigation')), findsOneWidget);
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('ride-local-bus')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bus-booking-home')), findsOneWidget);
    expect(
      find.byKey(const Key('travel-bus-local-navigation')),
      findsOneWidget,
    );
    _expectFixedRail(tester);
    _expectActions(const ['bike', 'auto', 'cab', 'bus']);
    expect(find.byKey(const Key('travel-local-bus')), findsOneWidget);
    expect(find.byKey(const Key('travel-global-profile')), findsOneWidget);

    await _openFamily(tester, 'eat');
    expect(find.byKey(const Key('eat-local-navigation')), findsOneWidget);
    _expectActions(const ['order', 'table']);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _openFamily(WidgetTester tester, String familyId) async {
  await tester.tap(find.byKey(const Key('mool-compact-launcher')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey('mool-navigator-family-$familyId')));
  await tester.pumpAndSettle();
}

void _expectActions(List<String> ids) {
  for (final id in ids) {
    expect(
      find.byKey(ValueKey('moolsocial-local-$id-selection')),
      findsOneWidget,
    );
  }
}

void _expectFixedRail(WidgetTester tester) {
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
