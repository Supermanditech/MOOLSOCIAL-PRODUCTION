import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../journey01/journey_services.dart';
import 'youtube_public_catalogue_repository.dart';

enum YouTubePublicSearchFreshness {
  fresh,
  stale,
  expired,
  missing,
  invalidated,
}

bool youtubePublicSearchHydrationIsDegraded(
  YouTubePublicSearchFreshness? freshness,
) =>
    freshness != YouTubePublicSearchFreshness.fresh &&
    freshness != YouTubePublicSearchFreshness.missing;

final class YouTubePublicSearchSnapshot {
  YouTubePublicSearchSnapshot({
    required this.submittedQuery,
    required List<YouTubePublicCatalogueItem> results,
    required this.searchSurfaceOpen,
    required this.resultsScrollOffset,
    required DateTime capturedAtUtc,
  }) : results = List<YouTubePublicCatalogueItem>.unmodifiable(results),
       capturedAtUtc = capturedAtUtc.toUtc();

  final String submittedQuery;
  final List<YouTubePublicCatalogueItem> results;
  final bool searchSurfaceOpen;
  final double resultsScrollOffset;
  final DateTime capturedAtUtc;

  YouTubePublicSearchSnapshot copyWith({double? resultsScrollOffset}) =>
      YouTubePublicSearchSnapshot(
        submittedQuery: submittedQuery,
        results: results,
        searchSurfaceOpen: searchSurfaceOpen,
        resultsScrollOffset: resultsScrollOffset ?? this.resultsScrollOffset,
        capturedAtUtc: capturedAtUtc,
      );
}

final class YouTubePublicSearchRead {
  const YouTubePublicSearchRead({required this.freshness, this.snapshot});

  final YouTubePublicSearchFreshness freshness;
  final YouTubePublicSearchSnapshot? snapshot;
}

abstract interface class YouTubePublicSearchStateRepository {
  Future<YouTubePublicSearchRead> read();

  Future<void> write(YouTubePublicSearchSnapshot snapshot);

  Future<void> clear();
}

