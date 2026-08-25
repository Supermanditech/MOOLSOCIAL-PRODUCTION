import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum YouTubePublicCatalogueKind { videos, shorts }

enum YouTubeCatalogueFreshness { fresh, stale, expired, missing, invalidated }

final class YouTubePublicCatalogueItem {
  YouTubePublicCatalogueItem({
    required this.videoId,
    required this.title,
    required this.channelId,
    required this.channelTitle,
    required this.description,
    required this.thumbnailUrl,
    required this.publishedAt,
    required this.duration,
    required this.captionAvailable,
    required this.viewCount,
    required this.likeCount,
    required this.commentCount,
    required this.embeddable,
    required this.hasKnownDeviceRegionExclusion,
    required List<String> hashtags,
    this.channelDescription,
    this.channelThumbnailUrl,
    this.subscriberCount,
    this.channelVideoCount,
    this.channelViewCount,
  }) : hashtags = List<String>.unmodifiable(hashtags);

  final String videoId;
  final String title;
  final String channelId;
  final String channelTitle;
  final String description;
  final Uri thumbnailUrl;
  final DateTime publishedAt;
  final String? duration;
  final bool? captionAvailable;
  final String? viewCount;
  final String? likeCount;
  final String? commentCount;
  final bool embeddable;
  final bool hasKnownDeviceRegionExclusion;
  final List<String> hashtags;
  final String? channelDescription;
  final Uri? channelThumbnailUrl;
  final String? subscriberCount;
  final String? channelVideoCount;
  final String? channelViewCount;
}

final class YouTubePublicCatalogueSnapshot {
  YouTubePublicCatalogueSnapshot({
    required this.kind,
    required DateTime capturedAtUtc,
    required List<YouTubePublicCatalogueItem> items,
  }) : capturedAtUtc = capturedAtUtc.toUtc(),
       items = List<YouTubePublicCatalogueItem>.unmodifiable(items);

  final YouTubePublicCatalogueKind kind;
  final DateTime capturedAtUtc;
  final List<YouTubePublicCatalogueItem> items;
}

final class YouTubePublicCatalogueRead {
  const YouTubePublicCatalogueRead({required this.freshness, this.snapshot});

  final YouTubeCatalogueFreshness freshness;
  final YouTubePublicCatalogueSnapshot? snapshot;
}

abstract interface class YouTubePublicCatalogueRepository {
  Future<YouTubePublicCatalogueRead> read(YouTubePublicCatalogueKind kind);

  Future<void> replace(
    YouTubePublicCatalogueKind kind,
    List<YouTubePublicCatalogueItem> items,
  );

  Future<void> clear(YouTubePublicCatalogueKind kind);

  Future<void> clearAll();
}

abstract interface class YouTubePublicCatalogueKeyValueStore {
  Future<String?> readString(String key);

  Future<bool> writeString(String key, String value);

  Future<bool> remove(String key);
}

final class SharedPreferencesAsyncYouTubePublicCatalogueStore
    implements YouTubePublicCatalogueKeyValueStore {
  const SharedPreferencesAsyncYouTubePublicCatalogueStore(this._preferences);

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> readString(String key) => _preferences.getString(key);

  @override
  Future<bool> writeString(String key, String value) async {
    await _preferences.setString(key, value);
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    await _preferences.remove(key);
    return true;
  }
}

final class YouTubePublicCataloguePersistenceException implements Exception {
  const YouTubePublicCataloguePersistenceException(this.code);

  final String code;

  @override
  String toString() => 'YouTube public catalogue persistence failed ($code).';
}

