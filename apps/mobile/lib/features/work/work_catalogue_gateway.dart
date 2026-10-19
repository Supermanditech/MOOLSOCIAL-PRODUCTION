import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart' as crypto;

import '../buy/buy_v2_content_contracts.dart';
import '../buy/buy_v2_models.dart';
import '../shared/social_content_gateway.dart';
import 'work_publication_data.dart';
import 'work_models.dart' show WorkspaceVariantFamily, WorkspaceVariantMembership, WorkspaceCatalogueItem,
  WorkspaceSavedInventory, WorkspaceStockMode,
  WorkspaceAnalyticsRequest, WorkspaceAnalyticsSnapshot, WorkspaceAnalyticsState, WorkspaceAnalyticsCoverage,
  WorkspaceAnalyticsMetric, WorkspaceAnalyticsBasis, WorkspaceAnalyticsUnit, WorkspaceAnalyticsBreakdown,
  WorkspaceAnalyticsDimension, WorkspaceAnalyticsRank;

/// Read-only public catalogue content, never an order/price/Stock authority.
abstract interface class WorkspaceCatalogueGateway {
  Future<WorkspaceCatalogueContentResult> read(BuyV2Product product);
}

abstract interface class WorkspacePublicProductGateway {
  Future<WorkspacePublicCatalogueEntry?> readPublicEntry({
    required String storeId, required String skuId, required BuyV2OfferClass channel,
    required bool Function() current,
  });
}

typedef WorkspaceVariantFamilyScope = ({String account, String store, String realm, String family});

typedef WorkspaceProductSubmissionScope = ({String account, String store, String realm, String sku});

typedef WorkspaceStoreStockScope = ({String account, String store, String realm, String sku});

Map<String, dynamic> _stockBinding(Object? raw) {
  final b = _map(jsonDecode(jsonEncode(raw)));
  _keys(b, ['skuId', 'skuRevision', 'canonicalProductId', 'verifiedPackId']);
  _id(b['skuId']); _id(b['canonicalProductId']); _id(b['verifiedPackId']); _int(b['skuRevision'], 1, 1000000000);
  return b;
}
DateTime _stockTime(Object? raw) {
  final text = _string(raw, 24), value = DateTime.parse(text).toUtc();
  if (value.toIso8601String() != text || text.length != 24) throw const FormatException('Stock time needs recovery.');
  return value;
}
Map<String, dynamic> _stockCheckpoint(Object? raw) {
  final s = _map(jsonDecode(jsonEncode(raw)));
  _keys(s, ['inventoryRevision', 'savedAt', 'mode', 'quantityPacks', 'available']);
  _int(s['inventoryRevision'], 1, 1000000000); _stockTime(s['savedAt']);
  if (!{'exact_quantity', 'availability_only'}.contains(s['mode']) || s['available'] is! bool ||
      s['mode'] == 'availability_only' && s['quantityPacks'] != null) { throw const FormatException(); }
  if (s['mode'] == 'exact_quantity') { _int(s['quantityPacks'], 0, 1000000000); }
  return s;
}
void _stockScope(WorkspaceStoreStockScope scope) {
  _id(scope.account); _id(scope.store); _id(scope.sku);
  if (!{'production', 'evaluation'}.contains(scope.realm)) throw const FormatException();
}

/// Captures an existing saved selling pack. Never serializes the inventory,
/// opening quantity, costs, movements, private images or unrelated products.
class WorkspaceStoreStockInput {
  WorkspaceStoreStockInput._(this._encoded);
  final String _encoded;
  Map<String, dynamic> toJson() => _map(jsonDecode(_encoded));
  Map<String, dynamic> get binding => _map(toJson()['binding']);
  Map<String, dynamic> get source => _map(toJson()['source']);
  static WorkspaceStoreStockInput fromJson(Object? raw) {
    final value = _map(raw); _keys(value, ['binding', 'source']);
    return WorkspaceStoreStockInput._(jsonEncode(_sorted({'binding': _stockBinding(value['binding']),
      'source': _stockCheckpoint(value['source'])})));
  }
  static WorkspaceStoreStockInput fromSaved(WorkspaceSavedInventory saved, WorkspaceCatalogueOwnedSku mirror,
      {required WorkspaceStoreStockScope scope, required DateTime now}) {
    _stockScope(scope); now = now.toUtc();
    final items = saved.products.where((p) => p.id == scope.sku).toList(growable: false);
    final links = saved.reviewedCatalogueLinks.where((l) => l.skuId == scope.sku).toList(growable: false);
    if (saved.account != scope.account || saved.store != scope.store || saved.qa != (scope.realm == 'evaluation') ||
        saved.revision <= 0 || saved.savedAt.isAfter(now) || !saved.savedAt.add(const Duration(minutes: 5)).isAfter(now) ||
        items.length != 1 || links.length != 1 || mirror.realm != scope.realm || mirror.storeId != scope.store || mirror.skuId != scope.sku) {
      throw const FormatException('Recover and save current Store Stock first.');
    }
    final item = WorkspaceCatalogueItem.fromInventoryJson(jsonDecode(jsonEncode(items.single.toInventoryJson()))), link = links.single;
    final origin = item.stockEntry, measure = item.packMeasure;
    if (!link.valid || link.realm != scope.realm || link.storeId != scope.store || link.mirrorRevision != mirror.revision ||
        link.canonicalProductId != mirror.canonicalProductId || link.verifiedPackId != mirror.verifiedPackId ||
        !item.publicListing || mirror.input['publicListing'] != true || origin?.valid != true || origin!.productId != item.id ||
        origin.pack != item.pack || measure?.valid != true) { throw const FormatException('Check this saved SKU and selling pack.'); }
    final pack = {'label': item.pack, 'quantityMilli': measure!.quantityMilli,
      'unit': measure.unitLabel == 'unit' ? 'count' : measure.unitLabel, 'unitsPerCase': measure.unitsPerCase};
    if (_catalogueHash(pack) != _catalogueHash(mirror.input['pack'])) throw const FormatException('The reviewed selling pack changed.');
    final content = _map(mirror.input['content']);
    final identity = {'sku': item.sku, 'title': item.title, 'brand': item.brand, 'variant': item.variant, 'categoryId': item.categoryId};
    final reviewedIdentity = {'sku': mirror.input['sku'], for (final field in ['title', 'brand', 'variant', 'categoryId']) field: content[field]};
    if (_catalogueHash(identity) != _catalogueHash(reviewedIdentity) ||
        _catalogueHash({'entryMethod': origin.method.name, 'sourceRecordId': item.id}) != _catalogueHash(mirror.input['provenance'])) {
      throw const FormatException('Review the changed product identity before reporting its Stock.');
    }
    WorkspaceVariantFamily.validateInventory(saved.variantFamilies, saved.products);
    // Stock v1 transports UTC milliseconds. The original local checkpoint and
    // its exact savedAt/revision remain unchanged; only this allowlist is sent.
    final transportTime = DateTime.fromMillisecondsSinceEpoch(saved.savedAt.toUtc().millisecondsSinceEpoch, isUtc: true);
    return fromJson({'binding': {'skuId': scope.sku, 'skuRevision': mirror.revision,
      'canonicalProductId': mirror.canonicalProductId, 'verifiedPackId': mirror.verifiedPackId},
      'source': {'inventoryRevision': saved.revision, 'savedAt': transportTime.toIso8601String(),
        'mode': item.stockMode == WorkspaceStockMode.exactQuantity ? 'exact_quantity' : 'availability_only',
        'quantityPacks': item.stockMode == WorkspaceStockMode.exactQuantity ? item.stock : null, 'available': item.available}});
  }
}

/// Frozen original, including expired requests. Restoration is clock-independent.
class WorkspaceStoreStockIntent {
  WorkspaceStoreStockIntent({required this.scope, required this.expectedRevision, required this.idempotencyKey,
      required WorkspaceStoreStockInput input}) : input = WorkspaceStoreStockInput.fromJson(input.toJson()) {
    _stockScope(scope); _int(expectedRevision, 0, 999999999); _id(idempotencyKey);
    if (this.input.binding['skuId'] != scope.sku) throw const FormatException();
  }
  final WorkspaceStoreStockScope scope;
  final int expectedRevision;
  final String idempotencyKey;
  final WorkspaceStoreStockInput input;
  Map<String, Object?> get body => {'stockSnapshotVersion': 1, 'storeId': scope.store,
    ...input.toJson(), 'expectedRevision': expectedRevision, 'idempotencyKey': idempotencyKey};
  String get serverFingerprint => _catalogueHash({'realm': scope.realm, 'owner': scope.account, 'request': body});
  Map<String, Object?> toJson() => {'version': 1, 'scope': {'account': scope.account, 'store': scope.store,
    'realm': scope.realm, 'sku': scope.sku}, 'expectedRevision': expectedRevision, 'idempotencyKey': idempotencyKey, 'input': input.toJson()};
  static WorkspaceStoreStockIntent fromJson(Object? raw) {
    final v = _map(raw); _keys(v, ['version', 'scope', 'expectedRevision', 'idempotencyKey', 'input']);
    final s = _map(v['scope']); _keys(s, ['account', 'store', 'realm', 'sku']);
    if (v['version'] is! int || v['version'] != 1) throw const FormatException();
    return WorkspaceStoreStockIntent(scope: (account: _id(s['account']), store: _id(s['store']), realm: _string(s['realm']), sku: _id(s['sku'])),
      expectedRevision: _int(v['expectedRevision'], 0, 999999999), idempotencyKey: _id(v['idempotencyKey']),
      input: WorkspaceStoreStockInput.fromJson(v['input']));
  }
}

class WorkspaceStoreStockRecord {
  WorkspaceStoreStockRecord._(this._encoded);
  final String _encoded;
  Map<String, dynamic> toJson() => _map(jsonDecode(_encoded));
  int get revision => toJson()['revision'] as int;
  Map<String, dynamic> get binding => _map(toJson()['binding']);
  Map<String, dynamic> get source => _map(toJson()['source']);
  static WorkspaceStoreStockRecord decode(Object? raw, WorkspaceStoreStockScope scope, DateTime now) {
    _stockScope(scope);
    final r = _map(raw); _keys(r, ['schemaVersion', 'realm', 'storeId', 'binding', 'ownerBinding', 'revision', 'reportedAt', 'source', 'integrity']);
    final binding = _stockBinding(r['binding']), source = _stockCheckpoint(r['source']), body = Map<String, dynamic>.of(r)..remove('integrity');
    final reportedAt = _stockTime(r['reportedAt']);
    if (r['schemaVersion'] is! int || r['schemaVersion'] != 1 || r['realm'] != scope.realm || r['storeId'] != scope.store ||
        binding['skuId'] != scope.sku || r['ownerBinding'] != _catalogueHash([scope.realm, scope.store, scope.account]) ||
        r['integrity'] != _catalogueHash(body) || _stockTime(source['savedAt']).isAfter(reportedAt) || reportedAt.isAfter(now.toUtc())) {
      throw const FormatException('Stock report needs recovery.');
    }
    _int(r['revision'], 1, 1000000000);
    return WorkspaceStoreStockRecord._(jsonEncode(_sorted(r)));
  }
}

class WorkspaceStoreStockHead {
  const WorkspaceStoreStockHead({required this.state, required this.currentRevision, this.record});
  final String state;
  final int currentRevision;
  final WorkspaceStoreStockRecord? record;
  static WorkspaceStoreStockHead decode(Object? raw, WorkspaceStoreStockScope scope, Map<String, dynamic> binding,
      DateTime now, {WorkspaceStoreStockIntent? original, bool reconcile = false}) {
    _stockScope(scope);
    if (_stockBinding(binding)['skuId'] != scope.sku || original != null && original.scope != scope) throw const FormatException();
    final r = _map(raw), state = r['state'];
    _keys(r, ['schemaVersion', 'stockSnapshotVersion', 'realm', 'storeId', 'binding', 'state', 'record', 'idempotencyKey',
      'orderingAvailable', 'reservationConfirmed', if (state == 'source_changed') 'currentRevision',
      if (state == 'expired') ...['expiredAt', 'settledAt', 'originalFingerprint']]);
    if (r['schemaVersion'] is! int || r['schemaVersion'] != 1 || r['stockSnapshotVersion'] is! int || r['stockSnapshotVersion'] != 1 ||
        r['realm'] != scope.realm || r['storeId'] != scope.store || _catalogueHash(_stockBinding(r['binding'])) != _catalogueHash(binding) ||
        r['idempotencyKey'] != original?.idempotencyKey || r['orderingAvailable'] != false || r['reservationConfirmed'] != false ||
        !(original == null ? {'reported', 'none', 'source_changed'} : {'reported', 'expired', if (reconcile) 'not_found'}).contains(state)) {
      throw const FormatException();
    }
    if (state == 'expired') {
      final expiredAt = _stockTime(r['expiredAt']), settledAt = _stockTime(r['settledAt']);
      if (r['record'] != null || r['originalFingerprint'] != original!.serverFingerprint ||
          expiredAt != _stockTime(original.input.source['savedAt']).add(const Duration(minutes: 5)) || settledAt.isBefore(expiredAt)) {
        throw const FormatException();
      }
      return const WorkspaceStoreStockHead(state: 'expired', currentRevision: 0);
    }
    if (state != 'reported') {
      if (r['record'] != null) throw const FormatException();
      return WorkspaceStoreStockHead(state: state as String,
        currentRevision: state == 'source_changed' ? _int(r['currentRevision'], 1, 1000000000) : 0);
    }
    final record = WorkspaceStoreStockRecord.decode(r['record'], scope, now);
    if (_catalogueHash(record.binding) != _catalogueHash(binding) || original != null &&
        (record.revision != original.expectedRevision + 1 || _catalogueHash(record.source) != _catalogueHash(original.input.source))) {
      throw const FormatException();
    }
    return WorkspaceStoreStockHead(state: 'reported', currentRevision: record.revision, record: record);
  }
}

enum WorkspaceStoreStockWriteState { reported, expired, notFound, notSent, unknown }
class WorkspaceStoreStockWriteResult {
  const WorkspaceStoreStockWriteResult(this.state, [this.record]);
  final WorkspaceStoreStockWriteState state;
  final WorkspaceStoreStockRecord? record;
}
abstract interface class WorkspaceStoreStockOwnerGateway {
  String get realm;
  bool get stockSnapshotsSupported;
  Future<WorkspaceStoreStockHead> readStoreStockHead(WorkspaceStoreStockScope scope, Map<String, dynamic> binding, {required bool Function() current});
  Future<WorkspaceStoreStockWriteResult> writeStoreStock(WorkspaceStoreStockIntent original, {required bool Function() current, bool reconcile = false});
}

abstract interface class WorkspaceStoreStockJournal {
  Future<WorkspaceStoreStockIntent?> readPending(WorkspaceStoreStockScope scope);
  Future<void> savePending(WorkspaceStoreStockIntent original);
  Future<void> removePending(WorkspaceStoreStockIntent original);
}

/// One original per saved SKU. A missing receipt is never proof of failure:
/// recovery sends that same original, including after its source has expired.
class WorkspaceStoreStockController {
  WorkspaceStoreStockController({required this.scope, required this.gateway, required this.journal,
    required this.context, DateTime Function()? now}) : _lifetime = context(), now = now ?? DateTime.now {
    _stockScope(scope);
    if (scope.realm != gateway.realm) throw const FormatException();
  }
  final WorkspaceStoreStockScope scope;
  final WorkspaceStoreStockOwnerGateway gateway;
  final WorkspaceStoreStockJournal journal;
  final Object? Function() context;
  final Object? _lifetime;
  final DateTime Function() now;
  bool _closed = false, busy = false;
  int _revision = 0;
  WorkspaceStoreStockIntent? pending;
  bool get active => !_closed && _lifetime != null && context() == _lifetime;
  bool get supported => active && gateway.stockSnapshotsSupported;

  Future<bool> _finish(WorkspaceStoreStockIntent original, WorkspaceStoreStockWriteResult result) async {
    if (!active || pending?.serverFingerprint != original.serverFingerprint) return false;
    final record = result.record;
    if (result.state == WorkspaceStoreStockWriteState.reported) {
      if (record == null || record.revision != original.expectedRevision + 1 ||
          _catalogueHash(record.binding) != _catalogueHash(original.input.binding) ||
          _catalogueHash(record.source) != _catalogueHash(original.input.source)) { return false; }
      // Revalidate even an injected adapter; no response object grants ownership.
      WorkspaceStoreStockRecord.decode(record.toJson(), scope, now());
      if (record.revision > _revision) _revision = record.revision;
    } else if (result.state != WorkspaceStoreStockWriteState.expired) {
      return false;
    }
    // Native completion, not a caller timeout, controls journal serialization.
    await journal.removePending(original).timeout(const Duration(seconds: 10));
    if (!active) return false;
    pending = null;
    return true;
  }

  Future<bool> _recover() async {
    var original = await journal.readPending(scope).timeout(const Duration(seconds: 10));
    if (!active) return false;
    if (original != null && original.scope != scope ||
        original != null && pending != null && original.serverFingerprint != pending!.serverFingerprint) {
      throw const FormatException('Keep the original Stock update.');
    }
    // A failed/late journal write never licenses a replacement original. Re-save
    // the same in-memory original after the physical journal tail has settled.
    if (original == null && pending != null) {
      original = pending;
      await journal.savePending(original!).timeout(const Duration(seconds: 10));
      if (!active) return false;
    }
    pending = original;
    if (original == null) return true;
    var result = await gateway.writeStoreStock(original, current: () => active, reconcile: true).timeout(const Duration(seconds: 25));
    if (!active) return false;
    if (result.state == WorkspaceStoreStockWriteState.notFound) {
      // The server serializes success/expiry on the original receipt. This is
      // not a replacement key, fresh savedAt, or a client-declared expiry.
      result = await gateway.writeStoreStock(original, current: () => active).timeout(const Duration(seconds: 25));
    }
    return _finish(original, result);
  }

  Future<bool> recover() async {
    if (!supported || busy) return false;
    busy = true;
    try { return await _recover(); } catch (_) { return false; } finally { busy = false; }
  }

  Future<bool> synchronize(WorkspaceStoreStockInput input, {required bool Function() inputCurrent}) async {
    if (!supported || busy || input.binding['skuId'] != scope.sku || !inputCurrent()) return false;
    busy = true;
    try {
      if (!await _recover() || !active || !inputCurrent()) return false;
      final head = await gateway.readStoreStockHead(scope, input.binding, current: () => active && inputCurrent()).timeout(const Duration(seconds: 25));
      if (!active || !inputCurrent() || head.currentRevision < _revision) return false;
      if (!{'reported', 'none', 'source_changed'}.contains(head.state)) return false;
      if (head.state == 'reported') {
        final record = head.record;
        if (record == null || record.revision != head.currentRevision) return false;
        WorkspaceStoreStockRecord.decode(record.toJson(), scope, now());
        if (_catalogueHash(record.binding) != _catalogueHash(input.binding)) return false;
        if (_catalogueHash(record.source) == _catalogueHash(input.source)) return true;
      } else if (head.record != null || head.state == 'none' && head.currentRevision != 0) { return false; }
      _revision = head.currentRevision;
      final savedAt = _stockTime(input.source['savedAt']), clock = now().toUtc();
      if (savedAt.isAfter(clock) || !savedAt.add(const Duration(minutes: 5)).isAfter(clock)) return false;
      final original = WorkspaceStoreStockIntent(scope: scope, expectedRevision: _revision, input: input,
        idempotencyKey: 'stock-${List.generate(16, (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0')).join()}');
      pending = original;
      await journal.savePending(original).timeout(const Duration(seconds: 10));
      if (!active || !inputCurrent()) return false;
      final result = await gateway.writeStoreStock(original, current: () => active && inputCurrent()).timeout(const Duration(seconds: 25));
      return await _finish(original, result) && result.state == WorkspaceStoreStockWriteState.reported;
    } catch (_) { return false; } finally { busy = false; }
  }
  void dispose() { _closed = true; }
}

class WorkspacePublicStockQuery {
  WorkspacePublicStockQuery({required this.realm, required this.storeId, required Map<String, dynamic> binding,
      required this.requestedPacks}) : _binding = jsonEncode(_sorted(_stockBinding(binding))) {
    _id(storeId); _int(requestedPacks, 1, 1000000000);
    if (!{'production', 'evaluation'}.contains(realm)) throw const FormatException();
  }
  final String realm, storeId, _binding;
  final int requestedPacks;
  Map<String, dynamic> get binding => _map(jsonDecode(_binding));
  Map<String, Object?> get body => {'stockSnapshotVersion': 1, 'storeId': storeId, 'binding': binding, 'requestedPacks': requestedPacks};
  String get identity => jsonEncode(_sorted({'realm': realm, ...body}));
  factory WorkspacePublicStockQuery.fromEntry(WorkspacePublicCatalogueEntry entry, int requestedPacks) {
    final listing = entry.product.publicListingIdentity;
    if (listing == null || !listing.matches(entry.product)) throw const FormatException();
    return WorkspacePublicStockQuery(realm: listing.realm, storeId: listing.storeId, requestedPacks: requestedPacks,
      binding: {'skuId': listing.skuId, 'skuRevision': _int(entry.readback.skuRevision, 1, 1000000000),
        'canonicalProductId': listing.canonicalProductId, 'verifiedPackId': listing.verifiedPackId});
  }
}
/// Read-only Store report for one exact quantity; never a delivery/order grant.
class WorkspacePublicStockResult {
  WorkspacePublicStockResult._(this.query, this._encoded);
  final WorkspacePublicStockQuery query;
  final String _encoded;
  Map<String, dynamic> toJson() => _map(jsonDecode(_encoded));
  String get state => toJson()['state'] as String;
  bool? get available => toJson()['stock']?['available'] as bool?;
  bool? get quantityAvailable => toJson()['stock']?['quantityAvailable'] as bool?;
  DateTime? get validUntil => toJson()['stock'] == null ? null : _stockTime(toJson()['stock']['validUntil']);
  bool freshAt(DateTime now) => state == 'reported' && validUntil!.isAfter(now.toUtc()) &&
    !_stockTime(toJson()['observedAt']).isAfter(now.toUtc());
  static WorkspacePublicStockResult decode(Object? raw, WorkspacePublicStockQuery query, DateTime now) {
    final r = _map(raw); _keys(r, ['schemaVersion', 'stockSnapshotVersion', 'realm', 'storeId', 'binding', 'state',
      'observedAt', 'requestedPacks', 'stock', 'orderingAvailable', 'reservationConfirmed']);
    final observedAt = _stockTime(r['observedAt']); now = now.toUtc();
    if (r['schemaVersion'] is! int || r['schemaVersion'] != 1 || r['stockSnapshotVersion'] is! int || r['stockSnapshotVersion'] != 1 ||
        r['realm'] != query.realm || r['storeId'] != query.storeId || r['requestedPacks'] is! int || r['requestedPacks'] != query.requestedPacks ||
        _catalogueHash(_stockBinding(r['binding'])) != _catalogueHash(query.binding) || observedAt.isAfter(now) ||
        r['orderingAvailable'] != false || r['reservationConfirmed'] != false || !{'unknown', 'reported'}.contains(r['state'])) {
      throw const FormatException();
    }
    if (r['state'] == 'unknown') {
      if (r['stock'] != null) throw const FormatException();
    } else {
      final s = _map(r['stock']); _keys(s, ['source', 'reportedAt', 'savedAt', 'validUntil', 'reportRevision', 'available', 'quantityAvailable']);
      final reportedAt = _stockTime(s['reportedAt']), savedAt = _stockTime(s['savedAt']), until = _stockTime(s['validUntil']);
      _int(s['reportRevision'], 1, 1000000000);
      if (s['source'] != 'selling_store_checkpoint' || savedAt.isAfter(reportedAt) || reportedAt.isAfter(observedAt) ||
          until != savedAt.add(const Duration(minutes: 5)) || !until.isAfter(now) || s['available'] is! bool ||
          s['quantityAvailable'] != null && s['quantityAvailable'] is! bool || s['available'] == false && s['quantityAvailable'] != false) {
        throw const FormatException();
      }
    }
    return WorkspacePublicStockResult._(query, jsonEncode(_sorted(r)));
  }
}
abstract interface class WorkspaceStoreStockPublicGateway {
  String get realm;
  bool get stockSnapshotsSupported;
  Future<WorkspacePublicStockResult> readPublicStoreStock(WorkspacePublicStockQuery query, {required bool Function() current});
}

/// Session-owned, explicit quantity reads. Synchronous getters never dispatch;
/// source expiry and Stock expiry are independent of delivery/quote authority.
class WorkspacePublicStockReader extends ChangeNotifier {
  WorkspacePublicStockReader({required this.gateway, required this.displayed, required this.current, DateTime Function()? now})
    : now = now ?? DateTime.now;
  final WorkspaceStoreStockPublicGateway gateway;
  final WorkspaceCatalogueContentResult? Function(BuyV2Product product) displayed;
  final bool Function() current;
  final DateTime Function() now;
  final _results = <String, WorkspacePublicStockResult>{};
  final _tokens = <String, Object>{};
  final _loads = <String, ({String key, Object token, bool Function() current, Future<bool> result})>{};
  final _expiry = <String, Timer>{};
  final _highWater = <String, ({int revision, String source})>{};
  final _bindingEpoch = <String, int>{};
  final _waiting = <Completer<void>>[];
  int _runningReads = 0;
  void _drain() {
    while (_runningReads < 3 && _waiting.isNotEmpty) {
      _runningReads++; _waiting.removeAt(0).complete();
    }
  }
  Future<void> _acquire() { final turn = Completer<void>(); _waiting.add(turn); _drain(); return turn.future; }
  Future<WorkspacePublicStockResult> _read(WorkspacePublicStockQuery query, bool Function() valid) async {
    await _acquire();
    try {
      if (!valid()) throw const FormatException();
      return await gateway.readPublicStoreStock(query, current: valid);
    } finally { _runningReads--; _drain(); }
  }
  bool _closed = false;
  bool get active => !_closed && gateway.stockSnapshotsSupported && current();
  WorkspacePublicStockQuery? _query(BuyV2Product product, int packs) {
    try {
      if (!active) return null;
      final content = displayed(product), clock = now().toUtc(), identity = product.publicListingIdentity;
      if (content == null || content.content.state != BuyV2ProductContentState.ready ||
          content.content.productId != product.id || content.content.observedAt == null ||
          content.content.observedAt!.isAfter(clock) || content.validUntil?.isAfter(clock) != true ||
          identity == null || identity.realm != gateway.realm || !identity.matches(product)) { return null; }
      return WorkspacePublicStockQuery.fromEntry(WorkspacePublicCatalogueEntry(product: product, readback: content), packs);
    } catch (_) { return null; }
  }
  String? requestIdentity(BuyV2Product product, int packs) => _query(product, packs)?.identity;
  WorkspacePublicStockResult? snapshotFor(BuyV2Product product, int packs) {
    final query = _query(product, packs), value = _results[product.id];
    return query != null && value?.query.identity == query.identity && value!.freshAt(now()) ? value : null;
  }
  String _bindingKey(WorkspacePublicStockQuery query) => _catalogueHash([query.realm, query.storeId, query.binding]);
  void _dropBinding(WorkspacePublicStockQuery query, {bool retirePending = false}) {
    final binding = _bindingKey(query);
    if (retirePending) { _bindingEpoch[binding] = (_bindingEpoch[binding] ?? 0) + 1; }
    for (final id in _results.keys.where((id) => _bindingKey(_results[id]!.query) == binding).toList()) {
      _results.remove(id); _expiry.remove(id)?.cancel();
    }
  }
  Future<bool> refresh(BuyV2Product product, int packs, {bool force = false, bool Function()? requestCurrent}) {
    final query = _query(product, packs);
    if (query == null || requestCurrent?.call() == false) return Future.value(false);
    final previous = _loads[product.id];
    if (previous?.key == query.identity && previous!.current()) return previous.result;
    if (!force && snapshotFor(product, packs) != null) return Future.value(true);
    final token = Object(); _tokens[product.id] = token; var reading = true;
    final binding = _bindingKey(query), epoch = _bindingEpoch[_bindingKey(query)] ?? 0;
    bool valid() => reading && active && identical(_tokens[product.id], token) && (requestCurrent?.call() ?? true) &&
      (_bindingEpoch[binding] ?? 0) == epoch &&
      _query(product, packs)?.identity == query.identity;
    // Refresh must not temporarily restore eligibility beneath a fresh shortage.
    final retained = snapshotFor(product, packs);
    if (retained?.available != false && retained?.quantityAvailable != false) {
      _results.remove(product.id); _expiry.remove(product.id)?.cancel();
    }
    final operation = () async {
      // Install the original flight before any callback can observe completion.
      await Future<void>.value();
      try {
        if (!valid()) return false;
        // A caller deadline does not release a still-running physical read.
        final value = await _read(query, valid).timeout(const Duration(seconds: 25));
        if (!valid()) return false;
        final verified = WorkspacePublicStockResult.decode(value.toJson(), query, now());
        if (verified.state != 'reported') { _dropBinding(query, retirePending: true); return false; }
        final body = verified.toJson()['stock'] as Map<String, dynamic>;
        final revision = body['reportRevision'] as int, source = _catalogueHash(Map<String, dynamic>.of(body)..remove('quantityAvailable'));
        final key = _bindingKey(query), previousHead = _highWater[key];
        if (previousHead != null && (revision < previousHead.revision || revision == previousHead.revision && source != previousHead.source)) {
          _dropBinding(query, retirePending: true); return false;
        }
        if (previousHead == null || revision > previousHead.revision) _dropBinding(query);
        _highWater[key] = (revision: revision, source: source);
        final contentExpiry = displayed(product)!.validUntil!;
        final until = verified.validUntil!.isBefore(contentExpiry) ? verified.validUntil! : contentExpiry;
        final remaining = until.difference(now().toUtc());
        if (remaining <= Duration.zero) return false;
        _results[product.id] = verified;
        _expiry[product.id] = Timer(remaining, () {
          if (_closed || !identical(_results[product.id], verified)) return;
          _results.remove(product.id); _expiry.remove(product.id);
          if (active) notifyListeners();
        });
        return true;
      } catch (_) {
        if (valid()) _dropBinding(query, retirePending: true);
        return false;
      } finally {
        reading = false;
        if (identical(_loads[product.id]?.token, token)) {
          _loads.remove(product.id);
          if (active) notifyListeners();
        }
      }
    }();
    _loads[product.id] = (key: query.identity, token: token, current: valid, result: operation);
    // Requests are invoked by explicit actions/postframe observers, not build.
    if (active) notifyListeners();
    return operation;
  }
  @override void dispose() {
    _closed = true;
    for (final turn in _waiting) { turn.completeError(const FormatException()); }
    _waiting.clear();
    for (final timer in _expiry.values) { timer.cancel(); }
    _expiry.clear(); _tokens.clear(); _loads.clear(); _results.clear(); _highWater.clear(); _bindingEpoch.clear();
    super.dispose();
  }
}

/// Owner-authored saved facts, not a reviewed mirror, Stock upload or publication.
class WorkspaceProductSubmissionInput {
  WorkspaceProductSubmissionInput._(this._encoded);
  final String _encoded;
  Map<String, dynamic> toJson() => _map(jsonDecode(_encoded));
  String get skuId => toJson()['skuId'] as String;
  String get fingerprint => _encoded;
  String get authoredSha256 => _catalogueHash(Map<String, dynamic>.of(toJson())..remove('catalogueProductHint'));
  bool get mediaPending => toJson()['mediaIntent']['pendingUpload'] == true;
  static WorkspaceProductSubmissionInput fromSaved(WorkspaceCatalogueItem item, {WorkspaceVariantFamily? family}) {
    final origin = item.stockEntry, measure = item.packMeasure, membership = item.variantMembership;
    if (origin?.valid != true || origin!.productId != item.id || measure?.valid != true) {
      throw const FormatException('Save the product with its pack quantity before submitting.');
    }
    if (membership != null) {
      if (family == null || family.id != membership.familyId) { throw const FormatException('Check the saved product options.'); }
      family.attributesFor(membership);
    } else if (family != null) { throw const FormatException(); }
    final facts = WorkspaceCatalogueProductFacts(compliance: item.compliance?.toBuyPublicCompliance(),
      composition: item.composition, regulatoryNote: item.regulatoryNote, requiresPrescription: item.requiresPrescription);
    final channels = <Map<String, Object?>>[];
    if (item.retailEnabled) { channels.add({'kind': 'retail', 'priceMinor': item.sellingPriceMinor,
      'mrpMinor': item.mrpMinor, 'minimumOrder': item.minimumOrder, 'quantityStep': 1, 'tiers': <Object>[]}); }
    final trade = item.wholesaleOffer;
    if (trade?.enabled == true) {
      if (!trade!.valid || trade.saleType == null) throw const FormatException('Check the saved trade prices.');
      final prices = {if (trade.tiers.isNotEmpty) trade.minimumPacks: trade.priceAtMinor(trade.minimumPacks),
        for (final tier in trade.tiers) tier.minimumPacks: tier.packPriceMinor};
      channels.add({'kind': trade.saleType!.name, 'priceMinor': trade.priceAtMinor(trade.minimumPacks),
        'mrpMinor': item.mrpMinor, 'minimumOrder': trade.minimumPacks, 'quantityStep': trade.incrementPacks,
        'tiers': [for (final entry in prices.entries) {'minimumQuantity': entry.key, 'unitPriceMinor': entry.value}]});
    }
    final photo = item.cataloguePhoto, private = item.privatePhoto;
    if (private != null && !private.matches(item) || private == null && photo != null && !photo.matches(item)) {
      throw const FormatException('Check the selected photo against this saved product.');
    }
    final pending = private != null || photo != null && photo.status.name != 'approved';
    // This hashes selected-reference identity only. It is not verified file metadata.
    final selection = private != null ? {'privateSha256': private.sha256, 'skuId': item.id}
      : photo != null ? {'assetId': photo.assetId, 'revision': photo.revision, 'status': photo.status.name} : null;
    return fromJson({'schemaVersion': 1, 'skuId': item.id, 'sku': item.sku, 'barcode': item.barcode,
      'catalogueProductHint': item.canonicalId.isEmpty ? null : item.canonicalId,
      'content': {'title': item.title, 'brand': item.brand, 'variant': item.variant, 'categoryId': item.categoryId,
        'description': item.content.description, 'highlights': item.content.highlights,
        'specifications': [for (final entry in item.content.specifications.entries) {'label': entry.key, 'value': entry.value}],
        if (!facts.isEmpty) 'productFacts': facts.toJson()},
      'pack': {'label': item.pack, 'quantityMilli': measure!.quantityMilli, 'unit': measure.unitLabel == 'unit' ? 'count' : measure.unitLabel,
        'unitsPerCase': measure.unitsPerCase}, 'channels': channels,
      'provenance': {'entryMethod': origin.method.name, 'sourceRecordId': item.id},
      'mediaIntent': {'pendingUpload': pending,
        'pendingSelectionSha256': pending ? crypto.sha256.convert(utf8.encode(jsonEncode(_sorted(selection)))).toString().toUpperCase() : null,
        'publishedReferences': [if (!pending && photo != null) {'assetId': photo.assetId, 'revision': photo.revision}]},
      'variantIntent': membership == null ? null : {'familyId': family!.id, 'localRevision': family.revision, 'selections': membership.selections}});
  }
  static WorkspaceProductSubmissionInput fromJson(Object? raw) {
    final p = _map(jsonDecode(jsonEncode(raw)));
    _keys(p, ['schemaVersion', 'skuId', 'sku', 'barcode', 'catalogueProductHint', 'content', 'pack', 'channels', 'provenance', 'mediaIntent', 'variantIntent']);
    if (p['schemaVersion'] is! int || p['schemaVersion'] != 1) throw const FormatException();
    _id(p['skuId']); _string(p['sku'], 80); _string(p['barcode'], 128, true);
    if (p['catalogueProductHint'] != null) _id(p['catalogueProductHint']);
    final c = _map(p['content']);
    _keys(c, ['title', 'brand', 'variant', 'categoryId', 'description', 'highlights', 'specifications', if (c.containsKey('productFacts')) 'productFacts']);
    _string(c['title']); _id(c['categoryId']); _string(c['brand'], 240, c['categoryId'] == 'fruits-vegetables');
    _string(c['variant'], 240, true); _string(c['description'], 4000, true);
    for (final text in _list(c['highlights'], 20)) { _string(text, 500); }
    for (final raw in _list(c['specifications'], 40)) {
      final row = _map(raw); _keys(row, ['label', 'value']); _string(row['label']); _string(row['value'], 1000);
    }
    if (c.containsKey('productFacts')) { WorkspaceCatalogueProductFacts.fromJson(c['productFacts']); }
    final pack = _map(p['pack']); _keys(pack, ['label', 'quantityMilli', 'unit', 'unitsPerCase']);
    _string(pack['label']); _int(pack['quantityMilli']); _int(pack['unitsPerCase']);
    if (!{'kg', 'L', 'count'}.contains(pack['unit'])) throw const FormatException();
    final kinds = <String>{};
    for (final raw in _list(p['channels'], 2)) {
      final row = _map(raw); _keys(row, ['kind', 'priceMinor', 'mrpMinor', 'minimumOrder', 'quantityStep', 'tiers']);
      final kind = _string(row['kind']);
      if (!{'retail', 'wholesale', 'bulk'}.contains(kind) || !kinds.add(kind)) throw const FormatException();
      final price = _int(row['priceMinor']), minimum = _int(row['minimumOrder']), step = _int(row['quantityStep']);
      if (row['mrpMinor'] != null) _int(row['mrpMinor'], price);
      int? lastQuantity, lastPrice;
      for (final raw in _list(row['tiers'], 20)) {
        final tier = _map(raw); _keys(tier, ['minimumQuantity', 'unitPriceMinor']);
        final q = _int(tier['minimumQuantity']), amount = _int(tier['unitPriceMinor']);
        if ((q - minimum) % step != 0 || (lastQuantity == null ? q != minimum || amount != price : q <= lastQuantity || amount > lastPrice!)) {
          throw const FormatException();
        }
        lastQuantity = q; lastPrice = amount;
      }
    }
    if (kinds.isEmpty || kinds.contains('wholesale') && kinds.contains('bulk')) throw const FormatException();
    final origin = _map(p['provenance']); _keys(origin, ['entryMethod', 'sourceRecordId']);
    if (!{'catalogue', 'manual', 'csv'}.contains(origin['entryMethod']) || origin['sourceRecordId'] != p['skuId']) throw const FormatException();
    final media = _map(p['mediaIntent']); _keys(media, ['pendingUpload', 'pendingSelectionSha256', 'publishedReferences']);
    if (media['pendingUpload'] is! bool || (media['pendingUpload'] == true
      ? media['pendingSelectionSha256'] is! String || !RegExp(r'^[A-F0-9]{64}$').hasMatch(media['pendingSelectionSha256'] as String)
      : media['pendingSelectionSha256'] != null)) { throw const FormatException(); }
    final assets = <String>{};
    for (final raw in _list(media['publishedReferences'], 10)) {
      final asset = _map(raw); _keys(asset, ['assetId', 'revision']); _id(asset['revision']);
      if (!assets.add(_id(asset['assetId']))) throw const FormatException();
    }
    if (p['variantIntent'] != null) {
      final v = _map(p['variantIntent']); _keys(v, ['familyId', 'localRevision', 'selections']);
      _id(v['familyId']); _int(v['localRevision'], 1, 1000000000);
      final selected = _map(v['selections']);
      if (selected.isEmpty || selected.length > 6) throw const FormatException();
      for (final entry in selected.entries) { _id(entry.key); _id(entry.value); }
    }
    final encoded = jsonEncode(_sorted(p));
    if (utf8.encode(encoded).length > 384 * 1024) throw const FormatException();
    return WorkspaceProductSubmissionInput._(encoded);
  }
}

