class ChatServiceException implements Exception {
  const ChatServiceException(this.userMessage);

  final String userMessage;
}

abstract interface class ChatSendGateway {
  Future<void> send({
    required String threadId,
    required String text,
    String? attachmentLabel,
  });
}

class ReviewChatSendGateway implements ChatSendGateway {
  ReviewChatSendGateway({
    this.failNextRequest = false,
    this.latency = const Duration(milliseconds: 100),
  });

  bool failNextRequest;
  final Duration latency;

  @override
  Future<void> send({
    required String threadId,
    required String text,
    String? attachmentLabel,
  }) async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
    if (failNextRequest) {
      failNextRequest = false;
      throw const ChatServiceException(
        'Message was not sent. Check your connection and retry.',
      );
    }
  }
}
