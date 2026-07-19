import 'package:flutter/foundation.dart';

import 'retailer_business_services_models.dart';
import 'retailer_business_services_services.dart';
import 'retailer_books_models.dart';
import 'retailer_books_services.dart';
import 'retailer_campaign_models.dart';
import 'retailer_campaign_services.dart';
import 'retailer_models.dart';
import 'retailer_pos_models.dart';
import 'retailer_pos_services.dart';
import 'retailer_services.dart';
import 'retailer_wholesale_models.dart';
import 'retailer_wholesale_services.dart';

class RetailerSession extends ChangeNotifier {
  RetailerSession({
    ReviewRetailerGateway? gateway,
    ReviewRetailerPosGateway? posGateway,
    ReviewRetailerWholesaleGateway? wholesaleGateway,
    ReviewRetailerBooksGateway? booksGateway,
    ReviewRetailerBusinessServicesGateway? businessServicesGateway,
    ReviewRetailerCampaignGateway? campaignGateway,
  }) : gateway = gateway ?? ReviewRetailerGateway(),
       posGateway = posGateway ?? ReviewRetailerPosGateway(),
       wholesaleGateway = wholesaleGateway ?? ReviewRetailerWholesaleGateway(),
       booksGateway = booksGateway ?? ReviewRetailerBooksGateway(),
       businessServicesGateway =
           businessServicesGateway ?? ReviewRetailerBusinessServicesGateway(),
       campaignGateway = campaignGateway ?? ReviewRetailerCampaignGateway(),
       orders = buildReviewRetailerOrders(),
       counters = buildReviewCounters(),
       sales = buildReviewSales(),
       purchases = buildReviewPurchaseRecords(),
       stockMovements = List.of(reviewStockMovements),
       moneyExceptions = buildReviewMoneyExceptions(),
       campaigns = buildReviewRetailerCampaigns();

  final ReviewRetailerGateway gateway;
  final ReviewRetailerPosGateway posGateway;
  final ReviewRetailerWholesaleGateway wholesaleGateway;
  final ReviewRetailerBooksGateway booksGateway;
  final ReviewRetailerBusinessServicesGateway businessServicesGateway;
  final ReviewRetailerCampaignGateway campaignGateway;
  final List<RetailerOrder> orders;
  final List<RetailerCounter> counters;
  final List<RetailerSaleRecord> sales;
  final List<RetailerPurchaseRecord> purchases;
  final List<RetailerStockMovement> stockMovements;
  final List<RetailerMoneyException> moneyExceptions;
  final List<RetailerCampaign> campaigns;

  RetailerHomeView view = RetailerHomeView.home;
  bool ordersOnline = true;
  bool busy = false;
  String searchQuery = '';
  String? errorMessage;
  String? noticeMessage;
  String? selectedOrderId;
  bool orderLinesExpanded = false;
  String? selectedCannotFulfilReason;
  String? selectedIssueReason;
  bool handoverOtpVisible = false;
  bool businessBookRecorded = false;

  RetailerOrderSource posSource = RetailerOrderSource.phone;
  RetailerFulfilment posFulfilment = RetailerFulfilment.moolDelivery;
  RetailerPosPayment posPayment = RetailerPosPayment.paymentRequest;
  final Map<String, int> posCart = {'oil': 1, 'atta': 1, 'salt': 0};
  String activeCounterId = 'CTR-01';
  String customerMobile = '';
  bool customerKnown = true;
  bool posOnline = true;
  bool cashConfirmed = false;
  bool customerMessagingConsent = true;
  bool businessBookAuthorized = true;
  String? posOrderId;
  String? posInvoiceId;
  String? lastSharedChannel;
  String? lastExportFormat;
  RetailerSalesBookView salesBookView = RetailerSalesBookView.sales;
  RetailerSaleSource? salesSourceFilter;
  bool salesDueOnly = false;
  String salesSearchQuery = '';
  String? selectedSaleId;

  RetailerWholesaleCategory wholesaleCategory = RetailerWholesaleCategory.all;
  String wholesaleSearchQuery = '';
  final Map<String, int> wholesaleCart = {};
  bool wholesaleOnline = true;
  bool cameraAllowed = true;
  List<RetailerPurchaseOrder> purchaseOrders = [];
  String? selectedPurchaseOrderId;
  RetailerGoodsReceiptChoice receiptChoice = RetailerGoodsReceiptChoice.pending;
  RetailerGoodsIssue? goodsIssue;
  bool goodsEvidenceAttached = false;
  String? goodsReceiptId;
  int acceptedStockPacks = 16;
  RetailerPurchaseBookView purchaseBookView =
      RetailerPurchaseBookView.purchases;
  String purchaseSourceFilter = 'all';
  String purchaseSearchQuery = '';
  String? selectedPurchaseId;
  bool purchaseBookAuthorized = true;
  String? lastPurchaseExport;
  RetailerSupplierPaymentMethod supplierPaymentMethod =
      RetailerSupplierPaymentMethod.upi;
  RetailerSupplierPaymentState supplierPaymentState =
      RetailerSupplierPaymentState.notStarted;
  String? supplierPaymentId;

  RetailerStockStatementView stockStatementView =
      RetailerStockStatementView.movements;
  RetailerStockMovementType? stockMovementFilter;
  String stockSearchQuery = '';
  String? selectedStockMovementId;
  String? selectedStockCheckId;
  RetailerStockAdjustmentKind stockAdjustmentKind =
      RetailerStockAdjustmentKind.physicalCount;
  String? stockAdjustmentId;
  String? lastStockExport;
  RetailerBusinessPeriod businessPeriod = RetailerBusinessPeriod.month;
  bool businessBookOnline = true;
  String? lastBusinessExport;
  String? matchedCustomerPaymentId;
  final List<RetailerExpense> expenses = [];
  String? expenseId;
  String? selectedMoneyExceptionId;

  bool businessServicesOnline = true;
  bool businessServicesAuthorized = true;
  bool businessServicesCatalogueAvailable = true;
  RetailerBusinessServiceOffering? selectedBusinessService;
  RetailerBusinessPlan? selectedBusinessPlan;
  int businessServiceMonthlyLimit = 3000;
  bool businessServiceCustomLimit = false;
  RetailerBusinessPayment businessServicePayment = RetailerBusinessPayment.upi;
  bool businessServiceCommercialConsent = false;
  bool businessServiceDataConsent = false;
  bool businessServiceTermsReviewed = false;
  final Map<RetailerBusinessServiceType, RetailerActiveBusinessService>
  activeBusinessServices = {};

  bool customerCampaignOnline = true;
  bool customerCampaignAuthorized = true;
  RetailerCustomerFilter customerFilter = RetailerCustomerFilter.all;
  String customerSearchQuery = '';
  String selectedCustomerId = 'sharma';
  RetailerMessageChannel reminderChannel = RetailerMessageChannel.moolChat;
  String reminderMessage =
      'Your usual atta, rice and oil basket is available. Review current prices before ordering.';
  String? reminderMessageId;
  RetailerCampaignFilter campaignFilter = RetailerCampaignFilter.all;
  int campaignBuilderStep = 0;
  RetailerCampaignObjective campaignObjective =
      RetailerCampaignObjective.increaseSales;
  String campaignName = 'Monthly staples offer';
  final Set<String> campaignProductIds = {'atta', 'oil'};
  RetailerCampaignBenefit campaignBenefit =
      RetailerCampaignBenefit.basketSaving;
  int campaignMaximumOrders = 30;
  RetailerCampaignAudience campaignAudience =
      RetailerCampaignAudience.repeatCustomers;
  int campaignRadiusKm = 5;
  int campaignDurationDays = 7;
  RetailerCampaignChannel campaignChannel = RetailerCampaignChannel.moolSocial;
  int campaignSpendCap = 1500;
  String? campaignDraftId;
  String? publishedCampaignId;

  List<RetailerOrder> get filteredOrders {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return List.unmodifiable(orders);
    return orders
        .where(
          (order) =>
              order.id.toLowerCase().contains(query) ||
              order.customer.toLowerCase().contains(query) ||
              order.area.toLowerCase().contains(query) ||
              order.lines.any(
                (line) => line.name.toLowerCase().contains(query),
              ),
        )
        .toList(growable: false);
  }

  RetailerOrder? get selectedOrder {
    final id = selectedOrderId;
    if (id == null) return null;
    for (final order in orders) {
      if (order.id == id) return order;
    }
    return null;
  }

  int get openOrderCount => orders
      .where(
        (order) =>
            order.stage != RetailerOrderStage.delivered &&
            order.stage != RetailerOrderStage.cannotFulfil,
      )
      .length;

  RetailerCounter get activeCounter => counters.firstWhere(
    (counter) => counter.id == activeCounterId,
    orElse: () => counters.first,
  );

  List<RetailerPosProduct> get posProducts => reviewPosProducts;

  int posQuantity(String productId) => posCart[productId] ?? 0;

  int get posItemCount => reviewPosProducts.fold(
    0,
    (sum, product) => sum + posQuantity(product.id),
  );

  int get posSubtotal => reviewPosProducts.fold(
    0,
    (sum, product) => sum + (posQuantity(product.id) * product.price),
  );

  int get posDeliveryFee =>
      posFulfilment == RetailerFulfilment.moolDelivery ? 48 : 0;

  int get posTotal => posSubtotal + posDeliveryFee;

  bool get posSaleCompleted => posInvoiceId != null;

  List<RetailerPosPayment> get availablePosPayments =>
      posSource == RetailerOrderSource.counter
      ? const [
          RetailerPosPayment.cash,
          RetailerPosPayment.upi,
          RetailerPosPayment.card,
        ]
      : const [
          RetailerPosPayment.paymentRequest,
          RetailerPosPayment.onDelivery,
          RetailerPosPayment.due,
        ];

  List<RetailerSaleRecord> get visibleSales {
    final query = salesSearchQuery.trim().toLowerCase();
    return sales
        .where((sale) {
          final viewMatches = switch (salesBookView) {
            RetailerSalesBookView.sales =>
              sale.status != RetailerSaleStatus.returned,
            RetailerSalesBookView.payments =>
              sale.status == RetailerSaleStatus.due,
            RetailerSalesBookView.returns =>
              sale.status == RetailerSaleStatus.returned,
          };
          final sourceMatches =
              salesSourceFilter == null || sale.source == salesSourceFilter;
          final dueMatches =
              !salesDueOnly || sale.status == RetailerSaleStatus.due;
          final searchMatches =
              query.isEmpty ||
              '${sale.invoiceId} ${sale.title} ${sale.customer} ${sale.orderId}'
                  .toLowerCase()
                  .contains(query);
          return viewMatches && sourceMatches && dueMatches && searchMatches;
        })
        .toList(growable: false);
  }

