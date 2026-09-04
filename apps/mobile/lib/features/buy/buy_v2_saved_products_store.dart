import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'buy_v2_content_contracts.dart';
import 'buy_v2_models.dart';

abstract interface class BuyV2SavedProductsStore {
  const BuyV2SavedProductsStore();

  String? get ownerScope;

  Future<Set<String>?> read();

  Future<bool> write(Set<String> savedProductKeys);
}

@immutable
class BuyV2CustomerStateSnapshot {
  const BuyV2CustomerStateSnapshot({
    this.cartQuantities = const {},
    this.addresses = const [],
    this.selectedAddressId,
    this.savedProductKeys = const {},
    this.deliveryInstructionIds = const {},
    this.selectedPayment,
    this.purchaseOrderReference,
    this.checkoutIdempotencyKey,
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
  final List<BuyV2Address> addresses;
  final String? selectedAddressId;
  final Set<String> savedProductKeys;
  final Map<BuyV2Destination, String> deliveryInstructionIds;
  final String? selectedPayment;
  final String? purchaseOrderReference;
  final String? checkoutIdempotencyKey;
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
      return _decodeSnapshot(decoded);
    } on Object {
      return null;
    }
  }

  @override
  Future<bool> write(BuyV2CustomerStateSnapshot snapshot) async {
    try {
      await _preferences.setString(_key, jsonEncode(_encodeSnapshot(snapshot)));
      return true;
    } on Object {
      return false;
    }
  }

  Map<String, Object?> _encodeSnapshot(BuyV2CustomerStateSnapshot snapshot) => {
    'cartQuantities': snapshot.cartQuantities,
    'addresses': [
      for (final address in snapshot.addresses) _encodeAddress(address),
    ],
    'selectedAddressId': snapshot.selectedAddressId,
    'savedProductKeys': snapshot.savedProductKeys.toList(growable: false),
    'deliveryInstructionIds': {
      for (final entry in snapshot.deliveryInstructionIds.entries)
        entry.key.name: entry.value,
    },
    'selectedPayment': snapshot.selectedPayment,
    'purchaseOrderReference': snapshot.purchaseOrderReference,
    'checkoutIdempotencyKey': snapshot.checkoutIdempotencyKey,
    'paymentReference': snapshot.paymentReference,
    'paymentActionUri': snapshot.paymentActionUri?.toString(),
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

  BuyV2CustomerStateSnapshot _decodeSnapshot(Map<String, Object?> source) =>
      BuyV2CustomerStateSnapshot(
        cartQuantities: _stringIntMap(source['cartQuantities']),
        addresses: _objectList(
          source['addresses'],
        ).map(_decodeAddress).whereType<BuyV2Address>().toList(growable: false),
        selectedAddressId: _string(source['selectedAddressId']),
        savedProductKeys: _stringList(source['savedProductKeys']).toSet(),
        deliveryInstructionIds: _destinationStringMap(
          source['deliveryInstructionIds'],
        ),
        selectedPayment: _string(source['selectedPayment']),
        purchaseOrderReference: _string(source['purchaseOrderReference']),
        checkoutIdempotencyKey: _string(source['checkoutIdempotencyKey']),
        paymentReference: _string(source['paymentReference']),
        paymentActionUri: _uri(source['paymentActionUri']),
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
    final landmark = _string(source['landmark']);
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
        {'productId': line.product.id, 'quantity': line.quantity},
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
    final products = {
      for (final product in BuyV2Catalogue.allProducts) product.id: product,
    };
    return [
      for (final source in _objectList(value))
        if (_string(source['productId']) case final productId?)
          if (products[productId] case final product?)
            if (_integer(source['quantity']) case final quantity?
                when quantity > 0)
              BuyV2CartLine(product: product, quantity: quantity),
    ];
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