class WorkspaceProductSubmissionIntent {
  WorkspaceProductSubmissionIntent({required this.scope, required this.expectedRevision, required this.idempotencyKey,
    required WorkspaceProductSubmissionInput input}) : input = WorkspaceProductSubmissionInput.fromJson(input.toJson()) {
    for (final value in [scope.account, scope.store, scope.sku, idempotencyKey]) { _id(value); }
    _int(expectedRevision, 0, 999999999);
    if (!{'evaluation', 'production'}.contains(scope.realm) || scope.sku != input.skuId) throw const FormatException();
  }
  final WorkspaceProductSubmissionScope scope;
  final int expectedRevision;
  final String idempotencyKey;
  final WorkspaceProductSubmissionInput input;
  Map<String, Object?> get body => {'storeId': scope.store, 'expectedRevision': expectedRevision, 'idempotencyKey': idempotencyKey, 'product': input.toJson()};
  Map<String, Object?> toJson() => {'schemaVersion': 1, 'accountId': scope.account, 'realm': scope.realm, ...body};
  String get fingerprint => jsonEncode(_sorted(toJson()));
  String get candidateFingerprint => crypto.sha256.convert(utf8.encode(jsonEncode(_sorted({'ownerUserId': scope.account,
    'realm': scope.realm, 'storeId': scope.store, 'expectedRevision': expectedRevision, 'product': input.toJson()})))).toString().toUpperCase();
  static WorkspaceProductSubmissionIntent fromJson(Object? raw) {
    final value = _map(raw); _keys(value, ['schemaVersion', 'accountId', 'realm', 'storeId', 'expectedRevision', 'idempotencyKey', 'product']);
    if (value['schemaVersion'] is! int || value['schemaVersion'] != 1) throw const FormatException();
    final input = WorkspaceProductSubmissionInput.fromJson(value['product']);
    return WorkspaceProductSubmissionIntent(scope: (account: _id(value['accountId']), store: _id(value['storeId']), realm: _string(value['realm']), sku: input.skuId),
      expectedRevision: _int(value['expectedRevision'], 0, 999999999), idempotencyKey: _id(value['idempotencyKey']), input: input);
  }
}

class WorkspaceProductSubmissionRecord {
  WorkspaceProductSubmissionRecord._(this.input, this.revision, this.fingerprint, this._encoded);
  final WorkspaceProductSubmissionInput input;
  final int revision;
  final String fingerprint, _encoded;
  Map<String, dynamic> toJson() => _map(jsonDecode(_encoded));
  static WorkspaceProductSubmissionRecord decode(Object? raw, WorkspaceProductSubmissionScope scope, DateTime now) {
    final value = _map(raw);
    _keys(value, ['schemaVersion', 'realm', 'storeId', 'skuId', 'revision', 'submittedAt', 'submittedBy', 'fingerprint', 'product']);
    final input = WorkspaceProductSubmissionInput.fromJson(value['product']), revision = _int(value['revision'], 1, 1000000000);
    final at = _time(value['submittedAt']), original = WorkspaceProductSubmissionIntent(scope: (account: _id(value['submittedBy']),
      store: scope.store, realm: scope.realm, sku: scope.sku), expectedRevision: revision - 1, idempotencyKey: 'validation-only', input: input);
    if (value['schemaVersion'] is! int || value['schemaVersion'] != 1 || value['realm'] != scope.realm || value['storeId'] != scope.store ||
        value['skuId'] != scope.sku || at.isAfter(now.toUtc()) || at.toIso8601String() != value['submittedAt'] || value['fingerprint'] != original.candidateFingerprint) {
      throw const FormatException();
    }
    return WorkspaceProductSubmissionRecord._(input, revision, original.candidateFingerprint, jsonEncode(_sorted(value)));
  }
  bool matches(WorkspaceProductSubmissionIntent original) => revision == original.expectedRevision + 1 && fingerprint == original.candidateFingerprint &&
    toJson()['submittedBy'] == original.scope.account && input.fingerprint == original.input.fingerprint;
}
enum WorkspaceProductSubmissionWriteState {notSent, rejected, unknown, submitted, notFound}
class WorkspaceProductSubmissionWriteResult {
  const WorkspaceProductSubmissionWriteResult(this.state, [this.record]);
  final WorkspaceProductSubmissionWriteState state;
  final WorkspaceProductSubmissionRecord? record;
}
abstract interface class WorkspaceProductSubmissionOwnerGateway {
  String get realm;
  bool get productSubmissionSupported;
  Future<WorkspaceProductSubmissionRecord?> readProductSubmission(WorkspaceProductSubmissionScope scope, {required bool Function() current});
  Future<WorkspaceProductSubmissionWriteResult> writeProductSubmission(WorkspaceProductSubmissionIntent original,
    {required bool Function() current, bool reconcile = false});
}

/// Negotiated private review results, never public visibility or ordering proof.
abstract interface class WorkspaceReviewedProductSubmissionGateway {
  bool get reviewedProductSubmissionSupported;
  DateTime get productReviewNow;
  Future<WorkspaceProductReviewReadback> readReviewedProductSubmission(WorkspaceProductSubmissionScope scope,
    {required bool Function() current});
}
class WorkspaceReviewedProductCandidate {
  WorkspaceReviewedProductCandidate._(this._encoded, this.source);
  final String _encoded;
  final WorkspaceProductSubmissionRecord source;
  Map<String, dynamic> toJson() => _map(jsonDecode(_encoded));
  Map<String, dynamic> get sku => _map(toJson()['sku']);
  int get revision => toJson()['revision'] as int;
  String get fingerprint => toJson()['fingerprint'] as String;
  WorkspaceReviewedProductMediaProof? get mediaProof => (toJson()['source'] as Map).containsKey('media')
    ? WorkspaceReviewedProductMediaProof.fromJson(toJson()['source']['media']) : null;
  DateTime get expiresAt => _time(toJson()['expiresAt']);
  static WorkspaceReviewedProductCandidate decode(Object? raw, WorkspaceProductSubmissionRecord source,
      WorkspaceProductSubmissionScope scope, DateTime observed, {bool requireCurrent = true, bool allowMedia = false}) {
    final value = _map(raw);
    _keys(value, ['schemaVersion', 'realm', 'storeId', 'skuId', 'revision', 'fingerprint', 'source', 'identity',
      'sku', 'expectedMirrorRevision', 'reviewedBy', 'reviewedAt', 'expiresAt', 'terms']);
    final reference = _map(value['source']);
    final hasMedia = reference.containsKey('media');
    _keys(reference, ['realm', 'storeId', 'skuId', 'revision', 'fingerprint', if (hasMedia) 'media']);
    final media = hasMedia ? WorkspaceReviewedProductMediaProof.fromJson(reference['media']) : null;
    if (hasMedia && !allowMedia) throw const FormatException('Update MoolSocial before adopting these reviewed photos.');
    _int(reference['revision'], 1, 1000000000);
    final identity = _map(value['identity']); _keys(identity, ['catalogueId', 'tenantId']);
    _id(identity['catalogueId']); _id(identity['tenantId']);
    _int(value['revision'], 1, 1000000000); _int(value['expectedMirrorRevision'], 0, 1000000000);
    final reviewedAt = _time(value['reviewedAt']), expires = _time(value['expiresAt']);
    final body = source.input.toJson(), sku = _map(value['sku']); _ownerSkuInput(sku, scope.store);
    final content = Map<String, dynamic>.of(_map(body['content']))..['media'] = [if (media != null)
      media.descriptor(realm: scope.realm, storeId: scope.store, skuId: scope.sku, canonicalId: _id(sku['canonicalProductId']))];
    final channels = (sku['channels'] as List).map((raw) => Map<String, dynamic>.of(_map(raw))..remove('offerId')).toList();
    final validMedia = (body['mediaIntent']['publishedReferences'] as List).isEmpty && (media == null
      ? body['mediaIntent']['pendingUpload'] == false
      : body['mediaIntent']['pendingUpload'] == true && media.matchesSelection(scope.sku, body['mediaIntent']['pendingSelectionSha256'] as String?));
    final hashed = Map<String, dynamic>.of(value)..remove('fingerprint');
    if (_int(value['schemaVersion'], 1, 2) != (hasMedia ? 2 : 1) || value['realm'] != scope.realm || value['storeId'] != scope.store || value['skuId'] != scope.sku ||
        reference['realm'] != scope.realm || reference['storeId'] != scope.store || reference['skuId'] != scope.sku ||
        reference['revision'] != source.revision || reference['fingerprint'] != source.fingerprint ||
        value['fingerprint'] != _catalogueHash(hashed) || _id(value['reviewedBy']) == source.toJson()['submittedBy'] ||
        reviewedAt.toIso8601String() != value['reviewedAt'] || expires.toIso8601String() != value['expiresAt'] ||
        reviewedAt.isAfter(observed) || reviewedAt.isBefore(_time(source.toJson()['submittedAt'])) || !expires.isAfter(reviewedAt) ||
        requireCurrent && !expires.isAfter(observed) || !validMedia || sku['publicListing'] != true ||
        sku['skuId'] != scope.sku || sku['sku'] != body['sku'] ||
        jsonEncode(_sorted(sku['content'])) != jsonEncode(_sorted(content)) ||
        jsonEncode(_sorted(sku['pack'])) != jsonEncode(_sorted(body['pack'])) ||
        jsonEncode(_sorted(sku['provenance'])) != jsonEncode(_sorted(body['provenance'])) ||
        jsonEncode(_sorted(channels)) != jsonEncode(_sorted(body['channels']))) { throw const FormatException(); }
    final terms = value['terms'];
    if (terms is! List || terms.length != channels.length) throw const FormatException();
    final kinds = <String>{};
    for (final raw in terms) {
      final term = _map(raw); _keys(term, ['kind', 'offerId', 'termSnapshotId', 'termSnapshotSha256', 'effectiveFrom', 'expiresAt']);
      final kind = _string(term['kind']);
      final channel = (sku['channels'] as List).map(_map).where((c) => c['kind'] == kind && c['offerId'] == term['offerId']).firstOrNull;
      if (channel == null || !kinds.add(kind)) throw const FormatException();
      final termsBody = <String, dynamic>{'currency': 'INR', ...channel}..remove('offerId');
      _id(term['termSnapshotId']);
      if (term['termSnapshotSha256'] != _catalogueHash(termsBody) || _time(term['effectiveFrom']).isAfter(reviewedAt) ||
          _time(term['expiresAt']).isBefore(expires) || _time(term['effectiveFrom']).toIso8601String() != term['effectiveFrom'] ||
          _time(term['expiresAt']).toIso8601String() != term['expiresAt']) { throw const FormatException(); }
    }
    return WorkspaceReviewedProductCandidate._(jsonEncode(_sorted(value)), source);
  }
  WorkspaceCatalogueBindingIntent publicationIntent({required String accountId, required String idempotencyKey}) =>
    WorkspaceCatalogueBindingIntent(accountId: accountId, realm: toJson()['realm'] as String,
      storeId: toJson()['storeId'] as String, expectedRevision: toJson()['expectedMirrorRevision'] as int,
      idempotencyKey: idempotencyKey, sku: sku, reviewCandidate: {'revision': revision, 'fingerprint': fingerprint}, reviewedSource: source, reviewedMedia: mediaProof);
}
String _catalogueHash(Object value) => crypto.sha256.convert(utf8.encode(jsonEncode(_sorted(value)))).toString().toUpperCase();
class WorkspaceProductReviewReadback {
  const WorkspaceProductReviewReadback({required this.record, required this.state, this.candidate});
  final WorkspaceProductSubmissionRecord? record;
  final String state;
  final WorkspaceReviewedProductCandidate? candidate;
  static WorkspaceProductReviewReadback decodeReview(Object? raw, WorkspaceProductSubmissionRecord? record,
      WorkspaceProductSubmissionScope scope, DateTime observed, {bool allowMedia = false}) {
    final review = _map(raw); _keys(review, ['version', 'state', 'candidate']);
    final state = _string(review['state']);
    if (_int(review['version'], 1, 1) != 1 || !{'pending', 'awaiting_media', 'ready', 'bound', 'outdated', 'unavailable'}.contains(state) ||
        ({'ready', 'bound'}.contains(state) ? record == null || review['candidate'] == null : review['candidate'] != null) ||
        state == 'awaiting_media' && record == null) { throw const FormatException(); }
    final candidate = review['candidate'] == null ? null : WorkspaceReviewedProductCandidate.decode(review['candidate'], record!, scope,
      observed, requireCurrent: state != 'bound', allowMedia: allowMedia);
    return WorkspaceProductReviewReadback(record: record, state: state, candidate: candidate);
  }
}

abstract interface class WorkspaceProductSubmissionJournal {
  Future<WorkspaceProductSubmissionIntent?> readPending(WorkspaceProductSubmissionScope scope);
  Future<void> savePending(WorkspaceProductSubmissionIntent original);
  Future<void> removePending(WorkspaceProductSubmissionIntent original);
}

/// Frozen private upload original; contains no bytes, picker path, signed URL or publication claim.
class WorkspaceProductMediaIntent {
  WorkspaceProductMediaIntent({required this.scope, required this.submissionRevision, required this.submissionFingerprint,
    required this.sourceSha256, required this.sourceByteLength, required this.idempotencyKey}) {
    for (final value in [scope.account, scope.store, scope.sku, idempotencyKey]) { _id(value); }
    _int(submissionRevision, 1, 100000000);
    _int(sourceByteLength, 1, 8 * 1024 * 1024);
    if (!{'evaluation', 'production'}.contains(scope.realm) || !RegExp(r'^[a-f0-9]{64}$').hasMatch(sourceSha256) ||
      !RegExp(r'^[A-F0-9]{64}$').hasMatch(submissionFingerprint)) {throw const FormatException('Check the saved photo and original submission.');}
  }
  final WorkspaceProductSubmissionScope scope;
  final int submissionRevision, sourceByteLength;
  final String submissionFingerprint, sourceSha256, idempotencyKey;
  String get uploadId => _catalogueHash([scope.realm, scope.store, scope.sku, scope.account, idempotencyKey]);
  Map<String, Object?> get body => {'storeId': scope.store, 'skuId': scope.sku, 'submissionRevision': submissionRevision,
    'submissionFingerprint': submissionFingerprint, 'sourceSha256': sourceSha256, 'sourceByteLength': sourceByteLength,
    'sourceMimeType': 'image/png', 'idempotencyKey': idempotencyKey};
  String get serverFingerprint => _catalogueHash({'realm': scope.realm, 'ownerUserId': scope.account, ...body});
  Map<String, Object?> toJson() => {'schemaVersion': 1, 'accountId': scope.account, 'realm': scope.realm, ...body};
  String get fingerprint => jsonEncode(_sorted(toJson()));
  bool sameSource(WorkspaceProductMediaIntent other) => scope == other.scope && submissionRevision == other.submissionRevision &&
    submissionFingerprint == other.submissionFingerprint && sourceSha256 == other.sourceSha256 && sourceByteLength == other.sourceByteLength;
  bool matchesSubmission(WorkspaceProductSubmissionRecord head) => head.revision == submissionRevision && head.fingerprint == submissionFingerprint &&
    head.toJson()['submittedBy'] == scope.account && head.input.skuId == scope.sku && head.input.mediaPending &&
    head.input.toJson()['mediaIntent']['pendingSelectionSha256'] == _catalogueHash({'privateSha256': sourceSha256, 'skuId': scope.sku});
  static WorkspaceProductMediaIntent fromJson(Object? raw) {
    final value = _map(raw);
    _keys(value, ['schemaVersion', 'accountId', 'realm', 'storeId', 'skuId', 'submissionRevision', 'submissionFingerprint',
      'sourceSha256', 'sourceByteLength', 'sourceMimeType', 'idempotencyKey']);
    if (_int(value['schemaVersion'], 1, 1) != 1 || value['sourceMimeType'] != 'image/png') throw const FormatException();
    return WorkspaceProductMediaIntent(scope: (account: _id(value['accountId']), store: _id(value['storeId']),
      realm: _string(value['realm']), sku: _id(value['skuId'])), submissionRevision: _int(value['submissionRevision']),
      submissionFingerprint: _string(value['submissionFingerprint']), sourceSha256: _string(value['sourceSha256']),
      sourceByteLength: _int(value['sourceByteLength']), idempotencyKey: _id(value['idempotencyKey']));
  }
}
class WorkspaceProductMediaResult {
  WorkspaceProductMediaResult._(this._encoded, this.uploadUrl, this.requiredHeaders);
  final String _encoded;
  final Uri? uploadUrl;
  final Map<String, String> requiredHeaders;
  Map<String, dynamic> toJson() => _map(jsonDecode(_encoded));
  String get state => toJson()['state'] as String;
  bool get current => toJson()['current'] as bool;
  bool get processed => state == 'processed';
  bool get meetsPublicSourceFloor => processed && toJson()['processed']['meetsPublicSourceFloor'] == true;
  static WorkspaceProductMediaResult decode(Object? raw, WorkspaceProductMediaIntent original, DateTime now, {bool grantAllowed = false, bool historical = false}) {
    if (historical && grantAllowed) throw const FormatException();
    DateTime time(Object? raw) {
      final parsed = _time(raw);
      if (parsed.toIso8601String() != raw) throw const FormatException();
      return parsed;
    }
    final value = _map(raw);
    final hasGrant = value.containsKey('uploadUrl') || value.containsKey('requiredHeaders');
    _keys(value, ['schemaVersion', 'productMediaVersion', 'realm', 'storeId', 'skuId', 'idempotencyKey', 'uploadId', 'current', 'state',
      'preparedAt', 'expiresAt', 'source', 'processed', 'approved', 'publicationConfirmed', if (hasGrant) ...['uploadUrl', 'requiredHeaders']]);
    final source = _map(value['source']); _keys(source, ['revision', 'fingerprint']);
    if (_int(value['schemaVersion'], 1, 1) != 1 || _int(value['productMediaVersion'], 1, 1) != 1 || value['realm'] != original.scope.realm ||
      value['storeId'] != original.scope.store || value['skuId'] != original.scope.sku || value['idempotencyKey'] != original.idempotencyKey ||
      value['uploadId'] != original.uploadId || value['current'] is! bool || value['approved'] != false || value['publicationConfirmed'] != false ||
      _int(source['revision']) != original.submissionRevision || source['fingerprint'] != original.submissionFingerprint ||
      !{'not_found', 'awaiting_upload', 'processed'}.contains(value['state'])) {throw const FormatException();}
    if (value['state'] == 'not_found') {
      if (value['preparedAt'] != null || value['expiresAt'] != null || value['processed'] != null || hasGrant) throw const FormatException();
    } else {
      final prepared = time(value['preparedAt']), expiry = time(value['expiresAt']);
      if (!historical && prepared.isAfter(now.toUtc()) || expiry.difference(prepared) < const Duration(minutes: 5)) throw const FormatException();
      if (value['state'] == 'processed') {
        final p = _map(value['processed']); _keys(p, ['assetId', 'originalGeneration', 'derivativeGeneration', 'processedAt', 'source', 'file', 'meetsPublicSourceFloor']);
        for (final key in ['originalGeneration', 'derivativeGeneration']) {
          if (p[key] is! String || !RegExp(r'^[1-9][0-9]*$').hasMatch(p[key] as String)) throw const FormatException();
        }
        final input = _map(p['source']), output = _map(p['file']);
        _keys(input, ['sha256', 'byteLength', 'width', 'height', 'mimeType']);
        _keys(output, ['sha256', 'byteLength', 'width', 'height', 'mimeType', 'normalized', 'frameCount']);
        final width = _int(input['width'], 1, 16384), height = _int(input['height'], 1, 16384), processedAt = time(p['processedAt']);
        if (input['sha256'] != original.sourceSha256.toUpperCase() || _int(input['byteLength']) != original.sourceByteLength || input['mimeType'] != 'image/png' ||
          width * height > 16 * 1024 * 1024 || output['sha256'] is! String || !RegExp(r'^[A-F0-9]{64}$').hasMatch(output['sha256'] as String) ||
          _int(output['byteLength'], 1, 8 * 1024 * 1024) < 1 || _int(output['width'], 1, 1024) * _int(output['height'], 1, 1024) > width * height ||
          output['mimeType'] != 'image/png' || output['normalized'] != true || _int(output['frameCount'], 1, 1) != 1 ||
          p['meetsPublicSourceFloor'] != (width >= 512 && height >= 512) || processedAt.isBefore(prepared) || !historical && processedAt.isAfter(now.toUtc()) ||
          p['assetId'] != _catalogueHash({'uploadId': original.uploadId, 'generation': p['originalGeneration'], 'sha256': output['sha256']}) || hasGrant) {throw const FormatException();}
      } else if (value['processed'] != null) { throw const FormatException(); }
    }
    Uri? url; final headers = <String, String>{};
    if (hasGrant) {
      if (!grantAllowed || value['state'] != 'awaiting_upload' || value['current'] != true || !_time(value['expiresAt']).isAfter(now.toUtc())) throw const FormatException();
      url = Uri.parse(_string(value['uploadUrl'], 8192));
      final suffix = '/private/product-media/v1/${original.scope.realm}/${original.uploadId}/original';
      if (url.scheme != 'https' || url.host != 'storage.googleapis.com' || url.hasPort || url.userInfo.isNotEmpty || url.hasFragment ||
        !url.path.endsWith(suffix) || url.path.substring(0, url.path.length - suffix.length).split('/').where((p) => p.isNotEmpty).length != 1 ||
        url.pathSegments.any((p) => p == '.' || p == '..' || p.contains('/'))) {throw const FormatException();}
      const queryKeys = {'X-Goog-Algorithm', 'X-Goog-Credential', 'X-Goog-Date', 'X-Goog-Expires', 'X-Goog-SignedHeaders', 'X-Goog-Signature'};
      if (url.queryParametersAll.length != queryKeys.length || url.queryParametersAll.entries.any((e) => !queryKeys.contains(e.key) || e.value.length != 1) ||
        url.queryParameters['X-Goog-Algorithm'] != 'GOOG4-RSA-SHA256' ||
        !RegExp(r'^\d{8}T\d{6}Z$').hasMatch(url.queryParameters['X-Goog-Date'] ?? '') ||
        !RegExp(r'^[a-fA-F0-9]+$').hasMatch(url.queryParameters['X-Goog-Signature'] ?? '') ||
        (int.tryParse(url.queryParameters['X-Goog-Expires'] ?? '') ?? 0) < 1 ||
        (int.tryParse(url.queryParameters['X-Goog-Expires'] ?? '') ?? 301) > 300 ||
        !(url.queryParameters['X-Goog-Credential'] ?? '').endsWith('/auto/storage/goog4_request')) {throw const FormatException();}
      final issued = DateTime.parse(url.queryParameters['X-Goog-Date']!);
      final signedExpiry = issued.add(Duration(seconds: int.parse(url.queryParameters['X-Goog-Expires']!)));
      if (issued.isAfter(now.toUtc()) || !signedExpiry.isAfter(now.toUtc()) ||
        _time(value['expiresAt']).difference(signedExpiry).isNegative ||
        _time(value['expiresAt']).difference(signedExpiry) > const Duration(seconds: 1)) {throw const FormatException();}
      final rawHeaders = _map(value['requiredHeaders']);
      final expected = <String, String>{'content-type': 'image/png', 'content-length': '${original.sourceByteLength}', 'x-goog-if-generation-match': '0',
        'x-goog-meta-moolsocial-schema': 'private-product-media-v1', 'x-goog-meta-moolsocial-binding': original.serverFingerprint,
        'x-goog-meta-moolsocial-owner': _catalogueHash(original.scope.account), 'x-goog-meta-moolsocial-source': original.sourceSha256};
      _keys(rawHeaders, expected.keys.toList());
      if (expected.entries.any((e) => rawHeaders[e.key] != e.value)) throw const FormatException();
      headers.addAll(expected);
      final signed = [...expected.keys, 'host']..sort();
      if (url.queryParameters['X-Goog-SignedHeaders'] != signed.join(';')) throw const FormatException();
    }
    final sanitized = Map<String, dynamic>.of(value)..remove('uploadUrl')..remove('requiredHeaders');
    return WorkspaceProductMediaResult._(jsonEncode(_sorted(sanitized)), url, Map.unmodifiable(headers));
  }
}
abstract interface class WorkspaceProductMediaGateway {
  bool get productMediaSupported;
  Future<WorkspaceProductMediaResult> readProductMedia(WorkspaceProductMediaIntent original, {required bool Function() current, bool confirm = false});
  Future<WorkspaceProductMediaResult> uploadProductMedia(WorkspaceProductMediaIntent original,
    {required Future<Uint8List> Function() readBytes, required bool Function() current});
}
class WorkspaceProductMediaRecovery {
  const WorkspaceProductMediaRecovery(this.original, [this.result, this.history = const []]);
  final WorkspaceProductMediaIntent original;
  final WorkspaceProductMediaResult? result;
  final List<WorkspaceProductMediaRecovery> history;
}
abstract interface class WorkspaceProductMediaJournal {
  Future<WorkspaceProductMediaRecovery?> read(WorkspaceProductSubmissionScope scope);
  Future<void> saveOriginal(WorkspaceProductMediaIntent original);
  Future<void> saveResult(WorkspaceProductMediaIntent original, WorkspaceProductMediaResult result);
}
/// Explicit editor actions only. A saved original survives uncertain prepare/PUT/confirm and restart.
class WorkspaceProductMediaController extends ChangeNotifier {
  WorkspaceProductMediaController({required this.scope, required this.gateway, required this.journal, required this.context}) : _lifetime = context();
  final WorkspaceProductSubmissionScope scope;
  final WorkspaceProductMediaGateway gateway;
  final WorkspaceProductMediaJournal journal;
  final Object? Function() context;
  final Object? _lifetime;
  bool _closed = false, ready = false, busy = false, fresh = false;
  WorkspaceProductMediaIntent? original;
  WorkspaceProductMediaResult? result;
  List<WorkspaceProductMediaRecovery> history = const [];
  String? message;
  Future<bool>? _restoring;
  bool get active => !_closed && _lifetime != null && context() == _lifetime;
  void _notify() {if (active) notifyListeners();}
  Future<bool> restore() => ready ? Future.value(active) : _restoring ??= _restore().whenComplete(() => _restoring = null);
  Future<bool> _restore() async {
    if (!active) return false;
    try {
      final saved = await journal.read(scope).timeout(const Duration(seconds: 10));
      if (!active) return false;
      if (saved != null && saved.original.scope != scope) throw const FormatException();
      original = saved?.original; result = saved?.result; history = saved?.history ?? const []; ready = true; fresh = false;
      message = original == null ? null : 'A saved photo request is kept. Check its original status before another upload.';
      return true;
    } catch (_) {
      if (active) {ready = false; message = 'Photo recovery could not be opened. Your saved photo is kept.';}
      return false;
    } finally {_notify();}
  }
  Future<bool> _record(WorkspaceProductMediaIntent intent, WorkspaceProductMediaResult next, bool Function() current) async {
    if (!active || !current() || original?.fingerprint != intent.fingerprint) return false;
    await journal.saveResult(intent, next).timeout(const Duration(seconds: 10));
    if (!active || !current() || original?.fingerprint != intent.fingerprint) return false;
    result = next; fresh = true;
    message = next.processed ? !next.current ? 'The earlier photo was processed privately. It does not replace the newer saved photo.'
      : next.meetsPublicSourceFloor ? 'Photo processed privately. Independent review and publication are still required.'
        : 'Photo processed privately. This saved copy is too small for public review; choose a larger image when available.'
      : !next.current ? 'This photo request belongs to earlier saved details. It cannot replace the current photo.'
        : 'Photo processing is not confirmed. The original request is kept.';
    return next.processed;
  }
  Future<bool> check({required bool Function() current}) async {
    if (!active || busy || !gateway.productMediaSupported || !current()) return false;
    busy = true; _notify();
    try {
      if (!await restore() || !current() || original == null) return false;
      final intent = original!;
      var next = await gateway.readProductMedia(intent, current: () => active && current());
      if (!active || !current()) return false;
      if (!next.processed && next.state != 'not_found') {
        try {next = await gateway.readProductMedia(intent, current: () => active && current(), confirm: true);}
        catch (_) {if (!active || !current()) return false;}
      }
      return await _record(intent, next, current);
    } catch (_) {
      if (active && current()) message = 'Original photo processing is unconfirmed. Keep the saved photo and check again.';
      return false;
    } finally {busy = false; _notify();}
  }
  Future<bool> upload(WorkspaceProductMediaIntent candidate, {required bool Function() current,
      required Future<Uint8List> Function(WorkspaceProductMediaIntent) readBytes}) async {
    if (!active || busy || !gateway.productMediaSupported || candidate.scope != scope || !current()) return false;
    busy = true; _notify();
    try {
      if (!await restore() || !active || !current()) return false;
      final prior = original;
      if (prior != null && !prior.sameSource(candidate)) {
        final old = await gateway.readProductMedia(prior, current: () => active && current());
        if (!active || !current()) return false;
        await _record(prior, old, current);
        if (!active || !current()) return false;
        if (!old.processed && old.current) {message = 'Check the original photo request before uploading changed details.'; return false;}
      }
      final intent = prior != null && prior.sameSource(candidate) ? prior : candidate;
      // Keep the original in memory on failed storage too; never dispatch until durable save succeeds.
      if (original?.fingerprint != intent.fingerprint) result = null;
      ready = false; original = intent; fresh = false;
      await journal.saveOriginal(intent).timeout(const Duration(seconds: 10));
      if (!active || !current()) return false;
      final retained = await journal.read(scope).timeout(const Duration(seconds: 10));
      if (!active || !current() || retained?.original.fingerprint != intent.fingerprint) return false;
      history = retained!.history; ready = true;
      final next = await gateway.uploadProductMedia(intent, readBytes: () => readBytes(intent), current: () => active && current());
      return await _record(intent, next, current);
    } catch (_) {
      ready = false; fresh = false;
      if (active && current()) {message = 'Photo upload or processing is unconfirmed. The original request and saved photo are kept.';}
      return false;
    } finally {busy = false; _notify();}
  }
  Future<bool> checkEarlier({required bool Function() current, String? requestKey}) async {
    if (!active || busy || !current()) return false;
    busy = true; _notify();
    try {
      if (!await restore() || !active || !current()) return false;
      final retained = history.where((entry) => entry.result?.processed != true && (requestKey == null || entry.original.idempotencyKey == requestKey)).firstOrNull;
      if (retained == null) return true;
      var next = await gateway.readProductMedia(retained.original, current: () => active && current());
      if (!active || !current()) return false;
      if (!next.processed && next.state != 'not_found') {
        try {next = await gateway.readProductMedia(retained.original, current: () => active && current(), confirm: true);}
        catch (_) {if (!active || !current()) return false;}
      }
      await journal.saveResult(retained.original, next).timeout(const Duration(seconds: 10));
      if (!active || !current()) return false;
      final saved = await journal.read(scope).timeout(const Duration(seconds: 10));
      if (!active || !current()) return false;
      history = saved?.history ?? history;
      message = next.processed ? 'Earlier photo processing is recovered privately. The current photo is unchanged.'
        : 'Earlier photo processing is still unconfirmed. Its original request remains saved.';
      return next.processed;
    } catch (_) {
      if (active && current()) message = 'The earlier photo request is kept for checking. No current photo was replaced.';
      return false;
    } finally {busy = false; _notify();}
  }
  @override
  void dispose() {_closed = true; super.dispose();}
}
abstract interface class WorkspaceProductMediaUploadTransport {
  Future<int> put(Uri url, Map<String, String> headers, Uint8List bytes, {required bool Function() current});
}
class IoWorkspaceProductMediaUploadTransport implements WorkspaceProductMediaUploadTransport {
  IoWorkspaceProductMediaUploadTransport({HttpClient? client}) : _client = client ?? HttpClient();
  final HttpClient _client;
  @override
  Future<int> put(Uri url, Map<String, String> headers, Uint8List bytes, {required bool Function() current}) async {
    if (!current() || url.scheme != 'https' || url.host != 'storage.googleapis.com' || url.hasPort || url.userInfo.isNotEmpty || url.hasFragment) throw const FormatException();
    final request = await _client.putUrl(url).timeout(const Duration(seconds: 15));
    request.followRedirects = false;
    if (!current()) {request.abort(); throw const FormatException();}
    request.contentLength = bytes.length;
    headers.forEach((key, value) {if (key != 'content-length') request.headers.set(key, value);});
    request.add(bytes);
    final response = await request.close().timeout(const Duration(seconds: 45));
    var read = 0;
    await for (final chunk in response.timeout(const Duration(seconds: 10))) {
      read += chunk.length; if (read > 64 * 1024) throw const FormatException();
    }
    if (!current()) throw const FormatException();
    return response.statusCode;
  }
}

