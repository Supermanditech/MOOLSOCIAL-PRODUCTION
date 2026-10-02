import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:shared_preferences/shared_preferences.dart';

import 'buy_v2_content_contracts.dart';
import 'buy_v2_models.dart';

abstract interface class BuyV2SavedProductsStore {
  const BuyV2SavedProductsStore();

  String? get ownerScope;

  Future<Set<String>?> read();

  Future<bool> write(Set<String> savedProductKeys);
}

/// Buy navigation retained within the exact Store operation owner scope.
@immutable
class BuyV2ProcurementNavigationSnapshot {
  const BuyV2ProcurementNavigationSnapshot({
    this.destination = BuyV2Destination.wholesale,
    this.view = BuyV2View.catalogue,
    this.categoryId = 'all',
    this.query = '',
    this.filter,
    this.productId,
    this.orderId,
    this.cartScope = BuyV2CartScope.wholesale,
    this.checkoutScope = BuyV2CartScope.wholesale,
    this.productReturnDestination = BuyV2Destination.wholesale,
    this.productReturnView = BuyV2View.catalogue,
    this.comparisonOrigins = const [],
    this.cartReturnProductId,
    this.cartReturnDestination = BuyV2Destination.wholesale,
    this.cartReturnOriginDestination,
    this.cartReturnOriginView,
    this.cartReturnComparisonOrigins = const [],
    this.showingSavedProducts = false,
    this.cartScrollOffset = 0,
  });

  final BuyV2Destination destination;
  final BuyV2View view;
  final String categoryId;
  final String query;
  final String? filter;
  final String? productId;
  final String? orderId;
  final BuyV2CartScope cartScope;
  final BuyV2CartScope checkoutScope;
  final BuyV2Destination productReturnDestination;
  final BuyV2View productReturnView;
  final List<String> comparisonOrigins;
  final String? cartReturnProductId;
  final BuyV2Destination cartReturnDestination;
  final BuyV2Destination? cartReturnOriginDestination;
  final BuyV2View? cartReturnOriginView;
  final List<String> cartReturnComparisonOrigins;
  final bool showingSavedProducts;
  final double cartScrollOffset;
}

/// Retained display/offer identity only. Cached data never grants eligibility.
@immutable
class BuyV2ProcurementDraftSnapshot {
  const BuyV2ProcurementDraftSnapshot({
    required this.ownerScope,
    this.cartProducts = const {},
    this.navigation,
  });

  final String ownerScope;
  final Map<String, BuyV2Product> cartProducts;
  final BuyV2ProcurementNavigationSnapshot? navigation;

  static BuyV2Product retainedProduct(String id, BuyV2Product? product) {
    final previous = product?.procurementSupplierGrant;
    final identity = BuyV2ProcurementSupplierGrant(
      workspaceId: previous?.workspaceId ?? '',
      storeId: previous?.storeId ?? product?.storeId ?? '',
      role: BuyV2SupplierWorkspaceRole.unknown,
      approved: false,
      listingId: previous?.listingId ?? id,
      productCanonicalId:
          previous?.productCanonicalId ?? product?.canonicalId ?? id,
      offerId: previous?.offerId ?? '',
      offerRevision: previous?.offerRevision ?? '',
      channel: BuyV2SupplierListingChannel.unknown,
      published: false,
      validUntil: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
    if (product != null) {
      return product.copyWith(procurementSupplierGrant: identity);
    }
    return BuyV2Product(
      id: id,
      destination: BuyV2Destination.wholesale,
      categoryId: 'all',
      brand: '',
      title: 'Unavailable item',
      variant: '',
      pack: 'Pack details unavailable',
      price: 0,
      unitPrice: 'Price unavailable',
      badge: '',
      seller: 'Supplier unavailable',
      sellerType: '',
      deliveryPromise: 'Availability not confirmed',
      origin: '',
      confirmedOn: '',
      visualLabel: '',
      visualKind: '',
      procurementSupplierGrant: identity,
      catalogueListing: false,
    );
  }
}

/// Unsent customer text; never a published review or proof of eligibility.
@immutable
class BuyV2ProductReviewDraft {
  const BuyV2ProductReviewDraft({required this.rating, required this.comment});
  final int rating;
  final String comment;
  bool get valid =>
      rating >= 0 && rating <= 5 && comment.characters.length <= 8000;
}

@immutable
class BuyV2CustomerStateSnapshot {
  const BuyV2CustomerStateSnapshot({
    this.shoppingRegionId,
    this.shoppingGooglePlaceId,
    this.shoppingAreaScope,
    this.cartQuantities = const {},
    this.excludedCartProductIds = const {},
    this.productIdentityKeys = const {},
    this.reviewDrafts = const {},
    this.procurementDraft,
    this.addresses = const [],
    this.selectedAddressId,
    this.savedProductKeys = const {},
    this.deliveryInstructionIds = const {},
    this.customDeliveryInstructions = const {},
    this.publicDeliveryInstruction,
    this.selectedPayment,
    this.purchaseOrderReference,
    this.pendingPurchaseOrderAccountId,
    this.pendingPurchaseOrderRequestId,
    this.pendingPurchaseOrderRevision,
    this.checkoutIdempotencyKey,
    this.checkoutPaymentAttempt,
    this.legacyCheckoutAttempt,
    this.retainedLegacyCheckoutAttempts = const [],
    this.retainedCheckoutPaymentAttempts = const [],
    this.paymentRecoveryIncomplete = false,
    this.paymentReference,
    this.paymentActionUri,
    this.bankTransferInstructions,
    this.shoppingIntent,
    this.checkoutSubmissionState,
    this.selectedBrands = const {},
    this.maximumPrice,
    this.packFilter,
    this.fulfilmentMode,
    this.productSort,
    this.availableOnly = false,
    this.recentlyViewedProductIds = const [],
    this.recentSearches = const {},
    this.orders = const [],
  });

  final Map<String, int> cartQuantities;
  final Set<String> excludedCartProductIds;

