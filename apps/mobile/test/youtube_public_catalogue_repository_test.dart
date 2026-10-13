import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/shared/youtube_public_catalogue_repository.dart';

void main() {
  group('DurableYouTubePublicCatalogueRepository', () {
    late DateTime clock;
    late _MemoryStore store;
    late DurableYouTubePublicCatalogueRepository repository;

    setUp(() {
      clock = DateTime.utc(2026, 8, 25, 6);
      store = _MemoryStore();
      repository = DurableYouTubePublicCatalogueRepository(
        persistence: store,
        now: () => clock,
      );
    });

    test('public item codec round-trips exact fields and rejects drift', () {
      const codec = YouTubePublicCatalogueItemJsonCodec();
      final source = _item('codec-video');
      final encoded = codec.encode(source);
      _expectItem(codec.decode(encoded), source);

      expect(
        () => codec.decode({...encoded, 'unknown': true}),
        throwsA(isA<YouTubePublicCatalogueItemCodecException>()),
      );
      expect(
        () => codec.decode({...encoded}..remove('description')),
        throwsA(isA<YouTubePublicCatalogueItemCodecException>()),
      );
    });

    test(
      'rejects noncanonical region and unbounded retention configuration',
      () {
        expect(
          () => DurableYouTubePublicCatalogueRepository(
            persistence: store,
            regionCode: 'in',
          ),
          throwsArgumentError,
        );
        expect(
          () => DurableYouTubePublicCatalogueRepository(
            persistence: store,
            maximumAge: const Duration(hours: 25),
          ),
          throwsArgumentError,
        );
      },
    );

    test('round-trips a complete videos item exactly', () async {
      final item = _item('video-1');

      await repository.replace(YouTubePublicCatalogueKind.videos, [item]);
      final result = await repository.read(YouTubePublicCatalogueKind.videos);

      expect(result.freshness, YouTubeCatalogueFreshness.fresh);
      expect(result.snapshot?.kind, YouTubePublicCatalogueKind.videos);
      expect(result.snapshot?.capturedAtUtc, clock);
      _expectItem(result.snapshot!.items.single, item);
    });

    test('round-trips a shorts item with nullable fields absent', () async {
      final item = _item(
        'short-1',
        duration: null,
        captionAvailable: null,
        viewCount: null,
        likeCount: null,
        commentCount: null,
        withChannelDetails: false,
      );

      await repository.replace(YouTubePublicCatalogueKind.shorts, [item]);
      final result = await repository.read(YouTubePublicCatalogueKind.shorts);

      expect(result.freshness, YouTubeCatalogueFreshness.fresh);
      _expectItem(result.snapshot!.items.single, item);
    });

    test('videos and shorts have independent keys and replacements', () async {
      await repository.replace(YouTubePublicCatalogueKind.videos, [
        _item('video-1'),
      ]);
      await repository.replace(YouTubePublicCatalogueKind.shorts, [
        _item('short-1'),
      ]);

      final shortsBefore = store
          .values[DurableYouTubePublicCatalogueRepository.shortsStorageKey];
      await repository.replace(YouTubePublicCatalogueKind.videos, [
        _item('video-2'),
      ]);

      expect(
        store.values.keys,
        containsAll(<String>[
          DurableYouTubePublicCatalogueRepository.videosStorageKey,
          DurableYouTubePublicCatalogueRepository.shortsStorageKey,
        ]),
      );
      expect(
        store.values[DurableYouTubePublicCatalogueRepository.shortsStorageKey],
        shortsBefore,
      );
      expect(
        (await repository.read(
          YouTubePublicCatalogueKind.videos,
        )).snapshot?.items.single.videoId,
        'video-2',
      );
      expect(
        (await repository.read(
          YouTubePublicCatalogueKind.shorts,
        )).snapshot?.items.single.videoId,
        'short-1',
      );
    });

    test('empty replacement truthfully replaces nonempty content', () async {
      await repository.replace(YouTubePublicCatalogueKind.videos, [
        _item('video-1'),
      ]);
      clock = clock.add(const Duration(minutes: 1));
      await repository.replace(YouTubePublicCatalogueKind.videos, const []);

      final result = await repository.read(YouTubePublicCatalogueKind.videos);
      expect(result.snapshot?.items, isEmpty);
      expect(result.snapshot?.capturedAtUtc, clock);
    });

    test('is fresh at the exact TTL boundary', () async {
      await repository.replace(YouTubePublicCatalogueKind.videos, [
        _item('video-1'),
      ]);
      clock = clock.add(const Duration(minutes: 5));

      expect(
        (await repository.read(YouTubePublicCatalogueKind.videos)).freshness,
        YouTubeCatalogueFreshness.fresh,
      );
    });

    test('is explicitly stale one millisecond beyond TTL', () async {
      final capturedAt = clock;
      await repository.replace(YouTubePublicCatalogueKind.videos, [
        _item('video-1'),
      ]);
      clock = clock.add(const Duration(minutes: 5, milliseconds: 1));

      final first = await repository.read(YouTubePublicCatalogueKind.videos);
      clock = clock.add(const Duration(hours: 1));
      final second = await repository.read(YouTubePublicCatalogueKind.videos);

      expect(first.freshness, YouTubeCatalogueFreshness.stale);
      expect(first.snapshot?.capturedAtUtc, capturedAt);
      expect(second.snapshot?.capturedAtUtc, capturedAt);
    });

    test('expires beyond maximum age and deletes only exact key', () async {
      store.values['unrelated'] = 'preserve';
      await repository.replace(YouTubePublicCatalogueKind.videos, [
        _item('video-1'),
      ]);
      await repository.replace(YouTubePublicCatalogueKind.shorts, [
        _item('short-1'),
      ]);
      clock = clock.add(const Duration(hours: 24, milliseconds: 1));

      final result = await repository.read(YouTubePublicCatalogueKind.videos);

      expect(result.freshness, YouTubeCatalogueFreshness.expired);
      expect(result.snapshot, isNull);
      expect(
        store.values,
        isNot(
          contains(DurableYouTubePublicCatalogueRepository.videosStorageKey),
        ),
      );
      expect(
        store.values,
        contains(DurableYouTubePublicCatalogueRepository.shortsStorageKey),
      );
      expect(store.values['unrelated'], 'preserve');
    });

    test('future timestamp invalidates and deletes exact key', () async {
      await repository.replace(YouTubePublicCatalogueKind.videos, [
        _item('video-1'),
      ]);
      final envelope = _envelope(store, YouTubePublicCatalogueKind.videos);
      envelope['capturedAtUtc'] = clock
          .add(const Duration(milliseconds: 1))
          .toIso8601String();
      _setEnvelope(store, YouTubePublicCatalogueKind.videos, envelope);

      final result = await repository.read(YouTubePublicCatalogueKind.videos);

      expect(result.freshness, YouTubeCatalogueFreshness.invalidated);
      expect(result.snapshot, isNull);
      expect(
        store.values,
        isNot(
          contains(DurableYouTubePublicCatalogueRepository.videosStorageKey),
        ),
      );
    });

    test(
      'a new repository instance restores exact process-death state',
      () async {
        final item = _item('video-1');
        await repository.replace(YouTubePublicCatalogueKind.videos, [item]);

        final relaunched = DurableYouTubePublicCatalogueRepository(
          persistence: store,
          now: () => clock,
        );
        final result = await relaunched.read(YouTubePublicCatalogueKind.videos);

        expect(result.freshness, YouTubeCatalogueFreshness.fresh);
        _expectItem(result.snapshot!.items.single, item);
      },
    );

    test(
      'corrupt JSON invalidates one kind without poisoning the other',
      () async {
        await repository.replace(YouTubePublicCatalogueKind.shorts, [
          _item('short-1'),
        ]);
        store.values[DurableYouTubePublicCatalogueRepository.videosStorageKey] =
            '{corrupt';

        expect(
          (await repository.read(YouTubePublicCatalogueKind.videos)).freshness,
          YouTubeCatalogueFreshness.invalidated,
        );
        expect(
          (await repository.read(
            YouTubePublicCatalogueKind.shorts,
          )).snapshot?.items.single.videoId,
          'short-1',
        );
      },
    );

    test(
      'invalid persisted variants fail closed and clear exact key',
      () async {
        final mutations = <String, void Function(Map<String, dynamic>)>{
          'wrong schema': (value) => value['schema'] = 'wrong',
          'wrong version': (value) => value['version'] = 2,
          'non-integer version': (value) => value['version'] = 1.0,
          'wrong kind': (value) => value['kind'] = 'shorts',
          'wrong region': (value) => value['regionCode'] = 'US',
          'missing field': (value) => value.remove('capturedAtUtc'),
          'unknown field': (value) => value['unknown'] = true,
          'invalid items type': (value) => value['items'] = <String, Object>{},
          'invalid date': (value) => value['capturedAtUtc'] = 'not-a-date',
          'non-UTC date': (value) =>
              value['capturedAtUtc'] = '2026-08-25T06:00:00.000+00:00',
          'item unknown field': (value) =>
              (value['items'] as List).cast<Map>().single['unknown'] = true,
          'item missing field': (value) =>
              (value['items'] as List).cast<Map>().single.remove('description'),
          'invalid URL': (value) =>
              (value['items'] as List).cast<Map>().single['thumbnailUrl'] =
                  'http://example.invalid/image.jpg',
          'credential URL': (value) =>
              (value['items'] as List).cast<Map>().single['thumbnailUrl'] =
                  'https://user:pass@example.invalid/image.jpg',
          'invalid count': (value) =>
              (value['items'] as List).cast<Map>().single['viewCount'] = '1.2',
          'invalid bool': (value) =>
              (value['items'] as List).cast<Map>().single['embeddable'] = 'yes',
          'ineligible item': (value) =>
              (value['items'] as List).cast<Map>().single['embeddable'] = false,
          'excluded item': (value) =>
              (value['items'] as List)
                      .cast<Map>()
                      .single['hasKnownDeviceRegionExclusion'] =
                  true,
          'duplicate ID': (value) => (value['items'] as List).add(
            Map<String, dynamic>.from(
              (value['items'] as List).cast<Map>().single,
            ),
          ),
        };

        for (final entry in mutations.entries) {
          await repository.replace(YouTubePublicCatalogueKind.videos, [
            _item('video-1'),
          ]);
          final value = _envelope(store, YouTubePublicCatalogueKind.videos);
          entry.value(value);
          _setEnvelope(store, YouTubePublicCatalogueKind.videos, value);

          final result = await repository.read(
            YouTubePublicCatalogueKind.videos,
          );
          expect(
            result.freshness,
            YouTubeCatalogueFreshness.invalidated,
            reason: entry.key,
          );
          expect(
            store.values,
            isNot(
              contains(
                DurableYouTubePublicCatalogueRepository.videosStorageKey,
              ),
            ),
            reason: entry.key,
          );
        }
      },
    );

    test(
      'too many items and oversized UTF-8 persisted data fail closed',
      () async {
        await repository.replace(YouTubePublicCatalogueKind.videos, [
          _item('video-1'),
        ]);
        final tooMany = _envelope(store, YouTubePublicCatalogueKind.videos);
        tooMany['items'] = List<Object>.generate(
          21,
          (index) => _itemJson('video-$index'),
        );
        _setEnvelope(store, YouTubePublicCatalogueKind.videos, tooMany);
        expect(
          (await repository.read(YouTubePublicCatalogueKind.videos)).freshness,
          YouTubeCatalogueFreshness.invalidated,
        );

        store.values[DurableYouTubePublicCatalogueRepository.videosStorageKey] =
            'x' * ((512 * 1024) + 1);
        expect(
          (await repository.read(YouTubePublicCatalogueKind.videos)).freshness,
          YouTubeCatalogueFreshness.invalidated,
        );
      },
    );

    test('invalid input is rejected before storage write', () async {
      final invalid = <YouTubePublicCatalogueItem>[
        _item(''),
        _item('video-1', embeddable: false),
        _item('video-1', hasKnownDeviceRegionExclusion: true),
        _item('video-1', thumbnailUrl: Uri.parse('http://example.test/a')),
        _item('video-1', viewCount: 'one'),
        _item('video-1', hashtags: ['#1', '#2', '#3', '#4']),
      ];

      for (final item in invalid) {
        await expectLater(
          repository.replace(YouTubePublicCatalogueKind.videos, [item]),
          throwsA(
            isA<YouTubePublicCataloguePersistenceException>().having(
              (error) => error.code,
              'code',
              'invalid_input',
            ),
          ),
        );
      }
      await expectLater(
        repository.replace(
          YouTubePublicCatalogueKind.videos,
          List<YouTubePublicCatalogueItem>.generate(
            21,
            (index) => _item('video-$index'),
          ),
        ),
        throwsA(isA<YouTubePublicCataloguePersistenceException>()),
      );
      expect(store.writeCount, 0);
    });

    test(
      'failed write leaves previously committed snapshot authoritative',
      () async {
        await repository.replace(YouTubePublicCatalogueKind.videos, [
          _item('video-1'),
        ]);
        store.failNextWrite = true;

        await expectLater(
          repository.replace(YouTubePublicCatalogueKind.videos, [
            _item('video-2'),
          ]),
          throwsA(
            isA<YouTubePublicCataloguePersistenceException>().having(
              (error) => error.code,
              'code',
              'write_failed',
            ),
          ),
        );
        expect(
          (await repository.read(
            YouTubePublicCatalogueKind.videos,
          )).snapshot?.items.single.videoId,
          'video-1',
        );
      },
    );

    test('throwing storage failures expose only sanitized errors', () async {
      store.throwNextWrite = StateError('private storage detail');

      final error = await _captureError(
        repository.replace(YouTubePublicCatalogueKind.videos, [
          _item('video-1'),
        ]),
      );

      expect(error, isA<YouTubePublicCataloguePersistenceException>());
      expect(error.toString(), isNot(contains('private storage detail')));
      expect(error.toString(), contains('write_failed'));
    });

    test('failed corrupt-data removal returns sanitized failure', () async {
      store.values[DurableYouTubePublicCatalogueRepository.videosStorageKey] =
          '{corrupt';
      store.throwNextRemove = StateError('private remove detail');

      final error = await _captureError(
        repository.read(YouTubePublicCatalogueKind.videos),
      );

      expect(error, isA<YouTubePublicCataloguePersistenceException>());
      expect(error.toString(), isNot(contains('private remove detail')));
      expect(error.toString(), contains('remove_failed'));
    });

    test(
      'false remove and throwing read are sanitized and do not poison queue',
      () async {
        await repository.replace(YouTubePublicCatalogueKind.videos, [
          _item('video-1'),
        ]);
        store.failNextRemove = true;
        final removeError = await _captureError(
          repository.clear(YouTubePublicCatalogueKind.videos),
        );
        expect(
          (removeError as YouTubePublicCataloguePersistenceException).code,
          'remove_failed',
        );

        store.throwNextRead = StateError('private read detail');
        final readError = await _captureError(
          repository.read(YouTubePublicCatalogueKind.videos),
        );
        expect(
          (readError as YouTubePublicCataloguePersistenceException).code,
          'read_failed',
        );
        expect(readError.toString(), isNot(contains('private read detail')));

        await repository.replace(YouTubePublicCatalogueKind.videos, [
          _item('video-2'),
        ]);
        expect(
          (await repository.read(
            YouTubePublicCatalogueKind.videos,
          )).snapshot?.items.single.videoId,
          'video-2',
        );
      },
    );

    test(
      'clear one kind preserves the other and unrelated preferences',
      () async {
        store.values['unrelated'] = 'preserve';
        await repository.replace(YouTubePublicCatalogueKind.videos, [
          _item('video-1'),
        ]);
        await repository.replace(YouTubePublicCatalogueKind.shorts, [
          _item('short-1'),
        ]);

        await repository.clear(YouTubePublicCatalogueKind.videos);

        expect(
          (await repository.read(YouTubePublicCatalogueKind.videos)).freshness,
          YouTubeCatalogueFreshness.missing,
        );
        expect(
          (await repository.read(YouTubePublicCatalogueKind.shorts)).freshness,
          YouTubeCatalogueFreshness.fresh,
        );
        expect(store.values['unrelated'], 'preserve');
      },
    );

    test('clearAll deletes only the two repository keys', () async {
      store.values['unrelated'] = 'preserve';
      await repository.replace(YouTubePublicCatalogueKind.videos, [
        _item('video-1'),
      ]);
      await repository.replace(YouTubePublicCatalogueKind.shorts, [
        _item('short-1'),
      ]);

      await repository.clearAll();

      expect(store.values, {'unrelated': 'preserve'});
    });

    test('partial clearAll failure is sanitized and retry-safe', () async {
      store.values['unrelated'] = 'preserve';
      await repository.replace(YouTubePublicCatalogueKind.videos, [
        _item('video-1'),
      ]);
      await repository.replace(YouTubePublicCatalogueKind.shorts, [
        _item('short-1'),
      ]);
      store.failRemoveKeyOnce =
          DurableYouTubePublicCatalogueRepository.shortsStorageKey;

      await expectLater(
        repository.clearAll(),
        throwsA(isA<YouTubePublicCataloguePersistenceException>()),
      );
      expect(
        store.values,
        isNot(
          contains(DurableYouTubePublicCatalogueRepository.videosStorageKey),
        ),
      );
      expect(
        store.values,
        contains(DurableYouTubePublicCatalogueRepository.shortsStorageKey),
      );
      expect(store.values['unrelated'], 'preserve');

      await repository.clearAll();
      expect(store.values, {'unrelated': 'preserve'});
    });

    test('delayed replacements are linearized in invocation order', () async {
      final gate = Completer<void>();
      store.nextWriteGate = gate;
      final first = repository.replace(YouTubePublicCatalogueKind.videos, [
        _item('video-1'),
      ]);
      await store.writeStarted.future;
      final second = repository.replace(YouTubePublicCatalogueKind.videos, [
        _item('video-2'),
      ]);

      gate.complete();
      await Future.wait([first, second]);

      expect(
        (await repository.read(
          YouTubePublicCatalogueKind.videos,
        )).snapshot?.items.single.videoId,
        'video-2',
      );
    });

    test(
      'separate repository instances share write and read ordering',
      () async {
        final secondRepository = DurableYouTubePublicCatalogueRepository(
          persistence: store,
          now: () => clock,
        );
        final gate = Completer<void>();
        store.nextWriteGate = gate;
        final first = repository.replace(YouTubePublicCatalogueKind.videos, [
          _item('video-1'),
        ]);
        await store.writeStarted.future;
        final second = secondRepository.replace(
          YouTubePublicCatalogueKind.videos,
          [_item('video-2')],
        );
        final queuedRead = repository.read(YouTubePublicCatalogueKind.videos);

        gate.complete();
        await Future.wait([first, second]);
        expect((await queuedRead).snapshot?.items.single.videoId, 'video-2');
      },
    );

    test('interleaved videos and shorts replacements both survive', () async {
      final gate = Completer<void>();
      store.nextWriteGate = gate;
      final videos = repository.replace(YouTubePublicCatalogueKind.videos, [
        _item('video-1'),
      ]);
      await store.writeStarted.future;
      final shorts = repository.replace(YouTubePublicCatalogueKind.shorts, [
        _item('short-1'),
      ]);
      gate.complete();
      await Future.wait([videos, shorts]);

      expect(
        (await repository.read(
          YouTubePublicCatalogueKind.videos,
        )).snapshot?.items.single.videoId,
        'video-1',
      );
      expect(
        (await repository.read(
          YouTubePublicCatalogueKind.shorts,
        )).snapshot?.items.single.videoId,
        'short-1',
      );
    });

    test('queued clear after delayed write leaves the key absent', () async {
      final gate = Completer<void>();
      store.nextWriteGate = gate;
      final write = repository.replace(YouTubePublicCatalogueKind.videos, [
        _item('video-1'),
      ]);
      await store.writeStarted.future;
      final clear = repository.clear(YouTubePublicCatalogueKind.videos);

      gate.complete();
      await Future.wait([write, clear]);

      expect(
        (await repository.read(YouTubePublicCatalogueKind.videos)).freshness,
        YouTubeCatalogueFreshness.missing,
      );
    });

    test('one failed queued mutation does not poison the next', () async {
      store.failNextWrite = true;
      await expectLater(
        repository.replace(YouTubePublicCatalogueKind.videos, [
          _item('video-1'),
        ]),
        throwsA(isA<YouTubePublicCataloguePersistenceException>()),
      );

      await repository.replace(YouTubePublicCatalogueKind.videos, [
        _item('video-2'),
      ]);
      expect(
        (await repository.read(
          YouTubePublicCatalogueKind.videos,
        )).snapshot?.items.single.videoId,
        'video-2',
      );
    });

    test('queued read after failed write sees prior committed value', () async {
      await repository.replace(YouTubePublicCatalogueKind.videos, [
        _item('video-0'),
      ]);
      store.failNextWrite = true;
      final failedWrite = repository.replace(
        YouTubePublicCatalogueKind.videos,
        [_item('video-1')],
      );
      final queuedRead = repository.read(YouTubePublicCatalogueKind.videos);

      await expectLater(
        failedWrite,
        throwsA(isA<YouTubePublicCataloguePersistenceException>()),
      );
      expect((await queuedRead).snapshot?.items.single.videoId, 'video-0');
    });

    test(
      'caller and returned collections cannot mutate persisted truth',
      () async {
        final sourceHashtags = <String>['#one'];
        final sourceItems = <YouTubePublicCatalogueItem>[
          _item('video-1', hashtags: sourceHashtags),
        ];
        final pending = repository.replace(
          YouTubePublicCatalogueKind.videos,
          sourceItems,
        );
        sourceHashtags.add('#two');
        sourceItems.clear();
        await pending;

        final result = await repository.read(YouTubePublicCatalogueKind.videos);
        expect(result.snapshot?.items.single.hashtags, ['#one']);
        expect(
          () => result.snapshot!.items.add(_item('video-2')),
          throwsUnsupportedError,
        );
        expect(
          () => result.snapshot!.items.single.hashtags.add('#two'),
          throwsUnsupportedError,
        );
      },
    );

    test(
      'payload has no private, account, playback, or media fields',
      () async {
        await repository.replace(YouTubePublicCatalogueKind.videos, [
          _item('video-1'),
        ]);
        final raw = store
            .values[DurableYouTubePublicCatalogueRepository.videosStorageKey]!;
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final itemKeys = ((decoded['items'] as List).single as Map).keys;

        for (final forbidden in <String>[
          'token',
          'credential',
          'cookie',
          'authorization',
          'uid',
          'email',
          'playback',
          'watch',
          'search',
          'activeShort',
          'mediaBytes',
          'base64',
        ]) {
          expect(itemKeys, isNot(contains(forbidden)));
        }
        expect(raw, isNot(contains('data:video/')));
      },
    );

    test(
      'field boundary lengths pass exactly and fail one unit over',
      () async {
        await repository.replace(YouTubePublicCatalogueKind.videos, [
          _item(
            'v' * 128,
            title: 't' * 512,
            description: 'd' * 10000,
            viewCount: '9' * 32,
            hashtags: ['#${'h' * 126}x'],
            thumbnailUrl: _uriAtLength(2048),
          ),
        ]);
        expect(store.writeCount, 1);

        final overBoundary = <YouTubePublicCatalogueItem>[
          _item('v' * 129),
          _item('video-1', title: 't' * 513),
          _item('video-1', description: 'd' * 10001),
          _item('video-1', viewCount: '9' * 33),
          _item('video-1', hashtags: ['h' * 129]),
          _item('video-1', thumbnailUrl: _uriAtLength(2049)),
        ];
        for (final item in overBoundary) {
          await expectLater(
            repository.replace(YouTubePublicCatalogueKind.videos, [item]),
            throwsA(isA<YouTubePublicCataloguePersistenceException>()),
          );
        }
        expect(store.writeCount, 1);
      },
    );
  });
}

