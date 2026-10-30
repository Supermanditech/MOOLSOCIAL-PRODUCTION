import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:moolsocial/features/work/work_services.dart';
import 'package:moolsocial/features/work/work_session.dart';
import 'package:moolsocial/features/work/work_models.dart';
import 'package:moolsocial/features/work/work_catalogue_gateway.dart';
import 'package:moolsocial/features/work/widgets/store_product_promotions.dart';
import 'work_catalogue_gateway_test.dart' as catalogue;
import 'package:moolsocial/features/shared/social_content_gateway.dart';
import 'package:moolsocial/features/work/work_product_promotions.dart';
import 'package:moolsocial/features/work/screens/work_workspace_dashboard_screen.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';

// Isolated host records/transport only; never native Store or published offers.
class _HostCouponWorkspaceGateway extends UnavailableWorkGateway {
  _HostCouponWorkspaceGateway(this.profile);
  final String profile;
  WorkReviewResult _record() {
    final checked = DateTime.now().toUtc().subtract(const Duration(seconds: 1));
    return WorkReviewResult(caseId: 'host-coupon-case', status: WorkRemoteReviewStatus.approved,
      plan: 'free', workspaceId: 'store-one', profileId: profile, name: 'HOST supplier', area: 'Jaipur',
      access: WorkWorkspaceAccess(accountId: 'owner-one', caseId: 'host-coupon-case', workspaceId: 'store-one',
        profileId: profile, version: 1, membershipId: 'host-coupon-member', applicationUpdatedAt: checked,
        checkedAt: checked, effectiveFrom: checked, expiresAt: checked.add(const Duration(minutes: 10))));
  }
  @override Future<List<WorkReviewResult>> loadFeed() async => [_record()];
  @override Future<WorkReviewResult> checkReview(String caseId) async {
    if (caseId != 'host-coupon-case') throw StateError('Foreign HOST application');
    return _record();
  }
}

