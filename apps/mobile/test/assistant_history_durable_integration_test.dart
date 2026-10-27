import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/assistant/history_gateway.dart';
import 'package:moolsocial/features/assistant/mool_assistant.dart';
import 'package:moolsocial/features/shared/social_content_gateway.dart';
import 'assistant_history_gateway_test.dart' show HistoryJournal, HistoryCredentials,
  historyOwner, historyContext;

const _port = int.fromEnvironment('AI_HISTORY_TEST_PORT');
const _phase = String.fromEnvironment('AI_HISTORY_CLIENT_PHASE');
const _journalDirectory = String.fromEnvironment('AI_HISTORY_JOURNAL_DIR');
const _functional = _port != 0 && _phase == '';
// Opt-in loopback tests use a real client, outside flutter_test's intentional
// HTTP-400 stub. This override is never part of the application/runtime.
class _LocalHttp extends HttpOverrides {}
HttpClient _realClient() => HttpOverrides.runWithHttpOverrides(() => HttpClient(), _LocalHttp());
class _LocalWire implements SocialContentTransport {
  _LocalWire() {delegate = IoSocialContentTransport(client: client, followRedirects: false);}
  final client = _realClient();
  late final IoSocialContentTransport delegate;
  final operations = <String>[];
  @override Future<SocialContentResponse> postJson(Uri endpoint, {required Map<String, String> headers, required Map<String, Object?> body}) {
    expect(endpoint.host, 'asia-south1-fixture-project.cloudfunctions.net');
    expect(endpoint.path, '/moolSocialAssistantHistory');
    operations.add(body['operation'] as String);
    return delegate.postJson(Uri.http('127.0.0.1:' + _port.toString(), endpoint.path), headers: headers, body: body);
  }
  void close() {client.close(force: true);}
}
class _Files extends HistoryJournal {
  _Files(String path) : directory = Directory(path) {directory.createSync(recursive: true);}
  final Directory directory;
  File file(String key) {expect(RegExp(r'^[a-f0-9]{64}$').hasMatch(key), true); return File(directory.path + '/' + key + '.json');}
  @override Future<String?> read(String key) async {final p = file(key); return await p.exists() ? p.readAsString() : null;}
  @override Future<void> write(String key, String data) async {await file(key).writeAsString(data, flush: true);}
  @override Future<void> clear(String key) async {final p = file(key); if (await p.exists()) await p.delete();}
}
Future<Map<String, Object?>> _control([String query = '']) async {
  final client = _realClient();
  try {
    final request = await client.getUrl(Uri.parse('http://127.0.0.1:' + _port.toString() + '/__fixture__' + query));
    final response = await request.close(); expect(response.statusCode, 200);
    return Map<String, Object?>.from(jsonDecode(await utf8.decodeStream(response)) as Map);
  } finally {client.close(force: true);}
}
class _Rig {
  _Rig({HistoryJournal? journal}) {
    source = AssistantHistoryGateway(owner: historyOwner, isCurrent: () => true, credentials: HistoryCredentials(),
      transport: wire, journal: journal ?? HistoryJournal());
    controller = MoolAssistantController(currentContext: () => state.value, contextChanges: state, historySource: source);
  }
  final wire = _LocalWire();
  final state = ValueNotifier(historyContext);
  late final AssistantHistoryGateway source;
  late final MoolAssistantController controller;
  void dispose() {controller.dispose(); source.dispose(); state.dispose(); wire.close();}
}
Future<MoolAssistantConversation> _original(AssistantHistoryGateway source, {String? text, List<(bool, String)>? messages}) =>
  source.saveConversation(historyContext, draftKey: 'process-bound-fixture', editorKey: 'process-history-editor',
    expectedRevision: 0, text: text ?? 'Restart-safe original request', language: 'Auto',
    messages: messages ?? const [(true, 'मेरी पुरानी बातचीत'), (false, 'An inert suggestion only.')], attachments: const []);

