import 'dart:convert';
import 'dart:math';

import '../shared/social_content_gateway.dart';
import 'retailer_models.dart';
import 'retailer_pos_models.dart';

const moolSocialRetailerUrl = String.fromEnvironment(
  'MOOLSOCIAL_WORKSPACE_URL',
);

class RetailerGatewayException implements Exception {
  const RetailerGatewayException(this.message, {this.retryable = false});
  final String message;
  final bool retryable;
  @override
  String toString() => message;
}

class RetailerStoreSnapshot {
  const RetailerStoreSnapshot({
    required this.workspaceId,
    required this.name,
    required this.area,
    required this.ordersEnabled,
    required this.products,
  });
  final String workspaceId;
  final String name;
  final String area;
  final bool ordersEnabled;
  final List<RetailerPosProduct> products;
}

abstract interface class RetailerGateway {
  Future<RetailerStoreSnapshot> loadStore();
  Future<RetailerStoreSnapshot> setAvailability(bool enabled);
  Future<RetailerStoreSnapshot> saveProduct({
    required String productId,
    required int stock,
    required int buyPrice,
    required int sellPrice,
  });
  Future<List<RetailerOrder>> refreshOrders();
  Future<void> acceptOrder(String orderId);
  Future<void> savePackedOrder(String orderId);
  Future<String> requestDelivery(String orderId);
  Future<String> confirmHandover(String orderId);
  Future<void> refreshTracking(String orderId);
  Future<String> createIssue(String orderId, String reason);
  Future<void> cannotFulfil(String orderId, String reason);
}

RetailerGateway buildRetailerGateway() {
  final endpoint = Uri.tryParse(moolSocialRetailerUrl.trim());
  if (endpoint == null ||
      endpoint.scheme != 'https' ||
      endpoint.host != 'asia-south1-moolsocial-dev-503018.cloudfunctions.net' ||
      endpoint.path != '/moolSocialWorkspace' ||
      endpoint.hasQuery ||
      endpoint.hasFragment) {
    return const UnavailableRetailerGateway();
  }
  return AuthenticatedRetailerGateway(
    endpoint: endpoint,
    credentials: FirebaseSocialContentCredentials(),
    transport: IoSocialContentTransport(),
  );
}

class UnavailableRetailerGateway implements RetailerGateway {
  const UnavailableRetailerGateway();
  RetailerGatewayException get _error => const RetailerGatewayException(
    'Shop operations are unavailable right now. Existing customer promises remain unchanged.',
    retryable: true,
  );
  @override
  Future<void> acceptOrder(String orderId) async => throw _error;
  @override
  Future<void> cannotFulfil(String orderId, String reason) async =>
      throw _error;
  @override
  Future<String> confirmHandover(String orderId) async => throw _error;
  @override
  Future<String> createIssue(String orderId, String reason) async =>
      throw _error;
  @override
  Future<RetailerStoreSnapshot> loadStore() async => throw _error;
  @override
  Future<List<RetailerOrder>> refreshOrders() async => throw _error;
  @override
  Future<void> refreshTracking(String orderId) async => throw _error;
  @override
  Future<String> requestDelivery(String orderId) async => throw _error;
  @override
  Future<RetailerStoreSnapshot> saveProduct({
    required String productId,
    required int stock,
    required int buyPrice,
    required int sellPrice,
  }) async => throw _error;
  @override
  Future<void> savePackedOrder(String orderId) async => throw _error;
  @override
  Future<RetailerStoreSnapshot> setAvailability(bool enabled) async =>
      throw _error;
}

class AuthenticatedRetailerGateway implements RetailerGateway {
  AuthenticatedRetailerGateway({
    required this.endpoint,
    required this.credentials,
    required this.transport,
    Random? random,
  }) : random = random ?? Random.secure();
  final Uri endpoint;
  final SocialContentCredentials credentials;
  final SocialContentTransport transport;
  final Random random;

