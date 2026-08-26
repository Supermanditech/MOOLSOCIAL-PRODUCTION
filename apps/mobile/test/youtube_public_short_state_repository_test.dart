import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/shared/youtube_public_catalogue_repository.dart';
import 'package:moolsocial/features/shared/youtube_public_short_state_repository.dart';

void main() {
  test('bootstrap truth distinguishes usable, empty and degraded reads', () {
    expect(
      youtubePublicShortHydrationIsDegraded(YouTubePublicShortFreshness.fresh),
      isFalse,
    );
    expect(
      youtubePublicShortHydrationIsDegraded(
        YouTubePublicShortFreshness.missing,
      ),
      isFalse,
    );
    for (final freshness in <YouTubePublicShortFreshness?>[
      YouTubePublicShortFreshness.stale,
      YouTubePublicShortFreshness.expired,
      YouTubePublicShortFreshness.invalidated,
      null,
    ]) {
      expect(youtubePublicShortHydrationIsDegraded(freshness), isTrue);
    }
  });

  group('DurableYouTubePublicShortStateRepository', () {
    late DateTime now;
    late _KeyValueStore store;
    late DurableYouTubePublicShortStateRepository repository;

    setUp(() {
      now = DateTime.utc(2026, 8, 25, 6);
      store = _KeyValueStore();
      repository = DurableYouTubePublicShortStateRepository(
        persistence: store,
        principalBinding: _binding(),
        now: () => now,
      );
    });

    test(
      'round-trips exact active identity, index and catalogue order',
      () async {
        await repository.write(_snapshot(now, selected: 'short-2', index: 1));

        final read = await repository.read();

        expect(read.freshness, YouTubePublicShortFreshness.fresh);
        expect(read.snapshot?.selectedVideoId, 'short-2');
        expect(read.snapshot?.activeIndex, 1);
        expect(read.snapshot?.catalogueVideoIds, const [
          'short-1',
          'short-2',
          'short-3',
        ]);
        expect(
          () => read.snapshot!.catalogueVideoIds.add('mutation'),
          throwsUnsupportedError,
        );
      },
    );

    test('a new repository instance restores prior process state', () async {
      await repository.write(_snapshot(now, selected: 'short-3', index: 2));

      final relaunched = DurableYouTubePublicShortStateRepository(
        persistence: store,
        principalBinding: _binding(),
        now: () => now,
      );

      expect((await relaunched.read()).snapshot?.selectedVideoId, 'short-3');
    });

    test('preserves fresh boundary and reports stale truth', () async {
      await repository.write(_snapshot(now));
      now = now.add(const Duration(minutes: 5));
      expect(
        (await repository.read()).freshness,
        YouTubePublicShortFreshness.fresh,
      );

      now = now.add(const Duration(microseconds: 1));
      final stale = await repository.read();
      expect(stale.freshness, YouTubePublicShortFreshness.stale);
      expect(stale.snapshot, isNotNull);
    });

    test('expires after hard age and preserves unrelated data', () async {
      store.values['unrelated'] = 'preserve';
      await repository.write(_snapshot(now));
      now = now.add(const Duration(hours: 24, microseconds: 1));

      expect(
        (await repository.read()).freshness,
        YouTubePublicShortFreshness.expired,
      );
      expect(store.values['unrelated'], 'preserve');
      expect(
        store.values,
        isNot(contains(DurableYouTubePublicShortStateRepository.storageKey)),
      );
    });

    test(
      'wrong opaque principal binding invalidates and removes state',
      () async {
        await repository.write(_snapshot(now));
        final otherAccount = DurableYouTubePublicShortStateRepository(
          persistence: store,
          principalBinding: _binding('b'),
          now: () => now,
        );

        expect(
          (await otherAccount.read()).freshness,
          YouTubePublicShortFreshness.invalidated,
        );
        expect(
          store.values,
          isNot(contains(DurableYouTubePublicShortStateRepository.storageKey)),
        );
      },
    );

    test('invalid exact-schema envelopes fail closed', () async {
      final mutations = <void Function(Map<String, dynamic>)>[
        (value) => value['schema'] = 'wrong',
        (value) => value['version'] = 1.0,
        (value) => value['regionCode'] = 'US',
        (value) => value['principalBinding'] = 'v1:${'b' * 64}',
        (value) => value['selectedVideoId'] = 'unknown',
        (value) => value['activeIndex'] = 3,
        (value) => value['activeIndex'] = 1.0,
        (value) => value['catalogueVideoIds'] = <Object>['short-1', 2],
        (value) => value['catalogueVideoIds'] = <String>['short-1', 'short-1'],
        (value) => value['unknown'] = true,
        (value) => value.remove('selectedVideoId'),
      ];

      for (final mutate in mutations) {
        await repository.write(_snapshot(now));
        final envelope = _storedEnvelope(store);
        mutate(envelope);
        store.values[DurableYouTubePublicShortStateRepository.storageKey] =
            jsonEncode(envelope);
        expect(
          (await repository.read()).freshness,
          YouTubePublicShortFreshness.invalidated,
        );
      }
    });

    test(
      'future timestamp, corrupt JSON and oversized bytes invalidate',
      () async {
        await repository.write(_snapshot(now));
        final future = _storedEnvelope(store);
        future['capturedAtUtc'] = now
            .add(const Duration(microseconds: 1))
            .toIso8601String();
        store.values[DurableYouTubePublicShortStateRepository.storageKey] =
            jsonEncode(future);
        expect(
          (await repository.read()).freshness,
          YouTubePublicShortFreshness.invalidated,
        );

        store.values[DurableYouTubePublicShortStateRepository.storageKey] = '{';
        expect(
          (await repository.read()).freshness,
          YouTubePublicShortFreshness.invalidated,
        );

        store.values[DurableYouTubePublicShortStateRepository.storageKey] =
            'x' * ((64 * 1024) + 1);
        expect(
          (await repository.read()).freshness,
          YouTubePublicShortFreshness.invalidated,
        );
      },
    );

    test('rejects invalid catalogue identity before write', () async {
      final invalid = <YouTubePublicShortSnapshot>[
        _snapshot(now, selected: 'short-2', index: 0),
        _snapshot(now, selected: ' short-1'),
        _snapshot(now, ids: const []),
        _snapshot(now, ids: const ['short-1', 'short-1']),
        _snapshot(now, index: -1),
        _snapshot(now, index: 3),
        _snapshot(now, ids: List<String>.generate(21, (index) => 's$index')),
        _snapshot(now, selected: 'x' * 129, ids: ['x' * 129]),
        _snapshot(now.add(const Duration(microseconds: 1))),
      ];

      for (final snapshot in invalid) {
        final error = await _capture(repository.write(snapshot));
        expect(error, isA<YouTubePublicShortPersistenceException>());
        expect(
          (error as YouTubePublicShortPersistenceException).code,
          'invalid_input',
        );
      }
    });

    test('rejects invalid repository configuration', () {
      expect(
        () => DurableYouTubePublicShortStateRepository(
          persistence: store,
          principalBinding: _binding(),
          freshTimeToLive: const Duration(hours: 25),
          maximumAge: const Duration(hours: 24),
        ),
        throwsArgumentError,
      );
      expect(
        () => DurableYouTubePublicShortStateRepository(
          persistence: store,
          principalBinding: _binding(),
          regionCode: 'India',
        ),
        throwsArgumentError,
      );
    });

    test('tombstone prevents resurrection after interrupted clear', () async {
      await repository.write(_snapshot(now));
      store.throwNextStorageRemove = StateError('private detail');

      final error = await _capture(repository.clear());
      expect(error.toString(), contains('(remove_failed)'));
      expect(error.toString(), isNot(contains('private detail')));
      expect(
        store.values,
        contains(DurableYouTubePublicShortStateRepository.invalidationKey),
      );

      expect(
        (await repository.read()).freshness,
        YouTubePublicShortFreshness.invalidated,
      );
      expect(
        store.values,
        isNot(contains(DurableYouTubePublicShortStateRepository.storageKey)),
      );
    });

    test('unbound invalidation is exact and survives delete failure', () async {
      store.values[DurableYouTubePublicShortStateRepository.storageKey] =
          'prior-account-state';
      store.values['unrelated'] = 'preserve';
      store.throwNextStorageRemove = StateError('private detail');

      final error = await _capture(
        DurableYouTubePublicShortStateRepository.invalidateUnbound(store),
      );

      expect(error.toString(), contains('(remove_failed)'));
      expect(error.toString(), isNot(contains('private detail')));
      expect(store.values['unrelated'], 'preserve');
      expect(
        store.values,
        contains(DurableYouTubePublicShortStateRepository.invalidationKey),
      );
    });

    test('storage failures expose only sanitized classifications', () async {
      store.throwNextWrite = StateError('secret write detail');
      var error = await _capture(repository.write(_snapshot(now)));
      expect(error.toString(), contains('(write_failed)'));
      expect(error.toString(), isNot(contains('secret')));

      store.throwNextRead = StateError('secret read detail');
      error = await _capture(repository.read());
      expect(error.toString(), contains('(read_failed)'));
      expect(error.toString(), isNot(contains('secret')));
    });

    test('cross-instance writes are globally serialized latest-wins', () async {
      final gate = Completer<void>();
      store.writeGate = gate;
      final second = DurableYouTubePublicShortStateRepository(
        persistence: store,
        principalBinding: _binding(),
        now: () => now,
      );

      final firstWrite = repository.write(_snapshot(now));
      await store.writeStarted.future;
      final secondWrite = second.write(
        _snapshot(now, selected: 'short-3', index: 2),
      );
      gate.complete();
      await Future.wait([firstWrite, secondWrite]);

      expect((await repository.read()).snapshot?.selectedVideoId, 'short-3');
    });
  });

  group('YouTubePublicShortStateCache', () {
    late DateTime now;

    setUp(() {
      now = DateTime.utc(2026, 8, 25, 6);
    });

    test('hydrates only a fresh snapshot', () async {
      final fresh = _ShortRepositoryFake()
        ..readValue = YouTubePublicShortRead(
          freshness: YouTubePublicShortFreshness.fresh,
          snapshot: _snapshot(now, selected: 'short-2', index: 1),
        );
      final cache = YouTubePublicShortStateCache(now: () => now);
      await cache.configureDurability(fresh);
      expect(cache.snapshot?.selectedVideoId, 'short-2');

      final stale = _ShortRepositoryFake()
        ..readValue = YouTubePublicShortRead(
          freshness: YouTubePublicShortFreshness.stale,
          snapshot: _snapshot(now),
        );
      final relaunched = YouTubePublicShortStateCache(now: () => now);
      await relaunched.configureDurability(stale);
      expect(relaunched.snapshot, isNull);
    });

    test('replace persists the exact newest selection and order', () async {
      final repository = _ShortRepositoryFake();
      final cache = YouTubePublicShortStateCache(now: () => now);
      await cache.configureDurability(repository);

      cache.replace(
        selectedVideoId: 'short-3',
        activeIndex: 2,
        catalogueVideoIds: const ['short-1', 'short-2', 'short-3'],
      );
      await cache.settleDurableWrites();

      expect(repository.writes, 1);
      expect(repository.lastWrite?.selectedVideoId, 'short-3');
      expect(repository.lastWrite?.activeIndex, 2);
      expect(repository.lastWrite?.catalogueVideoIds, const [
        'short-1',
        'short-2',
        'short-3',
      ]);
    });

    test('clear detaches and cannot write into the prior account', () async {
      final repository = _ShortRepositoryFake();
      final cache = YouTubePublicShortStateCache(now: () => now);
      await cache.configureDurability(repository);

      await cache.clear(detachRepository: true);
      cache.replace(
        selectedVideoId: 'new-account',
        activeIndex: 0,
        catalogueVideoIds: const ['new-account'],
      );
      await cache.settleDurableWrites();

      expect(cache.snapshot?.selectedVideoId, 'new-account');
      expect(repository.clears, 1);
      expect(repository.writes, 0);
    });

    test(
      'a stale principal binding attempt cannot attach or hydrate',
      () async {
        final oldRepository = _ShortRepositoryFake()
          ..readGate = Completer<void>()
          ..readValue = YouTubePublicShortRead(
            freshness: YouTubePublicShortFreshness.fresh,
            snapshot: _snapshot(
              now,
              selected: 'old-account',
              ids: const ['old-account'],
            ),
          );
        final currentRepository = _ShortRepositoryFake()
          ..readValue = YouTubePublicShortRead(
            freshness: YouTubePublicShortFreshness.fresh,
            snapshot: _snapshot(
              now,
              selected: 'current-account',
              ids: const ['current-account'],
            ),
          );
        final cache = YouTubePublicShortStateCache(now: () => now);
        final oldAttempt = cache.beginPrincipalBindingAttempt();
        final oldBinding = cache.configureDurability(
          oldRepository,
          bindingAttempt: oldAttempt,
        );
        await oldRepository.readStarted.future;
        final currentAttempt = cache.beginPrincipalBindingAttempt();
        await cache.configureDurability(
          currentRepository,
          bindingAttempt: currentAttempt,
        );

        oldRepository.readGate!.complete();
        await oldBinding;

        expect(cache.snapshot?.selectedVideoId, 'current-account');
      },
    );

    test(
      'page mutation during principal read survives and is flushed',
      () async {
        final repository = _ShortRepositoryFake()
          ..readGate = Completer<void>()
          ..readValue = YouTubePublicShortRead(
            freshness: YouTubePublicShortFreshness.fresh,
            snapshot: _snapshot(now),
          );
        final cache = YouTubePublicShortStateCache(now: () => now);
        final attempt = cache.beginPrincipalBindingAttempt();
        final binding = cache.configureDurability(
          repository,
          bindingAttempt: attempt,
        );
        await repository.readStarted.future;

        cache.replace(
          selectedVideoId: 'short-3',
          activeIndex: 2,
          catalogueVideoIds: const ['short-1', 'short-2', 'short-3'],
        );
        repository.readGate!.complete();
        await binding;

        expect(cache.snapshot?.selectedVideoId, 'short-3');
        expect(repository.lastWrite?.selectedVideoId, 'short-3');
      },
    );

    test('clear during principal read cannot resurrect stored state', () async {
      final repository = _ShortRepositoryFake()
        ..readGate = Completer<void>()
        ..readValue = YouTubePublicShortRead(
          freshness: YouTubePublicShortFreshness.fresh,
          snapshot: _snapshot(now),
        );
      final cache = YouTubePublicShortStateCache(now: () => now);
      final attempt = cache.beginPrincipalBindingAttempt();
      final binding = cache.configureDurability(
        repository,
        bindingAttempt: attempt,
      );
      await repository.readStarted.future;

      final clear = cache.clear();
      repository.readGate!.complete();
      await Future.wait([binding, clear]);

      expect(cache.snapshot, isNull);
      expect(repository.clears, greaterThanOrEqualTo(1));
    });
  });
}