  RetailerSaleRecord? get selectedSale {
    final id = selectedSaleId;
    if (id == null) return null;
    for (final sale in sales) {
      if (sale.invoiceId == id) return sale;
    }
    return null;
  }

  int get counterSalesTotal =>
      counters.fold(0, (sum, counter) => sum + counter.salesAmount);

  int get counterOrderTotal =>
      counters.fold(0, (sum, counter) => sum + counter.orderCount);

  int get openCounterCount =>
      counters.where((counter) => counter.isOpen).length;

  List<RetailerWholesaleProduct> get visibleWholesaleProducts {
    final query = wholesaleSearchQuery.trim().toLowerCase();
    return reviewWholesaleProducts
        .where((product) {
          final searchMatches =
              query.isEmpty ||
              '${product.brand} ${product.name} ${product.pack} ${product.id}'
                  .toLowerCase()
                  .contains(query);
          final categoryMatches = switch (wholesaleCategory) {
            RetailerWholesaleCategory.all => true,
            RetailerWholesaleCategory.deals =>
              product.offer.toLowerCase().contains('save') ||
                  product.offer.contains('%'),
            RetailerWholesaleCategory.fastDelivery =>
              product.delivery == 'Today' || product.delivery == 'Tomorrow',
            RetailerWholesaleCategory.credit =>
              product.payment.toLowerCase().contains('credit'),
            RetailerWholesaleCategory.brands => true,
          };
          return searchMatches && categoryMatches;
        })
        .toList(growable: false);
  }

  int wholesaleQuantity(String productId) => wholesaleCart[productId] ?? 0;

  int get wholesaleCaseCount =>
      wholesaleCart.values.fold(0, (sum, value) => sum + value);

  int get wholesaleCartTotal => reviewWholesaleProducts.fold(
    0,
    (sum, product) => sum + product.casePrice * wholesaleQuantity(product.id),
  );

  List<RetailerPurchaseRecord> get visiblePurchases {
    final query = purchaseSearchQuery.trim().toLowerCase();
    return purchases
        .where((purchase) {
          final viewMatches = switch (purchaseBookView) {
            RetailerPurchaseBookView.purchases => true,
            RetailerPurchaseBookView.payables =>
              purchase.status.toLowerCase().contains('due') ||
                  purchase.status.toLowerCase().contains('processing'),
            RetailerPurchaseBookView.returns =>
              purchase.status.toLowerCase().contains('return'),
          };
          final sourceMatches =
              purchaseSourceFilter == 'all' ||
              (purchaseSourceFilter == 'platform' &&
                  purchase.source == 'MoolSocial PO') ||
              (purchaseSourceFilter == 'direct' &&
                  purchase.source == 'Direct bill') ||
              (purchaseSourceFilter == 'paid' &&
                  purchase.status.toLowerCase() == 'paid');
          final searchMatches =
              query.isEmpty ||
              '${purchase.supplier} ${purchase.poId} ${purchase.invoiceId} ${purchase.summary}'
                  .toLowerCase()
                  .contains(query);
          return viewMatches && sourceMatches && searchMatches;
        })
        .toList(growable: false);
  }

  RetailerPurchaseRecord? get selectedPurchase {
    final id = selectedPurchaseId;
    if (id == null) return null;
    for (final purchase in purchases) {
      if (purchase.id == id) return purchase;
    }
    return null;
  }

  List<RetailerStockMovement> get visibleStockMovements {
    final query = stockSearchQuery.trim().toLowerCase();
    return stockMovements
        .where((movement) {
          final typeMatches =
              stockMovementFilter == null ||
              movement.type == stockMovementFilter;
          final searchMatches =
              query.isEmpty ||
              '${movement.product} ${movement.sku} ${movement.source} ${movement.reference}'
                  .toLowerCase()
                  .contains(query);
          return typeMatches && searchMatches;
        })
        .toList(growable: false);
  }

  List<RetailerStockCheck> get visibleStockChecks {
    final query = stockSearchQuery.trim().toLowerCase();
    return reviewStockChecks
        .where(
          (check) =>
              query.isEmpty ||
              '${check.product} ${check.reason} ${check.action}'
                  .toLowerCase()
                  .contains(query),
        )
        .toList(growable: false);
  }

  RetailerStockMovement? get selectedStockMovement {
    final id = selectedStockMovementId;
    if (id == null) return null;
    for (final movement in stockMovements) {
      if (movement.id == id) return movement;
    }
    return null;
  }

  List<RetailerMoneyException> get openMoneyExceptions => moneyExceptions
      .where((exception) => !exception.resolved)
      .toList(growable: false);

  int get activeBusinessServiceCount => activeBusinessServices.length;

  RetailerActiveBusinessService? activeBusinessService(
    RetailerBusinessServiceType type,
  ) => activeBusinessServices[type];

  bool get businessServiceCanActivate {
    final service = selectedBusinessService;
    return selectedBusinessPlan != null &&
        businessServiceMonthlyLimit >= 1000 &&
        businessServiceCommercialConsent &&
        (service == null ||
            !service.requiresDataConsent ||
            businessServiceDataConsent);
  }

  RetailerPurchaseOrder? get selectedPurchaseOrder {
    final id = selectedPurchaseOrderId;
    if (id == null) return null;
    for (final order in purchaseOrders) {
      if (order.id == id) return order;
    }
    return purchaseOrders.isEmpty ? null : purchaseOrders.first;
  }

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

  void setView(RetailerHomeView value) {
    clearMessages();
    view = value;
    notifyListeners();
  }

  void search(String value) {
    clearMessages();
    searchQuery = value;
    notifyListeners();
  }

  void clearSearch() {
    searchQuery = '';
    clearMessages();
    notifyListeners();
  }

  Future<void> refreshOrders() => _run(
    gateway.refreshOrders,
    success: 'Orders are current. No duplicate order was created.',
  );

  Future<void> setOrdersOnline(bool value) async {
    final previous = ordersOnline;
    await _run(
      () => gateway.setAvailability(value),
      success: value
          ? 'New customer orders are on.'
          : 'New customer orders are paused. Accepted orders remain active.',
      afterSuccess: () => ordersOnline = value,
      afterFailure: () => ordersOnline = previous,
    );
  }

  RetailerOrder openOrder(String id) {
    final order = ensureOrder(id);
    notifyListeners();
    return order;
  }

  RetailerOrder ensureOrder(String id) {
    clearMessages();
    selectedOrderId = id;
    orderLinesExpanded = false;
    final order = orders.firstWhere(
      (candidate) => candidate.id == id,
      orElse: () => orders.first,
    );
    selectedOrderId = order.id;
    return order;
  }

  void toggleOrderLines() {
    orderLinesExpanded = !orderLinesExpanded;
    notifyListeners();
  }

  void contactCustomer(String channel) {
    showNotice(
      channel == 'call'
          ? 'A masked customer call is ready. Your personal number stays private.'
          : 'Order chat is opening with ${selectedOrder?.id ?? 'this order'} attached.',
    );
  }

  Future<bool> acceptSelectedOrder() async {
    final order = selectedOrder;
    if (order == null) {
      _showError('Choose an order before accepting it.');
      return false;
    }
    if (order.stage != RetailerOrderStage.newOrder) {
      showNotice('This order is already ${order.stage.label.toLowerCase()}.');
      return true;
    }
    return _runBool(
      () => gateway.acceptOrder(order.id),
      success: 'Order accepted. Start packing before the shown deadline.',
      afterSuccess: () => order.stage = RetailerOrderStage.accepted,
    );
  }

  void startPacking() {
    final order = selectedOrder;
    if (order == null) return;
    clearMessages();
    if (order.stage == RetailerOrderStage.accepted) {
      order.stage = RetailerOrderStage.packing;
      noticeMessage = 'Packing started. Check every product before sealing.';
    }
    notifyListeners();
  }

  void togglePackedLine(String id) {
    final order = selectedOrder;
    if (order == null || order.stage != RetailerOrderStage.packing) return;
    final line = order.lines.firstWhere((item) => item.id == id);
    line.packed = !line.packed;
    clearMessages();
    notifyListeners();
  }

  Future<bool> markOrderPacked() async {
    final order = selectedOrder;
    if (order == null) {
      _showError('Choose an order before packing it.');
      return false;
    }
    if (!order.allPacked) {
      _showError(
        'Check every product before marking the order packed. ${order.packedCount} of ${order.lines.length} groups are checked.',
      );
      return false;
    }
    if (order.stage == RetailerOrderStage.packed) {
      showNotice('Packed status is already saved.');
      return true;
    }
    return _runBool(
      () => gateway.savePackedOrder(order.id),
      success:
          'Order packed. Request delivery when the sealed parcel is ready.',
      afterSuccess: () => order.stage = RetailerOrderStage.packed,
    );
  }

  Future<bool> requestDelivery() async {
    final order = selectedOrder;
    if (order == null) {
      _showError('Choose a packed order before requesting delivery.');
      return false;
    }
    if (order.stage.index < RetailerOrderStage.packed.index) {
      _showError('Finish and save packing before requesting delivery.');
      return false;
    }
    if (order.deliveryReference != null) {
      showNotice('Delivery is already assigned to this order.');
      return true;
    }
    order.stage = RetailerOrderStage.deliveryRequested;
    notifyListeners();
    return _runBool(
      () async {
        final reference = await gateway.requestDelivery(order.id);
        order.deliveryReference = reference;
      },
      success: 'Delivery assigned. Keep the parcel until captain handover.',
      afterSuccess: () {
        order
          ..stage = RetailerOrderStage.captainAssigned
          ..captainName = 'Rakesh Kumar'
          ..captainVehicle = 'RJ 19 SX 4821';
      },
      afterFailure: () => order.stage = RetailerOrderStage.packed,
    );
  }

  void markParcelReady() {
    final order = selectedOrder;
    if (order?.stage != RetailerOrderStage.captainAssigned) return;
    clearMessages();
    order!.stage = RetailerOrderStage.parcelReady;
    noticeMessage = 'Parcel ready recorded. Wait for the assigned captain.';
    notifyListeners();
  }

