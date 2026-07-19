import 'retailer_business_services_models.dart';
import 'retailer_services.dart';

class ReviewRetailerBusinessServicesGateway {
  bool failRefreshCatalogue = false;
  bool failLoadPlans = false;
  bool failActivate = false;
  bool failSetup = false;
  bool failSupport = false;
  bool failCancel = false;

  int refreshCatalogueCalls = 0;
  int loadPlansCalls = 0;
  int activateCalls = 0;
  int setupCalls = 0;
  int supportCalls = 0;
  int cancelCalls = 0;

  Future<void> _wait() =>
      Future<void>.delayed(const Duration(milliseconds: 24));

  Future<void> refreshCatalogue() async {
    refreshCatalogueCalls += 1;
    await _wait();
    if (failRefreshCatalogue) {
      failRefreshCatalogue = false;
      throw const RetailerGatewayException(
        'Business Services could not refresh. Existing plan details remain available.',
      );
    }
  }

  Future<void> loadPlans(RetailerBusinessServiceType service) async {
    loadPlansCalls += 1;
    await _wait();
    if (failLoadPlans) {
      failLoadPlans = false;
      throw const RetailerGatewayException(
        'The selected service plans could not load. Your previous selection remains ready to retry.',
      );
    }
  }

  Future<String> activate({
    required RetailerBusinessServiceType service,
    required String planId,
    required int monthlyLimit,
    required RetailerBusinessPayment payment,
    required String idempotencyKey,
  }) async {
    activateCalls += 1;
    await _wait();
    if (failActivate) {
      failActivate = false;
      throw const RetailerGatewayException(
        'Payment was not completed, so the service was not activated. Your plan, limit, payment and consent choices remain ready to retry.',
      );
    }
    return 'MS-BS-240711-${service.name.toUpperCase()}';
  }

  Future<void> saveSetup(
    RetailerBusinessServiceType service,
    String setupId,
  ) async {
    setupCalls += 1;
    await _wait();
    if (failSetup) {
      failSetup = false;
      throw const RetailerGatewayException(
        'This service setup was not saved. Its current status remains unchanged and is ready to retry.',
      );
    }
  }

  Future<void> openSupport(RetailerBusinessServiceType service) async {
    supportCalls += 1;
    await _wait();
    if (failSupport) {
      failSupport = false;
      throw const RetailerGatewayException(
        'Service support could not open. Your active service remains unchanged.',
      );
    }
  }

  Future<void> cancel(RetailerBusinessServiceType service) async {
    cancelCalls += 1;
    await _wait();
    if (failCancel) {
      failCancel = false;
      throw const RetailerGatewayException(
        'The cancellation request was not completed. The service remains active and is ready to retry.',
      );
    }
  }
}
