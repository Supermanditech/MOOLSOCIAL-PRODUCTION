import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';

bool _belongsToScope(
  BuyV2Product product,
  BuyV2CartScope scope,
) => switch (scope) {
  BuyV2CartScope.all => true,
  BuyV2CartScope.shop => product.destination == BuyV2Destination.shop,
  BuyV2CartScope.wholesale => product.destination == BuyV2Destination.wholesale,
  BuyV2CartScope.medicine => product.destination == BuyV2Destination.medicine,
};

void _expectExactState({
  required BuyV2Session session,
  required List<BuyV2Product> products,
  required int step,
}) {
  final active = <BuyV2Product, int>{
    for (final product in products)
      if (session.quantityFor(product.id) case final quantity when quantity > 0)
        product: quantity,
  };
  final expectedItemCount = active.values.fold<int>(
    0,
    (total, quantity) => total + quantity,
  );
  final expectedTotal = active.entries.fold<int>(
    0,
    (total, entry) => total + entry.key.price * entry.value,
  );
  final expectedDestinations = active.keys
      .map((product) => product.destination)
      .toSet();

  expect(session.itemCount, expectedItemCount, reason: 'step $step');
  expect(session.cartTotal, expectedTotal, reason: 'step $step');
  expect(session.cartDestinations, expectedDestinations, reason: 'step $step');
  for (final entry in active.entries) {
    expect(
      entry.value,
      greaterThanOrEqualTo(entry.key.minimumOrder),
      reason: 'step $step ${entry.key.id}',
    );
  }

  final expectedCart = <String, int>{
    for (final entry in active.entries)
      if (_belongsToScope(entry.key, session.cartScope))
        entry.key.id: entry.value,
  };
  final actualCart = <String, int>{
    for (final line in session.cartLines) line.product.id: line.quantity,
  };
  final expectedScopedTotal = active.entries
      .where((entry) => _belongsToScope(entry.key, session.cartScope))
      .fold<int>(0, (total, entry) => total + entry.key.price * entry.value);

  expect(actualCart, expectedCart, reason: 'step $step cart');
  expect(
    session.scopedItemCount,
    expectedCart.values.fold<int>(0, (total, quantity) => total + quantity),
    reason: 'step $step cart count',
  );
  expect(
    session.scopedCartTotal,
    expectedScopedTotal,
    reason: 'step $step cart total',
  );

  final expectedCheckout = <String, int>{
    for (final entry in active.entries)
      if (_belongsToScope(entry.key, session.checkoutScope))
        entry.key.id: entry.value,
  };
  final actualCheckout = <String, int>{
    for (final line in session.checkoutLines) line.product.id: line.quantity,
  };
  final expectedCheckoutTotal = active.entries
      .where((entry) => _belongsToScope(entry.key, session.checkoutScope))
      .fold<int>(0, (total, entry) => total + entry.key.price * entry.value);
  final expectedCheckoutDestinations = active.keys
      .where((product) => _belongsToScope(product, session.checkoutScope))
      .map((product) => product.destination)
      .toSet();

  expect(actualCheckout, expectedCheckout, reason: 'step $step checkout');
  expect(
    session.checkoutItemCount,
    expectedCheckout.values.fold<int>(0, (total, quantity) => total + quantity),
    reason: 'step $step checkout count',
  );
  expect(
    session.checkoutTotal,
    expectedCheckoutTotal,
    reason: 'step $step checkout total',
  );
  expect(
    session.checkoutDestinations,
    expectedCheckoutDestinations,
    reason: 'step $step checkout destinations',
  );

  final groups = session.checkoutFulfilmentGroups;
  expect(
    groups.fold<int>(0, (total, group) => total + group.itemCount),
    session.checkoutItemCount,
    reason: 'step $step group count',
  );
  expect(
    groups.fold<int>(0, (total, group) => total + group.total),
    session.checkoutTotal,
    reason: 'step $step group total',
  );
  expect(
    groups.expand((group) => group.productIds).toSet(),
    expectedCheckout.keys.toSet(),
    reason: 'step $step group products',
  );
  for (final group in groups) {
    expect(
      group.lines.every(
        (line) =>
            line.product.destination == group.destination &&
            line.product.seller == group.partner,
      ),
      isTrue,
      reason: 'step $step ${group.partner}',
    );
  }
}

