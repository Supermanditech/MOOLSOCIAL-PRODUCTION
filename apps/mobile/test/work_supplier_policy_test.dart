import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:moolsocial/features/work/work_supplier_policy.dart';
import 'package:moolsocial/features/work/work_services.dart';
import 'package:moolsocial/features/work/work_session.dart';
import 'package:moolsocial/features/work/work_models.dart';
import 'package:moolsocial/features/work/widgets/store_payment_terms.dart';
import 'package:moolsocial/features/shared/social_content_gateway.dart';
import 'work_catalogue_gateway_test.dart' as catalogue;

// Isolated host facts/journals only; no device policy, consent or live provider.
const scope = (account: 'owner-one', store: 'store-one', realm: 'evaluation');
// WorkSession uses the real clock; anchor its valid host draft to this run.
// Explicit expiry/stale-response tests still inject their own clock below.
final at = DateTime.fromMillisecondsSinceEpoch(
  DateTime.now().millisecondsSinceEpoch,
  isUtc: true,
);
StorePolicyDraft draft([String body = 'Host supplier terms']) =>
    StorePolicyDraft(
      title: 'Host terms',
      body: body,
      productIds: {'sku-one'},
      requiresAcceptance: true,
      validUntil: at.add(const Duration(days: 1)),
    );
Map<String, dynamic> recordJson(
  StorePolicyDraft value, {
  int revision = 1,
  StorePolicyScope owner = scope,
}) => {
  ...value.toJson(),
  'schemaVersion': 1,
  'realm': owner.realm,
  'storeId': owner.store,
  'id': 'host-policy-record',
  'revision': revision,
  'publishedAt': at.toIso8601String(),
};
StorePolicyRecord record(
  StorePolicyDraft value, {
  int revision = 1,
  StorePolicyScope owner = scope,
}) => StorePolicyRecord.decode(
  recordJson(value, revision: revision, owner: owner),
  owner,
  at,
);
StorePolicyIntent intent([StorePolicyDraft? value]) => StorePolicyIntent(
  scope: scope,
  expectedRevision: 0,
  idempotencyKey: 'host-policy-original',
  draft: value ?? draft(),
);
StorePolicyResult saved(StorePolicyIntent original) => StorePolicyResult(
  StorePolicyResultState.saved,
  record: record(
    original.draft,
    revision: original.expectedRevision + 1,
    owner: original.scope,
  ),
);

class Journal implements StorePolicyJournal {
  StorePolicyDraft? draft;
  StorePolicyIntent? pending;
  bool failRead = false, failSave = false, failClear = false;
  @override
  Future<StorePolicyRecovery> read(StorePolicyScope scope) async {
    if (failRead) throw StateError('isolated storage failure');
    return StorePolicyRecovery(draft: draft, pending: pending);
  }

  @override
  Future<void> saveDraft(StorePolicyScope scope, StorePolicyDraft value) async {
    draft = value;
  }

  @override
  Future<void> savePending(StorePolicyIntent original) async {
    if (failSave) throw StateError('isolated pending write failure');
    if (pending != null && pending!.fingerprint != original.fingerprint) {
      throw StateError('different original');
    }
    pending = original;
  }

  @override
  Future<void> clearPending(StorePolicyIntent original) async {
    if (failClear) throw StateError('isolated clear failure');
    expect(pending?.fingerprint, original.fingerprint);
    pending = null;
  }
}

class Gateway implements StorePolicyGateway {
  int writes = 0, checks = 0, reads = 0;
  Future<StorePolicyRecord?> Function() reading = () async => null;
  Future<StorePolicyResult> Function(StorePolicyIntent, bool Function())
  writing = (original, current) async => saved(original);
  Future<StorePolicyResult> Function(StorePolicyIntent) checking = (_) async =>
      const StorePolicyResult(StorePolicyResultState.unknown);
  @override
  Future<StorePolicyRecord?> read(
    StorePolicyScope scope,
    bool Function() current,
  ) {
    reads++;
    return reading();
  }

