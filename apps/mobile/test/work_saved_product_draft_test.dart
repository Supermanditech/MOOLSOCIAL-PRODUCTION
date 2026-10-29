import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:moolsocial/features/work/work_catalogue_gateway.dart';
import 'package:moolsocial/features/work/work_services.dart';
import 'package:moolsocial/features/shared/social_content_gateway.dart' show SocialContentResponse;
import 'package:moolsocial/features/work/work_models.dart' show WorkspaceCatalogueItem;
import 'package:moolsocial/features/buy/buy_v2_models.dart' show BuyV2OfferClass;
import 'work_catalogue_gateway_test.dart' show listingItem, Credentials, Transport;

final _now = DateTime.utc(2026, 10, 16, 12);
const _scope = (account: 'owner-one', store: 'store-one', realm: 'evaluation', sku: 'sku-one');
WorkspaceProductDraftIntent _intent({int revision = 0, String key = 'host-private-save'}) => WorkspaceProductDraftIntent(
  scope: _scope, expectedRevision: revision, idempotencyKey: key,
  input: WorkspaceProductDraftInput.fromSaved(listingItem()));
Map<String, dynamic> _record(WorkspaceProductDraftIntent intent) => {
  'schemaVersion': 1, 'realm': intent.scope.realm, 'storeId': intent.scope.store, 'skuId': intent.scope.sku,
  'revision': intent.expectedRevision + 1, 'savedAt': _now.toIso8601String(), 'savedBy': intent.scope.account,
  'fingerprint': intent.fingerprint, 'draft': intent.input.toJson(), 'catalogueOrigin': intent.origin?.toJson(),
};
Map<String, dynamic> _response(WorkspaceProductDraftIntent intent, {bool found = true}) => {
  'schemaVersion': 1, 'productDraftVersion': 1, 'actorAccountId': intent.scope.account, 'realm': intent.scope.realm,
  'storeId': intent.scope.store, 'skuId': intent.scope.sku, 'observedAt': _now.toIso8601String(),
  'state': found ? 'saved' : 'not_found', 'record': found ? _record(intent) : null,
};
AuthenticatedWorkspaceCatalogueGateway _gateway(Transport transport, {bool supported = true, bool previewSupported = false, String owner = 'owner-one', Credentials? credentials}) =>
  AuthenticatedWorkspaceCatalogueGateway(endpoint: Uri.parse('https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
    credentials: credentials ?? Credentials(), transport: transport, realm: 'evaluation', ownerAccountId: owner,
    productDraftSupported: supported, productPreviewSupported: previewSupported, now: () => _now);
class _RetiringPreviewCredentials extends Credentials {
  _RetiringPreviewCredentials(this.retire);
  final void Function() retire;
  @override Future<String> firebaseIdToken() async {retire(); return super.firebaseIdToken();}
}
class _RetiringPreviewTransport extends Transport {
  _RetiringPreviewTransport(super.data, this.retire);
  final void Function() retire;
  @override Future<SocialContentResponse> postJson(Uri endpoint, {required Map<String, String> headers,
      required Map<String, Object?> body}) async {
    final response = await super.postJson(endpoint, headers: headers, body: body); retire(); return response;
  }
}
class _Journal implements WorkspaceProductDraftJournal {
  WorkspaceProductDraftIntent? pending;
  bool fail = false;
  @override Future<WorkspaceProductDraftIntent?> readPending(WorkspaceProductSubmissionScope scope) async => pending;
  @override Future<void> savePending(WorkspaceProductDraftIntent original) async {
    if (fail) throw StateError('Host storage unavailable');
    if (pending != null && pending!.idempotencyKey != original.idempotencyKey) throw StateError('Keep original');
    pending = original;
  }
  @override Future<void> removePending(WorkspaceProductDraftIntent original) async {
    if (fail || pending?.idempotencyKey != original.idempotencyKey) throw StateError('Keep original');
    pending = null;
  }
}
class _DraftGateway implements WorkspaceProductDraftGateway {
  _DraftGateway(this.journal);
  final _Journal journal;
  final calls = <({String key, bool reconcile})>[];
  WorkspaceProductDraftWriteState result = WorkspaceProductDraftWriteState.unknown;
  @override bool get productDraftSupported => true;
  @override Future<WorkspaceProductDraftRecord?> readProductDraft(WorkspaceProductSubmissionScope scope,
    {required bool Function() current}) async => null;
  @override Future<WorkspaceProductDraftWriteResult> writeProductDraft(WorkspaceProductDraftIntent original,
      {required bool Function() current, bool reconcile = false}) async {
    expect(journal.pending?.idempotencyKey, original.idempotencyKey, reason: 'Journal must precede every dispatch.');
    if (!current()) return const WorkspaceProductDraftWriteResult(WorkspaceProductDraftWriteState.notSent);
    calls.add((key: original.idempotencyKey, reconcile: reconcile));
    return WorkspaceProductDraftWriteResult(result, result == WorkspaceProductDraftWriteState.saved
      ? WorkspaceProductDraftRecord.decode(_record(original), original.scope, _now) : null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('AGG02 initiating account pin does not alter the retained original journal or fingerprint', () {
    final original = _intent(), stored = original.toJson();
    expect(original.body['actorAccountId'], _scope.account);
    expect(stored.containsKey('actorAccountId'), isFalse);
    final recovered = WorkspaceProductDraftIntent.fromJson(stored);
    expect(recovered.toJson(), stored); expect(recovered.fingerprint, original.fingerprint);
    expect(recovered.body['actorAccountId'], _scope.account);
  });
  test('AGG02 controller journals before Save and never repeats an unknown original automatically', () async {
    final journal = _Journal(), input = _intent().input;
    final gateway = _DraftGateway(journal);
    var active = true;
    WorkspaceProductDraftController create() => WorkspaceProductDraftController(scope: _scope, gateway: gateway,
      journal: journal, current: () => active);
    final first = create();
    expect(await first.load(), isTrue); expect(gateway.calls, isEmpty);
    expect(await first.save(input, idempotencyKey: 'host-original', inputCurrent: () => true), WorkspaceProductDraftWriteState.unknown);
    expect(first.canSave, isFalse); expect(journal.pending!.idempotencyKey, 'host-original');
    expect(await first.save(input, idempotencyKey: 'host-replacement', inputCurrent: () => true), WorkspaceProductDraftWriteState.notSent);
    first.dispose();
    final resumed = create(); expect(await resumed.load(), isTrue); expect(gateway.calls.length, 1);
    expect(await resumed.recover(retryOriginal: true), WorkspaceProductDraftWriteState.notSent);
    gateway.result = WorkspaceProductDraftWriteState.notFound;
    expect(await resumed.recover(), WorkspaceProductDraftWriteState.notFound);
    expect(gateway.calls.last, (key: 'host-original', reconcile: true));
    gateway.result = WorkspaceProductDraftWriteState.saved;
    expect(await resumed.recover(retryOriginal: true), WorkspaceProductDraftWriteState.saved);
    expect(gateway.calls.last, (key: 'host-original', reconcile: false));
    expect(journal.pending, isNull); expect(resumed.record!.revision, 1);
    active = false; expect(await resumed.load(), isFalse);
    resumed.dispose();
  });
  test('AGG02 private Save blocks when storage fails or edited inputs are no longer current', () async {
    final journal = _Journal(), gateway = _DraftGateway(_Journal());
    final controller = WorkspaceProductDraftController(scope: _scope, gateway: gateway, journal: journal, current: () => true);
    expect(await controller.load(), isTrue);
    journal.fail = true;
    await controller.save(_intent().input, idempotencyKey: 'host-storage-failed', inputCurrent: () => true);
    expect(gateway.calls, isEmpty);
    expect(controller.canSave, isFalse);
    journal.fail = false;
    expect(await controller.save(_intent().input, idempotencyKey: 'host-changed', inputCurrent: () => false), WorkspaceProductDraftWriteState.notSent);
    expect(gateway.calls, isEmpty); controller.dispose();
  });
  test('AGG02 secure draft journal is separate from Submit and rejects replacement and account changes', () async {
    FlutterSecureStorage.setMockInitialValues({});
    var account = 'owner-one';
    final journal = SecureWorkProductDraftJournal(currentAccount: () => account);
    final submission = SecureWorkProductSubmissionJournal(currentAccount: () => account);
    final original = _intent();
    await journal.savePending(original);
    expect((await journal.readPending(_scope))!.toJson(), original.toJson());
    expect(await submission.readPending(_scope), isNull);
    await expectLater(journal.savePending(_intent(key: 'another-key')), throwsFormatException);
    await expectLater(journal.removePending(_intent(key: 'another-key')), throwsFormatException);
    account = 'other-owner';
    await expectLater(journal.readPending(_scope), throwsA(isA<WorkGatewayException>()));
    account = 'owner-one'; await journal.removePending(original);
    expect(await journal.readPending(_scope), isNull);
  });
  test('AGG02 preview gateway uses actor-bound read operations and exact original response', () async {
    final path = Platform.environment['AGG02_PREVIEW_ORIGINALS']; expect(path, isNotNull);
    final capture = jsonDecode(File(path!).readAsStringSync()) as Map<String, dynamic>;
    final frame = Map<String, dynamic>.from(capture['saved-draft'] as Map);
    final transport = Transport(Map<String, dynamic>.from(frame['page'] as Map)), credentials = Credentials();
    final gateway = _gateway(transport, previewSupported: true, credentials: credentials).forOwnerAccount(_scope.account);
    expect(gateway.productPreviewSupported, isTrue);
    final page = await gateway.listProductPreviewSources((account: _scope.account, store: _scope.store, realm: _scope.realm),
      WorkspaceProductOriginalKind.savedDraft, current: () => true, limit: 1);
    expect(page.items.single.kind, WorkspaceProductOriginalKind.savedDraft);
    expect(transport.sent!['operation'], 'listStoreProductPreviewSources');
    expect(transport.sent!['actorAccountId'], _scope.account); expect(transport.sent!['realm'], _scope.realm);
    transport.data = Map<String, dynamic>.from(frame['original'] as Map);
    final original = await gateway.readProductPreviewOriginal(_scope, WorkspaceProductOriginalKind.savedDraft,
      current: () => true, expected: page.items.single);
    expect(original!.reference.fingerprint, page.items.single.fingerprint);
    expect(transport.sent!['operation'], 'readStoreProductPreviewOriginal');
    expect(transport.sent!['expectedRevision'], page.items.single.revision);
    expect(transport.sent!['expectedFingerprint'], page.items.single.fingerprint);
    expect(transport.sent!.containsKey('draft'), isFalse); expect(transport.sent!.containsKey('idempotencyKey'), isFalse);
    expect(credentials.modes.map((mode) => mode.name), ['standard', 'standard']);
  });
  test('AGG02 preview gateway rejects disabled or retired accounts before dispatch and drops late replies', () async {
    final path = Platform.environment['AGG02_PREVIEW_ORIGINALS']; expect(path, isNotNull);
    final capture = jsonDecode(File(path!).readAsStringSync()) as Map<String, dynamic>;
    final data = Map<String, dynamic>.from(capture['saved-draft']['original'] as Map);
    for (final make in <AuthenticatedWorkspaceCatalogueGateway Function(Transport)>[
      (transport) => _gateway(transport),
      (transport) => _gateway(transport, previewSupported: true, owner: 'other-owner'),
    ]) {
      final transport = Transport(data);
      await expectLater(make(transport).readProductPreviewOriginal(_scope, WorkspaceProductOriginalKind.savedDraft,
        current: () => true), throwsFormatException);
      expect(transport.sent, isNull);
    }
    var active = true;
    final transport = Transport(data), credentials = _RetiringPreviewCredentials(() => active = false);
    await expectLater(_gateway(transport, previewSupported: true, credentials: credentials)
      .readProductPreviewOriginal(_scope, WorkspaceProductOriginalKind.savedDraft, current: () => active), throwsFormatException);
    expect(transport.sent, isNull);
    active = true;
    final late = _RetiringPreviewTransport(data, () => active = false);
    await expectLater(_gateway(late, previewSupported: true).readProductPreviewOriginal(_scope,
      WorkspaceProductOriginalKind.savedDraft, current: () => active), throwsFormatException);
    expect(late.sent!['operation'], 'readStoreProductPreviewOriginal');
    final foreign = Transport({...data, 'actorAccountId': 'other-owner'});
    await expectLater(_gateway(foreign, previewSupported: true).readProductPreviewOriginal(_scope,
      WorkspaceProductOriginalKind.savedDraft, current: () => true), throwsFormatException);
  });
  test('AGG02 actual repository typed originals preserve record kind and share descriptive projection', () {
    final path = Platform.environment['AGG02_PREVIEW_ORIGINALS'];
    expect(path, isNotNull, reason: 'Use the actual local repository preview export.');
    final capture = jsonDecode(File(path!).readAsStringSync()) as Map<String, dynamic>;
    final originals = <WorkspaceProductOriginalPresentation>[];
    for (final pair in <(String, WorkspaceProductOriginalKind)>[
      ('catalogue-sku', WorkspaceProductOriginalKind.catalogueSku),
      ('submitted-original', WorkspaceProductOriginalKind.submittedOriginal),
      ('saved-draft', WorkspaceProductOriginalKind.savedDraft),
    ]) {
      final frame = Map<String, dynamic>.from(capture[pair.$1] as Map);
      final raw = Map<String, dynamic>.from(frame['original'] as Map);
      final page = Map<String, dynamic>.from(frame['page'] as Map);
      final reference = WorkspaceProductPreviewReference.decode((page['items'] as List).single);
      final checked = WorkspaceProductPreviewOriginal.decode(raw, _scope, pair.$2, _now, expected: reference)!;
      expect(checked.reference.kind, pair.$2); expect(checked.reference.revision, 1);
      final presentation = checked.presentation(storeName: 'Host original Store', channel: BuyV2OfferClass.retail);
      originals.add(presentation);
      expect(presentation.kind, pair.$2); expect(presentation.fingerprint, reference.fingerprint);
      expect(presentation.product.title, reference.title); expect(presentation.product.pack, reference.pack);
      expect(presentation.product.publicListingIdentity, isNull); expect(presentation.product.catalogueListing, isFalse);
      expect(presentation.product.deliveryPromise, isEmpty); expect(presentation.product.returnPolicy, isNull);
      if (pair.$2 == WorkspaceProductOriginalKind.catalogueSku) {
        expect(presentation.original, isA<WorkspaceCatalogueOwnedSku>());
        expect(presentation.product.canonicalId, 'canonical-one');
      } else {
        expect(presentation.product.canonicalId, isEmpty);
        expect(presentation.original, pair.$2 == WorkspaceProductOriginalKind.submittedOriginal
          ? isA<WorkspaceProductSubmissionRecord>() : isA<WorkspaceProductDraftRecord>());
      }
    }
    expect(originals.map((view) => view.product.id).toSet().length, 3);
    expect(originals.map((view) => view.fingerprint).toSet().length, 3);
  });
  test('AGG02 typed original decoder rejects wrong source, scope, stale metadata and altered summary', () {
    final path = Platform.environment['AGG02_PREVIEW_ORIGINALS']; expect(path, isNotNull);
    final capture = jsonDecode(File(path!).readAsStringSync()) as Map<String, dynamic>;
    final frame = Map<String, dynamic>.from(capture['saved-draft'] as Map);
    final raw = Map<String, dynamic>.from(frame['original'] as Map);
    final reference = WorkspaceProductPreviewReference.decode((frame['page']['items'] as List).single);
    Map<String, dynamic> copy() => Map<String, dynamic>.from(jsonDecode(jsonEncode(raw)) as Map);
    for (final mutate in <void Function(Map<String, dynamic>)>[
      (v) => v['actorAccountId'] = 'other-owner', (v) => v['realm'] = 'production', (v) => v['storeId'] = 'other-store', (v) => v['skuId'] = 'other-sku',
      (v) => v['kind'] = 'submitted-original', (v) => v['reference']['kind'] = 'catalogue-sku',
      (v) => v['reference']['title'] = 'Not the original title',
      (v) => v['record'] = capture['submitted-original']['original']['record'],
      (v) => v['record']['draft']['content']['title'] = 'Altered original body',
      (v) => v['observedAt'] = _now.subtract(const Duration(minutes: 6)).toIso8601String(),
    ]) {
      final changed = copy(); mutate(changed);
      expect(() => WorkspaceProductPreviewOriginal.decode(changed, _scope, WorkspaceProductOriginalKind.savedDraft,
        _now, expected: reference), throwsFormatException);
    }
    final foreignReference = WorkspaceProductPreviewReference.decode((capture['submitted-original']['page']['items'] as List).single);
    expect(() => WorkspaceProductPreviewOriginal.decode(raw, _scope, WorkspaceProductOriginalKind.savedDraft,
      _now, expected: foreignReference), throwsFormatException);
    final none = copy()..['state'] = 'none'..['reference'] = null..['record'] = null;
    expect(WorkspaceProductPreviewOriginal.decode(none, _scope, WorkspaceProductOriginalKind.savedDraft, _now), isNull);
    expect(() => WorkspaceProductPreviewOriginal.decode(none, _scope, WorkspaceProductOriginalKind.savedDraft,
      _now, expected: reference), throwsFormatException);
  });
  test('AGG02 actual repository master page and private Save are accepted by the mobile boundary', () async {
    final path = Platform.environment['AGG02_ORIGINAL_RESPONSES'];
    expect(path, isNotNull, reason: 'Run with the isolated original-repository export; do not fabricate a successful source.');
    final capture = jsonDecode(File(path!).readAsStringSync()) as Map<String, dynamic>;
    const scope = (account: 'owner-two', store: 'store-two', realm: 'evaluation');
    final page = WorkspaceMasterCataloguePage.decode(capture['page'], scope, _now, search: '', code: null, pageSize: 1);
    expect(page.items.single.title, 'Host fixture oil');
    expect(page.items.single.toJson().containsKey('channels'), isFalse);
    expect(page.nextCursor, isNotNull);
    final blank = WorkspaceCatalogueItem(id: 'local-new', canonicalId: '', categoryId: 'grocery', brand: '', title: '',
      variant: '', pack: '', sku: 'LOCAL-NEW', barcode: '', purchasePrice: 0, sellingPrice: 0, stock: 0,
      unitPrice: '', deliveryPromise: '', origin: '', visualLabel: '', visualKind: '', publicListing: false, retailEnabled: false);
    final prepared = page.items.single.prepareNewStoreDraft(blank);
    expect(prepared.id, 'local-new'); expect(prepared.sku, 'LOCAL-NEW');
    expect(prepared.title, page.items.single.title); expect(prepared.pack, page.items.single.packLabel);
    expect(prepared.stock, 0); expect(prepared.retailEnabled, isFalse); expect(prepared.publicListing, isFalse);
    expect(WorkspaceProductDraftInput.fromSaved(prepared).toJson()['channels'], isEmpty);
    expect(() => page.items.single.prepareNewStoreDraft(listingItem()), throwsFormatException);
    final request = Map<String, dynamic>.from(capture['body'] as Map);
    final input = WorkspaceProductDraftInput.fromJson(request['draft']);
    final intent = WorkspaceProductDraftIntent(scope: (account: scope.account, store: scope.store, realm: scope.realm, sku: input.skuId),
      expectedRevision: request['expectedRevision'] as int, idempotencyKey: request['idempotencyKey'] as String,
      input: input, origin: WorkspaceMasterCatalogueOrigin.fromJson(request['catalogueOrigin']));
    final saved = WorkspaceProductDraftRecord.decode(capture['saved']['record'], intent.scope, _now);
    expect(saved.matches(intent), isTrue);
    final transport = Transport(Map<String, dynamic>.from(capture['page'] as Map));
    final gateway = AuthenticatedWorkspaceCatalogueGateway(
      endpoint: Uri.parse('https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
      credentials: Credentials(), transport: transport, realm: 'evaluation', ownerAccountId: 'owner-two',
      masterCatalogueSupported: true, now: () => _now);
    expect((await gateway.readMasterCatalogue(scope, current: () => true, pageSize: 1)).items.single.title, page.items.single.title);
    expect(transport.sent!['operation'], 'readStoreMasterCatalogue');
    expect(transport.sent!.containsKey('draft'), isFalse);
    for (final edit in <void Function(Map<String, dynamic>)>[
      (v) => v['storeId'] = 'other-store',
      (v) => v['realm'] = 'production',
      (v) => v['query']['search'] = 'unrelated search',
      (v) => v['items'][0]['content']['title'] = 'Changed source title',
      (v) => v['items'][0]['pack']['quantityMilli'] = 2500,
      (v) => v['items'][0]['channels'] = [],
      (v) => v['items'][0]['mediaIncluded'] = true,
      (v) => v['missingSourceCount'] = 2,
    ]) {
      final broken = jsonDecode(jsonEncode(capture['page'])) as Map<String, dynamic>; edit(broken);
      expect(() => WorkspaceMasterCataloguePage.decode(broken, scope, _now, search: '', code: null, pageSize: 1), throwsFormatException);
    }
    final latest = jsonDecode(jsonEncode(capture['page'])) as Map<String, dynamic>;
    latest['items'][0]['selectionId'] = '';
    expect(() => WorkspaceMasterCataloguePage.decode(latest, scope, _now, search: '', code: null, pageSize: 1), throwsFormatException);
  }, skip: Platform.environment['AGG02_ORIGINAL_RESPONSES'] == null ? 'Requires the isolated original-repository export.' : false);
  test('AGG02 private original Retail, Wholesale, Bulk and unknown-pack presentation preserves source facts without public claims', () {
    final capture = jsonDecode(File(Platform.environment['AGG02_ORIGINAL_RESPONSES']!).readAsStringSync()) as Map<String, dynamic>;
    expect(capture['presentations'], isNotEmpty);
    for (final raw in capture['presentations'] as List) {
      final row = Map<String, dynamic>.from(raw as Map), response = Map<String, dynamic>.from(row['response'] as Map);
      final source = Map<String, dynamic>.from(response['record'] as Map), input = Map<String, dynamic>.from(source['draft'] as Map);
      final scope = (account: 'owner-two', store: 'store-two', realm: 'evaluation', sku: source['skuId'] as String);
      final record = WorkspaceProductDraftRecord.decode(source, scope, _now);
      for (final rawTerms in input['channels'] as List) {
        final terms = Map<String, dynamic>.from(rawTerms as Map), channel = BuyV2OfferClass.values.firstWhere((kind) => kind.name == terms['kind']);
        final view = WorkspaceProductDraftPresentation.fromRecord(record, scope, storeName: 'Host recipient Store', channel: channel);
        expect(view.product.title, input['content']['title']); expect(view.product.brand, input['content']['brand']);
        expect(view.product.pack, input['pack']['label']); expect(view.product.priceMinor, terms['priceMinor']);
        expect(view.product.mrpMinor, terms['mrpMinor']); expect(view.product.minimumOrder, terms['minimumOrder']);
        expect(view.content.description, input['content']['description']);
        expect(view.content.sourceId, contains(record.fingerprint));
        expect(view.product.publicListingIdentity, isNull); expect(view.product.canonicalId, isEmpty);
        expect(view.product.badge, isEmpty); expect(view.product.unitPrice, isEmpty); expect(view.product.confirmedOn, isEmpty);
        expect(view.product.deliveryPromise, isEmpty); expect(view.product.returnPolicy, isNull); expect(view.product.purchaseProtection, isNull);
        expect(view.content.media, isEmpty); expect(view.product.mediaAssets, isEmpty);
        if (row['type'] == 'unknown-pack' || row['type'] == 'unknown-wholesale' && channel == BuyV2OfferClass.retail) {
          expect(view.product.packTerms, isNull);
        } else {
          expect(view.product.quantityStep, terms['quantityStep']);
          if (row['type'] == 'unknown-wholesale') {
            expect(input['pack']['quantityMilli'], isNull); expect(input['pack']['unitsPerCase'], isNull);
            expect(view.product.packTerms!.netContentMilli, isNull); expect(view.product.packTerms!.contentUnit, isNull);
            expect(view.product.hasValidPackTerms, isFalse, reason: 'A private preview cannot manufacture a verified pack or current trade quote.');
          }
          expect(view.product.packTerms!.priceObservedAt, isNull); expect(view.product.packTerms!.priceValidUntil, isNull);
          expect(view.product.packTerms!.priceTiers.map((tier) => tier.priceMinor),
            (terms['tiers'] as List).map((tier) => tier['unitPriceMinor']));
        }
      }
    }
  }, skip: Platform.environment['AGG02_ORIGINAL_RESPONSES'] == null ? 'Requires isolated original-repository draft records.' : false);
  test('AGG02 private Save retains text-only packs while Submit remains strict', () {
    final item = listingItem().copyWith(clearPackMeasure: true);
    final saved = WorkspaceProductDraftInput.fromSaved(item).toJson();
    expect(saved['pack']['quantityMilli'], isNull);
    expect(saved['pack']['unit'], isNull);
    expect(saved['pack']['unitsPerCase'], isNull);
    expect(saved['pack']['label'], item.pack);
    expect(() => WorkspaceProductSubmissionInput.fromJson(saved), throwsFormatException);
    final noChannels = Map<String, dynamic>.from(saved)..['channels'] = []..['provenance'] = null;
    expect(WorkspaceProductDraftInput.fromJson(noChannels).toJson(), noChannels);
    for (final key in ['quantityMilli', 'unit', 'unitsPerCase']) {
      final broken = jsonDecode(jsonEncode(saved)) as Map<String, dynamic>;
      broken['pack'][key] = key == 'unit' ? 'L' : 1;
      expect(() => WorkspaceProductDraftInput.fromJson(broken), throwsFormatException);
    }
  });
  test('AGG02 private record verifies exact fields, source revision and namespace', () {
    final authored = _intent().input.toJson();
    authored['channels'][0]['priceMinor'] = 900000000; authored['channels'][0]['mrpMinor'] = 1000000000;
    authored['pack']['quantityMilli'] = 999999999; authored['pack']['unitsPerCase'] = 999999;
    expect(WorkspaceProductDraftInput.fromJson(authored).toJson(), authored);
    expect(() => WorkspaceProductSubmissionInput.fromJson(authored), throwsFormatException);
    final intent = _intent(), record = _record(_intent());
    expect(WorkspaceProductDraftRecord.decode(record, _scope, _now).matches(intent), isTrue);
    for (final edit in <void Function(Map<String, dynamic>)>[
      (v) => v['draft']['content']['title'] = 'Changed response',
      (v) => v['revision'] = 2,
      (v) => v['storeId'] = 'other-store',
      (v) => v['savedAt'] = _now.add(const Duration(seconds: 1)).toIso8601String(),
      (v) => v['publicListing'] = true,
    ]) {
      final broken = jsonDecode(jsonEncode(record)) as Map<String, dynamic>; edit(broken);
      expect(() => WorkspaceProductDraftRecord.decode(broken, _scope, _now), throwsFormatException);
    }
    final restored = WorkspaceProductDraftIntent.fromJson(intent.toJson());
    expect(restored.fingerprint, intent.fingerprint);
    expect(restored.body, intent.body);
  });
  test('AGG02 original private Save and read-only reconcile use separate endpoints and exact acknowledgement', () async {
    final intent = _intent(), transport = Transport(_response(_intent())), credentials = Credentials();
    final gateway = _gateway(transport, credentials: credentials);
    final saved = await gateway.writeProductDraft(intent, current: () => true);
    expect(saved.state, WorkspaceProductDraftWriteState.saved);
    expect(saved.record!.matches(intent), isTrue);
    expect(transport.sent!['operation'], 'saveStoreProductDraft');
    expect(transport.sent!.containsKey('productSubmissionVersion'), isFalse);
    await gateway.writeProductDraft(intent, current: () => true, reconcile: true);
    expect(transport.sent!['operation'], 'reconcileStoreProductDraft');
    await gateway.readProductDraft(_scope, current: () => true);
    expect(transport.sent!['operation'], 'readStoreProductDraft');
    expect(transport.sent!.containsKey('draft'), isFalse);
    expect(credentials.modes.length, 3);
  });
  test('AGG02 disabled, switched and stale owners do not dispatch private Save', () async {
    for (final gatewayFactory in <AuthenticatedWorkspaceCatalogueGateway Function(Transport)>[
      (t) => _gateway(t, supported: false), (t) => _gateway(t, owner: 'other-owner'),
    ]) {
      final t = Transport(_response(_intent()));
      expect((await gatewayFactory(t).writeProductDraft(_intent(), current: () => true)).state, WorkspaceProductDraftWriteState.notSent);
      expect(t.sent, isNull);
    }
    final t = Transport(_response(_intent()));
    expect((await _gateway(t).writeProductDraft(_intent(), current: () => false)).state, WorkspaceProductDraftWriteState.notSent);
    expect(t.sent, isNull);
  });
  test('AGG02 unconfirmed dispatch remains unknown; reconcile never recreates a missing Save', () async {
    final t = Transport(_response(_intent()))..fail = true;
    final gateway = _gateway(t), intent = _intent();
    expect((await gateway.writeProductDraft(intent, current: () => true)).state, WorkspaceProductDraftWriteState.unknown);
    t.fail = false; t.data = _response(intent, found: false);
    expect((await gateway.writeProductDraft(intent, current: () => true, reconcile: true)).state, WorkspaceProductDraftWriteState.notFound);
    expect(t.sent!['operation'], 'reconcileStoreProductDraft');
    expect((await gateway.writeProductDraft(intent, current: () => true)).state, WorkspaceProductDraftWriteState.unknown);
  });
}
