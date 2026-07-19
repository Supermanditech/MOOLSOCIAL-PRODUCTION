class RetailerGatewayException implements Exception {
  const RetailerGatewayException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ReviewRetailerGateway {
  bool failRefresh = false;
  bool failAvailability = false;
  bool failAccept = false;
  bool failPacking = false;
  bool failDeliveryRequest = false;
  bool failHandover = false;
  bool failTracking = false;
  bool failIssue = false;
  bool failCannotFulfil = false;

  int availabilityCalls = 0;
  int acceptCalls = 0;
  int packingCalls = 0;
  int deliveryRequestCalls = 0;
  int handoverCalls = 0;
  int trackingCalls = 0;
  int issueCalls = 0;
  int cannotFulfilCalls = 0;

  Future<void> _wait() =>
      Future<void>.delayed(const Duration(milliseconds: 24));

  Future<void> refreshOrders() async {
    await _wait();
    if (failRefresh) {
      failRefresh = false;
      throw const RetailerGatewayException(
        'Orders could not be refreshed. Current orders remain available.',
      );
    }
  }

  Future<void> setAvailability(bool enabled) async {
    availabilityCalls += 1;
    await _wait();
    if (failAvailability) {
      failAvailability = false;
      throw const RetailerGatewayException(
        'Order availability was not changed. Your previous setting remains active.',
      );
    }
  }

  Future<void> acceptOrder(String orderId) async {
    acceptCalls += 1;
    await _wait();
    if (failAccept) {
      failAccept = false;
      throw const RetailerGatewayException(
        'Order was not accepted. Payment and the customer promise are unchanged.',
      );
    }
  }

  Future<void> savePackedOrder(String orderId) async {
    packingCalls += 1;
    await _wait();
    if (failPacking) {
      failPacking = false;
      throw const RetailerGatewayException(
        'Packed status was not saved. Your checked items remain selected.',
      );
    }
  }

  Future<String> requestDelivery(String orderId) async {
    deliveryRequestCalls += 1;
    await _wait();
    if (failDeliveryRequest) {
      failDeliveryRequest = false;
      throw const RetailerGatewayException(
        'Delivery was not assigned. The packed order remains at your shop.',
      );
    }
    return 'DEL-$orderId-${420 + deliveryRequestCalls}';
  }

  Future<String> confirmHandover(String orderId) async {
    handoverCalls += 1;
    await _wait();
    if (failHandover) {
      failHandover = false;
      throw const RetailerGatewayException(
        'Handover was not recorded. Keep the parcel until confirmation succeeds.',
      );
    }
    return 'HAND-$orderId-${810 + handoverCalls}';
  }

  Future<void> refreshTracking(String orderId) async {
    trackingCalls += 1;
    await _wait();
    if (failTracking) {
      failTracking = false;
      throw const RetailerGatewayException(
        'Live delivery update is unavailable. No delivery state was changed.',
      );
    }
  }

  Future<String> createIssue(String orderId, String reason) async {
    issueCalls += 1;
    await _wait();
    if (failIssue) {
      failIssue = false;
      throw const RetailerGatewayException(
        'Delivery issue was not sent. Your order and selected reason remain saved.',
      );
    }
    return 'DI-$orderId-${900 + issueCalls}';
  }

  Future<void> cannotFulfil(String orderId, String reason) async {
    cannotFulfilCalls += 1;
    await _wait();
    if (failCannotFulfil) {
      failCannotFulfil = false;
      throw const RetailerGatewayException(
        'The order was not declined. It remains open for your decision.',
      );
    }
  }
}
