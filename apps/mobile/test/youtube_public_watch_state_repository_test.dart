import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/shared/youtube_public_catalogue_repository.dart';
import 'package:moolsocial/features/shared/youtube_public_search_state_repository.dart';
import 'package:moolsocial/features/shared/youtube_public_watch_state_repository.dart';

void main() {
  test('bootstrap truth distinguishes usable, empty and degraded reads', () {
    expect(
      youtubePublicWatchHydrationIsDegraded(YouTubePublicWatchFreshness.fresh),
      isFalse,
    );
    expect(
      youtubePublicWatchHydrationIsDegraded(
        YouTubePublicWatchFreshness.missing,
      ),
      isFalse,
    );
    for (final freshness in <YouTubePublicWatchFreshness?>[
      YouTubePublicWatchFreshness.stale,
      YouTubePublicWatchFreshness.expired,
      YouTubePublicWatchFreshness.invalidated,
      null,
    ]) {
      expect(youtubePublicWatchHydrationIsDegraded(freshness), isTrue);
    }
  });

  group('DurableYouTubePublicWatchStateRepository', () {
    late DateTime now;
    late _KeyValueStore store;
    late DurableYouTubePublicWatchStateRepository repository;

    setUp(() {
      now = DateTime.utc(2026, 8, 25, 6);
      store = _KeyValueStore();
      repository = DurableYouTubePublicWatchStateRepository(
        persistence: store,
        principalBinding: _binding(),
        now: () => now,
      );
    });

    test('round-trips selected video, origin and both offsets', () async {
      final snapshot = _snapshot(
        now,
        origin: YouTubePublicWatchOrigin.search,
        searchOriginVideo: _item('origin-video'),
        watchOffset: 123.5,
        homeOffset: 456.25,
      );
      await repository.write(snapshot);

      final read = await repository.read();

      expect(read.freshness, YouTubePublicWatchFreshness.fresh);
      expect(read.snapshot?.origin, YouTubePublicWatchOrigin.search);
      expect(read.snapshot?.watchScrollOffset, 123.5);
      expect(read.snapshot?.homeScrollOffset, 456.25);
      expect(read.snapshot?.searchOriginVideo?.videoId, 'origin-video');
      _expectItem(read.snapshot!.selectedVideo, snapshot.selectedVideo);
    });

    test(
      'a new repository instance restores the prior process state',
      () async {
        await repository.write(_snapshot(now, videoId: 'process-one'));

        final relaunched = DurableYouTubePublicWatchStateRepository(
          persistence: store,
          principalBinding: _binding(),
          now: () => now,
        );

        expect(
          (await relaunched.read()).snapshot?.selectedVideo.videoId,
          'process-one',
        );
      },
    );

    test('preserves fresh boundary and reports stale truth', () async {
      await repository.write(_snapshot(now));
      now = now.add(const Duration(minutes: 5));
      expect(
        (await repository.read()).freshness,
        YouTubePublicWatchFreshness.fresh,
      );

      now = now.add(const Duration(microseconds: 1));
      final stale = await repository.read();
      expect(stale.freshness, YouTubePublicWatchFreshness.stale);
      expect(stale.snapshot, isNotNull);
    });

    test(
      'expires after hard age and preserves unrelated secure data',
      () async {
        store.values['unrelated'] = 'preserve';
        await repository.write(_snapshot(now));
        now = now.add(const Duration(hours: 24, microseconds: 1));

        expect(
          (await repository.read()).freshness,
          YouTubePublicWatchFreshness.expired,
        );
        expect(store.values['unrelated'], 'preserve');
        expect(
          store.values,
          isNot(contains(DurableYouTubePublicWatchStateRepository.storageKey)),
        );
      },
    );

    test('wrong principal binding invalidates and removes state', () async {
      await repository.write(_snapshot(now));
      final otherAccount = DurableYouTubePublicWatchStateRepository(
        persistence: store,
        principalBinding: _binding('b'),
        now: () => now,
      );

      expect(
        (await otherAccount.read()).freshness,
        YouTubePublicWatchFreshness.invalidated,
      );
      expect(
        store.values,
        isNot(contains(DurableYouTubePublicWatchStateRepository.storageKey)),
      );
    });

    test('invalid exact-schema envelopes fail closed', () async {
      final mutations = <void Function(Map<String, dynamic>)>[
        (value) => value['schema'] = 'wrong',
        (value) => value['version'] = 1.0,
        (value) => value['regionCode'] = 'US',
        (value) => value['origin'] = 'shorts',
        (value) => value['watchScrollOffset'] = -1,
        (value) => value['homeScrollOffset'] = 10000001,
        (value) => value['unknown'] = true,
        (value) => value.remove('selectedVideo'),
        (value) =>
            (value['selectedVideo'] as Map<String, dynamic>)['embeddable'] =
                false,
      ];

      for (final mutate in mutations) {
        await repository.write(_snapshot(now));
        final envelope = _storedEnvelope(store);
        mutate(envelope);
        store.values[DurableYouTubePublicWatchStateRepository.storageKey] =
            jsonEncode(envelope);
        expect(
          (await repository.read()).freshness,
          YouTubePublicWatchFreshness.invalidated,
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
        store.values[DurableYouTubePublicWatchStateRepository.storageKey] =
            jsonEncode(future);
        expect(
          (await repository.read()).freshness,
          YouTubePublicWatchFreshness.invalidated,
        );

        store.values[DurableYouTubePublicWatchStateRepository.storageKey] = '{';
        expect(
          (await repository.read()).freshness,
          YouTubePublicWatchFreshness.invalidated,
        );

        store.values[DurableYouTubePublicWatchStateRepository.storageKey] =
            'x' * ((512 * 1024) + 1);
        expect(
          (await repository.read()).freshness,
          YouTubePublicWatchFreshness.invalidated,
        );
      },
    );

    test('rejects invalid offsets and ineligible video before write', () async {
      final invalid = <YouTubePublicWatchSnapshot>[
        _snapshot(now, watchOffset: double.infinity),
        _snapshot(now, homeOffset: -1),
        YouTubePublicWatchSnapshot(
          selectedVideo: _item('blocked', embeddable: false),
          origin: YouTubePublicWatchOrigin.home,
          watchScrollOffset: 0,
          homeScrollOffset: 0,
          capturedAtUtc: now,
        ),
        _snapshot(
          now,
          origin: YouTubePublicWatchOrigin.home,
          searchOriginVideo: _item('impossible-origin'),
        ),
      ];

      for (final snapshot in invalid) {
        final error = await _capture(repository.write(snapshot));
        expect(error, isA<YouTubePublicWatchPersistenceException>());
        expect(
          (error as YouTubePublicWatchPersistenceException).code,
          'invalid_input',
        );
      }
    });

    test('rejects invalid repository configuration', () {
      expect(
        () => DurableYouTubePublicWatchStateRepository(
          persistence: store,
          principalBinding: _binding(),
          freshTimeToLive: const Duration(hours: 25),
          maximumAge: const Duration(hours: 24),
        ),
        throwsArgumentError,
      );
      expect(
        () => DurableYouTubePublicWatchStateRepository(
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
        contains(DurableYouTubePublicWatchStateRepository.invalidationKey),
      );

      expect(
        (await repository.read()).freshness,
        YouTubePublicWatchFreshness.invalidated,
      );
      expect(
        store.values,
        isNot(contains(DurableYouTubePublicWatchStateRepository.storageKey)),
      );
    });

    test('unbound invalidation is exact and survives delete failure', () async {
      store.values[DurableYouTubePublicWatchStateRepository.storageKey] =
          'prior-account-state';
      store.values['unrelated'] = 'preserve';
      store.throwNextStorageRemove = StateError('private detail');

      final error = await _capture(
        DurableYouTubePublicWatchStateRepository.invalidateUnbound(store),
      );

      expect(error.toString(), contains('(remove_failed)'));
      expect(error.toString(), isNot(contains('private detail')));
      expect(store.values['unrelated'], 'preserve');
      expect(
        store.values,
        contains(DurableYouTubePublicWatchStateRepository.invalidationKey),
      );
    });

    test(
      'Search and Watch auth invalidation attempts are failure-independent',
      () async {
        final failedSearch = _KeyValueStore()
          ..values[DurableYouTubePublicSearchStateRepository.storageKey] =
              'search'
          ..throwNextStorageRemove = StateError('search delete failed');
        final healthyWatch = _KeyValueStore()
          ..values[DurableYouTubePublicWatchStateRepository.storageKey] =
              'watch';

        final first = await invalidateYouTubePublicRuntimeState(
          searchPersistence: failedSearch,
          watchPersistence: healthyWatch,
        );

        expect(first.search, isFalse);
        expect(first.watch, isTrue);
        expect(
          healthyWatch.values,
          isNot(contains(DurableYouTubePublicWatchStateRepository.storageKey)),
        );

        final healthySearch = _KeyValueStore()
          ..values[DurableYouTubePublicSearchStateRepository.storageKey] =
              'search';
        final failedWatch = _KeyValueStore()
          ..values[DurableYouTubePublicWatchStateRepository.storageKey] =
              'watch'
          ..throwNextStorageRemove = StateError('watch delete failed');
        final second = await invalidateYouTubePublicRuntimeState(
          searchPersistence: healthySearch,
          watchPersistence: failedWatch,
        );

        expect(second.search, isTrue);
        expect(second.watch, isFalse);
        expect(
          healthySearch.values,
          isNot(contains(DurableYouTubePublicSearchStateRepository.storageKey)),
        );
      },
    );

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
      final second = DurableYouTubePublicWatchStateRepository(
        persistence: store,
        principalBinding: _binding(),
        now: () => now,
      );

      final firstWrite = repository.write(_snapshot(now, videoId: 'first'));
      await store.writeStarted.future;
      final secondWrite = second.write(_snapshot(now, videoId: 'second'));
      gate.complete();
      await Future.wait([firstWrite, secondWrite]);

      expect(
        (await repository.read()).snapshot?.selectedVideo.videoId,
        'second',
      );
    });
  });

  group('YouTubePublicWatchStateCache', () {
    late DateTime now;

    setUp(() {
      now = DateTime.utc(2026, 8, 25, 6);
    });

    test('hydrates only a fresh snapshot', () async {
      final fresh = _WatchRepositoryFake()
        ..readValue = YouTubePublicWatchRead(
          freshness: YouTubePublicWatchFreshness.fresh,
          snapshot: _snapshot(now),
        );
      final cache = YouTubePublicWatchStateCache(now: () => now);
      await cache.configureDurability(fresh);
      expect(cache.snapshot?.selectedVideo.videoId, 'video-1');

      final stale = _WatchRepositoryFake()
        ..readValue = YouTubePublicWatchRead(
          freshness: YouTubePublicWatchFreshness.stale,
          snapshot: _snapshot(now),
        );
      final relaunched = YouTubePublicWatchStateCache(now: () => now);
      await relaunched.configureDurability(stale);
      expect(relaunched.snapshot, isNull);
    });

    test('replace persists exact newest selection and origin', () async {
      final repository = _WatchRepositoryFake();
      final cache = YouTubePublicWatchStateCache(now: () => now);
      await cache.configureDurability(repository);

      cache.replace(
        selectedVideo: _item('selected'),
        origin: YouTubePublicWatchOrigin.search,
        watchScrollOffset: 10,
        homeScrollOffset: 20,
      );
      await cache.settleDurableWrites();

      expect(repository.writes, 1);
      expect(repository.lastWrite?.selectedVideo.videoId, 'selected');
      expect(repository.lastWrite?.origin, YouTubePublicWatchOrigin.search);
      expect(repository.lastWrite?.watchScrollOffset, 10);
      expect(repository.lastWrite?.homeScrollOffset, 20);
    });

    test('settle flushes the debounced Watch scroll mutation', () async {
      final repository = _WatchRepositoryFake();
      final cache = YouTubePublicWatchStateCache(now: () => now);
      await cache.configureDurability(repository);
      cache.replace(
        selectedVideo: _item('selected'),
        origin: YouTubePublicWatchOrigin.home,
      );
      await cache.settleDurableWrites();
      repository.writes = 0;

      cache.updateWatchScrollOffset(77.5);
      await cache.settleDurableWrites();

      expect(repository.writes, 1);
      expect(repository.lastWrite?.watchScrollOffset, 77.5);
    });

    test('clear detaches and cannot write into the prior account', () async {
      final repository = _WatchRepositoryFake();
      final cache = YouTubePublicWatchStateCache(now: () => now);
      await cache.configureDurability(repository);

      await cache.clear(detachRepository: true);
      cache.replace(
        selectedVideo: _item('new-account'),
        origin: YouTubePublicWatchOrigin.home,
      );
      await cache.settleDurableWrites();

      expect(cache.snapshot?.selectedVideo.videoId, 'new-account');
      expect(repository.clears, 1);
      expect(repository.writes, 0);
    });

    test(
      'a stale principal binding attempt cannot attach or hydrate',
      () async {
        final oldRepository = _WatchRepositoryFake()
          ..readGate = Completer<void>()
          ..readValue = YouTubePublicWatchRead(
            freshness: YouTubePublicWatchFreshness.fresh,
            snapshot: _snapshot(now, videoId: 'old-account'),
          );
        final currentRepository = _WatchRepositoryFake()
          ..readValue = YouTubePublicWatchRead(
            freshness: YouTubePublicWatchFreshness.fresh,
            snapshot: _snapshot(now, videoId: 'current-account'),
          );
        final cache = YouTubePublicWatchStateCache(now: () => now);
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

        expect(cache.snapshot?.selectedVideo.videoId, 'current-account');
      },
    );

    test('selection during principal read survives and is flushed', () async {
      final repository = _WatchRepositoryFake()
        ..readGate = Completer<void>()
        ..readValue = YouTubePublicWatchRead(
          freshness: YouTubePublicWatchFreshness.fresh,
          snapshot: _snapshot(now, videoId: 'stored'),
        );
      final cache = YouTubePublicWatchStateCache(now: () => now);
      final attempt = cache.beginPrincipalBindingAttempt();
      final binding = cache.configureDurability(
        repository,
        bindingAttempt: attempt,
      );
      await repository.readStarted.future;

      cache.replace(
        selectedVideo: _item('newest'),
        origin: YouTubePublicWatchOrigin.home,
      );
      repository.readGate!.complete();
      await binding;

      expect(cache.snapshot?.selectedVideo.videoId, 'newest');
      expect(repository.lastWrite?.selectedVideo.videoId, 'newest');
    });

    test('clear during principal read cannot resurrect stored state', () async {
      final repository = _WatchRepositoryFake()
        ..readGate = Completer<void>()
        ..readValue = YouTubePublicWatchRead(
          freshness: YouTubePublicWatchFreshness.fresh,
          snapshot: _snapshot(now, videoId: 'stored'),
        );
      final cache = YouTubePublicWatchStateCache(now: () => now);
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

    test('invalid scroll mutations do not alter or persist state', () async {
      final repository = _WatchRepositoryFake();
      final cache = YouTubePublicWatchStateCache(now: () => now);
      await cache.configureDurability(repository);
      cache.replace(
        selectedVideo: _item('selected'),
        origin: YouTubePublicWatchOrigin.home,
        watchScrollOffset: 5,
      );
      await cache.settleDurableWrites();
      repository.writes = 0;

      cache.updateWatchScrollOffset(double.nan);
      cache.updateWatchScrollOffset(-1);
      await cache.settleDurableWrites();

      expect(cache.snapshot?.watchScrollOffset, 5);
      expect(repository.writes, 0);
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

final class _WatchRepositoryFake implements YouTubePublicWatchStateRepository {
  final Completer<void> readStarted = Completer<void>();
  Completer<void>? readGate;
  YouTubePublicWatchRead readValue = const YouTubePublicWatchRead(
    freshness: YouTubePublicWatchFreshness.missing,
  );
  int clears = 0;
  int writes = 0;
  YouTubePublicWatchSnapshot? lastWrite;

  @override
  Future<YouTubePublicWatchRead> read() async {
    if (!readStarted.isCompleted) readStarted.complete();
    if (readGate case final gate?) await gate.future;
    return readValue;
  }

  @override
  Future<void> write(YouTubePublicWatchSnapshot snapshot) async {
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
          store.values[DurableYouTubePublicWatchStateRepository.storageKey]!,
        )
        as Map<String, dynamic>;

YouTubePublicWatchSnapshot _snapshot(
  DateTime capturedAt, {
  String videoId = 'video-1',
  YouTubePublicWatchOrigin origin = YouTubePublicWatchOrigin.home,
  YouTubePublicCatalogueItem? searchOriginVideo,
  double watchOffset = 0,
  double homeOffset = 0,
}) => YouTubePublicWatchSnapshot(
  selectedVideo: _item(videoId),
  origin: origin,
  searchOriginVideo: searchOriginVideo,
  watchScrollOffset: watchOffset,
  homeScrollOffset: homeOffset,
  capturedAtUtc: capturedAt,
);

YouTubePublicCatalogueItem _item(String id, {bool embeddable = true}) =>
    YouTubePublicCatalogueItem(
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
      embeddable: embeddable,
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