  void markCaptainArrived() {
    final order = selectedOrder;
    if (order?.stage != RetailerOrderStage.parcelReady) return;
    clearMessages();
    order!.stage = RetailerOrderStage.captainArrived;
    noticeMessage =
        'Captain is at the shop. Match the name and vehicle before OTP.';
    notifyListeners();
  }

  void beginHandoverVerification() {
    final order = selectedOrder;
    if (order?.stage != RetailerOrderStage.captainArrived) return;
    clearMessages();
    handoverOtpVisible = true;
    notifyListeners();
  }

  bool verifyHandoverOtp(String value) {
    final order = selectedOrder;
    if (order == null) return false;
    if (value.trim() != '2841') {
      _showError('Enter the 4-digit handover OTP shown to the captain.');
      return false;
    }
    clearMessages();
    order.stage = RetailerOrderStage.handoverVerified;
    handoverOtpVisible = false;
    noticeMessage = 'Captain verified. Hand over the sealed parcel now.';
    notifyListeners();
    return true;
  }

  Future<bool> handOverParcel() async {
    final order = selectedOrder;
    if (order?.stage != RetailerOrderStage.handoverVerified) {
      _showError('Verify the captain OTP before handing over the parcel.');
      return false;
    }
    return _runBool(
      () async {
        order!.handoverReference = await gateway.confirmHandover(order.id);
      },
      success: 'Parcel handed over. Live delivery tracking is active.',
      afterSuccess: () => order!.stage = RetailerOrderStage.handedOver,
    );
  }

  void openTracking() {
    ensureTrackingOpen();
    notifyListeners();
  }

  void ensureTrackingOpen() {
    final order = selectedOrder;
    if (order?.stage == RetailerOrderStage.handedOver) {
      order!.stage = RetailerOrderStage.outForDelivery;
    }
    clearMessages();
  }

  Future<bool> refreshTracking() async {
    final order = selectedOrder;
    if (order == null) return false;
    if (order.stage == RetailerOrderStage.delivered) {
      showNotice(
        'Delivery is complete. No further location refresh is needed.',
      );
      return true;
    }
    return _runBool(
      () => gateway.refreshTracking(order.id),
      success: switch (order.stage) {
        RetailerOrderStage.outForDelivery =>
          'Captain is near the customer. Delivery proof is still required.',
        RetailerOrderStage.nearby =>
          'Customer received the order. Payment and proof are recorded.',
        _ => 'Live delivery status is current.',
      },
      afterSuccess: () {
        if (order.stage == RetailerOrderStage.outForDelivery) {
          order.stage = RetailerOrderStage.nearby;
        } else if (order.stage == RetailerOrderStage.nearby) {
          order
            ..stage = RetailerOrderStage.delivered
            ..deliveryProof = 'Customer OTP · 8:04 PM';
          businessBookRecorded = true;
        }
      },
    );
  }

  void chooseCannotFulfilReason(String value) {
    selectedCannotFulfilReason = value;
    clearMessages();
    notifyListeners();
  }

  Future<bool> submitCannotFulfil() async {
    final order = selectedOrder;
    final reason = selectedCannotFulfilReason;
    if (order == null || reason == null) {
      _showError('Choose why the paid order cannot be fulfilled.');
      return false;
    }
    return _runBool(
      () => gateway.cannotFulfil(order.id, reason),
      success:
          'Order not fulfilled. The customer refund path is open and stock was not reduced.',
      afterSuccess: () {
        order
          ..stage = RetailerOrderStage.cannotFulfil
          ..cannotFulfilReason = reason;
      },
    );
  }

  void chooseIssueReason(String value) {
    selectedIssueReason = value;
    clearMessages();
    notifyListeners();
  }

  Future<bool> submitDeliveryIssue() async {
    final order = selectedOrder;
    final reason = selectedIssueReason;
    if (order == null || reason == null) {
      _showError('Choose the delivery issue before sending it.');
      return false;
    }
    return _runBool(() async {
      order.issueReference = await gateway.createIssue(order.id, reason);
    }, success: 'Delivery issue sent with the order and captain attached.');
  }

  void openBusinessBook() {
    showNotice(
      businessBookRecorded
          ? '₹${selectedOrder?.amount ?? 1240} sale and delivery proof are recorded in Business Book.'
          : 'Business Book is ready. This order will post only after delivery completion.',
    );
  }

  void ensurePosOrderSource(RetailerOrderSource value, {String? counterId}) {
    if (posOrderId == null) {
      posSource = value;
      customerKnown = value != RetailerOrderSource.counter;
      posFulfilment = value == RetailerOrderSource.counter
          ? RetailerFulfilment.counter
          : RetailerFulfilment.moolDelivery;
      posPayment = value == RetailerOrderSource.counter
          ? RetailerPosPayment.upi
          : RetailerPosPayment.paymentRequest;
    }
    if (counterId != null &&
        counters.any((counter) => counter.id == counterId)) {
      activeCounterId = counterId;
    }
  }

  void selectPosSource(RetailerOrderSource value) {
    if (posOrderId != null) {
      _showError('Start a new order before changing how this order began.');
      return;
    }
    clearMessages();
    posSource = value;
    customerKnown = value != RetailerOrderSource.counter;
    customerMobile = '';
    posFulfilment = value == RetailerOrderSource.counter
        ? RetailerFulfilment.counter
        : RetailerFulfilment.moolDelivery;
    posPayment = value == RetailerOrderSource.counter
        ? RetailerPosPayment.upi
        : RetailerPosPayment.paymentRequest;
    cashConfirmed = false;
    notifyListeners();
  }

  void setCustomerMobile(String value) {
    customerMobile = value.replaceAll(RegExp(r'\D'), '');
    clearMessages();
  }

  bool findCounterCustomer() {
    if (customerMobile.length != 10) {
      _showError(
        'Enter a 10-digit mobile number, or continue without customer details.',
      );
      return false;
    }
    customerKnown = true;
    customerMessagingConsent = true;
    clearMessages();
    noticeMessage =
        'Sharma Family found. Purchase history and invoice delivery are ready.';
    notifyListeners();
    return true;
  }

  void continueWithoutCustomer() {
    customerKnown = false;
    customerMobile = '';
    customerMessagingConsent = false;
    clearMessages();
    noticeMessage =
        'Counter sale can continue without personal customer details.';
    notifyListeners();
  }

  void changeCounterCustomer() {
    customerKnown = false;
    customerMobile = '';
    customerMessagingConsent = false;
    clearMessages();
    notifyListeners();
  }

  void setCustomerMessagingConsent(bool value) {
    customerMessagingConsent = value;
    clearMessages();
    notifyListeners();
  }

  void adjustPosQuantity(String productId, int change) {
    if (posOrderId != null) {
      _showError('Choose Edit order before changing reserved products.');
      return;
    }
    final product = reviewPosProducts.firstWhere(
      (item) => item.id == productId,
    );
    final current = posQuantity(productId);
    final next = (current + change).clamp(0, product.stock).toInt();
    clearMessages();
    if (next == current && change > 0) {
      noticeMessage =
          '${product.name} is limited to ${product.stock} available packs.';
    } else {
      posCart[productId] = next;
    }
    notifyListeners();
  }

  void clearPosCart() {
    if (posOrderId != null) return;
    for (final product in reviewPosProducts) {
      posCart[product.id] = 0;
    }
    clearMessages();
    notifyListeners();
  }

  void useRepeatBasket() {
    if (posOrderId != null) return;
    posCart
      ..['oil'] = 1
      ..['atta'] = 2
      ..['salt'] = 1;
    clearMessages();
    noticeMessage = 'The last verified basket is ready for review.';
    notifyListeners();
  }

  void useBarcodeResult({bool permissionDenied = false}) {
    if (permissionDenied) {
      _showError(
        'Camera access was not allowed. Search My Stock or enable camera access in device settings.',
      );
      return;
    }
    adjustPosQuantity('salt', 1);
    showNotice('Tata Salt matched in My Stock and was added once.');
  }

  void useVoiceResult({bool permissionDenied = false}) {
    if (permissionDenied) {
      _showError(
        'Microphone access was not allowed. Search My Stock or enable microphone access in device settings.',
      );
      return;
    }
    adjustPosQuantity('atta', 1);
    showNotice('“One atta 1 kg” matched and was added once.');
  }

  void selectPosFulfilment(RetailerFulfilment value) {
    if (posOrderId != null) return;
    clearMessages();
    posFulfilment = value;
    notifyListeners();
  }

  void selectPosPayment(RetailerPosPayment value) {
    if (posSaleCompleted) return;
    clearMessages();
    posPayment = value;
    cashConfirmed = value != RetailerPosPayment.cash;
    notifyListeners();
  }

  Future<bool> createPosOrder() async {
    if (posOrderId != null) {
      showNotice('$posOrderId is already created. No duplicate was added.');
      return true;
    }
    if (posItemCount == 0) {
      _showError(
        'Add at least one available product before creating the order.',
      );
      return false;
    }
    if (!availablePosPayments.contains(posPayment)) {
      _showError('Choose a payment option available for this order source.');
      return false;
    }
    if (!posOnline) {
      _showError(
        'You are offline. The draft remains on this device; reconnect and retry to reserve stock.',
      );
      return false;
    }
    final fingerprint =
        '${posSource.name}-${posCart.entries.map((item) => '${item.key}:${item.value}').join(',')}-${posFulfilment.name}-${posPayment.name}';
    return _runBool(
      () async {
        posOrderId = await posGateway.createOrder(fingerprint);
      },
      success: 'Order created. Products are reserved once for this customer.',
      afterSuccess: () {
        final id = posOrderId!;
        if (posSource != RetailerOrderSource.counter &&
            !orders.any((order) => order.id == id)) {
          orders.insert(
            0,
            RetailerOrder(
              id: id,
              customer: customerKnown ? 'Sharma Family' : 'Phone customer',
              area: 'Sardarpura · assisted order',
              payment: '${posPayment.label} · ₹$posTotal',
              fulfilment: posFulfilment.label,
              deliveryPromise: posFulfilment == RetailerFulfilment.counter
                  ? 'Collect at shop'
                  : 'Delivery promise shown after acceptance',
              amount: posTotal,
              stage: RetailerOrderStage.accepted,
              lines: [
                for (final product in reviewPosProducts.where(
                  (item) => posQuantity(item.id) > 0,
                ))
                  RetailerOrderLine(
                    id: product.id,
                    name: product.name,
                    detail: product.pack,
                    quantity: posQuantity(product.id),
                    amount: product.price * posQuantity(product.id),
                  ),
              ],
            ),
          );
        }
      },
    );
  }

