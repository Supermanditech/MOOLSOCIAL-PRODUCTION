import 'package:flutter/foundation.dart';

import 'manufacturer_models.dart';
import 'manufacturer_services.dart';

class ManufacturerSession extends ChangeNotifier {
  ManufacturerSession({ReviewManufacturerGateway? gateway})
    : gateway = gateway ?? ReviewManufacturerGateway();

  final ReviewManufacturerGateway gateway;

  bool online = true;
  bool authorized = true;
  bool busy = false;
  String? errorMessage;
  String? noticeMessage;

  ManufacturerHomeView homeView = ManufacturerHomeView.home;
  bool supplyOn = true;
  String searchQuery = '';
  String orderFilter = 'Need action';

  ManufacturerCatalogueMode catalogueMode = ManufacturerCatalogueMode.stock;
  String catalogueFilter = 'All';
  String selectedProductId = 'sunflower-oil';
  int productQuantity = 1860;
  int productPrice = 142;
  int productMoq = 40;
  String productTerms = '30% advance · 7 day balance';
  bool inputMappingConfirmed = false;
  String? productPublishedId;

  String selectedOrderId = 'SO-4821';
  ManufacturerOrderDecision orderDecision = ManufacturerOrderDecision.full;
  int confirmedCases = 240;
  String productionDate = '22 Jul 2026';
  String orderNote = '';
  ManufacturerTransport orderTransport = ManufacturerTransport.ownFleet;
  ManufacturerOrderStage orderStage = ManufacturerOrderStage.review;
  String? orderConfirmationId;
  bool gstInvoiceReady = true;
  bool lrReady = false;
  bool eWayBillReady = true;

  ManufacturerPurchaseTab purchaseTab = ManufacturerPurchaseTab.matched;
  String inputFilter = 'Matched inputs';
  final Map<String, int> purchaseCart = {};
  String? purchaseOrderId;
  String? purchaseReceiptId;

  ManufacturerDispatchTab dispatchTab = ManufacturerDispatchTab.ready;
  ManufacturerTransport dispatchTransport = ManufacturerTransport.ownFleet;
  String vehicleNumber = 'RJ19 GC 4821';
  String driverMobile = '98765 44021';
  String? dispatchId;
  String? deliveryReceiptId;

  String bookPeriod = 'This month';
  bool showBookPosition = false;
  String selectedBookId = 'sales';

  ManufacturerGrowthTab growthTab = ManufacturerGrowthTab.buyers;
  String selectedGrowthId = 'buyer-raj';
  String campaignName = 'Retailer activation · Jaipur';
  int campaignTarget = 100;
  int campaignBudget = 42000;
  bool campaignReviewed = false;
  String? campaignId;

  ManufacturerControlTab controlTab = ManufacturerControlTab.claims;
  String selectedClaimId = 'CLM-BUY-4771';
  String claimOutcome = 'Approve matched quantity';
  String claimMessage =
      'We reviewed the evidence and approved the matched quantity outcome.';
  bool claimEvidenceAttached = true;
  String? claimResolutionId;
  bool teamInviteOpen = false;
  String teamInviteName = 'Ajay Solanki';
  String teamInviteMobile = '98765 88221';
  String teamInviteRole = 'Production';
  String? teamInviteId;
  String? settingsVersion;

  ManufacturerServiceTab serviceTab = ManufacturerServiceTab.services;
  String selectedServiceId = 'sales';
  bool serviceTermsAccepted = false;
  String? serviceRequestId;

  ManufacturerProduct get selectedProduct => reviewManufacturerProducts
      .firstWhere((item) => item.id == selectedProductId);

  ManufacturerSalesOrder get selectedOrder =>
      reviewManufacturerOrders.firstWhere((item) => item.id == selectedOrderId);

  ManufacturerClaim get selectedClaim =>
      reviewManufacturerClaims.firstWhere((item) => item.id == selectedClaimId);

