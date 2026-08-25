import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../journey01/journey_services.dart';
import 'youtube_public_catalogue_repository.dart';
import 'youtube_public_search_state_repository.dart';

enum YouTubePublicWatchOrigin { home, search }

enum YouTubePublicWatchFreshness { fresh, stale, expired, missing, invalidated }

bool youtubePublicWatchHydrationIsDegraded(
  YouTubePublicWatchFreshness? freshness,
) =>
    freshness != YouTubePublicWatchFreshness.fresh &&
    freshness != YouTubePublicWatchFreshness.missing;

Future<({bool search, bool watch})> invalidateYouTubePublicRuntimeState({
  required YouTubePublicCatalogueKeyValueStore searchPersistence,
  required YouTubePublicCatalogueKeyValueStore watchPersistence,
  Duration? timeout,
}) async {
  Future<void> bounded(Future<void> operation) =>
      timeout == null ? operation : operation.timeout(timeout);
  var searchInvalidated = false;
  var watchInvalidated = false;
  try {
    await bounded(
      DurableYouTubePublicSearchStateRepository.invalidateUnbound(
        searchPersistence,
      ),
    );
    searchInvalidated = true;
  } on Object {
    // Watch invalidation remains mandatory after an independent Search error.
  }
  try {
    await bounded(
      DurableYouTubePublicWatchStateRepository.invalidateUnbound(
        watchPersistence,
      ),
    );
    watchInvalidated = true;
  } on Object {
    // Search invalidation remains authoritative after an independent Watch error.
  }
  return (search: searchInvalidated, watch: watchInvalidated);
}

final class YouTubePublicWatchSnapshot {
  YouTubePublicWatchSnapshot({
    required this.selectedVideo,
    required this.origin,
    this.searchOriginVideo,
    required this.watchScrollOffset,
    required this.homeScrollOffset,
    required DateTime capturedAtUtc,
  }) : capturedAtUtc = capturedAtUtc.toUtc();

  final YouTubePublicCatalogueItem selectedVideo;
  final YouTubePublicWatchOrigin origin;
  final YouTubePublicCatalogueItem? searchOriginVideo;
  final double watchScrollOffset;
  final double homeScrollOffset;
  final DateTime capturedAtUtc;

  YouTubePublicWatchSnapshot copyWith({double? watchScrollOffset}) =>
      YouTubePublicWatchSnapshot(
        selectedVideo: selectedVideo,
        origin: origin,
        searchOriginVideo: searchOriginVideo,
        watchScrollOffset: watchScrollOffset ?? this.watchScrollOffset,
        homeScrollOffset: homeScrollOffset,
        capturedAtUtc: capturedAtUtc,
      );
}

final class YouTubePublicWatchRead {
  const YouTubePublicWatchRead({required this.freshness, this.snapshot});

  final YouTubePublicWatchFreshness freshness;
  final YouTubePublicWatchSnapshot? snapshot;
}

abstract interface class YouTubePublicWatchStateRepository {
  Future<YouTubePublicWatchRead> read();

  Future<void> write(YouTubePublicWatchSnapshot snapshot);

  Future<void> clear();
}