final class _KeyValueStore implements YouTubePublicCatalogueKeyValueStore {
  final Map<String, String> values = <String, String>{};
  final Completer<void> writeStarted = Completer<void>();
  Completer<void>? writeGate;
  Object? throwNextRead;
  Object? throwNextWrite;
  Object? throwNextStorageRemove;

  @override
  Future<String?> readString(String key) async {
    final error = throwNextRead;
    throwNextRead = null;
    if (error != null) throw error;
    return values[key];
  }

  @override
  Future<bool> writeString(String key, String value) async {
    if (!writeStarted.isCompleted) writeStarted.complete();
    final gate = writeGate;
    writeGate = null;
    if (gate != null) await gate.future;
    final error = throwNextWrite;
    throwNextWrite = null;
    if (error != null) throw error;
    values[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    final error = throwNextStorageRemove;
    throwNextStorageRemove = null;
    if (error != null) throw error;
    values.remove(key);
    return true;
  }
}

final class _ShortRepositoryFake implements YouTubePublicShortStateRepository {
  final Completer<void> readStarted = Completer<void>();
  Completer<void>? readGate;
  YouTubePublicShortRead readValue = const YouTubePublicShortRead(
    freshness: YouTubePublicShortFreshness.missing,
  );
  int clears = 0;
  int writes = 0;
  YouTubePublicShortSnapshot? lastWrite;