  void editCreatedPosOrder() {
    posOrderId = null;
    posInvoiceId = null;
    cashConfirmed = posPayment != RetailerPosPayment.cash;
    clearMessages();
    notifyListeners();
  }

  void startNewPosOrder({RetailerOrderSource? source}) {
    posOrderId = null;
    posInvoiceId = null;
    lastSharedChannel = null;
    cashConfirmed = false;
    customerMobile = '';
    for (final product in reviewPosProducts) {
      posCart[product.id] = 0;
    }
    selectPosSource(source ?? RetailerOrderSource.counter);
  }

  void ensureSaleReady() {
    if (posOrderId != null) return;
    posSource = RetailerOrderSource.counter;
    posFulfilment = RetailerFulfilment.counter;
    posPayment = RetailerPosPayment.upi;
    customerKnown = true;
    customerMessagingConsent = true;
    posCart
      ..['oil'] = 1
      ..['atta'] = 1
      ..['salt'] = 1;
    posOrderId = 'RT-3028';
  }

  void confirmCashReceived(bool value) {
    cashConfirmed = value;
    clearMessages();
    notifyListeners();
  }

  Future<bool> completePosSale() async {
    ensureSaleReady();
    if (posInvoiceId != null) {
      showNotice(
        '$posInvoiceId is already complete. No second sale was posted.',
      );
      return true;
    }
    if (posPayment == RetailerPosPayment.cash && !cashConfirmed) {
      _showError(
        'Confirm that ₹$posTotal cash was received before completing the sale.',
      );
      return false;
    }
    if (!posOnline) {
      _showError(
        'You are offline. Payment is not posted; reconnect and retry before handing over the receipt.',
      );
      return false;
    }
    final orderId = posOrderId!;
    final succeeded = await _runBool(
      () async {
        posInvoiceId = await posGateway.completeSale(orderId, posPayment.name);
      },
      success:
          'Sale complete. Stock, payment, invoice and Sales Book were posted once.',
    );
    if (!succeeded) return false;
    final invoiceId = posInvoiceId!;
    if (!sales.any((sale) => sale.invoiceId == invoiceId)) {
      sales.insert(
        0,
        RetailerSaleRecord(
          invoiceId: invoiceId,
          source: RetailerSaleSource.counter,
          title: 'Counter ${activeCounter.number} · ${activeCounter.purpose}',
          subtitle: 'Sharma Family · $posItemCount items · just now',
          amount: posTotal,
          payment: '${posPayment.label} received',
          status: RetailerSaleStatus.paid,
          customer: customerKnown ? 'Sharma Family' : 'Counter customer',
          orderId: orderId,
          fulfilment: posFulfilment.label,
          stockPosting: '$posItemCount units posted',
          margin: '₹64',
        ),
      );
      activeCounter
        ..orderCount += 1
        ..salesAmount += posTotal
        ..activity.insert(
          0,
          '$orderId · ${posPayment.label} paid · ₹$posTotal',
        );
      businessBookRecorded = true;
      notifyListeners();
    }
    return true;
  }

  Future<bool> sharePosInvoice(String channel) async {
    final invoiceId = posInvoiceId;
    if (invoiceId == null) {
      _showError('Complete the sale before sending its invoice.');
      return false;
    }
    if ((channel == 'WhatsApp' || channel == 'SMS') &&
        !customerMessagingConsent) {
      _showError(
        'Customer consent is required before sending an invoice by $channel.',
      );
      return false;
    }
    if (lastSharedChannel == channel) {
      showNotice('Invoice $invoiceId was already prepared for $channel.');
      return true;
    }
    if (!posOnline) {
      _showError(
        'Reconnect before sending the invoice. The sale remains complete.',
      );
      return false;
    }
    return _runBool(
      () => posGateway.shareInvoice(invoiceId, channel),
      success: channel == 'QR / Print'
          ? 'Invoice QR is ready for the customer.'
          : 'Invoice $invoiceId sent by $channel.',
      afterSuccess: () => lastSharedChannel = channel,
    );
  }

  void selectCounter(String id) {
    if (!counters.any((counter) => counter.id == id)) return;
    activeCounterId = id;
    clearMessages();
    notifyListeners();
  }

  Future<bool> createCounter({
    required String purpose,
    required String operatorName,
    required bool open,
  }) async {
    final cleanPurpose = purpose.trim();
    final cleanOperator = operatorName.trim();
    if (cleanPurpose.length < 3) {
      _showError('Enter a clear counter purpose, such as Main Billing.');
      return false;
    }
    if (counters.any(
      (counter) => counter.purpose.toLowerCase() == cleanPurpose.toLowerCase(),
    )) {
      _showError(
        'A $cleanPurpose counter already exists. Choose it or use another purpose.',
      );
      return false;
    }
    if (!posOnline) {
      _showError('Reconnect before creating a counter.');
      return false;
    }
    final number = counters.length + 1;
    final id = 'CTR-${number.toString().padLeft(2, '0')}';
    return _runBool(
      () => posGateway.saveCounter(id),
      success: 'Counter $number created and ready for shop orders.',
      afterSuccess: () {
        counters.add(
          RetailerCounter(
            id: id,
            number: number,
            purpose: cleanPurpose,
            operatorName: cleanOperator.isEmpty ? 'Unassigned' : cleanOperator,
            isOpen: open,
            orderCount: 0,
            salesAmount: 0,
            activity: [],
          ),
        );
        activeCounterId = id;
      },
    );
  }

  Future<bool> updateActiveCounter({
    required String purpose,
    required String operatorName,
    required bool open,
  }) async {
    final counter = activeCounter;
    final cleanPurpose = purpose.trim();
    if (cleanPurpose.length < 3) {
      _showError('Enter a clear counter purpose before saving changes.');
      return false;
    }
    if (counters.any(
      (item) =>
          item.id != counter.id &&
          item.purpose.toLowerCase() == cleanPurpose.toLowerCase(),
    )) {
      _showError('Another counter already uses that purpose.');
      return false;
    }
    if (!posOnline) {
      _showError('Reconnect before saving counter changes.');
      return false;
    }
    return _runBool(
      () => posGateway.saveCounter(counter.id),
      success: 'Counter ${counter.number} changes saved.',
      afterSuccess: () {
        counter
          ..purpose = cleanPurpose
          ..operatorName = operatorName.trim().isEmpty
              ? 'Unassigned'
              : operatorName.trim()
          ..isOpen = open;
      },
    );
  }

  Future<bool> setActiveCounterOpen(bool open) async {
    final counter = activeCounter;
    if (counter.isOpen == open) {
      showNotice(
        'Counter ${counter.number} is already ${open ? 'open' : 'closed'}.',
      );
      return true;
    }
    if (!posOnline) {
      _showError('Reconnect before changing counter availability.');
      return false;
    }
    return _runBool(
      () => posGateway.setCounterOpen(counter.id, open),
      success:
          'Counter ${counter.number} is ${open ? 'open for orders' : 'closed safely'}.',
      afterSuccess: () => counter.isOpen = open,
    );
  }

  void setPosConnectivity(bool online) {
    posOnline = online;
    clearMessages();
    noticeMessage = online
        ? 'Connection restored. You can retry the pending action.'
        : 'Offline. Drafts remain visible, but stock and payment changes will wait.';
    notifyListeners();
  }

  void setSalesBookView(RetailerSalesBookView value) {
    salesBookView = value;
    salesDueOnly = false;
    clearMessages();
    notifyListeners();
  }

  void setSalesSourceFilter(RetailerSaleSource? value, {bool dueOnly = false}) {
    salesSourceFilter = value;
    salesDueOnly = dueOnly;
    clearMessages();
    notifyListeners();
  }

  void searchSales(String value) {
    salesSearchQuery = value;
    clearMessages();
    notifyListeners();
  }

  void clearSalesFilters() {
    salesSearchQuery = '';
    salesSourceFilter = null;
    salesDueOnly = false;
    clearMessages();
    notifyListeners();
  }

  void selectSale(String invoiceId) {
    selectedSaleId = invoiceId;
    clearMessages();
    notifyListeners();
  }

  void reviewPaymentAttention() {
    salesBookView = RetailerSalesBookView.payments;
    salesSourceFilter = null;
    salesDueOnly = false;
    clearMessages();
    notifyListeners();
  }

  Future<bool> refreshSalesBook() async {
    if (!businessBookAuthorized) {
      _showError('Your current shop role cannot open financial records.');
      return false;
    }
    if (!posOnline) {
      _showError(
        'The Sales Book is offline. Existing records remain available.',
      );
      return false;
    }
    return _runBool(
      posGateway.refreshSales,
      success: 'Sales Book is current. No sale was duplicated.',
    );
  }

  Future<bool> exportSalesBook(String format) async {
    if (!businessBookAuthorized) {
      _showError('Owner or accountant permission is required for exports.');
      return false;
    }
    if (!posOnline) {
      _showError('Reconnect before creating a period-locked sales export.');
      return false;
    }
    return _runBool(
      () => posGateway.exportSales(format),
      success: '$format is ready for the selected sales period.',
      afterSuccess: () => lastExportFormat = format,
    );
  }

  void setWholesaleOnline(bool value) {
    wholesaleOnline = value;
    clearMessages();
    notifyListeners();
  }

  void searchWholesale(String value) {
    wholesaleSearchQuery = value;
    clearMessages();
    notifyListeners();
  }

  void setWholesaleCategory(RetailerWholesaleCategory value) {
    wholesaleCategory = value;
    clearMessages();
    notifyListeners();
  }

  void changeWholesaleQuantity(String productId, int change) {
    final product = reviewWholesaleProducts.firstWhere(
      (item) => item.id == productId,
    );
    final current = wholesaleQuantity(productId);
    final next = change > 0
        ? (current == 0 ? product.moq : current + 1)
        : (current <= product.moq ? 0 : current - 1);
    if (next > product.availableCases) {
      _showError(
        'Only ${product.availableCases} cases are currently available. Your existing cart is unchanged.',
      );
      return;
    }
    if (next == 0) {
      wholesaleCart.remove(productId);
    } else {
      wholesaleCart[productId] = next;
    }
    clearMessages();
    notifyListeners();
  }