  /// Retained identity constraints only, never listing or purchase authority.
  final Map<String, String> productIdentityKeys;
  final Map<String, BuyV2ProductReviewDraft> reviewDrafts;
  // Persist selection identifiers, not Google response labels or coordinates.
  final String? shoppingRegionId;
  final String? shoppingGooglePlaceId;
  final String? shoppingAreaScope;
  final BuyV2ProcurementDraftSnapshot? procurementDraft;
  final List<BuyV2Address> addresses;
  final String? selectedAddressId;
  final Set<String> savedProductKeys;
  final Map<BuyV2Destination, String> deliveryInstructionIds;
  final Map<BuyV2Destination, String> customDeliveryInstructions;
  // Empty explicitly clears a public note; null permits retained-note migration.
  final String? publicDeliveryInstruction;
  final String? selectedPayment;
  final String? purchaseOrderReference;
  final String? pendingPurchaseOrderAccountId;
  final String? pendingPurchaseOrderRequestId;
  final String? pendingPurchaseOrderRevision;
  final String? checkoutIdempotencyKey;
  final BuyV2CheckoutPaymentAttempt? checkoutPaymentAttempt;
  final BuyV2LegacyCheckoutAttempt? legacyCheckoutAttempt;
  final List<BuyV2LegacyCheckoutAttempt> retainedLegacyCheckoutAttempts;
  final List<BuyV2CheckoutPaymentAttempt> retainedCheckoutPaymentAttempts;
  final bool paymentRecoveryIncomplete;
  final String? paymentReference;
  final Uri? paymentActionUri;
  final BuyV2BankTransferInstructions? bankTransferInstructions;
  final String? shoppingIntent;
  final String? checkoutSubmissionState;
  final Set<String> selectedBrands;
  final int? maximumPrice;
  final String? packFilter;
  final String? fulfilmentMode;
  final String? productSort;
  final bool availableOnly;
  final List<String> recentlyViewedProductIds;
  final Map<BuyV2Destination, List<String>> recentSearches;
  final List<BuyV2Order> orders;
}

abstract interface class BuyV2CustomerStateStore {
  const BuyV2CustomerStateStore();

  String? get ownerScope;

  Future<BuyV2CustomerStateSnapshot?> read();

