class SharedGatewayException implements Exception {
  const SharedGatewayException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ReviewSharedGateway {
  bool failNext = false;
  String? failActionId;
  final Map<String, int> calls = <String, int>{};

  Future<void> execute(String actionId) async {
    calls[actionId] = (calls[actionId] ?? 0) + 1;
    await Future<void>.delayed(const Duration(milliseconds: 24));
    if (failNext && (failActionId == null || failActionId == actionId)) {
      failNext = false;
      failActionId = null;
      throw const SharedGatewayException(
        'That action did not complete. Your previous state and selections are safe. Retry the same action.',
      );
    }
  }
}
