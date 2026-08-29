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

  BuyV2Session newSession() => BuyV2Session(core: BuySession());

  BuyV2Product firstProduct(BuyV2Destination destination) =>
      BuyV2Catalogue.products.firstWhere(
        (product) =>
            product.destination == destination && !product.requiresPrescription,
      );

  Widget app(
    BuyV2Session session, {
    double textScale = 1,
    bool reducedMotion = false,
    EdgeInsets safeArea = EdgeInsets.zero,
  }) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: MoolTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
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
      ),
    );
  }

  void arrangeMedicineWithUnrelatedShopCart(BuyV2Session session) {
    expect(session.addProduct(firstProduct(BuyV2Destination.shop).id), isTrue);
    session.openDestination(BuyV2Destination.medicine);
    session.updateQuery('paracetmol');
  }

  test('primary and Android Back restore exact origin, not unrelated Cart', () {
    for (final usePrimary in [false, true]) {
      final session = newSession();
      arrangeMedicineWithUnrelatedShopCart(session);
      final itemCount = session.itemCount;
      final cartTotal = session.cartTotal;

      session.openRecovery(BuyV2RecoveryKind.networkInterruption);
      session.openRecovery(BuyV2RecoveryKind.paymentFailed);
      expect(session.recoveryReturnLabel, 'Return to Medicine');

      if (usePrimary) {
        session.retryRecovery();
      } else {
        session.goBack();
      }

      expect(session.destination, BuyV2Destination.medicine);
      expect(session.view, BuyV2View.catalogue);
      expect(session.query, 'paracetmol');
      expect(session.itemCount, itemCount);
      expect(session.cartTotal, cartTotal);
      expect(session.notice, isNull);
      expect(
        session.navigationMotionDirection,
        BuyV2NavigationMotionDirection.back,
      );
      session.dispose();
    }
  });

  test(
    'Cart and Checkout recover to their exact scopes without success copy',
    () {
      final cartSession = newSession();
      final shop = firstProduct(BuyV2Destination.shop);
      expect(cartSession.addProduct(shop.id), isTrue);
      cartSession.openCart(scope: BuyV2CartScope.shop);
      cartSession.openRecovery(BuyV2RecoveryKind.stockUnavailable);
      expect(cartSession.recoveryReturnLabel, 'Return to Cart');
      cartSession.retryRecovery();
      expect(cartSession.view, BuyV2View.cart);
      expect(cartSession.cartScope, BuyV2CartScope.shop);
      expect(cartSession.notice, isNull);

      final checkoutSession = newSession();
      expect(checkoutSession.addProduct(shop.id), isTrue);
      checkoutSession.openCart(scope: BuyV2CartScope.shop);
      expect(checkoutSession.openCheckout(), isTrue);
      final itemCount = checkoutSession.itemCount;
      final cartTotal = checkoutSession.cartTotal;
      final payment = checkoutSession.selectedPayment;
      checkoutSession.openRecovery(BuyV2RecoveryKind.paymentFailed);
      expect(checkoutSession.recoveryReturnLabel, 'Return to Checkout');
      checkoutSession.retryRecovery();
      expect(checkoutSession.view, BuyV2View.checkout);
      expect(checkoutSession.checkoutScope, BuyV2CartScope.shop);
      expect(checkoutSession.itemCount, itemCount);
      expect(checkoutSession.cartTotal, cartTotal);
      expect(checkoutSession.selectedPayment, payment);
      expect(checkoutSession.notice, isNull);
    },
  );

  test('stale Checkout address fails closed to the real Cart', () {
    final session = newSession();
    final shop = firstProduct(BuyV2Destination.shop);
    expect(session.addProduct(shop.id), isTrue);
    session.openCart(scope: BuyV2CartScope.shop);
    expect(session.openCheckout(), isTrue);
    session.openRecovery(BuyV2RecoveryKind.serviceAreaUnavailable);

    expect(session.restoreSelectedAddressId(null), isFalse);
    expect(session.view, BuyV2View.recovery);
    session.retryRecovery();

    expect(session.view, BuyV2View.cart);
    expect(session.cartScope, BuyV2CartScope.shop);
    expect(session.notice, 'Choose a delivery address to continue.');
    expect(session.itemCount, 1);
  });

  test('delivery Help belongs only to the exact Tracking or Items order', () {
    for (final origin in [BuyV2View.tracking, BuyV2View.orderItems]) {
      final session = newSession();
      final opened = origin == BuyV2View.tracking
          ? session.openTracking('PO-240783')
          : session.openOrderItems('PO-240783');
      expect(opened, isTrue);
      session.openRecovery(BuyV2RecoveryKind.deliveryDelay);

      expect(session.recoveryReturnLabel, 'Return to order');
      expect(session.canOpenRecoveryOrderHelp, isTrue);
      expect(session.openRecoveryOrderHelp(), isTrue);
      expect(session.view, origin);
      expect(session.selectedOrder.id, 'PO-240783');
      session.dispose();
    }

    final unowned = newSession();
    unowned.openRecovery(BuyV2RecoveryKind.deliveryDelay);
    expect(unowned.canOpenRecoveryOrderHelp, isFalse);
    expect(unowned.openRecoveryOrderHelp(), isFalse);
  });

  test('intentional destination replacement clears the retained origin', () {
    final session = newSession();
    session.openDestination(BuyV2Destination.medicine);
    session.updateQuery('paracetamol');
    session.openRecovery(BuyV2RecoveryKind.networkInterruption);

    session.openDestination(BuyV2Destination.wholesale);
    session.updateQuery('basmati');
    session.openRecovery(BuyV2RecoveryKind.priceUpdate);
    session.goBack();

    expect(session.destination, BuyV2Destination.wholesale);
    expect(session.view, BuyV2View.catalogue);
    expect(session.query, 'basmati');
  });

  testWidgets('all six recovery states use honest copy and origin semantics', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = newSession();
    addTearDown(session.dispose);
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    final expected = <BuyV2RecoveryKind, (String, String)>{
      BuyV2RecoveryKind.priceUpdate: (
        'Price needs review',
        'No order has been changed.',
      ),
      BuyV2RecoveryKind.stockUnavailable: (
        'Availability needs review',
        'No replacement has been selected.',
      ),
      BuyV2RecoveryKind.serviceAreaUnavailable: (
        'Delivery availability needs review',
        'No address or product has been changed.',
      ),
      BuyV2RecoveryKind.paymentFailed: (
        'Payment status needs review',
        'cannot confirm whether money was debited',
      ),
      BuyV2RecoveryKind.networkInterruption: (
        'Connection interrupted',
        'confirm the latest details',
      ),
      BuyV2RecoveryKind.deliveryDelay: (
        'Delivery update needs review',
        'No new delivery commitment is confirmed here.',
      ),
    };

    for (final kind in BuyV2RecoveryKind.values) {
      session.openRecovery(kind);
      await tester.pumpAndSettle();
      expect(find.text(expected[kind]!.$1), findsOneWidget);
      expect(find.textContaining(expected[kind]!.$2), findsOneWidget);
      final primary = find.byKey(const ValueKey('buy-recovery-primary'));
      expect(find.text('Return to Shop'), findsOneWidget);
      final semantics = tester.getSemantics(primary).getSemanticsData();
      expect(semantics.hasAction(SemanticsAction.tap), isTrue);
      expect(find.text('Get help'), findsNothing);
      expect(find.textContaining('No amount was charged'), findsNothing);
      expect(find.textContaining('Cart is safe'), findsNothing);
      expect(find.textContaining('shared a new delivery'), findsNothing);
      expect(find.textContaining('Updated. You can continue.'), findsNothing);
      await tester.tap(primary);
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.catalogue);
    }
  });

  testWidgets('320px 140% and Android/iOS sizes remain stable', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final viewport in const [
      (
        size: Size(320, 568),
        safe: EdgeInsets.symmetric(vertical: 24),
        scale: 1.4,
        reduced: true,
      ),
      (
        size: Size(360, 800),
        safe: EdgeInsets.symmetric(vertical: 24),
        scale: 1.0,
        reduced: false,
      ),
      (
        size: Size(390, 844),
        safe: EdgeInsets.only(top: 47, bottom: 34),
        scale: 1.0,
        reduced: false,
      ),
      (
        size: Size(430, 932),
        safe: EdgeInsets.only(top: 59, bottom: 34),
        scale: 1.0,
        reduced: false,
      ),
    ]) {
      tester.view.physicalSize = viewport.size;
      final session = newSession();
      session.openRecovery(BuyV2RecoveryKind.paymentFailed);
      await tester.pumpWidget(
        app(
          session,
          textScale: viewport.scale,
          reducedMotion: viewport.reduced,
          safeArea: viewport.safe,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Payment status needs review'), findsOneWidget);
      expect(find.text('Return to Shop'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byKey(const ValueKey('buy-v2-screen'))).width,
        lessThanOrEqualTo(viewport.size.width),
      );
      session.dispose();
    }
  });
}
