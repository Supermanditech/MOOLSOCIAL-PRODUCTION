/// Shared by Store and consumer 022-R5-A; no Flutter, Work UI or transport import.
///
/// This is a wire definition, not an authorisation service. No endpoint is
/// enabled here. Credentials are provided by the future authenticated adapter,
/// never by request fields. See SCAN-AND-PICK-CONTRACT-V1.md before implementing.
library;

import 'dart:convert';

const scanPickProtocolVersion = 1;
const scanPickPurpose = 'customerCollection';
// Shared transport bound, not proof that a code is valid or safely rendered.
const scanPickMaxQrPayloadBytes = 1024;

enum ScanPickOperation { read, issueChallenge, authorise, handOver, reconcile }

enum ScanPickClient { consumer, retailer }

enum ScanPickOutcome { snapshot, rejected, unknown }

enum ScanPickState {
  preparing,
  ready,
  awaitingCustomer,
  matched,
  collected,
  cancelled,
}

enum ScanPickPayment { unpaid, partiallyPaid, paid, refunded }

enum ScanPickReadiness { preparing, ready }

enum ScanPickError {
  unauthenticated,
  forbidden,
  wrongPurchaser,
  wrongOrder,
  wrongStore,
  unsupportedPurpose,
  paymentRequired,
  paymentChanged,
  notReady,
  revisionConflict,
  challengeExpired,
  challengeInvalid,
  challengeConsumed,
  approvalMissing,
  approvalExpired,
  cancelled,
  alreadyCollected,
  operationInProgress,
  operationConflict,
  rateLimited,
  unavailable,
}

/// One request attempt has a new requestId. A mutation's operationId stays the
/// same across transport retries and is also the target of reconciliation.
/// Order-level completion uniqueness must additionally be enforced server-side.
final class ScanPickRequest {
  ScanPickRequest._({
    required this.operation,
    required this.requestId,
    required this.orderId,
    required this.storeId,
    this.operationId,
    this.expectedRevision,
    this.qrPayload,
    this.approvalId,
  }) {
    for (final value in [requestId, orderId, storeId]) {
      _nonEmpty(value, 'request identity');
    }
    if (operation != ScanPickOperation.read) {
      _nonEmpty(operationId, 'operationId');
    }
    if (operation != ScanPickOperation.read &&
        operation != ScanPickOperation.reconcile) {
      _nonEmpty(expectedRevision, 'expectedRevision');
    }
    if (operation == ScanPickOperation.authorise) {
      _qrPayload(qrPayload);
    }
    if (operation == ScanPickOperation.handOver) {
      _nonEmpty(approvalId, 'approvalId');
    }
  }

  factory ScanPickRequest.read({
    required String requestId,
    required String orderId,
    required String storeId,
  }) => ScanPickRequest._(
    operation: ScanPickOperation.read,
    requestId: requestId,
    orderId: orderId,
    storeId: storeId,
  );

  /// First issue and explicit refresh use the same operation. A refresh is a
  /// new intent/operationId; it atomically invalidates the previous challenge.
  factory ScanPickRequest.issueChallenge({
    required String requestId,
    required String operationId,
    required String orderId,
    required String storeId,
    required String expectedRevision,
  }) => ScanPickRequest._(
    operation: ScanPickOperation.issueChallenge,
    requestId: requestId,
    operationId: operationId,
    orderId: orderId,
    storeId: storeId,
    expectedRevision: expectedRevision,
  );

  factory ScanPickRequest.authorise({
    required String requestId,
    required String operationId,
    required String orderId,
    required String storeId,
    required String expectedRevision,
    required String qrPayload,
  }) => ScanPickRequest._(
    operation: ScanPickOperation.authorise,
    requestId: requestId,
    operationId: operationId,
    orderId: orderId,
    storeId: storeId,
    expectedRevision: expectedRevision,
    qrPayload: qrPayload,
  );

  factory ScanPickRequest.handOver({
    required String requestId,
    required String operationId,
    required String orderId,
    required String storeId,
    required String expectedRevision,
    required String approvalId,
  }) => ScanPickRequest._(
    operation: ScanPickOperation.handOver,
    requestId: requestId,
    operationId: operationId,
    orderId: orderId,
    storeId: storeId,
    expectedRevision: expectedRevision,
    approvalId: approvalId,
  );

