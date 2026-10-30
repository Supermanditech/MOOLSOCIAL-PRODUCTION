import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart' as crypto;
import '../shared/social_content_gateway.dart';
import '../buy/buy_v2_content_contracts.dart' show BuyV2AdvertisedBenefitTerms;
import '../buy/buy_v2_models.dart' show BuyV2StoreOfferTerms, BuyV2StoreOfferKind;

typedef StorePromotionScope = ({String account, String store, String realm});

/// Owner-entered, private Store-wide campaign configuration. Not a published
/// benefit, redemption, usage count or authority to reduce Checkout totals.
@immutable
class StoreCouponCampaign {
  StoreCouponCampaign({required this.id, required this.storeId,
    required this.revision, required this.name, required this.percentage,
    required this.discount, required this.minimumSpendMinor,
    required this.maximumSavingMinor, required this.startsAt,
    required this.endsAt, required this.totalUses, required this.usesPerCustomer})
    : structuredTerms = null, buyerReferences = const [] {
    if (id.trim().isEmpty || id.length > 128 || storeId.trim().isEmpty ||
        revision < 1 || name != name.trim() || name.isEmpty || name.length > 80 ||
        RegExp(r'[\x00-\x1f]').hasMatch(name) ||
        discount <= 0 || discount > (percentage ? 10000 : 9000000000000) ||
        minimumSpendMinor < 0 || minimumSpendMinor > 9000000000000 ||
        maximumSavingMinor <= 0 || maximumSavingMinor > 9000000000000 ||
        (!percentage && maximumSavingMinor != discount) ||
        !endsAt.isAfter(startsAt) || totalUses <= 0 || totalUses > 1000000000 ||
        usesPerCustomer <= 0 || usesPerCustomer > totalUses) {
      throw const FormatException('Check the coupon name, saving, dates and limits.');
    }
  }
  StoreCouponCampaign.offer({required this.id, required this.storeId, required this.revision,
    required this.name, required BuyV2StoreOfferTerms structuredTerms,
    Iterable<String> buyerReferences = const [], required this.startsAt, required this.endsAt,
    required this.totalUses, required this.usesPerCustomer})
    : structuredTerms = structuredTerms, buyerReferences = List.unmodifiable(buyerReferences),
      percentage = structuredTerms.discountKind == 'percentage',
      // Legacy monetary accessors are inactive for quantity/free-goods terms.
      // Such offers always render/serialize structuredTerms, never these zeros.
      discount = structuredTerms.discountValue ?? 0,
      minimumSpendMinor = structuredTerms.minimumSpendMinor,
      maximumSavingMinor = structuredTerms.maximumSavingMinor ?? 0 {
    if (id.trim().isEmpty || id.length > 128 || storeId.trim().isEmpty ||
        structuredTerms.storeId != storeId || revision < 1 || name != name.trim() ||
        name.isEmpty || name.length > 80 || RegExp(r'[\x00-\x1f]').hasMatch(name) ||
        !endsAt.isAfter(startsAt) || totalUses <= 0 || totalUses > 1000000000 ||
        usesPerCustomer <= 0 || usesPerCustomer > totalUses || this.buyerReferences.length > 1000 ||
        this.buyerReferences.toSet().length != this.buyerReferences.length ||
        this.buyerReferences.any((id) => !RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$').hasMatch(id)) ||
        (structuredTerms.kind == BuyV2StoreOfferKind.buyerDiscount
          ? this.buyerReferences.isEmpty : this.buyerReferences.isNotEmpty)) {
      throw const FormatException('Check this Store’s offer, buyers, dates and usage limits.');
    }
  }
  final String id, storeId, name;
  final BuyV2StoreOfferTerms? structuredTerms;
  /// Private Store-customer references. Never include these in public terms.
  final List<String> buyerReferences;
  final int revision;
  final bool percentage;
  /// Flat saving in paise, or percentage in basis points (100 = 1%).
  final int discount, minimumSpendMinor, maximumSavingMinor;
  final DateTime startsAt, endsAt;
  final int totalUses, usesPerCustomer;
  Map<String, Object> toJson() => structuredTerms != null ? {
    'schemaVersion': 2, 'id': id, 'storeId': storeId, 'revision': revision, 'name': name,
    'structuredTerms': structuredTerms!.toJson(), 'buyerReferences': buyerReferences,
    'startsAt': startsAt.toUtc().toIso8601String(), 'endsAt': endsAt.toUtc().toIso8601String(),
    'totalUses': totalUses, 'usesPerCustomer': usesPerCustomer,
  } : {
    'id': id, 'storeId': storeId, 'revision': revision, 'name': name,
    'percentage': percentage, 'discount': discount,
    'minimumSpendMinor': minimumSpendMinor, 'maximumSavingMinor': maximumSavingMinor,
    'startsAt': startsAt.toUtc().toIso8601String(),
    'endsAt': endsAt.toUtc().toIso8601String(),
    'totalUses': totalUses, 'usesPerCustomer': usesPerCustomer,
  };
  factory StoreCouponCampaign.fromJson(Object? raw, String storeId) {
    if (raw is Map && raw['schemaVersion'] == 2) {
      final row = _map(raw, ['schemaVersion', 'id', 'storeId', 'revision', 'name',
        'structuredTerms', 'buyerReferences', 'startsAt', 'endsAt', 'totalUses', 'usesPerCustomer']);
      if (row['schemaVersion'] is! int || row['storeId'] != storeId || row['buyerReferences'] is! List ||
          (row['buyerReferences'] as List).any((value) => value is! String) ||
          row['totalUses'] is! int || row['usesPerCustomer'] is! int) {
        throw const FormatException('Check the saved offer.');
      }
      return StoreCouponCampaign.offer(id: _text(row['id'], 128), storeId: storeId,
        revision: _revision(row['revision'], 1), name: _text(row['name'], 80),
        structuredTerms: BuyV2StoreOfferTerms.fromJson(row['structuredTerms']),
        buyerReferences: (row['buyerReferences'] as List).cast<String>(),
        startsAt: _time(row['startsAt']), endsAt: _time(row['endsAt']),
        totalUses: row['totalUses'] as int, usesPerCustomer: row['usesPerCustomer'] as int);
    }
    if (raw is! Map || raw.length != 12 || raw['storeId'] != storeId ||
        raw['id'] is! String || raw['name'] is! String || raw['revision'] is! int ||
        raw['percentage'] is! bool || raw['discount'] is! int ||
        raw['minimumSpendMinor'] is! int || raw['maximumSavingMinor'] is! int ||
        raw['startsAt'] is! String || raw['endsAt'] is! String ||
        raw['totalUses'] is! int || raw['usesPerCustomer'] is! int) {
      throw const FormatException('Saved coupons could not be opened.');
    }
    return StoreCouponCampaign(id: raw['id'] as String, storeId: storeId,
      revision: raw['revision'] as int, name: raw['name'] as String,
      percentage: raw['percentage'] as bool, discount: raw['discount'] as int,
      minimumSpendMinor: raw['minimumSpendMinor'] as int,
      maximumSavingMinor: raw['maximumSavingMinor'] as int,
      startsAt: DateTime.parse(raw['startsAt'] as String),
      endsAt: DateTime.parse(raw['endsAt'] as String),
      totalUses: raw['totalUses'] as int, usesPerCustomer: raw['usesPerCustomer'] as int);
  }
}

List<StoreCouponCampaign> decodeStoreCouponCampaigns(String? encoded, String storeId) {
  if (encoded == null) return const [];
  final raw = jsonDecode(encoded);
  if (raw is! Map || raw.length != 2 || raw['schemaVersion'] is! int || !{1, 2}.contains(raw['schemaVersion']) ||
      raw['campaigns'] is! List || (raw['campaigns'] as List).length > 50) {
    throw const FormatException('Saved coupons need a compatible app version.');
  }
  final records = (raw['campaigns'] as List)
      .map((row) => StoreCouponCampaign.fromJson(row, storeId)).toList();
  if (raw['schemaVersion'] == 1 && records.any((record) => record.structuredTerms != null)) {
    throw const FormatException('Check the saved offer version.');
  }
  if (records.map((row) => row.id).toSet().length != records.length) {
    throw const FormatException('Saved coupon identities could not be checked.');
  }
  return List.unmodifiable(records);
}

String encodeStoreCouponCampaigns(List<StoreCouponCampaign> campaigns) => jsonEncode({
  'schemaVersion': campaigns.any((row) => row.structuredTerms != null) ? 2 : 1,
  'campaigns': campaigns.map((row) => row.toJson()).toList(),
});

/// The existing private campaign's durable backing command. Its source CAS is
/// independent of the native campaign revision and publication CAS.
@immutable
class StoreCouponDraftIntent {
  StoreCouponDraftIntent({required this.scope, required this.expectedSourceRevision,
    required this.idempotencyKey, required StoreCouponCampaign campaign})
      : couponId = _text(campaign.id, 128),
        _campaign = jsonEncode(StoreCouponCampaign.fromJson(campaign.toJson(), scope.store).toJson()) {
    _scope(scope); _id(idempotencyKey); _revision(expectedSourceRevision);
    if (expectedSourceRevision >= 1000000000) throw const FormatException('Refresh the saved draft.');
  }
  final StorePromotionScope scope;
  final int expectedSourceRevision;
  final String couponId, idempotencyKey, _campaign;
  StoreCouponCampaign get campaign => StoreCouponCampaign.fromJson(jsonDecode(_campaign), scope.store);
  String get campaignFingerprint => _campaign;
  Map<String, dynamic> get body => {'storeCouponDraftVersion': 1, 'storeId': scope.store,
    'couponId': couponId, 'expectedSourceRevision': expectedSourceRevision,
    'idempotencyKey': idempotencyKey, 'campaign': jsonDecode(_campaign)};
  Map<String, dynamic> toJson() => {'schemaVersion': 1, 'accountId': scope.account, 'realm': scope.realm, ...body};
  String get fingerprint => jsonEncode(toJson());
  factory StoreCouponDraftIntent.fromJson(Object? raw) {
    final row = _map(raw, ['schemaVersion', 'storeCouponDraftVersion', 'accountId', 'realm', 'storeId',
      'couponId', 'expectedSourceRevision', 'idempotencyKey', 'campaign']);
    if (row['schemaVersion'] is! int || row['schemaVersion'] != 1 || row['storeCouponDraftVersion'] is! int ||
        row['storeCouponDraftVersion'] != 1) throw const FormatException('Check the saved draft request.');
    final scope = (account: _id(row['accountId']), store: _id(row['storeId']), realm: _text(row['realm'], 16));
    final campaign = StoreCouponCampaign.fromJson(row['campaign'], scope.store);
    if (campaign.id != _text(row['couponId'], 128)) throw const FormatException('Wrong saved draft.');
    return StoreCouponDraftIntent(scope: scope, expectedSourceRevision: _revision(row['expectedSourceRevision']),
      idempotencyKey: _id(row['idempotencyKey']), campaign: campaign);
  }
}

@immutable
class StoreCouponDraftRecord {
  const StoreCouponDraftRecord._(this.scope, this.couponId, this.sourceRevision, this.observedAt, this._campaign);
  final StorePromotionScope scope;
  final int sourceRevision;
  final DateTime observedAt;
  final String couponId, _campaign;
  StoreCouponCampaign get campaign => StoreCouponCampaign.fromJson(jsonDecode(_campaign), scope.store);
  String get campaignFingerprint => _campaign;
  static StoreCouponDraftRecord decode(Object? raw, StorePromotionScope scope, DateTime now) {
    _scope(scope);
    final row = _map(raw, ['schemaVersion', 'storeCouponDraftVersion', 'accountId', 'realm', 'storeId',
      'couponId', 'sourceRevision', 'observedAt', 'campaign']);
    final campaign = StoreCouponCampaign.fromJson(row['campaign'], scope.store), observed = _time(row['observedAt']);
    if (row['schemaVersion'] is! int || row['schemaVersion'] != 1 || row['storeCouponDraftVersion'] is! int ||
        row['storeCouponDraftVersion'] != 1 || row['accountId'] != scope.account ||
        row['realm'] != scope.realm || row['storeId'] != scope.store || campaign.id != _text(row['couponId'], 128) ||
        observed.isAfter(now.toUtc())) throw const FormatException('Refresh the original saved draft.');
    return StoreCouponDraftRecord._(scope, campaign.id, _revision(row['sourceRevision'], 1), observed, jsonEncode(campaign.toJson()));
  }
  bool acknowledges(StoreCouponDraftIntent intent) => scope == intent.scope && couponId == intent.couponId &&
    sourceRevision == intent.expectedSourceRevision + 1 && campaignFingerprint == intent.campaignFingerprint;
}

class StoreCouponDraftResult {
  const StoreCouponDraftResult(this.state, {this.record});
  final StorePromotionResultState state;
  final StoreCouponDraftRecord? record;
}
class StoreCouponDraftPage {
  StoreCouponDraftPage(List<StoreCouponDraftRecord> records, this.nextCursor) : records = List.unmodifiable(records);
  final List<StoreCouponDraftRecord> records;
  final String? nextCursor;
}
abstract interface class StoreCouponDraftGateway {
  bool get storeCouponDraftsSupported;
  Future<StoreCouponDraftRecord?> readCouponDraft(StorePromotionScope scope, String couponId, bool Function() current);
  Future<StoreCouponDraftPage> listCouponDrafts(StorePromotionScope scope, bool Function() current, {String? after, int limit = 20});
  Future<StoreCouponDraftResult> saveCouponDraft(StoreCouponDraftIntent intent, bool Function() current);
  Future<StoreCouponDraftResult> reconcileCouponDraft(StoreCouponDraftIntent intent, bool Function() current);
}
abstract interface class StoreCouponDraftPendingStore {
  Future<StoreCouponDraftIntent?> read(StorePromotionScope scope);
  Future<void> save(StoreCouponDraftIntent intent);
  Future<void> clear(StoreCouponDraftIntent intent);
}

/// Synchronizes an explicitly saved native draft. It never edits the native
/// book, publishes a coupon, or treats a historical receipt as the current head.
class StoreCouponDraftSyncController extends ChangeNotifier {
  StoreCouponDraftSyncController({required this.scope, required this.gateway, required this.pendingStore,
    required this.context}) : _lifetime = context() {_scope(scope);}
  final StorePromotionScope scope;
  final StoreCouponDraftGateway gateway;
  final StoreCouponDraftPendingStore pendingStore;
  final Object? Function() context;
  final Object? _lifetime;
  bool _closed = false, ready = false, busy = false;
  bool get active => !_closed && _lifetime != null && context() == _lifetime;
  StoreCouponDraftIntent? pending;
  StoreCouponDraftRecord? lastAcknowledged;
  String? message;
  Future<bool>? _restoring;
  void _emit() {if (!_closed) notifyListeners();}
  Future<bool> restore() {
    if (!active) return Future.value(false);
    if (ready) return Future.value(true);
    return _restoring ??= _restore().whenComplete(() => _restoring = null);
  }
  Future<bool> _restore() async {
    try {
      final original = await pendingStore.read(scope).timeout(const Duration(seconds: 10));
      if (!active) return false;
      if (original != null && original.scope != scope) throw const FormatException();
      pending = original; ready = true; message = null;
      return true;
    } on Object {
      if (active) message = 'The original draft save needs checking. Your device draft is kept.';
      return false;
    } finally {if (active) _emit();}
  }
  Future<StoreCouponDraftResult> sync(StoreCouponCampaign campaign, {required bool Function() inputCurrent}) async {
    const notSent = StoreCouponDraftResult(StorePromotionResultState.notSent);
    if (!active || busy || !gateway.storeCouponDraftsSupported) return notSent;
    busy = true; _emit();
    bool current() => active && inputCurrent();
    try {
      if (!await restore() || !current()) return notSent;
      if (pending != null) return const StoreCouponDraftResult(StorePromotionResultState.unknown);
      final frozen = StoreCouponCampaign.fromJson(campaign.toJson(), scope.store);
      final original = await gateway.readCouponDraft(scope, frozen.id, current).timeout(const Duration(seconds: 25));
      if (!current()) return notSent;
      if (original != null && (original.scope != scope || original.couponId != frozen.id)) throw const FormatException();
      if (original != null && original.campaign.revision >= frozen.revision) {
        message = original.campaignFingerprint == jsonEncode(frozen.toJson()) ?
          'The device draft matches the online copy.' : 'The online copy changed. Your device draft is kept.';
        return notSent;
      }
      final intent = StoreCouponDraftIntent(scope: scope, expectedSourceRevision: original?.sourceRevision ?? 0,
        idempotencyKey: _key(), campaign: frozen);
      pending = intent;
      try {await pendingStore.save(intent).timeout(const Duration(seconds: 10));}
      on Object {ready = false; rethrow;}
      if (!active) return const StoreCouponDraftResult(StorePromotionResultState.unknown);
      if (!current()) return await _finish(intent, notSent);
      return await _finish(intent, await gateway.saveCouponDraft(intent, current).timeout(const Duration(seconds: 25)));
    } on Object {
      if (active) message = 'Draft saved on this device. The online copy is unconfirmed.';
      return StoreCouponDraftResult(pending == null ? StorePromotionResultState.notSent : StorePromotionResultState.unknown);
    } finally {busy = false; _emit();}
  }
  Future<StoreCouponDraftResult> reconcile() async {
    const unknown = StoreCouponDraftResult(StorePromotionResultState.unknown);
    if (!active || busy || !gateway.storeCouponDraftsSupported) return unknown;
    busy = true; _emit();
    try {
      if (!await restore() || !active || pending == null) return unknown;
      final original = pending!;
      final result = await gateway.reconcileCouponDraft(original, () => active).timeout(const Duration(seconds: 25));
      if (result.state != StorePromotionResultState.saved) return unknown;
      return await _finish(original, result);
    } on Object {
      if (active) message = 'The original draft save is still unconfirmed.';
      return unknown;
    } finally {busy = false; _emit();}
  }
  Future<StoreCouponDraftResult> retryOriginal({required bool confirmedOriginal}) async {
    const unknown = StoreCouponDraftResult(StorePromotionResultState.unknown);
    if (!confirmedOriginal || !active || busy || !gateway.storeCouponDraftsSupported) return unknown;
    busy = true; _emit();
    try {
      if (!await restore() || !active || pending == null) return unknown;
      final original = pending!;
      final result = await gateway.saveCouponDraft(original, () => active).timeout(const Duration(seconds: 25));
      if (result.state != StorePromotionResultState.saved) return unknown;
      return await _finish(original, result);
    } on Object {return unknown;} finally {busy = false; _emit();}
  }
  Future<StoreCouponDraftResult> _finish(StoreCouponDraftIntent original, StoreCouponDraftResult result) async {
    const unknown = StoreCouponDraftResult(StorePromotionResultState.unknown);
    if (!active || pending?.fingerprint != original.fingerprint) return unknown;
    if (result.state == StorePromotionResultState.unknown || result.state == StorePromotionResultState.saved &&
        result.record?.acknowledges(original) != true) {
      message = 'Check the original draft save before another online save.';
      return unknown;
    }
    try {
      await pendingStore.clear(original).timeout(const Duration(seconds: 10));
      if (!active) return unknown;
      pending = null;
      if (result.state == StorePromotionResultState.saved) lastAcknowledged = result.record;
      message = result.state == StorePromotionResultState.saved ? 'Draft saved. Not published.' :
        'The online draft was not saved. Your device copy is kept.';
      return result;
    } on Object {
      message = 'The original draft save still needs checking.';
      return unknown;
    }
  }
  @override void dispose() {_closed = true; super.dispose();}
}

const _couponKeys = ['name', 'percentage', 'discount', 'minimumSpendMinor',
  'maximumSavingMinor', 'startsAt', 'endsAt', 'totalUses', 'usesPerCustomer', 'active'];

/// Exact advertised campaign terms, not an evaluated saving or a private revision.
@immutable
class StoreCouponInput {
  StoreCouponInput.fromCampaign(StoreCouponCampaign campaign, {required bool active})
    : this.fromJson(campaign.structuredTerms != null ? {
        'schemaVersion': 2, 'name': campaign.name, 'structuredTerms': campaign.structuredTerms!.toJson(),
        'buyerReferences': campaign.buyerReferences, 'startsAt': _iso(campaign.startsAt),
        'endsAt': _iso(campaign.endsAt), 'totalUses': campaign.totalUses,
        'usesPerCustomer': campaign.usesPerCustomer, 'active': active,
      } : {for (final key in _couponKeys.where((k) => k != 'active'))
        key: campaign.toJson()[key], 'startsAt': _iso(campaign.startsAt),
        'endsAt': _iso(campaign.endsAt), 'active': active});
  StoreCouponInput.fromJson(Object? raw) : _encoded = _validate(raw);
  static String _validate(Object? raw) {
    if (raw is Map && raw['schemaVersion'] == 2) {
      const keys = ['schemaVersion', 'name', 'structuredTerms', 'buyerReferences',
        'startsAt', 'endsAt', 'totalUses', 'usesPerCustomer', 'active'];
      final row = _map(raw, keys);
      if (row['schemaVersion'] is! int || row['active'] is! bool || row['buyerReferences'] is! List ||
          (row['buyerReferences'] as List).any((id) => id is! String) ||
          row['totalUses'] is! int || row['usesPerCustomer'] is! int) { throw const FormatException(); }
      final terms = BuyV2StoreOfferTerms.fromJson(row['structuredTerms']);
      StoreCouponCampaign.offer(id: 'coupon-check', storeId: terms.storeId, revision: 1,
        name: _text(row['name'], 80), structuredTerms: terms,
        buyerReferences: (row['buyerReferences'] as List).cast<String>(),
        startsAt: _time(row['startsAt']), endsAt: _time(row['endsAt']),
        totalUses: row['totalUses'] as int, usesPerCustomer: row['usesPerCustomer'] as int);
      return jsonEncode({for (final key in keys) key: row[key]});
    }
    final row = _map(raw, _couponKeys);
    if (row['active'] is! bool) throw const FormatException('Check the coupon status.');
    // Share owner validation without adopting its local revision or identity.
    StoreCouponCampaign.fromJson({'id': 'coupon-check', 'storeId': 'store-check',
      'revision': 1, for (final key in _couponKeys.where((k) => k != 'active')) key: row[key]}, 'store-check');
    for (final key in ['startsAt', 'endsAt']) {
      if (_iso(_time(row[key])) != row[key]) throw const FormatException('Check the coupon date.');
    }
    return jsonEncode({for (final key in _couponKeys) key: row[key]});
  }
  final String _encoded;
  bool get structured => toJson()['schemaVersion'] == 2;
  void validateStore(String storeId) {
    if (structured && BuyV2StoreOfferTerms.fromJson(toJson()['structuredTerms']).storeId != storeId) {
      throw const FormatException('The offer belongs to another Store.');
    }
  }
  Map<String, dynamic> toJson() => jsonDecode(_encoded) as Map<String, dynamic>;
  String get fingerprint => _encoded;
  String get name => toJson()['name'] as String;
  bool get active => toJson()['active'] as bool;
  DateTime get endsAt => _time(toJson()['endsAt']);
  StoreCouponInput paused() => StoreCouponInput.fromJson({...toJson(), 'active': false});
  void validateForSave(DateTime now) {
    if (active && !endsAt.isAfter(now.toUtc())) {
      throw const FormatException('Choose a future coupon expiry.');
    }
  }
}

@immutable
class StoreCouponIntent {
  StoreCouponIntent({required this.scope, required this.couponId,
    required this.expectedRevision, required this.idempotencyKey,
    required this.input, required bool fundingAcknowledged}) {
    _scope(scope); _id(couponId); _id(idempotencyKey); _revision(expectedRevision);
    input.validateStore(scope.store);
    if (!fundingAcknowledged || expectedRevision >= 1000000000) {
      throw const FormatException('Confirm Store funding and refresh the coupon.');
    }
  }
  final StorePromotionScope scope;
  final String couponId, idempotencyKey;
  final int expectedRevision;
  final StoreCouponInput input;
  Map<String, dynamic> get body => {if (input.structured) 'storeCouponTermsVersion': 2,
    'storeId': scope.store, 'couponId': couponId,
    'expectedRevision': expectedRevision, 'idempotencyKey': idempotencyKey,
    'coupon': input.toJson(), 'fundingAcknowledged': true};
  Map<String, dynamic> toJson() => {'schemaVersion': 1, 'storeCouponTermsVersion': input.structured ? 2 : 1, 'accountId': scope.account,
    'realm': scope.realm, ...body};
  String get fingerprint => jsonEncode(toJson());
  factory StoreCouponIntent.fromJson(Object? raw) {
    final row = _map(raw, ['schemaVersion', 'storeCouponTermsVersion', 'accountId', 'realm', 'storeId', 'couponId',
      'expectedRevision', 'idempotencyKey', 'coupon', 'fundingAcknowledged']);
    final input = StoreCouponInput.fromJson(row['coupon']);
    if (row['schemaVersion'] is! int || row['schemaVersion'] != 1 || row['storeCouponTermsVersion'] is! int ||
        row['storeCouponTermsVersion'] != (input.structured ? 2 : 1) || row['fundingAcknowledged'] != true) {
      throw const FormatException('Keep the original coupon request.');
    }
    return StoreCouponIntent(scope: (account: _id(row['accountId']), store: _id(row['storeId']),
      realm: _text(row['realm'], 16)), couponId: _id(row['couponId']),
      expectedRevision: _revision(row['expectedRevision']), idempotencyKey: _id(row['idempotencyKey']),
      input: input, fundingAcknowledged: true);
  }
}

@immutable
class StoreCouponRecord {
  const StoreCouponRecord._(this.scope, this.couponId, this.revision, this.observedAt, this.input);
  final StorePromotionScope scope;
  final String couponId;
  final int revision;
  final DateTime observedAt;
  final StoreCouponInput input;
  static StoreCouponRecord decode(Object? raw, StorePromotionScope scope, DateTime now) {
    _scope(scope);
    if (raw is Map && raw['schemaVersion'] == 2) {
      final row = _map(raw, ['schemaVersion', 'storeCouponTermsVersion', 'accountId', 'realm', 'storeId',
        'couponId', 'revision', 'observedAt', 'coupon']);
      final input = StoreCouponInput.fromJson(row['coupon']), observed = _time(row['observedAt']);
      if (row['schemaVersion'] is! int || row['storeCouponTermsVersion'] is! int ||
          row['storeCouponTermsVersion'] != 2 || row['accountId'] != scope.account ||
          row['realm'] != scope.realm || row['storeId'] != scope.store || !input.structured || observed.isAfter(now.toUtc())) {
        throw const FormatException('Refresh the exact Store offer.');
      }
      input.validateStore(scope.store);
      return StoreCouponRecord._(scope, _id(row['couponId']), _revision(row['revision'], 1), observed, input);
    }
    final row = _map(raw, [..._couponKeys, 'schemaVersion', 'realm', 'storeId', 'couponId', 'revision', 'observedAt']);
    final observed = _time(row['observedAt']);
    if (row['schemaVersion'] != 1 || row['realm'] != scope.realm || row['storeId'] != scope.store || observed.isAfter(now.toUtc())) {
      throw const FormatException('Refresh the Store coupon.');
    }
    return StoreCouponRecord._(scope, _id(row['couponId']), _revision(row['revision'], 1), observed,
      StoreCouponInput.fromJson({for (final key in _couponKeys) key: row[key]}));
  }
  bool acknowledges(StoreCouponIntent original) => scope == original.scope && couponId == original.couponId &&
    revision == original.expectedRevision + 1 && input.fingerprint == original.input.fingerprint;
}

class StoreCouponResult {
  const StoreCouponResult(this.state, {this.record});
  final StorePromotionResultState state;
  final StoreCouponRecord? record;
}

class StoreCouponPage {
  StoreCouponPage(List<StoreCouponRecord> records, this.nextCursor) : records = List.unmodifiable(records);
  final List<StoreCouponRecord> records;
  final String? nextCursor;
}

abstract interface class StoreCouponGateway {
  bool get storeCouponTermsSupported;
  Future<StoreCouponRecord?> readCoupon(StorePromotionScope scope, String couponId, bool Function() current);
  Future<StoreCouponPage> listCoupons(StorePromotionScope scope, bool Function() current, {String? after, int limit = 20});
  Future<StoreCouponResult> saveCoupon(StoreCouponIntent original, bool Function() current);
  Future<StoreCouponResult> reconcileCoupon(StoreCouponIntent original, bool Function() current);
}

/// Proposed richer publication capability. Existing v1 gateways do not acquire
/// this authority merely because a private draft has new fields.
abstract interface class StoreStructuredCouponGateway implements StoreCouponGateway {
  bool get structuredCouponTermsSupported;
}

abstract interface class StoreCouponPendingStore {
  Future<StoreCouponIntent?> read(StorePromotionScope scope);
  Future<void> save(StoreCouponIntent original);
  Future<void> clear(StoreCouponIntent original);
}

/// Owner publication workflow. A receipt proves an original write, not that the
/// coupon is currently public, eligible or redeemed. Always refresh current state.
class StoreCouponController extends ChangeNotifier {
  StoreCouponController({required this.scope, required this.gateway, required this.pendingStore,
    required this.context, DateTime Function()? now}) : now = now ?? DateTime.now, _lifetime = context() {
    _scope(scope);
  }
  final StorePromotionScope scope;
  final StoreCouponGateway gateway;
  final StoreCouponPendingStore pendingStore;
  final Object? Function() context;
  final DateTime Function() now;
  final Object? _lifetime;
  bool _closed = false, ready = false, busy = false;
  bool get active => !_closed && _lifetime != null && context() == _lifetime;
  String? loadedCouponId, message;
  StoreCouponRecord? currentRecord, lastAcknowledged;
  StoreCouponIntent? pending;
  bool supports(StoreCouponInput input) => !input.structured ||
    gateway is StoreStructuredCouponGateway && (gateway as StoreStructuredCouponGateway).structuredCouponTermsSupported;
  Future<bool>? _restoring;
  void _emit() {if (!_closed) notifyListeners();}
  Future<bool> restore() {
    if (!active) return Future.value(false);
    if (ready) return Future.value(true);
    return _restoring ??= _restore().whenComplete(() => _restoring = null);
  }
  Future<bool> _restore() async {
    try {
      final retained = await pendingStore.read(scope).timeout(const Duration(seconds: 10));
      if (!active) return false;
      if (retained != null && retained.scope != scope) throw const FormatException();
      pending = retained; ready = true; message = null;
      return true;
    } on Object {
      if (active) {ready = false; message = 'Saved coupon update could not be opened. Nothing was replaced.';}
      return false;
    } finally {if (active) _emit();}
  }
  Future<bool> refresh(String couponId, {bool Function()? inputCurrent}) async {
    bool current() => active && inputCurrent?.call() != false;
    if (!current() || busy || !gateway.storeCouponTermsSupported) return false;
    _id(couponId); busy = true; _emit();
    try {
      if (!await restore() || !current() || pending != null) return false;
      loadedCouponId = null;
      final result = await gateway.readCoupon(scope, couponId, current).timeout(const Duration(seconds: 25));
      if (!current()) return false;
      if (result != null && (result.scope != scope || result.couponId != couponId || !supports(result.input))) throw const FormatException();
      currentRecord = result; loadedCouponId = couponId; message = null;
      return true;
    } on Object {
      if (active) {loadedCouponId = null; message = 'Current coupon could not be checked. Your draft is kept.';}
      return false;
    } finally {busy = false; _emit();}
  }
  Future<StoreCouponResult> submit(String couponId, StoreCouponInput input,
    {required bool fundingAcknowledged, required bool Function() inputCurrent}) async {
    const notSent = StoreCouponResult(StorePromotionResultState.notSent);
    if (!active || busy || !gateway.storeCouponTermsSupported || !fundingAcknowledged) return notSent;
    if (!supports(input)) {
      message = 'Publishing is not available for this offer yet. Your draft is kept.';
      _emit(); return notSent;
    }
    busy = true; _emit();
    try {
      if (!await restore() || !active || pending != null || loadedCouponId != couponId) return notSent;
      bool current() => active && inputCurrent();
      if (!current()) return notSent;
      input.validateForSave(now());
      if (!input.active && (currentRecord == null || input.fingerprint != currentRecord!.input.paused().fingerprint)) return notSent;
      final original = StoreCouponIntent(scope: scope, couponId: couponId,
        expectedRevision: currentRecord?.revision ?? 0, idempotencyKey: _key(), input: input, fundingAcknowledged: true);
      pending = original;
      try {
        await pendingStore.save(original).timeout(const Duration(seconds: 10));
      } on Object {
        // No transport has begun. Exact cleanup is queued behind real writes.
        try {
          await pendingStore.clear(original).timeout(const Duration(seconds: 10));
          if (active) pending = null;
        } on Object { /* Keep the exact original when local cleanup is uncertain. */ }
        if (active) message = 'Coupon was not sent. Check saved recovery before another update.';
        return notSent;
      }
      if (!active) return const StoreCouponResult(StorePromotionResultState.unknown);
      try {
        if (!current()) return await _finish(original, notSent);
        input.validateForSave(now());
      } on Object {return await _finish(original, notSent);}
      final result = await gateway.saveCoupon(original, current).timeout(const Duration(seconds: 25));
      return await _finish(original, result);
    } on Object {
      if (active) message = pending == null ? 'Check the coupon details.' : 'Check the original coupon update before another save.';
      return StoreCouponResult(pending == null ? StorePromotionResultState.notSent : StorePromotionResultState.unknown);
    } finally {busy = false; _emit();}
  }
  Future<StoreCouponResult> reconcile({bool Function()? inputCurrent}) async {
    bool current() => active && inputCurrent?.call() != false;
    const unknown = StoreCouponResult(StorePromotionResultState.unknown);
    if (!current() || busy || !gateway.storeCouponTermsSupported) return unknown;
    busy = true; _emit();
    try {
      if (!await restore() || !current() || pending == null) return unknown;
      final original = pending!;
      if (!supports(original.input)) {
        message = 'The original offer needs a compatible service. It remains held.'; return unknown;
      }
      final result = await gateway.reconcileCoupon(original, current).timeout(const Duration(seconds: 25));
      if (result.state != StorePromotionResultState.saved) return unknown;
      return await _finish(original, result);
    } on Object {
      if (active) message = 'The original coupon result is still unconfirmed.';
      return unknown;
    } finally {busy = false; _emit();}
  }
  /// Deliberate owner action only. Reuses the frozen ID/key/CAS/terms; an absent
  /// receipt is not rejection, and an unsent retry cannot erase a prior attempt.
  Future<StoreCouponResult> retryOriginal({required bool fundingAcknowledged, bool Function()? inputCurrent}) async {
    bool current() => active && inputCurrent?.call() != false;
    const unknown = StoreCouponResult(StorePromotionResultState.unknown);
    if (!current() || busy || !gateway.storeCouponTermsSupported || !fundingAcknowledged) return unknown;
    busy = true; _emit();
    try {
      if (!await restore() || !current() || pending == null) return unknown;
      final original = pending!;
      if (!supports(original.input)) {
        message = 'The original offer needs a compatible service. It remains held.'; return unknown;
      }
      final result = await gateway.saveCoupon(original, current).timeout(const Duration(seconds: 25));
      if (result.state != StorePromotionResultState.saved) {
        if (active) message = 'The original update is still held. No replacement request was created; check its result again.';
        return unknown;
      }
      return await _finish(original, result);
    } on Object {
      if (active) message = 'The original coupon result is still unconfirmed.';
      return unknown;
    } finally {busy = false; _emit();}
  }
  Future<StoreCouponResult> _finish(StoreCouponIntent original, StoreCouponResult result) async {
    const unknown = StoreCouponResult(StorePromotionResultState.unknown);
    if (!active || pending?.fingerprint != original.fingerprint) return unknown;
    if (result.state == StorePromotionResultState.unknown ||
        result.state == StorePromotionResultState.saved && result.record?.acknowledges(original) != true) {
      message = 'Check the original coupon update before another save.'; return unknown;
    }
    try {
      await pendingStore.clear(original).timeout(const Duration(seconds: 10));
      if (!active) return unknown;
      pending = null; loadedCouponId = null;
      if (result.state == StorePromotionResultState.saved) lastAcknowledged = result.record;
      message = result.state == StorePromotionResultState.saved
        ? 'Coupon update saved. Refresh to check its current state; savings are not confirmed.'
        : 'Coupon was not saved. Refresh before trying again.';
      return result;
    } on Object {message = 'The original coupon update needs checking before another save.'; return unknown;}
  }
  @override void dispose() {_closed = true; super.dispose();}
}

Map<String, dynamic> _map(Object? raw, List<String> keys) {
  if (raw is! Map<String, dynamic> ||
      raw.length != keys.length ||
      keys.any((k) => !raw.containsKey(k))) {
    throw const FormatException('Promotion details could not be checked.');
  }
  return raw;
}

String _text(Object? raw, int maximum) {
  if (raw is! String ||
      raw.isEmpty ||
      raw != raw.trim() ||
      raw.length > maximum ||
      RegExp(r'[\x00-\x08\x0b\x0c\x0e-\x1f]').hasMatch(raw)) {
    throw const FormatException('Check the promotion details.');
  }
  return raw;
}

String _id(Object? raw) {
  final value = _text(raw, 128);
  if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]{2,127}$').hasMatch(value)) {
    throw const FormatException('Check the selected promotion.');
  }
  return value;
}

