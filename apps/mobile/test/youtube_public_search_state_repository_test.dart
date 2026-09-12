import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/shared/youtube_public_catalogue_repository.dart';
import 'package:moolsocial/features/shared/youtube_public_search_state_repository.dart';

void main() {
  test('bootstrap truth distinguishes usable, empty and degraded reads', () {
    expect(
      youtubePublicSearchHydrationIsDegraded(
        YouTubePublicSearchFreshness.fresh,
      ),
      isFalse,
    );
    expect(
      youtubePublicSearchHydrationIsDegraded(
        YouTubePublicSearchFreshness.missing,
      ),
      isFalse,
    );
    for (final freshness in <YouTubePublicSearchFreshness?>[
      YouTubePublicSearchFreshness.stale,
      YouTubePublicSearchFreshness.expired,
      YouTubePublicSearchFreshness.invalidated,
      null,
    ]) {
      expect(youtubePublicSearchHydrationIsDegraded(freshness), isTrue);
    }
  });

  group('DurableYouTubePublicSearchStateRepository', () {
    late DateTime now;
    late _KeyValueStore store;
    late DurableYouTubePublicSearchStateRepository repository;

    setUp(() {
      now = DateTime.utc(2026, 8, 25, 6);
      store = _KeyValueStore();
      repository = DurableYouTubePublicSearchStateRepository(
        persistence: store,
        principalBinding: _binding(),
        now: () => now,
      );
    });

    test('round-trips exact query, results, open state and offset', () async {
      final snapshot = _snapshot(now, offset: 321.5);
      await repository.write(snapshot);

      final read = await repository.read();

      expect(read.freshness, YouTubePublicSearchFreshness.fresh);
      expect(read.snapshot?.submittedQuery, 'India news');
      expect(read.snapshot?.searchSurfaceOpen, isTrue);
      expect(read.snapshot?.resultsScrollOffset, 321.5);
      _expectItem(read.snapshot!.results.single, snapshot.results.single);
    });

    test('preserves fresh boundary, stale truth and captured age', () async {
      await repository.write(_snapshot(now));
      final captured = now;
      now = now.add(const Duration(minutes: 5));
      expect(
        (await repository.read()).freshness,
        YouTubePublicSearchFreshness.fresh,
      );
      now = now.add(const Duration(microseconds: 1));
      final stale = await repository.read();
      expect(stale.freshness, YouTubePublicSearchFreshness.stale);
      expect(stale.snapshot?.capturedAtUtc, captured);
    });

    test('expires at hard age and deletes only the owned secure key', () async {
      store.values['unrelated'] = 'preserve';
      await repository.write(_snapshot(now));
      now = now.add(const Duration(hours: 24, microseconds: 1));

      expect(
        (await repository.read()).freshness,
        YouTubePublicSearchFreshness.expired,
      );
      expect(store.values['unrelated'], 'preserve');
      expect(
        store.values,
        isNot(contains(DurableYouTubePublicSearchStateRepository.storageKey)),
      );
    });

    test('invalid envelopes fail closed and clear exact state', () async {
      await repository.write(_snapshot(now));
      final mutations = <void Function(Map<String, dynamic>)>[
        (value) => value['schema'] = 'wrong',
        (value) => value['version'] = 1.0,
        (value) => value['regionCode'] = 'US',
        (value) => value['capturedAtUtc'] = 'not-a-date',
        (value) => value['submittedQuery'] = '',
        (value) => value['submittedQuery'] = ' padded ',
        (value) => value['searchSurfaceOpen'] = false,
        (value) => value['resultsScrollOffset'] = -1,
        (value) => value['unknown'] = true,
        (value) => value.remove('results'),
        (value) =>
            (value['results'] as List).cast<Map>().single['unknown'] = true,
      ];

      for (final mutate in mutations) {
        await repository.write(_snapshot(now));
        final envelope =
            jsonDecode(
                  store.values[DurableYouTubePublicSearchStateRepository
                      .storageKey]!,
                )
                as Map<String, dynamic>;
        mutate(envelope);
        store.values[DurableYouTubePublicSearchStateRepository.storageKey] =
            jsonEncode(envelope);
        expect(
          (await repository.read()).freshness,
          YouTubePublicSearchFreshness.invalidated,
        );
      }
    });

    test(
      'future timestamp, corrupt JSON and oversized bytes invalidate',
      () async {
        await repository.write(_snapshot(now));
        final envelope =
            jsonDecode(
                  store.values[DurableYouTubePublicSearchStateRepository
                      .storageKey]!,
                )
                as Map<String, dynamic>;
        envelope['capturedAtUtc'] = now
            .add(const Duration(microseconds: 1))
            .toIso8601String();
        store.values[DurableYouTubePublicSearchStateRepository.storageKey] =
            jsonEncode(envelope);
        expect(
          (await repository.read()).freshness,
          YouTubePublicSearchFreshness.invalidated,
        );

        store.values[DurableYouTubePublicSearchStateRepository.storageKey] =
            '{';
        expect(
          (await repository.read()).freshness,
          YouTubePublicSearchFreshness.invalidated,
        );

        store.values[DurableYouTubePublicSearchStateRepository.storageKey] =
            'x' * ((512 * 1024) + 1);
        expect(
          (await repository.read()).freshness,
          YouTubePublicSearchFreshness.invalidated,
        );
      },
    );

    test(
      'rejects query, result count, offset and item bounds before write',
      () async {
        final invalid = <YouTubePublicSearchSnapshot>[
          _snapshot(now, query: 'q' * 257),
          _snapshot(now, offset: double.infinity),
          _snapshot(now, offset: 10000001),
          YouTubePublicSearchSnapshot(
            submittedQuery: 'many',
            results: List.generate(21, (index) => _item('video-$index')),
            searchSurfaceOpen: true,
            resultsScrollOffset: 0,
            capturedAtUtc: now,
          ),
          YouTubePublicSearchSnapshot(
            submittedQuery: 'duplicate',
            results: [_item('same'), _item('same')],
            searchSurfaceOpen: true,
            resultsScrollOffset: 0,
            capturedAtUtc: now,
          ),
        ];
        for (final snapshot in invalid) {
          await expectLater(
            repository.write(snapshot),
            throwsA(isA<YouTubePublicSearchPersistenceException>()),
          );
        }
        expect(store.writeCount, 0);
      },
    );

    test(
      'write/read/remove failures are sanitized and queue recovers',
      () async {
        store.throwNextWrite = StateError('private write detail');
        final writeError = await _capture(repository.write(_snapshot(now)));
        expect(writeError.toString(), isNot(contains('private write detail')));

        await repository.write(_snapshot(now));
        store.throwNextRead = StateError('private read detail');
        final readError = await _capture(repository.read());
        expect(readError.toString(), isNot(contains('private read detail')));

        store.throwNextRemove = StateError('private remove detail');
        final removeError = await _capture(repository.clear());
        expect(
          removeError.toString(),
          isNot(contains('private remove detail')),
        );
        await repository.clear();
        expect(
          (await repository.read()).freshness,
          YouTubePublicSearchFreshness.missing,
        );
      },
    );

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
        YouTubePublicSearchFreshness.missing,
      );
    });

    test(
      'opaque principal mismatch invalidates before returning state',
      () async {
        await repository.write(_snapshot(now, query: 'first account query'));
        final secondAccount = DurableYouTubePublicSearchStateRepository(
          persistence: store,
          principalBinding: _binding('b'),
          now: () => now,
        );

        final read = await secondAccount.read();

        expect(read.freshness, YouTubePublicSearchFreshness.invalidated);
        expect(read.snapshot, isNull);
        expect(
          store.values,
          isNot(contains(DurableYouTubePublicSearchStateRepository.storageKey)),
        );
      },
    );

    test(
      'failed deletion leaves a tombstone that blocks relaunch restore',
      () async {
        await repository.write(_snapshot(now, query: 'must not resurrect'));
        store.throwNextRemove = StateError('delete unavailable');
        await expectLater(
          repository.clear(),
          throwsA(isA<YouTubePublicSearchPersistenceException>()),
        );
        expect(
          store.values[DurableYouTubePublicSearchStateRepository
              .invalidationKey],
          '1',
        );

        final relaunched = DurableYouTubePublicSearchStateRepository(
          persistence: store,
          principalBinding: _binding(),
          now: () => now,
        );
        final read = await relaunched.read();

        expect(read.freshness, YouTubePublicSearchFreshness.invalidated);
        expect(read.snapshot, isNull);
        expect(
          store.values,
          isNot(contains(DurableYouTubePublicSearchStateRepository.storageKey)),
        );
      },
    );

    test('envelope has no account, auth, playback, or media fields', () async {
      await repository.write(_snapshot(now));
      final envelope =
          jsonDecode(
                store.values[DurableYouTubePublicSearchStateRepository
                    .storageKey]!,
              )
              as Map<String, dynamic>;
      final raw = jsonEncode(envelope).toLowerCase();
      for (final forbidden in [
        'token',
        'credential',
        'cookie',
        'authorization',
        'uid',
        'email',
        'playback',
        'active_short',
        'media_bytes',
      ]) {
        expect(raw, isNot(contains(forbidden)));
      }
    });
  });

  group('YouTubePublicSearchStateCache', () {
    test('new cache instance hydrates persisted process state', () async {
      final now = DateTime.utc(2026, 8, 25, 6);
      final store = _KeyValueStore();
      final firstRepository = DurableYouTubePublicSearchStateRepository(
        persistence: store,
        principalBinding: _binding(),
        now: () => now,
      );
      final first = YouTubePublicSearchStateCache(now: () => now);
      await first.configureDurability(firstRepository);
      first.replace(submittedQuery: 'India news', results: [_item('video-1')]);
      first.updateScrollOffset(222);
      await first.settleDurableWrites();

      final relaunched = YouTubePublicSearchStateCache(now: () => now);
      expect(
        await relaunched.configureDurability(
          DurableYouTubePublicSearchStateRepository(
            persistence: store,
            principalBinding: _binding(),
            now: () => now,
          ),
        ),
        YouTubePublicSearchFreshness.fresh,
      );
      expect(relaunched.snapshot?.submittedQuery, 'India news');
      expect(relaunched.snapshot?.resultsScrollOffset, 222);
      expect(relaunched.snapshot?.results.single.videoId, 'video-1');
    });

    test('newer replace and clear fence delayed hydration', () async {
      final repository = _SearchRepositoryFake();
      final gate = Completer<void>();
      repository.readGate = gate;
      repository.readValue = YouTubePublicSearchRead(
        freshness: YouTubePublicSearchFreshness.fresh,
        snapshot: _snapshot(DateTime.utc(2026, 8, 25, 6), query: 'old'),
      );
      final cache = YouTubePublicSearchStateCache(
        now: () => DateTime.utc(2026, 8, 25, 6),
      );
      final hydration = cache.configureDurability(repository);
      await repository.readStarted.future;
      cache.replace(submittedQuery: 'new', results: [_item('new')]);
      gate.complete();
      await hydration;
      expect(cache.snapshot?.submittedQuery, 'new');

      await cache.clear();
      expect(cache.snapshot, isNull);
      expect(repository.clears, 1);
    });

    test(
      'stale hydration is reported and never exposed as current state',
      () async {
        final repository = _SearchRepositoryFake()
          ..readValue = YouTubePublicSearchRead(
            freshness: YouTubePublicSearchFreshness.stale,
            snapshot: _snapshot(DateTime.utc(2026, 8, 25, 6)),
          );
        final cache = YouTubePublicSearchStateCache();

        expect(
          await cache.configureDurability(repository),
          YouTubePublicSearchFreshness.stale,
        );
        expect(cache.snapshot, isNull);
      },
    );

    test(
      'auth detach cancels debounced write and prevents cross-user writes',
      () async {
        final repository = _SearchRepositoryFake();
        final cache = YouTubePublicSearchStateCache();
        await cache.configureDurability(repository);
        cache.replace(submittedQuery: 'first', results: [_item('first')]);
        cache.updateScrollOffset(50);
        repository.clearFailure = StateError('secure delete failed');

        await cache.clear(detachRepository: true);
        cache.replace(submittedQuery: 'second', results: [_item('second')]);
        await Future<void>.delayed(const Duration(milliseconds: 300));
        await cache.settleDurableWrites();

        expect(cache.snapshot?.submittedQuery, 'second');
        expect(repository.writes, 1);
        expect(repository.clears, 1);

        final reboundRepository = _SearchRepositoryFake();
        final bindingAttempt = cache.beginPrincipalBindingAttempt();
        expect(
          await cache.configureDurability(
            reboundRepository,
            bindingAttempt: bindingAttempt,
          ),
          YouTubePublicSearchFreshness.missing,
        );
        cache.replace(submittedQuery: 'rebound', results: [_item('rebound')]);
        await cache.settleDurableWrites();
        expect(reboundRepository.writes, 1);
      },
    );

    test(
      'verified bind persists Search submitted during receipt wait',
      () async {
        final cache = YouTubePublicSearchStateCache();
        final bindingAttempt = cache.beginPrincipalBindingAttempt();
        cache.replace(
          submittedQuery: 'during verified bind',
          results: [_item('during-bind')],
        );
        final repository = _SearchRepositoryFake();

        expect(
          await cache.configureDurability(
            repository,
            bindingAttempt: bindingAttempt,
          ),
          YouTubePublicSearchFreshness.missing,
        );
        expect(repository.writes, 1);
        expect(repository.lastWrite?.submittedQuery, 'during verified bind');

        final relaunchedRepository = _SearchRepositoryFake()
          ..readValue = YouTubePublicSearchRead(
            freshness: YouTubePublicSearchFreshness.fresh,
            snapshot: repository.lastWrite,
          );
        final relaunched = YouTubePublicSearchStateCache();
        expect(
          await relaunched.configureDurability(relaunchedRepository),
          YouTubePublicSearchFreshness.fresh,
        );
        expect(relaunched.snapshot?.submittedQuery, 'during verified bind');
      },
    );
  });
}