  @override
  Future<RetailerStoreSnapshot> loadStore() async =>
      _decodeStore(_map(await _invoke('retailerStoreState', const {})));
  @override
  Future<RetailerStoreSnapshot> setAvailability(bool enabled) async =>
      _decodeStore(
        _map(
          await _invoke('setRetailerAvailability', {
            'enabled': enabled,
          }, mutation: true),
        ),
      );
  @override
  Future<RetailerStoreSnapshot> saveProduct({
    required String productId,
    required int stock,
    required int buyPrice,
    required int sellPrice,
  }) async => _decodeStore(
    _map(
      await _invoke('saveRetailerProduct', {
        'productId': productId,
        'stock': stock,
        'buyPrice': buyPrice,
        'sellPrice': sellPrice,
      }, mutation: true),
    ),
  );
  @override
  Future<List<RetailerOrder>> refreshOrders() async {
    final data = _map(await _invoke('listRetailerOrders', const {}));
    final values = data['orders'];
    if (values is! List) {
      throw const RetailerGatewayException(
        'Orders returned an invalid response. Try again.',
        retryable: true,
      );
    }
    return values.map((value) => _decodeOrder(_map(value))).toList();
  }

  @override
  Future<void> acceptOrder(String orderId) =>
      _order('acceptRetailerOrder', orderId);
  @override
  Future<void> savePackedOrder(String orderId) =>
      _order('packRetailerOrder', orderId);
  @override
  Future<String> requestDelivery(String orderId) async => _requiredString(
    _map(await _order('requestRetailerDelivery', orderId))['deliveryReference'],
  );
  @override
  Future<String> confirmHandover(String orderId) async => _requiredString(
    _map(await _order('confirmRetailerHandover', orderId))['handoverReference'],
  );
  @override
  Future<void> refreshTracking(String orderId) =>
      _order('retailerDeliveryStatus', orderId, mutation: false);
  @override
  Future<String> createIssue(String orderId, String reason) async =>
      _requiredString(
        _map(
          await _invoke('createRetailerIssue', {
            'orderId': orderId,
            'reason': reason,
          }, mutation: true),
        )['issueReference'],
      );
  @override
  Future<void> cannotFulfil(String orderId, String reason) => _invoke(
    'declineRetailerOrder',
    {'orderId': orderId, 'reason': reason},
    mutation: true,
  );

  Future<Object?> _order(
    String operation,
    String orderId, {
    bool mutation = true,
  }) => _invoke(operation, {'orderId': orderId}, mutation: mutation);

  Future<Object?> _invoke(
    String operation,
    Map<String, Object?> body, {
    bool mutation = false,
  }) async {
    final response = await transport.postJson(
      endpoint,
      headers: {
        'accept': 'application/json',
        'authorization': 'Bearer ${await credentials.firebaseIdToken()}',
        'x-firebase-appcheck': await credentials.appCheckToken(
          mutation
              ? SocialAppCheckTokenMode.limitedUse
              : SocialAppCheckTokenMode.standard,
        ),
        'x-request-id': List<int>.generate(
          16,
          (_) => random.nextInt(256),
        ).map((value) => value.toRadixString(16).padLeft(2, '0')).join(),
      },
      body: {'operation': operation, ...body},
    );
    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const RetailerGatewayException(
        'Shop returned an invalid response. Try again.',
        retryable: true,
      );
    }
    final envelope = _map(decoded);
    if (envelope['ok'] == true) return envelope['data'];
    final error = _map(envelope['error']);
    throw RetailerGatewayException(
      _requiredString(error['message']),
      retryable: error['retryable'] == true,
    );
  }
}

class ReviewRetailerGateway implements RetailerGateway {
  bool failRefresh = false;
  bool failAvailability = false;
  bool failProduct = false;
  bool failAccept = false;
  bool failPacking = false;
  bool failDeliveryRequest = false;
  bool failHandover = false;
  bool failTracking = false;
  bool failIssue = false;
  bool failCannotFulfil = false;
  int availabilityCalls = 0;
  int productCalls = 0;
  int acceptCalls = 0;
  int packingCalls = 0;
  int deliveryRequestCalls = 0;
  int handoverCalls = 0;
  int trackingCalls = 0;
  int issueCalls = 0;
  int cannotFulfilCalls = 0;
  Future<void> _wait() =>
      Future<void>.delayed(const Duration(milliseconds: 24));

