import 'dart:async';
import 'package:crypto/crypto.dart' as selected_document_hash;
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugDefaultTargetPlatformOverride;
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/assistant/mool_assistant.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/work/work_services.dart';
import 'package:moolsocial/features/work/work_session.dart';
import 'package:moolsocial/features/work/work_models.dart';
import 'package:moolsocial/features/chat/chat_models.dart'
    show ChatAttachmentKind;
import 'package:moolsocial/features/chat/chat_services.dart'
    show ChatVoiceRecorder, ChatAttachmentPicker, ChatPickedAttachment;
import 'package:moolsocial/ui_v2/assistant/mool_assistant_v2.dart';
import 'package:moolsocial/ui_v2/universal/mool_global_navigation_v2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';

// Isolated host fixtures only; production composition supplies no connector.
class _Context extends ChangeNotifier {
  bool get observed => hasListeners;
  MoolAssistantContext value = _context('a', 1);
  void change(MoolAssistantContext next) {
    value = next;
    notifyListeners();
  }
}

MoolAssistantContext _context(String? account, int revision, {String? store}) =>
    MoolAssistantContext(
      accountScope: account,
      authenticationRevision: account == null ? null : revision,
      workspaceId: store,
      workspaceName: store == null ? null : 'Host fixture Store',
      workspaceProfile: store == null ? null : 'retailer',
      workspaceRevision: store == null ? null : revision,
      storeWorkspace: store != null,
      workspaceApproved: store != null,
    );

class _Entitlements extends ChangeNotifier
    implements MoolAssistantEntitlementSource {
  _Entitlements(this.response);
  Future<MoolAssistantEntitlement> Function(Object) response;
  int calls = 0;
  @override
  Future<MoolAssistantEntitlement> read(Object accountScope) {
    calls++;
    return response(accountScope);
  }

  bool get observed => hasListeners;
  void invalidate() => notifyListeners();
}

class _Voice implements ChatVoiceRecorder {
  int starts = 0, stops = 0, cancels = 0;
  bool disposed = false;
  Completer<void>? pendingStart;
  @override
  Future<void> start() async {
    starts++;
    await pendingStart?.future;
  }

  @override
  Future<ChatPickedAttachment> stop() async {
    stops++;
    return ChatPickedAttachment(
      kind: ChatAttachmentKind.voice,
      name: 'Voice message.m4a',
      contentType: 'audio/mp4',
      bytes: Uint8List(32),
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Future<void> cancel() async {
    cancels++;
  }

  @override
  void dispose() {
    disposed = true;
  }
}

class _Media implements ChatAttachmentPicker {
  int calls = 0;
  int bytes = 32;
  @override
  Future<ChatPickedAttachment?> pick(ChatAttachmentKind kind) async {
    calls++;
    return ChatPickedAttachment(
      kind: kind,
      name: kind == ChatAttachmentKind.video ? 'product.mp4' : 'bill.pdf',
      contentType: kind == ChatAttachmentKind.video
          ? 'video/mp4'
          : 'application/pdf',
      bytes: Uint8List(bytes),
    );
  }
}

class _Picker implements WorkProofPicker {
  int calls = 0;
  final pending = Completer<WorkPickedProof?>();
  @override
  Future<WorkPickedProof?> pick(WorkProofSource source) {
    calls++;
    return pending.future;
  }
}

class _AssistantDraftStore implements WorkPendingProofStore {
  _AssistantDraftStore(this.accountScope);
  @override
  final String accountScope;
  @override
  Future<Map<String, Object?>?> read(String scope) async => null;
  @override
  Future<void> save(String scope, Map<String, Object?> draft) async {}
  @override
  Future<void> clear(String scope) async {}
}

MoolAssistantEntitlement _entitlement(
  Object account,
  MoolAssistantAccess access, {
  DateTime? until,
  String revision = 'server-host-fixture-1',
}) => MoolAssistantEntitlement(
  accountScope: account,
  access: access,
  revision: revision,
  validUntil: until ?? DateTime.now().add(const Duration(hours: 1)),
);

MoolAssistantController _controller(
  _Context context, {
  _Entitlements? source,
  _Picker? picker,
  DateTime Function()? clock,
  _Voice? voice,
  _Media? media,
  MoolAssistantHistorySource? history,
  Iterable<MoolAssistantNativeAdapter> nativeAdapters = const [],
}) => MoolAssistantController(
  currentContext: () => context.value,
  contextChanges: context,
  entitlements: source,
  attachments: picker,
  clock: clock,
  voiceRecorder: voice,
  mediaPicker: media,
  historySource: history,
  nativeAdapters: nativeAdapters,
);

Future<void> _mount(
  WidgetTester tester,
  MoolAssistantController controller, {
  double scale = 1,
  bool ownsController = false,
  bool? reduceMotion,
  bool? accessibleNavigation,
}) async {
  await tester.pumpWidget(
    RepaintBoundary(
      key: const Key('assistant-audit-screen'),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MoolTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale),
            disableAnimations: reduceMotion, accessibleNavigation: accessibleNavigation),
          child: child!,
        ),
        home: RepaintBoundary(
          key: const Key('assistant-host-capture'),
          child: MoolAssistantPage(
            key: ValueKey(controller),
            controller: controller,
            disposeController: ownsController,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _capture(WidgetTester tester, String name) async {
  final directory = Platform.environment['MOOL_ASSISTANT_CAPTURE_DIR'];
  if (directory == null) return;
  await tester.pump(const Duration(milliseconds: 20));
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('assistant-host-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    await Directory(directory).create(recursive: true);
    await File('$directory/$name.png').writeAsBytes(png!.buffer.asUint8List());
  });
}

class _History implements MoolAssistantHistorySource {
  Future<MoolAssistantHistoryPage> Function(MoolAssistantContext, String?)?
  listing;
  Future<MoolAssistantConversation> Function(MoolAssistantContext, String)?
  reading;
  Future<MoolAssistantConversation> Function(
    MoolAssistantContext,
    String,
    String,
  )?
  saving;
  int saves = 0, reads = 0;
  @override
  Future<MoolAssistantHistoryPage> list(
    MoolAssistantContext c, {
    String? cursor,
  }) async => listing == null
      ? MoolAssistantHistoryPage(binding: c.binding, items: [_thread(c, 'one')])
      : listing!(c, cursor);
  @override
  Future<MoolAssistantConversation> read(
    MoolAssistantContext c,
    String id,
  ) async {
    reads++;
    return reading == null
        ? _thread(c, id, draft: 'stored request')
        : reading!(c, id);
  }

  @override
  Future<MoolAssistantConversation> saveDraft(
    MoolAssistantContext c, {
    required String draftKey,
    String? conversationId,
    required String text,
    required String language,
    required List<MoolAssistantAttachment> attachments,
  }) async {
    saves++;
    return saving == null
        ? _thread(
            c,
            conversationId ?? 'saved',
            draft: text,
            language: language,
            attachments: attachments,
          )
        : saving!(c, text, language);
  }
}

MoolAssistantConversation _thread(
  MoolAssistantContext c,
  String id, {
  String draft = '',
  String language = 'Auto',
  List<MoolAssistantAttachment> attachments = const [],
}) => MoolAssistantConversation(
  id: id,
  binding: c.binding,
  title: 'Host history $id',
  updatedAt: DateTime.utc(2026, 10, 25),
  draft: draft,
  language: language,
  attachments: attachments,
  messages: const [(true, 'Prior user request'), (false, 'Prior explanation')],
);

Future<void> _closeComposerChoices(WidgetTester tester) async {
  for (final label in ['Close media choices', 'Close language choices']) {
    final close = find.byTooltip(label);
    if (close.evaluate().isNotEmpty) {
      await tester.ensureVisible(close);
      await tester.tap(close);
      await tester.pumpAndSettle();
    }
  }
}

Future<void> _tapToolbar(WidgetTester tester, String key) async {
  await _closeComposerChoices(tester);
  final control = find.byKey(Key(key));
  await tester.ensureVisible(control);
  await tester.pumpAndSettle();
  await tester.tap(control);
  await tester.pumpAndSettle();
}

Future<void> _tapLanguageChoice(WidgetTester tester, String value) async {
  final choice = find.byKey(ValueKey('assistant-language-$value'));
  await tester.ensureVisible(choice);
  await tester.pumpAndSettle();
  await tester.tap(choice);
  await tester.pumpAndSettle();
}

Future<void> _tapMediaChoice(WidgetTester tester, String value) async {
  final choice = find.byKey(ValueKey('assistant-media-$value'));
  await tester.ensureVisible(choice);
  await tester.pumpAndSettle();
  await tester.tap(choice);
  await tester.pumpAndSettle();
}

Future<void> _pickTask(WidgetTester tester, String label) async {
  await _closeComposerChoices(tester);
  await tester.ensureVisible(find.byKey(const Key('mool-assistant-actions')));
  await _tapToolbar(tester, 'mool-assistant-actions');
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('mool-assistant-action-search')));
  await tester.enterText(
    find.byKey(const Key('mool-assistant-action-search')),
    label,
  );
  await tester.pumpAndSettle();
  final action = moolAssistantActions.singleWhere(
    (action) => action.label == label,
  );
  final row = find.byKey(ValueKey('assistant-action-${action.id}'));
  await tester.ensureVisible(row);
  await tester.tap(row);
  await tester.pumpAndSettle();
}

Future<void> _dismissTasks(WidgetTester tester) async {
  for (var step = 0; step < 2; step++) {
    final open = find.byKey(const Key('mool-assistant-action-list')).evaluate().isNotEmpty ||
        find.byKey(const Key('mool-assistant-action-categories')).evaluate().isNotEmpty;
    if (!open) return;
    await _tapToolbar(tester, 'mool-assistant-actions');
    await tester.pumpAndSettle();
  }
}

Future<void> _visualShot(WidgetTester tester, String name) async {
  final directory = Platform.environment['MOOL_ASSISTANT_CAPTURE_DIR'];
  if (directory == null) return;
  await tester.pump(const Duration(milliseconds: 20));
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('assistant-audit-screen')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    await Directory(directory).create(recursive: true);
    await File('$directory/$name.png').writeAsBytes(png!.buffer.asUint8List());
  });
}