final class SecureStorageYouTubePublicSearchKeyValueStore
    implements YouTubePublicCatalogueKeyValueStore {
  SecureStorageYouTubePublicSearchKeyValueStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(
              storageNamespace: 'moolsocial_youtube_public_search',
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

final class YouTubePublicSearchPersistenceException implements Exception {
  const YouTubePublicSearchPersistenceException(this.code);

  final String code;

  @override
  String toString() => 'YouTube public Search persistence failed ($code).';
}

final class DurableYouTubePublicSearchStateRepository
    implements YouTubePublicSearchStateRepository {
  DurableYouTubePublicSearchStateRepository({
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
      throw ArgumentError('Invalid Search repository configuration.');
    }
  }

  static const storageKey = 'youtube_public_search_state_v1';
  static const invalidationKey = 'youtube_public_search_state_invalidated_v1';
  static const _schema = 'moolsocial.youtube_public_search_state';
  static const _version = 1;
  static const _maximumResults = 20;
  static const _maximumQueryLength = 256;
  static const _maximumEnvelopeBytes = 512 * 1024;
  static const _maximumScrollOffset = 10000000.0;
  static const _fields = <String>{
    'schema',
    'version',
    'regionCode',
    'principalBinding',
    'capturedAtUtc',
    'submittedQuery',
    'searchSurfaceOpen',
    'resultsScrollOffset',
    'results',
  };
  static const _itemCodec = YouTubePublicCatalogueItemJsonCodec();
  static Future<void> _globalTail = Future<void>.value();

  static Future<void> invalidateUnbound(
    YouTubePublicCatalogueKeyValueStore persistence,
  ) async {
    late final bool tombstoned;
    try {
      tombstoned = await persistence.writeString(invalidationKey, '1');
    } on Object {
      throw const YouTubePublicSearchPersistenceException('write_failed');
    }
    if (!tombstoned) {
      throw const YouTubePublicSearchPersistenceException('write_failed');
    }
    late final bool removedState;
    try {
      removedState = await persistence.remove(storageKey);
    } on Object {
      throw const YouTubePublicSearchPersistenceException('remove_failed');
    }
    if (!removedState) {
      throw const YouTubePublicSearchPersistenceException('remove_failed');
    }
    late final bool removedTombstone;
    try {
      removedTombstone = await persistence.remove(invalidationKey);
    } on Object {
      throw const YouTubePublicSearchPersistenceException('remove_failed');
    }
    if (!removedTombstone) {
      throw const YouTubePublicSearchPersistenceException('remove_failed');
    }
  }

  final YouTubePublicCatalogueKeyValueStore _store;
  final DateTime Function() _now;
  final Duration freshTimeToLive;
  final Duration maximumAge;
  final String regionCode;
  final VerifiedPrincipalBinding principalBinding;

  @override
  Future<YouTubePublicSearchRead> read() => _enqueue(_readQueued);

  @override
  Future<void> write(YouTubePublicSearchSnapshot snapshot) async {
    late final String encoded;
    try {
      encoded = _encode(snapshot);
    } on YouTubePublicSearchPersistenceException {
      rethrow;
    } on Object {
      throw const YouTubePublicSearchPersistenceException('invalid_input');
    }
    await _enqueue(() async {
      late final bool succeeded;
      try {
        succeeded = await _store.writeString(storageKey, encoded);
      } on Object {
        throw const YouTubePublicSearchPersistenceException('write_failed');
      }
      if (!succeeded) {
        throw const YouTubePublicSearchPersistenceException('write_failed');
      }
    });
  }

  @override
  Future<void> clear() => _enqueue(_clearQueued);

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final result = _globalTail.then((_) => operation());
    _globalTail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  Future<YouTubePublicSearchRead> _readQueued() async {
    late final String? invalidated;
    try {
      invalidated = await _store.readString(invalidationKey);
    } on Object {
      throw const YouTubePublicSearchPersistenceException('read_failed');
    }
    if (invalidated != null) {
      await _removeRequired(storageKey);
      await _removeRequired(invalidationKey);
      return const YouTubePublicSearchRead(
        freshness: YouTubePublicSearchFreshness.invalidated,
      );
    }
    late final String? raw;
    try {
      raw = await _store.readString(storageKey);
    } on Object {
      throw const YouTubePublicSearchPersistenceException('read_failed');
    }
    if (raw == null) {
      return const YouTubePublicSearchRead(
        freshness: YouTubePublicSearchFreshness.missing,
      );
    }
    late final YouTubePublicSearchSnapshot snapshot;
    try {
      snapshot = _decode(raw);
    } on Object {
      await _clearQueued();
      return const YouTubePublicSearchRead(
        freshness: YouTubePublicSearchFreshness.invalidated,
      );
    }
    final age = _now().toUtc().difference(snapshot.capturedAtUtc);
    if (age.isNegative) {
      await _clearQueued();
      return const YouTubePublicSearchRead(
        freshness: YouTubePublicSearchFreshness.invalidated,
      );
    }
    if (age <= freshTimeToLive) {
      return YouTubePublicSearchRead(
        freshness: YouTubePublicSearchFreshness.fresh,
        snapshot: snapshot,
      );
    }
    if (age <= maximumAge) {
      return YouTubePublicSearchRead(
        freshness: YouTubePublicSearchFreshness.stale,
        snapshot: snapshot,
      );
    }
    await _clearQueued();
    return const YouTubePublicSearchRead(
      freshness: YouTubePublicSearchFreshness.expired,
    );
  }

  String _encode(YouTubePublicSearchSnapshot snapshot) {
    _validate(snapshot);
    final raw = jsonEncode(<String, Object?>{
      'schema': _schema,
      'version': _version,
      'regionCode': regionCode,
      'principalBinding': principalBinding.storageValue,
      'capturedAtUtc': snapshot.capturedAtUtc.toIso8601String(),
      'submittedQuery': snapshot.submittedQuery,
      'searchSurfaceOpen': snapshot.searchSurfaceOpen,
      'resultsScrollOffset': snapshot.resultsScrollOffset,
      'results': snapshot.results
          .map(_itemCodec.encode)
          .toList(growable: false),
    });
    if (utf8.encode(raw).length > _maximumEnvelopeBytes) {
      throw const YouTubePublicSearchPersistenceException('invalid_input');
    }
    return raw;
  }

  YouTubePublicSearchSnapshot _decode(String raw) {
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
        decoded['submittedQuery'] is! String ||
        decoded['searchSurfaceOpen'] is! bool ||
        decoded['resultsScrollOffset'] is! num ||
        decoded['results'] is! List) {
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
    final rawResults = decoded['results'] as List;
    final snapshot = YouTubePublicSearchSnapshot(
      submittedQuery: decoded['submittedQuery'] as String,
      results: rawResults.map(_itemCodec.decode).toList(growable: false),
      searchSurfaceOpen: decoded['searchSurfaceOpen'] as bool,
      resultsScrollOffset: (decoded['resultsScrollOffset'] as num).toDouble(),
      capturedAtUtc: _parseUtcDate(decoded['capturedAtUtc']),
    );
    _validate(snapshot, persisted: true);
    return snapshot;
  }

  void _validate(
    YouTubePublicSearchSnapshot snapshot, {
    bool persisted = false,
  }) {
    void invalid() {
      if (persisted) throw const YouTubePublicCatalogueItemCodecException();
      throw const YouTubePublicSearchPersistenceException('invalid_input');
    }

    final query = snapshot.submittedQuery;
    final offset = snapshot.resultsScrollOffset;
    if (query.isEmpty ||
        query != query.trim() ||
        query.length > _maximumQueryLength ||
        !snapshot.searchSurfaceOpen ||
        !snapshot.capturedAtUtc.isUtc ||
        snapshot.capturedAtUtc.isAfter(_now().toUtc()) ||
        !offset.isFinite ||
        offset < 0 ||
        offset > _maximumScrollOffset ||
        snapshot.results.length > _maximumResults) {
      invalid();
    }
    final ids = <String>{};
    for (final item in snapshot.results) {
      try {
        _itemCodec.validate(item);
      } on YouTubePublicCatalogueItemCodecException {
        invalid();
      }
      if (!ids.add(item.videoId)) invalid();
    }
  }

  Future<void> _clearQueued() async {
    await _writeRequired(invalidationKey, '1');
    await _removeRequired(storageKey);
    await _removeRequired(invalidationKey);
  }

  Future<void> _writeRequired(String key, String value) async {
    late final bool succeeded;
    try {
      succeeded = await _store.writeString(key, value);
    } on Object {
      throw const YouTubePublicSearchPersistenceException('write_failed');
    }
    if (!succeeded) {
      throw const YouTubePublicSearchPersistenceException('write_failed');
    }
  }

  Future<void> _removeRequired(String key) async {
    late final bool succeeded;
    try {
      succeeded = await _store.remove(key);
    } on Object {
      throw const YouTubePublicSearchPersistenceException('remove_failed');
    }
    if (!succeeded) {
      throw const YouTubePublicSearchPersistenceException('remove_failed');
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

final class YouTubePublicSearchStateCache {
  YouTubePublicSearchStateCache({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  YouTubePublicSearchStateRepository? _repository;
  YouTubePublicSearchSnapshot? _snapshot;
  Future<void> _mutationTail = Future<void>.value();
  Timer? _scrollWriteTimer;
  int _generation = 0;
  int _principalBindingEpoch = 0;
  int _bindingBaselineGeneration = 0;

  YouTubePublicSearchSnapshot? get snapshot => _snapshot;

  int beginPrincipalBindingAttempt() {
    _principalBindingEpoch += 1;
    _generation += 1;
    _bindingBaselineGeneration = _generation;
    _scrollWriteTimer?.cancel();
    _scrollWriteTimer = null;
    _repository = null;
    _snapshot = null;
    return _principalBindingEpoch;
  }

  Future<YouTubePublicSearchFreshness?> configureDurability(
    YouTubePublicSearchStateRepository repository, {
    int? bindingAttempt,
  }) async {
    if (bindingAttempt != null && bindingAttempt != _principalBindingEpoch) {
      return null;
    }
    _repository = repository;
    final generation = bindingAttempt == null ? ++_generation : _generation;
    final hadLocalMutationBeforeRead =
        bindingAttempt != null && generation != _bindingBaselineGeneration;
    late final YouTubePublicSearchRead read;
    try {
      read = await repository.read();
    } on Object {
      return null;
    }
    if ((bindingAttempt != null && bindingAttempt != _principalBindingEpoch) ||
        !identical(repository, _repository)) {
      return read.freshness;
    }
    if (hadLocalMutationBeforeRead || generation != _generation) {
      final current = _snapshot;
      if (current == null) {
        late final Future<void> mutation;
        try {
          mutation = repository.clear();
        } on Object {
          return null;
        }
        _observe(mutation);
      } else {
        _write(current);
      }
      await _mutationTail;
      return read.freshness;
    }
    _snapshot = read.freshness == YouTubePublicSearchFreshness.fresh
        ? read.snapshot
        : null;
    return read.freshness;
  }

  void replace({
    required String submittedQuery,
    required List<YouTubePublicCatalogueItem> results,
    double resultsScrollOffset = 0,
  }) {
    _generation += 1;
    _scrollWriteTimer?.cancel();
    final next = YouTubePublicSearchSnapshot(
      submittedQuery: submittedQuery,
      results: results,
      searchSurfaceOpen: true,
      resultsScrollOffset: resultsScrollOffset,
      capturedAtUtc: _now().toUtc(),
    );
    _snapshot = next;
    _write(next);
  }

  void updateScrollOffset(double offset) {
    final current = _snapshot;
    if (current == null || !offset.isFinite || offset < 0) return;
    final next = current.copyWith(resultsScrollOffset: offset);
    _snapshot = next;
    _scrollWriteTimer?.cancel();
    _scrollWriteTimer = Timer(const Duration(milliseconds: 250), () {
      _scrollWriteTimer = null;
      if (identical(_snapshot, next)) _write(next);
    });
  }

  Future<void> clear({bool detachRepository = false}) {
    _generation += 1;
    if (detachRepository) _principalBindingEpoch += 1;
    _scrollWriteTimer?.cancel();
    _scrollWriteTimer = null;
    _snapshot = null;
    final repository = _repository;
    if (detachRepository) _repository = null;
    if (repository == null) return Future<void>.value();
    late final Future<void> mutation;
    try {
      mutation = repository.clear();
    } on Object {
      return Future<void>.value();
    }
    _observe(mutation);
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

  void _write(YouTubePublicSearchSnapshot snapshot) {
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

final youtubePublicSearchState = YouTubePublicSearchStateCache();
