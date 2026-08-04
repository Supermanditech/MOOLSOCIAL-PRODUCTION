import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/ui_v2/motion/mool_buy_tap_acknowledgement.dart';

void main() {
  Future<void> pumpHarness(
    WidgetTester tester, {
    required ValueNotifier<RouteInformation> route,
    bool disableAnimations = false,
    VoidCallback? onTap,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: MoolBuyTapAcknowledgement(
            routeInformation: route,
            child: Material(
              child: Semantics(
                label: 'Underlying action',
                button: true,
                child: InkWell(onTap: onTap, child: const SizedBox.expand()),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('Buy pointer press acknowledges contact and passes the tap', (
    tester,
  ) async {
    final route = ValueNotifier(
      RouteInformation(uri: Uri.parse('/app/buy?destination=shop')),
    );
    addTearDown(route.dispose);
    var taps = 0;
    await pumpHarness(tester, route: route, onTap: () => taps += 1);

    final gesture = await tester.startGesture(const Offset(120, 260));
    await tester.pump(const Duration(milliseconds: 55));

    expect(
      tester
          .widget<AnimatedOpacity>(
            find.byKey(const ValueKey('mool-buy-tap-visual')),
          )
          .opacity,
      .92,
    );
    expect(
      tester.getCenter(find.byKey(const ValueKey('mool-buy-tap-visual'))),
      const Offset(120, 260),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('mool-buy-tap-ring'))),
      const Size.square(28),
    );

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 110));
    expect(taps, 1);
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.byKey(const ValueKey('mool-buy-tap-visual')),
          )
          .opacity,
      0,
    );
  });

  testWidgets('movement beyond touch slop cancels false tap feedback', (
    tester,
  ) async {
    final route = ValueNotifier(RouteInformation(uri: Uri.parse('/app/buy')));
    addTearDown(route.dispose);
    await pumpHarness(tester, route: route);

    final gesture = await tester.startGesture(const Offset(100, 200));
    await tester.pump();
    await gesture.moveBy(const Offset(kTouchSlop + 1, 0));
    await tester.pump();

    expect(
      tester
          .widget<AnimatedOpacity>(
            find.byKey(const ValueKey('mool-buy-tap-visual')),
          )
          .opacity,
      0,
    );
    await gesture.cancel();
  });

  testWidgets('acknowledgement is absent outside Buy routes', (tester) async {
    final route = ValueNotifier(
      RouteInformation(uri: Uri.parse('/app/social')),
    );
    addTearDown(route.dispose);
    await pumpHarness(tester, route: route);

    final gesture = await tester.startGesture(const Offset(80, 160));
    await tester.pump();
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.byKey(const ValueKey('mool-buy-tap-visual')),
          )
          .opacity,
      0,
    );
    await gesture.up();
  });

  testWidgets('route departure clears an active acknowledgement', (
    tester,
  ) async {
    final route = ValueNotifier(RouteInformation(uri: Uri.parse('/app/buy')));
    addTearDown(route.dispose);
    await pumpHarness(tester, route: route);

    final gesture = await tester.startGesture(const Offset(90, 180));
    await tester.pump();
    route.value = RouteInformation(uri: Uri.parse('/app/social'));
    await tester.pump();

    expect(
      tester
          .widget<AnimatedOpacity>(
            find.byKey(const ValueKey('mool-buy-tap-visual')),
          )
          .opacity,
      0,
    );
    await gesture.cancel();
  });

  testWidgets('reduced motion keeps a static held cue with zero durations', (
    tester,
  ) async {
    final route = ValueNotifier(RouteInformation(uri: Uri.parse('/app/buy')));
    addTearDown(route.dispose);
    await pumpHarness(tester, route: route, disableAnimations: true);

    final gesture = await tester.startGesture(const Offset(70, 140));
    await tester.pump();
    final opacity = tester.widget<AnimatedOpacity>(
      find.byKey(const ValueKey('mool-buy-tap-visual')),
    );
    final scale = tester.widget<AnimatedScale>(
      find.byKey(const ValueKey('mool-buy-tap-scale')),
    );
    expect(opacity.opacity, .92);
    expect(opacity.duration, Duration.zero);
    expect(scale.duration, Duration.zero);

    await gesture.up();
    await tester.pump();
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.byKey(const ValueKey('mool-buy-tap-visual')),
          )
          .opacity,
      0,
    );
  });

  testWidgets('visual adds no semantics node of its own', (tester) async {
    final route = ValueNotifier(RouteInformation(uri: Uri.parse('/app/buy')));
    addTearDown(route.dispose);
    final semantics = tester.ensureSemantics();
    await pumpHarness(tester, route: route);

    expect(find.bySemanticsLabel('Underlying action'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Underlying action')).label,
      'Underlying action',
    );
    semantics.dispose();
  });

  testWidgets('real Mool rail navigation activates the Buy-only layer', (
    tester,
  ) async {
    final journey = JourneySession(
      store: MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'manual',
          areaLabel: 'Sardarpura',
          setupComplete: true,
        ),
      ),
      otpGateway: ReviewOtpGateway(signedIn: true),
    );
    addTearDown(journey.dispose);
    await journey.start();
    await tester.pumpWidget(
      MoolSocialApp(session: journey, initialLocation: '/app/social'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('screen04-mool')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('screen04-rail-buy')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-v2-screen')), findsOneWidget);
    expect(
      tester
          .widget<MoolBuyTapAcknowledgement>(
            find.byType(MoolBuyTapAcknowledgement),
          )
          .isBuyActive!(),
      isTrue,
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('buy-search-control'))),
    );
    await tester.pump(const Duration(milliseconds: 55));
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.byKey(const ValueKey('mool-buy-tap-visual')),
          )
          .opacity,
      .92,
    );
    await gesture.up();
  });
}
