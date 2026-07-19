import 'retailer_services.dart';

class ReviewRetailerCampaignGateway {
  bool failRefreshCustomers = false;
  bool failSendReminder = false;
  bool failRefreshCampaigns = false;
  bool failSaveDraft = false;
  bool failPublish = false;
  bool failPause = false;
  bool failDelete = false;

  int refreshCustomersCalls = 0;
  int sendReminderCalls = 0;
  int refreshCampaignsCalls = 0;
  int saveDraftCalls = 0;
  int publishCalls = 0;
  int pauseCalls = 0;
  int deleteCalls = 0;

  Future<void> _wait() =>
      Future<void>.delayed(const Duration(milliseconds: 24));

  Future<void> refreshCustomers() async {
    refreshCustomersCalls += 1;
    await _wait();
    if (failRefreshCustomers) {
      failRefreshCustomers = false;
      throw const RetailerGatewayException(
        'Customers could not refresh. Existing permission and order records remain available.',
      );
    }
  }

  Future<String> sendReminder({
    required String customerId,
    required String channel,
    required String message,
    required String idempotencyKey,
  }) async {
    sendReminderCalls += 1;
    await _wait();
    if (failSendReminder) {
      failSendReminder = false;
      throw const RetailerGatewayException(
        'The reminder was not sent. No message or order was created, and your text remains ready to retry.',
      );
    }
    return 'MSG-98071';
  }

  Future<void> refreshCampaigns() async {
    refreshCampaignsCalls += 1;
    await _wait();
    if (failRefreshCampaigns) {
      failRefreshCampaigns = false;
      throw const RetailerGatewayException(
        'Campaign results could not refresh. Existing budgets and campaign states remain unchanged.',
      );
    }
  }

  Future<String> saveDraft({
    required String name,
    required String idempotencyKey,
  }) async {
    saveDraftCalls += 1;
    await _wait();
    if (failSaveDraft) {
      failSaveDraft = false;
      throw const RetailerGatewayException(
        'The draft was not saved. Your campaign choices remain ready to retry.',
      );
    }
    return 'CMP-DRAFT-1001';
  }

  Future<String> publish({
    required String name,
    required int maximumOrders,
    required int spendCap,
    required String idempotencyKey,
  }) async {
    publishCalls += 1;
    await _wait();
    if (failPublish) {
      failPublish = false;
      throw const RetailerGatewayException(
        'The campaign was not published. No stock or budget was committed, and the reviewed campaign remains ready to retry.',
      );
    }
    return 'CMP-10001';
  }

  Future<void> pause(String campaignId) async {
    pauseCalls += 1;
    await _wait();
    if (failPause) {
      failPause = false;
      throw const RetailerGatewayException(
        'The campaign could not be paused. Its active budget and state remain unchanged.',
      );
    }
  }

  Future<void> deleteDraft(String campaignId) async {
    deleteCalls += 1;
    await _wait();
    if (failDelete) {
      failDelete = false;
      throw const RetailerGatewayException(
        'The draft could not be deleted. It remains available to continue or retry.',
      );
    }
  }
}
