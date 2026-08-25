import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../journey01/journey_services.dart';
import 'youtube_public_catalogue_repository.dart';

enum YouTubePublicShortFreshness { fresh, stale, expired, missing, invalidated }

bool youtubePublicShortHydrationIsDegraded(
  YouTubePublicShortFreshness? freshness,
) =>
    freshness != YouTubePublicShortFreshness.fresh &&
    freshness != YouTubePublicShortFreshness.missing;

final class YouTubePublicShortSnapshot {
  YouTubePublicShortSnapshot({
    required this.selectedVideoId,
    required this.activeIndex,
    required List<String> catalogueVideoIds,
    required DateTime capturedAtUtc,
  }) : catalogueVideoIds = List<String>.unmodifiable(catalogueVideoIds),
       capturedAtUtc = capturedAtUtc.toUtc();

  final String selectedVideoId;
  final int activeIndex;
  final List<String> catalogueVideoIds;
  final DateTime capturedAtUtc;
}

final class YouTubePublicShortRead {
  const YouTubePublicShortRead({required this.freshness, this.snapshot});

  final YouTubePublicShortFreshness freshness;
  final YouTubePublicShortSnapshot? snapshot;
}

abstract interface class YouTubePublicShortStateRepository {
  Future<YouTubePublicShortRead> read();

  Future<void> write(YouTubePublicShortSnapshot snapshot);

  Future<void> clear();
}

final class SecureStorageYouTubePublicShortKeyValueStore
    implements YouTubePublicCatalogueKeyValueStore {
  SecureStorageYouTubePublicShortKeyValueStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(
              storageNamespace: 'moolsocial_youtube_public_short',
            ),
          );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readString(String key) => _storage.read(key: key);

  @override
  Future<bool> writeString(String key, String value) async {
    await _storage.write(key: key, value: value);
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    await _storage.delete(key: key);
    return true;
  }
}

final class YouTubePublicShortPersistenceException implements Exception {
  const YouTubePublicShortPersistenceException(this.code);

  final String code;

  @override
  String toString() => 'YouTube public Short persistence failed ($code).';
}

