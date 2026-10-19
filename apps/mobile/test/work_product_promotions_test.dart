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
import 'package:moolsocial/features/work/screens/work_workspace_dashboard_screen.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';

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
void main() {
  StoreCouponCampaign couponDraft() => StoreCouponCampaign(id: 'coupon-one', storeId: scope.store,
    revision: 19, name: 'Host Diwali savings', percentage: false, discount: 1050,
    minimumSpendMinor: 10000, maximumSavingMinor: 1050, startsAt: at,
    endsAt: at.add(const Duration(days: 1)), totalUses: 20, usesPerCustomer: 1);
  StoreCouponIntent couponIntent({int expectedRevision = 0, String name = 'Host Diwali savings'}) => StoreCouponIntent(
    scope: scope, couponId: 'coupon-one', expectedRevision: expectedRevision, idempotencyKey: 'coupon-original',
    input: StoreCouponInput.fromJson({...StoreCouponInput.fromCampaign(couponDraft(), active: true).toJson(), 'name': name}),
    fundingAcknowledged: true);
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
      final owner = WorkSession(gateway: const UnavailableWorkGateway(), contactDraftStore: catalogue.ListingAccount(),
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
    final owner = WorkSession(gateway: const UnavailableWorkGateway(), contactDraftStore: catalogue.ListingAccount(),
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
    gateway: review ? ReviewWorkGateway() : const UnavailableWorkGateway(), contactDraftStore: catalogue.ListingAccount(),
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
      tester.view.physicalSize = const Size(430, 932); tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
      final owner = supplierOwner(profile), core = BuySession();
      final buyer = BuyV2Session(core: core);
      addTearDown(owner.dispose); addTearDown(core.dispose); addTearDown(buyer.dispose);
      expect(await owner.recoverWorkspaceAccount(accountReady: true), isTrue);
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
    });
  }
  for (final profile in ['wholesaler', 'manufacturer']) {
    test('LF04 PUBLISHERS supplier owner reaches existing authoring controllers $profile', () {
      TestWidgetsFlutterBinding.ensureInitialized(); FlutterSecureStorage.setMockInitialValues({});
      final connection = AuthenticatedWorkspaceCatalogueGateway(endpoint: Uri.parse(
        'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
        credentials: catalogue.Credentials(), transport: catalogue.OwnerTransport((_) async => throw StateError('No host publication')),
        ownerAccountId: 'owner-one', supplierPublishersVersionSupported: true);
      final owner = WorkSession(gateway: const UnavailableWorkGateway(), contactDraftStore: catalogue.ListingAccount(),
        catalogueGateway: connection, productPromotionGateway: Provider(), productPromotionRealm: 'production',
        productPromotionPendingStoreFactory: (_) => Pending())
        ..activeWorkspace = WorkWorkspace(id: 'store-one', name: 'Host supplier', profileLabel: profile,
          profileId: profile, area: 'Jaipur', verified: true);
      addTearDown(owner.dispose);
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
