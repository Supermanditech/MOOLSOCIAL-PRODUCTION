import 'dart:async';

import 'package:flutter/foundation.dart';

import 'work_models.dart';
import 'work_services.dart';

class WorkSession extends ChangeNotifier {
  WorkSession({WorkGateway? gateway, WorkProofPicker? proofPicker})
    : gateway = gateway ?? ReviewWorkGateway(),
      proofPicker =
          proofPicker ??
          (kDebugMode &&
                  const bool.fromEnvironment('MOOLSOCIAL_DEVICE_REVIEW') &&
                  const bool.fromEnvironment('MOOLSOCIAL_UI_REVIEW_ONLY')
              ? NativeWorkProofPicker()
              : ReviewWorkProofPicker());

  WorkSession.production({WorkGateway? gateway, WorkProofPicker? proofPicker})
    : gateway = gateway ?? buildWorkGateway(),
      proofPicker = proofPicker ?? NativeWorkProofPicker();

  final WorkGateway gateway;
  final WorkProofPicker proofPicker;
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

  String workName = '';
  String workArea = '';
  String primaryActivity = '';
  final Map<String, String> addedProofs = <String, String>{};
  final Map<String, WorkPickedProof> pickedProofs = <String, WorkPickedProof>{};
  WorkProfileSubmission? submittedProfile;
  bool declarationAccepted = false;
  WorkReviewStage reviewStage = WorkReviewStage.none;
  String? reviewCaseId;
  String? workspaceId;
  String subscriptionPlan = 'free';
  String? reviewReason;
  WorkRemoteReviewStatus? remoteReviewStatus;
  bool reviewCorrectionDraft = false;
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

  WorkWorkspace? activeWorkspace;
  final List<WorkWorkspace> otherWorkspaces = <WorkWorkspace>[];

  bool retailerProductAdded = false;
  int retailerQuantity = 0;
  int retailerBuyPrice = 0;
  int retailerSellPrice = 0;
  bool retailerHomeDelivery = false;
  bool retailerStoreCollection = false;
  bool retailerPublishAfterSetup = false;
  bool retailerSetupSaved = false;
  bool initialWorkspaceStateLoaded = false;
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
      workspaceOrderStage != 'Completed' &&
      workspaceOrderStage != 'Cancelled';