int _revision(Object? raw, [int minimum = 0]) {
  if (raw is! int || raw < minimum || raw > 1000000000) {
    throw const FormatException('Refresh this promotion.');
  }
  return raw;
}

DateTime _time(Object? raw) {
  final value = _text(raw, 32), at = DateTime.parse(value).toUtc();
  if (at.toIso8601String() != value) {
    throw const FormatException('Check the promotion date.');
  }
  return at;
}

String _iso(DateTime value) => DateTime.fromMillisecondsSinceEpoch(
  value.millisecondsSinceEpoch,
  isUtc: true,
).toIso8601String();
void _scope(StorePromotionScope scope) {
  _id(scope.account);
  _id(scope.store);
  if (!{'evaluation', 'production'}.contains(scope.realm)) {
    throw const FormatException('Check the Store connection.');
  }
}

const _inputKeys = [
  'skuId',
  'skuRevision',
  'channel',
  'headline',
  'detail',
  'validFrom',
  'validUntil',
  'active',
];

/// Complete explicit promotional input, not a price/benefit or targeted-message draft.
@immutable
class StorePromotionInput {
  StorePromotionInput({
    required String skuId,
    required int skuRevision,
    required String channel,
    required String headline,
    required String detail,
    required DateTime validFrom,
    required DateTime validUntil,
    required bool active,
    BuyV2AdvertisedBenefitTerms? benefitTerms,
  }) : _encoded = jsonEncode({
         'skuId': _id(skuId),
         'skuRevision': _revision(skuRevision, 1),
         'channel': channel,
         'headline': _text(headline.trim(), 160),
         'detail': _text(detail.trim(), 2000),
         'validFrom': _iso(validFrom),
         'validUntil': _iso(validUntil),
         'active': active,
         if (benefitTerms != null) 'benefitTerms': benefitTerms.toJson(),
       }) {
    if (!{'retail', 'wholesale', 'bulk'}.contains(channel) ||
        !this.validUntil.isAfter(this.validFrom)) {
      throw const FormatException('Check the channel and promotion dates.');
    }
  }
  final String _encoded;
  String get fingerprint => _encoded;
  Map<String, dynamic> toJson() => jsonDecode(_encoded) as Map<String, dynamic>;
  String get skuId => toJson()['skuId'] as String;
  int get skuRevision => toJson()['skuRevision'] as int;
  String get channel => toJson()['channel'] as String;
  String get headline => toJson()['headline'] as String;
  String get detail => toJson()['detail'] as String;
  DateTime get validFrom => _time(toJson()['validFrom']);
  DateTime get validUntil => _time(toJson()['validUntil']);
  bool get active => toJson()['active'] as bool;
  BuyV2AdvertisedBenefitTerms? get benefitTerms => toJson().containsKey('benefitTerms')
    ? BuyV2AdvertisedBenefitTerms.fromJson(toJson()['benefitTerms']) : null;
  StorePromotionInput paused() =>
      StorePromotionInput.fromJson(toJson()..['active'] = false);
  void validateForSave(DateTime now) {
    if (active && !validUntil.isAfter(now.toUtc())) {
      throw const FormatException('Choose a future promotion expiry.');
    }
  }

