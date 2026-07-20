import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/ui_v2/launch/launch_interruption_guard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> mountApp(
    WidgetTester tester, {
    required JourneySession session,
    required LaunchInterruptionGuard interruptionGuard,
  }) async {
    await tester.binding.setSurfaceSize(const Size(360, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MoolSocialApp(
        session: session,
        launchInterruptionGuard: interruptionGuard,
      ),
    );
    await tester.pump();
  }

  Future<void> finishScreen01(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 3100));
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'completed previous candidate is required to show current Screen 02',
    (tester) async {
      final store = MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'skipped',
          setupComplete: true,
          setupExperienceVersion: 4,
        ),
      );
      final session = JourneySession(store: store);
      final guard = LaunchInterruptionGuard(
        minimumForegroundDuration: Duration.zero,
      );
      addTearDown(session.dispose);
      addTearDown(guard.dispose);

      await mountApp(tester, session: session, interruptionGuard: guard);
      await finishScreen01(tester);

      expect(find.byKey(const Key('screen02-v4')), findsOneWidget);
      expect(find.byKey(const Key('setup-v4-allow-location')), findsOneWidget);
      expect(find.byKey(const Key('mobile-otp-method')), findsNothing);
    },
  );

  testWidgets(
    'call or app switch during Screen 01 restarts foreground handoff time',
    (tester) async {
      final session = JourneySession();
      final guard = LaunchInterruptionGuard();
      addTearDown(session.dispose);
      addTearDown(guard.dispose);
      addTearDown(() {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
      });

      await mountApp(tester, session: session, interruptionGuard: guard);
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.byKey(const Key('screen01-v2')), findsOneWidget);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 5));

      expect(session.stage, JourneyStage.setup);
      expect(find.byKey(const Key('screen01-v2')), findsOneWidget);
      expect(find.byKey(const Key('screen02-v4')), findsNothing);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(milliseconds: 2900));
      expect(find.byKey(const Key('screen01-v2')), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('screen02-v4')), findsOneWidget);
    },
  );

  testWidgets(
    'Screen 02 interruption and process death cannot create completion',
    (tester) async {
      final store = MemoryJourneyStore();
      final firstSession = JourneySession(store: store);
      final firstGuard = LaunchInterruptionGuard(
        minimumForegroundDuration: Duration.zero,
      );

      await mountApp(
        tester,
        session: firstSession,
        interruptionGuard: firstGuard,
      );
      await finishScreen01(tester);
      expect(find.byKey(const Key('screen02-v4')), findsOneWidget);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 2));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.byKey(const Key('screen02-v4')), findsOneWidget);
      expect(store.writeCount, 0);

      await tapVisible(tester, const Key('setup-v4-allow-location'));
      expect(
        find.byKey(const Key('setup-v4-resolved-location')),
        findsOneWidget,
      );
      expect(store.writeCount, 0);

      await tester.pumpWidget(const SizedBox.shrink());
      firstSession.dispose();
      firstGuard.dispose();

      final relaunchedSession = JourneySession(store: store);
      final relaunchedGuard = LaunchInterruptionGuard(
        minimumForegroundDuration: Duration.zero,
      );
      addTearDown(relaunchedSession.dispose);
      addTearDown(relaunchedGuard.dispose);

      await mountApp(
        tester,
        session: relaunchedSession,
        interruptionGuard: relaunchedGuard,
      );
      await finishScreen01(tester);

      expect(find.byKey(const Key('screen02-v4')), findsOneWidget);
      expect(find.byKey(const Key('setup-v4-allow-location')), findsOneWidget);
      expect(find.byKey(const Key('mobile-otp-method')), findsNothing);
      expect(store.writeCount, 0);
    },
  );

  testWidgets(
    'only an explicit Screen 02 completion permits a later sign-in handoff',
    (tester) async {
      final store = MemoryJourneyStore();
      final firstSession = JourneySession(store: store);
      final firstGuard = LaunchInterruptionGuard(
        minimumForegroundDuration: Duration.zero,
      );

      await mountApp(
        tester,
        session: firstSession,
        interruptionGuard: firstGuard,
      );
      await finishScreen01(tester);
      await tapVisible(tester, const Key('setup-v4-continue-for-now'));

      expect(find.byKey(const Key('mobile-otp-method')), findsOneWidget);
      expect(store.snapshot?.setupComplete, isTrue);
      expect(
        store.snapshot?.setupExperienceVersion,
        approvedSetupExperienceVersion,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      firstSession.dispose();
      firstGuard.dispose();

      final relaunchedSession = JourneySession(store: store);
      final relaunchedGuard = LaunchInterruptionGuard(
        minimumForegroundDuration: Duration.zero,
      );
      addTearDown(relaunchedSession.dispose);
      addTearDown(relaunchedGuard.dispose);

      await mountApp(
        tester,
        session: relaunchedSession,
        interruptionGuard: relaunchedGuard,
      );
      await finishScreen01(tester);

      expect(find.byKey(const Key('mobile-otp-method')), findsOneWidget);
      expect(find.byKey(const Key('screen02-v4')), findsNothing);
    },
  );
}
