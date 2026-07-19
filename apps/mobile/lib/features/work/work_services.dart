class WorkGatewayException implements Exception {
  const WorkGatewayException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ReviewWorkGateway {
  bool failFeed = false;
  bool failApplication = false;
  bool failOtp = false;
  bool failProof = false;
  bool failSubmission = false;
  bool failReview = false;
  bool failGst = false;
  bool failSetup = false;

  int applicationCalls = 0;
  int otpCalls = 0;
  int proofCalls = 0;
  int submissionCalls = 0;
  int reviewCalls = 0;
  int gstCalls = 0;
  int setupCalls = 0;

  Future<void> _wait() =>
      Future<void>.delayed(const Duration(milliseconds: 24));

  Future<void> loadFeed() async {
    await _wait();
    if (failFeed) {
      failFeed = false;
      throw const WorkGatewayException(
        'Work could not be refreshed. Check your connection and try again.',
      );
    }
  }

  Future<String> apply(String opportunityId) async {
    applicationCalls += 1;
    await _wait();
    if (failApplication) {
      failApplication = false;
      throw const WorkGatewayException(
        'Application was not sent. Your opportunity is still saved.',
      );
    }
    return 'APP-${opportunityId.toUpperCase()}-${1200 + applicationCalls}';
  }

  Future<void> sendOtp(String mobile) async {
    otpCalls += 1;
    await _wait();
    if (failOtp) {
      failOtp = false;
      throw const WorkGatewayException(
        'OTP could not be sent. Check the number and try again.',
      );
    }
  }

  Future<String> saveProof(String proofId, String source) async {
    proofCalls += 1;
    await _wait();
    if (failProof) {
      failProof = false;
      throw const WorkGatewayException(
        'Proof was not added. Choose the same file or source and retry.',
      );
    }
    return 'PROOF-${proofId.toUpperCase()}-$proofCalls';
  }

  Future<String> submitProfile() async {
    submissionCalls += 1;
    await _wait();
    if (failSubmission) {
      failSubmission = false;
      throw const WorkGatewayException(
        'Work profile was not submitted. Your details and proof remain saved.',
      );
    }
    return 'WP-${240700 + submissionCalls}';
  }

  Future<String> checkReview() async {
    reviewCalls += 1;
    await _wait();
    if (failReview) {
      failReview = false;
      throw const WorkGatewayException(
        'Review update is unavailable. No duplicate request was created.',
      );
    }
    return 'WK-${510000 + reviewCalls}';
  }

  Future<String> submitGst() async {
    gstCalls += 1;
    await _wait();
    if (failGst) {
      failGst = false;
      throw const WorkGatewayException(
        'GST proof was not submitted. Your review remains active.',
      );
    }
    return 'GST-$gstCalls';
  }

  Future<void> finishSetup() async {
    setupCalls += 1;
    await _wait();
    if (failSetup) {
      failSetup = false;
      throw const WorkGatewayException(
        'Shop setup was not completed. Product and fulfilment choices remain saved.',
      );
    }
  }
}