  @override
  Future<RetailerStoreSnapshot> loadStore() async {
    await _wait();
    if (failRefresh) {
      failRefresh = false;
      throw const RetailerGatewayException(
        'Shop could not be refreshed. Current details remain available.',
      );
    }
    return _snapshot(true, reviewPosProducts);
  }

  @override
  Future<List<RetailerOrder>> refreshOrders() async {
    await _wait();
    if (failRefresh) {
      failRefresh = false;
      throw const RetailerGatewayException(
        'Orders could not be refreshed. Current orders remain available.',
      );
    }
    return buildReviewRetailerOrders();
  }

  @override
  Future<RetailerStoreSnapshot> setAvailability(bool enabled) async {
    availabilityCalls++;
    await _wait();
    if (failAvailability) {
      failAvailability = false;
      throw const RetailerGatewayException(
        'Order availability was not changed. Your previous setting remains active.',
      );
    }
    return _snapshot(enabled, reviewPosProducts);
  }

  @override
  Future<RetailerStoreSnapshot> saveProduct({
    required String productId,
    required int stock,
    required int buyPrice,
    required int sellPrice,
  }) async {
    productCalls++;
    await _wait();
    if (failProduct) {
      failProduct = false;
      throw const RetailerGatewayException(
        'Product changes were not saved. Previous stock and price remain active.',
      );
    }
    final products = reviewPosProducts
        .map(
          (product) => product.id == productId
              ? RetailerPosProduct(
                  id: product.id,
                  name: product.name,
                  pack: product.pack,
                  sku: product.sku,
                  price: sellPrice,
                  stock: stock,
                )
              : product,
        )
        .toList();
    return _snapshot(true, products);
  }

  @override
  Future<void> acceptOrder(String orderId) async {
    acceptCalls++;
    await _wait();
    if (failAccept) {
      failAccept = false;
      throw const RetailerGatewayException(
        'Order was not accepted. Payment and the customer promise are unchanged.',
      );
    }
  }

  @override
  Future<void> savePackedOrder(String orderId) async {
    packingCalls++;
    await _wait();
    if (failPacking) {
      failPacking = false;
      throw const RetailerGatewayException(
        'Packed status was not saved. Your checked items remain selected.',
      );
    }
  }

  @override
  Future<String> requestDelivery(String orderId) async {
    deliveryRequestCalls++;
    await _wait();
    if (failDeliveryRequest) {
      failDeliveryRequest = false;
      throw const RetailerGatewayException(
        'Delivery was not assigned. The packed order remains at your shop.',
      );
    }
    return 'DEL-$orderId-${420 + deliveryRequestCalls}';
  }

  @override
  Future<String> confirmHandover(String orderId) async {
    handoverCalls++;
    await _wait();
    if (failHandover) {
      failHandover = false;
      throw const RetailerGatewayException(
        'Handover was not recorded. Keep the parcel until confirmation succeeds.',
      );
    }
    return 'HAND-$orderId-${810 + handoverCalls}';
  }

  @override
  Future<void> refreshTracking(String orderId) async {
    trackingCalls++;
    await _wait();
    if (failTracking) {
      failTracking = false;
      throw const RetailerGatewayException(
        'Live delivery update is unavailable. No delivery state was changed.',
      );
    }
  }

  @override
  Future<String> createIssue(String orderId, String reason) async {
    issueCalls++;
    await _wait();
    if (failIssue) {
      failIssue = false;
      throw const RetailerGatewayException(
        'Delivery issue was not sent. Your order and selected reason remain saved.',
      );
    }
    return 'DI-$orderId-${900 + issueCalls}';
  }

  @override
  Future<void> cannotFulfil(String orderId, String reason) async {
    cannotFulfilCalls++;
    await _wait();
    if (failCannotFulfil) {
      failCannotFulfil = false;
      throw const RetailerGatewayException(
        'The order was not declined. It remains open for your decision.',
      );
    }
  }
}

RetailerStoreSnapshot _snapshot(
  bool enabled,
  List<RetailerPosProduct> products,
) => RetailerStoreSnapshot(
  workspaceId: 'WK-510001',
  name: 'Mahadev Fresh Mart',
  area: 'Sardarpura',
  ordersEnabled: enabled,
  products: List<RetailerPosProduct>.of(products),
);

