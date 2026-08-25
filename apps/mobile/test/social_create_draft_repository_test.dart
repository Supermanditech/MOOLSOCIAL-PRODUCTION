import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/shared/social_create_draft_repository.dart';
import 'package:moolsocial/features/shared/youtube_public_catalogue_repository.dart';

void main() {
  group('DurableSocialCreateDraftRepository', () {
    late DateTime now;
    late _Store store;
    late DurableSocialCreateDraftRepository repository;

    setUp(() {
      now = DateTime.utc(2026, 8, 25, 6);
      store = _Store();
      repository = DurableSocialCreateDraftRepository(
        persistence: store,
        principalBinding: _binding(),
        now: () => now,
      );
    });

    test('round-trips every draft field exactly', () async {
      final snapshot = _snapshot(now);
      await repository.write(snapshot);
      final read = await repository.read();
      expect(read.freshness, SocialCreateDraftFreshness.fresh);
      final restored = read.snapshot!;
      expect(restored.format, SocialCreateDraftFormat.carousel);
      expect(restored.tool, SocialCreateDraftTool.quiz);
      expect(restored.body, 'Unpublished body');
      expect(restored.choices, ['One', 'Two', 'Three', 'Four']);
      expect(restored.media.single.id, 'a' * 32);
      expect(restored.imagePollMedia[1]?.id, 'b' * 32);
      expect(restored.correctChoice, 2);
      expect(restored.quote?.id, 'quoted-1');
      expect(restored.revision, 7);
    });

    test('reports stale then expires and purges exact key', () async {
      store.values['unrelated'] = 'preserve';
      await repository.write(_snapshot(now));
      now = now.add(const Duration(days: 7, microseconds: 1));
      expect(
        (await repository.read()).freshness,
        SocialCreateDraftFreshness.stale,
      );
      now = now.add(const Duration(days: 23));
      expect(
        (await repository.read()).freshness,
        SocialCreateDraftFreshness.expired,
      );
      expect(store.values['unrelated'], 'preserve');
    });

    test('principal mismatch and schema corruption fail closed', () async {
      await repository.write(_snapshot(now));
      final other = DurableSocialCreateDraftRepository(
        persistence: store,
        principalBinding: _binding('b'),
        now: () => now,
      );
      expect(
        (await other.read()).freshness,
        SocialCreateDraftFreshness.invalidated,
      );

      await repository.write(_snapshot(now));
      final envelope =
          jsonDecode(
                store.values[DurableSocialCreateDraftRepository.storageKey]!,
              )
              as Map<String, dynamic>;
      envelope['unknown'] = true;
      store.values[DurableSocialCreateDraftRepository.storageKey] = jsonEncode(
        envelope,
      );
      expect(
        (await repository.read()).freshness,
        SocialCreateDraftFreshness.invalidated,
      );
    });

    test('future, oversized and invalid structures are rejected', () async {
      await expectLater(
        repository.write(_snapshot(now.add(const Duration(microseconds: 1)))),
        throwsA(isA<SocialCreateDraftPersistenceException>()),
      );
      await expectLater(
        repository.write(_snapshot(now, choices: const ['only one'])),
        throwsA(isA<SocialCreateDraftPersistenceException>()),
      );
      await expectLater(
        repository.write(_snapshot(now, body: 'x' * 10001)),
        throwsA(isA<SocialCreateDraftPersistenceException>()),
      );
    });

    test('interrupted clear tombstone blocks resurrection', () async {
      await repository.write(_snapshot(now));
      store.throwNextRemove = StateError('private detail');
      await expectLater(
        repository.clear(),
        throwsA(isA<SocialCreateDraftPersistenceException>()),
      );
      expect(
        store.values,
        contains(DurableSocialCreateDraftRepository.invalidationKey),
      );
      expect(
        (await repository.read()).freshness,
        SocialCreateDraftFreshness.invalidated,
      );
    });

    test('storage failures are sanitized and queue recovers', () async {
      store.throwNextWrite = StateError('private write');
      final error = await _capture(repository.write(_snapshot(now)));
      expect(error.toString(), isNot(contains('private write')));
      await repository.write(_snapshot(now));
      store.throwNextRead = StateError('private read');
      expect(
        (await _capture(repository.read())).toString(),
        isNot(contains('private read')),
      );
      await repository.clear();
      expect(
        (await repository.read()).freshness,
        SocialCreateDraftFreshness.missing,
      );
    });

    test('queued clear after delayed write wins', () async {
      final gate = Completer<void>();
      store.writeGate = gate;
      final write = repository.write(_snapshot(now));
      await store.writeStarted.future;
      final clear = repository.clear();
      gate.complete();
      await Future.wait([write, clear]);
      expect(
        (await repository.read()).freshness,
        SocialCreateDraftFreshness.missing,
      );
    });

    test('payload contains no raw account or auth fields', () async {
      await repository.write(_snapshot(now));
      final raw = store.values[DurableSocialCreateDraftRepository.storageKey]!
          .toLowerCase();
      for (final forbidden in [
        'uid',
        'email',
        'phone',
        'token',
        'cookie',
        'authorization',
      ]) {
        expect(raw, isNot(contains(forbidden)));
      }
    });
  });

  group('SocialCreateDraftStateCache', () {
    test(
      'debounce settles newest revision and clearIfRevision is exact',
      () async {
        final repo = _Repo();
        final cache = SocialCreateDraftStateCache(
          now: () => DateTime.utc(2026, 8, 25, 6),
        );
        await cache.configureDurability(repo);
        cache.replace(_snapshot(DateTime.utc(2026, 8, 25, 6), revision: 1));
        cache.replace(_snapshot(DateTime.utc(2026, 8, 25, 6), revision: 2));
        await cache.settleDurableWrites();
        expect(repo.lastWrite?.revision, 2);
        await cache.clearIfRevision(1);
        expect(cache.snapshot?.revision, 2);
        await cache.clearIfRevision(2);
        expect(cache.snapshot, isNull);
      },
    );

    test('typing during delayed binding survives and is flushed', () async {
      final repo = _Repo();
      final gate = Completer<void>();
      repo.readGate = gate;
      final cache = SocialCreateDraftStateCache(
        now: () => DateTime.utc(2026, 8, 25, 6),
      );
      final token = cache.beginPrincipalBindingAttempt();
      final bind = cache.configureDurability(repo, bindingAttempt: token);
      await repo.readStarted.future;
      cache.replace(_snapshot(DateTime.utc(2026, 8, 25, 6), revision: 9));
      gate.complete();
      await bind;
      await cache.settleDurableWrites();
      expect(repo.lastWrite?.revision, 9);
    });

    test('auth detach prevents later writes into prior repository', () async {
      final repo = _Repo();
      final cache = SocialCreateDraftStateCache();
      await cache.configureDurability(repo);
      cache.replace(_snapshot(DateTime.now().toUtc()));
      await cache.clear(detachRepository: true);
      cache.replace(_snapshot(DateTime.now().toUtc(), revision: 8));
      await cache.settleDurableWrites();
      expect(repo.writes, 0);
      expect(cache.snapshot, isNull);
    });

    test(
      'confirmed clear cancels debounce and reports durable failure',
      () async {
        final repo = _Repo();
        final cache = SocialCreateDraftStateCache();
        await cache.configureDurability(repo);
        cache.replace(_snapshot(DateTime.now().toUtc(), revision: 2));
        repo.clearFailure = StateError('secure remove failed');

        expect(await cache.clearConfirmed(), isFalse);
        expect(cache.snapshot?.revision, 2);
        expect(repo.writes, 0);

        cache.replace(_snapshot(DateTime.now().toUtc(), revision: 3));
        await cache.clearConfirmed(detachRepository: true);
        cache.replace(_snapshot(DateTime.now().toUtc(), revision: 4));
        await cache.settleDurableWrites();
        expect(cache.snapshot, isNull);
      },
    );

    test('confirmed settle reports write failure and later retry', () async {
      final repo = _Repo();
      final cache = SocialCreateDraftStateCache();
      await cache.configureDurability(repo);
      repo.writeFailure = StateError('secure write failed');
      cache.replace(_snapshot(DateTime.now().toUtc(), revision: 12));
      expect(await cache.settleDurableWritesConfirmed(), isFalse);

      cache.replace(_snapshot(DateTime.now().toUtc(), revision: 13));
      expect(await cache.settleDurableWritesConfirmed(), isTrue);
      expect(repo.lastWrite?.revision, 13);
    });

    test(
      'meaningful unbound flush fails until durability is configured',
      () async {
        final cache = SocialCreateDraftStateCache();
        cache.replace(_snapshot(DateTime.now().toUtc(), revision: 20));
        expect(await cache.settleDurableWritesConfirmed(), isFalse);

        final repo = _Repo();
        await cache.configureDurability(repo);
        expect(await cache.settleDurableWritesConfirmed(), isTrue);
        expect(repo.lastWrite?.revision, 20);
      },
    );

    test('late detached clear cannot erase a newly bound principal', () async {
      final oldRepo = _Repo();
      final oldSnapshot = _snapshot(DateTime.now().toUtc(), revision: 30);
      oldRepo.readValue = SocialCreateDraftRead(
        freshness: SocialCreateDraftFreshness.fresh,
        snapshot: oldSnapshot,
      );
      final cache = SocialCreateDraftStateCache();
      await cache.configureDurability(oldRepo);
      oldRepo.clearGate = Completer<void>();

      final oldClear = cache.clearConfirmed(detachRepository: true);
      await oldRepo.clearStarted.future;
      final newSnapshot = _snapshot(
        DateTime.now().toUtc(),
        body: 'New principal draft',
        revision: 31,
      );
      final newRepo = _Repo()
        ..readValue = SocialCreateDraftRead(
          freshness: SocialCreateDraftFreshness.fresh,
          snapshot: newSnapshot,
        );
      final binding = cache.beginPrincipalBindingAttempt();
      await cache.configureDurability(newRepo, bindingAttempt: binding);
      oldRepo.clearGate!.complete();

      expect(await oldClear, isTrue);
      expect(cache.snapshot?.body, 'New principal draft');
      cache.replace(
        _snapshot(DateTime.now().toUtc(), revision: 32),
        debounce: false,
      );
      expect(await cache.settleDurableWritesConfirmed(), isTrue);
      expect(newRepo.lastWrite?.revision, 32);
    });
  });
}