  ManufacturerService get selectedService => reviewManufacturerServices
      .firstWhere((item) => item.id == selectedServiceId);

  List<ManufacturerSalesOrder> get filteredOrders {
    final query = searchQuery.trim().toLowerCase();
    return reviewManufacturerOrders
        .where(
          (item) =>
              query.isEmpty ||
              '${item.id} ${item.buyer} ${item.buyerType} ${item.product}'
                  .toLowerCase()
                  .contains(query),
        )
        .toList(growable: false);
  }

  List<ManufacturerProduct> get filteredProducts {
    final query = searchQuery.trim().toLowerCase();
    return reviewManufacturerProducts
        .where(
          (item) =>
              item.live == (catalogueMode == ManufacturerCatalogueMode.stock) &&
              (query.isEmpty ||
                  '${item.name} ${item.pack} ${item.hsn}'
                      .toLowerCase()
                      .contains(query)),
        )
        .toList(growable: false);
  }

  int get purchaseCartCount =>
      purchaseCart.values.fold(0, (total, value) => total + value);

  void clearMessages() {
    errorMessage = null;
    noticeMessage = null;
  }

  void showNotice(String message) {
    errorMessage = null;
    noticeMessage = message;
    notifyListeners();
  }

  void setOnline(bool value) {
    online = value;
    clearMessages();
    notifyListeners();
  }

  void setHomeView(ManufacturerHomeView value) {
    homeView = value;
    clearMessages();
    notifyListeners();
  }

  void setSearch(String value) {
    searchQuery = value;
    clearMessages();
    notifyListeners();
  }

  void clearSearch() => setSearch('');

  void setOrderFilter(String value) {
    orderFilter = value;
    clearMessages();
    notifyListeners();
  }

  Future<bool> toggleSupply() async {
    final target = !supplyOn;
    return _protected(
      operation: () => gateway.setSupply(target),
      success: () {
        supplyOn = target;
        noticeMessage = target
            ? 'Supply is live for confirmed stock.'
            : 'Supply is paused. Your existing confirmed orders remain visible.';
      },
    );
  }

  void setCatalogueMode(ManufacturerCatalogueMode value) {
    catalogueMode = value;
    searchQuery = '';
    catalogueFilter = 'All';
    clearMessages();
    notifyListeners();
  }

  void setCatalogueFilter(String value) {
    catalogueFilter = value;
    clearMessages();
    notifyListeners();
  }

  void selectProduct(String id) {
    final product = reviewManufacturerProducts.firstWhere(
      (item) => item.id == id,
    );
    selectedProductId = id;
    productQuantity = product.available;
    productPrice = product.price;
    productMoq = product.moq;
    productTerms = product.terms;
    productPublishedId = null;
    clearMessages();
    notifyListeners();
  }

  bool setProductQuantity(int value) {
    if (value < 0) {
      return _validation('Available quantity cannot be negative.');
    }
    productQuantity = value;
    productPublishedId = null;
    clearMessages();
    notifyListeners();
    return true;
  }

  bool setProductPrice(int value) {
    if (value <= 0) return _validation('Enter a buyer price above zero.');
    productPrice = value;
    productPublishedId = null;
    clearMessages();
    notifyListeners();
    return true;
  }

  bool setProductMoq(int value) {
    if (value < 1 || value > productQuantity) {
      return _validation('MOQ must be within the confirmed available stock.');
    }
    productMoq = value;
    productPublishedId = null;
    clearMessages();
    notifyListeners();
    return true;
  }

  void setProductTerms(String value) {
    productTerms = value;
    productPublishedId = null;
    clearMessages();
    notifyListeners();
  }

  void confirmInputMapping(bool value) {
    inputMappingConfirmed = value;
    clearMessages();
    notifyListeners();
  }