  factory StorePromotionInput.fromJson(Object? raw) {
    final row = _map(raw, [..._inputKeys, if (raw is Map && raw.containsKey('benefitTerms')) 'benefitTerms']);
    if (row['active'] is! bool) {
      throw const FormatException('Check the promotion status.');
    }
    return StorePromotionInput(
      skuId: _id(row['skuId']),
      skuRevision: _revision(row['skuRevision'], 1),
      channel: _text(row['channel'], 16),
      headline: _text(row['headline'], 160),
      detail: _text(row['detail'], 2000),
      validFrom: _time(row['validFrom']),
      validUntil: _time(row['validUntil']),
      active: row['active'] as bool,
      benefitTerms: row.containsKey('benefitTerms') ? BuyV2AdvertisedBenefitTerms.fromJson(row['benefitTerms']) : null,
    );
  }
}

@immutable
class StorePromotionIntent {
  StorePromotionIntent({
    required this.scope,
    required this.placementId,
    required this.expectedRevision,
    required this.idempotencyKey,
    required this.input,
  }) {
    _scope(scope);
    _id(placementId);
    _id(idempotencyKey);
    _revision(expectedRevision);
    if (expectedRevision >= 1000000000) {
      throw const FormatException('This promotion needs a service update.');
    }
  }
  final StorePromotionScope scope;
  final String placementId, idempotencyKey;
  final int expectedRevision;
  final StorePromotionInput input;
  Map<String, dynamic> get body => {
    'storeId': scope.store,
    'placementId': placementId,
    'expectedRevision': expectedRevision,
    'idempotencyKey': idempotencyKey,
    'promotion': input.toJson(),
  };
  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'accountId': scope.account,
    'realm': scope.realm,
    ...body,
  };
  String get fingerprint => jsonEncode(toJson());
  factory StorePromotionIntent.fromJson(Object? raw) {
    final row = _map(raw, [
      'schemaVersion',
      'accountId',
      'realm',
      'storeId',
      'placementId',
      'expectedRevision',
      'idempotencyKey',
      'promotion',
    ]);
    if (row['schemaVersion'] != 1) {
      throw const FormatException('Check the saved promotion update.');
    }
    return StorePromotionIntent(
      scope: (
        account: _id(row['accountId']),
        store: _id(row['storeId']),
        realm: _text(row['realm'], 16),
      ),
      placementId: _id(row['placementId']),
      expectedRevision: _revision(row['expectedRevision']),
      idempotencyKey: _id(row['idempotencyKey']),
      input: StorePromotionInput.fromJson(row['promotion']),
    );
  }
}

