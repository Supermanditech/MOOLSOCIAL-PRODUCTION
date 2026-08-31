import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(
    BuyV2Session session, {
    double textScale = 1,
    bool reducedMotion = false,
  }) {
    return MaterialApp(
      theme: MoolTheme.light(),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reducedMotion,
          ),
          child: child!,
        );
      },
      home: BuyV2Screen(
        session: session,
        initialDestination: session.destination,
        initialView: session.view,
      ),
    );
  }

  BuyV2Session productSession(String productId) {
    final session = BuyV2Session(core: BuySession());
    final product = session.product(productId);
    session.openDestination(product.destination);
    session.openProduct(product.id);
    return session;
  }

  Future<void> revealAction(WidgetTester tester, Finder action) async {
    final productScroll = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(action, 180, scrollable: productScroll);
    await tester.pumpAndSettle();
    final viewportHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final actionCenter = tester.getCenter(action).dy;
    if (actionCenter < 100) {
      await tester.drag(
        productScroll,
        Offset(0, (100 - actionCenter).clamp(0.0, 120.0)),
      );
    } else if (actionCenter > viewportHeight - 100) {
      await tester.drag(
        productScroll,
        Offset(0, -(actionCenter - (viewportHeight - 100)).clamp(0.0, 120.0)),
      );
    }
    await tester.pumpAndSettle();
  }

  test('seller selector is literal, same-vertical and deterministic', () {
    final session = productSession('s-oil');
    final shopOil = session.product('s-oil');
    final paracetamol = session.product('m-paracetamol-500');

    expect(session.sellerContinuationsFor(shopOil).map((item) => item.id), [
      's-soap',
      's-mustard-oil',
      's-groundnut-oil',
      's-ghee',
    ]);
    expect(session.sellerContinuationsFor(paracetamol).map((item) => item.id), [
      'm-ors',
      'm-metformin-500',
      'm-pantoprazole-40',
      'm-telmisartan-40',
    ]);
    expect(
      session
          .sellerContinuationsFor(shopOil)
          .every(
            (item) =>
                item.destination == shopOil.destination &&
                item.seller == shopOil.seller &&
                item.id != shopOil.id,
          ),
      isTrue,
    );
    expect(
      session.sellerContinuationsFor(shopOil, limit: 2).map((item) => item.id),
      ['s-soap', 's-mustard-oil'],
    );
    expect(
      session.sellerContinuationsFor(session.product('s-tomato')),
      isEmpty,
    );
    expect(session.sellerContinuationsFor(session.product('w-oil')), isEmpty);
    expect(session.sellerContinuationsFor(shopOil, limit: 0), isEmpty);
  });

  testWidgets('Shop exposes automatic fulfilment without seller continuation', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = productSession('s-oil');
    final product = session.product('s-oil');
    final expectedPromise = buyV2BuyerDeliveryPromise(
      session.productFactsFor(product),
    );

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    final automatic = find.byKey(
      const ValueKey('buy-automatic-fulfilment-s-oil'),
    );
    await revealAction(tester, automatic);
    expect(automatic, findsOneWidget);
    expect(
      find.byKey(const ValueKey('buy-shop-seller-action-s-oil')),
      findsNothing,
    );
    expect(find.text('Automatically assigned Mool Partner'), findsOneWidget);
    expect(find.text(expectedPromise), findsWidgets);
    expect(find.text('Ghar Bazaar'), findsNothing);
    expect(find.textContaining('MoolSocial price'), findsWidgets);
  });

  testWidgets('Medicine pharmacy action keeps prescription and safety facts', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final session = productSession('m-paracetamol-500');

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    final action = find.byKey(
      const ValueKey('buy-medicine-pharmacy-action-m-paracetamol-500'),
    );
    await revealAction(tester, action);
    final semanticAction = find.bySemanticsLabel(
      'View 4 more products from Sardarpura Health Pharmacy that are '
      'available now. Not medical advice',
    );
    expect(semanticAction, findsOneWidget);
    expect(
      tester
          .getSemantics(semanticAction)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );

    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.text('More from Sardarpura Health Pharmacy'), findsOneWidget);
    expect(find.textContaining('Not medical advice'), findsWidgets);
    expect(
      find.byKey(const ValueKey('buy-product-m-metformin-500')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-horizontal-product-grid')),
      findsOneWidget,
    );
    expect(find.text('Pain relief gel'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.product);
    expect(session.selectedProductId, 'm-paracetamol-500');
    expect(session.destination, BuyV2Destination.medicine);
    semantics.dispose();
  });

  testWidgets('automatic fulfilment is usable at 320px 140 percent', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = productSession('s-oil');

    await tester.pumpWidget(app(session, textScale: 1.4, reducedMotion: true));
    await tester.pumpAndSettle();
    final automatic = find.byKey(
      const ValueKey('buy-automatic-fulfilment-s-oil'),
    );
    await revealAction(tester, automatic);
    expect(automatic, findsOneWidget);
    expect(
      find.byKey(const ValueKey('buy-shop-seller-action-s-oil')),
      findsNothing,
    );
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'B01 T02 automatic fulfilment responsive founder captures',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      for (final viewport in const [
        (
          size: Size(320, 568),
          safe: EdgeInsets.symmetric(vertical: 24),
          textScale: 1.0,
          reduced: false,
          label: '320x568-android',
        ),
        (
          size: Size(360, 800),
          safe: EdgeInsets.symmetric(vertical: 24),
          textScale: 1.0,
          reduced: false,
          label: '360x800-android',
        ),
        (
          size: Size(390, 844),
          safe: EdgeInsets.only(top: 47, bottom: 34),
          textScale: 1.0,
          reduced: false,
          label: '390x844-ios',
        ),
        (
          size: Size(430, 932),
          safe: EdgeInsets.only(top: 59, bottom: 34),
          textScale: 1.0,
          reduced: false,
          label: '430x932-ios',
        ),
        (
          size: Size(320, 568),
          safe: EdgeInsets.symmetric(vertical: 24),
          textScale: 1.4,
          reduced: true,
          label: '320x568-a11y140-reduced',
        ),
      ]) {
        tester.view.physicalSize = viewport.size;
        final session = productSession('s-oil');
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: MoolTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: viewport.safe,
                viewPadding: viewport.safe,
                textScaler: TextScaler.linear(viewport.textScale),
                disableAnimations: viewport.reduced,
              ),
              child: child!,
            ),
            home: BuyV2Screen(
              session: session,
              initialDestination: BuyV2Destination.shop,
              initialView: session.view,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final automatic = find.byKey(
          const ValueKey('buy-automatic-fulfilment-s-oil'),
        );
        await revealAction(tester, automatic);
        expect(automatic, findsOneWidget);
        expect(
          find.byKey(const ValueKey('buy-shop-seller-action-s-oil')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(const ValueKey('buy-v2-screen')),
          matchesGoldenFile(
            'candidate_captures/'
            'buy-v2-b01-t02-auto-fulfilment-${viewport.label}.png',
          ),
        );

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        session.dispose();
      }
    },
    // Run explicitly with --run-skipped --update-goldens for evidence.
    skip: true,
  );
}