  Future<bool> publishProduct() async {
    if (productPublishedId != null) {
      noticeMessage =
          'Product $productPublishedId is already published. Stock was not duplicated.';
      notifyListeners();
      return true;
    }
    if (productQuantity < 1 ||
        productPrice < 1 ||
        productMoq < 1 ||
        productMoq > productQuantity) {
      return _validation(
        'Confirm available quantity, buyer price and an MOQ within stock.',
      );
    }
    if (!inputMappingConfirmed) {
      return _validation(
        'Review and confirm the proposed manufacturing-input mapping.',
      );
    }
    return _protected(
      operation: gateway.publishProduct,
      success: () {
        productPublishedId = 'SKU-109-0719';
        noticeMessage =
            'SKU-109-0719 is buyer visible with confirmed stock, MOQ and terms.';
      },
    );
  }

  void selectOrder(String id) {
    selectedOrderId = id;
    confirmedCases = selectedOrder.cases;
    orderDecision = ManufacturerOrderDecision.full;
    orderStage = ManufacturerOrderStage.review;
    orderConfirmationId = null;
    clearMessages();
    notifyListeners();
  }

  void setOrderDecision(ManufacturerOrderDecision value) {
    orderDecision = value;
    if (value == ManufacturerOrderDecision.full) {
      confirmedCases = selectedOrder.cases;
    }
    orderConfirmationId = null;
    clearMessages();
    notifyListeners();
  }

  bool setConfirmedCases(int value) {
    if (value < 1 || value > selectedOrder.cases) {
      return _validation(
        'Confirmed cases must be between 1 and ${selectedOrder.cases}.',
      );
    }
    confirmedCases = value;
    orderConfirmationId = null;
    clearMessages();
    notifyListeners();
    return true;
  }

  void setProductionDate(String value) {
    productionDate = value;
    orderConfirmationId = null;
    clearMessages();
    notifyListeners();
  }

  void setOrderNote(String value) {
    orderNote = value;
    orderConfirmationId = null;
    clearMessages();
    notifyListeners();
  }

  Future<bool> confirmOrder() async {
    if (orderConfirmationId != null) {
      noticeMessage =
          'Order $orderConfirmationId is already confirmed. Quantity and advance were not duplicated.';
      notifyListeners();
      return true;
    }
    if (productionDate.trim().isEmpty) {
      return _validation('Choose a production or dispatch date.');
    }
    if (orderDecision == ManufacturerOrderDecision.partial &&
        (confirmedCases >= selectedOrder.cases || confirmedCases < 1)) {
      return _validation(
        'A partial offer must be below ${selectedOrder.cases} and above zero.',
      );
    }
    if (orderDecision == ManufacturerOrderDecision.cannotFulfil &&
        orderNote.trim().length < 10) {
      return _validation(
        'Explain why this order cannot be fulfilled before returning demand.',
      );
    }
    return _protected(
      operation: gateway.confirmOrder,
      success: () {
        orderConfirmationId = 'CONF-110-4821';
        orderStage = orderDecision == ManufacturerOrderDecision.cannotFulfil
            ? ManufacturerOrderStage.review
            : ManufacturerOrderStage.production;
        noticeMessage = orderDecision == ManufacturerOrderDecision.cannotFulfil
            ? 'Demand returned with an auditable reason; no quantity was silently reduced.'
            : '$confirmedCases cases confirmed for $productionDate. Protected advance remains held.';
      },
    );
  }

  void advanceOrder(ManufacturerOrderStage value) {
    if (orderConfirmationId == null) {
      _validation('Confirm the order quantity and terms first.');
      return;
    }
    orderStage = value;
    noticeMessage = switch (value) {
      ManufacturerOrderStage.packed =>
        'Packing is complete. Dispatch documents remain required.',
      ManufacturerOrderStage.dispatched =>
        'Shipment is in transit with confirmed dispatch documents.',
      ManufacturerOrderStage.delivered =>
        'Buyer delivery proof is available; payment release remains ledger controlled.',
      ManufacturerOrderStage.receivable =>
        'Receivable opened from the delivered GST invoice.',
      _ => 'Order production status updated.',
    };
    errorMessage = null;
    notifyListeners();
  }

