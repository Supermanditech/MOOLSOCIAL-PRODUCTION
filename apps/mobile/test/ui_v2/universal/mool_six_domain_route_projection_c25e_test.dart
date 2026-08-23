import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  testWidgets('C25E traverses all six domains without returning through Home', (
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

    _expectSocialActions(const ['shorts', 'videos', 'feed', 'create']);
    expect(find.byKey(const Key('social-global-chat')), findsOneWidget);

    await _openDomain(tester, 'buy');
    _expectLocalActions(const ['wholesale', 'orders']);
    expect(
      find.byKey(const ValueKey('moolsocial-family-root-buy')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('moolsocial-local-shop-selection')),
      findsNothing,
    );
    expect(find.byKey(const Key('buy-global-chat')), findsOneWidget);
    expect(find.byKey(const Key('buy-local-tab-medicine')), findsNothing);

    await _openDomain(tester, 'eat');
    _expectLocalActions(const ['order', 'table']);
    expect(find.byKey(const Key('eat-global-chat')), findsOneWidget);

    await _openDomain(tester, 'ride');
    _expectLocalActions(const ['bike', 'auto', 'cab', 'bus']);
    expect(find.byKey(const Key('ride-global-chat')), findsOneWidget);
    await tester.tap(find.byKey(const Key('ride-local-bus')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bus-booking-home')), findsOneWidget);
    _expectLocalActions(const ['bike', 'auto', 'cab', 'bus']);
    expect(find.byKey(const Key('travel-local-bus')), findsOneWidget);
    expect(find.byKey(const Key('ride-global-chat')), findsOneWidget);

    await _openDomain(tester, 'book');
    _expectLocalActions(const ['doctor', 'medicine', 'salon']);
    expect(find.byKey(const Key('care-global-chat')), findsOneWidget);
    await tester.tap(find.byKey(const Key('care-local-medicine')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-v2-screen')), findsOneWidget);
    _expectLocalActions(const ['doctor', 'medicine', 'salon']);
    expect(find.byKey(const Key('care-local-tab-medicine')), findsOneWidget);
    expect(find.byKey(const Key('buy-global-chat')), findsOneWidget);

    await _openDomain(tester, 'work');
    _expectLocalActions(const ['earn', 'workspace']);
    expect(find.byKey(const Key('work-local-earn')), findsOneWidget);
    expect(find.byKey(const Key('work-local-workspace')), findsOneWidget);
    expect(find.byKey(const Key('personal-mool-root-v2')), findsNothing);

    await tester.tap(find.byKey(const Key('work-global-chat')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    _expectLocalActions(const ['earn', 'workspace']);
  });
}

Future<void> _openDomain(WidgetTester tester, String familyId) async {
  await tester.tap(find.byKey(const Key('mool-compact-launcher')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey('mool-navigator-family-$familyId')));
  await tester.pumpAndSettle();
}

void _expectLocalActions(List<String> ids) {
  for (final id in ids) {
    expect(
      find.byKey(ValueKey('moolsocial-local-$id-selection')),
      findsOneWidget,
    );
  }
}

void _expectSocialActions(List<String> ids) {
  for (final id in ids) {
    expect(find.byKey(ValueKey('screen04-rail-$id')), findsOneWidget);
  }
}
