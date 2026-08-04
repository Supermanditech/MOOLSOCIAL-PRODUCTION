import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/ui_v2/launch/launch_presentation_gate.dart';
import 'package:moolsocial/ui_v2/screens/screen01_app_splash/app_splash_screen_v2.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> mountSplash(
    WidgetTester tester, {
    required JourneySession session,
    required LaunchPresentationGate gate,
    bool reduceMotion = false,
  }) async {
    await tester.binding.setSurfaceSize(const Size(360, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MoolTheme.light(),
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(360, 720),
            disableAnimations: reduceMotion,
            accessibleNavigation: reduceMotion,
          ),
          child: AppSplashScreenV2(session: session, presentationGate: gate),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'progressive lockup reveals wordmark tagline business then settles',
    (tester) async {
      final read = Completer<JourneySnapshot?>();
      final store = _ControlledJourneyStore(read);
      final session = JourneySession(store: store);
      final gate = LaunchPresentationGate();
      addTearDown(session.dispose);
      addTearDown(gate.dispose);

      await mountSplash(tester, session: session, gate: gate);

      expect(find.byKey(const Key('splash-v2-normal')), findsOneWidget);
      expect(find.text('Create. Connect. Work. Grow.'), findsOneWidget);
      expect(find.text('One app for life and business.'), findsOneWidget);
      expect(find.text('MoolSocial'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('moolsocial-brand-identity-line')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('splash-v2-footer-line')), findsNothing);
      expect(find.byKey(const Key('splash-v2-moving-tricolour')), findsNothing);
      expect(_opacity(tester, 'splash-v2-tagline-stage'), 0);
      expect(_opacity(tester, 'splash-v2-business-stage'), 0);

      await tester.pump(const Duration(milliseconds: 400));
      expect(
        _opacity(tester, 'moolsocial-brand-wordmark-opacity'),
        greaterThan(.9),
      );
      expect(_opacity(tester, 'splash-v2-tagline-stage'), 0);
      expect(_opacity(tester, 'splash-v2-business-stage'), 0);

      await tester.pump(const Duration(milliseconds: 400));
      expect(_opacity(tester, 'splash-v2-tagline-stage'), greaterThan(0));
      expect(_opacity(tester, 'splash-v2-business-stage'), 0);

      await tester.pump(const Duration(milliseconds: 600));
      expect(_opacity(tester, 'splash-v2-tagline-stage'), 1);
      expect(_opacity(tester, 'splash-v2-business-stage'), greaterThan(0));

      await tester.pump(const Duration(milliseconds: 1000));
      expect(_opacity(tester, 'splash-v2-business-stage'), 1);

      await tester.pump(const Duration(milliseconds: 650));
      expect(find.byKey(const Key('splash-v2-handoff')), findsOneWidget);
      expect(find.text('Still opening your MoolSocial space'), findsOneWidget);
      expect(find.textContaining('app version'), findsNothing);
      expect(find.textContaining('Network connected'), findsNothing);
      expect(find.textContaining('route selected'), findsNothing);
      expect(tester.takeException(), isNull);

      read.complete(null);
      await tester.pump();
    },
  );

  testWidgets('reduced motion shows one static complete lockup', (
    tester,
  ) async {
    final read = Completer<JourneySnapshot?>();
    final session = JourneySession(store: _ControlledJourneyStore(read));
    final gate = LaunchPresentationGate();
    addTearDown(session.dispose);
    addTearDown(gate.dispose);

    await mountSplash(tester, session: session, gate: gate, reduceMotion: true);

    expect(find.byKey(const Key('splash-v2-moving-tricolour')), findsNothing);
    expect(find.byKey(const Key('splash-v2-footer-line')), findsNothing);
    expect(
      find.byKey(const ValueKey('moolsocial-brand-identity-line')),
      findsOneWidget,
    );
    expect(find.text('India Ka Socio Commerce App'), findsOneWidget);
    expect(_opacity(tester, 'splash-v2-tagline-stage'), 1);
    expect(_opacity(tester, 'splash-v2-business-stage'), 1);
    expect(tester.takeException(), isNull);

    read.complete(null);
    await tester.pump(const Duration(milliseconds: 3000));
  });

  testWidgets('boot failure exposes Retry and preserves Help intent', (
    tester,
  ) async {
    final store = MemoryJourneyStore(readFailure: StateError('offline'));
    final session = JourneySession(store: store);
    final gate = LaunchPresentationGate();
    addTearDown(session.dispose);
    addTearDown(gate.dispose);

    await mountSplash(tester, session: session, gate: gate);
    await tester.pump();

    expect(find.byKey(const Key('splash-v2-recovery')), findsOneWidget);
    expect(find.text('Connection paused'), findsOneWidget);
    expect(find.byKey(const Key('retry-boot')), findsOneWidget);
    expect(find.byKey(const Key('boot-help')), findsOneWidget);

    await tester.tap(find.byKey(const Key('boot-help')));
    await tester.pump();
    expect(session.returnTo, '/app/chat');
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 3000));
  });
}

double _opacity(WidgetTester tester, String key) {
  return tester.widget<Opacity>(find.byKey(ValueKey<String>(key))).opacity;
}

class _ControlledJourneyStore implements JourneyStore {
  _ControlledJourneyStore(this.readResult);

  final Completer<JourneySnapshot?> readResult;
  JourneySnapshot? snapshot;

  @override
  Future<JourneySnapshot?> read() => readResult.future;

  @override
  Future<void> write(JourneySnapshot value) async {
    snapshot = value;
  }
}