  @override
  Future<YouTubePublicShortRead> read() async {
    if (!readStarted.isCompleted) readStarted.complete();
    if (readGate case final gate?) await gate.future;
    return readValue;
  }

  @override
  Future<void> write(YouTubePublicShortSnapshot snapshot) async {
    writes += 1;
    lastWrite = snapshot;
  }

  @override
  Future<void> clear() async {
    clears += 1;
  }
}

Map<String, dynamic> _storedEnvelope(_KeyValueStore store) =>
    jsonDecode(
          store.values[DurableYouTubePublicShortStateRepository.storageKey]!,
        )
        as Map<String, dynamic>;

YouTubePublicShortSnapshot _snapshot(
  DateTime capturedAt, {
  String selected = 'short-1',
  int index = 0,
  List<String> ids = const ['short-1', 'short-2', 'short-3'],
}) => YouTubePublicShortSnapshot(
  selectedVideoId: selected,
  activeIndex: index,
  catalogueVideoIds: ids,
  capturedAtUtc: capturedAt,
);

Future<Object> _capture(Future<Object?> future) async {
  try {
    await future;
  } catch (error) {
    return error;
  }
  throw StateError('Expected failure.');
}

VerifiedPrincipalBinding _binding([String hex = 'a']) =>
    VerifiedPrincipalBinding.fromStorage('v1:${hex * 64}');