@immutable
class StorePromotionRecord {
  const StorePromotionRecord._(
    this.scope,
    this.placementId,
    this.revision,
    this.observedAt,
    this.input,
  );
  final StorePromotionScope scope;
  final String placementId;
  final int revision;
  final DateTime observedAt;
  final StorePromotionInput input;
  static StorePromotionRecord decode(
    Object? raw,
    StorePromotionScope scope,
    DateTime now,
  ) {
    _scope(scope);
    final row = _map(raw, [
      ..._inputKeys,
      if (raw is Map && raw.containsKey('benefitTerms')) 'benefitTerms',
      'schemaVersion',
      'realm',
      'storeId',
      'placementId',
      'revision',
      'observedAt',
    ]);
    final observed = _time(row['observedAt']);
    if (row['schemaVersion'] != 1 ||
        row['realm'] != scope.realm ||
        row['storeId'] != scope.store ||
        observed.isAfter(now.toUtc())) {
      throw const FormatException('Promotion details changed. Refresh them.');
    }
    return StorePromotionRecord._(
      scope,
      _id(row['placementId']),
      _revision(row['revision'], 1),
      observed,
      StorePromotionInput.fromJson({
        for (final key in _inputKeys) key: row[key],
        if (row.containsKey('benefitTerms')) 'benefitTerms': row['benefitTerms'],
      }),
    );
  }

