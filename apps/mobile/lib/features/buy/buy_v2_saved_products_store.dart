abstract interface class BuyV2SavedProductsStore {
  const BuyV2SavedProductsStore();

  String? get ownerScope;

  Future<Set<String>?> read();

  Future<bool> write(Set<String> savedProductKeys);
}
