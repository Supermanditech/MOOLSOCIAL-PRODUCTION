// HOST inputs only. No provider override, phone record or financial outcome.
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/assistant/mool_assistant.dart';
import 'package:moolsocial/ui_v2/assistant/mool_assistant_v2.dart';
import 'package:moolsocial/features/work/screens/work_workspace_dashboard_screen.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:moolsocial/features/work/work_store_preferences.dart';
import 'package:moolsocial/features/work/widgets/store_settings_widgets.dart';
import 'package:moolsocial/features/work/work_ledger_gateway.dart' show workspaceLedgerCanonical, workspaceLedgerFingerprint;
import 'package:moolsocial/features/shared/social_content_gateway.dart' show SocialContentResponse,
  SocialContentCredentials, SocialContentTransport, SocialAppCheckTokenMode;
import 'package:moolsocial/features/work/work_catalogue_gateway.dart' show AuthenticatedWorkspaceCatalogueGateway;
import 'package:moolsocial/features/work/work_services.dart' show SecureWorkPrivatePreferenceJournalStorage;
import 'package:moolsocial/features/work/work_services.dart' show UnavailableWorkGateway, WorkReviewResult,
  WorkRemoteReviewStatus, WorkWorkspaceAccess, WorkPendingProofStore;
import 'package:moolsocial/features/work/work_session.dart' show WorkSession;
import 'package:moolsocial/features/work/work_models.dart' show WorkWorkspace;
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:moolsocial/features/shared/social_content_gateway.dart' show IoSocialContentTransport;