/// One journalled original per saved SKU. Recovery never rebuilds current edits.
class WorkspaceProductSubmissionController extends ChangeNotifier {
  WorkspaceProductSubmissionController({required this.scope, required this.gateway, required this.journal, required this.context})
    : _lifetime = context() {
    for (final value in [scope.account, scope.store, scope.sku]) { _id(value); }
    if (scope.realm != gateway.realm || !{'evaluation', 'production'}.contains(scope.realm)) throw const FormatException();
  }
  final WorkspaceProductSubmissionScope scope;
  final WorkspaceProductSubmissionOwnerGateway gateway;
  final WorkspaceProductSubmissionJournal journal;
  final Object? Function() context;
  final Object? _lifetime;
  bool _closed = false, ready = false, busy = false, headLoaded = false, originalNotFound = false;
  int _revision = 0;
  String? _headBytes, message;
  WorkspaceProductSubmissionRecord? head;
  WorkspaceProductReviewReadback? review;
  int _reviewRevision = 0;
  String? _reviewFingerprint;
  WorkspaceProductSubmissionIntent? pending;
  Future<bool>? _restoring;
  bool get active => !_closed && _lifetime != null && context() == _lifetime;
  bool get canSubmit => active && gateway.productSubmissionSupported && ready && headLoaded && !busy && pending == null;
  bool get canRetryOriginal => active && gateway.productSubmissionSupported && ready && !busy && pending != null && originalNotFound;
  void _notify() { if (active) notifyListeners(); }
  Future<bool> restore() {
    if (!active) return Future.value(false);
    if (ready) return Future.value(true);
    return _restoring ??= _restore().whenComplete(() => _restoring = null);
  }
  Future<bool> _restore() async {
    try {
      final original = await journal.readPending(scope).timeout(const Duration(seconds: 10));
      if (!active) return false;
      if (original != null && (original.scope != scope || pending != null && original.fingerprint != pending!.fingerprint)) throw const FormatException();
      pending ??= original; ready = true;
      message = pending == null ? null : 'An earlier product submission needs checking. Your saved details are kept.';
      return true;
    } catch (_) {
      if (active) { ready = false; message = 'The saved submission could not be opened. Your product is kept.'; }
      return false;
    } finally { _notify(); }
  }
  Future<bool> refresh() async {
    if (!active || busy || !gateway.productSubmissionSupported) return false;
    busy = true; headLoaded = false; review = null; _notify();
    try {
      if (!await restore() || !active) return false;
      if (pending != null) { message = 'Check the original request before another submission.'; return false; }
      final source = gateway;
      final nextReview = source is WorkspaceReviewedProductSubmissionGateway && (source as WorkspaceReviewedProductSubmissionGateway).reviewedProductSubmissionSupported
        ? await (source as WorkspaceReviewedProductSubmissionGateway).readReviewedProductSubmission(scope, current: () => active).timeout(const Duration(seconds: 25)) : null;
      final next = nextReview == null ? await gateway.readProductSubmission(scope, current: () => active).timeout(const Duration(seconds: 25)) : nextReview.record;
      if (!active) return false;
      final revision = next?.revision ?? 0, bytes = next == null ? null : jsonEncode(_sorted(next.toJson()));
      if (revision < _revision || revision == _revision && _headBytes != bytes) throw const FormatException();
      final candidate = nextReview?.candidate;
      if (candidate != null && (candidate.revision < _reviewRevision || candidate.revision == _reviewRevision &&
          _reviewFingerprint != candidate.fingerprint)) { throw const FormatException(); }
      if (candidate != null) { _reviewRevision = candidate.revision; _reviewFingerprint = candidate.fingerprint; }
      review = nextReview;
      head = next; _revision = revision; _headBytes = bytes; headLoaded = true;
      message = next == null ? 'This saved product has not been submitted.' : next.input.mediaPending
        ? 'Product details received privately. Photo upload and review are still needed.'
        : 'Product details received privately. Approval and public listing are not confirmed.';
      if (nextReview != null) {
        message = switch (nextReview.state) {
          'ready' => 'Reviewed details are ready. Publish them only after checking this saved product.',
          'bound' => 'Reviewed listing preference saved. Public visibility still needs confirmation.',
          'outdated' => 'Saved details changed after review. Submit the saved changes before publishing.',
          'unavailable' => 'Reviewed selling terms are not available now. Your saved product is kept.',
          'awaiting_media' => 'Product details received privately. Photo upload and review are still needed.',
          _ => next == null ? 'This saved product has not been submitted.' : 'Saved details are received privately. Review is not finished.',
        };
      }
      return true;
    } catch (_) {
      if (active) message = 'Product review status could not be confirmed. Your saved details are kept.';
      return false;
    } finally { busy = false; _notify(); }
  }
  Future<WorkspaceProductSubmissionWriteResult> submit(WorkspaceProductSubmissionInput input, {required bool Function() inputCurrent}) async {
    if (!canSubmit || input.skuId != scope.sku || !inputCurrent()) return const WorkspaceProductSubmissionWriteResult(WorkspaceProductSubmissionWriteState.notSent);
    if (head?.input.fingerprint == input.fingerprint) {
      message = 'These saved details are already submitted. Check review status.'; _notify();
      return const WorkspaceProductSubmissionWriteResult(WorkspaceProductSubmissionWriteState.notSent);
    }
    busy = true; review = null; _notify();
    try {
      final original = WorkspaceProductSubmissionIntent(scope: scope, expectedRevision: _revision, input: input,
        idempotencyKey: 'product-${List.generate(16, (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0')).join()}');
      pending = original; originalNotFound = false;
      await journal.savePending(original).timeout(const Duration(seconds: 10));
      if (!active || !inputCurrent()) {
        if (active) message = 'Saved product details changed. Check the original request before submitting again.';
        return const WorkspaceProductSubmissionWriteResult(WorkspaceProductSubmissionWriteState.unknown);
      }
      final result = await gateway.writeProductSubmission(original, current: () => active && inputCurrent()).timeout(const Duration(seconds: 25));
      if (!active) return const WorkspaceProductSubmissionWriteResult(WorkspaceProductSubmissionWriteState.unknown);
      return await _finish(original, result, recovery: false);
    } catch (_) {
      if (active) { ready = false; message = 'Submission is not confirmed. The original request and product are kept.'; }
      return const WorkspaceProductSubmissionWriteResult(WorkspaceProductSubmissionWriteState.unknown);
    } finally { busy = false; _notify(); }
  }
  Future<WorkspaceProductSubmissionWriteResult> reconcile() => _recover(retry: false);
  Future<WorkspaceProductSubmissionWriteResult> retryOriginal() => _recover(retry: true);
  Future<WorkspaceProductSubmissionWriteResult> _recover({required bool retry}) async {
    if (!active || busy || !gateway.productSubmissionSupported || retry && !canRetryOriginal) {
      return const WorkspaceProductSubmissionWriteResult(WorkspaceProductSubmissionWriteState.unknown);
    }
    busy = true; _notify();
    try {
      if (!await restore() || !active || pending == null) return const WorkspaceProductSubmissionWriteResult(WorkspaceProductSubmissionWriteState.unknown);
      final original = pending!; originalNotFound = false;
      if (retry) await journal.savePending(original).timeout(const Duration(seconds: 10));
      if (!active) return const WorkspaceProductSubmissionWriteResult(WorkspaceProductSubmissionWriteState.unknown);
      final result = await gateway.writeProductSubmission(original, current: () => active, reconcile: !retry).timeout(const Duration(seconds: 25));
      if (!active) return const WorkspaceProductSubmissionWriteResult(WorkspaceProductSubmissionWriteState.unknown);
      if (!retry && result.state == WorkspaceProductSubmissionWriteState.notFound) originalNotFound = true;
      return await _finish(original, result, recovery: true);
    } catch (_) {
      if (active) message = 'The original product submission is still unconfirmed. It is kept for checking.';
      return const WorkspaceProductSubmissionWriteResult(WorkspaceProductSubmissionWriteState.unknown);
    } finally { busy = false; _notify(); }
  }
  Future<WorkspaceProductSubmissionWriteResult> _finish(WorkspaceProductSubmissionIntent original,
      WorkspaceProductSubmissionWriteResult result, {required bool recovery}) async {
    final record = result.record;
    final submitted = result.state == WorkspaceProductSubmissionWriteState.submitted && record != null && record.matches(original);
    final definitive = submitted || !recovery && {WorkspaceProductSubmissionWriteState.notSent, WorkspaceProductSubmissionWriteState.rejected}.contains(result.state);
    if (!definitive) {
      message = originalNotFound ? 'No result found yet. Retry sends the same saved request, not current edits.'
        : 'Product submission is not confirmed. Check the original request.';
      return const WorkspaceProductSubmissionWriteResult(WorkspaceProductSubmissionWriteState.unknown);
    }
    await journal.removePending(original).timeout(const Duration(seconds: 10));
    if (!active) return const WorkspaceProductSubmissionWriteResult(WorkspaceProductSubmissionWriteState.unknown);
    pending = null; originalNotFound = false; headLoaded = false;
    if (submitted && record.revision >= _revision) { _revision = record.revision; _headBytes = jsonEncode(_sorted(record.toJson())); }
    message = submitted ? 'Product details received privately—not approval or public publication.' : 'The product was not submitted. Saved details are unchanged.';
    return result;
  }
  @override
  void dispose() { _closed = true; super.dispose(); }
}

/// Frozen descriptive input, never Stock, publication approval or live availability.
class WorkspaceVariantFamilySubmissionInput {
  WorkspaceVariantFamilySubmissionInput._(this._encoded);
  final String _encoded;
  Map<String, dynamic> toJson() => _map(jsonDecode(_encoded));
  String get familyId => toJson()['familyId'] as String;
  String get fingerprint => _encoded;
  static WorkspaceVariantFamilySubmissionInput fromSaved(WorkspaceVariantFamily family,
      Iterable<WorkspaceCatalogueItem> products, Map<String, int> serverRevisions) {
    final members = products.where((p) => p.variantMembership?.familyId == family.id).toList();
    WorkspaceVariantFamily.validateInventory([family], members);
    if (members.isEmpty || serverRevisions.length != members.length ||
        members.any((p) => !serverRevisions.containsKey(p.id))) {
      throw const FormatException('Check every saved SKU before submitting its group.');
    }
    return fromJson({'familyId': family.id, 'localRevision': family.revision, 'title': family.title,
      'brand': family.brand, 'categoryId': family.categoryId,
      'options': family.toJson()['options'], 'members': [for (final p in members) {
        'skuId': p.id, 'skuRevision': serverRevisions[p.id], 'selections': p.variantMembership!.selections}]});
  }
  static WorkspaceVariantFamilySubmissionInput fromJson(Object? raw) {
    final value = _map(raw);
    _keys(value, ['familyId', 'localRevision', 'title', 'brand', 'categoryId', 'options', 'members']);
    final family = WorkspaceVariantFamily.fromJson({'version': 1, 'id': _id(value['familyId']),
      'revision': _int(value['localRevision'], 1, 2147483647), 'title': value['title'], 'brand': value['brand'],
      'categoryId': _id(value['categoryId']), 'options': value['options'],
      'content': {'description': '', 'highlights': <String>[], 'specifications': <String, String>{}}});
    final tuples = <String>{}, skus = <String>{};
    final members = <Map<String, dynamic>>[];
    for (final raw in _list(value['members'], 80)) {
      final member = _map(raw); _keys(member, ['skuId', 'skuRevision', 'selections']);
      final selected = _map(member['selections']);
      _keys(selected, family.dimensionIds);
      final membership = WorkspaceVariantMembership(familyId: family.id,
        selections: {for (final key in selected.keys) _id(key): _id(selected[key])});
      family.attributesFor(membership);
      final sku = _id(member['skuId']), tuple = jsonEncode(_sorted(membership.selections));
      if (!skus.add(sku) || !tuples.add(tuple)) throw const FormatException('Keep one SKU per option combination.');
      members.add({'skuId': sku, 'skuRevision': _int(member['skuRevision'], 1, 1000000000),
        'selections': membership.selections});
    }
    if (members.isEmpty) throw const FormatException('Save a SKU before submitting its group.');
    final options = _list(family.toJson()['options'], 128).cast<Map<String, Object?>>().toList()
      ..sort((a, b) => (a['dimensionId'] as String).compareTo(b['dimensionId'] as String) != 0
        ? (a['dimensionId'] as String).compareTo(b['dimensionId'] as String)
        : (a['optionId'] as String).compareTo(b['optionId'] as String));
    members.sort((a, b) => (a['skuId'] as String).compareTo(b['skuId'] as String));
    return WorkspaceVariantFamilySubmissionInput._(jsonEncode(_sorted({'familyId': family.id,
      'localRevision': family.revision, 'title': family.title, 'brand': family.brand, 'categoryId': family.categoryId,
      'options': options, 'members': members})));
  }
}

class WorkspaceVariantFamilyIntent {
  WorkspaceVariantFamilyIntent({required this.scope, required this.expectedRevision,
    required this.idempotencyKey, required WorkspaceVariantFamilySubmissionInput input})
    : input = WorkspaceVariantFamilySubmissionInput.fromJson(input.toJson()) {
    for (final id in [scope.account, scope.store, scope.family, idempotencyKey]) { _id(id); }
    _int(expectedRevision, 0, 999999999);
    if (!{'evaluation', 'production'}.contains(scope.realm) || scope.family != input.familyId) throw const FormatException();
  }
  final WorkspaceVariantFamilyScope scope;
  final int expectedRevision;
  final String idempotencyKey;
  final WorkspaceVariantFamilySubmissionInput input;
  Map<String, Object?> get body => {'storeId': scope.store, 'expectedRevision': expectedRevision,
    'idempotencyKey': idempotencyKey, 'family': input.toJson()};
  Map<String, Object?> toJson() => {'schemaVersion': 1, 'accountId': scope.account, 'realm': scope.realm, ...body};
  String get fingerprint => jsonEncode(_sorted(toJson()));
  String get candidateFingerprint => crypto.sha256.convert(utf8.encode(jsonEncode(_sorted({
    'ownerUserId': scope.account, 'realm': scope.realm, 'storeId': scope.store,
    'expectedRevision': expectedRevision, 'family': input.toJson()})))).toString().toUpperCase();
  static WorkspaceVariantFamilyIntent fromJson(Object? raw) {
    final value = _map(raw);
    _keys(value, ['schemaVersion', 'accountId', 'realm', 'storeId', 'expectedRevision', 'idempotencyKey', 'family']);
    if (value['schemaVersion'] is! int || value['schemaVersion'] != 1) throw const FormatException();
    final input = WorkspaceVariantFamilySubmissionInput.fromJson(value['family']);
    return WorkspaceVariantFamilyIntent(scope: (account: _id(value['accountId']), store: _id(value['storeId']),
      realm: _string(value['realm']), family: input.familyId), expectedRevision: _int(value['expectedRevision'], 0, 999999999),
      idempotencyKey: _id(value['idempotencyKey']), input: input);
  }
}

class WorkspaceVariantFamilyCandidate {
  WorkspaceVariantFamilyCandidate._(this._encoded, this.input, this.revision, this.fingerprint);
  final String _encoded;
  final WorkspaceVariantFamilySubmissionInput input;
  final int revision;
  final String fingerprint;
  Map<String, dynamic> toJson() => _map(jsonDecode(_encoded));
  static WorkspaceVariantFamilyCandidate decode(Object? raw, WorkspaceVariantFamilyScope scope, DateTime now) {
    final value = _map(raw);
    _keys(value, ['schemaVersion', 'realm', 'storeId', 'revision', 'submittedAt', 'submittedBy', 'fingerprint', 'family']);
    final input = WorkspaceVariantFamilySubmissionInput.fromJson(value['family']), revision = _int(value['revision'], 1, 1000000000);
    final time = _time(value['submittedAt']);
    final original = WorkspaceVariantFamilyIntent(scope: (account: _id(value['submittedBy']),
      store: scope.store, realm: scope.realm, family: scope.family), expectedRevision: revision - 1,
      idempotencyKey: 'validation-only', input: input);
    if (value['schemaVersion'] is! int || value['schemaVersion'] != 1 || value['realm'] != scope.realm ||
        value['storeId'] != scope.store || input.familyId != scope.family || time.isAfter(now.toUtc()) ||
        time.toIso8601String() != value['submittedAt'] || original.candidateFingerprint != value['fingerprint']) { throw const FormatException(); }
    return WorkspaceVariantFamilyCandidate._(jsonEncode(_sorted(value)), input, revision, original.candidateFingerprint);
  }
  bool matches(WorkspaceVariantFamilyIntent original) => revision == original.expectedRevision + 1 &&
    fingerprint == original.candidateFingerprint && toJson()['submittedBy'] == original.scope.account &&
    input.fingerprint == original.input.fingerprint;
}

class WorkspaceVariantFamilyHead {
  const WorkspaceVariantFamilyHead({required this.candidate, required this.reviewedCandidate,
    required this.reviewRevision, required this.reviewFingerprint, required this.decision});
  final WorkspaceVariantFamilyCandidate? candidate, reviewedCandidate;
  final int reviewRevision;
  final String? reviewFingerprint, decision;
  static WorkspaceVariantFamilyHead decode(Object? raw, WorkspaceVariantFamilyScope scope, DateTime now) {
    final value = _map(raw);
    _keys(value, ['schemaVersion', 'realm', 'storeId', 'familyId', 'orderingAvailable', 'candidate', 'review']);
    if (value['schemaVersion'] is! int || value['schemaVersion'] != 1 || value['realm'] != scope.realm ||
        value['storeId'] != scope.store || value['familyId'] != scope.family || value['orderingAvailable'] != false) { throw const FormatException(); }
    final candidate = value['candidate'] == null ? null : WorkspaceVariantFamilyCandidate.decode(value['candidate'], scope, now);
    if (value['review'] == null) {
      return WorkspaceVariantFamilyHead(candidate: candidate, reviewedCandidate: null,
        reviewRevision: 0, reviewFingerprint: null, decision: null);
    }
    final review = _map(value['review']);
    _keys(review, ['schemaVersion', 'revision', 'decision', 'reviewerUserId', 'reviewedAt',
      'reasonCode', 'catalogueId', 'tenantId', 'candidate']);
    final reviewed = WorkspaceVariantFamilyCandidate.decode(review['candidate'], scope, now), at = _time(review['reviewedAt']);
    if (review['schemaVersion'] is! int || review['schemaVersion'] != 1 ||
        !{'verify', 'reject'}.contains(review['decision']) || at.isAfter(now.toUtc()) || at.toIso8601String() != review['reviewedAt'] ||
        at.isBefore(_time(reviewed.toJson()['submittedAt'])) || review['reviewerUserId'] == reviewed.toJson()['submittedBy'] ||
        candidate == null || reviewed.revision > candidate.revision ||
        reviewed.revision == candidate.revision && reviewed.fingerprint != candidate.fingerprint) { throw const FormatException(); }
    for (final key in ['reviewerUserId', 'reasonCode', 'catalogueId', 'tenantId']) { _id(review[key]); }
    return WorkspaceVariantFamilyHead(candidate: candidate, reviewedCandidate: reviewed,
      reviewRevision: _int(review['revision'], 1, 1000000000), reviewFingerprint: jsonEncode(_sorted(review)),
      decision: review['decision'] as String);
  }
}

enum WorkspaceVariantFamilyWriteState {notSent, rejected, unknown, submitted, notFound}
class WorkspaceVariantFamilyWriteResult {
  const WorkspaceVariantFamilyWriteResult(this.state, [this.candidate]);
  final WorkspaceVariantFamilyWriteState state;
  final WorkspaceVariantFamilyCandidate? candidate;
}
abstract interface class WorkspaceVariantFamilyOwnerGateway {
  String get realm;
  bool get variantFamilySubmissionSupported;
  Future<WorkspaceVariantFamilyHead> readVariantFamily(WorkspaceVariantFamilyScope scope, {required bool Function() current});
  Future<WorkspaceVariantFamilyWriteResult> writeVariantFamily(WorkspaceVariantFamilyIntent original,
    {required bool Function() current, bool reconcile = false});
}
abstract interface class WorkspaceVariantFamilyJournal {
  Future<WorkspaceVariantFamilyIntent?> readPending(WorkspaceVariantFamilyScope scope);
  Future<void> savePending(WorkspaceVariantFamilyIntent original);
  Future<void> removePending(WorkspaceVariantFamilyIntent original);
}

/// Device recovery and remote submission/review are separate states. No restore,
/// refresh or reconcile creates a new mutation or reads current edits as a retry.
class WorkspaceVariantFamilyController extends ChangeNotifier {
  WorkspaceVariantFamilyController({required this.scope, required this.gateway, required this.journal,
    required this.context, DateTime Function()? now}) : _lifetime = context(), now = now ?? DateTime.now {
    for (final id in [scope.account, scope.store, scope.family]) { _id(id); }
    if (scope.realm != gateway.realm || !{'evaluation', 'production'}.contains(scope.realm)) throw const FormatException();
  }
  final WorkspaceVariantFamilyScope scope;
  final WorkspaceVariantFamilyOwnerGateway gateway;
  final WorkspaceVariantFamilyJournal journal;
  final Object? Function() context;
  final DateTime Function() now;
  final Object? _lifetime;
  bool _closed = false, ready = false, busy = false, headLoaded = false, originalNotFound = false;
  int _candidateRevision = 0, _reviewRevision = 0;
  String? _candidateBytes, _reviewBytes;
  WorkspaceVariantFamilyHead? head;
  WorkspaceVariantFamilyIntent? pending;
  String? message;
  Future<bool>? _restoring;
  bool get active => !_closed && _lifetime != null && context() == _lifetime;
  bool get canSubmit => active && gateway.variantFamilySubmissionSupported && ready && headLoaded && !busy && pending == null;
  bool get canRetryOriginal => active && ready && !busy && pending != null && originalNotFound;
  void _notify() { if (active) notifyListeners(); }
  Future<bool> restore() {
    if (!active) return Future.value(false);
    if (ready) return Future.value(true);
    return _restoring ??= _restore().whenComplete(() => _restoring = null);
  }
  Future<bool> _restore() async {
    try {
      final original = await journal.readPending(scope).timeout(const Duration(seconds: 10));
      if (!active) return false;
      if (original != null && (original.scope != scope ||
          pending != null && original.fingerprint != pending!.fingerprint)) { throw const FormatException(); }
      pending ??= original;
      ready = true;
      message = pending == null ? null : 'An earlier group submission needs checking. Your saved options are kept.';
      return true;
    } catch (_) {
      if (active) { ready = false; message = 'The saved submission could not be opened. Your group is kept.'; }
      return false;
    } finally { _notify(); }
  }
  Future<bool> refresh() async {
    if (!active || busy || !gateway.variantFamilySubmissionSupported) return false;
    busy = true; headLoaded = false; _notify();
    try {
      if (!await restore() || !active) return false;
      if (pending != null) { message = 'Check the original request before another submission.'; return false; }
      final next = await gateway.readVariantFamily(scope, current: () => active).timeout(const Duration(seconds: 25));
      if (!active) return false;
      final candidate = next.candidate, bytes = candidate == null ? null : jsonEncode(_sorted(candidate.toJson()));
      if ((candidate?.revision ?? 0) < _candidateRevision || next.reviewRevision < _reviewRevision ||
          candidate != null && candidate.revision == _candidateRevision && _candidateBytes != bytes ||
          next.reviewRevision == _reviewRevision && _reviewBytes != next.reviewFingerprint) { throw const FormatException(); }
      head = next; headLoaded = true;
      _candidateRevision = candidate?.revision ?? 0; _candidateBytes = bytes;
      _reviewRevision = next.reviewRevision; _reviewBytes = next.reviewFingerprint;
      message = candidate == null ? 'This saved group has not been submitted.'
        : next.reviewedCandidate?.fingerprint != candidate.fingerprint ? 'Submitted changes are waiting for review.'
        : next.decision == 'verify' ? 'Last submitted options approved. Current listings and availability need separate checks.'
        : 'Review requested changes. Update and save the group before submitting again.';
      return true;
    } catch (_) {
      if (active) message = 'Group review status could not be confirmed. Your saved options are kept.';
      return false;
    } finally { busy = false; _notify(); }
  }
  Future<WorkspaceVariantFamilyWriteResult> submit(WorkspaceVariantFamilySubmissionInput input,
      {required bool Function() inputCurrent}) async {
    if (!canSubmit || input.familyId != scope.family || !inputCurrent()) {
      return const WorkspaceVariantFamilyWriteResult(WorkspaceVariantFamilyWriteState.notSent);
    }
    if (head?.candidate?.input.fingerprint == input.fingerprint) {
      message = 'These saved combinations are already submitted. Check review status.'; _notify();
      return const WorkspaceVariantFamilyWriteResult(WorkspaceVariantFamilyWriteState.notSent);
    }
    busy = true; _notify();
    try {
      final original = WorkspaceVariantFamilyIntent(scope: scope, expectedRevision: head?.candidate?.revision ?? 0,
        idempotencyKey: 'family-${List.generate(16, (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0')).join()}', input: input);
      pending = original; originalNotFound = false;
      await journal.savePending(original).timeout(const Duration(seconds: 10));
      if (!active || !inputCurrent()) {
        if (active) message = 'Saved group details changed. Check the original request before submitting again.';
        return const WorkspaceVariantFamilyWriteResult(WorkspaceVariantFamilyWriteState.unknown);
      }
      final result = await gateway.writeVariantFamily(original, current: () => active && inputCurrent())
        .timeout(const Duration(seconds: 25));
      if (!active) return const WorkspaceVariantFamilyWriteResult(WorkspaceVariantFamilyWriteState.unknown);
      return await _finish(original, result, recovery: false);
    } catch (_) {
      if (active) { ready = false; message = 'Submission is not confirmed. The original request and saved group are kept.'; }
      return const WorkspaceVariantFamilyWriteResult(WorkspaceVariantFamilyWriteState.unknown);
    } finally { busy = false; _notify(); }
  }
  Future<WorkspaceVariantFamilyWriteResult> reconcile() => _recover(retry: false);
  Future<WorkspaceVariantFamilyWriteResult> retryOriginal() => _recover(retry: true);
  Future<WorkspaceVariantFamilyWriteResult> _recover({required bool retry}) async {
    if (!active || busy || !gateway.variantFamilySubmissionSupported || retry && !canRetryOriginal) {
      return const WorkspaceVariantFamilyWriteResult(WorkspaceVariantFamilyWriteState.unknown);
    }
    busy = true; _notify();
    try {
      if (!await restore() || !active || pending == null) return const WorkspaceVariantFamilyWriteResult(WorkspaceVariantFamilyWriteState.unknown);
      final original = pending!;
      originalNotFound = false;
      if (retry) await journal.savePending(original).timeout(const Duration(seconds: 10));
      if (!active) return const WorkspaceVariantFamilyWriteResult(WorkspaceVariantFamilyWriteState.unknown);
      final result = await gateway.writeVariantFamily(original, current: () => active, reconcile: !retry)
        .timeout(const Duration(seconds: 25));
      if (!active) return const WorkspaceVariantFamilyWriteResult(WorkspaceVariantFamilyWriteState.unknown);
      if (!retry && result.state == WorkspaceVariantFamilyWriteState.notFound) originalNotFound = true;
      return await _finish(original, result, recovery: true);
    } catch (_) {
      if (active) message = 'The original submission is still unconfirmed. It is kept for checking.';
      return const WorkspaceVariantFamilyWriteResult(WorkspaceVariantFamilyWriteState.unknown);
    } finally { busy = false; _notify(); }
  }
  Future<WorkspaceVariantFamilyWriteResult> _finish(WorkspaceVariantFamilyIntent original,
      WorkspaceVariantFamilyWriteResult result, {required bool recovery}) async {
    final candidate = result.candidate;
    final submitted = result.state == WorkspaceVariantFamilyWriteState.submitted && candidate != null && candidate.matches(original);
    final definitive = submitted || !recovery &&
      {WorkspaceVariantFamilyWriteState.notSent, WorkspaceVariantFamilyWriteState.rejected}.contains(result.state);
    if (!definitive) {
      message = originalNotFound ? 'No result found yet. Retry sends the same saved request, not current edits.'
        : 'Group submission is not confirmed. Check the original request.';
      return const WorkspaceVariantFamilyWriteResult(WorkspaceVariantFamilyWriteState.unknown);
    }
    await journal.removePending(original).timeout(const Duration(seconds: 10));
    if (!active) return const WorkspaceVariantFamilyWriteResult(WorkspaceVariantFamilyWriteState.unknown);
    pending = null; originalNotFound = false; headLoaded = false;
    if (submitted && candidate.revision >= _candidateRevision) {
      _candidateRevision = candidate.revision; _candidateBytes = jsonEncode(_sorted(candidate.toJson()));
    }
    message = submitted ? 'Group submitted for review—not approval or public publication.'
      : 'The group was not submitted. Your saved options are unchanged.';
    return result;
  }
  @override
  void dispose() { _closed = true; super.dispose(); }
}

class WorkspacePublicDetailsRecord {
  const WorkspacePublicDetailsRecord({required this.realm, required this.storeId, required this.revision,
    required this.publishedAt, required this.details});
  final String realm, storeId;
  final int revision;
  final DateTime publishedAt;
  final WorkspacePublicDetailsFields details;
  static WorkspacePublicDetailsRecord decode(Object? raw, String realm, String storeId) {
    final record = _map(raw);
    _keys(record, ['schemaVersion', 'realm', 'storeId', 'revision', 'publishedAt', 'details']);
    if (record['schemaVersion'] != 1 || record['realm'] != realm || record['storeId'] != storeId) throw const FormatException();
    return WorkspacePublicDetailsRecord(realm: realm, storeId: storeId, revision: _int(record['revision'], 1, 1000000000),
      publishedAt: _time(record['publishedAt']), details: WorkspacePublicDetailsFields.fromJson(_map(record['details'])));
  }
}

/// Immutable original request; a caller must journal it before enabling a write.
class WorkspacePublicDetailsIntent {
  const WorkspacePublicDetailsIntent({required this.ownerAccountId, required this.realm, required this.storeId,
    required this.expectedRevision, required this.idempotencyKey, required this.details});
  final String ownerAccountId, realm, storeId, idempotencyKey;
  final int expectedRevision;
  final WorkspacePublicDetailsFields details;
  Map<String, Object?> get body => {'storeId': storeId, 'expectedRevision': expectedRevision,
    'idempotencyKey': idempotencyKey, 'details': details.toJson()};
  WorkspacePublicDetailsScope get scope => (account: ownerAccountId, store: storeId, realm: realm);
  Map<String, Object?> toJson() => {'schemaVersion': 1, 'ownerAccountId': ownerAccountId, 'realm': realm, ...body};
  String get fingerprint => jsonEncode(_sorted(toJson()));
  static WorkspacePublicDetailsIntent fromJson(Object? raw) {
    final value = _map(raw);
    _keys(value, ['schemaVersion', 'ownerAccountId', 'realm', 'storeId', 'expectedRevision', 'idempotencyKey', 'details']);
    if (value['schemaVersion'] != 1 || !{'evaluation', 'production'}.contains(value['realm'])) throw const FormatException();
    return WorkspacePublicDetailsIntent(ownerAccountId: _id(value['ownerAccountId']), realm: value['realm'] as String,
      storeId: _id(value['storeId']), expectedRevision: _int(value['expectedRevision'], 0, 999999999),
      idempotencyKey: _id(value['idempotencyKey']), details: WorkspacePublicDetailsFields.fromJson(_map(value['details'])));
  }
}
typedef WorkspacePublicDetailsScope = ({String account, String store, String realm});
abstract interface class WorkspacePublicDetailsOwnerGateway {
  Future<WorkspacePublicDetailsRecord?> readPublicDetailsOwned({required String storeId, required bool Function() current});
  Future<WorkspacePublicDetailsWriteResult> writePublicDetails(WorkspacePublicDetailsIntent original,
    {required bool Function() current, bool reconcile = false});
}
abstract interface class WorkspacePublicDetailsJournal {
  Future<WorkspacePublicDetailsIntent?> readPending(WorkspacePublicDetailsScope scope);
  Future<void> savePending(WorkspacePublicDetailsIntent original);
  Future<void> removePending(WorkspacePublicDetailsIntent original);
}
enum WorkspacePublicDetailsWriteState {notSent, rejected, unknown, saved, notFound}
class WorkspacePublicDetailsWriteResult {
  const WorkspacePublicDetailsWriteResult(this.state, [this.record]);
  final WorkspacePublicDetailsWriteState state;
  final WorkspacePublicDetailsRecord? record;
}

