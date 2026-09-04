import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_cart_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(BuyV2Session session) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: MoolTheme.light(),
    home: BuyV2Screen(
      session: session,
      initialDestination: session.destination,
      initialView: session.view,
      productId: session.selectedProductId,
    ),
  );

  testWidgets(
    'product offers show live eligibility without applying a saving',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      final evaluatedAt = DateTime.utc(2026, 8, 31, 12);
      final adapter = _ProductBenefitsAdapter(
        BuyV2CartBenefitsSnapshot(
          state: BuyV2CartBenefitsLoadState.ready,
          evaluatedAt: evaluatedAt,
          benefits: [
            BuyV2CartBenefit(
              id: 'fresh-price-drop',
              kind: BuyV2CartBenefitKind.coupon,
              destination: BuyV2Destination.shop,
              title: 'Fresh price drop',
              detail: 'Available on this pack today.',
              sourceId: 'family-dairy-sale',
              strategy: BuyV2CartBenefitStrategy.timedSale,
              sponsor: BuyV2CartBenefitSponsor.retailer,
              sponsorName: 'Family Dairy & Bake',
              savingAmount: 20,
              validUntil: evaluatedAt.add(const Duration(days: 1)),
            ),
            const BuyV2CartBenefit(
              id: 'upi-bank-offer',
              kind: BuyV2CartBenefitKind.paymentOffer,
              destination: BuyV2Destination.shop,
              title: 'UPI bank offer',
              detail: 'Pay with an eligible UPI account.',
              sourceId: 'bank-upi-campaign',
              strategy: BuyV2CartBenefitStrategy.financialProduct,
              sponsor: BuyV2CartBenefitSponsor.bank,
              sponsorName: 'HDFC Bank',
              eligiblePaymentMethods: {'UPI'},
            ),
          ],
        ),
      );
      final core = BuySession();
      final session = BuyV2Session(core: core, cartBenefitsAdapter: adapter);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      expect(session.openProduct('s-milk'), isTrue);

      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();
      final panel = find.byKey(
        const ValueKey('buy-product-benefits-ready-s-milk'),
      );
      await tester.scrollUntilVisible(
        panel,
        240,
        scrollable: find
            .descendant(
              of: find.byKey(const PageStorageKey('buy-product-s-milk')),
              matching: find.byType(Scrollable),
            )
            .first,
      );

      expect(find.text('Offers for this product'), findsOneWidget);
      expect(
        find.text('Eligibility is checked again at Checkout.'),
        findsOneWidget,
      );
      expect(find.text('Save ₹20'), findsOneWidget);
      expect(find.textContaining('Family Dairy & Bake'), findsWidgets);
      expect(find.textContaining('HDFC Bank'), findsOneWidget);
      expect(find.textContaining('With UPI'), findsOneWidget);
      expect(find.textContaining('Until'), findsOneWidget);
      expect(session.cartLines, isEmpty);
      expect(session.selectedCartBenefitsFor({BuyV2Destination.shop}), isEmpty);

      expect(session.addProduct('s-milk'), isTrue);
      await tester.pumpAndSettle();
      expect(adapter.requests.length, greaterThanOrEqualTo(2));
      expect(adapter.requests.first.lines.single.quantity, 1);
      expect(adapter.requests.last.lines.single.product.id, 's-milk');
      expect(session.scopedCouponSaving, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('product offer recovery stays on the selected product', (
    tester,
  ) async {
    final evaluatedAt = DateTime.utc(2026, 8, 31, 12);
    final adapter = _ProductBenefitsAdapter(
      BuyV2CartBenefitsSnapshot(
        state: BuyV2CartBenefitsLoadState.offline,
        evaluatedAt: evaluatedAt,
        customerMessage: 'Reconnect to check current offers.',
      ),
    );
    final core = BuySession();
    final session = BuyV2Session(core: core, cartBenefitsAdapter: adapter);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    expect(session.openProduct('s-milk'), isTrue);

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    final retry = find.byKey(
      const ValueKey('buy-product-benefits-retry-s-milk'),
    );
    final productScroll = find
        .descendant(
          of: find.byKey(const PageStorageKey('buy-product-s-milk')),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(retry, 240, scrollable: productScroll);
    expect(find.text('Product offers unavailable'), findsOneWidget);
    expect(find.text('Reconnect to check current offers.'), findsOneWidget);

    adapter.snapshot = BuyV2CartBenefitsSnapshot(
      state: BuyV2CartBenefitsLoadState.ready,
      evaluatedAt: evaluatedAt,
      benefits: const [
        BuyV2CartBenefit(
          id: 'free-local-delivery',
          kind: BuyV2CartBenefitKind.coupon,
          destination: BuyV2Destination.shop,
          title: 'Free local delivery',
          detail: 'Delivery is free for this order.',
          sourceId: 'local-delivery-campaign',
          strategy: BuyV2CartBenefitStrategy.freeDelivery,
          sponsor: BuyV2CartBenefitSponsor.moolSocial,
          sponsorName: 'MoolSocial',
          freeDelivery: true,
        ),
      ],
    );
    expect(await session.refreshProductBenefits('s-milk'), isTrue);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('buy-product-benefits-ready-s-milk')),
      findsOneWidget,
    );
    expect(find.text('Free local delivery'), findsOneWidget);
    expect(session.selectedProductId, 's-milk');
    expect(session.cartLines, isEmpty);
    expect(tester.takeException(), isNull);
  });
}

final class _ProductBenefitsAdapter implements BuyV2LiveCartBenefitsAdapter {
  _ProductBenefitsAdapter(this.snapshot);

  BuyV2CartBenefitsSnapshot snapshot;
  final List<BuyV2CartBenefitsRequest> requests = [];

  @override
  List<BuyV2CartBenefit> benefitsFor({
    required BuyV2CartBenefitKind kind,
    required Set<BuyV2Destination> destinations,
    required int itemTotal,
  }) => const [];

  @override
  Future<BuyV2CartBenefitsSnapshot> loadEligibility(
    BuyV2CartBenefitsRequest request,
  ) async {
    requests.add(request);
    return snapshot;
  }
}
