import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'work_models.dart'
    show
        WorkspaceExpenseRecord,
        WorkspaceSupplierLedger,
        WorkspaceSupplierBillAcceptance,
        WorkspaceSupplierMoneyAllocationIntent,
        WorkspaceSupplierBillMoneyAllocation,
        WorkspaceSupplierRefundIntent,
        WorkspaceSupplierRefund,
        WorkspaceSupplierCreditIntent,
        WorkspaceSupplierCreditNote,
        WorkspaceSupplierOpeningRecord,
        WorkspaceSupplierMoneyAttempt,
        WorkspaceMoneyRegisterSnapshot;
import 'work_purchase_entry_gateway.dart'
    show WorkspacePurchaseEntryScope, WorkspacePurchaseEntryRequest;

typedef WorkspaceLedgerScope = WorkspacePurchaseEntryScope;
Map<String, Object?> _object(Object? value) {
  if (value is! Map || value.keys.any((key) => key is! String))
    throw const FormatException();
  return Map<String, Object?>.from(value);
}

void _keys(Map<String, Object?> value, Set<String> required) {
  if (value.length != required.length || !required.every(value.containsKey))
    throw const FormatException();
}

String _text(Object? value, {bool blank = false, int? maximum}) {
  if (value is! String ||
      !blank && value.trim().isEmpty ||
      maximum != null && value.length > maximum ||
      RegExp(r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]').hasMatch(value) ||
      utf8.decode(utf8.encode(value)) != value)
    throw const FormatException();
  return value;
}

int _integer(Object? value, {int minimum = 0}) {
  if (value is! int || value < minimum || value.abs() > 9007199254740991)
    throw const FormatException();
  return value;
}

String _fingerprint(Object? value) {
  if (value is! String || !RegExp(r'^[a-f0-9]{64}$').hasMatch(value))
    throw const FormatException();
  return value;
}

DateTime _time(Object? value) {
  if (value is! String || !value.endsWith('Z')) throw const FormatException();
  final parsed = DateTime.parse(value).toUtc();
  if (parsed.toIso8601String() != value) throw const FormatException();
  return parsed;
}

Object? _sorted(Object? value) {
  if (value == null || value is String || value is bool) return value;
  if (value is int) return _integer(value, minimum: -9007199254740991);
  if (value is List) return List<Object?>.unmodifiable(value.map(_sorted));
  final map = _object(value), keys = map.keys.toList()..sort();
  return Map<String, Object?>.unmodifiable({
    for (final key in keys) key: _sorted(map[key]),
  });
}

String workspaceLedgerCanonical(Object? value) => jsonEncode(_sorted(value));
String workspaceLedgerFingerprint(Object? value) => crypto.sha256
    .convert(utf8.encode(workspaceLedgerCanonical(value)))
    .toString();
Map<String, Object?> _scopeJson(WorkspaceLedgerScope scope) => {
  'account': scope.account,
  'store': scope.store,
  'realm': scope.realm,
};
void _scope(WorkspaceLedgerScope scope) {
  _text(scope.account);
  _text(scope.store);
  if (!const {'evaluation', 'production'}.contains(scope.realm))
    throw const FormatException();
}

const _kinds = {'supplierLedger', 'expense', 'moneyRegister', 'moneyEntry'};
const _operations = {
  'recordStoreExpense',
  'confirmStoreSupplierOpening',
  'recordStoreMoneyRegisterEntry',
  'recordStoreSupplierMoney',
  'confirmStoreSupplierBill',
  'recordStoreSupplierMoneyAllocation',
  'recordStoreSupplierRefund',
  'recordStoreSupplierCreditNote',
};
const _entryKeys = {'id', 'reference', 'occurredAt', 'deltaMinor'};
const _headerKeys = {
  'accountScope',
  'workspaceId',
  'registerId',
  'label',
  'revision',
  'openingAt',
  'asOf',
  'openingMinor',
  'historyComplete',
  'entryCount',
  'lastEntryAt',
  'sequenceValidationMinor',
};
void _entry(Map<String, Object?> value) {
  _keys(value, _entryKeys);
  _text(value['id']);
  _text(value['reference']);
  _time(value['occurredAt']);
  if (_integer(value['deltaMinor'], minimum: -9007199254740991) == 0)
    throw const FormatException();
}

void _header(Map<String, Object?> value, WorkspaceLedgerScope scope) {
  _keys(value, _headerKeys);
  _text(value['registerId']);
  _text(value['label']);
  _integer(value['revision'], minimum: 1);
  final start = _time(value['openingAt']),
      end = _time(value['asOf']),
      count = _integer(value['entryCount']);
  final opening = value['openingMinor'] == null
      ? null
      : _integer(value['openingMinor'], minimum: -9007199254740991);
  final guard = _integer(
    value['sequenceValidationMinor'],
    minimum: -9007199254740991,
  );
  if (value['accountScope'] != scope.account ||
      value['workspaceId'] != scope.store ||
      value['historyComplete'] is! bool ||
      value['historyComplete'] == true && opening == null ||
      start.isAfter(end))
    throw const FormatException();
  if (count == 0) {
    if (value['lastEntryAt'] != null || guard != (opening ?? 0))
      throw const FormatException();
  } else {
    final tail = _time(value['lastEntryAt']);
    if (tail.isBefore(start) || !tail.isBefore(end))
      throw const FormatException();
  }
}

void _opening(Map<String, Object?> value, WorkspaceLedgerScope scope) {
  final opening = WorkspaceSupplierOpeningRecord.fromJson(value);
  _time(value['savedAt']);
  if (opening.account != scope.account ||
      opening.store != scope.store ||
      opening.qa)
    throw const FormatException();
}

void _expense(Map<String, Object?> value, WorkspaceLedgerScope scope) {
  _keys(value, {
    'account',
    'store',
    'operationId',
    'amountMinor',
    'category',
    'method',
    'reference',
    'note',
    'occurredAt',
  });
  final expense = WorkspaceExpenseRecord.fromJson(value);
  for (final key in [
    'account',
    'store',
    'operationId',
    'category',
    'method',
    'reference',
  ]) {
    _text(value[key], maximum: 512);
  }
  _text(value['note'], maximum: 2000, blank: true);
  _time(value['occurredAt']);
  _integer(value['amountMinor'], minimum: 1);
  if (expense == null ||
      expense.accountScope != scope.account ||
      expense.workspaceId != scope.store)
    throw const FormatException();
}