/// Current head, immutable original acknowledgement and private inputs are
/// separate. No restore/refresh sends a mutation or overwrites owner settings.
class WorkspacePublicDetailsController extends ChangeNotifier {
  WorkspacePublicDetailsController({required this.scope, required this.gateway, required this.journal,
    required this.context, DateTime Function()? now}) : _lifetime = context(), now = now ?? DateTime.now {
    _id(scope.account); _id(scope.store);
    if (!{'evaluation', 'production'}.contains(scope.realm)) throw const FormatException();
  }
  final WorkspacePublicDetailsScope scope;
  final WorkspacePublicDetailsOwnerGateway gateway;
  final WorkspacePublicDetailsJournal journal;
  final Object? Function() context;
  final DateTime Function() now;
  final Object? _lifetime;
  bool _closed = false, ready = false, busy = false, headLoaded = false, originalNotFound = false;
  int _minimumRevision = 0;
  WorkspacePublicDetailsIntent? pending;
  WorkspacePublicDetailsRecord? published, lastAcknowledged;
  String? message;
  Future<bool>? _restoring;
  bool get active => !_closed && _lifetime != null && context() == _lifetime;
  bool get canPublish => active && ready && headLoaded && !busy && pending == null;
  bool get canRetryOriginal => active && ready && !busy && pending != null && originalNotFound;
  void _notify() { if (active) notifyListeners(); }
  bool _validRecord(WorkspacePublicDetailsRecord record) {
    try {
      WorkspacePublicDetailsFields.fromJson(record.details.toJson());
      return record.realm == scope.realm && record.storeId == scope.store && record.revision > 0 &&
        record.revision <= 1000000000 && !record.publishedAt.isAfter(now().toUtc());
    } catch (_) { return false; }
  }
  Future<bool> restore() {
    if (!active) return Future.value(false);
    if (ready) return Future.value(true);
    return _restoring ??= _restore().whenComplete(() => _restoring = null);
  }
  Future<bool> _restore() async {
    try {
      final original = await journal.readPending(scope).timeout(const Duration(seconds: 10));
      if (!active) return false;
      if (original != null && (original.scope != scope ||
          pending != null && pending!.fingerprint != original.fingerprint)) {
        throw const FormatException();
      }
      // A failed/timed-out journal save may settle later. Never forget the
      // in-memory original merely because a read returned no record.
      pending ??= original;
      ready = true;
      message = pending == null ? null : 'An earlier public-details update needs checking. Your device entries are kept.';
      return true;
    } catch (_) {
      if (active) { ready = false; message = 'The saved public update could not be opened. Try again; your entries are kept.'; }
      return false;
    } finally { _notify(); }
  }
  Future<bool> refresh() async {
    if (!active || busy) return false;
    busy = true; headLoaded = false; _notify();
    try {
      if (!await restore() || !active) return false;
      if (pending != null) { message = 'Check the original update before starting another.'; return false; }
      final record = await gateway.readPublicDetailsOwned(storeId: scope.store, current: () => active)
        .timeout(const Duration(seconds: 25));
      if (!active) return false;
      if (record == null ? _minimumRevision > 0 : !_validRecord(record) || record.revision < _minimumRevision) {
        throw const FormatException();
      }
      published = record;
      if (record != null) _minimumRevision = record.revision;
      headLoaded = true;
      message = record == null ? 'No public address, contact or hours have been saved yet.' : 'Current public details checked.';
      return true;
    } catch (_) {
      if (active) message = 'Public details could not be confirmed. Your device entries are kept.';
      return false;
    } finally { busy = false; _notify(); }
  }
  Future<WorkspacePublicDetailsWriteResult> publish(WorkspacePublicDetailsFields fields,
    {required bool Function() inputCurrent}) async {
    if (!canPublish || !inputCurrent()) return const WorkspacePublicDetailsWriteResult(WorkspacePublicDetailsWriteState.notSent);
    busy = true; _notify();
    try {
      final original = WorkspacePublicDetailsIntent(ownerAccountId: scope.account, realm: scope.realm, storeId: scope.store,
        expectedRevision: published?.revision ?? 0,
        idempotencyKey: 'details-${List.generate(16, (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0')).join()}',
        details: WorkspacePublicDetailsFields.fromJson(fields.toJson()));
      pending = original; originalNotFound = false;
      await journal.savePending(original).timeout(const Duration(seconds: 10));
      if (!active || !inputCurrent()) {
        if (active) message = 'Your saved details changed. The original request is kept for checking, not replaced.';
        return const WorkspacePublicDetailsWriteResult(WorkspacePublicDetailsWriteState.unknown);
      }
      final result = await gateway.writePublicDetails(original, current: () => active && inputCurrent())
        .timeout(const Duration(seconds: 25));
      if (!active) return const WorkspacePublicDetailsWriteResult(WorkspacePublicDetailsWriteState.unknown);
      return await _finish(original, result, recovery: false);
    } catch (_) {
      if (active) { ready = false; message = 'The public update is not confirmed. Your original request and device entries are kept.'; }
      return const WorkspacePublicDetailsWriteResult(WorkspacePublicDetailsWriteState.unknown);
    } finally { busy = false; _notify(); }
  }
  Future<WorkspacePublicDetailsWriteResult> reconcile() => _recover(retry: false);
  /// Explicit owner choice only. Absence is NOT proof of non-application. This
  /// repeats exactly the persisted idempotent request, never current form inputs.
  Future<WorkspacePublicDetailsWriteResult> retryOriginal() => _recover(retry: true);
  Future<WorkspacePublicDetailsWriteResult> _recover({required bool retry}) async {
    if (!active || busy || (retry && !canRetryOriginal)) {
      return const WorkspacePublicDetailsWriteResult(WorkspacePublicDetailsWriteState.unknown);
    }
    busy = true; _notify();
    try {
      if (!await restore() || !active || pending == null) return const WorkspacePublicDetailsWriteResult(WorkspacePublicDetailsWriteState.unknown);
      final original = pending!;
      originalNotFound = false;
      // Also repairs a journal save that timed out before the first send. It
      // cannot replace another original or overtake a late native write.
      if (retry) await journal.savePending(original).timeout(const Duration(seconds: 10));
      if (!active) return const WorkspacePublicDetailsWriteResult(WorkspacePublicDetailsWriteState.unknown);
      final result = await gateway.writePublicDetails(original, current: () => active, reconcile: !retry)
        .timeout(const Duration(seconds: 25));
      if (!active) return const WorkspacePublicDetailsWriteResult(WorkspacePublicDetailsWriteState.unknown);
      if (!retry && result.state == WorkspacePublicDetailsWriteState.notFound) originalNotFound = true;
      return await _finish(original, result, recovery: true);
    } catch (_) {
      if (active) message = 'The original update is still unconfirmed. It is kept for checking.';
      return const WorkspacePublicDetailsWriteResult(WorkspacePublicDetailsWriteState.unknown);
    } finally { busy = false; _notify(); }
  }
  Future<WorkspacePublicDetailsWriteResult> _finish(WorkspacePublicDetailsIntent original,
    WorkspacePublicDetailsWriteResult result, {required bool recovery}) async {
    final record = result.record;
    final exact = record != null && _validRecord(record) && record.revision == original.expectedRevision + 1 &&
      jsonEncode(_sorted(record.details.toJson())) == jsonEncode(_sorted(original.details.toJson()));
    final saved = result.state == WorkspacePublicDetailsWriteState.saved && exact;
    final definitive = saved || !recovery && {WorkspacePublicDetailsWriteState.notSent, WorkspacePublicDetailsWriteState.rejected}.contains(result.state);
    if (!definitive) {
      message = originalNotFound
        ? 'No saved result was found. The original is still kept; retry sends its saved values, not your current edits.'
        : 'The original public update is not confirmed. Your device entries are kept.';
      return const WorkspacePublicDetailsWriteResult(WorkspacePublicDetailsWriteState.unknown);
    }
    await journal.removePending(original).timeout(const Duration(seconds: 10));
    if (!active) return const WorkspacePublicDetailsWriteResult(WorkspacePublicDetailsWriteState.unknown);
    pending = null; originalNotFound = false; headLoaded = false;
    if (saved) {
      lastAcknowledged = record;
      if (record.revision > _minimumRevision) _minimumRevision = record.revision;
    }
    message = saved ? 'Original update saved. Check current public details; online availability is not confirmed.'
      : 'This update was not saved publicly. Your device entries are kept; check before starting another.';
    return result;
  }
  @override
  void dispose() { _closed = true; super.dispose(); }
}

class WorkspacePublicStoreMetadata {
  const WorkspacePublicStoreMetadata({required this.state, required this.revision, required this.observedAt,
    required this.area, this.details});
  final String state;
  final int? revision;
  final DateTime observedAt;
  final String? area;
  final WorkspacePublicDetailsFields? details;
  static WorkspacePublicStoreMetadata decode(Object? raw, String realm, String storeId, DateTime now) {
    final value = _map(raw);
    _keys(value, ['schemaVersion', 'realm', 'storeId', 'observedAt', 'locationVerified',
      'publicAvailabilityConfirmed', 'area', 'state', 'revision', 'details']);
    final state = value['state'], observedAt = _time(value['observedAt']);
    if (value['schemaVersion'] != 1 || value['realm'] != realm || value['storeId'] != storeId ||
        value['locationVerified'] != false || value['publicAvailabilityConfirmed'] != false || observedAt.isAfter(now) ||
        !{'ready', 'none', 'unavailable'}.contains(state)) {
      throw const FormatException();
    }
    final revision = value['revision'] == null ? null : _int(value['revision'], 0, 1000000000);
    final fields = value['details'] == null ? null : WorkspacePublicDetailsFields.fromJson(_map(value['details']));
    if (state == 'ready' ? revision == null || revision == 0 || fields == null :
        fields != null || (state == 'none' ? revision != 0 : revision != null)) {
      throw const FormatException();
    }
    return WorkspacePublicStoreMetadata(state: state as String, revision: revision, observedAt: observedAt,
      area: value['area'] == null ? null : _string(value['area'], 240, true), details: fields);
  }
}

abstract interface class WorkspaceCatalogueOwnerGateway {
  String get realm;
  Future<WorkspaceCatalogueOwnedSku?> readOwnedSku({
    required String storeId,
    required String skuId,
    required bool Function() current,
  });
  Future<WorkspaceCatalogueBindingResult> bindReviewed(
    WorkspaceCatalogueBindingIntent original, {
    required bool Function() current,
    required bool recoveringUnknown,
  });
  Future<WorkspaceCatalogueBindingResult> reconcileBinding(
    WorkspaceCatalogueBindingIntent original, {
    required bool Function() current,
  });
}

enum WorkspaceCatalogueBindingState { saved, notSent, rejected, unknown }

class WorkspaceCatalogueBindingResult {
  const WorkspaceCatalogueBindingResult(this.state, {this.saved});
  final WorkspaceCatalogueBindingState state;
  final WorkspaceCatalogueOwnedSku? saved;
  // A saved mirror or recovered receipt never authorizes current publication.
  bool get publicationConfirmed => false;
}

/// Exact owner mirror, not an assertion of current review/commerce eligibility.
/// Serialized storage prevents mutation through caller-owned nested maps.
class WorkspaceCatalogueOwnedSku {
  WorkspaceCatalogueOwnedSku._(this._encoded, this.realm);
  final String _encoded;
  final String realm;
  Map<String, dynamic> get _data => _map(jsonDecode(_encoded));
  String get storeId => _data['storeId'] as String;
  String get skuId => _data['skuId'] as String;
  String get canonicalProductId => _data['canonicalProductId'] as String;
  String get verifiedPackId => _data['verifiedPackId'] as String;
  int get revision => _data['revision'] as int;
  Map<String, dynamic> toJson() => _data;
  Map<String, dynamic> get input => _data
    ..remove('schemaVersion')
    ..remove('storeId')
    ..remove('revision')
    ..remove('observedAt');

  static WorkspaceCatalogueOwnedSku decode(
    Object? raw, {
    required String storeId,
    required String skuId,
    required DateTime now,
    required String realm,
  }) {
    if (!{'production', 'evaluation'}.contains(realm)) {
      throw const FormatException();
    }
    final row = _map(raw);
    _keys(row, [
      'schemaVersion',
      'storeId',
      'revision',
      'observedAt',
      'skuId',
      'canonicalProductId',
      'verifiedPackId',
      'sku',
      'publicListing',
      'content',
      'pack',
      'channels',
      'provenance',
    ]);
    if (row['schemaVersion'] != 1 ||
        _id(row['storeId']) != storeId ||
        _id(row['skuId']) != skuId ||
        _time(row['observedAt']).isAfter(now.toUtc())) {
      throw const FormatException();
    }
    _int(row['revision'], 1, 1000000001);
    _ownerSkuInput(
      Map.of(row)
        ..remove('schemaVersion')
        ..remove('storeId')
        ..remove('revision')
        ..remove('observedAt'),
      storeId,
    );
    return WorkspaceCatalogueOwnedSku._(jsonEncode(row), realm);
  }

  WorkspaceCatalogueBindingIntent listingIntent({
    required String accountId,
    required String idempotencyKey,
    required bool listed,
  }) => WorkspaceCatalogueBindingIntent(
    accountId: accountId,
    realm: realm,
    storeId: storeId,
    expectedRevision: revision,
    idempotencyKey: idempotencyKey,
    sku: input..['publicListing'] = listed,
  );
}

/// Retain this exact intent on an unknown result; never allocate a replacement key.
class WorkspaceCatalogueBindingIntent {
  WorkspaceCatalogueBindingIntent({
    required this.accountId,
    required this.realm,
    required this.storeId,
    required this.expectedRevision,
    required this.idempotencyKey,
    required Map<String, dynamic> sku,
    Map<String, dynamic>? reviewCandidate,
    this.reviewedSource,
    this.reviewedMedia,
  }) : _encodedSku = jsonEncode(sku), _encodedReviewCandidate = reviewCandidate == null ? null : jsonEncode(reviewCandidate) {
    _id(accountId);
    if (!{'production', 'evaluation'}.contains(realm)) {
      throw const FormatException();
    }
    _id(storeId);
    _id(idempotencyKey);
    _int(expectedRevision, 0, 1000000000);
    _ownerSkuInput(_map(jsonDecode(_encodedSku)), storeId);
    if ((_encodedReviewCandidate == null) != (reviewedSource == null)) throw const FormatException();
    if (reviewedSource != null && (reviewedSource!.input.skuId != skuId || reviewedSource!.toJson()['submittedBy'] != accountId ||
        reviewedSource!.toJson()['realm'] != realm || reviewedSource!.toJson()['storeId'] != storeId)) { throw const FormatException(); }
    if (reviewedSource?.input.mediaPending == true && reviewedMedia == null) throw const FormatException('Keep the reviewed photo evidence with this original listing request.');
    if (reviewedMedia != null) {
      if (reviewedSource == null || !reviewedSource!.input.mediaPending ||
        !reviewedMedia!.matchesSelection(skuId, reviewedSource!.input.toJson()['mediaIntent']['pendingSelectionSha256'] as String?)) {throw const FormatException();}
      final expected = {..._map(reviewedSource!.input.toJson()['content']), 'media': [reviewedMedia!.descriptor(realm: realm, storeId: storeId,
        skuId: skuId, canonicalId: _id(this.sku['canonicalProductId']))]};
      if (_catalogueHash(expected) != _catalogueHash(this.sku['content'] as Object)) throw const FormatException();
    }
    if (_encodedReviewCandidate != null) {
      final ref = _map(jsonDecode(_encodedReviewCandidate)); _keys(ref, ['revision', 'fingerprint']);
      _int(ref['revision'], 1, 1000000000);
      if (ref['fingerprint'] is! String || !RegExp(r'^[A-F0-9]{64}$').hasMatch(ref['fingerprint'] as String)) throw const FormatException();
    }
  }
  final String accountId, realm, storeId, idempotencyKey, _encodedSku;
  final String? _encodedReviewCandidate;
  final WorkspaceProductSubmissionRecord? reviewedSource;
  final WorkspaceReviewedProductMediaProof? reviewedMedia;
  final int expectedRevision;
  Map<String, dynamic> get sku => _map(jsonDecode(_encodedSku));
  String get skuId => sku['skuId'] as String;
  Map<String, Object?> get body => {
    'storeId': storeId,
    'sku': sku,
    'expectedRevision': expectedRevision,
    'idempotencyKey': idempotencyKey,
    if (_encodedReviewCandidate != null) 'reviewCandidate': jsonDecode(_encodedReviewCandidate),
  };
  Map<String, Object?> toJson() => {
    'schemaVersion': _encodedReviewCandidate == null ? 1 : reviewedMedia == null ? 2 : 3,
    'accountId': accountId,
    'realm': realm,
    ...body,
    if (reviewedSource != null) 'reviewedSource': reviewedSource!.toJson(),
    if (reviewedMedia != null) 'reviewedMedia': reviewedMedia!.toJson(),
  };
  static WorkspaceCatalogueBindingIntent fromJson(Object? value) {
    final raw = _map(value);
    _keys(raw, [
      'schemaVersion',
      'accountId',
      'realm',
      'storeId',
      'sku',
      'expectedRevision',
      'idempotencyKey',
      if (raw['schemaVersion'] == 2 || raw['schemaVersion'] == 3) 'reviewCandidate',
      if (raw['schemaVersion'] == 2 || raw['schemaVersion'] == 3) 'reviewedSource',
      if (raw['schemaVersion'] == 3) 'reviewedMedia',
    ]);
    if (raw['schemaVersion'] is! int || !{1, 2, 3}.contains(raw['schemaVersion'])) throw const FormatException();
    return WorkspaceCatalogueBindingIntent(
      accountId: _id(raw['accountId']),
      realm: _string(raw['realm']),
      storeId: _id(raw['storeId']),
      expectedRevision: _int(raw['expectedRevision'], 0, 1000000000),
      idempotencyKey: _id(raw['idempotencyKey']),
      sku: _map(raw['sku']),
      reviewCandidate: raw['schemaVersion'] == 2 || raw['schemaVersion'] == 3 ? _map(raw['reviewCandidate']) : null,
      reviewedSource: raw['schemaVersion'] == 2 || raw['schemaVersion'] == 3 ? WorkspaceProductSubmissionRecord.decode(raw['reviewedSource'],
        (account: _id(raw['accountId']), store: _id(raw['storeId']), realm: _string(raw['realm']), sku: _id(_map(raw['sku'])['skuId'])),
        _time(_map(raw['reviewedSource'])['submittedAt'])) : null,
      reviewedMedia: raw['schemaVersion'] == 3 ? WorkspaceReviewedProductMediaProof.fromJson(raw['reviewedMedia']) : null,
    );
  }
}

typedef WorkspaceCatalogueBindingScope = ({
  String account,
  String store,
  String realm,
});

abstract interface class WorkspaceCatalogueBindingPendingStore {
  Future<WorkspaceCatalogueBindingIntent?> readPending(
    WorkspaceCatalogueBindingScope scope,
  );
  Future<void> savePending(WorkspaceCatalogueBindingIntent original);
  Future<void> removePending(WorkspaceCatalogueBindingIntent original);
}

/// One unresolved listing request per account/Store/realm; never a Stock writer.
class WorkspaceCatalogueListingController extends ChangeNotifier {
  WorkspaceCatalogueListingController({
    required this.scope,
    required this.gateway,
    required this.pendingStore,
    required this.context,
    this.completeReviewedBinding,
  });
  final WorkspaceCatalogueBindingScope scope;
  final WorkspaceCatalogueOwnerGateway gateway;
  final WorkspaceCatalogueBindingPendingStore pendingStore;
  final Object? Function() context;
  final Future<bool> Function(WorkspaceCatalogueBindingIntent original, WorkspaceCatalogueOwnedSku saved,
    bool Function() current)? completeReviewedBinding;
  WorkspaceCatalogueBindingIntent? pending;
  bool busy = false, ready = false, _closed = false;
  Future<bool>? _restoring;
  String? error;
  bool _current(Object? owner) =>
      !_closed && owner != null && context() == owner;
  bool _owns(WorkspaceCatalogueBindingIntent value) =>
      value.accountId == scope.account &&
      value.storeId == scope.store &&
      value.realm == scope.realm;
  void _notify() {
    if (!_closed) notifyListeners();
  }

  Future<bool> restore() {
    if (_closed || context() == null) return Future.value(false);
    if (ready) return Future.value(true);
    return _restoring ??= _restore().whenComplete(() => _restoring = null);
  }

  Future<bool> _restore() async {
    final owner = context();
    try {
      final saved = await pendingStore
          .readPending(scope)
          .timeout(const Duration(seconds: 10));
      if (!_current(owner)) return false;
      if (saved != null && !_owns(saved)) throw const FormatException();
      pending = saved;
      ready = true;
      error = null;
      _notify();
      return true;
    } on Object {
      if (_current(owner)) {
        ready = false;
        error = 'Your saved listing update could not be opened. Try again.';
        _notify();
      }
      return false;
    }
  }