void main() {
  test('mixed Buy actions preserve exact commerce state after every step', () {
    final session = BuyV2Session(core: BuySession());
    final products = BuyV2Catalogue.products
        .where((product) => !product.requiresPrescription)
        .toList(growable: false);
    const destinations = [
      BuyV2Destination.shop,
      BuyV2Destination.wholesale,
      BuyV2Destination.medicine,
    ];
    const scopes = BuyV2CartScope.values;
    const recoveryKinds = BuyV2RecoveryKind.values;
    var generatorState = 0x5eed113;
    var confirmations = 0;
    var clears = 0;
    final exercisedActions = <int>{};
    final exercisedDestinations = <BuyV2Destination>{};
    final exercisedScopes = <BuyV2CartScope>{};

    int next(int upperBound) {
      generatorState = (1664525 * generatorState + 1013904223) & 0x7fffffff;
      return generatorState % upperBound;
    }

    for (var step = 0; step < 2400; step += 1) {
      final product = products[next(products.length)];
      final destination = destinations[next(destinations.length)];
      final scope = scopes[next(scopes.length)];
      final action = step % 12;
      exercisedActions.add(action);
      exercisedDestinations.add(destination);
      exercisedScopes.add(scope);

      switch (action) {
        case 0:
          expect(session.addProduct(product.id), isTrue);
        case 1:
          session.increase(product.id);
        case 2:
          session.decrease(product.id);
        case 3:
          session.remove(product.id);
        case 4:
          session.openDestination(destination);
        case 5:
          session.chooseCartScope(scope);
        case 6:
          session.openCart(scope: scope);
        case 7:
          session.returnToCatalogue();
        case 8:
          session.updateQuery(product.title);
        case 9:
          session.chooseCartScope(scope);
          session.openCheckout();
          if (session.checkoutLines.isNotEmpty && step % 36 == 9) {
            final confirmedIds = session.checkoutLines
                .map((line) => line.product.id)
                .toSet();
            final confirmedItemCount = session.checkoutItemCount;
            final confirmedTotal = session.checkoutTotal;
            final confirmedDestinations = session.checkoutDestinations;
            final itemCountBefore = session.itemCount;

            expect(
              session.confirmOrder(),
              isTrue,
              reason:
                  'step $step confirmation must complete: ${session.notice}',
            );

            confirmations += 1;
            expect(
              session.confirmedOrders
                  .expand((order) => order.productIds)
                  .toSet(),
              confirmedIds,
              reason: 'step $step confirmed products',
            );
            expect(
              session.confirmedItemCount,
              confirmedItemCount,
              reason: 'step $step confirmed count',
            );
            expect(
              session.confirmedTotal,
              confirmedTotal,
              reason: 'step $step confirmed total',
            );
            expect(
              session.confirmedDestinations,
              confirmedDestinations,
              reason: 'step $step confirmed destinations',
            );
            expect(
              session.itemCount,
              itemCountBefore - confirmedItemCount,
              reason: 'step $step remaining count',
            );
            for (final id in confirmedIds) {
              expect(
                session.quantityFor(id),
                0,
                reason: 'step $step removed $id',
              );
            }
          }
        case 10:
          session.openAccount();
          expect(session.view, BuyV2View.account);
          session.goBack();
        case 11:
          if (step % 48 == 11) {
            session.clearCart();
            clears += 1;
          } else {
            session.openRecovery(recoveryKinds[next(recoveryKinds.length)]);
            session.goBack();
          }
      }

      _expectExactState(session: session, products: products, step: step);
    }

    expect(exercisedActions, hasLength(12));
    expect(exercisedDestinations, destinations.toSet());
    expect(exercisedScopes, scopes.toSet());
    expect(confirmations, greaterThan(0));
    expect(clears, greaterThan(0));
  });
}