const _scope = (account: 'HOST-private-preference-owner', store: 'HOST-private-preference-store', realm: 'evaluation');
const _project = 'host-private-pref-agg10';
Map<String, Object?> _status() => {'acceptingOrders': true, 'visibleToCustomers': false, 'fulfilmentMode': 'Delivery and pickup',
  'busyMinutes': 0, 'reopensAt': '', 'openingTime': '9:00 AM', 'closingTime': '21:30', 'maximumActiveOrders': 0,
  'alertSound': true, 'alertVibration': false};
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final value in ['0', '9007199254740993', '9223372036854775807']) {
    test('HOST exact native integer $value', () => expect(workspacePrivatePreferenceInteger(value).toString(), value));
  }
  for (final value in <Object?>['-1', '00', '+1', ' 1', '1 ', '1.0', '1e3', '9223372036854775808', 1, null, true]) {
    test('HOST rejects noncanonical integer $value', () => expect(() => workspacePrivatePreferenceInteger(value), throwsFormatException));
  }
  test('HOST four complete groups round-trip without defaulting or normalising', () {
    final groups = {
      WorkspacePrivatePreferenceKind.status: {..._status(), 'busyMinutes': int.parse('9223372036854775807')},
      WorkspacePrivatePreferenceKind.pickup: {'city': 'HOST city', 'area': 'अ' * 3000, 'pincode': '560001', 'pickupEnabled': false},
      WorkspacePrivatePreferenceKind.invoice: {'mode': 'moolSocialChat'},
      WorkspacePrivatePreferenceKind.staff: {'staffAccessEnabled': true, 'counterCount': 20},
    };
    for (final entry in groups.entries) {
      final wire = workspacePrivatePreferenceFieldsToWire(entry.key, entry.value);
      expect(workspacePrivatePreferenceFieldsFromWire(entry.key, jsonDecode(jsonEncode(wire))), entry.value);
      expect(() => wire['foreign'] = true, throwsUnsupportedError);
    }
  });
  test('HOST complete group fails omissions and mixed public/permission fields', () {
    final wire = workspacePrivatePreferenceFieldsToWire(WorkspacePrivatePreferenceKind.status, _status());
    expect(() => workspacePrivatePreferenceFieldsFromWire(WorkspacePrivatePreferenceKind.status, {...wire}..remove('alertSound')), throwsFormatException);
    expect(() => workspacePrivatePreferenceFieldsFromWire(WorkspacePrivatePreferenceKind.status, {...wire, 'membershipApproved': true}), throwsFormatException);
    expect(() => workspacePrivatePreferenceFieldsToWire(WorkspacePrivatePreferenceKind.staff, {'staffAccessEnabled': true, 'counterCount': 21}), throwsFormatException);
  });
  test('HOST preserves original whitespace and matches native time semantics', () {
    final native = {..._status(), 'openingTime': '\u0085 9:00 am\u0085', 'reopensAt': '  exact \ufeff interior  '};
    final wire = workspacePrivatePreferenceFieldsToWire(WorkspacePrivatePreferenceKind.status, native);
    expect(workspacePrivatePreferenceFieldsFromWire(WorkspacePrivatePreferenceKind.status, wire), native);
    expect(() => workspacePrivatePreferenceFieldsToWire(WorkspacePrivatePreferenceKind.status, {...native, 'openingTime': '\u180e9:00 AM'}), throwsFormatException);
  });
  test('HOST new private proposal converts exact int64 before unchanged native validation', () {
    final converted = workspacePrivatePreferenceNativeProposalFields('AI-ACT-319', {
      'preparationMinutes': '9223372036854775807', 'maximumActiveOrders': '0', 'alertSound': false,
    });
    final data = StoreSettingsInitialData.fromFields('AI-ACT-319', converted);
    expect(data.fields['preparationMinutes'].toString(), '9223372036854775807');
    expect(data.fields.containsKey('openingTime'), false); // No invented current/default fields.
    expect(() => StoreSettingsInitialData.fromFields('AI-ACT-319', {'preparationMinutes': '1'}), throwsFormatException);
    expect(() => workspacePrivatePreferenceNativeProposalFields('AI-ACT-320', {'legalName': 'HOST'}), throwsFormatException);
    expect(() => workspacePrivatePreferenceNativeProposalFields('AI-ACT-328', {'alertId': 'HOST'}), throwsFormatException);
  });
  test('HOST immutable original command and record preserve exact identity', () {
    final original = WorkspacePrivatePreferenceIntent(projectId: _project, scope: _scope, kind: WorkspacePrivatePreferenceKind.status,
      expectedRevision: 0, idempotencyKey: 'HOST-save-1', fields: _status());
    expect(WorkspacePrivatePreferenceIntent.fromJson(jsonDecode(jsonEncode(original.toJson()))).toJson(), original.toJson());
    expect(() => WorkspacePrivatePreferenceIntent.fromJson({...original.toJson(), 'projectId': 'foreign'}), throwsFormatException);
    expect(() => WorkspacePrivatePreferenceIntent.fromJson({...original.toJson(), 'expectedRevision': '1'}), throwsFormatException);
    expect(() => original.fields['busyMinutes'] = 9, throwsUnsupportedError);
    final value = {'version': 1, 'projectId': _project, 'scope': workspacePrivatePreferenceScopeJson(_scope),
      'kind': 'status', 'revision': '1', 'fields': workspacePrivatePreferenceFieldsToWire(WorkspacePrivatePreferenceKind.status, _status())};
    final record = WorkspacePrivatePreferenceRecord.fromJson(value, projectId: _project, scope: _scope, kind: WorkspacePrivatePreferenceKind.status);
    expect(record.toJson(), value);
    expect(() => WorkspacePrivatePreferenceRecord.fromJson(value, projectId: _project,
      scope: (account: _scope.account, store: 'foreign', realm: _scope.realm), kind: WorkspacePrivatePreferenceKind.status), throwsFormatException);
    final export = Platform.environment['AGG10_NATIVE_PRIVATE_PREFERENCE_WIRE'];
    if (export != null) File(export).writeAsStringSync(jsonEncode({'label': 'ISOLATED HOST native serializer', 'command': original.toJson(), 'record': record.toJson()}));
  });
  test('HOST opening and pending reads never save, check or resolve automatically', () async {
    final source = _HostSource(), journal = _HostJournal(), controller = _controller(source, journal);
    expect(await controller.read(), null); expect(source.calls, ['read']); expect(journal.resolved, null);
    journal.original = _intent();
    await expectLater(controller.read(), throwsStateError);
    expect(source.calls, ['read']); expect(journal.original, isNotNull);
  });
  test('HOST journal is durable before dispatch and exact acknowledgement resolves once', () async {
    final source = _HostSource(), journal = _HostJournal(), controller = _controller(source, journal), original = _intent();
    source.onSave = (input) async {
      expect(journal.original?.toJson(), original.toJson());
      return _result(input);
    };
    expect((await controller.save(original)).saved, true);
    expect(journal.original, null); expect(journal.resolved?.intent.toJson(), original.toJson());
    expect(source.calls, ['save']);
  });
  test('HOST timeout survives controller restart; check is read-only and explicit retry uses the original', () async {
    final source = _HostSource(), journal = _HostJournal(), original = _intent();
    source.onSave = (_) async => throw TimeoutException('HOST lost acknowledgement');
    await expectLater(_controller(source, journal).save(original), throwsA(isA<TimeoutException>()));
    final restarted = _controller(source, journal);
    source.onStatus = (input) async => _result(input, absent: true);
    expect((await restarted.check()).confirmed, false); expect(source.calls, ['save', 'status']);
    expect(journal.original?.toJson(), original.toJson());
    await expectLater(restarted.save(_intent(key: 'HOST-changed')), throwsStateError);
    source.onSave = (input) async {expect(input.toJson(), original.toJson()); return _result(input);};
    expect((await restarted.check(retry: true)).saved, true);
    expect(source.calls, ['save', 'status', 'status', 'save']); expect(journal.original, null);
  });
  test('HOST retired caller and late acknowledgement retain the original; no ABA resurrection', () async {
    final source = _HostSource(), journal = _HostJournal(), controller = _controller(source, journal);
    final dispatched = Completer<void>(), response = Completer<WorkspacePrivatePreferenceResult>();
    source.onSave = (input) {dispatched.complete(); return response.future;};
    final attempt = controller.save(_intent());
    final assertion = expectLater(attempt, throwsStateError);
    await dispatched.future; controller.retire(); response.complete(_result(_intent())); await assertion;
    expect(journal.original, isNotNull); expect(journal.resolved, null);
    source.active = false; source.active = true;
    await expectLater(controller.check(retry: true), throwsStateError); expect(source.calls, ['save']);
  });
  test('HOST failed retention prevents dispatch; failed clear preserves the known original', () async {
    final source = _HostSource(), journal = _HostJournal()..failRetain = true;
    await expectLater(_controller(source, journal).save(_intent()), throwsStateError); expect(source.calls, isEmpty);
    journal.failRetain = false; journal.failResolve = true;
    await expectLater(_controller(source, journal).save(_intent()), throwsStateError);
    expect(journal.original, isNotNull); expect(source.calls, ['save']);
    journal.failResolve = false;
    expect((await _controller(source, journal).check()).saved, true);
    expect(source.calls, ['save', 'status']); expect(journal.original, null);
  });
  test('HOST repeated taps cannot dispatch two saves', () async {
    final source = _HostSource(), journal = _HostJournal(), controller = _controller(source, journal);
    final dispatched = Completer<void>(), response = Completer<WorkspacePrivatePreferenceResult>();
    source.onSave = (input) {dispatched.complete(); return response.future;};
    final first = controller.save(_intent()); await dispatched.future;
    await expectLater(controller.save(_intent()), throwsStateError);
    response.complete(_result(_intent())); await first; expect(source.calls, ['save']);
  });
  test('HOST foreign pending status cannot authorize retry or clear', () async {
    final source = _HostSource(), journal = _HostJournal()..original = _intent();
    source.onStatus = (_) async => _result(_intent(key: 'HOST-foreign'), absent: true);
    await expectLater(_controller(source, journal).check(retry: true), throwsFormatException);
    expect(source.calls, ['status']); expect(journal.original?.idempotencyKey, 'HOST-save-1');
  });
  test('HOST receipt pointer and scope are checked and deeply frozen', () {
    final result = _result(_intent());
    expect(() => (result.receipt!['scope'] as Map)['store'] = 'foreign', throwsUnsupportedError);
    final bad = jsonDecode(jsonEncode(result.toJson())) as Map<String, dynamic>;
    (bad['receipt']['input'] as Map)['fingerprint'] = '0' * 64;
    expect(() => WorkspacePrivatePreferenceResult.fromJson(bad, _intent()), throwsFormatException);
  });
  test('HOST durable journal binds explicitly and restores the exact pending original after reconstruction', () async {
    final storage = _MemoryJournalStorage(), journal = _storedJournal(storage);
    expect(await journal.bound, false); expect(storage.writes, 0);
    await expectLater(journal.pending(), throwsStateError);
    await journal.bindConfirmedOriginal(null); expect(storage.writes, 1);
    await journal.retain(_intent()); expect(storage.writes, 2);
    await journal.retain(_intent()); expect(storage.writes, 2);
    final restarted = _storedJournal(storage);
    expect((await restarted.pending())?.toJson(), _intent().toJson());
    await expectLater(restarted.retain(_intent(key: 'HOST-replacement')), throwsStateError);
    expect((await restarted.pending())?.toJson(), _intent().toJson());
  });
  test('HOST endpoint changes and corrupt journals cannot reset or replace retained data', () async {
    final storage = _MemoryJournalStorage(), journal = _storedJournal(storage);
    await journal.bindConfirmedOriginal(null); await journal.retain(_intent());
    final original = storage.values[journal.storageKey];
    await expectLater(_storedJournal(storage, connectionId: '1' * 64).bound, throwsFormatException);
    expect(storage.values[journal.storageKey], original);
    storage.values[journal.storageKey] = '{"foreign":true}';
    await expectLater(journal.bindConfirmedOriginal(null), throwsFormatException);
    expect(storage.values[journal.storageKey], '{"foreign":true}');
  });
  test('HOST journal compare-and-set refuses a different result and retains complete resolved evidence', () async {
    final storage = _MemoryJournalStorage(), journal = _storedJournal(storage);
    await journal.bindConfirmedOriginal(null); await journal.retain(_intent());
    await expectLater(journal.resolve(_intent(), _result(_intent(key: 'HOST-other'))), throwsStateError);
    expect(await journal.pending(), isNotNull);
    await journal.resolve(_intent(), _result(_intent())); expect(await journal.pending(), null);
    final raw = jsonDecode(storage.values[journal.storageKey]!) as Map<String, dynamic>;
    expect(raw['lastResolved']['intent'], _intent().toJson()); expect(raw['lastResolved']['result'], _result(_intent()).toJson());
    expect(await _storedJournal(storage).pending(), null);
    await expectLater(journal.retain(_intent()), throwsStateError);
  });
  test('HOST durable failures retain original commands and verify committed writes before dispatch', () async {
    final storage = _MemoryJournalStorage(), journal = _storedJournal(storage);
    await journal.bindConfirmedOriginal(null);
    storage.failBeforeWrite = true;
    await expectLater(journal.retain(_intent()), throwsStateError); expect(await journal.pending(), null);
    storage.failBeforeWrite = false; storage.commitThenThrow = true;
    await journal.retain(_intent()); expect((await journal.pending())?.toJson(), _intent().toJson());
    storage.commitThenThrow = false; storage.failBeforeWrite = true;
    await expectLater(journal.resolve(_intent(), _result(_intent())), throwsStateError);
    expect((await _storedJournal(storage).pending())?.toJson(), _intent().toJson());
  });
  test('HOST separate journal instances serialize conflicting retains without losing the first original', () async {
    final storage = _MemoryJournalStorage(), first = _storedJournal(storage), second = _storedJournal(storage);
    await first.bindConfirmedOriginal(null);
    final results = await Future.wait([first.retain(_intent()), second.retain(_intent(key: 'HOST-racing'))]
      .map((attempt) async {try {await attempt; return true;} on StateError {return false;}}));
    expect(results.where((saved) => saved).length, 1);
    expect((await first.pending())?.idempotencyKey, 'HOST-save-1');
  });
  test('HOST actor/project/realm/Store/group journal keys are separate and retired access is blocked', () async {
    final storage = _MemoryJournalStorage(), original = _storedJournal(storage);
    final variants = [
      _storedJournal(storage, project: 'HOST-other-project'),
      StoredWorkspacePrivatePreferenceJournal(projectId: _project, scope: (account: 'HOST-other', store: _scope.store, realm: _scope.realm),
        kind: WorkspacePrivatePreferenceKind.status, connectionId: '0' * 64, storage: storage, current: () => true),
      StoredWorkspacePrivatePreferenceJournal(projectId: _project, scope: (account: _scope.account, store: 'HOST-other', realm: _scope.realm),
        kind: WorkspacePrivatePreferenceKind.status, connectionId: '0' * 64, storage: storage, current: () => true),
      StoredWorkspacePrivatePreferenceJournal(projectId: _project, scope: (account: _scope.account, store: _scope.store, realm: 'production'),
        kind: WorkspacePrivatePreferenceKind.status, connectionId: '0' * 64, storage: storage, current: () => true),
      StoredWorkspacePrivatePreferenceJournal(projectId: _project, scope: _scope, kind: WorkspacePrivatePreferenceKind.staff,
        connectionId: '0' * 64, storage: storage, current: () => true),
    ];
    expect({original.storageKey, ...variants.map((journal) => journal.storageKey)}.length, 6);
    await original.bindConfirmedOriginal(null); await original.retain(_intent());
    for (final journal in variants) {expect(await journal.bound, false);}
    final retired = StoredWorkspacePrivatePreferenceJournal(projectId: _project, scope: _scope, kind: WorkspacePrivatePreferenceKind.status,
      connectionId: '0' * 64, storage: storage, current: () => false);
    await expectLater(retired.pending(), throwsStateError);
    expect((await original.pending())?.toJson(), _intent().toJson());
  });
  test('HOST existing secure-storage adapter restores pending data without replay', () async {
    FlutterSecureStorage.setMockInitialValues({});
    const storage = SecureWorkPrivatePreferenceJournalStorage();
    final journal = _storedJournal(storage);
    await journal.bindConfirmedOriginal(null); await journal.retain(_intent());
    expect((await _storedJournal(const SecureWorkPrivatePreferenceJournalStorage()).pending())?.toJson(), _intent().toJson());
  });
  final backendWire = Platform.environment['AGG10_BACKEND_PRIVATE_PREFERENCE_WIRE_INPUT'];
  if (backendWire != null) {
    test('HOST actual SDK result is accepted by native recovery without rewriting', () {
      final value = jsonDecode(File(backendWire).readAsStringSync()) as Map<String, dynamic>;
      final intent = WorkspacePrivatePreferenceIntent.fromJson(value['command']);
      final result = WorkspacePrivatePreferenceResult.fromJson(value['result'], intent);
      expect(result.saved, true); expect(result.toJson(), value['result']);
    });
  }
  final httpWire = Platform.environment['AGG10_BACKEND_PRIVATE_PREFERENCE_HTTP_WIRE_INPUT'];
  if (httpWire != null) {
    final fixture = jsonDecode(File(httpWire).readAsStringSync()) as Map<String, dynamic>;
    final original = WorkspacePrivatePreferenceIntent.fromJson(fixture['command']);
    test('HOST authenticated gateway keeps legacy off and preserves private source negotiation, transport and App Check modes', () async {
      final credentials = _HostCredentials(), calls = <String>[];
      final privateTransport = _HostTransport((body) async {
        calls.add(body['operation'] as String);
        final key = switch (body['operation']) {'readStorePrivatePreferences' => 'empty', 'saveStorePrivatePreferences' => 'saved', _ => 'status'};
        return SocialContentResponse(statusCode: 200, body: jsonEncode(fixture[key]));
      });
      final ordinary = _HostTransport((_) async => throw StateError('Private source must use the bounded original transport.'));
      AuthenticatedWorkspaceCatalogueGateway gateway({bool enabled = false, String? project}) => AuthenticatedWorkspaceCatalogueGateway(
        endpoint: Uri.parse('https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
        credentials: credentials, transport: ordinary, privateOriginalTransport: privateTransport,
        realm: 'evaluation', privatePreferencesSupported: enabled, privatePreferencesProjectId: project);
      expect(gateway().originalPrivatePreferenceSource(accountId: original.scope.account, storeId: original.scope.store,
        kind: original.kind, current: () => true), null);
      expect(gateway(enabled: true).originalPrivatePreferenceSource(accountId: original.scope.account, storeId: original.scope.store,
        kind: original.kind, current: () => true), null);
      final configured = gateway(enabled: true, project: original.projectId).forOwnerAccount(original.scope.account);
      expect(configured.privatePreferencesSupported, true); expect(configured.privatePreferencesProjectId, original.projectId);
      var active = true;
      final source = configured.originalPrivatePreferenceSource(accountId: original.scope.account, storeId: original.scope.store,
        kind: original.kind, current: () => active)!;
      expect(await source.read(), null); expect((await source.save(original)).saved, true); expect((await source.status(original)).saved, true);
      expect(calls, ['readStorePrivatePreferences', 'saveStorePrivatePreferences', 'checkStorePrivatePreferencesSave']);
      expect(credentials.modes, [SocialAppCheckTokenMode.standard, SocialAppCheckTokenMode.limitedUse, SocialAppCheckTokenMode.standard]);
      active = false; await expectLater(source.read(), throwsA(isA<WorkspacePrivatePreferenceRequestFailure>()));
      expect(calls.length, 3);
    });
    test('HOST native remote read/save/status match actual SDK HTTP envelopes and mutation modes', () async {
      final calls = <String>[], modes = <bool>[];
      final source = WorkspacePrivatePreferenceRemoteSource(projectId: original.projectId, scope: original.scope, kind: original.kind,
        connectionId: '0' * 64, current: () => true, request: (body, active, {required mutation, onDispatch}) async {
          expect(active(), true); expect(body['storePrivatePreferencesVersion'], 1);
          expect(body['actorAccountId'], original.scope.account); expect(body['projectId'], original.projectId);
          calls.add(body['operation'] as String); modes.add(mutation); onDispatch?.call();
          final key = switch (body['operation']) {'readStorePrivatePreferences' => 'empty', 'saveStorePrivatePreferences' => 'saved', _ => 'status'};
          if (mutation) expect(body['command'], original.toJson());
          return SocialContentResponse(statusCode: 200, body: jsonEncode(fixture[key]));
        });
      expect(await source.read(), null);
      expect((await source.save(original)).saved, true); expect((await source.status(original)).saved, true);
      expect(calls, ['readStorePrivatePreferences', 'saveStorePrivatePreferences', 'checkStorePrivatePreferencesSave']);
      expect(modes, [false, true, false]);
    });
    test('HOST bad negotiated acknowledgement leaves the same pending command for status recovery', () async {
      var reject = true;
      final source = WorkspacePrivatePreferenceRemoteSource(projectId: original.projectId, scope: original.scope, kind: original.kind,
        connectionId: '0' * 64, current: () => true, request: (body, active, {required mutation, onDispatch}) async {
          onDispatch?.call();
          final response = jsonDecode(jsonEncode(fixture[mutation ? 'saved' : 'status'])) as Map<String, dynamic>;
          if (reject) (response['data'] as Map)['storePrivatePreferencesVersion'] = 2;
          return SocialContentResponse(statusCode: 200, body: jsonEncode(response));
        });
      final journal = _HostJournal();
      final controller = WorkspacePrivatePreferenceController(projectId: original.projectId, scope: original.scope, kind: original.kind, source: source, journal: journal);
      await expectLater(controller.save(original), throwsA(isA<WorkspacePrivatePreferenceRequestFailure>()));
      expect(journal.original?.toJson(), original.toJson());
      reject = false; expect((await controller.check()).saved, true); expect(journal.original, null);
    });
    test('HOST status current-reference mismatch never silently rebases the native form', () async {
      final later = jsonDecode(jsonEncode(fixture['read'])) as Map<String, dynamic>;
      (later['data']['record'] as Map)['revision'] = '3';
      final expected = jsonDecode(jsonEncode(fixture['read']['data']['record'])) as Map<String, dynamic>;
      expected['revision'] = '2';
      final status = jsonDecode(jsonEncode(fixture['status'])) as Map<String, dynamic>;
      (status['data']['result'] as Map)..['currentRevision'] = '2'..['currentFingerprint'] = workspaceLedgerFingerprint(expected);
      final calls = <String>[];
      final source = WorkspacePrivatePreferenceRemoteSource(projectId: original.projectId, scope: original.scope, kind: original.kind,
        connectionId: '0' * 64, current: () => true, request: (body, active, {required mutation, onDispatch}) async {
          expect(mutation, false); calls.add(body['operation'] as String);
          return SocialContentResponse(statusCode: 200, body: jsonEncode(body['operation'] == 'readStorePrivatePreferences' ? later : status));
        });
      await expectLater(source.status(original), throwsFormatException);
      expect(calls, ['checkStorePrivatePreferencesSave', 'readStorePrivatePreferences']);
    });
  }
  if (Platform.environment['AGG10_NATIVE_PRIVATE_PREFERENCE_HTTP_JOIN'] case final base?) {
    if (base != 'http://127.0.0.1:5001') throw StateError('Only the owned loopback HOST bridge is allowed.');
    test('HOST local HTTP unapproved access and dirty inputs make no original-source calls; approved read never saves', () async {
      _initializeHostStorage();
      final fixture = _HostSessionFixture(base); addTearDown(fixture.close);
      expect(await fixture.owner.loadWorkspacePrivatePreferences(WorkspacePrivatePreferenceKind.status, inputPristine: () => true), false);
      final before = await _hostControl(base, {'action': 'metrics'});
      expect((before['counts'] as Map)['readStorePrivatePreferences'], null);
      await fixture.approveHostSource();
      expect(await fixture.owner.loadWorkspacePrivatePreferences(WorkspacePrivatePreferenceKind.status, inputPristine: () => false), false);
      expect(await fixture.owner.loadWorkspacePrivatePreferences(WorkspacePrivatePreferenceKind.status, inputPristine: () => true), true);
      expect(fixture.owner.workspaceBusyMinutes, 4); expect(fixture.owner.workspaceFulfilmentMode, 'Pickup only');
      expect(fixture.owner.workspacePrivatePreferenceSourceProof(WorkspacePrivatePreferenceKind.status), startsWith('store-private-preferences:status:'));
      final after = await _hostControl(base, {'action': 'metrics'});
      expect((after['counts'] as Map)['saveStorePrivatePreferences'], null);
    });
    test('HOST local HTTP free approved Store confirms native staff preference Save with original SDK readback', () async {
      _initializeHostStorage(); final fixture = _HostSessionFixture(base); addTearDown(fixture.close);
      await fixture.approveHostSource();
      expect(await fixture.owner.loadWorkspacePrivatePreferences(WorkspacePrivatePreferenceKind.staff, inputPristine: () => true), true);
      expect(await fixture.owner.saveWorkspacePrivatePreferences(WorkspacePrivatePreferenceKind.staff,
        {'staffAccessEnabled': false, 'counterCount': 0}, current: () => true,
        expectedSourceProof: fixture.owner.workspacePrivatePreferenceSourceProof(WorkspacePrivatePreferenceKind.staff)), false);
      expect(fixture.owner.workspacePrivatePreferencePending(WorkspacePrivatePreferenceKind.staff), null);
      expect(fixture.owner.workspacePrivatePreferenceReady(WorkspacePrivatePreferenceKind.staff), true);
      fixture.owner.saveWorkspaceStaffSettings(staffAccessEnabled: false, counterCount: 3);
      expect(await fixture.owner.saveWorkspacePrivatePreferences(WorkspacePrivatePreferenceKind.staff,
        {'staffAccessEnabled': false, 'counterCount': 3}, current: () => true,
        expectedSourceProof: fixture.owner.workspacePrivatePreferenceSourceProof(WorkspacePrivatePreferenceKind.staff)), true);
      expect(fixture.owner.workspacePrivatePreferenceOriginalFields(WorkspacePrivatePreferenceKind.staff), {'staffAccessEnabled': false, 'counterCount': 3});
      expect(fixture.owner.workspacePrivatePreferencePending(WorkspacePrivatePreferenceKind.staff), null);
      expect(fixture.owner.workspacePrivatePreferenceReady(WorkspacePrivatePreferenceKind.staff), true);
    });
    test('HOST local HTTP a background refresh cannot rebase a form captured at an earlier original', () async {
      _initializeHostStorage(); final first = _HostSessionFixture(base), second = _HostSessionFixture(base);
      addTearDown(first.close); addTearDown(second.close); await first.approveHostSource(); await second.approveHostSource();
      const kind = WorkspacePrivatePreferenceKind.status;
      expect(await first.owner.loadWorkspacePrivatePreferences(kind, inputPristine: () => true), true);
      final oldProof = first.owner.workspacePrivatePreferenceSourceProof(kind);
      final draft = {...first.owner.workspacePrivatePreferenceOriginalFields(kind)!, 'busyMinutes': 8};
      expect(await second.owner.loadWorkspacePrivatePreferences(kind, inputPristine: () => true), true);
      final secondFields = {...second.owner.workspacePrivatePreferenceOriginalFields(kind)!, 'busyMinutes': 6};
      expect(await second.owner.saveWorkspacePrivatePreferences(kind, secondFields, current: () => true,
        expectedSourceProof: second.owner.workspacePrivatePreferenceSourceProof(kind)), true);
      expect(await first.owner.loadWorkspacePrivatePreferences(kind, refresh: true, inputPristine: () => true), true);
      expect(first.owner.workspacePrivatePreferenceSourceProof(kind), isNot(oldProof));
      final before = await _hostControl(base, {'action': 'metrics'});
      expect(await first.owner.saveWorkspacePrivatePreferences(kind, draft, current: () => true, expectedSourceProof: oldProof), false);
      final after = await _hostControl(base, {'action': 'metrics'});
      expect((after['counts'] as Map)['saveStorePrivatePreferences'], (before['counts'] as Map)['saveStorePrivatePreferences']);
      expect(first.owner.workspacePrivatePreferencePending(kind), null);
      expect(first.owner.workspaceBusyMinutes, 6);
    });
    test('HOST local HTTP lost acknowledgement survives WorkSession restart and status recovers without another Save', () async {
      _initializeHostStorage(); final first = _HostSessionFixture(base); addTearDown(first.close);
      await first.approveHostSource();
      expect(await first.owner.loadWorkspacePrivatePreferences(WorkspacePrivatePreferenceKind.pickup, inputPristine: () => true), true);
      await _hostControl(base, {'action': 'drop_next_save_ack', 'kind': 'pickup'});
      final desired = {'city': 'HOST original city', 'area': 'HOST original area', 'pincode': '560002', 'pickupEnabled': false};
      expect(await first.owner.saveWorkspacePrivatePreferences(WorkspacePrivatePreferenceKind.pickup, desired, current: () => true,
        expectedSourceProof: first.owner.workspacePrivatePreferenceSourceProof(WorkspacePrivatePreferenceKind.pickup)), false);
      final pending = first.owner.workspacePrivatePreferencePending(WorkspacePrivatePreferenceKind.pickup)!;
      final before = await _hostControl(base, {'action': 'metrics'});
      first.close();
      final restarted = _HostSessionFixture(base); addTearDown(restarted.close); await restarted.approveHostSource();
      expect(await restarted.owner.loadWorkspacePrivatePreferences(WorkspacePrivatePreferenceKind.pickup, inputPristine: () => true), false);
      expect(restarted.owner.workspacePrivatePreferencePending(WorkspacePrivatePreferenceKind.pickup)?.toJson(), pending.toJson());
      expect(restarted.owner.workspaceDeliveryCity, desired['city']);
      expect(await restarted.owner.checkWorkspacePrivatePreferenceSave(WorkspacePrivatePreferenceKind.pickup, current: () => true), true);
      final after = await _hostControl(base, {'action': 'metrics'});
      expect((after['counts'] as Map)['saveStorePrivatePreferences'], (before['counts'] as Map)['saveStorePrivatePreferences']);
      expect(restarted.owner.workspacePrivatePreferencePending(WorkspacePrivatePreferenceKind.pickup), null);
      expect(restarted.owner.workspacePrivatePreferenceOriginalFields(WorkspacePrivatePreferenceKind.pickup), desired);
    });
    test('HOST local HTTP revoked original membership blocks Save/status until explicit recovery under restored authority', () async {
      _initializeHostStorage(); final fixture = _HostSessionFixture(base); addTearDown(fixture.close); await fixture.approveHostSource();
      expect(await fixture.owner.loadWorkspacePrivatePreferences(WorkspacePrivatePreferenceKind.invoice, inputPristine: () => true), true);
      await _hostControl(base, {'action': 'membership', 'active': false});
      expect(await fixture.owner.saveWorkspacePrivatePreferences(WorkspacePrivatePreferenceKind.invoice, {'mode': 'automatic'}, current: () => true,
        expectedSourceProof: fixture.owner.workspacePrivatePreferenceSourceProof(WorkspacePrivatePreferenceKind.invoice)), false);
      final original = fixture.owner.workspacePrivatePreferencePending(WorkspacePrivatePreferenceKind.invoice)!;
      expect(await fixture.owner.checkWorkspacePrivatePreferenceSave(WorkspacePrivatePreferenceKind.invoice, current: () => true), false);
      expect(fixture.owner.workspacePrivatePreferencePending(WorkspacePrivatePreferenceKind.invoice)?.toJson(), original.toJson());
      await _hostControl(base, {'action': 'membership', 'active': true});
      expect(await fixture.owner.checkWorkspacePrivatePreferenceSave(WorkspacePrivatePreferenceKind.invoice, current: () => true), false);
      expect(await fixture.owner.checkWorkspacePrivatePreferenceSave(WorkspacePrivatePreferenceKind.invoice, retry: true, current: () => true), true);
      expect(fixture.owner.workspacePrivatePreferenceOriginalFields(WorkspacePrivatePreferenceKind.invoice), {'mode': 'automatic'});
    });
    for (final largeText in [false, true])
    for (final action in ['AI-ACT-318', 'AI-ACT-319', 'AI-ACT-327', 'AI-ACT-322', 'AI-ACT-323', 'AI-ACT-326']) {
      for (final outcome in ['save', if (largeText && action == 'AI-ACT-326') ...['cancel', 'conflict']]) {
      testWidgets('HOST actual native $action ${largeText ? '320 enlarged' : '390 normal'} $outcome Review fills supplied fields and preserves original confirmation', (tester) async {
        tester.view.physicalSize = largeText ? const Size(320, 640) : const Size(390, 844); tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
        _initializeHostStorage(); final fixture = _HostSessionFixture(base);
        final core = BuySession();
        final buy = BuyV2Session(core: core, reviewDataEnabled: false,
          commerceAdapter: const BuyV2UnavailableCommerceAdapter());
        final captureKey = GlobalKey();
        final identity = AuthenticatedAccountIdentity(firebaseUserId: _scope.account, firebaseProjectId: 'demo-moolsocial-local');
        final account = (environment: 'HOST isolated qualification', projectId: 'demo-moolsocial-local', tenantId: null, userId: _scope.account);
        MoolAssistantContext context() => MoolAssistantContext(accountScope: account, authenticationRevision: 1,
          workspaceId: _scope.store, workspaceName: 'HOST Store', workspaceProfile: 'retailer-grocery',
          workspaceRevision: fixture.owner.navigationScopeRevision, storeWorkspace: true, workspaceApproved: true);
        final router = GoRouter(initialLocation: '/app/work/workspace/dashboard', routes: [
          GoRoute(path: '/app/work/workspace/dashboard', builder: (_, _) => WorkWorkspaceDashboardScreen(
            session: fixture.owner, procurementSession: buy, accountIdentity: identity,
            accountAuthenticated: true, accountRecoveryReady: true, initialSection: 'dashboard')),
        ]);
        addTearDown(() {router.dispose(); buy.dispose(); core.dispose(); fixture.close();});
        try {
        await tester.runAsync(fixture.approveHostSource);
        await tester.pumpWidget(MaterialApp.router(theme: MoolTheme.light(), routerConfig: router,
          builder: (appContext, child) => MediaQuery(data: MediaQuery.of(appContext).copyWith(textScaler: TextScaler.linear(largeText ? 1.4 : 1)),
            child: RepaintBoundary(key: captureKey, child: MoolAssistantHost(readContext: context, contextChanges: fixture.owner,
            child: MoolAssistantWorkspaceScope(readWorkspace: () => MoolAssistantWorkspace(id: _scope.store,
              name: 'HOST Store', profile: 'retailer-grocery', revision: fixture.owner.navigationScopeRevision!,
              isStore: true, approved: true, approvalAccountScope: account), child: child!))))));
        await tester.pumpAndSettle();
        final native = find.byType(MoolAssistantNativeScope); expect(native, findsOneWidget);
        final adapters = tester.widget<MoolAssistantNativeScope>(native).readAdapters(tester.element(native));
        final adapter = adapters.singleWhere((value) => value.actionId == action);
        final snapshot = await tester.runAsync(() => adapter.snapshot(context(), null)); expect(snapshot, isNotNull);
        final fields = switch (action) {
          'AI-ACT-318' => <String, Object?>{'acceptingOrders': false, 'busyMinutes': '7'},
          'AI-ACT-319' => <String, Object?>{'openingTime': '08:15', 'maximumActiveOrders': '5'},
          'AI-ACT-327' => <String, Object?>{'visibleToCustomers': false},
          'AI-ACT-322' => <String, Object?>{'city': 'HOST UI city', 'pincode': '560003'},
          'AI-ACT-323' => <String, Object?>{'mode': 'off'},
          _ => <String, Object?>{'counterCount': '4'},
        };
        final before = await tester.runAsync(() => _hostControl(base, {'action': 'metrics'}));
        final proposal = MoolAssistantProposal(id: 'HOST-native-private-$action', actionId: action, binding: context().binding,
          requestRevision: 0, entitlementRevision: 'HOST preparation already reviewed; not live model access',
          sourceRevision: snapshot!.sourceRevision, validUntil: DateTime.now().add(const Duration(minutes: 2)),
          title: 'HOST original settings', summary: 'HOST original controls', fields: fields);
        MoolAssistantReviewResult? result;
        final opening = adapter.openReview(proposal, () => true).then((value) {result = value; return value;});
        await _pumpOwnedHttp(tester);
        final kind = workspacePrivatePreferenceKindForAction(action)!;
        final reviewed = await tester.runAsync(() => _hostControl(base, {'action': 'metrics'}));
        expect((reviewed!['counts'] as Map)['saveStorePrivatePreferences'], (before!['counts'] as Map)['saveStorePrivatePreferences']);
        expect(result, isNot(MoolAssistantReviewResult.stale));
        if (action == 'AI-ACT-322') {
          final controls = tester.widgetList<TextFormField>(find.byType(TextFormField));
          expect(controls.any((value) => value.controller?.text == 'HOST UI city'), true);
          expect(controls.any((value) => value.controller?.text == '560003'), true);
        } else if (action == 'AI-ACT-326') {
          expect(tester.widgetList<TextFormField>(find.byType(TextFormField)).any((value) => value.controller?.text == '4'), true);
        } else if (action == 'AI-ACT-323') {
          expect(find.byKey(const Key('work-invoice-proposed-mode')), findsOneWidget);
        } else {
          final dynamic status = tester.widget(find.byWidgetPredicate((value) => value.runtimeType.toString() == '_WorkspaceStatusSurface'));
          if (action == 'AI-ACT-318') {expect(status.acceptingOrders, false); expect(status.busyMinutes, 7);}
          if (action == 'AI-ACT-319') {expect(status.openingTime, '08:15'); expect(status.maximumActiveOrders, 5);}
          if (action == 'AI-ACT-327') expect(status.visibleToCustomers, false);
        }
        final staffEditor = action == 'AI-ACT-326' ? tester.state(find.byWidgetPredicate(
          (value) => value.runtimeType.toString() == '_WorkspaceStaffSettingsSurface')) : null;
        final staffDraft = action == 'AI-ACT-326' ? tester.widgetList<TextFormField>(find.byType(TextFormField)).single.controller : null;
        if (outcome == 'cancel') {
          await tester.tap(find.byType(BackButton)); await _pumpOwnedHttp(tester); await opening;
          final after = await tester.runAsync(() => _hostControl(base, {'action': 'metrics'}));
          expect((after!['counts'] as Map)['saveStorePrivatePreferences'], (before['counts'] as Map)['saveStorePrivatePreferences']);
          expect(fixture.owner.workspacePrivatePreferencePending(kind), null); return;
        }
        if (outcome == 'conflict') {
          await tester.runAsync(() async {
            final other = _HostSessionFixture(base);
            try {
              await other.approveHostSource();
              expect(await other.owner.loadWorkspacePrivatePreferences(kind, inputPristine: () => true), true);
              expect(await other.owner.saveWorkspacePrivatePreferences(kind,
                {...other.owner.workspacePrivatePreferenceOriginalFields(kind)!, 'counterCount': 6}, current: () => true,
                expectedSourceProof: other.owner.workspacePrivatePreferenceSourceProof(kind)), true);
            } finally {other.close();}
          });
        }
        final captureDirectory = Platform.environment['AGG10_PRIVATE_FORM_CAPTURE'];
        if (captureDirectory != null) {
          await tester.runAsync(() async {
            final image = await (captureKey.currentContext!.findRenderObject() as RenderRepaintBoundary).toImage();
            final data = await image.toByteData(format: ui.ImageByteFormat.png); image.dispose();
            await File('$captureDirectory/$action-${largeText ? '320-140' : '390-100'}-$outcome.png').writeAsBytes(data!.buffer.asUint8List());
          });
        }
        final key = switch (kind) {
          WorkspacePrivatePreferenceKind.status => 'work-status-save',
          WorkspacePrivatePreferenceKind.pickup => 'work-delivery-settings-save',
          WorkspacePrivatePreferenceKind.invoice => 'work-invoice-apply-proposal',
          WorkspacePrivatePreferenceKind.staff => 'work-staff-settings-save',
        };
        final save = find.byKey(Key(key)); expect(save, findsOneWidget);
        // Review notice must finish before a real tap can reach the original control.
        await tester.pump(const Duration(seconds: 5)); await tester.pumpAndSettle();
        await tester.ensureVisible(save); await tester.pumpAndSettle();
        expect(save.hitTestable(), findsOneWidget);
        await tester.runAsync(() async {await tester.tap(save);});
        await _pumpOwnedHttp(tester);
        expect(fixture.owner.workspacePrivatePreferencePending(kind), null);
        if (outcome == 'conflict') {
          expect(fixture.owner.workspacePrivatePreferenceReady(kind), false);
          expect(fixture.owner.workspacePrivatePreferenceError(kind), contains('changed before this Save'));
          // Retire stale/private controls while retaining the actual editor and draft.
          expect(identical(tester.state(find.byWidgetPredicate((value) =>
            value.runtimeType.toString() == '_WorkspaceStaffSettingsSurface', skipOffstage: false)), staffEditor), true);
          final retainedDraft = staffDraft!; expect(retainedDraft.text, '4');
          void onDraft() {}
          expect(() => retainedDraft.addListener(onDraft), returnsNormally); retainedDraft.removeListener(onDraft);
          expect(find.byKey(const Key('work-staff-settings-save')), findsNothing);
          await tester.runAsync(() async {
            final other = _HostSessionFixture(base);
            try {await other.approveHostSource();
              expect(await other.owner.loadWorkspacePrivatePreferences(kind, inputPristine: () => true), true);
              expect(other.owner.workspacePrivatePreferenceOriginalFields(kind)!['counterCount'], 6);
            } finally {other.close();}
          });
          router.routerDelegate.navigatorKey.currentState!.pop(); await tester.pumpAndSettle(); await opening;
          return;
        }
        final original = fixture.owner.workspacePrivatePreferenceOriginalFields(kind)!;
        for (final entry in fields.entries) {
          expect(original[entry.key], const {'busyMinutes', 'maximumActiveOrders', 'counterCount'}.contains(entry.key)
            ? int.parse(entry.value as String) : entry.value);
        }
        final after = await tester.runAsync(() => _hostControl(base, {'action': 'metrics'}));
        expect(((after!['counts'] as Map)['saveStorePrivatePreferences'] as int),
          ((before['counts'] as Map)['saveStorePrivatePreferences'] as int? ?? 0) + 1);
        expect(tester.takeException(), null);
        if (kind != WorkspacePrivatePreferenceKind.status) {
          router.routerDelegate.navigatorKey.currentState!.pop(); await tester.pumpAndSettle(); await opening;
        } else {await opening;}
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.runAsync(() async {fixture.close();});
          await tester.pumpAndSettle();
        }
      });
      }
    }

  }
}

