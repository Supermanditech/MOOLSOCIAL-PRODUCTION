import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../journey01/journey_services.dart';
import 'youtube_public_catalogue_repository.dart';

enum SocialCreateDraftFormat { post, carousel, reel }

enum SocialCreateDraftTool { none, image, imagePoll, quickPoll, quiz }

enum SocialCreateDraftMediaKind { image, video }

enum SocialCreateDraftFreshness { fresh, stale, expired, missing, invalidated }

final class SocialCreateDraftMediaReference {
  const SocialCreateDraftMediaReference({
    required this.id,
    required this.name,
    required this.kind,
    required this.isAsset,
    required this.byteLength,
    required this.sha256,
  });

  final String id;
  final String name;
  final SocialCreateDraftMediaKind kind;
  final bool isAsset;
  final int byteLength;
  final String sha256;
}

final class SocialCreateDraftQuote {
  const SocialCreateDraftQuote({
    required this.id,
    required this.authorName,
    required this.authorHandle,
    required this.body,
    this.mediaUrl,
  });

  final String id;
  final String authorName;
  final String authorHandle;
  final String body;
  final Uri? mediaUrl;
}

final class SocialCreateDraftSnapshot {
  SocialCreateDraftSnapshot({
    required this.initialized,
    required this.format,
    required this.tool,
    required this.body,
    required List<String> choices,
    required List<SocialCreateDraftMediaReference> media,
    required List<SocialCreateDraftMediaReference?> imagePollMedia,
    required this.correctChoice,
    required this.quote,
    required this.revision,
    required DateTime capturedAtUtc,
  }) : choices = List<String>.unmodifiable(choices),
       media = List<SocialCreateDraftMediaReference>.unmodifiable(media),
       imagePollMedia = List<SocialCreateDraftMediaReference?>.unmodifiable(
         imagePollMedia,
       ),
       capturedAtUtc = capturedAtUtc.toUtc();

  final bool initialized;
  final SocialCreateDraftFormat format;
  final SocialCreateDraftTool tool;
  final String body;
  final List<String> choices;
  final List<SocialCreateDraftMediaReference> media;
  final List<SocialCreateDraftMediaReference?> imagePollMedia;
  final int correctChoice;
  final SocialCreateDraftQuote? quote;
  final int revision;
  final DateTime capturedAtUtc;

  bool get hasMeaningfulContent =>
      body.trim().isNotEmpty ||
      choices.any((choice) => choice.trim().isNotEmpty) ||
      media.isNotEmpty ||
      imagePollMedia.any((item) => item != null) ||
      quote != null ||
      format != SocialCreateDraftFormat.post ||
      tool != SocialCreateDraftTool.none;
}

final class SocialCreateDraftRead {
  const SocialCreateDraftRead({required this.freshness, this.snapshot});

  final SocialCreateDraftFreshness freshness;
  final SocialCreateDraftSnapshot? snapshot;
}

abstract interface class SocialCreateDraftRepository {
  Future<SocialCreateDraftRead> read();
  Future<void> write(SocialCreateDraftSnapshot snapshot);
  Future<void> clear();
}

