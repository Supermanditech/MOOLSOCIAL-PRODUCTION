import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart' as invoice_ocr;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../shared/social_content_gateway.dart';
import '../buy/buy_v2_models.dart';
import '../buy/buy_v2_content_contracts.dart';
import '../buy/buy_session.dart';
import '../buy/buy_v2_session.dart';
import '../buy/buy_v2_saved_products_store.dart';
import 'work_models.dart';
import 'work_customer_feedback.dart';
import 'work_catalogue_gateway.dart';
import 'work_supplier_policy.dart';
import 'work_product_promotions.dart';
import 'work_order_identity_gateway.dart';

typedef WorkProcurementSessionFactory =
    BuyV2Session Function(
      ValueListenable<BuyV2ProcurementContext?> identity,
      BuyV2CustomerStateStore stateStore,
    );

/// A saved local purchase choice, never a server purpose or capability grant.
enum WorkRestockPurchasePurpose {
  resale('Finished goods for resale'),
  rawMaterials('Raw materials & components'),
  packaging('Packaging'),
  equipment('Equipment');
  const WorkRestockPurchasePurpose(this.label);
  final String label;
}

/// Owns Store sessions, never the consumer Shop session. Purchase grants remain
/// the responsibility of the injected commerce adapter, not this controller.
class WorkProcurementController extends ChangeNotifier {
  WorkProcurementController({
    required this.currentAccountId,
    required this.currentStoreId,
    required this.storeApproved,
    this.currentProfileId,
    this.bookmarks = const SecureWorkProcurementBookmarkStore(),
    this.reviewCatalogueAllowed,
    this.catalogueGateway,
    this.originalPurchaseReader,
    this.originalPurchaseRealm,
    WorkProcurementSessionFactory? sessionFactory,
    BuyV2CustomerStateStore Function(String scope)? stateStoreFactory,
  }) : _sessionFactory = sessionFactory,
       _ownsCore = sessionFactory == null,
       _stateStoreFactory = stateStoreFactory ?? _newStateStore;

  final String? Function() currentAccountId, currentStoreId;
  final String? Function()? currentProfileId;
  final bool Function() storeApproved;
  final WorkProcurementBookmarkStore bookmarks;
  final bool Function()? reviewCatalogueAllowed;
  final AuthenticatedWorkspaceCatalogueGateway? catalogueGateway;
  final AuthenticatedWorkspaceOrderIdentityGateway? Function()? originalPurchaseReader;
  final String Function()? originalPurchaseRealm;
  WorkspacePublicDiscoverySource? _ownedCatalogueSource;
  AuthenticatedWorkspaceOrderIdentityGateway? _purchaseSource;
  String? _purchaseSourceRealm;
  int _catalogueLifetime = 0;
  final WorkProcurementSessionFactory? _sessionFactory;
  final bool _ownsCore;
  final BuyV2CustomerStateStore Function(String) _stateStoreFactory;
  final _identity = ValueNotifier<BuyV2ProcurementContext?>(null);
  BuyV2Session? session;
  WorkProcurementBookmark? bookmark;
  String? openFailureMessage;
  int _epoch = 0;
  bool _disposed = false;
  Future<void> _writes = Future<void>.value();
  final _restockPolicyGeneration = ValueNotifier<int>(0);
  String? _observedProfileId;
  int _choiceOperation = 0;
  bool restockChoiceBusy = false;
  String? restockChoiceMessage;
  int get restockPolicyRevision => _restockPolicyGeneration.value;
  WorkRestockPurchasePurpose? get restockPurpose =>
    bookmark?.uiProfileId == currentProfileId?.call() ? bookmark?.restockPurpose : null;
  List<WorkRestockPurchasePurpose> get restockPurposeOptions => switch (currentProfileId?.call()) {
    'retailer-grocery' || 'retailer-speciality' || 'wholesaler' => const [WorkRestockPurchasePurpose.resale],
    'manufacturer' => const [WorkRestockPurchasePurpose.rawMaterials, WorkRestockPurchasePurpose.packaging,
      WorkRestockPurchasePurpose.equipment],
    _ => const [],
  };
  String? get restockRestrictionMessage {
    if (restockChoiceBusy) return 'Saving your purchase purpose. Your basket is kept.';
    final profile = currentProfileId?.call(), choice = restockPurpose;
    if (profile == null || restockPurposeOptions.isEmpty) {
      return 'Your Store profile could not be confirmed for this purchase. Your basket is kept.';
    }
    if (choice == null || !restockPurposeOptions.contains(choice)) {
      return 'Choose the purpose of this Store purchase. Your basket is kept.';
    }
    if (profile == 'wholesaler') {
      return 'Upstream supplier eligibility for your Store has not been confirmed. Other wholesalers are excluded. Your basket is kept.';
    }
    if (profile == 'manufacturer') {
      return 'Supplier eligibility for ${choice.label.toLowerCase()} has not been confirmed. Your basket is kept.';
    }
    return null;
  }

  void _refreshRestockPolicy() {
    _restockPolicyGeneration.value++;
    session?.refreshProcurementPolicy();
  }

  Future<bool> selectRestockPurpose(WorkRestockPurchasePurpose choice) async {
    final before = bookmark, opened = session, profile = currentProfileId?.call();
    if (_disposed || restockChoiceBusy || !scopeCurrent || before == null || !before.active || opened == null ||
        !restockPurposeOptions.contains(choice)) { return false; }
    if (restockPurpose == choice) return true;
    if (opened.checkoutBusy || opened.checkoutRequiresResolution || opened.customerStateRecoveryPending ||
        restockPurpose != null && opened.cartLines.isNotEmpty) {
      restockChoiceMessage = 'Finish or recover this Store purchase before changing its purpose.';
      notifyListeners(); return false;
    }
    final epoch = _epoch, generation = restockPolicyRevision, operation = ++_choiceOperation;
    bool current() => !_disposed && operation == _choiceOperation && epoch == _epoch &&
      generation == restockPolicyRevision && scopeCurrent && identical(session, opened) &&
      currentProfileId?.call() == profile && bookmark?.active == true &&
      bookmark?.context.customerStateOwnerScope == before.context.customerStateOwnerScope;
    restockChoiceBusy = true; restockChoiceMessage = null; notifyListeners();
    try {
      final saved = await _write(() async {
        if (!current() || opened.checkoutBusy || opened.checkoutRequiresResolution || opened.customerStateRecoveryPending ||
            restockPurpose != null && opened.cartLines.isNotEmpty) { return false; }
        final latest = bookmark!, chosen = WorkProcurementBookmark(context: latest.context, returnTo: latest.returnTo,
          active: latest.active, uiPurpose: choice.name, uiProfileId: profile);
        if (!await bookmarks.save(chosen)) return false;
        if (!current() || opened.checkoutBusy || opened.checkoutRequiresResolution || opened.customerStateRecoveryPending ||
            restockPurpose != null && opened.cartLines.isNotEmpty) {
          // The serialized rollback also precedes a queued leave/open write.
          await bookmarks.save(latest);
          return false;
        }
        // Activation follows confirmed persistence; no basket, scope or original is rewritten.
        bookmark = chosen; _epoch++; _refreshRestockPolicy();
        return true;
      });
      if (!saved && !_disposed && operation == _choiceOperation) {
        restockChoiceMessage = 'Saving this purchase purpose could not be confirmed. Reopen Buy stock to check the saved choice. Your basket is kept.';
      }
      return saved;
    } finally {
      if (!_disposed && operation == _choiceOperation) { restockChoiceBusy = false; notifyListeners(); }
    }
  }

  static BuyV2CustomerStateStore _newStateStore(String scope) =>
      BuyV2SharedPreferencesCustomerStateStore(
        SharedPreferencesAsync(),
        ownerScope: scope,
      );
  bool get usesReviewCatalogue =>
      session?.commerceAdapter is _StoreReviewProcurementCatalogue;

  BuyV2Session _newSession(
    ValueListenable<BuyV2ProcurementContext?> identity,
    BuyV2CustomerStateStore stateStore,
  ) {
    final context = identity.value;
    final configured = catalogueGateway?.procurementReadbackSupported == true;
    AuthenticatedWorkspaceCatalogueGateway? bound;
    if (configured && context != null) {
      final lifetime = _catalogueLifetime;
      bool current() => lifetime == _catalogueLifetime && scopeCurrent && restockRestrictionMessage == null &&
          identity.value?.customerStateOwnerScope == context.customerStateOwnerScope;
      try {
        bound = catalogueGateway!.forStoreProcurement(context, current: current);
        _ownedCatalogueSource = WorkspacePublicDiscoverySource(gateway: bound, current: current,
          requestGeneration: _restockPolicyGeneration);
      } on Object {
        // A configured source never falls back to evaluation catalogue grants.
        bound = null;
      }
    }
    final review =
        !configured && context != null &&
            context.purpose == BuyV2ProcurementPurpose.restock &&
            kDebugMode &&
            const bool.fromEnvironment('MOOLSOCIAL_DEVICE_REVIEW') &&
            const bool.fromEnvironment('MOOLSOCIAL_UI_REVIEW_ONLY') &&
            reviewCatalogueAllowed?.call() == true &&
            [12, 100, 1000].any(
              (count) =>
                  StoreReviewSeed(
                    accountScope: context.accountId,
                    orderCount: count,
                    now: DateTime.now(),
                  ).storeId ==
                  context.storeId,
            )
        ? _StoreReviewProcurementCatalogue(
            context,
            current: () =>
                scopeCurrent && restockRestrictionMessage == null &&
                identity.value?.customerStateOwnerScope ==
                    context.customerStateOwnerScope &&
                reviewCatalogueAllowed?.call() == true,
          )
        : null;
    final purchaseSource = originalPurchaseReader?.call(), purchaseRealm = originalPurchaseRealm?.call();
    _purchaseSource = purchaseSource; _purchaseSourceRealm = purchaseRealm;
    final purchases = context == null ? null : _scopedPurchases(context, purchaseSource, purchaseRealm);
    final catalogue = _ownedCatalogueSource;
    return BuyV2Session(
      core: BuySession(),
      procurementIdentity: identity,
      procurementRestriction: () => restockRestrictionMessage,
      customerStateStore: stateStore,
      reviewDataEnabled: false,
      purchaseReader: purchases,
      purchaseRealm: purchases == null ? bound?.realm ?? 'production' : purchaseRealm!,
      commerceAdapter: bound == null ? review : _StoreProcurementCommerceAdapter(bound),
      commercialPaymentTermsAdapter: review,
      cataloguePageSource: _ownedCatalogueSource ?? review,
      variantFamilySource: _ownedCatalogueSource,
      productContentAdapter: _ownedCatalogueSource,
      storeStockReader: bound?.stockSnapshotsSupported == true && catalogue != null
          ? WorkspacePublicStockReader(gateway: bound!, displayed: catalogue.displayedProduct,
              current: () => catalogue.active, now: bound.now)
          : null,
      catalogueNow: bound?.now ?? DateTime.now,
      initialCatalogueRegionId: review == null ? null : 'jodhpur',
      initialCatalogueAreaScope: bound == null ? BuyV2CatalogueAreaScope.regional : BuyV2CatalogueAreaScope.allAreas,
    );
  }

  AuthenticatedWorkspaceOrderIdentityGateway? _scopedPurchases(BuyV2ProcurementContext context,
    AuthenticatedWorkspaceOrderIdentityGateway? source, String? realm) {
    if (source == null || !source.isCurrent || source.accountUserId != context.accountId ||
        !const ['evaluation', 'production'].contains(realm)) {
      return null;
    }
    final lifetime = _catalogueLifetime, token = Object();
    return AuthenticatedWorkspaceOrderIdentityGateway(endpoint: source.endpoint,
      accountUserId: context.accountId, credentials: source.credentials, transport: source.transport,
      purchasedWarrantyReader: source.purchasedWarrantyReader,
      purchasedUnitSource: source.purchasedUnitSource,
      lifetime: () => lifetime == _catalogueLifetime && scopeCurrent && source.isCurrent &&
        identical(originalPurchaseReader?.call(), source) && originalPurchaseRealm?.call() == realm &&
        _identity.value?.customerStateOwnerScope == context.customerStateOwnerScope ? token : null);
  }

  void _refreshPurchaseReader() {
    final opened = session, context = bookmark?.context;
    if (!_ownsCore || opened == null || context == null || !scopeCurrent) {
      return;
    }
    final source = originalPurchaseReader?.call(), realm = originalPurchaseRealm?.call();
    final usable = source != null && source.isCurrent && source.accountUserId == context.accountId &&
      const ['evaluation', 'production'].contains(realm);
    if (identical(source, _purchaseSource) && realm == _purchaseSourceRealm &&
        usable == (opened.purchaseReader?.isCurrent == true)) {
      return;
    }
    final replacement = _scopedPurchases(context, source, realm);
    // Remember before session notification: listeners may inspect/reopen Restock.
    _purchaseSource = source; _purchaseSourceRealm = realm;
    opened.rebindStorePurchaseReader(reader: replacement, realm: realm ?? '');
  }

  bool get scopeCurrent {
    final value = bookmark?.context;
    return !_disposed &&
        value != null &&
        storeApproved() &&
        value.accountId == currentAccountId() &&
        value.storeId == currentStoreId();
  }

  /// Called synchronously when authentication or selected Store changes.
  void invalidateIfChanged() {
    if (bookmark != null && !scopeCurrent) {
      invalidate();
    } else {
      final profile = currentProfileId?.call();
      if (bookmark != null && _observedProfileId != profile) {
        _observedProfileId = profile; _epoch++; _refreshRestockPolicy();
        notifyListeners();
      }
      _refreshPurchaseReader();
    }
  }

  void invalidate() {
    _epoch++;
    _identity.value = null;
    _disposeSession();
    bookmark = null;
    if (!_disposed) notifyListeners();
  }

  void _disposeSession() {
    _catalogueLifetime++;
    _purchaseSource = null; _purchaseSourceRealm = null;
    final source = _ownedCatalogueSource;
    _ownedCatalogueSource = null;
    final previous = session;
    session = null;
    previous?.dispose();
    source?.dispose();
    if (_ownsCore) previous?.core.dispose();
  }

  Future<bool> _write(Future<bool> Function() action) {
    final result = Completer<bool>();
    _writes = _writes.then((_) async {
      try {
        result.complete(await action());
      } on Object {
        result.complete(false);
      }
    });
    return result.future;
  }

  Future<bool> open({
    required BuyV2ProcurementPurpose purpose,
    required String returnTo,
    bool restoreOnly = false,
    BuyV2ProcurementContext? exactContext,
  }) async {
    final account = currentAccountId(), store = currentStoreId(), profile = currentProfileId?.call();
    openFailureMessage = null;
    if (_disposed ||
        !storeApproved() ||
        account == null ||
        store == null ||
        account.trim().isEmpty ||
        store.trim().isEmpty ||
        !WorkProcurementBookmark.returnDestinations.contains(returnTo) ||
        (exactContext != null &&
            (restoreOnly ||
                !exactContext.hasIdentity ||
                exactContext.accountId != account ||
                exactContext.storeId != store ||
                exactContext.purpose != purpose))) {
      openFailureMessage = !storeApproved()
          ? 'Buy stock requires a verified Store. Check your Store verification status.'
          : account == null || account.trim().isEmpty || store == null || store.trim().isEmpty
          ? 'Your Store account is unavailable. Reopen the Store before buying stock.'
          : 'This purchase entry is unavailable. Return to Stock and try again.';
      return false;
    }
    final epoch = ++_epoch;
    bool current() =>
        !_disposed &&
        epoch == _epoch &&
        storeApproved() &&
        currentAccountId() == account &&
        currentStoreId() == store && currentProfileId?.call() == profile;
    WorkProcurementBookmark? previous;
    try {
      previous = await bookmarks.read(account, store);
    } on Object {
      // A failed read is not an empty cart. Preserve the saved operation.
      if (current()) {
        openFailureMessage = 'Your saved purchase could not be read. Nothing was replaced. Close and reopen Buy stock to retry.';
      }
      return false;
    }
    if (!current()) return false;
    if (restoreOnly && (previous == null || !previous.active)) return false;
    var chosen = exactContext != null
        ? WorkProcurementBookmark(context: exactContext, returnTo: returnTo,
            uiPurpose: previous?.uiPurpose, uiProfileId: previous?.uiProfileId)
        : previous != null &&
              (restoreOnly || previous.context.purpose == purpose)
        ? WorkProcurementBookmark(
            context: previous.context,
            returnTo: restoreOnly ? previous.returnTo : returnTo,
            uiPurpose: previous.uiPurpose, uiProfileId: previous.uiProfileId,
          )
        : WorkProcurementBookmark(
            context: BuyV2ProcurementContext(
              accountId: account,
              storeId: store,
              purpose: purpose,
              // Purpose is already part of Buy's storage namespace. Preserve
              // the Store visit identity when switching supply destinations so
              // returning to an earlier purpose recovers its own retained cart.
              originOperationId:
                  previous?.context.originOperationId ??
                  List.generate(
                    16,
                    (_) => Random.secure()
                        .nextInt(256)
                        .toRadixString(16)
                        .padLeft(2, '0'),
                  ).join(),
            ),
            returnTo: returnTo,
            uiPurpose: previous?.uiPurpose, uiProfileId: previous?.uiProfileId,
          );
    // Fixed resale profiles need no new hurdle; unknown/future choices are never defaulted.
    if (chosen.uiPurpose == null && chosen.uiProfileId == null &&
        const ['retailer-grocery', 'retailer-speciality', 'wholesaler'].contains(profile)) {
      chosen = WorkProcurementBookmark(context: chosen.context, returnTo: chosen.returnTo,
        active: chosen.active, uiPurpose: WorkRestockPurchasePurpose.resale.name, uiProfileId: profile);
    }
    if (!await _write(() async => current() && await bookmarks.save(chosen)) ||
        !current()) {
      if (current()) {
        openFailureMessage = 'Your purchase could not be saved on this phone. Nothing was opened. Try again.';
      }
      return false;
    }
    if (session != null &&
        scopeCurrent &&
        bookmark!.context.customerStateOwnerScope ==
            chosen.context.customerStateOwnerScope) {
      bookmark = chosen;
      final profileChanged = _observedProfileId != profile;
      _observedProfileId = profile;
      if (profileChanged) _refreshRestockPolicy();
      _refreshPurchaseReader();
      notifyListeners();
      return true;
    }
    _identity.value = null;
    _disposeSession();
    bookmark = chosen;
    _observedProfileId = profile;
    _identity.value = chosen.context;
    final opened = (_sessionFactory ?? _newSession)(
      _identity,
      _stateStoreFactory(chosen.context.customerStateOwnerScope),
    );
    session = opened;
    notifyListeners();
    await opened.restoreCommerce();
    if (!current() || session != opened) return false;
    await opened.restoreCustomerState();
    if (!current() || session != opened) return false;
    notifyListeners();
    return true;
  }

  Future<bool> leave() async {
    final value = bookmark;
    if (value == null || !scopeCurrent) return false;
    final epoch = ++_epoch;
    _choiceOperation++;
    restockChoiceBusy = false;
    WorkProcurementBookmark? inactive;
    final saved = await _write(() async {
      if (_disposed || epoch != _epoch || !scopeCurrent) return false;
      final latest = bookmark!;
      inactive = WorkProcurementBookmark(context: latest.context, returnTo: latest.returnTo,
        active: false, uiPurpose: latest.uiPurpose, uiProfileId: latest.uiProfileId);
      if (!await bookmarks.save(inactive!) || _disposed || epoch != _epoch || !scopeCurrent) return false;
      bookmark = inactive;
      return true;
    });
    if (!saved || _disposed || epoch != _epoch || !scopeCurrent) return false;
    return true;
  }

  @override
  void dispose() {
    _disposed = true;
    invalidate();
    _identity.dispose();
    _restockPolicyGeneration.dispose();
    super.dispose();
  }
}

/// Reuses the shared unavailable operations until real ordering is connected.
/// Catalogue permission grants no availability, credit or payment authority.
final class _StoreProcurementCommerceAdapter extends BuyV2UnavailableCommerceAdapter {
  const _StoreProcurementCommerceAdapter(this.gateway);
  final AuthenticatedWorkspaceCatalogueGateway gateway;
  @override
  Future<BuyV2CommerceSnapshot> refresh() => gateway.readProcurementAccess();
}

/// Explicit review-build responses for the existing synthetic Store only.
/// They exercise the normal eligibility contract, never real purchasing authority.
/// No transport, payment, order creation or recipient action is available.
/// Supplier-published arrangements are either public or granted to an exact buyer Store.
/// This is an access filter, not a credit score or an automatic approval.
class WorkSupplierPaymentAccess {
  WorkSupplierPaymentAccess({
    required this.supplierId,
    required Set<String> publicTermIds,
    Map<(String, String), Set<String>> storeTermIds = const {},
  }) : publicTermIds = Set.unmodifiable(publicTermIds),
       storeTermIds = Map.unmodifiable({
         for (final entry in storeTermIds.entries)
           entry.key: Set<String>.unmodifiable(entry.value),
       });
  final String supplierId;
  final Set<String> publicTermIds;
  final Map<(String, String), Set<String>> storeTermIds;

  bool permits(
    String termId, {
    required String supplier,
    required String account,
    required String store,
  }) =>
      supplier == supplierId &&
      account.isNotEmpty &&
      store.isNotEmpty &&
      (publicTermIds.contains(termId) ||
          storeTermIds[(account, store)]?.contains(termId) == true);
}

class _StoreReviewProcurementCatalogue
    implements
        BuyV2CommerceAdapter,
        BuyV2CataloguePageSource,
        BuyV2CommercialPaymentTermsAdapter {
  _StoreReviewProcurementCatalogue(this.context, {required this.current});
  final BuyV2ProcurementContext context;
  final bool Function() current;
  final _source = BuyV2DevelopmentCatalogueSource(
    destination: BuyV2Destination.wholesale,
    providerCount: 24,
    skusPerStore: 24,
  );
  static const _notice =
      'Test catalogue. Orders, payments and messages are unavailable.';
  void _requireCurrent([BuyV2CatalogueQuery? query]) {
    if (!current() ||
        (query != null &&
            (query.destination != BuyV2Destination.wholesale ||
                query.procurementContext?.customerStateOwnerScope !=
                    context.customerStateOwnerScope))) {
      throw StateError('Review catalogue scope changed');
    }
  }

  BuyV2Product _product(BuyV2Product product) => product.copyWith(
    seller: 'TEST · ${product.seller}',
    procurementSupplierGrant: BuyV2ProcurementSupplierGrant(
      workspaceId: 'review-workspace-${product.storeId}',
      storeId: product.storeId!,
      role: BuyV2SupplierWorkspaceRole.wholesaler,
      approved: true,
      listingId: product.id,
      productCanonicalId: product.canonicalId,
      offerId: 'review-offer-${product.id}',
      offerRevision: '1',
      channel: BuyV2SupplierListingChannel.wholesale,
      published: true,
      validUntil: DateTime.now().add(const Duration(minutes: 15)),
    ),
  );

  BuyV2CataloguePage<R> _map<T, R>(
    BuyV2CataloguePage<T> page,
    R Function(T) convert,
  ) => BuyV2CataloguePage<R>(
    queryKey: page.queryKey,
    snapshotId: page.snapshotId,
    items: page.items.map(convert),
    startIndex: page.startIndex,
    totalCount: page.totalCount,
    previousCursor: page.previousCursor,
    nextCursor: page.nextCursor,
  );

  @override
  Future<BuyV2CataloguePage<BuyV2StoreListing>> loadStores(
    BuyV2CatalogueQuery query, {
    String? cursor,
    required int pageSize,
  }) async {
    _requireCurrent(query);
    final page = await _source.loadStores(
      query,
      cursor: cursor,
      pageSize: pageSize,
    );
    _requireCurrent(query);
    return _map(
      page,
      (store) => BuyV2StoreListing(
        id: store.id,
        name: 'TEST · ${store.name}',
        area: store.area,
        address: store.address,
        regionId: store.regionId,
        publicContactPhone: store.publicContactPhone,
        openingHoursLabel: store.openingHoursLabel,
        previewProduct: store.previewProduct == null
            ? null
            : _product(store.previewProduct!),
      ),
    );
  }

  @override
  Future<BuyV2CataloguePage<BuyV2Product>> loadProducts(
    BuyV2CatalogueQuery query, {
    String? cursor,
    required int pageSize,
  }) async {
    _requireCurrent(query);
    final page = await _source.loadProducts(
      query,
      cursor: cursor,
      pageSize: pageSize,
    );
    _requireCurrent(query);
    return _map(page, _product);
  }

  @override
  Future<List<BuyV2Product>> resolveProducts(Set<String> ids) async {
    _requireCurrent();
    final products = await _source.resolveProducts(ids);
    _requireCurrent();
    return products.map(_product).toList();
  }

  @override
  Future<BuyV2CommerceSnapshot> refresh() async {
    _requireCurrent();
    final page = await loadProducts(
      BuyV2CatalogueQuery(
        destination: BuyV2Destination.wholesale,
        regionId: 'jodhpur',
        procurementContext: context,
      ),
      pageSize: 24,
    );
    return BuyV2CommerceSnapshot(
      state: BuyV2CommerceLoadState.ready,
      products: page.items,
      paymentMethods: BuyV2Session.storePaymentMethods,
      selectedAddressId: 'test-store-delivery',
      addresses: const [
        BuyV2Address(
          id: 'test-store-delivery',
          kind: BuyV2AddressKind.work,
          label: 'TEST Store delivery',
          recipient: 'TEST Store receiving team',
          phone: '9000000001',
          line: 'TEST delivery address',
          area: 'Jodhpur',
          pinCode: '342001',
          landmark: 'TEST location',
        ),
      ],
      businessVerified: true,
      businessVerificationState: BuyV2BusinessVerificationState.verified,
      procurementBuyerGrant: BuyV2ProcurementBuyerGrant(
        accountId: context.accountId,
        storeId: context.storeId,
        approved: true,
        validUntil: DateTime.now().add(const Duration(minutes: 15)),
      ),
    );
  }

  @override
  Future<BuyV2CommercialPaymentTermsSnapshot> loadTerms({
    required List<BuyV2FulfilmentGroup> groups,
    required String selectedPaymentMethod,
    required Map<String, int> quotedTotalsByFulfilmentKey,
  }) async {
    _requireCurrent();
    final terms = <BuyV2CommercialPaymentTerm>[];
    for (final group in groups) {
      if (group.destination != BuyV2Destination.wholesale) continue;
      final total = quotedTotalsByFulfilmentKey[group.key];
      if (total == null || total <= 0) continue;
      // The existing test supplier offers full payment or payment at delivery.
      // No buyer is assigned credit permission by this fixture.
      final access = WorkSupplierPaymentAccess(
        supplierId: group.partner,
        publicTermIds: {'advance', 'delivery'},
      );
      void add(
        String id,
        BuyV2CommercialPaymentTermKind kind,
        int percent, {
        int? days,
      }) {
        if (!access.permits(
          id,
          supplier: group.partner,
          account: context.accountId,
          store: context.storeId,
        )) {
          return;
        }
        final now = (total * percent + 99) ~/ 100;
        terms.add(
          BuyV2CommercialPaymentTerm(
            id: 'test-${group.key}-$id',
            fulfilmentKey: group.key,
            destination: group.destination,
            supplierName: group.partner,
            kind: kind,
            orderTotal: total,
            amountDueNow: now,
            balanceDue: total - now,
            balanceDueLabel: percent == 100
                ? 'No balance due'
                : days == null
                ? 'at confirmed delivery'
                : 'within $days days of confirmed delivery',
            sourceId: 'TEST-supplier-payment-terms',
            advancePercent: percent,
            acceptedPaymentMethods: BuyV2Session.storePaymentMethods,
            upiTransactionLimit: 100000,
            netDays: days,
            supplierIsMicroOrSmall: true,
          ),
        );
      }

      add('advance', BuyV2CommercialPaymentTermKind.wholesaleAdvance, 100);
      add('delivery', BuyV2CommercialPaymentTermKind.paymentOnDelivery, 0);
      for (final percent in [5, 10, 15, 20, 25]) {
        add(
          'advance-$percent-delivery',
          BuyV2CommercialPaymentTermKind.bookingBalanceOnDelivery,
          percent,
        );
        add(
          'advance-$percent-credit-45',
          BuyV2CommercialPaymentTermKind.supplierCredit,
          percent,
          days: 45,
        );
      }
      for (final days in [1, 7, 15, 30, 45]) {
        add(
          'credit-$days',
          BuyV2CommercialPaymentTermKind.supplierCredit,
          0,
          days: days,
        );
      }
    }
    return BuyV2CommercialPaymentTermsSnapshot(
      state: BuyV2CommerceLoadState.ready,
      terms: terms,
    );
  }

  @override
  Future<BuyV2OrderPlacementResult> placeOrder(
    BuyV2OrderPlacementRequest request,
  ) async => const BuyV2OrderPlacementResult(
    outcome: BuyV2OrderPlacementOutcome.unavailable,
    customerMessage: _notice,
  );
  @override
  Future<BuyV2OrderPlacementResult> reconcileOrder({
    required String idempotencyKey,
    required String paymentReference,
  }) async => const BuyV2OrderPlacementResult(
    outcome: BuyV2OrderPlacementOutcome.unavailable,
    customerMessage: _notice,
  );
  @override
  Future<BuyV2OrderRefreshResult> refreshOrder({
    required String orderId,
  }) async => const BuyV2OrderRefreshResult(
    state: BuyV2CommerceLoadState.unavailable,
    customerMessage: _notice,
  );
  @override
  Future<BuyV2OrderAlertsResult> loadOrderAlerts() async =>
      const BuyV2OrderAlertsResult(
        available: false,
        enabled: false,
        customerMessage: _notice,
      );
  @override
  Future<BuyV2OrderAlertsResult> setOrderAlerts({required bool enabled}) =>
      loadOrderAlerts();
  @override
  Future<BuyV2MutationResult> submitProductReview({
    required BuyV2Product product,
    required int rating,
    required String comment,
  }) async =>
      const BuyV2MutationResult(accepted: false, customerMessage: _notice);
  @override
  Future<BuyV2MutationResult> reportProduct({
    required BuyV2Product product,
    required String reason,
  }) async =>
      const BuyV2MutationResult(accepted: false, customerMessage: _notice);
  @override
  Future<BuyV2AddressRequestResult> createAddressRequest({
    String recipient = '',
  }) async => const BuyV2AddressRequestResult(customerMessage: _notice);
}

/// Durable Store navigation identity, never a buyer/supplier approval grant.
class WorkProcurementBookmark {
  const WorkProcurementBookmark({
    required this.context,
    required this.returnTo,
    this.active = true,
    this.uiPurpose,
    this.uiProfileId,
  });
  final BuyV2ProcurementContext context;
  final String returnTo;
  final bool active;
  final Object? uiPurpose, uiProfileId;
  WorkRestockPurchasePurpose? get restockPurpose => WorkRestockPurchasePurpose.values
    .where((choice) => choice.name == uiPurpose).firstOrNull;
  static const returnDestinations = {
    'dashboard',
    'stockStatement',
    'sourcing',
    'direct',
    'groupBuying',
  };

  Map<String, Object?> toJson() => {
    'version': uiPurpose == null && uiProfileId == null ? 1 : 2,
    'active': active,
    'accountId': context.accountId,
    'storeId': context.storeId,
    'purpose': context.purpose.name,
    'originOperationId': context.originOperationId,
    'returnTo': returnTo,
    if (uiPurpose != null || uiProfileId != null) ...{'uiPurpose': uiPurpose, 'uiProfileId': uiProfileId},
  };

  static WorkProcurementBookmark? decode(
    Map<String, Object?> value, {
    required String accountId,
    required String storeId,
  }) {
    if (!(value['version'] == 1 || value['version'] == 2 && value.containsKey('uiPurpose') && value.containsKey('uiProfileId')) ||
        value['active'] is! bool ||
        value['accountId'] != accountId ||
        value['storeId'] != storeId ||
        !returnDestinations.contains(value['returnTo'])) {
      return null;
    }
    final operation = value['originOperationId'];
    if (operation is! String ||
        operation.isEmpty ||
        operation.trim() != operation) {
      return null;
    }
    final purpose = BuyV2ProcurementPurpose.values
        .where((item) => item.name == value['purpose'])
        .firstOrNull;
    if (purpose == null) return null;
    final context = BuyV2ProcurementContext(
      accountId: accountId,
      storeId: storeId,
      purpose: purpose,
      originOperationId: operation,
    );
    if (!context.hasIdentity) return null;
    return WorkProcurementBookmark(
      context: context,
      returnTo: value['returnTo'] as String,
      active: value['active'] as bool,
      uiPurpose: value['version'] == 2 ? value['uiPurpose'] : null,
      uiProfileId: value['version'] == 2 ? value['uiProfileId'] : null,
    );
  }
}

abstract interface class WorkProcurementBookmarkStore {
  Future<WorkProcurementBookmark?> read(String accountId, String storeId);
  Future<bool> save(WorkProcurementBookmark bookmark);
  Future<bool> clear(String accountId, String storeId);
}

/// Uses its own account/Store namespace; never overwrites onboarding drafts.
class SecureWorkProcurementBookmarkStore
    implements WorkProcurementBookmarkStore {
  const SecureWorkProcurementBookmarkStore();
  static const _storage = FlutterSecureStorage();
  String _key(String accountId, String storeId) =>
      'moolsocial.work.procurement.v1:${Uri.encodeComponent(accountId)}:${Uri.encodeComponent(storeId)}';

  @override
  Future<WorkProcurementBookmark?> read(
    String accountId,
    String storeId,
  ) async {
    if (accountId.isEmpty || storeId.isEmpty) return null;
    final raw = await _storage.read(key: _key(accountId, storeId));
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid Store purchase bookmark');
    }
    final bookmark = WorkProcurementBookmark.decode(
      decoded,
      accountId: accountId,
      storeId: storeId,
    );
    if (bookmark == null) {
      throw const FormatException('Invalid Store purchase bookmark');
    }
    return bookmark;
  }

  @override
  Future<bool> save(WorkProcurementBookmark bookmark) async {
    if (!bookmark.context.hasIdentity ||
        !WorkProcurementBookmark.returnDestinations.contains(
          bookmark.returnTo,
        )) {
      return false;
    }
    try {
      await _storage.write(
        key: _key(bookmark.context.accountId, bookmark.context.storeId),
        value: jsonEncode(bookmark.toJson()),
      );
      return true;
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> clear(String accountId, String storeId) async {
    if (accountId.isEmpty || storeId.isEmpty) return false;
    try {
      await _storage.delete(key: _key(accountId, storeId));
      return true;
    } on Object {
      return false;
    }
  }
}

const moolSocialWorkspaceUrl = String.fromEnvironment(
  'MOOLSOCIAL_WORKSPACE_URL',
);

class WorkGatewayException implements Exception {
  const WorkGatewayException(
    this.message, {
    this.retryable = false,
    this.cancelled = false,
  });
  final String message;
  final bool retryable;
  final bool cancelled;
  @override
  String toString() => message;
}

enum WorkProofSource { camera, gallery, upload, cloudDrive }

class WorkPickedProof {
  const WorkPickedProof({
    required this.fileName,
    required this.contentType,
    required this.bytes,
    this.recoveryPath,
  });

  final String fileName;
  final String contentType;
  final Uint8List bytes;
  final String? recoveryPath;

  Map<String, Object?>? get recoveryRecord => recoveryPath == null
      ? null
      : {
          'name': fileName,
          'contentType': contentType,
          'path': recoveryPath!,
          'size': bytes.length,
          'sha256': crypto.sha256.convert(bytes).toString(),
        };
}

abstract interface class WorkProofPicker {
  Future<WorkPickedProof?> pick(WorkProofSource source);
}

abstract interface class WorkRecoverableProofPicker implements WorkProofPicker {
  Future<WorkPickedProof?> recover(WorkProofSource source);
}

abstract interface class WorkRetainedProofPicker implements WorkProofPicker {
  Future<WorkPickedProof?> restoreRecorded(Map<String, Object?> record);
}

/// A short-lived checkpoint for one external document-picker operation.
/// OTP codes, tokens, document bytes and Workspace approvals are never stored.
abstract interface class WorkPendingProofStore {
  String? get accountScope;
  Future<Map<String, Object?>?> read(String scope);
  Future<void> save(String scope, Map<String, Object?> draft);
  Future<void> clear(String scope);
}

class SecureWorkPendingProofStore implements WorkPendingProofStore {
  SecureWorkPendingProofStore({this.reviewOnly = false})
    : _contactDraft = false, _offerStoreId = null, _customerTermsId = null, _pickupPreferences = false, _publicationPreferences = false, _tradingPreferences = false;
  SecureWorkPendingProofStore.contactDraft({this.reviewOnly = false})
    : _contactDraft = true, _offerStoreId = null, _customerTermsId = null, _pickupPreferences = false, _publicationPreferences = false, _tradingPreferences = false;
  SecureWorkPendingProofStore.offerDraft(String storeId, {this.reviewOnly = false})
    : _contactDraft = false, _offerStoreId = storeId, _customerTermsId = null, _pickupPreferences = false, _publicationPreferences = false, _tradingPreferences = false;
  SecureWorkPendingProofStore.pickupPreferences(String storeId, {this.reviewOnly = false})
    : _contactDraft = false, _offerStoreId = storeId, _customerTermsId = null, _pickupPreferences = true, _publicationPreferences = false, _tradingPreferences = false;
  SecureWorkPendingProofStore.publicationPreferences(String storeId, {this.reviewOnly = false})
    : _contactDraft = false, _offerStoreId = storeId, _customerTermsId = null, _pickupPreferences = false, _publicationPreferences = true, _tradingPreferences = false;
  SecureWorkPendingProofStore.tradingPreferences(String storeId, {this.reviewOnly = false})
    : _contactDraft = false, _offerStoreId = storeId, _customerTermsId = null, _pickupPreferences = false, _publicationPreferences = false, _tradingPreferences = true;
  SecureWorkPendingProofStore.customerPaymentTerms(String storeId, String customerId, {this.reviewOnly = false})
    : _contactDraft = false, _offerStoreId = storeId, _customerTermsId = customerId,
      _pickupPreferences = false, _publicationPreferences = false, _tradingPreferences = false;
  final bool reviewOnly;
  final bool _contactDraft;
  final bool _pickupPreferences;
  final bool _publicationPreferences;
  final bool _tradingPreferences;
  final String? _offerStoreId;
  final String? _customerTermsId;
  static final Map<String, Future<void>> _offerWrites = {};
  static const _storage = FlutterSecureStorage();
  bool get _review =>
      reviewOnly &&
      kDebugMode &&
      const bool.fromEnvironment('MOOLSOCIAL_UI_REVIEW_ONLY') &&
      const bool.fromEnvironment('MOOLSOCIAL_DEVICE_REVIEW');
  String get _key => _review
      ? 'moolsocial.workspace.pending-proof.review.v1'
      : 'moolsocial.workspace.pending-proof.v1';

  String _scopedKey(String scope) => _offerStoreId != null
      ? 'moolsocial.workspace.${_customerTermsId != null ? 'customer-payment-terms' : _tradingPreferences ? 'trading-preferences' : _publicationPreferences ? 'publication-inputs' : _pickupPreferences ? 'pickup-preferences' : 'offer-draft'}.${_review ? 'review.' : ''}v1.'
          '${Uri.encodeComponent(scope)}/${Uri.encodeComponent(_offerStoreId)}${_customerTermsId == null ? '' : '/${Uri.encodeComponent(_customerTermsId)}'}'
      : _contactDraft
      ? 'moolsocial.workspace.contact-draft.${_review ? 'review.' : ''}v1.${Uri.encodeComponent(scope)}'
      : _key;

  @override
  String? get accountScope {
    if (_review) return 'isolated-workspace-ui-review';
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } on Object {
      return null;
    }
  }

  @override
  Future<Map<String, Object?>?> read(String scope) async {
    if (scope != accountScope) return null;
    if (_offerStoreId != null) {
      await _offerWrites[_scopedKey(scope)]?.timeout(const Duration(seconds: 10));
    }
    final value = await _storage
        .read(key: _scopedKey(scope))
        .timeout(const Duration(seconds: 10));
    if (value == null || scope != accountScope) return null;
    final decoded = jsonDecode(value);
    if (decoded is! Map ||
        decoded['scope'] != scope ||
        decoded['draft'] is! Map) {
      if (_offerStoreId != null) {
        throw WorkGatewayException(_customerTermsId != null
            ? 'Your saved private customer preferences could not be opened.'
            : _tradingPreferences
            ? 'Your saved Store hours and alerts could not be opened.'
            : _publicationPreferences
            ? 'Your saved Store defaults could not be opened.'
            : _pickupPreferences
            ? 'Your saved pickup preferences could not be opened.'
            : 'Your saved offer draft could not be opened.');
      }
      return null;
    }
    return Map<String, Object?>.from(decoded['draft'] as Map);
  }

  @override
  Future<void> save(String scope, Map<String, Object?> draft) async {
    if (scope != accountScope) {
      throw const WorkGatewayException(
        'Sign in again before adding a document.',
      );
    }
    if (_offerStoreId != null) {
      if (_offerStoreId.trim().isEmpty || _offerStoreId != _offerStoreId.trim() ||
          _customerTermsId != null && (_customerTermsId.trim().isEmpty || _customerTermsId != _customerTermsId.trim())) {
        throw const WorkGatewayException('Choose a Store before saving this draft.');
      }
      final key = _scopedKey(scope);
      final encoded = jsonEncode({'scope': scope, 'draft': draft});
      final write = (_offerWrites[key] ?? Future<void>.value()).then((_) async {
        if (scope != accountScope) {
          throw const WorkGatewayException('Sign in again before saving this draft.');
        }
        // A caller deadline cannot cancel the platform write. Keep the queue
        // bound to its real completion so a late old write cannot replace a
        // newer offer or pickup preference after timeout.
        await _storage.write(key: key, value: encoded);
      });
      final tail = write.then<void>((_) {}, onError: (Object _, StackTrace _) {});
      _offerWrites[key] = tail;
      unawaited(tail.then((_) { if (identical(_offerWrites[key], tail)) _offerWrites.remove(key); }));
      await write.timeout(const Duration(seconds: 10));
      return;
    }
    await _storage
        .write(
          key: _scopedKey(scope),
          value: jsonEncode({'scope': scope, 'draft': draft}),
        )
        .timeout(const Duration(seconds: 10));
  }

  @override
  Future<void> clear(String scope) async {
    if (await read(scope) != null && scope == accountScope) {
      await _storage
          .delete(key: _scopedKey(scope))
          .timeout(const Duration(seconds: 10));
    }
  }
}

abstract interface class WorkIssueDraftStore {
  Future<WorkspaceIssueDraft?> read(WorkspaceIssueDraftKey key);
  Future<void> save(WorkspaceIssueDraft draft);
}

abstract interface class WorkPurchasedUnitDraftStore {
  Future<WorkspacePurchasedUnitDraft?> read(WorkspacePurchasedUnitDraftKey key);
  Future<void> save(WorkspacePurchasedUnitDraft draft, {required int? expectedRevision});
}

abstract interface class WorkLedgerFormDraftStore {
  Future<WorkspaceLedgerFormDraft?> read(WorkspaceLedgerFormKey key);
  Future<void> save(
    WorkspaceLedgerFormDraft draft, {
    required int? expectedRevision,
  });
}

/// Serializes frozen manual money attempts against draft edits and reset.
abstract interface class WorkSupplierMoneyDraftGuard {
  Future<bool> withFrozenSupplierMoney(WorkspaceLedgerFormKey key, String attempt,
      Future<bool> Function() action);
  Future<void> resetConfirmedSupplierMoneyDraft(WorkspaceLedgerFormDraft next, {
    required int expectedRevision,
    required Future<bool> Function(WorkspaceSupplierLedgerEntry entry) verifyCommitted,
  });
}

/// Uses the existing encrypted draft storage approach; never financial authority.
abstract interface class WorkSupplierAllocationDraftGuard {
  Future<bool> withFrozenSupplierAllocation(WorkspaceLedgerFormKey key, String intent,
      Future<bool> Function() action);
  Future<void> resetConfirmedSupplierAllocationDraft(WorkspaceLedgerFormDraft next, {
    required int expectedRevision,
    required Future<bool> Function(WorkspaceSupplierMoneyAllocationIntent intent) verifyCommitted,
  });
}

abstract interface class WorkSupplierGoodsReturnDraftGuard {
  Future<bool> withFrozenSupplierGoodsReturn(WorkspaceLedgerFormKey key, String intent,
      Future<bool> Function() action);
  Future<void> cancelUnpostedSupplierGoodsReturnDraft(WorkspaceLedgerFormDraft next, {
    required int expectedRevision,
    required WorkspaceSupplierGoodsReturnIntent intent,
    required DateTime cancelledAt,
    required bool Function() isCurrent,
    required Future<bool> Function(WorkspaceSupplierGoodsReturnIntent intent) verifyUnposted,
  });
  Future<void> resetConfirmedSupplierGoodsReturnDraft(WorkspaceLedgerFormDraft next, {
    required int expectedRevision,
    required Future<bool> Function(WorkspaceSupplierGoodsReturnIntent intent) verifyCommitted,
  });
}

abstract interface class WorkSupplierCreditDraftGuard {
  Future<bool> withFrozenSupplierCredit(WorkspaceLedgerFormKey key, String intent,
      Future<bool> Function() action);
  Future<void> resetConfirmedSupplierCreditDraft(WorkspaceLedgerFormDraft next, {
    required int expectedRevision,
    required Future<bool> Function(WorkspaceSupplierCreditIntent intent) verifyCommitted,
  });
}

abstract interface class WorkSupplierRefundDraftGuard {
  Future<bool> withFrozenSupplierRefund(WorkspaceLedgerFormKey key, String intent,
      Future<bool> Function() action);
  Future<void> resetConfirmedSupplierRefundDraft(WorkspaceLedgerFormDraft next, {
    required int expectedRevision,
    required Future<bool> Function(WorkspaceSupplierRefundIntent intent) verifyCommitted,
  });
}

abstract interface class WorkSupplierShortageDraftGuard {
  Future<bool> withFrozenSupplierShortage(WorkspaceLedgerFormKey key, String intent,
      Future<bool> Function() action);
  Future<void> resetConfirmedSupplierShortageDraft(WorkspaceLedgerFormDraft next, {
    required int expectedRevision,
    required Future<bool> Function(WorkspaceSupplierShortageIntent intent) verifyCommitted,
  });
}

class SecureWorkLedgerFormDraftStore implements WorkLedgerFormDraftStore, WorkSupplierMoneyDraftGuard,
    WorkSupplierAllocationDraftGuard, WorkSupplierGoodsReturnDraftGuard, WorkSupplierCreditDraftGuard,
    WorkSupplierShortageDraftGuard, WorkSupplierRefundDraftGuard {
  SecureWorkLedgerFormDraftStore({
    required this.accountScope,
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();
  final String? Function() accountScope;
  final FlutterSecureStorage _storage;
  static final _pending = <String, Future<void>>{};
  String _key(WorkspaceLedgerFormKey key) =>
      'moolsocial.workspace.ledger-form.v1.${[key.account, key.store, key.customer, key.invoice, key.order, key.kind, '${key.ledgerRevision}'].map(Uri.encodeComponent).join('/')}';
  void _check(WorkspaceLedgerFormKey key) {
    if (key.account != accountScope() ||
        !WorkspaceLedgerFormDraft(
          key: key,
          revision: 1,
          fields: const {},
        ).valid) {
      throw const WorkGatewayException('Return to the correct Store invoice.');
    }
  }

  Future<T> _serial<T>(String key, Future<T> Function() action) {
    final result = (_pending[key] ?? Future<void>.value()).then(
      (_) => action(),
    );
    final tail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _pending[key] = tail;
    unawaited(
      tail.then((_) {
        if (identical(_pending[key], tail)) {
          _pending.remove(key);
        }
      }),
    );
    return result;
  }

  Future<WorkspaceLedgerFormDraft?> _read(WorkspaceLedgerFormKey key) async {
    _check(key);
    final raw = await _storage.read(key: _key(key));
    _check(key);
    if (raw == null) {
      return null;
    }
    WorkspaceLedgerFormDraft? draft;
    try {
      draft = WorkspaceLedgerFormDraft.fromJson(jsonDecode(raw));
    } on FormatException {
      // Preserve unreadable data rather than replacing it with an empty form.
    }
    if (draft == null || draft.key != key) {
      throw const WorkGatewayException(
        'Saved invoice input could not be opened.',
      );
    }
    return draft;
  }

  @override
  Future<WorkspaceLedgerFormDraft?> read(WorkspaceLedgerFormKey key) =>
      _serial(_key(key), () => _read(key));

  String _returnCancellationKey(WorkspaceLedgerFormKey key, String operation) =>
      '${_key(key)}.cancelled-return.${Uri.encodeComponent(operation)}';

  Future<Map<String, dynamic>?> _returnCancellation(WorkspaceLedgerFormKey key, String operation) async {
    _check(key);
    final raw = await _storage.read(key: _returnCancellationKey(key, operation));
    _check(key);
    if (raw == null) return null;
    try {
      final value = jsonDecode(raw);
      if (value is! Map<String, dynamic> || value.length != 4 || value['schema'] != 1) {
        throw const FormatException('Invalid cancellation');
      }
      final prior = WorkspaceLedgerFormDraft.fromJson(value['previous']);
      final next = WorkspaceLedgerFormDraft.fromJson(value['next']);
      final at = DateTime.tryParse(value['cancelledAt'] as String);
      if (prior == null || next == null || prior.key != key || next.key != key ||
          prior.supplierGoodsReturnIntent?.operationId != operation || next.supplierGoodsReturnIntent != null ||
          next.revision != prior.revision + 1 || at == null || !at.isUtc ||
          at.isBefore(prior.supplierGoodsReturnIntent!.requestedAt) || at.isAfter(DateTime.now().toUtc())) {
        throw const FormatException('Invalid cancellation identity');
      }
      return value;
    } on Object {
      throw const WorkGatewayException('Saved return cancellation is unavailable. Keep the review and recover it.');
    }
  }
  @override
  Future<void> save(
    WorkspaceLedgerFormDraft draft, {
    required int? expectedRevision,
  }) => _serial(_key(draft.key), () async {
    _check(draft.key);
    if (!draft.valid || draft.revision != (expectedRevision ?? 0) + 1) {
      throw const WorkGatewayException('Invoice input could not be saved.');
    }
    final returnIntent = draft.supplierGoodsReturnIntent;
    if (returnIntent != null && await _returnCancellation(draft.key, returnIntent.operationId) != null) {
      throw const WorkGatewayException('This return review was cancelled. Review corrected details as a new return.');
    }
    final previous = await _read(draft.key);
    final encoded = jsonEncode(draft.toJson());
    if (previous != null && jsonEncode(previous.toJson()) == encoded) {
      return;
    }
    if (previous?.revision != expectedRevision) {
      throw const WorkGatewayException(
        'Saved invoice input changed. Reopen it first.',
      );
    }
    if ((previous?.supplierMoneyAttempt != null || previous?.supplierAllocationIntent != null ||
        previous?.supplierGoodsReturnIntent != null || previous?.supplierCreditIntent != null ||
        previous?.supplierShortageIntent != null || previous?.supplierRefundIntent != null) &&
        jsonEncode(previous!.fields) != jsonEncode(draft.fields)) {
      throw const WorkGatewayException('This payment attempt is retained. Verify its saved status before recording another.');
    }
    await _storage.write(key: _key(draft.key), value: encoded);
    _check(draft.key);
  });

  @override
  Future<bool> withFrozenSupplierRefund(WorkspaceLedgerFormKey key, String intent,
      Future<bool> Function() action) => _serial(_key(key), () async {
    final draft = await _read(key);
    if (key.kind != 'supplierRefund' || draft?.supplierRefundIntent == null || draft!.fields['attempt'] != intent) {
      throw const WorkGatewayException('Reopen the saved supplier refund before retrying.');
    }
    final result = await action();
    _check(key);
    return result;
  });

  @override
  Future<void> resetConfirmedSupplierRefundDraft(WorkspaceLedgerFormDraft next, {
    required int expectedRevision,
    required Future<bool> Function(WorkspaceSupplierRefundIntent intent) verifyCommitted,
  }) => _serial(_key(next.key), () async {
    _check(next.key);
    if (next.key.kind != 'supplierRefund' || !next.valid || next.supplierRefundIntent != null ||
        next.revision != expectedRevision + 1) {
      throw const WorkGatewayException('Saved supplier refund cannot be reset.');
    }
    final previous = await _read(next.key), encoded = jsonEncode(next.toJson());
    if (previous != null && jsonEncode(previous.toJson()) == encoded) return;
    if (previous?.revision != expectedRevision || previous?.supplierRefundIntent == null ||
        !await verifyCommitted(previous!.supplierRefundIntent!)) {
      throw const WorkGatewayException('Verify this exact refund before recording another.');
    }
    _check(next.key);
    await _storage.write(key: _key(next.key), value: encoded);
    _check(next.key);
  });

  @override
  Future<bool> withFrozenSupplierShortage(WorkspaceLedgerFormKey key, String intent,
      Future<bool> Function() action) => _serial(_key(key), () async {
    final draft = await _read(key);
    if (key.kind != 'supplierShortage' || draft?.supplierShortageIntent == null || draft!.fields['attempt'] != intent) {
      throw const WorkGatewayException('Reopen the saved short-delivery review before retrying.');
    }
    final result = await action();
    _check(key);
    return result;
  });

  @override
  Future<void> resetConfirmedSupplierShortageDraft(WorkspaceLedgerFormDraft next, {
    required int expectedRevision,
    required Future<bool> Function(WorkspaceSupplierShortageIntent intent) verifyCommitted,
  }) => _serial(_key(next.key), () async {
    _check(next.key);
    if (next.key.kind != 'supplierShortage' || !next.valid || next.supplierShortageIntent != null ||
        next.revision != expectedRevision + 1) {
      throw const WorkGatewayException('Saved short-delivery review cannot be reset.');
    }
    final previous = await _read(next.key), encoded = jsonEncode(next.toJson());
    if (previous != null && jsonEncode(previous.toJson()) == encoded) return;
    if (previous?.revision != expectedRevision || previous?.supplierShortageIntent == null ||
        !await verifyCommitted(previous!.supplierShortageIntent!)) {
      throw const WorkGatewayException('Verify this exact shortage record before starting another.');
    }
    _check(next.key);
    await _storage.write(key: _key(next.key), value: encoded);
    _check(next.key);
  });

  @override
  Future<bool> withFrozenSupplierCredit(WorkspaceLedgerFormKey key, String intent,
      Future<bool> Function() action) => _serial(_key(key), () async {
    final draft = await _read(key);
    if (key.kind != 'supplierCredit' || draft?.supplierCreditIntent == null || draft!.fields['attempt'] != intent) {
      throw const WorkGatewayException('Reopen the saved supplier credit request before retrying.');
    }
    final result = await action();
    _check(key);
    return result;
  });

  @override
  Future<void> resetConfirmedSupplierCreditDraft(WorkspaceLedgerFormDraft next, {
    required int expectedRevision,
    required Future<bool> Function(WorkspaceSupplierCreditIntent intent) verifyCommitted,
  }) => _serial(_key(next.key), () async {
    _check(next.key);
    if (next.key.kind != 'supplierCredit' || !next.valid || next.supplierCreditIntent != null ||
        next.revision != expectedRevision + 1) {
      throw const WorkGatewayException('Saved supplier credit request cannot be reset.');
    }
    final previous = await _read(next.key), encoded = jsonEncode(next.toJson());
    if (previous != null && jsonEncode(previous.toJson()) == encoded) return;
    if (previous?.revision != expectedRevision || previous?.supplierCreditIntent == null ||
        !await verifyCommitted(previous!.supplierCreditIntent!)) {
      throw const WorkGatewayException('Verify this exact supplier credit before starting another.');
    }
    _check(next.key);
    await _storage.write(key: _key(next.key), value: encoded);
    _check(next.key);
  });

  @override
  Future<bool> withFrozenSupplierMoney(WorkspaceLedgerFormKey key, String attempt,
      Future<bool> Function() action) => _serial(_key(key), () async {
    final draft = await _read(key);
    if (key.kind != 'supplierMoney' || draft?.supplierMoneyAttempt == null ||
        draft!.fields['attempt'] != attempt) {
      throw const WorkGatewayException('Reopen the saved payment attempt before retrying.');
    }
    final result = await action();
    _check(key);
    return result;
  });

  @override
  Future<void> resetConfirmedSupplierMoneyDraft(WorkspaceLedgerFormDraft next, {
    required int expectedRevision,
    required Future<bool> Function(WorkspaceSupplierLedgerEntry entry) verifyCommitted,
  }) => _serial(_key(next.key), () async {
    _check(next.key);
    if (next.key.kind != 'supplierMoney' || !next.valid ||
        next.supplierMoneyAttempt != null || next.revision != expectedRevision + 1) {
      throw const WorkGatewayException('Saved payment input cannot be reset.');
    }
    final previous = await _read(next.key);
    final encoded = jsonEncode(next.toJson());
    if (previous != null && jsonEncode(previous.toJson()) == encoded) return;
    if (previous?.revision != expectedRevision || previous?.supplierMoneyAttempt == null ||
        !await verifyCommitted(previous!.supplierMoneyAttempt!.entry)) {
      throw const WorkGatewayException('Verify this exact recorded payment before starting another.');
    }
    _check(next.key);
    await _storage.write(key: _key(next.key), value: encoded);
    _check(next.key);
  });

  @override
  Future<bool> withFrozenSupplierAllocation(WorkspaceLedgerFormKey key, String intent,
      Future<bool> Function() action) => _serial(_key(key), () async {
    final draft = await _read(key);
    if (key.kind != 'supplierAllocation' || draft?.supplierAllocationIntent == null ||
        draft!.fields['attempt'] != intent) {
      throw const WorkGatewayException('Reopen the saved bill allocation before retrying.');
    }
    final result = await action();
    _check(key);
    return result;
  });

  @override
  Future<bool> withFrozenSupplierGoodsReturn(WorkspaceLedgerFormKey key, String intent,
      Future<bool> Function() action) => _serial(_key(key), () async {
    final draft = await _read(key);
    if (key.kind != 'supplierGoodsReturn' || draft?.supplierGoodsReturnIntent == null ||
        draft!.fields['attempt'] != intent) {
      throw const WorkGatewayException('Reopen the saved goods return before retrying.');
    }
    if (await _returnCancellation(key, draft.supplierGoodsReturnIntent!.operationId) != null) {
      throw const WorkGatewayException('This return review was cancelled. Recover its correction before continuing.');
    }
    final result = await action();
    _check(key);
    return result;
  });

  @override
  Future<void> cancelUnpostedSupplierGoodsReturnDraft(WorkspaceLedgerFormDraft next, {
    required int expectedRevision,
    required WorkspaceSupplierGoodsReturnIntent intent,
    required DateTime cancelledAt,
    required bool Function() isCurrent,
    required Future<bool> Function(WorkspaceSupplierGoodsReturnIntent intent) verifyUnposted,
  }) => _serial(_key(next.key), () async {
    final key = next.key;
    void checkScope() {
      _check(key);
      if (!isCurrent()) {
        throw const WorkGatewayException('Return to the original Store to recover this review.');
      }
    }
    checkScope();
    if (key.kind != 'supplierGoodsReturn' || !next.valid || next.fields.containsKey('attempt') ||
        next.revision != expectedRevision + 1 || !intent.valid || !cancelledAt.isUtc ||
        cancelledAt.isBefore(intent.requestedAt) || cancelledAt.isAfter(DateTime.now().toUtc())) {
      throw const WorkGatewayException('Return review cannot be corrected. Recover its saved status.');
    }
    final archive = await _returnCancellation(key, intent.operationId);
    checkScope();
    final previous = await _read(key), encoded = jsonEncode(next.toJson());
    checkScope();
    if (archive != null) {
      final original = WorkspaceLedgerFormDraft.fromJson(archive['previous'])!;
      if (original.revision != expectedRevision ||
          jsonEncode(original.supplierGoodsReturnIntent!.toJson()) != jsonEncode(intent.toJson()) ||
          jsonEncode(archive['next']) != encoded) {
        throw const WorkGatewayException('Saved cancellation differs. Keep both reviews and recover.');
      }
      if (previous != null && jsonEncode(previous.toJson()) == encoded) {
        if (!await verifyUnposted(intent)) {
          throw const WorkGatewayException('Cancellation status is unverified. Recover the original supplier account.');
        }
        checkScope();
        return;
      }
    }
    if (previous?.revision != expectedRevision ||
        jsonEncode(previous?.supplierGoodsReturnIntent?.toJson()) != jsonEncode(intent.toJson()) ||
        !await verifyUnposted(intent)) {
      throw const WorkGatewayException('Return is recorded or its status is unverified. Recover before correcting.');
    }
    checkScope();
    if (archive == null) {
      final cancellation = {'schema': 1, 'previous': previous!.toJson(), 'next': next.toJson(),
        'cancelledAt': cancelledAt.toIso8601String()};
      await _storage.write(key: _returnCancellationKey(key, intent.operationId), value: jsonEncode(cancellation));
      checkScope();
      final verified = await _returnCancellation(key, intent.operationId);
      checkScope();
      if (jsonEncode(verified) != jsonEncode(cancellation)) {
        throw const WorkGatewayException('Cancellation save is unverified. Keep this review and retry correction.');
      }
    }
    // Posting shares this form queue. The immutable archive blocks the old
    // operation even if replacing the editable input loses its acknowledgment.
    await _storage.write(key: _key(key), value: encoded);
    checkScope();
  });

  @override
  Future<void> resetConfirmedSupplierGoodsReturnDraft(WorkspaceLedgerFormDraft next, {
    required int expectedRevision,
    required Future<bool> Function(WorkspaceSupplierGoodsReturnIntent intent) verifyCommitted,
  }) => _serial(_key(next.key), () async {
    _check(next.key);
    if (next.key.kind != 'supplierGoodsReturn' || !next.valid ||
        next.supplierGoodsReturnIntent != null || next.revision != expectedRevision + 1) {
      throw const WorkGatewayException('Saved goods return cannot be reset.');
    }
    final previous = await _read(next.key), encoded = jsonEncode(next.toJson());
    if (previous != null && jsonEncode(previous.toJson()) == encoded) return;
    if (previous?.revision != expectedRevision || previous?.supplierGoodsReturnIntent == null ||
        !await verifyCommitted(previous!.supplierGoodsReturnIntent!)) {
      throw const WorkGatewayException('Verify this exact goods return before starting another.');
    }
    _check(next.key);
    await _storage.write(key: _key(next.key), value: encoded);
    _check(next.key);
  });

  @override
  Future<void> resetConfirmedSupplierAllocationDraft(WorkspaceLedgerFormDraft next, {
    required int expectedRevision,
    required Future<bool> Function(WorkspaceSupplierMoneyAllocationIntent intent) verifyCommitted,
  }) => _serial(_key(next.key), () async {
    _check(next.key);
    if (next.key.kind != 'supplierAllocation' || !next.valid ||
        next.supplierAllocationIntent != null || next.revision != expectedRevision + 1) {
      throw const WorkGatewayException('Saved bill allocation cannot be reset.');
    }
    final previous = await _read(next.key);
    final encoded = jsonEncode(next.toJson());
    if (previous != null && jsonEncode(previous.toJson()) == encoded) return;
    if (previous?.revision != expectedRevision || previous?.supplierAllocationIntent == null ||
        !await verifyCommitted(previous!.supplierAllocationIntent!)) {
      throw const WorkGatewayException('Verify this exact bill allocation before starting another.');
    }
    _check(next.key);
    await _storage.write(key: _key(next.key), value: encoded);
    _check(next.key);
  });
}

/// Separate encrypted keys per account, Store and case. Drafts contain no OTP,
/// customer collection challenge, payment credential or decision authority.
class SecureWorkIssueDraftStore implements WorkIssueDraftStore {
  SecureWorkIssueDraftStore({
    required this.accountScope,
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final String? Function() accountScope;
  final FlutterSecureStorage _storage;
  String _key(WorkspaceIssueDraftKey key) =>
      'moolsocial.workspace.issue-draft.v1.'
      '${[key.account, key.store, key.caseId].map(Uri.encodeComponent).join('/')}';

  @override
  Future<WorkspaceIssueDraft?> read(WorkspaceIssueDraftKey key) async {
    if (key.account != accountScope()) return null;
    final value = await _storage
        .read(key: _key(key))
        .timeout(const Duration(seconds: 10));
    if (value == null || key.account != accountScope()) return null;
    final draft = WorkspaceIssueDraft.fromJson(jsonDecode(value));
    if (draft == null || draft.key != key) {
      throw const WorkGatewayException(
        'Your saved response could not be opened.',
      );
    }
    return draft;
  }

  @override
  Future<void> save(WorkspaceIssueDraft draft) async {
    if (!draft.valid || draft.key.account != accountScope()) {
      throw const WorkGatewayException('Sign in again to save your response.');
    }
    await _storage
        .write(key: _key(draft.key), value: jsonEncode(draft.toJson()))
        .timeout(const Duration(seconds: 10));
    if (draft.key.account != accountScope()) {
      throw const WorkGatewayException(
        'Sign in again to check your saved response.',
      );
    }
  }
}

/// Private device drafts have their own encrypted namespace, never a financial
/// ledger, published supplier record, buyer report or original-order payload.
class SecureWorkPurchasedUnitDraftStore implements WorkPurchasedUnitDraftStore {
  SecureWorkPurchasedUnitDraftStore({required this.accountScope, required this.targetScope, FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();
  final String? Function() accountScope, targetScope;
  final FlutterSecureStorage _storage;
  static final _tails = <String, Future<void>>{};
  String _key(WorkspacePurchasedUnitDraftKey key) => 'moolsocial.workspace.purchased-unit-draft.v1.'
    '${[key.account, key.realm, key.store, key.binding].map(Uri.encodeComponent).join('/')}';
  void _check(WorkspacePurchasedUnitDraftKey key) {
    if (!key.valid || key.account != accountScope() || key.identity != targetScope()) {
      throw const WorkGatewayException('Device draft access has changed. Your saved draft is kept.');
    }
  }
  Future<T> _serial<T>(String key, Future<T> Function() action) {
    final result = (_tails[key] ?? Future<void>.value()).then((_) => action());
    final tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    _tails[key] = tail;
    unawaited(tail.then((_) { if (identical(_tails[key], tail)) _tails.remove(key); }));
    return result;
  }
  Future<WorkspacePurchasedUnitDraft?> _read(WorkspacePurchasedUnitDraftKey key) async {
    _check(key);
    final raw = await _storage.read(key: _key(key)).timeout(const Duration(seconds: 10));
    _check(key);
    if (raw == null) return null;
    try {
      if (utf8.encode(raw).length > 1024 * 1024) throw const FormatException();
      final draft = WorkspacePurchasedUnitDraft.fromJson(jsonDecode(raw));
      if (draft.key.identity != key.identity) throw const FormatException();
      return draft;
    } on Object {
      throw const WorkGatewayException('Saved device draft needs recovery. Its data has been kept unchanged.');
    }
  }
  @override Future<WorkspacePurchasedUnitDraft?> read(WorkspacePurchasedUnitDraftKey key) =>
    _serial(_key(key), () => _read(key)).timeout(const Duration(seconds: 10));
  @override Future<void> save(WorkspacePurchasedUnitDraft draft, {required int? expectedRevision}) {
    final bytes = jsonEncode(draft.toJson());
    if (utf8.encode(bytes).length > 1024 * 1024) {
      return Future<void>.error(const WorkGatewayException('Device draft is too large to save. Your previous saved draft is kept.'));
    }
    final frozen = WorkspacePurchasedUnitDraft.fromJson(jsonDecode(bytes));
    return _serial(_key(frozen.key), () async {
      _check(frozen.key);
      final previous = await _read(frozen.key);
      if (previous != null && jsonEncode(previous.toJson()) == bytes) return;
      if (previous?.revision != expectedRevision || frozen.revision != (expectedRevision ?? 0) + 1) {
        throw const WorkGatewayException('Your device draft changed. Recover the saved draft before editing.');
      }
      _check(frozen.key);
      // Completion means actual native settlement. The editor bounds its UI
      // waiting separately so accepted coalesced edits can finish after exit.
      // Recovery cannot overtake an uncertain write and then overwrite it.
      await _storage.write(key: _key(frozen.key), value: bytes);
      _check(frozen.key);
    });
  }
}

abstract interface class WorkReceiptDraftStore {
  Future<WorkspaceReceiptDraft?> read(WorkspaceReceiptDraftKey key);
  Future<void> save(
    WorkspaceReceiptDraft draft, {
    required int? expectedRevision,
  });
}

/// Encrypted recovery of unsent receiving observations, never receipt authority.
/// Serialize reads/writes across local instances and compare the retained draft
/// revision. A slow native write must finish before a newer edit can be saved.
class SecureWorkReceiptDraftStore implements WorkReceiptDraftStore {
  SecureWorkReceiptDraftStore({
    required this.accountScope,
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final String? Function() accountScope;
  final FlutterSecureStorage _storage;
  static final Map<String, Future<void>> _pending = {};

  String _key(WorkspaceReceiptDraftKey key) =>
      'moolsocial.workspace.receipt-draft.v1.'
      '${[key.account, key.store, key.shipment].map(Uri.encodeComponent).join('/')}';

  Future<T> _exclusive<T>(String key, Future<T> Function() action) {
    final result = (_pending[key] ?? Future<void>.value()).then(
      (_) => action(),
    );
    final tail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _pending[key] = tail;
    unawaited(
      tail.then((_) {
        if (identical(_pending[key], tail)) _pending.remove(key);
      }),
    );
    return result;
  }

  void _check(WorkspaceReceiptDraftKey key) {
    if ([
          key.account,
          key.store,
          key.shipment,
        ].any((value) => value.trim().isEmpty) ||
        accountScope() != key.account) {
      throw const WorkGatewayException(
        'Sign in again to open this delivery draft.',
      );
    }
  }

  Future<WorkspaceReceiptDraft?> _read(WorkspaceReceiptDraftKey key) async {
    _check(key);
    final value = await _storage.read(key: _key(key));
    _check(key);
    if (value == null) return null;
    WorkspaceReceiptDraft? draft;
    try {
      draft = WorkspaceReceiptDraft.fromJson(jsonDecode(value));
    } on FormatException {
      // Corrupt retained bytes are not an empty draft that may be overwritten.
    }
    if (draft == null || draft.key != key) {
      throw const WorkGatewayException(
        'Your saved delivery draft could not be opened.',
      );
    }
    return draft;
  }

  @override
  Future<WorkspaceReceiptDraft?> read(WorkspaceReceiptDraftKey key) =>
      _exclusive(_key(key), () => _read(key));

  @override
  Future<void> save(
    WorkspaceReceiptDraft draft, {
    required int? expectedRevision,
  }) => _exclusive(_key(draft.key), () async {
    _check(draft.key);
    if (!draft.valid ||
        (expectedRevision != null && expectedRevision < 1) ||
        draft.revision != (expectedRevision ?? 0) + 1) {
      throw const WorkGatewayException(
        'This delivery draft could not be saved.',
      );
    }
    final current = await _read(draft.key);
    final value = jsonEncode(draft.toJson());
    if (current != null && jsonEncode(current.toJson()) == value) return;
    if (current?.revision != expectedRevision) {
      throw const WorkGatewayException(
        'This delivery draft changed. Open the saved version first.',
      );
    }
    // Receipt/return counts, problems and note can change; purchased identity and its source
    // snapshot cannot silently follow today's refreshed supplier catalogue.
    if (current != null) {
      final previous = current.toJson()
        ..remove('revision')
        ..remove('countedPacks')
        ..remove('returnedPacks')
        ..remove('problems')
        ..remove('note');
      final next = draft.toJson()
        ..remove('revision')
        ..remove('countedPacks')
        ..remove('returnedPacks')
        ..remove('problems')
        ..remove('note');
      if (jsonEncode(previous) != jsonEncode(next)) {
        throw const WorkGatewayException(
          'Keep the original delivery details with this draft.',
        );
      }
    }
    _check(draft.key);
    await _storage.write(key: _key(draft.key), value: value);
    _check(draft.key);
  });
}

abstract interface class WorkInvoiceDeliveryPreferenceStore {
  Future<WorkspaceInvoiceDeliveryPreference?> read(
    String account,
    String store,
  );
  Future<void> save(WorkspaceInvoiceDeliveryPreference preference);
}

/// Device-local encrypted preference only. No outbox, recipient or delivery claim.
class SecureWorkInvoiceDeliveryPreferenceStore
    implements WorkInvoiceDeliveryPreferenceStore {
  SecureWorkInvoiceDeliveryPreferenceStore({
    required this.accountScope,
    required this.storeScope,
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final String? Function() accountScope, storeScope;
  final FlutterSecureStorage _storage;
  static final Map<String, Future<void>> _pending = {};

  String _key(String account, String store) =>
      'moolsocial.workspace.invoice-delivery.v1.'
      '${Uri.encodeComponent(account)}/${Uri.encodeComponent(store)}';

  void _check(String account, String store) {
    if (account.trim().isEmpty ||
        store.trim().isEmpty ||
        accountScope() != account ||
        storeScope() != store) {
      throw const WorkGatewayException(
        'Return to your Store to change invoice delivery.',
      );
    }
  }

  Future<T> _exclusive<T>(String key, Future<T> Function() action) {
    final result = (_pending[key] ?? Future<void>.value()).then(
      (_) => action(),
    );
    final tail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _pending[key] = tail;
    unawaited(
      tail.then((_) {
        if (identical(_pending[key], tail)) _pending.remove(key);
      }),
    );
    return result;
  }

  Future<WorkspaceInvoiceDeliveryPreference?> _read(
    String account,
    String store,
  ) async {
    _check(account, store);
    final raw = await _storage.read(key: _key(account, store));
    _check(account, store);
    if (raw == null) return null;
    WorkspaceInvoiceDeliveryPreference? preference;
    try {
      preference = WorkspaceInvoiceDeliveryPreference.fromJson(jsonDecode(raw));
    } on FormatException {
      // Keep unreadable data; never silently enable or replace a saved choice.
    }
    if (preference == null ||
        preference.account != account ||
        preference.store != store) {
      throw const WorkGatewayException(
        'Your invoice delivery preference could not be opened.',
      );
    }
    return preference;
  }

  @override
  Future<WorkspaceInvoiceDeliveryPreference?> read(
    String account,
    String store,
  ) => _exclusive(_key(account, store), () => _read(account, store));

  @override
  Future<void> save(WorkspaceInvoiceDeliveryPreference preference) =>
      _exclusive(_key(preference.account, preference.store), () async {
        _check(preference.account, preference.store);
        if (!preference.valid) {
          throw const WorkGatewayException(
            'Check your invoice delivery preference.',
          );
        }
        await _read(preference.account, preference.store);
        _check(preference.account, preference.store);
        await _storage.write(
          key: _key(preference.account, preference.store),
          value: jsonEncode(preference.toJson()),
        );
        _check(preference.account, preference.store);
      });
}

abstract interface class WorkUpiDestinationStore {
  Future<WorkspaceUpiDestination?> read(String account, String store);
  Future<void> save(WorkspaceUpiDestination destination);
}

/// Device-local retailer settings. Never supplies bank verification or a
/// payment result. Account/Store checks bracket every asynchronous storage call.
class SecureWorkUpiDestinationStore implements WorkUpiDestinationStore {
  SecureWorkUpiDestinationStore({
    required this.accountScope,
    required this.storeScope,
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final String? Function() accountScope, storeScope;
  final FlutterSecureStorage _storage;
  static final Map<String, Future<void>> _pending = {};

  String _key(String account, String store) =>
      'moolsocial.workspace.upi-destination.v1.'
      '${Uri.encodeComponent(account)}/${Uri.encodeComponent(store)}';

  void _checkScope(String account, String store) {
    if (account.trim().isEmpty ||
        store.trim().isEmpty ||
        accountScope() != account ||
        storeScope() != store) {
      throw const WorkGatewayException('Return to your Store to set up UPI.');
    }
  }

  Future<T> _exclusive<T>(String key, Future<T> Function() action) {
    final result = (_pending[key] ?? Future<void>.value()).then(
      (_) => action(),
    );
    final tail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _pending[key] = tail;
    unawaited(
      tail.then((_) {
        if (identical(_pending[key], tail)) _pending.remove(key);
      }),
    );
    return result;
  }

  Future<WorkspaceUpiDestination?> _read(String account, String store) async {
    _checkScope(account, store);
    final raw = await _storage.read(key: _key(account, store));
    _checkScope(account, store);
    if (raw == null) return null;
    WorkspaceUpiDestination? destination;
    try {
      destination = WorkspaceUpiDestination.fromJson(jsonDecode(raw));
    } on FormatException {
      // Preserve corrupt saved data instead of silently replacing the payee.
    }
    if (destination == null ||
        destination.account != account ||
        destination.store != store) {
      throw const WorkGatewayException(
        'Your Store UPI details could not be opened.',
      );
    }
    return destination;
  }

  @override
  Future<WorkspaceUpiDestination?> read(String account, String store) =>
      _exclusive(_key(account, store), () => _read(account, store));

  @override
  Future<void> save(WorkspaceUpiDestination destination) =>
      _exclusive(_key(destination.account, destination.store), () async {
        _checkScope(destination.account, destination.store);
        if (!destination.valid) {
          throw const WorkGatewayException('Check your Store UPI details.');
        }
        await _read(destination.account, destination.store);
        _checkScope(destination.account, destination.store);
        await _storage.write(
          key: _key(destination.account, destination.store),
          value: jsonEncode(destination.toJson()),
        );
        _checkScope(destination.account, destination.store);
      });
}

abstract interface class WorkPurchaseEntryStore {
  Future<WorkspacePurchaseEntryBook?> read(String account, String store, {required bool qa});
  Future<void> save(WorkspacePurchaseEntryBook directory, {required int? expectedRevision});
}

/// Local confirmation must share the purchase writer's serialization boundary.
/// Production needs equivalent authoritative transaction semantics, not this lock.
abstract interface class WorkPurchaseEntryRevisionGuard {
  Future<bool> withReviewedBook(String account, String store, {
    required bool qa,
    required int expectedRevision,
    required Future<bool> Function(WorkspacePurchaseEntryBook book) action,
  });
}

/// Uses the same queue as review cancellation. No HTTP call belongs in this lock.
abstract interface class WorkPurchaseRestockArrivalGuard {
  Future<WorkspacePurchaseEntryBook?> retainRestockArrival(WorkspaceGoodsArrivalCommand command, {
    required bool qa, required int expectedRevision, required bool Function() isCurrent,
    WorkspaceGoodsArrivalResult? recorded, WorkspaceGoodsArrivalResult? closed, bool requestClosure = false,
  });
}

/// Validate separate authoritative ledger state while holding the purchase queue,
/// then append the immutable allocation review without queue re-entry.
abstract interface class WorkPurchaseBillGoodsReviewGuard {
  Future<bool> saveReviewedBillGoods(WorkspacePurchaseEntryBook book, {
    required int expectedRevision, required Future<bool> Function() verifyCurrent,
  });
}

/// Hold the purchase queue before checking Stock, matching receipt posting order.
/// The supplied coordinator must call persist while it still owns the Stock queue.
abstract interface class WorkPurchaseGoodsReceiptReviewGuard {
  Future<bool> saveReviewedGoodsReceipt(WorkspacePurchaseEntryBook book, {
    required int expectedRevision,
    required Future<bool> Function(Future<bool> Function() persist) withVerifiedStock,
  });
}

/// App-private originals. No public upload, product-photo identity or accounting effect.
abstract interface class WorkPurchaseReceiptReviewAbandonment {
  Future<WorkspacePurchaseEntryBook?> abandonReviewedReceipt(String account, String store, {
    required bool qa, required int expectedRevision,
    required WorkspaceGoodsReceiptReviewCancellation cancellation,
    required Future<bool> Function(WorkspaceSupplierGoodsReceiptDraft review) verifyUncommitted,
  });
}

abstract interface class WorkPurchaseBillGoodsReviewAbandonment {
  Future<WorkspacePurchaseEntryBook?> abandonReviewedBillGoods(String account, String store, {
    required bool qa, required int expectedRevision,
    required WorkspaceBillGoodsReviewCancellation cancellation,
    required Future<bool> Function(WorkspaceSupplierBillGoodsReview review) verifyUncommitted,
  });
}

/// App-private originals. No public upload, product-photo identity or accounting effect.
class WorkPurchaseInvoiceCapture {
  WorkPurchaseInvoiceCapture({required this.currentScope, WorkProofPicker? picker,
    Future<Directory> Function()? supportDirectory,
    Future<String> Function(String)? recognize})
    : picker = picker ?? NativeWorkProofPicker(),
      _supportDirectory = supportDirectory ?? getApplicationSupportDirectory,
      _recognize = recognize ?? _nativeRecognize;
  final (String, String, bool)? Function() currentScope;
  final WorkProofPicker picker;
  final Future<Directory> Function() _supportDirectory;
  final Future<String> Function(String) _recognize;
  void _check((String, String, bool) scope) {
    if (scope != currentScope()) {
      throw const WorkGatewayException('Return to the same Store to continue with this invoice.');
    }
  }
  String owner((String, String, bool) scope, String draftId) =>
    jsonEncode([scope.$1, scope.$2, scope.$3, draftId]);
  Future<Directory> _directory(String owner) async {
    final support = await _supportDirectory();
    var directory = support;
    for (final part in ['purchase-invoices-v1', crypto.sha256.convert(utf8.encode(owner)).toString()]) {
      directory = Directory('${directory.path}${Platform.pathSeparator}$part');
      if (await FileSystemEntity.type(directory.path, followLinks: false) == FileSystemEntityType.link) {
        throw const WorkGatewayException('Invoice storage needs recovery. Your draft has been kept.');
      }
      await directory.create(recursive: true);
    }
    return directory;
  }
  Future<File> _file(WorkspacePurchaseInvoiceAttachment a) async {
    if (!a.valid) throw const WorkGatewayException('Invoice attachment needs recovery.');
    final directory = await _directory(a.owner);
    final file = File('${directory.path}${Platform.pathSeparator}${a.digest}.invoice');
    if (await FileSystemEntity.type(file.path, followLinks: false) == FileSystemEntityType.link) {
      throw const WorkGatewayException('Invoice attachment needs recovery.');
    }
    return file;
  }
  Future<WorkspacePurchaseInvoiceAttachment?> capture((String, String, bool) scope,
      String draftId, WorkProofSource source) async {
    _check(scope);
    final picked = await picker.pick(source);
    _check(scope);
    if (picked == null) return null;
    final bytes = picked.bytes;
    if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
      throw const WorkGatewayException('Choose an invoice photo or PDF up to 10 MB.');
    }
    final mime = bytes.length >= 5 && ascii.decode(bytes.take(5).toList(), allowInvalid: true) == '%PDF-'
      ? 'application/pdf' : bytes.length >= 3 && bytes[0] == 255 && bytes[1] == 216 && bytes[2] == 255
      ? 'image/jpeg' : bytes.length >= 8 && listEquals(bytes.take(8).toList(), [137,80,78,71,13,10,26,10])
      ? 'image/png' : bytes.length >= 12 && ascii.decode(bytes.take(4).toList(), allowInvalid: true) == 'RIFF' &&
        ascii.decode(bytes.sublist(8,12), allowInvalid: true) == 'WEBP' ? 'image/webp' : null;
    if (mime == null) throw const WorkGatewayException('Choose a readable JPEG, PNG, WebP or PDF invoice.');
    if (mime != 'application/pdf') {
      final codec = await ui.instantiateImageCodec(bytes);
      try { final frame = await codec.getNextFrame(); frame.image.dispose(); }
      finally { codec.dispose(); }
    }
    _check(scope);
    final name = picked.fileName.replaceAll(RegExp(r'[\\/\r\n]'), '_');
    final a = WorkspacePurchaseInvoiceAttachment(owner: owner(scope, draftId),
      digest: crypto.sha256.convert(bytes).toString(),
      fileName: name.isEmpty ? 'Invoice' : name.substring(0, min(200, name.length)),
      contentType: mime, byteLength: bytes.length, source: source.name);
    final file = await _file(a);
    _check(scope);
    if (await file.exists()) {
      await read(scope, draftId, a);
    } else {
      final temporary = File('${file.path}.${DateTime.now().microsecondsSinceEpoch}.${Random.secure().nextInt(1 << 32)}.pending');
      try {
        await temporary.writeAsBytes(bytes, flush: true);
        _check(scope);
        if (await file.exists()) {
          await read(scope, draftId, a);
        } else {
          await temporary.rename(file.path);
          await read(scope, draftId, a);
        }
      } finally {
        // Only this call's unpublished temporary copy; never remove a saved original.
        if (await temporary.exists()) await temporary.delete();
      }
    }
    return a;
  }
  Future<Uint8List> read((String, String, bool) scope, String draftId,
      WorkspacePurchaseInvoiceAttachment a) async {
    _check(scope);
    if (a.owner != owner(scope, draftId)) {
      throw const WorkGatewayException('This invoice belongs to another purchase draft.');
    }
    final file = await _file(a);
    _check(scope);
    if (!await file.exists() || await file.length() != a.byteLength) {
      throw const WorkGatewayException('Invoice attachment is unavailable. Attach the original again.');
    }
    final bytes = await file.readAsBytes();
    _check(scope);
    if (crypto.sha256.convert(bytes).toString() != a.digest) {
      throw const WorkGatewayException('Invoice attachment changed. Attach the original again.');
    }
    return bytes;
  }
  Future<WorkspacePurchaseInvoiceAttachment> scan((String, String, bool) scope,
      String draftId, WorkspacePurchaseInvoiceAttachment a) async {
    if (a.contentType == 'application/pdf') {
      throw const WorkGatewayException('PDF attached. Enter its details manually, or photograph a page to read its text.');
    }
    await read(scope, draftId, a);
    try {
      final text = await _recognize((await _file(a)).path);
      _check(scope);
      if (text.trim().isEmpty || text.length > 60000) {
        throw const WorkGatewayException('The invoice text could not be read. Retake a clear photo or enter the details.');
      }
      return a.withText(text);
    } on MissingPluginException {
      throw const WorkGatewayException('Text reading needs the next app update. Your invoice is kept; enter its details manually.');
    } on PlatformException {
      throw const WorkGatewayException('Text reading is unavailable. Your invoice is kept; retry or enter its details manually.');
    }
  }
  static Future<String> _nativeRecognize(String path) async {
    final recognizer = invoice_ocr.TextRecognizer(script: invoice_ocr.TextRecognitionScript.latin);
    try { return (await recognizer.processImage(invoice_ocr.InputImage.fromFilePath(path))).text; }
    finally { await recognizer.close(); }
  }
}

/// Conservative labelled suggestions only. Unlabelled/ambiguous values remain for review.
class WorkPurchaseInvoiceSuggestions {
  WorkPurchaseInvoiceSuggestions(this.fields, this.goods, {
    this.additionalFields = const [], this.additionalOverflow = false});
  final Map<String, String> fields;
  final List<Map<String, String>> goods;
  final List<WorkspacePurchaseAdditionalField> additionalFields;
  final bool additionalOverflow;
  static String _label(String value) => value.trim().toLowerCase()
    .replaceAll(RegExp(r'\.(?!\d)'), '').replaceAll(RegExp(r'\s*/\s*'), '/')
    .replaceAll(RegExp(r'\s*₹\s*$'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
  // Normalize explicit printed tokens only; never infer totals or round source amounts.
  static String? _number(String input, {bool negative = false,
      bool quantity = false, bool rate = false}) {
    var value = input.trim();
    if (!quantity && !rate) {
      value = value.replaceFirst(RegExp(r'^(?:₹\s*|INR\s+|Rs\.?\s*)',
        caseSensitive: false), '').trim();
      if (value.endsWith('/-')) value = value.substring(0, value.length - 2).trim();
    }
    if (rate && value.endsWith('%')) value = value.substring(0, value.length - 1).trim();
    if (value.contains(',')) {
      if (value.split('.').skip(1).any((fraction) => fraction.contains(','))) return null;
      final whole = value.replaceFirst(RegExp(r'^-'), '').split('.').first;
      if (!RegExp(r'^[1-9]\d{0,2}(,\d{3})+$').hasMatch(whole) &&
          !RegExp(r'^[1-9]\d?(,\d{2})*,\d{3}$').hasMatch(whole)) {
        return null;
      }
      value = value.replaceAll(',', '');
    }
    final pattern = quantity ? RegExp(r'^-?\d+(?:\.\d{1,6})?$')
      : rate ? RegExp(r'^-?\d+(?:\.\d{1,4})?$') : RegExp(r'^-?\d+(?:\.\d{1,2})?$');
    final number = double.tryParse(value);
    if (!pattern.hasMatch(value) || number == null || !number.isFinite ||
        number.abs() > 999999999999 || (!negative && number < 0) ||
        (rate && number > 100)) {
      return null;
    }
    return value;
  }
  static String? _date(String input) {
    final numeric = RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$').firstMatch(input);
    final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(input);
    final named = RegExp(r'^(\d{1,2})[\s-]+([a-z]+)[,\s-]+(\d{4})$',
      caseSensitive: false).firstMatch(input);
    const months = {'jan':1,'january':1,'feb':2,'february':2,'mar':3,'march':3,
      'apr':4,'april':4,'may':5,'jun':6,'june':6,'jul':7,'july':7,'aug':8,'august':8,
      'sep':9,'sept':9,'september':9,'oct':10,'october':10,'nov':11,'november':11,
      'dec':12,'december':12};
    final day = numeric != null ? int.parse(numeric[1]!) : iso != null
      ? int.parse(iso[3]!) : named != null ? int.parse(named[1]!) : null;
    final month = numeric != null ? int.parse(numeric[2]!) : iso != null
      ? int.parse(iso[2]!) : named != null ? months[named[2]!.toLowerCase()] : null;
    final year = numeric != null ? int.parse(numeric[3]!) : iso != null
      ? int.parse(iso[1]!) : named != null ? int.parse(named[3]!) : null;
    if (day == null || month == null || year == null || year < 1) return null;
    final date = DateTime(year, month, day);
    if (date.day != day || date.month != month || date.year != year) return null;
    return [day.toString().padLeft(2, '0'), month.toString().padLeft(2, '0'),
      year.toString().padLeft(4, '0')].join('/');
  }
  static WorkPurchaseInvoiceSuggestions parse(String text) {
    const labels = {'supplier': 'supplierName', 'sold by': 'supplierName',
      'supplier name':'supplierName', 'billed by':'supplierName', 'seller':'supplierName',
      'seller name':'supplierName', 'seller address':'supplierAddress',
      'billed to':'buyerName', 'bill to':'buyerName', 'customer details':'buyerName',
      'customer name':'buyerName', 'billing address':'buyerAddress',
      'shipping address':'deliveryAddress', 'customer phone':'buyerPhone',
      'customer email':'buyerEmail', 'customer gstin':'buyerGstin', 'seller gstin':'supplierGstin',
      'supplier invoice no':'invoiceReference', 'supplier invoice number':'invoiceReference',
      'invoice no#':'invoiceReference', 'bill number':'invoiceReference',
      'due date':'dueDate', 'pay by date':'dueDate', 'taxable amount':'taxableValue',
      'sub total':'supplyValue', 'subtotal':'supplyValue', 'gst':'totalTax',
      'total':'invoiceTotal', 'round off':'roundOff', 'roundoff':'roundOff',
      'discount':'billDiscount', 'freight':'freight', 'other charges':'otherCharges',
      'bank':'bankName', 'account #':'bankAccount', 'account no':'bankAccount',
      'branch':'bankBranch', 'upi number':'upiId', 'terms and conditions':'terms',
      'terms & conditions':'terms', 'notes':'notes', 'amount paid':'printedPaymentMark',
      'supplier address':'supplierAddress', 'supplier phone':'supplierPhone',
      'supplier email':'supplierEmail', 'buyer phone':'buyerPhone', 'buyer email':'buyerEmail',
      'purchase order no':'poReference', 'po number':'poReference', 'copy label':'documentCopy',
      'total tax':'totalTax', 'amount payable':'amountPayable', 'amount in words':'amountInWords',
      'bank name':'bankName', 'bank account':'bankAccount', 'account number':'bankAccount',
      'ifsc':'bankIfsc', 'bank branch':'bankBranch', 'upi type':'upiType', 'upi id':'upiId',
      'supplier terms':'terms', 'signatory name':'signatory', 'payment terms':'paymentTerms',
      'expected delivery date':'expectedDeliveryDate', 'shipping terms':'shippingTerms',
      'supplier gstin': 'supplierGstin', 'buyer gstin': 'buyerGstin',
      'buyer uin':'buyerUin', 'buyer name':'buyerName', 'buyer address':'buyerAddress',
      'buyer state':'buyerState', 'buyer state code':'buyerStateCode',
      'delivery address':'deliveryAddress', 'delivery state':'deliveryState',
      'delivery state code':'deliveryStateCode', 'place of supply code':'placeOfSupplyCode',
      'invoice no': 'invoiceReference', 'invoice number': 'invoiceReference', 'invoice #': 'invoiceReference',
      'document title':'documentTitle', 'original invoice date':'originalInvoiceDate',
      'total items':'printedTotalItems', 'total quantity':'printedTotalQuantity',
      'printed payment mark':'printedPaymentMark', 'footer':'printedFooter',
      'bill no': 'invoiceReference', 'invoice date': 'invoiceDate', 'bill date': 'invoiceDate',
      'place of supply': 'placeOfSupply', 'taxable value': 'taxableValue',
      'goods value':'supplyValue', 'cgst': 'cgst', 'sgst': 'sgstAmount', 'utgst':'utgst',
      'sgst/utgst':'sgst', 'igst': 'igst', 'cess': 'cess',
      'irn':'irn', 'ack no':'ackNumber', 'acknowledgement number':'ackNumber',
      'ack date':'ackDate', 'acknowledgement date':'ackDate',
      'grand total': 'invoiceTotal', 'invoice total': 'invoiceTotal'};
    final candidates = <String, Set<String>>{};
    final originalCandidates = <String, List<(String, String)>>{};
    final additional = <WorkspacePurchaseAdditionalField>[];
    var additionalSize = 0;
    var overflow = false;
    void keepRaw(String label, String value, {String section = 'invoice', int? itemIndex}) {
      if (label.isEmpty || label.length > 120 || value.length > 4000 ||
          additional.length >= 200 || additionalSize + label.length + value.length > 48000) {
        overflow = true; return;
      }
      additionalSize += label.length + value.length;
      final identity = crypto.sha256.convert(utf8.encode(jsonEncode(
        [section, itemIndex, label, value, additional.length]))).toString();
      additional.add(WorkspacePurchaseAdditionalField(id: 'detected-$identity',
        label: label, value: value, section: section, itemIndex: itemIndex));
    }
    final rows = text.split(RegExp(r'\r?\n'));
    String? party;
    void candidate(String key, String value, String label, String rawValue) {
      (candidates[key] ??= {}).add(value);
      (originalCandidates[key] ??= []).add((label, rawValue));
    }
    for (final row in rows) {
      final heading = _label(row).replaceFirst(RegExp(r':$'), '');
      final partyHeading = const ['supplier details','seller details','billed by'].contains(heading)
        ? 'supplier' : const ['buyer details','customer details','billed to','bill to'].contains(heading)
        ? 'buyer' : null;
      if (partyHeading != null) party = partyHeading;
      if (const ['tax invoice','bill of supply'].contains(heading)) {
        candidate('documentTitle', row.trim(), 'Document title', row.trim());
      }
      final match = RegExp(r'^\s*([^:]+?)\s*:\s*(.+?)\s*$').firstMatch(row);
      if (match == null) {
        if (heading.isNotEmpty && partyHeading == null) party = null;
        continue;
      }
      final originalLabel = match[1]!.trim(), originalValue = match[2]!.trim();
      final normalizedLabel = _label(originalLabel);
      final rateLabel = RegExp(r'^(cgst|sgst|utgst|igst|gst|cess)\s*(?:@|at)\s*(\d+(?:\.\d+)?)\s*%$')
        .firstMatch(normalizedLabel);
      var key = labels[rateLabel?[1] ?? normalizedLabel];
      if (key == null && party != null) {
        key = switch (normalizedLabel) {
          'gstin' => party == 'supplier' ? 'supplierGstin' : 'buyerGstin',
          'mobile' || 'mobile / phone' || 'mobile/phone' || 'phone' || 'ph' =>
            party == 'supplier' ? 'supplierPhone' : 'buyerPhone',
          'email' => party == 'supplier' ? 'supplierEmail' : 'buyerEmail',
          'address' => party == 'supplier' ? 'supplierAddress' : 'buyerAddress',
          _ => null,
        };
      }
      var value = originalValue;
      if (key == null || value.length > (key == 'terms' ? 4000 :
          const ['shippingTerms', 'paymentTerms', 'amountInWords'].contains(key) ||
          key.endsWith('Address') ? 500 : 120)) { party = null; keepRaw(match[1]!.trim(), value); continue; }
      if (key.endsWith('Gstin') && !RegExp(r'^[0-9A-Z]{15}$').hasMatch(value)) {
        party = null; keepRaw(match[1]!.trim(), value); continue;
      }
      party = key.startsWith('supplier') ? 'supplier' : key.startsWith('buyer') ? 'buyer' : null;
      if (key == 'irn' && !RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(value)) {
        keepRaw(match[1]!.trim(), value); continue;
      }
      if (const {'supplyValue', 'taxableValue', 'cgst', 'sgstAmount', 'sgst', 'utgst',
          'igst', 'cess', 'invoiceTotal', 'totalTax', 'amountPayable', 'roundOff',
          'billDiscount', 'freight', 'otherCharges'}.contains(key)) {
        final amount = _number(value, negative: key == 'roundOff');
        if (amount == null) {
          keepRaw(match[1]!.trim(), value); continue;
        }
        value = amount;
        const printedRates = {'cgst':'printedCgstRate','sgst':'printedSgstRate',
          'utgst':'printedUtgstRate','igst':'printedIgstRate','gst':'printedTaxRate'};
        if (rateLabel != null && printedRates.containsKey(rateLabel[1])) {
          final rate = _number(rateLabel[2]!, rate: true);
          if (rate != null) candidate(printedRates[rateLabel[1]]!, rate, originalLabel, originalValue);
        }
      }
      if (const ['invoiceDate','ackDate','expectedDeliveryDate','dueDate'].contains(key)) {
        final date = _date(value);
        if (date == null) {
          keepRaw(match[1]!.trim(), value); continue;
        }
        if (key == 'invoiceDate' && date != value) {
          candidate('originalInvoiceDate', value, 'Original invoice date', value);
        }
        value = date;
      }
      candidate(key, value, originalLabel, originalValue);
    }
    final fields = {for (final e in candidates.entries) if (e.value.length == 1) e.key: e.value.single};
    for (final e in candidates.entries.where((e) => e.value.length > 1)) {
      for (final (label, value) in originalCandidates[e.key]!) { keepRaw(label, value); }
    }
    // Only explicit tab/pipe tables: guessing whitespace columns risks price/quantity swaps.
    final goods = <Map<String, String>>[];
    List<String>? headers, originalHeaders;
    const columns = {'description':'name', 'item/description':'name', 'description of goods':'name',
      'item':'name', 'product':'name', 'services':'name', 'qty':'quantity',
      'quantity':'quantity', 'rate':'cost', 'cost':'cost', 'unit':'pack', 'hsn':'hsn',
      'units':'pack', 'hsn/sac':'hsn', 'specifications':'specifications', 'model':'specifications',
      'tax amount':'taxAmount', 'rate/item':'cost', 's no':'printedSerial', '#':'printedSerial',
      'uqc':'unitCode', 'unit code':'unitCode', 'discount':'discount',
      'taxable value':'taxableValue', 'gst %':'gstRate', 'gst rate':'gstRate',
      'cgst %':'cgstRate', 'cgst rate':'cgstRate', 'cgst':'cgst', 'cgst amount':'cgst',
      'sgst %':'sgstRate', 'sgst rate':'sgstRate', 'sgst':'sgst', 'sgst amount':'sgst',
      'utgst %':'utgstRate', 'utgst rate':'utgstRate', 'utgst':'utgst', 'utgst amount':'utgst',
      'igst %':'igstRate', 'igst rate':'igstRate', 'igst':'igst', 'igst amount':'igst',
      'cess %':'cessRate', 'cess rate':'cessRate', 'cess':'cess', 'amount':'lineTotal'};
    for (final row in rows) {
      if (!row.contains('|') && !row.contains('\t')) { headers = null; originalHeaders = null; continue; }
      final cells = row.split(RegExp(r'\||\t')).map((c) => c.trim()).toList();
      final mapped = cells.map((c) => columns[_label(c)] ?? '').toList();
      if (mapped.contains('name') && mapped.contains('quantity') && mapped.contains('cost')) {
        final known = mapped.where((key) => key.isNotEmpty).toList();
        headers = known.toSet().length == known.length ? mapped : null;
        originalHeaders = cells;
        continue;
      }
      final rowHeaders = headers;
      if (rowHeaders == null || cells.length != rowHeaders.length ||
          cells.indexed.any((cell) => cell.$2.length > (rowHeaders[cell.$1] == 'specifications' ? 1000 : 200))) { continue; }
      final line = <String, String>{'productId':'', 'name':'', 'pack':'', 'quantity':'', 'cost':''};
      final extraCells = <(String, String)>[];
      for (var i=0; i<rowHeaders.length; i++) { if (rowHeaders[i].isNotEmpty) line[rowHeaders[i]] = cells[i]; }
      for (var i=0; i<rowHeaders.length; i++) {
        if (rowHeaders[i].isEmpty && cells[i].isNotEmpty) extraCells.add((originalHeaders![i], cells[i]));
      }
      // Retain proven columns; uncertain optional numeric cells need manual review.
      for (final key in const ['discount', 'taxableValue', 'gstRate', 'cgstRate', 'cgst',
          'sgstRate', 'sgst', 'utgstRate', 'utgst', 'igstRate', 'igst', 'cessRate', 'cess', 'lineTotal', 'taxAmount']) {
        final value = line[key];
        if (value == null || value.isEmpty) continue;
        final number = _number(value, rate: key.endsWith('Rate'));
        if (number == null) {
          final columnIndex = rowHeaders.indexOf(key);
          extraCells.add((originalHeaders![columnIndex], value));
          line.remove(key);
        } else { line[key] = number; }
      }
      final quantityText = _number(line['quantity']!, quantity: true);
      final costText = _number(line['cost']!);
      if (quantityText != null) line['quantity'] = quantityText;
      if (costText != null) line['cost'] = costText;
      final quantity = double.tryParse(line['quantity']!);
      final cost = double.tryParse(line['cost']!);
      if (line['name']!.isNotEmpty && quantityText != null && costText != null &&
          quantity != null && quantity > 0 && cost != null && cost >= 0 && goods.length < 200) {
        for (final cell in extraCells) {
          keepRaw(cell.$1, cell.$2, section: 'items', itemIndex: goods.length);
        }
        goods.add(line);
      }
    }
    return WorkPurchaseInvoiceSuggestions(Map.unmodifiable(fields), List.unmodifiable(goods),
      additionalFields: List.unmodifiable(additional), additionalOverflow: overflow);
  }
}

/// Uses the existing encrypted, serialized, revision-checked checkpoint pattern.
/// Contacts never share an inventory or financial-journal key.
class SecureWorkPurchaseEntryStore
    implements WorkPurchaseEntryStore, WorkPurchaseEntryRevisionGuard, WorkPurchaseReceiptReviewAbandonment,
      WorkPurchaseBillGoodsReviewGuard, WorkPurchaseBillGoodsReviewAbandonment,
      WorkPurchaseGoodsReceiptReviewGuard, WorkPurchaseRestockArrivalGuard {
  SecureWorkPurchaseEntryStore({required this.accountScope, FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();
  final String? Function() accountScope;
  final FlutterSecureStorage _storage;
  static final _tails = <String, Future<void>>{};
  String _key(String account, String store, bool qa) =>
    'moolsocial.workspace.purchase-entry.${qa ? 'qa' : 'production'}.v1.'
    '${Uri.encodeComponent(account)}/${Uri.encodeComponent(store)}';
  void _check(String account, String store) {
    if (account.trim().isEmpty || store.trim().isEmpty || accountScope() != account) {
      throw const WorkGatewayException('Return to the same account to recover your purchase draft.');
    }
  }
  Future<T> _serial<T>(String key, Future<T> Function() action) {
    final result = (_tails[key] ?? Future<void>.value()).then((_) => action());
    final tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    _tails[key] = tail;
    unawaited(tail.then((_) { if (identical(_tails[key], tail)) _tails.remove(key); }));
    return result;
  }
  Future<WorkspacePurchaseEntryBook?> _read(String account, String store, bool qa) async {
    _check(account, store);
    final raw = await _storage.read(key: _key(account, store, qa));
    _check(account, store);
    if (raw == null) return null;
    try {
      final saved = WorkspacePurchaseEntryBook.fromJson(jsonDecode(raw));
      if (saved.account != account || saved.store != store || saved.qa != qa) {
        throw const FormatException('Supplier scope mismatch');
      }
      return saved;
    } on FormatException {
      throw const WorkGatewayException('Your saved purchase draft needs recovery. Records have been kept.');
    }
  }
  @override
  Future<WorkspacePurchaseEntryBook?> read(String account, String store, {required bool qa}) =>
    _serial(_key(account, store, qa), () => _read(account, store, qa));
  @override
  Future<bool> withReviewedBook(String account, String store, {
    required bool qa,
    required int expectedRevision,
    required Future<bool> Function(WorkspacePurchaseEntryBook book) action,
  }) => _serial(_key(account, store, qa), () async {
    final book = await _read(account, store, qa);
    if (book == null || book.revision != expectedRevision) return false;
    // action may write the separate ledger checkpoint, but must not recursively
    // read/save this purchase store. Other instances' purchase writes queue here.
    final saved = await action(book);
    _check(account, store);
    return saved;
  });
  @override
  Future<void> save(WorkspacePurchaseEntryBook directory, {required int? expectedRevision}) async {
    await _save(directory, expectedRevision: expectedRevision);
  }
  @override
  Future<WorkspacePurchaseEntryBook?> retainRestockArrival(WorkspaceGoodsArrivalCommand command, {
    required bool qa, required int expectedRevision, required bool Function() isCurrent,
    WorkspaceGoodsArrivalResult? recorded, WorkspaceGoodsArrivalResult? closed, bool requestClosure = false,
  }) {
    final source = command.receipt.restockOriginal!, account = source.accountScope, store = source.buyingStoreId;
    if (source.realm != (qa ? 'evaluation' : 'production')) return Future.value(null);
    final key = _key(account, store, qa);
    return _serial(key, () async {
      final old = await _read(account, store, qa);
      if (old == null || !isCurrent()) return null;
      final review = old.goodsReceiptDrafts.where((r) => r.receipt.id == command.receipt.id).singleOrNull;
      if (review == null || review.supplierId != command.supplierId ||
          jsonEncode(review.receipt.toJson()) != jsonEncode(command.receipt.toJson()) ||
          old.goodsReceiptCancellations.any((c) => c.receiptId == command.receipt.id)) { return null; }
      final previous = old.restockGoodsAttempts.where((a) => a.command.receipt.id == command.receipt.id).singleOrNull;
      if (previous != null && previous.command.fingerprint != command.fingerprint) return null;
      if (recorded != null && (!recorded.recorded || recorded.command.fingerprint != command.fingerprint || previous == null)) return null;
      if (closed != null && (!closed.closed || closed.command.fingerprint != command.fingerprint || previous == null)) return null;
      if (recorded != null && closed != null || requestClosure && (previous == null || recorded != null || closed != null)) return null;
      if (previous?.recorded != null) {
        return closed == null && (recorded == null || jsonEncode(previous!.recorded!.proof!.toJson()) ==
          jsonEncode(recorded.proof!.toJson())) ? old : null;
      }
      if (previous?.closed != null) {
        return recorded == null && (closed == null || jsonEncode(previous!.closed!.closure!.toJson()) ==
          jsonEncode(closed.closure!.toJson())) ? old : null;
      }
      if (previous != null && recorded == null && closed == null &&
          (!requestClosure || previous.closeRequestedRevision != null)) { return old; }
      if (old.revision != expectedRevision ||
          previous == null && old.restockGoodsAttempts.length >= 1000) { return null; }
      final attempt = WorkspaceRestockGoodsAttempt(command: command, revision: previous?.revision ?? old.revision + 1,
        recorded: recorded, recordedRevision: recorded == null ? null : old.revision + 1,
        closeRequestedRevision: previous?.closeRequestedRevision ?? (requestClosure ? old.revision + 1 : null),
        closed: closed, closedRevision: closed == null ? null : old.revision + 1);
      final attempts = previous == null ? [...old.restockGoodsAttempts, attempt]
        : [for (final a in old.restockGoodsAttempts) if (a.command.receipt.id == command.receipt.id) attempt else a];
      final next = WorkspacePurchaseEntryBook.fromJson({...old.toJson(), 'revision': old.revision + 1,
        'restockGoodsAttempts': attempts.map((a) => a.toJson()).toList()});
      final bytes = jsonEncode(next.toJson());
      if (utf8.encode(bytes).length > 10 * 1024 * 1024) throw const WorkGatewayException('Purchase storage is full. Saved records are kept.');
      _check(account, store);
      if (!isCurrent()) return null;
      try { await _storage.write(key: key, value: bytes); }
      on Object {
        _check(account, store);
        if (await _storage.read(key: key) != bytes) rethrow;
      }
      _check(account, store);
      return isCurrent() ? next : null;
    });
  }
  @override
  Future<bool> saveReviewedBillGoods(WorkspacePurchaseEntryBook book, {
    required int expectedRevision, required Future<bool> Function() verifyCurrent,
  }) => _save(book, expectedRevision: expectedRevision, verifyCurrent: verifyCurrent);

  @override
  Future<bool> saveReviewedGoodsReceipt(WorkspacePurchaseEntryBook book, {
    required int expectedRevision,
    required Future<bool> Function(Future<bool> Function() persist) withVerifiedStock,
  }) => _save(book, expectedRevision: expectedRevision, guardedPersist: withVerifiedStock);

  Future<bool> _save(WorkspacePurchaseEntryBook directory, {required int? expectedRevision,
      Future<bool> Function()? verifyCurrent,
      Future<bool> Function(Future<bool> Function() persist)? guardedPersist}) async {
    final bytes = jsonEncode(directory.toJson());
    final frozen = WorkspacePurchaseEntryBook.fromJson(jsonDecode(bytes));
    final key = _key(frozen.account, frozen.store, frozen.qa);
    return _serial(key, () async {
      _check(frozen.account, frozen.store);
      final previous = await _read(frozen.account, frozen.store, frozen.qa);
      if (previous != null && jsonEncode(previous.toJson()) == bytes) return true;
      if (previous?.revision != expectedRevision || frozen.revision != (expectedRevision ?? 0) + 1) {
        throw const WorkGatewayException('Your purchase draft changed. Reopen Purchases before saving again.');
      }
      if (jsonEncode(frozen.restockGoodsAttempts.map((a) => a.toJson()).toList()) !=
          jsonEncode((previous?.restockGoodsAttempts ?? const <WorkspaceRestockGoodsAttempt>[]).map((a) => a.toJson()).toList())) {
        throw const WorkGatewayException('Keep receiving attempts and confirmations unchanged. Recover the original delivery.');
      }
      for (final copy in previous?.copies ?? const <WorkspacePurchaseSavedCopy>[]) {
        final retained = frozen.copies.where((c) => c.id == copy.id).firstOrNull;
        if (retained == null || jsonEncode(retained.toJson()) != jsonEncode(copy.toJson())) {
          throw const WorkGatewayException('Earlier purchase copies must be kept unchanged. Reopen Purchases.');
        }
      }
      final retainedOpeningIds = <String>{};
      if (frozen.billGoodsCancellations.length != (previous?.billGoodsCancellations.length ?? 0) ||
          (previous?.billGoodsCancellations ?? const <WorkspaceBillGoodsReviewCancellation>[]).any((c) =>
            !frozen.billGoodsCancellations.any((r) => jsonEncode(r.toJson()) == jsonEncode(c.toJson())))) {
        throw const WorkGatewayException('Bill goods cancellations require verified status. Keep their history unchanged.');
      }
      if (frozen.goodsReceiptCancellations.length != (previous?.goodsReceiptCancellations.length ?? 0) ||
          (previous?.goodsReceiptCancellations ?? const <WorkspaceGoodsReceiptReviewCancellation>[]).any((c) =>
            !frozen.goodsReceiptCancellations.any((r) => jsonEncode(r.toJson()) == jsonEncode(c.toJson())))) {
        throw const WorkGatewayException('Receiving cancellations require a verified status check. Keep their history unchanged.');
      }
      final retainedReceiptIds = <String>{};
      for (final review in previous?.goodsReceiptDrafts ?? const <WorkspaceSupplierGoodsReceiptDraft>[]) {
        final retained = frozen.goodsReceiptDrafts.where((r) => r.receipt.id == review.receipt.id).firstOrNull;
        if (retained == null || jsonEncode(retained.toJson()) != jsonEncode(review.toJson())) {
          throw const WorkGatewayException('Earlier receiving reviews must be kept unchanged. Reopen Purchases.');
        }
        retainedReceiptIds.add(review.receipt.id);
      }
      final receiptAdditions = frozen.goodsReceiptDrafts.where((r) => !retainedReceiptIds.contains(r.receipt.id));
      if (receiptAdditions.length > 1 || receiptAdditions.any((r) => r.revision != frozen.revision)) {
        throw const WorkGatewayException('Save one reviewed delivery at a time. Reopen Purchases.');
      }
      final retainedAllocationIds = <String>{};
      for (final review in previous?.billGoodsReviews ?? const <WorkspaceSupplierBillGoodsReview>[]) {
        final retained = frozen.billGoodsReviews.where((r) => r.allocation.operationId == review.allocation.operationId).singleOrNull;
        if (retained == null || jsonEncode(retained.toJson()) != jsonEncode(review.toJson())) {
          throw const WorkGatewayException('Earlier bill goods reviews must be kept unchanged. Reopen Purchases.');
        }
        retainedAllocationIds.add(review.allocation.operationId);
      }
      final allocationAdditions = frozen.billGoodsReviews.where((r) => !retainedAllocationIds.contains(r.allocation.operationId));
      if (allocationAdditions.length > 1 || allocationAdditions.any((r) => r.revision != frozen.revision)) {
        throw const WorkGatewayException('Save one reviewed bill goods match at a time. Reopen Purchases.');
      }
      if (allocationAdditions.isNotEmpty && verifyCurrent == null) {
        throw const WorkGatewayException('A new bill goods review requires verified supplier account status.');
      }
      for (final record
          in previous?.openingRecords ??
              const <WorkspaceSupplierOpeningRecord>[]) {
        final retained = frozen.openingRecords
            .where((r) => r.id == record.id)
            .firstOrNull;
        if (retained == null ||
            jsonEncode(retained.toJson()) != jsonEncode(record.toJson())) {
          throw const WorkGatewayException(
            'Earlier opening records must be kept unchanged. Reopen Purchases.',
          );
        }
        retainedOpeningIds.add(record.id);
      }
      final additions = frozen.openingRecords
          .where((r) => !retainedOpeningIds.contains(r.id))
          .toList();
      if (additions.length > 1 ||
          additions.any((r) => r.revision != frozen.revision)) {
        throw const WorkGatewayException(
          'Save one reviewed opening record at a time. Reopen Purchases.',
        );
      }
      if (utf8.encode(bytes).length > 10 * 1024 * 1024) {
        throw const WorkGatewayException('Purchase storage is full. Your saved records are kept; do not clear app data.');
      }
      if (verifyCurrent != null && !await verifyCurrent()) return false;
      Future<bool> persist() async {
        _check(frozen.account, frozen.store);
        try {
          await _storage.write(key: key, value: bytes);
        } on Object {
          _check(frozen.account, frozen.store);
          if (await _storage.read(key: key) != bytes) rethrow;
        }
        _check(frozen.account, frozen.store);
        return true;
      }
      return guardedPersist == null ? persist() : guardedPersist(persist);
    });
  }
  @override
  Future<WorkspacePurchaseEntryBook?> abandonReviewedReceipt(String account, String store, {
    required bool qa, required int expectedRevision,
    required WorkspaceGoodsReceiptReviewCancellation cancellation,
    required Future<bool> Function(WorkspaceSupplierGoodsReceiptDraft review) verifyUncommitted,
  }) => _abandonReviewedReceipt(account, store, qa: qa, expectedRevision: expectedRevision,
    cancellation: cancellation, verifyUncommitted: verifyUncommitted);
  @override
  Future<WorkspacePurchaseEntryBook?> abandonReviewedBillGoods(String account, String store, {
    required bool qa, required int expectedRevision,
    required WorkspaceBillGoodsReviewCancellation cancellation,
    required Future<bool> Function(WorkspaceSupplierBillGoodsReview review) verifyUncommitted,
  }) => _serial(_key(account, store, qa), () async {
    final old = await _read(account, store, qa);
    if (old == null || !cancellation.valid) return null;
    final review = old.billGoodsReviews.where((r) => r.allocation.operationId == cancellation.operationId).singleOrNull;
    if (review == null || review.supplierId != cancellation.supplierId) return null;
    final previous = old.billGoodsCancellations.where((c) => c.operationId == cancellation.operationId).singleOrNull;
    if (previous != null) {
      if (jsonEncode(previous.toJson()) != jsonEncode(cancellation.toJson())) return null;
      if (!await verifyUncommitted(review)) {
        throw const WorkGatewayException('Cancelled match conflicts with supplier account status. Recover its saved records.');
      }
      _check(account, store);
      return old;
    }
    if (old.revision != expectedRevision || cancellation.revision != old.revision + 1 ||
        cancellation.cancelledAt.isBefore(review.allocation.linkedAt) ||
        old.billGoodsCancellations.length >= 1000 || !await verifyUncommitted(review)) { return null; }
    _check(account, store);
    final next = WorkspacePurchaseEntryBook.fromJson(WorkspacePurchaseEntryBook(
      account: old.account, store: old.store, qa: old.qa, revision: old.revision + 1,
      profiles: old.profiles, draft: old.draft, copies: old.copies,
      openingRecords: old.openingRecords, goodsReceiptDrafts: old.goodsReceiptDrafts,
      goodsReceiptCancellations: old.goodsReceiptCancellations, billGoodsReviews: old.billGoodsReviews,
      billGoodsCancellations: [...old.billGoodsCancellations, cancellation],
      restockGoodsAttempts: old.restockGoodsAttempts).toJson());
    final bytes = jsonEncode(next.toJson());
    if (utf8.encode(bytes).length > 10 * 1024 * 1024) {
      throw const WorkGatewayException('Purchase storage is full. Saved records are kept.');
    }
    final key = _key(account, store, qa);
    try { await _storage.write(key: key, value: bytes); }
    on Object {
      _check(account, store);
      if (await _storage.read(key: key) != bytes) rethrow;
    }
    _check(account, store);
    return next;
  });
}

// The implementation is below the secure purchase store to keep this mutation
// inside its existing scoped queue; it must not recursively call read/save.
extension _PurchaseReviewCancellation on SecureWorkPurchaseEntryStore {
  Future<WorkspacePurchaseEntryBook?> _abandonReviewedReceipt(String account, String store, {
    required bool qa, required int expectedRevision,
    required WorkspaceGoodsReceiptReviewCancellation cancellation,
    required Future<bool> Function(WorkspaceSupplierGoodsReceiptDraft review) verifyUncommitted,
  }) => _serial(_key(account, store, qa), () async {
    final old = await _read(account, store, qa);
    if (old == null || !cancellation.valid) return null;
    if (old.restockGoodsAttempts.any((a) => a.command.receipt.id == cancellation.receiptId)) return null;
    final previous = old.goodsReceiptCancellations.where((c) => c.receiptId == cancellation.receiptId).firstOrNull;
    final review = old.goodsReceiptDrafts.where((r) => r.receipt.id == cancellation.receiptId).firstOrNull;
    if (previous != null) {
      if (jsonEncode(previous.toJson()) != jsonEncode(cancellation.toJson()) ||
          review == null || !await verifyUncommitted(review)) { return null; }
      _check(account, store);
      return old;
    }
    if (old.revision != expectedRevision || cancellation.revision != old.revision + 1 ||
        review == null || review.supplierId != cancellation.supplierId ||
        cancellation.cancelledAt.isBefore(review.receipt.recordedAt) ||
        old.goodsReceiptCancellations.length >= 1000) { return null; }
    if (!await verifyUncommitted(review)) return null;
    _check(account, store);
    final next = WorkspacePurchaseEntryBook.fromJson(WorkspacePurchaseEntryBook(
      account: old.account, store: old.store, qa: old.qa, revision: old.revision + 1,
      profiles: old.profiles, draft: old.draft, copies: old.copies,
      openingRecords: old.openingRecords, goodsReceiptDrafts: old.goodsReceiptDrafts,
      goodsReceiptCancellations: [...old.goodsReceiptCancellations, cancellation],
      billGoodsReviews: old.billGoodsReviews,
      billGoodsCancellations: old.billGoodsCancellations, restockGoodsAttempts: old.restockGoodsAttempts).toJson());
    final bytes = jsonEncode(next.toJson());
    if (utf8.encode(bytes).length > 10 * 1024 * 1024) {
      throw const WorkGatewayException('Purchase storage is full. Saved records are kept.');
    }
    final key = _key(account, store, qa);
    try { await _storage.write(key: key, value: bytes); }
    on Object {
      _check(account, store);
      if (await _storage.read(key: key) != bytes) rethrow;
    }
    _check(account, store);
    return next;
  });
}

abstract interface class WorkInventoryStore {
  Future<WorkspaceSavedInventory?> read(
    String account,
    String store, {
    required bool qa,
  });
  Future<void> save(
    WorkspaceSavedInventory inventory, {
    required int? expectedRevision,
  });
}

/// Review receipt coordinator using the same queue as every inventory writer.
/// The callback may commit the separate authoritative ledger, but must not call
/// public inventory read/save methods: those would queue behind this guard.
abstract interface class WorkInventoryReceiptProjectionGuard {
  Future<bool> projectReceipt(String account, String store, {
    required bool qa,
    required int? expectedRevision,
    required Future<WorkspaceSavedInventory?> Function(WorkspaceSavedInventory? previous) commit,
  });
}

/// Encrypted local inventory, deliberately separate from financial journals.
/// No deletion/migration fallback: corrupt or newer records stay recoverable.
abstract interface class WorkInventoryRestockProjectionGuard {
  Future<bool> withRestockInventory(String account, String store, {required bool qa,
    required int expectedRevision, required Future<bool> Function(WorkspaceSavedInventory previous, WorkspaceLedgerCheckpoint? journal) action});
  Future<WorkspaceSavedInventory?> adoptRestockBaseline(WorkspaceSavedInventory inventory, {
    required int? expectedRevision, required bool ownerConfirmed, required bool Function() isCurrent,
  });
  Future<WorkspaceSavedInventory?> projectRestockArrival(WorkspaceGoodsArrivalProof proof, {
    required bool qa, required int expectedRevision, required bool Function() isCurrent,
    required Future<bool> Function(WorkspaceSavedInventory previous) verifyBaseline,
  });
}

class SecureWorkInventoryStore implements WorkInventoryStore, WorkInventoryReceiptProjectionGuard, WorkInventoryRestockProjectionGuard {
  SecureWorkInventoryStore({
    required this.accountScope,
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();
  final String? Function() accountScope;
  final FlutterSecureStorage _storage;
  static final _tails = <String, Future<void>>{};
  String _key(String account, String store, bool qa) =>
      'moolsocial.workspace.inventory.${qa ? 'qa' : 'production'}.v1.'
      '${Uri.encodeComponent(account)}/${Uri.encodeComponent(store)}';
  void _check(String account, String store) {
    if (account.trim().isEmpty ||
        store.trim().isEmpty ||
        accountScope() != account) {
      throw const WorkGatewayException(
        'Return to the same account to recover this Store stock.',
      );
    }
  }

  Future<T> _serial<T>(String key, Future<T> Function() action) {
    final result = (_tails[key] ?? Future<void>.value()).then((_) => action());
    final tail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _tails[key] = tail;
    unawaited(
      tail.then((_) {
        if (identical(_tails[key], tail)) _tails.remove(key);
      }),
    );
    return result;
  }

  Future<WorkspaceSavedInventory?> _read(
    String account,
    String store,
    bool qa,
  ) async {
    _check(account, store);
    final raw = await _storage.read(key: _key(account, store, qa));
    _check(account, store);
    if (raw == null) return null;
    try {
      final saved = WorkspaceSavedInventory.fromJson(jsonDecode(raw));
      if (saved.account != account || saved.store != store || saved.qa != qa) {
        throw const FormatException('Inventory scope mismatch');
      }
      return saved;
    } on FormatException {
      throw const WorkGatewayException(
        'Saved stock needs recovery. Its data has been kept; no products were replaced.',
      );
    }
  }

  @override
  Future<WorkspaceSavedInventory?> read(
    String account,
    String store, {
    required bool qa,
  }) => _serial(_key(account, store, qa), () => _read(account, store, qa));
  @override
  Future<void> save(
    WorkspaceSavedInventory inventory, {
    required int? expectedRevision,
  }) async {
    // Freeze mutable nested metadata before queuing, and validate on both paths.
    final bytes = jsonEncode(inventory.toJson());
    final frozen = WorkspaceSavedInventory.fromJson(jsonDecode(bytes));
    final key = _key(frozen.account, frozen.store, frozen.qa);
    await _serial(key, () => _saveUnderGuard(frozen, bytes, expectedRevision));
  }
  @override
  Future<bool> withRestockInventory(String account, String store, {required bool qa,
    required int expectedRevision, required Future<bool> Function(WorkspaceSavedInventory previous, WorkspaceLedgerCheckpoint? journal) action}) =>
    _serial(_key(account, store, qa), () async {
      final previous = await _read(account, store, qa);
      if (previous == null || previous.revision != expectedRevision) return false;
      final journal = await SecureWorkLedgerCheckpointStore(accountScope: accountScope, storage: _storage).read(account, store);
      if (!previous.preservesCommittedStock(journal)) return false;
      final result = await action(previous, journal);
      _check(account, store);
      return result;
    });

  @override
  Future<WorkspaceSavedInventory?> adoptRestockBaseline(WorkspaceSavedInventory inventory, {
    required int? expectedRevision, required bool ownerConfirmed, required bool Function() isCurrent,
  }) {
    final frozen = WorkspaceSavedInventory.fromJson(jsonDecode(jsonEncode(inventory.toJson())));
    return _serial(_key(frozen.account, frozen.store, frozen.qa), () async {
      final previous = await _read(frozen.account, frozen.store, frozen.qa);
      if (!isCurrent() || previous?.revision != expectedRevision ||
          previous == null && !ownerConfirmed || frozen.products.isEmpty ||
          !frozen.products.any((p) => p.stockMode == WorkspaceStockMode.exactQuantity)) { return null; }
      final fingerprint = WorkspaceRestockStockBaseline.fingerprint(frozen);
      if (previous != null && WorkspaceRestockStockBaseline.fingerprint(previous) != fingerprint) return null;
      if (previous?.restockBaseline != null) return previous;
      final at = DateTime.now().toUtc();
      final next = WorkspaceSavedInventory.fromJson(WorkspaceSavedInventory(account: frozen.account, store: frozen.store, qa: frozen.qa,
        revision: (expectedRevision ?? 0) + 1, savedAt: at, products: frozen.products, movements: frozen.movements,
        variantFamilies: frozen.variantFamilies, reviewedCatalogueLinks: frozen.reviewedCatalogueLinks,
        manualReceiptCheckpointRevision: frozen.manualReceiptCheckpointRevision, restockProjections: frozen.restockProjections,
        restockBaseline: WorkspaceRestockStockBaseline(realm: frozen.qa ? 'evaluation' : 'production',
          basis: previous == null ? 'owner_confirmed' : 'saved_stock', retainedAt: at, contentFingerprint: fingerprint)).toJson());
      if (!isCurrent()) return null;
      await _saveUnderGuard(next, jsonEncode(next.toJson()), expectedRevision, restockBaselineAdoption: true, isCurrent: isCurrent);
      return isCurrent() ? next : null;
    });
  }

  @override
  Future<bool> projectReceipt(String account, String store, {
    required bool qa,
    required int? expectedRevision,
    required Future<WorkspaceSavedInventory?> Function(WorkspaceSavedInventory? previous) commit,
  }) => _serial(_key(account, store, qa), () async {
    _check(account, store);
    if (!qa) {
      throw const WorkGatewayException('Supplier receipt projection needs the production inventory adapter.');
    }
    final previous = await _read(account, store, qa);
    if (previous?.revision != expectedRevision) {
      throw const WorkGatewayException('Store stock changed. Reopen it before receiving goods.');
    }
    final projection = await commit(previous);
    _check(account, store);
    if (projection == null) {
      return false;
    }
    final bytes = jsonEncode(projection.toJson());
    final frozen = WorkspaceSavedInventory.fromJson(jsonDecode(bytes));
    if (frozen.account != account || frozen.store != store || frozen.qa != qa) {
      throw const WorkGatewayException('Supplier receipt stock scope changed. Saved records are kept.');
    }
    if (frozen.manualReceiptCheckpointRevision == null) {
      throw const WorkGatewayException('Supplier receipt projection needs its committed checkpoint reference.');
    }
    await _saveUnderGuard(frozen, bytes, expectedRevision, receiptProjection: true);
    return true;
  });

  @override
  Future<WorkspaceSavedInventory?> projectRestockArrival(WorkspaceGoodsArrivalProof proof, {
    required bool qa, required int expectedRevision, required bool Function() isCurrent,
    required Future<bool> Function(WorkspaceSavedInventory previous) verifyBaseline,
  }) {
    final command = proof.command, source = command.receipt.restockOriginal!;
    if (source.realm != (qa ? 'evaluation' : 'production')) return Future.value(null);
    return _serial(_key(source.accountScope, source.buyingStoreId, qa), () async {
      final previous = await _read(source.accountScope, source.buyingStoreId, qa);
      if (previous == null || !isCurrent()) return null; // Never assume an empty Stock baseline.
      final existing = previous.restockProjections.where((p) => p.command.receipt.id == command.receipt.id).singleOrNull;
      if (existing != null) {
        if (!existing.matches(proof)) throw const WorkGatewayException('Receiving Stock proof changed. Recover the original delivery.');
        return previous;
      }
      if (previous.revision != expectedRevision || previous.restockProjections.length >= 1000 ||
          !await verifyBaseline(previous) || !isCurrent()) { return null; }
      final projection = WorkspaceRestockStockProjection.fromProof(proof, DateTime.now().toUtc());
      final deltas = <String, int>{};
      for (final line in command.receipt.lines) {
        final product = previous.products.where((p) => p.id == line.productId).singleOrNull;
        if (product == null || product.stockMode != WorkspaceStockMode.exactQuantity || product.pack != line.stockUnit) return null;
        deltas.update(line.productId, (delta) => delta + line.newStockUnits, ifAbsent: () => line.newStockUnits);
      }
      final products = <WorkspaceCatalogueItem>[];
      for (final product in previous.products) {
        final delta = deltas[product.id];
        if (delta == null) { products.add(product); continue; }
        final stock = product.stock + delta;
        if (stock < 0 || stock > 2147483647) return null;
        products.add(product.copyWith(stock: stock));
      }
      final previousJson = previous.toJson();
      final next = WorkspaceSavedInventory.fromJson({...previousJson, 'version': 6,
        'baseVersion': previousJson['version'] == 6 ? previousJson['baseVersion'] : previousJson['version'],
        'revision': previous.revision + 1,
        'savedAt': projection.appliedAt.toUtc().toIso8601String(), 'products': products.map((p) => p.toInventoryJson()).toList(),
        'restockProjections': [...previous.restockProjections, projection].map((p) => p.toJson()).toList(),
        'movements': [
          for (final line in command.receipt.lines)
            if (projection.movementFor(line) case final movement?) {'id': movement.id, 'productId': movement.productId,
              'productLabel': movement.productLabel, 'kind': movement.kind.name, 'quantityDelta': movement.quantityDelta,
              'reason': movement.reason, 'occurredAt': movement.occurredAt.toUtc().toIso8601String(),
              'referenceKind': movement.referenceKind!.name, 'referenceId': movement.referenceId},
          ...previousJson['movements'] as List,
        ]});
      if (!isCurrent()) return null;
      await _saveUnderGuard(next, jsonEncode(next.toJson()), previous.revision, restockProjection: true, isCurrent: isCurrent);
      return isCurrent() ? next : null;
    });
  }

  Future<void> _saveUnderGuard(WorkspaceSavedInventory frozen, String bytes,
      int? expectedRevision, {bool receiptProjection = false, bool restockProjection = false,
        bool restockBaselineAdoption = false, bool Function()? isCurrent}) async {
      final key = _key(frozen.account, frozen.store, frozen.qa);
      _check(frozen.account, frozen.store);
      final previous = await _read(frozen.account, frozen.store, frozen.qa);
      if (previous != null && jsonEncode(previous.toJson()) == bytes) return;
      if (!restockBaselineAdoption && jsonEncode(frozen.restockBaseline?.toJson()) != jsonEncode(previous?.restockBaseline?.toJson())) {
        throw const WorkGatewayException('Keep the saved receiving Stock baseline. Recover the original Store Stock.');
      }
      if (!restockProjection && jsonEncode(frozen.restockProjections.map((p) => p.toJson()).toList()) !=
          jsonEncode((previous?.restockProjections ?? const <WorkspaceRestockStockProjection>[]).map((p) => p.toJson()).toList())) {
        throw const WorkGatewayException('Keep saved receiving Stock proofs. Recover the original delivery.');
      }
      if ((!receiptProjection && previous?.manualReceiptCheckpointRevision !=
          frozen.manualReceiptCheckpointRevision) ||
          (receiptProjection && previous?.manualReceiptCheckpointRevision != null &&
              frozen.manualReceiptCheckpointRevision! < previous!.manualReceiptCheckpointRevision!)) {
        throw const WorkGatewayException('Keep the saved supplier receipt checkpoint reference. Reopen Stock.');
      }
      if (previous?.revision != expectedRevision ||
          frozen.revision != (expectedRevision ?? 0) + 1 ||
          (previous != null && frozen.savedAt.isBefore(previous.savedAt))) {
        throw const WorkGatewayException(
          'Store stock changed elsewhere. Reload it before saving again.',
        );
      }
      // Original stock-entry facts are retained, not editable current values.
      // A current-revision writer must not silently erase reviewed identity
      // history, or replace a newer acknowledged candidate with an older one.
      if (previous != null) {
        final nextLinks = {for (final link in frozen.reviewedCatalogueLinks) link.skuId: link};
        if (previous.reviewedCatalogueLinks.any((old) => nextLinks[old.skuId]?.preserves(old) != true)) {
          throw const WorkGatewayException('Keep saved reviewed product identities. Recover the original listing update.');
        }
      }
      // Reject dropped products/provenance too: an older or stale writer must
      // not erase their origin while advancing the inventory revision.
      if (previous != null) {
        final next = {for (final p in frozen.products) p.id: p};
        if (previous.products.any((p) =>
            next[p.id]?.stockEntry?.contentIdentity !=
                p.stockEntry?.contentIdentity)) {
          throw const WorkGatewayException(
            'Original stock-entry details changed. Reload Stock before saving again.',
          );
        }
        final receiptProducts = {
          for (final movement in [...previous.movements, ...frozen.movements])
            if (movement.referenceKind == WorkspaceStockReferenceKind.manualSupplierReceipt ||
                movement.referenceKind == WorkspaceStockReferenceKind.manualSupplierReturn ||
                movement.referenceKind == WorkspaceStockReferenceKind.restockGoodsArrival)
              movement.productId,
        };
        if (receiptProducts.isNotEmpty || previous.manualReceiptCheckpointRevision != null ||
            frozen.manualReceiptCheckpointRevision != null || previous.restockProjections.isNotEmpty || frozen.restockProjections.isNotEmpty) {
          final nextMovements = {for (final m in frozen.movements) m.id: m};
          if (previous.movements.any((m) => nextMovements[m.id]?.contentIdentity != m.contentIdentity)) {
            throw const WorkGatewayException('Supplier receipt stock history must be kept. Reopen Stock.');
          }
          final previousMovements = previous.movements.map((m) => m.id).toSet();
          final additions = frozen.movements.where((m) => !previousMovements.contains(m.id));
          for (final product in previous.products) {
            final nextProduct = next[product.id];
            final delta = additions.where((m) => m.productId == product.id)
              .fold<int>(0, (sum, m) => sum + m.quantityDelta);
            if (nextProduct == null || nextProduct.stock != product.stock + delta) {
              throw const WorkGatewayException('Stock quantity does not match its saved receipt and adjustments. Reopen Stock.');
            }
            if (receiptProducts.contains(product.id) &&
                (nextProduct.pack != product.pack || nextProduct.stockMode != product.stockMode)) {
              throw const WorkGatewayException('Keep this received product’s Stock unit. Add a separate product for a different pack.');
            }
          }
        }
      }
      if (!receiptProjection && frozen.qa) {
        // Every standalone writer participates in this inventory queue. Check
        // the current authoritative journal inside it, not before awaiting it.
        final ledger = await SecureWorkLedgerCheckpointStore(
          accountScope: accountScope, storage: _storage).read(frozen.account, frozen.store);
        final hasReceipts = ledger?.supplierLedgers.values.any((supplier) =>
          supplier.goodsReceipts.isNotEmpty) ?? false;
        if (hasReceipts && frozen.manualReceiptCheckpointRevision == null) {
          throw const WorkGatewayException('Goods receipt is saved. Recover Stock before saving this edit.');
        }
        if (frozen.manualReceiptCheckpointRevision != null) {
        final authoritative = ledger?.inventory;
        final quantities = authoritative?.quantities;
        final nextMovements = {for (final m in frozen.movements) m.id: m};
        if (ledger == null || authoritative == null || quantities == null ||
            ledger.revision < frozen.manualReceiptCheckpointRevision! ||
            !ledger.supplierLedgers.values.any((supplier) => supplier.goodsReceipts.isNotEmpty) ||
            authoritative.movements.any((m) => nextMovements[m.id]?.contentIdentity != m.contentIdentity)) {
          throw const WorkGatewayException('Saved supplier receipts or sales changed. Reopen Stock before saving this edit.');
        }
        final journalIds = authoritative.movements.map((m) => m.id).toSet();
        final localTail = frozen.movements.where((m) => !journalIds.contains(m.id));
        for (final product in frozen.products) {
          final base = quantities[product.id];
          if (base != null && product.stock != base + localTail
              .where((m) => m.productId == product.id)
              .fold<int>(0, (sum, m) => sum + m.quantityDelta)) {
            throw const WorkGatewayException('Stock changed after receipt. Keep your edit and reopen its saved quantity.');
          }
        }
        }
      }
      if (frozen.restockProjections.isNotEmpty || frozen.restockBaseline != null) {
        if (utf8.encode(bytes).length > 10 * 1024 * 1024) {
          throw const WorkGatewayException('Stock recovery storage is full. Saved records are kept.');
        }
        final ledger = await SecureWorkLedgerCheckpointStore(accountScope: accountScope, storage: _storage).read(frozen.account, frozen.store);
        if (!frozen.preservesCommittedStock(ledger)) {
          throw const WorkGatewayException('Recover saved supplier records before updating receiving Stock.');
        }
        final allocated = <String, int>{}, originals = {for (final m in frozen.movements) m.id: m};
        final receipts = [for (final p in frozen.restockProjections) p.command.receipt,
          for (final supplier in ledger?.supplierLedgers.values ?? const <WorkspaceSupplierLedger>[])
            ...supplier.goodsReceipts.values];
        for (final receipt in receipts) {
          for (final line in receipt.lines) {
            for (final entry in line.priorStockUnits.entries) {
              final quantity = (allocated[entry.key] ?? 0) + entry.value;
              if (originals[entry.key] == null || quantity > originals[entry.key]!.quantityDelta) {
                throw const WorkGatewayException('Earlier Stock entry is already linked to another delivery. Recover its original records.');
              }
              allocated[entry.key] = quantity;
            }
          }
        }
      }
      _check(frozen.account, frozen.store);
      if (isCurrent?.call() == false) throw const WorkGatewayException('Receiving scope changed before saving Stock.');
      try {
        await _storage.write(key: key, value: bytes);
      } on Object {
        // A native write may finish before its response is lost. Read back the
        // exact frozen record; never guess whether a retry would overwrite data.
        _check(frozen.account, frozen.store);
        if (await _storage.read(key: key) != bytes) rethrow;
      }
      // A scope change cannot apply this completion to another account.
      _check(frozen.account, frozen.store);
  }
}

abstract interface class WorkCounterDraftStore {
  Future<WorkspaceCounterDraft?> read(String account, String store);
  Future<void> save(
    WorkspaceCounterDraft draft, {
    required int? expectedRevision,
  });
}

/// Device-local encrypted recovery, not an order/payment completion journal.
/// A submitting draft cannot be restored as editable work. Its exact operation
/// must be reconciled by the caller before retiring it. Keep a revisioned
/// tombstone after discard/completion so delayed edits cannot revive the sale.
class SecureWorkCounterDraftStore implements WorkCounterDraftStore {
  SecureWorkCounterDraftStore({
    required this.accountScope,
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final String? Function() accountScope;
  final FlutterSecureStorage _storage;
  static final Map<String, Future<void>> _pending = {};

  String _key(String account, String store) =>
      'moolsocial.workspace.counter-draft.v1.'
      '${Uri.encodeComponent(account)}/${Uri.encodeComponent(store)}';

  // Serialize across session/store instances in the UI isolate. Do not time
  // out a native write and release the queue while that write can still land.
  // Distributed/cross-device concurrency belongs to the backend, not this key.
  Future<T> _exclusive<T>(String key, Future<T> Function() action) {
    final result = (_pending[key] ?? Future<void>.value()).then(
      (_) => action(),
    );
    final tail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _pending[key] = tail;
    unawaited(
      tail.then((_) {
        if (identical(_pending[key], tail)) _pending.remove(key);
      }),
    );
    return result;
  }

  void _checkAccount(String account, String store) {
    if (account.trim().isEmpty ||
        store.trim().isEmpty ||
        accountScope() != account) {
      throw const WorkGatewayException('Sign in again to recover this bill.');
    }
  }

  Future<WorkspaceCounterDraft?> _read(String account, String store) async {
    _checkAccount(account, store);
    final value = await _storage.read(key: _key(account, store));
    _checkAccount(account, store);
    if (value == null) return null;
    WorkspaceCounterDraft? draft;
    try {
      draft = WorkspaceCounterDraft.fromJson(jsonDecode(value));
    } on FormatException {
      // Invalid retained bytes are not an empty bill and must not be replaced.
    }
    if (draft == null || draft.account != account || draft.store != store) {
      throw const WorkGatewayException('Your saved bill could not be opened.');
    }
    return draft;
  }

  @override
  Future<WorkspaceCounterDraft?> read(String account, String store) =>
      _exclusive(_key(account, store), () => _read(account, store));

  @override
  Future<void> save(
    WorkspaceCounterDraft draft, {
    required int? expectedRevision,
  }) => _exclusive(_key(draft.account, draft.store), () async {
    _checkAccount(draft.account, draft.store);
    if (!draft.valid ||
        (expectedRevision != null && expectedRevision < 1) ||
        draft.revision != (expectedRevision ?? 0) + 1) {
      throw const WorkGatewayException('This bill could not be saved.');
    }
    final current = await _read(draft.account, draft.store);
    final value = jsonEncode(draft.toJson());
    if (current != null && jsonEncode(current.toJson()) == value) {
      return; // Same write retried after an uncertain local result.
    }
    if (current?.stage == WorkspaceCounterDraftStage.submitting &&
        draft.stage == WorkspaceCounterDraftStage.reviewRequired &&
        jsonEncode({
              ...current!.toJson(),
              'revision': draft.revision,
              'stage': draft.stage.name,
            }) !=
            value) {
      throw const WorkGatewayException(
        'Keep the saved bill unchanged during recovery.',
      );
    }
    if (current?.revision != expectedRevision ||
        (draft.stage == WorkspaceCounterDraftStage.reviewRequired &&
            current?.stage != WorkspaceCounterDraftStage.submitting) ||
        (current == null &&
            draft.stage != WorkspaceCounterDraftStage.editing) ||
        (current != null &&
            (current.id == draft.id
                ? current.stage == WorkspaceCounterDraftStage.retired ||
                      (current.stage == WorkspaceCounterDraftStage.submitting &&
                          ((draft.stage != WorkspaceCounterDraftStage.retired &&
                                  draft.stage !=
                                      WorkspaceCounterDraftStage
                                          .reviewRequired) ||
                              draft.submissionOrderId !=
                                  current.submissionOrderId)) ||
                      (current.stage ==
                              WorkspaceCounterDraftStage.reviewRequired &&
                          draft.stage != WorkspaceCounterDraftStage.editing &&
                          draft.stage != WorkspaceCounterDraftStage.retired)
                : current.stage != WorkspaceCounterDraftStage.retired ||
                      draft.stage != WorkspaceCounterDraftStage.editing))) {
      throw const WorkGatewayException(
        'This saved bill changed. Reopen it before continuing.',
      );
    }
    _checkAccount(draft.account, draft.store);
    await _storage.write(key: _key(draft.account, draft.store), value: value);
    _checkAccount(draft.account, draft.store);
  });
}

enum WorkIssueReplyState { applied, rejected, pending, notRecorded }

enum WorkIssueResponseError {
  permissionDenied,
  caseChanged,
  caseClosed,
  responseUnavailable,
  invalidDetails;

  String get instruction => switch (this) {
    permissionDenied => 'You do not have permission to respond to this case.',
    caseChanged =>
      'This case changed. Review the latest update before responding.',
    caseClosed => 'This case is closed. Your draft has been kept.',
    responseUnavailable =>
      'This response is no longer available. Review the case.',
    invalidDetails => 'Check your response details and try again.',
  };
}

/// V1 case-response command. The purchasing line snapshot is immutable, and
/// this command never doubles as a refund, receipt, substitution or handover.
class WorkIssueCommand {
  WorkIssueCommand({
    required this.operationId,
    required this.draft,
    required this.kind,
    required List<WorkspaceIssueLine> lines,
    this.purchaseContext,
    this.sourceCaseId,
  }) : lines = List.unmodifiable(lines);
  final String operationId;
  final WorkspaceIssueDraft draft;
  final WorkspaceIssueKind kind;
  final List<WorkspaceIssueLine> lines;
  final WorkspaceIssuePurchaseContext? purchaseContext;
  final String? sourceCaseId;
  WorkspaceIssueDraftKey get key => draft.key;
  bool get valid =>
      draft.valid &&
      draft.response != null &&
      RegExp(r'^STORE-ISSUE-[A-Za-z0-9_-]{22,64}$').hasMatch(operationId) &&
      (draft.response == WorkspaceIssueResponse.acceptRequest ||
          draft.note.trim().isNotEmpty) &&
      (purchaseContext == null ? sourceCaseId == null && kind != WorkspaceIssueKind.deviceMismatch && lines.isNotEmpty && lines.every((line) => line.valid) :
        purchaseContext!.valid && sourceCaseId != null && sourceCaseId!.isNotEmpty && sourceCaseId == sourceCaseId!.trim() && sourceCaseId!.length <= 240 &&
        !RegExp(r'[\x00-\x1f\x7f]').hasMatch(sourceCaseId!) &&
        draft.target == WorkspaceIssueTarget.customerOrder && draft.referenceId == purchaseContext!.reference.orderId &&
        key.store == purchaseContext!.reference.storeId && key == purchaseContext!.responseKey(key.account, key.store, sourceCaseId!) && lines.isEmpty) &&
      lines.map((line) => line.lineId).toSet().length == lines.length;

  Map<String, Object?> toJson() => {
    'version': purchaseContext == null ? 1 : 2,
    'operationId': operationId,
    'draft': draft.toJson(),
    'kind': kind.name,
    'lines': [
      for (final line in lines)
        {
          'lineId': line.lineId,
          'productId': line.productId,
          'name': line.name,
          'pack': line.pack,
          'orderedQuantity': line.orderedQuantity,
          'affectedQuantity': line.affectedQuantity,
        },
    ],
    if (purchaseContext != null) ...{'purchaseContext': purchaseContext!.toJson(), 'sourceCaseId': sourceCaseId},
  };

  /// SHA-256 over UTF-8 JSON. Legacy V1 field order/bytes remain unchanged.
  String get digest =>
      crypto.sha256.convert(utf8.encode(jsonEncode(toJson()))).toString();

  static WorkIssueCommand? fromJson(Object? value) {
    if (value is! Map ||
        !const [1, 2].contains(value['version']) ||
        value['operationId'] is! String ||
        value['lines'] is! List) {
      return null;
    }
    final draft = WorkspaceIssueDraft.fromJson(value['draft']);
    final kind = WorkspaceIssueKind.values
        .where((k) => k.name == value['kind'])
        .firstOrNull;
    if (draft == null || kind == null) return null;
    WorkspaceIssuePurchaseContext? context;
    if (value['version'] == 2) {
      const keys = {'version', 'operationId', 'draft', 'kind', 'lines', 'purchaseContext', 'sourceCaseId'};
      if (value['version'] is! int || value.length != keys.length || !value.keys.every(keys.contains) || value['sourceCaseId'] is! String) return null;
      try { context = WorkspaceIssuePurchaseContext.fromJson(value['purchaseContext']); } on Object { return null; }
    } else if (value.containsKey('purchaseContext') || value.containsKey('sourceCaseId')) { return null; }
    final lines = <WorkspaceIssueLine>[];
    for (final line in value['lines'] as List) {
      if (line is! Map ||
          line['lineId'] is! String ||
          line['productId'] is! String ||
          line['name'] is! String ||
          line['pack'] is! String ||
          line['orderedQuantity'] is! int ||
          line['affectedQuantity'] is! int) {
        return null;
      }
      lines.add(
        WorkspaceIssueLine(
          lineId: line['lineId'],
          productId: line['productId'],
          name: line['name'],
          pack: line['pack'],
          orderedQuantity: line['orderedQuantity'],
          affectedQuantity: line['affectedQuantity'],
        ),
      );
    }
    final command = WorkIssueCommand(
      operationId: value['operationId'],
      draft: draft,
      kind: kind,
      lines: lines,
      purchaseContext: context,
      sourceCaseId: context == null ? null : value['sourceCaseId'],
    );
    return command.valid ? command : null;
  }
}

/// Applied means the response was recorded once, not that the case was approved.
/// The case feed separately supplies its next status. Unknown/timeout stays pending.
class WorkIssueReply {
  const WorkIssueReply({
    required this.key,
    required this.operationId,
    required this.commandDigest,
    required this.state,
    this.revision,
    this.error,
  });
  final WorkspaceIssueDraftKey key;
  final String operationId, commandDigest;
  final WorkIssueReplyState state;
  final int? revision;
  final WorkIssueResponseError? error;
  bool matches(WorkIssueCommand command) =>
      key == command.key &&
      operationId == command.operationId &&
      commandDigest == command.digest &&
      switch (state) {
        WorkIssueReplyState.applied =>
          error == null &&
              revision != null &&
              revision! > command.draft.expectedRevision,
        WorkIssueReplyState.rejected => error != null,
        WorkIssueReplyState.pending ||
        WorkIssueReplyState.notRecorded => error == null,
      };
  Map<String, Object?> toJson() => {
    'account': key.account,
    'store': key.store,
    'caseId': key.caseId,
    'operationId': operationId,
    'commandDigest': commandDigest,
    'state': state.name,
    'revision': revision,
    'error': error?.name,
  };
  static WorkIssueReply? fromJson(Object? value) {
    if (value is! Map ||
        value['account'] is! String ||
        value['store'] is! String ||
        value['caseId'] is! String ||
        value['operationId'] is! String ||
        value['commandDigest'] is! String ||
        (value['revision'] != null && value['revision'] is! int)) {
      return null;
    }
    final state = WorkIssueReplyState.values
        .where((s) => s.name == value['state'])
        .firstOrNull;
    final error = WorkIssueResponseError.values
        .where((s) => s.name == value['error'])
        .firstOrNull;
    if (state == null || (value['error'] != null && error == null)) return null;
    return WorkIssueReply(
      key: (
        account: value['account'],
        store: value['store'],
        caseId: value['caseId'],
      ),
      operationId: value['operationId'],
      commandDigest: value['commandDigest'],
      state: state,
      revision: value['revision'],
      error: error,
    );
  }
}

class WorkIssueSubmission {
  const WorkIssueSubmission(this.command, [this.reply]);
  final WorkIssueCommand command;
  final WorkIssueReply? reply;
  bool get pending =>
      reply == null ||
      {
        WorkIssueReplyState.pending,
        WorkIssueReplyState.notRecorded,
      }.contains(reply!.state);
  bool get valid => command.valid && (reply == null || reply!.matches(command));
  Map<String, Object?> toJson() => {
    'version': 1,
    'command': command.toJson(),
    'reply': reply?.toJson(),
  };
  static WorkIssueSubmission? fromJson(Object? value) {
    if (value is! Map || value['version'] != 1) return null;
    final command = WorkIssueCommand.fromJson(value['command']);
    final reply = WorkIssueReply.fromJson(value['reply']);
    if (command == null || (value['reply'] != null && reply == null)) {
      return null;
    }
    final submission = WorkIssueSubmission(command, reply);
    return submission.valid ? submission : null;
  }
}

/// Authenticate independently; validate Store role, exact case/line/revision and
/// permitted response; atomically deduplicate operation+digest with the response.
/// Reconcile is read-only. Unknown is pending, never permission for a fresh ID.
/// A notRecorded reply permits retry of the SAME operation and payload only;
/// atomic deduplication must protect a racing/delayed original attempt as well.
/// A rejected receipt guarantees this operation recorded no case response.
abstract interface class WorkIssueCommandGateway {
  Future<WorkIssueReply> submitIssueResponse(WorkIssueCommand command);
  Future<WorkIssueReply> reconcileIssueResponse(WorkIssueCommand command);
}

/// Explicit opt-in to the proposed V2 canonical purchase case payload. Legacy
/// V1 gateways are never sent an unrecognised command or converted quantities.
abstract interface class WorkCanonicalIssueCommandGateway implements WorkIssueCommandGateway {}

abstract interface class WorkIssueCommandStore {
  Future<WorkIssueSubmission?> read(WorkspaceIssueDraftKey key);
  Future<void> save(WorkIssueSubmission submission);
}

class SecureWorkIssueCommandStore implements WorkIssueCommandStore {
  SecureWorkIssueCommandStore({
    required this.accountScope,
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();
  final String? Function() accountScope;
  final FlutterSecureStorage _storage;
  String _key(WorkspaceIssueDraftKey key) =>
      'moolsocial.workspace.issue-command.v1.'
      '${[key.account, key.store, key.caseId].map(Uri.encodeComponent).join('/')}';
  @override
  Future<WorkIssueSubmission?> read(WorkspaceIssueDraftKey key) async {
    if (key.account != accountScope()) return null;
    final value = await _storage
        .read(key: _key(key))
        .timeout(const Duration(seconds: 10));
    if (value == null || key.account != accountScope()) return null;
    final submission = WorkIssueSubmission.fromJson(jsonDecode(value));
    if (submission == null || submission.command.key != key) {
      throw const WorkGatewayException(
        'Your response status could not be opened.',
      );
    }
    return submission;
  }

  @override
  Future<void> save(WorkIssueSubmission submission) async {
    if (!submission.valid || submission.command.key.account != accountScope()) {
      throw const WorkGatewayException('Sign in again to check your response.');
    }
    await _storage
        .write(
          key: _key(submission.command.key),
          value: jsonEncode(submission.toJson()),
        )
        .timeout(const Duration(seconds: 10));
    if (submission.command.key.account != accountScope()) {
      throw const WorkGatewayException('Sign in again to check your response.');
    }
  }
}

/// Read-only, authenticated stock history. Cursors and the immutable snapshot
/// are bound to this exact account/Store/date/product scope. Never apply the
/// returned deltas to local stock, and never include private purchase costs.
abstract interface class WorkStockHistoryGateway {
  Future<WorkspaceStockHistoryPage> readStockHistory(
    WorkspaceStockHistoryQuery query, {
    String? cursor,
    String? snapshotId,
  });
}

class NativeWorkProofPicker
    implements WorkRecoverableProofPicker, WorkRetainedProofPicker {
  NativeWorkProofPicker({
    ImagePicker? imagePicker,
    this.documentPicker,
    this.documentFileName,
    Future<Directory> Function()? temporaryDirectory,
  }) : _imagePicker = imagePicker ?? ImagePicker(),
       _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory;

  final ImagePicker _imagePicker;
  final Future<XFile?> Function()? documentPicker;
  final String? Function()? documentFileName;
  final Future<Directory> Function() _temporaryDirectory;
  static const _maxProofBytes = 10 * 1024 * 1024;

  @override
  Future<WorkPickedProof?> restoreRecorded(Map<String, Object?> record) async {
    final path = record['path'];
    final name = record['name'];
    final type = record['contentType'];
    final size = record['size'];
    final digest = record['sha256'];
    if (path is! String ||
        name is! String ||
        type is! String ||
        size is! int ||
        size <= 0 ||
        size > _maxProofBytes ||
        digest is! String ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(digest)) {
      return null;
    }
    try {
      final root = await (await _temporaryDirectory()).resolveSymbolicLinks();
      final file = File(path);
      final resolved = await file.resolveSymbolicLinks();
      // Never reopen arbitrary provider paths, shared storage or symlink escapes.
      if (!resolved.startsWith('$root${Platform.pathSeparator}')) return null;
      final bytes = await _readDocument(XFile(resolved));
      if (bytes.length != size ||
          crypto.sha256.convert(bytes).toString() != digest) {
        return null;
      }
      final proof = _validateProof(name, bytes);
      if (proof.contentType != type) return null;
      return WorkPickedProof(
        fileName: proof.fileName,
        contentType: proof.contentType,
        bytes: proof.bytes,
        recoveryPath: resolved,
      );
    } on Object {
      return null;
    }
  }

  Future<Uint8List> _readDocument(XFile file) async {
    final reportedLength = await file.length();
    if (reportedLength <= 0 || reportedLength > _maxProofBytes) {
      throw const WorkGatewayException('Choose a document up to 10 MB.');
    }
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in file.openRead()) {
      if (bytes.length + chunk.length > _maxProofBytes) {
        throw const WorkGatewayException('Choose a document up to 10 MB.');
      }
      bytes.add(chunk);
    }
    return bytes.takeBytes();
  }

  @override
  Future<WorkPickedProof?> pick(WorkProofSource source) async {
    try {
      if (source == WorkProofSource.upload ||
          source == WorkProofSource.cloudDrive) {
        XFile? file;
        String? selectedName;
        if (documentPicker != null) {
          file = await documentPicker!();
        } else {
          final selected = await FilePicker.pickFile(
            type: FileType.custom,
            allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
          );
          file = selected?.xFile;
          selectedName = selected?.name;
        }
        if (file == null) return null;
        final bytes = await _readDocument(file);
        final proof = _validateProof(
          selectedName ?? documentFileName?.call() ?? file.name,
          bytes,
        );
        return WorkPickedProof(
          fileName: proof.fileName,
          contentType: proof.contentType,
          bytes: proof.bytes,
          recoveryPath: file.path,
        );
      }
      final image = await _imagePicker.pickImage(
        source: source == WorkProofSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        imageQuality: 92,
        maxWidth: 2400,
        maxHeight: 2400,
      );
      if (image == null) return null;
      return _pickedImage(image, source);
    } on WorkGatewayException {
      rethrow;
    } on PlatformException catch (error) {
      final denied =
          error.code.toLowerCase().contains('denied') ||
          error.code.toLowerCase().contains('permission');
      throw WorkGatewayException(
        denied
            ? 'Camera or photo access was denied. Allow access in device settings, then try again.'
            : 'The device could not open that option. Choose another way to add the document.',
      );
    } on FileSystemException {
      throw const WorkGatewayException(
        'That document could not be read. Choose it again.',
      );
    } on Object {
      throw const WorkGatewayException(
        'The device could not open that option. Choose another way to add the document.',
      );
    }
  }

  Future<WorkPickedProof> _pickedImage(
    XFile image,
    WorkProofSource source,
  ) async {
    final proof = _validateProof(image.name, await _readDocument(image));
    return WorkPickedProof(
      fileName: source == WorkProofSource.camera
          ? 'Camera photo.${proof.fileName.split('.').last.toLowerCase()}'
          : proof.fileName,
      contentType: proof.contentType,
      bytes: proof.bytes,
      recoveryPath: image.path,
    );
  }

  @override
  Future<WorkPickedProof?> recover(WorkProofSource source) async {
    try {
      final result = await _imagePicker.retrieveLostData();
      if (result.exception != null) {
        throw const WorkGatewayException(
          'The camera could not return the document. Please add it again.',
        );
      }
      final file = result.files?.firstOrNull;
      return file == null ? null : await _pickedImage(file, source);
    } on WorkGatewayException {
      rethrow;
    } on Object {
      throw const WorkGatewayException(
        'Your details are restored. Please add the document again.',
      );
    }
  }
}

/// Durable private product images, isolated from public catalogue approval.
/// Inventory stores the reference, not picker paths or image blobs. No network
/// upload or publication is performed here. Evaluation and real Stores differ.
class WorkPrivateProductPhotoStore {
  WorkPrivateProductPhotoStore({
    required this.accountId,
    required this.storeId,
    required this.evaluationOnly,
    required this.isCurrent,
    Future<Directory> Function()? supportDirectory,
  }) : _supportDirectory = supportDirectory ?? getApplicationSupportDirectory;

  final String accountId, storeId;
  final bool evaluationOnly;
  final bool Function() isCurrent;
  final Future<Directory> Function() _supportDirectory;
  static const _limit = 10 * 1024 * 1024;
  // Match the existing public still-image policy; this does not grant approval.
  static const _displaySide = 2048, _displayPixels = 4000000, _displayMinimumSide = 128;

  String get owner => crypto.sha256
      .convert(
        utf8.encode(
          jsonEncode([
            'store-product-photo-v1',
            evaluationOnly,
            accountId,
            storeId,
          ]),
        ),
      )
      .toString();

  void _checkScope() {
    if (accountId.trim().isEmpty || storeId.trim().isEmpty || !isCurrent()) {
      throw const WorkGatewayException(
        'Store changed. Open the product again.',
      );
    }
  }

  Future<Directory> _directory() async {
    _checkScope();
    final support = await _supportDirectory();
    final base = await support.resolveSymbolicLinks();
    var path = base;
    for (final segment in ['store-product-photos-v1', owner]) {
      path = '$path${Platform.pathSeparator}$segment';
      final type = await FileSystemEntity.type(path, followLinks: false);
      if (type != FileSystemEntityType.notFound &&
          type != FileSystemEntityType.directory) {
        throw const WorkGatewayException(
          'Product photo storage is unavailable.',
        );
      }
      final directory = await Directory(path).create();
      if (await directory.resolveSymbolicLinks() != path) {
        throw const WorkGatewayException(
          'Product photo storage is unavailable.',
        );
      }
    }
    _checkScope();
    return Directory(path);
  }

  String _fileName(WorkspacePrivateProductPhoto photo) {
    final identity = crypto.sha256.convert(utf8.encode(photo.identity));
    return '$identity-${photo.sha256}.png';
  }

  Future<Uint8List> _verifiedBytes(
    File file,
    WorkspacePrivateProductPhoto photo,
  ) async {
    if (await FileSystemEntity.type(file.path, followLinks: false) !=
            FileSystemEntityType.file ||
        await file.length() != photo.byteLength) {
      throw const WorkGatewayException(
        'Saved photo is unavailable. Choose it again.',
      );
    }
    final builder = BytesBuilder(copy: false);
    await for (final chunk in file.openRead()) {
      if (builder.length + chunk.length > photo.byteLength) {
        throw const WorkGatewayException(
          'Saved photo changed. Choose it again.',
        );
      }
      builder.add(chunk);
    }
    final bytes = builder.takeBytes();
    if (bytes.length != photo.byteLength ||
        crypto.sha256.convert(bytes).toString() != photo.sha256) {
      throw const WorkGatewayException('Saved photo changed. Choose it again.');
    }
    _checkScope();
    return bytes;
  }

  Future<Uint8List> read(WorkspaceCatalogueItem product) async {
    _checkScope();
    final photo = product.privatePhoto;
    if (photo == null || photo.owner != owner || !photo.matches(product)) {
      throw const WorkGatewayException(
        'Photo does not belong to this Store product.',
      );
    }
    WorkspacePrivateProductPhoto.fromJson(photo.toJson());
    final directory = await _directory();
    return _verifiedBytes(
      File('${directory.path}${Platform.pathSeparator}${_fileName(photo)}'),
      photo,
    );
  }

  /// Uses an actual selected image. Re-encodes a bounded still image to avoid
  /// retaining GPS/EXIF/provider metadata; does not invent or replace its content.
  Future<WorkspacePrivateProductPhoto> save({
    required WorkspaceCatalogueItem product,
    required WorkPickedProof picked,
  }) async {
    _checkScope();
    if (product.cataloguePhoto != null ||
        workspaceMasterCatalogue.any(
          (entry) => entry.canonicalId == product.canonicalId,
        )) {
      throw const WorkGatewayException(
        'MoolSocial manages this catalogue product photo.',
      );
    }
    if (!const [
          'image/jpeg',
          'image/png',
          'image/webp',
        ].contains(picked.contentType) ||
        picked.bytes.isEmpty ||
        picked.bytes.length > _limit) {
      throw const WorkGatewayException(
        'Choose a JPG, PNG or WebP product photo up to 10 MB.',
      );
    }
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    ui.Image? image;
    late Uint8List bytes;
    late int width, height;
    try {
      buffer = await ui.ImmutableBuffer.fromUint8List(picked.bytes);
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      // Technical floor only, not an assertion of composition or media rights.
      // A square presentation contains the whole source; it never stretches it.
      if (min(descriptor.width, descriptor.height) < 256 ||
          max(descriptor.width, descriptor.height) < 512) {
        throw const WorkGatewayException(
          'Choose a clearer product image: at least 512 pixels on the longer side and 256 on the shorter side.',
        );
      }
      if (descriptor.width <= 0 ||
          descriptor.height <= 0 ||
          descriptor.width * descriptor.height > 32000000) {
        throw const WorkGatewayException('Choose a smaller product photo.');
      }
      final ratio = min(1.0, min(_displaySide / max(descriptor.width, descriptor.height),
        sqrt(_displayPixels / (descriptor.width * descriptor.height))));
      final targetWidth = max(1, (descriptor.width * ratio).floor());
      final targetHeight = max(1, (descriptor.height * ratio).floor());
      if (min(targetWidth, targetHeight) < _displayMinimumSide) {
        throw const WorkGatewayException('Choose a less narrow product photo that stays clear when resized.');
      }
      codec = await descriptor.instantiateCodec(
        targetWidth: targetWidth,
        targetHeight: targetHeight,
      );
      image = (await codec.getNextFrame()).image;
      width = image.width;
      height = image.height;
      if (min(width, height) < _displayMinimumSide || max(width, height) > _displaySide || width * height > _displayPixels) {
        throw const WorkGatewayException('Choose a product photo that stays clear when resized.');
      }
      final encoded = await image.toByteData(format: ui.ImageByteFormat.png);
      if (encoded == null || encoded.lengthInBytes > _limit) {
        throw const WorkGatewayException('Choose a smaller product photo.');
      }
      bytes = encoded.buffer.asUint8List(
        encoded.offsetInBytes,
        encoded.lengthInBytes,
      );
    } on WorkGatewayException {
      rethrow;
    } on Object {
      throw const WorkGatewayException(
        'This product photo could not be opened. Choose another copy.',
      );
    } finally {
      image?.dispose();
      codec?.dispose();
      descriptor?.dispose();
      buffer?.dispose();
    }
    _checkScope();
    final photo = WorkspacePrivateProductPhoto(
      owner: owner,
      identity: WorkspacePrivateProductPhoto.identityOf(product),
      sha256: crypto.sha256.convert(bytes).toString(),
      byteLength: bytes.length,
      width: width,
      height: height,
    );
    WorkspacePrivateProductPhoto.fromJson(photo.toJson());
    final directory = await _directory();
    final target = File(
      '${directory.path}${Platform.pathSeparator}${_fileName(photo)}',
    );
    if (await target.exists()) {
      await _verifiedBytes(target, photo);
      return photo;
    }
    // Staging is owned by this operation only. Never remove another photo or
    // directory; a scope change can leave an unreferenced private image safely.
    final staging = await File(
      '${target.path}.${DateTime.now().microsecondsSinceEpoch}.${Random.secure().nextInt(1 << 32)}.pending',
    ).create(exclusive: true);
    try {
      await staging.writeAsBytes(bytes, flush: true);
      _checkScope();
      await staging.rename(target.path);
      await _verifiedBytes(target, photo);
      return photo;
    } finally {
      if (await staging.exists()) await staging.delete();
    }
  }
}

class ReviewWorkProofPicker implements WorkProofPicker {
  @override
  Future<WorkPickedProof?> pick(
    WorkProofSource source,
  ) async => WorkPickedProof(
    fileName:
        source == WorkProofSource.upload || source == WorkProofSource.cloudDrive
        ? 'review-proof.pdf'
        : 'review-proof.jpg',
    contentType:
        source == WorkProofSource.upload || source == WorkProofSource.cloudDrive
        ? 'application/pdf'
        : 'image/jpeg',
    bytes: Uint8List.fromList(const [0xff, 0xd8, 0xff, 0xd9]),
  );
}

abstract interface class WorkProofUploadTransport {
  Future<void> put({
    required Uri url,
    required Map<String, String> headers,
    required Uint8List bytes,
  });
}

class IoWorkProofUploadTransport implements WorkProofUploadTransport {
  IoWorkProofUploadTransport({HttpClient? client})
    : _client = client ?? HttpClient();

  final HttpClient _client;

  @override
  Future<void> put({
    required Uri url,
    required Map<String, String> headers,
    required Uint8List bytes,
  }) async {
    if (url.scheme != 'https' || !url.host.endsWith('googleapis.com')) {
      throw const WorkGatewayException(
        'Document upload could not be prepared. Choose the document again.',
      );
    }
    try {
      final request = await _client
          .putUrl(url)
          .timeout(const Duration(seconds: 15));
      request.contentLength = bytes.length;
      for (final entry in headers.entries) {
        if (entry.key.toLowerCase() == 'content-length') continue;
        request.headers.set(entry.key, entry.value);
      }
      request.add(bytes);
      final response = await request.close().timeout(
        const Duration(seconds: 45),
      );
      await response.drain<void>();
      if ((response.statusCode >= 200 && response.statusCode < 300) ||
          response.statusCode == HttpStatus.preconditionFailed) {
        return;
      }
      throw WorkGatewayException(
        response.statusCode == HttpStatus.unauthorized ||
                response.statusCode == HttpStatus.forbidden
            ? 'Document upload expired. Choose the document again.'
            : 'Document could not upload. Check your connection and try again.',
        retryable:
            response.statusCode == HttpStatus.requestTimeout ||
            response.statusCode == HttpStatus.tooManyRequests ||
            response.statusCode >= 500,
      );
    } on WorkGatewayException {
      rethrow;
    } on TimeoutException {
      throw const WorkGatewayException(
        'Document upload timed out. Check your connection and try again.',
        retryable: true,
      );
    } on SocketException {
      throw const WorkGatewayException(
        'Document could not upload. Check your connection and try again.',
        retryable: true,
      );
    } on Object {
      throw const WorkGatewayException(
        'Document could not upload. Choose the document again.',
      );
    }
  }
}

class WorkProfileSubmission {
  const WorkProfileSubmission({
    required this.familyId,
    required this.profileId,
    required this.name,
    this.authorizedPersonName = '',
    this.businessRelationship = '',
    required this.area,
    required this.primaryActivity,
    required this.proofReferences,
    this.primaryMobile = '',
    this.email = '',
    this.alternateMobile = '',
    this.connectedProvider = '',
    this.connectedProviderAccount = '',
    required this.alternateMobileVerified,
    required this.idempotencyKey,
  });
  final String familyId;
  final String profileId;
  final String name;
  final String authorizedPersonName;
  final String businessRelationship;
  final String area;
  final String primaryActivity;
  final Map<String, String> proofReferences;
  final String primaryMobile;
  final String email;
  final String alternateMobile;
  final String connectedProvider;
  final String connectedProviderAccount;
  final bool alternateMobileVerified;
  final String idempotencyKey;
}

enum WorkRemoteReviewStatus { pending, approved, rejected, suspended, live }

class WorkReviewResult {
  const WorkReviewResult({
    required this.caseId,
    required this.status,
    required this.plan,
    this.workspaceId,
    this.reason,
    this.profileId,
    this.name,
    this.area,
    this.primaryActivity,
  });
  final String caseId;
  final WorkRemoteReviewStatus status;
  final String plan;
  final String? workspaceId;
  final String? reason;
  final String? profileId;
  final String? name;
  final String? area;
  final String? primaryActivity;
}

/// Version 2 adds authoritative time requests; commands exclude payment, stock posting and
/// handover. Customer collection continues through its separately owned,
/// authenticated collection contract; a normal order reply cannot authorise it.
enum WorkOrderAction { accept, ready, reject, requestTime }

enum WorkOrderReplyState { applied, rejected, pending }

enum WorkOrderOperationState { submitting, reconciling, uncertain }

class WorkOrderCommand {
  const WorkOrderCommand({
    required this.accountScope,
    required this.workspaceId,
    required this.orderId,
    required this.operationId,
    required this.expectedRevision,
    required this.action,
    this.reason,
    this.additionalMinutes,
    this.expectedAcceptanceDeadline,
    this.version = contractVersion,
    this.purchaseReference,
    this.purchaseRealm,
  });

  static const contractVersion = 2;
  final String accountScope, workspaceId, orderId, operationId;
  final int expectedRevision;
  final WorkOrderAction action;
  final String? reason;
  final int version;
  final int? additionalMinutes;
  final DateTime? expectedAcceptanceDeadline;
  final WorkspacePurchaseReference? purchaseReference;
  final String? purchaseRealm;
}

class WorkOrderReply {
  WorkOrderReply({
    required this.accountScope,
    required this.workspaceId,
    required this.orderId,
    required this.operationId,
    required this.revision,
    required this.state,
    WorkspaceOrderRecord? order,
    this.delivery,
  }) : order = order?.copyWith();

  final String accountScope, workspaceId, orderId, operationId;
  final int revision;
  final WorkOrderReplyState state;
  final WorkspaceOrderRecord? order;

  /// Full order-scoped projection. Null removes a previous assignment; callers
  /// must not submit partial order events here. Collection uses its own contract.
  final WorkspaceDeliveryAssignment? delivery;
}

/// Backend adapters must authenticate the account independently, enforce Store
/// permissions, expected revision and legal transitions, and deduplicate the
/// same operation atomically with all business effects. IDs are not credentials.
/// Reconcile is read-only: an unknown operation must not be submitted again
/// unless the authority explicitly resolves the original attempt as rejected.
abstract interface class WorkOrderCommandGateway {
  Future<WorkOrderReply> submitOrderCommand(WorkOrderCommand command);
  Future<WorkOrderReply> reconcileOrderCommand(WorkOrderCommand command);
}

/// Bridges exact purchased-order commands to the existing durable controller.
/// References are captured in its pending journal, not guessed from legacy IDs.
class WorkspaceOperationalOrderCommandGateway implements WorkOrderCommandGateway {
  const WorkspaceOperationalOrderCommandGateway({required this.gateway,
    required this.realm, required this.accountScope, required this.workspaceId});
  final AuthenticatedWorkspaceOrderOperationsGateway gateway;
  final String realm, accountScope, workspaceId;
  bool get isCurrent => gateway.isCurrent &&
      gateway.identity.accountUserId == accountScope &&
      const ['evaluation', 'production'].contains(realm) && workspaceId.isNotEmpty;

  WorkOrderReply _reply(WorkspaceOperationalOrderSnapshot snapshot, String operationId, WorkOrderReplyState state) {
    if (!isCurrent || snapshot.realm != realm || snapshot.viewerUserId != accountScope ||
        snapshot.viewerRole != WorkspaceOrderIdentityRole.seller || snapshot.reference.storeId != workspaceId) {
      throw const WorkGatewayException('This order needs a current Store session.');
    }
    return WorkOrderReply(accountScope: accountScope, workspaceId: workspaceId,
      orderId: snapshot.reference.orderId, operationId: operationId, revision: snapshot.revision,
      state: state, order: WorkspaceOrderRecord.fromOperational(snapshot));
  }

  Future<WorkOrderReply?> read(WorkspacePurchaseReference reference) async {
    if (!isCurrent || reference.storeId != workspaceId) return null;
    final snapshot = await gateway.read(role: WorkspaceOrderIdentityRole.seller, realm: realm, reference: reference);
    return snapshot == null || !isCurrent ? null : _reply(snapshot, 'snapshot', WorkOrderReplyState.applied);
  }

  Future<WorkOrderReply> _command(WorkOrderCommand command, bool reconcile) async {
    final ref = command.purchaseReference;
    if (!isCurrent || command.version != WorkOrderCommand.contractVersion ||
        command.accountScope != accountScope || command.workspaceId != workspaceId ||
        command.purchaseRealm != realm || ref == null || !ref.valid ||
        ref.storeId != workspaceId || ref.orderId != command.orderId ||
        command.action == WorkOrderAction.requestTime || command.additionalMinutes != null ||
        command.expectedAcceptanceDeadline != null) {
      throw const WorkGatewayException('The original order operation cannot be verified.');
    }
    final result = await gateway.command(realm: realm, reference: ref, operationId: command.operationId,
      expectedRevision: command.expectedRevision, action: command.action.name, reason: command.reason, reconcile: reconcile);
    if (result == null || !isCurrent) {
      throw const WorkGatewayException('Order result unconfirmed. Check the original attempt.');
    }
    return _reply(result.snapshot, result.operationId, switch (result.state) {
      'applied' => WorkOrderReplyState.applied,
      'rejected' => WorkOrderReplyState.rejected,
      _ => WorkOrderReplyState.pending,
    });
  }
  @override
  Future<WorkOrderReply> submitOrderCommand(WorkOrderCommand command) => _command(command, false);
  @override
  Future<WorkOrderReply> reconcileOrderCommand(WorkOrderCommand command) => _command(command, true);
}

/// Explicit capability: legacy timing endpoints are not revisioned commands.
abstract interface class WorkOrderTimeCommandGateway
    implements WorkOrderCommandGateway {
  bool get supportsOrderTimeRequests;
}

/// A dedicated order journal, never a document draft or proof of success.
abstract interface class WorkOrderPendingStore {
  Future<List<WorkOrderCommand>> readPending(
    String accountScope,
    String workspaceId,
  );
  Future<void> savePending(WorkOrderCommand command);
  Future<void> removePending(WorkOrderCommand command);
}

class SecureWorkOrderPendingStore implements WorkOrderPendingStore {
  SecureWorkOrderPendingStore({
    FlutterSecureStorage? storage,
    String? Function()? currentAccount,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _currentAccount = currentAccount ?? _signedInAccount;

  final FlutterSecureStorage _storage;
  final String? Function() _currentAccount;
  // Across instances: timed-out callers must not release a still-running native
  // read/write and let a later write erase an independently pending order.
  static final Map<String, Future<void>> _tails = {};
  static const _journalVersion = 1;
  static String? _signedInAccount() {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } on Object {
      return null;
    }
  }

  String _key(String account, String store) =>
      'moolsocial.workspace.order-pending.v1.${base64UrlEncode(utf8.encode(jsonEncode([account, store])))}';

  void _checkAccount(String account, String store) {
    if (account.isEmpty || store.isEmpty || _currentAccount() != account) {
      throw const WorkGatewayException('Sign in again to check this order.');
    }
  }

  Future<T> _serial<T>(String key, Future<T> Function() operation) {
    final previous = _tails[key] ?? Future<void>.value();
    final result = previous.then((_) => operation());
    final tail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _tails[key] = tail;
    unawaited(
      tail.then((_) {
        if (identical(_tails[key], tail)) _tails.remove(key);
      }),
    );
    return result;
  }

  static Map<String, Object?> _encode(WorkOrderCommand command) => {
    'version': command.version,
    'orderId': command.orderId,
    'operationId': command.operationId,
    'expectedRevision': command.expectedRevision,
    'action': command.action.name,
    'reason': command.reason,
    'additionalMinutes': command.additionalMinutes,
    'expectedAcceptanceDeadline': command.expectedAcceptanceDeadline
        ?.toUtc()
        .toIso8601String(),
    if (command.purchaseReference != null) ...{
      'purchaseReference': command.purchaseReference!.toJson(),
      'purchaseRealm': command.purchaseRealm,
    },
  };

  static bool _valid(WorkOrderCommand command) =>
      {1, WorkOrderCommand.contractVersion}.contains(command.version) &&
      command.orderId.trim().isNotEmpty &&
      command.operationId.trim().isNotEmpty &&
      command.expectedRevision >= 0 &&
      (command.purchaseReference == null ? command.purchaseRealm == null :
        command.version == WorkOrderCommand.contractVersion &&
        command.expectedRevision >= 1 &&
        const ['evaluation', 'production'].contains(command.purchaseRealm) &&
        command.purchaseReference!.valid &&
        command.purchaseReference!.storeId == command.workspaceId &&
        command.purchaseReference!.orderId == command.orderId &&
        command.action != WorkOrderAction.requestTime) &&
      (command.action == WorkOrderAction.reject
          ? command.reason != null && command.reason!.trim().isNotEmpty
          : command.reason == null) &&
      (command.action == WorkOrderAction.requestTime
          ? command.version == 2 &&
                {2, 5}.contains(command.additionalMinutes) &&
                command.expectedAcceptanceDeadline != null
          : command.additionalMinutes == null &&
                command.expectedAcceptanceDeadline == null);

  Future<List<WorkOrderCommand>> _read(String account, String store) async {
    _checkAccount(account, store);
    final raw = await _storage.read(key: _key(account, store));
    _checkAccount(account, store);
    if (raw == null) return [];
    final data = jsonDecode(raw);
    if (data is! Map ||
        data['version'] != _journalVersion ||
        data['accountScope'] != account ||
        data['workspaceId'] != store ||
        data['entries'] is! List) {
      throw const FormatException('Invalid pending order journal');
    }
    final commands = <WorkOrderCommand>[];
    final orders = <String>{}, operations = <String>{};
    for (final entry in data['entries'] as List) {
      if (entry is! Map ||
          entry['orderId'] is! String ||
          entry['operationId'] is! String ||
          entry['expectedRevision'] is! int ||
          entry['action'] is! String ||
          (entry['reason'] != null && entry['reason'] is! String) ||
          (entry['version'] != null && entry['version'] is! int) ||
          (entry['additionalMinutes'] != null &&
              entry['additionalMinutes'] is! int) ||
          (entry['expectedAcceptanceDeadline'] != null &&
              entry['expectedAcceptanceDeadline'] is! String)) {
        throw const FormatException('Invalid pending order entry');
      }
      final deadlineText = entry['expectedAcceptanceDeadline'] as String?;
      final deadline = deadlineText == null
          ? null
          : DateTime.tryParse(deadlineText);
      if (deadlineText != null &&
          deadline?.toUtc().toIso8601String() != deadlineText) {
        throw const FormatException('Invalid pending order deadline');
      }
      final command = WorkOrderCommand(
        accountScope: account,
        workspaceId: store,
        orderId: entry['orderId'] as String,
        operationId: entry['operationId'] as String,
        expectedRevision: entry['expectedRevision'] as int,
        action: WorkOrderAction.values.byName(entry['action'] as String),
        reason: entry['reason'] as String?,
        version: (entry['version'] as int?) ?? 1,
        additionalMinutes: entry['additionalMinutes'] as int?,
        expectedAcceptanceDeadline: deadline,
        purchaseReference: entry.containsKey('purchaseReference')
            ? WorkspacePurchaseReference.fromJson(entry['purchaseReference']) : null,
        purchaseRealm: entry['purchaseRealm'] as String?,
      );
      if (!_valid(command) ||
          !orders.add(command.orderId) ||
          !operations.add(command.operationId)) {
        throw const FormatException('Conflicting pending order entry');
      }
      commands.add(command);
    }
    return commands;
  }

  Future<void> _write(
    String account,
    String store,
    List<WorkOrderCommand> commands,
  ) async {
    _checkAccount(account, store);
    // Keep an empty envelope rather than deleting unrelated storage keys.
    await _storage.write(
      key: _key(account, store),
      value: jsonEncode({
        'version': _journalVersion,
        'accountScope': account,
        'workspaceId': store,
        'entries': commands.map(_encode).toList(),
      }),
    );
    _checkAccount(account, store);
  }

  @override
  Future<List<WorkOrderCommand>> readPending(
    String accountScope,
    String workspaceId,
  ) => _serial(
    _key(accountScope, workspaceId),
    () => _read(accountScope, workspaceId),
  );

  @override
  Future<void> savePending(
    WorkOrderCommand command,
  ) => _serial(_key(command.accountScope, command.workspaceId), () async {
    if (!_valid(command)) throw const FormatException('Invalid order command');
    final commands = await _read(command.accountScope, command.workspaceId);
    for (final saved in commands) {
      if (saved.orderId == command.orderId ||
          saved.operationId == command.operationId) {
        if (jsonEncode(_encode(saved)) == jsonEncode(_encode(command))) return;
        throw const FormatException('Pending order cannot be overwritten');
      }
    }
    commands.add(command);
    await _write(command.accountScope, command.workspaceId, commands);
  });

  @override
  Future<void> removePending(WorkOrderCommand command) => _serial(
    _key(command.accountScope, command.workspaceId),
    () async {
      final commands = await _read(command.accountScope, command.workspaceId);
      final matches = commands
          .where((saved) => saved.orderId == command.orderId)
          .toList();
      if (matches.isEmpty) return;
      if (jsonEncode(_encode(matches.single)) != jsonEncode(_encode(command))) {
        throw const FormatException(
          'A different order operation remains pending',
        );
      }
      commands.removeWhere((saved) => saved.orderId == command.orderId);
      await _write(command.accountScope, command.workspaceId, commands);
    },
  );
}

/// Encrypted intent only, not a feedback feed or a server outcome. Native work
/// stays serialized across replacement controllers, including timed-out callers.
class SecureStoreFeedbackPendingStore implements StoreFeedbackPendingStore {
  SecureStoreFeedbackPendingStore({FlutterSecureStorage? storage,
    String? Function()? currentAccount})
      : _storage = storage ?? const FlutterSecureStorage(),
        _currentAccount = currentAccount ?? SecureWorkOrderPendingStore._signedInAccount;
  final FlutterSecureStorage _storage;
  final String? Function() _currentAccount;
  static final Map<String, Future<void>> _tails = {};
  String _key(StoreFeedbackScope scope) =>
      'moolsocial.workspace.feedback-pending.v1.${base64UrlEncode(utf8.encode(jsonEncode([scope.account, scope.store])))}';
  void _check(StoreFeedbackScope scope) {
    if (scope.account.trim().isEmpty || scope.store.trim().isEmpty ||
        _currentAccount() != scope.account) {
      throw const WorkGatewayException('Sign in again to check this request.');
    }
  }
  Future<T> _serial<T>(StoreFeedbackScope scope, Future<T> Function() operation) {
    final key = _key(scope);
    final result = (_tails[key] ?? Future<void>.value()).then((_) => operation());
    final tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    _tails[key] = tail;
    unawaited(tail.then((_) {
      if (identical(_tails[key], tail)) _tails.remove(key);
    }));
    return result;
  }
  bool _same(StoreFeedbackCommand a, StoreFeedbackCommand b) =>
      StoreFeedbackResult(command: a, outcome: StoreFeedbackOutcome.unknown).matches(b);
  Future<StoreFeedbackCommand?> _read(StoreFeedbackScope scope) async {
    _check(scope);
    final raw = await _storage.read(key: _key(scope));
    _check(scope);
    if (raw == null) return null;
    final data = jsonDecode(raw);
    if (data is! Map || data.length != 4 || data['version'] is! int || data['version'] != 1 ||
        data['accountScope'] != scope.account || data['workspaceId'] != scope.store ||
        !data.containsKey('command')) {
      throw const FormatException('Invalid feedback journal');
    }
    if (data['command'] == null) return null;
    final command = StoreFeedbackCommand.fromJson(data['command']);
    if (command.scope != scope) throw const FormatException('Wrong feedback owner');
    return command;
  }
  Future<void> _write(StoreFeedbackScope scope, StoreFeedbackCommand? command) async {
    _check(scope);
    await _storage.write(key: _key(scope), value: jsonEncode({
      'version': 1, 'accountScope': scope.account, 'workspaceId': scope.store,
      'command': command?.toJson(),
    }));
    _check(scope);
  }
  @override
  Future<StoreFeedbackCommand?> readPending(StoreFeedbackScope scope) =>
      _serial(scope, () => _read(scope));
  @override
  Future<void> savePending(StoreFeedbackCommand command) =>
      _serial(command.scope, () async {
        if (!command.valid) throw const FormatException('Invalid feedback request');
        final previous = await _read(command.scope);
        if (previous != null) {
          if (_same(previous, command)) return;
          throw const FormatException('Another feedback request remains pending');
        }
        await _write(command.scope, command);
      });
  @override
  Future<void> removePending(StoreFeedbackCommand original) =>
      _serial(original.scope, () async {
        final previous = await _read(original.scope);
        if (previous == null) return;
        if (!_same(previous, original)) {
          throw const FormatException('A different feedback request remains pending');
        }
        await _write(original.scope, null);
      });
}

/// One encrypted original listing request per account/Store/realm. No inventory
/// snapshot or provider outcome is stored; timeouts do not release native tails.
class SecureWorkCatalogueBindingPendingStore implements WorkspaceCatalogueBindingPendingStore {
  SecureWorkCatalogueBindingPendingStore({FlutterSecureStorage? storage, String? Function()? currentAccount})
    : _storage = storage ?? const FlutterSecureStorage(),
      _currentAccount = currentAccount ?? SecureWorkOrderPendingStore._signedInAccount;
  final FlutterSecureStorage _storage;
  final String? Function() _currentAccount;
  static final Map<String, Future<void>> _tails = {};
  WorkspaceCatalogueBindingScope _scope(WorkspaceCatalogueBindingIntent value) =>
    (account: value.accountId, store: value.storeId, realm: value.realm);
  String _key(WorkspaceCatalogueBindingScope scope) =>
    'moolsocial.workspace.catalogue-binding.v1.${base64UrlEncode(utf8.encode(jsonEncode([scope.account, scope.store, scope.realm])))}';
  void _check(WorkspaceCatalogueBindingScope scope) {
    if (scope.account.trim().isEmpty || scope.store.trim().isEmpty ||
        !{'production', 'evaluation'}.contains(scope.realm) || _currentAccount() != scope.account) {
      throw const WorkGatewayException('Sign in again to check this listing update.');
    }
  }
  Future<T> _serial<T>(WorkspaceCatalogueBindingScope scope, Future<T> Function() operation) {
    final key = _key(scope);
    final result = (_tails[key] ?? Future<void>.value()).then((_) => operation());
    final tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    _tails[key] = tail;
    unawaited(tail.then((_) { if (identical(_tails[key], tail)) _tails.remove(key); }));
    return result;
  }
  Future<WorkspaceCatalogueBindingIntent?> _read(WorkspaceCatalogueBindingScope scope) async {
    _check(scope);
    final raw = await _storage.read(key: _key(scope));
    _check(scope);
    if (raw == null) return null;
    final envelope = jsonDecode(raw);
    if (envelope is! Map || envelope.length != 5 || envelope['schemaVersion'] != 1 ||
        envelope['accountId'] != scope.account || envelope['storeId'] != scope.store || envelope['realm'] != scope.realm ||
        !envelope.containsKey('intent')) {
      throw const FormatException('Invalid listing journal');
    }
    if (envelope['intent'] == null) return null;
    final intent = WorkspaceCatalogueBindingIntent.fromJson(envelope['intent']);
    if (_scope(intent) != scope) throw const FormatException('Wrong listing request owner');
    return intent;
  }
  Future<void> _write(WorkspaceCatalogueBindingScope scope, WorkspaceCatalogueBindingIntent? intent) async {
    _check(scope);
    await _storage.write(key: _key(scope), value: jsonEncode({'schemaVersion': 1,
      'accountId': scope.account, 'storeId': scope.store, 'realm': scope.realm, 'intent': intent?.toJson()}));
    _check(scope);
  }
  bool _same(WorkspaceCatalogueBindingIntent a, WorkspaceCatalogueBindingIntent b) =>
    jsonEncode(a.toJson()) == jsonEncode(b.toJson());
  @override
  Future<WorkspaceCatalogueBindingIntent?> readPending(WorkspaceCatalogueBindingScope scope) =>
    _serial(scope, () => _read(scope));
  @override
  Future<void> savePending(WorkspaceCatalogueBindingIntent original) => _serial(_scope(original), () async {
    final previous = await _read(_scope(original));
    if (previous != null) {
      if (_same(previous, original)) return;
      throw const FormatException('Another listing update needs checking');
    }
    await _write(_scope(original), original);
  });
  @override
  Future<void> removePending(WorkspaceCatalogueBindingIntent original) => _serial(_scope(original), () async {
    final previous = await _read(_scope(original));
    if (previous == null) return;
    if (!_same(previous, original)) throw const FormatException('Keep the original listing request');
    await _write(_scope(original), null);
  });
}

/// An original Store-reported quantity, never the full inventory or a ledger.
/// Same account-scoped encrypted/native-tail pattern as product submissions.
/// Dedicated Bulk originals; reuses the existing encrypted serialized-storage
/// pattern without mixing agreements with orders, payment attempts or Stock.
class SecureWorkBulkQuoteJournal implements WorkspaceBulkQuoteJournal, WorkspaceBulkQuoteIndex {
  SecureWorkBulkQuoteJournal({FlutterSecureStorage? storage, String? Function()? currentAccount, DateTime Function()? now})
    : _storage = storage ?? const FlutterSecureStorage(),
      _currentAccount = currentAccount ?? SecureWorkOrderPendingStore._signedInAccount, _now = now ?? DateTime.now;
  final FlutterSecureStorage _storage;
  final String? Function() _currentAccount;
  final DateTime Function() _now;
  static final _tails = <String, Future<void>>{};
  String _indexKey(WorkspaceBulkQuoteNamespace owner) => 'moolsocial.workspace.bulk-quote-index.v1.${
    base64UrlEncode(utf8.encode(jsonEncode([owner.account, owner.realm, owner.role])))}';
  WorkspaceBulkQuoteNamespace _namespace(WorkspaceBulkQuoteScope scope) => (account: scope.account, realm: scope.realm, role: scope.role);
  void _checkNamespace(WorkspaceBulkQuoteNamespace owner) {
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]{2,127}$').hasMatch(owner.account) ||
      !{'production', 'evaluation'}.contains(owner.realm) || !{'buyer', 'supplier'}.contains(owner.role) ||
      _currentAccount() != owner.account) {
      throw const WorkGatewayException('Sign in again to check saved requests.');
    }
  }
  Future<List<String>> _readIndex(WorkspaceBulkQuoteNamespace owner) async {
    _checkNamespace(owner); final raw = await _storage.read(key: _indexKey(owner)); _checkNamespace(owner);
    if (raw == null) return [];
    if (raw.length > 20000) throw const FormatException('Keep saved request recovery.');
    final r = jsonDecode(raw), keys = {'schemaVersion', 'account', 'realm', 'role', 'stores'};
    if (r is! Map || r.length != keys.length || r.keys.any((k) => !keys.contains(k)) || r['schemaVersion'] != 1 ||
      r['account'] != owner.account || r['realm'] != owner.realm || r['role'] != owner.role || r['stores'] is! List ||
      (r['stores'] as List).length > 100) {
      throw const FormatException('Keep saved request recovery.');
    }
    final stores = <String>[];
    for (final value in r['stores'] as List) {
      if (value is! String || !RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]{2,127}$').hasMatch(value) ||
        stores.isNotEmpty && stores.last.compareTo(value) >= 0) {
        throw const FormatException('Keep saved request recovery.');
      }
      stores.add(value);
    }
    return stores;
  }
  Future<void> _writeIndex(WorkspaceBulkQuoteNamespace owner, List<String> stores) async {
    _checkNamespace(owner); if (stores.length > 100) throw const FormatException('Check saved requests before adding more.');
    final encoded = jsonEncode({'schemaVersion': 1, 'account': owner.account, 'realm': owner.realm, 'role': owner.role, 'stores': stores..sort()});
    await _storage.write(key: _indexKey(owner), value: encoded); _checkNamespace(owner);
    if (await _storage.read(key: _indexKey(owner)) != encoded) throw const FormatException('Saved requests could not be verified.');
    _checkNamespace(owner);
  }
  String _key(WorkspaceBulkQuoteScope scope) => 'moolsocial.workspace.bulk-quote.v1.${
    base64UrlEncode(utf8.encode(jsonEncode([scope.account, scope.realm, scope.store, scope.role])))}';
  void _check(WorkspaceBulkQuoteScope scope) {
    validateWorkspaceBulkQuoteScope(scope);
    if (_currentAccount() != scope.account) throw const WorkGatewayException('Sign in again to check saved requests.');
  }
  void _original(WorkspaceBulkQuoteScope scope, WorkspaceBulkQuoteIntent value) {
    if (value.account != scope.account || value.realm != scope.realm || value.storeId != scope.store ||
      !(scope.role == 'buyer' ? {'request', 'accept', 'withdraw'} : {'offer', 'withdraw'}).contains(value.kind)) {
      throw const FormatException('Keep the original request owner.');
    }
  }
  Future<T> _serialKey<T>(String key, Future<T> Function() action) {
    final result = (_tails[key] ?? Future<void>.value()).then((_) => action());
    final tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    _tails[key] = tail;
    unawaited(tail.then((_) { if (identical(_tails[key], tail)) _tails.remove(key); }));
    return result;
  }
  Future<T> _serial<T>(WorkspaceBulkQuoteScope scope, Future<T> Function() action) => _serialKey(_indexKey(_namespace(scope)), action);
  @override Future<List<String>> pendingStores(WorkspaceBulkQuoteNamespace owner) => _serialKey(_indexKey(owner), () async {
    final stored = await _readIndex(owner), pending = <String>[];
    for (final store in stored) {
      // The account queue has settled: an absent/validated-empty payload is a
      // harmless partial-save/cleanup pointer, not an unresolved command.
      if ((await _read((account: owner.account, realm: owner.realm, store: store, role: owner.role))).isNotEmpty) pending.add(store);
    }
    if (stored.length != pending.length) await _writeIndex(owner, pending);
    _checkNamespace(owner); return pending;
  });
  Future<List<WorkspaceBulkQuoteIntent>> _read(WorkspaceBulkQuoteScope scope) async {
    _check(scope); final raw = await _storage.read(key: _key(scope)); _check(scope);
    if (raw == null) return [];
    if (utf8.encode(raw).length > 1024 * 1024) throw const FormatException('Keep saved request recovery.');
    final r = jsonDecode(raw), keys = {'schemaVersion', 'account', 'realm', 'store', 'role', 'originals'};
    if (r is! Map || r.length != keys.length || r.keys.any((k) => !keys.contains(k)) || r['schemaVersion'] != 1 ||
      r['account'] != scope.account || r['realm'] != scope.realm || r['store'] != scope.store || r['role'] != scope.role ||
      r['originals'] is! List || (r['originals'] as List).length > 2) {
      throw const FormatException('Keep saved request recovery.');
    }
    final values = <WorkspaceBulkQuoteIntent>[], seen = <String>{};
    for (final row in r['originals'] as List) {
      final value = WorkspaceBulkQuoteIntent.decode(row, account: scope.account, realm: scope.realm, now: _now());
      _original(scope, value);
      if (!seen.add('${value.kind}:${value.operationId}')) throw const FormatException('Keep distinct originals.');
      values.add(value);
    }
    if (values.isNotEmpty) {
      final owner = _namespace(scope), stores = await _readIndex(_namespace(scope));
      if (!stores.contains(scope.store)) await _writeIndex(owner, [...stores, scope.store]);
    }
    return values;
  }
  Future<void> _write(WorkspaceBulkQuoteScope scope, List<WorkspaceBulkQuoteIntent> values) async {
    _check(scope);
    final owner = _namespace(scope), stores = await _readIndex(_namespace(scope));
    // The discoverable pointer must be durable first. A partial write may leave
    // an empty pointer, never an undiscoverable original or another Store's data.
    if (values.isNotEmpty && !stores.contains(scope.store)) await _writeIndex(owner, [...stores, scope.store]);
    final encoded = jsonEncode({'schemaVersion': 1, 'account': scope.account, 'realm': scope.realm,
      'store': scope.store, 'role': scope.role, 'originals': [for (final value in values) value.toJson()]});
    if (utf8.encode(encoded).length > 1024 * 1024) throw const FormatException('Keep saved request recovery.');
    await _storage.write(key: _key(scope), value: encoded); _check(scope);
    final saved = await _storage.read(key: _key(scope)); _check(scope);
    if (saved != encoded) throw const FormatException('Saved requests could not be verified.');
    if (values.isEmpty && stores.contains(scope.store)) await _writeIndex(owner, stores.where((s) => s != scope.store).toList());
  }
  @override Future<List<WorkspaceBulkQuoteIntent>> read(WorkspaceBulkQuoteScope scope) => _serial(scope, () => _read(scope));
  @override Future<void> save(WorkspaceBulkQuoteScope scope, WorkspaceBulkQuoteIntent original) => _serial(scope, () async {
    _original(scope, original);
    final restored = WorkspaceBulkQuoteIntent.decode(original.toJson(), account: scope.account, realm: scope.realm, now: _now());
    final prior = await _read(scope);
    final same = prior.where((p) => p.kind == original.kind && p.operationId == original.operationId).firstOrNull;
    if (same != null) {
      if (jsonEncode(same.toJson()) != jsonEncode(restored.toJson())) throw const FormatException('Keep the exact original request.');
      return;
    }
    // One original plus its explicit withdrawal. Reserve recovery capacity;
    // never evict an unresolved command to make room for a new quotation.
    if (prior.isNotEmpty && !(prior.length == 1 && original.kind == 'withdraw' &&
      {'offer', 'accept'}.contains(prior.single.kind) && prior.single.quoteId == original.quoteId)) {
      throw const FormatException('Check the earlier request first.');
    }
    await _write(scope, [...prior, restored]);
  });
  @override Future<void> remove(WorkspaceBulkQuoteScope scope, WorkspaceBulkQuoteIntent original) => _serial(scope, () async {
    _original(scope, original); final prior = await _read(scope);
    final same = prior.where((p) => p.kind == original.kind && p.operationId == original.operationId).firstOrNull;
    if (same == null) return;
    if (jsonEncode(same.toJson()) != jsonEncode(original.toJson())) throw const FormatException('Keep the exact original request.');
    await _write(scope, prior.where((p) => !identical(p, same)).toList());
  });
}

class SecureWorkStoreStockJournal implements WorkspaceStoreStockJournal {
  SecureWorkStoreStockJournal({FlutterSecureStorage? storage, String? Function()? currentAccount})
    : _storage = storage ?? const FlutterSecureStorage(),
      _currentAccount = currentAccount ?? SecureWorkOrderPendingStore._signedInAccount;
  final FlutterSecureStorage _storage;
  final String? Function() _currentAccount;
  static final _tails = <String, Future<void>>{};
  String _key(WorkspaceStoreStockScope scope) => 'moolsocial.workspace.store-stock.v1.${
    base64UrlEncode(utf8.encode(jsonEncode([scope.account, scope.store, scope.realm, scope.sku])))}';
  void _check(WorkspaceStoreStockScope scope) {
    if (scope.account.isEmpty || scope.store.isEmpty || scope.sku.isEmpty ||
        !{'production', 'evaluation'}.contains(scope.realm) || _currentAccount() != scope.account) {
      throw const WorkGatewayException('Sign in again to check the saved Stock update.');
    }
  }
  Future<T> _serial<T>(WorkspaceStoreStockScope scope, Future<T> Function() action) {
    final key = _key(scope), result = (_tails[key] ?? Future<void>.value()).then((_) => action());
    final tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    _tails[key] = tail;
    unawaited(tail.then((_) { if (identical(_tails[key], tail)) _tails.remove(key); }));
    return result;
  }
  Future<WorkspaceStoreStockIntent?> _read(WorkspaceStoreStockScope scope) async {
    _check(scope);
    final raw = await _storage.read(key: _key(scope));
    _check(scope);
    if (raw == null) return null;
    final value = jsonDecode(raw), keys = {'schemaVersion', 'accountId', 'storeId', 'realm', 'skuId', 'original'};
    if (value is! Map || value.length != keys.length || value.keys.any((key) => !keys.contains(key)) ||
        value['schemaVersion'] is! int || value['schemaVersion'] != 1 || value['accountId'] != scope.account ||
        value['storeId'] != scope.store || value['realm'] != scope.realm || value['skuId'] != scope.sku) {
      throw const FormatException('Keep the saved Stock recovery record.');
    }
    if (value['original'] == null) return null;
    final original = WorkspaceStoreStockIntent.fromJson(value['original']);
    if (original.scope != scope) throw const FormatException('Keep the original Stock owner.');
    return original;
  }
  Future<void> _write(WorkspaceStoreStockScope scope, WorkspaceStoreStockIntent? original) async {
    _check(scope);
    await _storage.write(key: _key(scope), value: jsonEncode({'schemaVersion': 1, 'accountId': scope.account,
      'storeId': scope.store, 'realm': scope.realm, 'skuId': scope.sku, 'original': original?.toJson()}));
    _check(scope);
  }
  @override
  Future<WorkspaceStoreStockIntent?> readPending(WorkspaceStoreStockScope scope) => _serial(scope, () => _read(scope));
  @override
  Future<void> savePending(WorkspaceStoreStockIntent original) => _serial(original.scope, () async {
    WorkspaceStoreStockIntent.fromJson(original.toJson());
    final prior = await _read(original.scope);
    if (prior != null) {
      if (prior.serverFingerprint == original.serverFingerprint) return;
      throw const FormatException('Check the earlier Stock update first.');
    }
    await _write(original.scope, original);
  });
  @override
  Future<void> removePending(WorkspaceStoreStockIntent original) => _serial(original.scope, () async {
    final prior = await _read(original.scope);
    if (prior == null) return;
    if (prior.serverFingerprint != original.serverFingerprint) throw const FormatException('Keep the original Stock update.');
    await _write(original.scope, null);
  });
}

class SecureWorkStockVisibilityJournal implements WorkspaceStockVisibilityJournal {
  SecureWorkStockVisibilityJournal({FlutterSecureStorage? storage, String? Function()? currentAccount})
    : _storage = storage ?? const FlutterSecureStorage(),
      _currentAccount = currentAccount ?? SecureWorkOrderPendingStore._signedInAccount;
  final FlutterSecureStorage _storage;
  final String? Function() _currentAccount;
  static final _tails = <String, Future<void>>{};
  String _key(WorkspaceStoreStockScope scope) => 'moolsocial.workspace.stock-visibility.v1.${
    base64UrlEncode(utf8.encode(jsonEncode([scope.account, scope.store, scope.realm, scope.sku])))}';
  void _check(WorkspaceStoreStockScope scope) {
    if (scope.account.isEmpty || scope.store.isEmpty || scope.sku.isEmpty ||
        !{'production', 'evaluation'}.contains(scope.realm) || _currentAccount() != scope.account) {
      throw const WorkGatewayException('Sign in again to check quantity visibility.');
    }
  }
  Future<T> _serial<T>(WorkspaceStoreStockScope scope, Future<T> Function() action) {
    final key = _key(scope), result = (_tails[key] ?? Future<void>.value()).then((_) => action());
    final tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    _tails[key] = tail;
    unawaited(tail.then((_) { if (identical(_tails[key], tail)) _tails.remove(key); }));
    return result;
  }
  Future<WorkspaceStockVisibilityIntent?> _read(WorkspaceStoreStockScope scope) async {
    _check(scope); final raw = await _storage.read(key: _key(scope)); _check(scope);
    if (raw == null) return null;
    final value = jsonDecode(raw), keys = {'schemaVersion', 'accountId', 'storeId', 'realm', 'skuId', 'original'};
    if (value is! Map || value.length != keys.length || value.keys.any((key) => !keys.contains(key)) ||
        value['schemaVersion'] != 1 || value['accountId'] != scope.account || value['storeId'] != scope.store ||
        value['realm'] != scope.realm || value['skuId'] != scope.sku) { throw const FormatException('Keep the visibility recovery record.'); }
    if (value['original'] == null) return null;
    final original = WorkspaceStockVisibilityIntent.fromJson(value['original']);
    if (original.scope != scope) throw const FormatException();
    return original;
  }
  Future<void> _write(WorkspaceStoreStockScope scope, WorkspaceStockVisibilityIntent? original) async {
    _check(scope);
    await _storage.write(key: _key(scope), value: jsonEncode({'schemaVersion': 1, 'accountId': scope.account,
      'storeId': scope.store, 'realm': scope.realm, 'skuId': scope.sku, 'original': original?.toJson()}));
    _check(scope);
  }
  @override Future<WorkspaceStockVisibilityIntent?> readPending(WorkspaceStoreStockScope scope) => _serial(scope, () => _read(scope));
  @override Future<void> savePending(WorkspaceStockVisibilityIntent original) => _serial(original.scope, () async {
    WorkspaceStockVisibilityIntent.fromJson(original.toJson());
    final prior = await _read(original.scope);
    if (prior != null) {
      if (prior.serverFingerprint != original.serverFingerprint || prior.closing && !original.closing) throw const FormatException('Recover the earlier visibility change first.');
      if (prior.closing == original.closing) return;
    }
    await _write(original.scope, original);
  });
  @override Future<void> removePending(WorkspaceStockVisibilityIntent original) => _serial(original.scope, () async {
    final prior = await _read(original.scope);
    if (prior == null) return;
    if (prior.serverFingerprint != original.serverFingerprint || prior.closing != original.closing) throw const FormatException('Keep the original visibility change.');
    await _write(original.scope, null);
  });
}

/// Same scoped encrypted-journal pattern as listing requests. One immutable
/// original per saved SKU; native tails finish before any later read/write.
class SecureWorkProductSubmissionJournal implements WorkspaceProductSubmissionJournal {
  SecureWorkProductSubmissionJournal({FlutterSecureStorage? storage, String? Function()? currentAccount})
    : _storage = storage ?? const FlutterSecureStorage(),
      _currentAccount = currentAccount ?? SecureWorkOrderPendingStore._signedInAccount;
  final FlutterSecureStorage _storage;
  final String? Function() _currentAccount;
  static final _tails = <String, Future<void>>{};
  String _key(WorkspaceProductSubmissionScope scope) => 'moolsocial.workspace.product-submission.v1.${
    base64UrlEncode(utf8.encode(jsonEncode([scope.account, scope.store, scope.realm, scope.sku])))}';
  void _check(WorkspaceProductSubmissionScope scope) {
    if (scope.account.isEmpty || scope.store.isEmpty || scope.sku.isEmpty ||
        !{'production', 'evaluation'}.contains(scope.realm) || _currentAccount() != scope.account) {
      throw const WorkGatewayException('Sign in again to check the product submission.');
    }
  }
  Future<T> _serial<T>(WorkspaceProductSubmissionScope scope, Future<T> Function() action) {
    final key = _key(scope), result = (_tails[key] ?? Future<void>.value()).then((_) => action());
    final tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    _tails[key] = tail;
    unawaited(tail.then((_) { if (identical(_tails[key], tail)) _tails.remove(key); }));
    return result;
  }
  Future<WorkspaceProductSubmissionIntent?> _read(WorkspaceProductSubmissionScope scope) async {
    _check(scope);
    final raw = await _storage.read(key: _key(scope));
    _check(scope);
    if (raw == null) return null;
    final value = jsonDecode(raw);
    const keys = {'schemaVersion', 'accountId', 'storeId', 'realm', 'skuId', 'original'};
    if (value is! Map || value.length != keys.length || value.keys.any((key) => !keys.contains(key)) ||
        value['schemaVersion'] is! int || value['schemaVersion'] != 1 || value['accountId'] != scope.account ||
        value['storeId'] != scope.store || value['realm'] != scope.realm || value['skuId'] != scope.sku) {
      throw const FormatException('The original product submission needs recovery.');
    }
    if (value['original'] == null) return null;
    final original = WorkspaceProductSubmissionIntent.fromJson(value['original']);
    if (original.scope != scope) throw const FormatException('The product request belongs to another context.');
    return original;
  }
  Future<void> _write(WorkspaceProductSubmissionScope scope, WorkspaceProductSubmissionIntent? original) async {
    _check(scope);
    await _storage.write(key: _key(scope), value: jsonEncode({'schemaVersion': 1, 'accountId': scope.account,
      'storeId': scope.store, 'realm': scope.realm, 'skuId': scope.sku, 'original': original?.toJson()}));
    _check(scope);
  }
  @override
  Future<WorkspaceProductSubmissionIntent?> readPending(WorkspaceProductSubmissionScope scope) => _serial(scope, () => _read(scope));
  @override
  Future<void> savePending(WorkspaceProductSubmissionIntent original) => _serial(original.scope, () async {
    WorkspaceProductSubmissionIntent.fromJson(original.toJson());
    final prior = await _read(original.scope);
    if (prior != null) {
      if (prior.fingerprint == original.fingerprint) return;
      throw const FormatException('Check the earlier product request before another submission.');
    }
    await _write(original.scope, original);
  });
  @override
  Future<void> removePending(WorkspaceProductSubmissionIntent original) => _serial(original.scope, () async {
    final prior = await _read(original.scope);
    if (prior == null) return;
    if (prior.fingerprint != original.fingerprint) throw const FormatException('Keep the original product request.');
    await _write(original.scope, null);
  });
}

/// The family journal remains a separate original from each SKU submission.
class SecureWorkProductMediaJournal implements WorkspaceProductMediaJournal {
  SecureWorkProductMediaJournal({FlutterSecureStorage? storage, String? Function()? currentAccount, DateTime Function()? now})
    : _storage = storage ?? const FlutterSecureStorage(), _currentAccount = currentAccount ?? SecureWorkOrderPendingStore._signedInAccount,
      _now = now ?? DateTime.now;
  final FlutterSecureStorage _storage;
  final String? Function() _currentAccount;
  final DateTime Function() _now;
  static final _tails = <String, Future<void>>{};
  String _key(WorkspaceProductSubmissionScope scope) => 'moolsocial.workspace.product-media.v1.${
    base64UrlEncode(utf8.encode(jsonEncode([scope.account, scope.store, scope.realm, scope.sku])))}';
  void _check(WorkspaceProductSubmissionScope scope) {
    if (_currentAccount() != scope.account || scope.account.isEmpty || scope.store.isEmpty || scope.sku.isEmpty ||
      !{'evaluation', 'production'}.contains(scope.realm)) {throw const WorkGatewayException('Sign in again to recover the product photo.');}
  }
  Future<T> _serial<T>(WorkspaceProductSubmissionScope scope, Future<T> Function() action) {
    final key = _key(scope), result = (_tails[key] ?? Future<void>.value()).then((_) => action());
    final tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {}); _tails[key] = tail;
    unawaited(tail.then((_) {if (identical(_tails[key], tail)) _tails.remove(key);})); return result;
  }
  Future<WorkspaceProductMediaRecovery?> _read(WorkspaceProductSubmissionScope scope) async {
    _check(scope); final raw = await _storage.read(key: _key(scope)); _check(scope);
    if (raw == null) return null;
    final value = jsonDecode(raw), keys = {'schemaVersion', 'original', 'result', 'history'};
    if (value is! Map || value.length < 3 || value.length > 4 || value.keys.any((k) => !keys.contains(k)) ||
      !value.containsKey('original') || !value.containsKey('result') || value['schemaVersion'] is! int || value['schemaVersion'] != 1) {
      throw const FormatException('Keep the saved photo recovery record.');
    }
    WorkspaceProductMediaRecovery pair(Object? raw) {
      if (raw is! Map || raw.length != 2 || !raw.containsKey('original') || !raw.containsKey('result')) throw const FormatException();
      final original = WorkspaceProductMediaIntent.fromJson(raw['original']);
      if (original.scope != scope) throw const FormatException();
      final result = raw['result'] == null ? null : WorkspaceProductMediaResult.decode(raw['result'], original, _now().toUtc(), historical: true);
      return WorkspaceProductMediaRecovery(original, result);
    }
    final current = pair({'original': value['original'], 'result': value['result']}), rawHistory = value['history'] ?? const [];
    if (rawHistory is! List || rawHistory.length > 8) throw const FormatException('Keep earlier photo recovery records.');
    final history = rawHistory.map(pair).toList();
    if ({current.original.fingerprint, ...history.map((entry) => entry.original.fingerprint)}.length != history.length + 1) throw const FormatException();
    return WorkspaceProductMediaRecovery(current.original, current.result, List.unmodifiable(history));
  }
  Future<void> _write(WorkspaceProductMediaIntent original, WorkspaceProductMediaResult? result, List<WorkspaceProductMediaRecovery> history) async {
    _check(original.scope);
    await _storage.write(key: _key(original.scope), value: jsonEncode({'schemaVersion': 1, 'original': original.toJson(), 'result': result?.toJson(),
      'history': [for (final entry in history) {'original': entry.original.toJson(), 'result': entry.result?.toJson()}]}));
    _check(original.scope);
  }
  @override
  Future<WorkspaceProductMediaRecovery?> read(WorkspaceProductSubmissionScope scope) => _serial(scope, () => _read(scope));
  @override
  Future<void> saveOriginal(WorkspaceProductMediaIntent original) => _serial(original.scope, () async {
    WorkspaceProductMediaIntent.fromJson(original.toJson());
    final old = await _read(original.scope);
    final history = old?.history.where((entry) => entry.result?.processed != true).toList() ?? <WorkspaceProductMediaRecovery>[];
    if (old != null) {
      if (old.original.fingerprint == original.fingerprint) return;
      if (old.result == null || !old.result!.processed && old.result!.current) throw const FormatException('Keep the uncertain original photo request.');
      if (!old.result!.processed) history.add(WorkspaceProductMediaRecovery(old.original, old.result));
    }
    if (history.length > 8) throw const FormatException('Check earlier saved photo requests before another upload. All originals are kept.');
    await _write(original, null, history);
  });
  @override
  Future<void> saveResult(WorkspaceProductMediaIntent original, WorkspaceProductMediaResult result) => _serial(original.scope, () async {
    final prior = await _read(original.scope);
    if (prior == null) throw const FormatException('Keep the original photo request.');
    final active = prior.original.fingerprint == original.fingerprint;
    final index = prior.history.indexWhere((entry) => entry.original.fingerprint == original.fingerprint);
    if (!active && index < 0) throw const FormatException('Keep the original photo request.');
    final previous = active ? prior.result : prior.history[index].result;
    final checked = WorkspaceProductMediaResult.decode(result.toJson(), original, _now().toUtc(), historical: true);
    if (previous?.processed == true && (!checked.processed ||
      jsonEncode(previous!.toJson()['processed']) != jsonEncode(checked.toJson()['processed']))) {throw const FormatException('Processed photo evidence changed.');}
    final history = prior.history.toList();
    if (!active) history[index] = WorkspaceProductMediaRecovery(original, checked);
    await _write(prior.original, active ? checked : prior.result, history);
  });
}

class SecureWorkVariantFamilyJournal implements WorkspaceVariantFamilyJournal {
  SecureWorkVariantFamilyJournal({FlutterSecureStorage? storage, String? Function()? currentAccount})
    : _storage = storage ?? const FlutterSecureStorage(),
      _currentAccount = currentAccount ?? SecureWorkOrderPendingStore._signedInAccount;
  final FlutterSecureStorage _storage;
  final String? Function() _currentAccount;
  static final _tails = <String, Future<void>>{};
  String _key(WorkspaceVariantFamilyScope scope) => 'moolsocial.workspace.variant-family.v1.${
    base64UrlEncode(utf8.encode(jsonEncode([scope.account, scope.store, scope.realm, scope.family])))}';
  void _check(WorkspaceVariantFamilyScope scope) {
    if (scope.account.isEmpty || scope.store.isEmpty || scope.family.isEmpty ||
        !{'production', 'evaluation'}.contains(scope.realm) || _currentAccount() != scope.account) {
      throw const WorkGatewayException('Sign in again to check the group submission.');
    }
  }
  Future<T> _serial<T>(WorkspaceVariantFamilyScope scope, Future<T> Function() action) {
    final key = _key(scope), result = (_tails[key] ?? Future<void>.value()).then((_) => action());
    final tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    _tails[key] = tail;
    unawaited(tail.then((_) { if (identical(_tails[key], tail)) _tails.remove(key); }));
    return result;
  }
  Future<WorkspaceVariantFamilyIntent?> _read(WorkspaceVariantFamilyScope scope) async {
    _check(scope);
    final raw = await _storage.read(key: _key(scope));
    _check(scope);
    if (raw == null) return null;
    final envelope = jsonDecode(raw);
    const keys = {'schemaVersion', 'accountId', 'storeId', 'realm', 'familyId', 'original'};
    if (envelope is! Map || envelope.length != keys.length || envelope.keys.any((k) => !keys.contains(k)) ||
        envelope['schemaVersion'] is! int || envelope['schemaVersion'] != 1 || envelope['accountId'] != scope.account ||
        envelope['storeId'] != scope.store || envelope['realm'] != scope.realm || envelope['familyId'] != scope.family) {
      throw const FormatException('The original group submission needs recovery.');
    }
    if (envelope['original'] == null) return null;
    final intent = WorkspaceVariantFamilyIntent.fromJson(envelope['original']);
    if (intent.scope != scope) throw const FormatException('The group request belongs to another context.');
    return intent;
  }
  Future<void> _write(WorkspaceVariantFamilyScope scope, WorkspaceVariantFamilyIntent? original) async {
    _check(scope);
    await _storage.write(key: _key(scope), value: jsonEncode({'schemaVersion': 1, 'accountId': scope.account,
      'storeId': scope.store, 'realm': scope.realm, 'familyId': scope.family, 'original': original?.toJson()}));
    _check(scope);
  }
  @override
  Future<WorkspaceVariantFamilyIntent?> readPending(WorkspaceVariantFamilyScope scope) => _serial(scope, () => _read(scope));
  @override
  Future<void> savePending(WorkspaceVariantFamilyIntent original) => _serial(original.scope, () async {
    WorkspaceVariantFamilyIntent.fromJson(original.toJson());
    final prior = await _read(original.scope);
    if (prior != null) {
      if (prior.fingerprint == original.fingerprint) return;
      throw const FormatException('Check the earlier group request before another submission.');
    }
    await _write(original.scope, original);
  });
  @override
  Future<void> removePending(WorkspaceVariantFamilyIntent original) => _serial(original.scope, () async {
    final prior = await _read(original.scope);
    if (prior == null) return;
    if (prior.fingerprint != original.fingerprint) throw const FormatException('Keep the original group request.');
    await _write(original.scope, null);
  });
}

/// Encrypted private policy draft and original request. Native tails remain
/// serialized across instances through actual completion, not caller timeouts.
/// Secure original-request recovery, not a local published-promotion database.
class SecureStoreCouponPendingStore implements StoreCouponPendingStore {
  SecureStoreCouponPendingStore({FlutterSecureStorage? storage, String? Function()? currentAccount})
    : _storage = storage ?? const FlutterSecureStorage(),
      _currentAccount = currentAccount ?? SecureWorkOrderPendingStore._signedInAccount;
  final FlutterSecureStorage _storage;
  final String? Function() _currentAccount;
  static final Map<String, Future<void>> _tails = {};
  String _key(StorePromotionScope scope) =>
    'moolsocial.workspace.store-coupon-command.v1.${base64UrlEncode(utf8.encode(jsonEncode([scope.account, scope.store, scope.realm])))}';
  void _check(StorePromotionScope scope) {
    if (_currentAccount() != scope.account || scope.account.isEmpty || scope.store.isEmpty ||
        !{'evaluation', 'production'}.contains(scope.realm)) {
      throw const WorkGatewayException('Sign in again to check this coupon update.');
    }
  }
  Future<T> _serial<T>(StorePromotionScope scope, Future<T> Function() action) {
    final key = _key(scope), result = (_tails[_key(scope)] ?? Future<void>.value()).then((_) => action());
    final tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    _tails[key] = tail;
    unawaited(tail.then((_) {if (identical(_tails[key], tail)) _tails.remove(key);}));
    return result;
  }
  Future<StoreCouponIntent?> _read(StorePromotionScope scope) async {
    _check(scope);
    final raw = await _storage.read(key: _key(scope));
    _check(scope);
    if (raw == null) return null;
    final row = jsonDecode(raw);
    if (row is! Map || row.length != 5 || row['schemaVersion'] != 1 || row['accountId'] != scope.account ||
        row['storeId'] != scope.store || row['realm'] != scope.realm || !row.containsKey('original')) {
      throw const FormatException('Saved coupon update needs checking.');
    }
    final original = StoreCouponIntent.fromJson(row['original']);
    if (original.scope != scope) throw const FormatException('Wrong coupon request owner.');
    return original;
  }
  @override
  Future<StoreCouponIntent?> read(StorePromotionScope scope) => _serial(scope, () => _read(scope));
  @override
  Future<void> save(StoreCouponIntent original) => _serial(original.scope, () async {
    StoreCouponIntent.fromJson(original.toJson());
    final previous = await _read(original.scope);
    if (previous != null && previous.fingerprint != original.fingerprint) {
      throw const FormatException('Check the original coupon update first.');
    }
    if (previous != null) return;
    _check(original.scope);
    await _storage.write(key: _key(original.scope), value: jsonEncode({'schemaVersion': 1,
      'accountId': original.scope.account, 'storeId': original.scope.store, 'realm': original.scope.realm,
      'original': original.toJson()}));
    _check(original.scope);
  });
  @override
  Future<void> clear(StoreCouponIntent original) => _serial(original.scope, () async {
    final previous = await _read(original.scope);
    if (previous == null) return;
    if (previous.fingerprint != original.fingerprint) throw const FormatException('Keep the original coupon update.');
    _check(original.scope);
    await _storage.delete(key: _key(original.scope));
    _check(original.scope);
  });
}

class SecureStorePromotionPendingStore implements StorePromotionPendingStore {
  SecureStorePromotionPendingStore({FlutterSecureStorage? storage, String? Function()? currentAccount})
    : _storage = storage ?? const FlutterSecureStorage(),
      _currentAccount = currentAccount ?? SecureWorkOrderPendingStore._signedInAccount;
  final FlutterSecureStorage _storage;
  final String? Function() _currentAccount;
  static final Map<String, Future<void>> _tails = {};
  String _key(StorePromotionScope scope) => 'moolsocial.workspace.product-promotion.v1.${base64UrlEncode(utf8.encode(jsonEncode([scope.account, scope.store, scope.realm])))}';
  void _check(StorePromotionScope scope) {
    if (_currentAccount() != scope.account || scope.account.isEmpty || scope.store.isEmpty ||
        !{'evaluation', 'production'}.contains(scope.realm)) {
      throw const WorkGatewayException('Sign in again to check this promotion update.');
    }
  }
  Future<T> _serial<T>(StorePromotionScope scope, Future<T> Function() action) {
    final key = _key(scope);
    final result = (_tails[key] ?? Future<void>.value()).then((_) => action());
    final tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    _tails[key] = tail;
    unawaited(tail.then((_) {if (identical(_tails[key], tail)) _tails.remove(key);}));
    return result;
  }
  Future<StorePromotionIntent?> _read(StorePromotionScope scope) async {
    _check(scope);
    final raw = await _storage.read(key: _key(scope));
    _check(scope);
    if (raw == null) return null;
    final row = jsonDecode(raw);
    if (row is! Map || row.length != 5 || row['schemaVersion'] != 1 || row['accountId'] != scope.account ||
        row['storeId'] != scope.store || row['realm'] != scope.realm || !row.containsKey('original')) {
      throw const FormatException('Saved promotion update needs checking.');
    }
    final original = StorePromotionIntent.fromJson(row['original']);
    if (original.scope != scope) throw const FormatException('Wrong promotion request owner.');
    return original;
  }
  @override
  Future<StorePromotionIntent?> read(StorePromotionScope scope) => _serial(scope, () => _read(scope));
  @override
  Future<void> save(StorePromotionIntent original) => _serial(original.scope, () async {
    final previous = await _read(original.scope);
    if (previous != null && previous.fingerprint != original.fingerprint) {
      throw const FormatException('Check the original promotion update first.');
    }
    if (previous != null) return;
    _check(original.scope);
    await _storage.write(key: _key(original.scope), value: jsonEncode({'schemaVersion': 1,
      'accountId': original.scope.account, 'storeId': original.scope.store, 'realm': original.scope.realm,
      'original': original.toJson()}));
    _check(original.scope);
  });
  @override
  Future<void> clear(StorePromotionIntent original) => _serial(original.scope, () async {
    final previous = await _read(original.scope);
    if (previous == null) return;
    if (previous.fingerprint != original.fingerprint) throw const FormatException('Keep the original promotion update.');
    _check(original.scope);
    await _storage.delete(key: _key(original.scope));
    _check(original.scope);
  });
}

/// Only the original public-details request, in its own encrypted namespace.
/// Queues follow real native completion, even after a caller deadline expires.
class SecureWorkPublicDetailsJournal implements WorkspacePublicDetailsJournal {
  SecureWorkPublicDetailsJournal({FlutterSecureStorage? storage, String? Function()? currentAccount})
    : _storage = storage ?? const FlutterSecureStorage(),
      _currentAccount = currentAccount ?? SecureWorkOrderPendingStore._signedInAccount;
  final FlutterSecureStorage _storage;
  final String? Function() _currentAccount;
  static final Map<String, Future<void>> _tails = {};
  String _key(WorkspacePublicDetailsScope scope) =>
    'moolsocial.workspace.public-details-command.v1.${base64UrlEncode(utf8.encode(jsonEncode([scope.account, scope.store, scope.realm])))}';
  void _check(WorkspacePublicDetailsScope scope) {
    if (scope.account.trim().isEmpty || scope.store.trim().isEmpty ||
        !{'production', 'evaluation'}.contains(scope.realm) || _currentAccount() != scope.account) {
      throw const WorkGatewayException('Sign in again to check this public-details update.');
    }
  }
  Future<T> _serial<T>(WorkspacePublicDetailsScope scope, Future<T> Function() action) {
    final key = _key(scope), result = (_tails[_key(scope)] ?? Future<void>.value()).then((_) => action());
    final tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    _tails[key] = tail;
    unawaited(tail.then((_) { if (identical(_tails[key], tail)) _tails.remove(key); }));
    return result;
  }
  Future<WorkspacePublicDetailsIntent?> _read(WorkspacePublicDetailsScope scope) async {
    _check(scope);
    final raw = await _storage.read(key: _key(scope));
    _check(scope);
    if (raw == null) return null;
    final value = jsonDecode(raw);
    if (value is! Map || value.length != 5 || value['schemaVersion'] != 1 || value['accountId'] != scope.account ||
        value['storeId'] != scope.store || value['realm'] != scope.realm || !value.containsKey('original')) {
      throw const FormatException('Saved public-details update needs checking.');
    }
    if (value['original'] == null) return null;
    final original = WorkspacePublicDetailsIntent.fromJson(value['original']);
    if (original.scope != scope) throw const FormatException('Wrong public-details request owner.');
    return original;
  }
  Future<void> _write(WorkspacePublicDetailsScope scope, WorkspacePublicDetailsIntent? original) async {
    _check(scope);
    await _storage.write(key: _key(scope), value: jsonEncode({'schemaVersion': 1,
      'accountId': scope.account, 'storeId': scope.store, 'realm': scope.realm, 'original': original?.toJson()}));
    _check(scope);
  }
  @override
  Future<WorkspacePublicDetailsIntent?> readPending(WorkspacePublicDetailsScope scope) => _serial(scope, () => _read(scope));
  @override
  Future<void> savePending(WorkspacePublicDetailsIntent original) => _serial(original.scope, () async {
    final previous = await _read(original.scope);
    if (previous != null) {
      if (previous.fingerprint != original.fingerprint) throw const FormatException('Check the original public-details update first.');
      return;
    }
    WorkspacePublicDetailsIntent.fromJson(original.toJson());
    await _write(original.scope, original);
  });
  @override
  Future<void> removePending(WorkspacePublicDetailsIntent original) => _serial(original.scope, () async {
    final previous = await _read(original.scope);
    if (previous == null) return;
    if (previous.fingerprint != original.fingerprint) throw const FormatException('Keep the original public-details request.');
    await _write(original.scope, null);
  });
}

class SecureStorePolicyJournal implements StorePolicyJournal {
  SecureStorePolicyJournal({FlutterSecureStorage? storage, String? Function()? currentAccount})
    : _storage = storage ?? const FlutterSecureStorage(),
      _currentAccount = currentAccount ?? SecureWorkOrderPendingStore._signedInAccount;
  final FlutterSecureStorage _storage;
  final String? Function() _currentAccount;
  static final Map<String, Future<void>> _tails = {};
  String _key(StorePolicyScope scope) => 'moolsocial.workspace.supplier-policy.v1.${base64UrlEncode(utf8.encode(jsonEncode([scope.account, scope.store, scope.realm])))}';
  void _check(StorePolicyScope scope) {
    if (scope.account.isEmpty || scope.store.isEmpty || !{'evaluation', 'production'}.contains(scope.realm) ||
        _currentAccount() != scope.account) {
      throw const WorkGatewayException('Sign in again to check this policy update.');
    }
  }
  Future<T> _serial<T>(StorePolicyScope scope, Future<T> Function() action) {
    final key = _key(scope);
    final result = (_tails[key] ?? Future<void>.value()).then((_) => action());
    final tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    _tails[key] = tail;
    unawaited(tail.then((_) {if (identical(_tails[key], tail)) _tails.remove(key);}));
    return result;
  }
  Future<StorePolicyRecovery> _read(StorePolicyScope scope) async {
    _check(scope);
    final raw = await _storage.read(key: _key(scope));
    _check(scope);
    if (raw == null) return const StorePolicyRecovery();
    final value = jsonDecode(raw);
    if (value is! Map || value.length != 6 || value['schemaVersion'] != 1 || value['accountId'] != scope.account ||
        value['storeId'] != scope.store || value['realm'] != scope.realm || !value.containsKey('draft') || !value.containsKey('pending')) {
      throw const FormatException('Saved Store policy needs checking.');
    }
    final pending = value['pending'] == null ? null : StorePolicyIntent.fromJson(value['pending']);
    if (pending != null && pending.scope != scope) throw const FormatException('Wrong policy request owner.');
    return StorePolicyRecovery(draft: value['draft'] == null ? null : StorePolicyDraft.fromJson(value['draft']), pending: pending);
  }
  Future<void> _write(StorePolicyScope scope, StorePolicyRecovery value) async {
    _check(scope);
    await _storage.write(key: _key(scope), value: jsonEncode({'schemaVersion': 1, 'accountId': scope.account,
      'storeId': scope.store, 'realm': scope.realm, 'draft': value.draft?.toJson(), 'pending': value.pending?.toJson()}));
    _check(scope);
  }
  @override
  Future<StorePolicyRecovery> read(StorePolicyScope scope) => _serial(scope, () => _read(scope));
  @override
  Future<void> saveDraft(StorePolicyScope scope, StorePolicyDraft draft) => _serial(scope, () async {
    final previous = await _read(scope);
    await _write(scope, StorePolicyRecovery(draft: draft, pending: previous.pending));
  });
  @override
  Future<void> savePending(StorePolicyIntent original) => _serial(original.scope, () async {
    final previous = await _read(original.scope);
    if (previous.pending != null && previous.pending!.fingerprint != original.fingerprint) {
      throw const FormatException('Check the original policy request first.');
    }
    if (previous.pending == null) await _write(original.scope, StorePolicyRecovery(draft: previous.draft, pending: original));
  });
  @override
  Future<void> clearPending(StorePolicyIntent original) => _serial(original.scope, () async {
    final previous = await _read(original.scope);
    if (previous.pending == null) return;
    if (previous.pending!.fingerprint != original.fingerprint) throw const FormatException('Keep the original policy request.');
    await _write(original.scope, StorePolicyRecovery(draft: previous.draft));
  });
}

/// Per-Store frontend reconciliation. It never posts inventory, payments,
/// invoices or collection completion. A/B operations may settle independently;
/// an uncertain A keeps its original identity and cannot be submitted twice.
/// The owning session must bind this to its authenticated account lifetime and
/// persist pending commands before enabling durable/relaunch qualification.
class WorkOrderOperations extends ChangeNotifier {
  WorkOrderOperations({
    required this.accountScope,
    required this.workspaceId,
    required this.gateway,
    this.pendingStore,
    this.timeout = const Duration(seconds: 15),
  });

  final String accountScope, workspaceId;
  final WorkOrderCommandGateway gateway;
  final WorkOrderPendingStore? pendingStore;
  final Duration timeout;
  final Map<String, WorkOrderReply> _orders = {};
  final Map<String, WorkOrderCommand> _pending = {};
  final Map<String, WorkOrderOperationState> _states = {};
  bool _disposed = false;
  String? _changedOrderId;
  bool _restored = false;
  Future<bool>? _restoring;

  bool get isDisposed => _disposed;
  bool get recoveryReady => pendingStore == null || _restored;
  bool get timeRequestsAvailable =>
      gateway is WorkOrderTimeCommandGateway &&
      (gateway as WorkOrderTimeCommandGateway).supportsOrderTimeRequests;
  String? get changedOrderId => _changedOrderId;
  List<WorkOrderReply> get orders => List.unmodifiable(_orders.values);

  void _emit(String orderId) {
    _changedOrderId = orderId;
    notifyListeners();
  }

  WorkOrderReply? order(String id) => _orders[id];
  WorkOrderCommand? pending(String id) => _pending[id];
  WorkOrderOperationState? state(String id) => _states[id];
  List<WorkOrderCommand> get pendingCommands =>
      List.unmodifiable(_pending.values);
  bool canAct(String orderId, WorkOrderAction action) =>
      !_disposed && recoveryReady && !_pending.containsKey(orderId) &&
      _orders[orderId] != null && _allowed(_orders[orderId]!, action);

  /// Complete before session binding. Corruption/read failure leaves new actions
  /// blocked; no restored command is automatically sent or treated as success.
  Future<bool> restore() {
    if (_disposed) return Future.value(false);
    if (recoveryReady) return Future.value(true);
    return _restoring ??= _restore().whenComplete(() => _restoring = null);
  }

  Future<bool> _restore() async {
    try {
      final commands = await pendingStore!
          .readPending(accountScope, workspaceId)
          .timeout(timeout);
      if (_disposed) return false;
      final orders = <String>{}, operations = <String>{};
      for (final command in commands) {
        if (command.accountScope != accountScope ||
            command.workspaceId != workspaceId ||
            accountScope.isEmpty ||
            workspaceId.isEmpty ||
            !SecureWorkOrderPendingStore._valid(command) ||
            !orders.add(command.orderId) ||
            !operations.add(command.operationId)) {
          return false;
        }
      }
      for (final command in commands) {
        _pending[command.orderId] = command;
        _states[command.orderId] = WorkOrderOperationState.uncertain;
      }
      _restored = true;
      for (final command in commands) {
        if (!_disposed) _emit(command.orderId);
      }
      return !_disposed;
    } on Object {
      return false;
    }
  }

  /// Restored local data is never success or permission. Only a read-only
  /// authoritative reconciliation may release a recovered operation lock.
  bool restorePending(WorkOrderCommand command) {
    if (_disposed ||
        pendingStore != null ||
        !SecureWorkOrderPendingStore._valid(command) ||
        accountScope.isEmpty ||
        workspaceId.isEmpty ||
        command.accountScope != accountScope ||
        command.workspaceId != workspaceId ||
        command.orderId.isEmpty ||
        command.operationId.isEmpty ||
        command.expectedRevision < 0 ||
        _pending.containsKey(command.orderId) ||
        _pending.values.any(
          (item) => item.operationId == command.operationId,
        ) ||
        (command.action == WorkOrderAction.reject &&
            (command.reason == null || command.reason!.trim().isEmpty))) {
      return false;
    }
    _pending[command.orderId] = command;
    _states[command.orderId] = WorkOrderOperationState.uncertain;
    _emit(command.orderId);
    return true;
  }

  bool _belongs(WorkOrderReply reply) =>
      accountScope.isNotEmpty &&
      workspaceId.isNotEmpty &&
      reply.accountScope == accountScope &&
      reply.workspaceId == workspaceId &&
      reply.orderId.isNotEmpty &&
      reply.revision >= 0 &&
      reply.order?.id == reply.orderId &&
      reply.order!.validBillAmounts &&
      (reply.order!.operational == null ||
        reply.order!.operational!.viewerRole == WorkspaceOrderIdentityRole.seller &&
        reply.order!.operational!.viewerUserId == accountScope &&
        reply.order!.operational!.reference.storeId == workspaceId &&
        reply.order!.operational!.reference.orderId == reply.orderId &&
        reply.order!.operational!.revision == reply.revision && reply.delivery == null) &&
      reply.order!.quantities.entries.every(
        (entry) => entry.key.isNotEmpty && entry.value > 0,
      ) &&
      (reply.delivery == null ||
          (!reply.order!.isCustomerCollection &&
              reply.delivery!.orderId == reply.orderId)) &&
      (reply.order?.collectionStoreId == null ||
          reply.order?.collectionStoreId == workspaceId);

  /// Full snapshots can skip revisions; patches cannot use this entry point.
  /// Repeated/older events never replace a newer order or clear a pending action.
  bool observe(WorkOrderReply snapshot) {
    if (_disposed || !_belongs(snapshot)) return false;
    final previous = _orders[snapshot.orderId];
    if (previous != null && !_sameOrderContext(previous, snapshot)) {
      return false;
    }
    if (previous != null && snapshot.revision <= previous.revision) {
      return false;
    }
    _orders[snapshot.orderId] = snapshot;
    _emit(snapshot.orderId);
    return true;
  }

  bool _sameOrderContext(WorkOrderReply previous, WorkOrderReply next) {
    final a = previous.order?.operational, b = next.order?.operational;
    if (a == null || b == null) return a == null && b == null;
    return a.realm == b.realm && a.viewerUserId == b.viewerUserId &&
        a.operationalSourceRevision == b.operationalSourceRevision &&
        jsonEncode(a.reference.toJson()) == jsonEncode(b.reference.toJson());
  }

  bool _allowed(WorkOrderReply snapshot, WorkOrderAction action) {
    final record = snapshot.order!;
    if (gateway is WorkspaceOperationalOrderCommandGateway &&
        !(gateway as WorkspaceOperationalOrderCommandGateway).isCurrent) {
      return false;
    }
    // Readiness and handover of authenticated customer collection remain under
    // the existing collection controller, not this general-order contract.
    if (record.isCustomerCollection || record.isClosed) return false;
    if (record.operational case final exact?) {
      return exact.permits(action.name, DateTime.now());
    }
    return switch (action) {
      WorkOrderAction.accept ||
      WorkOrderAction.reject => record.stage == 'Confirmed',
      WorkOrderAction.ready => record.stage == 'Preparing',
      WorkOrderAction.requestTime =>
        timeRequestsAvailable && record.stage == 'Confirmed',
    };
  }

  Future<bool> act(
    String orderId,
    WorkOrderAction action, {
    String? reason,
    int? additionalMinutes,
  }) {
    final snapshot = _orders[orderId];
    if (_disposed ||
        !recoveryReady ||
        _pending.containsKey(orderId) ||
        snapshot == null ||
        !_allowed(snapshot, action) ||
        (action == WorkOrderAction.requestTime &&
            (!{2, 5}.contains(additionalMinutes) ||
                snapshot.order!.actionDeadline?.isAfter(DateTime.now()) !=
                    true)) ||
        (action != WorkOrderAction.requestTime && additionalMinutes != null) ||
        (action == WorkOrderAction.reject &&
            (reason == null || reason.trim().isEmpty))) {
      return Future.value(false);
    }
    final random = Random.secure();
    final nonce = List.generate(16, (_) => random.nextInt(256));
    final command = WorkOrderCommand(
      accountScope: accountScope,
      workspaceId: workspaceId,
      orderId: orderId,
      operationId: 'STORE-ORDER-${base64UrlEncode(nonce)}',
      expectedRevision: snapshot.revision,
      action: action,
      reason: action == WorkOrderAction.reject ? reason!.trim() : null,
      additionalMinutes: additionalMinutes,
      expectedAcceptanceDeadline: action == WorkOrderAction.requestTime
          ? snapshot.order!.actionDeadline
          : null,
      purchaseReference: snapshot.order!.operational?.reference,
      purchaseRealm: snapshot.order!.operational?.realm,
    );
    _pending[orderId] = command;
    return _run(command, reconcile: false);
  }

  Future<bool> retry(String orderId) {
    final command = _pending[orderId];
    if (_disposed ||
        !recoveryReady ||
        command == null ||
        _states[orderId] != WorkOrderOperationState.uncertain) {
      return Future.value(false);
    }
    return _run(command, reconcile: true);
  }

  Future<bool> _run(WorkOrderCommand command, {required bool reconcile}) async {
    _states[command.orderId] = reconcile
        ? WorkOrderOperationState.reconciling
        : WorkOrderOperationState.submitting;
    _emit(command.orderId);
    bool current() =>
        !_disposed && identical(_pending[command.orderId], command);
    try {
      if (!current()) return false;
      if (!reconcile && pendingStore != null) {
        await pendingStore!.savePending(command).timeout(timeout);
        if (!current()) return false;
      }
      final reply =
          await (reconcile
                  ? gateway.reconcileOrderCommand(command)
                  : gateway.submitOrderCommand(command))
              .timeout(timeout);
      if (!current()) return false;
      if (!_belongs(reply) ||
          reply.orderId != command.orderId ||
          reply.operationId != command.operationId ||
          reply.order!.isCustomerCollection ||
          reply.revision < command.expectedRevision ||
          (reply.state == WorkOrderReplyState.applied &&
              reply.revision <= command.expectedRevision) ||
          reply.state == WorkOrderReplyState.pending) {
        return false;
      }
      if (command.purchaseReference case final ref?) {
        final exact = reply.order!.operational;
        if (exact == null || exact.realm != command.purchaseRealm ||
            jsonEncode(exact.reference.toJson()) != jsonEncode(ref.toJson()) ||
            (reply.state == WorkOrderReplyState.applied &&
              (reply.revision != command.expectedRevision + 1 ||
                exact.stage != const {WorkOrderAction.accept: 'Preparing', WorkOrderAction.ready: 'Ready', WorkOrderAction.reject: 'Rejected'}[command.action] ||
                (command.action == WorkOrderAction.reject && exact.rejectionReason != command.reason)))) {
          return false;
        }
      } else if (reply.order!.isOperationalProjection) {
        return false;
      }
      if (command.action == WorkOrderAction.requestTime &&
          reply.state == WorkOrderReplyState.applied) {
        final deadline = reply.order!.actionDeadline;
        final fulfilment = reply.order!.fulfilmentDeadline;
        final expected = command.expectedAcceptanceDeadline!;
        // A late but valid acknowledgement may already be expired. Display its
        // real deadline, never extend it from the client's receipt time.
        if (reply.order!.stage != 'Confirmed' ||
            deadline == null ||
            fulfilment == null ||
            !deadline.isAfter(expected) ||
            deadline.isAfter(
              expected.add(Duration(minutes: command.additionalMinutes!)),
            ) ||
            !fulfilment.isAfter(deadline)) {
          return false;
        }
      }
      // A later full snapshot wins over this delayed acknowledgement. Resolving
      // its operation must not restore an older stage or replay business effects.
      final latest = _orders[command.orderId];
      if (latest != null && !_sameOrderContext(latest, reply)) return false;
      if (latest == null || reply.revision > latest.revision) {
        _orders[command.orderId] = reply;
      }
      if (pendingStore != null) {
        await pendingStore!.removePending(command).timeout(timeout);
        if (!current()) return false;
      }
      _pending.remove(command.orderId);
      _states.remove(command.orderId);
      return reply.state == WorkOrderReplyState.applied;
    } catch (_) {
      // Network/parse failures are not authoritative rejections. Keep identity.
      return false;
    } finally {
      if (current()) {
        _states[command.orderId] = WorkOrderOperationState.uncertain;
      }
      if (!_disposed) _emit(command.orderId);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _orders.clear();
    _pending.clear();
    _states.clear();
    _changedOrderId = null;
    super.dispose();
  }
}

class WorkOperationalSnapshot {
  const WorkOperationalSnapshot({
    required this.workspaceId,
    required this.reason,
    required this.state,
    required this.idempotencyKey,
  });

  final String workspaceId;
  final String reason;
  final Map<String, Object?> state;
  final String idempotencyKey;
}

class WorkGroupBuySubmission {
  const WorkGroupBuySubmission({
    required this.workspaceId,
    required this.values,
    required this.idempotencyKey,
  });

  final String workspaceId;
  final Map<String, Object?> values;
  final String idempotencyKey;
}

class WorkPaidRequirementSubmission {
  const WorkPaidRequirementSubmission({
    required this.workspaceId,
    required this.values,
    required this.idempotencyKey,
  });

  final String workspaceId;
  final Map<String, Object?> values;
  final String idempotencyKey;
}

class WorkSettlementResult {
  const WorkSettlementResult({
    required this.reference,
    required this.acceptedAmount,
  });

  final String reference;
  final int acceptedAmount;
}

class WorkDeliveryAssignmentResult {
  const WorkDeliveryAssignmentResult({
    required this.partnerName,
    required this.vehicleLabel,
    required this.eta,
    required this.stage,
  });

  final String partnerName;
  final String vehicleLabel;
  final DateTime eta;
  final String stage;
}

/// Optional authenticated timing adapter. A request is not an order acceptance.
/// Implementations must reconcile repeated operation IDs and validate the
/// expected deadline, order state, store permission and current store workload.
abstract interface class WorkOrderTimeGateway {
  Future<WorkOrderTimeResult> requestOrderTime(WorkOrderTimeRequest request);
}

class WorkOrderTimeRequest {
  const WorkOrderTimeRequest({
    required this.workspaceId,
    required this.orderId,
    required this.operationId,
    required this.expectedAcceptanceDeadline,
    required this.additionalMinutes,
  });
  final String workspaceId, orderId, operationId;
  final DateTime expectedAcceptanceDeadline;
  final int additionalMinutes;
}

class WorkOrderTimeResult {
  const WorkOrderTimeResult({
    required this.workspaceId,
    required this.orderId,
    required this.operationId,
    required this.approved,
    this.acceptanceDeadline,
    this.fulfilmentDeadline,
  });
  final String workspaceId, orderId, operationId;
  final bool approved;
  final DateTime? acceptanceDeadline, fulfilmentDeadline;
}

abstract interface class WorkGateway {
  Future<List<WorkReviewResult>> loadFeed();
  Future<String> apply(String opportunityId);
  Future<void> withdraw(String applicationId, String opportunityId);
  Future<void> sendContactOtp({
    required WorkContactChannel channel,
    required String value,
  });
  Future<void> verifyContactOtp({
    required WorkContactChannel channel,
    required String value,
    required String code,
  });
  Future<String> saveProof(String proofId, WorkPickedProof proof);
  Future<WorkReviewResult> submitProfile(WorkProfileSubmission submission);
  Future<WorkReviewResult> submitCorrection(
    String caseId,
    WorkProfileSubmission submission,
  );
  Future<WorkReviewResult> checkReview(String caseId);
  Future<String> submitGst(String caseId, String gstin, String proofReference);
  Future<void> finishSetup({
    required String workspaceId,
    required int quantity,
    required int buyPrice,
    required int sellPrice,
    required bool homeDelivery,
    required bool storeCollection,
  });
  Future<void> saveOperationalState(WorkOperationalSnapshot snapshot);
  Future<String> createGroupBuy(WorkGroupBuySubmission submission);
  Future<String> createPaidRequirement(
    WorkPaidRequirementSubmission submission,
  );
  Future<WorkSettlementResult> requestSettlement({
    required String workspaceId,
    required int amount,
    required String idempotencyKey,
  });
  Future<void> verifyOrderHandover({
    required String workspaceId,
    required String orderId,
    required String otp,
    required String idempotencyKey,
  });
  Future<WorkDeliveryAssignmentResult> requestDeliveryAssignment({
    required String workspaceId,
    required String orderId,
    required String address,
    required String idempotencyKey,
  });
}

WorkGateway buildWorkGateway() {
  final endpoint = Uri.tryParse(moolSocialWorkspaceUrl.trim());
  if (endpoint == null ||
      endpoint.scheme != 'https' ||
      endpoint.host != 'asia-south1-moolsocial-dev-503018.cloudfunctions.net' ||
      endpoint.path != '/moolSocialWorkspace' ||
      endpoint.hasQuery ||
      endpoint.hasFragment) {
    return const UnavailableWorkGateway();
  }
  return AuthenticatedWorkGateway(
    endpoint: endpoint,
    credentials: FirebaseSocialContentCredentials(),
    transport: IoSocialContentTransport(),
  );
}

class UnavailableWorkGateway implements WorkGateway {
  const UnavailableWorkGateway();
  WorkGatewayException get _error => const WorkGatewayException(
    'Workspace service is unavailable right now. Your personal account remains active.',
    retryable: true,
  );
  @override
  Future<String> apply(String opportunityId) async => throw _error;
  @override
  Future<void> withdraw(String applicationId, String opportunityId) async =>
      throw _error;
  @override
  Future<WorkReviewResult> checkReview(String caseId) async => throw _error;
  @override
  Future<WorkReviewResult> submitCorrection(
    String caseId,
    WorkProfileSubmission submission,
  ) async => throw _error;
  @override
  Future<void> finishSetup({
    required String workspaceId,
    required int quantity,
    required int buyPrice,
    required int sellPrice,
    required bool homeDelivery,
    required bool storeCollection,
  }) async => throw _error;
  @override
  Future<void> saveOperationalState(WorkOperationalSnapshot snapshot) async =>
      throw _error;
  @override
  Future<String> createGroupBuy(WorkGroupBuySubmission submission) async =>
      throw _error;
  @override
  Future<String> createPaidRequirement(
    WorkPaidRequirementSubmission submission,
  ) async => throw _error;
  @override
  Future<WorkSettlementResult> requestSettlement({
    required String workspaceId,
    required int amount,
    required String idempotencyKey,
  }) async => throw _error;
  @override
  Future<void> verifyOrderHandover({
    required String workspaceId,
    required String orderId,
    required String otp,
    required String idempotencyKey,
  }) async => throw _error;
  @override
  Future<WorkDeliveryAssignmentResult> requestDeliveryAssignment({
    required String workspaceId,
    required String orderId,
    required String address,
    required String idempotencyKey,
  }) async => throw _error;
  @override
  Future<List<WorkReviewResult>> loadFeed() async => throw _error;
  @override
  Future<String> saveProof(String proofId, WorkPickedProof proof) async =>
      throw _error;
  @override
  Future<void> sendContactOtp({
    required WorkContactChannel channel,
    required String value,
  }) async => throw _error;
  @override
  Future<void> verifyContactOtp({
    required WorkContactChannel channel,
    required String value,
    required String code,
  }) async => throw _error;
  @override
  Future<WorkReviewResult> submitProfile(
    WorkProfileSubmission submission,
  ) async => throw _error;
  @override
  Future<String> submitGst(
    String caseId,
    String gstin,
    String proofReference,
  ) async => throw _error;
}

class AuthenticatedWorkGateway implements WorkGateway {
  AuthenticatedWorkGateway({
    required this.endpoint,
    required this.credentials,
    required this.transport,
    WorkProofUploadTransport? proofUploadTransport,
    Random? random,
  }) : proofUploadTransport =
           proofUploadTransport ?? IoWorkProofUploadTransport(),
       random = random ?? Random.secure();
  final Uri endpoint;
  final SocialContentCredentials credentials;
  final SocialContentTransport transport;
  final WorkProofUploadTransport proofUploadTransport;
  final Random random;

  @override
  Future<List<WorkReviewResult>> loadFeed() async {
    final data = _map(await _invoke('listWorkspaces', const {}));
    final items = data['workspaces'];
    if (items is! List) {
      throw const WorkGatewayException(
        'Workspace returned an invalid response. Try again.',
        retryable: true,
      );
    }
    return items.map((item) => _decodeReview(_map(item))).toList();
  }

  @override
  Future<String> apply(String opportunityId) async => _requiredString(
    _map(
      await _invoke('applyOpportunity', {
        'opportunityId': opportunityId,
      }, mutation: true),
    )['applicationId'],
  );
  @override
  Future<void> withdraw(String applicationId, String opportunityId) => _invoke(
    'withdrawOpportunity',
    {'applicationId': applicationId, 'opportunityId': opportunityId},
    mutation: true,
  );
  @override
  Future<void> sendContactOtp({
    required WorkContactChannel channel,
    required String value,
  }) => _invoke('sendWorkspaceContactOtp', {
    'channel': channel.apiValue,
    'value': value,
  }, mutation: true);
  @override
  Future<void> verifyContactOtp({
    required WorkContactChannel channel,
    required String value,
    required String code,
  }) => _invoke('verifyWorkspaceContactOtp', {
    'channel': channel.apiValue,
    'value': value,
    'code': code,
  }, mutation: true);
  @override
  Future<String> saveProof(String proofId, WorkPickedProof proof) async {
    final prepared = _map(
      await _invoke('prepareProofUpload', {
        'proofId': proofId,
        'fileName': proof.fileName,
        'contentType': proof.contentType,
        'sizeBytes': proof.bytes.length,
      }, mutation: true),
    );
    final uploadUrl = Uri.tryParse(_requiredString(prepared['uploadUrl']));
    final expiresAt = DateTime.tryParse(_requiredString(prepared['expiresAt']));
    if (uploadUrl == null ||
        expiresAt == null ||
        !expiresAt.isAfter(DateTime.now())) {
      throw const WorkGatewayException(
        'Document upload could not be prepared. Choose the document again.',
        retryable: true,
      );
    }
    final headers = _map(
      prepared['requiredHeaders'],
    ).map((key, value) => MapEntry(key, _requiredString(value)));
    await proofUploadTransport.put(
      url: uploadUrl,
      headers: headers,
      bytes: proof.bytes,
    );
    return _requiredString(
      _map(
        await _invoke('confirmProofUpload', {
          'proofId': proofId,
          'uploadId': _requiredString(prepared['uploadId']),
          'fileName': proof.fileName,
          'contentType': proof.contentType,
          'sizeBytes': proof.bytes.length,
        }, mutation: true),
      )['proofReference'],
    );
  }

  @override
  Future<WorkReviewResult> submitProfile(WorkProfileSubmission value) async =>
      _decodeReview(
        _map(
          await _invoke('submitProfile', {
            'familyId': value.familyId,
            'profileId': value.profileId,
            'name': value.name,
            'authorizedPersonName': value.authorizedPersonName,
            'businessRelationship': value.businessRelationship,
            'area': value.area,
            'primaryActivity': value.primaryActivity,
            'proofReferences': value.proofReferences,
            'primaryMobile': value.primaryMobile,
            'email': value.email,
            'alternateMobile': value.alternateMobile,
            'connectedProvider': value.connectedProvider,
            'connectedProviderAccount': value.connectedProviderAccount,
            'alternateMobileVerified': value.alternateMobileVerified,
            'idempotencyKey': value.idempotencyKey,
          }, mutation: true),
        ),
      );
  @override
  Future<WorkReviewResult> submitCorrection(
    String caseId,
    WorkProfileSubmission value,
  ) async => throw const WorkGatewayException(
    'Sending corrections to an existing review is not available yet. Your changes remain saved; contact MoolSocial Support for this review.',
    retryable: false,
  );
  @override
  Future<WorkReviewResult> checkReview(String caseId) async =>
      _decodeReview(_map(await _invoke('reviewStatus', {'caseId': caseId})));
  @override
  Future<String> submitGst(
    String caseId,
    String gstin,
    String proofReference,
  ) async => _requiredString(
    _map(
      await _invoke('submitGst', {
        'caseId': caseId,
        'gstin': gstin,
        'proofReference': proofReference,
      }, mutation: true),
    )['gstReference'],
  );
  @override
  Future<void> finishSetup({
    required String workspaceId,
    required int quantity,
    required int buyPrice,
    required int sellPrice,
    required bool homeDelivery,
    required bool storeCollection,
  }) => _invoke('finishRetailerSetup', {
    'workspaceId': workspaceId,
    'quantity': quantity,
    'buyPrice': buyPrice,
    'sellPrice': sellPrice,
    'homeDelivery': homeDelivery,
    'storeCollection': storeCollection,
  }, mutation: true);

  @override
  Future<void> saveOperationalState(WorkOperationalSnapshot snapshot) =>
      _invoke('saveWorkspaceOperations', {
        'workspaceId': snapshot.workspaceId,
        'reason': snapshot.reason,
        'state': snapshot.state,
        'idempotencyKey': snapshot.idempotencyKey,
      }, mutation: true);

  @override
  Future<String> createGroupBuy(WorkGroupBuySubmission submission) async =>
      _requiredString(
        _map(
          await _invoke('createWorkspaceGroupBuy', {
            'workspaceId': submission.workspaceId,
            'values': submission.values,
            'idempotencyKey': submission.idempotencyKey,
          }, mutation: true),
        )['paymentReference'],
      );

  @override
  Future<String> createPaidRequirement(
    WorkPaidRequirementSubmission submission,
  ) async => _requiredString(
    _map(
      await _invoke('createWorkspacePaidRequirement', {
        'workspaceId': submission.workspaceId,
        'values': submission.values,
        'idempotencyKey': submission.idempotencyKey,
      }, mutation: true),
    )['reference'],
  );

  @override
  Future<WorkSettlementResult> requestSettlement({
    required String workspaceId,
    required int amount,
    required String idempotencyKey,
  }) async {
    final result = _map(
      await _invoke('requestWorkspaceSettlement', {
        'workspaceId': workspaceId,
        'amount': amount,
        'idempotencyKey': idempotencyKey,
      }, mutation: true),
    );
    return WorkSettlementResult(
      reference: _requiredString(result['reference']),
      acceptedAmount: (result['acceptedAmount'] as num?)?.round() ?? amount,
    );
  }

  @override
  Future<void> verifyOrderHandover({
    required String workspaceId,
    required String orderId,
    required String otp,
    required String idempotencyKey,
  }) => _invoke('verifyWorkspaceOrderHandover', {
    'workspaceId': workspaceId,
    'orderId': orderId,
    'otp': otp,
    'idempotencyKey': idempotencyKey,
  }, mutation: true);

  @override
  Future<WorkDeliveryAssignmentResult> requestDeliveryAssignment({
    required String workspaceId,
    required String orderId,
    required String address,
    required String idempotencyKey,
  }) async {
    final result = _map(
      await _invoke('requestWorkspaceDelivery', {
        'workspaceId': workspaceId,
        'orderId': orderId,
        'address': address,
        'idempotencyKey': idempotencyKey,
      }, mutation: true),
    );
    final eta = DateTime.tryParse(_requiredString(result['eta']));
    if (eta == null) {
      throw const WorkGatewayException(
        'Delivery assignment returned an invalid arrival time.',
        retryable: true,
      );
    }
    return WorkDeliveryAssignmentResult(
      partnerName: _requiredString(result['partnerName']),
      vehicleLabel: _requiredString(result['vehicleLabel']),
      eta: eta,
      stage: _requiredString(result['stage']),
    );
  }

  Future<Object?> _invoke(
    String operation,
    Map<String, Object?> body, {
    bool mutation = false,
  }) async {
    final response = await transport.postJson(
      endpoint,
      headers: {
        'accept': 'application/json',
        'authorization': 'Bearer ${await credentials.firebaseIdToken()}',
        'x-firebase-appcheck': await credentials.appCheckToken(
          mutation
              ? SocialAppCheckTokenMode.limitedUse
              : SocialAppCheckTokenMode.standard,
        ),
        'x-request-id': List<int>.generate(
          16,
          (_) => random.nextInt(256),
        ).map((value) => value.toRadixString(16).padLeft(2, '0')).join(),
      },
      body: {'operation': operation, ...body},
    );
    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const WorkGatewayException(
        'Workspace returned an invalid response. Try again.',
        retryable: true,
      );
    }
    final envelope = _map(decoded);
    if (envelope['ok'] == true) return envelope['data'];
    final error = _map(envelope['error']);
    throw WorkGatewayException(
      _requiredString(error['message']),
      retryable: error['retryable'] == true,
    );
  }
}

abstract interface class WorkCustomerCollectionGateway {
  Future<WorkspaceFinanceSnapshot> recordCollection(
    WorkspaceCustomerCollection request,
  );
  Future<WorkspaceFinanceSnapshot> reconcileCollection(
    WorkspaceCustomerCollection request,
  );
}

abstract interface class WorkCustomerInvoiceGateway {
  Future<WorkspaceFinanceSnapshot> reconcileInvoice({
    required String accountScope,
    required String storeId,
    required WorkspaceCustomerInvoice invoice,
  });

  Future<WorkspaceFinanceSnapshot> recordInvoice({
    required String accountScope,
    required String storeId,
    required WorkspaceCustomerInvoice invoice,
  });
}

abstract interface class WorkCustomerRefundGateway {
  Future<WorkspaceFinanceSnapshot> recordRefund(
    WorkspaceCustomerRefund request,
  );
  Future<WorkspaceFinanceSnapshot> reconcileRefund(
    WorkspaceCustomerRefund request,
  );
}

abstract interface class WorkCustomerReturnGateway {
  Future<WorkspaceFinanceSnapshot> recordReturn(
    WorkspaceCustomerReturn request,
    WorkspaceOrderRecord originalOrder,
  );
  Future<WorkspaceFinanceSnapshot> reconcileReturn(
    WorkspaceCustomerReturn request,
  );
}

abstract interface class WorkLedgerCheckpointStore {
  Future<WorkspaceLedgerCheckpoint?> read(String account, String store);
  Future<void> save(
    WorkspaceLedgerCheckpoint checkpoint, {
    required int? expectedRevision,
  });
}

/// Uses the existing encrypted device-storage mechanism, scoped to one Store.
/// Serializes native writes; a timeout cannot release an unfinished write.
class SecureWorkLedgerCheckpointStore implements WorkLedgerCheckpointStore {
  SecureWorkLedgerCheckpointStore({
    required this.accountScope,
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();
  final String? Function() accountScope;
  final FlutterSecureStorage _storage;
  static final _tails = <String, Future<void>>{};
  String _key(String account, String store) =>
      'moolsocial.workspace.ledger.v1.${Uri.encodeComponent(account)}/${Uri.encodeComponent(store)}';
  void _check(String account, String store) {
    if (account.trim().isEmpty ||
        store.trim().isEmpty ||
        accountScope() != account) {
      throw const WorkGatewayException(
        'Sign in again to recover this Store ledger.',
      );
    }
  }

  Future<T> _serial<T>(String key, Future<T> Function() action) {
    final result = (_tails[key] ?? Future<void>.value()).then((_) => action());
    final tail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _tails[key] = tail;
    unawaited(
      tail.then((_) {
        if (identical(_tails[key], tail)) _tails.remove(key);
      }),
    );
    return result;
  }

  Future<WorkspaceLedgerCheckpoint?> _read(String account, String store) async {
    _check(account, store);
    final raw = await _storage.read(key: _key(account, store));
    _check(account, store);
    if (raw == null) return null;
    WorkspaceLedgerCheckpoint? result;
    try {
      result = WorkspaceLedgerCheckpoint.fromJson(jsonDecode(raw));
    } on FormatException {
      /* Retain invalid bytes. */
    }
    if (result == null ||
        result.finance.accountScope != account ||
        result.finance.workspaceId != store) {
      throw const WorkGatewayException(
        'Saved ledger needs recovery. Its data has been kept.',
      );
    }
    return result;
  }

  @override
  Future<WorkspaceLedgerCheckpoint?> read(String account, String store) =>
      _serial(_key(account, store), () => _read(account, store));

  @override
  Future<void> save(
    WorkspaceLedgerCheckpoint checkpoint, {
    required int? expectedRevision,
  }) => _serial(
    _key(checkpoint.finance.accountScope, checkpoint.finance.workspaceId),
    () async {
      final next = checkpoint.finance;
      _check(next.accountScope, next.workspaceId);
      if (!checkpoint.valid ||
          checkpoint.revision != (expectedRevision ?? 0) + 1) {
        throw const WorkGatewayException('Ledger checkpoint is invalid.');
      }
      final current = await _read(next.accountScope, next.workspaceId);
      final encoded = jsonEncode(checkpoint.toJson());
      if (current != null && jsonEncode(current.toJson()) == encoded) return;
      if (current?.revision != expectedRevision) {
        throw const WorkGatewayException(
          'Saved ledger changed. Recover it before continuing.',
        );
      }
      for (final supplier in checkpoint.supplierLedgers.entries) {
        final previous = current?.supplierLedgers[supplier.key];
        for (final returned in supplier.value.goodsReturns.values) {
          if (previous?.goodsReturns.containsKey(returned.operationId) == true) continue;
          if (previous == null || !previous.goodsReceipts.containsKey(returned.receiptId) ||
              returned.recordedAt.isAfter(DateTime.now().toUtc())) {
            throw const WorkGatewayException('Recover the saved delivery before recording goods returned.');
          }
        }
      }
      if (current != null) {
        final previous = current.finance;
        if (current.purchaseReceipts.entries.any(
          (entry) =>
              checkpoint.purchaseReceipts[entry.key]?.canFollow(entry.value) !=
              true,
        )) {
          throw const WorkGatewayException(
            'Confirmed receipt history cannot be replaced or discarded.',
          );
        }
        if (current.moneyRegisters.entries.any(
          (entry) =>
              checkpoint.moneyRegisters[entry.key]?.canFollow(entry.value) !=
              true,
        )) {
          throw const WorkGatewayException(
            'Money register history cannot be replaced or discarded.',
          );
        }
        if (current.expenses.entries.any(
          (entry) =>
              jsonEncode(checkpoint.expenses[entry.key]?.toJson()) !=
              jsonEncode(entry.value.toJson()),
        )) {
          throw const WorkGatewayException(
            'Recorded expenses cannot be replaced or discarded.',
          );
        }
        if (current.supplierLedgers.entries.any(
          (entry) =>
              checkpoint.supplierLedgers[entry.key]?.canFollow(entry.value) !=
              true,
        )) {
          throw const WorkGatewayException(
            'Supplier ledger history cannot be replaced or discarded.',
          );
        }
        if (current.billedInvoices.entries.any(
          (entry) =>
              jsonEncode(
                checkpoint.billedInvoices[entry.key]?.toLedgerJson(),
              ) !=
              jsonEncode(entry.value.toLedgerJson()),
        )) {
          throw const WorkGatewayException(
            'Original invoices cannot be replaced or discarded.',
          );
        }
        if (current.billedOrders.entries.any(
          (entry) =>
              jsonEncode(checkpoint.billedOrders[entry.key]?.toLedgerJson()) !=
              jsonEncode(entry.value.toLedgerJson()),
        )) {
          throw const WorkGatewayException(
            'Original billed items cannot be replaced or discarded.',
          );
        }
        if (current.inventory != null &&
            checkpoint.inventory?.canFollow(current.inventory!) != true) {
          throw const WorkGatewayException(
            'Saved stock movements cannot be replaced or discarded.',
          );
        }

        if (next.revision < previous.revision ||
            next.asOf.isBefore(previous.asOf) ||
            (next.revision == previous.revision &&
                jsonEncode(checkpoint.toJson()['finance']) !=
                    jsonEncode(current.toJson()['finance'])) ||
            previous.customerLedgers.any(
              (old) =>
                  next.customerLedgers
                      .where((l) => l.customerId == old.customerId)
                      .firstOrNull
                      ?.canFollow(old) !=
                  true,
            )) {
          throw const WorkGatewayException(
            'Known ledger history cannot be replaced.',
          );
        }
        final pendingRefund = current.pendingRefund;
        if (pendingRefund != null) {
          if (checkpoint.pending != null ||
              checkpoint.pendingReturn != null ||
              (checkpoint.pendingRefund != null &&
                  checkpoint.pendingRefund!.identityData !=
                      pendingRefund.identityData)) {
            throw const WorkGatewayException(
              'The original refund must be reconciled first.',
            );
          }
          if (checkpoint.pendingRefund == null) {
            final entries = next.customerLedgers
                .where(
                  (ledger) => ledger.customerId == pendingRefund.customerId,
                )
                .expand((ledger) => ledger.entries)
                .where(
                  (entry) => entry.operationId == pendingRefund.operationId,
                )
                .toList();
            final before = previous.payments
                .where(
                  (p) =>
                      p.invoiceId == pendingRefund.invoiceId &&
                      p.orderId == pendingRefund.orderId &&
                      p.customerId == pendingRefund.customerId,
                )
                .firstOrNull;
            final after = next.payments
                .where(
                  (p) =>
                      p.invoiceId == pendingRefund.invoiceId &&
                      p.orderId == pendingRefund.orderId &&
                      p.customerId == pendingRefund.customerId,
                )
                .firstOrNull;
            if (entries.length != 1 ||
                entries.single.kind != WorkspaceLedgerEntryKind.refund ||
                entries.single.state != WorkspaceLedgerPostingState.posted ||
                entries.single.customerRefund?.identityData !=
                    pendingRefund.identityData ||
                before == null ||
                after == null ||
                after.amountMinor != before.amountMinor ||
                after.paidMinor != before.paidMinor ||
                after.dueMinor != before.dueMinor ||
                after.refundedMinor !=
                    before.refundedMinor + pendingRefund.amountMinor ||
                jsonEncode(checkpoint.inventory?.toJson()) !=
                    jsonEncode(current.inventory?.toJson())) {
              throw const WorkGatewayException(
                'Confirmed refund must match its invoice without changing stock.',
              );
            }
          }
        }
        final pendingReturn = current.pendingReturn;
        if (pendingReturn != null) {
          if (checkpoint.pending != null ||
              (checkpoint.pendingReturn != null &&
                  jsonEncode(checkpoint.pendingReturn!.toJson()) !=
                      jsonEncode(pendingReturn.toJson()))) {
            throw const WorkGatewayException(
              'The original return must be reconciled first.',
            );
          }
          if (checkpoint.pendingReturn == null) {
            final request = pendingReturn.request;
            final entries = next.customerLedgers
                .where((ledger) => ledger.customerId == request.customerId)
                .expand((ledger) => ledger.entries)
                .where((entry) => entry.operationId == request.operationId)
                .toList();
            final before = previous.payments
                .where(
                  (p) =>
                      p.invoiceId == request.invoiceId &&
                      p.orderId == request.orderId &&
                      p.customerId == request.customerId,
                )
                .firstOrNull;
            final after = next.payments
                .where(
                  (p) =>
                      p.invoiceId == request.invoiceId &&
                      p.orderId == request.orderId &&
                      p.customerId == request.customerId,
                )
                .firstOrNull;
            final due = before == null
                ? null
                : (before.dueMinor - pendingReturn.creditMinor).clamp(
                    0,
                    before.dueMinor,
                  );
            if (entries.length != 1 ||
                entries.single.kind != WorkspaceLedgerEntryKind.creditNote ||
                entries.single.state != WorkspaceLedgerPostingState.posted ||
                entries.single.amountMinor != pendingReturn.creditMinor ||
                entries.single.customerReturn == null ||
                jsonEncode(entries.single.customerReturn!.toJson()) !=
                    jsonEncode(request.toJson()) ||
                before == null ||
                after == null ||
                after.dueMinor != due ||
                after.amountMinor != before.amountMinor ||
                after.paidMinor != before.paidMinor ||
                after.refundedMinor != before.refundedMinor) {
              throw const WorkGatewayException(
                'Confirmed return must match its original invoice and quantities.',
              );
            }
            if (pendingReturn.originalItems.isNotEmpty) {
              final expected = entries.single
                  .returnStockMovementsFromSavedItems(
                    pendingReturn.originalItems,
                  );
              final acknowledged = {
                for (final movement
                    in checkpoint.inventory?.movements ??
                        const <WorkspaceStockMovement>[])
                  movement.id: movement,
              };
              if (current.inventory == null ||
                  checkpoint.inventory == null ||
                  expected == null ||
                  expected.any(
                    (movement) =>
                        acknowledged[movement.id]?.contentIdentity !=
                        movement.contentIdentity,
                  )) {
                throw const WorkGatewayException(
                  'Return stock movements must be saved with the credit.',
                );
              }
            }
          }
        }
        final pending = current.pending;
        if (pending != null) {
          if (checkpoint.pending != null &&
              checkpoint.pending!.identityData != pending.identityData) {
            throw const WorkGatewayException(
              'The original collection must be reconciled first.',
            );
          }
          if (checkpoint.pending == null) {
            final before = previous.payments
                .where(
                  (p) =>
                      p.orderId == pending.orderId &&
                      p.invoiceId == pending.invoiceId &&
                      p.customerId == pending.customerId,
                )
                .firstOrNull;
            final after = next.payments
                .where(
                  (p) =>
                      p.orderId == pending.orderId &&
                      p.invoiceId == pending.invoiceId &&
                      p.customerId == pending.customerId,
                )
                .firstOrNull;
            if (before == null ||
                after == null ||
                after.amountMinor != before.amountMinor ||
                after.dueMinor != before.dueMinor - pending.amountMinor ||
                after.paidMinor != before.paidMinor + pending.amountMinor ||
                after.refundedMinor != before.refundedMinor) {
              throw const WorkGatewayException(
                'Confirmed collection must match its invoice balance.',
              );
            }
            final entries = next.customerLedgers
                .where((l) => l.customerId == pending.customerId)
                .expand((l) => l.entries)
                .where((e) => e.operationId == pending.operationId);
            if (entries.length != 1 ||
                entries.single.invoiceId != pending.invoiceId ||
                entries.single.orderId != pending.orderId ||
                entries.single.kind != WorkspaceLedgerEntryKind.collection ||
                entries.single.state != WorkspaceLedgerPostingState.posted ||
                entries.single.amountMinor != pending.amountMinor ||
                entries.single.channel != pending.channel ||
                entries.single.paymentReference != pending.reference) {
              throw const WorkGatewayException(
                'Unconfirmed collection cannot be removed.',
              );
            }
          }
        }
      }
      await _storage.write(
        key: _key(next.accountScope, next.workspaceId),
        value: encoded,
      );
      _check(next.accountScope, next.workspaceId);
    },
  );
}

/// Synthetic adapter for the existing labelled Store. No network or real money.
class StoreReviewCustomerCollectionGateway
    implements
        WorkCustomerCollectionGateway,
        WorkCustomerInvoiceGateway,
        WorkCustomerReturnGateway,
        WorkCustomerRefundGateway {
  StoreReviewCustomerCollectionGateway(this._finance);
  WorkspaceFinanceSnapshot _finance;
  final _requests = <String, WorkspaceCustomerCollection>{};
  final _replies = <String, WorkspaceFinanceSnapshot>{};
  bool _hasRecordedInvoices = false;

  /// Pure local preview: no money movement or adapter mutation before the
  /// caller's atomic checkpoint save. Production requires its own capability.
  WorkspaceFinanceSnapshot previewCreditAllocation({required String customerId,
    required String sourceInvoiceId, required String targetInvoiceId,
    required int amountMinor, required int expectedRevision, required String operationId}) {
    final ledger = _finance.customerLedgers.singleWhere((l) => l.customerId == customerId);
    final now = DateTime.now().toUtc();
    final nextLedger = ledger.allocateCredit(sourceInvoiceId: sourceInvoiceId,
      targetInvoiceId: targetInvoiceId, amountMinor: amountMinor,
      expectedRevision: expectedRevision, operationId: operationId, at: now);
    if (identical(ledger, nextLedger)) return _finance;
    final payment = _finance.payments.singleWhere((p) => p.customerId == customerId && p.invoiceId == targetInvoiceId);
    if (payment.dueMinor < amountMinor || payment.channel == WorkspacePaymentChannel.platform ||
        _finance.duesMinor < amountMinor) { throw StateError('Invoice is not eligible for local credit.'); }
    final next = WorkspaceFinanceSnapshot(accountScope: _finance.accountScope,
      workspaceId: _finance.workspaceId, revision: _finance.revision + 1, asOf: now,
      salesTodayMinor: _finance.salesTodayMinor, duesMinor: _finance.duesMinor - amountMinor,
      availableMinor: _finance.availableMinor, heldMinor: _finance.heldMinor,
      requestedMinor: _finance.requestedMinor, paidOutMinor: _finance.paidOutMinor,
      feesMinor: _finance.feesMinor, deliveryAdjustmentsMinor: _finance.deliveryAdjustmentsMinor,
      refundsMinor: _finance.refundsMinor, taxWithheldMinor: _finance.taxWithheldMinor,
      historyComplete: _finance.historyComplete, payouts: _finance.payouts,
      payments: [for (final p in _finance.payments)
        if (identical(p, payment)) WorkspacePaymentRecord(orderId: p.orderId,
          customerId: p.customerId, customerName: p.customerName, revision: p.revision + 1,
          updatedAt: now, amountMinor: p.amountMinor, paidMinor: p.paidMinor,
          dueMinor: p.dueMinor - amountMinor, refundedMinor: p.refundedMinor,
          state: WorkspacePaymentState.creditApplied, channel: p.channel,
          invoiceId: p.invoiceId, transactionId: p.transactionId)
        else p],
      customerLedgers: [for (final l in _finance.customerLedgers)
        l.customerId == customerId ? nextLedger : l]);
    if (!next.valid || !nextLedger.canFollow(ledger)) throw StateError('Credit projection is invalid.');
    return next;
  }

  bool acceptSavedCredit(WorkspaceFinanceSnapshot before, WorkspaceFinanceSnapshot saved) {
    if (!identical(before, _finance) || !saved.valid || saved.accountScope != before.accountScope ||
        saved.workspaceId != before.workspaceId || saved.revision != before.revision + 1) { return false; }
    _finance = saved;
    _hasRecordedInvoices = true;
    return true;
  }

  @override
  Future<WorkspaceFinanceSnapshot> reconcileInvoice({
    required String accountScope,
    required String storeId,
    required WorkspaceCustomerInvoice invoice,
  }) async {
    final payment = _finance.payments
        .where((p) => p.invoiceId == invoice.id && p.orderId == invoice.orderId)
        .firstOrNull;
    if (accountScope != _finance.accountScope ||
        storeId != _finance.workspaceId ||
        payment == null ||
        payment.customerId != workspaceCustomerMobile(invoice.customer) ||
        !invoice.validBillAmounts ||
        payment.amountMinor != invoice.payableMinor) {
      throw StateError('Invoice status is not confirmed.');
    }
    return _finance;
  }

  @override
  Future<WorkspaceFinanceSnapshot> recordInvoice({
    required String accountScope,
    required String storeId,
    required WorkspaceCustomerInvoice invoice,
  }) async {
    final customerId = workspaceCustomerMobile(invoice.customer);
    if (accountScope != _finance.accountScope ||
        storeId != _finance.workspaceId ||
        customerId == null ||
        invoice.id.trim().isEmpty ||
        invoice.orderId.trim().isEmpty ||
        !invoice.validBillAmounts ||
        invoice.payableMinor <= 0) {
      throw StateError('Invoice does not identify this Store and customer.');
    }
    final previousPayment = _finance.payments
        .where((p) => p.invoiceId == invoice.id || p.orderId == invoice.orderId)
        .firstOrNull;
    if (previousPayment != null) {
      if (previousPayment.invoiceId != invoice.id ||
          previousPayment.orderId != invoice.orderId ||
          previousPayment.customerId != customerId ||
          previousPayment.amountMinor != invoice.payableMinor) {
        throw StateError('Invoice identity cannot be changed.');
      }
      return _finance;
    }
    final previous = _finance.customerLedgers
        .where((l) => l.customerId == customerId)
        .firstOrNull;
    if (previous != null && !previous.historyComplete) {
      throw StateError('Customer history needs recovery.');
    }
    final now = DateTime.now().toUtc();
    final amount = invoice.payableMinor;
    final ledger = WorkspaceCustomerLedger(
      accountScope: accountScope,
      workspaceId: storeId,
      customerId: customerId,
      customerName: invoice.customer,
      revision: (previous?.revision ?? 0) + 1,
      asOf: now,
      openingBalanceMinor: previous?.openingBalanceMinor ?? 0,
      historyComplete: true,
      entries: [
        ...?previous?.entries,
        WorkspaceCustomerLedgerEntry(
          id: 'QA-BILL-${invoice.id}',
          operationId: 'BILL-${invoice.orderId}',
          invoiceId: invoice.id,
          orderId: invoice.orderId,
          sequence: (previous?.entries.lastOrNull?.sequence ?? 0) + 1,
          occurredAt: now,
          kind: WorkspaceLedgerEntryKind.invoice,
          state: WorkspaceLedgerPostingState.posted,
          amountMinor: amount,
        ),
      ],
    );
    final next = WorkspaceFinanceSnapshot(
      accountScope: accountScope,
      workspaceId: storeId,
      revision: _finance.revision + 1,
      asOf: now,
      salesTodayMinor: _finance.salesTodayMinor + amount,
      duesMinor: _finance.duesMinor + amount,
      availableMinor: _finance.availableMinor,
      heldMinor: _finance.heldMinor,
      requestedMinor: _finance.requestedMinor,
      paidOutMinor: _finance.paidOutMinor,
      feesMinor: _finance.feesMinor,
      deliveryAdjustmentsMinor: _finance.deliveryAdjustmentsMinor,
      refundsMinor: _finance.refundsMinor,
      taxWithheldMinor: _finance.taxWithheldMinor,
      payments: [
        ..._finance.payments,
        WorkspacePaymentRecord(
          orderId: invoice.orderId,
          customerId: customerId,
          customerName: invoice.customer,
          revision: 1,
          updatedAt: now,
          amountMinor: amount,
          paidMinor: 0,
          dueMinor: amount,
          refundedMinor: 0,
          state: WorkspacePaymentState.unpaid,
          channel: invoice.payment == 'Customer due'
              ? WorkspacePaymentChannel.credit
              : WorkspacePaymentChannel.unknown,
          invoiceId: invoice.id,
        ),
      ],
      payouts: _finance.payouts,
      customerLedgers: [
        ..._finance.customerLedgers.where((l) => l.customerId != customerId),
        ledger,
      ],
      historyComplete: _finance.historyComplete,
    );
    if (!next.valid || (previous != null && !ledger.canFollow(previous))) {
      throw StateError('Invoice projection is invalid.');
    }
    _finance = next;
    _hasRecordedInvoices = true;
    return next;
  }

  final _refundRequests = <String, WorkspaceCustomerRefund>{};
  @override
  Future<WorkspaceFinanceSnapshot> reconcileRefund(
    WorkspaceCustomerRefund request,
  ) async {
    if (!request.valid ||
        request.accountScope != _finance.accountScope ||
        request.workspaceId != _finance.workspaceId) {
      throw StateError('Refund does not belong to this Store.');
    }
    final entry = _finance.customerLedgers
        .where((ledger) => ledger.customerId == request.customerId)
        .expand((ledger) => ledger.entries)
        .where(
          (entry) =>
              entry.operationId == request.operationId &&
              entry.kind == WorkspaceLedgerEntryKind.refund,
        )
        .firstOrNull;
    final known = _refundRequests[request.operationId];
    if (entry == null ||
        entry.state != WorkspaceLedgerPostingState.posted ||
        entry.customerRefund?.identityData != request.identityData ||
        entry.invoiceId != request.invoiceId ||
        entry.orderId != request.orderId ||
        entry.amountMinor != request.amountMinor ||
        entry.channel != request.channel ||
        entry.paymentReference != request.reference ||
        (known != null && known.identityData != request.identityData)) {
      throw StateError('Refund status is not confirmed.');
    }
    return _finance;
  }

  @override
  Future<WorkspaceFinanceSnapshot> recordRefund(
    WorkspaceCustomerRefund request,
  ) async {
    if (!request.valid ||
        request.accountScope != _finance.accountScope ||
        request.workspaceId != _finance.workspaceId) {
      throw StateError('Refund does not belong to this Store.');
    }
    if (_finance.customerLedgers
        .expand((ledger) => ledger.entries)
        .any(
          (entry) =>
              entry.operationId == request.operationId &&
              entry.kind == WorkspaceLedgerEntryKind.refund,
        )) {
      return reconcileRefund(request);
    }
    final ledger = _finance.customerLedgers
        .where((ledger) => ledger.customerId == request.customerId)
        .firstOrNull;
    final payment = _finance.payments
        .where(
          (payment) =>
              payment.customerId == request.customerId &&
              payment.invoiceId == request.invoiceId &&
              payment.orderId == request.orderId,
        )
        .firstOrNull;
    final balance = ledger?.invoiceBalance(request.invoiceId);
    if (ledger == null ||
        ledger.revision != request.expectedRevision ||
        payment == null ||
        balance == null ||
        request.amountMinor > balance.refundableMinor ||
        !ledger.permitsReceiptRefund(request) ||
        payment.paidMinor != balance.collectedMinor ||
        payment.refundedMinor != balance.refundedMinor ||
        payment.channel == WorkspacePaymentChannel.platform) {
      throw StateError(
        'Refund requires a confirmed refundable balance and the original payment authority.',
      );
    }
    final now = DateTime.now().toUtc();
    final nextLedger = WorkspaceCustomerLedger(
      accountScope: ledger.accountScope,
      workspaceId: ledger.workspaceId,
      customerId: ledger.customerId,
      customerName: ledger.customerName,
      revision: ledger.revision + 1,
      asOf: now,
      openingBalanceMinor: ledger.openingBalanceMinor,
      historyComplete: ledger.historyComplete,
      entries: [
        ...ledger.entries,
        WorkspaceCustomerLedgerEntry(
          id: 'QA-REFUND-${request.operationId}',
          operationId: request.operationId,
          invoiceId: request.invoiceId,
          orderId: request.orderId,
          sequence: (ledger.entries.lastOrNull?.sequence ?? 0) + 1,
          occurredAt: now,
          kind: WorkspaceLedgerEntryKind.refund,
          customerRefund: request,
          state: WorkspaceLedgerPostingState.posted,
          amountMinor: request.amountMinor,
          channel: request.channel,
          paymentReference: request.reference,
        ),
      ],
    );
    final refunded = payment.refundedMinor + request.amountMinor;
    final nextPayment = WorkspacePaymentRecord(
      orderId: payment.orderId,
      customerId: payment.customerId,
      customerName: payment.customerName,
      revision: payment.revision + 1,
      updatedAt: now,
      amountMinor: payment.amountMinor,
      paidMinor: payment.paidMinor,
      dueMinor: payment.dueMinor,
      refundedMinor: refunded,
      state: request.amountMinor < balance.refundableMinor
          ? WorkspacePaymentState.refundPending
          : refunded == payment.paidMinor
          ? WorkspacePaymentState.refunded
          : WorkspacePaymentState.returnAdjusted,
      channel: payment.channel,
      invoiceId: payment.invoiceId,
      transactionId: payment.transactionId,
    );
    final next = WorkspaceFinanceSnapshot(
      accountScope: _finance.accountScope,
      workspaceId: _finance.workspaceId,
      revision: _finance.revision + 1,
      asOf: now,
      salesTodayMinor: _finance.salesTodayMinor,
      duesMinor: _finance.duesMinor,
      availableMinor: _finance.availableMinor,
      heldMinor: _finance.heldMinor,
      requestedMinor: _finance.requestedMinor,
      paidOutMinor: _finance.paidOutMinor,
      feesMinor: _finance.feesMinor,
      deliveryAdjustmentsMinor: _finance.deliveryAdjustmentsMinor,
      refundsMinor: _finance.refundsMinor + request.amountMinor,
      taxWithheldMinor: _finance.taxWithheldMinor,
      payments: [
        for (final item in _finance.payments)
          item.orderId == payment.orderId ? nextPayment : item,
      ],
      payouts: _finance.payouts,
      customerLedgers: [
        for (final item in _finance.customerLedgers)
          item.customerId == ledger.customerId ? nextLedger : item,
      ],
      historyComplete: _finance.historyComplete,
    );
    if (!next.valid ||
        !nextLedger.canFollow(ledger) ||
        nextLedger.invoiceBalance(request.invoiceId) == null) {
      throw StateError('Refund projection is invalid.');
    }
    _refundRequests[request.operationId] = request;
    _finance = next;
    _hasRecordedInvoices = true;
    return next;
  }

  void _checkReturnScope(WorkspaceCustomerReturn request) {
    if (!request.valid ||
        request.accountScope != _finance.accountScope ||
        request.workspaceId != _finance.workspaceId) {
      throw StateError('Return does not belong to this Store.');
    }
  }

  @override
  Future<WorkspaceFinanceSnapshot> reconcileReturn(
    WorkspaceCustomerReturn request,
  ) async {
    _checkReturnScope(request);
    final recorded = _finance.customerLedgers
        .expand((ledger) => ledger.entries)
        .where(
          (entry) =>
              entry.kind == WorkspaceLedgerEntryKind.creditNote &&
              entry.operationId == request.operationId,
        )
        .firstOrNull;
    if (recorded == null ||
        recorded.state != WorkspaceLedgerPostingState.posted ||
        recorded.customerReturn == null ||
        jsonEncode(recorded.customerReturn!.toJson()) !=
            jsonEncode(request.toJson())) {
      throw StateError('Return status is not confirmed.');
    }
    return _finance;
  }

  @override
  Future<WorkspaceFinanceSnapshot> recordReturn(
    WorkspaceCustomerReturn request,
    WorkspaceOrderRecord originalOrder,
  ) async {
    _checkReturnScope(request);
    final replay = _finance.customerLedgers
        .expand((ledger) => ledger.entries)
        .any(
          (entry) =>
              entry.kind == WorkspaceLedgerEntryKind.creditNote &&
              entry.operationId == request.operationId,
        );
    if (replay) return reconcileReturn(request);
    final ledger = _finance.customerLedgers
        .where((ledger) => ledger.customerId == request.customerId)
        .firstOrNull;
    final payment = _finance.payments
        .where(
          (payment) =>
              payment.invoiceId == request.invoiceId &&
              payment.orderId == request.orderId &&
              payment.customerId == request.customerId,
        )
        .firstOrNull;
    final balance = ledger?.invoiceBalance(request.invoiceId);
    if (ledger == null ||
        ledger.revision != request.expectedRevision ||
        balance == null ||
        payment == null ||
        payment.amountMinor != originalOrder.payableMinor ||
        workspaceCustomerMobile(originalOrder.customer) != request.customerId ||
        payment.dueMinor != balance.dueMinor) {
      throw StateError(
        'Refresh the original invoice before accepting a return.',
      );
    }
    final credits = ledger.entries.where(
      (entry) =>
          entry.invoiceId == request.invoiceId &&
          entry.kind == WorkspaceLedgerEntryKind.creditNote,
    );
    if (credits.any(
      (entry) =>
          entry.customerReturn == null ||
          entry.state == WorkspaceLedgerPostingState.pending,
    )) {
      throw StateError('Earlier return quantities need confirmation.');
    }
    final amount = request.creditMinorFor(
      originalOrder,
      priorReturns: [
        for (final entry in credits)
          if (entry.state == WorkspaceLedgerPostingState.posted)
            entry.customerReturn!,
      ],
    );
    if (amount == null ||
        amount <= 0 ||
        amount > balance.billedMinor - balance.creditedMinor) {
      throw StateError(
        'Return quantities or original prices cannot be verified.',
      );
    }
    final now = DateTime.now().toUtc();
    final nextLedger = WorkspaceCustomerLedger(
      accountScope: ledger.accountScope,
      workspaceId: ledger.workspaceId,
      customerId: ledger.customerId,
      customerName: ledger.customerName,
      revision: ledger.revision + 1,
      asOf: now,
      openingBalanceMinor: ledger.openingBalanceMinor,
      historyComplete: ledger.historyComplete,
      entries: [
        ...ledger.entries,
        WorkspaceCustomerLedgerEntry(
          id: 'QA-CREDIT-${request.operationId}',
          operationId: request.operationId,
          invoiceId: request.invoiceId,
          orderId: request.orderId,
          sequence: (ledger.entries.lastOrNull?.sequence ?? 0) + 1,
          occurredAt: now,
          kind: WorkspaceLedgerEntryKind.creditNote,
          state: WorkspaceLedgerPostingState.posted,
          amountMinor: amount,
          customerReturn: request,
        ),
      ],
    );
    final nextBalance = nextLedger.invoiceBalance(request.invoiceId);
    if (nextBalance == null) {
      throw StateError('Return balance is inconsistent.');
    }
    final nextPayment = WorkspacePaymentRecord(
      orderId: payment.orderId,
      customerId: payment.customerId,
      customerName: payment.customerName,
      revision: payment.revision + 1,
      updatedAt: now,
      amountMinor: payment.amountMinor,
      paidMinor: payment.paidMinor,
      dueMinor: nextBalance.dueMinor,
      refundedMinor: payment.refundedMinor,
      state: nextBalance.refundableMinor > 0
          ? WorkspacePaymentState.refundPending
          : nextBalance.dueMinor == 0
          ? WorkspacePaymentState.returnAdjusted
          : payment.paidMinor > 0
          ? WorkspacePaymentState.partPaid
          : WorkspacePaymentState.unpaid,
      channel: payment.channel,
      invoiceId: payment.invoiceId,
      transactionId: payment.transactionId,
    );
    final next = WorkspaceFinanceSnapshot(
      accountScope: _finance.accountScope,
      workspaceId: _finance.workspaceId,
      revision: _finance.revision + 1,
      asOf: now,
      salesTodayMinor: _finance.salesTodayMinor,
      duesMinor: _finance.duesMinor - payment.dueMinor + nextBalance.dueMinor,
      availableMinor: _finance.availableMinor,
      heldMinor: _finance.heldMinor,
      requestedMinor: _finance.requestedMinor,
      paidOutMinor: _finance.paidOutMinor,
      feesMinor: _finance.feesMinor,
      deliveryAdjustmentsMinor: _finance.deliveryAdjustmentsMinor,
      refundsMinor: _finance.refundsMinor,
      taxWithheldMinor: _finance.taxWithheldMinor,
      payments: [
        for (final item in _finance.payments)
          item.orderId == payment.orderId ? nextPayment : item,
      ],
      payouts: _finance.payouts,
      customerLedgers: [
        for (final item in _finance.customerLedgers)
          item.customerId == ledger.customerId ? nextLedger : item,
      ],
      historyComplete: _finance.historyComplete,
    );
    if (!next.valid || !nextLedger.canFollow(ledger)) {
      throw StateError('Return projection is invalid.');
    }
    _finance = next;
    _hasRecordedInvoices = true;
    return next;
  }

  /// Only replace an untouched synthetic seed; never reset an active adapter.
  bool restoreCheckpoint(
    WorkspaceFinanceSnapshot saved,
    WorkspaceFinanceSnapshot current,
  ) {
    String fingerprint(WorkspaceFinanceSnapshot value) => jsonEncode(
      WorkspaceLedgerCheckpoint(
        revision: 1,
        finance: value,
      ).toJson()['finance'],
    );
    if (_hasRecordedInvoices ||
        _requests.isNotEmpty ||
        _replies.isNotEmpty ||
        !saved.valid ||
        saved.accountScope != _finance.accountScope ||
        saved.workspaceId != _finance.workspaceId ||
        fingerprint(current) != fingerprint(_finance)) {
      return false;
    }
    _finance = saved;
    return true;
  }

  void _checkIdentity(WorkspaceCustomerCollection request) {
    if (!request.valid ||
        request.accountScope != _finance.accountScope ||
        request.workspaceId != _finance.workspaceId ||
        (_requests[request.operationId] != null &&
            _requests[request.operationId]!.identityData !=
                request.identityData)) {
      throw StateError('Collection identity does not match this test Store.');
    }
  }

  @override
  Future<WorkspaceFinanceSnapshot> recordCollection(
    WorkspaceCustomerCollection request,
  ) async {
    _checkIdentity(request);
    final replay = _replies[request.operationId];
    if (replay != null) return replay;
    final ledger = _finance.customerLedgers
        .where((l) => l.customerId == request.customerId)
        .firstOrNull;
    final payment = _finance.payments
        .where(
          (p) =>
              p.invoiceId == request.invoiceId &&
              p.orderId == request.orderId &&
              p.customerId == request.customerId,
        )
        .firstOrNull;
    final invoiceBalance = ledger?.invoiceBalance(request.invoiceId);
    if (invoiceBalance == null ||
        request.amountMinor > invoiceBalance.dueMinor ||
        ledger == null ||
        !ledger.historyComplete ||
        ledger.revision != request.expectedRevision ||
        payment == null ||
        request.amountMinor > payment.dueMinor ||
        request.amountMinor > _finance.duesMinor) {
      throw StateError('Refresh this invoice before recording a collection.');
    }
    final now = DateTime.now().toUtc();
    final nextLedger = WorkspaceCustomerLedger(
      accountScope: ledger.accountScope,
      workspaceId: ledger.workspaceId,
      customerId: ledger.customerId,
      customerName: ledger.customerName,
      revision: ledger.revision + 1,
      asOf: now,
      openingBalanceMinor: ledger.openingBalanceMinor,
      historyComplete: true,
      entries: [
        ...ledger.entries,
        WorkspaceCustomerLedgerEntry(
          id: 'QA-COLLECTION-${request.operationId}',
          channel: request.channel,
          paymentReference: request.reference,
          operationId: request.operationId,
          invoiceId: request.invoiceId,
          orderId: request.orderId,
          sequence: (ledger.entries.lastOrNull?.sequence ?? 0) + 1,
          occurredAt: now,
          kind: WorkspaceLedgerEntryKind.collection,
          state: WorkspaceLedgerPostingState.posted,
          amountMinor: request.amountMinor,
        ),
      ],
    );
    final due = payment.dueMinor - request.amountMinor;
    final nextPayment = WorkspacePaymentRecord(
      orderId: payment.orderId,
      customerId: payment.customerId,
      customerName: payment.customerName,
      revision: payment.revision + 1,
      updatedAt: now,
      amountMinor: payment.amountMinor,
      paidMinor: payment.paidMinor + request.amountMinor,
      dueMinor: due,
      refundedMinor: payment.refundedMinor,
      state: due == 0
          ? payment.paidMinor + request.amountMinor == payment.amountMinor
                ? WorkspacePaymentState.paid
                : nextLedger.entries.any((e) => e.invoiceId == payment.invoiceId &&
                    e.kind == WorkspaceLedgerEntryKind.creditReceived)
                    ? WorkspacePaymentState.creditApplied
                    : WorkspacePaymentState.returnAdjusted
          : WorkspacePaymentState.partPaid,
      channel: request.channel,
      invoiceId: payment.invoiceId,
      transactionId: request.operationId,
    );
    final next = WorkspaceFinanceSnapshot(
      accountScope: _finance.accountScope,
      workspaceId: _finance.workspaceId,
      revision: _finance.revision + 1,
      asOf: now,
      salesTodayMinor: _finance.salesTodayMinor,
      duesMinor: _finance.duesMinor - request.amountMinor,
      availableMinor: _finance.availableMinor,
      heldMinor: _finance.heldMinor,
      requestedMinor: _finance.requestedMinor,
      paidOutMinor: _finance.paidOutMinor,
      feesMinor: _finance.feesMinor,
      deliveryAdjustmentsMinor: _finance.deliveryAdjustmentsMinor,
      refundsMinor: _finance.refundsMinor,
      taxWithheldMinor: _finance.taxWithheldMinor,
      payments: [
        for (final p in _finance.payments)
          p.orderId == payment.orderId ? nextPayment : p,
      ],
      payouts: _finance.payouts,
      customerLedgers: [
        for (final l in _finance.customerLedgers)
          l.customerId == ledger.customerId ? nextLedger : l,
      ],
      historyComplete: _finance.historyComplete,
    );
    if (!next.valid || !nextLedger.canFollow(ledger)) {
      throw StateError('Invalid synthetic collection projection.');
    }
    _requests[request.operationId] = request;
    _finance = next;
    _replies[request.operationId] = next;
    return next;
  }

  @override
  Future<WorkspaceFinanceSnapshot> reconcileCollection(
    WorkspaceCustomerCollection request,
  ) async {
    _checkIdentity(request);
    final reply = _replies[request.operationId];
    if (reply == null) throw StateError('Collection is not confirmed.');
    return reply;
  }
}

enum WorkReviewTestCase { pending, clarification, rejected, approved }

/// A review-fixture selection, never Store approval or payment authority.
abstract interface class WorkReviewStoreSelectionStore {
  Future<StoreReviewSeed?> read(String account);
  Future<StoreReviewSeed?> archiveLegacySelectionForEntry(String account);
  Future<void> save(StoreReviewSeed seed);
}

class SecureWorkReviewStoreSelectionStore
    implements WorkReviewStoreSelectionStore {
  SecureWorkReviewStoreSelectionStore({
    required this.accountScope,
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();
  final String? Function() accountScope;
  final FlutterSecureStorage _storage;
  static const enabled =
      kDebugMode &&
      bool.fromEnvironment('MOOLSOCIAL_DEVICE_REVIEW') &&
      bool.fromEnvironment('MOOLSOCIAL_UI_REVIEW_ONLY');
  static final Map<String, Future<void>> _pending = {};
  String _key(String account) =>
      'moolsocial.workspace.review-store-selection.v1.${Uri.encodeComponent(account)}';
  void _check(String account) {
    if (!enabled || account.trim().isEmpty || accountScope() != account) {
      throw const WorkGatewayException(
        'Return to the same review account to reopen this test Store.',
      );
    }
  }

  Future<T> _exclusive<T>(String account, Future<T> Function() action) {
    final key = _key(account);
    final result = (_pending[key] ?? Future<void>.value()).then(
      (_) => action(),
    );
    final tail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _pending[key] = tail;
    unawaited(
      tail.then((_) {
        if (identical(_pending[key], tail)) _pending.remove(key);
      }),
    );
    return result;
  }

  Future<StoreReviewSeed?> _read(String account) async {
    _check(account);
    final raw = await _storage.read(key: _key(account));
    _check(account);
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw);
      if (data is! Map ||
          data.length != 4 ||
          data['version'] != StoreReviewSeed.version ||
          data['account'] != account ||
          data['orderCount'] is! int ||
          data['seedAt'] is! String) {
        throw const FormatException();
      }
      return StoreReviewSeed(
        accountScope: account,
        orderCount: data['orderCount'] as int,
        now: DateTime.parse(data['seedAt'] as String),
      );
    } on Object {
      throw const WorkGatewayException(
        'The saved test Store could not be reopened. Its saved bills have not been removed.',
      );
    }
  }

  @override
  Future<StoreReviewSeed?> read(String account) =>
      _exclusive(account, () => _read(account));

  /// Frontend evaluation migration only. Old Store namespaces (inventory,
  /// financial journals and drafts) remain intact under their original IDs.
  /// Never reset those records or grant production inventory authority.
  @override
  Future<StoreReviewSeed?> archiveLegacySelectionForEntry(
    String account,
  ) => _exclusive(account, () async {
    final previous = await _read(account);
    if (previous == null || previous.orderCount == 0) return previous;
    final selectionKey = _key(account);
    final raw = await _storage.read(key: selectionKey);
    _check(account);
    if (raw == null) {
      throw const WorkGatewayException(
        'The selected test Store changed. Retry.',
      );
    }
    final archiveKey = '$selectionKey.archive.${previous.storeId}';
    final archived = await _storage.read(key: archiveKey);
    _check(account);
    if (archived != null && archived != raw) {
      throw const WorkGatewayException(
        'The previous test Store archive needs review. Its data has been kept.',
      );
    }
    if (archived == null) {
      await _storage.write(key: archiveKey, value: raw);
    }
    _check(account);
    if (await _storage.read(key: archiveKey) != raw) {
      throw const WorkGatewayException(
        'The test Store archive was not saved. Retry.',
      );
    }
    _check(account);
    // Another session must not be silently overwritten after archival.
    if (await _storage.read(key: selectionKey) != raw) {
      throw const WorkGatewayException(
        'The selected test Store changed. Retry.',
      );
    }
    _check(account);
    final empty = StoreReviewSeed(
      accountScope: account,
      orderCount: 0,
      now: previous.now,
    );
    final replacement = jsonEncode({
      'version': StoreReviewSeed.version,
      'account': account,
      'orderCount': 0,
      'seedAt': empty.now.toIso8601String(),
    });
    await _storage.write(key: selectionKey, value: replacement);
    _check(account);
    if (await _storage.read(key: selectionKey) != replacement) {
      throw const WorkGatewayException(
        'The empty test Store was not saved. Retry.',
      );
    }
    _check(account);
    return empty;
  });
  @override
  Future<void> save(StoreReviewSeed seed) =>
      _exclusive(seed.accountScope, () async {
        await _read(
          seed.accountScope,
        ); // Preserve corrupt/unknown data instead of replacing it.
        _check(seed.accountScope);
        await _storage.write(
          key: _key(seed.accountScope),
          value: jsonEncode({
            'version': StoreReviewSeed.version,
            'account': seed.accountScope,
            'orderCount': seed.orderCount,
            'seedAt': seed.now.toIso8601String(),
          }),
        );
        _check(seed.accountScope);
      });
}

/// Versioned, synthetic projections for frontend UAT and future adapter tests.
/// Pure data only: no network, approval, payment or collection authority.
/// The runtime loader separately requires both review defines and debug mode.
/// Replaceable reference data for the empty frontend evaluation Store only.
/// No inventory, prices, orders, payments or approval are created by this list.
final storeEntryEvaluationCatalogue = List<WorkspaceCatalogueItem>.unmodifiable(
  [
    for (final row in const [
      (
        'oil-1l',
        'Sunflower oil',
        'Refined sunflower oil',
        '1 L pouch',
        'oils-ghee',
        1415081,
      ),
      (
        'atta-1kg',
        'Whole wheat atta',
        'Whole wheat flour',
        '1 kg pack',
        'flour-grains',
        1832510,
      ),
      (
        'salt-1kg',
        'Iodised salt',
        'Iodised salt',
        '1 kg pack',
        'salt-spices',
        1530221,
      ),
      (
        'rice-1kg',
        'Basmati rice',
        'Long grain rice',
        '1 kg pouch',
        'flour-grains',
        1670437,
      ),
      (
        'tea-250g',
        'Black tea',
        'Loose leaf tea',
        '250 g box',
        'tea-coffee',
        1800620,
      ),
      (
        'sugar-1kg',
        'White sugar',
        'Granulated sugar',
        '1 kg pouch',
        'salt-spices',
        1649924,
      ),
      (
        'lentils-500g',
        'Red lentils',
        'Split red lentils',
        '500 g pouch',
        'flour-grains',
        1792294,
      ),
      (
        'soap-100g',
        'Bath soap',
        'Wrapped soap bar',
        '100 g bar',
        'personal-care',
        1471018,
      ),
    ])
      WorkspaceCatalogueItem(
        id: 'evaluation-${row.$1}',
        canonicalId: 'evaluation-${row.$1}',
        categoryId: row.$5,
        brand: 'Evaluation',
        title: row.$2,
        variant: row.$3,
        pack: row.$4,
        sku: 'EVAL-${row.$1.toUpperCase()}',
        barcode: '',
        purchasePrice: 0,
        sellingPrice: 0,
        unitPrice: '',
        stock: 0,
        deliveryPromise: 'Store pickup',
        origin: '',
        visualLabel: '${row.$2} ${row.$4}',
        visualKind: 'catalogue-packshot',
        publicListing: false,
        cataloguePhoto: WorkspaceCataloguePhoto(
          assetId: 'evaluation-${row.$1}',
          revision: '20260924-v1',
          source: 'https://store-entry-evaluation.invalid/v1/${row.$1}.png',
          publisherWorkspaceId: 'evaluation-catalogue',
          canonicalId: 'evaluation-${row.$1}',
          brand: 'Evaluation',
          variant: row.$3,
          pack: row.$4,
          barcode: '',
          file: BuyV2MediaFileMetadata(
            mimeType: 'image/png',
            byteLength: row.$6,
            width: 1254,
            height: 1254,
            normalized: true,
            frameCount: 1,
          ),
          status: WorkspaceCataloguePhotoStatus.testOnly,
        ),
      ),
  ],
);

/// Exact bundled test-media adapter. Never fallback to another SKU or URL.
/// The .invalid source is an identifier, not a public endpoint or upload result.
String? storeEntryEvaluationPhotoAsset(WorkspaceCatalogueItem product) {
  if (!SecureWorkReviewStoreSelectionStore.enabled) return null;
  final photo = product.cataloguePhoto;
  if (photo == null ||
      !photo.matches(product) ||
      photo.status != WorkspaceCataloguePhotoStatus.testOnly) {
    return null;
  }
  for (final reference in storeEntryEvaluationCatalogue) {
    if (reference.canonicalId == product.canonicalId &&
        jsonEncode(reference.cataloguePhoto!.toJson()) ==
            jsonEncode(photo.toJson())) {
      return 'assets/store_evaluation_v1/${reference.id.substring('evaluation-'.length)}.png';
    }
  }
  return null;
}

class StoreReviewSeed {
  StoreReviewSeed({
    required this.accountScope,
    required this.orderCount,
    required DateTime now,
  }) : now = now.toUtc() {
    if (accountScope.trim().isEmpty ||
        !{0, 12, 100, 1000}.contains(orderCount)) {
      throw ArgumentError('Unsupported Store review scenario');
    }
  }

  static const version = 1;
  final String accountScope;
  final int orderCount;
  final DateTime now;
  String get storeId =>
      'QA-STORE-V1-$orderCount-'
      '${crypto.sha256.convert(utf8.encode(accountScope)).toString().substring(0, 16)}';
  String get label => orderCount == 0
      ? 'TEST Store · product entry'
      : 'TEST Store · $orderCount orders';
  WorkWorkspace get workspace => WorkWorkspace(
    id: storeId,
    name: label,
    profileLabel: 'Grocery / Kirana Shop',
    profileId: 'retailer-grocery',
    area: orderCount == 0 ? 'Frontend evaluation only' : 'Synthetic test data',
    verified: true,
  );

  late final List<WorkspaceCatalogueItem> products = List.unmodifiable([
    for (final product in workspaceMasterCatalogue.take(
      orderCount == 0 ? 0 : 6,
    ))
      product.copyWith(stock: 10000, available: true, publicListing: true),
  ]);

  late final List<WorkspaceOrderRecord> orders = List.unmodifiable([
    for (var i = 0; i < orderCount; i++) _order(i),
  ]);

  WorkspaceOrderRecord _order(int i) {
    final product = products[i % products.length];
    final quantity = 1 + i % 3;
    final stage = const [
      'Confirmed',
      'Preparing',
      'Ready',
      'Delivery requested',
    ][i % 4];
    return WorkspaceOrderRecord(
      id: 'QA-ORDER-${i.toString().padLeft(4, '0')}',
      customer: 'Test customer ${i + 1}',
      items: '${product.title} × $quantity',
      quantities: Map.unmodifiable({product.id: quantity}),
      amount: product.sellingPrice * quantity,
      source: 'App',
      fulfilment: 'Mool delivery',
      payment: i % 3 == 0 ? 'Payment due' : 'Paid online',
      address: 'Test address ${i + 1}, QA locality',
      stage: stage,
      needsDelivery: true,
      createdAt: now.subtract(Duration(seconds: i)),
      actionDeadline: stage == 'Confirmed'
          ? now.add(const Duration(seconds: 60))
          : null,
      fulfilmentDeadline: now.add(const Duration(minutes: 10)),
      stockReserved: stage != 'Confirmed',
      itemSnapshots: List.unmodifiable([
        WorkspaceOrderItemSnapshot(
          productId: product.id,
          name: product.title,
          pack: product.pack,
          quantity: quantity,
          unitPricePaise: product.sellingPrice * 100,
          lineTotalPaise: product.sellingPrice * quantity * 100,
        ),
      ]),
    );
  }

  WorkspaceFinanceSnapshot get finance => WorkspaceFinanceSnapshot(
    accountScope: accountScope,
    workspaceId: storeId,
    revision: 1,
    asOf: now,
    // Large-ledger totals intentionally exceed the visible payment sample.
    salesTodayMinor: orderCount == 1000
        ? 1000000000000
        : orders.fold<int>(0, (total, order) => total + order.amount * 100),
    duesMinor: [
      for (var i = 0; i < orders.length; i += 3) orders[i],
    ].fold<int>(0, (total, order) => total + order.amount * 100),
    availableMinor: orderCount == 0
        ? 0
        : (orderCount == 1000 ? 100000000000 : 250000),
    heldMinor: orderCount == 0 ? 0 : 125000,
    requestedMinor: 0,
    paidOutMinor: orderCount == 0 ? 0 : 450000,
    feesMinor: orderCount == 0 ? 0 : 1200,
    deliveryAdjustmentsMinor: orderCount == 0 ? 0 : -300,
    refundsMinor: 0,
    taxWithheldMinor: 0,
    payments: [
      for (var i = 0; i < orders.length; i++)
        WorkspacePaymentRecord(
          orderId: orders[i].id,
          customerId: 'QA-CUSTOMER-$i',
          customerName: orders[i].customer,
          revision: 1,
          updatedAt: now,
          amountMinor: orders[i].amount * 100,
          paidMinor: i % 3 == 0 ? 0 : orders[i].amount * 100,
          dueMinor: i % 3 == 0 ? orders[i].amount * 100 : 0,
          refundedMinor: 0,
          state: i % 3 == 0
              ? WorkspacePaymentState.unpaid
              : WorkspacePaymentState.paid,
          channel: i % 3 == 0
              ? WorkspacePaymentChannel.credit
              : WorkspacePaymentChannel.platform,
          invoiceId: 'QA-INVOICE-$i',
        ),
    ],
    customerLedgers: [
      // Explicit synthetic history for existing test customers. It does not
      // derive production transaction history from payment status.
      for (var i = 0; i < (orderCount == 0 ? 0 : 3); i++)
        WorkspaceCustomerLedger(
          accountScope: accountScope,
          workspaceId: storeId,
          customerId: 'QA-CUSTOMER-$i',
          customerName: orders[i].customer,
          revision: 1,
          asOf: now,
          openingBalanceMinor: 0,
          historyComplete: true,
          entries: [
            WorkspaceCustomerLedgerEntry(
              id: 'QA-LEDGER-INVOICE-$i',
              operationId: 'QA-INVOICE-OP-$i',
              invoiceId: 'QA-INVOICE-$i',
              orderId: orders[i].id,
              sequence: 1,
              occurredAt: orders[i].createdAt,
              kind: WorkspaceLedgerEntryKind.invoice,
              state: WorkspaceLedgerPostingState.posted,
              amountMinor: orders[i].amount * 100,
            ),
            if (i % 3 != 0)
              WorkspaceCustomerLedgerEntry(
                id: 'QA-LEDGER-PAYMENT-$i',
                operationId: 'QA-PAYMENT-OP-$i',
                invoiceId: 'QA-INVOICE-$i',
                orderId: orders[i].id,
                sequence: 2,
                occurredAt: now,
                kind: WorkspaceLedgerEntryKind.collection,
                state: WorkspaceLedgerPostingState.posted,
                amountMinor: orders[i].amount * 100,
              ),
          ],
        ),
    ],
    payouts: const [],
    historyComplete: orderCount == 0,
  );

  List<WorkspacePurchaseRecord> get purchases => List.unmodifiable([
    for (
      var i = 0;
      i < (orderCount == 0 ? 0 : WorkspaceSupplyStage.values.length);
      i++
    )
      WorkspacePurchaseRecord(
        accountScope: accountScope,
        workspaceId: storeId,
        supplierId: 'QA-SUPPLIER-${i % 3}',
        supplierName: 'Test ${WorkspaceStockSupplierType.values[i % 3].label}',
        orderId: 'QA-PURCHASE-$i',
        shipmentId: 'QA-SHIPMENT-$i',
        revision: 1,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now,
        stage: WorkspaceSupplyStage.values[i],
        amountMinor: products.first.purchasePrice * 20 * 100,
        itemSummary: '${products.first.title} × 20',
        paymentLabel: i.isEven ? 'Paid to supplier' : 'Payment pending',
        expectedArrival: 'Test estimate · today',
        address: 'QA receiving counter',
        trackingReference: 'QA-TRACK-$i',
        lines: [
          WorkspacePurchaseLine(
            id: 'QA-LINE-$i',
            productId: products.first.id,
            name: products.first.title,
            pack: products.first.pack,
            orderedPacks: 20,
            unitPriceMinor: products.first.purchasePrice * 100,
          ),
        ],
      ),
  ]);

  /// Explicit synthetic invoice/payment facts for the existing review Store.
  /// No production shipment status is converted into financial authority.
  List<WorkspaceSupplierLedger> get supplierLedgers => List.unmodifiable([
    for (var supplier = 0; supplier < (orderCount == 0 ? 0 : 3); supplier++)
      WorkspaceSupplierLedger(
        accountScope: accountScope,
        workspaceId: storeId,
        supplierId: 'QA-SUPPLIER-$supplier',
        supplierName:
            'Test ${WorkspaceStockSupplierType.values[supplier].label}',
        revision: 1,
        asOf: now,
        historyComplete: true,
        openingBalanceMinor: 0,
        entries: [
          for (var i = 0; i < WorkspaceSupplyStage.values.length; i++)
            if (i % 3 == supplier) ...[
              WorkspaceSupplierLedgerEntry(
                operationId: 'QA-SUPPLIER-BILL-$i',
                orderId: 'QA-PURCHASE-$i',
                billId: 'QA-BILL-$i',
                reference: 'QA-BILL-$i',
                kind: WorkspaceSupplierEntryKind.bill,
                amountMinor: products.first.purchasePrice * 20 * 100,
                postedAt: now.subtract(const Duration(days: 1)),
              ),
              WorkspaceSupplierLedgerEntry(
                operationId: 'QA-SUPPLIER-PAYMENT-$i',
                orderId: 'QA-PURCHASE-$i',
                billId: 'QA-BILL-$i',
                reference: 'QA-PAYMENT-$i',
                kind: i.isEven
                    ? WorkspaceSupplierEntryKind.payment
                    : WorkspaceSupplierEntryKind.advance,
                amountMinor:
                    products.first.purchasePrice * (i.isEven ? 20 : 5) * 100,
                postedAt: now,
              ),
            ],
        ],
      ),
  ]);

  List<WorkspaceGroupOffer> get offers => List.unmodifiable([
    for (var i = 0; i < (orderCount == 0 ? 0 : 3); i++)
      WorkspaceGroupOffer(
        accountScope: accountScope,
        workspaceId: storeId,
        supplierId: 'QA-SUPPLIER-$i',
        supplierName: 'Test ${WorkspaceStockSupplierType.values[i].label}',
        supplierType: WorkspaceStockSupplierType.values[i],
        productId: products[i].id,
        revision: 1,
        updatedAt: now,
        closingAt: now.add(const Duration(days: 1)),
        stage: WorkspaceGroupOfferStage.collecting,
        publicationConfirmed: true,
        details: WorkspaceGroupBuy(
          id: 'QA-OFFER-$i',
          productName: products[i].title,
          specification: products[i].pack,
          leadRetailer: 'Test group organiser',
          confirmedRetailers: const ['Test participating store'],
          targetQuantity: 1000,
          securedQuantity: 300 + i * 100,
          unitLabel: 'packs',
          regularUnitPrice: 100,
          groupUnitPrice: 80,
          facilitationFee: 100,
          deliveryFee: 200,
          confirmationAmount: 0,
          closingLabel: 'Test offer · closes tomorrow',
          storeDeliveryLabel: 'Test delivery · after offer closes',
          paymentConfirmed: false,
        ),
        participation: const WorkspaceGroupParticipation(
          state: WorkspaceGroupParticipationState.notJoined,
        ),
        note: 'Simulated offer. No purchase or payment will be made.',
      ),
  ]);
}

/// In-memory response simulator. It proves UI handling, never backend security.
/// A lost reply retains one result for reconciliation without replaying effects.
enum StoreReviewOrderResponse { applied, rejected, lostReply }

/// Synthetic receiving adapter for the existing labelled Store. No network,
/// financial posting or production approval is performed by this adapter.
class StoreReviewSupplierPaymentGateway {
  const StoreReviewSupplierPaymentGateway();

  WorkspaceSupplierLedger? record({
    required WorkspaceSupplierLedger ledger,
    required WorkspacePurchaseRecord purchase,
    required String operationId,
    required String reference,
    required String paymentMethod,
    required int amountMinor,
    required int expectedRevision,
  }) {
    if (!ledger.valid ||
        !purchase.valid ||
        !ledger.historyComplete ||
        ledger.accountScope != purchase.accountScope ||
        ledger.workspaceId != purchase.workspaceId ||
        ledger.supplierId != purchase.supplierId ||
        operationId.trim().isEmpty ||
        reference.trim().isEmpty ||
        paymentMethod.trim().isEmpty ||
        amountMinor <= 0 ||
        expectedRevision <= 0 ||
        expectedRevision > ledger.revision) {
      return null;
    }
    final existing = ledger.entries.where(
      (entry) => entry.operationId == operationId,
    );
    if (existing.isNotEmpty) {
      final entry = existing.single;
      return entry.orderId == purchase.orderId &&
              entry.kind == WorkspaceSupplierEntryKind.payment &&
              entry.reference == reference &&
              entry.paymentMethod == paymentMethod &&
              entry.amountMinor == amountMinor
          ? ledger
          : null;
    }
    if (expectedRevision != ledger.revision) {
      return null;
    }
    final entries = ledger.entries
        .where((entry) => entry.orderId == purchase.orderId)
        .toList();
    final bills = entries
        .where((entry) => entry.kind == WorkspaceSupplierEntryKind.bill)
        .toList();
    // This MVP action allocates to one confirmed bill; it cannot silently spread
    // one payment across suppliers or invent a bill from a purchase order.
    if (bills.length != 1) {
      return null;
    }
    final balance = entries.fold<int>(
      0,
      (sum, entry) => sum + entry.payableDeltaMinor,
    );
    if (amountMinor > balance) {
      return null;
    }
    return ledger.appendConfirmed(
      WorkspaceSupplierLedgerEntry(
        operationId: operationId,
        orderId: purchase.orderId,
        billId: bills.single.billId,
        reference: reference,
        paymentMethod: paymentMethod,
        kind: WorkspaceSupplierEntryKind.payment,
        amountMinor: amountMinor,
        postedAt: DateTime.now().toUtc(),
      ),
      expectedRevision: expectedRevision,
    );
  }
}

class StoreReviewReceiptGateway {
  const StoreReviewReceiptGateway(this.seed);
  final StoreReviewSeed seed;

  WorkspaceSupplierReturnConfirmation? confirmReturn(
    WorkspacePurchaseRecord purchase,
    WorkspaceReceiptDraft draft,
  ) {
    // Reuse exact seeded identity/pack checks; issue notes do not themselves
    // authorize a refund or determine the quantity physically returned.
    if (confirm(
          purchase,
          draft.edit(
            revision: draft.revision,
            countedPacks: draft.countedPacks,
            problems: const {},
            note: draft.note,
          ),
        ) ==
        null) {
      return null;
    }
    final counts = <String, int>{};
    for (final entry in draft.returnedPacks.entries) {
      final text = entry.value.trim();
      if (text.isEmpty) {
        continue;
      }
      if (!RegExp(r'^\d+$').hasMatch(text)) {
        return null;
      }
      final count = int.tryParse(text);
      if (count == null || count < 0) {
        return null;
      }
      counts[entry.key] = count;
    }
    if (counts.isEmpty || !counts.values.any((count) => count > 0)) {
      return null;
    }
    return WorkspaceSupplierReturnConfirmation(
      accountScope: purchase.accountScope,
      workspaceId: purchase.workspaceId,
      supplierId: purchase.supplierId,
      orderId: purchase.orderId,
      shipmentId: purchase.shipmentId,
      reference: 'TEST-RETURN-${purchase.shipmentId}-${draft.revision}',
      revision: draft.revision,
      confirmedAt: DateTime.now().toUtc(),
      returnedPacks: counts,
    );
  }

  WorkspacePurchaseRecord? confirm(
    WorkspacePurchaseRecord purchase,
    WorkspaceReceiptDraft draft,
  ) {
    final originals = seed.purchases.where(
      (item) => item.shipmentId == purchase.shipmentId,
    );
    if (originals.length != 1 ||
        !purchase.valid ||
        !draft.quantitiesComplete ||
        !draft.belongsTo(purchase) ||
        draft.problems.isNotEmpty ||
        purchase.accountScope != seed.accountScope ||
        purchase.workspaceId != seed.storeId) {
      return null;
    }
    final original = originals.single;
    if (purchase.supplierId != original.supplierId ||
        purchase.orderId != original.orderId ||
        draft.lines.length != original.lines.length ||
        purchase.lines.length != original.lines.length) {
      return null;
    }
    for (final line in original.lines) {
      final observed = draft.lines.where((item) => item.id == line.id);
      final current = purchase.lines.where((item) => item.id == line.id);
      bool same(WorkspacePurchaseLine item) =>
          item.productId == line.productId &&
          item.pack == line.pack &&
          item.orderedPacks == line.orderedPacks &&
          item.unitPriceMinor == line.unitPriceMinor;
      final count = draft.counted(line.id);
      if (observed.length != 1 ||
          current.length != 1 ||
          !same(observed.single) ||
          !same(current.single) ||
          count == null ||
          count > line.orderedPacks) {
        return null;
      }
    }
    final revision = purchase.revision > draft.revision
        ? purchase.revision + 1
        : draft.revision + 1;
    return WorkspacePurchaseRecord(
      accountScope: purchase.accountScope,
      workspaceId: purchase.workspaceId,
      supplierId: purchase.supplierId,
      supplierName: purchase.supplierName,
      orderId: purchase.orderId,
      shipmentId: purchase.shipmentId,
      purchaseId: purchase.purchaseId,
      procurementContext: purchase.procurementContext,
      revision: revision,
      createdAt: purchase.createdAt,
      updatedAt: DateTime.now().toUtc(),
      stage: purchase.stage,
      amountMinor: purchase.amountMinor,
      itemSummary: purchase.itemSummary,
      paymentLabel: purchase.paymentLabel,
      paymentTermLabel: purchase.paymentTermLabel,
      balanceDueLabel: purchase.balanceDueLabel,
      paymentMethod: purchase.paymentMethod,
      purchaseOrderReference: purchase.purchaseOrderReference,
      expectedArrival: purchase.expectedArrival,
      address: purchase.address,
      deliveryPartner: purchase.deliveryPartner,
      trackingReference: purchase.trackingReference,
      invoiceReference: purchase.invoiceReference,
      receiptState:
          original.lines.every(
            (line) => draft.counted(line.id) == line.orderedPacks,
          )
          ? WorkspaceReceiptState.confirmed
          : WorkspaceReceiptState.partial,
      receiptReference: 'TEST-${purchase.shipmentId}-${draft.revision}',
      updateNote: 'Test receipt only. No supplier message or payment.',
      lines: [
        for (final line in purchase.lines)
          WorkspacePurchaseLine(
            id: line.id,
            productId: line.productId,
            name: line.name,
            pack: line.pack,
            orderedPacks: line.orderedPacks,
            unitPriceMinor: line.unitPriceMinor,
            receivedPacks: draft.counted(line.id),
          ),
      ],
    );
  }
}

class StoreReviewOrderGateway implements WorkOrderTimeCommandGateway {
  StoreReviewOrderGateway(this.seed) {
    for (final order in seed.orders) {
      _orders[order.id] = WorkOrderReply(
        accountScope: seed.accountScope,
        workspaceId: seed.storeId,
        orderId: order.id,
        operationId: 'QA-SEED-${order.id}',
        revision: 1,
        state: WorkOrderReplyState.applied,
        order: order,
      );
    }
  }
  final StoreReviewSeed seed;
  final _orders = <String, WorkOrderReply>{};
  final _results = <String, WorkOrderReply>{};
  final _commands = <String, WorkOrderCommand>{};
  StoreReviewOrderResponse nextResponse = StoreReviewOrderResponse.applied;
  List<WorkOrderReply> get snapshots => List.unmodifiable(_orders.values);
  @override
  bool get supportsOrderTimeRequests => true;

  void _checkScope(WorkOrderCommand command) {
    if (command.accountScope != seed.accountScope ||
        command.workspaceId != seed.storeId ||
        !_orders.containsKey(command.orderId) ||
        !SecureWorkOrderPendingStore._valid(command)) {
      throw StateError('Invalid synthetic order command');
    }
    final previous = _commands[command.operationId];
    if (previous != null &&
        (previous.orderId != command.orderId ||
            previous.action != command.action ||
            previous.expectedRevision != command.expectedRevision ||
            previous.reason != command.reason ||
            previous.additionalMinutes != command.additionalMinutes ||
            previous.expectedAcceptanceDeadline !=
                command.expectedAcceptanceDeadline)) {
      throw StateError('Synthetic operation identity changed');
    }
  }

  @override
  Future<WorkOrderReply> submitOrderCommand(WorkOrderCommand command) async {
    _checkScope(command);
    final previous = _results[command.operationId];
    if (previous != null) return previous;
    final mode = nextResponse;
    nextResponse = StoreReviewOrderResponse.applied;
    final snapshot = _orders[command.orderId]!;
    var order = snapshot.order!;
    final legalStage = switch (command.action) {
      WorkOrderAction.accept ||
      WorkOrderAction.reject ||
      WorkOrderAction.requestTime => order.stage == 'Confirmed',
      WorkOrderAction.ready => order.stage == 'Preparing',
    };
    final rejected =
        mode == StoreReviewOrderResponse.rejected ||
        snapshot.revision != command.expectedRevision ||
        !legalStage ||
        order.isCustomerCollection ||
        (command.action == WorkOrderAction.requestTime &&
            command.expectedAcceptanceDeadline != order.actionDeadline) ||
        (order.stage == 'Confirmed' &&
            order.actionDeadline?.isAfter(DateTime.now()) != true);
    if (!rejected) {
      order = switch (command.action) {
        WorkOrderAction.accept => order.copyWith(
          stage: 'Preparing',
          clearActionDeadline: true,
          stockReserved: true,
        ),
        WorkOrderAction.ready => order.copyWith(stage: 'Ready'),
        WorkOrderAction.reject => order.copyWith(
          stage: 'Cancelled',
          rejectionReason: command.reason,
          clearActionDeadline: true,
        ),
        WorkOrderAction.requestTime => order.copyWith(
          actionDeadline: order.actionDeadline!.add(
            Duration(minutes: command.additionalMinutes!),
          ),
          extraMinutes: order.extraMinutes + command.additionalMinutes!,
        ),
      };
    }
    final result = WorkOrderReply(
      accountScope: seed.accountScope,
      workspaceId: seed.storeId,
      orderId: command.orderId,
      operationId: command.operationId,
      revision: snapshot.revision + 1,
      state: rejected
          ? WorkOrderReplyState.rejected
          : WorkOrderReplyState.applied,
      order: order,
    );
    _results[command.operationId] = result;
    _commands[command.operationId] = command;
    _orders[command.orderId] = result;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (mode == StoreReviewOrderResponse.lostReply) {
      throw TimeoutException(
        'Simulated lost response; reconcile the operation',
      );
    }
    return result;
  }

  @override
  Future<WorkOrderReply> reconcileOrderCommand(WorkOrderCommand command) async {
    _checkScope(command);
    final result = _results[command.operationId];
    if (result == null || result.orderId != command.orderId) {
      throw StateError('Synthetic operation is not known');
    }
    return result;
  }
}

class ReviewWorkGateway implements WorkGateway {
  ReviewWorkGateway({WorkRemoteReviewStatus? initialReviewStatus})
    : reviewResultStatus =
          initialReviewStatus ??
          (kDebugMode &&
                  const bool.fromEnvironment('MOOLSOCIAL_DEVICE_REVIEW') &&
                  const bool.fromEnvironment('MOOLSOCIAL_UI_REVIEW_ONLY')
              ? WorkRemoteReviewStatus.pending
              : WorkRemoteReviewStatus.approved);

  bool failFeed = false;
  bool failApplication = false;
  bool failWithdrawal = false;
  bool failOtp = false;
  bool failProof = false;
  bool failSubmission = false;
  bool failReview = false;
  WorkRemoteReviewStatus reviewResultStatus;
  final Map<String, String> _reviewWorkspaceIds = {};
  final Set<String> _submittedReviewCases = {};
  final Map<String, WorkReviewTestCase> _selectedReviewCases = {};
  late final String _deviceReviewIdentity =
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-'
      '${Random.secure().nextInt(1 << 32).toRadixString(36)}';

  bool get deviceReviewControlsEnabled =>
      kDebugMode &&
      const bool.fromEnvironment('MOOLSOCIAL_DEVICE_REVIEW') &&
      const bool.fromEnvironment('MOOLSOCIAL_UI_REVIEW_ONLY');

  bool canSelectDeviceReviewCase(String caseId) =>
      deviceReviewControlsEnabled && _submittedReviewCases.contains(caseId);

  /// Restore only the test selector, never an approval or Workspace authority.
  bool restoreDeviceReviewCase(String caseId, {required String accountScope}) {
    if (!deviceReviewControlsEnabled ||
        accountScope != 'isolated-workspace-ui-review' ||
        !RegExp(r'^WP-[a-z0-9]+-[a-z0-9]+-[1-9][0-9]*$').hasMatch(caseId)) {
      return false;
    }
    _submittedReviewCases.add(caseId);
    return true;
  }

  void selectDeviceReviewCase(String caseId, WorkReviewTestCase scenario) {
    if (!canSelectDeviceReviewCase(caseId)) {
      throw const WorkGatewayException('Review test cases are unavailable.');
    }
    _selectedReviewCases[caseId] = scenario;
  }

  String? reviewResultReason;
  bool failGst = false;
  bool failSetup = false;
  int applicationCalls = 0;
  int withdrawalCalls = 0;
  int otpCalls = 0;
  int otpVerificationCalls = 0;
  WorkContactChannel? lastOtpChannel;
  String? lastOtpValue;
  WorkProfileSubmission? lastSubmission;
  int proofCalls = 0;
  int submissionCalls = 0;
  int correctionCalls = 0;
  int reviewCalls = 0;
  int gstCalls = 0;
  int setupCalls = 0;
  int operationalSaveCalls = 0;
  int groupBuyCalls = 0;
  int paidRequirementCalls = 0;
  int settlementCalls = 0;
  int handoverCalls = 0;
  int deliveryAssignmentCalls = 0;
  WorkOperationalSnapshot? lastOperationalSnapshot;
  WorkGroupBuySubmission? lastGroupBuySubmission;
  WorkPaidRequirementSubmission? lastPaidRequirementSubmission;
  Future<void> _wait() =>
      Future<void>.delayed(const Duration(milliseconds: 24));
  @override
  Future<List<WorkReviewResult>> loadFeed() async {
    await _wait();
    if (failFeed) {
      failFeed = false;
      throw const WorkGatewayException(
        'Work could not be refreshed. Check your connection and try again.',
      );
    }
    return const [];
  }

  @override
  Future<String> apply(String opportunityId) async {
    applicationCalls++;
    await _wait();
    if (failApplication) {
      failApplication = false;
      throw const WorkGatewayException(
        'Application was not sent. Your opportunity is still saved.',
      );
    }
    return 'APP-${opportunityId.toUpperCase()}-${1200 + applicationCalls}';
  }

  @override
  Future<void> withdraw(String applicationId, String opportunityId) async {
    withdrawalCalls++;
    await _wait();
    if (failWithdrawal) {
      failWithdrawal = false;
      throw const WorkGatewayException(
        'Application could not be withdrawn. It remains active; try again.',
        retryable: true,
      );
    }
  }

  @override
  Future<void> sendContactOtp({
    required WorkContactChannel channel,
    required String value,
  }) async {
    otpCalls++;
    lastOtpChannel = channel;
    lastOtpValue = value;
    await _wait();
    if (failOtp) {
      failOtp = false;
      throw const WorkGatewayException(
        'OTP could not be sent. Check the number and try again.',
      );
    }
  }

  @override
  Future<void> verifyContactOtp({
    required WorkContactChannel channel,
    required String value,
    required String code,
  }) async {
    otpVerificationCalls++;
    lastOtpChannel = channel;
    lastOtpValue = value;
    await _wait();
    if (code != '123456') {
      throw const WorkGatewayException('That code does not match. Try again.');
    }
  }

  @override
  Future<String> saveProof(String proofId, WorkPickedProof proof) async {
    proofCalls++;
    await _wait();
    if (failProof) {
      failProof = false;
      throw const WorkGatewayException(
        'Document not added. Choose the same file or another option and try again.',
      );
    }
    return 'PROOF-${proofId.toUpperCase()}-$proofCalls';
  }

  @override
  Future<WorkReviewResult> submitProfile(WorkProfileSubmission value) async {
    submissionCalls++;
    lastSubmission = value;
    await _wait();
    if (failSubmission) {
      failSubmission = false;
      throw const WorkGatewayException(
        'Workspace profile was not submitted. Your details and documents remain saved.',
      );
    }
    final caseId = deviceReviewControlsEnabled
        ? 'WP-$_deviceReviewIdentity-$submissionCalls'
        : 'WP-${240700 + submissionCalls}';
    _submittedReviewCases.add(caseId);
    return WorkReviewResult(
      caseId: caseId,
      status: WorkRemoteReviewStatus.pending,
      plan: 'free',
    );
  }

  @override
  Future<WorkReviewResult> submitCorrection(
    String caseId,
    WorkProfileSubmission value,
  ) async {
    correctionCalls++;
    lastSubmission = value;
    await _wait();
    if (failSubmission) {
      failSubmission = false;
      throw const WorkGatewayException(
        'Workspace corrections were not sent. Your changes remain saved.',
      );
    }
    _selectedReviewCases.remove(caseId);
    return WorkReviewResult(
      caseId: caseId,
      status: WorkRemoteReviewStatus.pending,
      plan: 'free',
    );
  }

  @override
  Future<WorkReviewResult> checkReview(String caseId) async {
    reviewCalls++;
    await _wait();
    if (failReview) {
      failReview = false;
      throw const WorkGatewayException(
        'Review update is unavailable. No duplicate request was created.',
      );
    }
    final scenario = deviceReviewControlsEnabled
        ? _selectedReviewCases[caseId]
        : null;
    final status = switch (scenario) {
      WorkReviewTestCase.pending ||
      WorkReviewTestCase.clarification => WorkRemoteReviewStatus.pending,
      WorkReviewTestCase.rejected => WorkRemoteReviewStatus.rejected,
      WorkReviewTestCase.approved => WorkRemoteReviewStatus.approved,
      null => reviewResultStatus,
    };
    final reason = switch (scenario) {
      WorkReviewTestCase.clarification =>
        'Please add a readable shop address document and check the business name.',
      WorkReviewTestCase.rejected =>
        'The submitted business details could not be verified. Contact MoolSocial for help.',
      WorkReviewTestCase.pending || WorkReviewTestCase.approved => null,
      null => reviewResultReason,
    };
    return WorkReviewResult(
      caseId: caseId,
      status: status,
      reason: reason,
      plan: 'free',
      workspaceId:
          status == WorkRemoteReviewStatus.approved ||
              status == WorkRemoteReviewStatus.live
          ? _reviewWorkspaceIds.putIfAbsent(
              caseId,
              () => deviceReviewControlsEnabled
                  ? 'WK-$_deviceReviewIdentity-${_reviewWorkspaceIds.length + 1}'
                  : 'WK-${510001 + _reviewWorkspaceIds.length}',
            )
          : null,
    );
  }

  @override
  Future<String> submitGst(
    String caseId,
    String gstin,
    String proofReference,
  ) async {
    gstCalls++;
    await _wait();
    if (failGst) {
      failGst = false;
      throw const WorkGatewayException(
        'GST certificate was not submitted. Your Workspace review is still active.',
      );
    }
    return 'GST-$gstCalls';
  }

  @override
  Future<void> finishSetup({
    required String workspaceId,
    required int quantity,
    required int buyPrice,
    required int sellPrice,
    required bool homeDelivery,
    required bool storeCollection,
  }) async {
    setupCalls++;
    await _wait();
    if (failSetup) {
      failSetup = false;
      throw const WorkGatewayException(
        'Shop setup was not completed. Product and fulfilment choices remain saved.',
      );
    }
  }

  @override
  Future<void> saveOperationalState(WorkOperationalSnapshot snapshot) async {
    operationalSaveCalls++;
    lastOperationalSnapshot = snapshot;
    await _wait();
  }

  @override
  Future<String> createGroupBuy(WorkGroupBuySubmission submission) async {
    groupBuyCalls++;
    lastGroupBuySubmission = submission;
    await _wait();
    return 'PAY-GROUP-${1200 + groupBuyCalls}';
  }

  @override
  Future<String> createPaidRequirement(
    WorkPaidRequirementSubmission submission,
  ) async {
    paidRequirementCalls++;
    lastPaidRequirementSubmission = submission;
    await _wait();
    return 'WORK-REQ-${1200 + paidRequirementCalls}';
  }

  @override
  Future<WorkSettlementResult> requestSettlement({
    required String workspaceId,
    required int amount,
    required String idempotencyKey,
  }) async {
    settlementCalls++;
    await _wait();
    return WorkSettlementResult(
      reference: 'SET-${1200 + settlementCalls}',
      acceptedAmount: amount,
    );
  }

  @override
  Future<void> verifyOrderHandover({
    required String workspaceId,
    required String orderId,
    required String otp,
    required String idempotencyKey,
  }) async {
    handoverCalls++;
    await _wait();
    if (otp != '123456') {
      throw const WorkGatewayException(
        'Enter the 6-digit delivery OTP shared by the customer.',
      );
    }
  }

  @override
  Future<WorkDeliveryAssignmentResult> requestDeliveryAssignment({
    required String workspaceId,
    required String orderId,
    required String address,
    required String idempotencyKey,
  }) async {
    deliveryAssignmentCalls++;
    await _wait();
    return WorkDeliveryAssignmentResult(
      partnerName: 'Review delivery partner',
      vehicleLabel: 'Review vehicle',
      eta: DateTime.now().add(const Duration(minutes: 15)),
      stage: 'Assigned',
    );
  }
}

WorkPickedProof _validateProof(String fileName, Uint8List bytes) {
  final extension = fileName.split('.').last.toLowerCase();
  final contentType = switch (extension) {
    'pdf' => 'application/pdf',
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => throw const WorkGatewayException(
      'Choose a PDF, JPG, PNG or WebP document.',
    ),
  };
  if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
    throw const WorkGatewayException('Choose a document up to 10 MB.');
  }
  // Match the existing local preview boundary before replacing an attachment.
  // A signature is not proof of readability or server-side document validity.
  if (contentType == 'application/pdf' &&
      (bytes.length < 5 || String.fromCharCodes(bytes.take(5)) != '%PDF-')) {
    throw const WorkGatewayException(
      'This PDF could not be opened. Choose another copy.',
    );
  }
  return WorkPickedProof(
    fileName: fileName,
    contentType: contentType,
    bytes: bytes,
  );
}

Map<String, Object?> _map(Object? value) {
  if (value is! Map) {
    throw const WorkGatewayException(
      'Workspace returned an invalid response. Try again.',
      retryable: true,
    );
  }
  return value.map((key, item) => MapEntry(key.toString(), item));
}

String _requiredString(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    throw const WorkGatewayException(
      'Workspace returned an invalid response. Try again.',
      retryable: true,
    );
  }
  return value.trim();
}

WorkReviewResult _decodeReview(Map<String, Object?> data) => WorkReviewResult(
  caseId: _requiredString(data['caseId']),
  status: switch (_requiredString(data['status'])) {
    'approved' => WorkRemoteReviewStatus.approved,
    'rejected' => WorkRemoteReviewStatus.rejected,
    'suspended' => WorkRemoteReviewStatus.suspended,
    'live' => WorkRemoteReviewStatus.live,
    _ => WorkRemoteReviewStatus.pending,
  },
  plan: _requiredString(data['plan']),
  workspaceId: data['workspaceId'] is String
      ? _requiredString(data['workspaceId'])
      : null,
  reason: data['reason'] is String ? _requiredString(data['reason']) : null,
  profileId: data['profileId'] is String
      ? _requiredString(data['profileId'])
      : null,
  name: data['name'] is String ? _requiredString(data['name']) : null,
  area: data['area'] is String ? _requiredString(data['area']) : null,
  primaryActivity: data['primaryActivity'] is String
      ? _requiredString(data['primaryActivity'])
      : null,
);