final class DurableYouTubePublicCatalogueRepository
    implements YouTubePublicCatalogueRepository {
  DurableYouTubePublicCatalogueRepository({
    required YouTubePublicCatalogueKeyValueStore persistence,
    this.freshTimeToLive = const Duration(minutes: 5),
    this.maximumAge = const Duration(hours: 24),
    this.regionCode = 'IN',
    DateTime Function()? now,
  }) : _store = persistence,
       _now = now ?? DateTime.now {
    if (freshTimeToLive.isNegative ||
        maximumAge < freshTimeToLive ||
        maximumAge > const Duration(hours: 24) ||
        regionCode.isEmpty ||
        !RegExp(r'^[A-Z]{2}$').hasMatch(regionCode)) {
      throw ArgumentError('Invalid catalogue repository configuration.');
    }
  }

  static const videosStorageKey =
      'moolsocial.youtube_public_catalogue.v1.videos';
  static const shortsStorageKey =
      'moolsocial.youtube_public_catalogue.v1.shorts';
  static const _schema = 'moolsocial.youtube_public_catalogue';
  static const _version = 1;
  static const _maximumItems = 20;
  static const _maximumEnvelopeBytes = 512 * 1024;

  static const _envelopeFields = <String>{
    'schema',
    'version',
    'kind',
    'regionCode',
    'capturedAtUtc',
    'items',
  };
  static const _itemFields = <String>{
    'videoId',
    'title',
    'channelId',
    'channelTitle',
    'description',
    'thumbnailUrl',
    'publishedAt',
    'duration',
    'captionAvailable',
    'viewCount',
    'likeCount',
    'commentCount',
    'embeddable',
    'hasKnownDeviceRegionExclusion',
    'hashtags',
    'channelDescription',
    'channelThumbnailUrl',
    'subscriberCount',
    'channelVideoCount',
    'channelViewCount',
  };

  final YouTubePublicCatalogueKeyValueStore _store;
  final DateTime Function() _now;
  final Duration freshTimeToLive;
  final Duration maximumAge;
  final String regionCode;
  static Future<void> _globalTail = Future<void>.value();

  @override
  Future<YouTubePublicCatalogueRead> read(YouTubePublicCatalogueKind kind) =>
      _enqueue(() => _readQueued(kind));

  @override
  Future<void> replace(
    YouTubePublicCatalogueKind kind,
    List<YouTubePublicCatalogueItem> items,
  ) async {
    final copiedItems = items.map(_defensiveCopy).toList(growable: false);
    final capturedAtUtc = _now().toUtc();
    final envelope = _encodeEnvelope(
      YouTubePublicCatalogueSnapshot(
        kind: kind,
        capturedAtUtc: capturedAtUtc,
        items: copiedItems,
      ),
    );

    await _enqueue(() async {
      bool succeeded;
      try {
        succeeded = await _store.writeString(_keyFor(kind), envelope);
      } catch (_) {
        throw const YouTubePublicCataloguePersistenceException('write_failed');
      }
      if (!succeeded) {
        throw const YouTubePublicCataloguePersistenceException('write_failed');
      }
    });
  }

  @override
  Future<void> clear(YouTubePublicCatalogueKind kind) =>
      _enqueue(() => _removeRequired(_keyFor(kind)));

  @override
  Future<void> clearAll() => _enqueue(() async {
    await _removeRequired(videosStorageKey);
    await _removeRequired(shortsStorageKey);
  });

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final result = _globalTail.then((_) => operation());
    _globalTail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  Future<YouTubePublicCatalogueRead> _readQueued(
    YouTubePublicCatalogueKind kind,
  ) async {
    final key = _keyFor(kind);
    late final String? raw;
    try {
      raw = await _store.readString(key);
    } catch (_) {
      throw const YouTubePublicCataloguePersistenceException('read_failed');
    }
    if (raw == null) {
      return const YouTubePublicCatalogueRead(
        freshness: YouTubeCatalogueFreshness.missing,
      );
    }

    late final YouTubePublicCatalogueSnapshot snapshot;
    try {
      snapshot = _decodeEnvelope(raw, expectedKind: kind);
    } on _InvalidCatalogueData {
      await _removeRequired(key);
      return const YouTubePublicCatalogueRead(
        freshness: YouTubeCatalogueFreshness.invalidated,
      );
    }

    final age = _now().toUtc().difference(snapshot.capturedAtUtc);
    if (age.isNegative) {
      await _removeRequired(key);
      return const YouTubePublicCatalogueRead(
        freshness: YouTubeCatalogueFreshness.invalidated,
      );
    }
    if (age <= freshTimeToLive) {
      return YouTubePublicCatalogueRead(
        freshness: YouTubeCatalogueFreshness.fresh,
        snapshot: snapshot,
      );
    }
    if (age <= maximumAge) {
      return YouTubePublicCatalogueRead(
        freshness: YouTubeCatalogueFreshness.stale,
        snapshot: snapshot,
      );
    }

    await _removeRequired(key);
    return const YouTubePublicCatalogueRead(
      freshness: YouTubeCatalogueFreshness.expired,
    );
  }

  String _encodeEnvelope(YouTubePublicCatalogueSnapshot snapshot) {
    _validateSnapshot(snapshot);
    final raw = jsonEncode(<String, Object?>{
      'schema': _schema,
      'version': _version,
      'kind': snapshot.kind.name,
      'regionCode': regionCode,
      'capturedAtUtc': snapshot.capturedAtUtc.toIso8601String(),
      'items': snapshot.items.map(_encodeItem).toList(growable: false),
    });
    if (utf8.encode(raw).length > _maximumEnvelopeBytes) {
      throw const YouTubePublicCataloguePersistenceException('invalid_input');
    }
    return raw;
  }

  YouTubePublicCatalogueSnapshot _decodeEnvelope(
    String raw, {
    required YouTubePublicCatalogueKind expectedKind,
  }) {
    if (utf8.encode(raw).length > _maximumEnvelopeBytes) {
      throw const _InvalidCatalogueData();
    }
    late final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const _InvalidCatalogueData();
    }
    if (decoded is! Map<String, dynamic> ||
        !_hasExactFields(decoded, _envelopeFields) ||
        decoded['schema'] != _schema ||
        decoded['version'] is! int ||
        decoded['version'] != _version ||
        decoded['kind'] != expectedKind.name ||
        decoded['regionCode'] != regionCode) {
      throw const _InvalidCatalogueData();
    }
    final capturedAtUtc = _parseUtcDate(decoded['capturedAtUtc']);
    final rawItems = decoded['items'];
    if (rawItems is! List || rawItems.length > _maximumItems) {
      throw const _InvalidCatalogueData();
    }
    final items = <YouTubePublicCatalogueItem>[];
    final seenVideoIds = <String>{};
    for (final rawItem in rawItems) {
      if (rawItem is! Map<String, dynamic>) {
        throw const _InvalidCatalogueData();
      }
      final item = _decodeItem(rawItem);
      if (!seenVideoIds.add(item.videoId)) {
        throw const _InvalidCatalogueData();
      }
      items.add(item);
    }
    final snapshot = YouTubePublicCatalogueSnapshot(
      kind: expectedKind,
      capturedAtUtc: capturedAtUtc,
      items: items,
    );
    _validateSnapshot(snapshot, persistedData: true);
    return snapshot;
  }

  Map<String, Object?> _encodeItem(YouTubePublicCatalogueItem item) =>
      <String, Object?>{
        'videoId': item.videoId,
        'title': item.title,
        'channelId': item.channelId,
        'channelTitle': item.channelTitle,
        'description': item.description,
        'thumbnailUrl': item.thumbnailUrl.toString(),
        'publishedAt': item.publishedAt.toUtc().toIso8601String(),
        'duration': item.duration,
        'captionAvailable': item.captionAvailable,
        'viewCount': item.viewCount,
        'likeCount': item.likeCount,
        'commentCount': item.commentCount,
        'embeddable': item.embeddable,
        'hasKnownDeviceRegionExclusion': item.hasKnownDeviceRegionExclusion,
        'hashtags': item.hashtags,
        'channelDescription': item.channelDescription,
        'channelThumbnailUrl': item.channelThumbnailUrl?.toString(),
        'subscriberCount': item.subscriberCount,
        'channelVideoCount': item.channelVideoCount,
        'channelViewCount': item.channelViewCount,
      };

  YouTubePublicCatalogueItem _decodeItem(Map<String, dynamic> raw) {
    if (!_hasExactFields(raw, _itemFields)) {
      throw const _InvalidCatalogueData();
    }
    final rawHashtags = raw['hashtags'];
    if (rawHashtags is! List || rawHashtags.any((value) => value is! String)) {
      throw const _InvalidCatalogueData();
    }
    return YouTubePublicCatalogueItem(
      videoId: _requiredString(raw['videoId']),
      title: _requiredString(raw['title'], allowEmpty: true),
      channelId: _requiredString(raw['channelId']),
      channelTitle: _requiredString(raw['channelTitle'], allowEmpty: true),
      description: _requiredString(raw['description'], allowEmpty: true),
      thumbnailUrl: _parseHttpsUri(raw['thumbnailUrl']),
      publishedAt: _parseUtcDate(raw['publishedAt']),
      duration: _nullableString(raw['duration']),
      captionAvailable: _nullableBool(raw['captionAvailable']),
      viewCount: _nullableString(raw['viewCount']),
      likeCount: _nullableString(raw['likeCount']),
      commentCount: _nullableString(raw['commentCount']),
      embeddable: _requiredBool(raw['embeddable']),
      hasKnownDeviceRegionExclusion: _requiredBool(
        raw['hasKnownDeviceRegionExclusion'],
      ),
      hashtags: rawHashtags.cast<String>(),
      channelDescription: _nullableString(raw['channelDescription']),
      channelThumbnailUrl: _nullableHttpsUri(raw['channelThumbnailUrl']),
      subscriberCount: _nullableString(raw['subscriberCount']),
      channelVideoCount: _nullableString(raw['channelVideoCount']),
      channelViewCount: _nullableString(raw['channelViewCount']),
    );
  }

  void _validateSnapshot(
    YouTubePublicCatalogueSnapshot snapshot, {
    bool persistedData = false,
  }) {
    void invalid() {
      if (persistedData) throw const _InvalidCatalogueData();
      throw const YouTubePublicCataloguePersistenceException('invalid_input');
    }

    if (!snapshot.capturedAtUtc.isUtc ||
        snapshot.items.length > _maximumItems) {
      invalid();
    }
    final seenVideoIds = <String>{};
    for (final item in snapshot.items) {
      if (!_validString(item.videoId, 128) ||
          !seenVideoIds.add(item.videoId) ||
          !_validString(item.title, 512, allowEmpty: true) ||
          !_validString(item.channelId, 128) ||
          !_validString(item.channelTitle, 512, allowEmpty: true) ||
          !_validString(item.description, 10000, allowEmpty: true) ||
          !_validHttpsUri(item.thumbnailUrl) ||
          !item.publishedAt.isUtc ||
          !_validNullableString(item.duration, 64) ||
          !_validCount(item.viewCount) ||
          !_validCount(item.likeCount) ||
          !_validCount(item.commentCount) ||
          !item.embeddable ||
          item.hasKnownDeviceRegionExclusion ||
          item.hashtags.length > 3 ||
          item.hashtags.any((tag) => !_validString(tag, 128)) ||
          !_validNullableString(
            item.channelDescription,
            10000,
            allowEmpty: true,
          ) ||
          (item.channelThumbnailUrl != null &&
              !_validHttpsUri(item.channelThumbnailUrl!)) ||
          !_validCount(item.subscriberCount) ||
          !_validCount(item.channelVideoCount) ||
          !_validCount(item.channelViewCount)) {
        invalid();
      }
    }
  }

  YouTubePublicCatalogueItem _defensiveCopy(YouTubePublicCatalogueItem item) =>
      YouTubePublicCatalogueItem(
        videoId: item.videoId,
        title: item.title,
        channelId: item.channelId,
        channelTitle: item.channelTitle,
        description: item.description,
        thumbnailUrl: item.thumbnailUrl,
        publishedAt: item.publishedAt.toUtc(),
        duration: item.duration,
        captionAvailable: item.captionAvailable,
        viewCount: item.viewCount,
        likeCount: item.likeCount,
        commentCount: item.commentCount,
        embeddable: item.embeddable,
        hasKnownDeviceRegionExclusion: item.hasKnownDeviceRegionExclusion,
        hashtags: item.hashtags,
        channelDescription: item.channelDescription,
        channelThumbnailUrl: item.channelThumbnailUrl,
        subscriberCount: item.subscriberCount,
        channelVideoCount: item.channelVideoCount,
        channelViewCount: item.channelViewCount,
      );

  Future<void> _removeRequired(String key) async {
    late final bool succeeded;
    try {
      succeeded = await _store.remove(key);
    } catch (_) {
      throw const YouTubePublicCataloguePersistenceException('remove_failed');
    }
    if (!succeeded) {
      throw const YouTubePublicCataloguePersistenceException('remove_failed');
    }
  }

  String _keyFor(YouTubePublicCatalogueKind kind) => switch (kind) {
    YouTubePublicCatalogueKind.videos => videosStorageKey,
    YouTubePublicCatalogueKind.shorts => shortsStorageKey,
  };

  static bool _hasExactFields(Map<String, dynamic> raw, Set<String> expected) =>
      raw.length == expected.length && raw.keys.toSet().containsAll(expected);

  static String _requiredString(Object? value, {bool allowEmpty = false}) {
    if (value is! String || (!allowEmpty && value.isEmpty)) {
      throw const _InvalidCatalogueData();
    }
    return value;
  }

  static String? _nullableString(Object? value) {
    if (value == null) return null;
    if (value is! String) throw const _InvalidCatalogueData();
    return value;
  }

  static bool _requiredBool(Object? value) {
    if (value is! bool) throw const _InvalidCatalogueData();
    return value;
  }

  static bool? _nullableBool(Object? value) {
    if (value == null) return null;
    if (value is! bool) throw const _InvalidCatalogueData();
    return value;
  }

  static DateTime _parseUtcDate(Object? value) {
    if (value is! String || !value.endsWith('Z')) {
      throw const _InvalidCatalogueData();
    }
    late final DateTime parsed;
    try {
      parsed = DateTime.parse(value);
    } on FormatException {
      throw const _InvalidCatalogueData();
    }
    if (!parsed.isUtc || parsed.toIso8601String() != value) {
      throw const _InvalidCatalogueData();
    }
    return parsed;
  }

  static Uri _parseHttpsUri(Object? value) {
    if (value is! String) throw const _InvalidCatalogueData();
    final uri = Uri.tryParse(value);
    if (uri == null || !_validHttpsUri(uri)) {
      throw const _InvalidCatalogueData();
    }
    return uri;
  }

  static Uri? _nullableHttpsUri(Object? value) {
    if (value == null) return null;
    return _parseHttpsUri(value);
  }

  static bool _validHttpsUri(Uri uri) =>
      uri.scheme == 'https' &&
      uri.host.isNotEmpty &&
      uri.userInfo.isEmpty &&
      uri.toString().length <= 2048;

  static bool _validString(
    String value,
    int maximumLength, {
    bool allowEmpty = false,
  }) => (allowEmpty || value.isNotEmpty) && value.length <= maximumLength;

  static bool _validNullableString(
    String? value,
    int maximumLength, {
    bool allowEmpty = false,
  }) =>
      value == null ||
      _validString(value, maximumLength, allowEmpty: allowEmpty);

  static bool _validCount(String? value) =>
      value == null ||
      (value.isNotEmpty &&
          value.length <= 32 &&
          RegExp(r'^\d+$').hasMatch(value));
}

final class _InvalidCatalogueData implements Exception {
  const _InvalidCatalogueData();
}
