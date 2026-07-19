import 'retailer_services.dart';
import 'retailer_books_models.dart';

class ReviewRetailerBooksGateway {
  bool failRefreshStock = false;
  bool failAdjustStock = false;
  bool failExportStock = false;
  bool failRefreshBook = false;
  bool failExportBook = false;
  bool failSaveExpense = false;
  bool failResolveMoney = false;

  int refreshStockCalls = 0;
  int adjustStockCalls = 0;
  int exportStockCalls = 0;
  int refreshBookCalls = 0;
  int exportBookCalls = 0;
  int saveExpenseCalls = 0;
  int resolveMoneyCalls = 0;

  Future<void> _wait() =>
      Future<void>.delayed(const Duration(milliseconds: 24));

  Future<void> refreshStock() async {
    refreshStockCalls += 1;
    await _wait();
    if (failRefreshStock) {
      failRefreshStock = false;
      throw const RetailerGatewayException(
        'The Stock Statement could not refresh. Existing movements remain available.',
      );
    }
  }

  Future<String> adjustStock(
    RetailerStockAdjustmentKind kind,
    int quantity,
    String reason,
  ) async {
    adjustStockCalls += 1;
    await _wait();
    if (failAdjustStock) {
      failAdjustStock = false;
      throw const RetailerGatewayException(
        'The stock change was not recorded. Quantity, reason and approval remain ready for retry.',
      );
    }
    return 'ADJ-9101';
  }

  Future<void> exportStock(String format) async {
    exportStockCalls += 1;
    await _wait();
    if (failExportStock) {
      failExportStock = false;
      throw const RetailerGatewayException(
        'The stock export was not created. Choose the same format to retry.',
      );
    }
  }

  Future<void> refreshBusinessBook() async {
    refreshBookCalls += 1;
    await _wait();
    if (failRefreshBook) {
      failRefreshBook = false;
      throw const RetailerGatewayException(
        'The Business Book could not refresh. Existing approved records remain available.',
      );
    }
  }

  Future<void> exportBusinessBook(String format) async {
    exportBookCalls += 1;
    await _wait();
    if (failExportBook) {
      failExportBook = false;
      throw const RetailerGatewayException(
        'The business report was not created. Choose the same format to retry.',
      );
    }
  }

  Future<String> saveExpense(RetailerExpense expense) async {
    saveExpenseCalls += 1;
    await _wait();
    if (failSaveExpense) {
      failSaveExpense = false;
      throw const RetailerGatewayException(
        'The expense was not saved. Amount, category, method and note remain ready for retry.',
      );
    }
    return 'EXP-10601';
  }

  Future<void> resolveMoney(String exceptionId) async {
    resolveMoneyCalls += 1;
    await _wait();
    if (failResolveMoney) {
      failResolveMoney = false;
      throw const RetailerGatewayException(
        'The money exception was not resolved. Its evidence and existing status remain unchanged.',
      );
    }
  }
}
