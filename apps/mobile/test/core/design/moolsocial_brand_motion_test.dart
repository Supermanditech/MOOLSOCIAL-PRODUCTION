import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/moolsocial_brand_motion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cadence permits one session playback and rate-limits interaction', () {
    var now = DateTime.utc(2026, 8, 1, 8);
    final cadence = MoolSocialBrandCadence(now: () => now);

    expect(cadence.consumeAutomaticReplay(1), isTrue);
    expect(cadence.consumeAutomaticReplay(1), isFalse);
    expect(cadence.requestInteractionReplay(), isFalse);

    now = now.add(const Duration(minutes: 11));
    cadence.noteActivity();
    expect(cadence.interactionReplayArmed, isTrue);
    expect(cadence.requestInteractionReplay(), isFalse);

    now = now.add(const Duration(minutes: 9));
    expect(cadence.requestInteractionReplay(), isTrue);
    expect(cadence.interactionReplayArmed, isFalse);
  });

  test('a long background pause creates one automatic replay generation', () {
    var now = DateTime.utc(2026, 8, 1, 8);
    final cadence = MoolSocialBrandCadence(now: () => now);
    expect(cadence.consumeAutomaticReplay(1), isTrue);

    cadence.appPaused();
    now = now.add(const Duration(minutes: 20));
    cadence.appPaused();
    cadence.appResumed();

    expect(cadence.autoReplayGeneration, 2);
    expect(cadence.consumeAutomaticReplay(2), isTrue);
    expect(cadence.consumeAutomaticReplay(2), isFalse);
  });

  testWidgets(
    'cold start paints one full wordmark then completes one sleek settle',
    (tester) async {
      await tester.pumpWidget(_app(const MoolSocialBrandMotion()));

      final frame = find.byKey(const ValueKey('moolsocial-brand-motion-frame'));
      expect(tester.getSize(frame), const Size(118, 44));
      expect(find.text('MoolSocial'), findsOneWidget);
      expect(
        _opacity(tester, 'moolsocial-brand-wordmark-opacity'),
        closeTo(.54, .01),
      );

      final startTransform = _matrix(
        tester,
        'moolsocial-brand-wordmark-transform',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 420));
      expect(tester.getSize(frame), const Size(118, 44));
      expect(
        _opacity(tester, 'moolsocial-brand-wordmark-opacity'),
        greaterThan(.54),
      );
      expect(
        _matrix(tester, 'moolsocial-brand-wordmark-transform'),
        isNot(orderedEquals(startTransform)),
      );

      await tester.pump(MoolSocialBrandMotion.duration);
      expect(tester.getSize(frame), const Size(118, 44));
      expect(_opacity(tester, 'moolsocial-brand-wordmark-opacity'), 1);
      final settledTransform = _matrix(
        tester,
        'moolsocial-brand-wordmark-transform',
      );

      await tester.pump(const Duration(seconds: 5));
      expect(tester.getSize(frame), const Size(118, 44));
      expect(
        _matrix(tester, 'moolsocial-brand-wordmark-transform'),
        orderedEquals(settledTransform),
      );
      expect(tester.binding.transientCallbackCount, 0);
    },
  );

  testWidgets('one shared cadence animates only one visible owner', (
    tester,
  ) async {
    final cadence = MoolSocialBrandCadence();
    await tester.pumpWidget(
      _app(
        MoolSocialBrandMotionScope(
          cadence: cadence,
          child: const Row(
            children: [
              MoolSocialBrandMotion(key: ValueKey('first-brand')),
              MoolSocialBrandMotion(key: ValueKey('second-brand')),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(_descendantOpacity(tester, 'first-brand'), greaterThan(.54));
    expect(_descendantOpacity(tester, 'first-brand'), lessThan(1));
    expect(_descendantOpacity(tester, 'second-brand'), 1);
    expect(
      tester.getSize(find.byKey(const ValueKey('first-brand'))).width,
      118,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('second-brand'))).width,
      118,
    );
  });

  testWidgets('reduced motion renders the static complete wordmark', (
    tester,
  ) async {
    var pressed = 0;
    await tester.pumpWidget(
      _app(
        MoolSocialBrandMotion(onPressed: () => pressed += 1),
        disableAnimations: true,
      ),
    );
    await tester.pump();

    expect(
      tester.getSize(
        find.byKey(const ValueKey('moolsocial-brand-motion-frame')),
      ),
      const Size(118, 44),
    );
    expect(find.text('MoolSocial'), findsOneWidget);
    expect(_opacity(tester, 'moolsocial-brand-wordmark-opacity'), 1);
    expect(find.bySemanticsLabel('MoolSocial'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('moolsocial-brand-hit-owner')));
    await tester.pump(const Duration(seconds: 2));
    expect(pressed, 1);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('stacked header mark reveals Social from depth in fixed space', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const MoolSocialBrandMotion(
          width: 78,
          height: 44,
          fontSize: 17,
          onDarkBackground: true,
          layout: MoolSocialBrandLayout.stackedWords,
          motionDuration: Duration(milliseconds: 1500),
          useSharedCadence: false,
        ),
      ),
    );
    await tester.pump();

    final frame = find.byKey(const ValueKey('moolsocial-brand-motion-frame'));
    expect(tester.getSize(frame), const Size(78, 44));
    expect(
      find.byKey(const ValueKey('moolsocial-brand-surface')),
      findsNothing,
    );
    expect(find.text('Mool'), findsOneWidget);
    expect(find.text('Social'), findsOneWidget);
    expect(_opacity(tester, 'moolsocial-brand-stacked-mool-opacity'), 0);
    expect(_opacity(tester, 'moolsocial-brand-stacked-social-opacity'), 0);

    final moolStart = _matrix(tester, 'moolsocial-brand-stacked-mool-depth');
    await tester.pump(const Duration(milliseconds: 280));
    expect(
      _opacity(tester, 'moolsocial-brand-stacked-mool-opacity'),
      inExclusiveRange(0, 1),
    );
    expect(
      _matrix(tester, 'moolsocial-brand-stacked-mool-depth'),
      isNot(orderedEquals(moolStart)),
    );

    await tester.pump(const Duration(milliseconds: 370));
    expect(tester.getSize(frame), const Size(78, 44));
    expect(
      _opacity(tester, 'moolsocial-brand-stacked-social-opacity'),
      inExclusiveRange(0, 1),
    );
    expect(
      _matrix(tester, 'moolsocial-brand-stacked-social-depth'),
      isNot(orderedEquals(Matrix4.identity().storage)),
    );

    await tester.pump(const Duration(milliseconds: 1500));
    expect(_opacity(tester, 'moolsocial-brand-stacked-social-opacity'), 1);
    expect(find.bySemanticsLabel('MoolSocial'), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('stacked header mark is complete when motion is reduced', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const MoolSocialBrandMotion(
          width: 78,
          height: 44,
          fontSize: 17,
          onDarkBackground: true,
          layout: MoolSocialBrandLayout.stackedWords,
          motionDuration: Duration(milliseconds: 1500),
          useSharedCadence: false,
        ),
        disableAnimations: true,
      ),
    );
    await tester.pump();

    expect(
      tester.getSize(
        find.byKey(const ValueKey('moolsocial-brand-motion-frame')),
      ),
      const Size(78, 44),
    );
    expect(_opacity(tester, 'moolsocial-brand-stacked-social-opacity'), 1);
    expect(find.bySemanticsLabel('MoolSocial'), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('full wordmark stays bounded at 320 px and 140 percent text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      _app(
        const MoolSocialBrandMotion(autoPlay: false),
        textScaler: const TextScaler.linear(1.4),
      ),
    );

    final frame = find.byKey(const ValueKey('moolsocial-brand-motion-frame'));
    final wordmark = find.byKey(const ValueKey('moolsocial-brand-wordmark'));
    expect(tester.getSize(frame), const Size(118, 44));
    expect(
      tester.getRect(frame).contains(tester.getRect(wordmark).topLeft),
      isTrue,
    );
    expect(
      tester.getRect(frame).contains(tester.getRect(wordmark).bottomRight),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
}

Widget _app(
  Widget child, {
  bool disableAnimations = false,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        size: const Size(390, 844),
        disableAnimations: disableAnimations,
        accessibleNavigation: disableAnimations,
        textScaler: textScaler,
      ),
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

double _opacity(WidgetTester tester, String key) {
  return tester.widget<Opacity>(find.byKey(ValueKey<String>(key))).opacity;
}

double _descendantOpacity(WidgetTester tester, String ownerKey) {
  return tester
      .widget<Opacity>(
        find.descendant(
          of: find.byKey(ValueKey<String>(ownerKey)),
          matching: find.byKey(
            const ValueKey('moolsocial-brand-wordmark-opacity'),
          ),
        ),
      )
      .opacity;
}

List<double> _matrix(WidgetTester tester, String key) {
  return List<double>.of(
    tester
        .widget<Transform>(find.byKey(ValueKey<String>(key)))
        .transform
        .storage,
  );
}