  void setPurchaseTab(ManufacturerPurchaseTab value) {
    purchaseTab = value;
    clearMessages();
    notifyListeners();
  }

  void setInputFilter(String value) {
    inputFilter = value;
    clearMessages();
    notifyListeners();
  }

  void addInput(String id) {
    final offer = reviewManufacturerInputs.firstWhere((item) => item.id == id);
    purchaseCart[id] = (purchaseCart[id] ?? 0) + offer.moq;
    purchaseOrderId = null;
    noticeMessage =
        '${offer.name} MOQ added. Terms will be rechecked before PO.';
    errorMessage = null;
    notifyListeners();
  }

  void removeInput(String id) {
    purchaseCart.remove(id);
    purchaseOrderId = null;
    clearMessages();
    notifyListeners();
  }

  Future<bool> placePurchaseOrder() async {
    if (purchaseOrderId != null) {
      noticeMessage =
          'Purchase order $purchaseOrderId already exists. No second advance was created.';
      notifyListeners();
      return true;
    }
    if (purchaseCart.isEmpty) {
      return _validation('Add at least one verified input MOQ before the PO.');
    }
    return _protected(
      operation: gateway.placePurchase,
      success: () {
        purchaseOrderId = 'PO-IN-111-0719';
        purchaseTab = ManufacturerPurchaseTab.orders;
        noticeMessage =
            'PO-IN-111-0719 placed once. Advance remains protected until receipt conditions.';
      },
    );
  }

  void receivePurchase() {
    if (purchaseOrderId == null) {
      _validation('Place the purchase order before recording receipt.');
      return;
    }
    if (purchaseReceiptId != null) {
      noticeMessage = 'Receipt $purchaseReceiptId is already recorded.';
    } else {
      purchaseReceiptId = 'GRN-111-0719';
      noticeMessage =
          'GRN-111-0719 recorded with grade, quantity and condition evidence.';
    }
    errorMessage = null;
    notifyListeners();
  }

  void setDispatchTab(ManufacturerDispatchTab value) {
    dispatchTab = value;
    clearMessages();
    notifyListeners();
  }

  void setDispatchTransport(ManufacturerTransport value) {
    dispatchTransport = value;
    dispatchId = null;
    clearMessages();
    notifyListeners();
  }

  void setVehicleNumber(String value) {
    vehicleNumber = value;
    dispatchId = null;
    clearMessages();
    notifyListeners();
  }

  void setDriverMobile(String value) {
    driverMobile = value;
    dispatchId = null;
    clearMessages();
    notifyListeners();
  }

  void toggleDispatchDocument(String id) {
    switch (id) {
      case 'invoice':
        gstInvoiceReady = !gstInvoiceReady;
      case 'lr':
        lrReady = !lrReady;
      case 'eway':
        eWayBillReady = !eWayBillReady;
    }
    dispatchId = null;
    clearMessages();
    notifyListeners();
  }

  Future<bool> confirmDispatch() async {
    if (dispatchId != null) {
      noticeMessage =
          'Dispatch $dispatchId is already active. Documents and payment state were not duplicated.';
      notifyListeners();
      return true;
    }
    if (!gstInvoiceReady || !lrReady || !eWayBillReady) {
      return _validation('GST invoice, LR and e-way bill must all be ready.');
    }
    if (dispatchTransport == ManufacturerTransport.ownFleet &&
        (vehicleNumber.trim().length < 6 ||
            driverMobile.replaceAll(RegExp(r'\D'), '').length != 10)) {
      return _validation(
        'Enter a valid vehicle and 10-digit driver mobile for own fleet.',
      );
    }
    return _protected(
      operation: gateway.dispatchOrder,
      success: () {
        dispatchId = 'DSP-112-4821';
        dispatchTab = ManufacturerDispatchTab.transit;
        orderStage = ManufacturerOrderStage.dispatched;
        noticeMessage =
            'DSP-112-4821 is in transit with invoice, LR and e-way bill.';
      },
    );
  }

