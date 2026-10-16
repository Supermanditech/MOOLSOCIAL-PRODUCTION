// Isolated host adapter fixtures only. Never loaded into runtime Store data.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/work/work_customer_feedback.dart';
import 'package:moolsocial/features/work/widgets/store_customer_feedback.dart';

const scope = (account: 'host-account', store: 'host-store');
StoreFeedbackEntry entry({
  String id = 'central-review',
  String version = 'opaque-v1',
  String store = 'host-store',
  StoreFeedbackKind kind = StoreFeedbackKind.overallOrder,
  bool permitted = true,
}) => StoreFeedbackEntry(
  storeId: store,
  id: id,
  version: version,
  kind: kind,
  authorLabel: 'Permitted customer label',
  text: 'The items arrived as ordered.',
  stars: 4,
  orderId: 'this-store-suborder',
  mixedOrder: kind == StoreFeedbackKind.overallOrder,
  productId: kind == StoreFeedbackKind.product ? 'exact-sku' : null,
  productLabel: kind == StoreFeedbackKind.product ? 'Exact pack' : null,
  replyAudiences: permitted ? {StoreFeedbackAudience.storeAndCustomer} : {},
  canReport: permitted,
);
StoreFeedbackPage page({
  List<StoreFeedbackEntry>? entries,
  String? next,
  StoreFeedbackCoverage coverage = StoreFeedbackCoverage.complete,
}) => StoreFeedbackPage(
  scope: scope,
  coverage: coverage,
  entries: entries ?? [entry()],
  nextCursor: next,
);

class Adapter implements StoreFeedbackAdapter {
  @override
  bool commandRecoveryReady = true;
  Future<StoreFeedbackPage> Function(String?) read = (_) async => page();
  Future<StoreFeedbackResult> Function(StoreFeedbackCommand) write =
      (c) async => StoreFeedbackResult(
        command: c,
        outcome: StoreFeedbackOutcome.accepted,
      );
  Future<StoreFeedbackResult> Function(StoreFeedbackCommand) recover =
      (c) async => StoreFeedbackResult(
        command: c,
        outcome: StoreFeedbackOutcome.accepted,
      );
  final submitted = <StoreFeedbackCommand>[],
      reconciled = <StoreFeedbackCommand>[];
  @override
  Future<StoreFeedbackPage> load(StoreFeedbackScope scope, {String? cursor}) =>
      read(cursor);
  @override
  Future<StoreFeedbackResult> submit(StoreFeedbackCommand command) {
    submitted.add(command);
    return write(command);
  }

  @override
  Future<StoreFeedbackResult> reconcile(StoreFeedbackCommand original) {
    reconciled.add(original);
    return recover(original);
  }
}