  bool acknowledges(StorePromotionIntent original) =>
      scope == original.scope &&
      placementId == original.placementId &&
      revision == original.expectedRevision + 1 &&
      input.fingerprint == original.input.fingerprint;
}

enum StorePromotionResultState { saved, notSent, rejected, unknown }

class StorePromotionResult {
  const StorePromotionResult(this.state, {this.record});
  final StorePromotionResultState state;
  final StorePromotionRecord? record;
  bool get publicationConfirmed => false;
}

class StorePromotionPage {
  StorePromotionPage(List<StorePromotionRecord> records, this.nextCursor)
    : records = List.unmodifiable(records);
  final List<StorePromotionRecord> records;
  final String? nextCursor;
}

abstract interface class StorePromotionGateway {
  Future<StorePromotionRecord?> read(
    StorePromotionScope scope,
    String placementId,
    bool Function() current,
  );
  Future<StorePromotionPage> list(
    StorePromotionScope scope,
    bool Function() current, {
    String? after,
    int limit = 20,
  });
  Future<StorePromotionResult> save(
    StorePromotionIntent original,
    bool Function() current,
  );
  Future<StorePromotionResult> reconcile(
    StorePromotionIntent original,
    bool Function() current,
  );
}

class _NotSent implements Exception {}

abstract interface class StorePromotionTermsCapability {
  bool get benefitTermsSupported;
}

