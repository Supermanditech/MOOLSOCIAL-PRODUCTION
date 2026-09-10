import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'work_models.dart';
import 'work_services.dart';
import 'scan_and_pick_contract.dart';

/// Store packing capability, separate from the sealed consumer collection API.
/// An authenticated adapter must persist the explicit staff action against this
/// exact order/revision and register operationId in the collection reconciliation
/// ledger. Returning here is NOT readiness authority: the controller reconciles
/// the operation through ScanPickGateway before exposing a code. No default
/// implementation, endpoint or local-ready fallback is supplied.
abstract interface class StoreCollectionReadinessGateway {
  Future<void> markGoodsReady({
    required String storeId,
    required String orderId,
    required String expectedRevision,
    required String operationId,
  });
}

/// Per-order presentation controller. Only an authenticated injected adapter
/// may supply authority; no review WorkGateway or local completion fallback.
class StoreCollectionController extends ChangeNotifier {
  StoreCollectionController({
    required this.storeId,
    required this.orderId,
    required this.gateway,
    this.readinessGateway,
  });

  final String storeId, orderId;
  final ScanPickGateway gateway;
  final StoreCollectionReadinessGateway? readinessGateway;
  ScanPickResult? _result;
  ScanPickRequest? _request;
  ScanPickRequest? _uncertainMutation;
  String? _readinessRevision;
  final Stopwatch _elapsed = Stopwatch();
  Timer? _matchExpiryTimer;
  bool _matchExpired = false;
  Duration _responseAllowance = Duration.zero;
  bool busy = false;
  bool _closed = false;
  String? message;
  ScanPickSnapshot? get snapshot => _result?.snapshot;
  bool get needsReconciliation => _uncertainMutation != null;
  bool get confirmingReadiness => _readinessRevision != null;
  bool get confirmingHandover =>
      _uncertainMutation?.operation == ScanPickOperation.handOver;
  DateTime? get serverNow =>
      snapshot?.serverTime.add(_responseAllowance + _elapsed.elapsed);

  static String _id() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  bool get hasCurrentMatch =>
      !_closed &&
      !_matchExpired &&
      message == null &&
      !needsReconciliation &&
      _request != null &&
      serverNow != null &&
      (_result?.canRequestHandOver(_request!, serverNow!) ?? false);
  bool get canHandOver => !busy && hasCurrentMatch;
  bool get canMarkGoodsReady =>
      !_closed &&
      !busy &&
      !needsReconciliation &&
      message == null &&
      readinessGateway != null &&
      _result?.outcome == ScanPickOutcome.snapshot &&
      snapshot?.state == ScanPickState.preparing &&
      snapshot?.readiness == ScanPickReadiness.preparing &&
      snapshot?.payment == ScanPickPayment.paid;
  bool get actionPending => busy && needsReconciliation;
  bool get hasAuthoritativeSnapshot =>
      !needsReconciliation &&
      (_result?.outcome == ScanPickOutcome.snapshot ||
          _result?.error == ScanPickError.alreadyCollected);

  String? get visibleQr {
    final value = snapshot;
    final now = serverNow;
    if (_closed ||
        message != null ||
        needsReconciliation ||
        _result?.outcome != ScanPickOutcome.snapshot ||
        value == null ||
        now == null ||
        value.state != ScanPickState.awaitingCustomer ||
        !now.isBefore(value.challenge!.expiresAt)) {
      return null;
    }
    return value.challenge?.qrPayload;
  }

  Future<void> refresh() async {
    if (_closed || busy) return;
    final pending = _uncertainMutation;
    await _execute(
      pending == null
          ? ScanPickRequest.read(
              requestId: _id(),
              orderId: orderId,
              storeId: storeId,
            )
          : ScanPickRequest.reconcile(
              requestId: _id(),
              operationId: pending.operationId!,
              orderId: orderId,
              storeId: storeId,
            ),
    );
  }

  Future<void> showCode() async {
    final value = snapshot;
    if (_closed ||
        busy ||
        needsReconciliation ||
        message != null ||
        value == null ||
        _result?.outcome != ScanPickOutcome.snapshot ||
        value.payment != ScanPickPayment.paid ||
        value.readiness != ScanPickReadiness.ready ||
        !{
          ScanPickState.ready,
          ScanPickState.awaitingCustomer,
        }.contains(value.state)) {
      return;
    }
    await _execute(
      ScanPickRequest.issueChallenge(
        requestId: _id(),
        operationId: _id(),
        orderId: orderId,
        storeId: storeId,
        expectedRevision: value.revision,
      ),
    );
  }