void main() {
  late Adapter adapter;
  late StoreFeedbackController controller;
  Object? current;
  StoreFeedbackBinding? composer;
  setUp(() {
    adapter = Adapter();
    current = (scope, 1);
    composer = null;
    controller = StoreFeedbackController(
      scope: scope,
      context: () => current,
      adapter: adapter,
    );
  });
  tearDown(() => controller.dispose());
  Future<void> ready() async {
    await controller.load();
  }

  void draft(
    String text, [
    StoreFeedbackAction action = StoreFeedbackAction.reply,
  ]) {
    composer ??= controller.bindingFor('central-review');
    if (composer != null) controller.setDraft(composer!, action, text);
  }

  Future<void> send() async {
    if (composer != null) {
      await controller.submit(
        composer!,
        StoreFeedbackAction.reply,
        StoreFeedbackAudience.storeAndCustomer,
      );
    }
  }

  test('missing adapter is unavailable, never verified zero', () async {
    final missing = StoreFeedbackController(
      scope: scope,
      context: () => current,
    );
    addTearDown(missing.dispose);
    await missing.load();
    expect(missing.coverage, StoreFeedbackCoverage.unavailable);
    expect(missing.entries, isEmpty);
    expect(missing.actionsReady, isFalse);
  });
  test('complete empty and partial empty retain distinct coverage', () async {
    adapter.read = (_) async => page(entries: []);
    await ready();
    expect(controller.coverage, StoreFeedbackCoverage.complete);
    adapter.read = (_) async =>
        page(entries: [], coverage: StoreFeedbackCoverage.partial);
    await ready();
    expect(controller.coverage, StoreFeedbackCoverage.partial);
  });
  test('foreign account envelope is rejected', () async {
    adapter.read = (_) async => StoreFeedbackPage(
      scope: (account: 'other', store: scope.store),
      coverage: StoreFeedbackCoverage.complete,
      entries: [entry()],
    );
    await ready();
    expect(controller.entries, isEmpty);
    expect(controller.message, isNotNull);
  });
  test(
    'foreign Store entry rejects whole page without private leakage',
    () async {
      adapter.read = (_) async => page(
        entries: [
          entry(),
          entry(id: 'foreign', store: 'other-store'),
        ],
      );
      await ready();
      expect(controller.entries, isEmpty);
      expect(controller.actionsReady, isFalse);
    },
  );
  test(
    'invalid review and unavailable page with entries fail closed',
    () async {
      adapter.read = (_) async => page(entries: [entry(version: '')]);
      await ready();
      expect(controller.entries, isEmpty);
      adapter.read = (_) async =>
          page(coverage: StoreFeedbackCoverage.unavailable);
      await ready();
      expect(controller.entries, isEmpty);
    },
  );
  test(
    'paging deduplicates central IDs without contributing extra ratings',
    () async {
      adapter.read = (cursor) async => cursor == null
          ? page(next: 'opaque-next')
          : page(
              entries: [
                entry(),
                entry(id: 'service', kind: StoreFeedbackKind.storeService),
              ],
            );
      await ready();
      await controller.load(more: true);
      expect(controller.entries.map((e) => e.id), [
        'central-review',
        'service',
      ]);
      expect(controller.entries.first.mixedOrder, isTrue);
    },
  );
  test(
    'opaque version conflict retains original page but blocks actions',
    () async {
      adapter.read = (cursor) async => cursor == null
          ? page(next: 'next')
          : page(entries: [entry(version: 'different')]);
      await ready();
      await controller.load(more: true);
      expect(controller.entries.single.version, 'opaque-v1');
      expect(controller.actionsReady, isFalse);
      expect(controller.message, isNotNull);
    },
  );
  test('pagination cannot loop the same cursor', () async {
    adapter.read = (_) async => page(next: 'repeat');
    await ready();
    await controller.load(more: true);
    expect(controller.nextCursor, isNull);
    expect(controller.message, isNotNull);
  });
  test('late feed after context epoch change is not applied', () async {
    final result = Completer<StoreFeedbackPage>();
    adapter.read = (_) => result.future;
    final loading = controller.load();
    current = (scope, 2);
    result.complete(page());
    await loading;
    expect(controller.entries, isEmpty);
    expect(controller.actionsReady, isFalse);
  });
  test('late feed after controller disposal does not notify', () async {
    final closed = StoreFeedbackController(
      scope: scope,
      context: () => current,
      adapter: adapter,
    );
    final result = Completer<StoreFeedbackPage>();
    adapter.read = (_) => result.future;
    final loading = closed.load();
    closed.dispose();
    result.complete(page());
    await loading;
    expect(closed.entries, isEmpty);
  });
  test('capabilities and qualified recovery are both required', () async {
    adapter.read = (_) async => page(entries: [entry(permitted: false)]);
    await ready();
    draft('Reply');
    await send();
    expect(adapter.submitted, isEmpty);
    adapter.read = (_) async => page();
    await ready();
    adapter.commandRecoveryReady = false;
    await send();
    expect(adapter.submitted, isEmpty);
  });
  test(
    'audience and nonempty bounded content are enforced centrally',
    () async {
      await ready();
      draft('Reply');
      await controller.submit(
        composer!,
        StoreFeedbackAction.reply,
        StoreFeedbackAudience.public,
      );
      draft(' ');
      await send();
      draft('x' * 2001);
      await send();
      expect(adapter.submitted, isEmpty);
    },
  );
  test(
    'accepted reply clears only submitted draft and never edits review',
    () async {
      await ready();
      draft('Thank you');
      final original = controller.entries.single;
      await send();
      expect(controller.pending, isNull);
      expect(controller.draft(original.id, StoreFeedbackAction.reply), '');
      expect(identical(controller.entries.single, original), isTrue);
      expect(controller.entries.single.stars, 4);
      expect(controller.actionsReady, isFalse);
    },
  );
  test('new typing survives completion of older reply', () async {
    final result = Completer<StoreFeedbackResult>();
    adapter.write = (_) => result.future;
    await ready();
    draft('Old reply');
    final pending = send();
    draft('Newer reply');
    result.complete(
      StoreFeedbackResult(
        command: adapter.submitted.single,
        outcome: StoreFeedbackOutcome.accepted,
      ),
    );
    await pending;
    expect(
      controller.draft('central-review', StoreFeedbackAction.reply),
      'Newer reply',
    );
  });
  test(
    'unknown result blocks duplicate submit and reconciles same original command',
    () async {
      adapter.write = (_) async => throw TimeoutException('host fixture');
      await ready();
      draft('Original');
      await send();
      final original = controller.pending!;
      draft('Different typing');
      await send();
      expect(adapter.submitted, hasLength(1));
      await controller.load();
      final refreshed = controller.bindingFor('central-review')!;
      controller.setDraft(refreshed, StoreFeedbackAction.reply, 'Different typing');
      await controller.submit(refreshed, StoreFeedbackAction.reply,
        StoreFeedbackAudience.storeAndCustomer);
      expect(identical(controller.pending, original), isTrue);
      expect(adapter.submitted, hasLength(1));
      await controller.reconcile();
      expect(identical(adapter.reconciled.single, original), isTrue);
      expect(controller.pending, isNull);
      expect(
        controller.draft('central-review', StoreFeedbackAction.reply),
        'Different typing',
      );
    },
  );
  test('mismatched acknowledgement remains unknown not successful', () async {
    adapter.write = (c) async => StoreFeedbackResult(
      command: StoreFeedbackCommand(
        scope: c.scope,
        reviewId: c.reviewId,
        version: c.version,
        operationId: 'wrong',
        action: c.action,
        audience: c.audience,
        content: c.content,
      ),
      outcome: StoreFeedbackOutcome.accepted,
    );
    await ready();
    draft('Keep me');
    await send();
    expect(controller.pending, isNotNull);
    expect(controller.message, contains('not confirmed'));
    expect(
      controller.draft('central-review', StoreFeedbackAction.reply),
      'Keep me',
    );
  });
  test('definite rejection preserves text and requires fresh read', () async {
    adapter.write = (c) async =>
        StoreFeedbackResult(command: c, outcome: StoreFeedbackOutcome.rejected);
    await ready();
    draft('Keep me');
    await send();
    expect(controller.pending, isNull);
    expect(controller.actionsReady, isFalse);
    expect(
      controller.draft('central-review', StoreFeedbackAction.reply),
      'Keep me',
    );
  });
  test('scope change during submit cannot consume acknowledgement', () async {
    final result = Completer<StoreFeedbackResult>();
    adapter.write = (_) => result.future;
    await ready();
    draft('Original');
    final pending = send();
    current = null;
    result.complete(
      StoreFeedbackResult(
        command: adapter.submitted.single,
        outcome: StoreFeedbackOutcome.accepted,
      ),
    );
    await pending;
    expect(controller.pending, isNotNull);
    current = (scope, 2);
    await ready();
    await controller.reconcile();
    expect(controller.pending, isNull);
  });
  test('report only reaches moderation and never hides review', () async {
    await ready();
    draft('Reason', StoreFeedbackAction.report);
    await controller.submit(
      composer!,
      StoreFeedbackAction.report,
      StoreFeedbackAudience.public,
    );
    expect(adapter.submitted, isEmpty);
    await controller.submit(
      composer!,
      StoreFeedbackAction.report,
      StoreFeedbackAudience.moderation,
    );
    expect(adapter.submitted.single.audience, StoreFeedbackAudience.moderation);
    expect(controller.entries.single.id, 'central-review');
    expect(controller.message, contains('remains visible'));
  });
  test('order links reject changed context or stale review version', () async {
    await ready();
    final binding = controller.bindingFor('central-review')!;
    expect(controller.orderForReview(binding), 'this-store-suborder');
    expect(
      controller.orderForReview((
        context: binding.context,
        readEpoch: binding.readEpoch,
        reviewId: binding.reviewId,
        version: 'older',
      )),
      isNull,
    );
    current = (scope, 2);
    expect(controller.orderForReview(binding), isNull);
  });
  test(
    'LF27 regression reentrant load context change makes zero calls',
    () async {
      var reads = 0;
      adapter.read = (_) async {
        reads++;
        return page();
      };
      controller.addListener(() {
        if (controller.loading) current = null;
      });
      await controller.load();
      expect(reads, 0);
    },
  );
  test(
    'LF27 regression reentrant submit context change makes zero calls',
    () async {
      await ready();
      draft('Do not dispatch');
      controller.addListener(() {
        if (controller.commandInFlight) current = null;
      });
      await send();
      expect(adapter.submitted, isEmpty);
      expect(controller.pending, isNull);
      expect(controller.draft('central-review', StoreFeedbackAction.reply), 'Do not dispatch');
    },
  );
  test(
    'LF27 regression stale draft callback cannot write after epoch change',
    () async {
      await ready();
      final binding = controller.bindingFor('central-review')!;
      current = (scope, 2);
      controller.setDraft(binding, StoreFeedbackAction.reply, 'stale callback');
      expect(controller.draft('central-review', StoreFeedbackAction.reply), '');
    },
  );
  test(
    'LF27 regression old composer cannot send against refreshed review',
    () async {
      await ready();
      draft('Old-version reply');
      adapter.read = (_) async =>
          page(entries: [entry(version: 'new-version')]);
      await ready();
      await send();
      expect(adapter.submitted, isEmpty);
    },
  );
  testWidgets(
    'hung command times out as unknown and late acceptance cannot clear original hold',
    (tester) async {
      final result = Completer<StoreFeedbackResult>();
      adapter.write = (_) => result.future;
      await ready();
      draft('Keep original');
      final sending = send();
      await tester.pump(const Duration(seconds: 21));
      await sending;
      final original = controller.pending!;
      expect(controller.commandInFlight, isFalse);
      result.complete(
        StoreFeedbackResult(
          command: original,
          outcome: StoreFeedbackOutcome.accepted,
        ),
      );
      await tester.pump();
      expect(identical(controller.pending, original), isTrue);
      expect(controller.message, contains('not confirmed'));
    },
  );

  Future<void> mount(
    WidgetTester tester, {
    StoreFeedbackController? value,
    Size size = const Size(360, 720),
    double scale = 1,
    VoidCallback? close,
    ValueChanged<String>? open,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(scale),
          ),
          child: Scaffold(
            body: StoreCustomerFeedback(
              controller: value,
              onClose: close ?? () {},
              onOpenOrder: open,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final config in [
    (const Size(320, 640), 1.0),
    (const Size(320, 640), 2.0),
    (const Size(640, 320), 2.0),
  ]) {
    testWidgets(
      'unconnected feedback reachable at ${config.$1} scale ${config.$2}',
      (tester) async {
        var closed = false;
        await mount(
          tester,
          size: config.$1,
          scale: config.$2,
          close: () {
            closed = true;
          },
        );
        expect(
          find.text('Customer feedback is not connected yet.'),
          findsOneWidget,
        );
        expect(find.text('0 reviews'), findsNothing);
        for (final label in ['Overall order', 'Store service', 'Product']) {
          await tester.scrollUntilVisible(find.text(label), 150,
            scrollable: find.byType(Scrollable).first);
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text(label));
          await tester.pumpAndSettle();
          await tester.tap(find.text(label));
          await tester.pumpAndSettle();
        }
        await tester.scrollUntilVisible(
          find.byKey(const Key('work-feedback-back')),
          -200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('work-feedback-back')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-feedback-back')).hitTestable(),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('work-feedback-back')));
        expect(closed, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'three filters preserve central overall identity and Store-only order link',
    (tester) async {
      adapter.read = (_) async => page(
        entries: [
          entry(),
          entry(id: 'service', kind: StoreFeedbackKind.storeService),
          entry(id: 'product', kind: StoreFeedbackKind.product),
        ],
      );
      String? opened;
      await mount(
        tester,
        value: controller,
        open: (id) {
          opened = id;
        },
      );
      await tester.tap(find.text('Permitted customer label'));
      await tester.pumpAndSettle();
      expect(
        find.text('Mixed-Store order · Shared overall review'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('View this Store’s order'));
      await tester.tap(find.text('View this Store’s order'));
      expect(opened, 'this-store-suborder');
      await tester.tap(find.byKey(const Key('work-feedback-back')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Product'));
      await tester.pumpAndSettle();
      expect(find.text('Exact pack'), findsOneWidget);
      expect(
        find.text('Mixed-Store order · Overall order feedback'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'reply form shows permitted audience and preserves unknown request',
    (tester) async {
      adapter.write = (_) async => throw TimeoutException('host fixture');
      await mount(tester, value: controller);
      await tester.tap(find.text('Permitted customer label'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Reply'));
      await tester.tap(find.text('Reply'));
      await tester.pumpAndSettle();
      expect(find.text('Visible to: This Store and customer'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('work-feedback-text')),
        'Reply fixture',
      );
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('work-feedback-send')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('work-feedback-send')));
      await tester.pumpAndSettle();
      expect(controller.pending, isNotNull);
      expect(adapter.submitted, hasLength(1));
      await tester.scrollUntilVisible(
        find.byKey(const Key('work-feedback-send')),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('work-feedback-send')))
            .onPressed,
        isNull,
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('work-feedback-check-request')),
        -150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-feedback-check-request')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