Future<void> _visualMatrix(WidgetTester tester) async {
  tester.view.physicalSize = const Size(360, 806);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 41, bottom: 44);
  tester.view.viewPadding = const FakeViewPadding(top: 41, bottom: 44);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewPadding);
  addTearDown(tester.view.resetViewInsets);
  final c = _controller(_Context());
  addTearDown(c.dispose);
  await _mount(tester, c);
  await _visualShot(tester, 'public-main');
  await _tapToolbar(tester, 'mool-assistant-actions');
  await tester.pumpAndSettle();
  await _visualShot(tester, 'public-categories');
  await tester.tap(find.byKey(const Key('mool-assistant-action-search')));
  tester.view.viewInsets = const FakeViewPadding(bottom: 260);
  await tester.pumpAndSettle();
  await _visualShot(tester, 'public-search-keyboard');
  await tester.enterText(
    find.byKey(const Key('mool-assistant-action-search')),
    'no-such-task-xyz',
  );
  await tester.pumpAndSettle();
  await _visualShot(tester, 'tasks-no-results');
  tester.view.viewInsets = FakeViewPadding.zero;
  await tester.enterText(
    find.byKey(const Key('mool-assistant-action-search')),
    'invoice',
  );
  await tester.pumpAndSettle();
  await _visualShot(tester, 'invoice-results');
  await _dismissTasks(tester);
  await tester.pumpAndSettle();
  await _tapToolbar(tester, 'mool-assistant-attach');
  await tester.pumpAndSettle();
  await _visualShot(tester, 'media-choices');
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
  await _tapToolbar(tester, 'mool-assistant-language');
  await tester.pumpAndSettle();
  await _visualShot(tester, 'language-menu');
  await _tapLanguageChoice(tester, 'தமிழ்');
  tester.view.viewInsets = const FakeViewPadding(bottom: 260);
  await tester.pumpAndSettle();
  await _visualShot(tester, 'language-selected-keyboard');
  tester.view.viewInsets = FakeViewPadding.zero;
  await tester.pumpAndSettle();
  tester.view.physicalSize = const Size(320, 568);
  await _mount(tester, c);
  await _visualShot(tester, 'narrow-toolbar');
  await _mount(tester, c, scale: 2);
  await tester.ensureVisible(find.byKey(const Key('mool-assistant-actions')));
  await _visualShot(tester, 'narrow-enlarged-toolbar');
  tester.view.physicalSize = const Size(720, 360);
  await _mount(tester, c, scale: 2);
  await tester.ensureVisible(find.byKey(const Key('mool-assistant-actions')));
  await _visualShot(tester, 'landscape-enlarged');

  tester.view.physicalSize = const Size(360, 806);
  final storeContext = _Context()
    ..change(_context('a', 1, store: 'host-store'));
  final store = _controller(storeContext);
  addTearDown(store.dispose);
  await _mount(tester, store);
  await _visualShot(tester, 'store-main');
  await _tapToolbar(tester, 'mool-assistant-actions');
  await tester.pumpAndSettle();
  await _visualShot(tester, 'store-categories');
  await _visualShot(tester, 'store-product-tasks');
  await _dismissTasks(tester);
  await tester.pumpAndSettle();

  final history = _History();
  final pending = Completer<MoolAssistantHistoryPage>();
  history.listing = (_, _) => pending.future;
  final hc = _controller(_Context(), history: history);
  addTearDown(hc.dispose);
  await _mount(tester, hc);
  await tester.tap(find.byTooltip('History'));
  await tester.pump(const Duration(milliseconds: 250));
  await tester.pump(const Duration(milliseconds: 400));
  await _visualShot(tester, 'history-loading');
  pending.complete(
    MoolAssistantHistoryPage(
      binding: hc.context.binding,
      items: [_thread(hc.context, 'one')],
    ),
  );
  await tester.pumpAndSettle();
  await _visualShot(tester, 'history-populated');
  await tester.tap(find.byKey(const ValueKey('assistant-history-one')));
  await tester.pumpAndSettle();
  await _visualShot(tester, 'history-restored-conversation');
  history.listing = (_, _) async =>
      throw StateError('Host unavailable fixture');
  await tester.tap(find.byTooltip('History'));
  await tester.pumpAndSettle();
  await _visualShot(tester, 'history-error');
  history.listing = (context, _) async =>
      MoolAssistantHistoryPage(binding: context.binding, items: []);
  await tester.tap(find.text('Try again'));
  await tester.pumpAndSettle();
  await _visualShot(tester, 'history-empty');
  await tester.tap(find.byTooltip('Close history'));
  await tester.pumpAndSettle();

  final voice = _Voice(), media = _Media();
  final paid = _Entitlements(
    (a) async => _entitlement(a, MoolAssistantAccess.active),
  );
  final mixed = _controller(
    _Context(),
    source: paid,
    voice: voice,
    media: media,
  );
  var mixedDisposed = false;
  addTearDown(() {
    if (!mixedDisposed) mixed.dispose();
  });
  await _mount(tester, mixed);
  await mixed.pickMedia(ChatAttachmentKind.document);
  await mixed.pickMedia(ChatAttachmentKind.video);
  await mixed.toggleVoice();
  await tester.pump(const Duration(seconds: 2));
  await _visualShot(tester, 'voice-recording');
  await mixed.toggleVoice();
  await tester.pumpAndSettle();
  await _visualShot(tester, 'mixed-attachments');

  tester.view.physicalSize = const Size(320, 568);
  await tester.pumpWidget(
    RepaintBoundary(
      key: const Key('assistant-audit-screen'),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MoolTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: MoolAssistantProposalCard(
              title:
                  'Host fixture: prepare a supplier purchase from the printed invoice',
              summary:
                  'Review the original supplier, SKU, pack, quantities and tax details. ચોખા 2 kg / चावल 2 kg. No document was posted.',
              onReview: () {},
              onCancel: () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await _visualShot(tester, 'proposal-enlarged');
  mixed.dispose();
  mixedDisposed = true;
  tester.view.physicalSize = const Size(360, 806);
  final closing = _controller(_Context());
  await tester.pumpWidget(
    RepaintBoundary(
      key: const Key('assistant-audit-screen'),
      child: MaterialApp(
        key: const ValueKey('close-observation-app'),
        debugShowCheckedModeBanner: false,
        theme: MoolTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => MoolAssistantPage(
                    controller: closing,
                    disposeController: true,
                  ),
                ),
              ),
              child: const Text('Open host fixture'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open host fixture'));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const Key('mool-assistant-input')),
    'Host unsent request',
  );
  await tester.tap(find.byTooltip('Close Mool AI'));
  await tester.pumpAndSettle();
  await _visualShot(tester, 'close-prompt');
  final guarded = find.text('Keep editing').evaluate().isNotEmpty;
  final directory = Platform.environment['MOOL_ASSISTANT_CAPTURE_DIR'];
  if (directory != null) {
    await tester.runAsync(
      () => File('$directory/close-observation.txt').writeAsString(
        'confirmationShown=$guarded\ndraftCharactersAfterClose=${closing.draft.length}\n',
      ),
    );
  }
  if (guarded) {
    await tester.tap(find.text('Discard draft'));
    await tester.pumpAndSettle();
  }
  expect(tester.takeException(), isNull);
}

Future<void> _pushCloseFixture(
  WidgetTester tester,
  MoolAssistantController c,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: MoolTheme.light(),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => MoolAssistantPage(controller: c),
              ),
            ),
            child: const Text('Open close fixture'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open close fixture'));
  await tester.pumpAndSettle();
}

// External insertion draft; not a standalone test library.
// Paste this function before main() in apps/mobile/test/mool_assistant_test.dart,
// then call _registerAssistantHistoryPresentationTests() inside main().
// Reuses the existing _Context, _History, _thread, _controller and _mount fixtures.
// Host fixtures only; no production history integration or runtime evidence.
void _registerAssistantHistoryPresentationTests() {
  MoolAssistantConversation row(
    MoolAssistantContext context,
    String id,
    String title,
    DateTime updatedAt,
  ) => MoolAssistantConversation(
    id: id,
    binding: context.binding,
    title: title,
    updatedAt: updatedAt,
    messages: _thread(context, id).messages,
  );

  testWidgets(
    'AI-UI History title search retains zero-match pagination and partial retry',
    (tester) async {
      final context = _Context(), source = _History();
      final requestedCursors = <String?>[];
      var failNextPage = true;
      source.listing = (ctx, cursor) async {
        requestedCursors.add(cursor);
        if (cursor == null) {
          return MoolAssistantHistoryPage(
            binding: ctx.binding,
            items: [
              row(ctx, 'one', 'Weekend groceries', DateTime(2020, 1, 2, 12)),
            ],
            nextCursor: 'page2',
          );
        }
        expect(cursor, 'page2');
        if (failNextPage) {
          failNextPage = false;
          throw StateError('Isolated host pagination failure');
        }
        return MoolAssistantHistoryPage(
          binding: ctx.binding,
          items: [
            row(ctx, 'two', 'Second shopping trip', DateTime(2020, 1, 1, 12)),
          ],
        );
      };
      final c = _controller(context, history: source);
      await _mount(tester, c, ownsController: true);
      await tester.tap(find.byTooltip('History'));
      await tester.pumpAndSettle();

      final search = find.byKey(const Key('mool-assistant-history-search'));
      final first = find.byKey(const ValueKey('assistant-history-one'));
      final second = find.byKey(const ValueKey('assistant-history-two'));
      expect(
        tester.widget<TextField>(search).decoration?.hintText,
        'Search loaded chats',
      );

      // The real retained _thread fixture has this message, but neither title does.
      expect(
        c.history.single.messages.any(
          (message) => message.$2 == 'Prior user request',
        ),
        isTrue,
      );
      await tester.enterText(search, 'Prior user request');
      await tester.pumpAndSettle();
      expect(first, findsNothing);
      expect(find.text('No matching chats'), findsOneWidget);
      expect(find.text('No saved chats yet.'), findsNothing);
      expect(find.text('Load more chats'), findsOneWidget);

      await tester.enterText(search, '  GROCERIES  ');
      await tester.pumpAndSettle();
      expect(first, findsOneWidget);
      expect(find.text('No matching chats'), findsNothing);

      await tester.enterText(search, '  SECOND  ');
      await tester.pumpAndSettle();
      expect(find.text('No matching chats'), findsOneWidget);
      await tester.tap(find.text('Load more chats'));
      await tester.pumpAndSettle();
      expect(c.historyNotice, isNotNull);
      expect(c.history.single.id, 'one');
      expect(find.text('Load more chats'), findsOneWidget);
      expect(
        tester.widget<TextField>(search).decoration?.hintText,
        'Search loaded chats',
      );
      expect(tester.widget<TextField>(search).controller?.text, '  SECOND  ');

      await tester.tap(find.text('Load more chats'));
      await tester.pumpAndSettle();
      expect(requestedCursors, <String?>[null, 'page2', 'page2']);
      expect(first, findsNothing);
      expect(second, findsOneWidget);
      expect(find.text('No matching chats'), findsNothing);
      expect(find.text('Load more chats'), findsNothing);
      expect(tester.widget<TextField>(search).controller?.text, '  SECOND  ');
      expect(
        tester.widget<TextField>(search).decoration?.hintText,
        'Search chats',
      );
      expect(source.reads, 0);
      expect(source.saves, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'AI-UI History stably groups loaded source dates including future dates',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final context = _Context(), source = _History();
      final future = DateTime.now().add(const Duration(days: 2));
      final tied = DateTime(2020, 1, 3, 12);
      source.listing = (ctx, cursor) async => MoolAssistantHistoryPage(
        binding: ctx.binding,
        items: [
          row(ctx, 'tie-first', 'First tie', tied),
          row(ctx, 'oldest', 'Oldest', DateTime(2020, 1, 1, 12)),
          row(ctx, 'future', 'Future', future),
          row(ctx, 'tie-second', 'Second tie', tied),
          row(ctx, 'recent', 'Recent older chat', DateTime(2020, 1, 4, 12)),
        ],
      );
      final c = _controller(context, history: source);
      await _mount(tester, c, ownsController: true);
      await tester.tap(find.byTooltip('History'));
      await tester.pumpAndSettle();

      // The controller already sorts pages. UI stability preserves its loaded tie
      // order, without assuming List.sort guarantees original source-page ties.
      final loadedTies = c.history
          .where((item) => item.updatedAt == tied)
          .map((item) => item.id)
          .toList();
      expect(loadedTies, hasLength(2));
      final expectedOrder = ['future', 'recent', ...loadedTies, 'oldest'];
      final positions = <double>[];
      for (final id in expectedOrder) {
        final finder = find.byKey(ValueKey('assistant-history-$id'));
        expect(finder, findsOneWidget);
        positions.add(tester.getTopLeft(finder).dy);
      }
      for (var index = 0; index < positions.length - 1; index++) {
        expect(positions[index], lessThan(positions[index + 1]));
      }
      expect(find.text('Other dates'), findsOneWidget);
      expect(find.text('Older'), findsOneWidget);
      expect(find.text('Today'), findsNothing);
      expect(find.text('Yesterday'), findsNothing);
      expect(
        tester.getTopLeft(find.text('Other dates')).dy,
        lessThan(positions.first),
      );
      expect(
        tester.getTopLeft(find.text('Older')).dy,
        allOf(greaterThan(positions.first), lessThan(positions[1])),
      );
      expect(find.text('Buy · 4/1/2020'), findsOneWidget);
      final recent = c.history.singleWhere((item) => item.id == 'recent');
      expect(recent.updatedAt, DateTime(2020, 1, 4, 12));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'AI-UI History account change clears and disables search and hides rows',
    (tester) async {
      final context = _Context(), source = _History();
      source.listing = (ctx, cursor) async => MoolAssistantHistoryPage(
        binding: ctx.binding,
        items: [_thread(ctx, 'one')],
        nextCursor: 'page2',
      );
      final c = _controller(context, history: source);
      await _mount(tester, c, ownsController: true);
      await tester.tap(find.byTooltip('History'));
      await tester.pumpAndSettle();
      final search = find.byKey(const Key('mool-assistant-history-search'));
      final first = find.byKey(const ValueKey('assistant-history-one'));
      await tester.enterText(search, 'Host history one');
      await tester.pumpAndSettle();
      expect(first, findsOneWidget);
      expect(find.text('Load more chats'), findsOneWidget);

      // Exercise the real context notifier path, without manually refreshing UI.
      context.change(_context('b', 2));
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(search);
      expect(field.controller?.text, isEmpty);
      expect(field.enabled, isFalse);
      expect(field.decoration?.hintText, 'Search chats');
      expect(first, findsNothing);
      expect(find.text('Load more chats'), findsNothing);
      expect(find.text('No matching chats'), findsNothing);
      expect(find.text('No saved chats yet.'), findsNothing);
      expect(
        find.text('Your account or Store changed. Reopen History.'),
        findsOneWidget,
      );
      expect(find.byTooltip('Close history'), findsOneWidget);
      expect(source.reads, 0);
      expect(source.saves, 0);
      expect(c.messages, isEmpty);
      expect(c.taskId, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}

// DRAFT ONLY: paste into mool_assistant_test.dart per the companion instructions.
// Uses that file's imports, _Context, _context, _Entitlements, _entitlement,
// and _controller helper (extended with nativeAdapters). Not a runtime provider.

class _HandoffAdapter implements MoolAssistantNativeAdapter {
  _HandoffAdapter(Object binding, {this.actionId = 'AI-ACT-001'})
    : currentSnapshot = MoolAssistantNativeSnapshot(
        binding: binding,
        sourceRevision: 'r1',
        permitted: true,
      );

  @override
  final String actionId;
  @override
  Set<String> get allowedFields => const {'query'};
  MoolAssistantNativeSnapshot? currentSnapshot;
  Completer<MoolAssistantNativeSnapshot?>? snapshotGate;
  Completer<MoolAssistantReviewResult>? reviewGate;
  final reviewEntered = Completer<void>();
  int snapshotCalls = 0, reviewCalls = 0;
  bool throwOnReview = false;
  bool Function()? reviewIsCurrent;

  @override
  String? validateFields(Map<String, Object?> fields) {
    final query = fields['query'];
    return query is String && query.trim().isNotEmpty
        ? null
        : 'A query is required.';
  }

  @override
  Future<MoolAssistantNativeSnapshot?> snapshot(
    MoolAssistantContext context,
    String? entityId,
  ) async {
    snapshotCalls++;
    final gate = snapshotGate;
    return gate == null ? currentSnapshot : await gate.future;
  }

  @override
  Future<MoolAssistantReviewResult> openReview(
    MoolAssistantProposal proposal,
    bool Function() isCurrent,
  ) async {
    reviewCalls++;
    reviewIsCurrent = isCurrent;
    if (!reviewEntered.isCompleted) reviewEntered.complete();
    if (throwOnReview) throw StateError('Isolated host review failure');
    final gate = reviewGate;
    final result = gate == null
        ? MoolAssistantReviewResult.opened
        : await gate.future;
    // The native adapter contract requires this guard after an await.
    return isCurrent() ? result : MoolAssistantReviewResult.stale;
  }
}

class _HandoffFixture {
  _HandoffFixture({
    bool registered = true,
    MoolAssistantAccess access = MoolAssistantAccess.active,
    MoolAssistantHistorySource? history,
  }) {
    adapter = _HandoffAdapter(context.value.binding);
    source = _Entitlements(
      (account) async => _entitlement(
        account,
        access,
        until: now.add(const Duration(hours: 1)),
      ),
    );
    controller = _controller(
      context,
      source: source,
      clock: () => now,
      nativeAdapters: registered ? [adapter] : const [],
      history: history,
    );
  }

  final context = _Context();
  DateTime now = DateTime.now();
  late final _HandoffAdapter adapter;
  late final _Entitlements source;
  late final MoolAssistantController controller;

  Future<void> ready({bool withRequest = true}) async {
    await controller.refreshAccess();
    // refreshAccess may retire private input; establish the request afterward.
    if (withRequest) controller.setDraft('Find Rice');
  }

  MoolAssistantProposal proposal({
    String id = 'host-proposal-1',
    String actionId = 'AI-ACT-001',
    Object? binding,
    int? requestRevision,
    String? entitlementRevision,
    String sourceRevision = 'r1',
    String? entityId,
    DateTime? validUntil,
    String title = 'Review product search',
    String summary = 'Find products matching Rice.',
    Map<String, Object?> fields = const {'query': 'Rice'},
  }) => MoolAssistantProposal(
    id: id,
    actionId: actionId,
    binding: binding ?? context.value.binding,
    requestRevision: requestRevision ?? controller.requestRevision,
    entitlementRevision:
        entitlementRevision ?? controller.entitlementRevision ?? 'unavailable',
    sourceRevision: sourceRevision,
    entityId: entityId,
    validUntil: validUntil ?? now.add(const Duration(minutes: 5)),
    title: title,
    summary: summary,
    fields: fields,
  );

  void dispose() {
    controller
        .dispose(); // Cancels entitlement expiry timers in every unit case.
    source.dispose();
    context.dispose();
  }
}

void _registerHandoffRegressionTests() {
  group('FE-HANDOFF01 isolated host contract', () {
    test('requires a request and a registered receiver', () async {
      for (final registered in [true, false]) {
        final f = _HandoffFixture(registered: registered);
        try {
          await f.ready(withRequest: !registered);
          expect(f.controller.receiveProposal(f.proposal()), isFalse);
          expect(f.controller.proposal, isNull);
          expect(f.adapter.snapshotCalls, 0);
          expect(f.adapter.reviewCalls, 0);
        } finally {
          f.dispose();
        }
      }
    });

    test('unpaid access rejects even with a registered receiver', () async {
      final f = _HandoffFixture(
        access: MoolAssistantAccess.subscriptionRequired,
      );
      try {
        await f.ready();
        expect(f.controller.receiveProposal(f.proposal()), isFalse);
        expect(f.controller.proposal, isNull);
        expect(f.adapter.snapshotCalls, 0);
        expect(f.adapter.reviewCalls, 0);
      } finally {
        f.dispose();
      }
    });

    test(
      'unknown, excluded and duplicate native registrations fail closed',
      () {
        final context = _Context();
        try {
          for (final id in ['AI-ACT-999', 'AI-ACT-036']) {
            expect(
              () => _controller(
                context,
                nativeAdapters: [
                  _HandoffAdapter(context.value.binding, actionId: id),
                ],
              ),
              throwsArgumentError,
            );
          }
          expect(
            () => _controller(
              context,
              nativeAdapters: [
                _HandoffAdapter(context.value.binding),
                _HandoffAdapter(context.value.binding),
              ],
            ),
            throwsArgumentError,
          );
        } finally {
          context.dispose();
        }
      },
    );

    test('invalid metadata and fields never call a native owner', () async {
      final f = _HandoffFixture();
      try {
        await f.ready();
        final invalid = [
          f.proposal(binding: _context('b', 2).binding),
          f.proposal(actionId: 'AI-ACT-999'),
          f.proposal(requestRevision: f.controller.requestRevision + 1),
          f.proposal(entitlementRevision: 'obsolete'),
          f.proposal(id: ' '),
          f.proposal(title: ' '),
          f.proposal(summary: ' '),
          f.proposal(sourceRevision: ' '),
          f.proposal(entityId: ' '),
          f.proposal(validUntil: f.now),
          f.proposal(fields: const {'query': 'Rice', 'postImmediately': true}),
          f.proposal(fields: const {'query': ''}),
        ];
        for (final value in invalid) {
          expect(f.controller.receiveProposal(value), isFalse);
        }
        expect(f.controller.proposal, isNull);
        expect(f.adapter.snapshotCalls, 0);
        expect(f.adapter.reviewCalls, 0);
      } finally {
        f.dispose();
      }
    });

    test(
      'receive never navigates and cancelled IDs cannot be replayed',
      () async {
        final f = _HandoffFixture();
        try {
          await f.ready();
          final value = f.proposal();
          expect(f.controller.receiveProposal(value), isTrue);
          expect(f.controller.receiveProposal(value), isFalse);
          expect(f.adapter.snapshotCalls, 0);
          expect(f.adapter.reviewCalls, 0);
          f.controller.cancelProposal();
          expect(f.controller.receiveProposal(value), isFalse);
          expect(f.controller.proposal, isNull);
        } finally {
          f.dispose();
        }
      },
    );

    test(
      'fresh snapshot checks permission binding entity and revision',
      () async {
        for (final variant in [
          'permission',
          'binding',
          'entity',
          'revision',
          'null',
        ]) {
          final f = _HandoffFixture();
          try {
            await f.ready();
            expect(f.controller.receiveProposal(f.proposal()), isTrue);
            f.adapter.currentSnapshot = variant == 'null'
                ? null
                : MoolAssistantNativeSnapshot(
                    binding: variant == 'binding'
                        ? _context('b', 2).binding
                        : f.context.value.binding,
                    sourceRevision: variant == 'revision' ? 'r2' : 'r1',
                    permitted: variant != 'permission',
                    entityId: variant == 'entity' ? 'other-entity' : null,
                  );
            expect(
              await f.controller.reviewProposal(),
              variant == 'null'
                  ? MoolAssistantReviewResult.unavailable
                  : MoolAssistantReviewResult.stale,
            );
            expect(f.adapter.snapshotCalls, 1, reason: variant);
            expect(f.adapter.reviewCalls, 0, reason: variant);
            expect(f.controller.reviewBusy, isFalse);
          } finally {
            f.dispose();
          }
        }
      },
    );

    test(
      'duplicate taps during snapshot and native review open once',
      () async {
        final f = _HandoffFixture();
        try {
          await f.ready();
          f.adapter.snapshotGate = Completer<MoolAssistantNativeSnapshot?>();
          f.adapter.reviewGate = Completer<MoolAssistantReviewResult>();
          expect(f.controller.receiveProposal(f.proposal()), isTrue);
          final pending = f.controller.reviewProposal();
          expect(
            await f.controller.reviewProposal(),
            MoolAssistantReviewResult.unavailable,
          );
          expect(f.adapter.snapshotCalls, 1);
          f.adapter.snapshotGate!.complete(f.adapter.currentSnapshot);
          await f.adapter.reviewEntered.future;
          expect(
            await f.controller.reviewProposal(),
            MoolAssistantReviewResult.unavailable,
          );
          expect(f.adapter.reviewCalls, 1);
          f.adapter.reviewGate!.complete(MoolAssistantReviewResult.opened);
          expect(await pending, MoolAssistantReviewResult.opened);
          expect(f.adapter.snapshotCalls, 1);
          expect(f.adapter.reviewCalls, 1);
          expect(f.controller.proposal, isNull);
          expect(f.controller.reviewBusy, isFalse);
        } finally {
          f.dispose();
        }
      },
    );

    test('draft language and New chat changes retire suggestions', () async {
      for (final change in ['draft', 'language', 'new-chat']) {
        final f = _HandoffFixture();
        try {
          await f.ready();
          final revision = f.controller.requestRevision;
          expect(f.controller.receiveProposal(f.proposal()), isTrue);
          if (change == 'draft') f.controller.setDraft('Find wheat');
          if (change == 'language') f.controller.chooseLanguage('Hindi');
          if (change == 'new-chat') expect(f.controller.discardDraft(), isTrue);
          expect(f.controller.requestRevision, greaterThan(revision));
          expect(f.controller.proposal, isNull);
          expect(
            await f.controller.reviewProposal(),
            MoolAssistantReviewResult.unavailable,
          );
          expect(f.adapter.reviewCalls, 0);
        } finally {
          f.dispose();
        }
      }
    });

    test(
      'edits context or entitlement changes invalidate pending snapshots',
      () async {
        for (final change in ['draft', 'context', 'entitlement']) {
          final f = _HandoffFixture();
          try {
            await f.ready();
            f.adapter.snapshotGate = Completer<MoolAssistantNativeSnapshot?>();
            expect(f.controller.receiveProposal(f.proposal()), isTrue);
            final pending = f.controller.reviewProposal();
            if (change == 'draft') f.controller.setDraft('Find wheat');
            if (change == 'context') f.context.change(_context('b', 2));
            if (change == 'entitlement') f.source.invalidate();
            f.adapter.snapshotGate!.complete(f.adapter.currentSnapshot);
            expect(await pending, MoolAssistantReviewResult.stale);
            expect(f.adapter.reviewCalls, 0, reason: change);
            expect(f.controller.proposal, isNull);
            expect(f.controller.reviewBusy, isFalse);
          } finally {
            f.dispose();
          }
        }
      },
    );

    test(
      'proposal and paid access expiry both prevent native review',
      () async {
        final expiredAccess = _HandoffFixture();
        try {
          await expiredAccess.ready();
          expect(
            expiredAccess.controller.receiveProposal(
              expiredAccess.proposal(
                validUntil: expiredAccess.now.add(const Duration(hours: 2)),
              ),
            ),
            isTrue,
          );
          expiredAccess.now = expiredAccess.now.add(
            const Duration(hours: 1, seconds: 1),
          );
          await expiredAccess.controller.reviewProposal();
          expect(expiredAccess.controller.access, MoolAssistantAccess.expired);
          expect(expiredAccess.adapter.reviewCalls, 0);
          expect(expiredAccess.controller.reviewBusy, isFalse);
        } finally {
          expiredAccess.dispose();
        }
        final f = _HandoffFixture();
        try {
          await f.ready();
          expect(
            f.controller.receiveProposal(
              f.proposal(validUntil: f.now.add(const Duration(seconds: 10))),
            ),
            isTrue,
          );
          f.now = f.now.add(const Duration(seconds: 11));
          expect(
            await f.controller.reviewProposal(),
            MoolAssistantReviewResult.stale,
          );
          expect(f.adapter.snapshotCalls, 0);
          expect(f.adapter.reviewCalls, 0);
        } finally {
          f.dispose();
        }
      },
    );

    test(
      'cancel leaves native ownership pending and prevents restoration',
      () async {
        final f = _HandoffFixture();
        try {
          await f.ready();
          f.adapter.reviewGate = Completer<MoolAssistantReviewResult>();
          expect(f.controller.receiveProposal(f.proposal()), isTrue);
          final pending = f.controller.reviewProposal();
          await f.adapter.reviewEntered.future;
          expect(f.adapter.reviewIsCurrent!(), isTrue);
          f.controller.cancelProposal();
          expect(f.controller.proposal, isNull);
          expect(f.controller.reviewBusy, isTrue);
          expect(f.adapter.reviewIsCurrent!(), isFalse);
          expect(f.adapter.reviewGate!.isCompleted, isFalse);
          expect(f.controller.draft, 'Find Rice');
          f.adapter.reviewGate!.complete(MoolAssistantReviewResult.cancelled);
          expect(await pending, MoolAssistantReviewResult.stale);
          expect(f.controller.proposal, isNull);
          expect(f.controller.reviewBusy, isFalse);
          expect(f.adapter.reviewCalls, 1);
        } finally {
          f.dispose();
        }
      },
    );

    test(
      'backgrounded snapshot stays retired after resume and preserves input',
      () async {
        final f = _HandoffFixture();
        try {
          await f.ready();
          f.adapter.snapshotGate = Completer<MoolAssistantNativeSnapshot?>();
          final value = f.proposal();
          expect(f.controller.receiveProposal(value), isTrue);
          final pending = f.controller.reviewProposal();
          f.controller.setForeground(false);
          expect(f.controller.proposal, isNull);
          expect(f.controller.draft, 'Find Rice');
          expect(
            f.controller.receiveProposal(f.proposal(id: 'paused')),
            isFalse,
          );
          f.controller.setForeground(true);
          f.adapter.snapshotGate!.complete(f.adapter.currentSnapshot);
          expect(await pending, MoolAssistantReviewResult.stale);
          expect(f.adapter.reviewCalls, 0);
          expect(f.controller.receiveProposal(value), isFalse);
          expect(f.controller.reviewBusy, isFalse);
        } finally {
          f.dispose();
        }
      },
    );

    test('disposed controller never opens a delayed native review', () async {
      final f = _HandoffFixture();
      await f.ready();
      f.adapter.snapshotGate = Completer<MoolAssistantNativeSnapshot?>();
      expect(f.controller.receiveProposal(f.proposal()), isTrue);
      final pending = f.controller.reviewProposal();
      f.dispose();
      f.adapter.snapshotGate!.complete(f.adapter.currentSnapshot);
      expect(await pending, MoolAssistantReviewResult.stale);
      expect(f.adapter.reviewCalls, 0);
    });

    test(
      'cancelled read releases UI and cannot disturb a newer read',
      () async {
        final f = _HandoffFixture();
        final oldRead = Completer<MoolAssistantNativeSnapshot?>();
        final newRead = Completer<MoolAssistantNativeSnapshot?>();
        Future<MoolAssistantReviewResult>? oldPending, newPending;
        try {
          await f.ready();
          f.adapter.snapshotGate = oldRead;
          expect(f.controller.receiveProposal(f.proposal()), isTrue);
          oldPending = f.controller.reviewProposal();
          expect(f.controller.reviewBusy, isTrue);
          f.controller.cancelProposal();
          expect(f.controller.reviewBusy, isFalse);
          expect(f.controller.canChangeConversation, isTrue);
          expect(
            await oldPending.timeout(const Duration(seconds: 1)),
            MoolAssistantReviewResult.stale,
          );
          expect(oldRead.isCompleted, isFalse);
          f.controller.setDraft('Find flour');
          f.adapter.snapshotGate = newRead;
          final next = f.proposal(id: 'next-read');
          expect(f.controller.receiveProposal(next), isTrue);
          newPending = f.controller.reviewProposal();
          oldRead.completeError(StateError('Late cancelled read error'));
          await Future<void>.delayed(Duration.zero);
          expect(f.controller.reviewBusy, isTrue);
          expect(f.controller.proposal, same(next));
          expect(f.adapter.reviewCalls, 0);
          newRead.complete(f.adapter.currentSnapshot);
          expect(await newPending, MoolAssistantReviewResult.opened);
          expect(f.adapter.reviewCalls, 1);
        } finally {
          f.controller.cancelProposal();
          if (!oldRead.isCompleted) oldRead.complete(f.adapter.currentSnapshot);
          if (!newRead.isCompleted) newRead.complete(f.adapter.currentSnapshot);
          if (oldPending != null) await oldPending;
          if (newPending != null) await newPending;
          f.dispose();
        }
      },
    );
    for (final boundary in ['context', 'foreground']) {
      test(
        '$boundary retires a read immediately without native navigation',
        () async {
          final f = _HandoffFixture();
          final read = Completer<MoolAssistantNativeSnapshot?>();
          Future<MoolAssistantReviewResult>? pending;
          try {
            await f.ready();
            f.adapter.snapshotGate = read;
            expect(f.controller.receiveProposal(f.proposal()), isTrue);
            pending = f.controller.reviewProposal();
            if (boundary == 'context') {
              f.context.change(_context('b', 2));
            } else {
              f.controller.setForeground(false);
            }
            expect(f.controller.reviewBusy, isFalse);
            expect(
              await pending.timeout(const Duration(seconds: 1)),
              MoolAssistantReviewResult.stale,
            );
            expect(read.isCompleted, isFalse);
            expect(f.adapter.reviewCalls, 0);
            if (boundary == 'foreground') f.controller.setForeground(true);
            read.complete(f.adapter.currentSnapshot);
            await Future<void>.delayed(Duration.zero);
            expect(f.adapter.reviewCalls, 0);
            expect(f.controller.proposal, isNull);
          } finally {
            f.controller.cancelProposal();
            if (!read.isCompleted) read.complete(f.adapter.currentSnapshot);
            if (pending != null) await pending;
            f.dispose();
          }
        },
      );
    }
    test(
      'unknown native review outcome cannot replay the suggestion',
      () async {
        final f = _HandoffFixture();
        try {
          await f.ready();
          f.adapter.throwOnReview = true;
          final value = f.proposal();
          expect(f.controller.receiveProposal(value), isTrue);
          expect(
            await f.controller.reviewProposal(),
            MoolAssistantReviewResult.unavailable,
          );
          expect(f.controller.proposal, isNull);
          expect(f.controller.proposalNotice, contains('status is unclear'));
          expect(f.controller.receiveProposal(value), isFalse);
          expect(f.controller.draft, 'Find Rice');
          expect(f.adapter.reviewCalls, 1);
        } finally {
          f.dispose();
        }
      },
    );

    test('proposal fields deeply copy and freeze finite JSON data', () async {
      final f = _HandoffFixture();
      try {
        await f.ready();
        final nested = <String, Object?>{'name': 'Rice'};
        final list = <Object?>[nested];
        final input = <String, Object?>{'query': list};
        final value = f.proposal(fields: input);
        nested['name'] = 'Wheat';
        list.add('later');
        input['extra'] = true;
        final frozenList = value.fields['query']! as List<Object?>;
        final frozenMap = frozenList.single! as Map<String, Object?>;
        expect(frozenMap['name'], 'Rice');
        expect(value.fields.containsKey('extra'), isFalse);
        expect(() => value.fields['extra'] = true, throwsUnsupportedError);
        expect(() => frozenList.add('later'), throwsUnsupportedError);
        expect(() => frozenMap['name'] = 'Wheat', throwsUnsupportedError);
        final cycle = <String, Object?>{};
        cycle['self'] = cycle;
        for (final invalid in <Map<String, Object?>>[
          cycle,
          {'query': Object()},
          {'query': double.nan},
          {'query': double.infinity},
          {
            'query': <Object, Object?>{1: 'bad-key'},
          },
        ]) {
          expect(() => f.proposal(fields: invalid), throwsArgumentError);
        }
      } finally {
        f.dispose();
      }
    });
  });
}

class _SelectedDocumentAdapterFixture
    implements MoolAssistantSelectedDocumentAdapter {
  _SelectedDocumentAdapterFixture(this.binding);
  final Object binding;
  int ordinaryReviews = 0, selectedReviews = 0;
  MoolAssistantSelectedDocument? Function(String)? resolver;
  void Function(
    MoolAssistantProposal,
    MoolAssistantSelectedDocument? Function(String),
  )?
  duringReview;
  @override
  String get actionId => 'AI-ACT-241';
  @override
  Set<String> get allowedFields => const {'attachmentRef'};
  @override
  String? validateFields(Map<String, Object?> fields) =>
      fields.length == 1 && fields['attachmentRef'] is String
      ? null
      : 'Choose a file';
  @override
  Future<MoolAssistantNativeSnapshot?> snapshot(
    MoolAssistantContext context,
    String? entityId,
  ) async => MoolAssistantNativeSnapshot(
    binding: binding,
    sourceRevision: 'host-form-r1',
    permitted: true,
  );
  @override
  Future<MoolAssistantReviewResult> openReview(
    MoolAssistantProposal proposal,
    bool Function() isCurrent,
  ) async {
    ordinaryReviews++;
    return MoolAssistantReviewResult.unavailable;
  }

  @override
  Future<MoolAssistantReviewResult> openSelectedDocumentReview(
    MoolAssistantProposal proposal,
    bool Function() isCurrent,
    MoolAssistantSelectedDocument? Function(String) resolve,
  ) async {
    selectedReviews++;
    resolver = resolve;
    duringReview?.call(proposal, resolve);
    return isCurrent()
        ? MoolAssistantReviewResult.opened
        : MoolAssistantReviewResult.stale;
  }
}

class _SelectedDocumentControllerFixture {
  _SelectedDocumentControllerFixture() {
    context.change(_context('a', 1, store: 'host-store'));
    adapter = _SelectedDocumentAdapterFixture(context.value.binding);
    source = _Entitlements(
      (account) async => _entitlement(
        account,
        MoolAssistantAccess.active,
        until: now.add(const Duration(hours: 1)),
      ),
    );
    controller = _controller(
      context,
      source: source,
      picker: picker,
      clock: () => now,
      nativeAdapters: [adapter],
    );
  }
  final context = _Context(), picker = _Picker();
  var now = DateTime.now();
  // Resolver-only memory fixture, not a decodable/native OCR or runtime document.
  final bytes = Uint8List.fromList([1, 2, 3, 4]);
  late final _SelectedDocumentAdapterFixture adapter;
  late final _Entitlements source;
  late final MoolAssistantController controller;
  bool disposed = false;
  Future<void> ready(WorkProofSource origin, {WorkPickedProof? input}) async {
    await controller.refreshAccess();
    controller.setDraft('Review the selected supplier document');
    picker.pending.complete(
      input ?? WorkPickedProof(
        fileName: 'HOST-selected.png',
        contentType: 'image/png',
        bytes: bytes,
        recoveryPath: 'HOST-private-path',
      ),
    );
    await controller.pickAttachment(origin);
  }

  MoolAssistantProposal proposal(String reference) => MoolAssistantProposal(
    id: 'host-selected-review',
    actionId: adapter.actionId,
    binding: context.value.binding,
    requestRevision: controller.requestRevision,
    entitlementRevision: controller.entitlementRevision!,
    sourceRevision: 'host-form-r1',
    validUntil: now.add(const Duration(minutes: 5)),
    title: 'Review selected document',
    summary: 'Use HOST-selected.png in the existing native review.',
    fields: {'attachmentRef': reference},
  );
  void disposeController() {
    if (!disposed) {
      disposed = true;
      controller.dispose();
    }
  }

  void dispose() {
    disposeController();
    source.dispose();
    context.dispose();
  }
}

void registerOcrOpaqueReferenceTests() {
  for (final origin in WorkProofSource.values) {
    test(
      'FE-OCR-01 opaque reference preserves actual $origin and immutable copied bytes',
      () async {
        final f = _SelectedDocumentControllerFixture();
        try {
          await f.ready(origin);
          final reference = f.controller.selectedDocumentReferences.single;
          expect(reference.id, matches(RegExp(r'^att-[a-f0-9]{32}$')));
          expect(reference.source, origin);
          expect(reference.fileName, 'HOST-selected.png');
          expect(
            reference.toJson().keys,
            unorderedEquals([
              'attachmentRef',
              'fileName',
              'contentType',
              'byteLength',
              'source',
            ]),
          );
          f.bytes[0] = 99; // Picker memory can no longer change selected bytes.
          f.adapter.duringReview = (proposal, resolve) {
            final selected = resolve(reference.id)!;
            expect(selected.proof.bytes, orderedEquals([1, 2, 3, 4]));
            expect(selected.proof.recoveryPath, isNull);
            expect(
              selected.sourceDigest,
              selected_document_hash.sha256.convert([1, 2, 3, 4]).toString(),
            );
            expect(() => selected.proof.bytes[0] = 7, throwsUnsupportedError);
            expect(resolve('att-${List.filled(32, '0').join()}'), isNull);
          };
          expect(
            f.controller.receiveProposal(f.proposal(reference.id)),
            isTrue,
          );
          expect(
            await f.controller.reviewProposal(),
            MoolAssistantReviewResult.opened,
          );
          expect(f.adapter.ordinaryReviews, 0);
          expect(f.adapter.selectedReviews, 1);
          // A retained callback cannot resolve after this explicit Review ends.
          expect(f.adapter.resolver!(reference.id), isNull);
          expect(f.picker.calls, 1);
        } finally {
          f.dispose();
        }
      },
    );
  }

  final invalidations =
      <String, void Function(_SelectedDocumentControllerFixture)>{
        'request edit': (f) => f.controller.setDraft('A newer request'),
        'remove selected file': (f) => f.controller.removeSelectedAttachment(0),
        'clear selected files': (f) => f.controller.removeAttachment(),
        'account change': (f) =>
            f.context.change(_context('b', 2, store: 'host-store')),
        'account A-B-A': (f) {
          f.context.change(_context('b', 2, store: 'other-store'));
          f.context.change(_context('a', 1, store: 'host-store'));
        },
        'foreground retirement': (f) => f.controller.setForeground(false),
        'disposal': (f) => f.disposeController(),
      };
  for (final entry in invalidations.entries) {
    test(
      'FE-OCR-01 selected resolver rejects ${entry.key} during Review',
      () async {
        final f = _SelectedDocumentControllerFixture();
        try {
          await f.ready(WorkProofSource.upload);
          final reference = f.controller.selectedDocumentReferences.single;
          f.adapter.duringReview = (proposal, resolve) {
            expect(resolve(reference.id), isNotNull);
            entry.value(f);
            expect(resolve(reference.id), isNull);
          };
          expect(
            f.controller.receiveProposal(f.proposal(reference.id)),
            isTrue,
          );
          expect(
            await f.controller.reviewProposal(),
            MoolAssistantReviewResult.stale,
          );
          expect(f.adapter.ordinaryReviews, 0);
        } finally {
          f.dispose();
        }
      },
    );
  }

  test(
    'FE-OCR-01 selected references cannot replay into another controller',
    () async {
      final first = _SelectedDocumentControllerFixture();
      final second = _SelectedDocumentControllerFixture();
      try {
        await first.ready(WorkProofSource.camera);
        await second.ready(WorkProofSource.camera);
        final oldReference =
            first.controller.selectedDocumentReferences.single.id;
        final newReference =
            second.controller.selectedDocumentReferences.single.id;
        expect(newReference, isNot(oldReference));
        second.adapter.duringReview = (proposal, resolve) {
          expect(resolve(oldReference), isNull);
          expect(resolve(newReference), isNotNull);
        };
        expect(
          second.controller.receiveProposal(second.proposal(newReference)),
          isTrue,
        );
        expect(
          await second.controller.reviewProposal(),
          MoolAssistantReviewResult.opened,
        );
      } finally {
        first.dispose();
        second.dispose();
      }
    },
  );
}

void registerAct228SharedDocumentTests() {
  for (final format in [('csv', 'text/csv'), ('json', 'application/json')]) {
    test('ACT228 native Files accepts original ${format.$1} and delegates video', () async {
      final fallback = _Media(); var documents = 0;
      final bytes = Uint8List.fromList([65, 66, 67]);
      final picker = MoolAssistantNativeMediaPicker(fallback: fallback, documents: () async {
        documents++;
        return WorkPickedProof(fileName: 'HOST-original.${format.$1}', contentType: format.$2, bytes: bytes);
      });
      final document = (await picker.pick(ChatAttachmentKind.document))!;
      expect(document.name, 'HOST-original.${format.$1}'); expect(document.contentType, format.$2);
      expect(document.bytes, orderedEquals(bytes)); expect(fallback.calls, 0); expect(documents, 1);
      await picker.pick(ChatAttachmentKind.video);
      expect(fallback.calls, 1); expect(documents, 1);
    });
    for (final invalidation in ['request', 'remove', 'account', 'expiry']) {
      test('ACT228 opaque ${format.$1} bytes and $invalidation invalidation use real controller resolver', () async {
        final f = _SelectedDocumentControllerFixture();
        final bytes = Uint8List.fromList([65, 66, 67]);
        try {
          await f.ready(WorkProofSource.upload, input: WorkPickedProof(fileName: 'HOST-original.${format.$1}',
            contentType: format.$2, bytes: bytes, recoveryPath: '/HOST-private-input'));
          final ref = f.controller.selectedDocumentReferences.single;
          expect(ref.contentType, format.$2); expect(ref.source, WorkProofSource.upload);
          final json = ref.toJson();
          expect(json.keys, unorderedEquals(['attachmentRef','fileName','contentType','byteLength','source']));
          bytes[0] = 90;
          f.adapter.duringReview = (proposal, resolve) {
            final selected = resolve(ref.id)!;
            expect(selected.proof.bytes, orderedEquals([65, 66, 67]));
            expect(selected.proof.recoveryPath, isNull);
            expect(selected.sourceDigest, selected_document_hash.sha256.convert([65, 66, 67]).toString());
            expect(() => selected.proof.bytes[0] = 91, throwsUnsupportedError);
            if (invalidation == 'request') f.controller.setDraft('A new request');
            if (invalidation == 'remove') f.controller.removeSelectedAttachment(0);
            if (invalidation == 'account') f.context.change(_context('b', 2, store: 'host-store'));
            if (invalidation == 'expiry') f.now = f.now.add(const Duration(hours: 2));
            expect(resolve(ref.id), isNull);
          };
          expect(f.controller.receiveProposal(f.proposal(ref.id)), isTrue);
          expect(await f.controller.reviewProposal(), MoolAssistantReviewResult.stale);
          expect(f.adapter.ordinaryReviews, 0); expect(f.picker.calls, 1);
          expect(f.adapter.resolver!(ref.id), isNull);
        } finally { f.dispose(); }
      });
    }
  }
  for (final problem in ['unsupported', 'empty', 'oversize']) {
    test('ACT228 native Files rejects $problem before handing bytes to controller', () async {
      final picker = MoolAssistantNativeMediaPicker(documents: () async => WorkPickedProof(
        fileName: 'HOST-file.csv', contentType: problem == 'unsupported' ? 'application/zip' : 'text/csv',
        bytes: Uint8List(problem == 'empty' ? 0 : problem == 'oversize' ? 15 * 1024 * 1024 + 1 : 1)));
      await expectLater(picker.pick(ChatAttachmentKind.document), throwsA(isA<MoolAssistantDocumentException>()));
    });
  }
  test('ACT228 native Files cancellation returns no selected file', () async {
    final picker = MoolAssistantNativeMediaPicker(documents: () async => null);
    expect(await picker.pick(ChatAttachmentKind.document), isNull);
  });
  test('ACT228 selected owner signal publishes authoritative disposal before listeners are removed', () async {
    final f = _SelectedDocumentControllerFixture();
    try {
      await f.ready(WorkProofSource.upload, input: WorkPickedProof(fileName: 'HOST-selected.csv',
        contentType: 'text/csv', bytes: Uint8List.fromList([65, 66, 67])));
      final ref = f.controller.selectedDocumentReferences.single;
      var notified = false;
      f.adapter.duringReview = (_, resolve) {
        final selected = resolve(ref.id)!;
        selected.ownerChanges.addListener(() {
          notified = true;
          expect(resolve(ref.id), isNull, reason: 'Notification alone grants no authority; disposed resolver is already false.');
        });
        f.disposeController();
        expect(notified, isTrue);
      };
      expect(f.controller.receiveProposal(f.proposal(ref.id)), isTrue);
      expect(await f.controller.reviewProposal(), MoolAssistantReviewResult.stale);
    } finally { f.dispose(); }
  });
}


class _OwnedHandoffAdapter extends _HandoffAdapter implements MoolAssistantOwnerAwareNativeAdapter {
  _OwnedHandoffAdapter(super.binding);
  Listenable? ownerChanges;
  int ownedCalls = 0;
  @override Future<MoolAssistantReviewResult> openOwnedReview(MoolAssistantProposal proposal,
    {required bool Function() isCurrent, required Listenable ownerChanges}) async {
    ownedCalls++; this.ownerChanges = ownerChanges; reviewIsCurrent = isCurrent;
    if (!reviewEntered.isCompleted) reviewEntered.complete();
    final result = reviewGate == null ? MoolAssistantReviewResult.opened : await reviewGate!.future;
    return isCurrent() ? result : MoolAssistantReviewResult.stale;
  }
}
class _SelectedOwnedHandoffAdapter extends _OwnedHandoffAdapter implements MoolAssistantSelectedDocumentAdapter {
  _SelectedOwnedHandoffAdapter(super.binding);
  int selectedCalls = 0;
  @override Future<MoolAssistantReviewResult> openSelectedDocumentReview(MoolAssistantProposal proposal,
    bool Function() isCurrent, MoolAssistantSelectedDocument? Function(String) resolve) async {
    selectedCalls++; return isCurrent() ? MoolAssistantReviewResult.opened : MoolAssistantReviewResult.stale;
  }
}
void registerOwnerAwareHandoffTests() {
  for (final retirement in ['cancel', 'request', 'dispose']) {
    test('FE-HANDOFF01 actual $retirement signal retires owner-aware review but awaits original native future', () async {
      final context = _Context(), now = DateTime.now();
      final adapter = _OwnedHandoffAdapter(context.value.binding)..reviewGate = Completer<MoolAssistantReviewResult>();
      final access = _Entitlements((account) async => _entitlement(account, MoolAssistantAccess.active, until: now.add(const Duration(hours: 1))));
      final controller = _controller(context, source: access, clock: () => now, nativeAdapters: [adapter]);
      var disposed = false;
      try {
        await controller.refreshAccess(); controller.setDraft('Original query');
        expect(controller.receiveProposal(MoolAssistantProposal(id: 'HOST-owned', actionId: adapter.actionId,
          binding: context.value.binding, requestRevision: controller.requestRevision,
          entitlementRevision: controller.entitlementRevision!, sourceRevision: 'r1',
          validUntil: now.add(const Duration(minutes: 5)), title: 'Review original search', summary: 'HOST contract', fields: const {'query': 'Rice'})), isTrue);
        var completed = false, notifications = 0;
        final result = controller.reviewProposal().then((value) { completed = true; return value; });
        await adapter.reviewEntered.future;
        expect(adapter.ownerChanges, same(controller));
        adapter.ownerChanges!.addListener(() { notifications++; expect(adapter.reviewIsCurrent!(), isFalse); });
        if (retirement == 'cancel') controller.cancelProposal();
        if (retirement == 'request') controller.setDraft('A replacement query');
        if (retirement == 'dispose') { controller.dispose(); disposed = true; }
        await Future<void>.value();
        expect(notifications, greaterThan(0)); expect(completed, isFalse);
        expect(adapter.reviewCalls, 0); expect(adapter.ownedCalls, 1);
        adapter.reviewGate!.complete(MoolAssistantReviewResult.opened);
        expect(await result, MoolAssistantReviewResult.stale);
      } finally {
        if (!adapter.reviewGate!.isCompleted) adapter.reviewGate!.complete(MoolAssistantReviewResult.cancelled);
        if (!disposed) controller.dispose(); access.dispose(); context.dispose();
      }
    });
  }
  test('FE-HANDOFF01 ordinary adapter fallback is unchanged', () async {
    final f = _HandoffFixture();
    try {
      await f.ready(); expect(f.controller.receiveProposal(f.proposal()), isTrue);
      expect(await f.controller.reviewProposal(), MoolAssistantReviewResult.opened); expect(f.adapter.reviewCalls, 1);
    } finally { f.dispose(); }
  });
  test('FE-HANDOFF01 selected-document dispatch retains precedence over optional owner-aware interface', () async {
    final context = _Context(), now = DateTime.now();
    final adapter = _SelectedOwnedHandoffAdapter(context.value.binding);
    // Use the exact current fixture binding, not another identity or selected value.
    final access = _Entitlements((account) async => _entitlement(account, MoolAssistantAccess.active, until: now.add(const Duration(hours: 1))));
    adapter.currentSnapshot = MoolAssistantNativeSnapshot(binding: context.value.binding, sourceRevision: 'r1', permitted: true);
    final controller = _controller(context, source: access, clock: () => now, nativeAdapters: [adapter]);
    try {
      await controller.refreshAccess(); controller.setDraft('Original query');
      expect(controller.receiveProposal(MoolAssistantProposal(id: 'HOST-dual', actionId: adapter.actionId,
        binding: context.value.binding, requestRevision: controller.requestRevision, entitlementRevision: controller.entitlementRevision!,
        sourceRevision: 'r1', validUntil: now.add(const Duration(minutes: 5)), title: 'Review search', summary: 'HOST dispatch only', fields: const {'query':'Rice'})), isTrue);
      expect(await controller.reviewProposal(), MoolAssistantReviewResult.opened);
      expect(adapter.selectedCalls, 1); expect(adapter.ownedCalls, 0); expect(adapter.reviewCalls, 0);
    } finally { controller.dispose(); access.dispose(); context.dispose(); }
  });
}


void main() {
  testWidgets('POLISH05-V2 compact default composer leaves more content space', (tester) async {
    tester.view.physicalSize = const Size(360,806); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final c = _controller(_Context()); addTearDown(c.dispose); await _mount(tester,c);
    expect(tester.getSize(find.byKey(const Key('mool-assistant-composer'))).height, lessThanOrEqualTo(110));
    expect(find.text('Mool AI'),findsOneWidget);
    expect(c.draft,isEmpty); expect(c.proposal,isNull);
    expect(tester.takeException(),isNull);
  });
  testWidgets('POLISH05-V2 contextual moving examples never become draft content', (tester) async {
    final c=_controller(_Context());addTearDown(c.dispose);await _mount(tester,c,reduceMotion:false,accessibleNavigation:false);
    final input=tester.widget<TextField>(find.byKey(const Key('mool-assistant-input')));
    input.focusNode!.requestFocus();await tester.pumpAndSettle();
    input.focusNode!.unfocus();await tester.pump();await tester.pump();
    expect(find.text('Try “Find rice under ₹500”'),findsOneWidget);
    await tester.pump(const Duration(milliseconds:3200));
    expect(find.text('Try “Track my order”'),findsOneWidget);
    expect(c.draft,isEmpty);expect(input.controller!.text,isEmpty);
    await tester.pumpAndSettle();
    expect(find.text('Type or speak in your language'),findsOneWidget);
    expect(tester.binding.hasScheduledFrame,isFalse);
    expect(tester.takeException(),isNull);
  });
  testWidgets('POLISH05-V2 native click occurs only for accepted task choice', (tester) async {
    final sounds=<Object?>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform,(call)async{
      if(call.method=='SystemSound.play')sounds.add(call.arguments);return null;
    });
    addTearDown(()=>TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform,null));
    final c=_controller(_Context());addTearDown(c.dispose);await _mount(tester,c);
    await _tapToolbar(tester,'mool-assistant-actions');final toolbarSounds=sounds.length;
    final row=find.descendant(of:find.byKey(const Key('mool-assistant-action-list')),matching:find.byType(ListTile)).first;
    await tester.tap(row);await tester.pumpAndSettle();
    expect(sounds.length,toolbarSounds+1);expect(sounds.last,'SystemSoundType.click');expect(c.draft,isNotEmpty);expect(c.proposal,isNull);
    await tester.enterText(find.byKey(const Key('mool-assistant-input')),'My request');await tester.pumpAndSettle();
    expect(sounds,hasLength(toolbarSounds+1));expect(tester.takeException(),isNull);
  });
  testWidgets('POLISH05-V2 host-only visual states and proposed results', (tester) async {
    if(Platform.environment['MOOL_ASSISTANT_CAPTURE_DIR']!=null){
      await tester.runAsync(() async {
        final fonts=FontLoader('Inter')..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'));
        await fonts.load();
      });
    }
    await _visualMatrix(tester);
    expect(tester.takeException(),isNull);
  });

  testWidgets('POLISH05 toolbar uses consistent readable labels and utility icons with Tasks icon',(tester)async{
    final c=_controller(_Context());addTearDown(c.dispose);await _mount(tester,c);
    for(final key in ['mool-assistant-actions','mool-assistant-voice']){
      final owner=find.byKey(Key(key));final label=tester.widget<Text>(find.descendant(of:owner,matching:find.byType(Text)).first);
      expect(label.style!.fontSize,14);expect(label.style!.fontWeight,FontWeight.w500);expect(label.style!.color,isNull,reason:'Preserve native disabled-state colour');
      final textOwner=find.descendant(of:owner,matching:find.byType(Text)).first;
      expect(DefaultTextStyle.of(tester.element(textOwner)).style.merge(label.style).color,const Color(0xFF23252B));
      final icon=tester.widget<Icon>(find.descendant(of:owner,matching:find.byType(Icon)).first);
      expect(icon.size,20);expect(icon.color,const Color(0xFF666A73));expect(tester.getSize(owner).height,greaterThanOrEqualTo(48));
    }
    expect(find.descendant(of:find.byKey(const Key('mool-assistant-actions')),matching:find.byIcon(Icons.checklist_rounded)),findsOneWidget);
    expect(find.descendant(of:find.byKey(const Key('mool-assistant-voice')),matching:find.byIcon(Icons.mic_none_outlined)),findsOneWidget);
    expect(tester.takeException(),isNull);
  });

  for (final reduced in ['animations', 'accessible navigation']) {
    testWidgets('POLISH05 $reduced suppresses page lane composer and History motion', (tester) async {
      final c=_controller(_Context(),history:_History());addTearDown(c.dispose);
      await _mount(tester,c,reduceMotion:reduced=='animations',accessibleNavigation:reduced=='accessible navigation');
      expect(tester.widget<AnimatedContainer>(find.byKey(const Key('mool-assistant-composer'))).duration,Duration.zero);
      await _tapToolbar(tester,'mool-assistant-actions');await tester.pumpAndSettle();
      final reveals=tester.widgetList<TweenAnimationBuilder<double>>(find.byWidgetPredicate((w)=>w is TweenAnimationBuilder<double>));
      expect(reveals,isNotEmpty);expect(reveals.every((w)=>w.duration==Duration.zero),isTrue);
      await tester.tap(find.byTooltip('History'));await tester.pumpAndSettle();
      final panel=find.byKey(const Key('mool-assistant-history-panel'));
      expect(ModalRoute.of(tester.element(panel))!.transitionDuration,Duration.zero);
      await tester.tap(find.byTooltip('Close history'));await tester.pumpAndSettle();
      expect(tester.takeException(),isNull);
    });
  }
  testWidgets('POLISH05 finite transition keeps only latest interactive subtree and settles idle',(tester)async{
    final c=_controller(_Context());addTearDown(c.dispose);await _mount(tester,c);
    await _tapToolbar(tester,'mool-assistant-actions');await tester.pump(const Duration(milliseconds:20));
    final row=find.descendant(of:find.byKey(const Key('mool-assistant-action-list')),matching:find.byType(ListTile)).first;
    final oldKey=tester.widget<ListTile>(row).key!;
    await tester.tap(row);await tester.pump();
    expect(find.byKey(oldKey),findsNothing);expect(find.byKey(const Key('mool-assistant-action-list')),findsNothing);
    expect(c.draft,isNotEmpty);expect(c.proposal,isNull);
    tester.widget<TextField>(find.byKey(const Key('mool-assistant-input'))).focusNode!.unfocus();
    await tester.pumpAndSettle();expect(tester.binding.transientCallbackCount,0);
    expect(tester.binding.hasScheduledFrame,isFalse);expect(tester.takeException(),isNull);
  });
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('POLISH05 selection uses native primitive on $platform', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final events = <Object?>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'HapticFeedback.vibrate') events.add(call.arguments);
        return null;
      });
      addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
      final c = _controller(_Context()); addTearDown(c.dispose);
      await _mount(tester, c);
      await tester.tap(find.byKey(const Key('mool-assistant-actions')));
      await tester.pumpAndSettle();
      expect(events, [platform == TargetPlatform.android ? 'HapticFeedbackType.lightImpact' : 'HapticFeedbackType.selectionClick']);
      debugDefaultTargetPlatformOverride = null;
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('POLISH05 haptics are accepted single selections, throttled and absent for typing/background',(tester)async{
    final events=<Object?>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform,(call)async{
      if(call.method=='HapticFeedback.vibrate')events.add(call.arguments);return null;
    });
    addTearDown(()=>TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform,null));
    addTearDown(()=>tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed));
    final c=_controller(_Context());addTearDown(c.dispose);await _mount(tester,c);
    final tasks=tester.widget<TextButton>(find.byKey(const Key('mool-assistant-actions'))).onPressed!;
    tasks();await tester.pump();expect(events,['HapticFeedbackType.lightImpact']);
    tasks();tasks();await tester.pump();expect(events,hasLength(1));
    await tester.enterText(find.byKey(const Key('mool-assistant-action-search')),'cart');await tester.pumpAndSettle();expect(events,hasLength(1));
    expect(tester.widget<IconButton>(find.byKey(const Key('mool-assistant-send'))).onPressed,isNull);
    await tester.pump(const Duration(milliseconds:200));tasks();tasks();await tester.pump();expect(events,hasLength(2));
    await tester.pump(const Duration(milliseconds:200));
    final language=tester.widget<IconButton>(find.byKey(const Key('mool-assistant-language'))).onPressed!;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);language();await tester.pump();
    expect(events,hasLength(2));expect(find.byKey(const Key('mool-assistant-language-choices')),findsNothing);
    expect(c.language,'Auto');expect(tester.takeException(),isNull);
  });
  testWidgets('POLISH05 unavailable native feedback never blocks selected UI',(tester)async{
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform,(call)async{
      if(call.method=='HapticFeedback.vibrate')throw PlatformException(code:'unavailable');return null;
    });
    addTearDown(()=>TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform,null));
    final c=_controller(_Context());addTearDown(c.dispose);await _mount(tester,c);
    await _tapToolbar(tester,'mool-assistant-actions');await tester.pumpAndSettle();
    expect(find.byKey(const Key('mool-assistant-action-list')),findsOneWidget);expect(c.proposal,isNull);expect(tester.takeException(),isNull);
  });
  testWidgets('POLISH05 composer brand surface and focus preserve geometry and text contrast',(tester)async{
    final c=_controller(_Context());addTearDown(c.dispose);await _mount(tester,c);
    final owner=find.byKey(const Key('mool-assistant-composer')),before=tester.getRect(find.byKey(const Key('mool-assistant-composer')));
    BoxDecoration decoration()=>tester.widget<AnimatedContainer>(owner).decoration! as BoxDecoration;
    expect(decoration().gradient,isNull);
    expect(decoration().color,Colors.white);
    double contrast(Color a,Color b){final x=a.computeLuminance(),y=b.computeLuminance();return x>y?(x+.05)/(y+.05):(y+.05)/(x+.05);}
    expect(contrast(Colors.white,const Color(0xFF666A73)),greaterThanOrEqualTo(4.5));
    expect(contrast(Colors.white,const Color(0xFF23252B)),greaterThanOrEqualTo(4.5));
    expect(decoration().boxShadow,isNotEmpty);
    await tester.tap(find.byKey(const Key('mool-assistant-input')));await tester.pumpAndSettle();
    expect(tester.getRect(owner),before);
    final border=decoration().border! as Border;
    final actual=Color.alphaBlend(border.top.color,Colors.white);expect(contrast(actual,Colors.white),greaterThanOrEqualTo(3));
    expect(tester.takeException(),isNull);
  });

  for(final profile in [
    (name:'Android OPPO', platform:TargetPlatform.android,size:Size(360,806),top:41.0,bottom:44.0,side:0.0),
    (name:'Android small', platform:TargetPlatform.android,size:Size(320,568),top:24.0,bottom:48.0,side:0.0),
    (name:'Android gesture', platform:TargetPlatform.android,size:Size(412,915),top:28.0,bottom:24.0,side:0.0),
    (name:'Android landscape', platform:TargetPlatform.android,size:Size(806,360),top:0.0,bottom:24.0,side:24.0),
    (name:'iOS notch', platform:TargetPlatform.iOS,size:Size(393,852),top:59.0,bottom:34.0,side:0.0),
    (name:'iOS compact', platform:TargetPlatform.iOS,size:Size(320,568),top:20.0,bottom:0.0,side:0.0),
    (name:'iOS landscape', platform:TargetPlatform.iOS,size:Size(852,393),top:0.0,bottom:21.0,side:59.0),
    (name:'tablet', platform:TargetPlatform.iOS,size:Size(834,1194),top:24.0,bottom:20.0,side:0.0),
  ]) {
    for(final scale in [1.0,2.0]) {
      for(final keyboard in [0.0,180.0]) {
        testWidgets('PHYSICAL-SAFE ${profile.name} scale$scale keyboard$keyboard keeps compact full targets',(tester) async {
          tester.view.devicePixelRatio=1;tester.view.physicalSize=profile.size;
          tester.view.viewPadding=FakeViewPadding(top:profile.top,bottom:profile.bottom,left:profile.side,right:profile.side);
          tester.view.padding=FakeViewPadding(top:profile.top,bottom:keyboard>0?0:profile.bottom,left:profile.side,right:profile.side);
          tester.view.viewInsets=FakeViewPadding(bottom:keyboard);addTearDown(tester.view.reset);
          final c=_controller(_Context());addTearDown(c.dispose);await _mount(tester,c,scale:scale);
          final control=find.byKey(const Key('mool-assistant-language'));
          await Scrollable.ensureVisible(tester.element(control),alignment:1);await tester.pumpAndSettle();
          final rect=tester.getRect(control),safeBottom=profile.size.height-(keyboard>0?keyboard:profile.bottom);
          expect(rect.height,greaterThanOrEqualTo(48));expect(rect.width,greaterThanOrEqualTo(48));
          expect(rect.bottom,lessThanOrEqualTo(safeBottom+.1));
          expect(rect.bottom,greaterThanOrEqualTo(safeBottom-12),reason:'No status-bar-sized blank band');
          expect(rect.left,greaterThanOrEqualTo(profile.side-.1));expect(rect.right,lessThanOrEqualTo(profile.size.width-profile.side+.1));
          expect(tester.takeException(),isNull);
        },variant:TargetPlatformVariant.only(profile.platform));
      }
    }
  }

  testWidgets('HEADER-HISTORY task search icon belongs to field and tapping opens keyboard/tasks', (tester) async {
    final c=_controller(_Context());addTearDown(c.dispose);
    await _mount(tester,c);
    final field=find.byKey(const Key('mool-assistant-action-search'));
    final icon=find.byKey(const Key('mool-assistant-search-icon'));
    expect(tester.getRect(field).contains(tester.getCenter(icon)),isTrue);
    await tester.tap(icon);await tester.pumpAndSettle();
    expect(find.byKey(const Key('mool-assistant-action-list')),findsOneWidget);
    expect(tester.widget<TextField>(field).focusNode!.hasFocus,isTrue);
    expect(tester.takeException(),isNull);
  });
  for(final scale in [1.0,2.0]) {
    testWidgets('HEADER-HISTORY full screen search icon and clear preserve request scale$scale',(tester) async {
      tester.view.devicePixelRatio=1;tester.view.physicalSize=const Size(320,568);
      addTearDown(tester.view.reset);
      final c=_controller(_Context(),history:_History());addTearDown(c.dispose);
      c.setDraft('Keep this unsent request');
      await _mount(tester,c,scale:scale);
      await tester.tap(find.byTooltip('History'));await tester.pumpAndSettle();
      final panel=find.byKey(const Key('mool-assistant-history-panel'));
      expect(tester.getSize(panel),const Size(320,568));
      final search=find.byKey(const Key('mool-assistant-history-search'));
      final icon=find.byKey(const Key('mool-assistant-history-search-icon'));
      expect(tester.getRect(search).contains(tester.getCenter(icon)),isTrue);
      expect(tester.widget<TextField>(search).decoration!.filled,isFalse);
      await tester.tap(icon);await tester.pumpAndSettle();
      final editable=find.descendant(of:search,matching:find.byType(EditableText));
      expect(tester.widget<EditableText>(editable).focusNode.hasFocus,isTrue);
      await tester.enterText(search,'not-a-saved-title');await tester.pumpAndSettle();
      expect(find.text('No matching chats'),findsOneWidget);
      await tester.tap(find.byTooltip('Clear chat search'));await tester.pumpAndSettle();
      expect(tester.widget<TextField>(search).controller!.text,isEmpty);
      expect(find.byKey(const ValueKey('assistant-history-one')),findsOneWidget);
      tester.view.viewInsets=const FakeViewPadding(bottom:220);await tester.pumpAndSettle();
      expect(tester.getRect(search).bottom,lessThanOrEqualTo(348));
      expect(find.byTooltip('Close history').hitTestable(),findsOneWidget);
      await tester.tap(find.byTooltip('Close history'));await tester.pumpAndSettle();
      expect(c.draft,'Keep this unsent request');expect(tester.takeException(),isNull);
    });
  }
  testWidgets('HEADER-HISTORY no-inset Android removes optional bottom gap while retaining targets',(tester) async {
    tester.view.devicePixelRatio=1;tester.view.physicalSize=const Size(360,806);
    tester.view.padding=const FakeViewPadding();tester.view.viewPadding=const FakeViewPadding();
    addTearDown(tester.view.reset);
    final c=_controller(_Context());addTearDown(c.dispose);await _mount(tester,c);
    final rect=tester.getRect(find.byKey(const Key('mool-assistant-language')));
    expect(rect.height,greaterThanOrEqualTo(48));expect(rect.bottom,greaterThanOrEqualTo(798));
    expect(rect.bottom,lessThanOrEqualTo(806));expect(tester.takeException(),isNull);
  },variant:TargetPlatformVariant.only(TargetPlatform.android));

  for (final mode in ['Buy', 'Store', 'enlarged']) {
    testWidgets('NUMBERED-TASKS $mode keeps stable numbers, alphabetical rows and exact scoped search', (tester) async {
      tester.view.devicePixelRatio=1;tester.view.physicalSize=const Size(320,568);
      addTearDown(tester.view.reset);
      final source=_Context();
      if(mode=='Store')source.change(_context('a',1,store:'s'));
      final c=_controller(source);addTearDown(c.dispose);
      await _mount(tester,c,scale:mode=='enlarged'?2:1);
      await _tapToolbar(tester,'mool-assistant-actions');await tester.pumpAndSettle();
      final list=find.byKey(const Key('mool-assistant-action-list'));
      final rows=tester.widgetList<ListTile>(find.descendant(of:list,matching:find.byType(ListTile))).toList();
      final titles=rows.map((r)=>(r.title! as Text).data!.toLowerCase()).toList();
      expect(titles,orderedEquals([...titles]..sort()));
      expect(rows.map((r)=>int.parse((r.leading! as Text).data!)),orderedEquals(List.generate(rows.length,(i)=>i+1)));
      expect(find.text('Tap a task, or type "Do task 1" in the chat.'),findsOneWidget);
      expect(find.byKey(const Key('mool-assistant-task-number-hint')),findsOneWidget);
      expect(find.byKey(const ValueKey('assistant-task-separator-0')),findsOneWidget);
      expect(find.text('All tasks'),findsNothing);expect(find.text('A–Z'),findsNothing);
      final target=c.actions().singleWhere((a)=>a.id==(mode=='Store'?'AI-ACT-275':'AI-ACT-014'));
      final n=mode=='Store'?1:4;
      final search=find.byKey(const Key('mool-assistant-action-search'));
      await tester.enterText(search,'task $n');await tester.pumpAndSettle();
      final row=find.byKey(ValueKey('assistant-action-${target.id}'));
      expect(row,findsOneWidget);
      expect(tester.widget<Text>(find.byKey(ValueKey('assistant-task-number-${target.id}'))).data,'$n');
      expect(tester.getSize(row).height,greaterThanOrEqualTo(48));
      await tester.enterText(search,'99999');await tester.pumpAndSettle();
      expect(find.text('No matching tasks. Try another word.'),findsOneWidget);
      await tester.enterText(search,'$n');await tester.pumpAndSettle();
      expect(row,findsOneWidget);
      await tester.ensureVisible(row);await tester.tap(row);await tester.pumpAndSettle();
      expect(c.draft,target.request);expect(c.proposal,isNull);
      expect(find.byKey(const Key('mool-assistant-action-list')),findsNothing);
      expect(tester.takeException(),isNull);
    });
  }

  for (final mode in ['consumer', 'pending', 'approved Store']) {
    testWidgets('DIRECT-TASKS $mode opens only current-context tasks in one tap', (tester) async {
      final source = _Context();
      source.change(mode == 'consumer' ? _context('a', 1) : MoolAssistantContext(
        accountScope: 'a', authenticationRevision: 1, workspaceId: 'store',
        workspaceName: 'Host fixture Store', workspaceRevision: 1,
        storeWorkspace: true, workspaceApproved: mode == 'approved Store'));
      final c = _controller(source);
      addTearDown(c.dispose);
      await _mount(tester, c);
      await _tapToolbar(tester, 'mool-assistant-actions');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mool-assistant-action-list')), findsOneWidget);
      expect(find.text('All tasks'), findsNothing);
      expect(find.text('Workspace setup'), findsNothing);
      expect(find.byKey(const Key('mool-assistant-action-categories')), findsNothing);
      expect(c.actions().every((a) => mode == 'approved Store' ? a.store : !a.store && a.group == 'Shopping'), isTrue);
      for (final id in ['AI-ACT-187', 'AI-ACT-190', 'AI-ACT-194']) {
        expect(c.chooseAction(id), isFalse);
      }
      final first = find.descendant(of: find.byKey(const Key('mool-assistant-action-list')), matching: find.byType(ListTile)).first;
      expect(first.hitTestable(), findsOneWidget);
      await _tapToolbar(tester, 'mool-assistant-actions');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mool-assistant-action-list')), findsNothing);
      expect(find.byType(MoolAssistantPage), findsOneWidget);
      expect(c.draft, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  for (final historyMode in [
    'absent',
    'failed',
    'mismatch',
    'origin-mismatch',
    'saved',
  ]) {
    testWidgets(
      'AI-HANDOFF owned route preserves request with $historyMode History',
      (tester) async {
        final context = _Context(), picker = _Picker();
        final source = _Entitlements(
          (account) async => _entitlement(account, MoolAssistantAccess.active),
        );
        final history = historyMode == 'absent' ? null : _History();
        if (historyMode == 'failed') {
          history!.saving = (ctx, text, language) async =>
              throw StateError('Host save failure');
        } else if (historyMode == 'mismatch') {
          history!.saving = (ctx, text, language) async => _thread(
            ctx,
            'wrong',
            draft: 'Not the current request',
            language: language,
          );
        }
        final adapter = _HandoffAdapter(context.value.binding);
        adapter.reviewGate = Completer<MoolAssistantReviewResult>()
          ..complete(MoolAssistantReviewResult.returnToOwner);
        final c = _controller(
          context,
          source: source,
          picker: picker,
          history: history,
          nativeAdapters: [adapter],
        );
        await c.refreshAccess();
        c.setDraft('Keep this native review request');
        picker.pending.complete(
          WorkPickedProof(
            fileName: 'HOST-selected.png',
            contentType: 'image/png',
            bytes: Uint8List.fromList([1, 2, 3]),
          ),
        );
        await c.pickAttachment(WorkProofSource.upload);
        final original = c.selectedAttachments.single;
        if (historyMode == 'origin-mismatch') {
          history!.saving = (ctx, text, language) async => _thread(
            ctx,
            'wrong-origin',
            draft: text,
            language: language,
            attachments: [
              MoolAssistantAttachment(
                fileName: original.fileName,
                contentType: original.contentType,
                bytes: original.bytes,
                duration: original.duration,
              ),
            ],
          );
        }
        try {
          await tester.pumpWidget(
            MaterialApp(
              theme: MoolTheme.light(),
              home: Builder(
                builder: (ctx) => Scaffold(
                  body: TextButton(
                    onPressed: () => unawaited(
                      Navigator.of(ctx).push<void>(
                        MaterialPageRoute<void>(
                          settings: const RouteSettings(name: 'mool-assistant'),
                          builder: (_) => MoolAssistantPage(
                            controller: c,
                            disposeController: true,
                          ),
                        ),
                      ),
                    ),
                    child: const Text('Original owner'),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Original owner'));
          await tester.pumpAndSettle();
          expect(
            c.receiveProposal(
              MoolAssistantProposal(
                id: 'owned-review',
                actionId: adapter.actionId,
                binding: context.value.binding,
                requestRevision: c.requestRevision,
                entitlementRevision: c.entitlementRevision!,
                sourceRevision: 'r1',
                validUntil: DateTime.now().add(const Duration(minutes: 1)),
                title: 'Review original form',
                summary: 'Open the original native review.',
                fields: const {'query': 'Rice'},
              ),
            ),
            isTrue,
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('Review'));
          await tester.pumpAndSettle();
          if (historyMode == 'saved') {
            expect(history!.saves, 1);
            expect(find.text('Original owner'), findsOneWidget);
          } else {
            expect(find.byType(MoolAssistantPage), findsOneWidget);
            expect(find.text('Keep your request?'), findsOneWidget);
            expect(c.draft, 'Keep this native review request');
            expect(
              c.selectedAttachments.single.bytes,
              orderedEquals(original.bytes),
            );
            expect(c.selectedAttachments.single.source, WorkProofSource.upload);
            await tester.tap(find.text('Keep editing'));
            await tester.pumpAndSettle();
            expect(c.hasInput, isTrue);
            expect(find.text('Original owner'), findsNothing);
          }
          expect(adapter.reviewCalls, 1);
          expect(tester.takeException(), isNull);
        } finally {
          // This is the real production ownership mode: the route, not the test,
          // disposes the controller and its entitlement timer.
          await tester.pumpWidget(const SizedBox.shrink());
          source.dispose();
          context.dispose();
        }
      },
    );
  }
  registerAct228SharedDocumentTests();
  registerOcrOpaqueReferenceTests();
  for (final routeName in ['mool-assistant', 'unrelated-route']) {
    testWidgets('AI-HANDOFF reveals native owner only from $routeName', (
      tester,
    ) async {
      final f = _HandoffFixture(history: _History());
      try {
        await f.ready();
        f.adapter.reviewGate = Completer<MoolAssistantReviewResult>();
        await tester.pumpWidget(
          MaterialApp(
            theme: MoolTheme.light(),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => unawaited(
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        settings: RouteSettings(name: routeName),
                        builder: (_) =>
                            MoolAssistantPage(controller: f.controller),
                      ),
                    ),
                  ),
                  child: const Text('Original native owner'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Original native owner'));
        await tester.pumpAndSettle();
        expect(f.controller.receiveProposal(f.proposal()), isTrue);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Review'));
        await tester.pump();
        await f.adapter.reviewEntered.future;
        expect(find.text('Opening…'), findsOneWidget);
        f.adapter.reviewGate!.complete(MoolAssistantReviewResult.returnToOwner);
        await tester.pumpAndSettle();
        expect(
          find.text('Original native owner'),
          routeName == 'mool-assistant' ? findsOneWidget : findsNothing,
        );
        expect(f.adapter.reviewCalls, 1);
        expect(f.controller.proposal, isNull);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      } finally {
        f.dispose();
      }
    });
  }
  testWidgets('AI-UI History groups local midnight and refreshes on resume', (
    tester,
  ) async {
    var now = DateTime(2026, 10, 26, 23, 59);
    final context = _Context(), source = _History();
    source.listing = (ctx, cursor) async => MoolAssistantHistoryPage(
      binding: ctx.binding,
      items: [
        MoolAssistantConversation(
          id: 'today',
          binding: ctx.binding,
          title: 'Midnight boundary',
          updatedAt: DateTime(2026, 10, 26).toUtc(),
          messages: const [],
        ),
        MoolAssistantConversation(
          id: 'yesterday',
          binding: ctx.binding,
          title: 'Previous day',
          updatedAt: DateTime(2026, 10, 25, 23, 59).toUtc(),
          messages: const [],
        ),
      ],
    );
    final c = _controller(context, history: source, clock: () => now);
    await _mount(tester, c, ownsController: true);
    await tester.tap(find.byTooltip('History'));
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = DateTime(2026, 10, 27, 0, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsNothing);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('Older'), findsOneWidget);
    expect(c.history.first.updatedAt, DateTime(2026, 10, 26).toUtc());
    expect(tester.takeException(), isNull);
  });
  registerOwnerAwareHandoffTests();
  _registerHandoffRegressionTests();
  registerHandoffPreparationTests();
  registerHandoffLargeBatchTests();
  _registerActualHostRouteBindingTests();
  _registerAssistantHistoryPresentationTests();
  testWidgets('ONE-LANE normal Media and Language share the same compact row', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 806);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = _controller(_Context());
    addTearDown(c.dispose);
    await _mount(tester, c);
    final composer = find
        .ancestor(
          of: find.byKey(const Key('mool-assistant-input')),
          matching: find.byType(DecoratedBox),
        )
        .first;
    final before = tester.getSize(composer).height;
    expect(before, lessThanOrEqualTo(130));
    expect(
      find.byKey(const Key('mool-assistant-control-lane')),
      findsOneWidget,
    );
    await _visualShot(tester, 'one-lane-main');
    await _tapToolbar(tester, 'mool-assistant-attach');
    expect(
      find.byKey(const ValueKey('mool-assistant-toolbar-strip')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('mool-assistant-control-lane')),
      findsOneWidget,
    );
    final mediaHeight = tester.getSize(composer).height;
    expect(mediaHeight, closeTo(before, 2));
    await tester.ensureVisible(
      find.byKey(const ValueKey('assistant-media-video')),
    );
    await tester.pumpAndSettle();
    await _visualShot(tester, 'one-lane-media');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('mool-assistant-toolbar-strip')),
      findsOneWidget,
    );
    await _tapToolbar(tester, 'mool-assistant-language');
    expect(
      find.byKey(const ValueKey('mool-assistant-toolbar-strip')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('mool-assistant-control-lane')),
      findsOneWidget,
    );
    final languageHeight = tester.getSize(composer).height;
    expect(languageHeight, closeTo(before, 2));
    await _visualShot(tester, 'one-lane-language');
    await _tapLanguageChoice(tester, 'English');
    expect(c.language, 'English');
    expect(c.draft, isEmpty);
    expect(tester.takeException(), isNull);
    debugPrint('ONE_LANE_HEIGHTS ${[before, mediaHeight, languageHeight]}');
  });

  testWidgets('ONE-LANE enlarged keyboard recording replaces open choices', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final c = _controller(
      _Context(),
      voice: _Voice(),
      source: _Entitlements(
        (a) async => _entitlement(a, MoolAssistantAccess.active),
      ),
    );
    await _mount(tester, c, scale: 2, ownsController: true);
    await tester.enterText(
      find.byKey(const Key('mool-assistant-input')),
      'Keep this request',
    );
    tester.view.viewInsets = const FakeViewPadding(bottom: 180);
    await tester.pumpAndSettle();
    await _tapToolbar(tester, 'mool-assistant-attach');
    await tester.ensureVisible(
      find.byKey(const ValueKey('assistant-media-video')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('mool-assistant-control-lane')),
      findsOneWidget,
    );
    await _visualShot(tester, 'one-lane-keyboard-media');
    await c.toggleVoice();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mool-assistant-media-choices')), findsNothing);
    expect(
      find.byKey(const ValueKey('mool-assistant-toolbar-strip')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('mool-assistant-recording-strip')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('mool-assistant-control-lane')),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Stop'));
    await tester.pumpAndSettle();
    await _visualShot(tester, 'one-lane-keyboard-recording');
    await tester.ensureVisible(find.text('Cancel'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('mool-assistant-toolbar-strip')),
      findsOneWidget,
    );
    expect(c.draft, 'Keep this request');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'ONE-LANE landscape enlarged Send remains reachable without wrapping',
    (tester) async {
      tester.view.physicalSize = const Size(720, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = _controller(_Context());
      addTearDown(c.dispose);
      await _mount(tester, c, scale: 2);
      final lane = find.byKey(const Key('mool-assistant-control-lane'));
      expect(
        find.descendant(of: lane, matching: find.byType(Wrap)),
        findsNothing,
      );
      await tester.ensureVisible(find.byKey(const Key('mool-assistant-send')));
      await tester.pumpAndSettle();
      final target = tester.getSize(
        find.byKey(const Key('mool-assistant-send')),
      );
      expect(target.width, greaterThanOrEqualTo(48));
      expect(target.height, greaterThanOrEqualTo(48));
      await _visualShot(tester, 'one-lane-landscape');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('INLINE replaced panels reject callbacks from hidden choices', (
    tester,
  ) async {
    final media = _Media();
    final c = _controller(
      _Context(),
      media: media,
      source: _Entitlements(
        (a) async => _entitlement(a, MoolAssistantAccess.active),
      ),
    );
    await _mount(tester, c, ownsController: true);
    await _tapToolbar(tester, 'mool-assistant-attach');
    await tester.pumpAndSettle();
    final staleMedia = tester
        .widget<TextButton>(find.byKey(const ValueKey('assistant-media-files')))
        .onPressed!;
    await _tapToolbar(tester, 'mool-assistant-language');
    await tester.pumpAndSettle();
    staleMedia();
    await tester.pumpAndSettle();
    expect(media.calls, 0);
    expect(c.selectedAttachments, isEmpty);
    final staleLanguage = tester
        .widget<TextButton>(
          find.byKey(const ValueKey('assistant-language-English')),
        )
        .onPressed!;
    await _tapToolbar(tester, 'mool-assistant-attach');
    await tester.pumpAndSettle();
    staleLanguage();
    await tester.pumpAndSettle();
    expect(c.language, 'Auto');
    expect(
      find.byKey(const Key('mool-assistant-media-choices')),
      findsOneWidget,
    );
  });
  testWidgets(
    'INLINE choices stay in composer Back preserves text and supports all presets',
    (tester) async {
      tester.view.physicalSize = const Size(360, 806);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = _controller(_Context());
      addTearDown(c.dispose);
      c.setDraft('Keep my request');
      await _mount(tester, c);
      final composer = find
          .ancestor(
            of: find.byKey(const Key('mool-assistant-input')),
            matching: find.byType(DecoratedBox),
          )
          .first;
      await _tapToolbar(tester, 'mool-assistant-attach');
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: composer,
          matching: find.byKey(const Key('mool-assistant-media-choices')),
        ),
        findsOneWidget,
      );
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      await tester.ensureVisible(
        find.byKey(const ValueKey('assistant-media-video')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('assistant-media-video')).hitTestable(),
        findsOneWidget,
      );
      await _visualShot(tester, 'inline-media-swiped');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('mool-assistant-media-choices')),
        findsNothing,
      );
      expect(c.draft, 'Keep my request');
      for (final language in [
        'English',
        'हिन्दी',
        'मराठी',
        'தமிழ்',
        'اردو',
        'ಕನ್ನಡ',
      ]) {
        await _tapToolbar(tester, 'mool-assistant-language');
        await tester.pumpAndSettle();
        expect(find.byType(PopupMenuButton<String>), findsNothing);
        await _tapLanguageChoice(tester, language);
        expect(c.language, language);
        expect(c.draft, 'Keep my request');
      }
      await _tapToolbar(tester, 'mool-assistant-language');
      await tester.pumpAndSettle();
      await _visualShot(tester, 'inline-language-swiped');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(c.language, 'ಕನ್ನಡ');
      expect(find.byType(MoolAssistantPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'INLINE enlarged media and language remain current bound and compact',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final context = _Context();
      final c = _controller(context);
      addTearDown(c.dispose);
      await _mount(tester, c, scale: 2);
      await tester.ensureVisible(
        find.byKey(const Key('mool-assistant-attach')),
      );
      await _tapToolbar(tester, 'mool-assistant-attach');
      await tester.pumpAndSettle();
      final stale = tester
          .widget<TextButton>(
            find.byKey(const ValueKey('assistant-media-files')),
          )
          .onPressed!;
      await tester.ensureVisible(
        find.byKey(const ValueKey('assistant-media-video')),
      );
      await tester.pumpAndSettle();
      await _visualShot(tester, 'inline-media-enlarged');
      context.change(_context('b', 2));
      await tester.pumpAndSettle();
      stale();
      await tester.pumpAndSettle();
      expect(c.selectedAttachments, isEmpty);
      expect(
        find.byKey(const Key('mool-assistant-media-choices')),
        findsNothing,
      );
      await tester.ensureVisible(
        find.byKey(const Key('mool-assistant-language')),
      );
      await _tapToolbar(tester, 'mool-assistant-language');
      await tester.pumpAndSettle();
      await _tapLanguageChoice(tester, 'தமிழ்');
      await tester.pumpAndSettle();
      await _visualShot(tester, 'inline-language-selected-enlarged');
      expect(c.language, 'தமிழ்');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('PREMIUM-02 main controls preserve full targets and draft', (
    tester,
  ) async {
    final c = _controller(_Context());
    addTearDown(c.dispose);
    c.setDraft('Keep this request');
    await _mount(tester, c);
    for (final key in [
      'mool-assistant-history',
      'mool-assistant-new-chat',
      'mool-assistant-back',
      'mool-assistant-attach',
      'mool-assistant-actions',
      'mool-assistant-voice',
      'mool-assistant-language',
      'mool-assistant-send',
    ]) {
      final size = tester.getSize(find.byKey(Key(key)));
      expect(size.width, greaterThanOrEqualTo(48), reason: key);
      expect(size.height, greaterThanOrEqualTo(48), reason: key);
    }
    await _tapToolbar(tester, 'mool-assistant-language');
    await tester.pumpAndSettle();
    expect(find.byType(PopupMenuButton<String>), findsNothing);
    expect(find.byType(BottomSheet), findsNothing);
    for (final button in tester.widgetList<TextButton>(
      find.descendant(
        of: find.byKey(const Key('mool-assistant-language-choices')),
        matching: find.byType(TextButton),
      ),
    )) {
      final size = tester.getSize(find.byKey(button.key!));
      expect(size.height, greaterThanOrEqualTo(48));
    }
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(c.draft, 'Keep this request');
  });
  testWidgets('PREMIUM-02 task aliases preserve original request and search', (
    tester,
  ) async {
    final c = _controller(_Context()..change(_context('a', 1, store: 's')));
    addTearDown(c.dispose);
    await _mount(tester, c);
    await _pickTask(tester, 'Add a product to my Store');
    expect(c.draft, 'Help me with this task: Add a product to my Store.');
    c.discardDraft();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mool-assistant-action-search')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('mool-assistant-action-search')),
      'Update sale prices',
    );
    await tester.pumpAndSettle();
    final action = c.actions().singleWhere(
      (a) => a.label == "Update a product's sale prices",
    );
    final row = find.byKey(ValueKey('assistant-action-${action.id}'));
    expect(
      find.descendant(of: row, matching: find.text('Update sale prices')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: row, matching: find.text('Products')),
      findsNothing,
    );
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(c.draft, action.request);
  });

  testWidgets(
    'PREMIUM-02 selected language is visible checked and context bound',
    (tester) async {
      final context = _Context();
      final c = _controller(context);
      addTearDown(c.dispose);
      await _mount(tester, c);
      await _tapToolbar(tester, 'mool-assistant-language');
      await tester.pumpAndSettle();
      expect(find.text('Automatic'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
      await _tapLanguageChoice(tester, 'English');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('mool-assistant-selected-language')),
        findsOneWidget,
      );
      await _tapToolbar(tester, 'mool-assistant-language');
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check), findsOneWidget);
      final stale = tester
          .widget<TextButton>(
            find.byKey(const ValueKey('assistant-language-हिन्दी')),
          )
          .onPressed!;
      context.change(_context('b', 2));
      await tester.pumpAndSettle();
      stale();
      await tester.pumpAndSettle();
      expect(c.language, 'Auto');
      expect(
        find.byKey(const Key('mool-assistant-selected-language')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'PREMIUM-02 narrow enlarged header and clear control remain distinct',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = _controller(_Context());
      addTearDown(c.dispose);
      await _mount(tester, c, scale: 2);
      final field = find.byKey(const Key('mool-assistant-action-search'));
      expect(tester.widget<TextField>(field).decoration!.hintText, 'Search');
      await tester.tap(field);
      await tester.pumpAndSettle();
      await tester.enterText(field, 'invoice');
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
      expect(find.byTooltip('Close Mool AI'), findsOneWidget);
      await _capture(tester, 'premium-02-narrow-search');
      await tester.tap(find.byTooltip('Clear task search'));
      await tester.pumpAndSettle();
      expect(c.draft, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'PREMIUM-02 History hides background header and restores request',
    (tester) async {
      final c = _controller(_Context(), history: _History());
      addTearDown(c.dispose);
      c.setDraft('Unsent request');
      await _mount(tester, c);
      await tester.tap(find.byTooltip('History'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Buy · 25/10/2026'), findsOneWidget);
      final header = find.byKey(const Key('mool-assistant-header'));
      final opacity = tester.widget<Opacity>(
        find.ancestor(of: header, matching: find.byType(Opacity)).first,
      );
      expect(opacity.opacity, 0);
      await _capture(tester, 'premium-02-history');
      await tester.tap(find.byTooltip('Close history'));
      await tester.pumpAndSettle();
      expect(c.draft, 'Unsent request');
      expect(find.byTooltip('Close Mool AI').hitTestable(), findsOneWidget);
    },
  );

  testWidgets('PREMIUM-02 recording groups Stop Cancel and enlarged duration', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final voice = _Voice();
    final c = _controller(
      _Context(),
      voice: voice,
      source: _Entitlements(
        (a) async => _entitlement(a, MoolAssistantAccess.active),
      ),
    );
    await _mount(tester, c, scale: 2, ownsController: true);
    await c.toggleVoice();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Stop'));
    await tester.pumpAndSettle();
    expect(find.text('Stop'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    await _capture(tester, 'premium-02-recording-enlarged');
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(voice.cancels, 1);
    expect(c.recording, isFalse);
  });

  testWidgets(
    'PREMIUM-02 legacy language stays accessible with enlarged attachments',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = _controller(
        _Context(),
        media: _Media(),
        source: _Entitlements(
          (a) async => _entitlement(a, MoolAssistantAccess.active),
        ),
      );
      await _mount(tester, c, scale: 2, ownsController: true);
      const language = 'A long custom reply language name';
      c.chooseLanguage(language);
      await c.pickMedia(ChatAttachmentKind.document);
      await c.pickMedia(ChatAttachmentKind.video);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Remove bill.pdf'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Reply language: $language'), findsOneWidget);
      final strip = find.byKey(const Key('mool-assistant-attachment-strip'));
      expect(
        find.ancestor(of: strip, matching: find.byType(Scrollbar)),
        findsOneWidget,
      );
      await _capture(tester, 'premium-02-language-attachments');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'PREMIUM enlarged mixed attachments remain readable and removable',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = _controller(
        _Context(),
        voice: _Voice(),
        media: _Media(),
        source: _Entitlements(
          (a) async => _entitlement(a, MoolAssistantAccess.active),
        ),
      );
      await _mount(tester, c, scale: 2, ownsController: true);
      await c.pickMedia(ChatAttachmentKind.document);
      await c.pickMedia(ChatAttachmentKind.video);
      await c.toggleVoice();
      await c.toggleVoice();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Remove bill.pdf'));
      await tester.pumpAndSettle();
      expect(find.text('3 attachments'), findsOneWidget);
      expect(find.byTooltip('Remove bill.pdf').hitTestable(), findsOneWidget);
      expect(
        tester.getSize(find.byTooltip('Remove bill.pdf')).height,
        greaterThanOrEqualTo(48),
      );
      await _capture(tester, 'premium-attachments-enlarged');
      await tester.tap(find.byTooltip('Remove bill.pdf'));
      await tester.pumpAndSettle();
      expect(c.selectedAttachments.map((a) => a.fileName), [
        'product.mp4',
        'Voice message.m4a',
      ]);
      expect(find.text('2 attachments'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'PREMIUM explicit Close exits Tasks while Back preserves request',
    (tester) async {
      final c = _controller(_Context());
      addTearDown(c.dispose);
      await _pushCloseFixture(tester, c);
      await tester.enterText(
        find.byKey(const Key('mool-assistant-input')),
        'Keep this request',
      );
      await _tapToolbar(tester, 'mool-assistant-actions');
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(c.draft, 'Keep this request');
      expect(find.text('Keep your request?'), findsNothing);
      await _tapToolbar(tester, 'mool-assistant-actions');
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Close Mool AI'));
      await tester.pumpAndSettle();
      expect(find.text('Keep your request?'), findsOneWidget);
      await tester.tap(find.text('Discard draft'));
      await tester.pumpAndSettle();
      expect(find.byType(MoolAssistantPage), findsNothing);
    },
  );

  testWidgets('PREMIUM audit Back closes direct Tasks before leaving AI', (tester) async {
    final c = _controller(_Context()..change(_context('a', 1, store: 's')));
    addTearDown(c.dispose);
    await _pushCloseFixture(tester, c);
    await _tapToolbar(tester, 'mool-assistant-actions');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mool-assistant-action-list')), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(MoolAssistantPage), findsOneWidget);
    expect(find.byKey(const Key('mool-assistant-action-list')), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(MoolAssistantPage), findsNothing);
  });
  testWidgets(
    'PREMIUM audit stale preset language does not change new account',
    (tester) async {
      final context = _Context();
      final c = _controller(context);
      addTearDown(c.dispose);
      await _mount(tester, c);
      await _tapToolbar(tester, 'mool-assistant-language');
      await tester.pumpAndSettle();
      final stale = tester
          .widget<TextButton>(
            find.byKey(const ValueKey('assistant-language-हिन्दी')),
          )
          .onPressed!;
      context.change(_context('b', 2));
      await tester.pumpAndSettle();
      stale();
      await tester.pumpAndSettle();
      expect(c.language, 'Auto');
    },
  );

  test('AI-VISUAL-03 MVP exposes Buy and approved Store actions only', () {
    final context = _Context();
    final c = _controller(context);
    addTearDown(c.dispose);
    const setupIds = {
      'AI-ACT-187',
      'AI-ACT-188',
      'AI-ACT-189',
      'AI-ACT-190',
      'AI-ACT-191',
      'AI-ACT-192',
      'AI-ACT-193',
      'AI-ACT-194',
      'AI-ACT-195',
    };
    expect(c.actions(), hasLength(78));
    expect(c.actions().where((a) => a.group == 'Shopping'), hasLength(78));
    expect(c.actions().where((a) => a.id == 'AI-ACT-036'), isEmpty);
    expect(
      c.actions().where((a) => a.group == 'Work').map((a) => a.id).toSet(),
      isEmpty,
    );
    for (final id in setupIds) { expect(c.chooseAction(id), isFalse); }
    for (final a in moolAssistantActions.where(
      (a) => !a.store && a.group != 'Shopping' && !setupIds.contains(a.id),
    )) {
      expect(c.chooseAction(a.id), isFalse, reason: a.id);
    }
    context.change(_context('a', 1, store: 'store'));
    expect(c.actions(), hasLength(158));
    expect(c.actions().every((a) => a.store), isTrue);
    c.setDraft('Keep this request');
    final id = c.actions().first.id;
    expect(c.chooseAction(id), isFalse);
    expect(c.draft, 'Keep this request');
    expect(c.chooseAction(id, replaceDraft: true), isTrue);
  });

  test(
    'AI-VISUAL-03 registration and foreign or signed-out approval stay Buyer',
    () {
      final buyer = _context('a', 1);
      MoolAssistantWorkspace workspace({
        bool approved = false,
        Object? owner = 'a',
      }) => MoolAssistantWorkspace(
        id: 's',
        name: 'Host approved Store',
        profile: 'retailer',
        revision: 1,
        isStore: true,
        approved: approved,
        approvalAccountScope: owner,
      );
      expect(buyer.withWorkspace(workspace()).inWorkspace, isFalse);
      expect(
        buyer.withWorkspace(workspace(approved: true, owner: 'b')).inWorkspace,
        isFalse,
      );
      expect(
        _context(null, 1).withWorkspace(workspace(approved: true)).inWorkspace,
        isFalse,
      );
      final approved = buyer.withWorkspace(workspace(approved: true));
      expect(approved.inWorkspace, isTrue);
      expect(approved.workspaceId, 's');
      expect(approved.binding, isNot(buyer.binding));
      expect(buyer.withWorkspace(workspace()).workspaceId, isNull);
    },
  );

  test(
    'AI-VISUAL-03 Workspace approval reads existing reviewed owner state',
    () {
      const account = (
        environment: 'host',
        projectId: 'host-project',
        tenantId: null,
        userId: 'a',
      );
      const foreign = (
        environment: 'host',
        projectId: 'host-project',
        tenantId: null,
        userId: 'b',
      );
      final session = WorkSession.production(
        contactDraftStore: _AssistantDraftStore('a'),
      );
      addTearDown(session.dispose);
      session.activeWorkspace = const WorkWorkspace(
        id: 's',
        name: 'Host fixture',
        profileLabel: 'Host',
        profileId: 'host-test',
        area: 'Host',
        verified: true,
      );
      expect(session.workspaceApprovalMatchesAccount(account), isFalse);
      session.workspaceId = 's';
      session.reviewStage = WorkReviewStage.approved;
      for (final status in [
        WorkRemoteReviewStatus.pending,
        WorkRemoteReviewStatus.rejected,
        WorkRemoteReviewStatus.suspended,
      ]) {
        session.remoteReviewStatus = status;
        expect(session.workspaceApprovalMatchesAccount(account), isFalse);
      }
      session.remoteReviewStatus = WorkRemoteReviewStatus.approved;
      expect(session.workspaceApprovalMatchesAccount(account), isTrue);
      final buyer = MoolAssistantContext(
        accountScope: account,
        authenticationRevision: 1,
      );
      final proof = MoolAssistantWorkspace(
        id: 's',
        name: 'Host approved Store',
        profile: 'retailer',
        revision: 1,
        isStore: true,
        approved: session.workspaceApprovalMatchesAccount(account),
        approvalAccountScope: account,
      );
      expect(buyer.withWorkspace(proof).inWorkspace, isTrue);
      expect(
        MoolAssistantContext(
          accountScope: foreign,
          authenticationRevision: 1,
        ).withWorkspace(proof).inWorkspace,
        isFalse,
      );

      expect(session.workspaceApprovalMatchesAccount(foreign), isFalse);
      expect(session.workspaceApprovalMatchesAccount(null), isFalse);
      session.reviewStatusNeedsRefresh = true;
      expect(session.workspaceApprovalMatchesAccount(account), isFalse);
      session.reviewStatusNeedsRefresh = false;
      session.workspaceId = 'other';
      expect(session.workspaceApprovalMatchesAccount(account), isFalse);
      session.workspaceId = 's';
      session.reviewStage = WorkReviewStage.gstPending;
      expect(session.workspaceApprovalMatchesAccount(account), isFalse);
      session.reviewStage = WorkReviewStage.live;
      session.remoteReviewStatus = WorkRemoteReviewStatus.live;
      expect(session.workspaceApprovalMatchesAccount(account), isTrue);
    },
  );

  testWidgets(
    'AI-VISUAL-03 compact header subtle search and categories only under Tasks',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        tester.view.physicalSize = const Size(360, 806);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final c = _controller(_Context()..change(_context('a', 1, store: 's')));
        addTearDown(c.dispose);
        await _mount(tester, c);
        final header = find.byKey(const Key('mool-assistant-header'));
        final search = find.byKey(const Key('mool-assistant-action-search'));
        expect(tester.getSize(header).height, lessThanOrEqualTo(56));
        expect(
          find.descendant(
            of: header,
            matching: find.textContaining('Host fixture Store'),
          ),
          findsNothing,
        );
        expect(
          find.byKey(const Key('mool-assistant-action-categories')),
          findsNothing,
        );
        final field = tester.widget<TextField>(search);
        final searchSemantics = tester.getSemantics(search).getSemanticsData();
        expect(
          [
            searchSemantics.label,
            searchSemantics.hint,
          ].where((value) => value.isNotEmpty).join(', '),
          'Search tasks',
        );
        expect(searchSemantics.hasFlag(ui.SemanticsFlag.isTextField), isTrue);
        expect(field.decoration!.border, InputBorder.none);
        expect(field.decoration!.enabledBorder, InputBorder.none);
        expect(field.decoration!.focusedBorder, InputBorder.none);
        expect(field.decoration!.disabledBorder, InputBorder.none);
        expect(field.decoration!.filled, isFalse);
        expect(field.decoration!.fillColor, isNull);
        final collapsed = tester.getSize(search).width;
        await tester.tap(search);
        await tester.pumpAndSettle();
        expect(
          tester
              .getSemantics(search)
              .getSemanticsData()
              .hasAction(ui.SemanticsAction.setText),
          isTrue,
        );
        expect(tester.getSize(search).width, greaterThan(collapsed));
        expect(
          find.byKey(const Key('mool-assistant-action-list')),
          findsOneWidget,
        );
        expect(find.byTooltip('New chat'), findsNothing);
        expect(
          tester
              .getSemantics(find.byKey(const Key('mool-assistant-actions')))
              .getSemanticsData()
              .hasAction(ui.SemanticsAction.tap),
          isTrue,
        );
        await _tapToolbar(tester, 'mool-assistant-actions');
        await tester.pumpAndSettle();
        expect(tester.getSize(search).width, closeTo(collapsed, 1));
        await _tapToolbar(tester, 'mool-assistant-actions');
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('mool-assistant-action-categories')),
          findsNothing,
        );
        expect(find.byType(GridView), findsNothing);
        await tester.enterText(search, 'receive goods');
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('mool-assistant-action-categories')),
          findsNothing,
        );
        expect(find.byTooltip('Clear task search'), findsOneWidget);
        await tester.tap(find.byTooltip('Clear task search'));
        await tester.pumpAndSettle();
        expect(c.draft, isEmpty);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'AI-VISUAL-03 task replacement requires explicit current decision',
    (tester) async {
      final context = _Context();
      final c = _controller(context);
      addTearDown(c.dispose);
      await _mount(tester, c);
      await tester.enterText(
        find.byKey(const Key('mool-assistant-input')),
        'Keep my typed request',
      );
      await _pickTask(tester, 'Find a product');
      expect(find.text('Replace your request?'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(c.draft, 'Keep my typed request');
      await tester.tap(
        find.byKey(const ValueKey('assistant-action-AI-ACT-001')),
      );
      await tester.pumpAndSettle();
      context.change(_context('b', 2));
      c.setDraft('Other account request');
      await tester.tap(find.text('Use task'));
      await tester.pumpAndSettle();
      expect(c.draft, 'Other account request');
      await _pickTask(tester, 'Find a product');
      await tester.tap(find.text('Use task'));
      await tester.pumpAndSettle();
      expect(c.draft, 'Help me with this task: Find a product.');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'AI-VISUAL-03 approval loss retires Store input and task search',
    (tester) async {
      final context = _Context()..change(_context('a', 1, store: 's'));
      final c = _controller(context);
      addTearDown(c.dispose);
      await _mount(tester, c);
      await _pickTask(tester, 'Add a product to my Store');
      final oldBinding = c.context.binding;
      context.change(
        MoolAssistantContext(
          accountScope: 'a',
          authenticationRevision: 1,
          workspaceId: 's',
          workspaceName: 'Pending Store',
          workspaceRevision: 2,
          storeWorkspace: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(c.context.inWorkspace, isFalse);
      expect(c.context.binding, isNot(oldBinding));
      expect(c.draft, isEmpty);
      expect(c.actions().every((a) => !a.store), isTrue);
      expect(find.text('Buy'), findsOneWidget);
    },
  );

  testWidgets(
    'AI-VISUAL stale Close decision cannot discard another account request',
    (tester) async {
      final context = _Context();
      final c = _controller(context);
      addTearDown(c.dispose);
      await _pushCloseFixture(tester, c);
      await tester.enterText(
        find.byKey(const Key('mool-assistant-input')),
        'First account request',
      );
      await tester.tap(find.byTooltip('Close Mool AI'));
      await tester.pumpAndSettle();
      context.change(_context('b', 2));
      c.setDraft('Second account request');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard draft'));
      await tester.pumpAndSettle();
      expect(c.draft, 'Second account request');
      expect(find.byType(MoolAssistantPage), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Keep your request?'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(c.draft, 'Second account request');
    },
  );
  testWidgets('AI-VISUAL Store direct tasks have full targets without category names', (tester) async {
    tester.view.physicalSize = const Size(360, 806);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = _controller(_Context()..change(_context('a',1,store:'host-store')));
    addTearDown(c.dispose);
    await _mount(tester,c);
    await _tapToolbar(tester,'mool-assistant-actions');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mool-assistant-action-categories')),findsNothing);
    expect(find.text('All tasks'),findsNothing);
    expect(find.text('Workspace setup'),findsNothing);
    expect(find.byKey(const Key('mool-assistant-action-list')),findsOneWidget);
    final first=find.descendant(of: find.byKey(const Key('mool-assistant-action-list')), matching: find.byType(ListTile)).first;
    expect(first.hitTestable(),findsOneWidget);
    expect(tester.getSize(first).height,greaterThanOrEqualTo(48));
    expect(tester.takeException(),isNull);
  });
  testWidgets('AI-VISUAL Tasks remains labelled and tappable at 320 width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = _controller(_Context());
    addTearDown(c.dispose);
    await _mount(tester, c);
    final target = find.byKey(const Key('mool-assistant-actions'));
    expect(
      find.descendant(of: target, matching: find.text('Tasks')),
      findsOneWidget,
    );
    expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
    expect(target.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _mount(tester, c, scale: 2);
    expect(target.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'AI-VISUAL restored conversation has title and speaker hierarchy',
    (tester) async {
      final c = _controller(_Context(), history: _History());
      addTearDown(c.dispose);
      await c.loadHistory();
      expect(await c.changeConversation(id: 'one'), isTrue);
      await _mount(tester, c);
      expect(find.text('Host history one'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);
      expect(find.text('Assistant'), findsOneWidget);
      expect(find.text('Prior user request'), findsOneWidget);
      expect(await c.changeConversation(), isTrue);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('mool-assistant-conversation-title')),
        findsNothing,
      );
      expect(c.messages, isEmpty);
    },
  );

  testWidgets('AI-VISUAL attachments show count type and voice duration', (
    tester,
  ) async {
    final c = _controller(
      _Context(),
      voice: _Voice(),
      media: _Media(),
      source: _Entitlements(
        (a) async => _entitlement(a, MoolAssistantAccess.active),
      ),
    );
    await _mount(tester, c, ownsController: true);
    await c.pickMedia(ChatAttachmentKind.document);
    await c.pickMedia(ChatAttachmentKind.video);
    await c.toggleVoice();
    await c.toggleVoice();
    await tester.pumpAndSettle();
    expect(find.text('3 attachments'), findsOneWidget);
    expect(find.byIcon(Icons.picture_as_pdf_outlined), findsOneWidget);
    expect(find.byIcon(Icons.videocam_outlined), findsOneWidget);
    await tester.drag(
      find.byType(SingleChildScrollView).last,
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Voice 0:02'), findsOneWidget);
    c.removeSelectedAttachment(2);
    await tester.pumpAndSettle();
    expect(find.text('2 attachments'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'AI-VISUAL header and system Close preserve until explicit discard',
    (tester) async {
      final c = _controller(_Context());
      addTearDown(c.dispose);
      await _pushCloseFixture(tester, c);
      await tester.enterText(
        find.byKey(const Key('mool-assistant-input')),
        'Unsent request',
      );
      await tester.tap(find.byTooltip('Close Mool AI'));
      await tester.pumpAndSettle();
      expect(find.text('Keep your request?'), findsOneWidget);
      expect(find.text('Save & close'), findsNothing);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(c.draft, 'Unsent request');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Keep your request?'), findsOneWidget);
      await tester.tap(find.text('Discard draft'));
      await tester.pumpAndSettle();
      expect(find.text('Open close fixture'), findsOneWidget);
      expect(find.byType(MoolAssistantPage), findsNothing);
      expect(c.draft, isEmpty);
    },
  );

  testWidgets(
    'AI-VISUAL Save and close waits for correct acknowledgement and preserves failure',
    (tester) async {
      final history = _History();
      final pending = Completer<MoolAssistantConversation>();
      history.saving = (_, _, _) => pending.future;
      final c = _controller(_Context(), history: history);
      addTearDown(c.dispose);
      await _pushCloseFixture(tester, c);
      await tester.enterText(
        find.byKey(const Key('mool-assistant-input')),
        'Keep this request',
      );
      await tester.tap(find.byTooltip('Close Mool AI'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save & close'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(MoolAssistantPage), findsOneWidget);
      expect(c.draft, 'Keep this request');
      pending.completeError(StateError('Host save unavailable'));
      await tester.pumpAndSettle();
      expect(find.byType(MoolAssistantPage), findsOneWidget);
      expect(c.draft, 'Keep this request');
      history.saving = (context, text, language) async =>
          _thread(context, 'saved', draft: text, language: language);
      await tester.tap(find.byTooltip('Close Mool AI'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save & close'));
      await tester.pumpAndSettle();
      expect(history.saves, 2);
      expect(find.byType(MoolAssistantPage), findsNothing);
      expect(c.draft, isEmpty);
    },
  );
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('AI-VISUAL audit baseline screens', _visualMatrix);
  testWidgets('AI-UI MVP invoice search includes Buy and excludes Food', (
    tester,
  ) async {
    final c = _controller(_Context());
    addTearDown(c.dispose);
    expect(
      c
          .actions('invoice')
          .any(
            (a) => a.label == 'View my order invoice' && a.group == 'Shopping',
          ),
      isTrue,
    );
    expect(
      c
          .actions('invoice')
          .any(
            (a) => a.label == 'View my food-order invoice' && a.group == 'Food',
          ),
      isFalse,
    );
    await _mount(tester, c);
    await _pickTask(tester, 'View my order invoice');
    expect(c.taskId, 'AI-ACT-413');
    expect(c.draft, 'Help me with this task: View my order invoice.');
    expect(tester.takeException(), isNull);
  });
  for (final acknowledgedId in ['other-chat', 'one']) {
    test('AI-HISTORY existing chat save requires its exact acknowledgement ID $acknowledgedId', () async {
      final context = _Context(), history = _History();
      final c = _controller(context, history: history);
      try {
        await c.loadHistory();
        expect(await c.changeConversation(id: 'one'), isTrue);
        c.setDraft('Keep this exact existing-chat request');
        final epoch = c.epoch;
        history.saving = (ctx, text, language) async =>
          _thread(ctx, acknowledgedId, draft: text, language: language);
        final saved = await c.changeConversation();
        if (acknowledgedId == 'one') {
          expect(saved, isTrue);
          expect(c.draft, isEmpty);
        } else {
          expect(saved, isFalse);
          expect(c.conversationId, 'one');
          expect(c.draft, 'Keep this exact existing-chat request');
          expect(c.epoch, epoch);
          expect(c.notice, 'Could not switch chats. Your current draft is unchanged.');
        }
      } finally { c.dispose(); }
    });
  }
  test('AI-HISTORY fresh chat save may allocate a new acknowledgement ID', () async {
    final context = _Context(), history = _History();
    final c = _controller(context, history: history);
    try {
      c.setDraft('New request without an existing history ID');
      expect(c.conversationId, isNull);
      history.saving = (ctx, text, language) async =>
        _thread(ctx, 'newly-allocated-chat', draft: text, language: language);
      expect(await c.changeConversation(), isTrue);
      expect(c.draft, isEmpty);
    } finally { c.dispose(); }
  });

  test('AI-UI saving cannot drop restored attachments', () async {
    final context = _Context(), source = _History();
    final clip = MoolAssistantAttachment(
      fileName: 'bill.pdf',
      contentType: 'application/pdf',
      bytes: Uint8List(16),
    );
    source.reading = (c, id) async => _thread(c, id, attachments: [clip]);
    final c = _controller(context, history: source);
    addTearDown(c.dispose);
    await c.loadHistory();
    expect(await c.changeConversation(id: 'one'), isTrue);
    c.setDraft('keep the document');
    source.saving = (c, text, language) async =>
        _thread(c, 'saved', draft: text, language: language);
    expect(await c.changeConversation(), isFalse);
    expect(c.draft, 'keep the document');
    expect(c.selectedAttachments.single.fileName, 'bill.pdf');
  });
  test('AI-UI old account save cannot unlock a newer pending save', () async {
    final context = _Context(), source = _History();
    final first = Completer<MoolAssistantConversation>(),
        second = Completer<MoolAssistantConversation>();
    source.saving = (_, _, _) =>
        source.saves == 1 ? first.future : second.future;
    final c = _controller(context, history: source);
    addTearDown(c.dispose);
    final old = context.value;
    c.setDraft('account A');
    final saveA = c.changeConversation();
    context.change(_context('b', 2));
    c.setDraft('account B');
    final saveB = c.changeConversation();
    first.complete(_thread(old, 'old', draft: 'account A'));
    expect(await saveA, isFalse);
    expect(c.historyBusy, isTrue);
    expect(c.draft, 'account B');
    second.complete(_thread(context.value, 'new', draft: 'account B'));
    expect(await saveB, isTrue);
    expect(c.historyBusy, isFalse);
  });
  test(
    'AI-UI audited action IDs are unique and Public/Store scopes separate',
    () {
      expect(moolAssistantActions.length, 405);
      expect(moolAssistantActions.map((a) => a.id).toSet().length, 405);
      final context = _Context(), c = _controller(_Context());
      addTearDown(c.dispose);
      expect(c.actions().length, 78);
      expect(c.actions().every((a) => !a.store), isTrue);
      final store = _controller(context..change(_context('a', 1, store: 's')));
      addTearDown(store.dispose);
      expect(store.actions().length, 158);
      expect(store.actions().every((a) => a.store), isTrue);
      expect(
        store.actions().singleWhere((action) => action.id == 'AI-ACT-404').label,
        'Review or copy printed details',
        reason: 'The original Copy fields editor reviews saved printed fields; '
            'it does not map them into receipt quantities or amounts.',
      );
      expect(
        store.actions().any((a) => a.label.contains('approved terms')),
        isFalse,
      );
      final id = store.actions().first.id;
      c.setDraft('keep');
      expect(c.chooseAction(id), isFalse);
      expect(c.draft, 'keep');
      expect(c.chooseAction('arbitrary-route'), isFalse);
    },
  );
  test('AI-UI New chat without history receiver preserves input', () async {
    final c = _controller(_Context());
    addTearDown(c.dispose);
    c.setDraft('private request');
    c.chooseLanguage('ગુજરાતી');
    expect(await c.changeConversation(), isFalse);
    expect(c.draft, 'private request');
    expect(c.language, 'ગુજરાતી');
    await c.loadHistory();
    expect(c.history, isEmpty);
    expect(c.historyNotice, isNotNull);
  });
  test(
    'AI-UI acknowledged save starts fresh and history restore never executes',
    () async {
      final source = _History(),
          c = _controller(_Context(), history: _History());
      addTearDown(c.dispose);
      final actual = _controller(_Context(), history: source);
      addTearDown(actual.dispose);
      actual.setDraft('Add rice');
      actual.chooseLanguage('हिन्दी');
      expect(await actual.changeConversation(), isTrue);
      expect(source.saves, 1);
      expect(actual.draft, isEmpty);
      expect(actual.language, 'Auto');
      await actual.loadHistory();
      expect(actual.history.single.id, 'one');
      expect(await actual.changeConversation(id: 'one'), isTrue);
      expect(actual.draft, 'stored request');
      expect(actual.messages.length, 2);
      expect(actual.taskId, isNull);
      expect(source.saves, 1);
      expect(source.reads, 1);
    },
  );
  test('AI-UI failed history save cannot erase a draft', () async {
    final source = _History()
      ..saving = (_, _, _) async => throw StateError('Unavailable');
    final c = _controller(_Context(), history: source);
    addTearDown(c.dispose);
    c.setDraft('keep');
    expect(await c.changeConversation(), isFalse);
    expect(c.draft, 'keep');
    expect(c.historyBusy, isFalse);
    expect(c.notice, contains('unchanged'));
  });
  test(
    'AI-UI late save, double tap and edits cannot discard newer input',
    () async {
      final context = _Context(),
          source = _History(),
          pending = Completer<MoolAssistantConversation>();
      source.saving = (_, _, _) => pending.future;
      final c = _controller(context, history: source);
      addTearDown(c.dispose);
      c.setDraft('first');
      final save = c.changeConversation();
      expect(await c.changeConversation(), isFalse);
      expect(source.saves, 1);
      c.setDraft('newer');
      pending.complete(_thread(context.value, 'saved', draft: 'first'));
      expect(await save, isFalse);
      expect(c.draft, 'newer');
      expect(c.historyBusy, isFalse);
    },
  );
  test(
    'AI-UI account switch rejects delayed history pages and saves',
    () async {
      final context = _Context(),
          source = _History(),
          pending = Completer<MoolAssistantHistoryPage>();
      source.listing = (_, _) => pending.future;
      final c = _controller(context, history: source);
      addTearDown(c.dispose);
      final prior = context.value, load = c.loadHistory();
      context.change(_context('b', 2));
      pending.complete(
        MoolAssistantHistoryPage(
          binding: prior.binding,
          items: [_thread(prior, 'private')],
        ),
      );
      await load;
      expect(c.history, isEmpty);
      expect(c.historyLoading, isFalse);
      expect(c.messages, isEmpty);
    },
  );
  test('AI-UI wrong-scope history and cursor loops are rejected', () async {
    final source = _History()
      ..listing = (c, _) async => MoolAssistantHistoryPage(
        binding: _context('other', 2).binding,
        items: [],
      );
    final c = _controller(_Context(), history: source);
    addTearDown(c.dispose);
    await c.loadHistory();
    expect(c.history, isEmpty);
    expect(c.historyNotice, isNotNull);
    source.listing = (c, cursor) async => MoolAssistantHistoryPage(
      binding: c.binding,
      items: [_thread(c, cursor ?? 'one')],
      nextCursor: 'same',
    );
    await c.loadHistory();
    expect(c.historyCursor, 'same');
    await c.loadHistory(more: true);
    expect(c.historyNotice, isNotNull);
    expect(c.history.length, 1);
  });
  testWidgets('AI-UI categories and search-tap expose actions without typing', (
    tester,
  ) async {
    final c = _controller(_Context()..change(_context('a', 1, store: 's')));
    addTearDown(c.dispose);
    await _mount(tester, c);
    expect(find.byTooltip('New chat'), findsOneWidget);
    expect(find.byTooltip('History'), findsOneWidget);
    await _tapToolbar(tester, 'mool-assistant-actions');
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byKey(const Key('mool-assistant-input')), findsOneWidget);
    expect(
      Navigator.of(
        tester.element(find.byKey(const Key('mool-assistant-input'))),
      ).canPop(),
      isFalse,
    );
    expect(
      find.byKey(const Key('mool-assistant-action-categories')),
      findsNothing,
    );
    expect(find.byKey(const Key('mool-assistant-action-list')), findsOneWidget);
    await _tapToolbar(tester, 'mool-assistant-actions');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mool-assistant-action-search')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mool-assistant-action-list')), findsOneWidget);
    expect(find.byKey(const Key('mool-assistant-action-list')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('mool-assistant-action-search')),
      'not-an-existing-task',
    );
    await tester.pumpAndSettle();
    expect(find.text('No matching tasks. Try another word.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('AI-UI stale picker cannot prepare a previous context task', (
    tester,
  ) async {
    final context = _Context(), c = _controller(_Context());
    addTearDown(c.dispose);
    final actual = _controller(context);
    addTearDown(actual.dispose);
    await _mount(tester, actual);
    await _tapToolbar(tester, 'mool-assistant-actions');
    await tester.pumpAndSettle();
    context.change(_context('a', 2, store: 's'));
    await tester.pumpAndSettle();
    expect(
      find.text('Your account or Store changed. Reopen tasks.'),
      findsNothing,
    );
    expect(actual.draft, isEmpty);
    expect(
      find.byKey(const Key('mool-assistant-action-categories')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'AI-UI unavailable History and New chat are truthful and preserve request',
    (tester) async {
      final c = _controller(_Context());
      addTearDown(c.dispose);
      await _mount(tester, c);
      await tester.enterText(
        find.byKey(const Key('mool-assistant-input')),
        'my request',
      );
      expect(
        tester
            .getRect(find.byKey(const Key('mool-assistant-history')))
            .center
            .dx,
        lessThan(
          tester.getRect(find.byKey(const Key('mool-assistant-context'))).left,
        ),
      );
      expect(
        tester.getRect(find.byKey(const Key('mool-assistant-actions'))).top,
        closeTo(
          tester.getRect(find.byKey(const Key('mool-assistant-send'))).top,
          1,
        ),
      );
      await tester.tap(find.byTooltip('New chat'));
      await tester.pumpAndSettle();
      expect(c.draft, 'my request');
      await tester.tap(find.byTooltip('History'));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byTooltip('Close history')).right,
        lessThan(tester.view.physicalSize.width / tester.view.devicePixelRatio),
      );
      expect(
        find.text('Chat history is unavailable right now.'),
        findsOneWidget,
      );
      expect(find.text('No saved chats yet.'), findsNothing);
      expect(c.draft, 'my request');
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'AI-INPUT unpaid voice and file requests never open native capture',
    () async {
      final voice = _Voice(), media = _Media();
      final c = _controller(_Context(), voice: voice, media: media);
      addTearDown(c.dispose);
      await c.toggleVoice();
      await c.pickMedia(ChatAttachmentKind.document);
      expect(voice.starts, 0);
      expect(media.calls, 0);
      expect(c.selectedAttachments, isEmpty);
    },
  );

  test(
    'AI-INPUT photo plus GPT voice audio plus file remain one request',
    () async {
      final context = _Context(),
          voice = _Voice(),
          media = _Media(),
          picker = _Picker();
      final source = _Entitlements(
        (a) async => _entitlement(a, MoolAssistantAccess.active),
      );
      final c = _controller(
        context,
        source: source,
        voice: voice,
        media: media,
        picker: picker,
      );
      addTearDown(c.dispose);
      await Future<void>.delayed(Duration.zero);
      picker.pending.complete(
        WorkPickedProof(
          fileName: 'product.png',
          contentType: 'image/png',
          bytes: Uint8List(16),
        ),
      );
      await c.pickAttachment(WorkProofSource.gallery);
      await c.toggleVoice();
      expect(c.recording, isTrue);
      await c.toggleVoice();
      await c.pickMedia(ChatAttachmentKind.document);
      expect(c.selectedAttachments.map((a) => a.contentType), [
        'image/png',
        'audio/mp4',
        'application/pdf',
      ]);
      expect(c.selectedAttachments[1].duration, const Duration(seconds: 2));
      expect(c.recording, isFalse);
      c.removeSelectedAttachment(1);
      expect(c.selectedAttachments.map((a) => a.fileName), [
        'product.png',
        'bill.pdf',
      ]);
      context.change(_context('b', 2));
      expect(c.selectedAttachments, isEmpty);
    },
  );

  test(
    'AI-INPUT account switch while microphone permission waits cancels late recording',
    () async {
      final context = _Context(),
          voice = _Voice()..pendingStart = Completer<void>();
      final source = _Entitlements(
        (a) async => _entitlement(a, MoolAssistantAccess.active),
      );
      final c = _controller(context, source: source, voice: voice);
      addTearDown(c.dispose);
      await Future<void>.delayed(Duration.zero);
      final opening = c.toggleVoice();
      context.change(_context('b', 2));
      voice.pendingStart!.complete();
      await opening;
      expect(c.recording, isFalse);
      expect(c.selectedAttachments, isEmpty);
      expect(voice.cancels, greaterThanOrEqualTo(1));
    },
  );

  test(
    'AI-INPUT cancellation and entitlement revocation discard recording without creating a clip',
    () async {
      final context = _Context(), voice = _Voice();
      final source = _Entitlements(
        (a) async => _entitlement(a, MoolAssistantAccess.active),
      );
      final c = _controller(context, source: source, voice: voice);
      addTearDown(c.dispose);
      await Future<void>.delayed(Duration.zero);
      await c.toggleVoice();
      c.cancelVoice();
      expect(voice.stops, 0);
      expect(c.selectedAttachments, isEmpty);
      await c.toggleVoice();
      source.response = (a) async =>
          _entitlement(a, MoolAssistantAccess.revoked);
      source.invalidate();
      await Future<void>.delayed(Duration.zero);
      expect(c.recording, isFalse);
      expect(c.paidAccessCurrent, isFalse);
      expect(c.selectedAttachments, isEmpty);
    },
  );

  test(
    'AI-INPUT aggregate memory guard preserves previously selected valid video',
    () async {
      final context = _Context(), media = _Media()..bytes = 20 * 1024 * 1024;
      final picker = _Picker();
      final source = _Entitlements(
        (a) async => _entitlement(a, MoolAssistantAccess.active),
      );
      final c = _controller(
        context,
        source: source,
        media: media,
        picker: picker,
      );
      addTearDown(c.dispose);
      await Future<void>.delayed(Duration.zero);
      await c.pickMedia(ChatAttachmentKind.video);
      await c.pickMedia(ChatAttachmentKind.video);
      expect(c.selectedAttachments.length, 1);
      expect(c.notice, contains('too large'));
    },
  );

  testWidgets(
    'AI-INPUT public actions, optional Auto language and media tray',
    (tester) async {
      final c = _controller(_Context());
      addTearDown(c.dispose);
      await _mount(tester, c);
      expect(find.text('What would you like to do?'), findsNothing);
      expect(find.byKey(const Key('mool-assistant-actions')), findsOneWidget);
      expect(find.text('Find products'), findsNothing);
      expect(find.text('Add product'), findsNothing);
      expect(find.byTooltip('Language: Auto'), findsOneWidget);
      expect(c.language, 'Auto');
      await _tapToolbar(tester, 'mool-assistant-language');
      await tester.pumpAndSettle();
      await _tapLanguageChoice(tester, 'தமிழ்');
      await tester.pumpAndSettle();
      expect(c.language, 'தமிழ்');
      expect(c.draft, isEmpty);
      await _tapToolbar(tester, 'mool-assistant-attach');
      await tester.pumpAndSettle();
      for (final label in ['Camera', 'Photos', 'Files', 'Video']) {
        expect(find.text(label), findsOneWidget);
      }
      await _tapMediaChoice(tester, 'files');
      await tester.pumpAndSettle();
      expect(c.notice, isNotNull);
      expect(c.selectedAttachments, isEmpty);
      await _pickTask(tester, 'Find a product');
      await tester.pumpAndSettle();
      expect(c.taskId, 'AI-ACT-001');
      expect(c.draft, 'Help me with this task: Find a product.');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('AI-INPUT Store tasks use current Store context', (tester) async {
    final c = _controller(
      _Context()..change(_context('a', 1, store: 'store-a')),
    );
    addTearDown(c.dispose);
    await _mount(tester, c);
    await _pickTask(tester, 'Add a product to my Store');
    expect(c.taskId, startsWith('store.AI-ACT-'));
    expect(c.actions().every((a) => a.store), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'AI-INPUT compact enlarged media and language controls keep typed text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final c = _controller(_Context());
      addTearDown(c.dispose);
      await _mount(tester, c, scale: 2);
      await tester.enterText(
        find.byKey(const Key('mool-assistant-input')),
        'ચોખા 2 kg',
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 180);
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('mool-assistant-attach')),
      );
      await _tapToolbar(tester, 'mool-assistant-attach');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Video'));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(c.draft, 'ચોખા 2 kg');
      expect(tester.takeException(), isNull);
      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('mool-assistant-language')),
      );
      await _tapToolbar(tester, 'mool-assistant-language');
      await tester.pumpAndSettle();
      await _tapLanguageChoice(tester, 'தமிழ்');
      await tester.pumpAndSettle();
      expect(c.language, 'தமிழ்');
      expect(c.draft, 'ચોખા 2 kg');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'AI-INPUT Android language final option clears physical safe bottom',
    (tester) async {
      tester.view.physicalSize = const Size(360, 806);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 41, bottom: 44);
      tester.view.viewPadding = const FakeViewPadding(top: 41, bottom: 44);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      final c = _controller(_Context());
      addTearDown(c.dispose);
      await _mount(tester, c);
      await _tapToolbar(tester, 'mool-assistant-language');
      await tester.pumpAndSettle();
      final choice = find.byKey(const ValueKey('assistant-language-ಕನ್ನಡ'));
      await tester.ensureVisible(choice);
      await tester.pumpAndSettle();
      final row = tester.getRect(choice);
      expect(row.bottom, lessThanOrEqualTo(806 - 44));
      expect(row.height, greaterThanOrEqualTo(48));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final previous = SharedPreferencesAsyncPlatform.instance;
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    addTearDown(() => SharedPreferencesAsyncPlatform.instance = previous);
  });

  test(
    'THIN-F01 no connector cannot activate AI or open private attachments',
    () async {
      final context = _Context();
      final picker = _Picker();
      final controller = _controller(context, picker: picker);
      addTearDown(controller.dispose);
      controller.setDraft('મને 10 કિલો ચોખા જોઈએ');
      await controller.pickAttachment(WorkProofSource.camera);
      expect(controller.draft, 'મને 10 કિલો ચોખા જોઈએ');
      expect(controller.access, MoolAssistantAccess.unavailable);
      expect(controller.paidAccessCurrent, isFalse);
      expect(picker.calls, 0);
    },
  );

  for (final access in MoolAssistantAccess.values.where(
    (a) => a != MoolAssistantAccess.active,
  )) {
    test('THIN-F01 $access blocks attachment access', () async {
      final context = _Context();
      final source = _Entitlements((a) async => _entitlement(a, access));
      final picker = _Picker();
      final controller = _controller(context, source: source, picker: picker);
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);
      await controller.pickAttachment(WorkProofSource.upload);
      expect(controller.paidAccessCurrent, isFalse);
      expect(picker.calls, 0);
    });
  }

  test('THIN-F01 signed-out context never asks for entitlement', () async {
    final context = _Context()..change(_context(null, 0));
    final source = _Entitlements(
      (a) async => _entitlement(a, MoolAssistantAccess.active),
    );
    final controller = _controller(context, source: source);
    addTearDown(controller.dispose);
    expect(source.calls, 0);
    expect(controller.paidAccessCurrent, isFalse);
  });

  for (final invalid in ['other-account', 'empty-revision', 'expired']) {
    test('THIN-F01 rejects $invalid entitlement', () async {
      final context = _Context();
      final source = _Entitlements(
        (a) async => _entitlement(
          invalid == 'other-account' ? 'another' : a,
          MoolAssistantAccess.active,
          revision: invalid == 'empty-revision' ? '' : 'verified-host',
          until: invalid == 'expired' ? DateTime(2000) : null,
        ),
      );
      final controller = _controller(context, source: source);
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);
      expect(controller.paidAccessCurrent, isFalse);
    });
  }

  test(
    'THIN-F01 A to B to A rejects old reads and retires private text',
    () async {
      final context = _Context();
      final reads = <Completer<MoolAssistantEntitlement>>[];
      final source = _Entitlements((_) {
        final result = Completer<MoolAssistantEntitlement>();
        reads.add(result);
        return result.future;
      });
      final controller = _controller(context, source: source);
      addTearDown(controller.dispose);
      controller.setDraft('private A invoice');
      context.change(_context('b', 2));
      expect(controller.draft, isEmpty);
      controller.setDraft('private B');
      context.change(_context('a', 3));
      reads[0].complete(_entitlement('a', MoolAssistantAccess.active));
      reads[1].complete(_entitlement('b', MoolAssistantAccess.active));
      await Future<void>.delayed(Duration.zero);
      expect(controller.paidAccessCurrent, isFalse);
      expect(controller.draft, isEmpty);
      reads[2].complete(
        _entitlement('a', MoolAssistantAccess.subscriptionRequired),
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.access, MoolAssistantAccess.subscriptionRequired);
    },
  );

  test(
    'THIN-F01 Store switch discards an in-flight attachment and duplicate tap',
    () async {
      final context = _Context()..change(_context('a', 1, store: 'store-a'));
      final source = _Entitlements(
        (a) async => _entitlement(a, MoolAssistantAccess.active),
      );
      final picker = _Picker();
      final controller = _controller(context, source: source, picker: picker);
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);
      final picking = controller.pickAttachment(WorkProofSource.camera);
      await controller.pickAttachment(WorkProofSource.camera);
      expect(picker.calls, 1);
      context.change(_context('a', 2, store: 'store-b'));
      picker.pending.complete(
        WorkPickedProof(
          fileName: 'private-original.png',
          contentType: 'image/png',
          bytes: Uint8List(2),
        ),
      );
      await picking;
      expect(controller.attachment, isNull);
      expect(controller.pickingAttachment, isFalse);
    },
  );

  test(
    'THIN-F01 source revocation immediately retires text before its read finishes',
    () async {
      final context = _Context();
      final source = _Entitlements(
        (a) async => _entitlement(a, MoolAssistantAccess.active),
      );
      final controller = _controller(context, source: source);
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);
      controller.setDraft('private');
      final pending = Completer<MoolAssistantEntitlement>();
      source.response = (_) => pending.future;
      source.invalidate();
      expect(controller.draft, isEmpty);
      expect(controller.paidAccessCurrent, isFalse);
      pending.complete(_entitlement('a', MoolAssistantAccess.revoked));
      await Future<void>.delayed(Duration.zero);
      expect(controller.access, MoolAssistantAccess.revoked);
    },
  );

  test('THIN-F01 expired proof clears private input on resume', () async {
    final context = _Context();
    var now = DateTime.utc(2026, 10, 25);
    final source = _Entitlements(
      (a) async => _entitlement(
        a,
        MoolAssistantAccess.active,
        until: now.add(const Duration(minutes: 2)),
      ),
    );
    final controller = _controller(context, source: source, clock: () => now);
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);
    controller.setDraft('private');
    now = now.add(const Duration(minutes: 3));
    controller.synchronize();
    expect(controller.paidAccessCurrent, isFalse);
    expect(controller.draft, isEmpty);
    expect(controller.access, MoolAssistantAccess.expired);
  });

  for (final size in [
    const Size(320, 568),
    const Size(360, 640),
    const Size(720, 360),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'THIN-F01 composer ${size.width}x${size.height} scale$scale and keyboard',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetViewInsets);
          final controller = _controller(_Context());
          addTearDown(controller.dispose);
          await _mount(tester, controller, scale: scale);
          expect(tester.takeException(), isNull);
          expect(find.text('Type or speak in your language'), findsOneWidget);
          final back = tester.getRect(
            find.byKey(const Key('mool-assistant-back')),
          );
          expect(back.width, greaterThanOrEqualTo(44));
          expect(back.height, greaterThanOrEqualTo(44));
          expect(back.center.dx, greaterThan(size.width / 2));
          expect(find.byTooltip('Close Mool AI'), findsOneWidget);
          expect(find.byIcon(Icons.arrow_back), findsNothing);
          if (size.width > size.height) {
            expect(
              find.byKey(const Key('mool-assistant-send')).hitTestable(),
              findsOneWidget,
            );
          }
          await _capture(
            tester,
            'composer-${size.width.toInt()}-${size.height.toInt()}-$scale',
          );
          await _pickTask(tester, 'Buy an earlier order again');
          await tester.pumpAndSettle();
          expect(
            controller.draft,
            'Help me with this task: Buy an earlier order again.',
          );
          expect(
            find.byKey(const Key('mool-assistant-starter-0')),
            findsNothing,
          );
          expect(find.text('हिन्दी · ગુજરાતી · English · more'), findsNothing);
          expect(
            find.byKey(const Key('mool-assistant-language')),
            findsOneWidget,
          );
          tester.view.viewInsets = const FakeViewPadding(bottom: 180);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            tester
                .widget<IconButton>(
                  find.byKey(const Key('mool-assistant-send')),
                )
                .onPressed,
            isNull,
          );
          await tester.enterText(
            find.byKey(const Key('mool-assistant-input')),
            '2 kg ચોખા / चावल ₹120 SKU-A',
          );
          await tester.pump();
          expect(controller.draft, '2 kg ચોખા / चावल ₹120 SKU-A');
        },
      );
    }
  }

  for (final access in MoolAssistantAccess.values) {
    testWidgets('THIN-F01 finished copy and closed send for $access', (
      tester,
    ) async {
      final context = _Context();
      final pending = Completer<MoolAssistantEntitlement>();
      final source = _Entitlements(
        (a) => access == MoolAssistantAccess.checking
            ? pending.future
            : Future.value(_entitlement(a, access)),
      );
      final controller = _controller(context, source: source);
      await _mount(tester, controller, ownsController: true);
      final copy = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join(' ');
      expect(
        copy,
        isNot(
          matches(
            RegExp(
              r'backend|API|prototype|payload|implementation|fixture|test',
              caseSensitive: false,
            ),
          ),
        ),
      );
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('mool-assistant-send')))
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
      if (!pending.isCompleted) {
        pending.complete(_entitlement('a', MoolAssistantAccess.unavailable));
      }
      await tester.pump();
    });
  }

  testWidgets(
    'THIN-F01 proposal has Review and Cancel without a duplicate final confirmation',
    (tester) async {
      var reviews = 0, cancellations = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          home: Scaffold(
            body: MoolAssistantProposalCard(
              title: 'Add product',
              summary: 'Rice · 2 kg',
              onReview: () => reviews++,
              onCancel: () => cancellations++,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Review'));
      await tester.tap(find.text('Cancel'));
      expect(reviews, 1);
      expect(cancellations, 1);
      expect(find.text('Confirm'), findsNothing);
    },
  );

  testWidgets(
    'THIN-F01 Android composer stays inside physical safe viewport without a paid banner',
    (tester) async {
      tester.view.physicalSize = const Size(360, 806);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 41, bottom: 44);
      tester.view.viewPadding = const FakeViewPadding(top: 41, bottom: 44);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      final controller = _controller(_Context());
      addTearDown(controller.dispose);
      await _mount(tester, controller);
      // AOSP legacy XML dump clips to app display size. The real view is full-height.
      const exportedBottom = 806.0 - 44;
      expect(
        tester.getRect(find.byKey(const Key('mool-assistant-language'))).bottom,
        lessThanOrEqualTo(exportedBottom),
      );
      final input = tester.getRect(
        find.byKey(const Key('mool-assistant-input')),
      );
      expect(input.bottom, lessThanOrEqualTo(exportedBottom));
      expect(input.height, greaterThanOrEqualTo(44));
      final copy = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join(' ');
      expect(copy.toLowerCase(), isNot(contains('paid service')));
      expect(copy.toLowerCase(), isNot(contains('subscription')));
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'AI-INPUT Android media final action clears physical system bottom',
    (tester) async {
      tester.view.physicalSize = const Size(360, 806);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 41, bottom: 44);
      tester.view.viewPadding = const FakeViewPadding(top: 41, bottom: 44);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      final c = _controller(_Context());
      addTearDown(c.dispose);
      await _mount(tester, c);
      await _tapToolbar(tester, 'mool-assistant-attach');
      await tester.pumpAndSettle();
      final choice = find.byKey(const ValueKey('assistant-media-video'));
      await tester.ensureVisible(choice);
      await tester.pumpAndSettle();
      final row = tester.getRect(choice);
      expect(row.bottom, lessThanOrEqualTo(806 - 44));
      expect(row.height, greaterThanOrEqualTo(48));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'THIN-F01 shared menu opens native route and Back preserves underlying field',
    (tester) async {
      final context = _Context();
      final field = TextEditingController(text: 'retained form');
      addTearDown(field.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          builder: (_, child) => MoolAssistantHost(
            readContext: () => context.value,
            contextChanges: context,
            child: child!,
          ),
          home: Scaffold(
            body: Column(
              children: [
                TextField(controller: field),
                MoolMainDomainMenu(keyPrefix: 'host', onOpenFamily: (_) {}),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('host-ai-mode')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mool-assistant-page')), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mool-assistant-page')), findsNothing);
      expect(field.text, 'retained form');
      expect(find.byKey(const Key('host-ai-mode')), findsOneWidget);
    },
  );

  testWidgets(
    'THIN-F01 production app menu opens unavailable AI and returns to exact Shop owner',
    (tester) async {
      final session = JourneySession(
        store: MemoryJourneyStore(
          snapshot: const JourneySnapshot(
            languageCode: 'en',
            areaMode: 'current',
            currentAreaLabel: 'Jodhpur',
            setupComplete: true,
            setupExperienceVersion: approvedSetupExperienceVersion,
          ),
        ),
        otpGateway: ReviewOtpGateway(signedIn: true),
      );
      addTearDown(session.dispose);
      await session.start();
      await tester.pumpWidget(
        MoolSocialApp(
          session: session,
          initialLocation: '/app/buy?sub=shop',
          uiReviewOnly: true,
        ),
      );
      await tester.pumpAndSettle();
      final before = find.byKey(const Key('mool-compact-launcher'));
      expect(before, findsOneWidget);
      await tester.tap(before);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('mool-navigator-ai-mode')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mool-assistant-page')), findsOneWidget);
      expect(find.text('AI unavailable'), findsOneWidget);
      expect(find.byTooltip('AI is unavailable right now.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('mool-assistant-back')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
      expect(
        find.byKey(const Key('mool-connected-action-navigator')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

// Isolated HOST routing fixture; not a runtime provider or permission grant.
class _RouteBoundHostAdapter extends _HandoffAdapter
    implements MoolAssistantRouteBoundNativeAdapter {
  _RouteBoundHostAdapter(this.owner, this.navigator, this.ownerRoute)
      : admitted = ownerRoute.isCurrent,
        super(owner.value.binding);
  final _Context owner;
  final NavigatorState navigator;
  final Route<dynamic> ownerRoute;
  final bool admitted;
  Route<void>? assistantRoute;
  Route<void>? nativeRoute;
  bool rejectedBinding = false;
  int binds = 0, nativeEffects = 0;
  final entered = Completer<void>();

  @override
  void bindAssistantRoute(Route<void> route, NavigatorState nextNavigator) {
    binds++;
    if (assistantRoute != null || !admitted || !ownerRoute.isCurrent ||
        !identical(nextNavigator, navigator) || route.navigator != null) {
      rejectedBinding = true;
      return;
    }
    assistantRoute = route;
  }

  bool get ownerCurrent => admitted && !rejectedBinding &&
      owner.value.binding == currentSnapshot!.binding && navigator.mounted &&
      identical(ownerRoute.navigator, navigator) && ownerRoute.isActive;
  bool get assistantCurrent => ownerCurrent &&
      assistantRoute != null && assistantRoute!.isCurrent &&
      identical(assistantRoute!.navigator, navigator);

  @override
  Future<MoolAssistantNativeSnapshot?> snapshot(
    MoolAssistantContext context, String? entityId,
  ) async {
    snapshotCalls++;
    return MoolAssistantNativeSnapshot(
      binding: currentSnapshot!.binding,
      sourceRevision: 'r1',
      permitted: assistantCurrent && context.binding == owner.value.binding,
    );
  }

  @override
  Future<MoolAssistantReviewResult> openReview(
    MoolAssistantProposal proposal, bool Function() isCurrent,
  ) async {
    reviewCalls++;
    if (!assistantCurrent || !isCurrent()) return MoolAssistantReviewResult.stale;
    final route = MaterialPageRoute<void>(builder: (_) => Scaffold(
      body: ElevatedButton(
        key: const Key('host-route-native-final'),
        onPressed: () {
          if (!ownerCurrent || !isCurrent() || nativeRoute?.isCurrent != true ||
              !identical(nativeRoute?.navigator, navigator)) return;
          nativeEffects++;
        },
        child: const Text('Original final control'),
      ),
    ));
    nativeRoute = route;
    final finished = navigator.push<void>(route);
    entered.complete();
    await finished;
    return ownerCurrent && isCurrent()
        ? MoolAssistantReviewResult.opened : MoolAssistantReviewResult.stale;
  }
}

class _RouteHostFixture {
  final owner = _Context();
  final navigator = GlobalKey<NavigatorState>();
  late final source = _Entitlements((account) async =>
      _entitlement(account, MoolAssistantAccess.active));
  late _RouteBoundHostAdapter adapter;
  int factories = 0, iterations = 0;
  Iterable<MoolAssistantNativeAdapter> _read(BuildContext context) sync* {
    iterations++;
    adapter = _RouteBoundHostAdapter(owner, navigator.currentState!,
        ModalRoute.of(context)!);
    yield adapter;
  }

  Future<MoolAssistantController> open(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigator,
      theme: MoolTheme.light(),
      builder: (_, child) => MoolAssistantHost(
        readContext: () => owner.value, contextChanges: owner,
        entitlements: source, child: child!,
      ),
      home: MoolAssistantNativeScope(
        readAdapters: (context) { factories++; return _read(context); },
        child: Builder(builder: (context) => Scaffold(body: ElevatedButton(
          key: const Key('host-route-open'),
          onPressed: () => unawaited(MoolAssistantHost.maybeOf(context)!.open(context)),
          child: const Text('Open assistant'),
        ))),
      ),
    ));
    await tester.tap(find.byKey(const Key('host-route-open')));
    await tester.pumpAndSettle();
    final controller = tester.widget<MoolAssistantPage>(
        find.byType(MoolAssistantPage)).controller;
    await controller.refreshAccess();
    controller.setDraft('Find Rice');
    await tester.pumpAndSettle();
    return controller;
  }

  MoolAssistantProposal proposal(MoolAssistantController controller) =>
      MoolAssistantProposal(
        id: 'actual-host-route-proposal', actionId: adapter.actionId,
        binding: owner.value.binding,
        requestRevision: controller.requestRevision,
        entitlementRevision: controller.entitlementRevision!,
        sourceRevision: 'r1', validUntil: DateTime.now().add(const Duration(minutes: 2)),
        title: 'Review native details', summary: 'Isolated HOST route test.',
        fields: const {'query': 'Rice'},
      );

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    owner.dispose();
    source.dispose();
  }
}

class _FailingRouteBindingAdapter extends _HandoffAdapter
    implements MoolAssistantRouteBoundNativeAdapter {
  _FailingRouteBindingAdapter(Object binding) : super(binding);
  @override
  void bindAssistantRoute(Route<void> route, NavigatorState navigator) =>
      throw StateError('Isolated binding failure');
}

void _registerActualHostRouteBindingTests() {
  testWidgets('HANDOFF failed binding disposes controller before a page owns it', (tester) async {
    final owner = _Context();
    final source = _Entitlements((a) async => _entitlement(a, MoolAssistantAccess.active));
    late BuildContext nativeContext;
    await tester.pumpWidget(MaterialApp(
      theme: MoolTheme.light(),
      builder: (_, child) => MoolAssistantHost(
        readContext: () => owner.value, contextChanges: owner,
        entitlements: source, child: child!,
      ),
      home: MoolAssistantNativeScope(
        readAdapters: (_) => [_FailingRouteBindingAdapter(owner.value.binding)],
        child: Builder(builder: (context) {
          nativeContext = context;
          return const Scaffold(body: Text('Native owner'));
        }),
      ),
    ));
    try {
      await expectLater(MoolAssistantHost.maybeOf(nativeContext)!.open(nativeContext),
          throwsStateError);
      await tester.pumpAndSettle();
      expect(find.byType(MoolAssistantPage), findsNothing);
      expect(find.text('Native owner'), findsOneWidget);
      expect(owner.observed, isFalse);
      expect(source.observed, isFalse);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      owner.dispose();
      source.dispose();
    }
  });
  testWidgets('HANDOFF actual Host materializes and binds the same adapter before push', (tester) async {
    final f = _RouteHostFixture();
    try {
      final controller = await f.open(tester);
      expect(f.factories, 1);
      expect(f.iterations, 1);
      expect(f.adapter.binds, 1);
      expect(f.adapter.admitted, isTrue);
      expect(f.adapter.ownerRoute.isCurrent, isFalse);
      expect(f.adapter.assistantRoute!.isCurrent, isTrue);
      expect((await f.adapter.snapshot(f.owner.value, null))!.permitted, isTrue);
      expect(controller.receiveProposal(f.proposal(controller)), isTrue);
      final result = controller.reviewProposal();
      await tester.pumpAndSettle();
      expect(f.adapter.reviewCalls, 1);
      expect(f.adapter.nativeEffects, 0); // Review is not the native final tap.
      await tester.tap(find.byKey(const Key('host-route-native-final')));
      expect(f.adapter.nativeEffects, 1);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(await result, MoolAssistantReviewResult.opened);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      // Existing unsaved-request protection still owns leaving AI mode.
      expect(find.text('Keep your request?'), findsOneWidget);
      await tester.tap(find.text('Discard draft'));
      await tester.pumpAndSettle();
      expect(find.byType(MoolAssistantPage), findsNothing);
      expect(find.byKey(const Key('host-route-open')), findsOneWidget);
      expect(f.adapter.ownerRoute.isCurrent, isTrue);
      expect((await f.adapter.snapshot(f.owner.value, null))!.permitted, isFalse);
      expect(tester.takeException(), isNull);
    } finally { await f.dispose(tester); }
  });

  testWidgets('HANDOFF bound Host refuses arbitrary same-name cover and owner retirement', (tester) async {
    final f = _RouteHostFixture();
    try {
      final controller = await f.open(tester);
      final cover = MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'mool-assistant'),
        builder: (_) => const Scaffold(body: Text('Unrelated cover')),
      );
      unawaited(f.navigator.currentState!.push<void>(cover));
      await tester.pumpAndSettle();
      expect((await f.adapter.snapshot(f.owner.value, null))!.permitted, isFalse);
      f.navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(controller.receiveProposal(f.proposal(controller)), isTrue);
      final result = controller.reviewProposal();
      await tester.pumpAndSettle();
      final retained = tester.widget<ElevatedButton>(
          find.byKey(const Key('host-route-native-final'))).onPressed!;
      f.owner.change(_context('a', 2)); // Same native route; different principal revision.
      await tester.pump();
      retained();
      expect(f.adapter.nativeEffects, 0);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(await result, MoolAssistantReviewResult.stale);
      expect(tester.takeException(), isNull);
    } finally { await f.dispose(tester); }
  });

  testWidgets('HANDOFF route identity is not transferable to a foreign navigator or rebound', (tester) async {
    final f = _RouteHostFixture();
    try {
      await f.open(tester);
      final original = f.adapter.assistantRoute;
      final foreign = GlobalKey<NavigatorState>();
      unawaited(f.navigator.currentState!.push<void>(MaterialPageRoute<void>(
        builder: (_) => Navigator(key: foreign, onGenerateRoute: (_) =>
          MaterialPageRoute<void>(builder: (_) => const Scaffold())),
      )));
      await tester.pumpAndSettle();
      f.adapter.bindAssistantRoute(MaterialPageRoute<void>(
          builder: (_) => const Scaffold()), foreign.currentState!);
      expect(f.adapter.assistantRoute, same(original));
      expect(f.adapter.rejectedBinding, isTrue);
      expect((await f.adapter.snapshot(f.owner.value, null))!.permitted, isFalse);
      f.adapter.bindAssistantRoute(original!, f.navigator.currentState!);
      expect(f.adapter.assistantRoute, same(original));
      expect(f.adapter.rejectedBinding, isTrue);
      expect(tester.takeException(), isNull);
    } finally { await f.dispose(tester); }
  });
}

MoolAssistantPreparationBatch _hostPreparation(_HandoffFixture f,{String id='HOST-batch',
  Object? binding,int? requestRevision,DateTime? until,List<MoolAssistantPreparationItem>? items}) =>
    MoolAssistantPreparationBatch(id:id,binding:binding??f.context.value.binding,
      requestRevision:requestRevision??f.controller.requestRevision,entitlementRevision:f.controller.entitlementRevision!,
      validUntil:until??f.now.add(const Duration(minutes:4)),items:items??[
        MoolAssistantPreparationItem(id:'ready-one',actionId:'AI-ACT-001',title:'Find rice',detail:'Rice 5 kg',
          state:MoolAssistantPreparationState.ready,proposal:f.proposal(id:'HOST-batch-one')),
        const MoolAssistantPreparationItem(id:'needs-input',actionId:'AI-ACT-001',title:'Find flour',detail:'Which pack size?',state:MoolAssistantPreparationState.needsInput),
        const MoolAssistantPreparationItem(id:'unavailable',actionId:'AI-ACT-001',title:'Find sugar',detail:'Original supplier details unavailable',state:MoolAssistantPreparationState.unavailable),
        MoolAssistantPreparationItem(id:'ready-two',actionId:'AI-ACT-001',title:'Find lentils',detail:'મૂળ दाल 1 kg',
          state:MoolAssistantPreparationState.ready,proposal:f.proposal(id:'HOST-batch-two',fields:{'query':'મૂળ दाल 1 kg'})),
      ]);

void registerHandoffPreparationTests(){
  test('HANDOFF-BATCH mixed preparation is immutable and never automatically reviews or dispatches',() async {
    final f=_HandoffFixture();try{await f.ready();f.controller.messages=const [(true,'HOST earlier preserved conversation')];final batch=_hostPreparation(f);
      expect(()=>batch.items.clear(),throwsUnsupportedError);expect(f.controller.receivePreparationBatch(batch),isTrue);
      expect(f.controller.preparationBatch,same(batch));expect(f.adapter.snapshotCalls,0);expect(f.adapter.reviewCalls,0);
      expect(f.controller.choosePreparationItem('needs-input'),isFalse);expect(f.controller.choosePreparationItem('unavailable'),isFalse);
      expect(f.controller.choosePreparationItem('ready-one'),isTrue);expect(f.adapter.snapshotCalls,0);expect(f.adapter.reviewCalls,0);
      expect(await f.controller.reviewProposal(),MoolAssistantReviewResult.opened);expect(f.adapter.reviewCalls,1);
      expect(f.controller.preparationBatch,same(batch));expect(f.controller.choosePreparationItem('ready-one'),isFalse);
      expect(f.controller.choosePreparationItem('ready-two'),isTrue);expect(f.adapter.reviewCalls,1);
      expect(await f.controller.reviewProposal(),MoolAssistantReviewResult.opened);expect(f.adapter.reviewCalls,2);
      expect(f.controller.messages,const [(true,'HOST earlier preserved conversation')]);expect(f.controller.draft,'Find Rice');
    }finally{f.dispose();}
  });
  test('HANDOFF-BATCH duplicates, foreign context, expired requests and unsupported ready fields reject atomically',() async {
    for(final kind in ['duplicate-item','duplicate-proposal','foreign','request','expired','unknown-action','invalid-fields','failed-with-proposal']){
      final f=_HandoffFixture();try{await f.ready();final normal=_hostPreparation(f);var items=normal.items;
        if(kind=='duplicate-item')items=[normal.items.first,normal.items.first];
        if(kind=='duplicate-proposal')items=[normal.items.first,MoolAssistantPreparationItem(id:'another',actionId:'AI-ACT-001',title:'Another',detail:'Same ID rejected',state:MoolAssistantPreparationState.ready,proposal:normal.items.first.proposal)];
        if(kind=='unknown-action')items=[MoolAssistantPreparationItem(id:'bad',actionId:'AI-ACT-036',title:'Excluded',detail:'Not MVP Buy',state:MoolAssistantPreparationState.ready,proposal:f.proposal(actionId:'AI-ACT-036'))];
        if(kind=='invalid-fields')items=[MoolAssistantPreparationItem(id:'bad',actionId:'AI-ACT-001',title:'Find',detail:'Unexpected field',state:MoolAssistantPreparationState.ready,proposal:f.proposal(fields:{'query':'rice','autoPublish':true}))];
        if(kind=='failed-with-proposal')items=[MoolAssistantPreparationItem(id:'bad',actionId:'AI-ACT-001',title:'Find',detail:'Inconsistent response',state:MoolAssistantPreparationState.unavailable,proposal:f.proposal())];
        final batch=_hostPreparation(f,items:items,binding:kind=='foreign'?'HOST-foreign':null,
          requestRevision:kind=='request'?f.controller.requestRevision+1:null,until:kind=='expired'?f.now.subtract(const Duration(seconds:1)):null);
        expect(f.controller.receivePreparationBatch(batch),isFalse,reason:kind);expect(f.controller.preparationBatch,isNull);
        expect(f.controller.proposal,isNull);expect(f.adapter.reviewCalls,0);
      }finally{f.dispose();}
    }
  });
  test('HANDOFF-BATCH original source revalidation rejects stale ready item with zero native effect',() async {
    final f=_HandoffFixture();try{await f.ready();expect(f.controller.receivePreparationBatch(_hostPreparation(f)),isTrue);
      expect(f.controller.choosePreparationItem('ready-one'),isTrue);
      f.adapter.currentSnapshot=MoolAssistantNativeSnapshot(binding:f.context.value.binding,sourceRevision:'HOST-new-original',permitted:true);
      expect(await f.controller.reviewProposal(),MoolAssistantReviewResult.stale);expect(f.adapter.reviewCalls,0);
    }finally{f.dispose();}
  });
  test('HANDOFF-BATCH dismissal rejects the same envelope until a genuinely new request',()async{
    final f=_HandoffFixture();try{await f.ready();final batch=_hostPreparation(f);
      expect(f.controller.receivePreparationBatch(batch),isTrue);f.controller.cancelProposal();
      expect(f.controller.receivePreparationBatch(batch),isFalse);expect(f.adapter.reviewCalls,0);
      f.controller.setDraft('HOST new request');expect(f.controller.receivePreparationBatch(_hostPreparation(f)),isTrue);
    }finally{f.dispose();}
  });
  testWidgets('HANDOFF-BATCH expiry clears prepared rows and active selection without dispatch',(tester)async{
    final f=_HandoffFixture();try{await f.ready();final until=f.now.add(const Duration(seconds:1));
      expect(f.controller.receivePreparationBatch(_hostPreparation(f,until:until)),isTrue);
      expect(f.controller.choosePreparationItem('ready-one'),isTrue);f.now=until;
      await tester.pump(const Duration(seconds:1));expect(f.controller.preparationBatch,isNull);
      expect(f.controller.proposal,isNull);expect(f.controller.choosePreparationItem('ready-two'),isFalse);
      expect(f.adapter.reviewCalls,0);expect(f.controller.draft,'Find Rice');
    }finally{f.dispose();}
  });
  for(final kind in ['Cancel','request','background','access','context']){
    test('HANDOFF-BATCH actual $kind retires all private preparation without automatic replay',() async {
      final f=_HandoffFixture();try{await f.ready();expect(f.controller.receivePreparationBatch(_hostPreparation(f)),isTrue);
        switch(kind){case 'Cancel':f.controller.cancelProposal();break;case 'request':f.controller.setDraft('HOST revised request');break;
          case 'background':f.controller.setForeground(false);break;case 'access':f.source.response=(account)async=>_entitlement(account,MoolAssistantAccess.revoked);f.source.invalidate();await f.controller.refreshAccess();break;
          case 'context':f.context.change(_context('another',2));break;}
        expect(f.controller.preparationBatch,isNull);expect(f.controller.proposal,isNull);expect(f.controller.choosePreparationItem('ready-one'),isFalse);
        expect(f.adapter.reviewCalls,0);
      }finally{f.dispose();}
    });
  }
  for(final scale in [1.0,2.0]){
    testWidgets('HANDOFF-BATCH mixed compact presentation fits narrow text$scale and Choose is preparation only',(tester)async{
      final f=_HandoffFixture();try{await f.ready();final batch=_hostPreparation(f);expect(f.controller.receivePreparationBatch(batch),isTrue);
        tester.view.physicalSize=const Size(320,568);tester.view.devicePixelRatio=1;
        addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(MaterialApp(theme:MoolTheme.light(),home:MediaQuery(data:MediaQueryData(size:const Size(320,568),textScaler:TextScaler.linear(scale)),
          child:MoolAssistantPage(controller:f.controller))));
        expect(find.text('Prepared tasks'),findsOneWidget);expect(find.textContaining('completed'),findsNothing);
        final choose=find.widgetWithText(TextButton,'Choose').first;await tester.ensureVisible(choose);await tester.tap(choose);await tester.pumpAndSettle();
        expect(f.controller.proposal,same(batch.items.first.proposal));expect(f.adapter.reviewCalls,0);expect(f.adapter.snapshotCalls,0);
        final selected=find.byKey(const ValueKey('assistant-preparation-ready-one'));
        final scroll=find.descendant(of:find.byKey(const Key('mool-assistant-content')),matching:find.byType(Scrollable)).first;
        await tester.scrollUntilVisible(selected,-200,scrollable:scroll,maxScrolls:20);await tester.ensureVisible(selected);await tester.pump();
        expect(find.textContaining('Selected for review'),findsOneWidget);
        for(final item in [('needs-input','More details needed'),('unavailable','Unavailable')]){
          final row=find.byKey(ValueKey('assistant-preparation-${item.$1}'));
          await tester.scrollUntilVisible(row,200,scrollable:scroll,maxScrolls:20);await tester.ensureVisible(row);await tester.pump();
          expect(find.descendant(of:row,matching:find.textContaining(item.$2)),findsOneWidget);
        }
        expect(tester.takeException(),isNull);
      }finally{await tester.pumpWidget(const SizedBox.shrink());f.dispose();}
    });
  }
}

void registerHandoffLargeBatchTests(){
  for(final scale in [1.0,2.0]){
  for(final selectedIndex in [0,249,499]){
  testWidgets('HANDOFF-BATCH500 row$selectedIndex text$scale keeps nearby original Review in a lazy effect-free result list',(tester)async{
    final f=_HandoffFixture();try{
      await f.ready();final rows=[for(var i=0;i<500;i++)MoolAssistantPreparationItem(
        id:'HOST-prepared-$i',actionId:'AI-ACT-001',title:'HOST item $i · दाल',detail:'Original supplied pack $i',
        state:MoolAssistantPreparationState.ready,proposal:f.proposal(id:'HOST-large-proposal-$i',fields:{'query':'HOST item $i · दाल 1 kg'}))];
      expect(f.controller.receivePreparationBatch(_hostPreparation(f,items:rows)),isTrue);
      tester.view.physicalSize=const Size(320,568);tester.view.devicePixelRatio=1;
      addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(theme:MoolTheme.light(),home:MediaQuery(data:MediaQueryData(size:const Size(320,568),textScaler:TextScaler.linear(scale)),
        child:MoolAssistantPage(controller:f.controller))));await tester.pump();
      final visibleRows=find.byWidgetPredicate((widget)=>widget.key is ValueKey<String> && ((widget.key! as ValueKey<String>).value).startsWith('assistant-preparation-HOST-prepared-'));
      expect(visibleRows.evaluate().length,lessThan(40),reason:'500 valid rows must not eagerly create500 tiles inside one Column.');
      final last=find.byKey(const ValueKey('assistant-preparation-HOST-prepared-499'));
      expect(last,findsNothing);expect(f.adapter.snapshotCalls,0);expect(f.adapter.reviewCalls,0);
      final scroll=find.descendant(of:find.byKey(const Key('mool-assistant-content')),matching:find.byType(Scrollable)).first;
      final selected=find.byKey(ValueKey('assistant-preparation-HOST-prepared-$selectedIndex'));
      await tester.scrollUntilVisible(selected,240,scrollable:scroll,maxScrolls:1000);await tester.ensureVisible(selected);await tester.pump();
      expect(selected,findsOneWidget);expect(visibleRows.evaluate().length,lessThan(40));expect(f.adapter.snapshotCalls,0);expect(f.adapter.reviewCalls,0);
      final choose=find.descendant(of:selected,matching:find.widgetWithText(TextButton,'Choose'));
      await tester.ensureVisible(choose);await tester.tap(choose);await tester.pump();
      expect(f.controller.proposal,same(rows[selectedIndex].proposal));expect(f.adapter.snapshotCalls,0);expect(f.adapter.reviewCalls,0);
      final proposal=find.byKey(ValueKey('assistant-proposal-${rows[selectedIndex].proposal!.id}'));
      // Choosing an early/middle row must not put its Review after500 siblings.
      // A short local reveal is enough even with the original card at text2.
      await tester.scrollUntilVisible(proposal,160,scrollable:scroll,maxScrolls:6);await tester.ensureVisible(proposal);await tester.pump();
      expect(proposal,findsOneWidget);
      final review=find.descendant(of:proposal,matching:find.widgetWithText(FilledButton,'Review'));
      await tester.ensureVisible(review);await tester.pump();expect(review.hitTestable(),findsOneWidget);
      expect(visibleRows.evaluate().length,lessThan(40));
      expect(f.adapter.snapshotCalls,0);expect(f.adapter.reviewCalls,0);
      expect(f.controller.draft,'Find Rice');expect(tester.takeException(),isNull);
      f.controller.cancelProposal();await tester.pump();expect(f.controller.preparationBatch,isNull);
      expect(visibleRows,findsNothing);expect(f.adapter.reviewCalls,0);
    }finally{await tester.pumpWidget(const SizedBox.shrink());f.dispose();}
  });
  }
  }
}