  Future<bool> write(BuyV2CustomerStateSnapshot snapshot);
}

BuyV2CustomerStateStore createBuyV2DeviceReviewCustomerStateStore() =>
    BuyV2SharedPreferencesCustomerStateStore(
      SharedPreferencesAsync(),
      ownerScope: 'device-review:buy',
    );

final class BuyV2SharedPreferencesCustomerStateStore
    implements BuyV2CustomerStateStore {
  const BuyV2SharedPreferencesCustomerStateStore(
    this._preferences, {
    required this.ownerScope,
  });

  final SharedPreferencesAsync _preferences;

  @override
  final String ownerScope;

  String get _key => 'moolsocial.buy.customer-state.$ownerScope.v1';

  @override
  Future<BuyV2CustomerStateSnapshot?> read() async {
    try {
      final source = await _preferences.getString(_key);
      if (source == null || source.trim().isEmpty) return null;
      final decoded = jsonDecode(source);
      if (decoded is! Map<String, Object?>) return null;
      if (decoded.containsKey('procurementDraft') &&
          _decodeProcurementDraft(decoded['procurementDraft']) == null &&
          decoded['checkoutIdempotencyKey'] == null &&
          !decoded.containsKey('legacyCheckoutAttempt') &&
          !decoded.containsKey('checkoutPaymentAttempt')) {
        return null;
      }
      return _decodeSnapshot(decoded);
    } on Object {
      return null;
    }
  }

  @override
  Future<bool> write(BuyV2CustomerStateSnapshot snapshot) async {
    if (snapshot.legacyCheckoutAttempt?.ownerScope != null &&
            snapshot.legacyCheckoutAttempt!.ownerScope != ownerScope ||
        snapshot.retainedLegacyCheckoutAttempts.any(
          (attempt) => attempt.ownerScope != ownerScope,
        ) ||
        snapshot.retainedCheckoutPaymentAttempts.any(
          (attempt) => attempt.ownerScope != ownerScope,
        )) {
      return false;
    }
    if (snapshot.procurementDraft case final draft?
        when draft.ownerScope != ownerScope) {
      return false;
    }
    try {
      await _preferences.setString(_key, jsonEncode(_encodeSnapshot(snapshot)));
      return true;
    } on Object {
      return false;
    }
  }

  Map<String, Object?> _encodeSnapshot(BuyV2CustomerStateSnapshot snapshot) => {
    'shoppingRegionId': snapshot.shoppingRegionId,
    'shoppingGooglePlaceId': snapshot.shoppingGooglePlaceId,
    'shoppingAreaScope': snapshot.shoppingAreaScope,
    'cartQuantities': snapshot.cartQuantities,
    'excludedCartProductIds': snapshot.excludedCartProductIds.toList(
      growable: false,
    ),
    'productIdentityKeys': snapshot.productIdentityKeys,
    'reviewDrafts': {
      for (final entry in snapshot.reviewDrafts.entries)
        if (entry.key.isNotEmpty && entry.value.valid)
          entry.key: {
            'rating': entry.value.rating,
            'comment': entry.value.comment,
          },
    },
    if (snapshot.procurementDraft case final draft?)
      'procurementDraft': _encodeProcurementDraft(draft),
    'addresses': [
      for (final address in snapshot.addresses) _encodeAddress(address),
    ],
    'selectedAddressId': snapshot.selectedAddressId,
    'savedProductKeys': snapshot.savedProductKeys.toList(growable: false),
    'publicDeliveryInstruction': ?snapshot.publicDeliveryInstruction,
    'customDeliveryInstructions': {
      for (final entry in snapshot.customDeliveryInstructions.entries)
        entry.key.name: entry.value,
    },
    'deliveryInstructionIds': {
      for (final entry in snapshot.deliveryInstructionIds.entries)
        entry.key.name: entry.value,
    },
    'selectedPayment': snapshot.selectedPayment,
    'purchaseOrderReference': snapshot.purchaseOrderReference,
    'pendingPurchaseOrderAccountId': snapshot.pendingPurchaseOrderAccountId,
    'pendingPurchaseOrderRequestId': snapshot.pendingPurchaseOrderRequestId,
    'pendingPurchaseOrderRevision': snapshot.pendingPurchaseOrderRevision,
    'checkoutIdempotencyKey': snapshot.checkoutIdempotencyKey,
    if (snapshot.checkoutPaymentAttempt case final attempt?)
      'checkoutPaymentAttempt': _encodePaymentAttempt(attempt),
    if (snapshot.legacyCheckoutAttempt case final attempt?)
      'legacyCheckoutAttempt': _encodeLegacyAttempt(attempt),
    'retainedLegacyCheckoutAttempts': [
      for (final attempt in snapshot.retainedLegacyCheckoutAttempts)
        _encodeLegacyAttempt(attempt),
    ],
    'retainedCheckoutPaymentAttempts': [
      for (final attempt in snapshot.retainedCheckoutPaymentAttempts)
        _encodePaymentAttempt(attempt),
    ],
    'paymentRecoveryIncomplete': snapshot.paymentRecoveryIncomplete,
    'paymentReference': snapshot.paymentReference,
    'paymentActionUri': snapshot.paymentActionUri?.toString(),
    if (snapshot.bankTransferInstructions case final bank?)
      'bankTransferInstructions': _encodeTransfer(bank),
    'shoppingIntent': snapshot.shoppingIntent,
    'checkoutSubmissionState': snapshot.checkoutSubmissionState,
    'selectedBrands': snapshot.selectedBrands.toList(growable: false),
    'maximumPrice': snapshot.maximumPrice,
    'packFilter': snapshot.packFilter,
    'fulfilmentMode': snapshot.fulfilmentMode,
    'productSort': snapshot.productSort,
    'availableOnly': snapshot.availableOnly,
    'recentlyViewedProductIds': snapshot.recentlyViewedProductIds,
    'recentSearches': {
      for (final entry in snapshot.recentSearches.entries)
        entry.key.name: entry.value,
    },
    'orders': [for (final order in snapshot.orders) _encodeOrder(order)],
  };

  Map<String, BuyV2ProductReviewDraft> _decodeReviewDrafts(Object? value) {
    if (value is! Map) return const {};
    final drafts = <String, BuyV2ProductReviewDraft>{};
    for (final entry in value.entries) {
      final key = entry.key;
      final data = entry.value;
      if (key is! String || key.isEmpty || data is! Map) continue;
      final rating = data['rating'];
      final comment = data['comment'];
      if (rating is! int || comment is! String) continue;
      final draft = BuyV2ProductReviewDraft(rating: rating, comment: comment);
      if (draft.valid) drafts[key] = draft;
    }
    return Map.unmodifiable(drafts);
  }

  BuyV2CustomerStateSnapshot _decodeSnapshot(Map<String, Object?> source) =>
      BuyV2CustomerStateSnapshot(
        shoppingRegionId: _string(source['shoppingRegionId']),
        shoppingGooglePlaceId: _string(source['shoppingGooglePlaceId']),
        shoppingAreaScope: _string(source['shoppingAreaScope']),
        cartQuantities: _stringIntMap(source['cartQuantities']),
        excludedCartProductIds: _stringList(
          source['excludedCartProductIds'],
        ).toSet(),
        productIdentityKeys: _stringMap(source['productIdentityKeys']),
        reviewDrafts: _decodeReviewDrafts(source['reviewDrafts']),
        procurementDraft: _decodeProcurementDraft(source['procurementDraft']),
        addresses: _objectList(
          source['addresses'],
        ).map(_decodeAddress).whereType<BuyV2Address>().toList(growable: false),
        selectedAddressId: _string(source['selectedAddressId']),
        savedProductKeys: _stringList(source['savedProductKeys']).toSet(),
        publicDeliveryInstruction: source['publicDeliveryInstruction'] is String
            ? source['publicDeliveryInstruction'] as String
            : null,
        customDeliveryInstructions: _destinationStringMap(
          source['customDeliveryInstructions'],
        ),
        deliveryInstructionIds: _destinationStringMap(
          source['deliveryInstructionIds'],
        ),
        selectedPayment: _string(source['selectedPayment']),
        purchaseOrderReference: _string(source['purchaseOrderReference']),
        pendingPurchaseOrderAccountId: _string(
          source['pendingPurchaseOrderAccountId'],
        ),
        pendingPurchaseOrderRequestId: _string(
          source['pendingPurchaseOrderRequestId'],
        ),
        pendingPurchaseOrderRevision: _string(
          source['pendingPurchaseOrderRevision'],
        ),
        checkoutIdempotencyKey: _string(source['checkoutIdempotencyKey']),
        checkoutPaymentAttempt: _decodePaymentAttempt(
          source['checkoutPaymentAttempt'],
        ),
        legacyCheckoutAttempt: _decodeLegacyAttempt(
          source['legacyCheckoutAttempt'],
        ),
        retainedLegacyCheckoutAttempts:
            _objectList(source['retainedLegacyCheckoutAttempts'])
                .map(_decodeLegacyAttempt)
                .whereType<BuyV2LegacyCheckoutAttempt>()
                .toList(growable: false),
        retainedCheckoutPaymentAttempts:
            _objectList(source['retainedCheckoutPaymentAttempts'])
                .map(_decodePaymentAttempt)
                .whereType<BuyV2CheckoutPaymentAttempt>()
                .toList(growable: false),
        paymentRecoveryIncomplete: _paymentRecoveryIncomplete(source),
        paymentReference: _string(source['paymentReference']),
        paymentActionUri: _uri(source['paymentActionUri']),
        bankTransferInstructions: _decodeTransfer(
          source['bankTransferInstructions'],
        ),
        shoppingIntent: _string(source['shoppingIntent']),
        checkoutSubmissionState: _string(source['checkoutSubmissionState']),
        selectedBrands: _stringList(source['selectedBrands']).toSet(),
        maximumPrice: _integer(source['maximumPrice']),
        packFilter: _string(source['packFilter']),
        fulfilmentMode: _string(source['fulfilmentMode']),
        productSort: _string(source['productSort']),
        availableOnly: source['availableOnly'] == true,
        recentlyViewedProductIds: _stringList(
          source['recentlyViewedProductIds'],
        ),
        recentSearches: _destinationStringListMap(source['recentSearches']),
        orders: _objectList(
          source['orders'],
        ).map(_decodeOrder).whereType<BuyV2Order>().toList(growable: false),
      );

  Map<String, Object?> _encodePaymentAttempt(
    BuyV2CheckoutPaymentAttempt attempt,
  ) => {
    'version': 1,
    'id': attempt.id,
    'ownerScope': attempt.ownerScope,
    'quoteValidUntil': attempt.quoteValidUntil.toIso8601String(),
    'lateSettlementNeedsReview': attempt.lateSettlementNeedsReview,
    'groups': [for (final group in attempt.groups) _encodeFrozenPayment(group)],
  };

  Map<String, Object?> _encodeFrozenPayment(BuyV2CheckoutGroupAttempt group) =>
      {
        'fulfilmentKeys': group.fulfilmentKeys.toList(),
        'obligations': [
          for (final value in group.obligations)
            {
              'fulfilmentKey': value.fulfilmentKey,
              'productIds': value.productIds.toList(),
              'totalMinor': value.totalMinor,
              'dueNowMinor': value.dueNowMinor,
            },
        ],
        'state': group.state.name,
        'financiallyClosed': group.financiallyClosed,
        'paymentReference': group.paymentReference,
        'paymentActionUri': group.paymentActionUri?.toString(),
        if (group.bankTransferInstructions case final bank?)
          'bankTransferInstructions': _encodeTransfer(bank),
        'confirmedOrderIds': group.confirmedOrderIds,
        'request': {
          'checkoutAttemptId': group.request.checkoutAttemptId,
          'paymentGroupId': group.request.paymentGroupId,
          'idempotencyKey': group.request.idempotencyKey,
          'paymentMethod': group.request.paymentMethod,
          'total': group.request.total,
          'amountDueNow': group.request.amountDueNow,
          'address': _encodeAddress(group.request.address),
          'commercialPaymentTermIds': group.request.commercialPaymentTermIds,
          'deliveryInstructionsByProductId':
              group.request.deliveryInstructionsByProductId,
          'checkoutQuoteId': group.request.checkoutQuoteId,
          'purchaseOrderRequestId': group.request.purchaseOrderRequestId,
          'purchaseOrderRevision': group.request.purchaseOrderRevision,
          'useUpiQr': group.request.useUpiQr,
          if (group.request.procurementContext case final context?)
            'procurementContext': _encodeProcurementContext(context),
          'lines': [
            for (final line in group.request.lines)
              {
                'productId': line.product.id,
                'quantity': line.quantity,
                'purchasedProduct': _encodePurchasedProduct(line.product),
              },
          ],
        },
      };

  Map<String, Object?> _encodeLegacyAttempt(
    BuyV2LegacyCheckoutAttempt attempt,
  ) => {
    'version': 1,
    'ownerScope': attempt.ownerScope,
    'purchaseOrderAccountId': attempt.purchaseOrderAccountId,
    'lateSettlementNeedsReview': attempt.lateSettlementNeedsReview,
    'payment': _encodeFrozenPayment(attempt.payment),
  };

  BuyV2LegacyCheckoutAttempt? _decodeLegacyAttempt(Object? value) {
    final source = _objectMap(value);
    final owner = _string(source['ownerScope']);
    final group = _objectMap(source['payment']);
    final request = _objectMap(group['request']);
    final key = _string(request['idempotencyKey']);
    final method = _string(request['paymentMethod']);
    final address = _decodeAddress(_objectMap(request['address']));
    final lines = _decodeOrderLines(request['lines']);
    final total = request['total'];
    final due = request['amountDueNow'];
    final scopes = _stringList(group['fulfilmentKeys']);
    final state = _enumByName(
      BuyV2CheckoutSubmissionState.values,
      _string(group['state']),
    );
    final context = _decodeProcurementContext(request['procurementContext']);
    if (source['version'] != 1 ||
        owner == null ||
        owner != ownerScope ||
        request['checkoutAttemptId'] != null ||
        request['paymentGroupId'] != null ||
        key == null ||
        method == null ||
        address == null ||
        lines.isEmpty ||
        request['lines'] is! List ||
        lines.length != (request['lines'] as List).length ||
        lines.map((line) => line.product.id).toSet().length != lines.length ||
        total is! int ||
        due is! int ||
        due < 0 ||
        total < due ||
        total > 90071992547409 ||
        scopes.isEmpty ||
        scopes.toSet().length != scopes.length ||
        state == null ||
        request['useUpiQr'] is! bool ||
        (request.containsKey('procurementContext') && context == null)) {
      return null;
    }
    final payment = BuyV2CheckoutGroupAttempt(
      request: BuyV2OrderPlacementRequest(
        lines: List.unmodifiable(lines),
        address: address,
        paymentMethod: method,
        total: total,
        amountDueNow: due,
        idempotencyKey: key,
        useUpiQr: request['useUpiQr'] as bool,
        commercialPaymentTermIds: Map.unmodifiable(
          _stringMap(request['commercialPaymentTermIds']),
        ),
        deliveryInstructionsByProductId: Map.unmodifiable(
          _stringMap(request['deliveryInstructionsByProductId']),
        ),
        checkoutQuoteId: _string(request['checkoutQuoteId']),
        purchaseOrderRequestId: _string(request['purchaseOrderRequestId']),
        purchaseOrderRevision: _string(request['purchaseOrderRevision']),
        procurementContext: context,
      ),
      fulfilmentKeys: Set.unmodifiable(scopes),
      obligations: _decodeObligations(group['obligations']),
      state: state == BuyV2CheckoutSubmissionState.submitting
          ? BuyV2CheckoutSubmissionState.paymentUnknown
          : state,
      paymentReference: _string(group['paymentReference']),
      paymentActionUri: _uri(group['paymentActionUri']),
      bankTransferInstructions: _decodeTransfer(
        group['bankTransferInstructions'],
      ),
      confirmedOrderIds: List.unmodifiable(
        _stringList(group['confirmedOrderIds']),
      ),
      financiallyClosed: group['financiallyClosed'] == true,
    );
    if (!payment.hasValidObligations ||
        (payment.financiallyClosed &&
            (group['confirmedOrderIds'] is! List ||
                (group['confirmedOrderIds'] as List).isNotEmpty ||
                !const {
                  BuyV2CheckoutSubmissionState.failed,
                  BuyV2CheckoutSubmissionState.cancelled,
                }.contains(state)))) {
      return null;
    }
    return BuyV2LegacyCheckoutAttempt(
      ownerScope: owner,
      payment: payment,
      purchaseOrderAccountId: _string(source['purchaseOrderAccountId']),
      lateSettlementNeedsReview: source['lateSettlementNeedsReview'] == true,
    );
  }

  bool _paymentRecoveryIncomplete(Map<String, Object?> source) {
    if (source['paymentRecoveryIncomplete'] == true ||
        (source.containsKey('procurementDraft') &&
            _decodeProcurementDraft(source['procurementDraft']) == null) ||
        (source.containsKey('legacyCheckoutAttempt') &&
            _decodeLegacyAttempt(source['legacyCheckoutAttempt']) == null) ||
        (source.containsKey('checkoutPaymentAttempt') &&
            _decodePaymentAttempt(source['checkoutPaymentAttempt']) == null)) {
      return true;
    }
    for (final pair in [
      ('retainedLegacyCheckoutAttempts', _decodeLegacyAttempt),
      ('retainedCheckoutPaymentAttempts', _decodePaymentAttempt),
    ]) {
      final raw = source[pair.$1];
      if (raw != null &&
          (raw is! List || raw.any((item) => pair.$2(item) == null))) {
        return true;
      }
    }
    return false;
  }

  static Map<String, Object?> _encodeProcurementContext(
    BuyV2ProcurementContext context,
  ) => {
    'accountId': context.accountId,
    'storeId': context.storeId,
    'purpose': context.purpose.name,
    'originOperationId': context.originOperationId,
  };

  static BuyV2ProcurementContext? _decodeProcurementContext(Object? value) {
    final source = _objectMap(value);
    final account = _string(source['accountId']);
    final store = _string(source['storeId']);
    final purpose = _enumByName(
      BuyV2ProcurementPurpose.values,
      _string(source['purpose']),
    );
    final origin = _string(source['originOperationId']);
    if (account == null || store == null || purpose == null || origin == null) {
      return null;
    }
    final context = BuyV2ProcurementContext(
      accountId: account,
      storeId: store,
      purpose: purpose,
      originOperationId: origin,
    );
    return context.hasIdentity ? context : null;
  }

  BuyV2CheckoutPaymentAttempt? _decodePaymentAttempt(Object? value) {
    final source = _objectMap(value);
    final id = _string(source['id']);
    final owner = _string(source['ownerScope']);
    final expiry = DateTime.tryParse(_string(source['quoteValidUntil']) ?? '');
    final rawGroups = source['groups'];
    if (source['version'] != 1 ||
        id == null ||
        owner == null ||
        expiry == null ||
        rawGroups is! List ||
        rawGroups.isEmpty ||
        rawGroups.length > 100) {
      return null;
    }
    final groups = <BuyV2CheckoutGroupAttempt>[];
    final ids = <String>{};
    final keys = <String>{};
    final attemptKeys = <String>{};
    final productIds = <String>{};
    for (final raw in rawGroups) {
      final group = _objectMap(raw);
      final request = _objectMap(group['request']);
      final groupId = _string(request['paymentGroupId']);
      final key = _string(request['idempotencyKey']);
      final method = _string(request['paymentMethod']);
      final quoteId = _string(request['checkoutQuoteId']);
      final address = _decodeAddress(_objectMap(request['address']));
      final lines = _decodeOrderLines(request['lines']);
      final total = request['total'];
      final due = request['amountDueNow'];
      final scope = _stringList(group['fulfilmentKeys']);
      final actionUri = _string(group['paymentActionUri']);
      final state = _enumByName(
        BuyV2CheckoutSubmissionState.values,
        _string(group['state']),
      );
      if (request['checkoutAttemptId'] != id ||
          (request.containsKey('procurementContext') &&
              _decodeProcurementContext(request['procurementContext']) ==
                  null) ||
          groupId == null ||
          !ids.add(groupId) ||
          key == null ||
          !attemptKeys.add(key) ||
          method == null ||
          quoteId == null ||
          address == null ||
          lines.isEmpty ||
          request['lines'] is! List ||
          lines.length != (request['lines'] as List).length ||
          lines.any((line) => !productIds.add(line.product.id)) ||
          total is! int ||
          due is! int ||
          due < 0 ||
          total < due ||
          total > 90071992547409 ||
          scope.isEmpty ||
          scope.any((value) => !keys.add(value)) ||
          state == null ||
          (group.containsKey('financiallyClosed') &&
              group['financiallyClosed'] is! bool) ||
          (group['financiallyClosed'] == true &&
              (!const {
                    BuyV2CheckoutSubmissionState.failed,
                    BuyV2CheckoutSubmissionState.cancelled,
                  }.contains(state) ||
                  group['confirmedOrderIds'] is! List ||
                  (group['confirmedOrderIds'] as List).isNotEmpty)) ||
          request['useUpiQr'] is! bool) {
        return null;
      }
      groups.add(
        BuyV2CheckoutGroupAttempt(
          request: BuyV2OrderPlacementRequest(
            lines: List.unmodifiable(lines),
            address: address,
            paymentMethod: method,
            total: total,
            amountDueNow: due,
            idempotencyKey: key,
            checkoutAttemptId: id,
            paymentGroupId: groupId,
            checkoutQuoteId: quoteId,
            useUpiQr: request['useUpiQr'] as bool,
            commercialPaymentTermIds: Map.unmodifiable(
              _stringMap(request['commercialPaymentTermIds']),
            ),
            deliveryInstructionsByProductId: Map.unmodifiable(
              _stringMap(request['deliveryInstructionsByProductId']),
            ),
            purchaseOrderRequestId: _string(request['purchaseOrderRequestId']),
            purchaseOrderRevision: _string(request['purchaseOrderRevision']),
            procurementContext: _decodeProcurementContext(
              request['procurementContext'],
            ),
          ),
          fulfilmentKeys: Set.unmodifiable(scope),
          obligations: _decodeObligations(group['obligations']),
          state: state == BuyV2CheckoutSubmissionState.submitting
              ? BuyV2CheckoutSubmissionState.paymentUnknown
              : state,
          paymentReference: _string(group['paymentReference']),
          paymentActionUri: actionUri != null ? Uri.tryParse(actionUri) : null,
          bankTransferInstructions: _decodeTransfer(
            group['bankTransferInstructions'],
          ),
          confirmedOrderIds: List.unmodifiable(
            _stringList(group['confirmedOrderIds']),
          ),
          financiallyClosed: group['financiallyClosed'] == true,
        ),
      );
    }
    return BuyV2CheckoutPaymentAttempt(
      id: id,
      ownerScope: owner,
      quoteValidUntil: expiry,
      groups: List.unmodifiable(groups),
      lateSettlementNeedsReview: source['lateSettlementNeedsReview'] == true,
    );
  }

  static List<BuyV2CheckoutFulfilmentObligation> _decodeObligations(
    Object? raw,
  ) {
    if (raw is! List || raw.length > 100) return const [];
    final values = _objectList(raw);
    if (values.length != raw.length ||
        values.any(
          (value) =>
              _string(value['fulfilmentKey']) == null ||
              value['totalMinor'] is! int ||
              value['dueNowMinor'] is! int ||
              value['productIds'] is! List ||
              _stringList(value['productIds']).length !=
                  (value['productIds'] as List).length ||
              _stringList(value['productIds']).toSet().length !=
                  (value['productIds'] as List).length,
        )) {
      return const [];
    }
    return List.unmodifiable([
      for (final value in values)
        BuyV2CheckoutFulfilmentObligation(
          fulfilmentKey: _string(value['fulfilmentKey'])!,
          productIds: Set.unmodifiable(_stringList(value['productIds'])),
          totalMinor: value['totalMinor'] as int,
          dueNowMinor: value['dueNowMinor'] as int,
        ),
    ]);
  }

  static Map<String, Object?> _encodeTransfer(
    BuyV2BankTransferInstructions bank,
  ) => {
    'beneficiaryName': bank.beneficiaryName,
    'bankName': bank.bankName,
    'accountNumber': bank.accountNumber,
    'ifsc': bank.ifsc,
    'transferReference': bank.transferReference,
  };

  static BuyV2BankTransferInstructions? _decodeTransfer(Object? value) {
    final source = _objectMap(value);
    final fields = [
      'beneficiaryName',
      'bankName',
      'accountNumber',
      'ifsc',
      'transferReference',
    ];
    if (fields.any((key) => _string(source[key]) == null)) {
      return null;
    }
    return BuyV2BankTransferInstructions(
      beneficiaryName: source['beneficiaryName'] as String,
      bankName: source['bankName'] as String,
      accountNumber: source['accountNumber'] as String,
      ifsc: source['ifsc'] as String,
      transferReference: source['transferReference'] as String,
    );
  }

  Map<String, Object?> _encodeProcurementDraft(
    BuyV2ProcurementDraftSnapshot draft,
  ) => {
    'version': 1,
    'ownerScope': draft.ownerScope,
    if (draft.navigation case final navigation?)
      'navigation': _encodeProcurementNavigation(navigation),
    'cartProducts': {
      for (final entry in draft.cartProducts.entries)
        entry.key: {
          'id': entry.value.id,
          'canonicalId': entry.value.canonicalId,
          'storeId': entry.value.storeId,
          'categoryId': entry.value.categoryId,
          'brand': entry.value.brand,
          'title': entry.value.title,
          'variant': entry.value.variant,
          'variantAttributes': _encodeVariantAttributes(entry.value),
          'pack': entry.value.pack,
          'price': entry.value.price,
          'unitPrice': entry.value.unitPrice,
          'seller': entry.value.seller,
          'sellerType': entry.value.sellerType,
          'visualKind': entry.value.visualKind,
          'visualLabel': entry.value.visualLabel,
          'minimumOrder': entry.value.minimumOrder,
          'workspaceId': entry.value.procurementSupplierGrant?.workspaceId,
          'offerId': entry.value.procurementSupplierGrant?.offerId,
          'offerRevision': entry.value.procurementSupplierGrant?.offerRevision,
        },
    },
  };

  BuyV2ProcurementDraftSnapshot? _decodeProcurementDraft(Object? value) {
    if (value is! Map) return null;
    final source = _objectMap(value);
    final scope = _string(source['ownerScope']);
    if (source['version'] != 1 || scope == null || scope != ownerScope) {
      return null;
    }
    final products = <String, BuyV2Product>{};
    for (final entry in _objectMap(source['cartProducts']).entries) {
      final item = _objectMap(entry.value);
      final id = _string(item['id']);
      final price = item['price'];
      final minimum = item['minimumOrder'];
      if (id != entry.key ||
          id == null ||
          price is! int ||
          price < 0 ||
          minimum is! int ||
          minimum < 1) {
        continue;
      }
      final identity = BuyV2ProcurementSupplierGrant(
        workspaceId: _string(item['workspaceId']) ?? '',
        storeId: _string(item['storeId']) ?? '',
        role: BuyV2SupplierWorkspaceRole.unknown,
        approved: false,
        listingId: id,
        productCanonicalId: _string(item['canonicalId']) ?? '',
        offerId: _string(item['offerId']) ?? '',
        offerRevision: _string(item['offerRevision']) ?? '',
        channel: BuyV2SupplierListingChannel.unknown,
        published: false,
        validUntil: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
      products[id] = BuyV2Product(
        id: id,
        canonicalId: _string(item['canonicalId']),
        variantAttributes: _decodeVariantAttributes(item['variantAttributes']),
        storeId: _string(item['storeId']),
        destination: BuyV2Destination.wholesale,
        categoryId: _string(item['categoryId']) ?? 'all',
        brand: _string(item['brand']) ?? '',
        title: _string(item['title']) ?? 'Unavailable item',
        variant: _string(item['variant']) ?? '',
        pack: _string(item['pack']) ?? 'Pack details unavailable',
        price: price,
        unitPrice: _string(item['unitPrice']) ?? '',
        badge: '',
        seller: _string(item['seller']) ?? 'Supplier unavailable',
        sellerType: _string(item['sellerType']) ?? '',
        deliveryPromise: 'Availability not confirmed',
        origin: '',
        confirmedOn: '',
        visualLabel: _string(item['visualLabel']) ?? '',
        visualKind: _string(item['visualKind']) ?? '',
        minimumOrder: minimum,
        procurementSupplierGrant: identity,
        catalogueListing: false,
      );
    }
    return BuyV2ProcurementDraftSnapshot(
      ownerScope: scope,
      cartProducts: Map.unmodifiable(products),
      navigation: _decodeProcurementNavigation(source['navigation']),
    );
  }

  Map<String, Object?> _encodeProcurementNavigation(
    BuyV2ProcurementNavigationSnapshot value,
  ) => {
    'version': 1,
    'destination': value.destination.name,
    'view': value.view.name,
    'categoryId': value.categoryId,
    'query': value.query,
    'filter': value.filter,
    'productId': value.productId,
    'orderId': value.orderId,
    'cartScope': value.cartScope.name,
    'checkoutScope': value.checkoutScope.name,
    'productReturnDestination': value.productReturnDestination.name,
    'productReturnView': value.productReturnView.name,
    'comparisonOrigins': value.comparisonOrigins,
    'cartReturnProductId': value.cartReturnProductId,
    'cartReturnDestination': value.cartReturnDestination.name,
    'cartReturnOriginDestination': value.cartReturnOriginDestination?.name,
    'cartReturnOriginView': value.cartReturnOriginView?.name,
    'cartReturnComparisonOrigins': value.cartReturnComparisonOrigins,
    'showingSavedProducts': value.showingSavedProducts,
    'cartScrollOffset': value.cartScrollOffset,
  };

  BuyV2ProcurementNavigationSnapshot? _decodeProcurementNavigation(
    Object? value,
  ) {
    if (value is! Map) {
      return null;
    }
    final source = _objectMap(value);
    if (source['version'] != 1 ||
        source['categoryId'] is! String ||
        source['query'] is! String) {
      return null;
    }
    final destination = _enumByName(
      BuyV2Destination.values,
      _string(source['destination']),
    );
    if (destination == null) {
      return null;
    }
    final view = _enumByName(BuyV2View.values, _string(source['view']));
    if (view == null) {
      return null;
    }
    final cartScope = _enumByName(
      BuyV2CartScope.values,
      _string(source['cartScope']),
    );
    if (cartScope == null) {
      return null;
    }
    final checkoutScope = _enumByName(
      BuyV2CartScope.values,
      _string(source['checkoutScope']),
    );
    if (checkoutScope == null) {
      return null;
    }
    final productReturnDestination = _enumByName(
      BuyV2Destination.values,
      _string(source['productReturnDestination']),
    );
    if (productReturnDestination == null) {
      return null;
    }
    final productReturnView = _enumByName(
      BuyV2View.values,
      _string(source['productReturnView']),
    );
    if (productReturnView == null) {
      return null;
    }
    final cartReturnDestination = _enumByName(
      BuyV2Destination.values,
      _string(source['cartReturnDestination']),
    );
    if (cartReturnDestination == null) {
      return null;
    }
    final cartReturnOriginDestination = _enumByName(
      BuyV2Destination.values,
      _string(source['cartReturnOriginDestination']),
    );
    if (source['cartReturnOriginDestination'] != null &&
        cartReturnOriginDestination == null) {
      return null;
    }
    final cartReturnOriginView = _enumByName(
      BuyV2View.values,
      _string(source['cartReturnOriginView']),
    );
    if (source['cartReturnOriginView'] != null &&
        cartReturnOriginView == null) {
      return null;
    }
    final offset = source['cartScrollOffset'];
    return BuyV2ProcurementNavigationSnapshot(
      destination: destination,
      view: view,
      categoryId: source['categoryId'] as String,
      query: source['query'] as String,
      filter: _string(source['filter']),
      productId: _string(source['productId']),
      orderId: _string(source['orderId']),
      cartScope: cartScope,
      checkoutScope: checkoutScope,
      productReturnDestination: productReturnDestination,
      productReturnView: productReturnView,
      comparisonOrigins: _stringList(source['comparisonOrigins']),
      cartReturnProductId: _string(source['cartReturnProductId']),
      cartReturnDestination: cartReturnDestination,
      cartReturnOriginDestination: cartReturnOriginDestination,
      cartReturnOriginView: cartReturnOriginView,
      cartReturnComparisonOrigins: _stringList(
        source['cartReturnComparisonOrigins'],
      ),
      showingSavedProducts: source['showingSavedProducts'] == true,
      cartScrollOffset: offset is num && offset.isFinite && offset >= 0
          ? offset.toDouble()
          : 0,
    );
  }

  Map<String, Object?> _encodeAddress(BuyV2Address address) => {
    'id': address.id,
    'kind': address.kind.name,
    'label': address.label,
    'recipient': address.recipient,
    'phone': address.phone,
    'line': address.line,
    'area': address.area,
    'pinCode': address.pinCode,
    'landmark': address.landmark,
  };

  BuyV2Address? _decodeAddress(Map<String, Object?> source) {
    final id = _string(source['id']);
    final kind = _enumByName(BuyV2AddressKind.values, _string(source['kind']));
    final label = _string(source['label']);
    final recipient = _string(source['recipient']);
    final phone = _string(source['phone']);
    final line = _string(source['line']);
    final area = _string(source['area']);
    final pinCode = _string(source['pinCode']);
    final landmarkValue = source['landmark'];
    final landmark = landmarkValue == null
        ? ''
        : landmarkValue is String
        ? landmarkValue
        : null;
    if ([
          id,
          label,
          recipient,
          phone,
          line,
          area,
          pinCode,
          landmark,
        ].any((value) => value == null) ||
        kind == null) {
      return null;
    }
    return BuyV2Address(
      id: id!,
      kind: kind,
      label: label!,
      recipient: recipient!,
      phone: phone!,
      line: line!,
      area: area!,
      pinCode: pinCode!,
      landmark: landmark!,
    );
  }

  Map<String, Object?> _encodeOrder(BuyV2Order order) => {
    'id': order.id,
    'destination': order.destination.name,
    'title': order.title,
    'itemSummary': order.itemSummary,
    'total': order.total,
    'partner': order.partner,
    'partnerType': order.partnerType,
    'promise': order.promise,
    'destinationLabel': order.destinationLabel,
    'progress': order.progress,
    'status': order.status.name,
    'purchaseId': order.purchaseId,
    'promisedByLabel': order.promisedByLabel,
    'updatedDeliveryEstimate': order.updatedDeliveryEstimate,
    'productIds': order.productIds,
    'lines': [
      for (final line in order.lines)
        {
          'productId': line.product.id,
          'quantity': line.quantity,
          'purchasedProduct': _encodePurchasedProduct(line.product),
        },
    ],
    'paymentMethod': order.paymentMethod,
    'purchaseOrderReference': order.purchaseOrderReference,
    'recipient': order.recipient,
    'addressLine': order.addressLine,
    'deliveryInstruction': order.deliveryInstruction,
    'tip': order.tip,
    'discount': order.discount,
    'paymentTermLabel': order.paymentTermLabel,
    'amountPaidNow': order.amountPaidNow,
    'balanceDue': order.balanceDue,
    'balanceDueLabel': order.balanceDueLabel,
    'paymentStatusLabel': order.paymentStatusLabel,
    'buyerName': order.buyerName,
    'buyerType': order.buyerType,
    'tax': order.tax,
    'freight': order.freight,
    'deliveryFee': order.deliveryFee,
    'paymentCharge': order.paymentCharge,
    'dispatchPromise': order.dispatchPromise,
    'deliveryPartnerName': order.deliveryPartnerName,
    'deliveryPartnerType': order.deliveryPartnerType,
    'trackingReference': order.trackingReference,
    'deliveryServiceLevel': order.deliveryServiceLevel,
    'proofOfDeliveryStatus': order.proofOfDeliveryStatus,
    'invoiceAvailable': order.invoiceAvailable,
    'receiptReference': order.receiptReference,
  };

  BuyV2Order? _decodeOrder(Map<String, Object?> source) {
    final destination = _destination(_string(source['destination']));
    final status = _enumByName(
      BuyV2OrderStatus.values,
      _string(source['status']),
    );
    final requiredStrings = [
      _string(source['id']),
      _string(source['title']),
      _string(source['itemSummary']),
      _string(source['partner']),
      _string(source['partnerType']),
      _string(source['promise']),
      _string(source['destinationLabel']),
    ];
    final total = _integer(source['total']);
    final progress = source['progress'];
    final lines = _decodeOrderLines(source['lines']);
    if (destination == null ||
        status == null ||
        requiredStrings.any((value) => value == null) ||
        total == null ||
        progress is! num) {
      return null;
    }
    return BuyV2Order(
      id: requiredStrings[0]!,
      destination: destination,
      title: requiredStrings[1]!,
      itemSummary: requiredStrings[2]!,
      total: total,
      partner: requiredStrings[3]!,
      partnerType: requiredStrings[4]!,
      promise: requiredStrings[5]!,
      destinationLabel: requiredStrings[6]!,
      progress: progress.toDouble(),
      status: status,
      purchaseId: _string(source['purchaseId']),
      promisedByLabel: _string(source['promisedByLabel']),
      updatedDeliveryEstimate: _string(source['updatedDeliveryEstimate']),
      productIds: {
        ..._stringList(source['productIds']),
        ...lines.map((line) => line.product.id),
      }.toList(growable: false),
      lines: lines,
      paymentMethod: _string(source['paymentMethod']),
      purchaseOrderReference: _string(source['purchaseOrderReference']),
      recipient: _string(source['recipient']),
      addressLine: _string(source['addressLine']),
      deliveryInstruction: _string(source['deliveryInstruction']),
      tip: _integer(source['tip']) ?? 0,
      discount: _integer(source['discount']) ?? 0,
      paymentTermLabel: _string(source['paymentTermLabel']),
      amountPaidNow: _integer(source['amountPaidNow']),
      balanceDue: _integer(source['balanceDue']) ?? 0,
      balanceDueLabel: _string(source['balanceDueLabel']),
      paymentStatusLabel: _string(source['paymentStatusLabel']),
      buyerName: _string(source['buyerName']),
      buyerType: _string(source['buyerType']),
      tax: _integer(source['tax']) ?? 0,
      freight: _integer(source['freight']) ?? 0,
      deliveryFee: _integer(source['deliveryFee']) ?? 0,
      paymentCharge: _integer(source['paymentCharge']) ?? 0,
      dispatchPromise: _string(source['dispatchPromise']),
      deliveryPartnerName: _string(source['deliveryPartnerName']),
      deliveryPartnerType: _string(source['deliveryPartnerType']),
      trackingReference: _string(source['trackingReference']),
      deliveryServiceLevel: _string(source['deliveryServiceLevel']),
      proofOfDeliveryStatus: _string(source['proofOfDeliveryStatus']),
      invoiceAvailable: source['invoiceAvailable'] != false,
      receiptReference: _string(source['receiptReference']),
    );
  }

  static String? _string(Object? value) =>
      value is String && value.trim().isNotEmpty ? value : null;

  static int? _integer(Object? value) => value is num ? value.toInt() : null;

  static Uri? _uri(Object? value) {
    final source = _string(value);
    return source == null ? null : Uri.tryParse(source);
  }

  static List<String> _stringList(Object? value) => value is List
      ? value.whereType<String>().toList(growable: false)
      : const [];

  static Map<String, Object?> _objectMap(Object? value) =>
      value is Map ? Map<String, Object?>.from(value) : const {};

  static List<Map<String, Object?>> _objectList(Object? value) => value is List
      ? value
            .whereType<Map>()
            .map((item) => Map<String, Object?>.from(item))
            .toList(growable: false)
      : const [];

  static Map<String, String> _stringMap(Object? value) => _objectMap(
    value,
  ).map((key, value) => MapEntry(key, value is String ? value : ''));

  static Map<String, int> _stringIntMap(Object? value) => _objectMap(value).map(
    (key, value) => MapEntry(key, value is num ? value.toInt() : 0),
  )..removeWhere((_, value) => value <= 0);

  static Map<BuyV2Destination, String> _destinationStringMap(Object? value) {
    final result = <BuyV2Destination, String>{};
    for (final entry in _stringMap(value).entries) {
      final destination = _destination(entry.key);
      if (destination != null && entry.value.isNotEmpty) {
        result[destination] = entry.value;
      }
    }
    return result;
  }

  static Map<BuyV2Destination, List<String>> _destinationStringListMap(
    Object? value,
  ) {
    final result = <BuyV2Destination, List<String>>{};
    for (final entry in _objectMap(value).entries) {
      final destination = _destination(entry.key);
      final items = _stringList(entry.value);
      if (destination != null && items.isNotEmpty) {
        result[destination] = items;
      }
    }
    return result;
  }

  static List<BuyV2CartLine> _decodeOrderLines(Object? value) {
    return [
      for (final source in _objectList(value))
        if (_string(source['productId']) case final productId?)
          if (_decodePurchasedProduct(source['purchasedProduct'])
              case final product? when product.id == productId)
            if (source['quantity'] case final int quantity when quantity > 0)
              BuyV2CartLine(product: product, quantity: quantity),
    ];
  }

  // Historical display data only. Never recover purchase facts from today's
  // catalogue or restore listing/fulfilment authority from this local cache.
  static Map<String, Object?> _encodePurchasedProduct(BuyV2Product product) => {
    'version': 1,
    'id': product.id,
    'canonicalId': product.canonicalId,
    'storeId': product.storeId,
    'destination': product.destination.name,
    'categoryId': product.categoryId,
    'brand': product.brand,
    'title': product.title,
    'variant': product.variant,
    'variantAttributes': _encodeVariantAttributes(product),
    'pack': product.pack,
    'price': product.price,
    'unitPrice': product.unitPrice,
    'seller': product.seller,
    'sellerType': product.sellerType,
    'origin': product.origin,
    'minimumOrder': product.minimumOrder,
    'requiresPrescription': product.requiresPrescription,
    'composition': product.composition,
    'regulatoryNote': product.regulatoryNote,
  };

  static BuyV2Product? _decodePurchasedProduct(Object? value) {
    final source = _objectMap(value);
    final id = _string(source['id']);
    final canonicalId = _string(source['canonicalId']);
    final destination = _destination(_string(source['destination']));
    final title = _string(source['title']);
    final price = source['price'];
    final minimumOrder = source['minimumOrder'];
    const textFields = [
      'categoryId',
      'brand',
      'variant',
      'pack',
      'unitPrice',
      'seller',
      'sellerType',
      'origin',
    ];
    if (source['version'] != 1 ||
        id == null ||
        canonicalId == null ||
        destination == null ||
        title == null ||
        price is! int ||
        price < 0 ||
        minimumOrder is! int ||
        minimumOrder < 1 ||
        source['requiresPrescription'] is! bool ||
        textFields.any((key) => source[key] is! String)) {
      return null;
    }
    return BuyV2Product(
      id: id,
      canonicalId: canonicalId,
      variantAttributes: _decodeVariantAttributes(source['variantAttributes']),
      storeId: _string(source['storeId']),
      destination: destination,
      categoryId: source['categoryId'] as String,
      brand: source['brand'] as String,
      title: title,
      variant: source['variant'] as String,
      pack: source['pack'] as String,
      price: price,
      unitPrice: source['unitPrice'] as String,
      seller: source['seller'] as String,
      sellerType: source['sellerType'] as String,
      origin: source['origin'] as String,
      minimumOrder: minimumOrder,
      requiresPrescription: source['requiresPrescription'] as bool,
      composition: _string(source['composition']),
      regulatoryNote: _string(source['regulatoryNote']),
      badge: '',
      deliveryPromise: '',
      confirmedOn: '',
      visualLabel: '',
      visualKind: 'unavailable',
      catalogueListing: false,
    );
  }

  static List<Map<String, Object?>> _encodeVariantAttributes(
    BuyV2Product product,
  ) => [
    for (final value in product.variantAttributes)
      {
        'dimensionId': value.dimensionId,
        'dimensionLabel': value.dimensionLabel,
        'optionId': value.optionId,
        'optionLabel': value.optionLabel,
        'kind': value.kind.name,
        'swatchArgb': value.swatchArgb,
      },
  ];

  static List<BuyV2VariantAttribute> _decodeVariantAttributes(Object? value) {
    if (value == null) return const []; // Legacy snapshot.
    if (value is! List) return const [];
    final result = <BuyV2VariantAttribute>[];
    final dimensions = <String>{};
    for (final raw in value) {
      if (raw is! Map) return const [];
      final source = _objectMap(raw);
      final kind = _enumByName(
        BuyV2VariantDimensionKind.values,
        _string(source['kind']),
      );
      final swatch = source['swatchArgb'];
      if (kind == null || (swatch != null && swatch is! int)) return const [];
      final attribute = BuyV2VariantAttribute(
        dimensionId: _string(source['dimensionId']) ?? '',
        dimensionLabel: _string(source['dimensionLabel']) ?? '',
        optionId: _string(source['optionId']) ?? '',
        optionLabel: _string(source['optionLabel']) ?? '',
        kind: kind,
        swatchArgb: swatch as int?,
      );
      if (!attribute.isValid || !dimensions.add(attribute.dimensionId)) {
        return const [];
      }
      result.add(attribute);
    }
    return List.unmodifiable(result);
  }

  static BuyV2Destination? _destination(String? name) =>
      _enumByName(BuyV2Destination.values, name);

  static T? _enumByName<T extends Enum>(Iterable<T> values, String? name) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}

@immutable
class BuyV2GstInvoiceProfileRecord {
  const BuyV2GstInvoiceProfileRecord({
    required this.id,
    required this.legalName,
    required this.gstin,
    required this.billingAddress,
  });

  final String id;
  final String legalName;
  final String gstin;
  final String billingAddress;
}

@immutable
class BuyV2GstInvoiceProfileSnapshot {
  const BuyV2GstInvoiceProfileSnapshot({this.profiles = const []});

  final List<BuyV2GstInvoiceProfileRecord> profiles;
}

abstract interface class BuyV2GstInvoiceProfileStore {
  const BuyV2GstInvoiceProfileStore();

  /// Stable authenticated-account scope. A null scope disables persistence.
  String? get ownerScope;

  Future<BuyV2GstInvoiceProfileSnapshot?> read();

  Future<bool> write(BuyV2GstInvoiceProfileSnapshot snapshot);
}
