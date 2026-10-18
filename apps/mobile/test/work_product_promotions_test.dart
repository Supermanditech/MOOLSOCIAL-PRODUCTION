import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:moolsocial/features/work/work_services.dart';
import 'package:moolsocial/features/work/work_session.dart';
import 'package:moolsocial/features/work/work_models.dart';
import 'package:moolsocial/features/work/work_catalogue_gateway.dart';
import 'package:moolsocial/features/work/widgets/store_product_promotions.dart';
import 'work_catalogue_gateway_test.dart' as catalogue;
import 'package:moolsocial/features/shared/social_content_gateway.dart';
import 'package:moolsocial/features/work/work_product_promotions.dart';

// Isolated host records/transport only; never native Store or published offers.
class _FamilyCatalogue extends catalogue.SessionCatalogue implements WorkspaceVariantFamilyOwnerGateway {
  bool supported = true;
  @override bool get variantFamilySubmissionSupported => supported;
  @override Future<WorkspaceVariantFamilyHead> readVariantFamily(WorkspaceVariantFamilyScope scope,
    {required bool Function() current}) => throw StateError('Promotion read must not access family commands');
  @override Future<WorkspaceVariantFamilyWriteResult> writeVariantFamily(WorkspaceVariantFamilyIntent original,
    {required bool Function() current, bool reconcile = false}) => throw StateError('Promotion read must not submit family');
}
const scope = (account: 'owner-one', store: 'store-one', realm: 'evaluation');
final at = DateTime.utc(2026, 10, 17, 4);
StorePromotionInput input({bool active = true}) => StorePromotionInput(
  skuId: 'sku-one',
  skuRevision: 1,
  channel: 'retail',
  headline: 'Host promotion',
  detail: 'Host copy only; no applied discount.',
  validFrom: at,
  validUntil: at.add(const Duration(days: 1)),
  active: active,
);
StorePromotionIntent intent({StorePromotionInput? value, int revision = 0}) =>
    StorePromotionIntent(
      scope: scope,
      placementId: 'promotion-one',
      expectedRevision: revision,
      idempotencyKey: 'original-one',
      input: value ?? input(),
    );
Map<String, dynamic> recordJson(StorePromotionIntent original) => {
  ...original.input.toJson(),
  'schemaVersion': 1,
  'realm': original.scope.realm,
  'storeId': original.scope.store,
  'placementId': original.placementId,
  'revision': original.expectedRevision + 1,
  'observedAt': at.toIso8601String(),
};
SocialContentResponse response(Object? record, {int status = 200}) =>
    SocialContentResponse(
      statusCode: status,
      body: jsonEncode({
        'ok': true,
        'data': {
          'schemaVersion': 1,
          'realm': scope.realm,
          'storeId': scope.store,
          'record': record,
          'publicationConfirmed': false,
        },
      }),
    );

class Credentials implements SocialContentCredentials {
  Future<void> Function()? tokenWait;
  final modes = <SocialAppCheckTokenMode>[];
  @override
  Future<String> firebaseIdToken() async {
    await tokenWait?.call();
    return 'host-token';
  }

  @override
  Future<String> appCheckToken(SocialAppCheckTokenMode mode) async {
    modes.add(mode);
    return 'host-app-check';
  }
}

class Transport implements SocialContentTransport {
  final bodies = <Map<String, Object?>>[];
  Future<SocialContentResponse> Function(Map<String, Object?>) reply =
      (_) async => response(null);
  @override
  Future<SocialContentResponse> postJson(
    Uri endpoint, {
    required Map<String, String> headers,
    required Map<String, Object?> body,
  }) {
    bodies.add(jsonDecode(jsonEncode(body)) as Map<String, Object?>);
    return reply(body);
  }
}

AuthenticatedStorePromotionGateway gateway(
  Credentials credentials,
  Transport transport,
) => AuthenticatedStorePromotionGateway(
  endpoint: Uri.parse(
    'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace',
  ),
  credentials: credentials,
  transport: transport,
  ownerAccountId: scope.account,
  realm: scope.realm,
  now: () => at,
);
StorePromotionResult saved(StorePromotionIntent original) =>
    StorePromotionResult(
      StorePromotionResultState.saved,
      record: StorePromotionRecord.decode(
        recordJson(original),
        original.scope,
        at,
      ),
    );

class Pending implements StorePromotionPendingStore {
  StorePromotionIntent? original;
  bool failRead = false, failSave = false, failClear = false;
  int saves = 0, clears = 0;
  Future<void> Function()? saveWait, clearWait;
  @override
  Future<StorePromotionIntent?> read(StorePromotionScope scope) async {
    if (failRead) throw StateError('isolated storage failure');
    return original;
  }

