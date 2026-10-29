import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:moolsocial/features/shared/social_content_gateway.dart';
import 'package:moolsocial/features/work/work_catalogue_gateway.dart';
import 'package:moolsocial/features/work/work_models.dart';
import 'package:moolsocial/features/work/work_purchase_entry_gateway.dart';
import 'package:moolsocial/features/work/work_services.dart';

import 'work_catalogue_gateway_test.dart' show Credentials, Transport;

const _scope = (account: 'HOST-account', store: 'HOST-store', realm: 'evaluation');
final _now = DateTime.utc(2026, 10, 29, 1);
WorkspaceSupplierProfile _profile({String name = 'HOST labelled supplier'}) => WorkspaceSupplierProfile(
  id: 'HOST-manual-supplier', name: name, address: 'HOST billing address',
  createdAt: DateTime.parse('2026-10-29T00:00:00.123456Z'), updatedAt: DateTime.parse('2026-10-29T00:00:00.123456Z'));
WorkspaceSupplierSaveIntent _intent() => WorkspaceSupplierSaveIntent(scope: _scope, expectedRevision: null,
  idempotencyKey: 'HOST-original-save', profile: _profile());
WorkspacePurchaseEntryDraft _draft() => WorkspacePurchaseEntryDraft(id: 'HOST-manual-draft', supplierId: _profile().id,
  invoiceReference: 'HOST-BILL-1', invoiceDate: '29/10/2026', createdAt: _profile().createdAt, updatedAt: _profile().updatedAt,
  goods: const [{'productId': '', 'name': 'HOST printed item', 'pack': 'HOST pack', 'quantity': '1', 'cost': ''}]);
WorkspacePurchaseSavedCopy _copy() => WorkspacePurchaseSavedCopy(id: 'HOST-reviewed-copy', storeName: 'HOST Store',
  revision: 1, savedAt: _now, supplier: _profile(), draft: _draft(), labels: const {'name': 'HOST printed product label'});
Map<String, Object?> _frame({WorkspaceSupplierSaveIntent? original, int revision = 1, WorkspaceSupplierProfile? currentProfile}) {
  final book = WorkspacePurchaseEntryBook(account: _scope.account, store: _scope.store, qa: false,
    revision: revision, profiles: [currentProfile ?? _profile()]);
  final payload = jsonEncode(book.toJson());
  return {'schemaVersion': 1, 'purchaseEntryVersion': 1, 'actorAccountId': _scope.account,
    'storeId': _scope.store, 'realm': _scope.realm, 'observedAt': _now.toIso8601String(), 'state': 'ready',
    'bookJson': payload, 'bookFingerprint': crypto.sha256.convert(utf8.encode(payload)).toString(),
    'attempt': original == null ? null : {'schemaVersion': 1,
      'scope': {'account': _scope.account, 'store': _scope.store, 'realm': _scope.realm},
      'operation': 'saveSupplierProfile', 'idempotencyKey': original.idempotencyKey,
      'fingerprint': original.fingerprint, 'status': 'saved', 'reason': null, 'changed': true, 'resultRevision': 1,
      'profile': original.profile.toJson(), 'recordedAt': _now.toIso8601String()}};
}
SocialContentResponse _reply(Map<String, Object?> value) => SocialContentResponse(statusCode: 200,
  body: jsonEncode({'ok': true, 'data': value}));