final class _KeyValueStore implements YouTubePublicCatalogueKeyValueStore {
  final Map<String, String> values = {};
  Object? throwNextRead;
  Object? throwNextWrite;
  Object? throwNextRemove;
  Completer<void>? writeGate;
  Completer<void> writeStarted = Completer<void>();
  int writeCount = 0;

  @override
  Future<String?> readString(String key) async {
    final error = throwNextRead;
    throwNextRead = null;
    if (error != null) throw error;
    return values[key];
  }

  @override
  Future<bool> writeString(String key, String value) async {
    writeCount += 1;
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
    final error = throwNextRemove;
    throwNextRemove = null;
    if (error != null) throw error;
    values.remove(key);
    return true;
  }
}

final class _SearchRepositoryFake
    implements YouTubePublicSearchStateRepository {
  final Completer<void> readStarted = Completer<void>();
  Completer<void>? readGate;
  YouTubePublicSearchRead readValue = const YouTubePublicSearchRead(
    freshness: YouTubePublicSearchFreshness.missing,
  );
  int clears = 0;
  int writes = 0;
  Object? clearFailure;
  YouTubePublicSearchSnapshot? lastWrite;

  @override
  Future<YouTubePublicSearchRead> read() async {
    readStarted.complete();
    if (readGate case final gate?) await gate.future;
    return readValue;
  }

  @override
  Future<void> write(YouTubePublicSearchSnapshot snapshot) async {
    writes += 1;
    lastWrite = snapshot;
  }

  @override
  Future<void> clear() async {
    clears += 1;
    final failure = clearFailure;
    clearFailure = null;
    if (failure != null) throw failure;
  }
}