final class _MemoryStore implements YouTubePublicCatalogueKeyValueStore {
  final Map<String, String> values = <String, String>{};
  bool failNextWrite = false;
  bool failNextRemove = false;
  String? failRemoveKeyOnce;
  Object? throwNextRead;
  Object? throwNextWrite;
  Object? throwNextRemove;
  Completer<void>? nextWriteGate;
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
    final gate = nextWriteGate;
    nextWriteGate = null;
    if (gate != null) await gate.future;
    final error = throwNextWrite;
    throwNextWrite = null;
    if (error != null) throw error;
    if (failNextWrite) {
      failNextWrite = false;
      return false;
    }
    values[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    final error = throwNextRemove;
    throwNextRemove = null;
    if (error != null) throw error;
    if (failNextRemove) {
      failNextRemove = false;
      return false;
    }
    if (failRemoveKeyOnce == key) {
      failRemoveKeyOnce = null;
      return false;
    }
    values.remove(key);
    return true;
  }
}

YouTubePublicCatalogueItem _item(
  String id, {
  String title = 'Title',
  String description = 'Description',
  String? duration = 'PT1M2S',
  bool? captionAvailable = true,
  String? viewCount = '100',
  String? likeCount = '20',
  String? commentCount = '3',
  bool embeddable = true,
  bool hasKnownDeviceRegionExclusion = false,
  List<String> hashtags = const ['#one', '#two'],
  Uri? thumbnailUrl,
  bool withChannelDetails = true,
}) => YouTubePublicCatalogueItem(
  videoId: id,
  title: title,
  channelId: 'channel-1',
  channelTitle: 'Channel',
  description: description,
  thumbnailUrl: thumbnailUrl ?? Uri.parse('https://example.test/video.jpg'),
  publishedAt: DateTime.utc(2026, 8, 24),
  duration: duration,
  captionAvailable: captionAvailable,
  viewCount: viewCount,
  likeCount: likeCount,
  commentCount: commentCount,
  embeddable: embeddable,
  hasKnownDeviceRegionExclusion: hasKnownDeviceRegionExclusion,
  hashtags: hashtags,
  channelDescription: withChannelDetails ? 'Channel description' : null,
  channelThumbnailUrl: withChannelDetails
      ? Uri.parse('https://example.test/channel.jpg')
      : null,
  subscriberCount: withChannelDetails ? '1000' : null,
  channelVideoCount: withChannelDetails ? '50' : null,
  channelViewCount: withChannelDetails ? '50000' : null,
);