/// Explicit v2 transport capability. The ordinary v1 gateway never acquires
/// structured support merely from receiving a structured server record.
class AuthenticatedStructuredStorePromotionGateway extends AuthenticatedStorePromotionGateway
    implements StoreStructuredCouponGateway {
  AuthenticatedStructuredStorePromotionGateway({required super.endpoint, required super.credentials,
    required super.transport, required super.ownerAccountId, required super.realm,
    required super.storeCouponTermsSupported, super.storeCouponDraftsSupported, super.benefitTermsSupported, super.now});
  @override int get _couponTermsVersion => 2;
  @override bool get structuredCouponTermsSupported => storeCouponTermsSupported;
}

class AuthenticatedStorePromotionGateway implements StorePromotionGateway, StorePromotionTermsCapability, StoreCouponGateway, StoreCouponDraftGateway {
  AuthenticatedStorePromotionGateway({
    required this.endpoint,
    required this.credentials,
    required this.transport,
    required this.ownerAccountId,
    required this.realm,
    this.benefitTermsSupported = false,
    this.storeCouponTermsSupported = false,
    this.storeCouponDraftsSupported = false,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now {
    if (endpoint.scheme != 'https' ||
        endpoint.host !=
            'asia-south1-moolsocial-dev-503018.cloudfunctions.net' ||
        endpoint.path != '/moolSocialWorkspace' ||
        endpoint.hasQuery ||
        endpoint.hasFragment ||
        endpoint.hasPort ||
        endpoint.userInfo.isNotEmpty ||
        !{'evaluation', 'production'}.contains(realm)) {
      throw ArgumentError('Invalid Store connection.');
    }
    _id(ownerAccountId);
  }
  final Uri endpoint;
  final SocialContentCredentials credentials;
  final SocialContentTransport transport;
  final String ownerAccountId, realm;
  @override final bool benefitTermsSupported;
  @override final bool storeCouponTermsSupported;
  @override final bool storeCouponDraftsSupported;
  final DateTime Function() now;
  int get _couponTermsVersion => 1;
  void _check(StorePromotionScope scope, bool Function() current) {
    _scope(scope);
    if (scope.account != ownerAccountId || scope.realm != realm || !current()) {
      throw _NotSent();
    }
  }

  Future<SocialContentResponse> _request(
    StorePromotionScope scope,
    Map<String, dynamic> body,
    bool Function() current, {
    required bool mutation,
    required void Function() onSend,
    void Function()? beforeSend,
    bool storeCoupon = false,
    bool couponDraft = false,
  }) async {
    _check(scope, current);
    if (couponDraft && (!storeCouponDraftsSupported || storeCoupon ||
        utf8.encode(jsonEncode(body)).length > 8 * 1024 * 1024)) throw _NotSent();
    if (storeCoupon && !storeCouponTermsSupported) throw _NotSent();
    final couponVersion = body['storeCouponTermsVersion'] ?? _couponTermsVersion;
    if (storeCoupon && (couponVersion != 1 && couponVersion != 2 ||
        couponVersion == 2 && _couponTermsVersion != 2 ||
        couponVersion == 2 && utf8.encode(jsonEncode(body)).length > 8 * 1024 * 1024)) throw _NotSent();
    if (!benefitTermsSupported && body['promotion'] is Map && (body['promotion'] as Map).containsKey('benefitTerms')) {
      throw _NotSent();
    }
    final token = await credentials.firebaseIdToken();
    _check(scope, current);
    final check = await credentials.appCheckToken(
      mutation
          ? SocialAppCheckTokenMode.limitedUse
          : SocialAppCheckTokenMode.standard,
    );
    _check(scope, current);
    beforeSend?.call();
    if (token.isEmpty || check.isEmpty) throw _NotSent();
    onSend();
    return transport
        .postJson(
          endpoint,
          headers: {
            'accept': 'application/json',
            'authorization': 'Bearer $token',
            'x-firebase-appcheck': check,
            'x-request-id': _key(),
          },
          body: {...body, if (storeCoupon) 'storeCouponTermsVersion': couponVersion,
            if (couponDraft) 'storeCouponDraftVersion': 1,
            if (!storeCoupon && !couponDraft && benefitTermsSupported) 'promotionTermsVersion': 1},
        )
        .timeout(const Duration(seconds: 20));
  }

  Map<String, dynamic> _couponEnvelope(SocialContentResponse response, StorePromotionScope scope, List<String> fields, {int? termsVersion}) {
    if (response.statusCode != 200) throw const FormatException('Coupons could not be checked.');
    final expectedVersion = termsVersion ?? _couponTermsVersion;
    if (expectedVersion == 2 && utf8.encode(response.body).length > 8 * 1024 * 1024) {
      throw const FormatException('Coupon response is too large.');
    }
    final envelope = jsonDecode(response.body);
    if (envelope is! Map || envelope['ok'] != true) throw const FormatException('Coupons could not be checked.');
    final row = _map(envelope['data'], ['schemaVersion', 'storeCouponTermsVersion', 'realm', 'storeId',
      'orderingAvailable', 'redemptionAvailable', 'publicationConfirmed', ...fields]);
    if (row['schemaVersion'] != 1 || row['storeCouponTermsVersion'] != expectedVersion || row['realm'] != scope.realm ||
        row['storeId'] != scope.store || row['orderingAvailable'] != false ||
        row['redemptionAvailable'] != false || row['publicationConfirmed'] != false) {
      throw const FormatException('Coupon response changed.');
    }
    return row;
  }
  StoreCouponRecord? _couponRecord(SocialContentResponse response, StorePromotionScope scope, String couponId, {int? termsVersion}) {
    final row = _couponEnvelope(response, scope, ['record'], termsVersion: termsVersion);
    if (row['record'] == null) return null;
    final value = StoreCouponRecord.decode(row['record'], scope, now());
    if (value.couponId != couponId || value.input.structured && (termsVersion ?? _couponTermsVersion) != 2) throw const FormatException('Wrong or unsupported coupon returned.');
    return value;
  }
  @override
  Future<StoreCouponRecord?> readCoupon(StorePromotionScope scope, String couponId, bool Function() current) async {
    _id(couponId);
    final response = await _request(scope, {'operation': 'readStoreCoupon', 'storeId': scope.store, 'couponId': couponId},
      current, mutation: false, onSend: () {}, storeCoupon: true);
    _check(scope, current);
    return _couponRecord(response, scope, couponId);
  }
  /// Exact observational head for private-draft preparation. Only an explicit
  /// unavailable response differs from a successful original read returning null.
  Future<({bool available, StoreCouponRecord? record})> readCouponPreparationHead(
      StorePromotionScope scope, String couponId, bool Function() current) async {
    _check(scope, current);
    if (_couponTermsVersion != 2 || !storeCouponTermsSupported) return (available: false, record: null);
    _id(couponId);
    final response = await _request(scope, {'operation': 'readStoreCoupon', 'storeId': scope.store,
      'couponId': couponId, 'storeCouponTermsVersion': 2}, current, mutation: false, onSend: () {}, storeCoupon: true);
    _check(scope, current);
    if (response.statusCode == 503) return (available: false, record: null);
    return (available: true, record: _couponRecord(response, scope, couponId, termsVersion: 2));
  }
  @override
  Future<StoreCouponPage> listCoupons(StorePromotionScope scope, bool Function() current, {String? after, int limit = 20}) async {
    if (limit < 1 || limit > 20) throw const FormatException('Check the coupon page.');
    if (after != null) _id(after);
    final response = await _request(scope, {'operation': 'listStoreCoupons', 'storeId': scope.store, 'limit': limit, 'after': ?after},
      current, mutation: false, onSend: () {}, storeCoupon: true);
    _check(scope, current);
    final row = _couponEnvelope(response, scope, ['items', 'nextCursor']), items = row['items'];
    if (items is! List || items.length > limit) throw const FormatException('Coupon page changed.');
    final values = <StoreCouponRecord>[];
    var previous = after;
    for (final item in items) {
      final value = StoreCouponRecord.decode(item, scope, now());
      if (value.input.structured && _couponTermsVersion != 2) throw const FormatException('This service does not support structured offers.');
      if (previous != null && value.couponId.compareTo(previous) <= 0) throw const FormatException('Coupon page order changed.');
      values.add(value); previous = value.couponId;
    }
    final next = row['nextCursor'] == null ? null : _id(row['nextCursor']);
    if (_couponTermsVersion == 1 ? next != (values.length == limit ? values.last.couponId : null) :
        next != null && (values.isEmpty || next != values.last.couponId)) throw const FormatException('Coupon cursor changed.');
    return StoreCouponPage(values, next);
  }
  @override
  Future<StoreCouponResult> saveCoupon(StoreCouponIntent original, bool Function() current) => _writeCoupon(original, current, recovery: false);
  @override
  Future<StoreCouponResult> reconcileCoupon(StoreCouponIntent original, bool Function() current) => _writeCoupon(original, current, recovery: true);
  Future<StoreCouponResult> _writeCoupon(StoreCouponIntent original, bool Function() current, {required bool recovery}) async {
    if (original.input.structured && _couponTermsVersion != 2) {
      return StoreCouponResult(recovery ? StorePromotionResultState.unknown : StorePromotionResultState.notSent);
    }
    var sent = false;
    try {
      if (!recovery) original.input.validateForSave(now());
      final version = original.input.structured ? 2 : 1;
      final response = await _request(original.scope, {'operation': recovery ? 'reconcileStoreCoupon' : 'saveStoreCoupon',
        ...original.body, 'storeCouponTermsVersion': version},
        current, mutation: !recovery, onSend: () => sent = true, storeCoupon: true,
        beforeSend: recovery ? null : () => original.input.validateForSave(now()));
      _check(original.scope, current);
      if (!recovery && response.statusCode >= 400 && response.statusCode < 500) {
        final error = jsonDecode(response.body);
        if (error is Map && error['ok'] == false && error['error'] is Map &&
            {'invalid_input', 'conflict', 'not_found', 'invalid_state', 'forbidden', 'authentication_required'}.contains(error['error']['code'])) {
          return const StoreCouponResult(StorePromotionResultState.rejected);
        }
      }
      final record = _couponRecord(response, original.scope, original.couponId, termsVersion: version);
      return record?.acknowledges(original) == true
        ? StoreCouponResult(StorePromotionResultState.saved, record: record)
        : const StoreCouponResult(StorePromotionResultState.unknown);
    } on Object {
      return StoreCouponResult(sent || recovery ? StorePromotionResultState.unknown : StorePromotionResultState.notSent);
    }
  }

  Map<String, dynamic> _couponDraftEnvelope(SocialContentResponse response, StorePromotionScope scope, List<String> fields) {
    if (response.statusCode != 200 || utf8.encode(response.body).length > 8 * 1024 * 1024) {
      throw const FormatException('The original draft could not be checked.');
    }
    final envelope = jsonDecode(response.body);
    if (envelope is! Map || envelope['ok'] != true) throw const FormatException('Draft source unavailable.');
    final row = _map(envelope['data'], ['schemaVersion', 'storeCouponDraftVersion', 'accountId',
      'realm', 'storeId', 'observedAt', 'publicationConfirmed', ...fields]);
    if (row['schemaVersion'] is! int || row['schemaVersion'] != 1 || row['storeCouponDraftVersion'] is! int ||
        row['storeCouponDraftVersion'] != 1 || row['accountId'] != scope.account || row['realm'] != scope.realm ||
        row['storeId'] != scope.store || row['publicationConfirmed'] != false || _time(row['observedAt']).isAfter(now().toUtc())) {
      throw const FormatException('The original draft scope changed.');
    }
    return row;
  }
  StoreCouponDraftRecord? _couponDraftRecord(SocialContentResponse response, StorePromotionScope scope, String couponId) {
    final row = _couponDraftEnvelope(response, scope, ['record']);
    if (row['record'] == null) return null;
    final record = StoreCouponDraftRecord.decode(row['record'], scope, now());
    if (record.couponId != couponId || record.observedAt.isAfter(_time(row['observedAt']))) throw const FormatException('Wrong original draft.');
    return record;
  }
  @override
  Future<StoreCouponDraftRecord?> readCouponDraft(StorePromotionScope scope, String couponId, bool Function() current) async {
    _text(couponId, 128);
    final response = await _request(scope, {'operation': 'readStoreCouponDraft', 'storeId': scope.store, 'couponId': couponId},
      current, mutation: false, onSend: () {}, couponDraft: true);
    _check(scope, current);
    return _couponDraftRecord(response, scope, couponId);
  }
  @override
  Future<StoreCouponDraftPage> listCouponDrafts(StorePromotionScope scope, bool Function() current, {String? after, int limit = 20}) async {
    if (limit < 1 || limit > 20 || after != null && !RegExp(r'^[a-f0-9]{64}$').hasMatch(after)) throw const FormatException('Check the draft page.');
    final response = await _request(scope, {'operation': 'listStoreCouponDrafts', 'storeId': scope.store, 'limit': limit, 'after': ?after},
      current, mutation: false, onSend: () {}, couponDraft: true);
    _check(scope, current);
    final row = _couponDraftEnvelope(response, scope, ['items', 'nextCursor']), items = row['items'];
    if (items is! List || items.length > limit) throw const FormatException('Draft page changed.');
    final records = <StoreCouponDraftRecord>[];
    var previous = after;
    for (final value in items) {
      final record = StoreCouponDraftRecord.decode(value, scope, now());
      final cursor = crypto.sha256.convert(utf8.encode(jsonEncode([scope.account, record.couponId]))).toString();
      if (previous != null && cursor.compareTo(previous) <= 0 || record.observedAt.isAfter(_time(row['observedAt']))) {
        throw const FormatException('Draft page order changed.');
      }
      records.add(record); previous = cursor;
    }
    final cursor = row['nextCursor'];
    if (cursor != null && (cursor is! String || !RegExp(r'^[a-f0-9]{64}$').hasMatch(cursor) || records.isEmpty || cursor != previous)) {
      throw const FormatException('Draft continuation changed.');
    }
    return StoreCouponDraftPage(records, cursor as String?);
  }
  @override
  Future<StoreCouponDraftResult> saveCouponDraft(StoreCouponDraftIntent intent, bool Function() current) => _writeCouponDraft(intent, current, recovery: false);
  @override
  Future<StoreCouponDraftResult> reconcileCouponDraft(StoreCouponDraftIntent intent, bool Function() current) => _writeCouponDraft(intent, current, recovery: true);
  Future<StoreCouponDraftResult> _writeCouponDraft(StoreCouponDraftIntent intent, bool Function() current, {required bool recovery}) async {
    var sent = false;
    try {
      StoreCouponDraftIntent.fromJson(intent.toJson());
      final response = await _request(intent.scope, {'operation': recovery ? 'reconcileStoreCouponDraft' : 'saveStoreCouponDraft', ...intent.body},
        current, mutation: !recovery, onSend: () => sent = true, couponDraft: true);
      _check(intent.scope, current);
      if (!recovery && response.statusCode >= 400 && response.statusCode < 500) {
        final error = jsonDecode(response.body);
        if (error is Map && error['ok'] == false && error['error'] is Map &&
            {'invalid_input', 'conflict', 'not_found', 'invalid_state', 'forbidden', 'authentication_required'}.contains(error['error']['code'])) {
          return const StoreCouponDraftResult(StorePromotionResultState.rejected);
        }
      }
      final record = _couponDraftRecord(response, intent.scope, intent.couponId);
      return record?.acknowledges(intent) == true ? StoreCouponDraftResult(StorePromotionResultState.saved, record: record) :
        const StoreCouponDraftResult(StorePromotionResultState.unknown);
    } on Object {
      return StoreCouponDraftResult(sent || recovery ? StorePromotionResultState.unknown : StorePromotionResultState.notSent);
    }
  }

  Map<String, dynamic> _envelope(
    SocialContentResponse response,
    StorePromotionScope scope,
    List<String> fields,
  ) {
    if (response.statusCode != 200) {
      throw const FormatException('Promotions could not be checked.');
    }
    final envelope = jsonDecode(response.body);
    if (envelope is! Map || envelope['ok'] != true) {
      throw const FormatException('Promotions could not be checked.');
    }
    final row = _map(envelope['data'], [
      'schemaVersion',
      'realm',
      'storeId',
      'publicationConfirmed',
      if (benefitTermsSupported) 'promotionTermsVersion',
      ...fields,
    ]);
    if (row['schemaVersion'] is! int || row['schemaVersion'] != 1 ||
        benefitTermsSupported && (row['promotionTermsVersion'] is! int || row['promotionTermsVersion'] != 1) ||
        row['realm'] != scope.realm ||
        row['storeId'] != scope.store ||
        row['publicationConfirmed'] != false) {
      throw const FormatException('Promotion response changed.');
    }
    return row;
  }

  StorePromotionRecord? _record(
    SocialContentResponse response,
    StorePromotionScope scope,
    String placementId,
  ) {
    final row = _envelope(response, scope, ['record']);
    if (row['record'] == null) return null;
    final result = StorePromotionRecord.decode(row['record'], scope, now());
    if (result.input.benefitTerms != null && !benefitTermsSupported) throw const FormatException();
    if (result.placementId != placementId) {
      throw const FormatException('Wrong promotion returned.');
    }
    return result;
  }

  @override
  Future<StorePromotionRecord?> read(
    StorePromotionScope scope,
    String placementId,
    bool Function() current,
  ) async {
    _id(placementId);
    final response = await _request(
      scope,
      {
        'operation': 'readStorePromotion',
        'storeId': scope.store,
        'placementId': placementId,
      },
      current,
      mutation: false,
      onSend: () {},
    );
    _check(scope, current);
    return _record(response, scope, placementId);
  }

  @override
  Future<StorePromotionPage> list(
    StorePromotionScope scope,
    bool Function() current, {
    String? after,
    int limit = 20,
  }) async {
    if (limit < 1 || limit > 20) {
      throw const FormatException('Check the requested page.');
    }
    if (after != null) _id(after);
    final response = await _request(
      scope,
      {
        'operation': 'listStorePromotions',
        'storeId': scope.store,
        'limit': limit,
        'after': ?after,
      },
      current,
      mutation: false,
      onSend: () {},
    );
    _check(scope, current);
    final row = _envelope(response, scope, ['items', 'nextCursor']),
        items = row['items'];
    if (items is! List || items.length > limit) {
      throw const FormatException('Promotion page changed.');
    }
    final records = <StorePromotionRecord>[];
    var previous = after;
    for (final item in items) {
      final value = StorePromotionRecord.decode(item, scope, now());
      if (value.input.benefitTerms != null && !benefitTermsSupported) throw const FormatException();
      if (previous != null && value.placementId.compareTo(previous) <= 0) {
        throw const FormatException('Promotion page order changed.');
      }
      previous = value.placementId;
      records.add(value);
    }
    final next = row['nextCursor'] == null ? null : _id(row['nextCursor']);
    if (next != (records.length == limit ? records.last.placementId : null)) {
      throw const FormatException('Promotion page changed.');
    }
    return StorePromotionPage(records, next);
  }

  @override
  Future<StorePromotionResult> save(
    StorePromotionIntent original,
    bool Function() current,
  ) => _write(original, current, recovery: false);
  @override
  Future<StorePromotionResult> reconcile(
    StorePromotionIntent original,
    bool Function() current,
  ) => _write(original, current, recovery: true);
  Future<StorePromotionResult> _write(
    StorePromotionIntent original,
    bool Function() current, {
    required bool recovery,
  }) async {
    var sent = false;
    try {
      if (!recovery) original.input.validateForSave(now());
      final response = await _request(
        original.scope,
        {
          'operation': recovery
              ? 'reconcileStorePromotion'
              : 'saveStorePromotion',
          ...original.body,
        },
        current,
        mutation: !recovery,
        onSend: () => sent = true,
        beforeSend: recovery
            ? null
            : () => original.input.validateForSave(now()),
      );
      _check(original.scope, current);
      if (!recovery &&
          response.statusCode >= 400 &&
          response.statusCode < 500) {
        final error = jsonDecode(response.body);
        if (error is Map &&
            error['ok'] == false &&
            error['error'] is Map &&
            {
              'invalid_input',
              'conflict',
              'not_found',
              'invalid_state',
              'forbidden',
              'authentication_required',
            }.contains(error['error']['code'])) {
          return const StorePromotionResult(StorePromotionResultState.rejected);
        }
      }
      final result = _record(response, original.scope, original.placementId);
      return result?.acknowledges(original) == true
          ? StorePromotionResult(
              StorePromotionResultState.saved,
              record: result,
            )
          : const StorePromotionResult(StorePromotionResultState.unknown);
    } on Object {
      return StorePromotionResult(
        sent || recovery
            ? StorePromotionResultState.unknown
            : StorePromotionResultState.notSent,
      );
    }
  }
}

String _key() =>
    'promotion-${List.generate(16, (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';

/// One exact unresolved request per account/Store/realm; native implementation serializes across instances.
abstract interface class StorePromotionPendingStore {
  Future<StorePromotionIntent?> read(StorePromotionScope scope);
  Future<void> save(StorePromotionIntent original);
  Future<void> clear(StorePromotionIntent original);
}

class StorePromotionController extends ChangeNotifier {
  StorePromotionController({
    required this.scope,
    required this.gateway,
    required this.pendingStore,
    required this.context,
    required this.validateSelection,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now,
       _lifetime = context() {
    _scope(scope);
  }
  final StorePromotionScope scope;
  final StorePromotionGateway gateway;
  bool get benefitTermsSupported => gateway is StorePromotionTermsCapability &&
    (gateway as StorePromotionTermsCapability).benefitTermsSupported;
  final StorePromotionPendingStore pendingStore;
  final Object? Function() context;
  final Future<bool> Function(
    StorePromotionInput input,
    bool Function() current,
  )
  validateSelection;
  final DateTime Function() now;
  final Object? _lifetime;
  bool _closed = false, ready = false, busy = false;
  String? loadedPlacementId, message;
  StorePromotionRecord? currentRecord, lastAcknowledged;
  StorePromotionIntent? pending;
  Future<bool>? _restoring;
  bool get active => !_closed && _lifetime != null && context() == _lifetime;
  void _emit() {
    if (!_closed) notifyListeners();
  }

  Future<bool> restore() {
    if (!active) return Future.value(false);
    if (ready) return Future.value(true);
    return _restoring ??= _restore().whenComplete(() => _restoring = null);
  }

  Future<bool> _restore() async {
    try {
      final retained = await pendingStore
          .read(scope)
          .timeout(const Duration(seconds: 10));
      if (!active) return false;
      if (retained != null && retained.scope != scope) {
        throw const FormatException();
      }
      pending = retained;
      ready = true;
      message = null;
      return true;
    } on Object {
      if (active) {
        ready = false;
        message = 'Saved promotion update could not be opened. Try again.';
      }
      return false;
    } finally {
      if (active) _emit();
    }
  }

  Future<bool> refresh(String placementId) async {
    if (!active || busy) return false;
    _id(placementId);
    busy = true;
    _emit();
    try {
      if (!await restore() || !active || pending != null) return false;
      loadedPlacementId = null;
      final result = await gateway
          .read(scope, placementId, () => active)
          .timeout(const Duration(seconds: 25));
      if (!active) return false;
      if (result != null &&
          (result.scope != scope || result.placementId != placementId)) {
        throw const FormatException();
      }
      currentRecord = result;
      loadedPlacementId = placementId;
      message = null;
      return true;
    } on Object {
      if (active) {
        loadedPlacementId = null;
        message =
            'Current promotion could not be checked. Your entries are kept.';
      }
      return false;
    } finally {
      busy = false;
      _emit();
    }
  }

  Future<StorePromotionResult> submit(
    String placementId,
    StorePromotionInput input, {
    bool Function()? inputCurrent,
  }) async {
    const notSent = StorePromotionResult(StorePromotionResultState.notSent);
    if (!active || busy) return notSent;
    busy = true;
    _emit();
    try {
      if (!await restore() ||
          !active ||
          pending != null ||
          loadedPlacementId != placementId) {
        return notSent;
      }
      bool current() => active && (inputCurrent?.call() ?? true);
      input.validateForSave(now());
      final old = currentRecord;
      if (!input.active) {
        if (old == null ||
            input.fingerprint != old.input.paused().fingerprint) {
          return notSent;
        }
      } else if (!await validateSelection(input, current) || !current()) {
        message =
            'The saved product or channel changed. Refresh before saving.';
        return notSent;
      }
      final original = StorePromotionIntent(
        scope: scope,
        placementId: placementId,
        expectedRevision: old?.revision ?? 0,
        idempotencyKey: _key(),
        input: input,
      );
      pending = original;
      try {
        await pendingStore.save(original).timeout(const Duration(seconds: 10));
      } on Object {
        // Nothing was dispatched. Remove only this original if storage can confirm it.
        try {
          await pendingStore
              .clear(original)
              .timeout(const Duration(seconds: 10));
          if (active) pending = null;
        } on Object {
          // Keep this exact original held when its durable cleanup is uncertain.
        }
        if (active) {
          message = 'Promotion was not sent. Saved recovery needs checking.';
        }
        return notSent;
      }
      if (!active) {
        return const StorePromotionResult(StorePromotionResultState.unknown);
      }
      // Still before transport: expiry/changed form is demonstrably unsent.
      // A failed exact cleanup remains held instead of inventing a missing receipt.
      try {
        if (!current()) return await _finish(original, notSent);
        input.validateForSave(now());
      } on Object {
        return await _finish(original, notSent);
      }
      final result = await gateway
          .save(original, current)
          .timeout(const Duration(seconds: 25));
      return await _finish(original, result);
    } on Object {
      if (active) {
        message = pending == null
            ? 'Check the promotion details.'
            : 'Check the original promotion update before another save.';
      }
      return StorePromotionResult(
        pending == null
            ? StorePromotionResultState.notSent
            : StorePromotionResultState.unknown,
      );
    } finally {
      busy = false;
      _emit();
    }
  }

  Future<StorePromotionResult> reconcile() async {
    const unknown = StorePromotionResult(StorePromotionResultState.unknown);
    if (!active || busy) return unknown;
    busy = true;
    _emit();
    try {
      if (!await restore() || !active || pending == null) return unknown;
      final original = pending!;
      final result = await gateway
          .reconcile(original, () => active)
          .timeout(const Duration(seconds: 25));
      if (result.state != StorePromotionResultState.saved) return unknown;
      return await _finish(original, result);
    } on Object {
      if (active) message = 'The original result is still unconfirmed.';
      return unknown;
    } finally {
      busy = false;
      _emit();
    }
  }

  Future<StorePromotionResult> _finish(
    StorePromotionIntent original,
    StorePromotionResult result,
  ) async {
    const unknown = StorePromotionResult(StorePromotionResultState.unknown);
    if (!active || pending?.fingerprint != original.fingerprint) return unknown;
    if (result.state == StorePromotionResultState.unknown ||
        result.state == StorePromotionResultState.saved &&
            result.record?.acknowledges(original) != true) {
      message = 'Check the original promotion update before another save.';
      return unknown;
    }
    try {
      await pendingStore.clear(original).timeout(const Duration(seconds: 10));
      if (!active) return unknown;
      pending = null;
      loadedPlacementId = null;
      if (result.state == StorePromotionResultState.saved) {
        lastAcknowledged = result.record;
      }
      message = result.state == StorePromotionResultState.saved
          ? 'Promotion update saved. Refresh to check its current state; public visibility is unconfirmed.'
          : 'Promotion was not saved. Refresh before trying again.';
      return result;
    } on Object {
      message = 'The original update needs checking before another save.';
      return unknown;
    }
  }

  @override
  void dispose() {
    _closed = true;
    super.dispose();
  }
}
