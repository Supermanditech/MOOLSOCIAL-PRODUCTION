import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'social_create_draft_repository.dart';
import 'social_media_picker.dart';

final class SocialCreateDraftResolvedMedia {
  const SocialCreateDraftResolvedMedia({
    required this.media,
    required this.droppedCount,
  });
  final List<SocialPickedMedia> media;
  final int droppedCount;
}

final class SocialCreateDraftMediaStore {
  SocialCreateDraftMediaStore({
    required Directory root,
    Random? random,
    this.maximumBytes = 25 * 1024 * 1024,
    this.maximumTotalBytes = 100 * 1024 * 1024,
  }) : _root = root.absolute,
       _random = random ?? Random.secure();

  final Directory _root;
  final Random _random;
  final int maximumBytes;
  final int maximumTotalBytes;
  final Map<String, Future<SocialCreateDraftMediaReference>> _inflight = {};
  Future<void>? _stageTail;
  bool _acceptStages = true;
  int _stagingEpoch = 0;

  Future<SocialCreateDraftMediaReference> stage(SocialPickedMedia media) {
    if (!_acceptStages) {
      return Future<SocialCreateDraftMediaReference>.error(
        StateError('Draft media staging is disabled.'),
      );
    }
    final key = '${media.isAsset}|${media.kind.name}|${media.path}';
    final existing = _inflight[key];
    if (existing != null) return existing;
    final operation = media.isAsset
        ? _stageOnce(media)
        : _enqueueLocalStage(() => _stageOnce(media));
    _inflight[key] = operation;
    operation.then<void>(
      (_) {
        _inflight.remove(key);
      },
      onError: (Object _, StackTrace _) {
        _inflight.remove(key);
      },
    );
    return operation;
  }

  static SocialCreateDraftMediaReference referenceForBundledAsset(
    SocialPickedMedia media,
  ) {
    if (!media.isAsset || !_validAsset(media.path)) {
      throw const FormatException('Invalid asset.');
    }
    return SocialCreateDraftMediaReference(
      id: media.path,
      name: _safeName(media.name),
      kind: _kind(media.kind),
      isAsset: true,
      byteLength: 0,
      sha256: '',
    );
  }

  Future<T> _enqueueLocalStage<T>(Future<T> Function() operation) {
    final prior = _stageTail;
    final result = prior == null
        ? Future<T>.sync(operation)
        : prior.then((_) => operation());
    final settled = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _stageTail = settled;
    return settled.then<T>((_) {
      if (identical(_stageTail, settled)) _stageTail = null;
      return result;
    });
  }

  Future<SocialCreateDraftMediaReference> _stageOnce(
    SocialPickedMedia media,
  ) async {
    if (media.isAsset) {
      return referenceForBundledAsset(media);
    }
    final source = File(media.path);
    if (await FileSystemEntity.type(source.path, followLinks: false) !=
        FileSystemEntityType.file) {
      throw const FileSystemException('Draft media is unavailable.');
    }
    final length = await source.length();
    if (length <= 0 || length > maximumBytes) {
      throw const FileSystemException('Draft media size is invalid.');
    }
    await _ensureRoot();
    var existingBytes = 0;
    await for (final entity in _root.list(followLinks: false)) {
      if (entity is File) existingBytes += await entity.length();
    }
    if (existingBytes + length > maximumTotalBytes) {
      throw const FileSystemException('Draft media quota exceeded.');
    }
    final id = _opaqueId();
    final target = File('${_root.path}${Platform.pathSeparator}$id.bin');
    _requireInsideRoot(target.path);
    await source.copy(target.path);
    final digest = await sha256.bind(target.openRead()).first;
    return SocialCreateDraftMediaReference(
      id: id,
      name: _safeName(media.name),
      kind: _kind(media.kind),
      isAsset: false,
      byteLength: length,
      sha256: digest.toString(),
    );
  }

  Future<SocialPickedMedia?> resolve(
    SocialCreateDraftMediaReference reference,
  ) async {
    if (reference.isAsset) {
      if (!_validAsset(reference.id)) return null;
      return SocialPickedMedia(
        path: reference.id,
        name: reference.name,
        kind: _pickedKind(reference.kind),
        isAsset: true,
      );
    }
    if (!RegExp(r'^[0-9a-f]{32}$').hasMatch(reference.id)) return null;
    final file = File(
      '${_root.path}${Platform.pathSeparator}${reference.id}.bin',
    );
    _requireInsideRoot(file.path);
    if (await FileSystemEntity.type(file.path, followLinks: false) !=
        FileSystemEntityType.file) {
      return null;
    }
    if (await file.length() != reference.byteLength) return null;
    final digest = await sha256.bind(file.openRead()).first;
    if (digest.toString() != reference.sha256) return null;
    return SocialPickedMedia(
      path: file.path,
      name: reference.name,
      kind: _pickedKind(reference.kind),
    );
  }