  Future<WorkspaceCatalogueBindingResult> submit(
    WorkspaceCatalogueBindingIntent original, {
    required bool Function() inputCurrent,
  }) async {
    if (_closed || busy || !_owns(original)) {
      return const WorkspaceCatalogueBindingResult(
        WorkspaceCatalogueBindingState.notSent,
      );
    }
    final owner = context();
    busy = true;
    _notify();
    try {
      if (!await restore() || !_current(owner) || !inputCurrent()) {
        return const WorkspaceCatalogueBindingResult(
          WorkspaceCatalogueBindingState.notSent,
        );
      }
      if (pending != null) {
        return const WorkspaceCatalogueBindingResult(
          WorkspaceCatalogueBindingState.unknown,
        );
      }
      pending = original;
      await pendingStore
          .savePending(original)
          .timeout(const Duration(seconds: 10));
      if (!_current(owner) || !inputCurrent()) {
        // Definitely not dispatched. Clear only this exact original, never another request.
        await pendingStore
            .removePending(original)
            .timeout(const Duration(seconds: 10));
        if (_current(owner)) pending = null;
        return const WorkspaceCatalogueBindingResult(
          WorkspaceCatalogueBindingState.notSent,
        );
      }
      return await _send(
        original,
        owner,
        recovery: false,
        inputCurrent: inputCurrent,
      );
    } on Object {
      if (_current(owner)) {
        ready = false;
        error = 'Listing update is kept. Check it before trying another.';
      }
      return const WorkspaceCatalogueBindingResult(
        WorkspaceCatalogueBindingState.unknown,
      );
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<WorkspaceCatalogueBindingResult> reconcile() async {
    if (_closed || busy) {
      return const WorkspaceCatalogueBindingResult(
        WorkspaceCatalogueBindingState.unknown,
      );
    }
    final owner = context();
    busy = true;
    _notify();
    try {
      if (!await restore() || !_current(owner) || pending == null) {
        return const WorkspaceCatalogueBindingResult(
          WorkspaceCatalogueBindingState.unknown,
        );
      }
      return await _send(pending!, owner, recovery: true);
    } on Object {
      if (_current(owner)) {
        ready = false;
        error = 'Listing update is kept. Check it again when available.';
      }
      return const WorkspaceCatalogueBindingResult(
        WorkspaceCatalogueBindingState.unknown,
      );
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<WorkspaceCatalogueBindingResult> _send(
    WorkspaceCatalogueBindingIntent original,
    Object? owner, {
    required bool recovery,
    bool Function()? inputCurrent,
  }) async {
    bool current() =>
        _current(owner) && (recovery || inputCurrent?.call() == true);
    final result =
        await (recovery
                ? gateway.reconcileBinding(original, current: current)
                : gateway.bindReviewed(
                    original,
                    current: current,
                    recoveringUnknown: false,
                  ))
            .timeout(const Duration(seconds: 25));
    if (!_current(owner)) {
      return const WorkspaceCatalogueBindingResult(
        WorkspaceCatalogueBindingState.unknown,
      );
    }
    final saved = result.saved;
    final exact =
        saved != null &&
        saved.realm == original.realm &&
        saved.storeId == original.storeId &&
        saved.skuId == original.skuId &&
        saved.revision == original.expectedRevision + 1 &&
        jsonEncode(_sorted(saved.input)) == jsonEncode(_sorted(original.sku));
    final definitive =
        result.state == WorkspaceCatalogueBindingState.saved && exact ||
        !recovery &&
            {
              WorkspaceCatalogueBindingState.rejected,
              WorkspaceCatalogueBindingState.notSent,
            }.contains(result.state);
    if (!definitive) {
      error = 'Listing update is not confirmed. Your original request is kept.';
      return const WorkspaceCatalogueBindingResult(
        WorkspaceCatalogueBindingState.unknown,
      );
    }
    if (result.state == WorkspaceCatalogueBindingState.saved && exact && original.body.containsKey('reviewCandidate')) {
      final complete = completeReviewedBinding;
      if (complete == null || !await complete(original, saved, () => _current(owner)).timeout(const Duration(seconds: 10)) || !_current(owner)) {
        error = 'The reviewed listing result is kept. Finish restoring this product before another update.';
        return const WorkspaceCatalogueBindingResult(WorkspaceCatalogueBindingState.unknown);
      }
    }
    await pendingStore
        .removePending(original)
        .timeout(const Duration(seconds: 10));
    if (!_current(owner)) {
      return const WorkspaceCatalogueBindingResult(
        WorkspaceCatalogueBindingState.unknown,
      );
    }
    pending = null;
    error = null;
    return result;
  }

  @override
  void dispose() {
    _closed = true;
    super.dispose();
  }
}

class WorkspaceCatalogueContentResult {
  const WorkspaceCatalogueContentResult({
    required this.content,
    this.skuRevision,
    this.catalogueVersion,
    this.validUntil,
    this.fingerprint,
    this.policyRevision,
    this.policyFingerprint,
  });
  final BuyV2ProductContentSnapshot content;
  final int? skuRevision, catalogueVersion;
  final DateTime? validUntil;
  final String? fingerprint;
  final int? policyRevision;
  final String? policyFingerprint;
}

/// One channel of an exact-SKU public read. Never construct public products
/// from private owner records or infer delivery/Stock eligibility from this.
/// Versioned reviewed descriptive fields, not approval, eligibility or tax facts.
class WorkspaceCatalogueProductFacts {
  const WorkspaceCatalogueProductFacts({this.compliance, this.composition,
    this.regulatoryNote, this.requiresPrescription = false});
  final BuyV2ProductCompliance? compliance;
  final String? composition, regulatoryNote;
  final bool requiresPrescription;
  Map<String, Object?> get _compliance => {
    'genericName': compliance?.genericName, 'netQuantity': compliance?.netQuantity,
    'manufacturerName': compliance?.manufacturerName, 'manufacturerAddress': compliance?.manufacturerAddress,
    'packerName': compliance?.packerName, 'packerAddress': compliance?.packerAddress,
    'importerName': compliance?.importerName, 'importerAddress': compliance?.importerAddress,
    'countryOfOrigin': compliance?.countryOfOrigin, 'manufacturedOrPackedOn': compliance?.manufacturedOrPackedOnLabel,
    'bestBeforeOrUseBy': compliance?.bestBeforeOrUseByLabel, 'fssaiLicenseNumber': compliance?.fssaiLicenseNumber,
    'consumerCare': compliance?.consumerCare,
  };
  bool get isEmpty => !requiresPrescription && composition?.isNotEmpty != true && regulatoryNote?.isNotEmpty != true &&
      _compliance.values.every((value) => value == null);
  Map<String, Object?> toJson() => {'schemaVersion': 1, 'compliance': _compliance,
    'composition': composition?.isNotEmpty == true ? composition : null,
    'regulatoryNote': regulatoryNote?.isNotEmpty == true ? regulatoryNote : null,
    'requiresPrescription': requiresPrescription};
  factory WorkspaceCatalogueProductFacts.fromProduct(BuyV2Product product) => WorkspaceCatalogueProductFacts(
    compliance: product.compliance, composition: product.composition,
    regulatoryNote: product.regulatoryNote, requiresPrescription: product.requiresPrescription);
  factory WorkspaceCatalogueProductFacts.fromJson(Object? raw) {
    final value = _map(raw);
    _keys(value, ['schemaVersion', 'compliance', 'composition', 'regulatoryNote', 'requiresPrescription']);
    if (value['schemaVersion'] is! int || value['schemaVersion'] != 1 || value['requiresPrescription'] is! bool) {
      throw const FormatException();
    }
    final fields = _map(value['compliance']);
    _keys(fields, const WorkspaceCatalogueProductFacts()._compliance.keys.toList());
    String? text(Object? raw, [int maximum = 1000]) => raw == null ? null : _string(raw, maximum);
    for (final raw in fields.values) { text(raw); }
    final compliance = fields.values.every((value) => value == null) ? null : BuyV2ProductCompliance(
      genericName: text(fields['genericName']), netQuantity: text(fields['netQuantity']),
      manufacturerName: text(fields['manufacturerName']), manufacturerAddress: text(fields['manufacturerAddress']),
      packerName: text(fields['packerName']), packerAddress: text(fields['packerAddress']),
      importerName: text(fields['importerName']), importerAddress: text(fields['importerAddress']),
      countryOfOrigin: text(fields['countryOfOrigin']), manufacturedOrPackedOnLabel: text(fields['manufacturedOrPackedOn']),
      bestBeforeOrUseByLabel: text(fields['bestBeforeOrUseBy']), fssaiLicenseNumber: text(fields['fssaiLicenseNumber']),
      consumerCare: text(fields['consumerCare']));
    return WorkspaceCatalogueProductFacts(compliance: compliance,
      composition: text(value['composition'], 4000), regulatoryNote: text(value['regulatoryNote'], 4000),
      requiresPrescription: value['requiresPrescription'] as bool);
  }
}

void _checkProductFactsReadbackVersion(Map<String, dynamic> data) {
  if (data.containsKey('productFactsReadbackVersion') &&
      (data['productFactsReadbackVersion'] is! int || data['productFactsReadbackVersion'] != 1)) {
    throw const FormatException();
  }
}

void _checkProduceReadback(Map<String, dynamic> data, {bool supported = true}) {
  if (data.containsKey('unbrandedProduceReadbackVersion') &&
      (!supported || data['unbrandedProduceReadbackVersion'] is! int ||
       data['unbrandedProduceReadbackVersion'] != 1)) {
    throw const FormatException();
  }
}

String _catalogueBrand(Map<String, dynamic> content, {Map<String, dynamic>? readback}) {
  final brand = _string(content['brand'], 240, _id(content['categoryId']) == 'fruits-vegetables');
  if (brand.isEmpty && readback != null && readback['unbrandedProduceReadbackVersion'] != 1) {
    throw const FormatException();
  }
  return brand;
}

class WorkspacePublicCatalogueEntry {
  const WorkspacePublicCatalogueEntry({required this.product, required this.readback});
  final BuyV2Product product;
  final WorkspaceCatalogueContentResult readback;

  /// Throws on unavailable, incomplete, changed or unrepresentable source facts.
  /// The existing strict content decoder verifies the complete source tuple,
  /// including the actual server binding, pack, channels, policy and media.
  factory WorkspacePublicCatalogueEntry.fromResponse(
    Map<String, dynamic> data, {
    required String storeId,
    required String realm,
    required BuyV2OfferClass channel,
    required DateTime now,
  }) {
    _checkProductFactsReadbackVersion(data);
    _checkProduceReadback(data);
    if (!{'production', 'evaluation'}.contains(realm) ||
        data['realm'] != realm || data['storeId'] != storeId ||
        data['state'] != 'ready' || data['listingCoverage'] != 'complete' ||
        data['nextCursor'] != null) {
      throw const FormatException();
    }
    final rows = _list(data['items'], 1);
    if (rows.length != 1) throw const FormatException();
    final row = _map(rows.single), content = _map(row['content']), pack = _map(row['pack']);
    final facts = content.containsKey('productFacts')
        ? WorkspaceCatalogueProductFacts.fromJson(content['productFacts']) : null;
    if (facts != null && data['productFactsReadbackVersion'] != 1) throw const FormatException();
    final store = _publicStore(data, storeId, realm, now);
    final bindings = _list(row['listings'], 2).map(BuyV2PublicListingIdentity.fromJson)
      .whereType<BuyV2PublicListingIdentity>().where((value) => value.channel == channel).toList();
    final channels = _list(row['channels'], 2).map(_map)
      .where((value) => value['kind'] == channel.name).toList();
    if (bindings.length != 1 || channels.length != 1) throw const FormatException();
    final identity = bindings.single, terms = channels.single;
    final label = _string(pack['label'], 240);
    final count = _int(pack['unitsPerCase']), quantity = BigInt.from(_int(pack['quantityMilli']));
    var unit = switch (pack['unit']) { 'kg' => 'kg', 'L' => 'L', 'count' => 'piece', _ => throw const FormatException() };
    var amount = quantity;
    if (amount % BigInt.from(count) != BigInt.zero) {
      if (unit == 'piece') throw const FormatException();
      amount *= BigInt.from(1000);
      unit = unit == 'kg' ? 'g' : 'mL';
    }
    if (amount % BigInt.from(count) != BigInt.zero) throw const FormatException();
    amount ~/= BigInt.from(count);
    if (amount <= BigInt.zero || amount > BigInt.from(9007199254740991)) throw const FormatException();
    final packTerms = BuyV2PackTerms(skuId: identity.listingId,
      revision: _id(terms['revision']), sellUnit: label, sourceLabel: label,
      containedUnits: count, netContentMilli: amount.toInt(), contentUnit: unit,
      quantityStep: _int(terms['quantityStep']), pricingStoreId: storeId,
      priceObservedAt: _time(row['observedAt']), priceValidUntil: _time(terms['validUntil']),
      priceTiers: List.unmodifiable(_list(terms['tiers'], 20).map((raw) {
        final tier = _map(raw);
        return BuyV2PackPriceTier(minimumPacks: _int(tier['minimumQuantity']), priceMinor: _int(tier['unitPriceMinor']));
      })));
    final product = BuyV2Product(id: identity.listingId, canonicalId: _id(row['canonicalProductId']),
      storeId: storeId, publicListingIdentity: identity,
      destination: channel == BuyV2OfferClass.retail ? BuyV2Destination.shop : BuyV2Destination.wholesale,
      categoryId: _id(content['categoryId']), brand: _catalogueBrand(content, readback: data),
      title: _string(content['title']), variant: _string(content['variant'], 240, true),
      compliance: facts?.compliance, composition: facts?.composition,
      regulatoryNote: facts?.regulatoryNote, requiresPrescription: facts?.requiresPrescription ?? false,
      pack: label, packTerms: packTerms, priceMinor: _int(terms['priceMinor']),
      mrpMinor: terms['mrpMinor'] == null ? null : _int(terms['mrpMinor']),
      unitPrice: '', badge: '', seller: _string(store['name'], 240),
      sellerType: _publicSellerType(data, storeId, realm, now),
      deliveryPromise: '', origin: '', confirmedOn: '', visualLabel: '', visualKind: '',
      minimumOrder: _int(terms['minimumOrder']), offerClass: channel);
    final readback = _decode(data, product, realm, now.toUtc(), policyRequired: true);
    if (readback.content.state != BuyV2ProductContentState.ready || !product.hasValidPackTerms) {
      throw const FormatException();
    }
    return WorkspacePublicCatalogueEntry(product: product.copyWith(mediaAssets: List.unmodifiable(
      readback.content.media.where((asset) => BuyV2SupplierMediaPolicy.publicationMessage(product, asset) == null))),
      readback: readback);
  }
}

/// Reviewed association readback only. No owner write, review command or guessed
/// HTTP operation. A configured source must cover each requested listing, using
/// an explicit no-family record rather than treating missing data as standalone.
abstract interface class WorkspacePublicVariantSource {
  Future<List<WorkspaceReviewedVariantMembership>> readMemberships(
    List<WorkspacePublicCatalogueEntry> entries, {required bool Function() current});
  Future<BuyV2VariantFamilySnapshot> readFamily(BuyV2Product selected,
    BuyV2CatalogueQuery query, {required bool Function() current});
}

class WorkspaceReviewedVariantMembership {
  WorkspaceReviewedVariantMembership({required this.listing, required this.skuRevision,
    required this.catalogueVersion, required this.familyId, required this.sourceId,
    required this.revision, required this.observedAt, required this.validUntil,
    required Iterable<BuyV2VariantAttribute> attributes}) : attributes = List.unmodifiable(attributes);
  final BuyV2PublicListingIdentity listing;
  final int skuRevision, catalogueVersion, revision;
  final String? familyId;
  final String sourceId;
  final DateTime observedAt, validUntil;
  final List<BuyV2VariantAttribute> attributes;
  String get fingerprint {
    final ordered = attributes.toList()..sort((a, b) => a.dimensionId.compareTo(b.dimensionId));
    return jsonEncode([sourceId, familyId, for (final a in ordered)
      [a.dimensionId, a.dimensionLabel, a.optionId, a.optionLabel, a.kind.name, a.swatchArgb]]);
  }
  bool validFor(WorkspacePublicCatalogueEntry entry, String realm, DateTime now) {
    if (!listing.valid || listing.realm != realm || listing != entry.product.publicListingIdentity ||
        !listing.matches(entry.product) || skuRevision != entry.readback.skuRevision ||
        catalogueVersion != entry.readback.catalogueVersion || revision < 1 || revision > 1000000000 ||
        sourceId.isEmpty || sourceId != sourceId.trim() || sourceId.length > 240 ||
        observedAt.isAfter(now) || !now.isBefore(validUntil) || !observedAt.isBefore(validUntil)) { return false; }
    if (familyId == null) return attributes.isEmpty && entry.product.variantFamilyId == null;
    if (familyId!.length > 128 || attributes.length > 8) return false;
    final product = entry.product.copyWith(variantFamilyId: familyId, variantAttributes: attributes);
    return product.hasValidVariantFamilyIdentity && product.hasStructuredVariants;
  }
}

/// Existing workspace endpoint, negotiated only with its reviewed-family contract.
/// A private owner family is never a fallback for missing reviewed readback.
class WorkspaceHttpReviewedVariantSource implements WorkspacePublicVariantSource {
  WorkspaceHttpReviewedVariantSource(this.gateway);
  final AuthenticatedWorkspaceCatalogueGateway gateway;

  Future<Map<String, dynamic>> _read(String storeId, List<BuyV2PublicListingIdentity> listings,
      bool Function() current, {String? familyId}) async {
    if (!current() || listings.isEmpty || listings.length > 50 ||
        listings.any((i) => !i.valid || i.storeId != storeId || i.realm != gateway.realm)) { throw const FormatException(); }
    final response = await gateway._ownerRequest({'operation': 'readPublicStoreVariantFamilies', 'storeId': storeId,
      if (gateway.storeClassificationReadbackSupported) 'storeClassificationReadbackVersion': 1,
      'listings': [for (final i in listings) {'listingId': i.listingId, 'skuId': i.skuId, 'channel': i.channel.name}],
      'familyId': ?familyId}, current, mutation: false);
    if (!current() || response?.statusCode != 200) throw const FormatException();
    final envelope = _map(jsonDecode(response!.body));
    if (envelope['ok'] != true) throw const FormatException();
    final data = _map(envelope['data']);
    if (data['state'] != 'ready') throw const FormatException('Published options are unavailable.');
    _checkStoreClassificationReadback(data, supported: gateway.storeClassificationReadbackSupported);
    if (gateway.storeClassificationReadbackSupported && data['storeClassificationReadbackVersion'] != 1) throw const FormatException();
    _keys(Map<String, dynamic>.of(data)..remove('storeClassificationReadbackVersion')..remove('storeDetailsReadbackVersion'), ['schemaVersion', 'realm', 'storeId', 'observedAt', 'orderingAvailable', 'state',
      'catalogueVersion', 'publicStore', 'sourceId', 'revision', 'validUntil', 'memberships', 'family']);
    final now = gateway.now().toUtc(), observed = _time(data['observedAt']), expires = _time(data['validUntil']);
    if (data['schemaVersion'] is! int || data['schemaVersion'] != 1 || data['realm'] != gateway.realm ||
        data['storeId'] != storeId || data['orderingAvailable'] != false || observed.isAfter(now) ||
        !now.isBefore(expires) || !observed.isBefore(expires) || expires.difference(observed) > const Duration(minutes: 5) ||
        data['sourceId'] != 'store-reviewed-variants:${gateway.realm}:$storeId') { throw const FormatException(); }
    _int(data['revision'], 1, 1000000000); _int(data['catalogueVersion'], 1, 1000000001);
    _publicStore(data, storeId, gateway.realm, now);
    return data;
  }

  BuyV2VariantAttribute _attribute(Object? raw) {
    final row = _map(raw);
    _keys(row, ['dimensionId', 'dimensionLabel', 'optionId', 'optionLabel', 'kind', 'swatchArgb']);
    final kinds = BuyV2VariantDimensionKind.values.where((v) => v.name == row['kind']);
    if (kinds.length != 1) throw const FormatException();
    final result = BuyV2VariantAttribute(dimensionId: _id(row['dimensionId']), dimensionLabel: _string(row['dimensionLabel'], 120),
      optionId: _id(row['optionId']), optionLabel: _string(row['optionLabel'], 120), kind: kinds.single,
      swatchArgb: row['swatchArgb'] == null ? null : _int(row['swatchArgb'], 0, 0xffffffff));
    if (!result.isValid) throw const FormatException();
    return result;
  }

  WorkspaceReviewedVariantMembership _membership(Object? raw, Map<String, dynamic> data) {
    final row = _map(raw);
    _keys(row, ['listing', 'skuRevision', 'catalogueVersion', 'familyId', 'sourceId', 'revision',
      'observedAt', 'validUntil', 'attributes']);
    final listing = BuyV2PublicListingIdentity.fromJson(row['listing']);
    if (listing == null || !listing.valid || listing.realm != gateway.realm || listing.storeId != data['storeId'] ||
        row['sourceId'] != data['sourceId'] || row['revision'] != data['revision'] ||
        row['catalogueVersion'] != data['catalogueVersion'] || row['observedAt'] != data['observedAt'] ||
        row['validUntil'] != data['validUntil']) { throw const FormatException(); }
    return WorkspaceReviewedVariantMembership(listing: listing, skuRevision: _int(row['skuRevision'], 1, 1000000000),
      catalogueVersion: _int(row['catalogueVersion'], 1, 1000000001), familyId: row['familyId'] == null ? null : _id(row['familyId']),
      sourceId: _string(row['sourceId']), revision: _int(row['revision'], 1, 1000000000),
      observedAt: _time(row['observedAt']), validUntil: _time(row['validUntil']),
      attributes: _list(row['attributes'], 8).map(_attribute));
  }

  @override
  Future<List<WorkspaceReviewedVariantMembership>> readMemberships(List<WorkspacePublicCatalogueEntry> entries,
      {required bool Function() current}) async {
    final checked = <String, WorkspaceReviewedVariantMembership>{};
    final stores = entries.map((e) => e.product.storeId).toSet();
    for (final storeId in stores) {
      if (storeId == null) throw const FormatException();
      final group = entries.where((e) => e.product.storeId == storeId).toList();
      for (var offset = 0; offset < group.length; offset += 50) {
        final batch = group.sublist(offset, min(offset + 50, group.length));
        final listings = batch.map((e) => e.product.publicListingIdentity).toList();
        if (listings.any((i) => i == null)) throw const FormatException();
        final data = await _read(storeId, listings.cast<BuyV2PublicListingIdentity>(), current);
        if (data['storeClassificationReadbackVersion'] == 1 && batch.any((entry) =>
            entry.product.sellerType != _publicSellerType(data, storeId, gateway.realm, gateway.now().toUtc()))) {
          throw const FormatException('Store details changed. Refresh this product.');
        }
        final rows = _list(data['memberships'], 50).map((r) => _membership(r, data)).toList();
        if (rows.length != batch.length) throw const FormatException();
        for (final row in rows) {
          final matches = batch.where((e) => e.product.id == row.listing.listingId);
          if (checked.containsKey(row.listing.listingId) || matches.length != 1 ||
              !row.validFor(matches.single, gateway.realm, gateway.now().toUtc())) { throw const FormatException(); }
          checked[row.listing.listingId] = row;
        }
        if (data['family'] != null) throw const FormatException();
      }
    }
    if (!current()) throw const FormatException();
    return List.unmodifiable(entries.map((e) => checked[e.product.id]!));
  }

  @override
  Future<BuyV2VariantFamilySnapshot> readFamily(BuyV2Product selected, BuyV2CatalogueQuery query,
      {required bool Function() current}) async {
    // Only the gateway admits a complete batch after its monotonicity checks.
    // A rejected reply must never replace the context of a retained product.
    final previous = gateway._variantMemberships[selected.id], identity = selected.publicListingIdentity;
    if (previous == null || identity == null || previous.familyId == null || previous.familyId != selected.variantFamilyId ||
        !identity.matches(selected) || !gateway.now().toUtc().isBefore(previous.validUntil)) { throw const FormatException(); }
    final data = await _read(identity.storeId, [identity], current, familyId: previous.familyId);
    final memberships = _list(data['memberships'], 1).map((r) => _membership(r, data)).toList();
    if (memberships.length != 1 || memberships.single.listing != identity || memberships.single.fingerprint != previous.fingerprint ||
        memberships.single.revision != previous.revision || memberships.single.skuRevision != previous.skuRevision ||
        memberships.single.catalogueVersion != previous.catalogueVersion) { throw const FormatException('Options changed. Refresh this product.'); }
    final family = _map(data['family']);
    _keys(family, ['familyId', 'options', 'products']);
    if (family['familyId'] != previous.familyId) throw const FormatException();
    final products = <BuyV2Product>[];
    for (final raw in _list(family['products'], 80)) {
      final row = _map(raw); _keys(row, ['product', 'membership']);
      final member = _membership(row['membership'], data);
      final entry = WorkspacePublicCatalogueEntry.fromResponse({'schemaVersion': 1, 'realm': gateway.realm,
        'storeId': identity.storeId, 'observedAt': data['observedAt'], 'state': 'ready', 'orderingAvailable': false,
        'coverage': 'verified_public_only', 'listingCoverage': 'complete', 'listingReadbackVersion': 1,
        'productFactsReadbackVersion': 1, 'mediaReadbackVersion': 1, 'unbrandedProduceReadbackVersion': 1,
        if (data.containsKey('storeClassificationReadbackVersion')) 'storeClassificationReadbackVersion': data['storeClassificationReadbackVersion'],
        if (data.containsKey('storeDetailsReadbackVersion')) 'storeDetailsReadbackVersion': data['storeDetailsReadbackVersion'],
        'catalogueVersion': data['catalogueVersion'], 'publicStore': data['publicStore'], 'items': [row['product']], 'nextCursor': null},
        storeId: identity.storeId, realm: gateway.realm, channel: identity.channel, now: gateway.now().toUtc());
      if (!member.validFor(entry, gateway.realm, gateway.now().toUtc()) || member.familyId != previous.familyId ||
          products.any((p) => p.id == entry.product.id)) { throw const FormatException(); }
      products.add(entry.product.copyWith(variantFamilyId: member.familyId, variantAttributes: member.attributes));
    }
    if (!current()) throw const FormatException();
    final expiry = _time(data['validUntil']);
    return BuyV2VariantFamilySnapshot(productId: selected.id, canonicalId: selected.canonicalId,
      variantFamilyId: previous.familyId, categoryId: selected.categoryId, offerClass: selected.offerClass,
      realm: gateway.realm, storeId: identity.storeId, destination: selected.destination, queryKey: query.key,
      sourceId: previous.sourceId, revision: '${previous.revision}', observedAt: _time(data['observedAt']),
      validUntil: expiry.isBefore(previous.validUntil) ? expiry : previous.validUntil, complete: true,
      selectedAvailable: products.any((p) => p.id == selected.id),
      options: _list(family['options'], 128).map(_attribute), candidates: products);
  }
}

/// Genuine exact-Store catalogue source. Global/geo discovery and Store address
/// metadata require their own providers; an unsupported call is not an empty feed.
class WorkspaceStoreCatalogueSource implements BuyV2CataloguePageSource, BuyV2VariantFamilySource, BuyV2StorePublishedOffersSource {
  WorkspaceStoreCatalogueSource({required this.gateway, required this.storeId, required this.current, this.contentReadback});
  final AuthenticatedWorkspaceCatalogueGateway gateway;
  final String storeId;
  final bool Function() current;
  final WorkspaceCatalogueReadback? contentReadback;
  WorkspacePublicStoreMetadata? _storeMetadata;
  int? _metadataHighwater;
  String? _metadataFingerprint;
  String? _publicStoreName;
  int _promotionGeneration = 0;
  final _promotionHeads = <String, ({int revision, DateTime observed, String copy})>{};
  void Function() _prepareMetadata(Map<String, dynamic> data) {
    final store = _publicStore(data, storeId, gateway.realm, gateway.now().toUtc());
    final metadata = data['storeDetailsReadbackVersion'] == 1
      ? WorkspacePublicStoreMetadata.decode(store['details'], gateway.realm, storeId, gateway.now().toUtc()) : null;
    final fingerprint = jsonEncode(_sorted(metadata?.details?.toJson())), revision = metadata?.revision;
    void check() {
      if (_metadataHighwater != null && (revision == null || revision < _metadataHighwater! ||
          revision == _metadataHighwater && fingerprint != _metadataFingerprint)) {
        throw const FormatException('Public Store details changed. Refresh this Store.');
      }
    }
    check();
    final name = _string(store['name'], 240);
    return () {
      check();
      _storeMetadata = metadata;
      if (revision != null) { _metadataHighwater = revision; _metadataFingerprint = fingerprint; }
      _publicStoreName = name;
    };
  }
  @override
  bool get storeOffersActive => current();

  @override
  Future<List<BuyV2PublishedCatalogueOffer>> loadStoreOffers({required String storeId,
    required BuyV2Destination destination}) {
    var reading = true;
    final generation = ++_promotionGeneration;
    bool active() => reading && current() && generation == _promotionGeneration;
    return _readStoreOffers(storeId, destination, active)
      .timeout(const Duration(seconds: 25)).whenComplete(() => reading = false);
  }

  Future<List<BuyV2PublishedCatalogueOffer>> _readStoreOffers(String requestedStore,
      BuyV2Destination destination, bool Function() active) async {
    if (requestedStore != storeId || !active() ||
        !{BuyV2Destination.shop, BuyV2Destination.wholesale}.contains(destination)) {
      throw const FormatException('Promotions could not be checked.');
    }
    _id(storeId);
    final contentOwner = contentReadback?.context();
    final results = <BuyV2PublishedCatalogueOffer>[];
    final entries = <WorkspacePublicCatalogueEntry>[];
    final resolved = <String, WorkspacePublicCatalogueEntry>{};
    final heads = <String, ({int revision, DateTime observed, String copy})>{};
    final cursors = <String>{}, publications = <String>{};
    String? after;
    var complete = false;
    for (var page = 0; page < 20; page++) {
      if (!active()) throw const FormatException();
      final response = await gateway._ownerRequest({'operation': 'readPublicStorePromotions',
        'storeId': storeId, 'limit': 20, 'after': ?after,
        if (gateway.promotionTermsSupported) 'promotionTermsVersion': 1}, active, mutation: false);
      if (!active() || response?.statusCode != 200) throw const FormatException();
      final envelope = _map(jsonDecode(response!.body));
      if (envelope['ok'] != true) throw const FormatException();
      final data = _map(envelope['data']);
      _keys(data, ['schemaVersion', 'realm', 'storeId', 'observedAt', 'state', 'coverage',
        'orderingAvailable', 'items', 'nextCursor', if (gateway.promotionTermsSupported) 'promotionTermsVersion']);
      if (gateway.promotionTermsSupported) _int(data['promotionTermsVersion'], 1, 1);
      final observed = _time(data['observedAt']), now = gateway.now().toUtc();
      if (data['schemaVersion'] is! int || data['schemaVersion'] != 1 || data['realm'] != gateway.realm ||
          data['storeId'] != storeId || data['state'] != 'ready' ||
          data['coverage'] != 'verified_public_promotions_only' || data['orderingAvailable'] != false ||
          observed.isAfter(now)) { throw const FormatException(); }
      var previous = after;
      for (final raw in _list(data['items'], 20)) {
        final row = _map(raw);
        _keys(row, ['publicationId', 'revision', 'publisherType', 'publisherId', 'publisherName',
          'headline', 'detail', 'sourceId', 'observedAt', 'validUntil', 'product',
          if (gateway.promotionTermsSupported && row.containsKey('benefitTerms')) 'benefitTerms']);
        final benefitTerms = row.containsKey('benefitTerms') ? BuyV2AdvertisedBenefitTerms.fromJson(row['benefitTerms']) : null;
        final id = _id(row['publicationId']), revision = _int(row['revision'], 1, 1000000000);
        final source = _string(row['sourceId'], 512), itemObserved = _time(row['observedAt']);
        if (!publications.add(id) || previous != null && id.compareTo(previous) <= 0 ||
            row['publisherType'] != 'retailer' || row['publisherId'] != storeId ||
            source != 'store-promotion:${gateway.realm}:$storeId:$id:$revision' || itemObserved.isAfter(observed)) {
          throw const FormatException();
        }
        previous = id;
        final headline = _string(row['headline'], 160), detail = _string(row['detail'], 2000, true);
        final expiry = _time(row['validUntil']), sku = _map(row['product']);
        _keys(Map<String, dynamic>.of(sku)..remove('supplierPolicy'), ['skuId', 'canonicalProductId',
          'verifiedPackId', 'sku', 'revision', 'observedAt', 'content', 'pack', 'channels']);
        final channelRow = _map(_list(sku['channels'], 1).single);
        final channel = BuyV2OfferClass.values.where((c) => c.name == channelRow['kind']).single;
        if (!itemObserved.isBefore(expiry) || !now.isBefore(expiry)) throw const FormatException();
        if ((channel == BuyV2OfferClass.retail ? BuyV2Destination.shop : BuyV2Destination.wholesale) != destination) { continue; }
        final skuId = _id(sku['skuId']), resolutionKey = jsonEncode([skuId, channel.name]);
        final entry = resolved[resolutionKey] ?? await gateway.readPublicEntry(storeId: storeId, skuId: skuId,
          channel: channel, current: active);
        if (!active() || entry == null || entry.product.storeId != storeId ||
            entry.product.publicListingIdentity?.realm != gateway.realm) { throw const FormatException(); }
        resolved[resolutionKey] = entry;
        // Resolve the real listing first. Compare every immutable SKU/pack/media/
        // content/price fact, and separately pin the governed term window. Never
        // manufacture the missing listings/envelope from a promotion payload.
        final actual = _checkedPromotionProduct(sku, entry, expiry);
        final copy = jsonEncode([source, headline, detail, _sorted(actual), if (benefitTerms != null) benefitTerms.toJson()]);
        final head = (revision: revision, observed: itemObserved, copy: copy), old = _promotionHeads[id];
        if (old != null && (revision < old.revision || itemObserved.isBefore(old.observed) ||
            revision == old.revision && copy != old.copy)) { throw const FormatException(); }
        heads[id] = head;
        entries.add(entry);
        results.add(BuyV2PublishedCatalogueOffer(publicationId: id, revision: revision,
          product: entry.product, publisherType: BuyV2OfferPublisherType.retailer, publisherId: storeId,
          publisherName: _string(row['publisherName'], 240), headline: headline, detail: detail,
          sourceId: source, observedAt: itemObserved, validUntil: expiry, benefitTerms: benefitTerms));
      }
      final next = data['nextCursor'] == null ? null : _id(data['nextCursor']);
      if (next == null) { complete = true; break; }
      // The service filters rows after paging, so even an empty page can have a
      // genuine next cursor. It cannot loop or move backwards past shown rows.
      if (!cursors.add(next) || after != null && next.compareTo(after) <= 0 ||
          previous != null && next.compareTo(previous) < 0) { throw const FormatException(); }
      after = next;
    }
    final completedAt = gateway.now().toUtc();
    if (!complete || !active() || results.any((r) => !r.isCurrent(now: completedAt))) {
      throw const FormatException('Promotions could not be fully checked.');
    }
    // No high-water/cache admission from a partial, retired or expired traversal.
    _promotionHeads.addAll(heads);
    if (contentReadback != null && contentOwner != null) {
      for (final entry in entries) { contentReadback!.admitPublicEntry(entry, expectedContext: contentOwner); }
    }
    return List.unmodifiable(results);
  }

  Map<String, Object?> _query(BuyV2CatalogueQuery query, {Set<String> listingIds = const {}}) {
    if (query.storeId != storeId || query.areaScope != BuyV2CatalogueAreaScope.allAreas ||
        !{BuyV2Destination.shop, BuyV2Destination.wholesale}.contains(query.destination) ||
        query.shopSaleType != null || query.fulfilmentMode != null || query.pack != null || query.filter != null ||
        query.availableOnly || query.offersOnly || query.collectionOnly || query.offerPublisher != null ||
        query.supplierOffersOnly || query.procurementContext != null || query.sort == BuyV2ProductSort.deliveryFastest) {
      throw const FormatException('This Store catalogue query needs an additional provider.');
    }
    return {'destination': query.destination.name,
      'search': query.query.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' '),
      'categoryId': query.categoryId, 'sort': query.sort.name, 'brands': query.brands.toList()..sort(),
      'maximumPriceMinor': query.maximumPrice == null ? null : query.maximumPrice! * 100,
      'tradeType': query.wholesaleSaleType?.name, 'listingIds': listingIds.toList()..sort()};
  }

  Future<BuyV2CataloguePage<BuyV2Product>> _load(BuyV2CatalogueQuery query,
    {String? cursor, required int pageSize, Set<String> listingIds = const {}, bool Function()? requestCurrent}) async {
    bool active() => current() && (requestCurrent?.call() ?? true);
    final request = _query(query, listingIds: listingIds);
    final contentOwner = contentReadback?.context();
    if (pageSize < 1 || pageSize > 50 || !active()) throw const FormatException();
    final response = await gateway._ownerRequest({'operation': 'readPublicStoreCatalogue',
      'storeId': storeId, 'cataloguePageVersion': gateway.minorMoneyReadbackSupported ? 2 : 1, 'query': request, 'pageSize': pageSize,
      if (gateway.productFactsReadbackSupported) 'productFactsReadbackVersion': 1,
      'storeDetailsReadbackVersion': 1,
      if (gateway.storeClassificationReadbackSupported) 'storeClassificationReadbackVersion': 1,
      'cursor': ?cursor}, active, mutation: false);
    if (!active() || response == null || response.statusCode != 200) throw const FormatException();
    final envelope = _map(jsonDecode(response.body));
    if (envelope['ok'] != true) throw const FormatException();
    final data = _map(envelope['data']);
    _checkProductFactsReadbackVersion(data);
    _checkProduceReadback(data, supported: gateway.unbrandedProduceReadbackSupported);
    _checkStoreClassificationReadback(data, supported: gateway.storeClassificationReadbackSupported);
    if (gateway.storeClassificationReadbackSupported && data['storeClassificationReadbackVersion'] != 1) throw const FormatException();
    if (data['cataloguePageVersion'] is! int || data['cataloguePageVersion'] != (gateway.minorMoneyReadbackSupported ? 2 : 1) ||
        (gateway.minorMoneyReadbackSupported ? data['moneyUnit'] != 'paise' : data.containsKey('moneyUnit')) ||
        data['schemaVersion'] != 1 || data['realm'] != gateway.realm ||
        data['storeId'] != storeId || data['state'] != 'ready' || data['listingReadbackVersion'] != 1 ||
        data['mediaReadbackVersion'] != 1 || data['listingCoverage'] != 'complete' ||
        data['coverage'] != 'verified_public_only' || data['orderingAvailable'] != false ||
        _time(data['observedAt']).isAfter(gateway.now().toUtc()) ||
        jsonEncode(_sorted(data['query'])) != jsonEncode(_sorted(request))) {
      throw const FormatException();
    }
    final metadata = _map(data['page']);
    _keys(metadata, ['snapshotId', 'startIndex', 'totalCount', 'previousCursor', 'nextCursor']);
    final snapshotId = _string(metadata['snapshotId'], 64);
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(snapshotId)) throw const FormatException();
    final start = _int(metadata['startIndex'], 0, 1000), total = _int(metadata['totalCount'], 0, 1000);
    final next = metadata['nextCursor'] == null ? null : _string(metadata['nextCursor'], 2048);
    final previous = metadata['previousCursor'] == null ? null : _string(metadata['previousCursor'], 2048);
    final rows = _list(data['items'], pageSize);
    if ((cursor == null && start != 0) || start + rows.length > total ||
        (start == 0) != (previous == null) || (next == null) != (start + rows.length == total) ||
        (rows.isEmpty && (next != null || total != 0)) || data['nextCursor'] != next) {
      throw const FormatException();
    }
    final decodedEntries = rows.map((raw) {
      final item = _map(raw);
      _keys(item, ['channel', 'row']);
      final channel = BuyV2OfferClass.values.where((value) => value.name == item['channel']).single;
      final entry = WorkspacePublicCatalogueEntry.fromResponse({...data,
        // Page semantics were verified above. Project this single returned row
        // through the same exact-SKU binding/content decoder, not owner storage.
        'items': [_map(item['row'])], 'nextCursor': null},
        storeId: storeId, realm: gateway.realm, channel: channel, now: gateway.now().toUtc());
      if (entry.product.destination != query.destination ||
          (query.wholesaleSaleType != null && channel.name != query.wholesaleSaleType!.name) ||
          (listingIds.isNotEmpty && !listingIds.contains(entry.product.id))) {
        throw const FormatException();
      }
      return entry;
    }).toList(growable: false);
    final admitMetadata = _prepareMetadata(data);
    final entries = await gateway._enrichVariants(decodedEntries, active);
    final products = entries.map((entry) => entry.product).toList(growable: false);
    if (products.map((product) => product.id).toSet().length != products.length || !active()) throw const FormatException();
    admitMetadata();
    if (contentReadback != null && contentOwner != null) {
      for (final entry in entries) { contentReadback!.admitPublicEntry(entry, expectedContext: contentOwner); }
    }
    return BuyV2CataloguePage(queryKey: query.key, snapshotId: snapshotId, items: products,
      startIndex: start, totalCount: total, previousCursor: previous, nextCursor: next,
      storeObservation: BuyV2PublicStoreObservation(realm: gateway.realm, storeId: storeId,
        catalogueVersion: _int(data['catalogueVersion'], 1, 1000000001), observedAt: _time(data['observedAt'])));
  }

  @override
  Future<BuyV2CataloguePage<BuyV2Product>> loadProducts(BuyV2CatalogueQuery query,
    {String? cursor, required int pageSize}) => _load(query, cursor: cursor, pageSize: pageSize);

  @override
  Future<BuyV2VariantFamilySnapshot> loadVariantFamily(BuyV2Product selected, BuyV2CatalogueQuery context) {
    if (selected.storeId != storeId || context.storeId != storeId) throw const FormatException();
    var reading = true;
    bool active() => reading && current();
    return gateway._readReviewedFamily(selected, context, active,
      (ids) => resolveProducts(ids, requestCurrent: active))
      .timeout(const Duration(seconds: 15)).whenComplete(() => reading = false);
  }

  @override
  Future<BuyV2CataloguePage<BuyV2StoreListing>> loadStores(BuyV2CatalogueQuery query,
    {String? cursor, required int pageSize}) async {
    if (cursor != null || pageSize < 1 || pageSize > 50) throw const FormatException();
    final page = await _load(query, pageSize: 1), metadata = _storeMetadata, details = metadata?.details;
    if (!current() || metadata?.state != 'ready' || details == null || _publicStoreName == null) {
      throw const FormatException('Public Store details are unavailable.');
    }
    final store = BuyV2StoreListing(id: storeId, name: _publicStoreName!, area: metadata!.area?.isNotEmpty == true
      ? metadata.area! : '${details.city}, ${details.state}', address: details.address, regionId: '',
      publicContactPhone: details.publicContactPhone.isEmpty ? null : details.publicContactPhone,
      openingHoursLabel: details.openingTime.isEmpty ? null : '${details.openingTime} – ${details.closingTime}');
    return BuyV2CataloguePage(queryKey: query.key, snapshotId: page.snapshotId, items: [store],
      startIndex: 0, totalCount: 1);
  }

  @override
  Future<List<BuyV2Product>> resolveProducts(Set<String> productIds, {bool Function()? requestCurrent}) async {
    if (productIds.isEmpty) return const [];
    if (productIds.length > 50 || productIds.any((id) => !RegExp(r'^listing-[a-f0-9]{64}$').hasMatch(id))) {
      throw const FormatException();
    }
    final products = <BuyV2Product>[];
    for (final destination in [BuyV2Destination.shop, BuyV2Destination.wholesale]) {
      if (!current() || requestCurrent?.call() == false) throw const FormatException();
      final page = await _load(BuyV2CatalogueQuery(destination: destination, regionId: null,
        areaScope: BuyV2CatalogueAreaScope.allAreas, storeId: storeId), pageSize: 50, listingIds: productIds,
        requestCurrent: requestCurrent);
      products.addAll(page.items);
    }
    if (!current() || requestCurrent?.call() == false) throw const FormatException();
    return List.unmodifiable(products);
  }
}

// Reused by exact-Store and ordinary Offers. A promotion never supplies the
// missing listing identity or silently overrides current catalogue facts.
Map<String, dynamic> _checkedPromotionProduct(Map<String, dynamic> sku,
    WorkspacePublicCatalogueEntry entry, DateTime expiry) {
  _keys(Map<String, dynamic>.of(sku)..remove('supplierPolicy'), ['skuId', 'canonicalProductId',
    'verifiedPackId', 'sku', 'revision', 'observedAt', 'content', 'pack', 'channels']);
  final channelRow = _map(_list(sku['channels'], 1).single);
  final expected = _map(jsonDecode(entry.readback.fingerprint!))..remove('listings');
  expected['channels'] = _list(expected['channels'], 2).map(_map)
    .where((c) => c['kind'] == channelRow['kind']).toList();
  final actual = Map<String, dynamic>.of(sku)..remove('supplierPolicy');
  actual['channels'] = [Map<String, dynamic>.of(channelRow)..remove('revision')..remove('validUntil')];
  final expectedMedia = _list(_map(expected['content'])['media'], 10),
    actualMedia = _list(_map(actual['content'])['media'], 10);
  if (expectedMedia.length != actualMedia.length) throw const FormatException();
  for (var index = 0; index < actualMedia.length; index++) {
    final actualFile = _map(_map(actualMedia[index])['file']), expectedFile = _map(_map(expectedMedia[index])['file']);
    if (!actualFile.containsKey('frameCount') && expectedFile['frameCount'] == 1) { expectedFile.remove('frameCount'); }
  }
  if (jsonEncode(_sorted(actual)) != jsonEncode(_sorted(expected)) ||
      channelRow['revision'] != entry.product.packTerms?.revision ||
      _time(channelRow['validUntil']) != entry.product.packTerms?.priceValidUntil ||
      expiry.isAfter(entry.product.packTerms!.priceValidUntil!)) { throw const FormatException(); }
  return actual;
}

/// One authenticated account-generation's public discovery/content owner.
/// Unsupported geography/fulfilment filters require their actual producer.
/// Lossy, explicitly partial presentation reporting; never a visitor/payment/Stock ledger.
class WorkspaceProductPresentationGateway {
  WorkspaceProductPresentationGateway({required this.gateway, required this.current, required this.displayed,
    this.productPresentationsEnabled = true, this.storePresentationsEnabled = false, this.cartAdditionsEnabled = false});
  final AuthenticatedWorkspaceCatalogueGateway gateway;
  final bool Function() current;
  final WorkspaceCatalogueContentResult? Function(BuyV2Product) displayed;
  final bool productPresentationsEnabled, storePresentationsEnabled, cartAdditionsEnabled;
  Map<String, Object?>? prepare(BuyV2Product product, String presentationId, {bool cartAddition = false}) {
    final identity = product.publicListingIdentity, result = displayed(product);
    if (!(cartAddition ? cartAdditionsEnabled : productPresentationsEnabled) || !current() || identity == null || !identity.matches(product) || identity.realm != gateway.realm ||
        result?.content.state != BuyV2ProductContentState.ready || result?.validUntil?.isAfter(gateway.now().toUtc()) != true ||
        result?.skuRevision == null || result?.catalogueVersion == null || !RegExp(r'^[a-f0-9]{32}$').hasMatch(presentationId)) {return null;}
    return {'schemaVersion': 1, 'presentationId': presentationId, 'storeId': identity.storeId, 'skuId': identity.skuId,
      'listingId': identity.listingId, 'skuRevision': result!.skuRevision, 'catalogueVersion': result.catalogueVersion};
  }
  Map<String, Object?>? prepareStore(BuyV2PublicStoreObservation observation, String presentationId) {
    if (!storePresentationsEnabled || !current() || observation.realm != gateway.realm ||
        !observation.currentFor(observation.storeId, gateway.now().toUtc()) || !RegExp(r'^[a-f0-9]{32}$').hasMatch(presentationId)) {
      return null;
    }
    return {'schemaVersion': 1, 'presentationId': presentationId, 'storeId': observation.storeId,
      'catalogueVersion': observation.catalogueVersion, 'observedAt': observation.observedAt.toUtc().toIso8601String()};
  }
  Future<bool> record(Map<String, Object?> original, {required bool Function() visible, bool storeVisit = false}) async {
    return _record(original, visible: visible, operation: storeVisit ? 'recordPublicStorePresentation' : 'recordPublicProductPresentation',
      enabled: () => storeVisit ? storePresentationsEnabled : productPresentationsEnabled);
  }
  Future<bool> recordCartAddition(Map<String, Object?> original, {required bool Function() ownerCurrent}) =>
    _record(original, visible: ownerCurrent, operation: 'recordPublicCartAddition', enabled: () => cartAdditionsEnabled);
  Future<bool> _record(Map<String, Object?> original, {required bool Function() visible, required String operation, required bool Function() enabled}) async {
    final frozen = Map<String, Object?>.unmodifiable(original);
    bool valid() => current() && visible() && enabled();
    try {
      if (!valid()) return false;
      final response = await gateway._ownerRequest({'operation': operation, ...frozen}, valid, mutation: true);
      if (!valid() || response?.statusCode != 200) return false;
      final envelope = _map(jsonDecode(response!.body)); _keys(envelope, ['ok', 'data']);
      final data = _map(envelope['data']);
      _keys(data, [...frozen.keys, 'realm', 'acceptedAt', 'state', 'orderingAvailable']);
      return envelope['ok'] == true && data['realm'] == gateway.realm && data['state'] == 'recorded' && data['orderingAvailable'] == false &&
        !_time(data['acceptedAt']).isAfter(gateway.now().toUtc()) && frozen.entries.every((e) => data[e.key] == e.value);
    } on Object {return false;}
  }
  Future<WorkspaceAnalyticsSnapshot> readAnalytics(WorkspaceAnalyticsRequest request) async {
    if (!current() || !request.valid || request.accountScope != gateway.ownerAccountId) throw const FormatException();
    if (!storePresentationsEnabled && !cartAdditionsEnabled && productPresentationsEnabled) return _readProductAnalytics(request);
    final results = <WorkspaceAnalyticsSnapshot>[];
    if (productPresentationsEnabled) {
      try {results.add(await _readProductAnalytics(request));} on Object {/* Independent coverage remains unknown, never zero. */}
    }
    if (storePresentationsEnabled && current()) {
      try {results.add(await _readStoreAnalytics(request));} on Object {/* Keep verified product metrics if this source is unavailable. */}
    }
    if (cartAdditionsEnabled && current()) {
      try {results.add(await _readProductAnalytics(request, cart: true));} on Object {/* Independent Cart coverage remains unknown. */}
    }
    if (!current()) throw const FormatException();
    final verified = results.where((r) => r.state == WorkspaceAnalyticsState.verified && r.usableFor(request, gateway.now().toUtc())).toList();
    if (verified.isEmpty) {
      return WorkspaceAnalyticsSnapshot(request: request, state: WorkspaceAnalyticsState.unavailable,
        coverage: WorkspaceAnalyticsCoverage.unknown, source: 'Recorded public activity', metrics: const []);
    }
    if (verified.length == 1) return verified.single;
    final refreshed = verified.map((r) => r.updatedAt!).reduce((a, b) => a.isAfter(b) ? a : b);
    final from = verified.map((r) => r.coveredFrom!).reduce((a, b) => a.isBefore(b) ? a : b);
    final until = verified.map((r) => r.coveredUntil!).reduce((a, b) => a.isAfter(b) ? a : b);
    return WorkspaceAnalyticsSnapshot(request: request, state: WorkspaceAnalyticsState.verified,
      coverage: WorkspaceAnalyticsCoverage.partial, source: 'Reported public activity · partial coverage',
      updatedAt: refreshed, coveredFrom: from, coveredUntil: until,
      metrics: verified.expand((r) => r.metrics), breakdowns: verified.expand((r) => r.breakdowns));
  }
  Future<WorkspaceAnalyticsSnapshot> _readStoreAnalytics(WorkspaceAnalyticsRequest request) async {
    if (!current() || !request.valid || request.accountScope != gateway.ownerAccountId) throw const FormatException();
    DateTime floor(DateTime v) => DateTime.fromMillisecondsSinceEpoch(v.toUtc().millisecondsSinceEpoch, isUtc: true);
    final start = floor(request.start), end = floor(request.end);
    final fromRequest = start.isBefore(request.start) ? start.add(const Duration(milliseconds: 1)) : start;
    if (!fromRequest.isBefore(end)) throw const FormatException();
    final query = {'schemaVersion': 1, 'storeId': request.storeId, 'start': fromRequest.toIso8601String(),
      'end': end.toIso8601String(), 'skuIds': request.skuIds.toList()..sort()};
    final response = await gateway._ownerRequest({'operation': 'readStorePublicPresentations', ...query}, current, mutation: false);
    if (!current() || response?.statusCode != 200 || utf8.encode(response!.body).length > 512 * 1024) throw const FormatException();
    final envelope = _map(jsonDecode(response.body)); _keys(envelope, ['ok', 'data']);
    if (envelope['ok'] != true) throw const FormatException();
    final data = _map(envelope['data']);
    _keys(data, [...query.keys, 'realm', 'observedAt', 'source', 'state', 'coverage', 'collectionStartedAt', 'coveredFrom', 'coveredUntil', 'count', 'visitors']);
    final observed = _time(data['observedAt']);
    if (data['realm'] != gateway.realm || data['source'] != 'Recorded signed-in Store visits' || observed.isAfter(gateway.now().toUtc()) ||
        query.entries.any((e) => jsonEncode(data[e.key]) != jsonEncode(e.value))) {
      throw const FormatException();
    }
    if (data['state'] == 'unavailable') {
      if (data['coverage'] != 'unknown' || data['count'] != null || data['visitors'] != null || data['coveredFrom'] != null || data['coveredUntil'] != null ||
          data['collectionStartedAt'] != null && _time(data['collectionStartedAt']).isAfter(observed)) {
        throw const FormatException();
      }
      return WorkspaceAnalyticsSnapshot(request: request, state: WorkspaceAnalyticsState.unavailable,
        coverage: WorkspaceAnalyticsCoverage.unknown, source: 'Recorded signed-in Store visits', metrics: const []);
    }
    final from = _time(data['coveredFrom']), until = _time(data['coveredUntil']), collected = _time(data['collectionStartedAt']);
    final count = _int(data['count'], 0, 5000), visitors = _int(data['visitors'], 0, count);
    if (request.skuIds.isNotEmpty || data['state'] != 'ready' || data['coverage'] != 'signed_in_partial' ||
        collected.isAfter(from) || from.isBefore(fromRequest) || until.isAfter(end) || until.isAfter(observed) ||
        !from.isBefore(until) || (count == 0) != (visitors == 0)) {
      throw const FormatException();
    }
    String date(DateTime value) {
      final local = value.toLocal();
      return '${local.day}/${local.month}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    }
    final source = 'Signed-in Store visits only · tracked ${date(from)} to ${date(until)}';
    return WorkspaceAnalyticsSnapshot(request: request, state: WorkspaceAnalyticsState.verified,
      coverage: WorkspaceAnalyticsCoverage.partial, source: 'Recorded signed-in Store visits', updatedAt: observed,
      coveredFrom: from, coveredUntil: until, metrics: [
        for (final entry in {'store-views': count, 'visits': count, 'visitors': visitors}.entries)
          WorkspaceAnalyticsMetric(id: entry.key, state: WorkspaceAnalyticsState.verified, coverage: WorkspaceAnalyticsCoverage.partial,
            basis: WorkspaceAnalyticsBasis.periodActivity, unit: WorkspaceAnalyticsUnit.count, source: source, value: entry.value, asOf: until),
      ]);
  }
  Future<WorkspaceAnalyticsSnapshot> _readProductAnalytics(WorkspaceAnalyticsRequest request, {bool cart = false}) async {
    if (!current() || !request.valid || request.accountScope != gateway.ownerAccountId) throw const FormatException();
    DateTime millisecondFloor(DateTime value) {
      final utc = value.toUtc();
      return DateTime.utc(utc.year, utc.month, utc.day, utc.hour, utc.minute, utc.second, utc.millisecond);
    }
    final floor = millisecondFloor(request.start);
    // The provider records milliseconds. Narrow the covered interval; never
    // round start outward and count an event before the user's selected range.
    final wireStart = floor.isBefore(request.start) ? floor.add(const Duration(milliseconds: 1)) : floor,
      wireEnd = millisecondFloor(request.end);
    if (!wireStart.isBefore(wireEnd)) {
      return WorkspaceAnalyticsSnapshot(request: request, state: WorkspaceAnalyticsState.unavailable,
        coverage: WorkspaceAnalyticsCoverage.unknown, source: 'Recorded product views', metrics: const []);
    }
    final skus = request.skuIds.toList()..sort();
    final query = {'schemaVersion': 1, 'storeId': request.storeId, 'start': wireStart.toIso8601String(),
      'end': wireEnd.toIso8601String(), 'skuIds': skus};
    final sourceName = cart ? 'Reported signed-in Cart additions' : 'Recorded product views';
    final response = await gateway._ownerRequest({'operation': cart ? 'readStoreCartAdditions' : 'readStoreProductPresentations', ...query}, current, mutation: false);
    if (!current() || response?.statusCode != 200 || utf8.encode(response!.body).length > 512 * 1024) throw const FormatException();
    final envelope = _map(jsonDecode(response.body)); _keys(envelope, ['ok', 'data']);
    if (envelope['ok'] != true) throw const FormatException();
    final data = _map(envelope['data']);
    _keys(data, [...query.keys, 'realm', 'observedAt', 'source', 'state', 'coverage', 'collectionStartedAt', 'coveredFrom', 'coveredUntil', 'count', 'products', if (cart) 'customers']);
    if (data['realm'] != gateway.realm || query.entries.any((e) => jsonEncode(data[e.key]) != jsonEncode(e.value)) || data['source'] != sourceName) throw const FormatException();
    final observed = _time(data['observedAt']);
    if (observed.isAfter(gateway.now().toUtc())) throw const FormatException();
    if (data['state'] == 'unavailable') {
      if (data['coverage'] != 'unknown' || data['count'] != null || cart && data['customers'] != null || data['coveredFrom'] != null || data['coveredUntil'] != null || _list(data['products'], 0).isNotEmpty) throw const FormatException();
      if (data['collectionStartedAt'] != null && _time(data['collectionStartedAt']).isAfter(observed)) throw const FormatException();
      return WorkspaceAnalyticsSnapshot(request: request, state: WorkspaceAnalyticsState.unavailable,
        coverage: WorkspaceAnalyticsCoverage.unknown, source: sourceName, metrics: const []);
    }
    final from = _time(data['coveredFrom']), until = _time(data['coveredUntil']), start = _time(data['collectionStartedAt']);
    if (data['state'] != 'ready' || data['coverage'] != 'partial' || start.isAfter(from) || from.isBefore(wireStart) ||
        until.isAfter(wireEnd) || until.isAfter(observed) || !from.isBefore(until)) {throw const FormatException();}
    final count = _int(data['count'], 0, 5000), ids = <String>{};
    var total = 0;
    final rows = _list(data['products'], 5000).map((raw) {
      final row = _map(raw); _keys(row, ['skuId', 'label', 'count']);
      final id = _id(row['skuId']), amount = _int(row['count'], 1, 5000);
      if (!ids.add(id) || skus.isNotEmpty && !skus.contains(id)) throw const FormatException();
      total += amount;
      return WorkspaceAnalyticsRank(id: id, label: _string(row['label']), count: amount);
    }).toList(growable: false);
    if (total != count) throw const FormatException();
    final customers = cart ? _int(data['customers'], 0, count) : count;
    if (cart && (count == 0) != (customers == 0)) throw const FormatException();
    final snapshot = WorkspaceAnalyticsSnapshot(request: request, state: WorkspaceAnalyticsState.verified,
      coverage: WorkspaceAnalyticsCoverage.partial, source: sourceName, updatedAt: observed, coveredFrom: from, coveredUntil: until,
      metrics: [WorkspaceAnalyticsMetric(id: cart ? 'journey-cart' : 'product-views', state: WorkspaceAnalyticsState.verified,
        coverage: WorkspaceAnalyticsCoverage.partial, basis: WorkspaceAnalyticsBasis.periodActivity, unit: WorkspaceAnalyticsUnit.count,
        source: cart ? 'Distinct signed-in accounts reporting Add actions · partial coverage' : sourceName, value: customers, asOf: until)],
      breakdowns: [if (!cart) WorkspaceAnalyticsBreakdown(id: 'most-viewed-products', dimension: WorkspaceAnalyticsDimension.product,
        coverage: WorkspaceAnalyticsCoverage.partial, asOf: until, source: 'Recorded product views', rows: rows)]);
    if (!snapshot.usableFor(request, gateway.now().toUtc())) throw const FormatException();
    return snapshot;
  }
}

class WorkspacePublicDiscoverySource extends ChangeNotifier
    implements BuyV2CataloguePageSource, BuyV2VariantFamilySource,
      BuyV2ProductContentAdapter, BuyV2StorePublishedOffersSource, BuyV2PublishedCatalogueSource {
  WorkspacePublicDiscoverySource({required this.gateway, required this.current}) {
    if (!gateway.productFactsReadbackSupported || !gateway.unbrandedProduceReadbackSupported ||
        !gateway.storeClassificationReadbackSupported) { throw ArgumentError('Matching discovery contracts are required.'); }
    _readback = WorkspaceCatalogueReadback(gateway: gateway, context: () => active ? this : null, now: gateway.now);
    _readback.addListener(_changed);
  }
  final AuthenticatedWorkspaceCatalogueGateway gateway;
  final bool Function() current;
  late final WorkspaceCatalogueReadback _readback;
  final _stores = <String, WorkspaceStoreCatalogueSource>{};
  final _offerHeads = <String, ({int revision, DateTime observed, String copy})>{};
  final _offerCopies = <String, String>{};
  bool _closed = false;
  bool get active => !_closed && current();
  Iterable<String> get observedProductIds => _readback.observedProductIds;
  WorkspaceCatalogueContentResult? displayedProduct(BuyV2Product product) => active ? _readback.displayedProduct(product) : null;
  void _changed() { if (active) notifyListeners(); }
  WorkspaceStoreCatalogueSource _store(String storeId) => _stores.putIfAbsent(_id(storeId), () =>
    WorkspaceStoreCatalogueSource(gateway: gateway, storeId: storeId, current: () => active, contentReadback: _readback));

  Map<String, Object?> _query(BuyV2CatalogueQuery query, Set<String> ids) {
    if (query.areaScope != BuyV2CatalogueAreaScope.allAreas ||
        !{BuyV2Destination.shop, BuyV2Destination.wholesale}.contains(query.destination) ||
        query.shopSaleType != null || query.fulfilmentMode != null || query.pack != null || query.filter != null ||
        query.availableOnly || query.offersOnly || query.collectionOnly || query.offerPublisher != null ||
        query.supplierOffersOnly || query.procurementContext != null || query.sort == BuyV2ProductSort.deliveryFastest) {
      throw const FormatException('These filters require another connected provider.');
    }
    if (query.storeId != null) _id(query.storeId);
    return {'destination': query.destination.name,
      'search': query.query.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' '),
      'categoryId': query.categoryId, 'sort': query.sort.name, 'brands': query.brands.toList()..sort(),
      'maximumPriceMinor': query.maximumPrice == null ? null : query.maximumPrice! * 100,
      'tradeType': query.wholesaleSaleType?.name, 'listingIds': ids.toList()..sort()};
  }

  Future<({BuyV2CataloguePage<BuyV2Product> products, List<BuyV2StoreListing> stores})> _load(
    BuyV2CatalogueQuery query, {required int pageSize, String? cursor, String kind = 'products',
    Set<String> ids = const {}, bool Function()? requestCurrent}) async {
    bool valid() => active && (requestCurrent?.call() ?? true);
    if (!valid() || pageSize < 1 || pageSize > 50) throw const FormatException();
    final requested = _query(query, ids);
    final response = await gateway._ownerRequest({'operation': 'readPublicCatalogueDiscovery',
      'discoveryPageVersion': 1, 'query': requested, 'pageSize': pageSize, 'resultKind': kind,
      if (query.storeId != null) 'storeId': query.storeId, 'cursor': ?cursor}, valid, mutation: false);
    if (!valid() || response?.statusCode != 200 || utf8.encode(response!.body).length > 512 * 1024) throw const FormatException();
    final envelope = _map(jsonDecode(response.body));
    _keys(envelope, ['ok', 'data']);
    if (envelope['ok'] != true) throw const FormatException();
    final data = _map(envelope['data']);
    _keys(data, ['schemaVersion', 'discoveryPageVersion', 'realm', 'state', 'coverage', 'directoryCoverage',
      'orderingAvailable', 'observedAt', 'query', 'resultKind', 'requestedStore', 'items', 'page']);
    if (_int(data['schemaVersion'], 1, 1) != 1 || _int(data['discoveryPageVersion'], 1, 1) != 1 ||
        data['realm'] != gateway.realm || data['state'] != 'ready' || data['coverage'] != 'verified_public_only' ||
        data['directoryCoverage'] != 'complete_bounded' || data['orderingAvailable'] != false ||
        data['resultKind'] != kind || data['requestedStore'] != query.storeId ||
        _time(data['observedAt']).isAfter(gateway.now().toUtc()) ||
        jsonEncode(_sorted(data['query'])) != jsonEncode(_sorted(requested))) { throw const FormatException(); }
    final metadata = _map(data['page']);
    _keys(metadata, ['snapshotId', 'startIndex', 'totalCount', 'previousCursor', 'nextCursor']);
    final snapshotId = _string(metadata['snapshotId'], 64);
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(snapshotId)) throw const FormatException();
    final start = _int(metadata['startIndex'], 0, 500), total = _int(metadata['totalCount'], 0, 500);
    final next = metadata['nextCursor'] == null ? null : _string(metadata['nextCursor'], 2048);
    final previous = metadata['previousCursor'] == null ? null : _string(metadata['previousCursor'], 2048);
    final rows = _list(data['items'], pageSize);
    if ((cursor == null && start != 0) || start % pageSize != 0 || start + rows.length > total ||
        (start == 0) != (previous == null) || (next == null) != (start + rows.length == total) ||
        (rows.isEmpty && total != 0)) { throw const FormatException(); }
    final admissions = <void Function()>[], storeCopies = <String, String>{};
    final decoded = rows.map((raw) {
      final item = _map(raw); _keys(item, ['channel', 'listing']);
      final listing = _map(item['listing']), storeId = _id(listing['storeId']);
      final channels = BuyV2OfferClass.values.where((value) => value.name == item['channel']);
      if (channels.length != 1 || query.storeId != null && query.storeId != storeId ||
          listing['productFactsReadbackVersion'] != 1 || listing['storeClassificationReadbackVersion'] != 1 ||
          listing['storeDetailsReadbackVersion'] != 1 ||
          _time(listing['observedAt']).isAfter(_time(data['observedAt']))) { throw const FormatException(); }
      final entry = WorkspacePublicCatalogueEntry.fromResponse(listing, storeId: storeId,
        realm: gateway.realm, channel: channels.single, now: gateway.now().toUtc());
      if (entry.product.destination != query.destination || ids.isNotEmpty && !ids.contains(entry.product.id) ||
          query.wholesaleSaleType != null && entry.product.offerClass?.name != query.wholesaleSaleType!.name) { throw const FormatException(); }
      final storeCopy = jsonEncode(_sorted(listing['publicStore']));
      if (storeCopies[storeId] != null && storeCopies[storeId] != storeCopy) throw const FormatException();
      storeCopies[storeId] = storeCopy;
      admissions.add(_store(storeId)._prepareMetadata(listing));
      return entry;
    }).toList(growable: false);
    if (decoded.map((e) => kind == 'stores' ? e.product.storeId! : e.product.id).toSet().length != decoded.length) throw const FormatException();
    final entries = await gateway._enrichVariants(decoded, valid);
    if (!valid()) throw const FormatException();
    for (final admission in admissions) { admission(); }
    for (final entry in entries) { _readback.admitPublicEntry(entry, expectedContext: this); }
    final products = entries.map((entry) => entry.product).toList(growable: false);
    final stores = <BuyV2StoreListing>[];
    if (kind == 'stores') { for (final product in products) {
      final store = _store(product.storeId!), metadata = store._storeMetadata, details = metadata?.details;
      stores.add(BuyV2StoreListing(id: product.storeId!, name: store._publicStoreName!,
        area: metadata?.area ?? (details == null ? '' : '${details.city}, ${details.state}'),
        address: details?.address ?? '', regionId: '', previewProduct: product,
        publicContactPhone: details?.publicContactPhone.isNotEmpty == true ? details!.publicContactPhone : null,
        openingHoursLabel: details?.openingTime.isNotEmpty == true ? '${details!.openingTime} – ${details.closingTime}' : null));
    } }
    return (products: BuyV2CataloguePage(queryKey: query.key, snapshotId: snapshotId, items: products,
      startIndex: start, totalCount: total, previousCursor: previous, nextCursor: next,
      storeObservation: query.storeId != null && entries.isNotEmpty &&
        entries.every((e) => e.readback.catalogueVersion == entries.first.readback.catalogueVersion)
        ? BuyV2PublicStoreObservation(realm: gateway.realm, storeId: query.storeId!,
          catalogueVersion: entries.first.readback.catalogueVersion!, observedAt: _time(data['observedAt'])) : null),
      stores: List<BuyV2StoreListing>.unmodifiable(stores));
  }

  @override
  Future<BuyV2CataloguePage<BuyV2Product>> loadProducts(BuyV2CatalogueQuery query, {String? cursor, required int pageSize}) async =>
    (await _load(query, cursor: cursor, pageSize: pageSize)).products;
  @override
  Future<BuyV2CataloguePage<BuyV2PublishedCatalogueOffer>> loadOffers(BuyV2CatalogueQuery query,
      {String? cursor, required int pageSize}) async {
    var reading = true;
    bool valid() => reading && active;
    try {
      if (!valid() || !gateway.promotionDiscoverySupported || !query.offersOnly || pageSize < 1 || pageSize > 50 ||
          query.areaScope != BuyV2CatalogueAreaScope.allAreas || query.destination != BuyV2Destination.shop ||
          query.storeId != null || query.shopSaleType != null || query.wholesaleSaleType != null || query.fulfilmentMode != null ||
          query.pack != null || query.filter != null || query.availableOnly || query.collectionOnly ||
          query.brands.isNotEmpty || query.maximumPrice != null || query.sort != BuyV2ProductSort.relevance ||
          query.procurementContext != null) { throw const FormatException('These offers need another connected source.'); }
      final requested = {'search': query.query.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' '),
        'categoryId': query.categoryId, 'publisher': query.offerPublisher?.name, 'supplierOnly': query.supplierOffersOnly};
      final response = await gateway._ownerRequest({'operation': 'readPublicPromotionDiscovery',
        'promotionDiscoveryVersion': 1, 'query': requested, 'pageSize': pageSize, 'cursor': ?cursor,
        if (gateway.promotionTermsSupported) 'promotionTermsVersion': 1}, valid, mutation: false);
      if (!valid() || response?.statusCode != 200 || utf8.encode(response!.body).length > 512 * 1024) throw const FormatException();
      final envelope = _map(jsonDecode(response.body)); _keys(envelope, ['ok', 'data']);
      if (envelope['ok'] != true) throw const FormatException();
      final data = _map(envelope['data']);
      _keys(data, ['schemaVersion', 'promotionDiscoveryVersion', 'realm', 'state', 'coverage', 'orderingAvailable',
        'observedAt', 'query', 'items', 'page', if (gateway.promotionTermsSupported) 'promotionTermsVersion']);
      if (gateway.promotionTermsSupported) _int(data['promotionTermsVersion'], 1, 1);
      final observed = _time(data['observedAt']), now = gateway.now().toUtc(), coverage = _map(data['coverage']);
      _keys(coverage, ['kind', 'publisherTypes', 'countBasis']);
      if (_int(data['schemaVersion'], 1, 1) != 1 || _int(data['promotionDiscoveryVersion'], 1, 1) != 1 ||
          data['realm'] != gateway.realm || data['state'] != 'ready' || data['orderingAvailable'] != false || observed.isAfter(now) ||
          jsonEncode(_sorted(data['query'])) != jsonEncode(_sorted(requested)) ||
          coverage['kind'] != 'connected_publishers' || coverage['countBasis'] != 'publications' ||
          jsonEncode(coverage['publisherTypes']) != '["retailer"]') { throw const FormatException(); }
      final metadata = _map(data['page']);
      _keys(metadata, ['snapshotId', 'startIndex', 'totalCount', 'previousCursor', 'nextCursor']);
      final snapshot = _string(metadata['snapshotId'], 64), start = _int(metadata['startIndex'], 0, 500), total = _int(metadata['totalCount'], 0, 500);
      final next = metadata['nextCursor'] == null ? null : _string(metadata['nextCursor'], 2048),
        previous = metadata['previousCursor'] == null ? null : _string(metadata['previousCursor'], 2048);
      final rows = _list(data['items'], pageSize);
      if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(snapshot) || cursor == null && start != 0 || start % pageSize != 0 ||
          start + rows.length > total || (start == 0) != (previous == null) ||
          (next == null) != (start + rows.length == total) || rows.isEmpty && total != 0) { throw const FormatException(); }
      final entries = <WorkspacePublicCatalogueEntry>[], publications = <Map<String, dynamic>>[],
        admissions = <void Function()>[], heads = <String, ({int revision, DateTime observed, String copy})>{}, copies = <String, String>{};
      for (final raw in rows) {
        final row = _map(raw); _keys(row, ['publication', 'listing']);
        final publication = _map(row['publication']), listing = _map(row['listing']);
        _keys(publication, ['publicationId', 'revision', 'publisherType', 'publisherId', 'publisherName',
          'headline', 'detail', 'sourceId', 'observedAt', 'validUntil', 'product',
          if (gateway.promotionTermsSupported && publication.containsKey('benefitTerms')) 'benefitTerms']);
        final benefitTerms = publication.containsKey('benefitTerms') ? BuyV2AdvertisedBenefitTerms.fromJson(publication['benefitTerms']) : null;
        final storeId = _id(publication['publisherId']), id = _id(publication['publicationId']), revision = _int(publication['revision'], 1);
        final itemObserved = _time(publication['observedAt']), expiry = _time(publication['validUntil']), source = _string(publication['sourceId'], 512);
        final sku = _map(publication['product']), channelRow = _map(_list(sku['channels'], 1).single),
          channel = BuyV2OfferClass.values.where((c) => c.name == channelRow['kind']).single;
        if (publication['publisherType'] != 'retailer' || !query.acceptsOfferPublisher(BuyV2OfferPublisherType.retailer) ||
            listing['storeId'] != storeId || listing['productFactsReadbackVersion'] != 1 || listing['storeClassificationReadbackVersion'] != 1 ||
            listing['storeDetailsReadbackVersion'] != 1 || _time(listing['observedAt']).isAfter(observed) ||
            source != 'store-promotion:${gateway.realm}:$storeId:$id:$revision' || itemObserved.isAfter(observed) ||
            !itemObserved.isBefore(expiry) || !now.isBefore(expiry)) { throw const FormatException(); }
        final entry = WorkspacePublicCatalogueEntry.fromResponse(listing, storeId: storeId, realm: gateway.realm, channel: channel, now: now);
        final actual = _checkedPromotionProduct(sku, entry, expiry);
        final headline = _string(publication['headline'], 160), detail = _string(publication['detail'], 2000, true);
        _string(publication['publisherName'], 240);
        final identity = jsonEncode([gateway.realm, 'retailer', storeId, id]),
          copy = jsonEncode([source, headline, detail, _sorted(actual), if (benefitTerms != null) benefitTerms.toJson()]), old = _offerHeads[identity];
        if (heads.containsKey(identity) || old != null && (revision < old.revision || itemObserved.isBefore(old.observed) || revision == old.revision && copy != old.copy)) throw const FormatException();
        heads[identity] = (revision: revision, observed: itemObserved, copy: copy);
        final key = '$snapshot:${entry.product.id}', productCopy = entry.readback.fingerprint!;
        if ((copies[key] ?? _offerCopies[key]) case final known? when known != productCopy) throw const FormatException();
        copies[key] = productCopy;
        entries.add(entry); publications.add(publication); admissions.add(_store(storeId)._prepareMetadata(listing));
      }
      final uniqueEntries = {for (final entry in entries) entry.product.id: entry};
      final uniqueEnriched = await gateway._enrichVariants(uniqueEntries.values.toList(), valid);
      final enrichedById = {for (final entry in uniqueEnriched) entry.product.id: entry};
      final enriched = entries.map((entry) => enrichedById[entry.product.id]!).toList();
      final offers = List.generate(enriched.length, (index) {
        final p = publications[index];
        return BuyV2PublishedCatalogueOffer(publicationId: p['publicationId'], revision: p['revision'], product: enriched[index].product,
          publisherType: BuyV2OfferPublisherType.retailer, publisherId: p['publisherId'], publisherName: p['publisherName'],
          headline: p['headline'], detail: p['detail'], sourceId: p['sourceId'], observedAt: _time(p['observedAt']), validUntil: _time(p['validUntil']),
          benefitTerms: p.containsKey('benefitTerms') ? BuyV2AdvertisedBenefitTerms.fromJson(p['benefitTerms']) : null);
      });
      if (!valid() || offers.any((offer) => !offer.isCurrent(now: gateway.now().toUtc()))) throw const FormatException();
      // Another page/refresh may finish while reviewed-family enrichment awaits.
      // Recheck the current high-water marks before admitting any captured copy.
      for (final entry in heads.entries) {
        final head = entry.value, old = _offerHeads[entry.key];
        if (old != null && (head.revision < old.revision || head.observed.isBefore(old.observed) ||
            head.revision == old.revision && head.copy != old.copy)) { throw const FormatException(); }
      }
      for (final entry in copies.entries) {
        if (_offerCopies[entry.key] case final known? when known != entry.value) throw const FormatException();
      }
      for (final admit in admissions) { admit(); }
      for (final entry in enriched) { _readback.admitPublicEntry(entry, expectedContext: this); }
      _offerHeads.addAll(heads); _offerCopies.addAll(copies);
      while (_offerCopies.length > 500) { _offerCopies.remove(_offerCopies.keys.first); }
      while (_offerHeads.length > 500) { _offerHeads.remove(_offerHeads.keys.first); }
      return BuyV2CataloguePage(queryKey: query.key, snapshotId: snapshot, items: offers, startIndex: start, totalCount: total,
        previousCursor: previous, nextCursor: next, offerCoverage: BuyV2OfferCoverage([BuyV2OfferPublisherType.retailer]));
    } finally {reading = false;}
  }
  @override
  Future<BuyV2CataloguePage<BuyV2StoreListing>> loadStores(BuyV2CatalogueQuery query, {String? cursor, required int pageSize}) async {
    final result = await _load(query, cursor: cursor, pageSize: pageSize, kind: 'stores'), page = result.products;
    return BuyV2CataloguePage(queryKey: page.queryKey, snapshotId: page.snapshotId, items: result.stores,
      startIndex: page.startIndex, totalCount: page.totalCount, previousCursor: page.previousCursor, nextCursor: page.nextCursor);
  }
  @override
  Future<List<BuyV2Product>> resolveProducts(Set<String> productIds, {bool Function()? requestCurrent}) async {
    if (productIds.isEmpty) return const [];
    if (productIds.length > 50 || productIds.any((id) => !RegExp(r'^listing-[a-f0-9]{64}$').hasMatch(id))) throw const FormatException();
    final results = <BuyV2Product>[];
    for (final destination in [BuyV2Destination.shop, BuyV2Destination.wholesale]) {
      results.addAll((await _load(BuyV2CatalogueQuery(destination: destination, regionId: null,
        areaScope: BuyV2CatalogueAreaScope.allAreas), pageSize: 50, ids: productIds, requestCurrent: requestCurrent)).products.items);
    }
    if (!active || requestCurrent?.call() == false) throw const FormatException();
    return List.unmodifiable(results);
  }
  @override
  Future<BuyV2VariantFamilySnapshot> loadVariantFamily(BuyV2Product selected, BuyV2CatalogueQuery context) {
    var reading = true;
    bool valid() => reading && active;
    return gateway._readReviewedFamily(selected, context, valid, (ids) => resolveProducts(ids, requestCurrent: valid))
      .whenComplete(() => reading = false);
  }
  @override
  bool get storeOffersActive => active;
  @override
  Future<List<BuyV2PublishedCatalogueOffer>> loadStoreOffers({required String storeId, required BuyV2Destination destination}) =>
    _store(storeId).loadStoreOffers(storeId: storeId, destination: destination);
  @override
  BuyV2ProductContentSnapshot snapshotFor(BuyV2Product product) {
    if (!active || product.publicListingIdentity?.realm != gateway.realm) return _unavailable(product);
    final snapshot = _readback.snapshotFor(product);
    if (snapshot.state == BuyV2ProductContentState.unavailable) unawaited(_readback.refresh(product));
    return snapshot;
  }
  @override
  void dispose() {
    _closed = true;
    _readback.removeListener(_changed);
    _readback.dispose();
    super.dispose();
  }
}