/// A deeply frozen native-confirmed command. Preparing it never saves a record.
void _supplierMoneyEntry(Map<String, Object?> value) {
  _keys(value, {
    'operationId', 'orderId', 'origin', 'reference', 'billId', 'paymentMethod',
    'moneyReview', 'kind', 'amountMinor', 'postedAt',
    if (value['origin'] == 'manualPurchase') 'purchaseId',
  });
  _text(value['operationId']); _text(value['reference']); _time(value['postedAt']);
  _integer(value['amountMinor'], minimum: 1);
  if (!const {'UPI', 'Cheque', 'Bank transfer', 'NEFT', 'RTGS', 'Cash'}.contains(value['paymentMethod'])) {
    throw const FormatException();
  }
  final native = WorkspaceSupplierMoneyAttempt.fromJson({'entry': value, 'expectedRevision': 1});
  if (native == null || workspaceLedgerCanonical(native.entry.toJson()) != workspaceLedgerCanonical(value)) {
    throw const FormatException();
  }
}

class WorkspaceLedgerIntent {
  WorkspaceLedgerIntent._(this.scope, this.data, this.fingerprint);
  factory WorkspaceLedgerIntent.fromJson(
    Object? raw,
    WorkspaceLedgerScope scope,
  ) {
    _scope(scope);
    final value = _object(raw), operation = value['operation'];
    if (!_operations.contains(operation)) throw const FormatException();
    final specific = operation == 'recordStoreExpense'
        ? {'expense'}
        : operation == 'confirmStoreSupplierOpening'
        ? {
            'opening',
            'expectedPurchaseRevision',
            'expectedPurchaseFingerprint',
            'confirmedAt',
            'confirmedUtcOffsetMinutes',
          }
        : operation == 'recordStoreSupplierMoney'
        ? {'supplierId', 'expectedSupplierRevision', 'entry', 'confirmedUtcOffsetMinutes'}
        : operation == 'confirmStoreSupplierBill'
        ? {'supplierId', 'expectedSupplierRevision', 'expectedPurchaseRevision',
            'expectedPurchaseFingerprint', 'bill', 'confirmedUtcOffsetMinutes'}
        : operation == 'recordStoreSupplierMoneyAllocation'
        ? {'supplierId', 'expectedSupplierRevision', 'intent'}
        : operation == 'recordStoreSupplierRefund'
        ? {'supplierId', 'expectedSupplierRevision', 'intent', 'confirmedUtcOffsetMinutes'}
        : operation == 'recordStoreSupplierCreditNote'
        ? {'supplierId', 'expectedSupplierRevision', 'intent', 'confirmedUtcOffsetMinutes',
            'expectedPurchaseRevision', 'expectedPurchaseFingerprint'}
        : {'registerId', 'expectedRegisterRevision', 'entry', 'capturedAt'};
    _keys(value, {
      'scope',
      'operation',
      'expectedRevision',
      'idempotencyKey',
      'fingerprint',
      ...specific,
    });
    if (workspaceLedgerCanonical(value['scope']) !=
        workspaceLedgerCanonical(_scopeJson(scope)))
      throw const FormatException();
    if (value['expectedRevision'] != null)
      _integer(value['expectedRevision'], minimum: 1);
    _text(value['idempotencyKey']);
    if (operation == 'recordStoreExpense') {
      _expense(_object(value['expense']), scope);
    } else if (operation == 'confirmStoreSupplierOpening') {
      _opening(_object(value['opening']), scope);
      _integer(value['expectedPurchaseRevision'], minimum: 1);
      _fingerprint(value['expectedPurchaseFingerprint']);
      _time(value['confirmedAt']);
      if (_integer(value['confirmedUtcOffsetMinutes'], minimum: -720) > 840)
        throw const FormatException();
    } else if (operation == 'recordStoreSupplierMoney') {
      _text(value['supplierId']); _integer(value['expectedSupplierRevision'], minimum: 1);
      _supplierMoneyEntry(_object(value['entry']));
      if (_integer(value['confirmedUtcOffsetMinutes'], minimum: -720) > 840) throw const FormatException();
    } else if (operation == 'confirmStoreSupplierBill') {
      _text(value['supplierId']);
      _integer(value['expectedSupplierRevision'], minimum: 1);
      _integer(value['expectedPurchaseRevision'], minimum: 1);
      _fingerprint(value['expectedPurchaseFingerprint']);
      final bill = _object(value['bill']);
      final accepted = WorkspaceSupplierBillAcceptance.fromJson(bill);
      _time(bill['acceptedAt']);
      if (accepted.copy.supplier.id != value['supplierId'] ||
          _integer(value['confirmedUtcOffsetMinutes'], minimum: -720) > 840) {
        throw const FormatException();
      }
    } else if (operation == 'recordStoreSupplierMoneyAllocation') {
      _text(value['supplierId']); _integer(value['expectedSupplierRevision'], minimum: 1);
      final raw = _object(value['intent']), intent = WorkspaceSupplierMoneyAllocationIntent.fromJson(raw);
      _time(raw['requestedAt']);
      if (intent.accountScope != scope.account || intent.workspaceId != scope.store || intent.supplierId != value['supplierId']) {
        throw const FormatException();
      }
    } else if (operation == 'recordStoreSupplierRefund') {
      _text(value['supplierId']); _integer(value['expectedSupplierRevision'], minimum: 1);
      final raw = _object(value['intent']), intent = WorkspaceSupplierRefundIntent.fromJson(raw);
      _time(raw['requestedAt']);
      if (intent.accountScope != scope.account || intent.workspaceId != scope.store || intent.supplierId != value['supplierId'] ||
          _integer(value['confirmedUtcOffsetMinutes'], minimum: -720) > 840) throw const FormatException();
    } else if (operation == 'recordStoreSupplierCreditNote') {
      _text(value['supplierId']); _integer(value['expectedSupplierRevision'], minimum: 1);
      _integer(value['expectedPurchaseRevision'], minimum: 1); _fingerprint(value['expectedPurchaseFingerprint']);
      final raw = _object(value['intent']), intent = WorkspaceSupplierCreditIntent.fromJson(raw);
      _time(raw['requestedAt']);
      if (intent.accountScope != scope.account || intent.workspaceId != scope.store || intent.supplierId != value['supplierId'] ||
          intent.documentInput == null || intent.documentInput!.treatment.isEmpty || intent.documentInput!.reasonCode.isEmpty ||
          _integer(value['confirmedUtcOffsetMinutes'], minimum: -720) > 840) throw const FormatException();
    } else {
      _text(value['registerId']);
      _integer(value['expectedRegisterRevision'], minimum: 1);
      _entry(_object(value['entry']));
      _time(value['capturedAt']);
    }
    final fingerprint = _fingerprint(value.remove('fingerprint'));
    if (fingerprint != workspaceLedgerFingerprint(value))
      throw const FormatException();
    return WorkspaceLedgerIntent._(
      scope,
      _sorted(value)! as Map<String, Object?>,
      fingerprint,
    );
  }