final class SecureStorageYouTubePublicWatchKeyValueStore
    implements YouTubePublicCatalogueKeyValueStore {
  SecureStorageYouTubePublicWatchKeyValueStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(
              storageNamespace: 'moolsocial_youtube_public_watch',
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

final class YouTubePublicWatchPersistenceException implements Exception {
  const YouTubePublicWatchPersistenceException(this.code);

  final String code;

  @override
  String toString() => 'YouTube public Watch persistence failed ($code).';
}

final class DurableYouTubePublicWatchStateRepository
    implements YouTubePublicWatchStateRepository {
  DurableYouTubePublicWatchStateRepository({
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
      throw ArgumentError('Invalid Watch repository configuration.');
    }
  }

  static const storageKey = 'youtube_public_watch_state_v1';
  static const invalidationKey = 'youtube_public_watch_state_invalidated_v1';
  static const _schema = 'moolsocial.youtube_public_watch_state';
  static const _version = 1;
  static const _maximumEnvelopeBytes = 512 * 1024;
  static const _maximumScrollOffset = 10000000.0;
  static const _fields = <String>{
    'schema',
    'version',
    'regionCode',
    'principalBinding',
    'capturedAtUtc',
    'selectedVideo',
    'origin',
    'searchOriginVideo',
    'watchScrollOffset',
    'homeScrollOffset',
  };
  static const _itemCodec = YouTubePublicCatalogueItemJsonCodec();
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
  Future<YouTubePublicWatchRead> read() => _enqueueGlobal(_readQueued);

  @override
  Future<void> write(YouTubePublicWatchSnapshot snapshot) async {
    late final String encoded;
    try {
      encoded = _encode(snapshot);
    } on YouTubePublicWatchPersistenceException {
      rethrow;
    } on Object {
      throw const YouTubePublicWatchPersistenceException('invalid_input');
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

  Future<YouTubePublicWatchRead> _readQueued() async {
    final invalidated = await _readRequired(invalidationKey);
    if (invalidated != null) {
      await _removeRequiredFrom(_store, storageKey);
      await _removeRequiredFrom(_store, invalidationKey);
      return const YouTubePublicWatchRead(
        freshness: YouTubePublicWatchFreshness.invalidated,
      );
    }
    final raw = await _readRequired(storageKey);
    if (raw == null) {
      return const YouTubePublicWatchRead(
        freshness: YouTubePublicWatchFreshness.missing,
      );
    }
    late final YouTubePublicWatchSnapshot snapshot;
    try {
      snapshot = _decode(raw);
    } on Object {
      await _clearQueued();
      return const YouTubePublicWatchRead(
        freshness: YouTubePublicWatchFreshness.invalidated,
      );
    }
    final age = _now().toUtc().difference(snapshot.capturedAtUtc);
    if (age.isNegative) {
      await _clearQueued();
      return const YouTubePublicWatchRead(
        freshness: YouTubePublicWatchFreshness.invalidated,
      );
    }
    if (age <= freshTimeToLive) {
      return YouTubePublicWatchRead(
        freshness: YouTubePublicWatchFreshness.fresh,
        snapshot: snapshot,
      );
    }
    if (age <= maximumAge) {
      return YouTubePublicWatchRead(
        freshness: YouTubePublicWatchFreshness.stale,
        snapshot: snapshot,
      );
    }
    await _clearQueued();
    return const YouTubePublicWatchRead(
      freshness: YouTubePublicWatchFreshness.expired,
    );
  }

  Future<String?> _readRequired(String key) async {
    try {
      return await _store.readString(key);
    } on Object {
      throw const YouTubePublicWatchPersistenceException('read_failed');
    }
  }

  String _encode(YouTubePublicWatchSnapshot snapshot) {
    _validate(snapshot);
    final raw = jsonEncode(<String, Object?>{
      'schema': _schema,
      'version': _version,
      'regionCode': regionCode,
      'principalBinding': principalBinding.storageValue,
      'capturedAtUtc': snapshot.capturedAtUtc.toIso8601String(),
      'selectedVideo': _itemCodec.encode(snapshot.selectedVideo),
      'origin': snapshot.origin.name,
      'searchOriginVideo': snapshot.searchOriginVideo == null
          ? null
          : _itemCodec.encode(snapshot.searchOriginVideo!),
      'watchScrollOffset': snapshot.watchScrollOffset,
      'homeScrollOffset': snapshot.homeScrollOffset,
    });
    if (utf8.encode(raw).length > _maximumEnvelopeBytes) {
      throw const YouTubePublicWatchPersistenceException('invalid_input');
    }
    return raw;
  }

  YouTubePublicWatchSnapshot _decode(String raw) {
    if (utf8.encode(raw).length > _maximumEnvelopeBytes) {
      throw const YouTubePublicCatalogueItemCodecException();
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
        decoded['origin'] is! String ||
        decoded['watchScrollOffset'] is! num ||
        decoded['homeScrollOffset'] is! num) {
      throw const YouTubePublicCatalogueItemCodecException();
    }
    late final VerifiedPrincipalBinding persistedBinding;
    try {
      persistedBinding = VerifiedPrincipalBinding.fromStorage(
        decoded['principalBinding'] as String,
      );
    } on FormatException {
      throw const YouTubePublicCatalogueItemCodecException();
    }
    if (!principalBinding.matches(persistedBinding)) {
      throw const YouTubePublicCatalogueItemCodecException();
    }
    final origin = switch (decoded['origin']) {
      'home' => YouTubePublicWatchOrigin.home,
      'search' => YouTubePublicWatchOrigin.search,
      _ => throw const YouTubePublicCatalogueItemCodecException(),
    };
    final snapshot = YouTubePublicWatchSnapshot(
      selectedVideo: _itemCodec.decode(decoded['selectedVideo']),
      origin: origin,
      searchOriginVideo: decoded['searchOriginVideo'] == null
          ? null
          : _itemCodec.decode(decoded['searchOriginVideo']),
      watchScrollOffset: (decoded['watchScrollOffset'] as num).toDouble(),
      homeScrollOffset: (decoded['homeScrollOffset'] as num).toDouble(),
      capturedAtUtc: _parseUtcDate(decoded['capturedAtUtc']),
    );
    _validate(snapshot, persisted: true);
    return snapshot;
  }

  void _validate(
    YouTubePublicWatchSnapshot snapshot, {
    bool persisted = false,
  }) {
    void invalid() {
      if (persisted) throw const YouTubePublicCatalogueItemCodecException();
      throw const YouTubePublicWatchPersistenceException('invalid_input');
    }

    try {
      _itemCodec.validate(snapshot.selectedVideo);
      final searchOriginVideo = snapshot.searchOriginVideo;
      if (searchOriginVideo != null) _itemCodec.validate(searchOriginVideo);
    } on YouTubePublicCatalogueItemCodecException {
      invalid();
    }
    if ((snapshot.origin == YouTubePublicWatchOrigin.home &&
            snapshot.searchOriginVideo != null) ||
        !snapshot.capturedAtUtc.isUtc ||
        snapshot.capturedAtUtc.isAfter(_now().toUtc()) ||
        !_validOffset(snapshot.watchScrollOffset) ||
        !_validOffset(snapshot.homeScrollOffset)) {
      invalid();
    }
  }

  static bool _validOffset(double value) =>
      value.isFinite && value >= 0 && value <= _maximumScrollOffset;

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
      throw const YouTubePublicWatchPersistenceException('write_failed');
    }
    if (!succeeded) {
      throw const YouTubePublicWatchPersistenceException('write_failed');
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
      throw const YouTubePublicWatchPersistenceException('remove_failed');
    }
    if (!succeeded) {
      throw const YouTubePublicWatchPersistenceException('remove_failed');
    }
  }

  static DateTime _parseUtcDate(Object? value) {
    if (value is! String || !value.endsWith('Z')) {
      throw const YouTubePublicCatalogueItemCodecException();
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null || !parsed.isUtc || parsed.toIso8601String() != value) {
      throw const YouTubePublicCatalogueItemCodecException();
    }
    return parsed;
  }
}

final class YouTubePublicWatchStateCache {
  YouTubePublicWatchStateCache({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  YouTubePublicWatchStateRepository? _repository;
  YouTubePublicWatchSnapshot? _snapshot;
  Future<void> _mutationTail = Future<void>.value();
  Timer? _scrollWriteTimer;
  int _userGeneration = 0;
  int _principalBindingEpoch = 0;
  int _bindingBaselineUserGeneration = 0;

  YouTubePublicWatchSnapshot? get snapshot => _snapshot;

  int beginPrincipalBindingAttempt() {
    _principalBindingEpoch += 1;
    _bindingBaselineUserGeneration = _userGeneration;
    _scrollWriteTimer?.cancel();
    _scrollWriteTimer = null;
    _repository = null;
    _snapshot = null;
    return _principalBindingEpoch;
  }

  Future<YouTubePublicWatchFreshness?> configureDurability(
    YouTubePublicWatchStateRepository repository, {
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
    late final YouTubePublicWatchRead read;
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
    _snapshot = read.freshness == YouTubePublicWatchFreshness.fresh
        ? read.snapshot
        : null;
    return read.freshness;
  }

  void replace({
    required YouTubePublicCatalogueItem selectedVideo,
    required YouTubePublicWatchOrigin origin,
    YouTubePublicCatalogueItem? searchOriginVideo,
    double watchScrollOffset = 0,
    double homeScrollOffset = 0,
  }) {
    _userGeneration += 1;
    _scrollWriteTimer?.cancel();
    _scrollWriteTimer = null;
    final next = YouTubePublicWatchSnapshot(
      selectedVideo: selectedVideo,
      origin: origin,
      searchOriginVideo: searchOriginVideo,
      watchScrollOffset: watchScrollOffset,
      homeScrollOffset: homeScrollOffset,
      capturedAtUtc: _now().toUtc(),
    );
    _snapshot = next;
    _write(next);
  }

  void updateWatchScrollOffset(double offset) {
    final current = _snapshot;
    if (current == null || !offset.isFinite || offset < 0) return;
    _userGeneration += 1;
    final next = current.copyWith(watchScrollOffset: offset);
    _snapshot = next;
    _scrollWriteTimer?.cancel();
    _scrollWriteTimer = Timer(const Duration(milliseconds: 250), () {
      _scrollWriteTimer = null;
      if (identical(_snapshot, next)) _write(next);
    });
  }

  Future<void> clear({bool detachRepository = false}) {
    _userGeneration += 1;
    if (detachRepository) _principalBindingEpoch += 1;
    _scrollWriteTimer?.cancel();
    _scrollWriteTimer = null;
    _snapshot = null;
    final repository = _repository;
    if (detachRepository) _repository = null;
    if (repository == null) return Future<void>.value();
    _observeClear(repository);
    return _mutationTail;
  }

  Future<void> settleDurableWrites() {
    final pending = _scrollWriteTimer;
    if (pending != null) {
      pending.cancel();
      _scrollWriteTimer = null;
      final current = _snapshot;
      if (current != null) _write(current);
    }
    return _mutationTail;
  }

  void _observeClear(YouTubePublicWatchStateRepository repository) {
    late final Future<void> mutation;
    try {
      mutation = repository.clear();
    } on Object {
      return;
    }
    _observe(mutation);
  }

  void _write(YouTubePublicWatchSnapshot snapshot) {
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

final youtubePublicWatchState = YouTubePublicWatchStateCache();