  void buildLowStockReorder() {
    wholesaleCart['oil-case'] = 2;
    wholesaleCart['atta-case'] = 3;
    clearMessages();
    noticeMessage =
        'MOQ-ready reorder added. Review current price and delivery before placing it.';
    notifyListeners();
  }

  Future<bool> placeWholesaleOrders() async {
    if (purchaseOrders.isNotEmpty) {
      noticeMessage =
          'These purchase orders already exist. No duplicate order was created.';
      notifyListeners();
      return true;
    }
    if (wholesaleCart.isEmpty) {
      _showError('Add at least one wholesale product before placing an order.');
      return false;
    }
    if (!wholesaleOnline) {
      _showError(
        'Wholesale ordering is offline. Your cart remains saved for retry.',
      );
      return false;
    }
    final fingerprint = wholesaleCart.entries
        .map((entry) => '${entry.key}:${entry.value}')
        .join('|');
    if (busy) return false;
    clearMessages();
    busy = true;
    notifyListeners();
    var completed = false;
    try {
      final ids = await wholesaleGateway.placeOrders(fingerprint);
      final entries = wholesaleCart.entries.toList(growable: false);
      purchaseOrders = [
        for (var index = 0; index < entries.length; index += 1)
          (() {
            final entry = entries[index];
            final product = reviewWholesaleProducts.firstWhere(
              (item) => item.id == entry.key,
            );
            return RetailerPurchaseOrder(
              id: ids[index < ids.length ? index : ids.length - 1],
              supplier: product.id == 'atta-case'
                  ? 'Jodhpur Authorised Distributor'
                  : 'Supermandi Area Supply',
              productId: product.id,
              productName: '${product.brand} ${product.name}',
              cases: entry.value,
              value: entry.value * product.casePrice,
              deliveryMode: product.id == 'atta-case'
                  ? 'MoolSocial Transport'
                  : 'Supplier fleet',
              deliveryWindow: product.delivery == 'Today'
                  ? 'Today · 4–7 PM'
                  : 'Tomorrow · 2–6 PM',
              paymentTerm: product.payment,
            );
          })(),
      ];
      selectedPurchaseOrderId = purchaseOrders.last.id;
      noticeMessage =
          '${purchaseOrders.length} supplier-wise purchase order${purchaseOrders.length == 1 ? '' : 's'} placed.';
      completed = true;
    } on RetailerGatewayException catch (error) {
      errorMessage = error.message;
    } finally {
      busy = false;
      notifyListeners();
    }
    return completed;
  }

  void selectPurchaseOrder(String orderId) {
    selectedPurchaseOrderId = orderId;
    clearMessages();
    notifyListeners();
  }

  Future<bool> refreshWholesaleDelivery() async {
    final order = selectedPurchaseOrder;
    if (order == null) {
      _showError('Choose a purchase order to refresh.');
      return false;
    }
    if (!wholesaleOnline) {
      _showError(
        'Tracking is offline. The last verified delivery update remains visible.',
      );
      return false;
    }
    return _runBool(
      () => wholesaleGateway.refreshDelivery(order.id),
      success: 'Delivery status is current.',
    );
  }

  void advanceWholesaleDelivery() {
    final order = selectedPurchaseOrder;
    if (order == null) return;
    order.stage = switch (order.stage) {
      RetailerPurchaseOrderStage.confirmed =>
        RetailerPurchaseOrderStage.dispatched,
      RetailerPurchaseOrderStage.dispatched =>
        RetailerPurchaseOrderStage.inTransit,
      RetailerPurchaseOrderStage.inTransit =>
        RetailerPurchaseOrderStage.delivered,
      _ => order.stage,
    };
    clearMessages();
    notifyListeners();
  }

  void chooseGoodsReceipt(RetailerGoodsReceiptChoice value) {
    receiptChoice = value;
    if (value != RetailerGoodsReceiptChoice.issue) {
      goodsIssue = null;
      goodsEvidenceAttached = false;
    }
    clearMessages();
    notifyListeners();
  }

  void chooseGoodsIssue(RetailerGoodsIssue value) {
    receiptChoice = RetailerGoodsReceiptChoice.issue;
    goodsIssue = value;
    clearMessages();
    notifyListeners();
  }

  void attachGoodsEvidence({required bool permissionGranted}) {
    cameraAllowed = permissionGranted;
    if (!permissionGranted) {
      _showError(
        'Camera access was not allowed. Upload a saved photo or continue with written evidence.',
      );
      return;
    }
    goodsEvidenceAttached = true;
    clearMessages();
    noticeMessage = 'Delivery evidence attached.';
    notifyListeners();
  }

  Future<bool> postGoodsReceipt() async {
    if (goodsReceiptId != null) {
      noticeMessage =
          'Goods receipt $goodsReceiptId is already posted. Stock was not added again.';
      notifyListeners();
      return true;
    }
    if (receiptChoice == RetailerGoodsReceiptChoice.pending) {
      _showError('Choose All received or Report issue before confirming.');
      return false;
    }
    if (receiptChoice == RetailerGoodsReceiptChoice.issue &&
        goodsIssue == null) {
      _showError('Choose the goods issue before submitting the receipt.');
      return false;
    }
    if (!wholesaleOnline) {
      _showError(
        'Goods receipt is offline. No stock or supplier payment was changed.',
      );
      return false;
    }
    final order = selectedPurchaseOrder;
    if (order == null) {
      _showError('The purchase order could not be found.');
      return false;
    }
    if (busy) return false;
    clearMessages();
    busy = true;
    notifyListeners();
    var completed = false;
    try {
      final grn = await wholesaleGateway.postReceipt(order.id, receiptChoice);
      goodsReceiptId = grn;
      final issue = receiptChoice == RetailerGoodsReceiptChoice.issue;
      acceptedStockPacks += issue ? 8 : 12;
      order.stage = issue
          ? RetailerPurchaseOrderStage.issueOpen
          : RetailerPurchaseOrderStage.received;
      purchases.removeWhere((purchase) => purchase.grnId == grn);
      purchases.insert(
        0,
        RetailerPurchaseRecord(
          id: 'PUR-85021',
          supplier: order.supplier,
          summary:
              '${order.productName} · ${issue ? 2 : 3} cases · ${issue ? 8 : 12} packs',
          amount: issue ? 1904 : 2856,
          source: 'MoolSocial PO',
          status: issue ? 'Issue open' : 'Processing',
          invoiceId: 'INV-SM-2941',
          poId: order.id,
          grnId: grn,
        ),
      );
      noticeMessage = issue
          ? 'Accepted stock posted once. Disputed payment remains protected.'
          : 'Goods receipt posted once. Stock and Purchase Book are updated.';
      completed = true;
    } on RetailerGatewayException catch (error) {
      errorMessage = error.message;
    } finally {
      busy = false;
      notifyListeners();
    }
    return completed;
  }

  void setPurchaseBookView(RetailerPurchaseBookView value) {
    purchaseBookView = value;
    clearMessages();
    notifyListeners();
  }

  void setPurchaseSourceFilter(String value) {
    purchaseSourceFilter = value;
    clearMessages();
    notifyListeners();
  }

  void searchPurchases(String value) {
    purchaseSearchQuery = value;
    clearMessages();
    notifyListeners();
  }

  void selectPurchase(String purchaseId) {
    selectedPurchaseId = purchaseId;
    clearMessages();
    notifyListeners();
  }

  Future<bool> refreshPurchaseBook() async {
    if (!purchaseBookAuthorized) {
      _showError('Your current shop role cannot open financial records.');
      return false;
    }
    if (!wholesaleOnline) {
      _showError(
        'The Purchase Book is offline. Existing records remain available.',
      );
      return false;
    }
    return _runBool(
      wholesaleGateway.refreshPurchases,
      success: 'Purchase Book is current. No purchase was duplicated.',
    );
  }

  Future<bool> exportPurchaseBook(String format) async {
    if (!purchaseBookAuthorized) {
      _showError('Owner or accountant permission is required for exports.');
      return false;
    }
    if (!wholesaleOnline) {
      _showError('Reconnect before creating a purchase export.');
      return false;
    }
    return _runBool(
      () => wholesaleGateway.exportPurchases(format),
      success: '$format purchase report is ready.',
      afterSuccess: () => lastPurchaseExport = format,
    );
  }

  void chooseSupplierPaymentMethod(RetailerSupplierPaymentMethod value) {
    supplierPaymentMethod = value;
    clearMessages();
    notifyListeners();
  }

  Future<bool> authorizeSupplierPayment() async {
    if (supplierPaymentId != null) {
      noticeMessage =
          'Payment $supplierPaymentId is already authorized. No duplicate payment was created.';
      notifyListeners();
      return true;
    }
    if (!wholesaleOnline) {
      _showError(
        'Supplier payment is offline. The bill remains unpaid and unchanged.',
      );
      return false;
    }
    if (busy) return false;
    clearMessages();
    busy = true;
    notifyListeners();
    var completed = false;
    try {
      supplierPaymentId = await wholesaleGateway.authorizeSupplierPayment(
        'INV-RTD-665',
        supplierPaymentMethod,
      );
      supplierPaymentState = RetailerSupplierPaymentState.processing;
      noticeMessage =
          'Payment authorization submitted. Settlement is not confirmed yet.';
      completed = true;
    } on RetailerGatewayException catch (error) {
      errorMessage = error.message;
    } finally {
      busy = false;
      notifyListeners();
    }
    return completed;
  }