  /// Called only after the existing form has validated its reviewed fields.
  factory WorkspaceLedgerIntent.prepare({
    required WorkspaceLedgerScope scope,
    required String operation,
    required int? expectedRevision,
    required String idempotencyKey,
    required Map<String, Object?> fields,
  }) {
    final input = {
      'scope': _scopeJson(scope),
      'operation': operation,
      'expectedRevision': expectedRevision,
      'idempotencyKey': idempotencyKey,
      ...fields,
    };
    return WorkspaceLedgerIntent.fromJson({
      ...input,
      'fingerprint': workspaceLedgerFingerprint(input),
    }, scope);
  }
  final WorkspaceLedgerScope scope;
  final Map<String, Object?> data;
  final String fingerprint;
  String get operation => data['operation']! as String;
  String get idempotencyKey => data['idempotencyKey']! as String;
  Map<String, Object?> toJson() => {...data, 'fingerprint': fingerprint};
  Object? get input =>
      data[operation == 'recordStoreExpense'
          ? 'expense'
          : operation == 'confirmStoreSupplierOpening'
          ? 'opening'
          : operation == 'confirmStoreSupplierBill'
          ? 'bill'
          : operation == 'recordStoreSupplierMoneyAllocation' || operation == 'recordStoreSupplierRefund' || operation == 'recordStoreSupplierCreditNote'
          ? 'intent'
          : 'entry'];
  String get targetKind => operation == 'recordStoreExpense'
      ? 'expense'
      : operation == 'confirmStoreSupplierOpening' || operation == 'recordStoreSupplierMoney' || operation == 'confirmStoreSupplierBill' || operation == 'recordStoreSupplierMoneyAllocation' || operation == 'recordStoreSupplierRefund' || operation == 'recordStoreSupplierCreditNote'
      ? 'supplierLedger'
      : 'moneyRegister';
  String get targetId => operation == 'recordStoreExpense'
      ? _object(input)['operationId']! as String
      : operation == 'confirmStoreSupplierOpening'
      ? _object(input)['supplierId']! as String
      : operation == 'recordStoreSupplierMoney' || operation == 'confirmStoreSupplierBill' || operation == 'recordStoreSupplierMoneyAllocation' || operation == 'recordStoreSupplierRefund' || operation == 'recordStoreSupplierCreditNote'
      ? data['supplierId']! as String
      : data['registerId']! as String;
  String? get entryId => operation == 'recordStoreMoneyRegisterEntry'
      ? _object(input)['id']! as String
      : operation == 'recordStoreSupplierMoney' || operation == 'recordStoreSupplierMoneyAllocation' || operation == 'recordStoreSupplierRefund' || operation == 'recordStoreSupplierCreditNote'
      ? _object(input)['operationId']! as String
      : operation == 'confirmStoreSupplierBill'
      ? _object(_object(_object(input)['copy'])['draft'])['id']! as String
      : null;
}

class WorkspaceLedgerRow {
  WorkspaceLedgerRow._(this.data, this.value);
  factory WorkspaceLedgerRow.decode(Object? raw, WorkspaceLedgerScope scope) {
    final row = _object(raw);
    _keys(row, {
      'kind',
      'id',
      'parentId',
      'revision',
      'json',
      'fingerprint',
      'ordinal',
    });
    final kind = row['kind'], id = _text(row['id']);
    _integer(row['revision'], minimum: 1);
    if (!_kinds.contains(kind) || row['json'] is! String)
      throw const FormatException();
    final value = _object(jsonDecode(row['json']! as String));
    if (workspaceLedgerCanonical(value) != row['json'] ||
        workspaceLedgerFingerprint(value) != _fingerprint(row['fingerprint']))
      throw const FormatException();
    if (kind == 'moneyEntry') {
      _text(row['parentId']);
      _integer(row['ordinal'], minimum: 1);
      _entry(value);
      if (value['id'] != id) throw const FormatException();
    } else {
      if (row['parentId'] != null || row['ordinal'] != null)
        throw const FormatException();
      if (kind == 'expense') {
        _expense(value, scope);
        if (value['operationId'] != id) throw const FormatException();
      }
      if (kind == 'moneyRegister') {
        _header(value, scope);
        if (value['registerId'] != id || value['revision'] != row['revision'])
          throw const FormatException();
      }
      if (kind == 'supplierLedger') {
        final ledger = WorkspaceSupplierLedger.fromJson(value);
        if (ledger == null ||
            ledger.accountScope != scope.account ||
            ledger.workspaceId != scope.store ||
            ledger.supplierId != id ||
            ledger.revision != row['revision'])
          throw const FormatException();
        _time(value['asOf']);
        if (value['openingRecord'] != null)
          _opening(_object(value['openingRecord']), scope);
      }
    }
    return WorkspaceLedgerRow._(
      _sorted(row)! as Map<String, Object?>,
      _sorted(value)! as Map<String, Object?>,
    );
  }
  final Map<String, Object?> data, value;
  String get kind => data['kind']! as String;
  String get id => data['id']! as String;
}

