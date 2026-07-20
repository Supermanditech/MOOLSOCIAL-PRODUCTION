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

  testWidgets('Screen 01 Flutter V2 comparison capture at 360x720', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final read = Completer<JourneySnapshot?>();
    final session = JourneySession(store: _PendingJourneyStore(read));
    final gate = LaunchPresentationGate();
    addTearDown(session.dispose);
    addTearDown(gate.dispose);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MoolTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(size: Size(360, 720)),
          child: AppSplashScreenV2(session: session, presentationGate: gate),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    await expectLater(
      find.byKey(const Key('screen01-v2')),
      matchesGoldenFile(
        'goldens/ui_v2_screen01_normal-motion-midpoint-360x720.png',
      ),
    );

    await tester.pump(const Duration(milliseconds: 2200));
    read.complete(null);
    await tester.pump();
  });

  testWidgets('Screen 01 slow handoff comparison capture at 360x720', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final read = Completer<JourneySnapshot?>();
    final session = JourneySession(store: _PendingJourneyStore(read));
    final gate = LaunchPresentationGate();
    addTearDown(session.dispose);
    addTearDown(gate.dispose);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MoolTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(size: Size(360, 720)),
          child: AppSplashScreenV2(session: session, presentationGate: gate),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3000));

    await expectLater(
      find.byKey(const Key('screen01-v2')),
      matchesGoldenFile('goldens/ui_v2_screen01_handoff-360x720.png'),
    );

    read.complete(null);
    await tester.pump();
  });

  testWidgets('Screen 01 recovery comparison capture at 360x720', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final session = JourneySession(
      store: MemoryJourneyStore(readFailure: StateError('offline')),
    );
    final gate = LaunchPresentationGate();
    addTearDown(session.dispose);
    addTearDown(gate.dispose);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MoolTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(size: Size(360, 720)),
          child: AppSplashScreenV2(session: session, presentationGate: gate),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await expectLater(
      find.byKey(const Key('screen01-v2')),
      matchesGoldenFile('goldens/ui_v2_screen01_recovery-360x720.png'),
    );

    await tester.pump(const Duration(milliseconds: 3000));
  });
}

class _PendingJourneyStore implements JourneyStore {
  _PendingJourneyStore(this.readResult);

  final Completer<JourneySnapshot?> readResult;

  @override
  Future<JourneySnapshot?> read() => readResult.future;

  @override
  Future<void> write(JourneySnapshot value) async {}
}
