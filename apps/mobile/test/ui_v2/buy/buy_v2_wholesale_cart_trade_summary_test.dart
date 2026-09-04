import 'package:flutter/material.dart';
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
      initialDestination: BuyV2Destination.wholesale,
      initialView: BuyV2View.cart,
      initialCartScope: BuyV2CartScope.wholesale,
    ),
  );

  BuyV2Session wholesaleSession() {
    final session = BuyV2Session(core: BuySession());
    expect(session.addProduct('w-onion'), isTrue);
    session.openCart(scope: BuyV2CartScope.wholesale);
    return session;
  }

  testWidgets('Wholesale Cart distinguishes products, packs and landed total', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final session = wholesaleSession();
    addTearDown(session.dispose);
    final product = session.product('w-onion');
    final expectedTotal = product.price * product.minimumOrder;

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    expect(
      buyV2WholesaleCartTradeSummaryContractVersion,
      'buy-wholesale-cart-trade-summary-v1',
    );
    expect(
      find.text(
        '1 product · ${product.minimumOrder} packs · Wholesale · '
        '${buyV2Money(expectedTotal)}',
      ),
      findsOneWidget,
    );
    expect(find.text('${product.minimumOrder} products'), findsNothing);
    expect(
      find.text(
        'MOQ ${product.minimumOrder} packs · '
        '${buyV2Money(product.price)} per pack',
      ),
      findsOneWidget,
    );
    expect(
      find.text('${product.unitPrice} · Freight included'),
      findsOneWidget,
    );
    expect(find.text('Landed subtotal'), findsOneWidget);
    expect(find.text('Landed cart total'), findsOneWidget);
    expect(
      find.text('Freight included · GST invoice at checkout'),
      findsOneWidget,
    );
    expect(find.text('Review order'), findsOneWidget);

    final facts = find.byKey(
      ValueKey('buy-wholesale-cart-line-facts-${product.id}'),
    );
    expect(facts, findsOneWidget);
    expect(
      tester.getSemantics(facts).label,
      contains('Minimum order ${product.minimumOrder} packs'),
    );
    expect(
      tester.getSemantics(facts).label,
      contains('${buyV2Money(product.price)} per pack'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('scoped Wholesale header never leaks mixed-cart totals', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    expect(session.addProduct('s-tomato'), isTrue);
    expect(session.addProduct('w-onion'), isTrue);
    session.openCart(scope: BuyV2CartScope.wholesale);
    final wholesale = session.product('w-onion');
    final shop = session.product('s-tomato');
    final wholesaleTotal = wholesale.price * wholesale.minimumOrder;
    final globalTotal = wholesaleTotal + shop.price;

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    expect(
      find.text(
        '1 product · ${wholesale.minimumOrder} packs · Wholesale · '
        '${buyV2Money(wholesaleTotal)}',
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('buy-cart-header-value-motion')),
        matching: find.textContaining(buyV2Money(globalTotal)),
      ),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('buy-cart-line-s-tomato')), findsNothing);
    expect(find.byKey(const ValueKey('buy-cart-line-w-onion')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Wholesale quantity controls explain MOQ removal exactly', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final session = wholesaleSession();
    addTearDown(session.dispose);
    final product = session.product('w-onion');

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Add one trade pack'), findsOneWidget);
    expect(find.byTooltip('Remove ${product.title} from Cart'), findsOneWidget);
    await tester.tap(find.byTooltip('Add one trade pack'));
    await tester.pumpAndSettle();
    expect(session.quantityFor(product.id), product.minimumOrder + 1);
    expect(
      find.text('1 product · 3 packs · Wholesale · ₹2,325'),
      findsOneWidget,
    );
    expect(find.byTooltip('Remove one trade pack'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove one trade pack'));
    await tester.pumpAndSettle();
    expect(session.quantityFor(product.id), product.minimumOrder);
    expect(find.byTooltip('Remove ${product.title} from Cart'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove ${product.title} from Cart'));
    await tester.pumpAndSettle();
    expect(session.quantityFor(product.id), 0);
    expect(session.view, BuyV2View.catalogue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('product review and checkout return preserve Wholesale Cart', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final session = wholesaleSession();
    addTearDown(session.dispose);
    final product = session.product('w-onion');

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(ValueKey('buy-cart-product-details-${product.id}')),
    );
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.product);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.cart);
    expect(session.cartScope, BuyV2CartScope.wholesale);
    expect(session.quantityFor(product.id), product.minimumOrder);

    await tester.tap(find.text('Review order'));
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.checkout);
    expect(find.text('Receiving address'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('buy-scoped-purchase-owner')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('buy-local-destination-tabs')),
      findsOneWidget,
    );
    for (final key in const [
      'buy-local-tab-wholesale',
      'buy-local-tab-orders',
      'buy-local-tab-offers',
    ]) {
      expect(find.byKey(ValueKey(key)), findsOneWidget, reason: key);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact Android and iOS insets retain the Cart action', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final viewports = <({Size size, double scale, EdgeInsets safe})>[
      (
        size: const Size(320, 568),
        scale: 1.4,
        safe: const EdgeInsets.symmetric(vertical: 24),
      ),
      (
        size: const Size(430, 932),
        scale: 1.2,
        safe: const EdgeInsets.only(top: 59, bottom: 34),
      ),
    ];

    for (final viewport in viewports) {
      tester.view.physicalSize = viewport.size;
      final session = wholesaleSession();
      await tester.pumpWidget(
        app(
          session,
          size: viewport.size,
          textScale: viewport.scale,
          safeArea: viewport.safe,
        ),
      );
      await tester.pumpAndSettle();

      final actionBar = find.byKey(const ValueKey('buy-cart-action-bar'));
      expect(actionBar, findsOneWidget, reason: '${viewport.size} action');
      expect(find.text('Review order'), findsOneWidget);
      expect(
        tester.getBottomRight(actionBar).dy,
        lessThanOrEqualTo(viewport.size.height - viewport.safe.bottom),
        reason: '${viewport.size} bottom inset',
      );
      expect(tester.takeException(), isNull, reason: '${viewport.size}');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      session.dispose();
    }
  });
}