  @override
  Future<StorePolicyResult> publish(
    StorePolicyIntent original,
    bool Function() current,
  ) {
    writes++;
    return writing(original, current);
  }

  @override
  Future<StorePolicyResult> reconcile(
    StorePolicyIntent original,
    bool Function() current,
  ) {
    checks++;
    return checking(original);
  }
}

class Credentials implements SocialContentCredentials {
  int tokenCalls = 0;
  final modes = <SocialAppCheckTokenMode>[];
  Future<void> Function()? beforeAppCheck;
  @override
  Future<String> firebaseIdToken() async {
    tokenCalls++;
    return 'host-token';
  }

  @override
  Future<String> appCheckToken(SocialAppCheckTokenMode mode) async {
    modes.add(mode);
    await beforeAppCheck?.call();
    return 'host-app-check';
  }
}

class Wire implements SocialContentTransport {
  final sent = <Map<String, Object?>>[];
  Future<SocialContentResponse> Function(Map<String, Object?>) reply =
      (_) async => throw StateError('host offline');
  @override
  Future<SocialContentResponse> postJson(
    Uri endpoint, {
    required Map<String, String> headers,
    required Map<String, Object?> body,
  }) {
    sent.add(jsonDecode(jsonEncode(body)) as Map<String, dynamic>);
    return reply(body);
  }
}

