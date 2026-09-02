import 'dart:convert';

import '../../features/buy/buy_v2_models.dart';
import 'buy_v2_design.dart';

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
            : _orderHelpDraft(order),
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
          'purchaseId': ?_clean(order.purchaseId),
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
          'paymentMethod': ?_clean(order.paymentMethod),
          'paymentTerms': ?_clean(order.paymentTermLabel),
          'adminVisible': 'true',
          'escalationReason': 'supplier-non-response',
          'callAuthority': 'moolsocial-admin-only',
        },
      },
    ).toString();
  }

  String storeQuestionLocationFor({required BuyV2Product anchor}) {
    final returnRoute = Uri(
      path: '/app/buy',
      queryParameters: {'sub': anchor.destination.name},
    ).toString();
    return Uri(
      path: _supplierThreadPathFor(
        destination: anchor.destination,
        supplier: anchor.seller,
      ),
      queryParameters: {
        'draft': 'I have a question for ${anchor.seller}.',
        'return': returnRoute,
        'directReturn': 'true',
        'context': 'supplier-store',
        'conversationKey': _supplierConversationKey(anchor),
        'supplier': anchor.seller,
        'supplierType': anchor.sellerType,
        'supplierRole': anchor.partnerRole,
        'storeAnchorSku': anchor.id,
        'origin': anchor.origin,
        'adminVisible': 'true',
        'escalationReason': 'supplier-non-response',
        'callAuthority': 'moolsocial-admin-only',
      },
    ).toString();
  }

  String productQuestionLocationFor({
    required BuyV2Product product,
    int quantity = 0,
  }) {
    final requestedQuantity = quantity > 0 ? quantity : product.minimumOrder;
    final protection = product.purchaseProtection;
    final remedies = _cleanValues(protection?.remedies ?? const []);
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
        'draft': _productQuestionDraft(product, requestedQuantity),
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
            ?(_clean(protection?.summary) ?? _clean(product.returnPolicy)),
        if (protection != null) ...{
          if (remedies.isNotEmpty) 'remedies': remedies.join(','),
          'policyWindow': ?_clean(protection.windowLabel),
          'policyConditions': ?_clean(protection.conditionsLabel),
          'policyVerification': ?_clean(protection.verificationLabel),
          'policyInitiation': ?_clean(protection.initiationLabel),
          'policyApproval': ?_clean(protection.approvalLabel),
          'policyPickup': ?_clean(protection.pickupLabel),
          'refundMethod': ?_clean(protection.refundMethodLabel),
          'refundTimeline': ?_clean(protection.refundTimelineLabel),
          'warranty': ?_clean(protection.warrantyLabel),
          'nonReturnableReason': ?_clean(protection.nonReturnableReason),
          'policyVersion': ?_clean(protection.policyVersion),
          'policyEffectiveFrom': ?_clean(protection.effectiveFromLabel),
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
    final compliance = product.compliance;
    final remedies = _cleanValues(protection?.remedies ?? const []);
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
      'returnPolicy': _clean(product.returnPolicy),
      'compliance': <String, Object?>{
        'genericName': _clean(compliance?.genericName),
        'netQuantity': _clean(compliance?.netQuantity),
        'manufacturer': _clean(compliance?.manufacturerName),
        'packer': _clean(compliance?.packerName),
        'importer': _clean(compliance?.importerName),
        'countryOfOrigin': _clean(compliance?.countryOfOrigin),
        'manufacturedOrPackedOn': _clean(
          compliance?.manufacturedOrPackedOnLabel,
        ),
        'bestBeforeOrUseBy': _clean(compliance?.bestBeforeOrUseByLabel),
        'fssaiLicenseNumber': _clean(compliance?.fssaiLicenseNumber),
        'consumerCare': _clean(compliance?.consumerCare),
      },
      if (protection != null)
        'purchaseProtection': <String, Object?>{
          'summary': _clean(protection.summary),
          'remedies': remedies,
          'window': _clean(protection.windowLabel),
          'conditions': _clean(protection.conditionsLabel),
          'verification': _clean(protection.verificationLabel),
          'initiation': _clean(protection.initiationLabel),
          'approval': _clean(protection.approvalLabel),
          'pickup': _clean(protection.pickupLabel),
          'refundMethod': _clean(protection.refundMethodLabel),
          'refundTimeline': _clean(protection.refundTimelineLabel),
          'warranty': _clean(protection.warrantyLabel),
          'nonReturnableReason': _clean(protection.nonReturnableReason),
          'policyVersion': _clean(protection.policyVersion),
          'effectiveFrom': _clean(protection.effectiveFromLabel),
        },
    };
  }

  String _productQuestionDraft(BuyV2Product product, int quantity) {
    final compliance = product.compliance;
    final protection = product.purchaseProtection;
    final remedies = _cleanValues(protection?.remedies ?? const []);
    return [
      'Hello ${product.seller},',
      'I have a question about ${product.title}.',
      'SKU: ${product.id}',
      'Brand: ${product.brand}',
      'Variant: ${product.variant}',
      'Pack: ${product.pack}',
      'Quantity: $quantity',
      'Price: ${buyV2Money(product.price)}',
      'Unit price: ${product.unitPrice}',
      if (product.mrp case final mrp?) 'MRP: ${buyV2Money(mrp)}',
      'Delivery: ${product.deliveryPromise}',
      if (_clean(compliance?.genericName) case final value?)
        'Generic name: $value',
      if (_clean(compliance?.netQuantity) case final value?)
        'Net quantity: $value',
      if (_clean(compliance?.manufacturerName) case final value?)
        'Manufacturer: $value',
      if (_clean(compliance?.countryOfOrigin) case final value?)
        'Country of origin: $value',
      if (_clean(compliance?.bestBeforeOrUseByLabel) case final value?)
        'Best before / use by: $value',
      if ((_clean(protection?.summary) ?? _clean(product.returnPolicy))
          case final value?)
        'After delivery: $value',
      if (remedies.isNotEmpty) 'Available options: ${remedies.join(', ')}',
      if (_clean(protection?.warrantyLabel) case final value?)
        'Warranty: $value',
    ].join('\n');
  }

  String _orderHelpDraft(BuyV2Order order) {
    return [
      'Hello ${order.partner},',
      'Help with order ${order.id}.',
      if (_clean(order.purchaseId) case final purchaseId?)
        'Purchase: $purchaseId',
      'Items: ${order.itemSummary}',
      for (final line in order.lines)
        '${line.product.title} · SKU ${line.product.id} · '
            'Quantity ${line.quantity} · '
            '${buyV2Money(line.product.price * line.quantity)}',
      if (order.lines.isEmpty && order.productIds.isNotEmpty)
        'Product references: ${order.productIds.join(', ')}',
      'Order total: ${buyV2Money(order.total)}',
      'Delivery: ${order.promise}',
      if (_clean(order.paymentMethod) case final paymentMethod?)
        'Payment: $paymentMethod',
      if (_clean(order.paymentTermLabel) case final paymentTerms?)
        'Payment terms: $paymentTerms',
    ].join('\n');
  }

  String? _clean(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  List<String> _cleanValues(Iterable<String> values) =>
      values.map(_clean).whereType<String>().toList(growable: false);

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