  /// One deliberate retailer action after packing and bringing goods to the
  /// counter. Neither polling, item ticks, a timer nor a transport ACK calls this.
  Future<void> goodsReady() async {
    if (!canMarkGoodsReady) return;
    final revision = snapshot!.revision;
    final operationId = _id();
    _readinessRevision = revision;
    _uncertainMutation = ScanPickRequest.reconcile(
      requestId: _id(),
      operationId: operationId,
      orderId: orderId,
      storeId: storeId,
    );
    busy = true;
    message = null;
    notifyListeners();
    try {
      await readinessGateway!
          .markGoodsReady(
            storeId: storeId,
            orderId: orderId,
            expectedRevision: revision,
            operationId: operationId,
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      // A lost reply cannot establish failure or justify a new operation. Read
      // the same operation's outcome; never turn the local order ready here.
    }
    if (_closed) return;
    busy = false;
    await refresh();
  }

  Future<void> handOver() async {
    if (!canHandOver) return;
    final value = snapshot!;
    await _execute(
      ScanPickRequest.handOver(
        requestId: _id(),
        operationId: _id(),
        orderId: orderId,
        storeId: storeId,
        expectedRevision: value.revision,
        approvalId: value.approval!.id,
      ),
    );
  }

  Future<void> _execute(ScanPickRequest request) async {
    if (_closed || busy) return;
    busy = true;
    message = null;
    if (request.operation == ScanPickOperation.handOver ||
        request.operation == ScanPickOperation.issueChallenge) {
      _uncertainMutation = request;
    }
    notifyListeners();
    final roundTrip = Stopwatch()..start();
    try {
      final result = await gateway
          .execute(request)
          .timeout(const Duration(seconds: 20));
      if (_closed) return;
      result.validateFor(request, client: ScanPickClient.retailer);
      _request = request;
      _result = result;
      _responseAllowance = roundTrip.elapsed;
      _elapsed
        ..reset()
        ..start();
      _matchExpiryTimer?.cancel();
      _matchExpired = false;
      final expiry = result.snapshot?.approval?.expiresAt;
      if (expiry != null) {
        final remaining = expiry.difference(serverNow!);
        _matchExpired = remaining <= Duration.zero;
        if (!_matchExpired) {
          // Expiry can only remove the confirmed presentation/action. It never
          // advances an order, creates authority or performs a server mutation.
          _matchExpiryTimer = Timer(remaining, () {
            if (_closed) return;
            _matchExpired = true;
            notifyListeners();
          });
        }
      }
      if (result.outcome == ScanPickOutcome.unknown ||
          (confirmingReadiness &&
              result.outcome == ScanPickOutcome.snapshot &&
              (result.snapshot?.state == ScanPickState.preparing ||
                  result.snapshot?.revision == _readinessRevision)) ||
          result.error == ScanPickError.operationInProgress ||
          (request.operation == ScanPickOperation.reconcile &&
              {
                ScanPickError.unauthenticated,
                ScanPickError.forbidden,
                ScanPickError.unavailable,
                ScanPickError.rateLimited,
                ScanPickError.operationConflict,
              }.contains(result.error))) {
        message = confirmingReadiness
            ? 'Checking your update. Do not hand over yet.'
            : confirmingHandover
            ? 'Confirming collection…'
            : 'Checking your update. Do not hand over yet.';
      } else {
        _uncertainMutation = null;
        _readinessRevision = null;
        if (result.outcome == ScanPickOutcome.rejected &&
            result.error != ScanPickError.alreadyCollected) {
          message = switch (result.error) {
            ScanPickError.paymentRequired || ScanPickError.paymentChanged =>
              'Payment needs confirmation before handover.',
            ScanPickError.notReady =>
              'Finish packing before marking the order ready.',
            ScanPickError.challengeExpired || ScanPickError.approvalExpired =>
              'Ask the customer to scan the current code.',
            ScanPickError.cancelled =>
              'This order is cancelled. Do not hand over.',
            ScanPickError.forbidden || ScanPickError.unauthenticated =>
              'Sign in with an authorised store account.',
            _ => 'This order has changed. Check the latest details.',
          };
        }
      }
    } catch (_) {
      if (!_closed) {
        message = confirmingReadiness
            ? 'Checking your update. Do not hand over yet.'
            : confirmingHandover
            ? 'Confirming collection…'
            : needsReconciliation
            ? 'Checking your update. Do not hand over yet.'
            : 'Unable to load this order. Try again.';
      }
    } finally {
      if (!_closed) {
        busy = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _closed = true;
    _matchExpiryTimer?.cancel();
    _elapsed.stop();
    super.dispose();
  }
}

/// Existing Store fields partitioned by workspace, within this signed-in session.
/// This cache is not authoritative persistence or backend membership validation.
class _StoreOperationalData {
  WorkOrderOperations? orderOperations;
  final Map<String, int> projectedOrderRevisions = {};
  bool retailerProductAdded = false;
  int retailerQuantity = 0;
  int retailerBuyPrice = 0;
  int retailerSellPrice = 0;
  bool retailerHomeDelivery = false;
  bool retailerStoreCollection = false;
  bool retailerPublishAfterSetup = false;
  bool retailerSetupSaved = false;
  String workspaceSearchQuery = '';
  WorkspaceStoreState workspaceStoreState = WorkspaceStoreState.off;
  WorkspaceDashboardState workspaceDashboardState =
      WorkspaceDashboardState.ready;
  DateTime? workspaceLastUpdatedAt;
  String workspaceDashboardError = '';
  bool workspaceAcceptingOrders = false;
  String workspaceFulfilmentMode = 'Delivery and pickup';
  int workspaceBusyMinutes = 0;
  String workspaceReopensAt = '';
  String workspaceOpeningTime = '8:00 AM';
  String workspaceClosingTime = '10:00 PM';
  int workspaceMaximumActiveOrders = 8;
  bool workspaceOrderAlertSound = true;
  bool workspaceOrderAlertVibration = true;
  bool workspaceVisibleToCustomers = false;
  String workspaceOrderCustomer = '';
  String workspaceOrderItems = '';
  String workspaceOrderAmount = '';
  bool workspaceOrderNeedsDelivery = false;
  String workspaceOrderSource = 'Counter';
  String workspaceOrderFulfilment = 'At the shop';
  String workspaceOrderPayment = 'Cash';
  String workspaceOrderAddress = '';
  String workspaceOrderStage = 'No order';
  int workspaceOrderExtraMinutes = 0;
  DateTime? workspaceOrderActionDeadline;
  String workspaceOrderFilter = 'Live';
  String workspaceCustomerPeriod = 'Month';
  String workspaceCustomerSearch = '';
  String workspaceCustomerFilter = 'Recent';
  String workspaceMoneyPeriod = 'Today';
  DateTime? workspaceCustomerCustomStart;
  DateTime? workspaceCustomerCustomEnd;
  int workspaceSalesToday = 0;
  int workspaceCompletedSalesCount = 0;
  int workspacePlatformAdjustments = 0;
  int workspaceDeliveryAdjustments = 0;
  int workspaceRefunds = 0;
  int workspaceTaxWithheld = 0;
  int workspaceSettlementBalance = 0;
  int workspaceSettlementRequested = 0;
  String? workspaceSettlementReference;
  String workspacePayoutBankName = '';
  String workspacePayoutAccountEnding = '';
  final List<WorkspaceCatalogueItem> workspaceCatalogueItems = [];
  final List<WorkspaceStockMovement> workspaceStockMovements = [];
  final Map<String, int> workspaceOrderQuantities = {};
  final List<WorkspaceOrderRecord> workspaceOrders = [];
  final Set<String> workspacePackedProductIds = <String>{};
  final Map<String, Set<String>> _packingByOrder = {};
  final Map<String, ({String items, Map<String, int> quantities})>
  _packingContentsByOrder = {};
  final Map<String, WorkspaceDeliveryAssignment> _deliveryByOrder = {};
  final List<WorkspaceCustomerInvoice> workspaceInvoices = [];
  final List<WorkspaceStoreOffer> workspaceOffers = [];
  String? currentWorkspaceOrderId;
  WorkspaceDeliveryAssignment? workspaceDeliveryAssignment;
  bool workspaceOperationsSyncing = false;
  String? workspaceOperationsSyncError;
  bool workspaceHandoverBusy = false;
  final List<WorkspaceActivityEntry> workspaceActivity = [];
  WorkspaceGroupBuy? activeGroupBuy;
  int workspaceDeliveryRadiusKm = 5;
  int workspaceDeliveryFee = 30;
  int workspaceFreeDeliveryAbove = 499;
  String workspaceDeliveryCity = 'Jodhpur';
  String workspaceDeliveryArea = 'Sardarpura';
  String workspaceDeliveryPincode = '342003';
  bool workspacePickupEnabled = true;
  bool workspaceStaffAccessEnabled = false;
  int workspaceCounterCount = 1;
  String? workspacePaidRequirementReference;
  WorkspacePaidRequirementState workspacePaidRequirementState =
      WorkspacePaidRequirementState.draft;
  final Set<String> dismissedWorkspaceAlerts = <String>{};
  final Set<String> workspaceCustomersFollowingStore = <String>{};
  final Set<String> workspaceCustomersAllowingMessages = <String>{};
  final Map<String, DateTime> workspaceCustomerLastContactAt =
      <String, DateTime>{};

  int pendingOperationalRequests = 0;
}

/// Editable application data is separate from an approved Store's operations.
/// Document bytes and contact confirmation are memory-only and account-bound.
class _WorkspaceApplicationDraft {
  const _WorkspaceApplicationDraft({
    required this.id,
    required this.scope,
    required this.details,
    this.submitted,
    this.files = const {},
    this.confirmed = const {},
    this.status,
    this.reason,
    this.needsStatusRefresh = false,
  });

  final String id;
  final String? scope;
  final Map<String, Object?> details;
  final WorkProfileSubmission? submitted;
  final Map<String, WorkPickedProof> files;
  final Set<WorkContactChannel> confirmed;
  final WorkRemoteReviewStatus? status;
  final String? reason;
  final bool needsStatusRefresh;
  String? get caseId => details['caseId'] as String?;
}

class WorkSession extends ChangeNotifier {
  WorkSession({
    WorkGateway? gateway,
    WorkProofPicker? proofPicker,
    WorkPendingProofStore? pendingProofStore,
    WorkPendingProofStore? contactDraftStore,
  }) : gateway = gateway ?? ReviewWorkGateway(),
       contactDraftStore =
           contactDraftStore ??
           (kDebugMode &&
                   const bool.fromEnvironment('MOOLSOCIAL_DEVICE_REVIEW') &&
                   const bool.fromEnvironment('MOOLSOCIAL_UI_REVIEW_ONLY')
               ? SecureWorkPendingProofStore.contactDraft(reviewOnly: true)
               : null),
       pendingProofStore =
           pendingProofStore ??
           (kDebugMode &&
                   const bool.fromEnvironment('MOOLSOCIAL_DEVICE_REVIEW') &&
                   const bool.fromEnvironment('MOOLSOCIAL_UI_REVIEW_ONLY')
               ? SecureWorkPendingProofStore(reviewOnly: true)
               : null),
       proofPicker =
           proofPicker ??
           (kDebugMode &&
                   const bool.fromEnvironment('MOOLSOCIAL_DEVICE_REVIEW') &&
                   const bool.fromEnvironment('MOOLSOCIAL_UI_REVIEW_ONLY')
               ? NativeWorkProofPicker()
               : ReviewWorkProofPicker());

  WorkSession.production({
    WorkGateway? gateway,
    WorkProofPicker? proofPicker,
    WorkPendingProofStore? pendingProofStore,
    WorkPendingProofStore? contactDraftStore,
  }) : gateway = gateway ?? buildWorkGateway(),
       contactDraftStore =
           contactDraftStore ??
           (proofPicker == null || proofPicker is NativeWorkProofPicker
               ? SecureWorkPendingProofStore.contactDraft()
               : null),
       pendingProofStore =
           pendingProofStore ??
           (proofPicker == null || proofPicker is NativeWorkProofPicker
               ? SecureWorkPendingProofStore()
               : null),
       proofPicker = proofPicker ?? NativeWorkProofPicker();

  final WorkGateway gateway;
  final WorkProofPicker proofPicker;
  final WorkPendingProofStore? pendingProofStore;
  final WorkPendingProofStore? contactDraftStore;
  StoreCollectionController? _collection;
  StoreCollectionController? get currentCollection =>
      currentWorkspaceOrder?.isCustomerCollection == true &&
          _collection?.orderId == currentWorkspaceOrderId &&
          _collection?.storeId == (activeWorkspace?.id ?? workspaceId)
      ? _collection
      : null;

  /// A retained display string cannot prove current customer authorisation.
  /// Keep operational/wire state intact; derive the visible label using the
  /// same scoped, current authority that protects the central Hand Over action.
  String workspaceOrderStageLabel(WorkspaceOrderRecord order) {
    if (!order.isCustomerCollection) return order.stage;
    if ({'Matched', 'Customer confirmed'}.contains(order.stage)) {
      final current = currentCollection;
      return current?.orderId == order.id &&
              current?.storeId == order.collectionStoreId &&
              current?.hasCurrentMatch == true
          ? 'Customer confirmed'
          : 'Checking order';
    }
    return order.stage == 'Awaiting customer'
        ? 'Waiting for customer'
        : order.stage;
  }

  String get currentWorkspaceOrderStageLabel => currentWorkspaceOrder == null
      ? workspaceOrderStage
      : workspaceOrderStageLabel(currentWorkspaceOrder!);

  /// Called by the future authenticated order adapter, never by a QR decoder.
  void attachCollection(StoreCollectionController controller) {
    if (_collection?.needsReconciliation == true) {
      throw StateError('Reconcile the current collection update first');
    }
    final order = currentWorkspaceOrder;
    if (order == null ||
        !order.isCustomerCollection ||
        controller.orderId != order.id ||
        controller.storeId != order.collectionStoreId ||
        controller.storeId != (activeWorkspace?.id ?? workspaceId)) {
      throw ArgumentError(
        'Collection context does not match the selected store order',
      );
    }
    _clearCollection();
    _collection = controller..addListener(_collectionChanged);
    _collectionChanged();
  }

  void _collectionChanged() {
    final controller = currentCollection;
    final value = controller?.snapshot;
    if (controller?.hasAuthoritativeSnapshot == true && value != null) {
      final index = workspaceOrders.indexWhere(
        (order) =>
            order.id == value.orderId &&
            order.collectionStoreId == value.storeId,
      );
      if (index >= 0) {
        workspaceOrderStage = switch (value.state) {
          ScanPickState.preparing => 'Preparing',
          ScanPickState.ready => 'Ready for collection',
          ScanPickState.awaitingCustomer => 'Awaiting customer',
          ScanPickState.matched => 'Customer confirmed',
          ScanPickState.collected => 'Collected',
          ScanPickState.cancelled => 'Cancelled',
        };
        workspaceOrders[index] = workspaceOrders[index].copyWith(
          stage: workspaceOrderStage,
        );
        workspaceOrderActionDeadline = null;
        // These are server projections only. Never apply stock, invoice,
        // payment or settlement effects again from a collection response.
      }
    }
    notifyListeners();
  }

  void _clearCollection() {
    _collection?.removeListener(_collectionChanged);
    _collection?.dispose();
    _collection = null;
  }

  String? _contactDraftScope;
  bool _contactDraftScopeKnown = false;
  Future<void>? _contactDraftRecovery;
  Future<void>? _contactDraftWrite;
  ({String scope, Map<String, Object?> draft})? _queuedContactDraft;
  int _contactDraftRevision = 0;
  final Set<String> _editedDraftFields = {};
  String? contactDraftMessage;
  String? _pendingProofScope;
  Future<void>? _pendingProofRecovery;
  bool _pendingProofRoute = false;
  int _pendingProofGeneration = 0;
  bool _hasRecoveredDraft = false;
  bool recoveredDocumentStep = false;
  String? documentRecoveryMessage;
  String? _documentRecoveryProofId;
  bool _disposed = false;
  bool busy = false;
  String? errorMessage;
  String? noticeMessage;
  WorkFeedFilter filter = WorkFeedFilter.forYou;
  String searchQuery = '';
  String selectedCity = '';
  String selectedArea = '';
  String selectedPincode = '';
  String? expandedOpportunityId;
  WorkOpportunity? selectedOpportunity;
  WorkOpportunity? savedOpportunity;
  String? applicationId;
  String? appliedOpportunityId;
  String? withdrawnApplicationId;
  final Map<String, String> applicationIdsByOpportunity = <String, String>{};
  final Set<String> expandedTerms = <String>{};

  String? selectedFamilyId;
  WorkProfileOption? selectedProfile;
  String accountDisplayName = '';
  String authorizedPersonName = '';
  String businessRelationship = '';
  String connectedProviderLabel = '';
  String connectedProviderAccount = '';
  String primaryMobile = '';
  bool primaryMobileOtpSent = false;
  bool primaryMobileVerified = false;
  String contactEmail = '';
  bool contactEmailOtpSent = false;
  bool contactEmailVerified = false;
  String alternateMobile = '';
  bool alternateOtpSent = false;
  bool alternateVerified = false;
  final Map<WorkContactChannel, int> _contactRevisions = {};
  final Map<WorkContactChannel, ({String value, bool verified, String? scope})>
  _contactEditOrigins = {};

  String workName = '';
  String workArea = '';
  String primaryActivity = '';
  final Map<String, String> addedProofs = <String, String>{};
  final Map<String, WorkPickedProof> pickedProofs = <String, WorkPickedProof>{};
  final Map<
    String,
    ({
      String reference,
      WorkPickedProof? file,
      String? profileId,
      String? scope,
    })
  >
  _removedProofs = {};
  WorkProfileSubmission? submittedProfile;
  final Set<String> _seenApprovalMessages = {};
  ({String? scope, String caseId, String workspaceId})? _approvalWelcome;
  bool declarationAccepted = false;
  WorkReviewStage reviewStage = WorkReviewStage.none;
  String? reviewCaseId;
  String? workspaceId;
  String subscriptionPlan = 'free';
  String? reviewReason;
  WorkRemoteReviewStatus? remoteReviewStatus;
  bool reviewCorrectionDraft = false;
  bool reviewStatusNeedsRefresh = false;
  String? _workspaceApplicationId;
  final Map<String, _WorkspaceApplicationDraft> _workspaceApplications = {};
  bool get hasUnsubmittedReviewChanges {
    final submitted = submittedProfile;
    if (!reviewCorrectionDraft ||
        reviewCaseId == null ||
        submitted == null ||
        submitted.profileId != selectedProfile?.id) {
      return false;
    }
    return submitted.name != workName ||
        submitted.authorizedPersonName != authorizedPersonName ||
        submitted.businessRelationship != businessRelationship ||
        submitted.area != workArea ||
        submitted.primaryActivity != primaryActivity ||
        submitted.primaryMobile != primaryMobile ||
        submitted.email != contactEmail ||
        submitted.alternateMobile != alternateMobile ||
        !mapEquals(submitted.proofReferences, addedProofs);
  }

  String? _profileSubmissionKey;
  bool gstReminder = false;
  String gstin = '';
  bool gstAttachmentAdded = false;
  String? gstProofReference;
  bool unsupportedRequestSent = false;
  String unsupportedWorkspace = '';
  String unsupportedArea = '';
  String unsupportedFamily = '';
  String unsupportedOtherActivity = '';

  WorkWorkspace? _activeWorkspace;
  WorkWorkspace? get activeWorkspace => _activeWorkspace;
  set activeWorkspace(WorkWorkspace? value) {
    final previousId = _activeWorkspace?.id;
    if (previousId != value?.id) {
      _clearCollection();
      if (previousId != null) _storeDataById[previousId] = _storeData;
      if (value == null) {
        _storeData = _StoreOperationalData();
      } else {
        // First activation may adopt setup fields from this same session.
        // A different existing store must never inherit the previous data.
        _storeData =
            _storeDataById.remove(value.id) ??
            (previousId == null ? _storeData : _StoreOperationalData());
      }
    }
    _activeWorkspace = value;
    if (_scopedOrderOperations != null) {
      final order = currentWorkspaceOrder;
      if (order != null) _projectSelectedWorkspaceOrder(order);
    }
  }

  final List<WorkWorkspace> otherWorkspaces = <WorkWorkspace>[];

  bool initialWorkspaceStateLoaded = false;
  _StoreOperationalData _storeData = _StoreOperationalData();
  final Map<String, _StoreOperationalData> _storeDataById = {};

  WorkOrderOperations? get _scopedOrderOperations {
    final operations = _storeData.orderOperations;
    return operations != null &&
            !operations.isDisposed &&
            operations.accountScope == _contactAccountScope &&
            operations.workspaceId == (activeWorkspace?.id ?? workspaceId)
        ? operations
        : null;
  }

  bool hasScopedWorkspaceOrder(String orderId) =>
      _storeData.projectedOrderRevisions.containsKey(orderId);

  WorkOrderOperationState? workspaceOrderOperationState(String orderId) =>
      _scopedOrderOperations?.state(orderId);

  bool workspaceOrderHasTimeRequest(String orderId) =>
      _scopedOrderOperations?.pending(orderId)?.action ==
      WorkOrderAction.requestTime;

  /// Called by the authenticated Store adapter, not by a route or a review
  /// status label. Session owns the controller after successful binding.
  bool bindWorkspaceOrderOperations(WorkOrderOperations operations) {
    final storeId = activeWorkspace?.id ?? workspaceId;
    if (_disposed ||
        operations.isDisposed ||
        !operations.recoveryReady ||
        _contactAccountScope == null ||
        operations.accountScope != _contactAccountScope ||
        operations.workspaceId != storeId ||
        busy ||
        workspaceOperationsSyncing ||
        workspaceHandoverBusy ||
        hasPendingOrderTime ||
        _collection?.needsReconciliation == true ||
        _storeData.orderOperations != null) {
      return false;
    }
    final data = _storeData;
    data.orderOperations = operations;
    void project(String orderId) {
      if (_disposed ||
          operations.accountScope != _contactAccountScope ||
          !identical(data.orderOperations, operations)) {
        return;
      }
      final snapshot = operations.order(orderId);
      if (snapshot != null &&
          snapshot.revision > (data.projectedOrderRevisions[orderId] ?? -1)) {
        final order = snapshot.order!;
        // Collection authorisation stays with the collection controller.
        if (order.isCustomerCollection) return;
        final index = data.workspaceOrders.indexWhere(
          (item) => item.id == orderId,
        );
        if (index >= 0) {
          if (data.workspaceOrders[index].isCustomerCollection) return;
          data.workspaceOrders[index] = order;
        } else {
          data.workspaceOrders.insert(0, order);
        }
        data.projectedOrderRevisions[orderId] = snapshot.revision;
        final deliveryKey = '${operations.workspaceId}::$orderId';
        if (snapshot.delivery case final delivery?) {
          data._deliveryByOrder[deliveryKey] = delivery;
        } else {
          data._deliveryByOrder.remove(deliveryKey);
        }
        if (identical(data, _storeData) && currentWorkspaceOrderId == orderId) {
          _projectSelectedWorkspaceOrder(order);
        }
      }
      if (identical(data, _storeData)) notifyListeners();
    }

    operations.addListener(() {
      final orderId = operations.changedOrderId;
      if (orderId != null) project(orderId);
    });
    for (final snapshot in operations.orders) {
      project(snapshot.orderId);
    }
    notifyListeners();
    return true;
  }

  void _projectSelectedWorkspaceOrder(WorkspaceOrderRecord order) {
    _preparePackingContents(order, workspacePackedProductIds);
    workspaceOrderCustomer = order.customer;
    workspaceOrderItems = order.items;
    workspaceOrderQuantities
      ..clear()
      ..addAll(order.quantities);
    workspaceOrderAmount = order.amount.toString();
    workspaceOrderSource = order.source;
    workspaceOrderFulfilment = order.fulfilment;
    workspaceOrderPayment = order.payment;
    workspaceOrderAddress = order.address;
    workspaceOrderStage = order.stage;
    workspaceOrderNeedsDelivery = order.needsDelivery;
    workspaceOrderActionDeadline = order.actionDeadline;
    workspaceDeliveryAssignment = _deliveryByOrder[_orderScope(order.id)];
    // No stock, invoice, payout or sales total is derived from this projection.
  }

  Future<bool> submitWorkspaceOrderAction(
    String orderId,
    WorkOrderAction action, {
    String? reason,
  }) async {
    final operations = _scopedOrderOperations;
    final order = operations?.order(orderId)?.order;
    if (operations == null ||
        order == null ||
        currentWorkspaceOrderId != orderId ||
        busy ||
        workspaceOperationsSyncing ||
        workspaceHandoverBusy ||
        hasPendingOrderTime ||
        _collection?.needsReconciliation == true) {
      return false;
    }
    if (action == WorkOrderAction.ready && !workspacePackingComplete) {
      showError('Mark every product packed before the order is ready.');
      return false;
    }
    if (action == WorkOrderAction.accept &&
        order.actionDeadline != null &&
        !order.actionDeadline!.isAfter(DateTime.now())) {
      showError('Acceptance time ended. Waiting for an order update.');
      return false;
    }
    if (action == WorkOrderAction.reject &&
        (reason == null || reason.trim().isEmpty)) {
      showError('Choose a reason before rejecting the order.');
      return false;
    }
    final applied = await operations.act(orderId, action, reason: reason);
    _showScopedOrderResolution(operations, orderId, applied);
    return applied;
  }

  Future<bool> retryWorkspaceOrderAction(String orderId) async {
    final operations = _scopedOrderOperations;
    if (operations == null) return false;
    final applied = await operations.retry(orderId);
    _showScopedOrderResolution(operations, orderId, applied);
    return applied;
  }

  void _showScopedOrderResolution(
    WorkOrderOperations operations,
    String orderId,
    bool applied,
  ) {
    if (!applied &&
        operations.pending(orderId) == null &&
        identical(_scopedOrderOperations, operations) &&
        currentWorkspaceOrderId == orderId) {
      showError('This change was not approved. Review the current order.');
    }
  }

  Object? _busyStoreOperation;
  WorkOrderTimeRequest? _pendingOrderTime;
  _StoreOperationalData? _orderTimeData;
  String? _orderTimeAccountScope;

  bool get hasPendingOrderTime =>
      _pendingOrderTime != null &&
      identical(_orderTimeData, _storeData) &&
      _orderTimeAccountScope == _contactAccountScope &&
      _pendingOrderTime!.workspaceId == (activeWorkspace?.id ?? workspaceId);

  int? get pendingOrderTimeMinutes => hasPendingOrderTime
      ? _pendingOrderTime!.additionalMinutes
      : _scopedOrderOperations
            ?.pending(currentWorkspaceOrderId ?? '')
            ?.additionalMinutes;

  // The legacy global lock remains separate; a scoped A must not lock B.
  bool get hasPendingCurrentOrderTime =>
      hasPendingOrderTime ||
      workspaceOrderHasTimeRequest(currentWorkspaceOrderId ?? '');

  bool get orderTimeRequestBusy =>
      busy ||
      (workspaceOrderHasTimeRequest(currentWorkspaceOrderId ?? '') &&
          workspaceOrderOperationState(currentWorkspaceOrderId ?? '') !=
              WorkOrderOperationState.uncertain);

  bool get orderTimeServiceAvailable =>
      hasScopedWorkspaceOrder(currentWorkspaceOrderId ?? '')
      ? _scopedOrderOperations?.timeRequestsAvailable == true ||
            workspaceOrderHasTimeRequest(currentWorkspaceOrderId ?? '')
      : gateway is WorkOrderTimeGateway;

  Future<bool> requestWorkspaceOrderTime(
    String orderId,
    int additionalMinutes,
  ) async {
    if (hasScopedWorkspaceOrder(orderId)) {
      final operations = _scopedOrderOperations;
      if (operations == null ||
          currentWorkspaceOrderId != orderId ||
          busy ||
          workspaceOperationsSyncing ||
          workspaceHandoverBusy ||
          hasPendingOrderTime ||
          _collection?.needsReconciliation == true) {
        return false;
      }
      if (!operations.timeRequestsAvailable &&
          !workspaceOrderHasTimeRequest(orderId)) {
        showError(
          'More time is not available for this order yet. The current time still applies.',
        );
        return false;
      }
      final pending = operations.pending(orderId);
      if (pending != null && pending.action != WorkOrderAction.requestTime) {
        return false;
      }
      final applied = pending != null
          ? await operations.retry(orderId)
          : await operations.act(
              orderId,
              WorkOrderAction.requestTime,
              additionalMinutes: additionalMinutes,
            );
      if (identical(_scopedOrderOperations, operations) &&
          currentWorkspaceOrderId == orderId &&
          !applied &&
          operations.pending(orderId) == null) {
        showError(
          'More time was not approved. The current time still applies.',
        );
      }
      return applied;
    }
    if (busy) return false;
    final order = currentWorkspaceOrder;
    final storeId = activeWorkspace?.id ?? workspaceId;
    final deadline = order?.actionDeadline;
    if (order == null ||
        order.id != orderId ||
        order.stage != 'Confirmed' ||
        order.isCustomerCollection ||
        storeId == null ||
        deadline == null) {
      showError('This order has changed. Review its current status.');
      return false;
    }
    if (!hasPendingOrderTime && !{2, 5}.contains(additionalMinutes)) {
      showError('Choose 2 or 5 additional minutes.');
      return false;
    }
    if (!hasPendingOrderTime && !deadline.isAfter(DateTime.now())) {
      showError('Acceptance time ended. Wait for the order update.');
      return false;
    }
    if (!orderTimeServiceAvailable) {
      showError(
        'Cannot request more time right now. The current time still applies.',
      );
      return false;
    }
    final request = hasPendingOrderTime
        ? _pendingOrderTime!
        : WorkOrderTimeRequest(
            workspaceId: storeId,
            orderId: order.id,
            operationId:
                'ORDER-TIME-$storeId-${order.id}-${DateTime.now().microsecondsSinceEpoch}',
            expectedAcceptanceDeadline: deadline,
            additionalMinutes: additionalMinutes,
          );
    if (request.orderId != order.id ||
        request.expectedAcceptanceDeadline != deadline) {
      showError('Confirm the previous time request before making another.');
      return false;
    }
    final data = _storeData;
    final scope = _contactAccountScope;
    _pendingOrderTime = request;
    _orderTimeData = data;
    _orderTimeAccountScope = scope;
    bool current() =>
        _isStoreScopeCurrent(data, storeId, scope) &&
        currentWorkspaceOrderId == request.orderId &&
        identical(_pendingOrderTime, request);
    final token = _beginBusyStoreOperation();
    clearMessages();
    notifyListeners();
    try {
      final result = await (gateway as WorkOrderTimeGateway)
          .requestOrderTime(request)
          .timeout(const Duration(seconds: 15));
      if (!current()) return false;
      final latest = currentWorkspaceOrder!;
      if (latest.stage != 'Confirmed' ||
          latest.actionDeadline != request.expectedAcceptanceDeadline ||
          result.workspaceId != request.workspaceId ||
          result.orderId != request.orderId ||
          result.operationId != request.operationId) {
        showError('The time request needs an order update. Retry to check it.');
        return false;
      }
      if (!result.approved) {
        _pendingOrderTime = null;
        showError(
          'More time was not approved. The current time still applies.',
        );
        return false;
      }
      final acceptance = result.acceptanceDeadline;
      final fulfilment = result.fulfilmentDeadline;
      if (acceptance == null ||
          fulfilment == null ||
          !acceptance.isAfter(DateTime.now()) ||
          !acceptance.isAfter(request.expectedAcceptanceDeadline) ||
          acceptance.isAfter(
            request.expectedAcceptanceDeadline.add(
              Duration(minutes: request.additionalMinutes),
            ),
          ) ||
          !fulfilment.isAfter(acceptance)) {
        showError('The updated time is not confirmed. Retry to check it.');
        return false;
      }
      final index = workspaceOrders.indexWhere((item) => item.id == order.id);
      if (index < 0) return false;
      workspaceOrders[index] = latest.copyWith(
        actionDeadline: acceptance,
        fulfilmentDeadline: fulfilment,
      );
      workspaceOrderActionDeadline = acceptance;
      _pendingOrderTime = null;
      showNotice(
        'Time confirmed. Check the updated acceptance and fulfilment times.',
      );
      return true;
    } catch (_) {
      if (current()) {
        showError(
          'The request could not be confirmed. Retry to check the same request.',
        );
      }
      return false;
    } finally {
      if (!_disposed) _finishBusyStoreOperation(token);
    }
  }

  bool _isStoreScopeCurrent(
    _StoreOperationalData data,
    String id,
    String? scope,
  ) =>
      !_disposed &&
      identical(data, _storeData) &&
      id == (activeWorkspace?.id ?? workspaceId) &&
      scope == _contactAccountScope;

  Object _beginBusyStoreOperation() {
    final token = Object();
    _busyStoreOperation = token;
    busy = true;
    return token;
  }

  void _finishBusyStoreOperation(Object token) {
    if (!identical(token, _busyStoreOperation)) return;
    _busyStoreOperation = null;
    busy = false;
    notifyListeners();
  }

  void _finishOperationalRequest(
    _StoreOperationalData data,
    String id,
    String? scope,
  ) {
    data.pendingOperationalRequests--;
    data.workspaceOperationsSyncing = data.pendingOperationalRequests > 0;
    if (_isStoreScopeCurrent(data, id, scope)) notifyListeners();
  }

  bool get retailerProductAdded => _storeData.retailerProductAdded;
  set retailerProductAdded(bool value) =>
      _storeData.retailerProductAdded = value;
  int get retailerQuantity => _storeData.retailerQuantity;
  set retailerQuantity(int value) => _storeData.retailerQuantity = value;
  int get retailerBuyPrice => _storeData.retailerBuyPrice;
  set retailerBuyPrice(int value) => _storeData.retailerBuyPrice = value;
  int get retailerSellPrice => _storeData.retailerSellPrice;
  set retailerSellPrice(int value) => _storeData.retailerSellPrice = value;
  bool get retailerHomeDelivery => _storeData.retailerHomeDelivery;
  set retailerHomeDelivery(bool value) =>
      _storeData.retailerHomeDelivery = value;
  bool get retailerStoreCollection => _storeData.retailerStoreCollection;
  set retailerStoreCollection(bool value) =>
      _storeData.retailerStoreCollection = value;
  bool get retailerPublishAfterSetup => _storeData.retailerPublishAfterSetup;
  set retailerPublishAfterSetup(bool value) =>
      _storeData.retailerPublishAfterSetup = value;
  bool get retailerSetupSaved => _storeData.retailerSetupSaved;
  set retailerSetupSaved(bool value) => _storeData.retailerSetupSaved = value;
  String get workspaceSearchQuery => _storeData.workspaceSearchQuery;
  set workspaceSearchQuery(String value) =>
      _storeData.workspaceSearchQuery = value;
  WorkspaceStoreState get workspaceStoreState => _storeData.workspaceStoreState;
  set workspaceStoreState(WorkspaceStoreState value) =>
      _storeData.workspaceStoreState = value;
  WorkspaceDashboardState get workspaceDashboardState =>
      _storeData.workspaceDashboardState;
  set workspaceDashboardState(WorkspaceDashboardState value) =>
      _storeData.workspaceDashboardState = value;
  DateTime? get workspaceLastUpdatedAt => _storeData.workspaceLastUpdatedAt;
  set workspaceLastUpdatedAt(DateTime? value) =>
      _storeData.workspaceLastUpdatedAt = value;
  String get workspaceDashboardError => _storeData.workspaceDashboardError;
  set workspaceDashboardError(String value) =>
      _storeData.workspaceDashboardError = value;
  bool get workspaceAcceptingOrders => _storeData.workspaceAcceptingOrders;
  set workspaceAcceptingOrders(bool value) =>
      _storeData.workspaceAcceptingOrders = value;
  String get workspaceFulfilmentMode => _storeData.workspaceFulfilmentMode;
  set workspaceFulfilmentMode(String value) =>
      _storeData.workspaceFulfilmentMode = value;
  int get workspaceBusyMinutes => _storeData.workspaceBusyMinutes;
  set workspaceBusyMinutes(int value) =>
      _storeData.workspaceBusyMinutes = value;
  String get workspaceReopensAt => _storeData.workspaceReopensAt;
  set workspaceReopensAt(String value) => _storeData.workspaceReopensAt = value;
  String get workspaceOpeningTime => _storeData.workspaceOpeningTime;
  set workspaceOpeningTime(String value) =>
      _storeData.workspaceOpeningTime = value;
  String get workspaceClosingTime => _storeData.workspaceClosingTime;
  set workspaceClosingTime(String value) =>
      _storeData.workspaceClosingTime = value;
  int get workspaceMaximumActiveOrders =>
      _storeData.workspaceMaximumActiveOrders;
  set workspaceMaximumActiveOrders(int value) =>
      _storeData.workspaceMaximumActiveOrders = value;
  bool get workspaceOrderAlertSound => _storeData.workspaceOrderAlertSound;
  set workspaceOrderAlertSound(bool value) =>
      _storeData.workspaceOrderAlertSound = value;
  bool get workspaceOrderAlertVibration =>
      _storeData.workspaceOrderAlertVibration;
  set workspaceOrderAlertVibration(bool value) =>
      _storeData.workspaceOrderAlertVibration = value;
  bool get workspaceVisibleToCustomers =>
      _storeData.workspaceVisibleToCustomers;
  set workspaceVisibleToCustomers(bool value) =>
      _storeData.workspaceVisibleToCustomers = value;
  String get workspaceOrderCustomer => _storeData.workspaceOrderCustomer;
  set workspaceOrderCustomer(String value) =>
      _storeData.workspaceOrderCustomer = value;
  String get workspaceOrderItems => _storeData.workspaceOrderItems;
  set workspaceOrderItems(String value) =>
      _storeData.workspaceOrderItems = value;
  String get workspaceOrderAmount => _storeData.workspaceOrderAmount;
  set workspaceOrderAmount(String value) =>
      _storeData.workspaceOrderAmount = value;
  bool get workspaceOrderNeedsDelivery =>
      _storeData.workspaceOrderNeedsDelivery;
  set workspaceOrderNeedsDelivery(bool value) =>
      _storeData.workspaceOrderNeedsDelivery = value;
  String get workspaceOrderSource => _storeData.workspaceOrderSource;
  set workspaceOrderSource(String value) =>
      _storeData.workspaceOrderSource = value;
  String get workspaceOrderFulfilment => _storeData.workspaceOrderFulfilment;
  set workspaceOrderFulfilment(String value) =>
      _storeData.workspaceOrderFulfilment = value;
  String get workspaceOrderPayment => _storeData.workspaceOrderPayment;
  set workspaceOrderPayment(String value) =>
      _storeData.workspaceOrderPayment = value;
  String get workspaceOrderAddress => _storeData.workspaceOrderAddress;
  set workspaceOrderAddress(String value) =>
      _storeData.workspaceOrderAddress = value;
  String get workspaceOrderStage => _storeData.workspaceOrderStage;
  set workspaceOrderStage(String value) =>
      _storeData.workspaceOrderStage = value;
  int get workspaceOrderExtraMinutes => _storeData.workspaceOrderExtraMinutes;
  set workspaceOrderExtraMinutes(int value) =>
      _storeData.workspaceOrderExtraMinutes = value;
  DateTime? get workspaceOrderActionDeadline =>
      _storeData.workspaceOrderActionDeadline;
  set workspaceOrderActionDeadline(DateTime? value) =>
      _storeData.workspaceOrderActionDeadline = value;
  String get workspaceOrderFilter => _storeData.workspaceOrderFilter;
  set workspaceOrderFilter(String value) =>
      _storeData.workspaceOrderFilter = value;
  String get workspaceCustomerPeriod => _storeData.workspaceCustomerPeriod;
  set workspaceCustomerPeriod(String value) =>
      _storeData.workspaceCustomerPeriod = value;
  String get workspaceCustomerSearch => _storeData.workspaceCustomerSearch;
  set workspaceCustomerSearch(String value) =>
      _storeData.workspaceCustomerSearch = value;
  String get workspaceCustomerFilter => _storeData.workspaceCustomerFilter;
  set workspaceCustomerFilter(String value) =>
      _storeData.workspaceCustomerFilter = value;
  String get workspaceMoneyPeriod => _storeData.workspaceMoneyPeriod;
  set workspaceMoneyPeriod(String value) =>
      _storeData.workspaceMoneyPeriod = value;
  DateTime? get workspaceCustomerCustomStart =>
      _storeData.workspaceCustomerCustomStart;
  set workspaceCustomerCustomStart(DateTime? value) =>
      _storeData.workspaceCustomerCustomStart = value;
  DateTime? get workspaceCustomerCustomEnd =>
      _storeData.workspaceCustomerCustomEnd;
  set workspaceCustomerCustomEnd(DateTime? value) =>
      _storeData.workspaceCustomerCustomEnd = value;
  int get workspaceSalesToday => _storeData.workspaceSalesToday;
  set workspaceSalesToday(int value) => _storeData.workspaceSalesToday = value;
  int get workspaceCompletedSalesCount =>
      _storeData.workspaceCompletedSalesCount;
  set workspaceCompletedSalesCount(int value) =>
      _storeData.workspaceCompletedSalesCount = value;
  int get workspacePlatformAdjustments =>
      _storeData.workspacePlatformAdjustments;
  set workspacePlatformAdjustments(int value) =>
      _storeData.workspacePlatformAdjustments = value;
  int get workspaceDeliveryAdjustments =>
      _storeData.workspaceDeliveryAdjustments;
  set workspaceDeliveryAdjustments(int value) =>
      _storeData.workspaceDeliveryAdjustments = value;
  int get workspaceRefunds => _storeData.workspaceRefunds;
  set workspaceRefunds(int value) => _storeData.workspaceRefunds = value;
  int get workspaceTaxWithheld => _storeData.workspaceTaxWithheld;
  set workspaceTaxWithheld(int value) =>
      _storeData.workspaceTaxWithheld = value;
  int get workspaceSettlementBalance => _storeData.workspaceSettlementBalance;
  set workspaceSettlementBalance(int value) =>
      _storeData.workspaceSettlementBalance = value;
  int get workspaceSettlementRequested =>
      _storeData.workspaceSettlementRequested;
  set workspaceSettlementRequested(int value) =>
      _storeData.workspaceSettlementRequested = value;
  String? get workspaceSettlementReference =>
      _storeData.workspaceSettlementReference;
  set workspaceSettlementReference(String? value) =>
      _storeData.workspaceSettlementReference = value;
  String get workspacePayoutBankName => _storeData.workspacePayoutBankName;
  set workspacePayoutBankName(String value) =>
      _storeData.workspacePayoutBankName = value;
  String get workspacePayoutAccountEnding =>
      _storeData.workspacePayoutAccountEnding;
  set workspacePayoutAccountEnding(String value) =>
      _storeData.workspacePayoutAccountEnding = value;
  List<WorkspaceCatalogueItem> get workspaceCatalogueItems =>
      _storeData.workspaceCatalogueItems;
  List<WorkspaceStockMovement> get workspaceStockMovements =>
      _storeData.workspaceStockMovements;
  Map<String, int> get workspaceOrderQuantities =>
      _storeData.workspaceOrderQuantities;
  List<WorkspaceOrderRecord> get workspaceOrders => _storeData.workspaceOrders;
  Set<String> get workspacePackedProductIds =>
      _storeData.workspacePackedProductIds;
  Map<String, Set<String>> get _packingByOrder => _storeData._packingByOrder;
  Map<String, ({String items, Map<String, int> quantities})>
  get _packingContentsByOrder => _storeData._packingContentsByOrder;
  Map<String, WorkspaceDeliveryAssignment> get _deliveryByOrder =>
      _storeData._deliveryByOrder;
  List<WorkspaceCustomerInvoice> get workspaceInvoices =>
      _storeData.workspaceInvoices;
  List<WorkspaceStoreOffer> get workspaceOffers => _storeData.workspaceOffers;
  String? get currentWorkspaceOrderId => _storeData.currentWorkspaceOrderId;
  set currentWorkspaceOrderId(String? value) =>
      _storeData.currentWorkspaceOrderId = value;
  WorkspaceDeliveryAssignment? get workspaceDeliveryAssignment =>
      _storeData.workspaceDeliveryAssignment;
  set workspaceDeliveryAssignment(WorkspaceDeliveryAssignment? value) =>
      _storeData.workspaceDeliveryAssignment = value;
  bool get workspaceOperationsSyncing => _storeData.workspaceOperationsSyncing;
  set workspaceOperationsSyncing(bool value) =>
      _storeData.workspaceOperationsSyncing = value;
  String? get workspaceOperationsSyncError =>
      _storeData.workspaceOperationsSyncError;
  set workspaceOperationsSyncError(String? value) =>
      _storeData.workspaceOperationsSyncError = value;
  bool get workspaceHandoverBusy => _storeData.workspaceHandoverBusy;
  set workspaceHandoverBusy(bool value) =>
      _storeData.workspaceHandoverBusy = value;
  List<WorkspaceActivityEntry> get workspaceActivity =>
      _storeData.workspaceActivity;
  WorkspaceGroupBuy? get activeGroupBuy => _storeData.activeGroupBuy;
  set activeGroupBuy(WorkspaceGroupBuy? value) =>
      _storeData.activeGroupBuy = value;
  int get workspaceDeliveryRadiusKm => _storeData.workspaceDeliveryRadiusKm;
  set workspaceDeliveryRadiusKm(int value) =>
      _storeData.workspaceDeliveryRadiusKm = value;
  int get workspaceDeliveryFee => _storeData.workspaceDeliveryFee;
  set workspaceDeliveryFee(int value) =>
      _storeData.workspaceDeliveryFee = value;
  int get workspaceFreeDeliveryAbove => _storeData.workspaceFreeDeliveryAbove;
  set workspaceFreeDeliveryAbove(int value) =>
      _storeData.workspaceFreeDeliveryAbove = value;
  String get workspaceDeliveryCity => _storeData.workspaceDeliveryCity;
  set workspaceDeliveryCity(String value) =>
      _storeData.workspaceDeliveryCity = value;
  String get workspaceDeliveryArea => _storeData.workspaceDeliveryArea;
  set workspaceDeliveryArea(String value) =>
      _storeData.workspaceDeliveryArea = value;
  String get workspaceDeliveryPincode => _storeData.workspaceDeliveryPincode;
  set workspaceDeliveryPincode(String value) =>
      _storeData.workspaceDeliveryPincode = value;
  bool get workspacePickupEnabled => _storeData.workspacePickupEnabled;
  set workspacePickupEnabled(bool value) =>
      _storeData.workspacePickupEnabled = value;
  bool get workspaceStaffAccessEnabled =>
      _storeData.workspaceStaffAccessEnabled;
  set workspaceStaffAccessEnabled(bool value) =>
      _storeData.workspaceStaffAccessEnabled = value;
  int get workspaceCounterCount => _storeData.workspaceCounterCount;
  set workspaceCounterCount(int value) =>
      _storeData.workspaceCounterCount = value;
  String? get workspacePaidRequirementReference =>
      _storeData.workspacePaidRequirementReference;
  set workspacePaidRequirementReference(String? value) =>
      _storeData.workspacePaidRequirementReference = value;
  WorkspacePaidRequirementState get workspacePaidRequirementState =>
      _storeData.workspacePaidRequirementState;
  set workspacePaidRequirementState(WorkspacePaidRequirementState value) =>
      _storeData.workspacePaidRequirementState = value;
  Set<String> get dismissedWorkspaceAlerts =>
      _storeData.dismissedWorkspaceAlerts;
  Set<String> get workspaceCustomersFollowingStore =>
      _storeData.workspaceCustomersFollowingStore;
  Set<String> get workspaceCustomersAllowingMessages =>
      _storeData.workspaceCustomersAllowingMessages;
  Map<String, DateTime> get workspaceCustomerLastContactAt =>
      _storeData.workspaceCustomerLastContactAt;

  int get workspaceOrderItemCount => workspaceOrderQuantities.values.fold(
    0,
    (total, quantity) => total + quantity,
  );

  int get workspaceOrderDisplayItemCount {
    final selected = workspaceOrderItemCount;
    if (selected > 0) return selected;
    final summary = workspaceOrderItems.trim();
    if (summary.isEmpty) return 0;
    final quantities = RegExp(
      r'×\s*(\d+)',
    ).allMatches(summary).map((match) => int.tryParse(match.group(1)!) ?? 0);
    final total = quantities.fold(0, (sum, quantity) => sum + quantity);
    return total > 0 ? total : summary.split(',').length;
  }

  int get workspaceOrderTotal =>
      workspaceCatalogueItems.fold(0, (total, product) {
        return total +
            product.sellingPrice * (workspaceOrderQuantities[product.id] ?? 0);
      });

  int get workspaceLowStockCount => workspaceCatalogueItems
      .where(
        (product) =>
            product.stockMode == WorkspaceStockMode.exactQuantity &&
            product.available &&
            product.stock <= product.lowStockThreshold,
      )
      .length;

  int get workspaceOutOfStockCount => workspaceCatalogueItems
      .where(
        (product) =>
            !product.available ||
            (product.stockMode == WorkspaceStockMode.exactQuantity &&
                product.stock <= 0),
      )
      .length;

  int get workspaceAvailableUnitCount => workspaceCatalogueItems
      .where(
        (product) =>
            product.stockMode == WorkspaceStockMode.exactQuantity &&
            product.available,
      )
      .fold<int>(0, (total, product) => total + product.stock);

  int get workspaceReservedUnitCount => workspaceOrders
      .where(
        (order) =>
            order.stockReserved &&
            order.stage != 'Completed' &&
            order.stage != 'Cancelled',
      )
      .expand((order) => order.quantities.entries)
      .fold<int>(0, (total, entry) => total + entry.value);

  int get workspacePublishedProductCount =>
      workspaceCatalogueItems.where((product) => product.published).length;

  int reservedWorkspaceUnitsFor(String productId) => workspaceOrders
      .where(
        (order) =>
            order.stockReserved &&
            order.stage != 'Completed' &&
            order.stage != 'Cancelled',
      )
      .fold<int>(
        0,
        (total, order) => total + (order.quantities[productId] ?? 0),
      );

  int? workspaceDaysOfStockFor(WorkspaceCatalogueItem product) {
    if (product.stockMode != WorkspaceStockMode.exactQuantity) return null;
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final sold = workspaceOrders
        .where(
          (order) =>
              order.stage == 'Completed' && !order.createdAt.isBefore(cutoff),
        )
        .fold<int>(
          0,
          (total, order) => total + (order.quantities[product.id] ?? 0),
        );
    if (sold <= 0) return null;
    final daily = sold / 30;
    return (product.stock / daily).floor();
  }

  int suggestedWorkspaceRestockFor(WorkspaceCatalogueItem product) {
    if (product.stockMode != WorkspaceStockMode.exactQuantity) return 0;
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final sold = workspaceOrders
        .where(
          (order) =>
              order.stage == 'Completed' && !order.createdAt.isBefore(cutoff),
        )
        .fold<int>(
          0,
          (total, order) => total + (order.quantities[product.id] ?? 0),
        );
    final target = sold > 0
        ? ((sold / 30) * 14).ceil()
        : product.lowStockThreshold * 2;
    return (target - product.stock).clamp(0, 1 << 31).toInt();
  }

  bool get hasActiveWorkspaceOrder =>
      workspaceOrderCustomer.isNotEmpty &&
      currentWorkspaceOrder?.isClosed != true &&
      workspaceOrderStage != 'Completed' &&
      workspaceOrderStage != 'Delivered' &&
      workspaceOrderStage != 'Cancelled';

  WorkspaceOrderRecord? get currentWorkspaceOrder => workspaceOrders
      .where((order) => order.id == currentWorkspaceOrderId)
      .firstOrNull;

  bool isSelectedWorkspaceOrder(WorkspaceOrderRecord order) =>
      order.id == currentWorkspaceOrderId ||
      (currentWorkspaceOrderId == null &&
          workspaceOrders.isEmpty &&
          order.id == 'current-store-order');

  String _orderScope(String id) =>
      '${activeWorkspace?.id ?? workspaceId ?? ''}::$id';

  void _rememberActiveOrder() {
    if (currentWorkspaceOrderId case final id?) {
      _packingByOrder[_orderScope(id)] = Set.of(workspacePackedProductIds);
      final assignment = workspaceDeliveryAssignment;
      if (assignment != null && assignment.orderId == id) {
        _deliveryByOrder[_orderScope(id)] = assignment;
      }
    }
  }

  bool selectWorkspaceOrder(String orderId) {
    if (hasPendingOrderTime && currentWorkspaceOrderId != orderId) {
      showNotice('Confirm the time request before switching orders.');
      return false;
    }
    if (currentWorkspaceOrderId != orderId &&
        _collection?.needsReconciliation == true) {
      showNotice('Confirming this collection. Please wait for the update.');
      return false;
    }
    if (busy || workspaceOperationsSyncing || workspaceHandoverBusy) {
      return false;
    }
    final order = workspaceOrders
        .where((item) => item.id == orderId)
        .firstOrNull;
    if (order == null) return false;
    if (currentWorkspaceOrderId == orderId) return true;
    if (currentWorkspaceOrderId == null &&
        (workspaceOrderQuantities.isNotEmpty ||
            workspaceOrderCustomer.isNotEmpty)) {
      showNotice(
        'Finish or discard the current bill before opening another order.',
      );
      return false;
    }
    _rememberActiveOrder();
    _clearCollection();
    currentWorkspaceOrderId = order.id;
    workspaceOrderCustomer = order.customer;
    workspaceOrderItems = order.items;
    workspaceOrderQuantities
      ..clear()
      ..addAll(order.quantities);
    workspaceOrderAmount = order.amount.toString();
    workspaceOrderSource = order.source;
    workspaceOrderFulfilment = order.fulfilment;
    workspaceOrderPayment = order.payment;
    workspaceOrderAddress = order.address;
    workspaceOrderStage = order.stage;
    workspaceOrderNeedsDelivery = order.needsDelivery;
    workspaceOrderExtraMinutes = order.extraMinutes;
    workspaceOrderActionDeadline = order.actionDeadline;
    workspacePackedProductIds
      ..clear()
      ..addAll(_packingByOrder[_orderScope(orderId)] ?? const <String>{});
    workspaceDeliveryAssignment = _deliveryByOrder[_orderScope(orderId)];
    clearMessages();
    notifyListeners();
    return true;
  }

  List<WorkspaceOrderRecord> get visibleWorkspaceOrders {
    if (workspaceOrders.isNotEmpty) {
      return List<WorkspaceOrderRecord>.unmodifiable(workspaceOrders);
    }
    if (workspaceOrderCustomer.trim().isEmpty ||
        workspaceOrderStage == 'No order') {
      return const <WorkspaceOrderRecord>[];
    }
    return [
      WorkspaceOrderRecord(
        id: currentWorkspaceOrderId ?? 'current-store-order',
        customer: workspaceOrderCustomer,
        items: workspaceOrderItems,
        quantities: Map<String, int>.unmodifiable(workspaceOrderQuantities),
        amount: int.tryParse(workspaceOrderAmount) ?? 0,
        source: workspaceOrderSource,
        fulfilment: workspaceOrderFulfilment,
        payment: workspaceOrderPayment,
        address: workspaceOrderAddress,
        stage: workspaceOrderStage,
        needsDelivery: workspaceOrderNeedsDelivery,
        createdAt: DateTime.now(),
        actionDeadline: workspaceOrderActionDeadline,
      ),
    ];
  }

  List<WorkspaceOrderRecord> get filteredWorkspaceCustomerOrders {
    final now = DateTime.now();
    final start = switch (workspaceCustomerPeriod) {
      'Week' => now.subtract(const Duration(days: 7)),
      'Month' => DateTime(now.year, now.month, 1),
      'Quarter' => DateTime(now.year, now.month - 2, 1),
      'Financial year' => DateTime(
        now.month >= 4 ? now.year : now.year - 1,
        4,
        1,
      ),
      'Custom' => workspaceCustomerCustomStart,
      _ => null,
    };
    final end = workspaceCustomerPeriod == 'Custom'
        ? workspaceCustomerCustomEnd
        : null;
    return visibleWorkspaceOrders
        .where((order) {
          if (start != null && order.createdAt.isBefore(start)) return false;
          if (end != null &&
              order.createdAt.isAfter(end.add(const Duration(days: 1)))) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  String workspaceCustomerId(String customer) {
    return workspaceCustomerMobile(customer) ?? customer.trim().toLowerCase();
  }

  List<WorkspaceCustomerRecord> get workspaceCustomerBook {
    final grouped = <String, List<WorkspaceOrderRecord>>{};
    for (final order in visibleWorkspaceOrders.where(
      (order) => order.stage != 'Cancelled',
    )) {
      final id = workspaceCustomerId(order.customer);
      grouped.putIfAbsent(id, () => <WorkspaceOrderRecord>[]).add(order);
    }
    final customers = <WorkspaceCustomerRecord>[];
    for (final entry in grouped.entries) {
      final orders = [...entry.value]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final raw = orders.first.customer.trim();
      final parts = raw
          .split('·')
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .toList(growable: false);
      final mobile = workspaceCustomerMobile(raw) ?? '';
      final firstPart = parts.firstOrNull ?? raw;
      final name = firstPart.isEmpty
          ? 'Customer'
          : RegExp(r'^\+?[\d\s-]+$').hasMatch(firstPart)
          ? 'Customer ending ${entry.key.length >= 4 ? entry.key.substring(entry.key.length - 4) : entry.key}'
          : firstPart;
      final totalSpend = orders
          .where((order) => order.stage == 'Completed')
          .fold<int>(0, (total, order) => total + order.amount);
      final amountDue = orders
          .where((order) => order.payment.toLowerCase().contains('due'))
          .fold<int>(0, (total, order) => total + order.amount);
      customers.add(
        WorkspaceCustomerRecord(
          id: entry.key,
          name: name,
          mobile: mobile,
          orders: List<WorkspaceOrderRecord>.unmodifiable(orders),
          totalSpend: totalSpend,
          amountDue: amountDue,
          lastPurchaseAt: orders.first.createdAt,
          followingStore: workspaceCustomersFollowingStore.contains(entry.key),
          messagesAllowed: workspaceCustomersAllowingMessages.contains(
            entry.key,
          ),
          lastContactAt: workspaceCustomerLastContactAt[entry.key],
        ),
      );
    }
    customers.sort((a, b) => b.lastPurchaseAt.compareTo(a.lastPurchaseAt));
    return List<WorkspaceCustomerRecord>.unmodifiable(customers);
  }

  List<WorkspaceCustomerRecord> get visibleWorkspaceCustomers {
    final query = workspaceCustomerSearch.trim().toLowerCase();
    return workspaceCustomerBook
        .where((customer) {
          final searchMatch =
              query.isEmpty ||
              '${customer.name} ${customer.mobile}'.toLowerCase().contains(
                query,
              );
          final filterMatch = switch (workspaceCustomerFilter) {
            'Repeat' => customer.repeatCustomer,
            'Payment due' => customer.amountDue > 0,
            'Following Store' => customer.followingStore,
            'Messages allowed' => customer.messagesAllowed,
            _ => true,
          };
          return searchMatch && filterMatch;
        })
        .toList(growable: false);
  }

  void updateWorkspaceCustomerSearch(String value) {
    workspaceCustomerSearch = value;
    notifyListeners();
  }

  void setWorkspaceCustomerFilter(String value) {
    workspaceCustomerFilter = value;
    notifyListeners();
  }

  void markWorkspaceCustomerContacted(String customerId) {
    workspaceCustomerLastContactAt[customerId] = DateTime.now();
    notifyListeners();
  }

  List<WorkspaceOrderRecord> get filteredWorkspaceMoneyOrders {
    final now = DateTime.now();
    final start = switch (workspaceMoneyPeriod) {
      'Today' => DateTime(now.year, now.month, now.day),
      'Week' => now.subtract(const Duration(days: 7)),
      'Month' => DateTime(now.year, now.month, 1),
      'Financial year' => DateTime(
        now.month >= 4 ? now.year : now.year - 1,
        4,
        1,
      ),
      _ => null,
    };
    return visibleWorkspaceOrders
        .where((order) {
          return start == null || !order.createdAt.isBefore(start);
        })
        .toList(growable: false);
  }

  List<WorkspacePackingLine> get workspacePackingLines =>
      _packingLines(currentWorkspaceOrder, workspacePackedProductIds);

  List<WorkspacePackingLine> workspacePackingLinesForOrder(
    WorkspaceOrderRecord order,
  ) => _packingLines(
    order,
    isSelectedWorkspaceOrder(order)
        ? workspacePackedProductIds
        : _packingByOrder[_orderScope(order.id)] ?? const <String>{},
  );

  List<WorkspacePackingLine> _packingLines(
    WorkspaceOrderRecord? order,
    Set<String> packedIds,
  ) {
    if (order != null && !_packingContentsMatch(order)) packedIds = const {};
    if (order != null && order.quantities.isNotEmpty) {
      return order.quantities.entries
          .map((entry) {
            final product = workspaceCatalogueItems
                .where((item) => item.id == entry.key)
                .firstOrNull;
            return WorkspacePackingLine(
              id: entry.key,
              label: product?.title ?? entry.key,
              quantity: entry.value,
              packed: packedIds.contains(entry.key),
            );
          })
          .toList(growable: false);
    }
    final parts = (order?.items ?? workspaceOrderItems)
        .split(RegExp(r'\s+[·,]\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList(growable: false);
    return [
      for (var index = 0; index < parts.length; index++)
        WorkspacePackingLine(
          id: 'summary-$index',
          label: parts[index].replaceFirst(RegExp(r'\s*×\s*\d+\s*$'), ''),
          quantity:
              int.tryParse(
                RegExp(r'×\s*(\d+)').firstMatch(parts[index])?.group(1) ?? '',
              ) ??
              1,
          packed: packedIds.contains('summary-$index'),
        ),
    ];
  }

  double get workspacePackingProgress {
    final lines = workspacePackingLines;
    if (lines.isEmpty) return 0;
    return lines.where((line) => line.packed).length / lines.length;
  }

  bool get workspacePackingComplete =>
      workspacePackingLines.isNotEmpty &&
      workspacePackingLines.every((line) => line.packed);

  WorkspaceCustomerInvoice? get latestWorkspaceInvoice =>
      workspaceInvoices.firstOrNull;

  int get workspaceSettlementEligible {
    final balance =
        workspaceSettlementBalance -
        workspacePlatformAdjustments -
        workspaceDeliveryAdjustments -
        workspaceRefunds -
        workspaceTaxWithheld;
    return balance < 0 ? 0 : balance;
  }

  String get workspaceOrderRemainingLabel {
    final deadline = workspaceOrderActionDeadline;
    if (deadline == null) return 'Review now';
    final remaining = deadline.difference(DateTime.now());
    if (remaining.isNegative) return 'Action due';
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  List<WorkOpportunity> get filteredOpportunities {
    final normalized = searchQuery.trim().toLowerCase();
    final city = selectedCity.trim().toLowerCase();
    final area = selectedArea.trim().toLowerCase();
    final pincode = selectedPincode.trim();
    final validPincode = RegExp(r'^\d{6}$').hasMatch(pincode);
    return workOpportunities.where((opportunity) {
      final filterMatch =
          filter == WorkFeedFilter.forYou ||
          opportunity.filters.contains(filter);
      final searchMatch =
          normalized.isEmpty ||
          [
            opportunity.title,
            opportunity.publisher,
            opportunity.kind,
            opportunity.location,
            opportunity.requiredWork,
            opportunity.qualificationHeadline,
            opportunity.city,
            opportunity.area,
            opportunity.pincode,
            opportunity.posterType.label,
          ].join(' ').toLowerCase().contains(normalized);
      final cityMatch = city.isEmpty || opportunity.city.toLowerCase() == city;
      final areaMatch = area.isEmpty || opportunity.area.toLowerCase() == area;
      final pincodeMatch =
          pincode.isEmpty ||
          (validPincode && opportunity.pincode == selectedPincode.trim());
      return filterMatch &&
          searchMatch &&
          cityMatch &&
          areaMatch &&
          pincodeMatch;
    }).toList();
  }

  int get activeOpportunityFilterCount => [
    selectedCity,
    selectedArea,
    selectedPincode,
  ].where((value) => value.trim().isNotEmpty).length;

  bool get hasOpportunityLocationFilter =>
      selectedCity.trim().isNotEmpty ||
      selectedArea.trim().isNotEmpty ||
      selectedPincode.trim().isNotEmpty;

  List<WorkOpportunity> get relatedOpportunities {
    if (!hasOpportunityLocationFilter) return const <WorkOpportunity>[];
    final exactIds = filteredOpportunities
        .map((opportunity) => opportunity.id)
        .toSet();
    final normalized = searchQuery.trim().toLowerCase();
    return workOpportunities
        .where((opportunity) {
          if (exactIds.contains(opportunity.id)) return false;
          final filterMatch =
              filter == WorkFeedFilter.forYou ||
              opportunity.filters.contains(filter);
          final searchMatch =
              normalized.isEmpty ||
              [
                opportunity.title,
                opportunity.publisher,
                opportunity.kind,
                opportunity.requiredWork,
                opportunity.qualificationHeadline,
                opportunity.posterType.label,
              ].join(' ').toLowerCase().contains(normalized);
          return filterMatch && searchMatch;
        })
        .take(4)
        .toList(growable: false);
  }

  List<String> get familyIds => workProfiles
      .map((profile) => profile.familyId)
      .toSet()
      .toList(growable: false);

  List<WorkProfileOption> profilesForFamily(String familyId) => workProfiles
      .where((profile) => profile.familyId == familyId)
      .toList(growable: false);

  String familyLabel(String familyId) => workProfiles
      .firstWhere((profile) => profile.familyId == familyId)
      .familyLabel;

  WorkGstMatchCategory? get selectedGstMatchCategory =>
      selectedProfile?.gstMatchCategory;

  WorkDocumentChecklistItem? get selectedGstChecklistItem => selectedProfile
      ?.verificationDocuments
      .where((document) => document.title == 'GST registration certificate')
      .firstOrNull;

  List<WorkProofRequirement> get selectedWorkspaceDocuments {
    final profile = selectedProfile;
    if (profile == null) return workProofs;
    final documents = <WorkProofRequirement>[];
    for (var index = 0; index < profile.verificationDocuments.length; index++) {
      final document = profile.verificationDocuments[index];
      final id = document.title == 'GST registration certificate'
          ? 'gst'
          : index == 0
          ? 'personal-kyc'
          : document.title == 'Payout bank account proof'
          ? 'payout-bank-account'
          : document.title.toLowerCase().contains('address')
          ? 'shop-front'
          : document.title.toLowerCase().contains('authority') ||
                document.title.toLowerCase().contains('authorised')
          ? 'owner-authority'
          : '${profile.id}-document-$index';
      documents.add(
        WorkProofRequirement(
          id: id,
          label:
              id == 'owner-authority' &&
                  businessRelationship == 'Authorized representative'
              ? 'Authorization letter'
              : document.title,
          detail:
              id == 'owner-authority' &&
                  businessRelationship == 'Authorized representative'
              ? 'A letter signed by the owner authorizing you to manage this business.'
              : document.detail,
          importance: document.importance,
        ),
      );
    }
    return List<WorkProofRequirement>.unmodifiable(documents);
  }

  bool get requiredProofsAdded => selectedWorkspaceDocuments
      .where((proof) => proof.required)
      .every((proof) => addedProofs.containsKey(proof.id));

  bool get hasVerifiedWorkspace => activeWorkspace?.verified == true;

  bool takeWorkspaceApprovalWelcome() {
    final welcome = _approvalWelcome;
    if (welcome == null ||
        welcome.scope != _contactAccountScope ||
        welcome.caseId != reviewCaseId ||
        welcome.workspaceId != workspaceId ||
        welcome.workspaceId != activeWorkspace?.id ||
        !hasVerifiedWorkspace ||
        (remoteReviewStatus != WorkRemoteReviewStatus.approved &&
            remoteReviewStatus != WorkRemoteReviewStatus.live)) {
      return false;
    }
    _approvalWelcome = null;
    final key = jsonEncode([welcome.caseId, welcome.workspaceId]);
    if (!_seenApprovalMessages.add(key)) return false;
    // A dismissal acknowledgement is not authority for Workspace approval.
    _queueContactDraft();
    return true;
  }

  bool get retailerReady =>
      retailerProductAdded &&
      retailerQuantity > 0 &&
      retailerBuyPrice > 0 &&
      retailerSellPrice > retailerBuyPrice &&
      (retailerHomeDelivery || retailerStoreCollection);

  void clearMessages() {
    errorMessage = null;
    noticeMessage = null;
  }

  void dismissMessages() {
    clearMessages();
    notifyListeners();
  }

  void showNotice(String message) {
    errorMessage = null;
    noticeMessage = message;
    notifyListeners();
  }

  void showError(String message) {
    errorMessage = message;
    noticeMessage = null;
    notifyListeners();
  }

  void setFilter(WorkFeedFilter value) {
    filter = value;
    clearMessages();
    notifyListeners();
  }

  void search(String value) {
    searchQuery = value;
    clearMessages();
    notifyListeners();
  }

  void updateWorkspaceSearch(String value) {
    workspaceSearchQuery = value;
    notifyListeners();
  }

  void setWorkspaceOrderFilter(String value) {
    workspaceOrderFilter = value;
    notifyListeners();
  }

  void setWorkspaceCustomerPeriod(String value) {
    workspaceCustomerPeriod = value;
    notifyListeners();
  }

  void setWorkspaceCustomerCustomPeriod(DateTime start, DateTime end) {
    workspaceCustomerPeriod = 'Custom';
    workspaceCustomerCustomStart = DateTime(start.year, start.month, start.day);
    workspaceCustomerCustomEnd = DateTime(end.year, end.month, end.day);
    notifyListeners();
  }

  void setWorkspaceMoneyPeriod(String value) {
    workspaceMoneyPeriod = value;
    notifyListeners();
  }

  bool prepareRepeatWorkspaceOrder() => prepareRepeatWorkspaceOrderFor();

  bool prepareRepeatWorkspaceOrderFor({String? customerId}) {
    final eligibleOrders = customerId == null
        ? visibleWorkspaceOrders
        : visibleWorkspaceOrders
              .where(
                (order) => workspaceCustomerId(order.customer) == customerId,
              )
              .toList(growable: false);
    final source =
        eligibleOrders
            .where((order) => order.stage == 'Completed')
            .firstOrNull ??
        eligibleOrders.firstOrNull;
    if (source == null) {
      showError('No previous basket is available for this customer yet.');
      return false;
    }
    final repeatQuantities = Map<String, int>.from(source.quantities);
    var unavailableLines = 0;
    if (repeatQuantities.isEmpty) {
      final lines = source.items
          .split(RegExp(r'\s+[·,]\s+'))
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty);
      for (final line in lines) {
        final quantity =
            int.tryParse(
              RegExp(r'×\s*(\d+)').firstMatch(line)?.group(1) ?? '',
            ) ??
            1;
        final words = line
            .replaceAll(RegExp(r'×\s*\d+'), '')
            .toLowerCase()
            .split(RegExp(r'[^a-z0-9]+'))
            .where((word) => word.length > 2)
            .toSet();
        final product = workspaceCatalogueItems.where((item) {
          final candidate = '${item.brand} ${item.title}'.toLowerCase();
          return words.isNotEmpty && words.every(candidate.contains);
        }).firstOrNull;
        if (product == null ||
            !product.available ||
            (product.stockMode == WorkspaceStockMode.exactQuantity &&
                product.stock <= 0)) {
          unavailableLines++;
          continue;
        }
        repeatQuantities[product.id] =
            product.stockMode == WorkspaceStockMode.availabilityOnly
            ? quantity.clamp(1, 99)
            : quantity.clamp(1, product.stock);
      }
    }
    for (final entry in repeatQuantities.entries.toList(growable: false)) {
      final product = workspaceCatalogueItems
          .where((item) => item.id == entry.key)
          .firstOrNull;
      if (product == null ||
          !product.available ||
          (product.stockMode == WorkspaceStockMode.exactQuantity &&
              product.stock <= 0)) {
        repeatQuantities.remove(entry.key);
        unavailableLines++;
        continue;
      }
      repeatQuantities[entry.key] =
          product.stockMode == WorkspaceStockMode.availabilityOnly
          ? entry.value.clamp(1, 99)
          : entry.value.clamp(1, product.stock);
    }
    if (repeatQuantities.isEmpty) {
      showError(
        'The previous basket is saved, but its products are not available in your current catalogue.',
      );
      return false;
    }
    if (!startNewWorkspaceOrder()) return false;
    workspaceOrderSource = 'Repeat order';
    workspaceOrderFulfilment = source.needsDelivery
        ? source.fulfilment
        : 'At the shop';
    workspaceOrderNeedsDelivery = source.needsDelivery;
    workspaceOrderCustomer = source.customer;
    workspaceOrderAddress = source.address;
    workspaceOrderQuantities.addAll(repeatQuantities);
    noticeMessage = unavailableLines == 0
        ? 'Previous basket added. Confirm quantities before completing the sale.'
        : 'Available products were added. Review the basket before completing the sale.';
    notifyListeners();
    return true;
  }

  void activateWorkspace(WorkWorkspace workspace) {
    if (hasPendingOrderTime) {
      showNotice('Confirm the time request before switching stores.');
      return;
    }
    final current = activeWorkspace;
    if (current == null || current.id == workspace.id) return;
    if (_collection?.needsReconciliation == true) {
      showNotice('Confirming this collection. Please wait for the update.');
      return;
    }
    if (busy ||
        workspaceOperationsSyncing ||
        workspaceHandoverBusy ||
        _collection?.busy == true) {
      showNotice('Finishing this store update. Please wait before switching.');
      return;
    }
    _rememberWorkspaceApplication();
    _clearWorkspaceApplication();
    _clearCollection();
    otherWorkspaces.removeWhere((item) => item.id == workspace.id);
    otherWorkspaces.add(current);
    activeWorkspace = workspace;
    workspaceId = workspace.id;
    workName = workspace.name;
    workArea = workspace.area;
    selectedProfile = workProfiles
        .where((profile) => profile.id == workspace.profileId)
        .firstOrNull;
    selectedFamilyId = selectedProfile?.familyId;
    reviewStage = WorkReviewStage.approved;
    remoteReviewStatus = WorkRemoteReviewStatus.approved;
    _queueContactDraft();
    clearMessages();
    notifyListeners();
  }

  Map<String, Object?> _operationalState() => {
    'storeState': workspaceStoreState.name,
    'acceptingOrders': workspaceAcceptingOrders,
    'visibleToCustomers': workspaceVisibleToCustomers,
    'fulfilmentMode': workspaceFulfilmentMode,
    'busyMinutes': workspaceBusyMinutes,
    'reopensAt': workspaceReopensAt,
    'openingTime': workspaceOpeningTime,
    'closingTime': workspaceClosingTime,
    'maximumActiveOrders': workspaceMaximumActiveOrders,
    'orderAlertSound': workspaceOrderAlertSound,
    'orderAlertVibration': workspaceOrderAlertVibration,
    'catalogue': [
      for (final product in workspaceCatalogueItems)
        {
          'id': product.id,
          'canonicalId': product.canonicalId,
          'categoryId': product.categoryId,
          'brand': product.brand,
          'title': product.title,
          'variant': product.variant,
          'pack': product.pack,
          'sku': product.sku,
          'barcode': product.barcode,
          'purchasePrice': product.purchasePrice,
          'sellingPrice': product.sellingPrice,
          'mrp': product.mrp,
          'stock': product.stock,
          'deliveryPromise': product.deliveryPromise,
          'origin': product.origin,
          'minimumOrder': product.minimumOrder,
          'returnPolicy': product.returnPolicy,
          'available': product.available,
          'publicListing': product.publicListing,
          'stockMode': product.stockMode.name,
          'lowStockThreshold': product.lowStockThreshold,
        },
    ],
    'stockMovements': [
      for (final movement in workspaceStockMovements)
        {
          'id': movement.id,
          'productId': movement.productId,
          'productLabel': movement.productLabel,
          'kind': movement.kind.name,
          'quantityDelta': movement.quantityDelta,
          'reason': movement.reason,
          'occurredAt': movement.occurredAt.toUtc().toIso8601String(),
        },
    ],
    'orders': [
      for (final order in workspaceOrders)
        {
          'id': order.id,
          'customer': order.customer,
          'items': order.items,
          'quantities': order.quantities,
          if (order.itemSnapshots.isNotEmpty)
            'itemSnapshots': [
              for (final line in order.itemSnapshots)
                {
                  'productId': line.productId,
                  'name': line.name,
                  'pack': line.pack,
                  'quantity': line.quantity,
                  'unitPricePaise': line.unitPricePaise,
                  'lineTotalPaise': line.lineTotalPaise,
                },
            ],
          'amount': order.amount,
          'source': order.source,
          'fulfilment': order.fulfilment,
          'payment': order.payment,
          'address': order.address,
          'stage': order.stage,
          if (order.rejectionReason != null)
            'rejectionReason': order.rejectionReason,
          'needsDelivery': order.needsDelivery,
          'createdAt': order.createdAt.toUtc().toIso8601String(),
          'actionDeadline': order.actionDeadline?.toUtc().toIso8601String(),
          if (order.fulfilmentDeadline != null)
            'fulfilmentDeadline': order.fulfilmentDeadline!
                .toUtc()
                .toIso8601String(),
          'extraMinutes': order.extraMinutes,
          'stockReserved': order.stockReserved,
          if (order.isCustomerCollection)
            'collectionStoreId': order.collectionStoreId,
        },
    ],
    'invoices': [
      for (final invoice in workspaceInvoices)
        {
          'id': invoice.id,
          'orderId': invoice.orderId,
          'customer': invoice.customer,
          'items': invoice.items,
          'amount': invoice.amount,
          'payment': invoice.payment,
          'issuedAt': invoice.issuedAt.toUtc().toIso8601String(),
          'sharedChannels': invoice.sharedChannels.toList(growable: false),
        },
    ],
    'deliveryRadiusKm': workspaceDeliveryRadiusKm,
    'deliveryFee': workspaceDeliveryFee,
    'freeDeliveryAbove': workspaceFreeDeliveryAbove,
    'deliveryCity': workspaceDeliveryCity,
    'deliveryArea': workspaceDeliveryArea,
    'deliveryPincode': workspaceDeliveryPincode,
    'pickupEnabled': workspacePickupEnabled,
    'staffAccessEnabled': workspaceStaffAccessEnabled,
    'counterCount': workspaceCounterCount,
    'salesToday': workspaceSalesToday,
    'completedSalesCount': workspaceCompletedSalesCount,
    'settlementBalance': workspaceSettlementBalance,
    'settlementRequested': workspaceSettlementRequested,
    'moolSocialFees': workspacePlatformAdjustments,
    'deliveryAdjustments': workspaceDeliveryAdjustments,
    'payoutBankName': workspacePayoutBankName,
    'payoutAccountEnding': workspacePayoutAccountEnding,
  };

  void _persistOperationalState(String reason) {
    if (_storeData.orderOperations != null) {
      // Never send a legacy whole-Store overwrite over authoritative per-order
      // data. Other operational domains require their scoped adapters first.
      workspaceOperationsSyncError =
          'These changes remain on this device. Store sync is not available yet.';
      notifyListeners();
      return;
    }
    final id = activeWorkspace?.id ?? workspaceId;
    if (id == null || id.isEmpty) return;
    final data = _storeData;
    final scope = _contactAccountScope;
    final snapshot = _operationalState();
    data.pendingOperationalRequests++;
    workspaceOperationsSyncing = true;
    workspaceOperationsSyncError = null;
    notifyListeners();
    final key = 'OPS-$id-${DateTime.now().microsecondsSinceEpoch}';
    unawaited(
      gateway
          .saveOperationalState(
            WorkOperationalSnapshot(
              workspaceId: id,
              reason: reason,
              state: snapshot,
              idempotencyKey: key,
            ),
          )
          .then((_) {
            if (!_isStoreScopeCurrent(data, id, scope)) return;
            workspaceOperationsSyncError = null;
          })
          .catchError((Object error) {
            if (!_isStoreScopeCurrent(data, id, scope)) return;
            workspaceOperationsSyncError = error is WorkGatewayException
                ? error.message
                : 'Store changes could not sync. Your draft remains on this device.';
          })
          .whenComplete(() => _finishOperationalRequest(data, id, scope)),
    );
  }

  void saveWorkspaceAvailability({
    required bool acceptingOrders,
    required String fulfilmentMode,
    required int busyMinutes,
    required String reopensAt,
  }) {
    workspaceAcceptingOrders = acceptingOrders;
    workspaceFulfilmentMode = fulfilmentMode;
    workspaceBusyMinutes = busyMinutes;
    workspaceReopensAt = acceptingOrders ? '' : reopensAt;
    workspaceStoreState = acceptingOrders
        ? WorkspaceStoreState.open
        : reopensAt.isEmpty
        ? WorkspaceStoreState.off
        : WorkspaceStoreState.paused;
    workspaceLastUpdatedAt = DateTime.now();
    _recordWorkspaceActivity(
      acceptingOrders
          ? busyMinutes > 0
                ? 'Store marked busy with $busyMinutes minutes extra preparation.'
                : 'Store opened for customer orders.'
          : 'New customer orders paused${reopensAt.isEmpty ? '.' : ' until $reopensAt.'}',
    );
    showNotice(
      acceptingOrders
          ? 'Store availability updated for customers.'
          : 'Store paused. Customers can see when ordering resumes.',
    );
    _persistOperationalState('availability');
  }

  void saveWorkspaceTradingControls({
    required String openingTime,
    required String closingTime,
    required int maximumActiveOrders,
    required bool alertSound,
    required bool alertVibration,
  }) {
    workspaceOpeningTime = openingTime.trim();
    workspaceClosingTime = closingTime.trim();
    workspaceMaximumActiveOrders = maximumActiveOrders.clamp(1, 100);
    workspaceOrderAlertSound = alertSound;
    workspaceOrderAlertVibration = alertVibration;
    _recordWorkspaceActivity('Store hours and order alerts updated.');
    _persistOperationalState('trading-controls');
    notifyListeners();
  }

  void dismissWorkspaceAlert(String alertId) {
    dismissedWorkspaceAlerts.add(alertId);
    notifyListeners();
  }

  void setWorkspacePackingLine(String id, bool packed) {
    if (currentWorkspaceOrder case final order?) {
      _preparePackingContents(order, workspacePackedProductIds);
    }
    if (packed) {
      workspacePackedProductIds.add(id);
    } else {
      workspacePackedProductIds.remove(id);
    }
    notifyListeners();
  }

  bool _packingContentsMatch(WorkspaceOrderRecord order) {
    final contents = _packingContentsByOrder[_orderScope(order.id)];
    return contents == null ||
        (contents.items == order.items &&
            mapEquals(contents.quantities, order.quantities));
  }

  void _preparePackingContents(
    WorkspaceOrderRecord order,
    Set<String> packedIds,
  ) {
    if (!_packingContentsMatch(order)) packedIds.clear();
    _packingContentsByOrder[_orderScope(order.id)] = (
      items: order.items,
      quantities: Map.of(order.quantities),
    );
  }

  bool setWorkspaceOrderPackingLine({
    required String? storeId,
    required String orderId,
    required String lineId,
    required int quantity,
    required bool packed,
  }) {
    if (storeId != (activeWorkspace?.id ?? workspaceId) ||
        busy ||
        workspaceOperationsSyncing ||
        workspaceHandoverBusy) {
      return false;
    }
    final order = visibleWorkspaceOrders
        .where((record) => record.id == orderId)
        .firstOrNull;
    if (order == null ||
        order.stage != 'Preparing' ||
        order.isCustomerCollection ||
        (isSelectedWorkspaceOrder(order) &&
            workspaceOrderStage != 'Preparing') ||
        !workspacePackingLinesForOrder(
          order,
        ).any((line) => line.id == lineId && line.quantity == quantity)) {
      return false;
    }
    final packedIds = isSelectedWorkspaceOrder(order)
        ? workspacePackedProductIds
        : _packingByOrder.putIfAbsent(_orderScope(orderId), () => <String>{});
    _preparePackingContents(order, packedIds);
    if (packed) {
      packedIds.add(lineId);
    } else {
      packedIds.remove(lineId);
    }
    notifyListeners();
    return true;
  }

  void saveWorkspaceDeliverySettings({
    required int radiusKm,
    required int fee,
    required int freeAbove,
    String? city,
    String? area,
    String? pincode,
    bool? pickupEnabled,
  }) {
    workspaceDeliveryRadiusKm = radiusKm.clamp(1, 50);
    workspaceDeliveryFee = fee.clamp(0, 10000);
    workspaceFreeDeliveryAbove = freeAbove.clamp(0, 1000000);
    workspaceDeliveryCity = city?.trim() ?? workspaceDeliveryCity;
    workspaceDeliveryArea = area?.trim() ?? workspaceDeliveryArea;
    workspaceDeliveryPincode = pincode?.trim() ?? workspaceDeliveryPincode;
    workspacePickupEnabled = pickupEnabled ?? workspacePickupEnabled;
    _recordWorkspaceActivity('Store delivery coverage and charges updated.');
    showNotice('Delivery area and customer charges updated.');
    _persistOperationalState('delivery-settings');
  }

  void saveWorkspaceStaffSettings({
    required bool staffAccessEnabled,
    required int counterCount,
  }) {
    workspaceStaffAccessEnabled = staffAccessEnabled;
    workspaceCounterCount = counterCount.clamp(1, 20);
    _recordWorkspaceActivity('Store counter and staff access updated.');
    showNotice('Staff and counter settings updated.');
    _persistOperationalState('staff-settings');
  }

  WorkspaceCustomerInvoice _createInvoice(WorkspaceOrderRecord order) {
    final existing = workspaceInvoices
        .where((invoice) => invoice.orderId == order.id)
        .firstOrNull;
    if (existing != null) return existing;
    final invoice = WorkspaceCustomerInvoice(
      id: 'INV-${DateTime.now().millisecondsSinceEpoch}',
      orderId: order.id,
      customer: order.customer,
      items: order.items,
      amount: order.amount,
      payment: order.payment,
      issuedAt: DateTime.now(),
    );
    workspaceInvoices.insert(0, invoice);
    _recordWorkspaceActivity(
      'Invoice ${invoice.id} created for ${invoice.customer}.',
    );
    return invoice;
  }

  WorkspaceCustomerInvoice? completeWorkspaceCounterSale() {
    if (!_canEditCounterOrder()) {
      return null;
    }
    final completedInvoice = workspaceInvoices
        .where((invoice) => invoice.orderId == currentWorkspaceOrderId)
        .firstOrNull;
    if (completedInvoice != null) return completedInvoice;
    if (workspaceOrderQuantities.isEmpty ||
        workspaceOrderCustomer.trim().isEmpty ||
        workspaceOrderTotal <= 0) {
      showError('Add a customer and products before creating the invoice.');
      return null;
    }
    var order = _ensureCurrentOrderRecord();
    if (!order.stockReserved) {
      if (!_reserveOrderStock(order)) return null;
      order = order.copyWith(stockReserved: true);
    }
    workspaceOrderStage = 'Completed';
    workspaceOrderActionDeadline = null;
    final index = workspaceOrders.indexWhere((item) => item.id == order.id);
    final completed = order.copyWith(stage: 'Completed', stockReserved: true);
    if (index >= 0) workspaceOrders[index] = completed;
    workspaceSalesToday += order.amount;
    // A counter invoice records a sale, not money collected by MoolSocial.
    // Settlement remains the authoritative balance supplied for the Store.
    workspaceCompletedSalesCount++;
    final invoice = _createInvoice(completed);
    showNotice('Sale completed. Invoice ${invoice.id} is ready to send.');
    _persistOperationalState('counter-sale-completed');
    notifyListeners();
    return invoice;
  }

  void markWorkspaceInvoiceShared(String invoiceId, String channel) {
    final index = workspaceInvoices.indexWhere(
      (invoice) => invoice.id == invoiceId,
    );
    if (index < 0) return;
    final invoice = workspaceInvoices[index];
    workspaceInvoices[index] = invoice.copyWith(
      sharedChannels: {...invoice.sharedChannels, channel},
    );
    _recordWorkspaceActivity(
      '${invoice.id} sent through $channel and added to the customer relationship history.',
    );
    showNotice('Invoice ready in $channel. Customer history is updated.');
    _persistOperationalState('invoice-shared');
  }

  void setWorkspaceVisibility(bool visible) {
    workspaceVisibleToCustomers = visible;
    workspaceLastUpdatedAt = DateTime.now();
    _recordWorkspaceActivity(
      visible
          ? 'Store published for customer discovery.'
          : 'Store removed from customer discovery.',
    );
    showNotice(
      visible
          ? 'Your store is now visible to customers.'
          : 'Your store is hidden from customer discovery.',
    );
    _persistOperationalState('visibility');
  }

  void setWorkspaceDashboardState(
    WorkspaceDashboardState state, {
    String error = '',
    DateTime? lastUpdatedAt,
  }) {
    workspaceDashboardState = state;
    workspaceDashboardError = error.trim();
    workspaceLastUpdatedAt = lastUpdatedAt ?? workspaceLastUpdatedAt;
    notifyListeners();
  }

  void retryWorkspaceDashboard() {
    // No operational-feed reader is connected yet. Application-review data
    // cannot refresh orders, stock or payments, and a spinner is not a request.
    setWorkspaceDashboardState(
      WorkspaceDashboardState.failed,
      error:
          'Live store updates are unavailable. Your saved records are unchanged.',
    );
  }

  bool saveWorkspaceOrderDraft({
    required String customer,
    required String source,
    required String fulfilment,
    required String payment,
    required String address,
  }) {
    if (!_canEditCounterOrder()) return false;
    if (workspaceInvoices.any(
      (invoice) => invoice.orderId == currentWorkspaceOrderId,
    )) {
      showNotice('This sale is complete. Start a new bill for another sale.');
      return false;
    }
    workspaceOrderCustomer = customer.trim();
    workspaceOrderSource = source;
    workspaceOrderFulfilment = fulfilment;
    workspaceOrderPayment = payment;
    workspaceOrderAddress = address.trim();
    workspaceOrderNeedsDelivery = const {
      'Mool delivery',
      'Own delivery',
    }.contains(fulfilment);
    workspaceOrderItems = workspaceCatalogueItems
        .where((product) => (workspaceOrderQuantities[product.id] ?? 0) > 0)
        .map(
          (product) =>
              '${product.title} × ${workspaceOrderQuantities[product.id]}',
        )
        .join(', ');
    workspaceOrderAmount = '$workspaceOrderTotal';
    workspaceOrderStage = 'Confirmed';
    workspaceOrderExtraMinutes = 0;
    workspacePackedProductIds.clear();
    // A locally recorded sale is not a server-assigned acceptance window.
    workspaceOrderActionDeadline = null;
    final orderId =
        currentWorkspaceOrderId ??
        'ORD-${DateTime.now().microsecondsSinceEpoch}';
    currentWorkspaceOrderId = orderId;
    final record = WorkspaceOrderRecord(
      id: orderId,
      customer: workspaceOrderCustomer,
      items: workspaceOrderItems,
      quantities: Map<String, int>.from(workspaceOrderQuantities),
      amount: workspaceOrderTotal,
      source: workspaceOrderSource,
      fulfilment: workspaceOrderFulfilment,
      payment: workspaceOrderPayment,
      address: workspaceOrderAddress,
      stage: workspaceOrderStage,
      needsDelivery: workspaceOrderNeedsDelivery,
      createdAt: DateTime.now(),
      actionDeadline: workspaceOrderActionDeadline,
    );
    final existingIndex = workspaceOrders.indexWhere(
      (order) => order.id == orderId,
    );
    if (existingIndex == -1) {
      workspaceOrders.insert(0, record);
    } else {
      workspaceOrders[existingIndex] = record;
    }
    _recordWorkspaceActivity(
      '$source order saved · $workspaceOrderItemCount products · ₹$workspaceOrderTotal.',
    );
    showNotice(
      workspaceOrderNeedsDelivery
          ? 'Order saved. Add the delivery address when the customer confirms.'
          : 'Counter order saved for customer confirmation.',
    );
    _persistOperationalState('order-created');
    return true;
  }

  // Counter editing must never rewrite an incoming order's purchased facts.
  // Inspect the stored order, not the mutable composer source/stage fields.
  bool _canEditCounterOrder({bool allowCompletedInvoice = true}) {
    if (hasPendingOrderTime ||
        busy ||
        workspaceHandoverBusy ||
        _collection?.busy == true ||
        _collection?.needsReconciliation == true) {
      showError('Wait for the current order update before changing this bill.');
      return false;
    }
    final order = currentWorkspaceOrder;
    if (currentWorkspaceOrderId != null && order == null) {
      showError(
        'This order is unavailable. Start a new bill for a counter sale.',
      );
      return false;
    }
    if (order == null) return true;
    if (order.source == 'App' || order.isCustomerCollection) {
      showError(
        'Use this order’s actions. Start a new bill for a counter sale.',
      );
      return false;
    }
    if (allowCompletedInvoice &&
        order.stage == 'Completed' &&
        workspaceInvoices.any((invoice) => invoice.orderId == order.id)) {
      return true; // A duplicate completion may return its existing invoice.
    }
    if (order.stage != 'Confirmed' || order.stockReserved) {
      showError(
        'This order cannot be edited. Start a new bill for another sale.',
      );
      return false;
    }
    return true;
  }

  WorkspaceOrderRecord _ensureCurrentOrderRecord() {
    final existing = currentWorkspaceOrder;
    if (existing != null) return existing;
    final id =
        currentWorkspaceOrderId ??
        'ORD-${DateTime.now().microsecondsSinceEpoch}';
    currentWorkspaceOrderId = id;
    final created = WorkspaceOrderRecord(
      id: id,
      customer: workspaceOrderCustomer,
      items: workspaceOrderItems,
      quantities: Map<String, int>.from(workspaceOrderQuantities),
      amount: int.tryParse(workspaceOrderAmount) ?? 0,
      source: workspaceOrderSource,
      fulfilment: workspaceOrderFulfilment,
      payment: workspaceOrderPayment,
      address: workspaceOrderAddress,
      stage: workspaceOrderStage,
      needsDelivery: workspaceOrderNeedsDelivery,
      createdAt: DateTime.now(),
      actionDeadline: workspaceOrderActionDeadline,
    );
    workspaceOrders.insert(0, created);
    return created;
  }

  bool _reserveOrderStock(WorkspaceOrderRecord order) {
    for (final entry in order.quantities.entries) {
      final product = workspaceCatalogueItems
          .where((item) => item.id == entry.key)
          .firstOrNull;
      if (product == null ||
          !product.available ||
          (product.stockMode == WorkspaceStockMode.exactQuantity &&
              product.stock < entry.value)) {
        showError(
          product == null
              ? 'A product in this order is no longer in the catalogue.'
              : product.stockMode == WorkspaceStockMode.availabilityOnly
              ? '${product.title} is currently unavailable.'
              : '${product.title} has only ${product.stock} available.',
        );
        return false;
      }
    }
    for (final entry in order.quantities.entries) {
      final index = workspaceCatalogueItems.indexWhere(
        (item) => item.id == entry.key,
      );
      if (index < 0) continue;
      final product = workspaceCatalogueItems[index];
      if (product.stockMode == WorkspaceStockMode.availabilityOnly) continue;
      workspaceCatalogueItems[index] = product.copyWith(
        stock: product.stock - entry.value,
        available: product.stock - entry.value > 0,
      );
      _recordWorkspaceStockMovement(
        product: product,
        kind: WorkspaceStockMovementKind.sale,
        quantityDelta: -entry.value,
        reason: 'Reserved for ${order.id}',
      );
    }
    return true;
  }

  void _releaseOrderStock(WorkspaceOrderRecord order) {
    for (final entry in order.quantities.entries) {
      final index = workspaceCatalogueItems.indexWhere(
        (item) => item.id == entry.key,
      );
      if (index < 0) continue;
      final product = workspaceCatalogueItems[index];
      if (product.stockMode == WorkspaceStockMode.availabilityOnly) continue;
      workspaceCatalogueItems[index] = product.copyWith(
        stock: product.stock + entry.value,
        available: true,
      );
      _recordWorkspaceStockMovement(
        product: product,
        kind: WorkspaceStockMovementKind.returned,
        quantityDelta: entry.value,
        reason: 'Released after ${order.id} was cancelled',
      );
    }
  }

  void advanceWorkspaceOrder() {
    final scopedId = currentWorkspaceOrderId;
    if (scopedId != null && hasScopedWorkspaceOrder(scopedId)) {
      final action = switch (currentWorkspaceOrder?.stage) {
        'Confirmed' => WorkOrderAction.accept,
        'Preparing' => WorkOrderAction.ready,
        _ => null,
      };
      if (action != null) {
        unawaited(submitWorkspaceOrderAction(scopedId, action));
      }
      return;
    }
    if (hasPendingOrderTime) {
      showError('Confirm the time request before accepting this order.');
      return;
    }
    if (currentWorkspaceOrder?.isCustomerCollection == true) {
      showError('Use the collection card for this paid order.');
      return;
    }
    final previous = workspaceOrderStage;
    final current = currentWorkspaceOrder;
    if (current != null && current.stage != previous) {
      showError('This order has changed. Review its current status.');
      return;
    }
    if (!const {
      'Confirmed',
      'Preparing',
      'Ready',
      'Ready for pickup',
      'Delivery requested',
    }.contains(previous)) {
      return;
    }
    final acceptanceDeadline =
        current?.actionDeadline ?? workspaceOrderActionDeadline;
    if (previous == 'Confirmed' &&
        acceptanceDeadline != null &&
        !acceptanceDeadline.isAfter(DateTime.now())) {
      showError('Acceptance time ended. Waiting for an order update.');
      return;
    }
    var order = _ensureCurrentOrderRecord();
    if (previous == 'Confirmed' && !order.stockReserved) {
      if (!_reserveOrderStock(order)) return;
      order = order.copyWith(stockReserved: true);
    }
    if (previous == 'Delivery requested') {
      showError('Confirm the customer delivery OTP before handover.');
      return;
    }
    if (previous == 'Preparing' && !workspacePackingComplete) {
      showError('Mark every product packed before the order is ready.');
      return;
    }
    if (previous == 'Ready for pickup') {
      _completeWorkspaceOrder(order, activity: 'Customer pickup confirmed.');
      return;
    }
    if (previous == 'Ready' &&
        workspaceOrderNeedsDelivery &&
        workspaceOrderAddress.trim().isEmpty) {
      showError('Add the confirmed customer delivery address first.');
      return;
    }
    workspaceOrderStage = switch (previous) {
      'Confirmed' => 'Preparing',
      'Preparing' when workspaceOrderNeedsDelivery => 'Ready',
      'Preparing' => 'Ready for pickup',
      'Ready' when workspaceOrderNeedsDelivery => 'Delivery requested',
      'Ready' => 'Completed',
      'Delivery requested' => 'Delivery requested',
      _ => workspaceOrderStage,
    };
    // Keep an authoritative target when supplied. Accepting or packing an
    // order must not manufacture a new delivery promise or reset the clock.
    workspaceOrderActionDeadline = switch (workspaceOrderStage) {
      'Preparing' || 'Ready' || 'Ready for pickup' => order.fulfilmentDeadline,
      'Delivery requested' => workspaceDeliveryAssignment?.eta,
      _ => null,
    };
    order = order.copyWith(
      stage: workspaceOrderStage,
      actionDeadline: workspaceOrderActionDeadline,
      clearActionDeadline: workspaceOrderActionDeadline == null,
      stockReserved: order.stockReserved || previous == 'Confirmed',
    );
    final orderIndex = workspaceOrders.indexWhere(
      (item) => item.id == order.id,
    );
    if (orderIndex >= 0) workspaceOrders[orderIndex] = order;
    if (workspaceOrderStage == 'Completed' && previous != 'Completed') {
      final amount = int.tryParse(workspaceOrderAmount) ?? 0;
      workspaceSalesToday += amount;
      workspaceSettlementBalance += amount;
      workspaceCompletedSalesCount++;
    }
    _recordWorkspaceActivity('Order moved to $workspaceOrderStage.');
    showNotice('Order is now ${workspaceOrderStage.toLowerCase()}.');
    _persistOperationalState('order-$workspaceOrderStage');
    if (workspaceOrderStage == 'Delivery requested') {
      unawaited(_requestWorkspaceDeliveryAssignment(order.id));
    }
  }

  WorkspaceCustomerInvoice _completeWorkspaceOrder(
    WorkspaceOrderRecord order, {
    required String activity,
  }) {
    if (order.isCustomerCollection) {
      throw StateError('Customer collection requires authoritative completion');
    }
    workspaceOrderStage = 'Completed';
    workspaceOrderActionDeadline = null;
    final index = workspaceOrders.indexWhere((item) => item.id == order.id);
    final completed = order.copyWith(stage: 'Completed');
    if (index >= 0) workspaceOrders[index] = completed;
    workspaceSalesToday += order.amount;
    workspaceSettlementBalance += order.amount;
    workspaceCompletedSalesCount++;
    final invoice = _createInvoice(completed);
    _recordWorkspaceActivity(activity);
    showNotice('Order completed. Invoice ${invoice.id} is ready.');
    _persistOperationalState('order-completed');
    notifyListeners();
    return invoice;
  }

  Future<void> _requestWorkspaceDeliveryAssignment(String orderId) async {
    if (hasScopedWorkspaceOrder(orderId)) {
      showError('Delivery updates for this order are not available yet.');
      return;
    }
    final id = activeWorkspace?.id ?? workspaceId;
    if (id == null || id.isEmpty) return;
    final data = _storeData;
    final scope = _contactAccountScope;
    bool current() =>
        _isStoreScopeCurrent(data, id, scope) &&
        currentWorkspaceOrderId == orderId;
    data.pendingOperationalRequests++;
    workspaceOperationsSyncing = true;
    notifyListeners();
    try {
      final result = await gateway.requestDeliveryAssignment(
        workspaceId: id,
        orderId: orderId,
        address: workspaceOrderAddress,
        idempotencyKey:
            'DEL-$id-$orderId-${DateTime.now().microsecondsSinceEpoch}',
      );
      if (!current()) return;
      workspaceDeliveryAssignment = WorkspaceDeliveryAssignment(
        orderId: orderId,
        partnerName: result.partnerName,
        vehicleLabel: result.vehicleLabel,
        eta: result.eta,
        stage: result.stage,
      );
      workspaceOrderActionDeadline = result.eta;
      showNotice('Delivery partner assigned. Track arrival at your store.');
    } on WorkGatewayException catch (error) {
      if (current()) {
        workspaceOperationsSyncError = error.message;
        showError(error.message);
      }
    } finally {
      _finishOperationalRequest(data, id, scope);
    }
  }

  Future<bool> verifyWorkspaceHandover(String otp) async {
    if (hasScopedWorkspaceOrder(currentWorkspaceOrderId ?? '')) {
      showError('Handover confirmation for this order is not available yet.');
      return false;
    }
    if (currentWorkspaceOrder?.isCustomerCollection == true) return false;
    final id = activeWorkspace?.id ?? workspaceId;
    final order = currentWorkspaceOrder;
    if (id == null || id.isEmpty || order == null || workspaceHandoverBusy) {
      return false;
    }
    final normalized = otp.replaceAll(RegExp(r'\D'), '');
    if (normalized.length != 6) {
      showError('Enter the 6-digit delivery OTP shared by the customer.');
      return false;
    }
    final data = _storeData;
    final scope = _contactAccountScope;
    bool current() =>
        _isStoreScopeCurrent(data, id, scope) &&
        currentWorkspaceOrderId == order.id;
    workspaceHandoverBusy = true;
    clearMessages();
    notifyListeners();
    try {
      await gateway.verifyOrderHandover(
        workspaceId: id,
        orderId: order.id,
        otp: normalized,
        idempotencyKey:
            'HANDOVER-$id-${order.id}-${DateTime.now().microsecondsSinceEpoch}',
      );
      if (!current()) return false;
      _completeWorkspaceOrder(
        order,
        activity: 'Order handover confirmed by customer OTP.',
      );
      return true;
    } on WorkGatewayException catch (error) {
      if (current()) showError(error.message);
      return false;
    } finally {
      data.workspaceHandoverBusy = false;
      if (current()) notifyListeners();
    }
  }

  Future<bool> verifyWorkspacePickup(String code) async {
    if (hasScopedWorkspaceOrder(currentWorkspaceOrderId ?? '')) {
      showError('Collection confirmation for this order is not available yet.');
      return false;
    }
    if (currentWorkspaceOrder?.isCustomerCollection == true) return false;
    final id = activeWorkspace?.id ?? workspaceId;
    final order = currentWorkspaceOrder;
    if (id == null ||
        id.isEmpty ||
        order == null ||
        workspaceOrderStage != 'Ready for pickup' ||
        workspaceHandoverBusy) {
      return false;
    }
    final normalized = code.replaceAll(RegExp(r'\D'), '');
    if (normalized.length != 6) {
      showError('Enter the 6-digit pickup code shared with the customer.');
      return false;
    }
    final data = _storeData;
    final scope = _contactAccountScope;
    bool current() =>
        _isStoreScopeCurrent(data, id, scope) &&
        currentWorkspaceOrderId == order.id;
    workspaceHandoverBusy = true;
    clearMessages();
    notifyListeners();
    try {
      await gateway.verifyOrderHandover(
        workspaceId: id,
        orderId: order.id,
        otp: normalized,
        idempotencyKey:
            'PICKUP-$id-${order.id}-${DateTime.now().microsecondsSinceEpoch}',
      );
      if (!current()) return false;
      _completeWorkspaceOrder(
        order,
        activity: 'Customer pickup confirmed with the order pickup code.',
      );
      return true;
    } on WorkGatewayException catch (error) {
      if (current()) {
        showError(error.message.replaceAll('delivery OTP', 'pickup code'));
      }
      return false;
    } finally {
      data.workspaceHandoverBusy = false;
      if (current()) notifyListeners();
    }
  }

  Future<void> retryWorkspaceDeliveryAssignment() async {
    final order = currentWorkspaceOrder;
    if (order == null ||
        workspaceOrderStage != 'Delivery requested' ||
        workspaceOperationsSyncing) {
      return;
    }
    workspaceOperationsSyncError = null;
    await _requestWorkspaceDeliveryAssignment(order.id);
  }

  Future<void> requestWorkspaceSettlement({int? amount}) async {
    final eligible = workspaceSettlementEligible;
    if (eligible <= 0) {
      showError('No completed-sale balance is available for settlement yet.');
      return;
    }
    final requestedAmount = (amount ?? eligible).clamp(1, eligible).toInt();
    final id = activeWorkspace?.id ?? workspaceId;
    if (id == null || id.isEmpty || busy) return;
    final data = _storeData;
    final scope = _contactAccountScope;
    bool current() => _isStoreScopeCurrent(data, id, scope);
    final token = _beginBusyStoreOperation();
    clearMessages();
    notifyListeners();
    try {
      final result = await gateway.requestSettlement(
        workspaceId: id,
        amount: requestedAmount,
        idempotencyKey: 'SET-$id-${DateTime.now().microsecondsSinceEpoch}',
      );
      if (!current()) return;
      final accepted = result.acceptedAmount.clamp(0, requestedAmount).toInt();
      workspaceSettlementRequested += accepted;
      final remaining = workspaceSettlementBalance - accepted;
      workspaceSettlementBalance = remaining < 0 ? 0 : remaining;
      workspaceSettlementReference = result.reference;
      _recordWorkspaceActivity(
        'Settlement ${result.reference} requested for ₹$accepted.',
      );
      showNotice('Settlement request received for processing.');
      _persistOperationalState('settlement-requested');
    } on WorkGatewayException catch (error) {
      if (current()) showError(error.message);
    } finally {
      _finishBusyStoreOperation(token);
    }
  }

  void addWorkspaceOffer({
    required String title,
    required String detail,
    required DateTime validUntil,
    String? productId,
    String audience = 'Customers who allow Store offers',
    int orderCap = 0,
  }) {
    if (gateway is! ReviewWorkGateway) {
      showError(
        'Offer publishing is not available yet. Your details are still here.',
      );
      return;
    }
    workspaceOffers.insert(
      0,
      WorkspaceStoreOffer(
        id: 'OFFER-${DateTime.now().millisecondsSinceEpoch}',
        title: title.trim(),
        detail: detail.trim(),
        validUntil: validUntil,
        active: true,
        productId: productId,
        audience: audience,
        orderCap: orderCap,
      ),
    );
    _recordWorkspaceActivity('Store offer published: ${title.trim()}.');
    showNotice('Offer published for your Store customers.');
    _persistOperationalState('offer-published');
  }

  Future<bool> createWorkspacePaidRequirement({
    required String position,
    required String work,
    required String candidateRequirement,
    required String location,
    required int peopleNeeded,
    required int paymentAmount,
    required String paymentFormat,
    required DateTime deadline,
  }) async {
    final id = activeWorkspace?.id ?? workspaceId;
    if (id == null || id.isEmpty || busy) return false;
    final data = _storeData;
    final scope = _contactAccountScope;
    bool current() => _isStoreScopeCurrent(data, id, scope);
    final token = _beginBusyStoreOperation();
    clearMessages();
    notifyListeners();
    try {
      final reference = await gateway.createPaidRequirement(
        WorkPaidRequirementSubmission(
          workspaceId: id,
          values: {
            'position': position.trim(),
            'work': work.trim(),
            'candidateRequirement': candidateRequirement.trim(),
            'location': location.trim(),
            'peopleNeeded': peopleNeeded,
            'paymentAmount': paymentAmount,
            'paymentFormat': paymentFormat,
            'deadline': deadline.toUtc().toIso8601String(),
            'funded': true,
            'publisherType': 'workspace',
          },
          idempotencyKey:
              'WORK-REQ-$id-${DateTime.now().microsecondsSinceEpoch}',
        ),
      );
      if (!current()) return false;
      workspacePaidRequirementReference = reference;
      workspacePaidRequirementState = WorkspacePaidRequirementState.published;
      _recordWorkspaceActivity('Paid work $reference published for $position.');
      showNotice('Paid work published to Earn Today.');
      _persistOperationalState('paid-work-published');
      return true;
    } on WorkGatewayException catch (error) {
      if (current()) showError(error.message);
      return false;
    } finally {
      _finishBusyStoreOperation(token);
    }
  }

  void extendWorkspaceOrder(int minutes) {
    unawaited(
      requestWorkspaceOrderTime(currentWorkspaceOrderId ?? '', minutes),
    );
  }

  void cancelWorkspaceOrder({String? reason}) {
    final scopedId = currentWorkspaceOrderId;
    if (scopedId != null && hasScopedWorkspaceOrder(scopedId)) {
      unawaited(
        submitWorkspaceOrderAction(
          scopedId,
          WorkOrderAction.reject,
          reason: reason,
        ),
      );
      return;
    }
    if (hasPendingOrderTime) {
      showError('Confirm the time request before changing this order.');
      return;
    }
    final order = _ensureCurrentOrderRecord();
    if (order.stockReserved) _releaseOrderStock(order);
    workspaceOrderStage = 'Cancelled';
    final index = workspaceOrders.indexWhere((item) => item.id == order.id);
    if (index >= 0) {
      workspaceOrders[index] = order.copyWith(
        stage: 'Cancelled',
        stockReserved: false,
        rejectionReason: reason?.trim(),
      );
    }
    _recordWorkspaceActivity('Customer order cancelled.');
    showNotice('Order cancelled. Stock remains available.');
    _persistOperationalState('order-cancelled');
  }

  bool startNewWorkspaceOrder() {
    if (hasPendingOrderTime ||
        busy ||
        workspaceHandoverBusy ||
        _collection?.busy == true ||
        _collection?.needsReconciliation == true) {
      showNotice(
        'Wait for the current order update before starting a new bill.',
      );
      return false;
    }
    _rememberActiveOrder();
    _clearCollection();
    workspaceOrderCustomer = '';
    workspaceOrderItems = '';
    workspaceOrderAmount = '';
    workspaceOrderNeedsDelivery = false;
    workspaceOrderSource = 'Counter';
    workspaceOrderFulfilment = 'At the shop';
    workspaceOrderPayment = 'Cash';
    workspaceOrderAddress = '';
    workspaceOrderStage = 'No order';
    workspaceOrderExtraMinutes = 0;
    workspaceOrderActionDeadline = null;
    workspacePackedProductIds.clear();
    workspaceDeliveryAssignment = null;
    currentWorkspaceOrderId = null;
    workspaceOrderQuantities.clear();
    clearMessages();
    notifyListeners();
    return true;
  }

  void _recordWorkspaceStockMovement({
    required WorkspaceCatalogueItem product,
    required WorkspaceStockMovementKind kind,
    required int quantityDelta,
    required String reason,
  }) {
    if (quantityDelta == 0) return;
    workspaceStockMovements.insert(
      0,
      WorkspaceStockMovement(
        id: 'STK-${DateTime.now().microsecondsSinceEpoch}',
        productId: product.id,
        productLabel: '${product.title} · ${product.pack}',
        kind: kind,
        quantityDelta: quantityDelta,
        reason: reason,
        occurredAt: DateTime.now(),
      ),
    );
    if (workspaceStockMovements.length > 100) {
      workspaceStockMovements.removeRange(100, workspaceStockMovements.length);
    }
  }

  void addOrUpdateWorkspaceProduct(
    WorkspaceCatalogueItem product, {
    String stockReason = 'Product quantity updated',
  }) {
    final index = workspaceCatalogueItems.indexWhere(
      (item) => item.id == product.id,
    );
    if (index == -1) {
      workspaceCatalogueItems.add(product);
      _recordWorkspaceActivity('${product.title} added to your catalogue.');
      _recordWorkspaceStockMovement(
        product: product,
        kind: WorkspaceStockMovementKind.openingStock,
        quantityDelta: product.stock,
        reason: 'Opening quantity',
      );
    } else {
      final previous = workspaceCatalogueItems[index];
      workspaceCatalogueItems[index] = product;
      _recordWorkspaceActivity('${product.title} price and stock updated.');
      _recordWorkspaceStockMovement(
        product: product,
        kind: WorkspaceStockMovementKind.adjustment,
        quantityDelta: product.stock - previous.stock,
        reason: stockReason,
      );
    }
    retailerProductAdded = workspaceCatalogueItems.isNotEmpty;
    if (workspaceCatalogueItems.isNotEmpty) {
      final first = workspaceCatalogueItems.first;
      retailerQuantity = first.stock;
      retailerBuyPrice = first.purchasePrice;
      retailerSellPrice = first.sellingPrice;
    }
    showNotice(
      product.publicListing
          ? '${product.title} is ready for store publishing.'
          : '${product.title} saved for store use only.',
    );
    _persistOperationalState('catalogue-updated');
  }

  void importWorkspaceProducts(List<WorkspaceCatalogueItem> products) {
    for (final product in products) {
      final index = workspaceCatalogueItems.indexWhere(
        (item) => item.id == product.id || item.sku == product.sku,
      );
      if (index < 0) {
        workspaceCatalogueItems.add(product);
        _recordWorkspaceStockMovement(
          product: product,
          kind: WorkspaceStockMovementKind.goodsReceived,
          quantityDelta: product.stock,
          reason: 'Imported product quantity',
        );
      } else {
        final previous = workspaceCatalogueItems[index];
        workspaceCatalogueItems[index] = product;
        _recordWorkspaceStockMovement(
          product: product,
          kind: WorkspaceStockMovementKind.goodsReceived,
          quantityDelta: product.stock - previous.stock,
          reason: 'Imported product quantity',
        );
      }
    }
    retailerProductAdded = workspaceCatalogueItems.isNotEmpty;
    _recordWorkspaceActivity('${products.length} catalogue products imported.');
    showNotice('${products.length} products imported into your catalogue.');
    _persistOperationalState('catalogue-imported');
  }

  void retireWorkspaceProduct(String productId) {
    final index = workspaceCatalogueItems.indexWhere(
      (product) => product.id == productId,
    );
    if (index < 0) return;
    final product = workspaceCatalogueItems[index];
    workspaceCatalogueItems[index] = product.copyWith(
      available: false,
      publicListing: false,
      stock: 0,
    );
    _recordWorkspaceStockMovement(
      product: product,
      kind: WorkspaceStockMovementKind.adjustment,
      quantityDelta: -product.stock,
      reason: 'Removed from active catalogue',
    );
    _recordWorkspaceActivity('${product.title} removed from active catalogue.');
    showNotice('${product.title} is no longer shown to customers.');
    _persistOperationalState('catalogue-retired');
  }

  bool updateWorkspaceStock({
    required String productId,
    required int quantity,
    required String reason,
    WorkspaceStockMovementKind kind = WorkspaceStockMovementKind.adjustment,
  }) {
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) {
      showError('Choose why the quantity changed.');
      return false;
    }
    final index = workspaceCatalogueItems.indexWhere(
      (product) => product.id == productId,
    );
    if (index < 0) {
      showError('This product is no longer in your catalogue.');
      return false;
    }
    final product = workspaceCatalogueItems[index];
    final nextQuantity = quantity.clamp(0, 1 << 31).toInt();
    workspaceCatalogueItems[index] = product.copyWith(
      stock: nextQuantity,
      available: product.stockMode == WorkspaceStockMode.availabilityOnly
          ? product.available
          : nextQuantity > 0,
    );
    _recordWorkspaceStockMovement(
      product: product,
      kind: kind,
      quantityDelta: nextQuantity - product.stock,
      reason: cleanReason,
    );
    _recordWorkspaceActivity('${product.title} quantity updated.');
    showNotice('${product.title} quantity is now $nextQuantity.');
    _persistOperationalState('stock-adjusted');
    notifyListeners();
    return true;
  }

  void adjustWorkspaceOrderQuantity(String productId, int change) {
    if (!_canEditCounterOrder(allowCompletedInvoice: false)) return;
    final product = workspaceCatalogueItems
        .where((item) => item.id == productId)
        .firstOrNull;
    if (product == null) return;
    final current = workspaceOrderQuantities[productId] ?? 0;
    final maximum = product.stockMode == WorkspaceStockMode.availabilityOnly
        ? 99
        : product.stock;
    final next = (current + change).clamp(0, maximum);
    if (next == 0) {
      workspaceOrderQuantities.remove(productId);
    } else {
      workspaceOrderQuantities[productId] = next;
    }
    clearMessages();
    notifyListeners();
  }

  void _recordWorkspaceActivity(String message) {
    workspaceActivity.insert(
      0,
      WorkspaceActivityEntry(message: message, time: DateTime.now()),
    );
    if (workspaceActivity.length > 8) workspaceActivity.removeLast();
  }

  void setOpportunityLocationFilters({
    String? city,
    String? area,
    String? pincode,
  }) {
    selectedCity = city?.trim() ?? '';
    selectedArea = area?.trim() ?? '';
    selectedPincode = pincode?.trim() ?? '';
    clearMessages();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _workspaceApplications.clear();
    _clearCollection();
    for (final data in {..._storeDataById.values, _storeData}) {
      final operations = data.orderOperations;
      if (operations != null && !operations.isDisposed) operations.dispose();
    }
    _storeDataById.clear();
    _storeData = _StoreOperationalData();
    _busyStoreOperation = null;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  void clearOpportunityFilters() {
    selectedCity = '';
    selectedArea = '';
    selectedPincode = '';
    clearMessages();
    notifyListeners();
  }

  Future<void> refreshFeed() async {
    if (busy ||
        workspaceOperationsSyncing ||
        workspaceHandoverBusy ||
        _collection?.busy == true ||
        _collection?.needsReconciliation == true) {
      return;
    }
    final requestedScope = _contactAccountScope;
    bool current() => !_disposed && requestedScope == _contactAccountScope;
    busy = true;
    clearMessages();
    notifyListeners();
    try {
      final records = await gateway.loadFeed();
      if (!current()) return;
      _restoreWorkspaceState(records);
      initialWorkspaceStateLoaded = true;
      noticeMessage = 'Work opportunities refreshed.';
    } on WorkGatewayException catch (error) {
      if (current()) errorMessage = error.message;
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> loadInitialWorkspaceState() async {
    if (initialWorkspaceStateLoaded || busy) return;
    await refreshFeed();
    if (noticeMessage == 'Work opportunities refreshed.') {
      clearMessages();
      notifyListeners();
    }
  }

  void toggleOpportunity(String id) {
    expandedOpportunityId = expandedOpportunityId == id ? null : id;
    notifyListeners();
  }

  void openOpportunity(String id) {
    final opportunity = workOpportunities.firstWhere(
      (opportunity) => opportunity.id == id,
      orElse: () => workOpportunities.first,
    );
    selectedOpportunity = opportunity;
    applicationId = applicationIdsByOpportunity[opportunity.id];
    appliedOpportunityId = applicationId == null ? null : opportunity.id;
    withdrawnApplicationId = null;
    expandedTerms.clear();
    clearMessages();
  }

  void toggleTerm(String id) {
    if (!expandedTerms.add(id)) expandedTerms.remove(id);
    notifyListeners();
  }

  Future<bool> applySelectedOpportunity() async {
    final opportunity = selectedOpportunity;
    if (opportunity == null) {
      errorMessage = 'Open an opportunity before applying.';
      notifyListeners();
      return false;
    }
    if (!opportunity.available) {
      savedOpportunity = opportunity;
      errorMessage =
          'This opportunity is no longer accepting applications. It remains saved.';
      notifyListeners();
      return false;
    }
    final existingApplicationId = applicationIdsByOpportunity[opportunity.id];
    if (existingApplicationId != null) {
      applicationId = existingApplicationId;
      appliedOpportunityId = opportunity.id;
      errorMessage = null;
      noticeMessage =
          'Your application for this opportunity is already submitted.';
      notifyListeners();
      return true;
    }
    savedOpportunity = opportunity;
    if (opportunity.requiresWorkspace && !hasVerifiedWorkspace) {
      noticeMessage = 'Opportunity saved. Start My Work, then return to apply.';
      errorMessage = null;
      notifyListeners();
      return false;
    }
    return _runBool(
      () async {
        final createdApplicationId = await gateway.apply(opportunity.id);
        applicationIdsByOpportunity[opportunity.id] = createdApplicationId;
        applicationId = createdApplicationId;
        appliedOpportunityId = opportunity.id;
        withdrawnApplicationId = null;
      },
      success:
          'Application sent. The opportunity, terms and payout remain saved.',
    );
  }

  Future<bool> withdrawSelectedOpportunity() async {
    final opportunity = selectedOpportunity;
    final currentApplicationId = opportunity == null
        ? null
        : applicationIdsByOpportunity[opportunity.id];
    if (opportunity == null || currentApplicationId == null) {
      errorMessage =
          'There is no application to withdraw for this opportunity.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    return _runBool(
      () async {
        await gateway.withdraw(currentApplicationId, opportunity.id);
        applicationIdsByOpportunity.remove(opportunity.id);
        applicationId = null;
        appliedOpportunityId = null;
        withdrawnApplicationId = currentApplicationId;
      },
      success:
          'Application withdrawn. You can apply again while this opportunity remains available.',
    );
  }

  void startMyWork() {
    clearMessages();
    if (activeWorkspace == null) reviewStage = WorkReviewStage.drafting;
    notifyListeners();
  }

  Map<String, Object?> _applicationDetails() => {
    'profileId': selectedProfile?.id,
    'personName': authorizedPersonName,
    'relationship': businessRelationship,
    'phone': primaryMobile,
    'email': contactEmail,
    'alternate': alternateMobile,
    'name': workName,
    'area': workArea,
    'activity': primaryActivity,
    'proofs': Map<String, String>.unmodifiable(addedProofs),
    'caseId': reviewCaseId,
    'plan': subscriptionPlan,
    'correction': reviewCorrectionDraft,
    'submissionKey': _profileSubmissionKey,
    'editedFields': _editedDraftFields.toList(),
    'gstin': gstin,
    'gstReference': gstProofReference,
    'gstReminder': gstReminder,
  };

  void _rememberWorkspaceApplication() {
    if (_disposed ||
        selectedProfile == null ||
        remoteReviewStatus == WorkRemoteReviewStatus.approved ||
        remoteReviewStatus == WorkRemoteReviewStatus.live ||
        (_workspaceApplicationId == null &&
            {
              WorkReviewStage.approved,
              WorkReviewStage.live,
              WorkReviewStage.setup,
            }.contains(reviewStage))) {
      return;
    }
    _workspaceApplicationId ??=
        'draft-${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';
    _workspaceApplications[_workspaceApplicationId!] =
        _WorkspaceApplicationDraft(
          id: _workspaceApplicationId!,
          scope: _contactAccountScope,
          details: Map.unmodifiable(_applicationDetails()),
          submitted: submittedProfile,
          files: Map.unmodifiable(pickedProofs),
          confirmed: {
            for (final channel in WorkContactChannel.values)
              if (workspaceContactVerified(channel)) channel,
          },
          status: remoteReviewStatus,
          reason: reviewReason,
          needsStatusRefresh: reviewStatusNeedsRefresh,
        );
  }

  /// Called before opening the existing chooser; does not grant Store access.
  void retainWorkspaceApplication() => _queueContactDraft();

  List<({String id, String name, String status, String profileLabel})>
  get savedWorkspaceApplications => [
    for (final application in _workspaceApplications.values.toList().reversed)
      if (application.scope == _contactAccountScope)
        (
          id: application.id,
          name:
              (application.details['name'] as String?)?.trim().isNotEmpty ==
                  true
              ? application.details['name'] as String
              : 'Your Workspace',
          profileLabel:
              workProfiles
                  .where(
                    (profile) => profile.id == application.details['profileId'],
                  )
                  .firstOrNull
                  ?.label ??
              'Workspace',
          status: application.caseId == null
              ? 'Continue setup'
              : application.needsStatusRefresh
              ? 'Application saved'
              : switch (application.status) {
                  WorkRemoteReviewStatus.rejected => 'Not approved',
                  WorkRemoteReviewStatus.suspended => 'Workspace unavailable',
                  _ =>
                    application.reason?.trim().isNotEmpty == true
                        ? 'More information needed'
                        : 'Under review',
                },
        ),
  ];

  bool get _canChangeWorkspaceApplication =>
      !busy &&
      !workspaceOperationsSyncing &&
      !workspaceHandoverBusy &&
      !hasPendingOrderTime &&
      _collection?.busy != true &&
      _collection?.needsReconciliation != true;

  bool resumeWorkspaceApplication(String id) {
    final application = _workspaceApplications[id];
    if (application == null || application.scope != _contactAccountScope) {
      showError('This application is unavailable. Refresh your Workspaces.');
      return false;
    }
    if (!_canChangeWorkspaceApplication) {
      showNotice('Finishing your current update. Please wait.');
      return false;
    }
    _rememberWorkspaceApplication();
    _restoreWorkspaceApplication(application);
    _queueContactDraft();
    clearMessages();
    notifyListeners();
    return true;
  }

  String get workspaceApplicationRoute =>
      reviewCaseId != null || workspaceContactsReady
      ? '/app/work/workspace/proof'
      : '/app/work/workspace/contact';

  void _restoreWorkspaceApplication(_WorkspaceApplicationDraft application) {
    final data = application.details;
    String value(String key) => data[key] is String ? data[key] as String : '';
    _clearWorkspaceApplication();
    _workspaceApplicationId = application.id;
    selectedProfile = workProfiles
        .where((profile) => profile.id == data['profileId'])
        .firstOrNull;
    selectedFamilyId = selectedProfile?.familyId;
    authorizedPersonName = value('personName');
    businessRelationship = value('relationship');
    primaryMobile = value('phone');
    contactEmail = value('email');
    alternateMobile = value('alternate');
    workName = value('name');
    workArea = value('area');
    primaryActivity = value('activity');
    final allowed = selectedWorkspaceDocuments.map((proof) => proof.id).toSet();
    if (data['proofs'] case final Map proofs) {
      for (final entry in proofs.entries) {
        if (entry.key is String &&
            entry.value is String &&
            allowed.contains(entry.key)) {
          addedProofs[entry.key as String] = entry.value as String;
        }
      }
    }
    pickedProofs.addEntries(
      application.files.entries.where(
        (entry) => addedProofs.containsKey(entry.key),
      ),
    );
    primaryMobileVerified = application.confirmed.contains(
      WorkContactChannel.primaryMobile,
    );
    contactEmailVerified = application.confirmed.contains(
      WorkContactChannel.email,
    );
    alternateVerified = application.confirmed.contains(
      WorkContactChannel.alternateMobile,
    );
    _editedDraftFields
      ..clear()
      ..addAll((data['editedFields'] as List? ?? const []).whereType<String>());
    submittedProfile = application.submitted;
    reviewCaseId = application.caseId;
    subscriptionPlan = value('plan').isEmpty ? 'free' : value('plan');
    reviewCorrectionDraft = data['correction'] == true && reviewCaseId != null;
    _profileSubmissionKey = value('submissionKey').isEmpty
        ? null
        : value('submissionKey');
    remoteReviewStatus = application.status;
    reviewReason = application.reason;
    reviewStatusNeedsRefresh = application.needsStatusRefresh;
    reviewStage = reviewCaseId == null
        ? WorkReviewStage.drafting
        : WorkReviewStage.gstPending;
    gstin = value('gstin');
    gstProofReference = value('gstReference').isEmpty
        ? null
        : value('gstReference');
    gstAttachmentAdded = gstProofReference != null;
    gstReminder = data['gstReminder'] == true;
  }

  void _clearWorkspaceApplication() {
    _workspaceApplicationId = null;
    _removedProofs.clear();
    _contactEditOrigins.clear();
    for (final channel in WorkContactChannel.values) {
      _invalidateContactChallenge(channel);
    }
    recoveredDocumentStep = false;
    reviewStatusNeedsRefresh = false;
    documentRecoveryMessage = _documentRecoveryProofId = null;
    selectedFamilyId = null;
    selectedProfile = null;
    alternateMobile = '';
    alternateOtpSent = false;
    alternateVerified = false;
    workName = '';
    workArea = '';
    primaryActivity = '';
    addedProofs.clear();
    pickedProofs.clear();
    businessRelationship = '';
    submittedProfile = null;
    declarationAccepted = false;
    reviewCaseId = null;
    workspaceId = activeWorkspace?.id;
    subscriptionPlan = 'free';
    reviewReason = null;
    remoteReviewStatus = null;
    reviewCorrectionDraft = false;
    _profileSubmissionKey = null;
    reviewStage = WorkReviewStage.drafting;
    gstReminder = false;
    gstin = '';
    gstAttachmentAdded = false;
    gstProofReference = null;
  }

  bool startAnotherWork() {
    if (!_canChangeWorkspaceApplication) {
      showNotice('Finishing your current update. Please wait.');
      return false;
    }
    _rememberWorkspaceApplication();
    _clearWorkspaceApplication();
    _queueContactDraft();
    clearMessages();
    notifyListeners();
    return true;
  }

  void selectFamily(String familyId) {
    if (busy) return;
    _removedProofs.clear();
    if (selectedFamilyId != familyId) {
      documentRecoveryMessage = _documentRecoveryProofId = null;
    }
    selectedFamilyId = familyId;
    selectedProfile = null;
    _queueContactDraft();
    clearMessages();
    notifyListeners();
  }

  void selectProfile(String profileId) {
    if (busy) return;
    final nextProfile = workProfiles.firstWhere(
      (profile) => profile.id == profileId,
    );
    if (selectedProfile?.id != nextProfile.id) {
      if (reviewCaseId == null) _profileSubmissionKey = null;
      _removedProofs.clear();
      documentRecoveryMessage = _documentRecoveryProofId = null;
      addedProofs.removeWhere((id, _) => id != 'personal-kyc');
      declarationAccepted = false;
    }
    selectedProfile = nextProfile;
    _queueContactDraft();
    clearMessages();
    notifyListeners();
  }

  void changeFamily() {
    if (busy) return;
    _removedProofs.clear();
    documentRecoveryMessage = _documentRecoveryProofId = null;
    selectedFamilyId = null;
    selectedProfile = null;
    _queueContactDraft();
    clearMessages();
    notifyListeners();
  }

  void hydrateAccountSnapshot(WorkAccountSnapshot snapshot) {
    accountDisplayName = snapshot.displayName.trim();
    if (authorizedPersonName.isEmpty &&
        !_editedDraftFields.contains('personName')) {
      authorizedPersonName = accountDisplayName;
    }
    connectedProviderLabel = snapshot.providerLabel.trim();
    connectedProviderAccount = snapshot.providerAccount.trim();
    if (primaryMobile.isEmpty && !_editedDraftFields.contains('phone')) {
      final digits = snapshot.mobile.replaceAll(RegExp(r'\D'), '');
      final normalized = digits.length > 10
          ? digits.substring(digits.length - 10)
          : digits;
      if (normalized.length == 10) {
        primaryMobile = normalized;
        primaryMobileVerified = snapshot.mobileConfirmed;
      }
    }
    if (contactEmail.isEmpty && !_editedDraftFields.contains('email')) {
      final normalized = snapshot.email.trim().toLowerCase();
      if (_validEmail(normalized)) {
        contactEmail = normalized;
        contactEmailVerified = snapshot.emailConfirmed;
      }
    }
    final phone = snapshot.mobile.replaceAll(RegExp(r'\D'), '');
    final accountPhone = phone.length > 10
        ? phone.substring(phone.length - 10)
        : phone;
    if (primaryMobile.isNotEmpty &&
        primaryMobile == accountPhone &&
        snapshot.mobileConfirmed) {
      primaryMobileVerified = true;
    }
    if (contactEmail.isNotEmpty &&
        contactEmail == snapshot.email.trim().toLowerCase() &&
        snapshot.emailConfirmed) {
      contactEmailVerified = true;
    }
  }

  bool get workspaceContactsReady =>
      primaryMobileVerified &&
      contactEmailVerified &&
      (alternateMobile.isEmpty || alternateVerified);

  void savePersonName(String value) {
    _editedDraftFields.add('personName');
    if (authorizedPersonName != value.trim()) declarationAccepted = false;
    authorizedPersonName = value.trim();
    _queueContactDraft();
  }

  void saveBusinessRelationship(String value) {
    if (businessRelationship != value) declarationAccepted = false;
    businessRelationship = value;
    _queueContactDraft();
    notifyListeners();
  }

  void _queueContactDraft() {
    final store = contactDraftStore;
    final scope = store?.accountScope;
    if (_disposed || (_contactDraftScopeKnown && scope != _contactDraftScope)) {
      return;
    }
    _rememberWorkspaceApplication();
    if (store == null || scope == null || _disposed) return;
    if (_contactDraftScopeKnown && scope != _contactDraftScope) return;
    _contactDraftScopeKnown = true;
    _contactDraftScope = scope;
    _contactDraftRevision++;
    _queuedContactDraft = (
      scope: scope,
      draft: {
        'version': 2,
        'savedAt': DateTime.now().toUtc().toIso8601String(),
        'profileId': selectedProfile?.id,
        'personName': authorizedPersonName,
        'relationship': businessRelationship,
        'phone': primaryMobile,
        'email': contactEmail,
        'alternate': alternateMobile,
        'name': workName,
        'area': workArea,
        'activity': primaryActivity,
        'editedFields': _editedDraftFields.toList(),
        'dismissedWorkspaceWelcomes': _seenApprovalMessages.toList(),
        'workspaceApplicationId': _workspaceApplicationId,
        'applications': [
          for (final application in _workspaceApplications.values)
            if (application.scope == scope)
              {
                'id': application.id,
                'details': application.details,
                if (application.submitted != null)
                  'submitted': _savedSubmission(application.submitted!),
              },
        ],
      },
    );
    unawaited(flushContactDraft());
  }

  Map<String, Object?> _savedSubmission(WorkProfileSubmission value) => {
    'profileId': value.profileId,
    'personName': value.authorizedPersonName,
    'relationship': value.businessRelationship,
    'phone': value.primaryMobile,
    'email': value.email,
    'alternate': value.alternateMobile,
    'name': value.name,
    'area': value.area,
    'activity': value.primaryActivity,
    'proofs': value.proofReferences,
    'submissionKey': value.idempotencyKey,
  };

  WorkProfileSubmission? _readSavedSubmission(Object? raw, String profileId) {
    if (raw is! Map || raw['profileId'] != profileId) return null;
    final profile = workProfiles.where((p) => p.id == profileId).firstOrNull;
    if (profile == null) return null;
    String value(String key) => raw[key] is String ? raw[key] as String : '';
    final proofs = <String, String>{};
    if (raw['proofs'] case final Map references) {
      for (final entry in references.entries) {
        if (entry.key is String && entry.value is String) {
          proofs[entry.key as String] = entry.value as String;
        }
      }
    }
    return WorkProfileSubmission(
      familyId: profile.familyId,
      profileId: profile.id,
      authorizedPersonName: value('personName'),
      businessRelationship: value('relationship'),
      name: value('name'),
      area: value('area'),
      primaryActivity: value('activity'),
      primaryMobile: value('phone'),
      email: value('email'),
      alternateMobile: value('alternate'),
      alternateMobileVerified: false,
      proofReferences: Map.unmodifiable(proofs),
      idempotencyKey: value('submissionKey'),
    );
  }

  /// Coalesces edits without blocking typing. Verification secrets are excluded.
  void retryContactDraftSave() => _queueContactDraft();

  Future<void> flushContactDraft() {
    if (_contactDraftWrite != null) return _contactDraftWrite!;
    if (_queuedContactDraft == null || contactDraftStore == null) {
      return Future.value();
    }
    return _contactDraftWrite = _drainContactDraft().whenComplete(() {
      _contactDraftWrite = null;
      if (_queuedContactDraft != null) unawaited(flushContactDraft());
    });
  }

  Future<void> _drainContactDraft() async {
    final store = contactDraftStore!;
    while (_queuedContactDraft != null) {
      final pending = _queuedContactDraft!;
      _queuedContactDraft = null;
      try {
        await store.save(pending.scope, pending.draft);
        if (pending.scope == store.accountScope &&
            contactDraftMessage != null) {
          contactDraftMessage = null;
          notifyListeners();
        }
      } on Object {
        if (!_disposed && pending.scope == store.accountScope) {
          contactDraftMessage =
              'Your changes could not be saved on this phone. Keep this page open and try again.';
          notifyListeners();
        }
      }
    }
  }

  Future<void> _recoverContactDraft(bool accountReady) async {
    final store = contactDraftStore;
    if (store == null) return;
    final scope = accountReady ? store.accountScope : null;
    if (!_contactDraftScopeKnown || scope != _contactDraftScope) {
      if (_contactDraftScopeKnown) {
        _workspaceApplications.clear();
        _workspaceApplicationId = null;
        reviewStatusNeedsRefresh = false;
        _clearCollection();
        authorizedPersonName = businessRelationship = '';
        accountDisplayName = connectedProviderLabel = connectedProviderAccount =
            '';
        workName = workArea = primaryActivity = '';
        primaryMobile = contactEmail = alternateMobile = '';
        primaryMobileVerified = contactEmailVerified = alternateVerified =
            false;
        primaryMobileOtpSent = contactEmailOtpSent = alternateOtpSent = false;
        selectedProfile = null;
        selectedFamilyId = null;
        addedProofs.clear();
        pickedProofs.clear();
        _removedProofs.clear();
        submittedProfile = null;
        _approvalWelcome = null;
        _seenApprovalMessages.clear();
        _profileSubmissionKey = null;
        activeWorkspace = null;
        _storeDataById.clear();
        _storeData = _StoreOperationalData();
        _busyStoreOperation = null;
        busy = false;
        otherWorkspaces.clear();
        initialWorkspaceStateLoaded = false;
        reviewCaseId = workspaceId = reviewReason = null;
        remoteReviewStatus = null;
        reviewCorrectionDraft = false;
        reviewStage = WorkReviewStage.none;
        declarationAccepted = false;
        _contactEditOrigins.clear();
        _editedDraftFields.clear();
        for (final channel in WorkContactChannel.values) {
          _invalidateContactChallenge(channel);
        }
      }
      _contactDraftScopeKnown = true;
      _contactDraftScope = scope;
      _contactDraftRevision++;
      _queuedContactDraft = null;
      _contactDraftRecovery = null;
      contactDraftMessage = null;
    }
    if (scope == null) return;
    final revision = _contactDraftRevision;
    _contactDraftRecovery ??= _readContactDraft(store, scope, revision);
    await _contactDraftRecovery;
  }

  Future<void> _readContactDraft(
    WorkPendingProofStore store,
    String scope,
    int revision,
  ) async {
    bool current() =>
        !_disposed &&
        scope == store.accountScope &&
        scope == _contactDraftScope &&
        revision == _contactDraftRevision;
    try {
      final draft = await store.read(scope);
      if (draft == null || !current() || !{1, 2}.contains(draft['version'])) {
        return;
      }
      if (draft['dismissedWorkspaceWelcomes'] case final List messages) {
        _seenApprovalMessages.addAll(messages.whereType<String>());
      }
      final savedAt = DateTime.tryParse(draft['savedAt'] as String? ?? '');
      if (savedAt == null ||
          DateTime.now().difference(savedAt).isNegative ||
          DateTime.now().difference(savedAt) > const Duration(days: 30)) {
        return;
      }
      String field(String key) =>
          draft[key] is String ? draft[key] as String : '';
      authorizedPersonName = field('personName');
      businessRelationship = field('relationship');
      primaryMobile = field('phone');
      contactEmail = field('email');
      alternateMobile = field('alternate');
      workName = field('name');
      workArea = field('area');
      primaryActivity = field('activity');
      if (draft['editedFields'] case final List fields) {
        _editedDraftFields.addAll(fields.whereType<String>());
      }
      selectedProfile = workProfiles
          .where((p) => p.id == draft['profileId'])
          .firstOrNull;
      selectedFamilyId = selectedProfile?.familyId;
      // Local draft flags are not authority for identity or Workspace approval.
      primaryMobileVerified = contactEmailVerified = alternateVerified = false;
      primaryMobileOtpSent = contactEmailOtpSent = alternateOtpSent = false;
      declarationAccepted = false;
      if (draft['version'] == 2 && draft['applications'] is List) {
        for (final raw in draft['applications'] as List) {
          if (raw is! Map || raw['details'] is! Map || raw['id'] is! String) {
            continue;
          }
          final id = raw['id'] as String;
          final details = Map<String, Object?>.from(raw['details'] as Map);
          final profile = workProfiles
              .where((p) => p.id == details['profileId'])
              .firstOrNull;
          if (id.isEmpty ||
              profile == null ||
              (details['caseId'] != null && details['caseId'] is! String)) {
            continue;
          }
          _workspaceApplications[id] = _WorkspaceApplicationDraft(
            id: id,
            scope: scope,
            details: Map.unmodifiable(details),
            submitted: _readSavedSubmission(raw['submitted'], profile.id),
            needsStatusRefresh: details['caseId'] != null,
          );
        }
        final application =
            _workspaceApplications[draft['workspaceApplicationId']];
        if (application != null) _restoreWorkspaceApplication(application);
      }
    } on Object {
      if (current()) {
        contactDraftMessage =
            'Saved details could not be restored. Please enter your details to continue.';
      }
    }
  }

  String workspaceContactValue(WorkContactChannel channel) => switch (channel) {
    WorkContactChannel.primaryMobile => primaryMobile,
    WorkContactChannel.email => contactEmail,
    WorkContactChannel.alternateMobile => alternateMobile,
  };

  bool workspaceContactVerified(WorkContactChannel channel) =>
      switch (channel) {
        WorkContactChannel.primaryMobile => primaryMobileVerified,
        WorkContactChannel.email => contactEmailVerified,
        WorkContactChannel.alternateMobile => alternateVerified,
      };

  bool isEditingWorkspaceContact(WorkContactChannel channel) =>
      _contactEditOrigins.containsKey(channel);

  String? get _contactAccountScope =>
      contactDraftStore?.accountScope ?? pendingProofStore?.accountScope;

  void _invalidateContactChallenge(WorkContactChannel channel) {
    _contactRevisions[channel] = (_contactRevisions[channel] ?? 0) + 1;
    switch (channel) {
      case WorkContactChannel.primaryMobile:
        primaryMobileOtpSent = false;
      case WorkContactChannel.email:
        contactEmailOtpSent = false;
      case WorkContactChannel.alternateMobile:
        alternateOtpSent = false;
    }
  }

  void beginWorkspaceContactEdit(WorkContactChannel channel) {
    if (busy) return;
    _contactEditOrigins.putIfAbsent(
      channel,
      () => (
        value: workspaceContactValue(channel),
        verified: workspaceContactVerified(channel),
        scope: _contactAccountScope,
      ),
    );
    _invalidateContactChallenge(channel);
    clearMessages();
    notifyListeners();
  }

  void cancelWorkspaceContactEdit(WorkContactChannel channel) {
    final original = _contactEditOrigins.remove(channel);
    if (original == null) return;
    _invalidateContactChallenge(channel);
    if (original.scope != _contactAccountScope) {
      editWorkspaceContact(channel, '');
      errorMessage = 'Sign in again to confirm your contact details.';
      notifyListeners();
      return;
    }
    editWorkspaceContact(channel, original.value);
    switch (channel) {
      case WorkContactChannel.primaryMobile:
        primaryMobileVerified = original.verified;
      case WorkContactChannel.email:
        contactEmailVerified = original.verified;
      case WorkContactChannel.alternateMobile:
        alternateVerified = original.verified;
    }
    clearMessages();
    notifyListeners();
  }

  void editWorkspaceContact(WorkContactChannel channel, String value) {
    _editedDraftFields.add(switch (channel) {
      WorkContactChannel.primaryMobile => 'phone',
      WorkContactChannel.email => 'email',
      WorkContactChannel.alternateMobile => 'alternate',
    });
    final normalized = channel == WorkContactChannel.email
        ? value.trim().toLowerCase()
        : value.replaceAll(RegExp(r'\D'), '');
    final previous = switch (channel) {
      WorkContactChannel.primaryMobile => primaryMobile,
      WorkContactChannel.email => contactEmail,
      WorkContactChannel.alternateMobile => alternateMobile,
    };
    if (normalized == previous) {
      _queueContactDraft();
      return;
    }
    _contactRevisions[channel] = (_contactRevisions[channel] ?? 0) + 1;
    declarationAccepted = false;
    switch (channel) {
      case WorkContactChannel.primaryMobile:
        primaryMobile = normalized;
        primaryMobileOtpSent = false;
        primaryMobileVerified = false;
      case WorkContactChannel.email:
        contactEmail = normalized;
        contactEmailOtpSent = false;
        contactEmailVerified = false;
      case WorkContactChannel.alternateMobile:
        alternateMobile = normalized;
        alternateOtpSent = false;
        alternateVerified = false;
    }
    _queueContactDraft();
    clearMessages();
    notifyListeners();
  }

  Future<bool> sendPrimaryMobileOtp(String mobile) async {
    if (busy) return false;
    final normalized = mobile.replaceAll(RegExp(r'\D'), '');
    if (normalized.length != 10) {
      errorMessage = 'Enter a valid 10-digit phone number.';
      notifyListeners();
      return false;
    }
    editWorkspaceContact(WorkContactChannel.primaryMobile, normalized);
    return _sendWorkspaceContactOtp(
      WorkContactChannel.primaryMobile,
      normalized,
      onSent: () {
        primaryMobileOtpSent = true;
        primaryMobileVerified = false;
      },
    );
  }

  Future<bool> verifyPrimaryMobileOtp(String code) =>
      _verifyWorkspaceContactOtp(
        WorkContactChannel.primaryMobile,
        primaryMobile,
        code,
        onVerified: () => primaryMobileVerified = true,
      );

  Future<bool> sendContactEmailOtp(String email) async {
    if (busy) return false;
    final normalized = email.trim().toLowerCase();
    if (!_validEmail(normalized)) {
      errorMessage = 'Enter a valid email address.';
      notifyListeners();
      return false;
    }
    editWorkspaceContact(WorkContactChannel.email, normalized);
    return _sendWorkspaceContactOtp(
      WorkContactChannel.email,
      normalized,
      onSent: () {
        contactEmailOtpSent = true;
        contactEmailVerified = false;
      },
    );
  }

  Future<bool> verifyContactEmailOtp(String code) => _verifyWorkspaceContactOtp(
    WorkContactChannel.email,
    contactEmail,
    code,
    onVerified: () => contactEmailVerified = true,
  );

  void changePrimaryMobile() {
    _contactRevisions[WorkContactChannel.primaryMobile] =
        (_contactRevisions[WorkContactChannel.primaryMobile] ?? 0) + 1;
    declarationAccepted = false;
    primaryMobile = '';
    primaryMobileOtpSent = false;
    primaryMobileVerified = false;
    clearMessages();
    notifyListeners();
  }

  void changeContactEmail() {
    _contactRevisions[WorkContactChannel.email] =
        (_contactRevisions[WorkContactChannel.email] ?? 0) + 1;
    declarationAccepted = false;
    contactEmail = '';
    contactEmailOtpSent = false;
    contactEmailVerified = false;
    clearMessages();
    notifyListeners();
  }

  Future<bool> sendAlternateOtp(String mobile) async {
    if (busy) return false;
    final normalized = mobile.replaceAll(RegExp(r'\D'), '');
    if (normalized.length != 10) {
      errorMessage = 'Enter a valid 10-digit alternate mobile number.';
      notifyListeners();
      return false;
    }
    if (normalized == primaryMobile) {
      errorMessage = 'This is already the number customers can reach you on.';
      notifyListeners();
      return false;
    }
    editWorkspaceContact(WorkContactChannel.alternateMobile, normalized);
    return _sendWorkspaceContactOtp(
      WorkContactChannel.alternateMobile,
      normalized,
      onSent: () {
        alternateOtpSent = true;
        alternateVerified = false;
      },
    );
  }

  Future<bool> verifyAlternateOtp(String code) => _verifyWorkspaceContactOtp(
    WorkContactChannel.alternateMobile,
    alternateMobile,
    code,
    onVerified: () => alternateVerified = true,
  );

  Future<bool> _sendWorkspaceContactOtp(
    WorkContactChannel channel,
    String value, {
    required VoidCallback onSent,
  }) {
    final revision = _contactRevisions[channel] ?? 0;
    final scope = _contactAccountScope;
    return _runBool(() async {
      await gateway.sendContactOtp(channel: channel, value: value);
      if (_disposed ||
          revision != (_contactRevisions[channel] ?? 0) ||
          scope != _contactAccountScope ||
          workspaceContactValue(channel) != value) {
        throw const WorkGatewayException(
          'Contact changed. Request a new code.',
        );
      }
      onSent();
    }, success: null);
  }

  Future<bool> _verifyWorkspaceContactOtp(
    WorkContactChannel channel,
    String value,
    String code, {
    required VoidCallback onVerified,
  }) async {
    final sent = switch (channel) {
      WorkContactChannel.primaryMobile => primaryMobileOtpSent,
      WorkContactChannel.email => contactEmailOtpSent,
      WorkContactChannel.alternateMobile => alternateOtpSent,
    };
    if (!sent) {
      errorMessage = 'Send a code before confirming this contact.';
      notifyListeners();
      return false;
    }
    final normalizedCode = code.replaceAll(RegExp(r'\D'), '');
    if (normalizedCode.length != 6) {
      errorMessage = 'Enter all 6 digits of the code.';
      notifyListeners();
      return false;
    }
    final revision = _contactRevisions[channel] ?? 0;
    final scope = _contactAccountScope;
    return _runBool(() async {
      await gateway.verifyContactOtp(
        channel: channel,
        value: value,
        code: normalizedCode,
      );
      if (_disposed ||
          revision != (_contactRevisions[channel] ?? 0) ||
          scope != _contactAccountScope ||
          workspaceContactValue(channel) != value) {
        throw const WorkGatewayException(
          'Contact changed. Request a new code.',
        );
      }
      onVerified();
      _contactEditOrigins.remove(channel);
    }, success: null);
  }

  void removeAlternateMobile() {
    declarationAccepted = false;
    _contactRevisions[WorkContactChannel.alternateMobile] =
        (_contactRevisions[WorkContactChannel.alternateMobile] ?? 0) + 1;
    alternateMobile = '';
    alternateOtpSent = false;
    alternateVerified = false;
    clearMessages();
    notifyListeners();
  }

  bool continueToProof() {
    if (selectedProfile == null) {
      errorMessage = 'Choose the work profile that best matches what you do.';
      notifyListeners();
      return false;
    }
    if (primaryMobile.replaceAll(RegExp(r'\D'), '').length != 10) {
      errorMessage = 'Enter a valid 10-digit phone number.';
      notifyListeners();
      return false;
    }
    if (!primaryMobileVerified) {
      errorMessage =
          'Confirm the phone number customers can reach you on before continuing.';
      notifyListeners();
      return false;
    }
    if (!_validEmail(contactEmail)) {
      errorMessage = 'Enter a valid email address.';
      notifyListeners();
      return false;
    }
    if (!contactEmailVerified) {
      errorMessage = 'Confirm your email address before continuing.';
      notifyListeners();
      return false;
    }
    if (alternateMobile.isNotEmpty &&
        alternateMobile.replaceAll(RegExp(r'\D'), '').length != 10) {
      errorMessage = 'Enter a valid 10-digit alternate mobile number.';
      notifyListeners();
      return false;
    }
    if (alternateMobile.isNotEmpty && !alternateVerified) {
      errorMessage = 'Confirm or remove the alternate contact number.';
      notifyListeners();
      return false;
    }
    _contactEditOrigins.clear();
    reviewStage = WorkReviewStage.drafting;
    clearMessages();
    notifyListeners();
    return true;
  }

  Future<bool> sendUnsupportedRequest({
    required String workspace,
    required String family,
    required String area,
    String otherActivity = '',
  }) async {
    if (workspace.trim().length < 3) {
      errorMessage = 'Enter your business, profession or service.';
      notifyListeners();
      return false;
    }
    if (family.trim().isEmpty) {
      errorMessage = 'Choose the closest category.';
      notifyListeners();
      return false;
    }
    if (area.trim().length < 3) {
      errorMessage = 'Enter your operating city or area.';
      notifyListeners();
      return false;
    }
    if (family.trim() == 'Other' && otherActivity.trim().length < 3) {
      errorMessage = 'Enter the activity you want to offer.';
      notifyListeners();
      return false;
    }
    unsupportedWorkspace = workspace.trim();
    unsupportedFamily = family.trim();
    unsupportedArea = area.trim();
    unsupportedOtherActivity = family.trim() == 'Other'
        ? otherActivity.trim()
        : '';
    if (gateway is! ReviewWorkGateway) {
      unsupportedRequestSent = false;
      errorMessage =
          'This request cannot be sent yet. Your details are still here.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    unsupportedRequestSent = true;
    errorMessage = null;
    noticeMessage =
        'Thank you—MoolSocial will review your request and update you in Workspace and Chat.';
    notifyListeners();
    return true;
  }

  void saveDetails({
    required String name,
    required String area,
    required String activity,
  }) {
    if (workName != name.trim() ||
        workArea != area.trim() ||
        primaryActivity != activity.trim()) {
      declarationAccepted = false;
    }
    workName = name.trim();
    workArea = area.trim();
    primaryActivity = activity.trim();
    _queueContactDraft();
    clearMessages();
    notifyListeners();
  }

  String? get detailsNameError => workName.trim().length < 3
      ? 'Enter the business name shown on its PAN card.'
      : null;

  String? get detailsAreaError {
    final area = workArea.trim();
    final pin = area.replaceAll(RegExp(r'\s'), '');
    if (RegExp(r'^[0-9]+$').hasMatch(pin)) {
      return RegExp(r'^[1-9][0-9]{5}$').hasMatch(pin)
          ? null
          : 'Enter a 6-digit PIN code, or use your city name.';
    }
    if (area.length < 3 || !RegExp(r'\p{L}', unicode: true).hasMatch(area)) {
      return 'Enter your city name or a 6-digit PIN code.';
    }
    return null;
  }

  String? get detailsActivityError => primaryActivity.trim().length < 3
      ? 'Describe the primary activity.'
      : null;

  bool validateDetails() {
    final error = detailsNameError ?? detailsAreaError ?? detailsActivityError;
    if (error != null) {
      errorMessage = error;
      notifyListeners();
      return false;
    }
    clearMessages();
    notifyListeners();
    return true;
  }

  Map<String, Object?> _pendingDocumentDraft(
    String proofId,
    WorkProofSource source,
  ) => {
    'version': 1,
    'workspaceApplicationId': _workspaceApplicationId,
    'savedAt': DateTime.now().toUtc().toIso8601String(),
    'profileId': selectedProfile?.id,
    'proofId': proofId,
    'source': source.name,
    'personName': authorizedPersonName,
    'relationship': businessRelationship,
    'name': workName,
    'area': workArea,
    'activity': primaryActivity,
    'phone': primaryMobile,
    'email': contactEmail,
    'alternate': alternateMobile,
    'phoneConfirmed': primaryMobileVerified,
    'emailConfirmed': contactEmailVerified,
    'alternateConfirmed': alternateVerified,
    'proofs': Map<String, String>.of(addedProofs),
    'caseId': reviewCaseId,
    'reason': reviewReason,
    'correction': reviewCorrectionDraft,
  };

  /// Resumes only the document operation owned by the currently signed-in
  /// account. This does not restore sign-in, OTP secrets or approval authority.
  Future<bool> recoverPendingProof({required bool accountReady}) async {
    final store = pendingProofStore;
    if (store == null) {
      await _recoverContactDraft(accountReady);
      return false;
    }
    final scope = accountReady ? store.accountScope : null;
    if (_pendingProofScope != scope) {
      if (_pendingProofScope != null) {
        _workspaceApplications.clear();
        _workspaceApplicationId = null;
        reviewStatusNeedsRefresh = false;
      }
      _pendingProofGeneration++;
      _pendingProofScope = scope;
      _pendingProofRecovery = null;
      _pendingProofRoute = false;
      if (_hasRecoveredDraft) {
        selectedProfile = null;
        selectedFamilyId = null;
        authorizedPersonName = businessRelationship = '';
        workName = workArea = primaryActivity = '';
        primaryMobile = contactEmail = alternateMobile = '';
        primaryMobileVerified = contactEmailVerified = alternateVerified =
            false;
        addedProofs.clear();
        pickedProofs.clear();
        reviewCaseId = reviewReason = null;
        reviewCorrectionDraft = false;
        recoveredDocumentStep = false;
        documentRecoveryMessage = _documentRecoveryProofId = null;
        _hasRecoveredDraft = false;
      }
    }
    await _recoverContactDraft(accountReady);
    if (scope == null) return false;
    final generation = _pendingProofGeneration;
    _pendingProofRecovery ??= _restorePendingDocument(store, scope, generation);
    await _pendingProofRecovery;
    if (_disposed ||
        generation != _pendingProofGeneration ||
        scope != store.accountScope ||
        scope != _pendingProofScope) {
      return false;
    }
    final redirect = _pendingProofRoute;
    _pendingProofRoute = false;
    return redirect;
  }

  Future<void> _restorePendingDocument(
    WorkPendingProofStore store,
    String scope,
    int generation,
  ) async {
    bool current() =>
        !_disposed &&
        generation == _pendingProofGeneration &&
        scope == store.accountScope &&
        scope == _pendingProofScope;
    try {
      final draft = await store.read(scope);
      if (draft == null || !current()) return;
      final applicationId = draft['workspaceApplicationId'];
      if (applicationId is String &&
          _workspaceApplicationId != null &&
          applicationId != _workspaceApplicationId) {
        // An old picker checkpoint must not replace a newer application.
        return;
      }
      final timestamp = DateTime.tryParse(draft['savedAt'] as String? ?? '');
      final age = timestamp == null
          ? null
          : DateTime.now().difference(timestamp);
      final profile = workProfiles
          .where((p) => p.id == draft['profileId'])
          .firstOrNull;
      final source = WorkProofSource.values
          .where((s) => s.name == draft['source'])
          .firstOrNull;
      if (draft['version'] != 1 ||
          age == null ||
          age.isNegative ||
          age > const Duration(hours: 24) ||
          profile == null ||
          source == null) {
        await store.clear(scope);
        return;
      }
      String field(String name) =>
          draft[name] is String ? draft[name] as String : '';
      if (applicationId is String) _workspaceApplicationId = applicationId;
      selectedProfile = profile;
      selectedFamilyId = profile.familyId;
      authorizedPersonName = field('personName');
      businessRelationship = field('relationship');
      workName = field('name');
      workArea = field('area');
      primaryActivity = field('activity');
      primaryMobile = field('phone');
      contactEmail = field('email');
      alternateMobile = field('alternate');
      primaryMobileVerified =
          gateway is ReviewWorkGateway &&
          primaryMobile.isNotEmpty &&
          draft['phoneConfirmed'] == true;
      contactEmailVerified =
          gateway is ReviewWorkGateway &&
          contactEmail.isNotEmpty &&
          draft['emailConfirmed'] == true;
      alternateVerified =
          gateway is ReviewWorkGateway &&
          alternateMobile.isNotEmpty &&
          draft['alternateConfirmed'] == true;
      primaryMobileOtpSent = contactEmailOtpSent = alternateOtpSent = false;
      declarationAccepted = false;
      final proofId = field('proofId');
      final allowed = selectedWorkspaceDocuments.map((p) => p.id).toSet();
      addedProofs.clear();
      if (draft['proofs'] case final Map references) {
        for (final entry in references.entries) {
          if (allowed.contains(entry.key) && entry.value is String) {
            addedProofs[entry.key as String] = entry.value as String;
          }
        }
      }
      reviewCaseId = field('caseId').isEmpty ? null : field('caseId');
      reviewReason = field('reason').isEmpty ? null : field('reason');
      reviewCorrectionDraft =
          reviewCaseId != null && draft['correction'] == true;
      remoteReviewStatus = reviewCaseId == null
          ? null
          : WorkRemoteReviewStatus.pending;
      reviewStage = reviewCaseId == null
          ? WorkReviewStage.drafting
          : WorkReviewStage.gstPending;
      recoveredDocumentStep = true;
      _hasRecoveredDraft = true;
      _pendingProofRoute = true;
      noticeMessage =
          'Your details are restored. Add or review your documents to continue.';
      if (allowed.contains(proofId)) {
        final label = selectedWorkspaceDocuments
            .firstWhere((document) => document.id == proofId)
            .label;
        _documentRecoveryProofId = proofId;
        documentRecoveryMessage =
            'Your details are saved. Please add $label again.';
        noticeMessage = null;
      }
      if (allowed.contains(proofId) &&
          proofPicker is WorkRecoverableProofPicker) {
        final proof = await (proofPicker as WorkRecoverableProofPicker).recover(
          source,
        );
        if (!current()) return;
        if (proof != null) {
          final reference = await gateway.saveProof(proofId, proof);
          if (!current()) return;
          addedProofs[proofId] = reference;
          pickedProofs[proofId] = proof;
          documentRecoveryMessage = _documentRecoveryProofId = null;
          noticeMessage = 'Document restored. Review it before submitting.';
        }
      }
      if (current()) {
        _queueContactDraft();
        await store.clear(scope);
      }
    } on WorkGatewayException catch (error) {
      if (current()) {
        documentRecoveryMessage = null;
        errorMessage = error.message;
        noticeMessage = null;
      }
    } on Object {
      if (current()) {
        documentRecoveryMessage = null;
        errorMessage =
            'Your document could not be restored. Please add it again.';
        noticeMessage = null;
      }
    }
    if (current()) notifyListeners();
  }

  Future<bool> addProof(String proofId, WorkProofSource source) async {
    if (busy) return false;
    _rememberWorkspaceApplication();
    final applicationId = _workspaceApplicationId;
    final accountScope = _contactAccountScope;
    final profileId = selectedProfile?.id;
    bool current() =>
        !_disposed &&
        applicationId == _workspaceApplicationId &&
        accountScope == _contactAccountScope &&
        profileId == selectedProfile?.id;
    busy = true;
    clearMessages();
    notifyListeners();
    final store = pendingProofStore;
    final scope = store?.accountScope;
    try {
      if (store != null) {
        if (scope == null) {
          throw const WorkGatewayException(
            'Sign in again before adding a document.',
          );
        }
        await store.save(scope, _pendingDocumentDraft(proofId, source));
        if (!current() || scope != store.accountScope) return false;
      }
      final proof = await proofPicker.pick(source);
      if (!current() || (store != null && scope != store.accountScope)) {
        return false;
      }
      if (proof == null) return false;
      final reference = await gateway.saveProof(proofId, proof);
      if (!current() || (store != null && scope != store.accountScope)) {
        return false;
      }
      addedProofs[proofId] = reference;
      pickedProofs[proofId] = proof;
      _removedProofs.remove(proofId);
      if (_documentRecoveryProofId == proofId) {
        documentRecoveryMessage = _documentRecoveryProofId = null;
      }
      declarationAccepted = false;
      // The document row reports the attachment without moving the whole page.
      noticeMessage = null;
      return true;
    } on WorkGatewayException catch (error) {
      if (current() && !error.cancelled) errorMessage = error.message;
      return false;
    } on Object {
      if (current()) {
        errorMessage = 'The document could not be added. Please try again.';
      }
      return false;
    } finally {
      if (current() &&
          store != null &&
          scope != null &&
          scope == store.accountScope) {
        try {
          await store.clear(scope);
        } on Object {
          /* Retain recovery until storage is available. */
        }
      }
      if (current()) {
        _queueContactDraft();
        busy = false;
        notifyListeners();
      }
    }
  }

  void removeProof(String proofId) {
    final reference = addedProofs[proofId];
    if (busy ||
        reference == null ||
        (reviewCaseId != null && !reviewCorrectionDraft)) {
      return;
    }
    _removedProofs[proofId] = (
      reference: reference,
      file: pickedProofs[proofId],
      profileId: selectedProfile?.id,
      scope: _contactAccountScope,
    );
    addedProofs.remove(proofId);
    pickedProofs.remove(proofId);
    declarationAccepted = false;
    _queueContactDraft();
    clearMessages();
    notifyListeners();
  }

  bool canUndoProofRemoval(String proofId) {
    final removed = _removedProofs[proofId];
    return !busy &&
        removed != null &&
        !addedProofs.containsKey(proofId) &&
        removed.scope == _contactAccountScope &&
        removed.profileId == selectedProfile?.id &&
        selectedWorkspaceDocuments.any((proof) => proof.id == proofId) &&
        (reviewCaseId == null || reviewCorrectionDraft);
  }

  String? removedProofName(String proofId) => canUndoProofRemoval(proofId)
      ? _removedProofs[proofId]!.file?.fileName ??
            selectedWorkspaceDocuments
                .firstWhere((proof) => proof.id == proofId)
                .label
      : null;

  bool undoProofRemoval(String proofId) {
    if (!canUndoProofRemoval(proofId)) return false;
    final removed = _removedProofs.remove(proofId)!;
    addedProofs[proofId] = removed.reference;
    if (removed.file != null) pickedProofs[proofId] = removed.file!;
    declarationAccepted = false;
    _queueContactDraft();
    clearMessages();
    notifyListeners();
    return true;
  }

  void setDeclaration(bool value) {
    declarationAccepted = value;
    clearMessages();
    notifyListeners();
  }

  bool beginReviewCorrection() {
    if (reviewStatusNeedsRefresh) {
      showError(
        'Wait for the current application update before making changes.',
      );
      return false;
    }
    if (remoteReviewStatus == WorkRemoteReviewStatus.suspended) {
      errorMessage =
          'This Workspace is unavailable. Contact MoolSocial Support for the next step.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    if (remoteReviewStatus == WorkRemoteReviewStatus.approved ||
        remoteReviewStatus == WorkRemoteReviewStatus.live) {
      errorMessage =
          'This Workspace is already approved. Open its dashboard to manage it.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    if (remoteReviewStatus == WorkRemoteReviewStatus.rejected) {
      errorMessage =
          'This application was not approved. Contact MoolSocial about the review decision.';
      notifyListeners();
      return false;
    }
    if (reviewCaseId == null) {
      errorMessage = 'Submit the Workspace before sending a correction.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    if (reviewReason?.trim().isNotEmpty != true) {
      errorMessage =
          'MoolSocial is reviewing your application. No changes are needed now.';
      notifyListeners();
      return false;
    }
    if (gateway is! ReviewWorkGateway) {
      errorMessage =
          'Contact MoolSocial in Chat to provide the requested clarification. Your application remains saved.';
      notifyListeners();
      return false;
    }
    reviewCorrectionDraft = true;
    declarationAccepted = false;
    _queueContactDraft();
    clearMessages();
    notifyListeners();
    return true;
  }

  WorkProfileSubmission _currentProfileSubmission() {
    final profile = selectedProfile!;
    _profileSubmissionKey ??=
        'work-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
    return WorkProfileSubmission(
      familyId: profile.familyId,
      profileId: profile.id,
      name: workName,
      authorizedPersonName: authorizedPersonName,
      businessRelationship: businessRelationship,
      area: workArea,
      primaryActivity: primaryActivity,
      proofReferences: Map<String, String>.unmodifiable(addedProofs),
      primaryMobile: primaryMobile,
      email: contactEmail,
      alternateMobile: alternateMobile,
      connectedProvider: connectedProviderLabel,
      connectedProviderAccount: connectedProviderAccount,
      alternateMobileVerified: alternateVerified,
      idempotencyKey: _profileSubmissionKey!,
    );
  }

  Future<bool> submitProfile() async {
    if (reviewStatusNeedsRefresh && reviewCaseId != null) {
      showError('Check your application update before submitting changes.');
      return false;
    }
    if (!validateDetails()) return false;
    if (!workspaceContactsReady) {
      errorMessage =
          'Confirm your phone number and email before submitting this Workspace.';
      notifyListeners();
      return false;
    }
    if (!declarationAccepted) {
      errorMessage = 'Confirm the declaration before submission.';
      notifyListeners();
      return false;
    }
    final existingCaseId = reviewCaseId;
    if (existingCaseId != null && !reviewCorrectionDraft) {
      noticeMessage =
          'This Workspace is already under review as $existingCaseId.';
      errorMessage = null;
      notifyListeners();
      return true;
    }
    if (busy) return false;
    final requestedScope = _contactAccountScope;
    final submission = _currentProfileSubmission();
    _queueContactDraft();
    final requestedApplication = _workspaceApplicationId;
    bool current() =>
        !_disposed &&
        requestedApplication == _workspaceApplicationId &&
        requestedScope == _contactAccountScope &&
        selectedProfile?.id == submission.profileId &&
        reviewCaseId == existingCaseId;
    busy = true;
    clearMessages();
    notifyListeners();
    try {
      final result = existingCaseId == null
          ? await gateway.submitProfile(submission)
          : await gateway.submitCorrection(existingCaseId, submission);
      if (!current()) return false;
      if (result.caseId.trim().isEmpty ||
          _workspaceApplications.values.any(
            (application) =>
                application.id != requestedApplication &&
                application.caseId == result.caseId,
          ) ||
          (existingCaseId != null && result.caseId != existingCaseId) ||
          (result.profileId != null &&
              result.profileId != submission.profileId)) {
        throw const WorkGatewayException(
          'The response could not be matched to this application. Please retry.',
        );
      }
      submittedProfile = submission;
      reviewCaseId = result.caseId;
      subscriptionPlan = result.plan;
      reviewReason = result.reason;
      remoteReviewStatus = result.status;
      reviewStatusNeedsRefresh = false;
      reviewStage = WorkReviewStage.gstPending;
      reviewCorrectionDraft = false;
      // The acknowledged case changes the pre-request guard. Save the exact
      // validated result here, before leaving this synchronous success block.
      _queueContactDraft();
      noticeMessage = existingCaseId == null
          ? 'Application submitted.'
          : 'Your updated information was submitted.';
      return true;
    } on WorkGatewayException catch (error) {
      if (current()) errorMessage = error.message;
      return false;
    } finally {
      busy = false;
      if (current()) _queueContactDraft();
      if (!_disposed) notifyListeners();
    }
  }

  void remindGstLater() {
    gstReminder = true;
    errorMessage = null;
    noticeMessage =
        'GST reminder saved. Review continues without losing progress.';
    notifyListeners();
  }

  Future<bool> addGstProof(WorkProofSource source) async {
    if (busy) return false;
    busy = true;
    clearMessages();
    notifyListeners();
    try {
      final proof = await proofPicker.pick(source);
      if (proof == null) return false;
      gstProofReference = await gateway.saveProof('gst', proof);
      gstAttachmentAdded = true;
      noticeMessage = 'GST certificate received for this review.';
      return true;
    } on WorkGatewayException catch (error) {
      if (!error.cancelled) errorMessage = error.message;
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> submitGstProof(String value) async {
    final normalized = value.trim().toUpperCase();
    if (!RegExp(
      r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][A-Z0-9]Z[A-Z0-9]$',
    ).hasMatch(normalized)) {
      errorMessage = 'Enter a valid 15-character GSTIN.';
      notifyListeners();
      return false;
    }
    if (!gstAttachmentAdded) {
      errorMessage = 'Attach the GST certificate before submission.';
      notifyListeners();
      return false;
    }
    return _runBool(() async {
      final caseId = reviewCaseId;
      if (caseId == null) {
        throw const WorkGatewayException(
          'Submit the Workspace profile before adding a GST certificate.',
        );
      }
      final proofReference = gstProofReference;
      if (proofReference == null) {
        throw const WorkGatewayException(
          'Attach the GST certificate before submission.',
        );
      }
      await gateway.submitGst(caseId, normalized, proofReference);
      gstin = normalized;
      gstReminder = false;
    }, success: 'GST certificate added to your Workspace review.');
  }

  Future<bool> checkReview() async {
    if (reviewCaseId == null) {
      errorMessage = 'Submit the work profile before checking review.';
      notifyListeners();
      return false;
    }
    if (busy) return false;
    busy = true;
    clearMessages();
    notifyListeners();
    final requestedCase = reviewCaseId!;
    final requestedScope = _contactAccountScope;
    final requestedProfile = selectedProfile?.id;
    final requestedApplication = _workspaceApplicationId;
    bool current() =>
        !_disposed &&
        requestedApplication == _workspaceApplicationId &&
        reviewCaseId == requestedCase &&
        requestedScope == _contactAccountScope &&
        requestedProfile == selectedProfile?.id;
    try {
      final result = await gateway.checkReview(requestedCase);
      if (!current()) return false;
      if (result.caseId != requestedCase ||
          (result.profileId != null && result.profileId != requestedProfile)) {
        throw const WorkGatewayException(
          'The review update could not be matched to this application. Please retry.',
        );
      }
      if ((result.status == WorkRemoteReviewStatus.approved ||
              result.status == WorkRemoteReviewStatus.live) &&
          (result.workspaceId?.trim().isEmpty ?? true)) {
        throw const WorkGatewayException(
          'Approval was received without a Workspace. Try checking again.',
          retryable: true,
        );
      }
      subscriptionPlan = result.plan;
      reviewReason = result.reason;
      remoteReviewStatus = result.status;
      reviewStatusNeedsRefresh = false;
      switch (result.status) {
        case WorkRemoteReviewStatus.pending:
          reviewStage = WorkReviewStage.gstPending;
          noticeMessage = null;
          return false;
        case WorkRemoteReviewStatus.rejected:
          errorMessage = null;
          return false;
        case WorkRemoteReviewStatus.suspended:
          errorMessage = result.reason?.trim().isNotEmpty == true
              ? result.reason
              : 'This Workspace is temporarily unavailable. Contact MoolSocial Support.';
          return false;
        case WorkRemoteReviewStatus.approved:
        case WorkRemoteReviewStatus.live:
          final approvedWorkspaceId = result.workspaceId!;
          workspaceId = approvedWorkspaceId;
          _workspaceApplications.removeWhere(
            (_, application) =>
                application.id == requestedApplication ||
                application.caseId == requestedCase,
          );
          reviewCorrectionDraft = false;
          reviewStage = result.status == WorkRemoteReviewStatus.live
              ? WorkReviewStage.live
              : WorkReviewStage.approved;
          final previousWorkspace = activeWorkspace;
          if (previousWorkspace != null &&
              previousWorkspace.id != approvedWorkspaceId &&
              otherWorkspaces.every(
                (workspace) => workspace.id != previousWorkspace.id,
              )) {
            otherWorkspaces.add(previousWorkspace);
          }
          activeWorkspace = WorkWorkspace(
            id: approvedWorkspaceId,
            name: previousWorkspace?.id == approvedWorkspaceId
                ? previousWorkspace!.name
                : result.name?.trim().isNotEmpty == true
                ? result.name!.trim()
                : submittedProfile?.name.trim().isNotEmpty == true
                ? submittedProfile!.name.trim()
                : workName.trim().isNotEmpty
                ? workName.trim()
                : selectedProfile?.label ?? 'Your Workspace',
            profileLabel: selectedProfile?.label ?? 'Work profile',
            profileId: selectedProfile?.id,
            area: result.area ?? submittedProfile?.area ?? workArea,
            verified: true,
            gstReminder: gstReminder && gstin.isEmpty,
          );
          _approvalWelcome = (
            scope: requestedScope,
            caseId: requestedCase,
            workspaceId: approvedWorkspaceId,
          );
          noticeMessage = null;
          return true;
      }
    } on WorkGatewayException catch (error) {
      if (current()) {
        errorMessage = error.message;
        noticeMessage = null;
      }
      return false;
    } finally {
      busy = false;
      if (current()) _queueContactDraft();
      if (!_disposed) notifyListeners();
    }
  }

  void beginRetailerSetup() {
    reviewStage = WorkReviewStage.setup;
    clearMessages();
    notifyListeners();
  }

  void reviseRejectedProfile() {
    if (remoteReviewStatus != WorkRemoteReviewStatus.rejected) return;
    clearMessages();
    noticeMessage = 'Contact MoolSocial about this application.';
    notifyListeners();
  }

  void addRetailerProduct() {
    retailerProductAdded = true;
    if (workspaceCatalogueItems.isEmpty) {
      workspaceCatalogueItems.add(
        workspaceMasterCatalogue.first.copyWith(publicListing: false),
      );
    }
    clearMessages();
    notifyListeners();
  }

  void saveRetailerProduct({
    required int quantity,
    required int buyPrice,
    required int sellPrice,
    bool updateCatalogue = true,
  }) {
    retailerQuantity = quantity;
    retailerBuyPrice = buyPrice;
    retailerSellPrice = sellPrice;
    if (updateCatalogue &&
        retailerProductAdded &&
        workspaceCatalogueItems.isNotEmpty) {
      workspaceCatalogueItems[0] = workspaceCatalogueItems.first.copyWith(
        stock: quantity,
        purchasePrice: buyPrice,
        sellingPrice: sellPrice,
        unitPrice: '₹$sellPrice/${workspaceCatalogueItems.first.pack}',
        available: quantity > 0,
      );
    }
    clearMessages();
    notifyListeners();
  }

  void setRetailerFulfilment({
    required bool homeDelivery,
    required bool storeCollection,
  }) {
    retailerHomeDelivery = homeDelivery;
    retailerStoreCollection = storeCollection;
    clearMessages();
    notifyListeners();
  }

  void setRetailerPublishAfterSetup(bool value) {
    retailerPublishAfterSetup = value;
    clearMessages();
    notifyListeners();
  }

  bool prepareWorkspaceOrder({
    required String source,
    required String fulfilment,
  }) {
    if (!startNewWorkspaceOrder()) return false;
    workspaceOrderSource = source;
    workspaceOrderFulfilment = fulfilment;
    workspaceOrderNeedsDelivery = const {
      'Mool delivery',
      'Own delivery',
    }.contains(fulfilment);
    notifyListeners();
    return true;
  }

  void applyConfirmedWorkspaceGroupBuyPayment({
    required String productName,
    required String specification,
    required int targetQuantity,
    required int securedQuantity,
    required String unitLabel,
    required int regularUnitPrice,
    required int groupUnitPrice,
    required int facilitationFee,
    required int deliveryFee,
    required int confirmationAmount,
    required String paymentReference,
    required String closingLabel,
    required String storeDeliveryLabel,
  }) {
    if (paymentReference.trim().isEmpty) {
      showError(
        'Group Bulk Buying becomes active only after payment confirmation is received.',
      );
      return;
    }
    final storeName = activeWorkspace?.name ?? workName;
    activeGroupBuy = WorkspaceGroupBuy(
      id: 'GB-${DateTime.now().millisecondsSinceEpoch}',
      productName: productName.trim(),
      specification: specification.trim(),
      leadRetailer: storeName,
      confirmedRetailers: [storeName],
      targetQuantity: targetQuantity,
      securedQuantity: securedQuantity,
      unitLabel: unitLabel.trim(),
      regularUnitPrice: regularUnitPrice,
      groupUnitPrice: groupUnitPrice,
      facilitationFee: facilitationFee,
      deliveryFee: deliveryFee,
      confirmationAmount: confirmationAmount,
      closingLabel: closingLabel.trim(),
      storeDeliveryLabel: storeDeliveryLabel.trim(),
      paymentConfirmed: true,
      participants: [
        WorkspaceGroupBuyParticipant(
          businessName: storeName,
          locality: activeWorkspace?.area ?? workArea,
          quantity: securedQuantity,
          unitLabel: unitLabel.trim(),
          milestone: 'Payment confirmed',
        ),
      ],
    );
    _recordWorkspaceActivity(
      '$storeName confirmed $securedQuantity $unitLabel of $productName for Group Bulk Buying.',
    );
    showNotice(
      'Payment confirmed. This Group Bulk Buying offer is now visible to eligible retailers.',
    );
    _persistOperationalState('group-buy-confirmed');
  }

  Future<bool> createWorkspaceGroupBuy({
    required String productName,
    required String specification,
    required int targetQuantity,
    required int securedQuantity,
    required String unitLabel,
    required int regularUnitPrice,
    required int groupUnitPrice,
    required int facilitationFee,
    required int deliveryFee,
    required int confirmationAmount,
    required String closingLabel,
    required String storeDeliveryLabel,
  }) async {
    final id = activeWorkspace?.id ?? workspaceId;
    if (id == null || id.isEmpty || busy) return false;
    final data = _storeData;
    final scope = _contactAccountScope;
    bool current() => _isStoreScopeCurrent(data, id, scope);
    final token = _beginBusyStoreOperation();
    clearMessages();
    notifyListeners();
    final values = <String, Object?>{
      'productName': productName,
      'specification': specification,
      'targetQuantity': targetQuantity,
      'securedQuantity': securedQuantity,
      'unitLabel': unitLabel,
      'regularUnitPrice': regularUnitPrice,
      'groupUnitPrice': groupUnitPrice,
      'facilitationFee': facilitationFee,
      'deliveryFee': deliveryFee,
      'confirmationAmount': confirmationAmount,
      'closingLabel': closingLabel,
      'storeDeliveryLabel': storeDeliveryLabel,
    };
    try {
      final reference = await gateway.createGroupBuy(
        WorkGroupBuySubmission(
          workspaceId: id,
          values: values,
          idempotencyKey: 'GROUP-$id-${DateTime.now().microsecondsSinceEpoch}',
        ),
      );
      if (!current()) return false;
      applyConfirmedWorkspaceGroupBuyPayment(
        productName: productName,
        specification: specification,
        targetQuantity: targetQuantity,
        securedQuantity: securedQuantity,
        unitLabel: unitLabel,
        regularUnitPrice: regularUnitPrice,
        groupUnitPrice: groupUnitPrice,
        facilitationFee: facilitationFee,
        deliveryFee: deliveryFee,
        confirmationAmount: confirmationAmount,
        paymentReference: reference,
        closingLabel: closingLabel,
        storeDeliveryLabel: storeDeliveryLabel,
      );
      return true;
    } on WorkGatewayException catch (error) {
      if (current()) showError(error.message);
      return false;
    } finally {
      _finishBusyStoreOperation(token);
    }
  }

  Future<bool> finishRetailerSetup() async {
    if (!retailerProductAdded) {
      errorMessage = 'Add at least one product from the verified catalogue.';
      notifyListeners();
      return false;
    }
    if (retailerQuantity <= 0) {
      errorMessage = 'Enter the available consumer quantity.';
      notifyListeners();
      return false;
    }
    if (retailerBuyPrice <= 0) {
      errorMessage = 'Enter the purchase price for margin checking.';
      notifyListeners();
      return false;
    }
    if (retailerSellPrice <= retailerBuyPrice) {
      errorMessage =
          'Enter a selling price above the purchase price, or correct the purchase cost.';
      notifyListeners();
      return false;
    }
    if (!retailerHomeDelivery && !retailerStoreCollection) {
      errorMessage =
          'Choose home delivery or store collection before going live.';
      notifyListeners();
      return false;
    }
    if (retailerSetupSaved) {
      noticeMessage = 'Shop setup is already complete.';
      errorMessage = null;
      notifyListeners();
      return true;
    }
    return _runBool(
      () async {
        final approvedWorkspaceId = workspaceId;
        if (approvedWorkspaceId == null) {
          throw const WorkGatewayException(
            'Wait for Workspace approval before finishing setup.',
          );
        }
        await gateway.finishSetup(
          workspaceId: approvedWorkspaceId,
          quantity: retailerQuantity,
          buyPrice: retailerBuyPrice,
          sellPrice: retailerSellPrice,
          homeDelivery: retailerHomeDelivery,
          storeCollection: retailerStoreCollection,
        );
        retailerSetupSaved = true;
        reviewStage = WorkReviewStage.live;
        if (retailerPublishAfterSetup && workspaceCatalogueItems.isNotEmpty) {
          workspaceCatalogueItems[0] = workspaceCatalogueItems.first.copyWith(
            publicListing: true,
          );
        }
        workspaceVisibleToCustomers = retailerPublishAfterSetup;
        workspaceAcceptingOrders = retailerPublishAfterSetup;
        workspaceStoreState = retailerPublishAfterSetup
            ? WorkspaceStoreState.open
            : WorkspaceStoreState.off;
        workspaceLastUpdatedAt = DateTime.now();
        _recordWorkspaceActivity(
          retailerPublishAfterSetup
              ? 'Store setup completed and opened for customers.'
              : 'Store setup completed and kept off.',
        );
      },
      success: retailerPublishAfterSetup
          ? 'Shop setup complete. Your available products are open for customers.'
          : 'Shop setup complete. Your store remains off until you choose Open.',
    );
  }

  void seedVerifiedWorkspace() {
    selectedProfile = workProfiles.first;
    workName = 'Mahadev Fresh Mart';
    workArea = 'Sardarpura, Jodhpur';
    primaryActivity = 'Grocery and household products';
    reviewCaseId = 'WP-240701';
    workspaceId = 'WK-510001';
    reviewStage = WorkReviewStage.approved;
    activeWorkspace = const WorkWorkspace(
      id: 'WK-510001',
      name: 'Mahadev Fresh Mart',
      profileLabel: 'Grocery / Kirana Shop',
      profileId: 'retailer-grocery',
      area: 'Sardarpura, Jodhpur',
      verified: true,
    );
    workspaceCatalogueItems
      ..clear()
      ..add(
        workspaceMasterCatalogue.first.copyWith(
          stock: 8,
          available: true,
          publicListing: true,
        ),
      );
    workspaceStockMovements.clear();
    workspaceStoreState = WorkspaceStoreState.off;
    workspaceAcceptingOrders = false;
    workspaceVisibleToCustomers = false;
    workspaceLastUpdatedAt = DateTime.now();
    workspacePayoutBankName = 'State Bank of India';
    workspacePayoutAccountEnding = '2486';
    notifyListeners();
  }

  void seedMultipleWorkspaces() {
    seedVerifiedWorkspace();
    otherWorkspaces
      ..clear()
      ..addAll(const [
        WorkWorkspace(
          id: 'WK-510002',
          name: 'Creator Work',
          profileLabel: 'Creator',
          profileId: 'creator',
          area: 'Remote India',
          verified: true,
        ),
        WorkWorkspace(
          id: 'WK-510003',
          name: 'Quick Delivery Work',
          profileLabel: 'Quick Delivery Biker',
          profileId: 'quick-delivery-biker',
          area: 'Jodhpur',
          verified: true,
        ),
      ]);
    notifyListeners();
  }

  void _restoreWorkspaceState(List<WorkReviewResult> records) {
    if (records.isEmpty) return;
    _rememberWorkspaceApplication();
    final currentApplication = _workspaceApplicationId;
    for (final record in records) {
      if (record.caseId.trim().isEmpty) continue;
      if (record.status == WorkRemoteReviewStatus.approved ||
          record.status == WorkRemoteReviewStatus.live) {
        // Only the gateway's approved records can create accessible Workspaces.
        if (record.workspaceId?.trim().isNotEmpty == true &&
            record.name != null &&
            record.area != null &&
            workProfiles.any((profile) => profile.id == record.profileId)) {
          _workspaceApplications.removeWhere(
            (_, value) => value.caseId == record.caseId,
          );
        }
        continue;
      }
      final previous = _workspaceApplications.values
          .where(
            (application) =>
                application.scope == _contactAccountScope &&
                application.caseId == record.caseId,
          )
          .firstOrNull;
      final profileId = previous?.details['profileId'] ?? record.profileId;
      if (!workProfiles.any((profile) => profile.id == profileId)) continue;
      if (record.profileId != null && record.profileId != profileId) continue;
      final id = previous?.id ?? 'application-${record.caseId}';
      _workspaceApplications[id] = _WorkspaceApplicationDraft(
        id: id,
        scope: _contactAccountScope,
        details: Map.unmodifiable({
          if (previous != null)
            ...previous.details
          else ...{
            'profileId': profileId,
            'name': record.name ?? '',
            'area': record.area ?? '',
            'activity': record.primaryActivity ?? '',
          },
          'caseId': record.caseId,
          'plan': record.plan,
        }),
        submitted: previous?.submitted,
        files: previous?.files ?? const {},
        confirmed: previous?.confirmed ?? const {},
        status: record.status,
        reason: record.reason,
      );
    }
    _restoreWorkspaceRecords(records);
    final application =
        _workspaceApplications[currentApplication] ??
        (activeWorkspace == null
            ? _workspaceApplications.values
                  .where((value) => value.caseId == reviewCaseId)
                  .firstOrNull
            : null);
    if (application != null) {
      _restoreWorkspaceApplication(application);
    } else {
      _workspaceApplicationId = null;
    }
    _queueContactDraft();
  }

  void _restoreWorkspaceRecords(List<WorkReviewResult> records) {
    if (records.isEmpty) return;
    final preferredId = activeWorkspace?.id;
    WorkWorkspace? restoredActive;
    final restoredOthers = <WorkWorkspace>[];
    WorkReviewResult? pending;
    WorkReviewResult? stopped;
    for (final record in records) {
      if (record.status == WorkRemoteReviewStatus.pending) {
        pending ??= record;
        continue;
      }
      if (record.status == WorkRemoteReviewStatus.rejected ||
          record.status == WorkRemoteReviewStatus.suspended) {
        stopped ??= record;
        continue;
      }
      if (record.status != WorkRemoteReviewStatus.approved &&
          record.status != WorkRemoteReviewStatus.live) {
        continue;
      }
      final id = record.workspaceId;
      final name = record.name;
      final area = record.area;
      final profileId = record.profileId;
      if (id == null || name == null || area == null || profileId == null) {
        continue;
      }
      final option = workProfiles
          .where((item) => item.id == profileId)
          .firstOrNull;
      if (option == null) continue;
      final workspace = WorkWorkspace(
        id: id,
        name: name,
        profileLabel: option.label,
        profileId: option.id,
        area: area,
        verified: true,
      );
      if (restoredActive == null ||
          id == preferredId ||
          (restoredActive.id != preferredId &&
              record.status == WorkRemoteReviewStatus.live)) {
        if (restoredActive != null) restoredOthers.add(restoredActive);
        restoredActive = workspace;
        selectedProfile = option;
        workName = name;
        workArea = area;
        primaryActivity = record.primaryActivity ?? '';
        reviewCaseId = record.caseId;
        workspaceId = id;
        subscriptionPlan = record.plan;
        remoteReviewStatus = record.status;
        _approvalWelcome = (
          scope: _contactAccountScope,
          caseId: record.caseId,
          workspaceId: id,
        );
        reviewStage = record.status == WorkRemoteReviewStatus.live
            ? WorkReviewStage.live
            : WorkReviewStage.approved;
      } else {
        restoredOthers.add(workspace);
      }
    }
    if (restoredActive != null) {
      activeWorkspace = restoredActive;
      otherWorkspaces
        ..clear()
        ..addAll(restoredOthers);
      return;
    }
    if (pending != null) {
      final option = workProfiles
          .where((item) => item.id == pending!.profileId)
          .firstOrNull;
      selectedProfile = option;
      selectedFamilyId = option?.familyId;
      workName = pending.name ?? workName;
      workArea = pending.area ?? workArea;
      primaryActivity = pending.primaryActivity ?? primaryActivity;
      reviewCaseId = pending.caseId;
      subscriptionPlan = pending.plan;
      reviewReason = pending.reason;
      remoteReviewStatus = pending.status;
      reviewStage = WorkReviewStage.gstPending;
      return;
    }
    if (stopped != null) {
      final option = workProfiles
          .where((item) => item.id == stopped!.profileId)
          .firstOrNull;
      selectedProfile = option;
      selectedFamilyId = option?.familyId;
      workName = stopped.name ?? workName;
      workArea = stopped.area ?? workArea;
      primaryActivity = stopped.primaryActivity ?? primaryActivity;
      reviewCaseId = stopped.caseId;
      subscriptionPlan = stopped.plan;
      reviewReason = stopped.reason;
      remoteReviewStatus = stopped.status;
      reviewStage = WorkReviewStage.gstPending;
    }
  }

  Future<bool> _runBool(
    Future<void> Function() action, {
    required String? success,
  }) async {
    if (busy) return false;
    busy = true;
    clearMessages();
    notifyListeners();
    try {
      await action();
      errorMessage = null;
      noticeMessage = success;
      return true;
    } on WorkGatewayException catch (error) {
      errorMessage = error.message;
      noticeMessage = null;
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}

bool _validEmail(String value) =>
    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);