  Future<SocialCreateDraftResolvedMedia> resolveAll(
    Iterable<SocialCreateDraftMediaReference> references,
  ) async {
    final resolved = <SocialPickedMedia>[];
    var dropped = 0;
    for (final reference in references) {
      final media = await resolve(reference);
      if (media == null) {
        dropped += 1;
      } else {
        resolved.add(media);
      }
    }
    return SocialCreateDraftResolvedMedia(
      media: List<SocialPickedMedia>.unmodifiable(resolved),
      droppedCount: dropped,
    );
  }

  Future<void> clear(
    Iterable<SocialCreateDraftMediaReference> references,
  ) async {
    for (final reference in references) {
      if (reference.isAsset ||
          !RegExp(r'^[0-9a-f]{32}$').hasMatch(reference.id)) {
        continue;
      }
      final file = File(
        '${_root.path}${Platform.pathSeparator}${reference.id}.bin',
      );
      _requireInsideRoot(file.path);
      if (await file.exists()) await file.delete();
    }
  }

  Future<void> purgeAll() async {
    await _settleStages();
    if (!await _root.exists()) return;
    await for (final entity in _root.list(followLinks: false)) {
      if (entity is File) await entity.delete();
    }
  }

  Future<void> purgeExcept(Set<String> retainedIds) async {
    await _settleStages();
    if (!await _root.exists()) return;
    await for (final entity in _root.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      final id = name.endsWith('.bin')
          ? name.substring(0, name.length - 4)
          : '';
      if (!retainedIds.contains(id)) await entity.delete();
    }
  }

  void enableStaging() {
    _stagingEpoch += 1;
    _acceptStages = true;
  }

  Future<bool> disableStagingAndPurgeAll() async {
    final operationEpoch = ++_stagingEpoch;
    _acceptStages = false;
    try {
      await _settleStages();
      if (operationEpoch != _stagingEpoch) return false;
      if (await _root.exists()) {
        await for (final entity in _root.list(followLinks: false)) {
          if (operationEpoch != _stagingEpoch) return false;
          if (entity is File) await entity.delete();
        }
      }
      return true;
    } on Object {
      return false;
    }
  }

  Future<void> _settleStages() async {
    await _stageTail;
    final active = _inflight.values.toList(growable: false);
    if (active.isEmpty) return;
    await Future.wait<void>(
      active.map(
        (future) =>
            future.then<void>((_) {}, onError: (Object _, StackTrace _) {}),
      ),
    );
  }

  Future<void> _ensureRoot() async {
    if (!await _root.exists()) await _root.create(recursive: true);
    if (await FileSystemEntity.type(_root.path, followLinks: false) !=
        FileSystemEntityType.directory) {
      throw const FileSystemException('Invalid draft media root.');
    }
  }

  void _requireInsideRoot(String path) {
    final rootPrefix = '${_root.path}${Platform.pathSeparator}';
    if (!File(path).absolute.path.startsWith(rootPrefix)) {
      throw const FileSystemException('Draft media escaped its private root.');
    }
  }

  String _opaqueId() => List<int>.generate(
    16,
    (_) => _random.nextInt(256),
  ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

  static bool _validAsset(String path) =>
      path.startsWith('assets/') &&
      !path.contains('..') &&
      RegExp(r'^assets/[A-Za-z0-9_./-]{1,240}$').hasMatch(path);
  static String _safeName(String value) {
    final name = value.trim().replaceAll(RegExp(r'[\r\n\x00]'), '');
    return name.isEmpty ? 'media' : name.substring(0, min(name.length, 255));
  }

  static SocialCreateDraftMediaKind _kind(SocialMediaKind kind) =>
      kind == SocialMediaKind.image
      ? SocialCreateDraftMediaKind.image
      : SocialCreateDraftMediaKind.video;
  static SocialMediaKind _pickedKind(SocialCreateDraftMediaKind kind) =>
      kind == SocialCreateDraftMediaKind.image
      ? SocialMediaKind.image
      : SocialMediaKind.video;
}

SocialCreateDraftMediaStore? _socialCreateDraftMediaStore;

void configureSocialCreateDraftMediaStore(SocialCreateDraftMediaStore store) {
  _socialCreateDraftMediaStore = store;
}

SocialCreateDraftMediaStore? get socialCreateDraftMediaStore =>
    _socialCreateDraftMediaStore;
