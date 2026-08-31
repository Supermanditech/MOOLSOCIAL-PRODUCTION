import 'package:flutter/foundation.dart';

import 'buy_v2_models.dart';

enum BuyV2ShoppingAlertKind {
  order,
  payment,
  delivery,
  offer,
  priceDrop,
  restock,
  cancellation,
  returnUpdate,
  refund,
}

enum BuyV2ShoppingAlertsState { loading, ready, offline, unavailable }

@immutable
class BuyV2ShoppingAlert {
  const BuyV2ShoppingAlert({
    required this.id,
    required this.kind,
    required this.title,
    required this.detail,
    required this.updatedLabel,
    required this.destination,
    this.orderId,
    this.productId,
  });

  final String id;
  final BuyV2ShoppingAlertKind kind;
  final String title;
  final String detail;
  final String updatedLabel;
  final BuyV2Destination destination;
  final String? orderId;
  final String? productId;
}

@immutable
class BuyV2ShoppingAlertsRequest {
  const BuyV2ShoppingAlertsRequest({
    required this.orders,
    required this.products,
  });

  final List<BuyV2Order> orders;
  final List<BuyV2Product> products;
}

@immutable
class BuyV2ShoppingAlertsSnapshot {
  const BuyV2ShoppingAlertsSnapshot({
    required this.state,
    required this.sourceId,
    this.alerts = const [],
    this.customerMessage,
  });

  final BuyV2ShoppingAlertsState state;
  final String sourceId;
  final List<BuyV2ShoppingAlert> alerts;
  final String? customerMessage;
}

abstract interface class BuyV2ShoppingAlertsAdapter {
  const BuyV2ShoppingAlertsAdapter();

  Future<BuyV2ShoppingAlertsSnapshot> load(BuyV2ShoppingAlertsRequest request);
}

final class BuyV2UnavailableShoppingAlertsAdapter
    implements BuyV2ShoppingAlertsAdapter {
  const BuyV2UnavailableShoppingAlertsAdapter();

  @override
  Future<BuyV2ShoppingAlertsSnapshot> load(
    BuyV2ShoppingAlertsRequest request,
  ) async => const BuyV2ShoppingAlertsSnapshot(
    state: BuyV2ShoppingAlertsState.unavailable,
    sourceId: 'shopping-alerts-unavailable',
    customerMessage:
        'Shopping alerts are unavailable right now. Your orders are unchanged.',
  );
}

/// Deterministic previews for the non-promotable UI-review package.
final class BuyV2UiReviewShoppingAlertsAdapter
    implements BuyV2ShoppingAlertsAdapter {
  const BuyV2UiReviewShoppingAlertsAdapter();

  @override
  Future<BuyV2ShoppingAlertsSnapshot> load(
    BuyV2ShoppingAlertsRequest request,
  ) async {
    final activeOrder = request.orders
        .where((order) => order.status != BuyV2OrderStatus.delivered)
        .firstOrNull;
    final deliveredOrder = request.orders
        .where((order) => order.status == BuyV2OrderStatus.delivered)
        .firstOrNull;
    final shopProduct = request.products
        .where(
          (product) =>
              product.destination == BuyV2Destination.shop &&
              product.catalogueListing,
        )
        .firstOrNull;
    return BuyV2ShoppingAlertsSnapshot(
      state: BuyV2ShoppingAlertsState.ready,
      sourceId: 'ui-review-shopping-alerts',
      alerts: [
        if (activeOrder != null)
          BuyV2ShoppingAlert(
            id: 'order-${activeOrder.id}',
            kind: BuyV2ShoppingAlertKind.delivery,
            title: 'Delivery update',
            detail: '${activeOrder.title} · ${activeOrder.promise}',
            updatedLabel: 'Updated recently',
            destination: BuyV2Destination.orders,
            orderId: activeOrder.id,
          ),
        if (deliveredOrder != null)
          BuyV2ShoppingAlert(
            id: 'return-${deliveredOrder.id}',
            kind: BuyV2ShoppingAlertKind.returnUpdate,
            title: 'Need help after delivery?',
            detail: 'Review return, replacement and refund options.',
            updatedLabel: 'Available now',
            destination: BuyV2Destination.orders,
            orderId: deliveredOrder.id,
          ),
        if (shopProduct != null)
          BuyV2ShoppingAlert(
            id: 'price-${shopProduct.id}',
            kind: BuyV2ShoppingAlertKind.priceDrop,
            title: 'Price update',
            detail: '${shopProduct.title} · ${shopProduct.pack}',
            updatedLabel: 'Updated today',
            destination: BuyV2Destination.shop,
            productId: shopProduct.id,
          ),
        const BuyV2ShoppingAlert(
          id: 'offers-shop',
          kind: BuyV2ShoppingAlertKind.offer,
          title: 'New Shop offers',
          detail: 'Review current eligible product and payment offers.',
          updatedLabel: 'Available now',
          destination: BuyV2Destination.shop,
        ),
      ],
    );
  }
}

String buyV2ShoppingAlertLocation(BuyV2ShoppingAlert alert) {
  final orderId = alert.orderId?.trim();
  if (orderId != null && orderId.isNotEmpty) {
    return Uri(
      path: '/app/buy',
      queryParameters: {'sub': 'orders', 'view': 'tracking', 'order': orderId},
    ).toString();
  }
  final productId = alert.productId?.trim();
  if (productId != null && productId.isNotEmpty) {
    return Uri(
      path: '/app/buy',
      queryParameters: {
        'sub': alert.destination.name,
        'view': 'product',
        'product': productId,
      },
    ).toString();
  }
  if (alert.kind == BuyV2ShoppingAlertKind.offer) {
    return Uri(path: '/app/buy', queryParameters: {'sub': 'offers'}).toString();
  }
  return Uri(
    path: '/app/buy',
    queryParameters: {'sub': alert.destination.name},
  ).toString();
}
