import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moolsocial/features/retailer/retailer_session.dart';
import 'package:moolsocial/ui_v2/social/social_v2_design.dart';
import 'package:moolsocial/ui_v2/social/social_v2_plans_promotion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Promote keeps the explicit active Store visible across steps', (
    tester,
  ) async {
    final session = RetailerSession();
    addTearDown(session.dispose);

    await _pump(
      tester,
      SocialPromotionV2Screen(
        session: session,
        initialStep: 2,
        workspaceName: 'Mahadev Fresh Mart',
        workspaceId: 'store-510001',
      ),
    );

    expect(
      find.byKey(const Key('social-promotion-workspace-scope')),
      findsOneWidget,
    );
    expect(find.text('CAMPAIGN FOR'), findsOneWidget);
    expect(find.text('Mahadev Fresh Mart'), findsOneWidget);
    expect(find.text('store-510001'), findsOneWidget);

    await tester.tap(find.byKey(const Key('social-promotion-content-reel')));
    await tester.pumpAndSettle();

    expect(find.text('Choose the audience'), findsOneWidget);
    expect(find.text('Mahadev Fresh Mart'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Promote reads active Store identity from route parameters', (
    tester,
  ) async {
    final session = RetailerSession();
    addTearDown(session.dispose);
    final router = GoRouter(
      initialLocation:
          '/app/social/promote?workspaceName=Jodhpur%20Daily%20Needs&workspaceId=WK-2202&step=2',
      routes: [
        GoRoute(
          path: '/app/social/promote',
          builder: (context, state) => SocialPromotionV2Screen(
            session: session,
            initialStep: int.tryParse(state.uri.queryParameters['step'] ?? ''),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Jodhpur Daily Needs'), findsOneWidget);
    expect(find.text('WK-2202'), findsOneWidget);
    expect(find.text('Choose what people will see'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Promote selection uses premium navy and saffron surfaces', (
    tester,
  ) async {
    final session = RetailerSession();
    addTearDown(session.dispose);
    await _pump(
      tester,
      SocialPromotionV2Screen(session: session, initialStep: 1),
    );

    final hero = tester.widget<Container>(
      find.byKey(const Key('social-promotion-premium-hero-surface')),
    );
    final heroDecoration = hero.decoration! as BoxDecoration;
    final heroGradient = heroDecoration.gradient! as LinearGradient;
    expect(heroGradient.colors, contains(SocialV2Colors.navy));
    expect(heroDecoration.border!.top.color, SocialV2Colors.saffron);

    final iconSurface = tester.widget<Container>(
      find.byKey(const Key('social-promotion-action-icon')).first,
    );
    final iconDecoration = iconSurface.decoration! as BoxDecoration;
    expect(iconDecoration.color, SocialV2Colors.navy);
    expect(iconDecoration.gradient, isNull);
    expect(iconDecoration.border!.top.color, SocialV2Colors.saffron);

    await tester.tap(
      find.byKey(const Key('social-promotion-goal-increaseSales')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('social-promotion-premium-progress')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('all Promote states fit compact OPPO-width layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final state in const <(int?, String?)>[
      (1, null),
      (2, null),
      (3, null),
      (4, null),
      (5, null),
      (null, 'failure'),
      (null, 'live'),
    ]) {
      final session = RetailerSession();
      await _pump(
        tester,
        SocialPromotionV2Screen(
          session: session,
          initialStep: state.$1,
          initialState: state.$2,
          workspaceName: 'Mahadev Fresh Mart',
        ),
      );
      expect(tester.takeException(), isNull, reason: '$state');
      session.dispose();
    }
  });
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: child,
    ),
  );
  await tester.pumpAndSettle();
}
