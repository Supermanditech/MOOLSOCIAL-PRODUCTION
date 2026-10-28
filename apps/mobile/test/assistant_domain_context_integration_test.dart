import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moolsocial/features/assistant/domain_context_gateway.dart';
import 'package:moolsocial/features/assistant/mool_assistant.dart';
import 'package:moolsocial/features/assistant/profile_context.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:crypto/crypto.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_saved_products_store.dart';
import 'package:moolsocial/features/work/work_catalogue_gateway.dart';
import 'package:moolsocial/features/shared/social_content_gateway.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_views.dart' show BuyBrowseNativeAdapter;
import 'package:moolsocial/features/work/widgets/workspace_purchase_originals.dart' show WorkspaceBulkQuotes;
import 'ui_v2/buy/buy_v2_screen_test.dart' show FixtureShop06HostRig;
import 'package:moolsocial/features/journey01/journey_services.dart' show AuthenticatedAccountIdentity;
import 'package:moolsocial/features/work/screens/work_workspace_dashboard_screen.dart' show StoreProductInitialData, StoreProductDefaultsInitialData, StoreProductNativeInitial;
import 'package:moolsocial/features/work/work_publication_data.dart' show WorkspaceProductContent;

const _port = int.fromEnvironment('AI_DOMAIN_TEST_PORT');
const _storeExport = String.fromEnvironment('AI_DOMAIN_STORE_NATIVE_EXPORT_PATH');
const _owner = (environment: 'firebase-service', projectId: 'fixture-project', tenantId: null, userId: 'domain-host-a');
class _RealLoopback extends HttpOverrides {}
HttpClient _client() => HttpOverrides.runWithHttpOverrides(() => HttpClient(), _RealLoopback());
class _Credentials implements SocialContentCredentials {
  @override Future<String> firebaseIdToken() async => 'isolated-host-token';
  @override Future<String> appCheckToken(SocialAppCheckTokenMode mode) async {
    expect(mode, SocialAppCheckTokenMode.standard); return 'isolated-host-proof';
  }
}
class _Transport implements SocialContentTransport {
  _Transport() : client = _client();
  final HttpClient client;
  Completer<void>? returned;
  @override Future<SocialContentResponse> postJson(Uri endpoint, {required Map<String, String> headers,
      required Map<String, Object?> body}) async {
    final result = await IoSocialContentTransport(client: client, followRedirects: false,
      maximumResponseBytes: 256 * 1024).postJson(Uri.http('127.0.0.1:$_port', endpoint.path), headers: headers, body: body);
    if (returned != null && !returned!.isCompleted) returned!.complete();
    return result;
  }
}
Future<Map<String, Object?>> _control(String query) async {
  final client = _client();
  try {
    final response = await (await client.getUrl(Uri.parse('http://127.0.0.1:$_port/__fixture__?$query'))).close();
    expect(response.statusCode, 200);
    return Map<String, Object?>.from(jsonDecode(await response.transform(utf8.decoder).join()) as Map);
  } finally {client.close(force: true);}
}
class _Observer extends NavigatorObserver {
  Completer<void>? pushed;
  @override void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (pushed != null && !pushed!.isCompleted) pushed!.complete();
    super.didPush(route, previousRoute);
  }
}
Future<void> _frames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump(const Duration(milliseconds: 350));
}
class _Rig {
  final context = ValueNotifier(const MoolAssistantContext(accountScope: _owner, authenticationRevision: 1));
  final core = BuySession();
  late final buy = BuyV2Session(core: core, reviewDataEnabled: false);
  final navigator = GlobalKey<NavigatorState>(), observer = _Observer();
  final wire = _Transport();
  late final source = AssistantDomainContextGateway(owner: _owner, isCurrent: () => current,
    credentials: _Credentials(), transport: wire);
  bool current = true;
  late final native = BuySearchNativeAdapter(session: buy, navigator: navigator.currentState!,
    currentContext: () => context.value, isRootCurrent: () => current, scopeOwner: context,
    accountIdentity: () => null, accountAuthenticated: () => true);
  late final guard = AssistantProfileContextGuard(readCanonical: source.read,
    readContext: () => context.value, ownerChanges: context, nativeAdapters: [native],
    canonicalActions: assistantDomainContextActions, recoverableActions: assistantDomainContextActions);
  Future<void> mount(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({}); FlutterSecureStorage.setMockInitialValues({});
    tester.view.devicePixelRatio = 1; tester.view.physicalSize = const Size(412, 915);
    await tester.pumpWidget(MaterialApp(navigatorKey: navigator, navigatorObservers: [observer],
      home: const Scaffold(body: Text('Original Buy owner'))));
    await tester.runAsync(() => guard.capture(context.value, () => current));
  }
  Future<MoolAssistantProposal> proposal() async {
    final snapshot = await guard.adapters.single.snapshot(context.value, null);
    expect(snapshot, isNotNull);
    // Explicit host proposal fixture. It is not model execution or consent.
    return MoolAssistantProposal(id: 'host-product-search', actionId: 'AI-ACT-001', binding: context.value.binding,
      requestRevision: 1, entitlementRevision: 'host-paid-source', validUntil: DateTime.now().add(const Duration(seconds: 30)),
      sourceRevision: snapshot!.sourceRevision, title: 'Review search', summary: 'Isolated host case', fields: {'query': 'चावल'});
  }
  Future<void> close(WidgetTester tester) async {
    debugPrint('DOMAIN-HOST closing owned fixture');
    current = false; guard.dispose(); source.dispose(); wire.client.close(force: true);
    await tester.pumpWidget(const SizedBox.shrink()); buy.dispose(); core.dispose(); context.dispose(); tester.view.reset();
    debugPrint('DOMAIN-HOST owned fixture closed');
  }
}
void main() {
  const retainedQuoteExport = String.fromEnvironment('AI_DOMAIN_RETAINED_QUOTE_EXPORT_PATH');
  for (final action in ['AI-ACT-348', 'AI-ACT-349']) {
    testWidgets('Retained quote native Review $action uses original controls and closing has no effect', (tester) async {
      SharedPreferences.setMockInitialValues({}); FlutterSecureStorage.setMockInitialValues({});
      tester.view.devicePixelRatio = 1; tester.view.physicalSize = const Size(412, 915);
      final original = await _RetainedQuoteRig.create(retainedQuoteExport);
      final native = FixtureShop06HostRig(original.buy, user: original.user);
      try {
        await native.mount(tester, view: BuyV2View.cart);
        final before = original.buy.selectedSupplierQuotes.single.quoteBinding, writes = original.store.writes, reads = original.wire.reads;
        await native.start(tester, action, entity: original.quote.quoteId);
        if (action == 'AI-ACT-348') {
          expect(find.byTooltip('Remove selected supplier quote'), findsOneWidget);
        } else {
          final viewer = tester.widget<WorkspaceBulkQuotes>(find.byType(WorkspaceBulkQuotes));
          expect(viewer.readOnlyQuote!.toJson(), original.quote.toJson()); expect(viewer.onUseForCart, isNull);
          expect(viewer.request, isNull); expect(find.text('Accept offer'), findsNothing);
        }
        expect(original.store.writes, writes); expect(original.journal.writes, 0); expect(original.wire.reads, reads);
        await native.close(tester);
        expect(original.buy.selectedSupplierQuotes.single.quoteBinding, before);
        expect(original.store.writes, writes); expect(original.journal.writes, 0);
        expect(tester.takeException(), isNull);
      } finally {await native.dispose(tester); original.dispose(); tester.view.reset();}
    }, skip: retainedQuoteExport.isEmpty);
  }
  for (final retire in [false, true]) {
    testWidgets('Retained quote native Remove requires current final tap; retired=$retire', (tester) async {
      SharedPreferences.setMockInitialValues({}); FlutterSecureStorage.setMockInitialValues({});
      tester.view.devicePixelRatio = 1; tester.view.physicalSize = const Size(412, 915);
      final original = await _RetainedQuoteRig.create(retainedQuoteExport);
      final native = FixtureShop06HostRig(original.buy, user: original.user);
      try {
        await native.mount(tester, view: BuyV2View.cart);
        final writes = original.store.writes, reads = original.wire.reads;
        await native.start(tester, 'AI-ACT-348', entity: original.quote.quoteId);
        if (retire) {
          native.retire(); await tester.pumpAndSettle();
          final remove = find.byTooltip('Remove selected supplier quote');
          if (remove.evaluate().isNotEmpty) expect(tester.widget<IconButton>(remove).onPressed, isNull);
          expect(original.buy.selectedSupplierQuotes, hasLength(1)); expect(original.store.writes, writes);
        } else {
          await native.tap(tester, find.byTooltip('Remove selected supplier quote'));
          await native.review;
          expect(original.buy.selectedSupplierQuotes, isEmpty); expect(original.store.writes, writes + 1);
          expect(original.store.snapshot.supplierQuoteSelections, isEmpty);
        }
        expect(original.wire.reads, reads); expect(original.journal.writes, 0);
        expect(original.access.forStore(original.quote.storeId).head(original.quote.quoteId)!.toJson(), original.quote.toJson());
        expect(tester.takeException(), isNull);
      } finally {await native.dispose(tester); original.dispose(); tester.view.reset();}
    }, skip: retainedQuoteExport.isEmpty);
  }
  test('Retained quote native preparation reads the original without adopting a head, writing or replaying a journal', () async {
    final rig = await _RetainedQuoteRig.create(retainedQuoteExport);
    addTearDown(rig.dispose);
    final before = rig.buy.selectedSupplierQuotes.single.quoteBinding;
    final ready = await rig.read();
    expect(ready, rig.expected.keys.toSet());
    expect(rig.wire.reads, 2); // One explicit native setup refresh, one AI read.
    expect(rig.journal.writes, 0); expect(rig.store.writes, 0);
    expect(rig.buy.selectedSupplierQuotes.single.quoteBinding, before);
    expect(rig.access.forStore(rig.quote.storeId).head(rig.quote.quoteId)!.toJson(), rig.quote.toJson());
    expect(await rig.read(proof: 'buyer-retained-quote:evaluation:${'0' * 64}'), isEmpty);
    expect(rig.journal.writes, 0); expect(rig.store.writes, 0);
  }, skip: retainedQuoteExport.isEmpty ? 'Requires isolated original-service record export' : false);
  test('Retained quote native preparation never hydrates an uninitialised controller or adopts a missing head', () async {
    final cold = await _RetainedQuoteRig.create(retainedQuoteExport, initialise: false, refresh: false);
    addTearDown(cold.dispose);
    expect(await cold.read(), isEmpty); expect(cold.wire.reads, 0);
    expect(cold.access.forStore(cold.quote.storeId).initialized, false);
    final noHead = await _RetainedQuoteRig.create(retainedQuoteExport, refresh: false);
    addTearDown(noHead.dispose);
    expect(await noHead.read(), {('AI-ACT-348', noHead.quote.quoteId)});
    expect(noHead.access.forStore(noHead.quote.storeId).head(noHead.quote.quoteId), isNull);
    expect(noHead.store.writes, 0); expect(noHead.journal.writes, 0);
  }, skip: retainedQuoteExport.isEmpty ? 'Requires isolated original-service record export' : false);
  test('Retained quote native preparation rejects pending recovery, account changes, retirement and Cart navigation', () async {
    final rig = await _RetainedQuoteRig.create(retainedQuoteExport);
    addTearDown(rig.dispose);
    rig.journal.pending = [rig.pendingIntent];
    expect(await rig.read(), isEmpty); expect(rig.wire.reads, 1);
    expect(rig.journal.pending.single.fingerprint, rig.pendingIntent.fingerprint);
    rig.journal.pending = [];
    rig.store.owner = 'HOST-other-account'; expect(await rig.read(), isEmpty); expect(rig.wire.reads, 1);
    rig.store.owner = 'HOST-retained-owner';
    rig.wire.onRead = () {rig.current = false;};
    expect(await rig.read(), isEmpty); expect(rig.journal.writes, 0); expect(rig.store.writes, 0);
    final edited = await _RetainedQuoteRig.create(retainedQuoteExport);
    addTearDown(edited.dispose);
    edited.wire.onRead = () {edited.buy.openCart(scope: BuyV2CartScope.wholesale);};
    expect(await edited.read(), isEmpty);
    expect(edited.buy.cartScope, BuyV2CartScope.wholesale);
    expect(edited.buy.cartLines.single.quantity, 10);
    expect(edited.journal.writes, 0);
  }, skip: retainedQuoteExport.isEmpty ? 'Requires isolated original-service record export' : false);
  test('Domain actual owned-source backend proposal maps to the original Store editor field contract', () async {
    final data = jsonDecode(await File(_storeExport).readAsString()) as Map<String, dynamic>;
    expect(data['schemaVersion'], 1); expect(data['hostOnly'], true); expect(data['noDomainWrites'], true);
    expect((data['nativeTextFields'] as List).toSet(), StoreProductInitialData.editableFields,
      reason: 'Backend suggestions must use the existing native controllers, without invented or omitted field names.');
    final reply = data['reply'] as Map<String, dynamic>, proposal = reply['outcome'] as Map<String, dynamic>;
    expect(reply['scope'], {'audience': 'workspace', 'storeId': 'store-one'});
    expect(proposal['kind'], 'proposal'); expect(proposal['actionId'], 'AI-ACT-214'); expect(proposal['entityId'], 'owned-sku-0002');
    final fields = Map<String, Object?>.from(proposal['fields'] as Map);
    final native = StoreProductInitialData.fromFields(fields);
    expect(native.sourceCanonicalId, 'canonical-one'); expect(native.sourceSku, 'OWNED-2'); expect(native.sourcePack, '1 L');
    expect(native.sourceRetailEnabled, true); expect(native.sourceWholesaleEnabled, false);
    expect(native.inputs, {'description': 'मूल उत्पाद की जानकारी', 'sellingPrice': '100.25'});
    expect(native.inputs.containsKey('stock'), false); expect(native.inputs.containsKey('purchasePrice'), false);
    fields['description'] = 'Changed after parsing';
    expect(native.inputs['description'], 'मूल उत्पाद की जानकारी');
    expect(() => native.inputs.clear(), throwsUnsupportedError);
    expect(() => StoreProductInitialData.fromFields({...fields, 'ownerUserId': 'foreign'}), throwsFormatException);
    expect((data['nativeDefaultFields'] as List).toSet(), StoreProductDefaultsInitialData.allowedFields);
    final defaults = StoreProductDefaultsInitialData.fromFields(Map<String, Object?>.from(data['defaultsInput'] as Map));
    expect(defaults.fields, {'lowStockThreshold': '0005', 'customerListingRequested': false});
    expect(defaults.fields.containsKey('stockMode'), false);
    expect(() => defaults.fields.clear(), throwsUnsupportedError);
      expect((data['nativeWarrantyLabels'] as List).toSet(), WorkspaceProductContent.warrantyGuideLabels.toSet());
      final warranty = StoreProductNativeInitial.fromFields('AI-ACT-370', Map<String, Object?>.from(data['warrantyInput'] as Map));
      expect(warranty.warranty, {'Warranty issuer': 'मूल निर्माता', 'Warranty duration': '12 महीने', 'Warranty exclusions': ''});
      expect(() => warranty.warranty.clear(), throwsUnsupportedError);
      final confirmation = StoreProductNativeInitial.fromFields('AI-ACT-220', Map<String, Object?>.from(data['priceConfirmationInput'] as Map));
      expect(confirmation.validityMinutes, '00030');
      expect(confirmation.references['sourceWholesaleEnabled'], true);
      expect(StoreProductNativeInitial.fromFields('AI-ACT-372', {}).references, isEmpty);
  }, skip: _storeExport.isEmpty);
  testWidgets('Native saved-products action rejects absent owned persistence instead of showing a false empty list', (tester) async {
    const actorContext = MoolAssistantContext(accountScope: _owner, authenticationRevision: 1);
    final core = BuySession(), scope = ValueNotifier(0), navigator = GlobalKey<NavigatorState>();
    final buy = BuyV2Session(core: core, reviewDataEnabled: false);
    try {
      await tester.pumpWidget(MaterialApp(navigatorKey: navigator, home: const Scaffold(body: Text('Original owner'))));
      final adapter = BuyBrowseNativeAdapter(actionId: 'AI-ACT-010', session: buy,
        navigator: navigator.currentState!, currentContext: () => actorContext, isRootCurrent: () => true,
        scopeOwner: scope, accountAuthenticated: () => true, accountIdentity: () => const AuthenticatedAccountIdentity(
          firebaseProjectId: 'fixture-project', firebaseUserId: 'domain-host-a'));
      expect(buy.customerStateStore, isNull);
      expect(await adapter.snapshot(actorContext, null), isNull);
      expect(find.text('Original owner'), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink()); buy.dispose(); core.dispose(); scope.dispose();
    }
  });
  testWidgets('Domain actual gateway HTTP original services and guard prefill original Buy search without submitting', (tester) async {
    await tester.runAsync(() => _control('reset=1')); final rig = _Rig();
    try {
      await rig.mount(tester); debugPrint('DOMAIN-HOST original context captured');
      final p = (await tester.runAsync(rig.proposal))!;
      rig.observer.pushed = Completer<void>();
      late Future<MoolAssistantReviewResult> opening;
      await tester.runAsync(() async {
        rig.wire.returned = Completer<void>();
        opening = rig.guard.adapters.single.openReview(p, () => rig.current);
        await rig.wire.returned!.future.timeout(const Duration(seconds: 10));
        // Flush real-zone network continuations before driving Flutter frames.
        // Navigator observer delivery itself may require a fake-clock frame.
        await Future<void>.delayed(Duration.zero);
      });
      debugPrint('DOMAIN-HOST original review route pushed');
      await _frames(tester); expect(find.byType(BuyV2Screen), findsOneWidget);
      expect(rig.observer.pushed!.isCompleted, true);
      expect(tester.widgetList<EditableText>(find.byType(EditableText)).any((w) => w.controller.text == 'चावल'), true);
      expect(rig.buy.query, isEmpty, reason: 'Review cannot submit the original search or any order.');
      debugPrint('DOMAIN-HOST actual editable search prefill inspected');
      rig.navigator.currentState!.pop(); await _frames(tester);
      // The original search opens its own overlay above its Buy page. Close
      // that owned overlay and then the owned page, without submitting either.
      if (rig.navigator.currentState!.canPop()) {
        expect(find.byType(BuyV2Screen), findsOneWidget);
        rig.navigator.currentState!.pop(); await _frames(tester);
      }
      expect(find.byType(BuyV2Screen), findsNothing);
      expect(find.text('Original Buy owner'), findsOneWidget);
      await tester.runAsync(() => opening.timeout(const Duration(seconds: 10)));
      debugPrint('DOMAIN-HOST original review returned');
      final counts = (await tester.runAsync(() => _control('')))!;
      expect(counts['writes'], 0); expect(counts['modelCalls'], 0); expect(counts['domainEffects'], 0);
      expect(tester.takeException(), isNull);
    } finally {await rig.close(tester);}
  }, skip: _port == 0, timeout: const Timeout(Duration(seconds: 45)));
  testWidgets('Domain actual paid withdrawal before Review cannot open the native form', (tester) async {
    await tester.runAsync(() => _control('reset=1')); final rig = _Rig();
    try {
      await rig.mount(tester); final p = (await tester.runAsync(rig.proposal))!;
      await tester.runAsync(() => _control('deny=1'));
      await tester.runAsync(() async {
        await expectLater(rig.guard.adapters.single.openReview(p, () => rig.current), throwsA(anything));
      });
      await _frames(tester); expect(find.byType(BuyV2Screen), findsNothing); expect(rig.buy.query, isEmpty);
      final counts = (await tester.runAsync(() => _control('')))!;
      expect(counts['writes'], 0); expect(counts['domainEffects'], 0);
    } finally {await rig.close(tester);}
  }, skip: _port == 0, timeout: const Timeout(Duration(seconds: 45)));
}


