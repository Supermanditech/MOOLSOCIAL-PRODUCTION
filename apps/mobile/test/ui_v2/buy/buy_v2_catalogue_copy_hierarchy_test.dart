import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(
    BuyV2Session session, {
    required Size size,
    double textScale = 1,
    bool offers = false,
  }) {
    return MaterialApp(
      theme: MoolTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          size: size,
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: BuyV2Screen(session: session, initialOffersActive: offers),
    );
  }

  testWidgets(
    'compact search names the current customer task without clipping',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.reset);
      final semantics = tester.ensureSemantics();
      final core = BuySession();
      final session = BuyV2Session(core: core);

      await tester.pumpWidget(app(session, size: const Size(360, 800)));
      await tester.pumpAndSettle();
      expect(find.text('Search products'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('Search products, brands and codes')),
        findsOneWidget,
      );

      session.openDestination(BuyV2Destination.wholesale);
      await tester.pumpAndSettle();
      expect(find.text('Search bulk products'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('Search bulk products and suppliers')),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      session.dispose();
      core.dispose();

      final offersCore = BuySession();
      final offersSession = BuyV2Session(core: offersCore);
      await tester.pumpWidget(
        app(offersSession, size: const Size(360, 800), offers: true),
      );
      await tester.pumpAndSettle();
      expect(find.text('Search current offers'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('Search offers, products and sellers')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      offersSession.dispose();
      offersCore.dispose();
      semantics.dispose();
    },
  );

  testWidgets('promotion hierarchy wraps primary copy at compact large text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    addTearDown(tester.view.reset);
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);

    await tester.pumpWidget(
      app(session, size: const Size(320, 700), textScale: 1.4),
    );
    await tester.pumpAndSettle();

    final promotionRail = find.byKey(
      const ValueKey('buy-catalogue-promotions'),
    );
    expect(tester.getSize(promotionRail).height, 118);
    final title = tester.widget<Text>(find.text('Plan the monthly basket'));
    final detail = tester.widget<Text>(
      find.text('Review a ready household product list'),
    );
    expect(title.maxLines, 2);
    expect(title.style?.fontSize, greaterThanOrEqualTo(10.5));
    expect(detail.maxLines, 2);
    expect(detail.style?.fontSize, greaterThanOrEqualTo(9.5));
    expect(tester.takeException(), isNull);
  });
}