final class _Store implements YouTubePublicCatalogueKeyValueStore {
  final Map<String, String> values = {};
  Object? throwNextRead;
  Object? throwNextWrite;
  Object? throwNextRemove;
  Completer<void>? writeGate;
  final Completer<void> writeStarted = Completer<void>();
  @override
  Future<String?> readString(String key) async {
    final failure = throwNextRead;
    throwNextRead = null;
    if (failure != null) throw failure;
    return values[key];
  }

  @override
  Future<bool> writeString(String key, String value) async {
    if (!writeStarted.isCompleted) writeStarted.complete();
    final gate = writeGate;
    writeGate = null;
    if (gate != null) await gate.future;
    final failure = throwNextWrite;
    throwNextWrite = null;
    if (failure != null) throw failure;
    values[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    final failure = throwNextRemove;
    throwNextRemove = null;
    if (failure != null) throw failure;
    values.remove(key);
    return true;
  }
}

final class _Repo implements SocialCreateDraftRepository {
  SocialCreateDraftRead readValue = const SocialCreateDraftRead(
    freshness: SocialCreateDraftFreshness.missing,
  );
  Completer<void>? readGate;
  final Completer<void> readStarted = Completer<void>();
  SocialCreateDraftSnapshot? lastWrite;
  int writes = 0;
  Object? clearFailure;
  Object? writeFailure;
  Completer<void>? clearGate;
  final Completer<void> clearStarted = Completer<void>();
  @override
  Future<SocialCreateDraftRead> read() async {
    if (!readStarted.isCompleted) readStarted.complete();
    if (readGate case final gate?) await gate.future;
    return readValue;
  }