Map<String, dynamic> _envelope(
  _MemoryStore store,
  YouTubePublicCatalogueKind kind,
) => jsonDecode(store.values[_key(kind)]!) as Map<String, dynamic>;

void _setEnvelope(
  _MemoryStore store,
  YouTubePublicCatalogueKind kind,
  Map<String, dynamic> envelope,
) {
  store.values[_key(kind)] = jsonEncode(envelope);
}

String _key(YouTubePublicCatalogueKind kind) => switch (kind) {
  YouTubePublicCatalogueKind.videos =>
    DurableYouTubePublicCatalogueRepository.videosStorageKey,
  YouTubePublicCatalogueKind.shorts =>
    DurableYouTubePublicCatalogueRepository.shortsStorageKey,
};

Map<String, Object?> _itemJson(String id) => <String, Object?>{
  'videoId': id,
  'title': 'Title',
  'channelId': 'channel-1',
  'channelTitle': 'Channel',
  'description': 'Description',
  'thumbnailUrl': 'https://example.test/video.jpg',
  'publishedAt': '2026-08-24T00:00:00.000Z',
  'duration': 'PT1M2S',
  'captionAvailable': true,
  'viewCount': '100',
  'likeCount': '20',
  'commentCount': '3',
  'embeddable': true,
  'hasKnownDeviceRegionExclusion': false,
  'hashtags': <String>['#one'],
  'channelDescription': null,
  'channelThumbnailUrl': null,
  'subscriberCount': null,
  'channelVideoCount': null,
  'channelViewCount': null,
};

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
  expect(actual.embeddable, expected.embeddable);
  expect(
    actual.hasKnownDeviceRegionExclusion,
    expected.hasKnownDeviceRegionExclusion,
  );
  expect(actual.hashtags, expected.hashtags);
  expect(actual.channelDescription, expected.channelDescription);
  expect(actual.channelThumbnailUrl, expected.channelThumbnailUrl);
  expect(actual.subscriberCount, expected.subscriberCount);
  expect(actual.channelVideoCount, expected.channelVideoCount);
  expect(actual.channelViewCount, expected.channelViewCount);
}

Future<Object> _captureError(Future<Object?> future) async {
  try {
    await future;
  } catch (error) {
    return error;
  }
  throw StateError('Expected the future to fail.');
}

Uri _uriAtLength(int length) {
  const prefix = 'https://example.test/';
  return Uri.parse('$prefix${'a' * (length - prefix.length)}');
}
