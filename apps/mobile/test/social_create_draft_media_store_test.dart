import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/shared/social_create_draft_media_store.dart';
import 'package:moolsocial/features/shared/social_create_draft_repository.dart';
import 'package:moolsocial/features/shared/social_media_picker.dart';

void main() {
  late Directory sandbox;
  late Directory sourceRoot;
  late Directory privateRoot;
  late SocialCreateDraftMediaStore store;

  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('moolsocial-draft-test-');
    sourceRoot = await Directory('${sandbox.path}/source').create();
    privateRoot = Directory('${sandbox.path}/private');
    store = SocialCreateDraftMediaStore(root: privateRoot);
  });

  tearDown(() async {
    if (await sandbox.exists()) await sandbox.delete(recursive: true);
  });

  test(
    'stages local media under opaque private id and resolves exact bytes',
    () async {
      final source = File('${sourceRoot.path}/personal-name.jpg');
      await source.writeAsBytes([1, 2, 3, 4]);

      final reference = await store.stage(
        SocialPickedMedia(
          path: source.path,
          name: 'personal-name.jpg',
          kind: SocialMediaKind.image,
        ),
      );
      final restored = await store.resolve(reference);

      expect(reference.id, matches(RegExp(r'^[0-9a-f]{32}$')));
      expect(reference.id, isNot(contains('personal-name')));
      expect(reference.byteLength, 4);
      expect(reference.sha256, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(restored?.name, 'personal-name.jpg');
      expect(await File(restored!.path).readAsBytes(), [1, 2, 3, 4]);
    },
  );

  test(
    'tampered or missing staged media is dropped without throwing',
    () async {
      final source = File('${sourceRoot.path}/image.jpg');
      await source.writeAsBytes([1, 2, 3, 4]);
      final reference = await store.stage(
        SocialPickedMedia(
          path: source.path,
          name: 'image.jpg',
          kind: SocialMediaKind.image,
        ),
      );
      final staged = await store.resolve(reference);
      await File(staged!.path).writeAsBytes([9, 9]);
      expect(await store.resolve(reference), isNull);
      await File(staged.path).delete();
      expect(await store.resolve(reference), isNull);
    },
  );

  test(
    'resolveAll drops only invalid references and keeps valid text media',
    () async {
      final source = File('${sourceRoot.path}/valid.jpg');
      await source.writeAsBytes([1, 2, 3]);
      final valid = await store.stage(
        SocialPickedMedia(
          path: source.path,
          name: 'valid.jpg',
          kind: SocialMediaKind.image,
        ),
      );
      const invalid = SocialCreateDraftMediaReference(
        id: '../escape',
        name: 'bad',
        kind: SocialCreateDraftMediaKind.image,
        isAsset: false,
        byteLength: 1,
        sha256: 'bad',
      );

      final result = await store.resolveAll([valid, invalid]);

      expect(result.media, hasLength(1));
      expect(result.droppedCount, 1);
    },
  );

  test('allows only canonical bundled asset references', () async {
    final valid = await store.stage(
      const SocialPickedMedia(
        path: 'assets/prototype/photo.png',
        name: 'photo.png',
        kind: SocialMediaKind.image,
        isAsset: true,
      ),
    );
    expect((await store.resolve(valid))?.isAsset, isTrue);
    await expectLater(
      store.stage(
        const SocialPickedMedia(
          path: 'assets/../secret.png',
          name: 'secret.png',
          kind: SocialMediaKind.image,
          isAsset: true,
        ),
      ),
      throwsFormatException,
    );
  });

  test('clear removes only exact staged owners', () async {
    final source = File('${sourceRoot.path}/image.jpg');
    await source.writeAsBytes([1, 2, 3]);
    final reference = await store.stage(
      SocialPickedMedia(
        path: source.path,
        name: 'image.jpg',
        kind: SocialMediaKind.image,
      ),
    );
    final staged = await store.resolve(reference);
    await store.clear([reference]);
    expect(await File(staged!.path).exists(), isFalse);
    expect(await source.exists(), isTrue);
  });

  test(
    'concurrent staging of one source is single-flight with one file',
    () async {
      final source = File('${sourceRoot.path}/same.jpg');
      await source.writeAsBytes([1, 2, 3, 4]);
      final media = SocialPickedMedia(
        path: source.path,
        name: 'same.jpg',
        kind: SocialMediaKind.image,
      );

      final results = await Future.wait([
        store.stage(media),
        store.stage(media),
      ]);

      expect(results[0].id, results[1].id);
      expect(
        await privateRoot.list().where((entity) => entity is File).length,
        1,
      );
    },
  );

  test('total quota rejects additional staged copies', () async {
    store = SocialCreateDraftMediaStore(
      root: privateRoot,
      maximumBytes: 10,
      maximumTotalBytes: 4,
    );
    final first = File('${sourceRoot.path}/first.jpg');
    final second = File('${sourceRoot.path}/second.jpg');
    await first.writeAsBytes([1, 2, 3]);
    await second.writeAsBytes([4, 5, 6]);
    await store.stage(
      SocialPickedMedia(
        path: first.path,
        name: 'first.jpg',
        kind: SocialMediaKind.image,
      ),
    );
    await expectLater(
      store.stage(
        SocialPickedMedia(
          path: second.path,
          name: 'second.jpg',
          kind: SocialMediaKind.image,
        ),
      ),
      throwsA(isA<FileSystemException>()),
    );
  });

  test(
    'concurrent distinct sources atomically admit only one within quota',
    () async {
      store = SocialCreateDraftMediaStore(
        root: privateRoot,
        maximumBytes: 10,
        maximumTotalBytes: 4,
      );
      final first = File('${sourceRoot.path}/concurrent-first.jpg');
      final second = File('${sourceRoot.path}/concurrent-second.jpg');
      await first.writeAsBytes([1, 2, 3]);
      await second.writeAsBytes([4, 5, 6]);

      Future<Object> capture(Future<SocialCreateDraftMediaReference> future) =>
          future.then<Object>(
            (reference) => reference,
            onError: (Object error, StackTrace _) => error,
          );

      final outcomes = await Future.wait<Object>([
        capture(
          store.stage(
            SocialPickedMedia(
              path: first.path,
              name: 'concurrent-first.jpg',
              kind: SocialMediaKind.image,
            ),
          ),
        ),
        capture(
          store.stage(
            SocialPickedMedia(
              path: second.path,
              name: 'concurrent-second.jpg',
              kind: SocialMediaKind.image,
            ),
          ),
        ),
      ]);

      expect(
        outcomes.whereType<SocialCreateDraftMediaReference>(),
        hasLength(1),
      );
      expect(outcomes.whereType<FileSystemException>(), hasLength(1));
      final stagedFiles = await privateRoot
          .list()
          .where((entity) => entity is File)
          .cast<File>()
          .toList();
      expect(stagedFiles, hasLength(1));
      expect(await stagedFiles.single.length(), 3);
    },
  );

  test('purgeAll removes staged owners after envelope loss', () async {
    final source = File('${sourceRoot.path}/orphan.jpg');
    await source.writeAsBytes([1, 2, 3]);
    await store.stage(
      SocialPickedMedia(
        path: source.path,
        name: 'orphan.jpg',
        kind: SocialMediaKind.image,
      ),
    );
    await store.purgeAll();
    expect(
      await privateRoot.list().where((entity) => entity is File).length,
      0,
    );
  });

  test(
    'auth purge settles in-flight stage, purges all and rejects new stage',
    () async {
      final source = File(
        '${sourceRoot.path}${Platform.pathSeparator}auth.jpg',
      );
      await source.writeAsBytes(List<int>.filled(64 * 1024, 7));
      final media = SocialPickedMedia(
        path: source.path,
        name: 'auth.jpg',
        kind: SocialMediaKind.image,
      );

      final staging = store.stage(media);
      final purged = store.disableStagingAndPurgeAll();
      expect((await staging).id, hasLength(32));
      expect(await purged, isTrue);
      final stagedFiles = await privateRoot
          .list()
          .where((entity) => entity is File)
          .toList();
      expect(stagedFiles, isEmpty);
      await expectLater(store.stage(media), throwsStateError);
    },
  );

  test(
    'late old-principal purge cannot delete newly rebound staging',
    () async {
      final oldSource = File(
        '${sourceRoot.path}${Platform.pathSeparator}old.jpg',
      );
      final newSource = File(
        '${sourceRoot.path}${Platform.pathSeparator}new.jpg',
      );
      await oldSource.writeAsBytes(List<int>.filled(64 * 1024, 1));
      await newSource.writeAsBytes(List<int>.filled(64 * 1024, 2));
      final oldStage = store.stage(
        SocialPickedMedia(
          path: oldSource.path,
          name: 'old.jpg',
          kind: SocialMediaKind.image,
        ),
      );
      final oldPurge = store.disableStagingAndPurgeAll();
      store.enableStaging();
      final newStage = store.stage(
        SocialPickedMedia(
          path: newSource.path,
          name: 'new.jpg',
          kind: SocialMediaKind.image,
        ),
      );

      await oldStage;
      final newReference = await newStage;
      expect(await oldPurge, isFalse);
      expect(await store.resolve(newReference), isNotNull);
    },
  );
}
