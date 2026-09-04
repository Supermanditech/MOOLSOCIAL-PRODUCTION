import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Checkout and Order items retain the published product policy', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    final product = BuyV2Catalogue.products.firstWhere(
      (candidate) =>
          candidate.destination == BuyV2Destination.shop &&
          candidate.returnPolicy != null,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: BuyV2Screen(session: session),
      ),
    );
    await tester.pumpAndSettle();
    expect(session.addProduct(product.id), isTrue);
    session.openCart(scope: BuyV2CartScope.shop);
    expect(session.openCheckout(), isTrue);
    await tester.pumpAndSettle();

    expect(
      find.textContaining(
        'After delivery · ${product.title}: ${product.returnPolicy}',
      ),
      findsOneWidget,
    );

    expect(session.confirmOrder(), isTrue);
    final order = session.confirmedOrders.single;
    expect(session.openOrderItems(order.id), isTrue);
    await tester.pumpAndSettle();
    expect(
      find.text('After delivery · ${product.returnPolicy}'),
      findsOneWidget,
    );
    final policy = find.byKey(ValueKey('buy-order-item-policy-${product.id}'));
    expect(policy, findsOneWidget);
    expect(tester.widget<Text>(policy).maxLines, isNull);
    expect(tester.takeException(), isNull);
  });
}
