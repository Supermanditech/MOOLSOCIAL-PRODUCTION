import 'dart:convert';

import 'package:flutter/material.dart';

import '../buy/buy_v2_content_contracts.dart';
import '../buy/buy_v2_models.dart';
import 'work_publication_data.dart';
export 'work_publication_data.dart';

enum WorkspaceIssueTarget { customerOrder, supplierShipment }

/// Choices are supplied with the case, not inferred from an order's status.
enum WorkspaceIssueResponse {
  acceptRequest,
  declineRequest,
  provideDetails;

  String get label => switch (this) {
    acceptRequest => 'Accept request',
    declineRequest => 'Decline request',
    provideDetails => 'Send details',
  };
}

typedef WorkspaceIssueDraftKey = ({
  String account,
  String store,
  String caseId,
});

/// Unsent text only. It cannot authorise a case, payment or stock mutation.
class WorkspaceIssueDraft {
  const WorkspaceIssueDraft({
    required this.key,
    required this.referenceId,
    required this.target,
    required this.expectedRevision,
    this.response,
    this.note = '',
  });
  final WorkspaceIssueDraftKey key;
  final String referenceId;
  final WorkspaceIssueTarget target;
  final int expectedRevision;
  final WorkspaceIssueResponse? response;
  final String note;

  static bool acceptsNote(String value) => value.characters.length <= 2000;

  bool get valid =>
      [
        key.account,
        key.store,
        key.caseId,
        referenceId,
      ].every((value) => value.trim().isNotEmpty) &&
      expectedRevision > 0 &&
      acceptsNote(note);

  Map<String, Object?> toJson() => {
    'version': 1,
    'account': key.account,
    'store': key.store,
    'caseId': key.caseId,
    'referenceId': referenceId,
    'target': target.name,
    'revision': expectedRevision,
    'response': response?.name,
    'note': note,
  };

  static WorkspaceIssueDraft? fromJson(Object? value) {
    if (value is! Map ||
        value['version'] != 1 ||
        value['account'] is! String ||
        value['store'] is! String ||
        value['caseId'] is! String ||
        value['referenceId'] is! String ||
        value['revision'] is! int ||
        value['note'] is! String) {
      return null;
    }
    final target = WorkspaceIssueTarget.values
        .where((v) => v.name == value['target'])
        .firstOrNull;
    final response = WorkspaceIssueResponse.values
        .where((v) => v.name == value['response'])
        .firstOrNull;
    if (target == null || (value['response'] != null && response == null)) {
      return null;
    }
    final draft = WorkspaceIssueDraft(
      key: (
        account: value['account'],
        store: value['store'],
        caseId: value['caseId'],
      ),
      referenceId: value['referenceId'],
      target: target,
      expectedRevision: value['revision'],
      response: response,
      note: value['note'],
    );
    return draft.valid ? draft : null;
  }
}

enum WorkspaceIssueKind {
  returnRequest,
  missingItem,
  wrongItem,
  damagedItem,
  packingShortage,
  substitution;

  String get label => switch (this) {
    returnRequest => 'Return requested',
    missingItem => 'Missing item',
    wrongItem => 'Wrong item',
    damagedItem => 'Damaged item',
    packingShortage => 'Packing shortage',
    substitution => 'Replacement request',
  };
}

enum WorkspaceIssueState {
  retailerReview,
  customerReview,
  supplierReview,
  moolSocialReview,
  resolved,
  declined,
  cancelled;

  String get label => switch (this) {
    retailerReview => 'Your review needed',
    customerReview => 'Awaiting customer response',
    supplierReview => 'Awaiting supplier response',
    moolSocialReview => 'MoolSocial is reviewing',
    resolved => 'Case resolved',
    declined => 'Request declined',
    cancelled => 'Request cancelled',
  };
  bool get closed => const {resolved, declined, cancelled}.contains(this);
}

/// Original purchased line identity, not the current catalogue price or pack.
class WorkspaceIssueLine {
  const WorkspaceIssueLine({
    required this.lineId,
    required this.productId,
    required this.name,
    required this.pack,
    required this.orderedQuantity,
    required this.affectedQuantity,
  });
  final String lineId, productId, name, pack;
  final int orderedQuantity, affectedQuantity;
  bool get valid =>
      lineId.trim().isNotEmpty &&
      productId.trim().isNotEmpty &&
      name.trim().isNotEmpty &&
      orderedQuantity > 0 &&
      affectedQuantity > 0 &&
      affectedQuantity <= orderedQuantity;
  Object get identity =>
      (lineId, productId, name, pack, orderedQuantity, affectedQuantity);
}

/// Read-only case projection. A resolved case does not itself authorise a
/// refund, stock posting, substitution, receipt or customer collection.
class WorkspaceIssueRecord {
  WorkspaceIssueRecord({
    required this.accountScope,
    required this.workspaceId,
    required this.id,
    required this.referenceId,
    required this.target,
    required this.kind,
    required this.state,
    required this.revision,
    required this.updatedAt,
    required this.reason,
    required this.nextStep,
    required List<WorkspaceIssueLine> lines,
    List<WorkspaceIssueResponse> permittedResponses = const [],
    this.resolution,
  }) : lines = List.unmodifiable(lines),
       permittedResponses = List.unmodifiable(permittedResponses);

  final String accountScope, workspaceId, id, referenceId, reason, nextStep;
  final WorkspaceIssueTarget target;
  final WorkspaceIssueKind kind;
  final WorkspaceIssueState state;
  final int revision;
  final DateTime updatedAt;
  final List<WorkspaceIssueLine> lines;
  final List<WorkspaceIssueResponse> permittedResponses;
  final String? resolution;
  WorkspaceIssueDraftKey get draftKey =>
      (account: accountScope, store: workspaceId, caseId: id);
  bool get valid =>
      [
        accountScope,
        workspaceId,
        id,
        referenceId,
        reason,
        nextStep,
      ].every((s) => s.trim().isNotEmpty) &&
      revision > 0 &&
      lines.isNotEmpty &&
      lines.every((line) => line.valid) &&
      lines.map((line) => line.lineId).toSet().length == lines.length &&
      permittedResponses.toSet().length == permittedResponses.length &&
      (state == WorkspaceIssueState.retailerReview ||
          permittedResponses.isEmpty) &&
      (!state.closed || resolution?.trim().isNotEmpty == true);

  Object get _revisionData => (
    accountScope,
    workspaceId,
    id,
    referenceId,
    target,
    kind,
    state,
    updatedAt,
    reason,
    nextStep,
    resolution,
  );
  bool sameRevisionContent(WorkspaceIssueRecord other) =>
      _revisionData == other._revisionData &&
      permittedResponses.length == other.permittedResponses.length &&
      permittedResponses.asMap().entries.every(
        (entry) => entry.value == other.permittedResponses[entry.key],
      ) &&
      lines.length == other.lines.length &&
      lines.asMap().entries.every(
        (entry) => entry.value.identity == other.lines[entry.key].identity,
      );
}

/// Format validation only, using the existing supported Indian mobile range.
/// This does not establish customer identity, consent or OTP verification.
String? normalizeWorkspaceMobile(String value) {
  final input = value.trim();
  if (!RegExp(r'^(?:\+?91[ -]?)?[6-9]\d(?:[ -]?\d){8}$').hasMatch(input)) {
    return null;
  }
  final digits = input.replaceAll(RegExp(r'[ +\-]'), '');
  return digits.length == 12 ? digits.substring(2) : digits;
}

/// Reads a supported phone or the stored `name · phone` display format.
/// Never salvage a substring from malformed data or use this as account proof.
String? workspaceCustomerMobile(String customer) {
  final parts = customer.split('·');
  if (parts.length > 2 || (parts.length == 2 && parts.first.trim().isEmpty)) {
    return null;
  }
  return normalizeWorkspaceMobile(parts.last);
}

enum WorkspacePaymentState {
  unpaid,
  pending,
  partPaid,
  paid,
  failed,
  refundPending,
  refunded,
  returnAdjusted,
  creditApplied,
  disputed,
  unknown;

  String get label => switch (this) {
    unpaid => 'Payment due',
    pending => 'Payment pending',
    partPaid => 'Part paid',
    paid => 'Paid',
    failed => 'Payment failed',
    refundPending => 'Refund pending',
    refunded => 'Refunded',
    returnAdjusted => 'Adjusted for return',
    creditApplied => 'Customer credit applied',
    disputed => 'Payment under review',
    unknown => 'Payment update unavailable',
  };
}

enum WorkspacePaymentChannel {
  platform,
  cash,
  directUpi,
  credit,
  unknown,
  bankTransfer;

  String get label => switch (this) {
    platform => 'Through MoolSocial',
    cash => 'Cash at store',
    directUpi => 'UPI to store',
    bankTransfer => 'Bank transfer to store',
    credit => 'On account',
    unknown => 'Payment method unavailable',
  };
}

enum WorkspacePayoutState {
  requested,
  processing,
  paid,
  failed,
  held,
  cancelled,
  unknown;

  String get label => switch (this) {
    requested => 'Requested',
    processing => 'Processing',
    paid => 'Paid to bank',
    failed => 'Payout failed',
    held => 'On hold',
    cancelled => 'Cancelled',
    unknown => 'Checking payout',
  };
}

bool _financeAmountValid(int value, {bool signed = false}) =>
    (signed || value >= 0) && value.abs() <= 9007199254740991;

/// Authority-supplied order payment facts. Fulfilment and bank settlement are
/// deliberately absent: paid is neither delivered nor proof of platform funds.
class WorkspacePaymentRecord {
  const WorkspacePaymentRecord({
    required this.orderId,
    required this.customerId,
    required this.customerName,
    required this.revision,
    required this.updatedAt,
    required this.amountMinor,
    required this.paidMinor,
    required this.dueMinor,
    required this.refundedMinor,
    required this.state,
    required this.channel,
    this.invoiceId,
    this.transactionId,
  });
  final String orderId, customerId, customerName;
  final String? invoiceId, transactionId;
  final int revision, amountMinor, paidMinor, dueMinor, refundedMinor;
  final DateTime updatedAt;
  final WorkspacePaymentState state;
  final WorkspacePaymentChannel channel;
  Object get revisionData => (
    orderId,
    customerId,
    customerName,
    updatedAt.toUtc(),
    amountMinor,
    paidMinor,
    dueMinor,
    refundedMinor,
    state,
    channel,
    invoiceId,
    transactionId,
  );
  bool get valid =>
      [orderId, customerId, customerName].every((s) => s.trim().isNotEmpty) &&
      revision > 0 &&
      [
        amountMinor,
        paidMinor,
        dueMinor,
        refundedMinor,
      ].every((n) => _financeAmountValid(n)) &&
      paidMinor <= amountMinor &&
      dueMinor <= amountMinor &&
      refundedMinor <= paidMinor &&
      (state != WorkspacePaymentState.paid ||
          (dueMinor == 0 && paidMinor == amountMinor)) &&
      (state != WorkspacePaymentState.partPaid ||
          (paidMinor > 0 && dueMinor > 0)) &&
      (state != WorkspacePaymentState.returnAdjusted || dueMinor == 0) &&
      (state != WorkspacePaymentState.refunded ||
          (paidMinor > 0 && refundedMinor == paidMinor));
  String get label => state == WorkspacePaymentState.paid
      ? switch (channel) {
          WorkspacePaymentChannel.platform => 'Paid through MoolSocial',
          WorkspacePaymentChannel.cash => 'Paid in cash',
          WorkspacePaymentChannel.directUpi => 'Paid to store',
          WorkspacePaymentChannel.bankTransfer => 'Paid by bank transfer',
          _ => state.label,
        }
      : state.label;
}

class WorkspacePayoutRecord {
  const WorkspacePayoutRecord({
    required this.id,
    required this.operationId,
    required this.revision,
    required this.amountMinor,
    required this.updatedAt,
    required this.state,
    this.bankLabel,
    this.expectedBy,
    this.message,
  });
  final String id, operationId;
  final int revision, amountMinor;
  final DateTime updatedAt;
  final WorkspacePayoutState state;

  /// Masked customer-facing bank label, not raw account credentials.
  final String? bankLabel, expectedBy, message;
  Object get revisionData => (
    id,
    operationId,
    amountMinor,
    updatedAt.toUtc(),
    state,
    bankLabel,
    expectedBy,
    message,
  );
  bool get valid =>
      id.trim().isNotEmpty &&
      operationId.trim().isNotEmpty &&
      revision > 0 &&
      _financeAmountValid(amountMinor);
}

/// Goods accepted back against one original customer invoice. A returned unit
/// need not be sellable; only restockQuantity may increase available stock.
class WorkspaceCustomerReturnLine {
  const WorkspaceCustomerReturnLine({
    required this.productId,
    required this.quantity,
    required this.restockQuantity,
  });
  final String productId;
  final int quantity, restockQuantity;
  bool get valid =>
      productId.trim().isNotEmpty &&
      quantity > 0 &&
      quantity <= 2147483647 &&
      restockQuantity >= 0 &&
      restockQuantity <= quantity;
}

class WorkspaceCustomerReturn {
  static const reasonLabels = <String, String>{
    'damaged': 'Damaged',
    'expired': 'Expired',
    'wrong_item': 'Wrong item',
    'quality_issue': 'Quality issue',
    'changed_mind': 'Customer changed mind',
    'other': 'Other',
  };
  WorkspaceCustomerReturn({
    required this.accountScope,
    required this.workspaceId,
    required this.customerId,
    required this.invoiceId,
    required this.orderId,
    required this.operationId,
    required this.expectedRevision,
    required this.reason,
    this.reasonCode,
    required List<WorkspaceCustomerReturnLine> lines,
  }) : lines = List.unmodifiable(lines);
  final String accountScope,
      workspaceId,
      customerId,
      invoiceId,
      orderId,
      operationId,
      reason;
  final int expectedRevision;
  // Absent on historical records; never infer a category from their free text.
  final String? reasonCode;
  final List<WorkspaceCustomerReturnLine> lines;
  bool get valid =>
      [
        accountScope,
        workspaceId,
        customerId,
        invoiceId,
        orderId,
        operationId,
        reason,
      ].every((value) => value.trim().isNotEmpty) &&
      expectedRevision > 0 &&
      (reasonCode == null || reasonLabels.containsKey(reasonCode)) &&
      lines.isNotEmpty &&
      lines.every((line) => line.valid) &&
      lines.map((line) => line.productId).toSet().length == lines.length;

  Map<String, Object?> toJson() => {
    'accountScope': accountScope,
    'workspaceId': workspaceId,
    'customerId': customerId,
    'invoiceId': invoiceId,
    'orderId': orderId,
    'operationId': operationId,
    'expectedRevision': expectedRevision,
    'reason': reason,
    if (reasonCode != null) 'reasonCode': reasonCode,
    'lines': [
      for (final line in lines)
        {
          'productId': line.productId,
          'quantity': line.quantity,
          'restockQuantity': line.restockQuantity,
        },
    ],
  };

  factory WorkspaceCustomerReturn.fromJson(Object? value) {
    if (value is! Map) throw const FormatException('Return data is missing.');
    final result = WorkspaceCustomerReturn(
      accountScope: value['accountScope'] as String,
      workspaceId: value['workspaceId'] as String,
      customerId: value['customerId'] as String,
      invoiceId: value['invoiceId'] as String,
      orderId: value['orderId'] as String,
      operationId: value['operationId'] as String,
      expectedRevision: value['expectedRevision'] as int,
      reason: value['reason'] as String,
      reasonCode: value['reasonCode'] as String?,
      lines: [
        for (final line in value['lines'] as List)
          WorkspaceCustomerReturnLine(
            productId: line['productId'] as String,
            quantity: line['quantity'] as int,
            restockQuantity: line['restockQuantity'] as int,
          ),
      ],
    );
    if (!result.valid) throw const FormatException('Return data is invalid.');
    return result;
  }

  /// Uses the invoiced line total, including its original discount, never today's
  /// catalogue price. Cumulative allocation preserves every paise on a full return.
  /// priorReturns must contain only confirmed returns for this scoped invoice.
  int? creditMinorFor(
    WorkspaceOrderRecord order, {
    required List<WorkspaceCustomerReturn> priorReturns,
  }) {
    if (!valid ||
        order.id != orderId ||
        !order.isCompleted ||
        !order.validBillAmounts ||
        !order.hasCompleteItemSnapshot ||
        order.itemSnapshots.any(
          (line) =>
              !_financeAmountValid(line.lineTotalPaise) ||
              !_financeAmountValid(line.unitPricePaise),
        ) ||
        order.itemSnapshots.fold<int>(
              0,
              (sum, line) => sum + line.lineTotalPaise,
            ) !=
            order.payableMinor) {
      return null;
    }
    final returned = <String, int>{};
    final operations = <String>{operationId};
    for (final previous in priorReturns) {
      if (!previous.valid ||
          previous.accountScope != accountScope ||
          previous.workspaceId != workspaceId ||
          previous.customerId != customerId ||
          previous.invoiceId != invoiceId ||
          previous.orderId != orderId ||
          !operations.add(previous.operationId)) {
        return null;
      }
      for (final line in previous.lines) {
        returned.update(
          line.productId,
          (quantity) => quantity + line.quantity,
          ifAbsent: () => line.quantity,
        );
      }
    }
    final sold = {for (final line in order.itemSnapshots) line.productId: line};
    if (returned.entries.any(
      (entry) =>
          sold[entry.key] == null || entry.value > sold[entry.key]!.quantity,
    )) {
      return null;
    }
    int credit = 0;
    for (final line in lines) {
      final original = sold[line.productId];
      final before = returned[line.productId] ?? 0;
      final after = before + line.quantity;
      if (original == null || after > original.quantity) return null;
      // BigInt avoids intermediate multiplication losing precision on Flutter web.
      final total = BigInt.from(original.lineTotalPaise);
      final quantity = BigInt.from(original.quantity);
      credit +=
          ((total * BigInt.from(after)) ~/ quantity -
                  (total * BigInt.from(before)) ~/ quantity)
              .toInt();
    }
    return _financeAmountValid(credit) ? credit : null;
  }
}

enum WorkspaceLedgerEntryKind { invoice, collection, creditNote, refund, creditUsed, creditReceived }

enum WorkspaceLedgerPostingState { pending, posted, failed }

/// A request to record one receipt against one existing customer invoice.
/// It does not establish that money was received; the adapter confirms that.
class WorkspaceCustomerCollection {
  const WorkspaceCustomerCollection({
    required this.accountScope,
    required this.workspaceId,
    required this.customerId,
    required this.invoiceId,
    required this.orderId,
    required this.operationId,
    required this.expectedRevision,
    required this.amountMinor,
    required this.channel,
    this.reference,
  });
  final String accountScope,
      workspaceId,
      customerId,
      invoiceId,
      orderId,
      operationId;
  final int expectedRevision, amountMinor;
  final WorkspacePaymentChannel channel;
  final String? reference;
  bool get valid =>
      [
        accountScope,
        workspaceId,
        customerId,
        invoiceId,
        orderId,
        operationId,
      ].every((value) => value.trim().isNotEmpty) &&
      expectedRevision > 0 &&
      amountMinor > 0 &&
      _financeAmountValid(amountMinor) &&
      (channel == WorkspacePaymentChannel.cash ||
          ((channel == WorkspacePaymentChannel.directUpi ||
                  channel == WorkspacePaymentChannel.bankTransfer) &&
              reference?.trim().isNotEmpty == true));
  Object get identityData => (
    accountScope,
    workspaceId,
    customerId,
    invoiceId,
    orderId,
    operationId,
    expectedRevision,
    amountMinor,
    channel,
    reference,
  );
}

/// Refund confirmation request; it cannot be used as a collection command.
class WorkspaceCustomerRefund {
  const WorkspaceCustomerRefund({
    required this.accountScope,
    required this.workspaceId,
    required this.customerId,
    required this.invoiceId,
    required this.orderId,
    required this.operationId,
    required this.expectedRevision,
    required this.amountMinor,
    required this.channel,
    this.reference,
    this.sourceCollectionId,
  });
  final String accountScope,
      workspaceId,
      customerId,
      invoiceId,
      orderId,
      operationId;
  final int expectedRevision, amountMinor;
  final WorkspacePaymentChannel channel;
  final String? reference;
  /// Original posted receipt; absent only on older unallocated refund records.
  final String? sourceCollectionId;
  bool get valid =>
      [
        accountScope,
        workspaceId,
        customerId,
        invoiceId,
        orderId,
        operationId,
      ].every((value) => value.trim().isNotEmpty) &&
      expectedRevision > 0 &&
      amountMinor > 0 &&
      _financeAmountValid(amountMinor) &&
      (sourceCollectionId == null || sourceCollectionId!.trim().isNotEmpty) &&
      (channel == WorkspacePaymentChannel.cash ||
          ((channel == WorkspacePaymentChannel.directUpi ||
                  channel == WorkspacePaymentChannel.bankTransfer) &&
              reference?.trim().isNotEmpty == true));
  Map<String, Object?> toJson() => {
    'accountScope': accountScope,
    'workspaceId': workspaceId,
    'customerId': customerId,
    'invoiceId': invoiceId,
    'orderId': orderId,
    'operationId': operationId,
    'expectedRevision': expectedRevision,
    'amountMinor': amountMinor,
    'channel': channel.name,
    'reference': reference,
    if (sourceCollectionId != null) 'sourceCollectionId': sourceCollectionId,
  };
  factory WorkspaceCustomerRefund.fromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Refund data is missing.');
    }
    final result = WorkspaceCustomerRefund(
      accountScope: value['accountScope'] as String,
      workspaceId: value['workspaceId'] as String,
      customerId: value['customerId'] as String,
      invoiceId: value['invoiceId'] as String,
      orderId: value['orderId'] as String,
      operationId: value['operationId'] as String,
      expectedRevision: value['expectedRevision'] as int,
      amountMinor: value['amountMinor'] as int,
      channel: WorkspacePaymentChannel.values.byName(
        value['channel'] as String,
      ),
      reference: value['reference'] as String?,
      sourceCollectionId: value['sourceCollectionId'] as String?,
    );
    if (!result.valid) {
      throw const FormatException('Refund data is invalid.');
    }
    return result;
  }
  Object get identityData => (
    accountScope,
    workspaceId,
    customerId,
    invoiceId,
    orderId,
    operationId,
    expectedRevision,
    amountMinor,
    channel,
    reference,
    sourceCollectionId,
  );
}

/// A dated customer-account event, not a command to move money or stock.
/// Positive balances mean the customer owes the Store; negative balances are
/// customer credit. A refund consumes that credit without creating another sale.
class WorkspaceCustomerLedgerEntry {
  const WorkspaceCustomerLedgerEntry({
    required this.id,
    required this.operationId,
    required this.invoiceId,
    required this.orderId,
    required this.sequence,
    required this.occurredAt,
    required this.kind,
    required this.state,
    required this.amountMinor,
    this.channel = WorkspacePaymentChannel.unknown,
    this.paymentReference,
    this.customerReturn,
    this.customerRefund,
  });

  final String id, operationId, invoiceId, orderId;
  final int sequence, amountMinor;
  final DateTime occurredAt;
  final WorkspaceLedgerEntryKind kind;
  final WorkspaceLedgerPostingState state;
  final WorkspacePaymentChannel channel;
  final String? paymentReference;
  final WorkspaceCustomerReturn? customerReturn;
  final WorkspaceCustomerRefund? customerRefund;

  Object get identityData => (
    id,
    operationId,
    invoiceId,
    orderId,
    sequence,
    occurredAt.toUtc(),
    kind,
    amountMinor,
    channel,
    paymentReference,
    customerReturn == null ? null : jsonEncode(customerReturn!.toJson()),
    customerRefund?.identityData,
  );

  bool get valid =>
      [id, operationId, invoiceId, orderId].every((v) => v.trim().isNotEmpty) &&
      sequence > 0 &&
      amountMinor > 0 &&
      _financeAmountValid(amountMinor) &&
      (customerRefund == null ||
          (kind == WorkspaceLedgerEntryKind.refund &&
              customerRefund!.valid &&
              customerRefund!.operationId == operationId &&
              customerRefund!.invoiceId == invoiceId &&
              customerRefund!.orderId == orderId &&
              customerRefund!.amountMinor == amountMinor &&
              customerRefund!.channel == channel &&
              customerRefund!.reference == paymentReference)) &&
      (customerReturn == null ||
          (kind == WorkspaceLedgerEntryKind.creditNote &&
              customerReturn!.valid &&
              customerReturn!.operationId == operationId &&
              customerReturn!.invoiceId == invoiceId &&
              customerReturn!.orderId == orderId));

  /// Stable linked stock events for a confirmed credit. This does not mutate
  /// inventory; an inventory projection must acknowledge these IDs once.
  List<WorkspaceStockMovement>? returnStockMovements(
    WorkspaceOrderRecord order,
  ) {
    if (order.id != orderId ||
        !order.isCompleted ||
        !order.hasCompleteItemSnapshot) {
      return null;
    }
    return returnStockMovementsFromSavedItems(order.itemSnapshots);
  }

  List<WorkspaceStockMovement>? returnStockMovementsFromSavedItems(
    List<WorkspaceOrderItemSnapshot> items,
  ) {
    final returned = customerReturn;
    if (!valid ||
        state != WorkspaceLedgerPostingState.posted ||
        returned == null ||
        items.isEmpty ||
        items.map((item) => item.productId).toSet().length != items.length ||
        items.any(
          (item) =>
              item.productId.trim().isEmpty ||
              item.name.trim().isEmpty ||
              item.pack.trim().isEmpty ||
              item.quantity <= 0,
        )) {
      return null;
    }
    final sold = {for (final line in items) line.productId: line};
    final movements = <WorkspaceStockMovement>[];
    for (final line in returned.lines) {
      final original = sold[line.productId];
      if (original == null || line.quantity > original.quantity) {
        return null;
      }
      if (line.restockQuantity == 0) continue;
      movements.add(
        WorkspaceStockMovement(
          id: 'RETURN-${Uri.encodeComponent(operationId)}-${Uri.encodeComponent(line.productId)}',
          productId: line.productId,
          productLabel: '${original.name} · ${original.pack}',
          kind: WorkspaceStockMovementKind.returned,
          quantityDelta: line.restockQuantity,
          reason: returned.reason,
          occurredAt: occurredAt,
          referenceKind: WorkspaceStockReferenceKind.order,
          referenceId: orderId,
        ),
      );
    }
    return List.unmodifiable(movements);
  }

  int get balanceDeltaMinor => state != WorkspaceLedgerPostingState.posted
      ? 0
      : switch (kind) {
          WorkspaceLedgerEntryKind.invoice ||
          WorkspaceLedgerEntryKind.refund ||
          WorkspaceLedgerEntryKind.creditUsed => amountMinor,
          WorkspaceLedgerEntryKind.collection ||
          WorkspaceLedgerEntryKind.creditNote ||
          WorkspaceLedgerEntryKind.creditReceived => -amountMinor,
        };
}

/// A complete statement may calculate balances only from a supplied opening
/// balance. Partial history is displayable but cannot imply a closing balance.
class WorkspaceCustomerLedger {
  WorkspaceCustomerLedger({
    required this.accountScope,
    required this.workspaceId,
    required this.customerId,
    required this.customerName,
    required this.revision,
    required this.asOf,
    required List<WorkspaceCustomerLedgerEntry> entries,
    this.openingBalanceMinor,
    this.historyComplete = false,
  }) : entries = List.unmodifiable(entries);

  final String accountScope, workspaceId, customerId, customerName;
  final int revision;
  final DateTime asOf;
  final int? openingBalanceMinor;
  final bool historyComplete;
  final List<WorkspaceCustomerLedgerEntry> entries;

  /// Invoice-local amounts never use another bill's payments or opening balance.
  /// Null means the history cannot authorize a collection, credit or refund.
  ({
    int billedMinor,
    int creditedMinor,
    int collectedMinor,
    int refundedMinor,
    int dueMinor,
    int refundableMinor,
    int availableCreditMinor,
  })?
  invoiceBalance(String invoiceId) {
    if (!valid || !historyComplete || invoiceId.trim().isEmpty) return null;
    final lines = entries.where((entry) => entry.invoiceId == invoiceId);
    int billed = 0, credited = 0, collected = 0, refunded = 0;
    int used = 0, received = 0;
    String? orderId;
    for (final entry in lines) {
      if (orderId != null && orderId != entry.orderId) return null;
      orderId = entry.orderId;
      if (entry.state != WorkspaceLedgerPostingState.posted) continue;
      final balance = billed - credited - collected + refunded + used - received;
      switch (entry.kind) {
        case WorkspaceLedgerEntryKind.invoice:
          if (billed != 0) return null;
          billed = entry.amountMinor;
        case WorkspaceLedgerEntryKind.collection:
          if (billed == 0 || entry.amountMinor > balance) return null;
          collected += entry.amountMinor;
        case WorkspaceLedgerEntryKind.creditNote:
          if (billed == 0 || entry.amountMinor > billed - credited) return null;
          credited += entry.amountMinor;
        case WorkspaceLedgerEntryKind.refund:
          if (billed == 0 ||
              entry.amountMinor > -balance ||
              entry.amountMinor > collected - refunded) {
            return null;
          }
          refunded += entry.amountMinor;
        case WorkspaceLedgerEntryKind.creditUsed:
          if (billed == 0 || entry.amountMinor > -balance) return null;
          used += entry.amountMinor;
        case WorkspaceLedgerEntryKind.creditReceived:
          if (billed == 0 || entry.amountMinor > balance) return null;
          received += entry.amountMinor;
      }
    }
    if (billed == 0) return null;
    final balance = billed - credited - collected + refunded + used - received;
    final available = balance < 0 ? -balance : 0;
    final cashRemaining = collected - refunded;
    return (
      billedMinor: billed,
      creditedMinor: credited,
      collectedMinor: collected,
      refundedMinor: refunded,
      dueMinor: balance > 0 ? balance : 0,
      refundableMinor: available < cashRemaining ? available : cashRemaining,
      availableCreditMinor: available,
    );
  }

  Set<WorkspacePaymentChannel> recordedReceiptChannels(String invoiceId, String orderId) {
    if (!valid || !historyComplete) return {};
    return entries.where((entry) => entry.invoiceId == invoiceId &&
        entry.orderId == orderId && entry.kind == WorkspaceLedgerEntryKind.collection &&
        entry.state == WorkspaceLedgerPostingState.posted)
        .map((entry) => entry.channel).toSet();
  }

  /// Remaining original tender, not the invoice's currently available credit.
  /// Old refunds without a receipt link cannot be allocated by guessing.
  int? receiptRemainingMinor(String invoiceId, String receiptId) {
    if (!valid || !historyComplete) return null;
    final receipts = entries.where((e) =>
        e.id == receiptId && e.invoiceId == invoiceId &&
        e.kind == WorkspaceLedgerEntryKind.collection &&
        e.state == WorkspaceLedgerPostingState.posted);
    if (receipts.length != 1) return null;
    final receipt = receipts.single;
    var remaining = receipt.amountMinor;
    for (final entry in entries.where((e) =>
        e.invoiceId == invoiceId && e.kind == WorkspaceLedgerEntryKind.refund &&
        e.state == WorkspaceLedgerPostingState.posted)) {
      final source = entry.customerRefund?.sourceCollectionId;
      if (source == null) return null;
      final originals = entries.where((e) => e.id == source &&
          e.invoiceId == invoiceId && e.orderId == entry.orderId &&
          e.kind == WorkspaceLedgerEntryKind.collection &&
          e.state == WorkspaceLedgerPostingState.posted && e.channel == entry.channel);
      if (originals.length != 1) return null;
      if (source == receiptId) {
        if (entry.orderId != receipt.orderId || entry.channel != receipt.channel) return null;
        remaining -= entry.amountMinor;
      }
    }
    return remaining < 0 ? null : remaining;
  }

  bool permitsReceiptRefund(WorkspaceCustomerRefund request) {
    if (request.accountScope != accountScope || request.workspaceId != workspaceId ||
        request.customerId != customerId) {
      return false;
    }
    final id = request.sourceCollectionId;
    if (id == null) return true; // Retain legacy journal/reconciliation support.
    final receipt = entries.where((e) => e.id == id &&
        e.invoiceId == request.invoiceId && e.orderId == request.orderId &&
        e.channel == request.channel).firstOrNull;
    final remaining = receiptRemainingMinor(request.invoiceId, id);
    return receipt != null && remaining != null && request.amountMinor <= remaining;
  }

  /// Refreshes preserve known events. Corrections to posted money require a
  /// separate linked credit/refund, never an edit of an accepted event.
  bool canFollow(WorkspaceCustomerLedger previous) {
    if (!valid ||
        accountScope != previous.accountScope ||
        workspaceId != previous.workspaceId ||
        customerId != previous.customerId ||
        revision < previous.revision ||
        asOf.isBefore(previous.asOf) ||
        (previous.openingBalanceMinor != null &&
            openingBalanceMinor != previous.openingBalanceMinor) ||
        (previous.historyComplete && !historyComplete)) {
      return false;
    }
    final current = {for (final entry in entries) entry.id: entry};
    for (final old in previous.entries) {
      final next = current[old.id];
      if (next == null ||
          next.identityData != old.identityData ||
          (old.state != WorkspaceLedgerPostingState.pending &&
              next.state != old.state)) {
        return false;
      }
    }
    if (revision == previous.revision) {
      return customerName == previous.customerName &&
          asOf.isAtSameMomentAs(previous.asOf) &&
          openingBalanceMinor == previous.openingBalanceMinor &&
          historyComplete == previous.historyComplete &&
          entries.length == previous.entries.length &&
          previous.entries.every((old) => current[old.id]?.state == old.state);
    }
    return true;
  }

  bool get valid {
    if (![
          accountScope,
          workspaceId,
          customerId,
          customerName,
        ].every((v) => v.trim().isNotEmpty) ||
        revision <= 0 ||
        (historyComplete && openingBalanceMinor == null) ||
        (openingBalanceMinor != null &&
            !_financeAmountValid(openingBalanceMinor!, signed: true))) {
      return false;
    }
    final ids = <String>{};
    final operations = <(WorkspaceLedgerEntryKind, String, String)>{};
    final invoices = <String>{};
    var previousSequence = 0;
    DateTime? previousTime;
    var balance = openingBalanceMinor ?? 0;
    final creditPairs = <String, List<WorkspaceCustomerLedgerEntry>>{};
    final invoiceRunning = <String, int>{};
    for (final entry in entries) {
      if (!entry.valid ||
          (entry.customerRefund != null &&
              (entry.customerRefund!.accountScope != accountScope ||
                  entry.customerRefund!.workspaceId != workspaceId ||
                  entry.customerRefund!.customerId != customerId)) ||
          (entry.customerReturn != null &&
              (entry.customerReturn!.accountScope != accountScope ||
                  entry.customerReturn!.workspaceId != workspaceId ||
                  entry.customerReturn!.customerId != customerId)) ||
          entry.occurredAt.isAfter(asOf) ||
          (previousTime != null && entry.occurredAt.isBefore(previousTime)) ||
          entry.sequence <= previousSequence ||
          !ids.add(entry.id) ||
          !operations.add((entry.kind, entry.operationId, entry.invoiceId)) ||
          (entry.kind == WorkspaceLedgerEntryKind.invoice &&
              !invoices.add(entry.invoiceId))) {
        return false;
      }
      balance += entry.balanceDeltaMinor;
      if (entry.kind == WorkspaceLedgerEntryKind.creditUsed ||
          entry.kind == WorkspaceLedgerEntryKind.creditReceived) {
        if (entry.state != WorkspaceLedgerPostingState.posted ||
            entry.channel != WorkspacePaymentChannel.credit ||
            entry.customerReturn != null || entry.customerRefund != null) { return false; }
        final available = invoiceRunning[entry.invoiceId];
        if (available == null || !invoices.contains(entry.invoiceId) ||
            (entry.kind == WorkspaceLedgerEntryKind.creditUsed
                ? entry.amountMinor > -available : entry.amountMinor > available)) { return false; }
        creditPairs.putIfAbsent(entry.operationId, () => []).add(entry);
      }
      invoiceRunning.update(entry.invoiceId, (value) => value + entry.balanceDeltaMinor,
        ifAbsent: () => entry.balanceDeltaMinor);
      if (!_financeAmountValid(balance, signed: true)) return false;
      previousSequence = entry.sequence;
      previousTime = entry.occurredAt;
    }
    for (final pair in creditPairs.values) {
      if (pair.length != 2 || pair[0].kind != WorkspaceLedgerEntryKind.creditUsed ||
          pair[1].kind != WorkspaceLedgerEntryKind.creditReceived ||
          pair[0].amountMinor != pair[1].amountMinor ||
          pair[0].invoiceId == pair[1].invoiceId || pair[0].orderId == pair[1].orderId ||
          pair[1].sequence != pair[0].sequence + 1 ||
          pair[0].occurredAt != pair[1].occurredAt) { return false; }
    }
    return true;
  }

  /// Non-cash allocation within this exact customer ledger. The caller persists
  /// the complete returned checkpoint atomically before exposing the new balance.
  WorkspaceCustomerLedger allocateCredit({required String sourceInvoiceId,
    required String targetInvoiceId, required int amountMinor,
    required int expectedRevision, required String operationId, required DateTime at}) {
    final replay = entries.where((e) => e.operationId == operationId).toList();
    if (replay.isNotEmpty) {
      if (valid && replay.length == 2 &&
          replay[0].kind == WorkspaceLedgerEntryKind.creditUsed &&
          replay[1].kind == WorkspaceLedgerEntryKind.creditReceived &&
          replay[0].invoiceId == sourceInvoiceId && replay[1].invoiceId == targetInvoiceId &&
          replay.every((e) => e.amountMinor == amountMinor)) { return this; }
      throw const FormatException('Credit operation identity changed.');
    }
    final source = invoiceBalance(sourceInvoiceId);
    final target = invoiceBalance(targetInvoiceId);
    if (!historyComplete || revision != expectedRevision || operationId.trim().isEmpty ||
        at.isBefore(asOf) || sourceInvoiceId == targetInvoiceId ||
        source == null || target == null || amountMinor <= 0 ||
        amountMinor > source.availableCreditMinor || amountMinor > target.dueMinor) {
      throw const FormatException('Refresh customer credit and this invoice before applying.');
    }
    return WorkspaceCustomerLedger(accountScope: accountScope, workspaceId: workspaceId,
      customerId: customerId, customerName: customerName, revision: revision + 1,
      asOf: at, openingBalanceMinor: openingBalanceMinor, historyComplete: true,
      entries: [...entries,
        for (var i = 0; i < 2; i++)
          WorkspaceCustomerLedgerEntry(id: 'CREDIT-$operationId-$i', operationId: operationId,
            invoiceId: i == 0 ? sourceInvoiceId : targetInvoiceId,
            orderId: entries.firstWhere((e) => e.invoiceId == (i == 0 ? sourceInvoiceId : targetInvoiceId)).orderId,
            sequence: (entries.lastOrNull?.sequence ?? 0) + i + 1, occurredAt: at,
            kind: i == 0 ? WorkspaceLedgerEntryKind.creditUsed : WorkspaceLedgerEntryKind.creditReceived,
            state: WorkspaceLedgerPostingState.posted, amountMinor: amountMinor,
            channel: WorkspacePaymentChannel.credit),
      ]);
  }

  int? get closingBalanceMinor => !valid || !historyComplete
      ? null
      : entries.fold<int>(
          openingBalanceMinor!,
          (balance, entry) => balance + entry.balanceDeltaMinor,
        );
}

/// One atomic, read-only finance projection from an authenticated Store ledger.
/// Monetary values are INR minor units. Totals cover the account/Store ledger,
/// not a sum of the possibly partial rows. A snapshot authorizes no money move.
class WorkspaceFinanceSnapshot {
  WorkspaceFinanceSnapshot({
    required this.accountScope,
    required this.workspaceId,
    required this.revision,
    required this.asOf,
    required this.salesTodayMinor,
    required this.duesMinor,
    required this.availableMinor,
    required this.heldMinor,
    required this.requestedMinor,
    required this.paidOutMinor,
    required this.feesMinor,
    required this.deliveryAdjustmentsMinor,
    required this.refundsMinor,
    required this.taxWithheldMinor,
    required List<WorkspacePaymentRecord> payments,
    required List<WorkspacePayoutRecord> payouts,
    List<WorkspaceCustomerLedger> customerLedgers = const [],
    this.historyComplete = false,
  }) : payments = List.unmodifiable(payments),
       payouts = List.unmodifiable(payouts),
       customerLedgers = List.unmodifiable(customerLedgers);
  final String accountScope, workspaceId;
  final int revision,
      salesTodayMinor,
      duesMinor,
      availableMinor,
      heldMinor,
      requestedMinor,
      paidOutMinor,
      feesMinor,
      deliveryAdjustmentsMinor,
      refundsMinor,
      taxWithheldMinor;
  final DateTime asOf;
  final bool historyComplete;
  final List<WorkspacePaymentRecord> payments;
  final List<WorkspacePayoutRecord> payouts;
  final List<WorkspaceCustomerLedger> customerLedgers;

  /// Confirmed return operations, not units or cash refunds. End is exclusive.
  /// Null means incomplete evidence; an empty map means no returns in the period.
  Map<String, ({int count, int creditMinor})>? returnReasonsBetween(
    DateTime start, DateTime end,
  ) {
    if (!valid || !historyComplete || !end.isAfter(start) ||
        customerLedgers.any((ledger) => !ledger.historyComplete)) {
      return null;
    }
    final result = <String, ({int count, int creditMinor})>{};
    for (final ledger in customerLedgers) {
      for (final entry in ledger.entries) {
        if (entry.kind != WorkspaceLedgerEntryKind.creditNote ||
            entry.state != WorkspaceLedgerPostingState.posted ||
            entry.occurredAt.isBefore(start) || !entry.occurredAt.isBefore(end)) {
          continue;
        }
        final returned = entry.customerReturn;
        if (returned == null || !returned.valid ||
            returned.accountScope != accountScope || returned.workspaceId != workspaceId ||
            returned.customerId != ledger.customerId || returned.invoiceId != entry.invoiceId ||
            returned.orderId != entry.orderId || returned.operationId != entry.operationId) {
          return null;
        }
        final code = returned.reasonCode ?? 'uncategorised';
        final previous = result[code] ?? (count: 0, creditMinor: 0);
        result[code] = (count: previous.count + 1,
          creditMinor: previous.creditMinor + entry.amountMinor);
      }
    }
    return Map.unmodifiable(result);
  }

  /// Compares the supplied paid-out total with its confirmed payout records.
  /// Requests, holds and processing states never count as received money.
  /// This is a projection consistency check, not a bank account balance or
  /// independent bank confirmation. Partial history cannot reconcile a total.
  ({int recordedMinor, int reportedMinor, int? differenceMinor})?
  get settlementPaidReconciliation {
    if (!valid) {
      return null;
    }
    final recorded = payouts
        .where((payout) => payout.state == WorkspacePayoutState.paid)
        .fold<int>(0, (sum, payout) => sum + payout.amountMinor);
    if (!_financeAmountValid(recorded)) {
      return null;
    }
    return (
      recordedMinor: recorded,
      reportedMinor: paidOutMinor,
      differenceMinor: historyComplete ? paidOutMinor - recorded : null,
    );
  }

  bool get _customerIdentitiesValid {
    final ids = <String>{};
    final invoiceCustomers = <String, String>{};
    for (final ledger in customerLedgers) {
      for (final entry in ledger.entries) {
        if (!ids.add(entry.id)) return false;
        final customer = invoiceCustomers.putIfAbsent(
          entry.invoiceId,
          () => ledger.customerId,
        );
        if (customer != ledger.customerId) return false;
      }
    }
    return true;
  }

  bool get valid =>
      _customerIdentitiesValid &&
      accountScope.trim().isNotEmpty &&
      workspaceId.trim().isNotEmpty &&
      revision > 0 &&
      [
        salesTodayMinor,
        duesMinor,
        availableMinor,
        heldMinor,
        requestedMinor,
        paidOutMinor,
        refundsMinor,
      ].every((n) => _financeAmountValid(n)) &&
      [
        feesMinor,
        deliveryAdjustmentsMinor,
        taxWithheldMinor,
      ].every((n) => _financeAmountValid(n, signed: true)) &&
      payments.every((p) => p.valid && !p.updatedAt.isAfter(asOf)) &&
      payouts.every((p) => p.valid && !p.updatedAt.isAfter(asOf)) &&
      payments.map((p) => p.orderId).toSet().length == payments.length &&
      payouts.map((p) => p.id).toSet().length == payouts.length &&
      payouts.map((p) => p.operationId).toSet().length == payouts.length &&
      customerLedgers.every(
        (ledger) =>
            ledger.valid &&
            ledger.accountScope == accountScope &&
            ledger.workspaceId == workspaceId &&
            !ledger.asOf.isAfter(asOf),
      ) &&
      customerLedgers.map((l) => l.customerId).toSet().length ==
          customerLedgers.length;
}

/// Read-only rows for the Store's existing money statement. Invoice, bill and
/// stock facts are deliberately not money movements. A payout is an internal
/// transfer, so it cannot increase the Store's recorded receipts a second time.
class WorkspaceMoneyStatementEntry {
  const WorkspaceMoneyStatementEntry({
    required this.id,
    required this.label,
    required this.party,
    required this.reference,
    required this.method,
    required this.occurredAt,
    required this.amountMinor,
    required this.incoming,
    required this.posted,
    this.transfer = false,
    required this.status,
  });
  final String id, label, party, reference, method, status;
  final DateTime occurredAt;
  final int amountMinor;
  final bool incoming, posted, transfer;
}

/// One confirmed movement in an explicitly identified cash/bank register.
/// The supplying adapter must map the original operation to this register;
/// a payment-method label alone cannot identify a particular bank account.
class WorkspaceMoneyRegisterEntry {
  const WorkspaceMoneyRegisterEntry({
    required this.id,
    required this.reference,
    required this.occurredAt,
    required this.deltaMinor,
  });
  final String id, reference;
  final DateTime occurredAt;
  final int deltaMinor;
  bool get valid =>
      id.trim().isNotEmpty &&
      reference.trim().isNotEmpty &&
      deltaMinor != 0 &&
      _financeAmountValid(deltaMinor, signed: true);
  Object get identity => (id, reference, occurredAt.toUtc(), deltaMinor);
  Map<String, Object?> toJson() => {
    'id': id,
    'reference': reference,
    'occurredAt': occurredAt.toUtc().toIso8601String(),
    'deltaMinor': deltaMinor,
  };
}

/// Read-only register projection. The opening and complete event interval come
/// from the same scoped source. This does not infer a cash count or bank balance
/// from sales, payment-method names, settlement requests or partial history.
class WorkspaceMoneyRegisterSnapshot {
  WorkspaceMoneyRegisterSnapshot({
    required this.accountScope,
    required this.workspaceId,
    required this.registerId,
    required this.label,
    required this.revision,
    required this.openingAt,
    required this.asOf,
    required this.historyComplete,
    required List<WorkspaceMoneyRegisterEntry> entries,
    this.openingMinor,
  }) : entries = List.unmodifiable(entries);
  final String accountScope, workspaceId, registerId, label;
  final int revision;
  final DateTime openingAt, asOf;
  final bool historyComplete;
  final int? openingMinor;
  final List<WorkspaceMoneyRegisterEntry> entries;
  bool get valid {
    if ([
          accountScope,
          workspaceId,
          registerId,
          label,
        ].any((v) => v.trim().isEmpty) ||
        revision < 1 ||
        openingAt.isAfter(asOf) ||
        (historyComplete && openingMinor == null) ||
        (openingMinor != null &&
            !_financeAmountValid(openingMinor!, signed: true)) ||
        entries.map((e) => e.id).toSet().length != entries.length) {
      return false;
    }
    var balance = openingMinor ?? 0;
    DateTime? previous;
    for (final entry in entries) {
      if (!entry.valid ||
          entry.occurredAt.isBefore(openingAt) ||
          !entry.occurredAt.isBefore(asOf) ||
          (previous != null && entry.occurredAt.isBefore(previous))) {
        return false;
      }
      balance += entry.deltaMinor;
      if (!_financeAmountValid(balance, signed: true)) {
        return false;
      }
      previous = entry.occurredAt;
    }
    return true;
  }

  /// start is inclusive, end exclusive. A period beyond the supplied source
  /// coverage stays unavailable; an absent opening is never replaced with zero.
  ({int openingMinor, int inMinor, int outMinor, int closingMinor})? balances(
    DateTime start,
    DateTime end,
  ) {
    if (!valid ||
        !historyComplete ||
        start.isBefore(openingAt) ||
        end.isAfter(asOf) ||
        !start.isBefore(end)) {
      return null;
    }
    var opening = openingMinor!, incoming = 0, outgoing = 0;
    for (final entry in entries) {
      if (entry.occurredAt.isBefore(start)) {
        opening += entry.deltaMinor;
      } else if (entry.occurredAt.isBefore(end)) {
        if (entry.deltaMinor > 0) {
          incoming += entry.deltaMinor;
        } else {
          outgoing -= entry.deltaMinor;
        }
      }
    }
    if (!_financeAmountValid(incoming) || !_financeAmountValid(outgoing)) {
      return null;
    }
    return (
      openingMinor: opening,
      inMinor: incoming,
      outMinor: outgoing,
      closingMinor: opening + incoming - outgoing,
    );
  }

  bool canFollow(WorkspaceMoneyRegisterSnapshot old) {
    if (!valid ||
        !old.valid ||
        accountScope != old.accountScope ||
        workspaceId != old.workspaceId ||
        registerId != old.registerId ||
        label != old.label ||
        !openingAt.isAtSameMomentAs(old.openingAt) ||
        (old.openingMinor != null && openingMinor != old.openingMinor) ||
        revision < old.revision ||
        asOf.isBefore(old.asOf) ||
        (old.historyComplete && !historyComplete) ||
        entries.length < old.entries.length) {
      return false;
    }
    for (var i = 0; i < old.entries.length; i++) {
      if (entries[i].identity != old.entries[i].identity) {
        return false;
      }
    }
    if (old.historyComplete &&
        entries
            .skip(old.entries.length)
            .any((entry) => entry.occurredAt.isBefore(old.asOf))) {
      return false;
    }
    return revision > old.revision ||
        (asOf.isAtSameMomentAs(old.asOf) &&
            openingMinor == old.openingMinor &&
            historyComplete == old.historyComplete &&
            entries.length == old.entries.length);
  }

  Map<String, Object?> toJson() => {
    'accountScope': accountScope,
    'workspaceId': workspaceId,
    'registerId': registerId,
    'label': label,
    'revision': revision,
    'openingAt': openingAt.toUtc().toIso8601String(),
    'asOf': asOf.toUtc().toIso8601String(),
    'historyComplete': historyComplete,
    'openingMinor': openingMinor,
    'entries': entries.map((entry) => entry.toJson()).toList(),
  };
  static WorkspaceMoneyRegisterSnapshot? fromJson(Object? value) {
    if (value is! Map) {
      return null;
    }
    try {
      final result = WorkspaceMoneyRegisterSnapshot(
        accountScope: value['accountScope'] as String,
        workspaceId: value['workspaceId'] as String,
        registerId: value['registerId'] as String,
        label: value['label'] as String,
        revision: value['revision'] as int,
        openingAt: DateTime.parse(value['openingAt'] as String),
        asOf: DateTime.parse(value['asOf'] as String),
        historyComplete: value['historyComplete'] as bool,
        openingMinor: value['openingMinor'] as int?,
        entries: [
          for (final entry in value['entries'] as List)
            WorkspaceMoneyRegisterEntry(
              id: entry['id'] as String,
              reference: entry['reference'] as String,
              occurredAt: DateTime.parse(entry['occurredAt'] as String),
              deltaMinor: entry['deltaMinor'] as int,
            ),
        ],
      );
      return result.valid ? result : null;
    } catch (_) {
      return null;
    }
  }
}

class WorkspaceMoneyStatement {
  WorkspaceMoneyStatement._(List<WorkspaceMoneyStatementEntry> entries)
    : entries = List.unmodifiable(entries);
  final List<WorkspaceMoneyStatementEntry> entries;
  int get recordedInMinor => entries
      .where((e) => e.posted && e.incoming && !e.transfer)
      .fold<int>(0, (sum, e) => sum + e.amountMinor);
  int get recordedOutMinor => entries
      .where((e) => e.posted && !e.incoming && !e.transfer)
      .fold<int>(0, (sum, e) => sum + e.amountMinor);

  /// No opening balance is inferred from these possibly partial activity rows.
  /// The source lists must all belong to the same authenticated Store scope.
  static WorkspaceMoneyStatement? fromLedgers({
    required WorkspaceFinanceSnapshot finance,
    required List<WorkspaceSupplierLedger> suppliers,
    required List<WorkspaceExpenseRecord> expenses,
    required DateTime end,
    DateTime? start,
  }) {
    if (!finance.valid ||
        (start != null && start.isAfter(end)) ||
        suppliers.map((s) => s.supplierId).toSet().length != suppliers.length ||
        expenses.map((e) => e.operationId).toSet().length != expenses.length ||
        suppliers.any(
          (s) =>
              !s.valid ||
              s.accountScope != finance.accountScope ||
              s.workspaceId != finance.workspaceId,
        ) ||
        expenses.any(
          (e) =>
              !e.valid ||
              e.accountScope != finance.accountScope ||
              e.workspaceId != finance.workspaceId,
        )) {
      return null;
    }
    final rows = <WorkspaceMoneyStatementEntry>[];
    for (final customer in finance.customerLedgers) {
      for (final entry in customer.entries) {
        if (entry.kind != WorkspaceLedgerEntryKind.collection &&
            entry.kind != WorkspaceLedgerEntryKind.refund) {
          continue;
        }
        final incoming = entry.kind == WorkspaceLedgerEntryKind.collection;
        rows.add(
          WorkspaceMoneyStatementEntry(
            id: jsonEncode(['customer', customer.customerId, entry.id]),
            label: incoming ? 'Customer payment' : 'Customer refund',
            party: customer.customerName,
            reference: '${entry.invoiceId} · ${entry.orderId}',
            method: entry.channel.label,
            occurredAt: entry.occurredAt,
            amountMinor: entry.amountMinor,
            incoming: incoming,
            posted: entry.state == WorkspaceLedgerPostingState.posted,
            status: switch (entry.state) {
              WorkspaceLedgerPostingState.posted => 'Recorded',
              WorkspaceLedgerPostingState.pending => 'Pending confirmation',
              WorkspaceLedgerPostingState.failed => 'Failed',
            },
          ),
        );
      }
    }
    for (final supplier in suppliers) {
      for (final entry in supplier.entries) {
        if (entry.kind == WorkspaceSupplierEntryKind.bill ||
            entry.kind == WorkspaceSupplierEntryKind.creditNote) {
          continue;
        }
        rows.add(
          WorkspaceMoneyStatementEntry(
            id: jsonEncode([
              'supplier',
              supplier.supplierId,
              entry.operationId,
            ]),
            label: switch (entry.kind) {
              WorkspaceSupplierEntryKind.advance => 'Supplier advance',
              WorkspaceSupplierEntryKind.refund => 'Supplier refund',
              _ => 'Supplier payment',
            },
            party: supplier.supplierName,
            reference: entry.origin == WorkspaceSupplierEntryOrigin.moolSocialOrder
                ? '${entry.reference} · ${entry.orderId}'
                : entry.origin == WorkspaceSupplierEntryOrigin.manualPurchase
                ? '${entry.reference} · ${supplier.purchaseBills[entry.billId]?.copy.draft.invoiceReference ?? entry.billId ?? entry.purchaseId}'
                : entry.reference,
            method: entry.paymentMethod ?? 'Payment method unavailable',
            occurredAt: supplier.refunds[entry.operationId] != null
                ? DateTime.parse(supplier.refunds[entry.operationId]!.intent.occurredOn)
                : entry.moneyReview == null ? entry.postedAt
                : DateTime.parse(entry.moneyReview!.occurredOn),
            amountMinor: entry.amountMinor,
            incoming: entry.kind == WorkspaceSupplierEntryKind.refund,
            posted: true,
            status: 'Recorded',
          ),
        );
      }
    }
    for (final expense in expenses) {
      rows.add(
        WorkspaceMoneyStatementEntry(
          id: jsonEncode(['expense', expense.operationId]),
          label: 'Expense',
          party: expense.category,
          reference: expense.reference,
          method: expense.method,
          occurredAt: expense.occurredAt,
          amountMinor: expense.amountMinor,
          incoming: false,
          posted: true,
          status: 'Recorded',
        ),
      );
    }
    for (final payout in finance.payouts) {
      rows.add(
        WorkspaceMoneyStatementEntry(
          id: jsonEncode(['payout', payout.operationId]),
          label: 'Settlement transfer',
          party: payout.bankLabel ?? 'Bank',
          reference: payout.id,
          method: 'MoolSocial to bank',
          occurredAt: payout.updatedAt,
          amountMinor: payout.amountMinor,
          incoming: true,
          posted: payout.state == WorkspacePayoutState.paid,
          transfer: true,
          status: payout.state.label,
        ),
      );
    }
    rows.removeWhere(
      (e) =>
          e.occurredAt.isAfter(end) ||
          (start != null && e.occurredAt.isBefore(start)),
    );
    rows.sort((a, b) {
      final date = b.occurredAt.compareTo(a.occurredAt);
      return date == 0 ? a.id.compareTo(b.id) : date;
    });
    final result = WorkspaceMoneyStatement._(rows);
    return _financeAmountValid(result.recordedInMinor) &&
            _financeAmountValid(result.recordedOutMinor)
        ? result
        : null;
  }
}

/// Device recovery of a validated projection and its one unresolved collection.
/// These retained bytes are a cache, never fresh backend/payment authority.
class WorkspacePendingCustomerReturn {
  WorkspacePendingCustomerReturn({
    required this.request,
    required this.creditMinor,
    List<WorkspaceOrderItemSnapshot> originalItems = const [],
  }) : originalItems = List.unmodifiable(originalItems);
  final WorkspaceCustomerReturn request;
  final int creditMinor;
  final List<WorkspaceOrderItemSnapshot> originalItems;
  bool get valid =>
      request.valid &&
      creditMinor > 0 &&
      _financeAmountValid(creditMinor) &&
      (originalItems.isEmpty ||
          (originalItems.map((item) => item.productId).toSet().length ==
                  originalItems.length &&
              originalItems.every(
                (item) =>
                    item.productId.trim().isNotEmpty &&
                    item.name.trim().isNotEmpty &&
                    item.pack.trim().isNotEmpty &&
                    item.quantity > 0 &&
                    _financeAmountValid(item.unitPricePaise) &&
                    _financeAmountValid(item.lineTotalPaise),
              ) &&
              request.lines.every(
                (line) => originalItems.any(
                  (item) =>
                      item.productId == line.productId &&
                      item.quantity >= line.quantity,
                ),
              )));
  Map<String, Object?> toJson() => {
    'request': request.toJson(),
    'creditMinor': creditMinor,
    if (originalItems.isNotEmpty)
      'originalItems': [
        for (final item in originalItems)
          {
            'productId': item.productId,
            'name': item.name,
            'pack': item.pack,
            'quantity': item.quantity,
            'unitPricePaise': item.unitPricePaise,
            'lineTotalPaise': item.lineTotalPaise,
          },
      ],
  };
  factory WorkspacePendingCustomerReturn.fromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Pending return is missing.');
    }
    final result = WorkspacePendingCustomerReturn(
      request: WorkspaceCustomerReturn.fromJson(value['request']),
      creditMinor: value['creditMinor'] as int,
      originalItems: [
        for (final item in (value['originalItems'] as List? ?? const []))
          WorkspaceOrderItemSnapshot(
            productId: item['productId'] as String,
            name: item['name'] as String,
            pack: item['pack'] as String,
            quantity: item['quantity'] as int,
            unitPricePaise: item['unitPricePaise'] as int,
            lineTotalPaise: item['lineTotalPaise'] as int,
          ),
      ],
    );
    if (!result.valid) {
      throw const FormatException('Pending return is invalid.');
    }
    return result;
  }
}

/// One recorded business expense, separate from purchases and settlements.
class WorkspaceExpenseRecord {
  const WorkspaceExpenseRecord({
    required this.accountScope,
    required this.workspaceId,
    required this.operationId,
    required this.amountMinor,
    required this.category,
    required this.method,
    required this.reference,
    required this.note,
    required this.occurredAt,
  });
  final String accountScope,
      workspaceId,
      operationId,
      category,
      method,
      reference,
      note;
  final int amountMinor;
  final DateTime occurredAt;
  bool get valid =>
      [
        accountScope,
        workspaceId,
        operationId,
        category,
        method,
        reference,
      ].every((value) => value.trim().isNotEmpty && value.length <= 512) &&
      amountMinor > 0 &&
      _financeAmountValid(amountMinor) &&
      note.length <= 2000;
  Map<String, Object?> toJson() => {
    'account': accountScope,
    'store': workspaceId,
    'operationId': operationId,
    'amountMinor': amountMinor,
    'category': category,
    'method': method,
    'reference': reference,
    'note': note,
    'occurredAt': occurredAt.toUtc().toIso8601String(),
  };
  static WorkspaceExpenseRecord? fromJson(Object? value) {
    if (value is! Map) {
      return null;
    }
    try {
      final record = WorkspaceExpenseRecord(
        accountScope: value['account'] as String,
        workspaceId: value['store'] as String,
        operationId: value['operationId'] as String,
        amountMinor: value['amountMinor'] as int,
        category: value['category'] as String,
        method: value['method'] as String,
        reference: value['reference'] as String,
        note: value['note'] as String,
        occurredAt: DateTime.parse(value['occurredAt'] as String),
      );
      return record.valid ? record : null;
    } catch (_) {
      return null;
    }
  }
}

class WorkspaceLedgerCheckpoint {
  const WorkspaceLedgerCheckpoint({
    required this.revision,
    required this.finance,
    this.pending,
    this.pendingReturn,
    this.pendingRefund,
    this.inventory,
    this.billedOrders = const {},
    this.billedInvoices = const {},
    this.supplierLedgers = const {},
    this.expenses = const {},
    this.moneyRegisters = const {},
    this.purchaseReceipts = const {},
  });
  final int revision;
  final WorkspaceFinanceSnapshot finance;
  final WorkspaceInventoryLedger? inventory;
  final Map<String, WorkspaceOrderRecord> billedOrders;
  final Map<String, WorkspaceCustomerInvoice> billedInvoices;
  final Map<String, WorkspaceSupplierLedger> supplierLedgers;
  final Map<String, WorkspaceExpenseRecord> expenses;
  final Map<String, WorkspaceMoneyRegisterSnapshot> moneyRegisters;
  final Map<String, WorkspaceConfirmedPurchaseReceipt> purchaseReceipts;
  final WorkspaceCustomerCollection? pending;
  final WorkspacePendingCustomerReturn? pendingReturn;
  final WorkspaceCustomerRefund? pendingRefund;
  bool get valid =>
      revision > 0 &&
      finance.valid &&
      purchaseReceipts.entries.every(
        (entry) =>
            entry.key == entry.value.shipmentId &&
            entry.value.valid &&
            entry.value.accountScope == finance.accountScope &&
            entry.value.workspaceId == finance.workspaceId,
      ) &&
      moneyRegisters.entries.every(
        (entry) =>
            entry.key == entry.value.registerId &&
            entry.value.valid &&
            entry.value.accountScope == finance.accountScope &&
            entry.value.workspaceId == finance.workspaceId,
      ) &&
      expenses.entries.every(
        (entry) =>
            entry.key == entry.value.operationId &&
            entry.value.valid &&
            entry.value.accountScope == finance.accountScope &&
            entry.value.workspaceId == finance.workspaceId,
      ) &&
      supplierLedgers.entries.every(
        (entry) =>
            entry.key == entry.value.supplierId &&
            entry.value.valid &&
            entry.value.accountScope == finance.accountScope &&
            entry.value.workspaceId == finance.workspaceId,
      ) &&
      supplierLedgers.values.expand((ledger) => ledger.purchaseBills.keys).toSet().length ==
          supplierLedgers.values.fold<int>(0, (count, ledger) => count + ledger.purchaseBills.length) &&
      supplierLedgers.values.expand((ledger) => ledger.billGoodsAllocations.keys).toSet().length ==
          supplierLedgers.values.fold<int>(0, (count, ledger) => count + ledger.billGoodsAllocations.length) &&
      supplierLedgers.values.expand((ledger) => ledger.billMoneyAllocations.keys).toSet().length ==
          supplierLedgers.values.fold<int>(0, (count, ledger) => count + ledger.billMoneyAllocations.length) &&
      supplierLedgers.values.expand((ledger) => ledger.goodsReturns.keys).toSet().length ==
          supplierLedgers.values.fold<int>(0, (count, ledger) => count + ledger.goodsReturns.length) &&
      _manualGoodsReceiptsValid &&
      billedInvoices.length == billedOrders.length &&
      billedInvoices.entries.every(
        (entry) =>
            entry.key == entry.value.id &&
            entry.value.validBillAmounts &&
            billedOrders[entry.key]?.id == entry.value.orderId &&
            billedOrders[entry.key]?.payableMinor == entry.value.payableMinor &&
            billedOrders[entry.key]?.discountMinor ==
                entry.value.discountMinor &&
            billedOrders[entry.key]?.discount.kind ==
                entry.value.discount.kind &&
            billedOrders[entry.key]?.discount.value ==
                entry.value.discount.value,
      ) &&
      billedOrders.entries.every(
        (entry) =>
            entry.key.trim().isNotEmpty &&
            WorkspaceOrderRecord.fromLedgerJson(entry.value.toLedgerJson()) !=
                null &&
            finance.payments.any(
              (payment) =>
                  payment.invoiceId == entry.key &&
                  payment.orderId == entry.value.id &&
                  payment.amountMinor == entry.value.payableMinor,
            ) &&
            finance.customerLedgers.any(
              (ledger) => ledger.entries.any(
                (line) =>
                    line.invoiceId == entry.key &&
                    line.orderId == entry.value.id &&
                    line.kind == WorkspaceLedgerEntryKind.invoice &&
                    line.state == WorkspaceLedgerPostingState.posted &&
                    line.amountMinor == entry.value.payableMinor,
              ),
            ),
      ) &&
      (inventory == null ||
          (inventory!.valid &&
              inventory!.accountScope == finance.accountScope &&
              inventory!.workspaceId == finance.workspaceId)) &&
      [
            pending,
            pendingReturn,
            pendingRefund,
          ].where((item) => item != null).length <=
          1 &&
      (pendingReturn == null || _validPendingReturn()) &&
      (pendingRefund == null || _validPendingRefund()) &&
      (pending == null ||
          (pending!.valid &&
              pending!.accountScope == finance.accountScope &&
              pending!.workspaceId == finance.workspaceId &&
              finance.customerLedgers.any(
                (ledger) =>
                    ledger.customerId == pending!.customerId &&
                    ledger.historyComplete &&
                    ledger.revision == pending!.expectedRevision,
              ) &&
              finance.payments.any(
                (payment) =>
                    payment.customerId == pending!.customerId &&
                    payment.invoiceId == pending!.invoiceId &&
                    payment.orderId == pending!.orderId &&
                    payment.dueMinor >= pending!.amountMinor,
              ) &&
              !finance.customerLedgers
                  .expand((ledger) => ledger.entries)
                  .any((entry) => entry.operationId == pending!.operationId)));

  bool get _manualGoodsReceiptsValid {
    final receiptIds = <String>{};
    final groupSuppliers = <String, String>{};
    final movements = {for (final movement in inventory?.movements ?? const <WorkspaceStockMovement>[])
      movement.id: movement};
    final ownedMovements = <String, WorkspaceStockMovement>{};
    final reservations = <String, int>{};
    for (final ledger in supplierLedgers.values) {
      for (final receipt in ledger.goodsReceipts.values) {
        if (!receiptIds.add(receipt.id)) {
          return false;
        }
        final supplier = groupSuppliers[receipt.expectedDeliveryId];
        if (supplier != null && supplier != ledger.supplierId) {
          return false;
        }
        groupSuppliers[receipt.expectedDeliveryId] = ledger.supplierId;
        for (final line in receipt.lines) {
          final addition = receipt.movementFor(line);
          if (addition != null) {
            if (ownedMovements.containsKey(addition.id) ||
                movements[addition.id]?.contentIdentity != addition.contentIdentity) {
              return false;
            }
            ownedMovements[addition.id] = addition;
          }
          for (final entry in line.priorStockUnits.entries) {
            final original = movements[entry.key];
            // Only unassigned original stock evidence can be linked. A platform
            // or manual receipt's movement already has an owner and is ineligible.
            if (original == null || original.productId != line.productId ||
                original.referenceKind != null || original.referenceId != null ||
                !{WorkspaceStockMovementKind.openingStock,
                  WorkspaceStockMovementKind.goodsReceived}.contains(original.kind) ||
                original.quantityDelta <= 0 || original.occurredAt.isAfter(receipt.recordedAt)) {
              return false;
            }
            final reserved = (reservations[entry.key] ?? 0) + entry.value;
            if (reserved > original.quantityDelta) {
              return false;
            }
            reservations[entry.key] = reserved;
          }
        }
      }
    }
    for (final ledger in supplierLedgers.values) {
      for (final returned in ledger.goodsReturns.values) {
        for (final line in returned.lines) {
          final removal = returned.movementFor(line);
          if (removal != null) {
            if (ownedMovements.containsKey(removal.id) ||
                movements[removal.id]?.contentIdentity != removal.contentIdentity) {
              return false;
            }
            ownedMovements[removal.id] = removal;
          }
        }
      }
    }
    // Reverse ownership is required too: an orphan manual receipt/return movement
    // cannot be smuggled into Stock without its immutable receipt evidence.
    return movements.values.where((movement) =>
      movement.referenceKind == WorkspaceStockReferenceKind.manualSupplierReceipt ||
      movement.referenceKind == WorkspaceStockReferenceKind.manualSupplierReturn)
      .every((movement) => ownedMovements[movement.id]?.contentIdentity == movement.contentIdentity);
  }

  bool _validPendingRefund() {
    final request = pendingRefund!;
    final ledger = finance.customerLedgers
        .where((item) => item.customerId == request.customerId)
        .firstOrNull;
    final balance = ledger?.invoiceBalance(request.invoiceId);
    return request.valid &&
        request.accountScope == finance.accountScope &&
        request.workspaceId == finance.workspaceId &&
        ledger?.revision == request.expectedRevision &&
        balance != null &&
        request.amountMinor <= balance.refundableMinor &&
        ledger!.permitsReceiptRefund(request) &&
        finance.payments.any(
          (payment) =>
              payment.customerId == request.customerId &&
              payment.invoiceId == request.invoiceId &&
              payment.orderId == request.orderId &&
              payment.paidMinor - payment.refundedMinor >= request.amountMinor,
        ) &&
        !finance.customerLedgers
            .expand((item) => item.entries)
            .any((entry) => entry.operationId == request.operationId);
  }

  bool _validPendingReturn() {
    final pending = pendingReturn!;
    final request = pending.request;
    final ledger = finance.customerLedgers
        .where((item) => item.customerId == request.customerId)
        .firstOrNull;
    final balance = ledger?.invoiceBalance(request.invoiceId);
    return pending.valid &&
        request.accountScope == finance.accountScope &&
        request.workspaceId == finance.workspaceId &&
        ledger?.revision == request.expectedRevision &&
        balance != null &&
        pending.creditMinor <= balance.billedMinor - balance.creditedMinor &&
        finance.payments.any(
          (payment) =>
              payment.customerId == request.customerId &&
              payment.invoiceId == request.invoiceId &&
              payment.orderId == request.orderId,
        ) &&
        !finance.customerLedgers
            .expand((item) => item.entries)
            .any((entry) => entry.operationId == request.operationId);
  }

  Map<String, Object?> toJson() => {
    'version': 1,
    if (inventory != null) 'inventory': inventory!.toJson(),
    if (purchaseReceipts.isNotEmpty)
      'purchaseReceipts': purchaseReceipts.map(
        (id, receipt) => MapEntry(id, receipt.toJson()),
      ),
    if (expenses.isNotEmpty)
      'expenses': expenses.map((id, expense) => MapEntry(id, expense.toJson())),
    if (moneyRegisters.isNotEmpty)
      'moneyRegisters': moneyRegisters.map(
        (id, register) => MapEntry(id, register.toJson()),
      ),
    if (supplierLedgers.isNotEmpty)
      'supplierLedgers': supplierLedgers.map(
        (id, ledger) => MapEntry(id, ledger.toJson()),
      ),
    if (billedOrders.isNotEmpty)
      'billedOrders': {
        for (final entry in billedOrders.entries)
          entry.key: entry.value.toLedgerJson(),
      },
    if (billedInvoices.isNotEmpty)
      'billedInvoices': {
        for (final entry in billedInvoices.entries)
          entry.key: entry.value.toLedgerJson(),
      },
    if (pendingReturn != null) 'pendingReturn': pendingReturn!.toJson(),
    if (pendingRefund != null) 'pendingRefund': pendingRefund!.toJson(),
    'revision': revision,
    'finance': {
      'accountScope': finance.accountScope,
      'workspaceId': finance.workspaceId,
      'revision': finance.revision,
      'asOf': finance.asOf.toUtc().toIso8601String(),
      'salesTodayMinor': finance.salesTodayMinor,
      'duesMinor': finance.duesMinor,
      'availableMinor': finance.availableMinor,
      'heldMinor': finance.heldMinor,
      'requestedMinor': finance.requestedMinor,
      'paidOutMinor': finance.paidOutMinor,
      'feesMinor': finance.feesMinor,
      'deliveryAdjustmentsMinor': finance.deliveryAdjustmentsMinor,
      'refundsMinor': finance.refundsMinor,
      'taxWithheldMinor': finance.taxWithheldMinor,
      'historyComplete': finance.historyComplete,
      'payments': [
        for (final p in finance.payments)
          {
            'orderId': p.orderId,
            'customerId': p.customerId,
            'customerName': p.customerName,
            'revision': p.revision,
            'updatedAt': p.updatedAt.toUtc().toIso8601String(),
            'amountMinor': p.amountMinor,
            'paidMinor': p.paidMinor,
            'dueMinor': p.dueMinor,
            'refundedMinor': p.refundedMinor,
            'state': p.state.name,
            'channel': p.channel.name,
            'invoiceId': p.invoiceId,
            'transactionId': p.transactionId,
          },
      ],
      'payouts': [
        for (final p in finance.payouts)
          {
            'id': p.id,
            'operationId': p.operationId,
            'revision': p.revision,
            'amountMinor': p.amountMinor,
            'updatedAt': p.updatedAt.toUtc().toIso8601String(),
            'state': p.state.name,
            'bankLabel': p.bankLabel,
            'expectedBy': p.expectedBy,
            'message': p.message,
          },
      ],
      'customerLedgers': [
        for (final l in finance.customerLedgers)
          {
            'accountScope': l.accountScope,
            'workspaceId': l.workspaceId,
            'customerId': l.customerId,
            'customerName': l.customerName,
            'revision': l.revision,
            'asOf': l.asOf.toUtc().toIso8601String(),
            'openingBalanceMinor': l.openingBalanceMinor,
            'historyComplete': l.historyComplete,
            'entries': [
              for (final e in l.entries)
                {
                  'id': e.id,
                  'operationId': e.operationId,
                  'invoiceId': e.invoiceId,
                  'orderId': e.orderId,
                  'sequence': e.sequence,
                  'occurredAt': e.occurredAt.toUtc().toIso8601String(),
                  'kind': e.kind.name,
                  'state': e.state.name,
                  'amountMinor': e.amountMinor,
                  'channel': e.channel.name,
                  'paymentReference': e.paymentReference,
                  if (e.customerRefund != null)
                    'customerRefund': e.customerRefund!.toJson(),
                  if (e.customerReturn != null)
                    'customerReturn': e.customerReturn!.toJson(),
                },
            ],
          },
      ],
    },
    'pending': pending == null
        ? null
        : {
            'accountScope': pending!.accountScope,
            'workspaceId': pending!.workspaceId,
            'customerId': pending!.customerId,
            'invoiceId': pending!.invoiceId,
            'orderId': pending!.orderId,
            'operationId': pending!.operationId,
            'expectedRevision': pending!.expectedRevision,
            'amountMinor': pending!.amountMinor,
            'channel': pending!.channel.name,
            'reference': pending!.reference,
          },
  };

  static WorkspaceLedgerCheckpoint? fromJson(Object? value) {
    try {
      final root = value as Map;
      if (root['version'] is! int || root['version'] != 1) return null;
      final f = root['finance'] as Map;
      final pending = root['pending'] as Map?;
      final result = WorkspaceLedgerCheckpoint(
        revision: root['revision'] as int,
        purchaseReceipts: Map.unmodifiable({
          for (final entry
              in ((root['purchaseReceipts'] as Map?) ?? const {}).entries)
            entry.key as String: WorkspaceConfirmedPurchaseReceipt.fromJson(
              entry.value,
            )!,
        }),
        moneyRegisters: Map.unmodifiable({
          for (final entry
              in ((root['moneyRegisters'] as Map?) ?? const {}).entries)
            entry.key as String:
                WorkspaceMoneyRegisterSnapshot.fromJson(entry.value) ??
                (throw const FormatException('Invalid money register')),
        }),
        expenses: Map.unmodifiable({
          for (final entry in ((root['expenses'] as Map?) ?? const {}).entries)
            entry.key as String: WorkspaceExpenseRecord.fromJson(entry.value)!,
        }),
        supplierLedgers: Map.unmodifiable({
          for (final entry
              in ((root['supplierLedgers'] as Map?) ?? const {}).entries)
            entry.key as String: WorkspaceSupplierLedger.fromJson(entry.value)!,
        }),
        billedOrders: Map.unmodifiable({
          for (final entry
              in ((root['billedOrders'] as Map?) ?? const {}).entries)
            entry.key as String: WorkspaceOrderRecord.fromLedgerJson(
              entry.value,
            )!,
        }),
        billedInvoices: Map.unmodifiable({
          for (final entry
              in ((root['billedInvoices'] as Map?) ?? const {}).entries)
            entry.key as String: WorkspaceCustomerInvoice.fromLedgerJson(
              entry.value,
            ),
        }),
        pendingRefund: root.containsKey('pendingRefund')
            ? WorkspaceCustomerRefund.fromJson(root['pendingRefund'])
            : null,
        inventory: root.containsKey('inventory')
            ? WorkspaceInventoryLedger.fromJson(root['inventory'])
            : null,
        pendingReturn: root.containsKey('pendingReturn')
            ? WorkspacePendingCustomerReturn.fromJson(root['pendingReturn'])
            : null,
        pending: pending == null
            ? null
            : WorkspaceCustomerCollection(
                accountScope: pending['accountScope'] as String,
                workspaceId: pending['workspaceId'] as String,
                customerId: pending['customerId'] as String,
                invoiceId: pending['invoiceId'] as String,
                orderId: pending['orderId'] as String,
                operationId: pending['operationId'] as String,
                expectedRevision: pending['expectedRevision'] as int,
                amountMinor: pending['amountMinor'] as int,
                channel: WorkspacePaymentChannel.values.byName(
                  pending['channel'] as String,
                ),
                reference: pending['reference'] as String?,
              ),
        finance: WorkspaceFinanceSnapshot(
          accountScope: f['accountScope'] as String,
          workspaceId: f['workspaceId'] as String,
          revision: f['revision'] as int,
          asOf: DateTime.parse(f['asOf'] as String),
          salesTodayMinor: f['salesTodayMinor'] as int,
          duesMinor: f['duesMinor'] as int,
          availableMinor: f['availableMinor'] as int,
          heldMinor: f['heldMinor'] as int,
          requestedMinor: f['requestedMinor'] as int,
          paidOutMinor: f['paidOutMinor'] as int,
          feesMinor: f['feesMinor'] as int,
          deliveryAdjustmentsMinor: f['deliveryAdjustmentsMinor'] as int,
          refundsMinor: f['refundsMinor'] as int,
          taxWithheldMinor: f['taxWithheldMinor'] as int,
          historyComplete: f['historyComplete'] as bool,
          payments: [
            for (final p in f['payments'] as List)
              WorkspacePaymentRecord(
                orderId: p['orderId'] as String,
                customerId: p['customerId'] as String,
                customerName: p['customerName'] as String,
                revision: p['revision'] as int,
                updatedAt: DateTime.parse(p['updatedAt'] as String),
                amountMinor: p['amountMinor'] as int,
                paidMinor: p['paidMinor'] as int,
                dueMinor: p['dueMinor'] as int,
                refundedMinor: p['refundedMinor'] as int,
                state: WorkspacePaymentState.values.byName(
                  p['state'] as String,
                ),
                channel: WorkspacePaymentChannel.values.byName(
                  p['channel'] as String,
                ),
                invoiceId: p['invoiceId'] as String?,
                transactionId: p['transactionId'] as String?,
              ),
          ],
          payouts: [
            for (final p in f['payouts'] as List)
              WorkspacePayoutRecord(
                id: p['id'] as String,
                operationId: p['operationId'] as String,
                revision: p['revision'] as int,
                amountMinor: p['amountMinor'] as int,
                updatedAt: DateTime.parse(p['updatedAt'] as String),
                state: WorkspacePayoutState.values.byName(p['state'] as String),
                bankLabel: p['bankLabel'] as String?,
                expectedBy: p['expectedBy'] as String?,
                message: p['message'] as String?,
              ),
          ],
          customerLedgers: [
            for (final l in f['customerLedgers'] as List)
              WorkspaceCustomerLedger(
                accountScope: l['accountScope'] as String,
                workspaceId: l['workspaceId'] as String,
                customerId: l['customerId'] as String,
                customerName: l['customerName'] as String,
                revision: l['revision'] as int,
                asOf: DateTime.parse(l['asOf'] as String),
                openingBalanceMinor: l['openingBalanceMinor'] as int?,
                historyComplete: l['historyComplete'] as bool,
                entries: [
                  for (final e in l['entries'] as List)
                    WorkspaceCustomerLedgerEntry(
                      id: e['id'] as String,
                      operationId: e['operationId'] as String,
                      invoiceId: e['invoiceId'] as String,
                      orderId: e['orderId'] as String,
                      sequence: e['sequence'] as int,
                      occurredAt: DateTime.parse(e['occurredAt'] as String),
                      kind: WorkspaceLedgerEntryKind.values.byName(
                        e['kind'] as String,
                      ),
                      state: WorkspaceLedgerPostingState.values.byName(
                        e['state'] as String,
                      ),
                      amountMinor: e['amountMinor'] as int,
                      channel: WorkspacePaymentChannel.values.byName(
                        e['channel'] as String,
                      ),
                      paymentReference: e['paymentReference'] as String?,
                      customerRefund: e.containsKey('customerRefund')
                          ? WorkspaceCustomerRefund.fromJson(
                              e['customerRefund'],
                            )
                          : null,
                      customerReturn: e.containsKey('customerReturn')
                          ? WorkspaceCustomerReturn.fromJson(
                              e['customerReturn'],
                            )
                          : null,
                    ),
                ],
              ),
          ],
        ),
      );
      return result.valid ? result : null;
    } on Object {
      return null; // Corrupt/unknown data is not an empty, editable statement.
    }
  }
}

enum WorkspaceSupplyStage {
  ordered,
  confirmed,
  dispatched,
  arriving,
  delivered,
  delayed,
  cancelled,
  returned,
  unknown;

  String get label => switch (this) {
    ordered => 'Order placed',
    confirmed => 'Supplier confirmed',
    dispatched => 'Dispatched',
    arriving => 'Arriving',
    delivered => 'Delivered',
    delayed => 'Delivery delayed',
    cancelled => 'Cancelled',
    returned => 'Returned',
    unknown => 'Awaiting shipment update',
  };
  bool get incoming => !{delivered, cancelled, returned}.contains(this);
}

enum WorkspaceReceiptState {
  unavailable,
  awaiting,
  partial,
  confirmed,
  disputed;

  String get label => switch (this) {
    unavailable => 'Receipt update unavailable',
    awaiting => 'Receipt awaiting confirmation',
    partial => 'Part received',
    confirmed => 'Receipt confirmed',
    disputed => 'Receipt under review',
  };
}

typedef WorkspaceReceiptDraftKey = ({
  String account,
  String store,
  String shipment,
});

enum WorkspaceReceiptProblem {
  missing,
  damaged,
  wrongItem,
  wrongPack,
  extra,
  other;

  String get label => switch (this) {
    missing => 'Missing packs',
    damaged => 'Damaged packs',
    wrongItem => 'Wrong item',
    wrongPack => 'Wrong pack size',
    extra => 'Extra packs',
    other => 'Other issue',
  };
}

/// Device-local observations, not an accepted receipt or a stock movement.
/// Retain the original shipment revision and purchased lines; refreshed supplier
/// facts must never silently rebase what the retailer actually checked.
class WorkspaceReceiptDraft {
  WorkspaceReceiptDraft({
    required this.key,
    required this.supplierId,
    required this.orderId,
    required this.shipmentRevision,
    required this.revision,
    required List<WorkspacePurchaseLine> lines,
    required Map<String, String> countedPacks,
    required Map<String, WorkspaceReceiptProblem> problems,
    Map<String, String> returnedPacks = const {},
    this.purchaseId,
    this.note = '',
  }) : lines = List.unmodifiable(lines),
       countedPacks = Map.unmodifiable(countedPacks),
       returnedPacks = Map.unmodifiable(returnedPacks),
       problems = Map.unmodifiable(problems);

  final WorkspaceReceiptDraftKey key;
  final String supplierId, orderId;
  final String? purchaseId;
  final int shipmentRevision, revision;
  final List<WorkspacePurchaseLine> lines;
  // Preserve incomplete/invalid typed values for correction after relaunch.
  // Empty is unknown, never an inferred zero or the ordered quantity.
  final Map<String, String> countedPacks;
  final Map<String, String> returnedPacks;
  final Map<String, WorkspaceReceiptProblem> problems;
  final String note;

  WorkspaceReceiptDraft edit({
    required int revision,
    required Map<String, String> countedPacks,
    required Map<String, WorkspaceReceiptProblem> problems,
    required String note,
    Map<String, String>? returnedPacks,
  }) => WorkspaceReceiptDraft(
    key: key,
    supplierId: supplierId,
    orderId: orderId,
    purchaseId: purchaseId,
    shipmentRevision: shipmentRevision,
    revision: revision,
    lines: lines,
    countedPacks: countedPacks,
    returnedPacks: returnedPacks ?? this.returnedPacks,
    problems: problems,
    note: note,
  );

  bool get valid =>
      [
        key.account,
        key.store,
        key.shipment,
        supplierId,
        orderId,
      ].every((value) => value.trim().isNotEmpty) &&
      (purchaseId == null || purchaseId!.trim().isNotEmpty) &&
      shipmentRevision > 0 &&
      revision > 0 &&
      lines.isNotEmpty &&
      lines.every((line) => line.valid) &&
      lines.map((line) => line.id).toSet().length == lines.length &&
      countedPacks.keys.every((id) => lines.any((line) => line.id == id)) &&
      returnedPacks.keys.every((id) => lines.any((line) => line.id == id)) &&
      problems.keys.every((id) => lines.any((line) => line.id == id)) &&
      WorkspaceIssueDraft.acceptsNote(note);

  int? counted(String lineId) {
    final text = countedPacks[lineId]?.trim() ?? '';
    if (!RegExp(r'^\d+$').hasMatch(text)) return null;
    final number = int.tryParse(text);
    return number != null && number >= 0 ? number : null;
  }

  bool get quantitiesComplete =>
      valid && lines.every((line) => counted(line.id) != null);

  bool belongsTo(WorkspacePurchaseRecord record) =>
      key.account == record.accountScope &&
      key.store == record.workspaceId &&
      key.shipment == record.shipmentId &&
      supplierId == record.supplierId &&
      orderId == record.orderId &&
      purchaseId == record.purchaseId;

  bool matchesSnapshot(WorkspacePurchaseRecord record) =>
      belongsTo(record) &&
      shipmentRevision == record.revision &&
      jsonEncode(lines.map(_lineJson).toList()) ==
          jsonEncode(record.lines.map(_lineJson).toList());

  bool matchesPurchasedItems(WorkspacePurchaseRecord record) =>
      belongsTo(record) &&
      jsonEncode(
            lines
                .map((line) => _lineJson(line)..remove('receivedPacks'))
                .toList(),
          ) ==
          jsonEncode(
            record.lines
                .map((line) => _lineJson(line)..remove('receivedPacks'))
                .toList(),
          );

  static Map<String, Object?> _lineJson(WorkspacePurchaseLine line) => {
    'id': line.id,
    'productId': line.productId,
    'name': line.name,
    'pack': line.pack,
    'orderedPacks': line.orderedPacks,
    'unitPriceMinor': line.unitPriceMinor,
    'receivedPacks': line.receivedPacks,
  };

  Map<String, Object?> toJson() => {
    'schema': 1,
    'account': key.account,
    'store': key.store,
    'shipment': key.shipment,
    'supplierId': supplierId,
    'orderId': orderId,
    'purchaseId': purchaseId,
    'shipmentRevision': shipmentRevision,
    'revision': revision,
    'lines': lines.map(_lineJson).toList(),
    'countedPacks': countedPacks,
    if (returnedPacks.isNotEmpty) 'returnedPacks': returnedPacks,
    'problems': problems.map((id, value) => MapEntry(id, value.name)),
    'note': note,
  };

  static WorkspaceReceiptDraft? fromJson(Object? value) {
    if (value is! Map ||
        value['schema'] != 1 ||
        value['account'] is! String ||
        value['store'] is! String ||
        value['shipment'] is! String ||
        value['supplierId'] is! String ||
        value['orderId'] is! String ||
        value['shipmentRevision'] is! int ||
        value['revision'] is! int ||
        value['lines'] is! List ||
        value['countedPacks'] is! Map ||
        value['problems'] is! Map ||
        value['note'] is! String ||
        (value['purchaseId'] != null && value['purchaseId'] is! String)) {
      return null;
    }
    final lines = <WorkspacePurchaseLine>[];
    for (final raw in value['lines'] as List) {
      if (raw is! Map ||
          raw['id'] is! String ||
          raw['productId'] is! String ||
          raw['name'] is! String ||
          raw['pack'] is! String ||
          raw['orderedPacks'] is! int ||
          raw['unitPriceMinor'] is! int ||
          (raw['receivedPacks'] != null && raw['receivedPacks'] is! int)) {
        return null;
      }
      lines.add(
        WorkspacePurchaseLine(
          id: raw['id'] as String,
          productId: raw['productId'] as String,
          name: raw['name'] as String,
          pack: raw['pack'] as String,
          orderedPacks: raw['orderedPacks'] as int,
          unitPriceMinor: raw['unitPriceMinor'] as int,
          receivedPacks: raw['receivedPacks'] as int?,
        ),
      );
    }
    final counts = <String, String>{};
    for (final entry in (value['countedPacks'] as Map).entries) {
      if (entry.key is! String || entry.value is! String) return null;
      counts[entry.key as String] = entry.value as String;
    }
    final problems = <String, WorkspaceReceiptProblem>{};
    final returns = <String, String>{};
    final rawReturns = value['returnedPacks'];
    if (rawReturns != null) {
      if (rawReturns is! Map) {
        return null;
      }
      for (final entry in rawReturns.entries) {
        if (entry.key is! String || entry.value is! String) {
          return null;
        }
        returns[entry.key as String] = entry.value as String;
      }
    }
    for (final entry in (value['problems'] as Map).entries) {
      if (entry.key is! String || entry.value is! String) return null;
      final matches = WorkspaceReceiptProblem.values.where(
        (problem) => problem.name == entry.value,
      );
      if (matches.length != 1) return null;
      problems[entry.key as String] = matches.single;
    }
    final draft = WorkspaceReceiptDraft(
      key: (
        account: value['account'] as String,
        store: value['store'] as String,
        shipment: value['shipment'] as String,
      ),
      supplierId: value['supplierId'] as String,
      orderId: value['orderId'] as String,
      purchaseId: value['purchaseId'] as String?,
      shipmentRevision: value['shipmentRevision'] as int,
      revision: value['revision'] as int,
      lines: lines,
      countedPacks: counts,
      returnedPacks: returns,
      problems: problems,
      note: value['note'] as String,
    );
    return draft.valid ? draft : null;
  }
}

enum WorkspaceSupplierEntryKind { bill, advance, payment, creditNote, refund }

/// The document that authorizes a supplier accounting fact. A manual bill or
/// supplier advance must never manufacture a MoolSocial order identity.
enum WorkspaceSupplierEntryOrigin {
  moolSocialOrder,
  manualPurchase,
  supplierAccount,
}

/// Retailer-reviewed occurrence date and exact opening evidence. A payment
/// already represented in the starting balance must not be posted again.
class WorkspaceSupplierMoneyReview {
  const WorkspaceSupplierMoneyReview({required this.occurredOn,
    required this.openingId, required this.openingRevision,
    required this.notIncludedInOpening});

  final String occurredOn, openingId;
  final int openingRevision;
  final bool notIncludedInOpening;

  DateTime? get day {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(occurredOn)) return null;
    final parsed = DateTime.tryParse(occurredOn);
    if (parsed == null || parsed.toIso8601String().substring(0, 10) != occurredOn) {
      return null;
    }
    return DateTime.utc(parsed.year, parsed.month, parsed.day);
  }

  bool get valid => day != null && openingId.trim().isNotEmpty &&
      openingId.length <= 240 && openingRevision > 0 && notIncludedInOpening;

  Map<String, Object?> toJson() => {'occurredOn': occurredOn,
    'openingId': openingId, 'openingRevision': openingRevision,
    'notIncludedInOpening': notIncludedInOpening};

  static WorkspaceSupplierMoneyReview fromJson(Object? raw) {
    const keys = {'occurredOn', 'openingId', 'openingRevision',
      'notIncludedInOpening'};
    if (raw is! Map || raw.length != keys.length || !raw.keys.every(keys.contains)) {
      throw const FormatException('Invalid supplier money review');
    }
    final review = WorkspaceSupplierMoneyReview(
      occurredOn: raw['occurredOn'] as String,
      openingId: raw['openingId'] as String,
      openingRevision: raw['openingRevision'] as int,
      notIncludedInOpening: raw['notIncludedInOpening'] as bool);
    if (!review.valid) throw const FormatException('Invalid supplier money review');
    return review;
  }
}

/// Confirmed supplier money facts. Orders and receipts are deliberately not
/// financial entries; receiving a shipment cannot create another bill/payment.
class WorkspaceSupplierLedgerEntry {
  const WorkspaceSupplierLedgerEntry({
    required this.operationId,
    required this.reference,
    required this.kind,
    required this.amountMinor,
    required this.postedAt,
    this.orderId,
    this.purchaseId,
    this.origin = WorkspaceSupplierEntryOrigin.moolSocialOrder,
    this.billId,
    this.paymentMethod,
    this.moneyReview,
  });

  final String operationId, reference;
  final String? orderId, purchaseId, billId, paymentMethod;
  final WorkspaceSupplierEntryOrigin origin;
  final WorkspaceSupplierEntryKind kind;
  final int amountMinor;
  final DateTime postedAt;
  final WorkspaceSupplierMoneyReview? moneyReview;

  bool get valid =>
      [operationId, reference].every((value) => value.trim().isNotEmpty) &&
      _validOrigin &&
      (moneyReview == null || (moneyReview!.valid &&
        origin != WorkspaceSupplierEntryOrigin.moolSocialOrder &&
        (kind == WorkspaceSupplierEntryKind.payment ||
          kind == WorkspaceSupplierEntryKind.advance))) &&
      amountMinor > 0 &&
      _financeAmountValid(amountMinor) &&
      (paymentMethod == null || paymentMethod!.trim().isNotEmpty) &&
      (billId == null || billId!.trim().isNotEmpty) &&
      (kind != WorkspaceSupplierEntryKind.bill || billId != null);

  bool get _validOrigin => switch (origin) {
    WorkspaceSupplierEntryOrigin.moolSocialOrder =>
      orderId?.trim().isNotEmpty == true && purchaseId == null,
    WorkspaceSupplierEntryOrigin.manualPurchase =>
      purchaseId?.trim().isNotEmpty == true && orderId == null,
    WorkspaceSupplierEntryOrigin.supplierAccount =>
      orderId == null &&
          purchaseId == null &&
          kind != WorkspaceSupplierEntryKind.bill,
  };

  int get payableDeltaMinor => switch (kind) {
    WorkspaceSupplierEntryKind.bill ||
    WorkspaceSupplierEntryKind.refund => amountMinor,
    WorkspaceSupplierEntryKind.advance ||
    WorkspaceSupplierEntryKind.payment ||
    WorkspaceSupplierEntryKind.creditNote => -amountMinor,
  };

  Map<String, Object?> toJson() => {
    'operationId': operationId,
    'orderId': orderId,
    if (origin != WorkspaceSupplierEntryOrigin.moolSocialOrder)
      'origin': origin.name,
    if (purchaseId != null) 'purchaseId': purchaseId,
    'reference': reference,
    'billId': billId,
    if (paymentMethod != null) 'paymentMethod': paymentMethod,
    if (moneyReview != null) 'moneyReview': moneyReview!.toJson(),
    'kind': kind.name,
    'amountMinor': amountMinor,
    'postedAt': postedAt.toUtc().toIso8601String(),
  };
}

/// Immutable submitted input, separate from proof that money was recorded.
class WorkspaceSupplierMoneyAttempt {
  const WorkspaceSupplierMoneyAttempt({required this.entry, required this.expectedRevision});
  final WorkspaceSupplierLedgerEntry entry;
  final int expectedRevision;
  bool get valid => expectedRevision > 0 && entry.valid && entry.moneyReview != null &&
      entry.paymentMethod?.trim().isNotEmpty == true &&
      entry.origin != WorkspaceSupplierEntryOrigin.moolSocialOrder &&
      (entry.kind == WorkspaceSupplierEntryKind.payment ||
        (entry.kind == WorkspaceSupplierEntryKind.advance &&
          entry.origin == WorkspaceSupplierEntryOrigin.supplierAccount));
  Map<String, Object?> toJson() => {'entry': entry.toJson(), 'expectedRevision': expectedRevision};
  static WorkspaceSupplierMoneyAttempt? fromJson(Object? raw) {
    if (raw is! Map || raw.length != 2 || !raw.containsKey('entry') ||
        !raw.containsKey('expectedRevision') || raw['expectedRevision'] is! int || raw['entry'] is! Map) {
      return null;
    }
    try {
      final json = raw['entry'] as Map;
      const keys = {'operationId', 'orderId', 'origin', 'purchaseId', 'reference',
        'billId', 'paymentMethod', 'moneyReview', 'kind', 'amountMinor', 'postedAt'};
      if (!json.keys.every(keys.contains)) return null;
      final entry = WorkspaceSupplierLedgerEntry(operationId: json['operationId'] as String,
        orderId: json['orderId'] as String?, purchaseId: json['purchaseId'] as String?,
        origin: WorkspaceSupplierEntryOrigin.values.byName(json['origin'] as String),
        reference: json['reference'] as String, billId: json['billId'] as String?,
        paymentMethod: json['paymentMethod'] as String?,
        moneyReview: WorkspaceSupplierMoneyReview.fromJson(json['moneyReview']),
        kind: WorkspaceSupplierEntryKind.values.byName(json['kind'] as String),
        amountMinor: json['amountMinor'] as int, postedAt: DateTime.parse(json['postedAt'] as String));
      final result = WorkspaceSupplierMoneyAttempt(entry: entry, expectedRevision: raw['expectedRevision'] as int);
      return result.valid ? result : null;
    } on Object {
      return null;
    }
  }
}

/// Explicit money provenance, never inferred from a credit-note amount alone.
enum WorkspaceSupplierRefundSourceKind {
  openingAdvance, accountAdvance, manualBillSurplus,
}

/// Frozen retailer review, not proof that a refund has been received/posted.
/// A bill surplus does not restore the capacity of its original funding advance.
class WorkspaceSupplierRefundIntent {
  const WorkspaceSupplierRefundIntent({required this.operationId,
    required this.accountScope, required this.workspaceId, required this.supplierId,
    required this.qa, required this.sourceKind, required this.sourceId,
    required this.openingId, required this.openingRevision,
    required this.reference, required this.occurredOn, required this.paymentMethod,
    required this.amountMinor, required this.requestedAt,
    this.copyId, this.copyRevision});

  final String operationId, accountScope, workspaceId, supplierId, sourceId,
    openingId, reference, occurredOn, paymentMethod;
  final bool qa;
  final WorkspaceSupplierRefundSourceKind sourceKind;
  final int openingRevision, amountMinor;
  final String? copyId;
  final int? copyRevision;
  final DateTime requestedAt;

  bool get valid {
    final review = WorkspaceSupplierMoneyReview(occurredOn: occurredOn,
      openingId: openingId, openingRevision: openingRevision,
      notIncludedInOpening: true);
    final requested = requestedAt.toLocal();
    return [operationId, accountScope, workspaceId, supplierId, sourceId,
      openingId, reference].every((v) => v.isNotEmpty && v == v.trim() && v.length <= 512) &&
      review.valid && !review.day!.isAfter(DateTime.utc(requested.year,
        requested.month, requested.day)) &&
      const ['Cash', 'UPI', 'Bank transfer'].contains(paymentMethod) &&
      amountMinor > 0 && _financeAmountValid(amountMinor) &&
      (sourceKind == WorkspaceSupplierRefundSourceKind.manualBillSurplus
        ? copyId != null && copyId!.isNotEmpty && copyId == copyId!.trim() &&
          copyId!.length <= 512 && (copyRevision ?? 0) > 0
        : copyId == null && copyRevision == null);
  }

  Map<String, Object?> toJson() => {'operationId': operationId,
    'accountScope': accountScope, 'workspaceId': workspaceId,
    'supplierId': supplierId, 'qa': qa, 'sourceKind': sourceKind.name,
    'sourceId': sourceId, 'openingId': openingId,
    'openingRevision': openingRevision, 'reference': reference,
    'occurredOn': occurredOn, 'paymentMethod': paymentMethod,
    'amountMinor': amountMinor, 'requestedAt': requestedAt.toUtc().toIso8601String(),
    'copyId': copyId, 'copyRevision': copyRevision};

  static WorkspaceSupplierRefundIntent fromJson(Object? raw) {
    const keys = {'operationId', 'accountScope', 'workspaceId', 'supplierId',
      'qa', 'sourceKind', 'sourceId', 'openingId', 'openingRevision', 'reference',
      'occurredOn', 'paymentMethod', 'amountMinor', 'requestedAt', 'copyId', 'copyRevision'};
    if (raw is! Map || raw.length != keys.length || !keys.every(raw.containsKey)) {
      throw const FormatException('Invalid supplier refund review');
    }
    final intent = WorkspaceSupplierRefundIntent(operationId: raw['operationId'] as String,
      accountScope: raw['accountScope'] as String, workspaceId: raw['workspaceId'] as String,
      supplierId: raw['supplierId'] as String, qa: raw['qa'] as bool,
      sourceKind: WorkspaceSupplierRefundSourceKind.values.byName(raw['sourceKind'] as String),
      sourceId: raw['sourceId'] as String, openingId: raw['openingId'] as String,
      openingRevision: raw['openingRevision'] as int, reference: raw['reference'] as String,
      occurredOn: raw['occurredOn'] as String, paymentMethod: raw['paymentMethod'] as String,
      amountMinor: raw['amountMinor'] as int, requestedAt: DateTime.parse(raw['requestedAt'] as String),
      copyId: raw['copyId'] as String?, copyRevision: raw['copyRevision'] as int?);
    if (!intent.valid) throw const FormatException('Invalid supplier refund review');
    return intent;
  }

  WorkspaceSupplierRefund commit({required int revision, required DateTime at}) =>
    WorkspaceSupplierRefund(intent: this, committedRevision: revision, recordedAt: at);

  WorkspaceLedgerFormKey get formKey => (account: accountScope, store: workspaceId,
    customer: supplierId, invoice: sourceId,
    order: 'supplier-refund:${qa ? 'qa' : 'live'}:${sourceKind.name}:${copyId ?? 'account'}',
    kind: 'supplierRefund', ledgerRevision: copyRevision ?? openingRevision);
}

/// Proof and source consumption accompany exactly one incoming-money entry.
class WorkspaceSupplierRefund {
  const WorkspaceSupplierRefund({required this.intent,
    required this.committedRevision, required this.recordedAt});
  final WorkspaceSupplierRefundIntent intent;
  final int committedRevision;
  final DateTime recordedAt;
  bool get valid => intent.valid && committedRevision > 1 &&
    !recordedAt.isBefore(intent.requestedAt);
  Map<String, Object?> toJson() => {'intent': intent.toJson(),
    'committedRevision': committedRevision,
    'recordedAt': recordedAt.toUtc().toIso8601String()};
  static WorkspaceSupplierRefund fromJson(Object? raw) {
    if (raw is! Map || raw.length != 3 || !raw.containsKey('intent') ||
        !raw.containsKey('committedRevision') || !raw.containsKey('recordedAt')) {
      throw const FormatException('Invalid supplier refund proof');
    }
    final proof = WorkspaceSupplierRefund(intent: WorkspaceSupplierRefundIntent.fromJson(raw['intent']),
      committedRevision: raw['committedRevision'] as int,
      recordedAt: DateTime.parse(raw['recordedAt'] as String));
    if (!proof.valid) throw const FormatException('Invalid supplier refund proof');
    return proof;
  }
  WorkspaceSupplierLedgerEntry get entry => WorkspaceSupplierLedgerEntry(
    operationId: intent.operationId, reference: intent.reference,
    origin: intent.sourceKind == WorkspaceSupplierRefundSourceKind.manualBillSurplus
      ? WorkspaceSupplierEntryOrigin.manualPurchase : WorkspaceSupplierEntryOrigin.supplierAccount,
    purchaseId: intent.copyId,
    billId: intent.sourceKind == WorkspaceSupplierRefundSourceKind.manualBillSurplus ? intent.sourceId : null,
    kind: WorkspaceSupplierEntryKind.refund, amountMinor: intent.amountMinor,
    paymentMethod: intent.paymentMethod, postedAt: recordedAt);
}

/// Immutable bill acceptance, independent of receipt and payment. The supplier
/// document is frozen here; editing a saved copy cannot rewrite posted books.
/// Explicit whole-invoice classification against an immutable confirmed opening.
/// The containing acceptance freezes the reviewed invoice copy independently.
class WorkspaceSupplierBillOpeningReview {
  const WorkspaceSupplierBillOpeningReview({required this.openingId,
    required this.openingRevision, required this.treatment});
  final String openingId;
  final int openingRevision;
  final WorkspaceOpeningBillInclusion treatment;
  bool get valid => openingId.trim().isNotEmpty && openingId.length <= 240 &&
    openingRevision > 0 && treatment != WorkspaceOpeningBillInclusion.unknown;
  Map<String, Object?> toJson() => {'openingId': openingId,
    'openingRevision': openingRevision, 'treatment': treatment.name};
  static WorkspaceSupplierBillOpeningReview fromJson(Object? raw) {
    const keys = {'openingId', 'openingRevision', 'treatment'};
    if (raw is! Map || raw.length != keys.length || !raw.keys.every(keys.contains)) {
      throw const FormatException('Invalid purchase opening review');
    }
    final result = WorkspaceSupplierBillOpeningReview(openingId: raw['openingId'] as String,
      openingRevision: raw['openingRevision'] as int,
      treatment: WorkspaceOpeningBillInclusion.values.byName(raw['treatment'] as String));
    if (!result.valid) throw const FormatException('Invalid purchase opening review');
    return result;
  }
}

class WorkspaceSupplierBillAcceptance {
  WorkspaceSupplierBillAcceptance({
    required WorkspacePurchaseSavedCopy copy,
    required this.acceptedAt,
    required this.openingTreatment,
    this.openingReview,
  }) : copy = WorkspacePurchaseSavedCopy.fromJson(
         jsonDecode(jsonEncode(copy.toJson())));

  final WorkspacePurchaseSavedCopy copy;
  final DateTime acceptedAt;
  final WorkspaceOpeningBillInclusion openingTreatment;
  final WorkspaceSupplierBillOpeningReview? openingReview;
  String get billId => copy.draft.id;
  int? get amountMinor =>
      WorkspacePurchaseEntryDraft.printedPaise(copy.draft.details['invoiceTotal']);
  bool get addsLiability =>
      openingTreatment == WorkspaceOpeningBillInclusion.excluded &&
      (amountMinor ?? 0) > 0;
  bool get valid => copy.valid && copy.draft.invoiceReference.trim().isNotEmpty &&
      copy.draft.invoiceIssuedDay != null &&
      amountMinor != null && amountMinor! >= 0 &&
      _financeAmountValid(amountMinor!) &&
      openingTreatment != WorkspaceOpeningBillInclusion.unknown &&
      (openingReview == null || (openingReview!.valid &&
        openingReview!.treatment == openingTreatment)) &&
      !acceptedAt.isBefore(copy.savedAt) &&
      copy.draft.goods.isNotEmpty &&
      copy.draft.goods.every((line) =>
        (line['name'] ?? '').trim().isNotEmpty &&
        (line['pack'] ?? '').trim().isNotEmpty &&
        RegExp(r'^\d+(\.\d{1,3})?$').hasMatch(line['quantity'] ?? '') &&
        (RegExp(r'[1-9]').hasMatch(line['quantity'] ?? '') ||
          (RegExp(r'^\d+(\.\d{1,3})?$').hasMatch(line['freeQuantity'] ?? '') &&
            RegExp(r'[1-9]').hasMatch(line['freeQuantity'] ?? ''))) &&
        WorkspacePurchaseEntryDraft.printedPaise(line['cost']) != null &&
        WorkspacePurchaseEntryDraft.printedPaise(line['cost'])! >= 0) &&
      WorkspacePurchaseEntryDraft.reviewAmounts(copy.draft.details).isEmpty;

  Map<String, Object?> toJson() => {
    'copy': copy.toJson(), 'acceptedAt': acceptedAt.toUtc().toIso8601String(),
    'openingTreatment': openingTreatment.name,
    if (openingReview != null) 'openingReview': openingReview!.toJson(),
  };
  static WorkspaceSupplierBillAcceptance fromJson(Object? raw) {
    const keys = {'copy', 'acceptedAt', 'openingTreatment', 'openingReview'};
    if (raw is! Map || raw.length < 3 || raw.length > keys.length ||
        !raw.keys.every(keys.contains) ||
        !{'copy', 'acceptedAt', 'openingTreatment'}.every(raw.containsKey)) {
      throw const FormatException('Invalid accepted purchase bill');
    }
    final result = WorkspaceSupplierBillAcceptance(
      copy: WorkspacePurchaseSavedCopy.fromJson(raw['copy']),
      acceptedAt: DateTime.parse(raw['acceptedAt'] as String),
      openingTreatment: WorkspaceOpeningBillInclusion.values.byName(
        raw['openingTreatment'] as String),
      openingReview: raw.containsKey('openingReview')
        ? WorkspaceSupplierBillOpeningReview.fromJson(raw['openingReview']) : null,
    );
    if (!result.valid) {
      throw const FormatException('Invalid accepted purchase bill');
    }
    return result;
  }
}

/// One immutable delivery line. Quantities use thousandths of the supplier's
/// unit, converted exactly into the existing Stock unit; never rounded.
class WorkspaceSupplierGoodsReceiptLine {
  WorkspaceSupplierGoodsReceiptLine({required this.sourceLineId,
    required this.productId, required this.productLabel,
    required this.purchaseUnit, required this.stockUnit, required this.unitsPerPack,
    required this.deliveredMilli, required this.acceptedMilli,
    required this.damagedMilli, required this.shortMilli,
    this.expectedMilli, Map<String, int> priorStockUnits = const {},
  }) : priorStockUnits = Map.unmodifiable(priorStockUnits);
  final String sourceLineId, productId, productLabel, purchaseUnit, stockUnit;
  final int unitsPerPack, deliveredMilli, acceptedMilli, damagedMilli, shortMilli;
  final int? expectedMilli;
  final Map<String, int> priorStockUnits;
  int get acceptedStockUnits => acceptedMilli * unitsPerPack ~/ 1000;
  int get linkedStockUnits => priorStockUnits.values.fold(0, (a, b) => a + b);
  int get newStockUnits => acceptedStockUnits - linkedStockUnits;
  bool get valid =>
      [sourceLineId, productId, productLabel, purchaseUnit, stockUnit]
        .every((v) => v.trim().isNotEmpty && v.length <= 240) &&
      unitsPerPack > 0 && unitsPerPack <= 1000000 &&
      [deliveredMilli, acceptedMilli, damagedMilli, shortMilli]
        .every((v) => v >= 0 && v <= 2147483647) &&
      deliveredMilli > 0 && deliveredMilli == acceptedMilli + damagedMilli &&
      (expectedMilli == null || (expectedMilli! > 0 && expectedMilli! <= 2147483647 &&
        deliveredMilli + shortMilli <= expectedMilli!)) &&
      acceptedMilli * unitsPerPack % 1000 == 0 &&
      acceptedStockUnits <= 2147483647 && priorStockUnits.length <= 200 &&
      priorStockUnits.entries.every((e) => e.key.trim().isNotEmpty &&
        e.key.length <= 512 && e.value > 0 && e.value <= 2147483647) &&
      linkedStockUnits <= acceptedStockUnits;
  Object get mappingIdentity =>
      (productId, productLabel, purchaseUnit, stockUnit, unitsPerPack, expectedMilli);
  Map<String, Object?> toJson() => {
    'sourceLineId': sourceLineId, 'productId': productId, 'productLabel': productLabel,
    'purchaseUnit': purchaseUnit, 'stockUnit': stockUnit, 'unitsPerPack': unitsPerPack,
    'deliveredMilli': deliveredMilli, 'acceptedMilli': acceptedMilli,
    'damagedMilli': damagedMilli, 'shortMilli': shortMilli,
    'expectedMilli': expectedMilli, 'priorStockUnits': priorStockUnits,
  };
  static WorkspaceSupplierGoodsReceiptLine fromJson(Object? raw) {
    const keys = {'sourceLineId', 'productId', 'productLabel', 'purchaseUnit',
      'stockUnit', 'unitsPerPack', 'deliveredMilli', 'acceptedMilli', 'damagedMilli',
      'shortMilli', 'expectedMilli', 'priorStockUnits'};
    if (raw is! Map || raw.length != keys.length || !raw.keys.every(keys.contains)) {
      throw const FormatException('Invalid received item');
    }
    final result = WorkspaceSupplierGoodsReceiptLine(
      sourceLineId: raw['sourceLineId'] as String, productId: raw['productId'] as String,
      productLabel: raw['productLabel'] as String, purchaseUnit: raw['purchaseUnit'] as String,
      stockUnit: raw['stockUnit'] as String, unitsPerPack: raw['unitsPerPack'] as int,
      deliveredMilli: raw['deliveredMilli'] as int, acceptedMilli: raw['acceptedMilli'] as int,
      damagedMilli: raw['damagedMilli'] as int, shortMilli: raw['shortMilli'] as int,
      expectedMilli: raw['expectedMilli'] as int?,
      priorStockUnits: Map<String, int>.from(raw['priorStockUnits'] as Map));
    if (!result.valid) {
      throw const FormatException('Invalid received item');
    }
    return result;
  }
}

/// A physical arrival event, independent of bill acceptance and money. A group
/// identifies one expected delivery across partial arrivals, not one arrival.
class WorkspaceSupplierGoodsReceipt {
  WorkspaceSupplierGoodsReceipt({required this.id, required this.expectedDeliveryId,
    required this.reference, required this.deliveredOn, required this.recordedAt,
    required List<WorkspaceSupplierGoodsReceiptLine> lines,
  }) : lines = List.unmodifiable(lines);
  final String id, expectedDeliveryId, reference, deliveredOn;
  final DateTime recordedAt;
  final List<WorkspaceSupplierGoodsReceiptLine> lines;
  bool get valid {
    final day = DateTime.tryParse(deliveredOn);
    final local = recordedAt.toLocal();
    return [id, expectedDeliveryId, reference].every((v) =>
        v.trim().isNotEmpty && v.length <= 240) &&
      RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(deliveredOn) && day != null &&
      day.toIso8601String().substring(0, 10) == deliveredOn &&
      !DateTime.utc(day.year, day.month, day.day).isAfter(
        DateTime.utc(local.year, local.month, local.day)) &&
      lines.isNotEmpty && lines.length <= 200 && lines.every((line) => line.valid) &&
      lines.map((line) => line.sourceLineId).toSet().length == lines.length;
  }
  String stockReference(WorkspaceSupplierGoodsReceiptLine line) =>
      jsonEncode([id, line.sourceLineId]);
  WorkspaceStockMovement? movementFor(WorkspaceSupplierGoodsReceiptLine line) =>
      line.newStockUnits <= 0 ? null : WorkspaceStockMovement(
        id: jsonEncode(['manual-supplier-receipt', id, line.sourceLineId]),
        productId: line.productId, productLabel: line.productLabel,
        kind: WorkspaceStockMovementKind.goodsReceived, quantityDelta: line.newStockUnits,
        reason: 'Supplier delivery $reference', occurredAt: recordedAt,
        referenceKind: WorkspaceStockReferenceKind.manualSupplierReceipt,
        referenceId: stockReference(line));
  Map<String, Object?> toJson() => {'id': id, 'expectedDeliveryId': expectedDeliveryId,
    'reference': reference, 'deliveredOn': deliveredOn,
    'recordedAt': recordedAt.toUtc().toIso8601String(),
    'lines': lines.map((line) => line.toJson()).toList()};
  static WorkspaceSupplierGoodsReceipt fromJson(Object? raw) {
    const keys = {'id', 'expectedDeliveryId', 'reference', 'deliveredOn', 'recordedAt', 'lines'};
    if (raw is! Map || raw.length != keys.length || !raw.keys.every(keys.contains)) {
      throw const FormatException('Invalid supplier delivery');
    }
    final result = WorkspaceSupplierGoodsReceipt(id: raw['id'] as String,
      expectedDeliveryId: raw['expectedDeliveryId'] as String,
      reference: raw['reference'] as String, deliveredOn: raw['deliveredOn'] as String,
      recordedAt: DateTime.parse(raw['recordedAt'] as String),
      lines: [for (final line in raw['lines'] as List)
        WorkspaceSupplierGoodsReceiptLine.fromJson(line)]);
    if (!result.valid) {
      throw const FormatException('Invalid supplier delivery');
    }
    return result;
  }
}

/// A supplier-scoped projection, supplied independently of fulfilment facts.
/// A positive balance is payable; a negative balance is credit with the supplier.
/// Missing opening/history evidence must never be presented as a zero balance.
class WorkspaceSupplierBillGoodsAllocation {
  const WorkspaceSupplierBillGoodsAllocation({required this.operationId,
    required this.receiptId, required this.receiptLineId, required this.billId,
    required this.copyId, required this.copyRevision, required this.billLineIndex,
    required this.productId, required this.billUnit, required this.stockUnit,
    required this.stockUnitsNumerator, required this.stockUnitsDenominator,
    required this.billQuantityMilli, required this.acceptedReceiptMilli,
    required this.damagedReceiptMilli, required this.conversionReviewed,
    required this.linkedAt, this.freeBillQuantityMilli = 0});
  final String operationId, receiptId, receiptLineId, billId, copyId, productId, billUnit, stockUnit;
  final int copyRevision, billLineIndex, stockUnitsNumerator, stockUnitsDenominator,
      billQuantityMilli, freeBillQuantityMilli, acceptedReceiptMilli, damagedReceiptMilli;
  final bool conversionReviewed;
  final DateTime linkedAt;
  bool get valid => [operationId, receiptId, receiptLineId, billId, copyId, productId, billUnit, stockUnit]
      .every((v) => v.trim().isNotEmpty && v.length <= 512) &&
      copyRevision > 0 && billLineIndex >= 0 && billLineIndex < 200 && conversionReviewed &&
      stockUnitsNumerator > 0 && stockUnitsNumerator <= 1000000 &&
      stockUnitsDenominator > 0 && stockUnitsDenominator <= 1000000 &&
      BigInt.from(stockUnitsNumerator).gcd(BigInt.from(stockUnitsDenominator)) == BigInt.one &&
      billQuantityMilli >= 0 && freeBillQuantityMilli >= 0 &&
      billQuantityMilli + freeBillQuantityMilli > 0 &&
      billQuantityMilli + freeBillQuantityMilli <= 2147483647 &&
      acceptedReceiptMilli >= 0 && damagedReceiptMilli >= 0 &&
      acceptedReceiptMilli + damagedReceiptMilli > 0 &&
      acceptedReceiptMilli + damagedReceiptMilli <= 2147483647;
  Object get unitBinding => (copyId, copyRevision, productId, billUnit, stockUnit,
      stockUnitsNumerator, stockUnitsDenominator);
  Map<String, Object?> toJson() => {'operationId': operationId, 'receiptId': receiptId,
    'receiptLineId': receiptLineId, 'billId': billId, 'copyId': copyId,
    'copyRevision': copyRevision, 'billLineIndex': billLineIndex, 'productId': productId,
    'billUnit': billUnit, 'stockUnit': stockUnit, 'stockUnitsNumerator': stockUnitsNumerator,
    'stockUnitsDenominator': stockUnitsDenominator, 'billQuantityMilli': billQuantityMilli,
    if (freeBillQuantityMilli > 0) 'freeBillQuantityMilli': freeBillQuantityMilli,
    'acceptedReceiptMilli': acceptedReceiptMilli, 'damagedReceiptMilli': damagedReceiptMilli,
    'conversionReviewed': conversionReviewed, 'linkedAt': linkedAt.toUtc().toIso8601String()};
  static WorkspaceSupplierBillGoodsAllocation fromJson(Object? raw) {
    const keys = {'operationId', 'receiptId', 'receiptLineId', 'billId', 'copyId',
      'copyRevision', 'billLineIndex', 'productId', 'billUnit', 'stockUnit',
      'stockUnitsNumerator', 'stockUnitsDenominator', 'billQuantityMilli',
      'acceptedReceiptMilli', 'damagedReceiptMilli', 'conversionReviewed', 'linkedAt'};
    if (raw is! Map || !keys.every(raw.containsKey) ||
        !raw.keys.every((key) => keys.contains(key) || key == 'freeBillQuantityMilli')) {
      throw const FormatException('Invalid purchase goods link');
    }
    final result = WorkspaceSupplierBillGoodsAllocation(operationId: raw['operationId'] as String,
      receiptId: raw['receiptId'] as String, receiptLineId: raw['receiptLineId'] as String,
      billId: raw['billId'] as String, copyId: raw['copyId'] as String,
      copyRevision: raw['copyRevision'] as int, billLineIndex: raw['billLineIndex'] as int,
      productId: raw['productId'] as String, billUnit: raw['billUnit'] as String,
      stockUnit: raw['stockUnit'] as String, stockUnitsNumerator: raw['stockUnitsNumerator'] as int,
      stockUnitsDenominator: raw['stockUnitsDenominator'] as int,
      billQuantityMilli: raw['billQuantityMilli'] as int, acceptedReceiptMilli: raw['acceptedReceiptMilli'] as int,
      freeBillQuantityMilli: raw['freeBillQuantityMilli'] as int? ?? 0,
      damagedReceiptMilli: raw['damagedReceiptMilli'] as int,
      conversionReviewed: raw['conversionReviewed'] as bool,
      linkedAt: DateTime.parse(raw['linkedAt'] as String));
    if (!result.valid) throw const FormatException('Invalid purchase goods link');
    return result;
  }
}

enum WorkspaceSupplierMoneySourceKind { openingAdvance, accountPayment, accountAdvance, manualBillSurplus }

/// Frozen reviewed bill/delivery attribution for missing goods. Receipt and
/// prior-claim membership must be derived from the authoritative predecessor,
/// not selected by the caller. This evidence is not supplier-approved credit.
class WorkspaceSupplierShortageClaim {
  WorkspaceSupplierShortageClaim({required this.operationId, required this.accountScope,
    required this.workspaceId, required this.supplierId, required this.billId,
    required this.copyId, required this.copyRevision, required this.billLineIndex,
    required this.expectedDeliveryId, required this.receiptLineId,
    required this.productId, required this.purchaseUnit, required this.quantityMilli,
    required this.outstandingMilli, required this.priorClaimedMilli,
    required this.recordedAt, required this.committedRevision,
    required List<String> receiptIds, required List<String> priorClaimIds,
    required List<String> billAllocationIds, this.requestedAt,
    this.openingId, this.openingRevision})
    : receiptIds = List.unmodifiable(receiptIds), priorClaimIds = List.unmodifiable(priorClaimIds),
      billAllocationIds = List.unmodifiable(billAllocationIds);
  final String operationId, accountScope, workspaceId, supplierId, billId, copyId,
    expectedDeliveryId, receiptLineId, productId, purchaseUnit;
  final int copyRevision, billLineIndex, quantityMilli, outstandingMilli,
    priorClaimedMilli, committedRevision;
  final DateTime recordedAt;
  final DateTime? requestedAt;
  final String? openingId;
  final int? openingRevision;
  final List<String> receiptIds, priorClaimIds, billAllocationIds;
  Object get deliverySource => (expectedDeliveryId, receiptLineId);
  bool get valid => [operationId, accountScope, workspaceId, supplierId, billId,
    copyId, expectedDeliveryId, receiptLineId, productId, purchaseUnit]
    .every((v) => v.trim().isNotEmpty && v == v.trim() && v.length <= 512) &&
    copyRevision > 0 && committedRevision > 1 && billLineIndex >= 0 && billLineIndex < 200 &&
    quantityMilli > 0 && quantityMilli <= 2147483647 &&
    outstandingMilli >= quantityMilli && outstandingMilli <= 2147483647 &&
    priorClaimedMilli >= 0 && priorClaimedMilli <= outstandingMilli - quantityMilli &&
    receiptIds.isNotEmpty && receiptIds.length <= 1000 && priorClaimIds.length <= 10000 && billAllocationIds.length <= 10000 &&
    receiptIds.toSet().length == receiptIds.length &&
    priorClaimIds.toSet().length == priorClaimIds.length && !priorClaimIds.contains(operationId) &&
    billAllocationIds.toSet().length == billAllocationIds.length &&
    [...receiptIds, ...priorClaimIds, ...billAllocationIds].every((v) =>
      v.trim().isNotEmpty && v == v.trim() && v.length <= 512) &&
    (requestedAt == null ? openingId == null && openingRevision == null
      : openingId != null && openingId!.trim().isNotEmpty && openingId == openingId!.trim() &&
        openingId!.length <= 512 && openingRevision != null && openingRevision! > 0 &&
        !requestedAt!.isAfter(recordedAt));
  Map<String, Object?> toJson() => {'operationId': operationId, 'accountScope': accountScope,
    'workspaceId': workspaceId, 'supplierId': supplierId, 'billId': billId,
    'copyId': copyId, 'copyRevision': copyRevision, 'billLineIndex': billLineIndex,
    'expectedDeliveryId': expectedDeliveryId, 'receiptLineId': receiptLineId,
    'productId': productId, 'purchaseUnit': purchaseUnit, 'quantityMilli': quantityMilli,
    'outstandingMilli': outstandingMilli, 'priorClaimedMilli': priorClaimedMilli,
    'recordedAt': recordedAt.toUtc().toIso8601String(), 'committedRevision': committedRevision,
    'receiptIds': receiptIds, 'priorClaimIds': priorClaimIds, 'billAllocationIds': billAllocationIds,
    if (requestedAt != null) 'requestedAt': requestedAt!.toUtc().toIso8601String(),
    if (openingId != null) 'openingId': openingId,
    if (openingRevision != null) 'openingRevision': openingRevision};
  Map<String, Object?> intentToJson() => {...toJson()
    ..remove('recordedAt')..remove('committedRevision'),
    'receiptIds': receiptIds.toList()..sort(),
    'priorClaimIds': priorClaimIds.toList()..sort(),
    'billAllocationIds': billAllocationIds.toList()..sort()};
  static WorkspaceSupplierShortageClaim fromJson(Object? raw) {
    const keys = {'operationId', 'accountScope', 'workspaceId', 'supplierId', 'billId',
      'copyId', 'copyRevision', 'billLineIndex', 'expectedDeliveryId', 'receiptLineId',
      'productId', 'purchaseUnit', 'quantityMilli', 'outstandingMilli', 'priorClaimedMilli',
      'recordedAt', 'committedRevision', 'receiptIds', 'priorClaimIds', 'billAllocationIds'};
    const optional = {'requestedAt', 'openingId', 'openingRevision'};
    if (raw is! Map || !keys.every(raw.containsKey) ||
        !raw.keys.every((key) => keys.contains(key) || optional.contains(key)) ||
        (raw.keys.any(optional.contains) && !optional.every(raw.containsKey)) ||
        raw['receiptIds'] is! List || (raw['receiptIds'] as List).length > 1000 ||
        raw['priorClaimIds'] is! List || (raw['priorClaimIds'] as List).length > 10000 ||
        raw['billAllocationIds'] is! List || (raw['billAllocationIds'] as List).length > 10000) {
      throw const FormatException('Invalid supplier shortage claim');
    }
    final claim = WorkspaceSupplierShortageClaim(operationId: raw['operationId'] as String,
      accountScope: raw['accountScope'] as String, workspaceId: raw['workspaceId'] as String,
      supplierId: raw['supplierId'] as String, billId: raw['billId'] as String,
      copyId: raw['copyId'] as String, copyRevision: raw['copyRevision'] as int,
      billLineIndex: raw['billLineIndex'] as int, expectedDeliveryId: raw['expectedDeliveryId'] as String,
      receiptLineId: raw['receiptLineId'] as String, productId: raw['productId'] as String,
      purchaseUnit: raw['purchaseUnit'] as String, quantityMilli: raw['quantityMilli'] as int,
      outstandingMilli: raw['outstandingMilli'] as int, priorClaimedMilli: raw['priorClaimedMilli'] as int,
      recordedAt: DateTime.parse(raw['recordedAt'] as String), committedRevision: raw['committedRevision'] as int,
      receiptIds: (raw['receiptIds'] as List).cast<String>(), priorClaimIds: (raw['priorClaimIds'] as List).cast<String>(),
      billAllocationIds: (raw['billAllocationIds'] as List).cast<String>(),
      requestedAt: raw.containsKey('requestedAt') ? DateTime.parse(raw['requestedAt'] as String) : null,
      openingId: raw['openingId'] as String?, openingRevision: raw['openingRevision'] as int?);
    if (!claim.valid) throw const FormatException('Invalid supplier shortage claim');
    return claim;
  }
}

/// Frozen shortage review, distinct from the native commit and supplier credit.
class WorkspaceSupplierShortageIntent {
  WorkspaceSupplierShortageIntent._(this._review);
  final WorkspaceSupplierShortageClaim _review;
  String get operationId => _review.operationId;
  String get accountScope => _review.accountScope;
  String get workspaceId => _review.workspaceId;
  String get supplierId => _review.supplierId;
  String get billId => _review.billId;
  String get copyId => _review.copyId;
  int get copyRevision => _review.copyRevision;
  int get billLineIndex => _review.billLineIndex;
  String get expectedDeliveryId => _review.expectedDeliveryId;
  String get receiptLineId => _review.receiptLineId;
  String get productId => _review.productId;
  String get purchaseUnit => _review.purchaseUnit;
  int get quantityMilli => _review.quantityMilli;
  int get outstandingMilli => _review.outstandingMilli;
  int get priorClaimedMilli => _review.priorClaimedMilli;
  String get openingId => _review.openingId!;
  int get openingRevision => _review.openingRevision!;
  DateTime get requestedAt => _review.requestedAt!;
  List<String> get receiptIds => _review.receiptIds;
  List<String> get priorClaimIds => _review.priorClaimIds;
  List<String> get billAllocationIds => _review.billAllocationIds;
  bool get valid => _review.valid && _review.requestedAt != null && _review.openingId != null;
  Map<String, Object?> toJson() => _review.intentToJson();
  bool matches(WorkspaceSupplierShortageClaim claim) => valid && claim.valid &&
    claim.requestedAt != null && jsonEncode(toJson()) == jsonEncode(claim.intentToJson());
  static WorkspaceSupplierShortageIntent fromReview(WorkspaceSupplierShortageClaim review) {
    final intent = WorkspaceSupplierShortageIntent._(review);
    if (!intent.valid) { throw const FormatException('Invalid shortage review'); }
    return intent;
  }
  static WorkspaceSupplierShortageIntent fromJson(Object? raw) {
    if (raw is! Map || raw.containsKey('recordedAt') || raw.containsKey('committedRevision') ||
        !raw.containsKey('requestedAt') || !raw.containsKey('openingId') || !raw.containsKey('openingRevision')) {
      throw const FormatException('Invalid shortage review');
    }
    return fromReview(WorkspaceSupplierShortageClaim.fromJson({...raw,
      'recordedAt': raw['requestedAt'], 'committedRevision': 2}));
  }
}

/// Documentary credit support, not a Stock movement or a monetary valuation.
enum WorkspaceSupplierCreditSupportKind { goodsReturned, arrivalDamage, shortage }

class WorkspaceSupplierCreditSupport {
  const WorkspaceSupplierCreditSupport({required this.kind,
    required this.receiptId, required this.receiptLineId,
    required this.billLineIndex, required this.quantityMilli,
    this.returnOperationId, this.shortageClaimId});
  final WorkspaceSupplierCreditSupportKind kind;
  final String receiptId, receiptLineId;
  final String? returnOperationId, shortageClaimId;
  final int billLineIndex, quantityMilli;

  bool get valid => [receiptId, receiptLineId].every(
    (v) => v.trim().isNotEmpty && v == v.trim() && v.length <= 512) &&
    billLineIndex >= 0 && billLineIndex < 200 &&
    quantityMilli > 0 && quantityMilli <= 2147483647 &&
    (kind == WorkspaceSupplierCreditSupportKind.goodsReturned
      ? returnOperationId != null && returnOperationId!.trim().isNotEmpty &&
        returnOperationId == returnOperationId!.trim() && returnOperationId!.length <= 512
      : returnOperationId == null) &&
    (kind == WorkspaceSupplierCreditSupportKind.shortage
      ? shortageClaimId != null && shortageClaimId!.trim().isNotEmpty &&
        shortageClaimId == shortageClaimId!.trim() && shortageClaimId!.length <= 512
      : shortageClaimId == null);

  /// Shared across bills: one physical support item cannot be credited twice
  /// merely by selecting a different invoice or using a new note reference.
  Object get sourceIdentity => kind == WorkspaceSupplierCreditSupportKind.shortage
    ? (kind, shortageClaimId) : (kind, receiptId, receiptLineId, returnOperationId);
  Map<String, Object?> toJson() => {'kind': kind.name, 'receiptId': receiptId,
    'receiptLineId': receiptLineId, 'billLineIndex': billLineIndex,
    'quantityMilli': quantityMilli, if (returnOperationId != null) 'returnOperationId': returnOperationId,
    if (shortageClaimId != null) 'shortageClaimId': shortageClaimId};
  static WorkspaceSupplierCreditSupport fromJson(Object? raw) {
    const requiredKeys = {'kind', 'receiptId', 'receiptLineId', 'billLineIndex', 'quantityMilli'};
    if (raw is! Map || !requiredKeys.every(raw.containsKey) ||
        !raw.keys.every((key) => requiredKeys.contains(key) || key == 'returnOperationId' || key == 'shortageClaimId')) {
      throw const FormatException('Invalid supplier credit support');
    }
    final support = WorkspaceSupplierCreditSupport(
      kind: WorkspaceSupplierCreditSupportKind.values.byName(raw['kind'] as String),
      receiptId: raw['receiptId'] as String, receiptLineId: raw['receiptLineId'] as String,
      billLineIndex: raw['billLineIndex'] as int, quantityMilli: raw['quantityMilli'] as int,
      returnOperationId: raw['returnOperationId'] as String?, shortageClaimId: raw['shortageClaimId'] as String?);
    if (!support.valid) throw const FormatException('Invalid supplier credit support');
    return support;
  }
}

/// Exact reviewed supplier document and frozen support quantities. Structural
/// validity is not posting authority: predecessor journal admission must still
/// verify bill, opening and each support item, including cumulative consumption.
class WorkspaceSupplierCreditNote {
  WorkspaceSupplierCreditNote({required this.operationId, required this.accountScope,
    required this.workspaceId, required this.supplierId, required this.billId,
    required this.copyId, required this.copyRevision, required this.openingId,
    required this.openingRevision, required this.reference, required this.occurredOn,
    required this.reason, required this.amountMinor, required this.recordedAt,
    required this.committedRevision, required List<WorkspaceSupplierCreditSupport> supports,
    this.requestedAt})
    : supports = List.unmodifiable(supports);
  final String operationId, accountScope, workspaceId, supplierId, billId, copyId,
    openingId, reference, occurredOn, reason;
  final int copyRevision, openingRevision, amountMinor, committedRevision;
  final DateTime recordedAt;
  final DateTime? requestedAt;
  final List<WorkspaceSupplierCreditSupport> supports;

  DateTime? get day {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(occurredOn)) return null;
    final parsed = DateTime.tryParse(occurredOn);
    if (parsed == null || parsed.toIso8601String().substring(0, 10) != occurredOn) return null;
    return DateTime.utc(parsed.year, parsed.month, parsed.day);
  }
  bool get valid {
    final date = day, committed = recordedAt.toLocal();
    return [operationId, accountScope, workspaceId, supplierId, billId, copyId, openingId, reference]
      .every((v) => v.trim().isNotEmpty && v == v.trim() && v.length <= 512) &&
      reason.trim().isNotEmpty && reason == reason.trim() && reason.length <= 2000 &&
      copyRevision > 0 && openingRevision > 0 && committedRevision > 1 &&
      amountMinor > 0 && _financeAmountValid(amountMinor) && date != null &&
      (requestedAt == null || !requestedAt!.isAfter(recordedAt)) &&
      !date.isAfter(DateTime.utc(committed.year, committed.month, committed.day)) &&
      supports.isNotEmpty && supports.length <= 200 && supports.every((s) => s.valid) &&
      supports.map((s) => s.sourceIdentity).toSet().length == supports.length;
  }
  Map<String, Object?> toJson() => {'operationId': operationId, 'accountScope': accountScope,
    'workspaceId': workspaceId, 'supplierId': supplierId, 'billId': billId, 'copyId': copyId,
    'copyRevision': copyRevision, 'openingId': openingId, 'openingRevision': openingRevision,
    'reference': reference, 'occurredOn': occurredOn, 'reason': reason, 'amountMinor': amountMinor,
    'recordedAt': recordedAt.toUtc().toIso8601String(), 'committedRevision': committedRevision,
    'supports': [for (final support in supports) support.toJson()],
    if (requestedAt != null) 'requestedAt': requestedAt!.toUtc().toIso8601String()};
  Map<String, Object?> intentToJson() => toJson()..remove('recordedAt')..remove('committedRevision');
  static WorkspaceSupplierCreditNote fromJson(Object? raw) {
    const keys = {'operationId', 'accountScope', 'workspaceId', 'supplierId', 'billId', 'copyId',
      'copyRevision', 'openingId', 'openingRevision', 'reference', 'occurredOn', 'reason',
      'amountMinor', 'recordedAt', 'committedRevision', 'supports'};
    if (raw is! Map || !keys.every(raw.containsKey) ||
        !raw.keys.every((key) => keys.contains(key) || key == 'requestedAt') ||
        raw['supports'] is! List || (raw['supports'] as List).length > 200) {
      throw const FormatException('Invalid supplier credit note');
    }
    final note = WorkspaceSupplierCreditNote(operationId: raw['operationId'] as String,
      accountScope: raw['accountScope'] as String, workspaceId: raw['workspaceId'] as String,
      supplierId: raw['supplierId'] as String, billId: raw['billId'] as String,
      copyId: raw['copyId'] as String, copyRevision: raw['copyRevision'] as int,
      openingId: raw['openingId'] as String, openingRevision: raw['openingRevision'] as int,
      reference: raw['reference'] as String, occurredOn: raw['occurredOn'] as String,
      reason: raw['reason'] as String, amountMinor: raw['amountMinor'] as int,
      recordedAt: DateTime.parse(raw['recordedAt'] as String),
      requestedAt: raw.containsKey('requestedAt') ? DateTime.parse(raw['requestedAt'] as String) : null,
      committedRevision: raw['committedRevision'] as int,
      supports: [for (final support in raw['supports'] as List) WorkspaceSupplierCreditSupport.fromJson(support)]);
    if (!note.valid) throw const FormatException('Invalid supplier credit note');
    return note;
  }
}

/// Reviewed credit request only. Native posting derives commit revision/time.
class WorkspaceSupplierCreditIntent {
  WorkspaceSupplierCreditIntent({required this.operationId, required this.accountScope,
    required this.workspaceId, required this.supplierId, required this.billId,
    required this.copyId, required this.copyRevision, required this.openingId,
    required this.openingRevision, required this.reference, required this.occurredOn,
    required this.reason, required this.amountMinor, required this.requestedAt,
    required List<WorkspaceSupplierCreditSupport> supports}) : supports = List.unmodifiable(supports);
  final String operationId, accountScope, workspaceId, supplierId, billId, copyId,
    openingId, reference, occurredOn, reason;
  final int copyRevision, openingRevision, amountMinor;
  final DateTime requestedAt;
  final List<WorkspaceSupplierCreditSupport> supports;
  WorkspaceSupplierCreditNote commit({required int revision, required DateTime at}) =>
    WorkspaceSupplierCreditNote(operationId: operationId, accountScope: accountScope,
      workspaceId: workspaceId, supplierId: supplierId, billId: billId, copyId: copyId,
      copyRevision: copyRevision, openingId: openingId, openingRevision: openingRevision,
      reference: reference, occurredOn: occurredOn, reason: reason, amountMinor: amountMinor,
      recordedAt: at, committedRevision: revision, requestedAt: requestedAt, supports: supports);
  bool get valid => commit(revision: 2, at: requestedAt).valid;
  Map<String, Object?> toJson() => commit(revision: 2, at: requestedAt).intentToJson();
  bool matches(WorkspaceSupplierCreditNote note) => valid && note.valid &&
    jsonEncode(toJson()) == jsonEncode(note.intentToJson());
  static WorkspaceSupplierCreditIntent fromJson(Object? raw) {
    if (raw is! Map || raw.containsKey('recordedAt') || raw.containsKey('committedRevision') ||
        !raw.containsKey('requestedAt')) { throw const FormatException('Invalid supplier credit request'); }
    final note = WorkspaceSupplierCreditNote.fromJson({...raw,
      'recordedAt': raw['requestedAt'], 'committedRevision': 2});
    final intent = WorkspaceSupplierCreditIntent(operationId: note.operationId, accountScope: note.accountScope,
      workspaceId: note.workspaceId, supplierId: note.supplierId, billId: note.billId,
      copyId: note.copyId, copyRevision: note.copyRevision, openingId: note.openingId,
      openingRevision: note.openingRevision, reference: note.reference, occurredOn: note.occurredOn,
      reason: note.reason, amountMinor: note.amountMinor, requestedAt: note.requestedAt!, supports: note.supports);
    if (!intent.valid) throw const FormatException('Invalid supplier credit request');
    return intent;
  }
}

/// Frozen retailer request, with no caller-supplied commit proof.
class WorkspaceSupplierMoneyAllocationIntent {
  const WorkspaceSupplierMoneyAllocationIntent({required this.operationId,
    required this.accountScope, required this.workspaceId, required this.supplierId,
    required this.sourceKind, required this.sourceId, required this.openingId,
    required this.openingRevision, required this.billId, required this.copyId,
    required this.copyRevision, required this.amountMinor, required this.requestedAt,
    this.sourceCopyId, this.sourceCopyRevision});
  final String operationId, accountScope, workspaceId, supplierId, sourceId,
    openingId, billId, copyId;
  final WorkspaceSupplierMoneySourceKind sourceKind;
  final int openingRevision, copyRevision, amountMinor;
  final DateTime requestedAt;
  /// Exact accepted source copy reviewed for a bill surplus. The financial
  /// prefix is derived at commit, not frozen in the retailer's request.
  final String? sourceCopyId;
  final int? sourceCopyRevision;
  bool get valid => [operationId, accountScope, workspaceId, supplierId, sourceId,
    openingId, billId, copyId].every((v) => v.trim().isNotEmpty && v.length <= 512) &&
    openingRevision > 0 && copyRevision > 0 &&
    amountMinor > 0 && _financeAmountValid(amountMinor) &&
    (sourceKind == WorkspaceSupplierMoneySourceKind.manualBillSurplus
      ? sourceId != billId && sourceCopyId != null && sourceCopyId!.trim().isNotEmpty &&
        sourceCopyId!.length <= 512 && (sourceCopyRevision ?? 0) > 0
      : sourceCopyId == null && sourceCopyRevision == null);
  Map<String, Object?> intentToJson() => {'operationId': operationId, 'accountScope': accountScope,
    'workspaceId': workspaceId, 'supplierId': supplierId, 'sourceKind': sourceKind.name,
    'sourceId': sourceId, 'openingId': openingId, 'openingRevision': openingRevision,
    'billId': billId, 'copyId': copyId, 'copyRevision': copyRevision,
    'amountMinor': amountMinor, 'requestedAt': requestedAt.toUtc().toIso8601String(),
    if (sourceKind == WorkspaceSupplierMoneySourceKind.manualBillSurplus) ...{
      'sourceCopyId': sourceCopyId, 'sourceCopyRevision': sourceCopyRevision}};
  static WorkspaceSupplierMoneyAllocationIntent fromJson(Object? raw) {
    const keys = {'operationId', 'accountScope', 'workspaceId', 'supplierId', 'sourceKind',
      'sourceId', 'openingId', 'openingRevision', 'billId', 'copyId', 'copyRevision',
      'amountMinor', 'requestedAt'};
    final expected = {...keys, if (raw is Map && raw['sourceKind'] == 'manualBillSurplus')
      ...{'sourceCopyId', 'sourceCopyRevision'}};
    if (raw is! Map || raw.length != expected.length || !expected.every(raw.containsKey)) {
      throw const FormatException('Invalid supplier money allocation');
    }
    final value = WorkspaceSupplierMoneyAllocationIntent(operationId: raw['operationId'] as String,
      accountScope: raw['accountScope'] as String, workspaceId: raw['workspaceId'] as String,
      supplierId: raw['supplierId'] as String, sourceKind: WorkspaceSupplierMoneySourceKind.values.byName(raw['sourceKind'] as String),
      sourceId: raw['sourceId'] as String, openingId: raw['openingId'] as String,
      openingRevision: raw['openingRevision'] as int, billId: raw['billId'] as String,
      copyId: raw['copyId'] as String, copyRevision: raw['copyRevision'] as int,
      amountMinor: raw['amountMinor'] as int, requestedAt: DateTime.parse(raw['requestedAt'] as String),
      sourceCopyId: raw['sourceCopyId'] as String?, sourceCopyRevision: raw['sourceCopyRevision'] as int?);
    if (!value.valid) throw const FormatException('Invalid supplier money allocation');
    return value;
  }

  WorkspaceSupplierBillMoneyAllocation commit({required int revision, required DateTime at, int? sourceEntryCount}) =>
    WorkspaceSupplierBillMoneyAllocation(operationId: operationId, accountScope: accountScope,
      workspaceId: workspaceId, supplierId: supplierId, sourceKind: sourceKind, sourceId: sourceId,
      openingId: openingId, openingRevision: openingRevision, billId: billId, copyId: copyId,
      copyRevision: copyRevision, amountMinor: amountMinor, requestedAt: requestedAt,
      committedRevision: revision, recordedAt: at, sourceCopyId: sourceCopyId,
      sourceCopyRevision: sourceCopyRevision, sourceEntryCount: sourceEntryCount);
}

/// Committed attribution of existing money, not another payment or stock fact.
class WorkspaceSupplierBillMoneyAllocation extends WorkspaceSupplierMoneyAllocationIntent {
  const WorkspaceSupplierBillMoneyAllocation({required super.operationId,
    required super.accountScope, required super.workspaceId, required super.supplierId,
    required super.sourceKind, required super.sourceId, required super.openingId,
    required super.openingRevision, required super.billId, required super.copyId,
    required super.copyRevision, required super.amountMinor, required super.requestedAt,
    required this.committedRevision, required this.recordedAt,
    super.sourceCopyId, super.sourceCopyRevision, this.sourceEntryCount});
  final int committedRevision;
  final int? sourceEntryCount;
  final DateTime recordedAt;
  @override
  bool get valid => super.valid && committedRevision > 1 && !recordedAt.isBefore(requestedAt) &&
    (sourceKind == WorkspaceSupplierMoneySourceKind.manualBillSurplus
      ? sourceEntryCount != null && sourceEntryCount! >= 0 && sourceEntryCount! <= 10000
      : sourceEntryCount == null);
  Map<String, Object?> toJson() => {...intentToJson(), 'committedRevision': committedRevision,
    'recordedAt': recordedAt.toUtc().toIso8601String(),
    if (sourceKind == WorkspaceSupplierMoneySourceKind.manualBillSurplus) 'sourceEntryCount': sourceEntryCount};
  static WorkspaceSupplierBillMoneyAllocation fromJson(Object? raw) {
    if (raw is! Map || !raw.containsKey('committedRevision') || !raw.containsKey('recordedAt')) {
      throw const FormatException('Invalid committed supplier money allocation');
    }
    final intent = WorkspaceSupplierMoneyAllocationIntent.fromJson({
      for (final entry in raw.entries)
        if (entry.key != 'committedRevision' && entry.key != 'recordedAt' &&
            !(raw['sourceKind'] == 'manualBillSurplus' && entry.key == 'sourceEntryCount')) entry.key: entry.value});
    final value = intent.commit(revision: raw['committedRevision'] as int,
      at: DateTime.parse(raw['recordedAt'] as String), sourceEntryCount: raw['sourceEntryCount'] as int?);
    if (!value.valid) throw const FormatException('Invalid committed supplier money allocation');
    return value;
  }
}

/// Physical goods only: a credit note or refund is never implied by this record.
class WorkspaceSupplierGoodsReturnLine {
  const WorkspaceSupplierGoodsReturnLine({required this.receiptLineId,
    required this.productId, required this.productLabel, required this.purchaseUnit,
    required this.stockUnit, required this.unitsPerPack,
    required this.acceptedMilli, required this.damagedMilli});
  final String receiptLineId, productId, productLabel, purchaseUnit, stockUnit;
  final int unitsPerPack, acceptedMilli, damagedMilli;
  int get stockUnits => acceptedMilli * unitsPerPack ~/ 1000;
  bool get valid => [receiptLineId, productId, productLabel, purchaseUnit, stockUnit]
    .every((value) => value.trim().isNotEmpty && value.length <= 240) &&
    unitsPerPack > 0 && unitsPerPack <= 1000000 &&
    acceptedMilli >= 0 && acceptedMilli <= 2147483647 &&
    damagedMilli >= 0 && damagedMilli <= 2147483647 && acceptedMilli + damagedMilli > 0 &&
    acceptedMilli * unitsPerPack % 1000 == 0 && stockUnits <= 2147483647;
  bool matches(WorkspaceSupplierGoodsReceiptLine line) => valid && line.valid &&
    receiptLineId == line.sourceLineId && productId == line.productId &&
    productLabel == line.productLabel && purchaseUnit == line.purchaseUnit &&
    stockUnit == line.stockUnit && unitsPerPack == line.unitsPerPack;
  Map<String, Object?> toJson() => {'receiptLineId': receiptLineId, 'productId': productId,
    'productLabel': productLabel, 'purchaseUnit': purchaseUnit, 'stockUnit': stockUnit,
    'unitsPerPack': unitsPerPack, 'acceptedMilli': acceptedMilli, 'damagedMilli': damagedMilli};
  static WorkspaceSupplierGoodsReturnLine fromJson(Object? raw) {
    const keys = {'receiptLineId', 'productId', 'productLabel', 'purchaseUnit',
      'stockUnit', 'unitsPerPack', 'acceptedMilli', 'damagedMilli'};
    if (raw is! Map || raw.length != keys.length || !raw.keys.every(keys.contains)) {
      throw const FormatException('Invalid supplier return item');
    }
    final result = WorkspaceSupplierGoodsReturnLine(receiptLineId: raw['receiptLineId'] as String,
      productId: raw['productId'] as String, productLabel: raw['productLabel'] as String,
      purchaseUnit: raw['purchaseUnit'] as String, stockUnit: raw['stockUnit'] as String,
      unitsPerPack: raw['unitsPerPack'] as int, acceptedMilli: raw['acceptedMilli'] as int,
      damagedMilli: raw['damagedMilli'] as int);
    if (!result.valid) throw const FormatException('Invalid supplier return item');
    return result;
  }
}

class WorkspaceSupplierGoodsReturn {
  WorkspaceSupplierGoodsReturn({required this.operationId, required this.accountScope,
    required this.workspaceId, required this.supplierId, required this.receiptId,
    required this.reference, required this.reason, required this.returnedOn,
    required this.recordedAt, required this.committedRevision,
    required List<WorkspaceSupplierGoodsReturnLine> lines, this.requestedAt}) : lines = List.unmodifiable(lines);
  final String operationId, accountScope, workspaceId, supplierId, receiptId, reference, reason, returnedOn;
  final DateTime recordedAt;
  final DateTime? requestedAt;
  final int committedRevision;
  final List<WorkspaceSupplierGoodsReturnLine> lines;
  bool get valid {
    final day = DateTime.tryParse(returnedOn), local = recordedAt.toLocal();
    return [operationId, accountScope, workspaceId, supplierId, receiptId, reference]
      .every((value) => value.trim().isNotEmpty && value.length <= 240) &&
      reason.trim().isNotEmpty && reason.length <= 500 && committedRevision > 1 &&
      (requestedAt == null || !requestedAt!.isAfter(recordedAt)) &&
      RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(returnedOn) && day != null &&
      day.toIso8601String().substring(0, 10) == returnedOn &&
      !day.isAfter(DateTime(local.year, local.month, local.day)) &&
      lines.isNotEmpty && lines.length <= 200 && lines.every((line) => line.valid) &&
      lines.map((line) => line.receiptLineId).toSet().length == lines.length;
  }
  WorkspaceStockMovement? movementFor(WorkspaceSupplierGoodsReturnLine line) => line.stockUnits == 0
    ? null : WorkspaceStockMovement(id: 'supplier-goods-return:${jsonEncode([operationId, line.receiptLineId])}',
      productId: line.productId, productLabel: line.productLabel,
      kind: WorkspaceStockMovementKind.supplierReturn, quantityDelta: -line.stockUnits,
      reason: reason, occurredAt: recordedAt, referenceKind: WorkspaceStockReferenceKind.manualSupplierReturn,
      referenceId: operationId);
  Map<String, Object?> toJson() => {'operationId': operationId, 'accountScope': accountScope,
    'workspaceId': workspaceId, 'supplierId': supplierId, 'receiptId': receiptId,
    'reference': reference, 'reason': reason, 'returnedOn': returnedOn,
    'recordedAt': recordedAt.toUtc().toIso8601String(), 'committedRevision': committedRevision,
    'lines': lines.map((line) => line.toJson()).toList(),
    if (requestedAt != null) 'requestedAt': requestedAt!.toUtc().toIso8601String()};
  static WorkspaceSupplierGoodsReturn fromJson(Object? raw) {
    const keys = {'operationId', 'accountScope', 'workspaceId', 'supplierId', 'receiptId',
      'reference', 'reason', 'returnedOn', 'recordedAt', 'committedRevision', 'lines'};
    if (raw is! Map || !keys.every(raw.containsKey) ||
        !raw.keys.every((key) => keys.contains(key) || key == 'requestedAt') || raw['lines'] is! List ||
        (raw.containsKey('requestedAt') && raw['requestedAt'] is! String)) {
      throw const FormatException('Invalid supplier goods return');
    }
    final result = WorkspaceSupplierGoodsReturn(operationId: raw['operationId'] as String,
      accountScope: raw['accountScope'] as String, workspaceId: raw['workspaceId'] as String,
      supplierId: raw['supplierId'] as String, receiptId: raw['receiptId'] as String,
      reference: raw['reference'] as String, reason: raw['reason'] as String, returnedOn: raw['returnedOn'] as String,
      recordedAt: DateTime.parse(raw['recordedAt'] as String), committedRevision: raw['committedRevision'] as int,
      requestedAt: raw.containsKey('requestedAt') ? DateTime.parse(raw['requestedAt'] as String) : null,
      lines: [for (final line in raw['lines'] as List) WorkspaceSupplierGoodsReturnLine.fromJson(line)]);
    if (!result.valid) throw const FormatException('Invalid supplier goods return');
    return result;
  }
}

/// Frozen retailer request. Commit time/revision are assigned only on posting.
class WorkspaceSupplierGoodsReturnIntent {
  WorkspaceSupplierGoodsReturnIntent({required this.operationId, required this.accountScope,
    required this.workspaceId, required this.supplierId, required this.receiptId,
    required this.reference, required this.reason, required this.returnedOn,
    required this.requestedAt, required List<WorkspaceSupplierGoodsReturnLine> lines})
    : lines = List.unmodifiable(lines);
  final String operationId, accountScope, workspaceId, supplierId, receiptId, reference, reason, returnedOn;
  final DateTime requestedAt;
  final List<WorkspaceSupplierGoodsReturnLine> lines;
  WorkspaceSupplierGoodsReturn commit({required int revision, required DateTime at}) =>
    WorkspaceSupplierGoodsReturn(operationId: operationId, accountScope: accountScope,
      workspaceId: workspaceId, supplierId: supplierId, receiptId: receiptId,
      reference: reference, reason: reason, returnedOn: returnedOn, requestedAt: requestedAt,
      recordedAt: at, committedRevision: revision, lines: lines);
  bool get valid => commit(revision: 2, at: requestedAt).valid;
  Map<String, Object?> toJson() => {'operationId': operationId, 'accountScope': accountScope,
    'workspaceId': workspaceId, 'supplierId': supplierId, 'receiptId': receiptId,
    'reference': reference, 'reason': reason, 'returnedOn': returnedOn,
    'requestedAt': requestedAt.toUtc().toIso8601String(),
    'lines': lines.map((line) => line.toJson()).toList()};
  bool matches(WorkspaceSupplierGoodsReturn record) => record.requestedAt != null &&
    jsonEncode(toJson()) == jsonEncode(fromJson({for (final entry in record.toJson().entries)
      if (entry.key != 'recordedAt' && entry.key != 'committedRevision') entry.key: entry.value}).toJson());
  static WorkspaceSupplierGoodsReturnIntent fromJson(Object? raw) {
    const keys = {'operationId', 'accountScope', 'workspaceId', 'supplierId', 'receiptId',
      'reference', 'reason', 'returnedOn', 'requestedAt', 'lines'};
    if (raw is! Map || raw.length != keys.length || !raw.keys.every(keys.contains) || raw['lines'] is! List) {
      throw const FormatException('Invalid supplier return request');
    }
    final result = WorkspaceSupplierGoodsReturnIntent(operationId: raw['operationId'] as String,
      accountScope: raw['accountScope'] as String, workspaceId: raw['workspaceId'] as String,
      supplierId: raw['supplierId'] as String, receiptId: raw['receiptId'] as String,
      reference: raw['reference'] as String, reason: raw['reason'] as String,
      returnedOn: raw['returnedOn'] as String, requestedAt: DateTime.parse(raw['requestedAt'] as String),
      lines: [for (final line in raw['lines'] as List) WorkspaceSupplierGoodsReturnLine.fromJson(line)]);
    if (!result.valid) throw const FormatException('Invalid supplier return request');
    return result;
  }
}

class WorkspaceSupplierLedger {
  WorkspaceSupplierLedger({
    required this.accountScope,
    required this.workspaceId,
    required this.supplierId,
    required this.supplierName,
    required this.revision,
    required this.asOf,
    required List<WorkspaceSupplierLedgerEntry> entries,
    required this.historyComplete,
    this.openingBalanceMinor,
    this.openingRecord,
    Map<String, WorkspaceSupplierBillAcceptance> purchaseBills = const {},
    Map<String, WorkspaceSupplierGoodsReceipt> goodsReceipts = const {},
    Map<String, WorkspaceSupplierBillGoodsAllocation> billGoodsAllocations = const {},
    Map<String, WorkspaceSupplierBillMoneyAllocation> billMoneyAllocations = const {},
    Map<String, WorkspaceSupplierGoodsReturn> goodsReturns = const {},
    Map<String, WorkspaceSupplierCreditNote> creditNotes = const {},
    Map<String, WorkspaceSupplierShortageClaim> shortageClaims = const {},
    Map<String, WorkspaceSupplierRefund> refunds = const {},
  }) : entries = List.unmodifiable(entries),
       purchaseBills = Map.unmodifiable(purchaseBills),
       goodsReceipts = Map.unmodifiable(goodsReceipts),
       billGoodsAllocations = Map.unmodifiable(billGoodsAllocations),
       billMoneyAllocations = Map.unmodifiable(billMoneyAllocations),
       goodsReturns = Map.unmodifiable(goodsReturns),
       creditNotes = Map.unmodifiable(creditNotes),
       shortageClaims = Map.unmodifiable(shortageClaims),
       refunds = Map.unmodifiable(refunds);

  final String accountScope, workspaceId, supplierId, supplierName;
  final int revision;
  final DateTime asOf;
  final List<WorkspaceSupplierLedgerEntry> entries;
  final bool historyComplete;
  final int? openingBalanceMinor;
  /// Exact reviewed evidence retained by a confirmed opening, not a mutable
  /// pointer to the supplier's newest unposted record.
  final WorkspaceSupplierOpeningRecord? openingRecord;
  final Map<String, WorkspaceSupplierBillAcceptance> purchaseBills;
  final Map<String, WorkspaceSupplierGoodsReceipt> goodsReceipts;
  final Map<String, WorkspaceSupplierBillGoodsAllocation> billGoodsAllocations;
  final Map<String, WorkspaceSupplierBillMoneyAllocation> billMoneyAllocations;
  final Map<String, WorkspaceSupplierGoodsReturn> goodsReturns;
  final Map<String, WorkspaceSupplierCreditNote> creditNotes;
  final Map<String, WorkspaceSupplierShortageClaim> shortageClaims;
  final Map<String, WorkspaceSupplierRefund> refunds;

  static WorkspaceSupplierLedger? confirmedOpening(
    WorkspaceSupplierOpeningRecord record, {
    required String accountScope,
    required String workspaceId,
    required String supplierId,
    required String supplierName,
    required bool qa,
    required DateTime confirmedAt,
  }) {
    if (!record.valid ||
        record.amountMinor == null ||
        record.account != accountScope ||
        record.store != workspaceId ||
        record.supplierId != supplierId ||
        record.qa != qa ||
        confirmedAt.isBefore(record.savedAt)) {
      return null;
    }
    final result = WorkspaceSupplierLedger(
      accountScope: accountScope,
      workspaceId: workspaceId,
      supplierId: supplierId,
      supplierName: supplierName,
      revision: 1,
      asOf: confirmedAt,
      historyComplete: true,
      openingBalanceMinor:
          record.supplierCredit ? -record.amountMinor! : record.amountMinor!,
      openingRecord: record,
      entries: const [],
    );
    return result.valid ? result : null;
  }

  Map<String, Object?> toJson() => {
    'accountScope': accountScope,
    'workspaceId': workspaceId,
    'supplierId': supplierId,
    'supplierName': supplierName,
    'revision': revision,
    'asOf': asOf.toUtc().toIso8601String(),
    'openingBalanceMinor': openingBalanceMinor,
    if (openingRecord != null) 'openingRecord': openingRecord!.toJson(),
    if (purchaseBills.isNotEmpty) 'purchaseBills': purchaseBills.map(
      (id, bill) => MapEntry(id, bill.toJson())),
    if (goodsReceipts.isNotEmpty) 'goodsReceipts': goodsReceipts.map(
      (id, receipt) => MapEntry(id, receipt.toJson())),
    if (billGoodsAllocations.isNotEmpty) 'billGoodsAllocations': billGoodsAllocations.map(
      (id, allocation) => MapEntry(id, allocation.toJson())),
    if (billMoneyAllocations.isNotEmpty) 'billMoneyAllocations': billMoneyAllocations.map(
      (id, allocation) => MapEntry(id, allocation.toJson())),
    if (goodsReturns.isNotEmpty) 'goodsReturns': goodsReturns.map((id, returned) => MapEntry(id, returned.toJson())),
    if (creditNotes.isNotEmpty) 'creditNotes': creditNotes.map((id, note) => MapEntry(id, note.toJson())),
    if (shortageClaims.isNotEmpty) 'shortageClaims': shortageClaims.map((id, claim) => MapEntry(id, claim.toJson())),
    if (refunds.isNotEmpty) 'refunds': refunds.map((id, proof) => MapEntry(id, proof.toJson())),
    'historyComplete': historyComplete,
    'entries': entries.map((entry) => entry.toJson()).toList(),
  };

  static WorkspaceSupplierLedger? fromJson(Object? value) {
    if (value is! Map) {
      return null;
    }
    try {
      if ((value.containsKey('purchaseBills') && value['purchaseBills'] is! Map) ||
          (value.containsKey('goodsReceipts') && value['goodsReceipts'] is! Map) ||
          (value.containsKey('billGoodsAllocations') && value['billGoodsAllocations'] is! Map) ||
          (value.containsKey('billMoneyAllocations') && value['billMoneyAllocations'] is! Map) ||
          (value.containsKey('goodsReturns') && value['goodsReturns'] is! Map) ||
          (value.containsKey('creditNotes') && value['creditNotes'] is! Map) ||
          (value.containsKey('shortageClaims') && value['shortageClaims'] is! Map) ||
          (value.containsKey('refunds') && value['refunds'] is! Map)) {
        return null;
      }
      final result = WorkspaceSupplierLedger(
        accountScope: value['accountScope'] as String,
        workspaceId: value['workspaceId'] as String,
        supplierId: value['supplierId'] as String,
        supplierName: value['supplierName'] as String,
        revision: value['revision'] as int,
        asOf: DateTime.parse(value['asOf'] as String),
        openingBalanceMinor: value['openingBalanceMinor'] as int?,
        openingRecord: value.containsKey('openingRecord')
            ? WorkspaceSupplierOpeningRecord.fromJson(value['openingRecord'])
            : null,
        historyComplete: value['historyComplete'] as bool,
        purchaseBills: {
          for (final entry in ((value['purchaseBills'] as Map?) ?? const {}).entries)
            entry.key as String: WorkspaceSupplierBillAcceptance.fromJson(entry.value),
        },
        goodsReceipts: {
          for (final entry in ((value['goodsReceipts'] as Map?) ?? const {}).entries)
            entry.key as String: WorkspaceSupplierGoodsReceipt.fromJson(entry.value),
        },
        billGoodsAllocations: {
          for (final entry in ((value['billGoodsAllocations'] as Map?) ?? const {}).entries)
            entry.key as String: WorkspaceSupplierBillGoodsAllocation.fromJson(entry.value),
        },
        billMoneyAllocations: {
          for (final entry in ((value['billMoneyAllocations'] as Map?) ?? const {}).entries)
            entry.key as String: WorkspaceSupplierBillMoneyAllocation.fromJson(entry.value),
        },
        goodsReturns: {for (final entry in ((value['goodsReturns'] as Map?) ?? const {}).entries)
          entry.key as String: WorkspaceSupplierGoodsReturn.fromJson(entry.value)},
        creditNotes: {for (final entry in ((value['creditNotes'] as Map?) ?? const {}).entries)
          entry.key as String: WorkspaceSupplierCreditNote.fromJson(entry.value)},
        shortageClaims: {for (final entry in ((value['shortageClaims'] as Map?) ?? const {}).entries)
          entry.key as String: WorkspaceSupplierShortageClaim.fromJson(entry.value)},
        refunds: {for (final entry in ((value['refunds'] as Map?) ?? const {}).entries)
          entry.key as String: WorkspaceSupplierRefund.fromJson(entry.value)},
        entries: [
          for (final entry in value['entries'] as List)
            WorkspaceSupplierLedgerEntry(
              operationId: entry['operationId'] as String,
              orderId: entry['orderId'] as String?,
              purchaseId: entry['purchaseId'] as String?,
              origin: entry.containsKey('origin')
                  ? WorkspaceSupplierEntryOrigin.values.byName(
                      entry['origin'] as String,
                    )
                  : WorkspaceSupplierEntryOrigin.moolSocialOrder,
              reference: entry['reference'] as String,
              billId: entry['billId'] as String?,
              paymentMethod: entry['paymentMethod'] as String?,
              moneyReview: entry.containsKey('moneyReview')
                  ? WorkspaceSupplierMoneyReview.fromJson(entry['moneyReview'])
                  : null,
              kind: WorkspaceSupplierEntryKind.values.byName(
                entry['kind'] as String,
              ),
              amountMinor: entry['amountMinor'] as int,
              postedAt: DateTime.parse(entry['postedAt'] as String),
            ),
        ],
      );
      return result.valid ? result : null;
    } catch (_) {
      return null;
    }
  }

  bool get valid =>
      [
        accountScope,
        workspaceId,
        supplierId,
        supplierName,
      ].every((value) => value.trim().isNotEmpty) &&
      revision > 0 &&
      _amountsValid &&
      _openingProofValid &&
      _purchaseBillsValid &&
      _goodsReceiptsValid &&
      _billGoodsAllocationsValid &&
      _billMoneyAllocationsValid &&
      _goodsReturnsValid &&
      _creditNotesValid &&
      _shortageClaimsValid &&
      _reviewedMoneyValid &&
      _refundsValid &&
      entries.every((entry) => entry.valid && !entry.postedAt.isAfter(asOf)) &&
      entries.map((entry) => entry.operationId).toSet().length ==
          entries.length &&
      entries
              .where((entry) => entry.kind == WorkspaceSupplierEntryKind.bill)
              .map((entry) => entry.billId)
              .toSet()
              .length ==
          entries
              .where((entry) => entry.kind == WorkspaceSupplierEntryKind.bill)
              .length;

  bool get _openingProofValid {
    final opening = openingRecord;
    if (opening == null) return true; // Preserve legacy projections as-is.
    return opening.valid &&
        opening.amountMinor != null &&
        opening.account == accountScope &&
        opening.store == workspaceId &&
        opening.supplierId == supplierId &&
        historyComplete &&
        !opening.savedAt.isAfter(asOf) &&
        openingBalanceMinor ==
            (opening.supplierCredit
                ? -opening.amountMinor!
                : opening.amountMinor!) &&
        opening.bills.every(
          (bill) =>
              bill.copyId.trim().isNotEmpty &&
              bill.draftId.trim().isNotEmpty &&
              bill.copyRevision > 0 &&
              bill.inclusion != WorkspaceOpeningBillInclusion.unknown,
        ) &&
        !entries.any(
          (entry) =>
              entry.kind == WorkspaceSupplierEntryKind.bill &&
              entry.origin == WorkspaceSupplierEntryOrigin.manualPurchase &&
              opening.bills.any(
                (bill) =>
                    (bill.copyId == entry.purchaseId ||
                        bill.draftId == entry.billId) &&
                    bill.inclusion == WorkspaceOpeningBillInclusion.included,
              ),
        );
  }

  bool get _amountsValid {
    if (openingBalanceMinor != null &&
        !_financeAmountValid(openingBalanceMinor!, signed: true)) {
      return false;
    }
    var balance = openingBalanceMinor ?? 0;
    for (final entry in entries) {
      balance += entry.payableDeltaMinor;
      if (!_financeAmountValid(balance, signed: true)) {
        return false;
      }
    }
    return true;
  }

  bool get _purchaseBillsValid {
    if (purchaseBills.isEmpty) {
      return true; // Preserve pre-acceptance checkpoint bytes and projections.
    }
    final opening = openingRecord;
    if (opening == null || !historyComplete || purchaseBills.length > 1000) {
      return false;
    }
    final parsedCutoff = DateTime.parse(opening.asOfDate);
    final cutoff = DateTime.utc(parsedCutoff.year, parsedCutoff.month, parsedCutoff.day);
    final references = purchaseBills.values.map((bill) => (
      bill.copy.draft.invoiceFinancialYear,
      bill.copy.draft.invoiceReference.trim().toUpperCase(),
    ));
    if (references.toSet().length != purchaseBills.length) {
      return false;
    }
    return purchaseBills.entries.every((item) {
      final bill = item.value;
      if (item.key != bill.billId || !bill.valid ||
          bill.copy.supplier.id != supplierId || bill.acceptedAt.isAfter(asOf)) {
        return false;
      }
      final links = opening.bills.where((link) => link.draftId == bill.billId);
      final exactLink = links.length == 1 &&
          links.single.copyId == bill.copy.id &&
          links.single.copyRevision == bill.copy.revision &&
          links.single.inclusion == bill.openingTreatment;
      final historical = !bill.copy.draft.invoiceIssuedDay!.isAfter(cutoff);
      final review = bill.openingReview;
      final explicitReview = review != null && review.openingId == opening.id &&
          review.openingRevision == opening.revision &&
          review.treatment == bill.openingTreatment;
      if (review != null && !explicitReview) return false;
      final acceptedLocal = bill.acceptedAt.toLocal();
      if (bill.copy.draft.invoiceIssuedDay!.isAfter(DateTime.utc(
          acceptedLocal.year, acceptedLocal.month, acceptedLocal.day))) {
        return false;
      }
      // On/before the starting date needs an exact, explicit opening assertion.
      // A date alone never proves the bill is included in the starting amount.
      if ((historical && !exactLink && !explicitReview) ||
          (!historical && bill.openingTreatment != WorkspaceOpeningBillInclusion.excluded) ||
          (links.isNotEmpty && !exactLink)) {
        return false;
      }
      final financial = entries.where((entry) =>
        entry.kind == WorkspaceSupplierEntryKind.bill && entry.billId == bill.billId);
      if (!bill.addsLiability) {
        return financial.isEmpty;
      }
      return financial.length == 1 &&
          financial.single.origin == WorkspaceSupplierEntryOrigin.manualPurchase &&
          financial.single.purchaseId == bill.copy.id &&
          financial.single.amountMinor == bill.amountMinor &&
          financial.single.reference == bill.copy.draft.invoiceReference &&
          financial.single.postedAt == bill.acceptedAt;
    });
  }

  WorkspaceSupplierLedger? acceptReviewedBill(
    WorkspaceSupplierBillAcceptance bill, {required int expectedRevision}) {
    if (!valid || !bill.valid || bill.copy.supplier.id != supplierId) {
      return null;
    }
    final previous = purchaseBills[bill.billId];
    if (previous != null) {
      return jsonEncode(previous.toJson()) == jsonEncode(bill.toJson()) ? this : null;
    }
    if (expectedRevision != revision) {
      return null;
    }
    final next = WorkspaceSupplierLedger(accountScope: accountScope,
      workspaceId: workspaceId, supplierId: supplierId, supplierName: supplierName,
      revision: revision + 1,
      asOf: bill.acceptedAt.isAfter(asOf) ? bill.acceptedAt : asOf,
      historyComplete: historyComplete, openingBalanceMinor: openingBalanceMinor,
      openingRecord: openingRecord, purchaseBills: {...purchaseBills, bill.billId: bill},
      goodsReceipts: goodsReceipts,
      billGoodsAllocations: billGoodsAllocations,
      billMoneyAllocations: billMoneyAllocations,
      goodsReturns: goodsReturns,
      creditNotes: creditNotes,
      shortageClaims: shortageClaims,
      refunds: refunds,
      entries: [...entries, if (bill.addsLiability) WorkspaceSupplierLedgerEntry(
        operationId: 'manual-bill:${bill.billId}',
        reference: bill.copy.draft.invoiceReference,
        origin: WorkspaceSupplierEntryOrigin.manualPurchase,
        purchaseId: bill.copy.id, billId: bill.billId,
        kind: WorkspaceSupplierEntryKind.bill,
        amountMinor: bill.amountMinor!, postedAt: bill.acceptedAt)],
    );
    return next.valid && next.canFollow(this) ? next : null;
  }

  bool get _goodsReceiptsValid {
    if (goodsReceipts.isEmpty) {
      return true;
    }
    if (openingRecord == null || !historyComplete || goodsReceipts.length > 1000) {
      return false;
    }
    final groups = <(String, String), (Object, int)>{};
    for (final entry in goodsReceipts.entries) {
      final receipt = entry.value;
      if (entry.key != receipt.id || !receipt.valid || receipt.recordedAt.isAfter(asOf)) {
        return false;
      }
      for (final line in receipt.lines) {
        final key = (receipt.expectedDeliveryId, line.sourceLineId);
        final previous = groups[key];
        final delivered = (previous?.$2 ?? 0) + line.deliveredMilli;
        if ((previous != null && previous.$1 != line.mappingIdentity) ||
            delivered > 2147483647 ||
            (line.expectedMilli != null && delivered > line.expectedMilli!)) {
          return false;
        }
        groups[key] = (line.mappingIdentity, delivered);
      }
    }
    return true;
  }

  WorkspaceSupplierLedger? receiveGoods(WorkspaceSupplierGoodsReceipt receipt,
      {required int expectedRevision}) {
    if (!valid || !receipt.valid) {
      return null;
    }
    final previous = goodsReceipts[receipt.id];
    if (previous != null) {
      return jsonEncode(previous.toJson()) == jsonEncode(receipt.toJson()) ? this : null;
    }
    if (expectedRevision != revision) {
      return null;
    }
    final next = WorkspaceSupplierLedger(accountScope: accountScope,
      workspaceId: workspaceId, supplierId: supplierId, supplierName: supplierName,
      revision: revision + 1, historyComplete: historyComplete,
      asOf: receipt.recordedAt.isAfter(asOf) ? receipt.recordedAt : asOf,
      entries: entries, openingBalanceMinor: openingBalanceMinor, openingRecord: openingRecord,
      purchaseBills: purchaseBills, goodsReceipts: {...goodsReceipts, receipt.id: receipt},
      billGoodsAllocations: billGoodsAllocations, billMoneyAllocations: billMoneyAllocations,
      goodsReturns: goodsReturns, creditNotes: creditNotes, shortageClaims: shortageClaims,
      refunds: refunds);
    return next.valid && next.canFollow(this) ? next : null;
  }

  bool get _billGoodsAllocationsValid {
    if (billGoodsAllocations.length > 10000) return false;
    final receiptTotals = <(String, String), (int, int)>{};
    final billTotals = <(String, int), (int, int)>{};
    final bindings = <(String, int), Object>{};
    for (final entry in billGoodsAllocations.entries) {
      final link = entry.value;
      final receipt = goodsReceipts[link.receiptId];
      final bill = purchaseBills[link.billId];
      if (!link.valid || entry.key != link.operationId || receipt == null || bill == null ||
          link.copyId != bill.copy.id || link.copyRevision != bill.copy.revision ||
          link.billLineIndex >= bill.copy.draft.goods.length ||
          link.linkedAt.isAfter(asOf) || link.linkedAt.isBefore(receipt.recordedAt) ||
          link.linkedAt.isBefore(bill.acceptedAt)) {
        return false;
      }
      final lines = receipt.lines.where((line) => line.sourceLineId == link.receiptLineId).toList();
      if (lines.length != 1) return false;
      final line = lines.single;
      final printed = bill.copy.draft.goods[link.billLineIndex];
      // No display-name inference or silently repaired legacy product mapping.
      if (printed['productId'] != link.productId || line.productId != link.productId ||
          printed['pack']?.trim() != link.billUnit || line.stockUnit != link.stockUnit ||
          (link.billUnit == link.stockUnit &&
           (link.stockUnitsNumerator != 1 || link.stockUnitsDenominator != 1)) ||
          (link.billUnit == line.purchaseUnit &&
           (link.stockUnitsNumerator != line.unitsPerPack || link.stockUnitsDenominator != 1))) {
        return false;
      }
      final matched = link.acceptedReceiptMilli + link.damagedReceiptMilli;
      if (BigInt.from(link.billQuantityMilli + link.freeBillQuantityMilli) * BigInt.from(link.stockUnitsNumerator) !=
          BigInt.from(matched) * BigInt.from(line.unitsPerPack) * BigInt.from(link.stockUnitsDenominator)) {
        return false;
      }
      final quantity = printed['quantity'] ?? '';
      if (!RegExp(r'^\d+(\.\d{1,3})?$').hasMatch(quantity)) return false;
      final parts = quantity.split('.');
      final invoiced = BigInt.parse(parts[0]) * BigInt.from(1000) +
          (parts.length == 2 ? BigInt.parse(parts[1].padRight(3, '0')) : BigInt.zero);
      if (invoiced > BigInt.from(2147483647)) return false;
      final freeText = (printed['freeQuantity'] ?? '').trim();
      if (freeText.isNotEmpty && !RegExp(r'^\d+(\.\d{1,3})?$').hasMatch(freeText)) return false;
      final freeParts = freeText.isEmpty ? ['0'] : freeText.split('.');
      final free = BigInt.parse(freeParts[0]) * BigInt.from(1000) +
          (freeParts.length == 2 ? BigInt.parse(freeParts[1].padRight(3, '0')) : BigInt.zero);
      if (free > BigInt.from(2147483647) || invoiced + free <= BigInt.zero) return false;
      final receiptKey = (link.receiptId, link.receiptLineId);
      final previous = receiptTotals[receiptKey] ?? (0, 0);
      final accepted = previous.$1 + link.acceptedReceiptMilli;
      final damaged = previous.$2 + link.damagedReceiptMilli;
      if (accepted > line.acceptedMilli || damaged > line.damagedMilli) return false;
      receiptTotals[receiptKey] = (accepted, damaged);
      final billKey = (link.billId, link.billLineIndex);
      final priorBill = billTotals[billKey] ?? (0, 0);
      final paid = priorBill.$1 + link.billQuantityMilli;
      final freeAllocated = priorBill.$2 + link.freeBillQuantityMilli;
      if (BigInt.from(paid) > invoiced || BigInt.from(freeAllocated) > free ||
          (bindings[billKey] != null && bindings[billKey] != link.unitBinding)) {
        return false;
      }
      billTotals[billKey] = (paid, freeAllocated);
      bindings[billKey] = link.unitBinding;
    }
    return true;
  }

  /// Matching existing records adds neither Stock nor a second bill liability.
  WorkspaceSupplierLedger? allocateBillGoods(WorkspaceSupplierBillGoodsAllocation link,
      {required int expectedRevision}) {
    if (!valid || !link.valid) return null;
    final previous = billGoodsAllocations[link.operationId];
    if (previous != null) {
      return jsonEncode(previous.toJson()) == jsonEncode(link.toJson()) ? this : null;
    }
    if (revision != expectedRevision) return null;
    final next = WorkspaceSupplierLedger(accountScope: accountScope, workspaceId: workspaceId,
      supplierId: supplierId, supplierName: supplierName, revision: revision + 1,
      asOf: link.linkedAt.isAfter(asOf) ? link.linkedAt : asOf, entries: entries,
      historyComplete: historyComplete, openingBalanceMinor: openingBalanceMinor,
      openingRecord: openingRecord, purchaseBills: purchaseBills, goodsReceipts: goodsReceipts,
      billGoodsAllocations: {...billGoodsAllocations, link.operationId: link},
      billMoneyAllocations: billMoneyAllocations, goodsReturns: goodsReturns,
      creditNotes: creditNotes, shortageClaims: shortageClaims, refunds: refunds);
    return next.valid && next.canFollow(this) ? next : null;
  }

  bool get _goodsReturnsValid {
    if (goodsReturns.length > 10000 || goodsReturns.values.map((r) => r.committedRevision).toSet().length != goodsReturns.length) {
      return false;
    }
    final used = <(String, String), (int, int)>{};
    for (final pair in goodsReturns.entries) {
      final returned = pair.value, receipt = goodsReceipts[pair.value.receiptId];
      if (pair.key != returned.operationId || !returned.valid || receipt == null ||
          returned.accountScope != accountScope || returned.workspaceId != workspaceId || returned.supplierId != supplierId ||
          returned.committedRevision > revision || returned.recordedAt.isAfter(asOf) ||
          returned.recordedAt.isBefore(receipt.recordedAt) || returned.returnedOn.compareTo(receipt.deliveredOn) < 0) {
        return false;
      }
      for (final line in returned.lines) {
        final source = receipt.lines.where((source) => source.sourceLineId == line.receiptLineId).singleOrNull;
        if (source == null || !line.matches(source)) return false;
        final key = (receipt.id, line.receiptLineId), previous = used[(receipt.id, line.receiptLineId)] ?? (0, 0);
        final totals = (previous.$1 + line.acceptedMilli, previous.$2 + line.damagedMilli);
        if (totals.$1 > source.acceptedMilli || totals.$2 > source.damagedMilli) return false;
        used[key] = totals;
      }
    }
    return true;
  }

  /// Stock movement proof must be committed atomically by the checkpoint owner.
  /// No supplier balance entry is created by returning physical goods.
  WorkspaceSupplierLedger? recordGoodsReturned(WorkspaceSupplierGoodsReturn returned,
      {required int expectedRevision}) {
    if (!valid || !returned.valid || expectedRevision <= 0 || expectedRevision > revision) return null;
    final old = goodsReturns[returned.operationId];
    if (old != null) return jsonEncode(old.toJson()) == jsonEncode(returned.toJson()) ? this : null;
    if (expectedRevision != revision || returned.committedRevision != revision + 1 || returned.recordedAt.isBefore(asOf)) return null;
    final next = WorkspaceSupplierLedger(accountScope: accountScope, workspaceId: workspaceId,
      supplierId: supplierId, supplierName: supplierName, revision: revision + 1, asOf: returned.recordedAt,
      entries: entries, historyComplete: historyComplete, openingBalanceMinor: openingBalanceMinor,
      openingRecord: openingRecord, purchaseBills: purchaseBills, goodsReceipts: goodsReceipts,
      billGoodsAllocations: billGoodsAllocations, billMoneyAllocations: billMoneyAllocations,
      goodsReturns: {...goodsReturns, returned.operationId: returned}, creditNotes: creditNotes,
      shortageClaims: shortageClaims, refunds: refunds);
    return next.valid && next.canFollow(this) ? next : null;
  }

  static int? _claimInvoiceQuantity(String text) {
    if (!RegExp(r'^\d+(\.\d{1,3})?$').hasMatch(text)) return null;
    final parts = text.split('.');
    final amount = BigInt.parse(parts[0]) * BigInt.from(1000) +
      (parts.length == 2 ? BigInt.parse(parts[1].padRight(3, '0')) : BigInt.zero);
    return amount > BigInt.from(2147483647) ? null : amount.toInt();
  }

  /// Matching is bill attribution, not proof that all goods are undamaged or
  /// still held in Stock. Keep billed/free units and receiving exceptions apart.
  ({int totalItems, int matchedItems, bool hasMatches, bool damaged,
    bool shortage, bool returnedOnMatchedDelivery})? goodsProgressFor(WorkspacePurchaseSavedCopy copy) {
    final accepted = purchaseBills[copy.draft.id];
    if (!valid || !historyComplete || accepted == null ||
        jsonEncode(accepted.copy.toJson()) != jsonEncode(copy.toJson()) || copy.draft.goods.isEmpty) {
      return null;
    }
    final links = billGoodsAllocations.values.where((link) => link.billId == copy.draft.id &&
      link.copyId == copy.id && link.copyRevision == copy.revision).toList();
    var matched = 0;
    for (final (index, item) in copy.draft.goods.indexed) {
      final invoiced = _claimInvoiceQuantity((item['quantity'] ?? '').trim());
      final freeText = (item['freeQuantity'] ?? '').trim();
      final free = freeText.isEmpty ? 0 : _claimInvoiceQuantity(freeText);
      if (invoiced == null || free == null || invoiced + free <= 0) return null;
      final itemLinks = links.where((link) => link.billLineIndex == index);
      if (itemLinks.fold<int>(0, (sum, link) => sum + link.billQuantityMilli) == invoiced &&
          itemLinks.fold<int>(0, (sum, link) => sum + link.freeBillQuantityMilli) == free) {
        matched++;
      }
    }
    return (totalItems: copy.draft.goods.length, matchedItems: matched,
      hasMatches: links.isNotEmpty, damaged: links.any((link) => link.damagedReceiptMilli > 0),
      shortage: shortageClaims.values.any((claim) => claim.billId == copy.draft.id &&
        claim.copyId == copy.id && claim.copyRevision == copy.revision),
      returnedOnMatchedDelivery: goodsReturns.values.any((returned) => links.any((link) =>
        link.receiptId == returned.receiptId && returned.lines.any((line) =>
          line.receiptLineId == link.receiptLineId && line.productId == link.productId))));
  }

  WorkspaceSupplierShortageClaim? _deriveShortageClaim({required String operationId,
      required String billId, required int billLineIndex, required String deliveryId,
      required String lineId, required int quantityMilli, required DateTime recordedAt,
      required int committedRevision, List<String>? receiptSnapshot,
      List<String>? allocationSnapshot, DateTime? requestedAt}) {
    final bill = purchaseBills[billId];
    if (bill == null || bill.openingTreatment != WorkspaceOpeningBillInclusion.excluded ||
        billLineIndex < 0 || billLineIndex >= bill.copy.draft.goods.length ||
        recordedAt.isBefore(bill.acceptedAt) || (requestedAt != null &&
          (openingRecord == null || requestedAt.isAfter(recordedAt) || requestedAt.isBefore(bill.acceptedAt)))) { return null; }
    final group = goodsReceipts.values.where((r) => r.expectedDeliveryId == deliveryId &&
      r.lines.any((l) => l.sourceLineId == lineId)).toList();
    final receiptIds = receiptSnapshot ?? group.map((r) => r.id).toList();
    if (receiptIds.isEmpty || receiptIds.toSet().length != receiptIds.length ||
        receiptIds.any((id) => !group.any((r) => r.id == id))) { return null; }
    if (receiptSnapshot != null && group.any((r) =>
        r.recordedAt.isBefore(recordedAt) && !receiptIds.contains(r.id))) { return null; }
    final receipts = receiptIds.map((id) => goodsReceipts[id]!).toList();
    if (receipts.any((r) => r.recordedAt.isAfter(recordedAt) ||
        (requestedAt != null && r.recordedAt.isAfter(requestedAt)))) { return null; }
    final lines = receipts.map((r) => r.lines.singleWhere((l) => l.sourceLineId == lineId)).toList();
    final source = lines.first, printed = bill.copy.draft.goods[billLineIndex];
    if (source.expectedMilli == null || lines.any((l) => l.mappingIdentity != source.mappingIdentity) ||
        printed['productId'] != source.productId || printed['pack']?.trim() != source.purchaseUnit) { return null; }
    final outstanding = source.expectedMilli! - lines.fold<int>(0, (sum, l) => sum + l.deliveredMilli);
    final previousClaims = shortageClaims.values.where((c) => c.committedRevision < committedRevision).toList();
    final priorGroup = previousClaims.where((c) => c.deliverySource == (deliveryId, lineId)).toList();
    final priorTotal = priorGroup.fold<int>(0, (sum, c) => sum + c.quantityMilli);
    final priorBillClaims = previousClaims.where((c) => c.billId == billId && c.billLineIndex == billLineIndex).toList();
    final priorBill = priorBillClaims.fold<int>(0, (sum, c) => sum + c.quantityMilli);
    final relevantClaims = requestedAt == null ? priorGroup : [...priorGroup, ...priorBillClaims];
    if (requestedAt != null && relevantClaims.any((c) => c.recordedAt.isAfter(requestedAt))) return null;
    final allocations = billGoodsAllocations.values.where((a) => a.billId == billId && a.billLineIndex == billLineIndex).toList();
    final allocationIds = allocationSnapshot ?? allocations.map((a) => a.operationId).toList();
    if (allocationIds.toSet().length != allocationIds.length ||
        allocationIds.any((id) => !allocations.any((a) => a.operationId == id))) { return null; }
    if (allocationSnapshot != null && allocations.any((a) =>
        a.linkedAt.isBefore(recordedAt) && !allocationIds.contains(a.operationId))) { return null; }
    final allocated = allocationIds.map((id) => billGoodsAllocations[id]!).toList();
    if (allocated.any((a) => a.linkedAt.isAfter(recordedAt) ||
        (requestedAt != null && a.linkedAt.isAfter(requestedAt)))) { return null; }
    final billQuantity = _claimInvoiceQuantity(printed['quantity'] ?? '');
    final free = _claimInvoiceQuantity((printed['freeQuantity'] ?? '').trim().isEmpty ? '0' : printed['freeQuantity']!);
    if (billQuantity == null || free == null || quantityMilli <= 0 ||
        quantityMilli + priorTotal > outstanding || quantityMilli + priorBill +
          allocated.fold<int>(0, (sum, a) => sum + a.billQuantityMilli + a.freeBillQuantityMilli) > billQuantity + free) { return null; }
    final sortedReceipts = receiptIds.toList()..sort();
    final sortedPrior = relevantClaims.map((c) => c.operationId).toSet().toList()..sort();
    final sortedAllocations = allocationIds.toList()..sort();
    final claim = WorkspaceSupplierShortageClaim(operationId: operationId, accountScope: accountScope,
      workspaceId: workspaceId, supplierId: supplierId, billId: billId, copyId: bill.copy.id,
      copyRevision: bill.copy.revision, billLineIndex: billLineIndex, expectedDeliveryId: deliveryId,
      receiptLineId: lineId, productId: source.productId, purchaseUnit: source.purchaseUnit,
      quantityMilli: quantityMilli, outstandingMilli: outstanding, priorClaimedMilli: priorTotal,
      recordedAt: recordedAt, committedRevision: committedRevision, receiptIds: sortedReceipts,
      priorClaimIds: sortedPrior, billAllocationIds: sortedAllocations,
      requestedAt: requestedAt, openingId: requestedAt == null ? null : openingRecord!.id,
      openingRevision: requestedAt == null ? null : openingRecord!.revision);
    return claim.valid ? claim : null;
  }

  bool get _shortageClaimsValid {
    if (shortageClaims.length > 10000 || shortageClaims.values.map((c) => c.committedRevision).toSet().length != shortageClaims.length) return false;
    for (final pair in shortageClaims.entries) {
      final claim = pair.value;
      if (pair.key != claim.operationId || !claim.valid || claim.committedRevision > revision || claim.recordedAt.isAfter(asOf) ||
          entries.any((e) => e.operationId == claim.operationId) || goodsReturns.containsKey(claim.operationId) ||
          billMoneyAllocations.containsKey(claim.operationId) || billGoodsAllocations.containsKey(claim.operationId) ||
          creditNotes.values.any((n) => n.committedRevision == claim.committedRevision) ||
          goodsReturns.values.any((r) => r.committedRevision == claim.committedRevision) ||
          billMoneyAllocations.values.any((a) => a.committedRevision == claim.committedRevision)) { return false; }
      final reconstructed = _deriveShortageClaim(operationId: claim.operationId, billId: claim.billId,
        billLineIndex: claim.billLineIndex, deliveryId: claim.expectedDeliveryId, lineId: claim.receiptLineId,
        quantityMilli: claim.quantityMilli, recordedAt: claim.recordedAt, committedRevision: claim.committedRevision,
        receiptSnapshot: claim.receiptIds, allocationSnapshot: claim.billAllocationIds, requestedAt: claim.requestedAt);
      if (jsonEncode(reconstructed?.toJson()) != jsonEncode(claim.toJson())) return false;
    }
    return true;
  }

  /// The retailer explicitly confirms this delivery belongs to this bill line.
  /// Derive membership/budgets here from the fresh predecessor; no Stock or money.
  WorkspaceSupplierLedger? recordShortageClaim({required String operationId,
      required String billId, required int billLineIndex, required String deliveryId,
      required String lineId, required int quantityMilli, required bool attributionReviewed,
      required DateTime recordedAt, required int expectedRevision, DateTime? requestedAt}) {
    if (!valid || !attributionReviewed || expectedRevision <= 0 || expectedRevision > revision) return null;
    final old = shortageClaims[operationId];
    if (old != null) {
      return old.billId == billId && old.billLineIndex == billLineIndex && old.expectedDeliveryId == deliveryId &&
        old.receiptLineId == lineId && old.quantityMilli == quantityMilli && old.recordedAt == recordedAt &&
        old.requestedAt == requestedAt ? this : null;
    }
    if (expectedRevision != revision || recordedAt.isBefore(asOf)) return null;
    final claim = _deriveShortageClaim(operationId: operationId, billId: billId,
      billLineIndex: billLineIndex, deliveryId: deliveryId, lineId: lineId, quantityMilli: quantityMilli,
      recordedAt: recordedAt, committedRevision: revision + 1, requestedAt: requestedAt);
    if (claim == null) return null;
    final next = WorkspaceSupplierLedger(accountScope: accountScope, workspaceId: workspaceId,
      supplierId: supplierId, supplierName: supplierName, revision: revision + 1, asOf: recordedAt,
      historyComplete: historyComplete, openingBalanceMinor: openingBalanceMinor, openingRecord: openingRecord,
      entries: entries, purchaseBills: purchaseBills, goodsReceipts: goodsReceipts,
      billGoodsAllocations: billGoodsAllocations, billMoneyAllocations: billMoneyAllocations,
      goodsReturns: goodsReturns, creditNotes: creditNotes,
      shortageClaims: {...shortageClaims, operationId: claim}, refunds: refunds);
    return next.valid && next.canFollow(this) ? next : null;
  }

  WorkspaceSupplierShortageIntent? reviewShortageIntent({required String operationId,
      required String billId, required int billLineIndex, required String deliveryId,
      required String lineId, required int quantityMilli, required bool attributionReviewed,
      required DateTime requestedAt}) {
    if (shortageClaims.containsKey(operationId)) return null;
    final probe = recordShortageClaim(operationId: operationId, billId: billId,
      billLineIndex: billLineIndex, deliveryId: deliveryId, lineId: lineId, quantityMilli: quantityMilli,
      attributionReviewed: attributionReviewed, recordedAt: requestedAt,
      requestedAt: requestedAt, expectedRevision: revision);
    final claim = probe?.shortageClaims[operationId];
    return claim == null ? null : WorkspaceSupplierShortageIntent.fromReview(claim);
  }

  WorkspaceSupplierLedger? recordReviewedShortage(WorkspaceSupplierShortageIntent intent,
      {required DateTime recordedAt, required int expectedRevision, required bool attributionReviewed}) {
    if (!valid || !intent.valid || !attributionReviewed || expectedRevision <= 0 || expectedRevision > revision ||
        intent.accountScope != accountScope || intent.workspaceId != workspaceId || intent.supplierId != supplierId ||
        intent.openingId != openingRecord?.id || intent.openingRevision != openingRecord?.revision) { return null; }
    final old = shortageClaims[intent.operationId];
    if (old != null) return intent.matches(old) ? this : null;
    final next = recordShortageClaim(operationId: intent.operationId, billId: intent.billId,
      billLineIndex: intent.billLineIndex, deliveryId: intent.expectedDeliveryId, lineId: intent.receiptLineId,
      quantityMilli: intent.quantityMilli, attributionReviewed: attributionReviewed, recordedAt: recordedAt,
      requestedAt: intent.requestedAt, expectedRevision: expectedRevision);
    final proof = next?.shortageClaims[intent.operationId];
    return proof != null && intent.matches(proof) ? next : null;
  }

  bool get _creditNotesValid {
    if (creditNotes.length > 10000 ||
        creditNotes.values.map((n) => n.committedRevision).toSet().length != creditNotes.length ||
        creditNotes.values.map((n) => n.reference.toUpperCase()).toSet().length != creditNotes.length) { return false; }
    final quantities = <Object, int>{}, amounts = <String, int>{};
    final billQuantities = <Object, int>{};
    var lastCreditRevision = 0, lastCreditEntry = -1;
    DateTime? lastCreditAt;
    final orderedCredits = creditNotes.entries.toList()
      ..sort((a, b) => a.value.committedRevision.compareTo(b.value.committedRevision));
    for (final pair in orderedCredits) {
      final note = pair.value, bill = purchaseBills[pair.value.billId], opening = openingRecord;
      final entry = entries.where((e) => e.operationId == note.operationId).singleOrNull;
      if (pair.key != note.operationId || !note.valid || opening == null || bill == null ||
          note.accountScope != accountScope || note.workspaceId != workspaceId || note.supplierId != supplierId ||
          note.copyId != bill.copy.id || note.copyRevision != bill.copy.revision ||
          note.openingId != opening.id || note.openingRevision != opening.revision ||
          bill.openingTreatment != WorkspaceOpeningBillInclusion.excluded ||
          note.committedRevision > revision || note.recordedAt.isAfter(asOf) ||
          note.recordedAt.isBefore(bill.acceptedAt) || note.day!.isBefore(bill.copy.draft.invoiceIssuedDay!) ||
          entry == null || entry.kind != WorkspaceSupplierEntryKind.creditNote ||
          entry.origin != WorkspaceSupplierEntryOrigin.manualPurchase || entry.billId != note.billId ||
          entry.purchaseId != note.copyId || entry.reference != note.reference ||
          entry.amountMinor != note.amountMinor || entry.postedAt != note.recordedAt) { return false; }
      final entryIndex = entries.indexOf(entry);
      if (note.committedRevision <= lastCreditRevision || entryIndex <= lastCreditEntry ||
          (lastCreditAt != null && note.recordedAt.isBefore(lastCreditAt))) { return false; }
      lastCreditRevision = note.committedRevision;
      lastCreditEntry = entryIndex;
      lastCreditAt = note.recordedAt;
      amounts[note.billId] = (amounts[note.billId] ?? 0) + note.amountMinor;
      if (amounts[note.billId]! > bill.amountMinor!) return false;
      for (final support in note.supports) {
        final receipt = goodsReceipts[support.receiptId];
        final line = receipt?.lines.where((l) => l.sourceLineId == support.receiptLineId).singleOrNull;
        if (receipt == null || line == null || support.billLineIndex >= bill.copy.draft.goods.length ||
            note.recordedAt.isBefore(receipt.recordedAt) || note.occurredOn.compareTo(receipt.deliveredOn) < 0) { return false; }
        final printed = bill.copy.draft.goods[support.billLineIndex];
        // Exact product identity; return/damage units are bound by the validated
        // billGoodsAllocations below, including their reviewed conversion.
        if (printed['productId'] != line.productId) return false;
        if (support.kind == WorkspaceSupplierCreditSupportKind.shortage) {
          if (printed['pack']?.trim() != line.purchaseUnit) return false;
          final claim = shortageClaims[support.shortageClaimId];
          if (claim == null || claim.billId != note.billId || claim.billLineIndex != support.billLineIndex ||
              claim.copyId != note.copyId || claim.copyRevision != note.copyRevision ||
              claim.receiptLineId != support.receiptLineId || !claim.receiptIds.contains(receipt.id) ||
              claim.committedRevision >= note.committedRevision || claim.recordedAt.isAfter(note.recordedAt)) { return false; }
          final key = support.sourceIdentity;
          quantities[key] = (quantities[key] ?? 0) + support.quantityMilli;
          if (quantities[key]! > claim.quantityMilli) return false;
          continue;
        }
        final links = billGoodsAllocations.values.where((a) =>
          a.receiptId == receipt.id && a.receiptLineId == line.sourceLineId &&
          a.billId == note.billId && a.billLineIndex == support.billLineIndex).toList();
        if (links.isEmpty || links.any((a) => a.linkedAt.isAfter(note.recordedAt))) return false;
        final attributed = links.fold<int>(0, (sum, a) => sum +
          (support.kind == WorkspaceSupplierCreditSupportKind.goodsReturned
            ? a.acceptedReceiptMilli : a.damagedReceiptMilli));
        final billKey = (note.billId, support.billLineIndex, receipt.id, line.sourceLineId, support.kind);
        billQuantities[billKey] = (billQuantities[billKey] ?? 0) + support.quantityMilli;
        if (billQuantities[billKey]! > attributed) return false;
        var capacity = support.kind == WorkspaceSupplierCreditSupportKind.shortage
          ? line.shortMilli : line.damagedMilli;
        if (support.kind == WorkspaceSupplierCreditSupportKind.goodsReturned) {
          final returned = goodsReturns[support.returnOperationId];
          final returnedLine = returned?.lines.where((l) => l.receiptLineId == support.receiptLineId).singleOrNull;
          if (returned == null || returned.receiptId != receipt.id || returnedLine == null ||
              returned.committedRevision >= note.committedRevision ||
              note.recordedAt.isBefore(returned.recordedAt) || note.occurredOn.compareTo(returned.returnedOn) < 0) { return false; }
          // Never-stocked damage has its own source cap, even after hand-back.
          capacity = returnedLine.acceptedMilli;
        }
        final key = support.sourceIdentity;
        quantities[key] = (quantities[key] ?? 0) + support.quantityMilli;
        if (quantities[key]! > capacity) return false;
      }
    }
    return true;
  }

  /// Eligible documentary quantities for the retailer's credit-note review.
  /// These are quantity limits, never an inferred monetary credit amount.
  List<(WorkspaceSupplierCreditSupport, String, String)> availableCreditSupports(String billId) {
    if (!valid || !historyComplete || purchaseBills[billId]?.openingTreatment != WorkspaceOpeningBillInclusion.excluded) return const [];
    final result = <(WorkspaceSupplierCreditSupport, String, String)>[];
    final links = billGoodsAllocations.values.where((a) => a.billId == billId).toList();
    final groups = links.map((a) => (a.receiptId, a.receiptLineId, a.billLineIndex)).toSet();
    final credited = creditNotes.values.expand((n) => n.supports.map((s) => (n.billId, s))).toList();
    for (final group in groups) {
      final receipt = goodsReceipts[group.$1]!;
      final line = receipt.lines.singleWhere((l) => l.sourceLineId == group.$2);
      final allocated = links.where((a) => a.receiptId == group.$1 && a.receiptLineId == group.$2 && a.billLineIndex == group.$3).toList();
      final damageUsed = credited.where((p) => p.$2.kind == WorkspaceSupplierCreditSupportKind.arrivalDamage &&
        p.$2.receiptId == receipt.id && p.$2.receiptLineId == line.sourceLineId).toList();
      final damageGlobal = line.damagedMilli - damageUsed.fold<int>(0, (sum, p) => sum + p.$2.quantityMilli);
      final damageBill = allocated.fold<int>(0, (sum, a) => sum + a.damagedReceiptMilli) -
        damageUsed.where((p) => p.$1 == billId && p.$2.billLineIndex == group.$3)
          .fold<int>(0, (sum, p) => sum + p.$2.quantityMilli);
      final damage = damageGlobal < damageBill ? damageGlobal : damageBill;
      if (damage > 0) { result.add((WorkspaceSupplierCreditSupport(kind: WorkspaceSupplierCreditSupportKind.arrivalDamage,
        receiptId: receipt.id, receiptLineId: line.sourceLineId, billLineIndex: group.$3, quantityMilli: damage),
        '${line.productLabel} · Damaged on arrival', line.purchaseUnit)); }
      final returnedBillUsed = credited.where((p) => p.$1 == billId && p.$2.kind == WorkspaceSupplierCreditSupportKind.goodsReturned &&
        p.$2.receiptId == receipt.id && p.$2.receiptLineId == line.sourceLineId && p.$2.billLineIndex == group.$3)
        .fold<int>(0, (sum, p) => sum + p.$2.quantityMilli);
      final returnedBill = allocated.fold<int>(0, (sum, a) => sum + a.acceptedReceiptMilli) - returnedBillUsed;
      for (final returned in goodsReturns.values.where((r) => r.receiptId == receipt.id)) {
        final returnedLine = returned.lines.where((l) => l.receiptLineId == line.sourceLineId).singleOrNull;
        if (returnedLine == null) continue;
        final used = credited.where((p) => p.$2.kind == WorkspaceSupplierCreditSupportKind.goodsReturned &&
          p.$2.returnOperationId == returned.operationId && p.$2.receiptLineId == line.sourceLineId)
          .fold<int>(0, (sum, p) => sum + p.$2.quantityMilli);
        final global = returnedLine.acceptedMilli - used;
        final remaining = global < returnedBill ? global : returnedBill;
        if (remaining > 0) { result.add((WorkspaceSupplierCreditSupport(kind: WorkspaceSupplierCreditSupportKind.goodsReturned,
          receiptId: receipt.id, receiptLineId: line.sourceLineId, billLineIndex: group.$3,
          quantityMilli: remaining, returnOperationId: returned.operationId),
          '${line.productLabel} · Returned · ${returned.reference}', line.purchaseUnit)); }
      }
    }
    for (final claim in shortageClaims.values.where((c) => c.billId == billId)) {
      final used = credited.where((p) => p.$2.shortageClaimId == claim.operationId)
        .fold<int>(0, (sum, p) => sum + p.$2.quantityMilli);
      final remaining = claim.quantityMilli - used;
      if (remaining <= 0) continue;
      final receipt = goodsReceipts[claim.receiptIds.first]!;
      final line = receipt.lines.singleWhere((l) => l.sourceLineId == claim.receiptLineId);
      result.add((WorkspaceSupplierCreditSupport(kind: WorkspaceSupplierCreditSupportKind.shortage,
        shortageClaimId: claim.operationId, receiptId: receipt.id, receiptLineId: line.sourceLineId,
        billLineIndex: claim.billLineIndex, quantityMilli: remaining), '${line.productLabel} · Short delivery', claim.purchaseUnit));
    }
    return List.unmodifiable(result);
  }

  WorkspaceSupplierLedger? recordSupplierCredit(WorkspaceSupplierCreditNote note,
      {required int expectedRevision}) {
    if (!valid || !note.valid || expectedRevision <= 0 || expectedRevision > revision) return null;
    final old = creditNotes[note.operationId];
    if (old != null) return jsonEncode(old.toJson()) == jsonEncode(note.toJson()) ? this : null;
    if (expectedRevision != revision || note.committedRevision != revision + 1 ||
        note.recordedAt.isBefore(asOf)) { return null; }
    final next = WorkspaceSupplierLedger(accountScope: accountScope, workspaceId: workspaceId,
      supplierId: supplierId, supplierName: supplierName, revision: revision + 1, asOf: note.recordedAt,
      historyComplete: historyComplete, openingBalanceMinor: openingBalanceMinor, openingRecord: openingRecord,
      purchaseBills: purchaseBills, goodsReceipts: goodsReceipts, goodsReturns: goodsReturns,
      billGoodsAllocations: billGoodsAllocations, billMoneyAllocations: billMoneyAllocations,
      creditNotes: {...creditNotes, note.operationId: note},
      shortageClaims: shortageClaims,
      refunds: refunds,
      entries: [...entries, WorkspaceSupplierLedgerEntry(operationId: note.operationId,
        reference: note.reference, origin: WorkspaceSupplierEntryOrigin.manualPurchase,
        purchaseId: note.copyId, billId: note.billId, kind: WorkspaceSupplierEntryKind.creditNote,
        amountMinor: note.amountMinor, postedAt: note.recordedAt)]);
    return next.valid && next.canFollow(this) ? next : null;
  }

  int? get balanceMinor =>
      !valid || !historyComplete || openingBalanceMinor == null
      ? null
      : entries.fold<int>(
          openingBalanceMinor!,
          (total, entry) => total + entry.payableDeltaMinor,
        );

  int? get payableMinor {
    final balance = balanceMinor;
    return balance == null ? null : (balance > 0 ? balance : 0);
  }

  int? get creditMinor {
    final balance = balanceMinor;
    return balance == null ? null : (balance < 0 ? -balance : 0);
  }

  /// Read-only preflight. Posting must atomically consume this exact source
  /// together with the ledger entry; a positive result is not posting authority.
  /// Conservative policy requires both source capacity and net supplier credit.
  int? reviewedRefundCapacity(WorkspaceSupplierRefundIntent intent, {DateTime? checkedAt}) {
    final opening = openingRecord;
    final at = checkedAt ?? intent.requestedAt;
    if (!valid || !intent.valid || !historyComplete || opening == null ||
        intent.accountScope != accountScope || intent.workspaceId != workspaceId ||
        intent.supplierId != supplierId || intent.qa != opening.qa ||
        intent.openingId != opening.id || intent.openingRevision != opening.revision ||
        at.isBefore(asOf) || at.isBefore(intent.requestedAt) ||
        intent.occurredOn.compareTo(opening.asOfDate) < 0) {
      return null;
    }
    final credit = creditMinor;
    if (credit == null) return null;
    final capacity = _refundSourceCapacity(intent, entries.length, revision + 1, at);
    if (capacity == null || capacity < 0) return null;
    return capacity < credit ? capacity : credit;
  }

  /// Re-derive capacity from facts preceding this refund, not its own proof or
  /// later credits. Allocation revisions provide order for non-money entries.
  int? _refundSourceCapacity(WorkspaceSupplierRefundIntent intent, int entryLimit, int revisionLimit, DateTime at) {
    final prior = entries.take(entryLimit).toList();
    final priorRefunds = refunds.values.where((r) => r.committedRevision < revisionLimit);
    final priorLinks = billMoneyAllocations.values.where((a) => a.committedRevision < revisionLimit);
    if (priorLinks.any((link) => link.recordedAt.isAfter(at))) return null;
    int? capacity;
    switch (intent.sourceKind) {
      case WorkspaceSupplierRefundSourceKind.openingAdvance:
        capacity = _moneySourceAmount(WorkspaceSupplierMoneySourceKind.openingAdvance, intent.sourceId);
      case WorkspaceSupplierRefundSourceKind.accountAdvance:
        final source = prior.where((entry) => entry.operationId == intent.sourceId).toList();
        if (source.length != 1 || source.single.moneyReview == null ||
            intent.occurredOn.compareTo(source.single.moneyReview!.occurredOn) < 0) {
          return null;
        }
        capacity = _moneySourceAmount(WorkspaceSupplierMoneySourceKind.accountAdvance, intent.sourceId);
      case WorkspaceSupplierRefundSourceKind.manualBillSurplus:
        final bill = purchaseBills[intent.sourceId];
        if (bill == null || bill.copy.id != intent.copyId ||
            bill.copy.revision != intent.copyRevision ||
            bill.openingTreatment != WorkspaceOpeningBillInclusion.excluded ||
            !prior.any((e) => e.kind == WorkspaceSupplierEntryKind.bill && e.billId == bill.billId)) {
          return null;
        }
        final refundDay = DateTime.parse('${intent.occurredOn}T00:00:00Z');
        final invoiceDay = bill.copy.draft.invoiceIssuedDay;
        final fundingLinks = priorLinks.where((a) => a.billId == bill.billId).toList();
        if (fundingLinks.any((link) =>
            link.sourceKind == WorkspaceSupplierMoneySourceKind.manualBillSurplus
              ? intent.occurredOn.compareTo(link.recordedAt.toLocal().toIso8601String().substring(0, 10)) < 0
              : link.sourceKind != WorkspaceSupplierMoneySourceKind.openingAdvance &&
                !prior.any((entry) => entry.operationId == link.sourceId && entry.moneyReview != null &&
                  intent.occurredOn.compareTo(entry.moneyReview!.occurredOn) >= 0))) {
          return null;
        }
        if (invoiceDay == null || refundDay.isBefore(invoiceDay) ||
            creditNotes.values.any((note) => note.billId == bill.billId &&
              note.committedRevision < revisionLimit &&
              intent.occurredOn.compareTo(note.occurredOn) < 0) ||
            prior.any((entry) => entry.billId == bill.billId &&
              entry.kind == WorkspaceSupplierEntryKind.payment &&
              (entry.moneyReview == null ||
                intent.occurredOn.compareTo(entry.moneyReview!.occurredOn) < 0))) {
          return null;
        }
        if (prior.any((e) => e.billId == bill.billId &&
            e.kind == WorkspaceSupplierEntryKind.refund && !refunds.containsKey(e.operationId))) {
          return null;
        }
        final paid = prior.where((e) => e.billId == bill.billId &&
          e.kind == WorkspaceSupplierEntryKind.payment && e.origin == WorkspaceSupplierEntryOrigin.manualPurchase)
          .fold<int>(0, (sum, e) => sum + e.amountMinor);
        final allocated = priorLinks.where((a) => a.billId == bill.billId)
          .fold<int>(0, (sum, a) => sum + a.amountMinor);
        final credited = creditNotes.values.where((n) => n.billId == bill.billId &&
          n.committedRevision < revisionLimit && prior.any((e) => e.operationId == n.operationId))
          .fold<int>(0, (sum, n) => sum + n.amountMinor);
        final returnedMoney = priorRefunds.where((r) =>
          r.intent.sourceKind == WorkspaceSupplierRefundSourceKind.manualBillSurplus &&
          r.intent.sourceId == bill.billId).fold<int>(0, (sum, r) => sum + r.intent.amountMinor);
        final transferred = priorLinks.where((a) =>
          a.sourceKind == WorkspaceSupplierMoneySourceKind.manualBillSurplus && a.sourceId == bill.billId)
          .fold<int>(0, (sum, a) => sum + a.amountMinor);
        final remaining = bill.amountMinor! - paid - allocated - credited + returnedMoney + transferred;
        capacity = remaining < 0 ? -remaining : 0;
    }
    if (capacity == null) return null;
    if (intent.sourceKind != WorkspaceSupplierRefundSourceKind.manualBillSurplus) {
      final kind = intent.sourceKind == WorkspaceSupplierRefundSourceKind.openingAdvance
        ? WorkspaceSupplierMoneySourceKind.openingAdvance : WorkspaceSupplierMoneySourceKind.accountAdvance;
      capacity -= priorLinks.where((a) => a.sourceKind == kind && a.sourceId == intent.sourceId)
        .fold<int>(0, (sum, a) => sum + a.amountMinor);
      capacity -= priorRefunds.where((r) => r.intent.sourceKind == intent.sourceKind &&
        r.intent.sourceId == intent.sourceId).fold<int>(0, (sum, r) => sum + r.intent.amountMinor);
    }
    return capacity;
  }

  bool get _refundsValid {
    if (refunds.isEmpty) return true; // Retain legacy facts; not new posting authority.
    final opening = openingRecord;
    if (opening == null || !historyComplete || refunds.length > 10000 ||
        refunds.values.map((r) => r.committedRevision).toSet().length != refunds.length ||
        refunds.values.map((r) => r.intent.reference.toUpperCase()).toSet().length != refunds.length) {
      return false;
    }
    var running = openingBalanceMinor!, found = 0, lastRevision = 0;
    DateTime? lastAt;
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i], proof = refunds[entries[i].operationId];
      if (proof != null) {
        final intent = proof.intent;
        final capacity = _refundSourceCapacity(intent, i, proof.committedRevision, proof.recordedAt);
        if (!proof.valid || !intent.valid ||
            intent.accountScope != accountScope || intent.workspaceId != workspaceId ||
            intent.supplierId != supplierId || intent.qa != opening.qa ||
            intent.openingId != opening.id || intent.openingRevision != opening.revision ||
            intent.occurredOn.compareTo(opening.asOfDate) < 0 ||
            proof.committedRevision > revision || proof.committedRevision <= lastRevision ||
            creditNotes.values.any((n) => n.committedRevision == proof.committedRevision) ||
            shortageClaims.values.any((c) => c.committedRevision == proof.committedRevision) ||
            goodsReturns.values.any((r) => r.committedRevision == proof.committedRevision) ||
            billMoneyAllocations.values.any((a) => a.committedRevision == proof.committedRevision) ||
            proof.recordedAt.isAfter(asOf) || proof.recordedAt.isBefore(opening.savedAt) ||
            entries.take(i).any((e) => e.postedAt.isAfter(proof.recordedAt)) ||
            (lastAt != null && proof.recordedAt.isBefore(lastAt)) ||
            jsonEncode(entry.toJson()) != jsonEncode(proof.entry.toJson()) ||
            capacity == null || capacity < intent.amountMinor ||
            running >= 0 || intent.amountMinor > -running ||
            billMoneyAllocations.containsKey(intent.operationId) ||
            goodsReturns.containsKey(intent.operationId) || creditNotes.containsKey(intent.operationId) ||
            shortageClaims.containsKey(intent.operationId)) {
          return false;
        }
        if (intent.sourceKind != WorkspaceSupplierRefundSourceKind.manualBillSurplus) {
          final kind = intent.sourceKind == WorkspaceSupplierRefundSourceKind.openingAdvance
            ? WorkspaceSupplierMoneySourceKind.openingAdvance : WorkspaceSupplierMoneySourceKind.accountAdvance;
          final total = billMoneyAllocations.values.where((a) => a.sourceKind == kind && a.sourceId == intent.sourceId)
            .fold<int>(0, (sum, a) => sum + a.amountMinor) +
            refunds.values.where((r) => r.intent.sourceKind == intent.sourceKind && r.intent.sourceId == intent.sourceId)
              .fold<int>(0, (sum, r) => sum + r.intent.amountMinor);
          final sourceAmount = _moneySourceAmount(kind, intent.sourceId);
          if (sourceAmount == null || total > sourceAmount) return false;
        }
        lastRevision = proof.committedRevision;
        lastAt = proof.recordedAt;
        found++;
      }
      running += entry.payableDeltaMinor;
    }
    return found == refunds.length && refunds.entries.every((p) => p.key == p.value.intent.operationId);
  }

  /// Exact proof is checked before fresh capacity, so a lost acknowledgement
  /// cannot consume funds twice after the ledger or UI eligibility has changed.
  WorkspaceSupplierLedger? recordReviewedRefund(WorkspaceSupplierRefundIntent intent, {
    required int expectedRevision, required DateTime recordedAt,
  }) {
    if (!valid || !intent.valid || expectedRevision <= 0 || expectedRevision > revision) {
      return null;
    }
    final old = refunds[intent.operationId];
    if (old != null) {
      return jsonEncode(old.intent.toJson()) == jsonEncode(intent.toJson()) ? this : null;
    }
    if (expectedRevision != revision || recordedAt.isBefore(asOf) ||
        (reviewedRefundCapacity(intent, checkedAt: recordedAt) ?? -1) < intent.amountMinor ||
        entries.any((e) => e.operationId == intent.operationId) ||
        billMoneyAllocations.containsKey(intent.operationId) || goodsReturns.containsKey(intent.operationId) ||
        shortageClaims.containsKey(intent.operationId)) {
      return null;
    }
    final proof = intent.commit(revision: revision + 1, at: recordedAt);
    final next = WorkspaceSupplierLedger(accountScope: accountScope, workspaceId: workspaceId,
      supplierId: supplierId, supplierName: supplierName, revision: revision + 1, asOf: recordedAt,
      historyComplete: historyComplete, openingBalanceMinor: openingBalanceMinor, openingRecord: openingRecord,
      purchaseBills: purchaseBills, goodsReceipts: goodsReceipts, billGoodsAllocations: billGoodsAllocations,
      billMoneyAllocations: billMoneyAllocations, goodsReturns: goodsReturns, creditNotes: creditNotes,
      shortageClaims: shortageClaims, refunds: {...refunds, intent.operationId: proof},
      entries: [...entries, proof.entry]);
    return next.valid && next.canFollow(this) ? next : null;
  }

  /// An opening-included invoice has no independently reviewed remaining due.
  /// Unallocated supplier-account money never silently settles a specific bill.
  int? manualBillRemainingMinor(String billId) {
    if (!valid || !historyComplete || openingRecord == null) return null;
    return _manualBillRemainingMinor(billId);
  }

  int? _manualBillRemainingMinor(String billId) {
    final bill = purchaseBills[billId];
    if (bill == null || bill.openingTreatment != WorkspaceOpeningBillInclusion.excluded) {
      return null;
    }
    if (entries.any((entry) => entry.billId == billId &&
        ((entry.kind == WorkspaceSupplierEntryKind.creditNote && !creditNotes.containsKey(entry.operationId)) ||
          (entry.kind == WorkspaceSupplierEntryKind.refund && !refunds.containsKey(entry.operationId)) ||
          (entry.origin == WorkspaceSupplierEntryOrigin.manualPurchase &&
            entry.kind == WorkspaceSupplierEntryKind.payment && entry.moneyReview == null)))) {
      return null;
    }
    final paid = entries.where((entry) =>
      entry.origin == WorkspaceSupplierEntryOrigin.manualPurchase &&
      entry.kind == WorkspaceSupplierEntryKind.payment && entry.billId == billId)
      .fold<int>(0, (total, entry) => total + entry.amountMinor);
    final allocated = billMoneyAllocations.values.where((link) => link.billId == billId)
      .fold<int>(0, (total, link) => total + link.amountMinor);
    final credited = creditNotes.values.where((note) => note.billId == billId)
      .fold<int>(0, (total, note) => total + note.amountMinor);
    final refunded = refunds.values.where((r) => r.intent.sourceKind == WorkspaceSupplierRefundSourceKind.manualBillSurplus &&
      r.intent.sourceId == billId).fold<int>(0, (sum, r) => sum + r.intent.amountMinor);
    final transferred = billMoneyAllocations.values.where((a) =>
      a.sourceKind == WorkspaceSupplierMoneySourceKind.manualBillSurplus && a.sourceId == billId)
      .fold<int>(0, (sum, a) => sum + a.amountMinor);
    return bill.amountMinor! - paid - allocated - credited + refunded + transferred;
  }

  /// Replay only the entry prefix and typed revisions preceding an attribution.
  /// Later payments/credits cannot retroactively fund an earlier transfer.
  int? _billSurplusAt(String billId, int entryLimit, int revisionLimit, DateTime at) {
    final bill = purchaseBills[billId];
    if (bill == null || bill.openingTreatment != WorkspaceOpeningBillInclusion.excluded ||
        entryLimit < 0 || entryLimit > entries.length || bill.acceptedAt.isAfter(at)) { return null; }
    final prior = entries.take(entryLimit).toList();
    bool inPrefix(String id) => prior.any((e) => e.operationId == id);
    if (creditNotes.values.any((n) => (n.committedRevision < revisionLimit) != inPrefix(n.operationId)) ||
        refunds.values.any((r) => (r.committedRevision < revisionLimit) != inPrefix(r.intent.operationId)) ||
        billMoneyAllocations.values.any((a) => a.committedRevision < revisionLimit && a.recordedAt.isAfter(at))) {
      return null;
    }
    if (!prior.any((e) => e.kind == WorkspaceSupplierEntryKind.bill && e.billId == billId) ||
        prior.any((e) => e.postedAt.isAfter(at)) ||
        prior.any((e) => e.billId == billId &&
          ((e.kind == WorkspaceSupplierEntryKind.creditNote &&
            (!creditNotes.containsKey(e.operationId) || creditNotes[e.operationId]!.committedRevision >= revisionLimit)) ||
           (e.kind == WorkspaceSupplierEntryKind.refund &&
            (!refunds.containsKey(e.operationId) || refunds[e.operationId]!.committedRevision >= revisionLimit)) ||
           (e.kind == WorkspaceSupplierEntryKind.payment && e.moneyReview == null)))) { return null; }
    final paid = prior.where((e) => e.billId == billId &&
      e.origin == WorkspaceSupplierEntryOrigin.manualPurchase && e.kind == WorkspaceSupplierEntryKind.payment)
      .fold<int>(0, (sum, e) => sum + e.amountMinor);
    final links = billMoneyAllocations.values.where((a) => a.committedRevision < revisionLimit);
    final incoming = links.where((a) => a.billId == billId).fold<int>(0, (sum, a) => sum + a.amountMinor);
    final outgoing = links.where((a) => a.sourceKind == WorkspaceSupplierMoneySourceKind.manualBillSurplus &&
      a.sourceId == billId).fold<int>(0, (sum, a) => sum + a.amountMinor);
    final credited = creditNotes.values.where((n) => n.billId == billId && n.committedRevision < revisionLimit &&
      prior.any((e) => e.operationId == n.operationId)).fold<int>(0, (sum, n) => sum + n.amountMinor);
    final refunded = refunds.values.where((r) => r.committedRevision < revisionLimit &&
      r.intent.sourceKind == WorkspaceSupplierRefundSourceKind.manualBillSurplus && r.intent.sourceId == billId &&
      prior.any((e) => e.operationId == r.intent.operationId)).fold<int>(0, (sum, r) => sum + r.intent.amountMinor);
    final residual = bill.amountMinor! - paid - incoming - credited + outgoing + refunded;
    return residual < 0 ? -residual : 0;
  }

  int? _moneySourceAmount(WorkspaceSupplierMoneySourceKind kind, String id) {
    final opening = openingRecord;
    if (opening == null || !historyComplete) return null;
    // Refund attribution is not inferred from net credit. Its separate source
    // consumption adapter must qualify before affected funds can be assigned.
    if (entries.any((e) => e.origin == WorkspaceSupplierEntryOrigin.supplierAccount &&
        e.kind == WorkspaceSupplierEntryKind.refund && !refunds.containsKey(e.operationId))) {
      return null;
    }
    if (kind == WorkspaceSupplierMoneySourceKind.openingAdvance) {
      return opening.supplierCredit && opening.id == id ? opening.amountMinor : null;
    }
    if (kind == WorkspaceSupplierMoneySourceKind.manualBillSurplus) {
      return _billSurplusAt(id, entries.length, revision + 1, asOf);
    }
    final found = entries.where((e) => e.operationId == id).toList();
    if (found.length != 1) return null;
    final money = found.single;
    return money.origin == WorkspaceSupplierEntryOrigin.supplierAccount && money.moneyReview != null &&
      money.kind == (kind == WorkspaceSupplierMoneySourceKind.accountAdvance
        ? WorkspaceSupplierEntryKind.advance : WorkspaceSupplierEntryKind.payment)
      ? money.amountMinor : null;
  }

  /// Unassigned attribution capacity, NOT another available-cash/credit balance.
  int? unallocatedMoneyMinor(WorkspaceSupplierMoneySourceKind kind, String id) {
    if (!valid) return null;
    final amount = _moneySourceAmount(kind, id);
    if (amount == null) return null;
    // Surplus already includes both outgoing links and actual refunds.
    if (kind == WorkspaceSupplierMoneySourceKind.manualBillSurplus) return amount;
    final refundKind = kind == WorkspaceSupplierMoneySourceKind.openingAdvance
      ? WorkspaceSupplierRefundSourceKind.openingAdvance : WorkspaceSupplierRefundSourceKind.accountAdvance;
    final refunded = kind == WorkspaceSupplierMoneySourceKind.accountPayment ? 0 :
      refunds.values.where((r) => r.intent.sourceKind == refundKind && r.intent.sourceId == id)
        .fold<int>(0, (sum, r) => sum + r.intent.amountMinor);
    return amount - billMoneyAllocations.values.where((a) => a.sourceKind == kind && a.sourceId == id)
      .fold<int>(0, (sum, a) => sum + a.amountMinor) - refunded;
  }

  /// Reconciles aggregate dues against known excluded manual-bill residuals.
  /// Positive means other/unassigned dues; negative means unassigned credit.
  /// It is not labelled "opening due" because other account facts can contribute.
  int? get unassignedAccountBalanceMinor {
    final balance = balanceMinor;
    if (balance == null) return null;
    var assignedBillDues = 0;
    for (final bill in purchaseBills.values.where(
      (b) => b.openingTreatment == WorkspaceOpeningBillInclusion.excluded)) {
      final remaining = _manualBillRemainingMinor(bill.billId);
      if (remaining == null) return null;
      assignedBillDues += remaining;
    }
    return balance - assignedBillDues;
  }

  bool get _billMoneyAllocationsValid {
    if (billMoneyAllocations.isEmpty) return true;
    final opening = openingRecord;
    if (opening == null || !historyComplete || billMoneyAllocations.length > 10000 ||
        billMoneyAllocations.values.map((a) => a.committedRevision).toSet().length != billMoneyAllocations.length) {
      return false;
    }
    final used = <(WorkspaceSupplierMoneySourceKind, String), int>{};
    for (final pair in billMoneyAllocations.entries) {
      final link = pair.value;
      final bill = purchaseBills[link.billId];
      final surplus = link.sourceKind == WorkspaceSupplierMoneySourceKind.manualBillSurplus;
      final sourceBill = surplus ? purchaseBills[link.sourceId] : null;
      final capacity = surplus && link.sourceEntryCount != null
        ? _billSurplusAt(link.sourceId, link.sourceEntryCount!, link.committedRevision, link.recordedAt)
        : _moneySourceAmount(link.sourceKind, link.sourceId);
      if (pair.key != link.operationId || !link.valid || link.accountScope != accountScope ||
          link.workspaceId != workspaceId || link.supplierId != supplierId ||
          link.openingId != opening.id || link.openingRevision != opening.revision ||
          link.committedRevision > revision || link.recordedAt.isAfter(asOf) ||
          link.recordedAt.isBefore(opening.savedAt) || capacity == null || bill == null ||
          bill.openingTreatment != WorkspaceOpeningBillInclusion.excluded ||
          bill.copy.id != link.copyId || bill.copy.revision != link.copyRevision ||
          link.recordedAt.isBefore(bill.acceptedAt) || _manualBillRemainingMinor(link.billId) == null ||
          entries.where((e) => e.billId == link.billId &&
            e.origin == WorkspaceSupplierEntryOrigin.manualPurchase &&
            e.kind == WorkspaceSupplierEntryKind.payment)
            .fold<int>(0, (sum, e) => sum + e.amountMinor) +
            billMoneyAllocations.values.where((a) => a.billId == link.billId)
              .fold<int>(0, (sum, a) => sum + a.amountMinor) > bill.amountMinor!) {
        return false;
      }
      if (surplus) {
        if (sourceBill == null || sourceBill.copy.id != link.sourceCopyId ||
            sourceBill.copy.revision != link.sourceCopyRevision || capacity < link.amountMinor ||
            !entries.take(link.sourceEntryCount!).any((e) =>
              e.kind == WorkspaceSupplierEntryKind.bill && e.billId == link.billId)) { return false; }
        continue;
      }
      if (link.sourceKind != WorkspaceSupplierMoneySourceKind.openingAdvance &&
          entries.singleWhere((e) => e.operationId == link.sourceId).postedAt.isAfter(link.recordedAt)) {
        return false;
      }
      final source = (link.sourceKind, link.sourceId);
      used[source] = (used[source] ?? 0) + link.amountMinor;
      if (used[source]! > capacity) return false;
    }
    return true;
  }

  WorkspaceSupplierLedger? allocateRecordedMoney(WorkspaceSupplierBillMoneyAllocation link,
      {required int expectedRevision}) {
    if (!valid || !link.valid || expectedRevision <= 0 || expectedRevision > revision) return null;
    final old = billMoneyAllocations[link.operationId];
    if (old != null) return jsonEncode(old.toJson()) == jsonEncode(link.toJson()) ? this : null;
    if (expectedRevision != revision || link.committedRevision != revision + 1 ||
        (_manualBillRemainingMinor(link.billId) ?? -1) < link.amountMinor) { return null; }
    if (link.sourceKind == WorkspaceSupplierMoneySourceKind.manualBillSurplus &&
        (link.sourceEntryCount != entries.length ||
          (_moneySourceAmount(link.sourceKind, link.sourceId) ?? -1) < link.amountMinor)) { return null; }
    final next = WorkspaceSupplierLedger(accountScope: accountScope, workspaceId: workspaceId,
      supplierId: supplierId, supplierName: supplierName, revision: revision + 1,
      asOf: link.recordedAt.isAfter(asOf) ? link.recordedAt : asOf, entries: entries,
      historyComplete: historyComplete, openingBalanceMinor: openingBalanceMinor,
      openingRecord: openingRecord, purchaseBills: purchaseBills, goodsReceipts: goodsReceipts,
      billGoodsAllocations: billGoodsAllocations,
      billMoneyAllocations: {...billMoneyAllocations, link.operationId: link}, goodsReturns: goodsReturns,
      creditNotes: creditNotes, shortageClaims: shortageClaims, refunds: refunds);
    return next.valid && next.canFollow(this) ? next : null;
  }

  bool get _reviewedMoneyValid {
    final paidByBill = <String, int>{};
    var running = openingBalanceMinor ?? 0;
    for (final entry in entries) {
      final balanceBefore = running;
      running += entry.payableDeltaMinor;
      final review = entry.moneyReview;
      final manualPayment = entry.origin == WorkspaceSupplierEntryOrigin.manualPurchase &&
          entry.kind == WorkspaceSupplierEntryKind.payment;
      if (review == null) continue; // Decode legacy evidence, not new admission.
      final opening = openingRecord;
      if (opening == null || !historyComplete ||
          review.openingId != opening.id || review.openingRevision != opening.revision ||
          !review.valid || entry.paymentMethod?.trim().isNotEmpty != true) {
        return false;
      }
      final posted = entry.postedAt.toLocal();
      if (review.day!.isAfter(DateTime.utc(posted.year, posted.month, posted.day))) {
        return false;
      }
      if (entry.origin == WorkspaceSupplierEntryOrigin.supplierAccount) {
        if (entry.billId != null) return false;
        // An account payment settles dues. Extra money is a separately reviewed
        // advance, never an implicit conversion of an overpayment.
        if (entry.kind == WorkspaceSupplierEntryKind.payment &&
            entry.amountMinor > (balanceBefore > 0 ? balanceBefore : 0)) {
          return false;
        }
        continue;
      }
      if (!manualPayment) return false;
      if (entry.amountMinor > (balanceBefore > 0 ? balanceBefore : 0)) return false;
      final bill = purchaseBills[entry.billId];
      if (bill == null || bill.copy.id != entry.purchaseId ||
          bill.openingTreatment != WorkspaceOpeningBillInclusion.excluded ||
          entry.postedAt.isBefore(bill.acceptedAt) ||
          entries.any((other) => other.billId == entry.billId &&
            ((other.kind == WorkspaceSupplierEntryKind.creditNote && !creditNotes.containsKey(other.operationId)) ||
              (other.kind == WorkspaceSupplierEntryKind.refund && !refunds.containsKey(other.operationId)) ||
              (other.origin == WorkspaceSupplierEntryOrigin.manualPurchase &&
                other.kind == WorkspaceSupplierEntryKind.payment && other.moneyReview == null)))) {
        return false;
      }
      final paid = (paidByBill[bill.billId] ?? 0) + entry.amountMinor;
      final allocated = billMoneyAllocations.values.where((a) => a.billId == bill.billId)
        .fold<int>(0, (sum, a) => sum + a.amountMinor);
      if (paid + allocated > bill.amountMinor!) return false;
      paidByBill[bill.billId] = paid;
    }
    return true;
  }

  /// One reviewed money fact; advances and account payments need no goods or
  /// platform order. Replaying an identical operation returns this same ledger.
  WorkspaceSupplierLedger? recordReviewedMoney(WorkspaceSupplierLedgerEntry entry,
      {required int expectedRevision}) {
    if (entry.moneyReview == null ||
        (entry.kind != WorkspaceSupplierEntryKind.payment &&
          entry.kind != WorkspaceSupplierEntryKind.advance) ||
        entry.origin == WorkspaceSupplierEntryOrigin.moolSocialOrder ||
        (entry.kind == WorkspaceSupplierEntryKind.advance &&
          entry.origin != WorkspaceSupplierEntryOrigin.supplierAccount)) {
      return null;
    }
    return appendConfirmed(entry, expectedRevision: expectedRevision);
  }

  WorkspaceSupplierLedger? appendConfirmed(
    WorkspaceSupplierLedgerEntry entry, {
    required int expectedRevision,
  }) {
    if (!valid ||
        !entry.valid ||
        expectedRevision <= 0 ||
        expectedRevision > revision) {
      return null;
    }
    final existing = entries.where(
      (item) => item.operationId == entry.operationId,
    );
    if (existing.isNotEmpty) {
      return jsonEncode(existing.single.toJson()) == jsonEncode(entry.toJson())
          ? this
          : null;
    }
    if (expectedRevision != revision) {
      return null;
    }
    if (entry.origin != WorkspaceSupplierEntryOrigin.moolSocialOrder &&
        (entry.kind == WorkspaceSupplierEntryKind.payment ||
          entry.kind == WorkspaceSupplierEntryKind.advance) && entry.moneyReview == null) {
      return null;
    }
    if (entry.origin == WorkspaceSupplierEntryOrigin.manualPurchase &&
        (entry.kind == WorkspaceSupplierEntryKind.creditNote ||
          entry.kind == WorkspaceSupplierEntryKind.refund)) { return null; }
    if (entry.origin != WorkspaceSupplierEntryOrigin.moolSocialOrder &&
        entry.kind == WorkspaceSupplierEntryKind.refund) {
      return null;
    }
    if (entry.origin == WorkspaceSupplierEntryOrigin.manualPurchase &&
        entry.kind == WorkspaceSupplierEntryKind.payment &&
        (_manualBillRemainingMinor(entry.billId ?? '') ?? -1) < entry.amountMinor) { return null; }
    final next = WorkspaceSupplierLedger(
      accountScope: accountScope,
      workspaceId: workspaceId,
      supplierId: supplierId,
      supplierName: supplierName,
      revision: revision + 1,
      asOf: entry.postedAt.isAfter(asOf) ? entry.postedAt : asOf,
      entries: [...entries, entry],
      historyComplete: historyComplete,
      openingBalanceMinor: openingBalanceMinor,
      openingRecord: openingRecord,
      purchaseBills: purchaseBills,
      goodsReceipts: goodsReceipts,
      billGoodsAllocations: billGoodsAllocations,
      billMoneyAllocations: billMoneyAllocations,
      goodsReturns: goodsReturns,
      creditNotes: creditNotes,
      shortageClaims: shortageClaims,
      refunds: refunds,
    );
    return next.valid && next.canFollow(this) ? next : null;
  }

  bool canFollow(WorkspaceSupplierLedger previous) {
    if (!valid ||
        !previous.valid ||
        accountScope != previous.accountScope ||
        workspaceId != previous.workspaceId ||
        supplierId != previous.supplierId ||
        revision < previous.revision ||
        asOf.isBefore(previous.asOf) ||
        openingBalanceMinor != previous.openingBalanceMinor ||
        jsonEncode(openingRecord?.toJson()) !=
            jsonEncode(previous.openingRecord?.toJson()) ||
        (previous.historyComplete && !historyComplete) ||
        entries.length < previous.entries.length) {
      return false;
    }
    for (var i = 0; i < previous.entries.length; i++) {
      if (jsonEncode(entries[i].toJson()) !=
          jsonEncode(previous.entries[i].toJson())) {
        return false;
      }
    }
    for (final entry in entries.skip(previous.entries.length)) {
      if (entry.origin != WorkspaceSupplierEntryOrigin.moolSocialOrder &&
          (entry.kind == WorkspaceSupplierEntryKind.payment ||
            entry.kind == WorkspaceSupplierEntryKind.advance) && entry.moneyReview == null) {
        return false;
      }
      if (entry.origin == WorkspaceSupplierEntryOrigin.manualPurchase &&
          ((entry.kind == WorkspaceSupplierEntryKind.creditNote && !creditNotes.containsKey(entry.operationId)) ||
            (entry.kind == WorkspaceSupplierEntryKind.refund && !refunds.containsKey(entry.operationId)))) { return false; }
      if (entry.origin != WorkspaceSupplierEntryOrigin.moolSocialOrder &&
          entry.kind == WorkspaceSupplierEntryKind.refund && !refunds.containsKey(entry.operationId)) {
        return false;
      }
    }
    for (final entry in previous.purchaseBills.entries) {
      if (jsonEncode(purchaseBills[entry.key]?.toJson()) != jsonEncode(entry.value.toJson())) {
        return false;
      }
    }
    for (final entry in previous.goodsReceipts.entries) {
      if (jsonEncode(goodsReceipts[entry.key]?.toJson()) != jsonEncode(entry.value.toJson())) {
        return false;
      }
    }
    for (final entry in previous.billGoodsAllocations.entries) {
      if (jsonEncode(billGoodsAllocations[entry.key]?.toJson()) != jsonEncode(entry.value.toJson())) {
        return false;
      }
    }
    for (final entry in previous.billMoneyAllocations.entries) {
      if (jsonEncode(billMoneyAllocations[entry.key]?.toJson()) != jsonEncode(entry.value.toJson())) return false;
    }
    for (final entry in previous.goodsReturns.entries) {
      if (jsonEncode(goodsReturns[entry.key]?.toJson()) != jsonEncode(entry.value.toJson())) return false;
    }
    for (final entry in previous.creditNotes.entries) {
      if (jsonEncode(creditNotes[entry.key]?.toJson()) != jsonEncode(entry.value.toJson())) return false;
    }
    for (final entry in previous.shortageClaims.entries) {
      if (jsonEncode(shortageClaims[entry.key]?.toJson()) != jsonEncode(entry.value.toJson())) return false;
    }
    for (final entry in previous.refunds.entries) {
      if (jsonEncode(refunds[entry.key]?.toJson()) != jsonEncode(entry.value.toJson())) return false;
    }
    final addedRefunds = refunds.values.where((r) => !previous.refunds.containsKey(r.intent.operationId)).toList();
    if (addedRefunds.isNotEmpty) {
      if (addedRefunds.length != 1 || revision != previous.revision + 1 ||
          entries.length != previous.entries.length + 1 ||
          purchaseBills.length != previous.purchaseBills.length || goodsReceipts.length != previous.goodsReceipts.length ||
          goodsReturns.length != previous.goodsReturns.length || creditNotes.length != previous.creditNotes.length ||
          shortageClaims.length != previous.shortageClaims.length ||
          billGoodsAllocations.length != previous.billGoodsAllocations.length ||
          billMoneyAllocations.length != previous.billMoneyAllocations.length) {
        return false;
      }
      final proof = addedRefunds.single;
      if (proof.committedRevision != revision || proof.recordedAt != asOf ||
          (previous.reviewedRefundCapacity(proof.intent, checkedAt: proof.recordedAt) ?? -1) < proof.intent.amountMinor ||
          jsonEncode(entries.last.toJson()) != jsonEncode(proof.entry.toJson())) {
        return false;
      }
    }
    final addedClaims = shortageClaims.values.where((c) => !previous.shortageClaims.containsKey(c.operationId)).toList();
    if (addedClaims.isNotEmpty) {
      if (addedClaims.length != 1 || revision != previous.revision + 1 ||
          entries.length != previous.entries.length || creditNotes.length != previous.creditNotes.length ||
          goodsReceipts.length != previous.goodsReceipts.length || goodsReturns.length != previous.goodsReturns.length ||
          purchaseBills.length != previous.purchaseBills.length ||
          billGoodsAllocations.length != previous.billGoodsAllocations.length ||
          billMoneyAllocations.length != previous.billMoneyAllocations.length ||
          refunds.length != previous.refunds.length) { return false; }
      final claim = addedClaims.single;
      if (claim.committedRevision != revision || claim.recordedAt.isBefore(previous.asOf)) return false;
      final derived = previous._deriveShortageClaim(operationId: claim.operationId, billId: claim.billId,
        billLineIndex: claim.billLineIndex, deliveryId: claim.expectedDeliveryId, lineId: claim.receiptLineId,
        quantityMilli: claim.quantityMilli, recordedAt: claim.recordedAt, committedRevision: revision,
        requestedAt: claim.requestedAt);
      if (jsonEncode(derived?.toJson()) != jsonEncode(claim.toJson())) return false;
    }
    final addedCredits = creditNotes.values.where((n) => !previous.creditNotes.containsKey(n.operationId)).toList();
    if (addedCredits.isNotEmpty) {
      // A credit is one immutable revision, never a manufactured batch of
      // supporting receipts/returns and a new bill in the same transition.
      if (addedCredits.length != 1 || revision != previous.revision + 1 ||
          entries.length != previous.entries.length + 1 ||
          goodsReceipts.length != previous.goodsReceipts.length ||
          goodsReturns.length != previous.goodsReturns.length ||
          purchaseBills.length != previous.purchaseBills.length ||
          billGoodsAllocations.length != previous.billGoodsAllocations.length ||
          billMoneyAllocations.length != previous.billMoneyAllocations.length) { return false; }
      if (shortageClaims.length != previous.shortageClaims.length || refunds.length != previous.refunds.length) return false;
      final note = addedCredits.single;
      if (note.committedRevision != revision || note.recordedAt.isBefore(previous.asOf) ||
          !previous.purchaseBills.containsKey(note.billId) ||
          entries.last.operationId != note.operationId ||
          note.supports.any((s) => !previous.goodsReceipts.containsKey(s.receiptId) ||
            (s.returnOperationId != null && !previous.goodsReturns.containsKey(s.returnOperationId)) ||
            (s.shortageClaimId != null && !previous.shortageClaims.containsKey(s.shortageClaimId)))) { return false; }
    }
    final newlySettled = <String, int>{};
    for (final entry in entries.skip(previous.entries.length).where((e) =>
      e.origin == WorkspaceSupplierEntryOrigin.manualPurchase && e.kind == WorkspaceSupplierEntryKind.payment)) {
      final id = entry.billId!;
      newlySettled[id] = (newlySettled[id] ?? 0) + entry.amountMinor;
    }
    for (final link in billMoneyAllocations.values.where((a) => !previous.billMoneyAllocations.containsKey(a.operationId))) {
      newlySettled[link.billId] = (newlySettled[link.billId] ?? 0) + link.amountMinor;
    }
    for (final pair in newlySettled.entries) {
      if (pair.value > (previous._manualBillRemainingMinor(pair.key) ?? -1)) return false;
    }
    for (final returned in goodsReturns.values.where((r) => !previous.goodsReturns.containsKey(r.operationId))) {
      if (returned.committedRevision <= previous.revision || returned.committedRevision > revision ||
          returned.recordedAt.isBefore(previous.asOf) || !previous.goodsReceipts.containsKey(returned.receiptId)) {
        return false;
      }
    }
    for (final link in billMoneyAllocations.values.where((a) => !previous.billMoneyAllocations.containsKey(a.operationId))) {
      if (link.committedRevision <= previous.revision || link.committedRevision > revision ||
          link.recordedAt.isBefore(previous.asOf) ||
          !previous.purchaseBills.containsKey(link.billId) ||
          previous._moneySourceAmount(link.sourceKind, link.sourceId) == null) {
        return false;
      }
      if (link.sourceKind == WorkspaceSupplierMoneySourceKind.manualBillSurplus &&
          (revision != previous.revision + 1 || link.committedRevision != revision ||
            link.sourceEntryCount != previous.entries.length || entries.length != previous.entries.length ||
            purchaseBills.length != previous.purchaseBills.length || creditNotes.length != previous.creditNotes.length ||
            refunds.length != previous.refunds.length || goodsReceipts.length != previous.goodsReceipts.length ||
            goodsReturns.length != previous.goodsReturns.length || shortageClaims.length != previous.shortageClaims.length ||
            billGoodsAllocations.length != previous.billGoodsAllocations.length ||
            billMoneyAllocations.length != previous.billMoneyAllocations.length + 1 ||
            (previous._moneySourceAmount(link.sourceKind, link.sourceId) ?? -1) < link.amountMinor)) { return false; }
    }
    return revision > previous.revision ||
        (entries.length == previous.entries.length &&
            purchaseBills.length == previous.purchaseBills.length &&
            goodsReceipts.length == previous.goodsReceipts.length &&
            billGoodsAllocations.length == previous.billGoodsAllocations.length &&
            billMoneyAllocations.length == previous.billMoneyAllocations.length &&
            goodsReturns.length == previous.goodsReturns.length &&
            creditNotes.length == previous.creditNotes.length &&
            shortageClaims.length == previous.shortageClaims.length &&
            refunds.length == previous.refunds.length &&
            historyComplete == previous.historyComplete &&
            asOf.isAtSameMomentAs(previous.asOf) &&
            supplierName == previous.supplierName);
  }
}

class WorkspacePurchaseLine {
  const WorkspacePurchaseLine({
    required this.id,
    required this.productId,
    required this.name,
    required this.pack,
    required this.orderedPacks,
    required this.unitPriceMinor,
    this.receivedPacks,
  });
  final String id, productId, name, pack;
  final int orderedPacks, unitPriceMinor;
  final int? receivedPacks;
  bool get valid =>
      id.trim().isNotEmpty &&
      productId.trim().isNotEmpty &&
      name.trim().isNotEmpty &&
      orderedPacks > 0 &&
      unitPriceMinor >= 0 &&
      (receivedPacks == null || receivedPacks! >= 0);
}

/// Versioned, read-only shipment facts. Link identities must come from an
/// authenticated purchase adapter, never a display name or a URL parameter.
/// Rendering a receipt does not post stock or authorize payment.
/// Confirmed cumulative receipt facts saved atomically with their stock effect.
/// This is separate from editable counts and from payment/delivery authority.
class WorkspaceConfirmedPurchaseReceipt {
  WorkspaceConfirmedPurchaseReceipt({
    required this.accountScope,
    required this.workspaceId,
    required this.supplierId,
    required this.orderId,
    required this.shipmentId,
    required this.purchaseId,
    required this.revision,
    required this.reference,
    required this.confirmedAt,
    required List<WorkspacePurchaseLine> lines,
  }) : lines = List.unmodifiable(lines);

  factory WorkspaceConfirmedPurchaseReceipt.fromPurchase(
    WorkspacePurchaseRecord p,
  ) => WorkspaceConfirmedPurchaseReceipt(
    accountScope: p.accountScope,
    workspaceId: p.workspaceId,
    supplierId: p.supplierId,
    orderId: p.orderId,
    shipmentId: p.shipmentId,
    purchaseId: p.purchaseId,
    revision: p.revision,
    reference: p.receiptReference ?? '',
    confirmedAt: p.updatedAt,
    lines: p.lines,
  );

  final String accountScope,
      workspaceId,
      supplierId,
      orderId,
      shipmentId,
      reference;
  final String? purchaseId;
  final int revision;
  final DateTime confirmedAt;
  final List<WorkspacePurchaseLine> lines;

  bool get valid =>
      [
        accountScope,
        workspaceId,
        supplierId,
        orderId,
        shipmentId,
        reference,
      ].every((value) => value.trim().isNotEmpty) &&
      revision > 0 &&
      lines.isNotEmpty &&
      lines.map((line) => line.id).toSet().length == lines.length &&
      lines.every(
        (line) =>
            line.valid &&
            line.receivedPacks != null &&
            line.receivedPacks! <= line.orderedPacks,
      );

  bool belongsTo(WorkspacePurchaseRecord p) =>
      valid &&
      p.valid &&
      accountScope == p.accountScope &&
      workspaceId == p.workspaceId &&
      supplierId == p.supplierId &&
      orderId == p.orderId &&
      shipmentId == p.shipmentId &&
      purchaseId == p.purchaseId &&
      lines.length == p.lines.length &&
      lines.every(
        (line) => p.lines.any(
          (other) =>
              line.id == other.id &&
              line.productId == other.productId &&
              line.pack == other.pack &&
              line.orderedPacks == other.orderedPacks &&
              line.unitPriceMinor == other.unitPriceMinor,
        ),
      );

  bool canFollow(WorkspaceConfirmedPurchaseReceipt old) =>
      valid &&
      old.valid &&
      accountScope == old.accountScope &&
      workspaceId == old.workspaceId &&
      supplierId == old.supplierId &&
      orderId == old.orderId &&
      shipmentId == old.shipmentId &&
      purchaseId == old.purchaseId &&
      revision >= old.revision &&
      !confirmedAt.isBefore(old.confirmedAt) &&
      lines.length == old.lines.length &&
      lines.every(
        (line) => old.lines.any(
          (prior) =>
              line.id == prior.id &&
              line.productId == prior.productId &&
              line.pack == prior.pack &&
              line.orderedPacks == prior.orderedPacks &&
              line.unitPriceMinor == prior.unitPriceMinor &&
              line.receivedPacks! >= prior.receivedPacks!,
        ),
      ) &&
      (revision != old.revision ||
          jsonEncode(toJson()) == jsonEncode(old.toJson()));

  WorkspacePurchaseRecord applyTo(WorkspacePurchaseRecord p) {
    if (!belongsTo(p)) {
      throw StateError('Receipt identity conflicts with purchase');
    }
    return WorkspacePurchaseRecord(
      accountScope: p.accountScope,
      workspaceId: p.workspaceId,
      supplierId: p.supplierId,
      supplierName: p.supplierName,
      orderId: p.orderId,
      shipmentId: p.shipmentId,
      purchaseId: p.purchaseId,
      procurementContext: p.procurementContext,
      revision: p.revision > revision ? p.revision : revision,
      createdAt: p.createdAt,
      updatedAt: p.updatedAt.isAfter(confirmedAt) ? p.updatedAt : confirmedAt,
      stage: p.stage,
      amountMinor: p.amountMinor,
      itemSummary: p.itemSummary,
      paymentLabel: p.paymentLabel,
      paymentTermLabel: p.paymentTermLabel,
      balanceDueLabel: p.balanceDueLabel,
      paymentMethod: p.paymentMethod,
      purchaseOrderReference: p.purchaseOrderReference,
      expectedArrival: p.expectedArrival,
      address: p.address,
      deliveryPartner: p.deliveryPartner,
      trackingReference: p.trackingReference,
      invoiceReference: p.invoiceReference,
      receiptState:
          lines.every((line) => line.receivedPacks == line.orderedPacks)
          ? WorkspaceReceiptState.confirmed
          : WorkspaceReceiptState.partial,
      receiptReference: reference,
      updateNote: p.updateNote,
      lines: [
        for (final line in p.lines)
          WorkspacePurchaseLine(
            id: line.id,
            productId: line.productId,
            name: line.name,
            pack: line.pack,
            orderedPacks: line.orderedPacks,
            unitPriceMinor: line.unitPriceMinor,
            receivedPacks: lines
                .singleWhere((saved) => saved.id == line.id)
                .receivedPacks,
          ),
      ],
    );
  }

  Map<String, Object?> toJson() => {
    'accountScope': accountScope,
    'workspaceId': workspaceId,
    'supplierId': supplierId,
    'orderId': orderId,
    'shipmentId': shipmentId,
    'purchaseId': purchaseId,
    'revision': revision,
    'reference': reference,
    'confirmedAt': confirmedAt.toUtc().toIso8601String(),
    'lines': [
      for (final line in lines)
        {
          'id': line.id,
          'productId': line.productId,
          'name': line.name,
          'pack': line.pack,
          'orderedPacks': line.orderedPacks,
          'unitPriceMinor': line.unitPriceMinor,
          'receivedPacks': line.receivedPacks,
        },
    ],
  };

  static WorkspaceConfirmedPurchaseReceipt? fromJson(Object? value) {
    try {
      final raw = value as Map;
      final result = WorkspaceConfirmedPurchaseReceipt(
        accountScope: raw['accountScope'] as String,
        workspaceId: raw['workspaceId'] as String,
        supplierId: raw['supplierId'] as String,
        orderId: raw['orderId'] as String,
        shipmentId: raw['shipmentId'] as String,
        purchaseId: raw['purchaseId'] as String?,
        revision: raw['revision'] as int,
        reference: raw['reference'] as String,
        confirmedAt: DateTime.parse(raw['confirmedAt'] as String),
        lines: [
          for (final line in raw['lines'] as List)
            WorkspacePurchaseLine(
              id: line['id'] as String,
              productId: line['productId'] as String,
              name: line['name'] as String,
              pack: line['pack'] as String,
              orderedPacks: line['orderedPacks'] as int,
              unitPriceMinor: line['unitPriceMinor'] as int,
              receivedPacks: line['receivedPacks'] as int,
            ),
        ],
      );
      return result.valid ? result : null;
    } catch (_) {
      return null;
    }
  }
}

class WorkspacePurchaseRecord {
  WorkspacePurchaseRecord({
    required this.accountScope,
    required this.workspaceId,
    required this.supplierId,
    required this.supplierName,
    required this.orderId,
    required this.shipmentId,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    required this.stage,
    required this.amountMinor,
    required this.itemSummary,
    required this.paymentLabel,
    required List<WorkspacePurchaseLine> lines,
    this.purchaseId,
    this.procurementContext,
    this.expectedArrival,
    this.address,
    this.deliveryPartner,
    this.trackingReference,
    this.invoiceReference,
    this.receiptState = WorkspaceReceiptState.unavailable,
    this.receiptReference,
    this.updateNote,
    this.paymentTermLabel,
    this.balanceDueLabel,
    this.paymentMethod,
    this.purchaseOrderReference,
  }) : lines = List.unmodifiable(lines);

  final String accountScope,
      workspaceId,
      supplierId,
      supplierName,
      orderId,
      shipmentId;
  final int revision, amountMinor;
  final DateTime createdAt, updatedAt;
  final WorkspaceSupplyStage stage;
  final String itemSummary, paymentLabel;
  final String? paymentTermLabel,
      balanceDueLabel,
      paymentMethod,
      purchaseOrderReference;
  final List<WorkspacePurchaseLine> lines;
  final String? purchaseId,
      expectedArrival,
      address,
      deliveryPartner,
      trackingReference,
      invoiceReference,
      receiptReference,
      updateNote;
  final WorkspaceReceiptState receiptState;

  /// Trusted originating purchase scope, never inferred from current browsing.
  /// Older records may render, but cannot open scoped tracking without it.
  final BuyV2ProcurementContext? procurementContext;

  bool get valid =>
      [
        accountScope,
        workspaceId,
        supplierId,
        supplierName,
        orderId,
        shipmentId,
      ].every((value) => value.trim().isNotEmpty) &&
      revision > 0 &&
      amountMinor >= 0 &&
      (procurementContext == null ||
          (procurementContext!.hasIdentity &&
              procurementContext!.accountId == accountScope &&
              procurementContext!.storeId == workspaceId)) &&
      !updatedAt.isBefore(createdAt) &&
      lines.every((line) => line.valid) &&
      lines.map((line) => line.id).toSet().length == lines.length;

  /// Buy owns order content. This projection adds only the separately supplied
  /// trusted Store/supplier link; it cannot infer that link from Buy history.
  /// A Buy order is one fulfilment group here. Further shipment splits require
  /// explicit allocations from the receiving adapter, not a copied full order.
  factory WorkspacePurchaseRecord.fromBuyOrder({
    required BuyV2Order order,
    required String accountScope,
    required String workspaceId,
    required String supplierId,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
    BuyV2ProcurementContext? procurementContext,
  }) {
    if (order.destination != BuyV2Destination.wholesale) {
      throw ArgumentError(
        'Only an explicitly linked wholesale order is supported',
      );
    }
    return WorkspacePurchaseRecord(
      accountScope: accountScope,
      workspaceId: workspaceId,
      supplierId: supplierId,
      supplierName: order.partner,
      orderId: order.id,
      shipmentId: order.id,
      purchaseId: order.purchaseId,
      procurementContext: procurementContext,
      revision: revision,
      createdAt: createdAt,
      updatedAt: updatedAt,
      stage: switch (order.status) {
        BuyV2OrderStatus.preparing => WorkspaceSupplyStage.ordered,
        BuyV2OrderStatus.confirmed => WorkspaceSupplyStage.confirmed,
        BuyV2OrderStatus.dispatched => WorkspaceSupplyStage.dispatched,
        BuyV2OrderStatus.arriving => WorkspaceSupplyStage.arriving,
        BuyV2OrderStatus.delivered => WorkspaceSupplyStage.delivered,
      },
      amountMinor: order.total * 100,
      itemSummary: order.itemSummary,
      paymentLabel: order.paymentStatusLabel ?? 'Payment update unavailable',
      paymentTermLabel: order.paymentTermLabel,
      balanceDueLabel: order.balanceDueLabel,
      paymentMethod: order.paymentMethod,
      purchaseOrderReference: order.purchaseOrderReference,
      expectedArrival: order.updatedDeliveryEstimate ?? order.promise,
      address: order.addressLine,
      deliveryPartner: order.deliveryPartnerName,
      trackingReference: order.trackingReference,
      receiptReference: order.receiptReference,
      lines: [
        for (var i = 0; i < order.lines.length; i++)
          WorkspacePurchaseLine(
            id: '${order.id}:$i',
            productId: order.lines[i].product.id,
            name: order.lines[i].product.title,
            pack: order.lines[i].product.pack,
            orderedPacks: order.lines[i].quantity,
            unitPriceMinor: order.lines[i].product.price * 100,
          ),
      ],
    );
  }
}

enum WorkFeedFilter { forYou, jobs, freelance, campaigns, nearby }

extension WorkFeedFilterLabel on WorkFeedFilter {
  String get label => switch (this) {
    WorkFeedFilter.forYou => 'For You',
    WorkFeedFilter.jobs => 'Jobs',
    WorkFeedFilter.freelance => 'Freelance',
    WorkFeedFilter.campaigns => 'Campaigns',
    WorkFeedFilter.nearby => 'Nearby',
  };
}

enum WorkReviewStage { none, drafting, gstPending, approved, setup, live }

enum WorkspaceStoreState { open, paused, off }

enum WorkspaceDashboardState { ready, refreshing, offline, failed }

enum WorkspacePaidRequirementState {
  draft,
  clarification,
  published,
  closed,
  full,
}

class WorkspaceProductCompliance {
  const WorkspaceProductCompliance({
    this.genericName,
    this.netQuantity,
    this.manufacturerName,
    this.packerName,
    this.importerName,
    this.countryOfOrigin,
    this.manufacturedOrPackedOn,
    this.bestBeforeOrUseBy,
    this.fssaiLicenseNumber,
    this.consumerCare,
  });

  final String? genericName;
  final String? netQuantity;
  final String? manufacturerName;
  final String? packerName;
  final String? importerName;
  final String? countryOfOrigin;
  final String? manufacturedOrPackedOn;
  final String? bestBeforeOrUseBy;
  final String? fssaiLicenseNumber;
  final String? consumerCare;

  Map<String, Object?> toJson() => {
    'genericName': genericName,
    'netQuantity': netQuantity,
    'manufacturerName': manufacturerName,
    'packerName': packerName,
    'importerName': importerName,
    'countryOfOrigin': countryOfOrigin,
    'manufacturedOrPackedOn': manufacturedOrPackedOn,
    'bestBeforeOrUseBy': bestBeforeOrUseBy,
    'fssaiLicenseNumber': fssaiLicenseNumber,
    'consumerCare': consumerCare,
  };

  static WorkspaceProductCompliance? fromJson(Object? value) {
    if (value == null) return null;
    if (value is! Map) {
      throw const FormatException('Invalid product information');
    }
    String? field(String key) {
      final raw = value[key];
      if (raw == null) return null;
      if (raw is! String) {
        throw const FormatException('Invalid product information');
      }
      final text = raw.trim();
      return text.isEmpty ? null : text;
    }

    return WorkspaceProductCompliance(
      genericName: field('genericName'),
      netQuantity: field('netQuantity'),
      manufacturerName: field('manufacturerName'),
      packerName: field('packerName'),
      importerName: field('importerName'),
      countryOfOrigin: field('countryOfOrigin'),
      manufacturedOrPackedOn: field('manufacturedOrPackedOn'),
      bestBeforeOrUseBy: field('bestBeforeOrUseBy'),
      fssaiLicenseNumber: field('fssaiLicenseNumber'),
      consumerCare: field('consumerCare'),
    );
  }

  BuyV2ProductCompliance toBuyPublicCompliance() => BuyV2ProductCompliance(
    genericName: genericName,
    netQuantity: netQuantity,
    manufacturerName: manufacturerName,
    packerName: packerName,
    importerName: importerName,
    countryOfOrigin: countryOfOrigin,
    manufacturedOrPackedOnLabel: manufacturedOrPackedOn,
    bestBeforeOrUseByLabel: bestBeforeOrUseBy,
    fssaiLicenseNumber: fssaiLicenseNumber,
    consumerCare: consumerCare,
  );
}

/// Purchased facts from the order, never reconstructed from today's catalogue.
/// Prices are INR minor units (paise); line total includes the order's line
/// adjustments and is not recalculated by the display layer.
class WorkspaceOrderItemSnapshot {
  const WorkspaceOrderItemSnapshot({
    required this.productId,
    required this.name,
    required this.pack,
    required this.quantity,
    required this.unitPricePaise,
    required this.lineTotalPaise,
  });

  final String productId, name, pack;
  final int quantity, unitPricePaise, lineTotalPaise;
}

/// Local composer recovery only. These stages grant no order/payment authority.
enum WorkspaceCounterDraftStage { editing, submitting, reviewRequired, retired }

/// Optional billing identity; phone remains the sale's customer identity.
/// This does not grant delivery, tax validation or payment authority.
class WorkspaceBillingDetails {
  const WorkspaceBillingDetails({
    this.business = false,
    this.name = '',
    this.businessName = '',
    this.gst = '',
    this.address = '',
  });
  final bool business;
  final String name, businessName, gst, address;
  bool get isEmpty =>
      !business &&
      name.isEmpty &&
      businessName.isEmpty &&
      gst.isEmpty &&
      address.isEmpty;
  Map<String, Object?> toJson() => {
    'business': business,
    'name': name,
    'businessName': businessName,
    'gst': gst,
    'address': address,
  };
  static WorkspaceBillingDetails fromJson(Object? value) {
    if (value == null) return const WorkspaceBillingDetails();
    if (value is! Map ||
        value['business'] is! bool ||
        ![
          'name',
          'businessName',
          'gst',
          'address',
        ].every((key) => value[key] is String)) {
      throw const FormatException('Invalid billing details');
    }
    return WorkspaceBillingDetails(
      business: value['business'] as bool,
      name: value['name'] as String,
      businessName: value['businessName'] as String,
      gst: value['gst'] as String,
      address: value['address'] as String,
    );
  }
}

enum WorkspaceInvoiceDeliveryMode {
  off('Off'),
  automatic('Auto'),
  whatsapp('WhatsApp'),
  moolSocialChat('MoolSocial Chat');

  const WorkspaceInvoiceDeliveryMode(this.label);
  final String label;
}

/// A Store preference, never recipient consent or evidence of message delivery.
class WorkspaceInvoiceDeliveryPreference {
  const WorkspaceInvoiceDeliveryPreference({
    required this.account,
    required this.store,
    this.mode = WorkspaceInvoiceDeliveryMode.off,
  });

  final String account, store;
  final WorkspaceInvoiceDeliveryMode mode;
  bool get valid => account.trim().isNotEmpty && store.trim().isNotEmpty;

  Map<String, Object?> toJson() => {
    'version': 1,
    'account': account,
    'store': store,
    'mode': mode.name,
  };

  static WorkspaceInvoiceDeliveryPreference? fromJson(Object? value) {
    if (value is! Map ||
        value['version'] != 1 ||
        value['account'] is! String ||
        value['store'] is! String) {
      return null;
    }
    final mode = WorkspaceInvoiceDeliveryMode.values
        .where((item) => item.name == value['mode'])
        .firstOrNull;
    if (mode == null) return null;
    final preference = WorkspaceInvoiceDeliveryPreference(
      account: value['account'] as String,
      store: value['store'] as String,
      mode: mode,
    );
    return preference.valid ? preference : null;
  }
}

/// Retailer-entered destination, not bank verification or payment authority.
/// Persist and resolve only within its exact signed-in account and Store.
class WorkspaceUpiDestination {
  const WorkspaceUpiDestination({
    required this.account,
    required this.store,
    required this.address,
    required this.payeeName,
    this.merchantCode = '',
  });

  final String account, store, address, payeeName, merchantCode;

  bool get valid =>
      account.trim().isNotEmpty &&
      store.trim().isNotEmpty &&
      address.length <= 256 &&
      RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+$').hasMatch(address) &&
      payeeName.trim().isNotEmpty &&
      payeeName == payeeName.trim() &&
      payeeName.length <= 100 &&
      !RegExp(r'[\x00-\x1f\x7f]').hasMatch(payeeName) &&
      (merchantCode.isEmpty || RegExp(r'^\d{4}$').hasMatch(merchantCode));

  Map<String, Object?> toJson() => {
    'version': 1,
    'account': account,
    'store': store,
    'address': address,
    'payeeName': payeeName,
    'merchantCode': merchantCode,
  };

  static WorkspaceUpiDestination? fromJson(Object? value) {
    if (value is! Map ||
        value['version'] != 1 ||
        ![
          'account',
          'store',
          'address',
          'payeeName',
          'merchantCode',
        ].every((key) => value[key] is String)) {
      return null;
    }
    final destination = WorkspaceUpiDestination(
      account: value['account'] as String,
      store: value['store'] as String,
      address: value['address'] as String,
      payeeName: value['payeeName'] as String,
      merchantCode: value['merchantCode'] as String,
    );
    return destination.valid ? destination : null;
  }

  /// Generic UPI request. No callback, scan, or app return records a receipt.
  /// Use integer paise throughout; floating-point formatting can alter money.
  Uri paymentUri({
    required String expectedAccount,
    required String expectedStore,
    required int amountPaise,
    required String reference,
  }) {
    if (!valid ||
        expectedAccount != account ||
        expectedStore != store ||
        amountPaise <= 0 ||
        amountPaise > 9007199254740991 ||
        !RegExp(r'^[a-zA-Z0-9-]{1,64}$').hasMatch(reference)) {
      throw const FormatException('Invalid Store payment request');
    }
    return Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: {
        'pa': address,
        'pn': payeeName,
        if (merchantCode.isNotEmpty) 'mc': merchantCode,
        'tr': reference,
        'tn': 'Counter Sale',
        'am':
            '${amountPaise ~/ 100}.${(amountPaise % 100).toString().padLeft(2, '0')}',
        'cu': 'INR',
      },
    );
  }
}

/// Bill-level discount. Fixed values are paise; percentage values are basis
/// points (100 = 1%). Money calculations never use floating point.
class WorkspaceBillDiscount {
  const WorkspaceBillDiscount.none() : kind = 'none', value = 0;
  const WorkspaceBillDiscount.fixed(this.value) : kind = 'fixed';
  const WorkspaceBillDiscount.percentage(this.value) : kind = 'percentage';

  final String kind;
  final int value;
  bool get isEmpty => kind == 'none';
  bool get valid => switch (kind) {
    'none' => value == 0,
    'fixed' => value > 0 && value <= 9007199254740991,
    'percentage' => value > 0 && value <= 10000,
    _ => false,
  };

  static WorkspaceBillDiscount parse(String kind, String input) {
    if (!const {'fixed', 'percentage'}.contains(kind) ||
        !RegExp(r'^\d{1,12}(?:\.\d{1,2})?$').hasMatch(input.trim())) {
      throw const FormatException(
        'Enter a positive value with up to 2 decimals.',
      );
    }
    final parts = input.trim().split('.');
    final value =
        int.parse(parts[0]) * 100 +
        (parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0')));
    final result = kind == 'fixed'
        ? WorkspaceBillDiscount.fixed(value)
        : WorkspaceBillDiscount.percentage(value);
    if (!result.valid) throw const FormatException('Check the discount value.');
    return result;
  }

  int amountFor(int subtotalMinor) {
    if (!valid || subtotalMinor < 0) {
      throw const FormatException('Invalid discount.');
    }
    if (isEmpty) return 0;
    if (kind == 'fixed') return value;
    // Round once, half-up, to the nearest paise.
    return ((BigInt.from(subtotalMinor) * BigInt.from(value) +
                BigInt.from(5000)) ~/
            BigInt.from(10000))
        .toInt();
  }

  bool validFor(int subtotalMinor) =>
      valid &&
      subtotalMinor >= 0 &&
      (isEmpty || amountFor(subtotalMinor) < subtotalMinor);

  Map<String, Object?> toJson() => {'kind': kind, 'value': value};
  static WorkspaceBillDiscount fromJson(Object? raw) {
    if (raw == null) return const WorkspaceBillDiscount.none();
    if (raw is! Map || raw['value'] is! int) {
      throw const FormatException('Invalid discount.');
    }
    final result = switch (raw['kind']) {
      'none' when raw['value'] == 0 => const WorkspaceBillDiscount.none(),
      'fixed' => WorkspaceBillDiscount.fixed(raw['value'] as int),
      'percentage' => WorkspaceBillDiscount.percentage(raw['value'] as int),
      _ => throw const FormatException('Invalid discount.'),
    };
    if (!result.valid) throw const FormatException('Invalid discount.');
    return result;
  }
}

class WorkspaceCounterDraft {
  WorkspaceCounterDraft({
    required this.account,
    required this.store,
    required this.id,
    required this.revision,
    required this.stage,
    required this.customer,
    this.billingDetails = const WorkspaceBillingDetails(),
    this.billingCustomer = '',
    required this.source,
    required this.fulfilment,
    required this.payment,
    required this.address,
    required List<WorkspaceOrderItemSnapshot> lines,
    this.submissionOrderId,
    this.discount = const WorkspaceBillDiscount.none(),
  }) : lines = List.unmodifiable(lines);

  final WorkspaceBillingDetails billingDetails;

  /// Owner of retained billing input while the phone field is incomplete.
  final String billingCustomer;
  final WorkspaceBillDiscount discount;
  final String account,
      store,
      id,
      customer,
      source,
      fulfilment,
      payment,
      address;
  final int revision;
  final WorkspaceCounterDraftStage stage;
  final String? submissionOrderId;
  final List<WorkspaceOrderItemSnapshot> lines;

  bool get valid =>
      account.trim().isNotEmpty &&
      (billingCustomer.isEmpty ||
          normalizeWorkspaceMobile(billingCustomer) != null) &&
      store.trim().isNotEmpty &&
      id.trim().isNotEmpty &&
      revision > 0 &&
      discount.valid &&
      const {'Counter', 'Phone', 'Chat'}.contains(source) &&
      const {
        'At the shop',
        'Own delivery',
        'Mool delivery',
      }.contains(fulfilment) &&
      const {
        'Cash',
        'UPI',
        'Bank Transfer',
        'Pay request',
        'On delivery',
        'Customer due',
      }.contains(payment) &&
      (stage != WorkspaceCounterDraftStage.editing ||
          submissionOrderId == null) &&
      ((stage != WorkspaceCounterDraftStage.submitting &&
              stage != WorkspaceCounterDraftStage.reviewRequired) ||
          (submissionOrderId?.trim().isNotEmpty == true &&
              customer.trim().isNotEmpty &&
              lines.isNotEmpty)) &&
      lines.map((line) => line.productId).toSet().length == lines.length &&
      lines.every(
        (line) =>
            line.productId.trim().isNotEmpty &&
            line.name.trim().isNotEmpty &&
            line.pack.trim().isNotEmpty &&
            line.quantity > 0 &&
            line.unitPricePaise >= 0 &&
            line.lineTotalPaise >= 0 &&
            line.lineTotalPaise ~/ line.quantity == line.unitPricePaise &&
            line.lineTotalPaise % line.quantity == 0,
      );

  Map<String, Object?> toJson() => {
    'version': 1,
    'purpose': 'counter-bill-draft',
    'account': account,
    'store': store,
    'id': id,
    'revision': revision,
    'stage': stage.name,
    'customer': customer,
    'billingDetails': billingDetails.toJson(),
    'billingCustomer': billingCustomer,
    'discount': discount.toJson(),
    'source': source,
    'fulfilment': fulfilment,
    'payment': payment,
    'address': address,
    'submissionOrderId': submissionOrderId,
    'lines': [
      for (final line in lines)
        {
          'productId': line.productId,
          'name': line.name,
          'pack': line.pack,
          'quantity': line.quantity,
          'unitPricePaise': line.unitPricePaise,
          'lineTotalPaise': line.lineTotalPaise,
        },
    ],
  };

  static WorkspaceCounterDraft? fromJson(Object? value) {
    if (value is! Map ||
        value['version'] != 1 ||
        value['purpose'] != 'counter-bill-draft' ||
        value['revision'] is! int ||
        value['lines'] is! List ||
        !const [
          'account',
          'store',
          'id',
          'customer',
          'source',
          'fulfilment',
          'payment',
          'address',
        ].every((key) => value[key] is String) ||
        (value['submissionOrderId'] != null &&
            value['submissionOrderId'] is! String)) {
      return null;
    }
    final stage = WorkspaceCounterDraftStage.values
        .where((stage) => stage.name == value['stage'])
        .firstOrNull;
    if (stage == null) return null;
    final lines = <WorkspaceOrderItemSnapshot>[];
    for (final item in value['lines'] as List) {
      if (item is! Map ||
          !const [
            'productId',
            'name',
            'pack',
          ].every((key) => item[key] is String) ||
          !const [
            'quantity',
            'unitPricePaise',
            'lineTotalPaise',
          ].every((key) => item[key] is int)) {
        return null;
      }
      lines.add(
        WorkspaceOrderItemSnapshot(
          productId: item['productId'] as String,
          name: item['name'] as String,
          pack: item['pack'] as String,
          quantity: item['quantity'] as int,
          unitPricePaise: item['unitPricePaise'] as int,
          lineTotalPaise: item['lineTotalPaise'] as int,
        ),
      );
    }
    WorkspaceBillingDetails billing;
    WorkspaceBillDiscount discount;
    if (value['billingCustomer'] != null &&
        value['billingCustomer'] is! String) {
      return null;
    }
    try {
      billing = WorkspaceBillingDetails.fromJson(value['billingDetails']);
      discount = WorkspaceBillDiscount.fromJson(value['discount']);
    } on FormatException {
      return null;
    }
    final draft = WorkspaceCounterDraft(
      account: value['account'] as String,
      store: value['store'] as String,
      id: value['id'] as String,
      revision: value['revision'] as int,
      stage: stage,
      customer: value['customer'] as String,
      billingDetails: billing,
      billingCustomer: value['billingCustomer'] as String? ?? '',
      discount: discount,
      source: value['source'] as String,
      fulfilment: value['fulfilment'] as String,
      payment: value['payment'] as String,
      address: value['address'] as String,
      submissionOrderId: value['submissionOrderId'] as String?,
      lines: lines,
    );
    return draft.valid ? draft : null;
  }
}

class WorkspaceOrderRecord {
  const WorkspaceOrderRecord({
    required this.id,
    required this.customer,
    this.billingDetails = const WorkspaceBillingDetails(),
    required this.items,
    required this.quantities,
    required this.amount,
    this.remainderPaise = 0,
    this.discount = const WorkspaceBillDiscount.none(),
    this.discountMinor = 0,
    required this.source,
    required this.fulfilment,
    required this.payment,
    required this.address,
    required this.stage,
    required this.needsDelivery,
    required this.createdAt,
    this.actionDeadline,
    this.fulfilmentDeadline,
    this.extraMinutes = 0,
    this.stockReserved = false,
    this.collectionStoreId,
    this.itemSnapshots = const [],
    this.rejectionReason,
  });

  final WorkspaceBillingDetails billingDetails;
  final String id;
  final String customer;
  final String items;
  final Map<String, int> quantities;
  final int amount;
  final int remainderPaise, discountMinor;
  final WorkspaceBillDiscount discount;
  int get payableMinor => amount * 100 + remainderPaise;
  int get subtotalMinor => payableMinor + discountMinor;
  bool get validBillAmounts =>
      amount >= 0 &&
      remainderPaise >= 0 &&
      remainderPaise < 100 &&
      discountMinor >= 0 &&
      discount.valid &&
      discount.validFor(subtotalMinor) &&
      discount.amountFor(subtotalMinor) == discountMinor;
  final String source;
  final String fulfilment;
  final String payment;
  final String address;
  final String stage;
  final bool needsDelivery;
  final DateTime createdAt;
  final DateTime? actionDeadline;
  final DateTime? fulfilmentDeadline;
  final int extraMinutes;
  final bool stockReserved;

  /// Set only by the order adapter for authenticated customer collection.
  /// A legacy Pickup label is not sufficient to grant collection authority.
  final String? collectionStoreId;
  final List<WorkspaceOrderItemSnapshot> itemSnapshots;
  final String? rejectionReason;

  /// Frozen original bill details for local ledger recovery, not fulfilment authority.
  Map<String, Object?> toLedgerJson() => {
    'id': id,
    'customer': customer,
    'billingDetails': billingDetails.toJson(),
    'items': items,
    'quantities': quantities,
    'amount': amount,
    'remainderPaise': remainderPaise,
    'discount': discount.toJson(),
    'discountMinor': discountMinor,
    'source': source,
    'fulfilment': fulfilment,
    'payment': payment,
    'address': address,
    'stage': stage,
    'needsDelivery': needsDelivery,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'actionDeadline': actionDeadline?.toUtc().toIso8601String(),
    'fulfilmentDeadline': fulfilmentDeadline?.toUtc().toIso8601String(),
    'extraMinutes': extraMinutes,
    'stockReserved': stockReserved,
    'collectionStoreId': collectionStoreId,
    'rejectionReason': rejectionReason,
    'itemSnapshots': [
      for (final item in itemSnapshots)
        {
          'productId': item.productId,
          'name': item.name,
          'pack': item.pack,
          'quantity': item.quantity,
          'unitPricePaise': item.unitPricePaise,
          'lineTotalPaise': item.lineTotalPaise,
        },
    ],
  };

  static WorkspaceOrderRecord? fromLedgerJson(Object? value) {
    try {
      final map = value as Map;
      DateTime? date(String key) =>
          map[key] == null ? null : DateTime.parse(map[key] as String).toUtc();
      final order = WorkspaceOrderRecord(
        id: map['id'] as String,
        customer: map['customer'] as String,
        billingDetails: WorkspaceBillingDetails.fromJson(map['billingDetails']),
        items: map['items'] as String,
        quantities: Map.unmodifiable(
          (map['quantities'] as Map).cast<String, int>(),
        ),
        amount: map['amount'] as int,
        remainderPaise: map['remainderPaise'] as int? ?? 0,
        discount: WorkspaceBillDiscount.fromJson(map['discount']),
        discountMinor: map['discountMinor'] as int? ?? 0,
        source: map['source'] as String,
        fulfilment: map['fulfilment'] as String,
        payment: map['payment'] as String,
        address: map['address'] as String,
        stage: map['stage'] as String,
        needsDelivery: map['needsDelivery'] as bool,
        createdAt: date('createdAt')!,
        actionDeadline: date('actionDeadline'),
        fulfilmentDeadline: date('fulfilmentDeadline'),
        extraMinutes: map['extraMinutes'] as int,
        stockReserved: map['stockReserved'] as bool,
        collectionStoreId: map['collectionStoreId'] as String?,
        rejectionReason: map['rejectionReason'] as String?,
        itemSnapshots: List.unmodifiable(
          (map['itemSnapshots'] as List).map((raw) {
            final item = raw as Map;
            return WorkspaceOrderItemSnapshot(
              productId: item['productId'] as String,
              name: item['name'] as String,
              pack: item['pack'] as String,
              quantity: item['quantity'] as int,
              unitPricePaise: item['unitPricePaise'] as int,
              lineTotalPaise: item['lineTotalPaise'] as int,
            );
          }),
        ),
      );
      if (!order.isCompleted ||
          !order.hasCompleteItemSnapshot ||
          order.id.trim().isEmpty ||
          order.customer.trim().isEmpty ||
          !order.validBillAmounts ||
          order.itemSnapshots.fold<int>(
                0,
                (sum, item) => sum + item.lineTotalPaise,
              ) !=
              order.payableMinor ||
          (!order.discount.isEmpty &&
              order.itemSnapshots.fold<int>(
                    0,
                    (sum, item) => sum + item.unitPricePaise * item.quantity,
                  ) !=
                  order.subtotalMinor)) {
        return null;
      }
      return order;
    } catch (_) {
      return null;
    }
  }

  /// A changed SKU/quantity must not retain stale purchased-price information.
  bool get hasCompleteItemSnapshot =>
      itemSnapshots.isNotEmpty &&
      itemSnapshots.length == quantities.length &&
      itemSnapshots.map((line) => line.productId).toSet().length ==
          itemSnapshots.length &&
      itemSnapshots.every(
        (line) =>
            line.name.trim().isNotEmpty &&
            line.quantity > 0 &&
            quantities[line.productId] == line.quantity &&
            line.unitPricePaise >= 0 &&
            line.lineTotalPaise >= 0,
      );
  bool get isCustomerCollection => collectionStoreId != null;
  bool get isCompleted =>
      stage == 'Completed' ||
      (!isCustomerCollection && stage == 'Delivered') ||
      (isCustomerCollection && stage == 'Collected');
  bool get isClosed => isCompleted || stage == 'Cancelled';

  bool get isDeliveryInProgress =>
      !isCustomerCollection &&
      const {
        'Ready',
        'Delivery requested',
        'Assigned',
        'At store',
        'Picked up',
        'Out for delivery',
        'Dispatched',
        'Delivering',
        'Delivery failed',
        'Delivery cancelled',
      }.contains(stage);

  WorkspaceOrderRecord copyWith({
    String? customer,
    String? items,
    Map<String, int>? quantities,
    int? amount,
    String? source,
    String? fulfilment,
    String? payment,
    String? address,
    String? stage,
    bool? needsDelivery,
    DateTime? actionDeadline,
    bool clearActionDeadline = false,
    DateTime? fulfilmentDeadline,
    int? extraMinutes,
    bool? stockReserved,
    List<WorkspaceOrderItemSnapshot>? itemSnapshots,
    String? rejectionReason,
  }) => WorkspaceOrderRecord(
    id: id,
    customer: customer ?? this.customer,
    billingDetails: billingDetails,
    items: items ?? this.items,
    quantities: Map<String, int>.unmodifiable(quantities ?? this.quantities),
    amount: amount ?? this.amount,
    remainderPaise: amount == null ? remainderPaise : 0,
    discount: amount == null ? discount : const WorkspaceBillDiscount.none(),
    discountMinor: amount == null ? discountMinor : 0,
    source: source ?? this.source,
    fulfilment: fulfilment ?? this.fulfilment,
    payment: payment ?? this.payment,
    address: address ?? this.address,
    stage: stage ?? this.stage,
    needsDelivery: needsDelivery ?? this.needsDelivery,
    createdAt: createdAt,
    actionDeadline: clearActionDeadline
        ? null
        : actionDeadline ?? this.actionDeadline,
    fulfilmentDeadline: fulfilmentDeadline ?? this.fulfilmentDeadline,
    extraMinutes: extraMinutes ?? this.extraMinutes,
    stockReserved: stockReserved ?? this.stockReserved,
    collectionStoreId: collectionStoreId,
    itemSnapshots: List<WorkspaceOrderItemSnapshot>.unmodifiable(
      itemSnapshots ?? this.itemSnapshots,
    ),
    rejectionReason: rejectionReason ?? this.rejectionReason,
  );
}

class WorkspaceCustomerRecord {
  const WorkspaceCustomerRecord({
    required this.id,
    required this.name,
    required this.mobile,
    required this.orders,
    required this.totalSpend,
    required this.amountDue,
    this.totalSpendRemainderPaise = 0,
    this.amountDueRemainderPaise = 0,
    required this.lastPurchaseAt,
    required this.followingStore,
    required this.messagesAllowed,
    this.lastContactAt,
    this.confirmedBalanceMinor,
    this.balanceAvailable = true,
  });

  final String id;
  final String name;
  final String mobile;
  final List<WorkspaceOrderRecord> orders;
  final int totalSpend;
  final int amountDue;
  final int totalSpendRemainderPaise, amountDueRemainderPaise;
  int get totalSpendMinor => totalSpend * 100 + totalSpendRemainderPaise;
  final int? confirmedBalanceMinor;
  final bool balanceAvailable;
  int get amountDueMinor =>
      confirmedBalanceMinor ?? amountDue * 100 + amountDueRemainderPaise;
  bool get hasDues => balanceAvailable && amountDueMinor > 0;
  final DateTime lastPurchaseAt;
  final bool followingStore;
  final bool messagesAllowed;
  final DateTime? lastContactAt;

  int get orderCount => orders.length;
  int get averageBasket => orderCount == 0 ? 0 : totalSpend ~/ orderCount;
  bool get repeatCustomer => orderCount > 1;
}

class WorkspaceDeliveryAssignment {
  const WorkspaceDeliveryAssignment({
    required this.orderId,
    required this.partnerName,
    required this.vehicleLabel,
    required this.eta,
    required this.stage,
    this.updatedAt,
  });

  final String orderId;
  final String partnerName;
  final String vehicleLabel;
  final DateTime eta;
  final String stage;

  /// Authority timestamp, not the time this device happened to receive it.
  /// Its presence alone is not proof of fresh GPS or a guaranteed arrival.
  final DateTime? updatedAt;

  WorkspaceDeliveryStage get deliveryStage =>
      switch (stage.trim().toLowerCase()) {
        'assigned' => WorkspaceDeliveryStage.assigned,
        'at store' => WorkspaceDeliveryStage.atStore,
        'picked up' || 'collected' => WorkspaceDeliveryStage.pickedUp,
        'out for delivery' ||
        'dispatched' ||
        'delivering' => WorkspaceDeliveryStage.outForDelivery,
        'delivered' => WorkspaceDeliveryStage.delivered,
        'cancelled' || 'delivery cancelled' => WorkspaceDeliveryStage.cancelled,
        'failed' || 'delivery failed' => WorkspaceDeliveryStage.failed,
        _ => WorkspaceDeliveryStage.unknown,
      };
}

enum WorkspaceDeliveryStage {
  assigned,
  atStore,
  pickedUp,
  outForDelivery,
  delivered,
  cancelled,
  failed,
  unknown;

  String get label => switch (this) {
    assigned => 'Assigned',
    atStore => 'At store',
    pickedUp => 'Picked up',
    outForDelivery => 'Out for delivery',
    delivered => 'Delivered',
    cancelled => 'Delivery cancelled',
    failed => 'Delivery needs attention',
    unknown => 'Delivery update unavailable',
  };

  int get progressIndex => switch (this) {
    assigned => 0,
    atStore => 1,
    pickedUp || outForDelivery => 2,
    delivered => 3,
    _ => -1,
  };
}

class WorkspacePackingLine {
  const WorkspacePackingLine({
    required this.id,
    required this.label,
    required this.quantity,
    required this.packed,
  });

  final String id;
  final String label;
  final int quantity;
  final bool packed;
}

/// Store-owned details frozen at issue time, not verified tax registration or
/// publication authority. Absent on historical invoices; never backfill them.
class WorkspaceInvoiceSeller {
  const WorkspaceInvoiceSeller({
    required this.storeId,
    this.legalName = '',
    this.storeAddress = '',
    this.billingAddress = '',
  });

  final String storeId, legalName, storeAddress, billingAddress;
  String get invoiceAddress =>
      billingAddress.isNotEmpty ? billingAddress : storeAddress;
  List<String> get detailLines => [
    if (legalName.isNotEmpty) 'Legal name: $legalName',
    if (invoiceAddress.isNotEmpty) 'Seller address: $invoiceAddress',
  ];
  bool get valid =>
      storeId.trim().isNotEmpty &&
      storeId.length <= 500 &&
      legalName.length <= 2000 &&
      storeAddress.length <= 6500 &&
      billingAddress.length <= 2000;

  Map<String, Object?> toJson() => {
    'storeId': storeId,
    'legalName': legalName,
    'storeAddress': storeAddress,
    'billingAddress': billingAddress,
  };
  factory WorkspaceInvoiceSeller.fromJson(Object? value) {
    if (value is! Map) throw const FormatException('Invalid invoice seller.');
    String field(String key) {
      final text = value[key];
      if (text is! String) {
        throw const FormatException('Invalid invoice seller.');
      }
      return text;
    }

    final result = WorkspaceInvoiceSeller(
      storeId: field('storeId'),
      legalName: field('legalName'),
      storeAddress: field('storeAddress'),
      billingAddress: field('billingAddress'),
    );
    if (!result.valid) throw const FormatException('Invalid invoice seller.');
    return result;
  }
}

class WorkspaceCustomerInvoice {
  const WorkspaceCustomerInvoice({
    required this.id,
    required this.orderId,
    required this.customer,
    this.sellerName = '',
    this.seller,
    this.billingDetails = const WorkspaceBillingDetails(),
    required this.items,
    required this.amount,
    this.remainderPaise = 0,
    this.discount = const WorkspaceBillDiscount.none(),
    this.discountMinor = 0,
    required this.payment,
    required this.issuedAt,
    this.sharedChannels = const <String>{},
  });

  final WorkspaceBillingDetails billingDetails;
  final String id;
  final String orderId;
  final String customer;

  /// Seller identity at issue time; never substitute a later Store rename.
  final String sellerName;
  final WorkspaceInvoiceSeller? seller;
  final String items;
  final int amount;
  final int remainderPaise, discountMinor;
  final WorkspaceBillDiscount discount;
  int get payableMinor => amount * 100 + remainderPaise;
  int get subtotalMinor => payableMinor + discountMinor;
  bool get validBillAmounts =>
      amount >= 0 &&
      remainderPaise >= 0 &&
      remainderPaise < 100 &&
      discountMinor >= 0 &&
      discount.valid &&
      discount.validFor(subtotalMinor) &&
      discount.amountFor(subtotalMinor) == discountMinor;
  final String payment;
  final DateTime issuedAt;
  final Set<String> sharedChannels;

  String get pdfFileName {
    String component(String value, int limit) {
      final safe = value
          .replaceAll(
            RegExp(r'[\x00-\x1F\x7F<>:"/\\|?*\u202A-\u202E\u2066-\u2069]'),
            ' ',
          )
          .replaceAll(RegExp(r'[\s._-]+'), '-')
          .replaceAll(RegExp(r'^-+|-+$'), '');
      return String.fromCharCodes(
        safe.runes.take(limit),
      ).replaceAll(RegExp(r'-+$'), '');
    }

    final seller = component(sellerName, 48);
    final buyer = component(
      billingDetails.business && billingDetails.businessName.trim().isNotEmpty
          ? billingDetails.businessName
          : billingDetails.name,
      48,
    );
    final number = component(id, 64);
    final baseName = [
      seller.isEmpty ? 'MoolSocial' : seller,
      if (buyer.isNotEmpty) buyer,
      number.isEmpty ? 'Invoice' : number,
    ].join('_');
    return '$baseName.pdf';
  }

  Map<String, Object?> toLedgerJson() => {
    'id': id,
    'orderId': orderId,
    'customer': customer,
    'sellerName': sellerName,
    if (seller != null) 'seller': seller!.toJson(),
    'billingDetails': billingDetails.toJson(),
    'items': items,
    'amount': amount,
    'remainderPaise': remainderPaise,
    'discount': discount.toJson(),
    'discountMinor': discountMinor,
    'payment': payment,
    'issuedAt': issuedAt.toUtc().toIso8601String(),
    'sharedChannels': sharedChannels.toList()..sort(),
  };
  factory WorkspaceCustomerInvoice.fromLedgerJson(Object? value) {
    final map = value as Map;
    final invoice = WorkspaceCustomerInvoice(
      id: map['id'] as String,
      orderId: map['orderId'] as String,
      customer: map['customer'] as String,
      sellerName: map['sellerName'] as String? ?? '',
      seller: map['seller'] == null
          ? null
          : WorkspaceInvoiceSeller.fromJson(map['seller']),
      billingDetails: WorkspaceBillingDetails.fromJson(map['billingDetails']),
      items: map['items'] as String,
      amount: map['amount'] as int,
      remainderPaise: map['remainderPaise'] as int? ?? 0,
      discount: WorkspaceBillDiscount.fromJson(map['discount']),
      discountMinor: map['discountMinor'] as int? ?? 0,
      payment: map['payment'] as String,
      issuedAt: DateTime.parse(map['issuedAt'] as String).toUtc(),
      sharedChannels: Set.unmodifiable(
        (map['sharedChannels'] as List).cast<String>(),
      ),
    );
    if (!invoice.validBillAmounts) {
      throw const FormatException('Invalid invoice amounts.');
    }
    return invoice;
  }

  bool get needsCustomerHandoff => sharedChannels.isEmpty;

  WorkspaceCustomerInvoice copyWith({Set<String>? sharedChannels}) =>
      WorkspaceCustomerInvoice(
        id: id,
        orderId: orderId,
        customer: customer,
        sellerName: sellerName,
        seller: seller,
        billingDetails: billingDetails,
        items: items,
        amount: amount,
        remainderPaise: remainderPaise,
        discount: discount,
        discountMinor: discountMinor,
        payment: payment,
        issuedAt: issuedAt,
        sharedChannels: Set<String>.unmodifiable(
          sharedChannels ?? this.sharedChannels,
        ),
      );
}

class WorkspaceStoreOffer {
  const WorkspaceStoreOffer({
    required this.id,
    required this.title,
    required this.detail,
    required this.validUntil,
    required this.active,
    this.productId,
    this.audience = 'Customers who allow Store offers',
    this.orderCap = 0,
  });

  final String id;
  final String title;
  final String detail;
  final DateTime validUntil;
  final bool active;
  final String? productId;
  final String audience;
  final int orderCap;
}

enum WorkspaceStockMode { availabilityOnly, exactQuantity }

/// Store-owned defaults for NEW records only. Listing is retailer intent, not
/// publication authority. CSV drafts always remain private until reviewed.
class WorkspaceProductDefaults {
  const WorkspaceProductDefaults({
    this.stockMode = WorkspaceStockMode.exactQuantity,
    this.lowStockThreshold = 5,
    this.customerListingRequested = false,
  });
  final WorkspaceStockMode stockMode;
  final int lowStockThreshold;
  final bool customerListingRequested;
  bool get valid => lowStockThreshold >= 0 && lowStockThreshold <= 999999999;
  WorkspaceCatalogueItem applyToNew(WorkspaceCatalogueItem product) =>
      product.copyWith(
        stockMode: stockMode,
        lowStockThreshold: lowStockThreshold,
        publicListing: customerListingRequested,
      );
  Map<String, Object?> toJson() => {
    'stockMode': stockMode.name,
    'lowStockThreshold': lowStockThreshold,
    'customerListingRequested': customerListingRequested,
  };
}

/// Confirmed cumulative returned packs for one exact supplier shipment.
/// A return confirmation is not a credit note, refund or payment instruction.
class WorkspaceSupplierReturnConfirmation {
  WorkspaceSupplierReturnConfirmation({
    required this.accountScope,
    required this.workspaceId,
    required this.supplierId,
    required this.orderId,
    required this.shipmentId,
    required this.reference,
    required this.revision,
    required this.confirmedAt,
    required Map<String, int> returnedPacks,
  }) : returnedPacks = Map.unmodifiable(returnedPacks);
  final String accountScope,
      workspaceId,
      supplierId,
      orderId,
      shipmentId,
      reference;
  final int revision;
  final DateTime confirmedAt;
  final Map<String, int> returnedPacks;

  bool belongsTo(WorkspacePurchaseRecord purchase) =>
      revision > 0 &&
      reference.trim().isNotEmpty &&
      accountScope == purchase.accountScope &&
      workspaceId == purchase.workspaceId &&
      supplierId == purchase.supplierId &&
      orderId == purchase.orderId &&
      shipmentId == purchase.shipmentId &&
      returnedPacks.isNotEmpty &&
      returnedPacks.keys.every(
        (id) => purchase.lines.any((line) => line.id == id),
      ) &&
      returnedPacks.values.every((count) => count >= 0);
}

enum WorkspaceStockMovementKind {
  reserved,
  released,
  sale,
  returned,
  goodsReceived,
  adjustment,
  damageOrExpiry,
  openingStock,
  supplierReturn,
}

enum WorkspaceStockReferenceKind { order, supplierReceipt, manualSupplierReceipt, manualSupplierReturn }

typedef WorkspaceLedgerFormKey = ({
  String account,
  String store,
  String customer,
  String invoice,
  String order,
  String kind,
  int ledgerRevision,
});

/// Unsent input only. An updated bill uses a different key so an old refund or
/// collection amount cannot silently become a new payment after confirmation.
class WorkspaceLedgerFormDraft {
  WorkspaceLedgerFormDraft({
    required this.key,
    required this.revision,
    required Map<String, String> fields,
  }) : fields = Map.unmodifiable(fields);
  final WorkspaceLedgerFormKey key;
  final int revision;
  final Map<String, String> fields;
  bool get valid =>
      revision > 0 &&
      key.ledgerRevision > 0 &&
      [
        key.account,
        key.store,
        key.customer,
        key.invoice,
        key.order,
      ].every((value) => value.trim().isNotEmpty && value.length <= 512) &&
      const [
        'collection',
        'refund',
        'return',
        'supplierPayment',
        'supplierMoney',
        'supplierAllocation',
        'supplierGoodsReturn',
        'supplierReceivingInput',
        'supplierCredit',
        'supplierShortage',
        'supplierRefund',
        'expense',
      ].contains(key.kind) &&
      fields.keys.every(
        (field) =>
            (key.kind == 'expense'
                    ? const [
                        'amount',
                        'channel',
                        'reference',
                        'category',
                        'note',
                      ]
                    : key.kind == 'supplierMoney'
                    ? const ['amount', 'channel', 'reference', 'occurredOn', 'notIncludedInOpening', 'attempt']
                    : key.kind == 'supplierAllocation'
                    ? const ['amount', 'sourceKind', 'sourceId', 'attempt']
                    : key.kind == 'supplierReceivingInput'
                    ? const ['arrivalId', 'groupId', 'input']
                    : key.kind == 'supplierGoodsReturn'
                    ? const ['reference', 'reason', 'returnedOn', 'items', 'attempt']
                    : key.kind == 'supplierCredit'
                    ? const ['amount', 'reference', 'reason', 'occurredOn', 'supports', 'attempt']
                    : key.kind == 'supplierShortage'
                    ? const ['billLineIndex', 'deliveryId', 'lineId', 'quantityMilli', 'attributionReviewed', 'attempt']
                    : key.kind == 'supplierRefund'
                    ? const ['amount', 'channel', 'reference', 'occurredOn', 'sourceKind', 'sourceId', 'attempt']
                    : key.kind == 'return'
                    ? const ['product', 'quantity', 'sellable', 'reason', 'reasonCode', 'items']
                    : key.kind == 'refund'
                    ? const ['amount', 'channel', 'reference', 'sourceCollectionId']
                    : const ['amount', 'channel', 'reference'])
                .contains(field),
      ) &&
      fields.entries.every((entry) =>
          entry.key == 'input' && key.kind == 'supplierReceivingInput'
              ? entry.value.length <= 262144 && _validReceivingInput(entry.value)
              : entry.key == 'items' && key.kind == 'return'
              ? _validReturnItems(entry.value)
              : entry.key == 'attempt' && key.kind == 'supplierMoney'
              ? entry.value.length <= 8192 && _validSupplierMoneyAttempt(entry.value)
              : entry.key == 'attempt' && key.kind == 'supplierAllocation'
              ? entry.value.length <= 8192 && _validSupplierAllocationIntent(entry.value)
              : entry.key == 'attempt' && key.kind == 'supplierGoodsReturn'
              ? entry.value.length <= 262144 && _validSupplierGoodsReturnIntent(entry.value)
              : entry.key == 'attempt' && key.kind == 'supplierCredit'
              ? entry.value.length <= 262144 && _validSupplierCreditIntent(entry.value)
              : entry.key == 'attempt' && key.kind == 'supplierShortage'
              ? entry.value.length <= 262144 && _validSupplierShortageIntent(entry.value)
              : entry.key == 'attempt' && key.kind == 'supplierRefund'
              ? entry.value.length <= 8192 && _validSupplierRefundIntent(entry.value)
              : entry.key == 'supports' && key.kind == 'supplierCredit'
              ? entry.value.length <= 262144
              : entry.key == 'reason' && key.kind == 'supplierCredit'
              ? entry.value.length <= 2000
              : entry.key == 'items' && key.kind == 'supplierGoodsReturn'
              ? entry.value.length <= 262144
              : entry.value.length <= 512) &&
      (key.kind != 'supplierMoney' || _supplierMoneyNamespaceValid) &&
      (key.kind != 'supplierReceivingInput' ||
        (key.ledgerRevision == 1 && key.invoice == 'receiving-input' &&
          const ['receiving-input:qa', 'receiving-input:live'].contains(key.order) &&
          (fields.isEmpty || (fields.length == 3 &&
            fields['arrivalId']?.trim().isNotEmpty == true &&
            fields['groupId']?.trim().isNotEmpty == true && fields.containsKey('input'))))) &&
      (key.kind != 'supplierRefund' || RegExp(
        r'^supplier-refund:(qa|live):(openingAdvance|accountAdvance|manualBillSurplus):.+$').hasMatch(key.order)) &&
      (key.kind != 'supplierCredit' || (key.order.startsWith('credit-copy:') && key.order.length > 12)) &&
      (key.kind != 'supplierShortage' || (key.order.startsWith('shortage-copy:') && key.order.length > 14)) &&
      (key.kind != 'supplierGoodsReturn' ||
        (key.ledgerRevision == 1 && key.order == 'return-receipt:${key.invoice}')) &&
      (key.kind != 'supplierAllocation' ||
        (key.order.startsWith('allocation-copy:') && key.order.length > 16));

  // Editable input, not a goods receipt or an authority to post Stock. Keep
  // incomplete quantities as text; validate their meaning only during Review.
  static bool _validReceivingInput(String text) {
    try {
      final value = jsonDecode(text);
      if (value is! List || value.length < 3 || value.length > 102 ||
          value[0] is! String || value[1] is! String ||
          (value[0] as String).length > 512 || (value[1] as String).length > 512) {
        return false;
      }
      final ids = <String>{};
      for (final line in value.skip(2)) {
        if (line is! List || line.length != 10 || line[2] is! bool) return false;
        for (final index in const [0, 1, 3, 4, 5, 6, 7, 8]) {
          if (line[index] is! String || (line[index] as String).length > 512) return false;
        }
        if ((line[0] as String).trim().isEmpty || !ids.add(line[0] as String)) return false;
        final prior = line[9];
        if (prior is! Map || prior.length > 256 || prior.entries.any((entry) =>
            entry.key is! String || (entry.key as String).trim().isEmpty ||
            (entry.key as String).length > 512 || entry.value is! String ||
            (entry.value as String).length > 512)) {
          return false;
        }
      }
      return true;
    } on Object { return false; }
  }

  WorkspaceSupplierRefundIntent? get supplierRefundIntent {
    final text = fields['attempt'];
    if (key.kind != 'supplierRefund' || text == null || text.isEmpty || text.length > 8192) return null;
    try { return WorkspaceSupplierRefundIntent.fromJson(jsonDecode(text)); }
    on Object { return null; }
  }

  bool _validSupplierRefundIntent(String text) {
    if (text.isEmpty) return true;
    final intent = supplierRefundIntent;
    return intent != null && intent.formKey == key &&
      intent.reference == fields['reference'] && intent.occurredOn == fields['occurredOn'] &&
      intent.paymentMethod == fields['channel'] && intent.sourceKind.name == fields['sourceKind'] &&
      intent.sourceId == fields['sourceId'] &&
      WorkspacePurchaseEntryDraft.printedPaise(fields['amount']) == intent.amountMinor;
  }

  WorkspaceSupplierShortageIntent? get supplierShortageIntent {
    final text = fields['attempt'];
    if (key.kind != 'supplierShortage' || text == null || text.isEmpty || text.length > 262144) { return null; }
    try { return WorkspaceSupplierShortageIntent.fromJson(jsonDecode(text)); }
    on Object { return null; }
  }
  bool _validSupplierShortageIntent(String text) {
    if (text.isEmpty) return true;
    final intent = supplierShortageIntent;
    return intent != null && intent.accountScope == key.account && intent.workspaceId == key.store &&
      intent.supplierId == key.customer && intent.billId == key.invoice &&
      intent.copyRevision == key.ledgerRevision && key.order == 'shortage-copy:${intent.copyId}' &&
      '${intent.billLineIndex}' == fields['billLineIndex'] && intent.expectedDeliveryId == fields['deliveryId'] &&
      intent.receiptLineId == fields['lineId'] && '${intent.quantityMilli}' == fields['quantityMilli'] &&
      fields['attributionReviewed'] == 'true';
  }

  WorkspaceSupplierCreditIntent? get supplierCreditIntent {
    final text = fields['attempt'];
    if (key.kind != 'supplierCredit' || text == null || text.isEmpty || text.length > 262144) return null;
    try { return WorkspaceSupplierCreditIntent.fromJson(jsonDecode(text)); }
    on Object { return null; }
  }
  bool _validSupplierCreditIntent(String text) {
    if (text.isEmpty) return true;
    final intent = supplierCreditIntent;
    return intent != null && intent.accountScope == key.account && intent.workspaceId == key.store &&
      intent.supplierId == key.customer && intent.billId == key.invoice &&
      intent.copyRevision == key.ledgerRevision && key.order == 'credit-copy:${intent.copyId}' &&
      intent.reference == fields['reference'] && intent.reason == fields['reason'] &&
      intent.occurredOn == fields['occurredOn'] &&
      WorkspacePurchaseEntryDraft.printedPaise(fields['amount']) == intent.amountMinor &&
      jsonEncode(intent.supports.map((s) => s.toJson()).toList()) == fields['supports'];
  }

  WorkspaceSupplierGoodsReturnIntent? get supplierGoodsReturnIntent {
    final text = fields['attempt'];
    if (key.kind != 'supplierGoodsReturn' || text == null || text.isEmpty || text.length > 262144) return null;
    try { return WorkspaceSupplierGoodsReturnIntent.fromJson(jsonDecode(text)); }
    on Object { return null; }
  }
  bool _validSupplierGoodsReturnIntent(String text) {
    if (text.isEmpty) return true;
    final intent = supplierGoodsReturnIntent;
    return intent != null && intent.accountScope == key.account && intent.workspaceId == key.store &&
      intent.supplierId == key.customer && intent.receiptId == key.invoice &&
      key.ledgerRevision == 1 && key.order == 'return-receipt:${intent.receiptId}' &&
      intent.reference == fields['reference'] && intent.reason == fields['reason'] &&
      intent.returnedOn == fields['returnedOn'] &&
      jsonEncode(intent.lines.map((line) => line.toJson()).toList()) == fields['items'];
  }

  WorkspaceSupplierMoneyAllocationIntent? get supplierAllocationIntent {
    final text = fields['attempt'];
    if (key.kind != 'supplierAllocation' || text == null || text.isEmpty || text.length > 8192) return null;
    try { return WorkspaceSupplierMoneyAllocationIntent.fromJson(jsonDecode(text)); }
    on Object { return null; }
  }

  bool _validSupplierAllocationIntent(String text) {
    if (text.isEmpty) return true;
    final intent = supplierAllocationIntent;
    return intent != null && intent.accountScope == key.account && intent.workspaceId == key.store &&
      intent.supplierId == key.customer && intent.billId == key.invoice &&
      intent.copyRevision == key.ledgerRevision && key.order == 'allocation-copy:${intent.copyId}' &&
      intent.sourceKind.name == fields['sourceKind'] && intent.sourceId == fields['sourceId'] &&
      WorkspacePurchaseEntryDraft.printedPaise(fields['amount']) == intent.amountMinor;
  }

  /// For supplierMoney only, ledgerRevision is the immutable document/opening
  /// basis revision, NOT today's supplier ledger CAS revision. order is a draft
  /// namespace, never a fabricated financial orderId.
  bool get _supplierMoneyNamespaceValid =>
      (key.order.startsWith('manual-copy:') && key.order.length > 12) ||
      key.order == 'account-payment:${key.invoice}' ||
      key.order == 'account-advance:${key.invoice}';

  WorkspaceSupplierMoneyAttempt? get supplierMoneyAttempt {
    final text = fields['attempt'];
    if (key.kind != 'supplierMoney' || text == null || text.isEmpty || text.length > 8192) return null;
    try { return WorkspaceSupplierMoneyAttempt.fromJson(jsonDecode(text)); }
    on FormatException { return null; }
  }

  bool _validSupplierMoneyAttempt(String text) {
    if (text.isEmpty) return true; // Unsubmitted editable input.
    final attempt = supplierMoneyAttempt;
    final entry = attempt?.entry;
    if (entry == null || entry.paymentMethod != fields['channel'] ||
        entry.reference != fields['reference']?.trim() ||
        entry.moneyReview!.occurredOn != fields['occurredOn'] ||
        fields['notIncludedInOpening'] != 'true' ||
        WorkspacePurchaseEntryDraft.printedPaise(fields['amount']) != entry.amountMinor) {
      return false;
    }
    if (entry.origin == WorkspaceSupplierEntryOrigin.manualPurchase) {
      return entry.kind == WorkspaceSupplierEntryKind.payment &&
          key.invoice == entry.billId && key.order == 'manual-copy:${entry.purchaseId}';
    }
    return entry.origin == WorkspaceSupplierEntryOrigin.supplierAccount &&
        entry.billId == null && key.invoice == entry.moneyReview!.openingId &&
        key.ledgerRevision == entry.moneyReview!.openingRevision &&
        key.order == '${entry.kind == WorkspaceSupplierEntryKind.advance ? 'account-advance' : 'account-payment'}:${key.invoice}';
  }

  // Unsubmitted text is retained (including invalid quantities) for correction.
  // Financial validation still belongs to WorkspaceCustomerReturn.
  static bool _validReturnItems(String value) {
    if (value.length > 65536) return false;
    try {
      final items = jsonDecode(value);
      return items is Map && items.length <= 1000 && items.entries.every((entry) =>
          entry.key is String && (entry.key as String).isNotEmpty &&
          (entry.key as String).length <= 512 && entry.value is List &&
          (entry.value as List).length == 2 &&
          (entry.value as List).every((v) => v is String && v.length <= 512));
    } on FormatException {
      return false;
    }
  }
  Map<String, Object?> toJson() => {
    'version': 1,
    'account': key.account,
    'store': key.store,
    'customer': key.customer,
    'invoice': key.invoice,
    'order': key.order,
    'kind': key.kind,
    'ledgerRevision': key.ledgerRevision,
    'revision': revision,
    'fields': fields,
  };
  static WorkspaceLedgerFormDraft? fromJson(Object? value) {
    if (value is! Map ||
        value['version'] != 1 ||
        value['revision'] is! int ||
        value['ledgerRevision'] is! int ||
        value['fields'] is! Map ||
        ![
          'account',
          'store',
          'customer',
          'invoice',
          'order',
          'kind',
        ].every((key) => value[key] is String)) {
      return null;
    }
    final raw = value['fields'] as Map;
    if (raw.entries.any(
      (entry) => entry.key is! String || entry.value is! String,
    )) {
      return null;
    }
    final draft = WorkspaceLedgerFormDraft(
      key: (
        account: value['account'] as String,
        store: value['store'] as String,
        customer: value['customer'] as String,
        invoice: value['invoice'] as String,
        order: value['order'] as String,
        kind: value['kind'] as String,
        ledgerRevision: value['ledgerRevision'] as int,
      ),
      revision: value['revision'] as int,
      fields: raw.cast<String, String>(),
    );
    return draft.valid ? draft : null;
  }
}

class WorkspaceStockMovement {
  const WorkspaceStockMovement({
    required this.id,
    required this.productId,
    required this.productLabel,
    required this.kind,
    required this.quantityDelta,
    required this.reason,
    required this.occurredAt,
    this.referenceKind,
    this.referenceId,
  });

  final String id;
  final String productId;
  final String productLabel;
  final WorkspaceStockMovementKind kind;
  final int quantityDelta;
  final String reason;
  final DateTime occurredAt;
  final WorkspaceStockReferenceKind? referenceKind;
  final String? referenceId;

  bool get valid =>
      id.trim().isNotEmpty &&
      productId.trim().isNotEmpty &&
      productLabel.trim().isNotEmpty &&
      reason.trim().isNotEmpty &&
      quantityDelta != 0 &&
      (switch (kind) {
        WorkspaceStockMovementKind.reserved ||
        WorkspaceStockMovementKind.sale ||
        WorkspaceStockMovementKind.supplierReturn ||
        WorkspaceStockMovementKind.damageOrExpiry => quantityDelta < 0,
        WorkspaceStockMovementKind.released ||
        WorkspaceStockMovementKind.returned ||
        WorkspaceStockMovementKind.goodsReceived ||
        WorkspaceStockMovementKind.openingStock => quantityDelta > 0,
        WorkspaceStockMovementKind.adjustment => true,
      }) &&
      ((referenceKind == null && referenceId == null) ||
          (referenceKind != null && referenceId?.trim().isNotEmpty == true));
  Object get contentIdentity => (
    id,
    productId,
    productLabel,
    kind,
    quantityDelta,
    reason,
    occurredAt.toUtc(),
    referenceKind,
    referenceId,
  );
  String get label => switch (kind) {
    WorkspaceStockMovementKind.reserved => 'Reserved for order',
    WorkspaceStockMovementKind.released => 'Reservation released',
    WorkspaceStockMovementKind.sale => 'Sale',
    WorkspaceStockMovementKind.returned => 'Returned to stock',
    WorkspaceStockMovementKind.goodsReceived => 'Goods received',
    WorkspaceStockMovementKind.adjustment => 'Counted adjustment',
    WorkspaceStockMovementKind.damageOrExpiry => 'Damage or expiry',
    WorkspaceStockMovementKind.openingStock => 'Opening quantity',
    WorkspaceStockMovementKind.supplierReturn => 'Returned to supplier',
  };
  static int compareNewest(WorkspaceStockMovement a, WorkspaceStockMovement b) {
    final date = b.occurredAt.compareTo(a.occurredAt);
    return date != 0 ? date : a.id.compareTo(b.id);
  }
}

typedef WorkspaceStockHistoryKey = ({
  String account,
  String store,
  DateTime? from,
  DateTime? until,
  String? productId,
});

/// Immutable read scope. Calendar dates are converted to UTC by the caller;
/// from is inclusive, until exclusive. A cursor belongs to one snapshot only.
/// Scoped quantity recovery for the local frontend journey. A movement ID is
/// acknowledged once; saving this record does not establish backend stock authority.
class WorkspaceInventoryLedger {
  WorkspaceInventoryLedger({
    required this.accountScope,
    required this.workspaceId,
    required this.revision,
    required this.asOf,
    required Map<String, int> openingQuantities,
    required List<WorkspaceStockMovement> movements,
  }) : openingQuantities = Map.unmodifiable(openingQuantities),
       movements = List.unmodifiable(movements);
  final String accountScope, workspaceId;
  final int revision;
  final DateTime asOf;
  final Map<String, int> openingQuantities;
  final List<WorkspaceStockMovement> movements;

  Map<String, int>? get quantities {
    if (accountScope.trim().isEmpty ||
        workspaceId.trim().isEmpty ||
        revision <= 0 ||
        openingQuantities.entries.any(
          (item) =>
              item.key.trim().isEmpty ||
              item.value < 0 ||
              item.value > 2147483647,
        )) {
      return null;
    }
    final result = Map<String, int>.of(openingQuantities);
    final ids = <String>{};
    for (final movement in movements) {
      if (!movement.valid ||
          !ids.add(movement.id) ||
          movement.occurredAt.isAfter(asOf) ||
          !result.containsKey(movement.productId)) {
        return null;
      }
      final quantity = result[movement.productId]! + movement.quantityDelta;
      if (quantity < 0 || quantity > 2147483647) return null;
      result[movement.productId] = quantity;
    }
    return Map.unmodifiable(result);
  }

  bool get valid => quantities != null;

  WorkspaceInventoryLedger? post(
    List<WorkspaceStockMovement> incoming, {
    required DateTime at,
    Set<String> newProductIds = const {},
  }) {
    if (!valid || at.isBefore(asOf)) return null;
    if (newProductIds.any((id) => id.trim().isEmpty)) {
      return null;
    }
    final opening = Map<String, int>.of(openingQuantities);
    for (final id in newProductIds) {
      opening.putIfAbsent(id, () => 0);
    }
    final known = {for (final movement in movements) movement.id: movement};
    final additions = <WorkspaceStockMovement>[];
    for (final movement in incoming) {
      final previous = known[movement.id];
      if (previous != null) {
        if (previous.contentIdentity != movement.contentIdentity) return null;
      } else {
        known[movement.id] = movement;
        additions.add(movement);
      }
    }
    if (additions.isEmpty && opening.length == openingQuantities.length) {
      return this;
    }
    final next = WorkspaceInventoryLedger(
      accountScope: accountScope,
      workspaceId: workspaceId,
      revision: revision + 1,
      asOf: at,
      openingQuantities: opening,
      movements: [...movements, ...additions],
    );
    return next.valid ? next : null;
  }

  bool canFollow(WorkspaceInventoryLedger previous) {
    if (!valid ||
        !previous.valid ||
        accountScope != previous.accountScope ||
        workspaceId != previous.workspaceId ||
        revision < previous.revision ||
        asOf.isBefore(previous.asOf) ||
        previous.openingQuantities.entries.any(
          (entry) => openingQuantities[entry.key] != entry.value,
        ) ||
        openingQuantities.entries.any(
          (entry) =>
              !previous.openingQuantities.containsKey(entry.key) &&
              entry.value != 0,
        )) {
      return false;
    }
    if (revision == previous.revision) {
      return jsonEncode(toJson()) == jsonEncode(previous.toJson());
    }
    if (movements.length < previous.movements.length) return false;
    for (var i = 0; i < previous.movements.length; i++) {
      if (movements[i].contentIdentity !=
          previous.movements[i].contentIdentity) {
        return false;
      }
    }
    return true;
  }

  Map<String, Object?> toJson() => {
    'version': 1,
    'accountScope': accountScope,
    'workspaceId': workspaceId,
    'revision': revision,
    'asOf': asOf.toUtc().toIso8601String(),
    'openingQuantities': openingQuantities,
    'movements': [
      for (final movement in movements)
        {
          'id': movement.id,
          'productId': movement.productId,
          'productLabel': movement.productLabel,
          'kind': movement.kind.name,
          'quantityDelta': movement.quantityDelta,
          'reason': movement.reason,
          'occurredAt': movement.occurredAt.toUtc().toIso8601String(),
          'referenceKind': movement.referenceKind?.name,
          'referenceId': movement.referenceId,
        },
    ],
  };
  factory WorkspaceInventoryLedger.fromJson(Object? value) {
    if (value is! Map || value['version'] != 1) {
      throw const FormatException('Stock recovery version is unavailable.');
    }
    final result = WorkspaceInventoryLedger(
      accountScope: value['accountScope'] as String,
      workspaceId: value['workspaceId'] as String,
      revision: value['revision'] as int,
      asOf: DateTime.parse(value['asOf'] as String),
      openingQuantities: Map<String, int>.from(
        value['openingQuantities'] as Map,
      ),
      movements: [
        for (final movement in value['movements'] as List)
          WorkspaceStockMovement(
            id: movement['id'] as String,
            productId: movement['productId'] as String,
            productLabel: movement['productLabel'] as String,
            kind: WorkspaceStockMovementKind.values.byName(
              movement['kind'] as String,
            ),
            quantityDelta: movement['quantityDelta'] as int,
            reason: movement['reason'] as String,
            occurredAt: DateTime.parse(movement['occurredAt'] as String),
            referenceKind: movement['referenceKind'] == null
                ? null
                : WorkspaceStockReferenceKind.values.byName(
                    movement['referenceKind'] as String,
                  ),
            referenceId: movement['referenceId'] as String?,
          ),
      ],
    );
    if (!result.valid) throw const FormatException('Saved stock is invalid.');
    return result;
  }
}

class WorkspaceStockHistoryQuery {
  const WorkspaceStockHistoryQuery({
    required this.accountScope,
    required this.workspaceId,
    this.from,
    this.until,
    this.productId,
  });
  final String accountScope, workspaceId;
  final DateTime? from, until;
  final String? productId;
  static const pageSize = 50;
  WorkspaceStockHistoryKey get key => (
    account: accountScope,
    store: workspaceId,
    from: from,
    until: until,
    productId: productId,
  );
  bool get valid =>
      accountScope.trim().isNotEmpty &&
      workspaceId.trim().isNotEmpty &&
      (from == null || from!.isUtc) &&
      (until == null || until!.isUtc) &&
      (from == null || until == null || from!.isBefore(until!)) &&
      (productId == null || productId!.trim().isNotEmpty);
  bool includes(WorkspaceStockMovement record) =>
      (productId == null || record.productId == productId) &&
      (from == null || !record.occurredAt.isBefore(from!)) &&
      (until == null || record.occurredAt.isBefore(until!));
}

/// Server pages are read-only. They must not reapply quantities or expose cost.
class WorkspaceStockHistoryPage {
  WorkspaceStockHistoryPage({
    required this.query,
    required this.snapshotId,
    required List<WorkspaceStockMovement> records,
    this.cursor,
    this.nextCursor,
    this.totalCount,
  }) : records = List.unmodifiable(records);
  final WorkspaceStockHistoryQuery query;
  final String snapshotId;
  final String? cursor, nextCursor;
  final int? totalCount;
  final List<WorkspaceStockMovement> records;
  bool get valid =>
      query.valid &&
      snapshotId.trim().isNotEmpty &&
      records.length <= WorkspaceStockHistoryQuery.pageSize &&
      records.every((record) => record.valid && query.includes(record)) &&
      records.map((record) => record.id).toSet().length == records.length &&
      (cursor == null || cursor!.isNotEmpty) &&
      (nextCursor == null ||
          (nextCursor!.isNotEmpty &&
              nextCursor != cursor &&
              records.isNotEmpty)) &&
      (totalCount == null || totalCount! >= records.length) &&
      Iterable.generate(records.isNotEmpty ? records.length - 1 : 0).every(
        (i) =>
            WorkspaceStockMovement.compareNewest(records[i], records[i + 1]) <=
            0,
      );
}

enum WorkspaceCataloguePhotoStatus { pending, testOnly, approved }

/// Catalogue-owned metadata, not retailer approval authority. A production
/// adapter must supply the approval and a revision-specific immutable URL.
/// The original source is retained; thumbnail dimensions are presentation only.
class WorkspaceCataloguePhoto {
  const WorkspaceCataloguePhoto({
    required this.assetId,
    required this.revision,
    required this.source,
    required this.publisherWorkspaceId,
    required this.canonicalId,
    required this.brand,
    required this.variant,
    required this.pack,
    required this.barcode,
    required this.file,
    this.status = WorkspaceCataloguePhotoStatus.pending,
  });

  final String assetId, revision, source, publisherWorkspaceId;
  final String canonicalId, brand, variant, pack, barcode;
  final BuyV2MediaFileMetadata file;
  final WorkspaceCataloguePhotoStatus status;

  bool matches(WorkspaceCatalogueItem product) =>
      canonicalId.isNotEmpty &&
      canonicalId == product.canonicalId &&
      brand == product.brand &&
      variant == product.variant &&
      pack == product.pack &&
      barcode == product.barcode;

  BuyV2ProductMediaAsset _asset(
    WorkspaceCatalogueItem product,
    String storeId,
  ) => BuyV2ProductMediaAsset(
    id: assetId,
    label: 'Product photo',
    semanticLabel: '${product.brand} ${product.title}, ${product.pack}',
    kind: BuyV2ProductContentMediaKind.network,
    source: source,
    binding: BuyV2ProductMediaBinding(
      supplierWorkspaceId: publisherWorkspaceId,
      storeId: storeId,
      productId: product.canonicalId,
      skuId: product.id,
      assetRevision: revision,
      file: file,
    ),
  );

  Map<String, Object?> toJson() => {
    'assetId': assetId,
    'revision': revision,
    'source': source,
    'publisherWorkspaceId': publisherWorkspaceId,
    'canonicalId': canonicalId,
    'brand': brand,
    'variant': variant,
    'pack': pack,
    'barcode': barcode,
    'status': status.name,
    'file': {
      'mimeType': file.mimeType,
      'byteLength': file.byteLength,
      'width': file.width,
      'height': file.height,
      'normalized': file.normalized,
      'frameCount': file.frameCount,
      'durationMicroseconds': file.duration?.inMicroseconds,
      'frameRate': file.frameRate,
      'videoCodec': file.videoCodec,
      'videoProfile': file.videoProfile,
      'audioCodec': file.audioCodec,
    },
  };

  /// Invalid/unrecognised persisted metadata fails closed. This decoder does not
  /// turn local JSON into trusted approval; backend authorization is separate.
  static WorkspaceCataloguePhoto? fromJson(Object? value) {
    if (value is! Map) return null;
    final metadata = value['file'];
    if (metadata is! Map) return null;
    const fields = [
      'assetId',
      'revision',
      'source',
      'publisherWorkspaceId',
      'canonicalId',
      'brand',
      'variant',
      'pack',
      'barcode',
    ];
    if (fields.any((key) => value[key] is! String) ||
        metadata['mimeType'] is! String ||
        metadata['byteLength'] is! int ||
        metadata['width'] is! int ||
        metadata['height'] is! int ||
        metadata['normalized'] is! bool ||
        (metadata['frameCount'] != null && metadata['frameCount'] is! int) ||
        metadata['durationMicroseconds'] != null ||
        metadata['frameRate'] != null ||
        metadata['videoCodec'] != null ||
        metadata['videoProfile'] != null ||
        metadata['audioCodec'] != null) {
      return null;
    }
    final status = WorkspaceCataloguePhotoStatus.values
        .where((status) => status.name == value['status'])
        .firstOrNull;
    if (status == null) return null;
    return WorkspaceCataloguePhoto(
      assetId: value['assetId'] as String,
      revision: value['revision'] as String,
      source: value['source'] as String,
      publisherWorkspaceId: value['publisherWorkspaceId'] as String,
      canonicalId: value['canonicalId'] as String,
      brand: value['brand'] as String,
      variant: value['variant'] as String,
      pack: value['pack'] as String,
      barcode: value['barcode'] as String,
      status: status,
      file: BuyV2MediaFileMetadata(
        mimeType: metadata['mimeType'] as String,
        byteLength: metadata['byteLength'] as int,
        width: metadata['width'] as int,
        height: metadata['height'] as int,
        normalized: metadata['normalized'] as bool,
        frameCount: metadata['frameCount'] as int?,
      ),
    );
  }
}

enum WorkspaceProductImportIssueKind {
  invalidValue,
  duplicateInStore,
  duplicateInFile,
  malformedColumns,
}

/// One row of a file review. Blocked rows never become inventory implicitly.
class WorkspaceProductImportRow {
  const WorkspaceProductImportRow(
    this.number,
    this.title,
    this.product,
    this.issue,
    this.matched, {
    this.issueValues = const {},
    this.variant = '',
    this.pack = '',
    this.sku = '',
    this.rawValues = const {},
    this.sourceValues = const {},
    this.canCorrect = false,
    this.issueKind,
    this.relatedRowNumber,
    this.sourceCells = const [],
    this.sourceHeaders = const [],
  });
  final int number;
  final String title;
  final WorkspaceCatalogueItem? product;
  final String? issue;
  final bool matched;
  final Map<String, String> issueValues;
  final String variant, pack, sku;

  /// Current inputs and original source evidence; neither is sellable stock.
  final Map<String, String> rawValues, sourceValues;
  final bool canCorrect;
  final WorkspaceProductImportIssueKind? issueKind;
  final int? relatedRowNumber;

  /// Positional evidence for malformed CSV rows; never guessed product fields.
  final List<String> sourceCells, sourceHeaders;
}

class WorkspaceProductImport {
  const WorkspaceProductImport(this.rows);
  final List<WorkspaceProductImportRow> rows;
  // The same compliance keys used by the shared editor and Buy projection.
  // Batch dates are deliberately not SKU-wide import fields.
  static const packFieldLabels = {
    'genericName': 'Generic product name',
    'netQuantity': 'Net quantity',
    'manufacturerName': 'Manufacturer',
    'packerName': 'Packer',
    'importerName': 'Importer, if applicable',
    'countryOfOrigin': 'Country of origin',
    'fssaiLicenseNumber': 'Manufacturer FSSAI number, if applicable',
    'consumerCare': 'Product consumer care',
  };
  static const requiredColumns = {
    'title',
    'brand',
    'pack',
    'purchasePrice',
    'sellingPrice',
    'stock',
  };
  static final columns = Set<String>.unmodifiable({
    ...requiredColumns,
    ...WorkspaceSellingInputs.labels.keys,
    'sku',
    'barcode',
    'canonicalId',
    'variant',
    'categoryId',
    'mrp',
    'minimumOrder',
    'lowStockThreshold',
    'stockMode',
    'available',
    'publicListing',
    'unitPrice',
    'deliveryPromise',
    'returnPolicy',
    'origin',
    'visualLabel',
    'composition',
    'regulatoryNote',
    ...WorkspaceProductContent.labels.keys,
    ...packFieldLabels.keys,
  });
  // One schema owns the download headings and the retailer's column guide.
  // Identity/approval metadata and publication requests are not template inputs.
  static const templateLabels = {
    ...WorkspaceSellingInputs.labels,
    'title': 'Product name',
    'brand': 'Brand or maker',
    'pack': 'Pack size',
    'purchasePrice': 'Purchase price',
    'sellingPrice': 'Selling price',
    'stock': 'Stock quantity',
    'sku': 'Your Store SKU',
    'barcode': 'Product barcode',
    'variant': 'Variant',
    'categoryId': 'Category',
    'mrp': 'MRP',
    'minimumOrder': 'Minimum order',
    'lowStockThreshold': 'Low-stock level',
    'stockMode': 'Stock tracking',
    'available': 'Available for sale',
    'unitPrice': 'Unit-price label',
    'deliveryPromise': 'Product delivery terms',
    'returnPolicy': 'Product return terms',
    'origin': 'Product origin',
    'composition': 'Ingredients or composition',
    'regulatoryNote': 'Product regulatory note',
    ...WorkspaceProductContent.labels,
    ...packFieldLabels,
  };
  static String get csvTemplate => '\uFEFF${templateLabels.keys.join(',')}\r\n';

  /// Reuse the complete importer, including exact-pack matching and duplicate
  /// checks. Corrected rows keep their original CSV row and source evidence.
  static WorkspaceProductImportRow revalidateRow(
    WorkspaceProductImportRow original,
    Map<String, String> values, {
    required List<WorkspaceCatalogueItem> catalogue,
    required List<WorkspaceCatalogueItem> owned,
    List<WorkspaceProductImportRow> readyRows = const [],
    WorkspaceProductDefaults defaults = const WorkspaceProductDefaults(),
  }) {
    if (!original.canCorrect) {
      throw const FormatException(
        'Correct this row in the file and import again.',
      );
    }
    for (final entry in values.entries) {
      if (entry.value.length > 4000) {
        throw FormatException(
          '${entry.key}: Keep this value within 4,000 characters.',
        );
      }
    }
    final result = parse(
      jsonEncode([values]),
      json: true,
      catalogue: catalogue,
      owned: owned,
      readyRows: readyRows,
      defaults: defaults,
    ).rows.single;
    return WorkspaceProductImportRow(
      original.number,
      result.title,
      result.product,
      result.issue,
      result.matched,
      issueValues: result.issueValues,
      variant: result.variant,
      pack: result.pack,
      sku: result.sku,
      rawValues: result.rawValues,
      sourceValues: original.sourceValues,
      canCorrect: true,
      issueKind: result.issueKind,
      relatedRowNumber: result.relatedRowNumber,
      sourceCells: original.sourceCells,
      sourceHeaders: original.sourceHeaders,
    );
  }

  static String identity(WorkspaceCatalogueItem p) => jsonEncode([
    p.brand.toLowerCase().trim(),
    p.title.toLowerCase().trim(),
    p.pack.toLowerCase().trim(),
    p.variant.toLowerCase().trim(),
  ]);

  /// RFC-style quoted cells, escaped quotes, embedded newlines and UTF-8 BOM.
  /// Limits apply before allocating an unbounded row list.
  static List<List<String>> csv(String text, {List<int>? rowNumbers}) {
    if (text.startsWith('\uFEFF')) text = text.substring(1);
    final rows = <List<String>>[];
    var recordNumber = 1;
    var row = <String>[];
    var cell = StringBuffer();
    var quoted = false, endedQuote = false;
    void endCell() {
      row.add(cell.toString().trim());
      if (row.length > columns.length) {
        throw const FormatException(
          'Too many columns. Use the listed product columns.',
        );
      }
      cell = StringBuffer();
      endedQuote = false;
    }

    void endRow() {
      endCell();
      if (row.any((value) => value.isNotEmpty)) {
        rows.add(row);
        rowNumbers?.add(recordNumber);
      }
      recordNumber++;
      row = [];
      if (rows.length > 10001) {
        throw const FormatException('Import up to 10,000 products at a time.');
      }
    }

    for (var i = 0; i < text.length; i++) {
      final c = text[i];
      if (quoted) {
        if (c == '"') {
          if (i + 1 < text.length && text[i + 1] == '"') {
            cell.write('"');
            i++;
          } else {
            quoted = false;
            endedQuote = true;
          }
        } else {
          cell.write(c);
        }
      } else if (c == ',') {
        endCell();
      } else if (c == '\n' || c == '\r') {
        if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
        endRow();
      } else if (c == '"' && cell.isEmpty && !endedQuote) {
        quoted = true;
      } else if (c == '"' || (endedQuote && c.trim().isNotEmpty)) {
        throw FormatException(
          'CSV row $recordNumber: check the quotation marks. No products were saved.',
        );
      } else if (!endedQuote) {
        cell.write(c);
      }
      if (cell.length > 4000) {
        throw const FormatException(
          'A cell is too long. Keep each value within 4,000 characters.',
        );
      }
    }
    if (quoted) {
      throw FormatException(
        'CSV row $recordNumber: a quoted cell is not closed. Fix the file and import again; no products were saved.',
      );
    }
    if (cell.isNotEmpty || row.isNotEmpty || endedQuote) endRow();
    return rows;
  }

  static WorkspaceProductImport parse(
    String text, {
    bool json = false,
    required List<WorkspaceCatalogueItem> catalogue,
    required List<WorkspaceCatalogueItem> owned,
    List<WorkspaceProductImportRow> readyRows = const [],
    WorkspaceProductDefaults defaults = const WorkspaceProductDefaults(),
  }) {
    if (text.length > 10 * 1024 * 1024) {
      throw const FormatException('Choose a file smaller than 10 MB.');
    }
    final records = <Map<String, String>>[];
    final rowNumbers = <int>[];
    final malformed = <int>{};
    final sourceCells = <List<String>>[];
    var sourceHeaders = const <String>[];
    if (json) {
      final decoded = jsonDecode(text);
      if (decoded is! List || decoded.isEmpty || decoded.length > 10000) {
        throw const FormatException('Choose a list of 1 to 10,000 products.');
      }
      for (final value in decoded) {
        if (value is! Map) {
          throw const FormatException('Every product must be a record.');
        }
        records.add(
          value.map(
            (key, value) => MapEntry('$key', value == null ? '' : '$value'),
          ),
        );
        rowNumbers.add(records.length);
      }
    } else {
      final table = csv(text, rowNumbers: rowNumbers);
      if (rowNumbers.isNotEmpty) rowNumbers.removeAt(0);
      if (table.length < 2) {
        throw const FormatException(
          'Include column headings and at least one product.',
        );
      }
      final headers = table.first;
      sourceHeaders = List.unmodifiable(headers);
      if (headers.toSet().length != headers.length ||
          headers.any((h) => h.isEmpty)) {
        throw const FormatException('Use a unique name for every column.');
      }
      if (!headers.toSet().containsAll(requiredColumns)) {
        throw const FormatException(
          'Required columns: title, brand, pack, purchasePrice, sellingPrice, stock.',
        );
      }
      for (final values in table.skip(1)) {
        sourceCells.add(List.unmodifiable(values));
        if (values.length != headers.length) malformed.add(records.length);
        records.add({
          for (var i = 0; i < headers.length; i++)
            headers[i]: i < values.length ? values[i] : '',
        });
      }
    }
    final unknown = records.expand((r) => r.keys).toSet().difference(columns);
    if (unknown.isNotEmpty) {
      throw FormatException(
        'Unsupported columns: ${unknown.take(5).join(', ')}. No products were saved.',
      );
    }
    final byBarcode = <String, List<WorkspaceCatalogueItem>>{};
    final byCanonical = <String, List<WorkspaceCatalogueItem>>{};
    final byIdentity = <String, List<WorkspaceCatalogueItem>>{};
    for (final p in catalogue) {
      if (p.barcode.isNotEmpty) {
        byBarcode.putIfAbsent(p.barcode, () => []).add(p);
      }
      byCanonical.putIfAbsent(p.canonicalId, () => []).add(p);
      byIdentity.putIfAbsent(identity(p), () => []).add(p);
    }
    final skus = owned.map((p) => p.sku.toLowerCase().trim()).toSet();
    final barcodes = owned
        .where((p) => p.barcode.isNotEmpty)
        .map((p) => p.barcode)
        .toSet();
    final identities = owned.map(identity).toSet();
    final ownedIds = owned.map((p) => p.id).toSet();
    final batchSkus = <String, int>{};
    final batchBarcodes = <String, int>{};
    final batchIdentities = <String, int>{};
    final batchIds = <String, int>{};
    void indexReady(WorkspaceCatalogueItem product, int row) {
      batchSkus.putIfAbsent(product.sku.toLowerCase().trim(), () => row);
      if (product.barcode.isNotEmpty) {
        batchBarcodes.putIfAbsent(product.barcode, () => row);
      }
      batchIdentities.putIfAbsent(identity(product), () => row);
      batchIds.putIfAbsent(product.id, () => row);
    }

    for (final row in readyRows) {
      if (row.product case final product?) indexReady(product, row.number);
    }
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final result = <WorkspaceProductImportRow>[];
    for (var index = 0; index < records.length; index++) {
      final r = records[index].map((k, v) => MapEntry(k, v.trim()));
      String value(String key) => r[key] ?? '';
      final title = value('title');
      WorkspaceProductImportRow blocked(
        String issue, {
        List<String> fields = const [],
        WorkspaceProductImportIssueKind kind =
            WorkspaceProductImportIssueKind.invalidValue,
        int? relatedRow,
      }) => WorkspaceProductImportRow(
        rowNumbers[index],
        title.isEmpty ? 'Unnamed product' : title,
        null,
        issue,
        false,
        issueValues: Map.unmodifiable({
          for (final key in fields) key: value(key),
        }),
        variant: value('variant'),
        pack: value('pack'),
        sku: value('sku'),
        rawValues: Map.unmodifiable(r),
        sourceValues: Map.unmodifiable(r),
        canCorrect: !malformed.contains(index),
        issueKind: kind,
        relatedRowNumber: relatedRow,
        sourceCells: json ? const [] : sourceCells[index],
        sourceHeaders: sourceHeaders,
      );
      if (malformed.contains(index)) {
        result.add(
          blocked(
            'Column count does not match the headings: expected ${sourceHeaders.length}, found ${sourceCells[index].length}. Fix this row in the CSV and import again.',
            kind: WorkspaceProductImportIssueKind.malformedColumns,
          ),
        );
        continue;
      }
      final purchase = int.tryParse(value('purchasePrice'));
      final selling = int.tryParse(value('sellingPrice'));
      final stock = int.tryParse(value('stock'));
      final mrp = int.tryParse(value('mrp'));
      final minimum = value('minimumOrder').isEmpty
          ? 1
          : int.tryParse(value('minimumOrder'));
      final low = value('lowStockThreshold').isEmpty
          ? defaults.lowStockThreshold
          : int.tryParse(value('lowStockThreshold'));
      final error = workspaceProductValuesIssue(
        title: title,
        brand: value('brand'),
        pack: value('pack'),
        category: value('categoryId').isEmpty ? 'other' : value('categoryId'),
        sku: value('sku').isEmpty ? 'import-$stamp-$index' : value('sku'),
        purchase: purchase,
        selling: selling,
        stock: stock,
        mrp: mrp,
        lowStockThreshold: low,
        minimumOrder: minimum,
        delivery: value('deliveryPromise').isEmpty
            ? 'Store pickup or local delivery'
            : value('deliveryPromise'),
      );
      if (error != null) {
        result.add(blocked(error.message, fields: [error.field]));
        continue;
      }
      if (value('mrp').isNotEmpty && mrp == null) {
        result.add(
          blocked('Enter MRP as a whole-rupee amount.', fields: ['mrp']),
        );
        continue;
      }
      final oversized = {
        'purchasePrice': purchase!,
        'sellingPrice': selling!,
        'stock': stock!,
        'mrp': mrp ?? 0,
        'minimumOrder': minimum!,
        'lowStockThreshold': low!,
      }.entries.where((e) => e.value > 2147483647).map((e) => e.key).toList();
      if (oversized.isNotEmpty) {
        result.add(
          blocked(
            'Use a whole number no greater than 2147483647.',
            fields: oversized,
          ),
        );
        continue;
      }
      final invalidFlags = ['available', 'publicListing']
          .where(
            (k) =>
                value(k).isNotEmpty &&
                !['true', 'false'].contains(value(k).toLowerCase()),
          )
          .toList();
      if (invalidFlags.isNotEmpty) {
        result.add(
          blocked(
            'Use true or false for availability and visibility.',
            fields: invalidFlags,
          ),
        );
        continue;
      }
      if (value('stockMode').isNotEmpty &&
          ![
            'exactquantity',
            'availabilityonly',
          ].contains(value('stockMode').toLowerCase())) {
        result.add(
          blocked(
            'Stock mode must be exactQuantity or availabilityOnly.',
            fields: ['stockMode'],
          ),
        );
        continue;
      }
      final barcode = value('barcode'), canonical = value('canonicalId');
      final exactKey = jsonEncode([
        value('brand').toLowerCase(),
        title.toLowerCase(),
        value('pack').toLowerCase(),
        value('variant').toLowerCase(),
      ]);
      var candidates = barcode.isNotEmpty
          ? byBarcode[barcode] ?? []
          : canonical.isNotEmpty
          ? byCanonical[canonical] ?? []
          : byIdentity[exactKey] ?? [];
      if (canonical.isNotEmpty) {
        candidates = candidates
            .where((p) => p.canonicalId == canonical)
            .toList();
      }
      candidates = candidates.where((p) => identity(p) == exactKey).toList();
      if (candidates.length > 1) {
        result.add(
          blocked(
            'More than one catalogue match. Add the exact barcode or correct the variant.',
            fields: ['barcode', 'variant', 'pack'],
          ),
        );
        continue;
      }
      if (candidates.isEmpty &&
          (canonical.isNotEmpty ||
              (barcode.isNotEmpty && byBarcode.containsKey(barcode)))) {
        result.add(
          blocked(
            'Catalogue identity does not match the name, brand, variant or pack.',
            fields: ['barcode', 'title', 'brand', 'variant', 'pack'],
          ),
        );
        continue;
      }
      final matched = candidates.firstOrNull;
      final id = matched?.id ?? 'import-$stamp-$index';
      final sku = value('sku').isNotEmpty
          ? value('sku')
          : matched?.sku ?? 'SKU-$stamp-$index';
      final inStore =
          ownedIds.contains(id) ||
          skus.contains(sku.toLowerCase()) ||
          (barcode.isNotEmpty && barcodes.contains(barcode)) ||
          identities.contains(exactKey);
      final duplicateRow =
          batchIds[id] ??
          batchSkus[sku.toLowerCase()] ??
          (barcode.isEmpty ? null : batchBarcodes[barcode]) ??
          batchIdentities[exactKey];
      if (inStore || duplicateRow != null) {
        result.add(
          blocked(
            inStore
                ? 'Already in Store stock. Update the saved product from Store stock; this import will not overwrite it.'
                : 'Repeated product: matches CSV row $duplicateRow. Keep one row for this SKU and pack, or correct its identity.',
            kind: inStore
                ? WorkspaceProductImportIssueKind.duplicateInStore
                : WorkspaceProductImportIssueKind.duplicateInFile,
            relatedRow: inStore ? null : duplicateRow,
            fields:
                (skus.contains(sku.toLowerCase()) ||
                    batchSkus.containsKey(sku.toLowerCase()))
                ? ['sku']
                : barcode.isNotEmpty &&
                      (barcodes.contains(barcode) ||
                          batchBarcodes.containsKey(barcode))
                ? ['barcode']
                : ['title', 'brand', 'variant', 'pack'],
          ),
        );
        continue;
      }
      final mode = value('stockMode').isEmpty
          ? defaults.stockMode
          : value('stockMode').toLowerCase() == 'availabilityonly'
          ? WorkspaceStockMode.availabilityOnly
          : WorkspaceStockMode.exactQuantity;
      final base =
          matched ??
          WorkspaceCatalogueItem(
            id: id,
            canonicalId: id,
            categoryId: 'other',
            brand: value('brand'),
            title: title,
            variant: value('variant'),
            pack: value('pack'),
            sku: sku,
            barcode: barcode,
            purchasePrice: purchase,
            sellingPrice: selling,
            unitPrice: '',
            stock: stock,
            deliveryPromise: 'Store pickup or local delivery',
            origin: '',
            visualLabel: '$title ${value('pack')}',
            visualKind: 'catalogue-packshot',
            publicListing: false,
          );
      final packFacts = <String, Object?>{
        ...?base.compliance?.toJson(),
        // A new Store copy must not inherit another stock receipt's dates.
        'manufacturedOrPackedOn': null,
        'bestBeforeOrUseBy': null,
      };
      var packFactsChanged = false;
      for (final key in packFieldLabels.keys) {
        final supplied = value(key);
        if (supplied.isEmpty) continue; // Preserve exact-match facts.
        if (packFacts[key] != supplied) packFactsChanged = true;
        packFacts[key] = supplied;
      }
      final catalogueFacts = {
        'categoryId': base.categoryId,
        'origin': base.origin,
        'composition': base.composition,
        'regulatoryNote': base.regulatoryNote,
        'visualLabel': base.visualLabel,
      };
      final catalogueFactsChanged = catalogueFacts.entries.any(
        (entry) =>
            value(entry.key).isNotEmpty &&
            value(entry.key) != (entry.value ?? '').trim(),
      );
      WorkspaceProductContent content;
      try {
        content = WorkspaceProductContent.parse(
          r,
          existing: base.content,
          preserveBlank: true,
        );
      } on FormatException catch (error) {
        result.add(
          blocked(error.message, fields: [error.message.split(':').first]),
        );
        continue;
      }
      final contentChanged =
          jsonEncode(content.toJson()) != jsonEncode(base.content.toJson());
      WorkspaceSellingInputs sellingDetails;
      try {
        sellingDetails = WorkspaceSellingInputs.parse(
          r,
          existingMeasure: base.packMeasure,
          existingWholesale: base.wholesaleOffer,
          existingRetailEnabled: base.retailEnabled,
        );
      } on FormatException catch (error) {
        final field = error.message.split(':').first;
        result.add(
          blocked(
            error.message,
            fields: WorkspaceSellingInputs.labels.containsKey(field)
                ? [field]
                : [],
          ),
        );
        continue;
      }
      final product = base.copyWith(
        packMeasure: sellingDetails.measure,
        wholesaleOffer: sellingDetails.wholesale,
        retailEnabled: sellingDetails.retailEnabled,
        sku: sku,
        visualLabel: value('visualLabel').isEmpty
            ? base.visualLabel
            : value('visualLabel'),
        compliance: base.compliance == null && !packFactsChanged
            ? null
            : WorkspaceProductCompliance.fromJson(packFacts),
        purchasePrice: purchase,
        sellingPrice: selling,
        stock: stock,
        mrp: mrp ?? base.mrp,
        // An omitted override keeps the exact SKU's existing order rule.
        minimumOrder: value('minimumOrder').isEmpty
            ? base.minimumOrder
            : minimum,
        lowStockThreshold: low,
        unitPrice: value('unitPrice').isEmpty
            ? '₹$selling/${base.pack}'
            : value('unitPrice'),
        deliveryPromise: value('deliveryPromise').isEmpty
            ? base.deliveryPromise
            : value('deliveryPromise'),
        stockMode: mode,
        available: mode == WorkspaceStockMode.availabilityOnly
            ? value('available').toLowerCase() != 'false'
            : stock > 0,
        publicListing: false, // Import never publishes silently.
        categoryId: value('categoryId').isEmpty
            ? base.categoryId
            : value('categoryId'),
        origin: value('origin').isEmpty ? base.origin : value('origin'),
        returnPolicy: value('returnPolicy').isEmpty
            ? base.returnPolicy
            : value('returnPolicy'),
        composition: value('composition').isEmpty
            ? base.composition
            : value('composition'),
        regulatoryNote: value('regulatoryNote').isEmpty
            ? base.regulatoryNote
            : value('regulatoryNote'),
        content: content,
        catalogueFactsRequireReview:
            base.catalogueFactsRequireReview ||
            jsonEncode(sellingDetails.measure?.toJson()) !=
                jsonEncode(base.packMeasure?.toJson()) ||
            packFactsChanged ||
            catalogueFactsChanged ||
            contentChanged,
      );
      if (product.wholesaleOffer?.enabled == true &&
          product.mrp != null &&
          product.wholesaleOffer!.priceRupees > product.mrp!) {
        result.add(
          blocked(
            'Wholesale price cannot exceed the pack MRP.',
            fields: ['wholesalePrice', 'mrp'],
          ),
        );
        continue;
      }
      if (product.mrp != null && product.mrp! < selling) {
        result.add(
          blocked(
            value('mrp').isEmpty
                ? 'Customer price exceeds the catalogue MRP of ₹${product.mrp}. Correct the selling price or check the pack MRP.'
                : 'MRP cannot be lower than the customer price.',
            fields: value('mrp').isEmpty
                ? ['sellingPrice']
                : ['mrp', 'sellingPrice'],
          ),
        );
        continue;
      }
      indexReady(product, rowNumbers[index]);
      result.add(
        WorkspaceProductImportRow(
          rowNumbers[index],
          title,
          product,
          null,
          matched != null,
          rawValues: Map.unmodifiable(r),
          sourceValues: Map.unmodifiable(r),
          canCorrect: true,
          sourceCells: json ? const [] : sourceCells[index],
          sourceHeaders: sourceHeaders,
        ),
      );
    }
    return WorkspaceProductImport(List.unmodifiable(result));
  }
}

/// One field-aware validator; the shared editor keeps its existing text API.
({String field, String message})? workspaceProductValuesIssue({
  required String title,
  required String brand,
  required String pack,
  required String category,
  required String sku,
  required int? purchase,
  required int? selling,
  required int? stock,
  required int? mrp,
  required int? lowStockThreshold,
  required int? minimumOrder,
  required String delivery,
}) => title.isEmpty
    ? (field: 'title', message: 'Enter the product name shown to customers.')
    : brand.isEmpty
    ? (field: 'brand', message: 'Enter the product brand or maker.')
    : pack.isEmpty
    ? (field: 'pack', message: 'Enter the customer pack size.')
    : category.isEmpty
    ? (field: 'categoryId', message: 'Choose or enter the product category.')
    : sku.isEmpty
    ? (field: 'sku', message: 'Enter a unique store SKU.')
    : purchase == null || purchase <= 0
    ? (field: 'purchasePrice', message: 'Enter purchase price.')
    : selling == null || selling <= purchase
    ? (
        field: 'sellingPrice',
        message: 'Enter a customer price above the purchase price.',
      )
    : stock == null || stock < 0
    ? (field: 'stock', message: 'Enter the available stock.')
    : lowStockThreshold == null || lowStockThreshold < 0
    ? (
        field: 'lowStockThreshold',
        message: 'Enter when you want a low-stock reminder.',
      )
    : mrp != null && mrp < selling
    ? (field: 'mrp', message: 'MRP cannot be lower than the customer price.')
    : delivery.isEmpty
    ? (field: 'deliveryPromise', message: 'Add the customer delivery promise.')
    : minimumOrder == null || minimumOrder <= 0
    ? (
        field: 'minimumOrder',
        message: 'Enter the minimum customer order quantity.',
      )
    : null;

String? validateWorkspaceProductValues({
  required String title,
  required String brand,
  required String pack,
  required String category,
  required String sku,
  required int? purchase,
  required int? selling,
  required int? stock,
  required int? mrp,
  required int? lowStockThreshold,
  required int? minimumOrder,
  required String delivery,
}) => workspaceProductValuesIssue(
  title: title,
  brand: brand,
  pack: pack,
  category: category,
  sku: sku,
  purchase: purchase,
  selling: selling,
  stock: stock,
  mrp: mrp,
  lowStockThreshold: lowStockThreshold,
  minimumOrder: minimumOrder,
  delivery: delivery,
)?.message;

/// Private contact identity, not a public supplier or an accounting balance.
class WorkspaceSupplierProfile {
  const WorkspaceSupplierProfile({required this.id, required this.name,
    required this.createdAt, required this.updatedAt,
    this.phone = '', this.address = '', this.gstin = ''});
  final String id, name, phone, address, gstin;
  final DateTime createdAt, updatedAt;
  String? get validationError {
    if (id.trim().isEmpty || name.trim().isEmpty || name.length > 120) {
      return 'Enter a supplier name, up to 120 characters.';
    }
    if (phone.isNotEmpty && !RegExp(r'^\+?[0-9]{7,15}$').hasMatch(phone)) {
      return 'Enter a valid phone number, or leave it blank.';
    }
    if (address.length > 500) return 'Keep the address within 500 characters.';
    if (gstin.isNotEmpty && !RegExp(r'^[0-9A-Z]{15}$').hasMatch(gstin)) {
      return 'Enter the 15-character GSTIN, or leave it blank.';
    }
    if (updatedAt.isBefore(createdAt)) return 'Supplier dates need recovery.';
    return null;
  }
  Map<String, Object?> toJson() => {'id': id, 'name': name, 'phone': phone,
    'address': address, 'gstin': gstin, 'source': 'manual',
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String()};
  static WorkspaceSupplierProfile fromJson(Object? raw) {
    const keys = {'id', 'name', 'phone', 'address', 'gstin', 'source', 'createdAt', 'updatedAt'};
    if (raw is! Map || raw.length != keys.length ||
        !raw.keys.every(keys.contains) || raw['source'] != 'manual') {
      throw const FormatException('Supplier record needs recovery');
    }
    final result = WorkspaceSupplierProfile(id: raw['id'] as String,
      name: raw['name'] as String, phone: raw['phone'] as String,
      address: raw['address'] as String, gstin: raw['gstin'] as String,
      createdAt: DateTime.parse(raw['createdAt'] as String),
      updatedAt: DateTime.parse(raw['updatedAt'] as String));
    if (result.validationError != null) throw const FormatException('Invalid supplier');
    return result;
  }
}

/// Original private invoice evidence, not product media or publication approval.
class WorkspacePurchaseInvoiceAttachment {
  const WorkspacePurchaseInvoiceAttachment({required this.owner, required this.digest,
    required this.fileName, required this.contentType, required this.byteLength,
    required this.source, this.detectedText = ''});
  final String owner, digest, fileName, contentType, source, detectedText;
  final int byteLength;
  bool get valid => owner.isNotEmpty && owner.length <= 1000 &&
    RegExp(r'^[a-f0-9]{64}$').hasMatch(digest) && fileName.isNotEmpty &&
    fileName.length <= 200 && byteLength > 0 && byteLength <= 10 * 1024 * 1024 &&
    const ['image/jpeg', 'image/png', 'image/webp', 'application/pdf'].contains(contentType) &&
    const ['camera', 'gallery', 'upload'].contains(source) && detectedText.length <= 60000;
  Map<String, Object?> toJson() => {'owner': owner, 'digest': digest,
    'fileName': fileName, 'contentType': contentType, 'byteLength': byteLength,
    'source': source, 'detectedText': detectedText};
  WorkspacePurchaseInvoiceAttachment withText(String text) =>
    WorkspacePurchaseInvoiceAttachment(owner: owner, digest: digest,
      fileName: fileName, contentType: contentType, byteLength: byteLength,
      source: source, detectedText: text);
  static WorkspacePurchaseInvoiceAttachment fromJson(Object? raw) {
    const keys = {'owner', 'digest', 'fileName', 'contentType', 'byteLength', 'source', 'detectedText'};
    if (raw is! Map || raw.length != keys.length || !raw.keys.every(keys.contains)) {
      throw const FormatException('Invoice attachment needs recovery');
    }
    final value = WorkspacePurchaseInvoiceAttachment(owner: raw['owner'] as String,
      digest: raw['digest'] as String, fileName: raw['fileName'] as String,
      contentType: raw['contentType'] as String, byteLength: raw['byteLength'] as int,
      source: raw['source'] as String, detectedText: raw['detectedText'] as String);
    if (!value.valid) throw const FormatException('Invalid invoice attachment');
    return value;
  }
}

/// Unmapped invoice content is information, never a generated posting rule.
class WorkspacePurchaseAdditionalField {
  const WorkspacePurchaseAdditionalField({required this.id, required this.label,
    required this.value, required this.section, this.itemIndex, this.summaryIndex,
    this.sourceDigest, this.sourcePage, this.sourceItemIndex, this.reviewed = false});
  final String id, label, value, section;
  final int? itemIndex, summaryIndex, sourcePage, sourceItemIndex;
  final String? sourceDigest;
  final bool reviewed;
  static const sections = {'supplier', 'invoice', 'items', 'tax', 'buyer', 'receipt', 'payment'};
  bool get valid => id.isNotEmpty && id.length <= 200 && label.trim().isNotEmpty &&
    label.length <= 120 && value.length <= 4000 && sections.contains(section) &&
    (itemIndex == null || section == 'items' && itemIndex! >= 0) &&
    (summaryIndex == null || section == 'tax' && summaryIndex! >= 0) &&
    (sourceDigest == null || RegExp(r'^[a-f0-9]{64}$').hasMatch(sourceDigest!)) &&
    (sourceItemIndex == null || section == 'items' && sourceDigest != null &&
      sourceItemIndex! >= 0 && sourceItemIndex! < 200) &&
    (sourcePage == null || sourceDigest != null && sourcePage! > 0 && sourcePage! <= 10000);
  Map<String, Object?> toJson() => {'version': 1, 'id': id, 'label': label,
    'value': value, 'section': section, 'reviewed': reviewed,
    if (itemIndex != null) 'itemIndex': itemIndex,
    if (summaryIndex != null) 'summaryIndex': summaryIndex,
    if (sourceDigest != null) 'sourceDigest': sourceDigest,
    if (sourceItemIndex != null) 'sourceItemIndex': sourceItemIndex,
    if (sourcePage != null) 'sourcePage': sourcePage};
  static WorkspacePurchaseAdditionalField fromJson(Object? raw) {
    const required = {'version', 'id', 'label', 'value', 'section', 'reviewed'};
    const optional = {'itemIndex', 'summaryIndex', 'sourceDigest', 'sourcePage', 'sourceItemIndex'};
    if (raw is! Map || !required.every(raw.containsKey) || raw['version'] != 1 ||
        !raw.keys.every((key) => required.contains(key) || optional.contains(key))) {
      throw const FormatException('Additional invoice field needs recovery');
    }
    final field = WorkspacePurchaseAdditionalField(id: raw['id'] as String,
      label: raw['label'] as String, value: raw['value'] as String,
      section: raw['section'] as String, reviewed: raw['reviewed'] as bool,
      itemIndex: raw['itemIndex'] as int?, summaryIndex: raw['summaryIndex'] as int?,
      sourceDigest: raw['sourceDigest'] as String?, sourcePage: raw['sourcePage'] as int?,
      sourceItemIndex: raw['sourceItemIndex'] as int?);
    if (!field.valid) throw const FormatException('Invalid additional invoice field');
    return field;
  }
}

/// Manual/reviewed input only: saving cannot post stock, dues or payments.
class WorkspacePurchaseEntryDraft {
  WorkspacePurchaseEntryDraft({required this.id, required this.supplierId,
    required this.invoiceReference, required this.invoiceDate,
    required this.createdAt, required this.updatedAt,
    required List<Map<String, String>> goods, Map<String, String> details = const {},
    List<WorkspacePurchaseInvoiceAttachment> attachments = const [],
    List<WorkspacePurchaseAdditionalField> additionalFields = const [],
    List<Map<String, String>> printedTaxRows = const []})
      : goods = List.unmodifiable(goods.map((line) => Map<String, String>.unmodifiable(line))),
        details = Map.unmodifiable(details), attachments = List.unmodifiable(attachments),
        additionalFields = List.unmodifiable(additionalFields),
        printedTaxRows = List.unmodifiable(printedTaxRows.map((row) => Map<String, String>.unmodifiable(row)));
  final String id, supplierId, invoiceReference, invoiceDate;
  /// Parsed only for bill-identity checks; the printed date stays unchanged.
  DateTime? get invoiceIssuedDay {
    final value = invoiceDate.trim();
    final indian = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(value);
    final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (indian == null && iso == null) return null;
    final year = int.parse(indian?.group(3) ?? iso!.group(1)!);
    final month = int.parse(indian?.group(2) ?? iso!.group(2)!);
    final day = int.parse(indian?.group(1) ?? iso!.group(3)!);
    final date = DateTime.utc(year, month, day);
    if (year < 1900 || year > 9999 || date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }
  int? get invoiceFinancialYear {
    final date = invoiceIssuedDay;
    return date == null ? null : (date.month < 4 ? date.year - 1 : date.year);
  }
  final DateTime createdAt, updatedAt;
  final List<Map<String, String>> goods;
  final Map<String, String> details;
  final List<WorkspacePurchaseInvoiceAttachment> attachments;
  final List<WorkspacePurchaseAdditionalField> additionalFields;
  final List<Map<String, String>> printedTaxRows;
  static const printedTaxKeys = {'label', 'hsn', 'taxableValue', 'cgstRate', 'cgst',
    'sgstRate', 'sgst', 'utgstRate', 'utgst', 'igstRate', 'igst', 'cessRate', 'cess',
    'taxRate', 'totalTax'};
  static const detailKeys = {'documentType', 'placeOfSupply', 'buyerName', 'buyerAddress',
    'buyerGstin', 'priceBasis', 'taxTreatment', 'reverseCharge', 'billDiscount',
    'freight', 'otherCharges', 'roundOff', 'taxableValue', 'cgst', 'sgst', 'igst',
    'cess', 'invoiceTotal', 'receiptStatus', 'receivedDate', 'paymentStatus',
    'paidAmount', 'paymentMethod', 'paymentReference', 'paymentDate', 'dueDate', 'notes',
    'placeOfSupplyCode', 'buyerUin', 'buyerState', 'buyerStateCode', 'deliveryAddress',
    'deliveryState', 'deliveryStateCode', 'supplyValue', 'sgstAmount', 'utgst',
    'eInvoiceStatus', 'irn', 'ackNumber', 'ackDate', 'qrStatus', 'signatureStatus',
    'eInvoiceDeclaration', 'supplierEmail', 'buyerPhone', 'buyerEmail', 'poReference',
    'documentCopy', 'totalTax', 'amountPayable', 'amountInWords', 'bankName',
    'bankAccount', 'bankIfsc', 'bankBranch', 'upiType', 'upiId', 'paymentQrStatus',
    'terms', 'signatory', 'expectedDeliveryDate', 'shippingTerms', 'paymentTerms',
    'documentTitle', 'originalInvoiceDate', 'printedTotalItems', 'printedTotalQuantity',
    'printedTaxRate', 'printedCgstRate', 'printedSgstRate', 'printedUtgstRate',
    'printedIgstRate', 'printedPaymentMark', 'printedFooter', 'printedSignatoryLabel',
    'printedCompanyLabel', 'printedDeclaration'};
  static const goodsExtraKeys = {'hsn', 'barcode', 'freeQuantity', 'batch', 'expiry',
    'mrp', 'sellingPrice', 'discount', 'gstRate', 'cess', 'lineTotal',
    'receivedQuantity', 'damagedQuantity', 'shortQuantity', 'unitCode', 'taxableValue',
    'cgstRate', 'cgst', 'sgstRate', 'sgst', 'utgstRate', 'utgst', 'igstRate', 'igst', 'cessRate',
    'specifications', 'taxAmount', 'printedSerial'};
  /// Printed rupee amounts only; never rounds input or invents missing zeroes.
  static int? printedPaise(String? input) {
    if (input == null) return null;
    final value = input.trim();
    if (!RegExp(r'^-?\d+(\.\d{1,2})?$').hasMatch(value)) return null;
    final parts = value.replaceFirst('-', '').split('.');
    final paise = int.tryParse(parts[0]);
    if (paise == null || paise > 999999999999) return null;
    final result = paise * 100 + (parts.length == 2 ? int.parse(parts[1].padRight(2, '0')) : 0);
    return value.startsWith('-') ? -result : result;
  }
  static List<String> reviewAmounts(Map<String, String> values) {
    final warnings = <String>[];
    for (final key in const ['invoiceTotal', 'totalTax', 'amountPayable', 'paidAmount',
        'taxableValue', 'supplyValue', 'cgst', 'sgstAmount', 'utgst', 'igst', 'cess',
        'billDiscount', 'freight', 'otherCharges', 'roundOff']) {
      final value = values[key];
      if (value != null && value.trim().isNotEmpty && printedPaise(value) == null) {
        warnings.add('Check the amount format: use rupees with up to two decimal places.');
        break;
      }
    }
    final components = switch (values['taxTreatment']) {
      'CGST + SGST' => ['cgst', 'sgstAmount', 'cess'],
      'CGST + UTGST' => ['cgst', 'utgst', 'cess'],
      'IGST' => ['igst', 'cess'],
      _ => <String>[],
    };
    final total = printedPaise(values['totalTax']);
    // A missing component remains unknown; compare only a fully entered split.
    if (total != null && components.isNotEmpty &&
        components.every((key) => printedPaise(values[key]) != null) &&
        components.fold<int>(0, (sum, key) => sum + printedPaise(values[key])!) != total) {
      warnings.add('Printed tax and the entered tax split differ. Check the original bill.');
    }
    return List.unmodifiable(warnings);
  }
  /// No incomplete HSN summary or rate/quantity inference from invoice totals.
  static List<({String hsn, String rate, int taxable, int tax})> printedHsnSummary(
      List<Map<String, String>> lines) {
    if (lines.isEmpty || lines.any((line) => (line['hsn'] ?? '').trim().isEmpty ||
        printedPaise(line['taxableValue']) == null || printedPaise(line['taxAmount']) == null)) {
      return const [];
    }
    final totals = <(String, String), ({int taxable, int tax})>{};
    for (final line in lines) {
      final key = (line['hsn']!.trim(), line['gstRate'] ?? '');
      final before = totals[key];
      totals[key] = (taxable: (before?.taxable ?? 0) + printedPaise(line['taxableValue'])!,
        tax: (before?.tax ?? 0) + printedPaise(line['taxAmount'])!);
    }
    return List.unmodifiable([for (final entry in totals.entries)
      (hsn: entry.key.$1, rate: entry.key.$2, taxable: entry.value.taxable, tax: entry.value.tax)]);
  }
  // Review an external document without truncating it or blocking a partial draft.
  // These two format hints are not GST/IRN validation or ITC eligibility.
  List<String> get invoiceFormatWarnings => reviewInvoiceFormat(
    invoiceReference, invoiceDate, details['documentType']);
  static List<String> reviewInvoiceFormat(String reference, String issuedOn, String? documentType) {
    if (documentType != 'GST invoice') return const [];
    final warnings = <String>[];
    if (!RegExp(r'^[A-Za-z0-9/-]{1,16}$').hasMatch(reference)) {
      warnings.add('Check invoice number: up to 16 letters, digits, / or -.');
    }
    final match = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(issuedOn);
    bool dateValid = false;
    if (match != null) {
      final day = int.parse(match[1]!), month = int.parse(match[2]!), year = int.parse(match[3]!);
      final date = DateTime(year, month, day);
      dateValid = date.day == day && date.month == month && date.year == year && year > 0;
    }
    if (!dateValid) warnings.add('Check invoice date: use a valid DD/MM/YYYY date.');
    return List.unmodifiable(warnings);
  }
  bool get valid => id.isNotEmpty && supplierId.isNotEmpty &&
      invoiceReference.length <= 120 && invoiceDate.length <= 10 &&
      !updatedAt.isBefore(createdAt) && goods.length <= 200 &&
      details.keys.every(detailKeys.contains) &&
      details.entries.every((entry) => entry.value.length <= (entry.key == 'terms' ? 4000 : 500)) &&
      attachments.length <= 3 && attachments.every((a) => a.valid) &&
      attachments.fold<int>(0, (sum, a) => sum + a.byteLength) <= 20 * 1024 * 1024 &&
      attachments.map((a) => a.digest).toSet().length == attachments.length &&
      printedTaxRows.length <= 100 && printedTaxRows.every((row) =>
        row.keys.every(printedTaxKeys.contains) && row.values.every((value) => value.length <= 200)) &&
      additionalFields.length <= 200 &&
      additionalFields.map((field) => field.id).toSet().length == additionalFields.length &&
      additionalFields.fold<int>(0, (size, field) => size + field.label.length + field.value.length) <= 48000 &&
      additionalFields.every((field) => field.valid &&
        (field.itemIndex == null || field.itemIndex! < goods.length) &&
        (field.summaryIndex == null || field.summaryIndex! < printedTaxRows.length) &&
        (field.sourceDigest == null || attachments.any((a) => a.digest == field.sourceDigest))) &&
      goods.every((line) =>
        const ['productId', 'name', 'pack', 'quantity', 'cost'].every(line.containsKey) &&
        line.keys.every((k) => const ['productId', 'name', 'pack', 'quantity', 'cost'].contains(k) ||
          goodsExtraKeys.contains(k)) &&
        line.entries.every((entry) => entry.value.length <= (entry.key == 'specifications' ? 1000 : 200)));
  Map<String, Object?> toJson() => {'id': id, 'supplierId': supplierId,
    'invoiceReference': invoiceReference, 'invoiceDate': invoiceDate,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'source': 'manual', 'stage': 'draft', 'goods': goods,
    if (details.isNotEmpty) 'details': details,
    if (attachments.isNotEmpty) 'attachments': attachments.map((a) => a.toJson()).toList(),
    if (additionalFields.isNotEmpty) 'additionalFields': additionalFields.map((f) => f.toJson()).toList(),
    if (printedTaxRows.isNotEmpty) 'printedTaxRows': printedTaxRows};
  static WorkspacePurchaseEntryDraft fromJson(Object? raw) {
    const keys = {'id', 'supplierId', 'invoiceReference', 'invoiceDate',
      'createdAt', 'updatedAt', 'source', 'stage', 'goods'};
    if (raw is! Map || !keys.every(raw.containsKey) ||
        !raw.keys.every((k) => keys.contains(k) || k == 'details' || k == 'attachments' ||
          k == 'additionalFields' || k == 'printedTaxRows') ||
        raw['source'] != 'manual' || raw['stage'] != 'draft' || raw['goods'] is! List) {
      throw const FormatException('Invalid purchase draft');
    }
    final draft = WorkspacePurchaseEntryDraft(id: raw['id'] as String,
      supplierId: raw['supplierId'] as String,
      invoiceReference: raw['invoiceReference'] as String,
      invoiceDate: raw['invoiceDate'] as String,
      createdAt: DateTime.parse(raw['createdAt'] as String),
      updatedAt: DateTime.parse(raw['updatedAt'] as String),
      goods: [for (final line in raw['goods'] as List) (line as Map).cast<String, String>()],
      details: raw['details'] == null ? const {} : (raw['details'] as Map).cast<String, String>(),
      attachments: raw['attachments'] == null ? const [] :
        [for (final a in raw['attachments'] as List) WorkspacePurchaseInvoiceAttachment.fromJson(a)],
      additionalFields: raw['additionalFields'] == null ? const [] :
        [for (final f in raw['additionalFields'] as List) WorkspacePurchaseAdditionalField.fromJson(f)],
      printedTaxRows: raw['printedTaxRows'] == null ? const [] :
        [for (final row in raw['printedTaxRows'] as List) (row as Map).cast<String, String>()]);
    if (!draft.valid) throw const FormatException('Invalid purchase draft');
    return draft;
  }
}

/// One recoverable entry plus its private supplier identities, atomically saved.
/// This is not the posted purchase register or a financial journal.
/// A reviewed, unposted purchase copy; independent of the editable draft.
class WorkspacePurchaseSavedCopy {
  WorkspacePurchaseSavedCopy({required this.id, required this.storeName,
    required this.revision, required this.savedAt, required this.supplier,
    required this.draft, required Map<String, String> labels})
      : labels = Map.unmodifiable(labels);
  final String id, storeName;
  final int revision;
  final DateTime savedAt;
  final WorkspaceSupplierProfile supplier;
  final WorkspacePurchaseEntryDraft draft;
  final Map<String, String> labels;
  bool get valid => id.trim().isNotEmpty && id.length <= 240 &&
    storeName.trim().isNotEmpty && storeName.length <= 200 && revision >= 1 &&
    supplier.validationError == null && draft.valid && draft.supplierId == supplier.id &&
    !savedAt.isBefore(draft.updatedAt) && labels.length <= 200 &&
    labels.entries.every((e) => e.key.isNotEmpty && e.key.length <= 120 &&
      e.value.isNotEmpty && e.value.length <= 200);
  Map<String, Object?> toJson() => {'id': id, 'storeName': storeName,
    'revision': revision, 'savedAt': savedAt.toIso8601String(),
    'supplier': supplier.toJson(), 'draft': draft.toJson(), 'labels': labels};
  static WorkspacePurchaseSavedCopy fromJson(Object? raw) {
    const keys = {'id', 'storeName', 'revision', 'savedAt', 'supplier', 'draft', 'labels'};
    try {
      if (raw is! Map || raw.length != keys.length || !raw.keys.every(keys.contains) ||
          raw['labels'] is! Map) { throw const FormatException('Invalid purchase copy'); }
      final copy = WorkspacePurchaseSavedCopy(id: raw['id'] as String,
        storeName: raw['storeName'] as String, revision: raw['revision'] as int,
        savedAt: DateTime.parse(raw['savedAt'] as String),
        supplier: WorkspaceSupplierProfile.fromJson(raw['supplier']),
        draft: WorkspacePurchaseEntryDraft.fromJson(raw['draft']),
        labels: Map<String, String>.from(raw['labels'] as Map));
      if (!copy.valid) throw const FormatException('Invalid purchase copy');
      return copy;
    } on Object {
      throw const FormatException('Saved purchase copy needs recovery. Records have been kept.');
    }
  }
}

enum WorkspaceOpeningBillInclusion { unknown, included, excluded }

/// Retailer assertion about one exact reviewed bill; not an amount allocation.
class WorkspaceOpeningBillLink {
  const WorkspaceOpeningBillLink({
    required this.copyId,
    required this.copyRevision,
    required this.draftId,
    required this.inclusion,
  });
  final String copyId, draftId;
  final int copyRevision;
  final WorkspaceOpeningBillInclusion inclusion;
  Map<String, Object?> toJson() => {
    'copyId': copyId,
    'copyRevision': copyRevision,
    'draftId': draftId,
    'inclusion': inclusion.name,
  };
  static WorkspaceOpeningBillLink fromJson(Object? raw) {
    const keys = {'copyId', 'copyRevision', 'draftId', 'inclusion'};
    if (raw is! Map ||
        raw.length != keys.length ||
        !raw.keys.every(keys.contains)) {
      throw const FormatException('Invalid opening bill link');
    }
    final result = WorkspaceOpeningBillLink(
      copyId: raw['copyId'] as String,
      copyRevision: raw['copyRevision'] as int,
      draftId: raw['draftId'] as String,
      inclusion: WorkspaceOpeningBillInclusion.values.byName(
        raw['inclusion'] as String,
      ),
    );
    if (result.copyId.isEmpty ||
        result.draftId.isEmpty ||
        result.copyRevision < 1) {
      throw const FormatException('Invalid opening bill identity');
    }
    return result;
  }
}

/// Saved, unposted starting-balance evidence. Never a current payable projection.
class WorkspaceSupplierOpeningRecord {
  WorkspaceSupplierOpeningRecord({
    required this.id,
    required this.basisId,
    required this.account,
    required this.store,
    required this.qa,
    required this.supplierId,
    required this.revision,
    required this.asOfDate,
    required this.savedAt,
    required this.amountMinor,
    required this.supplierCredit,
    required this.sourceNote,
    List<WorkspaceOpeningBillLink> bills = const [],
  }) : bills = List.unmodifiable(bills);
  final String id, basisId, account, store, supplierId, asOfDate, sourceNote;
  final bool qa, supplierCredit;
  final int revision;
  final DateTime savedAt;
  final int? amountMinor;
  final List<WorkspaceOpeningBillLink> bills;
  bool get valid {
    final date = DateTime.tryParse(asOfDate);
    return [
          id,
          basisId,
          account,
          store,
          supplierId,
        ].every((v) => v.trim().isNotEmpty && v.length <= 240) &&
        revision >= 1 &&
        RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(asOfDate) &&
        date != null &&
        date.toIso8601String().substring(0, 10) == asOfDate &&
        (amountMinor == null ||
            (amountMinor! >= 0 && amountMinor! <= 999999999999)) &&
        sourceNote.trim().isNotEmpty &&
        sourceNote.length <= 4000 &&
        bills.length <= 1000 &&
        bills.map((b) => b.copyId).toSet().length == bills.length;
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'basisId': basisId,
    'account': account,
    'store': store,
    'qa': qa,
    'supplierId': supplierId,
    'revision': revision,
    'asOfDate': asOfDate,
    'savedAt': savedAt.toIso8601String(),
    'currency': 'INR',
    'amountMinor': amountMinor,
    'supplierCredit': supplierCredit,
    'sourceNote': sourceNote,
    'bills': bills.map((b) => b.toJson()).toList(),
  };
  static WorkspaceSupplierOpeningRecord fromJson(Object? raw) {
    const keys = {
      'id',
      'basisId',
      'account',
      'store',
      'qa',
      'supplierId',
      'revision',
      'asOfDate',
      'savedAt',
      'currency',
      'amountMinor',
      'supplierCredit',
      'sourceNote',
      'bills',
    };
    try {
      if (raw is! Map ||
          raw.length != keys.length ||
          !raw.keys.every(keys.contains) ||
          raw['currency'] != 'INR' ||
          raw['bills'] is! List ||
          (raw['bills'] as List).length > 1000) {
        throw const FormatException('Invalid opening record');
      }
      final result = WorkspaceSupplierOpeningRecord(
        id: raw['id'] as String,
        basisId: raw['basisId'] as String,
        account: raw['account'] as String,
        store: raw['store'] as String,
        qa: raw['qa'] as bool,
        supplierId: raw['supplierId'] as String,
        revision: raw['revision'] as int,
        asOfDate: raw['asOfDate'] as String,
        savedAt: DateTime.parse(raw['savedAt'] as String),
        amountMinor: raw['amountMinor'] as int?,
        supplierCredit: raw['supplierCredit'] as bool,
        sourceNote: raw['sourceNote'] as String,
        bills: [
          for (final b in raw['bills'] as List)
            WorkspaceOpeningBillLink.fromJson(b),
        ],
      );
      if (!result.valid) throw const FormatException('Invalid opening record');
      return result;
    } on Object {
      throw const FormatException(
        'Opening records need recovery. Records have been kept.',
      );
    }
  }
}

/// Frozen receiving review. Saving this is not a receipt commit or Stock update.
/// Its original operation identity survives closing the editor and restarting.
class WorkspaceSupplierGoodsReceiptDraft {
  const WorkspaceSupplierGoodsReceiptDraft({required this.supplierId,
    required this.revision, required this.receipt});
  final String supplierId;
  final int revision;
  final WorkspaceSupplierGoodsReceipt receipt;
  bool get valid => supplierId.trim().isNotEmpty && supplierId.length <= 240 &&
      revision > 0 && receipt.valid;
  Map<String, Object?> toJson() => {'supplierId': supplierId,
    'revision': revision, 'receipt': receipt.toJson()};
  static WorkspaceSupplierGoodsReceiptDraft fromJson(Object? raw) {
    const keys = {'supplierId', 'revision', 'receipt'};
    if (raw is! Map || raw.length != keys.length || !raw.keys.every(keys.contains)) {
      throw const FormatException('Invalid receiving review');
    }
    final result = WorkspaceSupplierGoodsReceiptDraft(supplierId: raw['supplierId'] as String,
      revision: raw['revision'] as int,
      receipt: WorkspaceSupplierGoodsReceipt.fromJson(raw['receipt']));
    if (!result.valid) throw const FormatException('Invalid receiving review');
    return result;
  }
}

/// Audit-only cancellation of a verified uncommitted receiving review. Never
/// erases its snapshot or reverses a saved receipt, Stock movement or payment.
class WorkspaceGoodsReceiptReviewCancellation {
  const WorkspaceGoodsReceiptReviewCancellation({required this.receiptId,
    required this.supplierId, required this.revision, required this.cancelledAt,
    required this.reason});
  final String receiptId, supplierId, reason;
  final int revision;
  final DateTime cancelledAt;
  bool get valid => [receiptId, supplierId].every((v) => v.trim().isNotEmpty && v.length <= 240) &&
      revision > 0 && reason.trim().isNotEmpty && reason.length <= 1000;
  Map<String, Object?> toJson() => {'receiptId': receiptId, 'supplierId': supplierId,
    'revision': revision, 'cancelledAt': cancelledAt.toUtc().toIso8601String(), 'reason': reason};
  static WorkspaceGoodsReceiptReviewCancellation fromJson(Object? raw) {
    const keys = {'receiptId', 'supplierId', 'revision', 'cancelledAt', 'reason'};
    if (raw is! Map || raw.length != keys.length || !raw.keys.every(keys.contains)) {
      throw const FormatException('Invalid receiving review cancellation');
    }
    final value = WorkspaceGoodsReceiptReviewCancellation(receiptId: raw['receiptId'] as String,
      supplierId: raw['supplierId'] as String, revision: raw['revision'] as int,
      cancelledAt: DateTime.parse(raw['cancelledAt'] as String), reason: raw['reason'] as String);
    if (!value.valid) throw const FormatException('Invalid receiving review cancellation');
    return value;
  }
}

/// Immutable review of a bill-to-delivery match, saved before account posting.
/// Its operation identity and quantities survive editor/process interruption.
class WorkspaceSupplierBillGoodsReview {
  const WorkspaceSupplierBillGoodsReview({required this.supplierId,
    required this.revision, required this.allocation});
  final String supplierId;
  final int revision;
  final WorkspaceSupplierBillGoodsAllocation allocation;
  bool get valid => supplierId.trim().isNotEmpty && supplierId.length <= 240 &&
      revision > 0 && allocation.valid;
  Map<String, Object?> toJson() => {'supplierId': supplierId,
    'revision': revision, 'allocation': allocation.toJson()};
  static WorkspaceSupplierBillGoodsReview fromJson(Object? raw) {
    const keys = {'supplierId', 'revision', 'allocation'};
    if (raw is! Map || raw.length != keys.length || !raw.keys.every(keys.contains)) {
      throw const FormatException('Invalid bill goods review');
    }
    final result = WorkspaceSupplierBillGoodsReview(supplierId: raw['supplierId'] as String,
      revision: raw['revision'] as int,
      allocation: WorkspaceSupplierBillGoodsAllocation.fromJson(raw['allocation']));
    if (!result.valid) throw const FormatException('Invalid bill goods review');
    return result;
  }
}

/// Cancels an unposted matching attempt, never the bill or received goods.
class WorkspaceBillGoodsReviewCancellation {
  const WorkspaceBillGoodsReviewCancellation({required this.operationId,
    required this.supplierId, required this.revision, required this.cancelledAt,
    required this.reason});
  final String operationId, supplierId, reason;
  final int revision;
  final DateTime cancelledAt;
  bool get valid => [operationId, supplierId].every((v) => v.trim().isNotEmpty && v.length <= 240) &&
    revision > 0 && reason.trim().isNotEmpty && reason.length <= 1000;
  Map<String, Object?> toJson() => {'operationId': operationId, 'supplierId': supplierId,
    'revision': revision, 'cancelledAt': cancelledAt.toUtc().toIso8601String(), 'reason': reason};
  static WorkspaceBillGoodsReviewCancellation fromJson(Object? raw) {
    const keys = {'operationId', 'supplierId', 'revision', 'cancelledAt', 'reason'};
    if (raw is! Map || raw.length != keys.length || !raw.keys.every(keys.contains)) {
      throw const FormatException('Invalid bill goods cancellation');
    }
    final result = WorkspaceBillGoodsReviewCancellation(operationId: raw['operationId'] as String,
      supplierId: raw['supplierId'] as String, revision: raw['revision'] as int,
      cancelledAt: DateTime.parse(raw['cancelledAt'] as String), reason: raw['reason'] as String);
    if (!result.valid) throw const FormatException('Invalid bill goods cancellation');
    return result;
  }
}

class WorkspacePurchaseEntryBook {
  WorkspacePurchaseEntryBook({
    required this.account,
    required this.store,
    required this.qa,
    required this.revision,
    required List<WorkspaceSupplierProfile> profiles,
    this.draft,
    List<WorkspacePurchaseSavedCopy> copies = const [],
    List<WorkspaceSupplierOpeningRecord> openingRecords = const [],
    List<WorkspaceSupplierGoodsReceiptDraft> goodsReceiptDrafts = const [],
    List<WorkspaceGoodsReceiptReviewCancellation> goodsReceiptCancellations = const [],
    List<WorkspaceSupplierBillGoodsReview> billGoodsReviews = const [],
    List<WorkspaceBillGoodsReviewCancellation> billGoodsCancellations = const [],
  }) : profiles = List.unmodifiable(profiles),
       copies = List.unmodifiable(copies),
       openingRecords = List.unmodifiable(openingRecords),
       goodsReceiptDrafts = List.unmodifiable(goodsReceiptDrafts),
       goodsReceiptCancellations = List.unmodifiable(goodsReceiptCancellations),
       billGoodsReviews = List.unmodifiable(billGoodsReviews),
       billGoodsCancellations = List.unmodifiable(billGoodsCancellations);
  final String account, store;
  final bool qa;
  final int revision;
  final List<WorkspaceSupplierProfile> profiles;
  final WorkspacePurchaseEntryDraft? draft;
  final List<WorkspacePurchaseSavedCopy> copies;
  final List<WorkspaceSupplierOpeningRecord> openingRecords;
  final List<WorkspaceSupplierGoodsReceiptDraft> goodsReceiptDrafts;
  final List<WorkspaceGoodsReceiptReviewCancellation> goodsReceiptCancellations;
  final List<WorkspaceSupplierBillGoodsReview> billGoodsReviews;
  final List<WorkspaceBillGoodsReviewCancellation> billGoodsCancellations;
  WorkspaceSupplierOpeningRecord? openingRecordFor(String supplierId) =>
      openingRecords.where((r) => r.supplierId == supplierId).lastOrNull;

  /// Older revisions remain in history, but do not reserve corrected bill keys.
  List<WorkspacePurchaseSavedCopy> get latestReviewedCopies {
    final latest = <String, List<WorkspacePurchaseSavedCopy>>{};
    for (final copy in copies) {
      final previous = latest[copy.draft.id];
      if (previous == null || copy.revision > previous.first.revision) {
        latest[copy.draft.id] = [copy];
      } else if (copy.revision == previous.first.revision) {
        // Ambiguous legacy records retain both keys and cannot unlock replacement.
        previous.add(copy);
      }
    }
    return List.unmodifiable(latest.values.expand((copies) => copies));
  }

  bool get draftHasReviewedCopy {
    if (draft == null) return false;
    final latest = latestReviewedCopies
        .where((copy) => copy.draft.id == draft!.id)
        .toList();
    return latest.length == 1 &&
        jsonEncode(latest.single.draft.toJson()) == jsonEncode(draft!.toJson());
  }

  WorkspacePurchaseSavedCopy? duplicateInvoice(
    WorkspacePurchaseEntryDraft candidate,
  ) {
    final reference = candidate.invoiceReference.trim().toLowerCase();
    final year = candidate.invoiceFinancialYear;
    if (reference.isEmpty || year == null) return null;
    return latestReviewedCopies
        .where(
          (copy) =>
              copy.draft.id != candidate.id &&
              copy.draft.supplierId == candidate.supplierId &&
              copy.draft.invoiceFinancialYear == year &&
              copy.draft.invoiceReference.trim().toLowerCase() == reference,
        )
        .firstOrNull;
  }

  Map<String, Object?> toJson() => {
    'version': 1,
    'account': account,
    'store': store,
    'qa': qa,
    'revision': revision,
    'profiles': profiles.map((p) => p.toJson()).toList(),
    'draft': draft?.toJson(),
    if (copies.isNotEmpty) 'copies': copies.map((c) => c.toJson()).toList(),
    if (openingRecords.isNotEmpty)
      'openingRecords': openingRecords.map((r) => r.toJson()).toList(),
    if (goodsReceiptDrafts.isNotEmpty)
      'goodsReceiptDrafts': goodsReceiptDrafts.map((r) => r.toJson()).toList(),
    if (goodsReceiptCancellations.isNotEmpty)
      'goodsReceiptCancellations': goodsReceiptCancellations.map((r) => r.toJson()).toList(),
    if (billGoodsReviews.isNotEmpty)
      'billGoodsReviews': billGoodsReviews.map((r) => r.toJson()).toList(),
    if (billGoodsCancellations.isNotEmpty)
      'billGoodsCancellations': billGoodsCancellations.map((r) => r.toJson()).toList(),
  };
  static WorkspacePurchaseEntryBook fromJson(Object? raw) {
    const keys = {
      'version',
      'account',
      'store',
      'qa',
      'revision',
      'profiles',
      'draft',
      'copies',
      'openingRecords',
      'goodsReceiptDrafts',
      'goodsReceiptCancellations',
      'billGoodsReviews',
      'billGoodsCancellations',
    };
    try {
      if (raw is! Map ||
          !keys
              .difference({'copies', 'openingRecords', 'goodsReceiptDrafts', 'goodsReceiptCancellations', 'billGoodsReviews', 'billGoodsCancellations'})
              .every(raw.containsKey) ||
          !raw.keys.every(keys.contains) ||
          raw['version'] != 1 ||
          raw['profiles'] is! List ||
          (raw['profiles'] as List).length > 10000 ||
          (raw.containsKey('copies') &&
              (raw['copies'] is! List ||
                  (raw['copies'] as List).length > 1000)) ||
          (raw.containsKey('openingRecords') &&
              (raw['openingRecords'] is! List ||
                  (raw['openingRecords'] as List).length > 1000)) ||
          (raw.containsKey('goodsReceiptDrafts') &&
            (raw['goodsReceiptDrafts'] is! List ||
              (raw['goodsReceiptDrafts'] as List).length > 1000)) ||
          (raw.containsKey('goodsReceiptCancellations') &&
            (raw['goodsReceiptCancellations'] is! List ||
              (raw['goodsReceiptCancellations'] as List).length > 1000)) ||
          (raw.containsKey('billGoodsReviews') &&
            (raw['billGoodsReviews'] is! List ||
              (raw['billGoodsReviews'] as List).length > 1000)) ||
          (raw.containsKey('billGoodsCancellations') &&
            (raw['billGoodsCancellations'] is! List ||
              (raw['billGoodsCancellations'] as List).length > 1000))) {
        throw const FormatException('Invalid supplier directory');
      }
      final result = WorkspacePurchaseEntryBook(
        account: raw['account'] as String,
        store: raw['store'] as String,
        qa: raw['qa'] as bool,
        revision: raw['revision'] as int,
        profiles: [
          for (final p in raw['profiles'] as List)
            WorkspaceSupplierProfile.fromJson(p),
        ],
        draft: raw['draft'] == null
            ? null
            : WorkspacePurchaseEntryDraft.fromJson(raw['draft']),
        copies: [
          for (final c in (raw['copies'] as List? ?? const []))
            WorkspacePurchaseSavedCopy.fromJson(c),
        ],
        openingRecords: [
          for (final r in (raw['openingRecords'] as List? ?? const []))
            WorkspaceSupplierOpeningRecord.fromJson(r),
        ],
        goodsReceiptDrafts: [for (final r in (raw['goodsReceiptDrafts'] as List? ?? const []))
          WorkspaceSupplierGoodsReceiptDraft.fromJson(r)],
        goodsReceiptCancellations: [for (final r in (raw['goodsReceiptCancellations'] as List? ?? const []))
          WorkspaceGoodsReceiptReviewCancellation.fromJson(r)],
        billGoodsReviews: [for (final r in (raw['billGoodsReviews'] as List? ?? const []))
          WorkspaceSupplierBillGoodsReview.fromJson(r)],
        billGoodsCancellations: [for (final r in (raw['billGoodsCancellations'] as List? ?? const []))
          WorkspaceBillGoodsReviewCancellation.fromJson(r)],
      );
      final ids = <String>{};
      final copyIds = <String>{};
      if (result.account.trim().isEmpty ||
          result.store.trim().isEmpty ||
          result.revision < 1 ||
          result.profiles.any((p) => !ids.add(p.id)) ||
          (result.draft != null &&
              (!ids.contains(result.draft!.supplierId) ||
                  result.draft!.attachments.any(
                    (a) =>
                        a.owner !=
                        jsonEncode([
                          result.account,
                          result.store,
                          result.qa,
                          result.draft!.id,
                        ]),
                  ))) ||
          result.copies.any(
            (c) =>
                !copyIds.add(c.id) ||
                c.revision > result.revision ||
                c.draft.attachments.any(
                  (a) =>
                      a.owner !=
                      jsonEncode([
                        result.account,
                        result.store,
                        result.qa,
                        c.draft.id,
                      ]),
                ),
          )) {
        throw const FormatException('Invalid supplier scope');
      }
      final openingIds = <String>{};
      final basisBySupplier = <String, String>{};
      final supplierByBasis = <String, String>{};
      var previousRevision = 0;
      for (final r in result.openingRecords) {
        if (!openingIds.add(r.id) ||
            r.account != result.account ||
            r.store != result.store ||
            r.qa != result.qa ||
            !ids.contains(r.supplierId) ||
            r.revision <= previousRevision ||
            r.revision > result.revision ||
            (basisBySupplier[r.supplierId] != null &&
                basisBySupplier[r.supplierId] != r.basisId) ||
            (supplierByBasis[r.basisId] != null &&
                supplierByBasis[r.basisId] != r.supplierId)) {
          throw const FormatException(
            'Invalid opening record scope or revision',
          );
        }
        for (final b in r.bills) {
          final copy = result.copies.where((c) => c.id == b.copyId).firstOrNull;
          if (copy == null ||
              copy.revision != b.copyRevision ||
              copy.draft.id != b.draftId ||
              copy.draft.supplierId != r.supplierId ||
              copy.revision >= r.revision) {
            throw const FormatException('Invalid opening bill relationship');
          }
        }
        previousRevision = r.revision;
        basisBySupplier[r.supplierId] = r.basisId;
        supplierByBasis[r.basisId] = r.supplierId;
      }
      final receiptIds = <String>{};
      var receiptRevision = 0;
      for (final review in result.goodsReceiptDrafts) {
        if (!receiptIds.add(review.receipt.id) || !ids.contains(review.supplierId) ||
            review.revision <= receiptRevision || review.revision > result.revision) {
          throw const FormatException('Invalid receiving review relationship');
        }
        receiptRevision = review.revision;
      }
      final allocationIds = <String>{};
      var allocationRevision = 0;
      for (final review in result.billGoodsReviews) {
        final link = review.allocation;
        final copy = result.copies.where((c) => c.id == link.copyId).singleOrNull;
        final receiptReview = result.goodsReceiptDrafts.where((r) => r.receipt.id == link.receiptId).singleOrNull;
        final line = receiptReview?.receipt.lines.where((l) => l.sourceLineId == link.receiptLineId).singleOrNull;
        if (!review.valid || !allocationIds.add(link.operationId) || !ids.contains(review.supplierId) ||
            review.revision <= allocationRevision || review.revision > result.revision ||
            copy == null || copy.supplier.id != review.supplierId || copy.draft.id != link.billId ||
            copy.revision != link.copyRevision || copy.revision >= review.revision ||
            link.billLineIndex >= copy.draft.goods.length ||
            copy.draft.goods[link.billLineIndex]['productId'] != link.productId ||
            receiptReview == null || receiptReview.supplierId != review.supplierId ||
            receiptReview.revision >= review.revision || line == null || line.productId != link.productId ||
            link.linkedAt.isBefore(receiptReview.receipt.recordedAt)) {
          throw const FormatException('Invalid bill goods review relationship');
        }
        allocationRevision = review.revision;
      }
      final cancelledIds = <String>{};
      var cancellationRevision = 0;
      for (final cancellation in result.goodsReceiptCancellations) {
        final review = result.goodsReceiptDrafts.where((r) => r.receipt.id == cancellation.receiptId).firstOrNull;
        if (!cancelledIds.add(cancellation.receiptId) || review == null ||
            review.supplierId != cancellation.supplierId || cancellation.revision <= review.revision ||
            cancellation.revision <= cancellationRevision || cancellation.revision > result.revision ||
            cancellation.cancelledAt.isBefore(review.receipt.recordedAt)) {
          throw const FormatException('Invalid receiving cancellation relationship');
        }
        cancellationRevision = cancellation.revision;
      }
      final cancelledAllocationIds = <String>{};
      var cancelledAllocationRevision = 0;
      for (final cancellation in result.billGoodsCancellations) {
        final review = result.billGoodsReviews.where((r) => r.allocation.operationId == cancellation.operationId).singleOrNull;
        if (!cancelledAllocationIds.add(cancellation.operationId) || review == null ||
            review.supplierId != cancellation.supplierId || cancellation.revision <= review.revision ||
            cancellation.revision <= cancelledAllocationRevision || cancellation.revision > result.revision ||
            cancellation.cancelledAt.isBefore(review.allocation.linkedAt)) {
          throw const FormatException('Invalid bill goods cancellation relationship');
        }
        cancelledAllocationRevision = cancellation.revision;
      }
      return result;
    } on Object {
      throw const FormatException(
        'Saved suppliers need recovery. Records have been kept.',
      );
    }
  }
}

enum WorkspaceStockEntryMethod { catalogue, manual, csv }

/// Original retailer-entered stock facts, not a bill, receipt or payable.
/// Null on legacy/nonqualifying routes means the entry source is unverified.
class WorkspaceStockEntry {
  const WorkspaceStockEntry({
    required this.method,
    required this.productId,
    required this.sku,
    required this.pack,
    required this.stockMode,
    required this.quantity,
    required this.purchasePriceRupees,
    required this.recordedAt,
    required this.stockAsOf,
    this.packMeasure,
  });

  final WorkspaceStockEntryMethod method;
  final String productId, sku, pack;
  final WorkspaceStockMode stockMode;
  // Availability-only has no counted quantity; never use its placeholder count.
  final int? quantity;
  final int purchasePriceRupees;
  final DateTime recordedAt, stockAsOf;
  final WorkspacePackMeasure? packMeasure;

  bool get valid =>
      [productId, sku, pack].every((s) => s.trim().isNotEmpty && s.length <= 16000) &&
      purchasePriceRupees > 0 && purchasePriceRupees <= 2147483647 &&
      !stockAsOf.isAfter(recordedAt) &&
      (stockMode == WorkspaceStockMode.availabilityOnly
          ? quantity == null
          : quantity != null && quantity! >= 0 && quantity! <= 2147483647) &&
      (packMeasure == null || packMeasure!.valid);

  Map<String, Object?> toJson() => {
    'version': 1, 'method': method.name, 'productId': productId, 'sku': sku,
    'pack': pack, 'stockMode': stockMode.name, 'quantity': quantity,
    'purchasePriceRupees': purchasePriceRupees,
    'recordedAt': recordedAt.toUtc().toIso8601String(),
    'stockAsOf': stockAsOf.toUtc().toIso8601String(),
    'packMeasure': packMeasure?.toJson(),
  };

  String get contentIdentity => jsonEncode(toJson());

  static WorkspaceStockEntry? fromJson(Object? raw) {
    if (raw == null) return null;
    const invalid = FormatException('Original stock-entry details need recovery.');
    try {
      if (raw is! Map || raw['version'] != 1) throw invalid;
      final measure = WorkspacePackMeasure.fromJson(raw['packMeasure']);
      if (raw['packMeasure'] != null && measure == null) throw invalid;
      final entry = WorkspaceStockEntry(
        method: WorkspaceStockEntryMethod.values.byName(raw['method'] as String),
        productId: raw['productId'] as String, sku: raw['sku'] as String,
        pack: raw['pack'] as String,
        stockMode: WorkspaceStockMode.values.byName(raw['stockMode'] as String),
        quantity: raw['quantity'] as int?,
        purchasePriceRupees: raw['purchasePriceRupees'] as int,
        recordedAt: DateTime.parse(raw['recordedAt'] as String),
        stockAsOf: DateTime.parse(raw['stockAsOf'] as String), packMeasure: measure,
      );
      if (!entry.valid) throw invalid;
      return entry;
    } on FormatException { rethrow; }
      on TypeError { throw invalid; }
      on ArgumentError { throw invalid; }
  }
}

/// Device-owned inventory only. QA data cannot be restored into production.
/// This checkpoint carries no invoice, payment, publication or backend authority.
class WorkspaceSavedInventory {
  WorkspaceSavedInventory({
    required this.account,
    required this.store,
    required this.qa,
    required this.revision,
    required this.savedAt,
    required List<WorkspaceCatalogueItem> products,
    required List<WorkspaceStockMovement> movements,
    this.manualReceiptCheckpointRevision,
  }) : products = List.unmodifiable(products),
       movements = List.unmodifiable(movements);
  final String account, store;
  final bool qa;
  final int revision;
  final DateTime savedAt;
  final List<WorkspaceCatalogueItem> products;
  final List<WorkspaceStockMovement> movements;
  /// Last authoritative manual-receipt checkpoint projected here. Retained even
  /// when all goods were already in Stock or damaged and no movement was added.
  final int? manualReceiptCheckpointRevision;

  Map<String, Object?> toJson() => {
    'version': products.any((p) => p.stockEntry != null) ? 2 : 1,
    'account': account,
    'store': store,
    'qa': qa,
    'revision': revision,
    'savedAt': savedAt.toUtc().toIso8601String(),
    if (manualReceiptCheckpointRevision != null)
      'manualReceiptCheckpointRevision': manualReceiptCheckpointRevision,
    'products': products.map((p) => p.toInventoryJson()).toList(),
    'movements': [
      for (final m in movements)
        {
          'id': m.id,
          'productId': m.productId,
          'productLabel': m.productLabel,
          'kind': m.kind.name,
          'quantityDelta': m.quantityDelta,
          'reason': m.reason,
          'occurredAt': m.occurredAt.toUtc().toIso8601String(),
          'referenceKind': m.referenceKind?.name,
          'referenceId': m.referenceId,
        },
    ],
  };

  static WorkspaceSavedInventory fromJson(Object? raw) {
    const invalid = FormatException(
      'Saved inventory needs recovery. Its data has been kept.',
    );
    try {
      if (raw is! Map ||
          !const [1, 2].contains(raw['version']) ||
          raw['products'] is! List ||
          raw['movements'] is! List) {
        throw invalid;
      }
      if ((raw['products'] as List).length > 10000) throw invalid;
      final result = WorkspaceSavedInventory(
        account: raw['account'] as String,
        store: raw['store'] as String,
        qa: raw['qa'] as bool,
        revision: raw['revision'] as int,
        savedAt: DateTime.parse(raw['savedAt'] as String),
        manualReceiptCheckpointRevision: raw['manualReceiptCheckpointRevision'] as int?,
        products: [
          for (final p in raw['products'] as List)
            WorkspaceCatalogueItem.fromInventoryJson(p),
        ],
        movements: [
          for (final m in raw['movements'] as List)
            WorkspaceStockMovement(
              id: m['id'] as String,
              productId: m['productId'] as String,
              productLabel: m['productLabel'] as String,
              kind: WorkspaceStockMovementKind.values.byName(
                m['kind'] as String,
              ),
              quantityDelta: m['quantityDelta'] as int,
              reason: m['reason'] as String,
              occurredAt: DateTime.parse(m['occurredAt'] as String),
              referenceKind: m['referenceKind'] == null
                  ? null
                  : WorkspaceStockReferenceKind.values.byName(
                      m['referenceKind'] as String,
                    ),
              referenceId: m['referenceId'] as String?,
            ),
        ],
      );
      final ids = <String>{};
      final movements = <String>{};
      if (result.account.trim().isEmpty ||
          raw['version'] != (result.products.any((p) => p.stockEntry != null) ? 2 : 1) ||
          result.store.trim().isEmpty ||
          result.revision < 1 ||
          (raw.containsKey('manualReceiptCheckpointRevision') &&
              raw['manualReceiptCheckpointRevision'] == null) ||
          (result.manualReceiptCheckpointRevision == null &&
              result.movements.any((m) =>
                  m.referenceKind == WorkspaceStockReferenceKind.manualSupplierReceipt)) ||
          (result.manualReceiptCheckpointRevision != null &&
              (result.manualReceiptCheckpointRevision! <= 0 ||
               result.manualReceiptCheckpointRevision! > 2147483647)) ||
          result.products.any(
            (p) =>
                !ids.add(p.id) ||
                (p.stockEntry != null &&
                    (!p.stockEntry!.valid || p.stockEntry!.productId != p.id ||
                     p.stockEntry!.recordedAt.isAfter(result.savedAt))) ||
                (!result.qa &&
                    p.cataloguePhoto?.status ==
                        WorkspaceCataloguePhotoStatus.testOnly),
          ) ||
          result.movements.any(
            (m) =>
                !m.valid ||
                !movements.add(m.id) ||
                m.occurredAt.isAfter(result.savedAt),
          )) {
        throw invalid;
      }
      return result;
    } on FormatException {
      rethrow;
    } on TypeError {
      throw invalid;
    } on ArgumentError {
      throw invalid;
    } on NoSuchMethodError {
      throw invalid;
    }
  }
}

/// Private, device-retained retailer media. Never publication approval or a URL.
/// The enclosing inventory owns this reference; the scoped media store owns bytes.
class WorkspacePrivateProductPhoto {
  const WorkspacePrivateProductPhoto({
    required this.owner,
    required this.identity,
    required this.sha256,
    required this.byteLength,
    required this.width,
    required this.height,
  });

  final String owner, identity, sha256;
  final int byteLength, width, height;

  static String identityOf(WorkspaceCatalogueItem product) => jsonEncode([
    product.id,
    product.canonicalId,
    product.brand,
    product.title,
    product.variant,
    product.pack,
    product.barcode,
  ]);

  bool matches(WorkspaceCatalogueItem product) =>
      identity == identityOf(product);

  Map<String, Object?> toJson() => {
    'version': 1,
    'owner': owner,
    'identity': identity,
    'sha256': sha256,
    'byteLength': byteLength,
    'width': width,
    'height': height,
  };

  static WorkspacePrivateProductPhoto? fromJson(Object? raw) {
    if (raw == null) return null;
    const invalid = FormatException('Saved product photo needs recovery.');
    if (raw is! Map || raw['version'] != 1) throw invalid;
    final owner = raw['owner'],
        digest = raw['sha256'],
        identity = raw['identity'];
    final length = raw['byteLength'],
        width = raw['width'],
        height = raw['height'];
    final hash = RegExp(r'^[a-f0-9]{64}$');
    if (owner is! String ||
        !hash.hasMatch(owner) ||
        digest is! String ||
        !hash.hasMatch(digest) ||
        identity is! String ||
        identity.isEmpty ||
        identity.length > 112000 ||
        length is! int ||
        length <= 0 ||
        length > 10 * 1024 * 1024 ||
        width is! int ||
        width <= 0 ||
        width > 2400 ||
        height is! int ||
        height <= 0 ||
        height > 2400) {
      throw invalid;
    }
    return WorkspacePrivateProductPhoto(
      owner: owner,
      identity: identity,
      sha256: digest,
      byteLength: length,
      width: width,
      height: height,
    );
  }
}

class WorkspaceCatalogueItem {
  const WorkspaceCatalogueItem({
    required this.id,
    required this.canonicalId,
    required this.categoryId,
    required this.brand,
    required this.title,
    required this.variant,
    required this.pack,
    required this.sku,
    required this.barcode,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.unitPrice,
    required this.stock,
    required this.deliveryPromise,
    required this.origin,
    required this.visualLabel,
    required this.visualKind,
    this.mrp,
    this.minimumOrder = 1,
    this.returnPolicy,
    this.requiresPrescription = false,
    this.composition,
    this.regulatoryNote,
    this.compliance,
    this.available = true,
    this.publicListing = true,
    this.counterSaleEnabled,
    this.stockMode = WorkspaceStockMode.exactQuantity,
    this.lowStockThreshold = 5,
    this.cataloguePhoto,
    this.privatePhoto,
    this.catalogueFactsRequireReview = false,
    this.packMeasure,
    this.wholesaleOffer,
    this.retailEnabled = true,
    this.content = const WorkspaceProductContent(),
    this.stockEntry,
  });

  final String id;
  final String canonicalId;
  final String categoryId;
  final String brand;
  final String title;
  final String variant;
  final String pack;
  final String sku;
  final String barcode;
  final int purchasePrice;
  final int sellingPrice;
  final String unitPrice;
  final int stock;
  final String deliveryPromise;
  final String origin;
  final String visualLabel;
  final String visualKind;
  final int? mrp;
  final int minimumOrder;
  final String? returnPolicy;
  final bool requiresPrescription;
  final String? composition;
  final String? regulatoryNote;
  final WorkspaceProductCompliance? compliance;
  final bool available;
  final bool publicListing;
  // Null preserves the availability decision of older saved products.
  final bool? counterSaleEnabled;
  bool get counterSaleAllowed => counterSaleEnabled ?? available;
  final WorkspaceStockMode stockMode;
  final int lowStockThreshold;
  final WorkspaceCataloguePhoto? cataloguePhoto;
  final WorkspacePrivateProductPhoto? privatePhoto;
  final WorkspacePackMeasure? packMeasure;
  final WorkspaceWholesaleOffer? wholesaleOffer;
  final bool retailEnabled;
  final WorkspaceProductContent content;
  final WorkspaceStockEntry? stockEntry;

  /// Projection only; callers still need publication authority and a content
  /// source revision. Does not create a preview route or publish the product.
  BuyV2ProductContentSnapshot toBuyPublicContent({
    required String storeId,
    required String sourceId,
  }) {
    if (storeId.trim().isEmpty || sourceId.trim().isEmpty) {
      throw ArgumentError('A Store identity and content source are required.');
    }
    final validated = WorkspaceProductContent.parse(content.inputValues);
    return BuyV2ProductContentSnapshot(
      productId: id,
      state: BuyV2ProductContentState.ready,
      sourceId: sourceId,
      description: validated.description.isEmpty ? null : validated.description,
      media: toBuyPublicProduct(storeName: '', storeId: storeId).mediaAssets,
      highlights: validated.highlights,
      specifications: List.unmodifiable(
        validated.specifications.entries.map(
          (e) => BuyV2ProductSpecification(label: e.key, value: e.value),
        ),
      ),
    );
  }

  /// Local fail-closed hold; only a future authoritative review may clear it.
  final bool catalogueFactsRequireReview;

  /// Explicit Store preview only. Test media never travels through the public
  /// adapter. Reuse Buy's file/identity validation and renderer in both cases.
  BuyV2Product toCataloguePreviewProduct() {
    final photo = cataloguePhoto;
    final product = toBuyPublicProduct(storeName: '');
    if (photo == null ||
        photo.source.trim().isEmpty ||
        !photo.matches(this) ||
        photo.status == WorkspaceCataloguePhotoStatus.pending) {
      return product;
    }
    final preview = product.copyWith(
      storeId: photo.publisherWorkspaceId,
      catalogueListing: false,
    );
    final asset = photo._asset(this, photo.publisherWorkspaceId);
    return BuyV2SupplierMediaPolicy.publicationMessage(preview, asset) == null
        ? preview.copyWith(mediaAssets: [asset])
        : preview;
  }

  bool get matchesMasterCatalogueIdentity => workspaceMasterCatalogue.any(
    (item) =>
        item.canonicalId == canonicalId &&
        item.title == title &&
        item.brand == brand &&
        item.pack == pack &&
        item.variant == variant &&
        item.categoryId == categoryId &&
        item.barcode == barcode,
  );

  bool get published =>
      publicListing &&
      customerProductFieldsComplete &&
      !catalogueFactsRequireReview &&
      _photoAllowsPublication &&
      available &&
      (stockMode == WorkspaceStockMode.availabilityOnly || stock > 0);

  bool get customerProductFieldsComplete =>
      customerFieldsCompleteFor(BuyV2Destination.shop);

  bool customerFieldsCompleteFor(BuyV2Destination channel) =>
      [
        id,
        canonicalId,
        title,
        brand,
        pack,
        categoryId,
        if (packMeasure?.valid != true) unitPrice,
        deliveryPromise,
        origin,
      ].every((value) => value.trim().isNotEmpty) &&
      (channel == BuyV2Destination.shop
          ? sellingPrice > 0 &&
                sellingPrice <= 999999999 &&
                minimumOrder > 0 &&
                (mrp == null || mrp! >= sellingPrice)
          : channel == BuyV2Destination.wholesale &&
                wholesaleOffer?.enabled == true &&
                wholesaleOffer!.valid &&
                (mrp == null || mrp! >= wholesaleOffer!.priceRupees));

  // A legacy photo-less record may remain private stock, never a public listing.
  bool get _photoAllowsPublication =>
      cataloguePhoto != null &&
      (cataloguePhoto!.status == WorkspaceCataloguePhotoStatus.approved &&
          toCataloguePreviewProduct().mediaAssets.isNotEmpty);

  // Public discovery and the retailer's own counter inventory are independent.
  bool get canSellAtCounter =>
      counterSaleAllowed &&
      available &&
      (stockMode == WorkspaceStockMode.availabilityOnly || stock > 0);

  BuyV2Product toBuyPublicProduct({
    required String storeName,
    String? storeId,
    String badge = 'Store price',
    String confirmedOn = 'Updated by store',
    BuyV2Destination channel = BuyV2Destination.shop,
    WorkspaceStorePublicationDetails? storeDetails,
  }) {
    final wholesale = channel == BuyV2Destination.wholesale;
    if (channel != BuyV2Destination.shop && !wholesale) {
      throw ArgumentError.value(
        channel,
        'channel',
        'Unsupported Store selling channel',
      );
    }
    final offer = wholesaleOffer;
    if (wholesale && (offer == null || !offer.valid || !offer.enabled)) {
      throw StateError('Wholesale is not enabled with valid selling terms.');
    }
    final channelPrice = wholesale ? offer!.priceRupees : sellingPrice;
    final channelMinimum = wholesale ? offer!.minimumPacks : minimumOrder;
    final product = BuyV2Product(
      id: id,
      storeId: storeId,
      canonicalId: canonicalId,
      destination: channel,
      categoryId: categoryId,
      brand: brand,
      title: title,
      variant: variant,
      pack: pack,
      price: channelPrice,
      unitPrice:
          packMeasure?.valid == true &&
              channelPrice >= 0 &&
              channelPrice <= 999999999
          ? packMeasure!.pricePerUnit(channelPrice)
          : unitPrice,
      badge: badge,
      seller: storeName,
      sellerType: storeDetails?.publicSellerType ?? 'Store',
      deliveryPromise: deliveryPromise,
      origin: origin,
      confirmedOn: confirmedOn,
      visualLabel: visualLabel,
      visualKind: visualKind,
      mrp: mrp,
      requiresPrescription: requiresPrescription,
      composition: composition,
      regulatoryNote: regulatoryNote,
      compliance: compliance?.toBuyPublicCompliance(),
      minimumOrder: channelMinimum,
      returnPolicy: returnPolicy?.trim().isNotEmpty == true
          ? returnPolicy
          : storeDetails?.returnSummary.trim().isNotEmpty == true
          ? storeDetails!.returnSummary.trim()
          : returnPolicy,
      purchaseProtection: storeDetails?.protectionFor(returnPolicy),
      catalogueListing: false,
    );
    final photo = cataloguePhoto;
    if (photo == null ||
        photo.source.trim().isEmpty ||
        !photo.matches(this) ||
        photo.status != WorkspaceCataloguePhotoStatus.approved ||
        storeId == null ||
        storeId.trim().isEmpty) {
      return product;
    }
    final asset = photo._asset(this, storeId);
    return BuyV2SupplierMediaPolicy.publicationMessage(product, asset) == null
        ? product.copyWith(
            mediaAssets: [asset],
            catalogueListing:
                publicListing &&
                (storeDetails?.channelEnabled(channel) ?? true) &&
                (wholesale || retailEnabled) &&
                (!wholesale || offer?.saleType != null) &&
                customerFieldsCompleteFor(channel) &&
                !catalogueFactsRequireReview,
          )
        : product;
  }

  BuyV2ProductFactsSnapshot toBuyPublicFacts({
    required String storeName,
    required String sourceId,
    required bool storeVisible,
    required bool acceptingOrders,
    required DateTime observedAt,
    String? nextOpeningLabel,
    String? orderCutoffLabel,
    String? deliveryFeeLabel,
  }) {
    final orderable =
        storeVisible &&
        publicListing &&
        customerProductFieldsComplete &&
        !catalogueFactsRequireReview &&
        _photoAllowsPublication &&
        available &&
        (stockMode == WorkspaceStockMode.availabilityOnly || stock > 0) &&
        acceptingOrders;
    return BuyV2ProductFactsSnapshot(
      productId: id,
      price: sellingPrice,
      deliveryPromise: deliveryPromise,
      partner: storeName,
      orderabilityLabel: orderable
          ? 'Available to order'
          : !storeVisible ||
                !publicListing ||
                !customerProductFieldsComplete ||
                catalogueFactsRequireReview ||
                !_photoAllowsPublication
          ? 'Not listed for customers'
          : !available ||
                (stockMode == WorkspaceStockMode.exactQuantity && stock <= 0)
          ? 'Out of stock'
          : 'Store is not accepting orders',
      sourceId: sourceId,
      // The Store supplies readiness, not fleet eligibility. Cursor's public
      // adapter must consume the authoritative serviceability contract; never
      // infer Quick/courier/freight from retailer-authored delivery text.
      fulfilmentMode: null,
      storeOperatingState: acceptingOrders
          ? BuyV2StoreOperatingState.open
          : BuyV2StoreOperatingState.closed,
      nextOpeningLabel: nextOpeningLabel,
      orderCutoffLabel: orderCutoffLabel,
      deliveryFeeLabel: deliveryFeeLabel,
      observedAt: observedAt,
    );
  }

  /// Device inventory record, not publication or financial authority.
  /// Keep QA/production and account/Store identity in the enclosing checkpoint.
  Map<String, Object?> toInventoryJson() => {
    // Old readers reject this version instead of silently dropping provenance.
    'version': stockEntry == null ? 1 : 2,
    if (stockEntry != null) 'stockEntry': stockEntry!.toJson(),
    'id': id,
    'canonicalId': canonicalId,
    'categoryId': categoryId,
    'brand': brand,
    'title': title,
    'variant': variant,
    'pack': pack,
    'sku': sku,
    'barcode': barcode,
    'purchasePrice': purchasePrice,
    'sellingPrice': sellingPrice,
    'unitPrice': unitPrice,
    'stock': stock,
    'deliveryPromise': deliveryPromise,
    'origin': origin,
    'visualLabel': visualLabel,
    'visualKind': visualKind,
    'mrp': mrp,
    'minimumOrder': minimumOrder,
    'returnPolicy': returnPolicy,
    'requiresPrescription': requiresPrescription,
    'composition': composition,
    'regulatoryNote': regulatoryNote,
    'compliance': compliance?.toJson(),
    'available': available,
    'publicListing': publicListing,
    'counterSaleEnabled': counterSaleEnabled,
    'stockMode': stockMode.name,
    'lowStockThreshold': lowStockThreshold,
    'cataloguePhoto': cataloguePhoto?.toJson(),
    'privatePhoto': privatePhoto?.toJson(),
    'catalogueFactsRequireReview': catalogueFactsRequireReview,
    'packMeasure': packMeasure?.toJson(),
    'wholesaleOffer': wholesaleOffer?.toJson(),
    'retailEnabled': retailEnabled,
    'content': content.toJson(),
  };

  static WorkspaceCatalogueItem fromInventoryJson(Object? raw) {
    const invalid = FormatException(
      'Saved product needs recovery. Its data has been kept.',
    );
    if (raw is! Map || !const [1, 2].contains(raw['version']) ||
        (raw['version'] == 2 && raw['stockEntry'] == null) ||
        (raw['version'] == 1 && raw['stockEntry'] != null)) {
      throw invalid;
    }
    String text(String key, {bool required = false}) {
      final value = raw[key];
      if (value is! String ||
          value.length > 16000 ||
          (required && value.trim().isEmpty)) {
        throw invalid;
      }
      return value;
    }

    int number(String key, {int minimum = 0}) {
      final value = raw[key];
      if (value is! int || value < minimum || value > 2147483647) throw invalid;
      return value;
    }

    bool flag(String key) {
      final value = raw[key];
      if (value is! bool) throw invalid;
      return value;
    }

    String? optionalText(String key) => raw[key] == null ? null : text(key);
    try {
      final photo = WorkspaceCataloguePhoto.fromJson(raw['cataloguePhoto']);
      final privatePhoto = WorkspacePrivateProductPhoto.fromJson(
        raw['privatePhoto'],
      );
      final compliance = WorkspaceProductCompliance.fromJson(raw['compliance']);
      final measure = WorkspacePackMeasure.fromJson(raw['packMeasure']);
      final wholesale = WorkspaceWholesaleOffer.fromJson(raw['wholesaleOffer']);
      if ((raw['cataloguePhoto'] != null && photo == null) ||
          (raw['compliance'] != null && compliance == null) ||
          (raw['packMeasure'] != null && measure == null) ||
          (raw['wholesaleOffer'] != null && wholesale == null)) {
        throw invalid;
      }
      final contents = raw['content'];
      if (contents is! Map ||
          contents['description'] is! String ||
          contents['highlights'] is! List ||
          contents['specifications'] is! Map) {
        throw invalid;
      }
      final content = WorkspaceProductContent(
        description: contents['description'] as String,
        highlights: List<String>.from(contents['highlights'] as List),
        specifications: Map<String, String>.from(
          contents['specifications'] as Map,
        ),
      );
      WorkspaceProductContent.parse(content.inputValues);
      final product = WorkspaceCatalogueItem(
        stockEntry: WorkspaceStockEntry.fromJson(raw['stockEntry']),
        id: text('id', required: true),
        canonicalId: text('canonicalId', required: true),
        categoryId: text('categoryId', required: true),
        brand: text('brand'),
        title: text('title', required: true),
        variant: text('variant'),
        pack: text('pack', required: true),
        sku: text('sku'),
        barcode: text('barcode'),
        purchasePrice: number('purchasePrice'),
        sellingPrice: number('sellingPrice'),
        unitPrice: text('unitPrice'),
        stock: number('stock'),
        deliveryPromise: text('deliveryPromise'),
        origin: text('origin'),
        visualLabel: text('visualLabel'),
        visualKind: text('visualKind'),
        mrp: raw['mrp'] == null ? null : number('mrp'),
        minimumOrder: number('minimumOrder', minimum: 1),
        returnPolicy: optionalText('returnPolicy'),
        requiresPrescription: flag('requiresPrescription'),
        composition: optionalText('composition'),
        regulatoryNote: optionalText('regulatoryNote'),
        compliance: compliance,
        available: flag('available'),
        publicListing: flag('publicListing'),
        counterSaleEnabled: raw['counterSaleEnabled'] == null
            ? null : flag('counterSaleEnabled'),
        stockMode: WorkspaceStockMode.values.byName(text('stockMode')),
        lowStockThreshold: number('lowStockThreshold'),
        cataloguePhoto: photo,
        privatePhoto: privatePhoto,
        catalogueFactsRequireReview: flag('catalogueFactsRequireReview'),
        packMeasure: measure,
        wholesaleOffer: wholesale,
        retailEnabled: flag('retailEnabled'),
        content: content,
      );
      if (photo != null && !photo.matches(product)) throw invalid;
      if (product.stockEntry != null && product.stockEntry!.productId != product.id) {
        throw invalid;
      }
      if (privatePhoto != null && !privatePhoto.matches(product)) throw invalid;
      return product;
    } on FormatException {
      rethrow;
    } on TypeError {
      throw invalid;
    } on ArgumentError {
      throw invalid;
    }
  }

  WorkspaceCatalogueItem copyWith({
    WorkspaceStockEntry? stockEntry,
    WorkspaceProductContent? content,
    String? canonicalId,
    String? categoryId,
    String? brand,
    String? title,
    String? variant,
    String? pack,
    String? sku,
    String? barcode,
    int? purchasePrice,
    int? sellingPrice,
    String? unitPrice,
    int? stock,
    String? deliveryPromise,
    String? origin,
    String? visualLabel,
    String? visualKind,
    int? mrp,
    int? minimumOrder,
    String? returnPolicy,
    bool? requiresPrescription,
    String? composition,
    String? regulatoryNote,
    WorkspaceProductCompliance? compliance,
    bool? available,
    bool? publicListing,
    bool? counterSaleEnabled,
    WorkspaceStockMode? stockMode,
    int? lowStockThreshold,
    WorkspaceCataloguePhoto? cataloguePhoto,
    bool clearCataloguePhoto = false,
    WorkspacePrivateProductPhoto? privatePhoto,
    bool clearPrivatePhoto = false,
    bool? catalogueFactsRequireReview,
    WorkspacePackMeasure? packMeasure,
    WorkspaceWholesaleOffer? wholesaleOffer,
    bool? retailEnabled,
    bool clearPackMeasure = false,
    bool clearWholesaleOffer = false,
  }) => WorkspaceCatalogueItem(
    id: id,
    stockEntry: stockEntry ?? this.stockEntry,
    content: content ?? this.content,
    canonicalId: canonicalId ?? this.canonicalId,
    categoryId: categoryId ?? this.categoryId,
    brand: brand ?? this.brand,
    title: title ?? this.title,
    variant: variant ?? this.variant,
    pack: pack ?? this.pack,
    sku: sku ?? this.sku,
    barcode: barcode ?? this.barcode,
    purchasePrice: purchasePrice ?? this.purchasePrice,
    sellingPrice: sellingPrice ?? this.sellingPrice,
    unitPrice: unitPrice ?? this.unitPrice,
    stock: stock ?? this.stock,
    deliveryPromise: deliveryPromise ?? this.deliveryPromise,
    origin: origin ?? this.origin,
    visualLabel: visualLabel ?? this.visualLabel,
    visualKind: visualKind ?? this.visualKind,
    mrp: mrp ?? this.mrp,
    minimumOrder: minimumOrder ?? this.minimumOrder,
    returnPolicy: returnPolicy ?? this.returnPolicy,
    requiresPrescription: requiresPrescription ?? this.requiresPrescription,
    composition: composition ?? this.composition,
    regulatoryNote: regulatoryNote ?? this.regulatoryNote,
    compliance: compliance ?? this.compliance,
    available: available ?? this.available,
    publicListing: publicListing ?? this.publicListing,
    counterSaleEnabled: counterSaleEnabled ?? this.counterSaleEnabled,
    stockMode: stockMode ?? this.stockMode,
    lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
    cataloguePhoto: clearCataloguePhoto
        ? null
        : cataloguePhoto ?? this.cataloguePhoto,
    privatePhoto: clearPrivatePhoto ? null : privatePhoto ?? this.privatePhoto,
    catalogueFactsRequireReview:
        catalogueFactsRequireReview ?? this.catalogueFactsRequireReview,
    packMeasure: clearPackMeasure ? null : packMeasure ?? this.packMeasure,
    wholesaleOffer: clearWholesaleOffer
        ? null
        : wholesaleOffer ?? this.wholesaleOffer,
    retailEnabled: retailEnabled ?? this.retailEnabled,
  );
}

const workspaceMasterCatalogue = <WorkspaceCatalogueItem>[
  WorkspaceCatalogueItem(
    id: 'oil-fortune-1l',
    canonicalId: 'oil-fortune-sunflower',
    categoryId: 'cooking-oil',
    brand: 'Fortune',
    title: 'Fortune Sunflower Oil',
    variant: 'Refined sunflower oil',
    pack: '1 L pouch',
    sku: 'FRT-1L',
    barcode: '8906007281015',
    purchasePrice: 248,
    sellingPrice: 264,
    unitPrice: '₹264/L',
    stock: 0,
    deliveryPromise: 'Store pickup or local delivery',
    origin: 'India',
    visualLabel: 'Fortune Sunflower Oil 1 L pouch',
    visualKind: 'catalogue-packshot',
    mrp: 270,
    returnPolicy: 'Return accepted for a sealed damaged pack at delivery.',
    compliance: WorkspaceProductCompliance(
      genericName: 'Refined sunflower oil',
      netQuantity: '1 L',
      countryOfOrigin: 'India',
    ),
  ),
  WorkspaceCatalogueItem(
    id: 'atta-aashirvaad-1kg',
    canonicalId: 'atta-aashirvaad-whole-wheat',
    categoryId: 'flour-grains',
    brand: 'Aashirvaad',
    title: 'Aashirvaad Whole Wheat Atta',
    variant: 'Whole wheat flour',
    pack: '1 kg pack',
    sku: 'AAT-1K',
    barcode: '8901725001228',
    purchasePrice: 98,
    sellingPrice: 108,
    unitPrice: '₹108/kg',
    stock: 0,
    deliveryPromise: 'Store pickup or local delivery',
    origin: 'India',
    visualLabel: 'Aashirvaad Whole Wheat Atta 1 kg',
    visualKind: 'catalogue-packshot',
    mrp: 112,
    compliance: WorkspaceProductCompliance(
      genericName: 'Whole wheat flour',
      netQuantity: '1 kg',
      countryOfOrigin: 'India',
    ),
  ),
  WorkspaceCatalogueItem(
    id: 'salt-tata-1kg',
    canonicalId: 'salt-tata-iodised',
    categoryId: 'salt-spices',
    brand: 'Tata',
    title: 'Tata Salt',
    variant: 'Iodised salt',
    pack: '1 kg pack',
    sku: 'TSL-1K',
    barcode: '8904043901017',
    purchasePrice: 50,
    sellingPrice: 56,
    unitPrice: '₹56/kg',
    stock: 0,
    deliveryPromise: 'Store pickup or local delivery',
    origin: 'India',
    visualLabel: 'Tata Salt 1 kg pack',
    visualKind: 'catalogue-packshot',
    mrp: 58,
    compliance: WorkspaceProductCompliance(
      genericName: 'Iodised salt',
      netQuantity: '1 kg',
      countryOfOrigin: 'India',
    ),
  ),
];

class WorkspaceActivityEntry {
  const WorkspaceActivityEntry({required this.message, required this.time});

  final String message;
  final DateTime time;
}

class WorkspaceGroupBuy {
  const WorkspaceGroupBuy({
    required this.id,
    required this.productName,
    required this.specification,
    required this.leadRetailer,
    required this.confirmedRetailers,
    required this.targetQuantity,
    required this.securedQuantity,
    required this.unitLabel,
    required this.regularUnitPrice,
    required this.groupUnitPrice,
    required this.facilitationFee,
    required this.deliveryFee,
    required this.confirmationAmount,
    required this.closingLabel,
    required this.storeDeliveryLabel,
    required this.paymentConfirmed,
    this.deliveryPartnerName,
    this.participants = const [],
  });

  final String id;
  final String productName;
  final String specification;
  final String leadRetailer;
  final List<String> confirmedRetailers;
  final int targetQuantity;
  final int securedQuantity;
  final String unitLabel;
  final int regularUnitPrice;
  final int groupUnitPrice;
  final int facilitationFee;
  final int deliveryFee;
  final int confirmationAmount;
  final String closingLabel;
  final String storeDeliveryLabel;
  final bool paymentConfirmed;
  final String? deliveryPartnerName;
  final List<WorkspaceGroupBuyParticipant> participants;

  int get remainingQuantity =>
      (targetQuantity - securedQuantity).clamp(0, targetQuantity);
  int get savingPerUnit => regularUnitPrice - groupUnitPrice;
  int get totalSaving => savingPerUnit * securedQuantity;
  int get goodsValue => groupUnitPrice * securedQuantity;
  int get deliveredTotal => goodsValue + facilitationFee + deliveryFee;
  int get referenceTotal => regularUnitPrice * securedQuantity;
  int get netSaving {
    final saving = referenceTotal - deliveredTotal;
    return saving < 0 ? 0 : saving;
  }

  int get balanceDue {
    final balance = deliveredTotal - confirmationAmount;
    return balance < 0 ? 0 : balance;
  }
}

class WorkspaceGroupBuyParticipant {
  const WorkspaceGroupBuyParticipant({
    required this.businessName,
    required this.locality,
    required this.quantity,
    required this.unitLabel,
    required this.milestone,
  });

  final String businessName;
  final String locality;
  final int quantity;
  final String unitLabel;
  final String milestone;
}

enum WorkspaceStockSupplierType {
  wholesaler,
  mandi,
  manufacturer;

  String get label => switch (this) {
    wholesaler => 'Wholesaler',
    mandi => 'Mandi',
    manufacturer => 'Manufacturer',
  };

  /// Exact authoritative business role, never guessed from names or copy.
  static WorkspaceStockSupplierType? fromRole(String role) => switch (role) {
    'wholesaler' => wholesaler,
    'mandi' => mandi,
    'manufacturer' => manufacturer,
    _ => null,
  };
}

enum WorkspaceGroupOfferStage {
  collecting,
  full,
  secured,
  packing,
  dispatched,
  delivered,
  closed,
  failed,
  cancelled;

  String get label => switch (this) {
    collecting => 'Accepting quantities',
    full => 'Quantity filled',
    secured => 'Stock secured',
    packing => 'Preparing dispatch',
    dispatched => 'On the way',
    delivered => 'Delivery completed',
    closed => 'Offer closed',
    failed => 'Purchase not completed',
    cancelled => 'Offer cancelled',
  };
}

enum WorkspaceGroupParticipationState {
  unknown,
  notJoined,
  pending,
  confirmationPaid,
  balanceDue,
  paid,
  paymentFailed,
  refundPending,
  refunded,
  cancelled;

  String get label => switch (this) {
    unknown => 'Your purchase update unavailable',
    notJoined => 'You have not joined',
    pending => 'Your confirmation is pending',
    confirmationPaid => 'Your confirmation payment received',
    balanceDue => 'Your balance is due',
    paid => 'Your payment is complete',
    paymentFailed => 'Your payment was not completed',
    refundPending => 'Your refund is pending',
    refunded => 'Your refund is complete',
    cancelled => 'Your purchase is cancelled',
  };
}

/// This Store's quoted amounts in paise, never the aggregate group's costs.
/// Unknown values remain null; local UI arithmetic cannot confirm a payment.
class WorkspaceGroupParticipation {
  const WorkspaceGroupParticipation({
    required this.state,
    this.quantity,
    this.goodsMinor,
    this.tradeFeeMinor,
    this.deliveryMinor,
    this.taxMinor,
    this.totalMinor,
    this.referenceMinor,
    this.paidMinor,
    this.dueMinor,
    this.refundMinor,
    this.paymentDeadline,
  });
  final WorkspaceGroupParticipationState state;
  final int? quantity,
      goodsMinor,
      tradeFeeMinor,
      deliveryMinor,
      taxMinor,
      totalMinor,
      referenceMinor,
      paidMinor,
      dueMinor,
      refundMinor;
  final DateTime? paymentDeadline;
  int? get savingMinor => totalMinor == null || referenceMinor == null
      ? null
      : referenceMinor! - totalMinor!;
  bool get valid {
    if ([
      quantity,
      goodsMinor,
      tradeFeeMinor,
      deliveryMinor,
      taxMinor,
      totalMinor,
      referenceMinor,
      paidMinor,
      dueMinor,
      refundMinor,
    ].any((value) => value != null && value < 0)) {
      return false;
    }
    if (paymentDeadline != null && !paymentDeadline!.isUtc) return false;
    if (goodsMinor != null &&
        tradeFeeMinor != null &&
        deliveryMinor != null &&
        taxMinor != null &&
        totalMinor != null &&
        totalMinor !=
            goodsMinor! + tradeFeeMinor! + deliveryMinor! + taxMinor!) {
      return false;
    }
    if (paidMinor != null &&
        dueMinor != null &&
        totalMinor != null &&
        paidMinor! + dueMinor! != totalMinor) {
      return false;
    }
    if (refundMinor != null && paidMinor != null && refundMinor! > paidMinor!) {
      return false;
    }
    return switch (state) {
      WorkspaceGroupParticipationState.notJoined =>
        (quantity == null || quantity == 0) &&
            (paidMinor == null || paidMinor == 0),
      WorkspaceGroupParticipationState.paid =>
        quantity != null &&
            quantity! > 0 &&
            totalMinor != null &&
            paidMinor == totalMinor &&
            dueMinor == 0,
      WorkspaceGroupParticipationState.balanceDue =>
        quantity != null && quantity! > 0 && dueMinor != null && dueMinor! > 0,
      WorkspaceGroupParticipationState.confirmationPaid =>
        quantity != null &&
            quantity! > 0 &&
            paidMinor != null &&
            paidMinor! > 0,
      WorkspaceGroupParticipationState.refunded =>
        refundMinor != null && refundMinor! > 0,
      _ => true,
    };
  }
}

/// Read-only projection supplied by an authenticated Store offer adapter.
/// Scope/revision validation here is not server-side eligibility or authority.
class WorkspaceGroupOffer {
  WorkspaceGroupOffer({
    required this.accountScope,
    required this.workspaceId,
    required this.supplierId,
    required this.supplierName,
    required this.supplierType,
    required this.productId,
    required this.revision,
    required this.updatedAt,
    required this.closingAt,
    required this.stage,
    required this.publicationConfirmed,
    required WorkspaceGroupBuy details,
    required this.participation,
    this.note,
  }) : details = WorkspaceGroupBuy(
         id: details.id,
         productName: details.productName,
         specification: details.specification,
         leadRetailer: details.leadRetailer,
         confirmedRetailers: List.unmodifiable(details.confirmedRetailers),
         targetQuantity: details.targetQuantity,
         securedQuantity: details.securedQuantity,
         unitLabel: details.unitLabel,
         regularUnitPrice: details.regularUnitPrice,
         groupUnitPrice: details.groupUnitPrice,
         facilitationFee: details.facilitationFee,
         deliveryFee: details.deliveryFee,
         confirmationAmount: details.confirmationAmount,
         closingLabel: details.closingLabel,
         storeDeliveryLabel: details.storeDeliveryLabel,
         paymentConfirmed: details.paymentConfirmed,
         deliveryPartnerName: details.deliveryPartnerName,
         participants: List.unmodifiable(details.participants),
       );
  final String accountScope, workspaceId, supplierId, supplierName, productId;
  final WorkspaceStockSupplierType supplierType;
  final int revision;
  final DateTime updatedAt, closingAt;
  final WorkspaceGroupOfferStage stage;
  final bool publicationConfirmed;
  final WorkspaceGroupBuy details;
  final WorkspaceGroupParticipation participation;
  final String? note;
  String get id => details.id;
  bool get valid =>
      [
        accountScope,
        workspaceId,
        supplierId,
        supplierName,
        productId,
        id,
        details.productName,
        details.specification,
        details.unitLabel,
        details.leadRetailer,
      ].every((value) => value.trim().isNotEmpty) &&
      revision > 0 &&
      updatedAt.isUtc &&
      closingAt.isUtc &&
      publicationConfirmed &&
      details.targetQuantity > 0 &&
      details.securedQuantity >= 0 &&
      details.securedQuantity <= details.targetQuantity &&
      details.groupUnitPrice >= 0 &&
      details.regularUnitPrice >= 0 &&
      details.facilitationFee >= 0 &&
      details.deliveryFee >= 0 &&
      details.confirmationAmount >= 0 &&
      participation.valid &&
      (participation.quantity == null ||
          participation.quantity! <= details.targetQuantity) &&
      details.participants.every(
        (person) =>
            person.quantity >= 0 &&
            person.businessName.trim().isNotEmpty &&
            person.unitLabel == details.unitLabel,
      );
}

enum WorkOpportunityPosterType {
  moolSocial,
  retailer,
  wholesaler,
  socialUser,
  manufacturer,
  rider,
  doctor,
  other,
}

extension WorkOpportunityPosterTypeLabel on WorkOpportunityPosterType {
  String get label => switch (this) {
    WorkOpportunityPosterType.moolSocial => 'MoolSocial',
    WorkOpportunityPosterType.retailer => 'Retailer',
    WorkOpportunityPosterType.wholesaler => 'Wholesaler',
    WorkOpportunityPosterType.socialUser => 'Social user',
    WorkOpportunityPosterType.manufacturer => 'Manufacturer',
    WorkOpportunityPosterType.rider => 'Rider',
    WorkOpportunityPosterType.doctor => 'Doctor',
    WorkOpportunityPosterType.other => 'Other verified user',
  };
}

enum WorkOpportunityCardColorToken {
  cobalt,
  emerald,
  crimson,
  violet,
  amber,
  teal,
  magenta,
  indigo,
}

class WorkOpportunity {
  const WorkOpportunity({
    required this.id,
    required this.publisher,
    required this.publisherType,
    required this.posterType,
    required this.title,
    required this.summary,
    required this.qualificationHeadline,
    required this.kind,
    required this.location,
    required this.city,
    required this.area,
    required this.pincode,
    required this.capacity,
    required this.peopleNeeded,
    required this.peopleJoined,
    required this.applicationsInProgress,
    required this.finalDeadline,
    required this.paymentAmount,
    required this.monthlyPayment,
    required this.payout,
    required this.requiredWork,
    required this.deadline,
    required this.fundingNote,
    required this.aboutRole,
    required this.whatYoullDo,
    required this.whoYouAre,
    required this.niceToHave,
    required this.whyJoin,
    required this.cardColorToken,
    required this.requiresWorkspace,
    required this.icon,
    required this.filters,
    this.hourlyPayment,
    this.assignmentPayment,
    this.funded = true,
    this.available = true,
  });

  final String id;
  final String publisher;
  final String publisherType;
  final WorkOpportunityPosterType posterType;
  final String title;
  final String summary;
  final String qualificationHeadline;
  final String kind;
  final String location;
  final String city;
  final String area;
  final String pincode;
  final String capacity;
  final int peopleNeeded;
  final int peopleJoined;
  final int applicationsInProgress;
  final String finalDeadline;
  int get positionsRemaining {
    final remaining = peopleNeeded - peopleJoined - applicationsInProgress;
    return remaining < 0 ? 0 : remaining;
  }

  final String paymentAmount;
  String get payment => monthlyPayment;
  final String monthlyPayment;
  final String? hourlyPayment;
  final String? assignmentPayment;
  final String payout;
  final String requiredWork;
  final String deadline;
  final String fundingNote;
  final String aboutRole;
  final List<String> whatYoullDo;
  final List<String> whoYouAre;
  final List<String> niceToHave;
  final String whyJoin;
  final WorkOpportunityCardColorToken cardColorToken;
  final bool requiresWorkspace;
  final IconData icon;
  final Set<WorkFeedFilter> filters;
  final bool funded;
  final bool available;
}

class WorkTerm {
  const WorkTerm({required this.id, required this.title, required this.detail});

  final String id;
  final String title;
  final String detail;
}

enum WorkGstMatchCategory {
  retailGoodsSupplier,
  wholesaleDistributor,
  manufacturerSupplier,
  foodServiceProvider,
  healthcareProvider,
  pharmacySupplier,
  personalCareProvider,
  bikeTravelProvider,
  autoTravelProvider,
  cabTravelProvider,
  busTravelProvider,
  quickDeliveryBiker,
  wholesaleFleetDelivery,
  bulkDeliveryFleet,
  digitalContentProvider,
  independentProfessional,
}

extension WorkGstMatchCategoryLabel on WorkGstMatchCategory {
  String get label => switch (this) {
    WorkGstMatchCategory.retailGoodsSupplier => 'Retail goods supplier',
    WorkGstMatchCategory.wholesaleDistributor => 'Wholesale distributor',
    WorkGstMatchCategory.manufacturerSupplier => 'Manufacturer or supplier',
    WorkGstMatchCategory.foodServiceProvider => 'Food service provider',
    WorkGstMatchCategory.healthcareProvider => 'Healthcare provider',
    WorkGstMatchCategory.pharmacySupplier => 'Pharmacy or medicine supplier',
    WorkGstMatchCategory.personalCareProvider =>
      'Personal care service provider',
    WorkGstMatchCategory.bikeTravelProvider => 'Bike travel provider',
    WorkGstMatchCategory.autoTravelProvider => 'Auto travel provider',
    WorkGstMatchCategory.cabTravelProvider => 'Cab travel provider',
    WorkGstMatchCategory.busTravelProvider => 'Bus travel provider',
    WorkGstMatchCategory.quickDeliveryBiker => 'Quick delivery biker',
    WorkGstMatchCategory.wholesaleFleetDelivery => 'Wholesale fleet delivery',
    WorkGstMatchCategory.bulkDeliveryFleet => 'Bulk delivery fleet',
    WorkGstMatchCategory.digitalContentProvider =>
      'Digital content service provider',
    WorkGstMatchCategory.independentProfessional => 'Independent professional',
  };
}

class WorkProfileOption {
  const WorkProfileOption({
    required this.id,
    required this.familyId,
    required this.familyLabel,
    required this.label,
    required this.gstMatchCategory,
    required this.sellSide,
    required this.buySide,
    required this.tools,
    required this.icon,
  });

  final String id;
  final String familyId;
  final String familyLabel;
  final String label;
  final WorkGstMatchCategory gstMatchCategory;
  final String sellSide;
  final String buySide;
  final String tools;
  final IconData icon;

  String get setupSubtitle => switch (id) {
    'retailer-grocery' ||
    'retailer-speciality' => 'Grocery / Kirana Shop or Speciality Retail Shop',
    _ => label,
  };
}

enum WorkContactChannel { primaryMobile, email, alternateMobile }

extension WorkContactChannelValue on WorkContactChannel {
  String get apiValue => switch (this) {
    WorkContactChannel.primaryMobile => 'primary_mobile',
    WorkContactChannel.email => 'email',
    WorkContactChannel.alternateMobile => 'alternate_mobile',
  };
}

class WorkAccountSnapshot {
  const WorkAccountSnapshot({
    this.displayName = '',
    this.email = '',
    this.mobile = '',
    this.providerLabel = '',
    this.providerAccount = '',
    this.emailConfirmed = false,
    this.mobileConfirmed = false,
  });

  final String displayName;
  final String email;
  final String mobile;
  final String providerLabel;
  final String providerAccount;
  final bool emailConfirmed;
  final bool mobileConfirmed;
}

enum WorkDocumentImportance { required, ifApplicable, optional }

extension WorkDocumentImportanceLabel on WorkDocumentImportance {
  String get label => switch (this) {
    WorkDocumentImportance.required => 'Required',
    WorkDocumentImportance.ifApplicable => 'Required when applicable',
    WorkDocumentImportance.optional => 'Optional',
  };
}

class WorkDocumentChecklistItem {
  const WorkDocumentChecklistItem({
    required this.title,
    required this.detail,
    required this.importance,
    required this.icon,
  });

  final String title;
  final String detail;
  final WorkDocumentImportance importance;
  final IconData icon;
}

const _identityDocument = WorkDocumentChecklistItem(
  title: 'Account owner identity',
  detail: 'PAN, Aadhaar or another accepted government identity document.',
  importance: WorkDocumentImportance.required,
  icon: Icons.badge_outlined,
);

const _gstDocument = WorkDocumentChecklistItem(
  title: 'GST registration certificate',
  detail:
      'Required when GST registration applies to this Workspace. Applicability is confirmed during verification.',
  importance: WorkDocumentImportance.ifApplicable,
  icon: Icons.receipt_long_outlined,
);

const _payoutBankDocument = WorkDocumentChecklistItem(
  title: 'Payout bank account proof',
  detail:
      'A cancelled cheque or recent bank statement PDF showing the account holder name, account number and IFSC for approved sales, service or work payments.',
  importance: WorkDocumentImportance.required,
  icon: Icons.account_balance_outlined,
);

List<WorkDocumentChecklistItem> _withRequiredPayoutBank(
  List<WorkDocumentChecklistItem> profileDocuments,
) => List<WorkDocumentChecklistItem>.unmodifiable([
  ...profileDocuments.where(
    (document) =>
        document.title != _gstDocument.title &&
        document.title != 'Payout account document',
  ),
  _payoutBankDocument,
  _gstDocument,
]);

extension WorkProfileDocumentChecklist on WorkProfileOption {
  List<WorkDocumentChecklistItem>
  get verificationDocuments => _withRequiredPayoutBank(switch (id) {
    'retailer-grocery' => const [
      _identityDocument,
      WorkDocumentChecklistItem(
        title: 'Shop address document',
        detail:
            'Ownership, rent, lease, consent or a recent utility document for the shop.',
        importance: WorkDocumentImportance.required,
        icon: Icons.storefront_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Food business registration or licence',
        detail: 'FSSAI registration or licence when food products require it.',
        importance: WorkDocumentImportance.ifApplicable,
        icon: Icons.restaurant_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Owner or operator authority',
        detail: 'Authorisation when the account owner is not the shop owner.',
        importance: WorkDocumentImportance.ifApplicable,
        icon: Icons.assignment_ind_outlined,
      ),
      _gstDocument,
    ],
    'retailer-speciality' => const [
      _identityDocument,
      WorkDocumentChecklistItem(
        title: 'Store address document',
        detail:
            'Ownership, rent, lease, consent or a recent utility document for the store.',
        importance: WorkDocumentImportance.required,
        icon: Icons.shopping_bag_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Category licence or registration',
        detail: 'Any licence required for the products you sell.',
        importance: WorkDocumentImportance.ifApplicable,
        icon: Icons.verified_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Owner or operator authority',
        detail: 'Authorisation when the account owner is not the store owner.',
        importance: WorkDocumentImportance.ifApplicable,
        icon: Icons.assignment_ind_outlined,
      ),
      _gstDocument,
    ],
    'wholesaler' => const [
      _identityDocument,
      WorkDocumentChecklistItem(
        title: 'Business registration document',
        detail:
            'Registration or constitution document for the wholesale business.',
        importance: WorkDocumentImportance.required,
        icon: Icons.business_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Warehouse or business address document',
        detail: 'Ownership, rent, lease, consent or utility document.',
        importance: WorkDocumentImportance.required,
        icon: Icons.warehouse_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Authorised representative document',
        detail: 'Authorisation if another person manages this Workspace.',
        importance: WorkDocumentImportance.ifApplicable,
        icon: Icons.assignment_ind_outlined,
      ),
      _gstDocument,
    ],
    'manufacturer' => const [
      _identityDocument,
      WorkDocumentChecklistItem(
        title: 'Business registration document',
        detail: 'Company, partnership, LLP, proprietorship or Udyam document.',
        importance: WorkDocumentImportance.required,
        icon: Icons.business_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Manufacturing unit address document',
        detail:
            'Ownership, rent, lease, consent or utility document for the unit.',
        importance: WorkDocumentImportance.required,
        icon: Icons.factory_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Manufacturing licence',
        detail: 'Licence or approval required for your product category.',
        importance: WorkDocumentImportance.ifApplicable,
        icon: Icons.approval_outlined,
      ),
      _gstDocument,
    ],
    'restaurant' || 'cloud-kitchen' => const [
      _identityDocument,
      WorkDocumentChecklistItem(
        title: 'FSSAI registration or licence',
        detail: 'The food registration or licence applicable to your business.',
        importance: WorkDocumentImportance.required,
        icon: Icons.restaurant_menu_rounded,
      ),
      WorkDocumentChecklistItem(
        title: 'Kitchen or restaurant address document',
        detail: 'Ownership, rent, lease, consent or utility document.',
        importance: WorkDocumentImportance.required,
        icon: Icons.location_city_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Owner or operator authority',
        detail: 'Authorisation when the account owner is not the operator.',
        importance: WorkDocumentImportance.ifApplicable,
        icon: Icons.assignment_ind_outlined,
      ),
      _gstDocument,
    ],
    'clinic' => const [
      _identityDocument,
      WorkDocumentChecklistItem(
        title: 'Professional registration certificate',
        detail:
            'Current medical council or applicable professional registration.',
        importance: WorkDocumentImportance.required,
        icon: Icons.medical_services_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Clinic address document',
        detail: 'Address document when appointments are offered from a clinic.',
        importance: WorkDocumentImportance.ifApplicable,
        icon: Icons.local_hospital_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Clinic operator authority',
        detail: 'Authorisation when the doctor does not own the clinic.',
        importance: WorkDocumentImportance.ifApplicable,
        icon: Icons.assignment_ind_outlined,
      ),
      _gstDocument,
    ],
    'pharmacy' => const [
      _identityDocument,
      WorkDocumentChecklistItem(
        title: 'Drug licence',
        detail: 'Current retail or wholesale drug licence for the pharmacy.',
        importance: WorkDocumentImportance.required,
        icon: Icons.local_pharmacy_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Pharmacist or authorised-person document',
        detail:
            'Registration or authorisation for the responsible professional.',
        importance: WorkDocumentImportance.required,
        icon: Icons.badge_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Pharmacy address document',
        detail: 'Ownership, rent, lease, consent or utility document.',
        importance: WorkDocumentImportance.required,
        icon: Icons.store_outlined,
      ),
      _gstDocument,
    ],
    'salon' => const [
      _identityDocument,
      WorkDocumentChecklistItem(
        title: 'Salon address document',
        detail: 'Ownership, rent, lease, consent or utility document.',
        importance: WorkDocumentImportance.required,
        icon: Icons.content_cut_rounded,
      ),
      WorkDocumentChecklistItem(
        title: 'Shop or local registration',
        detail: 'Local registration or licence required for your salon.',
        importance: WorkDocumentImportance.ifApplicable,
        icon: Icons.approval_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Owner or operator authority',
        detail: 'Authorisation when the account owner is not the salon owner.',
        importance: WorkDocumentImportance.ifApplicable,
        icon: Icons.assignment_ind_outlined,
      ),
      _gstDocument,
    ],
    'travel-bike-provider' ||
    'travel-auto-provider' ||
    'travel-cab-provider' => const [
      _identityDocument,
      WorkDocumentChecklistItem(
        title: 'Driving licence',
        detail: 'Current licence for the vehicle category you operate.',
        importance: WorkDocumentImportance.required,
        icon: Icons.badge_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Vehicle registration certificate',
        detail: 'Current RC for the vehicle used for passenger travel.',
        importance: WorkDocumentImportance.required,
        icon: Icons.directions_car_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Vehicle insurance and permit',
        detail:
            'Current insurance and the permit applicable to the travel service.',
        importance: WorkDocumentImportance.required,
        icon: Icons.health_and_safety_outlined,
      ),
      _gstDocument,
    ],
    'travel-bus-provider' => const [
      _identityDocument,
      WorkDocumentChecklistItem(
        title: 'Bus driving licence or operator authority',
        detail:
            'Current vehicle-category licence or authority from the bus operator.',
        importance: WorkDocumentImportance.required,
        icon: Icons.badge_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Bus registration certificate',
        detail: 'Current RC for each bus added to the Workspace.',
        importance: WorkDocumentImportance.required,
        icon: Icons.directions_bus_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Passenger-service permit and insurance',
        detail:
            'Current insurance and the permit applicable to the passenger service.',
        importance: WorkDocumentImportance.required,
        icon: Icons.health_and_safety_outlined,
      ),
      _gstDocument,
    ],
    'quick-delivery-biker' => const [
      _identityDocument,
      WorkDocumentChecklistItem(
        title: 'Driving licence',
        detail: 'Current licence for the delivery bike category.',
        importance: WorkDocumentImportance.required,
        icon: Icons.badge_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Bike registration certificate',
        detail: 'Current RC for the bike used for delivery work.',
        importance: WorkDocumentImportance.required,
        icon: Icons.two_wheeler_rounded,
      ),
      WorkDocumentChecklistItem(
        title: 'Bike insurance and permit',
        detail: 'Current insurance and any permit applicable to delivery work.',
        importance: WorkDocumentImportance.required,
        icon: Icons.health_and_safety_outlined,
      ),
      _gstDocument,
    ],
    'wholesale-fleet-delivery' || 'bulk-delivery-fleet' => const [
      _identityDocument,
      WorkDocumentChecklistItem(
        title: 'Transport business registration',
        detail: 'Registration or constitution document for the fleet business.',
        importance: WorkDocumentImportance.required,
        icon: Icons.business_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Vehicle RC, permit and insurance',
        detail:
            'Current documents for delivery vehicles added to the Workspace.',
        importance: WorkDocumentImportance.required,
        icon: Icons.local_shipping_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Fleet operator authority',
        detail: 'Authorisation for the person managing the fleet.',
        importance: WorkDocumentImportance.required,
        icon: Icons.assignment_ind_outlined,
      ),
      _gstDocument,
    ],
    'creator' => const [
      _identityDocument,
      WorkDocumentChecklistItem(
        title: 'Portfolio or channel ownership',
        detail:
            'A public portfolio, channel or account showing your original work.',
        importance: WorkDocumentImportance.required,
        icon: Icons.video_camera_front_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Payout account document',
        detail:
            'A bank document that confirms where approved earnings are paid.',
        importance: WorkDocumentImportance.required,
        icon: Icons.account_balance_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Agency or brand authorisation',
        detail: 'Authorisation when you represent a creator agency or brand.',
        importance: WorkDocumentImportance.ifApplicable,
        icon: Icons.assignment_ind_outlined,
      ),
      _gstDocument,
    ],
    _ => const [
      _identityDocument,
      WorkDocumentChecklistItem(
        title: 'Portfolio, qualification or experience document',
        detail: 'A document or link that demonstrates the work you offer.',
        importance: WorkDocumentImportance.required,
        icon: Icons.work_outline_rounded,
      ),
      WorkDocumentChecklistItem(
        title: 'Payout account document',
        detail:
            'A bank document that confirms where approved earnings are paid.',
        importance: WorkDocumentImportance.required,
        icon: Icons.account_balance_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Professional licence',
        detail: 'A current licence when your profession requires one.',
        importance: WorkDocumentImportance.ifApplicable,
        icon: Icons.workspace_premium_outlined,
      ),
      _gstDocument,
    ],
  });
}

class WorkProofRequirement {
  const WorkProofRequirement({
    required this.id,
    required this.label,
    required this.detail,
    required this.importance,
  });

  final String id;
  final String label;
  final String detail;
  final WorkDocumentImportance importance;
  bool get required => importance == WorkDocumentImportance.required;
}

class WorkWorkspace {
  const WorkWorkspace({
    required this.id,
    required this.name,
    required this.profileLabel,
    required this.area,
    required this.verified,
    this.profileId,
    this.gstReminder = false,
  });

  final String id;
  final String name;
  final String profileLabel;
  final String? profileId;
  final String area;
  final bool verified;
  final bool gstReminder;
}

const workOpportunities = <WorkOpportunity>[
  WorkOpportunity(
    id: 'quick-delivery-biker',
    publisher: 'MoolSocial',
    publisherType: 'MoolSocial-owned funded task',
    posterType: WorkOpportunityPosterType.moolSocial,
    title: 'Quick Delivery Biker',
    summary:
        'Pick up prepaid local orders and complete OTP-confirmed deliveries during an agreed shift.',
    qualificationHeadline: 'Bike, valid licence and Android phone required',
    kind: 'Freelance delivery',
    location: 'Sardarpura, Jodhpur · 342003',
    city: 'Jodhpur',
    area: 'Sardarpura',
    pincode: '342003',
    capacity: '18 funded shifts',
    peopleNeeded: 18,
    peopleJoined: 6,
    applicationsInProgress: 4,
    finalDeadline: '05 Sep 2026',
    paymentAmount: '₹650 per completed shift',
    monthlyPayment: 'Up to ₹19,500 monthly for 30 completed shifts',
    hourlyPayment: '₹100 per active hour',
    assignmentPayment: '₹650 for 8 verified drops',
    payout: 'Within 1 working day',
    requiredWork: 'Rider / delivery freelancer',
    deadline: 'Apply while 18 funded shifts remain',
    fundingNote: 'Funded · ₹11,700 total task budget',
    aboutRole:
        'A flexible local delivery assignment for riders who can complete a fixed, prepaid route safely and on time.',
    whatYoullDo: [
      'Collect the assigned prepaid orders from the pickup point.',
      'Complete eight OTP-confirmed drops in the assigned area.',
      'Report delivery exceptions through the route support flow.',
    ],
    whoYouAre: [
      'You have a roadworthy bike, valid driving licence and smartphone.',
      'You can navigate Sardarpura and communicate clearly with customers.',
    ],
    niceToHave: [
      'Previous food, grocery or parcel delivery experience.',
      'Your own insulated delivery bag.',
    ],
    whyJoin:
        'Choose a funded shift with its route, work requirement and payout stated before you apply.',
    cardColorToken: WorkOpportunityCardColorToken.cobalt,
    requiresWorkspace: true,
    icon: Icons.delivery_dining_outlined,
    filters: {
      WorkFeedFilter.forYou,
      WorkFeedFilter.jobs,
      WorkFeedFilter.freelance,
      WorkFeedFilter.nearby,
    },
  ),
  WorkOpportunity(
    id: 'user-acquisition-onboarding',
    publisher: 'MoolSocial Growth',
    publisherType: 'MoolSocial-owned funded task',
    posterType: WorkOpportunityPosterType.moolSocial,
    title: 'MoolSocial User Acquisition & Business Onboarding Specialist',
    summary:
        'Meet local retailers, explain MoolSocial and complete owner-approved onboarding.',
    qualificationHeadline: 'Local retail network and field-sales confidence',
    kind: 'Freelance onboarding',
    location: 'Sardarpura, Jodhpur · 342003',
    city: 'Jodhpur',
    area: 'Sardarpura',
    pincode: '342003',
    capacity: '40 funded onboardings',
    peopleNeeded: 40,
    peopleJoined: 14,
    applicationsInProgress: 9,
    finalDeadline: '07 Sep 2026',
    paymentAmount: '₹350 per verified retailer',
    monthlyPayment: 'Up to ₹14,000 monthly for 40 verified onboardings',
    assignmentPayment: '₹350 per approved onboarding',
    payout: 'T+1 after verification',
    requiredWork: 'Retailer acquisition freelancer',
    deadline: 'Open while 40 funded onboardings remain',
    fundingNote: 'Funded · maximum task budget ₹14,000',
    aboutRole:
        'Acquire eligible local retailers and help each owner complete an informed, consent-based MoolSocial onboarding.',
    whatYoullDo: [
      'Identify eligible retailers in the assigned area.',
      'Explain the relevant app benefits without making false promises.',
      'Submit owner consent and the required verified onboarding record.',
    ],
    whoYouAre: [
      'You know local shop owners and are comfortable with field visits.',
      'You can demonstrate a mobile app in Hindi or a local language.',
    ],
    niceToHave: [
      'Retail distribution, merchant acquisition or FMCG experience.',
    ],
    whyJoin:
        'Earn against each verified outcome with the acceptance rule and funded capacity visible upfront.',
    cardColorToken: WorkOpportunityCardColorToken.emerald,
    requiresWorkspace: false,
    icon: Icons.storefront_outlined,
    filters: {
      WorkFeedFilter.forYou,
      WorkFeedFilter.freelance,
      WorkFeedFilter.nearby,
    },
  ),
  WorkOpportunity(
    id: 'retailer-onboarding-specialist',
    publisher: 'Mahadev Fresh Mart',
    publisherType: 'Verified retailer-owned posting',
    posterType: WorkOpportunityPosterType.retailer,
    title: 'Retailer Onboarding Specialist',
    summary:
        'Onboard verified kirana and speciality retailers in one assigned market.',
    qualificationHeadline:
        'Retailer relationships and field-app demonstration skills',
    kind: 'Freelance onboarding',
    location: 'Ratanada, Jodhpur · 342011',
    city: 'Jodhpur',
    area: 'Ratanada',
    pincode: '342011',
    capacity: '20 funded onboardings',
    peopleNeeded: 20,
    peopleJoined: 8,
    applicationsInProgress: 5,
    finalDeadline: '06 Sep 2026',
    paymentAmount: '₹350 per verified retailer',
    monthlyPayment: 'Up to ₹7,000 monthly for 20 verified onboardings',
    assignmentPayment: '₹350 per approved onboarding',
    payout: 'T+1 after verification',
    requiredWork: 'Retailer onboarding freelancer',
    deadline: 'Open while 20 funded onboardings remain',
    fundingNote: 'Retailer funded · maximum task budget ₹7,000',
    aboutRole:
        'Help a verified retailer association bring eligible peers onto MoolSocial through an informed, owner-approved onboarding flow.',
    whatYoullDo: [
      'Meet the owner and explain the relevant retailer workflow.',
      'Confirm business category and operating area.',
      'Submit consent-backed onboarding evidence.',
    ],
    whoYouAre: [
      'You know local retailers and can conduct field visits.',
      'You can demonstrate an app accurately in a local language.',
    ],
    niceToHave: [
      'FMCG, merchant acquisition or retail distribution experience.',
    ],
    whyJoin: 'Earn a stated amount for each independently verified retailer.',
    cardColorToken: WorkOpportunityCardColorToken.amber,
    requiresWorkspace: false,
    icon: Icons.add_business_outlined,
    filters: {
      WorkFeedFilter.forYou,
      WorkFeedFilter.freelance,
      WorkFeedFilter.nearby,
    },
  ),
  WorkOpportunity(
    id: 'manufacturer-onboarding-specialist',
    publisher: 'MoolSocial Trade',
    publisherType: 'MoolSocial-owned funded task',
    posterType: WorkOpportunityPosterType.moolSocial,
    title: 'Manufacturer Onboarding Specialist',
    summary:
        'Use local industrial contacts to onboard verified manufacturers and their catalogue owners.',
    qualificationHeadline: 'B2B field network and manufacturer contacts',
    kind: 'Freelance onboarding',
    location: 'Boranada, Jodhpur · 342012',
    city: 'Jodhpur',
    area: 'Boranada',
    pincode: '342012',
    capacity: '12 funded onboardings',
    peopleNeeded: 12,
    peopleJoined: 3,
    applicationsInProgress: 4,
    finalDeadline: '10 Sep 2026',
    paymentAmount: '₹900 per verified manufacturer',
    monthlyPayment: 'Up to ₹10,800 monthly for 12 verified onboardings',
    assignmentPayment: '₹900 per approved onboarding',
    payout: 'Within 2 working days',
    requiredWork: 'Manufacturer acquisition freelancer',
    deadline: 'Open while 12 funded onboardings remain',
    fundingNote: 'Funded · maximum task budget ₹10,800',
    aboutRole:
        'Bring suitable manufacturers onto MoolSocial with verified business ownership and a clear trade profile.',
    whatYoullDo: [
      'Approach suitable manufacturers through existing or new contacts.',
      'Explain trade discovery and catalogue requirements.',
      'Complete a verified, owner-approved onboarding record.',
    ],
    whoYouAre: [
      'You understand local manufacturing or distribution businesses.',
      'You can verify the decision-maker before starting onboarding.',
    ],
    niceToHave: [
      'Industrial sales, sourcing or channel-development experience.',
    ],
    whyJoin:
        'Turn your B2B network into clearly priced, independently verifiable assignments.',
    cardColorToken: WorkOpportunityCardColorToken.crimson,
    requiresWorkspace: false,
    icon: Icons.factory_outlined,
    filters: {
      WorkFeedFilter.forYou,
      WorkFeedFilter.freelance,
      WorkFeedFilter.nearby,
    },
  ),
  WorkOpportunity(
    id: 'rider-onboarding-specialist',
    publisher: 'Arjun Fleet Services',
    publisherType: 'Verified rider-owned posting',
    posterType: WorkOpportunityPosterType.rider,
    title: 'Rider Onboarding Specialist',
    summary:
        'Onboard eligible taxi, bike and bus operators and verify their operating category.',
    qualificationHeadline:
        'Transport-operator contacts across taxi, bike or bus',
    kind: 'Freelance onboarding',
    location: 'Mansarovar, Jaipur · 302020',
    city: 'Jaipur',
    area: 'Mansarovar',
    pincode: '302020',
    capacity: '25 funded onboardings',
    peopleNeeded: 25,
    peopleJoined: 10,
    applicationsInProgress: 6,
    finalDeadline: '08 Sep 2026',
    paymentAmount: '₹500 per verified operator',
    monthlyPayment: 'Up to ₹12,500 monthly for 25 verified onboardings',
    assignmentPayment: '₹500 per approved operator',
    payout: 'Within 2 working days',
    requiredWork: 'Transport onboarding freelancer',
    deadline: 'Open while 25 funded onboardings remain',
    fundingNote: 'User funded · maximum task budget ₹12,500',
    aboutRole:
        'Help a verified fleet operator build a network of eligible taxi, bike and bus operators in Jaipur.',
    whatYoullDo: [
      'Contact operators and explain the exact participation terms.',
      'Confirm their vehicle or fleet category and operating area.',
      'Submit consent-backed onboarding evidence for review.',
    ],
    whoYouAre: [
      'You already know local drivers, owners or transport unions.',
      'You can distinguish taxi, bike and bus onboarding requirements.',
    ],
    niceToHave: [
      'Fleet coordination or mobility-platform acquisition experience.',
    ],
    whyJoin:
        'Use your transport network for a bounded, funded outcome rather than an undefined sales target.',
    cardColorToken: WorkOpportunityCardColorToken.violet,
    requiresWorkspace: false,
    icon: Icons.connect_without_contact_outlined,
    filters: {
      WorkFeedFilter.forYou,
      WorkFeedFilter.freelance,
      WorkFeedFilter.nearby,
    },
  ),
  WorkOpportunity(
    id: 'doctor-onboarding-specialist',
    publisher: 'Dr Meera Health Network',
    publisherType: 'Verified doctor-owned posting',
    posterType: WorkOpportunityPosterType.doctor,
    title: 'Doctor Onboarding Specialist',
    summary:
        'Use existing professional connections to onboard verified doctors with consent.',
    qualificationHeadline:
        'Existing doctor relationships or medical-representative experience',
    kind: 'Freelance onboarding',
    location: 'Vijay Nagar, Indore · 452010',
    city: 'Indore',
    area: 'Vijay Nagar',
    pincode: '452010',
    capacity: '15 funded onboardings',
    peopleNeeded: 15,
    peopleJoined: 5,
    applicationsInProgress: 3,
    finalDeadline: '12 Sep 2026',
    paymentAmount: '₹750 per verified doctor',
    monthlyPayment: 'Up to ₹11,250 monthly for 15 verified onboardings',
    assignmentPayment: '₹750 per approved onboarding',
    payout: 'Within 3 working days',
    requiredWork: 'Healthcare onboarding freelancer',
    deadline: 'Open while 15 funded onboardings remain',
    fundingNote: 'Doctor funded · maximum task budget ₹11,250',
    aboutRole:
        'Support a verified doctor network by introducing eligible clinicians and completing consent-based profile onboarding.',
    whatYoullDo: [
      'Contact doctors through legitimate professional relationships.',
      'Explain profile visibility and verification requirements.',
      'Submit only consented and verifiable onboarding records.',
    ],
    whoYouAre: [
      'You have active connections with doctors or clinics.',
      'You understand professional boundaries and consent.',
    ],
    niceToHave: [
      'Medical representative or healthcare partnership experience.',
    ],
    whyJoin:
        'Apply your trusted healthcare network to a transparent, per-outcome assignment.',
    cardColorToken: WorkOpportunityCardColorToken.teal,
    requiresWorkspace: false,
    icon: Icons.medical_services_outlined,
    filters: {
      WorkFeedFilter.forYou,
      WorkFeedFilter.freelance,
      WorkFeedFilter.nearby,
    },
  ),
  WorkOpportunity(
    id: 'sales-specialist',
    publisher: 'MoolSocial Commerce',
    publisherType: 'MoolSocial-owned funded task',
    posterType: WorkOpportunityPosterType.moolSocial,
    title: 'MoolSocial Area Sales Specialist',
    summary:
        'Promote selected MoolSocial products and close in-app orders in an assigned area.',
    qualificationHeadline: 'Field sales record and local buyer relationships',
    kind: 'Freelance sales',
    location: 'Kothrud, Pune · 411038',
    city: 'Pune',
    area: 'Kothrud',
    pincode: '411038',
    capacity: '4 monthly assignments',
    peopleNeeded: 4,
    peopleJoined: 1,
    applicationsInProgress: 1,
    finalDeadline: '15 Sep 2026',
    paymentAmount: '₹24,000 monthly assignment',
    monthlyPayment: '₹24,000 per month',
    hourlyPayment: '₹150 equivalent per active hour',
    payout: 'Monthly after verified activity',
    requiredWork: 'Area sales freelancer',
    deadline: 'Applications close 15 September',
    fundingNote: 'Funded · 4 one-month assignments',
    aboutRole:
        'Own area-wise product promotion and verified in-app sales for a one-month freelance assignment.',
    whatYoullDo: [
      'Visit eligible buyers and demonstrate selected products.',
      'Create an area plan and record qualified follow-ups.',
      'Close attributable orders through MoolSocial.',
    ],
    whoYouAre: [
      'You have field sales experience and can work independently.',
      'You understand the Kothrud trade area and can travel locally.',
    ],
    niceToHave: ['FMCG, retail-tech or marketplace sales experience.'],
    whyJoin:
        'Own a defined territory with monthly compensation and measurable work expectations.',
    cardColorToken: WorkOpportunityCardColorToken.magenta,
    requiresWorkspace: true,
    icon: Icons.campaign_outlined,
    filters: {
      WorkFeedFilter.forYou,
      WorkFeedFilter.jobs,
      WorkFeedFilter.freelance,
      WorkFeedFilter.nearby,
    },
  ),
  WorkOpportunity(
    id: 'content-creator',
    publisher: 'Saanvi Home Foods',
    publisherType: 'Verified manufacturer-owned posting',
    posterType: WorkOpportunityPosterType.manufacturer,
    title: 'Content Creator',
    summary:
        'Produce two original vertical product videos from the supplied brief and product pack.',
    qualificationHeadline:
        'Strong vertical-video portfolio and editing ability',
    kind: 'Freelance content',
    location: 'Remote, India',
    city: 'India',
    area: 'Remote',
    pincode: '',
    capacity: '10 funded assignments',
    peopleNeeded: 10,
    peopleJoined: 4,
    applicationsInProgress: 2,
    finalDeadline: '11 Sep 2026',
    paymentAmount: '₹2,400 per approved assignment',
    monthlyPayment: 'Up to ₹24,000 monthly for 10 assignments',
    assignmentPayment: '₹2,400 for two approved videos',
    payout: 'Within 3 working days',
    requiredWork: 'Content creator',
    deadline: 'Open while 10 funded assignments remain',
    fundingNote: 'Manufacturer funded · product supplied',
    aboutRole:
        'Create concise product-led videos for a verified manufacturer using a supplied factual brief.',
    whatYoullDo: [
      'Plan and record two original vertical videos.',
      'Edit captions, pacing and product demonstrations to the brief.',
      'Complete one correction round when requested.',
    ],
    whoYouAre: [
      'You can show a relevant original-content portfolio.',
      'You can shoot and edit clear vertical video independently.',
    ],
    niceToHave: ['Hindi or regional-language presentation skills.'],
    whyJoin:
        'Receive the product and acceptance criteria before producing a funded assignment.',
    cardColorToken: WorkOpportunityCardColorToken.indigo,
    requiresWorkspace: false,
    icon: Icons.video_camera_front_outlined,
    filters: {
      WorkFeedFilter.forYou,
      WorkFeedFilter.freelance,
      WorkFeedFilter.campaigns,
    },
  ),
  WorkOpportunity(
    id: 'social-content-creator',
    publisher: 'Kavya Sharma',
    publisherType: 'Verified social-user-owned posting',
    posterType: WorkOpportunityPosterType.socialUser,
    title: 'Social Content Creator',
    summary:
        'Create a local-language social story and three short edits for a funded community campaign.',
    qualificationHeadline:
        'Original storytelling and public social-content portfolio',
    kind: 'Freelance social content',
    location: 'Vaishali Nagar, Jaipur · 302021',
    city: 'Jaipur',
    area: 'Vaishali Nagar',
    pincode: '302021',
    capacity: '8 funded assignments',
    peopleNeeded: 8,
    peopleJoined: 3,
    applicationsInProgress: 2,
    finalDeadline: '09 Sep 2026',
    paymentAmount: '₹1,800 per approved assignment',
    monthlyPayment: 'Up to ₹14,400 monthly for 8 assignments',
    assignmentPayment: '₹1,800 for one story and three edits',
    payout: 'Within 3 working days',
    requiredWork: 'Social content creator',
    deadline: 'Open while 8 funded assignments remain',
    fundingNote: 'User funded · disclosure required',
    aboutRole:
        'Create original social content for a verified user campaign with the deliverables and usage window stated upfront.',
    whatYoullDo: [
      'Develop one local-language story from the approved brief.',
      'Deliver three vertical edits sized for social publishing.',
      'Label sponsored content and use only cleared material.',
    ],
    whoYouAre: [
      'You publish original social content and can share a portfolio.',
      'You understand disclosure, consent and music-rights requirements.',
    ],
    niceToHave: ['A Jaipur audience or local community-reporting experience.'],
    whyJoin:
        'Take a bounded creative assignment with explicit deliverables, funding and rights expectations.',
    cardColorToken: WorkOpportunityCardColorToken.crimson,
    requiresWorkspace: false,
    icon: Icons.auto_awesome_motion_outlined,
    filters: {
      WorkFeedFilter.forYou,
      WorkFeedFilter.freelance,
      WorkFeedFilter.campaigns,
      WorkFeedFilter.nearby,
    },
  ),
  WorkOpportunity(
    id: 'wholesaler-onboarding-specialist',
    publisher: 'MoolSocial Trade',
    publisherType: 'MoolSocial-owned funded task',
    posterType: WorkOpportunityPosterType.moolSocial,
    title: 'Wholesaler Onboarding Specialist',
    summary:
        'Identify eligible wholesalers and complete verified, owner-approved business onboarding.',
    qualificationHeadline:
        'Wholesale-market network and B2B onboarding ability',
    kind: 'Freelance onboarding',
    location: 'Madhupura, Ahmedabad · 380004',
    city: 'Ahmedabad',
    area: 'Madhupura',
    pincode: '380004',
    capacity: '16 funded onboardings',
    peopleNeeded: 16,
    peopleJoined: 6,
    applicationsInProgress: 4,
    finalDeadline: '13 Sep 2026',
    paymentAmount: '₹700 per verified wholesaler',
    monthlyPayment: 'Up to ₹11,200 monthly for 16 verified onboardings',
    assignmentPayment: '₹700 per approved onboarding',
    payout: 'Within 2 working days',
    requiredWork: 'Wholesaler acquisition freelancer',
    deadline: 'Open while 16 funded onboardings remain',
    fundingNote: 'Funded · maximum task budget ₹11,200',
    aboutRole:
        'Grow verified wholesale supply in Ahmedabad through informed, consent-based business onboarding.',
    whatYoullDo: [
      'Identify eligible wholesalers and confirm the business owner.',
      'Explain catalogue and trade-order requirements.',
      'Submit a verified onboarding record with consent.',
    ],
    whoYouAre: [
      'You know wholesale markets and can speak with business owners.',
      'You can explain a mobile trade workflow clearly.',
    ],
    niceToHave: ['Distribution, sourcing or B2B marketplace experience.'],
    whyJoin:
        'Use your wholesale network for transparent, funded onboarding outcomes.',
    cardColorToken: WorkOpportunityCardColorToken.indigo,
    requiresWorkspace: false,
    icon: Icons.warehouse_outlined,
    filters: {
      WorkFeedFilter.forYou,
      WorkFeedFilter.freelance,
      WorkFeedFilter.nearby,
    },
  ),
  WorkOpportunity(
    id: 'taxi-operator-onboarding-specialist',
    publisher: 'Arjun Fleet Services',
    publisherType: 'Verified rider-owned posting',
    posterType: WorkOpportunityPosterType.rider,
    title: 'Taxi Operator Onboarding Specialist',
    summary:
        'Onboard owner-drivers and taxi operators with verified vehicle and operating-area details.',
    qualificationHeadline: 'Existing taxi-owner or driver network',
    kind: 'Freelance onboarding',
    location: 'Sanganer, Jaipur · 302029',
    city: 'Jaipur',
    area: 'Sanganer',
    pincode: '302029',
    capacity: '12 funded onboardings',
    peopleNeeded: 12,
    peopleJoined: 4,
    applicationsInProgress: 3,
    finalDeadline: '10 Sep 2026',
    paymentAmount: '₹550 per verified taxi operator',
    monthlyPayment: 'Up to ₹6,600 monthly for 12 verified operators',
    assignmentPayment: '₹550 per approved taxi operator',
    payout: 'Within 2 working days',
    requiredWork: 'Taxi onboarding freelancer',
    deadline: 'Open while 12 funded onboardings remain',
    fundingNote: 'Rider funded · maximum task budget ₹6,600',
    aboutRole:
        'Recruit eligible taxi operators for a verified fleet owner in one defined Jaipur service area.',
    whatYoullDo: [
      'Contact owner-drivers and explain the exact participation terms.',
      'Verify taxi category, documents and operating area.',
      'Submit consent-backed onboarding evidence.',
    ],
    whoYouAre: [
      'You have active connections with taxi owners or drivers.',
      'You can verify documents without retaining private copies.',
    ],
    niceToHave: ['Taxi union, fleet desk or mobility-platform experience.'],
    whyJoin: 'Earn per verified taxi operator through a funded local task.',
    cardColorToken: WorkOpportunityCardColorToken.amber,
    requiresWorkspace: false,
    icon: Icons.local_taxi_outlined,
    filters: {
      WorkFeedFilter.forYou,
      WorkFeedFilter.freelance,
      WorkFeedFilter.nearby,
    },
  ),
  WorkOpportunity(
    id: 'bike-rider-onboarding-specialist',
    publisher: 'Imran Khan',
    publisherType: 'Verified rider-owned posting',
    posterType: WorkOpportunityPosterType.rider,
    title: 'Bike Rider Onboarding Specialist',
    summary:
        'Find eligible bike riders and complete licence, vehicle and service-area verification.',
    qualificationHeadline: 'Bike-rider network and local route knowledge',
    kind: 'Freelance onboarding',
    location: 'Talwandi, Kota · 324005',
    city: 'Kota',
    area: 'Talwandi',
    pincode: '324005',
    capacity: '20 funded onboardings',
    peopleNeeded: 20,
    peopleJoined: 7,
    applicationsInProgress: 5,
    finalDeadline: '14 Sep 2026',
    paymentAmount: '₹300 per verified bike rider',
    monthlyPayment: 'Up to ₹6,000 monthly for 20 verified riders',
    assignmentPayment: '₹300 per approved bike rider',
    payout: 'T+1 after verification',
    requiredWork: 'Bike-rider onboarding freelancer',
    deadline: 'Open while 20 funded onboardings remain',
    fundingNote: 'Rider funded · maximum task budget ₹6,000',
    aboutRole:
        'Help a verified rider create a local pool of eligible bike riders for defined route work.',
    whatYoullDo: [
      'Introduce the opportunity and its terms accurately.',
      'Confirm licence, bike and preferred operating area.',
      'Submit each rider only after consent.',
    ],
    whoYouAre: [
      'You know active bike riders in Kota.',
      'You can use the onboarding and verification flow reliably.',
    ],
    niceToHave: ['Delivery or two-wheeler community coordination experience.'],
    whyJoin: 'Turn local rider connections into verified, funded outcomes.',
    cardColorToken: WorkOpportunityCardColorToken.cobalt,
    requiresWorkspace: false,
    icon: Icons.two_wheeler_outlined,
    filters: {
      WorkFeedFilter.forYou,
      WorkFeedFilter.freelance,
      WorkFeedFilter.nearby,
    },
  ),
  WorkOpportunity(
    id: 'bus-operator-onboarding-specialist',
    publisher: 'Rajasthan Route Partners',
    publisherType: 'Verified other-user-owned posting',
    posterType: WorkOpportunityPosterType.other,
    title: 'Bus Operator Onboarding Specialist',
    summary:
        'Onboard verified private bus operators with route, fleet and authorized-contact details.',
    qualificationHeadline:
        'Bus-operator network and transport-business knowledge',
    kind: 'Freelance onboarding',
    location: 'Surajpole, Udaipur · 313001',
    city: 'Udaipur',
    area: 'Surajpole',
    pincode: '313001',
    capacity: '8 funded onboardings',
    peopleNeeded: 8,
    peopleJoined: 2,
    applicationsInProgress: 2,
    finalDeadline: '16 Sep 2026',
    paymentAmount: '₹1,200 per verified bus operator',
    monthlyPayment: 'Up to ₹9,600 monthly for 8 verified operators',
    assignmentPayment: '₹1,200 per approved bus operator',
    payout: 'Within 3 working days',
    requiredWork: 'Bus-operator onboarding freelancer',
    deadline: 'Open while 8 funded onboardings remain',
    fundingNote: 'User funded · maximum task budget ₹9,600',
    aboutRole:
        'Build a verified private-bus operator directory for a local route-services user.',
    whatYoullDo: [
      'Contact an authorized operator representative.',
      'Confirm routes, fleet category and business authority.',
      'Complete consent-based onboarding for review.',
    ],
    whoYouAre: [
      'You know private bus owners, agents or operator offices.',
      'You can check business authority and route information.',
    ],
    niceToHave: ['Bus booking, tourism or transport-agency experience.'],
    whyJoin: 'Earn against a small, defined set of high-value onboardings.',
    cardColorToken: WorkOpportunityCardColorToken.crimson,
    requiresWorkspace: false,
    icon: Icons.directions_bus_outlined,
    filters: {
      WorkFeedFilter.forYou,
      WorkFeedFilter.freelance,
      WorkFeedFilter.nearby,
    },
  ),
  WorkOpportunity(
    id: 'wholesale-sales-specialist',
    publisher: 'Surat Textile Distribution',
    publisherType: 'Verified wholesaler-owned posting',
    posterType: WorkOpportunityPosterType.wholesaler,
    title: 'Wholesale Sales Specialist',
    summary:
        'Promote a defined textile catalogue and close attributable retailer orders in-app.',
    qualificationHeadline: 'Wholesale textile sales and retailer relationships',
    kind: 'Freelance sales',
    location: 'Ring Road, Surat · 395002',
    city: 'Surat',
    area: 'Ring Road',
    pincode: '395002',
    capacity: '15 funded orders',
    peopleNeeded: 15,
    peopleJoined: 5,
    applicationsInProgress: 4,
    finalDeadline: '12 Sep 2026',
    paymentAmount: '₹500 per verified wholesale order',
    monthlyPayment: 'Up to ₹7,500 monthly for 15 verified orders',
    assignmentPayment: '₹500 per paid, non-refunded order',
    payout: 'T+2 after the refund window',
    requiredWork: 'Wholesale sales freelancer',
    deadline: 'Open while 15 funded orders remain',
    fundingNote: 'Wholesaler funded · maximum task budget ₹7,500',
    aboutRole:
        'Sell a verified wholesaler catalogue to eligible retailers using attributable in-app orders.',
    whatYoullDo: [
      'Present the exact catalogue, pack and price terms.',
      'Qualify retailer demand and answer product questions.',
      'Close trackable orders without off-platform payment.',
    ],
    whoYouAre: [
      'You have wholesale textile selling experience.',
      'You maintain trusted retailer relationships.',
    ],
    niceToHave: ['Existing Surat textile-market accounts.'],
    whyJoin: 'Sell a funded catalogue with transparent per-order earnings.',
    cardColorToken: WorkOpportunityCardColorToken.magenta,
    requiresWorkspace: true,
    icon: Icons.sell_outlined,
    filters: {
      WorkFeedFilter.forYou,
      WorkFeedFilter.freelance,
      WorkFeedFilter.nearby,
    },
  ),
  WorkOpportunity(
    id: 'bulk-sales-specialist',
    publisher: 'RajTex Manufacturing',
    publisherType: 'Verified manufacturer-owned posting',
    posterType: WorkOpportunityPosterType.manufacturer,
    title: 'Bulk Sales Specialist',
    summary:
        'Find institutional buyers and close funded bulk orders for a defined manufacturer range.',
    qualificationHeadline: 'Institutional or bulk-selling track record',
    kind: 'Freelance sales',
    location: 'Boranada, Jodhpur · 342012',
    city: 'Jodhpur',
    area: 'Boranada',
    pincode: '342012',
    capacity: '10 funded bulk orders',
    peopleNeeded: 10,
    peopleJoined: 4,
    applicationsInProgress: 2,
    finalDeadline: '11 Sep 2026',
    paymentAmount: '₹1,000 per verified bulk order',
    monthlyPayment: 'Up to ₹10,000 monthly for 10 verified orders',
    assignmentPayment: '₹1,000 per paid, non-refunded order',
    payout: 'T+3 after the refund window',
    requiredWork: 'Bulk sales freelancer',
    deadline: 'Open while 10 funded orders remain',
    fundingNote: 'Manufacturer funded · maximum task budget ₹10,000',
    aboutRole:
        'Develop institutional demand and close eligible high-volume orders for a verified manufacturer.',
    whatYoullDo: [
      'Identify buyers whose requirements match the defined range.',
      'Explain quantity, lead-time and payment terms accurately.',
      'Close attributable bulk orders through MoolSocial.',
    ],
    whoYouAre: [
      'You have proven wholesale, institutional or bulk-selling experience.',
      'You can manage longer B2B buying conversations.',
    ],
    niceToHave: [
      'Hospitality, institutional procurement or distributor contacts.',
    ],
    whyJoin: 'Earn a clear amount for each accepted and settled bulk order.',
    cardColorToken: WorkOpportunityCardColorToken.emerald,
    requiresWorkspace: true,
    icon: Icons.inventory_outlined,
    filters: {
      WorkFeedFilter.forYou,
      WorkFeedFilter.freelance,
      WorkFeedFilter.nearby,
    },
  ),
];

const workTerms = <WorkTerm>[
  WorkTerm(
    id: 'payment',
    title: 'Payment and payout',
    detail:
        'Use the selected opportunity’s funded amount, monthly earning basis, optional hourly or assignment rate, and payout timing.',
  ),
  WorkTerm(
    id: 'publisher',
    title: 'What the publisher provides',
    detail:
        'The selected opportunity states whether MoolSocial or a verified user posted and funded the requirement.',
  ),
  WorkTerm(
    id: 'review',
    title: 'Review, correction and rejection',
    detail:
        'Acceptance follows the selected opportunity’s stated work and qualification requirements. A failed action remains retryable without changing application identity.',
  ),
  WorkTerm(
    id: 'rights',
    title: 'Content use and rights',
    detail:
        'Any content-specific usage, disclosure and rights requirements must be stated in the selected opportunity before application.',
  ),
];

const workProfiles = <WorkProfileOption>[
  WorkProfileOption(
    id: 'retailer-grocery',
    familyId: 'products-trade',
    familyLabel: 'Products & Trade',
    label: 'Grocery / Kirana Shop',
    gstMatchCategory: WorkGstMatchCategory.retailGoodsSupplier,
    sellSide:
        'Grow a trusted neighbourhood store and serve more local customers.',
    buySide: 'Source verified wholesale packs from eligible suppliers.',
    tools: 'Run catalogue, stock, orders, delivery and business records.',
    icon: Icons.storefront_rounded,
  ),
  WorkProfileOption(
    id: 'retailer-speciality',
    familyId: 'products-trade',
    familyLabel: 'Products & Trade',
    label: 'Speciality Retail Shop',
    gstMatchCategory: WorkGstMatchCategory.retailGoodsSupplier,
    sellSide:
        'Showcase specialist products to customers searching by category.',
    buySide:
        'Build reliable supplier relationships and source with confidence.',
    tools: 'Manage catalogue, inventory, orders, invoices and fulfilment.',
    icon: Icons.shopping_bag_outlined,
  ),
  WorkProfileOption(
    id: 'wholesaler',
    familyId: 'products-trade',
    familyLabel: 'Products & Trade',
    label: 'Wholesaler / Distributor',
    gstMatchCategory: WorkGstMatchCategory.wholesaleDistributor,
    sellSide:
        'Reach verified retailers with clear case packs, pricing and trade terms.',
    buySide: 'Connect with manufacturers and strengthen your sourcing network.',
    tools: 'Manage business orders, buyer terms, credit and dispatch.',
    icon: Icons.warehouse_outlined,
  ),
  WorkProfileOption(
    id: 'manufacturer',
    familyId: 'products-trade',
    familyLabel: 'Products & Trade',
    label: 'Manufacturer / Supplier',
    gstMatchCategory: WorkGstMatchCategory.manufacturerSupplier,
    sellSide:
        'Expand distribution by reaching eligible retailers and wholesalers.',
    buySide: 'Source business materials and specialist services.',
    tools: 'Track sales opportunities, distribution partners and fulfilment.',
    icon: Icons.factory_outlined,
  ),
  WorkProfileOption(
    id: 'restaurant',
    familyId: 'food-business',
    familyLabel: 'Food Business',
    label: 'Restaurant / Café',
    gstMatchCategory: WorkGstMatchCategory.foodServiceProvider,
    sellSide:
        'Welcome more diners through delivery, pickup and table bookings.',
    buySide: 'Source ingredients, packaging and operating supplies.',
    tools: 'Run menus, kitchen flow, orders, tables and customer service.',
    icon: Icons.restaurant_rounded,
  ),
  WorkProfileOption(
    id: 'cloud-kitchen',
    familyId: 'food-business',
    familyLabel: 'Food Business',
    label: 'Cloud Kitchen / Tiffin',
    gstMatchCategory: WorkGstMatchCategory.foodServiceProvider,
    sellSide: 'Grow meal orders, tiffin plans and recurring subscriptions.',
    buySide: 'Source ingredients and packaging from suitable suppliers.',
    tools: 'Manage menus, meal plans, kitchen flow and delivery.',
    icon: Icons.soup_kitchen_outlined,
  ),
  WorkProfileOption(
    id: 'clinic',
    familyId: 'health',
    familyLabel: 'Health & Medicine',
    label: 'Clinic / Doctor',
    gstMatchCategory: WorkGstMatchCategory.healthcareProvider,
    sellSide:
        'Build a trusted patient presence and offer verified appointments.',
    buySide: 'Organise eligible clinic and professional supplies.',
    tools: 'Manage availability, consent, appointments and follow-up.',
    icon: Icons.medical_services_outlined,
  ),
  WorkProfileOption(
    id: 'pharmacy',
    familyId: 'health',
    familyLabel: 'Health & Medicine',
    label: 'Pharmacy',
    gstMatchCategory: WorkGstMatchCategory.pharmacySupplier,
    sellSide: 'Serve eligible medicine orders with licensed fulfilment.',
    buySide: 'Source medicines and products from licensed suppliers.',
    tools: 'Manage prescription review, compliant stock and orders.',
    icon: Icons.local_pharmacy_outlined,
  ),
  WorkProfileOption(
    id: 'salon',
    familyId: 'services',
    familyLabel: 'Services & Salon',
    label: 'Salon / Wellness',
    gstMatchCategory: WorkGstMatchCategory.personalCareProvider,
    sellSide:
        'Attract repeat customers with appointments, services and packages.',
    buySide: 'Source professional products for your team and customers.',
    tools: 'Manage schedules, staff, billing and repeat visits.',
    icon: Icons.content_cut_rounded,
  ),
  WorkProfileOption(
    id: 'travel-bike-provider',
    familyId: 'travel',
    familyLabel: 'Travel Partners',
    label: 'Bike Travel Provider',
    gstMatchCategory: WorkGstMatchCategory.bikeTravelProvider,
    sellSide: 'Offer eligible passenger bike trips in your operating area.',
    buySide: 'Find bike care and operating services.',
    tools: 'Manage trip availability, safety, documents and earnings.',
    icon: Icons.two_wheeler_rounded,
  ),
  WorkProfileOption(
    id: 'travel-auto-provider',
    familyId: 'travel',
    familyLabel: 'Travel Partners',
    label: 'Auto Travel Provider',
    gstMatchCategory: WorkGstMatchCategory.autoTravelProvider,
    sellSide: 'Offer eligible auto trips in your operating area.',
    buySide: 'Find auto care and operating services.',
    tools: 'Manage trip availability, safety, documents and earnings.',
    icon: Icons.electric_rickshaw_outlined,
  ),
  WorkProfileOption(
    id: 'travel-cab-provider',
    familyId: 'travel',
    familyLabel: 'Travel Partners',
    label: 'Cab Travel Provider',
    gstMatchCategory: WorkGstMatchCategory.cabTravelProvider,
    sellSide: 'Offer eligible cab trips in your operating area.',
    buySide: 'Find cab care and operating services.',
    tools: 'Manage trip availability, safety, documents and earnings.',
    icon: Icons.local_taxi_outlined,
  ),
  WorkProfileOption(
    id: 'travel-bus-provider',
    familyId: 'travel',
    familyLabel: 'Travel Partners',
    label: 'Bus Travel Provider',
    gstMatchCategory: WorkGstMatchCategory.busTravelProvider,
    sellSide: 'Offer eligible passenger bus routes and service capacity.',
    buySide: 'Find route and fleet operating services.',
    tools: 'Manage buses, drivers, routes, safety and settlements.',
    icon: Icons.directions_bus_outlined,
  ),
  WorkProfileOption(
    id: 'quick-delivery-biker',
    familyId: 'delivery',
    familyLabel: 'Delivery & Logistics',
    label: 'Quick Delivery Biker',
    gstMatchCategory: WorkGstMatchCategory.quickDeliveryBiker,
    sellSide: 'Accept eligible local quick-delivery assignments.',
    buySide: 'Find bike care and delivery operating services.',
    tools: 'Manage delivery availability, routes, proof and earnings.',
    icon: Icons.delivery_dining_outlined,
  ),
  WorkProfileOption(
    id: 'wholesale-fleet-delivery',
    familyId: 'delivery',
    familyLabel: 'Delivery & Logistics',
    label: 'Wholesale Fleet Delivery',
    gstMatchCategory: WorkGstMatchCategory.wholesaleFleetDelivery,
    sellSide: 'Offer verified fleet capacity for wholesale deliveries.',
    buySide: 'Find suitable wholesale routes and operating services.',
    tools: 'Manage vehicles, drivers, wholesale routes and settlements.',
    icon: Icons.local_shipping_outlined,
  ),
  WorkProfileOption(
    id: 'bulk-delivery-fleet',
    familyId: 'delivery',
    familyLabel: 'Delivery & Logistics',
    label: 'Bulk Delivery Fleet',
    gstMatchCategory: WorkGstMatchCategory.bulkDeliveryFleet,
    sellSide: 'Offer verified vehicle capacity for bulk deliveries.',
    buySide: 'Find suitable bulk routes and operating services.',
    tools: 'Manage vehicles, drivers, bulk routes and settlements.',
    icon: Icons.local_shipping_outlined,
  ),
  WorkProfileOption(
    id: 'creator',
    familyId: 'create-work',
    familyLabel: 'Create & Work',
    label: 'Creator',
    gstMatchCategory: WorkGstMatchCategory.digitalContentProvider,
    sellSide: 'Turn your audience and skills into paid brand opportunities.',
    buySide: 'Find professional tools and creator support.',
    tools: 'Manage channels, campaigns, deliverables and earnings.',
    icon: Icons.video_camera_front_outlined,
  ),
  WorkProfileOption(
    id: 'freelancer',
    familyId: 'create-work',
    familyLabel: 'Create & Work',
    label: 'Freelancer / Job Seeker',
    gstMatchCategory: WorkGstMatchCategory.independentProfessional,
    sellSide: 'Showcase your skills and pursue paid assignments and roles.',
    buySide: 'Access professional services that support your work.',
    tools: 'Manage applications, portfolio documents, payouts and profile.',
    icon: Icons.work_outline_rounded,
  ),
];

const workProofs = <WorkProofRequirement>[
  WorkProofRequirement(
    id: 'personal-kyc',
    label: 'Personal identity',
    detail: 'Signed-in account identity · included with this application',
    importance: WorkDocumentImportance.required,
  ),
  WorkProofRequirement(
    id: 'shop-front',
    label: 'Shop or workplace document',
    detail: 'A clear current document showing the work name or location',
    importance: WorkDocumentImportance.required,
  ),
  WorkProofRequirement(
    id: 'owner-authority',
    label: 'Owner or operator authority',
    detail: 'Registration, licence, bill or authorization showing your link',
    importance: WorkDocumentImportance.required,
  ),
  WorkProofRequirement(
    id: 'gst',
    label: 'GST certificate',
    detail: 'Required when GST registration applies to this Workspace',
    importance: WorkDocumentImportance.ifApplicable,
  ),
];
