import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  testWidgets('C26F Care Medicine and Work share one neutral fixed rail', (
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
        initialLocation: '/app/book/doctor',
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
    _expectActions(const ['doctor', 'medicine', 'salon']);
    expect(find.byKey(const Key('care-book-local-navigation')), findsOneWidget);
    expect(find.byKey(const Key('care-global-chat')), findsOneWidget);

    await tester.tap(find.byKey(const Key('care-local-medicine')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-v2-screen')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('care-local-destination-tabs')),
      findsOneWidget,
    );
    _expectFixedRail(tester);
    _expectActions(const ['doctor', 'medicine', 'salon']);
    expect(find.byKey(const Key('care-local-tab-medicine')), findsOneWidget);

    await tester.tap(find.byKey(const Key('mool-compact-launcher')));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-v2-screen')), findsOneWidget);
    expect(find.byKey(const Key('care-local-tab-medicine')), findsOneWidget);
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsNothing,
    );

    await _openFamily(tester, 'work');
    _expectFixedRail(tester);
    _expectActions(const ['earn', 'workspace']);
    expect(find.byKey(const Key('work-local-earn')), findsOneWidget);
    expect(find.byKey(const Key('work-local-workspace')), findsOneWidget);
    expect(find.byKey(const Key('work-global-chat')), findsNothing);
    expect(find.byKey(const Key('mool-global-chat')), findsOneWidget);
    expect(find.byKey(const Key('work-main-global-profile')), findsOneWidget);

    await tester.tap(find.byKey(const Key('work-local-workspace')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const ValueKey('moolsocial-local-workspace-selected-indicator'),
      ),
      findsOneWidget,
    );

    await _openFamily(tester, 'book');
    expect(find.byKey(const Key('care-book-local-navigation')), findsOneWidget);
    _expectActions(const ['doctor', 'medicine', 'salon']);
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