  void confirmDeliveryReceipt() {
    if (dispatchId == null) {
      _validation('Confirm dispatch before recording buyer receipt.');
      return;
    }
    deliveryReceiptId ??= 'POD-112-4821';
    dispatchTab = ManufacturerDispatchTab.delivered;
    orderStage = ManufacturerOrderStage.delivered;
    errorMessage = null;
    noticeMessage =
        'POD-112-4821 matched quantity and condition. Ledger release remains server controlled.';
    notifyListeners();
  }

  void setBookPeriod(String value) {
    bookPeriod = value;
    clearMessages();
    notifyListeners();
  }

  void toggleBookPosition() {
    showBookPosition = !showBookPosition;
    clearMessages();
    notifyListeners();
  }

  void selectBook(String id) {
    selectedBookId = id;
    noticeMessage =
        'Opened ${reviewManufacturerBookRows.firstWhere((item) => item.id == id).label} from confirmed transactions.';
    errorMessage = null;
    notifyListeners();
  }

  void setGrowthTab(ManufacturerGrowthTab value) {
    growthTab = value;
    clearMessages();
    notifyListeners();
  }

  bool setCampaignTarget(int value) {
    if (value < 1 || value > 10000) {
      return _validation('Choose a target between 1 and 10,000 buyers.');
    }
    campaignTarget = value;
    campaignReviewed = false;
    campaignId = null;
    clearMessages();
    notifyListeners();
    return true;
  }

  bool setCampaignBudget(int value) {
    if (value < 1000 || value > 1000000) {
      return _validation('Campaign funding must be ₹1,000 to ₹10,00,000.');
    }
    campaignBudget = value;
    campaignReviewed = false;
    campaignId = null;
    clearMessages();
    notifyListeners();
    return true;
  }

  Future<bool> reviewOrPublishCampaign() async {
    if (!campaignReviewed) {
      campaignReviewed = true;
      noticeMessage =
          'Review ready: $campaignTarget verified retailers, ₹$campaignBudget maximum funding.';
      notifyListeners();
      return true;
    }
    if (campaignId != null) {
      noticeMessage =
          'Campaign $campaignId is already active. Funding was not duplicated.';
      notifyListeners();
      return true;
    }
    return _protected(
      operation: gateway.publishCampaign,
      success: () {
        campaignId = 'MFG-CMP-113-0719';
        noticeMessage =
            'MFG-CMP-113-0719 is active with verified-outcome attribution.';
      },
    );
  }

  void setControlTab(ManufacturerControlTab value) {
    controlTab = value;
    clearMessages();
    notifyListeners();
  }

  void selectClaim(String id) {
    selectedClaimId = id;
    claimResolutionId = null;
    clearMessages();
    notifyListeners();
  }

  void setClaimOutcome(String value) {
    claimOutcome = value;
    claimResolutionId = null;
    clearMessages();
    notifyListeners();
  }

  void setClaimMessage(String value) {
    claimMessage = value;
    claimResolutionId = null;
    clearMessages();
    notifyListeners();
  }

  void setClaimEvidence(bool value) {
    claimEvidenceAttached = value;
    claimResolutionId = null;
    clearMessages();
    notifyListeners();
  }

  Future<bool> resolveClaim() async {
    if (claimResolutionId != null) {
      noticeMessage =
          'Resolution $claimResolutionId already exists. Money was not released twice.';
      notifyListeners();
      return true;
    }
    if (claimMessage.trim().length < 12 || !claimEvidenceAttached) {
      return _validation(
        'Add evidence and a clear 12-character response before resolving.',
      );
    }
    return _protected(
      operation: gateway.resolveClaim,
      success: () {
        claimResolutionId = 'MFG-RES-114-0719';
        noticeMessage =
            'MFG-RES-114-0719 recorded. Payment release remains ledger controlled.';
      },
    );
  }

