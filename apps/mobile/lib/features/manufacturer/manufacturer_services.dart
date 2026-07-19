class ManufacturerGatewayException implements Exception {
  const ManufacturerGatewayException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ReviewManufacturerGateway {
  bool failSupply = false;
  bool failProduct = false;
  bool failOrder = false;
  bool failPurchase = false;
  bool failDispatch = false;
  bool failCampaign = false;
  bool failClaim = false;
  bool failInvite = false;
  bool failSettings = false;
  bool failService = false;

  int supplyCalls = 0;
  int productCalls = 0;
  int orderCalls = 0;
  int purchaseCalls = 0;
  int dispatchCalls = 0;
  int campaignCalls = 0;
  int claimCalls = 0;
  int inviteCalls = 0;
  int settingsCalls = 0;
  int serviceCalls = 0;

  Future<void> setSupply(bool value) =>
      _run('supply', () => supplyCalls += 1, () => failSupply = false);

  Future<void> publishProduct() =>
      _run('product', () => productCalls += 1, () => failProduct = false);

  Future<void> confirmOrder() =>
      _run('order', () => orderCalls += 1, () => failOrder = false);

  Future<void> placePurchase() =>
      _run('purchase', () => purchaseCalls += 1, () => failPurchase = false);

  Future<void> dispatchOrder() =>
      _run('dispatch', () => dispatchCalls += 1, () => failDispatch = false);

  Future<void> publishCampaign() =>
      _run('campaign', () => campaignCalls += 1, () => failCampaign = false);

  Future<void> resolveClaim() =>
      _run('claim', () => claimCalls += 1, () => failClaim = false);

  Future<void> inviteTeam() =>
      _run('invite', () => inviteCalls += 1, () => failInvite = false);

  Future<void> saveSettings() =>
      _run('settings', () => settingsCalls += 1, () => failSettings = false);

  Future<void> requestService() =>
      _run('service', () => serviceCalls += 1, () => failService = false);

  Future<void> _run(
    String operation,
    void Function() count,
    void Function() clearFailure,
  ) async {
    count();
    await Future<void>.delayed(const Duration(milliseconds: 1));
    final shouldFail = switch (operation) {
      'supply' => failSupply,
      'product' => failProduct,
      'order' => failOrder,
      'purchase' => failPurchase,
      'dispatch' => failDispatch,
      'campaign' => failCampaign,
      'claim' => failClaim,
      'invite' => failInvite,
      'settings' => failSettings,
      _ => failService,
    };
    if (shouldFail) {
      clearFailure();
      throw ManufacturerGatewayException(
        'We could not complete $operation. Nothing was changed. Try again.',
      );
    }
  }
}
