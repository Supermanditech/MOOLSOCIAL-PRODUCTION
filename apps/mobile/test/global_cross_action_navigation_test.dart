import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<JourneySession> readyJourney() async {
    final session = JourneySession(
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
    await session.start();
    return session;
  }

  testWidgets(
    'Shop reaches every main action without returning through Mool home',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final journey = await readyJourney();
      addTearDown(journey.dispose);

      await tester.pumpWidget(
        MoolSocialApp(session: journey, initialLocation: '/app/buy?sub=shop'),
      );
      await tester.pumpAndSettle();

      const targets = <(String, Key)>[
        ('social', Key('screen04-universal-v2')),
        ('eat', Key('eat-home-screen')),
        ('ride', Key('ride-booking-screen')),
        ('book', Key('doctor-discovery-home')),
        ('work', Key('work-main-v2')),
      ];

      for (final target in targets) {
        await tester.tap(find.byKey(const Key('mool-compact-launcher')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('mool-connected-action-navigator')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('personal-mool-root-v2')), findsNothing);

        await tester.tap(
          find.byKey(ValueKey('mool-navigator-family-${target.$1}')),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(target.$2), findsOneWidget, reason: target.$1);
        expect(find.byKey(const Key('personal-mool-root-v2')), findsNothing);
        expect(tester.takeException(), isNull, reason: target.$1);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('buy-v2-screen')),
          findsOneWidget,
          reason: 'Back from ${target.$1}',
        );
      }
    },
  );

  testWidgets('native Back closes the in-place main switcher before Shop', (
    tester,
  ) async {
    final journey = await readyJourney();
    addTearDown(journey.dispose);
    await tester.pumpWidget(
      MoolSocialApp(session: journey, initialLocation: '/app/buy?sub=shop'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('mool-compact-launcher')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsOneWidget,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('buy-v2-screen')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('destination rails reach sibling subactions and return cleanly', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    const cases = <(String, Key, Key, Key, Key?)>[
      (
        '/app/eat/home',
        Key('eat-home-screen'),
        Key('eat-local-table'),
        Key('eat-table-screen'),
        null,
      ),
      (
        '/app/ride/book?type=bike',
        Key('ride-booking-screen'),
        Key('ride-local-bus'),
        Key('bus-booking-home'),
        Key('travel-local-bike'),
      ),
      (
        '/app/book/doctor',
        Key('doctor-discovery-home'),
        Key('care-local-salon'),
        Key('salon-discovery-home'),
        null,
      ),
      (
        '/app/work/home',
        Key('work-main-v2'),
        Key('work-local-workspace'),
        Key('my-work-screen'),
        null,
      ),
    ];

    for (final item in cases) {
      final journey = await readyJourney();
      await tester.pumpWidget(
        MoolSocialApp(
          key: UniqueKey(),
          session: journey,
          initialLocation: item.$1,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(item.$2), findsOneWidget, reason: item.$1);

      await tester.tap(find.byKey(item.$3));
      await tester.pumpAndSettle();
      expect(find.byKey(item.$4), findsOneWidget, reason: item.$1);
      expect(tester.takeException(), isNull, reason: item.$1);

      if (item.$5 case final returnAction?) {
        await tester.tap(find.byKey(returnAction));
      } else {
        await tester.binding.handlePopRoute();
      }
      await tester.pumpAndSettle();
      expect(find.byKey(item.$2), findsOneWidget, reason: 'Back to ${item.$1}');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      journey.dispose();
    }
  });
}