  void openTeamInvite() {
    teamInviteOpen = true;
    clearMessages();
    notifyListeners();
  }

  void closeTeamInvite() {
    teamInviteOpen = false;
    clearMessages();
    notifyListeners();
  }

  void setTeamInviteName(String value) {
    teamInviteName = value;
    teamInviteId = null;
    clearMessages();
    notifyListeners();
  }

  void setTeamInviteMobile(String value) {
    teamInviteMobile = value;
    teamInviteId = null;
    clearMessages();
    notifyListeners();
  }

  void setTeamInviteRole(String value) {
    teamInviteRole = value;
    teamInviteId = null;
    clearMessages();
    notifyListeners();
  }

  Future<bool> sendTeamInvite() async {
    if (teamInviteId != null) {
      noticeMessage =
          'Invite $teamInviteId is already sent. No access was duplicated.';
      notifyListeners();
      return true;
    }
    if (teamInviteName.trim().length < 3 ||
        teamInviteMobile.replaceAll(RegExp(r'\D'), '').length != 10) {
      return _validation('Enter a name and valid 10-digit mobile.');
    }
    return _protected(
      operation: gateway.inviteTeam,
      success: () {
        teamInviteId = 'MFG-INV-114-0719';
        noticeMessage =
            'Invite sent for $teamInviteRole. Access starts only after acceptance.';
      },
    );
  }

  Future<bool> saveWorkspaceSettings() async {
    if (settingsVersion != null) {
      noticeMessage =
          'Settings $settingsVersion are already saved. No second version was created.';
      notifyListeners();
      return true;
    }
    return _protected(
      operation: gateway.saveSettings,
      success: () {
        settingsVersion = 'MFG-SET-114-0719';
        noticeMessage =
            'MFG-SET-114-0719 saved. Your verified business type is unchanged.';
      },
    );
  }

  void setServiceTab(ManufacturerServiceTab value) {
    serviceTab = value;
    clearMessages();
    notifyListeners();
  }

  void selectService(String id) {
    selectedServiceId = id;
    serviceTermsAccepted = false;
    serviceRequestId = null;
    clearMessages();
    notifyListeners();
  }

  void acceptServiceTerms(bool value) {
    serviceTermsAccepted = value;
    serviceRequestId = null;
    clearMessages();
    notifyListeners();
  }

  Future<bool> requestService() async {
    if (serviceRequestId != null) {
      noticeMessage =
          'Request $serviceRequestId already exists. No second charge was created.';
      notifyListeners();
      return true;
    }
    if (!serviceTermsAccepted) {
      return _validation(
        'Accept the reviewed scope, charge, evidence and cancellation terms.',
      );
    }
    return _protected(
      operation: gateway.requestService,
      success: () {
        serviceRequestId = 'MFG-SVC-115-0719';
        serviceTab = ManufacturerServiceTab.requests;
        noticeMessage =
            'MFG-SVC-115-0719 submitted for approval. No service charge was taken yet.';
      },
    );
  }

  bool _validation(String message) {
    errorMessage = message;
    noticeMessage = null;
    notifyListeners();
    return false;
  }

  Future<bool> _protected({
    required Future<void> Function() operation,
    required void Function() success,
  }) async {
    if (busy) return false;
    if (!online) return _validation('You are offline. Reconnect and retry.');
    if (!authorized) {
      return _validation(
        'Your current access does not allow this action. Ask the owner to update your permission.',
      );
    }
    busy = true;
    clearMessages();
    notifyListeners();
    try {
      await operation();
      success();
      return true;
    } on ManufacturerGatewayException catch (error) {
      errorMessage = '${error.message} Retry the same action.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
