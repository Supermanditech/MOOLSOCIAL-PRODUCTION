import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:moolsocial/features/work/work_customer_gateway.dart';
import 'package:moolsocial/features/work/work_models.dart';
import 'package:moolsocial/features/work/work_services.dart' show SecureWorkCounterDraftStore, RemoteWorkCounterDraftStore, WorkGatewayException, WorkPendingProofStore, ReviewWorkGateway;
import 'package:moolsocial/features/work/work_session.dart';
import 'package:moolsocial/features/work/work_ledger_gateway.dart' show workspaceLedgerCanonical, workspaceLedgerFingerprint;
import 'package:moolsocial/features/shared/social_content_gateway.dart' show SocialContentResponse, SocialContentCredentials, SocialContentTransport, SocialAppCheckTokenMode;
import 'package:moolsocial/features/work/work_catalogue_gateway.dart';

// ISOLATED HOST serialization fixture only. No runtime finance/provider or phone
// records are installed, and these values are not an authoritative snapshot.
const hostAccount = 'HOST-customer-account';
const hostStore = 'HOST-customer-store';
final hostAsOf = DateTime.parse('2026-10-30T01:00:00.000010Z');
const hostScope = (account: hostAccount, store: hostStore, realm: 'evaluation');
class _HostCounterAccount implements WorkPendingProofStore {
  @override String? get accountScope => hostAccount;
  @override Future<Map<String, Object?>?> read(String scope) async => null;
  @override Future<void> save(String scope, Map<String, Object?> draft) async {}
  @override Future<void> clear(String scope) async {}
}
class _HostCounterCredentials implements SocialContentCredentials {
  @override Future<String> firebaseIdToken() async => 'HOST-isolated-token';
  @override Future<String> appCheckToken(SocialAppCheckTokenMode mode) async => 'HOST-isolated-appcheck';
}
class _HostCounterTransport implements SocialContentTransport {
  final requests = <Map<String, Object?>>[];
  @override Future<SocialContentResponse> postJson(Uri endpoint, {required Map<String, String> headers,
    required Map<String, Object?> body}) async {
    requests.add(body);
    return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': hostCounterReadback()}));
  }
}
WorkspaceCounterDraft hostCounterDraft({bool large = false, int revision = 1}) => WorkspaceCounterDraft(
  account: hostAccount, store: hostStore, id: 'HOST-native-bill', revision: revision,
  stage: WorkspaceCounterDraftStage.editing, customer: 'HOST unfinished customer',
  billingDetails: const WorkspaceBillingDetails(business: true, name: 'HOST ગ્રાહક',
    businessName: 'HOST વેપાર', gst: '', address: 'HOST entered address'),
  source: 'Counter', fulfilment: 'At the shop', payment: 'Customer due', address: '',
  lines: [WorkspaceOrderItemSnapshot(productId: 'HOST-private-sku', name: 'HOST original product',
    pack: 'HOST pack', quantity: large ? 2147483647 : 1,
    unitPricePaise: large ? 1000000000 : 1025,
    lineTotalPaise: large ? 2147483647000000000 : 1025)],
);
WorkspaceCustomerLedger hostCustomerLedger() => WorkspaceCustomerLedger(
  accountScope: hostAccount, workspaceId: hostStore,
  customerId: 'HOST-customer-one', customerName: 'HOST ग्राहक',
  revision: 2, asOf: hostAsOf, openingBalanceMinor: 0, historyComplete: true,
  entries: [
    WorkspaceCustomerLedgerEntry(id: 'HOST-invoice-entry', operationId: 'HOST-sale-operation',
      invoiceId: 'HOST-invoice', orderId: 'HOST-counter-order', sequence: 1,
      occurredAt: DateTime.parse('2026-10-30T01:00:00.000001Z'),
      kind: WorkspaceLedgerEntryKind.invoice, state: WorkspaceLedgerPostingState.posted, amountMinor: 250),
    WorkspaceCustomerLedgerEntry(id: 'HOST-collection-entry', operationId: 'HOST-collection-operation',
      invoiceId: 'HOST-invoice', orderId: 'HOST-counter-order', sequence: 2,
      occurredAt: DateTime.parse('2026-10-30T01:00:00.000002Z'),
      kind: WorkspaceLedgerEntryKind.collection, state: WorkspaceLedgerPostingState.posted,
      amountMinor: 100, channel: WorkspacePaymentChannel.cash, paymentReference: 'HOST cash record'),
  ],
);
Map<String, Object?> hostCustomerJson() => {
  'accountScope': hostAccount, 'workspaceId': hostStore,
  'customerId': 'HOST-customer-one', 'customerName': 'HOST ग्राहक',
  'revision': 2, 'asOf': '2026-10-30T01:00:00.000010Z', 'openingBalanceMinor': 0,
  'historyComplete': true, 'entries': [
    {'id': 'HOST-invoice-entry', 'operationId': 'HOST-sale-operation', 'invoiceId': 'HOST-invoice',
      'orderId': 'HOST-counter-order', 'sequence': 1, 'occurredAt': '2026-10-30T01:00:00.000001Z',
      'kind': 'invoice', 'state': 'posted', 'amountMinor': 250, 'channel': 'unknown', 'paymentReference': null},
    {'id': 'HOST-collection-entry', 'operationId': 'HOST-collection-operation', 'invoiceId': 'HOST-invoice',
      'orderId': 'HOST-counter-order', 'sequence': 2, 'occurredAt': '2026-10-30T01:00:00.000002Z',
      'kind': 'collection', 'state': 'posted', 'amountMinor': 100, 'channel': 'cash', 'paymentReference': 'HOST cash record'},
  ],
};
WorkspaceLedgerCheckpoint hostCheckpoint() => WorkspaceLedgerCheckpoint(revision: 2,
  finance: WorkspaceFinanceSnapshot(accountScope: hostAccount, workspaceId: hostStore,
    revision: 2, asOf: hostAsOf, salesTodayMinor: 0, duesMinor: 150,
    availableMinor: 0, heldMinor: 0, requestedMinor: 0, paidOutMinor: 0,
    feesMinor: 0, deliveryAdjustmentsMinor: 0, refundsMinor: 0, taxWithheldMinor: 0,
    payments: const [], payouts: const [], customerLedgers: [hostCustomerLedger()], historyComplete: false));
Object? checkpointCustomer(WorkspaceLedgerCheckpoint value) =>
  (((value.toJson()['finance'] as Map)['customerLedgers']) as List).single;

