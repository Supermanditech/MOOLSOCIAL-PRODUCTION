import 'package:flutter/foundation.dart';

import 'retailer_models.dart';
import 'retailer_services.dart';

class RetailerSession extends ChangeNotifier {
  RetailerSession({ReviewRetailerGateway? gateway})
    : gateway = gateway ?? ReviewRetailerGateway(),
      orders = buildReviewRetailerOrders();

  final ReviewRetailerGateway gateway;
  final List<RetailerOrder> orders;

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
