import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart' as crypto;

import '../buy/buy_v2_content_contracts.dart';
import '../buy/buy_v2_models.dart';
import '../shared/social_content_gateway.dart';
import 'work_publication_data.dart';
import 'work_models.dart' show WorkspaceVariantFamily, WorkspaceVariantMembership, WorkspaceCatalogueItem;

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

/// Owner-authored saved facts, not a reviewed mirror, Stock upload or publication.
class WorkspaceProductSubmissionInput {
  WorkspaceProductSubmissionInput._(this._encoded);
  final String _encoded;
  Map<String, dynamic> toJson() => _map(jsonDecode(_encoded));
  String get skuId => toJson()['skuId'] as String;
  String get fingerprint => _encoded;
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
  DateTime get expiresAt => _time(toJson()['expiresAt']);
  static WorkspaceReviewedProductCandidate decode(Object? raw, WorkspaceProductSubmissionRecord source,
      WorkspaceProductSubmissionScope scope, DateTime observed, {bool requireCurrent = true}) {
    final value = _map(raw);
    _keys(value, ['schemaVersion', 'realm', 'storeId', 'skuId', 'revision', 'fingerprint', 'source', 'identity',
      'sku', 'expectedMirrorRevision', 'reviewedBy', 'reviewedAt', 'expiresAt', 'terms']);
    final reference = _map(value['source']);
    _keys(reference, ['realm', 'storeId', 'skuId', 'revision', 'fingerprint']);
    _int(reference['revision'], 1, 1000000000);
    final identity = _map(value['identity']); _keys(identity, ['catalogueId', 'tenantId']);
    _id(identity['catalogueId']); _id(identity['tenantId']);
    _int(value['revision'], 1, 1000000000); _int(value['expectedMirrorRevision'], 0, 1000000000);
    final reviewedAt = _time(value['reviewedAt']), expires = _time(value['expiresAt']);
    final body = source.input.toJson(), sku = _map(value['sku']); _ownerSkuInput(sku, scope.store);
    final content = Map<String, dynamic>.of(_map(body['content']))..['media'] = <Object>[];
    final channels = (sku['channels'] as List).map((raw) => Map<String, dynamic>.of(_map(raw))..remove('offerId')).toList();
    final noImages = body['mediaIntent']['pendingUpload'] == false && (body['mediaIntent']['publishedReferences'] as List).isEmpty;
    final hashed = Map<String, dynamic>.of(value)..remove('fingerprint');
    if (_int(value['schemaVersion'], 1, 1) != 1 || value['realm'] != scope.realm || value['storeId'] != scope.store || value['skuId'] != scope.sku ||
        reference['realm'] != scope.realm || reference['storeId'] != scope.store || reference['skuId'] != scope.sku ||
        reference['revision'] != source.revision || reference['fingerprint'] != source.fingerprint ||
        value['fingerprint'] != _catalogueHash(hashed) || _id(value['reviewedBy']) == source.toJson()['submittedBy'] ||
        reviewedAt.toIso8601String() != value['reviewedAt'] || expires.toIso8601String() != value['expiresAt'] ||
        reviewedAt.isAfter(observed) || reviewedAt.isBefore(_time(source.toJson()['submittedAt'])) || !expires.isAfter(reviewedAt) ||
        requireCurrent && !expires.isAfter(observed) || !noImages || sku['publicListing'] != true ||
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
      idempotencyKey: idempotencyKey, sku: sku, reviewCandidate: {'revision': revision, 'fingerprint': fingerprint}, reviewedSource: source);
}
String _catalogueHash(Object value) => crypto.sha256.convert(utf8.encode(jsonEncode(_sorted(value)))).toString().toUpperCase();
class WorkspaceProductReviewReadback {
  const WorkspaceProductReviewReadback({required this.record, required this.state, this.candidate});
  final WorkspaceProductSubmissionRecord? record;
  final String state;
  final WorkspaceReviewedProductCandidate? candidate;
  static WorkspaceProductReviewReadback decodeReview(Object? raw, WorkspaceProductSubmissionRecord? record,
      WorkspaceProductSubmissionScope scope, DateTime observed) {
    final review = _map(raw); _keys(review, ['version', 'state', 'candidate']);
    final state = _string(review['state']);
    if (_int(review['version'], 1, 1) != 1 || !{'pending', 'awaiting_media', 'ready', 'bound', 'outdated', 'unavailable'}.contains(state) ||
        ({'ready', 'bound'}.contains(state) ? record == null || review['candidate'] == null : review['candidate'] != null) ||
        state == 'awaiting_media' && record == null) { throw const FormatException(); }
    final candidate = review['candidate'] == null ? null : WorkspaceReviewedProductCandidate.decode(review['candidate'], record!, scope,
      observed, requireCurrent: state != 'bound');
    return WorkspaceProductReviewReadback(record: record, state: state, candidate: candidate);
  }
}

abstract interface class WorkspaceProductSubmissionJournal {
  Future<WorkspaceProductSubmissionIntent?> readPending(WorkspaceProductSubmissionScope scope);
  Future<void> savePending(WorkspaceProductSubmissionIntent original);
  Future<void> removePending(WorkspaceProductSubmissionIntent original);
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
    busy = true; headLoaded = false; _notify();
    try {
      if (!await restore() || !active) return false;
      if (pending != null) { message = 'Check the original request before another submission.'; return false; }
      final next = await gateway.readProductSubmission(scope, current: () => active).timeout(const Duration(seconds: 25));
      if (!active) return false;
      final revision = next?.revision ?? 0, bytes = next == null ? null : jsonEncode(_sorted(next.toJson()));
      if (revision < _revision || revision == _revision && _headBytes != bytes) throw const FormatException();
      head = next; _revision = revision; _headBytes = bytes; headLoaded = true;
      message = next == null ? 'This saved product has not been submitted.' : next.input.mediaPending
        ? 'Product details received privately. Photo upload and review are still needed.'
        : 'Product details received privately. Approval and public listing are not confirmed.';
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
    busy = true; _notify();
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
    if (_encodedReviewCandidate != null) {
      final ref = _map(jsonDecode(_encodedReviewCandidate)); _keys(ref, ['revision', 'fingerprint']);
      _int(ref['revision'], 1, 1000000000);
      if (ref['fingerprint'] is! String || !RegExp(r'^[A-F0-9]{64}$').hasMatch(ref['fingerprint'] as String)) throw const FormatException();
    }
  }
  final String accountId, realm, storeId, idempotencyKey, _encodedSku;
  final String? _encodedReviewCandidate;
  final WorkspaceProductSubmissionRecord? reviewedSource;
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
    'schemaVersion': _encodedReviewCandidate == null ? 1 : 2,
    'accountId': accountId,
    'realm': realm,
    ...body,
    if (reviewedSource != null) 'reviewedSource': reviewedSource!.toJson(),
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
      if (raw['schemaVersion'] == 2) 'reviewCandidate',
      if (raw['schemaVersion'] == 2) 'reviewedSource',
    ]);
    if (raw['schemaVersion'] is! int || !{1, 2}.contains(raw['schemaVersion'])) throw const FormatException();
    return WorkspaceCatalogueBindingIntent(
      accountId: _id(raw['accountId']),
      realm: _string(raw['realm']),
      storeId: _id(raw['storeId']),
      expectedRevision: _int(raw['expectedRevision'], 0, 1000000000),
      idempotencyKey: _id(raw['idempotencyKey']),
      sku: _map(raw['sku']),
      reviewCandidate: raw['schemaVersion'] == 2 ? _map(raw['reviewCandidate']) : null,
      reviewedSource: raw['schemaVersion'] == 2 ? WorkspaceProductSubmissionRecord.decode(raw['reviewedSource'],
        (account: _id(raw['accountId']), store: _id(raw['storeId']), realm: _string(raw['realm']), sku: _id(_map(raw['sku'])['skuId'])),
        _time(_map(raw['reviewedSource'])['submittedAt'])) : null,
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
        'storeId': storeId, 'limit': 20, 'after': ?after}, active, mutation: false);
      if (!active() || response?.statusCode != 200) throw const FormatException();
      final envelope = _map(jsonDecode(response!.body));
      if (envelope['ok'] != true) throw const FormatException();
      final data = _map(envelope['data']);
      _keys(data, ['schemaVersion', 'realm', 'storeId', 'observedAt', 'state', 'coverage',
        'orderingAvailable', 'items', 'nextCursor']);
      final observed = _time(data['observedAt']), now = gateway.now().toUtc();
      if (data['schemaVersion'] is! int || data['schemaVersion'] != 1 || data['realm'] != gateway.realm ||
          data['storeId'] != storeId || data['state'] != 'ready' ||
          data['coverage'] != 'verified_public_promotions_only' || data['orderingAvailable'] != false ||
          observed.isAfter(now)) { throw const FormatException(); }
      var previous = after;
      for (final raw in _list(data['items'], 20)) {
        final row = _map(raw);
        _keys(row, ['publicationId', 'revision', 'publisherType', 'publisherId', 'publisherName',
          'headline', 'detail', 'sourceId', 'observedAt', 'validUntil', 'product']);
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
        final expected = _map(jsonDecode(entry.readback.fingerprint!))..remove('listings');
        expected['channels'] = _list(expected['channels'], 2).map(_map)
          .where((c) => c['kind'] == channel.name).toList();
        final actual = Map<String, dynamic>.of(sku)..remove('supplierPolicy');
        actual['channels'] = [Map<String, dynamic>.of(channelRow)..remove('revision')..remove('validUntil')];
        final expectedMedia = _list(_map(expected['content'])['media'], 10),
          actualMedia = _list(_map(actual['content'])['media'], 10);
        if (expectedMedia.length != actualMedia.length) throw const FormatException();
        for (var index = 0; index < actualMedia.length; index++) {
          final actualFile = _map(_map(actualMedia[index])['file']),
            expectedFile = _map(_map(expectedMedia[index])['file']);
          // Existing public promotion contract omits static-frame negotiation.
          // Only the reviewed default1 may be absent; all media facts still match.
          if (!actualFile.containsKey('frameCount') && expectedFile['frameCount'] == 1) {
            expectedFile.remove('frameCount');
          }
        }
        if (jsonEncode(_sorted(actual)) != jsonEncode(_sorted(expected)) ||
            channelRow['revision'] != entry.product.packTerms?.revision ||
            _time(channelRow['validUntil']) != entry.product.packTerms?.priceValidUntil ||
            expiry.isAfter(entry.product.packTerms!.priceValidUntil!)) { throw const FormatException(); }
        final copy = jsonEncode([source, headline, detail, _sorted(actual)]);
        final head = (revision: revision, observed: itemObserved, copy: copy), old = _promotionHeads[id];
        if (old != null && (revision < old.revision || itemObserved.isBefore(old.observed) ||
            revision == old.revision && copy != old.copy)) { throw const FormatException(); }
        heads[id] = head;
        entries.add(entry);
        results.add(BuyV2PublishedCatalogueOffer(publicationId: id, revision: revision,
          product: entry.product, publisherType: BuyV2OfferPublisherType.retailer, publisherId: storeId,
          publisherName: _string(row['publisherName'], 240), headline: headline, detail: detail,
          sourceId: source, observedAt: itemObserved, validUntil: expiry));
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
      'storeId': storeId, 'cataloguePageVersion': 1, 'query': request, 'pageSize': pageSize,
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
    if (data['cataloguePageVersion'] != 1 || data['schemaVersion'] != 1 || data['realm'] != gateway.realm ||
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
      startIndex: start, totalCount: total, previousCursor: previous, nextCursor: next);
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

/// One authenticated account-generation's public discovery/content owner.
/// Unsupported geography/fulfilment filters require their actual producer.
class WorkspacePublicDiscoverySource extends ChangeNotifier
    implements BuyV2CataloguePageSource, BuyV2VariantFamilySource,
      BuyV2ProductContentAdapter, BuyV2StorePublishedOffersSource {
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
  bool _closed = false;
  bool get active => !_closed && current();
  Iterable<String> get observedProductIds => _readback.observedProductIds;
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
      startIndex: start, totalCount: total, previousCursor: previous, nextCursor: next), stores: List<BuyV2StoreListing>.unmodifiable(stores));
  }

  @override
  Future<BuyV2CataloguePage<BuyV2Product>> loadProducts(BuyV2CatalogueQuery query, {String? cursor, required int pageSize}) async =>
    (await _load(query, cursor: cursor, pageSize: pageSize)).products;
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
    reviewedFamilyReadbackSupported: true, storeClassificationReadbackSupported: true);
  return WorkspacePublicDiscoverySource(gateway: gateway, current: current);
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

