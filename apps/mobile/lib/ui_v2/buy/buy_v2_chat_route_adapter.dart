import 'dart:convert';

import '../../features/buy/buy_v2_models.dart';

/// Buy contributes only commerce context and exact return wiring to the
/// authoritative shared Chat module.
class BuyV2ChatRouteAdapter {
  const BuyV2ChatRouteAdapter();

  // Buy never owns a second Chat shell. It contributes supplier, product,
  // purchased-line, policy and exact-return context to shared Chat. Shared
  // Chat/Admin remains responsible for durable conversations, Admin visibility
  // and any supplier non-response calling workflow.

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

  String orderHelpLocationFor({String? orderId, BuyV2Order? order}) {
    final normalizedOrderId = (order?.id ?? orderId ?? '').trim();
    if (normalizedOrderId.isEmpty) {
      throw ArgumentError.value(orderId, 'orderId', 'Order ID is required.');
    }
    return Uri(
      path: order == null
          ? '/app/chat/thread/shop-assist'
          : _supplierThreadPathFor(
              destination: order.destination,
              supplier: order.partner,
            ),
      queryParameters: {
        'draft': order == null
            ? 'Help with order $normalizedOrderId'
            : 'Help with order $normalizedOrderId from ${order.partner}',
        'return': Uri(
          path: '/app/buy',
          queryParameters: {
            'sub': order?.destination == BuyV2Destination.medicine
                ? 'medicine'
                : 'orders',
            'view': 'tracking',
            'order': normalizedOrderId,
          },
        ).toString(),
        'directReturn': 'true',
        if (order != null) ...{
          'context': order.destination == BuyV2Destination.medicine
              ? 'care-pharmacy-order'
              : 'supplier-order',
          'conversationKey': _supplierConversationKeyFor(
            destination: order.destination,
            supplier: order.partner,
          ),
          'supplier': order.partner,
          'supplierType': order.partnerType,
          'orderId': order.id,
          'purchaseId': ?order.purchaseId,
          'orderTotal': order.total.toString(),
          'productIds': order.productIds.join(','),
          'skuIds': order.lines.map((line) => line.product.id).join(','),
          'quantities': order.lines
              .map((line) => '${line.product.id}:${line.quantity}')
              .join(','),
          if (order.lines.isNotEmpty)
            'orderLines': jsonEncode(
              order.lines
                  .map(
                    (line) => {
                      ..._productSnapshot(line.product),
                      'quantity': line.quantity,
                      'lineTotal': line.product.price * line.quantity,
                    },
                  )
                  .toList(growable: false),
            ),
          'delivery': order.promise,
          'deliveryDestination': order.destinationLabel,
          'paymentMethod': ?order.paymentMethod,
          'paymentTerms': ?order.paymentTermLabel,
          'adminVisible': 'true',
          'escalationReason': 'supplier-non-response',
          'callAuthority': 'moolsocial-admin-only',
        },
      },
    ).toString();
  }

  String productQuestionLocationFor({
    required BuyV2Product product,
    int quantity = 0,
  }) {
    final requestedQuantity = quantity > 0 ? quantity : product.minimumOrder;
    final returnRoute = Uri(
      path: '/app/buy',
      queryParameters: {
        'sub': product.destination.name,
        'view': 'product',
        'product': product.id,
      },
    ).toString();
    return Uri(
      path: _supplierThreadPathFor(
        destination: product.destination,
        supplier: product.seller,
      ),
      queryParameters: {
        'draft':
            'Question for ${product.seller} about ${product.title} · '
            '${product.pack} · quantity $requestedQuantity',
        'return': returnRoute,
        'directReturn': 'true',
        'context': product.destination == BuyV2Destination.medicine
            ? 'care-pharmacy-product'
            : 'supplier-product',
        'conversationKey': _supplierConversationKey(product),
        'supplier': product.seller,
        'supplierType': product.sellerType,
        'supplierRole': product.partnerRole,
        'productId': product.canonicalId,
        'skuId': product.id,
        'productTitle': product.title,
        'brand': product.brand,
        'categoryId': product.categoryId,
        'variant': product.variant,
        'pack': product.pack,
        'price': product.price.toString(),
        'unitPrice': product.unitPrice,
        'mrp': ?product.mrp?.toString(),
        'quantity': requestedQuantity.toString(),
        'minimumOrder': product.minimumOrder.toString(),
        'delivery': product.deliveryPromise,
        'origin': product.origin,
        'productSnapshot': jsonEncode(_productSnapshot(product)),
        'policy':
            ?(product.purchaseProtection?.summary ?? product.returnPolicy),
        if (product.purchaseProtection case final protection?) ...{
          if (protection.remedies.isNotEmpty)
            'remedies': protection.remedies.join(','),
          'policyWindow': ?protection.windowLabel,
          'policyConditions': ?protection.conditionsLabel,
          'policyVerification': ?protection.verificationLabel,
          'policyInitiation': ?protection.initiationLabel,
          'policyApproval': ?protection.approvalLabel,
          'policyPickup': ?protection.pickupLabel,
          'refundMethod': ?protection.refundMethodLabel,
          'refundTimeline': ?protection.refundTimelineLabel,
          'warranty': ?protection.warrantyLabel,
          'nonReturnableReason': ?protection.nonReturnableReason,
          'policyVersion': ?protection.policyVersion,
          'policyEffectiveFrom': ?protection.effectiveFromLabel,
        },
        'adminVisible': 'true',
        'escalationReason': 'supplier-non-response',
        'callAuthority': 'moolsocial-admin-only',
      },
    ).toString();
  }

