class CreatorGatewayException implements Exception {
  const CreatorGatewayException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ReviewCreatorGateway {
  bool failDraft = false;
  bool failPostPublish = false;
  bool failYouTubeValidation = false;
  bool failYouTubePublish = false;
  bool failCampaignAccept = false;
  bool failStatement = false;
  bool failAppeal = false;
  bool failMembership = false;

  int draftCalls = 0;
  int postPublishCalls = 0;
  int youtubeValidationCalls = 0;
  int youtubePublishCalls = 0;
  int campaignAcceptCalls = 0;
  int statementCalls = 0;
  int appealCalls = 0;
  int membershipCalls = 0;

  Future<void> saveDraft() => _run(
    counter: () => draftCalls += 1,
    shouldFail: () => failDraft,
    clearFailure: () => failDraft = false,
    message: 'Draft could not be saved. Your content is still here.',
  );

  Future<void> publishPost() => _run(
    counter: () => postPublishCalls += 1,
    shouldFail: () => failPostPublish,
    clearFailure: () => failPostPublish = false,
    message: 'Post could not be published. Review it and retry.',
  );

  Future<void> validateYouTube() => _run(
    counter: () => youtubeValidationCalls += 1,
    shouldFail: () => failYouTubeValidation,
    clearFailure: () => failYouTubeValidation = false,
    message:
        'YouTube could not validate this content. Check availability and retry.',
  );

  Future<void> publishYouTubeConnection() => _run(
    counter: () => youtubePublishCalls += 1,
    shouldFail: () => failYouTubePublish,
    clearFailure: () => failYouTubePublish = false,
    message:
        'The connected post was not published. Your video and Mool action are saved.',
  );

  Future<void> acceptCampaign() => _run(
    counter: () => campaignAcceptCalls += 1,
    shouldFail: () => failCampaignAccept,
    clearFailure: () => failCampaignAccept = false,
    message:
        'Campaign acceptance did not complete. The funded seat is unchanged.',
  );

  Future<void> prepareStatement() => _run(
    counter: () => statementCalls += 1,
    shouldFail: () => failStatement,
    clearFailure: () => failStatement = false,
    message: 'Statement could not be prepared. No payout record changed.',
  );

  Future<void> submitAppeal() => _run(
    counter: () => appealCalls += 1,
    shouldFail: () => failAppeal,
    clearFailure: () => failAppeal = false,
    message: 'Appeal was not submitted. Your evidence remains attached.',
  );

  Future<void> saveMembership() => _run(
    counter: () => membershipCalls += 1,
    shouldFail: () => failMembership,
    clearFailure: () => failMembership = false,
    message:
        'Membership plan could not be saved. Price and benefits are unchanged.',
  );

  Future<void> _run({
    required void Function() counter,
    required bool Function() shouldFail,
    required void Function() clearFailure,
    required String message,
  }) async {
    counter();
    await Future<void>.delayed(const Duration(milliseconds: 1));
    if (shouldFail()) {
      clearFailure();
      throw CreatorGatewayException(message);
    }
  }
}