final class DurableYouTubePublicShortStateRepository
    implements YouTubePublicShortStateRepository {
  DurableYouTubePublicShortStateRepository({
    required YouTubePublicCatalogueKeyValueStore persistence,
    required this.principalBinding,
    this.freshTimeToLive = const Duration(minutes: 5),
    this.maximumAge = const Duration(hours: 24),
    this.regionCode = 'IN',
    DateTime Function()? now,
  }) : _store = persistence,
       _now = now ?? DateTime.now {
    if (freshTimeToLive.isNegative ||
        maximumAge < freshTimeToLive ||
        maximumAge > const Duration(hours: 24) ||
        !RegExp(r'^[A-Z]{2}$').hasMatch(regionCode)) {
      throw ArgumentError('Invalid Short repository configuration.');
    }
  }

  static const storageKey = 'youtube_public_short_state_v1';
  static const invalidationKey = 'youtube_public_short_state_invalidated_v1';
  static const _schema = 'moolsocial.youtube_public_short_state';
  static const _version = 1;
  static const _maximumItems = 20;
  static const _maximumVideoIdLength = 128;
  static const _maximumEnvelopeBytes = 64 * 1024;
  static const _fields = <String>{
    'schema',
    'version',
    'regionCode',
    'principalBinding',
    'capturedAtUtc',
    'selectedVideoId',
    'activeIndex',
    'catalogueVideoIds',
  };
  static Future<void> _globalTail = Future<void>.value();

  static Future<void> invalidateUnbound(
    YouTubePublicCatalogueKeyValueStore persistence,
  ) => _enqueueGlobal(() async {
    await _writeRequiredTo(persistence, invalidationKey, '1');
    await _removeRequiredFrom(persistence, storageKey);
    await _removeRequiredFrom(persistence, invalidationKey);
  });

  final YouTubePublicCatalogueKeyValueStore _store;
  final DateTime Function() _now;
  final Duration freshTimeToLive;
  final Duration maximumAge;
  final String regionCode;
  final VerifiedPrincipalBinding principalBinding;

  @override
  Future<YouTubePublicShortRead> read() => _enqueueGlobal(_readQueued);

  @override
  Future<void> write(YouTubePublicShortSnapshot snapshot) async {
    late final String encoded;
    try {
      encoded = _encode(snapshot);
    } on YouTubePublicShortPersistenceException {
      rethrow;
    } on Object {
      throw const YouTubePublicShortPersistenceException('invalid_input');
    }
    await _enqueueGlobal(() async {
      await _writeRequiredTo(_store, storageKey, encoded);
    });
  }

  @override
  Future<void> clear() => _enqueueGlobal(_clearQueued);

  static Future<T> _enqueueGlobal<T>(Future<T> Function() operation) {
    final result = _globalTail.then((_) => operation());
    _globalTail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  Future<YouTubePublicShortRead> _readQueued() async {
    final invalidated = await _readRequired(invalidationKey);
    if (invalidated != null) {
      await _removeRequiredFrom(_store, storageKey);
      await _removeRequiredFrom(_store, invalidationKey);
      return const YouTubePublicShortRead(
        freshness: YouTubePublicShortFreshness.invalidated,
      );
    }
    final raw = await _readRequired(storageKey);
    if (raw == null) {
      return const YouTubePublicShortRead(
        freshness: YouTubePublicShortFreshness.missing,
      );
    }
    late final YouTubePublicShortSnapshot snapshot;
    try {
      snapshot = _decode(raw);
    } on Object {
      await _clearQueued();
      return const YouTubePublicShortRead(
        freshness: YouTubePublicShortFreshness.invalidated,
      );
    }
    final age = _now().toUtc().difference(snapshot.capturedAtUtc);
    if (age.isNegative) {
      await _clearQueued();
      return const YouTubePublicShortRead(
        freshness: YouTubePublicShortFreshness.invalidated,
      );
    }
    if (age <= freshTimeToLive) {
      return YouTubePublicShortRead(
        freshness: YouTubePublicShortFreshness.fresh,
        snapshot: snapshot,
      );
    }
    if (age <= maximumAge) {
      return YouTubePublicShortRead(
        freshness: YouTubePublicShortFreshness.stale,
        snapshot: snapshot,
      );
    }
    await _clearQueued();
    return const YouTubePublicShortRead(
      freshness: YouTubePublicShortFreshness.expired,
    );
  }

  Future<String?> _readRequired(String key) async {
    try {
      return await _store.readString(key);
    } on Object {
      throw const YouTubePublicShortPersistenceException('read_failed');
    }
  }

  String _encode(YouTubePublicShortSnapshot snapshot) {
    _validate(snapshot);
    final raw = jsonEncode(<String, Object?>{
      'schema': _schema,
      'version': _version,
      'regionCode': regionCode,
      'principalBinding': principalBinding.storageValue,
      'capturedAtUtc': snapshot.capturedAtUtc.toIso8601String(),
      'selectedVideoId': snapshot.selectedVideoId,
      'activeIndex': snapshot.activeIndex,
      'catalogueVideoIds': snapshot.catalogueVideoIds,
    });
    if (utf8.encode(raw).length > _maximumEnvelopeBytes) {
      throw const YouTubePublicShortPersistenceException('invalid_input');
    }
    return raw;
  }

  YouTubePublicShortSnapshot _decode(String raw) {
    if (utf8.encode(raw).length > _maximumEnvelopeBytes) {
      throw const FormatException();
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic> ||
        decoded.length != _fields.length ||
        !decoded.keys.toSet().containsAll(_fields) ||
        decoded['schema'] != _schema ||
        decoded['version'] is! int ||
        decoded['version'] != _version ||
        decoded['regionCode'] != regionCode ||
        decoded['principalBinding'] is! String ||
        decoded['selectedVideoId'] is! String ||
        decoded['activeIndex'] is! int ||
        decoded['catalogueVideoIds'] is! List) {
      throw const FormatException();
    }
    late final VerifiedPrincipalBinding persistedBinding;
    try {
      persistedBinding = VerifiedPrincipalBinding.fromStorage(
        decoded['principalBinding'] as String,
      );
    } on FormatException {
      throw const FormatException();
    }
    if (!principalBinding.matches(persistedBinding)) {
      throw const FormatException();
    }
    final rawIds = decoded['catalogueVideoIds'] as List;
    if (rawIds.any((value) => value is! String)) {
      throw const FormatException();
    }
    final snapshot = YouTubePublicShortSnapshot(
      selectedVideoId: decoded['selectedVideoId'] as String,
      activeIndex: decoded['activeIndex'] as int,
      catalogueVideoIds: rawIds.cast<String>(),
      capturedAtUtc: _parseUtcDate(decoded['capturedAtUtc']),
    );
    _validate(snapshot, persisted: true);
    return snapshot;
  }

  void _validate(
    YouTubePublicShortSnapshot snapshot, {
    bool persisted = false,
  }) {
    Never invalid() {
      if (persisted) throw const FormatException();
      throw const YouTubePublicShortPersistenceException('invalid_input');
    }

    final ids = snapshot.catalogueVideoIds;
    if (ids.isEmpty ||
        ids.length > _maximumItems ||
        snapshot.activeIndex < 0 ||
        snapshot.activeIndex >= ids.length ||
        !_validVideoId(snapshot.selectedVideoId) ||
        !snapshot.capturedAtUtc.isUtc ||
        snapshot.capturedAtUtc.isAfter(_now().toUtc())) {
      invalid();
    }
    final unique = <String>{};
    for (final id in ids) {
      if (!_validVideoId(id) || !unique.add(id)) invalid();
    }
    if (ids[snapshot.activeIndex] != snapshot.selectedVideoId) invalid();
  }

  static bool _validVideoId(String value) =>
      value.isNotEmpty &&
      value == value.trim() &&
      value.length <= _maximumVideoIdLength;

  Future<void> _clearQueued() async {
    await _writeRequiredTo(_store, invalidationKey, '1');
    await _removeRequiredFrom(_store, storageKey);
    await _removeRequiredFrom(_store, invalidationKey);
  }

  static Future<void> _writeRequiredTo(
    YouTubePublicCatalogueKeyValueStore store,
    String key,
    String value,
  ) async {
    late final bool succeeded;
    try {
      succeeded = await store.writeString(key, value);
    } on Object {
      throw const YouTubePublicShortPersistenceException('write_failed');
    }
    if (!succeeded) {
      throw const YouTubePublicShortPersistenceException('write_failed');
    }
  }

  static Future<void> _removeRequiredFrom(
    YouTubePublicCatalogueKeyValueStore store,
    String key,
  ) async {
    late final bool succeeded;
    try {
      succeeded = await store.remove(key);
    } on Object {
      throw const YouTubePublicShortPersistenceException('remove_failed');
    }
    if (!succeeded) {
      throw const YouTubePublicShortPersistenceException('remove_failed');
    }
  }

  static DateTime _parseUtcDate(Object? value) {
    if (value is! String || !value.endsWith('Z')) {
      throw const FormatException();
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null || !parsed.isUtc || parsed.toIso8601String() != value) {
      throw const FormatException();
    }
    return parsed;
  }
}

final class YouTubePublicShortStateCache {
  YouTubePublicShortStateCache({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  YouTubePublicShortStateRepository? _repository;
  YouTubePublicShortSnapshot? _snapshot;
  Future<void> _mutationTail = Future<void>.value();
  int _userGeneration = 0;
  int _principalBindingEpoch = 0;
  int _bindingBaselineUserGeneration = 0;

  YouTubePublicShortSnapshot? get snapshot => _snapshot;

  int beginPrincipalBindingAttempt() {
    _principalBindingEpoch += 1;
    _bindingBaselineUserGeneration = _userGeneration;
    _repository = null;
    _snapshot = null;
    return _principalBindingEpoch;
  }

  Future<YouTubePublicShortFreshness?> configureDurability(
    YouTubePublicShortStateRepository repository, {
    int? bindingAttempt,
  }) async {
    if (bindingAttempt != null && bindingAttempt != _principalBindingEpoch) {
      return null;
    }
    _repository = repository;
    final userGeneration = _userGeneration;
    final hadLocalMutationBeforeRead =
        bindingAttempt != null &&
        userGeneration != _bindingBaselineUserGeneration;
    late final YouTubePublicShortRead read;
    try {
      read = await repository.read();
    } on Object {
      return null;
    }
    if ((bindingAttempt != null && bindingAttempt != _principalBindingEpoch) ||
        !identical(repository, _repository)) {
      return read.freshness;
    }
    if (hadLocalMutationBeforeRead || userGeneration != _userGeneration) {
      final current = _snapshot;
      if (current == null) {
        _observeClear(repository);
      } else {
        _write(current);
      }
      await _mutationTail;
      return read.freshness;
    }
    _snapshot = read.freshness == YouTubePublicShortFreshness.fresh
        ? read.snapshot
        : null;
    return read.freshness;
  }

  void replace({
    required String selectedVideoId,
    required int activeIndex,
    required List<String> catalogueVideoIds,
  }) {
    _userGeneration += 1;
    final next = YouTubePublicShortSnapshot(
      selectedVideoId: selectedVideoId,
      activeIndex: activeIndex,
      catalogueVideoIds: catalogueVideoIds,
      capturedAtUtc: _now().toUtc(),
    );
    _snapshot = next;
    _write(next);
  }

  Future<void> clear({bool detachRepository = false}) {
    _userGeneration += 1;
    if (detachRepository) _principalBindingEpoch += 1;
    _snapshot = null;
    final repository = _repository;
    if (detachRepository) _repository = null;
    if (repository == null) return Future<void>.value();
    _observeClear(repository);
    return _mutationTail;
  }

  Future<void> settleDurableWrites() => _mutationTail;

  void _observeClear(YouTubePublicShortStateRepository repository) {
    late final Future<void> mutation;
    try {
      mutation = repository.clear();
    } on Object {
      return;
    }
    _observe(mutation);
  }

  void _write(YouTubePublicShortSnapshot snapshot) {
    final repository = _repository;
    if (repository == null) return;
    late final Future<void> mutation;
    try {
      mutation = repository.write(snapshot);
    } on Object {
      return;
    }
    _observe(mutation);
  }

  void _observe(Future<void> mutation) {
    final observed = mutation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _mutationTail = Future.wait<void>([
      _mutationTail,
      observed,
    ]).then<void>((_) {});
  }
}

final youtubePublicShortState = YouTubePublicShortStateCache();