/// Only an explicitly matched deployed read contract may activate this root seam.
/// This function does not deploy, change configuration or bind a review account.
WorkspacePublicDiscoverySource? configuredWorkspacePublicDiscovery({required String environment,
  required String projectId, required String? tenantId, required String accountUserId,
  required String realm, required bool Function() current}) {
  if (!const bool.fromEnvironment('MOOLSOCIAL_WORKSPACE_DISCOVERY_V1') ||
      environment != 'firebase-service' || projectId != 'moolsocial-dev-503018' || tenantId != null ||
      !{'evaluation', 'production'}.contains(realm)) { return null; }
  final endpoint = Uri.tryParse(const String.fromEnvironment('MOOLSOCIAL_WORKSPACE_URL'));
  if (endpoint == null || !_validEndpoint(endpoint)) return null;
  final gateway = AuthenticatedWorkspaceCatalogueGateway(endpoint: endpoint,
    credentials: FirebaseSocialContentCredentials(), transport: IoSocialContentTransport(), realm: realm,
    ownerAccountId: _id(accountUserId), policyReadbackRequired: true,
    productFactsReadbackSupported: true, unbrandedProduceReadbackSupported: true,
    reviewedFamilyReadbackSupported: true, storeClassificationReadbackSupported: true,
    minorMoneyReadbackSupported: const bool.fromEnvironment('MOOLSOCIAL_WORKSPACE_CATALOGUE_MONEY_V2'),
    stockSnapshotsSupported: const bool.fromEnvironment('MOOLSOCIAL_STORE_STOCK_V1'),
    promotionTermsSupported: const bool.fromEnvironment('MOOLSOCIAL_STORE_PROMOTION_TERMS_V1'),
    promotionDiscoverySupported: const bool.fromEnvironment('MOOLSOCIAL_WORKSPACE_PROMOTION_DISCOVERY_V1'));
  return WorkspacePublicDiscoverySource(gateway: gateway, current: current);
}

WorkspaceProductPresentationGateway? configuredWorkspaceProductPresentations({required String environment,
  required String projectId, required String? tenantId, required String accountUserId, required String realm,
  required bool Function() current, required WorkspaceCatalogueContentResult? Function(BuyV2Product) displayed}) {
  const productEnabled = bool.fromEnvironment('MOOLSOCIAL_PRODUCT_PRESENTATIONS_V1'),
    storeEnabled = bool.fromEnvironment('MOOLSOCIAL_STORE_PRESENTATIONS_V1'),
    cartEnabled = bool.fromEnvironment('MOOLSOCIAL_CART_ADDITIONS_V1');
  if ((!productEnabled && !storeEnabled && !cartEnabled) || environment != 'firebase-service' ||
      projectId != 'moolsocial-dev-503018' || tenantId != null || !{'evaluation', 'production'}.contains(realm)) {return null;}
  final endpoint = Uri.tryParse(const String.fromEnvironment('MOOLSOCIAL_WORKSPACE_URL'));
  if (endpoint == null || !_validEndpoint(endpoint)) return null;
  return WorkspaceProductPresentationGateway(gateway: AuthenticatedWorkspaceCatalogueGateway(endpoint: endpoint,
    credentials: FirebaseSocialContentCredentials(), transport: IoSocialContentTransport(), realm: realm, ownerAccountId: _id(accountUserId)),
    current: current, displayed: displayed, productPresentationsEnabled: productEnabled, storePresentationsEnabled: storeEnabled, cartAdditionsEnabled: cartEnabled);
}

BuyV2ProductContentSnapshot _unavailable(BuyV2Product product, {bool policyResolutionPending = false}) =>
    BuyV2ProductContentSnapshot(
      productId: product.id,
      state: BuyV2ProductContentState.unavailable,
      sourceId: 'Store catalogue',
      supplierPolicyResolutionPending: policyResolutionPending,
      customerMessage:
          'Product details could not be confirmed. Please refresh.',
      retryable: true,
    );

class UnavailableWorkspaceCatalogueGateway
    implements WorkspaceCatalogueGateway {
  const UnavailableWorkspaceCatalogueGateway();
  @override
  Future<WorkspaceCatalogueContentResult> read(BuyV2Product product) async =>
      WorkspaceCatalogueContentResult(content: _unavailable(product));
}

WorkspaceCatalogueGateway buildWorkspaceCatalogueGateway({SocialContentCredentials? credentials}) {
  final endpoint = Uri.tryParse(
    const String.fromEnvironment('MOOLSOCIAL_WORKSPACE_URL'),
  );
  if (endpoint == null || !_validEndpoint(endpoint)) {
    return const UnavailableWorkspaceCatalogueGateway();
  }
  return AuthenticatedWorkspaceCatalogueGateway(
    endpoint: endpoint,
    credentials: credentials ?? FirebaseSocialContentCredentials(),
    transport: IoSocialContentTransport(),
    policyReadbackRequired: true,
    productFactsReadbackSupported: const bool.fromEnvironment('MOOLSOCIAL_WORKSPACE_PRODUCT_FACTS_V1'),
    unbrandedProduceReadbackSupported: const bool.fromEnvironment('MOOLSOCIAL_WORKSPACE_UNBRANDED_PRODUCE_V1'),
    reviewedFamilyReadbackSupported: const bool.fromEnvironment('MOOLSOCIAL_WORKSPACE_REVIEWED_FAMILIES_V1'),
    productSubmissionSupported: const bool.fromEnvironment('MOOLSOCIAL_WORKSPACE_PRODUCT_SUBMISSIONS_V1'),
    productMediaSupported: const bool.fromEnvironment('MOOLSOCIAL_PRODUCT_MEDIA_V1'),
    reviewedProductSubmissionSupported: const bool.fromEnvironment('MOOLSOCIAL_WORKSPACE_PRODUCT_REVIEW_V1'),
    reviewedProductMediaSupported: const bool.fromEnvironment('MOOLSOCIAL_WORKSPACE_PRODUCT_MEDIA_REVIEW_V1'),
    stockSnapshotsSupported: const bool.fromEnvironment('MOOLSOCIAL_STORE_STOCK_V1'),
    promotionTermsSupported: const bool.fromEnvironment('MOOLSOCIAL_STORE_PROMOTION_TERMS_V1'),
    storeClassificationReadbackSupported: const bool.fromEnvironment('MOOLSOCIAL_WORKSPACE_STORE_CLASSIFICATION_V1'),
    minorMoneyReadbackSupported: const bool.fromEnvironment('MOOLSOCIAL_WORKSPACE_CATALOGUE_MONEY_V2'),
  );
}

bool _validEndpoint(Uri value) =>
    value.scheme == 'https' &&
    value.host == 'asia-south1-moolsocial-dev-503018.cloudfunctions.net' &&
    value.path == '/moolSocialWorkspace' &&
    !value.hasQuery &&
    !value.hasFragment &&
    value.userInfo.isEmpty &&
    !value.hasPort;

