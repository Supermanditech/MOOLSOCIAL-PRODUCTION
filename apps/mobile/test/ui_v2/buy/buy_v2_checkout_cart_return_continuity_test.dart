import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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
    Size size = const Size(390, 844),
    double textScale = 1,
    bool reducedMotion = false,
    EdgeInsets safeArea = EdgeInsets.zero,
  }) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: MoolTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          size: size,
          padding: safeArea,
          viewPadding: safeArea,
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reducedMotion,
        ),
        child: child!,
      ),
      home: BuyV2Screen(
        session: session,
        initialDestination: session.destination,
        initialView: session.view,
        initialCartScope: session.cartScope,
      ),
    );
  }

  BuyV2Product productFor(BuyV2Destination destination) =>
      BuyV2Catalogue.products.firstWhere(
        (product) =>
            product.destination == destination && !product.requiresPrescription,
      );

  BuyV2Session mixedSession() {
    final session = BuyV2Session(core: BuySession());
    for (final destination in const [
      BuyV2Destination.shop,
      BuyV2Destination.wholesale,
      BuyV2Destination.medicine,
    ]) {
      expect(session.addProduct(productFor(destination).id), isTrue);
    }
    return session;
  }

  testWidgets('visible Checkout return restores every exact Cart scope', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final semantics = tester.ensureSemantics();

    for (final scope in BuyV2CartScope.values) {
      final session = mixedSession();
      addTearDown(session.dispose);
      session.openCart(scope: scope);
      session.rememberCartScrollOffset(scope, 37);
      expect(session.openCheckout(), isTrue, reason: scope.name);
      final itemCount = session.checkoutItemCount;
      final total = session.checkoutPayableTotal;
      final addressId = session.selectedAddress.id;
      final payment = session.selectedPayment;

      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();

      final returnOwner = find.byKey(
        const ValueKey('buy-checkout-return-cart'),
      );
      expect(returnOwner, findsOneWidget, reason: scope.name);
      final semanticNode = tester.getSemantics(returnOwner);
      final semanticData = semanticNode.getSemanticsData();
      expect(semanticData.label, 'Cart', reason: scope.name);
      expect(
        semanticData.hasAction(SemanticsAction.tap),
        isTrue,
        reason: scope.name,
      );
      expect(semanticNode.rect.width, lessThan(140), reason: scope.name);
      expect(semanticNode.rect.height, greaterThanOrEqualTo(44));

      await tester.tapAt(tester.getCenter(returnOwner));
      await tester.pumpAndSettle();

      expect(session.view, BuyV2View.cart, reason: scope.name);
      expect(session.cartScope, scope, reason: scope.name);
      expect(session.scopedItemCount, itemCount, reason: scope.name);
      expect(session.scopedPayableTotal, total, reason: scope.name);
      expect(session.selectedAddress.id, addressId, reason: scope.name);
      expect(session.selectedPayment, payment, reason: scope.name);
      expect(session.cartScrollOffsetFor(scope), 37, reason: scope.name);
      expect(tester.takeException(), isNull, reason: scope.name);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
    semantics.dispose();
  });

  testWidgets('visible return and Android Back preserve identical Shop state', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    BuyV2Session checkout() {
      final session = mixedSession();
      session.openCart(scope: BuyV2CartScope.shop);
      expect(session.openCheckout(), isTrue);
      return session;
    }

    final visible = checkout();
    final android = checkout();
    addTearDown(visible.dispose);
    addTearDown(android.dispose);

    await tester.pumpWidget(app(visible));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-checkout-return-cart')));
    await tester.pumpAndSettle();

    android.goBack();

    expect(visible.view, android.view);
    expect(visible.cartScope, android.cartScope);
    expect(visible.scopedItemCount, android.scopedItemCount);
    expect(visible.scopedPayableTotal, android.scopedPayableTotal);
    expect(visible.selectedAddress.id, android.selectedAddress.id);
    expect(visible.selectedPayment, android.selectedPayment);
    expect(
      {for (final line in visible.cartLines) line.product.id: line.quantity},
      {for (final line in android.cartLines) line.product.id: line.quantity},
    );
  });

  testWidgets('320px 140% reduced motion keeps one static compact owner', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final semantics = tester.ensureSemantics();
    final session = mixedSession();
    addTearDown(session.dispose);
    session.openCart(scope: BuyV2CartScope.medicine);
    expect(session.openCheckout(), isTrue);

    await tester.pumpWidget(
      app(
        session,
        size: const Size(320, 568),
        textScale: 1.4,
        reducedMotion: true,
      ),
    );
    await tester.pump();

    final owner = find.byKey(const ValueKey('buy-checkout-return-cart'));
    expect(owner, findsOneWidget);
    final semanticNode = tester.getSemantics(owner);
    expect(
      semanticNode.getSemanticsData().hasAction(SemanticsAction.tap),
      true,
    );
    expect(semanticNode.rect.width, lessThan(150));
    expect(semanticNode.rect.height, greaterThanOrEqualTo(44));
    expect(find.textContaining('Medicine fulfilment ·'), findsOneWidget);
    expect(find.textContaining('Shop fulfilment ·'), findsNothing);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets(
    'R58.8.6 responsive Android and iOS candidate captures',
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
        final session = mixedSession();
        session.openCart(scope: BuyV2CartScope.shop);
        expect(session.openCheckout(), isTrue);

        await tester.pumpWidget(
          app(
            session,
            size: viewport.size,
            textScale: viewport.textScale,
            reducedMotion: viewport.reduced,
            safeArea: viewport.safe,
          ),
        );
        await tester.pumpAndSettle();

        final owner = find.byKey(const ValueKey('buy-checkout-return-cart'));
        expect(owner, findsOneWidget, reason: viewport.label);
        expect(
          tester.getRect(owner).height,
          greaterThanOrEqualTo(44),
          reason: viewport.label,
        );
        expect(tester.takeException(), isNull, reason: viewport.label);
        await expectLater(
          find.byKey(const ValueKey('buy-v2-screen')),
          matchesGoldenFile(
            'candidate_captures/'
            'buy-v2-r58-8-6-c24f-checkout-cart-return-${viewport.label}.png',
          ),
        );

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        session.dispose();
      }
    },
    tags: 'protected-reference',
  );
}