class WorkspaceLedgerReadback {
  WorkspaceLedgerReadback._({
    required this.revision,
    required this.observedAt,
    required this.attempt,
    required this.current,
  });
  final int? revision;
  final DateTime observedAt;
  final Map<String, Object?>? attempt;
  final WorkspaceLedgerRow? current;
  factory WorkspaceLedgerReadback.decode(
    Object? raw,
    WorkspaceLedgerScope scope,
    DateTime now,
    WorkspaceLedgerIntent original,
  ) {
    if (original.scope != scope) throw const FormatException();
    final value = _frame(raw, scope, now, {
      'state',
      'sourceRevision',
      'attempt',
      'current',
    });
    final revision = value['sourceRevision'] == null
        ? null
        : _integer(value['sourceRevision'], minimum: 1);
    if (value['state'] != (revision == null ? 'empty' : 'ready'))
      throw const FormatException();
    final current = value['current'] == null
        ? null
        : WorkspaceLedgerRow.decode(value['current'], scope);
    if (revision == null && current != null) throw const FormatException();
    Map<String, Object?>? attempt;
    if (value['attempt'] != null) {
      final receipt = _object(value['attempt']);
      _keys(receipt, {
        'schemaVersion',
        'scope',
        'operation',
        'idempotencyKey',
        'fingerprint',
        'inputFingerprint',
        'status',
        'reason',
        'changed',
        'resultRevision',
        'targetKind',
        'targetId',
        'entryId',
        'recordedAt',
      });
      final resultRevision = receipt['resultRevision'] == null
          ? null
          : _integer(receipt['resultRevision'], minimum: 1);
      if (receipt['schemaVersion'] != 1 ||
          original.scope != scope ||
          receipt['operation'] != original.operation ||
          workspaceLedgerCanonical(receipt['scope']) !=
              workspaceLedgerCanonical(_scopeJson(scope)) ||
          receipt['idempotencyKey'] != original.idempotencyKey ||
          receipt['fingerprint'] != original.fingerprint ||
          receipt['inputFingerprint'] !=
              workspaceLedgerFingerprint(original.input) ||
          receipt['targetKind'] != original.targetKind ||
          receipt['targetId'] != original.targetId ||
          receipt['entryId'] != original.entryId ||
          receipt['changed'] is! bool ||
          _time(receipt['recordedAt']).isAfter(_time(value['observedAt'])) ||
          resultRevision != null &&
              (revision == null || revision < resultRevision))
        throw const FormatException();
      if (receipt['status'] == 'saved') {
        if (receipt['reason'] != null ||
            resultRevision == null ||
            current == null)
          throw const FormatException();
        if (original.operation == 'recordStoreSupplierMoney') {
          final entries = current.value['entries'];
          if (entries is! List) throw const FormatException();
          final matching = entries.where((entry) => entry is Map && entry['operationId'] == original.entryId).toList();
          if (matching.length != 1 || workspaceLedgerFingerprint(matching.single) != receipt['inputFingerprint']) {
            throw const FormatException();
          }
        }
        if (original.operation == 'confirmStoreSupplierBill') {
          final bill = _object(_object(current.value['purchaseBills'])[original.entryId]);
          final accepted = WorkspaceSupplierBillAcceptance.fromJson(bill);
          final entries = current.value['entries'];
          if (accepted.billId != original.entryId ||
              workspaceLedgerFingerprint(bill) != receipt['inputFingerprint'] || entries is! List) {
            throw const FormatException();
          }
          final matching = entries.where((entry) => entry is Map &&
              entry['kind'] == 'bill' && entry['billId'] == original.entryId).toList();
          final expected = {
            'operationId': 'manual-bill:${accepted.billId}', 'orderId': null,
            'origin': 'manualPurchase', 'purchaseId': accepted.copy.id,
            'reference': accepted.copy.draft.invoiceReference, 'billId': accepted.billId,
            'kind': 'bill', 'amountMinor': accepted.amountMinor, 'postedAt': bill['acceptedAt'],
          };
          if (accepted.addsLiability
              ? matching.length != 1 || workspaceLedgerFingerprint(matching.single) != workspaceLedgerFingerprint(expected)
              : matching.isNotEmpty) throw const FormatException();
        }
        if (original.operation == 'recordStoreSupplierMoneyAllocation') {
          final proofRaw = _object(_object(current.value['billMoneyAllocations'])[original.entryId]);
          final proof = WorkspaceSupplierBillMoneyAllocation.fromJson(proofRaw);
          _time(proofRaw['recordedAt']);
          final input = Map<String, Object?>.from(proofRaw)
            ..remove('committedRevision')..remove('recordedAt')..remove('sourceEntryCount');
          if (proof.operationId != original.entryId || proof.supplierId != original.targetId ||
              proof.accountScope != scope.account || proof.workspaceId != scope.store ||
              proof.committedRevision > (current.data['revision']! as int) ||
              proof.recordedAt.isAfter(_time(current.value['asOf'])) ||
              workspaceLedgerFingerprint(input) != receipt['inputFingerprint']) throw const FormatException();
        }
        if (original.operation == 'recordStoreSupplierRefund') {
          final raw = _object(_object(current.value['refunds'])[original.entryId]);
          final proof = WorkspaceSupplierRefund.fromJson(raw), input = _object(raw['intent']);
          final entries = current.value['entries'];
          if (entries is! List) throw const FormatException();
          final matching = entries.where((entry) => entry is Map && entry['operationId'] == original.entryId).toList();
          final expected = Map<String, Object?>.from(proof.entry.toJson())..['postedAt'] = raw['recordedAt'];
          if (proof.intent.operationId != original.entryId || proof.intent.supplierId != original.targetId ||
              proof.intent.accountScope != scope.account || proof.intent.workspaceId != scope.store ||
              proof.committedRevision > (current.data['revision']! as int) || proof.recordedAt.isAfter(_time(current.value['asOf'])) ||
              workspaceLedgerFingerprint(input) != receipt['inputFingerprint'] || matching.length != 1 ||
              workspaceLedgerFingerprint(matching.single) != workspaceLedgerFingerprint(expected)) throw const FormatException();
        }
        if (original.operation == 'recordStoreSupplierCreditNote') {
          final raw = _object(_object(current.value['creditNotes'])[original.entryId]);
          final proof = WorkspaceSupplierCreditNote.fromJson(raw);
          final input = Map<String, Object?>.from(raw)..remove('recordedAt')..remove('committedRevision');
          final entries = current.value['entries'];
          if (entries is! List) throw const FormatException();
          final matching = entries.where((entry) => entry is Map && entry['operationId'] == original.entryId).toList();
          final expected = {'operationId': proof.operationId, 'orderId': null, 'reference': proof.reference,
            'billId': proof.billId, 'origin': 'manualPurchase', 'purchaseId': proof.copyId,
            'kind': 'creditNote', 'amountMinor': proof.amountMinor, 'postedAt': raw['recordedAt']};
          if (proof.operationId != original.entryId || proof.supplierId != original.targetId ||
              proof.accountScope != scope.account || proof.workspaceId != scope.store ||
              proof.committedRevision > (current.data['revision']! as int) || proof.recordedAt.isAfter(_time(current.value['asOf'])) ||
              workspaceLedgerFingerprint(input) != receipt['inputFingerprint'] || matching.length != 1 ||
              workspaceLedgerFingerprint(matching.single) != workspaceLedgerFingerprint(expected)) throw const FormatException();
        }
        if (original.operation == 'recordStoreExpense' &&
                workspaceLedgerFingerprint(current.value) !=
                    receipt['inputFingerprint'] ||
            original.operation == 'confirmStoreSupplierOpening' &&
                workspaceLedgerFingerprint(current.value['openingRecord']) !=
                    receipt['inputFingerprint'])
          throw const FormatException();
      } else if (receipt['status'] != 'not_saved' ||
          receipt['changed'] != false ||
          !_reasons(original.operation).contains(receipt['reason'])) {
        throw const FormatException();
      }
      if (current != null &&
          (current.id != original.targetId ||
              current.kind != original.targetKind))
        throw const FormatException();
      attempt = _sorted(receipt)! as Map<String, Object?>;
    } else if (current != null) {
      throw const FormatException();
    }
    return WorkspaceLedgerReadback._(
      revision: revision,
      observedAt: _time(value['observedAt']),
      attempt: attempt,
      current: current,
    );
  }
}