void main() {
  setUp(() {FlutterSecureStorage.setMockInitialValues({});});
  test('AGG03 native intent retains original microseconds and guards journal scope/fingerprint', () {
    final original = _intent(), restored = WorkspaceSupplierSaveIntent.fromJson(original.toJson(), _scope);
    expect(restored.fingerprint, original.fingerprint);
    expect(restored.profile.createdAt.microsecond, 456);
    expect(restored.profile.createdAt.toIso8601String(), '2026-10-29T00:00:00.123456Z');
    expect(() => WorkspaceSupplierSaveIntent.fromJson(original.toJson(), (account: 'HOST-other', store: _scope.store, realm: _scope.realm)), throwsFormatException);
    expect(() => WorkspaceSupplierSaveIntent.fromJson({...original.toJson(), 'fingerprint': '0' * 64}, _scope), throwsFormatException);
  });
  test('AGG03 source read and historical receipt keep the independently current book', () {
    final original = _intent(), result = WorkspacePurchaseEntryReadback.decode(
      _frame(original: original, revision: 3, currentProfile: _profile(name: 'HOST later edit')), _scope, _now, original: original);
    expect(result.receipt!.resultRevision, 1);
    expect(result.receipt!.profile.name, original.profile.name);
    expect(result.book!.revision, 3);
    expect(result.book!.profiles.single.name, 'HOST later edit');
    expect(() => WorkspacePurchaseEntryReadback.decode(_frame(original: original), _scope, _now), throwsFormatException);
  });
  test('AGG03 unsupported native input is rejected before pending retention or dispatch and remains correctable', () async {
    final wire = _HostBookWire(), source = wire.source(), journal = WorkspacePurchaseEntryJournal(
      scope: _scope, connectionId: source.connectionId, current: () => source.current);
    await journal.adoptConfirmedOriginal();
    var key = 0;
    final controller = WorkspaceSupplierSaveController(source: source, journal: journal, newKey: () => 'HOST-input-${++key}');
    for (final name in ['HOST\u0000invalid', 'HOST\ud800']) {
      expect(WorkspaceSupplierSaveIntent.validationError(_profile(name: name)), isNotNull);
      await expectLater(controller.save(_profile(name: name), null), throwsFormatException);
      expect(await journal.readPending(), isNull); expect(wire.saves, 0);
    }
    expect((await controller.save(_profile(), null)).receipt!.saved, isTrue);
    expect(wire.saves, 1);
  });
  for (final change in [
    {'actorAccountId': 'HOST-other'}, {'storeId': 'HOST-other'}, {'realm': 'production'},
    {'schemaVersion': 2}, {'purchaseEntryVersion': 2}, {'unexpectedAuthority': true},
    {'bookFingerprint': '0' * 64}, {'bookJson': null}, {'state': 'empty'},
  ]) {
    test('AGG03 original frame rejects ${change.keys.single}', () {
      expect(() => WorkspacePurchaseEntryReadback.decode({..._frame(), ...change}, _scope, _now), throwsFormatException);
    });
  }
  test('AGG03 book scope and stale source cannot become a ready empty response', () {
    final value = _frame(), payload = jsonDecode(value['bookJson']! as String) as Map<String, dynamic>;
    payload['account'] = 'HOST-foreign'; value['bookJson'] = jsonEncode(payload);
    value['bookFingerprint'] = crypto.sha256.convert(utf8.encode(value['bookJson']! as String)).toString();
    expect(() => WorkspacePurchaseEntryReadback.decode(value, _scope, _now), throwsFormatException);
    expect(() => WorkspacePurchaseEntryReadback.decode(_frame(), _scope, _now.add(const Duration(seconds: 61))), throwsFormatException);
    expect(() => WorkspacePurchaseEntryReadback.decode(_frame(), _scope, _now.subtract(const Duration(seconds: 1))), throwsFormatException);
  });
  test('AGG03 unknown original status is distinct from failure and cannot replay a Save', () async {
    final operations = <String>[], mutations = <bool>[];
    final source = WorkspacePurchaseEntryRemoteSource(scope: _scope, connectionId: 'HOST-original-connection', current: () => true,
      now: () => _now, request: (body, current, {required mutation, onDispatch}) async {
        operations.add(body['operation']! as String); mutations.add(mutation); onDispatch?.call();
        return _reply(_frame());
      });
    expect((await source.readBook()).book, isNotNull);
    expect((await source.readAttempt(_intent())).receipt, isNull);
    expect(operations, ['readStorePurchaseEntryBook', 'readStorePurchaseEntryAttempt']);
    expect(mutations, [false, false]);
  });
  test('AGG03 a dispatched permission rejection remains an unknown Save outcome', () async {
    final source = WorkspacePurchaseEntryRemoteSource(scope: _scope, connectionId: 'HOST-original-connection', current: () => true,
      request: (body, current, {required mutation, onDispatch}) async {
        onDispatch?.call();
        return const SocialContentResponse(statusCode: 403, body: '{"ok":false,"error":{"code":"permission_denied"}}');
      });
    await expectLater(source.saveSupplier(_intent()), throwsA(isA<WorkspacePurchaseEntryRequestFailure>()
      .having((error) => error.mayHaveCommitted, 'retain original unknown Save', isTrue)));
  });
  test('AGG03 late mutation response after retirement cannot confirm another context', () async {
    final original = _intent(), entered = Completer<void>(), release = Completer<SocialContentResponse>();
    final source = WorkspacePurchaseEntryRemoteSource(scope: _scope, connectionId: 'HOST-original-connection', current: () => true,
      now: () => _now, request: (body, current, {required mutation, onDispatch}) {
        onDispatch?.call(); entered.complete(); return release.future;
      });
    final saving = source.saveSupplier(original);
    final assertion = expectLater(saving, throwsA(isA<WorkspacePurchaseEntryRequestFailure>()
      .having((error) => error.mayHaveCommitted, 'original dispatched Save', isTrue)));
    await entered.future; source.retire(); release.complete(_reply(_frame(original: original))); await assertion;
    expect(original.profile.createdAt.microsecond, 456);
  });
  test('AGG03 retired or unconfigured sources dispatch nothing and never fallback', () async {
    var calls = 0;
    final source = WorkspacePurchaseEntryRemoteSource(scope: _scope, connectionId: 'HOST-original-connection', current: () => false,
      request: (body, current, {required mutation, onDispatch}) async {calls++; return _reply(_frame());});
    await expectLater(source.saveSupplier(_intent()), throwsA(isA<WorkspacePurchaseEntryRequestFailure>()
      .having((error) => error.mayHaveCommitted, 'not dispatched', isFalse)));
    final transport = Transport(Map<String, dynamic>.from(_frame()));
    final gateway = AuthenticatedWorkspaceCatalogueGateway(endpoint: Uri.parse('https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
      realm: 'evaluation', credentials: Credentials(), transport: transport);
    expect(gateway.originalPurchaseEntrySource(accountId: _scope.account, storeId: _scope.store, current: () => true), isNull);
    expect(calls, 0); expect(transport.sent, isNull);
  });
  test('AGG03 original credential bridge keeps standard reads and limited-use mutations separate', () async {
    final original = _intent(), credentials = Credentials(), transport = Transport(Map<String, dynamic>.from(_frame()));
    var active = true;
    final gateway = AuthenticatedWorkspaceCatalogueGateway(endpoint: Uri.parse('https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'), realm: 'evaluation',
      credentials: credentials, transport: transport, purchaseEntrySupported: true, purchaseDraftSupported: true, now: () => _now);
    final source = gateway.originalPurchaseEntrySource(accountId: _scope.account, storeId: _scope.store, current: () => active)!;
    expect(source.purchaseDraftSupported, isTrue);
    expect(gateway.forOwnerAccount(_scope.account).purchaseDraftSupported, isTrue);
    await source.readBook();
    expect(credentials.modes, [SocialAppCheckTokenMode.standard]);
    expect(transport.sent!['operation'], 'readStorePurchaseEntryBook');
    expect(transport.sent!.containsKey('book'), isFalse);
    transport.data = Map<String, dynamic>.from(_frame(original: original));
    await source.saveSupplier(original);
    expect(credentials.modes.last, SocialAppCheckTokenMode.limitedUse);
    expect(transport.sent!['profile'], original.profile.toJson());
    expect(transport.sent!['fingerprint'], original.fingerprint);
    active = false;
    await expectLater(source.readBook(), throwsA(isA<WorkspacePurchaseEntryRequestFailure>()));
    expect(credentials.modes.length, 2);
  });
  test('AGG03 native original decoder never promotes local review-QA data', () {
    final value = _frame(), payload = jsonDecode(value['bookJson']! as String) as Map<String, dynamic>;
    payload['qa'] = true; value['bookJson'] = jsonEncode(payload);
    value['bookFingerprint'] = crypto.sha256.convert(utf8.encode(value['bookJson']! as String)).toString();
    expect(() => WorkspacePurchaseEntryReadback.decode(value, _scope, _now), throwsFormatException);
  });
  test('AGG03 durable client status recovers committed Save after restart without another write', () async {
    final wire = _HostBookWire()..loseNextAcknowledgement = true, first = wire.source();
    final journal = WorkspacePurchaseEntryJournal(scope: _scope, connectionId: first.connectionId, current: () => first.current);
    await first.readBook(); await journal.adoptConfirmedOriginal();
    final controller = WorkspaceSupplierSaveController(source: first, journal: journal, newKey: () => 'HOST-pending-original');
    await expectLater(controller.save(_profile(), null), throwsA(isA<WorkspacePurchaseEntryRequestFailure>()
      .having((value) => value.mayHaveCommitted, 'unknown committed result', isTrue)));
    final original = await journal.readPending(); expect(original!.idempotencyKey, 'HOST-pending-original');
    first.retire();
    final second = wire.source(), restoredJournal = WorkspacePurchaseEntryJournal(scope: _scope, connectionId: second.connectionId, current: () => second.current),
      restored = WorkspaceSupplierSaveController(source: second, journal: restoredJournal);
    final recovered = await restored.readCurrent();
    expect(recovered.book!.profiles.single.id, _profile().id); expect(wire.saves, 1);
    expect(await restoredJournal.readPending(), isNull);
    expect(await WorkspacePurchaseEntryJournal.hasOriginalBinding(_scope, current: () => true), isTrue);
    expect(wire.operations.where((value) => value == 'saveStoreSupplierProfile').length, 1);
  });
  test('AGG03 recovering an earlier Save never silently sends different new fields', () async {
    final wire = _HostBookWire()..loseNextAcknowledgement = true, source = wire.source(), journal = WorkspacePurchaseEntryJournal(
      scope: _scope, connectionId: source.connectionId, current: () => source.current);
    await source.readBook(); await journal.adoptConfirmedOriginal();
    var key = 0;
    final controller = WorkspaceSupplierSaveController(source: source, journal: journal, newKey: () => 'HOST-save-${++key}');
    await expectLater(controller.save(_profile(), null), throwsA(isA<WorkspacePurchaseEntryRequestFailure>()));
    final changed = _profile(name: 'HOST explicitly reviewed next contact');
    await expectLater(controller.save(changed, 1), throwsA(isA<WorkspaceSupplierSaveRecoveryRequired>()));
    expect(wire.saves, 1); expect(await journal.readPending(), isNull);
    final confirmed = await controller.save(changed, 1);
    expect(wire.saves, 2); expect(confirmed.book!.revision, 2); expect(confirmed.book!.profiles.single.name, changed.name);
    final originalStatus = await controller.recoverOnly(changed, 1);
    expect(originalStatus!.receipt!.profile.name, changed.name); expect(wire.saves, 2);
  });
  test('AGG03 unknown pending contact resolves only through the server terminal receipt', () async {
    final wire = _HostBookWire()..rejectNextBeforeCommit = true, source = wire.source(), journal = WorkspacePurchaseEntryJournal(
      scope: _scope, connectionId: source.connectionId, current: () => source.current);
    await source.readBook(); await journal.adoptConfirmedOriginal();
    var key = 0;
    final controller = WorkspaceSupplierSaveController(source: source, journal: journal, newKey: () => 'HOST-fenced-${++key}');
    await expectLater(controller.save(_profile(), null), throwsA(isA<WorkspacePurchaseEntryRequestFailure>()));
    final original = await journal.readPending(); expect(original, isNotNull);
    wire.book = WorkspacePurchaseEntryBook(account: _scope.account, store: _scope.store, qa: false,
      revision: 3, profiles: [], draft: null);
    final status = await controller.readCurrent(); expect(status.receipt, isNull);
    expect((await journal.readPending())!.fingerprint, original!.fingerprint);
    final refused = await controller.save(_profile(), null);
    expect(refused.receipt!.saved, isFalse); expect(refused.receipt!.reason, 'stale_book');
    expect(wire.saves, 2); expect(await journal.readPending(), isNull);
    expect(controller.lastResolution!.original.fingerprint, original.fingerprint);
    final retained = (await const FlutterSecureStorage().readAll()).values.single;
    final metadata = jsonDecode(retained) as Map<String, dynamic>;
    expect((metadata['lastResolved'] as Map)['status'], 'not_saved');
    expect(metadata['pending'], isNull);
    final confirmed = await controller.save(_profile(name: 'HOST reviewed after source changed'), 3);
    expect(confirmed.book!.revision, 4); expect(wire.saves, 3);
  });
  test('AGG03 reads never join an in-flight Save and repeated native Save shares its original request', () async {
    final wire = _HostBookWire(), hold = Completer<void>(), source = wire.source(), journal = WorkspacePurchaseEntryJournal(
      scope: _scope, connectionId: source.connectionId, current: () => source.current);
    await source.readBook(); await journal.adoptConfirmedOriginal(); wire.hold = hold.future;
    final controller = WorkspaceSupplierSaveController(source: source, journal: journal, newKey: () => 'HOST-single-flight');
    final one = controller.save(_profile(), null), two = controller.save(_profile(), null);
    try {
      await wire.entered.future.timeout(const Duration(seconds: 5));
      await expectLater(controller.readCurrent(), throwsA(isA<WorkspaceSupplierSaveRecoveryRequired>()));
      expect(wire.saves, 1); hold.complete();
      expect((await one).book!.revision, 1); expect((await two).book!.revision, 1);
      expect(wire.saves, 1);
    } finally {if (!hold.isCompleted) hold.complete();}
  });
  test('AGG03 changed connection cannot adopt over another original pending journal', () async {
    final wire = _HostBookWire()..rejectNextBeforeCommit = true, first = wire.source(), journal = WorkspacePurchaseEntryJournal(
      scope: _scope, connectionId: first.connectionId, current: () => first.current);
    await first.readBook(); await journal.adoptConfirmedOriginal();
    final controller = WorkspaceSupplierSaveController(source: first, journal: journal, newKey: () => 'HOST-retain-on-source-change');
    await expectLater(controller.save(_profile(), null), throwsA(isA<WorkspacePurchaseEntryRequestFailure>()));
    final before = await const FlutterSecureStorage().readAll();
    final changed = wire.source(connectionId: 'HOST-different-original'), other = WorkspacePurchaseEntryJournal(
      scope: _scope, connectionId: changed.connectionId, current: () => changed.current);
    expect(() => WorkspaceSupplierSaveController(source: changed, journal: journal), throwsArgumentError);
    await expectLater(other.readPending(), throwsFormatException);
    expect(await const FlutterSecureStorage().readAll(), before); expect(wire.saves, 1);
  });
  test('AGG03 manual draft intent is deeply frozen, keeps microseconds and rejects zone-less fresh capture', () {
    final raw = _draft(), original = WorkspacePurchaseDraftSaveIntent(scope: _scope, expectedRevision: null,
      idempotencyKey: 'HOST-frozen-draft', profile: _profile(), draft: raw, reviewedCopy: _copy());
    final before = original.fingerprint, exposed = original.data;
    (exposed['draft']! as Map)['invoiceReference'] = 'HOST external mutation';
    expect(original.draft.invoiceReference, raw.invoiceReference); expect(original.fingerprint, before);
    final restored = WorkspacePurchaseEntrySaveIntent.fromJson(original.toJson(), _scope);
    expect(restored, isA<WorkspacePurchaseDraftSaveIntent>()); expect(restored.fingerprint, before);
    expect((restored as WorkspacePurchaseDraftSaveIntent).draft.createdAt.microsecond, 456);
    final local = WorkspacePurchaseSavedCopy.fromJson({..._copy().toJson(), 'savedAt': _now.toLocal().toIso8601String()});
    expect(WorkspacePurchaseDraftSaveIntent.validationError(_profile(), raw, reviewedCopy: local), isNotNull);
  });
  test('AGG03 draft acknowledgement loss recovers after restart with writes disabled and no second Save', () async {
    final wire = _HostBookWire()..loseNextAcknowledgement = true, source = wire.source(purchaseDraftSupported: true),
      journal = WorkspacePurchaseEntryJournal(scope: _scope, connectionId: source.connectionId, current: () => source.current);
    await journal.adoptConfirmedOriginal();
    final controller = WorkspaceSupplierSaveController(source: source, journal: journal, newKey: () => 'HOST-frozen-purchase');
    await expectLater(controller.savePurchaseDraft(_profile(), _draft(), reviewedCopy: _copy(), expectedRevision: null),
      throwsA(isA<WorkspacePurchaseEntryRequestFailure>().having((e) => e.mayHaveCommitted, 'unknown original Save', isTrue)));
    final pending = await journal.readPending(); expect(pending, isA<WorkspacePurchaseDraftSaveIntent>());
    expect(pending!.idempotencyKey, 'HOST-frozen-purchase'); expect(wire.saves, 1);
    source.retire(); final next = wire.source(), recovery = WorkspaceSupplierSaveController(source: next,
      journal: WorkspacePurchaseEntryJournal(scope: _scope, connectionId: next.connectionId, current: () => next.current));
    final status = await recovery.readCurrent(); expect(status.receipt!.saved, isTrue);
    expect(status.book!.copies.single.id, _copy().id); expect(status.book!.draft!.goods.single['cost'], '');
    expect(await recovery.journal.readPending(), isNull); expect(wire.saves, 1);
  });
  test('AGG03 different operation cannot replace an unknown original draft Save', () async {
    final wire = _HostBookWire()..rejectNextBeforeCommit = true, source = wire.source(purchaseDraftSupported: true),
      journal = WorkspacePurchaseEntryJournal(scope: _scope, connectionId: source.connectionId, current: () => source.current);
    await journal.adoptConfirmedOriginal(); var key = 0;
    final controller = WorkspaceSupplierSaveController(source: source, journal: journal, newKey: () => 'HOST-global-original-${++key}');
    await expectLater(controller.savePurchaseDraft(_profile(), _draft(), expectedRevision: null), throwsA(isA<WorkspacePurchaseEntryRequestFailure>()));
    final original = await journal.readPending();
    await expectLater(controller.save(_profile(), null), throwsA(isA<WorkspaceSupplierSaveRecoveryRequired>()));
    expect(wire.saves, 1); expect((await journal.readPending())!.fingerprint, original!.fingerprint);
    final result = await controller.savePurchaseDraft(_profile(), _draft(), expectedRevision: null);
    expect(result.receipt!.saved, isTrue); expect(wire.saves, 2); expect(result.receipt!.original.idempotencyKey, original.idempotencyKey);
  });
  test('AGG03 an unsupported draft writer never creates pending or dispatches a mutation', () async {
    final wire = _HostBookWire(), source = wire.source(), journal = WorkspacePurchaseEntryJournal(
      scope: _scope, connectionId: source.connectionId, current: () => source.current);
    await journal.adoptConfirmedOriginal();
    final controller = WorkspaceSupplierSaveController(source: source, journal: journal);
    await expectLater(controller.savePurchaseDraft(_profile(), _draft(), expectedRevision: null), throwsA(isA<WorkspacePurchaseEntryRequestFailure>()
      .having((e) => e.mayHaveCommitted, 'no request dispatched', isFalse)));
    expect(wire.operations, isEmpty); expect(await journal.readPending(), isNull);
  });
  test('AGG03 historical draft status never clears a newer unresolved supplier request', () async {
    final wire = _HostBookWire(), source = wire.source(purchaseDraftSupported: true),
      journal = WorkspacePurchaseEntryJournal(scope: _scope, connectionId: source.connectionId, current: () => source.current);
    await journal.adoptConfirmedOriginal(); var sequence = 0;
    final controller = WorkspaceSupplierSaveController(source: source, journal: journal, newKey: () => 'HOST-status-${++sequence}');
    final saved = await controller.savePurchaseDraft(_profile(), _draft(), expectedRevision: null);
    final original = saved.receipt!.original;
    final lateRetry = await controller.retryPurchaseDraft(original as WorkspacePurchaseDraftSaveIntent);
    expect(lateRetry.receipt!.saved, isTrue); expect(wire.saves, 1);
    wire.rejectNextBeforeCommit = true;
    await expectLater(controller.save(_profile(name: 'HOST later contact'), 1), throwsA(isA<WorkspacePurchaseEntryRequestFailure>()));
    final pending = await journal.readPending(), before = wire.saves;
    final status = await controller.readRetainedAttempt(original);
    expect(status.receipt!.saved, isTrue); expect(wire.saves, before);
    expect((await journal.readPending())!.fingerprint, pending!.fingerprint);
    expect(controller.pending!.idempotencyKey, pending.idempotencyKey);
    expect(wire.operations.last, 'readStorePurchaseEntryAttempt');
    await expectLater(controller.retryPurchaseDraft(original), throwsA(isA<WorkspaceSupplierSaveRecoveryRequired>()));
    expect(wire.saves, before); expect((await journal.readPending())!.fingerprint, pending.fingerprint);
  });
  final capturePath = Platform.environment['AGG03_ORIGINAL_SUPPLIER_RESPONSE'];
  final draftCapturePath = Platform.environment['AGG03_ORIGINAL_DRAFT_RESPONSE'];
  test('AGG03 native draft codec consumes the actual original SDK command and current-book readback', () {
    final capture = jsonDecode(File(draftCapturePath!).readAsStringSync()) as Map<String, dynamic>, c = capture['command'] as Map<String, dynamic>,
      rawScope = c['scope'] as Map<String, dynamic>, scope = (account: rawScope['account'] as String, store: rawScope['store'] as String, realm: rawScope['realm'] as String);
    final original = WorkspacePurchaseDraftSaveIntent.fromJson({'schemaVersion': 1, 'operation': 'savePurchaseDraft', ...c}, scope);
    expect(original.fingerprint, c['fingerprint']);
    final reply = capture['response'] as Map<String, dynamic>, result = WorkspacePurchaseEntryReadback.decode(
      reply, scope, DateTime.parse(reply['observedAt'] as String), original: original);
    expect(result.receipt!.saved, isTrue); expect(result.book!.copies.single.toJson(), original.reviewedCopy!.toJson());
    expect(result.book!.draft!.toJson(), original.draft.toJson());
    final corrupted = {...reply, 'attempt': {...reply['attempt'] as Map<String, dynamic>, 'draftFingerprint': '0' * 64}};
    expect(() => WorkspacePurchaseEntryReadback.decode(corrupted, scope, DateTime.parse(reply['observedAt'] as String), original: original), throwsFormatException);
  }, skip: draftCapturePath == null);
  test('AGG03 pristine original adoption blocks legacy fallback but leaves QA data separate', () async {
    final wire = _HostBookWire(), local = SecureWorkPurchaseEntryStore(accountScope: () => _scope.account);
    final source = wire.source();
    final remote = await RemoteWorkPurchaseEntryStore.openOriginal(source: source, retainedLocal: local,
      qa: false, newKey: () => 'HOST-adopted-save');
    expect(remote.originalScope, (_scope.account, _scope.store, false));
    expect(remote, isNot(isA<WorkPurchaseEntryRevisionGuard>()));
    final outcome = await remote.saveSupplierProfile(_profile(), account: _scope.account, store: _scope.store, qa: false, expectedRevision: null);
    expect(outcome.recorded, isTrue); expect(outcome.currentBook!.profiles.single.name, _profile().name);
    expect(remote.pendingSupplierProfile, isNull); expect(remote.lastRejectedSupplierProfile, isNull);
    await expectLater(local.read(_scope.account, _scope.store, qa: false), throwsA(isA<Object>()));
    expect(await local.read(_scope.account, _scope.store, qa: true), isNull);
    await expectLater(remote.save(outcome.currentBook!, expectedRevision: 1), throwsA(isA<WorkGatewayException>()));
    await expectLater(remote.read(_scope.account, 'HOST-other-store', qa: false), throwsA(isA<WorkGatewayException>()));
    expect(wire.saves, 1);
  });
  test('AGG03 retained local original blocks remote adoption before source IO and preserves every byte', () async {
    final wire = _HostBookWire(), local = SecureWorkPurchaseEntryStore(accountScope: () => _scope.account);
    final retained = WorkspacePurchaseEntryBook(account: _scope.account, store: _scope.store, qa: false, revision: 1, profiles: [_profile()]);
    await local.save(retained, expectedRevision: null);
    final before = await const FlutterSecureStorage().readAll();
    await expectLater(RemoteWorkPurchaseEntryStore.openOriginal(source: wire.source(), retainedLocal: local, qa: false), throwsA(isA<Object>()));
    await expectLater(RemoteWorkPurchaseEntryStore.openOriginal(source: wire.source(), retainedLocal: local, qa: true), throwsA(isA<WorkGatewayException>()));
    expect(wire.operations, isEmpty); expect(await const FlutterSecureStorage().readAll(), before);
    expect((await local.read(_scope.account, _scope.store, qa: false))!.toJson(), retained.toJson());
  });
  test('AGG03 native codec consumes actual local SDK original read and receipt without alternate mapping', () {
    final capture = jsonDecode(File(capturePath!).readAsStringSync()) as Map<String, dynamic>, command = capture['command'] as Map<String, dynamic>;
    final rawScope = command['scope'] as Map<String, dynamic>, scope = (account: rawScope['account'] as String,
      store: rawScope['store'] as String, realm: rawScope['realm'] as String);
    final original = WorkspaceSupplierSaveIntent.fromJson({'schemaVersion': 1, ...command}, scope);
    expect(original.fingerprint, command['fingerprint']);
    final response = capture['response'] as Map<String, dynamic>, observed = DateTime.parse(response['observedAt'] as String);
    final saved = WorkspacePurchaseEntryReadback.decode(response, scope, observed, original: original);
    expect(saved.receipt!.profile.toJson(), original.profile.toJson());
    expect(saved.book!.profiles.single.toJson(), original.profile.toJson());
    final read = capture['readResponse'] as Map<String, dynamic>;
    final current = WorkspacePurchaseEntryReadback.decode(read, scope, DateTime.parse(read['observedAt'] as String));
    expect(current.receipt, isNull); expect(current.bookFingerprint, saved.bookFingerprint);
    expect(current.book!.toJson(), saved.book!.toJson());
  }, skip: capturePath == null);
}

/// Only a labelled client fault-injection fixture. Actual durable source/authority
/// checks are qualified separately against the local SDK repository export.
class _HostBookWire {
  WorkspacePurchaseEntryBook? book;
  final operations = <String>[];
  final receipts = <String, Map<String, Object?>>{};
  int saves = 0;
  bool loseNextAcknowledgement = false, rejectNextBeforeCommit = false;
  Future<void>? hold;
  final entered = Completer<void>();
  WorkspacePurchaseEntryRemoteSource source({String connectionId = 'HOST-original-connection', bool purchaseDraftSupported = false}) =>
    WorkspacePurchaseEntryRemoteSource(scope: _scope, connectionId: connectionId, request: request, current: () => true,
      purchaseDraftSupported: purchaseDraftSupported, now: () => _now);
  Map<String, Object?> response([String? key]) {
    final value = _frame(), original = book;
    final payload = original == null ? null : jsonEncode(original.toJson());
    return {...value, 'state': original == null ? 'empty' : 'ready', 'bookJson': payload,
      'bookFingerprint': payload == null ? null : crypto.sha256.convert(utf8.encode(payload)).toString(),
      'attempt': key == null ? null : receipts[key]};
  }
  Future<SocialContentResponse> request(Map<String, Object?> body, bool Function() current,
    {required bool mutation, void Function()? onDispatch}) async {
    final operation = body['operation']! as String; operations.add(operation); onDispatch?.call();
    if (operation == 'readStorePurchaseEntryBook') return _reply(response());
    final key = body['idempotencyKey']! as String;
    if (operation == 'readStorePurchaseEntryAttempt') return _reply(response(key));
    expect(operation, anyOf('saveStoreSupplierProfile', 'saveStorePurchaseDraft')); expect(mutation, isTrue); saves++;
    if (!entered.isCompleted) entered.complete();
    if (hold != null) await hold;
    final WorkspacePurchaseEntrySaveIntent original = operation == 'saveStorePurchaseDraft'
      ? WorkspacePurchaseDraftSaveIntent(scope: _scope, expectedRevision: body['expectedRevision'] as int?, idempotencyKey: key,
        profile: WorkspaceSupplierProfile.fromJson(body['profile']), draft: WorkspacePurchaseEntryDraft.fromJson(body['draft']),
        reviewedCopy: body['reviewedCopy'] == null ? null : WorkspacePurchaseSavedCopy.fromJson(body['reviewedCopy']),
        replaceReviewedDraftId: body['replaceReviewedDraftId'] as String?)
      : WorkspaceSupplierSaveIntent(scope: _scope, expectedRevision: body['expectedRevision'] as int?,
        idempotencyKey: key, profile: WorkspaceSupplierProfile.fromJson(body['profile']));
    expect(body['fingerprint'], original.fingerprint);
    if (rejectNextBeforeCommit) {rejectNextBeforeCommit = false; throw StateError('HOST unobserved, not committed');}
    if (!receipts.containsKey(key)) {
      if (original.expectedRevision != book?.revision) {
        receipts[key] = {'schemaVersion': 1, 'scope': {'account': _scope.account, 'store': _scope.store, 'realm': _scope.realm},
          'operation': original.operation, 'idempotencyKey': key, 'fingerprint': original.fingerprint, ...original.receiptFields,
          'status': 'not_saved', 'reason': 'stale_book', 'changed': false, 'resultRevision': book?.revision,
          'profile': original.profile.toJson(), 'recordedAt': _now.toIso8601String()};
        return _reply(response(key));
      }
      final revision = (book?.revision ?? 0) + 1, values = book?.toJson() ?? {
        'version': 1, 'account': _scope.account, 'store': _scope.store, 'qa': false, 'draft': null};
      book = WorkspacePurchaseEntryBook.fromJson({...values, 'revision': revision, 'profiles': [
        for (final p in book?.profiles ?? const <WorkspaceSupplierProfile>[]) if (p.id != original.profile.id) p.toJson(),
        original.profile.toJson()], if (original is WorkspacePurchaseDraftSaveIntent) ...{
          'draft': original.draft.toJson(), if (original.reviewedCopy != null) 'copies': [
            for (final copy in book?.copies ?? const <WorkspacePurchaseSavedCopy>[]) copy.toJson(), original.reviewedCopy!.toJson()],
        }});
      receipts[key] = {'schemaVersion': 1, 'scope': {'account': _scope.account, 'store': _scope.store, 'realm': _scope.realm},
        'operation': original.operation, 'idempotencyKey': key, 'fingerprint': original.fingerprint, ...original.receiptFields,
        'status': 'saved', 'reason': null, 'changed': true, 'resultRevision': revision, 'profile': original.profile.toJson(), 'recordedAt': _now.toIso8601String()};
    }
    if (loseNextAcknowledgement) {loseNextAcknowledgement = false; throw StateError('HOST committed response lost');}
    return _reply(response(key));
  }
}