void main() {
  test('History local actual gateway/handler/SQL/controller saves, reads and edits one original transcript', () async {
    await _control('?reset=1'); final r = _Rig(); addTearDown(r.dispose);
    r.controller.setDraft('આગળનો પ્રશ્ન'); r.controller.messages = const [(true, 'चावल चाहिए'), (false, 'Review quantity; no order placed.')];
    expect(await r.controller.changeConversation(), true);
    await r.controller.loadHistory(); expect(r.controller.history.length, 1);
    final id = r.controller.history.single.id;
    expect(await r.controller.changeConversation(id: id), true);
    expect(r.controller.draft, 'આગળનો પ્રશ્ન'); expect(r.controller.messages.length, 2);
    expect(r.controller.conversationRevision, 1); expect(r.controller.proposal, isNull);
    r.controller.setDraft('Edited exact original'); expect(await r.controller.changeConversation(), true);
    final saved = await r.source.read(historyContext, id);
    expect(saved.revision, 2); expect(saved.draft, 'Edited exact original');
    final stats = await _control(); expect(stats['conversations'], 1); expect(stats['revisions'], 2);
    expect(stats['modelCalls'], 0); expect(stats['domainEffects'], 0);
  }, skip: !_functional);
  test('History local original lost response is recovered before retry without a second SQL effect', () async {
    await _control('?reset=1'); await _control('?lose=1'); final r = _Rig(); addTearDown(r.dispose);
    r.controller.setDraft('Retain this exact draft'); r.controller.messages = const [(true, 'Original user text')];
    expect(await r.controller.changeConversation(), false); expect(r.controller.draft, 'Retain this exact draft');
    expect(await r.controller.changeConversation(), true);
    final stats = await _control(); expect(stats['conversations'], 1); expect(stats['revisions'], 1);
    expect(r.wire.operations, ['save', 'status']);
  }, skip: !_functional);
  test('History local two stale native editors cannot overwrite a newer original revision', () async {
    await _control('?reset=1'); final left = _Rig(), right = _Rig(); addTearDown(left.dispose); addTearDown(right.dispose);
    await _original(left.source); await left.controller.loadHistory(); await right.controller.loadHistory();
    final id = left.controller.history.single.id;
    expect(await left.controller.changeConversation(id: id), true); expect(await right.controller.changeConversation(id: id), true);
    left.controller.setDraft('Left accepted edit'); expect(await left.controller.changeConversation(), true);
    right.controller.setDraft('Keep stale right input'); expect(await right.controller.changeConversation(), false);
    expect(right.controller.draft, 'Keep stale right input'); expect((await left.source.read(historyContext, id)).draft, 'Left accepted edit');
    expect((await _control())['revisions'], 2);
  }, skip: !_functional);
  test('History local actual Plans/Workspace services isolate Personal and approved Store contexts', () async {
    await _control('?reset=1'); final r = _Rig(); addTearDown(r.dispose); await _original(r.source);
    for (final store in ['store-a', 'store-b']) {
      final c = MoolAssistantContext(accountScope: historyOwner, authenticationRevision: 1, workspaceId: store,
        workspaceName: 'Host ' + store, workspaceProfile: 'retailer-grocery', workspaceRevision: 1,
        workspaceApproved: true, storeWorkspace: true);
      await r.source.saveConversation(c, draftKey: store, editorKey: store, expectedRevision: 0,
        text: 'Private ' + store, language: 'Auto', messages: const [], attachments: const []);
      final page = await r.source.list(c); expect(page.items.length, 1);
      expect((await r.source.read(c, page.items.single.id)).draft, 'Private ' + store);
    }
    expect((await r.source.list(historyContext)).items.length, 1);
    await _control('?revoke=1');
    const revoked = MoolAssistantContext(accountScope: historyOwner, authenticationRevision: 1, workspaceId: 'store-a',
      workspaceProfile: 'retailer-grocery', workspaceRevision: 1, workspaceApproved: true, storeWorkspace: true);
    await expectLater(r.source.list(revoked), throwsA(anything));
    expect((await r.source.list(historyContext)).items.length, 1);
  }, skip: !_functional);
  test('History local paid withdrawal and restriction return unavailable rather than private cached rows', () async {
    await _control('?reset=1'); final r = _Rig(); addTearDown(r.dispose); await _original(r.source);
    await r.controller.loadHistory(); expect(r.controller.history.length, 1);
    r.controller.setDraft('Unsaved new input'); await _control('?deny=1'); await r.controller.loadHistory();
    expect(r.controller.history, isEmpty); expect(r.controller.draft, 'Unsaved new input');
    await _control('?deny=0'); await r.controller.loadHistory(); expect(r.controller.history.length, 1);
    await _control('?restrict=1'); await expectLater(r.source.list(historyContext), throwsA(anything));
    await _control('?restrict=0');
  }, skip: !_functional);
  test('History local original cursor pages summaries and controller merges without duplicates', () async {
    await _control('?reset=1'); final r = _Rig(); addTearDown(r.dispose);
    for (var n = 0; n < 23; n++) {
      await r.source.saveConversation(historyContext, draftKey: 'page-' + n.toString(), editorKey: 'page-' + n.toString(),
        expectedRevision: 0, text: 'Chat ' + n.toString(), language: 'Auto', messages: const [], attachments: const []);
    }
    await r.controller.loadHistory(); expect(r.controller.history.length, 20); expect(r.controller.historyCursor, isNotNull);
    await r.controller.loadHistory(more: true); expect(r.controller.history.length, 23);
    expect(r.controller.history.map((v) => v.id).toSet().length, 23); expect(r.controller.historyCursor, isNull);
    expect((await _control())['modelCalls'], 0);
  }, skip: !_functional);
  test('History process prepare original save with a lost response and durable identity-only client journal', () async {
    expect(_journalDirectory.isNotEmpty, true); await _control('?reset=1'); await _control('?lose=1');
    final files = _Files(_journalDirectory), r = _Rig(journal: files); addTearDown(r.dispose);
    await expectLater(_original(r.source), throwsA(anything));
    final stats = await _control(); expect(stats['conversations'], 1); expect(stats['revisions'], 1);
    final journals = files.directory.listSync().whereType<File>().where((p) => p.path.endsWith('.json')).toList(); expect(journals.length, 1);
    final raw = await journals.single.readAsString();
    expect(raw, isNot(contains('Restart-safe'))); expect(raw, isNot(contains('मेरी'))); expect(raw, isNot(contains('host-history-token')));
    await File(_journalDirectory + '/prepare-result.evidence').writeAsString(jsonEncode({'clientPid': pid,
      'backendPid': stats['backendPid'], 'conversations': 1, 'revisions': 1, 'identityOnlyClientJournal': true}));
  }, skip: _port == 0 || _phase != 'prepare');
  test('History process recover after independent client/backend restart reads inert text and original receipt only', () async {
    final files = _Files(_journalDirectory), r = _Rig(journal: files); addTearDown(r.dispose);
    await r.controller.loadHistory(); expect(r.controller.history.length, 1);
    expect(await r.controller.changeConversation(id: r.controller.history.single.id), true);
    expect(r.controller.draft, 'Restart-safe original request'); expect(r.controller.messages.length, 2); expect(r.controller.proposal, isNull);
    // Explicit retry of the exact original fixture request. Supplied text is
    // read from its real saved source; no consent or action is reconstructed.
    final recovered = await _original(r.source, text: r.controller.draft, messages: r.controller.messages);
    expect(recovered.revision, 1); expect(r.wire.operations, ['list', 'read', 'status']);
    final stats = await _control(); expect(stats['conversations'], 1); expect(stats['revisions'], 1);
    final before = Map<String, Object?>.from(jsonDecode(await File(_journalDirectory + '/prepare-result.evidence').readAsString()) as Map);
    expect(before['clientPid'], isNot(pid)); expect(before['backendPid'], isNot(stats['backendPid']));
    await File(_journalDirectory + '/recovery-result.evidence').writeAsString(jsonEncode({'clientPid': pid,
      'backendPid': stats['backendPid'], 'conversations': stats['conversations'], 'revisions': stats['revisions'],
      'originalStatusOnly': true, 'restoredExecutableProposal': false, 'modelCalls': stats['modelCalls'], 'domainEffects': stats['domainEffects']}));
  }, skip: _port == 0 || _phase != 'recover');
}