Set<String> _reasons(String operation) => {
  'stale_ledger',
  'record_identity_conflict',
  if (operation == 'confirmStoreSupplierOpening') ...{
    'stale_evidence',
    'supplier_has_records',
    'opening_amount_unknown',
    'opening_bill_inclusion_missing',
    'opening_confirmation_invalid',
  },
  if (operation == 'recordStoreMoneyRegisterEntry') ...{
    'register_unavailable',
    'stale_register',
    'register_history_changed',
  },
  if (operation == 'recordStoreSupplierMoney') ...{
    'supplier_unavailable', 'stale_supplier', 'opening_evidence_changed',
    'supplier_capacity_changed', 'supplier_money_evidence_invalid',
  },
  if (operation == 'confirmStoreSupplierBill') ...{
    'supplier_unavailable', 'stale_supplier', 'stale_evidence',
    'bill_source_changed', 'bill_opening_evidence_changed', 'bill_confirmation_invalid',
  },
  if (operation == 'recordStoreSupplierMoneyAllocation') ...{
    'supplier_unavailable', 'stale_supplier', 'opening_evidence_changed',
    'allocation_source_changed', 'allocation_capacity_changed', 'allocation_confirmation_invalid',
  },
  if (operation == 'recordStoreSupplierRefund') ...{
    'supplier_unavailable', 'stale_supplier', 'opening_evidence_changed',
    'refund_source_changed', 'refund_capacity_changed', 'refund_confirmation_invalid', 'refund_reference_conflict',
  },
  if (operation == 'recordStoreSupplierCreditNote') ...{
    'supplier_unavailable', 'stale_supplier', 'stale_evidence', 'opening_evidence_changed',
    'credit_source_changed', 'credit_capacity_changed', 'credit_confirmation_invalid', 'credit_reference_conflict',
  },
};
Map<String, Object?> _frame(
  Object? raw,
  WorkspaceLedgerScope scope,
  DateTime now,
  Set<String> fields,
) {
  final value = _object(raw);
  _keys(value, {
    'schemaVersion',
    'ledgerVersion',
    'actorAccountId',
    'storeId',
    'realm',
    'observedAt',
    ...fields,
  });
  final at = _time(value['observedAt']);
  if (value['schemaVersion'] != 1 ||
      value['ledgerVersion'] != 1 ||
      value['actorAccountId'] != scope.account ||
      value['storeId'] != scope.store ||
      value['realm'] != scope.realm ||
      at.isAfter(now.toUtc().add(const Duration(seconds: 30))) ||
      now.toUtc().difference(at) > const Duration(minutes: 5))
    throw const FormatException();
  return value;
}

class WorkspaceLedgerPage {
  WorkspaceLedgerPage._(
    this.revision,
    this.totalCount,
    this.rows,
    this.nextCursor,
  );
  final int? revision;
  final int totalCount;
  final List<WorkspaceLedgerRow> rows;
  final String? nextCursor;
  factory WorkspaceLedgerPage.decode(
    Object? raw,
    WorkspaceLedgerScope scope,
    DateTime now, {
    required String kind,
    required String? parentId,
    required String? cursor,
  }) {
    final value = _frame(raw, scope, now, {
      'state',
      'sourceRevision',
      'kind',
      'parentId',
      'totalCount',
      'startsSource',
      'rows',
      'nextCursor',
    });
    final revision = value['sourceRevision'] == null
            ? null
            : _integer(value['sourceRevision'], minimum: 1),
        count = _integer(value['totalCount']);
    if (value['state'] != (revision == null ? 'empty' : 'ready') ||
        value['kind'] != kind ||
        value['parentId'] != parentId ||
        value['startsSource'] != (cursor == null) ||
        value['rows'] is! List)
      throw const FormatException();
    final rows = [
      for (final row in value['rows']! as List)
        WorkspaceLedgerRow.decode(row, scope),
    ];
    final next = value['nextCursor'] == null
        ? null
        : _text(value['nextCursor']);
    if (rows.length > count ||
        rows.map((row) => row.id).toSet().length != rows.length ||
        rows.any(
          (row) => row.kind != kind || row.data['parentId'] != parentId,
        ) ||
        next != null && (next == cursor || rows.isEmpty) ||
        revision == null &&
            (count != 0 || rows.isNotEmpty || next != null || cursor != null))
      throw const FormatException();
    return WorkspaceLedgerPage._(
      revision,
      count,
      List.unmodifiable(rows),
      next,
    );
  }
}