  WorkspaceOrderRecord? get currentWorkspaceOrder => workspaceOrders
      .where((order) => order.id == currentWorkspaceOrderId)
      .firstOrNull;

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
    final digits = customer.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) return digits.substring(digits.length - 10);
    return customer.trim().toLowerCase();
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
      final mobileMatch = RegExp(
        r'(?:\+?91[\s-]?)?[6-9]\d(?:[\s-]?\d){8}',
      ).firstMatch(raw);
      final mobile = mobileMatch?.group(0)?.trim() ?? entry.key;
      final firstPart = parts.firstOrNull ?? raw;
      final name = RegExp(r'^\+?[\d\s-]+$').hasMatch(firstPart)
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

  List<WorkspacePackingLine> get workspacePackingLines {
    final order = currentWorkspaceOrder;
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
              packed: workspacePackedProductIds.contains(entry.key),
            );
          })
          .toList(growable: false);
    }
    final parts = workspaceOrderItems
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
          packed: workspacePackedProductIds.contains('summary-$index'),
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

  int get workspaceSettlementEligible =>
      (workspaceSettlementBalance -
              workspacePlatformAdjustments -
              workspaceDeliveryAdjustments -
              workspaceRefunds -
              workspaceTaxWithheld)
          .clamp(0, 1 << 31)
          .toInt();

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
    startNewWorkspaceOrder();
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
    final current = activeWorkspace;
    if (current == null || current.id == workspace.id) return;
    otherWorkspaces.removeWhere((item) => item.id == workspace.id);
    otherWorkspaces.add(current);
    activeWorkspace = workspace;
    workspaceId = workspace.id;
    workName = workspace.name;
    workArea = workspace.area;
    selectedProfile = workProfiles
        .where((profile) => profile.id == workspace.profileId)
        .firstOrNull;
    workspaceSearchQuery = '';
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
          'amount': order.amount,
          'source': order.source,
          'fulfilment': order.fulfilment,
          'payment': order.payment,
          'address': order.address,
          'stage': order.stage,
          'needsDelivery': order.needsDelivery,
          'createdAt': order.createdAt.toUtc().toIso8601String(),
          'actionDeadline': order.actionDeadline?.toUtc().toIso8601String(),
          'extraMinutes': order.extraMinutes,
          'stockReserved': order.stockReserved,
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
    final id = activeWorkspace?.id ?? workspaceId;
    if (id == null || id.isEmpty) return;
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
              state: _operationalState(),
              idempotencyKey: key,
            ),
          )
          .then((_) {
            if (_disposed) return;
            workspaceOperationsSyncing = false;
            workspaceOperationsSyncError = null;
            notifyListeners();
          })
          .catchError((Object error) {
            if (_disposed) return;
            workspaceOperationsSyncing = false;
            workspaceOperationsSyncError = error is WorkGatewayException
                ? error.message
                : 'Store changes could not sync. Your draft remains on this device.';
            notifyListeners();
          }),
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
    if (packed) {
      workspacePackedProductIds.add(id);
    } else {
      workspacePackedProductIds.remove(id);
    }
    notifyListeners();
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
    workspaceSettlementBalance += order.amount;
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
    workspaceDashboardState = WorkspaceDashboardState.refreshing;
    workspaceDashboardError = '';
    notifyListeners();
  }

  void saveWorkspaceOrderDraft({
    required String customer,
    required String source,
    required String fulfilment,
    required String payment,
    required String address,
  }) {
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
    workspaceOrderActionDeadline = DateTime.now().add(
      const Duration(seconds: 60),
    );
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
    final previous = workspaceOrderStage;
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
    final quickStoreOrder =
        order.source == 'App' &&
        const {
          'retailer-grocery',
          'retailer-speciality',
        }.contains(activeWorkspace?.profileId);
    final fulfilmentTarget = order.createdAt.add(const Duration(minutes: 10));
    workspaceOrderActionDeadline = switch (workspaceOrderStage) {
      'Preparing' ||
      'Ready' ||
      'Ready for pickup' when quickStoreOrder => fulfilmentTarget,
      'Preparing' => DateTime.now().add(const Duration(minutes: 15)),
      'Ready' => DateTime.now().add(const Duration(minutes: 10)),
      'Ready for pickup' => DateTime.now().add(const Duration(minutes: 10)),
      'Delivery requested' => workspaceDeliveryAssignment?.eta,
      _ => null,
    };
    order = order.copyWith(
      stage: workspaceOrderStage,
      actionDeadline: workspaceOrderActionDeadline,
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
    final id = activeWorkspace?.id ?? workspaceId;
    if (id == null || id.isEmpty) return;
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
      workspaceOperationsSyncError = error.message;
      showError(error.message);
    } finally {
      workspaceOperationsSyncing = false;
      notifyListeners();
    }
  }

  Future<bool> verifyWorkspaceHandover(String otp) async {
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
      _completeWorkspaceOrder(
        order,
        activity: 'Order handover confirmed by customer OTP.',
      );
      return true;
    } on WorkGatewayException catch (error) {
      showError(error.message);
      return false;
    } finally {
      workspaceHandoverBusy = false;
      notifyListeners();
    }
  }

  Future<bool> verifyWorkspacePickup(String code) async {
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
      _completeWorkspaceOrder(
        order,
        activity: 'Customer pickup confirmed with the order pickup code.',
      );
      return true;
    } on WorkGatewayException catch (error) {
      showError(error.message.replaceAll('delivery OTP', 'pickup code'));
      return false;
    } finally {
      workspaceHandoverBusy = false;
      notifyListeners();
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
    busy = true;
    clearMessages();
    notifyListeners();
    try {
      final result = await gateway.requestSettlement(
        workspaceId: id,
        amount: requestedAmount,
        idempotencyKey: 'SET-$id-${DateTime.now().microsecondsSinceEpoch}',
      );
      final accepted = result.acceptedAmount.clamp(0, requestedAmount).toInt();
      workspaceSettlementRequested += accepted;
      workspaceSettlementBalance = (workspaceSettlementBalance - accepted)
          .clamp(0, 1 << 31)
          .toInt();
      workspaceSettlementReference = result.reference;
      _recordWorkspaceActivity(
        'Settlement ${result.reference} requested for ₹$accepted.',
      );
      showNotice('Settlement request received for processing.');
      _persistOperationalState('settlement-requested');
    } on WorkGatewayException catch (error) {
      showError(error.message);
    } finally {
      busy = false;
      notifyListeners();
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
    busy = true;
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
      workspacePaidRequirementReference = reference;
      workspacePaidRequirementState = WorkspacePaidRequirementState.published;
      _recordWorkspaceActivity('Paid work $reference published for $position.');
      showNotice('Paid work published to Earn Today.');
      _persistOperationalState('paid-work-published');
      return true;
    } on WorkGatewayException catch (error) {
      showError(error.message);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void extendWorkspaceOrder(int minutes) {
    workspaceOrderExtraMinutes += minutes;
    workspaceOrderActionDeadline =
        (workspaceOrderActionDeadline ?? DateTime.now()).add(
          Duration(minutes: minutes),
        );
    final order = currentWorkspaceOrder;
    if (order != null) {
      final index = workspaceOrders.indexWhere((item) => item.id == order.id);
      if (index >= 0) {
        workspaceOrders[index] = order.copyWith(
          extraMinutes: workspaceOrderExtraMinutes,
          actionDeadline: workspaceOrderActionDeadline,
        );
      }
    }
    _recordWorkspaceActivity(
      'Customer preparation estimate extended by $minutes minutes.',
    );
    showNotice('Customer preparation estimate updated.');
    _persistOperationalState('order-time-extended');
  }

  void cancelWorkspaceOrder() {
    final order = _ensureCurrentOrderRecord();
    if (order.stockReserved) _releaseOrderStock(order);
    workspaceOrderStage = 'Cancelled';
    final index = workspaceOrders.indexWhere((item) => item.id == order.id);
    if (index >= 0) {
      workspaceOrders[index] = order.copyWith(
        stage: 'Cancelled',
        stockReserved: false,
      );
    }
    _recordWorkspaceActivity('Customer order cancelled.');
    showNotice('Order cancelled. Stock remains available.');
    _persistOperationalState('order-cancelled');
  }

  void startNewWorkspaceOrder() {
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
    await _run(() async {
      final records = await gateway.loadFeed();
      _restoreWorkspaceState(records);
      initialWorkspaceStateLoaded = true;
    }, success: 'Work opportunities refreshed.');
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

  void startAnotherWork() {
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
    if (activeWorkspace == null) reviewStage = WorkReviewStage.drafting;
    gstReminder = false;
    gstin = '';
    gstAttachmentAdded = false;
    gstProofReference = null;
    clearMessages();
    notifyListeners();
  }

  void selectFamily(String familyId) {
    selectedFamilyId = familyId;
    selectedProfile = null;
    clearMessages();
    notifyListeners();
  }

  void selectProfile(String profileId) {
    final nextProfile = workProfiles.firstWhere(
      (profile) => profile.id == profileId,
    );
    if (selectedProfile?.id != nextProfile.id) {
      addedProofs.removeWhere((id, _) => id != 'personal-kyc');
      declarationAccepted = false;
    }
    selectedProfile = nextProfile;
    clearMessages();
    notifyListeners();
  }

  void changeFamily() {
    selectedFamilyId = null;
    selectedProfile = null;
    clearMessages();
    notifyListeners();
  }

  void hydrateAccountSnapshot(WorkAccountSnapshot snapshot) {
    accountDisplayName = snapshot.displayName.trim();
    if (authorizedPersonName.isEmpty) authorizedPersonName = accountDisplayName;
    connectedProviderLabel = snapshot.providerLabel.trim();
    connectedProviderAccount = snapshot.providerAccount.trim();
    if (primaryMobile.isEmpty) {
      final digits = snapshot.mobile.replaceAll(RegExp(r'\D'), '');
      final normalized = digits.length > 10
          ? digits.substring(digits.length - 10)
          : digits;
      if (normalized.length == 10) {
        primaryMobile = normalized;
        primaryMobileVerified = snapshot.mobileConfirmed;
      }
    }
    if (contactEmail.isEmpty) {
      final normalized = snapshot.email.trim().toLowerCase();
      if (_validEmail(normalized)) {
        contactEmail = normalized;
        contactEmailVerified = snapshot.emailConfirmed;
      }
    }
  }

  bool get workspaceContactsReady =>
      primaryMobileVerified &&
      contactEmailVerified &&
      (alternateMobile.isEmpty || alternateVerified);

  void savePersonName(String value) {
    if (authorizedPersonName != value.trim()) declarationAccepted = false;
    authorizedPersonName = value.trim();
  }

  void saveBusinessRelationship(String value) {
    if (businessRelationship != value) declarationAccepted = false;
    businessRelationship = value;
    notifyListeners();
  }

  void editWorkspaceContact(WorkContactChannel channel, String value) {
    final normalized = channel == WorkContactChannel.email
        ? value.trim().toLowerCase()
        : value.replaceAll(RegExp(r'\D'), '');
    final previous = switch (channel) {
      WorkContactChannel.primaryMobile => primaryMobile,
      WorkContactChannel.email => contactEmail,
      WorkContactChannel.alternateMobile => alternateMobile,
    };
    if (normalized == previous) return;
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
    clearMessages();
    notifyListeners();
  }

  Future<bool> sendPrimaryMobileOtp(String mobile) async {
    final normalized = mobile.replaceAll(RegExp(r'\D'), '');
    if (normalized.length != 10) {
      errorMessage = 'Enter a valid 10-digit phone number.';
      notifyListeners();
      return false;
    }
    primaryMobile = normalized;
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
    final normalized = email.trim().toLowerCase();
    if (!_validEmail(normalized)) {
      errorMessage = 'Enter a valid email address.';
      notifyListeners();
      return false;
    }
    contactEmail = normalized;
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
    alternateMobile = normalized;
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
    return _runBool(() async {
      await gateway.sendContactOtp(channel: channel, value: value);
      if (_disposed || revision != (_contactRevisions[channel] ?? 0)) {
        throw const WorkGatewayException(
          'Contact changed. Request a new code.',
        );
      }
      onSent();
    }, success: 'Code sent. Enter it to confirm this contact.');
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
      errorMessage = 'Send the OTP before verification.';
      notifyListeners();
      return false;
    }
    final normalizedCode = code.replaceAll(RegExp(r'\D'), '');
    if (normalizedCode.length != 6) {
      errorMessage = 'Enter the complete 6-digit OTP.';
      notifyListeners();
      return false;
    }
    final revision = _contactRevisions[channel] ?? 0;
    return _runBool(() async {
      await gateway.verifyContactOtp(
        channel: channel,
        value: value,
        code: normalizedCode,
      );
      if (_disposed || revision != (_contactRevisions[channel] ?? 0)) {
        throw const WorkGatewayException(
          'Contact changed. Request a new code.',
        );
      }
      onVerified();
    }, success: 'Contact confirmed for this Workspace.');
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
    if (!primaryMobileVerified) {
      errorMessage =
          'Confirm the phone number customers can reach you on before continuing.';
      notifyListeners();
      return false;
    }
    if (!contactEmailVerified) {
      errorMessage = 'Confirm your email address before continuing.';
      notifyListeners();
      return false;
    }
    if (alternateMobile.isNotEmpty && !alternateVerified) {
      errorMessage = 'Confirm or remove the alternate contact number.';
      notifyListeners();
      return false;
    }
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
          'This request cannot be sent yet. Your details remain saved on this device.';
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
    clearMessages();
    notifyListeners();
  }

  bool validateDetails() {
    if (workName.length < 3) {
      errorMessage = 'Enter the business name shown on its PAN card.';
      notifyListeners();
      return false;
    }
    if (workArea.length < 3) {
      errorMessage = 'Enter an operating city or PIN code.';
      notifyListeners();
      return false;
    }
    if (primaryActivity.length < 3) {
      errorMessage = 'Describe the primary activity.';
      notifyListeners();
      return false;
    }
    clearMessages();
    notifyListeners();
    return true;
  }

  Future<bool> addProof(String proofId, WorkProofSource source) async {
    if (busy) return false;
    busy = true;
    clearMessages();
    notifyListeners();
    try {
      final proof = await proofPicker.pick(source);
      if (proof == null) return false;
      addedProofs[proofId] = await gateway.saveProof(proofId, proof);
      pickedProofs[proofId] = proof;
      declarationAccepted = false;
      noticeMessage = 'Document received. You can review it before submission.';
      return true;
    } on WorkGatewayException catch (error) {
      if (!error.cancelled) errorMessage = error.message;
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void removeProof(String proofId) {
    addedProofs.remove(proofId);
    pickedProofs.remove(proofId);
    declarationAccepted = false;
    showNotice('Document removed. You can add a replacement during review.');
  }

  void setDeclaration(bool value) {
    declarationAccepted = value;
    clearMessages();
    notifyListeners();
  }

  bool beginReviewCorrection() {
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
    if (existingCaseId != null && reviewCorrectionDraft) {
      return _runBool(
        () async {
          final submission = _currentProfileSubmission();
          final result = await gateway.submitCorrection(
            existingCaseId,
            submission,
          );
          submittedProfile = submission;
          reviewCaseId = result.caseId;
          subscriptionPlan = result.plan;
          reviewReason = result.reason;
          remoteReviewStatus = result.status;
          reviewStage = WorkReviewStage.gstPending;
          reviewCorrectionDraft = false;
        },
        success:
            'Your Workspace correction was sent with the existing review reference.',
      );
    }
    if (existingCaseId != null) {
      noticeMessage =
          'This Workspace is already under review as $existingCaseId.';
      errorMessage = null;
      notifyListeners();
      return true;
    }
    return _runBool(
      () async {
        final submission = _currentProfileSubmission();
        final result = await gateway.submitProfile(submission);
        submittedProfile = submission;
        reviewCaseId = result.caseId;
        subscriptionPlan = result.plan;
        reviewReason = result.reason;
        remoteReviewStatus = result.status;
        reviewStage = WorkReviewStage.gstPending;
      },
      success:
          'Work profile sent for review. Your personal account remains active.',
    );
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
    try {
      final requestedCase = reviewCaseId!;
      final result = await gateway.checkReview(requestedCase);
      if (_disposed || reviewCaseId != requestedCase) return false;
      if (result.caseId != requestedCase) {
        throw const WorkGatewayException(
          'The review update could not be matched to this application. Please retry.',
        );
      }
      subscriptionPlan = result.plan;
      reviewReason = result.reason;
      remoteReviewStatus = result.status;
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
          final approvedWorkspaceId = result.workspaceId;
          if (approvedWorkspaceId == null || approvedWorkspaceId.isEmpty) {
            throw const WorkGatewayException(
              'Approval was received without a Workspace. Try checking again.',
              retryable: true,
            );
          }
          workspaceId = approvedWorkspaceId;
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
                : selectedProfile?.label ?? 'Your Workspace',
            profileLabel: selectedProfile?.label ?? 'Work profile',
            profileId: selectedProfile?.id,
            area: workArea,
            verified: true,
            gstReminder: gstReminder && gstin.isEmpty,
          );
          noticeMessage = null;
          return true;
      }
    } on WorkGatewayException catch (error) {
      errorMessage = error.message;
      noticeMessage = null;
      return false;
    } finally {
      busy = false;
      notifyListeners();
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
      workspaceCatalogueItems.add(workspaceMasterCatalogue.first);
    }
    clearMessages();
    notifyListeners();
  }

  void saveRetailerProduct({
    required int quantity,
    required int buyPrice,
    required int sellPrice,
  }) {
    retailerQuantity = quantity;
    retailerBuyPrice = buyPrice;
    retailerSellPrice = sellPrice;
    if (workspaceCatalogueItems.isEmpty) {
      workspaceCatalogueItems.add(workspaceMasterCatalogue.first);
    }
    workspaceCatalogueItems[0] = workspaceCatalogueItems.first.copyWith(
      stock: quantity,
      purchasePrice: buyPrice,
      sellingPrice: sellPrice,
      unitPrice: '₹$sellPrice/${workspaceCatalogueItems.first.pack}',
      available: quantity > 0,
      publicListing: true,
    );
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

  void prepareWorkspaceOrder({
    required String source,
    required String fulfilment,
  }) {
    startNewWorkspaceOrder();
    workspaceOrderSource = source;
    workspaceOrderFulfilment = fulfilment;
    workspaceOrderNeedsDelivery = const {
      'Mool delivery',
      'Own delivery',
    }.contains(fulfilment);
    notifyListeners();
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
    busy = true;
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
      showError(error.message);
      return false;
    } finally {
      busy = false;
      notifyListeners();
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
          record.status == WorkRemoteReviewStatus.live) {
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

  Future<void> _run(
    Future<void> Function() action, {
    required String success,
  }) async {
    await _runBool(action, success: success);
  }

  Future<bool> _runBool(
    Future<void> Function() action, {
    required String success,
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