  @override
  Future<void> save(StorePromotionIntent value) async {
    saves++;
    if (original != null && original!.fingerprint != value.fingerprint) {
      throw StateError('different original');
    }
    await saveWait?.call();
    original = value;
    if (failSave) throw StateError('isolated failed journal acknowledgement');
  }

  @override
  Future<void> clear(StorePromotionIntent value) async {
    clears++;
    await clearWait?.call();
    if (failClear) throw StateError('isolated clear failure');
    if (original != null) expect(original!.fingerprint, value.fingerprint);
    original = null;
  }
}

class Provider implements StorePromotionGateway {
  int reads = 0, writes = 0, checks = 0;
  StorePromotionRecord? currentRecord;
  Future<StorePromotionResult> Function(StorePromotionIntent)? onSave, onCheck;
  @override
  Future<StorePromotionRecord?> read(
    StorePromotionScope scope,
    String id,
    bool Function() current,
  ) async {
    reads++;
    return currentRecord;
  }

  @override
  Future<StorePromotionPage> list(
    StorePromotionScope scope,
    bool Function() current, {
    String? after,
    int limit = 20,
  }) async => StorePromotionPage([?currentRecord], null);
  @override
  Future<StorePromotionResult> save(
    StorePromotionIntent original,
    bool Function() current,
  ) async {
    writes++;
    return onSave == null ? saved(original) : onSave!(original);
  }

  @override
  Future<StorePromotionResult> reconcile(
    StorePromotionIntent original,
    bool Function() current,
  ) async {
    checks++;
    return onCheck == null
        ? const StorePromotionResult(StorePromotionResultState.unknown)
        : onCheck!(original);
  }
}