class WorkspaceLedgerRequestFailure implements Exception {
  const WorkspaceLedgerRequestFailure({required this.mayHaveCommitted});
  final bool mayHaveCommitted;
  @override
  String toString() =>
      'The saved status could not be confirmed. Keep these details and check again.';
}

/// A complete collection at one original revision, not a financial snapshot.
/// An empty collection establishes no real-world balance or historical total.
class WorkspaceLedgerCollection {
  WorkspaceLedgerCollection._(this.revision, List<WorkspaceLedgerRow> rows) : rows = List.unmodifiable(rows);
  final int? revision;
  final List<WorkspaceLedgerRow> rows;
}
/// Only these original owned sections may be installed by the native bridge.
/// Customer finance, payments, inventory and their history are deliberately
/// absent, rather than manufactured to fit a local checkpoint envelope.
class WorkspaceOwnedLedgerSections {
  WorkspaceOwnedLedgerSections._(this.scope, this.revision,
    Map<String, WorkspaceSupplierLedger> suppliers, Map<String, WorkspaceExpenseRecord> expenses,
    Map<String, WorkspaceMoneyRegisterSnapshot> registers)
    : suppliers = Map.unmodifiable(suppliers), expenses = Map.unmodifiable(expenses), registers = Map.unmodifiable(registers);
  final WorkspaceLedgerScope scope;
  final int? revision;
  final Map<String, WorkspaceSupplierLedger> suppliers;
  final Map<String, WorkspaceExpenseRecord> expenses;
  final Map<String, WorkspaceMoneyRegisterSnapshot> registers;
}

/// Original authenticated transport. No financial totals, local Save fallback,
/// membership grants, automatic retries or subscription decisions live here.
class WorkspaceLedgerRemoteSource {
  WorkspaceLedgerRemoteSource({
    required this.scope,
    required this.connectionId,
    required WorkspacePurchaseEntryRequest request,
    required bool Function() current,
    DateTime Function()? now,
  }) : _request = request,
       _current = current,
       _now = now ?? DateTime.now {
    _scope(scope);
    _text(connectionId);
  }
  final WorkspaceLedgerScope scope;
  final String connectionId;
  final WorkspacePurchaseEntryRequest _request;
  final bool Function() _current;
  final DateTime Function() _now;
  bool _retired = false;
  bool get current => !_retired && _current();
  void retire() {
    _retired = true;
  }

  Future<Object?> _call(
    String operation,
    Map<String, Object?> fields, {
    bool mutation = false,
  }) async {
    var dispatched = false;
    try {
      if (!current) throw const FormatException();
      final response = await _request(
        {
          'operation': operation,
          'schemaVersion': 1,
          'ledgerVersion': 1,
          'scope': _scopeJson(scope),
          ...fields,
        },
        () => current,
        mutation: mutation,
        onDispatch: () {
          dispatched = true;
        },
      );
      if (!current || response?.statusCode != 200)
        throw const FormatException();
      final envelope = _object(jsonDecode(response!.body));
      _keys(envelope, {'ok', 'data'});
      if (envelope['ok'] != true) throw const FormatException();
      return envelope['data'];
    } on Object {
      throw WorkspaceLedgerRequestFailure(
        mayHaveCommitted: mutation && dispatched,
      );
    }
  }

  Future<WorkspaceLedgerPage> readPage(
    String kind, {
    String? parentId,
    String? cursor,
  }) async {
    if (!_kinds.contains(kind) ||
        (kind == 'moneyEntry' ? parentId == null : parentId != null))
      throw const FormatException();
    final raw = await _call('readStoreLedgerSource', {
      'kind': kind,
      'parentId': parentId,
      'cursor': cursor,
    });
    return WorkspaceLedgerPage.decode(
      raw,
      scope,
      _now(),
      kind: kind,
      parentId: parentId,
      cursor: cursor,
    );
  }

  Future<WorkspaceLedgerCollection> readCollection(String kind, {String? parentId}) async {
    final rows = <WorkspaceLedgerRow>[], ids = <String>{}, cursors = <String>{};
    String? cursor; int? revision, total;
    do {
      final page = await readPage(kind, parentId: parentId, cursor: cursor);
      if (!current || total != null && (page.revision != revision || page.totalCount != total)) throw const FormatException();
      revision = page.revision; total = page.totalCount;
      for (final row in page.rows) {
        if (!ids.add(row.id)) throw const FormatException(); rows.add(row);
      }
      if (rows.length > total || page.nextCursor != null && !cursors.add(page.nextCursor!)) throw const FormatException();
      cursor = page.nextCursor;
    } while (cursor != null);
    if (!current || rows.length != total) throw const FormatException();
    return WorkspaceLedgerCollection._(revision, rows);
  }
  Future<WorkspaceOwnedLedgerSections> readOwnedSections() async {
    final supplierRows = await readCollection('supplierLedger'), expenseRows = await readCollection('expense'),
      registerRows = await readCollection('moneyRegister');
    final revision = supplierRows.revision;
    if (!current || expenseRows.revision != revision || registerRows.revision != revision) throw const FormatException();
    final suppliers = <String, WorkspaceSupplierLedger>{}, expenses = <String, WorkspaceExpenseRecord>{},
      registers = <String, WorkspaceMoneyRegisterSnapshot>{};
    for (final row in supplierRows.rows) {
      final value = WorkspaceSupplierLedger.fromJson(row.value);
      if (value == null) throw const FormatException(); suppliers[row.id] = value;
    }
    for (final row in expenseRows.rows) {
      final value = WorkspaceExpenseRecord.fromJson(row.value);
      if (value == null) throw const FormatException(); expenses[row.id] = value;
    }
    for (final row in registerRows.rows) {
      final header = row.value, entries = await readCollection('moneyEntry', parentId: row.id);
      if (entries.revision != revision || entries.rows.length != header['entryCount']) throw const FormatException();
      final ordered = [...entries.rows]..sort((a, b) => (a.data['ordinal']! as int).compareTo(b.data['ordinal']! as int));
      var validation = header['openingMinor'] == null ? 0 : header['openingMinor']! as int;
      for (var index = 0; index < ordered.length; index++) {
        final entry = ordered[index];
        if (entry.data['ordinal'] != index + 1) throw const FormatException();
        validation = _integer(validation + (entry.value['deltaMinor']! as int), minimum: -9007199254740991);
      }
      if (validation != header['sequenceValidationMinor'] ||
          (ordered.isEmpty ? null : ordered.last.value['occurredAt']) != header['lastEntryAt']) throw const FormatException();
      final native = Map<String, Object?>.from(header)..remove('entryCount')..remove('lastEntryAt')..remove('sequenceValidationMinor');
      native['entries'] = [for (final entry in ordered) entry.value];
      final value = WorkspaceMoneyRegisterSnapshot.fromJson(native);
      if (value == null) throw const FormatException(); registers[row.id] = value;
    }
    if (!current) throw const FormatException();
    return WorkspaceOwnedLedgerSections._(scope, revision, suppliers, expenses, registers);
  }
  Future<WorkspaceLedgerReadback> save(WorkspaceLedgerIntent original) async {
    if (original.scope != scope)
      throw const WorkspaceLedgerRequestFailure(mayHaveCommitted: false);
    final fields = {...original.toJson()}
      ..remove('scope')
      ..remove('operation');
    final raw = await _call(original.operation, fields, mutation: true);
    try {
      final result = WorkspaceLedgerReadback.decode(
        raw,
        scope,
        _now(),
        original,
      );
      if (result.attempt == null) throw const FormatException();
      return result;
    } on Object {
      throw const WorkspaceLedgerRequestFailure(mayHaveCommitted: true);
    }
  }