  @override
  Future<void> write(SocialCreateDraftSnapshot snapshot) async {
    writes += 1;
    final failure = writeFailure;
    writeFailure = null;
    if (failure != null) throw failure;
    lastWrite = snapshot;
  }

  @override
  Future<void> clear() async {
    if (!clearStarted.isCompleted) clearStarted.complete();
    final gate = clearGate;
    if (gate != null) await gate.future;
    final failure = clearFailure;
    clearFailure = null;
    if (failure != null) throw failure;
  }
}

VerifiedPrincipalBinding _binding([String value = 'a']) =>
    VerifiedPrincipalBinding.fromStorage('v1:${value * 64}');

SocialCreateDraftMediaReference _media(String id) =>
    SocialCreateDraftMediaReference(
      id: id,
      name: 'photo.jpg',
      kind: SocialCreateDraftMediaKind.image,
      isAsset: false,
      byteLength: 4,
      sha256: 'c' * 64,
    );

SocialCreateDraftSnapshot _snapshot(
  DateTime now, {
  String body = 'Unpublished body',
  List<String> choices = const ['One', 'Two', 'Three', 'Four'],
  int revision = 7,
}) => SocialCreateDraftSnapshot(
  initialized: true,
  format: SocialCreateDraftFormat.carousel,
  tool: SocialCreateDraftTool.quiz,
  body: body,
  choices: choices,
  media: [_media('a' * 32)],
  imagePollMedia: [null, _media('b' * 32), null, null],
  correctChoice: 2,
  quote: const SocialCreateDraftQuote(
    id: 'quoted-1',
    authorName: 'Author',
    authorHandle: '@author',
    body: 'Quoted body',
    mediaUrl: null,
  ),
  revision: revision,
  capturedAtUtc: now,
);

Future<Object> _capture(Future<Object?> future) async {
  try {
    await future;
  } catch (error) {
    return error;
  }
  throw StateError('Expected failure.');
}