  factory ScanPickRequest.reconcile({
    required String requestId,
    required String operationId,
    required String orderId,
    required String storeId,
  }) => ScanPickRequest._(
    operation: ScanPickOperation.reconcile,
    requestId: requestId,
    operationId: operationId,
    orderId: orderId,
    storeId: storeId,
  );

  final ScanPickOperation operation;
  final String requestId;
  final String? operationId;
  final String orderId;
  final String storeId;
  final String? expectedRevision;
  final String? qrPayload;
  final String? approvalId;

  /// Do not log this map: authorise includes a short-lived security token.
  Map<String, Object> toJson() => {
    'protocolVersion': scanPickProtocolVersion,
    'purpose': scanPickPurpose,
    'operation': operation.name,
    'requestId': requestId,
    'orderId': orderId,
    'storeId': storeId,
    'operationId': ?operationId,
    'expectedRevision': ?expectedRevision,
    'qrPayload': ?qrPayload,
    'approvalId': ?approvalId,
  };
}

/// Separate injectable capability. Existing WorkGateway/biker OTP and Buy
/// product scanner do not implement it implicitly. No default success fixture.
abstract interface class ScanPickGateway {
  Future<ScanPickResult> execute(ScanPickRequest request);
}

final class ScanPickLine {
  ScanPickLine._(Map<String, Object?> json)
    : lineId = _text(json, 'lineId'),
      productId = _text(json, 'productId'),
      skuId = _text(json, 'skuId'),
      name = _text(json, 'name'),
      pack = _text(json, 'pack'),
      quantity = _text(json, 'quantity'),
      amountMinor = _amount(json, 'amountMinor') {
    if (!RegExp(r'^(0|[1-9]\d*)(\.\d+)?$').hasMatch(quantity) ||
        !RegExp(r'[1-9]').hasMatch(quantity)) {
      throw const FormatException('Invalid collection quantity');
    }
  }

  final String lineId;
  final String productId;
  // Exact purchased variant/pack SKU; a generic productId is not a substitute.
  final String skuId;
  final String name;
  final String pack;

  /// Exact positive decimal quantity, not binary floating point.
  final String quantity;
  final int amountMinor;
}

final class ScanPickChallenge {
  ScanPickChallenge._(Map<String, Object?> json)
    : id = _text(json, 'id'),
      qrPayload = json['qrPayload'] == null
          ? null
          : _qrPayload(json['qrPayload']),
      expiresAt = _instant(json, 'expiresAt');
  final String id;

  /// Retailer only. Consumer read/status responses MUST omit this token.
  final String? qrPayload;
  final DateTime expiresAt;
}

final class ScanPickApproval {
  ScanPickApproval._(Map<String, Object?> json)
    : id = _text(json, 'id'),
      expiresAt = _instant(json, 'expiresAt');
  final String id;
  final DateTime expiresAt;
}

final class ScanPickReceipt {
  ScanPickReceipt._(Map<String, Object?> json)
    : id = _text(json, 'id'),
      collectedAt = _instant(json, 'collectedAt'),
      invoiceReference = json['invoiceReference'] == null
          ? null
          : _text(json, 'invoiceReference');
  final String id;
  final DateTime collectedAt;
  final String? invoiceReference;
}