  Future<WorkspaceLedgerReadback> readAttempt(
    WorkspaceLedgerIntent original,
  ) async {
    if (original.scope != scope)
      throw const WorkspaceLedgerRequestFailure(mayHaveCommitted: false);
    final raw = await _call('readStoreLedgerAttempt', {
      'idempotencyKey': original.idempotencyKey,
      'fingerprint': original.fingerprint,
    });
    return WorkspaceLedgerReadback.decode(raw, scope, _now(), original);
  }
}

class WorkspaceLedgerResolution {
  WorkspaceLedgerResolution._(
    this.original,
    this.status,
    this.reason,
    this.resultRevision,
  );
  factory WorkspaceLedgerResolution.decode(
    Object? raw,
    WorkspaceLedgerScope scope,
  ) {
    final value = _object(raw);
    _keys(value, {'original', 'status', 'reason', 'resultRevision'});
    final original = WorkspaceLedgerIntent.fromJson(value['original'], scope),
        status = value['status'],
        reason = value['reason'];
    final revision = value['resultRevision'] == null
        ? null
        : _integer(value['resultRevision'], minimum: 1);
    if (status == 'saved') {
      if (reason != null || revision == null) throw const FormatException();
    } else if (status != 'not_saved' ||
        !_reasons(original.operation).contains(reason)) {
      throw const FormatException();
    }
    return WorkspaceLedgerResolution._(
      original,
      status! as String,
      reason as String?,
      revision,
    );
  }
  final WorkspaceLedgerIntent original;
  final String status;
  final String? reason;
  final int? resultRevision;
  Map<String, Object?> toJson() => {
    'original': original.toJson(),
    'status': status,
    'reason': reason,
    'resultRevision': resultRevision,
  };
}

typedef WorkspaceLedgerJournalState = ({
  WorkspaceLedgerIntent? pending,
  WorkspaceLedgerResolution? resolved,
});

abstract interface class WorkspaceLedgerJournal {
  Future<WorkspaceLedgerJournalState> read();
  Future<void> retain(WorkspaceLedgerIntent original);
  Future<void> resolve(
    WorkspaceLedgerIntent original,
    WorkspaceLedgerReadback readback,
  );
}

/// Only the pending command and terminal identity are retained. This encrypted
/// journal is not a ledger/balance cache, migration or local canonical writer.
/// Opening it does not admit existing local records to the remote source.
class SecureWorkspaceLedgerJournal implements WorkspaceLedgerJournal {
  SecureWorkspaceLedgerJournal({
    required this.scope,
    required this.connectionId,
    required bool Function() current,
    FlutterSecureStorage? storage,
  }) : _current = current,
       _storage = storage ?? const FlutterSecureStorage() {
    _scope(scope);
    _text(connectionId);
  }
  final WorkspaceLedgerScope scope;
  final String connectionId;
  final bool Function() _current;
  final FlutterSecureStorage _storage;
  static final _tails = <String, Future<void>>{};
  String get _key =>
      'moolsocial.workspace.ledger-original-attempt.v1.${workspaceLedgerFingerprint(_scopeJson(scope))}';
  void _check() {
    if (!_current())
      throw StateError(
        'Reopen the current Store before checking these records.',
      );
  }

  Future<T> _serial<T>(Future<T> Function() action) {
    final key = _key,
        result = (_tails[key] ?? Future<void>.value()).then((_) => action());
    final tail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _tails[key] = tail;
    unawaited(
      tail.then((_) {
        if (identical(_tails[key], tail)) _tails.remove(key);
      }),
    );
    return result;
  }

  Map<String, Object?> _decode(String raw) {
    final value = _object(jsonDecode(raw));
    _keys(value, {
      'schemaVersion',
      'scope',
      'connectionId',
      'pending',
      'lastResolved',
    });
    if (value['schemaVersion'] != 1 ||
        value['connectionId'] != connectionId ||
        workspaceLedgerCanonical(value['scope']) !=
            workspaceLedgerCanonical(_scopeJson(scope)))
      throw const FormatException();
    if (value['pending'] != null)
      WorkspaceLedgerIntent.fromJson(value['pending'], scope);
    if (value['lastResolved'] != null)
      WorkspaceLedgerResolution.decode(value['lastResolved'], scope);
    return value;
  }

  Future<Map<String, Object?>?> _read() async {
    _check();
    final raw = await _storage.read(key: _key);
    _check();
    return raw == null ? null : _decode(raw);
  }

  Future<void> _write(Map<String, Object?> value) async {
    _check();
    final raw = jsonEncode(value);
    try {
      await _storage.write(key: _key, value: raw);
    } on Object {
      _check();
      if (await _storage.read(key: _key) != raw) rethrow;
    }
    _check();
  }

