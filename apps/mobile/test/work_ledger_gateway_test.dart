import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:moolsocial/features/shared/social_content_gateway.dart';
import 'package:moolsocial/features/work/work_ledger_gateway.dart';
import 'package:moolsocial/features/work/work_models.dart' show WorkspacePurchaseEntryBook,
  WorkspaceLedgerFormKey, WorkspaceLedgerFormDraft, WorkspaceSupplierMoneyAttempt, WorkspaceSupplierBillAcceptance, WorkspaceSupplierLedger, WorkspaceSupplierEntryOrigin,
  WorkspaceSupplierMoneyAllocationIntent, WorkspaceSupplierBillMoneyAllocation, WorkspaceSupplierMoneySourceKind,
  WorkspaceSupplierRefundIntent, WorkspaceSupplierRefund, WorkspaceSupplierCreditDocumentInput,
  WorkspaceSupplierCreditIntent, WorkspaceSupplierCreditNote, WorkspaceSupplierCreditSupport, WorkspaceSupplierCreditSupportKind,
  WorkspaceSupplierLedgerEntry, WorkspaceSupplierEntryKind;
import 'package:moolsocial/features/work/work_purchase_entry_gateway.dart';
import 'package:moolsocial/features/work/work_services.dart' show SecureWorkLedgerCheckpointStore,
  SecureWorkLedgerFormDraftStore, WorkGatewayException, RemoteWorkOwnedLedgerStore;
import 'package:moolsocial/features/work/work_catalogue_gateway.dart' show AuthenticatedWorkspaceCatalogueGateway;
import 'work_catalogue_gateway_test.dart' show Credentials, Transport, AnalyticsHeldCredentials;

const scope = (
  account: 'HOST-ledger-account',
  store: 'HOST-ledger-store',
  realm: 'evaluation',
);
final now = DateTime.utc(2026, 10, 29, 2);
Map<String, Object?> expense() => {
  'account': scope.account,
  'store': scope.store,
  'operationId': 'HOST-expense-1',
  'amountMinor': 12505,
  'category': 'HOST delivery expense',
  'method': 'HOST manually recorded',
  'reference': 'HOST મૂળ ખર્ચ',
  'note': 'HOST original note; no provider confirmation',
  'occurredAt': '2026-10-29T01:00:00.123456Z',
};
WorkspaceLedgerIntent intent() => WorkspaceLedgerIntent.prepare(
  scope: scope,
  operation: 'recordStoreExpense',
  expectedRevision: null,
  idempotencyKey: 'HOST-expense-attempt',
  fields: {'expense': expense()},
);
Map<String, Object?> row() => {
  'kind': 'expense',
  'id': 'HOST-expense-1',
  'parentId': null,
  'revision': 1,
  'json': workspaceLedgerCanonical(expense()),
  'fingerprint': workspaceLedgerFingerprint(expense()),
  'ordinal': null,
};
Map<String, Object?> frame() => {
  'schemaVersion': 1,
  'ledgerVersion': 1,
  'actorAccountId': scope.account,
  'storeId': scope.store,
  'realm': scope.realm,
  'observedAt': now.toIso8601String(),
  'state': 'ready',
  'sourceRevision': 1,
};
Map<String, Object?> status({bool receipt = true}) => {
  ...frame(),
  'attempt': receipt
      ? {
          'schemaVersion': 1,
          'scope': {
            'account': scope.account,
            'store': scope.store,
            'realm': scope.realm,
          },
          'operation': 'recordStoreExpense',
          'idempotencyKey': intent().idempotencyKey,
          'fingerprint': intent().fingerprint,
          'inputFingerprint': workspaceLedgerFingerprint(expense()),
          'status': 'saved',
          'reason': null,
          'changed': true,
          'resultRevision': 1,
          'targetKind': 'expense',
          'targetId': 'HOST-expense-1',
          'entryId': null,
          'recordedAt': now.toIso8601String(),
        }
      : null,
  'current': receipt ? row() : null,
};
Map<String, Object?> page() => {
  ...frame(),
  'kind': 'expense',
  'parentId': null,
  'totalCount': 1,
  'startsSource': true,
  'rows': [row()],
  'nextCursor': null,
};
SocialContentResponse reply(Object? value) => SocialContentResponse(
  statusCode: 200,
  body: jsonEncode({'ok': true, 'data': value}),
);

// Host-only real HTTP byte transport. The validated production URL is mapped
// exclusively to this test's owned loopback server, never to the Internet.
class _LedgerHostHttpClient implements HttpClient {
  _LedgerHostHttpClient(this.delegate, this.destination);
  final HttpClient delegate;
  final Uri destination;
  @override Future<HttpClientRequest> postUrl(Uri url) {
    if (url.toString() != 'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace') {
      throw StateError('HOST unexpected network destination');
    }
    return delegate.postUrl(destination);
  }
  @override void close({bool force = false}) => delegate.close(force: force);
  @override dynamic noSuchMethod(Invocation invocation) => throw StateError('HOST unsupported HTTP surface');
}
class _LedgerHostHttpOverrides extends HttpOverrides {
  _LedgerHostHttpOverrides(this.destination);
  final Uri destination;
  final clients = <HttpClient>[];
  @override HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context); clients.add(client);
    return _LedgerHostHttpClient(client, destination);
  }
  void close() {for (final client in clients) {client.close(force: true);}}
}