  Future<bool> refreshSupplierPayment() async {
    final paymentId = supplierPaymentId;
    if (paymentId == null) {
      _showError('No supplier payment is available to refresh.');
      return false;
    }
    if (!wholesaleOnline) {
      _showError(
        'Payment status is offline. Do not pay again while the last verified state is ${supplierPaymentState.label.toLowerCase()}.',
      );
      return false;
    }
    if (busy) return false;
    clearMessages();
    busy = true;
    notifyListeners();
    var completed = false;
    try {
      supplierPaymentState = await wholesaleGateway.refreshSupplierPayment(
        paymentId,
      );
      RetailerPurchaseRecord? record;
      for (final purchase in purchases) {
        if (purchase.invoiceId == 'INV-RTD-665') {
          record = purchase;
          break;
        }
      }
      if (record != null) {
        record.status = switch (supplierPaymentState) {
          RetailerSupplierPaymentState.settled => 'Paid',
          RetailerSupplierPaymentState.failed => 'Due 25 Jul',
          RetailerSupplierPaymentState.reversed => 'Due · reversed',
          _ => 'Processing',
        };
      }
      noticeMessage = switch (supplierPaymentState) {
        RetailerSupplierPaymentState.settled =>
          'Payment settled. The supplier balance and Purchase Book are updated.',
        RetailerSupplierPaymentState.failed =>
          'Payment failed. The supplier bill remains due and no settlement was recorded.',
        RetailerSupplierPaymentState.reversed =>
          'Payment was reversed. The supplier obligation is due again.',
        _ => 'Payment remains processing. Do not pay again.',
      };
      completed = true;
    } on RetailerGatewayException catch (error) {
      errorMessage = error.message;
    } finally {
      busy = false;
      notifyListeners();
    }
    return completed;
  }

  void setBusinessBookOnline(bool value) {
    businessBookOnline = value;
    clearMessages();
    notifyListeners();
  }

  void setStockStatementView(RetailerStockStatementView value) {
    stockStatementView = value;
    clearMessages();
    notifyListeners();
  }

  void setStockMovementFilter(RetailerStockMovementType? value) {
    stockStatementView = RetailerStockStatementView.movements;
    stockMovementFilter = value;
    clearMessages();
    notifyListeners();
  }

  void searchStockStatement(String value) {
    stockSearchQuery = value;
    clearMessages();
    notifyListeners();
  }

  void selectStockMovement(String movementId) {
    selectedStockMovementId = movementId;
    clearMessages();
    notifyListeners();
  }

  void selectStockCheck(String checkId) {
    selectedStockCheckId = checkId;
    clearMessages();
    notifyListeners();
  }

  Future<bool> refreshStockStatement() async {
    if (!businessBookAuthorized) {
      _showError('Your current shop role cannot open stock financial value.');
      return false;
    }
    if (!businessBookOnline) {
      _showError(
        'The Stock Statement is offline. Existing movements remain available.',
      );
      return false;
    }
    return _runBool(
      booksGateway.refreshStock,
      success: 'Stock Statement is current. No movement was duplicated.',
    );
  }

  Future<bool> recordStockAdjustment({
    required RetailerStockAdjustmentKind kind,
    required int quantity,
    required String reason,
  }) async {
    if (stockAdjustmentId != null) {
      noticeMessage =
          'Stock change $stockAdjustmentId is already recorded. Quantity was not changed again.';
      notifyListeners();
      return true;
    }
    if (quantity <= 0) {
      _showError('Enter a quantity greater than zero.');
      return false;
    }
    if (reason.trim().length < 4) {
      _showError('Enter a clear reason for this stock change.');
      return false;
    }
    if (!businessBookAuthorized) {
      _showError('Shop owner approval is required for stock changes.');
      return false;
    }
    if (!businessBookOnline) {
      _showError(
        'Stock changes are offline. No available quantity was changed.',
      );
      return false;
    }
    if (busy) return false;
    clearMessages();
    busy = true;
    notifyListeners();
    var completed = false;
    try {
      stockAdjustmentId = await booksGateway.adjustStock(
        kind,
        quantity,
        reason.trim(),
      );
      stockAdjustmentKind = kind;
      final negative = kind != RetailerStockAdjustmentKind.physicalCount;
      stockMovements.insert(
        0,
        RetailerStockMovement(
          id: 'MOV-$stockAdjustmentId',
          product: 'Fortune Sunflower Oil 1 L',
          sku: 'FRT-1L',
          source: kind.label,
          reference:
              '$stockAdjustmentId · ${reason.trim()} · shop owner approved',
          change: negative ? -quantity : quantity,
          balance: negative ? 7 - quantity : 7 + quantity,
          type: kind == RetailerStockAdjustmentKind.damageOrExpiry
              ? RetailerStockMovementType.damage
              : RetailerStockMovementType.adjusted,
        ),
      );
      noticeMessage =
          '${kind.label} recorded once with owner approval and audit history.';
      completed = true;
    } on RetailerGatewayException catch (error) {
      errorMessage = error.message;
    } finally {
      busy = false;
      notifyListeners();
    }
    return completed;
  }

  Future<bool> exportStockStatement(String format) async {
    if (!businessBookAuthorized) {
      _showError('Owner or accountant permission is required for exports.');
      return false;
    }
    if (!businessBookOnline) {
      _showError('Reconnect before creating a stock statement export.');
      return false;
    }
    return _runBool(
      () => booksGateway.exportStock(format),
      success: '$format stock statement is ready.',
      afterSuccess: () => lastStockExport = format,
    );
  }

  void setBusinessPeriod(RetailerBusinessPeriod value) {
    businessPeriod = value;
    clearMessages();
    noticeMessage = '${value.label} Business Book selected.';
    notifyListeners();
  }

  Future<bool> refreshBusinessBook() async {
    if (!businessBookAuthorized) {
      _showError('Your current shop role cannot open financial records.');
      return false;
    }
    if (!businessBookOnline) {
      _showError(
        'The Business Book is offline. Existing approved records remain available.',
      );
      return false;
    }
    return _runBool(
      booksGateway.refreshBusinessBook,
      success: 'Business Book is current. No record was posted twice.',
    );
  }

  Future<bool> exportBusinessBook(String format) async {
    if (!businessBookAuthorized) {
      _showError('Owner or accountant permission is required for reports.');
      return false;
    }
    if (!businessBookOnline) {
      _showError('Reconnect before creating a business report.');
      return false;
    }
    return _runBool(
      () => booksGateway.exportBusinessBook(format),
      success: '$format Business Book report is ready.',
      afterSuccess: () => lastBusinessExport = format,
    );
  }

  void matchCustomerPayment() {
    if (matchedCustomerPaymentId != null) {
      noticeMessage =
          'Customer payment $matchedCustomerPaymentId is already matched.';
      notifyListeners();
      return;
    }
    matchedCustomerPaymentId = 'PH-1182';
    clearMessages();
    noticeMessage =
        '₹1,240 bank transfer PH-1182 matched to the customer due once.';
    notifyListeners();
  }

  Future<bool> saveBusinessExpense({
    required int amount,
    required String category,
    required String note,
    required String method,
    required bool evidenceAttached,
  }) async {
    if (expenseId != null) {
      noticeMessage =
          'Expense $expenseId is already saved. No duplicate expense was created.';
      notifyListeners();
      return true;
    }
    if (amount <= 0) {
      _showError('Enter an expense amount greater than zero.');
      return false;
    }
    if (category.trim().isEmpty || note.trim().length < 3) {
      _showError('Choose a category and enter a clear bill or note.');
      return false;
    }
    if (!evidenceAttached) {
      _showError('Attach the bill or payment evidence before saving.');
      return false;
    }
    if (!businessBookAuthorized) {
      _showError('Your current shop role cannot add business expenses.');
      return false;
    }
    if (!businessBookOnline) {
      _showError('Expenses are offline. No financial record was created.');
      return false;
    }
    if (busy) return false;
    clearMessages();
    busy = true;
    notifyListeners();
    var completed = false;
    try {
      final expense = RetailerExpense(
        id: 'EXP-10601',
        amount: amount,
        category: category.trim(),
        note: note.trim(),
        method: method,
        evidenceAttached: evidenceAttached,
      );
      expenseId = await booksGateway.saveExpense(expense);
      expenses.add(expense);
      noticeMessage =
          'Expense $expenseId saved once with source evidence and operator.';
      completed = true;
    } on RetailerGatewayException catch (error) {
      errorMessage = error.message;
    } finally {
      busy = false;
      notifyListeners();
    }
    return completed;
  }

  Future<bool> resolveMoneyException(String exceptionId) async {
    final exception = moneyExceptions.firstWhere(
      (item) => item.id == exceptionId,
    );
    selectedMoneyExceptionId = exceptionId;
    if (exception.resolved) {
      noticeMessage =
          'This money exception is already resolved. No duplicate record was created.';
      notifyListeners();
      return true;
    }
    if (!businessBookAuthorized) {
      _showError('Owner approval is required for money reconciliation.');
      return false;
    }
    if (!businessBookOnline) {
      _showError(
        'Money reconciliation is offline. The exception remains open.',
      );
      return false;
    }
    return _runBool(
      () => booksGateway.resolveMoney(exceptionId),
      success: '${exception.title} resolved with audit history.',
      afterSuccess: () => exception.resolved = true,
    );
  }

  void setBusinessServicesOnline(bool value) {
    businessServicesOnline = value;
    clearMessages();
    notifyListeners();
  }

  void selectBusinessService(RetailerBusinessServiceOffering service) {
    final changed = selectedBusinessService?.type != service.type;
    selectedBusinessService = service;
    final active = activeBusinessServices[service.type];
    if (active != null) {
      selectedBusinessPlan = active.plan;
      businessServiceMonthlyLimit = active.monthlyLimit;
      businessServicePayment = active.payment;
    } else if (changed || selectedBusinessPlan == null) {
      selectedBusinessPlan = service.plans.first;
      businessServiceMonthlyLimit = 3000;
      businessServicePayment = RetailerBusinessPayment.upi;
    }
    if (changed) {
      businessServiceCustomLimit = false;
      businessServiceCommercialConsent = false;
      businessServiceDataConsent = false;
      businessServiceTermsReviewed = false;
    }
    clearMessages();
    notifyListeners();
  }

  void selectBusinessServicePlan(RetailerBusinessPlan plan) {
    selectedBusinessPlan = plan;
    clearMessages();
    notifyListeners();
  }

  bool setBusinessServiceLimit(int value, {bool custom = false}) {
    if (value < 1000) {
      _showError('Set a monthly spending limit of at least ₹1,000.');
      return false;
    }
    if (value > 100000) {
      _showError('For your protection, choose a limit up to ₹1,00,000.');
      return false;
    }
    final monthly = selectedBusinessPlan?.monthly ?? 0;
    if (value < monthly) {
      _showError('The monthly limit must cover the selected plan price.');
      return false;
    }
    businessServiceMonthlyLimit = value;
    businessServiceCustomLimit = custom;
    clearMessages();
    notifyListeners();
    return true;
  }