WorkspacePrivatePreferenceIntent _intent({String key = 'HOST-save-1'}) => WorkspacePrivatePreferenceIntent(
  projectId: _project, scope: _scope, kind: WorkspacePrivatePreferenceKind.status,
  expectedRevision: 0, idempotencyKey: key, fields: _status());
WorkspacePrivatePreferenceResult _result(WorkspacePrivatePreferenceIntent original, {bool absent = false}) {
  if (absent) return WorkspacePrivatePreferenceResult.fromJson({'receipt': null, 'original': null, 'current': null}, original);
  final record = {'version': 1, 'projectId': original.projectId, 'scope': workspacePrivatePreferenceScopeJson(original.scope),
    'kind': original.kind.name, 'revision': (original.expectedRevision + 1).toString(),
    'fields': workspacePrivatePreferenceFieldsToWire(original.kind, original.fields)};
  final fingerprint = workspaceLedgerFingerprint(record), bytes = utf8.encode(workspaceLedgerCanonical(record)).length;
  final pointer = {'id': workspaceLedgerFingerprint({'scope': record['scope'], 'kind': record['kind'], 'revision': record['revision'], 'fingerprint': fingerprint}),
    'fingerprint': fingerprint, 'revision': record['revision'], 'byteLength': bytes, 'parts': (bytes / (192 * 1024)).ceil()};
  final receipt = {'version': 1, 'projectId': original.projectId, 'scope': record['scope'], 'kind': original.kind.name,
    'idempotencyKey': original.idempotencyKey, 'fingerprint': original.fingerprint, 'expectedRevision': original.expectedRevision.toString(),
    'status': 'saved', 'reason': null, 'input': pointer, 'recordedAt': '2026-10-30T00:00:00.000Z'};
  return WorkspacePrivatePreferenceResult.fromJson({'receipt': receipt, 'original': record, 'current': record}, original);
}
class _HostJournal implements WorkspacePrivatePreferenceJournal {
  WorkspacePrivatePreferenceIntent? original;
  WorkspacePrivatePreferenceResult? resolved;
  bool failRetain = false, failResolve = false;
  @override Future<WorkspacePrivatePreferenceIntent?> pending() async => original;
  @override Future<void> retain(WorkspacePrivatePreferenceIntent input) async {
    if (failRetain || original != null) throw StateError('HOST journal refusal'); original = input;
  }
  @override Future<void> resolve(WorkspacePrivatePreferenceIntent input, WorkspacePrivatePreferenceResult result) async {
    if (failResolve || original?.fingerprint != input.fingerprint || !result.confirmed) throw StateError('HOST original retained');
    resolved = result; original = null;
  }
}
class _HostSource implements WorkspacePrivatePreferenceSource {
  bool active = true;
  final calls = <String>[];
  Future<WorkspacePrivatePreferenceResult> Function(WorkspacePrivatePreferenceIntent)? onSave, onStatus;
  @override bool get current => active;
  @override Future<WorkspacePrivatePreferenceRecord?> read() async {calls.add('read'); return null;}
  @override Future<WorkspacePrivatePreferenceResult> save(WorkspacePrivatePreferenceIntent input) async {
    calls.add('save'); return onSave == null ? _result(input) : onSave!(input);
  }
  @override Future<WorkspacePrivatePreferenceResult> status(WorkspacePrivatePreferenceIntent input) async {
    calls.add('status'); return onStatus == null ? _result(input) : onStatus!(input);
  }
}
WorkspacePrivatePreferenceController _controller(_HostSource source, _HostJournal journal) => WorkspacePrivatePreferenceController(
  projectId: _project, scope: _scope, kind: WorkspacePrivatePreferenceKind.status, source: source, journal: journal);