  /// Invoke only after the original-source read and separate pristine-local
  /// adoption guard. This does not erase or adopt a pre-existing local ledger.
  Future<void> adoptConfirmedOriginal() => _serial(() async {
    final existing = await _read();
    if (existing != null) return;
    await _write({
      'schemaVersion': 1,
      'scope': _scopeJson(scope),
      'connectionId': connectionId,
      'pending': null,
      'lastResolved': null,
    });
  });
  /// Validate an existing connection without creating or retiring any binding.
  Future<void> validateRetainedConnection() => _serial(() async {await _read();});
  @override
  Future<WorkspaceLedgerJournalState> read() => _serial(() async {
    final value = await _read();
    if (value == null)
      throw StateError('Confirm the original Store records first.');
    return (
      pending: value['pending'] == null
          ? null
          : WorkspaceLedgerIntent.fromJson(value['pending'], scope),
      resolved: value['lastResolved'] == null
          ? null
          : WorkspaceLedgerResolution.decode(value['lastResolved'], scope),
    );
  });
  @override
  Future<void> retain(WorkspaceLedgerIntent original) => _serial(() async {
    if (original.scope != scope) throw const FormatException();
    final value = await _read();
    if (value == null)
      throw StateError('Confirm the original Store records first.');
    if (value['pending'] != null) {
      final pending = WorkspaceLedgerIntent.fromJson(value['pending'], scope);
      if (!_same(pending, original))
        throw StateError(
          'Check the pending Save before changing these entries.',
        );
      return;
    }
    if (value['lastResolved'] != null) {
      final prior = WorkspaceLedgerResolution.decode(
        value['lastResolved'],
        scope,
      );
      if (prior.original.idempotencyKey == original.idempotencyKey)
        throw StateError('This Save already has a recorded result.');
    }
    await _write({...value, 'pending': original.toJson()});
  });
  @override
  Future<void> resolve(
    WorkspaceLedgerIntent original,
    WorkspaceLedgerReadback readback,
  ) => _serial(() async {
    final value = await _read(), receipt = readback.attempt;
    if (value == null ||
        original.scope != scope ||
        receipt == null ||
        receipt['fingerprint'] != original.fingerprint ||
        receipt['idempotencyKey'] != original.idempotencyKey)
      throw const FormatException();
    final resolution = WorkspaceLedgerResolution.decode({
      'original': original.toJson(),
      'status': receipt['status'],
      'reason': receipt['reason'],
      'resultRevision': receipt['resultRevision'],
    }, scope);
    if (value['pending'] == null) {
      final prior = value['lastResolved'] == null
          ? null
          : WorkspaceLedgerResolution.decode(value['lastResolved'], scope);
      if (prior != null &&
          _same(prior.original, original) &&
          workspaceLedgerCanonical(prior.toJson()) ==
              workspaceLedgerCanonical(resolution.toJson()))
        return;
      throw StateError('Keep the current Save resolution.');
    }
    if (!_same(
      WorkspaceLedgerIntent.fromJson(value['pending'], scope),
      original,
    ))
      throw StateError('Keep the newer pending Save.');
    await _write({
      ...value,
      'pending': null,
      'lastResolved': resolution.toJson(),
    });
  });
}

bool _same(WorkspaceLedgerIntent a, WorkspaceLedgerIntent b) =>
    a.scope == b.scope &&
    a.idempotencyKey == b.idempotencyKey &&
    a.fingerprint == b.fingerprint;

/// Serial explicit native Save/retry and read-only recovery. The existing form
/// owns final confirmation. No operation ID is generated or replaced here.
class WorkspaceLedgerSaveController {
  WorkspaceLedgerSaveController({required this.source, required this.journal});
  final WorkspaceLedgerRemoteSource source;
  final WorkspaceLedgerJournal journal;
  WorkspaceLedgerIntent? _pending;
  WorkspaceLedgerResolution? _resolved;
  Future<WorkspaceLedgerReadback>? _saving;
  WorkspaceLedgerIntent? _savingOriginal;
  bool get busy => _saving != null;
  WorkspaceLedgerIntent? get pending => source.current ? _pending : null;
  WorkspaceLedgerResolution? get lastResolution =>
      source.current ? _resolved : null;
  void _check() {
    if (!source.current)
      throw StateError('Reopen the current Store before continuing.');
  }

  Future<void> _restore() async {
    _check();
    final state = await journal.read();
    _check();
    _pending = state.pending;
    _resolved = state.resolved;
  }
  Future<void> restoreState() => _restore();

  Future<WorkspaceLedgerReadback> _install(
    WorkspaceLedgerIntent original,
    WorkspaceLedgerReadback value,
  ) async {
    _check();
    if (value.attempt != null &&
        _pending != null &&
        _same(_pending!, original)) {
      await journal.resolve(original, value);
      await _restore();
    }
    return value;
  }

  Future<WorkspaceLedgerReadback> readRetainedAttempt(
    WorkspaceLedgerIntent original,
  ) async {
    if (busy) throw StateError('Wait for the current Save to finish.');
    await _restore();
    return _install(original, await source.readAttempt(original));
  }

  /// Both initial Save and an explicitly confirmed retry retain the same fully
  /// frozen intent. A resolved identity becomes a read, never another write.
  Future<WorkspaceLedgerReadback> save(WorkspaceLedgerIntent original) {
    if (_saving != null) {
      if (_same(_savingOriginal!, original)) return _saving!;
      throw StateError(
        'Wait for the current Save before changing these entries.',
      );
    }
    _savingOriginal = original;
    final result = _save(original);
    _saving = result;
    unawaited(
      result.then<void>(
        (_) {
          _saving = null;
          _savingOriginal = null;
        },
        onError: (Object _, StackTrace _) {
          _saving = null;
          _savingOriginal = null;
        },
      ),
    );
    return result;
  }

  Future<WorkspaceLedgerReadback> _save(WorkspaceLedgerIntent original) async {
    if (original.scope != source.scope) throw const FormatException();
    await _restore();
    if (_pending != null && !_same(_pending!, original))
      throw StateError('Check the pending Save before changing these entries.');
    if (_resolved?.original.idempotencyKey == original.idempotencyKey) {
      if (!_same(_resolved!.original, original))
        throw StateError('Keep the original recorded Save.');
      return source.readAttempt(original);
    }
    if (_pending != null) {
      final recovered = await source.readAttempt(original);
      _check();
      if (recovered.attempt != null) return _install(original, recovered);
    } else {
      await journal.retain(original);
      await _restore();
    }
    return _install(original, await source.save(original));
  }
}