/// Decode only from the authenticated adapter. A valid local object does not
/// prove payment, purchaser identity, physical handover or server permission.
final class ScanPickSnapshot {
  ScanPickSnapshot._(Map<String, Object?> json)
    : orderId = _text(json, 'orderId'),
      storeId = _text(json, 'storeId'),
      purchaserAccountId = _text(json, 'purchaserAccountId'),
      customerName = _text(json, 'customerName'),
      storeName = _text(json, 'storeName'),
      revision = _text(json, 'revision'),
      serverTime = _instant(json, 'serverTime'),
      state = _enum(json, 'state', ScanPickState.values),
      payment = _enum(json, 'payment', ScanPickPayment.values),
      readiness = _enum(json, 'readiness', ScanPickReadiness.values),
      currency = _text(json, 'currency'),
      totalMinor = _amount(json, 'totalMinor'),
      lines = _lines(json['lines']),
      challenge = json['challenge'] == null
          ? null
          : ScanPickChallenge._(_object(json['challenge'], 'challenge')),
      approval = json['approval'] == null
          ? null
          : ScanPickApproval._(_object(json['approval'], 'approval')),
      receipt = json['receipt'] == null
          ? null
          : ScanPickReceipt._(_object(json['receipt'], 'receipt')) {
    if (json['purpose'] != scanPickPurpose || currency != 'INR') {
      throw const FormatException('Unsupported collection purpose or currency');
    }
    if ((state == ScanPickState.awaitingCustomer && challenge == null) ||
        (state == ScanPickState.matched && approval == null) ||
        (state == ScanPickState.collected && receipt == null) ||
        (receipt != null && state != ScanPickState.collected) ||
        (approval != null && state != ScanPickState.matched) ||
        (challenge != null && state != ScanPickState.awaitingCustomer)) {
      throw const FormatException('Inconsistent collection state');
    }
    if ((state == ScanPickState.awaitingCustomer ||
            state == ScanPickState.matched) &&
        (payment != ScanPickPayment.paid ||
            readiness != ScanPickReadiness.ready)) {
      throw const FormatException('Collection requires paid and ready order');
    }
  }

  final String orderId;
  final String storeId;
  final String purchaserAccountId;
  final String customerName;
  final String storeName;

  /// Opaque equality token, never compare revisions numerically or lexically.
  final String revision;
  final DateTime serverTime;
  final ScanPickState state;
  final ScanPickPayment payment;
  final ScanPickReadiness readiness;
  final String currency;
  final int totalMinor;
  final List<ScanPickLine> lines;
  final ScanPickChallenge? challenge;
  final ScanPickApproval? approval;
  final ScanPickReceipt? receipt;

  /// Presentation eligibility only. Pass monotonic elapsed time applied to the
  /// last serverTime, not a user-adjustable wall clock. The server MUST repeat
  /// every permission/payment/readiness/revision/expiry check on handOver.
  bool _canRequestHandOver(DateTime estimatedServerNow) =>
      state == ScanPickState.matched &&
      payment == ScanPickPayment.paid &&
      readiness == ScanPickReadiness.ready &&
      !estimatedServerNow.isBefore(serverTime) &&
      approval != null &&
      estimatedServerNow.isBefore(approval!.expiresAt);
}

final class ScanPickResult {
  ScanPickResult._(Map<String, Object?> json)
    : requestId = _text(json, 'requestId'),
      operation = _enum(json, 'operation', ScanPickOperation.values),
      operationId = json['operationId'] == null
          ? null
          : _text(json, 'operationId'),
      outcome = _enum(json, 'outcome', ScanPickOutcome.values),
      snapshot = json['snapshot'] == null
          ? null
          : ScanPickSnapshot._(_object(json['snapshot'], 'snapshot')),
      error = json['error'] == null
          ? null
          : _enum(json, 'error', ScanPickError.values) {
    if (json['protocolVersion'] != scanPickProtocolVersion ||
        (operation != ScanPickOperation.read && operationId == null) ||
        (operation == ScanPickOperation.read && operationId != null) ||
        (outcome == ScanPickOutcome.snapshot &&
            (snapshot == null || error != null)) ||
        (outcome == ScanPickOutcome.rejected && error == null) ||
        (outcome == ScanPickOutcome.unknown &&
            (operation == ScanPickOperation.read ||
                snapshot != null ||
                error != null)) ||
        (error == ScanPickError.alreadyCollected &&
            snapshot?.state != ScanPickState.collected)) {
      throw const FormatException('Invalid collection result envelope');
    }
  }

  /// Unknown enums/version or incomplete data fail closed, never become Match.
  factory ScanPickResult.fromJson(Map<String, Object?> json) =>
      ScanPickResult._(json);

  final String requestId;
  final ScanPickOperation operation;
  final String? operationId;
  final ScanPickOutcome outcome;
  final ScanPickSnapshot? snapshot;
  final ScanPickError? error;

