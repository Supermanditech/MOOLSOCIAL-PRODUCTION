import 'package:flutter/foundation.dart';

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
    this.checkoutIdempotencyKey,
    this.paymentReference,
    this.paymentActionUri,
    this.bankTransferInstructions,
    this.checkoutSubmissionState,
  });

  final Map<String, int> cartQuantities;
  final List<BuyV2Address> addresses;
  final String? selectedAddressId;
  final Set<String> savedProductKeys;
  final Map<BuyV2Destination, String> deliveryInstructionIds;
  final String? selectedPayment;
  final String? checkoutIdempotencyKey;
  final String? paymentReference;
  final Uri? paymentActionUri;
  final BuyV2BankTransferInstructions? bankTransferInstructions;
  final String? checkoutSubmissionState;
}

abstract interface class BuyV2CustomerStateStore {
  const BuyV2CustomerStateStore();

  String? get ownerScope;

  Future<BuyV2CustomerStateSnapshot?> read();

  Future<bool> write(BuyV2CustomerStateSnapshot snapshot);
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
