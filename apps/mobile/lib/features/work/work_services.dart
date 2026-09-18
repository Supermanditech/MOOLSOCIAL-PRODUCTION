import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../shared/social_content_gateway.dart';
import '../buy/buy_v2_models.dart';
import '../buy/buy_v2_content_contracts.dart';
import '../buy/buy_session.dart';
import '../buy/buy_v2_session.dart';
import '../buy/buy_v2_saved_products_store.dart';
import 'work_models.dart';

typedef WorkProcurementSessionFactory =
    BuyV2Session Function(
      ValueListenable<BuyV2ProcurementContext?> identity,
      BuyV2CustomerStateStore stateStore,
    );

/// Owns Store sessions, never the consumer Shop session. Purchase grants remain
/// the responsibility of the injected commerce adapter, not this controller.
class WorkProcurementController extends ChangeNotifier {
  WorkProcurementController({
    required this.currentAccountId,
    required this.currentStoreId,
    required this.storeApproved,
    this.bookmarks = const SecureWorkProcurementBookmarkStore(),
    this.reviewCatalogueAllowed,
    WorkProcurementSessionFactory? sessionFactory,
    BuyV2CustomerStateStore Function(String scope)? stateStoreFactory,
  }) : _sessionFactory = sessionFactory,
       _ownsCore = sessionFactory == null,
       _stateStoreFactory = stateStoreFactory ?? _newStateStore;