  /// Presentation eligibility only, after request correlation. A Matched
  /// recovery snapshot in a rejected result must never enable Hand Over.
  /// The caller must still discard replies after session/order switches, use
  /// fresh server time, and leave final authorisation to the server.
  bool canRequestHandOver(
    ScanPickRequest request,
    DateTime estimatedServerNow,
  ) {
    validateFor(request, client: ScanPickClient.retailer);
    return outcome == ScanPickOutcome.snapshot &&
        (snapshot?._canRequestHandOver(estimatedServerNow) ?? false);
  }

  /// Consumers must supply their authenticated account ID. Store adapters must
  /// separately reject replies after account/workspace/selected-order changes.
  /// Correlation is not server authentication and cannot authorise handover.
  void validateFor(
    ScanPickRequest request, {
    required ScanPickClient client,
    String? purchaserAccountId,
  }) {
    final value = snapshot;
    if (client == ScanPickClient.consumer) {
      _nonEmpty(purchaserAccountId, 'authenticated purchasing account');
      if (request.operation == ScanPickOperation.issueChallenge ||
          request.operation == ScanPickOperation.handOver ||
          value?.challenge?.qrPayload != null) {
        throw const FormatException('Invalid consumer collection capability');
      }
    } else if (request.operation == ScanPickOperation.authorise) {
      throw const FormatException(
        'Retailer cannot authorise customer collection',
      );
    }
    if (requestId != request.requestId ||
        operation != request.operation ||
        operationId != request.operationId ||
        (value != null &&
            (value.orderId != request.orderId ||
                value.storeId != request.storeId ||
                (purchaserAccountId != null &&
                    value.purchaserAccountId != purchaserAccountId)))) {
      throw const FormatException('Collection response context changed');
    }
  }
}

String _nonEmpty(Object? value, String key) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Missing collection field: $key');
  }
  return value;
}

String _text(Map<String, Object?> json, String key) =>
    _nonEmpty(json[key], key);

String _qrPayload(Object? value) {
  final payload = _nonEmpty(value, 'qrPayload');
  if (payload.length > scanPickMaxQrPayloadBytes ||
      utf8.encode(payload).length > scanPickMaxQrPayloadBytes) {
    throw const FormatException('Collection code is too long');
  }
  return payload;
}

T _enum<T extends Enum>(Map<String, Object?> json, String key, List<T> values) {
  final raw = _text(json, key);
  for (final value in values) {
    if (value.name == raw) return value;
  }
  throw FormatException('Unknown collection field: $key');
}

int _amount(Map<String, Object?> json, String key) {
  final value = json[key];
  // Exact JSON-safe integer minor units, including amounts well above 1000 cr.
  if (value is! int || value < 0 || value > 9007199254740991) {
    throw FormatException('Invalid collection amount: $key');
  }
  return value;
}

DateTime _instant(Map<String, Object?> json, String key) {
  final value = _text(json, key);
  final components = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.\d{1,6})?Z$',
  ).firstMatch(value);
  final parsed = DateTime.tryParse(value);
  if (components == null ||
      parsed == null ||
      !parsed.isUtc ||
      parsed.year < 1 ||
      parsed.year != int.parse(components[1]!) ||
      parsed.month != int.parse(components[2]!) ||
      parsed.day != int.parse(components[3]!) ||
      parsed.hour != int.parse(components[4]!) ||
      parsed.minute != int.parse(components[5]!) ||
      parsed.second != int.parse(components[6]!)) {
    throw FormatException('Collection time must be UTC: $key');
  }
  return parsed;
}

Map<String, Object?> _object(Object? value, String key) {
  if (value is! Map<String, Object?>) {
    throw FormatException('Invalid collection object: $key');
  }
  return value;
}

List<ScanPickLine> _lines(Object? value) {
  if (value is! List || value.isEmpty) {
    throw const FormatException('Collection order needs purchased lines');
  }
  final result = value
      .map((item) => ScanPickLine._(_object(item, 'line')))
      .toList(growable: false);
  if (result.map((line) => line.lineId).toSet().length != result.length) {
    throw const FormatException('Duplicate collection line');
  }
  return List<ScanPickLine>.unmodifiable(result);
}
