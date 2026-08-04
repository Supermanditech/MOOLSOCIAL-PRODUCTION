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

  for (final phase in <(String, Duration)>[
    ('start', Duration.zero),
    ('wordmark', Duration(milliseconds: 400)),
    ('tagline', Duration(milliseconds: 850)),
    ('business', Duration(milliseconds: 1450)),
    ('settled', Duration(milliseconds: 2500)),
  ]) {
    testWidgets('R50 progressive launch phase ${phase.$1}', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final pending = Completer<JourneySnapshot?>();
      final session = JourneySession(store: _PendingJourneyStore(pending));
      final gate = LaunchPresentationGate();

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
      await tester.pump(phase.$2);
      await tester.pump(const Duration(milliseconds: 16));

      await expectLater(
        find.byKey(const Key('screen01-v2')),
        matchesGoldenFile(
          'goldens/moolsocial-progressive-lockup-${phase.$1}-360x720.png',
        ),
      );

      pending.complete(null);
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      gate.dispose();
      session.dispose();
    });
  }

  testWidgets('R50 reduced motion is complete at 320px and 140% text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final pending = Completer<JourneySnapshot?>();
    final session = JourneySession(store: _PendingJourneyStore(pending));
    final gate = LaunchPresentationGate();

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MoolTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 568),
            textScaler: TextScaler.linear(1.4),
            disableAnimations: true,
            accessibleNavigation: true,
          ),
          child: AppSplashScreenV2(session: session, presentationGate: gate),
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byKey(const Key('screen01-v2')),
      matchesGoldenFile(
        'goldens/moolsocial-progressive-lockup-reduced-320x568-140.png',
      ),
    );
    expect(tester.takeException(), isNull);

    pending.complete(null);
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    gate.dispose();
    session.dispose();
  });

  testWidgets('R50 settled lockup fits an iOS-size viewport', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final pending = Completer<JourneySnapshot?>();
    final session = JourneySession(store: _PendingJourneyStore(pending));
    final gate = LaunchPresentationGate();

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MoolTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            padding: EdgeInsets.fromLTRB(0, 47, 0, 34),
            viewPadding: EdgeInsets.fromLTRB(0, 47, 0, 34),
          ),
          child: AppSplashScreenV2(session: session, presentationGate: gate),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump(const Duration(milliseconds: 16));

    await expectLater(
      find.byKey(const Key('screen01-v2')),
      matchesGoldenFile(
        'goldens/moolsocial-progressive-lockup-settled-390x844-ios.png',
      ),
    );
    expect(tester.takeException(), isNull);

    pending.complete(null);
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    gate.dispose();
    session.dispose();
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
