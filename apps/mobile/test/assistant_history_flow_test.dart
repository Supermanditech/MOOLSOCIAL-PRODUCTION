import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/assistant/mool_assistant.dart';
import 'package:moolsocial/features/assistant/history_gateway.dart';
import 'package:moolsocial/features/assistant/model_gateway.dart';
import 'package:moolsocial/features/shared/social_content_gateway.dart';
import 'package:moolsocial/ui_v2/assistant/mool_assistant_v2.dart';
import 'assistant_history_gateway_test.dart' show historyOwner, historyContext,
  HistoryJournal, HistoryWire, historyGateway, historyOk, historySnapshot;
import 'assistant_model_flow_test.dart' show ModelEntitlements;
import 'assistant_model_gateway_test.dart' show ModelCredentials, ModelTransport, modelAt, modelResponse;

class _Host {
  _Host(this.wire) {
    source = historyGateway(wire, journal);
    controller = MoolAssistantController(currentContext: () => state.value, contextChanges: state, historySource: source);
  }
  final HistoryWire wire;
  final journal = HistoryJournal();
  final state = ValueNotifier(historyContext);
  late final AssistantHistoryGateway source;
  late final MoolAssistantController controller;
  void dispose() {controller.dispose(); source.dispose(); state.dispose();}
}
class _DraftOnly implements MoolAssistantHistorySource {
  int writes = 0;
  @override Future<MoolAssistantHistoryPage> list(MoolAssistantContext c, {String? cursor}) async =>
    MoolAssistantHistoryPage(binding: c.binding, items: []);
  @override Future<MoolAssistantConversation> read(MoolAssistantContext c, String id) async => throw StateError('No fixture read');
  @override Future<MoolAssistantConversation> saveDraft(MoolAssistantContext c, {required String draftKey,
    String? conversationId, required String text, required String language, required List<MoolAssistantAttachment> attachments}) async {
    writes++; throw StateError('Do not drop messages into a draft-only receiver');
  }
}
Map<String, Object?> _summary(String id, String title) => {'id': id, 'revision': 1, 'title': title, 'updatedAt': '2026-10-28T00:00:00.000Z'};

