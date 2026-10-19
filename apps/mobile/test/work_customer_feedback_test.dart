// Isolated host adapter fixtures only. Never loaded into runtime Store data.
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:moolsocial/features/work/work_customer_feedback.dart';
import 'package:moolsocial/features/work/work_services.dart';
import 'package:moolsocial/features/work/work_session.dart';
import 'package:moolsocial/features/work/work_models.dart';
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

class StarsAdapter extends Adapter implements StoreStarsOnlyFeedbackAdapter {
  StarsAdapter() {commandRecoveryReady = false;}
}

class FeedbackStorage extends FlutterSecureStorage {
  final values = <String, String>{};
  bool failRead = false, failWrite = false, loseWriteResponse = false;
  Completer<void>? holdWrite;
  int writes = 0;
  @override
  Future<String?> read({required String key, AppleOptions? iOptions,
    AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions,
    AppleOptions? mOptions, WindowsOptions? wOptions}) async {
    if (failRead) throw StateError('Host read failure');
    return values[key];
  }
  @override
  Future<void> write({required String key, required String? value,
    AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions,
    WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async {
    writes++;
    await holdWrite?.future;
    if (failWrite) throw StateError('Host write failure');
    values[key] = value!;
    if (loseWriteResponse) {
      loseWriteResponse = false;
      throw StateError('Host native response lost after write');
    }
  }
}

class FeedbackAccount implements WorkPendingProofStore {
  @override
  String? get accountScope => scope.account;
  @override
  Future<Map<String, Object?>?> read(String scope) async => null;
  @override
  Future<void> save(String scope, Map<String, Object?> draft) async {}
  @override
  Future<void> clear(String scope) async {}
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

  test('LF-STARS failed legacy journal restore does not block private reads or permit any writes', () async {
    final storage = FeedbackStorage()..failRead = true;
    final stars = StarsAdapter(); var reads = 0;
    stars.read = (_) async {reads++; return page(entries: [StoreFeedbackEntry(storeId: scope.store,
      id: 'private-stars', version: '1', kind: StoreFeedbackKind.product, authorLabel: 'Customer',
      text: '', stars: 1, productId: 'exact-sku', productLabel: 'Actual pack')], coverage: StoreFeedbackCoverage.partial);};
    final value = StoreFeedbackController(scope: scope, context: () => current, adapter: stars,
      pendingStore: SecureStoreFeedbackPendingStore(storage: storage, currentAccount: () => scope.account));
    addTearDown(value.dispose);
    await value.load();
    expect(reads, 1); expect(value.entries.single.stars, 1);
    expect(value.recoveryReady, isFalse); expect(value.actionsReady, isFalse);
    expect(storage.writes, 0); expect(stars.submitted, isEmpty); expect(stars.reconciled, isEmpty);
    expect(value.message, contains('Saved requests'));
  });
  test('LF-STARS unavailable feed and failed old recovery preserve journal bytes without zero claim', () async {
    final storage = FeedbackStorage(), journal = SecureStoreFeedbackPendingStore(storage: storage, currentAccount: () => scope.account);
    const original = StoreFeedbackCommand(scope: scope, reviewId: 'old-comment', version: '1', operationId: 'original-report',
      action: StoreFeedbackAction.report, audience: StoreFeedbackAudience.moderation, content: 'Retained private draft');
    await journal.savePending(original); final before = Map<String, String>.of(storage.values), writes = storage.writes;
    storage.failRead = true;
    final stars = StarsAdapter()..read = (_) async => page(entries: [], coverage: StoreFeedbackCoverage.unavailable);
    final value = StoreFeedbackController(scope: scope, context: () => current, adapter: stars, pendingStore: journal);
    addTearDown(value.dispose); await value.load();
    expect(value.coverage, StoreFeedbackCoverage.unavailable); expect(value.recoveryReady, isFalse);
    expect(value.actionsReady, isFalse); expect(value.message, contains('Saved requests'));
    expect(storage.values, before); expect(storage.writes, writes);
    stars.commandRecoveryReady = true; var reads = 0; stars.read = (_) async {reads++; return page();};
    await value.load(); expect(reads, 0); expect(storage.values, before);
  });

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

  test('LF feedback restart retains the original uncertain request', () async {
    final storage = FeedbackStorage();
    SecureStoreFeedbackPendingStore journal() => SecureStoreFeedbackPendingStore(
      storage: storage, currentAccount: () => scope.account);
    controller.dispose();
    controller = StoreFeedbackController(scope: scope, context: () => current,
      adapter: adapter, pendingStore: journal());
    adapter.write = (_) async => throw TimeoutException('host lost response');
    await ready();
    draft('Keep this original reply');
    await send();
    final original = controller.pending!;
    final restarted = StoreFeedbackController(
      scope: scope, context: () => current, adapter: adapter, pendingStore: journal());
    addTearDown(restarted.dispose);
    await restarted.load();
    expect(restarted.pending, isNotNull);
    expect(StoreFeedbackResult(command: restarted.pending!,
      outcome: StoreFeedbackOutcome.unknown).matches(original), isTrue);
    expect(adapter.submitted, hasLength(1));
    adapter.read = (_) async => page(entries: [], coverage: StoreFeedbackCoverage.partial);
    await restarted.load();
    expect(restarted.pending!.operationId, original.operationId);
    await restarted.reconcile();
    expect(adapter.reconciled.single.operationId, original.operationId);
    expect(restarted.pending, isNull);
    expect(await journal().readPending(scope), isNull);
  });

  group('LF feedback durable intent', () {
    late FeedbackStorage storage;
    String? signedIn;
    SecureStoreFeedbackPendingStore journal() => SecureStoreFeedbackPendingStore(
      storage: storage, currentAccount: () => signedIn);
    StoreFeedbackController make() {
      final value = StoreFeedbackController(scope: scope, context: () => current,
        adapter: adapter, pendingStore: journal());
      addTearDown(value.dispose);
      return value;
    }
    Future<void> reply(StoreFeedbackController value) async {
      final binding = value.bindingFor('central-review')!;
      value.setDraft(binding, StoreFeedbackAction.reply, 'Original persisted content');
      await value.submit(binding, StoreFeedbackAction.reply,
        StoreFeedbackAudience.storeAndCustomer);
    }
    StoreFeedbackCommand command(String id, {StoreFeedbackScope owner = scope,
      StoreFeedbackAction action = StoreFeedbackAction.reply,
      StoreFeedbackAudience audience = StoreFeedbackAudience.storeAndCustomer}) =>
        StoreFeedbackCommand(scope: owner, reviewId: 'central-review', version: 'opaque-v1',
          operationId: id, action: action, audience: audience, content: 'Original persisted content');
    Future<void> waitForWrite(int count) async {
      while (storage.writes < count) { await Future<void>.delayed(Duration.zero); }
    }
    setUp(() { storage = FeedbackStorage(); signedIn = scope.account; });

    test('failed restoration blocks dispatch and refresh retries safely', () async {
      storage.failRead = true;
      final value = make();
      await value.load();
      expect(value.recoveryReady, isFalse);
      expect(value.actionsReady, isFalse);
      expect(value.message, contains('restore'));
      expect(adapter.submitted, isEmpty);
      storage.failRead = false;
      await value.load();
      expect(value.actionsReady, isTrue);
    });
    test('failed journal save never dispatches or erases the typed text', () async {
      final value = make(); await value.load(); storage.failWrite = true;
      await reply(value);
      expect(adapter.submitted, isEmpty);
      expect(value.recoveryReady, isFalse);
      expect(value.draft('central-review', StoreFeedbackAction.reply), 'Original persisted content');
      expect(value.message, contains('not sent'));
      storage.failWrite = false; await value.load();
      expect(value.pending, isNull);
      expect(value.actionsReady, isTrue);
    });
    test('lost native save response restores exact intent without resubmission', () async {
      final value = make(); await value.load(); storage.loseWriteResponse = true;
      await reply(value);
      expect(adapter.submitted, isEmpty);
      final original = value.pending!;
      await value.load();
      expect(value.pending!.operationId, original.operationId);
      expect(value.actionsReady, isFalse);
      await value.reconcile();
      expect(adapter.reconciled.single.toJson(), original.toJson());
      expect(value.pending, isNull);
    });
    test('matched acceptance cannot clear hold before durable removal succeeds', () async {
      adapter.write = (c) async {
        storage.failWrite = true;
        return StoreFeedbackResult(command: c, outcome: StoreFeedbackOutcome.accepted);
      };
      final value = make(); await value.load(); await reply(value);
      final original = value.pending!;
      expect(value.message, contains('original request again'));
      expect((await journal().readPending(scope))!.operationId, original.operationId);
      storage.failWrite = false;
      await value.reconcile();
      expect(value.pending, isNull);
      expect(await journal().readPending(scope), isNull);
    });
    test('unavailable provider readiness is not supplied by a local journal', () async {
      adapter.commandRecoveryReady = false;
      final original = command('prior-operation'); await journal().savePending(original);
      final value = make(); await value.load();
      expect(value.pending!.toJson(), original.toJson());
      expect(value.canAct('central-review', StoreFeedbackAction.reply), isFalse);
      await value.reconcile();
      expect(adapter.reconciled, isEmpty);
      expect(value.pending, isNotNull);
    });
    test('provider readiness revoked during persistence prevents dispatch', () async {
      final value = make(); await value.load();
      storage.holdWrite = Completer<void>();
      final sending = reply(value); await waitForWrite(1);
      adapter.commandRecoveryReady = false;
      storage.holdWrite!.complete(); await sending;
      expect(adapter.submitted, isEmpty);
      expect((await journal().readPending(scope))!.operationId, value.pending!.operationId);
    });
    test('listener revoking readiness blocks reconciliation too', () async {
      await journal().savePending(command('original'));
      final value = make(); await value.load();
      value.addListener(() { if (value.commandInFlight) adapter.commandRecoveryReady = false; });
      await value.reconcile();
      expect(adapter.reconciled, isEmpty);
      expect(value.pending, isNotNull);
    });
    test('retired writer and replacement restore share the native queue', () async {
      final value = make(); await value.load();
      storage.holdWrite = Completer<void>();
      final sending = reply(value); await waitForWrite(1);
      current = null;
      current = (scope, 2);
      final replacement = make();
      var restored = false;
      final restoring = replacement.load().then((_) => restored = true);
      await Future<void>.delayed(Duration.zero);
      expect(restored, isFalse);
      final original = value.pending!;
      storage.holdWrite!.complete();
      await sending; await restoring;
      expect(adapter.submitted, isEmpty);
      expect(replacement.pending!.toJson(), original.toJson());
      expect(replacement.actionsReady, isFalse);
    });
    test('retired removal completes before a replacement reads the journal', () async {
      final value = make(); await value.load();
      adapter.write = (c) async {
        storage.holdWrite = Completer<void>();
        return StoreFeedbackResult(command: c, outcome: StoreFeedbackOutcome.accepted);
      };
      final sending = reply(value); await waitForWrite(2);
      current = (scope, 2);
      final replacement = make();
      final restoring = replacement.load();
      await Future<void>.delayed(Duration.zero);
      expect(replacement.recoveryReady, isFalse);
      storage.holdWrite!.complete();
      await sending; await restoring;
      expect(value.pending, isNotNull); // retired lifetime cannot consume the ack
      expect(replacement.pending, isNull); // exact confirmed removal completed
      expect(adapter.submitted, hasLength(1));
    });
    test('late original removal cannot erase a newer request', () async {
      final first = command('first'), next = command('next');
      await journal().savePending(first);
      storage.holdWrite = Completer<void>();
      final removing = journal().removePending(first); await waitForWrite(2);
      final writing = journal().savePending(next);
      storage.holdWrite!.complete();
      await removing; await writing;
      await expectLater(journal().removePending(first), throwsFormatException);
      expect((await journal().readPending(scope))!.toJson(), next.toJson());
    });
    test('cross-account access and a copied cross-Store envelope are rejected', () async {
      await journal().savePending(command('original'));
      signedIn = 'another-account';
      await expectLater(journal().readPending(scope), throwsA(isA<WorkGatewayException>()));
      signedIn = scope.account;
      const other = (account: 'host-account', store: 'other-store');
      await journal().savePending(command('other', owner: other));
      final keys = storage.values.keys.toList();
      storage.values[keys.last] = storage.values[keys.first]!;
      await expectLater(journal().readPending(other), throwsFormatException);
    });
    test('malformed journals remain errors, not empty successful restoration', () async {
      await journal().savePending(command('original'));
      final key = storage.values.keys.single;
      final correct = storage.values[key]!;
      for (final mutation in <Object?>['not-json', [], {'version': 1},
        {...jsonDecode(correct) as Map, 'command': {'action': 'reply'}},
        {...jsonDecode(correct) as Map, 'command': {...command('bad').toJson(), 'action': 'report'}},
      ]) {
        storage.values[key] = mutation is String ? mutation : jsonEncode(mutation);
        final value = make(); await value.load();
        expect(value.recoveryReady, isFalse);
        expect(value.actionsReady, isFalse);
        expect(adapter.submitted, isEmpty);
      }
    });
    test('Store session supplies scoped journal and retains original pending', () async {
      final original = command('pending-report', action: StoreFeedbackAction.report,
        audience: StoreFeedbackAudience.moderation);
      await journal().savePending(original);
      final seen = <StoreFeedbackScope>[];
      final work = WorkSession(contactDraftStore: FeedbackAccount(), customerFeedbackAdapter: adapter,
        customerFeedbackPendingStoreFactory: (s) { seen.add(s); return journal(); })
        ..activeWorkspace = const WorkWorkspace(id: 'host-store', name: 'Store',
          profileLabel: 'Grocery', profileId: 'retailer-grocery', area: 'Jaipur', verified: true)
        ..workspaceId = 'host-store';
      addTearDown(work.dispose);
      final value = work.workspaceCustomerFeedback!;
      expect(value.pendingStore, isA<SecureStoreFeedbackPendingStore>());
      expect(value.recoveryReady, isFalse);
      await value.load();
      expect(value.pending!.toJson(), original.toJson());
      expect(seen, [scope]);
      expect(adapter.submitted, isEmpty);
    });
    testWidgets('timed-out native save cannot dispatch late or bypass restore', (tester) async {
      final value = make(); await value.load();
      storage.holdWrite = Completer<void>();
      final sending = reply(value); await tester.pump();
      expect(storage.writes, 1);
      await tester.pump(const Duration(seconds: 21)); await sending;
      expect(value.recoveryReady, isFalse);
      expect(adapter.submitted, isEmpty);
      final original = value.pending!;
      final restoring = value.load(); await tester.pump();
      expect(value.recoveryReady, isFalse);
      storage.holdWrite!.complete(); await tester.pump(); await restoring;
      expect(value.pending!.toJson(), original.toJson());
      expect(adapter.submitted, isEmpty);
    });
    testWidgets('late native removal never manufactures a confirmed UI outcome', (tester) async {
      final value = make(); await value.load();
      adapter.write = (c) async {
        storage.holdWrite = Completer<void>();
        return StoreFeedbackResult(command: c, outcome: StoreFeedbackOutcome.accepted);
      };
      final sending = reply(value); await tester.pump();
      expect(storage.writes, 2);
      await tester.pump(const Duration(seconds: 21)); await sending;
      final original = value.pending!;
      expect(value.message, isNot(contains('Reply confirmed')));
      storage.holdWrite!.complete(); await tester.pump();
      expect(value.pending!.operationId, original.operationId);
      await value.reconcile();
      expect(adapter.reconciled.single.toJson(), original.toJson());
      expect(value.pending, isNull);
      expect(adapter.submitted, hasLength(1));
    });
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

  for (final scale in [1.0, 2.0]) {
    testWidgets('LF-STARS private inbox shows one-star product without legacy tabs or empty text scale=$scale', (tester) async {
      final stars = StarsAdapter()..read = (_) async => page(entries: [StoreFeedbackEntry(
        storeId: scope.store, id: 'private-stars', version: '1', kind: StoreFeedbackKind.product,
        authorLabel: 'Customer', text: '', stars: 1, orderId: 'this-store-suborder', productId: 'exact-sku', productLabel: 'Actual pack')],
        coverage: StoreFeedbackCoverage.partial);
      final value = StoreFeedbackController(scope: scope, context: () => current, adapter: stars);
      addTearDown(value.dispose);
      await mount(tester, value: value, size: const Size(320, 640), scale: scale);
      expect(find.textContaining('Only your Store'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('1 / 5 stars'), 120);
      expect(find.text('1 / 5 stars'), findsOneWidget); expect(find.text('Actual pack'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.text(''), findsNothing);
      await tester.ensureVisible(find.text('Actual pack')); await tester.tap(find.text('Actual pack')); await tester.pumpAndSettle();
      expect(find.text('1 / 5 stars'), findsOneWidget); expect(find.text('Reply'), findsNothing); expect(find.text('Report'), findsNothing);
      expect(find.text('Replies and reports are not available yet.'), findsNothing);
      expect(stars.submitted, isEmpty); expect(tester.takeException(), isNull);
    });
  }

  testWidgets('restored request is reachable with an empty feed at larger text', (tester) async {
    final storage = FeedbackStorage();
    final journal = SecureStoreFeedbackPendingStore(storage: storage, currentAccount: () => scope.account);
    const original = StoreFeedbackCommand(scope: scope, reviewId: 'not-in-feed',
      version: 'original-version', operationId: 'original-operation', action: StoreFeedbackAction.report,
      audience: StoreFeedbackAudience.moderation, content: 'Original private report');
    await journal.savePending(original);
    adapter.read = (_) async => page(entries: [], coverage: StoreFeedbackCoverage.partial);
    final value = StoreFeedbackController(scope: scope, context: () => current,
      adapter: adapter, pendingStore: journal);
    addTearDown(value.dispose);
    await mount(tester, value: value, size: const Size(320, 640), scale: 2);
    final check = find.byKey(const Key('work-feedback-check-request'));
    await tester.ensureVisible(check); await tester.pumpAndSettle();
    expect(check.hitTestable(), findsOneWidget);
    expect(value.entries, isEmpty);
    expect(adapter.submitted, isEmpty);
    await tester.tap(check); await tester.pumpAndSettle();
    expect(adapter.reconciled.single.toJson(), original.toJson());
    expect(value.pending, isNull);
    expect(tester.takeException(), isNull);
  });

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