class AuthenticatedWorkspaceCatalogueGateway
    implements WorkspaceCatalogueGateway, WorkspaceCatalogueOwnerGateway, WorkspacePublicProductGateway,
      WorkspacePublicDetailsOwnerGateway, WorkspaceVariantFamilyOwnerGateway, WorkspaceProductSubmissionOwnerGateway,
      WorkspaceReviewedProductSubmissionGateway, WorkspaceProductMediaGateway, WorkspaceStoreStockOwnerGateway, WorkspaceStoreStockPublicGateway {
  AuthenticatedWorkspaceCatalogueGateway({
    required this.endpoint,
    required this.credentials,
    required this.transport,
    this.realm = 'production',
    this.ownerAccountId,
    this.policyReadbackRequired = false,
    this.productFactsReadbackSupported = false,
    this.unbrandedProduceReadbackSupported = false,
    WorkspacePublicVariantSource? reviewedVariants,
    this.reviewedFamilyReadbackSupported = false,
    this.productSubmissionSupported = false,
    this.productMediaSupported = false,
    WorkspaceProductMediaUploadTransport? productMediaTransport,
    this.reviewedProductSubmissionSupported = false,
    this.reviewedProductMediaSupported = false,
    this.storeClassificationReadbackSupported = false,
    this.minorMoneyReadbackSupported = false,
    this.promotionDiscoverySupported = false,
    this.promotionTermsSupported = false,
    this.stockSnapshotsSupported = false,
    DateTime Function()? now,
  }) : _reviewedVariantsOverride = reviewedVariants, _productMediaTransportOverride = productMediaTransport, now = now ?? DateTime.now {
    if (!_validEndpoint(endpoint) ||
        !{'production', 'evaluation'}.contains(realm)) {
      throw ArgumentError('Invalid catalogue connection.');
    }
  }
  final Uri endpoint;
  final SocialContentCredentials credentials;
  final SocialContentTransport transport;
  @override
  final String realm;
  final String? ownerAccountId;
  final bool policyReadbackRequired;
  // Enable only with the matching service contract; do not break strict legacy endpoints.
  final bool productFactsReadbackSupported;
  // Negotiated only with a matching service; legacy strict endpoints reject new keys.
  final bool unbrandedProduceReadbackSupported;
  final bool reviewedFamilyReadbackSupported;
  @override
  final bool productSubmissionSupported;
  @override
  final bool productMediaSupported;
  final WorkspaceProductMediaUploadTransport? _productMediaTransportOverride;
  late final WorkspaceProductMediaUploadTransport _productMediaTransport = _productMediaTransportOverride ?? IoWorkspaceProductMediaUploadTransport();
  @override
  final bool reviewedProductSubmissionSupported;
  final bool reviewedProductMediaSupported;
  @override
  DateTime get productReviewNow => now().toUtc();
  final bool storeClassificationReadbackSupported;
  // Opt-in only for the matching integer-paise paged contract; legacy stays v1.
  final bool minorMoneyReadbackSupported;
  final bool promotionDiscoverySupported;
  final bool promotionTermsSupported;
  @override
  final bool stockSnapshotsSupported;
  @override
  bool get variantFamilySubmissionSupported => reviewedFamilyReadbackSupported;
  final WorkspacePublicVariantSource? _reviewedVariantsOverride;
  late final WorkspacePublicVariantSource? reviewedVariants = _reviewedVariantsOverride ??
      (reviewedFamilyReadbackSupported ? WorkspaceHttpReviewedVariantSource(this) : null);
  final Map<String, WorkspaceReviewedVariantMembership> _variantMemberships = {};
  final Map<String, String> _variantInputs = {};
  bool _policyObserved = false;
  bool get policyResolutionRequired => policyReadbackRequired || _policyObserved;
  final DateTime Function() now;

  /// Caller must pin the actual authenticated account/lifetime, not a contact label.
  AuthenticatedWorkspaceCatalogueGateway forOwnerAccount(String accountId) {
    _id(accountId);
    return AuthenticatedWorkspaceCatalogueGateway(
      endpoint: endpoint,
      credentials: credentials,
      transport: transport,
      realm: realm,
      ownerAccountId: accountId,
      policyReadbackRequired: policyReadbackRequired,
      productFactsReadbackSupported: productFactsReadbackSupported,
      unbrandedProduceReadbackSupported: unbrandedProduceReadbackSupported,
      reviewedVariants: _reviewedVariantsOverride,
      reviewedFamilyReadbackSupported: reviewedFamilyReadbackSupported,
      productSubmissionSupported: productSubmissionSupported,
      productMediaSupported: productMediaSupported,
      productMediaTransport: _productMediaTransportOverride,
      reviewedProductSubmissionSupported: reviewedProductSubmissionSupported,
      reviewedProductMediaSupported: reviewedProductMediaSupported,
      storeClassificationReadbackSupported: storeClassificationReadbackSupported,
      minorMoneyReadbackSupported: minorMoneyReadbackSupported,
      promotionDiscoverySupported: promotionDiscoverySupported,
      promotionTermsSupported: promotionTermsSupported,
      stockSnapshotsSupported: stockSnapshotsSupported,
      now: now,
    );
  }

  bool _productSubmissionOwner(WorkspaceProductSubmissionScope scope, bool Function() current) => current() &&
    productSubmissionSupported && scope.realm == realm && ownerAccountId == scope.account;

  bool _stockOwner(WorkspaceStoreStockScope scope, bool Function() current) => current() && stockSnapshotsSupported &&
    scope.realm == realm && ownerAccountId == scope.account;
  @override
  Future<WorkspacePublicStockResult> readPublicStoreStock(WorkspacePublicStockQuery query, {required bool Function() current}) async {
    bool valid() => current() && stockSnapshotsSupported && query.realm == realm;
    if (!valid()) throw const FormatException('Stock information is unavailable.');
    final response = await _ownerRequest({'operation': 'readPublicStoreStockSnapshot', ...query.body}, valid, mutation: false);
    if (!valid() || response?.statusCode != 200) throw const FormatException();
    final envelope = _map(jsonDecode(response!.body)); _keys(envelope, ['ok', 'data']);
    if (envelope['ok'] != true) throw const FormatException();
    return WorkspacePublicStockResult.decode(envelope['data'], query, now());
  }
  @override
  Future<WorkspaceStoreStockHead> readStoreStockHead(WorkspaceStoreStockScope scope, Map<String, dynamic> binding,
      {required bool Function() current}) async {
    _stockScope(scope); final frozen = _stockBinding(binding);
    if (!_stockOwner(scope, current) || frozen['skuId'] != scope.sku) throw const FormatException('Stock connection is unavailable.');
    final response = await _ownerRequest({'operation': 'readStoreStockSnapshot', 'stockSnapshotVersion': 1,
      'storeId': scope.store, 'binding': frozen}, () => _stockOwner(scope, current), mutation: false);
    if (!_stockOwner(scope, current) || response?.statusCode != 200) throw const FormatException();
    final envelope = _map(jsonDecode(response!.body)); _keys(envelope, ['ok', 'data']);
    if (envelope['ok'] != true) throw const FormatException();
    return WorkspaceStoreStockHead.decode(envelope['data'], scope, frozen, now());
  }
  @override
  Future<WorkspaceStoreStockWriteResult> writeStoreStock(WorkspaceStoreStockIntent original,
      {required bool Function() current, bool reconcile = false}) async {
    var dispatched = false;
    try {
      original = WorkspaceStoreStockIntent.fromJson(original.toJson());
      bool valid() => _stockOwner(original.scope, current);
      if (!valid()) return const WorkspaceStoreStockWriteResult(WorkspaceStoreStockWriteState.notSent);
      final response = await _ownerRequest({'operation': reconcile ? 'reconcileStoreStockSnapshot' : 'publishStoreStockSnapshot', ...original.body},
        valid, mutation: !reconcile, onDispatch: () => dispatched = true);
      if (!valid() || response?.statusCode != 200) throw const FormatException();
      final envelope = _map(jsonDecode(response!.body)); _keys(envelope, ['ok', 'data']);
      if (envelope['ok'] != true) throw const FormatException();
      final head = WorkspaceStoreStockHead.decode(envelope['data'], original.scope, original.input.binding, now(),
        original: original, reconcile: reconcile);
      return WorkspaceStoreStockWriteResult(switch (head.state) {
        'reported' => WorkspaceStoreStockWriteState.reported,
        'expired' => WorkspaceStoreStockWriteState.expired,
        'not_found' => WorkspaceStoreStockWriteState.notFound,
        _ => WorkspaceStoreStockWriteState.unknown,
      }, head.record);
    } catch (_) {
      return WorkspaceStoreStockWriteResult(dispatched ? WorkspaceStoreStockWriteState.unknown : WorkspaceStoreStockWriteState.notSent);
    }
  }
  Future<WorkspaceProductMediaResult> _mediaRequest(WorkspaceProductMediaIntent original, String operation,
      bool Function() current, {bool grant = false}) async {
    if (!productMediaSupported || !_productSubmissionOwner(original.scope, current)) throw const FormatException();
    final response = await _ownerRequest({'operation': operation, 'productMediaVersion': 1, ...original.body},
      () => productMediaSupported && _productSubmissionOwner(original.scope, current), mutation: operation != 'readStoreProductMedia');
    if (!_productSubmissionOwner(original.scope, current) || response?.statusCode != 200) throw const FormatException('Photo processing is unconfirmed. Keep the original request.');
    final value = _map(jsonDecode(response!.body)); _keys(value, ['ok', 'data']);
    if (value['ok'] != true) throw const FormatException();
    return WorkspaceProductMediaResult.decode(value['data'], original, now().toUtc(), grantAllowed: grant);
  }
  @override
  Future<WorkspaceProductMediaResult> readProductMedia(WorkspaceProductMediaIntent original,
      {required bool Function() current, bool confirm = false}) =>
    _mediaRequest(original, confirm ? 'confirmStoreProductMedia' : 'readStoreProductMedia', current);
  @override
  Future<WorkspaceProductMediaResult> uploadProductMedia(WorkspaceProductMediaIntent original,
      {required Future<Uint8List> Function() readBytes, required bool Function() current}) async {
    final existing = await readProductMedia(original, current: current);
    if (existing.processed) return existing;
    if (existing.state != 'not_found') {
      try {
        final confirmed = await readProductMedia(original, current: current, confirm: true);
        if (confirmed.processed) return confirmed;
      } catch (_) {if (!current()) rethrow;}
      if (!existing.current) return existing; // Keep historical recovery distinct from the current photo.
    }
    final bytes = Uint8List.fromList(await readBytes());
    if (!current() || bytes.length != original.sourceByteLength ||
      crypto.sha256.convert(bytes).toString() != original.sourceSha256) {throw const FormatException('Saved photo changed. The original request is kept.');}
    final grant = await _mediaRequest(original, 'prepareStoreProductMedia', current, grant: true);
    if (grant.processed) return grant;
    if (!current() || grant.uploadUrl == null) throw const FormatException();
    // No bearer/AppCheck tokens go to storage; only strictly validated signed headers and frozen bytes.
    try {
      final status = await _productMediaTransport.put(grant.uploadUrl!, grant.requiredHeaders, bytes, current: current);
      if (!current() || !(status >= 200 && status < 300 || status == 412)) throw const FormatException();
    } catch (_) {
      if (!current()) rethrow;
      // A lost PUT reply is not a failed upload. Confirm the same original, never allocate a new key.
      return readProductMedia(original, current: current, confirm: true);
    }
    return readProductMedia(original, current: current, confirm: true);
  }
  WorkspaceProductSubmissionRecord? _productSubmissionResponse(Object? raw, WorkspaceProductSubmissionScope scope,
      {required String? key, required bool reconcile}) {
    final value = _map(raw);
    _keys(value, ['schemaVersion', 'productSubmissionVersion', 'realm', 'storeId', 'skuId', 'observedAt', 'idempotencyKey',
      'state', 'approved', 'publicationConfirmed', 'orderingAvailable', 'record']);
    final observed = _time(value['observedAt']);
    if (value['schemaVersion'] is! int || value['schemaVersion'] != 1 || value['productSubmissionVersion'] is! int || value['productSubmissionVersion'] != 1 ||
        value['realm'] != scope.realm || value['storeId'] != scope.store || value['skuId'] != scope.sku || value['idempotencyKey'] != key ||
        value['approved'] != false || value['publicationConfirmed'] != false || value['orderingAvailable'] != false ||
        observed.isAfter(now().toUtc()) || observed.toIso8601String() != value['observedAt']) { throw const FormatException(); }
    if (value['record'] == null) {
      if (value['state'] != (reconcile ? 'not_found' : 'none')) throw const FormatException();
      return null;
    }
    final record = WorkspaceProductSubmissionRecord.decode(value['record'], scope, observed);
    if (value['state'] != (record.input.mediaPending ? 'awaiting_media' : 'submitted')) throw const FormatException();
    return record;
  }
  @override
  Future<WorkspaceProductSubmissionRecord?> readProductSubmission(WorkspaceProductSubmissionScope scope, {required bool Function() current}) async {
    if (!_productSubmissionOwner(scope, current)) throw const FormatException('Product review is not connected.');
    final response = await _ownerRequest({'operation': 'readStoreProductSubmission', 'productSubmissionVersion': 1,
      'storeId': scope.store, 'skuId': scope.sku}, current, mutation: false);
    if (!_productSubmissionOwner(scope, current) || response?.statusCode != 200) throw const FormatException();
    final envelope = _map(jsonDecode(response!.body));
    if (envelope['ok'] != true) throw const FormatException();
    return _productSubmissionResponse(envelope['data'], scope, key: null, reconcile: false);
  }
  @override
  Future<WorkspaceProductReviewReadback> readReviewedProductSubmission(WorkspaceProductSubmissionScope scope,
      {required bool Function() current}) async {
    if (!reviewedProductSubmissionSupported || !_productSubmissionOwner(scope, current)) throw const FormatException('Product review is not connected.');
    final response = await _ownerRequest({'operation': 'readStoreProductSubmission', 'productSubmissionVersion': 1,
      'productReviewVersion': 1, if (reviewedProductMediaSupported) 'productMediaReviewVersion': 1, 'storeId': scope.store, 'skuId': scope.sku}, current, mutation: false);
    if (!_productSubmissionOwner(scope, current) || response?.statusCode != 200) throw const FormatException();
    final envelope = _map(jsonDecode(response!.body)); _keys(envelope, ['ok', 'data']);
    if (envelope['ok'] != true) throw const FormatException();
    final value = _map(envelope['data']);
    if (_int(value['productReviewVersion'], 1, 1) != 1) throw const FormatException();
    if (reviewedProductMediaSupported && _int(value['productMediaReviewVersion'], 1, 1) != 1 || !reviewedProductMediaSupported && value.containsKey('productMediaReviewVersion')) throw const FormatException();
    final legacy = Map<String, dynamic>.of(value)..remove('productReviewVersion')..remove('review')..remove('productMediaReviewVersion');
    final record = _productSubmissionResponse(legacy, scope, key: null, reconcile: false);
    final readback = WorkspaceProductReviewReadback.decodeReview(value['review'], record, scope, _time(value['observedAt']), allowMedia: reviewedProductMediaSupported);
    if (readback.state == 'ready' && !readback.candidate!.expiresAt.isAfter(now().toUtc())) throw const FormatException();
    return readback;
  }
  @override
  Future<WorkspaceProductSubmissionWriteResult> writeProductSubmission(WorkspaceProductSubmissionIntent original,
      {required bool Function() current, bool reconcile = false}) async {
    var dispatched = false;
    if (!_productSubmissionOwner(original.scope, current)) return const WorkspaceProductSubmissionWriteResult(WorkspaceProductSubmissionWriteState.notSent);
    try {
      original = WorkspaceProductSubmissionIntent.fromJson(original.toJson());
      final response = await _ownerRequest({'operation': reconcile ? 'reconcileStoreProductSubmission' : 'submitStoreProduct',
        'productSubmissionVersion': 1, ...original.body}, () => _productSubmissionOwner(original.scope, current), mutation: !reconcile,
        onDispatch: () => dispatched = true);
      if (!_productSubmissionOwner(original.scope, current) || response == null) {
        return WorkspaceProductSubmissionWriteResult(dispatched ? WorkspaceProductSubmissionWriteState.unknown : WorkspaceProductSubmissionWriteState.notSent);
      }
      if (response.statusCode != 200) { return WorkspaceProductSubmissionWriteResult(!reconcile && _definitiveDetailsRejection(response)
        ? WorkspaceProductSubmissionWriteState.rejected : WorkspaceProductSubmissionWriteState.unknown); }
      final envelope = _map(jsonDecode(response.body));
      if (envelope['ok'] != true) throw const FormatException();
      final record = _productSubmissionResponse(envelope['data'], original.scope, key: original.idempotencyKey, reconcile: reconcile);
      if (record == null) {
        if (!reconcile) throw const FormatException();
        return const WorkspaceProductSubmissionWriteResult(WorkspaceProductSubmissionWriteState.notFound);
      }
      if (!record.matches(original)) throw const FormatException();
      return WorkspaceProductSubmissionWriteResult(WorkspaceProductSubmissionWriteState.submitted, record);
    } catch (_) {
      return WorkspaceProductSubmissionWriteResult(dispatched ? WorkspaceProductSubmissionWriteState.unknown : WorkspaceProductSubmissionWriteState.notSent);
    }
  }

  bool _familyOwner(WorkspaceVariantFamilyScope scope, bool Function() current) => current() &&
    variantFamilySubmissionSupported && scope.realm == realm && ownerAccountId == scope.account;
  @override
  Future<WorkspaceVariantFamilyHead> readVariantFamily(WorkspaceVariantFamilyScope scope,
      {required bool Function() current}) async {
    if (!_familyOwner(scope, current)) throw const FormatException('Group submission is not connected.');
    final response = await _ownerRequest({'operation': 'readStoreVariantFamily',
      'storeId': _id(scope.store), 'familyId': _id(scope.family)}, current, mutation: false);
    if (!_familyOwner(scope, current) || response?.statusCode != 200) throw const FormatException();
    final envelope = _map(jsonDecode(response!.body));
    if (envelope['ok'] != true) throw const FormatException();
    return WorkspaceVariantFamilyHead.decode(envelope['data'], scope, now().toUtc());
  }
  @override
  Future<WorkspaceVariantFamilyWriteResult> writeVariantFamily(WorkspaceVariantFamilyIntent original,
      {required bool Function() current, bool reconcile = false}) async {
    if (!_familyOwner(original.scope, current)) return const WorkspaceVariantFamilyWriteResult(WorkspaceVariantFamilyWriteState.notSent);
    var dispatching = false;
    try {
      original = WorkspaceVariantFamilyIntent.fromJson(original.toJson());
      if (!_familyOwner(original.scope, current)) return const WorkspaceVariantFamilyWriteResult(WorkspaceVariantFamilyWriteState.notSent);
      dispatching = true;
      final response = await _ownerRequest({'operation': reconcile ? 'reconcileStoreVariantFamily' : 'submitStoreVariantFamily',
        ...original.body}, current, mutation: !reconcile);
      if (!_familyOwner(original.scope, current) || response == null) return const WorkspaceVariantFamilyWriteResult(WorkspaceVariantFamilyWriteState.unknown);
      if (response.statusCode != 200) {
        return WorkspaceVariantFamilyWriteResult(!reconcile && _definitiveDetailsRejection(response)
          ? WorkspaceVariantFamilyWriteState.rejected : WorkspaceVariantFamilyWriteState.unknown);
      }
      final envelope = _map(jsonDecode(response.body));
      if (envelope['ok'] != true) throw const FormatException();
      final data = _map(envelope['data']);
      _keys(data, ['schemaVersion', 'realm', 'storeId', 'familyId', 'orderingAvailable', 'state', 'candidate', 'approved']);
      if (data['schemaVersion'] is! int || data['schemaVersion'] != 1 || data['realm'] != realm ||
          data['storeId'] != original.scope.store || data['familyId'] != original.scope.family ||
          data['orderingAvailable'] != false || data['approved'] != false) { throw const FormatException(); }
      if (reconcile && data['state'] == 'not_found' && data['candidate'] == null) {
        return const WorkspaceVariantFamilyWriteResult(WorkspaceVariantFamilyWriteState.notFound);
      }
      if (data['state'] != 'submitted') throw const FormatException();
      final candidate = WorkspaceVariantFamilyCandidate.decode(data['candidate'], original.scope, now().toUtc());
      if (!candidate.matches(original)) throw const FormatException();
      return WorkspaceVariantFamilyWriteResult(WorkspaceVariantFamilyWriteState.submitted, candidate);
    } catch (_) {
      return WorkspaceVariantFamilyWriteResult(dispatching ? WorkspaceVariantFamilyWriteState.unknown : WorkspaceVariantFamilyWriteState.notSent);
    }
  }

  Future<List<WorkspacePublicCatalogueEntry>> _enrichVariants(
      List<WorkspacePublicCatalogueEntry> entries, bool Function() current) async {
    if (!current()) throw const FormatException();
    final source = reviewedVariants;
    if (source == null || entries.isEmpty) return entries;
    final records = await source.readMemberships(List.unmodifiable(entries), current: current)
      .timeout(const Duration(seconds: 15));
    if (!current() || records.length != entries.length) throw const FormatException();
    final byId = <String, WorkspaceReviewedVariantMembership>{};
    for (final record in records) {
      if (byId.containsKey(record.listing.listingId)) throw const FormatException();
      byId[record.listing.listingId] = record;
    }
    final enriched = <WorkspacePublicCatalogueEntry>[];
    for (final entry in entries) {
      final record = byId[entry.product.id], previous = _variantMemberships[entry.product.id];
      if (record == null || !record.validFor(entry, realm, now().toUtc()) || previous != null &&
          (record.revision < previous.revision || record.observedAt.isBefore(previous.observedAt) ||
            record.skuRevision < previous.skuRevision || record.catalogueVersion < previous.catalogueVersion ||
            record.sourceId != previous.sourceId ||
            record.revision == previous.revision && record.fingerprint != previous.fingerprint)) {
        throw const FormatException('Product options could not be confirmed.');
      }
      enriched.add(WorkspacePublicCatalogueEntry(product: entry.product.copyWith(
        variantFamilyId: record.familyId, variantAttributes: record.attributes), readback: entry.readback));
    }
    if (!current()) throw const FormatException();
    // Validate the entire batch before admitting any association/high-water mark.
    final inputs = <String, String>{};
    for (final entry in enriched) {
      final input = WorkspaceCatalogueReadback._input(entry.product);
      if (input == null) throw const FormatException();
      inputs[entry.product.id] = input;
    }
    _variantMemberships.addAll(byId);
    _variantInputs.addAll(inputs);
    return List.unmodifiable(enriched);
  }

  Future<BuyV2VariantFamilySnapshot> _readReviewedFamily(BuyV2Product selected,
      BuyV2CatalogueQuery query, bool Function() current,
      Future<List<BuyV2Product>> Function(Set<String>) resolvePublished) async {
    final source = reviewedVariants, member = _variantMemberships[selected.id];
    bool active() {
      final latest = _variantMemberships[selected.id];
      return current() && latest != null && member != null && latest.revision == member.revision &&
        latest.sourceId == member.sourceId && latest.fingerprint == member.fingerprint &&
        latest.skuRevision == member.skuRevision && latest.catalogueVersion == member.catalogueVersion &&
        now().toUtc().isBefore(latest.validUntil) &&
        _variantInputs[selected.id] == WorkspaceCatalogueReadback._input(selected);
    }
    if (source == null || member == null || !active() || member.familyId == null ||
        member.familyId != selected.variantFamilyId || !member.listing.matches(selected) ||
        member.listing.realm != realm || !now().toUtc().isBefore(member.validUntil)) {
      throw const FormatException('Product options are not connected.');
    }
    final snapshot = await source.readFamily(selected, query, current: active).timeout(const Duration(seconds: 15));
    if (!active() || !snapshot.isValidFor(selected, query, now().toUtc()) ||
        snapshot.candidates.length > 500 ||
        snapshot.revision != '${member.revision}' || snapshot.sourceId != member.sourceId ||
        snapshot.observedAt.isBefore(member.observedAt) || snapshot.validUntil.isAfter(member.validUntil) ||
        snapshot.candidates.any((p) => p.publicListingIdentity?.valid != true ||
          p.publicListingIdentity?.realm != realm || !p.publicListingIdentity!.matches(p) ||
          !p.hasValidPackTerms || p.packTerms == null || !p.packTerms!.pricingCurrentAt(now().toUtc()) ||
          p.id == selected.id && WorkspaceCatalogueReadback._input(p) != _variantInputs[selected.id] ||
          p.variantAttributes.any((a) => !snapshot.options.any((o) =>
            a.dimensionId == o.dimensionId && a.dimensionLabel == o.dimensionLabel &&
            a.optionId == o.optionId && a.optionLabel == o.optionLabel && a.kind == o.kind && a.swatchArgb == o.swatchArgb)))) {
      throw const FormatException('Product options changed. Please refresh.');
    }
    final candidates = <BuyV2Product>[];
    final candidateMemberships = <String, WorkspaceReviewedVariantMembership>{};
    // Existing exact-listing resolution supplies each candidate's real public
    // product and association. A family/discovery hint cannot mint a sibling.
    for (var start = 0; start < snapshot.candidates.length; start += 50) {
      if (!active()) throw const FormatException();
      final end = min(start + 50, snapshot.candidates.length);
      final expected = {for (final p in snapshot.candidates.sublist(start, end)) p.id: p};
      final resolved = await resolvePublished(expected.keys.toSet());
      if (!active() || resolved.length != expected.length ||
          resolved.map((p) => p.id).toSet().length != resolved.length || resolved.any((p) {
            final original = expected[p.id], association = _variantMemberships[p.id];
            return original == null || association == null || association.familyId != member.familyId ||
              association.revision != member.revision || association.sourceId != member.sourceId ||
              WorkspaceCatalogueReadback._input(original) != WorkspaceCatalogueReadback._input(p);
          })) { throw const FormatException('A product option needs refreshing.'); }
      candidates.addAll(resolved);
      for (final product in resolved) {
        candidateMemberships[product.id] = _variantMemberships[product.id]!;
      }
    }
    final confirmed = BuyV2VariantFamilySnapshot(productId: snapshot.productId, canonicalId: snapshot.canonicalId,
      variantFamilyId: snapshot.variantFamilyId, categoryId: snapshot.categoryId, offerClass: snapshot.offerClass,
      realm: snapshot.realm, storeId: snapshot.storeId, destination: snapshot.destination, queryKey: snapshot.queryKey,
      sourceId: snapshot.sourceId, revision: snapshot.revision, observedAt: snapshot.observedAt,
      validUntil: snapshot.validUntil, complete: snapshot.complete, selectedAvailable: snapshot.selectedAvailable,
      options: snapshot.options, candidates: candidates);
    // A later batch can await while another read advances an earlier sibling.
    // Revalidate the entire completed result without any intervening await.
    final completedAt = now().toUtc();
    if (!active() || !confirmed.isValidFor(selected, query, completedAt) || candidates.any((product) {
      final original = candidateMemberships[product.id], latest = _variantMemberships[product.id];
      return original == null || latest == null || latest.revision != original.revision ||
        latest.skuRevision != original.skuRevision || latest.catalogueVersion != original.catalogueVersion ||
        latest.fingerprint != original.fingerprint || !completedAt.isBefore(latest.validUntil) ||
        _variantInputs[product.id] != WorkspaceCatalogueReadback._input(product);
    })) { throw const FormatException(); }
    return confirmed;
  }

  @override
  Future<WorkspaceCatalogueOwnedSku?> readOwnedSku({
    required String storeId,
    required String skuId,
    required bool Function() current,
  }) async {
    try {
      if (ownerAccountId == null) return null;
      _id(storeId);
      _id(skuId);
      final response = await _ownerRequest(
        {
          'operation': 'listStoreCatalogueSkus',
          'mediaReadbackVersion': 1,
          if (productFactsReadbackSupported) 'productFactsReadbackVersion': 1,
          'storeId': storeId,
          'skuId': skuId,
        },
        current,
        mutation: false,
      );
      if (response == null || !current() || response.statusCode != 200) {
        return null;
      }
      final envelope = _map(jsonDecode(response.body));
      if (envelope['ok'] != true) {
        return null;
      }
      final data = _map(envelope['data']);
      _keys(Map<String, dynamic>.of(data)..remove('mediaReadbackVersion')..remove('productFactsReadbackVersion')
        ..remove('unbrandedProduceReadbackVersion'), ['schemaVersion', 'realm', 'storeId', 'items', 'nextCursor']);
      if (data.containsKey('mediaReadbackVersion') && data['mediaReadbackVersion'] != 1) throw const FormatException();
      _checkProductFactsReadbackVersion(data);
      _checkProduceReadback(data, supported: unbrandedProduceReadbackSupported);
      if (data['schemaVersion'] != 1 ||
          data['realm'] != realm ||
          data['storeId'] != storeId ||
          data['nextCursor'] != null) {
        return null;
      }
      final items = _list(data['items'], 1);
      if (items.length != 1) {
        return null; // Empty is missing, not an invented binding.
      }
      final owned = WorkspaceCatalogueOwnedSku.decode(
        items.single,
        storeId: storeId,
        skuId: skuId,
        now: now(),
        realm: realm,
      );
      final content = _map(owned.input['content']);
      _catalogueBrand(content, readback: data);
      if (content.containsKey('productFacts') && data['productFactsReadbackVersion'] != 1) return null;
      if (_list(content['media'], 10).any((raw) => _map(_map(raw)['file']).containsKey('frameCount')) &&
          data['mediaReadbackVersion'] != 1) { return null; }
      return owned;
    } on Object {
      return null;
    }
  }

  @override
  Future<WorkspaceCatalogueBindingResult> bindReviewed(
    WorkspaceCatalogueBindingIntent original, {
    required bool Function() current,
    required bool recoveringUnknown,
  }) => _bindingRequest(
    original,
    current: current,
    recoveringUnknown: recoveringUnknown,
    reconciliation: false,
  );

  @override
  Future<WorkspaceCatalogueBindingResult> reconcileBinding(
    WorkspaceCatalogueBindingIntent original, {
    required bool Function() current,
  }) => _bindingRequest(
    original,
    current: current,
    recoveringUnknown: true,
    reconciliation: true,
  );

  Future<WorkspaceCatalogueBindingResult> _bindingRequest(
    WorkspaceCatalogueBindingIntent original, {
    required bool Function() current,
    required bool recoveringUnknown,
    required bool reconciliation,
  }) async {
    var sent = false;
    try {
      // Do not start a new binding that this connection cannot read back.
      // An original uncertain attempt must still use its existing reconciliation.
      if (!reconciliation && !recoveringUnknown && !unbrandedProduceReadbackSupported &&
          _map(original.sku['content'])['brand'] == '') {
        return const WorkspaceCatalogueBindingResult(WorkspaceCatalogueBindingState.notSent);
      }
      if (ownerAccountId == null ||
          original.accountId != ownerAccountId ||
          original.realm != realm) {
        return WorkspaceCatalogueBindingResult(
          recoveringUnknown
              ? WorkspaceCatalogueBindingState.unknown
              : WorkspaceCatalogueBindingState.notSent,
        );
      }
      final response = await _ownerRequest(
        {
          'operation': reconciliation
              ? 'reconcileStoreCatalogueBinding'
              : 'bindReviewedStoreCatalogueSku',
          ...original.body,
        },
        current,
        mutation: !reconciliation,
        onDispatch: () => sent = true,
      );
      if (response == null || !current()) {
        return WorkspaceCatalogueBindingResult(
          sent || recoveringUnknown
              ? WorkspaceCatalogueBindingState.unknown
              : WorkspaceCatalogueBindingState.notSent,
        );
      }
      final envelope = _map(jsonDecode(response.body));
      if (response.statusCode != 200 || envelope['ok'] != true) {
        final error = envelope['error'];
        final definitive =
            !recoveringUnknown &&
            error is Map &&
            const {
              'invalid_input',
              'forbidden',
              'not_found',
              'conflict',
              'authentication_required',
              'invalid_tenant',
            }.contains(error['code']) &&
            const {400, 401, 403, 404, 409}.contains(response.statusCode);
        return WorkspaceCatalogueBindingResult(
          definitive
              ? WorkspaceCatalogueBindingState.rejected
              : WorkspaceCatalogueBindingState.unknown,
        );
      }
      final data = _map(envelope['data']);
      _keys(data, [
        'schemaVersion',
        'realm',
        'storeId',
        'saved',
        'publicationConfirmed',
      ]);
      if (data['schemaVersion'] != 1 ||
          data['realm'] != realm ||
          data['storeId'] != original.storeId ||
          data['publicationConfirmed'] != false) {
        throw const FormatException();
      }
      if (data['saved'] == null) {
        return const WorkspaceCatalogueBindingResult(
          WorkspaceCatalogueBindingState.unknown,
        );
      }
      final saved = WorkspaceCatalogueOwnedSku.decode(
        data['saved'],
        storeId: original.storeId,
        skuId: original.skuId,
        now: now(),
        realm: realm,
      );
      if (saved.revision != original.expectedRevision + 1 ||
          jsonEncode(_sorted(saved.input)) !=
              jsonEncode(_sorted(original.sku))) {
        throw const FormatException();
      }
      return WorkspaceCatalogueBindingResult(
        WorkspaceCatalogueBindingState.saved,
        saved: saved,
      );
    } on Object {
      return WorkspaceCatalogueBindingResult(
        sent || recoveringUnknown
            ? WorkspaceCatalogueBindingState.unknown
            : WorkspaceCatalogueBindingState.notSent,
      );
    }
  }

  Future<SocialContentResponse?> _ownerRequest(
    Map<String, Object?> body,
    bool Function() current, {
    required bool mutation,
    void Function()? onDispatch,
  }) async {
    if (!current()) return null;
    final token = await credentials.firebaseIdToken();
    if (!current()) return null;
    final appCheck = await credentials.appCheckToken(
      mutation
          ? SocialAppCheckTokenMode.limitedUse
          : SocialAppCheckTokenMode.standard,
    );
    if (!current()) return null;
    onDispatch?.call();
    return transport
        .postJson(
          endpoint,
          headers: {
            'accept': 'application/json',
            'authorization': 'Bearer $token',
            'x-firebase-appcheck': appCheck,
            'x-request-id': List.generate(
              16,
              (_) => Random.secure()
                  .nextInt(256)
                  .toRadixString(16)
                  .padLeft(2, '0'),
            ).join(),
          },
          body: {
            ...body,
            if (unbrandedProduceReadbackSupported &&
                {'listStoreCatalogueSkus', 'readPublicStoreCatalogue'}.contains(body['operation']))
              'unbrandedProduceReadbackVersion': 1,
          },
        )
        .timeout(const Duration(seconds: 20));
  }

  @override
  Future<WorkspaceCatalogueContentResult> read(BuyV2Product product) async {
    final policyRequired = policyResolutionRequired || product.publicListingIdentity != null;
    try {
      if (product.brand.isEmpty && !unbrandedProduceReadbackSupported) throw const FormatException();
      if (!productFactsReadbackSupported && !WorkspaceCatalogueProductFacts.fromProduct(product).isEmpty) {
        throw const FormatException();
      }
      if (!product.hasValidPublicListingIdentity ||
          product.publicListingIdentity != null && product.publicListingIdentity!.realm != realm) {
        throw const FormatException();
      }
      _id(product.storeId);
      _id(product.id);
      final response = await transport
          .postJson(
            endpoint,
            headers: {
              'accept': 'application/json',
              'authorization': 'Bearer ${await credentials.firebaseIdToken()}',
              'x-firebase-appcheck': await credentials.appCheckToken(
                SocialAppCheckTokenMode.standard,
              ),
              'x-request-id': List.generate(
                16,
                (_) => Random.secure()
                    .nextInt(256)
                    .toRadixString(16)
                    .padLeft(2, '0'),
              ).join(),
            },
            body: {
              'operation': 'readPublicStoreCatalogue',
              'mediaReadbackVersion': 1,
              if (productFactsReadbackSupported) 'productFactsReadbackVersion': 1,
              if (unbrandedProduceReadbackSupported) 'unbrandedProduceReadbackVersion': 1,
              if (policyRequired) 'policyReadbackVersion': 1,
              if (product.publicListingIdentity != null) 'listingReadbackVersion': 1,
              if (storeClassificationReadbackSupported && product.publicListingIdentity != null) ...{
                'storeDetailsReadbackVersion': 1, 'storeClassificationReadbackVersion': 1,
              },
              'storeId': product.storeId,
              'skuId': product.sourceSkuId,
            },
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) throw const FormatException();
      final envelope = _map(jsonDecode(response.body));
      if (envelope['ok'] != true) throw const FormatException();
      final data = _map(envelope['data']);
      _checkProduceReadback(data, supported: unbrandedProduceReadbackSupported);
      _checkStoreClassificationReadback(data, supported: storeClassificationReadbackSupported);
      if (storeClassificationReadbackSupported && product.publicListingIdentity != null &&
          data['storeClassificationReadbackVersion'] != 1) { throw const FormatException(); }
      final items = data['items'];
      if (items is List && items.any((item) => item is Map && item.containsKey('supplierPolicy'))) {
        _policyObserved = true;
      }
      return _decode(data, product, realm, now().toUtc(), policyRequired: policyRequired || policyResolutionRequired);
    } catch (_) {
      // Never expose provider diagnostics, retain a stale result, or fake success.
      return WorkspaceCatalogueContentResult(content: _unavailable(product,
        policyResolutionPending: policyRequired || policyResolutionRequired));
    }
  }

  @override
  Future<WorkspacePublicCatalogueEntry?> readPublicEntry({
    required String storeId, required String skuId, required BuyV2OfferClass channel,
    required bool Function() current,
  }) async {
    try {
      _id(storeId); _id(skuId);
      final response = await _ownerRequest({
        'operation': 'readPublicStoreCatalogue', 'storeId': storeId, 'skuId': skuId,
        'listingReadbackVersion': 1, 'mediaReadbackVersion': 1, 'policyReadbackVersion': 1,
        if (productFactsReadbackSupported) 'productFactsReadbackVersion': 1,
        'storeDetailsReadbackVersion': 1,
        if (storeClassificationReadbackSupported) 'storeClassificationReadbackVersion': 1,
      }, current, mutation: false);
      if (!current() || response == null || response.statusCode != 200) return null;
      final envelope = _map(jsonDecode(response.body));
      if (envelope['ok'] != true) return null;
      _checkProduceReadback(_map(envelope['data']), supported: unbrandedProduceReadbackSupported);
      _checkStoreClassificationReadback(_map(envelope['data']), supported: storeClassificationReadbackSupported);
      if (storeClassificationReadbackSupported && _map(envelope['data'])['storeClassificationReadbackVersion'] != 1) throw const FormatException();
      final entry = WorkspacePublicCatalogueEntry.fromResponse(_map(envelope['data']),
        storeId: storeId, realm: realm, channel: channel, now: now().toUtc());
      // The response is scoped to the requested raw SKU, not merely a same-Store
      // listing. Account/session retirement never admits a delayed product.
      if (!current() || entry.product.sourceSkuId != skuId) return null;
      final enriched = await _enrichVariants([entry], current);
      return current() ? enriched.single : null;
    } catch (_) {
      return null;
    }
  }

  WorkspacePublicDetailsRecord? _ownerDetailsResponse(SocialContentResponse response, String operation, String storeId, String? key,
      {bool? classificationRequested}) {
    if (response.statusCode != 200) throw const FormatException();
    final envelope = _map(jsonDecode(response.body));
    if (envelope['ok'] != true) throw const FormatException();
    final data = _map(envelope['data']);
    final classification = classificationRequested ?? storeClassificationReadbackSupported;
    if (data.containsKey('storeClassificationReadbackVersion') &&
        (!classification || data['storeClassificationReadbackVersion'] is! int || data['storeClassificationReadbackVersion'] != 1) ||
        classification && data['storeClassificationReadbackVersion'] != 1) { throw const FormatException(); }
    _keys(Map<String, dynamic>.of(data)..remove('storeClassificationReadbackVersion'), ['schemaVersion', 'realm', 'storeId', 'operation', 'idempotencyKey', 'record',
      'locationVerified', 'publicAvailabilityConfirmed']);
    if (data['schemaVersion'] != 1 || data['realm'] != realm || data['storeId'] != storeId ||
        data['operation'] != operation || data['idempotencyKey'] != key || data['locationVerified'] != false ||
        data['publicAvailabilityConfirmed'] != false) {
      throw const FormatException();
    }
    final record = data['record'] == null ? null : WorkspacePublicDetailsRecord.decode(data['record'], realm, storeId);
    if (record?.details.businessType != null && !classification) throw const FormatException();
    if (record?.publishedAt.isAfter(now().toUtc()) == true) throw const FormatException();
    return record;
  }

  @override
  Future<WorkspacePublicDetailsRecord?> readPublicDetailsOwned({required String storeId, required bool Function() current}) async {
    if (ownerAccountId == null || !current()) throw const FormatException();
    _id(storeId);
    final response = await _ownerRequest({'operation': 'readStorePublicDetails', 'storeId': storeId,
      if (storeClassificationReadbackSupported) 'storeClassificationReadbackVersion': 1}, current, mutation: false);
    if (!current() || response == null) throw const FormatException();
    return _ownerDetailsResponse(response, 'readStorePublicDetails', storeId, null);
  }

  @override
  Future<WorkspacePublicDetailsWriteResult> writePublicDetails(WorkspacePublicDetailsIntent original,
    {required bool Function() current, bool reconcile = false}) async {
    var dispatched = false;
    final operation = reconcile ? 'reconcileStorePublicDetails' : 'saveStorePublicDetails';
    bool valid() => current() && ownerAccountId != null && ownerAccountId == original.ownerAccountId && realm == original.realm;
    try {
      if (!valid()) return const WorkspacePublicDetailsWriteResult(WorkspacePublicDetailsWriteState.notSent);
      _id(original.storeId); _id(original.idempotencyKey);
      _int(original.expectedRevision, 0, 999999999);
      WorkspacePublicDetailsFields.fromJson(original.details.toJson());
      if (!reconcile && original.details.businessType != null && !storeClassificationReadbackSupported) {
        return const WorkspacePublicDetailsWriteResult(WorkspacePublicDetailsWriteState.notSent);
      }
      final classification = storeClassificationReadbackSupported || reconcile && original.details.businessType != null;
      final response = await _ownerRequest({'operation': operation, ...original.body,
        if (classification) 'storeClassificationReadbackVersion': 1}, valid,
        mutation: !reconcile, onDispatch: () => dispatched = true);
      if (!valid() || response == null) throw const FormatException();
      if (!reconcile && _definitiveDetailsRejection(response)) {
        return const WorkspacePublicDetailsWriteResult(WorkspacePublicDetailsWriteState.rejected);
      }
      final record = _ownerDetailsResponse(response, operation, original.storeId, original.idempotencyKey,
        classificationRequested: classification);
      if (record == null && reconcile) return const WorkspacePublicDetailsWriteResult(WorkspacePublicDetailsWriteState.notFound);
      if (record == null || record.revision != original.expectedRevision + 1 ||
          jsonEncode(_sorted(record.details.toJson())) != jsonEncode(_sorted(original.details.toJson()))) {
        throw const FormatException();
      }
      return WorkspacePublicDetailsWriteResult(WorkspacePublicDetailsWriteState.saved, record);
    } catch (_) {
      return WorkspacePublicDetailsWriteResult(dispatched ? WorkspacePublicDetailsWriteState.unknown : WorkspacePublicDetailsWriteState.notSent);
    }
  }

  bool _definitiveDetailsRejection(SocialContentResponse response) {
    const codes = {400: 'invalid_input', 403: 'forbidden', 404: 'not_found', 409: 'revision_conflict'};
    if (!codes.containsKey(response.statusCode)) return false;
    try {
      final envelope = _map(jsonDecode(response.body));
      _keys(envelope, ['ok', 'error']);
      final error = _map(envelope['error']);
      _keys(error, ['code', 'message', 'retryable']);
      _string(error['message'], 2000);
      return envelope['ok'] == false && error['code'] == codes[response.statusCode] && error['retryable'] == false;
    } catch (_) { return false; }
  }
}