  String _supplierConversationKey(BuyV2Product product) {
    return _supplierConversationKeyFor(
      destination: product.destination,
      supplier: product.seller,
    );
  }

  Map<String, Object?> _productSnapshot(BuyV2Product product) {
    final protection = product.purchaseProtection;
    return <String, Object?>{
      'productId': product.canonicalId,
      'skuId': product.id,
      'title': product.title,
      'brand': product.brand,
      'categoryId': product.categoryId,
      'variant': product.variant,
      'pack': product.pack,
      'price': product.price,
      'unitPrice': product.unitPrice,
      'mrp': product.mrp,
      'supplier': product.seller,
      'supplierType': product.sellerType,
      'supplierRole': product.partnerRole,
      'delivery': product.deliveryPromise,
      'origin': product.origin,
      'minimumOrder': product.minimumOrder,
      'returnPolicy': product.returnPolicy,
      if (protection != null)
        'purchaseProtection': <String, Object?>{
          'summary': protection.summary,
          'remedies': protection.remedies,
          'window': protection.windowLabel,
          'conditions': protection.conditionsLabel,
          'verification': protection.verificationLabel,
          'initiation': protection.initiationLabel,
          'approval': protection.approvalLabel,
          'pickup': protection.pickupLabel,
          'refundMethod': protection.refundMethodLabel,
          'refundTimeline': protection.refundTimelineLabel,
          'warranty': protection.warrantyLabel,
          'nonReturnableReason': protection.nonReturnableReason,
          'policyVersion': protection.policyVersion,
          'effectiveFrom': protection.effectiveFromLabel,
        },
    };
  }

  String _supplierConversationKeyFor({
    required BuyV2Destination destination,
    required String supplier,
  }) {
    return '${destination.name}:${_supplierSlug(supplier)}';
  }

  String _supplierThreadPathFor({
    required BuyV2Destination destination,
    required String supplier,
  }) {
    final slug = _supplierSlug(supplier);
    return switch (destination) {
      BuyV2Destination.medicine => '/app/chat/thread/care-pharmacy-$slug',
      BuyV2Destination.shop ||
      BuyV2Destination.wholesale ||
      BuyV2Destination.orders =>
        '/app/chat/thread/shop-partner-${destination.name}-$slug',
    };
  }

  String _supplierSlug(String supplier) {
    final normalizedSupplier = supplier.trim();
    if (normalizedSupplier.isEmpty) {
      throw ArgumentError.value(
        supplier,
        'supplier',
        'Supplier identity is required.',
      );
    }
    final slug = normalizedSupplier
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    if (slug.isNotEmpty) return slug;
    return base64Url
        .encode(utf8.encode(normalizedSupplier))
        .replaceAll('=', '');
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
            ..['sub'] = destination == BuyV2Destination.medicine
                ? BuyV2Destination.medicine.name
                : BuyV2Destination.orders.name
            ..['view'] = 'tracking'
            ..['order'] = value.trim();
        }
        break;
      case BuyV2View.orderItems:
        if (orderId case final value? when value.trim().isNotEmpty) {
          query
            ..['sub'] = destination == BuyV2Destination.medicine
                ? BuyV2Destination.medicine.name
                : BuyV2Destination.orders.name
            ..['view'] = 'items'
            ..['order'] = value.trim();
        }
        break;
      case BuyV2View.assist:
        if (orderId case final value? when value.trim().isNotEmpty) {
          query
            ..['sub'] = destination == BuyV2Destination.medicine
                ? BuyV2Destination.medicine.name
                : BuyV2Destination.orders.name
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
