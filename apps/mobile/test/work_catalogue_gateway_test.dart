import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_views.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_catalogue.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_invoice.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_invoice_downloader.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_cart_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/features/buy/buy_v2_saved_products_store.dart';
import 'package:moolsocial/features/shared/social_content_gateway.dart';
import 'package:moolsocial/features/work/work_catalogue_gateway.dart';
import 'package:moolsocial/features/work/work_services.dart';
import 'package:moolsocial/features/work/work_session.dart';
import 'package:moolsocial/features/work/work_models.dart';
import 'package:moolsocial/features/work/work_publication.dart';
import 'package:moolsocial/features/work/work_product_promotions.dart';
import 'package:moolsocial/features/work/screens/work_workspace_dashboard_screen.dart';
import 'package:moolsocial/features/work/widgets/store_publication_settings.dart';

// Host fixtures only. No upload, device storage or real commerce.
final at = DateTime.utc(2026, 10, 16, 12);
// Configured reviewed-source fixture only; never injected into the native app.
class HostReviewedVariantSource implements WorkspacePublicVariantSource {
  HostReviewedVariantSource({required this.memberships, this.family});
  final Future<List<WorkspaceReviewedVariantMembership>> Function(
    List<WorkspacePublicCatalogueEntry> entries, bool Function() current) memberships;
  final Future<BuyV2VariantFamilySnapshot> Function(BuyV2Product selected,
    BuyV2CatalogueQuery query, bool Function() current)? family;
  @override
  Future<List<WorkspaceReviewedVariantMembership>> readMemberships(
    List<WorkspacePublicCatalogueEntry> entries, {required bool Function() current}) => memberships(entries, current);
  @override
  Future<BuyV2VariantFamilySnapshot> readFamily(BuyV2Product selected, BuyV2CatalogueQuery query,
    {required bool Function() current}) {
    if (family == null) throw StateError('No host family response configured');
    return family!(selected, query, current);
  }
}
// Isolated optional-content responses, never an injected native provider feed.
class _HostOptionalProductContent implements BuyV2ProductContentAdapter {
  BuyV2ProductContentState state = BuyV2ProductContentState.ready;
  String? description;
  BuyV2CategoryFacts? categoryFacts;
  List<BuyV2ProductSpecification> specifications = const [], highlights = const [];
  @override
  BuyV2ProductContentSnapshot snapshotFor(BuyV2Product product) => BuyV2ProductContentSnapshot(
    productId: product.id, state: state, sourceId: 'host-optional-details', observedAt: at,
    description: description, specifications: specifications, highlightFields: highlights,
    categoryFacts: categoryFacts, retryable: state == BuyV2ProductContentState.offline);
}
class _HostOperationalFacts implements BuyV2ProductFactsAdapter {
  _HostOperationalFacts(this.reply);
  BuyV2ProductFactsSnapshot Function(BuyV2Product) reply;
  @override
  BuyV2ProductFactsSnapshot snapshotFor(BuyV2Product product) => reply(product);
}
class _HostExactOrderCommerce implements BuyV2CommerceAdapter {
  List<BuyV2Order> records = [];
  BuyV2Order? refreshedOrder;
  late BuyV2OrderPlacementResult reconciliation;
  int reconciliationCalls = 0, placementCalls = 0;
  @override
  Future<BuyV2CommerceSnapshot> refresh() async => BuyV2CommerceSnapshot(
    state: BuyV2CommerceLoadState.ready, orders: records);
  @override
  Future<BuyV2OrderRefreshResult> refreshOrder({required String orderId}) async => BuyV2OrderRefreshResult(
    state: BuyV2CommerceLoadState.ready, customerMessage: 'Host refresh', order: refreshedOrder);
  @override
  Future<BuyV2OrderPlacementResult> reconcileOrder({required String idempotencyKey, required String paymentReference}) async {
    reconciliationCalls++;
    if (idempotencyKey != 'host-original-key' || paymentReference != 'host-original-reference') {
      throw StateError('Host original identity changed');
    }
    return reconciliation;
  }
  @override
  Future<BuyV2OrderPlacementResult> placeOrder(BuyV2OrderPlacementRequest request) async {
    placementCalls++;
    throw StateError('Read-only host fixture must not place');
  }
  // Read-only host fixture: no placement, payment or other command path.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
class _HostPlacement extends _HostExactOrderCommerce implements BuyV2GroupedOrderPlacementAdapter {
  final legacySingle = <BuyV2OrderPlacementRequest>[], legacyGroups = <BuyV2OrderPlacementRequest>[],
      minorSingle = <BuyV2OrderPlacementRequest>[], minorGroups = <BuyV2OrderPlacementRequest>[];
  void Function(BuyV2OrderPlacementRequest request)? onDispatch;
  BuyV2OrderPlacementResult Function(BuyV2OrderPlacementRequest request)? reply;
  BuyV2OrderPlacementResult record(BuyV2OrderPlacementRequest request) {
    onDispatch?.call(request);
    return reply?.call(request) ?? BuyV2OrderPlacementResult(outcome: BuyV2OrderPlacementOutcome.paymentUnknown,
      customerMessage: 'Host original needs checking', paymentReference: 'host-placement-reference',
      checkoutAttemptId: request.checkoutAttemptId, paymentGroupId: request.paymentGroupId, idempotencyKey: request.idempotencyKey);
  }
  @override
  Future<BuyV2OrderPlacementResult> placeOrder(BuyV2OrderPlacementRequest request) async {
    legacySingle.add(request); return record(request);
  }
  @override
  Future<BuyV2OrderPlacementResult> placePaymentGroup(BuyV2OrderPlacementRequest request) async {
    legacyGroups.add(request); return record(request);
  }
}
class _HostMinorPlacement extends _HostPlacement implements BuyV2MinorOrderPlacementAdapter {
  @override
  Future<BuyV2OrderPlacementResult> placeOrderMinor(BuyV2OrderPlacementRequest request) async {
    minorSingle.add(request); return record(request);
  }
}
class _HostMinorGroupedPlacement extends _HostMinorPlacement implements BuyV2MinorGroupedOrderPlacementAdapter {
  final reconciled = <({String key, String reference})>[];
  @override
  Future<BuyV2OrderPlacementResult> reconcileOrder({required String idempotencyKey, required String paymentReference}) async {
    reconciliationCalls++; reconciled.add((key: idempotencyKey, reference: paymentReference)); return reconciliation;
  }
  @override
  Future<BuyV2OrderPlacementResult> placePaymentGroupMinor(BuyV2OrderPlacementRequest request) async {
    minorGroups.add(request); return record(request);
  }
}
class _HostExactOrderTracking implements BuyV2LiveDeliveryAdapter {
  int calls = 0;
  @override
  Future<BuyV2LiveDeliverySnapshot> load({required String orderId}) async {
    calls++;
    return BuyV2LiveDeliverySnapshot(orderId: orderId,
      state: BuyV2LiveDeliveryState.ready, customerMessage: 'Host tracking only', sourceId: 'host-tracking',
      courierPosition: const BuyV2GeoPoint(latitude: 26.29, longitude: 73.02),
      destinationPosition: const BuyV2GeoPoint(latitude: 26.30, longitude: 73.03),
      driverName: 'Host driver', etaLabel: 'Host estimate', lastUpdatedAt: DateTime.now(), routeProgress: .5);
  }
}
class _HostLegacyBalance implements BuyV2BalancePaymentAdapter {
  int dueMinor = 1043, loads = 0, reconciles = 0;
  bool failLoad = false, failStart = false, failReconcile = false;
  final legacyAmounts = <int>[], minorAmounts = <int>[], keys = <String>[];
  void Function()? onStart;
  BuyV2BalancePaymentResult? nextLoad, nextStart, nextReconcile;
  @override
  Future<BuyV2BalancePaymentResult> loadBalance({required String orderId}) async {
    loads++;
    if (failLoad) throw StateError('Host load failure');
    return nextLoad ?? BuyV2BalancePaymentResult.minor(state: BuyV2BalancePaymentState.due,
      amountDueMinor: dueMinor, dueLabel: 'Host due', customerMessage: 'Host balance');
  }
  Future<BuyV2BalancePaymentResult> start(int minor, String key) async {
    keys.add(key); onStart?.call();
    if (failStart) throw StateError('Host lost response');
    return nextStart ?? BuyV2BalancePaymentResult.minor(state: BuyV2BalancePaymentState.paymentActionRequired,
      amountDueMinor: minor, dueLabel: 'Host due', customerMessage: 'Host original action',
      paymentReference: 'host-balance-reference', paymentActionUri: Uri.parse('https://host.invalid/original'));
  }
  @override
  Future<BuyV2BalancePaymentResult> startPayment({required String orderId, required int amountDue, required String idempotencyKey}) {
    legacyAmounts.add(amountDue); return start(amountDue * 100, idempotencyKey);
  }
  @override
  Future<BuyV2BalancePaymentResult> reconcilePayment({required String orderId, required String paymentReference}) async {
    reconciles++;
    if (paymentReference != 'host-balance-reference') throw StateError('Host reference changed');
    if (failReconcile) throw StateError('Host reconcile failure');
    return nextReconcile ?? const BuyV2BalancePaymentResult.minor(state: BuyV2BalancePaymentState.paid,
      amountDueMinor: 0, dueLabel: 'Host checked', customerMessage: 'Host original paid', paymentReference: 'host-balance-reference');
  }
}
class _HostMinorBalance extends _HostLegacyBalance implements BuyV2MinorBalancePaymentAdapter {
  @override
  Future<BuyV2BalancePaymentResult> startPaymentMinor({required String orderId, required int amountDueMinor, required String idempotencyKey}) {
    minorAmounts.add(amountDueMinor); return start(amountDueMinor, idempotencyKey);
  }
}
// Isolated quote/term transports. Never injected into the phone application.
class _HostLegacyQuote implements BuyV2CheckoutQuoteAdapter {
  int legacyCalls = 0;
  Map<String, int>? legacyTips;
  Future<BuyV2CheckoutQuoteSnapshot> Function(List<BuyV2FulfilmentGroup>, Map<String, int>)? reply;
  @override
  Future<BuyV2CheckoutQuoteSnapshot> loadQuote({required List<BuyV2FulfilmentGroup> groups,
    required BuyV2Address address, required String selectedPaymentMethod,
    required List<BuyV2CartBenefit> selectedBenefits, required Map<String, int> tipAmountsByFulfilmentKey}) async {
    legacyCalls++; legacyTips = Map.of(tipAmountsByFulfilmentKey);
    return reply?.call(groups, tipAmountsByFulfilmentKey) ??
      const BuyV2CheckoutQuoteSnapshot(state: BuyV2CommerceLoadState.unavailable);
  }
}
class _HostMinorQuote extends _HostLegacyQuote implements BuyV2MinorCheckoutQuoteAdapter {
  int minorCalls = 0;
  Map<String, int>? minorTips;
  @override
  Future<BuyV2CheckoutQuoteSnapshot> loadQuoteMinor({required List<BuyV2FulfilmentGroup> groups,
    required BuyV2Address address, required String selectedPaymentMethod,
    required List<BuyV2CartBenefit> selectedBenefits, required Map<String, int> tipAmountsMinorByFulfilmentKey}) async {
    minorCalls++; minorTips = Map.of(tipAmountsMinorByFulfilmentKey);
    return reply?.call(groups, tipAmountsMinorByFulfilmentKey) ??
      const BuyV2CheckoutQuoteSnapshot(state: BuyV2CommerceLoadState.unavailable);
  }
}
class _HostLegacyTerms implements BuyV2CommercialPaymentTermsAdapter {
  int legacyCalls = 0;
  Map<String, int>? legacyTotals;
  Future<BuyV2CommercialPaymentTermsSnapshot> Function(List<BuyV2FulfilmentGroup>, Map<String, int>)? reply;
  @override
  Future<BuyV2CommercialPaymentTermsSnapshot> loadTerms({required List<BuyV2FulfilmentGroup> groups,
    required String selectedPaymentMethod, required Map<String, int> quotedTotalsByFulfilmentKey}) async {
    legacyCalls++; legacyTotals = Map.of(quotedTotalsByFulfilmentKey);
    return reply?.call(groups, quotedTotalsByFulfilmentKey) ??
      const BuyV2CommercialPaymentTermsSnapshot(state: BuyV2CommerceLoadState.unavailable);
  }
}
class _HostMinorTerms extends _HostLegacyTerms implements BuyV2MinorCommercialPaymentTermsAdapter {
  int minorCalls = 0;
  Map<String, int>? minorTotals;
  @override
  Future<BuyV2CommercialPaymentTermsSnapshot> loadTermsMinor({required List<BuyV2FulfilmentGroup> groups,
    required String selectedPaymentMethod, required Map<String, int> quotedTotalsMinorByFulfilmentKey}) async {
    minorCalls++; minorTotals = Map.of(quotedTotalsMinorByFulfilmentKey);
    return reply?.call(groups, quotedTotalsMinorByFulfilmentKey) ??
      const BuyV2CommercialPaymentTermsSnapshot(state: BuyV2CommerceLoadState.unavailable);
  }
}
class _HostTipPolicy implements BuyV2TipPolicy {
  @override
  List<BuyV2TipOption> optionsFor(BuyV2Destination destination) => const [BuyV2TipOption(amount: 10)];
  @override
  bool accepts(BuyV2Destination destination, int amount) => amount == 0 || amount == 10;
}
class _HostRetirableStateStore implements BuyV2CustomerStateStore {
  Future<BuyV2CustomerStateSnapshot?>? heldRead;
  bool writesSucceed = true;
  @override
  String? ownerScope = 'host-loading-owner';
  @override
  Future<BuyV2CustomerStateSnapshot?> read() async => heldRead == null ? null : await heldRead;
  @override
  Future<bool> write(BuyV2CustomerStateSnapshot snapshot) async => writesSucceed;
}
BuyV2CheckoutQuoteSnapshot _hostExactQuote(List<BuyV2FulfilmentGroup> groups, Map<String, int> tips,
  {int coupon = 0, int fee = 0, String id = 'host-current-quote', DateTime? expires}) {
  final now = DateTime.now();
  final lines = [for (final group in groups) BuyV2CheckoutQuoteLine.minor(fulfilmentKey: group.key,
    itemSubtotalMinor: group.totalMinor, couponSavingMinor: coupon, taxMinor: 0, freightMinor: 0,
    deliveryFeeMinor: fee, tipMinor: tips[group.key] ?? 0, paymentChargeMinor: 0,
    totalMinor: group.totalMinor - coupon + fee + (tips[group.key] ?? 0))];
  return BuyV2CheckoutQuoteSnapshot(state: BuyV2CommerceLoadState.ready, quote: BuyV2CheckoutQuote.minor(
    id: id, sourceId: 'host-exact-quote-source', evaluatedAt: now, validUntil: expires ?? now.add(const Duration(minutes: 5)),
    lines: lines, totalMinor: buyV2SumMinor(lines.map((line) => line.totalMinor))));
}
BuyV2CommercialPaymentTermsSnapshot _hostExactRetailTerms(List<BuyV2FulfilmentGroup> groups, Map<String, int> totals) =>
  BuyV2CommercialPaymentTermsSnapshot(state: BuyV2CommerceLoadState.ready, terms: [for (final group in groups)
    BuyV2CommercialPaymentTerm.minor(id: 'host-retail-advance', fulfilmentKey: group.key, destination: group.destination,
      supplierName: group.partner, kind: BuyV2CommercialPaymentTermKind.retailAdvance, orderTotalMinor: totals[group.key]!,
      amountDueNowMinor: totals[group.key]!, balanceDueMinor: 0, balanceDueLabel: 'No balance', sourceId: 'host-terms-source')]);
class _HostLegacyBenefits implements BuyV2CartBenefitsAdapter {
  final offers = <BuyV2CartBenefit>[];
  final legacyInputs = <int>[];
  @override
  List<BuyV2CartBenefit> benefitsFor({required BuyV2CartBenefitKind kind,
    required Set<BuyV2Destination> destinations, required int itemTotal}) {
    legacyInputs.add(itemTotal);
    return offers.where((b) => b.kind == kind && destinations.contains(b.destination)).toList();
  }
}
class _HostMinorBenefits extends _HostLegacyBenefits implements BuyV2MinorCartBenefitsAdapter {
  final minorInputs = <int>[];
  @override
  List<BuyV2CartBenefit> benefitsForMinor({required BuyV2CartBenefitKind kind,
    required Set<BuyV2Destination> destinations, required int itemTotalMinor}) {
    minorInputs.add(itemTotalMinor);
    return offers.where((b) => b.kind == kind && destinations.contains(b.destination)).toList();
  }
}
class _HostSeededOverrideBenefits extends BuyV2SeededCartBenefitsAdapter {
  final calls = <int>[];
  @override
  List<BuyV2CartBenefit> benefitsFor({required BuyV2CartBenefitKind kind,
    required Set<BuyV2Destination> destinations, required int itemTotal}) {
    calls.add(itemTotal);
    return const [];
  }
}
class _HostLiveBenefits extends _HostLegacyBenefits implements BuyV2LiveCartBenefitsAdapter {
  Completer<BuyV2CartBenefitsSnapshot>? held;
  final requests = <BuyV2CartBenefitsRequest>[];
  @override
  Future<BuyV2CartBenefitsSnapshot> loadEligibility(BuyV2CartBenefitsRequest request) async {
    requests.add(request);
    return held?.future ?? BuyV2CartBenefitsSnapshot(state: BuyV2CartBenefitsLoadState.ready, evaluatedAt: at, benefits: List.of(offers));
  }
}
class _HostBenefitFacts implements BuyV2ProductFactsAdapter {
  int minor = 2000;
  @override
  BuyV2ProductFactsSnapshot snapshotFor(BuyV2Product product) =>
    const BuyV2CatalogueProductFactsAdapter().snapshotFor(product).copyWith(priceMinor: minor);
}
// Explicit isolated review source. No backend, native state or authority grant.
class _ExactMoneyHostCatalogue implements BuyV2CataloguePageSource {
  final rows = <BuyV2Product>[];
  @override
  Future<BuyV2CataloguePage<BuyV2StoreListing>> loadStores(BuyV2CatalogueQuery query,
    {String? cursor, required int pageSize}) async => BuyV2CataloguePage(queryKey: query.key,
      snapshotId: 'host-exact-money', items: const [], startIndex: 0, totalCount: 0);
  @override
  Future<BuyV2CataloguePage<BuyV2Product>> loadProducts(BuyV2CatalogueQuery query,
    {String? cursor, required int pageSize}) async => BuyV2CataloguePage(queryKey: query.key,
      snapshotId: 'host-exact-money', items: rows.where((p) => p.destination == query.destination),
      startIndex: 0, totalCount: rows.where((p) => p.destination == query.destination).length);
  @override
  Future<List<BuyV2Product>> resolveProducts(Set<String> ids) async => rows.where((p) => ids.contains(p.id)).toList();
}
final class _ExactMoneyHostPreferences implements SharedPreferencesAsync {
  _ExactMoneyHostPreferences({this.beforeSet, this.beforeWrite});
  final values = <String, String>{};
  final void Function(String key, String value)? beforeSet;
  final Future<void> Function(String key, String value)? beforeWrite;
  @override
  Future<String?> getString(String key) async => values[key];
  @override
  Future<void> setString(String key, String value) async {
    beforeSet?.call(key, value);
    await beforeWrite?.call(key, value);
    values[key] = value;
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('Unexpected host preferences operation');
}
// Isolated host journal/authority: never wired to a native evaluation Store.
class PublicDetailsHostJournal implements WorkspacePublicDetailsJournal {
  WorkspacePublicDetailsIntent? original;
  bool failRead = false, failSave = false, failRemove = false;
  Completer<void>? saveGate;
  final events = <String>[];
  @override
  Future<WorkspacePublicDetailsIntent?> readPending(WorkspacePublicDetailsScope scope) async {
    if (failRead) throw StateError('host read');
    return original;
  }
  @override
  Future<void> savePending(WorkspacePublicDetailsIntent value) async {
    events.add('journal');
    await saveGate?.future;
    if (failSave) throw StateError('host save');
    if (original != null && original!.fingerprint != value.fingerprint) throw StateError('different original');
    original = value;
  }
  @override
  Future<void> removePending(WorkspacePublicDetailsIntent value) async {
    if (failRemove) throw StateError('host remove');
    expect(original?.fingerprint, value.fingerprint);
    original = null;
  }
}
class PublicDetailsHostGateway implements WorkspacePublicDetailsOwnerGateway {
  WorkspacePublicDetailsRecord? head;
  WorkspacePublicDetailsWriteState outcome = WorkspacePublicDetailsWriteState.unknown;
  WorkspacePublicDetailsRecord? acknowledgement;
  Completer<WorkspacePublicDetailsWriteResult>? response;
  final sent = <({WorkspacePublicDetailsIntent original, bool reconcile})>[];
  int reads = 0;
  @override
  Future<WorkspacePublicDetailsRecord?> readPublicDetailsOwned({required String storeId, required bool Function() current}) async {
    reads++;
    return head;
  }
  @override
  Future<WorkspacePublicDetailsWriteResult> writePublicDetails(WorkspacePublicDetailsIntent original,
    {required bool Function() current, bool reconcile = false}) async {
    sent.add((original: original, reconcile: reconcile));
    return response?.future ?? WorkspacePublicDetailsWriteResult(outcome, acknowledgement);
  }
}
// Host storage-completion boundary; this is not Android encryption acceptance.
class _DelayedDetailsStorage extends FlutterSecureStorage {
  final rows = <String, String>{};
  final entered = Completer<void>(), release = Completer<void>();
  int writes = 0;
  @override
  Future<String?> read({required String key, AppleOptions? iOptions, AndroidOptions? aOptions,
    LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async => rows[key];
  @override
  Future<void> write({required String key, required String? value, AppleOptions? iOptions, AndroidOptions? aOptions,
    LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async {
    writes++; if (writes == 1) { entered.complete(); await release.future; }
    if (value == null) throw StateError('Journal must use a matching tombstone, not deletion');
    rows[key] = value;
  }
}
const product = BuyV2Product(
  id: 'sku-one',
  canonicalId: 'canonical-one',
  storeId: 'store-one',
  destination: BuyV2Destination.shop,
  categoryId: 'cooking-oil',
  brand: 'Host fixture',
  title: 'Host fixture oil',
  variant: 'Sunflower',
  pack: '1 L',
  price: 260,
  mrp: 280,
  unitPrice: '',
  badge: '',
  seller: 'Host Store',
  sellerType: 'Retailer',
  deliveryPromise: '',
  origin: '',
  confirmedOn: '',
  visualLabel: '',
  visualKind: '',
  offerClass: BuyV2OfferClass.retail,
);
Map<String, dynamic> page() => {
  'schemaVersion': 1,
  'realm': 'production',
  'storeId': 'store-one',
  'observedAt': '2026-10-16T12:00:00.000Z',
  'orderingAvailable': false,
  'coverage': 'verified_public_only',
  'state': 'ready',
  'catalogueVersion': 1,
  'nextCursor': null,
  'items': [
    {
      'skuId': 'sku-one',
      'canonicalProductId': 'canonical-one',
      'verifiedPackId': 'pack-one',
      'sku': 'HOST-ONE',
      'revision': 1,
      'observedAt': '2026-10-16T11:00:00.000Z',
      'content': {
        'title': product.title,
        'brand': product.brand,
        'variant': product.variant,
        'categoryId': 'cooking-oil',
        'description': 'Verified host description',
        'highlights': ['One litre'],
        'specifications': [
          {'label': 'Oil', 'value': 'Sunflower'},
        ],
        'media': [],
      },
      'pack': {
        'label': '1 L',
        'quantityMilli': 1000,
        'unit': 'L',
        'unitsPerCase': 1,
      },
      'channels': [
        {
          'kind': 'retail',
          'offerId': 'offer-one',
          'priceMinor': 26000,
          'mrpMinor': 28000,
          'minimumOrder': 1,
          'quantityStep': 1,
          'tiers': [],
          'revision': 'term-one',
          'validUntil': '2026-10-16T13:00:00.000Z',
        },
      ],
    },
  ],
};

class Credentials implements SocialContentCredentials {
  final modes = <SocialAppCheckTokenMode>[];
  @override
  Future<String> firebaseIdToken() async => 'isolated-host-token';
  @override
  Future<String> appCheckToken(SocialAppCheckTokenMode mode) async {
    modes.add(mode);
    return 'isolated-host-appcheck';
  }
}
// Private-media host fixtures. No native provider injection or publication/commerce acceptance.
String _mediaHash(Object? value) {
  Object? sorted(Object? item) => item is Map ? {for (final key in (item.keys.cast<String>().toList()..sort())) key: sorted(item[key])}
    : item is List ? item.map(sorted).toList() : item;
  return sha256.convert(utf8.encode(jsonEncode(sorted(value)))).toString().toUpperCase();
}
WorkspaceProductMediaIntent _mediaOriginal(Uint8List bytes, {String key = 'photo-original', int revision = 1}) => WorkspaceProductMediaIntent(
  scope: (account: 'owner-one', store: 'store-one', realm: 'evaluation', sku: 'sku-one'), submissionRevision: revision,
  submissionFingerprint: 'A' * 64, sourceSha256: sha256.convert(bytes).toString(), sourceByteLength: bytes.length, idempotencyKey: key);
Map<String, dynamic> _mediaReply(WorkspaceProductMediaIntent original, Uint8List bytes,
    {String state = 'not_found', bool current = true, bool grant = false}) {
  final outputHash = sha256.convert(bytes).toString().toUpperCase();
  final headers = {'content-type': 'image/png', 'content-length': '${original.sourceByteLength}', 'x-goog-if-generation-match': '0',
    'x-goog-meta-moolsocial-schema': 'private-product-media-v1', 'x-goog-meta-moolsocial-binding': original.serverFingerprint,
    'x-goog-meta-moolsocial-owner': _mediaHash(original.scope.account), 'x-goog-meta-moolsocial-source': original.sourceSha256};
  final signed = [...headers.keys, 'host']..sort();
  return {'schemaVersion': 1, 'productMediaVersion': 1, 'realm': original.scope.realm, 'storeId': original.scope.store,
    'skuId': original.scope.sku, 'idempotencyKey': original.idempotencyKey, 'uploadId': original.uploadId, 'current': current, 'state': state,
    'preparedAt': state == 'not_found' ? null : at.toIso8601String(), 'expiresAt': state == 'not_found' ? null : at.add(const Duration(minutes: 5)).toIso8601String(),
    'source': {'revision': original.submissionRevision, 'fingerprint': original.submissionFingerprint}, 'approved': false, 'publicationConfirmed': false,
    'processed': state == 'processed' ? {'assetId': _mediaHash({'uploadId': original.uploadId, 'generation': '17', 'sha256': outputHash}),
      'originalGeneration': '17', 'derivativeGeneration': '23', 'processedAt': at.toIso8601String(),
      'source': {'sha256': original.sourceSha256.toUpperCase(), 'byteLength': original.sourceByteLength, 'width': 512, 'height': 512, 'mimeType': 'image/png'},
      'file': {'sha256': outputHash, 'byteLength': bytes.length, 'width': 512, 'height': 512, 'mimeType': 'image/png', 'normalized': true, 'frameCount': 1},
      'meetsPublicSourceFloor': true} : null,
    if (grant) ...{'requiredHeaders': headers, 'uploadUrl': Uri.https('storage.googleapis.com', '/host-private/private/product-media/v1/evaluation/${original.uploadId}/original',
      {'X-Goog-Algorithm': 'GOOG4-RSA-SHA256', 'X-Goog-Credential': 'host@invalid/20261016/auto/storage/goog4_request',
        'X-Goog-Date': '20261016T120000Z', 'X-Goog-Expires': '300', 'X-Goog-SignedHeaders': signed.join(';'), 'X-Goog-Signature': 'ab' * 128}).toString()}};
}
class _MediaApi implements SocialContentTransport {
  _MediaApi(this.reply);
  final FutureOr<Map<String, dynamic>> Function(Map<String, Object?>) reply;
  final bodies = <Map<String, Object?>>[];
  @override
  Future<SocialContentResponse> postJson(Uri endpoint, {required Map<String, String> headers, required Map<String, Object?> body}) async {
    bodies.add(Map.of(body)); return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': await reply(body)}));
  }
}
class _MediaPut implements WorkspaceProductMediaUploadTransport {
  int calls = 0, status = 200;
  Future<void> Function()? afterWrite;
  final urls = <Uri>[];
  Uint8List? bytes;
  @override
  Future<int> put(Uri url, Map<String, String> headers, Uint8List bytes, {required bool Function() current}) async {
    expect(current(), isTrue); expect(headers.keys.any((k) => k.toLowerCase().contains('authorization') || k.contains('appcheck')), isFalse);
    calls++; urls.add(url); this.bytes = Uint8List.fromList(bytes);
    if (afterWrite != null) await afterWrite!(); return status;
  }
}
AuthenticatedWorkspaceCatalogueGateway _mediaGateway(SocialContentTransport api, _MediaPut put, {Credentials? credentials, DateTime Function()? now}) =>
  AuthenticatedWorkspaceCatalogueGateway(endpoint: Uri.parse('https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
    credentials: credentials ?? Credentials(), transport: api, realm: 'evaluation', ownerAccountId: 'owner-one', productSubmissionSupported: true,
    productMediaSupported: true, productMediaTransport: put, now: now ?? () => at);
class _MediaJournal implements WorkspaceProductMediaJournal {
  WorkspaceProductMediaRecovery? saved;
  bool failOriginal = false, failResult = false;
  Future<void> Function()? beforeOriginal;
  @override
  Future<WorkspaceProductMediaRecovery?> read(WorkspaceProductSubmissionScope scope) async => saved;
  @override
  Future<void> saveOriginal(WorkspaceProductMediaIntent original) async {
    if (beforeOriginal != null) await beforeOriginal!();
    if (failOriginal) throw StateError('Host original save failed');
    saved = WorkspaceProductMediaRecovery(original, saved?.original.fingerprint == original.fingerprint ? saved?.result : null);
  }
  @override
  Future<void> saveResult(WorkspaceProductMediaIntent original, WorkspaceProductMediaResult result) async {
    if (failResult) throw StateError('Host result save failed');
    expect(saved!.original.fingerprint, original.fingerprint); saved = WorkspaceProductMediaRecovery(original, result);
  }
}
class _ProductMediaOwner extends _ProductOwner implements WorkspaceProductMediaGateway {
  late WorkspaceProductMediaGateway media;
  @override
  bool get productMediaSupported => true;
  @override
  Future<WorkspaceProductMediaResult> readProductMedia(WorkspaceProductMediaIntent original, {required bool Function() current, bool confirm = false}) =>
    media.readProductMedia(original, current: current, confirm: confirm);
  @override
  Future<WorkspaceProductMediaResult> uploadProductMedia(WorkspaceProductMediaIntent original,
    {required Future<Uint8List> Function() readBytes, required bool Function() current}) => media.uploadProductMedia(original, readBytes: readBytes, current: current);
}

// Host-only originals; never injected into native Store storage or a live service.
class _ProductJournal implements WorkspaceProductSubmissionJournal {
  WorkspaceProductSubmissionIntent? pending;
  bool failSave = false, failRemove = false;
  Future<void> Function()? beforeSave;
  @override
  Future<WorkspaceProductSubmissionIntent?> readPending(WorkspaceProductSubmissionScope scope) async => pending;
  @override
  Future<void> savePending(WorkspaceProductSubmissionIntent original) async {
    if (beforeSave != null) await beforeSave!();
    if (failSave) throw StateError('Host storage failed');
    if (pending != null && pending!.fingerprint != original.fingerprint) throw StateError('Keep original');
    pending = WorkspaceProductSubmissionIntent.fromJson(original.toJson());
  }
  @override
  Future<void> removePending(WorkspaceProductSubmissionIntent original) async {
    if (failRemove) throw StateError('Host cleanup failed');
    if (pending?.fingerprint != original.fingerprint) throw StateError('Keep original');
    pending = null;
  }
}
class _ProductOwner implements WorkspaceCatalogueGateway, WorkspaceProductSubmissionOwnerGateway {
  @override
  String get realm => 'evaluation';
  @override
  bool productSubmissionSupported = true;
  WorkspaceProductSubmissionRecord? head;
  Future<WorkspaceProductSubmissionRecord?> Function()? readHead;
  Future<WorkspaceProductSubmissionWriteResult> Function(WorkspaceProductSubmissionIntent, bool)? write;
  final submitted = <WorkspaceProductSubmissionIntent>[], reconciled = <WorkspaceProductSubmissionIntent>[];
  final readScopes = <WorkspaceProductSubmissionScope>[];
  @override
  Future<WorkspaceCatalogueContentResult> read(BuyV2Product product) => throw StateError('No public host feed');
  @override
  Future<WorkspaceProductSubmissionRecord?> readProductSubmission(WorkspaceProductSubmissionScope scope, {required bool Function() current}) async {
    readScopes.add(scope); return readHead == null ? head : await readHead!();
  }
  @override
  Future<WorkspaceProductSubmissionWriteResult> writeProductSubmission(WorkspaceProductSubmissionIntent original,
      {required bool Function() current, bool reconcile = false}) async {
    (reconcile ? reconciled : submitted).add(original);
    return write == null ? const WorkspaceProductSubmissionWriteResult(WorkspaceProductSubmissionWriteState.unknown) : await write!(original, reconcile);
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FamilyJournal implements WorkspaceVariantFamilyJournal {
  WorkspaceVariantFamilyIntent? pending;
  bool failSave = false, failRemove = false;
  int saves = 0, removes = 0;
  Future<void> Function()? beforeSave;
  @override
  Future<WorkspaceVariantFamilyIntent?> readPending(WorkspaceVariantFamilyScope scope) async => pending;
  @override
  Future<void> savePending(WorkspaceVariantFamilyIntent original) async {
    saves++;
    if (beforeSave != null) await beforeSave!();
    if (failSave) throw StateError('Host journal failure');
    if (pending != null && pending!.fingerprint != original.fingerprint) throw StateError('Keep original');
    pending = WorkspaceVariantFamilyIntent.fromJson(original.toJson());
  }
  @override
  Future<void> removePending(WorkspaceVariantFamilyIntent original) async {
    removes++;
    if (failRemove) throw StateError('Host cleanup failure');
    if (pending?.fingerprint != original.fingerprint) throw StateError('Keep original');
    pending = null;
  }
}
class _FamilyOwner implements WorkspaceVariantFamilyOwnerGateway {
  @override
  String get realm => 'production';
  @override
  bool variantFamilySubmissionSupported = true;
  WorkspaceVariantFamilyHead head = const WorkspaceVariantFamilyHead(candidate: null, reviewedCandidate: null,
    reviewRevision: 0, reviewFingerprint: null, decision: null);
  final submitted = <WorkspaceVariantFamilyIntent>[], reconciled = <WorkspaceVariantFamilyIntent>[];
  Future<WorkspaceVariantFamilyWriteResult> Function(WorkspaceVariantFamilyIntent, bool)? write;
  Future<WorkspaceVariantFamilyHead> Function()? read;
  @override
  Future<WorkspaceVariantFamilyHead> readVariantFamily(WorkspaceVariantFamilyScope scope,
      {required bool Function() current}) async => read == null ? head : await read!();
  @override
  Future<WorkspaceVariantFamilyWriteResult> writeVariantFamily(WorkspaceVariantFamilyIntent original,
      {required bool Function() current, bool reconcile = false}) async {
    (reconcile ? reconciled : submitted).add(original);
    return write == null ? const WorkspaceVariantFamilyWriteResult(WorkspaceVariantFamilyWriteState.unknown)
      : await write!(original, reconcile);
  }
}

class Transport implements SocialContentTransport {
  Transport(this.data);
  Map<String, dynamic> data;
  Map<String, Object?>? sent;
  bool fail = false;
  @override
  Future<SocialContentResponse> postJson(
    Uri endpoint, {
    required Map<String, String> headers,
    required Map<String, Object?> body,
  }) async {
    sent = body;
    if (fail) throw StateError('isolated host failure');
    return SocialContentResponse(
      statusCode: 200,
      body: jsonEncode({'ok': true, 'data': data}),
    );
  }
}

AuthenticatedWorkspaceCatalogueGateway gateway(
  Transport transport, [
  Credentials? credentials,
]) => AuthenticatedWorkspaceCatalogueGateway(
  endpoint: Uri.parse(
    'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace',
  ),
  credentials: credentials ?? Credentials(),
  transport: transport,
  now: () => at,
);

AuthenticatedWorkspaceCatalogueGateway factsGateway(SocialContentTransport transport) =>
    AuthenticatedWorkspaceCatalogueGateway(
      endpoint: Uri.parse('https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
      credentials: Credentials(), transport: transport, now: () => at, productFactsReadbackSupported: true);

class HoldingGateway implements WorkspaceCatalogueGateway {
  final response = Completer<WorkspaceCatalogueContentResult>();
  int calls = 0;
  @override
  Future<WorkspaceCatalogueContentResult> read(BuyV2Product product) {
    calls++;
    return response.future;
  }
}

Map<String, dynamic> row(Map<String, dynamic> data) =>
    (data['items'] as List).single as Map<String, dynamic>;

Map<String, dynamic> ownerRow({int revision = 1, bool listed = false}) {
  final result = row(jsonDecode(jsonEncode(page())) as Map<String, dynamic>);
  for (final channel in result['channels'] as List) {
    (channel as Map)
      ..remove('revision')
      ..remove('validUntil');
  }
  return result
    ..['schemaVersion'] = 1
    ..['storeId'] = 'store-one'
    ..['revision'] = revision
    ..['publicListing'] = listed
    ..['provenance'] = {
      'entryMethod': 'manual',
      'sourceRecordId': 'original-one',
    };
}

class OwnerTransport implements SocialContentTransport {
  OwnerTransport(this.reply);
  final Future<SocialContentResponse> Function(Map<String, Object?> body) reply;
  int calls = 0;
  @override
  Future<SocialContentResponse> postJson(
    Uri endpoint, {
    required Map<String, String> headers,
    required Map<String, Object?> body,
  }) {
    calls++;
    return reply(body);
  }
}
// Host-only adapter delegates to the real strict client; no native provider injection.
class _AdoptionGateway implements WorkspaceCatalogueGateway, WorkspaceCatalogueOwnerGateway,
    WorkspaceProductSubmissionOwnerGateway, WorkspaceReviewedProductSubmissionGateway {
  _AdoptionGateway(this.source);
  final AuthenticatedWorkspaceCatalogueGateway source;
  @override String get realm => source.realm;
  @override bool get productSubmissionSupported => source.productSubmissionSupported;
  @override bool get reviewedProductSubmissionSupported => source.reviewedProductSubmissionSupported;
  @override DateTime get productReviewNow => source.productReviewNow;
  @override Future<WorkspaceCatalogueContentResult> read(BuyV2Product product) => Future.error(const FormatException('Host public reader not connected'));
  @override Future<WorkspaceProductSubmissionRecord?> readProductSubmission(WorkspaceProductSubmissionScope scope, {required bool Function() current}) =>
    source.readProductSubmission(scope, current: current);
  @override Future<WorkspaceProductReviewReadback> readReviewedProductSubmission(WorkspaceProductSubmissionScope scope, {required bool Function() current}) =>
    source.readReviewedProductSubmission(scope, current: current);
  @override Future<WorkspaceProductSubmissionWriteResult> writeProductSubmission(WorkspaceProductSubmissionIntent original,
    {required bool Function() current, bool reconcile = false}) => source.writeProductSubmission(original, current: current, reconcile: reconcile);
  @override Future<WorkspaceCatalogueOwnedSku?> readOwnedSku({required String storeId, required String skuId, required bool Function() current}) =>
    source.readOwnedSku(storeId: storeId, skuId: skuId, current: current);
  @override Future<WorkspaceCatalogueBindingResult> bindReviewed(WorkspaceCatalogueBindingIntent original,
    {required bool Function() current, required bool recoveringUnknown}) => source.bindReviewed(original, current: current, recoveringUnknown: recoveringUnknown);
  @override Future<WorkspaceCatalogueBindingResult> reconcileBinding(WorkspaceCatalogueBindingIntent original, {required bool Function() current}) =>
    source.reconcileBinding(original, current: current);
}
class _LoopbackFamilyHttpOverrides extends HttpOverrides {}
class _LoopbackFamilyTransport implements SocialContentTransport {
  _LoopbackFamilyTransport(this.forward);
  final Future<SocialContentResponse> Function(Map<String, Object?>, Map<String, String>) forward;
  @override Future<SocialContentResponse> postJson(Uri endpoint, {required Map<String, String> headers,
    required Map<String, Object?> body}) => forward(body, headers);
}
class _ConnectedFamilyGateway extends _AdoptionGateway implements WorkspaceVariantFamilyOwnerGateway {
  _ConnectedFamilyGateway(super.source);
  @override bool get variantFamilySubmissionSupported => source.variantFamilySubmissionSupported;
  @override Future<WorkspaceCatalogueContentResult> read(BuyV2Product product) => source.read(product);
  @override Future<WorkspaceVariantFamilyHead> readVariantFamily(WorkspaceVariantFamilyScope scope,
    {required bool Function() current}) => source.readVariantFamily(scope, current: current);
  @override Future<WorkspaceVariantFamilyWriteResult> writeVariantFamily(WorkspaceVariantFamilyIntent original,
    {required bool Function() current, bool reconcile = false}) => source.writeVariantFamily(original, current: current, reconcile: reconcile);
}
class _AdoptionInventory implements WorkInventoryStore, WorkInventoryReceiptProjectionGuard {
  _AdoptionInventory(this.source);
  final SecureWorkInventoryStore source;
  bool failReviewed = false;
  Completer<void>? holdSave, enteredSave;
  final writes = <String>[];
  @override Future<WorkspaceSavedInventory?> read(String account, String store, {required bool qa}) => source.read(account, store, qa: qa);
  @override Future<void> save(WorkspaceSavedInventory inventory, {required int? expectedRevision}) async {
    writes.add(inventory.store);
    if (holdSave != null) { if (enteredSave?.isCompleted == false) enteredSave!.complete(); await holdSave!.future; }
    if (failReviewed && inventory.reviewedCatalogueLinks.isNotEmpty) throw const WorkGatewayException('Host failed local link write');
    await source.save(inventory, expectedRevision: expectedRevision);
  }
  @override Future<bool> projectReceipt(String account, String store, {required bool qa, required int? expectedRevision,
    required Future<WorkspaceSavedInventory?> Function(WorkspaceSavedInventory? previous) commit}) =>
    source.projectReceipt(account, store, qa: qa, expectedRevision: expectedRevision, commit: commit);
}
class _AdoptionHeldLedger implements WorkLedgerCheckpointStore {
  _AdoptionHeldLedger(this.source);
  final WorkLedgerCheckpointStore source;
  final gate = Completer<void>(), entered = Completer<void>();
  @override Future<WorkspaceLedgerCheckpoint?> read(String account, String store) async {
    if (!entered.isCompleted) entered.complete(); await gate.future;
    return source.read(account, store);
  }
  @override Future<void> save(WorkspaceLedgerCheckpoint checkpoint, {required int? expectedRevision}) => source.save(checkpoint, expectedRevision: expectedRevision);
}

class RetiringOwnerCredentials extends Credentials {
  RetiringOwnerCredentials(this.retire);
  final void Function() retire;
  @override
  Future<String> appCheckToken(SocialAppCheckTokenMode mode) async {
    retire();
    return super.appCheckToken(mode);
  }
}

AuthenticatedWorkspaceCatalogueGateway ownerGateway(
  OwnerTransport transport, [
  Credentials? credentials,
]) => AuthenticatedWorkspaceCatalogueGateway(
  endpoint: Uri.parse(
    'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace',
  ),
  credentials: credentials ?? Credentials(),
  transport: transport,
  now: () => at,
  ownerAccountId: 'owner-one',
);

WorkspaceCatalogueBindingIntent ownerIntent() =>
    WorkspaceCatalogueOwnedSku.decode(
      ownerRow(),
      storeId: 'store-one',
      skuId: 'sku-one',
      now: at,
      realm: 'production',
    ).listingIntent(
      accountId: 'owner-one',
      idempotencyKey: 'binding-original',
      listed: true,
    );

SocialContentResponse ownerAck(Map<String, Object?> request) =>
    SocialContentResponse(
      statusCode: 200,
      body: jsonEncode({
        'ok': true,
        'data': {
          'schemaVersion': 1,
          'realm': 'production',
          'storeId': 'store-one',
          'saved': {
            ...request['sku'] as Map,
            'schemaVersion': 1,
            'storeId': 'store-one',
            'revision': 2,
            'observedAt': at.toIso8601String(),
          },
          'publicationConfirmed': false,
        },
      }),
    );

const listingScope = (
  account: 'owner-one',
  store: 'store-one',
  realm: 'production',
);

class BindingStore implements WorkspaceCatalogueBindingPendingStore {
  WorkspaceCatalogueBindingIntent? saved;
  Future<WorkspaceCatalogueBindingIntent?> Function()? read;
  bool failWrite = false, failRemoval = false;
  @override
  Future<WorkspaceCatalogueBindingIntent?> readPending(
    WorkspaceCatalogueBindingScope scope,
  ) async => read == null ? saved : await read!();
  @override
  Future<void> savePending(WorkspaceCatalogueBindingIntent original) async {
    if (failWrite) throw StateError('isolated journal failure');
    saved = original;
  }

  @override
  Future<void> removePending(WorkspaceCatalogueBindingIntent original) async {
    if (failRemoval) throw StateError('isolated removal failure');
    expect(saved?.idempotencyKey, original.idempotencyKey);
    saved = null;
  }
}

WorkspaceCatalogueBindingResult listingSaved(
  WorkspaceCatalogueBindingIntent original,
) {
  final data = jsonDecode(ownerAck(original.body).body) as Map;
  return WorkspaceCatalogueBindingResult(
    WorkspaceCatalogueBindingState.saved,
    saved: WorkspaceCatalogueOwnedSku.decode(
      (data['data'] as Map)['saved'],
      storeId: original.storeId,
      skuId: original.skuId,
      realm: original.realm,
      now: at,
    ),
  );
}

class ListingGateway implements WorkspaceCatalogueOwnerGateway {
  @override
  String get realm => 'production';
  int submitted = 0, reconciled = 0;
  Future<WorkspaceCatalogueBindingResult> Function(
    WorkspaceCatalogueBindingIntent,
    bool Function(),
  )
  write = (original, _) async => listingSaved(original);
  Future<WorkspaceCatalogueBindingResult> Function(
    WorkspaceCatalogueBindingIntent,
  )
  check = (_) async => const WorkspaceCatalogueBindingResult(
    WorkspaceCatalogueBindingState.unknown,
  );
  @override
  Future<WorkspaceCatalogueOwnedSku?> readOwnedSku({
    required String storeId,
    required String skuId,
    required bool Function() current,
  }) async => null;
  @override
  Future<WorkspaceCatalogueBindingResult> bindReviewed(
    WorkspaceCatalogueBindingIntent original, {
    required bool Function() current,
    required bool recoveringUnknown,
  }) {
    submitted++;
    expect(recoveringUnknown, false);
    return write(original, current);
  }

  @override
  Future<WorkspaceCatalogueBindingResult> reconcileBinding(
    WorkspaceCatalogueBindingIntent original, {
    required bool Function() current,
  }) {
    reconciled++;
    return check(original);
  }
}

class ListingAccount implements WorkPendingProofStore {
  String owner = 'owner-one';
  @override
  String? get accountScope => owner;
  @override
  Future<Map<String, Object?>?> read(String scope) async => null;
  @override
  Future<void> save(String scope, Map<String, Object?> draft) async {}
  @override
  Future<void> clear(String scope) async {}
}
// Host-only owner changes/held reads; never injected into the phone.
class _HeldWorkspaceAccount extends ListingAccount {
  final holds = <String, Completer<Map<String, Object?>?>>{};
  final entered = <String, Completer<void>>{}, failing = <String>{};
  final reads = <String>[], clears = <String>[];
  final restored = <String, Map<String, Object?>>{};
  @override Future<Map<String, Object?>?> read(String scope) async {
    reads.add(scope);
    final signal = entered[scope]; if (signal != null && !signal.isCompleted) signal.complete();
    if (failing.contains(scope)) throw StateError('Host failed owner recovery read');
    return holds[scope]?.future ?? restored[scope];
  }
  @override Future<void> clear(String scope) async {clears.add(scope);}
}

class SessionCatalogue extends ListingGateway
    implements WorkspaceCatalogueGateway {
  int ownerReads = 0;
  Future<WorkspaceCatalogueOwnedSku?> Function() ownerRead = () async {
    final data = ownerRow();
    (data['provenance'] as Map)['sourceRecordId'] = 'sku-one';
    return WorkspaceCatalogueOwnedSku.decode(
      data,
      storeId: 'store-one',
      skuId: 'sku-one',
      realm: 'production',
      now: at,
    );
  };
  @override
  Future<WorkspaceCatalogueOwnedSku?> readOwnedSku({
    required String storeId,
    required String skuId,
    required bool Function() current,
  }) {
    ownerReads++;
    return ownerRead();
  }

  @override
  Future<WorkspaceCatalogueContentResult> read(BuyV2Product product) async =>
      WorkspaceCatalogueContentResult(
        content: BuyV2ProductContentSnapshot(
          productId: product.id,
          state: BuyV2ProductContentState.unavailable,
          sourceId: 'Isolated host source',
        ),
      );
}

class _SessionFamilyCatalogue extends SessionCatalogue implements WorkspaceVariantFamilyOwnerGateway {
  final family = _FamilyOwner();
  final rows = <String, WorkspaceCatalogueOwnedSku>{};
  Future<void> Function(String)? beforeRead;
  @override
  bool get variantFamilySubmissionSupported => family.variantFamilySubmissionSupported;
  @override
  Future<WorkspaceCatalogueOwnedSku?> readOwnedSku({required String storeId, required String skuId,
      required bool Function() current}) async {
    ownerReads++;
    if (beforeRead != null) await beforeRead!(skuId);
    return current() ? rows[skuId] : null;
  }
  @override
  Future<WorkspaceVariantFamilyHead> readVariantFamily(WorkspaceVariantFamilyScope scope,
      {required bool Function() current}) => family.readVariantFamily(scope, current: current);
  @override
  Future<WorkspaceVariantFamilyWriteResult> writeVariantFamily(WorkspaceVariantFamilyIntent original,
      {required bool Function() current, bool reconcile = false}) => family.writeVariantFamily(original, current: current, reconcile: reconcile);
}

WorkspaceCatalogueItem listingItem() => WorkspaceCatalogueItem(
  id: 'sku-one',
  canonicalId: 'canonical-one',
  categoryId: 'cooking-oil',
  brand: product.brand,
  title: product.title,
  variant: product.variant,
  pack: '1 L',
  sku: 'HOST-ONE',
  barcode: '',
  purchasePrice: 230,
  sellingPrice: 260,
  mrp: 280,
  unitPrice: '₹260/L',
  stock: 7,
  deliveryPromise: 'Host Store pickup',
  origin: 'Host fixture source',
  visualLabel: 'Host image pending',
  visualKind: 'catalogue-packshot',
  publicListing: false,
  catalogueFactsRequireReview: true,
  packMeasure: const WorkspacePackMeasure(
    unit: BuyV2ComparisonUnit.litre,
    quantityMilli: 1000,
  ),
  content: const WorkspaceProductContent(
    description: 'Verified host description',
    highlights: ['One litre'],
    specifications: {'Oil': 'Sunflower'},
  ),
  stockEntry: WorkspaceStockEntry(
    method: WorkspaceStockEntryMethod.manual,
    productId: 'sku-one',
    sku: 'HOST-ONE',
    pack: '1 L',
    stockMode: WorkspaceStockMode.exactQuantity,
    quantity: 7,
    purchasePriceRupees: 230,
    recordedAt: at,
    stockAsOf: at,
  ),
);
WorkSession listingSession(SessionCatalogue source, BindingStore journal) =>
    WorkSession(
        contactDraftStore: ListingAccount(),
        catalogueGateway: source,
        catalogueBindingPendingStoreFactory: (_) => journal,
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
      ..workspaceCatalogueItems.add(listingItem());

Future<void> openListingEditor(WidgetTester tester, WorkSession work, {Size size = const Size(360, 740), Key? captureKey, ThemeData? theme}) async {
  tester.view.devicePixelRatio = 1; tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  work.retailerSetupSaved = true; work.reviewStage = WorkReviewStage.live;
  final core = BuySession(), consumer = BuyV2Session(core: core, reviewDataEnabled: false);
  addTearDown(work.dispose); addTearDown(core.dispose); addTearDown(consumer.dispose);
  final app = MaterialApp(theme: theme, home: WorkWorkspaceDashboardScreen(session: work,
    procurementSession: consumer, initialSection: 'stock', accountAuthenticated: true));
  await tester.pumpWidget(captureKey == null ? app : RepaintBoundary(key: captureKey, child: app));
  await tester.pumpAndSettle();
  final edit = find.byKey(const Key('work-catalogue-edit-sku-one'));
  await tester.ensureVisible(edit); await tester.tap(edit); await tester.pumpAndSettle();
}

// Isolated controller/journal fixtures; not injected into device inventory.
class _StockJournal implements WorkspaceStoreStockJournal {
  WorkspaceStoreStockIntent? saved;
  bool failSave = false, failRemove = false;
  @override Future<WorkspaceStoreStockIntent?> readPending(WorkspaceStoreStockScope scope) async => saved;
  @override Future<void> savePending(WorkspaceStoreStockIntent original) async {
    if (failSave) throw StateError('host save failure');
    if (saved != null && saved!.serverFingerprint != original.serverFingerprint) throw const FormatException();
    saved = WorkspaceStoreStockIntent.fromJson(original.toJson());
  }
  @override Future<void> removePending(WorkspaceStoreStockIntent original) async {
    if (failRemove) throw StateError('host removal failure');
    if (saved?.serverFingerprint != original.serverFingerprint) throw const FormatException();
    saved = null;
  }
}
class _StockOwner implements WorkspaceStoreStockOwnerGateway {
  @override String get realm => 'evaluation';
  @override bool stockSnapshotsSupported = true;
  WorkspaceStoreStockHead head = const WorkspaceStoreStockHead(state: 'none', currentRevision: 0);
  final sent = <({WorkspaceStoreStockIntent original, bool reconcile})>[];
  Future<WorkspaceStoreStockWriteResult> Function(WorkspaceStoreStockIntent original, bool reconcile)? write;
  @override Future<WorkspaceStoreStockHead> readStoreStockHead(WorkspaceStoreStockScope scope, Map<String, dynamic> binding,
    {required bool Function() current}) async => head;
  @override Future<WorkspaceStoreStockWriteResult> writeStoreStock(WorkspaceStoreStockIntent original,
    {required bool Function() current, bool reconcile = false}) async {
    sent.add((original: original, reconcile: reconcile));
    return write == null ? const WorkspaceStoreStockWriteResult(WorkspaceStoreStockWriteState.unknown) : await write!(original, reconcile);
  }
}
class _StockSessionCatalogue extends SessionCatalogue implements WorkspaceStoreStockOwnerGateway {
  _StockSessionCatalogue(this.stockOwner);
  final _StockOwner stockOwner;
  @override String get realm => stockOwner.realm;
  @override bool get stockSnapshotsSupported => stockOwner.stockSnapshotsSupported;
  @override Future<WorkspaceStoreStockHead> readStoreStockHead(WorkspaceStoreStockScope scope, Map<String, dynamic> binding,
    {required bool Function() current}) => stockOwner.readStoreStockHead(scope, binding, current: current);
  @override Future<WorkspaceStoreStockWriteResult> writeStoreStock(WorkspaceStoreStockIntent original,
    {required bool Function() current, bool reconcile = false}) => stockOwner.writeStoreStock(original, current: current, reconcile: reconcile);
}

void main() {
  const stockScope = (account: 'owner-one', store: 'store-one', realm: 'evaluation', sku: 'sku-one');
  WorkspaceCatalogueOwnedSku stockMirror({WorkspaceStockEntryMethod method = WorkspaceStockEntryMethod.manual}) => WorkspaceCatalogueOwnedSku.decode(
    ownerRow(listed: true)..['provenance'] = {'entryMethod': method.name, 'sourceRecordId': 'sku-one'}, storeId: 'store-one',
    skuId: 'sku-one', now: at, realm: 'evaluation');
  WorkspaceSavedInventory stockCheckpoint({WorkspaceStockEntryMethod method = WorkspaceStockEntryMethod.manual,
      int stock = 7, bool availabilityOnly = false, DateTime? savedAt, bool qa = true, String account = 'owner-one',
      String store = 'store-one', bool listed = true}) {
    final mirror = stockMirror(), raw = listingItem().toInventoryJson();
    raw['stock'] = stock; raw['publicListing'] = listed;
    raw['stockMode'] = availabilityOnly ? 'availabilityOnly' : 'exactQuantity';
    raw['stockEntry'] = {...listingItem().stockEntry!.toJson(), 'method': method.name,
      'stockMode': availabilityOnly ? 'availabilityOnly' : 'exactQuantity', 'quantity': availabilityOnly ? null : 99};
    final item = WorkspaceCatalogueItem.fromInventoryJson(raw);
    final link = WorkspaceReviewedCatalogueLink(realm: 'evaluation', storeId: 'store-one', skuId: 'sku-one',
      canonicalProductId: mirror.canonicalProductId, verifiedPackId: mirror.verifiedPackId, mirrorRevision: mirror.revision,
      candidateRevision: 1, candidateFingerprint: 'A' * 64, submissionRevision: 1, submissionFingerprint: 'B' * 64, authoredSha256: 'C' * 64);
    return WorkspaceSavedInventory(account: account, store: store, qa: qa, revision: 12, savedAt: savedAt ?? at,
      products: [item], movements: const [], reviewedCatalogueLinks: [link]);
  }
  WorkspaceStoreStockIntent stockOriginal() => WorkspaceStoreStockIntent(scope: stockScope, expectedRevision: 0, idempotencyKey: 'stock-original',
    input: WorkspaceStoreStockInput.fromSaved(stockCheckpoint(), stockMirror(), scope: stockScope, now: at));
  Map<String, dynamic> stockReply(WorkspaceStoreStockIntent original, {String state = 'reported'}) {
    final body = <String, dynamic>{'schemaVersion': 1, 'realm': original.scope.realm, 'storeId': original.scope.store,
      'binding': original.input.binding, 'ownerBinding': _mediaHash([original.scope.realm, original.scope.store, original.scope.account]),
      'revision': original.expectedRevision + 1, 'reportedAt': at.toIso8601String(), 'source': original.input.source};
    final until = DateTime.parse(original.input.source['savedAt'] as String).add(const Duration(minutes: 5)).toIso8601String();
    return {'schemaVersion': 1, 'stockSnapshotVersion': 1, 'realm': original.scope.realm, 'storeId': original.scope.store,
      'binding': original.input.binding, 'state': state, 'record': state == 'reported' ? {...body, 'integrity': _mediaHash(body)} : null,
      'idempotencyKey': original.idempotencyKey, 'orderingAvailable': false, 'reservationConfirmed': false,
      if (state == 'expired') ...{'expiredAt': until, 'settledAt': until, 'originalFingerprint': original.serverFingerprint}};
  }
  AuthenticatedWorkspaceCatalogueGateway stockGateway(SocialContentTransport transport, {Credentials? credentials, bool enabled = true,
      String account = 'owner-one', DateTime Function()? clock}) => AuthenticatedWorkspaceCatalogueGateway(
    endpoint: Uri.parse('https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
    credentials: credentials ?? Credentials(), transport: transport, realm: 'evaluation', ownerAccountId: account,
    stockSnapshotsSupported: enabled, now: clock ?? () => at);
  Map<String, dynamic> publicStockReply(WorkspacePublicStockQuery query, {bool unknown = false}) => {
    'schemaVersion': 1, 'stockSnapshotVersion': 1, 'realm': query.realm, 'storeId': query.storeId, 'binding': query.binding,
    'state': unknown ? 'unknown' : 'reported', 'observedAt': at.toIso8601String(), 'requestedPacks': query.requestedPacks,
    'orderingAvailable': false, 'reservationConfirmed': false, 'stock': unknown ? null : <String, dynamic>{
      'source': 'selling_store_checkpoint', 'reportedAt': at.toIso8601String(), 'savedAt': at.toIso8601String(),
      'validUntil': at.add(const Duration(minutes: 5)).toIso8601String(), 'reportRevision': 1, 'available': true, 'quantityAvailable': true}};
  test('LF11 Stock gateway is disabled for legacy connections', () {
    expect((gateway(Transport(page())) as dynamic).stockSnapshotsSupported, isFalse);
  });
  test('LF11 production builder preserves explicit Stock capability flag', () {
    final source = buildWorkspaceCatalogueGateway(credentials: Credentials());
    const endpoint = String.fromEnvironment('MOOLSOCIAL_WORKSPACE_URL');
    if (endpoint.isEmpty) { expect(source, isA<UnavailableWorkspaceCatalogueGateway>()); return; }
    expect(source, isA<AuthenticatedWorkspaceCatalogueGateway>());
    expect((source as AuthenticatedWorkspaceCatalogueGateway).stockSnapshotsSupported,
      const bool.fromEnvironment('MOOLSOCIAL_STORE_STOCK_V1'));
  });
  for (final method in WorkspaceStockEntryMethod.values) {
    test('LF11 Stock capture uses current saved selling packs not opening quantity ${method.name}', () {
      final saved = stockCheckpoint(method: method, savedAt: at.add(const Duration(microseconds: 123))), before = jsonEncode(saved.toJson());
      final input = WorkspaceStoreStockInput.fromSaved(saved, stockMirror(method: method), scope: stockScope, now: at.add(const Duration(milliseconds: 1)));
      expect(input.source['quantityPacks'], 7); expect(input.source['inventoryRevision'], 12);
      expect(input.source['savedAt'], at.toIso8601String()); expect(jsonEncode(saved.toJson()), before);
      for (final field in ['purchasePrice', 'purchasePriceMinor', 'movements', 'privatePhoto', 'products', 'account', 'method']) {
        expect(jsonEncode(input.toJson()).contains(field), isFalse);
      }
      final changedCopy = input.toJson(); (changedCopy['source'] as Map)['quantityPacks'] = 999;
      expect(input.source['quantityPacks'], 7);
    });
  }
  test('LF11 Stock capture distinguishes zero, availability-only and wrong checkpoint scope', () {
    expect(WorkspaceStoreStockInput.fromSaved(stockCheckpoint(stock: 0), stockMirror(), scope: stockScope, now: at).source['quantityPacks'], 0);
    final unknown = WorkspaceStoreStockInput.fromSaved(stockCheckpoint(stock: 999, availabilityOnly: true), stockMirror(), scope: stockScope, now: at);
    expect(unknown.source['quantityPacks'], isNull); expect(unknown.source['mode'], 'availability_only');
    for (final saved in [stockCheckpoint(qa: false), stockCheckpoint(account: 'other-owner'), stockCheckpoint(store: 'other-store'),
      stockCheckpoint(listed: false), stockCheckpoint(savedAt: at.add(const Duration(milliseconds: 1))),
      stockCheckpoint(savedAt: at.subtract(const Duration(minutes: 5)))]) {
      expect(() => WorkspaceStoreStockInput.fromSaved(saved, stockMirror(), scope: stockScope, now: at), throwsFormatException);
    }
    final raw = stockMirror().toJson(); (raw['pack'] as Map)['quantityMilli'] = 2000;
    final changed = WorkspaceCatalogueOwnedSku.decode(raw, storeId: 'store-one', skuId: 'sku-one', now: at, realm: 'evaluation');
    expect(() => WorkspaceStoreStockInput.fromSaved(stockCheckpoint(), changed, scope: stockScope, now: at), throwsFormatException);
  });
  test('LF11 Stock original restoration remains immutable and clock independent', () {
    final original = stockOriginal(), raw = original.toJson();
    expect(WorkspaceStoreStockIntent.fromJson(jsonDecode(jsonEncode(raw))).serverFingerprint, original.serverFingerprint);
    ((raw['input'] as Map)['source'] as Map)['quantityPacks'] = 10;
    expect(original.input.source['quantityPacks'], 7); expect(original.body['expectedRevision'], 0);
    final expired = stockReply(original, state: 'expired');
    expect(WorkspaceStoreStockHead.decode(expired, stockScope, original.input.binding, at, original: original).state, 'expired');
    expect(() => WorkspaceStoreStockHead.decode({...expired, 'originalFingerprint': 'D' * 64}, stockScope,
      original.input.binding, at, original: original), throwsFormatException);
    expect(() => WorkspaceStoreStockHead.decode({...expired, 'settledAt': at.toIso8601String()}, stockScope,
      original.input.binding, at, original: original), throwsFormatException);
  });
  test('LF11 Stock gateway binds original, preserves result copies and uses mutation versus read AppCheck', () async {
    final original = stockOriginal(), reply = stockReply(original), transport = Transport(reply), credentials = Credentials();
    final api = stockGateway(transport, credentials: credentials);
    expect(api.forOwnerAccount('owner-one').stockSnapshotsSupported, isTrue);
    final posted = await api.writeStoreStock(original, current: () => true);
    expect(posted.state, WorkspaceStoreStockWriteState.reported); expect(posted.record!.source['quantityPacks'], 7);
    expect(transport.sent!['operation'], 'publishStoreStockSnapshot');
    expect(credentials.modes.last, SocialAppCheckTokenMode.limitedUse);
    expect(await api.writeStoreStock(original, current: () => true, reconcile: true).then((r) => r.state), WorkspaceStoreStockWriteState.reported);
    expect(credentials.modes.last, SocialAppCheckTokenMode.standard);
    ((reply['record'] as Map)['source'] as Map)['quantityPacks'] = 500;
    expect(posted.record!.source['quantityPacks'], 7);
    expect((await api.writeStoreStock(original, current: () => true)).state, WorkspaceStoreStockWriteState.unknown);
    transport.data = stockReply(original, state: 'not_found');
    expect((await api.writeStoreStock(original, current: () => true, reconcile: true)).state, WorkspaceStoreStockWriteState.notFound);
    expect((await api.writeStoreStock(original, current: () => true)).state, WorkspaceStoreStockWriteState.unknown);
    transport.data = stockReply(original, state: 'expired');
    expect((await api.writeStoreStock(original, current: () => true, reconcile: true)).state, WorkspaceStoreStockWriteState.expired);
  });
  test('LF11 Stock gateway never sends disabled, wrong-owner or retired-before-dispatch requests', () async {
    final original = stockOriginal(), transport = Transport(stockReply(original));
    for (final api in [stockGateway(transport, enabled: false), stockGateway(transport, account: 'other-owner')]) {
      expect((await api.writeStoreStock(original, current: () => true)).state, WorkspaceStoreStockWriteState.notSent);
    }
    expect(transport.sent, isNull);
    var live = true;
    final api = stockGateway(transport, credentials: RetiringOwnerCredentials(() => live = false));
    expect((await api.writeStoreStock(original, current: () => live)).state, WorkspaceStoreStockWriteState.notSent);
    expect(transport.sent, isNull);
  });
  test('LF11 Stock gateway drops an acknowledgement after account lifetime retirement', () async {
    final original = stockOriginal(); var live = true;
    final transport = OwnerTransport((body) async {live = false; return SocialContentResponse(statusCode: 200,
      body: jsonEncode({'ok': true, 'data': stockReply(original)}));});
    expect((await stockGateway(transport).writeStoreStock(original, current: () => live)).state, WorkspaceStoreStockWriteState.unknown);
    expect(transport.calls, 1);
  });
  test('LF11 public Stock reader is exact-quantity, independently expiring and never ordering authority', () async {
    final query = WorkspacePublicStockQuery(realm: 'evaluation', storeId: 'store-one', binding: stockOriginal().input.binding, requestedPacks: 3);
    final reply = publicStockReply(query), transport = Transport(reply), credentials = Credentials();
    final result = await stockGateway(transport, credentials: credentials).readPublicStoreStock(query, current: () => true);
    expect(result.quantityAvailable, isTrue); expect(result.freshAt(at), isTrue);
    expect(result.freshAt(at.subtract(const Duration(milliseconds: 1))), isFalse,
      reason: 'A cached observation cannot remain current after the clock moves before it.');
    expect(result.freshAt(at.add(const Duration(minutes: 5))), isFalse);
    expect(credentials.modes.last, SocialAppCheckTokenMode.standard); expect(result.toJson()['orderingAvailable'], false);
    expect(() => WorkspacePublicStockResult.decode(reply, query, at.add(const Duration(minutes: 5))), throwsFormatException);
    expect(() => WorkspacePublicStockResult.decode({...reply, 'requestedPacks': 4}, query, at), throwsFormatException);
    expect(() => WorkspacePublicStockResult.decode({...reply, 'orderingAvailable': true}, query, at), throwsFormatException);
    final unknown = WorkspacePublicStockResult.decode(publicStockReply(query, unknown: true), query, at);
    expect(unknown.available, isNull); expect(unknown.quantityAvailable, isNull); expect(unknown.freshAt(at), false);
    final uncounted = publicStockReply(query); (uncounted['stock'] as Map)['quantityAvailable'] = null;
    expect(WorkspacePublicStockResult.decode(uncounted, query, at).quantityAvailable, isNull);
    (uncounted['stock'] as Map)['quantityPacks'] = 7;
    expect(() => WorkspacePublicStockResult.decode(uncounted, query, at), throwsFormatException);
  });
  test('LF11 Stock capture fences identity edits without coupling prices or descriptions', () {
    WorkspaceSavedInventory edited(WorkspaceCatalogueItem item) {
      final base = stockCheckpoint();
      return WorkspaceSavedInventory(account: base.account, store: base.store, qa: base.qa, revision: base.revision,
        savedAt: base.savedAt, products: [item], movements: [], reviewedCatalogueLinks: base.reviewedCatalogueLinks);
    }
    final base = stockCheckpoint().products.single;
    for (final key in ['sku', 'title', 'brand', 'variant', 'categoryId']) {
      final raw = base.toInventoryJson()..[key] = key == 'categoryId' ? 'snacks' : 'Different $key';
      expect(() => WorkspaceStoreStockInput.fromSaved(edited(WorkspaceCatalogueItem.fromInventoryJson(raw)), stockMirror(),
        scope: stockScope, now: at), throwsFormatException, reason: key);
    }
    final changed = base.copyWith(stock: 3, sellingPrice: 270, content: const WorkspaceProductContent(description: 'Private edit'));
    expect(WorkspaceStoreStockInput.fromSaved(edited(changed), stockMirror(), scope: stockScope, now: at).source['quantityPacks'], 3);
  });
  WorkspaceStoreStockRecord stockRecord(WorkspaceStoreStockIntent original) => WorkspaceStoreStockRecord.decode(
    stockReply(original)['record'], stockScope, at);
  WorkspaceStoreStockController stockController(_StockOwner api, WorkspaceStoreStockJournal journal, {Object? Function()? context, DateTime Function()? clock}) =>
    WorkspaceStoreStockController(scope: stockScope, gateway: api, journal: journal, context: context ?? () => 'current', now: clock ?? () => at);
  test('LF11 Stock controller journals before dispatch and deduplicates confirmed saved source', () async {
    final api = _StockOwner(), journal = _StockJournal(), controller = stockController(api, journal);
    addTearDown(controller.dispose);
    api.write = (original, _) async {
      expect(journal.saved!.serverFingerprint, original.serverFingerprint);
      final record = stockRecord(original); api.head = WorkspaceStoreStockHead(state: 'reported', currentRevision: record.revision, record: record);
      return WorkspaceStoreStockWriteResult(WorkspaceStoreStockWriteState.reported, record);
    };
    final input = stockOriginal().input;
    expect(await controller.synchronize(input, inputCurrent: () => true), true);
    expect(journal.saved, isNull); expect(api.sent, hasLength(1));
    expect(await controller.synchronize(input, inputCurrent: () => true), true);
    expect(api.sent, hasLength(1));
    api.head = const WorkspaceStoreStockHead(state: 'none', currentRevision: 0);
    expect(await controller.synchronize(input, inputCurrent: () => true), false);
    expect(api.sent, hasLength(1));
  });
  test('LF11 Stock unknown survives a new controller and not-found retries only the exact expired original', () async {
    final api = _StockOwner(), journal = _StockJournal(), first = stockController(api, journal);
    expect(await first.synchronize(stockOriginal().input, inputCurrent: () => true), false);
    final original = journal.saved!; first.dispose();
    final next = stockController(api, journal, clock: () => at.add(const Duration(hours: 1))); addTearDown(next.dispose);
    api.write = (attempt, reconcile) async {
      expect(attempt.serverFingerprint, original.serverFingerprint);
      return WorkspaceStoreStockWriteResult(reconcile ? WorkspaceStoreStockWriteState.notFound : WorkspaceStoreStockWriteState.expired);
    };
    expect(await next.recover(), true); expect(journal.saved, isNull);
    expect(api.sent.map((e) => e.reconcile), [false, true, false]);
    expect(api.sent.map((e) => e.original.serverFingerprint).toSet(), {original.serverFingerprint});
  });
  test('LF11 Stock failed journal save and removal never allocate a replacement original', () async {
    final api = _StockOwner(), journal = _StockJournal()..failSave = true, controller = stockController(api, journal);
    addTearDown(controller.dispose);
    expect(await controller.synchronize(stockOriginal().input, inputCurrent: () => true), false);
    expect(api.sent, isEmpty); final original = controller.pending!;
    journal.failSave = false; journal.failRemove = true;
    api.write = (attempt, _) async => WorkspaceStoreStockWriteResult(WorkspaceStoreStockWriteState.reported, stockRecord(attempt));
    expect(await controller.recover(), false); expect(journal.saved!.serverFingerprint, original.serverFingerprint);
    journal.failRemove = false;
    expect(await controller.recover(), true); expect(journal.saved, isNull);
    expect(api.sent.map((e) => e.original.serverFingerprint).toSet(), {original.serverFingerprint});
  });
  test('LF11 Stock account retirement retains owner original and suppresses later sends', () async {
    Object? lifetime = Object(); final api = _StockOwner(), journal = _StockJournal(), controller = stockController(api, journal, context: () => lifetime);
    addTearDown(controller.dispose);
    api.write = (original, _) async { lifetime = Object(); return WorkspaceStoreStockWriteResult(WorkspaceStoreStockWriteState.reported, stockRecord(original)); };
    expect(await controller.synchronize(stockOriginal().input, inputCurrent: () => true), false);
    expect(journal.saved, isNotNull); expect(await controller.recover(), false); expect(api.sent, hasLength(1));
  });
  test('LF11 encrypted Stock journal survives instances, rejects overwrites and fences scope', () async {
    TestWidgetsFlutterBinding.ensureInitialized(); FlutterSecureStorage.setMockInitialValues({});
    var account = stockScope.account;
    SecureWorkStoreStockJournal fresh() => SecureWorkStoreStockJournal(currentAccount: () => account);
    final original = stockOriginal(); await fresh().savePending(original);
    expect((await fresh().readPending(stockScope))!.serverFingerprint, original.serverFingerprint);
    final other = WorkspaceStoreStockIntent(scope: stockScope, expectedRevision: 0, idempotencyKey: 'other-original', input: original.input);
    await expectLater(fresh().savePending(other), throwsFormatException); await expectLater(fresh().removePending(other), throwsFormatException);
    expect(await fresh().readPending((account: account, store: 'other-store', realm: 'evaluation', sku: 'sku-one')), isNull);
    expect(await fresh().readPending((account: account, store: 'store-one', realm: 'production', sku: 'sku-one')), isNull);
    account = 'other-account'; await expectLater(fresh().readPending(stockScope), throwsA(isA<WorkGatewayException>()));
    account = stockScope.account; await fresh().removePending(original); expect(await fresh().readPending(stockScope), isNull);
  });
  test('LF11 Stock physical journal completion stays serialized after caller timeout', () async {
    final storage = _DelayedDetailsStorage(), original = stockOriginal();
    SecureWorkStoreStockJournal fresh() => SecureWorkStoreStockJournal(storage: storage, currentAccount: () => stockScope.account);
    final save = fresh().savePending(original); await storage.entered.future;
    await expectLater(save.timeout(const Duration(milliseconds: 1)), throwsA(isA<TimeoutException>()));
    final remove = fresh().removePending(original); await Future<void>.delayed(Duration.zero); expect(storage.writes, 1);
    storage.release.complete(); await save; await remove;
    expect(storage.writes, 2); expect(await fresh().readPending(stockScope), isNull);
  });
  test('LF11 WorkSession uploads only successfully saved Stock and never editor quantities or failed saves', () async {
    TestWidgetsFlutterBinding.ensureInitialized(); FlutterSecureStorage.setMockInitialValues({});
    final account = ListingAccount(), api = _StockOwner()..stockSnapshotsSupported = false, journal = _StockJournal();
    final source = _StockSessionCatalogue(api)..ownerRead = () async => stockMirror();
    final inventory = _AdoptionInventory(SecureWorkInventoryStore(accountScope: () => account.owner));
    await inventory.save(WorkspaceSavedInventory.fromJson({...stockCheckpoint().toJson(), 'revision': 1}), expectedRevision: null);
    final work = WorkSession(contactDraftStore: account, inventoryStore: inventory, catalogueGateway: source,
      storeStockJournalFactory: (_) => journal)
      ..activeWorkspace = const WorkWorkspace(id: 'store-one', name: 'Host Store', profileLabel: 'Grocery',
        profileId: 'retailer-grocery', area: 'Jaipur', verified: true) ..workspaceId = 'store-one';
    addTearDown(work.dispose);
    expect(await work.loadWorkspaceInventory(), true);
    api.stockSnapshotsSupported = true;
    api.write = (original, _) async {
      final raw = stockReply(original)['record'] as Map<String, dynamic>;
      raw['reportedAt'] = original.input.source['savedAt'];
      raw.remove('integrity'); raw['integrity'] = _mediaHash(raw);
      final record = WorkspaceStoreStockRecord.decode(raw, stockScope, DateTime.now().toUtc());
      api.head = WorkspaceStoreStockHead(state: 'reported', currentRevision: record.revision, record: record);
      return WorkspaceStoreStockWriteResult(WorkspaceStoreStockWriteState.reported, record);
    };
    expect(await work.retryWorkspaceInventorySave(), true);
    await work.workspaceStoreStockReportsSettled;
    expect(api.sent, hasLength(1)); expect(api.sent.single.original.input.source['quantityPacks'], 7);
    final saved = (await inventory.read(account.owner, 'store-one', qa: true))!;
    expect(api.sent.single.original.input.source['inventoryRevision'], saved.revision);
    // An unsaved list/editor change is not the durable checkpoint.
    work.workspaceCatalogueItems[0] = work.workspaceCatalogueItems.single.copyWith(stock: 2);
    expect(await work.refreshWorkspaceStoreStock(), true);
    expect(api.sent, hasLength(1));
    inventory.failReviewed = true;
    expect(await work.retryWorkspaceInventorySave(), false);
    await work.workspaceStoreStockReportsSettled; expect(api.sent, hasLength(1));
    expect(work.workspaceInventoryError, isNotNull);
    inventory.failReviewed = false;
    expect(await work.retryWorkspaceInventorySave(), true);
    await work.workspaceStoreStockReportsSettled;
    expect(api.sent, hasLength(2)); expect(api.sent.last.original.input.source['quantityPacks'], 2);
    expect(work.workspaceOrders, isEmpty); expect(work.workspaceInvoices, isEmpty);
    expect(work.workspaceCatalogueItems, hasLength(1));
  });
  test('LF11 WorkSession fences Store changes during mirror read and keeps saved Stock local', () async {
    TestWidgetsFlutterBinding.ensureInitialized(); FlutterSecureStorage.setMockInitialValues({});
    final account = ListingAccount(), api = _StockOwner()..stockSnapshotsSupported = false, journal = _StockJournal();
    final entered = Completer<void>(), release = Completer<WorkspaceCatalogueOwnedSku?>();
    final source = _StockSessionCatalogue(api)..ownerRead = () { if (!entered.isCompleted) entered.complete(); return release.future; };
    final inventory = SecureWorkInventoryStore(accountScope: () => account.owner);
    await inventory.save(WorkspaceSavedInventory.fromJson({...stockCheckpoint().toJson(), 'revision': 1}), expectedRevision: null);
    final work = WorkSession(contactDraftStore: account, inventoryStore: inventory, catalogueGateway: source,
      storeStockJournalFactory: (_) => journal)
      ..activeWorkspace = const WorkWorkspace(id: 'store-one', name: 'Host Store', profileLabel: 'Grocery',
        profileId: 'retailer-grocery', area: 'Jaipur', verified: true) ..workspaceId = 'store-one';
    addTearDown(work.dispose); expect(await work.loadWorkspaceInventory(), true);
    api.stockSnapshotsSupported = true; expect(await work.retryWorkspaceInventorySave(), true);
    final pending = work.workspaceStoreStockReportsSettled; await entered.future;
    work.activeWorkspace = const WorkWorkspace(id: 'other-store', name: 'Other', profileLabel: 'Grocery',
      profileId: 'retailer-grocery', area: 'Jaipur', verified: true);
    release.complete(stockMirror()); await pending;
    expect(api.sent, isEmpty); expect(journal.saved, isNull);
    expect((await inventory.read(account.owner, 'store-one', qa: true))!.products.single.stock, 7);
  });
  for (final failProjection in [false, true]) {
    test('LF11 committed Counter sale seven to six projects saved Stock and recovers without reposting failure=$failProjection', () async {
      TestWidgetsFlutterBinding.ensureInitialized(); FlutterSecureStorage.setMockInitialValues({});
      final account = ListingAccount(), api = _StockOwner()..stockSnapshotsSupported = false, journal = _StockJournal();
      final source = _StockSessionCatalogue(api)..ownerRead = () async => stockMirror();
      final inventory = _AdoptionInventory(SecureWorkInventoryStore(accountScope: () => account.owner));
      await inventory.save(WorkspaceSavedInventory.fromJson({...stockCheckpoint().toJson(), 'revision': 1}), expectedRevision: null);
      final finance = WorkspaceFinanceSnapshot(accountScope: account.owner, workspaceId: 'store-one', revision: 1, asOf: at,
        salesTodayMinor: 0, duesMinor: 0, availableMinor: 0, heldMinor: 0, requestedMinor: 0, paidOutMinor: 0,
        feesMinor: 0, deliveryAdjustmentsMinor: 0, refundsMinor: 0, taxWithheldMinor: 0, payments: const [], payouts: const [], historyComplete: true);
      final ledger = SecureWorkLedgerCheckpointStore(accountScope: () => account.owner);
      WorkSession fresh() => WorkSession(contactDraftStore: account, inventoryStore: inventory, catalogueGateway: source,
        storeStockJournalFactory: (_) => journal)
        ..activeWorkspace = const WorkWorkspace(id: 'store-one', name: 'Host Store', profileLabel: 'Grocery',
          profileId: 'retailer-grocery', area: 'Jaipur', verified: true) ..workspaceId = 'store-one';
      final work = fresh(); addTearDown(work.dispose);
      expect(await work.loadWorkspaceInventory(), true); expect(work.applyWorkspaceFinance(finance), true);
      expect(work.bindCustomerCollectionGateway(accountScope: account.owner, storeId: 'store-one',
        adapter: StoreReviewCustomerCollectionGateway(finance), checkpointStore: ledger), true);
      expect(await work.recoverCustomerLedger(), true);
      expect(await work.loadWorkspacePublicationPreferences(expectedStoreId: 'store-one'), true);
      expect(work.startNewWorkspaceOrder(), true);
      work.workspaceOrderCustomer = '9000000013'; work.workspaceOrderQuantities['sku-one'] = 1;
      expect(work.saveWorkspaceOrderDraft(customer: work.workspaceOrderCustomer, source: 'Counter',
        fulfilment: 'At the shop', payment: 'Cash', address: ''), true, reason: work.errorMessage);
      final invoice = work.completeWorkspaceCounterSale(); expect(invoice, isNotNull, reason: work.errorMessage);
      expect(invoice!.payableMinor, 26000);
      expect(work.workspaceCatalogueItems.single.stock, 6);
      api.stockSnapshotsSupported = true; inventory.failReviewed = failProjection;
      api.write = (original, _) async {
        final raw = stockReply(original)['record'] as Map<String, dynamic>;
        raw['reportedAt'] = original.input.source['savedAt']; raw.remove('integrity'); raw['integrity'] = _mediaHash(raw);
        final record = WorkspaceStoreStockRecord.decode(raw, stockScope, DateTime.now().toUtc());
        api.head = WorkspaceStoreStockHead(state: 'reported', currentRevision: record.revision, record: record);
        return WorkspaceStoreStockWriteResult(WorkspaceStoreStockWriteState.reported, record);
      };
      expect(await work.recordWorkspaceInvoiceInLedger(invoice), true, reason: work.errorMessage);
      await work.workspaceInventorySaved; await work.workspaceStoreStockReportsSettled;
      final committed = (await ledger.read(account.owner, 'store-one'))!;
      expect(committed.inventory!.quantities!['sku-one'], 6); expect(committed.billedInvoices, hasLength(1));
      final bytes = jsonEncode(committed.toJson());
      if (failProjection) {
        expect(api.sent, isEmpty); expect((await inventory.read(account.owner, 'store-one', qa: true))!.products.single.stock, 7);
      } else { expect(api.sent.single.original.input.source['quantityPacks'], 6); }
      inventory.failReviewed = false;
      final restored = fresh(); addTearDown(restored.dispose);
      expect(await restored.loadWorkspaceInventory(), true);
      expect(restored.applyWorkspaceFinance(finance), true);
      expect(restored.bindCustomerCollectionGateway(accountScope: account.owner, storeId: 'store-one',
        adapter: StoreReviewCustomerCollectionGateway(finance), checkpointStore: ledger), true);
      expect(await restored.recoverCustomerLedger(), true, reason: restored.customerLedgerRecoveryError);
      await restored.workspaceInventorySaved; await restored.workspaceStoreStockReportsSettled;
      expect(restored.workspaceCatalogueItems.single.stock, 6);
      expect((await inventory.read(account.owner, 'store-one', qa: true))!.products.single.stock, 6);
      expect(jsonEncode((await ledger.read(account.owner, 'store-one'))!.toJson()), bytes);
      expect(api.sent.every((attempt) => attempt.original.input.source['quantityPacks'] == 6), true);
      expect(api.sent, isNotEmpty); expect(journal.saved, isNull);
    });
  }
  test('LF11 WorkSession binds the ordinary unbound authenticated catalogue before owner reads', () async {
    TestWidgetsFlutterBinding.ensureInitialized(); FlutterSecureStorage.setMockInitialValues({});
    final account = ListingAccount(), journal = _StockJournal(), sent = <String>[];
    final mirror = stockMirror().toJson();
    final transport = OwnerTransport((body) async {
      final operation = body['operation'] as String; sent.add(operation);
      Map<String, dynamic> result;
      if (operation == 'listStoreCatalogueSkus') {
        result = {'schemaVersion': 1, 'realm': 'evaluation', 'storeId': 'store-one', 'items': [mirror], 'nextCursor': null};
      } else if (operation == 'readStoreStockSnapshot') {
        result = {'schemaVersion': 1, 'stockSnapshotVersion': 1, 'realm': 'evaluation', 'storeId': 'store-one',
          'binding': body['binding'], 'state': 'none', 'record': null, 'idempotencyKey': null,
          'orderingAvailable': false, 'reservationConfirmed': false};
      } else {
        expect(operation, 'publishStoreStockSnapshot');
        final original = WorkspaceStoreStockIntent(scope: stockScope, expectedRevision: body['expectedRevision'] as int,
          idempotencyKey: body['idempotencyKey'] as String, input: WorkspaceStoreStockInput.fromJson({'binding': body['binding'], 'source': body['source']}));
        result = stockReply(original);
        final record = result['record'] as Map<String, dynamic>;
        record['reportedAt'] = original.input.source['savedAt']; record.remove('integrity'); record['integrity'] = _mediaHash(record);
      }
      return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': result}));
    });
    final source = AuthenticatedWorkspaceCatalogueGateway(endpoint: Uri.parse('https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
      credentials: Credentials(), transport: transport, realm: 'evaluation', stockSnapshotsSupported: true);
    expect(source.ownerAccountId, isNull);
    final inventory = SecureWorkInventoryStore(accountScope: () => account.owner);
    await inventory.save(WorkspaceSavedInventory.fromJson({...stockCheckpoint().toJson(), 'revision': 1}), expectedRevision: null);
    final work = WorkSession(gateway: const UnavailableWorkGateway(), contactDraftStore: account, inventoryStore: inventory,
      catalogueGateway: source, storeStockJournalFactory: (_) => journal)
      ..activeWorkspace = const WorkWorkspace(id: 'store-one', name: 'Host Store', profileLabel: 'Grocery',
        profileId: 'retailer-grocery', area: 'Jaipur', verified: true) ..workspaceId = 'store-one';
    addTearDown(work.dispose);
    expect(await work.loadWorkspaceInventory(), true); await work.workspaceStoreStockReportsSettled;
    sent.clear(); expect(await work.retryWorkspaceInventorySave(), true); await work.workspaceStoreStockReportsSettled;
    expect(sent, containsAllInOrder(['listStoreCatalogueSkus', 'readStoreStockSnapshot', 'publishStoreStockSnapshot']));
    expect(journal.saved, isNull);
  });
  test('LF11 actual service Stock and terminal-expiry payloads decode through the strict Dart client', () async {
    final path = Platform.environment['LF11_STOCK_LOG'];
    if (path == null) fail('Set LF11_STOCK_LOG to the actual local-emulator producer output.');
    final lines = File(path).readAsLinesSync();
    final report = jsonDecode(lines.singleWhere((l) => l.startsWith('LF11_STORE_STOCK_PROJECTION=')).split('LF11_STORE_STOCK_PROJECTION=').last) as Map<String, dynamic>;
    final terminal = jsonDecode(lines.singleWhere((l) => l.startsWith('LF11_STOCK_EXPIRY_PROJECTION=')).split('LF11_STOCK_EXPIRY_PROJECTION=').last) as Map<String, dynamic>;
    WorkspaceStoreStockIntent originalFor(Map<String, dynamic> body) => WorkspaceStoreStockIntent(scope: stockScope,
      expectedRevision: body['expectedRevision'] as int, idempotencyKey: body['idempotencyKey'] as String,
      input: WorkspaceStoreStockInput.fromJson({'binding': body['binding'], 'source': body['source']}));
    final record = WorkspaceStoreStockRecord.decode(report['owner']['record'], stockScope, at);
    expect(record.source['quantityPacks'], 7);
    final query = WorkspacePublicStockQuery(realm: 'evaluation', storeId: 'store-one', binding: record.binding, requestedPacks: 1);
    expect(WorkspacePublicStockResult.decode(report['publicOne'], query, at).quantityAvailable, true);
    final original = originalFor(terminal['original'] as Map<String, dynamic>), api = stockGateway(Transport(terminal['expired'] as Map<String, dynamic>));
    expect((await api.writeStoreStock(original, current: () => true, reconcile: true)).state, WorkspaceStoreStockWriteState.expired);
    expect(original.serverFingerprint, terminal['expired']['originalFingerprint']);
  });
  testWidgets('H22-OWNER unknown storage owner hides Store until its first read settles', (tester) async {
    final account = _HeldWorkspaceAccount(), held = Completer<Map<String, Object?>?>();
    account.holds['owner-one'] = held;
    final work = WorkSession(contactDraftStore: account)
      ..activeWorkspace = const WorkWorkspace(id: 'store-one', name: 'Private initial Store', profileId: 'retailer-grocery', profileLabel: 'Grocery', area: 'Jaipur', verified: true)
      ..workspaceId = 'store-one' ..retailerSetupSaved = true ..reviewStage = WorkReviewStage.live;
    work.workspaceCatalogueItems.add(listingItem());
    final core = BuySession(), buyer = BuyV2Session(core: core, reviewDataEnabled: false);
    addTearDown(() {if (!held.isCompleted) held.complete(null);});
    addTearDown(work.dispose); addTearDown(core.dispose); addTearDown(buyer.dispose);
    await tester.pumpWidget(MaterialApp(theme: MoolTheme.light(), home: WorkWorkspaceDashboardScreen(
      session: work, procurementSession: buyer, accountAuthenticated: true, initialSection: 'stock')));
    await tester.pump();
    expect(find.textContaining('Private initial Store'), findsNothing);
    expect(find.byKey(const Key('work-account-recovery')), findsOneWidget);
    expect(find.byKey(const Key('work-local-navigation')), findsNothing);
    expect(find.byKey(const Key('work-global-chat')), findsNothing);
    expect(account.reads, ['owner-one']);
    held.complete(null); await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-catalogue-edit-sku-one')), findsOneWidget, reason: 'Retain the initial Stock operation after same-owner binding.');
    expect(work.hasVerifiedWorkspace, isTrue, reason: 'The trusted same-owner Store is not approval from the draft.');
    expect(tester.takeException(), isNull);
  });
  for (final proofOnly in [false, true]) {
    testWidgets('H22-OWNER explicit review or proof-only initialization cannot strand a pending surface proof=$proofOnly', (tester) async {
      final proof = _HeldWorkspaceAccount();
      final work = WorkSession(pendingProofStore: proofOnly ? proof : null)
        ..activeWorkspace = const WorkWorkspace(id: 'store-one', name: 'Trusted review Store', profileId: 'retailer-grocery', profileLabel: 'Grocery', area: 'Jaipur', verified: true)
        ..workspaceId = 'store-one' ..retailerSetupSaved = true ..reviewStage = WorkReviewStage.live;
      work.workspaceCatalogueItems.add(listingItem());
      final core = BuySession(), buyer = BuyV2Session(core: core, reviewDataEnabled: false);
      addTearDown(work.dispose); addTearDown(core.dispose); addTearDown(buyer.dispose);
      await tester.pumpWidget(MaterialApp(theme: MoolTheme.light(), home: WorkWorkspaceDashboardScreen(
        session: work, procurementSession: buyer, initialSection: 'stock', accountAuthenticated: proofOnly)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-account-recovery')), findsNothing);
      expect(find.byKey(const Key('work-catalogue-edit-sku-one')), findsOneWidget);
      expect(proof.reads, isEmpty, reason: 'Only the root may restore/consume the pending document.');
      expect(proof.clears, isEmpty); expect(tester.takeException(), isNull);
    });
  }
  for (final initiallyStale in [false, true]) {
  testWidgets('H22-OWNER account change hides old Store during held recovery and A B A initial=$initiallyStale', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    final account = _HeldWorkspaceAccount(), inventory = SecureWorkInventoryStore(accountScope: () => account.owner);
    final work = WorkSession(contactDraftStore: account, inventoryStore: inventory);
    await work.recoverPendingProof(accountReady: true);
    work.activeWorkspace = const WorkWorkspace(id: 'store-one', name: 'Private owner A Store', profileId: 'retailer-grocery', profileLabel: 'Grocery', area: 'Jaipur', verified: true);
    work.workspaceId = 'store-one'; work.retailerSetupSaved = true; work.reviewStage = WorkReviewStage.live;
    work.workspaceCatalogueItems.add(listingItem());
    expect(await work.loadWorkspaceInventory(), isTrue); expect(await work.retryWorkspaceInventorySave(), isTrue);
    // Independent host verification remains bound to A; it is not the B UI/storage adapter.
    final ownerAVerifier = SecureWorkInventoryStore(accountScope: () => 'owner-one');
    final original = (await ownerAVerifier.read('owner-one', 'store-one', qa: true))!.toJson();
    final core = BuySession(), buyer = BuyV2Session(core: core, reviewDataEnabled: false);
    addTearDown(work.dispose); addTearDown(core.dispose); addTearDown(buyer.dispose);
    final heldB = Completer<Map<String, Object?>?>(), heldA = Completer<Map<String, Object?>?>();
    addTearDown(() {if (!heldB.isCompleted) heldB.complete(null); if (!heldA.isCompleted) heldA.complete(null);});
    if (initiallyStale) {account.holds['owner-two'] = heldB; account.owner = 'owner-two';}
    await tester.pumpWidget(MaterialApp(theme: MoolTheme.light(), home: WorkWorkspaceDashboardScreen(
      session: work, procurementSession: buyer, accountAuthenticated: true)));
    if (!initiallyStale) {
      await tester.pumpAndSettle(); expect(find.textContaining('Private owner A Store'), findsWidgets);
      account.holds['owner-two'] = heldB; account.owner = 'owner-two'; work.dismissMessages();
    }
    await tester.pump();
    expect(work.activeWorkspace, isNull);
    expect(find.textContaining('Private owner A Store'), findsNothing);
    expect(find.byKey(const Key('work-account-recovery')), findsOneWidget);
    expect(find.text('No approved Workspace yet'), findsNothing, reason: 'A held read has not established absence.');
    expect(account.reads.where((scope) => scope == 'owner-two'), hasLength(1));
    account.holds['owner-one'] = heldA; account.owner = 'owner-one';
    work.dismissMessages(); await tester.pump();
    heldB.complete({'version': 1, 'savedAt': DateTime.now().toUtc().toIso8601String(), 'name': 'Obsolete B details'});
    await tester.pump(); await tester.pump(const Duration(milliseconds: 20));
    expect(work.activeWorkspace, isNull); expect(work.workName, isNot('Obsolete B details'));
    expect(find.byKey(const Key('work-account-recovery')), findsOneWidget, reason: 'An old completion cannot release A recovery.');
    heldA.complete({'version': 1, 'savedAt': DateTime.now().toUtc().toIso8601String(), 'name': 'Current A details',
      'approved': true, 'workspaceId': 'store-one'});
    await tester.pumpAndSettle();
    expect(work.workName, 'Current A details'); expect(work.activeWorkspace, isNull, reason: 'Local draft approval fields are not Store authority.');
    expect(find.text('No approved Workspace yet'), findsOneWidget);
    expect((await ownerAVerifier.read('owner-one', 'store-one', qa: true))!.toJson(), original);
    expect(account.clears, isEmpty); expect(tester.takeException(), isNull);
  });
  }
  testWidgets('H22-OWNER failed recovery stays unavailable and stale retry cannot replace current edits', (tester) async {
    final account = _HeldWorkspaceAccount(), work = WorkSession(contactDraftStore: account);
    await work.recoverPendingProof(accountReady: true);
    work.activeWorkspace = const WorkWorkspace(id: 'store-one', name: 'Private owner A Store', profileId: 'retailer-grocery', profileLabel: 'Grocery', area: 'Jaipur', verified: true);
    work.workspaceId = 'store-one'; work.retailerSetupSaved = true; work.reviewStage = WorkReviewStage.live;
    final core = BuySession(), buyer = BuyV2Session(core: core, reviewDataEnabled: false);
    addTearDown(work.dispose); addTearDown(core.dispose); addTearDown(buyer.dispose);
    await tester.pumpWidget(MaterialApp(theme: MoolTheme.light(), home: WorkWorkspaceDashboardScreen(
      session: work, procurementSession: buyer, accountAuthenticated: true)));
    await tester.pumpAndSettle();
    account.owner = 'owner-two'; account.failing.add('owner-two'); work.dismissMessages();
    await tester.pumpAndSettle();
    expect(work.activeWorkspace, isNull); expect(find.textContaining('Private owner A Store'), findsNothing);
    expect(find.byKey(const Key('work-account-recovery-error')), findsOneWidget); expect(find.text('No approved Workspace yet'), findsNothing);
    final retry = find.byKey(const Key('work-account-recovery-error-action'));
    final obsoleteRetry = tester.widget<OutlinedButton>(retry).onPressed!;
    final held = Completer<Map<String, Object?>?>(); addTearDown(() {if (!held.isCompleted) held.complete(null);});
    account.failing.clear(); account.holds['owner-two'] = held;
    await tester.tap(retry); await tester.pump(); expect(find.byKey(const Key('work-account-recovery')), findsOneWidget);
    obsoleteRetry(); await tester.pump(); expect(account.reads.where((scope) => scope == 'owner-two'), hasLength(2));
    work.saveBusinessRelationship('Current B input');
    held.complete({'version': 1, 'savedAt': DateTime.now().toUtc().toIso8601String(), 'name': 'Older B read'});
    await tester.pumpAndSettle();
    expect(work.workspaceAccountRecoveryPending, isFalse); expect(work.businessRelationship, 'Current B input');
    expect(work.workName, isNot('Older B read')); expect(work.activeWorkspace, isNull);
    expect(find.text('No approved Workspace yet'), findsOneWidget); expect(tester.takeException(), isNull);
  });
  Map<String, Object?> pendingOwnerProof() => {'version': 1, 'savedAt': DateTime.now().toUtc().toIso8601String(),
    'profileId': 'retailer-grocery', 'source': 'camera', 'proofId': 'host-unselected-proof', 'name': 'Original A pending details'};
  test('H22-OWNER old root held contact read cannot claim a newer A B A proof generation', () async {
    final contact = _HeldWorkspaceAccount(), proof = _HeldWorkspaceAccount();
    final work = WorkSession(contactDraftStore: contact, pendingProofStore: proof);
    final first = Completer<Map<String, Object?>?>(), current = Completer<Map<String, Object?>?>();
    final enteredFirst = Completer<void>(), enteredCurrent = Completer<void>();
    addTearDown(() {if (!first.isCompleted) first.complete(null); if (!current.isCompleted) current.complete(null);});
    addTearDown(work.dispose);
    contact.holds['owner-one'] = first; contact.entered['owner-one'] = enteredFirst;
    final oldRoot = work.recoverPendingProof(accountReady: true); await enteredFirst.future;
    contact.owner = proof.owner = 'owner-two'; await work.recoverWorkspaceAccount(accountReady: true);
    contact.holds['owner-one'] = current; contact.entered['owner-one'] = enteredCurrent;
    contact.owner = proof.owner = 'owner-one'; proof.restored['owner-one'] = pendingOwnerProof();
    final currentRoot = work.recoverPendingProof(accountReady: true); await enteredCurrent.future;
    first.complete(null);
    expect(await oldRoot, isFalse);
    expect(proof.reads, isEmpty); expect(proof.clears, isEmpty); expect(work.selectedProfile, isNull);
    current.complete(null); expect(await currentRoot, isTrue);
    expect(proof.reads, ['owner-one']); expect(proof.clears, ['owner-one']);
    expect(await work.recoverPendingProof(accountReady: true), isFalse);
  });
  test('H22-OWNER proof-only storage ownership detaches old Store without consuming the pending route', () async {
    final proof = _HeldWorkspaceAccount(), work = WorkSession(pendingProofStore: proof);
    addTearDown(work.dispose);
    await work.recoverPendingProof(accountReady: true);
    work.activeWorkspace = const WorkWorkspace(id: 'store-one', name: 'Private A', profileId: 'retailer-grocery', profileLabel: 'Grocery', area: 'Jaipur', verified: true);
    final before = proof.reads.length; proof.owner = 'owner-two'; proof.restored['owner-two'] = pendingOwnerProof();
    expect(await work.recoverWorkspaceAccount(accountReady: true), isTrue);
    expect(work.activeWorkspace, isNull); expect(proof.reads, hasLength(before)); expect(proof.clears, isEmpty);
    expect(await work.recoverPendingProof(accountReady: true), isTrue);
    expect(work.hasVerifiedWorkspace, isFalse); expect(work.selectedProfile!.id, 'retailer-grocery'); expect(proof.clears, ['owner-two']);
    expect(await work.recoverPendingProof(accountReady: true), isFalse); expect(proof.clears, ['owner-two']);
  });
  test('H22-OWNER old proof completion after A B A cannot restore or consume original checkpoint', () async {
    final contact = _HeldWorkspaceAccount(), proof = _HeldWorkspaceAccount(), work = WorkSession(contactDraftStore: contact, pendingProofStore: proof);
    addTearDown(work.dispose);
    final held = Completer<Map<String, Object?>?>(), entered = Completer<void>();
    addTearDown(() {if (!held.isCompleted) held.complete(null);});
    proof.holds['owner-one'] = held; proof.entered['owner-one'] = entered;
    final original = work.recoverPendingProof(accountReady: true); await entered.future;
    contact.owner = proof.owner = 'owner-two'; await work.recoverWorkspaceAccount(accountReady: true);
    contact.owner = proof.owner = 'owner-one'; await work.recoverWorkspaceAccount(accountReady: true);
    expect(proof.reads, ['owner-one']); expect(proof.clears, isEmpty);
    held.complete(pendingOwnerProof()); expect(await original, isFalse);
    expect(work.selectedProfile, isNull); expect(work.workName, isEmpty); expect(work.recoveredDocumentStep, isFalse); expect(proof.clears, isEmpty);
    expect(await work.recoverPendingProof(accountReady: true), isTrue);
    expect(work.workName, 'Original A pending details'); expect(work.hasVerifiedWorkspace, isFalse); expect(proof.clears, ['owner-one']);
    expect(await work.recoverPendingProof(accountReady: true), isFalse); expect(proof.reads, ['owner-one', 'owner-one']);
  });
  test('LF03-UPLOAD matching private media capability is explicit and disabled by default', () {
    final source = AuthenticatedWorkspaceCatalogueGateway(endpoint: Uri.parse('https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
      credentials: Credentials(), transport: Transport({}));
    expect((source as dynamic).productMediaSupported, false);
  });
  Future<Uint8List> mediaBytes() async {
    final recorder = ui.PictureRecorder(); ui.Canvas(recorder).drawColor(const ui.Color(0xff287348), ui.BlendMode.src);
    final picture = recorder.endRecording(), image = await picture.toImage(512, 512);
    try {return (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();}
    finally {image.dispose(); picture.dispose();}
  }
  test('LF03-UPLOAD frozen original, signed headers and processed receipt agree; account clone keeps capability', () async {
    final bytes = await mediaBytes(), original = _mediaOriginal(bytes), put = _MediaPut(), credentials = Credentials();
    var uploaded = false;
    put.afterWrite = () async {uploaded = true;};
    final api = _MediaApi((body) => _mediaReply(original, bytes, state: body['operation'] == 'prepareStoreProductMedia' ? 'awaiting_upload'
      : uploaded ? 'processed' : 'not_found', grant: body['operation'] == 'prepareStoreProductMedia'));
    final gateway = _mediaGateway(api, put, credentials: credentials).forOwnerAccount('owner-one');
    expect(gateway.productMediaSupported, isTrue);
    final result = await gateway.uploadProductMedia(original, readBytes: () async => bytes, current: () => true);
    expect(result.processed, isTrue); expect(result.current, isTrue); expect(put.bytes, bytes);
    expect(put.calls, 1); expect(result.uploadUrl, isNull); expect(result.toJson().toString(), isNot(contains('X-Goog-Signature')));
    expect(credentials.modes, [SocialAppCheckTokenMode.standard, SocialAppCheckTokenMode.limitedUse, SocialAppCheckTokenMode.limitedUse]);
    expect((await gateway.uploadProductMedia(original, readBytes: () async => throw StateError('Do not reread processed photo'), current: () => true)).processed, isTrue);
    expect(put.calls, 1); expect(api.bodies.every((body) => body['idempotencyKey'] == original.idempotencyKey), isTrue);
    expect(() => WorkspaceProductMediaIntent.fromJson({...original.toJson(), 'sourceByteLength': 8 * 1024 * 1024 + 1}), throwsFormatException);
  });
  for (final fault in ['lost PUT', 'precondition conflict', 'lost prepare', 'lost confirm']) {
    test('LF03-UPLOAD $fault recovers the same object/key without replacement', () async {
      final bytes = await mediaBytes(), original = _mediaOriginal(bytes), put = _MediaPut();
      var prepared = fault == 'precondition conflict', uploaded = false, processed = false, failed = false;
      put.status = fault == 'precondition conflict' ? 412 : 200;
      put.afterWrite = () async {uploaded = true; if (fault == 'lost PUT' && !failed) {failed = true; throw TimeoutException('Host lost upload reply');}};
      final api = _MediaApi((body) {
        final op = body['operation'];
        if (op == 'prepareStoreProductMedia') {
          prepared = true;
          if (fault == 'lost prepare' && !failed) {failed = true; throw TimeoutException('Host lost grant reply');}
          return _mediaReply(original, bytes, state: 'awaiting_upload', grant: true);
        }
        if (op == 'confirmStoreProductMedia' && uploaded) {
          processed = true;
          if (fault == 'lost confirm' && !failed) {failed = true; throw TimeoutException('Host lost confirmation reply');}
        } else if (op == 'confirmStoreProductMedia' && prepared) {throw StateError('Host original not uploaded yet');}
        return _mediaReply(original, bytes, state: processed ? 'processed' : prepared ? 'awaiting_upload' : 'not_found');
      });
      final gateway = _mediaGateway(api, put);
      if (fault == 'lost prepare' || fault == 'lost confirm') {
        await expectLater(gateway.uploadProductMedia(original, readBytes: () async => bytes, current: () => true), throwsA(anything));
      }
      final done = await gateway.uploadProductMedia(original, readBytes: () async => bytes, current: () => true);
      expect(done.processed, isTrue); expect(put.calls, 1);
      expect(put.urls.single.path, endsWith('/${original.uploadId}/original'));
      expect(api.bodies.every((body) => body['idempotencyKey'] == original.idempotencyKey), isTrue);
    });
  }
  test('LF03-UPLOAD expired successful upload confirms without another PUT or byte read', () async {
    final bytes = await mediaBytes(), original = _mediaOriginal(bytes), put = _MediaPut();
    final api = _MediaApi((body) => _mediaReply(original, bytes, state: body['operation'] == 'confirmStoreProductMedia' ? 'processed' : 'awaiting_upload'));
    final result = await _mediaGateway(api, put, now: () => at.add(const Duration(minutes: 6)))
      .uploadProductMedia(original, readBytes: () async => throw StateError('No resend after expired grant'), current: () => true);
    expect(result.processed, isTrue); expect(put.calls, 0); expect(api.bodies, hasLength(2));
  });
  for (final fault in ['host', 'object', 'header', 'signature', 'expiry', 'scope', 'schema', 'current', 'mime']) {
    test('LF03-UPLOAD malformed $fault grant cannot dispatch photo bytes', () async {
      final bytes = await mediaBytes(), original = _mediaOriginal(bytes), put = _MediaPut();
      final api = _MediaApi((body) {
        if (body['operation'] != 'prepareStoreProductMedia') return _mediaReply(original, bytes);
        final response = _mediaReply(original, bytes, state: 'awaiting_upload', grant: true);
        final url = Uri.parse(response['uploadUrl'] as String);
        switch (fault) {
          case 'host': response['uploadUrl'] = url.replace(host: 'storage.googleapis.com.evil.invalid').toString();
          case 'object': response['uploadUrl'] = url.replace(path: url.path.replaceFirst(original.uploadId, 'other-upload')).toString();
          case 'header': (response['requiredHeaders'] as Map)['authorization'] = 'Bearer forbidden';
          case 'signature': response['uploadUrl'] = url.replace(queryParameters: {...url.queryParameters, 'X-Goog-SignedHeaders': 'host'}).toString();
          case 'expiry': response['uploadUrl'] = url.replace(queryParameters: {...url.queryParameters, 'X-Goog-Expires': '600'}).toString();
          case 'scope': response['storeId'] = 'other-store';
          case 'schema': response['schemaVersion'] = 1.0;
          case 'current': response['current'] = false;
          case 'mime': (response['requiredHeaders'] as Map)['content-type'] = 'image/jpeg';
        }
        return response;
      });
      await expectLater(_mediaGateway(api, put).uploadProductMedia(original, readBytes: () async => bytes, current: () => true), throwsA(anything));
      expect(put.calls, 0);
    });
  }
  test('LF03-UPLOAD changed saved bytes and retired credential generation cannot prepare or upload', () async {
    final bytes = await mediaBytes(), original = _mediaOriginal(bytes), put = _MediaPut();
    final api = _MediaApi((_) => _mediaReply(original, bytes));
    await expectLater(_mediaGateway(api, put).uploadProductMedia(original, readBytes: () async => Uint8List(bytes.length), current: () => true), throwsFormatException);
    expect(api.bodies.map((b) => b['operation']), ['readStoreProductMedia']); expect(put.calls, 0);
    var active = true;
    final gateway = _mediaGateway(api, put, credentials: RetiringOwnerCredentials(() {active = false;}));
    await expectLater(gateway.uploadProductMedia(original, readBytes: () async => bytes, current: () => active), throwsA(anything));
    expect(api.bodies, hasLength(1)); expect(put.calls, 0);
  });
  test('LF03-UPLOAD secure original and completion survive restart, exclude URLs and preserve uncertain records', () async {
    TestWidgetsFlutterBinding.ensureInitialized(); FlutterSecureStorage.setMockInitialValues({});
    final bytes = await mediaBytes(), original = _mediaOriginal(bytes);
    String? account = original.scope.account;
    SecureWorkProductMediaJournal journal() => SecureWorkProductMediaJournal(currentAccount: () => account, now: () => at);
    await journal().saveOriginal(original);
    await expectLater(journal().saveOriginal(_mediaOriginal(bytes, key: 'new-uncertain')), throwsFormatException);
    expect((await journal().read(original.scope))!.original.fingerprint, original.fingerprint);
    final result = WorkspaceProductMediaResult.decode(_mediaReply(original, bytes, state: 'processed'), original, at);
    await journal().saveResult(original, result);
    final fresh = await journal().read(original.scope);
    expect(fresh!.result!.processed, isTrue); expect(fresh.original.fingerprint, original.fingerprint);
    expect((await const FlutterSecureStorage().readAll()).values.join(), isNot(contains('uploadUrl')));
    await expectLater(journal().saveResult(original, WorkspaceProductMediaResult.decode(_mediaReply(original, bytes, state: 'awaiting_upload'), original, at)), throwsFormatException);
    account = 'other-owner'; await expectLater(journal().read(original.scope), throwsA(isA<WorkGatewayException>()));
    account = original.scope.account;
    await journal().saveOriginal(_mediaOriginal(bytes, key: 'replacement-after-confirmed', revision: 2));
    expect((await journal().read(original.scope))!.original.submissionRevision, 2);
  });
  test('LF03-UPLOAD clock rollback retains historical originals without granting freshness or signed URLs', () async {
    TestWidgetsFlutterBinding.ensureInitialized(); FlutterSecureStorage.setMockInitialValues({});
    final bytes = await mediaBytes(), original = _mediaOriginal(bytes);
    final store = SecureWorkProductMediaJournal(currentAccount: () => original.scope.account, now: () => at);
    await store.saveOriginal(original);
    final complete = WorkspaceProductMediaResult.decode(_mediaReply(original, bytes, state: 'processed'), original, at);
    await store.saveResult(original, complete);
    final rolled = SecureWorkProductMediaJournal(currentAccount: () => original.scope.account, now: () => at.subtract(const Duration(days: 2)));
    expect((await rolled.read(original.scope))!.result!.processed, isTrue);
    expect(() => WorkspaceProductMediaResult.decode(complete.toJson(), original, at.subtract(const Duration(days: 2))), throwsFormatException);
    final controller = WorkspaceProductMediaController(scope: original.scope, gateway: _mediaGateway(_MediaApi((_) => complete.toJson()), _MediaPut()),
      journal: rolled, context: Object.new); // A changing lifetime cannot become a current upload.
    addTearDown(controller.dispose); expect(await controller.restore(), isFalse);
    final lifetime = Object(), restored = WorkspaceProductMediaController(scope: original.scope,
      gateway: _mediaGateway(_MediaApi((_) => complete.toJson()), _MediaPut()), journal: rolled, context: () => lifetime);
    addTearDown(restored.dispose); expect(await restored.restore(), isTrue); expect(restored.fresh, isFalse);
  });
  test('LF03-UPLOAD unresolved noncurrent original remains reachable when a replacement is saved', () async {
    TestWidgetsFlutterBinding.ensureInitialized(); FlutterSecureStorage.setMockInitialValues({});
    final bytes = await mediaBytes(), original = _mediaOriginal(bytes), next = _mediaOriginal(bytes, key: 'new-source', revision: 2);
    SecureWorkProductMediaJournal journal() => SecureWorkProductMediaJournal(currentAccount: () => original.scope.account, now: () => at);
    await journal().saveOriginal(original);
    await journal().saveResult(original, WorkspaceProductMediaResult.decode(_mediaReply(original, bytes, state: 'awaiting_upload', current: false), original, at));
    await journal().saveOriginal(next);
    final restart = await journal().read(original.scope);
    expect(restart!.original.fingerprint, next.fingerprint); expect(restart.history.single.original.fingerprint, original.fingerprint);
    final put = _MediaPut(), api = _MediaApi((body) => _mediaReply(original, bytes, state: 'processed', current: false)), lifetime = Object();
    final controller = WorkspaceProductMediaController(scope: next.scope, gateway: _mediaGateway(api, put), journal: journal(), context: () => lifetime);
    addTearDown(controller.dispose); expect(await controller.restore(), isTrue);
    expect(await controller.checkEarlier(current: () => true), isTrue);
    expect(controller.original!.fingerprint, next.fingerprint); expect(controller.result, isNull);
    final recovered = await journal().read(next.scope);
    expect(recovered!.history.single.result!.processed, isTrue); expect(recovered.history.single.result!.current, isFalse); expect(put.calls, 0);
  });
  test('LF03-UPLOAD earlier selection reaches a later recoverable original without dropping the first unresolved one', () async {
    TestWidgetsFlutterBinding.ensureInitialized(); FlutterSecureStorage.setMockInitialValues({});
    final bytes = await mediaBytes(), one = _mediaOriginal(bytes, key: 'earlier-one'), two = _mediaOriginal(bytes, key: 'earlier-two', revision: 2),
      latest = _mediaOriginal(bytes, key: 'latest-photo', revision: 3);
    final journal = SecureWorkProductMediaJournal(currentAccount: () => one.scope.account, now: () => at);
    for (final original in [one, two]) {
      await journal.saveOriginal(original);
      await journal.saveResult(original, WorkspaceProductMediaResult.decode(_mediaReply(original, bytes, state: 'awaiting_upload', current: false), original, at));
    }
    await journal.saveOriginal(latest);
    final api = _MediaApi((body) {expect(body['idempotencyKey'], two.idempotencyKey); return _mediaReply(two, bytes, state: 'processed', current: false);}), lifetime = Object();
    final controller = WorkspaceProductMediaController(scope: latest.scope, gateway: _mediaGateway(api, _MediaPut()), journal: journal, context: () => lifetime);
    addTearDown(controller.dispose);
    expect(await controller.checkEarlier(current: () => true, requestKey: two.idempotencyKey), isTrue);
    final saved = (await journal.read(one.scope))!;
    expect(saved.original.fingerprint, latest.fingerprint); expect(saved.history[0].result!.processed, isFalse); expect(saved.history[1].result!.processed, isTrue);
  });
  test('LF03-UPLOAD rejected history-cap replacement restores the durable original before another action', () async {
    TestWidgetsFlutterBinding.ensureInitialized(); FlutterSecureStorage.setMockInitialValues({});
    final bytes = await mediaBytes(), old = _mediaOriginal(bytes, key: 'retained-8', revision: 9), candidate = _mediaOriginal(bytes, key: 'cannot-save-new', revision: 10);
    final journal = SecureWorkProductMediaJournal(currentAccount: () => old.scope.account, now: () => at);
    for (var index = 0; index <= 8; index++) {
      final original = _mediaOriginal(bytes, key: 'retained-$index', revision: index + 1);
      await journal.saveOriginal(original);
      await journal.saveResult(original, WorkspaceProductMediaResult.decode(_mediaReply(original, bytes, state: 'awaiting_upload', current: false), original, at));
    }
    var recover = false; final put = _MediaPut(), lifetime = Object();
    final api = _MediaApi((body) {expect(body['idempotencyKey'], old.idempotencyKey); return _mediaReply(old, bytes, state: recover ? 'processed' : 'awaiting_upload', current: false);});
    final controller = WorkspaceProductMediaController(scope: old.scope, gateway: _mediaGateway(api, put), journal: journal, context: () => lifetime);
    addTearDown(controller.dispose);
    expect(await controller.upload(candidate, current: () => true, readBytes: (_) async => bytes), isFalse); expect(controller.ready, isFalse);
    expect((await journal.read(old.scope))!.original.fingerprint, old.fingerprint); expect(put.calls, 0);
    recover = true; expect(await controller.check(current: () => true), isTrue);
    expect(controller.original!.fingerprint, old.fingerprint); expect((await journal.read(old.scope))!.history, hasLength(8));
  });
  test('LF03-UPLOAD source change during failed journal replacement cannot leave recovery pointing at the unsaved candidate', () async {
    final bytes = await mediaBytes(), old = _mediaOriginal(bytes), candidate = _mediaOriginal(bytes, key: 'unsaved-replacement', revision: 2);
    final journal = _MediaJournal()..saved = WorkspaceProductMediaRecovery(old,
      WorkspaceProductMediaResult.decode(_mediaReply(old, bytes, state: 'awaiting_upload', current: false), old, at));
    final entered = Completer<void>(), release = Completer<void>();
    journal.beforeOriginal = () async {entered.complete(); await release.future;};
    journal.failOriginal = true;
    var unchanged = true, recovering = false;
    final lifetime = Object(), api = _MediaApi((body) {
      expect(body['idempotencyKey'], old.idempotencyKey);
      return _mediaReply(old, bytes, state: recovering ? 'processed' : 'awaiting_upload', current: false);
    });
    final controller = WorkspaceProductMediaController(scope: old.scope, gateway: _mediaGateway(api, _MediaPut()), journal: journal, context: () => lifetime);
    addTearDown(controller.dispose);
    final running = controller.upload(candidate, current: () => unchanged, readBytes: (_) async => bytes);
    await entered.future; expect(controller.ready, isFalse); unchanged = false; release.complete();
    expect(await running, isFalse); expect(controller.ready, isFalse); expect(journal.saved!.original.fingerprint, old.fingerprint);
    recovering = true;
    expect(await controller.check(current: () => true), isTrue); expect(controller.original!.fingerprint, old.fingerprint);
  });
  test('LF03-UPLOAD grant await and A-B-A lifetime changes fence PUT while keeping original recovery', () async {
    final bytes = await mediaBytes(), original = _mediaOriginal(bytes), put = _MediaPut(), pending = Completer<Map<String, dynamic>>();
    final granted = Completer<void>();
    final api = _MediaApi((body) {
      if (body['operation'] == 'prepareStoreProductMedia') {granted.complete(); return pending.future;}
      return _mediaReply(original, bytes);
    });
    final journal = _MediaJournal(); Object lifetime = Object(), captured = lifetime;
    var sourceUnchanged = true;
    final controller = WorkspaceProductMediaController(scope: original.scope, gateway: _mediaGateway(api, put), journal: journal, context: () => lifetime);
    addTearDown(controller.dispose);
    final running = controller.upload(original, current: () => sourceUnchanged, readBytes: (_) async => bytes);
    await granted.future; sourceUnchanged = false; lifetime = Object(); lifetime = Object();
    expect(lifetime, isNot(same(captured)));
    pending.complete(_mediaReply(original, bytes, state: 'awaiting_upload', grant: true));
    expect(await running, isFalse); expect(put.calls, 0); expect(journal.saved!.original.fingerprint, original.fingerprint);
    final again = WorkspaceProductMediaController(scope: original.scope, gateway: _mediaGateway(_MediaApi((_) => _mediaReply(original, bytes, state: 'processed', current: false)), put),
      journal: journal, context: () => lifetime); addTearDown(again.dispose);
    expect(await again.check(current: () => true), isTrue); expect(again.result!.current, isFalse); expect(put.calls, 0);
  });
  for (final failAt in ['original', 'result']) {
    test('LF03-UPLOAD failed $failAt journal preserves recovery and never claims durable success', () async {
      final bytes = await mediaBytes(), original = _mediaOriginal(bytes), put = _MediaPut(), journal = _MediaJournal();
      journal.failOriginal = failAt == 'original'; journal.failResult = failAt == 'result';
      var uploaded = false; put.afterWrite = () async {uploaded = true;};
      final api = _MediaApi((body) {
        final raw = Map<String, Object?>.of(body)..remove('operation')..remove('productMediaVersion');
        final request = WorkspaceProductMediaIntent.fromJson({'schemaVersion': 1, 'accountId': 'owner-one', 'realm': 'evaluation', ...raw});
        return _mediaReply(request, bytes, state: body['operation'] == 'prepareStoreProductMedia' ? 'awaiting_upload'
          : uploaded ? 'processed' : 'not_found', grant: body['operation'] == 'prepareStoreProductMedia');
      });
      final context = Object(), gateway = _mediaGateway(api, put), controller = WorkspaceProductMediaController(scope: original.scope,
        gateway: gateway, journal: journal, context: () => context); addTearDown(controller.dispose);
      expect(await controller.upload(original, current: () => true, readBytes: (_) async => bytes), isFalse);
      expect(controller.original!.fingerprint, original.fingerprint); expect(controller.result, isNull);
      expect(put.calls, failAt == 'original' ? 0 : 1);
      if (failAt == 'original') {expect(api.bodies, isEmpty);} else {expect(journal.saved!.original.fingerprint, original.fingerprint);}
      journal.failOriginal = false; journal.failResult = false;
      expect(await controller.upload(_mediaOriginal(bytes, key: 'new-tap-key'), current: () => true, readBytes: (_) async => bytes), isTrue);
      expect(controller.original!.idempotencyKey, failAt == 'original' ? 'new-tap-key' : original.idempotencyKey); expect(put.calls, 1);
    });
  }
  if (Platform.environment['LF03_FAMILY_SERVER'] == 'true') {
    test('LF03-CONNECTED Store saved variants to real reviewed service restart and public selection', () async {
      final emulator = Platform.environment['FIRESTORE_EMULATOR_HOST'] ?? '';
      expect(emulator, matches(r'^127\.0\.0\.1:\d+$'));
      FlutterSecureStorage.setMockInitialValues({}); SharedPreferences.setMockInitialValues({});
      final child = await Process.start('node', ['--test', '--test-isolation=none',
        '--test-name-pattern=LF03-CONNECTED live family bridge', 'lib/workspace/workspace_catalogue_service.test.js'],
        workingDirectory: Directory('../../backend/functions').absolute.path);
      final ready = Completer<Map<String, dynamic>>(), diagnostics = <String>[];
      void consume(String line) {
        const marker = 'LF03_FAMILY_READY=';
        if (line.contains(marker)) {
          if (!ready.isCompleted) ready.complete(jsonDecode(line.split(marker).last) as Map<String, dynamic>);
        } else {
          diagnostics.add(line); if (diagnostics.length > 100) diagnostics.removeAt(0);
        }
      }
      final stdout = child.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(consume);
      final stderr = child.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen(consume);
      // Only this opt-in loopback client uses real IO; keep the widget binding's
      // network prohibition unchanged for every ordinary test and production path.
      final client = HttpOverrides.runWithHttpOverrides(() => HttpClient(), _LoopbackFamilyHttpOverrides())
        ..connectionTimeout = const Duration(seconds: 5);
      addTearDown(() async {
        client.close(force: true); child.kill();
        await child.exitCode.timeout(const Duration(seconds: 10));
        await stdout.cancel(); await stderr.cancel();
      });
      final configuration = await ready.future.timeout(const Duration(seconds: 20),
        onTimeout: () => throw StateError('Host family bridge not ready: ${diagnostics.join('\n')}'));
      final port = configuration['port'] as int;
      expect(port, inInclusiveRange(1, 65535));
      Future<SocialContentResponse> post(String path, Map<String, Object?> body, Map<String, String> headers) async {
        final request = await client.postUrl(Uri.parse('http://127.0.0.1:$port/$path'));
        headers.forEach(request.headers.set); request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
        final response = await request.close().timeout(const Duration(seconds: 15));
        final text = await response.transform(utf8.decoder).join();
        if (response.statusCode != 200) {
          // Actual isolated service failure; do not rewrite it into a fixture.
          debugPrint('LF03_CONNECTED_ERROR=${jsonEncode({'operation': body['operation'], 'status': response.statusCode, 'response': text})}');
        }
        return SocialContentResponse(statusCode: response.statusCode, body: text);
      }
      Future<Map<String, dynamic>> control(Map<String, Object?> input) async {
        final response = await post('control', input, {'x-lf-control': configuration['controlToken'] as String});
        expect(response.statusCode, 200, reason: response.body);
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      final transport = _LoopbackFamilyTransport((body, headers) => post('gateway', body, headers));
      final connection = AuthenticatedWorkspaceCatalogueGateway(endpoint: Uri.parse(
        'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
        credentials: Credentials(), transport: transport, ownerAccountId: 'owner-one', realm: 'evaluation',
        productSubmissionSupported: true, reviewedProductSubmissionSupported: true,
        productFactsReadbackSupported: true, reviewedFamilyReadbackSupported: true, minorMoneyReadbackSupported: true,
        unbrandedProduceReadbackSupported: true, storeClassificationReadbackSupported: true, promotionDiscoverySupported: true, now: () => at);
      final account = ListingAccount();
      WorkSession fresh() => WorkSession(contactDraftStore: account, catalogueGateway: _ConnectedFamilyGateway(connection),
        productPromotionGateway: AuthenticatedStorePromotionGateway(endpoint: connection.endpoint, credentials: connection.credentials,
          transport: transport, ownerAccountId: 'owner-one', realm: 'evaluation', now: () => at), productPromotionRealm: 'evaluation',
        productPromotionPendingStoreFactory: (_) => SecureStorePromotionPendingStore(currentAccount: () => account.owner),
        inventoryStore: SecureWorkInventoryStore(accountScope: () => account.owner),
        productSubmissionJournalFactory: (_) => SecureWorkProductSubmissionJournal(currentAccount: () => account.owner),
        variantFamilyJournalFactory: (_) => SecureWorkVariantFamilyJournal(currentAccount: () => account.owner),
        catalogueBindingPendingStoreFactory: (_) => SecureWorkCatalogueBindingPendingStore(currentAccount: () => account.owner))
        ..activeWorkspace = const WorkWorkspace(id: 'store-one', name: 'Host Store', profileLabel: 'Grocery',
          profileId: 'retailer-grocery', area: 'Jaipur', verified: true) ..workspaceId = 'store-one';
      final work = fresh();
      var workDisposed = false;
      addTearDown(() { if (!workDisposed) work.dispose(); });
      expect(await work.loadWorkspaceInventory(), isTrue);
      const content = WorkspaceProductContent(description: 'Isolated host device description', specifications: {'Model': 'Host device'});
      final family = WorkspaceVariantFamily(id: 'family-one', revision: 1, title: 'Host device', brand: 'Host brand',
        categoryId: 'electronics', content: content, options: const [
          BuyV2VariantAttribute(dimensionId: 'colour', dimensionLabel: 'Colour', optionId: 'black', optionLabel: 'Black', kind: BuyV2VariantDimensionKind.colour),
          BuyV2VariantAttribute(dimensionId: 'colour', dimensionLabel: 'Colour', optionId: 'blue', optionLabel: 'Blue', kind: BuyV2VariantDimensionKind.colour),
          BuyV2VariantAttribute(dimensionId: 'storage', dimensionLabel: 'Storage', optionId: '128', optionLabel: '128 GB', kind: BuyV2VariantDimensionKind.storage),
          BuyV2VariantAttribute(dimensionId: 'storage', dimensionLabel: 'Storage', optionId: '512', optionLabel: '512 GB', kind: BuyV2VariantDimensionKind.storage),
        ]);
      for (final second in [false, true]) {
        final skuId = second ? 'sku-two' : 'sku-one', base = listingItem();
        final item = WorkspaceCatalogueItem.fromInventoryJson({...base.toInventoryJson(), 'id': skuId,
          'canonicalId': 'local-$skuId', 'sku': 'HOST-$skuId', 'pack': '1 phone',
          'stockEntry': {...base.stockEntry!.toJson(), 'productId': skuId, 'sku': 'HOST-$skuId', 'pack': '1 phone'}})
          .copyWith(title: family.title, brand: family.brand, categoryId: family.categoryId, content: content,
            variant: second ? 'Blue 512 GB' : 'Black 128 GB', sellingPriceMinor: second ? 1689950 : 1289925,
            mrpMinor: 2000000, packMeasure: const WorkspacePackMeasure(unit: BuyV2ComparisonUnit.count, quantityMilli: 1000),
            variantMembership: WorkspaceVariantMembership(familyId: family.id,
              selections: {'colour': second ? 'blue' : 'black', 'storage': second ? '512' : '128'}));
        expect(work.addOrUpdateWorkspaceProduct(item, variantFamily: family,
          stockEntryMethod: WorkspaceStockEntryMethod.manual), isTrue, reason: work.errorMessage);
      }
      expect(await work.workspaceInventorySaved, isTrue);
      final before = {for (final item in work.workspaceCatalogueItems) item.id: item.toInventoryJson()};
      final stockBefore = work.workspaceStockMovements.map((movement) => movement.contentIdentity).toList();
      for (final skuId in ['sku-one', 'sku-two']) {
        expect(await work.submitWorkspaceProduct(skuId, inputCurrent: () => true), isTrue,
          reason: work.workspaceProductSubmission(skuId)?.message ?? work.errorMessage);
        await control({'action': 'review-product', 'skuId': skuId});
        expect(await work.checkWorkspaceProductSubmission(skuId), isTrue, reason: work.workspaceProductSubmission(skuId)?.message);
        expect(work.canPublishReviewedWorkspaceProduct(skuId), isTrue);
        expect(await work.publishReviewedWorkspaceProduct(skuId, inputCurrent: () => true), isTrue, reason: work.errorMessage);
        expect(work.workspaceCatalogueItems.firstWhere((p) => p.id == skuId).toInventoryJson(), {...before[skuId]!, 'publicListing': true});
      }
      final saved = work.workspaceCatalogueItems.map((p) => p.toInventoryJson()).toList();
      expect(work.workspaceStockMovements.map((movement) => movement.contentIdentity).toList(), stockBefore);
      expect(work.workspaceInvoices, isEmpty); expect(work.workspaceOrders, isEmpty);
      work.dispose();
      workDisposed = true;
      final restored = fresh(); addTearDown(restored.dispose);
      expect(await restored.loadWorkspaceInventory(), isTrue);
      expect(restored.workspaceCatalogueItems.map((p) => p.toInventoryJson()).toList(), saved);
      expect(restored.workspaceStockMovements.map((movement) => movement.contentIdentity).toList(), stockBefore);
      for (final skuId in ['sku-one', 'sku-two']) {
        expect(restored.workspaceReviewedCatalogueLink(skuId)!.canonicalProductId, 'resolved-$skuId');
        expect(restored.workspaceCatalogueItems.firstWhere((p) => p.id == skuId).canonicalId, 'local-$skuId');
      }
      expect(await restored.checkWorkspaceVariantFamily(family.id), isTrue);
      expect(await restored.submitWorkspaceVariantFamily(family.id, inputCurrent: () => true), isTrue, reason: restored.errorMessage);
      await control({'action': 'review-family'});
      final entry = await connection.readPublicEntry(storeId: 'store-one', skuId: 'sku-one',
        channel: BuyV2OfferClass.retail, current: () => true);
      expect(entry, isNotNull); expect(entry!.product.variantFamilyId, family.id);
      final source = WorkspaceStoreCatalogueSource(storeId: 'store-one', current: () => true, gateway: connection);
      final query = BuyV2CatalogueQuery(destination: BuyV2Destination.shop, regionId: null, storeId: 'store-one',
        areaScope: BuyV2CatalogueAreaScope.allAreas);
      final firstPage = await source.loadProducts(query, pageSize: 1);
      expect(firstPage.items, hasLength(1));
      final peek = await connection.reviewedVariants!.readFamily(firstPage.items.single, query, current: () => true);
      expect(peek.isValidFor(firstPage.items.single, query, at), isTrue, reason: 'Actual family snapshot validity');
      Object comparable(BuyV2Product p) => [p.id, p.canonicalId, p.categoryId, p.title, p.brand, p.variant,
        p.variantFamilyId, p.sellerType, p.priceMinor, p.mrpMinor, p.minimumOrder, p.quantityStep, p.pack,
        p.publicListingIdentity?.toJson(), p.packTerms?.revision, p.packTerms?.sellUnit, p.packTerms?.containedUnits,
        p.packTerms?.netContentMilli, p.packTerms?.contentUnit, p.packTerms?.priceObservedAt?.toIso8601String(),
        p.packTerms?.priceValidUntil?.toIso8601String(),
        for (final a in p.variantAttributes) [a.dimensionId, a.dimensionLabel, a.optionId, a.optionLabel, a.kind.name, a.swatchArgb]];
      expect(comparable(peek.candidates.singleWhere((p) => p.id == firstPage.items.single.id)), comparable(firstPage.items.single),
        reason: 'Actual family selected candidate must match its paged source');
      final resolved = await source.loadVariantFamily(firstPage.items.single, query);
      expect(resolved.candidates.map((p) => p.sourceSkuId).toSet(), {'sku-one', 'sku-two'});
      expect(resolved.candidates, hasLength(2), reason: 'No generated Cartesian combinations');
      final core = BuySession();
      final buyer = BuyV2Session(core: core, cataloguePageSource: source,
        reviewDataEnabled: false, catalogueNow: () => at);
      addTearDown(core.dispose); addTearDown(buyer.dispose);
      final pager = buyer.acquireCatalogueProducts('connected-family'); await pager.open(query);
      expect(buyer.openProduct(entry.product.id), isTrue);
      expect(await buyer.refreshVariantFamily(buyer.selectedProduct!), isTrue);
      final sibling = resolved.candidates.singleWhere((p) => p.sourceSkuId == 'sku-two');
      expect(buyer.selectedProduct!.id, isNot(sibling.id), reason: 'Must select another real SKU, not the same opaque listing');
      expect(buyer.selectProductVariant(sibling.id), isTrue);
      expect(buyer.selectedProduct!.sourceSkuId, 'sku-two'); expect(buyer.selectedProduct!.canonicalId, 'resolved-sku-two');
      expect(buyer.selectedProduct!.publicListingIdentity!.verifiedPackId, 'resolved-pack-sku-two');
      expect(buyer.selectedProduct!.priceMinor, 1689950);
      buyer.releaseCatalogueProducts('connected-family');
      // Actual private owner save -> persistent service -> ordinary public Offers.
      final promotion = StorePromotionInput(skuId: 'sku-one', skuRevision: 1, channel: 'retail',
        headline: 'Host reviewed family promotion', detail: 'Descriptive text, not an applied discount', validFrom: at,
        validUntil: DateTime.now().toUtc().add(const Duration(days: 1)), active: true);
      for (final placement in ['promotion-one', 'promotion-two']) {
        expect(await restored.workspaceProductPromotions!.refresh(placement), isTrue,
          reason: restored.workspaceProductPromotions!.message);
        expect(await restored.readWorkspacePromotionSource('sku-one', channel: 'retail'), isNotNull,
          reason: 'Actual saved source must match before owner promotion submission');
        expect((await restored.submitWorkspaceProductPromotion(placement, promotion)).state, StorePromotionResultState.saved,
          reason: restored.workspaceProductPromotions!.message);
      }
      final global = WorkspacePublicDiscoverySource(gateway: connection, current: () => true);
      addTearDown(global.dispose);
      final offersQuery = BuyV2CatalogueQuery(destination: BuyV2Destination.shop, regionId: null,
        areaScope: BuyV2CatalogueAreaScope.allAreas, offersOnly: true);
      final offersPage = await global.loadOffers(offersQuery, pageSize: 1);
      expect(offersPage.totalCount, 2); expect(offersPage.offerCoverage!.key, 'retailer');
      final otherOffer = await global.loadOffers(offersQuery, pageSize: 1, cursor: offersPage.nextCursor);
      expect(otherOffer.items.single.publicationId, 'promotion-two');
      expect(otherOffer.items.single.product.id, offersPage.items.single.product.id);
      expect(otherOffer.items.single.product.variantFamilyId, 'family-one');
      final offerCore = BuySession();
      final offerBuyer = BuyV2Session(core: offerCore, reviewDataEnabled: false,
        catalogueNow: () => at, cataloguePageSource: global, publishedCatalogueSource: global);
      addTearDown(offerCore.dispose); addTearDown(offerBuyer.dispose);
      final offerPager = offerBuyer.acquireCatalogueOffers('connected-offers'); await offerPager.open(offersQuery);
      expect(offerPager.message, isNull); expect(offerPager.page!.items, hasLength(2));
      expect(offerBuyer.admitStorePromotion(global, offerPager.page!.items.last), isTrue);
      expect(offerBuyer.openProduct(offersPage.items.single.product.id), isTrue);
      expect(offerBuyer.selectedProduct!.sourceSkuId, 'sku-one'); expect(offerBuyer.cartLines, isEmpty);
      final paused = StorePromotionInput(skuId: promotion.skuId, skuRevision: promotion.skuRevision, channel: promotion.channel,
        headline: promotion.headline, detail: promotion.detail, validFrom: promotion.validFrom, validUntil: promotion.validUntil, active: false);
      expect(await restored.workspaceProductPromotions!.refresh('promotion-one'), isTrue);
      expect((await restored.submitWorkspaceProductPromotion('promotion-one', paused)).state, StorePromotionResultState.saved);
      expect((await global.loadOffers(offersQuery, pageSize: 1)).totalCount, 1);
      await expectLater(global.loadOffers(offersQuery, pageSize: 1, cursor: offersPage.nextCursor), throwsFormatException);
      final localSibling = restored.workspaceCatalogueItems.firstWhere((p) => p.id == 'sku-two');
      expect(restored.addOrUpdateWorkspaceProduct(localSibling.copyWith(sellingPriceMinor: 1689951)), isTrue);
      expect(await restored.workspaceInventorySaved, isTrue);
      final unchangedPublic = await connection.readPublicEntry(storeId: 'store-one', skuId: 'sku-two',
        channel: BuyV2OfferClass.retail, current: () => true);
      expect(unchangedPublic!.product.priceMinor, 1689950, reason: 'Private price edit is not publication');
      expect(await restored.requestWorkspaceProductListing('sku-two', listed: true), isFalse);
      expect(await restored.requestWorkspaceProductListing('sku-two', listed: false), isTrue, reason: restored.errorMessage);
      await expectLater(source.loadVariantFamily(entry.product, query), throwsFormatException);
      await control({'action': 'finish'});
      expect(await child.exitCode.timeout(const Duration(seconds: 15)), 0, reason: diagnostics.join('\n'));
    }, timeout: const Timeout(Duration(minutes: 4)));
  }
  test('LF03-ADOPT inventory restores a separate reviewed identity without rewriting the saved SKU', () {
    final item = listingItem();
    final raw = WorkspaceSavedInventory(account: 'owner-one', store: 'store-one', qa: true, revision: 1,
      savedAt: at, products: [item], movements: []).toJson();
    raw['version'] = 5; raw['variantFamilies'] = <Object>[];
    raw['reviewedCatalogueLinks'] = [
      {'version': 1, 'realm': 'evaluation', 'storeId': 'store-one', 'skuId': item.id,
        'canonicalProductId': 'resolved-canonical', 'verifiedPackId': 'resolved-pack', 'mirrorRevision': 1,
        'candidateRevision': 1, 'candidateFingerprint': 'A' * 64,
        'submissionRevision': 1, 'submissionFingerprint': 'B' * 64, 'authoredSha256': 'C' * 64},
    ];
    final restored = WorkspaceSavedInventory.fromJson(raw);
    expect(restored.toJson(), raw); expect(restored.products.single.toInventoryJson(), item.toInventoryJson());
  });
  test('LF03-ADOPT version5 keeps variant families legacy bytes and identity history through projection', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final base = listingItem(), family = WorkspaceVariantFamily(id: 'family-one', revision: 1, title: listingItem().title,
      brand: listingItem().brand, categoryId: listingItem().categoryId, content: listingItem().content,
      options: const [BuyV2VariantAttribute(dimensionId: 'variety', dimensionLabel: 'Variety', optionId: 'sunflower',
        optionLabel: 'Sunflower', kind: BuyV2VariantDimensionKind.other)]);
    final item = base.copyWith(variantMembership: WorkspaceVariantMembership(familyId: family.id, selections: {'variety': 'sunflower'}));
    final link = WorkspaceReviewedCatalogueLink(realm: 'evaluation', storeId: 'store-one', skuId: item.id,
      canonicalProductId: 'resolved-canonical', verifiedPackId: 'resolved-pack', mirrorRevision: 1,
      candidateRevision: 1, candidateFingerprint: 'A' * 64, submissionRevision: 1, submissionFingerprint: 'B' * 64, authoredSha256: 'C' * 64);
    WorkspaceSavedInventory snapshot(int revision, List<WorkspaceReviewedCatalogueLink> links) => WorkspaceSavedInventory(
      account: 'owner-one', store: 'store-one', qa: true, revision: revision, savedAt: at.add(Duration(seconds: revision)),
      products: [item], movements: [], variantFamilies: [family], reviewedCatalogueLinks: links);
    final old = snapshot(1, []), current = snapshot(1, [link]);
    expect(old.toJson()['version'], 4); expect(WorkspaceSavedInventory.fromJson(old.toJson()).toJson(), old.toJson());
    expect(WorkspaceSavedInventory.fromJson(current.toJson()).variantFamilies.single.toJson(), family.toJson());
    expect(current.products.single.toInventoryJson(), old.products.single.toInventoryJson());
    final store = SecureWorkInventoryStore(accountScope: () => 'owner-one');
    await store.save(current, expectedRevision: null);
    await expectLater(store.save(snapshot(2, []), expectedRevision: 1), throwsA(isA<WorkGatewayException>()));
    final changed = WorkspaceReviewedCatalogueLink.fromJson({...link.toJson(), 'candidateFingerprint': 'D' * 64});
    await expectLater(store.save(snapshot(2, [changed]), expectedRevision: 1), throwsA(isA<WorkGatewayException>()));
    for (final malformed in [
      {...current.toJson(), 'reviewedCatalogueLinks': [link.toJson(), link.toJson()]},
      {...current.toJson(), 'reviewedCatalogueLinks': [{...link.toJson(), 'storeId': 'other-store'}]},
      {...current.toJson(), 'reviewedCatalogueLinks': [{...link.toJson(), 'realm': 'production'}]},
    ]) { expect(() => WorkspaceSavedInventory.fromJson(malformed), throwsFormatException); }
    // Storage/projection fixtures only: test metadata retention, not real goods acceptance.
    for (final marker in [1, 2]) {
      expect(await store.projectReceipt('owner-one', 'store-one', qa: true, expectedRevision: marker,
        commit: (previous) async => WorkspaceSavedInventory(account: previous!.account, store: previous.store, qa: previous.qa,
          revision: previous.revision + 1, savedAt: at.add(Duration(minutes: marker)), products: previous.products,
          movements: previous.movements, variantFamilies: previous.variantFamilies, reviewedCatalogueLinks: previous.reviewedCatalogueLinks,
          manualReceiptCheckpointRevision: marker)), isTrue);
    }
    final restored = (await SecureWorkInventoryStore(accountScope: () => 'owner-one').read('owner-one', 'store-one', qa: true))!;
    expect(restored.reviewedCatalogueLinks.single.toJson(), link.toJson());
    expect(restored.products.single.toInventoryJson(), item.toInventoryJson()); expect(restored.variantFamilies.single.toJson(), family.toJson());
  });
  group('LF03-MEDIA private codec display bounds', () {
    late Directory directory;
    final product = workspaceMasterCatalogue.first.copyWith(publicListing: false,
      canonicalId: 'private-photo-codec-test', title: 'Codec test own product');
    WorkPrivateProductPhotoStore store() => WorkPrivateProductPhotoStore(accountId: 'account-A', storeId: 'store-A',
      evaluationOnly: true, isCurrent: () => true, supportDirectory: () async => directory);
    // Codec fixtures only, never uploaded or inserted into native inventory.
    Future<WorkPickedProof> selectedImage({required int width, required int height}) async {
      final recorder = ui.PictureRecorder(); ui.Canvas(recorder).drawColor(const ui.Color(0xff676767), ui.BlendMode.src);
      final picture = recorder.endRecording();
      final image = await picture.toImage(width, height);
      try {
        final data = (await image.toByteData(format: ui.ImageByteFormat.png))!;
        return WorkPickedProof(fileName: 'codec-test.png', contentType: 'image/png', bytes: data.buffer.asUint8List());
      } finally { image.dispose(); picture.dispose(); }
    }
    setUp(() async { directory = await Directory.systemTemp.createTemp('store-private-photo-test-'); });
    tearDown(() async { await directory.delete(recursive: true); }); // This test-created directory only.
    for (final dimensions in [(3000, 3000), (4096, 2048), (2048, 4096), (2048, 2048), (4096, 256)]) {
      test('actual saved PNG meets public display bounds ${dimensions.$1}x${dimensions.$2}', () async {
        final photo = await store().save(product: product, picked: await selectedImage(width: dimensions.$1, height: dimensions.$2));
        expect(photo.width, inInclusiveRange(128, 2048)); expect(photo.height, inInclusiveRange(128, 2048));
        expect(photo.width * photo.height, lessThanOrEqualTo(4000000));
        expect(photo.width, lessThanOrEqualTo(dimensions.$1)); expect(photo.height, lessThanOrEqualTo(dimensions.$2));
        expect((photo.width * dimensions.$2 - photo.height * dimensions.$1).abs(), lessThanOrEqualTo(dimensions.$1 + dimensions.$2));
        final saved = product.copyWith(privatePhoto: photo), bytes = await store().read(saved), codec = await ui.instantiateImageCodec(await store().read(saved));
        try {
          expect(codec.frameCount, 1);
          final frame = await codec.getNextFrame();
          try { expect(frame.image.width, photo.width); expect(frame.image.height, photo.height); }
          finally { frame.image.dispose(); }
        } finally { codec.dispose(); }
        expect(sha256.convert(bytes).toString(), photo.sha256);
        expect(saved.toBuyPublicProduct(storeName: '').mediaAssets, isEmpty, reason: 'Private codec facts are not publication approval.');
        expect(await store().read(saved), orderedEquals(bytes));
      });
    }
    test('extreme aspect cannot become a sub-minimum public derivative', () async {
      await expectLater(store().save(product: product, picked: await selectedImage(width: 8192, height: 256)), throwsA(isA<WorkGatewayException>()));
      expect(await directory.list(recursive: true).length, 0);
    });
    test('legacy private 2400px reference stays byte-identical and unapproved after restart', () async {
      final bytes = (await selectedImage(width: 2400, height: 2400)).bytes;
      final original = WorkspacePrivateProductPhoto(owner: store().owner, identity: WorkspacePrivateProductPhoto.identityOf(product),
        sha256: sha256.convert(bytes).toString(), byteLength: bytes.length, width: 2400, height: 2400);
      final identityHash = sha256.convert(utf8.encode(original.identity)).toString();
      final legacyDirectory = await Directory('${directory.path}/store-product-photos-v1/${original.owner}').create(recursive: true);
      final file = await File('${legacyDirectory.path}/$identityHash-${original.sha256}.png').create(exclusive: true);
      await file.writeAsBytes(bytes, flush: true);
      final restored = WorkspaceCatalogueItem.fromInventoryJson(jsonDecode(jsonEncode(product.copyWith(privatePhoto: original).toInventoryJson())));
      expect(restored.privatePhoto!.toJson(), original.toJson()); expect(await store().read(restored), orderedEquals(bytes));
      expect(await file.readAsBytes(), orderedEquals(bytes)); expect(restored.toBuyPublicProduct(storeName: '').mediaAssets, isEmpty);
    });
  });
  const submissionScope = (account: 'owner-one', store: 'store-one', realm: 'evaluation', sku: 'sku-one');
  WorkspaceProductSubmissionIntent submissionIntent() => WorkspaceProductSubmissionIntent(scope: submissionScope,
    expectedRevision: 0, idempotencyKey: 'product-original', input: WorkspaceProductSubmissionInput.fromSaved(listingItem()));
  Map<String, Object?> submissionAck(WorkspaceProductSubmissionIntent original) => {
    'schemaVersion': 1, 'productSubmissionVersion': 1, 'realm': original.scope.realm, 'storeId': original.scope.store,
    'skuId': original.scope.sku, 'observedAt': at.toIso8601String(), 'idempotencyKey': original.idempotencyKey,
    'state': original.input.mediaPending ? 'awaiting_media' : 'submitted', 'approved': false, 'publicationConfirmed': false, 'orderingAvailable': false,
    'record': {'schemaVersion': 1, 'realm': original.scope.realm, 'storeId': original.scope.store, 'skuId': original.scope.sku,
      'revision': original.expectedRevision + 1, 'submittedAt': at.toIso8601String(), 'submittedBy': original.scope.account,
      'fingerprint': original.candidateFingerprint, 'product': original.input.toJson()}};
  AuthenticatedWorkspaceCatalogueGateway submissionGateway(OwnerTransport transport, {Credentials? credentials, bool supported = true}) =>
    AuthenticatedWorkspaceCatalogueGateway(endpoint: Uri.parse('https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
      credentials: credentials ?? Credentials(), transport: transport, realm: submissionScope.realm, ownerAccountId: submissionScope.account,
      productSubmissionSupported: supported, now: () => at);
  test('LF03-SUBMIT saved inputs allow manual Catalogue and CSV without verified mirror IDs or private inventory', () {
    for (final method in WorkspaceStockEntryMethod.values) {
      final base = listingItem(), item = base.copyWith(stockEntry: WorkspaceStockEntry(method: method,
        productId: base.id, sku: base.sku, pack: base.pack, stockMode: base.stockMode, quantity: base.stock,
        purchasePriceRupees: base.purchasePrice, recordedAt: at, stockAsOf: at));
      final input = WorkspaceProductSubmissionInput.fromSaved(item), value = input.toJson();
      expect(value['provenance'], {'entryMethod': method.name, 'sourceRecordId': base.id});
      expect(value['content']['description'], base.content.description);
      expect(value['channels'].first['priceMinor'], 26000);
      for (final key in ['canonicalProductId', 'verifiedPackId', 'offerId', 'stock', 'purchasePrice', 'publicListing', 'deliveryPromise']) {
        expect(input.fingerprint, isNot(contains('"$key"')));
      }
      expect(value['catalogueProductHint'], base.canonicalId, reason: 'A saved nomination, not an approval identity.');
    }
    final input = submissionIntent().input, mutated = input.toJson()..['stock'] = 100;
    expect(() => WorkspaceProductSubmissionInput.fromJson(mutated), throwsFormatException);
    expect(() => WorkspaceProductSubmissionInput.fromSaved(listingItem().copyWith(clearPackMeasure: true)), throwsFormatException);
  });
  test('LF03-SUBMIT private photo selection is retained as a change fence without private owner or image metadata', () {
    final base = listingItem();
    WorkspaceCatalogueItem withPhoto(String hash) => base.copyWith(privatePhoto: WorkspacePrivateProductPhoto(owner: 'private-owner-do-not-send',
      identity: WorkspacePrivateProductPhoto.identityOf(base), sha256: hash, byteLength: 12000, width: 640, height: 640));
    final first = WorkspaceProductSubmissionInput.fromSaved(withPhoto('a' * 64)), second = WorkspaceProductSubmissionInput.fromSaved(withPhoto('b' * 64));
    expect(first.mediaPending, isTrue); expect(first.fingerprint, isNot(second.fingerprint));
    for (final key in ['private-owner-do-not-send', 'byteLength', 'width', 'height', 'identity', 'localPath']) {
      expect(first.fingerprint, isNot(contains(key)));
    }
    expect(first.toJson()['mediaIntent']['publishedReferences'], isEmpty);
    final old = first.toJson(); old['mediaIntent']['pendingUpload'] = false;
    expect(() => WorkspaceProductSubmissionInput.fromJson(old), throwsFormatException);
  });
  test('LF03-SUBMIT immutable request roundtrip and strict candidate identity fingerprint', () {
    final original = submissionIntent(), data = original.toJson();
    expect(WorkspaceProductSubmissionIntent.fromJson(data).candidateFingerprint, original.candidateFingerprint);
    (data['product'] as Map)['sku'] = 'changed';
    expect(original.input.toJson()['sku'], 'HOST-ONE');
    final record = (submissionAck(original)['record'] as Map<String, Object?>);
    expect(WorkspaceProductSubmissionRecord.decode(jsonDecode(jsonEncode(record)), submissionScope, at).matches(original), isTrue);
    for (final key in ['storeId', 'skuId', 'realm', 'submittedBy', 'fingerprint']) {
      expect(() => WorkspaceProductSubmissionRecord.decode(jsonDecode(jsonEncode({...record, key: 'changed'})), submissionScope, at), throwsFormatException);
    }
  });
  test('LF03-SUBMIT gateway explicit opt-in and pinned owner prevent unsupported or retired dispatch', () async {
    final transport = OwnerTransport((_) async => throw StateError('Must not dispatch'));
    expect((await submissionGateway(transport, supported: false).writeProductSubmission(submissionIntent(), current: () => true)).state,
      WorkspaceProductSubmissionWriteState.notSent);
    final gateway = submissionGateway(transport);
    expect(gateway.forOwnerAccount('another-owner').productSubmissionSupported, isTrue);
    expect((await gateway.forOwnerAccount('another-owner').writeProductSubmission(submissionIntent(), current: () => true)).state,
      WorkspaceProductSubmissionWriteState.notSent);
    var current = true;
    final retiring = submissionGateway(transport, credentials: RetiringOwnerCredentials(() => current = false));
    expect((await retiring.writeProductSubmission(submissionIntent(), current: () => current)).state, WorkspaceProductSubmissionWriteState.notSent);
    expect(transport.calls, 0);
  });
  test('LF03-SUBMIT gateway validates original receipt and uses read-only reconcile with standard App Check', () async {
    final original = submissionIntent(), credentials = Credentials();
    final transport = OwnerTransport((body) async {
      expect(body['productSubmissionVersion'], 1); expect(body['product'], original.input.toJson());
      expect(body.containsKey('family'), isFalse);
      return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': submissionAck(original)}));
    });
    final gateway = submissionGateway(transport, credentials: credentials);
    expect((await gateway.writeProductSubmission(original, current: () => true)).state, WorkspaceProductSubmissionWriteState.submitted);
    expect((await gateway.writeProductSubmission(original, current: () => true, reconcile: true)).state, WorkspaceProductSubmissionWriteState.submitted);
    expect(credentials.modes, [SocialAppCheckTokenMode.limitedUse, SocialAppCheckTokenMode.standard]);
  });
  test('LF03-SUBMIT lost or mismatched acknowledgements remain uncertain and are never auto-retried', () async {
    final original = submissionIntent();
    for (final edit in <void Function(Map<String, Object?>)>[
      (v) {v['approved'] = true;}, (v) {v['publicationConfirmed'] = true;}, (v) {v['orderingAvailable'] = true;},
      (v) {v['idempotencyKey'] = 'different-original';}, (v) {v['state'] = 'published';},
      (v) {(v['record'] as Map)['revision'] = 2;}, (v) {v['record'] = null;},
    ]) {
      final reply = submissionAck(original); edit(reply);
      final transport = OwnerTransport((_) async => SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': reply})));
      expect((await submissionGateway(transport).writeProductSubmission(original, current: () => true)).state, WorkspaceProductSubmissionWriteState.unknown);
      expect(transport.calls, 1);
    }
    final lost = OwnerTransport((_) async => throw StateError('Lost response after dispatch'));
    expect((await submissionGateway(lost).writeProductSubmission(original, current: () => true)).state, WorkspaceProductSubmissionWriteState.unknown);
    expect(lost.calls, 1);
  });
  test('LF03-SUBMIT private head absence differs from original-request not-found', () async {
    final original = submissionIntent();
    final transport = OwnerTransport((body) async {
      final read = body['operation'] == 'readStoreProductSubmission';
      final data = submissionAck(original)..['record'] = null..['state'] = read ? 'none' : 'not_found'..['idempotencyKey'] = read ? null : original.idempotencyKey;
      return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': data}));
    });
    final gateway = submissionGateway(transport);
    expect(await gateway.readProductSubmission(submissionScope, current: () => true), isNull);
    expect((await gateway.writeProductSubmission(original, current: () => true, reconcile: true)).state, WorkspaceProductSubmissionWriteState.notFound);
    expect((await gateway.writeProductSubmission(original, current: () => true)).state, WorkspaceProductSubmissionWriteState.unknown);
  });
  final cartAdditionLog = Platform.environment['LF14_CART_LOG'];
  if (cartAdditionLog != null) {
    Map<String, dynamic> cartCapture() => jsonDecode(File(cartAdditionLog).readAsLinesSync()
      .singleWhere((line) => line.startsWith('LF14_CART_ADDITIONS_PROJECTION='))
      .substring('LF14_CART_ADDITIONS_PROJECTION='.length)) as Map<String, dynamic>;
    WorkspaceProductPresentationGateway cartReporter(OwnerTransport transport, {bool enabled = true,
      String account = 'owner-one', bool Function()? current, SocialContentCredentials? credentials}) {
      final capture = cartCapture(), now = DateTime.parse(capture['aggregate']['observedAt'] as String);
      final entry = WorkspacePublicCatalogueEntry.fromResponse(capture['page'], storeId: 'store-one', realm: 'evaluation', channel: BuyV2OfferClass.retail, now: now);
      return WorkspaceProductPresentationGateway(current: current ?? () => true, displayed: (_) => entry.readback,
        productPresentationsEnabled: false, cartAdditionsEnabled: enabled,
        gateway: AuthenticatedWorkspaceCatalogueGateway(endpoint: Uri.parse('https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
          credentials: credentials ?? Credentials(), transport: transport, realm: 'evaluation', ownerAccountId: account, now: () => now));
    }
    WorkspaceAnalyticsRequest cartAnalyticsRequest({bool zero = false}) {
      final aggregate = cartCapture()[zero ? 'zero' : 'aggregate'] as Map;
      return WorkspaceAnalyticsRequest(accountScope: 'owner-one', storeId: 'store-one',
        start: DateTime.parse(aggregate['start']), end: DateTime.parse(aggregate['end']));
    }
    test('LF14 CART actual service acknowledgement and account union reach the existing Store analytics', () async {
      final capture = cartCapture();
      final reporter = cartReporter(OwnerTransport((body) async => SocialContentResponse(statusCode: 200,
        body: jsonEncode({'ok': true, 'data': body['operation'] == 'recordPublicCartAddition' ? capture['accepted'] : capture['aggregate']}))));
      expect(await reporter.recordCartAddition((capture['event'] as Map).cast<String, Object?>(), ownerCurrent: () => true), true);
      final work = WorkSession(contactDraftStore: ListingAccount())
        ..activeWorkspace = const WorkWorkspace(id: 'store-one', name: 'Host Store', profileId: 'retailer-grocery', profileLabel: 'Grocery', area: 'Jaipur', verified: true)
        ..workspaceId = 'store-one';
      addTearDown(work.dispose); work.bindProductPresentationReader(reporter);
      final snapshot = await work.readWorkspaceAnalytics(cartAnalyticsRequest());
      expect(snapshot.metrics.single.id, 'journey-cart'); expect(snapshot.metrics.single.value, 2);
      expect(snapshot.coverage, WorkspaceAnalyticsCoverage.partial);
      expect(snapshot.metrics.single.source, contains('signed-in accounts'));
      expect(snapshot.metrics.any((m) => {'journey-order', 'cart-dropoff', 'order-conversion'}.contains(m.id)), false);
    });
    test('LF14 CART covered zero stays distinct from unavailable collection', () async {
      final capture = cartCapture(); var absent = false;
      final reporter = cartReporter(OwnerTransport((body) async {
        final data = Map<String, dynamic>.from(capture['zero'] as Map);
        if (absent) { data.addAll({'state': 'unavailable', 'coverage': 'unknown', 'collectionStartedAt': null,
          'coveredFrom': null, 'coveredUntil': null, 'count': null, 'customers': null}); }
        return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': data}));
      }));
      expect((await reporter.readAnalytics(cartAnalyticsRequest(zero: true))).metrics.single.value, 0);
      absent = true;
      final unavailable = await reporter.readAnalytics(cartAnalyticsRequest(zero: true));
      expect(unavailable.state, WorkspaceAnalyticsState.unavailable); expect(unavailable.metrics, isEmpty);
    });
    for (final fault in ['too many customers', 'fraction', 'missing customers', 'private key', 'wrong Store', 'sum mismatch', 'future']) {
      test('LF14 CART rejects $fault instead of showing fabricated counts', () async {
        final reporter = cartReporter(OwnerTransport((body) async {
          final data = Map<String, dynamic>.from(cartCapture()['aggregate'] as Map);
          switch (fault) {
            case 'too many customers': data['customers'] = 4;
            case 'fraction': data['customers'] = 1.5;
            case 'missing customers': data.remove('customers');
            case 'private key': data['customerKey'] = 'opaque-but-private';
            case 'wrong Store': data['storeId'] = 'other-store';
            case 'sum mismatch': data['count'] = 4;
            case 'future': data['observedAt'] = '2027-01-01T00:00:00.000Z';
          }
          return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': data}));
        }));
        final snapshot = await reporter.readAnalytics(cartAnalyticsRequest());
        expect(snapshot.state, WorkspaceAnalyticsState.unavailable); expect(snapshot.metrics, isEmpty);
      });
    }
    test('LF14 CART disabled and retired owner reporting never sends', () async {
      final transport = OwnerTransport((body) async => throw StateError('Must not send'));
      final original = (cartCapture()['event'] as Map).cast<String, Object?>();
      expect(await cartReporter(transport, enabled: false).recordCartAddition(original, ownerCurrent: () => true), false);
      var live = true;
      final retired = cartReporter(transport, current: () => live, credentials: RetiringOwnerCredentials(() => live = false));
      expect(await retired.recordCartAddition(original, ownerCurrent: () => true), false);
      expect(transport.calls, 0);
    });
  }
  final presentationLog = Platform.environment['LF14_PRESENTATION_LOG'];
  if (presentationLog != null) {
    Map<String, dynamic> presentationCapture() {
      const marker = 'LF14_PRESENTATION_PROJECTION=';
      return jsonDecode(File(presentationLog).readAsLinesSync().singleWhere((line) => line.contains(marker)).split(marker).last) as Map<String, dynamic>;
    }
    WorkspacePublicCatalogueEntry presentationEntry(Map<String, dynamic> capture, {bool alternate = false}) =>
      WorkspacePublicCatalogueEntry.fromResponse(capture[alternate ? 'alternatePage' : 'page'] as Map<String, dynamic>,
        storeId: 'store-one', realm: 'evaluation', channel: BuyV2OfferClass.retail, now: DateTime.parse(capture['aggregate']['observedAt'] as String));
    AuthenticatedWorkspaceCatalogueGateway presentationOwner(OwnerTransport transport, {String account = 'owner-one', SocialContentCredentials? credentials}) =>
      AuthenticatedWorkspaceCatalogueGateway(endpoint: Uri.parse('https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
        credentials: credentials ?? Credentials(), transport: transport, realm: 'evaluation', ownerAccountId: account,
        now: () => DateTime.parse(presentationCapture()['aggregate']['observedAt'] as String));
    WorkspaceAnalyticsRequest presentationRequest() => WorkspaceAnalyticsRequest(accountScope: 'owner-one', storeId: 'store-one',
      start: DateTime.parse(presentationCapture()['aggregate']['start'] as String), end: DateTime.parse(presentationCapture()['aggregate']['end'] as String));
    Map<String, dynamic> storeVisitCapture() {
      const marker = 'LF14_STORE_VISITS_PROJECTION=';
      return (jsonDecode(File(presentationLog).readAsLinesSync().singleWhere((l) => l.startsWith(marker)).substring(marker.length)) as Map).cast<String, dynamic>();
    }
    WorkspaceProductPresentationGateway visitGateway(OwnerTransport transport, {bool product = true,
      bool Function()? current, SocialContentCredentials? credentials}) => WorkspaceProductPresentationGateway(
      current: current ?? () => true, displayed: (_) => presentationEntry(presentationCapture()).readback,
      productPresentationsEnabled: product, storePresentationsEnabled: true,
      gateway: AuthenticatedWorkspaceCatalogueGateway(endpoint: Uri.parse('https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
        credentials: credentials ?? Credentials(), transport: transport, realm: 'evaluation', ownerAccountId: 'owner-one',
        now: () => DateTime.parse(storeVisitCapture()['aggregate']['observedAt'] as String)));
    test('LF14-VISITS actual service events and unique signed-in visitors preserve existing product metrics in Work', () async {
      final capture = storeVisitCapture(), event = capture['event'] as Map, credentials = Credentials();
      final gateway = visitGateway(OwnerTransport((body) async => SocialContentResponse(statusCode: 200,
        body: jsonEncode({'ok': true, 'data': switch (body['operation']) {
          'recordPublicStorePresentation' => capture['accepted'], 'readStorePublicPresentations' => capture['aggregate'],
          _ => presentationCapture()['aggregate'],
        }}))), credentials: credentials);
      final original = gateway.prepareStore(BuyV2PublicStoreObservation(realm: 'evaluation', storeId: event['storeId'],
        catalogueVersion: event['catalogueVersion'], observedAt: DateTime.parse(event['observedAt'])), event['presentationId'])!;
      expect(original, event); expect(await gateway.record(original, visible: () => true, storeVisit: true), isTrue);
      final work = WorkSession(contactDraftStore: ListingAccount())
        ..activeWorkspace = const WorkWorkspace(id: 'store-one', name: 'Host Store', profileId: 'retailer-grocery', profileLabel: 'Grocery', area: 'Jaipur', verified: true)
        ..workspaceId = 'store-one';
      addTearDown(work.dispose); work.bindProductPresentationReader(gateway);
      final snapshot = await work.readWorkspaceAnalytics(presentationRequest());
      expect(snapshot.state, WorkspaceAnalyticsState.verified); expect(snapshot.coverage, WorkspaceAnalyticsCoverage.partial);
      expect({for (final metric in snapshot.metrics) metric.id: metric.value}, {'product-views': 1, 'store-views': 3, 'visits': 3, 'visitors': 2, 'journey-store': 2});
      expect(snapshot.metrics.every((m) => m.coverage == WorkspaceAnalyticsCoverage.partial && m.cohortId == null), isTrue);
      expect(snapshot.breakdowns.single.id, 'most-viewed-products');
      expect(credentials.modes, [SocialAppCheckTokenMode.limitedUse, SocialAppCheckTokenMode.standard, SocialAppCheckTokenMode.standard]);
    });
    test('LF14-VISITS covered empty interval supplies genuine zero journey stage without conversion', () async {
      final data = (storeVisitCapture()['zero'] as Map).cast<String, dynamic>();
      final gateway = visitGateway(OwnerTransport((_) async => SocialContentResponse(statusCode: 200,
        body: jsonEncode({'ok': true, 'data': data}))), product: false);
      final snapshot = await gateway.readAnalytics(WorkspaceAnalyticsRequest(accountScope: 'owner-one', storeId: 'store-one',
        start: DateTime.parse(data['start']), end: DateTime.parse(data['end'])));
      expect(snapshot.state, WorkspaceAnalyticsState.verified);
      expect(snapshot.metrics.singleWhere((metric) => metric.id == 'journey-store').value, 0);
      expect(snapshot.metrics.every((metric) => metric.cohortId == null && metric.coverage == WorkspaceAnalyticsCoverage.partial), isTrue);
      expect(snapshot.metrics.where((metric) => ['order-conversion', 'cart-dropoff', 'journey-left'].contains(metric.id)), isEmpty);
    });
    test('LF14-VISITS retired account cannot expose a returned journey stage', () async {
      var live = true;
      final gateway = visitGateway(OwnerTransport((_) async {
        live = false;
        return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': storeVisitCapture()['aggregate']}));
      }), product: false, current: () => live);
      await expectLater(gateway.readAnalytics(presentationRequest()), throwsFormatException);
    });
    for (final fault in ['realm', 'Store', 'extra', 'coverage', 'visitors exceed visits', 'zero visitors with visits', 'future', 'collection', 'range']) {
      test('LF14-VISITS corrupt $fault source stays unavailable, never zero', () async {
        final data = storeVisitCapture()['aggregate'] as Map<String, dynamic>;
        switch (fault) {
          case 'realm': data['realm'] = 'production';
          case 'Store': data['storeId'] = 'other-store';
          case 'extra': data['visitorIds'] = ['private'];
          case 'coverage': data['coverage'] = 'complete';
          case 'visitors exceed visits': data['visitors'] = 4;
          case 'zero visitors with visits': data['visitors'] = 0;
          case 'future': data['observedAt'] = '2026-10-20T00:00:00.000Z';
          case 'collection': data['collectionStartedAt'] = '2026-10-16T12:00:04.000Z';
          case 'range': data['start'] = '2026-10-01T00:00:00.000Z';
        }
        final gateway = visitGateway(OwnerTransport((_) async => SocialContentResponse(statusCode: 200,
          body: jsonEncode({'ok': true, 'data': data}))), product: false);
        final snapshot = await gateway.readAnalytics(presentationRequest());
        expect(snapshot.state, WorkspaceAnalyticsState.unavailable); expect(snapshot.metrics, isEmpty);
      });
    }
    test('LF14-VISITS absent feed retains verified product views and SKU requests cannot acquire whole-Store visitors', () async {
      var missing = true;
      final gateway = visitGateway(OwnerTransport((body) async {
        if (body['operation'] == 'readStorePublicPresentations') {
          return SocialContentResponse(statusCode: missing ? 503 : 200,
            body: jsonEncode({'ok': true, 'data': storeVisitCapture()['sku']}));
        }
        final data = presentationCapture()['aggregate'] as Map<String, dynamic>;
        data['skuIds'] = body['skuIds'];
        return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': data}));
      }));
      final snapshot = await gateway.readAnalytics(presentationRequest());
      expect(snapshot.metrics.single.id, 'product-views'); expect(snapshot.metrics.single.value, 1);
      missing = false;
      final request = presentationRequest();
      final scoped = await gateway.readAnalytics(WorkspaceAnalyticsRequest(accountScope: request.accountScope, storeId: request.storeId,
        start: request.start, end: request.end, skuIds: ['sku-one']));
      expect(scoped.metrics.single.id, 'product-views');
    });
    test('LF14-VISITS age, realm and visibility fences prevent replacement events and retired replies', () async {
      final capture = storeVisitCapture(), event = capture['event'] as Map;
      var live = true;
      final transport = OwnerTransport((_) async {live = false; return SocialContentResponse(statusCode: 200,
        body: jsonEncode({'ok': true, 'data': capture['accepted']}));});
      final gateway = visitGateway(transport, current: () => live);
      final observed = DateTime.parse(event['observedAt']);
      expect(gateway.prepareStore(BuyV2PublicStoreObservation(realm: 'production', storeId: 'store-one', catalogueVersion: 6, observedAt: observed), 'c' * 32), isNull);
      expect(gateway.prepareStore(BuyV2PublicStoreObservation(realm: 'evaluation', storeId: 'store-one', catalogueVersion: 6,
        observedAt: observed.subtract(const Duration(minutes: 10))), 'c' * 32), isNull);
      final original = gateway.prepareStore(BuyV2PublicStoreObservation(realm: 'evaluation', storeId: 'store-one', catalogueVersion: 6, observedAt: observed), 'c' * 32)!;
      expect(await gateway.record(original, visible: () => false, storeVisit: true), isFalse); expect(transport.calls, 0);
      expect(await gateway.record(original, visible: () => true, storeVisit: true), isFalse); expect(transport.calls, 1);
      expect(await gateway.record(original, visible: () => true, storeVisit: true), isFalse); expect(transport.calls, 1);
    });
    test('LF14-VISITS only a decoded exact Store page supplies a fresh Store observation', () async {
      final capture = storeVisitCapture();
      final gateway = AuthenticatedWorkspaceCatalogueGateway(endpoint: Uri.parse('https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
        credentials: Credentials(), realm: 'evaluation', ownerAccountId: 'buyer-one', productFactsReadbackSupported: true,
        minorMoneyReadbackSupported: true, now: () => DateTime.parse(capture['aggregate']['observedAt']),
        transport: OwnerTransport((_) async => SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': capture['page']}))));
      final source = WorkspaceStoreCatalogueSource(gateway: gateway, storeId: 'store-one', current: () => true);
      final page = await source.loadProducts(BuyV2CatalogueQuery(destination: BuyV2Destination.shop, storeId: 'store-one', regionId: null,
        areaScope: BuyV2CatalogueAreaScope.allAreas), pageSize: 40);
      expect(page.storeObservation, isNotNull); expect(page.storeObservation!.catalogueVersion, capture['page']['catalogueVersion']);
      expect(page.storeObservation!.currentFor('store-one', DateTime.parse(capture['aggregate']['observedAt'])), isTrue);
      expect(page.storeObservation!.currentFor('other-store', DateTime.parse(capture['aggregate']['observedAt'])), isFalse);
    });
    testWidgets('LF14-VISITS actual Visit Store paint counts once per opening, not prefetch rebuild or refresh', (tester) async {
      final capture = storeVisitCapture(), sent = <Map<String, Object?>>[], core = BuySession();
      var live = true;
      final now = DateTime.parse(capture['aggregate']['observedAt']);
      final wire = OwnerTransport((body) async {
        if (body['operation'] == 'recordPublicStorePresentation') {
          sent.add(body);
          return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': {
            ...Map<String, Object?>.of(body)..remove('operation'), 'realm': 'evaluation', 'acceptedAt': now.toIso8601String(),
            'state': 'recorded', 'orderingAvailable': false}}));
        }
        if (body['operation'] == 'readPublicStoreCatalogue') {
          return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': capture['page']}));
        }
        return const SocialContentResponse(statusCode: 503, body: '{}');
      });
      final owner = AuthenticatedWorkspaceCatalogueGateway(endpoint: Uri.parse('https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
        credentials: Credentials(), transport: wire, realm: 'evaluation', ownerAccountId: 'buyer-one', productFactsReadbackSupported: true,
        minorMoneyReadbackSupported: true, now: () => now);
      final source = WorkspaceStoreCatalogueSource(gateway: owner, storeId: 'store-one', current: () => live);
      final reporting = WorkspaceProductPresentationGateway(gateway: owner, current: () => live, displayed: (_) => null,
        productPresentationsEnabled: false, storePresentationsEnabled: true);
      final session = BuyV2Session(core: core, cataloguePageSource: source, reviewDataEnabled: false,
        productPresentations: reporting, catalogueNow: () => now);
      final pager = session.acquireCatalogueProducts('host-visit-entry');
      try {
        await pager.open(session.catalogueQuery(storeId: 'store-one'));
        final product = pager.page!.items.first;
        expect(sent, isEmpty);
        final navigator = GlobalKey<NavigatorState>();
        await tester.pumpWidget(MaterialApp(navigatorKey: navigator, theme: MoolTheme.light(), home: Builder(builder: (context) =>
          Scaffold(body: TextButton(onPressed: () => unawaited(showBuyV2PartnerCatalogue(context, session, product)), child: const Text('Open actual Store'))))));
        await tester.tap(find.text('Open actual Store')); await tester.pumpAndSettle();
        expect(sent, hasLength(1)); expect(sent.single['catalogueVersion'], capture['page']['catalogueVersion']);
        session.notifyListeners(); await tester.pumpAndSettle(); expect(sent, hasLength(1));
        await pager.refresh(); await tester.pumpAndSettle(); expect(sent, hasLength(1));
        navigator.currentState!.pop(); await tester.pumpAndSettle();
        await tester.tap(find.text('Open actual Store')); await tester.pumpAndSettle(); expect(sent, hasLength(2));
        expect(sent[0]['presentationId'], isNot(sent[1]['presentationId']));
        navigator.currentState!.pop(); await tester.pumpAndSettle();
        live = false;
        await tester.tap(find.text('Open actual Store')); await tester.pumpAndSettle(); expect(sent, hasLength(2));
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        session.releaseCatalogueProducts('host-visit-entry'); session.dispose(); core.dispose();
      }
    });
    test('LF14-CLIENT actual service projection feeds only product presentations and the existing Work analytics boundary', () async {
      final capture = presentationCapture(), entry = presentationEntry(capture), credentials = Credentials(), sent = <Map<String, Object?>>[];
      final gateway = WorkspaceProductPresentationGateway(current: () => true, displayed: (_) => entry.readback,
        gateway: presentationOwner(OwnerTransport((body) async {
          sent.add(body);
          return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true,
            'data': body['operation'] == 'recordPublicProductPresentation' ? capture['accepted'] : capture['aggregate']}));
        }), credentials: credentials));
      final prepared = gateway.prepare(entry.product, 'a' * 32)!;
      expect(prepared, capture['event']);
      expect(await gateway.record(prepared, visible: () => true), isTrue);
      final work = WorkSession(contactDraftStore: ListingAccount())
        ..activeWorkspace = const WorkWorkspace(id: 'store-one', name: 'Host Store', profileId: 'retailer-grocery', profileLabel: 'Grocery', area: 'Jaipur', verified: true)
        ..workspaceId = 'store-one';
      addTearDown(work.dispose); work.bindProductPresentationReader(gateway);
      expect(work.hasAnalyticsReader, isTrue);
      final snapshot = await work.readWorkspaceAnalytics(presentationRequest());
      expect(snapshot.state, WorkspaceAnalyticsState.verified); expect(snapshot.coverage, WorkspaceAnalyticsCoverage.partial);
      expect(snapshot.metrics.single.id, 'product-views'); expect(snapshot.metrics.single.value, 1);
      expect(snapshot.metrics.single.cohortId, isNull);
      expect(snapshot.breakdowns.single.id, 'most-viewed-products'); expect(snapshot.breakdowns.single.rows.single.id, 'sku-one');
      expect(credentials.modes, [SocialAppCheckTokenMode.limitedUse, SocialAppCheckTokenMode.standard]);
      work.bindProductPresentationReader(null); expect(work.hasAnalyticsReader, isFalse);
      expect((await work.readWorkspaceAnalytics(presentationRequest())).state, WorkspaceAnalyticsState.unavailable);
      expect(sent, hasLength(2));
    });
    for (final corrupt in ['scope', 'coverage', 'count', 'rank count', 'duplicate', 'future', 'before collection', 'extra metric']) {
      test('LF14-CLIENT malformed $corrupt aggregate cannot supply an analytics value', () async {
        final data = presentationCapture()['aggregate'] as Map<String, dynamic>;
        switch (corrupt) {
          case 'scope': data['storeId'] = 'other-store';
          case 'coverage': data['coverage'] = 'complete';
          case 'count': data['count'] = 2;
          case 'rank count': data['products'][0]['count'] = 0;
          case 'duplicate': (data['products'] as List).add(data['products'][0]);
          case 'future': data['observedAt'] = '2027-01-01T00:00:00.000Z';
          case 'before collection': data['coveredFrom'] = data['start'];
          case 'extra metric': data['visitors'] = 100;
        }
        final gateway = WorkspaceProductPresentationGateway(current: () => true, displayed: (_) => null,
          gateway: presentationOwner(OwnerTransport((_) async => SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': data})))));
        await expectLater(gateway.readAnalytics(presentationRequest()), throwsFormatException);
      });
    }
    test('LF14-CLIENT dashboard microsecond cutoff uses explicit millisecond coverage through Work reader', () async {
      final capture = presentationCapture(), range = presentationRequest();
      final request = WorkspaceAnalyticsRequest(accountScope: range.accountScope, storeId: range.storeId,
        start: range.start.add(const Duration(microseconds: 456)), end: range.end.add(const Duration(microseconds: 456)));
      final adapter = WorkspaceProductPresentationGateway(current: () => true, displayed: (_) => null,
        gateway: presentationOwner(OwnerTransport((body) async {
          expect(body['start'], '2026-10-16T00:00:00.001Z'); expect(body['end'], '2026-10-17T00:00:00.000Z');
          return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': capture['precisionAggregate']}));
        })));
      final work = WorkSession(contactDraftStore: ListingAccount())
        ..activeWorkspace = const WorkWorkspace(id: 'store-one', name: 'Host Store', profileId: 'retailer-grocery', profileLabel: 'Grocery', area: 'Jaipur', verified: true)
        ..workspaceId = 'store-one';
      addTearDown(work.dispose); work.bindProductPresentationReader(adapter);
      final snapshot = await work.readWorkspaceAnalytics(request);
      expect(snapshot.state, WorkspaceAnalyticsState.verified); expect(snapshot.request.sameScope(request), isTrue);
      expect(snapshot.metrics.single.value, 1); expect(snapshot.coveredFrom!.isBefore(request.start), isFalse);
      expect(snapshot.coveredUntil!.isAfter(request.end), isFalse);
    });
    test('LF14-CLIENT lost reporting reply never retries or dispatches after visibility or lifetime retires', () async {
      final capture = presentationCapture(), entry = presentationEntry(capture);
      final transport = OwnerTransport((_) async => throw StateError('Host lost acknowledgement'));
      final adapter = WorkspaceProductPresentationGateway(current: () => true, displayed: (_) => entry.readback, gateway: presentationOwner(transport));
      final original = adapter.prepare(entry.product, 'a' * 32)!;
      expect(await adapter.record(original, visible: () => true), isFalse); expect(transport.calls, 1);
      expect(await adapter.record(original, visible: () => false), isFalse); expect(transport.calls, 1);
      var current = true;
      final retiring = WorkspaceProductPresentationGateway(current: () => current, displayed: (_) => entry.readback,
        gateway: presentationOwner(transport, credentials: RetiringOwnerCredentials(() => current = false)));
      expect(await retiring.record(original, visible: () => true), isFalse); expect(transport.calls, 1);
    });
    test('LF14-CLIENT retired A B A owner lifetime cannot send or admit the old event', () async {
      const accountA = (environment: 'host-service', projectId: 'host-project', tenantId: null as String?, userId: 'owner-one');
      const accountB = (environment: 'host-service', projectId: 'host-project', tenantId: null as String?, userId: 'owner-two');
      BuyV2AccountPersistenceIdentity live = accountA;
      final capture = presentationCapture(), entry = presentationEntry(capture), core = BuySession();
      final providers = <WorkspaceProductPresentationGateway>[], outgoing = <Map<String, Object?>>[];
      final root = BuyV2RootSessions(core: core, currentIdentity: () => live, accountStoreFactory: (_, _) => _HostRetirableStateStore(),
        productPresentationFactory: (identity, current, _) {
          final gateway = WorkspaceProductPresentationGateway(current: current, displayed: (_) => entry.readback,
            gateway: presentationOwner(OwnerTransport((body) async {outgoing.add(body); return SocialContentResponse(statusCode: 503, body: '{}');}), account: identity.userId));
          providers.add(gateway); return gateway;
        });
      addTearDown(root.dispose); addTearDown(core.dispose);
      root.synchronize(accountRequired: true); final original = providers.single.prepare(entry.product, 'a' * 32)!;
      expect(root.current.productPresentations, same(providers.single));
      live = accountB; root.synchronize(accountRequired: true); live = accountA; root.synchronize(accountRequired: true);
      expect(providers, hasLength(3)); expect(providers.first.prepare(entry.product, 'b' * 32), isNull);
      expect(await providers.first.record(original, visible: () => true), isFalse); expect(outgoing, isEmpty);
      expect(root.current.productPresentations, same(providers.last));
      expect(configuredWorkspaceProductPresentations(environment: 'firebase-service', projectId: 'moolsocial-dev-503018',
        tenantId: null, accountUserId: 'owner-one', realm: 'evaluation', current: () => true, displayed: (_) => entry.readback), isNull);
    });
    testWidgets('LF14-CLIENT mounted current product frames count once, not loading navigation rebuilds or covered routes', (tester) async {
      final capture = presentationCapture(), entry = presentationEntry(capture), alternate = presentationEntry(capture, alternate: true);
      final sent = <Map<String, Object?>>[], core = BuySession(), catalogue = _ExactMoneyHostCatalogue()..rows.addAll([entry.product, alternate.product]);
      var live = true;
      final observer = WorkspaceProductPresentationGateway(current: () => live, displayed: (product) => product.id == entry.product.id ? entry.readback : alternate.readback,
        gateway: presentationOwner(OwnerTransport((body) async {
          sent.add(body);
          return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': {...capture['accepted'] as Map,
            ...Map<String, Object?>.of(body)..remove('operation')}}));
        }), account: 'buyer-one'));
      final session = BuyV2Session(core: core, cataloguePageSource: catalogue, reviewDataEnabled: false,
        productPresentations: observer, catalogueNow: () => DateTime.parse(capture['aggregate']['observedAt'] as String));
      addTearDown(session.dispose); addTearDown(core.dispose);
      final pager = session.acquireCatalogueProducts('host-presentations');
      addTearDown(() => session.releaseCatalogueProducts('host-presentations'));
      await pager.open(BuyV2CatalogueQuery(destination: BuyV2Destination.shop, regionId: null, areaScope: BuyV2CatalogueAreaScope.allAreas));
      expect(session.openProduct(entry.product.id), isTrue); expect(sent, isEmpty);
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(MaterialApp(navigatorKey: navigator, theme: MoolTheme.light(), home: Scaffold(body:
        AnimatedBuilder(animation: session, builder: (context, _) => BuyV2ProductView(session: session)))));
      await tester.pumpAndSettle(); expect(sent, hasLength(1));
      session.refreshProductContent(entry.product.id); await tester.pumpAndSettle(); expect(sent, hasLength(1));
      unawaited(navigator.currentState!.push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('Host covered route')))));
      await tester.pumpAndSettle();
      expect(session.openProduct(alternate.product.id), isTrue); await tester.pumpAndSettle(); expect(sent, hasLength(1));
      navigator.currentState!.pop(); await tester.pumpAndSettle(); expect(sent, hasLength(2));
      expect(sent[0]['skuId'], 'sku-one'); expect(sent[1]['skuId'], 'sku-two'); expect(sent[0]['presentationId'], isNot(sent[1]['presentationId']));
      expect(session.openProduct(entry.product.id), isTrue); await tester.pumpAndSettle(); expect(sent, hasLength(3));
      live = false; expect(session.openProduct(alternate.product.id), isTrue); await tester.pumpAndSettle(); expect(sent, hasLength(3));
      await tester.pumpWidget(const SizedBox.shrink()); expect(tester.takeException(), isNull);
    });
  }
  final publishedMediaLog = Platform.environment['LF03_PUBLISHED_MEDIA_LOG'];
  if (publishedMediaLog != null) {
    Map<String, dynamic> mediaCapture() {
      const marker = 'LF03_PUBLISHED_MEDIA_PROJECTION=';
      final line = File(publishedMediaLog).readAsLinesSync().singleWhere((line) => line.contains(marker));
      return jsonDecode(line.split(marker).last) as Map<String, dynamic>;
    }
    AuthenticatedWorkspaceCatalogueGateway publishedMediaGateway(OwnerTransport transport, {bool media = true}) =>
      AuthenticatedWorkspaceCatalogueGateway(endpoint: Uri.parse('https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
        credentials: Credentials(), transport: transport, realm: 'evaluation', ownerAccountId: 'owner-one',
        productSubmissionSupported: true, reviewedProductSubmissionSupported: true, productMediaSupported: media, reviewedProductMediaSupported: media, now: () => at);
    test('LF03-PUBLISHED-CLIENT actual backend candidate negotiates media without rewriting its private source', () async {
      final capture = mediaCapture(), bodies = <Map<String, Object?>>[];
      final source = publishedMediaGateway(OwnerTransport((body) async {
        bodies.add(body); return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': capture['ready']}));
      }));
      final reply = await source.readReviewedProductSubmission(submissionScope, current: () => true), candidate = reply.candidate!;
      expect(reply.state, 'ready'); expect(candidate.toJson()['schemaVersion'], 2); expect(candidate.source.input.mediaPending, isTrue);
      expect(candidate.mediaProof!.assetId, capture['ready']['review']['candidate']['source']['media']['assetId']);
      expect(bodies.single['productMediaReviewVersion'], 1);
      final original = candidate.publicationIntent(accountId: 'owner-one', idempotencyKey: 'publish-image-original');
      expect(original.toJson()['schemaVersion'], 3);
      expect(WorkspaceCatalogueBindingIntent.fromJson(original.toJson()).toJson(), original.toJson());
      expect(original.body.containsKey('reviewedMedia'), isFalse); // Private proof stays in recovery, not a new caller-supplied approval field.
      await expectLater(publishedMediaGateway(OwnerTransport((_) async => SocialContentResponse(statusCode: 200,
        body: jsonEncode({'ok': true, 'data': capture['ready']}))), media: false)
        .readReviewedProductSubmission(submissionScope, current: () => true), throwsFormatException);
    });
    test('LF03-PUBLISHED-CLIENT existing upload support never opts an older service into reviewed media', () async {
      final ready = mediaCapture()['ready'] as Map<String, dynamic>;
      ready.remove('productMediaReviewVersion'); ready['review'] = {'version': 1, 'state': 'awaiting_media', 'candidate': null};
      final gateway = AuthenticatedWorkspaceCatalogueGateway(endpoint: Uri.parse('https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
        credentials: Credentials(), realm: 'evaluation', ownerAccountId: 'owner-one', productSubmissionSupported: true,
        reviewedProductSubmissionSupported: true, productMediaSupported: true, now: () => at,
        transport: OwnerTransport((body) async {
          expect(body.containsKey('productMediaReviewVersion'), isFalse);
          return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': ready}));
        }));
      expect(gateway.forOwnerAccount('owner-one').reviewedProductMediaSupported, isFalse);
      expect((await gateway.readReviewedProductSubmission(submissionScope, current: () => true)).state, 'awaiting_media');
    });
    for (final fault in ['scope', 'asset', 'input hash', 'generation', 'width', 'mime', 'normalized', 'descriptor URL', 'descriptor file', 'version']) {
      test('LF03-PUBLISHED-CLIENT rejects rehashed but mismatched $fault media evidence', () async {
        final capture = mediaCapture(), ready = capture['ready'] as Map<String, dynamic>, candidate = ready['review']['candidate'] as Map<String, dynamic>,
          proof = candidate['source']['media'] as Map<String, dynamic>;
        switch (fault) {
          case 'scope': candidate['source']['storeId'] = 'other-store';
          case 'asset': proof['assetId'] = 'A' * 64;
          case 'input hash': proof['selectedSha256'] = 'b' * 64;
          case 'generation': proof['originalGeneration'] = '99';
          case 'width': proof['source']['width'] = 128;
          case 'mime': proof['file']['mimeType'] = 'image/jpeg';
          case 'normalized': proof['file']['normalized'] = false;
          case 'descriptor URL': candidate['sku']['content']['media'][0]['url'] = 'https://evil.invalid/private-original.png';
          case 'descriptor file': candidate['sku']['content']['media'][0]['file']['byteLength'] = 1;
          case 'version': candidate['schemaVersion'] = 1;
        }
        candidate['fingerprint'] = _mediaHash(Map<String, dynamic>.of(candidate)..remove('fingerprint'));
        final gateway = publishedMediaGateway(OwnerTransport((_) async => SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': ready}))));
        await expectLater(gateway.readReviewedProductSubmission(submissionScope, current: () => true), throwsFormatException);
      });
    }
    test('LF03-PUBLISHED-CLIENT existing public reader/gallery binding uses the actual delivered derivative', () async {
      final capture = mediaCapture(), entry = WorkspacePublicCatalogueEntry.fromResponse(capture['publicPage'] as Map<String, dynamic>,
        storeId: 'store-one', realm: 'evaluation', channel: BuyV2OfferClass.retail, now: at);
      final asset = entry.readback.content.media.single, bytes = base64Decode(capture['bytesBase64'] as String),
        proof = WorkspaceReviewedProductMediaProof.fromJson(capture['ready']['review']['candidate']['source']['media']);
      expect(asset.id, proof.assetId); expect(asset.source, proof.descriptor(realm: 'evaluation', storeId: 'store-one', skuId: 'sku-one', canonicalId: 'canonical-one')['url']);
      expect(BuyV2SupplierMediaPolicy.publicationMessage(entry.product, asset), isNull);
      expect(sha256.convert(bytes).toString().toUpperCase(), proof.toJson()['file']['sha256']);
      final codec = await ui.instantiateImageCodec(bytes);
      try {final frame = await codec.getNextFrame(); expect(frame.image.width, proof.toJson()['file']['width']); frame.image.dispose();} finally {codec.dispose();}
    });
    test('LF03-PUBLISHED-CLIENT frozen media adoption journal retains exact evidence through restart', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final capture = mediaCapture(), source = WorkspaceProductSubmissionRecord.decode(capture['source'], submissionScope, at);
      final candidate = WorkspaceReviewedProductCandidate.decode(capture['ready']['review']['candidate'], source, submissionScope, at, allowMedia: true);
      final original = candidate.publicationIntent(accountId: 'owner-one', idempotencyKey: 'recover-media-adoption');
      SecureWorkCatalogueBindingPendingStore journal() => SecureWorkCatalogueBindingPendingStore(currentAccount: () => 'owner-one');
      await journal().savePending(original);
      const scope = (account: 'owner-one', store: 'store-one', realm: 'evaluation');
      final restarted = (await journal().readPending(scope))!;
      expect(restarted.toJson(), original.toJson()); expect(restarted.reviewedMedia!.fingerprint, candidate.mediaProof!.fingerprint);
      final corrupt = original.toJson(); (corrupt['reviewedMedia'] as Map)['derivativeGeneration'] = 'changed';
      expect(() => WorkspaceCatalogueBindingIntent.fromJson(corrupt), throwsFormatException);
      final downgrade = original.toJson()..['schemaVersion'] = 2..remove('reviewedMedia');
      expect(() => WorkspaceCatalogueBindingIntent.fromJson(downgrade), throwsFormatException);
      await journal().removePending(restarted); expect(await journal().readPending(scope), isNull);
    });
    test('LF03-PUBLISHED-CLIENT WorkSession adoption preserves private photo, Stock and durable media sidecar', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final capture = mediaCapture(), account = ListingAccount(), inventory = _AdoptionInventory(SecureWorkInventoryStore(accountScope: () => account.owner));
      var readback = capture['ready'], bindingResponse = capture['response'];
      final source = _AdoptionGateway(publishedMediaGateway(OwnerTransport((body) async {
        final operation = body['operation'];
        return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true,
          'data': operation == 'readStoreProductSubmission' ? readback : bindingResponse}));
      })));
      final work = WorkSession(contactDraftStore: account, catalogueGateway: source, inventoryStore: inventory,
        productSubmissionJournalFactory: (_) => SecureWorkProductSubmissionJournal(currentAccount: () => account.owner),
        purchaseEntryStore: SecureWorkPurchaseEntryStore(accountScope: () => account.owner),
        catalogueBindingPendingStoreFactory: (_) => SecureWorkCatalogueBindingPendingStore(currentAccount: () => account.owner))
        ..activeWorkspace = const WorkWorkspace(id: 'store-one', name: 'Host Store', profileLabel: 'Grocery', profileId: 'retailer-grocery', area: 'Jaipur', verified: true)
        ..workspaceId = 'store-one';
      addTearDown(work.dispose);
      final product = capture['source']['product'] as Map<String, dynamic>, content = product['content'] as Map<String, dynamic>,
        proof = WorkspaceReviewedProductMediaProof.fromJson(capture['ready']['review']['candidate']['source']['media']);
      var item = listingItem().copyWith(canonicalId: 'local-canonical-nomination', title: content['title'] as String,
        brand: content['brand'] as String, variant: content['variant'] as String, categoryId: content['categoryId'] as String,
        sku: product['sku'] as String, barcode: product['barcode'] as String, sellingPriceMinor: product['channels'][0]['priceMinor'] as int,
        mrpMinor: product['channels'][0]['mrpMinor'] as int, content: WorkspaceProductContent(description: content['description'] as String,
          highlights: (content['highlights'] as List).cast<String>(), specifications: {for (final spec in content['specifications'] as List) spec['label'] as String: spec['value'] as String}));
      item = item.copyWith(privatePhoto: WorkspacePrivateProductPhoto(owner: work.privateProductPhotos!.owner,
        identity: WorkspacePrivateProductPhoto.identityOf(item), sha256: proof.selectedSha256,
        byteLength: proof.toJson()['source']['byteLength'] as int, width: proof.toJson()['source']['width'] as int, height: proof.toJson()['source']['height'] as int));
      work.workspaceCatalogueItems.add(item);
      expect(await work.loadWorkspaceInventory(), isTrue); expect(await work.retryWorkspaceInventorySave(), isTrue);
      final before = work.workspaceCatalogueItems.single.toInventoryJson();
      expect(await work.checkWorkspaceProductSubmission(item.id), isTrue);
      expect(work.canPublishReviewedWorkspaceProduct(item.id), isTrue);
      expect(await work.publishReviewedWorkspaceProduct(item.id, inputCurrent: () => true), isTrue, reason: work.errorMessage);
      expect(work.workspaceCatalogueItems.single.toInventoryJson(), {...before, 'publicListing': true});
      expect(work.workspaceStockMovements, isEmpty); expect(work.workspaceInvoices, isEmpty);
      final link = work.workspaceReviewedCatalogueLink(item.id)!;
      expect(link.toJson()['version'], 2); expect(link.mediaProof!.fingerprint, proof.fingerprint);
      final restored = WorkspaceSavedInventory.fromJson(jsonDecode(jsonEncode((await inventory.read('owner-one', 'store-one', qa: true))!.toJson())));
      expect(restored.reviewedCatalogueLinks.single.mediaProof!.fingerprint, proof.fingerprint);
      expect(restored.products.single.privatePhoto!.toJson(), item.privatePhoto!.toJson());
      expect(work.workspaceCatalogueListingPending, isFalse);
      const marker = 'LF03_REMOVED_MEDIA_PROJECTION=';
      final removed = jsonDecode(File(publishedMediaLog).readAsLinesSync().singleWhere((line) => line.contains(marker)).split(marker).last) as Map<String, dynamic>;
      readback = removed['ready']; bindingResponse = removed['response'];
      work.workspaceCatalogueItems[0] = work.workspaceCatalogueItems.single.copyWith(clearPrivatePhoto: true);
      expect(await work.retryWorkspaceInventorySave(), isTrue);
      expect(await work.checkWorkspaceProductSubmission(item.id), isTrue);
      expect(work.canPublishReviewedWorkspaceProduct(item.id), isTrue);
      expect(await work.publishReviewedWorkspaceProduct(item.id, inputCurrent: () => true), isTrue, reason: work.errorMessage);
      expect(work.workspaceReviewedCatalogueLink(item.id)!.mediaProof, isNull);
      expect(work.workspaceCatalogueItems.single.privatePhoto, isNull);
      final removedInventory = WorkspaceSavedInventory.fromJson(jsonDecode(jsonEncode((await inventory.read('owner-one', 'store-one', qa: true))!.toJson())));
      expect(removedInventory.reviewedCatalogueLinks.single.toJson()['version'], 1);
      expect(removedInventory.reviewedCatalogueLinks.single.mediaProof, isNull);
      expect(removedInventory.products.single.privatePhoto, isNull);
      expect(work.workspaceCatalogueItems.single.stock, item.stock);
      expect(work.workspaceStockMovements, isEmpty); expect(work.workspaceInvoices, isEmpty);
      expect(work.workspaceCatalogueListingPending, isFalse);
    });
  }
  final reviewLog = Platform.environment['LF03_REVIEW_LOG'];
  if (reviewLog != null) {
    Map<String, dynamic> reviewCapture(String marker) {
      final lines = File(reviewLog).readAsLinesSync().where((line) => line.contains(marker)).toList();
      expect(lines, hasLength(1));
      return jsonDecode(lines.single.split(marker).last) as Map<String, dynamic>;
    }
    Object? sortedReview(Object? raw) {
      if (raw is List) return raw.map(sortedReview).toList();
      if (raw is Map) { return {for (final key in raw.keys.cast<String>().toList()..sort()) key: sortedReview(raw[key])}; }
      return raw;
    }
    void hashReview(Map<String, dynamic> value) {
      final data = Map<String, dynamic>.of(value)..remove('fingerprint');
      value['fingerprint'] = sha256.convert(utf8.encode(jsonEncode(sortedReview(data)))).toString().toUpperCase();
    }
    AuthenticatedWorkspaceCatalogueGateway reviewGateway(OwnerTransport transport, {bool supported = true, DateTime? now}) =>
      AuthenticatedWorkspaceCatalogueGateway(endpoint: Uri.parse('https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
        credentials: Credentials(), transport: transport, realm: submissionScope.realm, ownerAccountId: submissionScope.account,
        productSubmissionSupported: true, reviewedProductSubmissionSupported: supported, now: () => now ?? at);
    Future<({WorkSession work, _AdoptionInventory inventory, Map<String, dynamic> capture, List<Map<String, Object?>> requests})> adoptionFixture({
      Future<void> Function(WorkSession work, _AdoptionInventory inventory)? beforeBinding,
      bool registerDispose = true,
    }) async {
      FlutterSecureStorage.setMockInitialValues({});
      final capture = reviewCapture('LF_REVIEW_ADOPTION_PROJECTION='), requests = <Map<String, Object?>>[], account = ListingAccount();
      final inventory = _AdoptionInventory(SecureWorkInventoryStore(accountScope: () => account.owner));
      late WorkSession work;
      var bound = false;
      Map<String, dynamic> currentSaved = jsonDecode(jsonEncode(capture['response']['saved'])) as Map<String, dynamic>;
      final source = _AdoptionGateway(reviewGateway(OwnerTransport((body) async {
        requests.add(jsonDecode(jsonEncode(body)) as Map<String, Object?>);
        final operation = body['operation']; Object? data;
        if (operation == 'readStoreProductSubmission') { data = capture[bound ? 'bound' : 'ready']; }
        else if (operation == 'bindReviewedStoreCatalogueSku' || operation == 'reconcileStoreCatalogueBinding') {
          if (operation == 'bindReviewedStoreCatalogueSku') { await beforeBinding?.call(work, inventory); }
          bound = true; data = capture['response'];
          if (operation == 'bindReviewedStoreCatalogueSku' && (body['sku'] as Map)['publicListing'] == false) {
            // Host transport continuation only; backend withdrawal is tested separately.
            currentSaved = {...currentSaved, 'publicListing': false, 'revision': (currentSaved['revision'] as int) + 1};
            data = {...capture['response'] as Map<String, dynamic>, 'saved': currentSaved};
          }
        } else if (operation == 'listStoreCatalogueSkus') {
          data = {'schemaVersion': 1, 'realm': 'evaluation', 'storeId': 'store-one', 'mediaReadbackVersion': 1,
            'items': [currentSaved], 'nextCursor': null};
        } else { throw StateError('Unexpected host operation $operation'); }
        return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': data}));
      })));
      final product = capture['source']['product'] as Map<String, dynamic>, content = product['content'] as Map<String, dynamic>;
      final item = listingItem().copyWith(canonicalId: 'local-canonical-nomination', title: content['title'] as String,
        brand: content['brand'] as String, variant: content['variant'] as String, categoryId: content['categoryId'] as String,
        sku: product['sku'] as String, barcode: product['barcode'] as String,
        sellingPriceMinor: product['channels'][0]['priceMinor'] as int, mrpMinor: product['channels'][0]['mrpMinor'] as int,
        content: WorkspaceProductContent(description: content['description'] as String,
          highlights: (content['highlights'] as List).cast<String>(),
          specifications: {for (final raw in content['specifications'] as List) raw['label'] as String: raw['value'] as String}));
      work = WorkSession(contactDraftStore: account, catalogueGateway: source, inventoryStore: inventory,
        productSubmissionJournalFactory: (_) => SecureWorkProductSubmissionJournal(currentAccount: () => account.owner),
        purchaseEntryStore: SecureWorkPurchaseEntryStore(accountScope: () => account.owner),
        catalogueBindingPendingStoreFactory: (_) => SecureWorkCatalogueBindingPendingStore(currentAccount: () => account.owner))
        ..activeWorkspace = const WorkWorkspace(id: 'store-one', name: 'Host Store', profileLabel: 'Grocery',
          profileId: 'retailer-grocery', area: 'Jaipur', verified: true)
        ..workspaceId = 'store-one' ..workspaceCatalogueItems.add(item);
      if (registerDispose) addTearDown(work.dispose);
      expect(await work.loadWorkspaceInventory(), isTrue); expect(await work.retryWorkspaceInventorySave(), isTrue);
      expect(await work.checkWorkspaceProductSubmission(item.id), isTrue, reason: work.workspaceProductSubmission(item.id)?.message);
      expect(work.canPublishReviewedWorkspaceProduct(item.id), isTrue);
      return (work: work, inventory: inventory, capture: capture, requests: requests);
    }
    test('LF03-ADOPT explicit owner publication keeps local SKU Stock provenance and survives restart', () async {
      final fixture = await adoptionFixture(), work = fixture.work;
      final before = work.workspaceCatalogueItems.single.toInventoryJson();
      expect(await work.publishReviewedWorkspaceProduct('sku-one', inputCurrent: () => true), isTrue, reason: work.errorMessage);
      final after = work.workspaceCatalogueItems.single.toInventoryJson();
      expect(after, {...before, 'publicListing': true}); expect(work.workspaceStockMovements, isEmpty);
      final link = work.workspaceReviewedCatalogueLink('sku-one')!;
      expect(link.canonicalProductId, fixture.capture['request']['sku']['canonicalProductId']);
      expect(link.canonicalProductId, isNot(work.workspaceCatalogueItems.single.canonicalId));
      final saved = (await fixture.inventory.read('owner-one', 'store-one', qa: true))!;
      expect(saved.toJson()['version'], 5); expect(saved.reviewedCatalogueLinks.single.toJson(), link.toJson());
      expect(WorkspaceSavedInventory.fromJson(jsonDecode(jsonEncode(saved.toJson()))).products.single.toInventoryJson(), after);
      expect(work.workspaceCatalogueListingPending, isFalse); expect(work.canPublishReviewedWorkspaceProduct('sku-one'), isFalse);
      expect(fixture.requests.where((body) => body['operation'] == 'bindReviewedStoreCatalogueSku'), hasLength(1));
      expect(fixture.requests.first['operation'], 'readStoreProductSubmission');
    });
    test('LF03-ADOPT local edit blocks republishing but permits withdrawing the exact old mirror', () async {
      final fixture = await adoptionFixture(), work = fixture.work;
      expect(await work.publishReviewedWorkspaceProduct('sku-one', inputCurrent: () => true), isTrue);
      final original = work.workspaceCatalogueItems.single;
      expect(work.addOrUpdateWorkspaceProduct(original.copyWith(title: 'New private title', barcode: 'CHANGED')), isTrue);
      expect(await work.workspaceInventorySaved, isTrue);
      expect(await work.requestWorkspaceProductListing('sku-one', listed: true), isFalse);
      expect(fixture.requests.where((body) => body['operation'] == 'bindReviewedStoreCatalogueSku'), hasLength(1));
      expect(await work.requestWorkspaceProductListing('sku-one', listed: false), isTrue, reason: work.errorMessage);
      final withdrawal = fixture.requests.lastWhere((body) => body['operation'] == 'bindReviewedStoreCatalogueSku');
      expect((withdrawal['sku'] as Map)['publicListing'], isFalse);
      expect(((withdrawal['sku'] as Map)['content'] as Map)['title'], original.title);
      expect(work.workspaceCatalogueItems.single.title, 'New private title');
      expect(work.workspaceReviewedCatalogueLink('sku-one')!.mirrorRevision, 1);
    });
    for (final fault in ['local save', 'private edit', 'store ABA']) {
      test('LF03-ADOPT $fault keeps exact publication original for read-only recovery', () async {
        WorkspaceCatalogueItem? originalItem;
        final fixture = await adoptionFixture(beforeBinding: (work, inventory) async {
          originalItem = work.workspaceCatalogueItems.single;
          if (fault == 'local save') inventory.failReviewed = true;
          if (fault == 'private edit') work.workspaceCatalogueItems[0] = originalItem!.copyWith(barcode: 'CHANGED');
          if (fault == 'store ABA') {
            final old = work.activeWorkspace!;
            work.activeWorkspace = const WorkWorkspace(id: 'other-store', name: 'Other', profileLabel: 'Grocery', profileId: 'retailer-grocery', area: '', verified: true);
            work.activeWorkspace = old;
          }
        });
        final work = fixture.work;
        expect(await work.publishReviewedWorkspaceProduct('sku-one', inputCurrent: () => true), isFalse);
        expect(work.workspaceCatalogueListingPending, isTrue);
        final original = fixture.requests.singleWhere((body) => body['operation'] == 'bindReviewedStoreCatalogueSku');
        expect(original['reviewCandidate'], fixture.capture['request']['reviewCandidate']);
        fixture.inventory.failReviewed = false;
        if (fault == 'private edit') { work.workspaceCatalogueItems[0] = originalItem!; }
        expect(await work.reconcileWorkspaceCatalogueListing(), isTrue, reason: work.errorMessage);
        final recovered = fixture.requests.singleWhere((body) => body['operation'] == 'reconcileStoreCatalogueBinding');
        expect(Map<String, Object?>.of(recovered)..remove('operation'), Map<String, Object?>.of(original)..remove('operation'));
        expect(work.workspaceCatalogueListingPending, isFalse); expect(work.workspaceCatalogueItems.single.canonicalId, 'local-canonical-nomination');
      });
    }
    test('LF03-ADOPT waits preceding save then fences ABA before any further inventory write', () async {
      final entered = Completer<void>(), release = Completer<void>();
      final fixture = await adoptionFixture(beforeBinding: (work, inventory) async {
        inventory.enteredSave = entered; inventory.holdSave = release;
        unawaited(work.retryWorkspaceInventorySave()); await entered.future;
      });
      final posting = fixture.work.publishReviewedWorkspaceProduct('sku-one', inputCurrent: () => true);
      await entered.future; await Future<void>.delayed(Duration.zero);
      final old = fixture.work.activeWorkspace!;
      fixture.work.activeWorkspace = const WorkWorkspace(id: 'other-store', name: 'Other', profileLabel: 'Grocery', profileId: 'retailer-grocery', area: '', verified: true);
      fixture.work.activeWorkspace = old;
      final count = fixture.inventory.writes.length; release.complete();
      expect(await posting, isFalse); expect(fixture.inventory.writes, hasLength(count));
      expect(fixture.work.workspaceReviewedCatalogueLink('sku-one'), isNull);
      expect(fixture.work.workspaceCatalogueListingPending, isTrue);
      fixture.inventory.holdSave = null;
      expect(await fixture.work.reconcileWorkspaceCatalogueListing(), isTrue);
    });
    test('LF03-ADOPT receipt lock acquired during binding prevents any adoption mutation', () async {
      _AdoptionHeldLedger? held; Future<WorkspaceGoodsReceiptSaveResult>? receiving;
      final fixture = await adoptionFixture(beforeBinding: (work, inventory) async {
        final finance = WorkspaceFinanceSnapshot(accountScope: 'owner-one', workspaceId: 'store-one', revision: 1, asOf: at,
          salesTodayMinor: 0, duesMinor: 0, availableMinor: 0, heldMinor: 0, requestedMinor: 0, paidOutMinor: 0,
          feesMinor: 0, deliveryAdjustmentsMinor: 0, refundsMinor: 0, taxWithheldMinor: 0, payments: const [], payouts: const [], historyComplete: true);
        expect(work.applyWorkspaceFinance(finance), isTrue);
        held = _AdoptionHeldLedger(SecureWorkLedgerCheckpointStore(accountScope: () => 'owner-one'));
        expect(work.bindCustomerCollectionGateway(accountScope: 'owner-one', storeId: 'store-one',
          adapter: StoreReviewCustomerCollectionGateway(finance), checkpointStore: held), isTrue);
        expect(await work.loadWorkspaceSuppliers(), isTrue);
        final item = work.workspaceCatalogueItems.single;
        final receipt = WorkspaceSupplierGoodsReceipt(id: 'host-lock-receipt', expectedDeliveryId: 'host-delivery', reference: 'HOST-LOCK',
          deliveredOn: '2026-10-16', recordedAt: DateTime.now().toUtc(), lines: [WorkspaceSupplierGoodsReceiptLine(
            sourceLineId: 'host-line', productId: item.id, productLabel: item.title, purchaseUnit: item.pack, stockUnit: item.pack,
            unitsPerPack: 1, deliveredMilli: 6000, acceptedMilli: 6000, damagedMilli: 0, shortMilli: 0, expectedMilli: 12000)]);
        receiving = work.confirmWorkspaceSupplierGoodsReceipt(receipt, supplierId: 'unconfirmed-host-supplier',
          scope: work.workspaceSupplierScope!, expectedPurchaseRevision: 0, expectedSupplierRevision: 1);
        expect(work.workspaceGoodsReceiptBusy, isTrue); await held!.entered.future;
      });
      expect(await fixture.work.publishReviewedWorkspaceProduct('sku-one', inputCurrent: () => true), isFalse);
      expect(fixture.work.workspaceReviewedCatalogueLink('sku-one'), isNull);
      expect(fixture.work.workspaceCatalogueItems.single.publicListing, isFalse);
      expect(fixture.work.workspaceCatalogueListingPending, isTrue);
      held!.gate.complete(); expect(await receiving, WorkspaceGoodsReceiptSaveResult.notPosted);
      expect(fixture.work.workspaceGoodsReceiptBusy, isFalse);
      expect(await fixture.work.reconcileWorkspaceCatalogueListing(), isTrue);
    });
    for (final scale in [1.0, 2.0]) {
      testWidgets('LF03-ADOPT explicit editor action fits and ordinary opening never publishes at $scale', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale; addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final fixture = await tester.runAsync(() => adoptionFixture(registerDispose: false));
        const captureKey = Key('adoption-host-root');
        await openListingEditor(tester, fixture!.work, captureKey: captureKey, theme: MoolTheme.light());
        final publish = find.byKey(const Key('work-product-review-publish'));
        await tester.ensureVisible(publish); await tester.pumpAndSettle();
        expect(tester.widget<TextButton>(publish).onPressed, isNotNull); expect(tester.getSize(publish).height, greaterThanOrEqualTo(48));
        expect(find.byKey(const Key('work-product-review-submit')), findsNothing, reason: 'Do not compete with publication by offering duplicate submission of the already-reviewed saved details');
        expect(fixture.requests.where((b) => b['operation'] == 'bindReviewedStoreCatalogueSku'), isEmpty);
        expect(tester.takeException(), isNull);
        final directory = Platform.environment['LF03_ADOPTION_CAPTURE_DIR'];
        if (directory != null) {
          final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(captureKey));
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            try {
              final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
              await Directory(directory).create(recursive: true);
              final file = File('$directory/reviewed-adoption-host-$scale.png');
              if (await file.exists()) throw StateError('Preserve existing host capture');
              await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
            } finally { image.dispose(); }
          });
        }
      });
    }
    test('LF03-REVIEW actual reviewed candidate negotiates exact facts and immutable versioned binding intent', () async {
      final actual = reviewCapture('LF_REVIEW_CANDIDATE_PROJECTION=');
      final transport = OwnerTransport((body) async {
        expect(body, {'operation': 'readStoreProductSubmission', 'productSubmissionVersion': 1, 'productReviewVersion': 1,
          'storeId': 'store-one', 'skuId': 'sku-one'});
        return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': actual}));
      });
      final source = reviewGateway(transport), result = await source.readReviewedProductSubmission(submissionScope, current: () => true);
      expect(result.state, 'ready'); expect(result.candidate!.toJson(), actual['review']['candidate']);
      expect(result.record!.toJson(), actual['record']);
      expect(result.candidate!.sku['channels'].first['priceMinor'], 10025);
      expect(source.forOwnerAccount('another-owner').reviewedProductSubmissionSupported, isTrue);
      final intent = result.candidate!.publicationIntent(accountId: submissionScope.account, idempotencyKey: 'explicit-publication');
      expect(intent.toJson()['schemaVersion'], 2); expect(intent.body['reviewCandidate'],
        {'revision': result.candidate!.revision, 'fingerprint': result.candidate!.fingerprint});
      expect(WorkspaceCatalogueBindingIntent.fromJson(intent.toJson()).toJson(), intent.toJson());
      expect(intent.reviewedSource!.toJson(), actual['record']);
      expect(intent.body.containsKey('reviewedSource'), isFalse, reason: 'Private recovery context is journalled, not sent as owner-selected review facts');
      final legacy = WorkspaceCatalogueBindingIntent(accountId: intent.accountId, realm: intent.realm, storeId: intent.storeId,
        expectedRevision: intent.expectedRevision, idempotencyKey: 'legacy', sku: intent.sku);
      expect(legacy.toJson()['schemaVersion'], 1); expect(legacy.body.containsKey('reviewCandidate'), isFalse);
      expect(WorkspaceCatalogueBindingIntent.fromJson(legacy.toJson()).toJson(), legacy.toJson());
      final edited = jsonDecode(jsonEncode(intent.toJson())) as Map<String, dynamic>;
      edited['reviewCandidate']['revision'] = 99; edited['sku']['content']['title'] = 'Caller mutation';
      expect(intent.body['reviewCandidate'], isNot(edited['reviewCandidate']));
      expect(result.candidate!.sku['content']['title'], isNot('Caller mutation'));
    });
    test('LF03-REVIEW actual candidate rejects altered facts self review scope and late replies even with rehashed data', () async {
      final edits = <void Function(Map<String, dynamic>)>[
        (v) {v['review']['candidate']['sku']['channels'][0]['priceMinor'] = 1;},
        (v) {v['review']['candidate']['source']['fingerprint'] = 'A' * 64;},
        (v) {v['review']['candidate']['source']['revision'] = 1.0;},
        (v) {v['review']['candidate']['reviewedBy'] = 'owner-one';},
        (v) {v['review']['candidate']['terms'][0]['termSnapshotSha256'] = 'A' * 64;},
        (v) {v['review']['candidate']['realm'] = 'production';},
        (v) {v['review']['candidate']['sku']['content']['description'] = 'Not the saved description';},
        (v) {v['review']['candidate']['reviewedAt'] = '2026-10-16T12:00:00+00:00';},
      ];
      for (final edit in edits) {
        final actual = reviewCapture('LF_REVIEW_CANDIDATE_PROJECTION='); edit(actual); hashReview(actual['review']['candidate'] as Map<String, dynamic>);
        final source = reviewGateway(OwnerTransport((_) async => SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': actual}))));
        await expectLater(source.readReviewedProductSubmission(submissionScope, current: () => true), throwsFormatException);
      }
      final actual = reviewCapture('LF_REVIEW_CANDIDATE_PROJECTION=');
      final late = reviewGateway(OwnerTransport((_) async => SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': actual}))),
        now: at.add(const Duration(hours: 1)));
      await expectLater(late.readReviewedProductSubmission(submissionScope, current: () => true), throwsFormatException);
      var current = true;
      final retired = reviewGateway(OwnerTransport((_) async { current = false;
        return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': actual})); }));
      await expectLater(retired.readReviewedProductSubmission(submissionScope, current: () => current), throwsFormatException);
      final disabledTransport = OwnerTransport((_) async => throw StateError('Must not send'));
      await expectLater(reviewGateway(disabledTransport, supported: false).readReviewedProductSubmission(submissionScope, current: () => true), throwsFormatException);
      expect(disabledTransport.calls, 0);
    });
    test('LF03-REVIEW actual binding acknowledgement stays journalled until local identity completion succeeds', () async {
      final capture = reviewCapture('LF_REVIEW_BINDING_PROJECTION='), request = capture['request'] as Map<String, dynamic>;
      final original = WorkspaceCatalogueBindingIntent(accountId: submissionScope.account, realm: submissionScope.realm,
        storeId: submissionScope.store, expectedRevision: request['expectedRevision'] as int, idempotencyKey: request['idempotencyKey'] as String,
        sku: request['sku'] as Map<String, dynamic>, reviewCandidate: request['reviewCandidate'] as Map<String, dynamic>,
        reviewedSource: WorkspaceProductSubmissionRecord.decode(capture['source'], submissionScope, at));
      final operations = <String>[];
      final source = reviewGateway(OwnerTransport((body) async {
        operations.add(body['operation']! as String);
        expect(Map<String, Object?>.of(body)..remove('operation'), original.body);
        return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': capture['response']}));
      }));
      FlutterSecureStorage.setMockInitialValues({});
      SecureWorkCatalogueBindingPendingStore journal() => SecureWorkCatalogueBindingPendingStore(currentAccount: () => submissionScope.account);
      final scope = (account: submissionScope.account, store: submissionScope.store, realm: submissionScope.realm);
      final first = WorkspaceCatalogueListingController(scope: scope, gateway: source, pendingStore: journal(), context: () => 'same-owner');
      addTearDown(first.dispose);
      expect((await first.submit(original, inputCurrent: () => true)).state, WorkspaceCatalogueBindingState.unknown);
      expect((await journal().readPending(scope))!.toJson(), original.toJson());
      var completed = false, finishes = 0;
      final restarted = WorkspaceCatalogueListingController(scope: scope, gateway: source, pendingStore: journal(), context: () => 'same-owner',
        completeReviewedBinding: (intent, saved, current) async { finishes++; expect(current(), isTrue);
          expect(intent.toJson(), original.toJson()); expect(saved.canonicalProductId, original.sku['canonicalProductId']); return completed; });
      addTearDown(restarted.dispose);
      expect((await restarted.reconcile()).state, WorkspaceCatalogueBindingState.unknown);
      expect((await journal().readPending(scope))!.toJson(), original.toJson());
      completed = true;
      expect((await restarted.reconcile()).state, WorkspaceCatalogueBindingState.saved);
      expect(await journal().readPending(scope), isNull); expect(finishes, 2);
      expect(operations, ['bindReviewedStoreCatalogueSku', 'reconcileStoreCatalogueBinding', 'reconcileStoreCatalogueBinding']);
    });
    test('LF03-REVIEW historical version2 original restores after a device clock rollback', () {
      final capture = reviewCapture('LF_REVIEW_BINDING_PROJECTION='), request = capture['request'] as Map<String, dynamic>;
      // Labelled host clock simulation: the original was received under a later
      // clock. Do not alter native time or treat this as a fresh provider result.
      final laterClock = DateTime.utc(2050, 1, 1), record = capture['source'] as Map<String, dynamic>;
      record['submittedAt'] = laterClock.toIso8601String();
      final original = WorkspaceCatalogueBindingIntent(accountId: submissionScope.account, realm: submissionScope.realm,
        storeId: submissionScope.store, expectedRevision: request['expectedRevision'] as int, idempotencyKey: request['idempotencyKey'] as String,
        sku: request['sku'] as Map<String, dynamic>, reviewCandidate: request['reviewCandidate'] as Map<String, dynamic>,
        reviewedSource: WorkspaceProductSubmissionRecord.decode(record, submissionScope, laterClock));
      expect(WorkspaceCatalogueBindingIntent.fromJson(original.toJson()).toJson(), original.toJson());
    });
  }
  final submissionLog = Platform.environment['LF03_SUBMISSION_LOG'];
  if (submissionLog != null) { test('LF03-SUBMIT actual emulator receipt decodes without approving or publishing', () async {
    const marker = 'LF_SUBMISSION_PROJECTION=';
    final captures = File(submissionLog).readAsLinesSync().where((line) => line.contains(marker)).toList();
    expect(captures, hasLength(1));
    final actual = jsonDecode(captures.single.split(marker).last) as Map<String, dynamic>;
    final record = actual['record'] as Map<String, dynamic>;
    final original = WorkspaceProductSubmissionIntent(scope: submissionScope, expectedRevision: 0,
      idempotencyKey: actual['idempotencyKey'] as String, input: WorkspaceProductSubmissionInput.fromJson(record['product']));
    final gateway = submissionGateway(OwnerTransport((body) async {
      expect(body['product'], original.input.toJson());
      return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': actual}));
    }));
    final result = await gateway.writeProductSubmission(original, current: () => true);
    expect(result.state, WorkspaceProductSubmissionWriteState.submitted);
    expect(result.record!.fingerprint, record['fingerprint']); expect(actual['publicationConfirmed'], isFalse);
  }); }
  WorkspaceProductSubmissionRecord submissionRecord(WorkspaceProductSubmissionIntent original) =>
    WorkspaceProductSubmissionRecord.decode(jsonDecode(jsonEncode(submissionAck(original)['record'])), original.scope, at);
  WorkspaceProductSubmissionController productController(_ProductOwner source, _ProductJournal journal, {Object? Function()? context}) =>
    WorkspaceProductSubmissionController(scope: submissionScope, gateway: source, journal: journal, context: context ?? () => 'host-owner');
  WorkSession productSession(_ProductOwner source, _ProductJournal journal, {WorkspaceProductMediaJournal? mediaJournal, Directory? photoDirectory}) => WorkSession(contactDraftStore: ListingAccount(),
    catalogueGateway: source, productSubmissionJournalFactory: (_) => journal,
    productMediaJournalFactory: mediaJournal == null ? null : (_) => mediaJournal,
    productPhotoSupportDirectory: photoDirectory == null ? null : () async => photoDirectory)
      ..activeWorkspace = const WorkWorkspace(id: 'store-one', name: 'Host Store', profileLabel: 'Grocery', profileId: 'retailer-grocery', area: 'Jaipur', verified: true)
      ..workspaceId = 'store-one' ..workspaceCatalogueItems.add(listingItem());
  for (final scale in [1.0, 2.0]) {
    testWidgets('LF03-UPLOAD saved-photo editor uses actual private bytes, explicit actions and readable recovery at $scale', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale; addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      late Directory directory;
      await tester.runAsync(() async {directory = await Directory.systemTemp.createTemp('lf03-media-editor-');});
      final owner = _ProductMediaOwner(), journal = _MediaJournal(), work = productSession(owner, _ProductJournal(), mediaJournal: journal, photoDirectory: directory);
      late Uint8List bytes;
      final originalItem = work.workspaceCatalogueItems.single;
      await tester.runAsync(() async {
        bytes = await mediaBytes();
        final photo = await work.privateProductPhotos!.save(product: originalItem,
          picked: WorkPickedProof(fileName: 'actual-host-photo.png', contentType: 'image/png', bytes: bytes));
        work.workspaceCatalogueItems[0] = originalItem.copyWith(privatePhoto: photo);
      });
      final input = WorkspaceProductSubmissionInput.fromSaved(work.workspaceCatalogueItems.single);
      owner.head = submissionRecord(WorkspaceProductSubmissionIntent(scope: submissionScope, expectedRevision: 0, idempotencyKey: 'host-media-source', input: input));
      final put = _MediaPut(); var uploaded = false;
      put.afterWrite = () async {uploaded = true;};
      final api = _MediaApi((body) {
        final raw = Map<String, Object?>.of(body)..remove('operation')..remove('productMediaVersion');
        final original = WorkspaceProductMediaIntent.fromJson({'schemaVersion': 1, 'accountId': 'owner-one', 'realm': 'evaluation', ...raw});
        return _mediaReply(original, put.bytes ?? bytes, state: body['operation'] == 'prepareStoreProductMedia' ? 'awaiting_upload'
          : uploaded ? 'processed' : 'not_found', grant: body['operation'] == 'prepareStoreProductMedia');
      });
      owner.media = _mediaGateway(api, put);
      const captureKey = Key('media-editor-host-root');
      await openListingEditor(tester, work, captureKey: captureKey, theme: MoolTheme.light());
      expect(api.bodies, isEmpty); expect(put.calls, 0); // Opening and local journal restore are not uploads.
      final check = find.byKey(const Key('work-product-review-check'));
      await tester.ensureVisible(check); await tester.pumpAndSettle(); await tester.tap(check); await tester.pumpAndSettle();
      expect(api.bodies, isEmpty);
      final upload = find.byKey(const Key('work-product-photo-upload'));
      await tester.ensureVisible(upload); await tester.pumpAndSettle();
      expect(tester.getSize(upload).height, greaterThanOrEqualTo(48));
      await tester.tap(upload);
      // Alternate framework microtasks with real file IO, rather than waiting inside the wrong fake-async zone.
      for (var turn = 0; turn < 100 && journal.saved?.result == null; turn++) {
        await tester.pump(const Duration(milliseconds: 10));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      }
      await tester.pumpAndSettle();
      expect(put.calls, 1, reason: '${work.errorMessage} ${work.workspaceProductMedia('sku-one')?.message}');
      expect(journal.saved!.result!.processed, isTrue); expect(owner.submitted, isEmpty);
      expect(work.workspaceCatalogueItems.single.privatePhoto!.sha256, sha256.convert(put.bytes!).toString());
      expect(work.workspaceOrders, isEmpty); expect(work.workspaceInvoices, isEmpty);
      final status = find.byKey(const Key('work-product-photo-status'));
      await tester.ensureVisible(status); await tester.pumpAndSettle();
      expect(find.textContaining('Photo processed privately'), findsOneWidget); expect(tester.takeException(), isNull);
      final captureDirectory = Platform.environment['LF03_MEDIA_CAPTURE_DIR'];
      if (captureDirectory != null) {
        final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(captureKey));
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          try {
            final data = (await image.toByteData(format: ui.ImageByteFormat.png))!;
            await Directory(captureDirectory).create(recursive: true);
            final file = File('$captureDirectory/media-editor-$scale.png');
            if (await file.exists()) throw StateError('Preserve existing host capture.');
            await file.writeAsBytes(data.buffer.asUint8List());
          } finally {image.dispose();}
        });
      }
    });
  }
  test('LF03-SUBMIT recovery journals before dispatch and never calls a reviewed mirror', () async {
    final owner = _ProductOwner(), journal = _ProductJournal(), controller = productController(owner, journal);
    addTearDown(controller.dispose);
    owner.write = (original, _) async {
      expect(journal.pending!.fingerprint, original.fingerprint);
      return WorkspaceProductSubmissionWriteResult(WorkspaceProductSubmissionWriteState.submitted, submissionRecord(original));
    };
    expect(await controller.refresh(), isTrue); expect(owner.submitted, isEmpty);
    expect((await controller.submit(submissionIntent().input, inputCurrent: () => true)).state, WorkspaceProductSubmissionWriteState.submitted);
    expect(journal.pending, isNull); expect(controller.headLoaded, isFalse); expect(controller.message, contains('not approval'));
  });
  test('LF03-SUBMIT uncertain request survives controller restart and retries only its frozen original', () async {
    final owner = _ProductOwner(), journal = _ProductJournal(), first = productController(owner, journal);
    expect(await first.refresh(), isTrue);
    await first.submit(submissionIntent().input, inputCurrent: () => true);
    final original = journal.pending!; first.dispose();
    final next = productController(owner, journal); addTearDown(next.dispose);
    expect(await next.restore(), isTrue); expect(next.canSubmit, isFalse);
    owner.write = (_, _) async => const WorkspaceProductSubmissionWriteResult(WorkspaceProductSubmissionWriteState.notFound);
    await next.reconcile(); expect(next.canRetryOriginal, isTrue); expect(journal.pending!.fingerprint, original.fingerprint);
    owner.write = (request, _) async {
      expect(request.fingerprint, original.fingerprint);
      return WorkspaceProductSubmissionWriteResult(WorkspaceProductSubmissionWriteState.submitted, submissionRecord(request));
    };
    expect((await next.retryOriginal()).state, WorkspaceProductSubmissionWriteState.submitted);
    expect(owner.submitted.last.fingerprint, original.fingerprint); expect(journal.pending, isNull);
  });
  for (final failure in ['save', 'input changed', 'cleanup']) {
    test('LF03-SUBMIT recovery preserves original on $failure interruption', () async {
      final owner = _ProductOwner(), journal = _ProductJournal(), controller = productController(owner, journal);
      addTearDown(controller.dispose); expect(await controller.refresh(), isTrue);
      var unchanged = true;
      if (failure == 'save') journal.failSave = true;
      if (failure == 'input changed') journal.beforeSave = () async { unchanged = false; };
      if (failure == 'cleanup') {
        journal.failRemove = true;
        owner.write = (request, _) async => WorkspaceProductSubmissionWriteResult(WorkspaceProductSubmissionWriteState.submitted, submissionRecord(request));
      }
      expect((await controller.submit(submissionIntent().input, inputCurrent: () => unchanged)).state, WorkspaceProductSubmissionWriteState.unknown);
      expect(controller.pending, isNotNull);
      if (failure == 'input changed') expect(controller.message, contains('details changed'));
      if (failure != 'cleanup') expect(owner.submitted, isEmpty);
      if (failure != 'save') expect(journal.pending!.fingerprint, controller.pending!.fingerprint);
    });
  }
  test('LF03-SUBMIT late old-lifetime reply cannot clear the durable original', () async {
    var lifetime = Object(); final owner = _ProductOwner(), journal = _ProductJournal();
    final controller = productController(owner, journal, context: () => lifetime); addTearDown(controller.dispose);
    expect(await controller.refresh(), isTrue);
    final entered = Completer<void>(), release = Completer<WorkspaceProductSubmissionWriteResult>();
    owner.write = (_, _) {entered.complete(); return release.future;};
    final attempt = controller.submit(submissionIntent().input, inputCurrent: () => true); await entered.future;
    final original = journal.pending!; lifetime = Object();
    release.complete(WorkspaceProductSubmissionWriteResult(WorkspaceProductSubmissionWriteState.submitted, submissionRecord(original)));
    expect((await attempt).state, WorkspaceProductSubmissionWriteState.unknown); expect(journal.pending!.fingerprint, original.fingerprint);
    final next = productController(owner, journal, context: () => lifetime); addTearDown(next.dispose);
    expect(await next.restore(), isTrue); expect(next.pending!.fingerprint, original.fingerprint);
  });
  test('LF03-SUBMIT head rollback and same-revision changed facts cannot enable another submit', () async {
    final owner = _ProductOwner(), journal = _ProductJournal(), controller = productController(owner, journal);
    addTearDown(controller.dispose); owner.head = submissionRecord(submissionIntent());
    expect(await controller.refresh(), isTrue);
    owner.head = null; expect(await controller.refresh(), isFalse); expect(controller.canSubmit, isFalse);
    final changed = WorkspaceProductSubmissionIntent(scope: submissionScope, expectedRevision: 0, idempotencyKey: 'changed',
      input: WorkspaceProductSubmissionInput.fromSaved(listingItem().copyWith(sellingPrice: 261)));
    owner.head = submissionRecord(changed); expect(await controller.refresh(), isFalse); expect(controller.canSubmit, isFalse);
  });
  test('LF03-SUBMIT secure original is isolated by account Store realm and SKU across journal instances', () async {
    TestWidgetsFlutterBinding.ensureInitialized(); FlutterSecureStorage.setMockInitialValues({});
    var account = submissionScope.account;
    SecureWorkProductSubmissionJournal fresh() => SecureWorkProductSubmissionJournal(currentAccount: () => account);
    final original = submissionIntent(); await fresh().savePending(original);
    expect((await fresh().readPending(submissionScope))!.fingerprint, original.fingerprint);
    final other = WorkspaceProductSubmissionIntent(scope: submissionScope, expectedRevision: 0, idempotencyKey: 'different-original', input: original.input);
    await expectLater(fresh().savePending(other), throwsFormatException); await expectLater(fresh().removePending(other), throwsFormatException);
    for (final scope in [
      (account: account, store: 'another-store', realm: 'evaluation', sku: 'sku-one'),
      (account: account, store: 'store-one', realm: 'production', sku: 'sku-one'),
      (account: account, store: 'store-one', realm: 'evaluation', sku: 'another-sku'),
    ]) { expect(await fresh().readPending(scope), isNull); }
    account = 'another-owner'; await expectLater(fresh().readPending(submissionScope), throwsA(isA<WorkGatewayException>()));
    account = submissionScope.account; await fresh().removePending(original); expect(await fresh().readPending(submissionScope), isNull);
  });
  test('LF03-SUBMIT secure native tail survives caller timeout before remove or subsequent reads', () async {
    final storage = _DelayedDetailsStorage(), original = submissionIntent();
    SecureWorkProductSubmissionJournal fresh() => SecureWorkProductSubmissionJournal(storage: storage, currentAccount: () => submissionScope.account);
    final first = fresh().savePending(original); await storage.entered.future;
    await expectLater(first.timeout(const Duration(milliseconds: 1)), throwsA(isA<TimeoutException>()));
    final remove = fresh().removePending(original); await Future<void>.delayed(Duration.zero); expect(storage.writes, 1);
    storage.release.complete(); await first; await remove;
    expect(storage.writes, 2); expect(await fresh().readPending(submissionScope), isNull);
  });
  test('LF03-SUBMIT session submits saved product once without mirror or altering Stock and ordinary Save', () async {
    final owner = _ProductOwner(), journal = _ProductJournal(), work = productSession(owner, journal); addTearDown(work.dispose);
    final before = work.workspaceCatalogueItems.single.toInventoryJson();
    owner.write = (original, _) async => WorkspaceProductSubmissionWriteResult(WorkspaceProductSubmissionWriteState.submitted, submissionRecord(original));
    expect(await work.submitWorkspaceProduct('sku-one', inputCurrent: () => true), isTrue, reason: work.errorMessage);
    expect(owner.submitted, hasLength(1)); expect(journal.pending, isNull);
    expect(work.workspaceCatalogueItems.single.toInventoryJson(), before); expect(work.workspaceOrders, isEmpty); expect(work.workspaceInvoices, isEmpty);
  });
  for (final fault in ['editor edit', 'saved edit', 'Store changed']) {
    test('LF03-SUBMIT session fences $fault before dispatch', () async {
      final owner = _ProductOwner(), journal = _ProductJournal(), work = productSession(owner, journal); addTearDown(work.dispose);
      owner.readHead = () async {
        if (fault == 'saved edit') work.workspaceCatalogueItems[0] = listingItem().copyWith(sellingPrice: 261);
        if (fault == 'Store changed') { work.activeWorkspace = const WorkWorkspace(id: 'other-store', name: 'Other', profileLabel: 'Grocery',
          profileId: 'retailer-grocery', area: 'Jaipur', verified: true); }
        return null;
      };
      expect(await work.submitWorkspaceProduct('sku-one', inputCurrent: () => fault != 'editor edit'), isFalse);
      expect(owner.submitted, isEmpty); expect(journal.pending, isNull);
    });
  }
  test('LF03-SUBMIT original recovery ignores changed or removed local product after Store loop', () async {
    final owner = _ProductOwner(), journal = _ProductJournal(), work = productSession(owner, journal); addTearDown(work.dispose);
    await work.submitWorkspaceProduct('sku-one', inputCurrent: () => true);
    final original = journal.pending!, first = work.workspaceProductSubmission('sku-one')!;
    final store = work.activeWorkspace!;
    work.activeWorkspace = const WorkWorkspace(id: 'other-store', name: 'Other', profileLabel: 'Grocery', profileId: 'retailer-grocery', area: 'Jaipur', verified: true);
    work.activeWorkspace = store; work.workspaceCatalogueItems.clear();
    final next = work.workspaceProductSubmission('sku-one')!; expect(next, isNot(same(first))); expect(next.active, isTrue);
    owner.write = (request, reconcile) async {
      expect(reconcile, isTrue); expect(request.fingerprint, original.fingerprint);
      return WorkspaceProductSubmissionWriteResult(WorkspaceProductSubmissionWriteState.submitted, submissionRecord(request));
    };
    expect(await work.checkWorkspaceProductSubmission('sku-one'), isTrue); expect(journal.pending, isNull); expect(owner.submitted, hasLength(1));
  });
  for (final scale in [1.0, 2.0]) {
    testWidgets('LF03-SUBMIT saved editor inline controls keep dirty edits private at $scale', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale; addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final owner = _ProductOwner(), journal = _ProductJournal(), work = productSession(owner, journal);
      const captureKey = Key('product-submission-host-root');
      await openListingEditor(tester, work, captureKey: captureKey, theme: MoolTheme.light());
      final check = find.byKey(const Key('work-product-review-check'));
      await tester.ensureVisible(check); await tester.pumpAndSettle(); await tester.tap(check); await tester.pumpAndSettle();
      final submit = find.byKey(const Key('work-product-review-submit'));
      await tester.ensureVisible(submit); await tester.pumpAndSettle();
      expect(tester.widget<TextButton>(submit).onPressed, isNotNull); expect(tester.getSize(submit).height, greaterThanOrEqualTo(48));
      expect(owner.submitted, isEmpty);
      final captureDirectory = Platform.environment['LF03_SUBMISSION_CAPTURE_DIR'];
      if (captureDirectory != null) {
        final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(captureKey));
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          try {
            final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
            await Directory(captureDirectory).create(recursive: true);
            final file = File('$captureDirectory/submission-editor-host-$scale.png');
            if (await file.exists()) { throw StateError('Preserve existing host capture.'); }
            await file.writeAsBytes(bytes.buffer.asUint8List());
          } finally { image.dispose(); }
        });
      }
      final title = find.byKey(const Key('work-product-title'));
      await tester.ensureVisible(title); await tester.pumpAndSettle(); await tester.enterText(title, 'Unsaved product'); await tester.pumpAndSettle();
      await tester.ensureVisible(submit); await tester.pumpAndSettle();
      expect(tester.widget<TextButton>(submit).onPressed, isNull); expect(owner.submitted, isEmpty); expect(tester.takeException(), isNull);
    });
  }
  for (final returnToOriginal in [false, true]) {
    testWidgets('LF03-SUBMIT stale saved editor cannot check another Store or returned generation $returnToOriginal', (tester) async {
      final owner = _ProductOwner(), journal = _ProductJournal(), work = productSession(owner, journal);
      await openListingEditor(tester, work);
      final check = find.byKey(const Key('work-product-review-check'));
      await tester.ensureVisible(check); await tester.pumpAndSettle();
      final oldAction = tester.widget<TextButton>(check).onPressed!;
      final originalStore = work.activeWorkspace!;
      work.activeWorkspace = const WorkWorkspace(id: 'other-store', name: 'Other', profileLabel: 'Grocery', profileId: 'retailer-grocery', area: 'Jaipur', verified: true);
      if (returnToOriginal) work.activeWorkspace = originalStore;
      // Exercise the already-captured gesture, not just a newly disabled button.
      oldAction(); await tester.pumpAndSettle();
      expect(owner.readScopes, isEmpty); expect(owner.submitted, isEmpty); expect(owner.reconciled, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }
  for (final action in ['submit', 'retry']) {
    for (final returnToOriginal in [false, true]) {
      testWidgets('LF03-SUBMIT stale saved editor fences captured $action gesture generation $returnToOriginal', (tester) async {
        final owner = _ProductOwner(), journal = _ProductJournal(), work = productSession(owner, journal);
        if (action == 'retry') {
          journal.pending = submissionIntent();
          owner.write = (_, _) async => const WorkspaceProductSubmissionWriteResult(WorkspaceProductSubmissionWriteState.notFound);
        }
        await openListingEditor(tester, work);
        final check = find.byKey(const Key('work-product-review-check'));
        await tester.ensureVisible(check); await tester.pumpAndSettle(); await tester.tap(check); await tester.pumpAndSettle();
        final button = find.byKey(Key('work-product-review-$action'));
        await tester.ensureVisible(button); await tester.pumpAndSettle();
        final oldAction = tester.widget<TextButton>(button).onPressed!;
        final reads = owner.readScopes.length, submitted = owner.submitted.length, reconciled = owner.reconciled.length, store = work.activeWorkspace!;
        work.activeWorkspace = const WorkWorkspace(id: 'other-store', name: 'Other', profileLabel: 'Grocery', profileId: 'retailer-grocery', area: 'Jaipur', verified: true);
        if (returnToOriginal) work.activeWorkspace = store;
        oldAction(); await tester.pumpAndSettle();
        expect(owner.readScopes.length, reads); expect(owner.submitted.length, submitted); expect(owner.reconciled.length, reconciled);
        expect(tester.takeException(), isNull);
      });
    }
  }
  const warrantyDetails = {'Warranty issuer': 'Host manufacturer', 'Warranty duration': '12 months',
    'Warranty start basis': 'From original invoice', 'Warranty coverage': 'Manufacturing faults',
    'Warranty exclusions': 'Accidental damage', 'Warranty service': 'Use the manufacturer service process',
    'Warranty contact': 'Public warranty support', 'Warranty reference': 'Warranty sheet PF07'};
  test('PF07 optional warranty prompts retain exact source copy, casing, saved identity and CSV', () {
    expect(WorkspaceProductContent.warrantyGuideLabels, warrantyDetails.keys);
    for (final label in warrantyDetails.keys) { expect(WorkspaceProductContent.guidedHintForLabel(label), isNot('Optional')); }
    final original = WorkspaceProductContent.parse({'specifications': 'warranty issuer: Older source\nCustom detail: Keep'});
    final content = original.withGuidedDetails(warrantyDetails);
    expect(content.specifications['warranty issuer'], warrantyDetails['Warranty issuer']);
    expect(content.specifications.containsKey('Warranty issuer'), isFalse); expect(content.specifications['Custom detail'], 'Keep');
    final item = listingItem().copyWith(content: content, categoryId: 'other');
    final restored = WorkspaceCatalogueItem.fromInventoryJson(jsonDecode(jsonEncode(item.toInventoryJson())));
    expect(restored.content.toJson(), content.toJson()); expect(restored.id, item.id); expect(restored.stockEntry!.toJson(), item.stockEntry!.toJson());
    expect(WorkspaceProductSubmissionInput.fromSaved(restored).toJson()['content']['specifications'],
      [for (final entry in content.specifications.entries) {'label': entry.key, 'value': entry.value}]);
    expect(restored.toBuyPublicProduct(storeName: '').purchaseProtection, isNull);
    final raw = {'title': item.title, 'brand': item.brand, 'variant': item.variant, 'pack': item.pack, 'canonicalId': item.canonicalId,
      'purchasePrice': '230', 'sellingPrice': '260', 'stock': '0', ...content.inputValues};
    String quoted(String value) => '"${value.replaceAll('"', '""')}"';
    for (final json in [false, true]) {
      final data = json ? jsonEncode([raw]) : '${raw.keys.map(quoted).join(',')}\n${raw.values.map(quoted).join(',')}';
      final row = WorkspaceProductImport.parse(data, json: json, catalogue: [item], owned: []).rows.single;
      expect(row.issue, isNull); expect(row.product!.content.specifications, content.specifications); expect(row.product!.publicListing, isFalse);
    }
    expect(const WorkspaceProductContent().withGuidedDetails({for (final label in warrantyDetails.keys) label: ' '}).isEmpty, isTrue);
    final cleared = content.withGuidedDetails({'Warranty issuer': ''});
    expect(cleared.specifications.containsKey('warranty issuer'), isFalse); expect(cleared.specifications['Custom detail'], 'Keep');
    final full = WorkspaceProductContent(specifications: {for (var index = 0; index < 30; index++) 'Field $index': 'Keep'});
    expect(() => full.withGuidedDetails({'Warranty issuer': 'Additional'}), throwsFormatException); expect(full.specifications.length, 30);
  });
  testWidgets('PF07 optional Warranty guide is offered without changing saved product', (tester) async {
    final work = productSession(_ProductOwner(), _ProductJournal());
    work.workspaceCatalogueItems[0] = listingItem().copyWith(categoryId: 'other');
    final before = work.workspaceCatalogueItems.single.toInventoryJson();
    await openListingEditor(tester, work, theme: MoolTheme.light());
    final section = find.byKey(const Key('work-product-customer-facts-section'));
    await tester.ensureVisible(section); await tester.tap(section); await tester.pumpAndSettle();
    final guide = find.byKey(const Key('work-product-guided-details'));
    await tester.ensureVisible(guide); await tester.tap(guide); await tester.pumpAndSettle();
    expect(find.text('Saved details stay in Specifications. Choose Electronics or Appliances for guided fields.'), findsNothing);
    await tester.tap(find.byKey(const Key('work-product-detail-guide'))); await tester.pumpAndSettle();
    expect(find.text('Warranty'), findsOneWidget);
    expect(work.workspaceCatalogueItems.single.toInventoryJson(), before);
  });
  for (final apply in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('PF07 warranty guide switching and ${apply ? 'Apply' : 'Cancel'} at $scale', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale; addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final work = productSession(_ProductOwner(), _ProductJournal());
        work.workspaceCatalogueItems[0] = listingItem().copyWith(categoryId: 'other');
        final before = work.workspaceCatalogueItems.single.toInventoryJson();
        await openListingEditor(tester, work, theme: MoolTheme.light());
        Future<void> show(Finder finder) async {
          FocusManager.instance.primaryFocus?.unfocus(); await tester.pumpAndSettle();
          await Scrollable.ensureVisible(tester.element(finder), alignment: .15); await tester.pumpAndSettle();
        }
        final section = find.byKey(const Key('work-product-customer-facts-section'));
        await show(section); await tester.tap(section); await tester.pumpAndSettle();
        final guide = find.byKey(const Key('work-product-guided-details'));
        await show(guide); await tester.tap(guide); await tester.pumpAndSettle();
        Future<void> choose(String label) async {
          final choice = find.byKey(const Key('work-product-detail-guide'));
          await show(choice); await tester.tap(choice); await tester.pumpAndSettle();
          await tester.tap(find.text(label).last); await tester.pumpAndSettle();
        }
        await choose('Warranty');
        expect(find.textContaining('manufacturer or seller warranty'), findsOneWidget);
        for (final entry in warrantyDetails.entries) {
          final field = find.byKey(Key('work-product-guided-${entry.key}'));
          await show(field); await tester.enterText(field, entry.value); await tester.pumpAndSettle();
        }
        await choose('Electronics');
        final model = find.byKey(const Key('work-product-guided-Model code'));
        await show(model); await tester.enterText(model, 'Host model'); await tester.pumpAndSettle();
        await choose('Warranty');
        expect(tester.widget<TextField>(find.byKey(const Key('work-product-guided-Warranty issuer'))).controller!.text, warrantyDetails['Warranty issuer']);
        final action = find.byKey(Key('work-product-guided-${apply ? 'apply' : 'cancel'}'));
        await show(action); await tester.tap(action); await tester.pumpAndSettle();
        final text = tester.widget<TextField>(find.byKey(const Key('work-product-specifications'))).controller!.text;
        final content = WorkspaceProductContent.parse({'specifications': text});
        if (apply) {
          for (final entry in warrantyDetails.entries) { expect(content.specifications[entry.key], entry.value); }
          expect(content.specifications['Model code'], 'Host model');
        } else { expect(content.specifications, listingItem().content.specifications); }
        expect(work.workspaceCatalogueItems.single.toInventoryJson(), before); expect(tester.takeException(), isNull);
      });
    }
  }
  const familyScope = (account: 'owner-one', store: 'store-one', realm: 'production', family: 'family-one');
  WorkspaceVariantFamilySubmissionInput ownerFamilyInput() => WorkspaceVariantFamilySubmissionInput.fromJson({
    'familyId': familyScope.family, 'localRevision': 1, 'title': 'Host option product', 'brand': 'Host fixture',
    'categoryId': 'electronics', 'options': [for (final colour in ['pink', 'blue']) {
      'dimensionId': 'colour', 'dimensionLabel': 'Colour', 'optionId': colour, 'optionLabel': colour,
      'kind': 'colour', 'swatchArgb': null}], 'members': [
      {'skuId': 'sku-one', 'skuRevision': 1, 'selections': {'colour': 'pink'}},
      {'skuId': 'sku-two', 'skuRevision': 1, 'selections': {'colour': 'blue'}}]});
  WorkspaceVariantFamilyIntent familyIntent({WorkspaceVariantFamilyScope scope = familyScope, int expectedRevision = 0}) =>
    WorkspaceVariantFamilyIntent(scope: scope, expectedRevision: expectedRevision, idempotencyKey: 'family-original-request', input: ownerFamilyInput());
  Map<String, Object?> familyCandidateData(WorkspaceVariantFamilyIntent original) => {'schemaVersion': 1,
    'realm': original.scope.realm, 'storeId': original.scope.store, 'revision': original.expectedRevision + 1,
    'submittedAt': at.toIso8601String(), 'submittedBy': original.scope.account, 'fingerprint': original.candidateFingerprint,
    'family': original.input.toJson()};
  WorkspaceVariantFamilyCandidate familyCandidate(WorkspaceVariantFamilyIntent original) =>
    WorkspaceVariantFamilyCandidate.decode(jsonDecode(jsonEncode(familyCandidateData(original))), original.scope, at);
  WorkspaceVariantFamilyController familyController(_FamilyOwner owner, _FamilyJournal journal, {Object? Function()? context}) =>
    WorkspaceVariantFamilyController(scope: familyScope, gateway: owner, journal: journal, context: context ?? () => 'host-owner', now: () => at);
  test('LF03 OWNER-FAMILY freezes exact input and rejects extra combinations and private fields', () {
    final original = familyIntent(), data = original.toJson(), family = data['family'] as Map;
    ((family['members'] as List).first['selections'] as Map)['colour'] = 'green';
    expect((original.input.toJson()['members'] as List).first['selections']['colour'], 'pink');
    expect(() => WorkspaceVariantFamilyIntent.fromJson(jsonDecode(jsonEncode(data))), throwsFormatException);
    expect(() => WorkspaceVariantFamilySubmissionInput.fromJson({...ownerFamilyInput().toJson(), 'stock': 10}), throwsFormatException);
    final duplicate = ownerFamilyInput().toJson();
    ((duplicate['members'] as List).last as Map)['selections'] = {'colour': 'pink'};
    expect(() => WorkspaceVariantFamilySubmissionInput.fromJson(duplicate), throwsFormatException);
    expect(WorkspaceVariantFamilyIntent.fromJson(jsonDecode(jsonEncode(original.toJson()))).candidateFingerprint,
      original.candidateFingerprint);
  });
  test('LF03 OWNER-FAMILY journal precedes send, receipt is submission not approval', () async {
    final owner = _FamilyOwner(), journal = _FamilyJournal(), controller = familyController(owner, journal);
    addTearDown(controller.dispose);
    owner.write = (original, _) async {
      expect(journal.pending!.fingerprint, original.fingerprint);
      return WorkspaceVariantFamilyWriteResult(WorkspaceVariantFamilyWriteState.submitted, familyCandidate(original));
    };
    expect(await controller.refresh(), isTrue);
    expect(owner.submitted, isEmpty); expect(controller.canSubmit, isTrue);
    expect((await controller.submit(ownerFamilyInput(), inputCurrent: () => true)).state, WorkspaceVariantFamilyWriteState.submitted);
    expect(journal.pending, isNull); expect(owner.submitted.length, 1); expect(controller.headLoaded, isFalse);
    expect(controller.message, contains('not approval'));
  });
  test('LF03 OWNER-FAMILY uncertain result survives restart; only exact original may reconcile or retry', () async {
    final owner = _FamilyOwner(), journal = _FamilyJournal(), first = familyController(owner, journal);
    expect(await first.refresh(), isTrue);
    expect((await first.submit(ownerFamilyInput(), inputCurrent: () => true)).state, WorkspaceVariantFamilyWriteState.unknown);
    final original = journal.pending!; first.dispose();
    final next = familyController(owner, journal); addTearDown(next.dispose);
    expect(await next.restore(), isTrue); expect(next.canSubmit, isFalse); expect(owner.submitted.length, 1);
    owner.write = (_, _) async => const WorkspaceVariantFamilyWriteResult(WorkspaceVariantFamilyWriteState.notFound);
    await next.reconcile(); expect(next.canRetryOriginal, isTrue); expect(journal.pending!.fingerprint, original.fingerprint);
    owner.write = (request, _) async => WorkspaceVariantFamilyWriteResult(WorkspaceVariantFamilyWriteState.submitted, familyCandidate(request));
    expect((await next.retryOriginal()).state, WorkspaceVariantFamilyWriteState.submitted);
    expect(owner.submitted.last.fingerprint, original.fingerprint);
    expect(owner.reconciled.single.fingerprint, original.fingerprint); expect(journal.pending, isNull);
  });
  test('LF03 OWNER-FAMILY failed journal blocks dispatch and keeps original input', () async {
    final owner = _FamilyOwner(), journal = _FamilyJournal()..failSave = true, controller = familyController(owner, journal);
    addTearDown(controller.dispose); expect(await controller.refresh(), isTrue);
    expect((await controller.submit(ownerFamilyInput(), inputCurrent: () => true)).state, WorkspaceVariantFamilyWriteState.unknown);
    expect(owner.submitted, isEmpty); expect(controller.pending, isNotNull); expect(controller.canSubmit, isFalse);
    journal.failSave = false; expect(await controller.restore(), isTrue); expect(controller.pending, isNotNull);
  });
  test('LF03 OWNER-FAMILY saved-input change during journal write never sends current or old unreviewed values', () async {
    var unchanged = true;
    final owner = _FamilyOwner(), journal = _FamilyJournal()..beforeSave = (() async { unchanged = false; });
    final controller = familyController(owner, journal); addTearDown(controller.dispose);
    expect(await controller.refresh(), isTrue);
    await controller.submit(ownerFamilyInput(), inputCurrent: () => unchanged);
    expect(owner.submitted, isEmpty); expect(journal.pending, isNotNull); expect(controller.canSubmit, isFalse);
  });
  test('LF03 OWNER-FAMILY failed receipt cleanup keeps recovery and blocks a fresh submission', () async {
    final owner = _FamilyOwner(), journal = _FamilyJournal()..failRemove = true, controller = familyController(owner, journal);
    addTearDown(controller.dispose); expect(await controller.refresh(), isTrue);
    owner.write = (request, _) async => WorkspaceVariantFamilyWriteResult(WorkspaceVariantFamilyWriteState.submitted, familyCandidate(request));
    expect((await controller.submit(ownerFamilyInput(), inputCurrent: () => true)).state, WorkspaceVariantFamilyWriteState.unknown);
    expect(controller.pending, isNotNull); expect(journal.pending, isNotNull); expect(controller.canSubmit, isFalse);
    journal.failRemove = false;
    expect((await controller.reconcile()).state, WorkspaceVariantFamilyWriteState.submitted);
    expect(journal.pending, isNull); expect(owner.submitted.length, 1);
  });
  test('LF03 OWNER-FAMILY wrong-owner or mutated acknowledgements retain the original', () async {
    final owner = _FamilyOwner(), journal = _FamilyJournal(), controller = familyController(owner, journal);
    addTearDown(controller.dispose); expect(await controller.refresh(), isTrue);
    owner.write = (request, _) async => WorkspaceVariantFamilyWriteResult(WorkspaceVariantFamilyWriteState.submitted,
      familyCandidate(familyIntent(scope: (account: 'other-owner', store: familyScope.store, realm: familyScope.realm, family: familyScope.family))));
    expect((await controller.submit(ownerFamilyInput(), inputCurrent: () => true)).state, WorkspaceVariantFamilyWriteState.unknown);
    expect(journal.pending, isNotNull); expect(controller.pending, isNotNull);
  });
  test('LF03 OWNER-FAMILY retired account cannot admit a delayed status or acknowledgement', () async {
    Object? lifetime = 'owner-before';
    final owner = _FamilyOwner(), journal = _FamilyJournal(), controller = familyController(owner, journal, context: () => lifetime);
    addTearDown(controller.dispose);
    final reply = Completer<WorkspaceVariantFamilyHead>(); owner.read = () => reply.future;
    final read = controller.refresh(); await Future<void>.delayed(Duration.zero); lifetime = 'owner-after';
    reply.complete(owner.head); expect(await read, isFalse); expect(controller.headLoaded, isFalse);
    expect(owner.submitted, isEmpty);
  });
  Map<String, Object?> ownerFamilyAck(WorkspaceVariantFamilyIntent original, {bool absent = false}) => {
    'schemaVersion': 1, 'realm': original.scope.realm, 'storeId': original.scope.store, 'familyId': original.scope.family,
    'orderingAvailable': false, 'state': absent ? 'not_found' : 'submitted',
    'candidate': absent ? null : familyCandidateData(original), 'approved': false};
  Map<String, Object?> ownerFamilyHead({WorkspaceVariantFamilyIntent? candidate, Map<String, Object?>? review}) => {
    'schemaVersion': 1, 'realm': familyScope.realm, 'storeId': familyScope.store, 'familyId': familyScope.family,
    'orderingAvailable': false, 'candidate': candidate == null ? null : familyCandidateData(candidate), 'review': review};
  AuthenticatedWorkspaceCatalogueGateway familyOwnerConnection(OwnerTransport transport, {Credentials? credentials}) =>
    AuthenticatedWorkspaceCatalogueGateway(endpoint: Uri.parse(
      'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'), credentials: credentials ?? Credentials(),
      transport: transport, ownerAccountId: familyScope.account, now: () => at, reviewedFamilyReadbackSupported: true);
  test('LF03 OWNER-FAMILY endpoint preserves exact original and mutation-only AppCheck', () async {
    final original = familyIntent(), credentials = Credentials(), requests = <Map<String, Object?>>[];
    final source = familyOwnerConnection(OwnerTransport((body) async {
      requests.add(body);
      return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data':
        body['operation'] == 'readStoreVariantFamily' ? ownerFamilyHead() : ownerFamilyAck(original)}));
    }), credentials: credentials);
    expect((await source.readVariantFamily(familyScope, current: () => true)).candidate, isNull);
    expect((await source.writeVariantFamily(original, current: () => true)).state, WorkspaceVariantFamilyWriteState.submitted);
    expect((await source.writeVariantFamily(original, current: () => true, reconcile: true)).state, WorkspaceVariantFamilyWriteState.submitted);
    expect(credentials.modes, [SocialAppCheckTokenMode.standard, SocialAppCheckTokenMode.limitedUse, SocialAppCheckTokenMode.standard]);
    expect(requests.map((r) => r['operation']), ['readStoreVariantFamily', 'submitStoreVariantFamily', 'reconcileStoreVariantFamily']);
    for (final request in requests.skip(1)) {
      final body = Map<String, Object?>.of(request)..remove('operation'); expect(body, original.body);
      expect(body.containsKey('approved'), isFalse); expect(body.containsKey('actor'), isFalse);
    }
    expect((await source.forOwnerAccount('other-owner').writeVariantFamily(original, current: () => true)).state,
      WorkspaceVariantFamilyWriteState.notSent);
    expect((await source.writeVariantFamily(original, current: () => false)).state, WorkspaceVariantFamilyWriteState.notSent);
    expect(requests.length, 3);
  });
  for (final corrupt in ['Store', 'family', 'realm', 'owner', 'revision', 'hash', 'timestamp', 'approval', 'payload']) {
    test('LF03 OWNER-FAMILY endpoint retains uncertainty for wrong $corrupt acknowledgement', () async {
      final original = familyIntent(), data = ownerFamilyAck(familyIntent());
      final candidate = data['candidate'] as Map;
      if (corrupt == 'Store') data['storeId'] = 'store-other';
      if (corrupt == 'family') data['familyId'] = 'family-other';
      if (corrupt == 'realm') data['realm'] = 'evaluation';
      if (corrupt == 'owner') candidate['submittedBy'] = 'owner-other';
      if (corrupt == 'revision') candidate['revision'] = 2;
      if (corrupt == 'hash') candidate['fingerprint'] = '0' * 64;
      if (corrupt == 'timestamp') candidate['submittedAt'] = [at.toIso8601String()];
      if (corrupt == 'approval') data['approved'] = true;
      if (corrupt == 'payload') (candidate['family'] as Map)['title'] = 'Changed';
      final source = familyOwnerConnection(OwnerTransport((_) async => SocialContentResponse(statusCode: 200,
        body: jsonEncode({'ok': true, 'data': data}))));
      expect((await source.writeVariantFamily(original, current: () => true)).state, WorkspaceVariantFamilyWriteState.unknown);
    });
  }
  test('LF03 OWNER-FAMILY not-found permits only original reconciliation, not submit success', () async {
    final original = familyIntent();
    final source = familyOwnerConnection(OwnerTransport((_) async => SocialContentResponse(statusCode: 200,
      body: jsonEncode({'ok': true, 'data': ownerFamilyAck(original, absent: true)}))));
    expect((await source.writeVariantFamily(original, current: () => true, reconcile: true)).state, WorkspaceVariantFamilyWriteState.notFound);
    expect((await source.writeVariantFamily(original, current: () => true)).state, WorkspaceVariantFamilyWriteState.unknown);
  });
  test('LF03 OWNER-FAMILY older trusted approval is distinct from newer submitted changes', () async {
    final reviewed = familyIntent(), next = familyIntent(expectedRevision: 1);
    final data = ownerFamilyHead(candidate: next, review: {'schemaVersion': 1, 'revision': 1,
      'decision': 'verify', 'reviewerUserId': 'reviewer-one', 'reviewedAt': at.toIso8601String(),
      'reasonCode': 'checked-source', 'catalogueId': 'catalogue-one', 'tenantId': 'tenant-one', 'candidate': familyCandidateData(reviewed)});
    final head = WorkspaceVariantFamilyHead.decode(jsonDecode(jsonEncode(data)), familyScope, at);
    final source = _FamilyOwner()..head = head, controller = familyController(source, _FamilyJournal());
    addTearDown(controller.dispose); expect(await controller.refresh(), isTrue);
    expect(controller.message, contains('waiting for review')); expect(controller.message, isNot(contains('approved')));
    source.head = WorkspaceVariantFamilyHead.decode(jsonDecode(jsonEncode(ownerFamilyHead(candidate: reviewed))), familyScope, at);
    expect(await controller.refresh(), isFalse); expect(controller.head!.candidate!.revision, 2);
  });
  test('LF03 OWNER-FAMILY does not create repeated submissions for unchanged saved combinations', () async {
    final original = familyIntent(), owner = _FamilyOwner()..head = WorkspaceVariantFamilyHead.decode(
      jsonDecode(jsonEncode(ownerFamilyHead(candidate: familyIntent()))), familyScope, at);
    final journal = _FamilyJournal(), controller = familyController(owner, journal); addTearDown(controller.dispose);
    expect(await controller.refresh(), isTrue);
    expect((await controller.submit(original.input, inputCurrent: () => true)).state, WorkspaceVariantFamilyWriteState.notSent);
    expect(owner.submitted, isEmpty); expect(journal.saves, 0);
  });
  test('LF03 OWNER-FAMILY secure journal restarts with account Store realm family and original isolated', () async {
    TestWidgetsFlutterBinding.ensureInitialized(); FlutterSecureStorage.setMockInitialValues({});
    var account = familyScope.account;
    SecureWorkVariantFamilyJournal fresh() => SecureWorkVariantFamilyJournal(currentAccount: () => account);
    final original = familyIntent(); await fresh().savePending(original);
    expect((await fresh().readPending(familyScope))!.fingerprint, original.fingerprint);
    final other = WorkspaceVariantFamilyIntent.fromJson(jsonDecode(jsonEncode(original.toJson()..['idempotencyKey'] = 'different-request')));
    await expectLater(fresh().savePending(other), throwsFormatException);
    await expectLater(fresh().removePending(other), throwsFormatException);
    for (final scope in [
      (account: account, store: 'store-other', realm: 'production', family: 'family-one'),
      (account: account, store: 'store-one', realm: 'evaluation', family: 'family-one'),
      (account: account, store: 'store-one', realm: 'production', family: 'family-other'),
    ]) { expect(await fresh().readPending(scope), isNull); }
    account = 'owner-other'; await expectLater(fresh().readPending(familyScope), throwsA(isA<WorkGatewayException>()));
    account = familyScope.account; await fresh().removePending(original); expect(await fresh().readPending(familyScope), isNull);
  });
  test('LF03 OWNER-FAMILY journal native tails survive caller timeout across instances', () async {
    final storage = _DelayedDetailsStorage(), original = familyIntent();
    SecureWorkVariantFamilyJournal fresh() => SecureWorkVariantFamilyJournal(storage: storage, currentAccount: () => familyScope.account);
    final first = fresh().savePending(original); await storage.entered.future;
    await expectLater(first.timeout(const Duration(milliseconds: 1)), throwsA(isA<TimeoutException>()));
    final remove = fresh().removePending(original);
    await Future<void>.delayed(Duration.zero); expect(storage.writes, 1);
    storage.release.complete(); await first; await remove;
    expect(storage.writes, 2); expect(await fresh().readPending(familyScope), isNull);
  });
  WorkSession ownerFamilySession(_SessionFamilyCatalogue source, _FamilyJournal journal, {ListingAccount? account}) {
    final work = WorkSession(contactDraftStore: account ?? ListingAccount(), catalogueGateway: source,
      catalogueBindingPendingStoreFactory: (_) => BindingStore(), variantFamilyJournalFactory: (_) => journal)
      ..activeWorkspace = const WorkWorkspace(id: 'store-one', name: 'Host Store', profileLabel: 'Grocery',
        profileId: 'retailer-grocery', area: 'Jaipur', verified: true)
      ..workspaceId = 'store-one';
    final base = listingItem();
    final family = WorkspaceVariantFamily(id: 'family-one', revision: 1, title: base.title, brand: base.brand,
      categoryId: base.categoryId, content: base.content, options: [for (final variety in ['sunflower', 'olive'])
        BuyV2VariantAttribute(dimensionId: 'variety', dimensionLabel: 'Variety', optionId: variety,
          optionLabel: variety, kind: BuyV2VariantDimensionKind.other)]);
    for (final second in [false, true]) {
      final skuId = second ? 'sku-two' : 'sku-one';
      final item = WorkspaceCatalogueItem.fromInventoryJson({...base.toInventoryJson(), 'id': skuId,
        'canonicalId': second ? 'canonical-two' : 'canonical-one', 'sku': second ? 'HOST-TWO' : 'HOST-ONE',
        'variant': second ? 'Olive' : 'Sunflower',
        'stockEntry': {...base.stockEntry!.toJson(), 'productId': skuId, 'sku': second ? 'HOST-TWO' : 'HOST-ONE'}})
        .copyWith(variantMembership: WorkspaceVariantMembership(familyId: family.id,
          selections: {'variety': second ? 'olive' : 'sunflower'}));
      expect(work.addOrUpdateWorkspaceProduct(item, variantFamily: family,
        stockEntryMethod: WorkspaceStockEntryMethod.manual), isTrue);
      final row = ownerRow(listed: true)
        ..['skuId'] = skuId ..['canonicalProductId'] = item.canonicalId ..['sku'] = item.sku
        ..['verifiedPackId'] = second ? 'pack-two' : 'pack-one';
      (row['content'] as Map)['variant'] = item.variant;
      (row['provenance'] as Map)['sourceRecordId'] = skuId;
      source.rows[skuId] = WorkspaceCatalogueOwnedSku.decode(row, storeId: 'store-one', skuId: skuId, realm: 'production', now: at);
    }
    return work;
  }
  test('LF03 OWNER-FAMILY session submits all saved exact members without changing Stock or invoices', () async {
    final source = _SessionFamilyCatalogue(), journal = _FamilyJournal(), work = ownerFamilySession(source, journal);
    addTearDown(work.dispose);
    final before = work.workspaceCatalogueItems.map((p) => p.toInventoryJson()).toList();
    source.family.write = (original, _) async => WorkspaceVariantFamilyWriteResult(WorkspaceVariantFamilyWriteState.submitted, familyCandidate(original));
    expect(await work.checkWorkspaceVariantFamily('family-one'), isTrue);
    expect(await work.submitWorkspaceVariantFamily('family-one', inputCurrent: () => true), isTrue, reason: work.errorMessage);
    final sent = source.family.submitted.single.input.toJson();
    expect((sent['members'] as List).map((m) => m['skuId']).toSet(), {'sku-one', 'sku-two'});
    expect(sent.containsKey('stock'), isFalse); expect(sent.containsKey('purchasePrice'), isFalse);
    expect(work.workspaceCatalogueItems.map((p) => p.toInventoryJson()).toList(), before);
    expect(work.workspaceInvoices, isEmpty); expect(work.workspaceOrders, isEmpty); expect(journal.pending, isNull);
  });
  test('LF03 OWNER-FAMILY Store loop restores original under a fresh lifetime and rejects retired reply', () async {
    final source = _SessionFamilyCatalogue(), journal = _FamilyJournal()..pending = familyIntent();
    final work = ownerFamilySession(source, journal); addTearDown(work.dispose);
    final first = work.workspaceVariantFamilyPublisher('family-one')!; expect(await first.restore(), isTrue);
    final original = journal.pending!, delayed = Completer<WorkspaceVariantFamilyWriteResult>();
    addTearDown(() { if (!delayed.isCompleted) delayed.complete(const WorkspaceVariantFamilyWriteResult(WorkspaceVariantFamilyWriteState.unknown)); });
    source.family.write = (_, _) => delayed.future;
    final old = work.checkWorkspaceVariantFamily('family-one', original: true); await Future<void>.delayed(Duration.zero);
    final store = work.activeWorkspace!;
    work.activeWorkspace = const WorkWorkspace(id: 'store-two', name: 'Other host Store', profileLabel: 'Grocery',
      profileId: 'retailer-grocery', area: 'Jaipur', verified: true);
    work.activeWorkspace = store;
    final next = work.workspaceVariantFamilyPublisher('family-one')!;
    expect(next, isNot(same(first))); expect(next.active, isTrue); expect(first.active, isFalse);
    source.family.write = (request, _) async => WorkspaceVariantFamilyWriteResult(WorkspaceVariantFamilyWriteState.submitted, familyCandidate(request));
    expect(await work.checkWorkspaceVariantFamily('family-one', original: true), isTrue);
    expect(next.pending, isNull); expect(journal.pending, isNull);
    delayed.complete(WorkspaceVariantFamilyWriteResult(WorkspaceVariantFamilyWriteState.submitted, familyCandidate(original)));
    expect(await old, isFalse); expect(next.pending, isNull); expect(source.family.submitted, isEmpty);
  });
  test('LF03 OWNER-FAMILY retired preparation cannot clear successor busy marker after Store loop', () async {
    final source = _SessionFamilyCatalogue(), journal = _FamilyJournal(), work = ownerFamilySession(source, journal);
    addTearDown(work.dispose); expect(await work.checkWorkspaceVariantFamily('family-one'), isTrue);
    final oldEntered = Completer<void>(), nextEntered = Completer<void>(), oldRelease = Completer<void>(), nextRelease = Completer<void>();
    addTearDown(() { if (!oldRelease.isCompleted) oldRelease.complete(); if (!nextRelease.isCompleted) nextRelease.complete(); });
    var phase = 0;
    source.beforeRead = (_) async {
      if (phase == 0) { if (!oldEntered.isCompleted) oldEntered.complete(); await oldRelease.future; }
      else { if (!nextEntered.isCompleted) nextEntered.complete(); await nextRelease.future; }
    };
    final old = work.submitWorkspaceVariantFamily('family-one', inputCurrent: () => true); await oldEntered.future;
    final store = work.activeWorkspace!;
    work.activeWorkspace = const WorkWorkspace(id: 'store-two', name: 'Other host Store', profileLabel: 'Grocery',
      profileId: 'retailer-grocery', area: 'Jaipur', verified: true);
    work.activeWorkspace = store;
    expect(await work.checkWorkspaceVariantFamily('family-one'), isTrue);
    phase = 1;
    source.family.write = (request, _) async => WorkspaceVariantFamilyWriteResult(WorkspaceVariantFamilyWriteState.submitted, familyCandidate(request));
    final next = work.submitWorkspaceVariantFamily('family-one', inputCurrent: () => true); await nextEntered.future;
    oldRelease.complete(); expect(await old, isFalse);
    expect(work.workspaceVariantFamilyBusy('family-one'), isTrue);
    nextRelease.complete(); expect(await next, isTrue);
    expect(source.family.submitted.length, 1); expect(work.workspaceVariantFamilyBusy('family-one'), isFalse);
  });
  for (final fault in ['missing mirror', 'changed price', 'unsaved editor', 'retired owner', 'changed saved group']) {
    test('LF03 OWNER-FAMILY session blocks $fault before any submission', () async {
      final source = _SessionFamilyCatalogue(), journal = _FamilyJournal(), account = ListingAccount();
      final work = ownerFamilySession(source, journal, account: account); addTearDown(work.dispose);
      expect(await work.checkWorkspaceVariantFamily('family-one'), isTrue);
      if (fault == 'missing mirror') source.rows.remove('sku-two');
      if (fault == 'changed price') work.workspaceCatalogueItems[1] = work.workspaceCatalogueItems[1].copyWith(sellingPrice: 261);
      if (fault == 'retired owner') {
        source.beforeRead = (_) async { account.owner = 'other-owner'; };
      }
      if (fault == 'changed saved group') {
        source.beforeRead = (_) async {
          work.workspaceCatalogueItems[1] = work.workspaceCatalogueItems[1].copyWith(sellingPrice: 261);
        };
      }
      expect(await work.submitWorkspaceVariantFamily('family-one', inputCurrent: () => fault != 'unsaved editor'), isFalse);
      expect(source.family.submitted, isEmpty); expect(journal.pending, isNull);
    });
  }
  for (final scale in [1.0, 2.0]) {
    testWidgets('LF03 OWNER-FAMILY saved editor inline status and dirty guard at $scale', (tester) async {
      tester.view.devicePixelRatio = 1; tester.view.physicalSize = const Size(360, 844);
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.reset); addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final source = _SessionFamilyCatalogue(), journal = _FamilyJournal(), work = ownerFamilySession(source, journal);
      await openListingEditor(tester, work);
      final check = find.byKey(const Key('work-product-family-check-status'));
      await tester.ensureVisible(check); await tester.pumpAndSettle(); await tester.tap(check); await tester.pumpAndSettle();
      final submit = find.byKey(const Key('work-product-family-submit'));
      await tester.ensureVisible(submit); await tester.pumpAndSettle();
      expect(tester.widget<TextButton>(submit).onPressed, isNotNull); expect(source.family.submitted, isEmpty);
      expect(tester.getSize(submit).height, greaterThanOrEqualTo(48));
      final title = find.byKey(const Key('work-product-title'));
      await tester.ensureVisible(title); await tester.pumpAndSettle(); await tester.enterText(title, 'Unsaved host edit');
      await tester.pumpAndSettle(); await tester.ensureVisible(submit); await tester.pumpAndSettle();
      expect(tester.widget<TextButton>(submit).onPressed, isNull); expect(source.family.submitted, isEmpty);
      expect(find.text('Save current product changes before submitting the group.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  TestWidgetsFlutterBinding.ensureInitialized();
  Map<String, dynamic> policyEnvelope({
    int revision = 1,
    String state = 'ready',
    String body = 'Host supplier terms',
  }) => {
    'schemaVersion': 1,
    'realm': 'production',
    'storeId': 'store-one',
    'skuId': 'sku-one',
    'observedAt': at.toIso8601String(),
    'state': state,
    'revision': revision,
    'requiresAcceptance': state == 'none' ? false : true,
    'policy': state == 'ready'
        ? {
            'id': 'host-supplier-policy-sku-one',
            'storeId': 'store-one',
            'revision': 'policy-v$revision',
            'title': 'Host supplier policy',
            'body': body,
            'productIds': ['sku-one'],
            'requiresAcceptance': true,
            'validUntil': at.add(const Duration(hours: 1)).toIso8601String(),
          }
        : null,
  };
  // Isolated server-response identities, never native/provider publication data.
  BuyV2PublicListingIdentity publicIdentity({BuyV2OfferClass channel = BuyV2OfferClass.retail}) =>
    BuyV2PublicListingIdentity(listingId: 'listing-${(channel == BuyV2OfferClass.retail ? 'a' : 'b') * 64}',
      realm: 'production', storeId: 'store-one', skuId: 'sku-one', canonicalProductId: 'canonical-one',
      verifiedPackId: 'pack-one', channel: channel);
  BuyV2Product publicProduct({bool trade = false}) {
    final identity = publicIdentity(channel: trade ? BuyV2OfferClass.wholesale : BuyV2OfferClass.retail);
    return BuyV2Product(id: identity.listingId, canonicalId: product.canonicalId, storeId: product.storeId,
      publicListingIdentity: identity, destination: trade ? BuyV2Destination.wholesale : BuyV2Destination.shop,
      categoryId: product.categoryId, brand: product.brand, title: product.title, variant: product.variant,
      pack: product.pack, price: trade ? 250 : 260, mrp: 280, unitPrice: '', badge: '', seller: product.seller,
      sellerType: product.sellerType, deliveryPromise: '', origin: '', confirmedOn: '', visualLabel: '', visualKind: '',
      minimumOrder: trade ? 10 : 1, offerClass: identity.channel);
  }
  Map<String, dynamic> publicPage({bool trade = false}) {
    final data = jsonDecode(jsonEncode(page())) as Map<String, dynamic>;
    data['listingReadbackVersion'] = 1; data['listingCoverage'] = 'complete';
    data['mediaReadbackVersion'] = 1;
    data['publicStore'] = {'id': 'store-one', 'name': 'Host Store', 'profileId': 'retailer-grocery'};
    row(data)['listings'] = [publicIdentity().toJson(), if (trade) publicIdentity(channel: BuyV2OfferClass.wholesale).toJson()];
    if (trade) { (row(data)['channels'] as List).add(<String, Object?>{
      ...(row(data)['channels'] as List).first as Map<String, dynamic>,
      'kind': 'wholesale', 'priceMinor': 25000, 'minimumOrder': 10, 'offerId': 'host-trade-offer'}); }
    row(data)['supplierPolicy'] = policyEnvelope();
    return data;
  }
  AuthenticatedWorkspaceCatalogueGateway discoveryGateway(SocialContentTransport transport, {String realm = 'production', bool promotions = false, bool advertisedTerms = false}) =>
    AuthenticatedWorkspaceCatalogueGateway(endpoint: Uri.parse('https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
      credentials: Credentials(), transport: transport, realm: realm, productFactsReadbackSupported: true,
      unbrandedProduceReadbackSupported: true, storeClassificationReadbackSupported: true, promotionDiscoverySupported: promotions,
      promotionTermsSupported: advertisedTerms, now: () => at);
  Map<String, dynamic> discoveryData(Map<String, Object?> body, {bool empty = false}) {
    final listing = publicPage();
    listing.addAll({'productFactsReadbackVersion': 1, 'storeClassificationReadbackVersion': 1, 'storeDetailsReadbackVersion': 1});
    listing['publicStore'] = <String, dynamic>{...listing['publicStore'] as Map, 'details': {'schemaVersion': 1, 'realm': 'production', 'storeId': 'store-one',
      'observedAt': at.toIso8601String(), 'state': 'none', 'revision': 0, 'details': null, 'area': null,
      'locationVerified': false, 'publicAvailabilityConfirmed': false}};
    ((row(listing)['channels'] as List).single as Map)['priceMinor'] = 10025;
    return {'schemaVersion': 1, 'discoveryPageVersion': 1, 'realm': 'production', 'state': 'ready',
      'coverage': 'verified_public_only', 'directoryCoverage': 'complete_bounded', 'orderingAvailable': false,
      'observedAt': at.toIso8601String(), 'query': body['query'], 'resultKind': body['resultKind'], 'requestedStore': body['storeId'],
      'items': empty ? [] : [{'channel': 'retail', 'listing': listing}],
      'page': {'snapshotId': 'a' * 64, 'startIndex': 0, 'totalCount': empty ? 0 : 1, 'previousCursor': null, 'nextCursor': null}};
  }
  BuyV2CatalogueQuery discoveryQuery({String? storeId}) => BuyV2CatalogueQuery(destination: BuyV2Destination.shop,
    regionId: null, areaScope: BuyV2CatalogueAreaScope.allAreas, storeId: storeId);
  test('LF-DISCOVERY client products Store preview and content use exact public identity and paise', () async {
    final requests = <Map<String, Object?>>[];
    final connection = discoveryGateway(OwnerTransport((body) async {
      requests.add(body);
      return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': discoveryData(body)}));
    }));
    final source = WorkspacePublicDiscoverySource(gateway: connection, current: () => true);
    addTearDown(source.dispose);
    final products = await source.loadProducts(discoveryQuery(), pageSize: 40), selected = products.items.single;
    expect(selected.id, publicIdentity().listingId); expect(selected.sourceSkuId, 'sku-one'); expect(selected.priceMinor, 10025);
    expect(source.snapshotFor(selected).state, BuyV2ProductContentState.ready);
    expect(selected.reviewDeliveryOptions, isEmpty);
    final stores = await source.loadStores(discoveryQuery(), pageSize: 40);
    expect(stores.totalCount, 1); expect(stores.items.single.id, 'store-one');
    expect(stores.items.single.previewProduct!.id, selected.id);
    expect(stores.items.single.address, isEmpty); expect(stores.items.single.hasCollectionAddress, isFalse);
    final scoped = await source.loadProducts(discoveryQuery(storeId: 'store-one'), pageSize: 40);
    expect(scoped.items.single.id, selected.id); expect(requests.last['storeId'], 'store-one');
    expect(requests.map((body) => body['resultKind']), ['products', 'stores', 'products']);
  });
  for (final fault in ['realm', 'query', 'kind', 'Store', 'count', 'duplicate', 'future', 'version', 'binding']) {
    test('LF-DISCOVERY client rejects mismatched public response $fault', () async {
      final source = WorkspacePublicDiscoverySource(current: () => true, gateway: discoveryGateway(OwnerTransport((body) async {
        final data = discoveryData(body);
        if (fault == 'realm') data['realm'] = 'evaluation';
        if (fault == 'query') data['query'] = {...body['query'] as Map, 'search': 'different'};
        if (fault == 'kind') data['resultKind'] = 'stores';
        if (fault == 'Store') data['requestedStore'] = 'foreign-store';
        if (fault == 'count') (data['page'] as Map)['totalCount'] = 2;
        if (fault == 'duplicate') { (data['items'] as List).add((data['items'] as List).single); (data['page'] as Map)['totalCount'] = 2; }
        if (fault == 'future') data['observedAt'] = at.add(const Duration(hours: 1)).toIso8601String();
        if (fault == 'version') data['discoveryPageVersion'] = 2;
        if (fault == 'binding') ((row(((data['items'] as List).single as Map)['listing'] as Map<String, dynamic>)['listings'] as List).single as Map)['skuId'] = 'foreign-sku';
        return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': data}));
      })));
      addTearDown(source.dispose);
      await expectLater(source.loadProducts(discoveryQuery(), pageSize: 40), throwsFormatException);
    });
  }
  test('LF-DISCOVERY root A B A retires the old pending reader and owns only its new source', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const accountA = (environment: 'host-service', projectId: 'host-project', tenantId: null as String?, userId: 'host-a');
    const accountB = (environment: 'host-service', projectId: 'host-project', tenantId: null as String?, userId: 'host-b');
    BuyV2AccountPersistenceIdentity live = accountA;
    final core = BuySession(), sources = <WorkspacePublicDiscoverySource>[];
    final pending = Completer<SocialContentResponse>(), started = Completer<Map<String, Object?>>();
    final root = BuyV2RootSessions(core: core, currentIdentity: () => live,
      accountStoreFactory: (_, _) => _HostRetirableStateStore(),
      catalogueSourceFactory: (_, current) {
        final first = sources.isEmpty;
        final source = WorkspacePublicDiscoverySource(current: current, gateway: discoveryGateway(OwnerTransport((body) {
          if (first) { started.complete(body); return pending.future; }
          return Future.value(SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': discoveryData(body)})));
        })));
        sources.add(source); return source;
      });
    addTearDown(core.dispose); addTearDown(root.dispose);
    root.synchronize(accountRequired: true);
    expect(root.current.cataloguePageSource, same(sources.single));
    expect(root.current.productContentAdapter, same(sources.single));
    final oldRead = sources.single.loadProducts(discoveryQuery(), pageSize: 40), body = await started.future;
    live = accountB; root.synchronize(accountRequired: true);
    live = accountA; root.synchronize(accountRequired: true);
    expect(sources, hasLength(3)); expect(sources.first.active, isFalse); expect(sources[1].active, isFalse);
    expect(root.current.cataloguePageSource, same(sources.last));
    pending.complete(SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': discoveryData(body)})));
    await expectLater(oldRead, throwsFormatException);
    expect((await sources.last.loadProducts(discoveryQuery(), pageSize: 40)).items.single.priceMinor, 10025);
    await expectLater(sources.last.loadProducts(root.current.catalogueQuery(), pageSize: 40), throwsFormatException,
      reason: 'Ordinary regional Quick queries require genuine eligibility; root injection is not completion of that producer.');
  });
  test('LF-DISCOVERY default configuration creates no provider for review unsupported tenant or missing opt-in', () {
    for (final environment in ['firebase-service', 'host-service', 'review']) {
      expect(configuredWorkspacePublicDiscovery(environment: environment, projectId: 'moolsocial-dev-503018',
        tenantId: null, accountUserId: 'host-owner', realm: 'evaluation', current: () => true), isNull);
    }
  });
  final discoveryLog = Platform.environment['LF03_DISCOVERY_PUBLIC_LOG'];
  if (discoveryLog != null) { test('LF-DISCOVERY actual emulator response enters the public client and existing Buy pager', () async {
    const marker = 'LF_DISCOVERY_PROJECTION=';
    final captured = File(discoveryLog).readAsLinesSync().where((line) => line.contains(marker)).toList();
    expect(captured, hasLength(1));
    final actual = jsonDecode(captured.single.split(marker).last) as Map<String, dynamic>;
    final source = WorkspacePublicDiscoverySource(current: () => true,
      gateway: discoveryGateway(OwnerTransport((body) async {
        expect(body['query'], actual['query']); expect(body['pageSize'], anyOf(40, 50));
        return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': actual}));
      }), realm: 'evaluation'));
    final core = BuySession(), session = BuyV2Session(core: core, reviewDataEnabled: false,
      cataloguePageSource: source, productContentAdapter: source, catalogueNow: () => at);
    addTearDown(core.dispose); addTearDown(session.dispose); addTearDown(source.dispose);
    expect((await source.loadProducts(BuyV2CatalogueQuery(destination: BuyV2Destination.shop, regionId: null,
      areaScope: BuyV2CatalogueAreaScope.allAreas, sort: BuyV2ProductSort.priceLowToHigh), pageSize: 50)).totalCount, 2);
    final pager = session.acquireCatalogueProducts('host-discovery-contract');
    await pager.open(BuyV2CatalogueQuery(destination: BuyV2Destination.shop, regionId: null,
      areaScope: BuyV2CatalogueAreaScope.allAreas, sort: BuyV2ProductSort.priceLowToHigh));
    expect(pager.message, isNull); expect(pager.page!.totalCount, 2);
    expect(pager.page!.items.map((p) => p.storeId), ['store-two', 'store-one']);
    expect(pager.page!.items.first.priceMinor, 10025);
    expect(session.productContentFor(pager.page!.items.first).state, BuyV2ProductContentState.ready);
    expect(session.productFactsFor(pager.page!.items.first).eligibility, isNull);
    session.releaseCatalogueProducts('host-discovery-contract');
  }); }
  final revisionLog = Platform.environment['LF03_REVISION_PUBLIC_LOG'];
  if (revisionLog != null) {
    test('LF03-REVISION actual approved update and other Store original reach the existing public content cache', () async {
      const marker = 'LF_REVISION_PROJECTION=';
      final captures = File(revisionLog).readAsLinesSync().where((line) => line.contains(marker)).toList();
      expect(captures, hasLength(1));
      final actual = jsonDecode(captures.single.split(marker).last) as Map<String, dynamic>;
      final source = WorkspacePublicDiscoverySource(current: () => true,
        gateway: discoveryGateway(OwnerTransport((body) async {
          expect(body['query'], actual['query']);
          return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': actual}));
        }), realm: 'evaluation'));
      addTearDown(source.dispose);
      final products = await source.loadProducts(BuyV2CatalogueQuery(destination: BuyV2Destination.shop, regionId: null,
        areaScope: BuyV2CatalogueAreaScope.allAreas, sort: BuyV2ProductSort.priceLowToHigh), pageSize: 50);
      final updated = products.items.singleWhere((p) => p.storeId == 'store-one');
      final original = products.items.singleWhere((p) => p.storeId == 'store-two');
      expect(updated.sourceSkuId, 'sku-one'); expect(updated.canonicalId, original.canonicalId);
      expect(source.snapshotFor(updated).description, 'Independently reviewed updated product details');
      expect(source.snapshotFor(original).description, 'Isolated test description');
      expect(updated.priceMinor, 26000); expect(original.priceMinor, 10025);
      expect(source.snapshotFor(updated).state, BuyV2ProductContentState.ready);
      expect(source.snapshotFor(original).state, BuyV2ProductContentState.ready);
    });
  }
  // LF04 readonly public-service fixtures. No owner draft or native feed injection.
  Map<String, dynamic> promotionRow({String id = 'promotion-one', int revision = 1}) {
    final sku = row(publicPage())..remove('listings');
    return {'publicationId': id, 'revision': revision, 'publisherType': 'retailer',
      'publisherId': 'store-one', 'publisherName': 'Host Store', 'headline': 'Host promotion',
      'detail': 'Host supplied detail', 'sourceId': 'store-promotion:production:store-one:$id:$revision',
      'observedAt': at.toIso8601String(),
      'validUntil': at.add(const Duration(minutes: 30)).toIso8601String(), 'product': sku};
  }
  Map<String, dynamic> promotionPage(List<Map<String, dynamic>> items, {String? next}) => {
    'schemaVersion': 1, 'realm': 'production', 'storeId': 'store-one',
    'observedAt': at.toIso8601String(), 'state': 'ready',
    'coverage': 'verified_public_promotions_only', 'orderingAvailable': false,
    'items': items, 'nextCursor': next};
  Map<String, dynamic> globalPromotionPage(Map<String, Object?> body) {
    final listing = ((discoveryData({'query': {}, 'resultKind': 'products'})['items'] as List).single as Map)['listing'] as Map<String, dynamic>;
    final sku = jsonDecode(jsonEncode(row(listing))) as Map<String, dynamic>..remove('listings');
    return {'schemaVersion': 1, 'promotionDiscoveryVersion': 1, 'realm': 'production', 'state': 'ready',
      'coverage': {'kind': 'connected_publishers', 'publisherTypes': ['retailer'], 'countBasis': 'publications'},
      'orderingAvailable': false, 'observedAt': at.toIso8601String(), 'query': body['query'],
      'items': <Object?>[for (final id in ['promotion-one', 'promotion-two']) {'publication': {...promotionRow(id: id), 'product': sku}, 'listing': listing}],
      'page': {'snapshotId': 'd' * 64, 'startIndex': 0, 'totalCount': 2, 'previousCursor': null, 'nextCursor': null}};
  }
  BuyV2CatalogueQuery globalOffersQuery() => BuyV2CatalogueQuery(destination: BuyV2Destination.shop,
    regionId: null, areaScope: BuyV2CatalogueAreaScope.allAreas, offersOnly: true);
  Map<String, dynamic> advertisedTerms({bool percentage = false}) => BuyV2AdvertisedBenefitTerms(kind: percentage ? 'percentage' : 'flat',
    flatAmountMinor: percentage ? null : 1025, flatBasis: percentage ? null : 'per_pack', percentageBasisPoints: percentage ? 750 : null,
    maximumSavingMinor: 5000, minimumSpendMinor: 0, minimumQuantity: 2).toJson();
  Map<String, dynamic> globalAdvertisedPage(Map<String, Object?> body, {bool clear = false, int revision = 1}) {
    final data = globalPromotionPage(body)..['promotionTermsVersion'] = 1;
    final items = (data['items'] as List).cast<Map>();
    for (var i = 0; i < items.length; i++) {
      final publication = items[i]['publication'] as Map<String, dynamic>;
      publication['revision'] = revision;
      publication['sourceId'] = 'store-promotion:production:store-one:${publication['publicationId']}:$revision';
      if (!clear) publication['benefitTerms'] = advertisedTerms(percentage: i == 1);
    }
    return data;
  }
  test('LF04 TERMS real Store and global readers retain exact terms without a Cart benefit', () async {
    final requests = <Map<String, Object?>>[];
    final connection = discoveryGateway(OwnerTransport((body) async {
      requests.add(body);
      final listing = ((discoveryData({'query': {}, 'resultKind': 'products'})['items'] as List).single as Map)['listing'] as Map<String, dynamic>;
      final placement = promotionRow()..['benefitTerms'] = advertisedTerms()
        ..['product'] = (jsonDecode(jsonEncode(row(listing))) as Map<String, dynamic>..remove('listings'));
      final data = body['operation'] == 'readPublicPromotionDiscovery' ? globalAdvertisedPage(body)
        : body['operation'] == 'readPublicStorePromotions'
          ? (promotionPage([placement])..['promotionTermsVersion'] = 1) : listing;
      return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': data}));
    }), promotions: true, advertisedTerms: true);
    expect(connection.forOwnerAccount('owner-one').promotionTermsSupported, true);
    final global = WorkspacePublicDiscoverySource(gateway: connection, current: () => true);
    final store = WorkspaceStoreCatalogueSource(gateway: connection, storeId: 'store-one', current: () => true);
    addTearDown(global.dispose);
    final found = await global.loadOffers(globalOffersQuery(), pageSize: 40);
    expect(found.items.map((o) => o.benefitTerms!.toJson()), [advertisedTerms(), advertisedTerms(percentage: true)]);
    final scoped = await store.loadStoreOffers(storeId: 'store-one', destination: BuyV2Destination.shop);
    expect(scoped.single.benefitTerms!.toJson(), advertisedTerms());
    expect(requests.where((b) => b['operation'] == 'readPublicStorePromotions' || b['operation'] == 'readPublicPromotionDiscovery')
      .every((b) => b['promotionTermsVersion'] == 1), true);
    expect(found.items.first.product.priceMinor, 10025);
  });
  for (final fault in ['no opt-in', 'missing marker', 'wrong version', 'null terms', 'ambiguous kind']) {
    test('LF04 TERMS public reader rejects $fault instead of dropping conditions', () async {
      final source = WorkspacePublicDiscoverySource(current: () => true, gateway: discoveryGateway(OwnerTransport((body) async {
        final data = globalAdvertisedPage(body);
        if (fault == 'missing marker') data.remove('promotionTermsVersion');
        if (fault == 'wrong version') data['promotionTermsVersion'] = 1.0;
        final publication = ((data['items'] as List).first as Map)['publication'] as Map;
        if (fault == 'null terms') publication['benefitTerms'] = null;
        if (fault == 'ambiguous kind') (publication['benefitTerms'] as Map)['percentageBasisPoints'] = 500;
        return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': data}));
      }), promotions: true, advertisedTerms: fault != 'no opt-in'));
      addTearDown(source.dispose); await expectLater(source.loadOffers(globalOffersQuery(), pageSize: 40), throwsFormatException);
    });
  }
  test('LF04 TERMS same-revision condition changes cannot overwrite admitted public facts', () async {
    var changed = false;
    final source = WorkspacePublicDiscoverySource(current: () => true, gateway: discoveryGateway(OwnerTransport((body) async {
      final data = globalAdvertisedPage(body);
      if (changed) ((((data['items'] as List).first as Map)['publication'] as Map)['benefitTerms'] as Map)['minimumQuantity'] = 3;
      return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': data}));
    }), promotions: true, advertisedTerms: true));
    addTearDown(source.dispose); await source.loadOffers(globalOffersQuery(), pageSize: 40); changed = true;
    await expectLater(source.loadOffers(globalOffersQuery(), pageSize: 40), throwsFormatException);
  });
  test('LF04 TERMS cleared head survives page removal and cannot resurrect opened terms', () async {
    var revision = 1, empty = false;
    final source = WorkspacePublicDiscoverySource(current: () => true, gateway: discoveryGateway(OwnerTransport((body) async {
      final data = globalAdvertisedPage(body, clear: revision == 2, revision: revision);
      if (empty) { data['items'] = <Object?>[]; (data['page'] as Map)['totalCount'] = 0; }
      return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': data}));
    }), promotions: true, advertisedTerms: true));
    final core = BuySession();
    final buyer = BuyV2Session(core: core, reviewDataEnabled: false,
      catalogueNow: () => at, cataloguePageSource: source, publishedCatalogueSource: source);
    addTearDown(core.dispose); addTearDown(buyer.dispose); addTearDown(source.dispose);
    final pager = buyer.acquireCatalogueOffers('terms-head'); await pager.open(globalOffersQuery());
    final old = pager.page!.items.first;
    expect(buyer.admitStorePromotion(source, old), true);
    expect(buyer.advertisedOffersFor(old.product), hasLength(2));
    revision = 2; await pager.refresh(); expect(pager.message, isNull);
    expect(buyer.advertisedOffersFor(old.product), isEmpty);
    empty = true; await pager.refresh(); expect(pager.message, isNull);
    expect(buyer.advertisedOffersFor(old.product), isEmpty);
    expect(buyer.admitStorePromotion(source, old), false);
  });
  test('LF04 TERMS conflicting equal revision is suppressed until a newer head', () async {
    final source = WorkspacePublicDiscoverySource(current: () => true, gateway: discoveryGateway(OwnerTransport((body) async =>
      SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': globalAdvertisedPage(body)}))),
      promotions: true, advertisedTerms: true));
    final core = BuySession();
    final buyer = BuyV2Session(core: core, reviewDataEnabled: false,
      catalogueNow: () => at, cataloguePageSource: source, publishedCatalogueSource: source);
    addTearDown(core.dispose); addTearDown(buyer.dispose); addTearDown(source.dispose);
    final pager = buyer.acquireCatalogueOffers('terms-conflict'); await pager.open(globalOffersQuery());
    final old = pager.page!.items.first;
    BuyV2PublishedCatalogueOffer changed(int revision) => BuyV2PublishedCatalogueOffer(
      publicationId: old.publicationId, product: old.product, publisherType: old.publisherType,
      publisherId: old.publisherId, publisherName: old.publisherName, headline: old.headline,
      sourceId: old.sourceId, observedAt: old.observedAt, validUntil: old.validUntil,
      detail: old.detail, revision: revision, benefitTerms: BuyV2AdvertisedBenefitTerms(kind: 'percentage', percentageBasisPoints: 500));
    expect(buyer.admitStorePromotion(source, old), true);
    expect(buyer.admitStorePromotion(source, changed(1)), false);
    expect(buyer.advertisedOffersFor(old.product).where((o) => o.identity == old.identity), isEmpty);
    expect(buyer.admitStorePromotion(source, old), false);
    expect(buyer.admitStorePromotion(source, changed(2)), true);
    expect(buyer.advertisedOffersFor(old.product).firstWhere((o) => o.identity == old.identity).revision, 2);
  });
  test('LF04 TERMS Store refresh retires opened terms without navigation; rename is not a terms conflict', () async {
    final source = WorkspacePublicDiscoverySource(current: () => true, gateway: discoveryGateway(OwnerTransport((body) async =>
      SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': globalAdvertisedPage(body)}))),
      promotions: true, advertisedTerms: true));
    final core = BuySession();
    final buyer = BuyV2Session(core: core, reviewDataEnabled: false,
      catalogueNow: () => at, cataloguePageSource: source, publishedCatalogueSource: source);
    addTearDown(core.dispose); addTearDown(buyer.dispose); addTearDown(source.dispose);
    final old = (await source.loadOffers(globalOffersQuery(), pageSize: 40)).items.first;
    BuyV2PublishedCatalogueOffer replacement(int revision, {bool clear = false, String? name}) => BuyV2PublishedCatalogueOffer(
      publicationId: old.publicationId, product: old.product, publisherType: old.publisherType,
      publisherId: old.publisherId, publisherName: name ?? old.publisherName, headline: old.headline,
      sourceId: old.sourceId, observedAt: old.observedAt, validUntil: old.validUntil,
      detail: old.detail, revision: revision, benefitTerms: clear ? null : old.benefitTerms);
    expect(buyer.admitStorePromotion(source, old), true);
    expect(buyer.observeStorePromotions(source, [replacement(1, name: 'Renamed Store')]), true);
    expect(buyer.advertisedOffersFor(old.product), hasLength(1));
    expect(buyer.observeStorePromotions(source, [replacement(2, clear: true)]), true);
    expect(buyer.advertisedOffersFor(old.product), isEmpty);
    expect(buyer.cartLines, isEmpty);
    expect(buyer.admitStorePromotion(source, old), false);
  });
  testWidgets('LF04 TERMS percentage disclosure does not invent its calculation basis', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: BuyV2AdvertisedBenefitRows(
      terms: BuyV2AdvertisedBenefitTerms(kind: 'percentage', percentageBasisPoints: 750)))));
    expect(find.text('Store-advertised amount: 7.5%'), findsOneWidget);
    expect(find.textContaining('subtotal'), findsNothing);
  });
  test('LF04 GLOBAL ordinary promotions retain separate placements and exact paise SKU', () async {
    final source = WorkspacePublicDiscoverySource(current: () => true, gateway: discoveryGateway(OwnerTransport((body) async {
      expect(body['operation'], 'readPublicPromotionDiscovery');
      return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': globalPromotionPage(body)}));
    }), promotions: true));
    addTearDown(source.dispose);
    final page = await source.loadOffers(globalOffersQuery(), pageSize: 40);
    expect(page.offerCoverage!.key, 'retailer'); expect(page.items.map((o) => o.product.priceMinor).toSet(), {10025});
    expect(page.items.map((o) => o.identity).toSet(), hasLength(2)); expect(page.items.map((o) => o.product.id).toSet(), hasLength(1));
    final core = BuySession();
    final buyer = BuyV2Session(core: core, catalogueNow: () => at,
      cataloguePageSource: source, publishedCatalogueSource: source, reviewDataEnabled: false);
    addTearDown(core.dispose); addTearDown(buyer.dispose);
    final pager = buyer.acquireCatalogueOffers('global-host'); await pager.open(globalOffersQuery());
    expect(pager.message, isNull); expect(pager.page!.items, hasLength(2)); expect(buyer.cartLines, isEmpty);
  });
  test('LF04 GLOBAL delayed older enrichment cannot regress a newer publication head', () async {
    final release = Completer<void>(), entered = Completer<void>(); var calls = 0, revision = 1;
    final reader = HostReviewedVariantSource(memberships: (entries, current) async {
      if (++calls == 1) { entered.complete(); await release.future; }
      return entries.map((entry) => WorkspaceReviewedVariantMembership(listing: entry.product.publicListingIdentity!,
        skuRevision: entry.readback.skuRevision!, catalogueVersion: entry.readback.catalogueVersion!, familyId: null,
        sourceId: 'host-global-associations', revision: 1, observedAt: at, validUntil: at.add(const Duration(minutes: 30)),
        attributes: const [])).toList();
    });
    final source = WorkspacePublicDiscoverySource(current: () => true, gateway: AuthenticatedWorkspaceCatalogueGateway(
      endpoint: Uri.parse('https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'), credentials: Credentials(),
      productFactsReadbackSupported: true, unbrandedProduceReadbackSupported: true, storeClassificationReadbackSupported: true,
      promotionDiscoverySupported: true, reviewedVariants: reader, now: () => at, transport: OwnerTransport((body) async {
        final data = globalPromotionPage(body);
        for (final raw in data['items'] as List) {
          final p = (raw as Map)['publication'] as Map;
          p['revision'] = revision; p['sourceId'] = 'store-promotion:production:store-one:${p['publicationId']}:$revision';
        }
        return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': data}));
      })));
    addTearDown(source.dispose);
    final old = expectLater(source.loadOffers(globalOffersQuery(), pageSize: 40), throwsFormatException);
    await entered.future; revision = 2;
    expect((await source.loadOffers(globalOffersQuery(), pageSize: 40)).items.first.revision, 2);
    release.complete(); await old; revision = 1;
    await expectLater(source.loadOffers(globalOffersQuery(), pageSize: 40), throwsFormatException);
  });
  test('LF04 GLOBAL two Stores can reuse a placement ID without product or publication collisions', () async {
    final source = WorkspacePublicDiscoverySource(current: () => true, gateway: discoveryGateway(OwnerTransport((body) async {
      final data = globalPromotionPage(body), items = data['items'] as List;
      items[1] = jsonDecode(jsonEncode(items.first).replaceAll('store-one', 'store-two').replaceAll('a' * 64, 'e' * 64));
      return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': data}));
    }), promotions: true));
    addTearDown(source.dispose);
    final core = BuySession();
    final buyer = BuyV2Session(core: core, reviewDataEnabled: false,
      catalogueNow: () => at, cataloguePageSource: source, publishedCatalogueSource: source);
    addTearDown(core.dispose); addTearDown(buyer.dispose);
    expect((await source.loadOffers(globalOffersQuery(), pageSize: 40)).items, hasLength(2));
    final pager = buyer.acquireCatalogueOffers('two-stores'); await pager.open(globalOffersQuery());
    expect(pager.message, isNull); expect(pager.page!.items.map((p) => p.publicationId).toSet(), {'promotion-one'});
    expect(pager.page!.items.map((p) => p.identity).toSet(), hasLength(2));
    expect(pager.page!.items.map((p) => p.product.storeId).toSet(), {'store-one', 'store-two'});
  });
  for (final scale in [1.0, 2.0]) {
    testWidgets('LF04 GLOBAL Offers coverage and distinct promotions fit at $scale', (tester) async {
      tester.view.devicePixelRatio = 1; tester.view.physicalSize = const Size(390, 844); addTearDown(tester.view.reset);
      final source = WorkspacePublicDiscoverySource(current: () => true, gateway: discoveryGateway(OwnerTransport((body) async =>
        SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': globalPromotionPage(body)}))), promotions: true));
      final core = BuySession();
      final buyer = BuyV2Session(core: core, reviewDataEnabled: false, catalogueNow: () => at,
        cataloguePageSource: source, publishedCatalogueSource: source)..chooseCatalogueArea(null, BuyV2CatalogueAreaScope.allAreas)
        ..featuredOffersMoolSocial = false;
      var closed = false;
      void close() {if (!closed) {closed = true; buyer.dispose(); core.dispose(); source.dispose();}}
      addTearDown(close);
      const capture = Key('global-offers-host');
      await tester.pumpWidget(MaterialApp(theme: MoolTheme.light(), builder: (context, child) =>
        MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true), child: child!),
        home: RepaintBoundary(key: capture, child: Scaffold(body: BuyV2OffersView(session: buyer, source: const BuyV2CataloguePublishedOffersSource())))));
      for (var frame = 0; frame < 10; frame++) { await tester.pump(const Duration(milliseconds: 200)); }
      expect(find.byKey(const Key('buy-offers-publisher-coverage')), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(buyer.commerceLoadState, BuyV2CommerceLoadState.loading, reason: 'Reading publications does not manufacture commerce readiness');
      final directory = Platform.environment['LF04_OFFERS_CAPTURE_DIR'];
      if (directory != null) { await tester.runAsync(() async {
        final image = await tester.renderObject<RenderRepaintBoundary>(find.byKey(capture)).toImage();
        try {
          final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
          await Directory(directory).create(recursive: true);
          final file = File('$directory/ordinary-offers-host-$scale.png');
          if (await file.exists()) throw StateError('Preserve existing capture');
          await file.writeAsBytes(bytes.buffer.asUint8List());
        } finally {image.dispose();}
      }); }
      buyer.toggleSaved(publicIdentity().listingId);
      await tester.tap(find.byKey(const Key('buy-offers-saved'))); await tester.pump();
      expect(find.bySemanticsLabel('2 saved retailer promotions shown'), findsOneWidget);
      expect(buyer.cartLines, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      close();
    });
  }
  for (final fault in ['coverage', 'publisher', 'source', 'price', 'count', 'duplicate', 'future', 'retired']) {
    test('LF04 GLOBAL rejects $fault without partial page admission', () async {
      var current = true;
      final source = WorkspacePublicDiscoverySource(current: () => current, gateway: discoveryGateway(OwnerTransport((body) async {
        final data = globalPromotionPage(body), item = ((data['items'] as List).first as Map)['publication'] as Map;
        if (fault == 'coverage') (data['coverage'] as Map)['publisherTypes'] = ['retailer', 'moolSocial'];
        if (fault == 'publisher') item['publisherId'] = 'other-store';
        if (fault == 'source') item['sourceId'] = 'other-source';
        if (fault == 'price') (((item['product'] as Map)['channels'] as List).single as Map)['priceMinor'] = 10026;
        if (fault == 'count') (data['page'] as Map)['totalCount'] = 3;
        if (fault == 'duplicate') (data['items'] as List)[1] = (data['items'] as List).first;
        if (fault == 'future') data['observedAt'] = at.add(const Duration(seconds: 1)).toIso8601String();
        if (fault == 'retired') current = false;
        return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': data}));
      }), promotions: true));
      addTearDown(source.dispose);
      await expectLater(source.loadOffers(globalOffersQuery(), pageSize: 40), throwsFormatException);
      expect(source.observedProductIds, isEmpty);
    });
  }
  for (final mode in ['commerce unavailable', 'recovery pending', 'missing publication source']) {
    testWidgets('LF04 GLOBAL browse guard $mode retains commercial and account boundaries', (tester) async {
      var calls = 0;
      final restored = Completer<BuyV2CustomerStateSnapshot?>();
      final stateStore = _HostRetirableStateStore()..heldRead = restored.future;
      final source = WorkspacePublicDiscoverySource(current: () => true, gateway: discoveryGateway(OwnerTransport((body) async {
        calls++; return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': globalPromotionPage(body)}));
      }), promotions: true));
      final core = BuySession();
      final buyer = BuyV2Session(core: core, reviewDataEnabled: false, catalogueNow: () => at,
        customerStateStore: mode == 'recovery pending' ? stateStore : null,
        cataloguePageSource: source, publishedCatalogueSource: mode == 'missing publication source' ? null : source)
        ..chooseCatalogueArea(null, BuyV2CatalogueAreaScope.allAreas)..featuredOffersMoolSocial = false
        ..commerceLoadState = BuyV2CommerceLoadState.unavailable;
      final recovery = mode == 'recovery pending' ? buyer.restoreCustomerState() : null;
      expect(buyer.customerStateRecoveryPending, mode == 'recovery pending');
      var closed = false;
      void close() {if (!closed) {closed = true; buyer.dispose(); core.dispose(); source.dispose();}}
      addTearDown(close);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: BuyV2OffersView(session: buyer, source: const BuyV2CataloguePublishedOffersSource()))));
      for (var frame = 0; frame < 10; frame++) {await tester.pump(const Duration(milliseconds: 200));}
      expect(find.byKey(const Key('buy-offers-publisher-coverage')), mode == 'commerce unavailable' ? findsOneWidget : findsNothing);
      expect(calls, mode == 'commerce unavailable' ? greaterThan(0) : 0);
      expect(buyer.catalogueAvailable, isFalse); expect(buyer.availablePaymentMethods, isEmpty); expect(buyer.cartLines, isEmpty);
      expect(tester.takeException(), isNull); await tester.pumpWidget(const SizedBox.shrink());
      restored.complete(null); if (recovery != null) await recovery; close();
    });
  }
  test('LF04 STORE reader traverses empty filtered page and resolves genuine listing and copy', () async {
    final requests = <Map<String, Object?>>[];
    final transport = OwnerTransport((body) async {
      requests.add(body);
      return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data':
        body['operation'] == 'readPublicStorePromotions'
          ? body['after'] == null ? promotionPage([], next: 'promotion-before')
              : promotionPage([promotionRow(), promotionRow(id: 'promotion-two')])
          : publicPage()}));
    });
    final source = WorkspaceStoreCatalogueSource(gateway: ownerGateway(transport), storeId: 'store-one', current: () => true);
    final results = await source.loadStoreOffers(storeId: 'store-one', destination: BuyV2Destination.shop);
    expect(results.length, 2); expect(results.map((r) => r.publicationId), ['promotion-one', 'promotion-two']);
    expect(results.map((r) => r.product.id).toSet(), {publicIdentity().listingId});
    expect(results.first.detail, 'Host supplied detail'); expect(results.first.revision, 1);
    expect(results.first.product.priceMinor, 26000); expect(results.first.product.storeId, 'store-one');
    expect(results.first.isCurrent(now: at), isTrue);
    expect(requests.first, {'operation': 'readPublicStorePromotions', 'storeId': 'store-one', 'limit': 20});
    expect(requests[1]['after'], 'promotion-before');
    expect(requests.where((b) => b['operation'] == 'readPublicStoreCatalogue').length, 1,
      reason: 'Resolve a SKU/channel once, retain both separate publications');
  });
  for (final change in ['store', 'realm', 'unavailable', 'ordering', 'coverage', 'future', 'expired',
    'issuer', 'revision', 'source', 'duplicate', 'loop', 'bound', 'sku money', 'sku pack', 'sku content', 'term revision']) {
    test('LF04 STORE reader rejects $change without partial/public fallback', () async {
      final placement = promotionRow(), data = promotionPage([placement]);
      if (change == 'store') data['storeId'] = 'other-store';
      if (change == 'realm') data['realm'] = 'evaluation';
      if (change == 'unavailable') data['state'] = 'unavailable';
      if (change == 'ordering') data['orderingAvailable'] = true;
      if (change == 'coverage') data['coverage'] = 'all_promotions';
      if (change == 'future') data['observedAt'] = at.add(const Duration(minutes: 1)).toIso8601String();
      if (change == 'expired') placement['validUntil'] = at.toIso8601String();
      if (change == 'issuer') placement['publisherId'] = 'other-store';
      if (change == 'revision') placement['revision'] = 0;
      if (change == 'source') placement['sourceId'] = 'unbound-source';
      if (change == 'duplicate') (data['items'] as List).add(promotionRow());
      if (change == 'sku money') (((placement['product'] as Map)['channels'] as List).single as Map)['priceMinor'] = 26001;
      if (change == 'sku pack') ((placement['product'] as Map)['pack'] as Map)['label'] = 'Different pack';
      if (change == 'sku content') ((placement['product'] as Map)['content'] as Map)['description'] = 'Different copy';
      if (change == 'term revision') (((placement['product'] as Map)['channels'] as List).single as Map)['revision'] = 'changed-term';
      var pages = 0;
      final transport = OwnerTransport((body) async {
        if (body['operation'] != 'readPublicStorePromotions') {
          return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': publicPage()}));
        }
        pages++;
        final returned = change == 'loop' ? promotionPage([], next: 'repeated-cursor') :
          change == 'bound' ? promotionPage([], next: 'cursor-${pages.toString().padLeft(4, '0')}') : data;
        return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': returned}));
      });
      final source = WorkspaceStoreCatalogueSource(gateway: ownerGateway(transport), storeId: 'store-one', current: () => true);
      await expectLater(source.loadStoreOffers(storeId: 'store-one', destination: BuyV2Destination.shop), throwsFormatException);
      expect(pages, lessThanOrEqualTo(20));
    });
  }
  test('LF04 STORE retired lifetime and wrong Store send no public reads', () async {
    final transport = OwnerTransport((_) async => throw StateError('Must not send'));
    final source = WorkspaceStoreCatalogueSource(gateway: ownerGateway(transport), storeId: 'store-one', current: () => false);
    await expectLater(source.loadStoreOffers(storeId: 'store-one', destination: BuyV2Destination.shop), throwsFormatException);
    await expectLater(source.loadStoreOffers(storeId: 'other-store', destination: BuyV2Destination.shop), throwsFormatException);
    expect(transport.calls, 0);
  });
  for (final change in ['revision rollback', 'same revision copy', 'late retirement', 'late expiry', 'late replacement']) {
    test('LF04 STORE rejects $change after an asynchronous read', () async {
      var active = true, clock = at, revision = 2, copy = 'Host supplied detail';
      final entered = Completer<void>(), released = Completer<void>();
      var delayed = false;
      final transport = OwnerTransport((body) async {
        if (body['operation'] == 'readPublicStorePromotions') {
          return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data':
            promotionPage([promotionRow(revision: revision)..['detail'] = copy])}));
        }
        if (delayed) { entered.complete(); await released.future; }
        return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': publicPage()}));
      });
      final connection = AuthenticatedWorkspaceCatalogueGateway(endpoint: Uri.parse(
        'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
        credentials: Credentials(), transport: transport, now: () => clock);
      final source = WorkspaceStoreCatalogueSource(gateway: connection, storeId: 'store-one', current: () => active);
      Future<List<BuyV2PublishedCatalogueOffer>> read() => source.loadStoreOffers(storeId: 'store-one', destination: BuyV2Destination.shop);
      expect((await read()).single.revision, 2);
      if (change == 'revision rollback') revision = 1;
      if (change == 'same revision copy') copy = 'Changed without revision';
      if (change.startsWith('late')) delayed = true;
      final pending = read();
      final failure = expectLater(pending, throwsFormatException);
      if (delayed) {
        await entered.future;
        if (change == 'late retirement') active = false;
        if (change == 'late expiry') clock = at.add(const Duration(minutes: 31));
        if (change == 'late replacement') {
          await expectLater(source.loadStoreOffers(storeId: 'wrong-store', destination: BuyV2Destination.shop), throwsFormatException);
        }
        released.complete();
      }
      await failure;
    });
  }
  for (final changedWidth in [false, true]) {
    test('LF04 STORE normalizes only omitted static frame count, changedWidth=$changedWidth', () async {
      final data = publicPage();
      (row(data)['content'] as Map)['media'] = [<String, Object?>{
        'id': 'host-image', 'revision': 'image-one', 'url': 'https://example.com/host-image.jpg',
        'storeId': 'store-one', 'skuId': 'sku-one', 'canonicalProductId': 'canonical-one',
        'publisherWorkspaceId': 'supplier-one', 'file': {'mimeType': 'image/jpeg', 'byteLength': 1024,
          'width': 640, 'height': 640, 'normalized': true, 'frameCount': 1}}];
      final promotion = promotionRow()..['product'] = (jsonDecode(jsonEncode(row(data))) as Map<String, dynamic>..remove('listings'));
      final file = ((((promotion['product'] as Map)['content'] as Map)['media'] as List).single['file']) as Map;
      file.remove('frameCount'); if (changedWidth) file['width'] = 320;
      final transport = OwnerTransport((body) async => SocialContentResponse(statusCode: 200,
        body: jsonEncode({'ok': true, 'data': body['operation'] == 'readPublicStorePromotions' ? promotionPage([promotion]) : data})));
      final source = WorkspaceStoreCatalogueSource(gateway: ownerGateway(transport), storeId: 'store-one', current: () => true);
      final result = source.loadStoreOffers(storeId: 'store-one', destination: BuyV2Destination.shop);
      if (changedWidth) { await expectLater(result, throwsFormatException); }
      else { expect((await result).single.product.mediaAssets.single.binding!.file.frameCount, 1); }
    });
  }
  Map<String, dynamic> descriptiveFacts() => {
    'schemaVersion': 1,
    'compliance': {
      'genericName': 'Host oil', 'netQuantity': '1 L', 'manufacturerName': 'Host maker',
      'manufacturerAddress': 'Host manufacturer address', 'packerName': null, 'packerAddress': null,
      'importerName': null, 'importerAddress': null, 'countryOfOrigin': 'India',
      'manufacturedOrPackedOn': 'See pack', 'bestBeforeOrUseBy': 'See pack',
      'fssaiLicenseNumber': 'Host descriptive licence', 'consumerCare': 'Host care details',
    },
    'composition': 'Host ingredients', 'regulatoryNote': 'Host pack directions', 'requiresPrescription': false,
  };
  test('LF-PRODUCE reviewed empty brand survives public mapping without a fabricated label', () {
    final data = publicPage()..['unbrandedProduceReadbackVersion'] = 1;
    (row(data)['content'] as Map)..['categoryId'] = 'fruits-vegetables'..['brand'] = '';
    final entry = WorkspacePublicCatalogueEntry.fromResponse(data,
      storeId: 'store-one', realm: 'production', channel: BuyV2OfferClass.retail, now: at);
    expect(entry.product.brand, isEmpty);
    expect(entry.product.categoryId, 'fruits-vegetables');
    expect(entry.product.sourceSkuId, 'sku-one');
    expect(entry.product.priceMinor, 26000);
    expect(entry.readback.content.state, BuyV2ProductContentState.ready);
  });
  final canonicalPublicLog = Platform.environment['LF03_CANONICAL_PUBLIC_LOG'];
  if (canonicalPublicLog != null) {
    test('LF03-BRAND actual emulator producer response decodes in the public client', () {
      const marker = 'LF03_CANONICAL_PUBLIC=';
      final captured = File(canonicalPublicLog).readAsLinesSync()
          .where((line) => line.contains(marker)).toList();
      expect(captured, hasLength(1));
      final data = jsonDecode(captured.single.split(marker).last) as Map<String, dynamic>;
      final entry = WorkspacePublicCatalogueEntry.fromResponse(data,
        storeId: data['storeId'] as String, realm: 'evaluation',
        channel: BuyV2OfferClass.retail, now: DateTime.parse(data['observedAt'] as String));
      expect(entry.product.brand, isEmpty);
      expect(entry.product.categoryId, 'fruits-vegetables');
      expect(entry.product.title, 'Cucumber');
      expect(entry.product.storeId, data['storeId']);
      expect(entry.product.sourceSkuId, 'sku-one');
      expect(entry.product.priceMinor, 5000);
      expect(entry.product.hasValidPackTerms, isTrue);
      expect(entry.product.manufacturerVerified, isFalse);
      expect((row(data)['content'] as Map).containsKey('brandId'), isFalse);
      expect(row(data).containsKey('brandId'), isFalse);
      expect(entry.readback.content.state, BuyV2ProductContentState.ready);
    });
  }
  test('LF-PRODUCE local owned record retains empty produce brand and listing intent exactly', () {
    final original = ownerRow();
    (original['content'] as Map)..['categoryId'] = 'fruits-vegetables'..['brand'] = '';
    final owned = WorkspaceCatalogueOwnedSku.decode(original,
      storeId: 'store-one', skuId: 'sku-one', realm: 'production', now: at);
    expect((owned.input['content'] as Map)['brand'], '');
    expect(owned.listingIntent(accountId: 'owner-one', listed: true,
      idempotencyKey: 'produce-intent').sku['content'], original['content']);
  });
  test('LF-FACTS exact public factory carries reviewed dedicated facts without losing pack or money', () {
    final data = publicPage()..['productFactsReadbackVersion'] = 1;
    (row(data)['content'] as Map)['productFacts'] = descriptiveFacts();
    final entry = WorkspacePublicCatalogueEntry.fromResponse(data,
      storeId: 'store-one', realm: 'production', channel: BuyV2OfferClass.retail, now: at);
    expect(entry.product.compliance?.manufacturerName, 'Host maker');
    expect(entry.product.compliance?.manufacturerAddress, 'Host manufacturer address');
    expect(entry.product.compliance?.countryOfOrigin, 'India');
    expect(entry.product.compliance?.manufacturedOrPackedOnLabel, 'See pack');
    expect(entry.product.composition, 'Host ingredients');
    expect(entry.product.regulatoryNote, 'Host pack directions');
    expect(entry.product.priceMinor, 26000);
    expect(entry.product.sourceSkuId, 'sku-one');
    expect(entry.product.hasValidPackTerms, isTrue);
    expect(entry.readback.content.state, BuyV2ProductContentState.ready);
  });
  test('PF06 reviewed appliance specifications reach the exact public SKU without invented fields', () {
    final data = publicPage();
    (row(data)['content'] as Map)..['categoryId'] = 'other'..['specifications'] = [
      {'label': 'Capacity', 'value': 'Host supplied 7 kg'},
      {'label': 'Electrical supply', 'value': 'Host supplied voltage and frequency'},
      {'label': 'Installation requirements', 'value': 'Host supplied clearance'},
    ];
    final entry = WorkspacePublicCatalogueEntry.fromResponse(data,
      storeId: 'store-one', realm: 'production', channel: BuyV2OfferClass.retail, now: at);
    expect(entry.readback.content.specifications.map((s) => [s.label, s.value]).toList(), [
      ['Capacity', 'Host supplied 7 kg'], ['Electrical supply', 'Host supplied voltage and frequency'],
      ['Installation requirements', 'Host supplied clearance'],
    ]);
    expect(entry.product.sourceSkuId, 'sku-one');
    expect(entry.product.priceMinor, 26000);
    expect(entry.readback.content.specifications.any((s) => s.label == 'Certification reference'), isFalse);
  });
  test('LF-FACTS owner record retains the exact reviewed extension through serialization', () {
    final original = ownerRow();
    (original['content'] as Map)['productFacts'] = descriptiveFacts();
    final owned = WorkspaceCatalogueOwnedSku.decode(original,
      storeId: 'store-one', skuId: 'sku-one', realm: 'production', now: at);
    expect((owned.input['content'] as Map)['productFacts'], descriptiveFacts());
  });
  test('LF-FACTS configured owner connection retains negotiated support across account binding', () async {
    final transport = OwnerTransport((body) async {
      expect(body['productFactsReadbackVersion'], 1);
      final record = ownerRow();
      (record['content'] as Map)['productFacts'] = descriptiveFacts();
      return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': {
        'schemaVersion': 1, 'realm': 'production', 'storeId': 'store-one',
        'productFactsReadbackVersion': 1, 'items': [record], 'nextCursor': null}}));
    });
    final owner = factsGateway(transport).forOwnerAccount('owner-one');
    expect(owner.productFactsReadbackSupported, isTrue);
    final result = await owner.readOwnedSku(storeId: 'store-one', skuId: 'sku-one', current: () => true);
    expect((result!.input['content'] as Map)['productFacts'], descriptiveFacts());
  });
  for (final version in [2, 1.0, '1', null]) {
    test('LF-FACTS unsupported advertised version rejects even absent facts $version ${version.runtimeType}', () async {
      final data = publicPage()..['productFactsReadbackVersion'] = version;
      expect(() => WorkspacePublicCatalogueEntry.fromResponse(data,
        storeId: 'store-one', realm: 'production', channel: BuyV2OfferClass.retail, now: at), throwsFormatException);
      expect((await gateway(Transport(data)).read(publicProduct())).content.state, BuyV2ProductContentState.unavailable);
      final owner = ownerGateway(OwnerTransport((body) async => SocialContentResponse(statusCode: 200,
        body: jsonEncode({'ok': true, 'data': {'schemaVersion': 1, 'realm': 'production', 'storeId': 'store-one',
          'items': [ownerRow()], 'nextCursor': null, 'productFactsReadbackVersion': version}}))));
      expect(await owner.readOwnedSku(storeId: 'store-one', skuId: 'sku-one', current: () => true), isNull);
    });
  }
  test('LF-FACTS cache does not reuse content after known facts change or disappear', () async {
    final data = publicPage()..['productFactsReadbackVersion'] = 1;
    (row(data)['content'] as Map)['productFacts'] = descriptiveFacts();
    final entry = WorkspacePublicCatalogueEntry.fromResponse(data,
      storeId: 'store-one', realm: 'production', channel: BuyV2OfferClass.retail, now: at);
    final transport = Transport(data), cache = WorkspaceCatalogueReadback(
      gateway: factsGateway(Transport(data)), context: () => 'host-facts-owner', now: () => at);
    addTearDown(cache.dispose);
    await cache.refresh(entry.product);
    expect(cache.snapshotFor(entry.product).state, BuyV2ProductContentState.ready);
    final changedData = jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
    ((row(changedData)['content'] as Map)['productFacts'] as Map)['composition'] = 'Changed host ingredients';
    final changed = WorkspacePublicCatalogueEntry.fromResponse(changedData,
      storeId: 'store-one', realm: 'production', channel: BuyV2OfferClass.retail, now: at).product;
    expect(cache.snapshotFor(changed).state, BuyV2ProductContentState.unavailable);
    expect((await factsGateway(transport).read(changed)).content.state, BuyV2ProductContentState.unavailable);
    (row(transport.data)['content'] as Map).remove('productFacts');
    expect((await factsGateway(transport).read(entry.product)).content.state, BuyV2ProductContentState.unavailable);
    transport.sent = null;
    expect((await gateway(transport).read(entry.product)).content.state, BuyV2ProductContentState.unavailable);
    expect(transport.sent, isNull, reason: 'Known enriched facts must not silently downgrade to a legacy request.');
  });
  for (final sourceFacts in ['matching', 'missing', 'changed']) {
    test('LF-FACTS Store listing checks exact dedicated facts $sourceFacts without changing Stock', () async {
      final source = SessionCatalogue(), work = listingSession(source, BindingStore());
      addTearDown(work.dispose);
      final facts = descriptiveFacts();
      work.workspaceCatalogueItems[0] = listingItem().copyWith(
        compliance: WorkspaceProductCompliance.fromJson(facts['compliance']),
        composition: facts['composition'] as String?, regulatoryNote: facts['regulatoryNote'] as String?);
      final original = (await source.ownerRead())!.toJson();
      if (sourceFacts != 'missing') {
        if (sourceFacts == 'changed') facts['composition'] = 'Different reviewed ingredients';
        (original['content'] as Map)['productFacts'] = facts;
      }
      source.ownerRead = () async => WorkspaceCatalogueOwnedSku.decode(original,
        storeId: 'store-one', skuId: 'sku-one', realm: 'production', now: at);
      source.write = (intent, current) async => listingSaved(intent);
      final before = work.workspaceCatalogueItems.single.toInventoryJson();
      expect(await work.toggleWorkspaceProductListing('sku-one'), sourceFacts == 'matching');
      expect(source.submitted, sourceFacts == 'matching' ? 1 : 0);
      expect(work.workspaceCatalogueItems.single.stock, 7);
      expect(work.workspaceStockMovements, isEmpty);
      if (sourceFacts != 'matching') expect(work.workspaceCatalogueItems.single.toInventoryJson(), before);
    });
  }
  test('LF-FACTS legacy public constructor leaves absent dedicated facts unknown', () {
    final entry = WorkspacePublicCatalogueEntry.fromResponse(publicPage(),
      storeId: 'store-one', realm: 'production', channel: BuyV2OfferClass.retail, now: at);
    expect(entry.product.compliance, isNull);
    expect(entry.product.composition, isNull);
    expect(entry.product.regulatoryNote, isNull);
  });
  for (final malformed in ['unnegotiated', 'version', 'extra', 'boolean', 'private']) {
    test('LF-FACTS public constructor rejects malformed descriptive extension $malformed', () {
      final data = publicPage()..['productFactsReadbackVersion'] = 1;
      final facts = descriptiveFacts();
      if (malformed == 'unnegotiated') data.remove('productFactsReadbackVersion');
      if (malformed == 'version') facts['schemaVersion'] = 2;
      if (malformed == 'extra') facts['other'] = 'unknown';
      if (malformed == 'boolean') facts['requiresPrescription'] = 'false';
      if (malformed == 'private') (facts['compliance'] as Map)['purchaseCost'] = '20';
      (row(data)['content'] as Map)['productFacts'] = facts;
      expect(() => WorkspacePublicCatalogueEntry.fromResponse(data,
        storeId: 'store-one', realm: 'production', channel: BuyV2OfferClass.retail, now: at), throwsFormatException);
    });
  }
  test('LF-LISTING source binding roundtrip and copy preserve legacy identities without authority', () {
    final identity = publicIdentity(), selected = publicProduct();
    expect(BuyV2PublicListingIdentity.fromJson(identity.toJson()), identity);
    expect(selected.hasValidPublicListingIdentity, isTrue); expect(selected.sourceSkuId, 'sku-one');
    expect(selected.copyWith(title: 'Updated display').publicListingIdentity, identity);
    expect(selected.copyWith(id: 'different-listing').hasValidPublicListingIdentity, isFalse);
    expect(selected.copyWith(storeId: 'different-store').hasValidPublicListingIdentity, isFalse);
    expect(selected.copyWith(canonicalId: 'different-product').hasValidPublicListingIdentity, isFalse);
    expect(selected.copyWith(offerClass: BuyV2OfferClass.bulk).hasValidPublicListingIdentity, isFalse);
    expect(product.hasValidPublicListingIdentity, isTrue); expect(product.sourceSkuId, product.id);
    for (final raw in [
      {...identity.toJson(), 'schemaVersion': 1.0}, {...identity.toJson(), 'extra': true},
      {...identity.toJson(), 'realm': 'unknown'}, {...identity.toJson(), 'storeId': 'store-one\n'},
      {...identity.toJson(), 'channel': 'unknown'}, {...identity.toJson(), 'listingId': 'sku-one'},
    ]) { expect(BuyV2PublicListingIdentity.fromJson(raw), isNull); }
  });
  test('LF-FACTORY bound pack cannot omit known source pricing metadata', () {
    final selected = publicProduct();
    final terms = BuyV2PackTerms(skuId: selected.id, revision: 'term-one', sellUnit: '1 L');
    expect(selected.copyWith(packTerms: terms).hasValidPackTerms, isFalse);
    expect(product.copyWith(packTerms: BuyV2PackTerms(skuId: product.id,
      revision: 'term-one', sellUnit: '1 L')).hasValidPackTerms, isTrue);
  });
  test('LF-FACTORY fixed-price freshness cannot ignore supplied expiry', () {
    final terms = BuyV2PackTerms(skuId: 'sku-one', revision: 'term-one', sellUnit: '1 L',
      pricingStoreId: 'store-one', priceObservedAt: at.subtract(const Duration(hours: 1)),
      priceValidUntil: at);
    expect(terms.pricingCurrentAt(at), isFalse);
  });
  WorkspacePublicCatalogueEntry factoryEntry(Map<String, dynamic> data,
    {BuyV2OfferClass channel = BuyV2OfferClass.retail}) =>
      WorkspacePublicCatalogueEntry.fromResponse(data, storeId: 'store-one',
        realm: 'production', channel: channel, now: at);
  WorkspacePublicStockQuery stockPublicQuery(Map<String, Object?> body) => WorkspacePublicStockQuery(realm: 'production',
    storeId: body['storeId'] as String, binding: Map<String, dynamic>.from(body['binding'] as Map), requestedPacks: body['requestedPacks'] as int);
  AuthenticatedWorkspaceCatalogueGateway publicStockApi(OwnerTransport transport, {DateTime Function()? clock, bool enabled = true, bool discovery = false}) =>
    AuthenticatedWorkspaceCatalogueGateway(endpoint: Uri.parse('https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
      credentials: Credentials(), transport: transport, realm: 'production', stockSnapshotsSupported: enabled, now: clock ?? () => at,
      productFactsReadbackSupported: discovery, unbrandedProduceReadbackSupported: discovery, storeClassificationReadbackSupported: discovery);
  SocialContentResponse stockPublicResponse(WorkspacePublicStockQuery query, {int revision = 1, bool unknown = false,
    bool available = true, bool? quantityAvailable = true}) {
    final data = publicStockReply(query, unknown: unknown);
    if (!unknown) { (data['stock'] as Map<String, dynamic>).addAll({'reportRevision': revision, 'available': available, 'quantityAvailable': quantityAvailable}); }
    return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': data}));
  }
  test('LF11 public Stock cache getters never read and identical explicit queries coalesce', () async {
    final entry = factoryEntry(publicPage()), response = Completer<SocialContentResponse>();
    final transport = OwnerTransport((_) => response.future);
    final reader = WorkspacePublicStockReader(gateway: publicStockApi(transport), displayed: (_) => entry.readback, current: () => true, now: () => at);
    addTearDown(reader.dispose);
    for (var i = 0; i < 40; i++) {
      expect(reader.requestIdentity(entry.product, 1), isNotNull); expect(reader.snapshotFor(entry.product, 1), isNull);
    }
    expect(transport.calls, 0);
    final first = reader.refresh(entry.product, 1), same = reader.refresh(entry.product, 1);
    expect(identical(first, same), true); await Future<void>.delayed(Duration.zero); expect(transport.calls, 1);
    response.complete(stockPublicResponse(WorkspacePublicStockQuery.fromEntry(entry, 1)));
    expect(await first, true); expect(reader.snapshotFor(entry.product, 1)!.quantityAvailable, true);
    expect(await reader.refresh(entry.product, 1), true); expect(transport.calls, 1);
  });
  test('LF11 public Stock cache drops late quantity and revision replies', () async {
    final entry = factoryEntry(publicPage()), held = Completer<SocialContentResponse>();
    final transport = OwnerTransport((body) async {
      final query = stockPublicQuery(body);
      return query.requestedPacks == 1 ? held.future : stockPublicResponse(query, quantityAvailable: false);
    });
    final reader = WorkspacePublicStockReader(gateway: publicStockApi(transport), displayed: (_) => entry.readback, current: () => true, now: () => at);
    addTearDown(reader.dispose);
    final old = reader.refresh(entry.product, 1); await Future<void>.delayed(Duration.zero);
    expect(await reader.refresh(entry.product, 8), true);
    held.complete(stockPublicResponse(WorkspacePublicStockQuery.fromEntry(entry, 1)));
    expect(await old, false); expect(reader.snapshotFor(entry.product, 1), isNull);
    expect(reader.snapshotFor(entry.product, 8)!.quantityAvailable, false);
  });
  test('LF11 public Stock cache fences changed binding, unavailable readback and retired lifetime', () async {
    final entry = factoryEntry(publicPage()), held = Completer<SocialContentResponse>(); var displayed = entry.readback;
    final transport = OwnerTransport((_) => held.future);
    final reader = WorkspacePublicStockReader(gateway: publicStockApi(transport), displayed: (_) => displayed, current: () => true, now: () => at);
    final original = reader.refresh(entry.product, 1); await Future<void>.delayed(Duration.zero);
    displayed = WorkspaceCatalogueContentResult(content: entry.readback.content, skuRevision: entry.readback.skuRevision! + 1,
      validUntil: entry.readback.validUntil);
    held.complete(stockPublicResponse(WorkspacePublicStockQuery.fromEntry(entry, 1)));
    expect(await original, false); expect(reader.snapshotFor(entry.product, 1), isNull); reader.dispose();
    final blocked = WorkspacePublicStockReader(gateway: publicStockApi(transport), displayed: (_) => null, current: () => true, now: () => at);
    expect(await blocked.refresh(entry.product, 1), false); blocked.dispose();
    final pending = Completer<SocialContentResponse>(), retiredTransport = OwnerTransport((_) => pending.future);
    final retired = WorkspacePublicStockReader(gateway: publicStockApi(retiredTransport), displayed: (_) => entry.readback, current: () => true, now: () => at);
    final late = retired.refresh(entry.product, 1); await Future<void>.delayed(Duration.zero); retired.dispose();
    pending.complete(stockPublicResponse(WorkspacePublicStockQuery.fromEntry(entry, 1)));
    expect(await late, false); expect(retired.snapshotFor(entry.product, 1), isNull);
  });
  test('LF11 public Stock cache fresh-zero and availability-only remain distinct; unknown/failure clears positives', () async {
    final entry = factoryEntry(publicPage()); var mode = 'positive';
    final transport = OwnerTransport((body) async {
      if (mode == 'failure') throw StateError('isolated unavailable source');
      return stockPublicResponse(stockPublicQuery(body), unknown: mode == 'unknown', available: mode != 'zero',
        quantityAvailable: mode == 'zero' ? false : mode == 'uncounted' ? null : true);
    });
    final reader = WorkspacePublicStockReader(gateway: publicStockApi(transport), displayed: (_) => entry.readback, current: () => true, now: () => at);
    addTearDown(reader.dispose);
    expect(await reader.refresh(entry.product, 1), true);
    mode = 'failure'; expect(await reader.refresh(entry.product, 1, force: true), false); expect(reader.snapshotFor(entry.product, 1), isNull);
    mode = 'zero'; expect(await reader.refresh(entry.product, 1), false, reason: 'Same revision cannot change immutable source facts.');
    final zero = WorkspacePublicStockReader(gateway: publicStockApi(transport), displayed: (_) => entry.readback, current: () => true, now: () => at);
    addTearDown(zero.dispose); expect(await zero.refresh(entry.product, 1), true); expect(zero.snapshotFor(entry.product, 1)!.available, false);
    mode = 'uncounted'; final uncounted = WorkspacePublicStockReader(gateway: publicStockApi(transport), displayed: (_) => entry.readback, current: () => true, now: () => at);
    addTearDown(uncounted.dispose); expect(await uncounted.refresh(entry.product, 1), true); expect(uncounted.snapshotFor(entry.product, 1)!.quantityAvailable, isNull);
    mode = 'unknown'; expect(await uncounted.refresh(entry.product, 1, force: true), false); expect(uncounted.snapshotFor(entry.product, 1), isNull);
  });
  test('LF11 public Stock cache high-water spans quantities and expiry notifies without interaction', () async {
    final entry = factoryEntry(publicPage()); var revision = 2, clock = at.add(const Duration(minutes: 4, seconds: 59));
    final transport = OwnerTransport((body) async => stockPublicResponse(stockPublicQuery(body), revision: revision));
    final reader = WorkspacePublicStockReader(gateway: publicStockApi(transport, clock: () => clock), displayed: (_) => entry.readback, current: () => true, now: () => clock);
    addTearDown(reader.dispose); var changes = 0; reader.addListener(() => changes++);
    expect(await reader.refresh(entry.product, 1), true); revision = 1;
    expect(await reader.refresh(entry.product, 2), false); expect(reader.snapshotFor(entry.product, 1), isNull);
    revision = 3; expect(await reader.refresh(entry.product, 1), true); final before = changes;
    clock = at.add(const Duration(minutes: 5)); await Future<void>.delayed(const Duration(milliseconds: 1050));
    expect(changes, greaterThan(before)); expect(reader.snapshotFor(entry.product, 1), isNull);
    expect(reader.requestIdentity(entry.product.copyWith(storeId: 'other-store'), 1), isNull);
  });
  test('LF11 public Stock refresh retains fresh shortage while the original response is pending', () async {
    final entry = factoryEntry(publicPage()), pending = Completer<SocialContentResponse>(); var hold = false;
    final transport = OwnerTransport((body) async => hold ? pending.future : stockPublicResponse(stockPublicQuery(body), quantityAvailable: false));
    final reader = WorkspacePublicStockReader(gateway: publicStockApi(transport), displayed: (_) => entry.readback, current: () => true, now: () => at);
    addTearDown(reader.dispose);
    expect(await reader.refresh(entry.product, 1), true); hold = true;
    final refreshing = reader.refresh(entry.product, 1, force: true); await Future<void>.delayed(Duration.zero);
    expect(reader.snapshotFor(entry.product, 1)!.quantityAvailable, false);
    pending.complete(stockPublicResponse(WorkspacePublicStockQuery.fromEntry(entry, 1), revision: 2));
    expect(await refreshing, true); expect(reader.snapshotFor(entry.product, 1)!.quantityAvailable, true);
  });
  test('LF11 public Stock unknown retires an older sibling listing response for the same SKU', () async {
    final page = publicPage(trade: true), retail = factoryEntry(page), trade = factoryEntry(page, channel: BuyV2OfferClass.wholesale);
    final old = Completer<SocialContentResponse>();
    final transport = OwnerTransport((body) async => (body['requestedPacks'] as int) == 1 ? old.future : stockPublicResponse(stockPublicQuery(body), unknown: true));
    final reader = WorkspacePublicStockReader(gateway: publicStockApi(transport),
      displayed: (p) => p.id == retail.product.id ? retail.readback : trade.readback, current: () => true, now: () => at);
    addTearDown(reader.dispose);
    final pending = reader.refresh(retail.product, 1); await Future<void>.delayed(Duration.zero);
    expect(await reader.refresh(trade.product, trade.product.minimumOrder), false);
    old.complete(stockPublicResponse(WorkspacePublicStockQuery.fromEntry(retail, 1)));
    expect(await pending, false); expect(reader.snapshotFor(retail.product, 1), isNull);
    expect(await reader.refresh(retail.product, 2), false);
  });
  test('LF11 public Stock physical read pool is bounded and never dispatches retired queued quantities', () async {
    final entry = factoryEntry(publicPage()), held = <int, Completer<SocialContentResponse>>{};
    var running = 0, peak = 0;
    final transport = OwnerTransport((body) async {
      final packs = body['requestedPacks'] as int; running++; if (running > peak) peak = running;
      final response = Completer<SocialContentResponse>(); held[packs] = response;
      try { return await response.future; } finally { running--; }
    });
    final reader = WorkspacePublicStockReader(gateway: publicStockApi(transport), displayed: (_) => entry.readback, current: () => true, now: () => at);
    final requests = <Future<bool>>[];
    for (var packs = 1; packs <= 8; packs++) { requests.add(reader.refresh(entry.product, packs)); await Future<void>.delayed(Duration.zero); }
    expect(held.keys, [1, 2, 3]); expect(peak, 3);
    held[1]!.complete(stockPublicResponse(WorkspacePublicStockQuery.fromEntry(entry, 1))); await Future<void>.delayed(Duration.zero);
    expect(held.keys, [1, 2, 3, 8]); expect(peak, 3);
    for (final packs in [2, 3, 8]) { held[packs]!.complete(stockPublicResponse(WorkspacePublicStockQuery.fromEntry(entry, packs))); }
    expect((await Future.wait(requests)).where((v) => v), [true]); reader.dispose();
    final blocked = Completer<SocialContentResponse>(), disposedApi = OwnerTransport((_) => blocked.future);
    final disposed = WorkspacePublicStockReader(gateway: publicStockApi(disposedApi), displayed: (_) => entry.readback, current: () => true, now: () => at);
    final closing = <Future<bool>>[];
    for (var packs = 1; packs <= 5; packs++) { closing.add(disposed.refresh(entry.product, packs)); await Future<void>.delayed(Duration.zero); }
    disposed.dispose(); blocked.complete(stockPublicResponse(WorkspacePublicStockQuery.fromEntry(entry, 1)));
    expect(await Future.wait(closing), everyElement(false)); expect(disposedApi.calls, 3);
  });
  for (final contradiction in [false, true]) {
    test('LF11 public Stock rejected head retires sibling flight contradiction=$contradiction', () async {
      final data = publicPage(trade: true), retail = factoryEntry(data), trade = factoryEntry(data, channel: BuyV2OfferClass.wholesale);
      final held = Completer<SocialContentResponse>(); var first = true;
      final reader = WorkspacePublicStockReader(gateway: publicStockApi(OwnerTransport((body) async {
        final query = stockPublicQuery(body);
        if (first) { first = false; return stockPublicResponse(query, revision: 2); }
        if (query.requestedPacks == 1) return held.future;
        return stockPublicResponse(query, revision: contradiction ? 2 : 1, available: !contradiction, quantityAvailable: !contradiction);
      })), displayed: (p) => p.id == retail.product.id ? retail.readback : trade.readback, current: () => true, now: () => at);
      addTearDown(reader.dispose); expect(await reader.refresh(retail.product, 1), true);
      final pending = reader.refresh(retail.product, 1, force: true); await Future<void>.delayed(Duration.zero);
      expect(await reader.refresh(trade.product, trade.product.minimumOrder), false);
      held.complete(stockPublicResponse(WorkspacePublicStockQuery.fromEntry(retail, 1), revision: 2));
      expect(await pending, false); expect(reader.snapshotFor(retail.product, 1), isNull);
    });
  }
  test('LF-FACTORY exact source facts and empty tiers retain real fixed-price freshness', () {
    final entry = factoryEntry(publicPage()), value = entry.product, pack = value.packTerms!;
    expect(value.id, publicIdentity().listingId); expect(value.sourceSkuId, 'sku-one');
    expect(value.pack, '1 L'); expect(pack.label, '1 L'); expect(pack.contentUnit, 'L');
    expect(pack.netContentMilli, 1000); expect(pack.containedUnits, 1);
    expect(pack.priceTiers, isEmpty); expect(pack.priceObservedAt, at.subtract(const Duration(hours: 1)));
    expect(pack.priceValidUntil, at.add(const Duration(hours: 1)));
    expect(pack.pricingCurrentAt(at), isTrue); expect(value.hasValidPackTerms, isTrue);
    expect(pack.pricesIncludeTax, isNull); expect(pack.pricesIncludeFreight, isNull);
    expect(value.price, 260); expect(value.mrp, 280); expect(value.seller, 'Host Store');
    expect(value.deliveryPromise, isEmpty); expect(value.manufacturerVerified, isFalse);
    expect(value.reviewDeliveryOptions, isEmpty); expect(value.procurementSupplierGrant, isNull);
    expect(entry.readback.content.supplierPolicy!.productIds, {'sku-one'});
    expect(product.copyWith(packTerms: BuyV2PackTerms(skuId: product.id, revision: 'term-one',
      sellUnit: 'pack', sourceLabel: '1 L')).hasValidPackTerms, isFalse);
  });
  test('LF-FACTORY exact source pack conversion keeps label case count and tier basis', () {
    final data = publicPage(trade: true), source = row(data);
    source['pack'] = {'label': 'Four bottles, total 1.001 L', 'quantityMilli': 1001,
      'unit': 'L', 'unitsPerCase': 4};
    final trade = (source['channels'] as List)[1] as Map;
    trade['quantityStep'] = 5;
    trade['tiers'] = [{'minimumQuantity': 10, 'unitPriceMinor': 25000},
      {'minimumQuantity': 20, 'unitPriceMinor': 24000}];
    final value = factoryEntry(data, channel: BuyV2OfferClass.wholesale).product, pack = value.packTerms!;
    expect(value.pack, 'Four bottles, total 1.001 L'); expect(pack.contentUnit, 'mL');
    expect(pack.netContentMilli, 250250); expect(pack.containedUnits, 4);
    expect(value.minimumOrder, 10); expect(value.quantityStep, 5);
    expect(pack.priceForQuantity(20, value.price), 240); expect(value.hasValidPackTerms, isTrue);
  });
  for (final channel in [BuyV2OfferClass.retail, BuyV2OfferClass.wholesale]) {
    test('LF-FACTORY exact paise base MRP and tiers retain public authority boundaries ${channel.name}', () async {
      final data = publicPage(trade: channel != BuyV2OfferClass.retail);
      final terms = (row(data)['channels'] as List).cast<Map>().singleWhere((t) => t['kind'] == channel.name);
      final price = channel == BuyV2OfferClass.retail ? 26025 : 25025;
      final minimum = terms['minimumOrder'] as int;
      terms['priceMinor'] = price; terms['mrpMinor'] = 28050;
      terms['tiers'] = [{'minimumQuantity': minimum, 'unitPriceMinor': price},
        {'minimumQuantity': minimum * 2, 'unitPriceMinor': price - 115}];
      final entry = factoryEntry(data, channel: channel), value = entry.product;
      expect(value.priceMinor, price); expect(value.mrpMinor, 28050);
      expect(() => value.price, throwsFormatException);
      expect(value.packTerms!.priceMinorForQuantity(minimum * 2, value.priceMinor), price - 115);
      expect(value.sourceSkuId, 'sku-one'); expect(value.hasValidPackTerms, isTrue);
      expect(value.publicListingIdentity!.channel, channel);
      expect(value.reviewDeliveryOptions, isEmpty);
      expect(entry.readback.content.state, BuyV2ProductContentState.ready);
      final found = await gateway(Transport(data)).readPublicEntry(storeId: 'store-one',
        skuId: 'sku-one', channel: channel, current: () => true);
      expect(found!.product.priceMinor, price);
      expect(data['orderingAvailable'], isFalse);
    });
  }
  for (final change in ['tier paise', 'fraction count', 'inexact volume',
    'wrong store', 'wrong realm', 'wrong binding', 'partial', 'unavailable', 'expired', 'future', 'missing policy']) {
    test('LF-FACTORY rejects unsupported or unconfirmed source $change', () {
      final data = publicPage(), source = row(data), terms = (source['channels'] as List).single as Map;
      if (change == 'tier paise') terms['tiers'] = [{'minimumQuantity': 1, 'unitPriceMinor': 26001}];
      if (change == 'fraction count') {
        source['pack'] = {'label': 'one piece', 'quantityMilli': 1000, 'unit': 'count', 'unitsPerCase': 2};
      }
      if (change == 'inexact volume') {
        source['pack'] = {'label': 'three bottles', 'quantityMilli': 1000, 'unit': 'L', 'unitsPerCase': 3};
      }
      if (change == 'wrong store') data['storeId'] = 'other-store';
      if (change == 'wrong realm') data['realm'] = 'evaluation';
      if (change == 'wrong binding') (source['listings'] as List).single['verifiedPackId'] = 'wrong-pack';
      if (change == 'partial') data['listingCoverage'] = 'partial';
      if (change == 'unavailable') data['state'] = 'unavailable';
      if (change == 'expired') terms['validUntil'] = at.toIso8601String();
      if (change == 'future') source['observedAt'] = at.add(const Duration(minutes: 1)).toIso8601String();
      if (change == 'missing policy') source.remove('supplierPolicy');
      expect(() => factoryEntry(data), throwsFormatException);
    });
  }
  test('LF-FACTORY bound fixed-price metadata is complete and legacy labels remain derived', () {
    final selected = publicProduct();
    BuyV2PackTerms terms({String? store = 'store-one', DateTime? observed,
      DateTime? expiry}) => BuyV2PackTerms(skuId: selected.id, revision: 'term-one',
        sellUnit: 'bottle', sourceLabel: 'Reviewed one litre', netContentMilli: 1000, contentUnit: 'L',
        pricingStoreId: store, priceObservedAt: observed, priceValidUntil: expiry);
    expect(selected.copyWith(packTerms: terms(observed: at, expiry: at.add(const Duration(hours: 1))))
      .hasValidPackTerms, isTrue);
    expect(selected.copyWith(packTerms: terms(observed: at)).hasValidPackTerms, isFalse);
    expect(selected.copyWith(packTerms: terms(store: null, observed: at,
      expiry: at.add(const Duration(hours: 1)))).hasValidPackTerms, isFalse);
    expect(terms(observed: at.add(const Duration(minutes: 1)), expiry: at.add(const Duration(hours: 1)))
      .pricingCurrentAt(at), isFalse);
    expect(const BuyV2PackTerms(skuId: 'sku-one', revision: 'term-one', sellUnit: 'bottle',
      netContentMilli: 1000, contentUnit: 'L').label, '1 L · bottle');
  });
  test('LF-FACTORY authenticated discovery uses original source SKU and real response identity', () async {
    final transport = Transport(publicPage()), credentials = Credentials();
    final entry = await gateway(transport, credentials).readPublicEntry(storeId: 'store-one',
      skuId: 'sku-one', channel: BuyV2OfferClass.retail, current: () => true);
    expect(entry!.product.id, publicIdentity().listingId);
    expect(transport.sent, {'operation': 'readPublicStoreCatalogue', 'storeId': 'store-one',
      'skuId': 'sku-one', 'listingReadbackVersion': 1, 'mediaReadbackVersion': 1, 'policyReadbackVersion': 1,
      'storeDetailsReadbackVersion': 1});
    expect(credentials.modes, [SocialAppCheckTokenMode.standard]);
    expect(await gateway(transport).readPublicEntry(storeId: 'store-one', skuId: 'other-sku',
      channel: BuyV2OfferClass.retail, current: () => true), isNull);
    transport.sent = null;
    expect(await gateway(transport).readPublicEntry(storeId: 'store-one', skuId: 'sku-one',
      channel: BuyV2OfferClass.retail, current: () => false), isNull);
    expect(transport.sent, isNull);
  });
  test('LF-FACTORY discovery rejects a response after account lifetime retires', () async {
    var current = true;
    final pending = Completer<SocialContentResponse>();
    final sent = Completer<void>();
    final source = AuthenticatedWorkspaceCatalogueGateway(endpoint: Uri.parse(
      'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
      credentials: Credentials(), now: () => at,
      transport: OwnerTransport((body) { sent.complete(); return pending.future; }));
    final result = source.readPublicEntry(storeId: 'store-one', skuId: 'sku-one',
      channel: BuyV2OfferClass.retail, current: () => current);
    await sent.future; current = false;
    pending.complete(SocialContentResponse(statusCode: 200,
      body: jsonEncode({'ok': true, 'data': publicPage()})));
    expect(await result, isNull);
  });
  BuyV2CatalogueQuery storeQuery({String search = ''}) => BuyV2CatalogueQuery(
    destination: BuyV2Destination.shop, regionId: null, areaScope: BuyV2CatalogueAreaScope.allAreas,
    storeId: 'store-one', query: search);
  Map<String, dynamic> pageData(Map<String, Object?> body, {bool empty = false}) {
    final data = jsonDecode(jsonEncode(publicPage())) as Map<String, dynamic>, source = row(data);
    return {...data, 'cataloguePageVersion': 1, 'query': body['query'],
      'items': [if (!empty) {'channel': 'retail', 'row': source}], 'nextCursor': null,
      'page': {'snapshotId': 'c' * 64, 'startIndex': 0, 'totalCount': empty ? 0 : 1,
        'previousCursor': null, 'nextCursor': null}};
  }
  test('LF-MONEY2 Store pager preserves paise and owner clones negotiate the same contract', () async {
    final transport = OwnerTransport((body) async {
      expect(body['cataloguePageVersion'], 2);
      final data = pageData(body)..['cataloguePageVersion'] = 2..['moneyUnit'] = 'paise';
      final terms = (((data['items'] as List).single['row'] as Map)['channels'] as List).single as Map;
      terms['priceMinor'] = 26025; terms['mrpMinor'] = 28050;
      return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': data}));
    });
    final gateway = AuthenticatedWorkspaceCatalogueGateway(endpoint: Uri.parse(
      'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
      credentials: Credentials(), transport: transport, now: () => at, minorMoneyReadbackSupported: true);
    final source = WorkspaceStoreCatalogueSource(storeId: 'store-one', current: () => true, gateway: gateway.forOwnerAccount('owner-one'));
    expect(source.gateway.minorMoneyReadbackSupported, isTrue);
    final product = (await source.loadProducts(storeQuery(), pageSize: 40)).items.single;
    expect(product.priceMinor, 26025); expect(product.mrpMinor, 28050);
  });
  for (final failure in ['missing unit', 'wrong unit', 'downgrade', 'double version', 'unsolicited']) {
    test('LF-MONEY2 Store pager rejects $failure without admission', () async {
      final transport = OwnerTransport((body) async {
        final data = pageData(body)..['cataloguePageVersion'] = 2..['moneyUnit'] = 'paise';
        if (failure == 'missing unit') data.remove('moneyUnit');
        if (failure == 'wrong unit') data['moneyUnit'] = 'INR';
        if (failure == 'downgrade') data['cataloguePageVersion'] = 1;
        if (failure == 'double version') data['cataloguePageVersion'] = 2.0;
        return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': data}));
      });
      final gateway = AuthenticatedWorkspaceCatalogueGateway(endpoint: Uri.parse(
        'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
        credentials: Credentials(), transport: transport, now: () => at, minorMoneyReadbackSupported: failure != 'unsolicited');
      final source = WorkspaceStoreCatalogueSource(storeId: 'store-one', current: () => true, gateway: gateway);
      await expectLater(source.loadProducts(storeQuery(), pageSize: 40), throwsFormatException);
    });
  }
  AuthenticatedWorkspaceCatalogueGateway pageGateway(OwnerTransport transport) =>
    AuthenticatedWorkspaceCatalogueGateway(endpoint: Uri.parse(
      'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
      credentials: Credentials(), transport: transport, now: () => at);
  Map<String, dynamic> producePage() {
    final data = publicPage()..['unbrandedProduceReadbackVersion'] = 1;
    (row(data)['content'] as Map)..['categoryId'] = 'fruits-vegetables'..['brand'] = '';
    return data;
  }
  AuthenticatedWorkspaceCatalogueGateway produceGateway(SocialContentTransport transport) =>
    AuthenticatedWorkspaceCatalogueGateway(endpoint: Uri.parse(
      'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
      credentials: Credentials(), transport: transport, now: () => at,
      unbrandedProduceReadbackSupported: true);
  test('LF-PRODUCE promotion resolves the negotiated public SKU without changing promotion envelope', () async {
    final transport = OwnerTransport((body) async {
      if (body['operation'] == 'readPublicStorePromotions') {
        expect(body.containsKey('unbrandedProduceReadbackVersion'), isFalse);
        final publication = promotionRow();
        publication['product'] = row(producePage())..remove('listings');
        return SocialContentResponse(statusCode: 200,
          body: jsonEncode({'ok': true, 'data': promotionPage([publication])}));
      }
      expect(body['unbrandedProduceReadbackVersion'], 1);
      return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': producePage()}));
    });
    final source = WorkspaceStoreCatalogueSource(gateway: produceGateway(transport),
      storeId: 'store-one', current: () => true);
    final offers = await source.loadStoreOffers(storeId: 'store-one', destination: BuyV2Destination.shop);
    expect(offers.single.product.brand, '');
    expect(offers.single.product.sourceSkuId, 'sku-one');
    expect(offers.single.product.priceMinor, 26000);
  });
  for (final version in [null, 2, 1.0, '1']) {
    test('LF-PRODUCE missing or malformed version cannot admit blank public brand $version ${version.runtimeType}', () async {
      final data = producePage();
      if (version == null) { data.remove('unbrandedProduceReadbackVersion'); }
      else { data['unbrandedProduceReadbackVersion'] = version; }
      expect(() => WorkspacePublicCatalogueEntry.fromResponse(data,
        storeId: 'store-one', realm: 'production', channel: BuyV2OfferClass.retail, now: at), throwsFormatException);
      final entry = WorkspacePublicCatalogueEntry.fromResponse(producePage(),
        storeId: 'store-one', realm: 'production', channel: BuyV2OfferClass.retail, now: at);
      expect((await produceGateway(Transport(data)).read(entry.product)).content.state,
        BuyV2ProductContentState.unavailable);
    });
  }
  for (final bad in ['', ' ', 7, null]) {
    test('LF-PRODUCE nonproduce empty and malformed brands stay invalid $bad ${bad.runtimeType}', () {
      final data = producePage();
      (row(data)['content'] as Map)..['categoryId'] = bad == '' ? 'electronics' : 'fruits-vegetables'..['brand'] = bad;
      expect(() => WorkspacePublicCatalogueEntry.fromResponse(data,
        storeId: 'store-one', realm: 'production', channel: BuyV2OfferClass.retail, now: at), throwsFormatException);
    });
  }
  test('LF-PRODUCE owner clone negotiates exact optional-brand record without changing its intent', () async {
    final record = ownerRow();
    (record['content'] as Map)..['categoryId'] = 'fruits-vegetables'..['brand'] = '';
    final transport = OwnerTransport((body) async {
      expect(body['unbrandedProduceReadbackVersion'], 1);
      return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': {
        'schemaVersion': 1, 'realm': 'production', 'storeId': 'store-one', 'items': [record],
        'nextCursor': null, 'unbrandedProduceReadbackVersion': 1}}));
    });
    final owner = produceGateway(transport).forOwnerAccount('owner-one');
    expect(owner.unbrandedProduceReadbackSupported, isTrue);
    final saved = await owner.readOwnedSku(storeId: 'store-one', skuId: 'sku-one', current: () => true);
    expect((saved!.input['content'] as Map)['brand'], '');
  });
  test('LF-PRODUCE direct content and paged public readers propagate negotiated capability', () async {
    final transport = OwnerTransport((body) async {
      expect(body['unbrandedProduceReadbackVersion'], 1);
      final data = producePage();
      if (body.containsKey('cataloguePageVersion')) {
        final record = row(data);
        data.addAll({'cataloguePageVersion': 1, 'query': body['query'],
          'items': [{'channel': 'retail', 'row': record}], 'nextCursor': null,
          'page': {'snapshotId': 'c' * 64, 'startIndex': 0, 'totalCount': 1,
            'previousCursor': null, 'nextCursor': null}});
      }
      return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': data}));
    });
    final connection = produceGateway(transport);
    final entry = await connection.readPublicEntry(storeId: 'store-one', skuId: 'sku-one',
      channel: BuyV2OfferClass.retail, current: () => true);
    expect(entry!.product.brand, '');
    expect((await connection.read(entry.product)).content.state, BuyV2ProductContentState.ready);
    final source = WorkspaceStoreCatalogueSource(gateway: connection, storeId: 'store-one', current: () => true);
    final page = await source.loadProducts(storeQuery(), pageSize: 10);
    expect(page.items.single.brand, '');
    expect(page.totalCount, 1);
  });
  test('LF-PRODUCE legacy connection cannot accept unsolicited capability or start a blank-brand binding', () async {
    final transport = Transport(producePage());
    expect(await gateway(transport).readPublicEntry(storeId: 'store-one', skuId: 'sku-one',
      channel: BuyV2OfferClass.retail, current: () => true), isNull);
    final record = ownerRow();
    (record['content'] as Map)..['categoryId'] = 'fruits-vegetables'..['brand'] = '';
    final original = WorkspaceCatalogueOwnedSku.decode(record,
      storeId: 'store-one', skuId: 'sku-one', realm: 'production', now: at)
      .listingIntent(accountId: 'owner-one', listed: true, idempotencyKey: 'produce-original');
    final ownerTransport = OwnerTransport((body) async => ownerAck(body));
    final owner = ownerGateway(ownerTransport);
    expect((await owner.bindReviewed(original, current: () => true, recoveringUnknown: false)).state,
      WorkspaceCatalogueBindingState.notSent);
    expect(ownerTransport.calls, 0);
    // Read-only recovery of an original attempt must not become a new write.
    expect((await owner.reconcileBinding(original, current: () => true)).state, WorkspaceCatalogueBindingState.saved);
    expect(ownerTransport.calls, 1);
  });
  WorkspaceReviewedVariantMembership reviewedMember(WorkspacePublicCatalogueEntry entry,
    {int revision = 1, DateTime? expiry, String? familyId = 'host-reviewed-family', String colour = 'pink'}) =>
    WorkspaceReviewedVariantMembership(listing: entry.product.publicListingIdentity!,
      skuRevision: entry.readback.skuRevision!, catalogueVersion: entry.readback.catalogueVersion!,
      familyId: familyId, sourceId: 'host-reviewed-associations', revision: revision,
      observedAt: at, validUntil: expiry ?? at.add(const Duration(minutes: 30)), attributes: [
        if (familyId != null) BuyV2VariantAttribute(dimensionId: 'colour', dimensionLabel: 'Colour',
          optionId: colour, optionLabel: colour, kind: BuyV2VariantDimensionKind.colour),
      ]);
  test('LF03 PUBLIC-FAMILY direct page resolve and owner clone use the same reviewed association', () async {
    final reader = HostReviewedVariantSource(memberships: (entries, current) async =>
      entries.map((entry) => reviewedMember(entry)).toList());
    final transport = OwnerTransport((body) async {
      expect(body['operation'], 'readPublicStoreCatalogue');
      expect(body.containsKey('variantFamilyReadbackVersion'), isFalse,
        reason: 'Injected reader must not guess a new HTTP operation or break legacy request shapes');
      return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true,
        'data': body.containsKey('cataloguePageVersion')
          ? pageData(body, empty: (body['query'] as Map)['destination'] == 'wholesale') : publicPage()}));
    });
    final connection = AuthenticatedWorkspaceCatalogueGateway(endpoint: Uri.parse(
      'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
      credentials: Credentials(), transport: transport, now: () => at, reviewedVariants: reader);
    expect(identical(connection.forOwnerAccount('owner-one').reviewedVariants, reader), isTrue);
    final direct = await connection.readPublicEntry(storeId: 'store-one', skuId: 'sku-one',
      channel: BuyV2OfferClass.retail, current: () => true);
    expect(direct, isNotNull);
    expect(direct!.product.variantFamilyId, 'host-reviewed-family');
    expect(direct.product.canonicalId, 'canonical-one');
    expect(direct.product.priceMinor, 26000);
    expect(direct.product.pack, '1 L');
    final source = WorkspaceStoreCatalogueSource(gateway: connection, storeId: 'store-one', current: () => true);
    final page = await source.loadProducts(storeQuery(), pageSize: 40);
    expect(page.items.single.variantFamilyId, direct.product.variantFamilyId);
    expect(page.items.single.variantAttributes.single.optionId, 'pink');
    final restored = await source.resolveProducts({direct.product.id});
    expect(restored.first.variantFamilyId, direct.product.variantFamilyId);
  });
  test('LF03 PUBLIC-FAMILY missing incomplete expired and conflicting membership fails closed', () async {
    var revision = 2, colour = 'pink', omit = false;
    DateTime? expiry;
    final reader = HostReviewedVariantSource(memberships: (entries, current) async => omit ? [] :
      entries.map((entry) => reviewedMember(entry, revision: revision, colour: colour, expiry: expiry)).toList());
    final connection = AuthenticatedWorkspaceCatalogueGateway(endpoint: Uri.parse(
      'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
      credentials: Credentials(), transport: Transport(publicPage()), now: () => at, reviewedVariants: reader);
    Future<WorkspacePublicCatalogueEntry?> read() => connection.readPublicEntry(storeId: 'store-one', skuId: 'sku-one',
      channel: BuyV2OfferClass.retail, current: () => true);
    expect(await read(), isNotNull);
    colour = 'blue'; expect(await read(), isNull, reason: 'same revision cannot rewrite selected attributes');
    revision = 1; expect(await read(), isNull, reason: 'older family association cannot return');
    revision = 3; expiry = at; expect(await read(), isNull);
    expiry = null; omit = true; expect(await read(), isNull, reason: 'absence is not a standalone assertion');
    omit = false; expect((await read())!.product.variantAttributes.single.optionId, 'blue');
  });
  Future<BuyV2Session> readinessSession(BuyV2Product selected,
    {bool review = false, BuyV2ProductFactsAdapter? facts}) async {
    final core = BuySession(), catalogue = _ExactMoneyHostCatalogue()..rows.add(selected);
    final session = BuyV2Session(core: core, cataloguePageSource: catalogue, reviewDataEnabled: review,
      productFactsAdapter: facts ?? const BuyV2CatalogueProductFactsAdapter(), catalogueNow: () => at);
    addTearDown(core.dispose); addTearDown(session.dispose);
    final pager = session.acquireCatalogueProducts('host-readiness');
    addTearDown(() => session.releaseCatalogueProducts('host-readiness'));
    await pager.open(BuyV2CatalogueQuery(destination: selected.destination, regionId: null,
      areaScope: BuyV2CatalogueAreaScope.allAreas));
    return session;
  }
  for (final trade in [false, true]) {
    for (final review in [false, true]) {
      for (final seller in ['Host Store', 'Pet Family Store', 'Beauty Supply']) {
        test('LF03 READINESS published identity cannot infer review status trade=$trade review=$review seller=$seller', () async {
          final data = publicPage(trade: trade);
          (data['publicStore'] as Map)['name'] = seller;
          final selected = factoryEntry(data, channel: trade ? BuyV2OfferClass.wholesale : BuyV2OfferClass.retail).product;
          final session = await readinessSession(selected, review: review);
          for (final facts in [session.productFactsAdapter.snapshotFor(selected), session.productFactsFor(selected)]) {
            expect(facts.storeOperatingState, BuyV2StoreOperatingState.unknown);
            expect(facts.nextOpeningLabel, isNull); expect(facts.fulfilmentMode, isNull);
            expect(facts.deliveryProviderName, isNull); expect(facts.eligibility, isNull);
            expect(facts.deliveryPromise.toLowerCase(), contains('unconfirmed'));
            expect(facts.orderabilityLabel, isNot('Available to add'));
            expect(facts.orderabilityLabel, isNot('Store closed'));
            expect(facts.orderabilityLabel, isNot('Products unavailable'));
            expect(facts.priceMinor, selected.priceMinor); expect(facts.stale, isTrue);
          }
          expect(session.addProduct(selected.id), isFalse); expect(session.cartLines, isEmpty);
        });
      }
    }
  }
  test('LF03 READINESS production default is neutral while explicit review fixtures remain unchanged', () {
    final value = BuyV2Catalogue.products.firstWhere((p) => p.id == 's-tomato');
    final core = BuySession(), production = BuyV2Session(core: BuySession(), reviewDataEnabled: false);
    final review = BuyV2Session(core: core, reviewDataEnabled: true);
    addTearDown(core.dispose); addTearDown(review.dispose);
    addTearDown(production.core.dispose); addTearDown(production.dispose);
    final live = production.productFactsAdapter.snapshotFor(value);
    expect(live.storeOperatingState, BuyV2StoreOperatingState.unknown); expect(live.stale, isTrue);
    final original = review.productFactsFor(value);
    expect(original.storeOperatingState, BuyV2StoreOperatingState.open);
    expect(original.orderabilityLabel, 'Available to add');
    expect(review.refreshProductFacts(value.id), isTrue);
    expect(review.productFactsFor(value), original);
  });
  for (final review in [false, true]) {
    test('LF03 READINESS invalid adapter cannot revive review status review=$review', () async {
      final selected = factoryEntry(publicPage()).product;
      final adapter = _HostOperationalFacts((p) => BuyV2ProductFactsSnapshot(productId: 'wrong-listing',
        priceMinor: p.priceMinor, deliveryPromise: 'Invented delivery', partner: p.seller,
        orderabilityLabel: 'Available to add', sourceId: 'host-invalid-source',
        storeOperatingState: BuyV2StoreOperatingState.open));
      final session = await readinessSession(selected, review: review, facts: adapter);
      final current = session.productFactsFor(selected);
      expect(current.storeOperatingState, BuyV2StoreOperatingState.unknown);
      expect(current.stale, isTrue); expect(current.fulfilmentMode, isNull);
      expect(current.deliveryPromise, isNot('Invented delivery'));
      expect(current.priceMinor, selected.priceMinor); expect(session.addProduct(selected.id), isFalse);
    });
  }
  test('LF03 READINESS supplied provider state is preserved and invalid refresh retires readiness not last paise', () async {
    final selected = factoryEntry(publicPage()).product;
    final adapter = _HostOperationalFacts((p) => BuyV2ProductFactsSnapshot(productId: p.id,
      priceMinor: 26025, deliveryPromise: 'Host confirmed delivery', partner: p.seller,
      orderabilityLabel: 'Store closed', sourceId: 'host-confirmed-source', observedAt: at,
      storeOperatingState: BuyV2StoreOperatingState.closed, nextOpeningLabel: 'Host confirmed opening',
      fulfilmentMode: BuyV2FulfilmentMode.quickLocal, dispatchPromise: 'Host confirmed dispatch',
      deliveryProviderName: 'Host actual provider', deliveryServiceLevel: 'Host actual service',
      orderCutoffLabel: 'Host actual cutoff', deliveryFeeLabel: 'Host actual fee'));
    final session = await readinessSession(selected, facts: adapter);
    final known = session.productFactsFor(selected);
    expect(known.storeOperatingState, BuyV2StoreOperatingState.closed);
    expect(known.nextOpeningLabel, 'Host confirmed opening'); expect(known.priceMinor, 26025);
    adapter.reply = (p) => BuyV2ProductFactsSnapshot(productId: 'retired-product', priceMinor: 1,
      deliveryPromise: 'Wrong refresh', partner: p.seller, orderabilityLabel: 'Available to add', sourceId: 'host-invalid');
    expect(session.refreshProductFacts(selected.id), isFalse);
    final unavailable = session.productFactsFor(selected);
    expect(unavailable.priceMinor, 26025, reason: 'failed refresh must retain the original last-known paise');
    expect(unavailable.storeOperatingState, BuyV2StoreOperatingState.unknown);
    expect(unavailable.stale, isTrue); expect(unavailable.nextOpeningLabel, isNull);
    expect(unavailable.fulfilmentMode, isNull); expect(unavailable.dispatchPromise, isNull);
    expect(unavailable.deliveryProviderName, isNull); expect(unavailable.deliveryServiceLevel, isNull);
    expect(unavailable.orderCutoffLabel, isNull); expect(unavailable.deliveryFeeLabel, isNull);
    expect(session.addProduct(selected.id), isFalse); expect(session.cartLines, isEmpty);
  });
  test('LF03 READINESS bound listing with review delivery options cannot restore cleared mode', () async {
    final selected = factoryEntry(publicPage()).product.copyWith(reviewDeliveryOptions: {BuyV2DeliveryOption.quick});
    final session = await readinessSession(selected, review: true);
    expect(session.productFactsFor(selected).fulfilmentMode, isNull);
    expect(session.deliveryOptionsFor(selected), isEmpty);
  });
  test('LF03 READINESS invalid price is unavailable rather than a stale similar-family placeholder', () {
    const adapter = BuyV2CatalogueProductFactsAdapter(includeReviewFixtures: false);
    final selected = factoryEntry(publicPage()).product, invalid = selected.copyWith(priceMinor: 0);
    expect(buyV2ResolveProductOfferDecision(product: invalid, facts: adapter.snapshotFor(invalid)).state,
      BuyV2ProductOfferDecisionState.unavailable);
    expect(buyV2ResolveProductOfferDecision(product: selected, facts: adapter.snapshotFor(selected)).state,
      BuyV2ProductOfferDecisionState.stale, reason: 'unknown readiness is not verified out-of-stock');
  });
  test('LF03 READINESS genuine configured eligibility and provider fields remain available', () async {
    final selected = factoryEntry(publicPage()).product;
    final adapter = _HostOperationalFacts((p) => const BuyV2CatalogueProductFactsAdapter(includeReviewFixtures: false).snapshotFor(p));
    final session = await readinessSession(selected, facts: adapter);
    final eligibility = BuyV2OfferEligibility(productId: selected.id, storeId: selected.storeId!,
      sourceRevision: 'host-live-revision', customerLocationKey: session.eligibilityLocationKey,
      observedAt: at, expiresAt: at.add(const Duration(minutes: 15)), offerClass: selected.offerClass!,
      channelEnabled: true, storeReady: true, fleetAvailable: true, customerLocationConfirmed: true,
      options: {BuyV2DeliveryOption.quick});
    adapter.reply = (p) => BuyV2ProductFactsSnapshot(productId: p.id, priceMinor: 26025,
      deliveryPromise: 'Host source-confirmed delivery', partner: p.seller, orderabilityLabel: 'Available to add',
      sourceId: 'host-real-provider-contract', observedAt: at, storeOperatingState: BuyV2StoreOperatingState.open,
      eligibility: eligibility, deliveryProviderName: 'Host supplied provider');
    expect(session.refreshProductFacts(selected.id), isTrue);
    final facts = session.productFactsFor(selected);
    expect(facts.eligibility, same(eligibility)); expect(facts.stale, isFalse);
    expect(facts.storeOperatingState, BuyV2StoreOperatingState.open);
    expect(facts.deliveryProviderName, 'Host supplied provider'); expect(facts.priceMinor, 26025);
    expect(session.deliveryOptionsFor(selected), {BuyV2DeliveryOption.quick});
    expect(facts.fulfilmentMode, BuyV2FulfilmentMode.quickLocal);
  });
  test('LF03 READINESS review confirmation rejects a newly stale reply before creating an order', () {
    final core = BuySession(); var stale = false, reads = 0;
    final adapter = _HostOperationalFacts((p) {
      reads++;
      return const BuyV2CatalogueProductFactsAdapter().snapshotFor(p).copyWith(stale: stale);
    });
    final session = BuyV2Session(core: core, reviewDataEnabled: true, productFactsAdapter: adapter);
    addTearDown(core.dispose); addTearDown(session.dispose);
    expect(session.addProduct('s-tomato'), isTrue);
    session.openCart(); expect(session.openCheckout(), isTrue);
    final previousReads = reads, orders = session.orders.length, cart = session.itemCount;
    stale = true;
    expect(session.confirmOrder(), isFalse);
    expect(reads, greaterThan(previousReads), reason: 'must reach fresh facts, not an unrelated earlier guard');
    expect(session.orders.length, orders); expect(session.itemCount, cart);
    expect(session.notice, contains('could not be confirmed'));
  });
  // Both rows are isolated reviewed-source fixtures, not private Store records.
  Map<String, dynamic> siblingPage() {
    final data = publicPage(), value = row(data);
    value['skuId'] = 'sku-two'; value['canonicalProductId'] = 'canonical-two';
    value['verifiedPackId'] = 'pack-two'; value['sku'] = 'HOST-TWO';
    (value['content'] as Map)['variant'] = 'Blue';
    ((value['channels'] as List).single as Map)['priceMinor'] = 26025;
    value['listings'] = [BuyV2PublicListingIdentity(listingId: 'listing-${'c' * 64}',
      realm: 'production', storeId: 'store-one', skuId: 'sku-two', canonicalProductId: 'canonical-two',
      verifiedPackId: 'pack-two', channel: BuyV2OfferClass.retail).toJson()];
    value['supplierPolicy'] = {...policyEnvelope(state: 'none', revision: 0), 'skuId': 'sku-two'};
    return data;
  }
  BuyV2Product familyProduct(Map<String, dynamic> data, String colour) {
    final entry = factoryEntry(data);
    return entry.product.copyWith(variantFamilyId: 'host-reviewed-family',
      variantAttributes: reviewedMember(entry, colour: colour).attributes);
  }
  BuyV2VariantFamilySnapshot familyReply(BuyV2Product selected, BuyV2CatalogueQuery query,
    List<BuyV2Product> candidates, {int revision = 1, String sourceId = 'host-reviewed-associations'}) =>
    BuyV2VariantFamilySnapshot(productId: selected.id, canonicalId: selected.canonicalId,
      variantFamilyId: selected.variantFamilyId, categoryId: selected.categoryId,
      offerClass: selected.offerClass, realm: 'production', storeId: 'store-one',
      destination: selected.destination, queryKey: query.key, sourceId: sourceId,
      revision: '$revision', observedAt: at, validUntil: at.add(const Duration(minutes: 30)),
      complete: true, selectedAvailable: true,
      options: [for (final colour in ['pink', 'blue']) BuyV2VariantAttribute(dimensionId: 'colour',
        dimensionLabel: 'Colour', optionId: colour, optionLabel: colour, kind: BuyV2VariantDimensionKind.colour)],
      candidates: candidates);
  OwnerTransport familyTransport({void Function(Map<String, Object?>)? onRequest}) => OwnerTransport((body) async {
    onRequest?.call(body);
    if (!body.containsKey('cataloguePageVersion')) {
      return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true,
        'data': body['skuId'] == 'sku-two' ? siblingPage() : publicPage()}));
    }
    final query = body['query'] as Map, ids = (query['listingIds'] as List).cast<String>();
    final rows = <Map<String, dynamic>>[];
    if (query['destination'] == 'shop') {
      for (final data in [publicPage(), siblingPage()]) {
        final value = row(data), id = ((value['listings'] as List).single as Map)['listingId'];
        // Initial discovery is deliberately partial. Exact resolution can find B.
        if (ids.isEmpty ? value['skuId'] == 'sku-one' : ids.contains(id)) {
          rows.add({'channel': 'retail', 'row': value});
        }
      }
    }
    final data = pageData(body, empty: rows.isEmpty);
    data['items'] = rows;
    (data['page'] as Map)['totalCount'] = rows.length;
    return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': data}));
  });
  AuthenticatedWorkspaceCatalogueGateway familyGateway(WorkspacePublicVariantSource reader,
    {SocialContentTransport? transport}) => AuthenticatedWorkspaceCatalogueGateway(endpoint: Uri.parse(
      'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
      credentials: Credentials(), transport: transport ?? familyTransport(), now: () => at, reviewedVariants: reader);
  Map<String, dynamic> httpReviewedFamily(Map<String, Object?> request, {bool standalone = false}) {
    const sourceId = 'store-reviewed-variants:production:store-one';
    final expiry = at.add(const Duration(minutes: 5)).toIso8601String();
    Map<String, dynamic> membership(Map<String, dynamic> page) {
      final sku = row(page), identity = (sku['listings'] as List).single;
      final colour = sku['skuId'] == 'sku-one' ? 'pink' : 'blue';
      return {'listing': identity, 'skuRevision': sku['revision'], 'catalogueVersion': 1,
        'familyId': standalone ? null : 'host-reviewed-family', 'sourceId': sourceId, 'revision': 2,
        'observedAt': at.toIso8601String(), 'validUntil': expiry, 'attributes': standalone ? [] : [{
          'dimensionId': 'colour', 'dimensionLabel': 'Colour', 'optionId': colour, 'optionLabel': colour,
          'kind': 'colour', 'swatchArgb': null}]};
    }
    final pages = [publicPage(), siblingPage()];
    final requested = (request['listings'] as List).cast<Map>();
    return {'schemaVersion': 1, 'realm': 'production', 'storeId': 'store-one', 'observedAt': at.toIso8601String(),
      'orderingAvailable': false, 'state': 'ready', 'catalogueVersion': 1, 'publicStore': publicPage()['publicStore'],
      'sourceId': sourceId, 'revision': 2, 'validUntil': expiry,
      'memberships': [for (final request in requested) membership(pages.singleWhere((p) => row(p)['skuId'] == request['skuId']))],
      'family': request['familyId'] == null ? null : {'familyId': 'host-reviewed-family',
        'options': [for (final colour in ['pink', 'blue']) {'dimensionId': 'colour', 'dimensionLabel': 'Colour',
          'optionId': colour, 'optionLabel': colour, 'kind': 'colour', 'swatchArgb': null}],
        'products': [for (final p in pages) {'product': row(p), 'membership': membership(p)}]}};
  }
  AuthenticatedWorkspaceCatalogueGateway httpFamilyGateway(SocialContentTransport transport, {bool enabled = true}) =>
      AuthenticatedWorkspaceCatalogueGateway(endpoint: Uri.parse(
        'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
        credentials: Credentials(), transport: transport, now: () => at, reviewedFamilyReadbackSupported: enabled);
  test('LF03 HTTP-FAMILY reads actual endpoint association and exact off-page sibling without generated SKUs', () async {
    final fallback = familyTransport(), operations = <Object?>[];
    final transport = OwnerTransport((body) async {
      operations.add(body['operation']);
      if (body['operation'] == 'readPublicStoreVariantFamilies') {
        return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': httpReviewedFamily(body)}));
      }
      return fallback.postJson(Uri.parse('https://example.com'), headers: {}, body: body);
    });
    final connection = httpFamilyGateway(transport);
    final entry = await connection.readPublicEntry(storeId: 'store-one', skuId: 'sku-one',
      channel: BuyV2OfferClass.retail, current: () => true);
    expect(entry, isNotNull); expect(entry!.product.variantFamilyId, 'host-reviewed-family');
    final query = BuyV2CatalogueQuery(destination: BuyV2Destination.shop, regionId: null, storeId: 'store-one');
    final source = WorkspaceStoreCatalogueSource(storeId: 'store-one', current: () => true, gateway: connection);
    final snapshot = await source.loadVariantFamily(entry.product, query);
    expect(snapshot.isValidFor(entry.product, query, at), isTrue);
    expect(snapshot.candidates.map((p) => p.sourceSkuId).toSet(), {'sku-one', 'sku-two'});
    expect(snapshot.candidates.singleWhere((p) => p.sourceSkuId == 'sku-two').priceMinor, 26025);
    expect(snapshot.candidates.singleWhere((p) => p.sourceSkuId == 'sku-two').publicListingIdentity!.verifiedPackId, 'pack-two');
    expect(snapshot.options.length, 2); expect(snapshot.candidates.length, 2);
    expect(operations, contains('readPublicStoreVariantFamilies'));
    final clone = connection.forOwnerAccount('owner-two');
    expect(clone.reviewedVariants, isNot(same(connection.reviewedVariants)));
    expect((clone.reviewedVariants as WorkspaceHttpReviewedVariantSource).gateway.ownerAccountId, 'owner-two');
  });
  test('LF03 HTTP-FAMILY negotiated standalone differs from missing/unconnected source', () async {
    final fallback = familyTransport(); var reads = 0;
    final transport = OwnerTransport((body) async {
      if (body['operation'] == 'readPublicStoreVariantFamilies') {
        reads++;
        return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': httpReviewedFamily(body, standalone: true)}));
      }
      return fallback.postJson(Uri.parse('https://example.com'), headers: {}, body: body);
    });
    final legacy = await httpFamilyGateway(transport, enabled: false).readPublicEntry(storeId: 'store-one', skuId: 'sku-one',
      channel: BuyV2OfferClass.retail, current: () => true);
    expect(legacy, isNotNull); expect(reads, 0);
    final actual = await httpFamilyGateway(transport).readPublicEntry(storeId: 'store-one', skuId: 'sku-one',
      channel: BuyV2OfferClass.retail, current: () => true);
    expect(actual, isNotNull); expect(actual!.product.variantFamilyId, isNull); expect(reads, 1);
  });
  test('LF03 HTTP-FAMILY rejected downgrade cannot poison retained family loading', () async {
    var revision = 2;
    final fallback = familyTransport();
    final transport = OwnerTransport((body) async {
      if (body['operation'] != 'readPublicStoreVariantFamilies') {
        return fallback.postJson(Uri.parse('https://example.com'), headers: {}, body: body);
      }
      final data = httpReviewedFamily(body)..['revision'] = revision;
      for (final member in data['memberships'] as List) { (member as Map)['revision'] = revision; }
      if (data['family'] case final Map family) {
        for (final product in family['products'] as List) { (product['membership'] as Map)['revision'] = revision; }
      }
      return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': data}));
    });
    final connection = httpFamilyGateway(transport);
    final retained = (await connection.readPublicEntry(storeId: 'store-one', skuId: 'sku-one',
      channel: BuyV2OfferClass.retail, current: () => true))!;
    revision = 1;
    expect(await connection.readPublicEntry(storeId: 'store-one', skuId: 'sku-one',
      channel: BuyV2OfferClass.retail, current: () => true), isNull);
    revision = 2;
    final source = WorkspaceStoreCatalogueSource(storeId: 'store-one', current: () => true, gateway: connection);
    final query = BuyV2CatalogueQuery(destination: BuyV2Destination.shop, regionId: null, storeId: 'store-one');
    final snapshot = await source.loadVariantFamily(retained.product, query);
    expect(snapshot.isValidFor(retained.product, query, at), isTrue);
    expect(snapshot.candidates.length, 2);
  });
  for (final defect in ['unavailable', 'foreign Store', 'wrong source', 'missing member', 'duplicate member',
      'wrong revision', 'expired', 'wrong SKU', 'empty attributes', 'unknown private field']) {
    test('LF03 HTTP-FAMILY rejects $defect without private-family fallback', () async {
      final fallback = familyTransport();
      final transport = OwnerTransport((body) async {
        if (body['operation'] != 'readPublicStoreVariantFamilies') {
          return fallback.postJson(Uri.parse('https://example.com'), headers: {}, body: body);
        }
        final data = httpReviewedFamily(body), members = data['memberships'] as List;
        final member = members.single as Map;
        if (defect == 'unavailable') data['state'] = 'unavailable';
        if (defect == 'foreign Store') data['storeId'] = 'store-two';
        if (defect == 'wrong source') data['sourceId'] = 'private-family';
        if (defect == 'missing member') members.clear();
        if (defect == 'duplicate member') members.add(Map.of(member));
        if (defect == 'wrong revision') member['revision'] = 3;
        if (defect == 'expired') data['validUntil'] = at.toIso8601String();
        if (defect == 'wrong SKU') (member['listing'] as Map)['skuId'] = 'sku-other';
        if (defect == 'empty attributes') member['attributes'] = [];
        if (defect == 'unknown private field') member['stock'] = 100;
        return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': data}));
      });
      expect(await httpFamilyGateway(transport).readPublicEntry(storeId: 'store-one', skuId: 'sku-one',
        channel: BuyV2OfferClass.retail, current: () => true), isNull);
    });
  }
  test('LF03 PUBLIC-FAMILY off-page sibling resolves exact source before selection and refresh', () async {
    final candidates = [familyProduct(publicPage(), 'pink'), familyProduct(siblingPage(), 'blue')];
    final reader = HostReviewedVariantSource(memberships: (entries, current) async => entries.map((entry) =>
      reviewedMember(entry, colour: entry.product.sourceSkuId == 'sku-one' ? 'pink' : 'blue')).toList(),
      family: (selected, query, current) async => familyReply(selected, query, candidates));
    final requested = <Set<String>>[];
    final source = WorkspaceStoreCatalogueSource(storeId: 'store-one', current: () => true,
      gateway: familyGateway(reader, transport: familyTransport(onRequest: (body) {
        if (body['query'] case final Map query) requested.add((query['listingIds'] as List).cast<String>().toSet());
      })));
    final core = BuySession();
    final session = BuyV2Session(core: core, cataloguePageSource: source, reviewDataEnabled: false, catalogueNow: () => at);
    addTearDown(core.dispose); addTearDown(session.dispose);
    final pager = session.acquireCatalogueProducts('host-reviewed-family');
    await pager.open(storeQuery());
    expect(pager.page!.items.length, 1);
    expect(session.findProduct(candidates[1].id), isNull);
    expect(session.openProduct(candidates[0].id), isTrue);
    expect(await session.refreshVariantFamily(session.selectedProduct!), isTrue);
    expect(requested.any((ids) => ids.contains(candidates[1].id)), isTrue);
    expect(session.selectProductVariant(candidates[1].id), isTrue);
    final selected = session.selectedProduct!;
    expect(selected.canonicalId, 'canonical-two'); expect(selected.sourceSkuId, 'sku-two');
    expect(selected.publicListingIdentity!.verifiedPackId, 'pack-two'); expect(selected.priceMinor, 26025);
    expect(await session.refreshVariantFamily(selected), isTrue, reason: 'off-page B must have its own admitted readback');
    expect(session.selectProductVariant(candidates[0].id), isTrue);
    expect(session.selectedProduct!.canonicalId, 'canonical-one'); expect(session.selectedProduct!.priceMinor, 26000);
    session.releaseCatalogueProducts('host-reviewed-family');
  });
  test('LF03 PUBLIC-FAMILY older neighbour cannot bypass newer admitted association', () async {
    var revision = 1;
    final reader = HostReviewedVariantSource(memberships: (entries, current) async => entries.map((entry) =>
      reviewedMember(entry, revision: revision, colour: entry.product.sourceSkuId == 'sku-one' ? 'pink' : 'blue')).toList(),
      family: (selected, query, current) async => familyReply(selected, query,
        [familyProduct(publicPage(), 'pink'), familyProduct(siblingPage(), 'blue')]));
    final connection = familyGateway(reader);
    final source = WorkspaceStoreCatalogueSource(storeId: 'store-one', current: () => true, gateway: connection);
    final first = (await source.loadProducts(storeQuery(), pageSize: 40)).items.single;
    revision = 2;
    expect(await connection.readPublicEntry(storeId: 'store-one', skuId: 'sku-two',
      channel: BuyV2OfferClass.retail, current: () => true), isNotNull);
    revision = 1;
    await expectLater(source.loadVariantFamily(first, storeQuery()), throwsFormatException);
    expect(await connection.readPublicEntry(storeId: 'store-one', skuId: 'sku-two',
      channel: BuyV2OfferClass.retail, current: () => true), isNull);
  });
  for (final fault in ['price', 'pack', 'source', 'option label', 'withdrawn']) {
    test('LF03 PUBLIC-FAMILY rejects inconsistent family hint $fault', () async {
      final first = familyProduct(publicPage(), 'pink'), second = familyProduct(siblingPage(), 'blue');
      final reader = HostReviewedVariantSource(memberships: (entries, current) async => entries.map((entry) =>
        reviewedMember(entry, colour: entry.product.sourceSkuId == 'sku-one' ? 'pink' : 'blue')).toList(),
        family: (selected, query, current) async {
          final changed = switch (fault) {
            'price' => second.copyWith(priceMinor: 26026),
            'pack' => second.copyWith(pack: 'Wrong pack'),
            'option label' => second.copyWith(variantAttributes: [const BuyV2VariantAttribute(
              dimensionId: 'colour', dimensionLabel: 'Colour', optionId: 'blue', optionLabel: 'Different blue',
              kind: BuyV2VariantDimensionKind.colour)]),
            _ => second,
          };
          return familyReply(selected, query, [first, changed],
            revision: fault == 'withdrawn' ? 2 : 1,
            sourceId: fault == 'source' ? 'unrelated-source' : 'host-reviewed-associations');
        });
      final source = WorkspaceStoreCatalogueSource(storeId: 'store-one', current: () => true, gateway: familyGateway(reader));
      final selected = (await source.loadProducts(storeQuery(), pageSize: 40)).items.single;
      await expectLater(source.loadVariantFamily(selected, storeQuery()), throwsFormatException);
    });
  }
  test('LF03 PUBLIC-FAMILY retired read cannot admit pending membership', () async {
    var current = true, hold = true;
    final pending = Completer<List<WorkspaceReviewedVariantMembership>>();
    final started = Completer<List<WorkspacePublicCatalogueEntry>>();
    final reader = HostReviewedVariantSource(memberships: (entries, lifetime) {
      if (hold) { started.complete(entries); return pending.future; }
      return Future.value(entries.map((entry) => reviewedMember(entry)).toList());
    });
    final connection = familyGateway(reader);
    final read = connection.readPublicEntry(storeId: 'store-one', skuId: 'sku-one',
      channel: BuyV2OfferClass.retail, current: () => current);
    final entries = await started.future;
    current = false; pending.complete(entries.map((entry) => reviewedMember(entry, revision: 5)).toList());
    expect(await read, isNull);
    hold = false; current = true;
    expect(await connection.readPublicEntry(storeId: 'store-one', skuId: 'sku-one',
      channel: BuyV2OfferClass.retail, current: () => current), isNotNull,
      reason: 'discarded revision5 must not poison the new request with a high-water mark');
  });
  test('LF03 PUBLIC-FAMILY delayed older SKU and catalogue cannot replace newer source', () async {
    final older = Completer<SocialContentResponse>(), started = Completer<void>();
    var calls = 0;
    final reader = HostReviewedVariantSource(memberships: (entries, current) async =>
      entries.map((entry) => reviewedMember(entry)).toList());
    final connection = familyGateway(reader, transport: OwnerTransport((body) async {
      if (++calls == 1) { started.complete(); return older.future; }
      final data = publicPage()..['catalogueVersion'] = 2;
      row(data)['revision'] = 2;
      return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': data}));
    }));
    Future<WorkspacePublicCatalogueEntry?> read() => connection.readPublicEntry(storeId: 'store-one', skuId: 'sku-one',
      channel: BuyV2OfferClass.retail, current: () => true);
    final pending = read(); await started.future;
    expect((await read())!.readback.skuRevision, 2);
    older.complete(SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': publicPage()})));
    expect(await pending, isNull, reason: 'unchanged family revision does not authorize older catalogue facts');
  });
  test('LF03 PUBLIC-FAMILY final batch cannot expose a sibling advanced during later resolution', () async {
    final data = <Map<String, dynamic>>[], candidates = <BuyV2Product>[];
    for (var i = 0; i < 51; i++) {
      final item = publicPage(), value = row(item), id = 'listing-${i.toRadixString(16).padLeft(64, '0')}';
      final sku = 'sku-host-$i';
      value.addAll({'skuId': sku, 'canonicalProductId': 'canonical-host-$i', 'verifiedPackId': 'pack-host-$i', 'sku': 'HOST-$i',
        'listings': [BuyV2PublicListingIdentity(listingId: id, realm: 'production', storeId: 'store-one',
          skuId: sku, canonicalProductId: 'canonical-host-$i', verifiedPackId: 'pack-host-$i',
          channel: BuyV2OfferClass.retail).toJson()],
        'supplierPolicy': {...policyEnvelope(state: 'none', revision: 0), 'skuId': sku}});
      data.add(item);
      candidates.add(familyProduct(item, 'choice-$i'));
    }
    final later = Completer<void>(), started = Completer<void>();
    var hold = true, revisedSibling = false;
    final reader = HostReviewedVariantSource(memberships: (entries, current) async => entries.map((entry) {
      final i = int.parse(entry.product.sourceSkuId.split('-').last);
      return reviewedMember(entry, revision: revisedSibling && i == 1 ? 2 : 1, colour: 'choice-$i');
    }).toList(), family: (selected, query, current) async => BuyV2VariantFamilySnapshot(
      productId: selected.id, canonicalId: selected.canonicalId, variantFamilyId: selected.variantFamilyId,
      categoryId: selected.categoryId, offerClass: selected.offerClass, realm: 'production', storeId: 'store-one',
      destination: selected.destination, queryKey: query.key, sourceId: 'host-reviewed-associations', revision: '1',
      observedAt: at, validUntil: at.add(const Duration(minutes: 30)), complete: true, selectedAvailable: true,
      options: candidates.map((p) => p.variantAttributes.single), candidates: candidates));
    final connection = familyGateway(reader, transport: OwnerTransport((body) async {
      if (!body.containsKey('cataloguePageVersion')) {
        return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true,
          'data': data.singleWhere((d) => row(d)['skuId'] == body['skuId'])}));
      }
      final query = body['query'] as Map, ids = (query['listingIds'] as List).cast<String>();
      if (hold && ids.length == 1 && ids.contains(candidates.last.id) && query['destination'] == 'shop') {
        started.complete(); await later.future;
      }
      final rows = query['destination'] == 'wholesale' ? <Map<String, dynamic>>[] : [
        for (var i = 0; i < data.length; i++)
          if (ids.isEmpty ? i == 0 : ids.contains(candidates[i].id)) {'channel': 'retail', 'row': row(data[i])},
      ];
      final reply = pageData(body, empty: rows.isEmpty)..['items'] = rows;
      (reply['page'] as Map)['totalCount'] = rows.length;
      return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': reply}));
    }));
    final source = WorkspaceStoreCatalogueSource(storeId: 'store-one', current: () => true, gateway: connection);
    final first = (await source.loadProducts(storeQuery(), pageSize: 40)).items.single;
    final pending = source.loadVariantFamily(first, storeQuery());
    final expectation = expectLater(pending, throwsFormatException);
    await started.future;
    revisedSibling = true;
    expect(await connection.readPublicEntry(storeId: 'store-one', skuId: 'sku-host-1',
      channel: BuyV2OfferClass.retail, current: () => true), isNotNull);
    hold = false; later.complete();
    await expectation;
  });
  for (final empty in [false, true]) {
    test('LF-FACTS unsupported version cannot pass a catalogue page empty=$empty', () async {
      final source = WorkspaceStoreCatalogueSource(storeId: 'store-one', current: () => true,
        gateway: pageGateway(OwnerTransport((body) async {
          expect(body.containsKey('productFactsReadbackVersion'), isFalse,
            reason: 'Legacy strict endpoint must retain its original request shape.');
          final data = pageData(body, empty: empty)..['productFactsReadbackVersion'] = 2;
          return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': data}));
        })));
      await expectLater(source.loadProducts(storeQuery(), pageSize: 40), throwsFormatException);
    });
  }
  test('LF-PAGER client source enters existing Buy pager with exact source product and no ordering authority', () async {
    final transport = OwnerTransport((body) async => SocialContentResponse(statusCode: 200,
      body: jsonEncode({'ok': true, 'data': pageData(body)})));
    final source = WorkspaceStoreCatalogueSource(gateway: pageGateway(transport), storeId: 'store-one', current: () => true);
    final core = BuySession();
    final consumer = BuyV2Session(core: core,
      cataloguePageSource: source, reviewDataEnabled: false, catalogueNow: () => at);
    addTearDown(core.dispose); addTearDown(consumer.dispose);
    final pager = consumer.acquireCatalogueProducts('host-store-page');
    await pager.open(storeQuery());
    expect(pager.message, isNull); expect(pager.page!.totalCount, 1);
    final selected = pager.page!.items.single;
    expect(selected.id, publicIdentity().listingId); expect(selected.sourceSkuId, 'sku-one');
    expect(selected.pack, '1 L'); expect(selected.price, 260);
    expect(consumer.productFactsFor(selected).eligibility, isNull);
    expect(selected.reviewDeliveryOptions, isEmpty);
    consumer.releaseCatalogueProducts('host-store-page');
  });
  for (final mutation in ['query', 'realm', 'count', 'duplicate', 'binding', 'metadata', 'cursor']) {
    test('LF-PAGER client rejects malformed or mismatched page $mutation', () async {
      final transport = OwnerTransport((body) async {
        final data = pageData(body), metadata = data['page'] as Map;
        if (mutation == 'query') data['query'] = {...body['query'] as Map, 'search': 'other'};
        if (mutation == 'realm') data['realm'] = 'evaluation';
        if (mutation == 'count') metadata['totalCount'] = 2;
        if (mutation == 'duplicate') { (data['items'] as List).add((data['items'] as List).single); metadata['totalCount'] = 2; }
        if (mutation == 'binding') (((data['items'] as List).single['row']['listings'] as List).single as Map)['skuId'] = 'other-sku';
        if (mutation == 'metadata') metadata['snapshotId'] = 'client-invented';
        if (mutation == 'cursor') data['nextCursor'] = 'unmatched';
        return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': data}));
      });
      final source = WorkspaceStoreCatalogueSource(gateway: pageGateway(transport), storeId: 'store-one', current: () => true);
      expect(() => source.loadProducts(storeQuery(), pageSize: 40), throwsFormatException);
    });
  }
  test('LF-PAGER client restores only requested actual listing IDs without guessing source joins', () async {
    final requests = <Map<String, Object?>>[];
    final transport = OwnerTransport((body) async {
      requests.add(body);
      final query = body['query'] as Map;
      return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true,
        'data': pageData(body, empty: query['destination'] == 'wholesale')}));
    });
    final source = WorkspaceStoreCatalogueSource(gateway: pageGateway(transport), storeId: 'store-one', current: () => true);
    expect((await source.resolveProducts({publicIdentity().listingId})).single.sourceSkuId, 'sku-one');
    expect(requests, hasLength(2));
    for (final request in requests) { expect((request['query'] as Map)['listingIds'], [publicIdentity().listingId]); }
    expect(() => source.resolveProducts({'sku-one'}), throwsFormatException);
    expect(() => source.loadStores(storeQuery(), pageSize: 40), throwsFormatException);
    expect(() => source.loadProducts(BuyV2CatalogueQuery(destination: BuyV2Destination.shop,
      regionId: 'unverified-region', storeId: 'store-one'), pageSize: 40), throwsFormatException);
  });
  test('LF-PAGER client drops late scoped results after retirement', () async {
    var current = true;
    final response = Completer<SocialContentResponse>(), sent = Completer<Map<String, Object?>>();
    final source = WorkspaceStoreCatalogueSource(gateway: pageGateway(OwnerTransport((body) {
      sent.complete(body); return response.future;
    })), storeId: 'store-one', current: () => current);
    final result = source.loadProducts(storeQuery(), pageSize: 40);
    final body = await sent.future; current = false;
    response.complete(SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': pageData(body)})));
    await expectLater(result, throwsFormatException);
  });
  test('LF-PAGER page A to B retains each verified content and policy through the existing admission cache', () async {
    var second = false;
    final transport = OwnerTransport((body) async {
      final data = pageData(body);
      if (second) {
        final row = ((data['items'] as List).single as Map)['row'] as Map;
        row.addAll(<String, dynamic>{'skuId': 'sku-two', 'canonicalProductId': 'canonical-two', 'verifiedPackId': 'pack-two'});
        ((row['listings'] as List).single as Map).addAll(<String, dynamic>{'listingId': 'listing-${'e' * 64}',
          'skuId': 'sku-two', 'canonicalProductId': 'canonical-two', 'verifiedPackId': 'pack-two'});
        (row['content'] as Map).addAll(<String, dynamic>{'title': 'Second verified product', 'description': 'Second product description'});
        final terms = (row['channels'] as List).single as Map;
        terms['priceMinor'] = 26025; terms['mrpMinor'] = 28050;
        final envelope = row['supplierPolicy'] as Map;
        envelope['skuId'] = 'sku-two';
        (envelope['policy'] as Map).addAll(<String, dynamic>{'id': 'host-supplier-policy-sku-two', 'productIds': ['sku-two']});
        (data['page'] as Map)['snapshotId'] = 'e' * 64;
      }
      return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': data}));
    });
    final connection = pageGateway(transport), readback = WorkspaceCatalogueReadback(
      gateway: pageGateway(transport), context: () => 'host-owner', now: () => at);
    final source = WorkspaceStoreCatalogueSource(gateway: connection, storeId: 'store-one',
      current: () => true, contentReadback: readback);
    final core = BuySession();
    final consumer = BuyV2Session(core: core,
      cataloguePageSource: source, productContentAdapter: readback, reviewDataEnabled: false, catalogueNow: () => at);
    addTearDown(core.dispose); addTearDown(consumer.dispose); addTearDown(readback.dispose);
    final pager = consumer.acquireCatalogueProducts('host-public-content');
    await pager.open(storeQuery());
    final first = pager.page!.items.single;
    expect(first.priceMinor, 26000);
    expect(consumer.productContentFor(first).description, 'Verified host description');
    expect(consumer.productContentFor(first).supplierPolicy!.productIds, {'sku-one'});
    second = true;
    expect((await source.loadProducts(storeQuery(), pageSize: 40)).items.single.sourceSkuId, 'sku-two');
    await pager.refresh();
    expect(pager.message, isNull);
    final other = pager.page!.items.single;
    expect(other.priceMinor, 26025); expect(other.mrpMinor, 28050);
    expect(consumer.openProduct(other.id), isTrue);
    expect(consumer.productContentFor(other).description, 'Second product description');
    expect(consumer.productContentFor(other).supplierPolicy!.productIds, {'sku-two'});
    expect(readback.snapshotFor(first).supplierPolicy!.productIds, {'sku-one'});
    consumer.releaseCatalogueProducts('host-public-content');
  });
  test('LF-PAGER page admission cannot bypass policy highwater or retired cache context', () async {
    var revision = 2, owner = 'first-owner';
    final connection = pageGateway(OwnerTransport((body) async {
      final data = pageData(body);
      (((data['items'] as List).single as Map)['row'] as Map)['supplierPolicy'] = policyEnvelope(revision: revision);
      return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': data}));
    }));
    final cache = WorkspaceCatalogueReadback(gateway: connection, context: () => owner, now: () => at);
    addTearDown(cache.dispose);
    final source = WorkspaceStoreCatalogueSource(gateway: connection, storeId: 'store-one',
      current: () => true, contentReadback: cache);
    final first = (await source.loadProducts(storeQuery(), pageSize: 40)).items.single;
    expect(cache.snapshotFor(first).supplierPolicy!.revision, 'policy-v2');
    revision = 1;
    final old = (await source.loadProducts(storeQuery(), pageSize: 40)).items.single;
    expect(cache.snapshotFor(old).state, BuyV2ProductContentState.unavailable);
    expect(cache.snapshotFor(old).supplierPolicyResolutionPending, isTrue);
    owner = 'second-owner';
    cache.admitPublicEntry(factoryEntry(publicPage()), expectedContext: 'first-owner');
    expect(cache.snapshotFor(first).state, BuyV2ProductContentState.unavailable);
  });
  test('LF-PAISE legacy products and Cart need canonical minor amounts', () {
    final legacy = product;
    final line = BuyV2CartLine(product: product, quantity: 3);
    expect(legacy.priceMinor, 26000);
    expect(line.totalMinor, 78000);
    expect(legacy.mrpMinor, 28000);
  });
  test('LF-PAISE quote term and original request contracts retain exact money', () {
    const line = BuyV2CheckoutQuoteLine.minor(fulfilmentKey: 'host-exact', itemSubtotalMinor: 1025,
      couponSavingMinor: 1, taxMinor: 2, freightMinor: 3, deliveryFeeMinor: 4,
      tipMinor: 5, paymentChargeMinor: 6, totalMinor: 1044);
    const group = BuyV2CheckoutPaymentGroup.minor(id: 'host-group', fulfilmentKeys: {'host-exact'},
      paymentMethod: 'UPI', totalMinor: 1044, amountDueNowMinor: 1);
    final quote = BuyV2CheckoutQuote.minor(id: 'host-quote', sourceId: 'host-quote-source', evaluatedAt: at,
      validUntil: at.add(const Duration(minutes: 5)), lines: const [line], totalMinor: 1044, paymentGroups: const [group]);
    const term = BuyV2CommercialPaymentTerm.minor(id: 'host-term', fulfilmentKey: 'host-exact',
      destination: BuyV2Destination.wholesale, supplierName: 'Host Store',
      kind: BuyV2CommercialPaymentTermKind.bookingBalanceBeforeDispatch,
      orderTotalMinor: 1044, amountDueNowMinor: 1, balanceDueMinor: 1043,
      balanceDueLabel: 'Before dispatch', sourceId: 'host-terms', upiTransactionLimitMinor: 20000000);
    expect([line.itemSubtotalMinor, line.couponSavingMinor, line.taxMinor, line.freightMinor,
      line.deliveryFeeMinor, line.tipMinor, line.paymentChargeMinor, line.totalMinor], [1025, 1, 2, 3, 4, 5, 6, 1044]);
    expect(quote.totalMinor, 1044); expect(group.amountDueNowMinor, 1);
    expect(term.orderTotalMinor, 1044); expect(term.balanceDueMinor, 1043);
    expect(term.upiTransactionLimitMinor, 20000000); expect(term.hasValidMoney, isTrue);
    expect(() => quote.total, throwsFormatException); expect(() => line.total, throwsFormatException);
    expect(() => group.amountDueNow, throwsFormatException); expect(() => term.orderTotal, throwsFormatException);
    final request = BuyV2OrderPlacementRequest.minor(lines: [BuyV2CartLine(product: product, quantity: 1)],
      address: const BuyV2Address(id: 'host-address', kind: BuyV2AddressKind.home, label: 'Host', recipient: 'Host buyer',
        phone: '9000000000', line: 'Host address', area: 'Host area', pinCode: '342003', landmark: ''), paymentMethod: 'UPI', totalMinor: 1044,
      amountDueNowMinor: 1, idempotencyKey: 'host-original');
    expect(request.totalMinor, 1044); expect(request.amountDueNowMinor, 1);
    expect(request.hasValidMoney, isTrue); expect(() => request.total, throwsFormatException);
    const balance = BuyV2BalancePaymentResult.minor(state: BuyV2BalancePaymentState.due,
      amountDueMinor: 1043, dueLabel: 'Host balance', customerMessage: 'Host result');
    expect(balance.amountDueMinor, 1043); expect(() => balance.amountDue, throwsFormatException);
  });
  const frozenAddress = BuyV2Address(id: 'host-frozen-address', kind: BuyV2AddressKind.home,
    label: 'Host', recipient: 'Host buyer', phone: '9000000000', line: 'Host address',
    area: 'Host area', pinCode: '342003', landmark: '');
  test('LF-PAISE legacy commercial DTOs preserve required rupee values and total inference', () {
    const line = BuyV2CheckoutQuoteLine(fulfilmentKey: 'host-legacy', itemSubtotal: 20,
      couponSaving: 1, tax: 2, freight: 3, deliveryFee: 4, tip: 5, paymentCharge: 6, total: 39);
    final quote = BuyV2CheckoutQuote(id: 'host-legacy', sourceId: 'host-legacy-source', evaluatedAt: at,
      validUntil: at.add(const Duration(minutes: 5)), lines: const [line],
      total: [line].fold(0, (sum, value) => sum + value.total));
    const group = BuyV2CheckoutPaymentGroup(id: 'host-legacy', fulfilmentKeys: {'host-legacy'},
      paymentMethod: 'UPI', total: 39, amountDueNow: 1);
    const term = BuyV2CommercialPaymentTerm(id: 'host-legacy', fulfilmentKey: 'host-legacy',
      destination: BuyV2Destination.wholesale, supplierName: 'Host Store', kind: BuyV2CommercialPaymentTermKind.bookingBalanceOnDelivery,
      orderTotal: 39, amountDueNow: 1, balanceDue: 38, balanceDueLabel: 'At delivery', sourceId: 'host-legacy-source',
      upiTransactionLimit: 200000);
    const balance = BuyV2BalancePaymentResult(state: BuyV2BalancePaymentState.due, amountDue: 38,
      dueLabel: 'At delivery', customerMessage: 'Host balance');
    expect(line.hasValidMoney, isTrue); expect(line.total, 39); expect(quote.totalMinor, 3900);
    expect(group.amountDueNow, 1); expect(group.amountDueNowMinor, 100);
    expect(term.hasValidMoney, isTrue); expect(term.orderTotal, 39); expect(term.balanceDueMinor, 3800);
    expect(term.upiTransactionLimit, 200000); expect(term.upiTransactionLimitMinor, 20000000);
    expect(balance.amountDue, 38); expect(balance.amountDueMinor, 3800);
  });
  test('LF-PAISE exact quote arithmetic uses BigInt before netting discounts', () {
    const maximum = 9007199254740991;
    const value = BuyV2CheckoutQuoteLine.minor(fulfilmentKey: 'host-maximum', itemSubtotalMinor: maximum,
      couponSavingMinor: 1, taxMinor: 1, freightMinor: 0, deliveryFeeMinor: 0, tipMinor: 0,
      paymentChargeMinor: 0, totalMinor: maximum);
    expect(value.hasValidMoney, isTrue);
    const invalid = BuyV2CheckoutQuoteLine.minor(fulfilmentKey: 'host-invalid', itemSubtotalMinor: 1,
      couponSavingMinor: 2, taxMinor: 1, freightMinor: 0, deliveryFeeMinor: 0, tipMinor: 0,
      paymentChargeMinor: 0, totalMinor: 0);
    expect(invalid.hasValidMoney, isFalse);
  });
  for (final invalid in [-1, 9007199254740992]) {
    test('LF-PAISE commercial exact $invalid amount cannot become a rounded legacy amount', () {
      final group = BuyV2CheckoutPaymentGroup.minor(id: 'host-invalid', fulfilmentKeys: const {'host-invalid'},
        paymentMethod: 'UPI', totalMinor: invalid, amountDueNowMinor: 1);
      final request = BuyV2OrderPlacementRequest.minor(lines: const [], address: frozenAddress,
        paymentMethod: 'UPI', idempotencyKey: 'host-invalid', totalMinor: invalid, amountDueNowMinor: 1);
      expect(group.hasValidMoney, isFalse); expect(request.hasValidMoney, isFalse);
      expect(() => group.totalMinor, throwsFormatException); expect(() => group.total, throwsFormatException);
      expect(() => request.totalMinor, throwsFormatException); expect(() => request.total, throwsFormatException);
    });
  }
  BuyV2CheckoutGroupAttempt frozenPayment({required bool grouped, bool exact = true, int? totalOverride}) {
    final value = exact ? product.copyWith(priceMinor: 1025) : product;
    final request = exact ? BuyV2OrderPlacementRequest.minor(
      lines: [BuyV2CartLine(product: value, quantity: 1)], address: frozenAddress,
      paymentMethod: 'UPI', idempotencyKey: 'host-original-key', totalMinor: totalOverride ?? 1025, amountDueNowMinor: 1,
      checkoutAttemptId: grouped ? 'host-original-attempt' : null, paymentGroupId: grouped ? 'host-original-group' : null,
      checkoutQuoteId: 'host-original-quote', deliveryInstructionsByProductId: {value.id: 'Host original note'}) :
      BuyV2OrderPlacementRequest(lines: [BuyV2CartLine(product: value, quantity: 1)], address: frozenAddress,
        paymentMethod: 'UPI', idempotencyKey: 'host-original-key', total: 260, amountDueNow: 1,
        checkoutAttemptId: grouped ? 'host-original-attempt' : null, paymentGroupId: grouped ? 'host-original-group' : null,
        checkoutQuoteId: 'host-original-quote', deliveryInstructionsByProductId: {value.id: 'Host original note'});
    return BuyV2CheckoutGroupAttempt(
      request: request,
      fulfilmentKeys: const {'host-original-fulfilment'},
      obligations: [BuyV2CheckoutFulfilmentObligation(fulfilmentKey: 'host-original-fulfilment',
        productIds: {value.id}, totalMinor: exact ? 1025 : 26000, dueNowMinor: exact ? 1 : 100)],
      state: BuyV2CheckoutSubmissionState.paymentUnknown, paymentReference: 'host-original-reference');
  }
  BuyV2CustomerStateSnapshot frozenSnapshot(BuyV2CheckoutGroupAttempt payment, {required bool grouped}) =>
    BuyV2CustomerStateSnapshot(cartQuantities: {product.id: 1}, checkoutIdempotencyKey: 'host-original-key',
      legacyCheckoutAttempt: grouped ? null : BuyV2LegacyCheckoutAttempt(ownerScope: 'host-paise', payment: payment),
      checkoutPaymentAttempt: grouped ? BuyV2CheckoutPaymentAttempt(id: 'host-original-attempt', ownerScope: 'host-paise',
        quoteValidUntil: at.add(const Duration(minutes: 5)), groups: [payment]) : null);
  for (final grouped in [false, true]) {
    for (final difference in ['none', 'total', 'paid', 'balance', 'price', 'unknown paid']) {
      test('LF-PAISE original confirmation grouped=$grouped difference=$difference retains exact commitment', () async {
        final preferences = _ExactMoneyHostPreferences();
        final store = BuyV2SharedPreferencesCustomerStateStore(preferences, ownerScope: 'host-paise');
        final frozen = frozenPayment(grouped: grouped), request = frozenPayment(grouped: grouped).request;
        expect(await store.write(frozenSnapshot(frozen, grouped: grouped)), isTrue);
        final order = BuyV2Order.minor(id: 'host-confirmed-order', purchaseId: 'host-confirmed-purchase',
          destination: BuyV2Destination.shop, title: 'Host original purchase', itemSummary: 'One host SKU',
          totalMinor: difference == 'total' ? 1026 : 1025, partner: 'Host Store', partnerType: 'Retailer',
          promise: 'Host delivery', destinationLabel: request.address.shortLine, recipient: request.address.recipient,
          addressLine: request.address.line, paymentMethod: request.paymentMethod, progress: 0, status: BuyV2OrderStatus.preparing,
          productIds: [product.id], lines: [BuyV2CartLine(product: request.lines.single.product.copyWith(
            priceMinor: difference == 'price' ? 1026 : 1025), quantity: 1)],
          amountPaidNowMinor: difference == 'unknown paid' ? null : difference == 'paid' ? 2 : 1,
          balanceDueMinor: difference == 'total' || difference == 'balance' ? 1025 : difference == 'paid' ? 1023 : 1024);
        final commerce = _HostExactOrderCommerce()..reconciliation = BuyV2OrderPlacementResult(
          outcome: BuyV2OrderPlacementOutcome.confirmed, customerMessage: 'Host original readback', orders: [order],
          purchaseReference: 'host-confirmed-purchase', paymentReference: 'host-original-reference',
          idempotencyKey: 'host-original-key', checkoutAttemptId: grouped ? 'host-original-attempt' : null,
          paymentGroupId: grouped ? 'host-original-group' : null);
        final core = BuySession();
        final session = BuyV2Session(core: core, commerceAdapter: commerce, customerStateStore: store,
          cataloguePageSource: _ExactMoneyHostCatalogue()..rows.add(product.copyWith(priceMinor: 1025)),
          reviewDataEnabled: true, catalogueNow: () => at);
        addTearDown(core.dispose); addTearDown(session.dispose);
        await session.restoreCustomerState(restoreBrowsing: false);
        expect(await session.reconcilePayment(), difference == 'none', reason: session.notice);
        expect(commerce.reconciliationCalls, 1); expect(commerce.placementCalls, 0);
        if (difference == 'none') {
          expect(session.orders.firstWhere((value) => value.id == order.id).payableTotalMinor, 1025);
          expect(session.orders.firstWhere((value) => value.id == order.id).amountPaidNowMinor, 1);
          expect(session.quantityFor(product.id), 0);
        } else {
          expect(session.checkoutRequiresResolution, isTrue);
          expect(session.quantityFor(product.id), 1);
          expect(session.orders.any((value) => value.id == order.id), isFalse);
          final retained = grouped ? session.currentCheckoutPaymentGroup!.request : session.legacyCheckoutAttempt!.payment.request;
          expect(retained.totalMinor, 1025); expect(retained.amountDueNowMinor, 1);
          expect(retained.idempotencyKey, 'host-original-key');
        }
      });
    }
  }
  for (final grouped in [false, true]) {
    test('LF-PAISE frozen session restart grouped=$grouped uses original exact commitment without new placement', () async {
      final preferences = _ExactMoneyHostPreferences();
      final store = BuyV2SharedPreferencesCustomerStateStore(preferences, ownerScope: 'host-paise');
      expect(await store.write(frozenSnapshot(frozenPayment(grouped: grouped), grouped: grouped)), isTrue);
      final core = BuySession();
      final source = _ExactMoneyHostCatalogue()..rows.add(product.copyWith(priceMinor: 1025));
      final session = BuyV2Session(core: core, customerStateStore: store, cataloguePageSource: source,
        reviewDataEnabled: true, catalogueNow: () => at);
      addTearDown(core.dispose); addTearDown(session.dispose);
      await session.restoreCustomerState(restoreBrowsing: false);
      expect(session.checkoutRequiresResolution, isTrue);
      expect(session.checkoutPayableTotalMinor, 1025);
      expect(session.checkoutAmountDueNowMinor, 1);
      expect(session.checkoutBalanceDueMinor, 1024);
      expect(session.checkoutPaymentActionAmountMinor, 1);
      expect(session.checkoutPaymentCount, 1);
      final original = grouped ? session.currentCheckoutPaymentGroup!.request : session.legacyCheckoutAttempt!.payment.request;
      expect(original.idempotencyKey, 'host-original-key');
      expect(original.totalMinor, 1025); expect(original.amountDueNowMinor, 1);
      expect(session.addProduct(product.id), isFalse);
      expect(session.checkoutRequiresResolution, isTrue);
      expect(grouped ? session.checkoutPaymentGroups.single.id : original.idempotencyKey,
        grouped ? 'host-original-group' : 'host-original-key');
    });
    for (final exact in [false, true]) {
      test('LF-PAISE frozen request restart grouped=$grouped exact=$exact retains original amount and identity', () async {
        final preferences = _ExactMoneyHostPreferences();
        BuyV2SharedPreferencesCustomerStateStore fresh() => BuyV2SharedPreferencesCustomerStateStore(preferences, ownerScope: 'host-paise');
        final original = frozenPayment(grouped: grouped, exact: exact);
        expect(original.hasValidObligations, isTrue);
        expect(await fresh().write(frozenSnapshot(original, grouped: grouped)), isTrue);
        final restored = (await fresh().read())!;
        final payment = grouped ? restored.checkoutPaymentAttempt!.groups.single : restored.legacyCheckoutAttempt!.payment;
        expect(restored.paymentRecoveryIncomplete, isFalse);
        expect(restored.cartQuantities[product.id], 1);
        expect(payment.request.totalMinor, exact ? 1025 : 26000);
        expect(payment.request.amountDueNowMinor, exact ? 1 : 100);
        expect(payment.request.idempotencyKey, 'host-original-key');
        expect(payment.request.checkoutAttemptId, grouped ? 'host-original-attempt' : null);
        expect(payment.request.paymentGroupId, grouped ? 'host-original-group' : null);
        expect(payment.request.checkoutQuoteId, 'host-original-quote');
        expect(payment.request.deliveryInstructionsByProductId, {product.id: 'Host original note'});
        expect(payment.paymentReference, 'host-original-reference');
        expect(payment.state, BuyV2CheckoutSubmissionState.paymentUnknown);
        expect(payment.request.lines.single.totalMinor, exact ? 1025 : 26000);
        expect(payment.hasValidObligations, isTrue);
        final raw = jsonDecode(preferences.values.values.single) as Map;
        final attempt = raw[grouped ? 'checkoutPaymentAttempt' : 'legacyCheckoutAttempt'] as Map;
        final request = (grouped ? (attempt['groups'] as List).single : attempt['payment'])['request'] as Map;
        expect(attempt['version'], exact ? 2 : 1);
        expect(request.containsKey('totalMinor'), exact);
        expect(request.containsKey('total'), !exact);
        if (!exact) expect(payment.request.total, 260);
      });
    }
    for (final corrupt in ['null', 'string', 'negative', 'overflow', 'conflict', 'downgrade', 'obligation', 'version', 'missing']) {
      test('LF-PAISE corrupt frozen $corrupt grouped=$grouped keeps recovery held and original bytes', () async {
        final preferences = _ExactMoneyHostPreferences();
        final store = BuyV2SharedPreferencesCustomerStateStore(preferences, ownerScope: 'host-paise');
        expect(await store.write(frozenSnapshot(frozenPayment(grouped: grouped), grouped: grouped)), isTrue);
        final key = preferences.values.keys.single;
        final raw = jsonDecode(preferences.values[key]!) as Map;
        final attempt = raw[grouped ? 'checkoutPaymentAttempt' : 'legacyCheckoutAttempt'] as Map;
        final payment = (grouped ? (attempt['groups'] as List).single : attempt['payment']) as Map;
        final request = payment['request'] as Map;
        switch (corrupt) {
          case 'null': request['amountDueNowMinor'] = null;
          case 'string': request['totalMinor'] = '1025';
          case 'negative': request['totalMinor'] = -1;
          case 'overflow': request['totalMinor'] = 9007199254740992;
          case 'conflict': request['total'] = 11;
          case 'downgrade': attempt['version'] = 1; request['total'] = 10; request['amountDueNow'] = 1;
          case 'obligation': (payment['obligations'] as List).single['totalMinor'] = 1026;
          case 'version': attempt['version'] = 2.0;
          case 'missing': request.remove('totalMinor'); request['total'] = 10;
        }
        final corruptedBytes = jsonEncode(raw); preferences.values[key] = corruptedBytes;
        final restored = (await store.read())!;
        expect(restored.paymentRecoveryIncomplete, isTrue);
        expect(restored.checkoutPaymentAttempt, isNull); expect(restored.legacyCheckoutAttempt, isNull);
        expect(restored.cartQuantities[product.id], 1);
        expect(preferences.values[key], corruptedBytes, reason: 'A read must not erase or rewrite original evidence');
      });
    }
  }
  for (final grouped in [false, true]) {
  testWidgets('LF-PAISE confirmation renders exact original total paid and balance grouped=$grouped', (tester) async {
    final preferences = _ExactMoneyHostPreferences();
    final store = BuyV2SharedPreferencesCustomerStateStore(preferences, ownerScope: 'host-paise');
    final payment = frozenPayment(grouped: grouped), request = frozenPayment(grouped: grouped).request;
    expect(await store.write(frozenSnapshot(payment, grouped: grouped)), isTrue);
    final order = BuyV2Order.minor(id: 'host-confirmed-order', purchaseId: 'host-confirmed-purchase',
      destination: BuyV2Destination.shop, title: 'Host original purchase', itemSummary: 'One host SKU', totalMinor: 1025,
      partner: 'Host Store', partnerType: 'Retailer', promise: 'Host delivery', destinationLabel: request.address.shortLine,
      recipient: request.address.recipient, addressLine: request.address.line, paymentMethod: request.paymentMethod,
      progress: 0, status: BuyV2OrderStatus.preparing, productIds: [product.id], lines: request.lines,
      amountPaidNowMinor: 1, balanceDueMinor: 1024);
    final commerce = _HostExactOrderCommerce()..reconciliation = BuyV2OrderPlacementResult(
      outcome: BuyV2OrderPlacementOutcome.confirmed, customerMessage: 'Host original readback', orders: [order],
      purchaseReference: 'host-confirmed-purchase', paymentReference: 'host-original-reference', idempotencyKey: 'host-original-key',
      checkoutAttemptId: grouped ? 'host-original-attempt' : null, paymentGroupId: grouped ? 'host-original-group' : null);
    final core = BuySession();
    final session = BuyV2Session(core: core, commerceAdapter: commerce, customerStateStore: store,
      cataloguePageSource: _ExactMoneyHostCatalogue()..rows.add(product.copyWith(priceMinor: 1025)),
      reviewDataEnabled: true, catalogueNow: () => at);
    addTearDown(core.dispose); addTearDown(session.dispose);
    await session.restoreCustomerState(restoreBrowsing: false);
    expect(await session.reconcilePayment(), isTrue);
    await tester.pumpWidget(MaterialApp(theme: MoolTheme.light(), home: Scaffold(body: BuyV2ConfirmationView(session: session))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('₹10.25'), findsWidgets);
    expect(find.text('Paid now ₹0.01 · Balance ₹10.24'), findsOneWidget);
    expect(commerce.placementCalls, 0);
  });
  }
  test('LF-PAISE invalid original request cannot replace the last saved hold', () async {
    final preferences = _ExactMoneyHostPreferences();
    final store = BuyV2SharedPreferencesCustomerStateStore(preferences, ownerScope: 'host-paise');
    expect(await store.write(frozenSnapshot(frozenPayment(grouped: false), grouped: false)), isTrue);
    final before = preferences.values.values.single;
    expect(await store.write(frozenSnapshot(frozenPayment(grouped: false, totalOverride: -1), grouped: false)), isFalse);
    expect(preferences.values.values.single, before);
  });
  BuyV2CheckoutPaymentAttempt twoFrozenGroups({int total = 1}) => BuyV2CheckoutPaymentAttempt(
    id: 'host-two-groups', ownerScope: 'host-paise', quoteValidUntil: at.add(const Duration(minutes: 5)),
    groups: [for (final id in ['first', 'second']) BuyV2CheckoutGroupAttempt(
      request: BuyV2OrderPlacementRequest.minor(
        lines: [BuyV2CartLine(product: product.copyWith(id: 'host-$id', priceMinor: total), quantity: 1)],
        address: frozenAddress, paymentMethod: 'UPI', totalMinor: total, amountDueNowMinor: 0,
        idempotencyKey: 'host-key-$id', checkoutAttemptId: 'host-two-groups', paymentGroupId: 'host-group-$id',
        checkoutQuoteId: 'host-two-groups-quote'),
      fulfilmentKeys: {'host-scope-$id'}, obligations: [BuyV2CheckoutFulfilmentObligation(
        fulfilmentKey: 'host-scope-$id', productIds: {'host-$id'}, totalMinor: total, dueNowMinor: 0)],
      state: BuyV2CheckoutSubmissionState.paymentUnknown)]);
  test('LF-PAISE oversized frozen aggregate cannot overwrite a recoverable original', () async {
    final preferences = _ExactMoneyHostPreferences();
    final store = BuyV2SharedPreferencesCustomerStateStore(preferences, ownerScope: 'host-paise');
    expect(await store.write(BuyV2CustomerStateSnapshot(checkoutPaymentAttempt: twoFrozenGroups())), isTrue);
    final before = preferences.values.values.single;
    expect(await store.write(BuyV2CustomerStateSnapshot(
      checkoutPaymentAttempt: twoFrozenGroups(total: 4503599627370496))), isFalse);
    expect(preferences.values.values.single, before);
  });
  for (final version in [1, 2]) {
    test('LF-PAISE oversized stored aggregate version=$version is incomplete recovery not a throwable usable attempt', () async {
      final preferences = _ExactMoneyHostPreferences();
      final store = BuyV2SharedPreferencesCustomerStateStore(preferences, ownerScope: 'host-paise');
      expect(await store.write(BuyV2CustomerStateSnapshot(checkoutPaymentAttempt: twoFrozenGroups())), isTrue);
      final key = preferences.values.keys.single;
      final raw = jsonDecode(preferences.values[key]!) as Map;
      final attempt = raw['checkoutPaymentAttempt'] as Map; attempt['version'] = version;
      for (final group in attempt['groups'] as List) {
        final request = group['request'] as Map;
        if (version == 1) {
          request.remove('totalMinor'); request.remove('amountDueNowMinor');
          request['total'] = 45035996273705; request['amountDueNow'] = 0;
        } else { request['totalMinor'] = 4503599627370496; }
        (group['obligations'] as List).single['totalMinor'] = version == 1 ? 4503599627370500 : 4503599627370496;
      }
      final corrupted = jsonEncode(raw); preferences.values[key] = corrupted;
      final restored = (await store.read())!;
      expect(restored.paymentRecoveryIncomplete, isTrue); expect(restored.checkoutPaymentAttempt, isNull);
      expect(preferences.values[key], corrupted);
    });
  }
  test('LF-PAISE benefit saving and threshold require canonical minor amounts', () {
    const value = BuyV2CartBenefit(id: 'host-exact-coupon', kind: BuyV2CartBenefitKind.coupon,
      destination: BuyV2Destination.shop, title: 'Host coupon', detail: 'Isolated host eligibility',
      sourceId: 'host-benefits', savingAmount: 1, minimumSpend: 20);
    final exact = value;
    expect(exact.savingAmountMinor, 100); expect(exact.minimumSpendMinor, 2000);
  });
  BuyV2CartBenefit hostBenefit({int saving = 25, int minimum = 2001}) => BuyV2CartBenefit(
    id: 'host-exact-coupon', kind: BuyV2CartBenefitKind.coupon, destination: BuyV2Destination.shop,
    title: 'Host coupon', detail: 'Isolated host eligibility', sourceId: 'host-benefits',
    savingAmountMinor: saving, minimumSpendMinor: minimum, scope: BuyV2CartBenefitScope.store, storeId: 'store-one',
    strategy: BuyV2CartBenefitStrategy.minimumOrder, validUntil: at.add(const Duration(hours: 1)), revision: 1);
  Future<BuyV2Session> benefitSession(BuyV2CartBenefitsAdapter adapter, List<BuyV2Product> values,
    {BuyV2ProductFactsAdapter? facts, BuyV2CheckoutQuoteAdapter? quoteAdapter,
      BuyV2CommercialPaymentTermsAdapter? termsAdapter, BuyV2TipPolicy tipPolicy = const BuyV2DisabledTipPolicy(),
      BuyV2CustomerStateStore? customerStateStore, BuyV2CommerceAdapter? commerceAdapter, bool reviewDataEnabled = true,
      WorkspacePublicStockReader? stockReader, WorkspaceProductPresentationGateway? presentations, bool disposeAtTearDown = true}) async {
    final core = BuySession(), source = _ExactMoneyHostCatalogue()..rows.addAll(values);
    final session = BuyV2Session(core: core, cataloguePageSource: source, reviewDataEnabled: reviewDataEnabled, catalogueNow: () => at,
      productFactsAdapter: facts ?? const BuyV2CatalogueProductFactsAdapter(), cartBenefitsAdapter: adapter,
      checkoutQuoteAdapter: quoteAdapter, commercialPaymentTermsAdapter: termsAdapter, tipPolicy: tipPolicy,
      customerStateStore: customerStateStore, commerceAdapter: commerceAdapter, storeStockReader: stockReader, productPresentations: presentations);
    addTearDown(core.dispose); if (disposeAtTearDown) addTearDown(session.dispose);
    if (customerStateStore != null) await session.restoreCustomerState(restoreBrowsing: false);
    final pager = session.acquireCatalogueProducts('host-paise-benefits');
    addTearDown(() => session.releaseCatalogueProducts('host-paise-benefits'));
    await pager.open(BuyV2CatalogueQuery(destination: values.first.destination, regionId: 'host-region',
      areaScope: BuyV2CatalogueAreaScope.allAreas));
    expect(pager.page?.items.length, values.length, reason: pager.message);
    return session;
  }
  Future<void> mountOptionalDetails(WidgetTester tester, BuyV2Session session, double scale) async {
    tester.view.physicalSize = const Size(320, 800); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: MoolTheme.light(), builder: (context, child) =>
      MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
      home: Scaffold(body: AnimatedBuilder(animation: session, builder: (context, _) => BuyV2ProductView(session: session)))));
    await tester.pumpAndSettle();
  }
  Future<void> revealOptionalDetails(WidgetTester tester, BuyV2Product selected, Finder control) async {
    await tester.scrollUntilVisible(control, 220, scrollable: find.descendant(
      of: find.byKey(PageStorageKey('buy-product-${selected.id}')), matching: find.byType(Scrollable)).first);
    await tester.ensureVisible(control); await tester.pumpAndSettle();
  }
  void enableHostStockEligibility(BuyV2Session session, BuyV2Product selected, _HostOperationalFacts adapter) {
    adapter.reply = (p) => BuyV2ProductFactsSnapshot(productId: p.id, priceMinor: p.priceMinor,
      deliveryPromise: 'Host confirmed delivery', partner: p.seller, orderabilityLabel: 'Available to add',
      sourceId: 'host-stock-consumer-facts', observedAt: at, storeOperatingState: BuyV2StoreOperatingState.open,
      eligibility: BuyV2OfferEligibility(productId: selected.id, storeId: selected.storeId!,
        sourceRevision: 'host-stock-eligibility', customerLocationKey: session.eligibilityLocationKey,
        observedAt: at, expiresAt: at.add(const Duration(minutes: 15)), offerClass: selected.offerClass!,
        channelEnabled: true, storeReady: true, fleetAvailable: true, customerLocationConfirmed: true,
        options: {BuyV2DeliveryOption.quick}));
    expect(session.refreshProductFacts(selected.id), true);
  }
  BuyV2CartBenefit identityCoupon({String id = 'shared-coupon', String store = 'store-one', String source = 'host-benefits',
    int revision = 1, int saving = 25}) => BuyV2CartBenefit(id: id, kind: BuyV2CartBenefitKind.coupon,
      destination: BuyV2Destination.shop, title: '$store $source r$revision', detail: 'Isolated host scoped coupon',
      sourceId: source, revision: revision, scope: BuyV2CartBenefitScope.store, storeId: store,
      savingAmountMinor: saving, validUntil: at.add(const Duration(hours: 1)));
  for (final live in [false, true]) {
    for (final difference in ['Store', 'source', 'revision']) {
      test('LF08 ID ${live ? 'live' : 'local'} retains same-ID $difference candidates without stacking', () async {
        final adapter = live ? _HostLiveBenefits() : _HostMinorBenefits();
        final a = product.copyWith(priceMinor: 2000, deliveryPromise: 'Host-only fulfilment');
        final b = a.copyWith(id: 'host-other-store-sku', storeId: 'store-two');
        final first = identityCoupon(), second = identityCoupon(store: difference == 'Store' ? 'store-two' : 'store-one',
          source: difference == 'source' ? 'host-other-source' : 'host-benefits', revision: difference == 'revision' ? 2 : 1, saving: 35);
        final buyer = await benefitSession(adapter, [a, b]);
        expect(buyer.addProduct(a.id), true); expect(buyer.addProduct(b.id), true);
        adapter.offers.addAll([first, first, second]);
        if (live) expect(await buyer.refreshCartBenefits(), true);
        expect(buyer.cartBenefits(kind: BuyV2CartBenefitKind.coupon), [first, second]);
        expect(buyer.chooseCartBenefit(first), true); expect(buyer.chooseCartBenefit(second), true);
        expect(buyer.selectedCartBenefitsFor({BuyV2Destination.shop}), [second]);
        expect(buyer.scopedCouponSavingMinor, 35); expect(buyer.cartTotalMinor, 4000);
      });
    }
    test('LF08 ID ${live ? 'live' : 'local'} product preview retains different source namespaces', () async {
      final adapter = live ? _HostLiveBenefits() : _HostMinorBenefits();
      final value = product.copyWith(priceMinor: 2000, deliveryPromise: 'Host-only fulfilment');
      final first = identityCoupon(), second = identityCoupon(source: 'host-other-source');
      adapter.offers.addAll([first, first, second]);
      final buyer = await benefitSession(adapter, [value]);
      expect(await buyer.refreshProductBenefits(value.id), true);
      expect(buyer.productBenefitsFor(value), [first, second]);
    });
  }
  testWidgets('LF08 ID captured old Remove cannot clear a newer selected coupon', (tester) async {
    final adapter = _HostMinorBenefits(), value = product.copyWith(priceMinor: 2000, deliveryPromise: 'Host-only fulfilment');
    final first = identityCoupon(id: 'old-selection'), second = identityCoupon(id: 'new-selection', saving: 35);
    adapter.offers.addAll([first, second]);
    final buyer = await benefitSession(adapter, [value]);
    expect(buyer.addProduct(value.id), true); expect(buyer.chooseCartBenefit(first), true); buyer.openCart();
    await tester.pumpWidget(MaterialApp(theme: MoolTheme.light(), home: Scaffold(body: BuyV2CartView(session: buyer, onBrowseMore: () {}))));
    await tester.pumpAndSettle();
    final oldRemove = tester.widget<Semantics>(find.byKey(const ValueKey('buy-cart-benefit-remove-old-selection'))).properties.onTap!;
    expect(buyer.chooseCartBenefit(second), true);
    oldRemove();
    expect(buyer.selectedCartBenefit(kind: BuyV2CartBenefitKind.coupon, destination: BuyV2Destination.shop), same(second));
    expect(buyer.scopedCouponSavingMinor, 35);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('LF08 ID old-owner Remove is retired and Cart listener follows the replacement session', (tester) async {
    final value = product.copyWith(priceMinor: 2000, deliveryPromise: 'Host-only fulfilment');
    final coupon = identityCoupon(id: 'shared-owner-coupon'), replacement = identityCoupon(id: 'new-owner-choice', saving: 35);
    final a = _HostMinorBenefits()..offers.addAll([coupon, replacement]), b = _HostMinorBenefits()..offers.addAll([coupon, replacement]);
    final first = await benefitSession(a, [value]), second = await benefitSession(b, [value]);
    expect(first.addProduct(value.id), true); expect(first.chooseCartBenefit(coupon), true); first.openCart();
    expect(second.addProduct(value.id), true); expect(second.chooseCartBenefit(coupon), true); second.openCart();
    Widget page(BuyV2Session buyer) => MaterialApp(theme: MoolTheme.light(), home: Scaffold(body: BuyV2CartView(session: buyer, onBrowseMore: () {})));
    await tester.pumpWidget(page(first)); await tester.pumpAndSettle();
    final oldRemove = tester.widget<Semantics>(find.byKey(const ValueKey('buy-cart-benefit-remove-shared-owner-coupon'))).properties.onTap!;
    final oldSelect = tester.widget<Semantics>(find.byKey(const ValueKey('buy-cart-benefit-select-new-owner-choice'))).properties.onTap!;
    await tester.pumpWidget(page(second)); await tester.pumpAndSettle();
    final before = (saving: second.scopedCouponSavingMinor, total: second.cartTotalMinor,
      quote: second.checkoutQuote, quoteState: second.checkoutQuoteLoadState);
    oldSelect();
    expect(second.isCartBenefitSelected(coupon), true);
    oldRemove();
    expect(second.isCartBenefitSelected(coupon), true);
    expect((saving: second.scopedCouponSavingMinor, total: second.cartTotalMinor,
      quote: second.checkoutQuote, quoteState: second.checkoutQuoteLoadState), before);
    final retained = tester.element(find.descendant(of: find.byKey(const ValueKey('buy-cart-inline-benefits-owner')),
      matching: find.byWidgetPredicate((w) => w.runtimeType.toString() == '_CartBenefitsInline')));
    expect(second.chooseCartBenefit(replacement), true);
    expect(retained.dirty, true, reason: 'Current owner must schedule its actual listener component.');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-cart-benefit-remove-new-owner-choice')), findsOneWidget);
    expect(retained.dirty, false);
    expect(first.chooseCartBenefit(replacement), true);
    expect(retained.dirty, false, reason: 'Retired listener must not schedule the replacement owner UI.');
    await tester.pumpWidget(const SizedBox.shrink());
  });
  for (final scale in [1.0, 2.0]) {
    testWidgets('LF08 ID same-ID Store cards have separate action ownership at $scale', (tester) async {
      tester.view.devicePixelRatio = 1; tester.view.physicalSize = const Size(320, 800); addTearDown(tester.view.reset);
      final adapter = _HostMinorBenefits(), a = product.copyWith(priceMinor: 2000, deliveryPromise: 'Host-only fulfilment');
      final b = a.copyWith(id: 'host-second-store', storeId: 'store-two');
      final first = identityCoupon(), second = identityCoupon(store: 'store-two', saving: 35);
      adapter.offers.addAll([first, second]);
      final buyer = await benefitSession(adapter, [a, b]);
      buyer.addProduct(a.id); buyer.addProduct(b.id); buyer.chooseCartBenefit(second); buyer.openCart();
      await tester.pumpWidget(MaterialApp(theme: MoolTheme.light(), builder: (context, child) =>
        MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
        home: Scaffold(body: BuyV2CartView(session: buyer, onBrowseMore: () {}))));
      await tester.pumpAndSettle();
      final firstCard = find.byKey(ValueKey('buy-cart-benefit-owner-${BuyV2Session.benefitIdentity(first)}'));
      final secondCard = find.byKey(ValueKey('buy-cart-benefit-owner-${BuyV2Session.benefitIdentity(second)}'));
      final cartScroll = find.descendant(
        of: find.byKey(const PageStorageKey('buy-cart-all')),
        matching: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down),
      );
      expect(cartScroll, findsOneWidget);
      await tester.scrollUntilVisible(find.byKey(const ValueKey('buy-cart-inline-benefits-owner')), 220, scrollable: cartScroll);
      await tester.pumpAndSettle();
      expect(firstCard, findsOneWidget); expect(secondCard, findsOneWidget);
      expect(find.descendant(of: firstCard, matching: find.byKey(const ValueKey('buy-cart-benefit-select-shared-coupon'))), findsOneWidget);
      final remove = find.descendant(of: secondCard, matching: find.byKey(const ValueKey('buy-cart-benefit-remove-shared-coupon')));
      expect(remove, findsOneWidget);
      await Scrollable.ensureVisible(tester.element(remove), alignment: .2); await tester.pumpAndSettle();
      expect(remove.hitTestable(), findsOneWidget); await tester.tap(remove); await tester.pumpAndSettle();
      expect(buyer.selectedCartBenefitsFor({BuyV2Destination.shop}), isEmpty);
      expect(buyer.scopedCouponSavingMinor, 0); expect(buyer.cartTotalMinor, 4000);
      expect(tester.takeException(), isNull); await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  test('LF14 CART actual successful Add reports once; failed Add and Cart editing do not manufacture events', () async {
    final entry = factoryEntry(publicPage()), sent = <Map<String, Object?>>[], received = Completer<void>();
    final reporter = WorkspaceProductPresentationGateway(current: () => true, displayed: (_) => entry.readback,
      productPresentationsEnabled: false, cartAdditionsEnabled: true,
      gateway: AuthenticatedWorkspaceCatalogueGateway(endpoint: Uri.parse('https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
        credentials: Credentials(), now: () => at, transport: OwnerTransport((body) async {
          sent.add(body); if (!received.isCompleted) received.complete();
          return const SocialContentResponse(statusCode: 503, body: '{}'); // Telemetry failure never changes the accepted Cart.
        })));
    final facts = _HostOperationalFacts((p) => const BuyV2CatalogueProductFactsAdapter(includeReviewFixtures: false).snapshotFor(p));
    final buyer = await benefitSession(_HostMinorBenefits(), [entry.product], facts: facts, presentations: reporter, reviewDataEnabled: false);
    expect(buyer.addProduct(entry.product.id), false); expect(sent, isEmpty);
    enableHostStockEligibility(buyer, entry.product, facts);
    expect(buyer.addProduct(entry.product.id), true);
    await received.future.timeout(const Duration(seconds: 1));
    expect(sent, hasLength(1)); expect(sent.single['operation'], 'recordPublicCartAddition');
    expect(sent.single['skuId'], entry.product.sourceSkuId);
    expect(sent.single['listingId'], entry.product.id);
    expect(sent.single['presentationId'], matches(RegExp(r'^[a-f0-9]{32}$')));
    expect(sent.single.keys, isNot(contains('customerKey'))); expect(sent.single.keys, isNot(contains('quantity')));
    expect(buyer.quantityFor(entry.product.id), 1);
    buyer.openCart(); expect(buyer.setCartQuantity(entry.product.id, '2'), true);
    await Future<void>.delayed(Duration.zero);
    expect(sent, hasLength(1)); expect(buyer.quantityFor(entry.product.id), 2);
  });
  for (final saved in [true, false]) {
    test('LF14 CART Scheduled Add reports only confirmed save $saved and not choice replacement', () async {
      final entry = factoryEntry(publicPage()), sent = <Map<String, Object?>>[], received = Completer<void>();
      final store = _HostRetirableStateStore()..writesSucceed = saved;
      final reporter = WorkspaceProductPresentationGateway(current: () => true, displayed: (_) => entry.readback,
        productPresentationsEnabled: false, cartAdditionsEnabled: true,
        gateway: AuthenticatedWorkspaceCatalogueGateway(endpoint: Uri.parse('https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
          credentials: Credentials(), now: () => at, transport: OwnerTransport((body) async {
            sent.add(body); if (!received.isCompleted) received.complete();
            return const SocialContentResponse(statusCode: 503, body: '{}');
          })));
      final facts = _HostOperationalFacts((p) => const BuyV2CatalogueProductFactsAdapter(includeReviewFixtures: false).snapshotFor(p));
      final buyer = await benefitSession(_HostMinorBenefits(), [entry.product], facts: facts, presentations: reporter,
        customerStateStore: store, reviewDataEnabled: false);
      var slot = 'host-slot-A';
      facts.reply = (p) => BuyV2ProductFactsSnapshot(productId: p.id, priceMinor: p.priceMinor,
        deliveryPromise: 'Host Scheduled choice', partner: p.seller, orderabilityLabel: 'Available to add',
        sourceId: 'host-scheduled-cart-event', observedAt: at, storeOperatingState: BuyV2StoreOperatingState.open,
        eligibility: BuyV2OfferEligibility(productId: p.id, storeId: p.storeId!, sourceRevision: slot,
          customerLocationKey: buyer.eligibilityLocationKey, observedAt: at, expiresAt: at.add(const Duration(minutes: 15)),
          offerClass: p.offerClass!, channelEnabled: true, storeReady: true, fleetAvailable: true,
          customerLocationConfirmed: true, options: {BuyV2DeliveryOption.scheduled}, scheduledSlotId: slot,
          scheduledStart: at.add(const Duration(hours: 1)), scheduledEnd: at.add(const Duration(hours: 2))));
      buyer.refreshProductFacts(entry.product.id);
      expect(sent, isEmpty);
      final selected = buyer.scheduledWindowFor(entry.product)!;
      expect(await buyer.addProductForScheduledWindow(entry.product.id, selected), saved, reason: buyer.notice);
      if (!saved) { await Future<void>.delayed(Duration.zero); expect(sent, isEmpty); expect(buyer.cartLines, isEmpty); return; }
      await received.future.timeout(const Duration(seconds: 1)); expect(sent, hasLength(1));
      final old = buyer.cartLineFor(entry.product.id)!;
      slot = 'host-slot-B'; buyer.refreshProductFacts(entry.product.id);
      expect(await buyer.addProductForScheduledWindow(entry.product.id, buyer.scheduledWindowFor(entry.product)!, replaceLine: old), true, reason: buyer.notice);
      await Future<void>.delayed(Duration.zero);
      expect(sent, hasLength(1)); expect(buyer.quantityFor(entry.product.id), 1);
    });
  }
  for (final scale in [1.0, 2.0]) {
    testWidgets('LF04 TERMS product and Cart disclose supplied terms without applying savings at $scale', (tester) async {
      var current = true;
      final source = WorkspacePublicDiscoverySource(current: () => current, gateway: discoveryGateway(OwnerTransport((body) async =>
        SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': globalAdvertisedPage(body)}))),
        promotions: true, advertisedTerms: true));
      final core = BuySession();
      final facts = _HostOperationalFacts((p) => const BuyV2CatalogueProductFactsAdapter(includeReviewFixtures: false).snapshotFor(p));
      final buyer = BuyV2Session(core: core, reviewDataEnabled: false, catalogueNow: () => at,
        cataloguePageSource: source, publishedCatalogueSource: source, productFactsAdapter: facts);
      var closed = false;
      void close() { if (!closed) { closed = true; buyer.dispose(); core.dispose(); source.dispose(); } }
      addTearDown(close);
      final pager = buyer.acquireCatalogueOffers('terms-ui'); await pager.open(globalOffersQuery());
      final selected = pager.page!.items.first.product;
      expect(buyer.openProduct(selected.id), true);
      enableHostStockEligibility(buyer, selected, facts);
      await mountOptionalDetails(tester, buyer, scale);
      final link = find.byKey(ValueKey('buy-advertised-offer-terms-${selected.id}'));
      await revealOptionalDetails(tester, selected, link); await tester.tap(link); await tester.pumpAndSettle();
      expect(find.text('Store-advertised amount: ₹10.25 per selling pack'), findsOneWidget);
      expect(find.text('Store-advertised amount: 7.5%'), findsOneWidget);
      expect(find.text('No minimum product spend'), findsNWidgets(2));
      expect(buyer.cartLines, isEmpty);
      await tester.tap(find.text('Close')); await tester.pumpAndSettle();
      expect(buyer.addProduct(selected.id), true); buyer.openCart();
      await tester.pumpWidget(MaterialApp(theme: MoolTheme.light(), builder: (context, child) =>
        MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
        home: Scaffold(body: AnimatedBuilder(animation: buyer, builder: (context, _) => BuyV2CartView(session: buyer, onBrowseMore: () {})))));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(link, 200, scrollable: find.byType(Scrollable).first);
      await Scrollable.ensureVisible(tester.element(link), alignment: .15); await tester.pumpAndSettle();
      final before = buyer.cartLines.single.totalMinor;
      await tester.tap(link); await tester.pumpAndSettle();
      expect(find.text('Current Store offer terms'), findsOneWidget);
      expect(buyer.cartLines.single.totalMinor, before); expect(before, 10025);
      expect(find.textContaining('No discount is applied here'), findsOneWidget);
      current = false; buyer.refreshProductFacts(selected.id); await tester.pumpAndSettle();
      expect(find.textContaining('promotion changed or ended'), findsOneWidget);
      expect(find.textContaining('Store-advertised amount:'), findsNothing);
      expect(buyer.cartLines.single.totalMinor, before);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink()); close();
    });
  }
  test('LF11 Stock session positive is not eligibility and fresh negative preserves Cart without a replacement payment', () async {
    final entry = factoryEntry(publicPage()); var short = false, revision = 1;
    final reader = WorkspacePublicStockReader(gateway: publicStockApi(OwnerTransport((body) async =>
      stockPublicResponse(stockPublicQuery(body), revision: revision, quantityAvailable: !short))),
      displayed: (_) => entry.readback, current: () => true, now: () => at);
    final facts = _HostOperationalFacts((p) => const BuyV2CatalogueProductFactsAdapter(includeReviewFixtures: false).snapshotFor(p));
    final session = await benefitSession(_HostMinorBenefits(), [entry.product], facts: facts, stockReader: reader, reviewDataEnabled: false);
    expect(await session.refreshStoreStock(entry.product), true);
    expect(session.productFactsFor(entry.product).eligibility, isNull);
    expect(session.addProduct(entry.product.id), false);
    enableHostStockEligibility(session, entry.product, facts);
    expect(session.addProduct(entry.product.id), true); expect(session.setCartQuantity(entry.product.id, '8'), true);
    short = true; revision = 2; expect(await session.refreshStoreStock(entry.product), true);
    expect(session.storeStockFor(entry.product)!.query.requestedPacks, 8);
    expect(session.productFactsFor(entry.product).eligibility, isNull);
    expect(session.cartLines.single.quantity, 8); expect(session.cartLines.single.product.id, entry.product.id);
    expect(session.storeStockLabelFor(entry.product), contains('this quantity'));
    session.decrease(entry.product.id); expect(session.quantityFor(entry.product.id), 7);
    expect(session.storeStockFor(entry.product), isNull, reason: 'A check for eight packs cannot label seven.');
  });
  for (final layout in [(scale: 1.0, landscape: false), (scale: 2.0, landscape: false), (scale: 1.0, landscape: true)]) {
    final scale = layout.scale;
    testWidgets('LF11 Stock visible product and Cart request exact added typed and decreased quantities at $layout', (tester) async {
      final entry = factoryEntry(publicPage()), requests = <int>[];
      final reader = WorkspacePublicStockReader(gateway: publicStockApi(OwnerTransport((body) async {
        requests.add(body['requestedPacks'] as int); return stockPublicResponse(stockPublicQuery(body));
      })), displayed: (_) => entry.readback, current: () => true, now: () => at);
      final facts = _HostOperationalFacts((p) => const BuyV2CatalogueProductFactsAdapter(includeReviewFixtures: false).snapshotFor(p));
      final session = await benefitSession(_HostMinorBenefits(), [entry.product], facts: facts, stockReader: reader, reviewDataEnabled: false, disposeAtTearDown: false);
      enableHostStockEligibility(session, entry.product, facts);
      expect(requests, isEmpty); expect(session.openProduct(entry.product.id), true);
      await mountOptionalDetails(tester, session, scale);
      expect(requests, [1]); expect(session.storeStockLabelFor(entry.product), contains('1 pack'));
      await revealOptionalDetails(tester, entry.product, find.byKey(ValueKey('buy-automatic-fulfilment-${entry.product.id}')));
      expect(find.text('Stock'), findsOneWidget); expect(find.text('Store reports stock for 1 pack'), findsOneWidget);
      expect(session.addProduct(entry.product.id), true); session.openCart();
      await tester.pumpWidget(MaterialApp(theme: MoolTheme.light(), builder: (context, child) =>
        MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
        home: Scaffold(body: AnimatedBuilder(animation: session, builder: (context, _) => BuyV2CartView(session: session, onBrowseMore: () {})))));
      await tester.pumpAndSettle(); expect(requests, [1], reason: 'Identical fresh product/Cart query is reused.');
      if (layout.landscape) {
        tester.view.physicalSize = const Size(800, 360); await tester.pumpAndSettle();
        final list = find.byKey(PageStorageKey('buy-cart-${session.cartScope.name}'));
        await tester.drag(list, const Offset(0, -1100)); await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('buy-cart-back')).hitTestable(), findsNothing);
      }
      expect(session.setCartQuantity(entry.product.id, '8'), true); await tester.pumpAndSettle();
      expect(requests, [1, 8]);
      if (!layout.landscape) {
        expect(find.byKey(ValueKey('buy-cart-stock-${entry.product.id}')), findsOneWidget);
        expect(find.text('Store reports stock for 8 packs'), findsOneWidget);
      }
      session.decrease(entry.product.id); await tester.pumpAndSettle(); expect(requests, [1, 8, 7]);
      if (!layout.landscape) expect(find.text('Store reports stock for 7 packs'), findsOneWidget);
      expect(tester.takeException(), isNull); await tester.pumpWidget(const SizedBox.shrink()); session.dispose();
    });
  }
  testWidgets('LF11 Stock covered product cannot admit a late reply and return reads the current source', (tester) async {
    final entry = factoryEntry(publicPage()), first = Completer<SocialContentResponse>(); var calls = 0;
    final reader = WorkspacePublicStockReader(gateway: publicStockApi(OwnerTransport((body) async {
      calls++; return calls == 1 ? first.future : stockPublicResponse(stockPublicQuery(body), revision: 2);
    })), displayed: (_) => entry.readback, current: () => true, now: () => at);
    final session = await benefitSession(_HostMinorBenefits(), [entry.product], stockReader: reader, reviewDataEnabled: false, disposeAtTearDown: false);
    expect(session.openProduct(entry.product.id), true); await mountOptionalDetails(tester, session, 1);
    expect(calls, 1);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
    unawaited(navigator.push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('Host covering route')))));
    await tester.pumpAndSettle(); first.complete(stockPublicResponse(WorkspacePublicStockQuery.fromEntry(entry, 1)));
    await tester.pumpAndSettle(); expect(session.storeStockFor(entry.product), isNull); expect(calls, 1);
    navigator.pop(); await tester.pumpAndSettle(); expect(calls, 2); expect(session.storeStockFor(entry.product), isNotNull);
    expect(tester.takeException(), isNull); await tester.pumpWidget(const SizedBox.shrink()); session.dispose();
  });
  testWidgets('LF11 Stock restored saved Cart checks its retained exact quantity without re-adding', (tester) async {
    final entry = factoryEntry(publicPage()), preferences = _ExactMoneyHostPreferences(), quantities = <int>[];
    final firstFacts = _HostOperationalFacts((p) => const BuyV2CatalogueProductFactsAdapter(includeReviewFixtures: false).snapshotFor(p));
    final first = await benefitSession(_HostMinorBenefits(), [entry.product], facts: firstFacts, reviewDataEnabled: false,
      customerStateStore: BuyV2SharedPreferencesCustomerStateStore(preferences, ownerScope: 'host-restored-stock'));
    enableHostStockEligibility(first, entry.product, firstFacts); expect(first.addProduct(entry.product.id), true);
    expect(first.setCartQuantity(entry.product.id, '8'), true); await first.retainedAccountState();
    final saved = Map.of(preferences.values);
    final reader = WorkspacePublicStockReader(gateway: publicStockApi(OwnerTransport((body) async {
      quantities.add(body['requestedPacks'] as int); return stockPublicResponse(stockPublicQuery(body));
    })), displayed: (_) => entry.readback, current: () => true, now: () => at);
    final session = await benefitSession(_HostMinorBenefits(), [entry.product], stockReader: reader, reviewDataEnabled: false, disposeAtTearDown: false,
      customerStateStore: BuyV2SharedPreferencesCustomerStateStore(preferences, ownerScope: 'host-restored-stock'));
    expect(session.quantityFor(entry.product.id), 8); expect(quantities, isEmpty); expect(preferences.values, saved);
    session.openCart();
    await tester.pumpWidget(MaterialApp(theme: MoolTheme.light(), home: Scaffold(body: AnimatedBuilder(animation: session,
      builder: (context, _) => BuyV2CartView(session: session, onBrowseMore: () {})))));
    await tester.pumpAndSettle(); expect(quantities, [8]); expect(session.cartLines.single.product.id, entry.product.id);
    expect(session.quantityFor(entry.product.id), 8); expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink()); session.dispose();
  });
  test('LF11 Stock actual root owns reader and retires original A B A response', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const accountA = (environment: 'host-service', projectId: 'host-project', tenantId: null as String?, userId: 'host-a');
    const accountB = (environment: 'host-service', projectId: 'host-project', tenantId: null as String?, userId: 'host-b');
    BuyV2AccountPersistenceIdentity live = accountA;
    final core = BuySession(), held = Completer<SocialContentResponse>(), started = Completer<Map<String, Object?>>();
    final root = BuyV2RootSessions(core: core, currentIdentity: () => live, accountStoreFactory: (_, _) => _HostRetirableStateStore(),
      catalogueSourceFactory: (_, current) => WorkspacePublicDiscoverySource(current: current, gateway: publicStockApi(discovery: true, OwnerTransport((body) async {
        if (body['operation'] == 'readPublicStoreStockSnapshot') { started.complete(body); return held.future; }
        return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': discoveryData(body)}));
      }))));
    addTearDown(core.dispose); addTearDown(root.dispose); root.synchronize(accountRequired: true);
    final original = root.current, source = original.cataloguePageSource as WorkspacePublicDiscoverySource;
    final selected = (await source.loadProducts(discoveryQuery(), pageSize: 40)).items.single;
    final originalRead = original.refreshStoreStock(selected), body = await started.future;
    expect(original.storeStockReader, isNotNull);
    live = accountB; root.synchronize(accountRequired: true); live = accountA; root.synchronize(accountRequired: true);
    expect(identical(root.current.storeStockReader, original.storeStockReader), false);
    held.complete(stockPublicResponse(stockPublicQuery(body)));
    expect(await originalRead, false); expect(original.storeStockFor(selected), isNull);
    expect(root.current.storeStockFor(selected), isNull);
  });
  Future<BuyV2Session> optionalDetailsSession(BuyV2Product selected, _HostOptionalProductContent content) async {
    final core = BuySession(), catalogue = _ExactMoneyHostCatalogue()..rows.add(selected);
    final session = BuyV2Session(core: core, cataloguePageSource: catalogue, productContentAdapter: content,
      reviewDataEnabled: false, catalogueNow: () => at);
    addTearDown(core.dispose); addTearDown(session.dispose);
    final pager = session.acquireCatalogueProducts('host-optional-details');
    addTearDown(() => session.releaseCatalogueProducts('host-optional-details'));
    await pager.open(BuyV2CatalogueQuery(destination: selected.destination, regionId: null,
      areaScope: BuyV2CatalogueAreaScope.allAreas));
    expect(session.openProduct(selected.id), isTrue);
    return session;
  }
  BuyV2Product optionalDetailsProduct({bool trade = false, bool supplied = true}) {
    final data = publicPage(trade: trade)..['productFactsReadbackVersion'] = 1;
    final facts = descriptiveFacts();
    facts['compliance'] = <String, dynamic>{for (final key in (facts['compliance'] as Map).keys) key as String: null};
    facts['composition'] = supplied ? 'Host reviewed ingredients' : null;
    facts['regulatoryNote'] = supplied ? 'Host reviewed safety directions' : null;
    (row(data)['content'] as Map)['productFacts'] = facts;
    return factoryEntry(data, channel: trade ? BuyV2OfferClass.wholesale : BuyV2OfferClass.retail).product;
  }
  for (final trade in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('PF07 public supplied warranty facts remain separate from entitlement trade=$trade scale=$scale', (tester) async {
        final selected = optionalDetailsProduct(trade: trade, supplied: false), content = _HostOptionalProductContent()
          ..specifications = [for (final entry in warrantyDetails.entries) BuyV2ProductSpecification(label: entry.key, value: entry.value)];
        final session = await optionalDetailsSession(selected, content);
        await mountOptionalDetails(tester, session, scale);
        final details = find.byKey(ValueKey('buy-product-content-ready-${selected.id}'));
        await revealOptionalDetails(tester, selected, details);
        for (final entry in warrantyDetails.entries) {
          expect(find.descendant(of: details, matching: find.text(entry.key)), findsOneWidget);
          expect(find.descendant(of: details, matching: find.text(entry.value)), findsOneWidget);
        }
        expect(selected.purchaseProtection, isNull); expect(session.cartLines, isEmpty);
        content.specifications = []; session.refreshProductContent(selected.id); await tester.pumpAndSettle();
        expect(find.text('Warranty issuer'), findsNothing); expect(find.text('Warranty duration'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
  if (revisionLog != null) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('PF07 actual reviewed service warranty values reach public page at $scale', (tester) async {
        const marker = 'LF_REVISION_PROJECTION=';
        final captures = File(revisionLog).readAsLinesSync().where((line) => line.contains(marker)).toList();
        expect(captures, hasLength(1));
        final actual = jsonDecode(captures.single.split(marker).last) as Map<String, dynamic>;
        final source = WorkspacePublicDiscoverySource(current: () => true,
          gateway: discoveryGateway(OwnerTransport((body) async => SocialContentResponse(statusCode: 200,
            body: jsonEncode({'ok': true, 'data': actual}))), realm: 'evaluation'));
        final core = BuySession(), session = BuyV2Session(core: core, reviewDataEnabled: false,
          cataloguePageSource: source, productContentAdapter: source, catalogueNow: () => at);
        final pager = session.acquireCatalogueProducts('pf07-actual-service');
        try {
          await pager.open(BuyV2CatalogueQuery(destination: BuyV2Destination.shop, regionId: null,
            areaScope: BuyV2CatalogueAreaScope.allAreas, sort: BuyV2ProductSort.priceLowToHigh));
          final selected = pager.page!.items.singleWhere((p) => p.storeId == 'store-one');
          final original = pager.page!.items.singleWhere((p) => p.storeId == 'store-two');
          expect(source.snapshotFor(original).specifications, isEmpty);
          expect(session.openProduct(selected.id), isTrue);
          await mountOptionalDetails(tester, session, scale);
          final details = find.byKey(ValueKey('buy-product-content-ready-${selected.id}'));
          await revealOptionalDetails(tester, selected, details);
          for (final entry in warrantyDetails.entries) {
            expect(find.descendant(of: details, matching: find.text(entry.value)), findsOneWidget);
          }
          expect(selected.purchaseProtection, isNull); expect(selected.priceMinor, 26000);
          expect(session.cartLines, isEmpty); expect(tester.takeException(), isNull);
        } finally {
          // Widget invariants run before package:test addTearDown callbacks.
          // Release real content-expiry timers, never disable or advance them.
          await tester.pumpWidget(const SizedBox.shrink());
          session.releaseCatalogueProducts('pf07-actual-service');
          session.dispose(); core.dispose(); source.dispose();
        }
      });
    }
  }
  for (final trade in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('CONTENT-GUIDE reviewed details display supplied fields only trade=$trade scale=$scale', (tester) async {
        final base = listingItem();
        const publishedDetails = {
          'Storage': 'Host published storage instructions',
          'Contains allergens': 'Milk', 'May contain allergens': 'Peanuts',
          'Food declaration': 'Host pack declaration', 'Nutrition basis': 'Per 100 ml',
          'Serving size': '15 ml', 'Nutrition details': 'Energy 90 kcal per labelled serving',
          'After opening': 'Keep refrigerated after opening',
          'Model code': 'Host published model', 'RAM': '8 GB', 'Storage capacity': '256 GB',
          'Compatibility': 'Host published standard', 'In the box': 'Host published included items',
          'Form or material': 'Host published material', 'Intended surface': 'Host source surface',
        };
        final authored = base.copyWith(content: base.content.withGuidedDetails({
          ...publishedDetails, 'Preparation': '', 'Power rating': '', 'Age or size guidance': ''}));
        final saved = WorkspaceCatalogueItem.fromInventoryJson(authored.toInventoryJson());
        final projection = saved.toBuyPublicContent(storeId: 'store-one', sourceId: 'Host reviewed source');
        // This is a labelled accepted-source host response, not automatic publication.
        final data = publicPage(trade: trade);
        (row(data)['content'] as Map)['specifications'] = [for (final field in projection.specifications)
          {'label': field.label, 'value': field.value}];
        final entry = factoryEntry(data, channel: trade ? BuyV2OfferClass.wholesale : BuyV2OfferClass.retail);
        final content = _HostOptionalProductContent()..specifications = entry.readback.content.specifications;
        final session = await optionalDetailsSession(entry.product, content);
        final privateEdit = saved.copyWith(content: saved.content.withGuidedDetails({
          'Storage': 'Host private unpublished edit', 'Contains allergens': 'Host private allergen edit',
          'Model code': 'Host private model edit'}));
        expect(privateEdit.content.specifications['Storage'], 'Host private unpublished edit');
        await mountOptionalDetails(tester, session, scale);
        final details = find.byKey(ValueKey('buy-product-content-ready-${entry.product.id}'));
        await revealOptionalDetails(tester, entry.product, details);
        for (final field in publishedDetails.entries) {
          expect(find.text(field.key), findsOneWidget);
          expect(find.text(field.value), findsOneWidget);
        }
        expect(find.text('Host private unpublished edit'), findsNothing);
        expect(find.text('Host private allergen edit'), findsNothing);
        expect(find.text('Host private model edit'), findsNothing);
        expect(find.text('Preparation'), findsNothing);
        expect(find.text('Power rating'), findsNothing);
        expect(find.text('Age or size guidance'), findsNothing);
        expect(session.cartLines, isEmpty); expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
      testWidgets('LF03 READINESS public product labels do not promise unsourced delivery trade=$trade scale=$scale', (tester) async {
        final semantics = tester.ensureSemantics();
        try {
        final selected = factoryEntry(publicPage(trade: trade),
          channel: trade ? BuyV2OfferClass.wholesale : BuyV2OfferClass.retail).product;
        final session = await readinessSession(selected);
        expect(session.openProduct(selected.id), isTrue);
        await mountOptionalDetails(tester, session, scale);
        expect(find.bySemanticsLabel(RegExp('Add minimum order of.*MoolSocial Courier Delivery')), findsNothing);
        final delivery = find.byKey(ValueKey('buy-automatic-fulfilment-${selected.id}'));
        await revealOptionalDetails(tester, selected, delivery);
        expect(find.text('Open for orders'), findsNothing); expect(find.textContaining('tomorrow at 8'), findsNothing);
        expect(find.descendant(of: delivery, matching: find.text('Check delivery availability')), findsOneWidget);
        expect(find.descendant(of: delivery, matching: find.text('Method')), findsNothing);
        expect(session.cartLines, isEmpty); expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        } finally {
          semantics.dispose();
        }
      });
    }
  }
  for (final trade in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('LF03 OPTIONAL reviewed composition safety and changing tabs trade=$trade scale=$scale', (tester) async {
        final selected = optionalDetailsProduct(trade: trade), content = _HostOptionalProductContent();
        final session = await optionalDetailsSession(selected, content);
        await mountOptionalDetails(tester, session, scale);
        final details = find.byKey(ValueKey('buy-product-content-ready-${selected.id}'));
        await revealOptionalDetails(tester, selected, details);
        expect(find.descendant(of: details, matching: find.text('Composition or ingredients')), findsOneWidget);
        expect(find.descendant(of: details, matching: find.text('Host reviewed ingredients')), findsOneWidget);
        expect(find.descendant(of: details, matching: find.text('Safety information')), findsOneWidget);
        expect(find.descendant(of: details, matching: find.text('Host reviewed safety directions')), findsOneWidget);
        expect(find.byKey(ValueKey('buy-product-details-tab-1-${selected.id}')), findsNothing);
        expect(find.byKey(ValueKey('buy-product-details-tab-2-${selected.id}')), findsNothing);
        content.description = 'Host published additional description';
        session.refreshProductContent(selected.id); await tester.pumpAndSettle();
        final description = find.byKey(ValueKey('buy-product-details-tab-1-${selected.id}'));
        await revealOptionalDetails(tester, selected, description); await tester.tap(description); await tester.pumpAndSettle();
        expect(find.text(content.description!), findsOneWidget);
        content.description = null;
        session.refreshProductContent(selected.id); await tester.pumpAndSettle();
        expect(description, findsNothing);
        expect(find.descendant(of: details, matching: find.text('Host reviewed ingredients')), findsOneWidget,
          reason: 'retained missing Description tab must fall back to an actually supplied section');
        expect(find.text('Description unavailable.'), findsNothing);
        expect(find.text('Manufacturer information unavailable.'), findsNothing);
        expect(session.selectedProduct!.publicListingIdentity, selected.publicListingIdentity);
        expect(session.selectedProduct!.priceMinor, selected.priceMinor);
        expect(session.cartLines, isEmpty); expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
  testWidgets('LF03 OPTIONAL ready empty is omitted but loading and failure remain truthful', (tester) async {
    final selected = optionalDetailsProduct(supplied: false), content = _HostOptionalProductContent();
    final session = await optionalDetailsSession(selected, content);
    await mountOptionalDetails(tester, session, 1);
    final details = find.byKey(ValueKey('buy-product-content-ready-${selected.id}'));
    await revealOptionalDetails(tester, selected, details);
    expect(tester.widget(details), isA<SizedBox>());
    expect(find.text('Product details unavailable'), findsNothing); expect(find.text('All details'), findsNothing);
    content.state = BuyV2ProductContentState.loading;
    session.refreshProductContent(selected.id); await tester.pumpAndSettle();
    expect(find.text('Loading product details'), findsOneWidget);
    content.state = BuyV2ProductContentState.offline;
    session.refreshProductContent(selected.id); await tester.pumpAndSettle();
    expect(find.text('Product details unavailable'), findsOneWidget);
    expect(find.byKey(ValueKey('buy-product-content-retry-${selected.id}')), findsOneWidget);
    content.state = BuyV2ProductContentState.ready;
    session.refreshProductContent(selected.id); await tester.pumpAndSettle();
    expect(tester.widget(details), isA<SizedBox>()); expect(session.cartLines, isEmpty);
    expect(tester.takeException(), isNull); await tester.pumpWidget(const SizedBox.shrink());
  });
  for (final mode in ['replacement', 'unknown', 'private', 'highlight']) {
    testWidgets('LF03 OPTIONAL typed ownership prevents duplicated or revived details $mode', (tester) async {
      final selected = optionalDetailsProduct(), content = _HostOptionalProductContent();
      if (mode == 'highlight') {
        content.highlights = const [BuyV2ProductSpecification(attributeId: 'composition', label: 'Current ingredients',
          value: 'Current published ingredients'), BuyV2ProductSpecification(attributeId: 'regulatory_note',
          label: 'Current safety', value: 'Current published safety')];
      } else {
        content.categoryFacts = BuyV2CategoryFacts(categoryId: selected.categoryId, fields: [
          for (final id in ['composition', 'regulatory_note']) BuyV2CategoryAttribute(id: id, label: 'Current $id',
            type: mode == 'unknown' ? BuyV2AttributeType.unknown : BuyV2AttributeType.text,
            value: mode == 'replacement' ? 'Current published $id' : 'Suppressed $id', isPublic: mode != 'private'),
        ]);
      }
      final session = await optionalDetailsSession(selected, content);
      await mountOptionalDetails(tester, session, 1);
      final details = find.byKey(ValueKey('buy-product-content-ready-${selected.id}'));
      await revealOptionalDetails(tester, selected, details);
      expect(find.textContaining('Host reviewed ingredients'), findsNothing);
      expect(find.textContaining('Host reviewed safety directions'), findsNothing);
      expect(find.textContaining('Suppressed '), findsNothing);
      if (mode == 'replacement' || mode == 'highlight') {
        expect(find.textContaining('Current published'), findsNWidgets(2));
      } else {
        expect(find.text('All details'), findsNothing);
        expect(find.text('Product details unavailable'), findsNothing);
      }
      expect(tester.takeException(), isNull); await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets('LF03 OPTIONAL malformed blank legal field cannot create empty Manufacturer tab', (tester) async {
    final selected = optionalDetailsProduct(supplied: false), content = _HostOptionalProductContent()
      ..specifications = const [BuyV2ProductSpecification(attributeId: 'manufacturer_name',
        label: 'Manufacturer', value: '   ')];
    final session = await optionalDetailsSession(selected, content);
    await mountOptionalDetails(tester, session, 1);
    expect(session.productContentFor(selected).state, BuyV2ProductContentState.unavailable,
      reason: 'malformed source data is not a valid ready-empty response');
    final details = find.byKey(ValueKey('buy-product-content-unavailable-${selected.id}'));
    await revealOptionalDetails(tester, selected, details);
    expect(find.text('All details'), findsNothing);
    expect(find.text('Manufacturer info'), findsNothing);
    expect(find.text('Product details unavailable'), findsOneWidget);
    expect(tester.takeException(), isNull); await tester.pumpWidget(const SizedBox.shrink());
  });
  Future<({BuyV2Session session, _ExactMoneyHostPreferences preferences})> placementFixture(
    _HostPlacement adapter, {bool grouped = false, int price = 1025, int quantity = 1, int fee = 0,
    int? mrp, bool withTerms = false, void Function(String key, String value)? beforeSet,
    Future<void> Function(String key, String value)? beforeWrite,
    WorkspacePublicCatalogueEntry? stockEntry, WorkspacePublicStockReader? stockReader}) async {
    final quote = _HostMinorQuote()..reply = ((groups, tips) async {
      final value = _hostExactQuote(groups, tips, fee: fee).quote!;
      return BuyV2CheckoutQuoteSnapshot(state: BuyV2CommerceLoadState.ready, quote: BuyV2CheckoutQuote.minor(
        id: value.id, sourceId: value.sourceId, evaluatedAt: value.evaluatedAt, validUntil: value.validUntil,
        lines: value.lines, totalMinor: value.totalMinor,
        paymentGroups: !grouped ? null : [BuyV2CheckoutPaymentGroup.minor(id: 'host-payment-group',
          fulfilmentKeys: groups.map((group) => group.key).toSet(), paymentMethod: 'UPI',
          totalMinor: value.totalMinor, amountDueNowMinor: value.totalMinor)]));
    });
    final preferences = _ExactMoneyHostPreferences(beforeSet: beforeSet, beforeWrite: beforeWrite);
    final store = BuyV2SharedPreferencesCustomerStateStore(preferences, ownerScope: 'host-placement');
    final value = (stockEntry?.product ?? product).copyWith(priceMinor: price, mrpMinor: mrp ?? 28000, deliveryPromise: 'Host-only fulfilment');
    final facts = stockEntry == null ? null : _HostOperationalFacts((p) => const BuyV2CatalogueProductFactsAdapter(includeReviewFixtures: false).snapshotFor(p));
    final session = await benefitSession(_HostMinorBenefits(), [value], quoteAdapter: quote,
      customerStateStore: store, commerceAdapter: adapter, stockReader: stockReader, facts: facts, termsAdapter: !withTerms ? null :
        (_HostMinorTerms()..reply = ((groups, totals) async => _hostExactRetailTerms(groups, totals))));
    if (facts != null) { enableHostStockEligibility(session, value, facts); }
    expect(session.addProduct(value.id), isTrue); expect(session.setCartQuantity(value.id, '$quantity'), isTrue);
    session.addAddress(frozenAddress); session.openCart(); expect(session.openCheckout(), isTrue);
    expect(await session.refreshCheckoutQuote(), isTrue);
    return (session: session, preferences: preferences);
  }
  for (final grouped in [false, true]) {
    test('LF11 Stock fresh shortage during frozen save prevents new dispatch grouped=$grouped', () async {
      final entry = factoryEntry(publicPage()), adapter = _HostMinorGroupedPlacement(); var shortage = false, intercepted = false;
      late BuyV2Session session;
      final reader = WorkspacePublicStockReader(gateway: publicStockApi(OwnerTransport((body) async =>
        stockPublicResponse(stockPublicQuery(body), quantityAvailable: !shortage))), displayed: (_) => entry.readback, current: () => true, now: () => at);
      final fixture = await placementFixture(adapter, grouped: grouped, price: entry.product.priceMinor,
        stockEntry: entry, stockReader: reader, beforeWrite: (_, value) async {
          final state = jsonDecode(value) as Map;
          if (!intercepted && (state['legacyCheckoutAttempt'] != null || state['checkoutPaymentAttempt'] != null)) {
            intercepted = true; shortage = true; expect(await session.refreshStoreStock(entry.product), true);
          }
        });
      session = fixture.session;
      expect(await session.submitOrder(), false); expect(intercepted, true);
      expect(adapter.minorSingle, isEmpty); expect(adapter.minorGroups, isEmpty);
      expect(session.notice, contains('Stock changed')); expect(session.cartLines.single.quantity, 1);
      expect(session.storeStockFor(entry.product)!.quantityAvailable, false);
    });
    test('LF11 Stock reports never replace or forget a submitted original payment grouped=$grouped', () async {
      final entry = factoryEntry(publicPage()), adapter = _HostMinorGroupedPlacement(); var shortage = false;
      final reader = WorkspacePublicStockReader(gateway: publicStockApi(OwnerTransport((body) async =>
        stockPublicResponse(stockPublicQuery(body), quantityAvailable: !shortage))), displayed: (_) => entry.readback, current: () => true, now: () => at);
      final fixture = await placementFixture(adapter, grouped: grouped, price: entry.product.priceMinor, stockEntry: entry, stockReader: reader), session = fixture.session;
      expect(await session.submitOrder(), false); final originals = grouped ? adapter.minorGroups : adapter.minorSingle;
      expect(originals, hasLength(1)); final bytes = Map.of(fixture.preferences.values), before = session.cartLines.single;
      shortage = true; expect(await session.refreshStoreStock(entry.product), true);
      expect(session.cartChangesBlocked, true); expect(originals, hasLength(1));
      final after = session.cartLines.single;
      expect(after.product, same(before.product)); expect(after.quantity, before.quantity);
      expect(after.product.priceMinor, before.product.priceMinor); expect(fixture.preferences.values, bytes);
      final original = originals.single;
      adapter.reconciliation = BuyV2OrderPlacementResult(outcome: BuyV2OrderPlacementOutcome.paymentUnknown,
        customerMessage: 'Host original remains unconfirmed', paymentReference: 'host-placement-reference',
        checkoutAttemptId: original.checkoutAttemptId, paymentGroupId: original.paymentGroupId, idempotencyKey: original.idempotencyKey);
      expect(await session.reconcilePayment(), false);
      expect(adapter.reconciled, [(key: original.idempotencyKey, reference: 'host-placement-reference')]);
      expect(originals, hasLength(1)); expect(session.cartChangesBlocked, true);
    });
  }
  for (final grouped in [false, true]) {
    test('LF-PAISE new exact placement grouped=$grouped saves original paise before explicit dispatch', () async {
      final adapter = _HostMinorGroupedPlacement();
      final fixture = await placementFixture(adapter, grouped: grouped, fee: 1), session = fixture.session;
      adapter.onDispatch = (request) {
        final store = BuyV2SharedPreferencesCustomerStateStore(fixture.preferences, ownerScope: 'host-placement');
        expect(fixture.preferences.values.values.single, contains(request.idempotencyKey));
        expect(store.ownerScope, 'host-placement');
      };
      expect(await session.submitOrder(), isFalse);
      final requests = grouped ? adapter.minorGroups : adapter.minorSingle;
      expect(requests, hasLength(1), reason: session.notice);
      final request = requests.single;
      expect(request.usesMinorAmounts, isTrue); expect(request.totalMinor, 1026); expect(request.amountDueNowMinor, 1026);
      expect(request.lines.single.product.priceMinor, 1025);
      expect(adapter.legacySingle, isEmpty); expect(adapter.legacyGroups, isEmpty);
      final saved = await BuyV2SharedPreferencesCustomerStateStore(fixture.preferences, ownerScope: 'host-placement').read();
      final payment = grouped ? saved!.checkoutPaymentAttempt!.groups.single : saved!.legacyCheckoutAttempt!.payment;
      expect(payment.request.idempotencyKey, request.idempotencyKey);
      expect(payment.request.usesMinorAmounts, isTrue); expect(payment.obligations.single.totalMinor, 1026);
      expect(payment.obligations.single.dueNowMinor, 1026);
      expect(await session.submitOrder(), isFalse); expect(requests, hasLength(1));
    });
  }
  for (final grouped in [false, true]) {
    for (final kind in ['whole', 'fractional unit with whole total', 'fractional MRP', 'fractional fee']) {
      test('LF-PAISE legacy placement grouped=$grouped preserves units or blocks $kind', () async {
        final adapter = _HostPlacement();
        final fixture = await placementFixture(adapter, grouped: grouped,
          price: kind == 'fractional unit with whole total' ? 1025 : 1000,
          quantity: kind == 'fractional unit with whole total' ? 4 : 1,
          mrp: kind == 'fractional MRP' ? 1251 : 28000, fee: kind == 'fractional fee' ? 1 : 0);
        expect(await fixture.session.submitOrder(), isFalse);
        final calls = grouped ? adapter.legacyGroups : adapter.legacySingle;
        expect(calls.length, kind == 'whole' ? 1 : 0, reason: fixture.session.notice);
        if (kind == 'whole') {
          expect(calls.single.usesMinorAmounts, isFalse);
          expect(calls.single.total, 10); expect(calls.single.amountDueNow, 10);
        } else {
          expect(fixture.session.checkoutPaymentAttempt, isNull);
          expect(fixture.session.legacyCheckoutAttempt, isNull);
          expect(fixture.session.quantityFor(product.id), kind == 'fractional unit with whole total' ? 4 : 1);
        }
        expect(adapter.minorGroups, isEmpty); expect(adapter.minorSingle, isEmpty);
      });
    }
    test('LF-PAISE minor placement grouped=$grouped saves whole amounts explicitly in paise', () async {
      final adapter = _HostMinorGroupedPlacement();
      final fixture = await placementFixture(adapter, grouped: grouped, price: 1000);
      expect(await fixture.session.submitOrder(), isFalse);
      final request = (grouped ? adapter.minorGroups : adapter.minorSingle).single;
      expect(request.usesMinorAmounts, isTrue); expect(request.totalMinor, 1000); expect(request.amountDueNowMinor, 1000);
      expect(adapter.legacySingle, isEmpty); expect(adapter.legacyGroups, isEmpty);
    });
    test('LF-PAISE minor placement grouped=$grouped never dispatches on failed durable save', () async {
      final adapter = _HostMinorGroupedPlacement();
      var failWrite = false;
      final fixture = await placementFixture(adapter, grouped: grouped, beforeSet: (_, text) {
        if (failWrite) throw StateError('Host placement write failed');
      });
      failWrite = true;
      expect(await fixture.session.submitOrder(), isFalse);
      expect(adapter.minorSingle, isEmpty); expect(adapter.minorGroups, isEmpty);
      expect(adapter.legacySingle, isEmpty); expect(adapter.legacyGroups, isEmpty);
      expect(fixture.session.quantityFor(product.id), 1);
    });
    test('LF-PAISE frozen exact placement grouped=$grouped survives restart without downgrading capability', () async {
      final adapter = _HostMinorGroupedPlacement();
      final fixture = await placementFixture(adapter, grouped: grouped, fee: 1);
      expect(await fixture.session.submitOrder(), isFalse);
      final request = (grouped ? adapter.minorGroups : adapter.minorSingle).single;
      final legacy = _HostPlacement()..reconciliation = BuyV2OrderPlacementResult(
        outcome: BuyV2OrderPlacementOutcome.paymentUnknown, customerMessage: 'Host original held',
        paymentReference: 'host-placement-reference', idempotencyKey: request.idempotencyKey,
        checkoutAttemptId: request.checkoutAttemptId, paymentGroupId: request.paymentGroupId);
      final recovered = await benefitSession(_HostMinorBenefits(), [request.lines.single.product], commerceAdapter: legacy,
        customerStateStore: BuyV2SharedPreferencesCustomerStateStore(fixture.preferences, ownerScope: 'host-placement'));
      final original = grouped ? recovered.currentCheckoutPaymentGroup!.request : recovered.legacyCheckoutAttempt!.payment.request;
      expect(original.usesMinorAmounts, isTrue); expect(original.totalMinor, 1026);
      expect(original.idempotencyKey, request.idempotencyKey);
      expect(await recovered.submitOrder(), isFalse);
      expect(await recovered.reconcilePayment(), isFalse);
      expect(legacy.reconciliationCalls, 1); expect(legacy.legacySingle, isEmpty); expect(legacy.legacyGroups, isEmpty);
      expect(recovered.checkoutRequiresResolution, isTrue); expect(recovered.quantityFor(product.id), 1);
    });
    for (final difference in [-1, 0, 1]) {
      test('LF-PAISE exact placement QR grouped=$grouped rejects paise difference=$difference', () async {
        final adapter = _HostMinorGroupedPlacement();
        final fixture = await placementFixture(adapter, grouped: grouped, fee: 1);
        fixture.session.upiQrAvailable = true;
        expect(fixture.session.chooseUpiQr(true), isTrue);
        final action = BuyV2UpiQrAction(uri: Uri.parse('upi://pay?pa=host@invalid&pn=Host&cu=INR&tr=host-qr&am=${((1026 + difference) / 100).toStringAsFixed(2)}'),
          paymentReference: 'host-placement-reference', transactionReference: 'host-qr', expiresAt: at.add(const Duration(hours: 1)));
        adapter.reply = (request) => BuyV2OrderPlacementResult(outcome: BuyV2OrderPlacementOutcome.paymentPending,
          customerMessage: 'Host original QR', paymentReference: 'host-placement-reference', upiQrAction: action,
          idempotencyKey: request.idempotencyKey, checkoutAttemptId: request.checkoutAttemptId, paymentGroupId: request.paymentGroupId);
        expect(await fixture.session.submitOrder(), isFalse);
        expect(fixture.session.upiQrAction, difference == 0 ? same(action) : isNull);
        expect((grouped ? adapter.minorGroups : adapter.minorSingle), hasLength(1));
        expect(fixture.session.quantityFor(product.id), 1);
        expect(fixture.session.checkoutRequiresResolution, isTrue);
      });
    }
    for (final scale in [1.0, 2.0]) {
      testWidgets('LF-PAISE frozen Checkout exact totals grouped=$grouped scale=$scale', (tester) async {
        tester.view.physicalSize = const Size(320, 568); tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
        final fixture = await placementFixture(_HostMinorGroupedPlacement(), grouped: grouped, fee: 1);
        final session = fixture.session;
        expect(await session.submitOrder(), isFalse);
        expect(session.checkoutRequiresResolution, isTrue);
        session.checkoutStep = BuyV2CheckoutStep.payment;
        final gst = BuyV2GstInvoiceController(); addTearDown(gst.dispose);
        await tester.pumpWidget(MaterialApp(theme: MoolTheme.light(), builder: (context, child) =>
          MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
          home: Scaffold(body: BuyV2CheckoutView(session: session, gstInvoiceController: gst))));
        await tester.pumpAndSettle(); expect(tester.takeException(), isNull);
        expect(find.text(grouped ? 'Agreed total' : 'Original total'), findsOneWidget);
        expect(find.textContaining('₹10.26'), findsWidgets);
        await tester.pumpWidget(const SizedBox.shrink());
      });
      for (final step in BuyV2CheckoutStep.values) {
        testWidgets('LF-PAISE Checkout exact labels grouped=$grouped scale=$scale step=${step.name}', (tester) async {
          final faults = <FlutterErrorDetails>[];
          final onError = FlutterError.onError;
          FlutterError.onError = (details) { faults.add(details); onError?.call(details); };
          addTearDown(() { FlutterError.onError = onError; });
          tester.view.physicalSize = const Size(320, 568); tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
          final fixture = await placementFixture(_HostMinorGroupedPlacement(), grouped: grouped, fee: 1, withTerms: true);
          final session = fixture.session;
          expect(await session.refreshCommercialPaymentTerms(), isTrue);
          session.checkoutStep = step;
          final gst = BuyV2GstInvoiceController(); addTearDown(gst.dispose);
          await tester.pumpWidget(MaterialApp(theme: MoolTheme.light(), builder: (context, child) =>
            MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
            home: Scaffold(body: BuyV2CheckoutView(session: session, gstInvoiceController: gst))));
          await tester.pumpAndSettle(); expect(tester.takeException(), isNull,
            reason: faults.map((detail) => '${detail.exception}\n${detail.stack}').join('\n'));
          expect(find.textContaining('₹10.26'), findsWidgets);
          await tester.pumpWidget(const SizedBox.shrink());
        });
      }
    }
  }
  for (final destination in [BuyV2Destination.shop, BuyV2Destination.wholesale]) {
    for (final surface in ['catalogue', 'product', 'cart', 'purchased items']) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('LF-PAISE shared $surface ${destination.name} exact money scale=$scale', (tester) async {
          tester.view.physicalSize = const Size(320, 568); tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
          final faults = <FlutterErrorDetails>[];
          final onError = FlutterError.onError;
          FlutterError.onError = (detail) { faults.add(detail); onError?.call(detail); };
          addTearDown(() { FlutterError.onError = onError; });
          final value = BuyV2Product(id: product.id, canonicalId: product.canonicalId, storeId: product.storeId,
            destination: destination, categoryId: product.categoryId, brand: product.brand, title: product.title,
            variant: product.variant, pack: product.pack, priceMinor: 1025, mrpMinor: 1250,
            unitPrice: '', badge: '', seller: product.seller, sellerType: product.sellerType,
            origin: '', confirmedOn: '', visualLabel: product.visualLabel, visualKind: product.visualKind,
            offerClass: destination == BuyV2Destination.shop ? BuyV2OfferClass.retail : BuyV2OfferClass.wholesale,
            deliveryPromise: 'Host-only fulfilment');
          final commerce = _HostExactOrderCommerce()..records = [BuyV2Order.minor(
            id: 'host-render-order', purchaseId: 'host-render-purchase', destination: destination,
            title: 'Host saved order', itemSummary: 'One product', totalMinor: 2050,
            partner: 'Host Store', partnerType: 'Retailer', promise: 'Host delivery', destinationLabel: 'Host address',
            progress: 0, status: BuyV2OrderStatus.preparing, productIds: [value.id],
            lines: [BuyV2CartLine(product: value, quantity: 2)], amountPaidNowMinor: 0, balanceDueMinor: 2050)];
          final session = await benefitSession(_HostMinorBenefits(), [value], commerceAdapter: commerce,
            reviewDataEnabled: surface != 'purchased items');
          session.openDestination(destination);
          if (surface == 'product') expect(session.openProduct(value.id), isTrue);
          if (surface == 'cart') {
            expect(session.addProduct(value.id), isTrue); expect(session.setCartQuantity(value.id, '2'), isTrue);
            session.openCart();
          }
          if (surface == 'purchased items') {
            await session.restoreCommerce(); expect(session.openOrderItems('host-render-order'), isTrue);
          }
          final Widget child = switch (surface) {
            'catalogue' => BuyV2CatalogueView(session: session),
            'product' => BuyV2ProductView(session: session),
            'cart' => BuyV2CartView(session: session, onBrowseMore: () {}),
            _ => BuyV2OrderItemsView(session: session),
          };
          await tester.pumpWidget(MaterialApp(theme: MoolTheme.light(), builder: (context, child) =>
            MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
            home: Scaffold(body: child)));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
            reason: faults.map((detail) => '${detail.exception}\n${detail.stack.toString().split('\n').take(8).join('\n')}').join('\n'));
          expect(find.textContaining(surface == 'cart' || surface == 'purchased items' ? '₹20.50' : '₹10.25'), findsWidgets);
          if (surface == 'product') {
            final details = find.byKey(ValueKey('buy-product-price-details-${value.id}'));
            await tester.scrollUntilVisible(details, 250, scrollable: find.byType(Scrollable).first);
            await Scrollable.ensureVisible(tester.element(details), alignment: .5);
            await tester.pumpAndSettle(); expect(details.hitTestable(), findsOneWidget);
            await tester.tap(details); await tester.pumpAndSettle();
            expect(find.byKey(ValueKey('buy-product-price-details-inline-${value.id}')), findsOneWidget);
            expect(find.text('₹12.50'), findsWidgets); expect(find.text('₹2.25'), findsOneWidget);
            expect(tester.takeException(), isNull);
          }
          await tester.pumpWidget(const SizedBox.shrink());
        });
      }
    }
  }
  testWidgets('LF-PAISE tier Cart displays exact per-pack and next-quantity totals', (tester) async {
    tester.view.physicalSize = const Size(320, 800); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    final value = product.copyWith(id: 'host-ui-tier', priceMinor: 1025, mrpMinor: 1250,
      deliveryPromise: 'Host-only fulfilment', packTerms: BuyV2PackTerms(skuId: 'host-ui-tier',
        revision: 'host-ui-tier-revision', sellUnit: 'piece', pricingStoreId: 'store-one', priceObservedAt: at,
        priceValidUntil: at.add(const Duration(hours: 1)), priceTiers: const [
          BuyV2PackPriceTier(minimumPacks: 1, priceMinor: 1025), BuyV2PackPriceTier(minimumPacks: 3, priceMinor: 1001)]));
    final session = await benefitSession(_HostMinorBenefits(), [value]);
    expect(session.addProduct(value.id, quantity: 2), isTrue); session.openCart();
    await tester.pumpWidget(MaterialApp(theme: MoolTheme.light(),
      home: Scaffold(body: AnimatedBuilder(animation: session, builder: (context, _) =>
        BuyV2CartView(session: session, onBrowseMore: () {})))));
    await tester.pumpAndSettle(); expect(tester.takeException(), isNull);
    final tier = find.byKey(ValueKey('buy-cart-quantity-tier-${value.id}'));
    await tester.scrollUntilVisible(tier, 250, scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('₹10.01/pack'), findsOneWidget);
    expect(find.textContaining('Item total ₹30.03'), findsOneWidget);
    await tester.tap(tier); await tester.pumpAndSettle();
    expect(session.quantityFor(value.id), 3); expect(session.cartLines.single.totalMinor, 3003);
    expect(find.text('₹30.03'), findsWidgets); expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  test('LF-PAISE single minor placement capability does not grant grouped fractional dispatch', () async {
    final adapter = _HostMinorPlacement();
    final fixture = await placementFixture(adapter, grouped: true);
    expect(await fixture.session.submitOrder(), isFalse);
    expect(adapter.minorSingle, isEmpty); expect(adapter.legacyGroups, isEmpty);
    expect(fixture.session.checkoutPaymentAttempt, isNull);
  });
  test('LF-PAISE exact quote and retail terms consume canonical paise without legacy dispatch', () async {
    final quote = _HostMinorQuote()..reply = ((groups, tips) async => _hostExactQuote(groups, tips, coupon: 25, fee: 1));
    final terms = _HostMinorTerms()..reply = ((groups, totals) async => _hostExactRetailTerms(groups, totals));
    final benefits = _HostMinorBenefits()..offers.add(hostBenefit(minimum: 1));
    final base = product.copyWith(priceMinor: 2001, deliveryPromise: 'Host-only fulfilment');
    final session = await benefitSession(benefits, [base], quoteAdapter: quote, termsAdapter: terms);
    expect(session.addProduct(base.id), isTrue); expect(session.chooseCartBenefit(benefits.offers.single), isTrue);
    session.addAddress(frozenAddress); session.openCart();
    expect(await session.refreshCheckoutQuote(), isTrue);
    expect(await session.refreshCommercialPaymentTerms(), isTrue);
    expect(session.checkoutPayableTotalMinor, 1977); expect(session.checkoutAmountDueNowMinor, 1977);
    expect(session.checkoutQuotedDeliveryFeeMinor, 1); expect(session.checkoutBalanceDueMinor, 0);
    expect(session.checkoutQuoteReviewRequired, isFalse); expect(session.checkoutPaymentTermsReviewRequired, isFalse);
    expect(quote.minorCalls, greaterThan(0)); expect(quote.legacyCalls, 0); expect(quote.minorTips!.values.single, 0);
    expect(terms.minorTotals!.values.single, 1977); expect(terms.legacyCalls, 0);
  });
  for (final component in ['unit price', 'MRP', 'future tier', 'benefit']) {
    test('LF-PAISE legacy quote receives no fractional $component payload even with a whole basket total', () async {
      final quote = _HostLegacyQuote();
      final benefits = _HostMinorBenefits();
      var base = product.copyWith(priceMinor: 2000, mrpMinor: component == 'MRP' ? 2001 : 28000,
        deliveryPromise: 'Host-only fulfilment');
      if (component == 'unit price') { base = base.copyWith(priceMinor: 1050, minimumOrder: 2); }
      if (component == 'future tier') { base = base.copyWith(packTerms: BuyV2PackTerms(skuId: base.id, revision: 'host-tiers',
        sellUnit: 'piece', pricingStoreId: base.storeId, priceObservedAt: at, priceValidUntil: at.add(const Duration(hours: 1)),
        priceTiers: const [BuyV2PackPriceTier(minimumPacks: 1, priceMinor: 2000), BuyV2PackPriceTier(minimumPacks: 2, priceMinor: 1001)])); }
      if (component == 'benefit') benefits.offers.add(hostBenefit(minimum: 1));
      final session = await benefitSession(benefits, [base], quoteAdapter: quote);
      expect(session.addProduct(base.id), isTrue, reason: session.notice);
      // Adding an ordinary whole-price item legitimately requests a quote before
      // its fractional coupon is selected. Only subsequent dispatch is forbidden.
      final permittedWholeCalls = quote.legacyCalls;
      if (component != 'benefit') expect(permittedWholeCalls, 0);
      if (component == 'benefit') expect(session.chooseCartBenefit(benefits.offers.single), isTrue);
      session.addAddress(frozenAddress); session.openCart();
      expect(session.checkoutTotalMinor % 100, 0);
      expect(await session.refreshCheckoutQuote(), isFalse);
      expect(quote.legacyCalls, permittedWholeCalls); expect(session.checkoutQuoteLoadState, BuyV2CommerceLoadState.unavailable);
      expect(session.checkoutQuote, isNull);
    });
  }
  test('LF-PAISE legacy terms receive no fractional quoted fee while Cart prices are whole', () async {
    final quote = _HostMinorQuote()..reply = ((groups, tips) async => _hostExactQuote(groups, tips, fee: 1));
    final terms = _HostLegacyTerms();
    final session = await benefitSession(const BuyV2DisabledCartBenefitsAdapter(),
      [product.copyWith(priceMinor: 2000, deliveryPromise: 'Host-only fulfilment')], quoteAdapter: quote, termsAdapter: terms);
    expect(session.addProduct(product.id), isTrue); session.addAddress(frozenAddress); session.openCart();
    expect(await session.refreshCheckoutQuote(), isTrue);
    expect(await session.refreshCommercialPaymentTerms(), isFalse);
    expect(terms.legacyCalls, 0); expect(session.commercialPaymentTermsLoadState, BuyV2CommerceLoadState.unavailable);
  });
  test('LF-PAISE legacy quote and term maps retain rupees while exact provider tip maps use paise', () async {
    for (final exact in [false, true]) {
      final quote = exact ? _HostMinorQuote() : _HostLegacyQuote();
      quote.reply = (groups, tips) async => _hostExactQuote(groups,
        exact ? tips : tips.map((key, value) => MapEntry(key, value * 100)));
      final terms = exact ? _HostMinorTerms() : _HostLegacyTerms();
      terms.reply = (groups, totals) async => _hostExactRetailTerms(groups,
        exact ? totals : totals.map((key, value) => MapEntry(key, value * 100)));
      final session = await benefitSession(const BuyV2DisabledCartBenefitsAdapter(),
        [product.copyWith(priceMinor: 2000, deliveryPromise: 'Host-only fulfilment')],
        quoteAdapter: quote, termsAdapter: terms, tipPolicy: _HostTipPolicy());
      expect(session.addProduct(product.id), isTrue); session.addAddress(frozenAddress); session.openCart();
      final group = session.checkoutFulfilmentGroups.single;
      expect(session.chooseTip(fulfilmentKey: group.key, destination: group.destination, amount: 10), isTrue);
      expect(await session.refreshCheckoutQuote(), isTrue);
      expect(await session.refreshCommercialPaymentTerms(), isTrue);
      expect(exact ? (quote as _HostMinorQuote).minorTips!.values.single : quote.legacyTips!.values.single, exact ? 1000 : 10);
      expect(exact ? (terms as _HostMinorTerms).minorTotals!.values.single : terms.legacyTotals!.values.single, exact ? 3000 : 30);
      expect(session.checkoutPayableTotalMinor, 3000); expect(session.checkoutAmountDueNowMinor, 3000);
    }
  });
  for (final mismatch in ['subtotal', 'coupon', 'tip', 'total', 'quote total', 'foreign group', 'negative tax']) {
    test('LF-PAISE exact quote rejects $mismatch without retaining a usable total', () async {
      final quote = _HostMinorQuote()..reply = ((groups, tips) async {
        final good = _hostExactQuote(groups, tips).quote!, original = _hostExactQuote(groups, tips).quote!.lines.single;
        final subtotal = original.itemSubtotalMinor + (mismatch == 'subtotal' ? 1 : 0);
        final coupon = mismatch == 'coupon' ? 1 : 0, tip = mismatch == 'tip' ? 1 : 0;
        final total = subtotal - coupon + tip + (mismatch == 'total' ? 1 : 0);
        final line = BuyV2CheckoutQuoteLine.minor(fulfilmentKey: mismatch == 'foreign group' ? 'host-foreign' : original.fulfilmentKey,
          itemSubtotalMinor: subtotal, couponSavingMinor: coupon, taxMinor: mismatch == 'negative tax' ? -1 : 0,
          freightMinor: 0, deliveryFeeMinor: 0, tipMinor: tip, paymentChargeMinor: 0, totalMinor: total);
        return BuyV2CheckoutQuoteSnapshot(state: BuyV2CommerceLoadState.ready, quote: BuyV2CheckoutQuote.minor(
          id: good.id, sourceId: good.sourceId, evaluatedAt: good.evaluatedAt, validUntil: good.validUntil,
          lines: [line], totalMinor: total + (mismatch == 'quote total' ? 1 : 0)));
      });
      final session = await benefitSession(const BuyV2DisabledCartBenefitsAdapter(),
        [product.copyWith(priceMinor: 2001, deliveryPromise: 'Host-only fulfilment')], quoteAdapter: quote);
      expect(session.addProduct(product.id), isTrue); session.addAddress(frozenAddress); session.openCart();
      expect(await session.refreshCheckoutQuote(), isFalse);
      expect(session.checkoutQuote, isNull); expect(session.checkoutQuoteLoadState, BuyV2CommerceLoadState.unavailable);
      expect(session.cartTotalMinor, 2001); expect(quote.legacyCalls, 0);
    });
  }
  test('LF-PAISE older terms cannot replace the newer one-paise fee and quote identity', () async {
    final quote = _HostMinorQuote(); var fee = 1;
    quote.reply = (groups, tips) async => _hostExactQuote(groups, tips, fee: fee, id: 'host-quote-$fee');
    final held = Completer<BuyV2CommercialPaymentTermsSnapshot>();
    final terms = _HostMinorTerms();
    terms.reply = (groups, totals) => totals.values.single == 2001 ? held.future :
      Future.value(_hostExactRetailTerms(groups, totals));
    final session = await benefitSession(const BuyV2DisabledCartBenefitsAdapter(),
      [product.copyWith(priceMinor: 2000, deliveryPromise: 'Host-only fulfilment')], quoteAdapter: quote, termsAdapter: terms);
    expect(session.addProduct(product.id), isTrue); session.addAddress(frozenAddress); session.openCart();
    expect(await session.refreshCheckoutQuote(), isTrue);
    final oldGroups = session.checkoutFulfilmentGroups;
    expect(session.commercialPaymentTermsLoadState, BuyV2CommerceLoadState.loading);
    fee = 2; expect(await session.refreshCheckoutQuote(), isTrue);
    expect(await session.refreshCommercialPaymentTerms(), isTrue);
    held.complete(_hostExactRetailTerms(oldGroups, {oldGroups.single.key: 2001}));
    await Future<void>.delayed(Duration.zero);
    expect(session.checkoutPayableTotalMinor, 2002);
    expect(session.selectedCommercialPaymentTermFor(oldGroups.single.key)!.orderTotalMinor, 2002);
    expect(session.commercialPaymentTermsLoadState, BuyV2CommerceLoadState.ready);
  });
  test('LF-PAISE quote expiry while terms are pending clears loading and cannot accept them', () async {
    final quote = _HostMinorQuote()..reply = ((groups, tips) async => _hostExactQuote(groups, tips,
      expires: DateTime.now().add(const Duration(milliseconds: 250))));
    final held = Completer<BuyV2CommercialPaymentTermsSnapshot>();
    final terms = _HostMinorTerms()..reply = ((groups, totals) => held.future);
    final session = await benefitSession(const BuyV2DisabledCartBenefitsAdapter(),
      [product.copyWith(priceMinor: 2001, deliveryPromise: 'Host-only fulfilment')], quoteAdapter: quote, termsAdapter: terms);
    expect(session.addProduct(product.id), isTrue); session.addAddress(frozenAddress); session.openCart();
    expect(await session.refreshCheckoutQuote(), isTrue);
    final pending = session.refreshCommercialPaymentTerms(), groups = session.checkoutFulfilmentGroups;
    await Future<void>.delayed(const Duration(milliseconds: 350));
    held.complete(_hostExactRetailTerms(groups, {groups.single.key: 2001}));
    expect(await pending, isFalse); expect(session.checkoutQuoteReviewRequired, isTrue);
    expect(session.commercialPaymentTermsLoadState, BuyV2CommerceLoadState.unavailable);
    expect(session.selectedCommercialPaymentTermFor(groups.single.key), isNull);
  });
  for (final quoteOperation in [false, true]) {
    for (final retire in [false, true]) {
      test('LF-PAISE loading listener ${retire ? 'retirement' : 'newer request'} prevents stale ${quoteOperation ? 'quote' : 'term'} dispatch', () async {
        final quote = _HostMinorQuote()..reply = ((groups, tips) async => _hostExactQuote(groups, tips));
        final terms = _HostMinorTerms()..reply = ((groups, totals) async => _hostExactRetailTerms(groups, totals));
        final store = _HostRetirableStateStore();
        final session = await benefitSession(const BuyV2DisabledCartBenefitsAdapter(),
          [product.copyWith(priceMinor: 2001, deliveryPromise: 'Host-only fulfilment')],
          quoteAdapter: quoteOperation ? quote : null, termsAdapter: quoteOperation ? null : terms,
          customerStateStore: store);
        expect(session.addProduct(product.id), isTrue); session.addAddress(frozenAddress); session.openCart();
        final Future<bool> Function() operation = quoteOperation ? session.refreshCheckoutQuote : session.refreshCommercialPaymentTerms;
        expect(await operation(), isTrue);
        final before = quoteOperation ? quote.minorCalls : terms.minorCalls;
        var handled = false;
        void listener() {
          final loading = quoteOperation ? session.checkoutQuoteLoadState == BuyV2CommerceLoadState.loading :
            session.commercialPaymentTermsLoadState == BuyV2CommerceLoadState.loading;
          if (handled || !loading) return;
          handled = true;
          if (retire) { store.ownerScope = 'host-retired-owner'; }
          else { unawaited(operation()); }
        }
        session.addListener(listener);
        expect(await operation(), isFalse);
        await Future<void>.delayed(Duration.zero);
        session.removeListener(listener);
        expect(handled, isTrue);
        expect(quoteOperation ? quote.minorCalls : terms.minorCalls, before + (retire ? 0 : 1));
        if (!retire) {
          expect(quoteOperation ? session.checkoutQuoteLoadState : session.commercialPaymentTermsLoadState,
            BuyV2CommerceLoadState.ready);
        }
      });
    }
  }
  test('LF-PAISE benefit exact saving defaults do not conflict and malformed amounts never fall back', () {
    final value = hostBenefit();
    expect(value.validScope, isTrue); expect(value.savingAmountMinor, 25); expect(value.minimumSpendMinor, 2001);
    expect(() => value.savingAmount, throwsFormatException); expect(() => value.minimumSpend, throwsFormatException);
    for (final bad in [
      BuyV2CartBenefit(id: 'bad', kind: value.kind, destination: value.destination, title: value.title, detail: value.detail,
        sourceId: value.sourceId, savingAmount: 0, savingAmountMinor: 25),
      BuyV2CartBenefit(id: 'bad', kind: value.kind, destination: value.destination, title: value.title, detail: value.detail,
        sourceId: value.sourceId, savingAmountMinor: -1),
      BuyV2CartBenefit(id: 'bad', kind: value.kind, destination: value.destination, title: value.title, detail: value.detail,
        sourceId: value.sourceId, minimumSpend: 20, minimumSpendMinor: 2001),
    ]) { expect(bad.hasValidMoney, isFalse); expect(bad.validScope, isFalse); }
  });
  test('LF-PAISE enabled minor benefits preserve threshold saving and Store scope', () async {
    final adapter = _HostMinorBenefits(), coupon = hostBenefit(); adapter.offers.add(coupon);
    final base = product.copyWith(priceMinor: 2000, deliveryPromise: 'Host-only fulfilment');
    final tiny = base.copyWith(id: 'host-paise-unit', priceMinor: 1);
    final other = base.copyWith(id: 'host-foreign-store-unit', storeId: 'other-store', priceMinor: 999);
    final session = await benefitSession(adapter, [base, tiny, other]);
    expect(session.addProduct(base.id), isTrue);
    expect(session.cartBenefits(kind: BuyV2CartBenefitKind.coupon), isEmpty);
    expect(session.chooseCartBenefit(coupon), isFalse);
    expect(session.addProduct(tiny.id), isTrue);
    expect(session.cartBenefits(kind: BuyV2CartBenefitKind.coupon).single.id, coupon.id);
    expect(session.chooseCartBenefit(coupon), isTrue);
    expect(session.scopedCouponSavingMinor, 25); expect(session.scopedPayableTotalMinor, 1976);
    expect(session.calculatedCheckoutPayableTotalMinor, 1976);
    expect(session.addProduct(other.id), isTrue);
    expect(session.scopedCouponSavingMinor, 25); expect(session.scopedPayableTotalMinor, 2975);
    expect(adapter.minorInputs, contains(2001)); expect(adapter.legacyInputs, isEmpty);
    expect(session.productBenefitsFor(base), isEmpty, reason: 'One product preview remains one paise below the threshold');
  });
  testWidgets('LF-PAISE Cart renders the applied paise coupon and exact payable without rounding', (tester) async {
    final adapter = _HostMinorBenefits()..offers.add(hostBenefit(minimum: 1));
    final base = product.copyWith(priceMinor: 2000, deliveryPromise: 'Host-only fulfilment');
    final session = await benefitSession(adapter, [base]);
    expect(session.addProduct(base.id), isTrue);
    expect(session.chooseCartBenefit(adapter.offers.single), isTrue);
    session.openCart();
    await tester.pumpWidget(MaterialApp(theme: MoolTheme.light(), home: Scaffold(
      body: BuyV2CartView(session: session, onBrowseMore: () {}))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('₹19.75'), findsWidgets);
    final summary = find.byKey(const ValueKey('buy-cart-bill-summary'));
    await tester.scrollUntilVisible(summary, 260,
      scrollable: find.descendant(of: find.byKey(const ValueKey('buy-cart-scroll')),
        matching: find.byType(Scrollable)).first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Applied coupon ₹0.25'), findsOneWidget);
    expect(session.scopedCouponSavingMinor, 25);
    expect(session.cartTotalMinor, 2000);
    expect(tester.takeException(), isNull);
  });
  test('LF-PAISE legacy enabled adapter receives whole rupees and unsupported fractional requests stay unavailable', () async {
    final adapter = _HostLegacyBenefits(), coupon = hostBenefit(minimum: 1); adapter.offers.add(coupon);
    final base = product.copyWith(priceMinor: 2000, deliveryPromise: 'Host-only fulfilment');
    final tiny = base.copyWith(id: 'host-paise-unit', priceMinor: 1);
    final session = await benefitSession(adapter, [base, tiny]);
    expect(session.addProduct(base.id), isTrue);
    expect(session.cartBenefits(kind: BuyV2CartBenefitKind.coupon).single.id, coupon.id);
    expect(adapter.legacyInputs.every((value) => value == 20), isTrue);
    final before = adapter.legacyInputs.length;
    expect(session.addProduct(tiny.id), isTrue);
    expect(session.cartBenefits(kind: BuyV2CartBenefitKind.coupon), isEmpty);
    expect(adapter.legacyInputs.length, before);
    expect(session.cartBenefitsLoadState, BuyV2CartBenefitsLoadState.unavailable);
    expect(session.cartBenefitsMessage, isNotNull); expect(await session.refreshCartBenefits(), isFalse);
    expect(session.productBenefitsStateFor(tiny), BuyV2CartBenefitsLoadState.unavailable);
    expect(await session.refreshProductBenefits(tiny.id), isFalse);
    expect(session.cartTotalMinor, 2001);
  });
  test('LF-PAISE seeded subclass retains its legacy override without inheriting an exact-money capability', () async {
    final adapter = _HostSeededOverrideBenefits();
    final base = product.copyWith(priceMinor: 2000, deliveryPromise: 'Host-only fulfilment');
    final tiny = base.copyWith(id: 'host-seeded-paise-unit', priceMinor: 1);
    final session = await benefitSession(adapter, [base, tiny]);
    expect(session.addProduct(base.id), isTrue);
    session.cartBenefits(kind: BuyV2CartBenefitKind.coupon);
    expect(adapter.calls, isNotEmpty);
    expect(adapter.calls.every((amount) => amount == 20), isTrue);
    final before = adapter.calls.length;
    expect(session.addProduct(tiny.id), isTrue);
    expect(session.cartBenefits(kind: BuyV2CartBenefitKind.coupon), isEmpty);
    expect(adapter.calls.length, before);
    expect(session.cartBenefitsLoadState, BuyV2CartBenefitsLoadState.unavailable);
    expect(session.cartTotalMinor, 2001);
  });
  test('LF-PAISE live opportunity keeps one-paise shortfall separate from applied saving', () async {
    final adapter = _HostLiveBenefits(), coupon = hostBenefit(); adapter.offers.add(coupon);
    final base = product.copyWith(priceMinor: 2000, deliveryPromise: 'Host-only fulfilment');
    final tiny = base.copyWith(id: 'host-paise-unit', priceMinor: 1);
    final session = await benefitSession(adapter, [base, tiny]);
    expect(session.addProduct(base.id), isTrue); await session.refreshCartBenefits();
    expect(session.cartOfferOpportunity()!.remainingSpendMinor, 1);
    expect(session.scopedCouponSavingMinor, 0); expect(session.chooseCartBenefit(coupon), isFalse);
    expect(session.addProduct(tiny.id), isTrue); await session.refreshCartBenefits();
    expect(session.cartOfferOpportunity(), isNull); expect(session.chooseCartBenefit(coupon), isTrue);
    expect(session.scopedCouponSavingMinor, 25); expect(session.scopedPayableTotalMinor, 1976);
    expect(adapter.requests.last.lines.fold<int>(0, (sum, line) => sum + line.totalMinor), 2001);
  });
  test('LF-PAISE stale product benefit reply after one-paise refresh cannot remain loading or apply', () async {
    final adapter = _HostLiveBenefits()..held = Completer<BuyV2CartBenefitsSnapshot>();
    final facts = _HostBenefitFacts();
    final base = product.copyWith(priceMinor: 2000, deliveryPromise: 'Host-only fulfilment');
    final session = await benefitSession(adapter, [base], facts: facts);
    final pending = session.refreshProductBenefits(base.id);
    await Future<void>.delayed(Duration.zero);
    facts.minor = 2001; expect(session.refreshProductFacts(base.id), isTrue);
    adapter.held!.complete(BuyV2CartBenefitsSnapshot(state: BuyV2CartBenefitsLoadState.ready, evaluatedAt: at,
      benefits: [hostBenefit(minimum: 1)]));
    expect(await pending, isFalse); expect(session.productBenefitsFor(base), isEmpty);
    expect(session.productBenefitsStateFor(base), BuyV2CartBenefitsLoadState.unavailable);
  });
  test('LF-PAISE catalogue facts require a canonical minor amount', () {
    final facts = const BuyV2CatalogueProductFactsAdapter().snapshotFor(product);
    expect(facts.priceMinor, 26000);
  });
  test('LF-PAISE missing money becomes unavailable facts without an invented amount', () {
    const missing = BuyV2Product(id: 'host-no-price', destination: BuyV2Destination.shop,
      categoryId: 'grocery', brand: 'Host', title: 'Host missing price', variant: '', pack: '1 piece', unitPrice: '',
      badge: '', seller: 'Host Store', sellerType: 'Retailer', deliveryPromise: 'Host-only fulfilment',
      origin: '', confirmedOn: '', visualLabel: '', visualKind: 'unavailable');
    final snapshot = const BuyV2CatalogueProductFactsAdapter().snapshotFor(missing);
    expect(snapshot.hasValidMoney, isFalse); expect(snapshot.stale, isTrue);
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(core.dispose); addTearDown(session.dispose);
    expect(session.productFactsFor(missing).orderabilityLabel, 'Unavailable');
  });
  test('LF-PAISE exact facts copy equality and hash retain the last paise', () {
    const adapter = BuyV2CatalogueProductFactsAdapter();
    final legacy = adapter.snapshotFor(product);
    final exact = adapter.snapshotFor(product.copyWith(priceMinor: 1025));
    expect(exact.priceMinor, 1025); expect(() => exact.price, throwsFormatException);
    expect(exact.copyWith(stale: true).priceMinor, 1025);
    expect(exact.copyWith(price: 11).priceMinor, 1100);
    expect(exact.copyWith(priceMinor: 1026).priceMinor, 1026);
    expect(exact.copyWith(priceMinor: 1026), isNot(exact));
    final equivalent = legacy.copyWith(priceMinor: legacy.priceMinor);
    expect(equivalent, legacy); expect(equivalent.hashCode, legacy.hashCode);
    final bad = exact.copyWith(price: 10, priceMinor: 1025);
    expect(bad.hasValidMoney, isFalse); expect(bad, isNot(exact));
    expect(bad.copyWith(), bad); expect(() => bad.hashCode, returnsNormally);
    final invalidProduct = product.copyWith(price: 10, priceMinor: 1025);
    expect(adapter.snapshotFor(invalidProduct).hasValidMoney, isFalse);
  });
  test('LF-PAISE actual session admits one paise and reprices Cart across fractional tiers', () async {
    final source = _ExactMoneyHostCatalogue(), core = BuySession();
    final session = BuyV2Session(core: core, cataloguePageSource: source, reviewDataEnabled: true, catalogueNow: () => at);
    addTearDown(core.dispose); addTearDown(session.dispose);
    final tiered = product.copyWith(id: 'host-tiered-paise', priceMinor: 1025, mrpMinor: 1250,
      deliveryPromise: 'Host-only fulfilment', packTerms: BuyV2PackTerms(skuId: 'host-tiered-paise',
        revision: 'host-price-revision', sellUnit: 'piece', pricingStoreId: 'store-one', priceObservedAt: at,
        priceValidUntil: at.add(const Duration(hours: 1)), priceTiers: const [
          BuyV2PackPriceTier(minimumPacks: 1, priceMinor: 1025), BuyV2PackPriceTier(minimumPacks: 3, priceMinor: 1001)]));
    final tiny = product.copyWith(id: 'host-one-paise', priceMinor: 1, mrpMinor: 2, deliveryPromise: 'Host-only fulfilment');
    source.rows.addAll([tiered, tiny, product.copyWith(deliveryPromise: 'Host-only fulfilment')]);
    final pager = session.acquireCatalogueProducts('host-paise-session');
    addTearDown(() => session.releaseCatalogueProducts('host-paise-session'));
    await pager.open(storeQuery());
    expect(pager.page?.items.length, 3, reason: pager.message);
    expect(session.addProduct(tiered.id, quantity: 2), isTrue, reason: session.notice);
    expect(session.cartLines.single.totalMinor, 2050);
    expect(session.nextCartDealTierFor(tiered)!.priceMinor, 1001);
    expect(session.setCartQuantity(tiered.id, '3'), isTrue);
    expect(session.cartLines.single.totalMinor, 3003);
    expect(session.productFactsFor(tiered).priceMinor, 1001);
    expect(session.addProduct(tiny.id, quantity: 2), isTrue);
    expect(session.addProduct(product.id), isTrue);
    final exactTotals = session;
    expect(exactTotals.cartTotalMinor, 29005);
    expect(exactTotals.scopedCartTotalMinor, 29005);
    expect(exactTotals.scopedCartListPriceTotalMinor, 31754);
    expect(exactTotals.scopedCartSavingsMinor, 2749);
    expect(exactTotals.scopedCartFamilyTotalsMinor[BuyV2Destination.shop], 29005);
    expect(() => session.cartTotal, throwsFormatException, reason: 'Unmigrated consumers must not truncate paise');
    expect(session.setCartQuantity(tiered.id, '2'), isTrue);
    expect(exactTotals.cartTotalMinor, 28052);
    expect(session.quantityFor(tiered.id), 2);
    expect(session.setCartQuantity(tiny.id, '9007199254740991'), isFalse);
    expect(session.addProduct(tiny.id, quantity: 9007199254740991), isFalse);
    expect(exactTotals.cartTotalMinor, 28052, reason: 'Rejected capacity changes must not mutate any line');
    final historicalProduct = product.copyWith(id: tiered.id, pack: tiered.pack, price: 25);
    final historical = BuyV2Order(id: 'host-old-order', destination: BuyV2Destination.shop, title: 'Host historical sale',
      itemSummary: 'Four packs', total: 100, totalMinor: 10000, partner: product.seller, partnerType: product.sellerType,
      promise: 'Host-only fulfilment', destinationLabel: 'Host address', progress: 1, status: BuyV2OrderStatus.confirmed,
      productIds: [tiered.id], lines: [BuyV2CartLine(product: historicalProduct, quantity: 4)]);
    session.clearCart();
    expect(session.reorder(historical), isTrue);
    expect(session.quantityFor(tiered.id), 1, reason: 'Preserve approved reorder-as-editable-selection behavior');
    expect(session.cartTotalMinor, 1025, reason: 'Current exact selling price, not the historical ₹25');
    expect(historical.lines.single.product.priceMinor, 2500);
    expect(historical.totalMinor, 10000);
  });
  for (final difference in ['same', 'price', 'MRP']) {
    test('LF-PAISE recommendation identity compares exact $difference without whole getters', () async {
      final source = _ExactMoneyHostCatalogue(), core = BuySession();
      final session = BuyV2Session(core: core, cataloguePageSource: source, reviewDataEnabled: true, catalogueNow: () => at);
      addTearDown(core.dispose); addTearDown(session.dispose);
      final first = product.copyWith(id: 'host-choice-one', priceMinor: 1025, mrpMinor: 1250, deliveryPromise: 'Host-only fulfilment');
      source.rows.addAll([first, first.copyWith(id: 'host-choice-two',
        priceMinor: difference == 'price' ? 1026 : 1025, mrpMinor: difference == 'MRP' ? 1251 : 1250)]);
      final pager = session.acquireCatalogueProducts('host-exact-choice');
      addTearDown(() => session.releaseCatalogueProducts('host-exact-choice'));
      await pager.open(storeQuery()); expect(pager.page?.items.length, 2, reason: pager.message);
      final choices = session.cartRecommendationsFor(BuyV2Destination.shop, limit: 10)
        .where((p) => p.id.startsWith('host-choice-')).toList();
      expect(choices.length, difference == 'same' ? 1 : 2);
    });
  }
  test('LF-PAISE exact product Cart copy and MRP never manufacture a whole rupee price', () {
    final value = product.copyWith(priceMinor: 1025, mrpMinor: 1250);
    expect(value.priceMinor, 1025); expect(value.mrpMinor, 1250); expect(value.hasValidMoney, isTrue);
    expect(BuyV2CartLine(product: value, quantity: 3).totalMinor, 3075);
    expect(() => value.price, throwsFormatException); expect(() => value.mrp, throwsFormatException);
    final copy = value.copyWith(title: 'Retained exact price');
    expect(copy.priceMinor, 1025); expect(copy.mrpMinor, 1250);
    expect(copy.minimumOrderTotalMinor(), 1025);
    expect(copy.copyWith(price: 20).priceMinor, 2000);
    expect(copy.copyWith(priceMinor: 1).priceMinor, 1);
    expect(product.copyWith(priceMinor: 26000).price, 260);
    expect(product.copyWith(mrpMinor: 28000).mrp, 280);
  });
  test('LF-PAISE exact tiers and mixed legacy fulfilment sum use integer paise', () {
    final terms = BuyV2PackTerms(skuId: product.id, revision: 'exact-host-tiers', sellUnit: 'piece',
      pricingStoreId: product.storeId, priceObservedAt: at, priceValidUntil: at.add(const Duration(hours: 1)),
      priceTiers: const [BuyV2PackPriceTier(minimumPacks: 1, priceMinor: 1025),
        BuyV2PackPriceTier(minimumPacks: 3, priceMinor: 1001)]);
    expect(terms.validPricingFor(product.storeId, 1), isTrue);
    expect(terms.priceMinorForQuantity(2, 1025), 1025); expect(terms.priceMinorForQuantity(3, 1025), 1001);
    final lines = [BuyV2CartLine(product: product.copyWith(priceMinor: terms.priceMinorForQuantity(3, 1025)), quantity: 3),
      BuyV2CartLine(product: product, quantity: 1), BuyV2CartLine(product: product.copyWith(priceMinor: 1), quantity: 2)];
    final group = BuyV2FulfilmentGroup(groupKey: 'host-exact', destination: BuyV2Destination.shop,
      partner: 'Host Store', partnerType: 'Retailer', promise: '', lines: lines);
    expect(lines.first.totalMinor, 3003); expect(group.totalMinor, 29005);
    expect(() => group.total, throwsFormatException);
  });
  for (final amount in [-1, 9007199254740992]) {
    test('LF-PAISE invalid exact $amount cannot downgrade to legacy price', () {
      final value = product.copyWith(price: 10, priceMinor: amount, mrp: 12, mrpMinor: amount);
      expect(value.hasValidMoney, isFalse);
      expect(() => value.priceMinor, throwsFormatException); expect(() => value.price, throwsFormatException);
      expect(() => value.mrpMinor, throwsFormatException); expect(() => value.mrp, throwsFormatException);
    });
  }
  test('LF-PAISE conflicting representations reject rather than choosing a convenient amount', () {
    final value = product.copyWith(price: 10, priceMinor: 1025);
    expect(value.hasValidMoney, isFalse); expect(() => value.priceMinor, throwsFormatException);
    expect(() => const BuyV2PackPriceTier(minimumPacks: 1, price: 10, priceMinor: 1025).priceMinor, throwsFormatException);
    expect(product.copyWith(price: 10, priceMinor: 1000).priceMinor, 1000);
  });
  test('LF-PAISE safe boundary uses BigInt before multiplication or sum', () {
    const maximum = 9007199254740991;
    expect(buyV2MultiplyMinor(maximum, 1), maximum);
    expect(buyV2SumMinor([maximum, 0]), maximum);
    expect(buyV2MultiplyMinor(1, 0), 0);
    expect(() => buyV2MultiplyMinor(maximum, 2), throwsFormatException);
    expect(() => buyV2MultiplyMinor(1, -1), throwsFormatException);
    expect(() => buyV2SumMinor([maximum, 1]), throwsFormatException);
    expect(() => buyV2ExactMinorAmount(legacyRupees: maximum), throwsFormatException);
    // ₹100 crore remains exact; this is an isolated model fixture, not native data.
    expect(buyV2MultiplyMinor(100000000000, 1), 100000000000);
  });
  test('LF-PAISE procurement restart preserves exact money and never restores eligibility', () async {
    final preferences = _ExactMoneyHostPreferences(), value = product.copyWith(priceMinor: 1025, mrpMinor: 1250);
    BuyV2SharedPreferencesCustomerStateStore fresh() => BuyV2SharedPreferencesCustomerStateStore(preferences, ownerScope: 'host-paise');
    final snapshot = BuyV2CustomerStateSnapshot(procurementDraft: BuyV2ProcurementDraftSnapshot(
      ownerScope: 'host-paise', cartProducts: {value.id: value}));
    expect(await fresh().write(snapshot), isTrue);
    final retained = (await fresh().read())!.procurementDraft!.cartProducts[value.id]!;
    expect(retained.priceMinor, 1025); expect(retained.mrpMinor, 1250);
    expect(retained.procurementSupplierGrant!.approved, isFalse);
    expect(retained.procurementSupplierGrant!.published, isFalse); expect(retained.catalogueListing, isFalse);
    final raw = jsonDecode(preferences.values.values.single) as Map;
    final stored = raw['procurementDraft']['cartProducts'][value.id] as Map;
    expect(stored['priceMinor'], 1025); expect(stored.containsKey('price'), isFalse);
  });
  for (final corruption in ['null', 'string', 'negative', 'overflow', 'conflict', 'MRP', 'old version']) {
    test('LF-PAISE corrupt retained $corruption never falls back to an apparently valid legacy price', () async {
      final preferences = _ExactMoneyHostPreferences(), value = product.copyWith(priceMinor: 1025, mrpMinor: 1250);
      final store = BuyV2SharedPreferencesCustomerStateStore(preferences, ownerScope: 'host-paise');
      expect(await store.write(BuyV2CustomerStateSnapshot(procurementDraft: BuyV2ProcurementDraftSnapshot(
        ownerScope: 'host-paise', cartProducts: {value.id: value}))), isTrue);
      final key = preferences.values.keys.single;
      final raw = jsonDecode(preferences.values[key]!) as Map<String, dynamic>;
      final row = raw['procurementDraft']['cartProducts'][value.id] as Map;
      if (corruption == 'null') row['priceMinor'] = null;
      if (corruption == 'string') row['priceMinor'] = '1025';
      if (corruption == 'negative') row['priceMinor'] = -1;
      if (corruption == 'overflow') row['priceMinor'] = 9007199254740992;
      if (corruption == 'MRP') row['mrpMinor'] = '1250';
      if (corruption == 'old version') raw['procurementDraft']['version'] = 1;
      row['price'] = 10;
      preferences.values[key] = jsonEncode(raw);
      expect((await store.read())!.procurementDraft!.cartProducts, isEmpty);
      expect(jsonDecode(preferences.values[key]!), raw, reason: 'Read must not silently rewrite retained evidence');
    });
  }
  test('LF-PAISE mixed procurement and legacy v1 remain readable without granting a listing', () async {
    final preferences = _ExactMoneyHostPreferences(), exact = product.copyWith(id: 'exact-row', priceMinor: 1);
    final store = BuyV2SharedPreferencesCustomerStateStore(preferences, ownerScope: 'host-paise');
    expect(await store.write(BuyV2CustomerStateSnapshot(procurementDraft: BuyV2ProcurementDraftSnapshot(
      ownerScope: 'host-paise', cartProducts: {exact.id: exact, product.id: product}))), isTrue);
    final rows = (await store.read())!.procurementDraft!.cartProducts;
    expect(rows[exact.id]!.priceMinor, 1); expect(rows[product.id]!.price, 260);
    expect(rows.values.every((p) => !p.catalogueListing), isTrue);
    expect(await store.write(BuyV2CustomerStateSnapshot(procurementDraft: BuyV2ProcurementDraftSnapshot(
      ownerScope: 'host-paise', cartProducts: {product.id: product}))), isTrue);
    expect(jsonDecode(preferences.values.values.single)['procurementDraft']['version'], 1);
    expect((await store.read())!.procurementDraft!.cartProducts[product.id]!.priceMinor, 26000);
  });
  test('LF-PAISE purchased-product restart retains fractional unit price and exact total', () async {
    final preferences = _ExactMoneyHostPreferences(), value = product.copyWith(priceMinor: 1025, mrpMinor: 1250);
    final store = BuyV2SharedPreferencesCustomerStateStore(preferences, ownerScope: 'host-paise');
    // Four packs at ₹10.25 is exactly ₹41. No dummy/truncated legacy total.
    final order = BuyV2Order(id: 'host-purchased-paise', destination: value.destination, title: 'Host purchased items',
      itemSummary: 'Four packs', total: 41, totalMinor: 4100, partner: value.seller, partnerType: value.sellerType,
      promise: 'Awaiting fulfilment', destinationLabel: 'Host address', progress: 0, status: BuyV2OrderStatus.confirmed,
      productIds: [value.id], lines: [BuyV2CartLine(product: value, quantity: 4)]);
    expect(await store.write(BuyV2CustomerStateSnapshot(orders: [order])), isTrue);
    final restored = (await store.read())!.orders.single;
    expect(restored.totalMinor, 4100); expect(restored.total, 41);
    expect(restored.lines.single.product.priceMinor, 1025);
    expect(restored.lines.single.product.mrpMinor, 1250); expect(restored.lines.single.totalMinor, 4100);
    expect(restored.lines.single.product.catalogueListing, isFalse);
    final key = preferences.values.keys.single;
    final raw = jsonDecode(preferences.values[key]!) as Map<String, dynamic>;
    raw['orders'][0]['totalMinor'] = '4100'; preferences.values[key] = jsonEncode(raw);
    await expectLater(store.read(), throwsFormatException);
    expect(jsonDecode(preferences.values[key]!), raw);
  });
  BuyV2Order exactHistoryOrder({int? paid = 1, int balance = 1043, int tax = 2,
    int price = 1025, String title = 'Host purchase', double progress = 0,
    String? purchaseId = 'host-purchase', String storeId = 'store-one',
    List<String>? ids, BuyV2CollectionOrderReference? collection, int total = 1044,
    BuyV2TaxInvoiceDetails? invoice}) => BuyV2Order.minor(
    id: 'host-order', destination: BuyV2Destination.shop, title: title, itemSummary: 'One host SKU',
    totalMinor: total, partner: 'Host Store', partnerType: 'Retailer', promise: 'Host delivery',
    destinationLabel: 'Host address', progress: progress, status: BuyV2OrderStatus.preparing,
    purchaseId: purchaseId, productIds: ids ?? [product.id], collection: collection,
    lines: [BuyV2CartLine(product: product.copyWith(priceMinor: price, storeId: storeId), quantity: 1)],
    tipMinor: 5, discountMinor: 1, taxMinor: tax, freightMinor: 3, deliveryFeeMinor: 4,
    paymentChargeMinor: 6, amountPaidNowMinor: paid, balanceDueMinor: balance,
    taxInvoiceState: invoice == null ? null : BuyV2TaxInvoiceState.ready, taxInvoiceDetails: invoice);
  for (final kind in ['matching whole tax', 'fractional cannot match legacy', 'unsafe legacy tax']) {
    test('LF-PAISE invoice refresh $kind uses checked original units without offline misclassification', () async {
      final tax = kind == 'fractional cannot match legacy' ? 2 : 100;
      final total = 1044 + tax - 2;
      final original = exactHistoryOrder(tax: tax, total: total, balance: total - 1);
      final invoice = BuyV2TaxInvoiceDetails(invoiceNumber: 'HOST-INVOICE', issuedAt: at,
        sellerLegalName: 'Host Store', sellerAddress: 'Host address', sellerGstin: '123456789012345',
        placeOfSupply: 'Host state', sourceId: 'host-invoice-source', lines: [BuyV2TaxInvoiceLine(
          description: 'Host product', hsnSac: '1234', taxableValue: 10, gstRate: 10,
          cgst: kind == 'unsafe legacy tax' ? 9007199254740991 : tax == 100 ? 1 : 0, sgst: 0, igst: 0, cess: 0)]);
      final commerce = _HostExactOrderCommerce()..records = [original]
        ..refreshedOrder = exactHistoryOrder(tax: tax, total: total, balance: total - 1, invoice: invoice, progress: .5);
      final core = BuySession();
      final session = BuyV2Session(core: core, commerceAdapter: commerce, reviewDataEnabled: false);
      addTearDown(core.dispose); addTearDown(session.dispose);
      await session.restoreCommerce();
      expect(await session.refreshOrder(original.id), kind == 'matching whole tax');
      expect(session.orderRefreshState(original.id), kind == 'matching whole tax'
        ? BuyV2CommerceLoadState.ready : BuyV2CommerceLoadState.unavailable);
      expect(session.orders.single.taxMinor, tax); expect(session.orders.single.payableTotalMinor, total);
      expect(session.orders.single.progress, kind == 'matching whole tax' ? .5 : 0);
    });
  }
  for (final update in ['valid', 'invalid money', 'foreign purchase']) {
    test('LF-PAISE exact order refresh $update retains truthful status and original amount', () async {
      final original = exactHistoryOrder();
      final commerce = _HostExactOrderCommerce()..records = [original]
        ..refreshedOrder = exactHistoryOrder(progress: .5, tax: update == 'invalid money' ? -1 : 2,
          purchaseId: update == 'foreign purchase' ? 'host-other-purchase' : 'host-purchase');
      final core = BuySession();
      final session = BuyV2Session(core: core, commerceAdapter: commerce, reviewDataEnabled: false);
      addTearDown(core.dispose); addTearDown(session.dispose);
      await session.restoreCommerce();
      expect(await session.refreshOrder(original.id), update == 'valid');
      expect(session.orderRefreshState(original.id), update == 'valid' ? BuyV2CommerceLoadState.ready : BuyV2CommerceLoadState.unavailable);
      expect(session.orders.single.payableTotalMinor, 1044);
      expect(session.orders.single.balanceDueMinor, 1043);
      expect(session.orders.single.purchaseId, 'host-purchase');
      expect(session.orders.single.progress, update == 'valid' ? .5 : 0);
    });
  }
  BuyV2Order hostInvoiceOrder(BuyV2Destination destination, String kind) {
    final price = kind == 'large' ? 100000000000 : 1025;
    final value = BuyV2Catalogue.products.firstWhere((value) => value.destination == destination)
      .copyWith(id: 'host-invoice-sku', canonicalId: 'host-invoice-product', storeId: 'host-invoice-store',
        priceMinor: price, mrpMinor: price + 225);
    final lines = [BuyV2CartLine(product: value, quantity: 1)];
    if (kind == 'legacy override') {
      return BuyV2Order(id: 'host-invoice-order', destination: destination, title: 'Host invoice', itemSummary: 'One product',
        total: 10, totalMinor: 1025, partner: 'Host Store', partnerType: 'Retailer', promise: 'Host recorded estimate',
        destinationLabel: 'Host address', progress: 0, status: BuyV2OrderStatus.preparing, lines: lines);
    }
    return BuyV2Order.minor(id: 'host-invoice-order', destination: destination, title: 'Host invoice', itemSummary: 'One product',
      totalMinor: price + 19, partner: 'Host Store', partnerType: 'Retailer', promise: 'Host recorded estimate',
      destinationLabel: 'Host address', progress: 0, status: BuyV2OrderStatus.preparing, lines: lines,
      tipMinor: 5, discountMinor: 1, taxMinor: 2, freightMinor: 3, deliveryFeeMinor: 4, paymentChargeMinor: 6,
      amountPaidNowMinor: kind == 'unknown paid' ? null : 1, balanceDueMinor: price + 18);
  }
  for (final destination in [BuyV2Destination.shop, BuyV2Destination.wholesale]) {
    for (final kind in ['exact', 'large', 'unknown paid', 'legacy override']) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('LF-PAISE invoice ${destination.name} $kind exact display scale=$scale', (tester) async {
          tester.view.physicalSize = const Size(320, 568); tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
          final order = hostInvoiceOrder(destination, kind);
          final faults = <FlutterErrorDetails>[]; final onError = FlutterError.onError;
          FlutterError.onError = (detail) { faults.add(detail); onError?.call(detail); };
          addTearDown(() { FlutterError.onError = onError; });
          await tester.pumpWidget(MaterialApp(theme: MoolTheme.light(), builder: (context, child) =>
            MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
            home: BuyV2InvoicePage(order: order)));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: faults.map((detail) =>
            '${detail.exception}\n${detail.stack.toString().split('\n').take(8).join('\n')}').join('\n'));
          expect(find.text(buyV2MoneyMinor(order.payableTotalMinor)), findsWidgets);
          await tester.scrollUntilVisible(find.text('Order details'), 250, maxScrolls: 80);
          if (kind == 'unknown paid') expect(find.text('Amount paid now'), findsNothing);
          await tester.scrollUntilVisible(find.text('Order total'), 250, maxScrolls: 80);
          expect(find.text(buyV2MoneyMinor(order.payableTotalMinor)), findsWidgets);
          expect(find.text(buyV2MoneyMinor(order.lines.single.totalMinor)), findsWidgets);
          expect(tester.takeException(), isNull);
          if (kind == 'legacy override') expect(order.total, 10);
          await tester.pumpWidget(const SizedBox.shrink());
        });
      }
      test('LF-PAISE invoice ${destination.name} $kind exports original exact money without changing native protocol', () async {
        const channel = MethodChannel('host.paise/invoice');
        MethodCall? captured;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
          captured = call; return 'saved';
        });
        addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
        final order = hostInvoiceOrder(destination, kind);
        expect(await saveBuyV2InvoiceWithChannel(BuyV2InvoiceDocument(order: order), channel: channel,
          platform: TargetPlatform.android), BuyV2InvoiceDownloadOutcome.saved);
        expect(captured!.method, 'saveInvoice');
        final payload = captured!.arguments as Map;
        expect(payload.keys.toSet(), {'fileName', 'lines'});
        final lines = (payload['lines'] as List).cast<String>();
        String amount(int minor) => minor % 100 == 0 ? '${minor ~/ 100}' : '${minor ~/ 100}.${(minor % 100).toString().padLeft(2, '0')}';
        expect(lines, contains('Order total: INR ${amount(order.payableTotalMinor)}'));
        expect(lines, contains('Items subtotal: INR ${amount(order.lines.single.totalMinor)}'));
        expect(lines, contains('1 x ${order.lines.single.product.customerTitle} (${order.lines.single.product.pack}) - INR ${amount(order.lines.single.totalMinor)}'));
        if (kind == 'unknown paid') expect(lines.where((line) => line.startsWith('Amount paid now:')), isEmpty);
        if (kind == 'exact') {
          expect(lines, contains('Amount paid now: INR 0.01')); expect(lines, contains('Balance due: INR 10.43 - Due later'));
          expect(lines, contains('Delivery tip: INR 0.05')); expect(lines, contains('Coupon saving: -INR 0.01'));
          expect(lines, contains('GST and taxes: INR 0.02')); expect(lines, contains('Freight: INR 0.03'));
          expect(lines, contains('Delivery fee: INR 0.04')); expect(lines, contains('Payment charge: INR 0.06'));
        }
      });
    }
  }
  for (final unitCase in [(500, '20.50'), (1000, '10.25'), (1500, '6.83'), (400, '25.63')]) {
    test('LF-PAISE Store exact retail preview and per-unit amount quantity=${unitCase.$1}', () {
      final measure = WorkspacePackMeasure(unit: BuyV2ComparisonUnit.kilogram,
        quantityMilli: unitCase.$1, unitsPerCase: 1);
      expect(measure.pricePerUnitMinor(1025), '₹${unitCase.$2}/kg');
      expect(measure.pricePerUnit(10), measure.pricePerUnitMinor(1000));
      final product = workspaceMasterCatalogue.first.copyWith(purchasePriceMinor: 925,
        sellingPriceMinor: 1025, mrpMinor: 1250, packMeasure: measure);
      final preview = product.toBuyPublicProduct(storeName: 'Host Store', storeId: 'host-store');
      expect(preview.priceMinor, 1025); expect(preview.mrpMinor, 1250);
      expect(preview.unitPrice, '₹${unitCase.$2}/kg');
      expect(preview.id, product.id); expect(preview.canonicalId, product.canonicalId);
      expect(preview.pack, product.pack); expect(preview.storeId, 'host-store');
      expect(product.toCataloguePreviewProduct().priceMinor, 1025);
      expect(() => measure.pricePerUnitMinor(-1), throwsFormatException);
      expect(() => measure.pricePerUnitMinor(99999999901), throwsFormatException);
    });
  }

  test('LF-PAISE Store current public audit binds paise and rejects one-paise changes while v1 stays strict', () {
    final source = workspaceMasterCatalogue.first.copyWith(purchasePriceMinor: 925,
      sellingPriceMinor: 1025, mrpMinor: 1250);
    final target = source.toBuyPublicProduct(storeName: 'Host Store', storeId: 'host-store');
    final sourceAudit = WorkspacePublicationContract.sourceProductAuditValues(source,
      storeId: 'host-store', storeName: 'Host Store');
    final targetAudit = WorkspacePublicationContract.publicProductAuditValues(target);
    expect(sourceAudit['price'], isNull); expect(sourceAudit['priceMinor'], 1025);
    expect(sourceAudit['mrp'], isNull); expect(sourceAudit['mrpMinor'], 1250);
    expect(targetAudit['priceMinor'], 1025); expect(targetAudit['mrpMinor'], 1250);
    expect(sourceAudit['publicListingIdentity'], isNull);
    expect(targetAudit['publicListingIdentity'], isNull);
    expect(() => WorkspacePublicationContract.sourceProductValues(source, storeId: 'host-store', storeName: 'Host Store'), throwsFormatException);
    expect(() => WorkspacePublicationContract.publicProductValues(target), throwsFormatException);
    for (final kind in ['matching', 'priceMinor', 'mrpMinor']) {
      final projected = kind == 'priceMinor' ? target.copyWith(priceMinor: 1026)
          : kind == 'mrpMinor' ? target.copyWith(mrpMinor: 1251) : target;
      final issues = WorkspacePublicationContract.productIssues(source, storeId: 'host-store',
        storeName: 'Host Store', projected: projected);
      expect(issues.any((issue) => issue.field.endsWith(':priceMinor')), kind == 'priceMinor');
      expect(issues.any((issue) => issue.field.endsWith(':mrpMinor')), kind == 'mrpMinor');
    }
  });

  test('LF-PAISE shared Store price input keeps exact decimals and original ceiling', () {
    for (final value in <(String, int)>[
      ('0', 0), ('.5', 50), ('9.25', 925), ('10.2', 1020),
      (' 10.25 ', 1025), ('2147483647', 214748364700),
    ]) {
      final minor = workspacePriceMinorFromInput(value.$1);
      expect(minor, value.$2);
      expect(workspacePriceMinorFromInput(workspacePriceInputFromMinor(minor!)), value.$2);
    }
    for (final value in ['', '9.251', '1e3', '2147483647.01', '9,25', '₹9', '-1', '.', '1.', 'NaN']) {
      expect(workspacePriceMinorFromInput(value), isNull, reason: value);
    }
    expect(workspacePriceInputFromMinor(1025), '10.25');
    expect(workspacePriceInputFromMinor(1000), '10');
  });

  for (final method in WorkspaceStockEntryMethod.values) {
    test('LF-PAISE original Stock purchase provenance uses explicit minor schema ${method.name}', () {
      final base = workspaceMasterCatalogue.first;
      final legacy = WorkspaceStockEntry(method: method, productId: base.id,
        sku: base.sku, pack: base.pack, stockMode: base.stockMode, quantity: base.stock,
        purchasePriceRupees: 230, recordedAt: at, stockAsOf: at);
      final legacyJson = legacy.toJson();
      expect(jsonEncode(WorkspaceStockEntry.fromJson(legacyJson)!.toJson()), jsonEncode(legacyJson));
      for (final price in [925, 1000, 214748364700]) {
        final raw = <String, Object?>{...legacyJson, 'version': 2, 'purchasePriceMinor': price}
          ..remove('purchasePriceRupees');
        final exact = WorkspaceStockEntry.fromJson(raw)!;
        expect(exact.valid, isTrue); expect(exact.toJson(), raw);
        expect(exact.purchasePriceMinor, price);
        expect(exact.usesMinorAmounts, isTrue);
        if (price % 100 == 0) {
          expect(exact.purchasePriceRupees, price ~/ 100);
        } else {
          expect(() => exact.purchasePriceRupees, throwsFormatException);
        }
        expect(exact.toJson().containsKey('purchasePriceRupees'), isFalse);
        final product = base.copyWith(purchasePriceMinor: 925,
          sellingPriceMinor: 1025, mrpMinor: 1250, stockEntry: exact);
        final restored = WorkspaceCatalogueItem.fromInventoryJson(product.toInventoryJson());
        expect(restored.stockEntry!.contentIdentity, exact.contentIdentity);
        expect(restored.copyWith(purchasePriceMinor: 950, stock: 3)
          .stockEntry!.contentIdentity, exact.contentIdentity);
        for (final patch in <Map<String, Object?>>[
          {'version': 1}, {'purchasePriceRupees': 9}, {'purchasePriceRupees': null},
          {'purchasePriceMinor': null}, {'purchasePriceMinor': -1}, {'purchasePriceMinor': 0},
          {'purchasePriceMinor': 214748364701}, {'purchasePriceMinor': 9.25},
          {'purchasePriceMinor': '925'},
        ]) {
          expect(() => WorkspaceStockEntry.fromJson({...raw, ...patch}), throwsFormatException);
        }
        expect(() => WorkspaceStockEntry.fromJson({...raw}..remove('purchasePriceMinor')), throwsFormatException);
      }
      expect(() => WorkspaceStockEntry.fromJson({...legacyJson, 'purchasePriceMinor': 23000}), throwsFormatException);
      final ambiguous = WorkspaceStockEntry(method: method, productId: base.id,
        sku: base.sku, pack: base.pack, stockMode: base.stockMode, quantity: base.stock,
        purchasePriceRupees: 9, purchasePriceMinor: 925, recordedAt: at, stockAsOf: at);
      expect(ambiguous.valid, isFalse);
      expect(() => ambiguous.purchasePriceMinor, throwsFormatException);
      expect(() => ambiguous.toJson(), throwsFormatException);
    });
  }

  test('LF-PAISE Store explicit minor inventory survives roundtrip without legacy price invention', () {
    final original = workspaceMasterCatalogue.first;
    final raw = <String, Object?>{...original.toInventoryJson(),
      'version': 3, 'purchasePriceMinor': 925, 'sellingPriceMinor': 1025, 'mrpMinor': 1250}
      ..remove('purchasePrice')..remove('sellingPrice')..remove('mrp');
    final restored = WorkspaceCatalogueItem.fromInventoryJson(raw);
    expect(restored.toInventoryJson(), raw);
    expect(restored.id, original.id); expect(restored.canonicalId, original.canonicalId);
    expect(restored.sku, original.sku); expect(restored.stock, original.stock);
  });

  for (final withEntry in [false, true]) {
    test('LF-PAISE Store legacy inventory stays literal and original Stock provenance survives exact edits entry=$withEntry', () {
      final base = workspaceMasterCatalogue.first;
      final entry = WorkspaceStockEntry(method: WorkspaceStockEntryMethod.catalogue,
        productId: base.id, sku: base.sku, pack: base.pack, stockMode: base.stockMode,
        quantity: base.stock, purchasePriceRupees: base.purchasePrice, recordedAt: at, stockAsOf: at);
      final original = withEntry ? base.copyWith(stockEntry: entry) : base;
      final raw = original.toInventoryJson();
      expect(raw['version'], withEntry ? 2 : 1);
      expect(raw.keys.toList().indexOf('mrp'), raw.keys.toList().indexOf('visualKind') + 1);
      expect(jsonEncode(WorkspaceCatalogueItem.fromInventoryJson(raw).toInventoryJson()), jsonEncode(raw));
      expect(jsonEncode(original.copyWith(stock: original.stock).toInventoryJson()), jsonEncode(raw));
      final exact = original.copyWith(purchasePriceMinor: 925, sellingPriceMinor: 1025, mrpMinor: 1250);
      expect(exact.usesMinorAmounts, isTrue);
      expect(exact.purchasePriceMinor, 925); expect(exact.sellingPriceMinor, 1025); expect(exact.mrpMinor, 1250);
      expect(() => exact.purchasePrice, throwsFormatException);
      expect(() => exact.sellingPrice, throwsFormatException);
      expect(() => exact.mrp, throwsFormatException);
      final moved = exact.copyWith(stock: 7);
      expect(moved.id, original.id); expect(moved.sku, original.sku); expect(moved.stock, 7);
      expect(moved.purchasePriceMinor, 925); expect(moved.sellingPriceMinor, 1025);
      expect(moved.cataloguePhoto?.toJson(), original.cataloguePhoto?.toJson());
      expect(moved.stockEntry?.contentIdentity, original.stockEntry?.contentIdentity);
      final inventory = WorkspaceSavedInventory(account: 'host-account', store: 'host-store', qa: true,
        revision: 1, savedAt: at, products: [moved], movements: []);
      final serialized = inventory.toJson();
      expect(serialized['version'], 3);
      final restored = WorkspaceSavedInventory.fromJson(serialized);
      expect(restored.products, hasLength(1)); expect(restored.toJson(), serialized);
      expect(restored.products.single.sellingPriceMinor, 1025);
      expect(() => WorkspaceSavedInventory.fromJson({...serialized, 'version': withEntry ? 2 : 1}), throwsFormatException);
    });
  }
  for (final price in [1000, 100000000000]) {
    test('LF-PAISE Store exact whole-valued and100crore records keep explicit units price=$price', () {
      final product = workspaceMasterCatalogue.first.copyWith(purchasePriceMinor: price,
        sellingPriceMinor: price, mrpMinor: price);
      expect(product.toInventoryJson()['version'], 3);
      expect(product.sellingPrice, price ~/ 100);
      expect(product.copyWith(sellingPrice: 20).sellingPriceMinor, 2000);
      final restored = WorkspaceCatalogueItem.fromInventoryJson(product.toInventoryJson());
      expect(restored.sellingPriceMinor, price); expect(restored.usesMinorAmounts, isTrue);
    });
  }
  test('LF-PAISE Store missing MRP stays unknown and unsafe or ambiguous units reject without fallback', () {
    final raw = <String, Object?>{...workspaceMasterCatalogue.first.toInventoryJson(),
      'version': 3, 'purchasePriceMinor': 925, 'sellingPriceMinor': 1025, 'mrpMinor': null}
      ..remove('purchasePrice')..remove('sellingPrice')..remove('mrp');
    final restored = WorkspaceCatalogueItem.fromInventoryJson(raw);
    expect(restored.mrpMinor, isNull); expect(restored.mrp, isNull);
    expect(restored.copyWith(stock: 2).mrpMinor, isNull);
    for (final field in ['purchasePriceMinor', 'sellingPriceMinor', 'mrpMinor']) {
      expect(() => WorkspaceCatalogueItem.fromInventoryJson({...raw}..remove(field)), throwsFormatException);
      for (final bad in [-1, 9007199254740992, '1025', 10.25]) {
        expect(() => WorkspaceCatalogueItem.fromInventoryJson({...raw, field: bad}), throwsFormatException);
      }
    }
    for (final legacy in ['purchasePrice', 'sellingPrice', 'mrp']) {
      expect(() => WorkspaceCatalogueItem.fromInventoryJson({...raw, legacy: null}), throwsFormatException);
    }
    expect(() => WorkspaceCatalogueItem.fromInventoryJson({...workspaceMasterCatalogue.first.toInventoryJson(), 'sellingPriceMinor': 1025}), throwsFormatException);
    final conflict = workspaceMasterCatalogue.first.copyWith(sellingPrice: 10, sellingPriceMinor: 1025);
    expect(() => conflict.sellingPriceMinor, throwsFormatException);
    expect(() => conflict.sellingPrice, throwsFormatException);
    expect(() => conflict.toInventoryJson(), throwsFormatException);
  });

  test('LF-PAISE invoice malformed money cannot invoke native save or claim success', () async {
    const channel = MethodChannel('host.paise/invalid-invoice');
    var calls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (_) async {
      calls++; return 'saved';
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
    final invalid = exactHistoryOrder(tax: -1);
    expect(invalid.hasValidMoney, isFalse);
    expect(await saveBuyV2InvoiceWithChannel(BuyV2InvoiceDocument(order: invalid),
      channel: channel, platform: TargetPlatform.android), BuyV2InvoiceDownloadOutcome.failed);
    expect(calls, 0);
  });

  test('LF-PAISE exact history order has no invented whole amount and retains every component', () {
    final order = exactHistoryOrder();
    expect(order.usesMinorAmounts, isTrue); expect(order.hasValidMoney, isTrue);
    expect([order.payableTotalMinor, order.tipMinor, order.discountMinor, order.taxMinor,
      order.freightMinor, order.deliveryFeeMinor, order.paymentChargeMinor, order.amountPaidNowMinor, order.balanceDueMinor],
      [1044, 5, 1, 2, 3, 4, 6, 1, 1043]);
    expect(() => order.total, throwsFormatException); expect(() => order.tax, throwsFormatException);
    expect(exactHistoryOrder(paid: null).amountPaidNowMinor, isNull);
    expect(exactHistoryOrder(tax: -1).hasValidMoney, isFalse);
  });
  test('LF-PAISE exact history restart preserves amounts original identities and private hold identity', () async {
    final preferences = _ExactMoneyHostPreferences();
    BuyV2SharedPreferencesCustomerStateStore fresh() => BuyV2SharedPreferencesCustomerStateStore(preferences, ownerScope: 'host-paise');
    final original = exactHistoryOrder(), identity = BuyV2BalancePaymentHold.identityOf(exactHistoryOrder());
    // This helper also owns after-sales identity. Its amount-free hold does not
    // pretend the still-legacy balance-payment adapter accepts paise requests.
    final hold = BuyV2OrderResolutionHold(ownerScope: 'host-paise', accountId: 'host-buyer',
      orderId: original.id, orderIdentity: identity);
    expect(await fresh().write(BuyV2CustomerStateSnapshot(orders: [original], orderResolutionHolds: [hold])), isTrue);
    final restored = (await fresh().read())!, order = (await fresh().read())!.orders.single;
    expect(order.payableTotalMinor, 1044); expect(order.tipMinor, 5); expect(order.discountMinor, 1);
    expect(order.taxMinor, 2); expect(order.freightMinor, 3); expect(order.deliveryFeeMinor, 4); expect(order.paymentChargeMinor, 6);
    expect(order.amountPaidNowMinor, 1); expect(order.balanceDueMinor, 1043);
    expect(order.lines.single.product.id, product.id); expect(order.lines.single.totalMinor, 1025);
    expect(order.purchaseId, 'host-purchase'); expect(BuyV2BalancePaymentHold.identityOf(order), identity);
    expect(restored.orderResolutionHolds.single.orderId, original.id);
    expect(restored.orderResolutionHolds.single.orderIdentity, identity);
    expect(BuyV2BalancePaymentHold.identityOf(exactHistoryOrder(paid: 1044, balance: 0)), identity);
    final row = jsonDecode(preferences.values.values.single)['orders'].single as Map;
    expect(row['moneyVersion'], 2); expect(row['totalMinor'], 1044); expect(row.containsKey('total'), isFalse);
  });
  test('LF-PAISE legacy collection compatibility amount and absent override hashes are unchanged', () async {
    for (final override in [null, 1025]) {
      final preferences = _ExactMoneyHostPreferences();
      final store = BuyV2SharedPreferencesCustomerStateStore(preferences, ownerScope: 'host-paise');
      final original = BuyV2Order(id: 'host-order', destination: BuyV2Destination.shop, title: 'Host purchase', itemSummary: 'One host SKU',
        total: 10, totalMinor: override, partner: 'Host Store', partnerType: 'Retailer', promise: 'Host delivery',
        destinationLabel: 'Host address', progress: 0, status: BuyV2OrderStatus.preparing, purchaseId: 'host-purchase',
        collection: const BuyV2CollectionOrderReference(storeId: 'store-one', purchaserAccountId: 'host-buyer'),
        productIds: [product.id], lines: [BuyV2CartLine(product: product.copyWith(priceMinor: 1025), quantity: 1)]);
      final expected = sha256.convert(utf8.encode(override == null ?
        '["host-order","host-purchase","shop",10,null,"Host Store",["sku-one"],["sku-one","store-one","canonical-one","Sunflower","1 L",1]]' :
        '["host-order","host-purchase","shop",10,1025,"Host Store",["sku-one"],["sku-one","store-one","canonical-one","Sunflower","1 L",1]]')).toString();
      expect(BuyV2BalancePaymentHold.identityOf(original), expected);
      expect(await store.write(BuyV2CustomerStateSnapshot(orders: [original])), isTrue);
      final restored = (await store.read())!.orders.single;
      expect(restored.usesMinorAmounts, isFalse); expect(restored.total, 10); expect(restored.totalMinor, override);
      expect(restored.payableTotalMinor, override ?? 1000); expect(restored.amountPaidNowMinor, isNull);
      expect(BuyV2BalancePaymentHold.identityOf(restored), expected);
      final row = jsonDecode(preferences.values.values.single)['orders'].single as Map;
      expect(row.containsKey('moneyVersion'), isFalse); expect(row['total'], 10);
    }
  });
  test('LF-PAISE exact history preserves unknown paid amount empty explicit IDs and collection routing without a grant', () async {
    final preferences = _ExactMoneyHostPreferences();
    final store = BuyV2SharedPreferencesCustomerStateStore(preferences, ownerScope: 'host-paise');
    final original = exactHistoryOrder(paid: null, ids: [], collection:
      const BuyV2CollectionOrderReference(storeId: 'store-one', purchaserAccountId: 'host-buyer'));
    expect(await store.write(BuyV2CustomerStateSnapshot(orders: [original])), isTrue);
    final restored = (await store.read())!.orders.single;
    expect(restored.amountPaidNowMinor, isNull); expect(restored.amountPaidNow, isNull);
    expect(restored.productIds, isEmpty); expect(restored.lines.single.product.id, product.id);
    expect(restored.collection!.storeId, 'store-one'); expect(restored.collection!.purchaserAccountId, 'host-buyer');
    expect(BuyV2BalancePaymentHold.identityOf(restored), BuyV2BalancePaymentHold.identityOf(original));
    expect(restored.lines.single.product.catalogueListing, isFalse);
  });
  for (final key in ['totalMinor', 'tipMinor', 'discountMinor', 'amountPaidNowMinor', 'balanceDueMinor',
    'taxMinor', 'freightMinor', 'deliveryFeeMinor', 'paymentChargeMinor']) {
    test('LF-PAISE malformed exact history $key cannot be silently defaulted or erased', () async {
      final preferences = _ExactMoneyHostPreferences();
      final store = BuyV2SharedPreferencesCustomerStateStore(preferences, ownerScope: 'host-paise');
      expect(await store.write(BuyV2CustomerStateSnapshot(orders: [exactHistoryOrder()])), isTrue);
      final storageKey = preferences.values.keys.single;
      final raw = jsonDecode(preferences.values[storageKey]!) as Map;
      (raw['orders'] as List).single[key] = '1';
      final invalid = jsonEncode(raw); preferences.values[storageKey] = invalid;
      await expectLater(store.read(), throwsFormatException);
      expect(preferences.values[storageKey], invalid);
    });
  }
  for (final corruption in ['missing paid', 'null fee', 'negative fee', 'overflow fee', 'legacy conflict',
    'downgrade', 'version', 'missing lines', 'fractional quantity', 'duplicate lines', 'foreign product', 'collection']) {
    test('LF-PAISE corrupt exact history $corruption retains bytes instead of partial recovery', () async {
      final preferences = _ExactMoneyHostPreferences();
      final store = BuyV2SharedPreferencesCustomerStateStore(preferences, ownerScope: 'host-paise');
      expect(await store.write(BuyV2CustomerStateSnapshot(orders: [exactHistoryOrder()])), isTrue);
      final storageKey = preferences.values.keys.single;
      final raw = jsonDecode(preferences.values[storageKey]!) as Map;
      final row = (raw['orders'] as List).single as Map;
      switch (corruption) {
        case 'missing paid': row.remove('amountPaidNowMinor');
        case 'null fee': row['taxMinor'] = null;
        case 'negative fee': row['taxMinor'] = -1;
        case 'overflow fee': row['taxMinor'] = 9007199254740992;
        case 'legacy conflict': row['total'] = 10;
        case 'downgrade': row.remove('moneyVersion'); row['total'] = 10;
        case 'version': row['moneyVersion'] = 2.0;
        case 'missing lines': row['lines'] = [];
        case 'fractional quantity': (row['lines'] as List).single['quantity'] = 1.5;
        case 'duplicate lines': (row['lines'] as List).add((row['lines'] as List).single);
        case 'foreign product': (row['lines'] as List).single['productId'] = 'foreign';
        case 'collection': row['collection'] = {'storeId': '', 'purchaserAccountId': 'host-buyer'};
      }
      final invalid = jsonEncode(raw); preferences.values[storageKey] = invalid;
      await expectLater(store.read(), throwsFormatException);
      expect(preferences.values[storageKey], invalid);
    });
  }
  test('LF-PAISE invalid exact order write cannot overwrite the last good history', () async {
    final preferences = _ExactMoneyHostPreferences();
    final store = BuyV2SharedPreferencesCustomerStateStore(preferences, ownerScope: 'host-paise');
    expect(await store.write(BuyV2CustomerStateSnapshot(orders: [exactHistoryOrder()])), isTrue);
    final before = preferences.values.values.single;
    expect(await store.write(BuyV2CustomerStateSnapshot(orders: [exactHistoryOrder(tax: -1)])), isFalse);
    expect(preferences.values.values.single, before);
  });
  test('LF-PAISE exact identity binds purchased prices fees and collection owner not payment progress', () {
    final identity = BuyV2BalancePaymentHold.identityOf(exactHistoryOrder());
    expect(BuyV2BalancePaymentHold.identityOf(exactHistoryOrder(price: 1026)), isNot(identity));
    expect(BuyV2BalancePaymentHold.identityOf(exactHistoryOrder(tax: 3)), isNot(identity));
    expect(BuyV2BalancePaymentHold.identityOf(exactHistoryOrder(paid: 1044, balance: 0)), identity);
    final collection = BuyV2BalancePaymentHold.identityOf(exactHistoryOrder(collection:
      const BuyV2CollectionOrderReference(storeId: 'store-one', purchaserAccountId: 'host-buyer')));
    expect(BuyV2BalancePaymentHold.identityOf(exactHistoryOrder(collection:
      const BuyV2CollectionOrderReference(storeId: 'store-one', purchaserAccountId: 'other-buyer'))), isNot(collection));
  });
  test('LF-PAISE exact writer rejects facts which cannot be faithfully restored', () async {
    final preferences = _ExactMoneyHostPreferences();
    final store = BuyV2SharedPreferencesCustomerStateStore(preferences, ownerScope: 'host-paise');
    expect(await store.write(BuyV2CustomerStateSnapshot(orders: [exactHistoryOrder()])), isTrue);
    final before = preferences.values.values.single;
    for (final invalid in [exactHistoryOrder(title: ''), exactHistoryOrder(title: ' Host purchase '),
      exactHistoryOrder(progress: double.nan), exactHistoryOrder(collection:
        const BuyV2CollectionOrderReference(storeId: 'foreign-store', purchaserAccountId: 'host-buyer'))]) {
      expect(await store.write(BuyV2CustomerStateSnapshot(orders: [invalid])), isFalse);
      expect(preferences.values.values.single, before);
    }
  });
  test('LF-PAISE corrupt exact order cannot silently restore a new editable account Cart', () async {
    final preferences = _ExactMoneyHostPreferences();
    final store = BuyV2SharedPreferencesCustomerStateStore(preferences, ownerScope: 'host-paise');
    expect(await store.write(BuyV2CustomerStateSnapshot(orders: [exactHistoryOrder()])), isTrue);
    final key = preferences.values.keys.single, raw = jsonDecode(preferences.values.values.single) as Map;
    (raw['orders'] as List).single['amountPaidNowMinor'] = 'unknown';
    final invalid = jsonEncode(raw); preferences.values[key] = invalid;
    final core = BuySession();
    final session = BuyV2Session(core: core, customerStateStore: store, reviewDataEnabled: true);
    addTearDown(core.dispose); addTearDown(session.dispose);
    await session.restoreCustomerState(restoreBrowsing: false);
    expect(session.customerStateRecoveryPending, isTrue); expect(session.addProduct('s-tomato'), isFalse);
    expect(preferences.values[key], invalid);
  });
  test('LF-PAISE optional exact identity never normalizes empty into null after writing', () async {
    final preferences = _ExactMoneyHostPreferences();
    final store = BuyV2SharedPreferencesCustomerStateStore(preferences, ownerScope: 'host-paise');
    final valid = exactHistoryOrder(purchaseId: null);
    expect(await store.write(BuyV2CustomerStateSnapshot(orders: [valid])), isTrue);
    expect(BuyV2BalancePaymentHold.identityOf((await store.read())!.orders.single),
        BuyV2BalancePaymentHold.identityOf(valid));
    final before = preferences.values.values.single;
    for (final invalid in [exactHistoryOrder(purchaseId: ''), exactHistoryOrder(purchaseId: ' host-purchase '),
      exactHistoryOrder(storeId: ''), exactHistoryOrder(storeId: ' store-one ')]) {
      expect(await store.write(BuyV2CustomerStateSnapshot(orders: [invalid])), isFalse);
      expect(preferences.values.values.single, before);
    }
    for (final field in ['purchaseId', 'storeId']) {
      final raw = jsonDecode(before) as Map, row = (jsonDecode(before)['orders'] as List).single as Map;
      if (field == 'purchaseId') { row[field] = ''; }
      else { (row['lines'] as List).single['purchasedProduct'][field] = ''; }
      raw['orders'] = [row];
      final malformed = jsonEncode(raw); preferences.values[preferences.values.keys.single] = malformed;
      await expectLater(store.read(), throwsFormatException);
      expect(preferences.values.values.single, malformed);
    }
  });
  BuyV2BalancePaymentHold exactBalanceHold({int minor = 107}) => BuyV2BalancePaymentHold.minor(
    ownerScope: 'host-paise', accountId: null, orderId: 'host-order',
    orderIdentity: BuyV2BalancePaymentHold.identityOf(exactHistoryOrder()),
    idempotencyKey: 'host-original-balance-key', amountDueMinor: minor);
  test('LF-PAISE balance hold retains legacy literal units and tagged exact recovery', () async {
    final legacy = BuyV2BalancePaymentHold(ownerScope: 'host-paise', accountId: null, orderId: 'host-order',
      orderIdentity: BuyV2BalancePaymentHold.identityOf(exactHistoryOrder()), idempotencyKey: 'host-original-balance-key', amountDue: 7);
    expect(legacy.toJson(), {'ownerScope': 'host-paise', 'accountId': null, 'orderId': 'host-order',
      'orderIdentity': legacy.orderIdentity, 'idempotencyKey': 'host-original-balance-key', 'amountDue': 7,
      'currency': 'INR', 'paymentReference': null});
    expect(legacy.amountDue, 7); expect(legacy.amountDueMinor, 700); expect(legacy.usesMinorAmounts, isFalse);
    final exact = exactBalanceHold(), referenced = exactBalanceHold().withReference('host-balance-reference');
    expect(exact.amountDueMinor, 107); expect(() => exact.amountDue, throwsFormatException);
    expect(exact.usesMinorAmounts, isTrue); expect(exact.storageKey, legacy.storageKey);
    expect(exact.toJson()['moneyVersion'], 2); expect(exact.toJson().containsKey('amountDue'), isFalse);
    expect(referenced.usesMinorAmounts, isTrue); expect(referenced.amountDueMinor, 107);
    expect(BuyV2BalancePaymentHold.fromJson(legacy.toJson()).toJson(), legacy.toJson());
    final preferences = _ExactMoneyHostPreferences();
    BuyV2SharedPreferencesCustomerStateStore fresh() => BuyV2SharedPreferencesCustomerStateStore(preferences, ownerScope: 'host-paise');
    expect(await fresh().write(BuyV2CustomerStateSnapshot(orders: [exactHistoryOrder()], balancePaymentHolds: [referenced])), isTrue);
    final restored = (await fresh().read())!.balancePaymentHolds.single;
    expect(restored.toJson(), referenced.toJson()); expect(restored.idempotencyKey, exact.idempotencyKey);
    expect(restored.amountDueMinor, 107); expect(restored.paymentReference, 'host-balance-reference');
  });
  for (final corruption in ['mixed', 'missing', 'null', 'string', 'fractional', 'version', 'downgrade', 'negative', 'overflow']) {
    test('LF-PAISE malformed tagged balance hold $corruption never downgrades original units', () {
      final raw = Map<String, Object?>.of(exactBalanceHold().toJson());
      switch (corruption) {
        case 'mixed': raw['amountDue'] = 1;
        case 'missing': raw.remove('amountDueMinor');
        case 'null': raw['amountDueMinor'] = null;
        case 'string': raw['amountDueMinor'] = '107';
        case 'fractional': raw['amountDueMinor'] = 107.0;
        case 'version': raw['moneyVersion'] = 2.0;
        case 'downgrade': raw.remove('moneyVersion');
        case 'negative': raw['amountDueMinor'] = -1;
        case 'overflow': raw['amountDueMinor'] = 9007199254740992;
      }
      expect(() => BuyV2BalancePaymentHold.fromJson(raw), throwsFormatException);
    });
  }
  test('LF-PAISE invalid exact balance hold cannot replace prior recovery and large legacy bytes survive', () async {
    final preferences = _ExactMoneyHostPreferences();
    final store = BuyV2SharedPreferencesCustomerStateStore(preferences, ownerScope: 'host-paise');
    expect(await store.write(BuyV2CustomerStateSnapshot(balancePaymentHolds: [exactBalanceHold()])), isTrue);
    final before = preferences.values.values.single;
    expect(await store.write(BuyV2CustomerStateSnapshot(balancePaymentHolds: [exactBalanceHold(minor: 0)])), isFalse);
    expect(preferences.values.values.single, before);
    final original = BuyV2BalancePaymentHold(ownerScope: 'host-paise', accountId: null, orderId: 'host-order',
      orderIdentity: exactBalanceHold().orderIdentity, idempotencyKey: 'host-large-legacy-key', amountDue: 9007199254740991);
    expect(original.valid, isTrue); expect(() => original.amountDueMinor, throwsFormatException);
    expect(BuyV2BalancePaymentHold.fromJson(original.toJson()).toJson(), original.toJson());
  });
  Future<({BuyV2Session session, _ExactMoneyHostPreferences preferences})> balanceFixture(
    _HostLegacyBalance adapter, {_ExactMoneyHostPreferences? restoredPreferences, BuyV2BalancePaymentHold? hold,
    void Function(String key, String value)? beforeSet, bool recoveryExpected = true}) async {
    final preferences = restoredPreferences ?? _ExactMoneyHostPreferences(beforeSet: beforeSet);
    final store = BuyV2SharedPreferencesCustomerStateStore(preferences, ownerScope: 'host-paise');
    if (restoredPreferences == null) {
      expect(await store.write(BuyV2CustomerStateSnapshot(orders: [exactHistoryOrder()],
        balancePaymentHolds: hold == null ? [] : [hold])), isTrue);
    }
    final core = BuySession(), commerce = _HostExactOrderCommerce()..records = [exactHistoryOrder()];
    final session = BuyV2Session(core: core, commerceAdapter: commerce, balancePaymentAdapter: adapter,
      customerStateStore: store, reviewDataEnabled: false);
    addTearDown(core.dispose); addTearDown(session.dispose);
    await session.restoreCustomerState(restoreBrowsing: false);
    await session.restoreCommerce();
    expect(session.customerStateRecoveryPending, !recoveryExpected, reason: session.notice ?? session.commerceMessage);
    expect(session.orders.any((order) => order.id == 'host-order'), isTrue);
    return (session: session, preferences: preferences);
  }
  test('LF-PAISE balance minor start saves exact original before dispatch then restores reconcile only', () async {
    final adapter = _HostMinorBalance();
    final actual = await balanceFixture(adapter);
    expect(await actual.session.restoreBalancePayment('host-order'), isTrue);
    adapter.onStart = () {
      final record = jsonDecode(actual.preferences.values.values.single)['balancePaymentHolds']['records'].single as Map;
      expect(record['moneyVersion'], 2); expect(record['amountDueMinor'], 1043);
      expect(record['idempotencyKey'], adapter.keys.single); expect(record['paymentReference'], isNull);
    };
    expect(await actual.session.startBalancePayment('host-order'), isTrue);
    expect(adapter.minorAmounts, [1043]); expect(adapter.legacyAmounts, isEmpty);
    final restarted = await balanceFixture(adapter, restoredPreferences: actual.preferences);
    expect(restarted.session.balancePaymentFor('host-order')!.amountDueMinor, 1043);
    expect(restarted.session.balancePaymentFor('host-order')!.state, BuyV2BalancePaymentState.unknown);
    expect(await restarted.session.startBalancePayment('host-order'), isFalse);
    expect(await restarted.session.reconcileBalancePayment('host-order'), isTrue);
    expect(adapter.reconciles, 1); expect(adapter.keys.length, 1);
    expect(restarted.session.orders.single.balanceDueMinor, 1043, reason: 'No local ledger/payment posting');
  });
  test('LF-PAISE legacy balance start receives rupees only and fractional result grants no capability', () async {
    final fractional = _HostLegacyBalance();
    final unsupported = await balanceFixture(fractional);
    expect(await unsupported.session.restoreBalancePayment('host-order'), isTrue);
    expect(await unsupported.session.startBalancePayment('host-order'), isFalse);
    expect(fractional.keys, isEmpty); expect(fractional.legacyAmounts, isEmpty);
    final legacy = _HostLegacyBalance()..dueMinor = 1000;
    final supported = await balanceFixture(legacy);
    expect(await supported.session.restoreBalancePayment('host-order'), isTrue);
    expect(await supported.session.startBalancePayment('host-order'), isTrue);
    expect(legacy.legacyAmounts, [10]); expect(legacy.minorAmounts, isEmpty);
    final record = jsonDecode(supported.preferences.values.values.single)['balancePaymentHolds']['records'].single as Map;
    expect(record['amountDue'], 10); expect(record.containsKey('moneyVersion'), isFalse);
  });
  test('LF-PAISE balance saved without reference stays unknown after restart without another call', () async {
    final adapter = _HostMinorBalance()..failStart = true;
    final fixture = await balanceFixture(adapter);
    expect(await fixture.session.restoreBalancePayment('host-order'), isTrue);
    expect(await fixture.session.startBalancePayment('host-order'), isFalse);
    final restarted = await balanceFixture(adapter, restoredPreferences: fixture.preferences);
    expect(restarted.session.balancePaymentFor('host-order')!.amountDueMinor, 1043);
    expect(await restarted.session.restoreBalancePayment('host-order'), isFalse);
    expect(await restarted.session.startBalancePayment('host-order'), isFalse);
    expect(await restarted.session.reconcileBalancePayment('host-order'), isFalse);
    expect(adapter.loads, 1); expect(adapter.keys.length, 1); expect(adapter.reconciles, 0);
  });
  test('LF-PAISE balance failed save retries only its known-unsent key and amount unit', () async {
    final adapter = _HostMinorBalance();
    final attemptedKeys = <String>[];
    var failWrite = false;
    final actual = await balanceFixture(adapter, beforeSet: (_, text) {
      final records = jsonDecode(text)['balancePaymentHolds']['records'] as List;
      if (records.isNotEmpty) attemptedKeys.add(records.single['idempotencyKey'] as String);
      if (failWrite) throw StateError('Host preference write failure');
    });
    expect(await actual.session.restoreBalancePayment('host-order'), isTrue);
    failWrite = true;
    expect(await actual.session.startBalancePayment('host-order'), isFalse);
    expect(adapter.keys, isEmpty);
    failWrite = false;
    expect(await actual.session.startBalancePayment('host-order'), isTrue);
    expect(attemptedKeys.toSet(), {adapter.keys.single}); expect(adapter.minorAmounts, [1043]);
  });
  test('LF-PAISE balance reference-save failure cannot bypass persistence through refresh or continuation', () async {
    final adapter = _HostMinorBalance();
    var failReferenceSave = false;
    final fixture = await balanceFixture(adapter, beforeSet: (_, text) {
      final records = jsonDecode(text)['balancePaymentHolds']['records'] as List;
      if (failReferenceSave && records.isNotEmpty && records.single['paymentReference'] != null) {
        throw StateError('Host reference write failed');
      }
    });
    final session = fixture.session;
    expect(await session.restoreBalancePayment('host-order'), isTrue);
    failReferenceSave = true;
    expect(await session.startBalancePayment('host-order'), isFalse);
    adapter.nextLoad = BuyV2BalancePaymentResult.minor(state: BuyV2BalancePaymentState.paymentActionRequired,
      amountDueMinor: 1043, dueLabel: 'Host due', customerMessage: 'Host original action',
      paymentReference: 'host-balance-reference', paymentActionUri: Uri.parse('https://host.invalid/original'));
    expect(await session.restoreBalancePayment('host-order'), isFalse);
    var handoffs = 0;
    expect(await session.continueBalancePayment('host-order', (_) async { handoffs++; return true; }), isFalse);
    expect(handoffs, 0);
    expect(session.balancePaymentFor('host-order')!.state, BuyV2BalancePaymentState.unknown);
    final restarted = await balanceFixture(adapter, restoredPreferences: fixture.preferences);
    expect(restarted.session.balancePaymentFor('host-order')!.paymentReference, isNull);
    expect(await restarted.session.restoreBalancePayment('host-order'), isFalse);
    failReferenceSave = false;
    expect(await session.restoreBalancePayment('host-order'), isTrue);
    expect(jsonDecode(fixture.preferences.values.values.single)['balancePaymentHolds']['records'].single['paymentReference'],
      'host-balance-reference');
    expect(await session.continueBalancePayment('host-order', (_) async { handoffs++; return true; }), isTrue);
    expect(handoffs, 1); expect(adapter.keys.length, 1);
  });
  for (final reply in ['one-paise drift', 'foreign reference', 'due only', 'negative', 'unsafe']) {
    test('LF-PAISE balance $reply reply preserves exact original unknown attempt', () async {
      final adapter = _HostMinorBalance();
      final fixture = await balanceFixture(adapter), session = fixture.session;
      expect(await session.restoreBalancePayment('host-order'), isTrue);
      expect(await session.startBalancePayment('host-order'), isTrue);
      expect(await session.continueBalancePayment('host-order', (_) async => false), isFalse);
      adapter.nextLoad = adapter.nextReconcile = BuyV2BalancePaymentResult.minor(
        state: reply == 'due only' ? BuyV2BalancePaymentState.due : BuyV2BalancePaymentState.paymentPending,
        amountDueMinor: switch (reply) { 'one-paise drift' => 1042, 'negative' => -1, 'unsafe' => 9007199254740992, _ => 1043 },
        dueLabel: 'Host due', customerMessage: 'Host reply',
        paymentReference: reply == 'foreign reference' ? 'host-other-reference' :
          reply == 'due only' ? null : 'host-balance-reference');
      expect(await session.restoreBalancePayment('host-order'), isFalse);
      expect(await session.reconcileBalancePayment('host-order'), isFalse);
      final retained = session.balancePaymentFor('host-order')!;
      expect(retained.amountDueMinor, 1043); expect(retained.paymentReference, 'host-balance-reference');
      expect(retained.state, BuyV2BalancePaymentState.unknown);
      expect(await session.startBalancePayment('host-order'), isFalse); expect(adapter.keys.length, 1);
    });
  }
  test('LF-PAISE balance failed transport keeps exact original reference and amount', () async {
    final adapter = _HostMinorBalance();
    final fixture = await balanceFixture(adapter), session = fixture.session;
    expect(await session.restoreBalancePayment('host-order'), isTrue);
    expect(await session.startBalancePayment('host-order'), isTrue);
    expect(await session.continueBalancePayment('host-order', (_) async => throw StateError('Host handoff failure')), isFalse);
    adapter.failLoad = adapter.failReconcile = true;
    expect(await session.restoreBalancePayment('host-order'), isFalse);
    expect(await session.reconcileBalancePayment('host-order'), isFalse);
    expect(session.balancePaymentFor('host-order')!.amountDueMinor, 1043);
    expect(session.balancePaymentFor('host-order')!.paymentReference, 'host-balance-reference');
    expect(await session.startBalancePayment('host-order'), isFalse); expect(adapter.keys.length, 1);
  });
  test('LF-PAISE balance corrupt nested recovery is preserved and cannot dispatch', () async {
    final adapter = _HostMinorBalance();
    final initial = await balanceFixture(adapter, hold: exactBalanceHold());
    final key = initial.preferences.values.keys.single;
    final raw = jsonDecode(initial.preferences.values[key]!) as Map<String, dynamic>;
    raw['balancePaymentHolds']['records'].single['amountDueMinor'] = '107';
    final bytes = jsonEncode(raw); initial.preferences.values[key] = bytes;
    final restarted = await balanceFixture(adapter, restoredPreferences: initial.preferences, recoveryExpected: false);
    expect(await restarted.session.restoreBalancePayment('host-order'), isFalse);
    expect(await restarted.session.startBalancePayment('host-order'), isFalse);
    expect(adapter.loads, 0); expect(adapter.keys, isEmpty);
    expect(initial.preferences.values[key], bytes);
  });
  test('LF-PAISE balance unsafe legacy conversion preserves original raw hold without calls', () async {
    final adapter = _HostMinorBalance();
    final hold = BuyV2BalancePaymentHold(ownerScope: 'host-paise', accountId: null, orderId: 'host-order',
      orderIdentity: exactBalanceHold().orderIdentity, idempotencyKey: 'host-large-legacy-key', amountDue: 9007199254740991);
    final fixture = await balanceFixture(adapter, hold: hold);
    final before = fixture.preferences.values.values.single;
    expect(fixture.session.balancePaymentFor('host-order'), isNull);
    expect(await fixture.session.restoreBalancePayment('host-order'), isFalse);
    expect(await fixture.session.startBalancePayment('host-order'), isFalse);
    expect(adapter.loads, 0); expect(adapter.keys, isEmpty);
    expect(fixture.preferences.values.values.single, before);
  });
  for (final exact in [false, true]) {
    test('LF-PAISE balance whole amount retains explicit dispatch unit after unsent save exact=$exact', () async {
      final adapter = exact ? _HostMinorBalance() : _HostLegacyBalance();
      adapter.dueMinor = 1000;
      var failWrite = false;
      final fixture = await balanceFixture(adapter, beforeSet: (_, text) {
        if (failWrite) throw StateError('Host initial save failure');
      });
      expect(await fixture.session.restoreBalancePayment('host-order'), isTrue);
      failWrite = true; expect(await fixture.session.startBalancePayment('host-order'), isFalse);
      expect(adapter.keys, isEmpty);
      failWrite = false; expect(await fixture.session.startBalancePayment('host-order'), isTrue);
      expect(adapter.minorAmounts, exact ? [1000] : isEmpty);
      expect(adapter.legacyAmounts, exact ? isEmpty : [10]);
      final row = jsonDecode(fixture.preferences.values.values.single)['balancePaymentHolds']['records'].single as Map;
      expect(row.containsKey('moneyVersion'), exact);
      expect(row[exact ? 'amountDueMinor' : 'amountDue'], exact ? 1000 : 10);
    });
  }
  for (final surface in ['tracking', 'orders']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('LF-PAISE $surface shows exact balance at text scale $scale', (tester) async {
        tester.view.physicalSize = const Size(320, 568); tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
        final fixture = await balanceFixture(_HostMinorBalance()), session = fixture.session;
        expect(await session.restoreBalancePayment('host-order'), isTrue);
        if (surface == 'tracking') expect(session.openTracking('host-order'), isTrue);
        await tester.pumpWidget(MaterialApp(theme: MoolTheme.light(), builder: (context, child) =>
          MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
          home: Scaffold(body: surface == 'tracking' ? BuyV2TrackingView(session: session, onOpenOrderHelp: (_) {}) :
            BuyV2OrdersView(session: session, onOpenOrderHelp: (_) {}))));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (surface == 'tracking') {
          await tester.scrollUntilVisible(find.byKey(const ValueKey('buy-tracking-balance-amount')), 250,
            scrollable: find.byType(Scrollable).first);
          await tester.pumpAndSettle();
          expect(find.textContaining('₹10.43'), findsWidgets);
        } else {
          expect(find.textContaining('₹10.44'), findsWidgets);
          expect(find.text('₹10.43 balance'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
  BuyV2OrderSupplyProgress exactRefundProgress(int amount, {BuyV2SupplyRefundState state = BuyV2SupplyRefundState.refunded}) =>
    BuyV2OrderSupplyProgress(orderId: 'host-order', purchaseId: 'host-purchase', sourceId: 'host-supply', revision: 1,
      state: BuyV2SupplyState.ready,
      lines: [BuyV2SupplyLine(productId: product.id, variant: product.variant, pack: product.pack,
        orderedQuantity: 1, availableQuantity: 1, unavailableQuantity: 0, supplierId: 'host-supplier', supplierName: 'Host supplier')],
      refundState: state, refundAmountMinor: amount, refundRoute: 'Host original route', refundReference: 'host-refund');
  test('LF-PAISE supply refund bounds use exact paid money without rounding or unknown-paid inference', () {
    expect(exactRefundProgress(1).matchesOrder(exactHistoryOrder()), isTrue);
    expect(exactRefundProgress(2).matchesOrder(exactHistoryOrder()), isFalse);
    expect(exactRefundProgress(1).matchesOrder(exactHistoryOrder(paid: null)), isFalse);
    expect(exactRefundProgress(1045, state: BuyV2SupplyRefundState.pending).matchesOrder(exactHistoryOrder()), isFalse);
    expect(exactRefundProgress(1).matchesOrder(exactHistoryOrder(tax: -1)), isFalse);
  });
  test('LF-PAISE exact tracking preserves money and invalidates immutable purchased-price drift', () async {
    final commerce = _HostExactOrderCommerce()..records = [exactHistoryOrder()];
    final tracking = _HostExactOrderTracking(), core = BuySession();
    final session = BuyV2Session(core: core, commerceAdapter: commerce, liveDeliveryAdapter: tracking, reviewDataEnabled: false);
    addTearDown(core.dispose); addTearDown(session.dispose);
    await session.restoreCommerce();
    expect(await session.refreshLiveDelivery('host-order'), isTrue);
    expect(tracking.calls, 1); expect(session.liveDeliveryFor('host-order'), isNotNull);
    expect(session.orders.single.payableTotalMinor, 1044);
    expect(session.orders.single.amountPaidNowMinor, 1);
    commerce.records = [exactHistoryOrder(paid: 1044, balance: 0)];
    await session.restoreCommerce();
    expect(session.liveDeliveryFor('host-order'), isNotNull);
    commerce.records = [exactHistoryOrder(price: 1026)];
    await session.restoreCommerce();
    expect(session.liveDeliveryFor('host-order'), isNull);
  });
  test('LF-PAISE malformed purchased price invalidates exact tracking without throwing', () async {
    final commerce = _HostExactOrderCommerce()..records = [exactHistoryOrder()];
    final core = BuySession();
    final session = BuyV2Session(core: core, commerceAdapter: commerce,
      liveDeliveryAdapter: _HostExactOrderTracking(), reviewDataEnabled: false);
    addTearDown(core.dispose); addTearDown(session.dispose);
    await session.restoreCommerce();
    expect(await session.refreshLiveDelivery('host-order'), isTrue);
    commerce.records = [exactHistoryOrder(price: -1)];
    await session.restoreCommerce();
    expect(session.liveDeliveryFor('host-order'), isNull);
  });
  const publicFields = WorkspacePublicDetailsFields(street: 'Host market road', city: 'Jodhpur', state: 'Rajasthan',
    pinCode: '342003', publicContactPhone: '+91 90000 00001', openingTime: '09:00', closingTime: '21:00');
  Map<String, dynamic> metadata({int revision = 1}) => {'schemaVersion': 1, 'realm': 'production', 'storeId': 'store-one',
    'observedAt': at.toIso8601String(), 'locationVerified': false, 'publicAvailabilityConfirmed': false,
    'area': 'Host locality', 'state': 'ready', 'revision': revision, 'details': publicFields.toJson()};
  Map<String, dynamic> ownerDetailsReply(Map<String, Object?> body) => {'schemaVersion': 1, 'realm': 'production', 'storeId': 'store-one',
    'operation': body['operation'], 'idempotencyKey': body['idempotencyKey'], 'locationVerified': false, 'publicAvailabilityConfirmed': false,
    'record': {'schemaVersion': 1, 'realm': 'production', 'storeId': 'store-one', 'revision': 1,
      'publishedAt': at.toIso8601String(), 'details': publicFields.toJson()}};
  const metadataIntent = WorkspacePublicDetailsIntent(ownerAccountId: 'host-owner', realm: 'production', storeId: 'store-one',
    expectedRevision: 0, idempotencyKey: 'original-details-one', details: publicFields);
  WorkspacePublicDetailsRecord receipt(WorkspacePublicDetailsIntent intent, {int? revision, String? store}) =>
    WorkspacePublicDetailsRecord(realm: intent.realm, storeId: store ?? intent.storeId,
      revision: revision ?? intent.expectedRevision + 1, publishedAt: at, details: intent.details);
  WorkspacePublicDetailsController publisher(PublicDetailsHostGateway gateway, PublicDetailsHostJournal journal,
    {Object? Function()? context}) => WorkspacePublicDetailsController(scope: metadataIntent.scope,
      gateway: gateway, journal: journal, context: context ?? () => 'host-lifetime', now: () => at);
  test('public publisher journals before dispatch and separates original receipt from current head', () async {
    final journal = PublicDetailsHostJournal(), authority = PublicDetailsHostGateway();
    final controller = publisher(authority, journal); addTearDown(controller.dispose);
    expect((await controller.publish(publicFields, inputCurrent: () => true)).state, WorkspacePublicDetailsWriteState.notSent);
    expect(authority.sent, isEmpty);
    expect(await controller.refresh(), isTrue);
    authority.outcome = WorkspacePublicDetailsWriteState.saved;
    final gate = Completer<void>(); journal.saveGate = gate;
    final send = controller.publish(publicFields, inputCurrent: () => true);
    await Future<void>.delayed(Duration.zero);
    expect(journal.events, ['journal']); expect(authority.sent, isEmpty);
    authority.acknowledgement = receipt(controller.pending!);
    gate.complete();
    expect((await send).state, WorkspacePublicDetailsWriteState.saved);
    expect(journal.original, isNull); expect(controller.pending, isNull);
    expect(controller.lastAcknowledged!.revision, 1); expect(controller.published, isNull);
    expect(controller.canPublish, isFalse);
    authority.head = receipt(metadataIntent, revision: 2);
    expect(await controller.refresh(), isTrue); expect(controller.published!.revision, 2);
    expect(controller.lastAcknowledged!.revision, 1);
  });
  test('public publisher restart and absent receipt allow only explicit identical-original retry', () async {
    final journal = PublicDetailsHostJournal(), authority = PublicDetailsHostGateway();
    final first = publisher(authority, journal); await first.refresh();
    await first.publish(publicFields, inputCurrent: () => true);
    final original = journal.original!; first.dispose();
    final next = publisher(authority, journal); addTearDown(next.dispose);
    expect(await next.restore(), isTrue); expect(authority.sent.length, 1);
    expect(await next.refresh(), isFalse); expect(next.canPublish, isFalse);
    authority.outcome = WorkspacePublicDetailsWriteState.notFound;
    expect((await next.reconcile()).state, WorkspacePublicDetailsWriteState.unknown);
    expect(next.canRetryOriginal, isTrue); expect(journal.original!.fingerprint, original.fingerprint);
    expect(authority.sent.last.reconcile, isTrue);
    authority.outcome = WorkspacePublicDetailsWriteState.saved; authority.acknowledgement = receipt(original);
    expect((await next.retryOriginal()).state, WorkspacePublicDetailsWriteState.saved);
    expect(authority.sent.last.reconcile, isFalse);
    expect(authority.sent.last.original.fingerprint, original.fingerprint);
    expect(next.pending, isNull);
  });
  for (final outcome in [WorkspacePublicDetailsWriteState.rejected, WorkspacePublicDetailsWriteState.notSent]) {
    test('public publisher original retry $outcome cannot clear earlier uncertainty', () async {
      final journal = PublicDetailsHostJournal()..original = metadataIntent;
      final authority = PublicDetailsHostGateway()..outcome = WorkspacePublicDetailsWriteState.notFound;
      final controller = publisher(authority, journal); addTearDown(controller.dispose);
      await controller.restore(); await controller.reconcile(); authority.outcome = outcome;
      expect((await controller.retryOriginal()).state, WorkspacePublicDetailsWriteState.unknown);
      expect(journal.original!.fingerprint, metadataIntent.fingerprint); expect(controller.canPublish, isFalse);
    });
  }
  test('public publisher failed journal save sends nothing and never forgets memory original', () async {
    final journal = PublicDetailsHostJournal(), authority = PublicDetailsHostGateway();
    final controller = publisher(authority, journal); addTearDown(controller.dispose);
    await controller.refresh(); journal.failSave = true;
    await controller.publish(publicFields, inputCurrent: () => true);
    final original = controller.pending!; expect(authority.sent, isEmpty); expect(journal.original, isNull);
    journal.failSave = false; expect(await controller.restore(), isTrue);
    expect(controller.pending!.fingerprint, original.fingerprint); expect(controller.canPublish, isFalse);
  });
  test('public publisher failed journal removal retains original for reconciliation', () async {
    final journal = PublicDetailsHostJournal()..original = metadataIntent;
    journal.failRemove = true;
    final authority = PublicDetailsHostGateway()..outcome = WorkspacePublicDetailsWriteState.saved
      ..acknowledgement = receipt(metadataIntent);
    final controller = publisher(authority, journal); addTearDown(controller.dispose);
    await controller.restore(); expect((await controller.reconcile()).state, WorkspacePublicDetailsWriteState.unknown);
    expect(controller.pending, isNotNull); expect(controller.lastAcknowledged, isNull);
    journal.failRemove = false;
    expect((await controller.reconcile()).state, WorkspacePublicDetailsWriteState.saved);
  });
  test('public publisher changed input while journaling cannot dispatch', () async {
    final journal = PublicDetailsHostJournal(), authority = PublicDetailsHostGateway();
    final controller = publisher(authority, journal); addTearDown(controller.dispose);
    await controller.refresh(); journal.saveGate = Completer<void>(); var current = true;
    final send = controller.publish(publicFields, inputCurrent: () => current);
    await Future<void>.delayed(Duration.zero); current = false; journal.saveGate!.complete();
    expect((await send).state, WorkspacePublicDetailsWriteState.unknown);
    expect(authority.sent, isEmpty); expect(journal.original, isNotNull);
  });
  test('public publisher retired A-B-A lifetime cannot consume a late receipt', () async {
    var lifetime = 1;
    final journal = PublicDetailsHostJournal(), authority = PublicDetailsHostGateway()..response = Completer();
    final first = publisher(authority, journal, context: () => lifetime); await first.refresh();
    final send = first.publish(publicFields, inputCurrent: () => true);
    while (authority.sent.isEmpty) { await Future<void>.delayed(Duration.zero); }
    lifetime = 3;
    authority.response!.complete(WorkspacePublicDetailsWriteResult(WorkspacePublicDetailsWriteState.saved,
      receipt(journal.original!)));
    expect((await send).state, WorkspacePublicDetailsWriteState.unknown); expect(journal.original, isNotNull);
    first.dispose();
    final next = publisher(authority, journal, context: () => lifetime); addTearDown(next.dispose);
    await next.restore(); expect(next.pending, isNotNull);
  });
  for (final wrong in ['Store', 'revision']) {
    test('public publisher wrong $wrong acknowledgement cannot clear original', () async {
      final journal = PublicDetailsHostJournal()..original = metadataIntent;
      final authority = PublicDetailsHostGateway()..outcome = WorkspacePublicDetailsWriteState.saved
        ..acknowledgement = receipt(metadataIntent, store: wrong == 'Store' ? 'other-store' : null,
          revision: wrong == 'revision' ? 3 : null);
      final controller = publisher(authority, journal); addTearDown(controller.dispose);
      await controller.restore(); expect((await controller.reconcile()).state, WorkspacePublicDetailsWriteState.unknown);
      expect(journal.original, isNotNull);
    });
  }
  test('public journal survives restart and isolates account Store realm and exact original', () async {
    TestWidgetsFlutterBinding.ensureInitialized(); FlutterSecureStorage.setMockInitialValues({});
    var account = metadataIntent.ownerAccountId;
    SecureWorkPublicDetailsJournal fresh() => SecureWorkPublicDetailsJournal(currentAccount: () => account);
    await fresh().savePending(metadataIntent);
    expect((await fresh().readPending(metadataIntent.scope))!.fingerprint, metadataIntent.fingerprint);
    final other = WorkspacePublicDetailsIntent.fromJson({...metadataIntent.toJson(), 'idempotencyKey': 'other-original'});
    await expectLater(fresh().savePending(other), throwsFormatException);
    await expectLater(fresh().removePending(other), throwsFormatException);
    expect(await fresh().readPending((account: account, store: 'other-store', realm: 'production')), isNull);
    expect(await fresh().readPending((account: account, store: 'store-one', realm: 'evaluation')), isNull);
    account = 'other-account'; await expectLater(fresh().readPending(metadataIntent.scope), throwsA(isA<WorkGatewayException>()));
    account = metadataIntent.ownerAccountId; await fresh().removePending(metadataIntent);
    expect(await fresh().readPending(metadataIntent.scope), isNull);
  });
  test('public journal storage tail survives caller timeout across instances', () async {
    final storage = _DelayedDetailsStorage();
    SecureWorkPublicDetailsJournal fresh() => SecureWorkPublicDetailsJournal(storage: storage,
      currentAccount: () => metadataIntent.ownerAccountId);
    final original = WorkspacePublicDetailsIntent.fromJson({...metadataIntent.toJson(), 'storeId': 'native-tail-store'});
    final first = fresh().savePending(original); await storage.entered.future;
    await expectLater(first.timeout(const Duration(milliseconds: 1)), throwsA(isA<TimeoutException>()));
    final remove = fresh().removePending(original);
    await Future<void>.delayed(Duration.zero); expect(storage.writes, 1);
    storage.release.complete(); await first; await remove;
    expect(storage.writes, 2); expect(await fresh().readPending(original.scope), isNull);
  });
  test('LF-METADATA whitelist excludes private settings and preserves explicit unknown hours', () {
    final input = WorkspacePublicDetailsFields.fromSettings(const WorkspaceStorePublicationDetails(
      street: 'Host market road', city: 'Jodhpur', state: 'Rajasthan', pinCode: '342003',
      publicContactPhone: '+91 90000 00001', legalName: 'Private legal name', pan: 'PRIVATE-PAN',
      billingAddress: 'Private billing address', signatory: 'Private signatory'));
    expect(input.toJson().keys.toSet(), {'street', 'city', 'state', 'pinCode', 'publicContactPhone', 'openingTime', 'closingTime'});
    expect(input.openingTime, isEmpty); expect(input.closingTime, isEmpty);
    for (final invalid in [
      {...publicFields.toJson(), 'regionId': 'invented'}, {...publicFields.toJson(), 'pinCode': '000000'},
      {...publicFields.toJson(), 'city': ''}, {...publicFields.toJson(), 'closingTime': ''},
      {...publicFields.toJson(), 'publicContactPhone': 'private-account-contact'},
    ]) { expect(() => WorkspacePublicDetailsFields.fromJson(invalid), throwsFormatException); }
  });
  test('LF-CLASS optional published business type preserves unknown legacy settings and exact journal input', () {
    final legacy = WorkspaceStorePublicationDetails.fromJson({});
    expect(legacy.businessType, 'retailer');
    expect(legacy.toJson().containsKey('businessType'), isFalse,
      reason: 'A dropdown fallback is not a supplied public fact');
    for (final type in ['', 'retailer', 'manufacturer', 'wholesaler', 'supplier']) {
      final fields = WorkspacePublicDetailsFields.fromJson({...publicFields.toJson(), 'businessType': type});
      expect(fields.toJson()['businessType'], type);
      final intent = WorkspacePublicDetailsIntent.fromJson({...metadataIntent.toJson(), 'details': fields.toJson()});
      expect(WorkspacePublicDetailsIntent.fromJson(intent.toJson()).fingerprint, intent.fingerprint);
    }
    expect(publicFields.toJson().containsKey('businessType'), isFalse);
    for (final value in [null, true, 1, {}, 'Manufacturer', ' manufacturer', 'delivery fleet']) {
      expect(() => WorkspacePublicDetailsFields.fromJson({...publicFields.toJson(), 'businessType': value}), throwsFormatException);
    }
  });
  Map<String, dynamic> classifiedPublicPage(String? type) {
    final data = publicPage()..['storeDetailsReadbackVersion'] = 1
      ..['storeClassificationReadbackVersion'] = 1;
    final details = metadata();
    if (type != null) (details['details'] as Map)['businessType'] = type;
    data['publicStore'] = <String, dynamic>{...(data['publicStore'] as Map), 'details': details};
    return data;
  }
  test('LF-CLASS reviewed public factory carries only published role without verification or private facts', () {
    for (final entry in {'manufacturer': 'Manufacturer', 'wholesaler': 'Wholesaler', 'supplier': 'Supplier', 'retailer': 'Retailer', '': ''}.entries) {
      final result = WorkspacePublicCatalogueEntry.fromResponse(classifiedPublicPage(entry.key),
        storeId: 'store-one', realm: 'production', channel: BuyV2OfferClass.retail, now: at);
      expect(result.product.sellerType, entry.value);
      expect(result.product.manufacturerVerified, isFalse);
    }
    expect(WorkspacePublicCatalogueEntry.fromResponse(classifiedPublicPage(null),
      storeId: 'store-one', realm: 'production', channel: BuyV2OfferClass.retail, now: at).product.sellerType, isEmpty);
  });
  test('LF-CLASS factory rejects unnegotiated malformed and wrong-Store classified metadata', () {
    for (final fault in ['missing marker', 'boolean marker', 'wrong Store', 'invalid role']) {
      final data = classifiedPublicPage('manufacturer');
      if (fault == 'missing marker') data.remove('storeClassificationReadbackVersion');
      if (fault == 'boolean marker') data['storeClassificationReadbackVersion'] = true;
      final details = (data['publicStore'] as Map)['details'] as Map;
      if (fault == 'wrong Store') details['storeId'] = 'other-store';
      if (fault == 'invalid role') (details['details'] as Map)['businessType'] = 'delivery operator';
      expect(() => WorkspacePublicCatalogueEntry.fromResponse(data,
        storeId: 'store-one', realm: 'production', channel: BuyV2OfferClass.retail, now: at), throwsFormatException, reason: fault);
    }
  });
  AuthenticatedWorkspaceCatalogueGateway classifiedGateway(OwnerTransport transport, {bool enabled = true, Credentials? credentials}) =>
    AuthenticatedWorkspaceCatalogueGateway(endpoint: Uri.parse('https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
      credentials: credentials ?? Credentials(), transport: transport, storeClassificationReadbackSupported: enabled, now: () => at);
  test('LF-CLASS saved settings distinguish explicit published type from legacy dropdown fallback', () {
    final raw = WorkspaceStorePublicationDetails.fromJson(publicFields.toJson());
    expect(WorkspacePublicDetailsFields.fromSettings(raw, includeBusinessType: true).businessType, isNull);
    for (final type in ['', 'retailer', 'manufacturer', 'wholesaler', 'supplier']) {
      final saved = WorkspaceStorePublicationDetails.fromJson({...raw.toJson(), 'businessType': type});
      expect(saved.businessTypeSupplied, isTrue);
      expect(WorkspacePublicDetailsFields.fromSettings(saved).toJson(), publicFields.toJson());
      expect(WorkspacePublicDetailsFields.fromSettings(saved, includeBusinessType: true).businessType, type);
    }
  });
  test('LF-CLASS owner capability clones, journals and original reconciliation keep exact descriptive field', () async {
    final input = WorkspacePublicDetailsFields.fromJson({...publicFields.toJson(), 'businessType': 'manufacturer'});
    final original = WorkspacePublicDetailsIntent.fromJson({...metadataIntent.toJson(), 'details': input.toJson()});
    final before = original.fingerprint, credentials = Credentials();
    final transport = OwnerTransport((body) async {
      expect(body['storeClassificationReadbackVersion'], 1);
      final data = ownerDetailsReply(body)..['storeClassificationReadbackVersion'] = 1;
      (data['record'] as Map)['details'] = input.toJson();
      return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': data}));
    });
    final owner = classifiedGateway(transport, credentials: credentials).forOwnerAccount('host-owner');
    expect(owner.storeClassificationReadbackSupported, isTrue);
    expect((await owner.writePublicDetails(original, current: () => true)).state, WorkspacePublicDetailsWriteState.saved);
    expect((await owner.readPublicDetailsOwned(storeId: 'store-one', current: () => true))!.details.businessType, 'manufacturer');
    final legacy = classifiedGateway(transport, enabled: false, credentials: credentials).forOwnerAccount('host-owner');
    expect((await legacy.writePublicDetails(original, current: () => true)).state, WorkspacePublicDetailsWriteState.notSent);
    expect((await legacy.writePublicDetails(original, current: () => true, reconcile: true)).state, WorkspacePublicDetailsWriteState.saved);
    expect(credentials.modes, [SocialAppCheckTokenMode.limitedUse, SocialAppCheckTokenMode.standard, SocialAppCheckTokenMode.standard]);
    expect(original.fingerprint, before); expect(original.toJson().containsKey('storeClassificationReadbackVersion'), isFalse);
    TestWidgetsFlutterBinding.ensureInitialized(); FlutterSecureStorage.setMockInitialValues({});
    SecureWorkPublicDetailsJournal journal() => SecureWorkPublicDetailsJournal(currentAccount: () => 'host-owner');
    await journal().savePending(original);
    expect((await journal().readPending(original.scope))!.fingerprint, before);
    await journal().removePending(original);
  });
  test('LF-CLASS direct and refreshed products cannot silently reuse changed public type', () async {
    var role = 'manufacturer';
    final transport = OwnerTransport((body) async {
      expect(body['storeClassificationReadbackVersion'], 1); expect(body['storeDetailsReadbackVersion'], 1);
      return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': classifiedPublicPage(role)}));
    });
    final gateway = classifiedGateway(transport);
    final entry = (await gateway.readPublicEntry(storeId: 'store-one', skuId: 'sku-one', channel: BuyV2OfferClass.retail, current: () => true))!;
    expect(entry.product.sellerType, 'Manufacturer'); expect(entry.product.manufacturerVerified, isFalse);
    expect((await gateway.read(entry.product)).content.state, BuyV2ProductContentState.ready);
    role = 'wholesaler';
    expect((await gateway.read(entry.product)).content.state, BuyV2ProductContentState.unavailable);
    final next = (await gateway.readPublicEntry(storeId: 'store-one', skuId: 'sku-one', channel: BuyV2OfferClass.retail, current: () => true))!;
    expect(next.product.sellerType, 'Wholesaler');
  });
  test('LF-CLASS real Store page maps same metadata and rejects retired revision', () async {
    var revision = 2, role = 'manufacturer';
    final source = WorkspaceStoreCatalogueSource(storeId: 'store-one', current: () => true,
      gateway: classifiedGateway(OwnerTransport((body) async {
        expect(body['storeClassificationReadbackVersion'], 1);
        final data = pageData(body)..['storeDetailsReadbackVersion'] = 1..['storeClassificationReadbackVersion'] = 1;
        final info = metadata(revision: revision);
        (info['details'] as Map)['businessType'] = role;
        (data['publicStore'] as Map)['details'] = info;
        return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': data}));
      })));
    expect((await source.loadProducts(storeQuery(), pageSize: 40)).items.single.sellerType, 'Manufacturer');
    revision = 3; role = 'supplier';
    expect((await source.loadProducts(storeQuery(), pageSize: 40)).items.single.sellerType, 'Supplier');
    revision = 2; await expectLater(source.loadProducts(storeQuery(), pageSize: 40), throwsFormatException);
  });
  test('LF-CLASS real HTTP family preserves published metadata and rejects changed selected role', () async {
    var role = 'manufacturer';
    final fallback = familyTransport();
    final transport = OwnerTransport((body) async {
      expect(body['storeClassificationReadbackVersion'], 1);
      final data = body['operation'] == 'readPublicStoreVariantFamilies'
        ? (httpReviewedFamily(body)..['storeClassificationReadbackVersion'] = 1..['storeDetailsReadbackVersion'] = 1)
        : body.containsKey('cataloguePageVersion')
          ? (jsonDecode((await fallback.postJson(Uri.parse('https://example.com'), headers: {}, body: body)).body) as Map)['data'] as Map<String, dynamic>
          : classifiedPublicPage(role);
      data['storeClassificationReadbackVersion'] = 1; data['storeDetailsReadbackVersion'] = 1;
      data['publicStore'] = classifiedPublicPage(role)['publicStore'];
      return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': data}));
    });
    final gateway = AuthenticatedWorkspaceCatalogueGateway(endpoint: Uri.parse(
      'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
      credentials: Credentials(), transport: transport, now: () => at,
      reviewedFamilyReadbackSupported: true, storeClassificationReadbackSupported: true);
    final entry = (await gateway.readPublicEntry(storeId: 'store-one', skuId: 'sku-one', channel: BuyV2OfferClass.retail, current: () => true))!;
    final source = WorkspaceStoreCatalogueSource(storeId: 'store-one', current: () => true, gateway: gateway);
    final query = BuyV2CatalogueQuery(destination: BuyV2Destination.shop, regionId: null, storeId: 'store-one');
    final family = await source.loadVariantFamily(entry.product, query);
    expect(family.candidates.map((p) => p.sellerType).toSet(), {'Manufacturer'});
    expect(family.candidates.every((p) => !p.manufacturerVerified), isTrue);
    role = 'supplier'; await expectLater(source.loadVariantFamily(entry.product, query), throwsFormatException);
  });
  test('LF-CLASS Store promotion reader resolves descriptive role without granting publisher authority', () async {
    final source = WorkspaceStoreCatalogueSource(storeId: 'store-one', current: () => true,
      gateway: classifiedGateway(OwnerTransport((body) async {
        final data = body['operation'] == 'readPublicStorePromotions'
          ? promotionPage([promotionRow()]) : classifiedPublicPage('supplier');
        if (body['operation'] != 'readPublicStorePromotions') expect(body['storeClassificationReadbackVersion'], 1);
        return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': data}));
      })));
    final offers = await source.loadStoreOffers(storeId: 'store-one', destination: BuyV2Destination.shop);
    expect(offers.single.product.sellerType, 'Supplier'); expect(offers.single.product.manufacturerVerified, isFalse);
    expect(offers.single.publisherType, BuyV2OfferPublisherType.retailer);
  });
  for (final scale in [1.0, 2.0]) {
    testWidgets('LF-CLASS Store channel edits preserve unknown type and explicit hide at $scale', (tester) async {
      tester.view.devicePixelRatio = 1; tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.reset);
      final work = WorkSession(gateway: ReviewWorkGateway())..activeWorkspace = const WorkWorkspace(
        id: 'class-host-store', name: 'Host Store', profileLabel: 'Grocery', profileId: 'retailer-grocery', area: 'Jodhpur', verified: true);
      addTearDown(work.dispose);
      await tester.pumpWidget(MaterialApp(theme: MoolTheme.light(), builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
        home: Scaffold(body: SingleChildScrollView(child: StorePublicationSettings(session: work)))));
      await tester.pumpAndSettle();
      expect(work.workspacePublicationDetails.businessTypeSupplied, isFalse);
      for (final key in ['work-publication-channel-retail', 'work-publication-channel-wholesale']) {
        final checkbox = find.byKey(Key(key)); await tester.ensureVisible(checkbox); await tester.tap(checkbox); await tester.pumpAndSettle();
        expect(work.workspacePublicationDetails.businessTypeSupplied, isFalse);
        expect(WorkspaceStorePublicationDetails.fromJson(work.workspacePublicationDetails.toJson()).businessTypeSupplied, isFalse);
      }
      final type = find.byKey(const Key('work-publication-business-type'));
      await tester.ensureVisible(type); await tester.tap(type); await tester.pumpAndSettle();
      await tester.tap(find.text('Not shown publicly').last); await tester.pumpAndSettle();
      expect(work.workspacePublicationDetails.businessTypeSupplied, isTrue);
      expect(WorkspacePublicDetailsFields.fromSettings(WorkspaceStorePublicationDetails.fromJson({
        ...publicFields.toJson(), ...work.workspacePublicationDetails.toJson(),
        'street': publicFields.street, 'city': publicFields.city, 'state': publicFields.state, 'pinCode': publicFields.pinCode,
      }), includeBusinessType: true).businessType, isEmpty);
      expect(tester.takeException(), isNull);
    });
    testWidgets('LF-CLASS published Supplier is visible as informational supplier at $scale', (tester) async {
      final selected = WorkspacePublicCatalogueEntry.fromResponse(classifiedPublicPage('supplier'),
        storeId: 'store-one', realm: 'production', channel: BuyV2OfferClass.retail, now: at).product;
      final session = await optionalDetailsSession(selected, _HostOptionalProductContent());
      await mountOptionalDetails(tester, session, scale);
      final label = find.text('Store · Supplier');
      await revealOptionalDetails(tester, selected, label);
      expect(label, findsOneWidget); expect(selected.manufacturerVerified, isFalse);
      expect(tester.takeException(), isNull);
    });
    testWidgets('LF-CLASS explicitly hidden type omits empty public classification at $scale', (tester) async {
      final selected = WorkspacePublicCatalogueEntry.fromResponse(classifiedPublicPage(''),
        storeId: 'store-one', realm: 'production', channel: BuyV2OfferClass.retail, now: at).product;
      final session = await optionalDetailsSession(selected, _HostOptionalProductContent());
      await mountOptionalDetails(tester, session, scale);
      await revealOptionalDetails(tester, selected, find.text('Store'));
      expect(find.text('Store · Seller'), findsNothing); expect(find.text('Store · '), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  test('LF-METADATA owner transport correlates original payload and uses mutation-only limited AppCheck', () async {
    final credentials = Credentials(), transport = OwnerTransport((body) async => SocialContentResponse(statusCode: 200,
      body: jsonEncode({'ok': true, 'data': ownerDetailsReply(body)})));
    final owner = AuthenticatedWorkspaceCatalogueGateway(endpoint: Uri.parse(
      'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
      credentials: credentials, transport: transport, ownerAccountId: 'host-owner', now: () => at);
    final saved = await owner.writePublicDetails(metadataIntent, current: () => true);
    expect(saved.state, WorkspacePublicDetailsWriteState.saved); expect(saved.record!.details.address, publicFields.address);
    final original = await owner.writePublicDetails(metadataIntent, current: () => true, reconcile: true);
    expect(original.state, WorkspacePublicDetailsWriteState.saved);
    final read = await owner.readPublicDetailsOwned(storeId: 'store-one', current: () => true);
    expect(read!.revision, 1);
    expect(credentials.modes, [SocialAppCheckTokenMode.limitedUse, SocialAppCheckTokenMode.standard, SocialAppCheckTokenMode.standard]);
  });
  for (final change in ['realm', 'store', 'revision', 'key', 'operation', 'details', 'verified']) {
    test('LF-METADATA mismatched owner response remains unknown: $change', () async {
      final transport = OwnerTransport((body) async {
        final data = jsonDecode(jsonEncode(ownerDetailsReply(body))) as Map<String, dynamic>;
        if (change == 'realm') data['realm'] = 'evaluation';
        if (change == 'store') data['storeId'] = 'other-store';
        if (change == 'revision') (data['record'] as Map)['revision'] = 2;
        if (change == 'key') data['idempotencyKey'] = 'other-original';
        if (change == 'operation') data['operation'] = 'readStorePublicDetails';
        if (change == 'details') ((data['record'] as Map)['details'] as Map)['city'] = 'Changed city';
        if (change == 'verified') data['locationVerified'] = true;
        return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': data}));
      });
      final owner = pageGateway(transport).forOwnerAccount('host-owner');
      expect((await owner.writePublicDetails(metadataIntent, current: () => true)).state, WorkspacePublicDetailsWriteState.unknown);
    });
  }
  test('LF-METADATA missing original denial and retired credential lifetime cannot publish', () async {
    final transport = OwnerTransport((body) async => SocialContentResponse(statusCode: 200,
      body: jsonEncode({'ok': true, 'data': ownerDetailsReply(body)..['record'] = null})));
    final owner = pageGateway(transport).forOwnerAccount('host-owner');
    expect((await owner.writePublicDetails(metadataIntent, current: () => true, reconcile: true)).state,
      WorkspacePublicDetailsWriteState.notFound);
    var current = true;
    final retired = AuthenticatedWorkspaceCatalogueGateway(endpoint: owner.endpoint, ownerAccountId: 'host-owner',
      credentials: RetiringOwnerCredentials(() => current = false), transport: transport, now: () => at);
    final count = transport.calls;
    expect((await retired.writePublicDetails(metadataIntent, current: () => current)).state, WorkspacePublicDetailsWriteState.notSent);
    expect(transport.calls, count);
    final denied = pageGateway(OwnerTransport((body) async => SocialContentResponse(statusCode: 403,
      body: jsonEncode({'ok': false, 'error': {'code': 'forbidden', 'message': 'Not permitted.', 'retryable': false}}))))
      .forOwnerAccount('host-owner');
    expect((await denied.writePublicDetails(metadataIntent, current: () => true)).state, WorkspacePublicDetailsWriteState.rejected);
    expect((await denied.writePublicDetails(metadataIntent, current: () => true, reconcile: true)).state, WorkspacePublicDetailsWriteState.unknown);
  });
  test('LF-METADATA a late accepted write cannot become another account success', () async {
    var current = true;
    final sent = Completer<Map<String, Object?>>(), response = Completer<SocialContentResponse>();
    final owner = pageGateway(OwnerTransport((body) { sent.complete(body); return response.future; })).forOwnerAccount('host-owner');
    final result = owner.writePublicDetails(metadataIntent, current: () => current), body = await sent.future;
    current = false;
    response.complete(SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': ownerDetailsReply(body)})));
    expect((await result).state, WorkspacePublicDetailsWriteState.unknown);
  });
  test('LF-METADATA malformed rejection cannot prove the original write was not applied', () async {
    for (final body in ['<html>proxy failure</html>', '{}',
      jsonEncode({'ok': false, 'error': {'code': 'conflict', 'message': 'Original request changed.', 'retryable': false}})]) {
      final owner = pageGateway(OwnerTransport((request) async => SocialContentResponse(statusCode: 409, body: body)))
        .forOwnerAccount('host-owner');
      expect((await owner.writePublicDetails(metadataIntent, current: () => true)).state,
        WorkspacePublicDetailsWriteState.unknown);
    }
  });
  test('LF-METADATA only a valid revision-conflict envelope confirms a rejected new write', () async {
    final owner = pageGateway(OwnerTransport((request) async => SocialContentResponse(statusCode: 409,
      body: jsonEncode({'ok': false, 'error': {'code': 'revision_conflict', 'message': 'Refresh public details.', 'retryable': false}}))))
      .forOwnerAccount('host-owner');
    expect((await owner.writePublicDetails(metadataIntent, current: () => true)).state, WorkspacePublicDetailsWriteState.rejected);
  });
  test('LF-METADATA exact-Store header uses owner public data without inventing a region or collection grant', () async {
    final source = WorkspaceStoreCatalogueSource(storeId: 'store-one', current: () => true,
      gateway: pageGateway(OwnerTransport((body) async {
        final data = pageData(body)..['storeDetailsReadbackVersion'] = 1;
        (data['publicStore'] as Map)['details'] = metadata();
        return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': data}));
      })));
    final core = BuySession();
    final consumer = BuyV2Session(core: core, cataloguePageSource: source, reviewDataEnabled: false);
    addTearDown(core.dispose); addTearDown(consumer.dispose);
    final pager = consumer.acquireCatalogueStores('host-described-store');
    await pager.open(storeQuery());
    expect(pager.message, isNull); final store = pager.page!.items.single;
    expect(store.id, 'store-one'); expect(store.address, publicFields.address); expect(store.regionId, isEmpty);
    expect(store.publicContactPhone, publicFields.publicContactPhone); expect(store.openingHoursLabel, '09:00 – 21:00');
    expect(store.collection, isNull); expect(store.distanceMeters, isNull);
    consumer.releaseCatalogueStores('host-described-store');
  });
  test('LF-METADATA stale absent and wrong-Store empty catalogue headers are not confirmed empty feeds', () async {
    var revision = 2, wrongStore = false;
    final source = WorkspaceStoreCatalogueSource(storeId: 'store-one', current: () => true,
      gateway: pageGateway(OwnerTransport((body) async {
        final data = pageData(body, empty: true)..['storeDetailsReadbackVersion'] = 1;
        final store = data['publicStore'] as Map;
        store['details'] = metadata(revision: revision);
        if (wrongStore) store['id'] = 'other-store';
        return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': data}));
      })));
    expect((await source.loadStores(storeQuery(), pageSize: 40)).items.single.address, publicFields.address);
    revision = 1; await expectLater(source.loadStores(storeQuery(), pageSize: 40), throwsFormatException);
    revision = 3; wrongStore = true; await expectLater(source.loadStores(storeQuery(), pageSize: 40), throwsFormatException);
  });
  test('LF-LISTING source readback uses original SKU and keeps actual media and policy scopes', () async {
    final data = publicPage();
    (row(data)['content'] as Map)['media'] = [<String, Object?>{
      'id': 'host-image', 'revision': 'image-one', 'url': 'https://example.com/host-image.jpg',
      'storeId': 'store-one', 'skuId': 'sku-one', 'canonicalProductId': 'canonical-one',
      'publisherWorkspaceId': 'supplier-one', 'file': {'mimeType': 'image/jpeg', 'byteLength': 1024,
        'width': 640, 'height': 640, 'normalized': true, 'frameCount': 1}}];
    final transport = Transport(data), selected = publicProduct();
    final result = await gateway(transport).read(selected);
    expect(result.content.state, BuyV2ProductContentState.ready);
    expect(transport.sent!['skuId'], 'sku-one'); expect(transport.sent!['listingReadbackVersion'], 1);
    expect(transport.sent!['policyReadbackVersion'], 1);
    expect(result.content.productId, selected.id);
    expect(result.content.media.single.binding!.skuId, 'sku-one');
    expect(BuyV2SupplierMediaPolicy.publicationMessage(selected, result.content.media.single), isNull);
    final policy = result.content.supplierPolicy!;
    expect(policy.productIds, {'sku-one'}); expect(policy.sourceRealm, 'production');
    expect(policy.appliesTo(selected, at), isTrue);
    expect(policy.receiptKey, jsonEncode(['production', 'store-one', 'host-supplier-policy-sku-one']));
  });
  for (final change in ['missing', 'store', 'sku', 'channel', 'pack', 'realm', 'listing', 'partial', 'media', 'policy', 'duplicate channel']) {
    test('LF-LISTING wrong public binding cannot be admitted $change', () async {
      final data = publicPage(trade: change == 'duplicate channel'), selected = publicProduct();
      final bindings = row(data)['listings'] as List;
      final original = Map<String, Object?>.from(bindings.first as Map);
      if (change == 'missing') row(data).remove('listings');
      if (change == 'store') bindings[0] = {...original, 'storeId': 'other-store'};
      if (change == 'sku') bindings[0] = {...original, 'skuId': 'other-sku'};
      if (change == 'channel') bindings[0] = {...original, 'channel': 'bulk'};
      if (change == 'pack') bindings[0] = {...original, 'verifiedPackId': 'other-pack'};
      if (change == 'realm') bindings[0] = {...original, 'realm': 'evaluation'};
      if (change == 'listing') bindings[0] = {...original, 'listingId': 'listing-${'c' * 64}'};
      if (change == 'partial') data['listingCoverage'] = 'partial';
      if (change == 'media') {
        (row(data)['content'] as Map)['media'] = [<String, Object?>{'id': 'wrong', 'skuId': selected.id}];
      }
      if (change == 'policy') (row(data)['supplierPolicy'] as Map)['skuId'] = selected.id;
      if (change == 'duplicate channel') bindings[1] = {...original, 'listingId': 'listing-${'c' * 64}'};
      expect((await gateway(Transport(data)).read(selected)).content.state, BuyV2ProductContentState.unavailable);
    });
  }
  test('LF-LISTING same source policy spans channels without rewriting applicability or legacy consent', () async {
    final data = publicPage(trade: true), transport = Transport(data);
    final source = gateway(transport), retail = publicProduct(), trade = publicProduct(trade: true);
    final a = (await source.read(retail)).content.supplierPolicy!;
    final b = (await source.read(trade)).content.supplierPolicy!;
    expect(retail.id, isNot(trade.id)); expect(retail.sourceSkuId, trade.sourceSkuId);
    expect(a.receiptKey, b.receiptKey);
    expect(a.acceptanceFingerprint('host-owner'), b.acceptanceFingerprint('host-owner'));
    final legacy = (await gateway(Transport(page()..['items'] = [row(page())..['supplierPolicy'] = policyEnvelope()])).read(product))
      .content.supplierPolicy!;
    expect(a.receiptKey, isNot(legacy.receiptKey));
    expect(a.acceptanceFingerprint('host-owner'), isNot(legacy.acceptanceFingerprint('host-owner')));
    expect(a.appliesTo(product, at), isFalse); expect(legacy.appliesTo(retail, at), isFalse);
  });
  test('LF-LISTING absent frame proof remains unknown and malformed static proof is rejected', () async {
    final data = publicPage();
    final file = <String, Object?>{'mimeType': 'image/jpeg', 'byteLength': 1024,
      'width': 640, 'height': 640, 'normalized': true};
    (row(data)['content'] as Map)['media'] = [<String, Object?>{
      'id': 'host-image', 'revision': 'image-one', 'url': 'https://example.com/host-image.jpg',
      'storeId': 'store-one', 'skuId': 'sku-one', 'canonicalProductId': 'canonical-one',
      'publisherWorkspaceId': 'supplier-one', 'file': file}];
    final transport = Transport(data), selected = publicProduct();
    final unknown = await gateway(transport).read(selected);
    expect(unknown.content.media.single.binding!.file.frameCount, isNull);
    expect(BuyV2SupplierMediaPolicy.publicationMessage(selected, unknown.content.media.single), isNotNull);
    for (final invalid in [null, 0, 2, 1.5, '1']) {
      file['frameCount'] = invalid;
      expect((await gateway(transport).read(selected)).content.state, BuyV2ProductContentState.unavailable);
    }
    file['frameCount'] = 1;
    final checked = await gateway(transport).read(selected);
    expect(checked.content.media.single.binding!.file.frameCount, 1);
    expect(BuyV2SupplierMediaPolicy.publicationMessage(selected, checked.content.media.single), isNull);
    data.remove('mediaReadbackVersion');
    expect((await gateway(transport).read(selected)).content.state, BuyV2ProductContentState.unavailable);
  });
  test('LF-LISTING source policy highwater protects both listing channels', () async {
    final data = publicPage(trade: true), transport = Transport(data);
    final reader = WorkspaceCatalogueReadback(gateway: gateway(transport), context: () => 'host-owner', now: () => at);
    addTearDown(reader.dispose);
    final retail = publicProduct(), trade = publicProduct(trade: true);
    await reader.refresh(retail);
    row(data)['supplierPolicy'] = policyEnvelope(revision: 2);
    await reader.refresh(trade);
    expect(reader.snapshotFor(trade).supplierPolicy!.revision, 'policy-v2');
    row(data)['supplierPolicy'] = policyEnvelope(revision: 1, state: 'none');
    await reader.refresh(retail);
    expect(reader.snapshotFor(retail).supplierPolicyResolutionPending, isTrue);
  });
  test('LF-LISTING bound cache preserves required policy hold before and after first failed read', () async {
    final data = publicPage(), transport = Transport(data)..fail = true;
    final reader = WorkspaceCatalogueReadback(gateway: gateway(transport), context: () => 'host-owner', now: () => at);
    addTearDown(reader.dispose);
    final selected = publicProduct();
    expect(reader.snapshotFor(selected).supplierPolicyResolutionPending, isTrue);
    await reader.refresh(selected);
    expect(reader.snapshotFor(selected).supplierPolicyResolutionPending, isTrue);
    transport.fail = false; row(data).remove('supplierPolicy');
    await reader.refresh(selected);
    expect(reader.snapshotFor(selected).supplierPolicyResolutionPending, isTrue);
    expect(reader.snapshotFor(product).supplierPolicyResolutionPending, isFalse,
      reason: 'Legacy unbound behavior is unchanged when no actual policy was observed.');
  });
  test(
    'catalogue policy readback reaches accepted policy shape and keeps expired resolution separate',
    () async {
      final data = page();
      row(data)['supplierPolicy'] = policyEnvelope();
      final source = gateway(Transport(data));
      final result = await source.read(product);
      expect(result.content.state, BuyV2ProductContentState.ready);
      expect(result.content.supplierPolicy?.body, 'Host supplier terms');
      expect(result.content.supplierPolicyAcceptanceRequired, true);
      expect(result.content.supplierPolicyResolutionPending, false);
      row(data)['supplierPolicy'] = policyEnvelope(
        revision: 2,
        state: 'unavailable',
      );
      final held = (await source.read(product)).content;
      expect(held.supplierPolicy, isNull);
      expect(held.supplierPolicyResolutionPending, true);
      expect(held.supplierPolicyAcceptanceRequired, true);
    },
  );
  test(
    'configured policy protocol holds the initial lookup and never falls back to a legacy response',
    () async {
      final data = page(),
          transport = Transport(data),
          legacy = gateway(transport);
      final source = AuthenticatedWorkspaceCatalogueGateway(
        endpoint: legacy.endpoint,
        credentials: legacy.credentials,
        transport: transport,
        now: () => at,
        policyReadbackRequired: true,
      );
      final reader = WorkspaceCatalogueReadback(
        gateway: source,
        context: () => 'owner',
        now: () => at,
      );
      addTearDown(reader.dispose);
      expect(reader.snapshotFor(product).supplierPolicyResolutionPending, true);
      await reader.refresh(product);
      expect(reader.snapshotFor(product).supplierPolicyResolutionPending, true);
      expect(transport.sent!['policyReadbackVersion'], 1);
      row(data)['supplierPolicy'] = policyEnvelope(revision: 0, state: 'none');
      await reader.refresh(product);
      expect(
        reader.snapshotFor(product).supplierPolicyResolutionPending,
        false,
      );
      expect(
        reader.snapshotFor(product).supplierPolicyAcceptanceRequired,
        false,
      );
      transport.fail = true;
      await reader.refresh(product);
      expect(reader.snapshotFor(product).supplierPolicyResolutionPending, true);
    },
  );
  for (final name in [
    'foreign Store',
    'foreign realm',
    'foreign SKU',
    'private field',
    'wrong policy scope',
    'conflicting requirement',
  ]) {
    test('unsafe policy $name cannot become a ready public policy', () async {
      final data = page(), value = policyEnvelope();
      switch (name) {
        case 'foreign Store':
          value['storeId'] = 'store-two';
        case 'foreign realm':
          value['realm'] = 'evaluation';
        case 'foreign SKU':
          value['skuId'] = 'sku-two';
        case 'private field':
          value['ownerUserId'] = 'private-owner';
        case 'wrong policy scope':
          (value['policy'] as Map)['productIds'] = ['sku-two'];
        case 'conflicting requirement':
          (value['policy'] as Map)['requiresAcceptance'] = false;
      }
      row(data)['supplierPolicy'] = value;
      final held = (await gateway(Transport(data)).read(product)).content;
      expect(held.supplierPolicy, isNull);
      expect(held.supplierPolicyResolutionPending, true);
    });
  }
  test(
    'policy revision changes independently from SKU; stale none and same-version changes stay held',
    () async {
      final data = page();
      row(data)['supplierPolicy'] = policyEnvelope();
      final reader = WorkspaceCatalogueReadback(
        gateway: gateway(Transport(data)),
        context: () => 'owner',
        now: () => at,
      );
      addTearDown(reader.dispose);
      await reader.refresh(product);
      expect(reader.snapshotFor(product).supplierPolicy?.revision, 'policy-v1');
      row(data)['supplierPolicy'] = policyEnvelope(
        revision: 2,
        body: 'Updated host terms',
      );
      await reader.refresh(product);
      expect(reader.snapshotFor(product).supplierPolicy?.revision, 'policy-v2');
      row(data)['supplierPolicy'] = policyEnvelope(revision: 1, state: 'none');
      await reader.refresh(product);
      expect(reader.snapshotFor(product).supplierPolicyResolutionPending, true);
      row(data)['supplierPolicy'] = policyEnvelope(
        revision: 2,
        body: 'Changed without revision',
      );
      await reader.refresh(product);
      expect(reader.snapshotFor(product).supplierPolicyResolutionPending, true);
      row(data)['supplierPolicy'] = policyEnvelope(
        revision: 3,
        state: 'unavailable',
      );
      await reader.refresh(product);
      expect(reader.snapshotFor(product).supplierPolicyResolutionPending, true);
      row(data)['supplierPolicy'] = policyEnvelope(
        revision: 2,
        body: 'Updated host terms',
      );
      await reader.refresh(product);
      expect(reader.snapshotFor(product).supplierPolicyResolutionPending, true);
    },
  );
  test(
    'same SKU policy revision is shared across Retail and Wholesale cached views',
    () async {
      final data = jsonDecode(jsonEncode(page())) as Map<String, dynamic>;
      final channels = row(data)['channels'] as List;
      channels.add({
        ...channels.single as Map,
        'kind': 'wholesale',
        'offerId': 'host-wholesale-offer',
      });
      row(data)['supplierPolicy'] = policyEnvelope();
      final reader = WorkspaceCatalogueReadback(
        gateway: gateway(Transport(data)),
        context: () => 'owner',
        now: () => at,
      );
      addTearDown(reader.dispose);
      await reader.refresh(product);
      expect(reader.snapshotFor(product).supplierPolicy?.revision, 'policy-v1');
      row(data)['supplierPolicy'] = policyEnvelope(
        revision: 2,
        body: 'Updated across both channels',
      );
      final wholesale = product.copyWith(offerClass: BuyV2OfferClass.wholesale);
      await reader.refresh(wholesale);
      expect(
        reader.snapshotFor(wholesale).supplierPolicy?.revision,
        'policy-v2',
      );
      expect(reader.snapshotFor(product).supplierPolicyResolutionPending, true);
      row(data)['supplierPolicy'] = policyEnvelope(revision: 1, state: 'none');
      await reader.refresh(product);
      expect(reader.snapshotFor(product).supplierPolicyResolutionPending, true);
    },
  );
  testWidgets(
    'reachable product editor saves an explicit listing request without a Stock movement',
    (tester) async {
      final source = SessionCatalogue(), journal = BindingStore();
      final work = listingSession(source, journal);
      source.write = (intent, current) async {
        expect(current(), true);
        expect(journal.saved?.idempotencyKey, intent.idempotencyKey);
        return listingSaved(intent);
      };
      await openListingEditor(tester, work);
      final row = find.byKey(const Key('work-product-public'));
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: row, matching: find.byType(Switch)));
      await tester.pumpAndSettle();
      final save = find.byKey(const Key('work-product-save'));
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(
        source.submitted,
        1,
        reason:
            'Owner reads=${source.ownerReads}; notice=${work.noticeMessage}; error=${work.errorMessage}; visible=${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).whereType<String>().join(" | ")}',
      );
      expect(work.workspaceCatalogueItems.single.publicListing, true);
      expect(work.workspaceCatalogueItems.single.stock, 7);
      expect(
        work.workspaceCatalogueItems.single.catalogueFactsRequireReview,
        true,
      );
      expect(work.workspaceOrders, isEmpty);
      expect(work.workspaceInvoices, isEmpty);
      expect(journal.saved, isNull);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'reopened product editor restores pending original before enabling listing changes',
    (tester) async {
      final source = SessionCatalogue(),
          journal = BindingStore(),
          restore = Completer<WorkspaceCatalogueBindingIntent?>();
      final original = ownerIntent();
      journal.saved = original;
      journal.read = () => restore.future;
      final work = listingSession(source, journal);
      await openListingEditor(tester, work);
      final row = find.byKey(const Key('work-product-public'));
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Switch>(
              find.descendant(of: row, matching: find.byType(Switch)),
            )
            .onChanged,
        isNull,
      );
      restore.complete(original);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-product-public-check')),
        findsOneWidget,
      );
      expect(source.submitted, 0);
      expect(source.reconciled, 0);
      expect(work.workspaceCatalogueItems.single.publicListing, false);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'retained Check listing callback never creates a new request after original cleared',
    (tester) async {
      final source = SessionCatalogue(),
          journal = BindingStore()..saved = ownerIntent();
      final work = listingSession(source, journal);
      // Prepare the old state without a provider submission; then clear it elsewhere.
      await work.requestWorkspaceProductListing('sku-one', listed: false);
      await openListingEditor(tester, work);
      final row = find.byKey(const Key('work-product-public-check'));
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      final callback = tester
          .widget<IconButton>(
            find.descendant(of: row, matching: find.byType(IconButton)),
          )
          .onPressed!;
      source.check = (original) async => listingSaved(original);
      expect(
        await work.requestWorkspaceProductListing('sku-one', listed: false),
        true,
      );
      expect(journal.saved, isNull);
      callback();
      await tester.pumpAndSettle();
      expect(source.submitted, 0);
      expect(work.workspaceCatalogueItems.single.publicListing, false);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'failed listing restoration stays read-only and can be retried without submission',
    (tester) async {
      final source = SessionCatalogue(), journal = BindingStore();
      journal.read = () async =>
          throw StateError('Isolated journal unavailable');
      final work = listingSession(source, journal);
      await openListingEditor(tester, work);
      expect(find.byKey(const Key('work-product-public')), findsNothing);
      final row = find.byKey(const Key('work-product-public-check'));
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      journal.read = () async => null;
      await tester.tap(
        find.descendant(of: row, matching: find.byType(IconButton)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-product-public')), findsOneWidget);
      expect(source.submitted, 0);
      expect(source.reconciled, 0);
      expect(work.workspaceCatalogueItems.single.publicListing, false);
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'quantity steps start at the minimum order in owner and public projections',
    () async {
      final data = page();
      final channel = (row(data)['channels'] as List).single as Map;
      channel['minimumOrder'] = 3;
      channel['quantityStep'] = 2;
      channel['tiers'] = [
        {'minimumQuantity': 3, 'unitPriceMinor': 26000},
        {'minimumQuantity': 5, 'unitPriceMinor': 25000},
      ];
      final requested = product.copyWith(
        minimumOrder: 3,
        packTerms: BuyV2PackTerms(
          skuId: 'sku-one',
          revision: 'pack-source-one',
          sellUnit: 'bottle',
          netContentMilli: 1000,
          contentUnit: 'L',
          quantityStep: 2,
          pricingStoreId: 'store-one',
          priceObservedAt: at.subtract(const Duration(hours: 1)),
          priceValidUntil: at.add(const Duration(hours: 1)),
          priceTiers: const [
            BuyV2PackPriceTier(minimumPacks: 3, price: 260),
            BuyV2PackPriceTier(minimumPacks: 5, price: 250),
          ],
        ),
      );
      (row(data)['pack'] as Map)['label'] = requested.pack;
      expect(
        (await gateway(Transport(data)).read(requested)).content.state,
        BuyV2ProductContentState.ready,
      );
      final owned = Map<String, dynamic>.from(row(data));
      (owned['channels'] as List).single.remove('revision');
      (owned['channels'] as List).single.remove('validUntil');
      owned.addAll({
        'schemaVersion': 1,
        'storeId': 'store-one',
        'publicListing': true,
        'provenance': {
          'entryMethod': 'manual',
          'sourceRecordId': 'original-one',
        },
      });
      expect(
        WorkspaceCatalogueOwnedSku.decode(
          owned,
          storeId: 'store-one',
          skuId: 'sku-one',
          now: at,
          realm: 'production',
        ).input['channels'],
        isNotEmpty,
      );
      ((owned['channels'] as List).single['tiers']
              as List)[1]['minimumQuantity'] =
          4;
      expect(
        () => WorkspaceCatalogueOwnedSku.decode(
          owned,
          storeId: 'store-one',
          skuId: 'sku-one',
          now: at,
          realm: 'production',
        ),
        throwsFormatException,
      );
    },
  );
  group('Store listing caller (isolated host)', () {
    test(
      'explicit owner action binds one saved SKU without Stock or review-flag mutation',
      () async {
        final source = SessionCatalogue(),
            journal = BindingStore(),
            work = listingSession(source, journal);
        final original = work.workspaceCatalogueItems.single;
        source.write = (intent, current) async {
          expect(current(), true);
          expect(intent.sku['provenance'], {
            'entryMethod': 'manual',
            'sourceRecordId': 'sku-one',
          });
          expect(jsonEncode(intent.body), isNot(contains('purchasePrice')));
          expect(journal.saved?.idempotencyKey, intent.idempotencyKey);
          return listingSaved(intent);
        };
        expect(await work.toggleWorkspaceProductListing('sku-one'), true);
        expect(source.ownerReads, 1);
        expect(source.submitted, 1);
        expect(journal.saved, isNull);
        expect(
          work.workspaceCatalogueItems.single.toInventoryJson(),
          original.copyWith(publicListing: true).toInventoryJson(),
        );
        expect(
          work.workspaceCatalogueItems.single.catalogueFactsRequireReview,
          true,
        );
        expect(work.workspaceStockMovements, isEmpty);
        expect(work.workspaceInvoices, isEmpty);
        work.dispose();
      },
    );
    test(
      'configured missing or mismatched binding never falls back to local visibility',
      () async {
        for (final mismatch in [false, true]) {
          final source = SessionCatalogue(),
              work = listingSession(source, BindingStore());
          if (mismatch) {
            final record = await source.ownerRead();
            final changed = record!.toJson();
            (changed['content'] as Map)['description'] =
                'Different reviewed description';
            source.ownerRead = () async => WorkspaceCatalogueOwnedSku.decode(
              changed,
              storeId: 'store-one',
              skuId: 'sku-one',
              realm: 'production',
              now: at,
            );
          } else {
            source.ownerRead = () async => null;
          }
          final before = work.workspaceCatalogueItems.single.toInventoryJson();
          expect(await work.toggleWorkspaceProductListing('sku-one'), false);
          expect(source.submitted, 0);
          expect(work.workspaceCatalogueItems.single.toInventoryJson(), before);
          work.dispose();
        }
      },
    );
    test(
      'ordinary edits and CSV import have no owner-read or upload side effect',
      () async {
        final source = SessionCatalogue(),
            work = listingSession(source, BindingStore());
        expect(
          work.addOrUpdateWorkspaceProduct(
            listingItem().copyWith(sellingPrice: 261),
          ),
          true,
        );
        final other = WorkspaceCatalogueItem.fromInventoryJson({
          ...listingItem().toInventoryJson(),
          'id': 'sku-two',
          'canonicalId': 'canonical-two',
          'sku': 'HOST-TWO',
          'title': 'Host fixture flour',
          'stockEntry': null,
          'version': 1,
        });
        expect(
          work.importWorkspaceProducts(
            [other],
            addOnly: true,
            stockEntryMethod: WorkspaceStockEntryMethod.csv,
          ),
          true,
        );
        expect(source.ownerReads, 0);
        expect(source.submitted, 0);
        expect(work.workspaceCatalogueItems.length, 2);
        work.dispose();
      },
    );
    test(
      'restored original checks receipt, never flips a later preference or resubmits',
      () async {
        final source = SessionCatalogue(), journal = BindingStore();
        source.write = (_, _) async => const WorkspaceCatalogueBindingResult(
          WorkspaceCatalogueBindingState.unknown,
        );
        var work = listingSession(source, journal);
        expect(await work.toggleWorkspaceProductListing('sku-one'), false);
        final saved = work.workspaceCatalogueItems.single;
        work.dispose();
        work = listingSession(source, journal)..workspaceCatalogueItems.clear();
        work.workspaceCatalogueItems.add(saved);
        source.check = (intent) async => listingSaved(intent);
        expect(await work.toggleWorkspaceProductListing('sku-one'), true);
        expect(source.submitted, 1);
        expect(source.reconciled, 1);
        expect(work.workspaceCatalogueItems.single.publicListing, true);
        expect(work.workspaceStockMovements, isEmpty);
        expect(journal.saved, isNull);
        work.dispose();
      },
    );
    test(
      'withdrawal keeps changed local price but sends only the old mirror listing false',
      () async {
        final source = SessionCatalogue(),
            work = listingSession(source, BindingStore());
        work.workspaceCatalogueItems[0] = listingItem().copyWith(
          publicListing: true,
          sellingPrice: 261,
        );
        final owned = (await source.ownerRead())!.toJson()
          ..['publicListing'] = true;
        source.ownerRead = () async => WorkspaceCatalogueOwnedSku.decode(
          owned,
          storeId: 'store-one',
          skuId: 'sku-one',
          realm: 'production',
          now: at,
        );
        source.write = (intent, _) async {
          expect(intent.sku['publicListing'], false);
          expect(
            ((intent.sku['channels'] as List).single as Map)['priceMinor'],
            26000,
          );
          return listingSaved(intent);
        };
        expect(await work.toggleWorkspaceProductListing('sku-one'), true);
        expect(source.submitted, 1);
        expect(work.workspaceCatalogueItems.single.sellingPrice, 261);
        expect(work.workspaceCatalogueItems.single.publicListing, false);
        expect(work.workspaceStockMovements, isEmpty);
        work.dispose();
      },
    );
    test(
      'A-B-A Store transition during owner read cannot dispatch a stale request',
      () async {
        final source = SessionCatalogue(),
            work = listingSession(source, BindingStore());
        final entered = Completer<void>(),
            release = Completer<void>(),
            originalRead = source.ownerRead;
        source.ownerRead = () async {
          entered.complete();
          await release.future;
          return originalRead();
        };
        final operation = work.toggleWorkspaceProductListing('sku-one');
        await entered.future;
        final originalStore = work.activeWorkspace;
        work.activeWorkspace = const WorkWorkspace(
          id: 'store-two',
          name: 'Other Store',
          profileLabel: 'Grocery',
          profileId: 'retailer-grocery',
          area: 'Jaipur',
          verified: true,
        );
        work.activeWorkspace = originalStore;
        release.complete();
        expect(await operation, false);
        expect(source.submitted, 0);
        expect(work.workspaceCatalogueItems.single.publicListing, false);
        work.dispose();
      },
    );
  });
  group('listing original request recovery (isolated host)', () {
    test(
      'journal is saved before dispatch, matching acknowledgement is removed',
      () async {
        final store = BindingStore(), gateway = ListingGateway();
        gateway.write = (original, _) async {
          expect(store.saved?.toJson(), original.toJson());
          return listingSaved(original);
        };
        final controller = WorkspaceCatalogueListingController(
          scope: listingScope,
          gateway: gateway,
          pendingStore: store,
          context: () => 'current-owner',
        );
        final result = await controller.submit(
          ownerIntent(),
          inputCurrent: () => true,
        );
        expect(result.state, WorkspaceCatalogueBindingState.saved);
        expect(store.saved, isNull);
        expect(controller.pending, isNull);
        controller.dispose();
      },
    );
    test(
      'restart restores unknown original and checks receipt without another submission',
      () async {
        final store = BindingStore(), gateway = ListingGateway();
        gateway.write = (_, _) async => const WorkspaceCatalogueBindingResult(
          WorkspaceCatalogueBindingState.unknown,
        );
        var controller = WorkspaceCatalogueListingController(
          scope: listingScope,
          gateway: gateway,
          pendingStore: store,
          context: () => 'current-owner',
        );
        await controller.submit(ownerIntent(), inputCurrent: () => true);
        controller.dispose();
        controller = WorkspaceCatalogueListingController(
          scope: listingScope,
          gateway: gateway,
          pendingStore: store,
          context: () => 'current-owner',
        );
        expect(await controller.restore(), true);
        expect(controller.pending?.idempotencyKey, 'binding-original');
        final another = WorkspaceCatalogueBindingIntent.fromJson(
          jsonDecode(
            jsonEncode(
              ownerIntent().toJson()..['idempotencyKey'] = 'do-not-replace',
            ),
          ),
        );
        expect(
          (await controller.submit(another, inputCurrent: () => true)).state,
          WorkspaceCatalogueBindingState.unknown,
        );
        gateway.check = (original) async => listingSaved(original);
        expect(
          (await controller.reconcile()).state,
          WorkspaceCatalogueBindingState.saved,
        );
        expect(gateway.submitted, 1);
        expect(gateway.reconciled, 1);
        expect(store.saved, isNull);
        controller.dispose();
      },
    );
    test(
      'failed journal cannot dispatch; failed removal retains original after a saved reply',
      () async {
        for (final failSave in [true, false]) {
          final store = BindingStore()
            ..failWrite = failSave
            ..failRemoval = !failSave;
          final gateway = ListingGateway();
          final controller = WorkspaceCatalogueListingController(
            scope: listingScope,
            gateway: gateway,
            pendingStore: store,
            context: () => 'current-owner',
          );
          expect(
            (await controller.submit(
              ownerIntent(),
              inputCurrent: () => true,
            )).state,
            WorkspaceCatalogueBindingState.unknown,
          );
          expect(gateway.submitted, failSave ? 0 : 1);
          expect(controller.ready, false);
          expect(controller.pending?.idempotencyKey, 'binding-original');
          controller.dispose();
        }
      },
    );
    test(
      'input changed during credentials prevents a stale listing dispatch',
      () async {
        final store = BindingStore(),
            gateway = ListingGateway(),
            entered = Completer<void>(),
            release = Completer<void>();
        var valid = true, sent = 0;
        gateway.write = (original, current) async {
          entered.complete();
          await release.future;
          if (!current()) {
            return const WorkspaceCatalogueBindingResult(
              WorkspaceCatalogueBindingState.notSent,
            );
          }
          sent++;
          return listingSaved(original);
        };
        final controller = WorkspaceCatalogueListingController(
          scope: listingScope,
          gateway: gateway,
          pendingStore: store,
          context: () => 'current-owner',
        );
        final operation = controller.submit(
          ownerIntent(),
          inputCurrent: () => valid,
        );
        await entered.future;
        valid = false;
        release.complete();
        await operation;
        expect(sent, 0);
        controller.dispose();
      },
    );
    test('retired Store result cannot clear the original journal', () async {
      final store = BindingStore(),
          gateway = ListingGateway(),
          reply = Completer<WorkspaceCatalogueBindingResult>();
      var context = 'first-store';
      gateway.write = (_, _) => reply.future;
      final controller = WorkspaceCatalogueListingController(
        scope: listingScope,
        gateway: gateway,
        pendingStore: store,
        context: () => context,
      );
      final operation = controller.submit(
        ownerIntent(),
        inputCurrent: () => true,
      );
      while (gateway.submitted == 0) {
        await Future<void>.delayed(Duration.zero);
      }
      context = 'other-store';
      reply.complete(listingSaved(ownerIntent()));
      expect((await operation).state, WorkspaceCatalogueBindingState.unknown);
      expect(store.saved?.idempotencyKey, 'binding-original');
      controller.dispose();
    });
    test(
      'native journal retains exact owner realm and original request across instances',
      () async {
        FlutterSecureStorage.setMockInitialValues({});
        final journal = SecureWorkCatalogueBindingPendingStore(
          currentAccount: () => 'owner-one',
        );
        await journal.savePending(ownerIntent());
        final restarted = SecureWorkCatalogueBindingPendingStore(
          currentAccount: () => 'owner-one',
        );
        expect(
          (await restarted.readPending(listingScope))?.toJson(),
          ownerIntent().toJson(),
        );
        expect(
          await restarted.readPending((
            account: 'owner-one',
            store: 'store-one',
            realm: 'evaluation',
          )),
          isNull,
        );
        final different = WorkspaceCatalogueBindingIntent.fromJson(
          jsonDecode(
            jsonEncode(
              ownerIntent().toJson()..['idempotencyKey'] = 'different-original',
            ),
          ),
        );
        await expectLater(
          restarted.removePending(different),
          throwsFormatException,
        );
        expect(
          (await restarted.readPending(listingScope))?.idempotencyKey,
          'binding-original',
        );
        await restarted.removePending(ownerIntent());
        expect(await restarted.readPending(listingScope), isNull);
      },
    );
  });
  group('owner binding adapter (isolated host)', () {
    test(
      'checking an original binding is read-only, missing receipt stays unknown',
      () async {
        for (final exists in [true, false]) {
          final credentials = Credentials();
          final transport = OwnerTransport((request) async {
            expect(request['operation'], 'reconcileStoreCatalogueBinding');
            expect(request['idempotencyKey'], 'binding-original');
            final data = jsonDecode(ownerAck(request).body) as Map;
            if (!exists) (data['data'] as Map)['saved'] = null;
            return SocialContentResponse(
              statusCode: 200,
              body: jsonEncode(data),
            );
          });
          final result = await ownerGateway(
            transport,
            credentials,
          ).reconcileBinding(ownerIntent(), current: () => true);
          expect(
            result.state,
            exists
                ? WorkspaceCatalogueBindingState.saved
                : WorkspaceCatalogueBindingState.unknown,
          );
          expect(credentials.modes, [SocialAppCheckTokenMode.standard]);
        }
      },
    );
    test(
      'restored intent cannot cross its original account or realm',
      () async {
        for (final changed in [
          {'accountId': 'other-owner'},
          {'realm': 'evaluation'},
        ]) {
          final intent = WorkspaceCatalogueBindingIntent.fromJson(
            jsonDecode(jsonEncode(ownerIntent().toJson()..addAll(changed))),
          );
          final credentials = Credentials();
          final transport = OwnerTransport(
            (request) async => ownerAck(request),
          );
          final result = await ownerGateway(
            transport,
            credentials,
          ).bindReviewed(intent, current: () => true, recoveringUnknown: true);
          expect(result.state, WorkspaceCatalogueBindingState.unknown);
          expect(transport.calls, 0);
          expect(credentials.modes, isEmpty);
        }
      },
    );
    test(
      'access denial during original recovery never proves the earlier write failed',
      () async {
        final transport = OwnerTransport(
          (_) async => SocialContentResponse(
            statusCode: 403,
            body: jsonEncode({
              'ok': false,
              'error': {'code': 'forbidden'},
            }),
          ),
        );
        final result = await ownerGateway(transport).bindReviewed(
          ownerIntent(),
          current: () => true,
          recoveringUnknown: true,
        );
        expect(result.state, WorkspaceCatalogueBindingState.unknown);
        expect(transport.calls, 1);
      },
    );
    test(
      'read exact private row with source IDs, without publication authority',
      () async {
        final credentials = Credentials();
        final transport = OwnerTransport((body) async {
          expect(body, {
            'operation': 'listStoreCatalogueSkus',
            'mediaReadbackVersion': 1,
            'storeId': 'store-one',
            'skuId': 'sku-one',
          });
          return SocialContentResponse(
            statusCode: 200,
            body: jsonEncode({
              'ok': true,
              'data': {
                'schemaVersion': 1,
                'realm': 'production',
                'storeId': 'store-one',
                'items': [ownerRow()],
                'nextCursor': null,
              },
            }),
          );
        });
        final saved = await ownerGateway(transport, credentials).readOwnedSku(
          storeId: 'store-one',
          skuId: 'sku-one',
          current: () => true,
        );
        expect(saved?.verifiedPackId, 'pack-one');
        expect(saved?.canonicalProductId, 'canonical-one');
        expect(saved?.input['provenance'], {
          'entryMethod': 'manual',
          'sourceRecordId': 'original-one',
        });
        expect(credentials.modes, [SocialAppCheckTokenMode.standard]);
      },
    );
    test('LF-LISTING owner photo proof needs negotiated metadata and preserves original file facts', () async {
      var negotiated = false;
      final raw = ownerRow();
      (raw['content'] as Map)['media'] = [<String, Object?>{
        'id': 'host-owner-photo', 'revision': 'photo-one', 'url': 'https://example.com/host-photo.jpg',
        'storeId': 'store-one', 'skuId': 'sku-one', 'canonicalProductId': 'canonical-one',
        'publisherWorkspaceId': 'store-one', 'file': {'mimeType': 'image/jpeg', 'byteLength': 1024,
          'width': 640, 'height': 640, 'normalized': true, 'frameCount': 1}}];
      final transport = OwnerTransport((body) async {
        expect(body['mediaReadbackVersion'], 1);
        return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': {
          'schemaVersion': 1, 'realm': 'production', 'storeId': 'store-one', 'items': [raw],
          'nextCursor': null, if (negotiated) 'mediaReadbackVersion': 1}}));
      });
      final source = ownerGateway(transport, Credentials());
      expect(await source.readOwnedSku(storeId: 'store-one', skuId: 'sku-one', current: () => true), isNull);
      negotiated = true;
      final saved = await source.readOwnedSku(storeId: 'store-one', skuId: 'sku-one', current: () => true);
      expect((saved!.input['content']['media'] as List).single['file']['frameCount'], 1);
      expect(saved.input['content'], raw['content']);
    });
    test(
      'binding intent owns its immutable request and survives JSON restore',
      () {
        final original = ownerIntent(), encoded = jsonEncode(original.toJson());
        (original.sku['content'] as Map)['title'] = 'Mutated caller copy';
        final restored = WorkspaceCatalogueBindingIntent.fromJson(
          jsonDecode(encoded),
        );
        expect(restored.sku['content'], original.sku['content']);
        expect(restored.idempotencyKey, 'binding-original');
        expect(restored.accountId, 'owner-one');
      },
    );
    test(
      'exact saved acknowledgement uses limited-use App Check but not publication success',
      () async {
        final credentials = Credentials();
        final transport = OwnerTransport((request) async {
          expect(request['operation'], 'bindReviewedStoreCatalogueSku');
          expect(request['idempotencyKey'], 'binding-original');
          expect(request.containsKey('accountId'), false);
          return ownerAck(request);
        });
        final result = await ownerGateway(transport, credentials).bindReviewed(
          ownerIntent(),
          current: () => true,
          recoveringUnknown: false,
        );
        expect(result.state, WorkspaceCatalogueBindingState.saved);
        expect(result.saved?.revision, 2);
        expect(result.publicationConfirmed, false);
        expect(credentials.modes, [SocialAppCheckTokenMode.limitedUse]);
      },
    );
    test(
      'retired context before dispatch cannot send an owner request',
      () async {
        var current = true;
        final credentials = RetiringOwnerCredentials(() => current = false);
        final transport = OwnerTransport((request) async => ownerAck(request));
        final result = await ownerGateway(transport, credentials).bindReviewed(
          ownerIntent(),
          current: () => current,
          recoveringUnknown: false,
        );
        expect(result.state, WorkspaceCatalogueBindingState.notSent);
        expect(transport.calls, 0);
      },
    );
    test(
      'lost response and retired post-dispatch result remain unknown, with the original key',
      () async {
        for (final lose in [true, false]) {
          var current = true;
          final original = ownerIntent();
          final transport = OwnerTransport((request) async {
            if (lose) throw StateError('isolated lost reply');
            current = false;
            return ownerAck(request);
          });
          final result = await ownerGateway(transport).bindReviewed(
            original,
            current: () => current,
            recoveringUnknown: false,
          );
          expect(result.state, WorkspaceCatalogueBindingState.unknown);
          expect(original.idempotencyKey, 'binding-original');
          expect(transport.calls, 1);
        }
      },
    );
    test(
      'changed revision payload Store realm or publication claim cannot acknowledge an intent',
      () async {
        for (final change in [
          'revision',
          'content',
          'store',
          'realm',
          'publication',
        ]) {
          final transport = OwnerTransport((request) async {
            final envelope =
                jsonDecode(ownerAck(request).body) as Map<String, dynamic>;
            final data = envelope['data'] as Map<String, dynamic>,
                saved = data['saved'] as Map<String, dynamic>;
            switch (change) {
              case 'revision':
                saved['revision'] = 3;
              case 'content':
                (saved['content'] as Map)['title'] = 'Different product';
              case 'store':
                data['storeId'] = 'store-other';
              case 'realm':
                data['realm'] = 'evaluation';
              case 'publication':
                data['publicationConfirmed'] = true;
            }
            return SocialContentResponse(
              statusCode: 200,
              body: jsonEncode(envelope),
            );
          });
          expect(
            (await ownerGateway(transport).bindReviewed(
              ownerIntent(),
              current: () => true,
              recoveringUnknown: false,
            )).state,
            WorkspaceCatalogueBindingState.unknown,
            reason: change,
          );
        }
      },
    );
    test(
      'known server rejection is distinct from an unexplained failure',
      () async {
        for (final status in [409, 503]) {
          final transport = OwnerTransport(
            (_) async => SocialContentResponse(
              statusCode: status,
              body: jsonEncode({
                'ok': false,
                'error': {
                  'code': status == 409 ? 'conflict' : 'service_unavailable',
                },
              }),
            ),
          );
          expect(
            (await ownerGateway(transport).bindReviewed(
              ownerIntent(),
              current: () => true,
              recoveringUnknown: false,
            )).state,
            status == 409
                ? WorkspaceCatalogueBindingState.rejected
                : WorkspaceCatalogueBindingState.unknown,
          );
        }
      },
    );
    test(
      'private fields foreign identity or unknown provenance fail owner record decoding',
      () {
        for (final change in ['private', 'store', 'provenance', 'trade']) {
          final data = ownerRow();
          switch (change) {
            case 'private':
              (data['content'] as Map)['purchasePrice'] = 50;
            case 'store':
              data['storeId'] = 'store-other';
            case 'provenance':
              (data['provenance'] as Map)['entryMethod'] = 'guessed';
            case 'trade':
              (data['channels'] as List).addAll([
                {
                  ...(data['channels'] as List).single as Map,
                  'kind': 'wholesale',
                },
                {...(data['channels'] as List).single as Map, 'kind': 'bulk'},
              ]);
          }
          expect(
            () => WorkspaceCatalogueOwnedSku.decode(
              data,
              storeId: 'store-one',
              skuId: 'sku-one',
              now: at,
              realm: 'production',
            ),
            throwsFormatException,
            reason: change,
          );
        }
      },
    );
  });
  test('LF-PAISE readback matches paise and invalidates price MRP and tier-only changes', () async {
    BuyV2PackTerms terms(int tier) => BuyV2PackTerms(skuId: product.id,
      revision: 'term-one', sellUnit: 'pouch', containedUnits: 1,
      netContentMilli: 1000, contentUnit: 'L', quantityStep: 1,
      pricingStoreId: product.storeId,
      priceObservedAt: at.subtract(const Duration(hours: 1)),
      priceValidUntil: at.add(const Duration(hours: 1)),
      priceTiers: [BuyV2PackPriceTier(minimumPacks: 1, priceMinor: 26025),
        BuyV2PackPriceTier(minimumPacks: 2, priceMinor: tier)]);
    final exact = product.copyWith(priceMinor: 26025, mrpMinor: 28050,
      pack: terms(25925).label, packTerms: terms(25925));
    final data = page();
    (row(data)['pack'] as Map)['label'] = exact.pack;
    final channel = (row(data)['channels'] as List).single as Map;
    channel['priceMinor'] = 26025; channel['mrpMinor'] = 28050;
    channel['tiers'] = [{'minimumQuantity': 1, 'unitPriceMinor': 26025},
      {'minimumQuantity': 2, 'unitPriceMinor': 25925}];
    final reader = WorkspaceCatalogueReadback(gateway: gateway(Transport(data)),
      context: () => 'host-owner', now: () => at);
    addTearDown(reader.dispose);
    await reader.refresh(exact);
    expect(reader.snapshotFor(exact).state, BuyV2ProductContentState.ready);
    for (final changed in [exact.copyWith(priceMinor: 26026),
      exact.copyWith(mrpMinor: 28051), exact.copyWith(packTerms: terms(25924))]) {
      expect(reader.snapshotFor(changed).state, BuyV2ProductContentState.unavailable);
      expect((await gateway(Transport(data)).read(changed)).content.state,
        BuyV2ProductContentState.unavailable);
    }
    expect(reader.snapshotFor(exact).state, BuyV2ProductContentState.ready);
  });
  test('LF-PAISE malformed catalogue money is unavailable without cache mutation or transport', () async {
    final transport = Transport(page());
    final reader = WorkspaceCatalogueReadback(gateway: gateway(transport),
      context: () => 'host-owner', now: () => at);
    addTearDown(reader.dispose);
    await reader.refresh(product);
    expect(reader.snapshotFor(product).state, BuyV2ProductContentState.ready);
    final invalid = product.copyWith(priceMinor: -1);
    expect(reader.snapshotFor(invalid).state, BuyV2ProductContentState.unavailable);
    transport.sent = null;
    await reader.refresh(invalid);
    expect(transport.sent, isNull);
    expect(reader.snapshotFor(product).state, BuyV2ProductContentState.ready);
  });

  test(
    'exact verified public readback maps content and server revisions',
    () async {
      final transport = Transport(page()), credentials = Credentials();
      final result = await gateway(transport, credentials).read(product);
      expect(result.content.state, BuyV2ProductContentState.ready);
      expect(result.content.description, 'Verified host description');
      expect(result.skuRevision, 1);
      expect(result.catalogueVersion, 1);
      expect(result.content.observedAt, at);
      expect(transport.sent, {
        'operation': 'readPublicStoreCatalogue',
        'mediaReadbackVersion': 1,
        'storeId': 'store-one',
        'skuId': 'sku-one',
      });
      expect(credentials.modes, [SocialAppCheckTokenMode.standard]);
    },
  );
  test(
    'failed readback remains unavailable with no save or publication side effect',
    () async {
      final transport = Transport(page())..fail = true;
      final result = await gateway(transport).read(product);
      expect(result.content.state, BuyV2ProductContentState.unavailable);
      expect(result.skuRevision, isNull);
      expect(transport.sent?['operation'], 'readPublicStoreCatalogue');
    },
  );
  test('foreign realm and Store do not cross into public content', () async {
    for (final changed in [
      {'realm': 'evaluation'},
      {'storeId': 'store-two'},
    ]) {
      final result = await gateway(
        Transport(page()..addAll(changed)),
      ).read(product);
      expect(result.content.state, BuyV2ProductContentState.unavailable);
    }
  });
  for (final entry in <String, void Function(Map<String, dynamic>)>{
    'missing ordering hold': (d) {
      d.remove('orderingAvailable');
    },
    'ordering permission': (d) {
      d['orderingAvailable'] = true;
    },
    'wrong SKU': (d) {
      row(d)['skuId'] = 'sku-other';
    },
    'wrong canonical identity': (d) {
      row(d)['canonicalProductId'] = 'canonical-other';
    },
    'wrong pack': (d) {
      (row(d)['pack'] as Map)['label'] = '2 L';
    },
    'different price': (d) {
      ((row(d)['channels'] as List).single as Map)['priceMinor'] = 26100;
    },
    'expired terms': (d) {
      ((row(d)['channels'] as List).single as Map)['validUntil'] = at
          .toIso8601String();
    },
    'future observation': (d) {
      d['observedAt'] = at.add(const Duration(minutes: 1)).toIso8601String();
    },
    'private field': (d) {
      (row(d)['content'] as Map)['purchasePrice'] = 230;
    },
    'unknown tier': (d) {
      ((row(d)['channels'] as List).single as Map)['tiers'] = [
        {'minimumQuantity': 2, 'unitPriceMinor': 26000},
      ];
    },
    'duplicate response rows': (d) {
      (d['items'] as List).add((d['items'] as List).first);
    },
  }.entries) {
    test('${entry.key} cannot masquerade as verified content', () async {
      final data = page();
      entry.value(data);
      expect(
        (await gateway(Transport(data)).read(product)).content.state,
        BuyV2ProductContentState.unavailable,
      );
    });
  }
  test(
    'reviewed media retains publisher, exact SKU and file metadata',
    () async {
      final data = page();
      (row(data)['content'] as Map)['media'] = [
        {
          'id': 'photo-one',
          'revision': 'media-one',
          'url': 'https://example.invalid/product.png',
          'storeId': 'store-one',
          'skuId': 'sku-one',
          'canonicalProductId': 'canonical-one',
          'publisherWorkspaceId': 'publisher-one',
          'file': {
            'mimeType': 'image/png',
            'byteLength': 40000,
            'width': 800,
            'height': 800,
            'normalized': true,
          },
        },
      ];
      final result = await gateway(Transport(data)).read(product);
      expect(result.content.state, BuyV2ProductContentState.ready);
      final media = result.content.media.single;
      expect(media.binding?.supplierWorkspaceId, 'publisher-one');
      expect(media.binding?.skuId, product.id);
      expect(media.binding?.assetRevision, 'media-one');
      expect(media.binding?.file.byteLength, 40000);
      ((row(data)['content'] as Map)['media'] as List).single['skuId'] =
          'sku-other';
      expect(
        (await gateway(Transport(data)).read(product)).content.state,
        BuyV2ProductContentState.unavailable,
      );
    },
  );
  test('late readback and duplicate refresh are fenced by lifetime', () async {
    Object context = ('account-one', 'store-one', 0);
    final held = HoldingGateway(),
        reader = WorkspaceCatalogueReadback(
          gateway: held,
          context: () => context,
          now: () => at,
        );
    final first = reader.refresh(product);
    await reader.refresh(product);
    expect(held.calls, 1);
    context = ('account-two', 'store-one', 1);
    held.response.complete(await gateway(Transport(page())).read(product));
    await first;
    expect(
      reader.snapshotFor(product).state,
      BuyV2ProductContentState.unavailable,
    );
    reader.dispose();
  });
  test(
    'failed refresh never loses revision high-water or revives stale data',
    () async {
      final transport = Transport(page());
      row(transport.data)['revision'] = 2;
      final reader = WorkspaceCatalogueReadback(
        gateway: gateway(transport),
        context: () => 'same-owner',
        now: () => at,
      );
      await reader.refresh(product);
      expect(reader.snapshotFor(product).state, BuyV2ProductContentState.ready);
      expect(
        reader.snapshotFor(product.copyWith(title: 'Other product')).state,
        BuyV2ProductContentState.unavailable,
      );
      transport.fail = true;
      await reader.refresh(product);
      expect(
        reader.snapshotFor(product).state,
        BuyV2ProductContentState.unavailable,
      );
      transport.fail = false;
      row(transport.data)['revision'] = 1;
      await reader.refresh(product);
      expect(
        reader.snapshotFor(product).state,
        BuyV2ProductContentState.unavailable,
      );
      row(transport.data)['revision'] = 2;
      (row(transport.data)['content'] as Map)['description'] =
          'Mutated same revision';
      await reader.refresh(product);
      expect(
        reader.snapshotFor(product).state,
        BuyV2ProductContentState.unavailable,
      );
      reader.dispose();
    },
  );
  testWidgets(
    'source term expiry notifies the existing consumer and holds readback',
    (tester) async {
      var time = at;
      final transport = Transport(page());
      ((row(transport.data)['channels'] as List).single as Map)['validUntil'] =
          at.add(const Duration(seconds: 1)).toIso8601String();
      final reader = WorkspaceCatalogueReadback(
        gateway: gateway(transport),
        context: () => 'same-owner',
        now: () => time,
      );
      var notices = 0;
      reader.addListener(() {
        notices++;
      });
      await reader.refresh(product);
      expect(reader.snapshotFor(product).state, BuyV2ProductContentState.ready);
      time = time.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(notices, 2);
      expect(
        reader.snapshotFor(product).state,
        BuyV2ProductContentState.unavailable,
      );
      reader.dispose();
    },
  );
  for (final units in [
    (publicUnit: 'L', sourceUnit: 'L', storeUnit: BuyV2ComparisonUnit.litre),
    (
      publicUnit: 'kg',
      sourceUnit: 'kg',
      storeUnit: BuyV2ComparisonUnit.kilogram,
    ),
    (
      publicUnit: 'piece',
      sourceUnit: 'count',
      storeUnit: BuyV2ComparisonUnit.count,
    ),
  ]) {
    test(
      'aggregate case content agrees with Store mapping for ${units.publicUnit}',
      () async {
        final terms = BuyV2PackTerms(
          skuId: product.id,
          revision: 'pack-source-one',
          sellUnit: 'case',
          containedUnits: 12,
          netContentMilli: 1000,
          contentUnit: units.publicUnit,
        );
        final requested = product.copyWith(packTerms: terms), data = page();
        (row(data)['pack'] as Map).addAll(<String, Object>{
          'label': requested.pack,
          'quantityMilli': 12000,
          'unit': units.sourceUnit,
          'unitsPerCase': 12,
        });
        final item = listingItem().copyWith(
          pack: requested.pack,
          packMeasure: WorkspacePackMeasure(
            unit: units.storeUnit,
            quantityMilli: 12000,
            unitsPerCase: 12,
          ),
        );
        expect(
          item.publicSellingTermsIssue(
            channel: BuyV2Destination.shop,
            storeId: product.storeId,
            terms: terms,
            now: at,
          ),
          null,
        );
        final result = await gateway(Transport(data)).read(requested);
        expect(result.content.state, BuyV2ProductContentState.ready);
        expect(requested.price, product.price);
        expect(requested.minimumOrder, product.minimumOrder);
        for (final mismatch in ['quantity', 'count', 'unit']) {
          final changed = jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
          final pack = row(changed)['pack'] as Map;
          if (mismatch == 'quantity') pack['quantityMilli'] = 12001;
          if (mismatch == 'count') pack['unitsPerCase'] = 11;
          if (mismatch == 'unit') {
            pack['unit'] = units.sourceUnit == 'L' ? 'kg' : 'L';
          }
          expect(
            (await gateway(Transport(changed)).read(requested)).content.state,
            BuyV2ProductContentState.unavailable,
            reason: mismatch,
          );
        }
      },
    );
  }
  for (final units in [
    (publicUnit: 'mL', sourceUnit: 'L', storeUnit: BuyV2ComparisonUnit.litre),
    (
      publicUnit: 'g',
      sourceUnit: 'kg',
      storeUnit: BuyV2ComparisonUnit.kilogram,
    ),
  ]) {
    test(
      'aggregate scaled ${units.publicUnit} content checks divisibility after contained units',
      () async {
        final terms = BuyV2PackTerms(
          skuId: product.id,
          revision: 'pack-source-one',
          sellUnit: 'case',
          containedUnits: 2,
          netContentMilli: 500,
          contentUnit: units.publicUnit,
        );
        final requested = product.copyWith(packTerms: terms), data = page();
        (row(data)['pack'] as Map).addAll(<String, Object>{
          'label': requested.pack,
          'quantityMilli': 1,
          'unit': units.sourceUnit,
          'unitsPerCase': 2,
        });
        final item = listingItem().copyWith(
          pack: requested.pack,
          packMeasure: WorkspacePackMeasure(
            unit: units.storeUnit,
            quantityMilli: 1,
            unitsPerCase: 2,
          ),
        );
        expect(
          item.publicSellingTermsIssue(
            channel: BuyV2Destination.shop,
            storeId: product.storeId,
            terms: terms,
            now: at,
          ),
          null,
        );
        expect(
          (await gateway(Transport(data)).read(requested)).content.state,
          BuyV2ProductContentState.ready,
        );
        final nonIntegral = product.copyWith(
          packTerms: BuyV2PackTerms(
            skuId: product.id,
            revision: 'pack-source-one',
            sellUnit: 'case',
            containedUnits: 3,
            netContentMilli: 500,
            contentUnit: units.publicUnit,
          ),
        );
        (row(data)['pack'] as Map).addAll(<String, Object>{
          'label': nonIntegral.pack,
          'unitsPerCase': 3,
        });
        expect(
          (await gateway(Transport(data)).read(nonIntegral)).content.state,
          BuyV2ProductContentState.unavailable,
          reason: 'A fractional source milli-unit must not be rounded down',
        );
      },
    );
  }
  test(
    'aggregate whole-piece and source integer bounds remain enforced',
    () async {
      final invalid = product.copyWith(
        packTerms: const BuyV2PackTerms(
          skuId: 'sku-one',
          revision: 'pack-source-one',
          sellUnit: 'case',
          containedUnits: 2,
          netContentMilli: 500,
          contentUnit: 'piece',
        ),
      );
      final data = page();
      (row(data)['pack'] as Map).addAll(<String, Object>{
        'label': invalid.pack,
        'quantityMilli': 1000,
        'unit': 'count',
        'unitsPerCase': 2,
      });
      expect(
        (await gateway(Transport(data)).read(invalid)).content.state,
        BuyV2ProductContentState.unavailable,
      );
      for (final value in [0, -1, 100000001]) {
        final bounded = page();
        (row(bounded)['pack'] as Map)['quantityMilli'] = value;
        expect(
          (await gateway(Transport(bounded)).read(product)).content.state,
          BuyV2ProductContentState.unavailable,
        );
      }
    },
  );
  test(
    'structured pack facts must match even with the same display label',
    () async {
      final structured = product.copyWith(
        packTerms: const BuyV2PackTerms(
          skuId: 'sku-one',
          revision: 'pack-source-one',
          sellUnit: 'bottle',
          netContentMilli: 1000,
          contentUnit: 'L',
        ),
      );
      final data = page();
      (row(data)['pack'] as Map)['label'] = structured.pack;
      expect(
        (await gateway(Transport(data)).read(structured)).content.state,
        BuyV2ProductContentState.ready,
      );
      (row(data)['pack'] as Map)['quantityMilli'] = 2000;
      expect(
        (await gateway(Transport(data)).read(structured)).content.state,
        BuyV2ProductContentState.unavailable,
      );
    },
  );
  test(
    'valid but different tier prices cannot pass the content binding',
    () async {
      final structured = product.copyWith(
        packTerms: BuyV2PackTerms(
          skuId: 'sku-one',
          revision: 'pack-source-one',
          sellUnit: 'bottle',
          netContentMilli: 1000,
          contentUnit: 'L',
          priceTiers: const [
            BuyV2PackPriceTier(minimumPacks: 1, price: 260),
            BuyV2PackPriceTier(minimumPacks: 10, price: 250),
          ],
          pricingStoreId: 'store-one',
          priceObservedAt: at.subtract(const Duration(hours: 1)),
          priceValidUntil: at.add(const Duration(hours: 1)),
        ),
      );
      final data = page();
      (row(data)['pack'] as Map)['label'] = structured.pack;
      ((row(data)['channels'] as List).single as Map)['tiers'] = [
        {'minimumQuantity': 1, 'unitPriceMinor': 26000},
        {'minimumQuantity': 10, 'unitPriceMinor': 25000},
      ];
      expect(
        (await gateway(Transport(data)).read(structured)).content.state,
        BuyV2ProductContentState.ready,
      );
      (((row(data)['channels'] as List).single as Map)['tiers']
              as List)[1]['unitPriceMinor'] =
          24000;
      expect(
        (await gateway(Transport(data)).read(structured)).content.state,
        BuyV2ProductContentState.unavailable,
      );
    },
  );
  test('unapproved endpoint is rejected before credentials or transport', () {
    expect(
      () => AuthenticatedWorkspaceCatalogueGateway(
        endpoint: Uri.parse('https://example.invalid/api'),
        credentials: Credentials(),
        transport: Transport(page()),
      ),
      throwsArgumentError,
    );
  });
}