/// Lifetime-scoped content cache. Refresh explicitly; no writes or blind retries.
class WorkspaceCatalogueReadback extends ChangeNotifier
    implements BuyV2ProductContentAdapter {
  WorkspaceCatalogueReadback({
    required this.gateway,
    required this.context,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;
  final WorkspaceCatalogueGateway gateway;
  final Object? Function() context;
  final DateTime Function() now;
  final Map<String, WorkspaceCatalogueContentResult> _results = {};
  final Map<String, WorkspaceCatalogueContentResult> _highWater = {};
  final Map<String, ({int revision, String? fingerprint})> _policyHighWater = {};
  final Map<String, Object> _owners = {};
  final Map<String, String> _inputs = {};
  final Set<String> _busy = {};
  final Map<String, Timer> _expiry = {};
  bool _closed = false;
  Object? _lifetime;
  bool get _policyRequired => gateway is AuthenticatedWorkspaceCatalogueGateway &&
      (gateway as AuthenticatedWorkspaceCatalogueGateway).policyResolutionRequired;
  bool _requiresPolicy(BuyV2Product product) => product.publicListingIdentity != null || _policyRequired;
  String _key(BuyV2Product product) =>
      jsonEncode([product.storeId, product.id, product.offerClass?.name]);
  String _policyKey(BuyV2Product product) => jsonEncode([product.storeId, product.sourceSkuId,
    if (product.publicListingIdentity case final identity?) identity.realm]);
  static String? _input(BuyV2Product product) {
    try {
      final price = product.priceMinor, mrp = product.mrpMinor;
      final tiers = [for (final tier in product.packTerms?.priceTiers ?? <BuyV2PackPriceTier>[]) tier.priceMinor];
      final exact = price % 100 != 0 || mrp != null && mrp % 100 != 0 || tiers.any((price) => price % 100 != 0);
      final values = [
    product.storeId,
    product.id,
    if (product.publicListingIdentity case final identity?) identity.toJson(),
    product.canonicalId,
    product.offerClass?.name,
    product.categoryId,
    product.title,
    product.brand,
    product.variant,
    if (product.variantFamilyId != null) [product.variantFamilyId,
      for (final a in product.variantAttributes)
        [a.dimensionId, a.dimensionLabel, a.optionId, a.optionLabel, a.kind.name, a.swatchArgb]],
    if (product.publicListingIdentity != null && product.sellerType.isNotEmpty)
      {'publicSellerType': product.sellerType},
    product.pack,
    if (!WorkspaceCatalogueProductFacts.fromProduct(product).isEmpty)
      WorkspaceCatalogueProductFacts.fromProduct(product).toJson(),
    exact ? price : price ~/ 100,
    mrp == null ? null : exact ? mrp : mrp ~/ 100,
    product.minimumOrder,
    product.quantityStep,
    if (product.packTerms case final terms?) ...[
      terms.revision,
      terms.sellUnit,
      terms.containedUnits,
      terms.netContentMilli,
      terms.contentUnit,
      terms.requiresMeasurement,
      terms.pricingStoreId,
      terms.priceObservedAt?.toIso8601String(),
      terms.priceValidUntil?.toIso8601String(),
      for (var i = 0; i < terms.priceTiers.length; i++)
        [terms.priceTiers[i].minimumPacks, exact ? tiers[i] : tiers[i] ~/ 100],
    ],
      ];
      // Keep the old whole-money fingerprint literal. Exact money is tagged;
      // malformed money is never admitted or rebound in a catch handler.
      return jsonEncode(exact ? {'version': 2, 'moneyUnit': 'minor', 'values': values} : values);
    } on FormatException {
      return null;
    }
  }

  Future<void> refresh(BuyV2Product product) async {
    final owner = context(), key = _key(product);
    if (_closed || owner == null) return;
    _prepareOwner(owner);
    final input = _input(product);
    if (input == null) { notifyListeners(); return; }
    if (!_busy.add(key)) return;
    try {
      final result = await gateway.read(product);
      if (_closed || context() != owner) return;
      _admitResult(product, result, owner);
    } catch (_) {
      if (!_closed && context() == owner) {
        _results[key] = WorkspaceCatalogueContentResult(
          content: _unavailable(product, policyResolutionPending: _requiresPolicy(product) ||
            _policyHighWater.containsKey(_policyKey(product)) ||
            _results[key]?.content.supplierPolicyResolutionPending == true),
        );
        _owners[key] = owner;
        _inputs[key] = input;
        notifyListeners();
      }
    } finally {
      _busy.remove(key);
    }
  }

  /// Already decoded public-page entries use exactly the same freshness and
  /// high-water admission as individual network reads. No permissive side cache.
  void admitPublicEntry(WorkspacePublicCatalogueEntry entry, {required Object expectedContext}) {
    if (_closed || context() != expectedContext || entry.product.publicListingIdentity == null ||
        !entry.product.hasValidPublicListingIdentity) {
      return;
    }
    _prepareOwner(expectedContext);
    _admitResult(entry.product, entry.readback, expectedContext);
  }

  Iterable<String> get observedProductIds => _results.entries
    .where((entry) => !_closed && _owners[entry.key] == context())
    .map((entry) => entry.value.content.productId).toSet();

  void _prepareOwner(Object owner) {
    if (_lifetime != owner) {
      for (final timer in _expiry.values) {
        timer.cancel();
      }
      _expiry.clear();
      _results.clear();
      _highWater.clear();
      _policyHighWater.clear();
      _owners.clear();
      _inputs.clear();
      _lifetime = owner;
    }
  }

  void _admitResult(BuyV2Product product, WorkspaceCatalogueContentResult result, Object owner) {
      final input = _input(product);
      if (input == null) return;
      final key = _key(product);
      final prior = _highWater[key];
      final priorPolicy = _policyHighWater[_policyKey(product)], policyRevision = result.policyRevision;
      final ready =
          result.content.productId == product.id &&
          result.content.state == BuyV2ProductContentState.ready &&
          (result.skuRevision ?? 0) > 0 &&
          (result.catalogueVersion ?? 0) > 0 &&
          result.fingerprint?.isNotEmpty == true &&
          result.content.sourceId.trim().isNotEmpty &&
          result.content.observedAt != null &&
          !result.content.observedAt!.isAfter(now().toUtc()) &&
          result.validUntil?.isAfter(now().toUtc()) == true;
      final policyRegressed = priorPolicy != null &&
          (policyRevision == null && !result.content.supplierPolicyResolutionPending ||
            policyRevision != null && (policyRevision < priorPolicy.revision ||
              policyRevision == priorPolicy.revision && result.policyFingerprint != null &&
              priorPolicy.fingerprint != null && result.policyFingerprint != priorPolicy.fingerprint));
      final regressed = policyRegressed ||
          prior?.skuRevision != null &&
          ready &&
          (result.skuRevision! < prior!.skuRevision! ||
              result.catalogueVersion! < prior.catalogueVersion! ||
              (result.skuRevision == prior.skuRevision &&
                  result.fingerprint != prior.fingerprint));
      _results[key] = ready && !regressed
          ? result
          : WorkspaceCatalogueContentResult(content: _unavailable(product,
              policyResolutionPending: _requiresPolicy(product) || priorPolicy != null ||
                result.content.supplierPolicyResolutionPending));
      if (ready && !regressed) _highWater[key] = result;
      if (ready && !regressed && policyRevision != null) {
        _policyHighWater[_policyKey(product)] = (revision: policyRevision,
          fingerprint: result.policyFingerprint ??
            (policyRevision == priorPolicy?.revision ? priorPolicy?.fingerprint : null));
      }
      _owners[key] = owner;
      _inputs[key] = input;
      _expiry.remove(key)?.cancel();
      if (ready && !regressed) {
        _expiry[key] = Timer(result.validUntil!.difference(now().toUtc()), () {
          if (!_closed && context() == owner) notifyListeners();
        });
      }
      notifyListeners();
  }

  @override
  BuyV2ProductContentSnapshot snapshotFor(BuyV2Product product) {
    final key = _key(product), result = _results[_key(product)];
    final policy = _policyHighWater[_policyKey(product)];
    final input = _input(product);
    if (_closed ||
        input == null ||
        context() == null ||
        _owners[key] != context() ||
        result == null ||
        _inputs[key] != input ||
        result.validUntil?.isAfter(now().toUtc()) != true ||
        policy != null && (result.policyRevision == null || result.policyRevision! < policy.revision ||
          result.policyRevision == policy.revision && result.policyFingerprint != null &&
          policy.fingerprint != null && result.policyFingerprint != policy.fingerprint)) {
      return _unavailable(product, policyResolutionPending: _requiresPolicy(product) || policy != null ||
        result?.content.supplierPolicyResolutionPending == true);
    }
    return result.content;
  }

  WorkspaceCatalogueContentResult? displayedProduct(BuyV2Product product) =>
    snapshotFor(product).state == BuyV2ProductContentState.ready ? _results[_key(product)] : null;

  @override
  void dispose() {
    _closed = true;
    for (final timer in _expiry.values) {
      timer.cancel();
    }
    _expiry.clear();
    _results.clear();
    _highWater.clear();
    _policyHighWater.clear();
    _owners.clear();
    _inputs.clear();
    super.dispose();
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is! Map<String, dynamic>) throw const FormatException();
  return value;
}

String _string(Object? value, [int maximum = 240, bool empty = false]) {
  if (value is! String ||
      value.trim() != value ||
      value.length > maximum ||
      (!empty && value.isEmpty) ||
      RegExp(r'[\x00-\x08\x0b\x0c\x0e-\x1f]').hasMatch(value)) {
    throw const FormatException();
  }
  return value;
}

String _id(Object? value) {
  final id = _string(value, 128);
  if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]{2,127}$').hasMatch(id)) {
    throw const FormatException();
  }
  return id;
}

int _int(Object? value, [int minimum = 1, int maximum = 100000000]) {
  if (value is! int || value < minimum || value > maximum) {
    throw const FormatException();
  }
  return value;
}

List<dynamic> _list(Object? value, int maximum) {
  if (value is! List || value.length > maximum) throw const FormatException();
  return value;
}

DateTime _time(Object? value) => DateTime.parse(_string(value, 32)).toUtc();

void _ownerSkuInput(Map<String, dynamic> sku, String storeId) {
  _keys(sku, [
    'skuId',
    'canonicalProductId',
    'verifiedPackId',
    'sku',
    'publicListing',
    'content',
    'pack',
    'channels',
    'provenance',
  ]);
  final skuId = _id(sku['skuId']), canonicalId = _id(sku['canonicalProductId']);
  _id(sku['verifiedPackId']);
  _string(sku['sku'], 80);
  if (sku['publicListing'] is! bool) throw const FormatException();
  final provenance = _map(sku['provenance']);
  _keys(provenance, ['entryMethod', 'sourceRecordId']);
  if (!{'catalogue', 'manual', 'csv'}.contains(provenance['entryMethod'])) {
    throw const FormatException();
  }
  _id(provenance['sourceRecordId']);
  final content = _map(sku['content']);
  _keys(Map<String, dynamic>.of(content)..remove('productFacts'), [
    'title',
    'brand',
    'variant',
    'categoryId',
    'description',
    'highlights',
    'specifications',
    'media',
  ]);
  _string(content['title']);
  _catalogueBrand(content);
  _string(content['variant'], 240, true);
  _id(content['categoryId']);
  if (content.containsKey('productFacts')) WorkspaceCatalogueProductFacts.fromJson(content['productFacts']);
  _string(content['description'], 4000, true);
  for (final value in _list(content['highlights'], 20)) {
    _string(value, 500);
  }
  for (final raw in _list(content['specifications'], 40)) {
    final spec = _map(raw);
    _keys(spec, ['label', 'value']);
    _string(spec['label']);
    _string(spec['value'], 1000);
  }
  final mediaIds = <String>{};
  for (final raw in _list(content['media'], 10)) {
    final media = _map(raw);
    _keys(media, [
      'id',
      'revision',
      'url',
      'storeId',
      'skuId',
      'canonicalProductId',
      'publisherWorkspaceId',
      'file',
    ]);
    if (!mediaIds.add(_id(media['id'])) ||
        media['storeId'] != storeId ||
        media['skuId'] != skuId ||
        media['canonicalProductId'] != canonicalId) {
      throw const FormatException();
    }
    _id(media['revision']);
    _id(media['publisherWorkspaceId']);
    final uri = Uri.parse(_string(media['url'], 2048));
    if (uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.userInfo.isNotEmpty) {
      throw const FormatException();
    }
    final file = _map(media['file']);
    _keys(Map<String, dynamic>.of(file)..remove('frameCount'), ['mimeType', 'byteLength', 'width', 'height', 'normalized']);
    if (file.containsKey('frameCount')) { _int(file['frameCount'], 1, 1); }
    if (!{'image/png', 'image/jpeg', 'image/webp'}.contains(file['mimeType']) ||
        file['normalized'] is! bool) {
      throw const FormatException();
    }
    _int(file['byteLength'], 1, 10485760);
    _int(file['width'], 1, 8192);
    _int(file['height'], 1, 8192);
  }
  final pack = _map(sku['pack']);
  _keys(pack, ['label', 'quantityMilli', 'unit', 'unitsPerCase']);
  _string(pack['label']);
  _int(pack['quantityMilli']);
  _int(pack['unitsPerCase']);
  if (!{'kg', 'L', 'count'}.contains(pack['unit'])) {
    throw const FormatException();
  }
  final channels = _list(sku['channels'], 2), kinds = <String>{};
  if (channels.isEmpty) throw const FormatException();
  for (final raw in channels) {
    final channel = _map(raw);
    _keys(channel, [
      'kind',
      'offerId',
      'priceMinor',
      'mrpMinor',
      'minimumOrder',
      'quantityStep',
      'tiers',
    ]);
    final kind = _string(channel['kind']);
    if (!{'retail', 'wholesale', 'bulk'}.contains(kind) ||
        !kinds.add(kind) ||
        kinds.contains('wholesale') && kinds.contains('bulk')) {
      throw const FormatException();
    }
    _id(channel['offerId']);
    final price = _int(channel['priceMinor']),
        minimum = _int(channel['minimumOrder']),
        step = _int(channel['quantityStep']);
    if (channel['mrpMinor'] != null) _int(channel['mrpMinor'], price);
    var lastMinimum = 0, lastPrice = price, index = 0;
    for (final raw in _list(channel['tiers'], 20)) {
      final tier = _map(raw);
      _keys(tier, ['minimumQuantity', 'unitPriceMinor']);
      final quantity = _int(tier['minimumQuantity']),
          amount = _int(tier['unitPriceMinor']);
      if (quantity <= lastMinimum ||
          (quantity - minimum) % step != 0 ||
          amount > lastPrice ||
          index == 0 && (quantity != minimum || amount != price)) {
        throw const FormatException();
      }
      lastMinimum = quantity;
      lastPrice = amount;
      index++;
    }
  }
}

WorkspaceCatalogueContentResult _decode(
  Map<String, dynamic> data,
  BuyV2Product product,
  String realm,
  DateTime now, {
  bool policyRequired = false,
}) {
  _checkProductFactsReadbackVersion(data);
  _checkProduceReadback(data);
  if (data['schemaVersion'] != 1 ||
      data['realm'] != realm ||
      data['storeId'] != product.storeId ||
      data['orderingAvailable'] != false ||
      data['coverage'] != 'verified_public_only') {
    throw const FormatException();
  }
  final observed = _time(data['observedAt']);
  if (observed.isAfter(now)) throw const FormatException();
  final items = _list(data['items'], 1);
  if (data['state'] != 'ready' ||
      items.length != 1 ||
      data['nextCursor'] != null) {
    return WorkspaceCatalogueContentResult(content: _unavailable(product, policyResolutionPending: policyRequired));
  }
  final catalogueVersion = _int(data['catalogueVersion'], 1, 1000000001);
  final row = _map(items.single);
  final identity = product.publicListingIdentity;
  final coreRow = Map<String, dynamic>.of(row)..remove('supplierPolicy');
  if (identity != null) {
    if (!identity.matches(product) || identity.realm != realm || data['listingReadbackVersion'] != 1 ||
        data['listingCoverage'] != 'complete') { throw const FormatException(); }
    _publicStore(data, product.storeId!, realm, now);
    if (data['storeClassificationReadbackVersion'] == 1 &&
        _publicSellerType(data, product.storeId!, realm, now) != product.sellerType) { throw const FormatException(); }
    final bindings = _list(row['listings'], 2).map(BuyV2PublicListingIdentity.fromJson).toList();
    if (bindings.isEmpty || bindings.any((binding) => binding == null || !binding.valid ||
        binding.realm != realm || binding.storeId != product.storeId || binding.skuId != product.sourceSkuId ||
        binding.canonicalProductId != product.canonicalId || binding.verifiedPackId != row['verifiedPackId']) ||
        bindings.map((binding) => binding?.channel).toSet().length != bindings.length || !bindings.contains(identity) ||
        bindings.length != (row['channels'] as List).length ||
        bindings.any((binding) => !(row['channels'] as List).any((channel) =>
          channel is Map && channel['kind'] == binding!.channel.name))) { throw const FormatException(); }
    coreRow.remove('listings');
  }
  _keys(coreRow, [
    'skuId',
    'canonicalProductId',
    'verifiedPackId',
    'sku',
    'revision',
    'observedAt',
    'content',
    'pack',
    'channels',
  ]);
  if (row['skuId'] != product.sourceSkuId ||
      row['canonicalProductId'] != product.canonicalId ||
      _time(row['observedAt']).isAfter(observed)) {
    throw const FormatException();
  }
  _id(row['verifiedPackId']);
  _string(row['sku'], 80);
  final revision = _int(row['revision'], 1, 1000000001),
      content = _map(row['content']);
  _keys(Map<String, dynamic>.of(content)..remove('productFacts'), [
    'title',
    'brand',
    'variant',
    'categoryId',
    'description',
    'highlights',
    'specifications',
    'media',
  ]);
  if (content['title'] != product.title ||
      content['brand'] != product.brand ||
      content['variant'] != product.variant ||
      content['categoryId'] != product.categoryId) {
    throw const FormatException();
  }
  _catalogueBrand(content, readback: data);
  if (content.containsKey('productFacts')) {
    final facts = WorkspaceCatalogueProductFacts.fromJson(content['productFacts']);
    if (data['productFactsReadbackVersion'] != 1 ||
        jsonEncode(_sorted(facts.toJson())) !=
        jsonEncode(_sorted(WorkspaceCatalogueProductFacts.fromProduct(product).toJson()))) {
      throw const FormatException();
    }
  } else if (!WorkspaceCatalogueProductFacts.fromProduct(product).isEmpty) {
    // Do not silently drop known reviewed facts when a source is downgraded.
    throw const FormatException();
  }
  final pack = _map(row['pack']);
  _keys(pack, ['label', 'quantityMilli', 'unit', 'unitsPerCase']);
  if (pack['label'] != product.pack ||
      !{'kg', 'L', 'count'}.contains(pack['unit'])) {
    throw const FormatException();
  }
  _int(pack['quantityMilli']);
  _int(pack['unitsPerCase']);
  final packTerms = product.packTerms;
  if (packTerms != null) {
    final scale = switch (packTerms.contentUnit) {
      'kg' || 'L' || 'piece' => 1,
      'g' || 'mL' => 1000,
      _ => null,
    };
    final unit = switch (packTerms.contentUnit) {
      'kg' || 'g' => 'kg',
      'L' || 'mL' => 'L',
      'piece' => 'count',
      _ => null,
    };
    final amount = packTerms.netContentMilli;
    if (!product.hasValidPackTerms ||
        !packTerms.pricingCurrentAt(now) ||
        packTerms.requiresMeasurement ||
        scale == null ||
        amount == null ||
        pack['unit'] != unit ||
        // Store quantity is aggregate content of the selling pack, not one
        // contained item. Cross-multiply to preserve exact g/mL conversion.
        BigInt.from(amount) * BigInt.from(packTerms.containedUnits) !=
            BigInt.from(pack['quantityMilli'] as int) * BigInt.from(scale) ||
        pack['unitsPerCase'] != packTerms.containedUnits) {
      throw const FormatException();
    }
  }
  final channels = _list(row['channels'], 2).map(_map).toList();
  if (channels.isEmpty ||
      channels.map((c) => c['kind']).toSet().length != channels.length ||
      (channels.any((c) => c['kind'] == 'wholesale') &&
          channels.any((c) => c['kind'] == 'bulk'))) {
    throw const FormatException();
  }
  DateTime? validUntil;
  final coreChannels = <Map<String, dynamic>>[];
  for (final channel in channels) {
    _keys(channel, [
      'kind',
      'offerId',
      'priceMinor',
      'mrpMinor',
      'minimumOrder',
      'quantityStep',
      'tiers',
      'revision',
      'validUntil',
    ]);
    if (!{'retail', 'wholesale', 'bulk'}.contains(channel['kind'])) {
      throw const FormatException();
    }
    _id(channel['offerId']);
    _id(channel['revision']);
    final price = _int(channel['priceMinor']),
        minimum = _int(channel['minimumOrder']),
        step = _int(channel['quantityStep']);
    if (channel['mrpMinor'] != null) _int(channel['mrpMinor'], price);
    final tiers = _list(channel['tiers'], 20).map(_map).toList();
    var lastMinimum = 0, lastPrice = price;
    for (var i = 0; i < tiers.length; i++) {
      final t = tiers[i];
      _keys(t, ['minimumQuantity', 'unitPriceMinor']);
      final quantity = _int(t['minimumQuantity']),
          tierPrice = _int(t['unitPriceMinor']);
      if (quantity <= lastMinimum ||
          (quantity - minimum) % step != 0 ||
          tierPrice > lastPrice ||
          (i == 0 && (quantity != minimum || tierPrice != price))) {
        throw const FormatException();
      }
      lastMinimum = quantity;
      lastPrice = tierPrice;
    }
    final expires = _time(channel['validUntil']);
    if (!expires.isAfter(now)) throw const FormatException();
    validUntil = validUntil == null || expires.isBefore(validUntil)
        ? expires
        : validUntil;
    coreChannels.add(
      Map.of(channel)
        ..remove('revision')
        ..remove('validUntil'),
    );
  }
  final matching = channels
      .where((c) => c['kind'] == product.offerClass?.name)
      .toList();
  if (matching.length != 1 ||
      matching.single['priceMinor'] != product.priceMinor ||
      matching.single['mrpMinor'] != product.mrpMinor ||
      matching.single['minimumOrder'] != product.minimumOrder ||
      matching.single['quantityStep'] != product.quantityStep) {
    throw const FormatException();
  }
  if (identity != null && packTerms != null &&
      (packTerms.revision != matching.single['revision'] ||
          packTerms.priceObservedAt != _time(row['observedAt']) ||
          packTerms.priceValidUntil != _time(matching.single['validUntil']))) {
    throw const FormatException();
  }
  final expectedTiers = [
    for (final tier in packTerms?.priceTiers ?? <BuyV2PackPriceTier>[])
      {
        'minimumQuantity': tier.minimumPacks,
        'unitPriceMinor': tier.priceMinor,
      },
  ];
  if (jsonEncode(_sorted(matching.single['tiers'])) !=
      jsonEncode(_sorted(expectedTiers))) {
    throw const FormatException();
  }
  final media = _list(content['media'], 10).map((raw) {
    final m = _map(raw);
    _keys(m, [
      'id',
      'revision',
      'url',
      'storeId',
      'skuId',
      'canonicalProductId',
      'publisherWorkspaceId',
      'file',
    ]);
    if (m['storeId'] != product.storeId ||
        m['skuId'] != product.sourceSkuId ||
        m['canonicalProductId'] != product.canonicalId) {
      throw const FormatException();
    }
    final uri = Uri.parse(_string(m['url'], 2048));
    if (uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const FormatException();
    }
    final file = _map(m['file']);
    if (file.containsKey('frameCount') && data['mediaReadbackVersion'] != 1) throw const FormatException();
    _keys(Map<String, dynamic>.of(file)..remove('frameCount'), ['mimeType', 'byteLength', 'width', 'height', 'normalized']);
    if (file.containsKey('frameCount')) { _int(file['frameCount'], 1, 1); }
    if (!{'image/png', 'image/jpeg', 'image/webp'}.contains(file['mimeType']) ||
        file['normalized'] is! bool) {
      throw const FormatException();
    }
    return BuyV2ProductMediaAsset(
      id: _id(m['id']),
      label: product.title,
      semanticLabel: '${product.title}, ${product.pack}',
      kind: BuyV2ProductContentMediaKind.network,
      source: uri.toString(),
      binding: BuyV2ProductMediaBinding(
        supplierWorkspaceId: _id(m['publisherWorkspaceId']),
        storeId: product.storeId!,
        productId: product.canonicalId,
        skuId: product.sourceSkuId,
        assetRevision: _id(m['revision']),
        file: BuyV2MediaFileMetadata(
          mimeType: file['mimeType'] as String,
          byteLength: _int(file['byteLength'], 1, 10485760),
          width: _int(file['width'], 1, 8192),
          height: _int(file['height'], 1, 8192),
          normalized: file['normalized'] as bool,
          frameCount: file['frameCount'] as int?,
        ),
      ),
    );
  }).toList();
  if (media.map((m) => m.id).toSet().length != media.length) {
    throw const FormatException();
  }
  final policy = row.containsKey('supplierPolicy')
      ? _decodePolicy(row['supplierPolicy'], product, realm, now) : null;
  if (policyRequired && policy == null) throw const FormatException();
  final policyExpiry = policy?.policy?.validUntil;
  if (policyExpiry != null && (validUntil == null || policyExpiry.isBefore(validUntil))) {
    validUntil = policyExpiry;
  }
  final result = BuyV2ProductContentSnapshot(
    productId: product.id,
    state: BuyV2ProductContentState.ready,
    sourceId:
        'store:${product.storeId}:catalogue:$catalogueVersion:sku:${product.sourceSkuId}:revision:$revision',
    observedAt: observed,
    supplierPolicy: policy?.policy,
    supplierPolicyAcceptanceRequired: policy?.required,
    supplierPolicyObservedAt: policy?.observed,
    supplierPolicyResolutionPending: policy?.pending ?? false,
    description: _string(content['description'], 4000, true),
    media: List.unmodifiable(media),
    highlights: List.unmodifiable(
      _list(content['highlights'], 20).map((h) => _string(h, 500)),
    ),
    specifications: List.unmodifiable(
      _list(content['specifications'], 40).map((s) {
        final item = _map(s);
        _keys(item, ['label', 'value']);
        return BuyV2ProductSpecification(
          label: _string(item['label']),
          value: _string(item['value'], 1000),
        );
      }),
    ),
  );
  // Immutable SKU payload, excluding legitimately rotating governed term windows.
  final core = Map<String, dynamic>.of(row)..remove('supplierPolicy')..['channels'] = coreChannels;
  return WorkspaceCatalogueContentResult(
    content: result,
    skuRevision: revision,
    catalogueVersion: catalogueVersion,
    validUntil: validUntil,
    fingerprint: jsonEncode(_sorted(core)),
    policyRevision: policy?.revision,
    policyFingerprint: policy?.fingerprint,
  );
}

({BuyV2SupplierPolicy? policy, bool? required, bool pending, int? revision,
  String? fingerprint, DateTime observed}) _decodePolicy(Object? raw, BuyV2Product product, String realm, DateTime now) {
  final envelope = _map(raw);
  _keys(envelope, ['schemaVersion', 'realm', 'storeId', 'skuId', 'observedAt', 'state', 'revision', 'requiresAcceptance', 'policy']);
  final observed = _time(envelope['observedAt']);
  if (envelope['schemaVersion'] != 1 || envelope['realm'] != realm ||
      envelope['storeId'] != product.storeId || envelope['skuId'] != product.sourceSkuId || observed.isAfter(now)) {
    throw const FormatException();
  }
  final revision = envelope['revision'] == null ? null : _int(envelope['revision'], 0, 1000000001);
  final required = envelope['requiresAcceptance'];
  if (required != null && required is! bool) throw const FormatException();
  final state = envelope['state'];
  if (state == 'unavailable') {
    if (envelope['policy'] != null || (revision == null) != (required == null) || revision == 0) {
      throw const FormatException();
    }
    return (policy: null, required: required as bool?, pending: true, revision: revision,
      fingerprint: null, observed: observed);
  }
  if (revision == null) throw const FormatException();
  if (state == 'none') {
    if (required != false || envelope['policy'] != null) throw const FormatException();
    return (policy: null, required: false, pending: false, revision: revision,
      fingerprint: 'none', observed: observed);
  }
  if (state != 'ready' || revision < 1 || required is! bool) throw const FormatException();
  final value = _map(envelope['policy']);
  _keys(value, ['id', 'storeId', 'revision', 'title', 'body', 'productIds', 'requiresAcceptance', 'validUntil']);
  final ids = _list(value['productIds'], 1);
  if (value['storeId'] != product.storeId || value['revision'] != 'policy-v$revision' ||
      value['requiresAcceptance'] != required || ids.length != 1 || ids.single != product.sourceSkuId) {
    throw const FormatException();
  }
  final policy = BuyV2SupplierPolicy(id: _id(value['id']), storeId: product.storeId!, revision: value['revision'] as String,
    title: _string(value['title'], 160), body: _string(value['body'], 12000), productIds: {product.sourceSkuId},
    sourceRealm: product.publicListingIdentity?.realm,
    requiresAcceptance: required, validUntil: value['validUntil'] == null ? null : _time(value['validUntil']));
  if (!policy.appliesTo(product, now)) throw const FormatException();
  return (policy: policy, required: required, pending: false, revision: revision,
    fingerprint: jsonEncode(_sorted(value)), observed: observed);
}

Map<String, dynamic> _publicStore(Map<String, dynamic> data, String storeId, String realm, DateTime now) {
  _checkStoreClassificationReadback(data);
  final store = _map(data['publicStore']);
  _keys(Map<String, dynamic>.of(store)..remove('details'), ['id', 'name', 'profileId']);
  if (store['id'] != storeId || !_string(store['profileId']).startsWith('retailer-')) throw const FormatException();
  _string(store['name'], 240);
  if (store.containsKey('details') || data['storeDetailsReadbackVersion'] == 1) {
    if (data['storeDetailsReadbackVersion'] != 1) throw const FormatException();
    final metadata = WorkspacePublicStoreMetadata.decode(store['details'], realm, storeId, now);
    if (metadata.details?.businessType != null && data['storeClassificationReadbackVersion'] != 1) throw const FormatException();
  }
  return store;
}

void _checkStoreClassificationReadback(Map<String, dynamic> data, {bool supported = true}) {
  if (data.containsKey('storeClassificationReadbackVersion') &&
      (!supported || data['storeClassificationReadbackVersion'] is! int ||
       data['storeClassificationReadbackVersion'] != 1 || data['storeDetailsReadbackVersion'] != 1)) {
    throw const FormatException();
  }
}

String _publicSellerType(Map<String, dynamic> data, String storeId, String realm, DateTime now) {
  if (data['storeClassificationReadbackVersion'] != 1) return '';
  final store = _map(data['publicStore']);
  return WorkspacePublicStoreMetadata.decode(store['details'], realm, storeId, now).details?.publicSellerType ?? '';
}

void _keys(Map<String, dynamic> value, List<String> allowed) {
  if (value.length != allowed.length ||
      allowed.any((key) => !value.containsKey(key))) {
    throw const FormatException();
  }
}

Object? _sorted(Object? value) {
  if (value is List) return value.map(_sorted).toList();
  if (value is Map<String, dynamic>) {
    return {
      for (final key in value.keys.toList()..sort()) key: _sorted(value[key]),
    };
  }
  return value;
}
