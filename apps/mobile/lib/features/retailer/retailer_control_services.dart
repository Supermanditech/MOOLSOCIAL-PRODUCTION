import 'retailer_services.dart';

class ReviewRetailerControlGateway {
  bool failPublishRecovery = false;
  bool failAskAi = false;
  bool failInvite = false;
  bool failStaffChange = false;
  bool failSaveSettings = false;
  bool failResolveIssue = false;

  int recoveryCalls = 0;
  int askCalls = 0;
  int inviteCalls = 0;
  int staffChangeCalls = 0;
  int settingsCalls = 0;
  int issueCalls = 0;

  Future<void> _wait() =>
      Future<void>.delayed(const Duration(milliseconds: 24));

  Future<String> publishRecovery() async {
    recoveryCalls += 1;
    await _wait();
    if (failPublishRecovery) {
      failPublishRecovery = false;
      throw const RetailerGatewayException(
        'The recovery action was not published. No quantity was reserved and every choice remains ready to retry.',
      );
    }
    return 'REC-101-0715';
  }

  Future<String> askAi(String prompt) async {
    askCalls += 1;
    await _wait();
    if (failAskAi) {
      failAskAi = false;
      throw const RetailerGatewayException(
        'Mool AI could not prepare an answer. No business action was taken.',
      );
    }
    return 'AI-102-0715';
  }

  Future<String> inviteStaff() async {
    inviteCalls += 1;
    await _wait();
    if (failInvite) {
      failInvite = false;
      throw const RetailerGatewayException(
        'The secure invite was not sent. No staff access was granted.',
      );
    }
    return 'INV-103-0715';
  }

  Future<void> changeStaff() async {
    staffChangeCalls += 1;
    await _wait();
    if (failStaffChange) {
      failStaffChange = false;
      throw const RetailerGatewayException(
        'Staff access was not changed. Existing branch access remains unchanged.',
      );
    }
  }

  Future<String> saveSettings() async {
    settingsCalls += 1;
    await _wait();
    if (failSaveSettings) {
      failSaveSettings = false;
      throw const RetailerGatewayException(
        'Store settings were not saved. Customer-visible settings remain on the previous version.',
      );
    }
    return 'SET-104-0715';
  }

  Future<String> resolveIssue() async {
    issueCalls += 1;
    await _wait();
    if (failResolveIssue) {
      failResolveIssue = false;
      throw const RetailerGatewayException(
        'The issue resolution was not completed. Payment protection, stock and customer message remain unchanged.',
      );
    }
    return 'RES-105-0715';
  }
}