final class SecureStorageSocialCreateDraftKeyValueStore
    implements YouTubePublicCatalogueKeyValueStore {
  SecureStorageSocialCreateDraftKeyValueStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(
              storageNamespace: 'moolsocial_social_create_draft',
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

final class SocialCreateDraftPersistenceException implements Exception {
  const SocialCreateDraftPersistenceException(this.code);
  final String code;
  @override
  String toString() => 'Social Create draft persistence failed ($code).';
}

final class DurableSocialCreateDraftRepository
    implements SocialCreateDraftRepository {
  DurableSocialCreateDraftRepository({
    required YouTubePublicCatalogueKeyValueStore persistence,
    required this.principalBinding,
    this.freshTimeToLive = const Duration(days: 7),
    this.maximumAge = const Duration(days: 30),
    DateTime Function()? now,
  }) : _store = persistence,
       _now = now ?? DateTime.now {
    if (freshTimeToLive.isNegative ||
        maximumAge < freshTimeToLive ||
        maximumAge > const Duration(days: 30)) {
      throw ArgumentError('Invalid draft repository configuration.');
    }
  }

  static const storageKey = 'social_create_draft_v1';
  static const invalidationKey = 'social_create_draft_invalidated_v1';
  static const _schema = 'moolsocial.social_create_draft';
  static const _version = 1;
  static const _maximumEnvelopeBytes = 512 * 1024;
  static const _fields = <String>{
    'schema',
    'version',
    'principalBinding',
    'capturedAtUtc',
    'initialized',
    'format',
    'tool',
    'body',
    'choices',
    'media',
    'imagePollMedia',
    'correctChoice',
    'quote',
    'revision',
  };
  static const _mediaFields = <String>{
    'id',
    'name',
    'kind',
    'isAsset',
    'byteLength',
    'sha256',
  };
  static const _quoteFields = <String>{
    'id',
    'authorName',
    'authorHandle',
    'body',
    'mediaUrl',
  };
  static Future<void>? _globalTail;

  final YouTubePublicCatalogueKeyValueStore _store;
  final DateTime Function() _now;
  final VerifiedPrincipalBinding principalBinding;
  final Duration freshTimeToLive;
  final Duration maximumAge;

  static Future<void> invalidateUnbound(
    YouTubePublicCatalogueKeyValueStore store,
  ) => _enqueue(() async {
    await _writeRequired(store, invalidationKey, '1');
    await _removeRequired(store, storageKey);
    await _removeRequired(store, invalidationKey);
  });

  @override
  Future<SocialCreateDraftRead> read() => _enqueue(_readQueued);
  @override
  Future<void> write(SocialCreateDraftSnapshot snapshot) async {
    final encoded = _encode(snapshot);
    await _enqueue(() => _writeRequired(_store, storageKey, encoded));
  }

  @override
  Future<void> clear() => _enqueue(_clearQueued);

  static Future<T> _enqueue<T>(Future<T> Function() operation) {
    final prior = _globalTail;
    final result = prior == null
        ? Future<T>.sync(operation)
        : prior.then((_) => operation());
    final settled = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _globalTail = settled;
    return settled.then<T>((_) {
      if (identical(_globalTail, settled)) _globalTail = null;
      return result;
    });
  }

  Future<SocialCreateDraftRead> _readQueued() async {
    final invalidated = await _readRequired(_store, invalidationKey);
    if (invalidated != null) {
      await _removeRequired(_store, storageKey);
      await _removeRequired(_store, invalidationKey);
      return const SocialCreateDraftRead(
        freshness: SocialCreateDraftFreshness.invalidated,
      );
    }
    final raw = await _readRequired(_store, storageKey);
    if (raw == null) {
      return const SocialCreateDraftRead(
        freshness: SocialCreateDraftFreshness.missing,
      );
    }
    late final SocialCreateDraftSnapshot snapshot;
    try {
      snapshot = _decode(raw);
    } on Object {
      await _clearQueued();
      return const SocialCreateDraftRead(
        freshness: SocialCreateDraftFreshness.invalidated,
      );
    }
    final age = _now().toUtc().difference(snapshot.capturedAtUtc);
    if (age.isNegative) {
      await _clearQueued();
      return const SocialCreateDraftRead(
        freshness: SocialCreateDraftFreshness.invalidated,
      );
    }
    if (age <= freshTimeToLive) {
      return SocialCreateDraftRead(
        freshness: SocialCreateDraftFreshness.fresh,
        snapshot: snapshot,
      );
    }
    if (age <= maximumAge) {
      return SocialCreateDraftRead(
        freshness: SocialCreateDraftFreshness.stale,
        snapshot: snapshot,
      );
    }
    await _clearQueued();
    return const SocialCreateDraftRead(
      freshness: SocialCreateDraftFreshness.expired,
    );
  }

  String _encode(SocialCreateDraftSnapshot snapshot) {
    _validate(snapshot, persisted: false);
    final raw = jsonEncode(<String, Object?>{
      'schema': _schema,
      'version': _version,
      'principalBinding': principalBinding.storageValue,
      'capturedAtUtc': snapshot.capturedAtUtc.toIso8601String(),
      'initialized': snapshot.initialized,
      'format': snapshot.format.name,
      'tool': snapshot.tool.name,
      'body': snapshot.body,
      'choices': snapshot.choices,
      'media': snapshot.media.map(_encodeMedia).toList(growable: false),
      'imagePollMedia': snapshot.imagePollMedia
          .map((item) => item == null ? null : _encodeMedia(item))
          .toList(growable: false),
      'correctChoice': snapshot.correctChoice,
      'quote': snapshot.quote == null ? null : _encodeQuote(snapshot.quote!),
      'revision': snapshot.revision,
    });
    if (utf8.encode(raw).length > _maximumEnvelopeBytes) {
      throw const SocialCreateDraftPersistenceException('invalid_input');
    }
    return raw;
  }

  SocialCreateDraftSnapshot _decode(String raw) {
    if (utf8.encode(raw).length > _maximumEnvelopeBytes) {
      throw const FormatException();
    }
    final value = jsonDecode(raw);
    if (value is! Map<String, dynamic> ||
        value.length != _fields.length ||
        !value.keys.toSet().containsAll(_fields) ||
        value['schema'] != _schema ||
        value['version'] is! int ||
        value['version'] != _version ||
        value['principalBinding'] is! String ||
        value['initialized'] is! bool ||
        value['format'] is! String ||
        value['tool'] is! String ||
        value['body'] is! String ||
        value['choices'] is! List ||
        value['media'] is! List ||
        value['imagePollMedia'] is! List ||
        value['correctChoice'] is! int ||
        value['revision'] is! int) {
      throw const FormatException();
    }
    final binding = VerifiedPrincipalBinding.fromStorage(
      value['principalBinding'] as String,
    );
    if (!principalBinding.matches(binding)) {
      throw const FormatException();
    }
    final format = SocialCreateDraftFormat.values.byName(
      value['format'] as String,
    );
    final tool = SocialCreateDraftTool.values.byName(value['tool'] as String);
    final choices = (value['choices'] as List).cast<String>();
    final media = (value['media'] as List).map(_decodeMedia).toList();
    final poll = (value['imagePollMedia'] as List)
        .map((item) => item == null ? null : _decodeMedia(item))
        .toList();
    final snapshot = SocialCreateDraftSnapshot(
      initialized: value['initialized'] as bool,
      format: format,
      tool: tool,
      body: value['body'] as String,
      choices: choices,
      media: media,
      imagePollMedia: poll,
      correctChoice: value['correctChoice'] as int,
      quote: value['quote'] == null ? null : _decodeQuote(value['quote']),
      revision: value['revision'] as int,
      capturedAtUtc: _parseUtc(value['capturedAtUtc']),
    );
    _validate(snapshot, persisted: true);
    return snapshot;
  }

  Map<String, Object?> _encodeMedia(SocialCreateDraftMediaReference item) => {
    'id': item.id,
    'name': item.name,
    'kind': item.kind.name,
    'isAsset': item.isAsset,
    'byteLength': item.byteLength,
    'sha256': item.sha256,
  };
  SocialCreateDraftMediaReference _decodeMedia(Object? raw) {
    if (raw is! Map<String, dynamic> ||
        raw.length != _mediaFields.length ||
        !raw.keys.toSet().containsAll(_mediaFields)) {
      throw const FormatException();
    }
    return SocialCreateDraftMediaReference(
      id: raw['id'] as String,
      name: raw['name'] as String,
      kind: SocialCreateDraftMediaKind.values.byName(raw['kind'] as String),
      isAsset: raw['isAsset'] as bool,
      byteLength: raw['byteLength'] as int,
      sha256: raw['sha256'] as String,
    );
  }

  Map<String, Object?> _encodeQuote(SocialCreateDraftQuote item) => {
    'id': item.id,
    'authorName': item.authorName,
    'authorHandle': item.authorHandle,
    'body': item.body,
    'mediaUrl': item.mediaUrl?.toString(),
  };
  SocialCreateDraftQuote _decodeQuote(Object? raw) {
    if (raw is! Map<String, dynamic> ||
        raw.length != _quoteFields.length ||
        !raw.keys.toSet().containsAll(_quoteFields)) {
      throw const FormatException();
    }
    final media = raw['mediaUrl'];
    return SocialCreateDraftQuote(
      id: raw['id'] as String,
      authorName: raw['authorName'] as String,
      authorHandle: raw['authorHandle'] as String,
      body: raw['body'] as String,
      mediaUrl: media == null ? null : Uri.parse(media as String),
    );
  }

  void _validate(SocialCreateDraftSnapshot value, {required bool persisted}) {
    void invalid() {
      if (persisted) throw const FormatException();
      throw const SocialCreateDraftPersistenceException('invalid_input');
    }

    if (!value.initialized ||
        value.revision < 1 ||
        value.body.length > 10000 ||
        value.choices.length != 4 ||
        value.choices.any((item) => item.length > 500) ||
        value.media.length > 10 ||
        value.imagePollMedia.length != 4 ||
        value.correctChoice < 0 ||
        value.correctChoice > 3 ||
        !value.capturedAtUtc.isUtc ||
        value.capturedAtUtc.isAfter(_now().toUtc())) {
      invalid();
    }
    for (final item in [
      ...value.media,
      ...value.imagePollMedia.whereType<SocialCreateDraftMediaReference>(),
    ]) {
      if (item.id.isEmpty ||
          item.id.length > 256 ||
          item.name.length > 512 ||
          item.byteLength < 0 ||
          item.byteLength > 25 * 1024 * 1024 ||
          (!item.isAsset && !RegExp(r'^[0-9a-f]{64}$').hasMatch(item.sha256)) ||
          item.isAsset && item.sha256.isNotEmpty) {
        invalid();
      }
    }
    final quote = value.quote;
    if (quote != null &&
        (quote.id.isEmpty ||
            quote.id.length > 256 ||
            quote.authorName.length > 512 ||
            quote.authorHandle.length > 256 ||
            quote.body.length > 10000 ||
            (quote.mediaUrl != null &&
                (quote.mediaUrl!.scheme != 'https' ||
                    quote.mediaUrl!.host.isEmpty ||
                    quote.mediaUrl!.userInfo.isNotEmpty)))) {
      invalid();
    }
  }

  Future<void> _clearQueued() async {
    await _writeRequired(_store, invalidationKey, '1');
    await _removeRequired(_store, storageKey);
    await _removeRequired(_store, invalidationKey);
  }

  static Future<String?> _readRequired(
    YouTubePublicCatalogueKeyValueStore s,
    String k,
  ) async {
    try {
      return await s.readString(k);
    } on Object {
      throw const SocialCreateDraftPersistenceException('read_failed');
    }
  }

  static Future<void> _writeRequired(
    YouTubePublicCatalogueKeyValueStore s,
    String k,
    String v,
  ) async {
    try {
      if (!await s.writeString(k, v)) throw const FormatException();
    } on Object {
      throw const SocialCreateDraftPersistenceException('write_failed');
    }
  }

  static Future<void> _removeRequired(
    YouTubePublicCatalogueKeyValueStore s,
    String k,
  ) async {
    try {
      if (!await s.remove(k)) throw const FormatException();
    } on Object {
      throw const SocialCreateDraftPersistenceException('remove_failed');
    }
  }

  static DateTime _parseUtc(Object? raw) {
    if (raw is! String || !raw.endsWith('Z')) throw const FormatException();
    final value = DateTime.tryParse(raw);
    if (value == null || !value.isUtc || value.toIso8601String() != raw) {
      throw const FormatException();
    }
    return value;
  }
}

final class SocialCreateDraftStateCache {
  SocialCreateDraftStateCache({DateTime Function()? now})
    : _now = now ?? DateTime.now;
  final DateTime Function() _now;
  SocialCreateDraftRepository? _repository;
  SocialCreateDraftSnapshot? _snapshot;
  Future<void> _tail = Future.value();
  int _writeSerial = 0;
  int _lastSuccessfulWriteSerial = 0;
  Timer? _timer;
  int _generation = 0;
  int _bindingEpoch = 0;
  int _bindingBaseline = 0;
  bool _acceptWrites = true;
  bool _durabilityConfigured = false;
  SocialCreateDraftSnapshot? get snapshot => _snapshot;
  int beginPrincipalBindingAttempt() {
    _bindingEpoch++;
    _generation++;
    _bindingBaseline = _generation;
    _timer?.cancel();
    _timer = null;
    _repository = null;
    _snapshot = null;
    _acceptWrites = true;
    _durabilityConfigured = false;
    return _bindingEpoch;
  }

  Future<SocialCreateDraftFreshness?> configureDurability(
    SocialCreateDraftRepository repository, {
    int? bindingAttempt,
  }) async {
    if (bindingAttempt != null && bindingAttempt != _bindingEpoch) return null;
    _acceptWrites = true;
    _durabilityConfigured = false;
    _repository = repository;
    final generation = _generation;
    final local = generation != _bindingBaseline;
    SocialCreateDraftRead read;
    try {
      read = await repository.read();
    } on Object {
      return null;
    }
    if ((bindingAttempt != null && bindingAttempt != _bindingEpoch) ||
        !identical(repository, _repository)) {
      return read.freshness;
    }
    _durabilityConfigured = true;
    if (local || generation != _generation) {
      final current = _snapshot;
      if (current == null) {
        _observe(repository.clear());
      } else {
        _write(current);
      }
      await _tail;
      return read.freshness;
    }
    _snapshot =
        read.freshness == SocialCreateDraftFreshness.fresh ||
            read.freshness == SocialCreateDraftFreshness.stale
        ? read.snapshot
        : null;
    return read.freshness;
  }

  void replace(SocialCreateDraftSnapshot snapshot, {bool debounce = true}) {
    if (!_acceptWrites) return;
    _generation++;
    _snapshot = snapshot;
    _timer?.cancel();
    _timer = null;
    if (!snapshot.hasMeaningfulContent) {
      unawaited(clear());
      return;
    }
    if (debounce) {
      _timer = Timer(const Duration(milliseconds: 300), () {
        _timer = null;
        if (identical(_snapshot, snapshot)) _write(snapshot);
      });
    } else {
      _write(snapshot);
    }
  }

  Future<void> clear({bool detachRepository = false}) {
    _generation++;
    if (detachRepository) _bindingEpoch++;
    if (detachRepository) _acceptWrites = false;
    if (detachRepository) _durabilityConfigured = false;
    _timer?.cancel();
    _timer = null;
    _snapshot = null;
    final repo = _repository;
    if (detachRepository) _repository = null;
    if (repo != null) _observe(repo.clear());
    return _tail;
  }

  Future<bool> clearConfirmed({bool detachRepository = false}) async {
    _generation++;
    if (detachRepository) _bindingEpoch++;
    if (detachRepository) _acceptWrites = false;
    if (detachRepository) _durabilityConfigured = false;
    final operationEpoch = _bindingEpoch;
    _timer?.cancel();
    _timer = null;
    final retainedSnapshot = _snapshot;
    final repo = _repository;
    await _tail;
    if (repo == null) {
      if (operationEpoch == _bindingEpoch) {
        _snapshot = null;
        if (detachRepository) _repository = null;
      }
      return true;
    }
    try {
      await repo.clear();
      if (operationEpoch == _bindingEpoch) {
        _snapshot = null;
        if (detachRepository) _repository = null;
      }
      return true;
    } on Object {
      if (operationEpoch != _bindingEpoch) return false;
      if (detachRepository) {
        _snapshot = null;
        _repository = null;
      } else {
        _snapshot = retainedSnapshot;
      }
      return false;
    }
  }

  Future<void> clearIfRevision(int revision) {
    if (_snapshot?.revision != revision) return Future.value();
    return clear();
  }

  Future<void> settleDurableWrites() {
    return settleDurableWritesConfirmed().then<void>((_) {});
  }

  Future<bool> settleDurableWritesConfirmed() async {
    final timer = _timer;
    if (timer != null) {
      timer.cancel();
      _timer = null;
      final s = _snapshot;
      if (s != null) _write(s);
    }
    final targetSerial = _writeSerial;
    await _tail;
    if ((_snapshot?.hasMeaningfulContent ?? false) && !_durabilityConfigured) {
      return false;
    }
    return targetSerial == 0 || _lastSuccessfulWriteSerial >= targetSerial;
  }

  void _write(SocialCreateDraftSnapshot value) {
    final repo = _repository;
    if (repo == null) return;
    _observe(repo.write(value));
  }

  void _observe(Future<void> value) {
    final serial = ++_writeSerial;
    final safe = value.then<void>((_) {
      _lastSuccessfulWriteSerial = serial;
    }, onError: (Object _, StackTrace _) {});
    _tail = Future.wait<void>([_tail, safe]).then<void>((_) {});
  }

  SocialCreateDraftSnapshot createSnapshot({
    required bool initialized,
    required SocialCreateDraftFormat format,
    required SocialCreateDraftTool tool,
    required String body,
    required List<String> choices,
    required List<SocialCreateDraftMediaReference> media,
    required List<SocialCreateDraftMediaReference?> imagePollMedia,
    required int correctChoice,
    required SocialCreateDraftQuote? quote,
    required int revision,
  }) => SocialCreateDraftSnapshot(
    initialized: initialized,
    format: format,
    tool: tool,
    body: body,
    choices: choices,
    media: media,
    imagePollMedia: imagePollMedia,
    correctChoice: correctChoice,
    quote: quote,
    revision: revision,
    capturedAtUtc: _now().toUtc(),
  );
}

final socialCreateDraftState = SocialCreateDraftStateCache();
