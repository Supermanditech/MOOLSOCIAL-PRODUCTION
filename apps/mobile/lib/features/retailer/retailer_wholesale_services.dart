import 'retailer_services.dart';
import 'retailer_wholesale_models.dart';

class ReviewRetailerWholesaleGateway {
  bool failPlaceOrders = false;
  bool failRefreshDelivery = false;
  bool failPostReceipt = false;
  bool failRefreshPurchases = false;
  bool failExportPurchases = false;
  bool failAuthorizePayment = false;
  bool failRefreshPayment = false;

  RetailerSupplierPaymentState nextPaymentState =
      RetailerSupplierPaymentState.settled;

  int placeOrderCalls = 0;
  int refreshDeliveryCalls = 0;
  int postReceiptCalls = 0;
  int refreshPurchaseCalls = 0;
  int exportPurchaseCalls = 0;
  int authorizePaymentCalls = 0;
  int refreshPaymentCalls = 0;

  Future<void> _wait() =>
      Future<void>.delayed(const Duration(milliseconds: 24));

  Future<List<String>> placeOrders(String fingerprint) async {
    placeOrderCalls += 1;
    await _wait();
    if (failPlaceOrders) {
      failPlaceOrders = false;
      throw const RetailerGatewayException(
        'The purchase orders were not placed. Your quantities and delivery choices remain ready for retry.',
      );
    }
    return const ['PO-MS-8201', 'PO-MS-8202'];
  }

  Future<void> refreshDelivery(String orderId) async {
    refreshDeliveryCalls += 1;
    await _wait();
    if (failRefreshDelivery) {
      failRefreshDelivery = false;
      throw const RetailerGatewayException(
        'Delivery tracking could not refresh. The last verified update remains visible.',
      );
    }
  }

  Future<String> postReceipt(
    String orderId,
    RetailerGoodsReceiptChoice choice,
  ) async {
    postReceiptCalls += 1;
    await _wait();
    if (failPostReceipt) {
      failPostReceipt = false;
      throw const RetailerGatewayException(
        'The goods receipt was not posted. Your accepted quantity, issue and evidence remain ready for retry.',
      );
    }
    return 'GRN-85021';
  }

  Future<void> refreshPurchases() async {
    refreshPurchaseCalls += 1;
    await _wait();
    if (failRefreshPurchases) {
      failRefreshPurchases = false;
      throw const RetailerGatewayException(
        'The Purchase Book could not refresh. Existing purchases remain available.',
      );
    }
  }

  Future<void> exportPurchases(String format) async {
    exportPurchaseCalls += 1;
    await _wait();
    if (failExportPurchases) {
      failExportPurchases = false;
      throw const RetailerGatewayException(
        'The purchase export was not created. Choose the same format to retry.',
      );
    }
  }

  Future<String> authorizeSupplierPayment(
    String billId,
    RetailerSupplierPaymentMethod method,
  ) async {
    authorizePaymentCalls += 1;
    await _wait();
    if (failAuthorizePayment) {
      failAuthorizePayment = false;
      throw const RetailerGatewayException(
        'Payment was not authorized. The supplier bill remains unpaid and ready for retry.',
      );
    }
    return 'PAY-RTD-2568';
  }

  Future<RetailerSupplierPaymentState> refreshSupplierPayment(
    String paymentId,
  ) async {
    refreshPaymentCalls += 1;
    await _wait();
    if (failRefreshPayment) {
      failRefreshPayment = false;
      throw const RetailerGatewayException(
        'Payment status could not refresh. Do not pay again while the last verified state is processing.',
      );
    }
    return nextPaymentState;
  }
}