class _HostCredentials implements SocialContentCredentials {
  final modes = <SocialAppCheckTokenMode>[];
  @override Future<String> appCheckToken(SocialAppCheckTokenMode mode) async {modes.add(mode); return 'HOST_ONLY_NOT_AN_APPCHECK_TOKEN';}
  @override Future<String> firebaseIdToken() async => 'HOST_ONLY_NOT_AN_AUTH_TOKEN';
}
class _HostTransport implements SocialContentTransport {
  _HostTransport(this.reply);
  final Future<SocialContentResponse> Function(Map<String, Object?>) reply;
  @override Future<SocialContentResponse> postJson(Uri endpoint, {required Map<String, String> headers, required Map<String, Object?> body}) => reply(body);
}
StoredWorkspacePrivatePreferenceJournal _storedJournal(WorkspacePrivatePreferenceJournalStorage storage,
  {String connectionId = '0000000000000000000000000000000000000000000000000000000000000000', String project = _project}) =>
  StoredWorkspacePrivatePreferenceJournal(projectId: project, scope: _scope, kind: WorkspacePrivatePreferenceKind.status,
    connectionId: connectionId, storage: storage, current: () => true);
class _MemoryJournalStorage implements WorkspacePrivatePreferenceJournalStorage {
  final values = <String, String>{};
  int writes = 0;
  bool failBeforeWrite = false, commitThenThrow = false;
  @override Future<String?> read(String key) async => values[key];
  @override Future<void> write(String key, String value) async {
    if (failBeforeWrite) throw StateError('HOST disk unavailable');
    writes++; values[key] = value;
    if (commitThenThrow) throw StateError('HOST acknowledgement lost');
  }
}
void _initializeHostStorage() {
  FlutterSecureStorage.setMockInitialValues({});
  SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
}
Future<Map<String, dynamic>> _hostControl(String base, Map<String, Object?> body) async {
  if (base != 'http://127.0.0.1:5001') throw StateError('Only the owned loopback bridge is allowed.');
  final client = _ownedLoopbackHttpClient();
  try {
    final request = await client.postUrl(Uri.parse('$base/HOST_ONLY'));
    request.headers.set('x-host-test-token', 'HOST_ONLY_PRIVATE_PREF_AGG10'); request.headers.contentType = ContentType.json;
    request.write(jsonEncode(body)); final response = await request.close();
    expect(response.statusCode, 200); return jsonDecode(await utf8.decoder.bind(response).join()) as Map<String, dynamic>;
  } finally {client.close(force: true);}
}
HttpClient _ownedLoopbackHttpClient() {
  if (Platform.environment['AGG10_NATIVE_PRIVATE_PREFERENCE_HTTP_JOIN'] != 'http://127.0.0.1:5001') {
    throw StateError('Actual HTTP is available only for the owned HOST loopback qualification.');
  }
  // Flutter's default test binding returns a synthetic400. Bypass only that
  // constructor override, only in this isolated localhost test; all app paths
  // still use the actual IoSocialContentTransport and original service.
  return _OwnedHostLoopbackHttpOverrides().createHttpClient(null);
}
class _OwnedHostLoopbackHttpOverrides extends HttpOverrides {}
class _HostLocalCredentials implements SocialContentCredentials {
  @override Future<String> firebaseIdToken() async => 'HOST_ONLY_NOT_AN_AUTH_TOKEN';
  @override Future<String> appCheckToken(SocialAppCheckTokenMode mode) async => mode == SocialAppCheckTokenMode.limitedUse
    ? 'HOST_ONLY_LIMITED_USE_APPCHECK' : 'HOST_ONLY_STANDARD_APPCHECK';
}
class _HostContactScope implements WorkPendingProofStore {
  @override String? get accountScope => _scope.account;
  @override Future<Map<String, Object?>?> read(String scope) async => null;
  @override Future<void> save(String scope, Map<String, Object?> draft) async {}
  @override Future<void> clear(String scope) async {}
}
class _HostWorkspaceGateway extends UnavailableWorkGateway {
  WorkReviewResult _record() {
    final checked = DateTime.now().toUtc().subtract(const Duration(seconds: 1));
    return WorkReviewResult(caseId: 'HOST-private-preference-case', status: WorkRemoteReviewStatus.approved, plan: 'free',
      workspaceId: _scope.store, profileId: 'retailer-grocery', name: 'HOST private Store', area: 'HOST area',
      access: WorkWorkspaceAccess(accountId: _scope.account, caseId: 'HOST-private-preference-case', workspaceId: _scope.store,
        profileId: 'retailer-grocery', version: 1, membershipId: 'HOST-private-member', applicationUpdatedAt: checked,
        checkedAt: checked, effectiveFrom: checked, expiresAt: checked.add(const Duration(minutes: 10))));
  }
  @override Future<List<WorkReviewResult>> loadFeed() async => [_record()];
  @override Future<WorkReviewResult> checkReview(String caseId) async {
    if (caseId != 'HOST-private-preference-case') throw StateError('Foreign HOST case'); return _record();
  }
}
class _HostSessionFixture {
  _HostSessionFixture(String base) {
    transport = IoSocialContentTransport(client: _ownedLoopbackHttpClient(), maximumResponseBytes: 8 * 1024 * 1024, followRedirects: false);
    owner = WorkSession(gateway: _HostWorkspaceGateway(), contactDraftStore: _HostContactScope(),
      catalogueGateway: AuthenticatedWorkspaceCatalogueGateway(endpoint: Uri.parse('$base/demo-moolsocial-local/asia-south1/moolSocialWorkspace'),
        realm: 'evaluation', credentials: _HostLocalCredentials(), transport: transport, privateOriginalTransport: transport,
        ownerAccountId: _scope.account, privatePreferencesSupported: true, privatePreferencesProjectId: 'demo-moolsocial-local'))
      ..activeWorkspace = WorkWorkspace(id: _scope.store, name: 'HOST Store', profileLabel: 'HOST Store',
        profileId: 'retailer-grocery', area: 'HOST area', verified: true);
  }
  late final IoSocialContentTransport transport;
  late final WorkSession owner;
  bool closed = false;
  Future<void> approveHostSource() async {
    expect(await owner.recoverWorkspaceAccount(accountReady: true), true); await owner.refreshFeed(); expect(owner.hasVerifiedWorkspace, true);
  }
  void close() {if (closed) return; closed = true; owner.dispose(); transport.close(force: true);}
}

Future<void> _pumpOwnedHttp(WidgetTester tester) async {
  // Real localhost I/O runs outside the fake widget clock; never applies on OPPO.
  for (var pass = 0; pass < 12; pass++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 40));
  }
  await tester.pumpAndSettle();
}