class _RichOfferMemory extends catalogue.ListingAccount {
  final values = <String, Map<String, Object?>>{};
  bool unknownSave = false;
  @override Future<Map<String, Object?>?> read(String scope) async => values[scope];
  @override Future<void> save(String scope, Map<String, Object?> draft) async {
    values[scope] = Map<String, Object?>.from(draft);
    if (unknownSave) throw StateError('Host unknown save after durable write');
  }
  @override Future<void> clear(String scope) async { values.remove(scope); }
}
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
SocialContentResponse response(Object? record, {int status = 200, bool terms = false}) =>
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
          if (terms) 'promotionTermsVersion': 1,
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
  {bool terms = false}
) => AuthenticatedStorePromotionGateway(
  endpoint: Uri.parse(
    'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace',
  ),
  credentials: credentials,
  transport: transport,
  ownerAccountId: scope.account,
  realm: scope.realm,
  now: () => at,
  benefitTermsSupported: terms,
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

// Isolated host command fixtures only. Never injected into the evaluation phone.
class CouponPending implements StoreCouponPendingStore {
  StoreCouponIntent? original;
  bool failSave = false, failClear = false;
  Future<void> Function()? afterSave;
  @override Future<StoreCouponIntent?> read(StorePromotionScope scope) async => original;
  @override Future<void> save(StoreCouponIntent value) async {
    if (original != null && original!.fingerprint != value.fingerprint) throw const FormatException();
    original = value; await afterSave?.call();
    if (failSave) throw StateError('Host save acknowledgement failed');
  }
  @override Future<void> clear(StoreCouponIntent value) async {
    if (failClear) throw StateError('Host clear failed');
    if (original != null && original!.fingerprint != value.fingerprint) throw const FormatException();
    original = null;
  }
}
// Isolated HOST lifecycle fakes. Actual DTOs are qualified separately above.
class _PrivateDraftPending implements StoreCouponDraftPendingStore {
  StoreCouponDraftIntent? original;
  bool failBeforeSave = false, failAfterSave = false, failClear = false;
  Future<void> Function()? afterSave;
  @override Future<StoreCouponDraftIntent?> read(StorePromotionScope scope) async => original;
  @override Future<void> save(StoreCouponDraftIntent intent) async {
    if (failBeforeSave) throw StateError('HOST journal did not save');
    if (original != null && original!.fingerprint != intent.fingerprint) throw const FormatException();
    original ??= intent;
    await afterSave?.call();
    if (failAfterSave) throw StateError('HOST journal acknowledgement lost');
  }
  @override Future<void> clear(StoreCouponDraftIntent intent) async {
    if (failClear) throw StateError('HOST clear failed');
    if (original != null && original!.fingerprint != intent.fingerprint) throw const FormatException();
    original = null;
  }
}
class _PrivateDraftGateway implements StoreCouponDraftGateway {
  @override bool storeCouponDraftsSupported = true;
  StoreCouponDraftRecord? head;
  final receipts = <String, StoreCouponDraftRecord>{};
  final writes = <StoreCouponDraftIntent>[], checks = <StoreCouponDraftIntent>[];
  int reads = 0, effects = 0;
  bool unknownWrite = false;
  StorePromotionResultState? writeState, recoveryState;
  Future<void> Function()? beforeRead, afterWrite;
  StoreCouponDraftRecord acknowledge(StoreCouponDraftIntent intent) => StoreCouponDraftRecord.decode({
    'schemaVersion': 1, 'storeCouponDraftVersion': 1, 'accountId': intent.scope.account, 'realm': intent.scope.realm,
    'storeId': intent.scope.store, 'couponId': intent.couponId, 'sourceRevision': intent.expectedSourceRevision + 1,
    'observedAt': at.toIso8601String(), 'campaign': intent.campaign.toJson()}, intent.scope, at);
  @override Future<StoreCouponDraftRecord?> readCouponDraft(StorePromotionScope scope, String couponId, bool Function() current) async {
    reads++; await beforeRead?.call(); return head;
  }
  @override Future<StoreCouponDraftPage> listCouponDrafts(StorePromotionScope scope, bool Function() current, {String? after, int limit = 20}) async => StoreCouponDraftPage([], null);
  @override Future<StoreCouponDraftResult> saveCouponDraft(StoreCouponDraftIntent intent, bool Function() current) async {
    writes.add(intent);
    if (!current()) return const StoreCouponDraftResult(StorePromotionResultState.notSent);
    if (writeState != null) return StoreCouponDraftResult(writeState!);
    final receipt = receipts[intent.fingerprint];
    if (receipt == null) {effects++; receipts[intent.fingerprint] = head = acknowledge(intent);}
    await afterWrite?.call();
    return unknownWrite ? const StoreCouponDraftResult(StorePromotionResultState.unknown) :
      StoreCouponDraftResult(StorePromotionResultState.saved, record: receipts[intent.fingerprint]);
  }
  @override Future<StoreCouponDraftResult> reconcileCouponDraft(StoreCouponDraftIntent intent, bool Function() current) async {
    checks.add(intent);
    if (recoveryState != null) return StoreCouponDraftResult(recoveryState!);
    final original = receipts[intent.fingerprint];
    return original == null ? const StoreCouponDraftResult(StorePromotionResultState.unknown) :
      StoreCouponDraftResult(StorePromotionResultState.saved, record: original);
  }
}
class CouponProvider implements StoreCouponGateway {
  @override bool storeCouponTermsSupported = true;
  final writes = <StoreCouponIntent>[], recoveries = <StoreCouponIntent>[];
  StoreCouponRecord? head, receipt;
  bool unknown = false;
  Future<void> Function()? afterWrite;
  StoreCouponRecord acknowledge(StoreCouponIntent original) => StoreCouponRecord.decode({...original.input.toJson(),
    'schemaVersion': 1, 'realm': original.scope.realm, 'storeId': original.scope.store,
    'couponId': original.couponId, 'revision': original.expectedRevision + 1, 'observedAt': at.toIso8601String()}, original.scope, at);
  @override Future<StoreCouponRecord?> readCoupon(StorePromotionScope scope, String couponId, bool Function() current) async => head;
  @override Future<StoreCouponPage> listCoupons(StorePromotionScope scope, bool Function() current, {String? after, int limit = 20}) async => StoreCouponPage([], null);
  @override Future<StoreCouponResult> saveCoupon(StoreCouponIntent original, bool Function() current) async {
    writes.add(original); receipt = head = acknowledge(original); await afterWrite?.call();
    return unknown ? const StoreCouponResult(StorePromotionResultState.unknown) : StoreCouponResult(StorePromotionResultState.saved, record: receipt);
  }
  @override Future<StoreCouponResult> reconcileCoupon(StoreCouponIntent original, bool Function() current) async {
    recoveries.add(original);
    return receipt == null ? const StoreCouponResult(StorePromotionResultState.unknown)
      : StoreCouponResult(StorePromotionResultState.saved, record: receipt);
  }
}

class Provider implements StorePromotionGateway, StorePromotionTermsCapability {
  @override bool benefitTermsSupported = false;
  StorePromotionIntent? lastSaved;
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
    lastSaved = original;
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
class _OfferHeldCouponPending extends CouponPending {
  Completer<void>? readGate;
  final readEntered = Completer<void>();
  @override Future<StoreCouponIntent?> read(StorePromotionScope scope) async {
    if (!readEntered.isCompleted) readEntered.complete();
    await readGate?.future; return super.read(scope);
  }
}
class _OfferGuardedCouponProvider extends CouponProvider {
  final entered = Completer<void>();
  Completer<void>? beforeTransport;
  @override Future<StoreCouponResult> saveCoupon(StoreCouponIntent original, bool Function() current) async {
    if (!entered.isCompleted) entered.complete();
    await beforeTransport?.future;
    if (!current()) return const StoreCouponResult(StorePromotionResultState.unknown);
    return super.saveCoupon(original, current);
  }
}
void registerOfferControllerOwnerTests() {
  Future<StoreCouponIntent> seed(CouponPending pending) async {
    final gateway = CouponProvider()..unknown = true;
    final controller = StoreCouponController(scope: scope, gateway: gateway, pendingStore: pending, context: () => 1, now: () => at);
    try {
      final campaign = StoreCouponCampaign(id: 'coupon-guarded', storeId: scope.store, revision: 1, name: 'HOST guarded coupon',
        percentage: false, discount: 100, minimumSpendMinor: 0, maximumSavingMinor: 100,
        startsAt: at.subtract(const Duration(days: 1)), endsAt: at.add(const Duration(days: 7)), totalUses: 100, usesPerCustomer: 1);
      expect(await controller.refresh(campaign.id), isTrue);
      expect((await controller.submit(campaign.id, StoreCouponInput.fromCampaign(campaign, active: true),
        fundingAcknowledged: true, inputCurrent: () => true)).state, StorePromotionResultState.unknown);
      return controller.pending!;
    } finally { controller.dispose(); }
  }
  test('FE-OFFER310 retry rechecks actual captured current after pending restore without replacing original', () async {
    final pending = _OfferHeldCouponPending(); final original = await seed(pending);
    pending.readGate = Completer<void>();
    final gateway = CouponProvider(); var current = true;
    final controller = StoreCouponController(scope: scope, gateway: gateway, pendingStore: pending, context: () => 1, now: () => at);
    try {
      final retry = controller.retryOriginal(fundingAcknowledged: true, inputCurrent: () => current);
      await Future<void>.value(); current = false; pending.readGate!.complete();
      expect((await retry).state, StorePromotionResultState.unknown);
      expect(gateway.writes, isEmpty); expect(controller.pending!.fingerprint, original.fingerprint);
      expect(pending.original!.idempotencyKey, original.idempotencyKey);
    } finally { if (!pending.readGate!.isCompleted) pending.readGate!.complete(); controller.dispose(); }
  });
  test('FE-OFFER310 exact-original gateway receives the live inputCurrent guard through transport wait', () async {
    final pending = CouponPending(), gateway = _OfferGuardedCouponProvider()..beforeTransport = Completer<void>();
    final original = await seed(pending); var current = true;
    final controller = StoreCouponController(scope: scope, gateway: gateway, pendingStore: pending, context: () => 1, now: () => at);
    try {
      final retry = controller.retryOriginal(fundingAcknowledged: true, inputCurrent: () => current);
      await gateway.entered.future; current = false; gateway.beforeTransport!.complete();
      expect((await retry).state, StorePromotionResultState.unknown);
      expect(gateway.writes, isEmpty); expect(controller.pending!.fingerprint, original.fingerprint);
    } finally { if (!gateway.beforeTransport!.isCompleted) gateway.beforeTransport!.complete(); controller.dispose(); }
  });
  test('FE-OFFER310 manual default retry retains exact key CAS and terms without replacement', () async {
    final pending = CouponPending(), gateway = CouponProvider(); final original = await seed(pending);
    final controller = StoreCouponController(scope: scope, gateway: gateway, pendingStore: pending, context: () => 1, now: () => at);
    try {
      expect((await controller.retryOriginal(fundingAcknowledged: true)).state, StorePromotionResultState.saved);
      expect(gateway.writes, hasLength(1)); expect(gateway.writes.single.fingerprint, original.fingerprint);
      expect(gateway.writes.single.idempotencyKey, original.idempotencyKey); expect(gateway.writes.single.expectedRevision, original.expectedRevision);
      expect(controller.pending, isNull);
    } finally { controller.dispose(); }
  });
}


void main() {
  registerOfferControllerOwnerTests();
  BuyV2StoreOfferSku offerSku(String id, {String store = 'store-one'}) =>
    BuyV2StoreOfferSku(storeId: store, skuId: id, title: 'Host $id', sellUnit: '1 L');
  BuyV2StoreOfferTerms offerTerms({BuyV2StoreOfferKind kind = BuyV2StoreOfferKind.productDiscount}) {
    if (kind == BuyV2StoreOfferKind.quantityPrice) {
      return BuyV2StoreOfferTerms(storeId: 'store-one', kind: kind, skus: [offerSku('sku-one')],
        channels: const {'wholesale', 'bulk'}, tiers: const [BuyV2StoreOfferTier(minimumQuantity: 10, priceMinor: 9000)]);
    }
    if (kind == BuyV2StoreOfferKind.extraQuantity) {
      return BuyV2StoreOfferTerms(storeId: 'store-one', kind: kind, skus: [offerSku('sku-one')],
        channels: const {'wholesale'}, buyQuantity: 10, rewardSku: offerSku('reward-one'), rewardQuantity: 1);
    }
    return BuyV2StoreOfferTerms(storeId: 'store-one', kind: kind, skus: [offerSku('sku-one')],
      channels: const {'retail', 'wholesale', 'bulk'}, discountKind: 'percentage',
      discountValue: 500, minimumSpendMinor: 10000, maximumSavingMinor: 20000,
      nextPurchaseDays: kind == BuyV2StoreOfferKind.nextPurchase ? 30 : null);
  }
  StoreCouponCampaign richDraft({BuyV2StoreOfferKind kind = BuyV2StoreOfferKind.productDiscount}) =>
    StoreCouponCampaign.offer(id: 'coupon-rich', storeId: 'store-one', revision: 1,
      name: 'Host Holi savings', structuredTerms: offerTerms(kind: kind),
      buyerReferences: kind == BuyV2StoreOfferKind.buyerDiscount ? const ['customer-one'] : const [],
      startsAt: at, endsAt: at.add(const Duration(days: 2)), totalUses: 20, usesPerCustomer: 1);

  test('AGG09 native structured inputs and original fingerprints preserve all seven kinds and large selections', () {
    final inputs = [for (final kind in BuyV2StoreOfferKind.values)
      StoreCouponIntent(scope: scope, couponId: 'coupon-${kind.name}', expectedRevision: 0,
        idempotencyKey: 'request-${kind.name}', input: StoreCouponInput.fromCampaign(richDraft(kind: kind), active: true),
        fundingAcknowledged: true)];
    final large = StoreCouponCampaign.offer(id: 'coupon-large', storeId: scope.store, revision: 1,
      name: 'HOST large native terms', structuredTerms: BuyV2StoreOfferTerms(storeId: scope.store,
        kind: BuyV2StoreOfferKind.productDiscount, channels: const {'retail', 'wholesale', 'bulk'},
        skus: [for (var i = 0; i < 1000; i++) BuyV2StoreOfferSku(storeId: scope.store, skuId: 'sku-$i',
          title: List.filled(40, 'हिंदी').join(), sellUnit: List.filled(40, 'पैक').join(),
          listings: [for (final channel in BuyV2OfferClass.values) BuyV2PublicListingIdentity(
            listingId: 'listing-${List.filled(64, 'a').join()}', realm: scope.realm, storeId: scope.store,
            skuId: 'sku-$i', canonicalProductId: 'product-$i', verifiedPackId: 'pack-$i', channel: channel)])],
        discountKind: 'flat', discountValue: 100, maximumSavingMinor: 100),
      startsAt: at, endsAt: at.add(const Duration(days: 2)), totalUses: 100, usesPerCustomer: 1);
    inputs.add(StoreCouponIntent(scope: scope, couponId: large.id, expectedRevision: 0,
      idempotencyKey: 'request-large', input: StoreCouponInput.fromCampaign(large, active: true), fundingAcknowledged: true));
    expect(utf8.encode(jsonEncode(inputs.last.body)).length, greaterThan(1024 * 1024));
    for (final intent in inputs) {
      expect(StoreCouponIntent.fromJson(intent.toJson()).fingerprint, intent.fingerprint);
      expect(intent.input.toJson()['structuredTerms']['schemaVersion'], 1);
    }
    final campaigns = {for (final intent in inputs) intent.couponId:
      StoreCouponCampaign.fromJson({...(intent.input.toJson()..remove('active')),
        'id': intent.couponId, 'storeId': scope.store, 'revision': 1}, scope.store).toJson()};
    final legacyCampaign = StoreCouponCampaign(id: 'A', storeId: scope.store, revision: 12,
      name: 'HOST existing private draft', percentage: false, discount: 100, minimumSpendMinor: 0,
      maximumSavingMinor: 100, startsAt: at, endsAt: at.add(const Duration(days: 2)), totalUses: 20, usesPerCustomer: 1);
    final path = Platform.environment['AGG09_NATIVE_COUPON_WIRE_EXPORT_PATH'];
    if (path != null) File(path).writeAsStringSync(jsonEncode({'fixture': 'ISOLATED HOST native serializers; never phone authority',
      'scope': {'account': scope.account, 'store': scope.store, 'realm': scope.realm}, 'now': at.toIso8601String(),
      'legacyCampaign': legacyCampaign.toJson(),
      'intents': [for (final intent in inputs) {'input': intent.input.toJson(), 'body': intent.body,
        'campaign': campaigns[intent.couponId], 'nativeFingerprint': intent.fingerprint}]}));
  });

  final sdkCouponWire = Platform.environment['AGG09_BACKEND_COUPON_WIRE_EXPORT_PATH'];
  test('AGG09 structured transport remains explicitly configured through owner rebinding', () {
    AuthenticatedWorkspaceCatalogueGateway source(bool enabled) => AuthenticatedWorkspaceCatalogueGateway(
      endpoint: Uri.parse('https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
      credentials: Credentials(), transport: Transport(), realm: scope.realm, ownerAccountId: scope.account,
      storeCouponTermsV2Supported: enabled);
    expect(source(false).forOwnerAccount('another-owner').storeCouponTermsV2Supported, isFalse);
    expect(source(true).forOwnerAccount('another-owner').storeCouponTermsV2Supported, isTrue);
    expect(source(true).storeCouponTermsSupported, isFalse);
    expect(source(true).storeCouponEligibilitySupported, isFalse);
  });
  test('AGG09 authenticated native v2 gateway decodes actual SDK originals without losing pending fingerprints', () async {
    final exported = jsonDecode(File(sdkCouponWire!).readAsStringSync()) as Map;
    expect(exported['fixture'], 'ISOLATED HOST actual SDK original responses; never phone authority');
    for (final row in exported['rows'] as List) {
      final original = StoreCouponIntent.fromJson(jsonDecode(row['nativeFingerprint'] as String));
      final credentials = Credentials(), transport = Transport();
      transport.reply = (_) async => SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': row['response']}));
      final subject = AuthenticatedStructuredStorePromotionGateway(
        endpoint: Uri.parse('https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
        credentials: credentials, transport: transport, ownerAccountId: scope.account, realm: scope.realm,
        storeCouponTermsSupported: true, now: () => at);
      expect(subject, isA<StoreStructuredCouponGateway>());
      expect((await subject.readCoupon(scope, original.couponId, () => true))!.input.fingerprint, original.input.fingerprint);
      expect((await subject.saveCoupon(original, () => true)).record!.acknowledges(original), isTrue);
      expect((await subject.reconcileCoupon(original, () => true)).record!.acknowledges(original), isTrue);
      expect(transport.bodies.map((body) => body['storeCouponTermsVersion']), everyElement(2));
      expect(credentials.modes, [SocialAppCheckTokenMode.standard, SocialAppCheckTokenMode.limitedUse, SocialAppCheckTokenMode.standard]);
      transport.reply = (_) async => SocialContentResponse(statusCode: 200,
        body: jsonEncode({'ok': true, 'data': {...row['response'] as Map, 'storeCouponTermsVersion': 1}}));
      await expectLater(subject.readCoupon(scope, original.couponId, () => true), throwsFormatException);
      expect((await subject.reconcileCoupon(original, () => true)).state, StorePromotionResultState.unknown);
    }
    final pageTransport = Transport();
    pageTransport.reply = (_) async => SocialContentResponse(statusCode: 200,
      body: jsonEncode({'ok': true, 'data': exported['byteBoundPage']}));
    final pageSource = AuthenticatedStructuredStorePromotionGateway(
      endpoint: Uri.parse('https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
      credentials: Credentials(), transport: pageTransport, ownerAccountId: scope.account, realm: scope.realm,
      storeCouponTermsSupported: true, now: () => at);
    final page = await pageSource.listCoupons(scope, () => true);
    expect(page.records.length, lessThan(20)); expect(page.records, isNotEmpty);
    expect(page.nextCursor, page.records.last.couponId);
  }, skip: sdkCouponWire == null ? 'Actual SDK native wire is produced by the explicit local qualification run' : false);

  final sdkDraftWire = Platform.environment['AGG09_BACKEND_COUPON_DRAFT_WIRE_EXPORT_PATH'];
  test('AGG09 native private draft gateway preserves actual SDK originals and never negotiates publication', () async {
    final exported = jsonDecode(File(sdkDraftWire!).readAsStringSync()) as Map;
    expect(exported['fixture'], 'ISOLATED HOST actual SDK private draft originals; never phone authority');
    for (final row in exported['drafts'] as List) {
      final campaign = StoreCouponCampaign.fromJson(row['body']['campaign'], scope.store);
      final intent = StoreCouponDraftIntent(scope: scope, expectedSourceRevision: row['body']['expectedSourceRevision'] as int,
        idempotencyKey: row['body']['idempotencyKey'] as String, campaign: campaign);
      expect(StoreCouponDraftIntent.fromJson(intent.toJson()).fingerprint, intent.fingerprint);
      expect(intent.campaignFingerprint, row['nativeCampaignJson']);
      final record = StoreCouponDraftRecord.decode(row['record'], scope, at);
      expect(record.acknowledges(intent), isTrue);
      if (campaign.id == 'A') {expect(record.sourceRevision, 1); expect(record.campaign.revision, 12);}
      final credentials = Credentials(), transport = Transport();
      transport.reply = (_) async => SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': row['response']}));
      final source = AuthenticatedStorePromotionGateway(endpoint: Uri.parse(
        'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
        credentials: credentials, transport: transport, ownerAccountId: scope.account, realm: scope.realm,
        benefitTermsSupported: true, storeCouponDraftsSupported: true, now: () => at);
      expect(source.storeCouponTermsSupported, isFalse);
      expect((await source.readCouponDraft(scope, campaign.id, () => true))!.campaignFingerprint, intent.campaignFingerprint);
      expect((await source.saveCouponDraft(intent, () => true)).record!.acknowledges(intent), isTrue);
      expect((await source.reconcileCouponDraft(intent, () => true)).record!.acknowledges(intent), isTrue);
      expect(credentials.modes, [SocialAppCheckTokenMode.standard, SocialAppCheckTokenMode.limitedUse, SocialAppCheckTokenMode.standard]);
      for (final body in transport.bodies) {
        expect(body['storeCouponDraftVersion'], 1); expect(body.containsKey('storeCouponTermsVersion'), isFalse);
        expect(body.containsKey('promotionTermsVersion'), isFalse);
      }
      transport.reply = (_) async => SocialContentResponse(statusCode: 200,
        body: jsonEncode({'ok': true, 'data': {...row['response'] as Map, 'publicationConfirmed': true}}));
      expect((await source.reconcileCouponDraft(intent, () => true)).state, StorePromotionResultState.unknown);
      expect(() => StoreCouponDraftRecord.decode({...row['record'] as Map, 'accountId': 'foreign-owner'}, scope, at), throwsFormatException);
    }
  }, skip: sdkDraftWire == null ? 'Requires explicit actual SDK private draft wire' : false);

  test('AGG09 secure private draft original remains separate from publication and cannot be replaced', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final draft = StoreCouponDraftIntent(scope: scope, expectedSourceRevision: 0, idempotencyKey: 'private-original', campaign: richDraft());
    final changed = StoreCouponDraftIntent(scope: scope, expectedSourceRevision: 0, idempotencyKey: 'private-changed', campaign: richDraft());
    final storage = SecureStoreCouponDraftPendingStore(currentAccount: () => scope.account);
    final publication = SecureStoreCouponPendingStore(currentAccount: () => scope.account);
    final publicIntent = StoreCouponIntent(scope: scope, couponId: 'publication-one', expectedRevision: 0,
      idempotencyKey: 'publication-original', input: StoreCouponInput.fromCampaign(richDraft(), active: true), fundingAcknowledged: true);
    await publication.save(publicIntent); await storage.save(draft);
    expect((await SecureStoreCouponDraftPendingStore(currentAccount: () => scope.account).read(scope))!.fingerprint, draft.fingerprint);
    await expectLater(storage.save(changed), throwsFormatException);
    await expectLater(storage.clear(changed), throwsFormatException);
    expect((await publication.read(scope))!.fingerprint, publicIntent.fingerprint);
    await storage.clear(draft); expect(await storage.read(scope), isNull);
    expect((await publication.read(scope))!.fingerprint, publicIntent.fingerprint);
    await publication.clear(publicIntent);
  });

  test('AGG09 secure private draft journal serializes competing instances and rejects a retired account', () async {
    FlutterSecureStorage.setMockInitialValues({});
    String? account = scope.account;
    final one = SecureStoreCouponDraftPendingStore(currentAccount: () => account);
    final two = SecureStoreCouponDraftPendingStore(currentAccount: () => account);
    StoreCouponDraftIntent command(String key) => StoreCouponDraftIntent(scope: scope, expectedSourceRevision: 0,
      idempotencyKey: key, campaign: richDraft());
    final results = await Future.wait([one.save(command('private-first')), two.save(command('private-second'))]
      .map((future) => future.then((_) => true, onError: (Object _) => false)));
    expect(results.where((value) => value), hasLength(1));
    final original = await one.read(scope); expect(original, isNotNull);
    account = 'foreign-owner';
    await expectLater(one.read(scope), throwsA(isA<WorkGatewayException>()));
    await expectLater(two.clear(original!), throwsA(isA<WorkGatewayException>()));
    account = scope.account;
    expect((await two.read(scope))!.fingerprint, original.fingerprint);
    await one.clear(original); expect(await two.read(scope), isNull);
  });

  StoreCouponDraftSyncController privateController(_PrivateDraftGateway gateway, _PrivateDraftPending journal,
    {Object? Function()? context}) => StoreCouponDraftSyncController(scope: scope, gateway: gateway,
      pendingStore: journal, context: context ?? () => 1);
  test('AGG09 private sync persists the original before dispatch and separates source CAS from native revision', () async {
    final gateway = _PrivateDraftGateway(), journal = _PrivateDraftPending();
    gateway.afterWrite = () async {expect(journal.original, isNotNull); expect(journal.original!.fingerprint, gateway.writes.single.fingerprint);};
    final controller = privateController(gateway, journal); addTearDown(controller.dispose);
    final draft = StoreCouponCampaign.fromJson({...richDraft().toJson(), 'revision': 27}, scope.store);
    expect((await controller.sync(draft, inputCurrent: () => true)).state, StorePromotionResultState.saved);
    expect(gateway.writes.single.expectedSourceRevision, 0); expect(gateway.writes.single.campaign.revision, 27);
    expect(gateway.effects, 1); expect(journal.original, isNull);
    expect(controller.lastAcknowledged!.sourceRevision, 1); expect(controller.lastAcknowledged!.campaign.revision, 27);
    expect(gateway.writes.single.body.containsKey('fundingAcknowledged'), isFalse);
  });
  for (final afterCommit in [false, true]) {
    test('AGG09 private journal failure blocks dispatch and reloads actual retained state afterCommit=$afterCommit', () async {
      final gateway = _PrivateDraftGateway(), journal = _PrivateDraftPending()
        ..failBeforeSave = !afterCommit ..failAfterSave = afterCommit;
      final controller = privateController(gateway, journal); addTearDown(controller.dispose);
      expect((await controller.sync(richDraft(), inputCurrent: () => true)).state, StorePromotionResultState.unknown);
      expect(gateway.writes, isEmpty); expect(controller.ready, isFalse);
      journal.failBeforeSave = false; journal.failAfterSave = false;
      expect(await controller.restore(), isTrue);
      expect(controller.pending != null, afterCommit);
      if (afterCommit) {
        expect((await controller.retryOriginal(confirmedOriginal: false)).state, StorePromotionResultState.unknown);
        expect(gateway.writes, isEmpty);
        expect((await controller.retryOriginal(confirmedOriginal: true)).state, StorePromotionResultState.saved);
      } else {
        expect((await controller.sync(richDraft(), inputCurrent: () => true)).state, StorePromotionResultState.saved);
      }
      expect(gateway.effects, 1); expect(journal.original, isNull);
    });
  }
  test('AGG09 private original recovery returns the immutable result rather than a later current head', () async {
    final gateway = _PrivateDraftGateway()..unknownWrite = true, journal = _PrivateDraftPending();
    final first = privateController(gateway, journal);
    expect((await first.sync(richDraft(), inputCurrent: () => true)).state, StorePromotionResultState.unknown);
    final original = journal.original!; first.dispose();
    gateway.head = gateway.acknowledge(StoreCouponDraftIntent(scope: scope, expectedSourceRevision: 1, idempotencyKey: 'later-host-save',
      campaign: StoreCouponCampaign.fromJson({...richDraft().toJson(), 'revision': 2, 'name': 'HOST later terms'}, scope.store)));
    final restarted = privateController(gateway, journal); addTearDown(restarted.dispose);
    expect(await restarted.restore(), isTrue); expect(restarted.pending!.fingerprint, original.fingerprint);
    expect((await restarted.reconcile()).state, StorePromotionResultState.saved);
    expect(restarted.lastAcknowledged!.sourceRevision, 1); expect(gateway.head!.sourceRevision, 2);
    expect(restarted.lastAcknowledged!.campaign.name, richDraft().name);
    expect(gateway.checks.single.fingerprint, original.fingerprint); expect(gateway.effects, 1); expect(journal.original, isNull);
  });
  for (final state in [StorePromotionResultState.notSent, StorePromotionResultState.rejected, StorePromotionResultState.unknown]) {
    test('AGG09 private unacknowledged recovery/retry cannot erase the original $state', () async {
      final gateway = _PrivateDraftGateway()..unknownWrite = true, journal = _PrivateDraftPending();
      final controller = privateController(gateway, journal); addTearDown(controller.dispose);
      await controller.sync(richDraft(), inputCurrent: () => true);
      final original = journal.original!;
      gateway.recoveryState = state; gateway.writeState = state;
      expect((await controller.reconcile()).state, StorePromotionResultState.unknown);
      expect((await controller.retryOriginal(confirmedOriginal: true)).state, StorePromotionResultState.unknown);
      expect(journal.original!.fingerprint, original.fingerprint);
      expect(gateway.writes.last.fingerprint, original.fingerprint); expect(gateway.effects, 1);
    });
  }
  test('AGG09 private busy/current-input fences prevent a second or stale dispatch', () async {
    final gateway = _PrivateDraftGateway(), journal = _PrivateDraftPending(), gate = Completer<void>(), entered = Completer<void>();
    gateway.beforeRead = () async {entered.complete(); await gate.future;};
    var current = true;
    final controller = privateController(gateway, journal); addTearDown(controller.dispose);
    final first = controller.sync(richDraft(), inputCurrent: () => current);
    await entered.future;
    expect((await controller.sync(richDraft(), inputCurrent: () => true)).state, StorePromotionResultState.notSent);
    current = false; gate.complete();
    expect((await first).state, StorePromotionResultState.notSent); expect(gateway.writes, isEmpty); expect(journal.original, isNull);
  });
  test('AGG09 private retained original survives retirement and failed durable clear without another effect', () async {
    final gateway = _PrivateDraftGateway(), journal = _PrivateDraftPending();
    Object? lifetime = Object();
    final controller = privateController(gateway, journal, context: () => lifetime);
    gateway.afterWrite = () async {lifetime = null;};
    expect((await controller.sync(richDraft(), inputCurrent: () => true)).state, StorePromotionResultState.unknown);
    expect(journal.original, isNotNull); controller.dispose();
    final restarted = privateController(gateway, journal); addTearDown(restarted.dispose);
    journal.failClear = true;
    expect((await restarted.reconcile()).state, StorePromotionResultState.unknown); expect(journal.original, isNotNull);
    journal.failClear = false;
    expect((await restarted.reconcile()).state, StorePromotionResultState.saved); expect(journal.original, isNull); expect(gateway.effects, 1);
  });
  test('AGG09 private expired campaign may sync as a draft but cannot authorize active publication', () async {
    final gateway = _PrivateDraftGateway(), journal = _PrivateDraftPending();
    final controller = privateController(gateway, journal); addTearDown(controller.dispose);
    final draft = StoreCouponCampaign.fromJson({...richDraft().toJson(), 'startsAt': DateTime.utc(2020).toIso8601String(),
      'endsAt': DateTime.utc(2020, 2).toIso8601String()}, scope.store);
    expect((await controller.sync(draft, inputCurrent: () => true)).state, StorePromotionResultState.saved);
    expect(() => StoreCouponInput.fromCampaign(draft, active: true).validateForSave(at), throwsFormatException);
  });

  WorkSession privateDraftOwner(Transport transport, _PrivateDraftPending journal, _RichOfferMemory book,
      {bool enabled = true, bool structured = false}) => WorkSession(gateway: _HostCouponWorkspaceGateway('retailer-grocery'),
    contactDraftStore: catalogue.ListingAccount(), offerDraftStoreFactory: (_) => book,
    storeCouponDraftPendingStoreFactory: (_) => journal,
    storeCouponPendingStoreFactory: (_) => CouponPending(),
    catalogueGateway: AuthenticatedWorkspaceCatalogueGateway(endpoint: Uri.parse(
      'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
      credentials: Credentials(), transport: transport, ownerAccountId: scope.account, realm: scope.realm,
      storeCouponDraftsSupported: enabled, storeCouponTermsV2Supported: structured))
    ..activeWorkspace = WorkWorkspace(id: scope.store, name: 'HOST private draft owner',
      profileLabel: 'Grocery', profileId: 'retailer-grocery', area: 'Jaipur', verified: true);
  for (final enabled in [false, true]) {
    test('AGG09 explicit native Save alone may queue configured private backing enabled=$enabled', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final transport = Transport(), journal = _PrivateDraftPending(), book = _RichOfferMemory();
      Map<String, Object?>? head;
      transport.reply = (body) async {
        expect(body['storeCouponDraftVersion'], 1);
        expect(body.containsKey('storeCouponTermsVersion'), isFalse);
        if (body['operation'] == 'saveStoreCouponDraft') {
          head = {'schemaVersion': 1, 'storeCouponDraftVersion': 1, 'accountId': scope.account,
            'realm': scope.realm, 'storeId': scope.store, 'couponId': body['couponId'],
            'sourceRevision': (body['expectedSourceRevision'] as int) + 1,
            'observedAt': DateTime.now().toUtc().toIso8601String(), 'campaign': body['campaign']};
        }
        return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': {
          'schemaVersion': 1, 'storeCouponDraftVersion': 1, 'accountId': scope.account,
          'realm': scope.realm, 'storeId': scope.store, 'observedAt': DateTime.now().toUtc().toIso8601String(),
          'publicationConfirmed': false, 'record': head}}));
      };
      final owner = privateDraftOwner(transport, journal, book, enabled: enabled); addTearDown(owner.dispose);
      expect(await owner.recoverWorkspaceAccount(accountReady: true), isTrue); await owner.refreshFeed();
      expect(owner.workspaceStoreAuthoringAvailable, isTrue);
      expect(await owner.loadWorkspaceOfferDraft(expectedStoreId: scope.store), isTrue);
      expect(owner.workspaceAssistantLoadedCouponDraftSync, isNull);
      expect(transport.bodies, isEmpty); expect(journal.original, isNull);
      final campaign = StoreCouponCampaign.fromJson({...richDraft().toJson(), 'revision': 1}, scope.store);
      expect(await owner.saveWorkspaceStoreCouponCampaign(campaign, expectedStoreId: scope.store), isTrue);
      await owner.waitForWorkspaceCouponDraftSync();
      expect(owner.workspaceStoreCouponCampaigns.single.toJson(), campaign.toJson());
      expect(transport.bodies.where((body) => body['operation'] == 'saveStoreCouponDraft'), hasLength(enabled ? 1 : 0));
      expect(transport.bodies.where((body) => body['operation'] == 'saveStoreCoupon'), isEmpty);
      expect(journal.original, isNull);
      expect(owner.workspaceAssistantLoadedCouponDraftSync?.lastAcknowledged?.sourceRevision, enabled ? 1 : null);
      final before = transport.bodies.length;
      expect(await owner.loadWorkspaceOfferDraft(expectedStoreId: scope.store), isTrue);
      await owner.waitForWorkspaceCouponDraftSync();
      expect(transport.bodies, hasLength(before));
    });
  }
  test('AGG09 a later local Save cannot replace an unresolved private original', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final transport = Transport(), journal = _PrivateDraftPending(), book = _RichOfferMemory();
    transport.reply = (body) async => body['operation'] == 'readStoreCouponDraft'
      ? SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': {
          'schemaVersion': 1, 'storeCouponDraftVersion': 1, 'accountId': scope.account,
          'realm': scope.realm, 'storeId': scope.store, 'observedAt': DateTime.now().toUtc().toIso8601String(),
          'publicationConfirmed': false, 'record': null}}))
      : SocialContentResponse(statusCode: 503, body: '{}');
    final owner = privateDraftOwner(transport, journal, book); addTearDown(owner.dispose);
    expect(await owner.recoverWorkspaceAccount(accountReady: true), isTrue); await owner.refreshFeed();
    expect(await owner.loadWorkspaceOfferDraft(expectedStoreId: scope.store), isTrue);
    final first = StoreCouponCampaign.fromJson({...richDraft().toJson(), 'revision': 1}, scope.store);
    expect(await owner.saveWorkspaceStoreCouponCampaign(first, expectedStoreId: scope.store), isTrue);
    await owner.waitForWorkspaceCouponDraftSync(); final original = journal.original!;
    final next = StoreCouponCampaign.fromJson({...first.toJson(), 'revision': 2, 'name': 'HOST later private edit'}, scope.store);
    expect(await owner.saveWorkspaceStoreCouponCampaign(next, expectedStoreId: scope.store), isTrue);
    await owner.waitForWorkspaceCouponDraftSync();
    expect(owner.workspaceStoreCouponCampaigns.single.toJson(), next.toJson());
    expect(journal.original!.fingerprint, original.fingerprint);
    expect(transport.bodies.where((body) => body['operation'] == 'saveStoreCouponDraft'), hasLength(1));
    expect(transport.bodies.where((body) => body['operation'] == 'reconcileStoreCouponDraft'), hasLength(1));
    expect(transport.bodies.where((body) => body['operation'] == 'saveStoreCoupon'), isEmpty);
  });

  final privateProofWire = Platform.environment['AGG09_COUPON_PRIVATE_CONTEXT_EXPORT_PATH'];
  test('AGG09 a legacy coupon ID resembling an opaque selector remains valid when private backing is off', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final transport = Transport(), journal = _PrivateDraftPending(), book = _RichOfferMemory(),
      campaign = StoreCouponCampaign.fromJson({...richDraft().toJson(), 'id': 'coupon-draft:${'a' * 64}'}, scope.store);
    final owner = privateDraftOwner(transport, journal, book, enabled: false); addTearDown(owner.dispose);
    expect(await owner.recoverWorkspaceAccount(accountReady: true), isTrue); await owner.refreshFeed();
    expect(owner.workspaceAssistantCouponEntityMatches(campaign, campaign.id), isTrue);
    expect(owner.workspaceAssistantCouponEntityMatches(campaign, null), isFalse);
    expect(transport.bodies, isEmpty);
  });
  test('AGG09 native selectors and source proofs match backend context for actual SDK originals', () {
    final wire = jsonDecode(File(privateProofWire!).readAsStringSync()) as Map;
    expect(wire['fixture'], 'ISOLATED HOST actual SDK originals and backend context proofs; never phone authority');
    for (final row in wire['drafts'] as List) {
      final record = StoreCouponDraftRecord.decode(row['record'], scope, at);
      expect(WorkSession.workspaceAssistantCouponDraftSelector(scope, record.couponId), row['selector']);
      expect(WorkSession.workspaceAssistantPrivateCouponSourceProof(record,
        publishedAvailable: row['publishedAvailable'] as bool, published: null), row['proof']);
    }
  }, skip: privateProofWire == null ? 'Requires actual SDK original/backend context qualification' : false);
  for (final mode in ['absent', 'unavailable', 'forbidden', 'malformed']) {
    test('AGG09 AI private capture is observational and separates original publication states $mode', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final transport = Transport(), journal = _PrivateDraftPending(), book = _RichOfferMemory(),
        campaign = StoreCouponCampaign.fromJson({...richDraft().toJson(), 'revision': 1}, scope.store),
        observed = DateTime.now().toUtc(), record = StoreCouponDraftRecord.decode({
          'schemaVersion': 1, 'storeCouponDraftVersion': 1, 'accountId': scope.account, 'realm': scope.realm,
          'storeId': scope.store, 'couponId': campaign.id, 'sourceRevision': 4,
          'observedAt': observed.toIso8601String(), 'campaign': campaign.toJson()}, scope, observed);
      book.values[scope.account] = {'schemaVersion': 1, 'storeId': scope.store,
        'fields': {'storeCouponCampaignsV1': encodeStoreCouponCampaigns([campaign])}};
      transport.reply = (body) async {
        if (body['operation'] == 'readStoreCouponDraft') return SocialContentResponse(statusCode: 200,
          body: jsonEncode({'ok': true, 'data': {'schemaVersion': 1, 'storeCouponDraftVersion': 1,
            'accountId': scope.account, 'realm': scope.realm, 'storeId': scope.store,
            'observedAt': observed.toIso8601String(), 'publicationConfirmed': false, 'record': {
              'schemaVersion': 1, 'storeCouponDraftVersion': 1, 'accountId': scope.account, 'realm': scope.realm,
              'storeId': scope.store, 'couponId': campaign.id, 'sourceRevision': 4,
              'observedAt': observed.toIso8601String(), 'campaign': campaign.toJson()}}}));
        expect(body['operation'], 'readStoreCoupon'); expect(body['storeCouponTermsVersion'], 2);
        if (mode != 'absent') return SocialContentResponse(statusCode: mode == 'unavailable' ? 503 : mode == 'forbidden' ? 403 : 200, body: '{}');
        return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': {
          'schemaVersion': 1, 'storeCouponTermsVersion': 2, 'realm': scope.realm, 'storeId': scope.store,
          'orderingAvailable': false, 'redemptionAvailable': false, 'publicationConfirmed': false, 'record': null}}));
      };
      final owner = privateDraftOwner(transport, journal, book, structured: true); addTearDown(owner.dispose);
      expect(await owner.recoverWorkspaceAccount(accountReady: true), isTrue); await owner.refreshFeed();
      final selector = WorkSession.workspaceAssistantCouponDraftSelector(scope, campaign.id),
        proof = WorkSession.workspaceAssistantPrivateCouponSourceProof(record, publishedAvailable: mode == 'absent', published: null),
        expected = {('AI-ACT-309', selector): proof, ('AI-ACT-310', selector): proof},
        before = jsonEncode(book.values);
      expect(owner.workspaceAssistantLoadedCouponDraftSync, isNull); expect(owner.workspaceAssistantLoadedCouponController, isNull);
      final ready = await owner.readWorkspaceAssistantOriginalCoupons(expected, accountUserId: scope.account,
        inputCurrent: () => true, validUntil: DateTime.now().add(const Duration(minutes: 1)));
      expect(ready, mode == 'absent' ? expected.keys.toSet() : mode == 'unavailable' ? {('AI-ACT-309', selector)} : isEmpty);
      expect(owner.workspaceAssistantLoadedCouponDraftSync, isNull); expect(owner.workspaceAssistantLoadedCouponController, isNull);
      expect(journal.original, isNull); expect(jsonEncode(book.values), before);
      expect(transport.bodies.every((body) => ['readStoreCouponDraft', 'readStoreCoupon'].contains(body['operation'])), isTrue);
    });
  }

  for (final scale in [1.0, 2.0]) {
    for (final outcome in ['cancel', 'confirm', 'retire']) {
      testWidgets('AGG09 private manager checks status and retries only the confirmed retained original $outcome text$scale', (tester) async {
        FlutterSecureStorage.setMockInitialValues({});
        tester.view.physicalSize = const Size(360, 800); tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset); addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final transport = Transport(), journal = _PrivateDraftPending(), book = _RichOfferMemory(),
          campaign = StoreCouponCampaign.fromJson({...richDraft().toJson(), 'revision': 1}, scope.store),
          later = StoreCouponCampaign.fromJson({...campaign.toJson(), 'revision': 2, 'name': 'HOST later private edits'}, scope.store),
          original = StoreCouponDraftIntent(scope: scope, expectedSourceRevision: 0,
            idempotencyKey: 'HOST-original-private-retry', campaign: campaign);
        journal.original = original;
        book.values[scope.account] = {'schemaVersion': 1, 'storeId': scope.store,
          'fields': {'storeCouponCampaignsV1': encodeStoreCouponCampaigns([later])}};
        transport.reply = (body) async {
          expect(body['storeCouponDraftVersion'], 1);
          if (body['operation'] == 'reconcileStoreCouponDraft') return SocialContentResponse(statusCode: 503, body: '{}');
          expect(body['operation'], 'saveStoreCouponDraft'); expect(body['campaign'], campaign.toJson());
          expect(body['idempotencyKey'], original.idempotencyKey); expect(body['expectedSourceRevision'], 0);
          return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': {
            'schemaVersion': 1, 'storeCouponDraftVersion': 1, 'accountId': scope.account, 'realm': scope.realm,
            'storeId': scope.store, 'observedAt': DateTime.now().toUtc().toIso8601String(), 'publicationConfirmed': false,
            'record': {'schemaVersion': 1, 'storeCouponDraftVersion': 1, 'accountId': scope.account, 'realm': scope.realm,
              'storeId': scope.store, 'couponId': campaign.id, 'sourceRevision': 1,
              'observedAt': DateTime.now().toUtc().toIso8601String(), 'campaign': body['campaign']}}}));
        };
        final owner = privateDraftOwner(transport, journal, book);
        var closed = false;
        void closeFixture() {if (!closed) {closed = true; owner.dispose();}}
        addTearDown(closeFixture);
        expect(await owner.recoverWorkspaceAccount(accountReady: true), isTrue); await owner.refreshFeed();
        final before = jsonEncode(book.values);
        await tester.pumpWidget(MaterialApp(home: Scaffold(body: ListView(children: [StoreCouponCampaignPanel(session: owner)]))));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('work-coupon-draft-save-status')), findsOneWidget);
        expect(transport.bodies, isEmpty); expect(journal.original!.fingerprint, original.fingerprint);
        final check = find.widgetWithText(TextButton, 'Check draft save');
        await tester.ensureVisible(check); await tester.pumpAndSettle(); await tester.tap(check); await tester.pumpAndSettle();
        expect(transport.bodies.map((body) => body['operation']), ['reconcileStoreCouponDraft']);
        expect(journal.original!.fingerprint, original.fingerprint);
        final retry = find.widgetWithText(TextButton, 'Retry original save');
        await tester.ensureVisible(retry); await tester.pumpAndSettle(); await tester.tap(retry); await tester.pumpAndSettle();
        expect(find.text('Retry saved draft?'), findsOneWidget);
        expect(find.textContaining(campaign.name), findsOneWidget);
        final confirm = find.widgetWithText(FilledButton, 'Retry original save');
        if (outcome == 'retire') {
          owner.activeWorkspace = WorkWorkspace(id: 'HOST-other-store', name: 'HOST other Store',
            profileId: 'retailer-grocery', profileLabel: 'Grocery', area: 'Jaipur', verified: true);
          owner.notifyListeners(); await tester.pumpAndSettle();
          expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
        }
        final action = outcome == 'confirm' ? confirm : find.widgetWithText(TextButton, 'Cancel');
        await tester.ensureVisible(action); await tester.pumpAndSettle(); await tester.tap(action); await tester.pumpAndSettle();
        expect(transport.bodies.where((body) => body['operation'] == 'saveStoreCouponDraft'), hasLength(outcome == 'confirm' ? 1 : 0));
        expect(journal.original?.fingerprint, outcome == 'confirm' ? null : original.fingerprint);
        expect(jsonEncode(book.values), before);
        if (outcome != 'retire') expect(owner.workspaceStoreCouponCampaigns.single.toJson(), later.toJson());
        expect(transport.bodies.where((body) => body['operation'] == 'saveStoreCoupon'), isEmpty);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink()); closeFixture(); await tester.pump();
      });
    }
  }

  final publicCouponWire = Platform.environment['AGG09_PUBLIC_COUPON_WIRE_EXPORT_PATH'];
  Map<String, dynamic> sdkPublicCouponWire() {
    final wire = Map<String, dynamic>.from(jsonDecode(File(publicCouponWire!).readAsStringSync()) as Map);
    expect(wire['fixture'], 'ISOLATED HOST actual SDK coupon originals with isolated original catalogue read ports; never phone authority');
    return wire;
  }
  AuthenticatedWorkspaceCatalogueGateway publicCouponConnection(Transport transport, DateTime clock,
      {bool rich = true, bool legacy = false}) => AuthenticatedWorkspaceCatalogueGateway(endpoint: Uri.parse(
        'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
      credentials: Credentials(), transport: transport, ownerAccountId: 'buyer-one', realm: scope.realm,
      storeCouponTermsV2Supported: rich, storeCouponTermsSupported: legacy, storeCouponEligibilitySupported: true, now: () => clock);
  final moneyCouponWire = Platform.environment['AGG09_MONEY_COUPON_WIRE_EXPORT_PATH'];
  test('AGG09 actual SDK structured money response crosses native decoding with original version and allocations', () {
    final wire=Map<String,dynamic>.from(jsonDecode(File(moneyCouponWire!).readAsStringSync()) as Map);
    expect(wire['fixture'],'ISOLATED HOST actual SDK v2 original coupon and usage with isolated original price port; never phone authority');
    final clock=DateTime.parse(wire['now'] as String),coupon=BuyV2PublishedStoreCoupon.decodeOfferDisplay(wire['offer'],now:clock),
      query=Map<String,Object?>.from(wire['query'] as Map)..remove('storeCouponEligibilityVersion'),
      items=(wire['page'] as Map)['items'] as List;
    final lines=[for(final raw in query['lines'] as List) () {
      final row=Map<String,dynamic>.from(raw as Map),identity=BuyV2PublicListingIdentity.fromJson(row['listing'])!,
        source=items.cast<Map>().singleWhere((item)=>item['skuId']==identity.skuId),channel=(source['channels'] as List).single as Map,
        template=catalogue.product;
      return BuyV2CartLine(product:BuyV2Product(id:row['lineId'] as String,canonicalId:identity.canonicalProductId,
        storeId:identity.storeId,publicListingIdentity:identity,offerClass:identity.channel,
        destination:identity.channel==BuyV2OfferClass.retail?BuyV2Destination.shop:BuyV2Destination.wholesale,
        categoryId:template.categoryId,brand:template.brand,title:(source['content'] as Map)['title'] as String,
        variant:'',pack:(source['pack'] as Map)['label'] as String,priceMinor:channel['priceMinor'] as int,
        unitPrice:template.unitPrice,badge:template.badge,seller:template.seller,sellerType:template.sellerType,
        deliveryPromise:template.deliveryPromise,origin:template.origin,confirmedOn:template.confirmedOn,
        visualLabel:template.visualLabel,visualKind:template.visualKind),quantity:row['quantity'] as int);
    }()];
    BuyV2StoreCouponEligibility decode(Object? data,{Map<String,Object?>? request,String? buyer}) =>
      BuyV2StoreCouponEligibility.decode(data,coupon:coupon,accountId:buyer??wire['buyer'] as String,
        query:request??query,lines:lines,now:clock);
    final result=decode(wire['result']);
    expect(result.eligible,isTrue);expect(result.savingMinor,1050);expect(result.subtotalMinor,20003);
    expect(result.allocations.values.reduce((a,b)=>a+b),1050);expect(result.matches(lines,clock),isTrue);
    expect(()=>decode(wire['result'],buyer:'foreign-buyer'),throwsFormatException);
    expect(()=>decode(wire['result'],request:Map<String,Object?>.from(query)..remove('storeCouponTermsVersion')),throwsFormatException);
    final missing=Map<String,dynamic>.from(wire['result'] as Map)..remove('storeCouponTermsVersion');
    expect(()=>decode(missing),throwsFormatException);
  },skip:moneyCouponWire==null?'Requires explicit actual SDK original structured money wire':false);
  test('AGG09 actual SDK mixed public coupon wire reaches the native original reader without granting eligibility', () async {
    final wire = sdkPublicCouponWire(), data = Map<String, dynamic>.from(wire['response'] as Map),
      clock = DateTime.parse(wire['now'] as String), transport = Transport();
    transport.reply = (body) async {
      expect(body, {'operation': 'readPublicStoreCouponSnapshot', 'storeId': scope.store,
        'storeCouponTermsVersion': 2, 'storeCouponSnapshotVersion': 1});
      return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': data}));
    };
    final connection = publicCouponConnection(transport, clock), source = WorkspaceStoreCatalogueSource(
      gateway: connection, storeId: scope.store, current: () => true);
    expect(source.storeCouponsActive, isTrue); expect(source.storeCouponEligibilityActive, isTrue);
    final rows = await source.loadStoreCoupons(storeId: scope.store);
    expect(rows, hasLength(7)); expect(rows.where((row) => row.structuredTerms != null), hasLength(6));
    expect(rows.where((row) => row.terms != null), hasLength(1));
    for (final row in rows.where((row) => row.structuredTerms != null)) {
      expect(row.viewerAccountId, isNull); expect(row.isCurrent(clock), isTrue);
      expect(BuyV2PublishedStoreCoupon.decodeOfferDisplay(row.toOfferDisplayJson(), now: clock).termsFingerprint, row.termsFingerprint);
      expect(jsonEncode(row.toOfferDisplayJson()).contains('buyerReferences'), isFalse);
    }
    expect(connection.forOwnerAccount('another-owner').storeCouponTermsV2Supported, isTrue);
    // Capability is not a saving: unsupported reward/history-dependent kinds
    // fail before any product or eligibility read, even on a v2 connection.
    final calls = transport.bodies.length;
    for (final row in rows.where((row) => row.structuredTerms != null &&
        !{BuyV2StoreOfferKind.billDiscount, BuyV2StoreOfferKind.productDiscount}.contains(row.structuredTerms!.kind))) {
      await expectLater(connection.evaluateStoreCoupon(coupon: row, lines: const [], current: () => true), throwsFormatException);
    }
    expect(transport.bodies.length, calls);
  }, skip: publicCouponWire == null ? 'Requires explicit actual SDK public projection wire' : false);
  for (final fault in ['private-field', 'digest', 'foreign-store', 'duplicate', 'incomplete']) {
    test('AGG09 native public structured read rejects incompatible source $fault', () async {
      final wire = sdkPublicCouponWire(), data = Map<String, dynamic>.from(wire['response'] as Map),
        clock = DateTime.parse(wire['now'] as String), transport = Transport(), items = data['items'] as List,
        rich = items.firstWhere((value) => (value as Map)['schemaVersion'] == 2) as Map;
      if (fault == 'private-field') rich['buyerReferences'] = ['HOST-private-record'];
      if (fault == 'foreign-store') rich['storeId'] = 'foreign-store';
      if (fault == 'duplicate') items.add(jsonDecode(jsonEncode(rich)));
      if (fault == 'incomplete') data['complete'] = false;
      if (fault == 'digest') {
        final selected = items.cast<Map>().firstWhere((row) => row['schemaVersion'] == 2 &&
          ((row['structuredTerms'] as Map)['skus'] as List).isNotEmpty);
        ((((selected['structuredTerms'] as Map)['skus'] as List).first as Map)['listings'] as List).first['listingId'] = 'listing-${'a' * 64}';
      }
      transport.reply = (_) async => SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': data}));
      final source = WorkspaceStoreCatalogueSource(gateway: publicCouponConnection(transport, clock), storeId: scope.store, current: () => true);
      await expectLater(source.loadStoreCoupons(storeId: scope.store), throwsA(anything));
      expect(transport.bodies.every((body) => body['operation'] == 'readPublicStoreCouponSnapshot'), isTrue);
    }, skip: publicCouponWire == null ? 'Requires explicit actual SDK public projection wire' : false);
  }
  test('AGG09 native public high-water cannot resurrect a same-revision changed rich copy', () async {
    final wire = sdkPublicCouponWire(), clock = DateTime.parse(wire['now'] as String), transport = Transport();
    var data = Map<String, dynamic>.from(wire['response'] as Map);
    transport.reply = (_) async => SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': data}));
    final source = WorkspaceStoreCatalogueSource(gateway: publicCouponConnection(transport, clock), storeId: scope.store, current: () => true);
    expect(await source.loadStoreCoupons(storeId: scope.store), hasLength(7));
    final rich = (data['items'] as List).cast<Map>().firstWhere((row) => row['schemaVersion'] == 2);
    rich['name'] = 'HOST changed without revision';
    await expectLater(source.loadStoreCoupons(storeId: scope.store), throwsFormatException);
    data = Map<String, dynamic>.from(sdkPublicCouponWire()['response'] as Map);
    await expectLater(source.loadStoreCoupons(storeId: scope.store), throwsFormatException);
  }, skip: publicCouponWire == null ? 'Requires explicit actual SDK public projection wire' : false);
  test('AGG09 native public reader never infers v2 capability from a server response', () async {
    final wire = sdkPublicCouponWire(), clock = DateTime.parse(wire['now'] as String), transport = Transport();
    transport.reply = (_) async => SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': wire['response']}));
    final legacy = WorkspaceStoreCatalogueSource(gateway: publicCouponConnection(transport, clock, rich: false, legacy: true), storeId: scope.store, current: () => true);
    await expectLater(legacy.loadStoreCoupons(storeId: scope.store), throwsFormatException);
    final before = transport.bodies.length,
      disabled = WorkspaceStoreCatalogueSource(gateway: publicCouponConnection(transport, clock, rich: false), storeId: scope.store, current: () => true);
    await expectLater(disabled.loadStoreCoupons(storeId: scope.store), throwsFormatException);
    expect(transport.bodies, hasLength(before));
  }, skip: publicCouponWire == null ? 'Requires explicit actual SDK public projection wire' : false);

  test('STRUCTUREDOFFER01 immutable exact SKU terms round trip without buyer leakage', () {
    final terms = offerTerms(kind: BuyV2StoreOfferKind.buyerDiscount);
    expect(BuyV2StoreOfferKind.values, hasLength(7));
    expect(BuyV2StoreOfferTerms.fromJson(terms.toJson()).toJson(), terms.toJson());
    expect(() => terms.skus.clear(), throwsUnsupportedError);
    expect(() => terms.channels.clear(), throwsUnsupportedError);
    final campaign = richDraft(kind: BuyV2StoreOfferKind.buyerDiscount);
    expect(campaign.buyerReferences, ['customer-one']);
    expect(jsonEncode(terms.toJson()), isNot(contains('customer-one')));
    expect(() => StoreCouponCampaign.offer(id: 'coupon-rich', storeId: 'other-store', revision: 1,
      name: campaign.name, structuredTerms: terms, buyerReferences: ['customer-one'],
      startsAt: at, endsAt: at.add(const Duration(days: 1)), totalUses: 20, usesPerCustomer: 1), throwsFormatException);
  });
  test('STRUCTUREDOFFER01 rejects foreign SKU and inconsistent quantity units', () {
    expect(() => BuyV2StoreOfferTerms(storeId: 'store-one', kind: BuyV2StoreOfferKind.productDiscount,
      skus: [offerSku('sku-one', store: 'other-store')], channels: {'retail'},
      discountKind: 'flat', discountValue: 100, maximumSavingMinor: 100), throwsFormatException);
    expect(() => BuyV2StoreOfferTerms(storeId: 'store-one', kind: BuyV2StoreOfferKind.quantityPrice,
      skus: [offerSku('sku-one'), offerSku('sku-two')], channels: {'wholesale'},
      tiers: [const BuyV2StoreOfferTier(minimumQuantity: 10, priceMinor: 10000)]), throwsFormatException);
    expect(() => BuyV2StoreOfferTerms(storeId: 'store-one', kind: BuyV2StoreOfferKind.extraQuantity,
      skus: [offerSku('sku-one')], channels: {'wholesale'}, buyQuantity: 10,
      rewardSku: offerSku('bonus-one', store: 'other-store'), rewardQuantity: 1), throwsFormatException);
  });
  test('STRUCTUREDOFFER01 tier thresholds must be unique ordered exact prices', () {
    final valid = BuyV2StoreOfferTerms(storeId: 'store-one', kind: BuyV2StoreOfferKind.quantityPrice,
      skus: [offerSku('sku-one')], channels: {'bulk'}, tiers: const [
        BuyV2StoreOfferTier(minimumQuantity: 10, priceMinor: 10000),
        BuyV2StoreOfferTier(minimumQuantity: 20, priceMinor: 9500)]);
    expect(BuyV2StoreOfferTerms.fromJson(valid.toJson()).toJson(), valid.toJson());
    for (final tiers in [
      [const BuyV2StoreOfferTier(minimumQuantity: 10, priceMinor: 10000), const BuyV2StoreOfferTier(minimumQuantity: 10, priceMinor: 9500)],
      [const BuyV2StoreOfferTier(minimumQuantity: 20, priceMinor: 10000), const BuyV2StoreOfferTier(minimumQuantity: 10, priceMinor: 9500)],
      [const BuyV2StoreOfferTier(minimumQuantity: 0, priceMinor: 10000)],
    ]) {
      expect(() => BuyV2StoreOfferTerms(storeId: 'store-one', kind: BuyV2StoreOfferKind.quantityPrice,
        skus: [offerSku('sku-one')], channels: {'bulk'}, tiers: tiers), throwsFormatException);
    }
  });
  StoreCouponCampaign couponDraft() => StoreCouponCampaign(id: 'coupon-one', storeId: scope.store,
    revision: 19, name: 'Host Diwali savings', percentage: false, discount: 1050,
    minimumSpendMinor: 10000, maximumSavingMinor: 1050, startsAt: at,
    endsAt: at.add(const Duration(days: 1)), totalUses: 20, usesPerCustomer: 1);
  StoreCouponIntent couponIntent({int expectedRevision = 0, String name = 'Host Diwali savings'}) => StoreCouponIntent(
    scope: scope, couponId: 'coupon-one', expectedRevision: expectedRevision, idempotencyKey: 'coupon-original',
    input: StoreCouponInput.fromJson({...StoreCouponInput.fromCampaign(couponDraft(), active: true).toJson(), 'name': name}),
    fundingAcknowledged: true);
  test('STRUCTUREDOFFER02 legacy private and pending wire identities survive mixed rich drafts', () {
    final legacy = couponDraft(), legacyJson = jsonEncode(couponDraft().toJson());
    final original = couponIntent();
    final originalJson = jsonEncode(original.toJson());
    final mixed = decodeStoreCouponCampaigns(encodeStoreCouponCampaigns([legacy, richDraft()]), 'store-one');
    expect(jsonEncode(mixed.first.toJson()), legacyJson);
    expect(mixed.last.structuredTerms!.toJson(), offerTerms().toJson());
    expect(jsonEncode(StoreCouponIntent.fromJson(jsonDecode(originalJson)).toJson()), originalJson);
    expect(jsonDecode(encodeStoreCouponCampaigns([legacy]))['schemaVersion'], 1);
    expect(jsonDecode(encodeStoreCouponCampaigns(mixed))['schemaVersion'], 2);
  });
  test('STRUCTUREDOFFER02 old publication capability never journals or sends rich terms', () async {
    final provider = CouponProvider(), pending = CouponPending();
    final controller = StoreCouponController(scope: scope, gateway: provider, pendingStore: pending,
      context: () => 1, now: () => at);
    addTearDown(controller.dispose);
    final campaign = richDraft();
    expect(await controller.refresh(campaign.id), isTrue);
    final result = await controller.submit(campaign.id,
      StoreCouponInput.fromCampaign(campaign, active: true), fundingAcknowledged: true, inputCurrent: () => true);
    expect(result.state, StorePromotionResultState.notSent);
    expect(provider.writes, isEmpty);
    expect(pending.original, isNull);
  });
  test('STRUCTUREDOFFER02 rich original has explicit wire version and Store fence', () {
    final input = StoreCouponInput.fromCampaign(richDraft(), active: true);
    final original = StoreCouponIntent(scope: scope, couponId: 'coupon-rich', expectedRevision: 0,
      idempotencyKey: 'rich-original', input: input, fundingAcknowledged: true);
    expect(original.toJson()['storeCouponTermsVersion'], 2);
    expect(original.body['storeCouponTermsVersion'], 2);
    expect(StoreCouponIntent.fromJson(original.toJson()).fingerprint, original.fingerprint);
    expect(() => StoreCouponIntent.fromJson({...original.toJson(), 'storeCouponTermsVersion': 1}), throwsFormatException);
    final foreign = StoreCouponInput.fromJson({...input.toJson(), 'structuredTerms': BuyV2StoreOfferTerms(
      storeId: 'other-store', kind: BuyV2StoreOfferKind.billDiscount, channels: {'retail'},
      discountKind: 'flat', discountValue: 100, maximumSavingMinor: 100).toJson()});
    expect(() => StoreCouponIntent(scope: scope, couponId: 'coupon-rich', expectedRevision: 0,
      idempotencyKey: 'rich-original', input: foreign, fundingAcknowledged: true), throwsFormatException);
  });
  test('STRUCTUREDOFFER02 rich owner receipt binds actor Store and exact original', () {
    final input = StoreCouponInput.fromCampaign(richDraft(), active: true);
    final original = StoreCouponIntent(scope: scope, couponId: 'coupon-rich', expectedRevision: 0,
      idempotencyKey: 'rich-original', input: input, fundingAcknowledged: true);
    final raw = <String, Object?>{'schemaVersion': 2, 'storeCouponTermsVersion': 2,
      'accountId': scope.account, 'realm': scope.realm, 'storeId': scope.store,
      'couponId': original.couponId, 'revision': 1, 'observedAt': at.toIso8601String(), 'coupon': input.toJson()};
    expect(StoreCouponRecord.decode(raw, scope, at).acknowledges(original), isTrue);
    for (final patch in [{'accountId': 'another-owner'}, {'storeId': 'other-store'}, {'storeCouponTermsVersion': 1}]) {
      expect(() => StoreCouponRecord.decode({...raw, ...patch}, scope, at), throwsFormatException);
    }
  });
  Future<WorkSession> openPrivateCouponEditor(WidgetTester tester, StoreCouponCampaign draft) async {
    FlutterSecureStorage.setMockInitialValues({});
    final owner = WorkSession(gateway: const UnavailableWorkGateway(), contactDraftStore: catalogue.ListingAccount(),
      offerDraftStoreFactory: (_) => catalogue.ListingAccount())
      ..activeWorkspace = WorkWorkspace(id: 'store-one', name: 'Host Store', profileLabel: 'Grocery',
        profileId: 'retailer-grocery', area: 'Jaipur', verified: true);
    addTearDown(owner.dispose);
    owner.workspaceCatalogueItems.addAll([catalogue.listingItem('sku-one'), catalogue.listingItem('reward-one')]);
    expect(await owner.loadWorkspaceOfferDraft(expectedStoreId: 'store-one'), isTrue);
    expect(await owner.saveWorkspaceStoreCouponCampaign(draft, expectedStoreId: 'store-one'), isTrue);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ListView(children: [StoreCouponCampaignPanel(session: owner)]))));
    await tester.pumpAndSettle();
    final edit = find.byTooltip('Edit ${draft.name}');
    await tester.ensureVisible(edit); await tester.pumpAndSettle();
    expect(edit.hitTestable(), findsOneWidget); await tester.tap(edit); await tester.pumpAndSettle();
    return owner;
  }
  testWidgets('COUPONCOMPACT02 invalid offscreen legacy amount cannot crash or write', (tester) async {
    tester.view.devicePixelRatio = 1; tester.view.physicalSize = const Size(320, 568);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset); addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final draft = StoreCouponCampaign.fromJson({...couponDraft().toJson(), 'revision': 1}, 'store-one');
    final owner = await openPrivateCouponEditor(tester, draft), before = jsonEncode(owner.workspaceOfferDraft);
    final scroll = find.descendant(of: find.byKey(const Key('work-coupon-editor')), matching: find.byType(Scrollable)).first;
    final amount = find.byKey(const Key('work-coupon-discount'));
    await tester.scrollUntilVisible(amount, 180, scrollable: scroll); await tester.enterText(amount, '10.255');
    FocusManager.instance.primaryFocus?.unfocus(); await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('work-coupon-customer-uses')), 220, scrollable: scroll);
    await tester.pumpAndSettle(); await tester.tap(find.byKey(const Key('work-coupon-save'))); await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('work-coupon-editor')), findsOneWidget);
    expect(jsonEncode(owner.workspaceOfferDraft), before);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('COUPONCOMPACT01 normal phone pairs financial date and usage controls', (tester) async {
    tester.view.devicePixelRatio = 1; tester.view.physicalSize = const Size(360, 806);
    addTearDown(tester.view.reset);
    final owner = await openPrivateCouponEditor(tester, richDraft(kind: BuyV2StoreOfferKind.billDiscount));
    final before = jsonEncode(owner.workspaceOfferDraft);
    final scroll = find.descendant(of: find.byKey(const Key('work-coupon-editor')), matching: find.byType(Scrollable)).first;
    final discount = find.byKey(const Key('work-coupon-discount'));
    await tester.scrollUntilVisible(discount, 160, scrollable: scroll); await tester.pumpAndSettle();
    final kind = find.byType(SegmentedButton<bool>);
    expect((tester.getTopLeft(discount).dy - tester.getTopLeft(kind).dy).abs(), lessThanOrEqualTo(4));
    final start = find.byKey(const Key('work-coupon-start')), end = find.byKey(const Key('work-coupon-end'));
    await tester.scrollUntilVisible(end, 160, scrollable: scroll);
    expect((tester.getTopLeft(start).dy - tester.getTopLeft(end).dy).abs(), lessThanOrEqualTo(4));
    final total = find.byKey(const Key('work-coupon-total-uses')), per = find.byKey(const Key('work-coupon-customer-uses'));
    await tester.scrollUntilVisible(per, 160, scrollable: scroll);
    expect((tester.getTopLeft(total).dy - tester.getTopLeft(per).dy).abs(), lessThanOrEqualTo(4));
    expect(tester.takeException(), isNull); expect(jsonEncode(owner.workspaceOfferDraft), before);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  for (final scale in [1.0, 2.0]) {
    testWidgets('COUPONCOMPACT03 slab viewport and keyboard retain unit and reachable action $scale', (tester) async {
      tester.view.devicePixelRatio = 1; tester.view.physicalSize = scale == 1 ? const Size(360, 806) : const Size(320, 640);
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.reset); addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final owner = await openPrivateCouponEditor(tester, richDraft(kind: BuyV2StoreOfferKind.quantityPrice));
      final before = jsonEncode(owner.workspaceOfferDraft);
      final scroll = find.descendant(of: find.byKey(const Key('work-coupon-editor')), matching: find.byType(Scrollable)).first;
      final tiers = find.byKey(const Key('work-coupon-tiers'));
      await tester.scrollUntilVisible(tiers, 180, scrollable: scroll); await tester.ensureVisible(tiers); await tester.pumpAndSettle();
      await tester.tap(tiers); await tester.pumpAndSettle();
      if (scale == 1) expect(tester.getSize(find.byType(Scaffold).last).height, lessThanOrEqualTo(440));
      expect(find.textContaining('1 L'), findsWidgets);
      final rows = find.byKey(const Key('work-coupon-tier-rows'));
      final fields = find.descendant(of: rows, matching: find.byType(TextFormField));
      expect(fields, findsNWidgets(2));
      if (scale == 1) expect((tester.getTopLeft(fields.first).dy - tester.getTopLeft(fields.last).dy).abs(), lessThanOrEqualTo(4));
      await tester.ensureVisible(fields.last); await tester.pumpAndSettle(); await tester.showKeyboard(fields.last);
      tester.view.viewInsets = const FakeViewPadding(bottom: 260); await tester.pumpAndSettle();
      final use = find.widgetWithText(FilledButton, 'Use price slabs');
      expect(use.hitTestable(), findsOneWidget); expect(tester.getSize(use).height, greaterThanOrEqualTo(48));
      expect(tester.getBottomRight(use).dy, lessThanOrEqualTo((scale == 1 ? 806 : 640) - 260));
      expect(tester.takeException(), isNull);
      tester.testTextInput.hide(); tester.view.resetViewInsets(); await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Cancel price slabs')); await tester.pumpAndSettle();
      expect(jsonEncode(owner.workspaceOfferDraft), before); await tester.pumpWidget(const SizedBox.shrink());
    });
    testWidgets('COUPONNAME01 tappable names remain editable without changing saved terms $scale', (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      tester.view.devicePixelRatio = 1; tester.view.physicalSize = const Size(360, 800);
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.reset); addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final owner = WorkSession(gateway: const UnavailableWorkGateway(), contactDraftStore: catalogue.ListingAccount(),
        offerDraftStoreFactory: (_) => catalogue.ListingAccount())
        ..activeWorkspace = WorkWorkspace(id: 'store-one', name: 'Host Store', profileLabel: 'Grocery',
          profileId: 'retailer-grocery', area: 'Jaipur', verified: true);
      addTearDown(owner.dispose);
      owner.workspaceCatalogueItems.add(catalogue.listingItem('sku-one'));
      expect(await owner.loadWorkspaceOfferDraft(expectedStoreId: 'store-one'), isTrue);
      final draft = richDraft(kind: BuyV2StoreOfferKind.billDiscount);
      expect(await owner.saveWorkspaceStoreCouponCampaign(draft, expectedStoreId: 'store-one'), isTrue);
      final before = jsonEncode(owner.workspaceOfferDraft);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: ListView(children: [StoreCouponCampaignPanel(session: owner)]))));
      await tester.pumpAndSettle(); await tester.tap(find.byTooltip('Edit ${draft.name}')); await tester.pumpAndSettle();
      final scrollable = find.descendant(of: find.byKey(const Key('work-coupon-editor')), matching: find.byType(Scrollable)).first;
      final name = find.byKey(const Key('work-coupon-name'));
      await tester.scrollUntilVisible(name, 160, scrollable: scrollable);
      final controller = tester.widget<TextFormField>(name).controller!;
      for (final example in ['Diwali offer', 'Holi offer']) {
        final chip = find.byKey(ValueKey('work-coupon-name-example-$example'));
        await tester.scrollUntilVisible(chip, 160, scrollable: scrollable);
        await tester.ensureVisible(chip); await tester.pumpAndSettle();
        expect(chip.hitTestable(), findsOneWidget);
        await tester.tap(chip); await tester.pumpAndSettle();
        expect(controller.text, example);
      }
      await tester.scrollUntilVisible(name, -160, scrollable: scrollable);
      await tester.ensureVisible(name); await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Edit coupon name')); await tester.pump();
      await tester.enterText(name, 'My Diwali trade offer');
      expect(controller.text, 'My Diwali trade offer');
      FocusManager.instance.primaryFocus?.unfocus(); await tester.pumpAndSettle();
      final all = find.byKey(const Key('work-coupon-scope-all'));
      await tester.scrollUntilVisible(all, 160, scrollable: scrollable);
      await tester.ensureVisible(all); await tester.pumpAndSettle(); await tester.tap(all); await tester.pumpAndSettle();
      expect(tester.widget<ChoiceChip>(all).selected, isTrue);
      final selected = find.byKey(const Key('work-coupon-scope-selected'));
      await tester.ensureVisible(selected); await tester.pumpAndSettle(); await tester.tap(selected); await tester.pumpAndSettle();
      expect(tester.widget<ChoiceChip>(selected).selected, isTrue);
      final products = find.byKey(const Key('work-coupon-products'));
      await tester.scrollUntilVisible(products, 160, scrollable: scrollable);
      expect(products.hitTestable(), findsOneWidget);
      await tester.tap(find.byTooltip('Close coupon editor')); await tester.pumpAndSettle();
      await tester.tap(find.text('Leave')); await tester.pumpAndSettle();
      expect(jsonEncode(owner.workspaceOfferDraft), before);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  test('STRUCTUREDOFFER08 all rich drafts reopen from durable storage and recover unknown saves', () async {
    FlutterSecureStorage.setMockInitialValues({});
    for (final kind in BuyV2StoreOfferKind.values) {
      final memory = _RichOfferMemory();
      WorkSession open() => WorkSession(gateway: const UnavailableWorkGateway(), contactDraftStore: memory,
        offerDraftStoreFactory: (_) => memory)
        ..activeWorkspace = WorkWorkspace(id: 'store-one', name: 'Host Store', profileLabel: 'Grocery',
          profileId: 'retailer-grocery', area: 'Jaipur', verified: true);
      final owner = open();
      try {
        expect(await owner.loadWorkspaceOfferDraft(expectedStoreId: 'store-one'), isTrue);
        memory.unknownSave = true;
        expect(await owner.saveWorkspaceStoreCouponCampaign(richDraft(kind: kind), expectedStoreId: 'store-one'), isFalse);
        expect(owner.workspaceStoreCouponRecoveryRequired, isTrue);
        memory.unknownSave = false;
        expect(await owner.loadWorkspaceOfferDraft(expectedStoreId: 'store-one'), isTrue);
        expect(owner.workspaceStoreCouponRecoveryRequired, isFalse);
        expect(owner.workspaceStoreCouponCampaigns.single.toJson(), richDraft(kind: kind).toJson());
        final reopened = open();
        try {
          expect(await reopened.loadWorkspaceOfferDraft(expectedStoreId: 'store-one'), isTrue);
          expect(reopened.workspaceStoreCouponCampaigns.single.toJson(), richDraft(kind: kind).toJson());
          memory.owner = 'other-owner';
          expect(await reopened.saveWorkspaceStoreCouponCampaign(richDraft(kind: kind), expectedStoreId: 'store-one'), isFalse);
        } finally { reopened.dispose(); }
      } finally { owner.dispose(); }
    }
  });
  testWidgets('STRUCTUREDOFFER04 renamed quantity offer cannot inherit a changed selling unit', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    final owner = WorkSession(gateway: const UnavailableWorkGateway(), contactDraftStore: catalogue.ListingAccount(),
      offerDraftStoreFactory: (_) => catalogue.ListingAccount())
      ..activeWorkspace = WorkWorkspace(id: 'store-one', name: 'Host Store', profileLabel: 'Grocery',
        profileId: 'retailer-grocery', area: 'Jaipur', verified: true);
    addTearDown(owner.dispose);
    owner.workspaceCatalogueItems.add(catalogue.listingItem('sku-one').copyWith(pack: '5 L'));
    expect(await owner.loadWorkspaceOfferDraft(expectedStoreId: 'store-one'), isTrue);
    final draft = richDraft(kind: BuyV2StoreOfferKind.quantityPrice);
    expect(await owner.saveWorkspaceStoreCouponCampaign(draft, expectedStoreId: 'store-one'), isTrue);
    final before = jsonEncode(owner.workspaceOfferDraft);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ListView(children: [StoreCouponCampaignPanel(session: owner)]))));
    await tester.pumpAndSettle(); await tester.tap(find.byTooltip('Edit ${draft.name}')); await tester.pumpAndSettle();
    final name = find.byKey(const Key('work-coupon-name'));
    await tester.ensureVisible(name); await tester.enterText(name, 'Host renamed offer');
    FocusManager.instance.primaryFocus?.unfocus(); await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-coupon-save'))); await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-coupon-editor')), findsOneWidget);
    expect(jsonEncode(owner.workspaceOfferDraft), before);
    final error = find.textContaining('Selling unit changed');
    await tester.scrollUntilVisible(error, 180, scrollable: find.descendant(
      of: find.byKey(const Key('work-coupon-editor')), matching: find.byType(Scrollable)).first);
    expect(error.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  for (final kind in BuyV2StoreOfferKind.values) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('STRUCTUREDOFFER03 compact editor fields preserve ${kind.name} $scale', (tester) async {
        FlutterSecureStorage.setMockInitialValues({});
        tester.view.devicePixelRatio = 1; tester.view.physicalSize = const Size(360, 806);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset); addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final owner = WorkSession(gateway: const UnavailableWorkGateway(), contactDraftStore: catalogue.ListingAccount(),
          offerDraftStoreFactory: (_) => catalogue.ListingAccount())
          ..activeWorkspace = WorkWorkspace(id: 'store-one', name: 'Host Store', profileLabel: 'Grocery',
            profileId: 'retailer-grocery', area: 'Jaipur', verified: true);
        addTearDown(owner.dispose);
        owner.workspaceCatalogueItems.addAll([catalogue.listingItem('sku-one'), catalogue.listingItem('reward-one')]);
        expect(await owner.loadWorkspaceOfferDraft(expectedStoreId: 'store-one'), isTrue);
        final draft = richDraft(kind: kind);
        expect(await owner.saveWorkspaceStoreCouponCampaign(draft, expectedStoreId: 'store-one'), isTrue);
        final before = jsonEncode(owner.workspaceOfferDraft);
        await tester.pumpWidget(MaterialApp(home: Scaffold(body: ListView(children: [StoreCouponCampaignPanel(session: owner)]))));
        await tester.pumpAndSettle();
        final edit = find.byTooltip('Edit ${draft.name}'); await tester.ensureVisible(edit);
        await tester.tap(edit); await tester.pumpAndSettle();
        expect(find.byKey(const Key('work-coupon-type')), findsOneWidget);
        expect(find.text(kind.label), findsWidgets);
        final expected = switch (kind) {
          BuyV2StoreOfferKind.quantityPrice => 'work-coupon-tiers',
          BuyV2StoreOfferKind.extraQuantity => 'work-coupon-buy-quantity',
          BuyV2StoreOfferKind.nextPurchase => 'work-coupon-next-days',
          BuyV2StoreOfferKind.buyerDiscount => 'work-coupon-buyers',
          _ => 'work-coupon-discount',
        };
        final field = find.byKey(Key(expected));
        await tester.scrollUntilVisible(field, 180, scrollable: find.descendant(
          of: find.byKey(const Key('work-coupon-editor')), matching: find.byType(Scrollable)).first);
        await tester.ensureVisible(field); await tester.pumpAndSettle();
        expect(field.hitTestable(), findsOneWidget);
        if (!draft.structuredTerms!.hasMonetaryDiscount) {
          expect(find.byKey(const Key('work-coupon-discount')), findsNothing);
        }
        final save = find.byKey(const Key('work-coupon-save'));
        expect(save.hitTestable(), findsOneWidget); expect(tester.getSize(save).height, greaterThanOrEqualTo(48));
        await tester.tap(find.byTooltip('Close coupon editor')); await tester.pumpAndSettle();
        expect(jsonEncode(owner.workspaceOfferDraft), before);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
  Map<String, dynamic> couponRecord(StoreCouponIntent original) => {...original.input.toJson(),
    'schemaVersion': 1, 'realm': scope.realm, 'storeId': scope.store, 'couponId': original.couponId,
    'revision': original.expectedRevision + 1, 'observedAt': at.toIso8601String()};
  SocialContentResponse couponResponse(Object? record, {Map<String, Object?>? extra}) => SocialContentResponse(
    statusCode: 200, body: jsonEncode({'ok': true, 'data': {'schemaVersion': 1,
      'storeCouponTermsVersion': 1, 'realm': scope.realm, 'storeId': scope.store,
      'orderingAvailable': false, 'redemptionAvailable': false, 'publicationConfirmed': false,
      if (extra == null) 'record': record, ...?extra}}));
  AuthenticatedStorePromotionGateway couponGateway(Credentials credentials, Transport transport,
    {bool enabled = true, DateTime Function()? clock}) => AuthenticatedStorePromotionGateway(
      endpoint: Uri.parse('https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
      credentials: credentials, transport: transport, ownerAccountId: scope.account, realm: scope.realm,
      benefitTermsSupported: true, storeCouponTermsSupported: enabled, now: clock ?? () => at);

  for (final scale in [1.0, 2.0]) {
    for (final keyboard in [false, true]) {
      testWidgets('COUPONFOOTER01 exported editor action $scale keyboard=$keyboard', (tester) async {
        FlutterSecureStorage.setMockInitialValues({});
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(360, 806);
        tester.view.viewPadding = const FakeViewPadding(top: 41, bottom: 44);
        tester.view.padding = const FakeViewPadding(top: 41, bottom: 44);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final owner = WorkSession(
          gateway: const UnavailableWorkGateway(),
          contactDraftStore: catalogue.ListingAccount(),
          offerDraftStoreFactory: (_) => catalogue.ListingAccount(),
        )..activeWorkspace = WorkWorkspace(id: scope.store, name: 'Host Store',
          profileLabel: 'Grocery', profileId: 'retailer-grocery', area: 'Jaipur', verified: true);
        addTearDown(owner.dispose);
        expect(await owner.loadWorkspaceOfferDraft(expectedStoreId: scope.store), isTrue);
        final campaign = StoreCouponCampaign.fromJson({...couponDraft().toJson(), 'revision': 1,
          'endsAt': DateTime.utc(2027).toIso8601String()}, scope.store);
        expect(await owner.saveWorkspaceStoreCouponCampaign(campaign, expectedStoreId: scope.store), isTrue);
        final before = jsonEncode(owner.workspaceOfferDraft);
        await tester.pumpWidget(MaterialApp(home: Scaffold(body: ListView(
          children: [StoreCouponCampaignPanel(session: owner)]))));
        await tester.pumpAndSettle();
        final edit = find.byTooltip('Edit ${campaign.name}');
        await tester.ensureVisible(edit);
        await tester.pumpAndSettle();
        expect(edit.hitTestable(), findsOneWidget);
        await tester.tap(edit);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('work-coupon-editor')), findsOneWidget);
        if (keyboard) {
          final name = find.byKey(const Key('work-coupon-name'));
          await tester.scrollUntilVisible(name, 150, scrollable: find.descendant(
            of: find.byKey(const Key('work-coupon-editor')), matching: find.byType(Scrollable)).first);
          await tester.pumpAndSettle();
          await tester.showKeyboard(name);
          tester.view.viewInsets = const FakeViewPadding(bottom: 300);
          tester.view.padding = const FakeViewPadding(top: 41);
          await tester.pumpAndSettle();
        }
        final save = find.byKey(const Key('work-coupon-save'));
        expect(save.hitTestable(), findsOneWidget);
        expect(tester.getSize(save).height, greaterThanOrEqualTo(48));
        expect(tester.getBottomRight(save).dy, lessThanOrEqualTo(keyboard ? 506.0 : 721.0),
          reason: 'The whole coupon action must fit inside the exported Android window.');
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('Close coupon editor'));
        tester.testTextInput.hide();
        tester.view.resetViewInsets();
        tester.view.padding = const FakeViewPadding(top: 41, bottom: 44);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('work-coupon-editor')), findsNothing);
        expect(jsonEncode(owner.workspaceOfferDraft), before);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  test('LF04 STORE COUPON exact frozen original excludes private revision and requires funding', () {
    final original = couponIntent(), bytes = original.fingerprint;
    final map = original.input.toJson()..['name'] = 'Later change';
    expect(map['name'], 'Later change'); expect(original.fingerprint, bytes);
    expect(original.expectedRevision, 0); expect(original.body.containsKey('revision'), isFalse);
    expect(original.body['coupon'], isNot(contains('revision')));
    expect(StoreCouponIntent.fromJson(jsonDecode(bytes)).fingerprint, bytes);
    expect(() => StoreCouponIntent(scope: scope, couponId: 'coupon-one', expectedRevision: 0,
      idempotencyKey: 'original-one', input: original.input, fundingAcknowledged: false), throwsFormatException);
    expect(() => StoreCouponIntent.fromJson({...original.toJson(), 'fundingAcknowledged': 'true'}), throwsFormatException);
  });
  for (final patch in <Map<String, Object?>>[
    {'name': 'Diwali\nsavings'}, {'discount': 10.5}, {'totalUses': '20'}, {'active': 1},
    {'maximumSavingMinor': 1051}, {'appliedSavingMinor': 1050},
  ]) {
    test('LF04 STORE COUPON invalid typed input ${patch.keys.first}', () {
      expect(() => StoreCouponInput.fromJson({...couponIntent().input.toJson(), ...patch}), throwsFormatException);
    });
  }
  test('LF04 STORE COUPON negotiated owner save read and original reconcile keep old SKU negotiation separate', () async {
    final creds = Credentials(), transport = Transport(), original = couponIntent();
    transport.reply = (_) async => couponResponse(couponRecord(original));
    final subject = couponGateway(creds, transport);
    expect((await subject.saveCoupon(original, () => true)).state, StorePromotionResultState.saved);
    expect((await subject.readCoupon(scope, original.couponId, () => true))!.revision, 1);
    expect((await subject.reconcileCoupon(original, () => true)).record!.acknowledges(original), isTrue);
    expect(creds.modes, [SocialAppCheckTokenMode.limitedUse, SocialAppCheckTokenMode.standard, SocialAppCheckTokenMode.standard]);
    expect(transport.bodies.map((b) => b['operation']), ['saveStoreCoupon', 'readStoreCoupon', 'reconcileStoreCoupon']);
    for (final body in transport.bodies) {
      expect(body['storeCouponTermsVersion'], 1); expect(body.containsKey('promotionTermsVersion'), isFalse);
      expect(body.containsKey('skuId'), isFalse);
    }
    expect(transport.bodies.first['coupon'], original.input.toJson());
    expect(transport.bodies.last['coupon'], original.input.toJson());
  });
  test('LF04 STORE COUPON unsupported capability and retired account send nothing', () async {
    final creds = Credentials(), transport = Transport(), original = couponIntent();
    expect((await couponGateway(creds, transport, enabled: false).saveCoupon(original, () => true)).state, StorePromotionResultState.notSent);
    expect(transport.bodies, isEmpty); expect(creds.modes, isEmpty);
    var current = true;
    creds.tokenWait = () async {current = false;};
    expect((await couponGateway(creds, transport).saveCoupon(original, () => current)).state, StorePromotionResultState.notSent);
    expect(transport.bodies, isEmpty);
  });
  for (final fault in ['transport', 'absent', 'wrong coupon', 'later revision', 'changed terms', 'retired', 'claim']) {
    test('LF04 STORE COUPON uncertain $fault result stays held for original reconciliation', () async {
      final creds = Credentials(), transport = Transport(), original = couponIntent(); var current = true;
      transport.reply = (_) async {
        if (fault == 'transport') throw StateError('Host connection dropped');
        final record = couponRecord(original);
        if (fault == 'wrong coupon') record['couponId'] = 'coupon-two';
        if (fault == 'later revision') record['revision'] = 2;
        if (fault == 'changed terms') record['name'] = 'Later campaign';
        if (fault == 'retired') current = false;
        if (fault == 'claim') { return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true,
          'data': {'schemaVersion': 1, 'storeCouponTermsVersion': 1, 'realm': scope.realm, 'storeId': scope.store,
            'orderingAvailable': false, 'redemptionAvailable': true, 'publicationConfirmed': false, 'record': record}})); }
        return couponResponse(fault == 'absent' ? null : record);
      };
      final subject = couponGateway(creds, transport);
      expect((await subject.saveCoupon(original, () => current)).state, StorePromotionResultState.unknown);
      expect(transport.bodies.length, 1, reason: 'Never retry or switch to a replacement operation automatically.');
    });
  }
  test('LF04 STORE COUPON original expiry does not block historical recovery; stale new save is unsent', () async {
    final creds = Credentials(), transport = Transport(), original = couponIntent();
    transport.reply = (_) async => couponResponse(couponRecord(original));
    final subject = couponGateway(creds, transport, clock: () => at.add(const Duration(days: 2)));
    expect((await subject.saveCoupon(original, () => true)).state, StorePromotionResultState.notSent);
    expect(transport.bodies, isEmpty);
    expect((await subject.reconcileCoupon(original, () => true)).state, StorePromotionResultState.saved);
    expect(transport.bodies.single['operation'], 'reconcileStoreCoupon');
  });
  test('LF04 STORE COUPON owner page validates order cursor and immutable Store scope', () async {
    final creds = Credentials(), transport = Transport(), original = couponIntent();
    transport.reply = (_) async => couponResponse(null, extra: {'items': [couponRecord(original)], 'nextCursor': 'coupon-one'});
    final subject = couponGateway(creds, transport);
    final page = await subject.listCoupons(scope, () => true, limit: 1);
    expect(page.records.single.couponId, original.couponId); expect(page.nextCursor, 'coupon-one');
    expect(() => page.records.clear(), throwsUnsupportedError);
    transport.reply = (_) async => couponResponse(null, extra: {'items': [couponRecord(original)], 'nextCursor': null});
    await expectLater(subject.listCoupons(scope, () => true, limit: 1), throwsFormatException);
    transport.reply = (_) async => couponResponse(null, extra: {'items': [{...couponRecord(original), 'storeId': 'store-two'}], 'nextCursor': null});
    await expectLater(subject.listCoupons(scope, () => true), throwsFormatException);
  });
  test('LF04 STORE COUPON secure original survives restart and cannot overwrite SKU or another original', () async {
    TestWidgetsFlutterBinding.ensureInitialized(); FlutterSecureStorage.setMockInitialValues({});
    final first = SecureStoreCouponPendingStore(currentAccount: () => scope.account), original = couponIntent();
    final sku = SecureStorePromotionPendingStore(currentAccount: () => scope.account);
    await sku.save(intent()); await first.save(original);
    final restart = SecureStoreCouponPendingStore(currentAccount: () => scope.account);
    expect((await restart.read(scope))?.fingerprint, original.fingerprint);
    await expectLater(restart.save(couponIntent(name: 'Other original')), throwsFormatException);
    await expectLater(restart.clear(couponIntent(name: 'Other original')), throwsFormatException);
    expect((await sku.read(scope))?.fingerprint, intent().fingerprint);
    await restart.clear(original); expect(await first.read(scope), isNull);
    expect((await sku.read(scope))?.fingerprint, intent().fingerprint);
  });
  test('LF04 STORE COUPON concurrent journal instances preserve exactly one original', () async {
    TestWidgetsFlutterBinding.ensureInitialized(); FlutterSecureStorage.setMockInitialValues({});
    final first = SecureStoreCouponPendingStore(currentAccount: () => scope.account),
      second = SecureStoreCouponPendingStore(currentAccount: () => scope.account);
    final originals = [couponIntent(), couponIntent(name: 'Competing coupon')];
    final outcomes = await Future.wait([first.save(originals[0]), second.save(originals[1])]
      .map((pending) async {try {await pending; return true;} catch (_) {return false;}}));
    expect(outcomes.where((saved) => saved).length, 1);
    final retained = await second.read(scope);
    expect(retained!.fingerprint, originals[0].fingerprint);
  });
  test('LF04 STORE COUPON secure journal isolates scope and preserves malformed original for recovery', () async {
    TestWidgetsFlutterBinding.ensureInitialized(); FlutterSecureStorage.setMockInitialValues({});
    var account = scope.account;
    final journal = SecureStoreCouponPendingStore(currentAccount: () => account), original = couponIntent();
    await journal.save(original);
    expect(await journal.read((account: scope.account, store: 'store-two', realm: scope.realm)), isNull);
    expect(await journal.read((account: scope.account, store: scope.store, realm: 'production')), isNull);
    account = 'owner-two'; await expectLater(journal.read(scope), throwsA(isA<WorkGatewayException>()));
    account = scope.account;
    const storage = FlutterSecureStorage(); final values = await storage.readAll();
    expect(values.length, 1);
    final raw = jsonDecode(values.values.single) as Map<String, dynamic>;
    (raw['original'] as Map<String, dynamic>)['storeCouponTermsVersion'] = 2;
    final corrupted = jsonEncode(raw); await storage.write(key: values.keys.single, value: corrupted);
    await expectLater(journal.read(scope), throwsFormatException);
    await expectLater(journal.clear(original), throwsFormatException);
    expect((await storage.readAll()).values.single, corrupted, reason: 'Do not erase an unknown saved contract.');
  });
  StoreCouponController couponController(CouponPending journal, CouponProvider provider, {Object? Function()? context}) =>
    StoreCouponController(scope: scope, gateway: provider, pendingStore: journal, context: context ?? () => 1, now: () => at);
  test('LF04 STORE COUPON controller persists before dispatch and uses server CAS not private revision', () async {
    final journal = CouponPending(), provider = CouponProvider(), original = couponIntent();
    final subject = couponController(journal, provider); addTearDown(subject.dispose);
    expect(await subject.refresh(original.couponId), isTrue);
    provider.afterWrite = () async {expect(journal.original!.fingerprint, provider.writes.single.fingerprint);};
    final saved = await subject.submit(original.couponId, original.input, fundingAcknowledged: true, inputCurrent: () => true);
    expect(saved.state, StorePromotionResultState.saved); expect(provider.writes.single.expectedRevision, 0);
    expect(journal.original, isNull); expect(subject.loadedCouponId, isNull);
    expect(subject.lastAcknowledged!.revision, 1); expect(subject.currentRecord, isNull);
    expect(await subject.refresh(original.couponId), isTrue); expect(subject.currentRecord!.revision, 1);
  });
  test('LF04 STORE COUPON controller unknown restart reconciles identical original and never overwrites current head', () async {
    final journal = CouponPending(), provider = CouponProvider()..unknown = true, original = couponIntent();
    final first = couponController(journal, provider);
    await first.refresh(original.couponId);
    expect((await first.submit(original.couponId, original.input, fundingAcknowledged: true, inputCurrent: () => true)).state,
      StorePromotionResultState.unknown);
    final retained = journal.original!; first.dispose();
    final restart = couponController(journal, provider); addTearDown(restart.dispose);
    expect(await restart.refresh(original.couponId), isFalse);
    expect((await restart.submit(original.couponId, original.input, fundingAcknowledged: true, inputCurrent: () => true)).state,
      StorePromotionResultState.notSent); expect(provider.writes.length, 1);
    provider.head = provider.acknowledge(couponIntent(expectedRevision: 1, name: 'Later public campaign'));
    expect((await restart.reconcile()).state, StorePromotionResultState.saved);
    expect(provider.recoveries.single.fingerprint, retained.fingerprint);
    expect(restart.lastAcknowledged!.input.name, original.input.name); expect(restart.currentRecord, isNull);
    await restart.refresh(original.couponId); expect(restart.currentRecord!.revision, 2);
    expect(restart.currentRecord!.input.name, 'Later public campaign');
  });
  test('LF04 STORE COUPON controller failed journal sends nothing; failed exact clear remains held', () async {
    final journal = CouponPending()..failSave = true, provider = CouponProvider(), original = couponIntent();
    final subject = couponController(journal, provider); addTearDown(subject.dispose);
    await subject.refresh(original.couponId);
    expect((await subject.submit(original.couponId, original.input, fundingAcknowledged: true, inputCurrent: () => true)).state,
      StorePromotionResultState.notSent); expect(provider.writes, isEmpty); expect(journal.original, isNull);
    journal.failSave = false; journal.failClear = true;
    expect((await subject.submit(original.couponId, original.input, fundingAcknowledged: true, inputCurrent: () => true)).state,
      StorePromotionResultState.unknown); expect(journal.original, isNotNull);
    expect(provider.writes.length, 1); journal.failClear = false;
    expect((await subject.reconcile()).state, StorePromotionResultState.saved); expect(journal.original, isNull);
  });
  for (final boundary in ['funding', 'form', 'owner before dispatch', 'owner after dispatch']) {
    test('LF04 STORE COUPON controller fences $boundary without leaking a result', () async {
      var owner = 1;
      final journal = CouponPending(), provider = CouponProvider(), original = couponIntent();
      final subject = couponController(journal, provider, context: () => owner); addTearDown(subject.dispose);
      await subject.refresh(original.couponId);
      if (boundary == 'owner before dispatch') journal.afterSave = () async {owner = 2;};
      if (boundary == 'owner after dispatch') provider.afterWrite = () async {owner = 2;};
      final result = await subject.submit(original.couponId, original.input,
        fundingAcknowledged: boundary != 'funding', inputCurrent: () => boundary != 'form');
      expect(result.state, boundary.startsWith('owner') ? StorePromotionResultState.unknown : StorePromotionResultState.notSent);
      expect(provider.writes.length, boundary == 'owner after dispatch' ? 1 : 0);
      expect(subject.lastAcknowledged, isNull);
      if (boundary.startsWith('owner')) expect(journal.original, isNotNull);
    });
  }
  test('LF04 STORE COUPON controller pause preserves exact existing terms and server revision', () async {
    final journal = CouponPending(), provider = CouponProvider(), original = couponIntent();
    provider.head = provider.acknowledge(original);
    final subject = couponController(journal, provider); addTearDown(subject.dispose);
    await subject.refresh(original.couponId);
    final changed = StoreCouponInput.fromJson({...original.input.paused().toJson(), 'name': 'Changed while pausing'});
    expect((await subject.submit(original.couponId, changed, fundingAcknowledged: true, inputCurrent: () => true)).state,
      StorePromotionResultState.notSent); expect(provider.writes, isEmpty);
    expect((await subject.submit(original.couponId, original.input.paused(), fundingAcknowledged: true, inputCurrent: () => true)).state,
      StorePromotionResultState.saved);
    expect(provider.writes.single.expectedRevision, 1); expect(provider.writes.single.input.active, isFalse);
  });
  test('LF04 STORE COUPON pre-dispatch interruption recovers only by explicit identical retry', () async {
    var owner = 1;
    final journal = CouponPending(), provider = CouponProvider(), original = couponIntent();
    final first = couponController(journal, provider, context: () => owner);
    await first.refresh(original.couponId); journal.afterSave = () async {owner = 2;};
    await first.submit(original.couponId, original.input, fundingAcknowledged: true, inputCurrent: () => true);
    final retained = journal.original!; expect(provider.writes, isEmpty); first.dispose();
    final restart = couponController(journal, provider); addTearDown(restart.dispose);
    await restart.restore(); await restart.reconcile(); expect(journal.original, isNotNull);
    expect((await restart.retryOriginal(fundingAcknowledged: false)).state, StorePromotionResultState.unknown);
    expect(provider.writes, isEmpty);
    expect((await restart.retryOriginal(fundingAcknowledged: true)).state, StorePromotionResultState.saved);
    expect(provider.writes.single.fingerprint, retained.fingerprint);
    expect(journal.original, isNull); expect(restart.loadedCouponId, isNull);
  });
  for (final scale in [1.0, 2.0]) {
    testWidgets('LF04 STORE COUPON publish sheet confirms exact campaign and stays scrollable at $scale', (tester) async {
      FlutterSecureStorage.setMockInitialValues({}); tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1; tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.reset); addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final creds = Credentials(), transport = Transport(), journal = CouponPending();
      Map<String, dynamic>? head;
      transport.reply = (body) async {
        if (body['operation'] == 'saveStoreCoupon') {
          head = {...body['coupon'] as Map<String, dynamic>, 'schemaVersion': 1, 'realm': scope.realm,
            'storeId': scope.store, 'couponId': body['couponId'], 'revision': (body['expectedRevision'] as int) + 1,
            'observedAt': at.toIso8601String()};
        }
        return couponResponse(head);
      };
      final owner = WorkSession(gateway: ReviewWorkGateway(), contactDraftStore: catalogue.ListingAccount(),
        catalogueGateway: AuthenticatedWorkspaceCatalogueGateway(endpoint: Uri.parse(
          'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
          credentials: catalogue.Credentials(), transport: catalogue.OwnerTransport((_) async => throw StateError('No SKU lookup')),
          ownerAccountId: scope.account), offerDraftStoreFactory: (_) => catalogue.ListingAccount(),
        productPromotionGateway: couponGateway(creds, transport), productPromotionRealm: scope.realm,
        storeCouponPendingStoreFactory: (_) => journal)
        ..activeWorkspace = WorkWorkspace(id: scope.store, name: 'Host Store', profileLabel: 'Grocery',
          profileId: 'retailer-grocery', area: 'Jaipur', verified: true);
      addTearDown(owner.dispose);
      await owner.loadWorkspaceOfferDraft(expectedStoreId: scope.store);
      final campaign = StoreCouponCampaign.fromJson({...couponDraft().toJson(), 'revision': 1,
        'endsAt': DateTime.utc(2027).toIso8601String()}, scope.store);
      expect(await owner.saveWorkspaceStoreCouponCampaign(campaign, expectedStoreId: scope.store), isTrue);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: ListView(children: [StoreCouponCampaignPanel(session: owner)]))));
      await tester.pumpAndSettle();
      final manage = find.byTooltip('Manage publishing for ${campaign.name}');
      await tester.ensureVisible(manage); await tester.pumpAndSettle(); await tester.tap(manage); await tester.pumpAndSettle();
      expect(find.text('Coupon publishing'), findsOneWidget);
      final publish = find.widgetWithText(FilledButton, 'Publish coupon terms');
      await tester.ensureVisible(publish); await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(publish).onPressed, isNull);
      final confirmation = find.byType(CheckboxListTile);
      await tester.ensureVisible(confirmation); await tester.pumpAndSettle(); await tester.tap(confirmation); await tester.pumpAndSettle();
      await tester.ensureVisible(publish); await tester.pumpAndSettle(); await tester.tap(publish); await tester.pumpAndSettle();
      final writes = transport.bodies.where((b) => b['operation'] == 'saveStoreCoupon').toList();
      expect(writes.length, 1); expect(writes.single['expectedRevision'], 0);
      expect((writes.single['coupon'] as Map)['name'], campaign.name);
      expect(journal.original, isNull); expect(find.textContaining('savings are not confirmed'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('LF04 STORE COUPON original retry consent cannot authorize different current draft', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    final creds = Credentials(), transport = Transport(), journal = CouponPending();
    final original = couponIntent(name: 'Original recovered campaign'); journal.original = original;
    transport.reply = (_) async => couponResponse(couponRecord(original));
    final owner = WorkSession(gateway: ReviewWorkGateway(), contactDraftStore: catalogue.ListingAccount(),
      catalogueGateway: AuthenticatedWorkspaceCatalogueGateway(endpoint: Uri.parse(
        'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
        credentials: catalogue.Credentials(), transport: catalogue.OwnerTransport((_) async => throw StateError('No SKU lookup')),
        ownerAccountId: scope.account), offerDraftStoreFactory: (_) => catalogue.ListingAccount(),
      productPromotionGateway: couponGateway(creds, transport), productPromotionRealm: scope.realm,
      storeCouponPendingStoreFactory: (_) => journal)
      ..activeWorkspace = WorkWorkspace(id: scope.store, name: 'Host Store', profileLabel: 'Grocery',
        profileId: 'retailer-grocery', area: 'Jaipur', verified: true);
    addTearDown(owner.dispose);
    await owner.loadWorkspaceOfferDraft(expectedStoreId: scope.store);
    final campaign = StoreCouponCampaign.fromJson({...couponDraft().toJson(), 'revision': 1,
      'endsAt': DateTime.utc(2027).toIso8601String()}, scope.store);
    expect(await owner.saveWorkspaceStoreCouponCampaign(campaign, expectedStoreId: scope.store), isTrue);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ListView(children: [StoreCouponCampaignPanel(session: owner)]))));
    await tester.pumpAndSettle(); final manage = find.byTooltip('Manage publishing for ${campaign.name}');
    await tester.ensureVisible(manage); await tester.pumpAndSettle(); await tester.tap(manage); await tester.pumpAndSettle();
    expect(find.text('Original coupon: Original recovered campaign'), findsOneWidget);
    final confirm = find.byType(CheckboxListTile); await tester.ensureVisible(confirm); await tester.pumpAndSettle();
    await tester.tap(confirm); await tester.pumpAndSettle();
    final check = find.text('Check original coupon update'); await tester.ensureVisible(check); await tester.pumpAndSettle();
    await tester.tap(check); await tester.pumpAndSettle();
    expect(journal.original, isNull);
    final refresh = find.text('Check current coupon'); await tester.ensureVisible(refresh); await tester.pumpAndSettle();
    await tester.tap(refresh); await tester.pumpAndSettle();
    final publish = find.widgetWithText(FilledButton, 'Publish updated terms');
    await tester.ensureVisible(publish); await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(publish).onPressed, isNull);
    expect(tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value, isFalse);
    expect(transport.bodies.where((b) => b['operation'] == 'saveStoreCoupon'), isEmpty);
    expect(tester.takeException(), isNull);
  });
  WorkSession supplierOwner(String profile, {bool supported = true, bool review = false}) => WorkSession(
    gateway: review ? ReviewWorkGateway() : _HostCouponWorkspaceGateway(profile), contactDraftStore: catalogue.ListingAccount(),
    catalogueGateway: AuthenticatedWorkspaceCatalogueGateway(endpoint: Uri.parse(
      'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
      credentials: catalogue.Credentials(), transport: catalogue.OwnerTransport((_) async => throw StateError('No host publication')),
      ownerAccountId: 'owner-one', supplierPublishersVersionSupported: supported),
    productPromotionGateway: Provider(), productPromotionRealm: 'production', productPromotionPendingStoreFactory: (_) => Pending())
    ..activeWorkspace = WorkWorkspace(id: 'store-one', name: 'Host supplier', profileLabel: profile,
      profileId: profile, area: 'Jaipur', verified: true);
  for (final fault in ['legacy', 'review', 'unknown profile']) {
    test('LF04 PUBLISHERS supplier authoring remains closed for $fault', () {
      TestWidgetsFlutterBinding.ensureInitialized(); FlutterSecureStorage.setMockInitialValues({});
      final owner = supplierOwner(fault == 'unknown profile' ? 'wholesaler-pretend' : 'wholesaler',
        supported: fault != 'legacy', review: fault == 'review'); addTearDown(owner.dispose);
      expect(owner.workspaceStoreAuthoringAvailable, isFalse);
      expect(owner.workspaceProductPromotions, isNull); expect(owner.workspacePublicDetailsPublisher, isNull);
    });
  }
  for (final profile in ['wholesaler', 'manufacturer']) {
    testWidgets('LF04 PUBLISHERS $profile uses existing Store and Stock navigation', (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      addTearDown(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());
      tester.view.physicalSize = const Size(430, 932); tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
      final owner = supplierOwner(profile), core = BuySession();
      final buyer = BuyV2Session(core: core);
      var closed = false;
      void closeFixture() {if (closed) return; closed = true; buyer.dispose(); core.dispose(); owner.dispose();}
      addTearDown(closeFixture);
      expect(await owner.recoverWorkspaceAccount(accountReady: true), isTrue);
      await owner.refreshFeed();
      expect(owner.hasVerifiedWorkspace, isTrue);
      await tester.pumpWidget(MaterialApp(home: WorkWorkspaceDashboardScreen(session: owner,
        procurementSession: buyer, accountRecoveryReady: true)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-store-home')), findsOneWidget);
      final stock = find.byKey(const Key('work-store-stock')); expect(stock, findsOneWidget);
      await tester.tap(stock); await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-store-home')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('work-store-home'))); await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-store-full-name')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      closeFixture();
      await tester.pump();
    });
  }
  for (final profile in ['wholesaler', 'manufacturer']) {
    test('LF04 PUBLISHERS supplier owner reaches existing authoring controllers $profile', () async {
      TestWidgetsFlutterBinding.ensureInitialized(); FlutterSecureStorage.setMockInitialValues({});
      final connection = AuthenticatedWorkspaceCatalogueGateway(endpoint: Uri.parse(
        'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
        credentials: catalogue.Credentials(), transport: catalogue.OwnerTransport((_) async => throw StateError('No host publication')),
        ownerAccountId: 'owner-one', supplierPublishersVersionSupported: true);
      final owner = WorkSession(gateway: _HostCouponWorkspaceGateway(profile), contactDraftStore: catalogue.ListingAccount(),
        catalogueGateway: connection, productPromotionGateway: Provider(), productPromotionRealm: 'production',
        productPromotionPendingStoreFactory: (_) => Pending())
        ..activeWorkspace = WorkWorkspace(id: 'store-one', name: 'Host supplier', profileLabel: profile,
          profileId: profile, area: 'Jaipur', verified: true);
      addTearDown(owner.dispose);
      expect(await owner.recoverWorkspaceAccount(accountReady: true), isTrue);
      await owner.refreshFeed();
      expect(owner.hasVerifiedWorkspace, isTrue);
      expect(owner.workspaceProductPromotions, isNotNull);
      expect(owner.workspacePublicDetailsPublisher, isNotNull);
    });
  }
  Map<String, dynamic> benefitTerms({bool percentage = false}) => {'schemaVersion': 1,
    'kind': percentage ? 'percentage' : 'flat', 'currency': 'INR',
    'flatAmountMinor': percentage ? null : 1025, 'flatBasis': percentage ? null : 'per_pack',
    'percentageBasisPoints': percentage ? 750 : null, 'maximumSavingMinor': 5000,
    'minimumSpendMinor': 0, 'minimumQuantity': 2};
  for (final percentage in [false, true]) {
    test('LF04 advertised terms exact immutable source survives record and original journal percentage=$percentage', () {
      final raw = benefitTerms(percentage: percentage), terms = BuyV2AdvertisedBenefitTerms.fromJson(raw);
      raw['minimumQuantity'] = 99;
      expect(terms.minimumQuantity, 2); expect(terms.minimumSpendMinor, 0);
      final value = StorePromotionInput.fromJson({...input().toJson(), 'benefitTerms': terms.toJson()}), original = intent(value: value);
      expect(StorePromotionIntent.fromJson(original.toJson()).input.fingerprint, value.fingerprint);
      final decoded = StorePromotionRecord.decode(recordJson(original), scope, at);
      expect(decoded.acknowledges(original), true);
      expect(decoded.input.paused().benefitTerms!.toJson(), terms.toJson());
      expect(value.toJson()..remove('benefitTerms'), input().toJson());
      final clear = StorePromotionInput.fromJson(input().toJson()); expect(clear.toJson().containsKey('benefitTerms'), false);
    });
  }
  for (final change in <Map<String, dynamic>>[
    {'schemaVersion': 1.0}, {'kind': ['flat']}, {'flatBasis': ['per_pack']}, {'flatAmountMinor': 10.5},
    {'flatAmountMinor': '1025'}, {'flatAmountMinor': null}, {'percentageBasisPoints': 500}, {'maximumSavingMinor': 0},
    {'minimumSpendMinor': -1}, {'minimumQuantity': 0}, {'applied': true}, {'currency': 'USD'},
    {'kind': 'percentage', 'flatAmountMinor': null, 'flatBasis': null, 'percentageBasisPoints': 10001},
    {'kind': 'percentage', 'flatAmountMinor': null, 'flatBasis': null, 'percentageBasisPoints': 0},
  ]) {
    test('LF04 advertised terms strict source rejects ${jsonEncode(change)}', () {
      expect(() => BuyV2AdvertisedBenefitTerms.fromJson({...benefitTerms(), ...change}), throwsFormatException);
    });
  }
  test('LF04 advertised terms negotiated owner gateway never upgrades legacy calls or sends disabled rich writes', () async {
    final credentials = Credentials(), transport = Transport();
    final original = intent(value: StorePromotionInput.fromJson({...input().toJson(), 'benefitTerms': benefitTerms()}));
    expect((await gateway(credentials, transport).save(original, () => true)).state, StorePromotionResultState.notSent);
    expect(transport.bodies, isEmpty); expect(credentials.modes, isEmpty);
    transport.reply = (_) async => response(recordJson(original), terms: true);
    final enabled = gateway(credentials, transport, terms: true);
    expect((await enabled.save(original, () => true)).state, StorePromotionResultState.saved);
    expect(transport.bodies.single['promotionTermsVersion'], 1);
    expect(transport.bodies.single['promotion'], original.input.toJson());
    expect(credentials.modes, [SocialAppCheckTokenMode.limitedUse]);
    expect((await enabled.reconcile(original, () => true)).state, StorePromotionResultState.saved);
    expect(transport.bodies.last['idempotencyKey'], original.idempotencyKey);
    expect(credentials.modes.last, SocialAppCheckTokenMode.standard);
    transport.reply = (_) async => response(recordJson(original));
    expect((await enabled.save(original, () => true)).state, StorePromotionResultState.unknown,
      reason: 'A missing matching response capability cannot acknowledge a rich write.');
    expect((await gateway(credentials, transport).save(intent(), () => true)).state, StorePromotionResultState.unknown,
      reason: 'An unsolicited rich record must not be consumed by a legacy caller.');
  });
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
          productPromotionNow: () => at,
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
  for (final kind in <String?>[null, 'flat', 'percentage']) {
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'explicit promotion editor uses saved source without Stock or targeted draft mutation text$scale terms=$kind',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 700);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final journal = Pending(),
            provider = Provider()..benefitTermsSupported = kind != null,
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
        final termsKind = find.byKey(const Key('work-promotion-benefit-kind'));
        if (kind == null) {
          expect(termsKind, findsNothing);
        } else {
          await tester.ensureVisible(termsKind); await tester.tap(termsKind); await tester.pumpAndSettle();
          await tester.tap(find.text(kind == 'flat' ? 'Flat amount (₹)' : 'Percentage (%)').last); await tester.pumpAndSettle();
          final amount = find.byKey(const Key('work-promotion-benefit-amount'));
          await tester.ensureVisible(amount); await tester.enterText(amount, '10.255'); await tester.pump();
          expect(find.byKey(const Key('work-promotion-benefit-error')), findsOneWidget);
          await tester.enterText(amount, '10.25');
          FocusManager.instance.primaryFocus?.unfocus(); await tester.pumpAndSettle();
          if (kind == 'flat') {
            final basis = find.byKey(const Key('work-promotion-flat-basis'));
            await tester.ensureVisible(basis); await tester.tap(basis); await tester.pumpAndSettle();
            await tester.tap(find.text('Per selling pack').last); await tester.pumpAndSettle();
          }
          for (final field in {'work-promotion-benefit-cap': '50', 'work-promotion-benefit-spend': '0', 'work-promotion-benefit-quantity': '2'}.entries) {
            final input = find.byKey(Key(field.key)); await tester.ensureVisible(input); await tester.enterText(input, field.value);
          }
          FocusManager.instance.primaryFocus?.unfocus(); await tester.pumpAndSettle();
          expect(find.byKey(const Key('work-promotion-benefit-error')), findsNothing);
        }
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
        final terms = provider.lastSaved!.input.benefitTerms;
        if (kind == null) {
          expect(terms, isNull);
        } else {
          expect(terms!.kind, kind); expect(terms.flatAmountMinor ?? terms.percentageBasisPoints, 1025);
          expect(terms.maximumSavingMinor, 5000); expect(terms.minimumSpendMinor, 0); expect(terms.minimumQuantity, 2);
        }
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
