import '../../features/buy/buy_v2_models.dart';

/// Buy contributes only commerce context and exact return wiring to the
/// authoritative shared Chat module.
class BuyV2ChatRouteAdapter {
  const BuyV2ChatRouteAdapter();

  String locationFor({
    required BuyV2Destination destination,
    required BuyV2View view,
    required bool offersActive,
    BuyV2CartScope cartScope = BuyV2CartScope.all,
    BuyV2CartScope checkoutScope = BuyV2CartScope.all,
    String? productId,
    String? orderId,
    BuyV2RecoveryKind? recoveryKind,
  }) {
    final returnRoute = _returnRouteFor(
      destination: destination,
      view: view,
      offersActive: offersActive,
      cartScope: cartScope,
      checkoutScope: checkoutScope,
      productId: productId,
      orderId: orderId,
      recoveryKind: recoveryKind,
    );
    final type = offersActive
        ? 'support'
        : switch (destination) {
            BuyV2Destination.orders => 'order',
            BuyV2Destination.wholesale => 'business',
            BuyV2Destination.medicine => 'business',
            BuyV2Destination.shop => null,
          };
    return Uri(
      path: '/app/chat/inbox',
      queryParameters: {'return': returnRoute, 'type': ?type},
    ).toString();
  }

  String orderHelpLocationFor({required String orderId}) {
    final normalizedOrderId = orderId.trim();
    return Uri(
      path: '/app/chat/thread/shop-assist',
      queryParameters: {
        'draft': 'Help with order $normalizedOrderId',
        'return': Uri(
          path: '/app/buy',
          queryParameters: {
            'sub': 'orders',
            'view': 'tracking',
            'order': normalizedOrderId,
          },
        ).toString(),
        'directReturn': 'true',
      },
    ).toString();
  }

  String _returnRouteFor({
    required BuyV2Destination destination,
    required BuyV2View view,
    required bool offersActive,
    required BuyV2CartScope cartScope,
    required BuyV2CartScope checkoutScope,
    required String? productId,
    required String? orderId,
    required BuyV2RecoveryKind? recoveryKind,
  }) {
    final query = <String, String>{
      'sub': offersActive ? 'offers' : destination.name,
    };
    switch (view) {
      case BuyV2View.catalogue:
        break;
      case BuyV2View.product:
        if (productId case final value? when value.trim().isNotEmpty) {
          query
            ..['view'] = 'product'
            ..['product'] = value.trim();
        }
        break;
      case BuyV2View.cart:
        query
          ..['view'] = 'cart'
          ..['scope'] = cartScope.name;
        break;
      case BuyV2View.checkout:
        query
          ..['view'] = 'checkout'
          ..['scope'] = checkoutScope.name;
        break;
      case BuyV2View.confirmation:
        query
          ..['view'] = 'confirmation'
          ..['scope'] = checkoutScope.name;
        break;
      case BuyV2View.tracking:
        if (orderId case final value? when value.trim().isNotEmpty) {
          query
            ..['sub'] = BuyV2Destination.orders.name
            ..['view'] = 'tracking'
            ..['order'] = value.trim();
        }
        break;
      case BuyV2View.orderItems:
        if (orderId case final value? when value.trim().isNotEmpty) {
          query
            ..['sub'] = BuyV2Destination.orders.name
            ..['view'] = 'items'
            ..['order'] = value.trim();
        }
        break;
      case BuyV2View.assist:
        if (orderId case final value? when value.trim().isNotEmpty) {
          query
            ..['sub'] = BuyV2Destination.orders.name
            ..['view'] = 'tracking'
            ..['order'] = value.trim();
        }
        break;
      case BuyV2View.account:
        break;
      case BuyV2View.recovery:
        if (recoveryKind case final value?) {
          query
            ..['view'] = 'recovery'
            ..['recovery'] = _recoveryRouteValue(value);
        }
        break;
    }
    return Uri(path: '/app/buy', queryParameters: query).toString();
  }

  String _recoveryRouteValue(BuyV2RecoveryKind kind) => switch (kind) {
    BuyV2RecoveryKind.priceUpdate => 'price-update',
    BuyV2RecoveryKind.stockUnavailable => 'stock-unavailable',
    BuyV2RecoveryKind.serviceAreaUnavailable => 'service-area',
    BuyV2RecoveryKind.paymentFailed => 'payment-failed',
    BuyV2RecoveryKind.networkInterruption => 'offline',
    BuyV2RecoveryKind.deliveryDelay => 'delivery-delay',
  };
}
