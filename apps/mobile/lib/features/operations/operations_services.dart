class OperationsGatewayException implements Exception {
  const OperationsGatewayException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ReviewOperationsGateway {
  bool failApplication = false;
  bool failWorkStart = false;
  bool failOutcome = false;
  bool failStatement = false;
  bool failEarnSupport = false;
  bool failServiceSave = false;
  bool failAvailability = false;
  bool failRequestAccept = false;
  bool failRequestDecline = false;
  bool failFulfilment = false;
  bool failExport = false;
  bool failGrowthAccept = false;
  bool failControls = false;
  bool failProviderSupport = false;

  int applicationCalls = 0;
  int workStartCalls = 0;
  int outcomeCalls = 0;
  int statementCalls = 0;
  int earnSupportCalls = 0;
  int serviceSaveCalls = 0;
  int availabilityCalls = 0;
  int requestAcceptCalls = 0;
  int requestDeclineCalls = 0;
  int fulfilmentCalls = 0;
  int exportCalls = 0;
  int growthAcceptCalls = 0;
  int controlsCalls = 0;
  int providerSupportCalls = 0;

  Future<void> apply() => _attempt(
    counter: () => applicationCalls += 1,
    shouldFail: () => failApplication,
    clearFailure: () => failApplication = false,
    message: 'Application could not be sent. Your terms remain selected.',
  );

  Future<void> startWork() => _attempt(
    counter: () => workStartCalls += 1,
    shouldFail: () => failWorkStart,
    clearFailure: () => failWorkStart = false,
    message: 'Work could not start. Your reserved seat is unchanged.',
  );

  Future<void> submitOutcome() => _attempt(
    counter: () => outcomeCalls += 1,
    shouldFail: () => failOutcome,
    clearFailure: () => failOutcome = false,
    message: 'Outcome could not be submitted. All proof remains saved.',
  );

  Future<void> prepareStatement() => _attempt(
    counter: () => statementCalls += 1,
    shouldFail: () => failStatement,
    clearFailure: () => failStatement = false,
    message: 'Statement could not be prepared. Try the same action again.',
  );

  Future<void> openEarnSupport() => _attempt(
    counter: () => earnSupportCalls += 1,
    shouldFail: () => failEarnSupport,
    clearFailure: () => failEarnSupport = false,
    message: 'Support case could not be opened. Your description is saved.',
  );

  Future<void> saveService() => _attempt(
    counter: () => serviceSaveCalls += 1,
    shouldFail: () => failServiceSave,
    clearFailure: () => failServiceSave = false,
    message: 'Service could not be saved. Your details are still here.',
  );

  Future<void> saveAvailability() => _attempt(
    counter: () => availabilityCalls += 1,
    shouldFail: () => failAvailability,
    clearFailure: () => failAvailability = false,
    message: 'Availability could not be saved. No customer promise changed.',
  );

  Future<void> acceptRequest() => _attempt(
    counter: () => requestAcceptCalls += 1,
    shouldFail: () => failRequestAccept,
    clearFailure: () => failRequestAccept = false,
    message: 'Request was not accepted. Capacity remains open.',
  );

  Future<void> declineRequest() => _attempt(
    counter: () => requestDeclineCalls += 1,
    shouldFail: () => failRequestDecline,
    clearFailure: () => failRequestDecline = false,
    message: 'Response was not sent. The request remains open.',
  );

  Future<void> completeFulfilment() => _attempt(
    counter: () => fulfilmentCalls += 1,
    shouldFail: () => failFulfilment,
    clearFailure: () => failFulfilment = false,
    message: 'Completion could not be confirmed. Payment remains protected.',
  );

  Future<void> exportRecords() => _attempt(
    counter: () => exportCalls += 1,
    shouldFail: () => failExport,
    clearFailure: () => failExport = false,
    message: 'File could not be prepared. Choose the same export again.',
  );

  Future<void> acceptGrowth() => _attempt(
    counter: () => growthAcceptCalls += 1,
    shouldFail: () => failGrowthAccept,
    clearFailure: () => failGrowthAccept = false,
    message: 'Funded work was not accepted. Reserved terms remain visible.',
  );

  Future<void> saveControls() => _attempt(
    counter: () => controlsCalls += 1,
    shouldFail: () => failControls,
    clearFailure: () => failControls = false,
    message: 'Controls could not be saved. The previous version is active.',
  );

  Future<void> openProviderSupport() => _attempt(
    counter: () => providerSupportCalls += 1,
    shouldFail: () => failProviderSupport,
    clearFailure: () => failProviderSupport = false,
    message: 'Support case could not be opened. Your details remain saved.',
  );

  Future<void> _attempt({
    required void Function() counter,
    required bool Function() shouldFail,
    required void Function() clearFailure,
    required String message,
  }) async {
    counter();
    await Future<void>.delayed(const Duration(milliseconds: 1));
    if (shouldFail()) {
      clearFailure();
      throw OperationsGatewayException(message);
    }
  }
}