  final String? Function() currentAccountId, currentStoreId;
  final bool Function() storeApproved;
  final WorkProcurementBookmarkStore bookmarks;
  final bool Function()? reviewCatalogueAllowed;
  final WorkProcurementSessionFactory? _sessionFactory;
  final bool _ownsCore;
  final BuyV2CustomerStateStore Function(String) _stateStoreFactory;
  final _identity = ValueNotifier<BuyV2ProcurementContext?>(null);
  BuyV2Session? session;
  WorkProcurementBookmark? bookmark;
  int _epoch = 0;
  bool _disposed = false;
  Future<void> _writes = Future<void>.value();

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
    final review =
        context != null &&
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
                scopeCurrent &&
                identity.value?.customerStateOwnerScope ==
                    context.customerStateOwnerScope &&
                reviewCatalogueAllowed?.call() == true,
          )
        : null;
    return BuyV2Session(
      core: BuySession(),
      procurementIdentity: identity,
      customerStateStore: stateStore,
      reviewDataEnabled: false,
      commerceAdapter: review,
      commercialPaymentTermsAdapter: review,
      cataloguePageSource: review,
      initialCatalogueRegionId: review == null ? null : 'jodhpur',
    );
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
    if (bookmark != null && !scopeCurrent) invalidate();
  }

  void invalidate() {
    _epoch++;
    _identity.value = null;
    _disposeSession();
    bookmark = null;
    if (!_disposed) notifyListeners();
  }

  void _disposeSession() {
    final previous = session;
    session = null;
    previous?.dispose();
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
    final account = currentAccountId(), store = currentStoreId();
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
      return false;
    }
    final epoch = ++_epoch;
    bool current() =>
        !_disposed &&
        epoch == _epoch &&
        storeApproved() &&
        currentAccountId() == account &&
        currentStoreId() == store;
    WorkProcurementBookmark? previous;
    try {
      previous = await bookmarks.read(account, store);
    } on Object {
      // A failed read is not an empty cart. Preserve the saved operation.
      return false;
    }
    if (!current()) return false;
    if (restoreOnly && (previous == null || !previous.active)) return false;
    final chosen = exactContext != null
        ? WorkProcurementBookmark(context: exactContext, returnTo: returnTo)
        : previous != null &&
              (restoreOnly || previous.context.purpose == purpose)
        ? WorkProcurementBookmark(
            context: previous.context,
            returnTo: restoreOnly ? previous.returnTo : returnTo,
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
          );
    if (!await _write(() async => current() && await bookmarks.save(chosen)) ||
        !current()) {
      return false;
    }
    if (session != null &&
        scopeCurrent &&
        bookmark!.context.customerStateOwnerScope ==
            chosen.context.customerStateOwnerScope) {
      bookmark = chosen;
      notifyListeners();
      return true;
    }
    _identity.value = null;
    _disposeSession();
    bookmark = chosen;
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
    final inactive = WorkProcurementBookmark(
      context: value.context,
      returnTo: value.returnTo,
      active: false,
    );
    final saved = await _write(() => bookmarks.save(inactive));
    if (!saved || _disposed || epoch != _epoch || !scopeCurrent) return false;
    bookmark = inactive;
    return true;
  }

  @override
  void dispose() {
    _disposed = true;
    invalidate();
    _identity.dispose();
    super.dispose();
  }
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
  });
  final BuyV2ProcurementContext context;
  final String returnTo;
  final bool active;
  static const returnDestinations = {
    'dashboard',
    'stockStatement',
    'sourcing',
    'direct',
    'groupBuying',
  };

  Map<String, Object?> toJson() => {
    'version': 1,
    'active': active,
    'accountId': context.accountId,
    'storeId': context.storeId,
    'purpose': context.purpose.name,
    'originOperationId': context.originOperationId,
    'returnTo': returnTo,
  };

  static WorkProcurementBookmark? decode(
    Map<String, Object?> value, {
    required String accountId,
    required String storeId,
  }) {
    if (value['version'] != 1 ||
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
    : _contactDraft = false;
  SecureWorkPendingProofStore.contactDraft({this.reviewOnly = false})
    : _contactDraft = true;
  final bool reviewOnly;
  final bool _contactDraft;
  static const _storage = FlutterSecureStorage();
  bool get _review =>
      reviewOnly &&
      kDebugMode &&
      const bool.fromEnvironment('MOOLSOCIAL_UI_REVIEW_ONLY') &&
      const bool.fromEnvironment('MOOLSOCIAL_DEVICE_REVIEW');
  String get _key => _review
      ? 'moolsocial.workspace.pending-proof.review.v1'
      : 'moolsocial.workspace.pending-proof.v1';

  String _scopedKey(String scope) => _contactDraft
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
    final value = await _storage
        .read(key: _scopedKey(scope))
        .timeout(const Duration(seconds: 10));
    if (value == null || scope != accountScope) return null;
    final decoded = jsonDecode(value);
    if (decoded is! Map ||
        decoded['scope'] != scope ||
        decoded['draft'] is! Map) {
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

abstract interface class WorkLedgerFormDraftStore {
  Future<WorkspaceLedgerFormDraft?> read(WorkspaceLedgerFormKey key);
  Future<void> save(
    WorkspaceLedgerFormDraft draft, {
    required int? expectedRevision,
  });
}

/// Uses the existing encrypted draft storage approach; never financial authority.
class SecureWorkLedgerFormDraftStore implements WorkLedgerFormDraftStore {
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
  @override
  Future<void> save(
    WorkspaceLedgerFormDraft draft, {
    required int? expectedRevision,
  }) => _serial(_key(draft.key), () async {
    _check(draft.key);
    if (!draft.valid || draft.revision != (expectedRevision ?? 0) + 1) {
      throw const WorkGatewayException('Invoice input could not be saved.');
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
    await _storage.write(key: _key(draft.key), value: encoded);
    _check(draft.key);
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
  }) : lines = List.unmodifiable(lines);
  final String operationId;
  final WorkspaceIssueDraft draft;
  final WorkspaceIssueKind kind;
  final List<WorkspaceIssueLine> lines;
  WorkspaceIssueDraftKey get key => draft.key;
  bool get valid =>
      draft.valid &&
      draft.response != null &&
      RegExp(r'^STORE-ISSUE-[A-Za-z0-9_-]{22,64}$').hasMatch(operationId) &&
      (draft.response == WorkspaceIssueResponse.acceptRequest ||
          draft.note.trim().isNotEmpty) &&
      lines.isNotEmpty &&
      lines.every((line) => line.valid) &&
      lines.map((line) => line.lineId).toSet().length == lines.length;

  Map<String, Object?> toJson() => {
    'version': 1,
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
  };

  /// SHA-256 over UTF-8 JSON in the exact V1 field order above. Not a credential.
  String get digest =>
      crypto.sha256.convert(utf8.encode(jsonEncode(toJson()))).toString();

  static WorkIssueCommand? fromJson(Object? value) {
    if (value is! Map ||
        value['version'] != 1 ||
        value['operationId'] is! String ||
        value['lines'] is! List) {
      return null;
    }
    final draft = WorkspaceIssueDraft.fromJson(value['draft']);
    final kind = WorkspaceIssueKind.values
        .where((k) => k.name == value['kind'])
        .firstOrNull;
    if (draft == null || kind == null) return null;
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
    Future<Directory> Function()? temporaryDirectory,
  }) : _imagePicker = imagePicker ?? ImagePicker(),
       _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory;

  final ImagePicker _imagePicker;
  final Future<XFile?> Function()? documentPicker;
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
        final proof = _validateProof(selectedName ?? file.name, bytes);
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
  });

  static const contractVersion = 2;
  final String accountScope, workspaceId, orderId, operationId;
  final int expectedRevision;
  final WorkOrderAction action;
  final String? reason;
  final int version;
  final int? additionalMinutes;
  final DateTime? expectedAcceptanceDeadline;
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
  };

  static bool _valid(WorkOrderCommand command) =>
      {1, WorkOrderCommand.contractVersion}.contains(command.version) &&
      command.orderId.trim().isNotEmpty &&
      command.operationId.trim().isNotEmpty &&
      command.expectedRevision >= 0 &&
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
      reply.order!.amount >= 0 &&
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
    if (previous != null && snapshot.revision <= previous.revision) {
      return false;
    }
    _orders[snapshot.orderId] = snapshot;
    _emit(snapshot.orderId);
    return true;
  }

  bool _allowed(WorkOrderReply snapshot, WorkOrderAction action) {
    final record = snapshot.order!;
    // Readiness and handover of authenticated customer collection remain under
    // the existing collection controller, not this general-order contract.
    if (record.isCustomerCollection || record.isClosed) return false;
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
        payment.amountMinor != invoice.amount * 100) {
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
        invoice.amount <= 0) {
      throw StateError('Invoice does not identify this Store and customer.');
    }
    final previousPayment = _finance.payments
        .where((p) => p.invoiceId == invoice.id || p.orderId == invoice.orderId)
        .firstOrNull;
    if (previousPayment != null) {
      if (previousPayment.invoiceId != invoice.id ||
          previousPayment.orderId != invoice.orderId ||
          previousPayment.customerId != customerId ||
          previousPayment.amountMinor != invoice.amount * 100) {
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
    final amount = invoice.amount * 100;
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
        payment.amountMinor != originalOrder.amount * 100 ||
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

/// Versioned, synthetic projections for frontend UAT and future adapter tests.
/// Pure data only: no network, approval, payment or collection authority.
/// The runtime loader separately requires both review defines and debug mode.
class StoreReviewSeed {
  StoreReviewSeed({
    required this.accountScope,
    required this.orderCount,
    required DateTime now,
  }) : now = now.toUtc() {
    if (accountScope.trim().isEmpty || !{12, 100, 1000}.contains(orderCount)) {
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
  String get label => 'TEST Store · $orderCount orders';
  WorkWorkspace get workspace => WorkWorkspace(
    id: storeId,
    name: label,
    profileLabel: 'Grocery / Kirana Shop',
    profileId: 'retailer-grocery',
    area: 'Synthetic test data',
    verified: true,
  );

  late final List<WorkspaceCatalogueItem> products = List.unmodifiable([
    for (final product in workspaceMasterCatalogue.take(6))
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
    availableMinor: orderCount == 1000 ? 100000000000 : 250000,
    heldMinor: 125000,
    requestedMinor: 0,
    paidOutMinor: 450000,
    feesMinor: 1200,
    deliveryAdjustmentsMinor: -300,
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
      for (var i = 0; i < 3; i++)
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
    historyComplete: false,
  );

  List<WorkspacePurchaseRecord> get purchases => List.unmodifiable([
    for (var i = 0; i < WorkspaceSupplyStage.values.length; i++)
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
    for (var supplier = 0; supplier < 3; supplier++)
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
    for (var i = 0; i < 3; i++)
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