StorePromotionController controller(
  Pending journal,
  Provider provider, {
  Object? Function()? context,
  DateTime Function()? now,
  Future<bool> Function(StorePromotionInput, bool Function())? validate,
}) => StorePromotionController(
  scope: scope,
  gateway: provider,
  pendingStore: journal,
  context: context ?? () => 1,
  validateSelection: validate ?? (_, current) async => current(),
  now: now ?? () => at,
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'concurrent host journal instances cannot replace an unresolved original',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final first = SecureStorePromotionPendingStore(
        currentAccount: () => scope.account,
      );
      final second = SecureStorePromotionPendingStore(
        currentAccount: () => scope.account,
      );
      final original = intent(),
          different = StorePromotionIntent(
            scope: scope,
            placementId: 'promotion-two',
            expectedRevision: 0,
            idempotencyKey: 'another-original',
            input: input(),
          );
      final outcomes = await Future.wait([
        first.save(original).then((_) => true, onError: (Object _) => false),
        second.save(different).then((_) => true, onError: (Object _) => false),
      ]);
      expect(outcomes, [true, false]);
      expect((await second.read(scope))?.fingerprint, original.fingerprint);
      await first.clear(original);
    },
  );
  test(
    'failed durable cleanup keeps the original held after a confirmed save',
    () async {
      final journal = Pending()..failClear = true,
          provider = Provider(),
          subject = controller(journal, provider);
      await subject.refresh('promotion-one');
      expect(
        (await subject.submit('promotion-one', input())).state,
        StorePromotionResultState.unknown,
      );
      expect(subject.pending?.fingerprint, journal.original?.fingerprint);
      expect(subject.lastAcknowledged, null);
      expect(
        (await subject.submit('promotion-one', input())).state,
        StorePromotionResultState.notSent,
      );
      expect(provider.writes, 1);
      journal.failClear = false;
      provider.onCheck = (original) async => saved(original);
      expect(
        (await subject.reconcile()).state,
        StorePromotionResultState.saved,
      );
      expect(provider.writes, 1);
      expect(subject.pending, null);
      subject.dispose();
    },
  );
  catalogue.SessionCatalogue source() =>
      catalogue.SessionCatalogue()
        ..ownerRead = () async {
          final data = catalogue.ownerRow(listed: true);
          (data['provenance'] as Map)['sourceRecordId'] = 'sku-one';
          return WorkspaceCatalogueOwnedSku.decode(
            data,
            storeId: scope.store,
            skuId: 'sku-one',
            realm: 'production',
            now: catalogue.at,
          );
        };
  WorkSession work(
    Pending journal,
    Provider provider,
    catalogue.SessionCatalogue source,
  ) =>
      WorkSession(
          contactDraftStore: catalogue.ListingAccount(),
          catalogueGateway: source,
          productPromotionGateway: provider,
          productPromotionRealm: 'production',
          productPromotionPendingStoreFactory: (_) => journal,
        )
        ..activeWorkspace = const WorkWorkspace(
          id: 'store-one',
          name: 'Host Store',
          profileLabel: 'Grocery',
          profileId: 'retailer-grocery',
          area: 'Jaipur',
          verified: true,
        )
        ..workspaceId = 'store-one'
        ..workspaceCatalogueItems.add(catalogue.listingItem());
  test(
    'WorkSession resolves actual saved source and leaves Stock and targeted draft unchanged',
    () async {
      final journal = Pending(),
          provider = Provider(),
          owner = work(journal, provider, source());
      addTearDown(owner.dispose);
      owner.workspaceOfferDraft.addAll({
        'title': 'Existing targeted host draft',
        'orderCap': '5',
        'productId': 'sku-one',
      });
      final targetedBefore = jsonEncode(owner.workspaceOfferDraft);
      final before = jsonEncode(
        owner.workspaceCatalogueItems.single.toInventoryJson(),
      );
      final mirror = await owner.readWorkspacePromotionSource(
        'sku-one',
        channel: 'retail',
      );
      expect(mirror?.revision, 1);
      await owner.workspaceProductPromotions!.refresh('promotion-one');
      // WorkSession uses the real clock; keep this host save active when the
      // suite runs later, while fixed-clock expiry tests below remain unchanged.
      final base = input();
      final activeInput = StorePromotionInput(skuId: base.skuId, skuRevision: base.skuRevision,
        channel: base.channel, headline: base.headline, detail: base.detail,
        validFrom: at, validUntil: DateTime.now().toUtc().add(const Duration(days: 1)), active: true);
      expect(
        (await owner.submitWorkspaceProductPromotion(
          'promotion-one',
          activeInput,
        )).state,
        StorePromotionResultState.saved,
      );
      expect(provider.writes, 1);
      expect(jsonEncode(owner.workspaceOfferDraft), targetedBefore);
      expect(owner.workspaceOffers, isEmpty);
      expect(owner.workspaceOfferPublishingAvailable, false);
      expect(
        jsonEncode(owner.workspaceCatalogueItems.single.toInventoryJson()),
        before,
      );
      expect(owner.workspaceOrders, isEmpty);
      expect(owner.workspaceInvoices, isEmpty);
    },
  );
  test('LF-PAISE promotion source binds exact Store prices without a publishing write', () async {
    final connected = source();
    final provider = Provider();
    final owner = work(Pending(), provider, connected);
    addTearDown(owner.dispose);
    owner.workspaceCatalogueItems[0] = owner.workspaceCatalogueItems.single.copyWith(
      sellingPriceMinor: 26025, mrpMinor: 28050);
    connected.ownerRead = () async {
      final data = catalogue.ownerRow(listed: true);
      (data['provenance'] as Map)['sourceRecordId'] = 'sku-one';
      final channel = (data['channels'] as List).single as Map;
      channel['priceMinor'] = 26025; channel['mrpMinor'] = 28050;
      return WorkspaceCatalogueOwnedSku.decode(data, storeId: scope.store,
        skuId: 'sku-one', realm: 'production', now: catalogue.at);
    };
    expect((await owner.readWorkspacePromotionSource('sku-one', channel: 'retail'))?.revision, 1);
    owner.workspaceCatalogueItems[0] = owner.workspaceCatalogueItems.single.copyWith(sellingPriceMinor: 26026);
    expect(await owner.readWorkspacePromotionSource('sku-one', channel: 'retail'), isNull);
    expect(owner.workspaceCatalogueItems.single.sellingPriceMinor, 26026);
    expect(owner.workspaceCatalogueItems.single.stock, 7);
    expect(provider.writes, 0);
    expect(owner.workspaceOrders, isEmpty); expect(owner.workspaceInvoices, isEmpty);
  });
  test('LF03-FAMILY promotion source accepts only negotiated exact structured SKU mirrors', () async {
    final connected = _FamilyCatalogue()..ownerRead = source().ownerRead;
    final provider = Provider();
    final owner = work(Pending(), provider, connected);
    addTearDown(owner.dispose);
    owner.workspaceCatalogueItems[0] = owner.workspaceCatalogueItems.single.copyWith(
      variantMembership: WorkspaceVariantMembership(familyId: 'family-one', selections: {'colour': 'black'}));
    final original = owner.workspaceCatalogueItems.single;
    final before = jsonEncode(owner.workspaceCatalogueItems.single.toInventoryJson());
    expect((await owner.readWorkspacePromotionSource('sku-one', channel: 'retail'))?.revision, 1);
    expect(await owner.readWorkspacePromotionSource('sku-one', channel: 'wholesale'), isNull);
    connected.supported = false;
    expect(await owner.readWorkspacePromotionSource('sku-one', channel: 'retail'), isNull);
    connected.supported = true;
    owner.workspaceCatalogueItems[0] = owner.workspaceCatalogueItems.single.copyWith(sellingPriceMinor: 26001);
    expect(await owner.readWorkspacePromotionSource('sku-one', channel: 'retail'), isNull);
    owner.workspaceCatalogueItems[0] = original;
    expect(jsonEncode(owner.workspaceCatalogueItems.single.toInventoryJson()), before);
    expect(provider.writes, 0); expect(connected.submitted, 0);
    expect(owner.workspaceStockMovements, isEmpty); expect(owner.workspaceOrders, isEmpty); expect(owner.workspaceInvoices, isEmpty);
  });
  test('LF03-FAMILY legacy reader cannot silently strip structured options', () async {
    final provider = Provider();
    final owner = work(Pending(), provider, source());
    addTearDown(owner.dispose);
    owner.workspaceCatalogueItems[0] = owner.workspaceCatalogueItems.single.copyWith(
      variantMembership: WorkspaceVariantMembership(familyId: 'family-one', selections: {'colour': 'black'}));
    expect(await owner.readWorkspacePromotionSource('sku-one', channel: 'retail'), isNull);
    expect(provider.writes, 0);
  });
  for (final initiallyStructured in [false, true]) {
  test('LF03-FAMILY promotion source rejects changed options during SKU read structured=$initiallyStructured', () async {
    final connected = _FamilyCatalogue(), delayed = Completer<WorkspaceCatalogueOwnedSku?>();
    final owner = work(Pending(), Provider(), connected); addTearDown(owner.dispose);
    if (initiallyStructured) {
      owner.workspaceCatalogueItems[0] = owner.workspaceCatalogueItems.single.copyWith(
        variantMembership: WorkspaceVariantMembership(familyId: 'family-one', selections: {'colour': 'black'}));
    }
    connected.ownerRead = () => delayed.future;
    final pending = owner.readWorkspacePromotionSource('sku-one', channel: 'retail');
    await Future<void>.delayed(Duration.zero);
    owner.workspaceCatalogueItems[0] = owner.workspaceCatalogueItems.single.copyWith(
      variantMembership: WorkspaceVariantMembership(familyId: 'family-one', selections: {'colour': 'red'}));
    delayed.complete(await source().ownerRead());
    expect(await pending, isNull);
  });
  }
  test('LF03-FAMILY promotion source rejects account retirement during structured SKU read', () async {
    final connected = _FamilyCatalogue(), delayed = Completer<WorkspaceCatalogueOwnedSku?>();
    final owner = work(Pending(), Provider(), connected); addTearDown(owner.dispose);
    owner.workspaceCatalogueItems[0] = owner.workspaceCatalogueItems.single.copyWith(
      variantMembership: WorkspaceVariantMembership(familyId: 'family-one', selections: {'colour': 'black'}));
    connected.ownerRead = () => delayed.future;
    final pending = owner.readWorkspacePromotionSource('sku-one', channel: 'retail');
    await Future<void>.delayed(Duration.zero);
    (owner.contactDraftStore! as catalogue.ListingAccount).owner = 'other-owner';
    delayed.complete(await source().ownerRead());
    expect(await pending, isNull);
  });
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'explicit promotion editor uses saved source without Stock or targeted draft mutation text$scale',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 700);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final journal = Pending(),
            provider = Provider(),
            owner = work(journal, provider, source());
        addTearDown(owner.dispose);
        owner.workspaceOfferDraft['title'] = 'Untouched targeted host draft';
        final stock = jsonEncode(
          owner.workspaceCatalogueItems.single.toInventoryJson(),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: StoreProductPromotionPanel(
                  session: owner,
                  now: () => at,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Public product promotions'));
        await tester.pumpAndSettle();
        expect(provider.writes, 0);
        final create = find.byKey(const Key('work-promotion-new'));
        await tester.ensureVisible(create);
        await tester.pumpAndSettle();
        expect(create.hitTestable(), findsOneWidget);
        await tester.tap(create);
        await tester.pumpAndSettle();
        final choose = find.byKey(const Key('work-promotion-product'));
        await tester.ensureVisible(choose);
        await tester.pumpAndSettle();
        await tester.tap(choose);
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('work-promotion-product-sku-one')),
        );
        await tester.pumpAndSettle();
        final title = find.byKey(const Key('work-promotion-headline')),
            detail = find.byKey(const Key('work-promotion-detail'));
        await tester.ensureVisible(title);
        await tester.enterText(title, 'Host public promotion');
        await tester.ensureVisible(detail);
        await tester.enterText(
          detail,
          'Product information only, no applied discount.',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        final expiry = find.byKey(const Key('work-promotion-expiry'));
        await tester.ensureVisible(expiry);
        await tester.pumpAndSettle();
        await tester.tap(expiry);
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        final save = find.byKey(const Key('work-promotion-save'));
        await tester.ensureVisible(save);
        await tester.pumpAndSettle();
        expect(save.hitTestable(), findsOneWidget);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(provider.writes, 1);
        expect(journal.original, null);
        expect(
          owner.workspaceOfferDraft['title'],
          'Untouched targeted host draft',
        );
        expect(
          jsonEncode(owner.workspaceCatalogueItems.single.toInventoryJson()),
          stock,
        );
        expect(
          find.textContaining('public visibility is unconfirmed'),
          findsOneWidget,
        );
        expect(tester.takeException(), null);
      },
    );
  }
  testWidgets('unconfigured connection adds no dead-end promotional form', (
    tester,
  ) async {
    final owner = WorkSession();
    addTearDown(owner.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StoreProductPromotionPanel(session: owner)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Public product promotions'), findsNothing);
    expect(find.byKey(const Key('work-promotion-new')), findsNothing);
    expect(tester.takeException(), null);
  });
  testWidgets(
    'restored unknown exposes only original check and never another submit',
    (tester) async {
      final journal = Pending(),
          provider = Provider(),
          owner = work(journal, provider, source());
      addTearDown(owner.dispose);
      journal.original = StorePromotionIntent(
        scope: (
          account: scope.account,
          store: scope.store,
          realm: 'production',
        ),
        placementId: 'promotion-one',
        expectedRevision: 0,
        idempotencyKey: 'host-original',
        input: input(),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StoreProductPromotionPanel(session: owner, now: () => at),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Public product promotions'));
      await tester.pumpAndSettle();
      final check = find.byKey(const Key('work-promotion-original'));
      await tester.ensureVisible(check);
      await tester.pumpAndSettle();
      await tester.tap(check);
      await tester.pumpAndSettle();
      expect(provider.checks, 1);
      expect(provider.writes, 0);
      expect(journal.original, isNotNull);
      expect(
        tester
            .widget<TextButton>(find.byKey(const Key('work-promotion-new')))
            .onPressed,
        null,
      );
      expect(tester.takeException(), null);
    },
  );
  testWidgets(
    'open product selector hides retired Store data and closes only its own sheet',
    (tester) async {
      final journal = Pending(),
          provider = Provider(),
          owner = work(journal, provider, source());
      addTearDown(owner.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StoreProductPromotionPanel(session: owner, now: () => at),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Public product promotions'));
      await tester.pumpAndSettle();
      final create = find.byKey(const Key('work-promotion-new'));
      await tester.ensureVisible(create);
      await tester.pumpAndSettle();
      await tester.tap(create);
      await tester.pumpAndSettle();
      final choose = find.byKey(const Key('work-promotion-product'));
      await tester.ensureVisible(choose);
      await tester.pumpAndSettle();
      await tester.tap(choose);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-promotion-product-sku-one')),
        findsOneWidget,
      );
      owner.activeWorkspace = const WorkWorkspace(
        id: 'store-two',
        name: 'Other Store',
        profileLabel: 'Grocery',
        profileId: 'retailer-grocery',
        area: 'Jaipur',
        verified: true,
      );
      owner.showNotice('Host Store transition');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-promotion-product-sku-one')),
        findsNothing,
      );
      expect(find.text('Choose a saved product'), findsNothing);
      expect(provider.writes, 0);
      expect(tester.takeException(), null);
    },
  );
  testWidgets(
    'pause uses saved original with unavailable source and preserves unsaved editor changes',
    (tester) async {
      final journal = Pending(),
          provider = Provider(),
          catalogueSource = source();
      catalogueSource.ownerRead = () async => null;
      final original = StorePromotionIntent(
        scope: (
          account: scope.account,
          store: scope.store,
          realm: 'production',
        ),
        placementId: 'promotion-one',
        expectedRevision: 0,
        idempotencyKey: 'host-original',
        input: input(),
      );
      provider.currentRecord = StorePromotionRecord.decode(
        recordJson(original),
        original.scope,
        at,
      );
      final owner = work(journal, provider, catalogueSource);
      addTearDown(owner.dispose);
      provider.onSave = (value) async {
        expect(value.input.fingerprint, original.input.paused().fingerprint);
        return saved(value);
      };
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StoreProductPromotionPanel(session: owner, now: () => at),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Public product promotions'));
      await tester.pumpAndSettle();
      final row = find.byKey(const Key('work-promotion-record-promotion-one'));
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();
      final title = find.byKey(const Key('work-promotion-headline'));
      await tester.ensureVisible(title);
      await tester.enterText(title, 'Unsaved new headline');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      final pause = find.byKey(const Key('work-promotion-pause'));
      await tester.ensureVisible(pause);
      await tester.pumpAndSettle();
      expect(pause.hitTestable(), findsOneWidget);
      await tester.tap(pause);
      await tester.pumpAndSettle();
      expect(provider.writes, 1);
      expect(
        tester.widget<TextField>(title).controller!.text,
        'Unsaved new headline',
      );
      expect(
        find.text('Unsaved entries are kept while this editor stays open.'),
        findsOneWidget,
      );
      final create = find.byKey(const Key('work-promotion-new'));
      await tester.ensureVisible(create);
      await tester.pumpAndSettle();
      await tester.tap(create);
      await tester.pumpAndSettle();
      expect(find.text('Discard unsaved promotion changes?'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(title).controller!.text,
        'Unsaved new headline',
      );
      expect(tester.takeException(), null);
    },
  );
  test(
    'WorkSession rejects missing source and replaces retired promotion state on Store A-B-A',
    () async {
      final journal = Pending(),
          provider = Provider(),
          catalogueSource = source();
      catalogueSource.ownerRead = () async => null;
      final owner = work(journal, provider, catalogueSource);
      addTearDown(owner.dispose);
      final first = owner.workspaceProductPromotions!;
      await first.refresh('promotion-one');
      expect(
        (await owner.submitWorkspaceProductPromotion(
          'promotion-one',
          input(),
        )).state,
        StorePromotionResultState.notSent,
      );
      expect(provider.writes, 0);
      final originalStore = owner.activeWorkspace;
      owner.activeWorkspace = const WorkWorkspace(
        id: 'store-two',
        name: 'Other Store',
        profileLabel: 'Grocery',
        profileId: 'retailer-grocery',
        area: 'Jaipur',
        verified: true,
      );
      owner.activeWorkspace = originalStore;
      final replacement = owner.workspaceProductPromotions!;
      expect(identical(first, replacement), false);
      expect(await first.restore(), false);
    },
  );
  test(
    'host secure journal restores across instances without overwriting another original',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final first = SecureStorePromotionPendingStore(
            currentAccount: () => scope.account,
          ),
          original = intent();
      await first.save(original);
      final second = SecureStorePromotionPendingStore(
        currentAccount: () => scope.account,
      );
      expect((await second.read(scope))?.fingerprint, original.fingerprint);
      final changed = StorePromotionIntent(
        scope: scope,
        placementId: 'promotion-two',
        expectedRevision: 0,
        idempotencyKey: 'another-original',
        input: input(),
      );
      await expectLater(second.save(changed), throwsA(isA<FormatException>()));
      await expectLater(second.clear(changed), throwsA(isA<FormatException>()));
      expect((await first.read(scope))?.fingerprint, original.fingerprint);
      await second.clear(original);
      expect(await first.read(scope), null);
    },
  );
  test(
    'host secure journal isolates account Store and realm and fails on corruption',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      var account = scope.account;
      final subject = SecureStorePromotionPendingStore(
        currentAccount: () => account,
      );
      await subject.save(intent());
      expect(
        await subject.read((
          account: scope.account,
          store: 'another-store',
          realm: scope.realm,
        )),
        null,
      );
      expect(
        await subject.read((
          account: scope.account,
          store: scope.store,
          realm: 'production',
        )),
        null,
      );
      account = 'another-owner';
      await expectLater(
        subject.read(scope),
        throwsA(isA<WorkGatewayException>()),
      );
      account = scope.account;
      const storage = FlutterSecureStorage();
      final values = await storage.readAll();
      expect(values.length, 1);
      await storage.write(key: values.keys.single, value: '{}');
      await expectLater(subject.read(scope), throwsFormatException);
    },
  );
  test(
    'expiry while journal saves is confirmed unsent and clears only that original',
    () async {
      var clock = at;
      final journal = Pending(), provider = Provider();
      final subject = controller(journal, provider, now: () => clock);
      await subject.refresh('promotion-one');
      journal.saveWait = () async {
        clock = input().validUntil;
      };
      expect(
        (await subject.submit('promotion-one', input())).state,
        StorePromotionResultState.notSent,
      );
      expect(provider.writes, 0);
      expect(journal.original, null);
      expect(subject.pending, null);
      expect(subject.loadedPlacementId, null);
      subject.dispose();
    },
  );
  test(
    'exact immutable promotion original survives codec without inventing benefits',
    () {
      final original = intent();
      final restored = StorePromotionIntent.fromJson(
        jsonDecode(jsonEncode(original.toJson())),
      );
      expect(restored.fingerprint, original.fingerprint);
      final copy = original.input.toJson();
      copy['headline'] = 'mutated';
      expect(original.input.headline, 'Host promotion');
      expect(original.body.keys, isNot(contains('accountId')));
      expect(jsonEncode(original.body), isNot(contains('savingAmount')));
    },
  );
  test(
    'save acknowledgement requires exact source and remains storage-only',
    () async {
      final credentials = Credentials(),
          transport = Transport(),
          original = intent();
      transport.reply = (_) async => response(recordJson(original));
      final result = await gateway(
        credentials,
        transport,
      ).save(original, () => true);
      expect(result.state, StorePromotionResultState.saved);
      expect(result.publicationConfirmed, false);
      expect(transport.bodies.single, {
        'operation': 'saveStorePromotion',
        ...original.body,
      });
      expect(credentials.modes.single, SocialAppCheckTokenMode.limitedUse);
    },
  );
  test(
    'read failures are not authoritative absence; reconciliation uses readonly original',
    () async {
      final credentials = Credentials(),
          transport = Transport(),
          original = intent();
      final subject = gateway(credentials, transport);
      expect(await subject.read(scope, original.placementId, () => true), null);
      transport.reply = (_) async =>
          const SocialContentResponse(statusCode: 503, body: '{}');
      await expectLater(
        subject.read(scope, original.placementId, () => true),
        throwsFormatException,
      );
      transport.reply = (_) async => response(null);
      final missing = await subject.reconcile(original, () => true);
      expect(missing.state, StorePromotionResultState.unknown);
      expect(transport.bodies.last, {
        'operation': 'reconcileStorePromotion',
        ...original.body,
      });
      expect(
        credentials.modes.every((m) => m == SocialAppCheckTokenMode.standard),
        true,
      );
    },
  );
  for (final field in [
    'realm',
    'storeId',
    'placementId',
    'revision',
    'headline',
    'skuRevision',
    'channel',
  ]) {
    test('changed $field cannot acknowledge the original update', () async {
      final transport = Transport(),
          original = intent(),
          raw = recordJson(original);
      raw[field] = switch (field) {
        'revision' || 'skuRevision' => 2,
        'channel' => ['retail'],
        _ => 'changed',
      };
      transport.reply = (_) async => response(raw);
      expect(
        (await gateway(
          Credentials(),
          transport,
        ).save(original, () => true)).state,
        StorePromotionResultState.unknown,
      );
    });
  }
  test('retired context while credentials wait prevents transport', () async {
    var current = true;
    final credentials = Credentials()
      ..tokenWait = () async {
        current = false;
      };
    final transport = Transport();
    expect(
      (await gateway(
        credentials,
        transport,
      ).save(intent(), () => current)).state,
      StorePromotionResultState.notSent,
    );
    expect(transport.bodies, isEmpty);
    expect(credentials.modes, isEmpty);
  });
  test(
    'late reply after context retirement is unknown, never a saved result',
    () async {
      var current = true;
      final transport = Transport(), original = intent();
      transport.reply = (_) async {
        current = false;
        return response(recordJson(original));
      };
      expect(
        (await gateway(
          Credentials(),
          transport,
        ).save(original, () => current)).state,
        StorePromotionResultState.unknown,
      );
    },
  );
  test(
    'expired active save is unsent but original pause and reconciliation remain permitted',
    () async {
      final expired = StorePromotionInput(
        skuId: 'sku-one',
        skuRevision: 1,
        channel: 'retail',
        headline: 'Expired host',
        detail: 'Host only',
        validFrom: at.subtract(const Duration(days: 2)),
        validUntil: at.subtract(const Duration(days: 1)),
        active: true,
      );
      final transport = Transport(),
          credentials = Credentials(),
          subject = gateway(credentials, transport);
      expect(
        (await subject.save(intent(value: expired), () => true)).state,
        StorePromotionResultState.notSent,
      );
      expect(transport.bodies, isEmpty);
      final pause = intent(value: expired.paused(), revision: 1);
      transport.reply = (_) async => response(recordJson(pause));
      expect(
        (await subject.save(pause, () => true)).state,
        StorePromotionResultState.saved,
      );
      expect(
        (await subject.reconcile(pause, () => true)).state,
        StorePromotionResultState.saved,
      );
      expect(credentials.modes, [
        SocialAppCheckTokenMode.limitedUse,
        SocialAppCheckTokenMode.standard,
      ]);
    },
  );
  test(
    'owner page uses exact ordered cursor; malformed cursor cannot masquerade as complete',
    () async {
      final transport = Transport(),
          credentials = Credentials(),
          original = intent();
      transport.reply = (_) async => SocialContentResponse(
        statusCode: 200,
        body: jsonEncode({
          'ok': true,
          'data': {
            'schemaVersion': 1,
            'realm': scope.realm,
            'storeId': scope.store,
            'publicationConfirmed': false,
            'items': [recordJson(original)],
            'nextCursor': original.placementId,
          },
        }),
      );
      final subject = gateway(credentials, transport),
          page = await subject.list(scope, () => true, limit: 1);
      expect(page.records.single.placementId, original.placementId);
      expect(page.nextCursor, original.placementId);
      await expectLater(
        subject.list(scope, () => true, after: original.placementId, limit: 1),
        throwsFormatException,
      );
    },
  );
  test(
    'controller restores first, persists original before send and never treats receipt as current',
    () async {
      final journal = Pending(),
          provider = Provider(),
          subject = controller(journal, provider);
      provider.onSave = (original) async {
        expect(journal.original?.fingerprint, original.fingerprint);
        return saved(original);
      };
      expect(await subject.refresh('promotion-one'), true);
      expect(
        (await subject.submit('promotion-one', input())).state,
        StorePromotionResultState.saved,
      );
      expect(journal.original, null);
      expect(subject.pending, null);
      expect(subject.currentRecord, null);
      expect(subject.loadedPlacementId, null);
      expect(subject.lastAcknowledged?.revision, 1);
      expect(provider.writes, 1);
      subject.dispose();
    },
  );
  test(
    'lost reply survives controller recreation; only original reconciliation clears it',
    () async {
      final journal = Pending(), provider = Provider();
      provider.onSave = (_) async =>
          const StorePromotionResult(StorePromotionResultState.unknown);
      final first = controller(journal, provider);
      await first.refresh('promotion-one');
      expect(
        (await first.submit('promotion-one', input())).state,
        StorePromotionResultState.unknown,
      );
      final original = first.pending!;
      expect(
        (await first.submit('promotion-one', input())).state,
        StorePromotionResultState.notSent,
      );
      first.dispose();
      final next = controller(journal, provider);
      expect(await next.restore(), true);
      expect(next.pending?.fingerprint, original.fingerprint);
      expect((await next.reconcile()).state, StorePromotionResultState.unknown);
      expect(next.pending?.fingerprint, original.fingerprint);
      provider.onCheck = (value) async {
        expect(value.fingerprint, original.fingerprint);
        return saved(value);
      };
      expect((await next.reconcile()).state, StorePromotionResultState.saved);
      expect(next.loadedPlacementId, null);
      expect(next.currentRecord, null);
      expect(provider.writes, 1);
      expect(provider.checks, 2);
      next.dispose();
    },
  );
  test(
    'failed restore or journal acknowledgement cannot dispatch a write',
    () async {
      final journal = Pending()..failRead = true,
          provider = Provider(),
          subject = controller(journal, provider);
      expect(await subject.refresh('promotion-one'), false);
      expect(subject.ready, false);
      expect(
        (await subject.submit('promotion-one', input())).state,
        StorePromotionResultState.notSent,
      );
      journal.failRead = false;
      expect(await subject.refresh('promotion-one'), true);
      journal.failSave = true;
      expect(
        (await subject.submit('promotion-one', input())).state,
        StorePromotionResultState.notSent,
      );
      expect(provider.writes, 0);
      expect(journal.original, null);
      subject.dispose();
    },
  );
  test(
    'controller cannot adopt replacement lifetime or dispatch after selection retirement',
    () async {
      Object? context = 1;
      final journal = Pending(),
          provider = Provider(),
          retired = controller(journal, provider, context: () => context);
      context = 2;
      expect(await retired.restore(), false);
      expect(await retired.refresh('promotion-one'), false);
      retired.dispose();
      final subject = controller(journal, provider, context: () => context);
      await subject.refresh('promotion-one');
      journal.saveWait = () async {
        context = 3;
      };
      expect(
        (await subject.submit('promotion-one', input())).state,
        StorePromotionResultState.unknown,
      );
      expect(provider.writes, 0);
      expect(journal.original, isNotNull);
      subject.dispose();
    },
  );
  test(
    'pause changes only loaded original active flag; missing source need not block it',
    () async {
      final journal = Pending(), provider = Provider(), original = intent();
      provider.currentRecord = StorePromotionRecord.decode(
        recordJson(original),
        scope,
        at,
      );
      final subject = controller(
        journal,
        provider,
        validate: (_, _) async => false,
      );
      await subject.refresh('promotion-one');
      expect(
        (await subject.submit('promotion-one', input())).state,
        StorePromotionResultState.notSent,
      );
      expect(
        (await subject.submit('promotion-one', original.input.paused())).state,
        StorePromotionResultState.saved,
      );
      expect(provider.writes, 1);
      subject.dispose();
    },
  );
  test(
    'controller stays busy until durable original removal actually completes',
    () async {
      final journal = Pending(),
          provider = Provider(),
          subject = controller(journal, provider);
      await subject.refresh('promotion-one');
      final entered = Completer<void>(), release = Completer<void>();
      journal.clearWait = () async {
        entered.complete();
        await release.future;
      };
      final operation = subject.submit('promotion-one', input());
      await entered.future;
      try {
        expect(subject.busy, true);
      } finally {
        release.complete();
        await operation;
        subject.dispose();
      }
    },
  );
}