SocialContentResponse response(Object? value) => SocialContentResponse(
  statusCode: 200,
  body: jsonEncode({
    'ok': true,
    'data': {
      'schemaVersion': 1,
      'realm': scope.realm,
      'storeId': scope.store,
      'record': value,
      'publicAvailabilityConfirmed': false,
    },
  }),
);
AuthenticatedStorePolicyGateway client(
  Wire wire,
  Credentials credentials, {
  DateTime Function()? now,
}) => AuthenticatedStorePolicyGateway(
  endpoint: Uri.parse(
    'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace',
  ),
  credentials: credentials,
  transport: wire,
  ownerAccountId: scope.account,
  realm: scope.realm,
  now: now ?? () => at,
);
StorePolicyController controller(
  Journal journal,
  Gateway gateway, {
  Object? Function()? context,
  Future<bool> Function(StorePolicyDraft, bool Function())? validate,
  DateTime Function()? now,
}) => StorePolicyController(
  scope: scope,
  journal: journal,
  gateway: gateway,
  context: context ?? () => 'owner-visit',
  validateSelection: validate ?? (_, _) async => true,
  now: now ?? () => at,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WorkSession ownerWork(Journal journal, Gateway gateway, catalogue.SessionCatalogue source) => WorkSession(
    contactDraftStore: catalogue.ListingAccount(), catalogueGateway: source,
    supplierPolicyGateway: gateway, supplierPolicyRealm: 'production', supplierPolicyJournalFactory: (_) => journal)
    ..activeWorkspace = const WorkWorkspace(id: 'store-one', name: 'Host Store', profileLabel: 'Grocery', profileId: 'retailer-grocery', area: 'Jaipur', verified: true)
    ..workspaceId = 'store-one'
    ..workspaceCatalogueItems.add(catalogue.listingItem());
  test('secure journal keeps newer draft, exact original, realm and account across recreation', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final first = SecureStorePolicyJournal(currentAccount: () => scope.account), original = intent();
    await first.saveDraft(scope, draft()); await first.savePending(original);
    final restarted = SecureStorePolicyJournal(currentAccount: () => scope.account);
    await restarted.saveDraft(scope, draft('Newer private draft'));
    expect((await restarted.read(scope)).pending?.fingerprint, original.fingerprint);
    expect((await restarted.read(scope)).draft?.body, 'Newer private draft');
    final different = StorePolicyIntent(scope: scope, expectedRevision: 0, idempotencyKey: 'another-original', draft: draft());
    await expectLater(restarted.savePending(different), throwsFormatException);
    await expectLater(restarted.clearPending(different), throwsFormatException);
    expect((await restarted.read(scope)).pending?.fingerprint, original.fingerprint);
    await restarted.clearPending(original);
    expect((await restarted.read(scope)).pending, isNull);
    expect((await restarted.read(scope)).draft?.body, 'Newer private draft');
    final otherRealm = (account: scope.account, store: scope.store, realm: 'production');
    expect((await restarted.read(otherRealm)).draft, isNull);
    await expectLater(SecureStorePolicyJournal(currentAccount: () => 'other-owner').read(scope), throwsA(isA<WorkGatewayException>()));
  });
  test('WorkSession publishes only exact bound SKU set and retains one Stock record', () async {
    final journal = Journal(), gateway = Gateway(), source = catalogue.SessionCatalogue();
    final work = ownerWork(journal, gateway, source); addTearDown(work.dispose);
    final before = jsonEncode(work.workspaceCatalogueItems.single.toInventoryJson());
    final state = work.workspaceSupplierPolicy!; expect(await state.refresh(), true);
    expect((await work.publishWorkspaceSupplierPolicy(draft())).state, StorePolicyResultState.saved);
    expect(gateway.writes, 1); expect(source.ownerReads, 1);
    expect(jsonEncode(work.workspaceCatalogueItems.single.toInventoryJson()), before);
    expect(work.workspaceOrders, isEmpty); expect(work.workspaceInvoices, isEmpty);
  });
  test('WorkSession refuses missing or mismatched bindings without dropping selected IDs', () async {
    final journal = Journal(), gateway = Gateway(), source = catalogue.SessionCatalogue()..ownerRead = () async => null;
    final work = ownerWork(journal, gateway, source); addTearDown(work.dispose);
    await work.workspaceSupplierPolicy!.refresh();
    expect((await work.publishWorkspaceSupplierPolicy(draft())).state, StorePolicyResultState.notSent);
    expect(journal.draft?.productIds, {'sku-one'}); expect(gateway.writes, 0);
  });
  test('WorkSession replaces retired policy controllers on Store A-B-A, preserving journal', () async {
    final journal = Journal(), gateway = Gateway(), work = ownerWork(journal, gateway, catalogue.SessionCatalogue()); addTearDown(work.dispose);
    final original = work.workspaceSupplierPolicy!; await original.refresh();
    final a = work.activeWorkspace;
    work.activeWorkspace = const WorkWorkspace(id: 'store-two', name: 'Other Store', profileLabel: 'Grocery', profileId: 'retailer-grocery', area: 'Jaipur', verified: true);
    work.activeWorkspace = a;
    final replacement = work.workspaceSupplierPolicy!;
    expect(identical(original, replacement), false);
    expect(await original.saveDraft(draft()), false);
    expect(await replacement.saveDraft(draft()), true);
    expect(journal.draft?.fingerprint, draft().fingerprint); expect(gateway.writes, 0);
  });
  for (final scale in [1.0, 2.0]) {
    testWidgets('compact policy editor saves private draft without publication at 320px text$scale', (tester) async {
      tester.view.devicePixelRatio = 1; tester.view.physicalSize = const Size(320, 650);
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.reset); addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final journal = Journal()..draft = draft(), gateway = Gateway();
      final work = ownerWork(journal, gateway, catalogue.SessionCatalogue()); addTearDown(work.dispose);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: Padding(
        padding: const EdgeInsets.all(12), child: StoreSupplierPolicyPanel(session: work))))));
      await tester.pumpAndSettle(); await tester.tap(find.text('Customer-facing policy')); await tester.pumpAndSettle();
      final body = find.byKey(const Key('work-supplier-policy-body'));
      await tester.ensureVisible(body); await tester.enterText(body, 'Edited private terms');
      FocusManager.instance.primaryFocus?.unfocus(); await tester.pumpAndSettle();
      final save = find.widgetWithText(OutlinedButton, 'Save private draft');
      await tester.ensureVisible(save); await tester.pumpAndSettle();
      expect(save.hitTestable(), findsOneWidget);
      await tester.tap(save); await tester.pumpAndSettle();
      expect(journal.draft?.body, 'Edited private terms'); expect(gateway.writes, 0);
      expect(find.textContaining('Not published.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('explicit Publish policy button uses bound products and leaves private defaults untouched', (tester) async {
    final journal = Journal()..draft = draft(), gateway = Gateway();
    final work = ownerWork(journal, gateway, catalogue.SessionCatalogue()); addTearDown(work.dispose);
    final preferences = jsonEncode(work.workspacePublicationDetails.toJson());
    final stock = jsonEncode(work.workspaceCatalogueItems.single.toInventoryJson());
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: StoreSupplierPolicyPanel(session: work)))));
    await tester.pumpAndSettle(); await tester.tap(find.text('Customer-facing policy')); await tester.pumpAndSettle();
    expect(gateway.writes, 0);
    final publish = find.widgetWithText(FilledButton, 'Publish policy');
    await tester.ensureVisible(publish); await tester.pumpAndSettle(); expect(publish.hitTestable(), findsOneWidget);
    await tester.tap(publish); await tester.pumpAndSettle();
    expect(gateway.writes, 1); expect(journal.pending, isNull);
    expect(tester.widget<FilledButton>(publish).onPressed, isNull);
    expect(find.textContaining('Policy update recorded.'), findsOneWidget);
    expect(jsonEncode(work.workspacePublicationDetails.toJson()), preferences);
    expect(jsonEncode(work.workspaceCatalogueItems.single.toInventoryJson()), stock);
    expect(work.workspaceOrders, isEmpty); expect(work.workspaceInvoices, isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets('failed editor restoration stays locked and retry hydrates original draft once', (tester) async {
    final journal = Journal()..draft = draft('Original unread draft')..failRead = true;
    final work = ownerWork(journal, Gateway(), catalogue.SessionCatalogue()); addTearDown(work.dispose);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: StoreSupplierPolicyPanel(session: work)))));
    await tester.pumpAndSettle(); await tester.tap(find.text('Customer-facing policy')); await tester.pumpAndSettle();
    final field = find.byKey(const Key('work-supplier-policy-body'));
    expect(tester.widget<TextField>(field).enabled, false);
    expect(tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Save private draft')).onPressed, isNull);
    journal.failRead = false;
    final refresh = find.widgetWithText(TextButton, 'Refresh current policy');
    await tester.ensureVisible(refresh); await tester.pumpAndSettle(); await tester.tap(refresh); await tester.pumpAndSettle();
    expect(tester.widget<TextField>(field).controller!.text, 'Original unread draft');
    await tester.ensureVisible(field); await tester.enterText(field, 'Unsaved new edit');
    FocusManager.instance.primaryFocus?.unfocus(); await tester.pumpAndSettle();
    await tester.ensureVisible(refresh); await tester.pumpAndSettle(); await tester.tap(refresh); await tester.pumpAndSettle();
    expect(tester.widget<TextField>(field).controller!.text, 'Unsaved new edit');
    expect(journal.draft?.body, 'Original unread draft');
  });
  testWidgets('open product picker hides old Store details as soon as scope retires', (tester) async {
    final journal = Journal()..draft = draft();
    final work = ownerWork(journal, Gateway(), catalogue.SessionCatalogue()); addTearDown(work.dispose);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: StoreSupplierPolicyPanel(session: work)))));
    await tester.pumpAndSettle(); await tester.tap(find.text('Customer-facing policy')); await tester.pumpAndSettle();
    final choose = find.text('Choose products · 1 selected');
    await tester.ensureVisible(choose); await tester.pumpAndSettle(); await tester.tap(choose); await tester.pumpAndSettle();
    expect(find.text(catalogue.product.title), findsOneWidget);
    work.activeWorkspace = const WorkWorkspace(id: 'store-two', name: 'Other Store', profileLabel: 'Grocery', profileId: 'retailer-grocery', area: 'Jaipur', verified: true);
    work.showNotice('Host Store changed'); await tester.pumpAndSettle();
    expect(find.text(catalogue.product.title), findsNothing);
    expect(find.text('Use selection'), findsNothing);
    expect(journal.draft?.productIds, {'sku-one'});
  });
  test(
    'draft and original codecs retain all fields without exposing mutable payload',
    () {
      final original = intent(), encoded = original.toJson();
      (encoded['policy'] as Map)['body'] = 'Mutated caller';
      expect(original.draft.body, 'Host supplier terms');
      final restored = StorePolicyIntent.fromJson(original.toJson());
      expect(restored.fingerprint, original.fingerprint);
      expect(original.body.containsKey('accountId'), false);
      expect(original.body.containsKey('realm'), false);
      expect(draft().validUntil, at.add(const Duration(days: 1)));
    },
  );
  test(
    'initial read failure does not become revision zero or permit publish',
    () async {
      final journal = Journal(),
          gateway = Gateway()
            ..reading = () async => throw StateError('host unavailable');
      final state = controller(journal, gateway);
      addTearDown(state.dispose);
      expect(await state.refresh(), false);
      expect(
        (await state.publish(draft())).state,
        StorePolicyResultState.notSent,
      );
      expect(gateway.writes, 0);
      expect(await state.saveDraft(draft()), true);
      expect(journal.draft?.body, 'Host supplier terms');
    },
  );
  test(
    'restore failure blocks publication without clearing saved original',
    () async {
      final journal = Journal()
            ..pending = intent()
            ..failRead = true,
          gateway = Gateway();
      final state = controller(journal, gateway);
      addTearDown(state.dispose);
      expect(await state.refresh(), false);
      expect(
        (await state.publish(draft())).state,
        StorePolicyResultState.notSent,
      );
      expect(journal.pending, isNotNull);
      expect(gateway.writes, 0);
    },
  );
  test(
    'explicit publish persists original before send and never claims current online policy',
    () async {
      final journal = Journal(), gateway = Gateway();
      final state = controller(journal, gateway);
      addTearDown(state.dispose);
      gateway.writing = (original, current) async {
        expect(current(), true);
        expect(journal.pending?.fingerprint, original.fingerprint);
        expect(journal.draft?.fingerprint, original.draft.fingerprint);
        return saved(original);
      };
      expect(await state.refresh(), true);
      expect(
        (await state.publish(draft())).state,
        StorePolicyResultState.saved,
      );
      expect(gateway.writes, 1);
      expect(journal.pending, isNull);
      expect(state.currentLoaded, false);
      expect(state.published, isNull);
      expect(state.lastAcknowledged?.revision, 1);
    },
  );
  test(
    'unknown save restores then checks exact original, preserving newer private draft',
    () async {
      final journal = Journal(), gateway = Gateway();
      gateway.writing = (_, _) async =>
          const StorePolicyResult(StorePolicyResultState.unknown);
      final first = controller(journal, gateway);
      await first.refresh();
      await first.publish(draft());
      final original = journal.pending!;
      first.dispose();
      final restored = controller(journal, gateway);
      addTearDown(restored.dispose);
      expect(await restored.refresh(), false);
      expect(gateway.reads, 1);
      expect(gateway.writes, 1);
      await restored.saveDraft(draft('Newer private draft'));
      expect(
        (await restored.publish(draft())).state,
        StorePolicyResultState.notSent,
      );
      gateway.checking = (checked) async {
        expect(checked.fingerprint, original.fingerprint);
        return saved(checked);
      };
      expect((await restored.reconcile()).state, StorePolicyResultState.saved);
      expect(restored.draft?.body, 'Newer private draft');
      expect(journal.draft?.body, 'Newer private draft');
      expect(restored.published, isNull);
      expect(gateway.writes, 1);
      gateway.reading = () async => record(draft('Current v3'), revision: 3);
      expect(await restored.refresh(), true);
      expect(restored.published?.revision, 3);
      expect(restored.draft?.body, 'Newer private draft');
    },
  );
  test(
    'missing or denied original remains unknown; retained Check with no pending cannot publish',
    () async {
      final journal = Journal()..pending = intent(), gateway = Gateway();
      final state = controller(journal, gateway);
      addTearDown(state.dispose);
      await state.restore();
      expect((await state.reconcile()).state, StorePolicyResultState.unknown);
      expect(journal.pending, isNotNull);
      expect(gateway.writes, 0);
      gateway.checking = (original) async => saved(original);
      await state.reconcile();
      await state.reconcile();
      expect(gateway.writes, 0);
      expect(gateway.checks, 2);
    },
  );
  test(
    'CAS rejection preserves draft and requires refresh, never automatic rebase',
    () async {
      final journal = Journal(), gateway = Gateway();
      gateway.writing = (_, _) async =>
          const StorePolicyResult(StorePolicyResultState.rejected);
      final state = controller(journal, gateway);
      addTearDown(state.dispose);
      await state.refresh();
      expect(
        (await state.publish(draft())).state,
        StorePolicyResultState.rejected,
      );
      expect(journal.pending, isNull);
      expect(state.draft?.fingerprint, draft().fingerprint);
      expect(
        (await state.publish(draft())).state,
        StorePolicyResultState.notSent,
      );
      expect(gateway.writes, 1);
    },
  );
  test(
    'unbound selection is retained whole and cannot reach publication',
    () async {
      final journal = Journal(), gateway = Gateway();
      final state = controller(
        journal,
        gateway,
        validate: (_, _) async => false,
      );
      addTearDown(state.dispose);
      await state.refresh();
      expect(
        (await state.publish(draft())).state,
        StorePolicyResultState.notSent,
      );
      expect(journal.draft?.productIds, {'sku-one'});
      expect(gateway.writes, 0);
      expect(journal.pending, isNull);
    },
  );
  test(
    'A-B-A visit and duplicate action cannot dispatch a stale policy',
    () async {
      var visit = 'visit-one';
      final entered = Completer<void>(), release = Completer<void>();
      final journal = Journal(), gateway = Gateway();
      final state = controller(
        journal,
        gateway,
        context: () => visit,
        validate: (_, current) async {
          entered.complete();
          await release.future;
          return current();
        },
      );
      addTearDown(state.dispose);
      await state.refresh();
      final saving = state.publish(draft());
      await entered.future;
      expect(
        (await state.publish(draft())).state,
        StorePolicyResultState.notSent,
      );
      visit = 'visit-two';
      visit = 'visit-three';
      release.complete();
      expect((await saving).state, StorePolicyResultState.notSent);
      expect(gateway.writes, 0);
    },
  );
  test(
    'retained controller cannot start an operation after its original visit retires',
    () async {
      var visit = 'visit-one';
      final journal = Journal(), gateway = Gateway();
      final state = controller(journal, gateway, context: () => visit);
      addTearDown(state.dispose);
      await state.refresh();
      visit = 'replacement-visit';
      expect(await state.restore(), false);
      expect(await state.saveDraft(draft()), false);
      expect(
        (await state.publish(draft())).state,
        StorePolicyResultState.notSent,
      );
      expect(journal.draft, isNull);
      expect(journal.pending, isNull);
      expect(gateway.writes, 0);
    },
  );
  test(
    'failed journal save or removal never silently releases a request',
    () async {
      for (final writing in [true, false]) {
        final journal = Journal()
              ..failSave = writing
              ..failClear = !writing,
            gateway = Gateway();
        final state = controller(journal, gateway);
        await state.refresh();
        expect(
          (await state.publish(draft())).state,
          StorePolicyResultState.unknown,
        );
        expect(state.pending, isNotNull);
        expect(gateway.writes, writing ? 0 : 1);
        state.dispose();
      }
    },
  );
  test(
    'immutable owner transport uses save-only limited-use AppCheck and exact saved response',
    () async {
      final wire = Wire(), credentials = Credentials(), original = intent();
      wire.reply = (_) async => response(recordJson(original.draft));
      final source = client(wire, credentials);
      expect(
        (await source.publish(original, () => true)).state,
        StorePolicyResultState.saved,
      );
      expect(wire.sent.single, {
        'operation': 'saveStoreSupplierPolicy',
        ...original.body,
      });
      expect(credentials.modes, [SocialAppCheckTokenMode.limitedUse]);
      await source.reconcile(original, () => true);
      expect(wire.sent.last['operation'], 'reconcileStoreSupplierPolicy');
      expect(credentials.modes.last, SocialAppCheckTokenMode.standard);
    },
  );
  test(
    'account realm and credential-return fences stop transport before dispatch',
    () async {
      final wire = Wire(),
          credentials = Credentials(),
          source = client(wire, credentials);
      final other = StorePolicyIntent(
        scope: (account: 'other-owner', store: scope.store, realm: scope.realm),
        expectedRevision: 0,
        idempotencyKey: 'other-original',
        draft: draft(),
      );
      expect(
        (await source.publish(other, () => true)).state,
        StorePolicyResultState.notSent,
      );
      expect(credentials.tokenCalls, 0);
      var current = true;
      credentials.beforeAppCheck = () async {
        current = false;
      };
      expect(
        (await source.publish(intent(), () => current)).state,
        StorePolicyResultState.notSent,
      );
      expect(wire.sent, isEmpty);
    },
  );
  test(
    'expired input after credentials is not sent; reconciliation can read expired original',
    () async {
      var now = at;
      final wire = Wire(), credentials = Credentials();
      credentials.beforeAppCheck = () async {
        now = at.add(const Duration(days: 2));
      };
      final source = client(wire, credentials, now: () => now),
          original = intent();
      expect(
        (await source.publish(original, () => true)).state,
        StorePolicyResultState.notSent,
      );
      expect(wire.sent, isEmpty);
      wire.reply = (_) async => response(recordJson(original.draft));
      expect(
        (await source.reconcile(original, () => true)).state,
        StorePolicyResultState.saved,
      );
    },
  );
  test(
    'missing receipt and error during original check are unknown, not new writes',
    () async {
      final wire = Wire(),
          credentials = Credentials(),
          source = client(wire, credentials);
      wire.reply = (_) async => response(null);
      expect(
        (await source.reconcile(intent(), () => true)).state,
        StorePolicyResultState.unknown,
      );
      wire.reply = (_) async => SocialContentResponse(
        statusCode: 403,
        body: jsonEncode({
          'ok': false,
          'error': {'code': 'forbidden'},
        }),
      );
      expect(
        (await source.reconcile(intent(), () => true)).state,
        StorePolicyResultState.unknown,
      );
      expect(
        wire.sent.every(
          (r) => r['operation'] == 'reconcileStoreSupplierPolicy',
        ),
        true,
      );
    },
  );
  for (final change in ['realm', 'Store', 'revision', 'body', 'publication']) {
    test('changed $change cannot acknowledge the owner original', () async {
      final wire = Wire(), credentials = Credentials(), original = intent();
      final row = recordJson(original.draft);
      if (change == 'realm') row['realm'] = 'production';
      if (change == 'Store') row['storeId'] = 'store-two';
      if (change == 'revision') row['revision'] = 2;
      if (change == 'body') row['body'] = 'Changed provider text';
      wire.reply = (_) async {
        final envelope = jsonDecode(response(row).body);
        if (change == 'publication') {
          envelope['data']['publicAvailabilityConfirmed'] = true;
        }
        return SocialContentResponse(
          statusCode: 200,
          body: jsonEncode(envelope),
        );
      };
      expect(
        (await client(wire, credentials).publish(original, () => true)).state,
        StorePolicyResultState.unknown,
      );
    });
  }
}