void main() {
  test('History New chat preserves completed messages even when the composer is empty', () async {
    Map<String, Object?>? payload;
    final h = _Host(HistoryWire((b) {
      payload = Map<String, Object?>.from(b['payload'] as Map);
      return historyOk({'state': 'confirmed', 'conversation': historySnapshot(payload!)});
    })); addTearDown(h.dispose);
    h.controller.messages = const [(true, 'चावल खरीदना है'), (false, 'Review first. No order was placed.')];
    expect(h.controller.hasInput, false); expect(await h.controller.changeConversation(), true);
    expect(payload!['messages'], hasLength(2)); expect(payload!['draft'], '');
    expect(h.controller.messages, isEmpty); expect(h.controller.conversationId, isNull); expect(h.controller.proposal, isNull);
  });
  test('History failed acknowledgement retains draft/messages; retry reconciles before any duplicate save', () async {
    Map<String, Object?>? saved; var writes = 0;
    final h = _Host(HistoryWire((b) {
      if (b['operation'] == 'save') {writes++; saved = historySnapshot(Map<String, Object?>.from(b['payload'] as Map)); throw StateError('Host lost acknowledgement');}
      expect(b['operation'], 'status'); return historyOk({'state': 'confirmed', 'conversation': saved});
    })); addTearDown(h.dispose);
    h.controller.setDraft('Keep my new request'); h.controller.messages = const [(true, 'Earlier text')];
    expect(await h.controller.changeConversation(), false);
    expect(h.controller.draft, 'Keep my new request'); expect(h.controller.messages.single.$2, 'Earlier text');
    expect(await h.controller.changeConversation(), true); expect(writes, 1); expect(h.controller.draft, '');
  });
  test('History a newer draft is never retired by an earlier accepted completion', () async {
    final waiting = Completer<void>(); Map<String, Object?>? saved; var writes = 0;
    final h = _Host(HistoryWire((b) async {
      if (b['operation'] == 'status') return historyOk({'state': 'confirmed', 'conversation': saved});
      final p = Map<String, Object?>.from(b['payload'] as Map);
      writes++; saved = historySnapshot(p);
      if (writes == 1) await waiting.future;
      return historyOk({'state': 'confirmed', 'conversation': saved});
    })); addTearDown(h.dispose);
    h.controller.setDraft('First draft'); final first = h.controller.changeConversation();
    await Future<void>.delayed(Duration.zero); h.controller.setDraft('Newer draft'); waiting.complete();
    expect(await first, false); expect(h.controller.draft, 'Newer draft');
    expect(await h.controller.changeConversation(), true); expect(writes, 2);
    final saves = h.wire.calls.where((b) => b['operation'] == 'save').toList();
    expect((saves.last['payload'] as Map)['conversationId'], 'chat-one');
    expect((saves.last['payload'] as Map)['expectedRevision'], 1);
  });
  test('History cannot discard a transcript through a legacy draft-only receiver', () async {
    final state = ValueNotifier(historyContext), source = _DraftOnly();
    final c = MoolAssistantController(currentContext: () => state.value, contextChanges: state, historySource: source);
    addTearDown(() {c.dispose(); state.dispose();});
    c.messages = const [(true, 'Must remain'), (false, 'An inert reply')]; c.setDraft('Unsent');
    expect(await c.changeConversation(), false); expect(source.writes, 0);
    expect(c.messages.length, 2); expect(c.draft, 'Unsent');
  });
  test('History model preparation cannot race a New chat save', () async {
    final h = _Host(HistoryWire((_) => throw StateError('No History save during preparation'))); addTearDown(h.dispose);
    h.controller.setDraft('Keep current request'); h.controller.modelBusy = true;
    expect(await h.controller.changeConversation(), false); expect(h.wire.calls, isEmpty);
    expect(h.controller.draft, 'Keep current request'); h.controller.modelBusy = false;
  });
  test('History authoritative denial clears cached rows, preserves current input and allows fresh readback', () async {
    var denied = false;
    final h = _Host(HistoryWire((_) => denied
      ? const SocialContentResponse(statusCode: 403, body: '{"ok":false,"error":{"code":"ai_access_required"}}')
      : historyOk({'items': [_summary('one', 'My private chat')], 'nextCursor': null}))); addTearDown(h.dispose);
    await h.controller.loadHistory(); expect(h.controller.history.length, 1);
    h.controller.setDraft('Retain my input'); denied = true; await h.controller.loadHistory();
    expect(h.controller.history, isEmpty); expect(h.controller.draft, 'Retain my input');
    denied = false; await h.controller.loadHistory(); expect(h.controller.history.length, 1);
  });
  test('History account/Store change rejects old completions and leaves the new context alone', () async {
    final waiting = Completer<void>();
    final h = _Host(HistoryWire((b) async {
      final p = Map<String, Object?>.from(b['payload'] as Map); await waiting.future;
      return historyOk({'state': 'confirmed', 'conversation': historySnapshot(p)});
    })); addTearDown(h.dispose);
    h.controller.setDraft('Personal request'); final old = h.controller.changeConversation();
    await Future<void>.delayed(Duration.zero);
    h.state.value = const MoolAssistantContext(accountScope: historyOwner, authenticationRevision: 1,
      workspaceId: 'store-b', workspaceName: 'Host Store B', workspaceProfile: 'retailer-grocery',
      workspaceRevision: 1, workspaceApproved: true, storeWorkspace: true);
    h.controller.setDraft('Store B request'); waiting.complete();
    expect(await old, false); expect(h.controller.draft, 'Store B request'); expect(h.controller.history, isEmpty);
    expect(h.controller.context.workspaceId, 'store-b'); expect(h.controller.proposal, isNull);
  });
  test('History retains the full transcript while model preparation receives its supported last twenty turns', () async {
    final state = ValueNotifier(historyContext), paid = ModelEntitlements();
    final wire = ModelTransport((b) {
      if (b['operation'] == 'cancel') return modelResponse({'state': 'cancelled'});
      final p = Map<String, Object?>.from(b['payload'] as Map), turns = p['history'] as List;
      expect(turns.length, 20); expect((turns.first as Map)['text'], 'Turn 12');
      return modelResponse({'state': 'ready', 'reply': {
        'scope': p['scope'], 'requestId': p['requestId'], 'requestRevision': p['requestRevision'],
        'entitlementRevision': p['expectedEntitlementRevision'], 'checkedAt': modelAt.toIso8601String(),
        'validUntil': modelAt.add(const Duration(minutes: 1)).toIso8601String(),
        'outcome': {'kind': 'clarification', 'text': 'Which quantity do you need?'},
      }});
    });
    final model = AssistantModelGateway(owner: historyOwner, isCurrent: () => true,
      credentials: ModelCredentials(), transport: wire, pendingStore: HistoryJournal(), clock: () => modelAt);
    Map<String, Object?>? saved;
    final history = historyGateway(HistoryWire((b) {
      saved = Map<String, Object?>.from(b['payload'] as Map);
      return historyOk({'state': 'confirmed', 'conversation': historySnapshot(saved!)});
    }), HistoryJournal());
    final c = MoolAssistantController(currentContext: () => state.value, contextChanges: state, entitlements: paid,
      readModelSource: () => model, historySource: history, clock: () => modelAt);
    addTearDown(() {c.dispose(); model.dispose(); history.dispose(); paid.dispose(); state.dispose();});
    await c.refreshAccess(); c.messages = List.generate(32, (i) => (i.isEven, 'Turn ' + i.toString()));
    c.setDraft('Continue this conversation'); expect(await c.sendRequest(), true);
    expect(c.messages.first.$2, 'Turn 0'); expect(c.messages.length, 34);
    expect(await c.changeConversation(), true); expect(saved!['messages'], hasLength(34));
  });
  testWidgets('History messages-only Close uses the existing Save and close confirmation', (tester) async {
    Map<String, Object?>? saved;
    final h = _Host(HistoryWire((b) {
      saved = Map<String, Object?>.from(b['payload'] as Map);
      return historyOk({'state': 'confirmed', 'conversation': historySnapshot(saved!)});
    })); addTearDown(h.dispose);
    h.controller.messages = const [(true, 'Keep this conversation'), (false, 'An inert explanation')];
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) => TextButton(
      onPressed: () => Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => MoolAssistantPage(controller: h.controller))),
      child: const Text('Open chat')))));
    await tester.tap(find.text('Open chat')); await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close Mool AI')); await tester.pumpAndSettle();
    expect(find.text('Save & close'), findsOneWidget);
    await tester.tap(find.text('Save & close')); await tester.pumpAndSettle();
    expect(saved!['messages'], hasLength(2)); expect(saved!['draft'], '');
    expect(find.text('Open chat'), findsOneWidget); expect(h.controller.messages, isEmpty);
  });
  for (final scale in [1.0, 2.0]) {
    testWidgets('History original search/Clear/resume is readable and inert at text scale ' + scale.toString(), (tester) async {
      tester.view.physicalSize = const Size(360, 800); tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
      final h = _Host(HistoryWire((b) {
        if (b['operation'] == 'list') return historyOk({'items': [_summary('rice', 'Rice enquiry'), _summary('tea', 'Tea enquiry')], 'nextCursor': null});
        final p = Map<String, Object?>.from(b['payload'] as Map);
        expect(b['operation'], 'read');
        return historyOk({'conversation': historySnapshot({'expectedRevision': 0, 'draft': 'Saved unsent request', 'language': 'Auto',
          'messages': [{'role': 'assistant', 'text': 'A historical suggestion; no current action is approved.'}]}, id: p['id'] as String)});
      })); addTearDown(h.dispose);
      await tester.pumpWidget(MaterialApp(home: MediaQuery(data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: MoolAssistantPage(controller: h.controller))));
      await tester.pumpAndSettle(); await tester.tap(find.byTooltip('History')); await tester.pumpAndSettle();
      final search = find.byKey(const Key('mool-assistant-history-search')); expect(search, findsOneWidget);
      await tester.enterText(search, 'Rice'); await tester.pump();
      expect(find.text('Rice enquiry'), findsOneWidget); expect(find.text('Tea enquiry'), findsNothing);
      await tester.tap(find.byTooltip('Clear chat search')); await tester.pump();
      expect(find.text('Tea enquiry'), findsOneWidget);
      FocusManager.instance.primaryFocus?.unfocus(); await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('assistant-history-rice'))); await tester.pumpAndSettle();
      expect(h.controller.conversationId, 'rice'); expect(h.controller.conversationRevision, 1);
      expect(h.controller.draft, 'Saved unsent request'); expect(h.controller.proposal, isNull);
      expect(h.wire.calls.where((b) => b['operation'] == 'save'), isEmpty); expect(tester.takeException(), isNull);
    });
  }
}