  void selectBusinessServicePayment(RetailerBusinessPayment payment) {
    businessServicePayment = payment;
    clearMessages();
    notifyListeners();
  }

  void setBusinessServiceCommercialConsent(bool value) {
    businessServiceCommercialConsent = value;
    clearMessages();
    notifyListeners();
  }

  void setBusinessServiceDataConsent(bool value) {
    businessServiceDataConsent = value;
    clearMessages();
    notifyListeners();
  }

  void reviewBusinessServiceTerms() {
    businessServiceTermsReviewed = true;
    clearMessages();
    noticeMessage =
        'Service terms reviewed. Charges, limit and renewal remain visible.';
    notifyListeners();
  }

  Future<bool> refreshBusinessServices() async {
    if (!businessServicesAuthorized) {
      _showError(
        'Your current shop role cannot manage paid business services.',
      );
      return false;
    }
    if (!businessServicesOnline) {
      _showError(
        'Business Services is offline. No plan or entitlement was changed.',
      );
      return false;
    }
    return _runBool(
      businessServicesGateway.refreshCatalogue,
      success: 'Business Services plans and prices are current.',
      afterSuccess: () => businessServicesCatalogueAvailable = true,
    );
  }

  Future<bool> loadBusinessServicePlans(
    RetailerBusinessServiceOffering service,
  ) async {
    selectBusinessService(service);
    if (!businessServicesAuthorized) {
      _showError('Your current shop role cannot review paid service plans.');
      return false;
    }
    if (!businessServicesOnline) {
      _showError(
        'Service plans are offline. Your existing selection remains unchanged.',
      );
      return false;
    }
    return _runBool(
      () => businessServicesGateway.loadPlans(service.type),
      success: '${service.title} plans are ready to compare.',
    );
  }

  Future<bool> activateBusinessService() async {
    final service = selectedBusinessService;
    final plan = selectedBusinessPlan;
    if (service == null || plan == null) {
      _showError('Choose a service and plan before activation.');
      return false;
    }
    final existing = activeBusinessServices[service.type];
    if (existing != null) {
      noticeMessage =
          '${service.title} is already active as ${existing.id}. No duplicate payment or entitlement was created.';
      errorMessage = null;
      notifyListeners();
      return true;
    }
    if (!businessServiceCommercialConsent) {
      _showError('Approve the displayed commercial terms before activation.');
      return false;
    }
    if (service.requiresDataConsent && !businessServiceDataConsent) {
      _showError(
        'Approve purpose-limited business-record access before activating this service.',
      );
      return false;
    }
    if (!businessServicesAuthorized) {
      _showError('Shop owner approval is required to activate a paid service.');
      return false;
    }
    if (!businessServicesOnline) {
      _showError(
        'Activation is offline. No payment was collected and no service was started.',
      );
      return false;
    }
    if (busy) return false;
    clearMessages();
    busy = true;
    notifyListeners();
    var completed = false;
    try {
      final id = await businessServicesGateway.activate(
        service: service.type,
        planId: plan.id,
        monthlyLimit: businessServiceMonthlyLimit,
        payment: businessServicePayment,
        idempotencyKey:
            '${service.type.name}-${plan.id}-$businessServiceMonthlyLimit',
      );
      activeBusinessServices[service.type] = RetailerActiveBusinessService(
        id: id,
        offering: service,
        plan: plan,
        monthlyLimit: businessServiceMonthlyLimit,
        payment: businessServicePayment,
        readySetup: {
          for (final setup in service.quickSetup)
            if (setup.$3) setup.$1,
        },
      );
      noticeMessage =
          '${service.title} activated once. Plan, spend limit and payment proof are recorded.';
      completed = true;
    } on RetailerGatewayException catch (error) {
      errorMessage = error.message;
    } finally {
      busy = false;
      notifyListeners();
    }
    return completed;
  }

  Future<bool> completeBusinessServiceSetup(
    RetailerBusinessServiceType type,
    String setupId,
  ) async {
    final active = activeBusinessServices[type];
    if (active == null) {
      _showError('Activate this service before completing its setup.');
      return false;
    }
    if (active.readySetup.contains(setupId)) {
      noticeMessage = '$setupId is already ready. No duplicate was created.';
      errorMessage = null;
      notifyListeners();
      return true;
    }
    if (!businessServicesOnline) {
      _showError('Service setup is offline. Its current status is unchanged.');
      return false;
    }
    return _runBool(
      () => businessServicesGateway.saveSetup(type, setupId),
      success: '$setupId is ready to use.',
      afterSuccess: () => active.readySetup.add(setupId),
    );
  }

  Future<bool> openBusinessServiceSupport(
    RetailerBusinessServiceType type,
  ) async {
    if (!activeBusinessServices.containsKey(type)) {
      _showError('Activate this service before opening service support.');
      return false;
    }
    if (!businessServicesOnline) {
      _showError(
        'Service support is offline. Your active service remains unchanged.',
      );
      return false;
    }
    return _runBool(
      () => businessServicesGateway.openSupport(type),
      success: 'A service support case is ready in Chat.',
    );
  }

  Future<bool> cancelBusinessService(RetailerBusinessServiceType type) async {
    final active = activeBusinessServices[type];
    if (active == null) {
      noticeMessage = 'This service is already inactive.';
      errorMessage = null;
      notifyListeners();
      return true;
    }
    if (!businessServicesOnline) {
      _showError(
        'Cancellation is offline. The service remains active until a confirmed request is recorded.',
      );
      return false;
    }
    return _runBool(
      () => businessServicesGateway.cancel(type),
      success:
          '${active.offering.title} will not renew. Current paid access remains available until renewal.',
      afterSuccess: () => activeBusinessServices.remove(type),
    );
  }

  List<RetailerCustomer> get filteredCustomers {
    final query = customerSearchQuery.trim().toLowerCase();
    return reviewRetailerCustomers
        .where(
          (customer) =>
              customer.matches(customerFilter) &&
              (query.isEmpty ||
                  customer.name.toLowerCase().contains(query) ||
                  customer.summary.toLowerCase().contains(query) ||
                  customer.detail.toLowerCase().contains(query)),
        )
        .toList(growable: false);
  }

  RetailerCustomer get selectedCustomer => reviewRetailerCustomers.firstWhere(
    (customer) => customer.id == selectedCustomerId,
    orElse: () => reviewRetailerCustomers.first,
  );

  List<RetailerCampaign> get filteredCampaigns => campaigns
      .where(
        (campaign) => switch (campaignFilter) {
          RetailerCampaignFilter.all => true,
          RetailerCampaignFilter.active =>
            campaign.state == RetailerCampaignState.active ||
                campaign.state == RetailerCampaignState.paused,
          RetailerCampaignFilter.draft =>
            campaign.state == RetailerCampaignState.draft,
          RetailerCampaignFilter.completed =>
            campaign.state == RetailerCampaignState.completed,
          RetailerCampaignFilter.loyalty => campaign.loyalty,
        },
      )
      .toList(growable: false);

  List<RetailerCampaignProduct> get selectedCampaignProducts =>
      reviewCampaignProducts
          .where((product) => campaignProductIds.contains(product.id))
          .toList(growable: false);

  void setCustomerCampaignOnline(bool value) {
    customerCampaignOnline = value;
    clearMessages();
    notifyListeners();
  }

  void setCustomerSearch(String value) {
    customerSearchQuery = value;
    clearMessages();
    notifyListeners();
  }

  void setCustomerFilter(RetailerCustomerFilter value) {
    customerFilter = value;
    clearMessages();
    notifyListeners();
  }

  void selectCustomer(String id) {
    selectedCustomerId =
        reviewRetailerCustomers.any((customer) => customer.id == id)
        ? id
        : reviewRetailerCustomers.first.id;
    reminderMessageId = null;
    clearMessages();
    notifyListeners();
  }

  void setReminderChannel(RetailerMessageChannel value) {
    if (value == RetailerMessageChannel.sms) {
      _showError(
        'SMS is off for this customer. Choose a currently permitted channel.',
      );
      return;
    }
    reminderChannel = value;
    clearMessages();
    notifyListeners();
  }

  void setReminderMessage(String value) {
    reminderMessage = value;
    reminderMessageId = null;
    clearMessages();
    notifyListeners();
  }

  Future<bool> refreshCustomers() async {
    if (!customerCampaignAuthorized) {
      _showError('Your current shop role cannot access customer records.');
      return false;
    }
    if (!customerCampaignOnline) {
      _showError(
        'Customers are offline. Existing permissions and order records remain available.',
      );
      return false;
    }
    return _runBool(
      campaignGateway.refreshCustomers,
      success: 'Customer orders, dues, issues and permissions are current.',
    );
  }

  Future<bool> sendCustomerReminder() async {
    final customer = selectedCustomer;
    if (reminderMessageId != null) {
      noticeMessage =
          'Reminder $reminderMessageId was already sent once. No duplicate message or order was created.';
      errorMessage = null;
      notifyListeners();
      return true;
    }
    if (!customer.allowed) {
      _showError(
        'Promotional reminders are not allowed for this customer. Invoices remain available independently.',
      );
      return false;
    }
    if (customer.issue) {
      _showError(
        'Resolve the open customer issue before sending a promotional reminder.',
      );
      return false;
    }
    if (reminderChannel == RetailerMessageChannel.sms) {
      _showError('SMS is off. Choose Mool Chat or permitted WhatsApp.');
      return false;
    }
    if (reminderMessage.trim().length < 12) {
      _showError('Enter a clear customer reminder before sending.');
      return false;
    }
    if (!customerCampaignAuthorized) {
      _showError('Your current shop role cannot send customer reminders.');
      return false;
    }
    if (!customerCampaignOnline) {
      _showError('Messaging is offline. No reminder or order was created.');
      return false;
    }
    if (busy) return false;
    clearMessages();
    busy = true;
    notifyListeners();
    var completed = false;
    try {
      reminderMessageId = await campaignGateway.sendReminder(
        customerId: customer.id,
        channel: reminderChannel.name,
        message: reminderMessage.trim(),
        idempotencyKey:
            '${customer.id}-${reminderChannel.name}-${reminderMessage.trim().hashCode}',
      );
      noticeMessage =
          'Reminder $reminderMessageId sent once by ${reminderChannel.label}. Permission, purpose, operator and opt-out were recorded. No order was created.';
      completed = true;
    } on RetailerGatewayException catch (error) {
      errorMessage = error.message;
    } finally {
      busy = false;
      notifyListeners();
    }
    return completed;
  }