WorkspaceCounterOriginalIntent hostCounterIntent() => WorkspaceCounterOriginalIntent(scope: hostScope,
  draft: hostCounterDraft(), expectedRevision: null, idempotencyKey: 'HOST-native-counter-save');
Map<String, Object?> hostCounterReadback({WorkspaceCounterOriginalIntent? original, bool missing = false}) {
  final wire = workspaceCounterDraftToOriginalWire(original?.draft ?? hostCounterDraft(), hostScope);
  return {'schemaVersion': 1, 'customerOriginalVersion': 1, 'actorAccountId': hostAccount,
    'realm': 'evaluation', 'storeId': hostStore, 'observedAt': '2026-10-30T01:00:02.000Z',
    'state': missing ? 'empty' : 'ready', 'draftJson': missing ? null : workspaceLedgerCanonical(wire),
    'draftFingerprint': missing ? null : workspaceLedgerFingerprint(wire),
    'attempt': original == null ? null : {'schemaVersion': 1,
      'scope': {'account': hostAccount, 'store': hostStore, 'realm': 'evaluation'},
      'operation': 'saveStoreCounterDraft', 'idempotencyKey': original.idempotencyKey, 'fingerprint': original.fingerprint,
      'status': 'saved', 'reason': null, 'changed': true, 'resultRevision': original.draft.revision.toString(),
      'recordedAt': '2026-10-30T01:00:01.000Z'}};
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final serviceNow = DateTime.parse('2026-10-30T01:00:02.000Z');
  test('AGG06 unchanged reopened Counter draft preserves exact saved bytes and revision on navigation save', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final storage = const FlutterSecureStorage(), local = SecureWorkCounterDraftStore(accountScope: () => hostAccount);
    final draft = WorkspaceCounterDraft(account: hostAccount, store: hostStore, id: 'HOST-retained-bill', revision: 1,
      stage: WorkspaceCounterDraftStage.editing, customer: '9000000013', source: 'Counter',
      fulfilment: 'At the shop', payment: 'Cash', address: 'HOST retained address', lines: const []);
    await local.save(draft, expectedRevision: null);
    final before = Map<String, String>.of(await storage.readAll());
    final session = WorkSession(gateway: ReviewWorkGateway(), contactDraftStore: _HostCounterAccount(), counterDraftStore: local)
      ..activeWorkspace = const WorkWorkspace(id: hostStore, name: 'HOST isolated Store',
        profileLabel: 'HOST grocery', profileId: 'retailer-grocery', area: 'HOST area', verified: true);
    addTearDown(session.dispose);
    session.startNewWorkspaceOrder(); await session.loadWorkspaceCounterDraft();
    expect(session.counterDraftEditingBlocked, false);
    expect(await session.saveWorkspaceCounterDraft(), true);
    expect(await storage.readAll(), before);
    expect((await local.read(hostAccount, hostStore))!.revision, 1);
    session.updateWorkspaceCounterDetails(address: 'HOST actual edit'); await session.workspaceCounterDraftWrites;
    expect((await local.read(hostAccount, hostStore))!.revision, 2);
    expect((await local.read(hostAccount, hostStore))!.address, 'HOST actual edit');
  });
  test('AGG06 unchanged Counter save refuses a newer original instead of silently overwriting it', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final local = SecureWorkCounterDraftStore(accountScope: () => hostAccount);
    WorkspaceCounterDraft draft(int revision, String address) => WorkspaceCounterDraft(account: hostAccount, store: hostStore,
      id: 'HOST-retained-bill', revision: revision, stage: WorkspaceCounterDraftStage.editing,
      customer: '9000000013', source: 'Counter', fulfilment: 'At the shop', payment: 'Cash', address: address, lines: const []);
    await local.save(draft(1, 'HOST retained address'), expectedRevision: null);
    final session = WorkSession(gateway: ReviewWorkGateway(), contactDraftStore: _HostCounterAccount(), counterDraftStore: local)
      ..activeWorkspace = const WorkWorkspace(id: hostStore, name: 'HOST isolated Store',
        profileLabel: 'HOST grocery', profileId: 'retailer-grocery', area: 'HOST area', verified: true);
    addTearDown(session.dispose);
    session.startNewWorkspaceOrder(); await session.loadWorkspaceCounterDraft();
    await local.save(draft(2, 'HOST newer separate editor'), expectedRevision: 1);
    expect(await session.saveWorkspaceCounterDraft(), false);
    expect((await local.read(hostAccount, hostStore))!.address, 'HOST newer separate editor');
    expect((await local.read(hostAccount, hostStore))!.revision, 2);
    expect(session.workspaceInvoices, isEmpty);
  });
  test('AGG06 Counter original connector is negotiated, owner-scoped and retired without local fallback', () async {
    final transport = _HostCounterTransport();
    AuthenticatedWorkspaceCatalogueGateway connection(bool enabled) => AuthenticatedWorkspaceCatalogueGateway(
      endpoint: Uri.parse('https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
      credentials: _HostCounterCredentials(), transport: transport, realm: 'evaluation',
      counterOriginalSupported: enabled, now: () => serviceNow);
    expect(connection(false).originalCounterDraftSource(accountId: hostAccount, storeId: hostStore, current: () => true), isNull);
    final enabled = connection(true), owner = enabled.forOwnerAccount(hostAccount);
    expect(owner.counterOriginalSupported, true);
    var active = true;
    final source = enabled.originalCounterDraftSource(accountId: hostAccount, storeId: hostStore, current: () => active)!;
    expect((await source.read()).currentDraft!.account, hostAccount);
    expect(transport.requests.single['actorAccountId'], hostAccount);
    expect(transport.requests.single['storeId'], hostStore);
    expect(transport.requests.single['operation'], 'readStoreCounterDraft');
    active = false;
    await expectLater(source.read(), throwsA(isA<WorkspaceCounterOriginalRequestFailure>()));
    expect(transport.requests.length, 1);
  });
  test('AGG06 Counter original draft cannot enter legacy local sale completion without original Stock confirmation', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final local = SecureWorkCounterDraftStore(accountScope: () => hostAccount);
    final source = WorkspaceCounterOriginalRemoteSource(scope: hostScope, connectionId: 'HOST-source', now: () => serviceNow,
      current: () => true, request: (body, current, {required mutation, onDispatch}) async {
        expect(mutation, false);
        return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': hostCounterReadback(missing: true)}));
      });
    final original = await RemoteWorkCounterDraftStore.openOriginal(source: source, retainedLocal: local,
      assertNoPendingLocalOperations: () async {});
    final session = WorkSession(gateway: ReviewWorkGateway(), contactDraftStore: _HostCounterAccount(), counterDraftStore: original)
      ..activeWorkspace = const WorkWorkspace(id: hostStore, name: 'HOST isolated Store',
        profileLabel: 'HOST grocery', profileId: 'retailer-grocery', area: 'HOST area', verified: true);
    addTearDown(session.dispose);
    final before = Map<String, String>.of(await const FlutterSecureStorage().readAll());
    expect(session.workspaceOriginalCounterConfigured, true);
    expect(await session.submitWorkspaceCounterBill(), isNull);
    expect(session.workspaceInvoices, isEmpty); expect(session.workspaceOrders, isEmpty);
    expect(await const FlutterSecureStorage().readAll(), before);
  });
  test('AGG06 forcing Counter refresh stays read-only while only the explicit Retry resends pending input', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final local = SecureWorkCounterDraftStore(accountScope: () => hostAccount), operations = <String>[];
    var permitSave = false, committed = false;
    final original = WorkspaceCounterOriginalIntent(scope: hostScope, expectedRevision: null, idempotencyKey: 'HOST-pending-native-save',
      draft: WorkspaceCounterDraft(account: hostAccount, store: hostStore, id: 'HOST-pending-bill', revision: 1,
        stage: WorkspaceCounterDraftStage.editing, customer: '9000000013', source: 'Counter', fulfilment: 'At the shop',
        payment: 'Cash', address: '', lines: const []));
    final source = WorkspaceCounterOriginalRemoteSource(scope: hostScope, connectionId: 'HOST-source', now: () => serviceNow,
      current: () => true, request: (body, current, {required mutation, onDispatch}) async {
        operations.add(body['operation']! as String);
        if (mutation) {
          if (!permitSave) throw StateError('A refresh must not dispatch Save.');
          expect(body['fingerprint'], original.fingerprint); expect(body['wire'], original.toJson()['wire']);
          onDispatch?.call(); committed = true;
        }
        final data = committed ? hostCounterReadback(original: original) : hostCounterReadback(missing: true);
        if (body['operation'] == 'readStoreCounterDraft') data['attempt'] = null;
        return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': data}));
      });
    final remote = await RemoteWorkCounterDraftStore.openOriginal(source: source, retainedLocal: local,
      assertNoPendingLocalOperations: () async {});
    await remote.controller.journal.retain(original); operations.clear();
    final session = WorkSession(gateway: ReviewWorkGateway(), contactDraftStore: _HostCounterAccount(), counterDraftStore: remote)
      ..activeWorkspace = const WorkWorkspace(id: hostStore, name: 'HOST isolated Store',
        profileLabel: 'HOST grocery', profileId: 'retailer-grocery', area: 'HOST area', verified: true);
    addTearDown(session.dispose);
    await session.loadWorkspaceCounterDraft(retry: true);
    expect(operations, ['readStoreCounterDraftAttempt']);
    expect(session.counterDraftLoaded, false);
    expect((await remote.controller.journal.pending())!.toJson(), original.toJson());
    permitSave = true; operations.clear();
    expect(await session.retryWorkspaceCounterDraft(), true);
    expect(operations, ['readStoreCounterDraftAttempt', 'saveStoreCounterDraft', 'readStoreCounterDraft']);
    expect(await remote.controller.journal.pending(), isNull);
    expect(session.retainedCounterDraft!.toJson(), original.draft.toJson());
  });
  test('AGG06 native Counter original command freezes exact scope and serializer without financial outcomes', () {
    final original = hostCounterIntent(), snapshot = original.toJson();
    expect(snapshot['fingerprint'], original.fingerprint);
    ((snapshot['wire'] as Map)['draft'] as Map)['customer'] = 'HOST mutated caller copy';
    expect(original.draft.customer, 'HOST unfinished customer');
    expect(WorkspaceCounterOriginalIntent.fromJson(original.toJson(), hostScope).toJson(), original.toJson());
    final changed = original.toJson(); changed['idempotencyKey'] = 'HOST-different-key';
    expect(() => WorkspaceCounterOriginalIntent.fromJson(changed, hostScope), throwsFormatException);
    expect(() => WorkspaceCounterOriginalIntent(scope: hostScope, draft: hostCounterDraft(revision: 2),
      expectedRevision: null, idempotencyKey: 'HOST-bad-revision'), throwsFormatException);
    expect(() => WorkspaceCounterOriginalIntent.fromJson(original.toJson(),
      (account: hostAccount, store: hostStore, realm: 'production')), throwsFormatException);
  });
  test('AGG06 native Counter original readback distinguishes empty, exact current source and historical save', () {
    final original = hostCounterIntent();
    expect(WorkspaceCounterOriginalReadback.decode(hostCounterReadback(missing: true), hostScope, serviceNow).currentDraft, isNull);
    final decoded = WorkspaceCounterOriginalReadback.decode(hostCounterReadback(original: original), hostScope, serviceNow, original: original);
    expect(decoded.saved, true); expect(decoded.refused, false);
    expect(decoded.currentDraft!.toJson(), original.draft.toJson());
    expect(() => WorkspaceCounterOriginalReadback.decode(hostCounterReadback(original: original), hostScope, serviceNow), throwsFormatException);
  });
  test('AGG06 native Counter original parser rejects foreign, stale, corrupted and invented-success responses', () {
    final original = hostCounterIntent(), base = hostCounterReadback(original: original);
    for (final change in [<String, Object?>{'actorAccountId': 'HOST-other'}, {'storeId': 'HOST-other'},
      {'realm': 'production'}, {'state': 'posted'}, {'draftFingerprint': '0' * 64},
      {'observedAt': '2026-10-30T00:00:00.000Z'}, {'state': 'empty', 'draftJson': null, 'draftFingerprint': null}]) {
      expect(() => WorkspaceCounterOriginalReadback.decode({...base, ...change}, hostScope, serviceNow, original: original), throwsFormatException);
    }
    for (final change in [<String, Object?>{'fingerprint': '0' * 64}, {'idempotencyKey': 'HOST-other'},
      {'status': 'posted'}, {'resultRevision': null}, {'resultRevision': '2'},
      {'recordedAt': '2026-10-30T01:01:00.000Z'}, {'status': 'not_saved', 'reason': 'stale_draft', 'changed': true}]) {
      final response = hostCounterReadback(original: original);
      response['attempt'] = {...response['attempt']! as Map<String, Object?>, ...change};
      expect(() => WorkspaceCounterOriginalReadback.decode(response, hostScope, serviceNow, original: original), throwsFormatException);
    }
    final changed = hostCounterReadback(original: original), wire = workspaceCounterDraftToOriginalWire(original.draft, hostScope);
    (wire['draft'] as Map)['address'] = 'HOST different same-version input';
    changed['draftJson'] = workspaceLedgerCanonical(wire); changed['draftFingerprint'] = workspaceLedgerFingerprint(wire);
    expect(() => WorkspaceCounterOriginalReadback.decode(changed, hostScope, serviceNow, original: original), throwsFormatException);
  });
  test('AGG06 native original Counter read/status remain read-only and Save binds exact command', () async {
    final original = hostCounterIntent(), requests = <Map<String, Object?>>[], modes = <bool>[];
    final remote = WorkspaceCounterOriginalRemoteSource(scope: hostScope, connectionId: 'HOST-original-connection',
      current: () => true, now: () => serviceNow,
      request: (body, current, {required mutation, onDispatch}) async {
        expect(current(), true); requests.add(body); modes.add(mutation); onDispatch?.call();
        return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true,
          'data': hostCounterReadback(original: body['operation'] == 'readStoreCounterDraft' ? null : original)}));
      });
    await remote.read(); expect((await remote.save(original)).saved, true); await remote.status(original);
    expect(modes, [false, true, false]);
    expect(requests.map((v) => v['operation']), ['readStoreCounterDraft', 'saveStoreCounterDraft', 'readStoreCounterDraftAttempt']);
    expect(requests[1]['wire'], original.toJson()['wire']);
    expect(requests[1]['expectedRevision'], isNull);
    expect(requests[2].containsKey('wire'), false); expect(requests[2].containsKey('expectedRevision'), false);
  });
  test('AGG06 native original Counter transport keeps dispatch ambiguity and retires stale callbacks', () async {
    final original = hostCounterIntent();
    for (final dispatched in [false, true]) {
      final remote = WorkspaceCounterOriginalRemoteSource(scope: hostScope, connectionId: 'HOST-original-connection',
        current: () => true, now: () => serviceNow, request: (body, current, {required mutation, onDispatch}) async {
          if (dispatched) onDispatch?.call(); throw TimeoutException('HOST isolated lost response');
        });
      await expectLater(remote.save(original), throwsA(isA<WorkspaceCounterOriginalRequestFailure>()
        .having((failure) => failure.mayHaveCommitted, 'mayHaveCommitted', dispatched)));
    }
    var active = true, calls = 0;
    final pending = Completer<SocialContentResponse?>();
    final remote = WorkspaceCounterOriginalRemoteSource(scope: hostScope, connectionId: 'HOST-original-connection',
      current: () => active, now: () => serviceNow, request: (body, current, {required mutation, onDispatch}) {
        calls++; onDispatch?.call(); return pending.future;
      });
    final result = remote.save(original); active = false;
    pending.complete(SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': hostCounterReadback(original: original)})));
    await expectLater(result, throwsA(isA<WorkspaceCounterOriginalRequestFailure>().having((e) => e.mayHaveCommitted, 'unknown original result', true)));
    remote.retire();
    await expectLater(remote.read(), throwsA(isA<WorkspaceCounterOriginalRequestFailure>().having((e) => e.mayHaveCommitted, 'read cannot save', false)));
    expect(calls, 1);
  });
  test('AGG06 encrypted Counter journal requires explicit binding and preserves pending identity across restart', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final original = hostCounterIntent();
    SecureWorkspaceCounterOriginalJournal journal({String connection = 'HOST-source'}) =>
      SecureWorkspaceCounterOriginalJournal(scope: hostScope, connectionId: connection, current: () => true);
    await expectLater(journal().pending(), throwsStateError);
    await expectLater(journal().retain(original), throwsStateError);
    expect(await journal().bound, false);
    await journal().bindConfirmedOriginal();
    await journal().retain(original); await journal().retain(original);
    expect((await journal().pending())!.toJson(), original.toJson());
    final other = WorkspaceCounterOriginalIntent(scope: hostScope, draft: hostCounterDraft(),
      expectedRevision: null, idempotencyKey: 'HOST-other-save');
    await expectLater(journal().retain(other), throwsStateError);
    await expectLater(journal(connection: 'HOST-other-endpoint').pending(), throwsFormatException);
    final result = WorkspaceCounterOriginalReadback.decode(hostCounterReadback(original: original), hostScope, serviceNow, original: original);
    await journal().resolve(original, result);
    expect(await journal().pending(), isNull);
    await expectLater(journal().retain(original), throwsStateError);
    expect(await journal().bound, true);
  });
  test('AGG06 Counter journal retains unknown input when transport fails and resolves exact original status after restart', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final original = hostCounterIntent(), calls = <String>[];
    var acknowledge = false;
    final remote = WorkspaceCounterOriginalRemoteSource(scope: hostScope, connectionId: 'HOST-source',
      now: () => serviceNow, current: () => true, request: (body, current, {required mutation, onDispatch}) async {
        calls.add(body['operation']! as String); onDispatch?.call();
        if (mutation) throw TimeoutException('HOST committed result with lost acknowledgement');
        final data = acknowledge ? hostCounterReadback(original: original) : hostCounterReadback();
        return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': data}));
      });
    SecureWorkspaceCounterOriginalJournal journal() => SecureWorkspaceCounterOriginalJournal(scope: hostScope,
      connectionId: 'HOST-source', current: () => remote.current);
    await journal().bindConfirmedOriginal();
    await expectLater(WorkspaceCounterOriginalController(source: remote, journal: journal()).save(original),
      throwsA(isA<WorkspaceCounterOriginalRequestFailure>().having((e) => e.mayHaveCommitted, 'unknown', true)));
    expect((await journal().pending())!.fingerprint, original.fingerprint);
    final restarted = WorkspaceCounterOriginalController(source: remote, journal: journal());
    await expectLater(restarted.read(), throwsStateError);
    expect(calls, ['saveStoreCounterDraft', 'readStoreCounterDraftAttempt']);
    expect((await restarted.recover()).attempt, isNull);
    expect((await journal().pending())!.idempotencyKey, original.idempotencyKey);
    acknowledge = true;
    final recovered = await restarted.read(); expect(recovered.saved, true);
    expect(await journal().pending(), isNull);
    expect(calls.where((value) => value == 'saveStoreCounterDraft').length, 1);
  });
  test('AGG06 Counter explicit retry checks status before resending the exact frozen input', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final original = hostCounterIntent(), calls = <String>[];
    final remote = WorkspaceCounterOriginalRemoteSource(scope: hostScope, connectionId: 'HOST-source',
      now: () => serviceNow, current: () => true, request: (body, current, {required mutation, onDispatch}) async {
        calls.add(body['operation']! as String); onDispatch?.call();
        if (mutation) {
          expect(body['wire'], original.toJson()['wire']); expect(body['fingerprint'], original.fingerprint);
          expect(body['idempotencyKey'], original.idempotencyKey);
        }
        return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true,
          'data': hostCounterReadback(original: mutation ? original : null)}));
      });
    final journal = SecureWorkspaceCounterOriginalJournal(scope: hostScope, connectionId: 'HOST-source', current: () => remote.current);
    await journal.bindConfirmedOriginal(); await journal.retain(original);
    final controller = WorkspaceCounterOriginalController(source: remote, journal: journal);
    expect((await controller.recover()).attempt, isNull); expect(calls.length, 1);
    expect((await controller.recover(retry: true)).saved, true);
    expect(calls, ['readStoreCounterDraftAttempt', 'readStoreCounterDraftAttempt', 'saveStoreCounterDraft']);
    expect(await journal.pending(), isNull);
  });
  test('AGG06 native original Counter adoption refuses retained local bills without clearing data', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final local = SecureWorkCounterDraftStore(accountScope: () => hostAccount);
    await local.save(hostCounterDraft(), expectedRevision: null);
    final remote = WorkspaceCounterOriginalRemoteSource(scope: hostScope, connectionId: 'HOST-source',
      current: () => true, now: () => serviceNow, request: (body, current, {required mutation, onDispatch}) async {
        expect(mutation, false);
        return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': hostCounterReadback(missing: true)}));
      });
    await expectLater(RemoteWorkCounterDraftStore.openOriginal(source: remote, retainedLocal: local,
      assertNoPendingLocalOperations: () async {}), throwsA(isA<WorkGatewayException>()));
    expect((await local.read(hostAccount, hostStore))!.toJson(), hostCounterDraft().toJson());
    expect(await SecureWorkspaceCounterOriginalJournal(scope: hostScope, connectionId: 'HOST-source', current: () => true).bound, false);
  });
  test('AGG06 original Counter binding prevents local fallback and survives controller restart', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final local = SecureWorkCounterDraftStore(accountScope: () => hostAccount);
    final source = WorkspaceCounterOriginalRemoteSource(scope: hostScope, connectionId: 'HOST-source',
      current: () => true, now: () => serviceNow, request: (body, current, {required mutation, onDispatch}) async {
        expect(mutation, false);
        return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': hostCounterReadback()}));
      });
    final original = await RemoteWorkCounterDraftStore.openOriginal(source: source, retainedLocal: local,
      assertNoPendingLocalOperations: () async {});
    expect((await original.read(hostAccount, hostStore))!.toJson(), hostCounterDraft().toJson());
    await expectLater(local.read(hostAccount, hostStore), throwsA(isA<WorkGatewayException>()));
    await expectLater(local.save(hostCounterDraft(), expectedRevision: null), throwsA(isA<WorkGatewayException>()));
    final reopened = await RemoteWorkCounterDraftStore.openOriginal(source: source, retainedLocal: local,
      assertNoPendingLocalOperations: () async {fail('Existing original binding must not re-adopt local records.');});
    expect((await reopened.read(hostAccount, hostStore))!.revision, 1);
    source.retire();
    await expectLater(reopened.read(hostAccount, hostStore), throwsA(isA<WorkGatewayException>()));
  });
  test('AGG06 Counter adoption shares the existing local write queue and cannot race a delayed local save', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final local = SecureWorkCounterDraftStore(accountScope: () => hostAccount), entered = Completer<void>(), release = Completer<void>();
    final source = WorkspaceCounterOriginalRemoteSource(scope: hostScope, connectionId: 'HOST-source',
      current: () => true, now: () => serviceNow, request: (body, current, {required mutation, onDispatch}) async =>
        SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': hostCounterReadback(missing: true)})));
    final opening = RemoteWorkCounterDraftStore.openOriginal(source: source, retainedLocal: local,
      assertNoPendingLocalOperations: () async {entered.complete(); await release.future;});
    await entered.future;
    final saving = expectLater(local.save(hostCounterDraft(), expectedRevision: null), throwsA(isA<WorkGatewayException>()));
    release.complete(); await opening; await saving;
    expect(await SecureWorkspaceCounterOriginalJournal(scope: hostScope, connectionId: 'HOST-source', current: () => true).bound, true);
  });
  test('AGG06 original Counter source unavailable before adoption does not bind or retire the local route', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final local = SecureWorkCounterDraftStore(accountScope: () => hostAccount);
    final source = WorkspaceCounterOriginalRemoteSource(scope: hostScope, connectionId: 'HOST-source',
      current: () => true, request: (body, current, {required mutation, onDispatch}) async => const SocialContentResponse(statusCode: 503, body: '{}'));
    await expectLater(RemoteWorkCounterDraftStore.openOriginal(source: source, retainedLocal: local,
      assertNoPendingLocalOperations: () async {}), throwsA(isA<WorkspaceCounterOriginalRequestFailure>()));
    expect(await local.read(hostAccount, hostStore), isNull);
    await local.save(hostCounterDraft(), expectedRevision: null);
    expect((await local.read(hostAccount, hostStore))!.revision, 1);
  });
  test('AGG06 original Counter store acknowledges exact native int64 draft without applying finance-only limits', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final local = SecureWorkCounterDraftStore(accountScope: () => hostAccount);
    final source = WorkspaceCounterOriginalRemoteSource(scope: hostScope, connectionId: 'HOST-source',
      current: () => true, now: () => serviceNow, request: (body, current, {required mutation, onDispatch}) async {
        onDispatch?.call();
        if (!mutation) return SocialContentResponse(statusCode: 200,
          body: jsonEncode({'ok': true, 'data': hostCounterReadback(missing: true)}));
        final original = WorkspaceCounterOriginalIntent.fromJson({'operation': body['operation'],
          'scope': {'account': hostAccount, 'store': hostStore, 'realm': 'evaluation'},
          for (final key in ['expectedRevision', 'idempotencyKey', 'fingerprint', 'wire']) key: body[key]}, hostScope);
        return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': hostCounterReadback(original: original)}));
      });
    final original = await RemoteWorkCounterDraftStore.openOriginal(source: source, retainedLocal: local,
      assertNoPendingLocalOperations: () async {});
    final draft = hostCounterDraft(large: true);
    await original.save(draft, expectedRevision: null);
    expect(await original.controller.journal.pending(), isNull);
  });
  test('AGG06 a definitively refused Counter draft permits a separately reviewed corrected input without reusing its identity', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final local = SecureWorkCounterDraftStore(accountScope: () => hostAccount), keys = <String>[];
    final currentJson = hostCounterDraft().toJson()
      ..['stage'] = 'submitting' ..['customer'] = '9000000013' ..['submissionOrderId'] = 'HOST-original-order';
    final currentDraft = WorkspaceCounterDraft.fromJson(currentJson)!;
    final nextJson = {...currentJson, 'revision': 2, 'stage': 'reviewRequired'};
    final correct = WorkspaceCounterDraft.fromJson(nextJson)!, wrong = WorkspaceCounterDraft.fromJson({...nextJson, 'address': 'HOST changed recovery input'})!;
    final source = WorkspaceCounterOriginalRemoteSource(scope: hostScope, connectionId: 'HOST-source',
      current: () => true, now: () => serviceNow, request: (body, current, {required mutation, onDispatch}) async {
        if (!mutation) {
          final data = hostCounterReadback();
          final wire = workspaceCounterDraftToOriginalWire(currentDraft, hostScope);
          data['draftJson'] = workspaceLedgerCanonical(wire); data['draftFingerprint'] = workspaceLedgerFingerprint(wire);
          return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': data}));
        }
        keys.add(body['idempotencyKey']! as String); onDispatch?.call();
        final input = WorkspaceCounterOriginalIntent.fromJson({'operation': body['operation'],
          'scope': {'account': hostAccount, 'store': hostStore, 'realm': 'evaluation'},
          for (final key in ['expectedRevision', 'idempotencyKey', 'fingerprint', 'wire']) key: body[key]}, hostScope);
        final response = hostCounterReadback(original: input);
        if (keys.length == 1) {
          final wire = workspaceCounterDraftToOriginalWire(currentDraft, hostScope);
          response['draftJson'] = workspaceLedgerCanonical(wire); response['draftFingerprint'] = workspaceLedgerFingerprint(wire);
          response['attempt'] = {...response['attempt']! as Map<String, Object?>, 'status': 'not_saved',
            'reason': 'recovery_input_changed', 'changed': false, 'resultRevision': '1'};
        }
        return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': response}));
      });
    final remote = await RemoteWorkCounterDraftStore.openOriginal(source: source, retainedLocal: local,
      assertNoPendingLocalOperations: () async {});
    await expectLater(remote.save(wrong, expectedRevision: 1), throwsA(isA<WorkGatewayException>()));
    expect(await remote.controller.journal.pending(), isNull, reason: 'Refusal is terminal; its input is not an unknown save.');
    await remote.save(correct, expectedRevision: 1);
    expect(keys.length, 2); expect(keys[0], isNot(keys[1]));
    expect(await remote.controller.journal.pending(), isNull);
  });
  test('AGG06 changed Counter input cannot bypass an unknown frozen save through a different content identity', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final local = SecureWorkCounterDraftStore(accountScope: () => hostAccount), posts = <Map<String, Object?>>[];
    var acknowledge = false;
    final source = WorkspaceCounterOriginalRemoteSource(scope: hostScope, connectionId: 'HOST-source',
      current: () => true, now: () => serviceNow, request: (body, current, {required mutation, onDispatch}) async {
        if (!mutation) return SocialContentResponse(statusCode: 200,
          body: jsonEncode({'ok': true, 'data': hostCounterReadback(missing: true)}));
        posts.add(body); onDispatch?.call();
        if (!acknowledge) throw TimeoutException('HOST unknown original save');
        final original = WorkspaceCounterOriginalIntent.fromJson({'operation': body['operation'],
          'scope': {'account': hostAccount, 'store': hostStore, 'realm': 'evaluation'},
          for (final key in ['expectedRevision', 'idempotencyKey', 'fingerprint', 'wire']) key: body[key]}, hostScope);
        return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': hostCounterReadback(original: original)}));
      });
    final remote = await RemoteWorkCounterDraftStore.openOriginal(source: source, retainedLocal: local,
      assertNoPendingLocalOperations: () async {});
    await expectLater(remote.save(hostCounterDraft(), expectedRevision: null), throwsA(isA<WorkspaceCounterOriginalRequestFailure>()));
    final frozen = (await remote.controller.journal.pending())!.toJson();
    final changed = WorkspaceCounterDraft.fromJson({...hostCounterDraft().toJson(), 'address': 'HOST later edit'})!;
    await expectLater(remote.save(changed, expectedRevision: null), throwsStateError);
    expect(posts.length, 1); expect((await remote.controller.journal.pending())!.toJson(), frozen);
    acknowledge = true;
    expect((await remote.recover(explicitRetry: true))!.toJson(), hostCounterDraft().toJson());
    expect(posts.length, 2); expect(posts[1], posts[0]);
    expect(await remote.controller.journal.pending(), isNull);
  });
  const serviceCapture = String.fromEnvironment('AGG06_COUNTER_SERVICE_CAPTURE_PATH');
  test('AGG06 actual SDK Counter service crosses exact native transport and recovers old receipt with current source', () async {
    final capture = jsonDecode(File('$serviceCapture.json').readAsStringSync()) as Map<String, dynamic>;
    expect(capture['label'], 'ISOLATED HOST ACTUAL SDK COUNTER SERVICE; NO PHONE AUTHORITY');
    final original = WorkspaceCounterOriginalIntent.fromJson(capture['command'], hostScope);
    final decoded = WorkspaceCounterOriginalReadback.decode(capture['response'], hostScope, serviceNow, original: original);
    expect(decoded.saved, true); expect(original.draft.revision, 1); expect(decoded.currentDraft!.revision, 2);
    expect(decoded.currentDraft!.address, 'HOST newer entered address');
    final remote = WorkspaceCounterOriginalRemoteSource(scope: hostScope, connectionId: 'HOST-captured-service',
      now: () => serviceNow, current: () => true, request: (body, current, {required mutation, onDispatch}) async {
        expect(mutation, false); expect(body['operation'], 'readStoreCounterDraftAttempt');
        return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': capture['response']}));
      });
    expect((await remote.status(original)).currentDraft!.revision, 2);
  }, skip: serviceCapture.isEmpty ? 'Requires explicitly captured isolated actual SDK service' : false);
  const counterExport = String.fromEnvironment('AGG06_COUNTER_WIRE_NATIVE_EXPORT_PATH');
  const backendCounterExport = String.fromEnvironment('AGG06_COUNTER_WIRE_BACKEND_EXPORT_PATH');
  for (final variant in ['plain', 'int64', 'revision64']) {
    test('AGG06 validated backend Counter format returns exact native JSON: $variant', () {
      final vector = jsonDecode(File('$backendCounterExport.$variant.json').readAsStringSync()) as Map<String, dynamic>;
      expect(vector['label'], 'ISOLATED HOST VALIDATED COUNTER FORMAT; NO ORIGINAL AUTHORITY');
      expect(vector['scope'], {'account': hostAccount, 'store': hostStore, 'realm': 'evaluation'});
      final original = workspaceCounterDraftFromOriginalWire(vector['wire'], hostScope);
      expect(jsonEncode(original.toJson()), vector['nativeJson']);
      expect(original.billingDetails.businessName, 'HOST વેપાર');
      expect(original.billingDetails.gst, '');
    }, skip: backendCounterExport.isEmpty ? 'Requires explicit isolated validated Counter format vectors' : false);
  }
  test('AGG06 Counter wire preserves exact native int64 draft and entered billing text', () {
    for (final original in [hostCounterDraft(), hostCounterDraft(large: true),
      hostCounterDraft(large: true, revision: 9223372036854775807)]) {
      final wire = workspaceCounterDraftToOriginalWire(original, hostScope);
      final transported = jsonDecode(jsonEncode(wire));
      final decoded = workspaceCounterDraftFromOriginalWire(transported, hostScope);
      expect(jsonEncode(decoded.toJson()), jsonEncode(original.toJson()));
      expect(decoded.lines.single.lineTotalPaise, original.lines.single.lineTotalPaise);
      expect(decoded.revision, original.revision);
      expect(decoded.billingDetails.gst, '');
      expect(decoded.billingDetails.businessName, 'HOST વેપાર');
      expect((wire['draft'] as Map)['revision'], original.revision.toString());
      expect(((wire['draft'] as Map)['lines'] as List).single['lineTotalPaise'],
        original.lines.single.lineTotalPaise.toString());
    }
  });
  test('AGG06 Counter wire rejects rounded numbers, unknown fields and foreign owner without changing input', () {
    final original = workspaceCounterDraftToOriginalWire(hostCounterDraft(large: true), hostScope);
    final mutations = <void Function(Map<String, dynamic>)>[
      (wire) => (wire['draft'] as Map)['revision'] = 1,
      (wire) => (wire['draft'] as Map)['availableSettlementMinor'] = 0,
      (wire) => (wire['draft'] as Map).remove('billingDetails'),
      (wire) => ((wire['draft'] as Map)['discount'] as Map)['value'] = '-0',
      (wire) => (((wire['draft'] as Map)['lines'] as List).single as Map)['lineTotalPaise'] = '9223372036854775808',
      (wire) => (wire['draft'] as Map)['source'] = 'App',
      (wire) => (wire['draft'] as Map)['submissionOrderId'] = 'HOST-unconfirmed-order',
    ];
    for (final mutate in mutations) {
      final wire = jsonDecode(jsonEncode(original)) as Map<String, dynamic>;
      mutate(wire);
      final before = jsonEncode(wire);
      expect(() => workspaceCounterDraftFromOriginalWire(wire, hostScope), throwsFormatException);
      expect(jsonEncode(wire), before);
    }
    expect(() => workspaceCounterDraftFromOriginalWire(original,
      (account: 'HOST-foreign', store: hostStore, realm: 'evaluation')), throwsFormatException);
    expect(() => workspaceCounterDraftToOriginalWire(hostCounterDraft(),
      (account: hostAccount, store: hostStore, realm: 'guessed')), throwsFormatException);
  });
  test('AGG06 Counter native format exports preserve source values without creating originals', () {
    for (final item in <String, WorkspaceCounterDraft>{'plain': hostCounterDraft(),
      'int64': hostCounterDraft(large: true),
      'revision64': hostCounterDraft(large: true, revision: 9223372036854775807)}.entries) {
      final target = File('$counterExport.${item.key}.json');
      expect(target.existsSync(), false, reason: 'Retain previous qualification artifacts.');
      target.writeAsStringSync(jsonEncode({'label': 'ISOLATED HOST NATIVE COUNTER FORMAT; NO ORIGINAL AUTHORITY',
        'scope': {'account': hostAccount, 'store': hostStore, 'realm': 'evaluation'},
        'wire': workspaceCounterDraftToOriginalWire(item.value, hostScope),
        'nativeJson': jsonEncode(item.value.toJson())}));
    }
  }, skip: counterExport.isEmpty ? 'Explicit isolated native Counter export only' : false);
  const recordExport = String.fromEnvironment('AGG06_CUSTOMER_FORMAT_EXPORT_PATH');
  for (final variant in ['baseline', 'credit', 'allocated', 'partial', 'near-limit']) {
    test('AGG06 backend pure customer format matches native capacities: $variant', () {
      final vector = jsonDecode(File('$recordExport.$variant.json').readAsStringSync()) as Map<String, dynamic>;
      expect(vector['label'], 'ISOLATED HOST CUSTOMER FORMAT; NO ORIGINAL AUTHORITY');
      final scope = vector['scope'] as Map, raw = vector['ledger'] as Map;
      expect(scope['account'], hostAccount); expect(scope['store'], hostStore);
      expect(scope['realm'], 'evaluation');
      final ledger = WorkspaceCustomerLedger.fromJson(raw);
      expect(ledger.valid, true);
      expect(ledger.accountScope, scope['account']); expect(ledger.workspaceId, scope['store']);
      expect(ledger.toJson(), raw);
      for (final entry in (vector['balances'] as Map).entries) {
        final balance = ledger.invoiceBalance(entry.key as String);
        expect(balance == null ? null : {
          'billedMinor': balance.billedMinor, 'creditedMinor': balance.creditedMinor,
          'collectedMinor': balance.collectedMinor, 'refundedMinor': balance.refundedMinor,
          'dueMinor': balance.dueMinor, 'refundableMinor': balance.refundableMinor,
          'availableCreditMinor': balance.availableCreditMinor,
        }, entry.value);
      }
      expect(ledger.receiptRemainingMinor('HOST-invoice-one', 'HOST-entry-2'), vector['receiptRemaining']);
    }, skip: recordExport.isEmpty ? 'Requires explicit isolated backend pure format vectors' : false);
  }
  test('AGG06 retained customer serialization baseline preserves exact keys, paise and UTC microseconds', () {
    final value = hostCheckpoint();
    expect(value.valid, true);
    expect(jsonEncode(checkpointCustomer(value)), jsonEncode(hostCustomerJson()));
    expect(value.finance.customerLedgers.single.invoiceBalance('HOST-invoice')!.dueMinor, 150);
  });
  test('AGG06 retained checkpoint decoder round trip preserves existing customer originals', () {
    final decoded = WorkspaceLedgerCheckpoint.fromJson(hostCheckpoint().toJson());
    expect(decoded, isNotNull);
    expect(jsonEncode(checkpointCustomer(decoded!)), jsonEncode(hostCustomerJson()));
    expect(decoded.finance.historyComplete, false);
  });
  test('AGG06 shared customer codec equals the retained checkpoint format', () {
    final ledger = hostCustomerLedger();
    expect(jsonEncode(ledger.toJson()), jsonEncode(hostCustomerJson()));
    final decoded = WorkspaceCustomerLedger.fromJson(ledger.toJson());
    expect(jsonEncode(decoded.toJson()), jsonEncode(hostCustomerJson()));
    expect(decoded.canFollow(ledger), true);
    for (var index = 0; index < ledger.entries.length; index++) {
      final raw = (hostCustomerJson()['entries'] as List)[index];
      expect(jsonEncode(ledger.entries[index].toJson()), jsonEncode(raw));
      expect(WorkspaceCustomerLedgerEntry.fromJson(raw).identityData,
        ledger.entries[index].identityData);
    }
  });
  test('AGG06 unknown opening stays unknown and cannot authorise invoice operations', () {
    final raw = {...hostCustomerJson(), 'openingBalanceMinor': null, 'historyComplete': false};
    final decoded = WorkspaceCustomerLedger.fromJson(raw);
    expect(decoded.valid, true);
    expect(decoded.openingBalanceMinor, isNull);
    expect(decoded.closingBalanceMinor, isNull);
    expect(decoded.invoiceBalance('HOST-invoice'), isNull);
    expect(decoded.toJson()['openingBalanceMinor'], isNull);
    expect(() => WorkspaceCustomerLedger.fromJson({...raw, 'historyComplete': true}),
      throwsFormatException);
  });
  test('AGG06 customer codec rejects future microseconds, overflow and changed posted history', () {
    expect(() => WorkspaceCustomerLedger.fromJson({...hostCustomerJson(),
      'asOf': '2026-10-30T01:00:00.000001Z'}), throwsFormatException);
    final raw = jsonDecode(jsonEncode(hostCustomerJson())) as Map<String, dynamic>;
    (raw['entries'] as List).first['amountMinor'] = 9007199254740992;
    expect(() => WorkspaceCustomerLedger.fromJson(raw), throwsFormatException);
    final changed = jsonDecode(jsonEncode(hostCustomerJson())) as Map<String, dynamic>;
    (changed['entries'] as List).last['paymentReference'] = 'HOST changed original';
    final decoded = WorkspaceCustomerLedger.fromJson(changed);
    expect(decoded.canFollow(hostCustomerLedger()), false);
  });
  test('AGG06 shared event codec retains original return and refund documents', () {
    final refund = WorkspaceCustomerRefund(accountScope: hostAccount, workspaceId: hostStore,
      customerId: 'HOST-customer-one', invoiceId: 'HOST-invoice', orderId: 'HOST-counter-order',
      operationId: 'HOST-refund', expectedRevision: 2, amountMinor: 50,
      channel: WorkspacePaymentChannel.cash, reference: 'HOST cash returned',
      sourceCollectionId: 'HOST-collection-entry');
    final returned = WorkspaceCustomerReturn(accountScope: hostAccount, workspaceId: hostStore,
      customerId: 'HOST-customer-one', invoiceId: 'HOST-invoice', orderId: 'HOST-counter-order',
      operationId: 'HOST-return', expectedRevision: 2, reason: 'HOST physical return', reasonCode: 'damaged',
      lines: const [WorkspaceCustomerReturnLine(productId: 'HOST-original-sku', quantity: 2, restockQuantity: 1)]);
    final events = [
      WorkspaceCustomerLedgerEntry(id: 'HOST-refund-event', operationId: refund.operationId,
        invoiceId: refund.invoiceId, orderId: refund.orderId, sequence: 3, occurredAt: hostAsOf,
        kind: WorkspaceLedgerEntryKind.refund, state: WorkspaceLedgerPostingState.posted,
        amountMinor: refund.amountMinor, channel: refund.channel, paymentReference: refund.reference, customerRefund: refund),
      WorkspaceCustomerLedgerEntry(id: 'HOST-return-event', operationId: returned.operationId,
        invoiceId: returned.invoiceId, orderId: returned.orderId, sequence: 3, occurredAt: hostAsOf,
        kind: WorkspaceLedgerEntryKind.creditNote, state: WorkspaceLedgerPostingState.posted,
        amountMinor: 50, customerReturn: returned),
    ];
    for (final event in events) {
      expect(event.valid, true);
      final raw = event.toJson(), decoded = WorkspaceCustomerLedgerEntry.fromJson(raw);
      expect(jsonEncode(decoded.toJson()), jsonEncode(raw));
      expect(decoded.identityData, event.identityData);
    }
  });
  test('AGG06 customer codec does not truncate a long original event history', () {
    final entries = [for (var index = 1; index <= 1001; index++)
      WorkspaceCustomerLedgerEntry(id: 'HOST-event-$index', operationId: 'HOST-operation-$index',
        invoiceId: 'HOST-invoice-$index', orderId: 'HOST-order-$index', sequence: index,
        occurredAt: hostAsOf, kind: WorkspaceLedgerEntryKind.invoice,
        state: WorkspaceLedgerPostingState.posted, amountMinor: 1)];
    final ledger = WorkspaceCustomerLedger(accountScope: hostAccount, workspaceId: hostStore,
      customerId: 'HOST-long-history', customerName: 'HOST long history', revision: 1001,
      asOf: hostAsOf, openingBalanceMinor: 0, historyComplete: true, entries: entries);
    final decoded = WorkspaceCustomerLedger.fromJson(ledger.toJson());
    expect(decoded.entries.length, 1001);
    expect(decoded.closingBalanceMinor, 1001);
    expect(decoded.invoiceBalance('HOST-invoice-1001')!.dueMinor, 1);
  });
}