// Labelled host-only original-service readback. No phone provider or authority is injected.
class _RetainedQuoteJournal implements WorkspaceBulkQuoteJournal {
  List<WorkspaceBulkQuoteIntent> pending = [];
  int writes = 0;
  @override Future<List<WorkspaceBulkQuoteIntent>> read(WorkspaceBulkQuoteScope scope) async => List.of(pending);
  @override Future<void> save(WorkspaceBulkQuoteScope scope, WorkspaceBulkQuoteIntent original) async {writes++; throw StateError('Preparation must not save a journal');}
  @override Future<void> remove(WorkspaceBulkQuoteScope scope, WorkspaceBulkQuoteIntent original) async {writes++; throw StateError('Preparation must not remove a journal');}
}
class _RetainedQuoteStore implements BuyV2CustomerStateStore {
  _RetainedQuoteStore(this.snapshot);
  BuyV2CustomerStateSnapshot snapshot;
  String owner = 'HOST-retained-owner'; int writes = 0;
  @override String get ownerScope => owner;
  @override Future<BuyV2CustomerStateSnapshot?> read() async => snapshot;
  @override Future<bool> write(BuyV2CustomerStateSnapshot value) async {writes++; snapshot = value; return true;}
}
class _RetainedQuoteCatalogue implements BuyV2CataloguePageSource {
  _RetainedQuoteCatalogue(this.product); final BuyV2Product product;
  @override Future<List<BuyV2Product>> resolveProducts(Set<String> ids) async => [if(ids.contains(product.id)) product];
  @override Future<BuyV2CataloguePage<BuyV2Product>> loadProducts(BuyV2CatalogueQuery query, {String? cursor, required int pageSize}) async =>
    BuyV2CataloguePage(queryKey: query.key, snapshotId: 'HOST-labelled-original', items: [product], startIndex: 0, totalCount: 1);
  @override Future<BuyV2CataloguePage<BuyV2StoreListing>> loadStores(BuyV2CatalogueQuery query, {String? cursor, required int pageSize}) async =>
    BuyV2CataloguePage(queryKey: query.key, snapshotId: 'HOST-labelled-original', items: const [], startIndex: 0, totalCount: 0);
}
class _RetainedQuoteWire implements SocialContentTransport {
  _RetainedQuoteWire(this.head); final Map<String, dynamic> head;
  int reads = 0; void Function()? onRead;
  @override Future<SocialContentResponse> postJson(Uri endpoint, {required Map<String, String> headers, required Map<String, Object?> body}) async {
    expect(body, {'operation': 'readBulkSupplierQuote', 'quoteId': head['quoteId']});
    reads++; onRead?.call();
    return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': head}));
  }
}
class _RetainedQuoteRig {
  late BuyV2Session buy; late BuySession core; late WorkspaceBulkQuoteAccess access;
  late _RetainedQuoteWire wire; late _RetainedQuoteStore store; final journal = _RetainedQuoteJournal();
  late WorkspaceBulkQuote quote; late BuyV2Product product; late WorkspaceBulkQuoteIntent pendingIntent;
  late Map<(String, String), String> expected; late String user;
  final now = DateTime.utc(2026, 10, 28, 8); bool current = true;
  static Future<_RetainedQuoteRig> create(String path, {bool initialise = true, bool refresh = true}) async {
    final r = _RetainedQuoteRig(), export = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
    expect(export['hostOnly'], true);
    final head = export['head'] as Map<String, dynamic>, line = (head['lines'] as List).single as Map<String, dynamic>;
    r.user = (export['actor'] as Map)['uid'] as String;
    r.quote = WorkspaceBulkQuote.decode(head, realm: 'evaluation', now: r.now);
    r.product = BuyV2Product(id: line['listingId'] as String, canonicalId: line['canonicalProductId'] as String,
      destination: BuyV2Destination.wholesale, categoryId: 'HOST-category', brand: 'HOST-labelled', title: line['name'] as String,
      variant: line['variant'] as String? ?? '', pack: line['packLabel'] as String, priceMinor: 10025,
      unitPrice: '', badge: '', seller: 'HOST-labelled supplier', sellerType: 'Wholesaler', deliveryPromise: '', origin: '',
      confirmedOn: '', visualLabel: '', visualKind: 'pack', storeId: r.quote.storeId, offerClass: BuyV2OfferClass.bulk, minimumOrder: 10,
      publicListingIdentity: BuyV2PublicListingIdentity(listingId: line['listingId'] as String, realm: 'evaluation', storeId: r.quote.storeId,
        skuId: line['skuId'] as String, canonicalProductId: line['canonicalProductId'] as String,
        verifiedPackId: line['verifiedPackId'] as String, channel: BuyV2OfferClass.bulk));
    final price = (head['offer']['prices'] as List).single as Map;
    final selected = BuyV2SupplierQuoteSelection.fromJson({'schemaVersion': 1, 'realm': 'evaluation', 'storeId': r.quote.storeId,
      'quoteId': r.quote.quoteId, 'acceptedRevision': r.quote.revision, 'agreementFingerprint': head['acceptance']['agreementFingerprint'],
      'acceptedAt': head['acceptance']['acceptedAt'], 'validUntil': head['offer']['validUntil'], 'merchandiseMinor': head['offer']['merchandiseMinor'],
      'lines': [{for(final key in ['skuId','listingId','skuRevision','canonicalProductId','verifiedPackId','quantity']) key: line[key],
        'productId': r.product.id, 'quoteLineId': line['lineId'], 'unitPriceMinor': price['unitPriceMinor'], 'merchandiseMinor': price['merchandiseMinor']}]});
    r.store = _RetainedQuoteStore(BuyV2CustomerStateSnapshot(cartQuantities: {r.product.id: 10}, supplierQuoteSelections: {r.quote.storeId: selected}));
    r.wire = _RetainedQuoteWire(head);
    final gateway = AuthenticatedWorkspaceCatalogueGateway(endpoint: Uri.parse('https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
      credentials: _Credentials(), transport: r.wire, realm: 'evaluation', ownerAccountId: r.user, now: () => r.now);
    r.access = WorkspaceBulkQuoteAccess(gateway: WorkspaceBulkQuoteGateway(gateway, enabled: true), journal: r.journal, role: 'buyer', current: () => r.current);
    final controller = r.access.forStore(r.quote.storeId);
    if(initialise) expect(await controller.restore(), true);
    if(refresh) expect(await controller.refresh(r.quote.quoteId), true);
    r.core = BuySession(); r.buy = BuyV2Session(core: r.core, customerStateStore: r.store, bulkQuotes: r.access,
      cataloguePageSource: _RetainedQuoteCatalogue(r.product), reviewDataEnabled: false, purchaseRealm: 'evaluation', catalogueNow: () => r.now);
    await r.buy.restoreCustomerState();
    expect(r.buy.customerStateRecoveryPending, false); expect(r.buy.cartLines, hasLength(1)); expect(r.buy.selectedSupplierQuotes, hasLength(1));
    Object? ordered(Object? value) {
      if(value is Map){final keys=value.keys.cast<String>().toList()..sort();return {for(final key in keys) key: ordered(value[key])};}
      if(value is List)return value.map(ordered).toList();return value;
    }
    final proof = 'buyer-retained-quote:evaluation:${sha256.convert(utf8.encode(jsonEncode(ordered([
      'moolsocial-dev-503018', r.user, 'profile:3', r.quote.toJson()]))))}';
    r.expected = {for(final action in ['AI-ACT-348','AI-ACT-349']) (action,r.quote.quoteId): proof};
    final fields = {for(final key in ['lineId','skuId','listingId','skuRevision','quantity','canonicalProductId','verifiedPackId']) key: line[key]};
    r.pendingIntent = WorkspaceBulkQuoteIntent.decode({'schemaVersion':1,'account':r.user,'realm':'evaluation','kind':'request',
      'body':{'schemaVersion':1,'requestId':'HOST-pending-only','storeId':r.quote.storeId,'lines':[
        {for(final key in ['lineId','skuId','listingId','skuRevision','quantity']) key:line[key]}]},'base':null,'expected':[fields]},
      account:r.user,realm:'evaluation',now:r.now);
    return r;
  }
  Future<Set<(String,String)>> read({String? proof}) => buy.readAssistantRetainedQuoteOriginals(
    proof == null ? expected : {for(final key in expected.keys) key:proof}, projectId:'moolsocial-dev-503018', accountUserId:user,
    accountOwnerScope:'HOST-retained-owner', profileRevision:'profile:3',inputCurrent:()=>current,validUntil:now.add(const Duration(minutes:1)));
  void dispose(){current=false;buy.dispose();core.dispose();access.dispose();}
}