YouTubePublicSearchSnapshot _snapshot(
  DateTime capturedAt, {
  String query = 'India news',
  double offset = 0,
}) => YouTubePublicSearchSnapshot(
  submittedQuery: query,
  results: [_item('video-1')],
  searchSurfaceOpen: true,
  resultsScrollOffset: offset,
  capturedAtUtc: capturedAt,
);

YouTubePublicCatalogueItem _item(String id) => YouTubePublicCatalogueItem(
  videoId: id,
  title: 'Title $id',
  channelId: 'channel-$id',
  channelTitle: 'Channel',
  description: 'Description',
  thumbnailUrl: Uri.parse('https://example.test/$id.jpg'),
  publishedAt: DateTime.utc(2026, 8, 24),
  duration: 'PT2M',
  captionAvailable: true,
  viewCount: '100',
  likeCount: '10',
  commentCount: '1',
  embeddable: true,
  hasKnownDeviceRegionExclusion: false,
  hashtags: const ['#news'],
  channelDescription: 'Channel description',
  channelThumbnailUrl: Uri.parse('https://example.test/channel.jpg'),
  subscriberCount: '1000',
  channelVideoCount: '50',
  channelViewCount: '50000',
);

void _expectItem(
  YouTubePublicCatalogueItem actual,
  YouTubePublicCatalogueItem expected,
) {
  expect(actual.videoId, expected.videoId);
  expect(actual.title, expected.title);
  expect(actual.channelId, expected.channelId);
  expect(actual.channelTitle, expected.channelTitle);
  expect(actual.description, expected.description);
  expect(actual.thumbnailUrl, expected.thumbnailUrl);
  expect(actual.publishedAt, expected.publishedAt);
  expect(actual.duration, expected.duration);
  expect(actual.captionAvailable, expected.captionAvailable);
  expect(actual.viewCount, expected.viewCount);
  expect(actual.likeCount, expected.likeCount);
  expect(actual.commentCount, expected.commentCount);
  expect(actual.hashtags, expected.hashtags);
  expect(actual.channelDescription, expected.channelDescription);
  expect(actual.channelThumbnailUrl, expected.channelThumbnailUrl);
  expect(actual.subscriberCount, expected.subscriberCount);
  expect(actual.channelVideoCount, expected.channelVideoCount);
  expect(actual.channelViewCount, expected.channelViewCount);
}

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