  void setCampaignFilter(RetailerCampaignFilter value) {
    campaignFilter = value;
    clearMessages();
    notifyListeners();
  }

  Future<bool> refreshCampaigns() async {
    if (!customerCampaignAuthorized) {
      _showError('Your current shop role cannot manage campaigns.');
      return false;
    }
    if (!customerCampaignOnline) {
      _showError(
        'Campaigns are offline. Existing budgets and campaign states remain unchanged.',
      );
      return false;
    }
    return _runBool(
      campaignGateway.refreshCampaigns,
      success: 'Paid sales, refunds, spend and campaign states are current.',
    );
  }

  void resetCampaignBuilder({String? cloneId}) {
    campaignBuilderStep = 0;
    campaignObjective = RetailerCampaignObjective.increaseSales;
    campaignName = cloneId == null
        ? 'Monthly staples offer'
        : 'Monthly staples offer copy';
    campaignProductIds
      ..clear()
      ..addAll({'atta', 'oil'});
    campaignBenefit = RetailerCampaignBenefit.basketSaving;
    campaignMaximumOrders = 30;
    campaignAudience = RetailerCampaignAudience.repeatCustomers;
    campaignRadiusKm = 5;
    campaignDurationDays = 7;
    campaignChannel = RetailerCampaignChannel.moolSocial;
    campaignSpendCap = 1500;
    campaignDraftId = null;
    publishedCampaignId = null;
    clearMessages();
    notifyListeners();
  }

  void setCampaignObjective(RetailerCampaignObjective value) {
    campaignObjective = value;
    clearMessages();
    notifyListeners();
  }

  void setCampaignName(String value) {
    campaignName = value;
    campaignDraftId = null;
    publishedCampaignId = null;
    clearMessages();
    notifyListeners();
  }

  void toggleCampaignProduct(String productId) {
    if (campaignProductIds.contains(productId)) {
      if (campaignProductIds.length == 1) {
        _showError('Keep at least one stock-backed product in the campaign.');
        return;
      }
      campaignProductIds.remove(productId);
    } else {
      campaignProductIds.add(productId);
    }
    campaignDraftId = null;
    publishedCampaignId = null;
    clearMessages();
    notifyListeners();
  }

  void setCampaignBenefit(RetailerCampaignBenefit value) {
    campaignBenefit = value;
    clearMessages();
    notifyListeners();
  }

  bool setCampaignMaximumOrders(int value) {
    if (value < 1) {
      _showError('Maximum orders must be at least 1.');
      return false;
    }
    final available = selectedCampaignProducts
        .map((product) => product.available)
        .reduce((a, b) => a < b ? a : b);
    if (value > available) {
      _showError(
        'Maximum orders cannot exceed the lowest selected sellable stock of $available.',
      );
      return false;
    }
    campaignMaximumOrders = value;
    clearMessages();
    notifyListeners();
    return true;
  }

  void setCampaignAudience(RetailerCampaignAudience value) {
    campaignAudience = value;
    clearMessages();
    notifyListeners();
  }

  void setCampaignRadius(int value) {
    campaignRadiusKm = value;
    clearMessages();
    notifyListeners();
  }

  void setCampaignDuration(int value) {
    campaignDurationDays = value;
    clearMessages();
    notifyListeners();
  }

  void setCampaignChannel(RetailerCampaignChannel value) {
    campaignChannel = value;
    clearMessages();
    notifyListeners();
  }

  bool setCampaignSpendCap(int value) {
    if (value < 100) {
      _showError('Set a maximum campaign spend of at least ₹100.');
      return false;
    }
    if (value > 100000) {
      _showError('Choose a campaign spend cap up to ₹1,00,000.');
      return false;
    }
    campaignSpendCap = value;
    clearMessages();
    notifyListeners();
    return true;
  }

  bool goToCampaignStep(int value) {
    if (value > campaignBuilderStep &&
        !_campaignStepValid(campaignBuilderStep)) {
      return false;
    }
    campaignBuilderStep = value.clamp(0, 3);
    clearMessages();
    notifyListeners();
    return true;
  }

  bool continueCampaignBuilder() {
    if (!_campaignStepValid(campaignBuilderStep)) return false;
    if (campaignBuilderStep < 3) {
      campaignBuilderStep += 1;
      clearMessages();
      notifyListeners();
    }
    return true;
  }

  bool _campaignStepValid(int step) {
    if (step == 0 && campaignName.trim().length < 4) {
      _showError('Enter a clear campaign name before continuing.');
      return false;
    }
    if (step == 1 && campaignProductIds.isEmpty) {
      _showError('Choose at least one stock-backed product.');
      return false;
    }
    return true;
  }

  Future<bool> saveCampaignDraft() async {
    if (campaignDraftId != null) {
      noticeMessage =
          'Draft $campaignDraftId is already saved. No duplicate campaign was created.';
      errorMessage = null;
      notifyListeners();
      return true;
    }
    if (campaignName.trim().length < 4) {
      _showError('Enter a clear campaign name before saving.');
      return false;
    }
    if (!customerCampaignOnline) {
      _showError('Campaigns are offline. No draft was created.');
      return false;
    }
    if (!customerCampaignAuthorized) {
      _showError('Your current shop role cannot save campaigns.');
      return false;
    }
    if (busy) return false;
    clearMessages();
    busy = true;
    notifyListeners();
    var completed = false;
    try {
      campaignDraftId = await campaignGateway.saveDraft(
        name: campaignName.trim(),
        idempotencyKey:
            '${campaignName.trim()}-${campaignProductIds.join('-')}',
      );
      noticeMessage = 'Draft $campaignDraftId saved once.';
      completed = true;
    } on RetailerGatewayException catch (error) {
      errorMessage = error.message;
    } finally {
      busy = false;
      notifyListeners();
    }
    return completed;
  }

  Future<bool> publishCampaign() async {
    if (publishedCampaignId != null) {
      noticeMessage =
          'Campaign $publishedCampaignId is already published. No stock, budget or campaign was duplicated.';
      errorMessage = null;
      notifyListeners();
      return true;
    }
    if (!_campaignStepValid(0) || !_campaignStepValid(1)) return false;
    final available = selectedCampaignProducts
        .map((product) => product.available)
        .reduce((a, b) => a < b ? a : b);
    if (campaignMaximumOrders > available) {
      _showError(
        'Reduce maximum orders to $available or less before publishing.',
      );
      return false;
    }
    if (!customerCampaignAuthorized) {
      _showError('Shop owner approval is required to publish a campaign.');
      return false;
    }
    if (!customerCampaignOnline) {
      _showError('Publishing is offline. No stock or budget was committed.');
      return false;
    }
    if (busy) return false;
    clearMessages();
    busy = true;
    notifyListeners();
    var completed = false;
    try {
      publishedCampaignId = await campaignGateway.publish(
        name: campaignName.trim(),
        maximumOrders: campaignMaximumOrders,
        spendCap: campaignSpendCap,
        idempotencyKey:
            '${campaignName.trim()}-$campaignMaximumOrders-$campaignSpendCap',
      );
      campaigns.insert(
        0,
        RetailerCampaign(
          id: publishedCampaignId!,
          title: campaignName.trim(),
          detail:
              '${campaignAudience.label} · ${campaignChannel.label} · $campaignDurationDays days',
          state: RetailerCampaignState.active,
          paidSales: 0,
          spend: 0,
          result: '₹$campaignSpendCap maximum spend',
        ),
      );
      noticeMessage =
          'Campaign $publishedCampaignId published once. Stock is committed only on accepted orders and spend cannot exceed ₹$campaignSpendCap.';
      completed = true;
    } on RetailerGatewayException catch (error) {
      errorMessage = error.message;
    } finally {
      busy = false;
      notifyListeners();
    }
    return completed;
  }

  Future<bool> pauseCampaign(String id) async {
    final campaign = campaigns.firstWhere((item) => item.id == id);
    if (campaign.state == RetailerCampaignState.paused) {
      noticeMessage = '${campaign.title} is already paused.';
      errorMessage = null;
      notifyListeners();
      return true;
    }
    if (campaign.state != RetailerCampaignState.active) {
      _showError('Only an active campaign can be paused.');
      return false;
    }
    if (!customerCampaignOnline) {
      _showError('Campaigns are offline. The campaign remains active.');
      return false;
    }
    return _runBool(
      () => campaignGateway.pause(id),
      success:
          '${campaign.title} paused. No new eligible campaign spend will be accepted.',
      afterSuccess: () => campaign.state = RetailerCampaignState.paused,
    );
  }

  Future<bool> deleteCampaignDraft(String id) async {
    final campaign = campaigns.firstWhere((item) => item.id == id);
    if (campaign.state != RetailerCampaignState.draft) {
      _showError('Only a draft campaign can be deleted.');
      return false;
    }
    if (!customerCampaignOnline) {
      _showError('Campaigns are offline. The draft remains available.');
      return false;
    }
    return _runBool(
      () => campaignGateway.deleteDraft(id),
      success: '${campaign.title} draft deleted.',
      afterSuccess: () => campaigns.remove(campaign),
    );
  }

  Future<void> _run(
    Future<void> Function() action, {
    required String success,
    VoidCallback? afterSuccess,
    VoidCallback? afterFailure,
  }) async {
    if (busy) return;
    clearMessages();
    busy = true;
    notifyListeners();
    try {
      await action();
      afterSuccess?.call();
      noticeMessage = success;
    } on RetailerGatewayException catch (error) {
      afterFailure?.call();
      errorMessage = error.message;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> _runBool(
    Future<void> Function() action, {
    required String success,
    VoidCallback? afterSuccess,
    VoidCallback? afterFailure,
  }) async {
    if (busy) return false;
    clearMessages();
    busy = true;
    notifyListeners();
    var completed = false;
    try {
      await action();
      afterSuccess?.call();
      noticeMessage = success;
      completed = true;
    } on RetailerGatewayException catch (error) {
      afterFailure?.call();
      errorMessage = error.message;
    } finally {
      busy = false;
      notifyListeners();
    }
    return completed;
  }

  void _showError(String message) {
    noticeMessage = null;
    errorMessage = message;
    notifyListeners();
  }
}