void main() {
  const creditDocumentExport = String.fromEnvironment('AGG05_CREDIT_DOCUMENT_CAPTURE_PATH');
  const creditGoodsExport = String.fromEnvironment('AGG05_CREDIT_GOODS_CAPTURE_PATH');
  const creditHistoryExport = String.fromEnvironment('AGG05_CREDIT_HISTORY_CAPTURE_PATH');
  const creditFinancialExport = String.fromEnvironment('AGG05_CREDIT_FINANCIAL_CAPTURE_PATH');
  const creditCommandExport = String.fromEnvironment('AGG05_CREDIT_COMMAND_CAPTURE_PATH');
  for (final variant in ['plain', 'lot', 'restock', 'legacy-calendar']) {
    test('AGG05 backend credit goods source matches native ledger relationships $variant', () {
      final source = jsonDecode(File('$creditGoodsExport.$variant.json').readAsStringSync()) as Map<String, dynamic>;
      expect(source['label'], 'ISOLATED HOST GOODS SOURCE FORMAT; NO RUNTIME RECEIPT OR STOCK AUTHORITY');
      final decoded = WorkspaceSupplierLedger.fromJson(source['ledger']);
      expect(decoded, isNotNull); final ledger = decoded!;
      expect(ledger.valid, true); expect(ledger.goodsReceipts.length, source['receiptCount']);
      expect(ledger.billGoodsAllocations.length, source['linkCount']);
      final receipt = ledger.goodsReceipts.values.single, line = receipt.lines.single;
      expect(line.acceptedStockUnits, 1); expect(line.damagedMilli, 500);
      final bill = ledger.purchaseBills.values.single;
      final available = ledger.availableCreditSupports(bill.billId);
      expect(available.length, 1); expect(available.single.$1.kind, WorkspaceSupplierCreditSupportKind.arrivalDamage);
      expect(available.single.$1.quantityMilli, 500);
      expect(source['legacyCalendar'], variant == 'legacy-calendar');
      expect(ledger.creditNotes, isEmpty); expect(ledger.refunds, isEmpty);
      expect(ledger.entries.where((entry) => entry.kind == WorkspaceSupplierEntryKind.creditNote), isEmpty);
    }, skip: creditGoodsExport.isEmpty ? 'Requires explicit isolated backend goods-format export' : false);
  }

  test('AGG05 backend returned goods source matches native return relationships', () {
    final source = jsonDecode(File('$creditGoodsExport.returned.json').readAsStringSync()) as Map<String, dynamic>;
    expect(source['label'], 'ISOLATED HOST RETURN FORMAT; NO RUNTIME STOCK OR FINANCIAL AUTHORITY');
    final decoded = WorkspaceSupplierLedger.fromJson(source['ledger']);
    expect(decoded, isNotNull); final ledger = decoded!;
    expect(ledger.valid, true); expect(ledger.goodsReturns.length, source['returnCount']);
    final returned = ledger.goodsReturns.values.single, line = returned.lines.single;
    expect(line.acceptedMilli, 500); expect(line.damagedMilli, 500); expect(line.stockUnits, 1);
    expect(returned.receiptId, ledger.goodsReceipts.values.single.id);
    expect(source['legacyCalendar'], true);
    final supports = ledger.availableCreditSupports(ledger.purchaseBills.values.single.billId);
    expect(supports.map((value) => value.$1.kind).toSet(), {
      WorkspaceSupplierCreditSupportKind.goodsReturned, WorkspaceSupplierCreditSupportKind.arrivalDamage});
    expect(ledger.creditNotes, isEmpty); expect(ledger.refunds, isEmpty);
    expect(ledger.entries.where((entry) => entry.kind == WorkspaceSupplierEntryKind.creditNote), isEmpty);
  }, skip: creditGoodsExport.isEmpty ? 'Requires explicit isolated backend return-format export' : false);

  for (final kind in ['reviewed', 'legacy']) {
    test('AGG05 backend shortage source matches native original snapshot $kind', () {
      final source = jsonDecode(File('$creditGoodsExport.shortage-$kind.json').readAsStringSync()) as Map<String, dynamic>;
      expect(source['label'], 'ISOLATED HOST SHORTAGE FORMAT; NO RUNTIME GOODS OR FINANCIAL AUTHORITY');
      final decoded = WorkspaceSupplierLedger.fromJson(source['ledger']);
      expect(decoded, isNotNull); final ledger = decoded!;
      expect(ledger.valid, true); expect(ledger.shortageClaims.length, source['claimCount']);
      final claim = ledger.shortageClaims.values.single;
      expect(claim.quantityMilli, 500); expect(claim.outstandingMilli, 500); expect(claim.priorClaimedMilli, 0);
      expect(claim.receiptIds, [ledger.goodsReceipts.values.single.id]);
      expect(claim.billAllocationIds, [ledger.billGoodsAllocations.values.single.operationId]);
      expect(claim.requestedAt != null, kind == 'reviewed');
      final supports = ledger.availableCreditSupports(ledger.purchaseBills.values.single.billId);
      expect(supports.where((value) => value.$1.kind == WorkspaceSupplierCreditSupportKind.shortage).single.$1.quantityMilli, 500);
      expect(ledger.creditNotes, isEmpty); expect(ledger.refunds, isEmpty);
      expect(ledger.entries.where((entry) => entry.kind == WorkspaceSupplierEntryKind.creditNote), isEmpty);
    }, skip: creditGoodsExport.isEmpty ? 'Requires explicit isolated backend shortage-format export' : false);
  }

  for (final kind in ['goodsReturned', 'arrivalDamage', 'shortage']) {
    for (final treatment in ['gst', 'commercial']) {
      test('AGG05 backend typed credit history matches native source caps $kind $treatment', () {
        final source = jsonDecode(File('$creditHistoryExport.$kind-$treatment.json').readAsStringSync()) as Map<String, dynamic>;
        expect(source['label'], 'ISOLATED HOST CREDIT HISTORY FORMAT; NO ORIGINAL RECORDING OR TAX AUTHORITY');
        final decoded = WorkspaceSupplierLedger.fromJson(source['ledger']);
        expect(decoded, isNotNull); final ledger = decoded!;
        expect(ledger.valid, true); expect(ledger.creditNotes.length, source['creditCount']);
        final note = ledger.creditNotes.values.single;
        expect(note.documentInput!.treatment, treatment); expect(note.amountMinor, 100);
        expect(note.supports.single.kind.name, kind); expect(note.supports.single.quantityMilli, 500);
        expect(ledger.manualBillRemainingMinor(note.billId), 900);
        expect(ledger.availableCreditSupports(note.billId).where((value) => value.$1.kind.name == kind), isEmpty);
        expect(ledger.refunds, isEmpty);
      }, skip: creditHistoryExport.isEmpty ? 'Requires explicit isolated backend credit-history export' : false);
    }
  }

  test('AGG05 backend original bill surplus matches native typed financial prefix', () {
    final source = jsonDecode(File('$creditHistoryExport.surplus.json').readAsStringSync()) as Map<String, dynamic>;
    expect(source['label'], 'ISOLATED HOST BILL SURPLUS FORMAT; NO ORIGINAL FINANCIAL AUTHORITY');
    final decoded = WorkspaceSupplierLedger.fromJson(source['ledger']);
    expect(decoded, isNotNull); final ledger = decoded!;
    expect(ledger.valid, true);
    final billId = source['billId'] as String;
    expect(ledger.manualBillRemainingMinor(billId), -100);
    expect(ledger.unallocatedMoneyMinor(WorkspaceSupplierMoneySourceKind.manualBillSurplus, billId), source['amountMinor']);
    expect(source['amountMinor'], 100);
    expect(ledger.refunds, isEmpty); expect(ledger.billMoneyAllocations, isEmpty);
  }, skip: creditHistoryExport.isEmpty ? 'Requires explicit isolated backend bill-surplus export' : false);

  for (final state in ['base', 'refund', 'transfer']) {
    test('AGG05 shared backend credit financial history matches native remaining amounts $state', () {
      final source = jsonDecode(File('$creditFinancialExport.$state.json').readAsStringSync()) as Map<String, dynamic>;
      expect(source['label'], 'ISOLATED HOST FINANCIAL HISTORY FORMAT; NO ORIGINAL RECORDING AUTHORITY');
      final decoded = WorkspaceSupplierLedger.fromJson(source['ledger']);
      expect(decoded, isNotNull); final ledger = decoded!;
      expect(ledger.valid, true); expect(ledger.balanceMinor, source['balanceMinor']);
      final billId = source['sourceBillId'] as String;
      expect(ledger.manualBillRemainingMinor(billId), source['remainingMinor']);
      expect(ledger.unallocatedMoneyMinor(WorkspaceSupplierMoneySourceKind.manualBillSurplus, billId), source['availableMinor']);
      if (source.containsKey('targetBillId')) {
        expect(ledger.manualBillRemainingMinor(source['targetBillId'] as String), source['targetRemainingMinor']);
      }
      expect(ledger.creditNotes.length, 1);
    }, skip: creditFinancialExport.isEmpty ? 'Requires explicit isolated backend financial-history export' : false);
  }

  Map<String, dynamic> sdkCreditCapture(String suffix) => jsonDecode(File('$creditCommandExport.$suffix.json').readAsStringSync()) as Map<String, dynamic>;
  for (final kind in ['goodsReturned', 'arrivalDamage', 'shortage']) {
    for (final treatment in ['gst', 'commercial']) {
      test('AGG05 actual SDK credit command and saved proof decode in native gateway $kind $treatment', () {
        final source = sdkCreditCapture('$kind-$treatment');
        expect(source['label'], 'ISOLATED ACTUAL SDK CREDIT COMMAND; NO RUNTIME FINANCIAL AUTHORITY');
        final original = WorkspaceLedgerIntent.fromJson(source['command'], scope);
        expect(original.operation, 'recordStoreSupplierCreditNote'); expect(original.targetKind, 'supplierLedger');
        expect(original.entryId, (source['command']['intent'] as Map)['operationId']);
        final reply = WorkspaceLedgerReadback.decode(source['status'], scope, DateTime.parse(source['now'] as String), original);
        expect(reply.attempt!['status'], 'saved'); expect(reply.attempt!['changed'], true);
        final ledger = WorkspaceSupplierLedger.fromJson(reply.current!.value)!;
        expect(ledger.valid, true); expect(ledger.creditNotes.length, 1);
        final note = ledger.creditNotes.values.single;
        expect(note.documentInput!.treatment, treatment); expect(note.supports.single.kind.name, kind);
        expect(WorkspaceSupplierCreditIntent.fromJson(original.input).matches(note), true);
      }, skip: creditCommandExport.isEmpty ? 'Requires actual isolated SDK credit-command capture' : false);
    }
  }
  test('AGG05 actual SDK credit refusal retains exact original request and reason', () {
    final source = sdkCreditCapture('refused-copy-revision');
    final original = WorkspaceLedgerIntent.fromJson(source['command'], scope);
    final reply = WorkspaceLedgerReadback.decode(source['status'], scope, DateTime.parse(source['now'] as String), original);
    expect(reply.attempt!['status'], 'not_saved'); expect(reply.attempt!['changed'], false);
    expect(reply.attempt!['reason'], 'credit_source_changed');
    expect(WorkspaceSupplierLedger.fromJson(reply.current!.value)!.creditNotes, isEmpty);
  }, skip: creditCommandExport.isEmpty ? 'Requires actual isolated SDK credit-command capture' : false);
  test('AGG05 actual SDK credit uses private original transport and read-only status', () async {
    final capture = sdkCreditCapture('arrivalDamage-commercial'), original = WorkspaceLedgerIntent.fromJson(capture['command'], scope);
    final publicTransport = Transport(Map<String, dynamic>.from(capture['status'] as Map));
    final privateTransport = Transport(Map<String, dynamic>.from(capture['status'] as Map)), credentials = Credentials();
    final gateway = AuthenticatedWorkspaceCatalogueGateway(
      endpoint: Uri.parse('https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'), realm: scope.realm,
      credentials: credentials, transport: publicTransport, privateOriginalTransport: privateTransport, ledgerSourceSupported: true,
      now: () => DateTime.parse(capture['now'] as String));
    final source = gateway.originalLedgerSource(accountId: scope.account, storeId: scope.store, current: () => true)!;
    final saved = await source.save(original);
    expect(saved.attempt!['status'], 'saved'); expect(privateTransport.sent!['operation'], 'recordStoreSupplierCreditNote');
    expect(privateTransport.sent!['intent'], original.input); expect(publicTransport.sent, isNull);
    expect((await source.readAttempt(original)).attempt, saved.attempt);
    expect(privateTransport.sent!['operation'], 'readStoreLedgerAttempt'); expect(publicTransport.sent, isNull);
    expect(credentials.modes, [SocialAppCheckTokenMode.limitedUse, SocialAppCheckTokenMode.standard]);
  }, skip: creditCommandExport.isEmpty ? 'Requires actual isolated SDK credit-command capture' : false);
  for (final change in ['reason', 'document reason', 'quantity']) {
    test('AGG05 native original credit recovery rejects changed valid proof $change', () {
      final source = sdkCreditCapture('arrivalDamage-commercial');
      final original = WorkspaceLedgerIntent.fromJson(source['command'], scope);
      final status = jsonDecode(jsonEncode(source['status'])) as Map<String, dynamic>;
      final current = status['current'] as Map<String, dynamic>;
      final ledger = jsonDecode(current['json'] as String) as Map<String, dynamic>;
      final proof = (ledger['creditNotes'] as Map).values.single as Map;
      if (change == 'reason') proof['reason'] = 'HOST changed printed reason';
      if (change == 'document reason') (proof['documentInput'] as Map)['reasonCode'] = 'other';
      if (change == 'quantity') (proof['supports'] as List).single['quantityMilli'] = 499;
      expect(WorkspaceSupplierLedger.fromJson(ledger)!.valid, true);
      current['json'] = workspaceLedgerCanonical(ledger); current['fingerprint'] = workspaceLedgerFingerprint(ledger);
      expect(() => WorkspaceLedgerReadback.decode(status, scope, DateTime.parse(source['now'] as String), original), throwsFormatException);
    }, skip: creditCommandExport.isEmpty ? 'Requires actual isolated SDK credit-command capture' : false);
  }
  for (final change in ['offset', 'missing book revision', 'missing document', 'extra field']) {
    test('AGG05 native original credit command rejects unsupported shape $change', () {
      final source = sdkCreditCapture('arrivalDamage-commercial');
      final command = jsonDecode(jsonEncode(source['command'])) as Map<String, dynamic>;
      command.remove('fingerprint');
      if (change == 'offset') command['confirmedUtcOffsetMinutes'] = 841;
      if (change == 'missing book revision') command.remove('expectedPurchaseRevision');
      if (change == 'missing document') (command['intent'] as Map).remove('documentInput');
      if (change == 'extra field') command['bankVerified'] = true;
      command['fingerprint'] = workspaceLedgerFingerprint(command);
      expect(() => WorkspaceLedgerIntent.fromJson(command, scope), throwsFormatException);
    }, skip: creditCommandExport.isEmpty ? 'Requires actual isolated SDK credit-command capture' : false);
  }

  WorkspaceSupplierCreditIntent creditDocumentRequest(WorkspaceSupplierCreditDocumentInput? document) =>
    WorkspaceSupplierCreditIntent(operationId: 'HOST-document-request', accountScope: 'HOST-document-account',
      workspaceId: 'HOST-document-store', supplierId: 'HOST-document-supplier', billId: 'HOST-document-bill',
      copyId: 'HOST-document-copy', copyRevision: 1, openingId: 'HOST-document-opening', openingRevision: 1,
      reference: 'HOST-CN-1', occurredOn: '2026-10-29', reason: 'HOST supplied credit reason', amountMinor: 11800,
      requestedAt: DateTime.utc(2026, 10, 29, 8), documentInput: document,
      supports: const [WorkspaceSupplierCreditSupport(kind: WorkspaceSupplierCreditSupportKind.arrivalDamage,
        receiptId: 'HOST-receipt', receiptLineId: 'HOST-line', billLineIndex: 0, quantityMilli: 1000)]);
  const creditDocumentKey = (account: 'HOST-document-account', store: 'HOST-document-store',
    customer: 'HOST-document-supplier', invoice: 'HOST-document-bill', order: 'credit-copy:HOST-document-copy',
    kind: 'supplierCredit', ledgerRevision: 1);
  Map<String, String> creditDocumentFields(WorkspaceSupplierCreditIntent intent) => {
    'amount': '118.00', 'reference': intent.reference, 'reason': intent.reason, 'occurredOn': intent.occurredOn,
    'supports': jsonEncode(intent.supports.map((value) => value.toJson()).toList()),
    'attempt': jsonEncode(intent.toJson()),
    if (intent.documentInput != null) 'documentInput': jsonEncode(intent.documentInput!.toJson()),
  };
  Future<({SecureWorkLedgerFormDraftStore store, WorkspaceLedgerFormDraft draft,
      WorkspaceSupplierCreditIntent intent, WorkspaceLedgerIntent original, List<String> accounts})> sdkCreditStorageFixture(
      [String suffix = 'arrivalDamage-commercial']) async {
    final source = sdkCreditCapture(suffix), original = WorkspaceLedgerIntent.fromJson(source['command'], scope);
    final intent = WorkspaceSupplierCreditIntent.fromJson(original.input);
    final key = (account: intent.accountScope, store: intent.workspaceId, customer: intent.supplierId,
      invoice: intent.billId, order: 'credit-copy:${intent.copyId}', kind: 'supplierCredit', ledgerRevision: intent.copyRevision);
    final accounts = [scope.account], store = SecureWorkLedgerFormDraftStore(accountScope: () => accounts.single);
    final draft = WorkspaceLedgerFormDraft(key: key, revision: 1, fields: {...creditDocumentFields(intent), 'amount': '1.00'});
    expect(draft.valid, true); await store.save(draft, expectedRevision: null);
    return (store: store, draft: draft, intent: intent, original: original, accounts: accounts);
  }
  test('AGG05 encrypted original credit retains SDK request across reopen without changing document', () async {
    final f = await sdkCreditStorageFixture();
    expect(await f.store.readOriginalSupplierCreditAttempt(f.draft.key, f.intent, scope: scope, connectionId: 'HOST-credit-connection'), isNull);
    await f.store.retainOriginalSupplierCreditAttempt(f.draft.key, f.intent, f.original, scope: scope, connectionId: 'HOST-credit-connection');
    final reopened = SecureWorkLedgerFormDraftStore(accountScope: () => scope.account);
    final original = await reopened.readOriginalSupplierCreditAttempt(f.draft.key, f.intent, scope: scope, connectionId: 'HOST-credit-connection');
    expect(original!.toJson(), f.original.toJson());
    expect((await reopened.read(f.draft.key))!.supplierCreditIntent!.documentInput!.sameAs(f.intent.documentInput!), true);
  }, skip: creditCommandExport.isEmpty ? 'Requires actual isolated SDK credit-command capture' : false);
  test('AGG05 encrypted original credit cannot replace retained request identity', () async {
    final f = await sdkCreditStorageFixture();
    await f.store.retainOriginalSupplierCreditAttempt(f.draft.key, f.intent, f.original, scope: scope, connectionId: 'HOST-credit-connection');
    final before = await const FlutterSecureStorage().readAll();
    final input = f.original.toJson()..remove('fingerprint')..['expectedRevision'] = 6;
    input['idempotencyKey'] = 'HOST-changed-credit-identity';
    final changed = WorkspaceLedgerIntent.fromJson({...input, 'fingerprint': workspaceLedgerFingerprint(input)}, scope);
    await expectLater(f.store.retainOriginalSupplierCreditAttempt(f.draft.key, f.intent, changed,
      scope: scope, connectionId: 'HOST-credit-connection'), throwsA(isA<WorkGatewayException>()));
    expect(await const FlutterSecureStorage().readAll(), before);
  }, skip: creditCommandExport.isEmpty ? 'Requires actual isolated SDK credit-command capture' : false);
  for (final context in ['account', 'Store', 'connection']) {
    test('AGG05 encrypted original credit refuses changed context $context', () async {
      final f = await sdkCreditStorageFixture();
      await f.store.retainOriginalSupplierCreditAttempt(f.draft.key, f.intent, f.original, scope: scope, connectionId: 'HOST-credit-connection');
      final before = await const FlutterSecureStorage().readAll();
      if (context == 'account') f.accounts[0] = 'HOST-other-account';
      final requested = context == 'Store' ? (account: scope.account, store: 'HOST-other-store', realm: scope.realm) : scope;
      await expectLater(f.store.readOriginalSupplierCreditAttempt(f.draft.key, f.intent, scope: requested,
        connectionId: context == 'connection' ? 'HOST-other-connection' : 'HOST-credit-connection'), throwsA(isA<WorkGatewayException>()));
      expect(await const FlutterSecureStorage().readAll(), before);
    }, skip: creditCommandExport.isEmpty ? 'Requires actual isolated SDK credit-command capture' : false);
  }
  for (final damage in ['schema', 'original fingerprint', 'frozen document']) {
    test('AGG05 encrypted original credit refuses damaged retained identity $damage', () async {
      final f = await sdkCreditStorageFixture();
      await f.store.retainOriginalSupplierCreditAttempt(f.draft.key, f.intent, f.original, scope: scope, connectionId: 'HOST-credit-connection');
      final storage = const FlutterSecureStorage(), values = await storage.readAll();
      final key = values.keys.singleWhere((key) => key.contains('.original-request.'));
      final sidecar = jsonDecode(values[key]!) as Map<String, dynamic>;
      if (damage == 'schema') sidecar['schemaVersion'] = 2;
      if (damage == 'original fingerprint') (sidecar['original'] as Map)['fingerprint'] = List.filled(64, 'a').join();
      if (damage == 'frozen document') ((sidecar['frozenDraft'] as Map)['fields'] as Map).remove('documentInput');
      await storage.write(key: key, value: jsonEncode(sidecar)); final before = await storage.readAll();
      await expectLater(f.store.readOriginalSupplierCreditAttempt(f.draft.key, f.intent,
        scope: scope, connectionId: 'HOST-credit-connection'), throwsA(isA<WorkGatewayException>()));
      expect(await storage.readAll(), before);
    }, skip: creditCommandExport.isEmpty ? 'Requires actual isolated SDK credit-command capture' : false);
  }
  test('AGG05 encrypted original credit reset requires exact SDK not-saved proof', () async {
    final f = await sdkCreditStorageFixture('refused-copy-revision');
    await f.store.retainOriginalSupplierCreditAttempt(f.draft.key, f.intent, f.original, scope: scope, connectionId: 'HOST-credit-connection');
    final next = WorkspaceLedgerFormDraft(key: f.draft.key, revision: 2, fields: {...f.draft.fields}..remove('attempt'));
    final before = await const FlutterSecureStorage().readAll();
    await expectLater(f.store.resetRefusedSupplierCreditDraft(next, expectedRevision: 1,
      scope: scope, connectionId: 'HOST-credit-connection', verifyNotRecorded: (_, _) async => false), throwsA(isA<WorkGatewayException>()));
    expect(await const FlutterSecureStorage().readAll(), before);
    var checks = 0;
    await f.store.resetRefusedSupplierCreditDraft(next, expectedRevision: 1, scope: scope, connectionId: 'HOST-credit-connection',
      verifyNotRecorded: (intent, original) async {
        checks++; expect(original.toJson(), f.original.toJson());
        expect(workspaceLedgerFingerprint(intent.toJson()), workspaceLedgerFingerprint(original.input));
        final source = sdkCreditCapture('refused-copy-revision');
        final readback = WorkspaceLedgerReadback.decode(source['status'], scope, DateTime.parse(source['now'] as String), original);
        return readback.attempt?['status'] == 'not_saved';
      });
    expect(checks, 1); final saved = await f.store.read(next.key);
    expect(saved!.supplierCreditIntent, isNull); expect(saved.fields, next.fields);
    expect(saved.supplierCreditDocumentInput!.sameAs(f.intent.documentInput!), true);
  }, skip: creditCommandExport.isEmpty ? 'Requires actual isolated SDK credit-command capture' : false);
  for (final change in ['document', 'amount', 'reference']) {
    test('AGG05 encrypted original credit refused reset cannot change frozen inputs $change', () async {
      final f = await sdkCreditStorageFixture('refused-copy-revision');
      await f.store.retainOriginalSupplierCreditAttempt(f.draft.key, f.intent, f.original, scope: scope, connectionId: 'HOST-credit-connection');
      final fields = {...f.draft.fields}..remove('attempt');
      if (change == 'document') fields['documentInput'] = jsonEncode({...f.intent.documentInput!.toJson(), 'reasonCode': 'other'});
      if (change == 'amount') fields['amount'] = '2.00';
      if (change == 'reference') fields['reference'] = 'HOST-other-note';
      final next = WorkspaceLedgerFormDraft(key: f.draft.key, revision: 2, fields: fields), before = await const FlutterSecureStorage().readAll();
      var checks = 0;
      await expectLater(f.store.resetRefusedSupplierCreditDraft(next, expectedRevision: 1, scope: scope,
        connectionId: 'HOST-credit-connection', verifyNotRecorded: (_, _) async {checks++; return true;}), throwsA(isA<WorkGatewayException>()));
      expect(checks, 0); expect(await const FlutterSecureStorage().readAll(), before);
    }, skip: creditCommandExport.isEmpty ? 'Requires actual isolated SDK credit-command capture' : false);
  }
  const creditRequestExport = String.fromEnvironment('AGG05_CREDIT_INTENT_CAPTURE_PATH');
  for (final kind in ['goodsReturned', 'arrivalDamage', 'shortage']) for (final treatment in ['gst', 'commercial']) {
    test('AGG05 backend structured credit request matches native proof $kind $treatment', () {
      final source = jsonDecode(File('$creditRequestExport.$kind.$treatment.json').readAsStringSync()) as Map<String, dynamic>;
      expect(source['label'], 'ISOLATED HOST STRUCTURED CREDIT FORMAT; NO ORIGINAL SOURCE OR FINANCIAL AUTHORITY');
      final input = Map<String, Object?>.from(source['intent'] as Map), result = Map<String, Object?>.from(source['proof'] as Map);
      final intent = WorkspaceSupplierCreditIntent.fromJson(input), proof = WorkspaceSupplierCreditNote.fromJson(result);
      expect(intent.valid, true); expect(proof.valid, true); expect(intent.matches(proof), true);
      expect(intent.toJson(), input); expect(proof.toJson(), result);
      expect(proof.documentInput!.treatment, treatment); expect(proof.supports.single.kind.name, kind);
      final entry = WorkspaceSupplierLedgerEntry(operationId: proof.operationId, reference: proof.reference,
        origin: WorkspaceSupplierEntryOrigin.manualPurchase, purchaseId: proof.copyId, billId: proof.billId,
        kind: WorkspaceSupplierEntryKind.creditNote, amountMinor: proof.amountMinor, postedAt: proof.recordedAt);
      expect(entry.valid, true); expect(entry.toJson(), source['entry']); expect(entry.payableDeltaMinor, -proof.amountMinor);
      final key = (account: intent.accountScope, store: intent.workspaceId, customer: intent.supplierId,
        invoice: intent.billId, order: 'credit-copy:${intent.copyId}', kind: 'supplierCredit', ledgerRevision: intent.copyRevision);
      expect(WorkspaceLedgerFormDraft(key: key, revision: 1, fields: creditDocumentFields(intent)).valid, true);
      final lostDocument = {...result}..remove('documentInput');
      expect(intent.matches(WorkspaceSupplierCreditNote.fromJson(lostDocument)), false,
        reason: 'Legacy decode support must never confirm a new request whose document was discarded.');
    }, skip: creditRequestExport.isEmpty ? 'Requires explicit isolated backend structured credit export' : false);
  }

  WorkspaceSupplierCreditDocumentInput exportedCreditDocument(int index) {
    final source = jsonDecode(File(creditDocumentExport).readAsStringSync()) as Map<String, dynamic>;
    return WorkspaceSupplierCreditDocumentInput.fromJson(((source['cases'] as List)[index] as Map)['output']);
  }
  for (var index = 0; index < 9; index++) {
    test('AGG05 structured credit request preserves document in proof and raw freeze $index', () {
      final document = exportedCreditDocument(index), intent = creditDocumentRequest(document);
      expect(intent.valid, true);
      final restored = WorkspaceSupplierCreditIntent.fromJson(jsonDecode(jsonEncode(intent.toJson())));
      expect(restored.documentInput!.sameAs(document), true);
      final proof = intent.commit(revision: 2, at: intent.requestedAt.add(const Duration(seconds: 1)));
      final original = WorkspaceSupplierCreditNote.fromJson(jsonDecode(workspaceLedgerCanonical(proof.toJson())));
      expect(intent.matches(original), true, reason: 'Backend key ordering must not retire an identical printed document.');
      expect(original.documentInput!.sameAs(document), true);
      final fields = creditDocumentFields(intent);
      expect(WorkspaceLedgerFormDraft(key: creditDocumentKey, revision: 1, fields: fields).valid, true);
      final missing = {...fields}..remove('documentInput');
      expect(WorkspaceLedgerFormDraft(key: creditDocumentKey, revision: 1, fields: missing).valid, false);
      final changed = WorkspaceSupplierCreditDocumentInput(treatment: document.treatment,
        reasonCode: document.reasonCode == 'other' ? 'return' : 'other', taxRows: document.taxRows,
        particulars: document.particulars);
      expect(WorkspaceLedgerFormDraft(key: creditDocumentKey, revision: 1,
        fields: {...fields, 'documentInput': jsonEncode(changed.toJson())}).valid, false);
      final tampered = WorkspaceSupplierCreditNote.fromJson({...proof.toJson(), 'documentInput': changed.toJson()});
      expect(intent.matches(tampered), false);
    }, skip: creditDocumentExport.isEmpty ? 'Requires explicit isolated document format export' : false);
  }
  test('AGG05 legacy credit request stays unclassified with unchanged serialized fields', () {
    final legacy = creditDocumentRequest(null), input = legacy.toJson();
    expect(input.containsKey('documentInput'), false);
    final restored = WorkspaceSupplierCreditIntent.fromJson(jsonDecode(jsonEncode(input)));
    expect(restored.documentInput, isNull); expect(restored.toJson(), input);
    final proof = legacy.commit(revision: 2, at: legacy.requestedAt.add(const Duration(seconds: 1)));
    expect(proof.toJson().containsKey('documentInput'), false); expect(legacy.matches(proof), true);
    expect(WorkspaceLedgerFormDraft(key: creditDocumentKey, revision: 1, fields: creditDocumentFields(legacy)).valid, true);
  });
  for (final variant in ['exact', 'drop', 'change', 'raw missing', 'raw mismatch']) {
    test('AGG05 encrypted credit freeze preserves original document: $variant', () async {
      final document = exportedCreditDocument(1), intent = creditDocumentRequest(document);
      final store = SecureWorkLedgerFormDraftStore(accountScope: () => creditDocumentKey.account);
      final input = creditDocumentFields(intent)..remove('attempt');
      final draft = WorkspaceLedgerFormDraft(key: creditDocumentKey, revision: 1, fields: input);
      expect(draft.valid, true); await store.save(draft, expectedRevision: null);
      final storage = const FlutterSecureStorage(), before = await storage.readAll();
      final changed = WorkspaceSupplierCreditDocumentInput(treatment: 'commercial', reasonCode: 'discount',
        taxRows: document.taxRows, particulars: document.particulars);
      final attempt = variant == 'drop' ? creditDocumentRequest(null)
        : variant == 'change' ? creditDocumentRequest(changed) : intent;
      final fields = creditDocumentFields(attempt);
      if (variant == 'raw missing') fields.remove('documentInput');
      if (variant == 'raw mismatch') fields['documentInput'] = jsonEncode(changed.toJson());
      final frozen = WorkspaceLedgerFormDraft(key: creditDocumentKey, revision: 2, fields: fields);
      if (variant == 'exact') {
        await store.save(frozen, expectedRevision: 1);
        final reopened = await SecureWorkLedgerFormDraftStore(accountScope: () => creditDocumentKey.account).read(creditDocumentKey);
        expect(reopened!.supplierCreditIntent!.documentInput!.sameAs(document), true);
        expect(reopened.supplierCreditDocumentInput!.sameAs(document), true);
        var dispatched = 0;
        expect(await store.withFrozenSupplierCredit(creditDocumentKey, jsonEncode(intent.toJson()), () async {dispatched++; return true;}), true);
        expect(dispatched, 1);
        await expectLater(store.withFrozenSupplierCredit(creditDocumentKey,
          jsonEncode(creditDocumentRequest(changed).toJson()), () async {dispatched++; return true;}), throwsA(isA<WorkGatewayException>()));
        expect(dispatched, 1);
      } else {
        await expectLater(store.save(frozen, expectedRevision: 1), throwsA(isA<WorkGatewayException>()));
        expect(await storage.readAll(), before); expect((await store.read(creditDocumentKey))!.fields, input);
      }
    }, skip: creditDocumentExport.isEmpty ? 'Requires explicit isolated document format export' : false);
  }

  for (var index = 0; index < 9; index++) {
    test('AGG05 original credit document codec matches existing native fields $index', () {
      final exported = jsonDecode(File(creditDocumentExport).readAsStringSync()) as Map<String, dynamic>;
      expect(exported['label'], 'ISOLATED HOST DOCUMENT FORMAT; NO TAX AUTHORITY OR FINANCIAL EFFECT');
      final sample = (exported['cases'] as List)[index] as Map<String, dynamic>;
      final input = Map<String, Object?>.from(sample['input'] as Map);
      final document = WorkspaceSupplierCreditDocumentInput.fromJson(sample['output']);
      expect(document.valid, true); expect(document.treatment, input['treatment']);
      expect(document.reasonCode, input['reasonCode']); expect(document.taxRows, input['taxRows']);
      expect(document.particulars, input['particulars'] ?? const {});
      expect(document.printedTotalMinor, sample['printedTotal']);
      // Existing native version encoding omits an empty particulars map;
      // every entered field and printed row is preserved through that encoding.
      final canonical = {...input};
      if (document.particulars.isEmpty) {canonical['version'] = 1; canonical.remove('particulars');}
      expect(document.toJson(), canonical);
      expect(() => document.particulars['supplierName'] = 'HOST mutation', throwsUnsupportedError);
      if (document.taxRows.isNotEmpty) expect(() => document.taxRows.first['rate'] = 'HOST mutation', throwsUnsupportedError);
    }, skip: creditDocumentExport.isEmpty ? 'Requires explicit isolated backend document format export' : false);
  }

  test('AGG04 authenticated ledger factory is opt-in and preserves original scope through owner clones', () async {
    final transport = Transport(Map<String, dynamic>.from(page())), credentials = Credentials();
    AuthenticatedWorkspaceCatalogueGateway gateway({bool enabled = false}) => AuthenticatedWorkspaceCatalogueGateway(
      endpoint: Uri.parse('https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
      realm: scope.realm, credentials: credentials, transport: transport, ledgerSourceSupported: enabled, now: () => now);
    expect(gateway().originalLedgerSource(accountId: scope.account, storeId: scope.store, current: () => true), null);
    expect(transport.sent, null); expect(credentials.modes, isEmpty);
    final owner = gateway(enabled: true).forOwnerAccount(scope.account);
    expect(owner.ledgerSourceSupported, true);
    final source = owner.originalLedgerSource(accountId: scope.account, storeId: scope.store, current: () => true)!;
    expect(source.scope, scope); expect((await source.readPage('expense')).rows.single.value, expense());
    expect(transport.sent!['operation'], 'readStoreLedgerSource'); expect(transport.sent!['scope'], {
      'account': scope.account, 'store': scope.store, 'realm': scope.realm});
    transport.data = Map<String, dynamic>.from(status());
    expect((await source.save(intent())).attempt!['status'], 'saved');
    expect(transport.sent!['operation'], 'recordStoreExpense');
    expect((await source.readAttempt(intent())).attempt!['status'], 'saved');
    expect(transport.sent!['operation'], 'readStoreLedgerAttempt');
    expect(credentials.modes, [SocialAppCheckTokenMode.standard, SocialAppCheckTokenMode.limitedUse, SocialAppCheckTokenMode.standard]);
    final other = owner.originalLedgerSource(accountId: scope.account, storeId: 'HOST-other-store', current: () => true)!;
    expect(other.connectionId, isNot(source.connectionId));
    source.retire(); expect(source.current, false);
    final before = transport.sent;
    await expectLater(source.readPage('expense'), throwsA(isA<WorkspaceLedgerRequestFailure>()));
    expect(identical(transport.sent, before), true);
  });
  test('AGG04 authenticated ledger request never dispatches after account lifetime expires during credentials', () async {
    final release = Completer<void>(), credentials = AnalyticsHeldCredentials(release.future, after: 0);
    final transport = Transport(Map<String, dynamic>.from(page())); var live = true;
    final gateway = AuthenticatedWorkspaceCatalogueGateway(
      endpoint: Uri.parse('https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
      realm: scope.realm, credentials: credentials, transport: transport, ledgerSourceSupported: true, now: () => now);
    final source = gateway.originalLedgerSource(accountId: scope.account, storeId: scope.store, current: () => live)!;
    final read = source.readPage('expense');
    await Future<void>.delayed(Duration.zero); live = false; release.complete();
    await expectLater(read, throwsA(isA<WorkspaceLedgerRequestFailure>()));
    expect(transport.sent, null); expect(credentials.modes, isEmpty);
    expect(gateway.originalLedgerSource(accountId: scope.account, storeId: scope.store, current: () => false), null);
  });
  test('AGG04 actual HTTP original gateway carries large native evidence and keeps the public response bound', () async {
    final base = Platform.environment['AGG04_NATIVE_CAPTURE_PATH']; expect(base, isNotNull);
    final capture = jsonDecode(File('$base.large.json').readAsStringSync()) as Map<String, dynamic>;
    final savedFrame = Map<String, Object?>.from(capture['response'] as Map), readFrame = {...savedFrame, 'attempt': null};
    expect(utf8.encode(jsonEncode({'ok': true, 'data': readFrame})).length, greaterThan(2 * 1024 * 1024));
    final command = WorkspaceSupplierOpeningSaveIntent.fromJson({'schemaVersion': 1, 'operation': 'saveSupplierOpeningEvidence',
      ...Map<String, Object?>.from(capture['command'] as Map)}, scope);
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0), failures = <Object>[];
    final overrides = _LedgerHostHttpOverrides(Uri.parse('http://127.0.0.1:${server.port}/HOST-original'));
    var redirects = 0, redirectMode = false, largeInput = 0;
    final subscription = server.listen((request) async {
      String? operation;
      try {
        final raw = await utf8.decoder.bind(request).join(), body = jsonDecode(raw) as Map<String, dynamic>;
        operation = body['operation'] as String?;
        if (operation == 'HOST-public-limit-probe') {
          request.response.headers.contentType = ContentType.json;
          request.response.write(jsonEncode({'label': 'HOST response capacity probe', 'padding': 'x' * (3 * 1024 * 1024)}));
          await request.response.close(); return;
        }
        if (request.uri.path == '/HOST-redirect-target') redirects++;
        expect(request.headers.value('authorization'), 'Bearer isolated-host-token');
        expect(request.headers.value('x-firebase-appcheck'), 'isolated-host-appcheck');
        expect(body['actorAccountId'], scope.account); expect(body['storeId'], scope.store); expect(body['realm'], scope.realm);
        if (redirectMode && request.uri.path == '/HOST-original') {
          request.response.statusCode = HttpStatus.found; request.response.headers.set(HttpHeaders.locationHeader, '/HOST-redirect-target');
          await request.response.close(); return;
        }
        if (operation == 'saveStoreSupplierOpeningEvidence') {
          largeInput = utf8.encode(raw).length; expect(largeInput, greaterThan(64 * 1024));
          expect(body['fingerprint'], command.fingerprint); expect(body['opening'], command.opening.toJson());
        } else {expect(operation, 'readStorePurchaseEntryBook');}
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'ok': true, 'data': operation == 'saveStoreSupplierOpeningEvidence' ? savedFrame : readFrame}));
        await request.response.close();
      } catch (error) {
        if (operation != 'HOST-public-limit-probe') failures.add(error);
        try {await request.response.close();} on Object {/* Preserve the original test failure. */}
      }
    });
    try {
      await HttpOverrides.runWithHttpOverrides(() async {
        final ordinary = IoSocialContentTransport(), credentials = Credentials();
        final gateway = AuthenticatedWorkspaceCatalogueGateway(
          endpoint: Uri.parse('https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
          credentials: credentials, transport: ordinary, realm: 'evaluation', purchaseEntrySupported: true,
          purchaseOpeningEvidenceSupported: true, now: () => DateTime.parse(capture['now'] as String));
        final source = gateway.originalPurchaseEntrySource(accountId: scope.account, storeId: scope.store, current: () => true)!;
        expect((await source.readBook()).book!.copies.length, 1000);
        final saved = await source.saveOpeningEvidence(command); expect(saved.receipt!.saved, true); expect(saved.receipt!.changed, false);
        expect(largeInput, greaterThan(64 * 1024));
        expect(credentials.modes, [SocialAppCheckTokenMode.standard, SocialAppCheckTokenMode.limitedUse]);
        await expectLater(ordinary.postJson(gateway.endpoint, headers: const {}, body: const {'operation': 'HOST-public-limit-probe'}),
          throwsA(isA<SocialContentGatewayException>().having((error) => error.code, 'unchanged public bound', 'response_too_large')));
        redirectMode = true;
        await expectLater(source.readBook(), throwsA(isA<WorkspacePurchaseEntryRequestFailure>()));
        expect(redirects, 0); expect(failures, isEmpty);
      }, overrides);
    } finally {overrides.close(); await subscription.cancel(); await server.close(force: true);}
  });
  test('AGG04 native model accepts the actual multipart original and complete supplier evidence', () {
    final base = Platform.environment['AGG04_NATIVE_CAPTURE_PATH']; expect(base, isNotNull);
    final capture = jsonDecode(File('$base.large.json').readAsStringSync()) as Map<String, dynamic>;
    expect(capture['label'], startsWith('ISOLATED ACTUAL SDK LARGE ORIGINAL'));
    final original = WorkspacePurchaseEntryBook.fromJson(jsonDecode((capture['response'] as Map)['bookJson'] as String));
    expect(original.copies.length, 1000); expect(original.copies.every((copy) => copy.valid), true);
    expect(original.openingRecords.single.bills.length, 1000);
    final row = WorkspaceLedgerRow.decode(capture['row'], scope);
    expect(workspaceLedgerCanonical(row.value['openingRecord']), workspaceLedgerCanonical(original.openingRecords.single.toJson()));
    expect(utf8.encode(row.data['json']! as String).length, greaterThan(1024 * 1024));
  });
  test('AGG04 remote owned-store verifies source outside the local lock before activation', () async {
    final local = SecureWorkLedgerCheckpointStore(accountScope: () => scope.account); var reads = 0, audits = 0;
    final source = WorkspaceLedgerRemoteSource(scope: scope, connectionId: 'HOST-empty-original', current: () => true, now: () => now,
      request: (body, current, {required mutation, onDispatch}) async {
        expect(mutation, false); expect(await local.read(scope.account, scope.store), null); reads++;
        return reply({...page(), 'state': 'empty', 'sourceRevision': null, 'kind': body['kind'], 'parentId': body['parentId'],
          'totalCount': 0, 'rows': const []});
      });
    final original = await RemoteWorkOwnedLedgerStore.openOriginal(source: source, retainedLocal: local, qa: false,
      assertNoPendingLocalOperations: () async {audits++;});
    expect(reads, 3); expect(audits, 2); expect(original.snapshot!.revision, null);
    expect(original.snapshot!.suppliers, isEmpty); expect(original.snapshot!.expenses, isEmpty); expect(original.snapshot!.registers, isEmpty);
    await expectLater(local.read(scope.account, scope.store), throwsA(isA<WorkGatewayException>()));
    original.retire(); expect(original.snapshot, null);
  });
  test('AGG04 failed refresh invalidates earlier owned records without releasing original routing', () async {
    final local = SecureWorkLedgerCheckpointStore(accountScope: () => scope.account); var fail = false;
    final source = WorkspaceLedgerRemoteSource(scope: scope, connectionId: 'HOST-refresh-unavailable', current: () => true, now: () => now,
      request: (body, current, {required mutation, onDispatch}) async {
        expect(mutation, false);
        if (fail) throw const SocketException('HOST revoked or unavailable original source');
        return reply({...page(), 'state': 'empty', 'sourceRevision': null, 'kind': body['kind'], 'parentId': body['parentId'],
          'totalCount': 0, 'rows': const []});
      });
    final original = await RemoteWorkOwnedLedgerStore.openOriginal(source: source, retainedLocal: local, qa: false,
      assertNoPendingLocalOperations: () async {});
    expect(original.snapshot, isNotNull); fail = true;
    await expectLater(original.read(), throwsA(isA<WorkspaceLedgerRequestFailure>()));
    expect(original.snapshot, null);
    await expectLater(local.read(scope.account, scope.store), throwsA(isA<WorkGatewayException>()));
    fail = false; expect((await original.read()).revision, null);
    expect(original.snapshot, isNotNull); expect(original.pending, null);
  });
  test('AGG04 denied status cannot leave complete earlier sections marked current', () async {
    final local = SecureWorkLedgerCheckpointStore(accountScope: () => scope.account); var statusReads = 0;
    final source = WorkspaceLedgerRemoteSource(scope: scope, connectionId: 'HOST-status-revoked', current: () => true, now: () => now,
      request: (body, current, {required mutation, onDispatch}) async {
        expect(mutation, false);
        if (body['operation'] == 'readStoreLedgerAttempt') {
          statusReads++; return const SocialContentResponse(statusCode: 403, body: '{"ok":false}');
        }
        return reply({...page(), 'state': 'empty', 'sourceRevision': null, 'kind': body['kind'], 'parentId': body['parentId'],
          'totalCount': 0, 'rows': const []});
      });
    final original = await RemoteWorkOwnedLedgerStore.openOriginal(source: source, retainedLocal: local, qa: false,
      assertNoPendingLocalOperations: () async {});
    expect(original.snapshot, isNotNull);
    await expectLater(original.readAttempt(intent()), throwsA(isA<WorkspaceLedgerRequestFailure>()));
    expect(statusReads, 1); expect(original.snapshot, null);
    await expectLater(local.read(scope.account, scope.store), throwsA(isA<WorkGatewayException>()));
  });
  for (final block in ['source unavailable', 'pending local operation', 'legacy ledger']) {
    test('AGG04 remote owned-store preserves the local route when $block prevents activation', () async {
      final local = SecureWorkLedgerCheckpointStore(accountScope: () => scope.account); var reads = 0;
      const storage = FlutterSecureStorage();
      final key = 'moolsocial.workspace.ledger.v1.${Uri.encodeComponent(scope.account)}/${Uri.encodeComponent(scope.store)}';
      if (block == 'legacy ledger') await storage.write(key: key, value: 'HOST retained ledger bytes');
      final source = WorkspaceLedgerRemoteSource(scope: scope, connectionId: 'HOST-unavailable-original', current: () => true, now: () => now,
        request: (body, current, {required mutation, onDispatch}) async {reads++; throw const SocketException('HOST original unavailable');});
      await expectLater(RemoteWorkOwnedLedgerStore.openOriginal(source: source, retainedLocal: local, qa: false,
        assertNoPendingLocalOperations: () async {if (block == 'pending local operation') throw StateError('HOST local Save unresolved');}), throwsA(isA<Object>()));
      expect(reads, block == 'source unavailable' ? 1 : 0);
      expect(await storage.read(key: '$key.original-binding'), null);
      expect(await storage.read(key: key), block == 'legacy ledger' ? 'HOST retained ledger bytes' : null);
    });
  }
  test('AGG04 original adapter restart retains an unknown command without dispatching it', () async {
    final local = SecureWorkLedgerCheckpointStore(accountScope: () => scope.account); var mutations = 0;
    WorkspaceLedgerRemoteSource source() => WorkspaceLedgerRemoteSource(scope: scope, connectionId: 'HOST-restart-original', current: () => true, now: () => now,
      request: (body, current, {required mutation, onDispatch}) async {
        if (mutation) {mutations++; onDispatch?.call(); throw TimeoutException('HOST uncertain original Save');}
        return reply({...page(), 'state': 'empty', 'sourceRevision': null, 'kind': body['kind'], 'parentId': body['parentId'],
          'totalCount': 0, 'rows': const []});
      });
    final first = await RemoteWorkOwnedLedgerStore.openOriginal(source: source(), retainedLocal: local, qa: false, assertNoPendingLocalOperations: () async {});
    await expectLater(first.save(intent()), throwsA(isA<WorkspaceLedgerRequestFailure>()));
    final restarted = await RemoteWorkOwnedLedgerStore.openOriginal(source: source(), retainedLocal: local, qa: false, assertNoPendingLocalOperations: () async {});
    expect(restarted.pending!.fingerprint, intent().fingerprint); expect(mutations, 1);
    await expectLater(local.read(scope.account, scope.store), throwsA(isA<WorkGatewayException>()));
  });
  for (final damage in ['none', 'wrong ordinal', 'wrong history guard', 'mixed source revision']) {
    test('AGG04 owned-section reader preserves native unknown register history ($damage)', () async {
      final first = {'id': 'HOST-entry-1', 'reference': 'HOST original in', 'occurredAt': '2026-10-29T01:10:00.000Z', 'deltaMinor': 100};
      final second = {'id': 'HOST-entry-2', 'reference': 'HOST original out', 'occurredAt': '2026-10-29T01:20:00.000Z', 'deltaMinor': -50};
      final header = <String, Object?>{'accountScope': scope.account, 'workspaceId': scope.store, 'registerId': 'HOST-register',
        'label': 'HOST owned manual register', 'revision': 2, 'openingAt': '2026-10-29T00:00:00.000Z',
        'asOf': now.toIso8601String(), 'openingMinor': null, 'historyComplete': false,
        'entryCount': 2, 'lastEntryAt': second['occurredAt'], 'sequenceValidationMinor': damage == 'wrong history guard' ? 0 : 50};
      Map<String, Object?> nativeRow(String kind, String id, Map<String, Object?> value, {int? ordinal}) =>
        {'kind': kind, 'id': id, 'parentId': kind == 'moneyEntry' ? 'HOST-register' : null, 'revision': value['revision'] ?? 1,
          'json': workspaceLedgerCanonical(value), 'fingerprint': workspaceLedgerFingerprint(value), 'ordinal': ordinal};
      final source = WorkspaceLedgerRemoteSource(scope: scope, connectionId: 'HOST-owned-sections', current: () => true, now: () => now,
        request: (body, current, {required mutation, onDispatch}) async {
          expect(mutation, false);
          final kind = body['kind']! as String;
          final rows = kind == 'moneyRegister' ? [nativeRow(kind, 'HOST-register', header)] : kind == 'moneyEntry'
            ? [nativeRow(kind, 'HOST-entry-2', second, ordinal: 2), nativeRow(kind, 'HOST-entry-1', first, ordinal: damage == 'wrong ordinal' ? 2 : 1)]
            : <Map<String, Object?>>[];
          return reply({...frame(), 'sourceRevision': damage == 'mixed source revision' && kind == 'expense' ? 3 : 2,
            'kind': kind, 'parentId': body['parentId'], 'totalCount': rows.length, 'startsSource': true, 'rows': rows, 'nextCursor': null});
        });
      if (damage != 'none') {await expectLater(source.readOwnedSections(), throwsFormatException); return;}
      final owned = await source.readOwnedSections(); expect(owned.scope, scope); expect(owned.revision, 2);
      expect(owned.suppliers, isEmpty); expect(owned.expenses, isEmpty);
      final register = owned.registers['HOST-register']!;
      expect(register.openingMinor, null); expect(register.historyComplete, false);
      expect(register.entries.map((entry) => entry.id), ['HOST-entry-1', 'HOST-entry-2']);
      expect(() => owned.registers.clear(), throwsUnsupportedError);
    });
  }
  test('AGG04 ledger readonly preflight cannot bind or retire a local Store before authenticated source read', () async {
    final local = SecureWorkLedgerCheckpointStore(accountScope: () => scope.account);
    await local.checkPristineOriginalBinding(scope.account, scope.store, connectionId: 'HOST-ledger-original', realm: scope.realm);
    expect(await local.read(scope.account, scope.store), null);
    final key = 'moolsocial.workspace.ledger.v1.${Uri.encodeComponent(scope.account)}/${Uri.encodeComponent(scope.store)}.original-binding';
    expect(await const FlutterSecureStorage().read(key: key), null);
  });
  test('AGG04 native complete collection validates one revision and every record across original pages', () async {
    final secondValue = {...expense(), 'operationId': 'HOST-expense-2'};
    final second = {...row(), 'id': 'HOST-expense-2', 'json': workspaceLedgerCanonical(secondValue), 'fingerprint': workspaceLedgerFingerprint(secondValue)};
    var calls = 0;
    final source = WorkspaceLedgerRemoteSource(scope: scope, connectionId: 'HOST-pages', current: () => true, now: () => now,
      request: (body, current, {required mutation, onDispatch}) async {
        expect(mutation, false); calls++;
        return reply({...page(), 'totalCount': 2, 'startsSource': calls == 1,
          'rows': [calls == 1 ? row() : second], 'nextCursor': calls == 1 ? 'HOST-next-page' : null});
      });
    final complete = await source.readCollection('expense');
    expect(complete.revision, 1); expect(complete.rows.map((row) => row.id), ['HOST-expense-1', 'HOST-expense-2']);
    expect(calls, 2); expect(() => complete.rows.clear(), throwsUnsupportedError);
  });
  for (final damage in ['missing page', 'changed revision', 'changed count', 'duplicate record', 'cursor loop']) {
    test('AGG04 native complete collection refuses $damage instead of admitting incomplete records', () async {
      var calls = 0;
      final secondValue = {...expense(), 'operationId': 'HOST-expense-2'};
      final second = {...row(), 'id': 'HOST-expense-2', 'json': workspaceLedgerCanonical(secondValue), 'fingerprint': workspaceLedgerFingerprint(secondValue)};
      final source = WorkspaceLedgerRemoteSource(scope: scope, connectionId: 'HOST-pages', current: () => true, now: () => now,
        request: (body, current, {required mutation, onDispatch}) async {
          expect(mutation, false); calls++;
          if (calls == 1) return reply({...page(), 'totalCount': 2, 'nextCursor': damage == 'missing page' ? null : 'HOST-next-page'});
          return reply({...page(), 'startsSource': false, 'sourceRevision': damage == 'changed revision' ? 2 : 1,
            'totalCount': damage == 'changed count' ? 3 : 2,
            'rows': [damage == 'duplicate record' ? row() : second], 'nextCursor': damage == 'cursor loop' ? 'HOST-next-page' : null});
        });
      await expectLater(source.readCollection('expense'), throwsFormatException); expect(calls, lessThanOrEqualTo(2));
    });
  }
  test('AGG04 native empty collection preserves unknown balances and does not request a second page', () async {
    var calls = 0;
    final source = WorkspaceLedgerRemoteSource(scope: scope, connectionId: 'HOST-empty-original', current: () => true, now: () => now,
      request: (body, current, {required mutation, onDispatch}) async {
        calls++; return reply({...page(), 'state': 'empty', 'sourceRevision': null, 'totalCount': 0, 'rows': const []});
      });
    final empty = await source.readCollection('expense'); expect(empty.revision, null); expect(empty.rows, isEmpty); expect(calls, 1);
  });
  test('AGG04 opening evidence journal survives restart and late retry reads the same original receipt', () async {
    final base = Platform.environment['AGG04_NATIVE_CAPTURE_PATH']; expect(base, isNotNull);
    final capture = jsonDecode(File('$base.opening.json').readAsStringSync()) as Map<String, dynamic>;
    final original = WorkspaceSupplierOpeningSaveIntent.fromJson({'schemaVersion': 1, 'operation': 'saveSupplierOpeningEvidence',
      ...Map<String, Object?>.from(capture['command'] as Map)}, scope);
    WorkspacePurchaseEntryJournal journal() => WorkspacePurchaseEntryJournal(scope: scope,
      connectionId: 'HOST-evidence-original', current: () => true);
    await journal().adoptConfirmedOriginal(); await journal().retain(original);
    expect(await journal().readPending(), isA<WorkspaceSupplierOpeningSaveIntent>());
    final other = WorkspaceSupplierSaveIntent(scope: scope, expectedRevision: original.expectedRevision,
      idempotencyKey: 'HOST-other-supplier-save', profile: original.profile);
    await expectLater(journal().retain(other), throwsStateError);
    var reads = 0;
    final source = WorkspacePurchaseEntryRemoteSource(scope: scope, connectionId: 'HOST-evidence-original',
      openingEvidenceSupported: true, current: () => true, now: () => DateTime.parse(capture['now'] as String),
      request: (body, current, {required mutation, onDispatch}) async {
        expect(mutation, false); expect(body['operation'], 'readStorePurchaseEntryAttempt');
        expect(body['idempotencyKey'], original.idempotencyKey); expect(body['fingerprint'], original.fingerprint);
        reads++; return reply(capture['response']);
      });
    final restarted = WorkspaceSupplierSaveController(source: source, journal: journal());
    expect((await restarted.readCurrent()).receipt!.saved, true);
    expect(await journal().readPending(), null);
    expect((await journal().readState()).resolved!.original, isA<WorkspaceSupplierOpeningSaveIntent>());
    expect((await restarted.retryOpeningEvidence(original)).receipt!.saved, true);
    expect(reads, 2);
  });
  test('AGG04 ledger adoption retains legacy bytes and never calls the original bind on a non-pristine slot', () async {
    const storage = FlutterSecureStorage();
    final key = 'moolsocial.workspace.ledger.v1.${Uri.encodeComponent(scope.account)}/${Uri.encodeComponent(scope.store)}';
    const retained = 'HOST retained legacy ledger bytes; migration is not admitted';
    await storage.write(key: key, value: retained);
    final local = SecureWorkLedgerCheckpointStore(accountScope: () => scope.account); var calls = 0;
    await expectLater(local.withPristineOriginalBinding(scope.account, scope.store, connectionId: 'HOST-ledger-original', realm: scope.realm,
      bind: () async {calls++;}), throwsA(isA<WorkGatewayException>()));
    expect(calls, 0); expect(await storage.read(key: key), retained);
    expect(await storage.read(key: '$key.original-binding'), null);
  });
  test('AGG04 ledger original binding shares the writer queue and prevents local fallback after activation', () async {
    final local = SecureWorkLedgerCheckpointStore(accountScope: () => scope.account), started = Completer<void>(), release = Completer<void>();
    final binding = local.withPristineOriginalBinding(scope.account, scope.store, connectionId: 'HOST-ledger-original', realm: scope.realm,
      bind: () async {started.complete(); await release.future;});
    await started.future;
    final queuedRead = expectLater(local.read(scope.account, scope.store), throwsA(isA<WorkGatewayException>()));
    release.complete(); await binding; await queuedRead;
    final reopened = SecureWorkLedgerCheckpointStore(accountScope: () => scope.account);
    await expectLater(reopened.read(scope.account, scope.store), throwsA(isA<WorkGatewayException>()));
    var wrongCalls = 0;
    await expectLater(reopened.withPristineOriginalBinding(scope.account, scope.store, connectionId: 'HOST-different-source', realm: scope.realm,
      bind: () async {wrongCalls++;}), throwsA(isA<WorkGatewayException>()));
    expect(wrongCalls, 0);
    await expectLater(reopened.withPristineOriginalBinding(scope.account, scope.store, connectionId: 'HOST-ledger-original', realm: 'production',
      bind: () async {wrongCalls++;}), throwsA(isA<WorkGatewayException>()));
    expect(wrongCalls, 0);
    await reopened.withPristineOriginalBinding(scope.account, scope.store, connectionId: 'HOST-ledger-original', realm: scope.realm, bind: () async {});
    expect(await reopened.read(scope.account, 'HOST-unbound-store'), null);
  });
  test('AGG04 failed adoption does not publish a marker or erase the existing local route', () async {
    final local = SecureWorkLedgerCheckpointStore(accountScope: () => scope.account);
    await expectLater(local.withPristineOriginalBinding(scope.account, scope.store, connectionId: 'HOST-ledger-original', realm: scope.realm,
      bind: () async {throw StateError('HOST encrypted metadata unavailable');}), throwsStateError);
    expect(await local.read(scope.account, scope.store), null);
  });
  test('AGG04 native unposted opening evidence decodes the actual original purchase Save response', () async {
    final base = Platform.environment['AGG04_NATIVE_CAPTURE_PATH'];
    expect(base, isNotNull, reason: 'The real local SDK capture is required.');
    final capture = jsonDecode(File('$base.opening.json').readAsStringSync()) as Map<String, dynamic>;
    expect(capture['label'], startsWith('ISOLATED ACTUAL SDK UNPOSTED OPENING RESPONSE'));
    final command = Map<String, Object?>.from(capture['command'] as Map);
    final original = WorkspaceSupplierOpeningSaveIntent.fromJson({'schemaVersion': 1,
      'operation': 'saveSupplierOpeningEvidence', ...command}, scope);
    final read = WorkspacePurchaseEntryReadback.decode(capture['response'], scope, DateTime.parse(capture['now'] as String), original: original);
    expect(read.receipt!.saved, true); expect(original.opening.amountMinor, null);
    expect(read.book!.openingRecords.single.amountMinor, null);
    expect(read.book!.openingRecords.single.id, original.opening.id);
    final calls = <bool>[];
    final source = WorkspacePurchaseEntryRemoteSource(scope: scope, connectionId: 'HOST-opening-original',
      openingEvidenceSupported: true, current: () => true, now: () => DateTime.parse(capture['now'] as String),
      request: (body, current, {required mutation, onDispatch}) async {
        calls.add(mutation); onDispatch?.call(); expect(body['opening'], original.opening.toJson());
        return reply(capture['response']);
      });
    final saved = await source.saveOpeningEvidence(original); expect(saved.receipt!.saved, true); expect(calls, [true]);
    expect(WorkspacePurchaseEntrySaveIntent.fromJson(original.toJson(), scope).fingerprint, original.fingerprint);
  });
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });
  SecureWorkspaceLedgerJournal journal({
    String connection = 'HOST-original',
    bool Function()? current,
  }) => SecureWorkspaceLedgerJournal(
    scope: scope,
    connectionId: connection,
    current: current ?? () => true,
  );
  test(
    'AGG04 encrypted journal requires explicit original adoption and protects pending identity across restart',
    () async {
      final first = journal();
      await expectLater(first.read(), throwsStateError);
      await first.adoptConfirmedOriginal();
      await first.retain(intent());
      expect(
        (await journal().read()).pending!.fingerprint,
        intent().fingerprint,
      );
      final other = WorkspaceLedgerIntent.prepare(
        scope: scope,
        operation: 'recordStoreExpense',
        expectedRevision: null,
        idempotencyKey: 'HOST-other',
        fields: {
          'expense': {...expense(), 'operationId': 'HOST-other'},
        },
      );
      await expectLater(journal().retain(other), throwsStateError);
      await expectLater(
        journal(connection: 'HOST-replaced-endpoint').read(),
        throwsFormatException,
      );
      expect(
        (await journal().read()).pending!.idempotencyKey,
        intent().idempotencyKey,
      );
    },
  );
  test(
    'AGG04 encrypted terminal resolution cannot erase a newer pending Save',
    () async {
      final original = intent(), store = journal();
      await store.adoptConfirmedOriginal();
      await store.retain(original);
      final saved = WorkspaceLedgerReadback.decode(
        status(),
        scope,
        now,
        original,
      );
      await store.resolve(original, saved);
      expect((await journal().read()).pending, null);
      expect((await journal().read()).resolved!.status, 'saved');
      await expectLater(journal().retain(original), throwsStateError);
      final other = WorkspaceLedgerIntent.prepare(
        scope: scope,
        operation: 'recordStoreExpense',
        expectedRevision: 1,
        idempotencyKey: 'HOST-newer',
        fields: {
          'expense': {...expense(), 'operationId': 'HOST-newer'},
        },
      );
      await journal().retain(other);
      await expectLater(journal().resolve(original, saved), throwsStateError);
      expect(
        (await journal().read()).pending!.idempotencyKey,
        other.idempotencyKey,
      );
    },
  );
  test(
    'AGG04 native restarted controller resolves lost acknowledgement by status without sending again',
    () async {
      final store = journal();
      await store.adoptConfirmedOriginal();
      var mutations = 0, reads = 0;
      final source = WorkspaceLedgerRemoteSource(
        scope: scope,
        connectionId: 'HOST-original',
        current: () => true,
        now: () => now,
        request: (body, current, {required mutation, onDispatch}) async {
          onDispatch?.call();
          if (mutation) {
            mutations++;
            throw TimeoutException('HOST lost committed acknowledgement');
          }
          reads++;
          return reply(status());
        },
      );
      final first = WorkspaceLedgerSaveController(
        source: source,
        journal: store,
      );
      await expectLater(
        first.save(intent()),
        throwsA(isA<WorkspaceLedgerRequestFailure>()),
      );
      expect((await journal().read()).pending, isNotNull);
      final restarted = WorkspaceLedgerSaveController(
        source: source,
        journal: journal(),
      );
      final recovered = await restarted.readRetainedAttempt(intent());
      expect(recovered.attempt!['status'], 'saved');
      await restarted.save(intent());
      expect(mutations, 1);
      expect(reads, 2);
      expect((await journal().read()).pending, null);
    },
  );
  test(
    'AGG04 explicit retry of unknown Save retains nonce and fingerprint and performs status first',
    () async {
      final store = journal();
      await store.adoptConfirmedOriginal();
      final calls = <String>[];
      var mutations = 0;
      final source = WorkspaceLedgerRemoteSource(
        scope: scope,
        connectionId: 'HOST-original',
        current: () => true,
        now: () => now,
        request: (body, current, {required mutation, onDispatch}) async {
          onDispatch?.call();
          calls.add(body['operation']! as String);
          expect(body['idempotencyKey'], intent().idempotencyKey);
          expect(body['fingerprint'], intent().fingerprint);
          if (mutation) {
            mutations++;
            if (mutations == 1)
              throw TimeoutException('HOST unconfirmed dispatch');
            return reply(status());
          }
          return reply(status(receipt: false));
        },
      );
      await expectLater(
        WorkspaceLedgerSaveController(
          source: source,
          journal: store,
        ).save(intent()),
        throwsA(isA<WorkspaceLedgerRequestFailure>()),
      );
      final restarted = WorkspaceLedgerSaveController(
        source: source,
        journal: journal(),
      );
      final result = await restarted.save(intent());
      expect(result.attempt!['status'], 'saved');
      expect(calls, [
        'recordStoreExpense',
        'readStoreLedgerAttempt',
        'recordStoreExpense',
      ]);
    },
  );
  test(
    'AGG04 repeated native Save taps share one dispatched future and conflicting taps are blocked',
    () async {
      final store = journal();
      await store.adoptConfirmedOriginal();
      final gate = Completer<void>();
      var mutations = 0;
      final source = WorkspaceLedgerRemoteSource(
        scope: scope,
        connectionId: 'HOST-original',
        current: () => true,
        now: () => now,
        request: (body, current, {required mutation, onDispatch}) async {
          mutations++;
          onDispatch?.call();
          await gate.future;
          return reply(status());
        },
      );
      final controller = WorkspaceLedgerSaveController(
            source: source,
            journal: store,
          ),
          first = controller.save(intent()),
          second = controller.save(intent());
      expect(identical(first, second), true);
      final other = WorkspaceLedgerIntent.prepare(
        scope: scope,
        operation: 'recordStoreExpense',
        expectedRevision: null,
        idempotencyKey: 'HOST-conflicting-tap',
        fields: {'expense': expense()},
      );
      expect(() => controller.save(other), throwsStateError);
      gate.complete();
      await first;
      expect(mutations, 1);
      expect((await journal().read()).pending, null);
    },
  );
  test(
    'AGG04 retired account cannot restore or change its encrypted pending state',
    () async {
      var active = true;
      final store = journal(current: () => active);
      await store.adoptConfirmedOriginal();
      await store.retain(intent());
      active = false;
      await expectLater(store.read(), throwsStateError);
      await expectLater(store.retain(intent()), throwsStateError);
      expect(
        (await journal().read()).pending!.fingerprint,
        intent().fingerprint,
      );
    },
  );
  test(
    'AGG04 native intent freezes exact original data and detects tampered or foreign commands',
    () {
      final input = expense(),
          original = WorkspaceLedgerIntent.prepare(
            scope: scope,
            operation: 'recordStoreExpense',
            expectedRevision: null,
            idempotencyKey: 'HOST-freeze',
            fields: {'expense': input},
          );
      input['note'] = 'HOST mutation';
      expect((original.input! as Map)['note'], expense()['note']);
      expect(
        () => (original.input! as Map)['note'] = 'HOST mutation',
        throwsUnsupportedError,
      );
      expect(
        WorkspaceLedgerIntent.fromJson(original.toJson(), scope).fingerprint,
        original.fingerprint,
      );
      expect(
        () => WorkspaceLedgerIntent.fromJson({
          ...original.toJson(),
          'expectedRevision': 2,
        }, scope),
        throwsFormatException,
      );
      expect(
        () => WorkspaceLedgerIntent.fromJson(original.toJson(), (
          account: scope.account,
          store: 'HOST-other',
          realm: scope.realm,
        )),
        throwsFormatException,
      );
    },
  );
  test(
    'AGG04 native expense bounds, unknown type and extra fields fail before transport',
    () {
      for (final amount in [0, -1, 9007199254740992]) {
        expect(
          () => WorkspaceLedgerIntent.prepare(
            scope: scope,
            operation: 'recordStoreExpense',
            expectedRevision: null,
            idempotencyKey: 'HOST-invalid',
            fields: {
              'expense': {...expense(), 'amountMinor': amount},
            },
          ),
          throwsFormatException,
        );
      }
      expect(
        () => WorkspaceLedgerIntent.prepare(
          scope: scope,
          operation: 'saveWholeLedger',
          expectedRevision: null,
          idempotencyKey: 'HOST-invalid',
          fields: {'expense': expense()},
        ),
        throwsFormatException,
      );
      expect(
        () => WorkspaceLedgerIntent.prepare(
          scope: scope,
          operation: 'recordStoreExpense',
          expectedRevision: null,
          idempotencyKey: 'HOST-invalid',
          fields: {
            'expense': {...expense(), 'verifiedPaid': true},
          },
        ),
        throwsFormatException,
      );
    },
  );
  test(
    'AGG04 native page and status preserve typed owned records without inferring finance',
    () {
      final read = WorkspaceLedgerPage.decode(
        page(),
        scope,
        now,
        kind: 'expense',
        parentId: null,
        cursor: null,
      );
      expect(read.totalCount, 1);
      expect(read.rows.single.value, expense());
      expect(read.nextCursor, null);
      final saved = WorkspaceLedgerReadback.decode(
        status(),
        scope,
        now,
        intent(),
      );
      expect(saved.attempt!['status'], 'saved');
      expect(saved.current!.value, expense());
      final unknown = WorkspaceLedgerReadback.decode(
        status(receipt: false),
        scope,
        now,
        intent(),
      );
      expect(unknown.attempt, null);
      expect(unknown.current, null);
    },
  );
  test(
    'AGG04 native malformed, foreign, stale or partial source responses never qualify a Save',
    () {
      for (final change in <String, Object?>{
        'actorAccountId': 'HOST-other',
        'storeId': 'HOST-other',
        'realm': 'production',
        'observedAt': DateTime.utc(2026).toIso8601String(),
        'current': null,
        'sourceRevision': null,
      }.entries) {
        expect(
          () => WorkspaceLedgerReadback.decode(
            {...status(), change.key: change.value},
            scope,
            now,
            intent(),
          ),
          throwsFormatException,
        );
      }
      for (final change in <String, Object?>{
        'rows': [row(), row()],
        'totalCount': 0,
        'nextCursor': '',
        'startsSource': false,
        'kind': 'supplierLedger',
      }.entries) {
        expect(
          () => WorkspaceLedgerPage.decode(
            {...page(), change.key: change.value},
            scope,
            now,
            kind: 'expense',
            parentId: null,
            cursor: null,
          ),
          throwsFormatException,
        );
      }
      expect(
        () => WorkspaceLedgerRow.decode({
          ...row(),
          'json': jsonEncode({...expense(), 'note': 'HOST damaged'}),
        }, scope),
        throwsFormatException,
      );
    },
  );
  test(
    'AGG04 native transport separates mutation credentials from read-only status and never replays',
    () async {
      final calls = <(String, bool)>[];
      final source = WorkspaceLedgerRemoteSource(
        scope: scope,
        connectionId: 'HOST-original',
        current: () => true,
        now: () => now,
        request: (body, current, {required mutation, onDispatch}) async {
          expect(current(), true);
          onDispatch?.call();
          calls.add((body['operation']! as String, mutation));
          return reply(
            body['operation'] == 'readStoreLedgerSource' ? page() : status(),
          );
        },
      );
      await source.readPage('expense');
      await source.save(intent());
      await source.readAttempt(intent());
      expect(calls, [
        ('readStoreLedgerSource', false),
        ('recordStoreExpense', true),
        ('readStoreLedgerAttempt', false),
      ]);
    },
  );
  test(
    'AGG04 native dispatched failure stays unknown and does not trigger an automatic retry',
    () async {
      var calls = 0;
      final source = WorkspaceLedgerRemoteSource(
        scope: scope,
        connectionId: 'HOST-original',
        current: () => true,
        request: (body, current, {required mutation, onDispatch}) async {
          calls++;
          onDispatch?.call();
          throw TimeoutException('HOST lost acknowledgement');
        },
      );
      await expectLater(
        source.save(intent()),
        throwsA(
          isA<WorkspaceLedgerRequestFailure>().having(
            (error) => error.mayHaveCommitted,
            'unknown',
            true,
          ),
        ),
      );
      expect(calls, 1);
      source.retire();
      await expectLater(
        source.save(intent()),
        throwsA(
          isA<WorkspaceLedgerRequestFailure>().having(
            (error) => error.mayHaveCommitted,
            'not sent',
            false,
          ),
        ),
      );
      expect(calls, 1);
    },
  );
  test(
    'AGG04 native source retirement during response cannot publish a previous account result',
    () async {
      var current = true;
      final source = WorkspaceLedgerRemoteSource(
        scope: scope,
        connectionId: 'HOST-original',
        current: () => current,
        now: () => now,
        request: (body, active, {required mutation, onDispatch}) async {
          onDispatch?.call();
          current = false;
          return reply(status());
        },
      );
      await expectLater(
        source.save(intent()),
        throwsA(
          isA<WorkspaceLedgerRequestFailure>().having(
            (error) => error.mayHaveCommitted,
            'unknown',
            true,
          ),
        ),
      );
    },
  );
  test(
    'AGG04 native decodes actual SDK plus handler capture rather than a parallel response schema',
    () {
      final capturePath = Platform.environment['AGG04_NATIVE_CAPTURE_PATH'];
      expect(
        capturePath,
        isNotNull,
        reason:
            'Run with the owned loopback SDK capture; a missing capture is unqualified.',
      );
      final capture =
          jsonDecode(File(capturePath!).readAsStringSync())
              as Map<String, dynamic>;
      expect(
        capture['label'],
        startsWith('ISOLATED ACTUAL SDK/HANDLER CAPTURE'),
      );
      final original = WorkspaceLedgerIntent.fromJson(
            capture['command'],
            scope,
          ),
          observed = DateTime.parse(capture['now'] as String);
      final saved = WorkspaceLedgerReadback.decode(
        capture['status'],
        scope,
        observed,
        original,
      );
      final list = WorkspaceLedgerPage.decode(
        capture['page'],
        scope,
        observed,
        kind: 'expense',
        parentId: null,
        cursor: null,
      );
      expect(saved.attempt!['status'], 'saved');
      expect(list.rows.single.value, saved.current!.value);
    },
  );
  Map<String, dynamic> supplierMoneyCapture(String kind) {
    final base = Platform.environment['AGG05_NATIVE_CAPTURE_PATH']; expect(base, isNotNull);
    return jsonDecode(File('$base.$kind.json').readAsStringSync()) as Map<String, dynamic>;
  }
  for (final kind in ['payment', 'advance']) {
    test('AGG05 mobile actual SDK supplier money $kind uses the original authenticated gateway and native proof', () async {
      final capture = supplierMoneyCapture(kind), response = Map<String, Object?>.from(capture['response'] as Map);
      final original = WorkspaceLedgerIntent.fromJson(capture['command'], scope);
      expect(original.operation, 'recordStoreSupplierMoney'); expect(original.targetKind, 'supplierLedger');
      expect(original.entryId, (capture['command'] as Map)['entry']['operationId']);
      expect(original.fingerprint, (capture['command'] as Map)['fingerprint']);
      final transport = Transport(Map<String, dynamic>.from(response)), privateTransport = Transport(Map<String, dynamic>.from(response)), credentials = Credentials();
      final gateway = AuthenticatedWorkspaceCatalogueGateway(
        endpoint: Uri.parse('https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
        realm: scope.realm, credentials: credentials, transport: transport, privateOriginalTransport: privateTransport,
        ledgerSourceSupported: true, now: () => now);
      final source = gateway.originalLedgerSource(accountId: scope.account, storeId: scope.store, current: () => true)!;
      final saved = await source.save(original);
      expect(saved.attempt!['status'], 'saved'); expect(saved.current!.value['entries'], [original.input]);
      for (final field in (capture['requestBody'] as Map).entries) expect(privateTransport.sent![field.key], field.value);
      expect((await source.readAttempt(original)).attempt, saved.attempt);
      expect(privateTransport.sent!['operation'], 'readStoreLedgerAttempt'); expect(transport.sent, null);
      expect(credentials.modes, [SocialAppCheckTokenMode.limitedUse, SocialAppCheckTokenMode.standard]);
      expect(() => (original.data['entry'] as Map)['amountMinor'] = 1, throwsUnsupportedError);
    });
  }
  test('AGG05 mobile actual SDK supplier money refusal is not a payment success', () {
    final capture = supplierMoneyCapture('refused'), original = WorkspaceLedgerIntent.fromJson(capture['command'], scope);
    final result = WorkspaceLedgerReadback.decode(capture['response'], scope, now, original);
    expect(result.attempt!['status'], 'not_saved'); expect(result.attempt!['changed'], false);
    expect(result.attempt!['reason'], 'supplier_capacity_changed'); expect(result.current!.value['entries'], isEmpty);
  });
  test('AGG05 mobile money status rejects a different entry even with a self-consistent current row fingerprint', () {
    final capture = supplierMoneyCapture('payment'), original = WorkspaceLedgerIntent.fromJson(capture['command'], scope);
    for (final damage in ['actor', 'nonce', 'resultRevision', 'missingCurrent', 'differentEntry', 'duplicateEntry']) {
      final response = jsonDecode(jsonEncode(capture['response'])) as Map<String, dynamic>;
      final receipt = response['attempt'] as Map<String, dynamic>;
      if (damage == 'actor') response['actorAccountId'] = 'HOST-other-account';
      if (damage == 'nonce') receipt['idempotencyKey'] = 'HOST-other-attempt';
      if (damage == 'resultRevision') receipt['resultRevision'] = 3;
      if (damage == 'missingCurrent') response['current'] = null;
      if (damage == 'differentEntry' || damage == 'duplicateEntry') {
        final row = response['current'] as Map<String, dynamic>, ledger = jsonDecode(row['json'] as String) as Map<String, dynamic>;
        final entries = ledger['entries'] as List;
        if (damage == 'differentEntry') { (entries.single as Map)['amountMinor'] = 1251; }
        else { entries.add(jsonDecode(jsonEncode(entries.single))); }
        row['json'] = workspaceLedgerCanonical(ledger); row['fingerprint'] = workspaceLedgerFingerprint(ledger);
      }
      expect(() => WorkspaceLedgerReadback.decode(response, scope, now, original), throwsFormatException, reason: damage);
    }
  });
  test('AGG05 mobile encrypted money attempt survives lost reply and restart with status-only recovery', () async {
    final capture = supplierMoneyCapture('payment'), original = WorkspaceLedgerIntent.fromJson(capture['command'], scope);
    SecureWorkspaceLedgerJournal retained() => journal(connection: 'HOST-supplier-money-original');
    await retained().adoptConfirmedOriginal(); var writes = 0, reads = 0;
    final source = WorkspaceLedgerRemoteSource(scope: scope, connectionId: 'HOST-supplier-money-original',
      current: () => true, now: () => now, request: (body, current, {required mutation, onDispatch}) async {
        onDispatch?.call();
        if (mutation) {
          writes++; expect(body, capture['requestBody']); throw TimeoutException('HOST lost original money acknowledgement');
        }
        reads++; expect(body['operation'], 'readStoreLedgerAttempt');
        expect(body['idempotencyKey'], original.idempotencyKey); expect(body['fingerprint'], original.fingerprint);
        return reply(capture['response']);
      });
    final first = WorkspaceLedgerSaveController(source: source, journal: retained());
    await expectLater(first.save(original), throwsA(isA<WorkspaceLedgerRequestFailure>()));
    expect((await retained().read()).pending!.toJson(), original.toJson());
    final restarted = WorkspaceLedgerSaveController(source: source, journal: retained());
    expect((await restarted.readRetainedAttempt(original)).attempt!['status'], 'saved');
    expect((await restarted.save(original)).attempt!['status'], 'saved');
    expect(writes, 1); expect(reads, 2); expect((await retained().read()).pending, null);
    expect((await retained().read()).resolved!.original.toJson(), original.toJson());
  });
  test('AGG05 mobile resolved money refusal stays status-only on an old Save callback', () async {
    final capture = supplierMoneyCapture('refused'), original = WorkspaceLedgerIntent.fromJson(capture['command'], scope);
    final store = journal(connection: 'HOST-refused-money-original'); await store.adoptConfirmedOriginal();
    var writes = 0, reads = 0;
    final source = WorkspaceLedgerRemoteSource(scope: scope, connectionId: 'HOST-refused-money-original',
      current: () => true, now: () => now, request: (body, current, {required mutation, onDispatch}) async {
        onDispatch?.call(); if (mutation) {writes++;} else {reads++; expect(body['operation'], 'readStoreLedgerAttempt');}
        return reply(capture['response']);
      });
    final controller = WorkspaceLedgerSaveController(source: source, journal: store);
    expect((await controller.save(original)).attempt!['status'], 'not_saved');
    expect((await controller.save(original)).attempt!['status'], 'not_saved');
    expect(writes, 1); expect(reads, 1); expect(controller.pending, null);
    expect(controller.lastResolution!.original.fingerprint, original.fingerprint);
  });

  test('AGG05 refund backend formats agree with native intent and original command boundaries', () {
    final path = Platform.environment['AGG05_REFUND_INPUT_CAPTURE_PATH']; expect(path, isNotNull);
    final capture = jsonDecode(File(path!).readAsStringSync()) as Map;
    expect(capture['label'], 'ISOLATED HOST FORMAT CASES; NO SOURCE CAPACITY OR FINANCIAL EFFECT');
    expect((capture['cases'] as List).length, 20);
    for (final raw in capture['cases'] as List) {
      final item = raw as Map;
      Object? parse() => WorkspaceLedgerIntent.prepare(scope: scope, operation: 'recordStoreSupplierRefund',
        expectedRevision: 1, idempotencyKey: 'HOST-refund-parser-case', fields: {
          'supplierId': 'HOST-supplier-1', 'expectedSupplierRevision': 1,
          'intent': item['input'], 'confirmedUtcOffsetMinutes': 330,
        }).input;
      if (item['accepted'] == true) expect(parse(), item['input'], reason: item['name'] as String);
      else expect(parse, throwsA(anything), reason: item['name'] as String);
    }
    final proof = WorkspaceSupplierRefund.fromJson(capture['proof']);
    expect(proof.valid, true); expect(proof.entry.amountMinor, 250);
  });
  Map<String, dynamic> refundCapture(String kind) {
    final path = Platform.environment['AGG05_REFUND_NATIVE_CAPTURE_PATH']; expect(path, isNotNull);
    return jsonDecode(File('$path.$kind.json').readAsStringSync()) as Map<String, dynamic>;
  }
  for (final kind in ['openingAdvance', 'accountAdvance']) {
    test('AGG05 refund actual SDK $kind matches native entry balance and exact receipt', () {
      final capture = refundCapture(kind), response = capture['response'] as Map;
      final original = WorkspaceLedgerIntent.fromJson(capture['command'], scope);
      final input = WorkspaceSupplierRefundIntent.fromJson(original.input);
      expect(original.operation, 'recordStoreSupplierRefund'); expect(original.targetKind, 'supplierLedger');
      expect(original.entryId, input.operationId); expect(original.targetId, input.supplierId);
      final result = WorkspaceLedgerReadback.decode(response, scope, now, original);
      expect(result.attempt!['status'], 'saved'); expect(result.attempt!['inputFingerprint'], workspaceLedgerFingerprint(original.input));
      final ledger = WorkspaceSupplierLedger.fromJson(result.current!.value)!;
      expect(ledger.valid, true); expect(ledger.balanceMinor, -750); expect(ledger.creditMinor, 750);
      expect(ledger.entries.where((entry) => entry.operationId == input.operationId).length, 1);
      expect(ledger.refunds[input.operationId]!.intent.toJson(), input.toJson());
      expect(ledger.unallocatedMoneyMinor(WorkspaceSupplierMoneySourceKind.values.byName(kind), input.sourceId), 750);
      for (final damage in ['amount', 'entry', 'missing proof', 'other supplier']) {
        final altered = jsonDecode(jsonEncode(response)) as Map, row = altered['current'] as Map,
          value = jsonDecode(row['json'] as String) as Map;
        final proof = (value['refunds'] as Map)[input.operationId] as Map;
        if (damage == 'amount') (proof['intent'] as Map)['amountMinor'] = 249;
        if (damage == 'entry') ((value['entries'] as List).last as Map)['amountMinor'] = 249;
        if (damage == 'missing proof') (value['refunds'] as Map).remove(input.operationId);
        if (damage == 'other supplier') (proof['intent'] as Map)['supplierId'] = 'HOST-foreign-supplier';
        row['json'] = workspaceLedgerCanonical(value); row['fingerprint'] = workspaceLedgerFingerprint(value);
        expect(() => WorkspaceLedgerReadback.decode(altered, scope, now, original), throwsA(anything), reason: damage);
      }
    });
  }
  test('AGG05 refund actual SDK uses private original transport and status never repeats the record', () async {
    final capture = refundCapture('openingAdvance'), original = WorkspaceLedgerIntent.fromJson(capture['command'], scope);
    final publicTransport = Transport(Map<String, dynamic>.from(capture['response'] as Map)),
      privateTransport = Transport(Map<String, dynamic>.from(capture['response'] as Map)), credentials = Credentials();
    final gateway = AuthenticatedWorkspaceCatalogueGateway(
      endpoint: Uri.parse('https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'), realm: scope.realm,
      credentials: credentials, transport: publicTransport, privateOriginalTransport: privateTransport, ledgerSourceSupported: true, now: () => now);
    final source = gateway.originalLedgerSource(accountId: scope.account, storeId: scope.store, current: () => true)!;
    final saved = await source.save(original);
    expect(saved.attempt!['status'], 'saved'); expect(privateTransport.sent!['operation'], 'recordStoreSupplierRefund');
    expect(privateTransport.sent!['intent'], original.input); expect(publicTransport.sent, isNull);
    expect((await source.readAttempt(original)).attempt, saved.attempt);
    expect(privateTransport.sent!['operation'], 'readStoreLedgerAttempt'); expect(publicTransport.sent, isNull);
    expect(credentials.modes, [SocialAppCheckTokenMode.limitedUse, SocialAppCheckTokenMode.standard]);
  });
  Future<({SecureWorkLedgerFormDraftStore store, WorkspaceLedgerFormKey key,
    WorkspaceSupplierRefundIntent intent, WorkspaceLedgerFormDraft draft, WorkspaceLedgerIntent original})>
      frozenOriginalRefundForm({String? Function()? account}) async {
    final capture = refundCapture('openingAdvance'), original = WorkspaceLedgerIntent.fromJson(capture['command'], scope);
    final intent = WorkspaceSupplierRefundIntent.fromJson(original.input), key = intent.formKey;
    final store = SecureWorkLedgerFormDraftStore(accountScope: account ?? () => scope.account);
    final fields = {'amount': '2.50', 'channel': intent.paymentMethod, 'reference': intent.reference,
      'occurredOn': intent.occurredOn, 'sourceKind': intent.sourceKind.name, 'sourceId': intent.sourceId};
    await store.save(WorkspaceLedgerFormDraft(key: key, revision: 1, fields: fields), expectedRevision: null);
    final draft = WorkspaceLedgerFormDraft(key: key, revision: 2, fields: {...fields, 'attempt': jsonEncode(intent.toJson())});
    await store.save(draft, expectedRevision: 1);
    return (store: store, key: key, intent: intent, draft: draft, original: original);
  }
  test('AGG05 refund encrypted original survives reopen and a newer shared request', () async {
    final f = await frozenOriginalRefundForm();
    await f.store.retainOriginalSupplierRefundAttempt(f.key, f.intent, f.original, scope: scope, connectionId: 'HOST-original');
    await f.store.retainOriginalSupplierRefundAttempt(f.key, f.intent, f.original, scope: scope, connectionId: 'HOST-original');
    final shared = journal(); await shared.adoptConfirmedOriginal(); await shared.retain(intent());
    final reopened = await SecureWorkLedgerFormDraftStore(accountScope: () => scope.account)
      .readOriginalSupplierRefundAttempt(f.key, f.intent, scope: scope, connectionId: 'HOST-original');
    expect(reopened!.toJson(), f.original.toJson());
    expect((await shared.read()).pending!.operation, 'recordStoreExpense');
    final values = await const FlutterSecureStorage().readAll();
    final raw = values.entries.singleWhere((entry) => entry.key.contains('.original-request.')).value;
    final persisted = jsonDecode(raw) as Map;
    expect(persisted['frozenDraft'], f.draft.toJson()); expect(persisted['original'], f.original.toJson());
    expect(persisted.keys.toSet(), {'schemaVersion', 'connectionId', 'original', 'frozenDraft'});
  });
  test('AGG05 refund recovery selector reads only current owner source identities without storage writes', () async {
    final f = await frozenOriginalRefundForm();
    await f.store.retainOriginalSupplierRefundAttempt(f.key, f.intent, f.original, scope: scope, connectionId: 'HOST-original');
    final before = await const FlutterSecureStorage().readAll();
    final hints = await f.store.readOriginalSupplierRefundSources(f.intent.supplierId, scope: scope, connectionId: 'HOST-original');
    expect(hints.length, 1); expect(hints.single.sourceId, f.intent.sourceId);
    expect(hints.single.reference, f.intent.reference); expect(hints.single.openingRevision, f.intent.openingRevision);
    expect(hints.single.sourceKind, f.intent.sourceKind); expect(hints.single.qa, f.intent.qa);
    expect(await f.store.readOriginalSupplierRefundSources('HOST-foreign-supplier', scope: scope, connectionId: 'HOST-original'), isEmpty);
    expect(await f.store.readOriginalSupplierRefundSources(f.intent.supplierId,
      scope: (account: scope.account, store: 'HOST-foreign-store', realm: scope.realm), connectionId: 'HOST-original'), isEmpty);
    await expectLater(f.store.readOriginalSupplierRefundSources(f.intent.supplierId,
      scope: (account: 'HOST-foreign-account', store: scope.store, realm: scope.realm), connectionId: 'HOST-original'), throwsA(anything));
    await expectLater(f.store.readOriginalSupplierRefundSources(f.intent.supplierId,
      scope: scope, connectionId: 'HOST-foreign-endpoint'), throwsA(anything));
    expect(await const FlutterSecureStorage().readAll(), before);
    final fields = {...f.draft.fields}..remove('attempt');
    await f.store.resetRefusedSupplierRefundDraft(WorkspaceLedgerFormDraft(key: f.key, revision: 3, fields: fields),
      expectedRevision: 2, scope: scope, connectionId: 'HOST-original', verifyNotRecorded: (_, __) async => true);
    expect(await f.store.readOriginalSupplierRefundSources(f.intent.supplierId, scope: scope, connectionId: 'HOST-original'), isEmpty,
      reason: 'An archived sidecar must not resurrect an unfrozen current form.');
  });
  test('AGG05 refund original nonce endpoint and source cannot be replaced', () async {
    final f = await frozenOriginalRefundForm();
    await f.store.retainOriginalSupplierRefundAttempt(f.key, f.intent, f.original, scope: scope, connectionId: 'HOST-original');
    final changed = {...f.original.toJson()}..remove('fingerprint'); changed['idempotencyKey'] = 'HOST-replacement-request';
    final replacement = WorkspaceLedgerIntent.fromJson({...changed, 'fingerprint': workspaceLedgerFingerprint(changed)}, scope);
    await expectLater(f.store.retainOriginalSupplierRefundAttempt(f.key, f.intent, replacement,
      scope: scope, connectionId: 'HOST-original'), throwsA(anything));
    await expectLater(f.store.readOriginalSupplierRefundAttempt(f.key, f.intent,
      scope: scope, connectionId: 'HOST-other-endpoint'), throwsA(anything));
    await expectLater(f.store.readOriginalSupplierRefundAttempt(f.key, f.intent,
      scope: (account: scope.account, store: 'HOST-foreign-store', realm: scope.realm), connectionId: 'HOST-original'), throwsA(anything));
    final values = await const FlutterSecureStorage().readAll(), entry = values.entries.singleWhere((entry) => entry.key.contains('.original-request.'));
    final corrupted = jsonDecode(entry.value) as Map;
    ((corrupted['frozenDraft'] as Map)['fields'] as Map)['amount'] = '2.49';
    await const FlutterSecureStorage().write(key: entry.key, value: jsonEncode(corrupted));
    await expectLater(f.store.readOriginalSupplierRefundAttempt(f.key, f.intent,
      scope: scope, connectionId: 'HOST-original'), throwsA(anything));
    await const FlutterSecureStorage().write(key: entry.key, value: entry.value);
    expect((await f.store.readOriginalSupplierRefundAttempt(f.key, f.intent,
      scope: scope, connectionId: 'HOST-original'))!.toJson(), f.original.toJson());
  });
  test('AGG05 refund refusal reset preserves input and needs exact verified absence', () async {
    final f = await frozenOriginalRefundForm();
    await f.store.retainOriginalSupplierRefundAttempt(f.key, f.intent, f.original, scope: scope, connectionId: 'HOST-original');
    final fields = {...f.draft.fields}..remove('attempt');
    final next = WorkspaceLedgerFormDraft(key: f.key, revision: 3, fields: fields);
    await expectLater(f.store.resetRefusedSupplierRefundDraft(next, expectedRevision: 2, scope: scope, connectionId: 'HOST-original',
      verifyNotRecorded: (_, __) async => false), throwsA(anything));
    expect((await f.store.read(f.key))!.toJson(), f.draft.toJson());
    var checks = 0;
    final changed = WorkspaceLedgerFormDraft(key: f.key, revision: 3, fields: {...fields, 'amount': '2.49'});
    await expectLater(f.store.resetRefusedSupplierRefundDraft(changed, expectedRevision: 2, scope: scope, connectionId: 'HOST-original',
      verifyNotRecorded: (_, __) async {checks++; return true;}), throwsA(anything));
    expect(checks, 0);
    await f.store.resetRefusedSupplierRefundDraft(next, expectedRevision: 2, scope: scope, connectionId: 'HOST-original',
      verifyNotRecorded: (intent, original) async {
        expect(intent.toJson(), f.intent.toJson()); expect(original.toJson(), f.original.toJson()); checks++; return true;
      });
    expect(checks, 1); expect((await f.store.read(f.key))!.toJson(), next.toJson());
    await expectLater(f.store.readOriginalSupplierRefundAttempt(f.key, f.intent,
      scope: scope, connectionId: 'HOST-original'), throwsA(anything));
  });
  test('AGG05 refund retired account during refusal verification cannot release saved inputs', () async {
    var account = scope.account;
    final f = await frozenOriginalRefundForm(account: () => account);
    await f.store.retainOriginalSupplierRefundAttempt(f.key, f.intent, f.original, scope: scope, connectionId: 'HOST-original');
    final before = await const FlutterSecureStorage().readAll(), fields = {...f.draft.fields}..remove('attempt');
    final next = WorkspaceLedgerFormDraft(key: f.key, revision: 3, fields: fields);
    await expectLater(f.store.resetRefusedSupplierRefundDraft(next, expectedRevision: 2, scope: scope, connectionId: 'HOST-original',
      verifyNotRecorded: (_, __) async {account = 'HOST-retired-account'; return true;}), throwsA(anything));
    expect(await const FlutterSecureStorage().readAll(), before);
    await expectLater(f.store.readOriginalSupplierRefundAttempt(f.key, f.intent,
      scope: scope, connectionId: 'HOST-original'), throwsA(anything));
    account = scope.account;
    expect((await f.store.read(f.key))!.toJson(), f.draft.toJson());
  });
  test('AGG05 allocation backend formats agree with unchanged native intent and original-proof decoders', () {
    final path = Platform.environment['AGG05_ALLOCATION_INPUT_CAPTURE_PATH']; expect(path, isNotNull);
    final export = jsonDecode(File(path!).readAsStringSync()) as Map;
    expect(export['label'], 'ISOLATED NATIVE ALLOCATION FORMAT PARITY; NOT CAPACITY, AUTHORITY OR POSTING');
    expect((export['cases'] as List).length, 18);
    for (final item in export['cases'] as List) {
      Object? parse() => item['kind'] == 'intent'
        ? WorkspaceSupplierMoneyAllocationIntent.fromJson(item['input']).intentToJson()
        : WorkspaceSupplierBillMoneyAllocation.fromJson(item['input']).toJson();
      if (item['accepted'] == true) expect(parse(), item['input'], reason: item['name'] as String);
      else expect(parse, throwsA(anything), reason: item['name'] as String);
    }
  });
  for (final kind in ['openingAdvance', 'accountPayment', 'accountAdvance']) {
    test('AGG05 actual SDK allocation $kind row preserves native money, bill remaining and source use', () {
      final path = Platform.environment['AGG05_ALLOCATION_NATIVE_CAPTURE_PATH']; expect(path, isNotNull);
      final capture = jsonDecode(File('$path.$kind.json').readAsStringSync()) as Map;
      expect(capture['label'], 'ISOLATED ACTUAL SDK ORIGINAL ALLOCATION; NO NEW PAYMENT OR RUNTIME AUTHORITY');
      final command = capture['command'] as Map, input = WorkspaceSupplierMoneyAllocationIntent.fromJson(command['intent']);
      final response = capture['response'] as Map, row = WorkspaceLedgerRow.decode(response['current'], scope);
      final original = WorkspaceLedgerIntent.fromJson(command, scope);
      expect(original.toJson(), command); expect(original.entryId, input.operationId);
      expect(WorkspaceLedgerReadback.decode(response, scope, now, original).attempt!['status'], 'saved');
      final ledger = WorkspaceSupplierLedger.fromJson(row.value)!;
      expect(ledger.valid, true); expect(ledger.payableMinor, kind == 'openingAdvance' ? 0 : 10500);
      expect(ledger.entries.length, kind == 'openingAdvance' ? 1 : 2);
      expect(ledger.manualBillRemainingMinor(input.billId), 750);
      expect(ledger.unallocatedMoneyMinor(WorkspaceSupplierMoneySourceKind.values.byName(kind), input.sourceId),
        kind == 'openingAdvance' ? 750 : 250);
      final proof = ledger.billMoneyAllocations[input.operationId]!;
      expect(proof.intentToJson(), input.intentToJson());
      expect(proof.committedRevision, row.data['revision']);
      expect(ledger.entries.where((entry) => entry.operationId == input.operationId), isEmpty,
        reason: 'An allocation proof must not become another payment entry.');
      final altered = jsonDecode(jsonEncode(response)) as Map;
      final alteredRow = altered['current'] as Map, value = jsonDecode(alteredRow['json'] as String) as Map;
      ((value['billMoneyAllocations'] as Map)[input.operationId] as Map)['amountMinor'] = input.amountMinor + 1;
      alteredRow['json'] = workspaceLedgerCanonical(value); alteredRow['fingerprint'] = workspaceLedgerFingerprint(value);
      expect(() => WorkspaceLedgerRow.decode(alteredRow, scope), returnsNormally,
        reason: 'The altered amount still forms a valid ledger but does not prove this original request.');
      expect(() => WorkspaceLedgerReadback.decode(altered, scope, now, original), throwsFormatException);
    });
  }
  test('AGG05 original bill backend input cases agree with the existing native reviewed-bill validator', () {
    final path = Platform.environment['AGG05_BILL_INPUT_CAPTURE_PATH']; expect(path, isNotNull);
    final capture = jsonDecode(File(path!).readAsStringSync()) as Map;
    expect(capture['label'], 'ISOLATED ORIGINAL BILL INPUT PARITY; NO FINANCIAL AUTHORITY OR EFFECT');
    expect((capture['cases'] as List).length, 6);
    for (final raw in capture['cases'] as List) {
      final value = raw as Map, input = value['input'] as Map;
      if (value['accepted'] == false) {
        expect(() => WorkspaceSupplierBillAcceptance.fromJson(input), throwsFormatException, reason: value['name'] as String);
      } else {
        final parsed = WorkspaceSupplierBillAcceptance.fromJson(input), copy = input['copy'] as Map;
        final draft = copy['draft'] as Map;
        expect(parsed.openingTreatment.name, input['openingTreatment']);
        expect(parsed.copy.draft.goods, draft['goods']); expect(parsed.copy.draft.details, draft['details']);
        expect(parsed.billId, draft['id']); expect(parsed.acceptedAt.toUtc().toIso8601String(), input['acceptedAt']);
      }
    }
  });

  for (final treatment in ['included', 'excluded']) {
    test('AGG05 actual original SDK $treatment bill row agrees with native accepted liability', () {
      final path = Platform.environment['AGG05_BILL_NATIVE_CAPTURE_PATH']; expect(path, isNotNull);
      final capture = jsonDecode(File('$path.$treatment.json').readAsStringSync()) as Map;
      expect(capture['label'], 'ISOLATED ACTUAL SDK ORIGINAL BILL; NOT RUNTIME AUTHORITY OR PAYMENT');
      final original = capture['command'] as Map, response = capture['response'] as Map, receipt = response['attempt'] as Map;
      final parsed = WorkspaceSupplierBillAcceptance.fromJson(original['bill']);
      final row = WorkspaceLedgerRow.decode(response['current'], scope);
      final ledger = WorkspaceSupplierLedger.fromJson(row.value)!;
      expect(ledger.valid, true); expect(ledger.historyComplete, true);
      expect(receipt['status'], 'saved'); expect(receipt['entryId'], parsed.billId);
      expect(receipt['inputFingerprint'], workspaceLedgerFingerprint(original['bill']));
      expect(ledger.purchaseBills[parsed.billId]!.toJson(), parsed.toJson());
      expect(ledger.entries.length, treatment == 'excluded' ? 1 : 0);
      expect(ledger.payableMinor, treatment == 'excluded' ? 11000 : 10000);
      expect(ledger.purchaseBills[parsed.billId]!.addsLiability, treatment == 'excluded');
      if (treatment == 'excluded') expect(ledger.entries.single.toJson(), (row.value['entries'] as List).single);
    });
    test('AGG05 actual SDK $treatment bill command and exact status decode without changing reviewed input', () {
      final path = Platform.environment['AGG05_BILL_NATIVE_CAPTURE_PATH']!;
      final capture = jsonDecode(File('$path.$treatment.json').readAsStringSync()) as Map;
      final original = WorkspaceLedgerIntent.fromJson(capture['command'], scope);
      expect(original.toJson(), capture['command']);
      expect(original.operation, 'confirmStoreSupplierBill');
      expect(original.targetKind, 'supplierLedger');
      final bill = WorkspaceSupplierBillAcceptance.fromJson(original.input);
      expect(original.entryId, bill.billId);
      expect(original.targetId, bill.copy.supplier.id);
      final status = WorkspaceLedgerReadback.decode(capture['response'], scope, now, original);
      expect(status.attempt!['status'], 'saved');
      expect(status.current!.value['purchaseBills'], contains(bill.billId));
      final wrong = jsonDecode(jsonEncode(capture['response'])) as Map;
      (wrong['attempt'] as Map)['entryId'] = 'another-original-bill';
      expect(() => WorkspaceLedgerReadback.decode(wrong, scope, now, original), throwsFormatException);
    });
    test('AGG05 $treatment bill command rejects invalid source pins and supplier identity', () {
      final path = Platform.environment['AGG05_BILL_NATIVE_CAPTURE_PATH']!;
      final capture = jsonDecode(File('$path.$treatment.json').readAsStringSync()) as Map;
      for (final change in <Map<String, Object?>>[
        {'supplierId': 'another-supplier'}, {'expectedSupplierRevision': 0},
        {'expectedPurchaseRevision': 0}, {'expectedPurchaseFingerprint': 'not-a-hash'},
        {'confirmedUtcOffsetMinutes': -721}, {'confirmedUtcOffsetMinutes': 841},
        {'unexpectedField': true},
      ]) {
        final command = Map<String, Object?>.from(capture['command'] as Map)..remove('fingerprint');
        command.addAll(change);
        expect(() => WorkspaceLedgerIntent.fromJson({
          ...command, 'fingerprint': workspaceLedgerFingerprint(command),
        }, scope), throwsFormatException, reason: change.keys.single);
      }
    });
  }

  for (final variant in ['bill', 'account', 'advance']) {
    test('AGG05 actual SDK bill money $variant preserves original source and independent bill remaining', () {
      final path = Platform.environment['AGG05_BILL_MONEY_NATIVE_CAPTURE_PATH']; expect(path, isNotNull);
      final capture = jsonDecode(File('$path.$variant.json').readAsStringSync()) as Map;
      expect(capture['label'], 'ISOLATED ACTUAL SDK ORIGINAL BILL MONEY; NOT RUNTIME AUTHORITY OR PAYMENT');
      final original = WorkspaceLedgerIntent.fromJson(capture['command'], scope);
      final readback = WorkspaceLedgerReadback.decode(capture['response'], scope, now, original);
      expect(readback.attempt!['status'], 'saved'); expect(readback.revision, 3);
      final ledger = WorkspaceSupplierLedger.fromJson(readback.current!.value)!;
      expect(ledger.valid, true); expect(ledger.payableMinor, 10500);
      final bill = ledger.purchaseBills.values.single;
      expect(ledger.manualBillRemainingMinor(bill.billId), variant == 'bill' ? 500 : 1000);
      expect(ledger.entries.last.toJson(), original.input);
      expect(ledger.entries.last.origin, variant == 'bill'
        ? WorkspaceSupplierEntryOrigin.manualPurchase : WorkspaceSupplierEntryOrigin.supplierAccount);
    });
  }
  for (final outcome in ['payment', 'refused']) {
    test('AGG05 older $outcome status cannot replace a newer unrelated pending request', () async {
      final capture = supplierMoneyCapture(outcome), original = WorkspaceLedgerIntent.fromJson(capture['command'], scope);
      final store = journal(connection: 'HOST-old-money-status');
      await store.adoptConfirmedOriginal(); await store.retain(original);
      final receipt = WorkspaceLedgerReadback.decode(capture['response'], scope, now, original);
      await store.resolve(original, receipt);
      final newer = intent(); await store.retain(newer);
      var writes = 0, reads = 0;
      final source = WorkspaceLedgerRemoteSource(scope: scope, connectionId: 'HOST-old-money-status',
        current: () => true, now: () => now, request: (body, current, {required mutation, onDispatch}) async {
          if (mutation) writes++; else reads++;
          expect(mutation, false); expect(body['operation'], 'readStoreLedgerAttempt');
          expect(body['idempotencyKey'], original.idempotencyKey);
          return reply(capture['response']);
        });
      final controller = WorkspaceLedgerSaveController(source: source, journal: store);
      expect((await controller.readRetainedAttempt(original)).attempt!['status'], receipt.attempt!['status']);
      expect(controller.pending!.toJson(), newer.toJson());
      await expectLater(controller.save(original), throwsStateError);
      expect((await store.read()).pending!.toJson(), newer.toJson());
      expect((await store.read()).resolved!.original.toJson(), original.toJson());
      expect(writes, 0); expect(reads, 1);
    });
  }
  test('AGG05 retired Store during money status recovery cannot resolve its retained request', () async {
    final capture = supplierMoneyCapture('payment'), original = WorkspaceLedgerIntent.fromJson(capture['command'], scope);
    final store = journal(connection: 'HOST-money-retired'); await store.adoptConfirmedOriginal(); await store.retain(original);
    var live = true, writes = 0;
    final source = WorkspaceLedgerRemoteSource(scope: scope, connectionId: 'HOST-money-retired',
      current: () => live, now: () => now, request: (body, current, {required mutation, onDispatch}) async {
        if (mutation) writes++;
        live = false; return reply(capture['response']);
      });
    final controller = WorkspaceLedgerSaveController(source: source, journal: store);
    await expectLater(controller.readRetainedAttempt(original), throwsA(anything));
    expect(controller.pending, null); expect(controller.lastResolution, null);
    expect((await store.read()).pending!.toJson(), original.toJson()); expect(writes, 0);
  });

  Future<({SecureWorkLedgerFormDraftStore store, WorkspaceLedgerFormKey key,
    WorkspaceSupplierMoneyAllocationIntent allocation, WorkspaceLedgerFormDraft draft, WorkspaceLedgerIntent original})>
      frozenOriginalAllocationForm() async {
    final path = Platform.environment['AGG05_ALLOCATION_NATIVE_CAPTURE_PATH']; expect(path, isNotNull);
    final capture = jsonDecode(File('$path.accountPayment.json').readAsStringSync()) as Map;
    final original = WorkspaceLedgerIntent.fromJson(capture['command'], scope);
    final allocation = WorkspaceSupplierMoneyAllocationIntent.fromJson(original.input);
    final WorkspaceLedgerFormKey key = (account: scope.account, store: scope.store, customer: allocation.supplierId,
      invoice: allocation.billId, order: 'allocation-copy:${allocation.copyId}',
      kind: 'supplierAllocation', ledgerRevision: allocation.copyRevision);
    final store = SecureWorkLedgerFormDraftStore(accountScope: () => scope.account);
    final fields = {'amount': '${allocation.amountMinor ~/ 100}.${(allocation.amountMinor % 100).toString().padLeft(2, '0')}',
      'sourceKind': allocation.sourceKind.name, 'sourceId': allocation.sourceId};
    await store.save(WorkspaceLedgerFormDraft(key: key, revision: 1, fields: fields), expectedRevision: null);
    final draft = WorkspaceLedgerFormDraft(key: key, revision: 2,
      fields: {...fields, 'attempt': jsonEncode(allocation.intentToJson())});
    await store.save(draft, expectedRevision: 1);
    return (store: store, key: key, allocation: allocation, draft: draft, original: original);
  }
  test('AGG05 allocation encrypted request survives reopening and newer shared journal request', () async {
    final f = await frozenOriginalAllocationForm();
    await f.store.retainOriginalSupplierAllocationAttempt(f.key, f.allocation, f.original,
      scope: scope, connectionId: 'HOST-original');
    await f.store.retainOriginalSupplierAllocationAttempt(f.key, f.allocation, f.original,
      scope: scope, connectionId: 'HOST-original');
    final shared = journal(); await shared.adoptConfirmedOriginal(); await shared.retain(intent());
    final reopened = await SecureWorkLedgerFormDraftStore(accountScope: () => scope.account)
      .readOriginalSupplierAllocationAttempt(f.key, f.allocation, scope: scope, connectionId: 'HOST-original');
    expect(reopened!.toJson(), f.original.toJson());
    expect((await shared.read()).pending!.operation, 'recordStoreExpense');
    final values = await const FlutterSecureStorage().readAll();
    final envelope = jsonDecode(values.entries.singleWhere((entry) => entry.key.contains('.original-request.')).value) as Map;
    expect(envelope['frozenDraft'], f.draft.toJson());
  });
  test('AGG05 allocation encrypted request rejects replacement identity and foreign endpoint or owner', () async {
    final f = await frozenOriginalAllocationForm();
    await f.store.retainOriginalSupplierAllocationAttempt(f.key, f.allocation, f.original,
      scope: scope, connectionId: 'HOST-original');
    final before = await const FlutterSecureStorage().readAll();
    final fields = Map<String, Object?>.from(f.original.data)
      ..remove('scope')..remove('operation')..remove('expectedRevision')..remove('idempotencyKey');
    final replacement = WorkspaceLedgerIntent.prepare(scope: scope, operation: f.original.operation,
      expectedRevision: f.original.data['expectedRevision'] as int?, idempotencyKey: 'HOST-replacement-nonce', fields: fields);
    await expectLater(f.store.retainOriginalSupplierAllocationAttempt(f.key, f.allocation, replacement,
      scope: scope, connectionId: 'HOST-original'), throwsA(isA<WorkGatewayException>()));
    await expectLater(f.store.readOriginalSupplierAllocationAttempt(f.key, f.allocation,
      scope: scope, connectionId: 'HOST-other-endpoint'), throwsA(isA<WorkGatewayException>()));
    await expectLater(f.store.readOriginalSupplierAllocationAttempt(f.key, f.allocation,
      scope: (account: scope.account, store: 'HOST-other-store', realm: scope.realm),
      connectionId: 'HOST-original'), throwsA(isA<WorkGatewayException>()));
    await expectLater(SecureWorkLedgerFormDraftStore(accountScope: () => 'HOST-other-account')
      .readOriginalSupplierAllocationAttempt(f.key, f.allocation, scope: scope,
        connectionId: 'HOST-original'), throwsA(isA<WorkGatewayException>()));
    expect(await const FlutterSecureStorage().readAll(), before);
  });
  test('AGG05 allocation encrypted request refuses changed frozen input and corrupted retained evidence', () async {
    final f = await frozenOriginalAllocationForm();
    await f.store.retainOriginalSupplierAllocationAttempt(f.key, f.allocation, f.original,
      scope: scope, connectionId: 'HOST-original');
    final changed = WorkspaceSupplierMoneyAllocationIntent.fromJson({...f.allocation.intentToJson(),
      'amountMinor': f.allocation.amountMinor + 1});
    await expectLater(f.store.readOriginalSupplierAllocationAttempt(f.key, changed,
      scope: scope, connectionId: 'HOST-original'), throwsA(isA<WorkGatewayException>()));
    final values = await const FlutterSecureStorage().readAll();
    final entry = values.entries.singleWhere((entry) => entry.key.contains('.original-request.'));
    final envelope = jsonDecode(entry.value) as Map;
    (envelope['frozenDraft'] as Map)['fields'] = {'amount': '999'};
    await const FlutterSecureStorage().write(key: entry.key, value: jsonEncode(envelope));
    await expectLater(f.store.readOriginalSupplierAllocationAttempt(f.key, f.allocation,
      scope: scope, connectionId: 'HOST-original'), throwsA(isA<WorkGatewayException>()));
    expect((await f.store.read(f.key))!.toJson(), f.draft.toJson());
  });

  test('AGG05 allocation encrypted refusal reset retains input and request evidence and requires verification', () async {
    final f = await frozenOriginalAllocationForm();
    await f.store.retainOriginalSupplierAllocationAttempt(f.key, f.allocation, f.original,
      scope: scope, connectionId: 'HOST-original');
    final fields = {...f.draft.fields}..remove('attempt');
    final next = WorkspaceLedgerFormDraft(key: f.key, revision: 3, fields: fields);
    final before = await const FlutterSecureStorage().readAll();
    await expectLater(f.store.resetRefusedSupplierAllocationDraft(next, expectedRevision: 2, scope: scope,
      connectionId: 'HOST-original', verifyNotRecorded: (_, __) async => false), throwsA(isA<WorkGatewayException>()));
    expect(await const FlutterSecureStorage().readAll(), before);
    var checked = 0;
    Future<bool> hostVerification(WorkspaceSupplierMoneyAllocationIntent input, WorkspaceLedgerIntent original) async {
      checked++; expect(input.intentToJson(), f.allocation.intentToJson());
      expect(original.toJson(), f.original.toJson());
      return true; // Storage-contract seam only; not an original not_saved receipt.
    }
    await f.store.resetRefusedSupplierAllocationDraft(next, expectedRevision: 2, scope: scope,
      connectionId: 'HOST-original', verifyNotRecorded: hostVerification);
    await f.store.resetRefusedSupplierAllocationDraft(next, expectedRevision: 2, scope: scope,
      connectionId: 'HOST-original', verifyNotRecorded: hostVerification);
    expect(checked, 1); expect((await f.store.read(f.key))!.fields, fields);
    final after = await const FlutterSecureStorage().readAll();
    for (final entry in before.entries.where((entry) => entry.key.contains('.original-request.'))) {
      expect(after[entry.key], entry.value);
    }
    await expectLater(f.store.readOriginalSupplierAllocationAttempt(f.key, f.allocation,
      scope: scope, connectionId: 'HOST-original'), throwsA(isA<WorkGatewayException>()));
  });
  test('AGG05 allocation encrypted refusal reset cannot change inputs or clear an actual saved receipt', () async {
    final f = await frozenOriginalAllocationForm();
    await f.store.retainOriginalSupplierAllocationAttempt(f.key, f.allocation, f.original,
      scope: scope, connectionId: 'HOST-original');
    final fields = {...f.draft.fields}..remove('attempt');
    final before = await const FlutterSecureStorage().readAll(); var checked = 0;
    for (final changed in [{'amount': '1.00'}, {'sourceId': 'HOST-another-source'}, {'sourceKind': 'openingAdvance'}]) {
      await expectLater(f.store.resetRefusedSupplierAllocationDraft(
        WorkspaceLedgerFormDraft(key: f.key, revision: 3, fields: {...fields, ...changed}),
        expectedRevision: 2, scope: scope, connectionId: 'HOST-original',
        verifyNotRecorded: (_, __) async {checked++; return true;}), throwsA(isA<WorkGatewayException>()));
    }
    expect(checked, 0);
    await expectLater(f.store.resetRefusedSupplierAllocationDraft(
      WorkspaceLedgerFormDraft(key: f.key, revision: 3, fields: fields),
      expectedRevision: 2, scope: scope, connectionId: 'HOST-original', verifyNotRecorded: (_, original) async {
        final path = Platform.environment['AGG05_ALLOCATION_NATIVE_CAPTURE_PATH'];
        final capture = jsonDecode(File('$path.accountPayment.json').readAsStringSync()) as Map;
        return WorkspaceLedgerReadback.decode(capture['response'], scope, now, original).attempt!['status'] == 'not_saved';
      }), throwsA(isA<WorkGatewayException>()));
    expect(await const FlutterSecureStorage().readAll(), before);
  });

  Future<({SecureWorkLedgerFormDraftStore store, WorkspaceLedgerFormKey key,
    WorkspaceSupplierMoneyAttempt attempt, WorkspaceLedgerFormDraft draft, WorkspaceLedgerIntent original})>
      frozenOriginalMoneyForm(String kind) async {
    final original = WorkspaceLedgerIntent.fromJson(supplierMoneyCapture(kind)['command'], scope);
    final attempt = WorkspaceSupplierMoneyAttempt.fromJson({'entry': original.input,
      'expectedRevision': original.data['expectedSupplierRevision']})!;
    final review = attempt.entry.moneyReview!, advance = attempt.entry.kind.name == 'advance';
    final WorkspaceLedgerFormKey key = (account: scope.account, store: scope.store, customer: original.targetId,
      invoice: review.openingId, order: 'account-${advance ? 'advance' : 'payment'}:${review.openingId}',
      kind: 'supplierMoney', ledgerRevision: review.openingRevision);
    final store = SecureWorkLedgerFormDraftStore(accountScope: () => scope.account);
    final fields = {'amount': '${attempt.entry.amountMinor ~/ 100}.${(attempt.entry.amountMinor % 100).toString().padLeft(2, '0')}',
      'reference': attempt.entry.reference, 'channel': attempt.entry.paymentMethod!,
      'occurredOn': review.occurredOn, 'notIncludedInOpening': 'true'};
    await store.save(WorkspaceLedgerFormDraft(key: key, revision: 1, fields: fields), expectedRevision: null);
    final draft = WorkspaceLedgerFormDraft(key: key, revision: 2,
      fields: {...fields, 'attempt': jsonEncode(attempt.toJson())});
    await store.save(draft, expectedRevision: 1);
    return (store: store, key: key, attempt: attempt, draft: draft, original: original);
  }
  test('AGG05 encrypted raw form retains the original nonce when the shared journal moves to another request', () async {
    final f = await frozenOriginalMoneyForm('refused');
    await f.store.retainOriginalSupplierMoneyAttempt(f.key, f.attempt, f.original, scope: scope, connectionId: 'HOST-original');
    await f.store.retainOriginalSupplierMoneyAttempt(f.key, f.attempt, f.original, scope: scope, connectionId: 'HOST-original');
    final global = journal(); await global.adoptConfirmedOriginal(); await global.retain(f.original);
    final refused = WorkspaceLedgerReadback.decode(supplierMoneyCapture('refused')['response'], scope, now, f.original);
    await global.resolve(f.original, refused);
    await global.retain(intent()); // No expense is dispatched or manufactured here.
    expect((await global.read()).pending!.operation, 'recordStoreExpense');
    final reopened = await SecureWorkLedgerFormDraftStore(accountScope: () => scope.account)
      .readOriginalSupplierMoneyAttempt(f.key, f.attempt, scope: scope, connectionId: 'HOST-original');
    expect(reopened!.toJson(), f.original.toJson());
    final bytes = await const FlutterSecureStorage().readAll();
    final records = bytes.entries.where((entry) => entry.key.contains('.original-request.')).toList();
    expect(records.length, 1);
    final snapshot = jsonDecode(records.single.value) as Map;
    expect(snapshot['frozenDraft'], f.draft.toJson());
  });
  test('AGG05 encrypted raw form cannot replace an event nonce or use another endpoint scope', () async {
    final f = await frozenOriginalMoneyForm('payment');
    await f.store.retainOriginalSupplierMoneyAttempt(f.key, f.attempt, f.original, scope: scope, connectionId: 'HOST-original');
    final fields = Map<String, Object?>.from(f.original.data)
      ..remove('scope')..remove('operation')..remove('expectedRevision')..remove('idempotencyKey');
    final replacement = WorkspaceLedgerIntent.prepare(scope: scope, operation: f.original.operation,
      expectedRevision: f.original.data['expectedRevision'] as int?, idempotencyKey: 'HOST-replacement-nonce', fields: fields);
    final before = await const FlutterSecureStorage().readAll();
    await expectLater(f.store.retainOriginalSupplierMoneyAttempt(f.key, f.attempt, replacement,
      scope: scope, connectionId: 'HOST-original'), throwsA(isA<WorkGatewayException>()));
    await expectLater(f.store.readOriginalSupplierMoneyAttempt(f.key, f.attempt,
      scope: scope, connectionId: 'HOST-replaced-endpoint'), throwsA(isA<WorkGatewayException>()));
    await expectLater(f.store.readOriginalSupplierMoneyAttempt(f.key, f.attempt,
      scope: (account: scope.account, store: 'HOST-other-store', realm: scope.realm),
      connectionId: 'HOST-original'), throwsA(isA<WorkGatewayException>()));
    expect(await const FlutterSecureStorage().readAll(), before);
  });
  test('AGG05 refused raw input reset preserves fields and request evidence and requires confirmed non-recording', () async {
    final f = await frozenOriginalMoneyForm('refused');
    await f.store.retainOriginalSupplierMoneyAttempt(f.key, f.attempt, f.original, scope: scope, connectionId: 'HOST-original');
    final fields = {...f.draft.fields}..remove('attempt'); fields['notIncludedInOpening'] = 'false';
    final next = WorkspaceLedgerFormDraft(key: f.key, revision: 3, fields: fields);
    final before = await const FlutterSecureStorage().readAll();
    await expectLater(f.store.resetRefusedSupplierMoneyDraft(next, expectedRevision: 2, scope: scope,
      connectionId: 'HOST-original', verifyNotRecorded: (_, __) async => false), throwsA(isA<WorkGatewayException>()));
    expect(await const FlutterSecureStorage().readAll(), before);
    var checked = 0;
    Future<bool> verify(WorkspaceSupplierMoneyAttempt attempt, WorkspaceLedgerIntent original) async {
      checked++; expect(attempt.toJson(), f.attempt.toJson()); expect(original.toJson(), f.original.toJson());
      final result = WorkspaceLedgerReadback.decode(supplierMoneyCapture('refused')['response'], scope, now, original);
      return result.attempt!['status'] == 'not_saved' && (result.current!.value['entries'] as List).isEmpty;
    }
    await f.store.resetRefusedSupplierMoneyDraft(next, expectedRevision: 2, scope: scope,
      connectionId: 'HOST-original', verifyNotRecorded: verify);
    await f.store.resetRefusedSupplierMoneyDraft(next, expectedRevision: 2, scope: scope,
      connectionId: 'HOST-original', verifyNotRecorded: verify);
    expect(checked, 1); expect((await f.store.read(f.key))!.fields, fields);
    final after = await const FlutterSecureStorage().readAll();
    for (final entry in before.entries.where((entry) => entry.key.contains('.original-request.'))) expect(after[entry.key], entry.value);
    expect((await f.store.read(f.key))!.supplierMoneyAttempt, null);
    await expectLater(f.store.readOriginalSupplierMoneyAttempt(f.key, f.attempt, scope: scope,
      connectionId: 'HOST-original'), throwsA(isA<WorkGatewayException>()));
  });
  test('AGG05 refusal reset cannot drop copies/change money fields or clear a recorded request', () async {
    final f = await frozenOriginalMoneyForm('payment');
    await f.store.retainOriginalSupplierMoneyAttempt(f.key, f.attempt, f.original, scope: scope, connectionId: 'HOST-original');
    final fields = {...f.draft.fields}..remove('attempt'); fields['notIncludedInOpening'] = 'false';
    final before = await const FlutterSecureStorage().readAll(); var callback = 0;
    for (final changed in [{'amount': '1.00'}, {'reference': 'HOST changed'}, {'notIncludedInOpening': 'true'}]) {
      final next = WorkspaceLedgerFormDraft(key: f.key, revision: 3, fields: {...fields, ...changed});
      await expectLater(f.store.resetRefusedSupplierMoneyDraft(next, expectedRevision: 2, scope: scope,
        connectionId: 'HOST-original', verifyNotRecorded: (_, __) async {callback++; return true;}), throwsA(isA<WorkGatewayException>()));
    }
    expect(callback, 0);
    await expectLater(f.store.resetRefusedSupplierMoneyDraft(WorkspaceLedgerFormDraft(key: f.key, revision: 3, fields: fields),
      expectedRevision: 2, scope: scope, connectionId: 'HOST-original', verifyNotRecorded: (_, original) async {
        final saved = WorkspaceLedgerReadback.decode(supplierMoneyCapture('payment')['response'], scope, now, original);
        return saved.attempt!['status'] == 'not_saved';
      }), throwsA(isA<WorkGatewayException>()));
    expect(await const FlutterSecureStorage().readAll(), before);
  });

}