RetailerStoreSnapshot _decodeStore(Map<String, Object?> data) {
  final rawProducts = data['products'];
  if (rawProducts is! List) {
    throw const RetailerGatewayException(
      'Shop returned an invalid response. Try again.',
      retryable: true,
    );
  }
  return RetailerStoreSnapshot(
    workspaceId: _requiredString(data['workspaceId']),
    name: _requiredString(data['name']),
    area: _requiredString(data['area']),
    ordersEnabled: data['ordersEnabled'] == true,
    products: rawProducts.map((value) {
      final product = _map(value);
      return RetailerPosProduct(
        id: _requiredString(product['id']),
        name: _requiredString(product['name']),
        pack: _requiredString(product['pack']),
        sku: _requiredString(product['sku']),
        price: _requiredInt(product['price']),
        stock: _requiredInt(product['stock'], allowZero: true),
      );
    }).toList(),
  );
}

Map<String, Object?> _map(Object? value) {
  if (value is! Map) {
    throw const RetailerGatewayException(
      'Shop returned an invalid response. Try again.',
      retryable: true,
    );
  }
  return value.map((key, item) => MapEntry(key.toString(), item));
}

String _requiredString(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    throw const RetailerGatewayException(
      'Shop returned an invalid response. Try again.',
      retryable: true,
    );
  }
  return value.trim();
}

int _requiredInt(Object? value, {bool allowZero = false}) {
  if (value is! int || value < (allowZero ? 0 : 1)) {
    throw const RetailerGatewayException(
      'Shop returned an invalid response. Try again.',
      retryable: true,
    );
  }
  return value;
}

RetailerOrder _decodeOrder(Map<String, Object?> data) {
  final rawLines = data['lines'];
  if (rawLines is! List) {
    throw const RetailerGatewayException(
      'Orders returned an invalid response. Try again.',
      retryable: true,
    );
  }
  final order = RetailerOrder(
    id: _requiredString(data['id']),
    customer: _requiredString(data['customer']),
    area: _requiredString(data['area']),
    payment: _requiredString(data['payment']),
    fulfilment: _requiredString(data['fulfilment']),
    deliveryPromise: _requiredString(data['deliveryPromise']),
    amount: _requiredInt(data['amount']),
    stage: _decodeOrderStage(_requiredString(data['stage'])),
    lines: rawLines.map((value) {
      final line = _map(value);
      return RetailerOrderLine(
        id: _requiredString(line['id']),
        name: _requiredString(line['name']),
        detail: _requiredString(line['detail']),
        quantity: _requiredInt(line['quantity']),
        amount: _requiredInt(line['amount'], allowZero: true),
        packed: line['packed'] == true,
      );
    }).toList(),
  );
  order
    ..cannotFulfilReason = _optionalString(data['cannotFulfilReason'])
    ..deliveryReference = _optionalString(data['deliveryReference'])
    ..captainName = _optionalString(data['captainName'])
    ..captainVehicle = _optionalString(data['captainVehicle'])
    ..handoverReference = _optionalString(data['handoverReference'])
    ..deliveryProof = _optionalString(data['deliveryProof'])
    ..issueReference = _optionalString(data['issueReference']);
  return order;
}

RetailerOrderStage _decodeOrderStage(String value) => switch (value) {
  'accepted' => RetailerOrderStage.accepted,
  'packing' => RetailerOrderStage.packing,
  'packed' => RetailerOrderStage.packed,
  'delivery_requested' => RetailerOrderStage.deliveryRequested,
  'captain_assigned' => RetailerOrderStage.captainAssigned,
  'parcel_ready' => RetailerOrderStage.parcelReady,
  'captain_arrived' => RetailerOrderStage.captainArrived,
  'handover_verified' => RetailerOrderStage.handoverVerified,
  'handed_over' => RetailerOrderStage.handedOver,
  'out_for_delivery' => RetailerOrderStage.outForDelivery,
  'nearby' => RetailerOrderStage.nearby,
  'delivered' => RetailerOrderStage.delivered,
  'cancelled' => RetailerOrderStage.cancelled,
  'returned' => RetailerOrderStage.returned,
  'cannot_fulfil' => RetailerOrderStage.cannotFulfil,
  _ => RetailerOrderStage.newOrder,
};

String? _optionalString(Object? value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;