WorkspaceCatalogueGateway buildWorkspaceCatalogueGateway() {
  final endpoint = Uri.tryParse(
    const String.fromEnvironment('MOOLSOCIAL_WORKSPACE_URL'),
  );
  if (endpoint == null || !_validEndpoint(endpoint)) {
    return const UnavailableWorkspaceCatalogueGateway();
  }
  return AuthenticatedWorkspaceCatalogueGateway(
    endpoint: endpoint,
    credentials: FirebaseSocialContentCredentials(),
    transport: IoSocialContentTransport(),
    policyReadbackRequired: true,
    productFactsReadbackSupported: const bool.fromEnvironment('MOOLSOCIAL_WORKSPACE_PRODUCT_FACTS_V1'),
    unbrandedProduceReadbackSupported: const bool.fromEnvironment('MOOLSOCIAL_WORKSPACE_UNBRANDED_PRODUCE_V1'),
    reviewedFamilyReadbackSupported: const bool.fromEnvironment('MOOLSOCIAL_WORKSPACE_REVIEWED_FAMILIES_V1'),
    productSubmissionSupported: const bool.fromEnvironment('MOOLSOCIAL_WORKSPACE_PRODUCT_SUBMISSIONS_V1'),
    reviewedProductSubmissionSupported: const bool.fromEnvironment('MOOLSOCIAL_WORKSPACE_PRODUCT_REVIEW_V1'),
    storeClassificationReadbackSupported: const bool.fromEnvironment('MOOLSOCIAL_WORKSPACE_STORE_CLASSIFICATION_V1'),
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
      WorkspaceReviewedProductSubmissionGateway {
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
    this.reviewedProductSubmissionSupported = false,
    this.storeClassificationReadbackSupported = false,
    DateTime Function()? now,
  }) : _reviewedVariantsOverride = reviewedVariants, now = now ?? DateTime.now {
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
  final bool reviewedProductSubmissionSupported;
  final bool storeClassificationReadbackSupported;
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
      reviewedProductSubmissionSupported: reviewedProductSubmissionSupported,
      storeClassificationReadbackSupported: storeClassificationReadbackSupported,
      now: now,
    );
  }

  bool _productSubmissionOwner(WorkspaceProductSubmissionScope scope, bool Function() current) => current() &&
    productSubmissionSupported && scope.realm == realm && ownerAccountId == scope.account;
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
      'productReviewVersion': 1, 'storeId': scope.store, 'skuId': scope.sku}, current, mutation: false);
    if (!_productSubmissionOwner(scope, current) || response?.statusCode != 200) throw const FormatException();
    final envelope = _map(jsonDecode(response!.body)); _keys(envelope, ['ok', 'data']);
    if (envelope['ok'] != true) throw const FormatException();
    final value = _map(envelope['data']);
    if (_int(value['productReviewVersion'], 1, 1) != 1) throw const FormatException();
    final legacy = Map<String, dynamic>.of(value)..remove('productReviewVersion')..remove('review');
    final record = _productSubmissionResponse(legacy, scope, key: null, reconcile: false);
    final readback = WorkspaceProductReviewReadback.decodeReview(value['review'], record, scope, _time(value['observedAt']));
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
