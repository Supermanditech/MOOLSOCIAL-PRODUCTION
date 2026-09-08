import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../work/scan_and_pick_contract.dart';
import 'buy_session.dart';
import 'buy_v2_cart_contracts.dart';
import 'buy_v2_content_contracts.dart';
import 'buy_v2_models.dart';
import 'buy_v2_order_resolution_contracts.dart';
import 'buy_v2_search_relevance.dart';
import 'buy_v2_saved_products_store.dart';
import 'buy_v2_shopping_alerts.dart';

String _buyV2SavedKey(BuyV2Product product) => product.storeId == null
    ? '${product.destination.name}|${product.canonicalId}'
    : '${product.destination.name}|listing:${Uri.encodeComponent(product.id)}';

String? _buyV2SavedListingId(String key) {
  final separator = key.indexOf('|listing:');
  if (separator < 0 ||
      !BuyV2Destination.values.any(
        (value) => value.name == key.substring(0, separator),
      )) {
    return null;
  }
  try {
    final id = Uri.decodeComponent(key.substring(separator + 9));
    return id.trim().isEmpty ? null : id;
  } on FormatException {
    return null;
  }
}

/// A catalogue draft. Previewing it never changes the session or saved account.
@immutable
class BuyV2DiscoveryRefinements {
  BuyV2DiscoveryRefinements({
    Set<String> brands = const {},
    this.maximumPrice,
    this.pack,
    this.fulfilmentMode,
    this.filter,
    this.sort = BuyV2ProductSort.relevance,
    this.availableOnly = false,
  }) : brands = Set.unmodifiable(brands);

  final Set<String> brands;
  final int? maximumPrice;
  final BuyV2PackFilter? pack;
  final BuyV2FulfilmentMode? fulfilmentMode;
  final String? filter;
  final BuyV2ProductSort sort;
  final bool availableOnly;

  int get count =>
      brands.length +
      (maximumPrice == null ? 0 : 1) +
      (pack == null ? 0 : 1) +
      (fulfilmentMode == null ? 0 : 1) +
      (filter == null ? 0 : 1) +
      (sort == BuyV2ProductSort.relevance ? 0 : 1) +
      (availableOnly ? 1 : 0);

  BuyV2DiscoveryRefinements copyWith({
    Set<String>? brands,
    int? maximumPrice,
    bool clearPrice = false,
    BuyV2PackFilter? pack,
    bool clearPack = false,
    BuyV2ProductSort? sort,
    bool? availableOnly,
  }) => BuyV2DiscoveryRefinements(
    brands: brands ?? this.brands,
    maximumPrice: clearPrice ? null : maximumPrice ?? this.maximumPrice,
    pack: clearPack ? null : pack ?? this.pack,
    fulfilmentMode: fulfilmentMode,
    filter: filter,
    sort: sort ?? this.sort,
    availableOnly: availableOnly ?? this.availableOnly,
  );
}

@immutable
class _BuyV2CartBenefitSelectionRef {
  const _BuyV2CartBenefitSelectionRef({
    required this.benefitId,
    required this.sourceId,
  });

  final String benefitId;
  final String sourceId;
}

@immutable
class _BuyV2DeliveryPromiseQuote {
  const _BuyV2DeliveryPromiseQuote({
    required this.promise,
    this.promisedByLabel,
  });

  final String promise;
  final String? promisedByLabel;

  @override
  bool operator ==(Object other) =>
      other is _BuyV2DeliveryPromiseQuote &&
      other.promise == promise &&
      other.promisedByLabel == promisedByLabel;

  @override
  int get hashCode => Object.hash(promise, promisedByLabel);
}

typedef BuyV2DeliveryPromiseChange = ({
  String groupKey,
  String previousPromise,
  String? previousPromisedByLabel,
  String currentPromise,
  String? currentPromisedByLabel,
});

typedef BuyV2PriceChange = ({
  String productId,
  String title,
  int previousPrice,
  int currentPrice,
});

typedef BuyV2CheckoutAvailabilityIssue = ({
  String productId,
  String title,
  String orderabilityLabel,
});

typedef _BuyV2NavigationSurfaceIdentity = ({
  BuyV2Destination destination,
  BuyV2View view,
  String? detail,
});

typedef _BuyV2RecoveryOrigin = ({
  BuyV2Destination destination,
  BuyV2View view,
  BuyV2CartScope cartScope,
  BuyV2CartScope checkoutScope,
  BuyV2OrdersTab ordersTab,
  String shopCategoryId,
  String wholesaleCategoryId,
  String medicineCategoryId,
  String query,
  String? filter,
  String? productId,
  String? orderId,
});

enum BuyV2CheckoutSubmissionState {
  idle,
  submitting,
  paymentActionRequired,
  paymentPending,
  paymentUnknown,
  cancelled,
  confirmed,
  failed,
  unavailable,
}

final class _BuyV2UnavailableCommerceAdapter implements BuyV2CommerceAdapter {
  const _BuyV2UnavailableCommerceAdapter();

  static const _unavailable =
      'Shop is unavailable right now. Try again shortly.';

  @override
  Future<BuyV2CommerceSnapshot> refresh() async => const BuyV2CommerceSnapshot(
    state: BuyV2CommerceLoadState.unavailable,
    customerMessage: _unavailable,
  );

  @override
  Future<BuyV2OrderPlacementResult> placeOrder(
    BuyV2OrderPlacementRequest request,
  ) async => const BuyV2OrderPlacementResult(
    outcome: BuyV2OrderPlacementOutcome.unavailable,
    customerMessage:
        'Ordering is unavailable right now. Your Cart has not changed.',
  );

  @override
  Future<BuyV2OrderPlacementResult> reconcileOrder({
    required String idempotencyKey,
    required String paymentReference,
  }) async => const BuyV2OrderPlacementResult(
    outcome: BuyV2OrderPlacementOutcome.unavailable,
    customerMessage:
        'Payment status is unavailable right now. Do not pay again.',
  );

  @override
  Future<BuyV2OrderRefreshResult> refreshOrder({
    required String orderId,
  }) async => const BuyV2OrderRefreshResult(
    state: BuyV2CommerceLoadState.unavailable,
    customerMessage: 'Order updates are unavailable right now.',
  );

  @override
  Future<BuyV2OrderAlertsResult> loadOrderAlerts() async =>
      const BuyV2OrderAlertsResult(
        available: false,
        enabled: false,
        customerMessage: 'Order alerts are unavailable right now.',
      );

  @override
  Future<BuyV2OrderAlertsResult> setOrderAlerts({
    required bool enabled,
  }) async => const BuyV2OrderAlertsResult(
    available: false,
    enabled: false,
    customerMessage: 'Order alerts are unavailable right now.',
  );

  @override
  Future<BuyV2MutationResult> submitProductReview({
    required BuyV2Product product,
    required int rating,
    required String comment,
  }) async => const BuyV2MutationResult(
    accepted: false,
    customerMessage: 'Reviews are unavailable right now. Try again later.',
  );

  @override
  Future<BuyV2MutationResult> reportProduct({
    required BuyV2Product product,
    required String reason,
  }) async => const BuyV2MutationResult(
    accepted: false,
    customerMessage:
        'Product reporting is unavailable right now. Try again later.',
  );

  @override
  Future<BuyV2AddressRequestResult> createAddressRequest({
    String recipient = '',
  }) async => const BuyV2AddressRequestResult(
    customerMessage:
        'Address requests are unavailable right now. Enter the address yourself.',
  );
}

final class _BuyV2DeviceReviewCommerceAdapter implements BuyV2CommerceAdapter {
  const _BuyV2DeviceReviewCommerceAdapter();

  @override
  Future<BuyV2CommerceSnapshot> refresh() async => BuyV2CommerceSnapshot(
    state: BuyV2CommerceLoadState.ready,
    products: BuyV2Catalogue.allProducts,
    paymentMethods: BuyV2Session.paymentMethods,
    businessVerified: true,
    businessVerificationState: BuyV2BusinessVerificationState.verified,
    productReportsAvailable: true,
    reviewableProductIds: const {
      's-tomato',
      's-atta',
      's-oil',
      's-rice',
      's-soap',
      's-notebook',
      's-onion',
      's-banana',
      'w-rice',
      'w-oil',
      'w-notebook',
    },
  );

  @override
  Future<BuyV2OrderPlacementResult> placeOrder(
    BuyV2OrderPlacementRequest request,
  ) async {
    final reference =
        'BT-${DateTime.now().microsecondsSinceEpoch.toString().substring(8)}';
    if (const {
      'PhonePe',
      'Paytm',
      'Pine Labs',
    }.contains(request.paymentMethod)) {
      final provider = request.paymentMethod.toLowerCase().replaceAll(' ', '-');
      final paymentReference = reference.replaceFirst('BT-', 'PAY-');
      return BuyV2OrderPlacementResult(
        outcome: BuyV2OrderPlacementOutcome.paymentActionRequired,
        customerMessage:
            'Continue securely with ${request.paymentMethod}. MoolSocial will collect this payment.',
        paymentReference: paymentReference,
        paymentActionUri: Uri.https('payments.moolsocial.app', '/checkout', {
          'provider': provider,
          'reference': paymentReference,
        }),
      );
    }
    return BuyV2OrderPlacementResult(
      outcome: BuyV2OrderPlacementOutcome.confirmed,
      customerMessage: 'Your order is confirmed.',
      purchaseReference:
          'MS-${DateTime.now().microsecondsSinceEpoch.toString().substring(8)}',
    );
  }

  @override
  Future<BuyV2OrderPlacementResult> reconcileOrder({
    required String idempotencyKey,
    required String paymentReference,
  }) async => paymentReference.startsWith('BT-')
      ? BuyV2OrderPlacementResult(
          outcome: BuyV2OrderPlacementOutcome.paymentPending,
          customerMessage:
              'Your transfer is still being checked. Do not transfer again.',
          paymentReference: paymentReference,
        )
      : BuyV2OrderPlacementResult(
          outcome: BuyV2OrderPlacementOutcome.confirmed,
          customerMessage: 'Payment confirmed. Your order is placed.',
          purchaseReference: paymentReference.replaceFirst('PAY-', 'MS-'),
          paymentReference: paymentReference,
        );

  @override
  Future<BuyV2OrderRefreshResult> refreshOrder({
    required String orderId,
  }) async => const BuyV2OrderRefreshResult(
    state: BuyV2CommerceLoadState.unavailable,
    customerMessage: 'Order updates are unavailable right now.',
  );

  @override
  Future<BuyV2OrderAlertsResult> loadOrderAlerts() async =>
      const BuyV2OrderAlertsResult(
        available: true,
        enabled: true,
        customerMessage: 'Order alerts are on.',
      );

  @override
  Future<BuyV2OrderAlertsResult> setOrderAlerts({
    required bool enabled,
  }) async => BuyV2OrderAlertsResult(
    available: true,
    enabled: enabled,
    customerMessage: enabled
        ? 'Order alerts are on.'
        : 'Order alerts are paused.',
  );

  @override
  Future<BuyV2MutationResult> submitProductReview({
    required BuyV2Product product,
    required int rating,
    required String comment,
  }) async => const BuyV2MutationResult(
    accepted: true,
    customerMessage: 'Your review was added.',
  );

  @override
  Future<BuyV2MutationResult> reportProduct({
    required BuyV2Product product,
    required String reason,
  }) async => const BuyV2MutationResult(
    accepted: true,
    customerMessage: 'Report received. We will review the product details.',
  );

  @override
  Future<BuyV2AddressRequestResult> createAddressRequest({
    String recipient = '',
  }) async => BuyV2AddressRequestResult(
    shareUri: Uri.parse('https://moolsocial.com/address/request'),
    customerMessage: 'Choose an app to send the address request.',
  );
}

final class _BuyV2DeviceReviewGstInvoiceProfileStore
    implements BuyV2GstInvoiceProfileStore {
  BuyV2GstInvoiceProfileSnapshot? _snapshot;

  @override
  String? get ownerScope => 'device-review-session:buy-gst';

  @override
  Future<BuyV2GstInvoiceProfileSnapshot?> read() async => _snapshot;

  @override
  Future<bool> write(BuyV2GstInvoiceProfileSnapshot snapshot) async {
    _snapshot = snapshot;
    return true;
  }
}

class _BuyV2CollectionState {
  ScanPickSnapshot? snapshot;
  BuyV2CollectionPendingIntent? pendingIntent;
  final Stopwatch elapsed = Stopwatch();
  bool busy = false;
  bool pending = false;
  bool refreshRequired = true;
  int attempt = 0;
  int? navigation;
  String? message;
  String? scanMessage;
  ScanPickState? scanMessageState;
  String? scanMessageChallenge;
}

typedef _BuyV2CollectionContext = ({
  BuyV2Order order,
  BuyV2CollectionIdentity identity,
  int epoch,
  int navigation,
});

/// A bounded page window. Filter changes replace the pending request and stale
/// responses never enter the cache. One controller has one source call in flight.
class BuyV2CataloguePager<T> extends ChangeNotifier {
  BuyV2CataloguePager({
    required this.load,
    required this.identityOf,
    this.pageSize = 40,
    this.maximumCachedPages = 3,
  }) {
    if (pageSize < 1 ||
        pageSize > 50 ||
        maximumCachedPages < 1 ||
        maximumCachedPages > 5) {
      throw ArgumentError('Invalid catalogue page bounds');
    }
  }

  final Future<BuyV2CataloguePage<T>> Function(
    BuyV2CatalogueQuery query, {
    String? cursor,
    required int pageSize,
  })
  load;
  final String Function(T item) identityOf;
  final int pageSize;
  final int maximumCachedPages;
  final Map<String, BuyV2CataloguePage<T>> _cache = {};
  final Map<String, Map<String, double>> _scrollOffsets = {};
  BuyV2CatalogueQuery? _query;
  BuyV2CataloguePage<T>? _page;
  ({BuyV2CatalogueQuery query, String? cursor, int generation})? _pending;
  Future<void>? _running;
  String? _cursor;
  String? _requestedCursor;
  int _generation = 0;
  bool _disposed = false;
  bool _loading = false;
  String? _message;

  BuyV2CatalogueQuery? get query => _query;
  BuyV2CataloguePage<T>? get page => _page;
  String? get cursor => _cursor;
  String? get requestedCursor => _requestedCursor;
  bool get isDisposed => _disposed;
  bool get loading => _loading;
  String? get message => _message;
  int get cachedPageCount => _cache.length;
  int get retainedItemCount =>
      _cache.values.fold(0, (count, value) => count + value.items.length);
  Iterable<T> get cachedItems => _cache.values.expand((page) => page.items);
  String _pageScrollKey(
    BuyV2CatalogueQuery query,
    BuyV2CataloguePage<T> page,
  ) => jsonEncode([query.key, page.snapshotId, page.startIndex]);
  String? get _visibleScrollKey =>
      _query == null || _page == null ? null : _pageScrollKey(_query!, _page!);

  double _readOffset(String axis) =>
      _scrollOffsets[_visibleScrollKey]?[axis] ?? 0;

  void _rememberOffset(String axis, double value) {
    final key = _visibleScrollKey;
    if (_disposed ||
        key == null ||
        _page == null ||
        !value.isFinite ||
        value < 0) {
      return;
    }
    _scrollOffsets.putIfAbsent(key, () => {})[axis] = value;
  }

  double get scrollOffset => _readOffset('vertical');
  set scrollOffset(double value) => _rememberOffset('vertical', value);
  double laneOffset(int lane) => _readOffset('lane-${lane.clamp(0, 1)}');
  void rememberLaneOffset(int lane, double value) =>
      _rememberOffset('lane-${lane.clamp(0, 1)}', value);

  String _cacheKey(BuyV2CatalogueQuery query, String? cursor) =>
      jsonEncode([query.key, cursor]);

  Future<void> open(BuyV2CatalogueQuery query, {String? cursor}) {
    if (_disposed) return Future.value();
    if (_query == query &&
        _requestedCursor == cursor &&
        (_loading ||
            (_page != null && _cursor == cursor && _message == null))) {
      return _running ?? Future.value();
    }
    final changedQuery = _query != query;
    if (changedQuery) {
      _page = null;
      _cursor = null;
      _cache.clear();
      _scrollOffsets.clear();
    }
    _query = query;
    _requestedCursor = cursor;
    _message = null;
    final generation = ++_generation;
    final cacheKey = _cacheKey(query, cursor);
    final cached = _cache.remove(cacheKey);
    if (cached != null) {
      _cache[cacheKey] = cached;
      _page = cached;
      _cursor = cursor;
      _pending = null;
      _loading = false;
      notifyListeners();
      return Future.value();
    }
    _pending = (query: query, cursor: cursor, generation: generation);
    _loading = true;
    notifyListeners();
    return _running ??= _drain().whenComplete(() => _running = null);
  }

  Future<void> next() {
    final currentQuery = _query;
    final next = _page?.nextCursor;
    if (currentQuery == null || next == null || _loading) {
      return _running ?? Future.value();
    }
    return open(currentQuery, cursor: next);
  }

  Future<void> previous() {
    final currentQuery = _query;
    final previous = _page?.previousCursor;
    if (currentQuery == null || previous == null || _loading) {
      return _running ?? Future.value();
    }
    return open(currentQuery, cursor: previous);
  }

  Future<void> retry() {
    final currentQuery = _query;
    if (currentQuery == null) return Future.value();
    return open(currentQuery, cursor: _requestedCursor);
  }

  Future<void> refresh() {
    final currentQuery = _query;
    if (currentQuery == null || _disposed) return Future.value();
    _cache.clear();
    _scrollOffsets.clear();
    _page = null;
    _cursor = null;
    _requestedCursor = null;
    _generation += 1;
    _loading = false;
    _message = null;
    return open(currentQuery);
  }

  Future<void> _drain() async {
    while (!_disposed && _pending != null) {
      final request = _pending!;
      _pending = null;
      final previous = _page;
      final previousCursor = _cursor;
      try {
        final result = await load(
          request.query,
          cursor: request.cursor,
          pageSize: pageSize,
        );
        if (_disposed || request.generation != _generation) continue;
        _validate(
          result,
          request.query,
          request.cursor,
          previous,
          previousCursor,
        );
        final key = _cacheKey(request.query, request.cursor);
        _cache.remove(key);
        _cache[key] = result;
        while (_cache.length > maximumCachedPages) {
          _cache.remove(_cache.keys.first);
        }
        final retainedOffsets = _cache.values
            .map((page) => _pageScrollKey(request.query, page))
            .toSet();
        _scrollOffsets.removeWhere((key, _) => !retainedOffsets.contains(key));
        _page = result;
        _cursor = request.cursor;
        _message = null;
      } on Object {
        if (_disposed || request.generation != _generation) continue;
        _message = 'Results could not load. Try again.';
      }
      if (!_disposed && request.generation == _generation) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  void _validate(
    BuyV2CataloguePage<T> result,
    BuyV2CatalogueQuery query,
    String? requestedCursor,
    BuyV2CataloguePage<T>? previous,
    String? previousCursor,
  ) {
    final total = result.totalCount;
    final ids = result.items.map(identityOf).toList(growable: false);
    final end = result.startIndex + result.items.length;
    if (result.queryKey != query.key ||
        result.snapshotId.trim().isEmpty ||
        result.items.length > pageSize ||
        result.startIndex < 0 ||
        (requestedCursor == null && result.startIndex != 0) ||
        ids.any((id) => id.trim().isEmpty) ||
        ids.toSet().length != ids.length ||
        (result.nextCursor != null && result.nextCursor!.trim().isEmpty) ||
        (result.previousCursor != null &&
            result.previousCursor!.trim().isEmpty) ||
        (result.nextCursor != null && result.nextCursor == requestedCursor) ||
        (result.previousCursor != null &&
            result.previousCursor == requestedCursor) ||
        (result.startIndex == 0 && result.previousCursor != null) ||
        (result.startIndex > 0 && result.previousCursor == null) ||
        (result.items.isEmpty && result.nextCursor != null) ||
        (total != null &&
            (total < 0 ||
                end > total ||
                (result.nextCursor == null && end != total) ||
                (result.nextCursor != null && end >= total)))) {
      throw const FormatException('Invalid catalogue page');
    }
    if (previous != null &&
        requestedCursor != null &&
        requestedCursor != previousCursor) {
      if (result.snapshotId != previous.snapshotId ||
          result.totalCount != previous.totalCount) {
        throw const FormatException('Catalogue snapshot changed');
      }
      if (requestedCursor == previous.nextCursor &&
          result.startIndex != previous.startIndex + previous.items.length) {
        throw const FormatException('Catalogue next-page gap');
      }
      if (requestedCursor == previous.previousCursor &&
          end != previous.startIndex) {
        throw const FormatException('Catalogue previous-page gap');
      }
      final previousIds = previous.items.map(identityOf).toSet();
      if (ids.any(previousIds.contains)) {
        throw const FormatException('Duplicate catalogue page boundary');
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _scrollOffsets.clear();
    _generation += 1;
    _pending = null;
    _cache.clear();
    super.dispose();
  }
}

/// Versioned, on-demand development catalogue. Each destination is an isolated
/// fixture cohort; no inventory, payment or serviceability is claimed live.
/// Only the requested page creates Product/Store objects, never the Cartesian
/// estate. Stable IDs are also resolved through the future transport's seam.
class BuyV2DevelopmentCatalogueSource implements BuyV2CataloguePageSource {
  BuyV2DevelopmentCatalogueSource({
    required this.destination,
    this.providerCount = 100000,
    this.skusPerStore = 5000,
    this.now = DateTime.now,
  }) : _templates = List.unmodifiable(
         BuyV2Catalogue.products.where((p) => p.destination == destination),
       ) {
    if (_templates.isEmpty ||
        providerCount < 1 ||
        providerCount > 100000 ||
        skusPerStore < 1 ||
        skusPerStore > 5000) {
      throw ArgumentError('Invalid development catalogue cohort');
    }
  }

  static const version = 'buy-catalogue-dev-v1';
  static const regions = [
    'jodhpur',
    'jaipur',
    'delhi',
    'mumbai',
    'bengaluru',
    'hyderabad',
    'kolkata',
    'pune',
    'ahmedabad',
    'chennai',
  ];
  final BuyV2Destination destination;
  final int providerCount;
  final int skusPerStore;
  final DateTime Function() now;
  final List<BuyV2Product> _templates;
  int productObjectsCreated = 0;
  int storeObjectsCreated = 0;

  String get _snapshotId =>
      '$version-${destination.name}-$providerCount-$skusPerStore';

  String storeIdAt(int index) =>
      '$version-${destination.name}-store-${(index + 1).toString().padLeft(6, '0')}';

  String productIdAt(int store, int sku) =>
      '${storeIdAt(store)}-sku-${(sku + 1).toString().padLeft(4, '0')}';

  int? _storeIndex(String? id) {
    if (id == null) return null;
    final prefix = '$version-${destination.name}-store-';
    if (!id.startsWith(prefix)) return null;
    final suffix = id.substring(prefix.length);
    if (!RegExp(r'^\d{6}$').hasMatch(suffix)) return null;
    final index = int.parse(suffix) - 1;
    return index >= 0 && index < providerCount ? index : null;
  }

  String _region(int store) => regions[store % regions.length];
  String _name(int store) =>
      'Mool Market ${(store + 1).toString().padLeft(6, '0')}';
  String _area(int store) =>
      '${_region(store)} · Market ${store ~/ regions.length + 1}';

  bool _serviceable(int store, BuyV2CatalogueQuery query) {
    if (query.storeId != null ||
        query.areaScope == BuyV2CatalogueAreaScope.allAreas) {
      return true;
    }
    final region = query.regionId;
    if (!regions.contains(region)) return false;
    if (_region(store) == region) return true;
    return query.areaScope == BuyV2CatalogueAreaScope.national &&
        store % 3 == 0 &&
        regions[(store + 1) % regions.length] != region;
  }

  List<int> _stores(BuyV2CatalogueQuery query, {required bool searchNames}) {
    if (query.destination != destination) return const [];
    final selected = _storeIndex(query.storeId);
    if (query.storeId != null && selected == null) return const [];
    final text = query.query.trim().toLowerCase();
    final indexes = <int>[];
    final first = selected ?? 0;
    final end = selected == null ? providerCount : selected + 1;
    for (var index = first; index < end; index++) {
      if (!_serviceable(index, query)) continue;
      if (query.collectionOnly && index % 4 == 3) continue;
      if (searchNames &&
          text.isNotEmpty &&
          !'${_name(index)} ${_area(index)} ${storeIdAt(index)}'
              .toLowerCase()
              .contains(text)) {
        continue;
      }
      indexes.add(index);
    }
    return indexes;
  }

  BuyV2StoreCollectionCapability _capability(int store) {
    final observed = now();
    return BuyV2StoreCollectionCapability(
      storeId: storeIdAt(store),
      supportsCollection: store % 4 != 3,
      sourceId: version,
      observedAt: observed,
      validUntil: observed.add(const Duration(minutes: 15)),
    );
  }

  BuyV2Product _product(int store, int sku) {
    productObjectsCreated += 1;
    final base = _templates[sku % _templates.length];
    return base.copyWith(
      id: productIdAt(store, sku),
      canonicalId: '$version-${destination.name}-product-${sku + 1}',
      storeId: storeIdAt(store),
      title: '${base.title} ${sku + 1}',
      seller: _name(store),
      origin: _area(store),
      variant: '${base.variant} · SKU ${sku + 1}',
      catalogueListing: true,
    );
  }

  BuyV2StoreListing _store(int index, {int previewSku = 0}) {
    storeObjectsCreated += 1;
    return BuyV2StoreListing(
      id: storeIdAt(index),
      name: _name(index),
      area: _area(index),
      address: '${index + 1}, ${_area(index)}',
      regionId: _region(index),
      // No invented distance: a real location service must supply that field.
      collection: _capability(index),
      previewProduct: _product(index, previewSku),
    );
  }

  bool _matchesSku(
    int sku,
    BuyV2CatalogueQuery query, {
    bool ignoreText = false,
  }) {
    final base = _templates[sku % _templates.length];
    if (query.categoryId != 'all' && base.categoryId != query.categoryId) {
      return false;
    }
    if (query.brands.isNotEmpty && !query.brands.contains(base.brand)) {
      return false;
    }
    if (query.maximumPrice != null && base.price > query.maximumPrice!) {
      return false;
    }
    if (query.offersOnly && sku % 5 != 0) return false;
    final fulfilment = buyV2CatalogueFulfilmentModeFor(base);
    if (query.fulfilmentMode != null && query.fulfilmentMode != fulfilment) {
      return false;
    }
    if (query.shopSaleType != null &&
        ((query.shopSaleType == BuyV2ShopSaleType.quickDelivery) !=
            (fulfilment == BuyV2FulfilmentMode.quickLocal))) {
      return false;
    }
    if (query.wholesaleSaleType != null &&
        ((query.wholesaleSaleType == BuyV2WholesaleSaleType.bulk) !=
            (base.minimumOrder > 2))) {
      return false;
    }
    final pack = base.destination == BuyV2Destination.wholesale
        ? (base.minimumOrder > 2
              ? BuyV2PackFilter.bulk
              : BuyV2PackFilter.standard)
        : base.minimumOrder > 1 ||
              RegExp(
                r'case|carton|crate|sack|pallet|lot|trade',
              ).hasMatch(base.pack.toLowerCase())
        ? BuyV2PackFilter.bulk
        : RegExp(
            r'pack of\s*[2-9]|[2-9]\s*[×x]',
          ).hasMatch(base.pack.toLowerCase())
        ? BuyV2PackFilter.multipack
        : BuyV2PackFilter.standard;
    if (query.pack != null && query.pack != pack) return false;
    final matchesFilter = switch (query.filter) {
      null => true,
      'fast' ||
      'today' ||
      'quick-local' => fulfilment == BuyV2FulfilmentMode.quickLocal,
      'standard-courier' => fulfilment == BuyV2FulfilmentMode.standardCourier,
      'bulk-freight' => fulfilment == BuyV2FulfilmentMode.bulkFreight,
      'freight' => base.freightIncluded,
      'moq' => base.minimumOrder <= 2,
      'manufacturer' =>
        base.manufacturerVerified ||
            base.sellerType.toLowerCase().contains('manufacturer'),
      'returns' => base.returnPolicy != null,
      'lowest' =>
        base.badge.toLowerCase().contains('lowest') ||
            base.badge.toLowerCase().contains('off'),
      // These require a regional source query, not inferred product promises.
      'nearby' ||
      'two-days' => query.areaScope == BuyV2CatalogueAreaScope.regional,
      'rx' => base.requiresPrescription,
      'otc' => !base.requiresPrescription,
      _ => false,
    };
    if (!matchesFilter) return false;
    final text = query.query.trim().toLowerCase();
    if (ignoreText || text.isEmpty) return true;
    final haystack = '${base.title} ${base.brand} ${base.pack} sku ${sku + 1}'
        .toLowerCase();
    return text.split(RegExp(r'\s+')).every(haystack.contains);
  }

  String _queryHash(BuyV2CatalogueQuery query) =>
      sha256.convert(utf8.encode(query.key)).toString();

  String _encodeCursor(BuyV2CatalogueQuery query, int start, int pageSize) =>
      base64Url.encode(
        utf8.encode(
          jsonEncode([_snapshotId, _queryHash(query), start, pageSize]),
        ),
      );

  int _offset(
    BuyV2CatalogueQuery query,
    String? cursor,
    int pageSize,
    int total,
  ) {
    if (pageSize < 1 || pageSize > 50) {
      throw ArgumentError('Page size exceeds bound');
    }
    if (cursor == null) return 0;
    final value = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(cursor))),
    );
    if (value is! List ||
        value.length != 4 ||
        value[0] != _snapshotId ||
        value[1] != _queryHash(query) ||
        value[2] is! int ||
        value[3] != pageSize ||
        (value[2] as int) < 0 ||
        (value[2] as int) >= total) {
      throw const FormatException('Development cursor does not match query');
    }
    return value[2] as int;
  }

  BuyV2CataloguePage<T> _page<T>(
    BuyV2CatalogueQuery query,
    String? cursor,
    int pageSize,
    int total,
    T Function(int index) itemAt,
  ) {
    final start = _offset(query, cursor, pageSize, total);
    final end = math.min(start + pageSize, total);
    return BuyV2CataloguePage(
      queryKey: query.key,
      snapshotId: _snapshotId,
      items: [for (var index = start; index < end; index++) itemAt(index)],
      startIndex: start,
      totalCount: total,
      previousCursor: start == 0
          ? null
          : _encodeCursor(query, math.max(0, start - pageSize), pageSize),
      nextCursor: end == total ? null : _encodeCursor(query, end, pageSize),
    );
  }

  @override
  Future<BuyV2CataloguePage<BuyV2StoreListing>> loadStores(
    BuyV2CatalogueQuery query, {
    String? cursor,
    required int pageSize,
  }) async {
    final stores = _stores(query, searchNames: true);
    final previewSku = Iterable.generate(
      skusPerStore,
    ).where((sku) => _matchesSku(sku, query, ignoreText: true)).firstOrNull;
    return _page(
      query,
      cursor,
      pageSize,
      previewSku == null ? 0 : stores.length,
      (i) => _store(stores[i], previewSku: previewSku!),
    );
  }

  @override
  Future<BuyV2CataloguePage<BuyV2Product>> loadProducts(
    BuyV2CatalogueQuery query, {
    String? cursor,
    required int pageSize,
  }) async {
    final stores = _stores(query, searchNames: false);
    final skus = [
      for (var sku = 0; sku < skusPerStore; sku++)
        if (_matchesSku(sku, query)) sku,
    ];
    int price(int sku) => _templates[sku % _templates.length].price;
    if (query.sort == BuyV2ProductSort.priceLowToHigh ||
        query.sort == BuyV2ProductSort.priceHighToLow) {
      skus.sort((a, b) {
        final comparison = query.sort == BuyV2ProductSort.priceLowToHigh
            ? price(a).compareTo(price(b))
            : price(b).compareTo(price(a));
        return comparison != 0 ? comparison : a.compareTo(b);
      });
    } else if (query.sort == BuyV2ProductSort.deliveryFastest) {
      skus.sort((a, b) {
        final first = buyV2CatalogueFulfilmentModeFor(
          _templates[a % _templates.length],
        );
        final second = buyV2CatalogueFulfilmentModeFor(
          _templates[b % _templates.length],
        );
        final comparison = first.index.compareTo(second.index);
        return comparison != 0 ? comparison : a.compareTo(b);
      });
    }
    final sortedAcrossStores = query.sort != BuyV2ProductSort.relevance;
    return _page(query, cursor, pageSize, stores.length * skus.length, (i) {
      final storeIndex = sortedAcrossStores
          ? i % stores.length
          : i ~/ skus.length;
      final skuIndex = sortedAcrossStores
          ? i ~/ stores.length
          : i % skus.length;
      return _product(stores[storeIndex], skus[skuIndex]);
    });
  }

  @override
  Future<List<BuyV2Product>> resolveProducts(Set<String> productIds) async {
    if (productIds.length > 50) {
      throw ArgumentError('Product resolution exceeds bound');
    }
    final products = <BuyV2Product>[];
    for (final id in productIds) {
      final separator = id.lastIndexOf('-sku-');
      if (separator < 0) continue;
      final store = _storeIndex(id.substring(0, separator));
      final suffix = id.substring(separator + 5);
      if (store == null || !RegExp(r'^\d{4}$').hasMatch(suffix)) continue;
      final sku = int.parse(suffix) - 1;
      if (sku < 0 || sku >= skusPerStore) continue;
      products.add(_product(store, sku));
    }
    return List.unmodifiable(products);
  }
}

/// Bounded development publication feed with the same Store/SKU identities as
/// the Shop and Wholesale development catalogues. It is never live proof.
class BuyV2DevelopmentPublishedCatalogueSource
    implements BuyV2PublishedCatalogueSource {
  BuyV2DevelopmentPublishedCatalogueSource({
    int providerCount = 100000,
    int skusPerStore = 5000,
    this.now = DateTime.now,
  }) : _shop = BuyV2DevelopmentCatalogueSource(
         destination: BuyV2Destination.shop,
         providerCount: providerCount,
         skusPerStore: skusPerStore,
         now: now,
       ),
       _wholesale = BuyV2DevelopmentCatalogueSource(
         destination: BuyV2Destination.wholesale,
         providerCount: providerCount,
         skusPerStore: skusPerStore,
         now: now,
       );

  static const version = 'buy-published-offers-dev-v1';
  final DateTime Function() now;
  final BuyV2DevelopmentCatalogueSource _shop;
  final BuyV2DevelopmentCatalogueSource _wholesale;
  int get productObjectsCreated =>
      _shop.productObjectsCreated + _wholesale.productObjectsCreated;
  String get _snapshot =>
      '$version-${_shop.providerCount}-${_shop.skusPerStore}';

  BuyV2OfferPublisherType _publisher(BuyV2Destination destination, int store) =>
      destination == BuyV2Destination.shop
      ? BuyV2OfferPublisherType.retailer
      : (store ~/ BuyV2DevelopmentCatalogueSource.regions.length).isEven
      ? BuyV2OfferPublisherType.manufacturer
      : BuyV2OfferPublisherType.wholesaler;

  ({BuyV2DevelopmentCatalogueSource source, List<int> stores, List<int> skus})
  _cohort(BuyV2DevelopmentCatalogueSource source, BuyV2CatalogueQuery query) {
    final scoped = BuyV2CatalogueQuery(
      destination: source.destination,
      regionId: query.regionId,
      areaScope: query.areaScope,
      storeId: query.storeId,
      query: query.query,
      categoryId: query.categoryId,
      sort: query.sort,
      fulfilmentMode: query.fulfilmentMode,
      pack: query.pack,
      filter: query.filter,
      brands: query.brands,
      maximumPrice: query.maximumPrice,
      availableOnly: query.availableOnly,
      offersOnly: true,
      collectionOnly: query.collectionOnly,
      offerPublisher: query.offerPublisher,
    );
    var stores = source
        ._stores(scoped, searchNames: false)
        .where(
          (store) =>
              query.offerPublisher == null ||
              _publisher(source.destination, store) == query.offerPublisher,
        )
        .toList(growable: false);
    final text = query.query.trim().toLowerCase();
    final namedStores = text.isEmpty
        ? const <int>[]
        : stores
              .where(
                (store) =>
                    '${source._name(store)} ${source._area(store)} ${source.storeIdAt(store)}'
                        .toLowerCase()
                        .contains(text),
              )
              .toList(growable: false);
    // Development Store names do not overlap its product titles/brands. Either
    // Store-first or product-first search retains the same exact listing IDs.
    if (namedStores.isNotEmpty) stores = namedStores;
    final skus = [
      for (var sku = 0; sku < source.skusPerStore; sku++)
        if (source._matchesSku(sku, scoped, ignoreText: namedStores.isNotEmpty))
          sku,
    ];
    return (source: source, stores: stores, skus: skus);
  }

  String _cursor(BuyV2CatalogueQuery query, int start, int size) =>
      base64Url.encode(
        utf8.encode(
          jsonEncode([
            _snapshot,
            sha256.convert(utf8.encode(query.key)).toString(),
            start,
            size,
          ]),
        ),
      );

  int _offset(BuyV2CatalogueQuery query, String? cursor, int size, int total) {
    if (size < 1 || size > 50) throw ArgumentError('Offers page exceeds bound');
    if (cursor == null) return 0;
    final value = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(cursor))),
    );
    if (value is! List ||
        value.length != 4 ||
        value[0] != _snapshot ||
        value[1] != sha256.convert(utf8.encode(query.key)).toString() ||
        value[2] is! int ||
        value[3] != size ||
        (value[2] as int) < 0 ||
        (value[2] as int) >= total) {
      throw const FormatException('Offers cursor does not match query');
    }
    return value[2] as int;
  }

  @override
  Future<BuyV2CataloguePage<BuyV2PublishedCatalogueOffer>> loadOffers(
    BuyV2CatalogueQuery query, {
    String? cursor,
    required int pageSize,
  }) async {
    if (!query.offersOnly ||
        query.sort != BuyV2ProductSort.relevance ||
        query.shopSaleType != null ||
        query.wholesaleSaleType != null) {
      throw const FormatException('Unsupported development Offers query');
    }
    final shop = _cohort(_shop, query);
    final wholesale = _cohort(_wholesale, query);
    final shopCount = shop.stores.length * shop.skus.length;
    final wholesaleCount = wholesale.stores.length * wholesale.skus.length;
    final paired = math.min(shopCount, wholesaleCount);
    final total = shopCount + wholesaleCount;
    final start = _offset(query, cursor, pageSize, total);
    final end = math.min(start + pageSize, total);
    final observed = now();
    BuyV2PublishedCatalogueOffer itemAt(int index) {
      final inPair = index < paired * 2;
      final useShop = inPair ? index.isEven : shopCount > wholesaleCount;
      final cohort = useShop ? shop : wholesale;
      final offset = inPair ? index ~/ 2 : index - paired;
      final store = cohort.stores[offset ~/ cohort.skus.length];
      final sku = cohort.skus[offset % cohort.skus.length];
      final product = cohort.source._product(store, sku);
      final publisher = _publisher(product.destination, store);
      return BuyV2PublishedCatalogueOffer(
        publicationId: '$version-${product.id}',
        product: product,
        publisherType: publisher,
        publisherId: publisher == BuyV2OfferPublisherType.manufacturer
            ? '$version-maker-${product.brand}'
            : product.storeId!,
        publisherName: publisher == BuyV2OfferPublisherType.manufacturer
            ? '${product.brand} Makers'
            : product.seller,
        headline: switch (publisher) {
          BuyV2OfferPublisherType.manufacturer => 'Manufacturer price',
          BuyV2OfferPublisherType.wholesaler => 'Bulk saving',
          BuyV2OfferPublisherType.retailer => 'Store offer',
        },
        sourceId: version,
        observedAt: observed,
        validUntil: observed.add(const Duration(minutes: 15)),
      );
    }

    return BuyV2CataloguePage(
      queryKey: query.key,
      snapshotId: _snapshot,
      items: [for (var index = start; index < end; index++) itemAt(index)],
      startIndex: start,
      totalCount: total,
      previousCursor: start == 0
          ? null
          : _cursor(query, math.max(0, start - pageSize), pageSize),
      nextCursor: end == total ? null : _cursor(query, end, pageSize),
    );
  }
}

class _BuyV2PagerLease<T> {
  _BuyV2PagerLease(this.pager);

  final BuyV2CataloguePager<T> pager;
  int references = 1;
  int lastUsed = 0;
}

enum BuyV2CollectionCheckoutPhase {
  idle,
  checking,
  ready,
  pending,
  paid,
  blocked,
}

/// Buyer purchase coordinator for the existing checkout view. Missing shared
/// transports remain unavailable, including in device-review builds.
class BuyV2CollectionCheckoutController extends ChangeNotifier {
  BuyV2CollectionCheckoutController({
    required this.identity,
    this.gateway,
    this.pendingStore,
    this.collectionGateway,
    this.acceptPaidOrder,
    this.now = DateTime.now,
    this.timeout = const Duration(seconds: 15),
  }) {
    identity.addListener(_identityChanged);
  }

  final ValueListenable<BuyV2CollectionIdentity?> identity;
  final BuyV2CollectionCheckoutGateway? gateway;
  final BuyV2CollectionPurchaseStore? pendingStore;
  final ScanPickGateway? collectionGateway;
  final bool Function(BuyV2CollectionPurchaseIntent, ScanPickSnapshot)?
  acceptPaidOrder;
  final DateTime Function() now;
  final Duration timeout;
  BuyV2CollectionCheckoutPhase phase = BuyV2CollectionCheckoutPhase.idle;
  BuyV2CollectionBasket? basket;
  BuyV2CollectionCheckoutQuote? quote;
  BuyV2CollectionPurchaseIntent? intent;
  BuyV2CollectionPurchaseResult? result;
  ScanPickSnapshot? paidOrder;
  String? message;
  final Stopwatch _quoteElapsed = Stopwatch();
  DateTime? _quoteReceivedAt;
  int _epoch = 0;
  bool _disposed = false;
  bool _busy = false;

  bool get busy => _busy;
  bool get available =>
      gateway != null && pendingStore != null && collectionGateway != null;
  bool get unresolved =>
      intent != null && phase != BuyV2CollectionCheckoutPhase.paid;
  Uri? get paymentActionUri =>
      result?.state == BuyV2CollectionPurchaseState.actionRequired
      ? result?.paymentActionUri
      : null;

  bool _current(int epoch, BuyV2CollectionIdentity original) {
    final current = identity.value;
    return !_disposed &&
        _epoch == epoch &&
        current?.accountId == original.accountId &&
        current?.sessionId == original.sessionId;
  }

  void _identityChanged() {
    _epoch++;
    _busy = false;
    basket = null;
    quote = null;
    intent = null;
    result = null;
    paidOrder = null;
    message = null;
    phase = BuyV2CollectionCheckoutPhase.idle;
    _quoteElapsed.stop();
    if (!_disposed) notifyListeners();
  }

  void _begin() {
    _busy = true;
    phase = BuyV2CollectionCheckoutPhase.checking;
    message = null;
    notifyListeners();
  }

  void _unknown() {
    phase = BuyV2CollectionCheckoutPhase.pending;
    result = null;
    message = 'Payment needs checking. Do not pay again.';
  }

  void requireReconciliation() {
    if (_disposed || intent == null) return;
    paidOrder = null;
    _unknown();
    notifyListeners();
  }

  void _finish(int epoch, BuyV2CollectionIdentity original) {
    if (!_current(epoch, original)) return;
    _busy = false;
    notifyListeners();
  }

  /// An outstanding durable purchase takes precedence over the new basket.
  Future<bool> prepare(BuyV2CollectionBasket requested) async {
    if (_busy || _disposed) return false;
    final original = identity.value;
    if (original == null ||
        original.accountId != requested.identity.accountId ||
        original.sessionId != requested.identity.sessionId) {
      return false;
    }
    final epoch = _epoch;
    if (!available) {
      phase = BuyV2CollectionCheckoutPhase.blocked;
      message =
          'Store collection is unavailable right now. Your Cart has not changed.';
      notifyListeners();
      return false;
    }
    if (unresolved) return checkPayment();
    intent = null;
    basket = requested;
    quote = null;
    paidOrder = null;
    result = null;
    _begin();
    try {
      final retained = await pendingStore!
          .read(original.accountId)
          .timeout(timeout);
      if (!_current(epoch, original)) return false;
      if (retained != null) {
        if (retained.basket.identity.accountId != original.accountId) {
          throw const FormatException('Purchase account mismatch');
        }
        intent = retained;
        basket = retained.basket;
        quote = retained.quote;
        return await _reconcile(epoch, original);
      }
      if (!requested.collectionAvailableAt(now())) {
        phase = BuyV2CollectionCheckoutPhase.blocked;
        message = 'Check this store’s collection availability to continue.';
        return false;
      }
      final received = await gateway!.quote(requested).timeout(timeout);
      if (!_current(epoch, original)) return false;
      final receivedAt = now();
      if (!received.isCurrentFor(requested, receivedAt)) {
        throw const FormatException('Collection quote changed');
      }
      quote = received;
      _quoteReceivedAt = receivedAt;
      _quoteElapsed
        ..reset()
        ..start();
      phase = BuyV2CollectionCheckoutPhase.ready;
      return true;
    } on Object {
      if (_current(epoch, original)) {
        if (intent != null) {
          _unknown();
        } else {
          phase = BuyV2CollectionCheckoutPhase.blocked;
          message =
              'The collection total could not be checked. Your Cart has not changed.';
        }
      }
      return false;
    } finally {
      _finish(epoch, original);
    }
  }

  bool canPlace(BuyV2CollectionBasket currentBasket) {
    final received = quote;
    final receivedAt = _quoteReceivedAt;
    final current = identity.value;
    return !_busy &&
        !_disposed &&
        available &&
        !unresolved &&
        phase == BuyV2CollectionCheckoutPhase.ready &&
        received != null &&
        receivedAt != null &&
        current?.accountId == currentBasket.identity.accountId &&
        current?.sessionId == currentBasket.identity.sessionId &&
        received.isCurrentFor(currentBasket, now()) &&
        received.isCurrentFor(
          currentBasket,
          receivedAt.add(_quoteElapsed.elapsed),
        );
  }

  Future<bool> place(BuyV2CollectionBasket currentBasket) async {
    if (!canPlace(currentBasket)) return false;
    final original = identity.value!;
    final epoch = _epoch;
    final random = math.Random.secure();
    final operationId = base64Url.encode(
      List<int>.generate(24, (_) => random.nextInt(256)),
    );
    final reserved = BuyV2CollectionPurchaseIntent(
      operationId: operationId,
      basket: currentBasket,
      quote: quote!,
    );
    intent = reserved;
    _begin();
    try {
      final accepted = await pendingStore!.reserve(reserved).timeout(timeout);
      if (!_current(epoch, original)) return false;
      if (!accepted) {
        _unknown();
        return false;
      }
      if (!reserved.quote.isCurrentFor(reserved.basket, now()) ||
          !reserved.quote.isCurrentFor(
            reserved.basket,
            _quoteReceivedAt!.add(_quoteElapsed.elapsed),
          )) {
        _unknown();
        return false;
      }
      final received = await gateway!.place(reserved).timeout(timeout);
      if (!_current(epoch, original)) return false;
      return await _accept(received, epoch, original);
    } on Object {
      if (_current(epoch, original)) _unknown();
      return false;
    } finally {
      _finish(epoch, original);
    }
  }

  Future<bool> checkPayment() async {
    if (_busy || _disposed || !available) return false;
    final original = identity.value;
    if (original == null) return false;
    final epoch = _epoch;
    _begin();
    try {
      final retained = await pendingStore!
          .read(original.accountId)
          .timeout(timeout);
      if (!_current(epoch, original)) return false;
      if (retained == null ||
          retained.basket.identity.accountId != original.accountId) {
        _unknown();
        message = 'Check Orders for this payment. Do not pay again.';
        return false;
      }
      intent = retained;
      basket = retained.basket;
      quote = retained.quote;
      return await _reconcile(epoch, original);
    } on Object {
      if (_current(epoch, original)) _unknown();
      return false;
    } finally {
      _finish(epoch, original);
    }
  }

  Future<bool> _reconcile(int epoch, BuyV2CollectionIdentity original) async {
    final received = await gateway!.reconcile(intent!).timeout(timeout);
    if (!_current(epoch, original)) return false;
    return _accept(received, epoch, original);
  }

  Future<bool> _accept(
    BuyV2CollectionPurchaseResult received,
    int epoch,
    BuyV2CollectionIdentity original,
  ) async {
    final pending = intent!;
    if (!received.matches(pending)) {
      _unknown();
      return false;
    }
    result = received;
    if (received.state == BuyV2CollectionPurchaseState.paid) {
      final request = ScanPickRequest.read(
        requestId:
            '${pending.operationId}-${DateTime.now().microsecondsSinceEpoch}',
        orderId: received.orderId!,
        storeId: pending.basket.store.id,
      );
      final read = await collectionGateway!.execute(request).timeout(timeout);
      if (!_current(epoch, original)) return false;
      read.validateFor(
        request,
        client: ScanPickClient.consumer,
        purchaserAccountId: original.accountId,
      );
      final snapshot = read.snapshot;
      if (read.outcome != ScanPickOutcome.snapshot ||
          snapshot == null ||
          !received.matchesPaidOrder(pending, snapshot) ||
          acceptPaidOrder?.call(pending, snapshot) == false) {
        _unknown();
        return false;
      }
      final settled = await pendingStore!
          .settle(pending, received, paidOrder: snapshot)
          .timeout(timeout);
      if (!_current(epoch, original)) return false;
      if (!settled || acceptPaidOrder?.call(pending, snapshot) == false) {
        _unknown();
        return false;
      }
      paidOrder = snapshot;
      phase = BuyV2CollectionCheckoutPhase.paid;
      message = null;
      return true;
    }
    if (received.state == BuyV2CollectionPurchaseState.notCharged) {
      final settled = await pendingStore!
          .settle(pending, received)
          .timeout(timeout);
      if (!_current(epoch, original)) return false;
      if (!settled) {
        _unknown();
        return false;
      }
      intent = null;
      quote = null;
      phase = BuyV2CollectionCheckoutPhase.blocked;
      message = 'Payment was not taken. Review your order to try again.';
      return false;
    }
    phase = BuyV2CollectionCheckoutPhase.pending;
    message = received.state == BuyV2CollectionPurchaseState.actionRequired
        ? 'Complete payment to place this collection order.'
        : 'Payment needs checking. Do not pay again.';
    return false;
  }

  Future<bool> continuePayment(BuyV2PaymentHandoff handoff) async {
    final uri = paymentActionUri;
    final original = identity.value;
    if (_busy || _disposed || uri == null || original == null || !unresolved) {
      return false;
    }
    final epoch = _epoch;
    _begin();
    try {
      // Even an unsuccessful/uncertain app handoff keeps the same payment.
      await handoff(uri).timeout(timeout);
      if (!_current(epoch, original)) return false;
      return await _reconcile(epoch, original);
    } on Object {
      if (_current(epoch, original)) _unknown();
      return false;
    } finally {
      _finish(epoch, original);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    identity.removeListener(_identityChanged);
    _quoteElapsed.stop();
    super.dispose();
  }
}

class BuyV2Session extends ChangeNotifier {
  BuyV2Session({
    required this.core,
    this.productFactsAdapter = const BuyV2CatalogueProductFactsAdapter(),
    this.productContentAdapter = const BuyV2CatalogueProductContentAdapter(),
    this.marketplaceTrustAdapter =
        const BuyV2CatalogueMarketplaceTrustAdapter(),
    this.sponsoredContentAdapter = const BuyV2DisabledSponsoredContentAdapter(),
    BuyV2CartBenefitsAdapter? cartBenefitsAdapter,
    this.tipPolicy = const BuyV2DisabledTipPolicy(),
    this.savedProductsStore,
    BuyV2CustomerStateStore? customerStateStore,
    BuyV2GstInvoiceProfileStore? gstInvoiceProfileStore,
    this.commercialPaymentTermsAdapter,
    this.checkoutQuoteAdapter,
    this.balancePaymentAdapter,
    this.deliveryExceptionAdapter,
    this.liveDeliveryAdapter,
    this.collectionGateway,
    this.collectionIdentity,
    this.collectionPendingStore,
    this.collectionCheckoutGateway,
    this.collectionPurchaseStore,
    this.catalogueNow = DateTime.now,
    this.cataloguePageSource,
    this.publishedCatalogueSource,
    Map<String, String> catalogueAreas = const {},
    String? initialCatalogueRegionId,
    BuyV2OrderResolutionAdapter? orderResolutionAdapter,
    BuyV2ShoppingAlertsAdapter? shoppingAlertsAdapter,
    BuyV2CommerceAdapter? commerceAdapter,
    bool? reviewDataEnabled,
  }) : cartBenefitsAdapter =
           cartBenefitsAdapter ??
           (buyV2DeviceReviewBenefitSeedsEnabled
               ? const BuyV2SeededCartBenefitsAdapter()
               : const BuyV2DisabledCartBenefitsAdapter()),
       reviewDataEnabled =
           reviewDataEnabled ??
           (kDebugMode || buyV2DeviceReviewBenefitSeedsEnabled),
       customerStateStore =
           customerStateStore ??
           (buyV2DeviceReviewBenefitSeedsEnabled
               ? createBuyV2DeviceReviewCustomerStateStore()
               : null),
       gstInvoiceProfileStore =
           gstInvoiceProfileStore ??
           ((reviewDataEnabled ??
                   (kDebugMode || buyV2DeviceReviewBenefitSeedsEnabled))
               ? _BuyV2DeviceReviewGstInvoiceProfileStore()
               : null),
       commerceAdapter =
           commerceAdapter ??
           ((reviewDataEnabled ??
                   (kDebugMode || buyV2DeviceReviewBenefitSeedsEnabled))
               ? const _BuyV2DeviceReviewCommerceAdapter()
               : const _BuyV2UnavailableCommerceAdapter()),
       orderResolutionAdapter =
           orderResolutionAdapter ??
           ((reviewDataEnabled ??
                   (kDebugMode || buyV2DeviceReviewBenefitSeedsEnabled))
               ? const BuyV2UiReviewOrderResolutionAdapter()
               : const BuyV2UnavailableOrderResolutionAdapter()),
       shoppingAlertsAdapter =
           shoppingAlertsAdapter ??
           ((reviewDataEnabled ??
                   (kDebugMode || buyV2DeviceReviewBenefitSeedsEnabled))
               ? const BuyV2UiReviewShoppingAlertsAdapter()
               : const BuyV2UnavailableShoppingAlertsAdapter()) {
    collectionIdentity?.addListener(_onCollectionIdentityChanged);
    final buyerIdentity = collectionIdentity;
    if (buyerIdentity != null) {
      collectionCheckout = BuyV2CollectionCheckoutController(
        identity: buyerIdentity,
        gateway: collectionCheckoutGateway,
        pendingStore: collectionPurchaseStore,
        collectionGateway: collectionGateway,
        acceptPaidOrder: _canAdmitCollectionPurchase,
        now: catalogueNow,
      )..addListener(_onCollectionCheckoutChanged);
    }
    _catalogueAreas.addAll(catalogueAreas);
    _catalogueRegionId = initialCatalogueRegionId;
    if (cataloguePageSource == null && buyV2DeviceReviewBenefitSeedsEnabled) {
      for (final destination in [
        BuyV2Destination.shop,
        BuyV2Destination.wholesale,
      ]) {
        _deviceCatalogueSources[destination] = BuyV2DevelopmentCatalogueSource(
          destination: destination,
          now: catalogueNow,
        );
      }
      for (final area in BuyV2DevelopmentCatalogueSource.regions) {
        _catalogueAreas[area] = '${area[0].toUpperCase()}${area.substring(1)}';
      }
      // The review cohort is explicitly based in Jodhpur; this is not GPS.
      _catalogueRegionId ??= 'jodhpur';
      if (publishedCatalogueSource == null) {
        _devicePublishedCatalogueSource =
            BuyV2DevelopmentPublishedCatalogueSource(now: catalogueNow);
      }
    }
    if (cartBenefitsAdapter is BuyV2LiveCartBenefitsAdapter) {
      cartBenefitsLoadState = BuyV2CartBenefitsLoadState.idle;
    }
    _catalogueProducts.addAll(BuyV2Catalogue.allProducts);
    if (this.reviewDataEnabled) {
      _businessVerificationState = BuyV2BusinessVerificationState.verified;
      _productReportsAvailable = true;
      _reviewableProductIds.addAll(
        _orders
            .where((order) => order.status == BuyV2OrderStatus.delivered)
            .expand((order) => order.productIds),
      );
    }
    if (!this.reviewDataEnabled) {
      _catalogueProducts.clear();
      _addresses.clear();
      _orders.clear();
      _selectedAddressId = null;
      businessVerified = false;
      trackingAlertsEnabled = false;
      trackingAlertsAvailable = false;
      availablePaymentMethods = const {};
      commerceLoadState = BuyV2CommerceLoadState.loading;
    }
  }

  bool get pagedCatalogueEnabled =>
      cataloguePageSource != null ||
      _deviceCatalogueSources.containsKey(destination);

  BuyV2PublishedCatalogueSource? get _publishedCatalogueSource =>
      publishedCatalogueSource ?? _devicePublishedCatalogueSource;
  bool get pagedOffersEnabled => _publishedCatalogueSource != null;

  BuyV2CatalogueQuery catalogueOffersQuery({
    BuyV2OfferPublisherType? publisher,
    String categoryId = 'all',
  }) => BuyV2CatalogueQuery(
    destination: BuyV2Destination.shop,
    regionId: _catalogueRegionId,
    areaScope: _catalogueAreaScope,
    query: query,
    categoryId: categoryId,
    offersOnly: true,
    offerPublisher: publisher,
  );

  int get pagedProductCount => _pagedProducts.length;
  int get catalogueRequestsInFlight => _catalogueActiveRequests;

  final Map<String, String> _catalogueAreas = {};
  String? _catalogueRegionId;
  BuyV2CatalogueAreaScope _catalogueAreaScope =
      BuyV2CatalogueAreaScope.regional;
  Map<String, String> get catalogueAreaChoices =>
      Map.unmodifiable(_catalogueAreas);
  String? get catalogueRegionId => _catalogueRegionId;
  BuyV2CatalogueAreaScope get catalogueAreaScope => _catalogueAreaScope;
  String get catalogueAreaLabel =>
      _catalogueAreaScope == BuyV2CatalogueAreaScope.allAreas
      ? 'Any area'
      : _catalogueAreas[_catalogueRegionId] ?? 'Choose area';

  void chooseCatalogueArea(String? regionId, BuyV2CatalogueAreaScope scope) {
    if (scope != BuyV2CatalogueAreaScope.allAreas &&
        (regionId == null || !_catalogueAreas.containsKey(regionId))) {
      return;
    }
    if (_catalogueRegionId == regionId && _catalogueAreaScope == scope) return;
    _catalogueRegionId = regionId;
    _catalogueAreaScope = scope;
    notifyListeners();
  }

  BuyV2CatalogueQuery catalogueQuery({
    String? storeId,
    String? search,
    String? categoryId,
    bool offersOnly = false,
    bool collectionOnly = false,
    BuyV2Destination? catalogueDestination,
    BuyV2DiscoveryRefinements? refinements,
  }) {
    final value = catalogueDestination ?? destination;
    final storeCatalogue = storeId != null;
    final choices = refinements ?? discoveryRefinements;
    return BuyV2CatalogueQuery(
      destination: value,
      regionId: _catalogueRegionId,
      areaScope: storeCatalogue
          ? BuyV2CatalogueAreaScope.allAreas
          : _catalogueAreaScope,
      storeId: storeId,
      query: search ?? (storeCatalogue ? '' : query),
      categoryId: categoryId ?? (storeCatalogue ? 'all' : selectedCategoryId),
      sort: choices.sort,
      shopSaleType:
          !storeCatalogue && !collectionOnly && value == BuyV2Destination.shop
          ? shopSaleType
          : null,
      wholesaleSaleType: !storeCatalogue && value == BuyV2Destination.wholesale
          ? wholesaleSaleType
          : null,
      fulfilmentMode: storeCatalogue || collectionOnly
          ? null
          : choices.fulfilmentMode,
      pack: storeCatalogue ? null : choices.pack,
      filter: storeCatalogue ? null : choices.filter,
      brands: storeCatalogue ? const {} : choices.brands,
      maximumPrice: storeCatalogue ? null : choices.maximumPrice,
      availableOnly: !storeCatalogue && choices.availableOnly,
      offersOnly: offersOnly,
      collectionOnly: collectionOnly,
    );
  }

  BuyV2CataloguePageSource? _sourceForCatalogue(BuyV2Destination destination) =>
      cataloguePageSource ?? _deviceCatalogueSources[destination];

  Future<R> _withCatalogueRequest<R>(
    Future<R> Function() action, {
    bool Function()? isCurrent,
  }) async {
    if (_collectionDisposed) throw StateError('Buy session disposed');
    if (_catalogueActiveRequests >= 2) {
      final slot = Completer<void>();
      _catalogueRequestQueue.add(slot);
      await slot.future;
    } else {
      _catalogueActiveRequests += 1;
    }
    try {
      if (_collectionDisposed || (isCurrent != null && !isCurrent())) {
        throw StateError('Catalogue request is obsolete');
      }
      return await action();
    } finally {
      if (_catalogueRequestQueue.isEmpty) {
        _catalogueActiveRequests -= 1;
      } else {
        _catalogueRequestQueue.removeAt(0).complete();
      }
    }
  }

  void _validatePagedProduct(BuyV2Product product, BuyV2CatalogueQuery query) {
    final storeId = product.storeId;
    final previous = _pagedProducts[product.id];
    if (product.id.trim().isEmpty ||
        storeId == null ||
        storeId.trim().isEmpty ||
        storeId.trim() != storeId ||
        product.destination != query.destination ||
        (query.storeId != null && storeId != query.storeId) ||
        product.price <= 0 ||
        product.title.trim().isEmpty ||
        product.pack.trim().isEmpty ||
        product.minimumOrder < 1 ||
        (previous != null && previous.storeId != storeId)) {
      throw const FormatException('Catalogue listing identity mismatch');
    }
  }

  void _validateStore(BuyV2StoreListing store, BuyV2CatalogueQuery query) {
    if (store.id.trim().isEmpty ||
        store.id.trim() != store.id ||
        store.name.trim().isEmpty ||
        store.area.trim().isEmpty ||
        store.address.trim().isEmpty ||
        store.regionId.trim().isEmpty ||
        (query.storeId != null && store.id != query.storeId) ||
        (store.distanceMeters != null && store.distanceMeters! < 0) ||
        (store.collection != null && store.collection!.storeId != store.id)) {
      throw const FormatException('Catalogue Store identity mismatch');
    }
    final preview = store.previewProduct;
    if (preview != null) {
      _validatePagedProduct(preview, query);
      if (preview.storeId != store.id) {
        throw const FormatException('Store preview belongs to another branch');
      }
    }
  }

  BuyV2CataloguePager<BuyV2Product> acquireCatalogueProducts(String scopeKey) {
    final existing = _catalogueProductPagers.remove(scopeKey);
    if (existing != null) {
      existing.references += 1;
      existing.lastUsed = ++_catalogueUseSequence;
      _catalogueProductPagers[scopeKey] = existing;
      return existing.pager;
    }
    late final BuyV2CataloguePager<BuyV2Product> pager;
    pager = BuyV2CataloguePager<BuyV2Product>(
      identityOf: (product) => product.id,
      load: (query, {cursor, required pageSize}) => _withCatalogueRequest(
        () async {
          final source = _sourceForCatalogue(query.destination);
          if (source == null) throw StateError('Catalogue unavailable');
          final page = await source.loadProducts(
            query,
            cursor: cursor,
            pageSize: pageSize,
          );
          for (final product in page.items) {
            _validatePagedProduct(product, query);
          }
          return page;
        },
        isCurrent: () =>
            !pager.isDisposed &&
            pager.query == query &&
            pager.requestedCursor == cursor,
      ),
    );
    pager.addListener(_retainCataloguePages);
    _catalogueProductPagers[scopeKey] = _BuyV2PagerLease(pager)
      ..lastUsed = ++_catalogueUseSequence;
    return pager;
  }

  BuyV2CataloguePager<BuyV2StoreListing> acquireCatalogueStores(
    String scopeKey,
  ) {
    final existing = _catalogueStorePagers.remove(scopeKey);
    if (existing != null) {
      existing.references += 1;
      existing.lastUsed = ++_catalogueUseSequence;
      _catalogueStorePagers[scopeKey] = existing;
      return existing.pager;
    }
    late final BuyV2CataloguePager<BuyV2StoreListing> pager;
    pager = BuyV2CataloguePager<BuyV2StoreListing>(
      identityOf: (store) => store.id,
      load: (query, {cursor, required pageSize}) => _withCatalogueRequest(
        () async {
          final source = _sourceForCatalogue(query.destination);
          if (source == null) throw StateError('Store search unavailable');
          final page = await source.loadStores(
            query,
            cursor: cursor,
            pageSize: pageSize,
          );
          for (final store in page.items) {
            _validateStore(store, query);
          }
          return page;
        },
        isCurrent: () =>
            !pager.isDisposed &&
            pager.query == query &&
            pager.requestedCursor == cursor,
      ),
    );
    pager.addListener(_retainCataloguePages);
    _catalogueStorePagers[scopeKey] = _BuyV2PagerLease(pager)
      ..lastUsed = ++_catalogueUseSequence;
    return pager;
  }

  void releaseCatalogueProducts(String scopeKey) {
    final lease = _catalogueProductPagers.remove(scopeKey);
    if (lease != null) {
      if (lease.references > 0) lease.references -= 1;
      lease.lastUsed = ++_catalogueUseSequence;
      _catalogueProductPagers[scopeKey] = lease;
    }
    _trimCatalogueContexts();
  }

  BuyV2CataloguePager<BuyV2PublishedCatalogueOffer> acquireCatalogueOffers(
    String scopeKey,
  ) {
    final existing = _catalogueOfferPagers.remove(scopeKey);
    if (existing != null) {
      existing.references += 1;
      existing.lastUsed = ++_catalogueUseSequence;
      _catalogueOfferPagers[scopeKey] = existing;
      return existing.pager;
    }
    late final BuyV2CataloguePager<BuyV2PublishedCatalogueOffer> pager;
    pager = BuyV2CataloguePager<BuyV2PublishedCatalogueOffer>(
      identityOf: (offer) => offer.product.id,
      load: (query, {cursor, required pageSize}) => _withCatalogueRequest(
        () async {
          final source = _publishedCatalogueSource;
          if (source == null || !query.offersOnly) {
            throw StateError('Published offers unavailable');
          }
          final page = await source.loadOffers(
            query,
            cursor: cursor,
            pageSize: pageSize,
          );
          final publications = <String>{};
          for (final offer in page.items) {
            if (!offer.isCurrent(now: catalogueNow()) ||
                !publications.add(offer.publicationId) ||
                (query.offerPublisher != null &&
                    query.offerPublisher != offer.publisherType) ||
                pager.cachedItems.any(
                  (previous) =>
                      previous.publicationId == offer.publicationId &&
                      previous.product.id != offer.product.id,
                )) {
              throw const FormatException('Published offer facts do not match');
            }
            // Only the explicit publication feed permits mixed Shop/Wholesale
            // rows. Ordinary Store/product destination checks stay strict.
            _validatePagedProduct(
              offer.product,
              BuyV2CatalogueQuery(
                destination: offer.product.destination,
                regionId: query.regionId,
                storeId: query.storeId,
              ),
            );
          }
          return page;
        },
        isCurrent: () =>
            !pager.isDisposed &&
            pager.query == query &&
            pager.requestedCursor == cursor,
      ),
    );
    pager.addListener(_retainCataloguePages);
    _catalogueOfferPagers[scopeKey] = _BuyV2PagerLease(pager)
      ..lastUsed = ++_catalogueUseSequence;
    return pager;
  }

  void releaseCatalogueOffers(String scopeKey) {
    final lease = _catalogueOfferPagers.remove(scopeKey);
    if (lease != null) {
      if (lease.references > 0) lease.references -= 1;
      lease.lastUsed = ++_catalogueUseSequence;
      _catalogueOfferPagers[scopeKey] = lease;
    }
    _trimCatalogueContexts();
  }

  void releaseCatalogueStores(String scopeKey) {
    final lease = _catalogueStorePagers.remove(scopeKey);
    if (lease != null) {
      if (lease.references > 0) lease.references -= 1;
      lease.lastUsed = ++_catalogueUseSequence;
      _catalogueStorePagers[scopeKey] = lease;
    }
    _trimCatalogueContexts();
  }

  void _trimCatalogueContexts() {
    // Keep four inactive query contexts for product/Store/Back continuity.
    // Mounted surfaces retain their own three-page window.
    while (_catalogueProductPagers.values
                .where((v) => v.references == 0)
                .length +
            _catalogueStorePagers.values
                .where((v) => v.references == 0)
                .length +
            _catalogueOfferPagers.values
                .where((v) => v.references == 0)
                .length >
        4) {
      final product = _catalogueProductPagers.entries
          .where((entry) => entry.value.references == 0)
          .firstOrNull;
      final store = _catalogueStorePagers.entries
          .where((entry) => entry.value.references == 0)
          .firstOrNull;
      final offer = _catalogueOfferPagers.entries
          .where((entry) => entry.value.references == 0)
          .firstOrNull;
      if (offer != null &&
          (product == null || offer.value.lastUsed < product.value.lastUsed) &&
          (store == null || offer.value.lastUsed < store.value.lastUsed)) {
        _catalogueOfferPagers.remove(offer.key)?.pager.dispose();
      } else if (product != null &&
          (store == null || product.value.lastUsed < store.value.lastUsed)) {
        _catalogueProductPagers.remove(product.key)?.pager.dispose();
      } else {
        _catalogueStorePagers.remove(store!.key)?.pager.dispose();
      }
    }
    _retainCataloguePages(notify: false);
  }

  void _rememberPagedStore(BuyV2StoreListing store) {
    _pagedStores[store.id] = store;
    final preview = store.previewProduct;
    if (preview != null) _pagedProducts[preview.id] = preview;
    // The new Store capability replaces its earlier one, including withdrawal.
    _productFacts.removeWhere(
      (id, facts) => _pagedProducts[id]?.storeId == store.id,
    );
  }

  void _retainCataloguePages({bool notify = true}) {
    if (_collectionDisposed) return;
    for (final lease in _catalogueOfferPagers.values) {
      for (final offer in lease.pager.cachedItems) {
        _pagedProducts[offer.product.id] = offer.product;
      }
    }
    for (final lease in _catalogueProductPagers.values) {
      for (final product in lease.pager.cachedItems) {
        _pagedProducts[product.id] = product;
      }
    }
    final storeIds = <String>{};
    for (final lease in _catalogueStorePagers.values) {
      for (final store in lease.pager.cachedItems) {
        storeIds.add(store.id);
        if (_admittedStoreListings[store] != true) {
          _admittedStoreListings[store] = true;
          _rememberPagedStore(store);
        }
      }
    }
    final retained = <String>{
      ..._cart.keys,
      ..._recentlyViewedProductIds,
      ..._comparedProductOrigins,
      ...?_cartProductReturnOrigin?.comparisons,
      ?selectedProductId,
      ?_cartProductReturnId,
      ?_accountReturnProductId,
      ?_pendingStoreReturnAnchorId,
      ..._catalogueStoreBrowseAnchors.values,
      for (final lease in _catalogueOfferPagers.values)
        for (final offer in lease.pager.cachedItems) offer.product.id,
      for (final lease in _catalogueProductPagers.values)
        for (final product in lease.pager.cachedItems) product.id,
      for (final store in _pagedStores.values)
        if (storeIds.contains(store.id) && store.previewProduct != null)
          store.previewProduct!.id,
      for (final product in _pagedProducts.values)
        if (_savedKeys.contains(_buyV2SavedKey(product))) product.id,
    };
    _pagedProducts.removeWhere((id, _) => !retained.contains(id));
    storeIds.addAll(
      _pagedProducts.values.map((product) => product.storeId!).toSet(),
    );
    _pagedStores.removeWhere((id, _) => !storeIds.contains(id));
    retained.addAll(_catalogueProducts.map((product) => product.id));
    _productFacts.removeWhere((id, _) => !retained.contains(id));
    _productContent.removeWhere((id, _) => !retained.contains(id));
    _marketplaceTrust.removeWhere((id, _) => !retained.contains(id));
    _productBenefits.removeWhere((id, _) => !retained.contains(id));
    _productBenefitStates.removeWhere((id, _) => !retained.contains(id));
    _productBenefitMessages.removeWhere((id, _) => !retained.contains(id));
    _productBenefitRequestSequences.removeWhere(
      (id, _) => !retained.contains(id),
    );
    if (notify) notifyListeners();
  }

  BuyV2StoreListing? catalogueStore(String storeId) => _pagedStores[storeId];

  BuyV2CatalogueQuery? retainedCatalogueQuery(String scopeKey) =>
      _catalogueProductPagers[scopeKey]?.pager.query;

  BuyV2CatalogueQuery? retainedCatalogueOffersQuery(String scopeKey) =>
      _catalogueOfferPagers[scopeKey]?.pager.query;

  final Map<BuyV2Destination, String> _catalogueStoreBrowseAnchors = {};

  /// One public Store return anchor per destination, independent of page LRU.
  void retainCatalogueStoreBrowse(BuyV2Product product) {
    if (_collectionDisposed ||
        !pagedCatalogueEnabled ||
        product.storeId == null) {
      return;
    }
    _validatePagedProduct(
      product,
      catalogueQuery(
        storeId: product.storeId,
        catalogueDestination: product.destination,
      ),
    );
    _pagedProducts.putIfAbsent(product.id, () => product);
    _catalogueStoreBrowseAnchors[product.destination] = product.id;
    _retainCataloguePages(notify: false);
  }

  Future<BuyV2StoreListing?> refreshCatalogueStore(
    String storeId,
    BuyV2Destination destination,
  ) {
    return _storeLookups.putIfAbsent(
      storeId,
      () =>
          _withCatalogueRequest<BuyV2StoreListing?>(() async {
                final source = _sourceForCatalogue(destination);
                if (source == null) throw StateError('Store unavailable');
                final query = BuyV2CatalogueQuery(
                  destination: destination,
                  regionId: null,
                  storeId: storeId,
                  areaScope: BuyV2CatalogueAreaScope.allAreas,
                );
                final page = await source.loadStores(query, pageSize: 1);
                if (_collectionDisposed) return null;
                if (page.queryKey != query.key ||
                    page.items.length != 1 ||
                    page.startIndex != 0 ||
                    page.snapshotId.trim().isEmpty ||
                    page.previousCursor != null ||
                    page.nextCursor != null ||
                    (page.totalCount != null && page.totalCount != 1)) {
                  throw const FormatException(
                    'Exact Store response could not be verified',
                  );
                }
                final store = page.items.single;
                _validateStore(store, query);
                _rememberPagedStore(store);
                notifyListeners();
                return store;
              })
              .catchError((Object _) {
                if (_collectionDisposed) return null;
                final previous = _pagedStores[storeId];
                if (previous != null) {
                  _rememberPagedStore(
                    BuyV2StoreListing(
                      id: previous.id,
                      name: previous.name,
                      area: previous.area,
                      address: previous.address,
                      regionId: previous.regionId,
                      distanceMeters: previous.distanceMeters,
                      previewProduct: previous.previewProduct,
                    ),
                  );
                }
                notifyListeners();
                return null;
              })
              .whenComplete(() {
                _storeLookups.remove(storeId);
              }),
    );
  }

  void _onCollectionIdentityChanged() {
    // Public fulfilment/branch choices must not silently become delivery when
    // authentication changes. The checkout controller clears payment authority.
    if (view != BuyV2View.checkout) {
      _collectionCheckoutSelected = false;
      _collectionCheckoutStoreId = null;
    }
    _collectionEpoch++;
    for (final state in _collectionStates.values) {
      state.elapsed.stop();
    }
    _collectionStates.clear();
    if (_collectionDisposed) return;
    notifyListeners();
    final order = selectedOrderOrNull;
    if (view == BuyV2View.tracking && order?.collection != null) {
      unawaited(refreshCollectionOrder(order!.id));
    }
  }

  @override
  void dispose() {
    _collectionDisposed = true;
    _collectionEpoch++;
    collectionCheckout?.removeListener(_onCollectionCheckoutChanged);
    collectionCheckout?.dispose();
    collectionIdentity?.removeListener(_onCollectionIdentityChanged);
    for (final state in _collectionStates.values) {
      state.elapsed.stop();
    }
    for (final lease in _catalogueProductPagers.values) {
      lease.pager.dispose();
    }
    for (final lease in _catalogueStorePagers.values) {
      lease.pager.dispose();
    }
    for (final lease in _catalogueOfferPagers.values) {
      lease.pager.dispose();
    }
    super.dispose();
  }

  bool collectionOrderBelongsToCurrentAccount(BuyV2Order order) {
    final reference = order.collection;
    final identity = collectionIdentity?.value;
    return reference != null &&
        identity != null &&
        identity.accountId.trim().isNotEmpty &&
        identity.sessionId.trim().isNotEmpty &&
        reference.storeId.trim().isNotEmpty &&
        reference.purchaserAccountId == identity.accountId;
  }

  _BuyV2CollectionContext? _collectionContext(String orderId) {
    final order = _orders.where((value) => value.id == orderId).firstOrNull;
    if (_collectionDisposed ||
        order == null ||
        view != BuyV2View.tracking ||
        selectedOrderId != orderId ||
        !collectionOrderBelongsToCurrentAccount(order)) {
      return null;
    }
    return (
      order: order,
      identity: collectionIdentity!.value!,
      epoch: _collectionEpoch,
      navigation: _navigationMotionSequence,
    );
  }

  bool _collectionContextIsCurrent(_BuyV2CollectionContext context) {
    final current = _collectionContext(context.order.id);
    return current != null &&
        identical(current.order, context.order) &&
        identical(current.identity, context.identity) &&
        current.epoch == context.epoch &&
        current.navigation == context.navigation;
  }

  _BuyV2CollectionState? _collectionStateFor(String orderId) {
    final order = _orders.where((value) => value.id == orderId).firstOrNull;
    if (order == null || !collectionOrderBelongsToCurrentAccount(order)) {
      return null;
    }
    final state = _collectionStates[orderId];
    final snapshot = state?.snapshot;
    if (snapshot != null &&
        (snapshot.storeId != order.collection!.storeId ||
            snapshot.purchaserAccountId !=
                order.collection!.purchaserAccountId)) {
      return null;
    }
    return state;
  }

  ScanPickSnapshot? collectionSnapshotFor(String orderId) =>
      _collectionStateFor(orderId)?.snapshot;

  bool collectionBusy(String orderId) =>
      _collectionStateFor(orderId)?.busy ?? false;

  bool collectionReconciliationPending(String orderId) =>
      _collectionStateFor(orderId)?.pending ?? false;

  String? collectionMessageFor(String orderId) {
    final state = _collectionStateFor(orderId);
    if (state == null) return null;
    if (state.message != null) return state.message;
    if (state.scanMessage != null) return state.scanMessage;
    final snapshot = state.snapshot;
    if (snapshot == null ||
        snapshot.state == ScanPickState.collected ||
        snapshot.state == ScanPickState.cancelled) {
      return null;
    }
    if (snapshot.payment != ScanPickPayment.paid) {
      return 'Payment needs checking before collection.';
    }
    if (snapshot.state == ScanPickState.ready ||
        (snapshot.state == ScanPickState.awaitingCustomer &&
            snapshot.challenge == null)) {
      return 'Waiting for the store’s QR. This order updates automatically.';
    }
    if (snapshot.state == ScanPickState.awaitingCustomer &&
        !snapshot.serverTime
            .add(state.elapsed.elapsed)
            .isBefore(snapshot.challenge!.expiresAt)) {
      return 'Ask the store to refresh this order’s QR. We’ll check again automatically.';
    }
    return null;
  }

  bool canScanCollection(String orderId) {
    final context = _collectionContext(orderId);
    final state = _collectionStateFor(orderId);
    final snapshot = state?.snapshot;
    if (context == null ||
        collectionGateway == null ||
        collectionPendingStore == null ||
        state == null ||
        state.busy ||
        state.pending ||
        state.refreshRequired ||
        state.navigation != context.navigation ||
        state.elapsed.elapsed >= const Duration(seconds: 30) ||
        snapshot == null ||
        snapshot.state != ScanPickState.awaitingCustomer ||
        snapshot.payment != ScanPickPayment.paid ||
        snapshot.readiness != ScanPickReadiness.ready) {
      return false;
    }
    final challenge = snapshot.challenge;
    return challenge != null &&
        snapshot.serverTime
            .add(state.elapsed.elapsed)
            .isBefore(challenge.expiresAt);
  }

  String collectionStatusLabelFor(String orderId) {
    final state = _collectionStateFor(orderId);
    if (state == null) return 'Collection unavailable';
    if (state.pending) return 'Checking collection';
    final snapshot = state.snapshot;
    if (snapshot == null) {
      return state.busy ? 'Checking order' : 'Check collection';
    }
    if (snapshot.state == ScanPickState.collected) return 'Collected';
    final approvalExpired =
        snapshot.state == ScanPickState.matched &&
        !snapshot.serverTime
            .add(state.elapsed.elapsed)
            .isBefore(snapshot.approval!.expiresAt);
    if (state.refreshRequired ||
        approvalExpired ||
        state.elapsed.elapsed >= const Duration(seconds: 30)) {
      return 'Updating collection';
    }
    return switch (snapshot.state) {
      ScanPickState.preparing => 'Preparing your order',
      ScanPickState.ready || ScanPickState.awaitingCustomer => 'Ready at store',
      ScanPickState.matched => 'Matched · awaiting handover',
      ScanPickState.collected => 'Collected',
      ScanPickState.cancelled => 'Collection cancelled',
    };
  }

  bool orderIsCompleted(BuyV2Order order) => order.collection == null
      ? order.status == BuyV2OrderStatus.delivered
      : collectionSnapshotFor(order.id)?.state == ScanPickState.collected &&
            collectionSnapshotFor(order.id)?.receipt != null;

  /// Called when the order view loses the foreground. An in-flight scan keeps
  /// its durable intent, but its eventual reply cannot update a resumed view.
  void pauseCollection({bool notify = true}) {
    _collectionEpoch++;
    for (final state in _collectionStates.values) {
      state.attempt++;
      state.busy = false;
      state.refreshRequired = true;
    }
    if (notify && !_collectionDisposed) notifyListeners();
  }

  Future<bool> refreshCollectionOrder(String orderId) =>
      _runCollection(orderId);

  Future<bool> authoriseCollection(String orderId, String qrPayload) =>
      _runCollection(orderId, qrPayload: qrPayload);

  String _newCollectionRequestId() {
    final random = math.Random.secure();
    return List.generate(
      24,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  bool _validCollectionIntent(
    BuyV2CollectionPendingIntent intent,
    _BuyV2CollectionContext context,
  ) =>
      intent.accountId == context.identity.accountId &&
      intent.orderId == context.order.id &&
      intent.storeId == context.order.collection!.storeId &&
      intent.operationId.trim().isNotEmpty &&
      RegExp(r'^[a-f0-9]{64}$').hasMatch(intent.requestFingerprint);

  Future<bool> _runCollection(String orderId, {String? qrPayload}) async {
    final context = _collectionContext(orderId);
    if (context == null) return false;
    final state = _collectionStates.putIfAbsent(
      orderId,
      _BuyV2CollectionState.new,
    );
    if (state.busy) return false;
    final gateway = collectionGateway;
    final pendingStore = collectionPendingStore;
    if (gateway == null || pendingStore == null) {
      state.refreshRequired = true;
      state.message =
          'Collection is unavailable here. Open Order help for this order.';
      notifyListeners();
      return false;
    }
    if (qrPayload != null && !canScanCollection(orderId)) return false;
    final revision = state.snapshot?.revision;
    state.busy = true;
    state.refreshRequired = true;
    final attempt = ++state.attempt;
    if (qrPayload != null) {
      state.scanMessage = null;
      state.message = 'Checking this order…';
    }
    notifyListeners();
    BuyV2CollectionPendingIntent? intent;
    try {
      // The durable adapter serializes reads after earlier reservations. The
      // transport is never called until a reservation has completed durably.
      intent = await pendingStore
          .read(
            accountId: context.identity.accountId,
            orderId: orderId,
            storeId: context.order.collection!.storeId,
          )
          .timeout(const Duration(seconds: 15));
      if (!_collectionContextIsCurrent(context)) return false;
      final original = state.pendingIntent;
      if (intent != null &&
          original != null &&
          (intent.operationId != original.operationId ||
              intent.requestFingerprint != original.requestFingerprint)) {
        state.pending = true;
        state.message = 'The earlier scan needs recovery on this order.';
        return false;
      }
      // A missing cache entry cannot settle a request already sent by this
      // session. Reconcile its original operation even if storage was lost.
      intent ??= state.pendingIntent;
      if (intent != null && !_validCollectionIntent(intent, context)) {
        state.pending = true;
        state.message = 'The earlier scan needs recovery on this order.';
        return false;
      }
      ScanPickRequest request;
      if (intent != null) {
        state.pending = true;
        request = ScanPickRequest.reconcile(
          requestId: _newCollectionRequestId(),
          operationId: intent.operationId,
          orderId: orderId,
          storeId: context.order.collection!.storeId,
        );
      } else if (qrPayload != null) {
        // Shared constructor validates the unmodified payload before any write.
        request = ScanPickRequest.authorise(
          requestId: _newCollectionRequestId(),
          operationId: _newCollectionRequestId(),
          orderId: orderId,
          storeId: context.order.collection!.storeId,
          expectedRevision: revision!,
          qrPayload: qrPayload,
        );
        intent = BuyV2CollectionPendingIntent(
          accountId: context.identity.accountId,
          orderId: orderId,
          storeId: context.order.collection!.storeId,
          operationId: request.operationId!,
          requestFingerprint: sha256
              .convert(
                utf8.encode(
                  jsonEncode([
                    context.identity.accountId,
                    request.orderId,
                    request.storeId,
                    request.expectedRevision,
                    qrPayload,
                  ]),
                ),
              )
              .toString(),
        );
        state.pending = true;
        final reserved = await pendingStore
            .reserve(intent)
            .timeout(const Duration(seconds: 15));
        if (!_collectionContextIsCurrent(context)) return false;
        if (!reserved) {
          state.message = 'An earlier scan is being checked on this order.';
          return false;
        }
      } else {
        state.pending = false;
        request = ScanPickRequest.read(
          requestId: _newCollectionRequestId(),
          orderId: orderId,
          storeId: context.order.collection!.storeId,
        );
      }
      if (intent != null) state.pendingIntent = intent;
      final result = await gateway
          .execute(request)
          .timeout(const Duration(seconds: 15));
      if (!_collectionContextIsCurrent(context)) return false;
      result.validateFor(
        request,
        client: ScanPickClient.consumer,
        purchaserAccountId: context.identity.accountId,
      );
      final uncertain =
          result.outcome == ScanPickOutcome.unknown ||
          (result.outcome == ScanPickOutcome.rejected &&
              const {
                ScanPickError.operationInProgress,
                ScanPickError.operationConflict,
                ScanPickError.unavailable,
                ScanPickError.rateLimited,
                ScanPickError.unauthenticated,
                ScanPickError.forbidden,
                ScanPickError.wrongPurchaser,
              }.contains(result.error));
      if (uncertain) {
        state.pending = intent != null;
        state.message = intent == null
            ? 'Order status could not refresh. We’ll check again automatically.'
            : 'Checking your earlier scan. Keep this order open.';
        return false;
      }
      if (intent != null) {
        final cleared = await pendingStore
            .clear(intent)
            .timeout(const Duration(seconds: 15));
        if (!_collectionContextIsCurrent(context)) return false;
        if (!cleared) {
          state.pending = true;
          state.message = 'Finishing the earlier scan check on this order.';
          return false;
        }
      }
      state.pending = false;
      state.pendingIntent = null;
      final accepted =
          result.outcome == ScanPickOutcome.snapshot ||
          (result.error == ScanPickError.alreadyCollected &&
              result.snapshot?.state == ScanPickState.collected);
      if (!accepted) {
        state.scanMessageState = state.snapshot?.state;
        state.scanMessageChallenge = state.snapshot?.challenge?.id;
        state.snapshot = null;
        state.scanMessage = switch (result.error) {
          ScanPickError.wrongOrder || ScanPickError.wrongStore =>
            'Use the QR for this order at the correct store.',
          ScanPickError.challengeExpired ||
          ScanPickError.challengeInvalid ||
          ScanPickError.challengeConsumed =>
            'Ask the store to refresh this order’s QR, then scan again.',
          ScanPickError.notReady => 'The store is still preparing this order.',
          ScanPickError.paymentRequired || ScanPickError.paymentChanged =>
            'Payment needs checking before collection.',
          ScanPickError.cancelled => 'This collection has been cancelled.',
          _ => 'Order status changed. Checking the latest details here.',
        };
        state.message = null;
        return false;
      }
      state.snapshot = result.snapshot!;
      state.elapsed
        ..reset()
        ..start();
      state.navigation = context.navigation;
      state.refreshRequired = false;
      state.message = null;
      if (state.snapshot!.state != state.scanMessageState ||
          state.snapshot!.challenge?.id != state.scanMessageChallenge ||
          state.snapshot!.state == ScanPickState.matched ||
          state.snapshot!.state == ScanPickState.collected ||
          state.snapshot!.state == ScanPickState.cancelled) {
        state.scanMessage = null;
      }
      return true;
    } on Object {
      if (!_collectionContextIsCurrent(context)) return false;
      state.pending = intent != null || state.pending;
      state.message = state.pending
          ? 'The scan result is uncertain. Checking this same order safely.'
          : 'Collection could not refresh. We’ll check again automatically.';
      return false;
    } finally {
      if (state.attempt == attempt) state.busy = false;
      if (!_collectionDisposed &&
          identical(_collectionStates[orderId], state)) {
        notifyListeners();
      }
    }
  }

  final BuySession core;
  final BuyV2ProductFactsAdapter productFactsAdapter;
  final BuyV2ProductContentAdapter productContentAdapter;
  final BuyV2MarketplaceTrustAdapter marketplaceTrustAdapter;
  final BuyV2SponsoredContentAdapter sponsoredContentAdapter;
  final BuyV2CartBenefitsAdapter cartBenefitsAdapter;
  final BuyV2TipPolicy tipPolicy;
  final BuyV2SavedProductsStore? savedProductsStore;
  final BuyV2CustomerStateStore? customerStateStore;
  final BuyV2GstInvoiceProfileStore? gstInvoiceProfileStore;
  final BuyV2CommercialPaymentTermsAdapter? commercialPaymentTermsAdapter;
  final BuyV2CheckoutQuoteAdapter? checkoutQuoteAdapter;
  final BuyV2BalancePaymentAdapter? balancePaymentAdapter;
  final BuyV2DeliveryExceptionAdapter? deliveryExceptionAdapter;
  final BuyV2LiveDeliveryAdapter? liveDeliveryAdapter;
  final ScanPickGateway? collectionGateway;
  final ValueListenable<BuyV2CollectionIdentity?>? collectionIdentity;
  final BuyV2CollectionPendingStore? collectionPendingStore;
  final BuyV2CollectionCheckoutGateway? collectionCheckoutGateway;
  final BuyV2CollectionPurchaseStore? collectionPurchaseStore;
  BuyV2CollectionCheckoutController? collectionCheckout;
  bool _collectionCheckoutSelected = false;
  String? _collectionCheckoutStoreId;
  final DateTime Function() catalogueNow;
  final BuyV2CataloguePageSource? cataloguePageSource;
  final BuyV2PublishedCatalogueSource? publishedCatalogueSource;
  BuyV2PublishedCatalogueSource? _devicePublishedCatalogueSource;
  final Map<BuyV2Destination, BuyV2CataloguePageSource>
  _deviceCatalogueSources = {};
  final Map<String, _BuyV2PagerLease<BuyV2Product>> _catalogueProductPagers =
      {};
  final Map<String, _BuyV2PagerLease<BuyV2StoreListing>> _catalogueStorePagers =
      {};
  final Map<String, _BuyV2PagerLease<BuyV2PublishedCatalogueOffer>>
  _catalogueOfferPagers = {};
  final Map<String, BuyV2Product> _pagedProducts = {};
  final Map<String, BuyV2StoreListing> _pagedStores = {};
  final Expando<bool> _admittedStoreListings = Expando<bool>();
  final Map<String, Future<BuyV2StoreListing?>> _storeLookups = {};
  final List<Completer<void>> _catalogueRequestQueue = [];
  int _catalogueActiveRequests = 0;
  int _catalogueUseSequence = 0;
  final Map<String, _BuyV2CollectionState> _collectionStates = {};
  int _collectionEpoch = 0;
  bool _collectionDisposed = false;
  final BuyV2OrderResolutionAdapter orderResolutionAdapter;
  final BuyV2ShoppingAlertsAdapter shoppingAlertsAdapter;
  final BuyV2CommerceAdapter commerceAdapter;
  final bool reviewDataEnabled;

  static const bool sponsoredContentActivationApproved = false;
  static const BuyV2CatalogueProductFactsAdapter _catalogueFactsFallback =
      BuyV2CatalogueProductFactsAdapter();
  static const BuyV2CatalogueProductContentAdapter _catalogueContentFallback =
      BuyV2CatalogueProductContentAdapter();
  static const BuyV2CatalogueMarketplaceTrustAdapter _catalogueTrustFallback =
      BuyV2CatalogueMarketplaceTrustAdapter();

  static const Set<String> paymentMethods = {
    'PhonePe',
    'Paytm',
    'Pine Labs',
    'Cash on Delivery',
    'Purchase order',
  };

  BuyV2CommerceLoadState commerceLoadState = BuyV2CommerceLoadState.ready;
  BuyV2CheckoutSubmissionState checkoutSubmissionState =
      BuyV2CheckoutSubmissionState.idle;
  Set<String> availablePaymentMethods = paymentMethods;
  String? commerceMessage;
  String? _checkoutIdempotencyKey;
  String? _paymentReference;
  Uri? _paymentActionUri;
  BuyV2BankTransferInstructions? _bankTransferInstructions;
  int _checkoutAttemptSequence = 0;

  String? get checkoutIdempotencyKey => _checkoutIdempotencyKey;
  String? get paymentReference => _paymentReference;
  Uri? get paymentActionUri => _paymentActionUri;
  BuyV2BankTransferInstructions? get bankTransferInstructions =>
      _bankTransferInstructions;

  bool get catalogueAvailable =>
      commerceLoadState == BuyV2CommerceLoadState.ready;

  bool canReviewProduct(String productId) =>
      _reviewableProductIds.contains(productId);

  bool canReportProduct(String productId) =>
      findProduct(productId) != null && _productReportsAvailable;

  bool productFeedbackBusy(String productId) =>
      _productFeedbackBusyIds.contains(productId);

  bool get addressRequestsAvailable => reviewDataEnabled;

  bool get checkoutBusy =>
      (collectionCheckout?.busy ?? false) ||
      checkoutSubmissionState == BuyV2CheckoutSubmissionState.submitting;

  bool get checkoutRequiresResolution =>
      (collectionCheckout?.unresolved ?? false) ||
      checkoutSubmissionState ==
          BuyV2CheckoutSubmissionState.paymentActionRequired ||
      checkoutSubmissionState == BuyV2CheckoutSubmissionState.paymentPending ||
      checkoutSubmissionState == BuyV2CheckoutSubmissionState.paymentUnknown;

  bool get checkoutBenefitReviewRequired =>
      liveCartBenefitsEnabled &&
      _hasSelectedCartBenefitReference &&
      cartBenefitsLoadState != BuyV2CartBenefitsLoadState.ready;

  BuyV2Destination destination = BuyV2Destination.shop;
  BuyV2View view = BuyV2View.catalogue;
  BuyV2CheckoutStep checkoutStep = BuyV2CheckoutStep.address;
  BuyV2CartScope cartScope = BuyV2CartScope.all;
  BuyV2CartScope checkoutScope = BuyV2CartScope.all;
  BuyV2OrdersTab ordersTab = BuyV2OrdersTab.active;
  String shopCategoryId = 'all';
  String wholesaleCategoryId = 'all';
  String medicineCategoryId = 'all';
  BuyV2Destination? _savedCatalogueDestination;
  bool get showingSavedProducts => _savedCatalogueDestination == destination;
  String query = '';
  String? selectedProductId;
  String? _pendingStoreReturnAnchorId;
  String? pendingPrescriptionProductId;
  BuyV2RecoveryKind? recoveryKind;
  _BuyV2RecoveryOrigin? _recoveryOrigin;
  ({
    Object token,
    BuyV2ShoppingAlert alert,
    VoidCallback returnToAlerts,
    VoidCallback restoreOrigin,
  })?
  _shoppingAlertVisit;
  bool _shoppingAlertReturnRequested = false;
  String? notice;
  String? cartAcknowledgement;
  BuyV2Destination? _cartAcknowledgementDestination;

  String? cartAcknowledgementForDestination(BuyV2Destination value) =>
      _cartAcknowledgementDestination == value ? cartAcknowledgement : null;

  String? selectedFilter;
  final Set<String> _selectedBrands = {};
  Set<String> get selectedBrands => Set.unmodifiable(_selectedBrands);
  int? maximumProductPrice;
  BuyV2PackFilter? selectedPackFilter;
  BuyV2FulfilmentMode? selectedFulfilmentMode;
  BuyV2ShopSaleType _shopSaleType = BuyV2ShopSaleType.quickDelivery;
  BuyV2WholesaleSaleType _wholesaleSaleType = BuyV2WholesaleSaleType.wholesale;
  BuyV2ProductSort productSort = BuyV2ProductSort.relevance;
  bool availableProductsOnly = false;
  BuyV2ShoppingIntent? activeShoppingIntent;
  bool businessVerified = true;
  BuyV2BusinessVerificationState _businessVerificationState =
      BuyV2BusinessVerificationState.unavailable;
  BuyV2BusinessVerificationState get businessVerificationState {
    if (businessVerified) return BuyV2BusinessVerificationState.verified;
    return _businessVerificationState == BuyV2BusinessVerificationState.verified
        ? BuyV2BusinessVerificationState.unavailable
        : _businessVerificationState;
  }

  bool prescriptionAttached = false;
  bool trackingAlertsEnabled = true;
  bool trackingAlertsAvailable = true;
  bool trackingAlertsBusy = false;
  String selectedPayment = 'PhonePe';
  String purchaseOrderReference = '';

  bool get purchaseOrderEligibleForCheckout {
    final lines = checkoutLines;
    return businessVerified &&
        lines.isNotEmpty &&
        lines.every(
          (line) => line.product.destination == BuyV2Destination.wholesale,
        );
  }

  bool get purchaseOrderDetailsComplete =>
      purchaseOrderReference.trim().length >= 3;

  bool get cashOnDeliveryEligibleForCheckout {
    final lines = checkoutLines;
    return lines.isNotEmpty &&
        lines.every(
          (line) => line.product.destination == BuyV2Destination.shop,
        ) &&
        checkoutAmountDueNow <= 5000;
  }

  static const purchaseOrderEligibilityMessage =
      'Purchase order requires a confirmed business account and a wholesale-only basket.';
  static const purchaseOrderDetailsMessage =
      'Enter the purchase order reference used by your business.';
  static const cashOnDeliveryEligibilityMessage =
      'Cash on Delivery is available for eligible Shop orders up to ₹5,000.';

  int _navigationMotionSequence = 0;
  BuyV2NavigationMotionDirection _navigationMotionDirection =
      BuyV2NavigationMotionDirection.replace;
  bool _handlingBackNavigation = false;

  int get navigationMotionSequence => _navigationMotionSequence;
  BuyV2NavigationMotionDirection get navigationMotionDirection =>
      _navigationMotionDirection;

  BuyV2Destination get activeDockDestination => switch (view) {
    BuyV2View.cart => _dockDestinationForScope(cartScope),
    BuyV2View.checkout => _dockDestinationForScope(checkoutScope),
    _ => destination,
  };

  BuyV2Destination _dockDestinationForScope(BuyV2CartScope scope) =>
      switch (scope) {
        BuyV2CartScope.shop => BuyV2Destination.shop,
        BuyV2CartScope.wholesale => BuyV2Destination.wholesale,
        BuyV2CartScope.medicine => BuyV2Destination.medicine,
        BuyV2CartScope.all => destination,
      };

  String get recoveryReturnLabel {
    final origin = _recoveryOrigin;
    if (origin == null) return 'Return to Shop';
    return switch (origin.view) {
      BuyV2View.catalogue => 'Return to ${origin.destination.label}',
      BuyV2View.product => 'Return to product',
      BuyV2View.cart => 'Return to Cart',
      BuyV2View.checkout => 'Return to Checkout',
      BuyV2View.confirmation => 'Return to confirmation',
      BuyV2View.tracking || BuyV2View.orderItems => 'Return to order',
      BuyV2View.assist => 'Return to Help',
      BuyV2View.account => 'Return to Account',
      BuyV2View.recovery => 'Return to Shop',
    };
  }

  bool get canOpenRecoveryOrderHelp {
    final origin = _recoveryOrigin;
    if (recoveryKind != BuyV2RecoveryKind.deliveryDelay || origin == null) {
      return false;
    }
    if (origin.view != BuyV2View.tracking &&
        origin.view != BuyV2View.orderItems) {
      return false;
    }
    final orderId = origin.orderId;
    return orderId != null && _orders.any((order) => order.id == orderId);
  }

  bool get canResolveCheckoutAddress =>
      recoveryKind == BuyV2RecoveryKind.serviceAreaUnavailable &&
      _recoveryOrigin?.view == BuyV2View.checkout &&
      selectedAddressOrNull != null;

  _BuyV2NavigationSurfaceIdentity get _navigationSurfaceIdentity => (
    destination: destination,
    view: view,
    detail: switch (view) {
      BuyV2View.product => selectedProductId,
      BuyV2View.tracking || BuyV2View.orderItems => _selectedOrderId,
      BuyV2View.recovery => recoveryKind?.name,
      BuyV2View.catalogue ||
      BuyV2View.cart ||
      BuyV2View.checkout ||
      BuyV2View.confirmation ||
      BuyV2View.assist ||
      BuyV2View.account => null,
    },
  );

  void _notifyNavigation(BuyV2NavigationMotionDirection direction) {
    _navigationMotionDirection = _handlingBackNavigation
        ? BuyV2NavigationMotionDirection.back
        : direction;
    _navigationMotionSequence += 1;
    notifyListeners();
  }

  void _notifyNavigationIfChanged(
    _BuyV2NavigationSurfaceIdentity previous,
    BuyV2NavigationMotionDirection direction,
  ) {
    if (previous == _navigationSurfaceIdentity) {
      notifyListeners();
    } else {
      _notifyNavigation(direction);
    }
  }

  String? _selectedOrderId;
  String? _selectedAddressId = 'home';

  BuyV2Destination _accountReturnDestination = BuyV2Destination.shop;
  BuyV2View _accountReturnView = BuyV2View.catalogue;
  String? _accountReturnProductId;
  String? _accountReturnOrderId;
  String _accountReturnQuery = '';
  String? _accountReturnFilter;
  bool _accountChildReturnActive = false;
  BuyV2Destination _assistReturnDestination = BuyV2Destination.shop;
  BuyV2View _assistReturnView = BuyV2View.catalogue;
  BuyV2Destination _productReturnDestination = BuyV2Destination.shop;
  BuyV2View _productReturnView = BuyV2View.catalogue;
  final List<String> _comparedProductOrigins = [];
  bool _cartProductReturnActive = false;
  BuyV2Destination _cartProductReturnDestination = BuyV2Destination.shop;
  String? _cartProductReturnId;
  ({BuyV2Destination destination, BuyV2View view, List<String> comparisons})?
  _cartProductReturnOrigin;

  final List<BuyV2Product> _catalogueProducts = [];
  final Map<String, BuyV2CartLine> _cart = {};
  final Map<String, BuyV2ProductFactsSnapshot> _productFacts = {};
  final Map<String, BuyV2ProductContentSnapshot> _productContent = {};
  final Map<String, BuyV2MarketplaceTrustSnapshot> _marketplaceTrust = {};
  final Map<String, int> _prescriptionApprovedQuantities = {};
  final Map<String, BuyV2CustomerReview> _customerReviews = {};
  final Map<String, String> _reportedProductReasons = {};
  final Set<String> _reviewableProductIds = {};
  final Set<String> _productFeedbackBusyIds = {};
  bool _productReportsAvailable = false;
  final Set<String> _orderRefreshBusyIds = {};
  final Map<String, BuyV2CommerceLoadState> _orderRefreshStates = {};
  final Map<String, String> _orderRefreshMessages = {};
  final Map<String, BuyV2OrderResolutionSnapshot> _orderResolutionSnapshots =
      {};
  final Map<String, BuyV2OrderResolutionResult> _orderResolutionResults = {};
  final Set<String> _orderResolutionBusyIds = {};
  List<BuyV2ShoppingAlert> _shoppingAlerts = [];
  BuyV2ShoppingAlertsState shoppingAlertsState =
      BuyV2ShoppingAlertsState.loading;
  String? shoppingAlertsMessage;
  bool shoppingAlertsBusy = false;
  final Map<String, BuyV2BalancePaymentResult> _balancePaymentResults = {};
  final Set<String> _balancePaymentBusyOrderIds = {};
  int _balancePaymentAttemptSequence = 0;
  final Map<String, BuyV2DeliveryExceptionSnapshot>
  _deliveryExceptionSnapshots = {};
  final Set<String> _deliveryExceptionBusyOrderIds = {};
  final Map<String, String> _selectedDeliveryRescheduleSlots = {};
  final Map<String, BuyV2LiveDeliverySnapshot> _liveDeliverySnapshots = {};
  final Set<String> _liveDeliveryBusyOrderIds = {};
  final Map<String, String> _liveDeliveryRefreshMessages = {};
  final Map<BuyV2CartScope, double> _cartScrollOffsets = {};
  final Map<BuyV2Destination, String> _deliveryInstructionIds = {};
  final Map<String, _BuyV2CartBenefitSelectionRef> _selectedCartBenefitRefs =
      {};
  List<BuyV2CartBenefit> _liveCartBenefits = [];
  int _cartBenefitsRequestSequence = 0;
  final Map<String, List<BuyV2CartBenefit>> _productBenefits = {};
  final Map<String, BuyV2CartBenefitsLoadState> _productBenefitStates = {};
  final Map<String, String> _productBenefitMessages = {};
  final Map<String, int> _productBenefitRequestSequences = {};
  int _productBenefitRequestSequence = 0;
  BuyV2CartBenefitsLoadState cartBenefitsLoadState =
      BuyV2CartBenefitsLoadState.ready;
  String? cartBenefitsMessage;
  List<BuyV2CommercialPaymentTerm> _commercialPaymentTerms = [];
  final Map<String, String> _selectedCommercialPaymentTermIds = {};
  int _commercialPaymentTermsRequestSequence = 0;
  BuyV2CommerceLoadState commercialPaymentTermsLoadState =
      BuyV2CommerceLoadState.ready;
  String? commercialPaymentTermsMessage;
  BuyV2CheckoutQuote? _checkoutQuote;
  String? _checkoutQuoteFingerprint;
  int _checkoutQuoteRequestSequence = 0;
  BuyV2CommerceLoadState checkoutQuoteLoadState = BuyV2CommerceLoadState.ready;
  String? checkoutQuoteMessage;
  final Map<String, int> _tipsByFulfilmentKey = {};
  final Set<String> _savedKeys = {};
  final List<String> _recentlyViewedProductIds = [];
  final Map<BuyV2Destination, List<String>> _recentSearches = {};
  String? _savedProductsOwnerScope;
  int _savedProductsMutationRevision = 0;
  String? _customerStateOwnerScope;
  int _customerStateMutationRevision = 0;
  Set<BuyV2Destination> _confirmedDestinations = {};
  List<BuyV2Order> _confirmedOrders = [];
  Map<String, _BuyV2DeliveryPromiseQuote> _checkoutPromiseSnapshot = {};
  Map<String, _BuyV2DeliveryPromiseQuote>? _pendingCheckoutPromiseSnapshot;
  List<BuyV2DeliveryPromiseChange> _checkoutDeliveryPromiseChanges = [];
  List<BuyV2PriceChange> _checkoutPriceChanges = [];
  BuyV2CheckoutAvailabilityIssue? _checkoutAvailabilityIssue;
  String? _confirmedPurchaseId;
  int _confirmedProductCount = 0;
  int _confirmedItemCount = 0;
  int _confirmedTotal = 0;
  int _confirmedAmountPaidNow = 0;
  int _confirmedBalanceDue = 0;
  int _orderSequence = 1;
  int _purchaseSequence = 1;

  List<BuyV2PriceChange> get checkoutPriceChanges =>
      List.unmodifiable(_checkoutPriceChanges);

  bool get checkoutPriceReviewRequired => _checkoutPriceChanges.isNotEmpty;

  BuyV2CheckoutAvailabilityIssue? get checkoutAvailabilityIssue =>
      _checkoutAvailabilityIssue;

  void acceptCheckoutPriceChanges() {
    if (_checkoutPriceChanges.isEmpty) return;
    _checkoutPriceChanges = [];
    _invalidateAndRefreshCheckoutPricingContracts();
    notice = 'Updated prices accepted';
    _persistCustomerState();
    notifyListeners();
  }

  final List<BuyV2Address> _addresses = [
    const BuyV2Address(
      id: 'home',
      kind: BuyV2AddressKind.home,
      label: 'Home',
      recipient: 'Aarav Sharma',
      phone: '9000000000',
      line: '12, Central Avenue',
      area: 'Sardarpura, Jodhpur',
      pinCode: '342003',
      landmark: 'Near Sardarpura circle',
    ),
    const BuyV2Address(
      id: 'work',
      kind: BuyV2AddressKind.work,
      label: 'Work',
      recipient: 'Aarav Sharma',
      phone: '9000000000',
      line: 'Business receiving desk',
      area: 'Basni, Jodhpur',
      pinCode: '342005',
      landmark: 'Near industrial area gate',
    ),
  ];

  final List<BuyV2Order> _orders = [
    const BuyV2Order(
      id: 'MS-240782',
      destination: BuyV2Destination.shop,
      title: 'Shop order',
      itemSummary: '13 products · Home · Sardarpura',
      total: 4839,
      partner: 'Sardarpura Supermart',
      partnerType: 'MoolSocial Fulfilment Store',
      promise: 'Delivery schedule awaiting live confirmation',
      destinationLabel: 'Sardarpura · 342003',
      progress: .54,
      status: BuyV2OrderStatus.preparing,
    ),
    const BuyV2Order(
      id: 'PO-240783',
      destination: BuyV2Destination.wholesale,
      title: 'Wholesale order',
      itemSummary: '1 trade product · Work receiving · Basni',
      total: 4200,
      partner: 'Marwar Foods Distribution',
      partnerType: 'MoolSocial Fulfilment Partner',
      buyerName: 'Shree Balaji Retail',
      buyerType: 'Retailer business',
      paymentMethod: 'Bank transfer',
      paymentTermLabel: 'Booking amount with balance at delivery',
      amountPaidNow: 1260,
      balanceDue: 2940,
      balanceDueLabel: 'Due at confirmed delivery',
      paymentStatusLabel: 'Booking amount paid · balance due at delivery',
      promise: 'Supplier delivery schedule awaiting confirmation',
      destinationLabel: 'Basni · 342005',
      progress: .2,
      status: BuyV2OrderStatus.confirmed,
    ),
    const BuyV2Order(
      id: 'RX-240784',
      destination: BuyV2Destination.medicine,
      title: 'Medicine order',
      itemSummary: '2 medicines · Home · Sardarpura',
      total: 134,
      partner: 'Sardarpura Health Pharmacy',
      partnerType: 'Mool Pharmacy Partner',
      promise: 'Pharmacy delivery schedule awaiting confirmation',
      destinationLabel: 'Sardarpura · 342003',
      progress: .67,
      status: BuyV2OrderStatus.preparing,
    ),
    const BuyV2Order(
      id: 'MS-240741',
      destination: BuyV2Destination.shop,
      title: 'Shop order',
      itemSummary: '8 products · Home · Sardarpura',
      total: 2186,
      partner: 'Sardarpura Supermart',
      partnerType: 'MoolSocial Fulfilment Store',
      promise: 'Delivered · 25 Jul · 6:42 pm',
      destinationLabel: 'Sardarpura · 342003',
      progress: 1,
      status: BuyV2OrderStatus.delivered,
      productIds: [
        's-tomato',
        's-atta',
        's-oil',
        's-rice',
        's-soap',
        's-notebook',
        's-onion',
        's-banana',
      ],
    ),
    const BuyV2Order(
      id: 'PO-240728',
      destination: BuyV2Destination.wholesale,
      title: 'Wholesale order',
      itemSummary: '3 trade products · Work receiving · Basni',
      total: 8460,
      partner: 'Marwar Foods Distribution',
      partnerType: 'MoolSocial Fulfilment Partner',
      buyerName: 'Shree Balaji Retail',
      buyerType: 'Retailer business',
      paymentMethod: 'Bank transfer',
      paymentTermLabel: 'Full advance',
      amountPaidNow: 8460,
      paymentStatusLabel: 'Paid in full',
      promise: 'Delivered · 23 Jul · 1:18 pm',
      destinationLabel: 'Basni · 342005',
      progress: 1,
      status: BuyV2OrderStatus.delivered,
      productIds: ['w-rice', 'w-oil', 'w-notebook'],
    ),
    const BuyV2Order(
      id: 'RX-240719',
      destination: BuyV2Destination.medicine,
      title: 'Medicine order',
      itemSummary: '2 medicines · Home · Sardarpura',
      total: 698,
      partner: 'Sardarpura Health Pharmacy',
      partnerType: 'Mool Pharmacy Partner',
      promise: 'Delivered · 20 Jul · 10:36 am',
      destinationLabel: 'Sardarpura · 342003',
      progress: 1,
      status: BuyV2OrderStatus.delivered,
    ),
  ];

  List<BuyV2Address> get addresses => List.unmodifiable(_addresses);

  List<BuyV2Order> get orders => List.unmodifiable(_orders);

  bool orderRefreshBusy(String orderId) =>
      _orderRefreshBusyIds.contains(orderId);

  BuyV2CommerceLoadState? orderRefreshState(String orderId) =>
      _orderRefreshStates[orderId];

  String? orderRefreshMessage(String orderId) => _orderRefreshMessages[orderId];

  Future<bool> refreshOrder(String orderId) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index < 0) {
      notice = 'This order could not be found.';
      notifyListeners();
      return false;
    }
    if (_orders[index].collection != null) {
      return refreshCollectionOrder(orderId);
    }
    if (!_orderRefreshBusyIds.add(orderId)) return false;
    _orderRefreshStates[orderId] = BuyV2CommerceLoadState.loading;
    _orderRefreshMessages.remove(orderId);
    notifyListeners();
    try {
      final result = await commerceAdapter.refreshOrder(orderId: orderId);
      final refreshed = result.order;
      final valid =
          result.state == BuyV2CommerceLoadState.ready &&
          refreshed != null &&
          refreshed.id == orderId &&
          refreshed.total >= 0 &&
          refreshed.progress >= 0 &&
          refreshed.progress <= 1 &&
          refreshed.partner.trim().isNotEmpty &&
          refreshed.promise.trim().isNotEmpty &&
          _validTaxInvoiceForOrder(refreshed);
      if (!valid) {
        _orderRefreshStates[orderId] = result.state;
        _orderRefreshMessages[orderId] = result.customerMessage;
        notice = null;
        return false;
      }
      _orders[index] = refreshed;
      _orderRefreshStates[orderId] = BuyV2CommerceLoadState.ready;
      _orderRefreshMessages[orderId] = result.customerMessage;
      notice = result.customerMessage;
      return true;
    } on Object {
      _orderRefreshStates[orderId] = BuyV2CommerceLoadState.offline;
      _orderRefreshMessages[orderId] =
          'Order could not refresh. Check your connection and try again.';
      notice = null;
      return false;
    } finally {
      _orderRefreshBusyIds.remove(orderId);
      notifyListeners();
    }
  }

  bool _validTaxInvoiceForOrder(BuyV2Order order) {
    final state = order.taxInvoiceState;
    final details = order.taxInvoiceDetails;
    if (state == null) return true;
    if (state == BuyV2TaxInvoiceState.pending ||
        state == BuyV2TaxInvoiceState.unavailable) {
      return details == null;
    }
    if (!order.invoiceAvailable ||
        details == null ||
        details.invoiceNumber.trim().isEmpty ||
        details.sellerLegalName.trim().isEmpty ||
        details.sellerAddress.trim().isEmpty ||
        details.sellerGstin.trim().length != 15 ||
        details.placeOfSupply.trim().isEmpty ||
        details.sourceId.trim().isEmpty ||
        details.lines.isEmpty ||
        (state == BuyV2TaxInvoiceState.corrected &&
            details.revisionLabel?.trim().isNotEmpty != true)) {
      return false;
    }
    for (final line in details.lines) {
      final intraStateTax = line.cgst > 0 || line.sgst > 0;
      if (line.description.trim().isEmpty ||
          line.hsnSac.trim().isEmpty ||
          line.taxableValue < 0 ||
          line.gstRate < 0 ||
          line.gstRate > 100 ||
          line.cgst < 0 ||
          line.sgst < 0 ||
          line.igst < 0 ||
          line.cess < 0 ||
          (intraStateTax && line.igst > 0)) {
        return false;
      }
    }
    return details.totalTax == order.tax;
  }

  bool balancePaymentBusy(String orderId) =>
      _balancePaymentBusyOrderIds.contains(orderId);

  BuyV2BalancePaymentResult? balancePaymentFor(String orderId) =>
      _balancePaymentResults[orderId];

  Future<bool> restoreBalancePayment(String orderId) async {
    final adapter = balancePaymentAdapter;
    final order = _orders
        .where((candidate) => candidate.id == orderId)
        .firstOrNull;
    if (adapter == null || order == null || order.balanceDue <= 0) return false;
    if (!_balancePaymentBusyOrderIds.add(orderId)) return false;
    notifyListeners();
    try {
      final result = await adapter.loadBalance(orderId: orderId);
      if (!_validBalancePaymentResult(order, result)) return false;
      _balancePaymentResults[orderId] = result;
      return true;
    } on Object {
      _balancePaymentResults[orderId] = BuyV2BalancePaymentResult(
        state: BuyV2BalancePaymentState.offline,
        amountDue: order.balanceDue,
        dueLabel: order.balanceDueLabel ?? 'Due later',
        customerMessage: 'Balance status could not be checked. Try again.',
      );
      return false;
    } finally {
      _balancePaymentBusyOrderIds.remove(orderId);
      notifyListeners();
    }
  }

  Future<bool> startBalancePayment(String orderId) async {
    final adapter = balancePaymentAdapter;
    final order = _orders
        .where((candidate) => candidate.id == orderId)
        .firstOrNull;
    final current = _balancePaymentResults[orderId];
    if (adapter == null ||
        order == null ||
        current == null ||
        (current.state != BuyV2BalancePaymentState.due &&
            current.state != BuyV2BalancePaymentState.overdue) ||
        !_balancePaymentBusyOrderIds.add(orderId)) {
      return false;
    }
    notifyListeners();
    try {
      final result = await adapter.startPayment(
        orderId: orderId,
        amountDue: current.amountDue,
        idempotencyKey:
            'balance-${orderId.toLowerCase()}-'
            '${_balancePaymentAttemptSequence++}',
      );
      if (!_validBalancePaymentResult(order, result)) return false;
      _balancePaymentResults[orderId] = result;
      return result.state == BuyV2BalancePaymentState.paymentActionRequired;
    } on Object {
      _balancePaymentResults[orderId] = BuyV2BalancePaymentResult(
        state: BuyV2BalancePaymentState.offline,
        amountDue: current.amountDue,
        dueLabel: current.dueLabel,
        customerMessage: 'Balance payment could not start. Try again.',
      );
      return false;
    } finally {
      _balancePaymentBusyOrderIds.remove(orderId);
      notifyListeners();
    }
  }

  Future<bool> continueBalancePayment(
    String orderId,
    BuyV2PaymentHandoff handoff,
  ) async {
    final order = _orders
        .where((candidate) => candidate.id == orderId)
        .firstOrNull;
    final current = _balancePaymentResults[orderId];
    final uri = current?.paymentActionUri;
    if (order == null ||
        current == null ||
        current.state != BuyV2BalancePaymentState.paymentActionRequired ||
        uri == null ||
        !_balancePaymentBusyOrderIds.add(orderId)) {
      return false;
    }
    notifyListeners();
    var opened = false;
    try {
      opened = await handoff(uri);
    } on Object {
      opened = false;
    }
    _balancePaymentResults[orderId] = BuyV2BalancePaymentResult(
      state: opened
          ? BuyV2BalancePaymentState.paymentPending
          : BuyV2BalancePaymentState.unknown,
      amountDue: current.amountDue,
      dueLabel: current.dueLabel,
      customerMessage: opened
          ? 'Return here after payment to check the balance.'
          : 'The payment app did not open. No payment is confirmed.',
      paymentReference: current.paymentReference,
      paymentActionUri: current.paymentActionUri,
    );
    _balancePaymentBusyOrderIds.remove(orderId);
    notifyListeners();
    return opened;
  }

  Future<bool> reconcileBalancePayment(String orderId) async {
    final adapter = balancePaymentAdapter;
    final order = _orders
        .where((candidate) => candidate.id == orderId)
        .firstOrNull;
    final current = _balancePaymentResults[orderId];
    final reference = current?.paymentReference;
    if (adapter == null ||
        order == null ||
        current == null ||
        reference == null ||
        (current.state != BuyV2BalancePaymentState.paymentPending &&
            current.state != BuyV2BalancePaymentState.unknown) ||
        !_balancePaymentBusyOrderIds.add(orderId)) {
      return false;
    }
    notifyListeners();
    try {
      final result = await adapter.reconcilePayment(
        orderId: orderId,
        paymentReference: reference,
      );
      if (!_validBalancePaymentResult(order, result)) return false;
      _balancePaymentResults[orderId] = result;
      return result.state == BuyV2BalancePaymentState.paid;
    } on Object {
      _balancePaymentResults[orderId] = BuyV2BalancePaymentResult(
        state: BuyV2BalancePaymentState.unknown,
        amountDue: current.amountDue,
        dueLabel: current.dueLabel,
        customerMessage:
            'Balance payment is still being checked. Do not pay again.',
        paymentReference: reference,
      );
      return false;
    } finally {
      _balancePaymentBusyOrderIds.remove(orderId);
      notifyListeners();
    }
  }

  bool _validBalancePaymentResult(
    BuyV2Order order,
    BuyV2BalancePaymentResult result,
  ) {
    if (result.amountDue < 0 ||
        result.amountDue > order.balanceDue ||
        result.dueLabel.trim().isEmpty ||
        result.customerMessage.trim().isEmpty) {
      return false;
    }
    return switch (result.state) {
      BuyV2BalancePaymentState.paymentActionRequired =>
        result.amountDue > 0 &&
            result.paymentReference?.trim().isNotEmpty == true &&
            result.paymentActionUri != null &&
            (result.paymentActionUri!.scheme == 'upi' ||
                result.paymentActionUri!.scheme == 'https') &&
            result.paymentActionUri!.host.isNotEmpty,
      BuyV2BalancePaymentState.paymentPending ||
      BuyV2BalancePaymentState.unknown =>
        result.paymentReference?.trim().isNotEmpty == true,
      BuyV2BalancePaymentState.paid => result.amountDue == 0,
      BuyV2BalancePaymentState.upcoming ||
      BuyV2BalancePaymentState.due ||
      BuyV2BalancePaymentState.overdue ||
      BuyV2BalancePaymentState.offline ||
      BuyV2BalancePaymentState.unavailable => result.amountDue > 0,
    };
  }

  bool deliveryExceptionBusy(String orderId) =>
      _deliveryExceptionBusyOrderIds.contains(orderId);

  BuyV2DeliveryExceptionSnapshot? deliveryExceptionFor(String orderId) =>
      _deliveryExceptionSnapshots[orderId];

  String? selectedDeliveryRescheduleSlot(String orderId) =>
      _selectedDeliveryRescheduleSlots[orderId];

  Future<bool> restoreDeliveryException(String orderId) async {
    final adapter = deliveryExceptionAdapter;
    final orderExists = _orders.any((order) => order.id == orderId);
    if (adapter == null ||
        !orderExists ||
        !_deliveryExceptionBusyOrderIds.add(orderId)) {
      return false;
    }
    notifyListeners();
    try {
      final snapshot = await adapter.loadException(orderId: orderId);
      if (!_validDeliveryExceptionSnapshot(snapshot)) return false;
      _deliveryExceptionSnapshots[orderId] = snapshot;
      final selected = _selectedDeliveryRescheduleSlots[orderId];
      if (selected != null && !snapshot.rescheduleSlots.contains(selected)) {
        _selectedDeliveryRescheduleSlots.remove(orderId);
      }
      return true;
    } on Object {
      _deliveryExceptionSnapshots[orderId] =
          const BuyV2DeliveryExceptionSnapshot(
            state: BuyV2CommerceLoadState.offline,
            customerMessage:
                'Delivery updates could not be checked. Try again.',
          );
      return false;
    } finally {
      _deliveryExceptionBusyOrderIds.remove(orderId);
      notifyListeners();
    }
  }

  bool chooseDeliveryRescheduleSlot(String orderId, String slot) {
    final snapshot = _deliveryExceptionSnapshots[orderId];
    if (snapshot == null || !snapshot.rescheduleSlots.contains(slot)) {
      notice = 'This delivery time is no longer available.';
      notifyListeners();
      return false;
    }
    _selectedDeliveryRescheduleSlots[orderId] = slot;
    notice = '$slot selected.';
    notifyListeners();
    return true;
  }

  Future<bool> confirmDeliveryReschedule(String orderId) async {
    final adapter = deliveryExceptionAdapter;
    final snapshot = _deliveryExceptionSnapshots[orderId];
    final exceptionId = snapshot?.exceptionId;
    final slot = _selectedDeliveryRescheduleSlots[orderId];
    if (adapter == null ||
        snapshot == null ||
        exceptionId == null ||
        slot == null ||
        !snapshot.rescheduleSlots.contains(slot) ||
        !_deliveryExceptionBusyOrderIds.add(orderId)) {
      return false;
    }
    notifyListeners();
    try {
      final updated = await adapter.rescheduleDelivery(
        orderId: orderId,
        exceptionId: exceptionId,
        slot: slot,
      );
      if (!_validDeliveryExceptionSnapshot(updated)) return false;
      _deliveryExceptionSnapshots[orderId] = updated;
      _selectedDeliveryRescheduleSlots.remove(orderId);
      notice = updated.customerMessage;
      return true;
    } on Object {
      notice = 'Delivery could not be rescheduled. Try again.';
      return false;
    } finally {
      _deliveryExceptionBusyOrderIds.remove(orderId);
      notifyListeners();
    }
  }

  Future<bool> disputeProofOfDelivery(String orderId) async {
    final adapter = deliveryExceptionAdapter;
    final snapshot = _deliveryExceptionSnapshots[orderId];
    final exceptionId = snapshot?.exceptionId;
    final proofReference = snapshot?.proofReference;
    if (adapter == null ||
        snapshot?.kind != BuyV2DeliveryExceptionKind.proofOfDeliveryAvailable ||
        exceptionId == null ||
        proofReference == null ||
        !_deliveryExceptionBusyOrderIds.add(orderId)) {
      return false;
    }
    notifyListeners();
    try {
      final updated = await adapter.disputeProofOfDelivery(
        orderId: orderId,
        exceptionId: exceptionId,
        proofReference: proofReference,
      );
      if (!_validDeliveryExceptionSnapshot(updated)) return false;
      _deliveryExceptionSnapshots[orderId] = updated;
      notice = updated.customerMessage;
      return updated.kind == BuyV2DeliveryExceptionKind.proofOfDeliveryDisputed;
    } on Object {
      notice = 'Proof of delivery could not be reported. Try again.';
      return false;
    } finally {
      _deliveryExceptionBusyOrderIds.remove(orderId);
      notifyListeners();
    }
  }

  bool get liveDeliveryAvailable => liveDeliveryAdapter != null;

  bool liveDeliveryBusy(String orderId) =>
      _liveDeliveryBusyOrderIds.contains(orderId);

  BuyV2LiveDeliverySnapshot? liveDeliveryFor(String orderId) =>
      _liveDeliverySnapshots[orderId];

  String? liveDeliveryRefreshMessage(String orderId) =>
      _liveDeliveryRefreshMessages[orderId];

  Future<bool> refreshLiveDelivery(String orderId) async {
    final orderExists = _orders.any((order) => order.id == orderId);
    if (!orderExists || !_liveDeliveryBusyOrderIds.add(orderId)) return false;
    final adapter = liveDeliveryAdapter;
    if (adapter == null) {
      _liveDeliveryBusyOrderIds.remove(orderId);
      _liveDeliverySnapshots[orderId] = BuyV2LiveDeliverySnapshot(
        orderId: orderId,
        state: BuyV2LiveDeliveryState.unavailable,
        customerMessage:
            'Live delivery updates are not available for this order yet.',
        sourceId: 'not-connected',
      );
      _liveDeliveryRefreshMessages.remove(orderId);
      notifyListeners();
      return false;
    }
    notifyListeners();
    try {
      final snapshot = await adapter.load(orderId: orderId);
      if (!_validLiveDeliverySnapshot(snapshot, orderId)) {
        const message =
            'Live delivery details are temporarily unavailable. Try again.';
        if (_liveDeliverySnapshots[orderId]?.state ==
            BuyV2LiveDeliveryState.ready) {
          _liveDeliveryRefreshMessages[orderId] = message;
        } else {
          _liveDeliverySnapshots[orderId] = BuyV2LiveDeliverySnapshot(
            orderId: orderId,
            state: BuyV2LiveDeliveryState.unavailable,
            customerMessage: message,
            sourceId: 'invalid-details',
          );
        }
        return false;
      }
      if ((snapshot.state == BuyV2LiveDeliveryState.offline ||
              snapshot.state == BuyV2LiveDeliveryState.unavailable) &&
          _liveDeliverySnapshots[orderId]?.state ==
              BuyV2LiveDeliveryState.ready) {
        _liveDeliveryRefreshMessages[orderId] = snapshot.customerMessage;
        return false;
      }
      _liveDeliverySnapshots[orderId] = snapshot;
      _liveDeliveryRefreshMessages.remove(orderId);
      return snapshot.state == BuyV2LiveDeliveryState.ready ||
          snapshot.state == BuyV2LiveDeliveryState.delivered;
    } on Object {
      const message =
          'Live delivery could not refresh. Check your connection and try again.';
      if (_liveDeliverySnapshots[orderId]?.state ==
          BuyV2LiveDeliveryState.ready) {
        _liveDeliveryRefreshMessages[orderId] = message;
      } else {
        _liveDeliverySnapshots[orderId] = BuyV2LiveDeliverySnapshot(
          orderId: orderId,
          state: BuyV2LiveDeliveryState.offline,
          customerMessage: message,
          sourceId: 'connection-unavailable',
        );
      }
      return false;
    } finally {
      _liveDeliveryBusyOrderIds.remove(orderId);
      notifyListeners();
    }
  }

  bool _validLiveDeliverySnapshot(
    BuyV2LiveDeliverySnapshot snapshot,
    String orderId,
  ) {
    if (snapshot.orderId != orderId ||
        snapshot.customerMessage.trim().isEmpty ||
        snapshot.sourceId.trim().isEmpty) {
      return false;
    }
    if (snapshot.state != BuyV2LiveDeliveryState.ready) return true;
    final progress = snapshot.routeProgress;
    final updatedAt = snapshot.lastUpdatedAt;
    return snapshot.courierPosition?.isValid == true &&
        snapshot.destinationPosition?.isValid == true &&
        snapshot.driverName?.trim().isNotEmpty == true &&
        snapshot.etaLabel?.trim().isNotEmpty == true &&
        updatedAt != null &&
        !updatedAt.isAfter(DateTime.now().add(const Duration(minutes: 5))) &&
        progress != null &&
        progress.isFinite &&
        progress >= 0 &&
        progress <= 1;
  }

  bool _validDeliveryExceptionSnapshot(
    BuyV2DeliveryExceptionSnapshot snapshot,
  ) {
    if (snapshot.customerMessage.trim().isEmpty) return false;
    if (snapshot.state != BuyV2CommerceLoadState.ready) return true;
    final kind = snapshot.kind;
    if (kind == null) return true;
    if (snapshot.exceptionId?.trim().isNotEmpty != true ||
        snapshot.headline?.trim().isNotEmpty != true ||
        snapshot.detail?.trim().isNotEmpty != true ||
        snapshot.rescheduleSlots.any((slot) => slot.trim().isEmpty) ||
        snapshot.rescheduleSlots.toSet().length !=
            snapshot.rescheduleSlots.length) {
      return false;
    }
    if (kind == BuyV2DeliveryExceptionKind.rescheduleAvailable &&
        snapshot.rescheduleSlots.isEmpty) {
      return false;
    }
    if (kind == BuyV2DeliveryExceptionKind.proofOfDeliveryAvailable &&
        snapshot.proofReference?.trim().isNotEmpty != true) {
      return false;
    }
    return true;
  }

  String? get selectedOrderId => _selectedOrderId;

  String? get selectedAddressId => _selectedAddressId;

  Future<void> restoreCommerce() async {
    if (reviewDataEnabled) {
      commerceLoadState = BuyV2CommerceLoadState.ready;
      commerceMessage = null;
      return;
    }
    commerceLoadState = BuyV2CommerceLoadState.loading;
    commerceMessage = null;
    notifyListeners();
    try {
      final snapshot = await commerceAdapter.refresh();
      _catalogueProducts
        ..clear()
        ..addAll(snapshot.products);
      _addresses
        ..clear()
        ..addAll(snapshot.addresses);
      _orders
        ..clear()
        ..addAll(snapshot.orders);
      _businessVerificationState = snapshot.businessVerificationState;
      businessVerified =
          snapshot.businessVerificationState ==
              BuyV2BusinessVerificationState.verified ||
          snapshot.businessVerified;
      _productReportsAvailable = snapshot.productReportsAvailable;
      _reviewableProductIds
        ..clear()
        ..addAll(snapshot.reviewableProductIds);
      availablePaymentMethods = Set.unmodifiable(snapshot.paymentMethods);
      _selectedAddressId = snapshot.selectedAddressId;
      if (_selectedAddressId != null &&
          !_addresses.any((address) => address.id == _selectedAddressId)) {
        _selectedAddressId = null;
      }
      if (!availablePaymentMethods.contains(selectedPayment)) {
        selectedPayment = availablePaymentMethods.firstOrNull ?? '';
      }
      commerceLoadState = snapshot.state;
      commerceMessage = snapshot.customerMessage;
    } on Object {
      commerceLoadState = BuyV2CommerceLoadState.offline;
      commerceMessage =
          'Shop could not refresh. Check your connection and try again.';
    }
    notifyListeners();
  }

  Future<void> retryCommerce() => restoreCommerce();

  Future<BuyV2AddressRequestResult> createAddressRequest({
    String recipient = '',
  }) async {
    return commerceAdapter.createAddressRequest(recipient: recipient.trim());
  }

  List<BuyV2Category> get categories => categoriesFor(destination);

  List<BuyV2Category> categoriesFor(BuyV2Destination destination) =>
      switch (destination) {
        BuyV2Destination.shop => BuyV2Catalogue.shopCategories,
        BuyV2Destination.wholesale => BuyV2Catalogue.wholesaleCategories,
        BuyV2Destination.medicine => BuyV2Catalogue.medicineCategories,
        BuyV2Destination.orders => const [],
      };

  String get selectedCategoryId => switch (destination) {
    BuyV2Destination.shop => shopCategoryId,
    BuyV2Destination.wholesale => wholesaleCategoryId,
    BuyV2Destination.medicine => medicineCategoryId,
    BuyV2Destination.orders => 'all',
  };

  BuyV2FulfilmentMode fulfilmentModeFor(BuyV2Product product) =>
      productFactsFor(product).fulfilmentMode ??
      buyV2CatalogueFulfilmentModeFor(product);

  BuyV2PackFilter packFilterFor(BuyV2Product product) {
    final pack = product.pack.toLowerCase();
    if (product.destination == BuyV2Destination.wholesale) {
      return product.minimumOrder > 2
          ? BuyV2PackFilter.bulk
          : BuyV2PackFilter.standard;
    }
    if (product.minimumOrder > 1 ||
        RegExp(r'case|carton|crate|sack|pallet|lot|trade').hasMatch(pack)) {
      return BuyV2PackFilter.bulk;
    }
    if (RegExp(r'pack of\s*[2-9]|[2-9]\s*[×x]').hasMatch(pack)) {
      return BuyV2PackFilter.multipack;
    }
    return BuyV2PackFilter.standard;
  }

  BuyV2ShopSaleType get shopSaleType => _shopSaleType;

  BuyV2WholesaleSaleType get wholesaleSaleType => _wholesaleSaleType;

  String get saleTypeSignature => switch (destination) {
    BuyV2Destination.shop => 'shop-${shopSaleType.name}',
    BuyV2Destination.wholesale => 'wholesale-${wholesaleSaleType.name}',
    BuyV2Destination.medicine || BuyV2Destination.orders => destination.name,
  };

  void chooseShopSaleType(BuyV2ShopSaleType value) {
    if (_shopSaleType == value &&
        selectedFilter == null &&
        selectedFulfilmentMode == null) {
      return;
    }
    _shopSaleType = value;
    selectedFilter = null;
    selectedFulfilmentMode = null;
    notifyListeners();
  }

  void chooseWholesaleSaleType(BuyV2WholesaleSaleType value) {
    if (_wholesaleSaleType == value &&
        selectedFilter == null &&
        selectedPackFilter == null &&
        selectedFulfilmentMode == null) {
      return;
    }
    _wholesaleSaleType = value;
    selectedFilter = null;
    selectedPackFilter = null;
    selectedFulfilmentMode = null;
    notifyListeners();
  }

  bool _availableForDiscovery(BuyV2Product product) {
    final facts = productFactsFor(product);
    final orderability = facts.orderabilityLabel.toLowerCase();
    return !facts.stale &&
        facts.storeOperatingState != BuyV2StoreOperatingState.closed &&
        !orderability.contains('unavailable') &&
        !orderability.contains('not available') &&
        !orderability.contains('out of stock') &&
        !orderability.contains('checking') &&
        !orderability.contains('loading');
  }

  List<BuyV2Product> get visibleProducts =>
      _resolveVisibleProducts(limit: true);

  List<BuyV2Product> get visibleSavedProducts => _resolveVisibleProducts(
    limit: false,
    source: savedProductsFor(destination),
  );

  List<BuyV2Product> _resolveVisibleProducts({
    required bool limit,
    BuyV2DiscoveryRefinements? refinements,
    Iterable<BuyV2Product>? source,
  }) {
    final choices = refinements ?? discoveryRefinements;
    final normalized = query.trim().toLowerCase();
    final filterDestination = destination == BuyV2Destination.orders
        ? BuyV2Destination.shop
        : destination;
    final category = selectedCategoryId;
    final intentProductIds =
        activeShoppingIntent == BuyV2ShoppingIntent.monthlyBasket &&
            filterDestination == BuyV2Destination.shop
        ? monthlyBasketPlan.map((line) => line.product.id).toSet()
        : null;
    final candidates = (source ?? _catalogueProducts).where((product) {
      if (product.destination != filterDestination) return false;
      if (!product.catalogueListing) return false;
      if (intentProductIds != null && !intentProductIds.contains(product.id)) {
        return false;
      }
      final matchesCategory =
          category == 'all' ||
          (category == 'rx' && product.requiresPrescription) ||
          product.categoryId == category;
      final matchesFilter = switch (choices.filter) {
        'fast' => switch (filterDestination) {
          BuyV2Destination.shop =>
            fulfilmentModeFor(product) == BuyV2FulfilmentMode.quickLocal,
          BuyV2Destination.wholesale => product.origin.toLowerCase().contains(
            'jodhpur',
          ),
          BuyV2Destination.medicine => !product.requiresPrescription,
          BuyV2Destination.orders => false,
        },
        'today' => fulfilmentModeFor(product) == BuyV2FulfilmentMode.quickLocal,
        'lowest' =>
          product.badge.toLowerCase().contains('lowest') ||
              product.badge.contains('off'),
        'manufacturer' =>
          product.sellerType.toLowerCase().contains('manufacturer') ||
              product.manufacturerVerified,
        'nearby' =>
          product.origin.toLowerCase().contains('jodhpur') ||
              product.seller.toLowerCase().contains('sardarpura') ||
              product.seller.toLowerCase().contains('jodhpur'),
        'two-days' =>
          product.origin.toLowerCase().contains('jodhpur') ||
              product.origin.toLowerCase().contains('jaipur'),
        'freight' => product.freightIncluded,
        'moq' =>
          product.destination == BuyV2Destination.wholesale &&
              product.minimumOrder <= 2,
        'returns' => product.returnPolicy != null,
        'quick-local' =>
          fulfilmentModeFor(product) == BuyV2FulfilmentMode.quickLocal,
        'standard-courier' =>
          fulfilmentModeFor(product) == BuyV2FulfilmentMode.standardCourier,
        'bulk-freight' =>
          fulfilmentModeFor(product) == BuyV2FulfilmentMode.bulkFreight,
        'rx' => product.requiresPrescription,
        'otc' => !product.requiresPrescription,
        _ => true,
      };
      final matchesBrands =
          choices.brands.isEmpty || choices.brands.contains(product.brand);
      final matchesPrice =
          choices.maximumPrice == null ||
          productFactsFor(product).price <= choices.maximumPrice!;
      final matchesPack =
          choices.pack == null || packFilterFor(product) == choices.pack;
      final matchesFulfilment =
          choices.fulfilmentMode == null ||
          fulfilmentModeFor(product) == choices.fulfilmentMode;
      final matchesAvailability =
          !choices.availableOnly || _availableForDiscovery(product);
      return matchesCategory &&
          matchesFilter &&
          matchesBrands &&
          matchesPrice &&
          matchesPack &&
          matchesFulfilment &&
          matchesAvailability;
    }).toList();
    final products = normalized.isEmpty
        ? candidates
        : BuyV2SearchRelevance.rankProducts(candidates, query);
    switch (choices.sort) {
      case BuyV2ProductSort.relevance:
        break;
      case BuyV2ProductSort.priceLowToHigh:
        products.sort(
          (left, right) => productFactsFor(
            left,
          ).price.compareTo(productFactsFor(right).price),
        );
      case BuyV2ProductSort.priceHighToLow:
        products.sort(
          (left, right) => productFactsFor(
            right,
          ).price.compareTo(productFactsFor(left).price),
        );
      case BuyV2ProductSort.deliveryFastest:
        int priority(BuyV2Product product) =>
            switch (fulfilmentModeFor(product)) {
              BuyV2FulfilmentMode.quickLocal => 0,
              BuyV2FulfilmentMode.standardCourier => 1,
              BuyV2FulfilmentMode.bulkFreight => 2,
            };
        products.sort((left, right) {
          final fulfilment = priority(left).compareTo(priority(right));
          if (fulfilment != 0) return fulfilment;
          return productFactsFor(
            left,
          ).price.compareTo(productFactsFor(right).price);
        });
    }
    if (limit &&
        category == 'all' &&
        normalized.isEmpty &&
        products.length > 18) {
      return products.take(18).toList();
    }
    return products;
  }

  List<BuyV2Product> get catalogueSaleTypeProducts {
    return previewDiscoveryProducts(discoveryRefinements);
  }

  List<BuyV2Product> previewDiscoveryProducts(
    BuyV2DiscoveryRefinements refinements,
  ) {
    final products = _resolveVisibleProducts(
      limit: false,
      refinements: refinements,
    );
    return products
        .where((product) {
          return switch (destination) {
            BuyV2Destination.shop => switch (shopSaleType) {
              BuyV2ShopSaleType.quickDelivery =>
                fulfilmentModeFor(product) == BuyV2FulfilmentMode.quickLocal,
              BuyV2ShopSaleType.courier =>
                fulfilmentModeFor(product) ==
                    BuyV2FulfilmentMode.standardCourier,
            },
            BuyV2Destination.wholesale => switch (wholesaleSaleType) {
              BuyV2WholesaleSaleType.wholesale => product.minimumOrder <= 2,
              BuyV2WholesaleSaleType.bulk => product.minimumOrder > 2,
            },
            BuyV2Destination.medicine || BuyV2Destination.orders => true,
          };
        })
        .toList(growable: false);
  }

  bool get hasNarrowedProductSearchScope =>
      destination != BuyV2Destination.orders &&
      query.trim().isNotEmpty &&
      (selectedCategoryId != 'all' ||
          selectedFilter != null ||
          activeDiscoveryRefinementCount > 0);

  /// Truthful, replaceable search-discovery boundary for the active vertical.
  ///
  /// Until an approved suggestion API exists, suggestions come only from the
  /// products already allowed by the current destination/category/filter
  /// selection. The presentation does not infer popularity, history or
  /// personalization from this list.
  List<String> get searchSuggestions {
    if (destination == BuyV2Destination.orders || query.trim().isNotEmpty) {
      return const [];
    }
    final suggestions = <String>[];
    final seen = <String>{};
    for (final product in visibleProducts) {
      final label = product.title.trim();
      if (label.isEmpty || !seen.add(label.toLowerCase())) continue;
      suggestions.add(label);
      if (suggestions.length == 4) break;
    }
    return List.unmodifiable(suggestions);
  }

  List<String> recentSearchesFor(BuyV2Destination value) =>
      List.unmodifiable(_recentSearches[value] ?? const <String>[]);

  bool submitSearch(String value) {
    final clean = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    query = clean;
    if (clean.length < 2 || clean.length > 80) {
      notifyListeners();
      return false;
    }
    _recordRecentSearch(destination, clean);
    _persistCustomerState();
    notifyListeners();
    return true;
  }

  void clearRecentSearches(BuyV2Destination value) {
    if (_recentSearches.remove(value) == null) return;
    _persistCustomerState();
    notifyListeners();
  }

  void _recordRecentSearch(BuyV2Destination value, String clean) {
    if (value == BuyV2Destination.medicine) return;
    final values = _recentSearches.putIfAbsent(value, () => <String>[]);
    values.removeWhere(
      (candidate) => candidate.toLowerCase() == clean.toLowerCase(),
    );
    values.insert(0, clean);
    if (values.length > 6) values.removeRange(6, values.length);
  }

  List<BuyV2Product> savedProductsFor(BuyV2Destination value) {
    final destination = value == BuyV2Destination.orders
        ? BuyV2Destination.shop
        : value;
    return _knownCatalogueProducts
        .where(
          (product) =>
              product.destination == destination &&
              _savedKeys.contains(_buyV2SavedKey(product)),
        )
        .toList(growable: false);
  }

  int savedCountFor(BuyV2Destination value) => savedProductsFor(value).length;

  bool isSaved(String productId) {
    final item = findProduct(productId);
    return item != null && _savedKeys.contains(_buyV2SavedKey(item));
  }

  void toggleSaved(String productId) {
    final item = findProduct(productId);
    if (item == null) {
      notice = 'This product could not be found.';
      notifyListeners();
      return;
    }
    final key = _buyV2SavedKey(item);
    if (_savedKeys.remove(key)) {
      notice = '${item.title} removed from Saved.';
    } else {
      _savedKeys.add(key);
      notice = '${item.title} saved.';
    }
    _savedProductsMutationRevision += 1;
    _persistSavedProducts();
    _persistCustomerState();
    notifyListeners();
  }

  void clearSavedProducts(BuyV2Destination value) {
    final destination = value == BuyV2Destination.orders
        ? BuyV2Destination.shop
        : value;
    final removed = _savedKeys.where(
      (key) => key.startsWith('${destination.name}|'),
    );
    if (removed.isEmpty) return;
    _savedKeys.removeAll(removed.toList(growable: false));
    _savedProductsMutationRevision += 1;
    notice = '${destination.label} Saved products cleared.';
    _persistSavedProducts();
    _persistCustomerState();
    notifyListeners();
  }

  Future<void> restoreSavedProducts() async {
    final store = savedProductsStore;
    final ownerScope = store?.ownerScope;
    if (store == null ||
        ownerScope == null ||
        ownerScope == _savedProductsOwnerScope) {
      return;
    }
    _savedProductsOwnerScope = ownerScope;
    _savedKeys.clear();
    final mutationRevision = _savedProductsMutationRevision;
    notifyListeners();
    try {
      final stored = await store.read() ?? const <String>{};
      if (_collectionDisposed ||
          store.ownerScope != ownerScope ||
          mutationRevision != _savedProductsMutationRevision) {
        return;
      }
      final resolved = await _resolvePersistedCatalogueProducts(
        stored.map(_buyV2SavedListingId).whereType<String>().toSet(),
      );
      if (_collectionDisposed ||
          store.ownerScope != ownerScope ||
          mutationRevision != _savedProductsMutationRevision) {
        return;
      }
      _pagedProducts.addAll(resolved);
      final validKeys = _knownCatalogueProducts.map(_buyV2SavedKey).toSet();
      _savedKeys
        ..clear()
        ..addAll(stored.where(validKeys.contains));
      notifyListeners();
    } on Object {
      if (_collectionDisposed ||
          store.ownerScope != ownerScope ||
          mutationRevision != _savedProductsMutationRevision) {
        return;
      }
      if (store.ownerScope == ownerScope) {
        _savedProductsOwnerScope = null;
      }
      notice = 'Saved products could not be restored.';
      notifyListeners();
    }
  }

  Iterable<BuyV2Product> get _knownCatalogueProducts => <String, BuyV2Product>{
    for (final product in _catalogueProducts) product.id: product,
    ..._pagedProducts,
  }.values;

  Future<Map<String, BuyV2Product>> _resolvePersistedCatalogueProducts(
    Set<String> ids,
  ) async {
    final missing = ids.where((id) => findProduct(id) == null).toSet();
    if (missing.isEmpty) return {};
    final sources = <BuyV2CataloguePageSource>{
      ?cataloguePageSource,
      ..._deviceCatalogueSources.values,
    };
    if (sources.isEmpty) return {};
    final resolved = <String, BuyV2Product>{};
    for (final source in sources) {
      final pending = missing.where((id) => !resolved.containsKey(id)).toList();
      for (var start = 0; start < pending.length; start += 50) {
        final batch = pending.skip(start).take(50).toSet();
        final products = await _withCatalogueRequest(
          () => source.resolveProducts(batch),
        );
        if (_collectionDisposed) throw StateError('Buy session disposed');
        for (final product in products) {
          if (!batch.contains(product.id) || resolved.containsKey(product.id)) {
            throw const FormatException('Restored catalogue identity mismatch');
          }
          _validatePagedProduct(
            product,
            BuyV2CatalogueQuery(
              destination: product.destination,
              regionId: null,
              areaScope: BuyV2CatalogueAreaScope.allAreas,
            ),
          );
          resolved[product.id] = product;
        }
      }
    }
    if (!resolved.keys.toSet().containsAll(missing)) {
      throw StateError('Some retained products could not be restored');
    }
    return resolved;
  }

  void _persistSavedProducts() {
    final store = savedProductsStore;
    if (store == null) return;
    final snapshot = Set<String>.unmodifiable(_savedKeys);
    unawaited(
      store
          .write(snapshot)
          .then((saved) {
            if (!saved) {
              notice = 'Saved products could not be retained. Try again.';
              notifyListeners();
            }
          })
          .catchError((Object _) {
            notice = 'Saved products could not be retained. Try again.';
            notifyListeners();
          }),
    );
  }

  Future<void> restoreCustomerState() async {
    final store = customerStateStore;
    final ownerScope = store?.ownerScope;
    if (store == null ||
        ownerScope == null ||
        ownerScope == _customerStateOwnerScope) {
      return;
    }
    _customerStateOwnerScope = ownerScope;
    final mutationRevision = _customerStateMutationRevision;
    try {
      final snapshot = await store.read();
      if (snapshot == null ||
          _collectionDisposed ||
          store.ownerScope != ownerScope ||
          mutationRevision != _customerStateMutationRevision) {
        return;
      }
      final resolved = await _resolvePersistedCatalogueProducts({
        ...snapshot.cartQuantities.keys,
        ...snapshot.savedProductKeys
            .map(_buyV2SavedListingId)
            .whereType<String>(),
        ...snapshot.recentlyViewedProductIds.take(10),
      });
      if (_collectionDisposed ||
          store.ownerScope != ownerScope ||
          mutationRevision != _customerStateMutationRevision) {
        return;
      }
      _pagedProducts.addAll(resolved);
      _cart.clear();
      for (final entry in snapshot.cartQuantities.entries) {
        final product = findProduct(entry.key);
        if (product == null || entry.value < product.minimumOrder) continue;
        _cart[product.id] = BuyV2CartLine(
          product: product,
          quantity: entry.value,
        );
      }
      for (final order in snapshot.orders.reversed) {
        final validOrder =
            order.collection == null &&
            order.destination != BuyV2Destination.orders &&
            order.id.trim().isNotEmpty &&
            order.total >= 0 &&
            order.progress.isFinite &&
            order.progress >= 0 &&
            order.progress <= 1 &&
            !_orders.any((existing) => existing.id == order.id);
        if (validOrder) _orders.insert(0, order);
      }
      _addresses
        ..clear()
        ..addAll(snapshot.addresses);
      _selectedAddressId = snapshot.selectedAddressId;
      if (_selectedAddressId != null &&
          !_addresses.any((address) => address.id == _selectedAddressId)) {
        _selectedAddressId = null;
      }
      final validSavedKeys = _knownCatalogueProducts
          .map(_buyV2SavedKey)
          .toSet();
      _savedKeys
        ..clear()
        ..addAll(snapshot.savedProductKeys.where(validSavedKeys.contains));
      _deliveryInstructionIds
        ..clear()
        ..addAll(snapshot.deliveryInstructionIds);
      final storedPayment = snapshot.selectedPayment;
      if (storedPayment != null &&
          paymentMethods.contains(storedPayment) &&
          availablePaymentMethods.contains(storedPayment)) {
        selectedPayment = storedPayment;
      }
      purchaseOrderReference = snapshot.purchaseOrderReference ?? '';
      _checkoutIdempotencyKey = snapshot.checkoutIdempotencyKey;
      _paymentReference = snapshot.paymentReference;
      _paymentActionUri = snapshot.paymentActionUri;
      _bankTransferInstructions = snapshot.bankTransferInstructions;
      activeShoppingIntent = BuyV2ShoppingIntent.values
          .where((intent) => intent.name == snapshot.shoppingIntent)
          .firstOrNull;
      // Browsing filters belong to the current catalogue, not account defaults.
      // Ignore historical stored filters without resetting a live browse draft.
      final validRecentIds = _knownCatalogueProducts
          .where(
            (product) =>
                product.destination == BuyV2Destination.shop ||
                product.destination == BuyV2Destination.wholesale,
          )
          .map((product) => product.id)
          .toSet();
      _recentlyViewedProductIds
        ..clear()
        ..addAll(
          snapshot.recentlyViewedProductIds
              .where(validRecentIds.contains)
              .toSet()
              .take(10),
        );
      _recentSearches.clear();
      for (final entry in snapshot.recentSearches.entries) {
        if (entry.key != BuyV2Destination.shop &&
            entry.key != BuyV2Destination.wholesale &&
            entry.key != BuyV2Destination.orders) {
          continue;
        }
        final seen = <String>{};
        final values = <String>[];
        for (final value in entry.value) {
          final clean = value.trim().replaceAll(RegExp(r'\s+'), ' ');
          if (clean.length < 2 || clean.length > 80) continue;
          if (!seen.add(clean.toLowerCase())) continue;
          values.add(clean);
          if (values.length == 6) break;
        }
        if (values.isNotEmpty) _recentSearches[entry.key] = values;
      }
      final storedSubmissionState = BuyV2CheckoutSubmissionState.values
          .where((state) => state.name == snapshot.checkoutSubmissionState)
          .firstOrNull;
      checkoutSubmissionState = switch (storedSubmissionState) {
        BuyV2CheckoutSubmissionState.submitting
            when _paymentReference != null =>
          BuyV2CheckoutSubmissionState.paymentUnknown,
        BuyV2CheckoutSubmissionState.submitting =>
          BuyV2CheckoutSubmissionState.failed,
        final state? => state,
        null => BuyV2CheckoutSubmissionState.idle,
      };
      if (checkoutRequiresResolution) {
        // Retired choices cannot start a new payment, but an unresolved
        // persisted attempt must keep its original provider identity.
        if (const {'Bank transfer', 'UPI'}.contains(storedPayment)) {
          selectedPayment = storedPayment!;
        }
        checkoutStep = BuyV2CheckoutStep.payment;
      }
      _pruneCartSelections();
      notifyListeners();
    } on Object {
      if (_collectionDisposed ||
          store.ownerScope != ownerScope ||
          mutationRevision != _customerStateMutationRevision) {
        return;
      }
      if (store.ownerScope == ownerScope) _customerStateOwnerScope = null;
      notice = 'Your Shop choices could not be restored. Try again.';
      notifyListeners();
    }
  }

  void _persistCustomerState() {
    final store = customerStateStore;
    if (store == null || store.ownerScope == null) return;
    _customerStateMutationRevision += 1;
    final snapshot = BuyV2CustomerStateSnapshot(
      cartQuantities: Map.unmodifiable({
        for (final line in _cart.values) line.product.id: line.quantity,
      }),
      addresses: List.unmodifiable(_addresses),
      selectedAddressId: _selectedAddressId,
      savedProductKeys: Set.unmodifiable(_savedKeys),
      deliveryInstructionIds: Map.unmodifiable(_deliveryInstructionIds),
      selectedPayment: selectedPayment.isEmpty ? null : selectedPayment,
      purchaseOrderReference: purchaseOrderReference.trim().isEmpty
          ? null
          : purchaseOrderReference.trim(),
      checkoutIdempotencyKey: _checkoutIdempotencyKey,
      paymentReference: _paymentReference,
      paymentActionUri: _paymentActionUri,
      bankTransferInstructions: _bankTransferInstructions,
      shoppingIntent: activeShoppingIntent?.name,
      checkoutSubmissionState: checkoutSubmissionState.name,
      recentlyViewedProductIds: List.unmodifiable(_recentlyViewedProductIds),
      recentSearches: Map<BuyV2Destination, List<String>>.unmodifiable({
        for (final entry in _recentSearches.entries)
          entry.key: List<String>.unmodifiable(entry.value),
      }),
      orders: List.unmodifiable(
        _orders.where(
          (order) =>
              // The legacy cache codec cannot preserve collection identity.
              // Collection orders must be restored by authenticated commerce.
              order.collection == null &&
              (order.purchaseId?.trim().isNotEmpty == true ||
                  order.id.contains('-NEW-')),
        ),
      ),
    );
    unawaited(
      store
          .write(snapshot)
          .then((saved) {
            if (!saved) {
              notice = 'Your Shop choices could not be retained. Try again.';
              notifyListeners();
            }
          })
          .catchError((Object _) {
            notice = 'Your Shop choices could not be retained. Try again.';
            notifyListeners();
          }),
    );
  }

  List<BuyV2CartLine> get cartLines {
    final lines = _linesForScope(cartScope);
    return List.unmodifiable(lines);
  }

  double cartScrollOffsetFor(BuyV2CartScope scope) =>
      _cartScrollOffsets[scope] ?? 0;

  void rememberCartScrollOffset(BuyV2CartScope scope, double offset) {
    if (!offset.isFinite) return;
    _cartScrollOffsets[scope] = offset < 0 ? 0 : offset;
  }

  List<BuyV2CartLine> get checkoutLines {
    final pending = collectionCheckout?.intent;
    if (collectionCheckoutSelected &&
        collectionCheckout?.unresolved == true &&
        pending != null) {
      return pending.basket.lines;
    }
    return List.unmodifiable(
      _linesForScope(checkoutScope).where(
        (line) =>
            !collectionCheckoutSelected ||
            line.product.storeId == _collectionCheckoutStoreId,
      ),
    );
  }

  bool get collectionCheckoutSelected => _collectionCheckoutSelected;

  List<BuyV2StoreListing> get collectionCheckoutStores => [
    for (final id in _linesForScope(
      checkoutScope,
    ).map((line) => line.product.storeId).whereType<String>().toSet())
      if (_pagedStores[id] case final store?)
        if (store.collection?.isSupportedFor(id, now: catalogueNow()) == true)
          store,
  ];

  BuyV2StoreListing? get collectionCheckoutStore =>
      collectionCheckout?.unresolved == true
      ? collectionCheckout?.intent?.basket.store
      : _pagedStores[_collectionCheckoutStoreId];

  BuyV2CollectionCheckoutQuote? get collectionCheckoutQuote {
    final value = collectionCheckout?.quote;
    if (collectionCheckout?.unresolved == true) return value;
    final basket = currentCollectionBasket;
    return value != null && basket != null && value.matches(basket)
        ? value
        : null;
  }

  String? get collectionCheckoutMessage {
    if (!collectionCheckoutSelected) return null;
    if (collectionCheckout?.message case final value?) return value;
    if (collectionIdentity?.value == null) {
      return 'Sign in to place a store collection order.';
    }
    if (collectionCheckout?.available != true) {
      return 'Store collection is unavailable right now. Your Cart has not changed.';
    }
    if (collectionCheckoutStore == null) {
      return 'Choose the store where you will collect.';
    }
    if (collectionCheckoutStore!.collection?.isSupportedFor(
          collectionCheckoutStore!.id,
          now: catalogueNow(),
        ) !=
        true) {
      return 'Check this store’s collection availability to continue.';
    }
    final quote = collectionCheckout?.quote;
    final basket = currentCollectionBasket;
    if (quote != null &&
        basket != null &&
        quote.matches(basket) &&
        !quote.isCurrentFor(basket, catalogueNow())) {
      return 'Your total needs updating. Review it before paying.';
    }
    return null;
  }

  void _onCollectionCheckoutChanged() {
    if (_collectionDisposed) return;
    final pending = collectionCheckout?.intent;
    if (collectionCheckout?.unresolved == true && pending != null) {
      _collectionCheckoutSelected = true;
      _collectionCheckoutStoreId = pending.basket.store.id;
    }
    notifyListeners();
  }

  bool chooseCheckoutCollection(bool selected, {String? storeId}) {
    if (view != BuyV2View.checkout ||
        checkoutBusy ||
        checkoutRequiresResolution) {
      return false;
    }
    final stores = collectionCheckoutStores;
    if (selected && stores.isEmpty) return false;
    if (storeId != null && !stores.any((store) => store.id == storeId)) {
      return false;
    }
    _collectionCheckoutSelected = selected;
    _collectionCheckoutStoreId = selected
        ? storeId ?? (stores.length == 1 ? stores.single.id : null)
        : null;
    checkoutStep = BuyV2CheckoutStep.address;
    notice = null;
    notifyListeners();
    return true;
  }

  BuyV2CollectionBasket? get currentCollectionBasket {
    final buyer = collectionIdentity?.value;
    final store = collectionCheckoutStore;
    if (!collectionCheckoutSelected || buyer == null || store == null) {
      return null;
    }
    try {
      return BuyV2CollectionBasket(
        identity: buyer,
        store: store,
        lines: checkoutLines,
        paymentMethod: selectedPayment,
      );
    } on FormatException {
      return null;
    }
  }

  Future<bool> prepareCollectionCheckout() async {
    if (view != BuyV2View.checkout ||
        checkoutBusy ||
        !collectionCheckoutSelected) {
      return false;
    }
    final basket = currentCollectionBasket;
    final controller = collectionCheckout;
    if (basket == null ||
        controller == null ||
        !availablePaymentMethods.contains(selectedPayment)) {
      notice =
          collectionCheckoutMessage ??
          'Choose an available payment method to continue.';
      notifyListeners();
      return false;
    }
    final ready = await controller.prepare(basket);
    if (_collectionDisposed) return false;
    if (controller.phase == BuyV2CollectionCheckoutPhase.paid) {
      return _completeCollectionPurchase();
    }
    if (ready &&
        view == BuyV2View.checkout &&
        collectionCheckoutSelected &&
        currentCollectionBasket?.fingerprint == basket.fingerprint) {
      checkoutStep = BuyV2CheckoutStep.confirm;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> submitCollectionPurchase() async {
    if (view != BuyV2View.checkout ||
        checkoutStep != BuyV2CheckoutStep.confirm ||
        checkoutBusy) {
      return false;
    }
    final basket = currentCollectionBasket;
    if (basket == null || collectionCheckout == null) return false;
    final paid = await collectionCheckout!.place(basket);
    if (_collectionDisposed) return false;
    if (paid) return _completeCollectionPurchase();
    if (view == BuyV2View.checkout && collectionCheckoutSelected) {
      if (collectionCheckout!.unresolved) {
        checkoutStep = BuyV2CheckoutStep.payment;
      }
      notifyListeners();
    }
    return false;
  }

  Future<bool> reconcileCollectionPurchase() async {
    final paid = await collectionCheckout?.checkPayment() ?? false;
    return !_collectionDisposed && paid && _completeCollectionPurchase();
  }

  Future<bool> continueCollectionPayment(BuyV2PaymentHandoff handoff) async {
    final paid = await collectionCheckout?.continuePayment(handoff) ?? false;
    return !_collectionDisposed && paid && _completeCollectionPurchase();
  }

  bool _canAdmitCollectionPurchase(
    BuyV2CollectionPurchaseIntent intent,
    ScanPickSnapshot snapshot,
  ) {
    final existing = _orders
        .where((order) => order.id == snapshot.orderId)
        .firstOrNull;
    return existing == null ||
        (existing.collection?.storeId == snapshot.storeId &&
            existing.collection?.purchaserAccountId ==
                snapshot.purchaserAccountId &&
            (existing.totalMinor ?? existing.total * 100) ==
                snapshot.totalMinor);
  }

  bool _completeCollectionPurchase() {
    final controller = collectionCheckout;
    final snapshot = controller?.paidOrder;
    final intent = controller?.intent;
    final result = controller?.result;
    if (controller?.phase != BuyV2CollectionCheckoutPhase.paid ||
        snapshot == null ||
        intent == null ||
        result == null ||
        collectionIdentity?.value?.accountId != snapshot.purchaserAccountId ||
        !result.matchesPaidOrder(intent, snapshot) ||
        !_canAdmitCollectionPurchase(intent, snapshot)) {
      controller?.requireReconciliation();
      return false;
    }
    final newlyAdmitted = !_orders.any((order) => order.id == snapshot.orderId);
    if (newlyAdmitted) {
      final lines = intent.basket.lines;
      _orders.insert(
        0,
        BuyV2Order(
          id: snapshot.orderId,
          destination: lines.first.product.destination,
          title: snapshot.storeName,
          itemSummary: '${lines.length} products',
          total: snapshot.totalMinor ~/ 100,
          totalMinor: snapshot.totalMinor,
          partner: snapshot.storeName,
          partnerType: lines.first.product.partnerRole,
          promise: 'Collect at store',
          destinationLabel: intent.basket.store.address,
          progress: 0,
          status: BuyV2OrderStatus.preparing,
          collection: BuyV2CollectionOrderReference(
            storeId: snapshot.storeId,
            purchaserAccountId: snapshot.purchaserAccountId,
          ),
          purchaseId: result.purchaseId,
          productIds: List.unmodifiable(lines.map((line) => line.product.id)),
          lines: lines,
          paymentMethod: intent.basket.paymentMethod,
          paymentStatusLabel: 'Paid',
          invoiceAvailable: false,
        ),
      );
      for (final line in lines) {
        final current = _cart[line.product.id];
        if (current == null ||
            current.product.storeId != line.product.storeId ||
            current.product.canonicalId != line.product.canonicalId ||
            current.product.pack != line.product.pack) {
          continue;
        }
        final remaining = current.quantity - line.quantity;
        if (remaining > 0) {
          _cart[line.product.id] = current.copyWith(quantity: remaining);
        } else {
          _cart.remove(line.product.id);
        }
      }
      _pruneCartSelections();
    }
    _collectionStates[snapshot.orderId] = _BuyV2CollectionState()
      ..snapshot = snapshot
      ..refreshRequired = true
      ..elapsed.start();
    final shouldOpen = view == BuyV2View.checkout && collectionCheckoutSelected;
    _collectionCheckoutSelected = false;
    _collectionCheckoutStoreId = null;
    checkoutSubmissionState = BuyV2CheckoutSubmissionState.idle;
    _persistCustomerState();
    if (shouldOpen) return openTracking(snapshot.orderId);
    notifyListeners();
    return true;
  }

  List<BuyV2CartLine> _linesForScope(BuyV2CartScope scope) =>
      _cart.values.where((line) {
        return switch (scope) {
          BuyV2CartScope.all => true,
          BuyV2CartScope.shop =>
            line.product.destination == BuyV2Destination.shop,
          BuyV2CartScope.wholesale =>
            line.product.destination == BuyV2Destination.wholesale,
          BuyV2CartScope.medicine =>
            line.product.destination == BuyV2Destination.medicine,
        };
      }).toList();

  int countForDestination(BuyV2Destination value) => _cart.values
      .where((line) => line.product.destination == value)
      .fold(0, (total, line) => total + line.quantity);

  int productCountForDestination(BuyV2Destination value) =>
      _cart.values.where((line) => line.product.destination == value).length;

  int totalForDestination(BuyV2Destination value) => _cart.values
      .where((line) => line.product.destination == value)
      .fold(0, (total, line) => total + line.total);

  int get itemCount =>
      _cart.values.fold(0, (total, line) => total + line.quantity);

  int get cartTotal =>
      _cart.values.fold(0, (total, line) => total + line.total);

  int get scopedItemCount =>
      cartLines.fold(0, (total, line) => total + line.quantity);

  int get scopedCartTotal =>
      cartLines.fold(0, (total, line) => total + line.total);

  int get scopedCartListPriceTotal => cartLines.fold(0, (total, line) {
    final product = line.product;
    final listPrice = product.mrp != null && product.mrp! > product.price
        ? product.mrp!
        : product.price;
    return total + (listPrice * line.quantity);
  });

  int get scopedCartSavings => scopedCartListPriceTotal - scopedCartTotal;

  Map<BuyV2Destination, int> get scopedCartFamilyTotals => Map.unmodifiable({
    for (final destination in const [
      BuyV2Destination.shop,
      BuyV2Destination.wholesale,
      BuyV2Destination.medicine,
    ])
      if (cartLines.any((line) => line.product.destination == destination))
        destination: cartLines
            .where((line) => line.product.destination == destination)
            .fold(0, (total, line) => total + line.total),
  });

  Set<BuyV2Destination> get cartDestinations => Set.unmodifiable(
    _cart.values.map((line) => line.product.destination).toSet(),
  );

  Set<BuyV2Destination> get checkoutDestinations => Set.unmodifiable(
    checkoutLines.map((line) => line.product.destination).toSet(),
  );

  int get checkoutItemCount =>
      checkoutLines.fold(0, (total, line) => total + line.quantity);

  int get checkoutTotal =>
      checkoutLines.fold(0, (total, line) => total + line.total);

  List<BuyV2FulfilmentGroup> get scopedCartFulfilmentGroups =>
      _fulfilmentGroupsFor(cartLines);

  List<BuyV2FulfilmentGroup> get checkoutFulfilmentGroups =>
      _fulfilmentGroupsFor(checkoutLines);

  List<BuyV2FulfilmentGroup> _fulfilmentGroupsFor(List<BuyV2CartLine> lines) {
    final grouped = <String, List<BuyV2CartLine>>{};
    for (final line in lines) {
      final product = line.product;
      final facts = productFactsFor(product);
      final mode = fulfilmentModeFor(product);
      final promise = facts.deliveryPromise.trim().toLowerCase();
      final promisedBy = facts.promisedByLabel?.trim().toLowerCase() ?? '';
      final key =
          '${product.destination.name}|${product.seller}|'
          '${mode.name}|$promise|$promisedBy';
      grouped.putIfAbsent(key, () => []).add(line);
    }
    return grouped.values
        .map((lines) {
          final facts = lines
              .map((line) => productFactsFor(line.product))
              .toList(growable: false);
          final promisedByLabels = facts
              .map((fact) => fact.promisedByLabel?.trim())
              .whereType<String>()
              .where((label) => label.isNotEmpty)
              .toSet();
          final dispatchPromises = facts
              .map((fact) => fact.dispatchPromise?.trim())
              .whereType<String>()
              .where((value) => value.isNotEmpty)
              .toSet();
          final deliveryProviders = facts
              .map((fact) => fact.deliveryProviderName?.trim())
              .whereType<String>()
              .where((value) => value.isNotEmpty)
              .toSet();
          final serviceLevels = facts
              .map((fact) => fact.deliveryServiceLevel?.trim())
              .whereType<String>()
              .where((value) => value.isNotEmpty)
              .toSet();
          final firstProduct = lines.first.product;
          final stableProductIds =
              lines.map((line) => line.product.id).toList(growable: false)
                ..sort();
          return BuyV2FulfilmentGroup(
            groupKey:
                '${firstProduct.destination.name}|${firstProduct.seller}|'
                '${fulfilmentModeFor(firstProduct).name}|${stableProductIds.join(',')}',
            destination: firstProduct.destination,
            partner: firstProduct.seller,
            partnerType: firstProduct.partnerRole,
            promise: facts
                .map((fact) => fact.deliveryPromise)
                .toSet()
                .join(' · '),
            promisedByLabel: promisedByLabels.isEmpty
                ? null
                : promisedByLabels.join(' · '),
            dispatchPromise: dispatchPromises.isEmpty
                ? null
                : dispatchPromises.join(' · '),
            deliveryProviderName: deliveryProviders.isEmpty
                ? null
                : deliveryProviders.join(' · '),
            deliveryServiceLevel: serviceLevels.isEmpty
                ? null
                : serviceLevels.join(' · '),
            lines: List.unmodifiable(lines),
          );
        })
        .toList(growable: false);
  }

  Map<String, _BuyV2DeliveryPromiseQuote> _deliveryPromiseSnapshotFor(
    List<BuyV2FulfilmentGroup> groups,
  ) => {
    for (final group in groups)
      group.key: _BuyV2DeliveryPromiseQuote(
        promise: group.promise,
        promisedByLabel: group.promisedByLabel,
      ),
  };

  void _captureCheckoutPromiseSnapshot() {
    _checkoutPromiseSnapshot = _deliveryPromiseSnapshotFor(
      checkoutFulfilmentGroups,
    );
    _pendingCheckoutPromiseSnapshot = null;
    _checkoutDeliveryPromiseChanges = [];
  }

  void _clearCheckoutPromiseSnapshot() {
    _checkoutPromiseSnapshot = {};
    _pendingCheckoutPromiseSnapshot = null;
    _checkoutDeliveryPromiseChanges = [];
    _checkoutPriceChanges = [];
    _checkoutAvailabilityIssue = null;
    _invalidateCheckoutQuote();
    _invalidateCommercialPaymentTerms();
  }

  int tipForGroup(BuyV2FulfilmentGroup group) =>
      _tipsByFulfilmentKey[group.key] ?? 0;

  int get scopedTipTotal => scopedCartFulfilmentGroups.fold(
    0,
    (total, group) => total + tipForGroup(group),
  );

  int get checkoutTipTotal => checkoutFulfilmentGroups.fold(
    0,
    (total, group) => total + tipForGroup(group),
  );

  int couponSavingForDestination(BuyV2Destination destination) {
    final coupon = selectedCartBenefit(
      kind: BuyV2CartBenefitKind.coupon,
      destination: destination,
    );
    if (coupon == null) return 0;
    return coupon.savingAmount.clamp(0, totalForDestination(destination));
  }

  int get scopedCouponSaving => cartLines
      .map((line) => line.product.destination)
      .toSet()
      .fold(
        0,
        (total, destination) => total + couponSavingForDestination(destination),
      );

  int get checkoutCouponSaving => checkoutDestinations.fold(
    0,
    (total, destination) => total + couponSavingForDestination(destination),
  );

  Map<String, int> _checkoutGroupCouponSavings() {
    final remainingDiscount = {
      for (final destination in checkoutDestinations)
        destination: couponSavingForDestination(destination),
    };
    return Map.unmodifiable({
      for (final group in checkoutFulfilmentGroups)
        group.key: () {
          final available = remainingDiscount[group.destination] ?? 0;
          final discount = available > group.total ? group.total : available;
          remainingDiscount[group.destination] = available - discount;
          return discount;
        }(),
    });
  }

  Map<String, int> _checkoutGroupPayables() {
    if (checkoutQuoteLoadState == BuyV2CommerceLoadState.ready &&
        _checkoutQuote != null) {
      return Map.unmodifiable({
        for (final line in _checkoutQuote!.lines)
          line.fulfilmentKey: line.total,
      });
    }
    final discountByKey = _checkoutGroupCouponSavings();
    return Map.unmodifiable({
      for (final group in checkoutFulfilmentGroups)
        group.key:
            group.total + tipForGroup(group) - (discountByKey[group.key] ?? 0),
    });
  }

  int get scopedPayableTotal =>
      (scopedCartTotal + scopedTipTotal - scopedCouponSaving).clamp(
        0,
        scopedCartTotal + scopedTipTotal,
      );

  int get calculatedCheckoutPayableTotal =>
      (checkoutTotal + checkoutTipTotal - checkoutCouponSaving).clamp(
        0,
        checkoutTotal + checkoutTipTotal,
      );

  BuyV2CheckoutQuote? get checkoutQuote => _checkoutQuote;

  int get checkoutPayableTotal =>
      checkoutQuoteLoadState == BuyV2CommerceLoadState.ready &&
          _checkoutQuote != null
      ? _checkoutQuote!.total
      : calculatedCheckoutPayableTotal;

  List<BuyV2TipOption> tipOptionsFor(BuyV2Destination destination) =>
      List.unmodifiable(tipPolicy.optionsFor(destination));

  bool chooseTip({
    required String fulfilmentKey,
    required BuyV2Destination destination,
    required int amount,
  }) {
    final group = _fulfilmentGroupsFor(
      _cart.values.toList(),
    ).where((candidate) => candidate.key == fulfilmentKey).firstOrNull;
    if (group == null ||
        group.destination != destination ||
        !tipPolicy.accepts(destination, amount)) {
      notice = 'This tip option is not available.';
      notifyListeners();
      return false;
    }
    if (amount == 0) {
      _tipsByFulfilmentKey.remove(fulfilmentKey);
    } else {
      _tipsByFulfilmentKey[fulfilmentKey] = amount;
    }
    _invalidateAndRefreshCheckoutPricingContracts();
    notice = null;
    notifyListeners();
    return true;
  }

  List<BuyV2DeliveryInstructionOption> deliveryInstructionsFor(
    BuyV2Destination destination,
  ) => buyV2DeliveryInstructionsFor(destination);

  BuyV2DeliveryInstructionOption? selectedDeliveryInstructionFor(
    BuyV2Destination destination,
  ) {
    final id = _deliveryInstructionIds[destination];
    if (id == null) return null;
    return buyV2DeliveryInstructionOptions
        .where((option) => option.id == id && option.destination == destination)
        .firstOrNull;
  }

  bool chooseDeliveryInstruction({
    required BuyV2Destination destination,
    required String? instructionId,
  }) {
    if (instructionId == null) {
      _deliveryInstructionIds.remove(destination);
      notice = null;
      _persistCustomerState();
      notifyListeners();
      return true;
    }
    final valid = buyV2DeliveryInstructionOptions.any(
      (option) =>
          option.id == instructionId && option.destination == destination,
    );
    if (!valid ||
        !_cart.values.any((line) => line.product.destination == destination)) {
      notice = 'This delivery instruction is not available.';
      notifyListeners();
      return false;
    }
    _deliveryInstructionIds[destination] = instructionId;
    notice = null;
    _persistCustomerState();
    notifyListeners();
    return true;
  }

  bool get liveCartBenefitsEnabled =>
      cartBenefitsAdapter is BuyV2LiveCartBenefitsAdapter;

  bool get cartBenefitsBusy =>
      cartBenefitsLoadState == BuyV2CartBenefitsLoadState.loading;

  BuyV2CartBenefitsLoadState productBenefitsStateFor(BuyV2Product product) {
    if (!liveCartBenefitsEnabled) return BuyV2CartBenefitsLoadState.ready;
    return _productBenefitStates[product.id] ?? BuyV2CartBenefitsLoadState.idle;
  }

  String? productBenefitsMessageFor(BuyV2Product product) =>
      _productBenefitMessages[product.id];

  List<BuyV2CartBenefit> productBenefitsFor(BuyV2Product product) {
    if (liveCartBenefitsEnabled) {
      return List.unmodifiable(_productBenefits[product.id] ?? const []);
    }
    final total = productFactsFor(product).price * product.minimumOrder;
    final candidates = [
      for (final kind in BuyV2CartBenefitKind.values)
        ...cartBenefitsAdapter.benefitsFor(
          kind: kind,
          destinations: {product.destination},
          itemTotal: total,
        ),
    ];
    return _validatedProductBenefits(
      product,
      candidates,
      evaluatedAt: DateTime.now(),
    );
  }

  Future<bool> refreshProductBenefits(String productId) async {
    final product = findProduct(productId);
    if (product == null) {
      notice = 'This product could not be found.';
      notifyListeners();
      return false;
    }
    final adapter = cartBenefitsAdapter;
    if (adapter is! BuyV2LiveCartBenefitsAdapter) {
      _productBenefits[product.id] = productBenefitsFor(product);
      _productBenefitStates[product.id] = BuyV2CartBenefitsLoadState.ready;
      _productBenefitMessages.remove(product.id);
      notifyListeners();
      return true;
    }
    final sequence = ++_productBenefitRequestSequence;
    _productBenefitRequestSequences[product.id] = sequence;
    final fingerprint = _productBenefitFingerprint(product);
    _productBenefits.remove(product.id);
    _productBenefitStates[product.id] = BuyV2CartBenefitsLoadState.loading;
    _productBenefitMessages.remove(product.id);
    notifyListeners();
    try {
      final snapshot = await adapter.loadEligibility(
        BuyV2CartBenefitsRequest(
          lines: [
            BuyV2CartLine(product: product, quantity: product.minimumOrder),
          ],
          selectedPaymentMethod: selectedPayment,
        ),
      );
      if (_collectionDisposed ||
          _productBenefitRequestSequences[product.id] != sequence ||
          _productBenefitFingerprint(product) != fingerprint) {
        return false;
      }
      _productBenefitStates[product.id] = snapshot.state;
      if (snapshot.customerMessage case final message?) {
        _productBenefitMessages[product.id] = message;
      } else {
        _productBenefitMessages.remove(product.id);
      }
      if (snapshot.state != BuyV2CartBenefitsLoadState.ready) {
        _productBenefits.remove(product.id);
        notifyListeners();
        return false;
      }
      _productBenefits[product.id] = _validatedProductBenefits(
        product,
        snapshot.benefits,
        evaluatedAt: snapshot.evaluatedAt,
      );
      notifyListeners();
      return true;
    } on Object {
      if (_collectionDisposed ||
          _productBenefitRequestSequences[product.id] != sequence) {
        return false;
      }
      _productBenefits.remove(product.id);
      _productBenefitStates[product.id] =
          BuyV2CartBenefitsLoadState.unavailable;
      _productBenefitMessages[product.id] =
          'Product offers could not be checked. Try again.';
      notifyListeners();
      return false;
    }
  }

  String _productBenefitFingerprint(BuyV2Product product) =>
      '${product.id}:${product.minimumOrder}:${productFactsFor(product).price}:'
      '$selectedPayment';

  List<BuyV2CartBenefit> _validatedProductBenefits(
    BuyV2Product product,
    List<BuyV2CartBenefit> benefits, {
    required DateTime evaluatedAt,
  }) {
    final total = productFactsFor(product).price * product.minimumOrder;
    final ids = <String>{};
    return List.unmodifiable([
      for (final benefit in benefits)
        if (benefit.destination == product.destination &&
            benefit.id.trim().isNotEmpty &&
            benefit.title.trim().isNotEmpty &&
            benefit.detail.trim().isNotEmpty &&
            benefit.sourceId.trim().isNotEmpty &&
            benefit.sponsorName.trim().isNotEmpty &&
            benefit.savingAmount >= 0 &&
            benefit.savingAmount <= total &&
            (benefit.kind == BuyV2CartBenefitKind.coupon ||
                benefit.savingAmount == 0) &&
            _liveBenefitMatchesStrategy(
              benefit,
              evaluatedAt: evaluatedAt,
              destinationTotal: total,
              destinationQuantity: product.minimumOrder,
            ) &&
            ids.add('${benefit.kind.name}|${benefit.id}'))
          benefit,
    ]);
  }

  String _cartBenefitsFingerprint() => _cart.values
      .map(
        (line) => '${line.product.id}:${line.quantity}:${line.product.price}',
      )
      .followedBy([selectedPayment])
      .join('|');

  Future<bool> refreshCartBenefits() async {
    final adapter = cartBenefitsAdapter;
    if (adapter is! BuyV2LiveCartBenefitsAdapter) return true;
    if (_cart.isEmpty) {
      _liveCartBenefits = [];
      cartBenefitsLoadState = BuyV2CartBenefitsLoadState.ready;
      cartBenefitsMessage = null;
      _invalidateAndRefreshCheckoutPricingContracts();
      notifyListeners();
      return true;
    }
    final requestSequence = ++_cartBenefitsRequestSequence;
    final fingerprint = _cartBenefitsFingerprint();
    cartBenefitsLoadState = BuyV2CartBenefitsLoadState.loading;
    cartBenefitsMessage = null;
    notifyListeners();
    try {
      final snapshot = await adapter.loadEligibility(
        BuyV2CartBenefitsRequest(
          lines: List.unmodifiable(_cart.values),
          selectedPaymentMethod: selectedPayment,
        ),
      );
      if (requestSequence != _cartBenefitsRequestSequence ||
          fingerprint != _cartBenefitsFingerprint()) {
        return false;
      }
      cartBenefitsLoadState = snapshot.state;
      cartBenefitsMessage = snapshot.customerMessage;
      if (snapshot.state != BuyV2CartBenefitsLoadState.ready) {
        _liveCartBenefits = [];
        _invalidateAndRefreshCheckoutPricingContracts();
        notifyListeners();
        return !_hasSelectedCartBenefitReference;
      }
      _liveCartBenefits = _validatedLiveCartBenefits(snapshot);
      final removedSelection = _removeIneligibleCartBenefitSelections();
      if (removedSelection) {
        cartBenefitsMessage =
            'A selected coupon or offer is no longer eligible. Review the current options.';
      }
      _invalidateAndRefreshCheckoutPricingContracts();
      notifyListeners();
      return !removedSelection;
    } on Object {
      if (requestSequence != _cartBenefitsRequestSequence) return false;
      _liveCartBenefits = [];
      cartBenefitsLoadState = BuyV2CartBenefitsLoadState.unavailable;
      cartBenefitsMessage =
          'Coupons and offers could not be checked. Try again.';
      _invalidateAndRefreshCheckoutPricingContracts();
      notifyListeners();
      return !_hasSelectedCartBenefitReference;
    }
  }

  List<BuyV2CartBenefit> _validatedLiveCartBenefits(
    BuyV2CartBenefitsSnapshot snapshot,
  ) {
    final destinations = cartDestinations;
    final totals = {
      for (final destination in destinations)
        destination: totalForDestination(destination),
    };
    final quantities = {
      for (final destination in destinations)
        destination: countForDestination(destination),
    };
    final ids = <String>{};
    return List.unmodifiable([
      for (final benefit in snapshot.benefits)
        if (destinations.contains(benefit.destination) &&
            benefit.id.trim().isNotEmpty &&
            benefit.title.trim().isNotEmpty &&
            benefit.detail.trim().isNotEmpty &&
            benefit.sourceId.trim().isNotEmpty &&
            benefit.sponsorName.trim().isNotEmpty &&
            benefit.savingAmount >= 0 &&
            benefit.savingAmount <= (totals[benefit.destination] ?? 0) &&
            (benefit.kind == BuyV2CartBenefitKind.coupon ||
                benefit.savingAmount == 0) &&
            _liveBenefitMatchesStrategy(
              benefit,
              evaluatedAt: snapshot.evaluatedAt,
              destinationTotal: totals[benefit.destination] ?? 0,
              destinationQuantity: quantities[benefit.destination] ?? 0,
            ) &&
            ids.add(
              '${benefit.destination.name}|${benefit.kind.name}|${benefit.id}',
            ))
          benefit,
    ]);
  }

  bool _liveBenefitMatchesStrategy(
    BuyV2CartBenefit benefit, {
    required DateTime evaluatedAt,
    required int destinationTotal,
    required int destinationQuantity,
  }) {
    if (benefit.validFrom case final validFrom?
        when evaluatedAt.isBefore(validFrom)) {
      return false;
    }
    if (benefit.validUntil case final validUntil?
        when !evaluatedAt.isBefore(validUntil)) {
      return false;
    }
    if (benefit.minimumSpend case final minimumSpend?
        when minimumSpend <= 0 || destinationTotal < minimumSpend) {
      return false;
    }
    if (benefit.minimumQuantity case final minimumQuantity?
        when minimumQuantity <= 0 || destinationQuantity < minimumQuantity) {
      return false;
    }
    return switch (benefit.strategy) {
      BuyV2CartBenefitStrategy.timedSale => benefit.validUntil != null,
      BuyV2CartBenefitStrategy.publishedOffer =>
        benefit.offerId?.trim().isNotEmpty ?? false,
      BuyV2CartBenefitStrategy.minimumOrder =>
        benefit.minimumSpend != null || benefit.minimumQuantity != null,
      BuyV2CartBenefitStrategy.loadBased => benefit.minimumQuantity != null,
      BuyV2CartBenefitStrategy.financialProduct =>
        (benefit.sponsor == BuyV2CartBenefitSponsor.bank ||
                benefit.sponsor == BuyV2CartBenefitSponsor.financialPartner) &&
            (benefit.eligiblePaymentMethods.isEmpty ||
                benefit.eligiblePaymentMethods.contains(selectedPayment)),
      BuyV2CartBenefitStrategy.partnerCampaign => true,
      BuyV2CartBenefitStrategy.freeDelivery => benefit.freeDelivery,
    };
  }

  bool get _hasSelectedCartBenefitReference =>
      _selectedCartBenefitRefs.isNotEmpty;

  bool _removeIneligibleCartBenefitSelections() {
    var removed = false;
    _selectedCartBenefitRefs.removeWhere((key, selection) {
      final available = _liveCartBenefits.any(
        (benefit) =>
            key ==
                _cartBenefitSelectionKey(benefit.destination, benefit.kind) &&
            selection.benefitId == benefit.id &&
            selection.sourceId == benefit.sourceId,
      );
      if (!available) removed = true;
      return !available;
    });
    return removed;
  }

  void _invalidateLiveCartBenefits() {
    if (!liveCartBenefitsEnabled) return;
    _cartBenefitsRequestSequence += 1;
    _liveCartBenefits = [];
    cartBenefitsLoadState = _cart.isEmpty
        ? BuyV2CartBenefitsLoadState.ready
        : BuyV2CartBenefitsLoadState.idle;
    cartBenefitsMessage = null;
  }

  bool get checkoutQuoteEnabled => checkoutQuoteAdapter != null;

  bool get checkoutQuoteBusy =>
      checkoutQuoteLoadState == BuyV2CommerceLoadState.loading;

  bool get checkoutQuoteReviewRequired {
    if (!checkoutQuoteEnabled) return false;
    final quote = _checkoutQuote;
    return checkoutQuoteLoadState != BuyV2CommerceLoadState.ready ||
        quote == null ||
        !DateTime.now().isBefore(quote.validUntil) ||
        _checkoutQuoteFingerprint != _currentCheckoutQuoteFingerprint();
  }

  int get checkoutQuotedTax =>
      _checkoutQuote?.lines.fold<int>(0, (total, line) => total + line.tax) ??
      0;

  int get checkoutQuotedFreight =>
      _checkoutQuote?.lines.fold<int>(
        0,
        (total, line) => total + line.freight,
      ) ??
      0;

  int get checkoutQuotedDeliveryFee =>
      _checkoutQuote?.lines.fold<int>(
        0,
        (total, line) => total + line.deliveryFee,
      ) ??
      0;

  int get checkoutQuotedPaymentCharge =>
      _checkoutQuote?.lines.fold<int>(
        0,
        (total, line) => total + line.paymentCharge,
      ) ??
      0;

  Future<bool> refreshCheckoutQuote() async {
    final adapter = checkoutQuoteAdapter;
    final address = selectedAddressOrNull;
    final groups = checkoutFulfilmentGroups;
    if (adapter == null) return true;
    if (address == null || groups.isEmpty) {
      _checkoutQuote = null;
      _checkoutQuoteFingerprint = null;
      checkoutQuoteLoadState = BuyV2CommerceLoadState.unavailable;
      checkoutQuoteMessage = 'Choose a delivery address to check the total.';
      notifyListeners();
      return false;
    }
    final requestSequence = ++_checkoutQuoteRequestSequence;
    final fingerprint = _currentCheckoutQuoteFingerprint();
    _checkoutQuote = null;
    _checkoutQuoteFingerprint = null;
    checkoutQuoteLoadState = BuyV2CommerceLoadState.loading;
    checkoutQuoteMessage = null;
    notifyListeners();
    try {
      final snapshot = await adapter.loadQuote(
        groups: List.unmodifiable(groups),
        address: address,
        selectedPaymentMethod: selectedPayment,
        selectedBenefits: selectedCartBenefitsFor(cartDestinations),
        tipAmountsByFulfilmentKey: {
          for (final group in groups) group.key: tipForGroup(group),
        },
      );
      if (requestSequence != _checkoutQuoteRequestSequence ||
          fingerprint != _currentCheckoutQuoteFingerprint()) {
        return false;
      }
      checkoutQuoteLoadState = snapshot.state;
      checkoutQuoteMessage = snapshot.customerMessage;
      final quote = snapshot.quote;
      if (snapshot.state != BuyV2CommerceLoadState.ready ||
          quote == null ||
          !_validCheckoutQuote(quote, groups)) {
        _checkoutQuote = null;
        _checkoutQuoteFingerprint = null;
        if (snapshot.state == BuyV2CommerceLoadState.ready) {
          checkoutQuoteLoadState = BuyV2CommerceLoadState.unavailable;
          checkoutQuoteMessage = 'The current total could not be verified.';
        }
        _invalidateCommercialPaymentTerms();
        notifyListeners();
        return false;
      }
      _checkoutQuote = quote;
      _checkoutQuoteFingerprint = fingerprint;
      _invalidateCommercialPaymentTerms();
      if (commercialPaymentTermsEnabled) {
        unawaited(refreshCommercialPaymentTerms());
      }
      notifyListeners();
      return true;
    } on Object {
      if (requestSequence != _checkoutQuoteRequestSequence) return false;
      _checkoutQuote = null;
      _checkoutQuoteFingerprint = null;
      checkoutQuoteLoadState = BuyV2CommerceLoadState.unavailable;
      checkoutQuoteMessage = 'Checkout total could not be checked. Try again.';
      _invalidateCommercialPaymentTerms();
      notifyListeners();
      return false;
    }
  }

  bool _validCheckoutQuote(
    BuyV2CheckoutQuote quote,
    List<BuyV2FulfilmentGroup> groups,
  ) {
    if (quote.id.trim().isEmpty ||
        quote.sourceId.trim().isEmpty ||
        !quote.evaluatedAt.isBefore(quote.validUntil) ||
        !DateTime.now().isBefore(quote.validUntil) ||
        quote.lines.length != groups.length) {
      return false;
    }
    final groupByKey = {for (final group in groups) group.key: group};
    final expectedCouponSaving = _checkoutGroupCouponSavings();
    final seen = <String>{};
    var total = 0;
    for (final line in quote.lines) {
      final group = groupByKey[line.fulfilmentKey];
      if (group == null ||
          !seen.add(line.fulfilmentKey) ||
          line.itemSubtotal != group.total ||
          line.couponSaving !=
              (expectedCouponSaving[line.fulfilmentKey] ?? 0) ||
          line.tip != tipForGroup(group) ||
          line.tax < 0 ||
          line.freight < 0 ||
          line.deliveryFee < 0 ||
          line.paymentCharge < 0 ||
          line.total !=
              line.itemSubtotal -
                  line.couponSaving +
                  line.tax +
                  line.freight +
                  line.deliveryFee +
                  line.tip +
                  line.paymentCharge) {
        return false;
      }
      total += line.total;
    }
    return total == quote.total;
  }

  String _currentCheckoutQuoteFingerprint() {
    final addressId = selectedAddressOrNull?.id ?? 'no-address';
    final benefits = selectedCartBenefitsFor(
      cartDestinations,
    ).map((benefit) => '${benefit.id}:${benefit.sourceId}').join(',');
    return checkoutFulfilmentGroups
        .map(
          (group) =>
              '${group.key}:${group.total}:${tipForGroup(group)}:'
              '${_checkoutGroupCouponSavings()[group.key] ?? 0}',
        )
        .followedBy([addressId, selectedPayment, benefits])
        .join('|');
  }

  void _invalidateCheckoutQuote() {
    if (!checkoutQuoteEnabled) return;
    _checkoutQuoteRequestSequence += 1;
    _checkoutQuote = null;
    _checkoutQuoteFingerprint = null;
    checkoutQuoteLoadState = BuyV2CommerceLoadState.loading;
    checkoutQuoteMessage = null;
  }

  bool get commercialPaymentTermsEnabled =>
      commercialPaymentTermsAdapter != null;

  bool get commercialPaymentTermsBusy =>
      commercialPaymentTermsLoadState == BuyV2CommerceLoadState.loading;

  List<BuyV2CommercialPaymentTerm> commercialPaymentTermsFor(
    String fulfilmentKey,
  ) => List.unmodifiable(
    _commercialPaymentTerms.where(
      (term) => term.fulfilmentKey == fulfilmentKey,
    ),
  );

  BuyV2CommercialPaymentTerm? selectedCommercialPaymentTermFor(
    String fulfilmentKey,
  ) {
    final selectedId = _selectedCommercialPaymentTermIds[fulfilmentKey];
    if (selectedId == null) return null;
    return _commercialPaymentTerms
        .where(
          (term) =>
              term.fulfilmentKey == fulfilmentKey && term.id == selectedId,
        )
        .firstOrNull;
  }

  bool get checkoutPaymentTermsReviewRequired {
    if (!commercialPaymentTermsEnabled) return false;
    if (commercialPaymentTermsLoadState != BuyV2CommerceLoadState.ready) {
      return true;
    }
    return checkoutFulfilmentGroups.any(
      (group) => selectedCommercialPaymentTermFor(group.key) == null,
    );
  }

  int get checkoutAmountDueNow {
    if (!commercialPaymentTermsEnabled) return checkoutPayableTotal;
    final selected = [
      for (final group in checkoutFulfilmentGroups)
        selectedCommercialPaymentTermFor(group.key),
    ];
    if (selected.any((term) => term == null)) return checkoutPayableTotal;
    return selected.whereType<BuyV2CommercialPaymentTerm>().fold(
      0,
      (total, term) => total + term.amountDueNow,
    );
  }

  int get checkoutBalanceDue {
    if (!commercialPaymentTermsEnabled) return 0;
    return checkoutFulfilmentGroups
        .map((group) => selectedCommercialPaymentTermFor(group.key))
        .whereType<BuyV2CommercialPaymentTerm>()
        .fold(0, (total, term) => total + term.balanceDue);
  }

  Future<bool> refreshCommercialPaymentTerms() async {
    final adapter = commercialPaymentTermsAdapter;
    if (adapter == null) return true;
    final groups = checkoutFulfilmentGroups;
    if (groups.isEmpty) {
      _commercialPaymentTerms = [];
      _selectedCommercialPaymentTermIds.clear();
      commercialPaymentTermsLoadState = BuyV2CommerceLoadState.ready;
      commercialPaymentTermsMessage = null;
      notifyListeners();
      return true;
    }
    final requestSequence = ++_commercialPaymentTermsRequestSequence;
    final fingerprint = _commercialPaymentTermsFingerprint(groups);
    commercialPaymentTermsLoadState = BuyV2CommerceLoadState.loading;
    commercialPaymentTermsMessage = null;
    notifyListeners();
    try {
      final snapshot = await adapter.loadTerms(
        groups: List.unmodifiable(groups),
        selectedPaymentMethod: selectedPayment,
        quotedTotalsByFulfilmentKey: _checkoutGroupPayables(),
      );
      if (requestSequence != _commercialPaymentTermsRequestSequence ||
          fingerprint != _commercialPaymentTermsFingerprint(groups)) {
        return false;
      }
      commercialPaymentTermsLoadState = snapshot.state;
      commercialPaymentTermsMessage = snapshot.customerMessage;
      if (snapshot.state != BuyV2CommerceLoadState.ready) {
        _commercialPaymentTerms = [];
        notifyListeners();
        return false;
      }
      _commercialPaymentTerms = _validatedCommercialPaymentTerms(
        snapshot.terms,
        groups,
      );
      _selectedCommercialPaymentTermIds.removeWhere(
        (groupKey, selectedId) => !_commercialPaymentTerms.any(
          (term) => term.fulfilmentKey == groupKey && term.id == selectedId,
        ),
      );
      for (final group in groups) {
        if (group.destination == BuyV2Destination.wholesale) continue;
        final retailAdvance = commercialPaymentTermsFor(group.key)
            .where(
              (term) =>
                  term.kind == BuyV2CommercialPaymentTermKind.retailAdvance,
            )
            .firstOrNull;
        if (retailAdvance != null) {
          _selectedCommercialPaymentTermIds[group.key] = retailAdvance.id;
        }
      }
      if (checkoutPaymentTermsReviewRequired &&
          commercialPaymentTermsMessage == null) {
        commercialPaymentTermsMessage =
            'Choose an available payment term for each Wholesale delivery.';
      }
      notifyListeners();
      return !checkoutPaymentTermsReviewRequired;
    } on Object {
      if (requestSequence != _commercialPaymentTermsRequestSequence) {
        return false;
      }
      _commercialPaymentTerms = [];
      commercialPaymentTermsLoadState = BuyV2CommerceLoadState.unavailable;
      commercialPaymentTermsMessage =
          'Payment terms could not be checked. Try again.';
      notifyListeners();
      return false;
    }
  }

  String _commercialPaymentTermsFingerprint(
    List<BuyV2FulfilmentGroup> groups,
  ) => groups
      .map(
        (group) =>
            '${group.key}:${group.total}:${tipForGroup(group)}:'
            '${couponSavingForDestination(group.destination)}',
      )
      .followedBy([selectedPayment])
      .join('|');

  List<BuyV2CommercialPaymentTerm> _validatedCommercialPaymentTerms(
    List<BuyV2CommercialPaymentTerm> terms,
    List<BuyV2FulfilmentGroup> groups,
  ) {
    final groupByKey = {for (final group in groups) group.key: group};
    final payableByKey = _checkoutGroupPayables();
    final identities = <String>{};
    return List.unmodifiable([
      for (final term in terms)
        if (_validCommercialPaymentTerm(
              term,
              group: groupByKey[term.fulfilmentKey],
              expectedTotal: payableByKey[term.fulfilmentKey],
            ) &&
            identities.add('${term.fulfilmentKey}|${term.id}'))
          term,
    ]);
  }

  bool _validCommercialPaymentTerm(
    BuyV2CommercialPaymentTerm term, {
    required BuyV2FulfilmentGroup? group,
    required int? expectedTotal,
  }) {
    if (group == null ||
        expectedTotal == null ||
        term.id.trim().isEmpty ||
        term.sourceId.trim().isEmpty ||
        term.supplierName.trim().isEmpty ||
        term.fulfilmentKey != group.key ||
        term.destination != group.destination ||
        term.supplierName != group.partner ||
        term.orderTotal != expectedTotal ||
        term.amountDueNow < 0 ||
        term.balanceDue < 0 ||
        term.amountDueNow + term.balanceDue != expectedTotal ||
        term.balanceDueLabel.trim().isEmpty) {
      return false;
    }
    if (group.destination != BuyV2Destination.wholesale) {
      return term.kind == BuyV2CommercialPaymentTermKind.retailAdvance &&
          term.amountDueNow == expectedTotal &&
          term.balanceDue == 0;
    }
    return switch (term.kind) {
      BuyV2CommercialPaymentTermKind.retailAdvance => false,
      BuyV2CommercialPaymentTermKind.wholesaleAdvance =>
        term.amountDueNow == expectedTotal && term.balanceDue == 0,
      BuyV2CommercialPaymentTermKind.bookingBalanceBeforeDispatch ||
      BuyV2CommercialPaymentTermKind.bookingBalanceOnDelivery =>
        term.amountDueNow > 0 && term.balanceDue > 0,
      BuyV2CommercialPaymentTermKind.supplierCredit =>
        term.netDays != null &&
            term.netDays! >= 1 &&
            term.netDays! <= (term.supplierIsMicroOrSmall ? 45 : 90) &&
            term.financierName == null &&
            term.keyFactsUri == null,
      BuyV2CommercialPaymentTermKind.regulatedCredit =>
        term.netDays != null &&
            term.netDays! >= 1 &&
            term.netDays! <= 90 &&
            term.financierName?.trim().isNotEmpty == true &&
            term.annualPercentageRate != null &&
            term.annualPercentageRate! >= 0 &&
            term.keyFactsUri?.scheme == 'https' &&
            term.keyFactsUri?.host.isNotEmpty == true,
    };
  }

  bool chooseCommercialPaymentTerm(BuyV2CommercialPaymentTerm term) {
    if (commercialPaymentTermsLoadState != BuyV2CommerceLoadState.ready ||
        !commercialPaymentTermsFor(
          term.fulfilmentKey,
        ).any((candidate) => candidate.id == term.id)) {
      notice = 'This payment term is no longer available.';
      notifyListeners();
      return false;
    }
    _selectedCommercialPaymentTermIds[term.fulfilmentKey] = term.id;
    notice = '${_commercialPaymentTermLabel(term.kind)} selected.';
    notifyListeners();
    return true;
  }

  String _commercialPaymentTermLabel(BuyV2CommercialPaymentTermKind kind) =>
      switch (kind) {
        BuyV2CommercialPaymentTermKind.retailAdvance ||
        BuyV2CommercialPaymentTermKind.wholesaleAdvance => 'Full advance',
        BuyV2CommercialPaymentTermKind.bookingBalanceBeforeDispatch =>
          'Booking amount with balance before dispatch',
        BuyV2CommercialPaymentTermKind.bookingBalanceOnDelivery =>
          'Booking amount with balance at delivery',
        BuyV2CommercialPaymentTermKind.supplierCredit => 'Supplier credit',
        BuyV2CommercialPaymentTermKind.regulatedCredit =>
          'Financial partner credit',
      };

  void _invalidateCommercialPaymentTerms() {
    if (!commercialPaymentTermsEnabled) return;
    _commercialPaymentTermsRequestSequence += 1;
    _commercialPaymentTerms = [];
    commercialPaymentTermsLoadState = BuyV2CommerceLoadState.loading;
    commercialPaymentTermsMessage = null;
  }

  void _invalidateAndRefreshCheckoutPricingContracts() {
    _invalidateCheckoutQuote();
    if (_cart.isNotEmpty && checkoutQuoteEnabled) {
      unawaited(refreshCheckoutQuote());
    }
    _invalidateCommercialPaymentTerms();
    if (_cart.isNotEmpty &&
        commercialPaymentTermsEnabled &&
        !checkoutQuoteEnabled) {
      unawaited(refreshCommercialPaymentTerms());
    }
  }

  List<BuyV2CartBenefit> cartBenefits({
    required BuyV2CartBenefitKind kind,
    BuyV2Destination? destination,
  }) {
    final destinations = destination == null
        ? cartLines.map((line) => line.product.destination).toSet()
        : {destination};
    if (destinations.isEmpty ||
        destinations.contains(BuyV2Destination.orders)) {
      return const [];
    }
    final raw = liveCartBenefitsEnabled
        ? _liveCartBenefits
        : cartBenefitsAdapter.benefitsFor(
            kind: kind,
            destinations: destinations,
            itemTotal: destination == null
                ? scopedCartTotal
                : totalForDestination(destination),
          );
    final valid = <BuyV2CartBenefit>[];
    final ids = <String>{};
    for (final benefit in raw) {
      if (benefit.kind != kind ||
          !destinations.contains(benefit.destination) ||
          benefit.id.trim().isEmpty ||
          benefit.title.trim().isEmpty ||
          benefit.detail.trim().isEmpty ||
          benefit.sourceId.trim().isEmpty ||
          benefit.sponsorName.trim().isEmpty ||
          benefit.savingAmount < 0 ||
          !ids.add('${benefit.destination.name}|${benefit.id}')) {
        continue;
      }
      valid.add(benefit);
    }
    return List.unmodifiable(valid);
  }

  String _cartBenefitSelectionKey(
    BuyV2Destination destination,
    BuyV2CartBenefitKind kind,
  ) => '${destination.name}|${kind.name}';

  BuyV2CartBenefit? selectedCartBenefit({
    required BuyV2CartBenefitKind kind,
    required BuyV2Destination destination,
  }) {
    final selected =
        _selectedCartBenefitRefs[_cartBenefitSelectionKey(destination, kind)];
    if (selected == null) return null;
    return cartBenefits(kind: kind, destination: destination)
        .where(
          (benefit) =>
              benefit.id == selected.benefitId &&
              benefit.sourceId == selected.sourceId,
        )
        .firstOrNull;
  }

  List<BuyV2CartBenefit> selectedCartBenefitsFor(
    Set<BuyV2Destination> destinations,
  ) {
    final selected = <BuyV2CartBenefit>[];
    for (final destination in destinations) {
      if (destination == BuyV2Destination.orders) continue;
      for (final kind in BuyV2CartBenefitKind.values) {
        final benefit = selectedCartBenefit(
          kind: kind,
          destination: destination,
        );
        if (benefit != null) selected.add(benefit);
      }
    }
    return List.unmodifiable(selected);
  }

  bool chooseCartBenefit(BuyV2CartBenefit benefit) {
    if (liveCartBenefitsEnabled &&
        cartBenefitsLoadState != BuyV2CartBenefitsLoadState.ready) {
      notice = 'Coupon eligibility is still being checked.';
      notifyListeners();
      return false;
    }
    final available = cartBenefits(
      kind: benefit.kind,
      destination: benefit.destination,
    );
    final current = available
        .where(
          (candidate) =>
              candidate.id == benefit.id &&
              candidate.sourceId == benefit.sourceId,
        )
        .firstOrNull;
    if (current == null) {
      notice = 'This offer is no longer available.';
      notifyListeners();
      return false;
    }
    _selectedCartBenefitRefs[_cartBenefitSelectionKey(
      current.destination,
      current.kind,
    )] = _BuyV2CartBenefitSelectionRef(
      benefitId: current.id,
      sourceId: current.sourceId,
    );
    _invalidateAndRefreshCheckoutPricingContracts();
    notice =
        current.kind == BuyV2CartBenefitKind.coupon && current.savingAmount > 0
        ? '${current.title} applied. Your total now includes the saving.'
        : '${current.title} selected for Checkout review.';
    notifyListeners();
    return true;
  }

  void removeCartBenefit({
    required BuyV2CartBenefitKind kind,
    required BuyV2Destination destination,
  }) {
    final removed = _selectedCartBenefitRefs.remove(
      _cartBenefitSelectionKey(destination, kind),
    );
    if (removed == null) return;
    _invalidateAndRefreshCheckoutPricingContracts();
    notice = kind == BuyV2CartBenefitKind.coupon
        ? 'Coupon removed from Checkout review.'
        : 'Payment offer removed from Checkout review.';
    notifyListeners();
  }

  List<BuyV2Product> cartRecommendationsFor(
    BuyV2Destination destination, {
    Set<String> excludedProductIds = const {},
    bool specialOffersOnly = false,
    int limit = 6,
  }) {
    if (destination == BuyV2Destination.orders || limit <= 0) {
      return const [];
    }
    final cartProductIds = _cart.keys.toSet();
    final categoryIds = _cart.values
        .where((line) => line.product.destination == destination)
        .map((line) => line.product.categoryId)
        .toSet();
    bool hasOffer(BuyV2Product product) {
      final badge = product.badge.toLowerCase();
      return (product.mrp != null && product.mrp! > product.price) ||
          badge.contains('off') ||
          badge.contains('lowest') ||
          badge.contains('best');
    }

    int score(BuyV2Product product) {
      var value = categoryIds.contains(product.categoryId) ? 8 : 0;
      if (hasOffer(product)) value += 4;
      if (destination == BuyV2Destination.medicine &&
          !product.requiresPrescription) {
        value += 2;
      }
      return value;
    }

    final candidates = _catalogueProducts
        .where(
          (product) =>
              product.destination == destination &&
              product.catalogueListing &&
              !cartProductIds.contains(product.id) &&
              !excludedProductIds.contains(product.id) &&
              (!specialOffersOnly || hasOffer(product)),
        )
        .toList(growable: false);
    candidates.sort((left, right) {
      final scoreOrder = score(right).compareTo(score(left));
      if (scoreOrder != 0) return scoreOrder;
      final priceOrder = left.price.compareTo(right.price);
      if (priceOrder != 0) return priceOrder;
      return left.id.compareTo(right.id);
    });
    return List.unmodifiable(candidates.take(limit));
  }

  /// Returns deterministic continuation products from the current catalogue.
  ///
  /// This is deliberately independent of Cart contents, customer history,
  /// popularity, serviceability and provider state. It is a local catalogue
  /// ordering helper, not a personalized or clinical recommendation owner.
  List<BuyV2Product> productVariantsFor(BuyV2Product current) {
    if (current.destination == BuyV2Destination.orders) return const [];
    return List.unmodifiable(
      _catalogueProducts.where(
        (product) =>
            product.destination == current.destination &&
            product.canonicalId == current.canonicalId,
      ),
    );
  }

  List<BuyV2Product> recentlyViewedProductsFor(
    BuyV2Destination destination, {
    int limit = 10,
  }) {
    if (limit <= 0 ||
        (destination != BuyV2Destination.shop &&
            destination != BuyV2Destination.wholesale)) {
      return const [];
    }
    return List.unmodifiable(
      _recentlyViewedProductIds
          .map(findProduct)
          .whereType<BuyV2Product>()
          .where((product) => product.destination == destination)
          .take(limit),
    );
  }

  void _recordRecentlyViewed(BuyV2Product product) {
    if (product.destination != BuyV2Destination.shop &&
        product.destination != BuyV2Destination.wholesale) {
      return;
    }
    _recentlyViewedProductIds
      ..remove(product.id)
      ..insert(0, product.id);
    if (_recentlyViewedProductIds.length > 10) {
      _recentlyViewedProductIds.removeRange(
        10,
        _recentlyViewedProductIds.length,
      );
    }
    _persistCustomerState();
  }

  void clearRecentlyViewed(BuyV2Destination destination) {
    final productIds = _knownCatalogueProducts
        .where((product) => product.destination == destination)
        .map((product) => product.id)
        .toSet();
    final previousLength = _recentlyViewedProductIds.length;
    _recentlyViewedProductIds.removeWhere(productIds.contains);
    if (_recentlyViewedProductIds.length == previousLength) return;
    notice = 'Recently viewed products cleared.';
    _persistCustomerState();
    notifyListeners();
  }

  List<BuyV2Product> productContinuationsFor(
    BuyV2Product current, {
    int limit = 6,
  }) {
    if (current.destination == BuyV2Destination.orders || limit <= 0) {
      return const [];
    }

    int score(BuyV2Product product) {
      var value = product.categoryId == current.categoryId ? 8 : 0;
      if (product.brand == current.brand) value += 4;
      return value;
    }

    final candidates = _catalogueProducts
        .where(
          (product) =>
              product.destination == current.destination &&
              product.catalogueListing &&
              product.canonicalId != current.canonicalId,
        )
        .toList(growable: false);
    candidates.sort((left, right) {
      final scoreOrder = score(right).compareTo(score(left));
      if (scoreOrder != 0) return scoreOrder;
      final priceOrder = left.price.compareTo(right.price);
      if (priceOrder != 0) return priceOrder;
      return left.id.compareTo(right.id);
    });
    return List.unmodifiable(candidates.take(limit));
  }

  /// Returns exact current-catalogue Wholesale products from the same seller.
  ///
  /// Explicit branch IDs take precedence over legacy display-name grouping.
  /// This selector does not establish availability, verification or ranking.
  List<BuyV2Product> supplierContinuationsFor(
    BuyV2Product current, {
    int limit = 12,
  }) {
    if (current.destination != BuyV2Destination.wholesale || limit <= 0) {
      return const [];
    }

    final candidates = _catalogueProducts
        .where(
          (product) =>
              product.destination == BuyV2Destination.wholesale &&
              product.catalogueListing &&
              product.id != current.id &&
              product.isFromSameStoreAs(current),
        )
        .toList(growable: false);
    candidates.sort((left, right) {
      final priceOrder = left.price.compareTo(right.price);
      if (priceOrder != 0) return priceOrder;
      return left.id.compareTo(right.id);
    });
    return List.unmodifiable(candidates.take(limit));
  }

  /// Returns exact current-catalogue Shop or Medicine products from the same
  /// Store, using explicit branch identity where supplied.
  ///
  /// This local selector does not establish seller or pharmacy identity,
  /// verification, availability, serviceability, ranking, recommendation or
  /// a medical relationship. Wholesale remains owned by
  /// [supplierContinuationsFor].
  List<BuyV2Product> sellerContinuationsFor(
    BuyV2Product current, {
    int limit = 12,
  }) {
    final supportedDestination =
        current.destination == BuyV2Destination.shop ||
        current.destination == BuyV2Destination.medicine;
    if (!supportedDestination || limit <= 0) return const [];

    final candidates = _knownCatalogueProducts
        .where(
          (product) =>
              product.destination == current.destination &&
              product.catalogueListing &&
              product.id != current.id &&
              product.isFromSameStoreAs(current),
        )
        .toList(growable: false);
    candidates.sort((left, right) {
      final priceOrder = left.price.compareTo(right.price);
      if (priceOrder != 0) return priceOrder;
      return left.id.compareTo(right.id);
    });
    return List.unmodifiable(candidates.take(limit));
  }

  List<BuyV2Product> otherStorePreviewsFor(
    BuyV2Product current, {
    int limit = 4,
  }) {
    if (limit <= 0) return const [];
    if (pagedCatalogueEnabled && current.storeId != null) {
      final region = _pagedStores[current.storeId]?.regionId;
      if (region == null) return const [];
      return List.unmodifiable(
        _pagedStores.values
            .where(
              (store) =>
                  store.id != current.storeId &&
                  store.regionId == region &&
                  store.previewProduct?.destination == current.destination,
            )
            .take(limit)
            .map((store) => store.previewProduct!),
      );
    }
    final stores = <BuyV2Product>[];
    for (final product in _knownCatalogueProducts) {
      if (product.destination != current.destination ||
          !product.catalogueListing ||
          product.id == current.id ||
          product.isFromSameStoreAs(current) ||
          stores.any((store) => store.isFromSameStoreAs(product))) {
        continue;
      }
      stores.add(product);
      if (stores.length == limit) break;
    }
    return List.unmodifiable(stores);
  }

  List<BuyV2Product> partnerCatalogueFor(
    BuyV2Product current, {
    int limit = 50,
  }) {
    final supportedDestination =
        current.destination == BuyV2Destination.shop ||
        current.destination == BuyV2Destination.wholesale;
    if (!supportedDestination || limit <= 0) return const [];
    if (productFactsFor(
      current,
    ).orderabilityLabel.toLowerCase().contains('unavailable')) {
      return const [];
    }

    // Alternate packs stay out of the main grid, but the exact catalogue-backed
    // entry pack must remain browsable when its customer visits this supplier.
    final candidates = _knownCatalogueProducts
        .where(
          (product) =>
              product.destination == current.destination &&
              (product.catalogueListing || product.id == current.id) &&
              product.isFromSameStoreAs(current) &&
              switch (current.destination) {
                BuyV2Destination.shop => true,
                BuyV2Destination.wholesale =>
                  (product.minimumOrder > 2) == (current.minimumOrder > 2),
                BuyV2Destination.medicine || BuyV2Destination.orders => true,
              },
        )
        .toList(growable: false);
    candidates.sort((left, right) {
      if (left.id == current.id) return -1;
      if (right.id == current.id) return 1;
      final categoryOrder = left.categoryId.compareTo(right.categoryId);
      if (categoryOrder != 0) return categoryOrder;
      final priceOrder = left.price.compareTo(right.price);
      if (priceOrder != 0) return priceOrder;
      return left.id.compareTo(right.id);
    });
    return List.unmodifiable(candidates.take(limit));
  }

  List<BuyV2Product> brandCatalogueFor(BuyV2Product current, {int limit = 50}) {
    final supportedDestination =
        current.destination == BuyV2Destination.shop ||
        current.destination == BuyV2Destination.wholesale;
    if (!supportedDestination || current.brand.trim().isEmpty || limit <= 0) {
      return const [];
    }

    final candidates = _catalogueProducts
        .where(
          (product) =>
              product.destination == current.destination &&
              product.catalogueListing &&
              product.brand == current.brand,
        )
        .toList(growable: false);
    candidates.sort((left, right) {
      if (left.id == current.id) return -1;
      if (right.id == current.id) return 1;
      final sellerOrder = left.seller.compareTo(right.seller);
      if (sellerOrder != 0) return sellerOrder;
      final priceOrder = left.price.compareTo(right.price);
      if (priceOrder != 0) return priceOrder;
      return left.id.compareTo(right.id);
    });
    return List.unmodifiable(candidates.take(limit));
  }

  Set<BuyV2Destination> get confirmedDestinations =>
      Set.unmodifiable(_confirmedDestinations);

  List<BuyV2Order> get confirmedOrders => List.unmodifiable(_confirmedOrders);

  String? get confirmedPurchaseId => _confirmedPurchaseId;

  int get confirmedProductCount => _confirmedProductCount;

  bool get checkoutPromiseReviewRequired =>
      _pendingCheckoutPromiseSnapshot != null;

  List<BuyV2DeliveryPromiseChange> get checkoutDeliveryPromiseChanges =>
      List.unmodifiable(_checkoutDeliveryPromiseChanges);

  int get confirmedItemCount => _confirmedItemCount;

  int get confirmedTotal => _confirmedTotal;

  int get confirmedAmountPaidNow => _confirmedAmountPaidNow;

  int get confirmedBalanceDue => _confirmedBalanceDue;

  List<BuyV2Order> get visibleOrders {
    final normalizedQuery = query.trim().toLowerCase();
    return _orders
        .where(
          (order) =>
              order.collection == null ||
              collectionOrderBelongsToCurrentAccount(order),
        )
        .where((order) => order.destination != BuyV2Destination.medicine)
        .where(
          (order) => ordersTab == BuyV2OrdersTab.delivered
              ? orderIsCompleted(order)
              : !orderIsCompleted(order),
        )
        .where(
          (order) =>
              destination != BuyV2Destination.orders ||
              normalizedQuery.isEmpty ||
              [
                order.id,
                order.title,
                order.partner,
                order.partnerType,
                order.itemSummary,
              ].any((value) => value.toLowerCase().contains(normalizedQuery)),
        )
        .toList(growable: false);
  }

  int get activeOrderCount => _orders
      .where(
        (order) =>
            order.collection == null ||
            collectionOrderBelongsToCurrentAccount(order),
      )
      .where((order) => order.destination != BuyV2Destination.medicine)
      .where((order) => !orderIsCompleted(order))
      .length;

  BuyV2Order? get activeQuickDeliveryOrder => _orders
      .where((order) => order.collection == null)
      .where((order) => order.destination != BuyV2Destination.medicine)
      .where((order) => order.status != BuyV2OrderStatus.delivered)
      .where((order) => order.lines.isNotEmpty)
      .where(
        (order) => order.lines.any(
          (line) =>
              fulfilmentModeFor(line.product) == BuyV2FulfilmentMode.quickLocal,
        ),
      )
      .firstOrNull;

  BuyV2Order? get activeQuietDeliveryOrder => _orders
      .where((order) => order.collection == null)
      .where((order) => order.destination != BuyV2Destination.medicine)
      .where((order) => order.status != BuyV2OrderStatus.delivered)
      .where((order) => order.lines.isNotEmpty)
      .where(
        (order) => order.lines.every(
          (line) =>
              fulfilmentModeFor(line.product) != BuyV2FulfilmentMode.quickLocal,
        ),
      )
      .firstOrNull;

  int get deliveredOrderCount => _orders
      .where(
        (order) =>
            order.collection == null ||
            collectionOrderBelongsToCurrentAccount(order),
      )
      .where((order) => order.destination != BuyV2Destination.medicine)
      .where(orderIsCompleted)
      .length;

  BuyV2Product? findProduct(String id) {
    final paged = _pagedProducts[id];
    if (paged != null) return paged;
    for (final product in _catalogueProducts) {
      if (product.id == id) return product;
    }
    return _cart[id]?.product;
  }

  BuyV2Product product(String id) {
    final match = findProduct(id);
    if (match != null) return match;
    throw ArgumentError.value(id, 'id', 'Unknown Buy product');
  }

  BuyV2ProductFactsSnapshot productFactsFor(BuyV2Product product) {
    return _productFacts.putIfAbsent(product.id, () {
      final next = productFactsAdapter.snapshotFor(product);
      final facts = _validProductFacts(product, next)
          ? next
          : _catalogueFactsFallback.snapshotFor(product);
      final store = _pagedStores[product.storeId];
      return store == null
          ? facts
          : facts.copyWith(
              storeCollection: store.collection,
              clearStoreCollection: store.collection == null,
            );
    });
  }

  bool refreshProductFacts(String productId) {
    final product = findProduct(productId);
    if (product == null) {
      notice = 'This product could not be found.';
      notifyListeners();
      return false;
    }
    final next = productFactsAdapter.snapshotFor(product);
    if (!_validProductFacts(product, next)) {
      final previous = _productFacts[product.id];
      if (previous?.storeCollection != null) {
        _productFacts[product.id] = previous!.copyWith(
          clearStoreCollection: true,
        );
      }
      notice = 'Product information could not be refreshed.';
      notifyListeners();
      return false;
    }
    final previous = _productFacts[product.id];
    _productFacts[product.id] = next;
    if (previous != next) {
      notifyListeners();
    }
    return true;
  }

  bool _validProductFacts(
    BuyV2Product product,
    BuyV2ProductFactsSnapshot snapshot,
  ) {
    return snapshot.productId == product.id &&
        snapshot.price > 0 &&
        snapshot.deliveryPromise.trim().isNotEmpty &&
        snapshot.partner.trim().isNotEmpty &&
        snapshot.orderabilityLabel.trim().isNotEmpty &&
        snapshot.sourceId.trim().isNotEmpty &&
        (snapshot.dispatchPromise == null ||
            snapshot.dispatchPromise!.trim().isNotEmpty) &&
        (snapshot.deliveryProviderName == null ||
            snapshot.deliveryProviderName!.trim().isNotEmpty) &&
        (snapshot.deliveryServiceLevel == null ||
            snapshot.deliveryServiceLevel!.trim().isNotEmpty) &&
        (snapshot.nextOpeningLabel == null ||
            snapshot.nextOpeningLabel!.trim().isNotEmpty) &&
        (snapshot.orderCutoffLabel == null ||
            snapshot.orderCutoffLabel!.trim().isNotEmpty) &&
        (snapshot.deliveryFeeLabel == null ||
            snapshot.deliveryFeeLabel!.trim().isNotEmpty) &&
        (snapshot.storeOperatingState != BuyV2StoreOperatingState.closed ||
            snapshot.nextOpeningLabel?.trim().isNotEmpty == true);
  }

  BuyV2ProductContentSnapshot productContentFor(BuyV2Product product) {
    return _productContent.putIfAbsent(product.id, () {
      final next = productContentAdapter.snapshotFor(product);
      return _validProductContent(product, next)
          ? next
          : _catalogueContentFallback.snapshotFor(product);
    });
  }

  bool refreshProductContent(String productId) {
    final product = findProduct(productId);
    if (product == null) {
      notice = 'This product could not be found.';
      notifyListeners();
      return false;
    }
    final next = productContentAdapter.snapshotFor(product);
    if (!_validProductContent(product, next)) {
      notice = 'Product details could not be refreshed.';
      notifyListeners();
      return false;
    }
    final previous = _productContent[product.id];
    _productContent[product.id] = next;
    if (!identical(previous, next)) notifyListeners();
    return true;
  }

  bool _validProductContent(
    BuyV2Product product,
    BuyV2ProductContentSnapshot snapshot,
  ) {
    if (snapshot.productId != product.id || snapshot.sourceId.trim().isEmpty) {
      return false;
    }
    final mediaIds = <String>{};
    if (snapshot.media.any(
      (item) =>
          item.id.trim().isEmpty ||
          !mediaIds.add(item.id) ||
          item.label.trim().isEmpty ||
          item.semanticLabel.trim().isEmpty,
    )) {
      return false;
    }
    if (snapshot.highlights.any((item) => item.trim().isEmpty) ||
        snapshot.specifications.any(
          (item) => item.label.trim().isEmpty || item.value.trim().isEmpty,
        ) ||
        (snapshot.description != null &&
            snapshot.description!.trim().isEmpty)) {
      return false;
    }
    if ((snapshot.state == BuyV2ProductContentState.offline ||
            snapshot.state == BuyV2ProductContentState.unavailable) &&
        snapshot.customerMessage?.trim().isNotEmpty != true) {
      return false;
    }
    return true;
  }

  BuyV2MarketplaceTrustSnapshot marketplaceTrustFor(BuyV2Product product) {
    return _marketplaceTrust.putIfAbsent(product.id, () {
      final next = marketplaceTrustAdapter.snapshotFor(product);
      return _validMarketplaceTrust(product, next)
          ? next
          : _catalogueTrustFallback.snapshotFor(product);
    });
  }

  bool refreshMarketplaceTrust(String productId) {
    final product = findProduct(productId);
    if (product == null) {
      notice = 'This product could not be found.';
      notifyListeners();
      return false;
    }
    final next = marketplaceTrustAdapter.snapshotFor(product);
    if (!_validMarketplaceTrust(product, next)) {
      notice = 'Ratings and seller details could not be refreshed.';
      notifyListeners();
      return false;
    }
    final previous = _marketplaceTrust[product.id];
    _marketplaceTrust[product.id] = next;
    if (!identical(previous, next)) notifyListeners();
    return true;
  }

  bool _validMarketplaceTrust(
    BuyV2Product product,
    BuyV2MarketplaceTrustSnapshot snapshot,
  ) {
    final facts = productFactsFor(product);
    if (snapshot.productId != product.id ||
        snapshot.sourceId.trim().isEmpty ||
        snapshot.partnerName.trim().isEmpty ||
        snapshot.partnerName != facts.partner ||
        snapshot.partnerType.trim().isEmpty) {
      return false;
    }
    bool validRating(double? rating) =>
        rating == null || (rating >= 1 && rating <= 5);
    if (!validRating(snapshot.productRating) ||
        !validRating(snapshot.partnerRating) ||
        (snapshot.productRatingCount != null &&
            snapshot.productRatingCount! < 0) ||
        (snapshot.verifiedBuyerRatingCount != null &&
            snapshot.verifiedBuyerRatingCount! < 0) ||
        (snapshot.productRatingCount != null &&
            snapshot.verifiedBuyerRatingCount != null &&
            snapshot.verifiedBuyerRatingCount! >
                snapshot.productRatingCount!) ||
        (snapshot.partnerOrderCount != null &&
            snapshot.partnerOrderCount! < 0)) {
      return false;
    }
    if ([
      snapshot.partnerLocation,
      snapshot.serviceReliabilityLabel,
      snapshot.returnSummary,
      snapshot.customerMessage,
    ].whereType<String>().any((value) => value.trim().isEmpty)) {
      return false;
    }
    if ((snapshot.state == BuyV2MarketplaceTrustState.offline ||
            snapshot.state == BuyV2MarketplaceTrustState.unavailable) &&
        snapshot.customerMessage?.trim().isNotEmpty != true) {
      return false;
    }
    return true;
  }

  BuyV2SponsoredContent? sponsoredContentFor(
    BuyV2SponsoredPlacement placement,
  ) {
    if (!sponsoredContentActivationApproved) return null;
    final content = sponsoredContentAdapter.contentFor(placement);
    return content?.placement == placement ? content : null;
  }

  BuyV2Product? get selectedProduct {
    final id = selectedProductId;
    return id == null ? null : findProduct(id);
  }

  BuyV2Order? get selectedOrderOrNull {
    final id = _selectedOrderId;
    if (id == null) return null;
    return _orders.where((order) => order.id == id).firstOrNull;
  }

  BuyV2Order get selectedOrder =>
      selectedOrderOrNull ??
      (throw StateError('No valid Buy order is selected.'));

  /// The truthful order owner for the existing Assist current-order card.
  ///
  /// A selected order is contextual only when Assist was opened from that
  /// order's Tracking or Items depth. General Assist entry deliberately keeps
  /// the established first-active-order fallback and cannot consume a stale
  /// selection left by an earlier Orders journey.
  BuyV2Order get assistOrder {
    final selected = selectedOrderOrNull;
    if ((_assistReturnView == BuyV2View.tracking ||
            _assistReturnView == BuyV2View.orderItems) &&
        selected != null) {
      return selected;
    }
    return _orders.firstWhere(
      (order) => order.status != BuyV2OrderStatus.delivered,
      orElse: () => _orders.first,
    );
  }

  BuyV2Address? get selectedAddressOrNull {
    final id = _selectedAddressId;
    if (id == null) return null;
    return _addresses.where((address) => address.id == id).firstOrNull;
  }

  BuyV2Address get selectedAddress =>
      selectedAddressOrNull ??
      (throw StateError('No valid Buy address is selected.'));

  bool restoreSelectedOrderId(String? id) {
    if (id == null || !_orders.any((order) => order.id == id)) {
      _selectedOrderId = null;
      destination = BuyV2Destination.orders;
      view = BuyV2View.catalogue;
      query = '';
      selectedFilter = null;
      notice = 'This order could not be found.';
      notifyListeners();
      return false;
    }
    _selectedOrderId = id;
    notice = null;
    notifyListeners();
    return true;
  }

  bool restoreSelectedAddressId(String? id) {
    if (id == null || !_addresses.any((address) => address.id == id)) {
      _selectedAddressId = null;
      if (view == BuyV2View.checkout) {
        checkoutStep = BuyV2CheckoutStep.address;
      } else if (view == BuyV2View.confirmation) {
        view = BuyV2View.cart;
      }
      notice = 'Choose a delivery address to continue.';
      notifyListeners();
      return false;
    }
    _selectedAddressId = id;
    _invalidateAndRefreshCheckoutPricingContracts();
    notice = null;
    notifyListeners();
    return true;
  }

  void openDestination(BuyV2Destination value) {
    final previous = _navigationSurfaceIdentity;
    _clearRecoveryOriginIfActive();
    _accountChildReturnActive = false;
    _savedCatalogueDestination = null;
    _comparedProductOrigins.clear();
    _cartProductReturnOrigin = null;
    destination = value;
    view = value == BuyV2Destination.orders
        ? BuyV2View.catalogue
        : BuyV2View.catalogue;
    query = '';
    selectedFilter = null;
    _clearDiscoveryRefinements();
    activeShoppingIntent = null;
    _cartProductReturnActive = false;
    _cartProductReturnId = null;
    notice = null;
    _notifyNavigationIfChanged(
      previous,
      BuyV2NavigationMotionDirection.replace,
    );
  }

  bool openProduct(String id, {bool preserveComparisonOrigin = false}) {
    final item = findProduct(id);
    if (item == null) {
      notice = 'This product could not be found.';
      notifyListeners();
      return false;
    }
    final previous = _navigationSurfaceIdentity;
    if (view != BuyV2View.product) {
      _productReturnDestination = destination;
      _productReturnView = view;
      _comparedProductOrigins.clear();
    } else if (preserveComparisonOrigin &&
        selectedProductId != null &&
        selectedProductId != id) {
      _comparedProductOrigins.add(selectedProductId!);
    }
    final activeSearch = query.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (view == BuyV2View.catalogue && activeSearch.length >= 2) {
      _recordRecentSearch(destination, activeSearch);
      _persistCustomerState();
    }
    destination = item.destination;
    selectedProductId = item.id;
    view = BuyV2View.product;
    notice = null;
    _recordRecentlyViewed(item);
    _notifyNavigationIfChanged(
      previous,
      BuyV2NavigationMotionDirection.forward,
    );
    if (liveCartBenefitsEnabled) {
      unawaited(refreshProductBenefits(item.id));
    }
    return true;
  }

  bool rememberStoreReturnAnchor(String id) {
    final product = findProduct(id);
    if (product == null ||
        (product.destination != BuyV2Destination.shop &&
            product.destination != BuyV2Destination.wholesale)) {
      return false;
    }
    _pendingStoreReturnAnchorId = product.id;
    return true;
  }

  String? takeStoreReturnAnchor({required String? routeProductId}) {
    final pendingId = _pendingStoreReturnAnchorId;
    if (pendingId == null || pendingId != routeProductId) return null;
    _pendingStoreReturnAnchorId = null;
    return pendingId;
  }

  void clearStoreReturnAnchor() {
    _pendingStoreReturnAnchorId = null;
  }

  bool selectProductVariant(String id) {
    final current = selectedProduct;
    final next = findProduct(id);
    if (current == null ||
        next == null ||
        next.destination != current.destination ||
        next.canonicalId != current.canonicalId) {
      notice = 'This product option is no longer available.';
      notifyListeners();
      return false;
    }
    if (next.id == current.id) return true;
    final previous = _navigationSurfaceIdentity;
    selectedProductId = next.id;
    destination = next.destination;
    notice = null;
    _recordRecentlyViewed(next);
    _notifyNavigationIfChanged(
      previous,
      BuyV2NavigationMotionDirection.replace,
    );
    if (liveCartBenefitsEnabled) {
      unawaited(refreshProductBenefits(next.id));
    }
    return true;
  }

  bool get canReturnToComparedProduct =>
      view == BuyV2View.product && _comparedProductOrigins.isNotEmpty;

  /// Restores the navigation underneath a temporary Store route without
  /// opening another product or reverting Cart, Saved or checkout decisions.
  /// The route owner discards this return when the customer changes destination.
  VoidCallback beginStoreNavigationVisit() {
    final origin = (
      destination: destination,
      view: view,
      productId: selectedProductId,
      cartScope: cartScope,
      productReturnDestination: _productReturnDestination,
      productReturnView: _productReturnView,
      comparisons: List<String>.of(_comparedProductOrigins),
      cartProductReturnActive: _cartProductReturnActive,
      cartProductReturnDestination: _cartProductReturnDestination,
      cartProductReturnId: _cartProductReturnId,
      cartProductReturnOrigin: _cartProductReturnOrigin,
    );
    _comparedProductOrigins.clear();
    var returned = false;
    return () {
      if (returned) return;
      returned = true;
      final previous = _navigationSurfaceIdentity;
      destination = origin.destination;
      view = origin.view;
      selectedProductId = origin.productId;
      cartScope = origin.cartScope;
      _productReturnDestination = origin.productReturnDestination;
      _productReturnView = origin.productReturnView;
      _comparedProductOrigins
        ..clear()
        ..addAll(origin.comparisons.where((id) => findProduct(id) != null));
      _cartProductReturnActive = origin.cartProductReturnActive;
      _cartProductReturnDestination = origin.cartProductReturnDestination;
      _cartProductReturnId = origin.cartProductReturnId;
      _cartProductReturnOrigin = origin.cartProductReturnOrigin;
      notice = null;
      if ((view == BuyV2View.cart && _cart.isEmpty) ||
          (view == BuyV2View.product &&
              (selectedProductId == null ||
                  findProduct(selectedProductId!) == null))) {
        returnToCatalogue();
        return;
      }
      _notifyNavigationIfChanged(previous, BuyV2NavigationMotionDirection.back);
    };
  }

  List<String> takeProductComparisonOrigin() {
    final origin = List<String>.unmodifiable(_comparedProductOrigins);
    _comparedProductOrigins.clear();
    return origin;
  }

  void restoreProductComparisonOrigin(List<String> origin) {
    _comparedProductOrigins
      ..clear()
      ..addAll(origin.where((id) => findProduct(id) != null));
    notifyListeners();
  }

  String? get productReturnLabel => canReturnToComparedProduct
      ? findProduct(_comparedProductOrigins.last)?.title ?? 'Previous product'
      : canReturnToShoppingAlerts
      ? 'Shopping alerts'
      : _productReturnView == BuyV2View.orderItems
      ? 'Order items'
      : null;

  void closeProduct() {
    if (_returnToShoppingAlerts()) return;
    final previous = _navigationSurfaceIdentity;
    while (_comparedProductOrigins.isNotEmpty) {
      final product = findProduct(_comparedProductOrigins.removeLast());
      if (product == null) continue;
      destination = product.destination;
      selectedProductId = product.id;
      view = BuyV2View.product;
      notice = null;
      _notifyNavigationIfChanged(previous, BuyV2NavigationMotionDirection.back);
      return;
    }
    destination = _productReturnDestination;
    view = _productReturnView;
    selectedProductId = null;
    notice = null;
    _notifyNavigationIfChanged(previous, BuyV2NavigationMotionDirection.back);
  }

  void openCart({BuyV2CartScope scope = BuyV2CartScope.all}) {
    final previous = _navigationSurfaceIdentity;
    if (view == BuyV2View.product && selectedProductId != null) {
      _cartProductReturnActive = true;
      _cartProductReturnDestination = destination;
      _cartProductReturnId = selectedProductId;
      _cartProductReturnOrigin = (
        destination: _productReturnDestination,
        view: _productReturnView,
        comparisons: List<String>.of(_comparedProductOrigins),
      );
    } else if (view != BuyV2View.checkout && view != BuyV2View.cart) {
      _cartProductReturnActive = false;
      _cartProductReturnId = null;
    }
    if (_cart.isEmpty) {
      _cartProductReturnActive = false;
      _cartProductReturnId = null;
      destination = switch (scope) {
        BuyV2CartScope.shop => BuyV2Destination.shop,
        BuyV2CartScope.wholesale => BuyV2Destination.wholesale,
        BuyV2CartScope.medicine => BuyV2Destination.medicine,
        BuyV2CartScope.all =>
          destination == BuyV2Destination.orders
              ? BuyV2Destination.shop
              : destination,
      };
      cartScope = BuyV2CartScope.all;
      view = BuyV2View.catalogue;
      notice = null;
      _notifyNavigationIfChanged(
        previous,
        BuyV2NavigationMotionDirection.replace,
      );
      return;
    }
    cartScope = scope;
    view = BuyV2View.cart;
    _notifyNavigationIfChanged(
      previous,
      BuyV2NavigationMotionDirection.forward,
    );
  }

  bool buyProductNow(String productId) {
    final product = findProduct(productId);
    if (product == null || product.destination == BuyV2Destination.orders) {
      notice = 'This product could not be found.';
      notifyListeners();
      return false;
    }
    if (quantityFor(product.id) == 0 && !addProduct(product.id)) return false;
    final scope = switch (product.destination) {
      BuyV2Destination.shop => BuyV2CartScope.shop,
      BuyV2Destination.wholesale => BuyV2CartScope.wholesale,
      BuyV2Destination.medicine => BuyV2CartScope.medicine,
      BuyV2Destination.orders => BuyV2CartScope.all,
    };
    openCart(scope: scope);
    return openCheckout();
  }

  bool openCheckout() {
    final previous = _navigationSurfaceIdentity;
    final retainingCheckout = view == BuyV2View.checkout;
    final retainedStep = checkoutStep;
    if (cartLines.isEmpty) {
      _clearCheckoutPromiseSnapshot();
      view = BuyV2View.catalogue;
      notice = 'Choose a product to continue.';
      _notifyNavigationIfChanged(
        previous,
        BuyV2NavigationMotionDirection.replace,
      );
      return false;
    }
    checkoutScope = cartScope;
    view = BuyV2View.checkout;
    checkoutStep = checkoutRequiresResolution
        ? BuyV2CheckoutStep.payment
        : retainingCheckout
        ? retainedStep
        : BuyV2CheckoutStep.address;
    if (!checkoutRequiresResolution) {
      checkoutSubmissionState = BuyV2CheckoutSubmissionState.idle;
    }
    notice = null;
    _captureCheckoutPromiseSnapshot();
    _invalidateAndRefreshCheckoutPricingContracts();
    _notifyNavigationIfChanged(
      previous,
      BuyV2NavigationMotionDirection.forward,
    );
    return true;
  }

  bool continueCheckoutFromAddress() {
    if (view != BuyV2View.checkout || checkoutBusy) return false;
    if (collectionCheckoutSelected) {
      if (collectionCheckoutStore == null) return false;
      checkoutStep = BuyV2CheckoutStep.payment;
      notice = null;
      notifyListeners();
      return true;
    }
    if (selectedAddressOrNull == null) {
      notice = 'Choose a delivery address to continue.';
      notifyListeners();
      return false;
    }
    checkoutStep = BuyV2CheckoutStep.payment;
    notice = null;
    _invalidateAndRefreshCheckoutPricingContracts();
    notifyListeners();
    return true;
  }

  bool continueCheckoutFromPayment() {
    if (view != BuyV2View.checkout || checkoutBusy) return false;
    if (collectionCheckoutSelected) return false;
    if (!availablePaymentMethods.contains(selectedPayment)) {
      notice = 'Choose an available payment method to continue.';
      notifyListeners();
      return false;
    }
    if (selectedPayment == 'Purchase order' &&
        !purchaseOrderEligibleForCheckout) {
      notice = purchaseOrderEligibilityMessage;
      notifyListeners();
      return false;
    }
    if (selectedPayment == 'Purchase order' && !purchaseOrderDetailsComplete) {
      notice = purchaseOrderDetailsMessage;
      notifyListeners();
      return false;
    }
    if (selectedPayment == 'Cash on Delivery' &&
        !cashOnDeliveryEligibleForCheckout) {
      notice = cashOnDeliveryEligibilityMessage;
      notifyListeners();
      return false;
    }
    if (checkoutSubmissionState != BuyV2CheckoutSubmissionState.idle) {
      notice = 'Complete the current payment step before continuing.';
      notifyListeners();
      return false;
    }
    checkoutStep = BuyV2CheckoutStep.confirm;
    notice = null;
    notifyListeners();
    return true;
  }

  bool showCheckoutStep(BuyV2CheckoutStep step) {
    if (view != BuyV2View.checkout || checkoutBusy) return false;
    if (step == BuyV2CheckoutStep.confirm &&
        ((!collectionCheckoutSelected && selectedAddressOrNull == null) ||
            checkoutRequiresResolution)) {
      return false;
    }
    checkoutStep = step;
    notice = null;
    notifyListeners();
    return true;
  }

  bool retryCheckoutPayment() {
    if (view != BuyV2View.checkout || checkoutBusy) return false;
    if (checkoutSubmissionState != BuyV2CheckoutSubmissionState.cancelled &&
        checkoutSubmissionState != BuyV2CheckoutSubmissionState.failed &&
        checkoutSubmissionState != BuyV2CheckoutSubmissionState.unavailable) {
      return false;
    }
    _clearCheckoutPaymentAttempt();
    checkoutSubmissionState = BuyV2CheckoutSubmissionState.idle;
    checkoutStep = BuyV2CheckoutStep.payment;
    notice = null;
    notifyListeners();
    return true;
  }

  void openOrders() {
    _clearRecoveryOriginIfActive();
    _accountChildReturnActive = false;
    query = '';
    selectedFilter = null;
    _openOrdersRoot();
  }

  void _openOrdersRoot({
    BuyV2NavigationMotionDirection direction =
        BuyV2NavigationMotionDirection.replace,
  }) {
    final previous = _navigationSurfaceIdentity;
    destination = BuyV2Destination.orders;
    view = BuyV2View.catalogue;
    ordersTab = BuyV2OrdersTab.active;
    notice = null;
    _notifyNavigationIfChanged(previous, direction);
  }

  void openOrdersFromAccount() {
    if (view != BuyV2View.account) {
      openOrders();
      return;
    }
    _accountChildReturnActive = true;
    query = '';
    selectedFilter = null;
    _openOrdersRoot(direction: BuyV2NavigationMotionDirection.forward);
  }

  void openWholesaleFromAccount() {
    if (view != BuyV2View.account) {
      openDestination(BuyV2Destination.wholesale);
      return;
    }
    final previous = _navigationSurfaceIdentity;
    _accountChildReturnActive = true;
    destination = BuyV2Destination.wholesale;
    view = BuyV2View.catalogue;
    query = '';
    selectedFilter = null;
    notice = null;
    _notifyNavigationIfChanged(
      previous,
      BuyV2NavigationMotionDirection.forward,
    );
  }

  bool openTracking(String orderId) {
    final previous = _navigationSurfaceIdentity;
    final order = _orders
        .where((candidate) => candidate.id == orderId)
        .firstOrNull;
    destination = order?.destination == BuyV2Destination.medicine
        ? BuyV2Destination.medicine
        : BuyV2Destination.orders;
    if (order == null) {
      _selectedOrderId = null;
      view = BuyV2View.catalogue;
      notice = 'This order could not be found.';
      _notifyNavigationIfChanged(
        previous,
        BuyV2NavigationMotionDirection.replace,
      );
      return false;
    }
    _selectedOrderId = orderId;
    view = BuyV2View.tracking;
    notice = null;
    _notifyNavigationIfChanged(
      previous,
      BuyV2NavigationMotionDirection.forward,
    );
    if (order.collection != null) {
      unawaited(refreshCollectionOrder(orderId));
      return true;
    }
    if (balancePaymentAdapter != null) {
      unawaited(restoreBalancePayment(orderId));
    }
    if (deliveryExceptionAdapter != null) {
      unawaited(restoreDeliveryException(orderId));
    }
    return true;
  }

  void returnToOrders() {
    if (_returnToShoppingAlerts()) return;
    final previous = _navigationSurfaceIdentity;
    destination = selectedOrderOrNull?.destination == BuyV2Destination.medicine
        ? BuyV2Destination.medicine
        : BuyV2Destination.orders;
    view = BuyV2View.catalogue;
    notice = null;
    _notifyNavigationIfChanged(previous, BuyV2NavigationMotionDirection.back);
  }

  bool openOrderItems(String orderId) {
    final order = _orders
        .where((candidate) => candidate.id == orderId)
        .firstOrNull;
    if (order == null) {
      notice = 'This order could not be found.';
      notifyListeners();
      return false;
    }
    if (order.collection != null) return openTracking(orderId);
    final previous = _navigationSurfaceIdentity;
    _selectedOrderId = order.id;
    destination = order.destination == BuyV2Destination.medicine
        ? BuyV2Destination.medicine
        : BuyV2Destination.orders;
    view = BuyV2View.orderItems;
    notice = null;
    _notifyNavigationIfChanged(
      previous,
      BuyV2NavigationMotionDirection.forward,
    );
    return true;
  }

  List<BuyV2Product> productsForOrder(BuyV2Order order) {
    final recorded = order.productIds
        .map(findProduct)
        .whereType<BuyV2Product>()
        .where((product) => product.destination == order.destination)
        .toList(growable: false);
    if (recorded.isNotEmpty ||
        order.productIds.isNotEmpty ||
        !reviewDataEnabled) {
      return recorded;
    }
    final requestedCount = int.tryParse(
      RegExp(r'^\d+').firstMatch(order.itemSummary)?.group(0) ?? '',
    );
    final parsedCount = requestedCount ?? 1;
    final limit = parsedCount < 1
        ? 1
        : parsedCount > 12
        ? 12
        : parsedCount;
    return _catalogueProducts
        .where(
          (product) =>
              product.destination == order.destination &&
              product.catalogueListing,
        )
        .take(limit)
        .toList(growable: false);
  }

  BuyV2OrderResolutionSnapshot? orderResolutionFor(String orderId) =>
      _orderResolutionSnapshots[orderId];

  BuyV2OrderResolutionResult? orderResolutionResultFor(String orderId) =>
      _orderResolutionResults[orderId];

  bool orderResolutionBusy(String orderId) =>
      _orderResolutionBusyIds.contains(orderId);

  BuyV2OrderResolutionItemEligibility? orderResolutionEligibilityFor(
    String orderId,
    BuyV2OrderResolutionKind kind,
    String productId,
  ) {
    final order = _orders.where((value) => value.id == orderId).firstOrNull;
    final snapshot = _orderResolutionSnapshots[orderId];
    if (order?.status != BuyV2OrderStatus.delivered ||
        snapshot?.state != BuyV2OrderResolutionState.ready ||
        !snapshot!.options.any((option) => option.kind == kind)) {
      return null;
    }
    final lines = order!.lines.where((line) => line.product.id == productId);
    final facts = snapshot.itemEligibility.where(
      (item) => item.productId == productId && item.kind == kind,
    );
    if (lines.length != 1 || facts.length != 1) return null;
    final line = lines.single;
    final fact = facts.single;
    if (line.quantity <= 0 ||
        line.product.destination != order.destination ||
        fact.eligibleQuantity < 0 ||
        fact.eligibleQuantity > line.quantity) {
      return null;
    }
    return fact;
  }

  bool orderResolutionItemsAllowed({
    required String orderId,
    required BuyV2OrderResolutionKind kind,
    required Map<String, int> itemQuantities,
  }) {
    final order = _orders.where((value) => value.id == orderId).firstOrNull;
    if (kind == BuyV2OrderResolutionKind.cancel) {
      return itemQuantities.isEmpty &&
          (order?.status == BuyV2OrderStatus.confirmed ||
              order?.status == BuyV2OrderStatus.preparing);
    }
    if (itemQuantities.isEmpty) return false;
    final now = DateTime.now();
    return itemQuantities.entries.every((entry) {
      final fact = orderResolutionEligibilityFor(orderId, kind, entry.key);
      return fact != null &&
          fact.unavailableReasonAt(now) == null &&
          entry.value > 0 &&
          entry.value <= fact.eligibleQuantity;
    });
  }

  Future<bool> refreshOrderResolution(String orderId) async {
    final order = _orders
        .where((candidate) => candidate.id == orderId)
        .firstOrNull;
    if (order == null || _orderResolutionBusyIds.contains(orderId)) {
      return false;
    }
    _orderResolutionBusyIds.add(orderId);
    _orderResolutionResults.remove(orderId);
    _orderResolutionSnapshots[orderId] = BuyV2OrderResolutionSnapshot(
      orderId: orderId,
      state: BuyV2OrderResolutionState.loading,
      sourceId: 'loading',
    );
    notifyListeners();
    try {
      final snapshot = await orderResolutionAdapter.load(order);
      _orderResolutionSnapshots[orderId] = _validOrderResolutionSnapshot(
        order,
        snapshot,
      );
      return _orderResolutionSnapshots[orderId]!.state ==
          BuyV2OrderResolutionState.ready;
    } on Object {
      _orderResolutionSnapshots[orderId] = BuyV2OrderResolutionSnapshot(
        orderId: orderId,
        state: BuyV2OrderResolutionState.unavailable,
        sourceId: 'order-resolution-error',
        customerMessage:
            'Order changes could not be checked. Try again or contact support.',
      );
      return false;
    } finally {
      _orderResolutionBusyIds.remove(orderId);
      notifyListeners();
    }
  }

  BuyV2OrderResolutionSnapshot _validOrderResolutionSnapshot(
    BuyV2Order order,
    BuyV2OrderResolutionSnapshot snapshot,
  ) {
    if (snapshot.orderId != order.id || snapshot.sourceId.trim().isEmpty) {
      return BuyV2OrderResolutionSnapshot(
        orderId: order.id,
        state: BuyV2OrderResolutionState.unavailable,
        sourceId: 'invalid-order-resolution',
        customerMessage:
            'Order changes are unavailable right now. Contact support for help.',
      );
    }
    if (snapshot.state != BuyV2OrderResolutionState.ready) return snapshot;
    final kinds = <BuyV2OrderResolutionKind>{};
    final options = snapshot.options
        .where((option) {
          final allowed = switch (option.kind) {
            BuyV2OrderResolutionKind.cancel =>
              order.status == BuyV2OrderStatus.preparing ||
                  order.status == BuyV2OrderStatus.confirmed,
            BuyV2OrderResolutionKind.returnItems ||
            BuyV2OrderResolutionKind.replacement ||
            BuyV2OrderResolutionKind.refund =>
              order.status == BuyV2OrderStatus.delivered,
          };
          return allowed &&
              kinds.add(option.kind) &&
              option.title.trim().isNotEmpty &&
              option.detail.trim().isNotEmpty &&
              option.reasons.isNotEmpty &&
              option.reasons.every((reason) => reason.trim().isNotEmpty);
        })
        .toList(growable: false);
    if (options.isEmpty) {
      return BuyV2OrderResolutionSnapshot(
        orderId: order.id,
        state: BuyV2OrderResolutionState.unavailable,
        sourceId: snapshot.sourceId,
        customerMessage:
            snapshot.customerMessage ??
            'This order cannot be changed at its current stage. Contact support for help.',
      );
    }
    return BuyV2OrderResolutionSnapshot(
      orderId: order.id,
      state: BuyV2OrderResolutionState.ready,
      sourceId: snapshot.sourceId,
      options: List.unmodifiable(options),
      itemEligibility: List.unmodifiable(snapshot.itemEligibility),
      customerMessage: snapshot.customerMessage,
    );
  }

  Future<bool> submitOrderResolution({
    required String orderId,
    required BuyV2OrderResolutionKind kind,
    required String reason,
    Map<String, int> itemQuantities = const {},
  }) async {
    final cleanReason = reason.trim();
    final snapshot = _orderResolutionSnapshots[orderId];
    final option = snapshot?.options
        .where((candidate) => candidate.kind == kind)
        .firstOrNull;
    if (snapshot?.state != BuyV2OrderResolutionState.ready ||
        option == null ||
        !option.reasons.contains(cleanReason) ||
        _orderResolutionBusyIds.contains(orderId)) {
      notice = 'Choose an available request and reason to continue.';
      notifyListeners();
      return false;
    }
    if (!orderResolutionItemsAllowed(
      orderId: orderId,
      kind: kind,
      itemQuantities: itemQuantities,
    )) {
      notice =
          'Choose eligible purchased quantities. Check eligibility again or contact support.';
      notifyListeners();
      return false;
    }
    _orderResolutionBusyIds.add(orderId);
    notifyListeners();
    try {
      final result = await orderResolutionAdapter.submit(
        BuyV2OrderResolutionRequest(
          orderId: orderId,
          kind: kind,
          reason: cleanReason,
          itemQuantities: Map.unmodifiable(itemQuantities),
          eligibilitySourceId: snapshot!.sourceId,
        ),
      );
      final valid =
          result.customerMessage.trim().isNotEmpty &&
          (!result.accepted || (result.reference?.trim().isNotEmpty ?? false));
      if (!valid) {
        notice = 'This request could not be confirmed. Try again.';
        return false;
      }
      _orderResolutionResults[orderId] = result;
      notice = result.accepted ? result.customerMessage : null;
      return result.accepted;
    } on Object {
      notice = 'This request could not be sent. Try again or contact support.';
      return false;
    } finally {
      _orderResolutionBusyIds.remove(orderId);
      notifyListeners();
    }
  }

  List<BuyV2ShoppingAlert> get shoppingAlerts =>
      List.unmodifiable(_shoppingAlerts);

  bool get hasShoppingAlertReturnOrigin => _shoppingAlertVisit != null;

  Object beginShoppingAlertVisit(
    BuyV2ShoppingAlert alert,
    VoidCallback returnToAlerts,
  ) {
    final token = Object();
    final origin = (
      destination: destination,
      view: view,
      cartScope: cartScope,
      checkoutScope: checkoutScope,
      ordersTab: ordersTab,
      shopCategoryId: shopCategoryId,
      wholesaleCategoryId: wholesaleCategoryId,
      medicineCategoryId: medicineCategoryId,
      query: query,
      filter: selectedFilter,
      productId: selectedProductId,
      orderId: _selectedOrderId,
    );
    final productReturnDestination = _productReturnDestination;
    final productReturnView = _productReturnView;
    final comparisons = List<String>.of(_comparedProductOrigins);
    _comparedProductOrigins.clear();
    _shoppingAlertReturnRequested = false;
    _shoppingAlertVisit = (
      token: token,
      alert: alert,
      returnToAlerts: returnToAlerts,
      restoreOrigin: () {
        final previous = _navigationSurfaceIdentity;
        destination = origin.destination;
        view = origin.view;
        cartScope = origin.cartScope;
        checkoutScope = origin.checkoutScope;
        ordersTab = origin.ordersTab;
        shopCategoryId = origin.shopCategoryId;
        wholesaleCategoryId = origin.wholesaleCategoryId;
        medicineCategoryId = origin.medicineCategoryId;
        query = origin.query;
        selectedFilter = origin.filter;
        selectedProductId = origin.productId;
        _selectedOrderId = origin.orderId;
        _productReturnDestination = productReturnDestination;
        _productReturnView = productReturnView;
        _comparedProductOrigins
          ..clear()
          ..addAll(comparisons);
        notice = null;
        _notifyNavigationIfChanged(
          previous,
          BuyV2NavigationMotionDirection.back,
        );
      },
    );
    return token;
  }

  void finishShoppingAlertVisit(Object token, {required bool restore}) {
    final visit = _shoppingAlertVisit;
    if (visit == null || !identical(visit.token, token)) return;
    _shoppingAlertVisit = null;
    _shoppingAlertReturnRequested = false;
    if (restore) visit.restoreOrigin();
  }

  bool get canReturnToShoppingAlerts {
    final visit = _shoppingAlertVisit;
    if (visit == null || _shoppingAlertReturnRequested) return false;
    final alert = visit.alert;
    if (alert.orderId != null) {
      return view == BuyV2View.tracking && _selectedOrderId == alert.orderId;
    }
    if (alert.productId != null) {
      return view == BuyV2View.product && !canReturnToComparedProduct;
    }
    return view == BuyV2View.catalogue && destination == BuyV2Destination.shop;
  }

  bool _returnToShoppingAlerts() {
    if (!canReturnToShoppingAlerts) return false;
    _shoppingAlertReturnRequested = true;
    _shoppingAlertVisit!.returnToAlerts();
    return true;
  }

  Future<bool> restoreShoppingAlerts() async {
    // A target route hydrates the shared session too. Keep the originating
    // collection stable until its visit ends; an explicit later refresh can
    // publish a new authoritative snapshot.
    if (hasShoppingAlertReturnOrigin) {
      return shoppingAlertsState == BuyV2ShoppingAlertsState.ready;
    }
    if (shoppingAlertsBusy) return false;
    shoppingAlertsBusy = true;
    shoppingAlertsState = BuyV2ShoppingAlertsState.loading;
    shoppingAlertsMessage = null;
    notifyListeners();
    try {
      final snapshot = await shoppingAlertsAdapter.load(
        BuyV2ShoppingAlertsRequest(
          orders: List.unmodifiable(_orders),
          products: List.unmodifiable(_catalogueProducts),
        ),
      );
      if (snapshot.sourceId.trim().isEmpty) {
        throw const FormatException('Missing shopping alerts source');
      }
      shoppingAlertsState = snapshot.state;
      shoppingAlertsMessage = snapshot.customerMessage;
      if (snapshot.state != BuyV2ShoppingAlertsState.ready) {
        _shoppingAlerts = [];
        return false;
      }
      final ids = <String>{};
      _shoppingAlerts = List.unmodifiable(
        snapshot.alerts.where((alert) {
          if (alert.id.trim().isEmpty ||
              alert.title.trim().isEmpty ||
              alert.detail.trim().isEmpty ||
              alert.updatedLabel.trim().isEmpty ||
              !ids.add(alert.id)) {
            return false;
          }
          final orderId = alert.orderId?.trim();
          final productId = alert.productId?.trim();
          final orderRequired = switch (alert.kind) {
            BuyV2ShoppingAlertKind.order ||
            BuyV2ShoppingAlertKind.payment ||
            BuyV2ShoppingAlertKind.delivery ||
            BuyV2ShoppingAlertKind.cancellation ||
            BuyV2ShoppingAlertKind.returnUpdate ||
            BuyV2ShoppingAlertKind.refund => true,
            BuyV2ShoppingAlertKind.offer ||
            BuyV2ShoppingAlertKind.priceDrop ||
            BuyV2ShoppingAlertKind.restock => false,
          };
          if (orderRequired) {
            return orderId != null &&
                orderId.isNotEmpty &&
                _orders.any((order) => order.id == orderId);
          }
          if (alert.kind == BuyV2ShoppingAlertKind.priceDrop ||
              alert.kind == BuyV2ShoppingAlertKind.restock) {
            return productId != null &&
                productId.isNotEmpty &&
                _catalogueProducts.any(
                  (product) =>
                      product.id == productId &&
                      product.destination == alert.destination,
                );
          }
          return alert.kind == BuyV2ShoppingAlertKind.offer;
        }),
      );
      return true;
    } on Object {
      _shoppingAlerts = [];
      shoppingAlertsState = BuyV2ShoppingAlertsState.unavailable;
      shoppingAlertsMessage =
          'Shopping alerts could not load. Try again. Your orders are unchanged.';
      return false;
    } finally {
      shoppingAlertsBusy = false;
      notifyListeners();
    }
  }

  void toggleTrackingAlerts() {
    if (!reviewDataEnabled) {
      notice = 'Order alerts are unavailable right now.';
      notifyListeners();
      return;
    }
    trackingAlertsEnabled = !trackingAlertsEnabled;
    notice = trackingAlertsEnabled
        ? 'Live order alerts are on.'
        : 'Live order alerts are paused.';
    notifyListeners();
  }

  Future<void> restoreOrderAlerts() async {
    if (reviewDataEnabled || trackingAlertsBusy) return;
    trackingAlertsBusy = true;
    notifyListeners();
    try {
      final result = await commerceAdapter.loadOrderAlerts();
      trackingAlertsAvailable = result.available;
      trackingAlertsEnabled = result.available && result.enabled;
      notice = result.available ? null : result.customerMessage;
    } on Object {
      trackingAlertsAvailable = false;
      trackingAlertsEnabled = false;
      notice = 'Order alerts could not load. Try again.';
    } finally {
      trackingAlertsBusy = false;
      notifyListeners();
    }
  }

  Future<bool> setTrackingAlerts(bool enabled) async {
    if (trackingAlertsBusy || !trackingAlertsAvailable) return false;
    if (reviewDataEnabled) {
      trackingAlertsEnabled = enabled;
      notice = enabled ? 'Order alerts are on.' : 'Order alerts are paused.';
      notifyListeners();
      return true;
    }
    trackingAlertsBusy = true;
    notifyListeners();
    try {
      final result = await commerceAdapter.setOrderAlerts(enabled: enabled);
      trackingAlertsAvailable = result.available;
      trackingAlertsEnabled = result.available && result.enabled;
      notice = result.customerMessage;
      return result.available && result.enabled == enabled;
    } on Object {
      notice = 'Order alert preference could not be saved. Try again.';
      return false;
    } finally {
      trackingAlertsBusy = false;
      notifyListeners();
    }
  }

  void openAssist() {
    final previous = _navigationSurfaceIdentity;
    if (view != BuyV2View.assist) {
      _assistReturnDestination = destination;
      _assistReturnView = view;
    }
    _selectedOrderId = assistOrder.id;
    view = BuyV2View.assist;
    notice = null;
    _notifyNavigationIfChanged(
      previous,
      BuyV2NavigationMotionDirection.forward,
    );
  }

  void closeAssist() {
    final previous = _navigationSurfaceIdentity;
    destination = _assistReturnDestination;
    view = _assistReturnView;
    notice = null;
    _notifyNavigationIfChanged(previous, BuyV2NavigationMotionDirection.back);
  }

  void openAccount() {
    if (_accountChildReturnActive) {
      returnToAccount();
      return;
    }
    final previous = _navigationSurfaceIdentity;
    if (view != BuyV2View.account) {
      _accountReturnDestination = destination;
      _accountReturnView = view;
      _accountReturnProductId = selectedProductId;
      _accountReturnOrderId = _selectedOrderId;
      _accountReturnQuery = query;
      _accountReturnFilter = selectedFilter;
    }
    view = BuyV2View.account;
    notice = null;
    _notifyNavigationIfChanged(
      previous,
      BuyV2NavigationMotionDirection.forward,
    );
  }

  void closeAccount() {
    final previous = _navigationSurfaceIdentity;
    _accountChildReturnActive = false;
    destination = _accountReturnDestination;
    view = _accountReturnView;
    selectedProductId = _accountReturnProductId;
    _selectedOrderId = _accountReturnOrderId;
    if ((_accountReturnView == BuyV2View.tracking ||
            _accountReturnView == BuyV2View.orderItems) &&
        selectedOrderOrNull == null) {
      _accountChildReturnActive = false;
      _openOrdersRoot(direction: BuyV2NavigationMotionDirection.back);
      notice = 'This order could not be found.';
      notifyListeners();
      return;
    }
    query = _accountReturnQuery;
    selectedFilter = _accountReturnFilter;
    notice = null;
    _notifyNavigationIfChanged(previous, BuyV2NavigationMotionDirection.back);
  }

  bool get canReturnToAccount =>
      _accountChildReturnActive && view != BuyV2View.account;

  void returnToAccount() {
    if (!_accountChildReturnActive) return;
    final previous = _navigationSurfaceIdentity;
    _accountChildReturnActive = false;
    destination = _accountReturnDestination;
    view = BuyV2View.account;
    query = _accountReturnQuery;
    selectedFilter = _accountReturnFilter;
    notice = null;
    _notifyNavigationIfChanged(previous, BuyV2NavigationMotionDirection.back);
  }

  bool get canHandleBack =>
      canReturnToShoppingAlerts ||
      canReturnToAccount ||
      view != BuyV2View.catalogue ||
      destination != BuyV2Destination.shop;

  void goBack() {
    if (_returnToShoppingAlerts()) return;
    if (view == BuyV2View.checkout && checkoutBusy) {
      notice = 'Keep Checkout open while your payment status is checked.';
      notifyListeners();
      return;
    }
    _handlingBackNavigation = true;
    try {
      switch (view) {
        case BuyV2View.account:
          closeAccount();
        case BuyV2View.product:
          closeProduct();
        case BuyV2View.cart:
          if (_cartProductReturnActive) {
            _returnToCartProduct();
          } else {
            returnToCatalogue();
          }
        case BuyV2View.checkout:
          switch (checkoutStep) {
            case BuyV2CheckoutStep.confirm:
              checkoutStep = BuyV2CheckoutStep.payment;
              notice = null;
              notifyListeners();
            case BuyV2CheckoutStep.payment:
              checkoutStep = BuyV2CheckoutStep.address;
              notice = null;
              notifyListeners();
            case BuyV2CheckoutStep.address:
              openCart(scope: checkoutScope);
          }
        case BuyV2View.confirmation:
          _openOrdersRoot();
        case BuyV2View.tracking:
          returnToOrders();
        case BuyV2View.orderItems:
          final order = selectedOrderOrNull;
          if (order == null) {
            _openOrdersRoot();
            notice = 'This order could not be found.';
            notifyListeners();
          } else {
            openTracking(order.id);
          }
        case BuyV2View.assist:
          closeAssist();
        case BuyV2View.recovery:
          _restoreRecoveryOrigin();
        case BuyV2View.catalogue:
          if (canReturnToAccount) {
            returnToAccount();
          } else if (destination != BuyV2Destination.shop) {
            openDestination(BuyV2Destination.shop);
          }
      }
    } finally {
      _handlingBackNavigation = false;
    }
  }

  void showOrdersTab(BuyV2OrdersTab value) {
    destination = BuyV2Destination.orders;
    view = BuyV2View.catalogue;
    ordersTab = value;
    notifyListeners();
  }

  void returnToCatalogue() {
    final previous = _navigationSurfaceIdentity;
    _comparedProductOrigins.clear();
    _cartProductReturnOrigin = null;
    if (destination == BuyV2Destination.orders) {
      view = BuyV2View.catalogue;
    } else {
      view = BuyV2View.catalogue;
    }
    selectedProductId = null;
    _cartProductReturnActive = false;
    _cartProductReturnId = null;
    notice = null;
    _notifyNavigationIfChanged(previous, BuyV2NavigationMotionDirection.back);
  }

  void _returnToCartProduct() {
    final previous = _navigationSurfaceIdentity;
    final origin = _cartProductReturnOrigin;
    _cartProductReturnOrigin = null;
    final product = _cartProductReturnId == null
        ? null
        : findProduct(_cartProductReturnId!);
    _cartProductReturnActive = false;
    _cartProductReturnId = null;
    if (product == null ||
        product.destination != _cartProductReturnDestination) {
      returnToCatalogue();
      return;
    }
    if (origin != null) {
      _productReturnDestination = origin.destination;
      _productReturnView = origin.view;
      _comparedProductOrigins
        ..clear()
        ..addAll(origin.comparisons);
    }
    destination = product.destination;
    selectedProductId = product.id;
    view = BuyV2View.product;
    notice = null;
    _notifyNavigationIfChanged(previous, BuyV2NavigationMotionDirection.back);
  }

  BuyV2CustomerReview? customerReviewFor(String productId) {
    final product = findProduct(productId);
    return product == null ? null : _customerReviews[product.canonicalId];
  }

  bool submitProductReview({
    required String productId,
    required int rating,
    required String comment,
  }) {
    final product = findProduct(productId);
    final cleanComment = comment.trim();
    if (product == null || rating < 1 || rating > 5 || cleanComment.isEmpty) {
      notice = 'Add a rating and a short review to continue.';
      notifyListeners();
      return false;
    }
    _customerReviews[product.canonicalId] = BuyV2CustomerReview(
      productCanonicalId: product.canonicalId,
      rating: rating,
      comment: cleanComment,
      updatedLabel: 'Added just now',
    );
    notice = 'Your review was added.';
    notifyListeners();
    return true;
  }

  bool hasReportedProduct(String productId) {
    final product = findProduct(productId);
    return product != null &&
        _reportedProductReasons.containsKey(product.canonicalId);
  }

  bool reportProduct({required String productId, required String reason}) {
    final product = findProduct(productId);
    final cleanReason = reason.trim();
    if (product == null || cleanReason.isEmpty) {
      notice = 'Choose what needs attention.';
      notifyListeners();
      return false;
    }
    _reportedProductReasons[product.canonicalId] = cleanReason;
    notice = 'Report received. We will review these product details.';
    notifyListeners();
    return true;
  }

  Future<bool> submitProductReviewOnline({
    required String productId,
    required int rating,
    required String comment,
  }) async {
    if (reviewDataEnabled) {
      return submitProductReview(
        productId: productId,
        rating: rating,
        comment: comment,
      );
    }
    final product = findProduct(productId);
    final cleanComment = comment.trim();
    if (product == null || rating < 1 || rating > 5 || cleanComment.isEmpty) {
      notice = 'Add a rating and a short review to continue.';
      notifyListeners();
      return false;
    }
    if (!canReviewProduct(productId)) {
      notice = 'You can review this product after a delivered purchase.';
      notifyListeners();
      return false;
    }
    if (!_productFeedbackBusyIds.add(productId)) return false;
    notice = null;
    notifyListeners();
    try {
      final result = await commerceAdapter.submitProductReview(
        product: product,
        rating: rating,
        comment: cleanComment,
      );
      if (result.accepted) {
        _customerReviews[product.canonicalId] = BuyV2CustomerReview(
          productCanonicalId: product.canonicalId,
          rating: rating,
          comment: cleanComment,
          updatedLabel: 'Added just now',
        );
      }
      notice = result.customerMessage;
      return result.accepted;
    } on Object {
      notice =
          'Your review could not be sent. Check your connection and retry.';
      return false;
    } finally {
      _productFeedbackBusyIds.remove(productId);
      notifyListeners();
    }
  }

  Future<bool> reportProductOnline({
    required String productId,
    required String reason,
  }) async {
    if (reviewDataEnabled) {
      return reportProduct(productId: productId, reason: reason);
    }
    final product = findProduct(productId);
    final cleanReason = reason.trim();
    if (product == null || cleanReason.isEmpty) {
      notice = 'Choose what needs attention.';
      notifyListeners();
      return false;
    }
    if (!canReportProduct(productId)) {
      notice = 'Product reporting is unavailable right now. Try again later.';
      notifyListeners();
      return false;
    }
    if (!_productFeedbackBusyIds.add(productId)) return false;
    notice = null;
    notifyListeners();
    try {
      final result = await commerceAdapter.reportProduct(
        product: product,
        reason: cleanReason,
      );
      if (result.accepted) {
        _reportedProductReasons[product.canonicalId] = cleanReason;
      }
      notice = result.customerMessage;
      return result.accepted;
    } on Object {
      notice =
          'This report could not be sent. Check your connection and retry.';
      return false;
    } finally {
      _productFeedbackBusyIds.remove(productId);
      notifyListeners();
    }
  }

  void showSavedProducts(bool value) {
    if (showingSavedProducts == value) return;
    _savedCatalogueDestination = value ? destination : null;
    if (value) {
      chooseCategory('all');
    } else {
      notifyListeners();
    }
  }

  void chooseCategory(String id) {
    switch (destination) {
      case BuyV2Destination.shop:
        shopCategoryId = id;
      case BuyV2Destination.wholesale:
        wholesaleCategoryId = id;
      case BuyV2Destination.medicine:
        medicineCategoryId = id;
      case BuyV2Destination.orders:
        break;
    }
    query = '';
    notice = null;
    notifyListeners();
  }

  void updateQuery(String value) {
    query = value;
    notifyListeners();
  }

  bool broadenProductSearchScope() {
    if (!hasNarrowedProductSearchScope) return false;
    switch (destination) {
      case BuyV2Destination.shop:
        shopCategoryId = 'all';
      case BuyV2Destination.wholesale:
        wholesaleCategoryId = 'all';
      case BuyV2Destination.medicine:
        medicineCategoryId = 'all';
      case BuyV2Destination.orders:
        return false;
    }
    selectedFilter = null;
    activeShoppingIntent = null;
    notice = null;
    _clearDiscoveryRefinements();
    _persistCustomerState();
    notifyListeners();
    return true;
  }

  void chooseFilter(String? value) {
    selectedFilter = value;
    selectedFulfilmentMode = null;
    notifyListeners();
  }

  BuyV2DiscoveryRefinements get discoveryRefinements =>
      BuyV2DiscoveryRefinements(
        brands: _selectedBrands,
        maximumPrice: maximumProductPrice,
        pack: selectedPackFilter,
        fulfilmentMode: selectedFulfilmentMode,
        filter: selectedFilter,
        sort: productSort,
        availableOnly: availableProductsOnly,
      );

  void applyDiscoveryRefinements(BuyV2DiscoveryRefinements value) {
    _selectedBrands
      ..clear()
      ..addAll(value.brands);
    maximumProductPrice = value.maximumPrice;
    selectedPackFilter = value.pack;
    selectedFilter = value.filter;
    selectedFulfilmentMode = value.fulfilmentMode;
    productSort = value.sort;
    availableProductsOnly = value.availableOnly;
    notifyListeners();
  }

  List<String> get discoveryBrands {
    if (destination == BuyV2Destination.orders) return const [];
    final brands =
        previewDiscoveryProducts(BuyV2DiscoveryRefinements())
            .map((product) => product.brand)
            .where((brand) => brand.trim().isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort();
    return List.unmodifiable(brands);
  }

  List<int> get discoveryPriceLimits => switch (destination) {
    BuyV2Destination.shop => const [100, 250, 500, 1000],
    BuyV2Destination.wholesale => const [2000, 5000, 10000],
    BuyV2Destination.medicine => const [100, 250, 500, 1000],
    BuyV2Destination.orders => const [],
  };

  int get activeDiscoveryRefinementCount =>
      _selectedBrands.length +
      (maximumProductPrice == null ? 0 : 1) +
      (selectedPackFilter == null ? 0 : 1) +
      (selectedFulfilmentMode == null ? 0 : 1) +
      (productSort == BuyV2ProductSort.relevance ? 0 : 1) +
      (availableProductsOnly ? 1 : 0);

  String get discoveryRefinementSignature => [
    productSort.name,
    maximumProductPrice?.toString() ?? 'any-price',
    selectedPackFilter?.name ?? 'any-pack',
    selectedFulfilmentMode?.name ?? 'any-delivery',
    availableProductsOnly ? 'available' : 'all-stock',
    ...(_selectedBrands.toList()..sort()),
  ].join('|');

  void toggleDiscoveryBrand(String brand) {
    final value = brand.trim();
    if (value.isEmpty || !discoveryBrands.contains(value)) return;
    if (!_selectedBrands.remove(value)) _selectedBrands.add(value);
    _persistCustomerState();
    notifyListeners();
  }

  void chooseMaximumProductPrice(int? value) {
    if (value != null &&
        (value <= 0 || !discoveryPriceLimits.contains(value))) {
      return;
    }
    maximumProductPrice = value;
    _persistCustomerState();
    notifyListeners();
  }

  void choosePackFilter(BuyV2PackFilter? value) {
    selectedPackFilter = value;
    _persistCustomerState();
    notifyListeners();
  }

  void chooseFulfilmentMode(BuyV2FulfilmentMode? value) {
    selectedFulfilmentMode = value;
    if (destination == BuyV2Destination.shop) {
      if (value == BuyV2FulfilmentMode.quickLocal) {
        _shopSaleType = BuyV2ShopSaleType.quickDelivery;
      } else if (value == BuyV2FulfilmentMode.standardCourier) {
        _shopSaleType = BuyV2ShopSaleType.courier;
      }
    }
    _persistCustomerState();
    notifyListeners();
  }

  void chooseProductSort(BuyV2ProductSort value) {
    productSort = value;
    _persistCustomerState();
    notifyListeners();
  }

  void setAvailableProductsOnly(bool value) {
    availableProductsOnly = value;
    _persistCustomerState();
    notifyListeners();
  }

  void clearDiscoveryRefinements() {
    if (activeDiscoveryRefinementCount == 0 && selectedFilter == null) return;
    selectedFilter = null;
    _clearDiscoveryRefinements();
    _persistCustomerState();
    notifyListeners();
  }

  void _clearDiscoveryRefinements() {
    _selectedBrands.clear();
    maximumProductPrice = null;
    selectedPackFilter = null;
    selectedFulfilmentMode = null;
    productSort = BuyV2ProductSort.relevance;
    availableProductsOnly = false;
  }

  List<BuyV2CartLine> get monthlyBasketPlan {
    final originalProducts = BuyV2Catalogue.products
        .where((product) => product.destination == BuyV2Destination.shop)
        .take(12)
        .toList(growable: false);
    const quantities = <int>[2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1];
    final plan = <BuyV2CartLine>[];
    for (var index = 0; index < originalProducts.length; index++) {
      final current = findProduct(originalProducts[index].id);
      if (current != null) {
        plan.add(BuyV2CartLine(product: current, quantity: quantities[index]));
      }
    }
    return List.unmodifiable(plan);
  }

  bool get monthlyBasketCanAdd {
    final plan = monthlyBasketPlan;
    return !checkoutRequiresResolution &&
        plan.length == 12 &&
        plan.every((line) => _availableForDiscovery(line.product));
  }

  void addMonthlyBasket() {
    if (_holdCartForPaymentResolution()) return;
    if (!monthlyBasketCanAdd) {
      showNotice(
        'Some basket products are unavailable. Review products first.',
      );
      return;
    }
    final plan = monthlyBasketPlan;
    for (final line in plan) {
      while (quantityFor(line.product.id) < line.quantity) {
        if (!addProduct(line.product.id)) {
          clearCartAcknowledgement();
          return;
        }
      }
    }
    final ready = plan
        .where((line) => quantityFor(line.product.id) >= line.quantity)
        .length;
    _acknowledgeCart(
      ready == plan.length
          ? 'Monthly basket ready · $ready products'
          : '$ready of ${plan.length} basket products ready',
      destination: BuyV2Destination.shop,
    );
    notifyListeners();
  }

  void chooseShoppingIntent(BuyV2ShoppingIntent intent) {
    final target = switch (intent) {
      BuyV2ShoppingIntent.monthlyBasket ||
      BuyV2ShoppingIntent.homeShopping => BuyV2Destination.shop,
      BuyV2ShoppingIntent.businessBuying ||
      BuyV2ShoppingIntent.flexibleRestocking => BuyV2Destination.wholesale,
    };
    openDestination(target);
    activeShoppingIntent = intent;
    switch (target) {
      case BuyV2Destination.shop:
        shopCategoryId = 'all';
      case BuyV2Destination.wholesale:
        wholesaleCategoryId = 'all';
      case BuyV2Destination.medicine || BuyV2Destination.orders:
        break;
    }
    selectedFilter = intent == BuyV2ShoppingIntent.flexibleRestocking
        ? 'moq'
        : null;
    notice = null;
    _persistCustomerState();
    notifyListeners();
  }

  void clearShoppingIntent() {
    if (activeShoppingIntent == null) return;
    activeShoppingIntent = null;
    selectedFilter = null;
    notice = 'Showing all ${destination.label} products.';
    _persistCustomerState();
    notifyListeners();
  }

  bool _holdCartForPaymentResolution() {
    if (!checkoutRequiresResolution) return false;
    notice =
        'Check the current payment before changing your Cart or payment method.';
    notifyListeners();
    return true;
  }

  bool addProduct(String id) {
    if (_holdCartForPaymentResolution()) return false;
    final item = findProduct(id);
    if (item == null) {
      notice = 'This product could not be found.';
      notifyListeners();
      return false;
    }
    final facts = productFactsFor(item);
    if (facts.storeOperatingState == BuyV2StoreOperatingState.closed) {
      final nextOpening = facts.nextOpeningLabel?.trim();
      notice = nextOpening?.isNotEmpty == true
          ? 'This store is closed and opens $nextOpening.'
          : 'This store is closed right now.';
      notifyListeners();
      return false;
    }
    if (!_availableForDiscovery(item)) {
      notice = 'This product is unavailable right now.';
      notifyListeners();
      return false;
    }
    if (item.destination == BuyV2Destination.wholesale && !businessVerified) {
      notice = 'Complete your business profile to place a wholesale order.';
      notifyListeners();
      return false;
    }
    if (item.requiresPrescription &&
        !_prescriptionApprovedQuantities.containsKey(item.id)) {
      pendingPrescriptionProductId = item.id;
      notice = null;
      notifyListeners();
      return false;
    }
    final current = _cart[id];
    final approvedMaximum = _prescriptionApprovedQuantities[item.id];
    if (approvedMaximum != null &&
        (current?.quantity ?? 0) + item.minimumOrder > approvedMaximum) {
      notice = 'Prescription quantity reached for ${item.title}.';
      notifyListeners();
      return false;
    }
    _cart[id] = BuyV2CartLine(
      product: item,
      quantity: (current?.quantity ?? 0) + item.minimumOrder,
    );
    _pruneCartSelections();
    _acknowledgeCart('${item.title} added', destination: item.destination);
    _persistCustomerState();
    notifyListeners();
    return true;
  }

  bool approveSavedPrescription(String prescriptionId) {
    final matched = switch (prescriptionId) {
      'meera' => const {'m-telmisartan-40': 1, 'm-atorvastatin-10': 1},
      'arvind' => const {'m-metformin-500': 1, 'm-pantoprazole-40': 1},
      _ => null,
    };
    if (matched == null) {
      notice = 'This saved prescription could not be found.';
      notifyListeners();
      return false;
    }
    prescriptionAttached = true;
    _prescriptionApprovedQuantities.addAll(matched);
    final pending = pendingPrescriptionProductId;
    pendingPrescriptionProductId = null;
    if (pending != null &&
        _prescriptionApprovedQuantities.containsKey(pending)) {
      addProduct(pending);
      return true;
    }
    notice = '${matched.length} prescribed medicines are ready to add.';
    notifyListeners();
    return true;
  }

  bool attachNewPrescription() {
    prescriptionAttached = true;
    const matched = {
      'm-telmisartan-40': 1,
      'm-atorvastatin-10': 1,
      'm-metformin-500': 1,
    };
    _prescriptionApprovedQuantities.addAll(matched);
    final pending = pendingPrescriptionProductId;
    pendingPrescriptionProductId = null;
    if (pending != null &&
        _prescriptionApprovedQuantities.containsKey(pending)) {
      addProduct(pending);
      return true;
    }
    notice = '${matched.length} matched medicines are ready to add.';
    notifyListeners();
    return true;
  }

  bool isPrescriptionApproved(String id) =>
      _prescriptionApprovedQuantities.containsKey(id);

  int get approvedPrescriptionProductCount =>
      _prescriptionApprovedQuantities.length;

  List<BuyV2Product> get matchedPrescriptionProducts => List.unmodifiable(
    _catalogueProducts.where(
      (product) =>
          product.destination == BuyV2Destination.medicine &&
          _prescriptionApprovedQuantities.containsKey(product.id),
    ),
  );

  int? prescriptionMaximumFor(String id) => _prescriptionApprovedQuantities[id];

  int quantityFor(String id) => _cart[id]?.quantity ?? 0;

  void increase(String id) {
    if (_holdCartForPaymentResolution()) return;
    final current = _cart[id];
    if (current == null) {
      addProduct(id);
      return;
    }
    final approvedMaximum = _prescriptionApprovedQuantities[id];
    if (approvedMaximum != null && current.quantity >= approvedMaximum) {
      notice = 'Prescription quantity reached for ${current.product.title}.';
      notifyListeners();
      return;
    }
    _cart[id] = current.copyWith(quantity: current.quantity + 1);
    _pruneCartSelections();
    _acknowledgeCart(
      '${current.product.title} · ${current.quantity + 1} in cart',
      destination: current.product.destination,
    );
    _persistCustomerState();
    notifyListeners();
  }

  void decrease(String id) {
    if (_holdCartForPaymentResolution()) return;
    final previous = _navigationSurfaceIdentity;
    final current = _cart[id];
    if (current == null) return;
    final minimum = current.product.minimumOrder;
    if (current.quantity <= minimum) {
      _cart.remove(id);
      _acknowledgeCart(
        '${current.product.title} removed',
        destination: current.product.destination,
      );
    } else {
      _cart[id] = current.copyWith(quantity: current.quantity - 1);
      _acknowledgeCart(
        '${current.product.title} · ${current.quantity - 1} in cart',
        destination: current.product.destination,
      );
    }
    if (_cart.isEmpty &&
        (view == BuyV2View.cart || view == BuyV2View.checkout)) {
      destination = current.product.destination;
      view = BuyV2View.catalogue;
      cartScope = BuyV2CartScope.all;
    }
    _pruneCartSelections();
    _persistCustomerState();
    if (_cart.isEmpty) {
      _notifyNavigationIfChanged(previous, BuyV2NavigationMotionDirection.back);
    } else {
      notifyListeners();
    }
  }

  void remove(String id) {
    if (_holdCartForPaymentResolution()) return;
    final previous = _navigationSurfaceIdentity;
    final removed = _cart.remove(id);
    if (removed == null) return;
    _acknowledgeCart(
      '${removed.product.title} removed',
      destination: removed.product.destination,
    );
    if (_cart.isEmpty &&
        (view == BuyV2View.cart || view == BuyV2View.checkout)) {
      destination = removed.product.destination;
      view = BuyV2View.catalogue;
      cartScope = BuyV2CartScope.all;
    }
    _pruneCartSelections();
    _persistCustomerState();
    if (_cart.isEmpty) {
      _notifyNavigationIfChanged(previous, BuyV2NavigationMotionDirection.back);
    } else {
      notifyListeners();
    }
  }

  void clearCart() {
    if (_holdCartForPaymentResolution()) return;
    final previous = _navigationSurfaceIdentity;
    final fallback = switch (cartScope) {
      BuyV2CartScope.shop => BuyV2Destination.shop,
      BuyV2CartScope.wholesale => BuyV2Destination.wholesale,
      BuyV2CartScope.medicine => BuyV2Destination.medicine,
      BuyV2CartScope.all =>
        destination == BuyV2Destination.orders
            ? BuyV2Destination.shop
            : destination,
    };
    _cart.clear();
    _deliveryInstructionIds.clear();
    _selectedCartBenefitRefs.clear();
    _tipsByFulfilmentKey.clear();
    destination = fallback;
    view = BuyV2View.catalogue;
    cartScope = BuyV2CartScope.all;
    notice = null;
    cartAcknowledgement = null;
    _cartAcknowledgementDestination = null;
    _persistCustomerState();
    _notifyNavigationIfChanged(previous, BuyV2NavigationMotionDirection.back);
  }

  bool clearCartScope(BuyV2CartScope scope) {
    if (_holdCartForPaymentResolution()) return false;
    final scopedLines = _linesForScope(scope);
    if (scopedLines.isEmpty) return false;
    if (scope == BuyV2CartScope.all) {
      clearCart();
      return true;
    }

    final previous = _navigationSurfaceIdentity;
    final removedIds = scopedLines.map((line) => line.product.id).toSet();
    final removedCount = scopedLines.fold<int>(
      0,
      (total, line) => total + line.quantity,
    );
    _cart.removeWhere((id, _) => removedIds.contains(id));
    _pruneCartSelections();

    if (_cart.isEmpty) {
      destination = _destinationForScope(scope);
      view = BuyV2View.catalogue;
      cartScope = BuyV2CartScope.all;
      notice = null;
      cartAcknowledgement = null;
      _cartAcknowledgementDestination = null;
      _persistCustomerState();
      _notifyNavigationIfChanged(previous, BuyV2NavigationMotionDirection.back);
      return true;
    }

    final remainingDestinations = cartDestinations;
    if (remainingDestinations.length == 1) {
      destination = remainingDestinations.single;
      cartScope = _scopeForDestination(destination);
    } else {
      if (!remainingDestinations.contains(destination)) {
        destination = remainingDestinations.first;
      }
      cartScope = BuyV2CartScope.all;
    }
    view = BuyV2View.cart;
    notice = null;
    final remainingCount = itemCount;
    cartAcknowledgement =
        '${scope.label} ${removedCount == 1 ? 'item' : 'items'} removed · '
        '$remainingCount ${remainingCount == 1 ? 'item remains' : 'items remain'}';
    _cartAcknowledgementDestination = remainingDestinations.length == 1
        ? remainingDestinations.single
        : null;
    _persistCustomerState();
    _notifyNavigationIfChanged(
      previous,
      BuyV2NavigationMotionDirection.replace,
    );
    return true;
  }

  BuyV2Destination _destinationForScope(BuyV2CartScope scope) =>
      switch (scope) {
        BuyV2CartScope.shop => BuyV2Destination.shop,
        BuyV2CartScope.wholesale => BuyV2Destination.wholesale,
        BuyV2CartScope.medicine => BuyV2Destination.medicine,
        BuyV2CartScope.all => destination,
      };

  BuyV2CartScope _scopeForDestination(BuyV2Destination value) =>
      switch (value) {
        BuyV2Destination.shop => BuyV2CartScope.shop,
        BuyV2Destination.wholesale => BuyV2CartScope.wholesale,
        BuyV2Destination.medicine => BuyV2CartScope.medicine,
        BuyV2Destination.orders => BuyV2CartScope.all,
      };

  void chooseCartScope(BuyV2CartScope value) {
    cartScope = value;
    notifyListeners();
  }

  bool chooseAddress(String id) {
    if (!_addresses.any((address) => address.id == id)) {
      notice = 'This saved address could not be found.';
      notifyListeners();
      return false;
    }
    _selectedAddressId = id;
    notice = 'Delivering to ${selectedAddress.shortLine}';
    _persistCustomerState();
    notifyListeners();
    return true;
  }

  void addAddress(BuyV2Address address) {
    _addresses.add(address);
    _selectedAddressId = address.id;
    _invalidateAndRefreshCheckoutPricingContracts();
    notice = 'Delivering to ${address.shortLine}';
    _persistCustomerState();
    notifyListeners();
  }

  bool updateAddress(BuyV2Address address) {
    final index = _addresses.indexWhere(
      (candidate) => candidate.id == address.id,
    );
    if (index < 0) {
      notice = 'This saved address is no longer available.';
      notifyListeners();
      return false;
    }
    _addresses[index] = address;
    _invalidateAndRefreshCheckoutPricingContracts();
    notice = '${address.label} address updated';
    _persistCustomerState();
    notifyListeners();
    return true;
  }

  bool removeAddress(String id) {
    final index = _addresses.indexWhere((address) => address.id == id);
    if (index < 0) {
      notice = 'This saved address is no longer available.';
      notifyListeners();
      return false;
    }
    final removed = _addresses.removeAt(index);
    if (_selectedAddressId == id) {
      _selectedAddressId = _addresses.firstOrNull?.id;
    }
    _invalidateAndRefreshCheckoutPricingContracts();
    notice = '${removed.label} address removed';
    _persistCustomerState();
    notifyListeners();
    return true;
  }

  bool choosePayment(String value) {
    if (_holdCartForPaymentResolution()) return false;
    if (collectionCheckoutSelected &&
        const {'Cash on Delivery', 'Purchase order'}.contains(value)) {
      return false;
    }
    if (!paymentMethods.contains(value) ||
        !availablePaymentMethods.contains(value)) {
      notice = 'This payment method is not available.';
      notifyListeners();
      return false;
    }
    if (collectionCheckoutSelected) {
      selectedPayment = value;
      notice = null;
      _persistCustomerState();
      notifyListeners();
      return true;
    }
    if (value == 'Purchase order' &&
        view == BuyV2View.checkout &&
        !purchaseOrderEligibleForCheckout) {
      notice = purchaseOrderEligibilityMessage;
      notifyListeners();
      return false;
    }
    selectedPayment = value;
    _invalidateLiveCartBenefits();
    if (_cart.isNotEmpty && liveCartBenefitsEnabled) {
      unawaited(refreshCartBenefits());
    }
    _invalidateCheckoutQuote();
    if (_cart.isNotEmpty && checkoutQuoteEnabled) {
      unawaited(refreshCheckoutQuote());
    }
    _invalidateCommercialPaymentTerms();
    if (_cart.isNotEmpty &&
        commercialPaymentTermsEnabled &&
        !checkoutQuoteEnabled) {
      unawaited(refreshCommercialPaymentTerms());
    }
    notice = '$value selected';
    _persistCustomerState();
    notifyListeners();
    return true;
  }

  void updatePurchaseOrderReference(String value) {
    if (purchaseOrderReference == value) return;
    purchaseOrderReference = value;
    notice = null;
    _persistCustomerState();
    notifyListeners();
  }

  bool confirmOrder() {
    if (checkoutBusy || checkoutRequiresResolution) return false;
    if (collectionCheckoutSelected || collectionCheckout?.unresolved == true) {
      return false;
    }
    if (!reviewDataEnabled) {
      checkoutSubmissionState = BuyV2CheckoutSubmissionState.unavailable;
      notice = 'Ordering is unavailable right now. Your Cart has not changed.';
      notifyListeners();
      return false;
    }
    final previous = _navigationSurfaceIdentity;
    final lines = checkoutLines;
    if (lines.isEmpty) {
      returnToCatalogue();
      return false;
    }
    final address = selectedAddressOrNull;
    if (address == null) {
      view = BuyV2View.checkout;
      checkoutStep = BuyV2CheckoutStep.address;
      notice = 'Choose a delivery address to continue.';
      _notifyNavigationIfChanged(
        previous,
        BuyV2NavigationMotionDirection.replace,
      );
      return false;
    }
    if (checkoutPromiseReviewRequired) {
      notice = 'Review and accept the updated delivery times to continue.';
      notifyListeners();
      return false;
    }
    for (final product in lines.map((line) => line.product).toSet()) {
      final next = productFactsAdapter.snapshotFor(product);
      if (!_validProductFacts(product, next)) {
        notice = 'Delivery times could not be confirmed. Try again.';
        notifyListeners();
        return false;
      }
      final availability = next.orderabilityLabel.toLowerCase();
      if (availability.contains('unavailable') ||
          availability.contains('out of stock') ||
          availability.contains('not available')) {
        _checkoutAvailabilityIssue = (
          productId: product.id,
          title: product.title,
          orderabilityLabel: next.orderabilityLabel,
        );
        openRecovery(BuyV2RecoveryKind.stockUnavailable);
        return false;
      }
      _productFacts[product.id] = next;
    }
    final groups = checkoutFulfilmentGroups;
    final refreshedSnapshot = _deliveryPromiseSnapshotFor(groups);
    if (_checkoutPromiseSnapshot.isEmpty) {
      _checkoutPromiseSnapshot = refreshedSnapshot;
    }
    if (!mapEquals(_checkoutPromiseSnapshot, refreshedSnapshot)) {
      final changedKeys = {
        ..._checkoutPromiseSnapshot.keys,
        ...refreshedSnapshot.keys,
      }.where((key) => _checkoutPromiseSnapshot[key] != refreshedSnapshot[key]);
      _checkoutDeliveryPromiseChanges = [
        for (final key in changedKeys)
          (
            groupKey: key,
            previousPromise:
                _checkoutPromiseSnapshot[key]?.promise ?? 'Not quoted',
            previousPromisedByLabel:
                _checkoutPromiseSnapshot[key]?.promisedByLabel,
            currentPromise: refreshedSnapshot[key]?.promise ?? 'Unavailable',
            currentPromisedByLabel: refreshedSnapshot[key]?.promisedByLabel,
          ),
      ];
      _pendingCheckoutPromiseSnapshot = refreshedSnapshot;
      notice = 'Delivery times changed. Review the updated plan.';
      notifyListeners();
      return false;
    }
    final purchaseId = _nextLocalPurchaseId();
    _confirmedPurchaseId = purchaseId;
    _confirmedOrders = _createOrdersForGroups(groups, address, purchaseId);
    _completeConfirmedOrder(previous: previous, lines: lines);
    return true;
  }

  Future<bool> submitOrder() {
    if (collectionCheckoutSelected || collectionCheckout?.unresolved == true) {
      return submitCollectionPurchase();
    }
    if (selectedPayment == 'Purchase order' &&
        !purchaseOrderEligibleForCheckout) {
      notice = purchaseOrderEligibilityMessage;
      notifyListeners();
      return Future<bool>.value(false);
    }
    if (selectedPayment == 'Purchase order' && !purchaseOrderDetailsComplete) {
      notice = purchaseOrderDetailsMessage;
      notifyListeners();
      return Future<bool>.value(false);
    }
    if (selectedPayment == 'Cash on Delivery' &&
        !cashOnDeliveryEligibleForCheckout) {
      notice = cashOnDeliveryEligibilityMessage;
      notifyListeners();
      return Future<bool>.value(false);
    }
    if (reviewDataEnabled &&
        const {'PhonePe', 'Paytm', 'Pine Labs'}.contains(selectedPayment)) {
      return _submitOrderAsync();
    }
    if (reviewDataEnabled) {
      if ((liveCartBenefitsEnabled && _hasSelectedCartBenefitReference) ||
          checkoutQuoteEnabled ||
          commercialPaymentTermsEnabled) {
        return _submitReviewOrderWithContracts();
      }
      return Future<bool>.value(confirmOrder());
    }
    return _submitOrderAsync();
  }

  Future<bool> _submitReviewOrderWithContracts() async {
    if (liveCartBenefitsEnabled && _hasSelectedCartBenefitReference) {
      final eligible = await refreshCartBenefits();
      if (!eligible ||
          cartBenefitsLoadState != BuyV2CartBenefitsLoadState.ready) {
        notice =
            cartBenefitsMessage ??
            'Coupon eligibility could not be confirmed. Review the current options.';
        notifyListeners();
        return false;
      }
    }
    if (checkoutQuoteEnabled) {
      await refreshCheckoutQuote();
      if (checkoutQuoteReviewRequired) {
        notice =
            checkoutQuoteMessage ??
            'The current Checkout total could not be confirmed.';
        notifyListeners();
        return false;
      }
    }
    if (commercialPaymentTermsEnabled) {
      await refreshCommercialPaymentTerms();
      if (checkoutPaymentTermsReviewRequired) {
        notice =
            commercialPaymentTermsMessage ??
            'Choose an available payment term to continue.';
        notifyListeners();
        return false;
      }
    }
    return confirmOrder();
  }

  bool _refreshCheckoutFactsForProduction(List<BuyV2CartLine> lines) {
    final priceChanges = <BuyV2PriceChange>[];
    for (final product in lines.map((line) => line.product).toSet()) {
      final next = productFactsAdapter.snapshotFor(product);
      if (!_validProductFacts(product, next) || next.stale) {
        checkoutSubmissionState = BuyV2CheckoutSubmissionState.failed;
        notice =
            'Current price and availability could not be confirmed. Try again.';
        notifyListeners();
        return false;
      }
      final availability = next.orderabilityLabel.toLowerCase();
      if (availability.contains('unavailable') ||
          availability.contains('out of stock') ||
          availability.contains('not available')) {
        _checkoutAvailabilityIssue = (
          productId: product.id,
          title: product.title,
          orderabilityLabel: next.orderabilityLabel,
        );
        openRecovery(BuyV2RecoveryKind.stockUnavailable);
        return false;
      }
      if (next.price != product.price) {
        priceChanges.add((
          productId: product.id,
          title: product.title,
          previousPrice: product.price,
          currentPrice: next.price,
        ));
      }
      final updatedProduct = product.copyWith(
        price: next.price,
        deliveryPromise: next.deliveryPromise,
        seller: next.partner,
        confirmedOn: 'Checked now',
      );
      final catalogueIndex = _catalogueProducts.indexWhere(
        (candidate) => candidate.id == product.id,
      );
      if (catalogueIndex >= 0) {
        _catalogueProducts[catalogueIndex] = updatedProduct;
      }
      final cartLine = _cart[product.id];
      if (cartLine != null) {
        _cart[product.id] = cartLine.copyWith(product: updatedProduct);
      }
      _productFacts[product.id] = next;
    }
    if (priceChanges.isNotEmpty) {
      _checkoutPriceChanges = List.unmodifiable(priceChanges);
      checkoutSubmissionState = BuyV2CheckoutSubmissionState.idle;
      _invalidateCheckoutQuote();
      _invalidateCommercialPaymentTerms();
      notice = 'Prices changed. Review the updated total to continue.';
      _persistCustomerState();
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<bool> _submitOrderAsync() async {
    if (checkoutBusy) return false;
    final previous = _navigationSurfaceIdentity;
    final lines = checkoutLines;
    if (lines.isEmpty) {
      returnToCatalogue();
      return false;
    }
    final address = selectedAddressOrNull;
    if (address == null) {
      view = BuyV2View.checkout;
      checkoutStep = BuyV2CheckoutStep.address;
      notice = 'Choose a delivery address to continue.';
      _notifyNavigationIfChanged(
        previous,
        BuyV2NavigationMotionDirection.replace,
      );
      return false;
    }
    if (checkoutPromiseReviewRequired) {
      notice = 'Review and accept the updated delivery times to continue.';
      notifyListeners();
      return false;
    }
    if (liveCartBenefitsEnabled && _hasSelectedCartBenefitReference) {
      final eligible = await refreshCartBenefits();
      if (!eligible ||
          cartBenefitsLoadState != BuyV2CartBenefitsLoadState.ready) {
        notice =
            cartBenefitsMessage ??
            'Coupon eligibility could not be confirmed. Review the current options.';
        notifyListeners();
        return false;
      }
    }
    if (!_refreshCheckoutFactsForProduction(lines)) return false;
    if (checkoutQuoteEnabled) {
      await refreshCheckoutQuote();
      if (checkoutQuoteReviewRequired) {
        notice =
            checkoutQuoteMessage ??
            'The current Checkout total could not be confirmed.';
        notifyListeners();
        return false;
      }
    }
    if (commercialPaymentTermsEnabled) {
      await refreshCommercialPaymentTerms();
      if (checkoutPaymentTermsReviewRequired) {
        notice =
            commercialPaymentTermsMessage ??
            'Choose an available payment term to continue.';
        notifyListeners();
        return false;
      }
    }
    final groups = checkoutFulfilmentGroups;
    final refreshedSnapshot = _deliveryPromiseSnapshotFor(groups);
    if (_checkoutPromiseSnapshot.isEmpty) {
      _checkoutPromiseSnapshot = refreshedSnapshot;
    }
    if (!mapEquals(_checkoutPromiseSnapshot, refreshedSnapshot)) {
      final changedKeys = {
        ..._checkoutPromiseSnapshot.keys,
        ...refreshedSnapshot.keys,
      }.where((key) => _checkoutPromiseSnapshot[key] != refreshedSnapshot[key]);
      _checkoutDeliveryPromiseChanges = [
        for (final key in changedKeys)
          (
            groupKey: key,
            previousPromise:
                _checkoutPromiseSnapshot[key]?.promise ?? 'Not quoted',
            previousPromisedByLabel:
                _checkoutPromiseSnapshot[key]?.promisedByLabel,
            currentPromise: refreshedSnapshot[key]?.promise ?? 'Unavailable',
            currentPromisedByLabel: refreshedSnapshot[key]?.promisedByLabel,
          ),
      ];
      _pendingCheckoutPromiseSnapshot = refreshedSnapshot;
      notice = 'Delivery times changed. Review the updated plan.';
      notifyListeners();
      return false;
    }
    if (checkoutPriceReviewRequired) {
      notice = 'Review and accept the updated prices to continue.';
      notifyListeners();
      return false;
    }
    if (checkoutRequiresResolution) {
      notice = 'Check the current payment before trying again.';
      notifyListeners();
      return false;
    }
    _checkoutIdempotencyKey ??=
        'shop-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-'
        '${_checkoutAttemptSequence++}';
    checkoutSubmissionState = BuyV2CheckoutSubmissionState.submitting;
    notice = null;
    _persistCustomerState();
    notifyListeners();
    final placement = await commerceAdapter.placeOrder(
      BuyV2OrderPlacementRequest(
        lines: List.unmodifiable(lines),
        address: address,
        paymentMethod: selectedPayment,
        total: checkoutPayableTotal,
        amountDueNow: checkoutAmountDueNow,
        idempotencyKey: _checkoutIdempotencyKey!,
        commercialPaymentTermIds: Map.unmodifiable(
          _selectedCommercialPaymentTermIds,
        ),
        checkoutQuoteId: _checkoutQuote?.id,
      ),
    );
    return _handleOrderPlacement(
      placement: placement,
      previous: previous,
      lines: lines,
      groups: groups,
      address: address,
    );
  }

  bool _handleOrderPlacement({
    required BuyV2OrderPlacementResult placement,
    required _BuyV2NavigationSurfaceIdentity previous,
    required List<BuyV2CartLine> lines,
    required List<BuyV2FulfilmentGroup> groups,
    required BuyV2Address address,
  }) {
    _paymentReference = placement.paymentReference ?? _paymentReference;
    _paymentActionUri = placement.paymentActionUri;
    _bankTransferInstructions =
        placement.bankTransferInstructions ?? _bankTransferInstructions;
    if (placement.outcome != BuyV2OrderPlacementOutcome.confirmed &&
        _openPlacementRecovery(placement, lines)) {
      return false;
    }
    if (placement.outcome != BuyV2OrderPlacementOutcome.confirmed) {
      checkoutStep = BuyV2CheckoutStep.payment;
      checkoutSubmissionState = switch (placement.outcome) {
        BuyV2OrderPlacementOutcome.paymentActionRequired
            when _validPaymentAction(placement) ||
                _validBankTransferAction(placement) =>
          BuyV2CheckoutSubmissionState.paymentActionRequired,
        BuyV2OrderPlacementOutcome.paymentActionRequired =>
          BuyV2CheckoutSubmissionState.failed,
        BuyV2OrderPlacementOutcome.paymentPending
            when _paymentReference != null =>
          BuyV2CheckoutSubmissionState.paymentPending,
        BuyV2OrderPlacementOutcome.paymentPending ||
        BuyV2OrderPlacementOutcome.paymentUnknown =>
          BuyV2CheckoutSubmissionState.paymentUnknown,
        BuyV2OrderPlacementOutcome.cancelled =>
          BuyV2CheckoutSubmissionState.cancelled,
        BuyV2OrderPlacementOutcome.unavailable =>
          BuyV2CheckoutSubmissionState.unavailable,
        BuyV2OrderPlacementOutcome.failed =>
          BuyV2CheckoutSubmissionState.failed,
        BuyV2OrderPlacementOutcome.confirmed =>
          BuyV2CheckoutSubmissionState.confirmed,
      };
      if (checkoutSubmissionState == BuyV2CheckoutSubmissionState.cancelled) {
        _checkoutIdempotencyKey = null;
        _paymentReference = null;
        _paymentActionUri = null;
        _bankTransferInstructions = null;
      }
      notice = null;
      _persistCustomerState();
      notifyListeners();
      return false;
    }
    if (!reviewDataEnabled && placement.orders.isEmpty) {
      checkoutSubmissionState = BuyV2CheckoutSubmissionState.failed;
      notice =
          'Order confirmation could not be verified. Your Cart has not changed.';
      notifyListeners();
      return false;
    }
    if (!reviewDataEnabled &&
        placement.orders.fold<int>(0, (total, order) => total + order.total) !=
            checkoutPayableTotal) {
      checkoutSubmissionState = BuyV2CheckoutSubmissionState.failed;
      notice = 'Order total could not be verified. Your Cart has not changed.';
      notifyListeners();
      return false;
    }
    final purchaseId = placement.purchaseReference ?? _nextLocalPurchaseId();
    _confirmedPurchaseId = purchaseId;
    _confirmedOrders = placement.orders.isNotEmpty
        ? List.unmodifiable(placement.orders)
        : _createOrdersForGroups(groups, address, purchaseId);
    _completeConfirmedOrder(previous: previous, lines: lines);
    return true;
  }

  bool _openPlacementRecovery(
    BuyV2OrderPlacementResult placement,
    List<BuyV2CartLine> lines,
  ) {
    final failureKind = placement.failureKind;
    if (failureKind == null) return false;
    if (failureKind == BuyV2OrderPlacementFailureKind.stockUnavailable) {
      final productId = placement.affectedProductId?.trim();
      final line = productId == null
          ? null
          : lines
                .where((candidate) => candidate.product.id == productId)
                .firstOrNull;
      if (line == null) return false;
      _checkoutAvailabilityIssue = (
        productId: line.product.id,
        title: line.product.title,
        orderabilityLabel: placement.customerMessage,
      );
      _clearCheckoutPaymentAttempt();
      checkoutSubmissionState = BuyV2CheckoutSubmissionState.idle;
      openRecovery(BuyV2RecoveryKind.stockUnavailable);
      return true;
    }
    _checkoutAvailabilityIssue = null;
    _clearCheckoutPaymentAttempt();
    checkoutSubmissionState = BuyV2CheckoutSubmissionState.idle;
    openRecovery(BuyV2RecoveryKind.serviceAreaUnavailable);
    return true;
  }

  void _clearCheckoutPaymentAttempt() {
    _checkoutIdempotencyKey = null;
    _paymentReference = null;
    _paymentActionUri = null;
    _bankTransferInstructions = null;
    _persistCustomerState();
  }

  bool _validPaymentAction(BuyV2OrderPlacementResult placement) {
    final uri = placement.paymentActionUri;
    final reference = placement.paymentReference?.trim();
    return uri != null &&
        (uri.scheme == 'upi' || uri.scheme == 'https') &&
        uri.host.isNotEmpty &&
        reference != null &&
        reference.isNotEmpty;
  }

  bool _validBankTransferAction(BuyV2OrderPlacementResult placement) {
    final instructions = placement.bankTransferInstructions;
    final reference = placement.paymentReference?.trim();
    return selectedPayment == 'Bank transfer' &&
        instructions != null &&
        instructions.beneficiaryName.trim().isNotEmpty &&
        instructions.bankName.trim().isNotEmpty &&
        instructions.accountNumber.trim().isNotEmpty &&
        instructions.ifsc.trim().isNotEmpty &&
        instructions.transferReference.trim().isNotEmpty &&
        reference != null &&
        reference.isNotEmpty &&
        instructions.transferReference == reference;
  }

  bool markBankTransferSent() {
    if (checkoutBusy ||
        selectedPayment != 'Bank transfer' ||
        checkoutSubmissionState !=
            BuyV2CheckoutSubmissionState.paymentActionRequired ||
        _bankTransferInstructions == null ||
        _paymentReference == null) {
      return false;
    }
    checkoutSubmissionState = BuyV2CheckoutSubmissionState.paymentPending;
    notice = 'Transfer submitted for checking. Do not transfer again.';
    _persistCustomerState();
    notifyListeners();
    return true;
  }

  Future<bool> continuePayment(BuyV2PaymentHandoff handoff) async {
    final uri = _paymentActionUri;
    if (checkoutBusy ||
        checkoutSubmissionState !=
            BuyV2CheckoutSubmissionState.paymentActionRequired ||
        uri == null) {
      return false;
    }
    checkoutSubmissionState = BuyV2CheckoutSubmissionState.submitting;
    notice = null;
    _persistCustomerState();
    notifyListeners();
    var opened = false;
    try {
      opened = await handoff(uri);
    } on Object {
      opened = false;
    }
    if (!opened) {
      checkoutSubmissionState = BuyV2CheckoutSubmissionState.failed;
      notice = null;
      _persistCustomerState();
      notifyListeners();
      return false;
    }
    checkoutSubmissionState = BuyV2CheckoutSubmissionState.paymentPending;
    notice = null;
    _persistCustomerState();
    notifyListeners();
    return true;
  }

  Future<bool> reconcilePayment() async {
    if (collectionCheckoutSelected || collectionCheckout?.unresolved == true) {
      return reconcileCollectionPurchase();
    }
    if (checkoutBusy) return false;
    final idempotencyKey = _checkoutIdempotencyKey;
    final paymentReference = _paymentReference;
    final address = selectedAddressOrNull;
    final lines = checkoutLines;
    if (idempotencyKey == null ||
        paymentReference == null ||
        address == null ||
        lines.isEmpty) {
      checkoutSubmissionState = BuyV2CheckoutSubmissionState.paymentUnknown;
      notice =
          'Payment status could not be matched. Do not pay again. Get order help.';
      _persistCustomerState();
      notifyListeners();
      return false;
    }
    final previous = _navigationSurfaceIdentity;
    final groups = checkoutFulfilmentGroups;
    checkoutSubmissionState = BuyV2CheckoutSubmissionState.submitting;
    notice = null;
    _persistCustomerState();
    notifyListeners();
    final placement = await commerceAdapter.reconcileOrder(
      idempotencyKey: idempotencyKey,
      paymentReference: paymentReference,
    );
    return _handleOrderPlacement(
      placement: placement,
      previous: previous,
      lines: lines,
      groups: groups,
      address: address,
    );
  }

  bool cancelPaymentAttempt() {
    if (checkoutBusy ||
        checkoutSubmissionState !=
            BuyV2CheckoutSubmissionState.paymentActionRequired) {
      return false;
    }
    checkoutSubmissionState = BuyV2CheckoutSubmissionState.cancelled;
    _checkoutIdempotencyKey = null;
    _paymentReference = null;
    _paymentActionUri = null;
    _bankTransferInstructions = null;
    notice = null;
    _persistCustomerState();
    notifyListeners();
    return true;
  }

  bool markPaymentStatusNeedsChecking() {
    if (checkoutBusy ||
        checkoutSubmissionState !=
            BuyV2CheckoutSubmissionState.paymentPending) {
      return false;
    }
    checkoutSubmissionState = BuyV2CheckoutSubmissionState.paymentUnknown;
    notice = null;
    _persistCustomerState();
    notifyListeners();
    return true;
  }

  void _completeConfirmedOrder({
    required _BuyV2NavigationSurfaceIdentity previous,
    required List<BuyV2CartLine> lines,
  }) {
    _orders.insertAll(0, _confirmedOrders);
    _confirmedDestinations = _confirmedOrders
        .map((order) => order.destination)
        .toSet();
    _confirmedProductCount = lines.length;
    _confirmedItemCount = checkoutItemCount;
    _confirmedTotal = checkoutPayableTotal;
    _confirmedAmountPaidNow = checkoutAmountDueNow;
    _confirmedBalanceDue = checkoutBalanceDue;
    for (final line in lines) {
      _cart.remove(line.product.id);
    }
    _pruneCartSelections();
    cartScope = BuyV2CartScope.all;
    checkoutScope = BuyV2CartScope.all;
    checkoutStep = BuyV2CheckoutStep.address;
    destination = BuyV2Destination.orders;
    view = BuyV2View.confirmation;
    checkoutSubmissionState = BuyV2CheckoutSubmissionState.confirmed;
    _checkoutIdempotencyKey = null;
    _paymentReference = null;
    _paymentActionUri = null;
    _bankTransferInstructions = null;
    purchaseOrderReference = '';
    notice = null;
    _clearCheckoutPromiseSnapshot();
    _persistCustomerState();
    _notifyNavigationIfChanged(
      previous,
      BuyV2NavigationMotionDirection.forward,
    );
  }

  List<BuyV2Order> _createOrdersForGroups(
    List<BuyV2FulfilmentGroup> groups,
    BuyV2Address address,
    String purchaseId,
  ) {
    final discountByKey = _checkoutGroupCouponSavings();
    final quoteLineByKey = {
      for (final line
          in _checkoutQuote?.lines ?? const <BuyV2CheckoutQuoteLine>[])
        line.fulfilmentKey: line,
    };
    return List.unmodifiable([
      for (final group in groups)
        () {
          final quoteLine = quoteLineByKey[group.key];
          return _createOrderForGroup(
            group,
            address,
            purchaseId,
            discount:
                quoteLine?.couponSaving ?? (discountByKey[group.key] ?? 0),
            tax: quoteLine?.tax ?? 0,
            freight: quoteLine?.freight ?? 0,
            deliveryFee: quoteLine?.deliveryFee ?? 0,
            paymentCharge: quoteLine?.paymentCharge ?? 0,
            totalOverride: quoteLine?.total,
          );
        }(),
    ]);
  }

  String _nextLocalPurchaseId() {
    final retained = _orders.map((order) => order.purchaseId).toSet();
    String candidate;
    do {
      candidate = 'BUY-NEW-${(_purchaseSequence++).toString().padLeft(2, '0')}';
    } while (retained.contains(candidate));
    return candidate;
  }

  String _nextLocalOrderId(String prefix) {
    final retained = _orders.map((order) => order.id).toSet();
    String candidate;
    do {
      candidate =
          '$prefix-NEW-${(_orderSequence++).toString().padLeft(2, '0')}';
    } while (retained.contains(candidate));
    return candidate;
  }

  BuyV2Order _createOrderForGroup(
    BuyV2FulfilmentGroup group,
    BuyV2Address address,
    String purchaseId, {
    int discount = 0,
    int tax = 0,
    int freight = 0,
    int deliveryFee = 0,
    int paymentCharge = 0,
    int? totalOverride,
  }) {
    final prefix = switch (group.destination) {
      BuyV2Destination.shop => 'MS',
      BuyV2Destination.wholesale => 'PO',
      BuyV2Destination.medicine => 'RX',
      BuyV2Destination.orders => 'MS',
    };
    final productCount = group.lines.length;
    final productCountLabel =
        '$productCount ${productCount == 1 ? 'product' : 'products'}';
    final quantityLabel = group.destination == BuyV2Destination.wholesale
        ? '${group.itemCount} ${group.itemCount == 1 ? 'pack' : 'packs'}'
        : '${group.itemCount} ${group.itemCount == 1 ? 'item' : 'items'}';
    final status = group.destination == BuyV2Destination.wholesale
        ? BuyV2OrderStatus.confirmed
        : BuyV2OrderStatus.preparing;
    final paymentTerm = selectedCommercialPaymentTermFor(group.key);
    return BuyV2Order(
      id: _nextLocalOrderId(prefix),
      destination: group.destination,
      title: '${group.destination.label} order',
      itemSummary:
          '$productCountLabel · $quantityLabel · ${address.label} · ${address.area}',
      total:
          totalOverride ??
          group.total +
              tipForGroup(group) -
              discount +
              tax +
              freight +
              deliveryFee +
              paymentCharge,
      partner: group.partner,
      partnerType: group.partnerType,
      promise: group.promise,
      destinationLabel: address.shortLine,
      progress: status == BuyV2OrderStatus.confirmed ? .2 : .4,
      status: status,
      purchaseId: purchaseId,
      promisedByLabel: group.promisedByLabel,
      productIds: group.productIds,
      lines: List.unmodifiable(group.lines),
      paymentMethod: selectedPayment,
      purchaseOrderReference: selectedPayment == 'Purchase order'
          ? purchaseOrderReference.trim()
          : null,
      recipient: address.recipient,
      addressLine: '${address.line}, ${address.area} ${address.pinCode}',
      deliveryInstruction: selectedDeliveryInstructionFor(
        group.destination,
      )?.label,
      tip: tipForGroup(group),
      discount: discount,
      paymentTermLabel: paymentTerm == null
          ? null
          : _commercialPaymentTermLabel(paymentTerm.kind),
      amountPaidNow: paymentTerm?.amountDueNow,
      balanceDue: paymentTerm?.balanceDue ?? 0,
      balanceDueLabel: paymentTerm?.balanceDueLabel,
      paymentStatusLabel: paymentTerm == null
          ? null
          : paymentTerm.balanceDue == 0
          ? 'Paid in full'
          : 'Booking amount paid · balance ${paymentTerm.balanceDueLabel}',
      buyerName: group.destination == BuyV2Destination.wholesale
          ? 'Shree Balaji Retail'
          : null,
      buyerType: group.destination == BuyV2Destination.wholesale
          ? 'Retailer business'
          : null,
      tax: tax,
      freight: freight,
      deliveryFee: deliveryFee,
      paymentCharge: paymentCharge,
      dispatchPromise: group.dispatchPromise,
      deliveryPartnerName: group.deliveryProviderName,
      deliveryPartnerType: group.deliveryProviderName == null
          ? null
          : 'Delivery partner',
      deliveryServiceLevel: group.deliveryServiceLevel,
    );
  }

  bool acceptCheckoutPromiseChanges() {
    final pending = _pendingCheckoutPromiseSnapshot;
    if (pending == null) return false;
    _checkoutPromiseSnapshot = Map.unmodifiable(pending);
    _pendingCheckoutPromiseSnapshot = null;
    _checkoutDeliveryPromiseChanges = [];
    notice = null;
    notifyListeners();
    return true;
  }

  void _pruneCartSelections() {
    final destinations = _cart.values
        .map((line) => line.product.destination)
        .toSet();
    _deliveryInstructionIds.removeWhere(
      (destination, _) => !destinations.contains(destination),
    );
    _selectedCartBenefitRefs.removeWhere((key, _) {
      final destinationName = key.split('|').firstOrNull;
      return !destinations.any(
        (destination) => destination.name == destinationName,
      );
    });
    final groupKeys = _fulfilmentGroupsFor(
      _cart.values.toList(growable: false),
    ).map((group) => group.key).toSet();
    _tipsByFulfilmentKey.removeWhere((key, _) => !groupKeys.contains(key));
    _invalidateLiveCartBenefits();
    if (_cart.isNotEmpty && liveCartBenefitsEnabled) {
      unawaited(refreshCartBenefits());
    }
    _invalidateCheckoutQuote();
    if (_cart.isNotEmpty && checkoutQuoteEnabled) {
      unawaited(refreshCheckoutQuote());
    }
    _invalidateCommercialPaymentTerms();
    if (_cart.isNotEmpty &&
        commercialPaymentTermsEnabled &&
        !checkoutQuoteEnabled) {
      unawaited(refreshCommercialPaymentTerms());
    }
  }

  bool reorder(BuyV2Order order) {
    final exactProducts = productsForOrder(order);
    if (exactProducts.isEmpty ||
        (order.productIds.isNotEmpty &&
            exactProducts.length != order.productIds.length) ||
        exactProducts.map((product) => product.id).toSet().length !=
            exactProducts.length) {
      notice = 'Products from this order could not be found.';
      notifyListeners();
      return false;
    }
    if (order.destination == BuyV2Destination.wholesale && !businessVerified) {
      notice = 'Complete your business profile to place a wholesale order.';
      notifyListeners();
      return false;
    }
    if (exactProducts.any(
      (product) =>
          product.requiresPrescription &&
          !_prescriptionApprovedQuantities.containsKey(product.id),
    )) {
      notice = 'Prescription review is required before reordering medicines.';
      notifyListeners();
      return false;
    }
    for (final product in exactProducts) {
      final approvedMaximum = _prescriptionApprovedQuantities[product.id];
      final nextQuantity =
          (_cart[product.id]?.quantity ?? 0) + product.minimumOrder;
      if (approvedMaximum != null && nextQuantity > approvedMaximum) {
        notice = 'Prescription quantity reached for ${product.title}.';
        notifyListeners();
        return false;
      }
    }

    final previous = _navigationSurfaceIdentity;
    destination = order.destination;
    for (final product in exactProducts) {
      final current = _cart[product.id];
      _cart[product.id] = BuyV2CartLine(
        product: product,
        quantity: (current?.quantity ?? 0) + product.minimumOrder,
      );
    }
    cartScope = switch (order.destination) {
      BuyV2Destination.shop => BuyV2CartScope.shop,
      BuyV2Destination.wholesale => BuyV2CartScope.wholesale,
      BuyV2Destination.medicine => BuyV2CartScope.medicine,
      BuyV2Destination.orders => BuyV2CartScope.all,
    };
    _cartScrollOffsets[cartScope] = 0;
    view = BuyV2View.cart;
    notice = 'Previous products are ready to edit.';
    cartAcknowledgement = 'Previous products are ready to edit.';
    _cartAcknowledgementDestination = order.destination;
    _persistCustomerState();
    _notifyNavigationIfChanged(
      previous,
      BuyV2NavigationMotionDirection.forward,
    );
    return true;
  }

  void openRecovery(BuyV2RecoveryKind kind) {
    final previous = _navigationSurfaceIdentity;
    if (kind != BuyV2RecoveryKind.stockUnavailable) {
      _checkoutAvailabilityIssue = null;
    }
    if (view != BuyV2View.recovery) {
      _recoveryOrigin = (
        destination: destination,
        view: view,
        cartScope: cartScope,
        checkoutScope: checkoutScope,
        ordersTab: ordersTab,
        shopCategoryId: shopCategoryId,
        wholesaleCategoryId: wholesaleCategoryId,
        medicineCategoryId: medicineCategoryId,
        query: query,
        filter: selectedFilter,
        productId: selectedProductId,
        orderId: _selectedOrderId,
      );
    }
    recoveryKind = kind;
    view = BuyV2View.recovery;
    notice = null;
    _notifyNavigationIfChanged(
      previous,
      BuyV2NavigationMotionDirection.forward,
    );
  }

  void retryRecovery() {
    _restoreRecoveryOrigin();
  }

  bool retryCheckoutAvailability() {
    final issue = _checkoutAvailabilityIssue;
    if (recoveryKind != BuyV2RecoveryKind.stockUnavailable || issue == null) {
      return false;
    }
    final product = findProduct(issue.productId);
    if (product == null) {
      notice = 'This product could not be found.';
      notifyListeners();
      return false;
    }
    final next = productFactsAdapter.snapshotFor(product);
    if (!_validProductFacts(product, next) || next.stale) {
      notice = 'Availability could not be confirmed. Try again.';
      notifyListeners();
      return false;
    }
    final availability = next.orderabilityLabel.toLowerCase();
    if (availability.contains('unavailable') ||
        availability.contains('out of stock') ||
        availability.contains('not available')) {
      _checkoutAvailabilityIssue = (
        productId: product.id,
        title: product.title,
        orderabilityLabel: next.orderabilityLabel,
      );
      notice = '${product.title} is still unavailable.';
      notifyListeners();
      return false;
    }
    final previous = _navigationSurfaceIdentity;
    final updatedProduct = product.copyWith(
      price: next.price,
      deliveryPromise: next.deliveryPromise,
      seller: next.partner,
      confirmedOn: 'Checked now',
    );
    final catalogueIndex = _catalogueProducts.indexWhere(
      (candidate) => candidate.id == product.id,
    );
    if (catalogueIndex >= 0) {
      _catalogueProducts[catalogueIndex] = updatedProduct;
    }
    final cartLine = _cart[product.id];
    if (cartLine != null) {
      _cart[product.id] = cartLine.copyWith(product: updatedProduct);
    }
    _productFacts[product.id] = next;
    if (next.price != product.price) {
      _checkoutPriceChanges = [
        (
          productId: product.id,
          title: product.title,
          previousPrice: product.price,
          currentPrice: next.price,
        ),
      ];
    }
    _checkoutAvailabilityIssue = null;
    _restoreRecoveryOrigin(notify: false);
    notice = next.price == product.price
        ? '${product.title} is available. Review Checkout to continue.'
        : 'The current price changed. Review the updated total to continue.';
    _persistCustomerState();
    _notifyNavigationIfChanged(previous, BuyV2NavigationMotionDirection.back);
    return true;
  }

  bool removeCheckoutIssueProduct() {
    final issue = _checkoutAvailabilityIssue;
    if (recoveryKind != BuyV2RecoveryKind.stockUnavailable || issue == null) {
      return false;
    }
    final previous = _navigationSurfaceIdentity;
    final removed = _cart.remove(issue.productId);
    if (removed == null) return false;
    _checkoutAvailabilityIssue = null;
    _restoreRecoveryOrigin(notify: false);
    _acknowledgeCart(
      '${removed.product.title} removed',
      destination: removed.product.destination,
    );
    _pruneCartSelections();
    if (_cart.isEmpty) {
      destination = removed.product.destination;
      view = BuyV2View.catalogue;
      cartScope = BuyV2CartScope.all;
    } else if (checkoutLines.isEmpty) {
      view = BuyV2View.cart;
      cartScope = BuyV2CartScope.all;
    }
    _persistCustomerState();
    _notifyNavigationIfChanged(previous, BuyV2NavigationMotionDirection.back);
    return true;
  }

  bool openCheckoutIssueProduct() {
    final issue = _checkoutAvailabilityIssue;
    if (recoveryKind != BuyV2RecoveryKind.stockUnavailable || issue == null) {
      return false;
    }
    _restoreRecoveryOrigin(notify: false);
    _checkoutAvailabilityIssue = null;
    return openProduct(issue.productId);
  }

  bool openRecoveryOrderHelp() {
    if (!canOpenRecoveryOrderHelp) return false;
    return _restoreRecoveryOrigin();
  }

  void _clearRecoveryOriginIfActive() {
    if (view != BuyV2View.recovery) return;
    recoveryKind = null;
    _recoveryOrigin = null;
  }

  bool _restoreRecoveryOrigin({bool notify = true}) {
    final previous = _navigationSurfaceIdentity;
    final origin = _recoveryOrigin;
    recoveryKind = null;
    _recoveryOrigin = null;
    _checkoutAvailabilityIssue = null;

    if (origin == null || origin.view == BuyV2View.recovery) {
      destination = BuyV2Destination.shop;
      view = BuyV2View.catalogue;
      query = '';
      selectedFilter = null;
      selectedProductId = null;
      _selectedOrderId = null;
      notice = null;
      if (notify) {
        _notifyNavigationIfChanged(
          previous,
          BuyV2NavigationMotionDirection.back,
        );
      }
      return false;
    }

    destination = origin.destination;
    view = origin.view;
    cartScope = origin.cartScope;
    checkoutScope = origin.checkoutScope;
    ordersTab = origin.ordersTab;
    shopCategoryId = origin.shopCategoryId;
    wholesaleCategoryId = origin.wholesaleCategoryId;
    medicineCategoryId = origin.medicineCategoryId;
    query = origin.query;
    selectedFilter = origin.filter;
    selectedProductId = origin.productId;
    _selectedOrderId = origin.orderId;
    notice = null;
    var exact = true;

    switch (origin.view) {
      case BuyV2View.product:
        final product = selectedProduct;
        if (product == null || product.destination != origin.destination) {
          selectedProductId = null;
          view = BuyV2View.catalogue;
          notice = 'This product could not be found.';
          exact = false;
        }
      case BuyV2View.cart:
        if (_linesForScope(origin.cartScope).isEmpty) {
          view = BuyV2View.catalogue;
          notice = 'This Cart section is empty.';
          exact = false;
        }
      case BuyV2View.checkout:
        if (_linesForScope(origin.checkoutScope).isEmpty) {
          if (_linesForScope(origin.cartScope).isEmpty) {
            view = BuyV2View.catalogue;
            notice = 'Choose a product to continue.';
          } else {
            view = BuyV2View.cart;
            notice = 'Review your Cart before continuing.';
          }
          exact = false;
        } else if (selectedAddressOrNull == null) {
          checkoutScope = origin.checkoutScope;
          view = BuyV2View.checkout;
          checkoutStep = BuyV2CheckoutStep.address;
          notice = 'Choose a delivery address to continue.';
          exact = false;
        }
      case BuyV2View.confirmation:
        if (_confirmedOrders.isEmpty || _confirmedItemCount <= 0) {
          destination = BuyV2Destination.orders;
          view = BuyV2View.catalogue;
          notice = 'This confirmation is no longer available. View Orders.';
          exact = false;
        }
      case BuyV2View.tracking || BuyV2View.orderItems:
        if (selectedOrderOrNull == null) {
          destination = BuyV2Destination.orders;
          view = BuyV2View.catalogue;
          notice = 'This order could not be found.';
          exact = false;
        }
      case BuyV2View.assist:
        final requiresExactOrder =
            _assistReturnView == BuyV2View.tracking ||
            _assistReturnView == BuyV2View.orderItems;
        if (requiresExactOrder && selectedOrderOrNull == null) {
          destination = BuyV2Destination.orders;
          view = BuyV2View.catalogue;
          notice = 'This order could not be found.';
          exact = false;
        }
      case BuyV2View.catalogue || BuyV2View.account:
        break;
      case BuyV2View.recovery:
        throw StateError('Recovery cannot be its own retained origin.');
    }

    if (notify) {
      _notifyNavigationIfChanged(previous, BuyV2NavigationMotionDirection.back);
    }
    return exact;
  }

  void clearNotice() {
    if (notice == null) return;
    notice = null;
    notifyListeners();
  }

  void clearCartAcknowledgement() {
    if (cartAcknowledgement == null) return;
    cartAcknowledgement = null;
    _cartAcknowledgementDestination = null;
    notifyListeners();
  }

  void _acknowledgeCart(String message, {BuyV2Destination? destination}) {
    notice = null;
    cartAcknowledgement = message;
    _cartAcknowledgementDestination = destination;
  }

  void showNotice(String message) {
    notice = message;
    notifyListeners();
  }
}
