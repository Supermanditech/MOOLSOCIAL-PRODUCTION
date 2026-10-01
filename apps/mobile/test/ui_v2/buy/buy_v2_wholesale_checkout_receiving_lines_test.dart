import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

// Rendering-only boundary data; never published to the review catalogue.
class _LargeCheckoutSession extends BuyV2Session {
  _LargeCheckoutSession() : super(core: BuySession());
  @override
  List<BuyV2CartLine> get checkoutLines => [
    for (final line in super.checkoutLines)
      BuyV2CartLine(
        quantity: line.quantity,
        product: line.product.copyWith(
          price: 10000000,
          title:
              'Long product name with provider supplied variant and pack information',
        ),
      ),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(
    BuyV2Session session, {
    Size size = const Size(390, 844),
    double textScale = 1,
    EdgeInsets safeArea = EdgeInsets.zero,
  }) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: MoolTheme.light(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        size: size,
        textScaler: TextScaler.linear(textScale),
        padding: safeArea,
        viewPadding: safeArea,
        disableAnimations: true,
      ),
      child: child!,
    ),
    home: BuyV2Screen(
      session: session,
      initialDestination: session.destination,
      initialView: session.view,
      initialCartScope: session.checkoutScope,
    ),
  );

  BuyV2Session checkout(List<String> ids, {BuyV2CartScope? scope}) {
    final session = BuyV2Session(core: BuySession());
    for (final id in ids) {
      expect(session.addProduct(id), isTrue, reason: id);
    }
    if (scope == null) {
      session.openCart();
    } else {
      session.openCart(scope: scope);
    }
    expect(session.openCheckout(), isTrue);
    expect(session.continueCheckoutFromAddress(), isTrue);
    expect(session.continueCheckoutFromPayment(), isTrue);
    return session;
  }

  testWidgets('one Wholesale receiving line retains every Cart decision fact', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final session = checkout(const ['w-onion']);
    addTearDown(session.dispose);
    final product = session.product('w-onion');

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    expect(
      buyV2WholesaleCheckoutReceivingLinesContractVersion,
      'buy-wholesale-checkout-receiving-lines-v1',
    );
    expect(find.text('Products and trade packs'), findsNothing);
    expect(find.text(product.title), findsOneWidget);
    expect(find.text('2 packs · ${product.pack}'), findsOneWidget);
    expect(
      find.text(
        'Minimum order ${product.minimumOrder} packs · '
        '${buyV2Money(product.price)} per pack · ${product.unitPrice}',
      ),
      findsOneWidget,
    );
    expect(find.text('Item total'), findsOneWidget);
    expect(find.text(buyV2Money(product.price * 2)), findsWidgets);
    final line = find.byKey(
      ValueKey('buy-wholesale-checkout-receiving-line-${product.id}'),
    );
    expect(line, findsOneWidget);
    expect(tester.getSemantics(line).label, contains('2 packs'));
    expect(tester.getSemantics(line).label, contains(product.unitPrice));
    expect(tester.takeException(), isNull);
  });

  testWidgets('multiple Wholesale products retain independent line subtotals', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final session = checkout(const ['w-onion', 'w-potato']);
    addTearDown(session.dispose);

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    for (final id in const ['w-onion', 'w-potato']) {
      final product = session.product(id);
      expect(
        find.byKey(
          ValueKey('buy-wholesale-checkout-receiving-line-${product.id}'),
        ),
        findsOneWidget,
      );
      expect(find.text(product.title), findsOneWidget);
      expect(find.text(buyV2Money(product.price * 2)), findsWidgets);
    }
    final groups = session.checkoutFulfilmentGroups;
    expect(groups, isNotEmpty);
    for (var index = 0; index < groups.length; index += 1) {
      final group = groups[index];
      final products =
          '${group.lines.length} '
          '${group.lines.length == 1 ? 'product' : 'products'}';
      final packs =
          '${group.itemCount} '
          '${group.itemCount == 1 ? 'pack' : 'packs'}';
      expect(
        find.descendant(
          of: find.byKey(
            ValueKey('buy-checkout-confirm-delivery-${group.key}'),
          ),
          matching: find.text('$products · $packs'),
        ),
        findsOneWidget,
      );
    }
    expect(groups.fold<int>(0, (total, group) => total + group.itemCount), 4);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Shop Checkout does not expose Wholesale receiving UI', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final session = checkout(const ['s-tomato'], scope: BuyV2CartScope.shop);
    addTearDown(session.dispose);

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    expect(find.text('Products and trade packs'), findsNothing);
    expect(
      find.byKey(
        const ValueKey('buy-wholesale-checkout-receiving-line-s-tomato'),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('receiving lines remain readable at compact large text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.reset);
    final session = checkout(const ['w-onion']);
    addTearDown(session.dispose);
    final product = session.product('w-onion');

    await tester.pumpWidget(
      app(
        session,
        size: const Size(320, 568),
        textScale: 1.4,
        safeArea: const EdgeInsets.symmetric(vertical: 24),
      ),
    );
    await tester.pumpAndSettle();

    final line = find.byKey(
      ValueKey('buy-wholesale-checkout-receiving-line-${product.id}'),
    );
    await tester.scrollUntilVisible(
      line,
      160,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('buy-checkout-unified')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(line, findsOneWidget);
    expect(find.text('2 packs · ${product.pack}'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('T02 review unresolved payment locks quantities at $scale', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      addTearDown(tester.view.reset);
      final session = checkout(const ['s-tomato', 'w-onion']);
      addTearDown(session.dispose);
      await tester.pumpWidget(
        app(session, size: const Size(320, 700), textScale: scale),
      );
      await tester.pumpAndSettle();
      for (final state in [
        BuyV2CheckoutSubmissionState.submitting,
        BuyV2CheckoutSubmissionState.paymentPending,
        BuyV2CheckoutSubmissionState.paymentUnknown,
      ]) {
        session.checkoutSubmissionState = state;
        await tester.pumpWidget(
          app(session, size: const Size(320, 700), textScale: scale),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(session.checkoutSubmissionState, state);
        final scroll = find
            .descendant(
              of: find.byKey(const PageStorageKey('buy-checkout-unified')),
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(
          find.byKey(
            const ValueKey('buy-wholesale-checkout-receiving-line-w-onion'),
          ),
          140,
          scrollable: scroll,
          maxScrolls: 40,
        );
        for (final id in ['s-tomato', 'w-onion']) {
          expect(
            find.byKey(ValueKey('buy-checkout-quantity-$id')),
            findsNothing,
          );
        }
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byKey(const ValueKey('buy-quantity-input')), findsNothing);
        expect(session.quantityFor('s-tomato'), 1);
        expect(session.quantityFor('w-onion'), 2);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('T02 review large amounts and full names fit at $scale', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      addTearDown(tester.view.reset);
      final session = _LargeCheckoutSession();
      addTearDown(session.dispose);
      expect(session.addProduct('s-tomato'), isTrue);
      expect(session.addProduct('w-onion'), isTrue);
      session.openCart();
      expect(session.openCheckout(), isTrue);
      await tester.pumpWidget(
        app(session, size: const Size(320, 700), textScale: scale),
      );
      await tester.pumpAndSettle();
      final scroll = find
          .descendant(
            of: find.byKey(const PageStorageKey('buy-checkout-unified')),
            matching: find.byType(Scrollable),
          )
          .first;
      for (final line in session.checkoutLines) {
        final details = find.textContaining(line.product.customerTitle).first;
        await tester.scrollUntilVisible(
          details,
          140,
          scrollable: scroll,
          maxScrolls: 40,
        );
        await tester.pumpAndSettle();
        expect(details, findsOneWidget);
        expect(
          find.byKey(ValueKey('buy-checkout-quantity-${line.product.id}')),
          findsNothing,
        );
        expect(find.text(buyV2Money(line.total)), findsWidgets);
        expect(tester.takeException(), isNull);
      }
      expect(session.checkoutTotal, 30000000);
      expect(session.view, BuyV2View.checkout);
    });

    testWidgets('T02 review inline quantities preserve Checkout at $scale', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      addTearDown(tester.view.reset);
      final session = checkout(const ['s-tomato', 'w-onion']);
      addTearDown(session.dispose);
      final payment = session.selectedPayment;
      final product = session.product('w-onion');
      final original = session.quantityFor(product.id);
      await tester.pumpWidget(
        app(session, size: const Size(320, 700), textScale: scale),
      );
      await tester.pumpAndSettle();
      final scroll = find
          .descendant(
            of: find.byKey(const PageStorageKey('buy-checkout-unified')),
            matching: find.byType(Scrollable),
          )
          .first;
      Future<void> tap(Finder target) async {
        if (target.evaluate().isEmpty) {
          await tester.scrollUntilVisible(
            target,
            140,
            scrollable: scroll,
            maxScrolls: 40,
          );
        }
        await Scrollable.ensureVisible(tester.element(target), alignment: .2);
        await tester.pumpAndSettle();
        expect(target.hitTestable(), findsOneWidget);
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      final group = session.checkoutFulfilmentGroups.firstWhere(
        (g) => g.lines.any((line) => line.product.id == product.id),
      );
      final disclosure = find.byKey(
        ValueKey('buy-checkout-items-toggle-${group.key}'),
      );
      final line = find.byKey(
        ValueKey('buy-wholesale-checkout-receiving-line-${product.id}'),
      );
      await tap(disclosure);
      expect(line, findsNothing);
      expect(session.view, BuyV2View.checkout);
      expect(session.checkoutLines.length, 2);
      await tap(disclosure);
      expect(line, findsOneWidget);
      await tap(line);
      expect(
        find.byKey(ValueKey('buy-checkout-quantity-${product.id}')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('buy-quantity-input')), findsNothing);
      expect(session.view, BuyV2View.checkout);
      expect(session.quantityFor(product.id), original);
      expect(session.quantityFor('s-tomato'), 1);
      expect(session.selectedPayment, payment);
      expect(
        session.checkoutTotal,
        session.checkoutLines.fold<int>(0, (n, line) => n + line.total),
      );
      expect(find.text('Review basket'), findsNothing);
      expect(find.textContaining('Shipment '), findsNothing);
      expect(find.text('Delivery'), findsNothing);
      expect(find.text('Delivery estimate'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }
}
