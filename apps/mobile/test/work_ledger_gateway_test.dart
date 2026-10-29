import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:moolsocial/features/shared/social_content_gateway.dart';
import 'package:moolsocial/features/work/work_ledger_gateway.dart';
import 'package:moolsocial/features/work/work_models.dart' show WorkspacePurchaseEntryBook;
import 'package:moolsocial/features/work/work_purchase_entry_gateway.dart';
import 'package:moolsocial/features/work/work_services.dart' show SecureWorkLedgerCheckpointStore, WorkGatewayException, RemoteWorkOwnedLedgerStore;
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
}
