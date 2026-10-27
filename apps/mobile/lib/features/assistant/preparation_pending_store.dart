import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Only bounded pending-request identity is kept, never chat text, media, model
/// credentials or permission grants. A saved key is not proof of server success.
abstract interface class AssistantPreparationPendingStore {
  Future<String?> read(String ownerScopeKey);
  Future<void> write(String ownerScopeKey, String metadata);
  Future<void> clear(String ownerScopeKey);
}

class SecureAssistantPreparationPendingStore
    implements AssistantPreparationPendingStore {
  SecureAssistantPreparationPendingStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;
  String _key(String owner) => 'assistant.preparation.pending.v1.$owner';
  @override
  Future<String?> read(String ownerScopeKey) =>
      _storage.read(key: _key(ownerScopeKey));
  @override
  Future<void> write(String ownerScopeKey, String metadata) =>
      _storage.write(key: _key(ownerScopeKey), value: metadata);
  @override
  Future<void> clear(String ownerScopeKey) =>
      _storage.delete(key: _key(ownerScopeKey));
}
