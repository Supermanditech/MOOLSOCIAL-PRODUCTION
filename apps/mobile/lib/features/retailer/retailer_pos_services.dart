import 'retailer_services.dart';

class ReviewRetailerPosGateway {
  bool failCreateOrder = false;
  bool failSaveCounter = false;
  bool failToggleCounter = false;
  bool failCompleteSale = false;
  bool failShareInvoice = false;
  bool failRefreshSales = false;
  bool failExport = false;

  int createOrderCalls = 0;
  int saveCounterCalls = 0;
  int toggleCounterCalls = 0;
  int completeSaleCalls = 0;
  int shareInvoiceCalls = 0;
  int refreshSalesCalls = 0;
  int exportCalls = 0;

  Future<void> _wait() =>
      Future<void>.delayed(const Duration(milliseconds: 24));

  Future<String> createOrder(String fingerprint) async {
    createOrderCalls += 1;
    await _wait();
    if (failCreateOrder) {
      failCreateOrder = false;
      throw const RetailerGatewayException(
        'The order was not created. Your customer, products and choices remain ready for retry.',
      );
    }
    return 'RT-3028';
  }

  Future<void> saveCounter(String counterId) async {
    saveCounterCalls += 1;
    await _wait();
    if (failSaveCounter) {
      failSaveCounter = false;
      throw const RetailerGatewayException(
        'The counter was not saved. Its purpose and operator remain ready for retry.',
      );
    }
  }

  Future<void> setCounterOpen(String counterId, bool open) async {
    toggleCounterCalls += 1;
    await _wait();
    if (failToggleCounter) {
      failToggleCounter = false;
      throw const RetailerGatewayException(
        'The counter availability was not changed. Its previous state remains active.',
      );
    }
  }

  Future<String> completeSale(String orderId, String payment) async {
    completeSaleCalls += 1;
    await _wait();
    if (failCompleteSale) {
      failCompleteSale = false;
      throw const RetailerGatewayException(
        'The sale was not completed. Payment, reserved stock and the order remain unchanged for retry.',
      );
    }
    return 'MSI-3028';
  }

  Future<void> shareInvoice(String invoiceId, String channel) async {
    shareInvoiceCalls += 1;
    await _wait();
    if (failShareInvoice) {
      failShareInvoice = false;
      throw const RetailerGatewayException(
        'The invoice was not sent. The paid sale and invoice remain safely recorded.',
      );
    }
  }

  Future<void> refreshSales() async {
    refreshSalesCalls += 1;
    await _wait();
    if (failRefreshSales) {
      failRefreshSales = false;
      throw const RetailerGatewayException(
        'The Sales Book could not refresh. Existing sales remain available.',
      );
    }
  }

  Future<void> exportSales(String format) async {
    exportCalls += 1;
    await _wait();
    if (failExport) {
      failExport = false;
      throw const RetailerGatewayException(
        'The sales export was not created. Choose the same format to retry.',
      );
    }
  }
}
