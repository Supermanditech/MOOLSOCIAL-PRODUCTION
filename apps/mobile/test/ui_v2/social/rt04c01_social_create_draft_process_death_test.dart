import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/creator/creator_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/retailer/retailer_session.dart';
import 'package:moolsocial/features/shared/shared_models.dart';
import 'package:moolsocial/features/shared/shared_session.dart';
import 'package:moolsocial/features/shared/social_content_gateway.dart';
import 'package:moolsocial/features/shared/social_create_draft_media_store.dart';
import 'package:moolsocial/features/shared/social_create_draft_repository.dart';
import 'package:moolsocial/features/shared/social_media_picker.dart';
import 'package:moolsocial/features/shared/youtube_public_catalogue_repository.dart';
import 'package:moolsocial/ui_v2/social/social_v2_consumer.dart';
import 'package:moolsocial/ui_v2/social/social_v2_create_workbench.dart';
import 'package:moolsocial/ui_v2/social/social_v2_public_content.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'RT-04C-01 Close flushes and new objects restore the exact draft',
    (tester) async {
      final repository = _MemoryDraftRepository();
      final firstCache = SocialCreateDraftStateCache();
      await firstCache.configureDurability(repository);
      final firstOwners = _Owners();

      await _pumpConsumer(
        tester,
        firstOwners,
        cache: firstCache,
        picker: _Picker(),
      );
      await tester.enterText(
        find.byKey(const Key('screen04-create-post-text')),
        'Close must keep this exact unpublished draft',
      );
      await tester.tap(find.byKey(const Key('screen04-create-close')));
      await tester.pumpAndSettle();
      await firstCache.settleDurableWrites();

      expect(
        (await repository.read()).snapshot?.body,
        'Close must keep this exact unpublished draft',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await firstCache.settleDurableWritesConfirmed();
      firstOwners.dispose();

      final relaunchedCache = SocialCreateDraftStateCache();
      expect(
        await relaunchedCache.configureDurability(repository),
        SocialCreateDraftFreshness.fresh,
      );
      final relaunchedPicker = _Picker();
      final relaunchedOwners = _Owners();
      await _pumpConsumer(
        tester,
        relaunchedOwners,
        cache: relaunchedCache,
        picker: relaunchedPicker,
      );

      expect(_bodyText(tester), 'Close must keep this exact unpublished draft');
      expect(
        relaunchedPicker.recoverCalls,
        0,
        reason: 'A durable draft must suppress lost-picker recovery.',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await relaunchedCache.settleDurableWritesConfirmed();
      relaunchedOwners.dispose();
    },
  );

  testWidgets('RT-04C-01 confirmed Discard is absent after relaunch', (
    tester,
  ) async {
    final repository = _MemoryDraftRepository();
    await repository.write(_snapshot(body: 'Discard me'));
    final cache = SocialCreateDraftStateCache();
    await cache.configureDurability(repository);
    final owners = _Owners();

    await _pumpConsumer(tester, owners, cache: cache, picker: _Picker());
    expect(_bodyText(tester), 'Discard me');
    await tester.tap(find.byKey(const Key('screen04-create-discard')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('screen04-create-discard-confirmation')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('screen04-create-discard-confirm')));
    await tester.pumpAndSettle();
    await cache.settleDurableWrites();

    expect(cache.snapshot, isNull);
    expect(
      (await repository.read()).freshness,
      SocialCreateDraftFreshness.missing,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    owners.dispose();

    final relaunchedCache = SocialCreateDraftStateCache();
    await relaunchedCache.configureDurability(repository);
    final relaunchedOwners = _Owners();
    addTearDown(relaunchedOwners.dispose);
    await _pumpConsumer(
      tester,
      relaunchedOwners,
      cache: relaunchedCache,
      picker: _Picker(),
    );
    expect(_bodyText(tester), isEmpty);
    expect(find.text('Discard me'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'RT-04C-01 acknowledged publish clears while failed publish retains',
    (tester) async {
      final successRepository = _MemoryDraftRepository();
      await successRepository.write(_snapshot(body: 'Publish and clear'));
      final successCache = SocialCreateDraftStateCache();
      await successCache.configureDurability(successRepository);
      final successOwners = _Owners(gateway: _PublishingGateway());
      await _pumpConsumer(
        tester,
        successOwners,
        cache: successCache,
        picker: _Picker(),
      );
      await tester.tap(find.byKey(const Key('screen04-create-publish-post')));
      await tester.pumpAndSettle();
      await successCache.settleDurableWrites();
      expect(successCache.snapshot, isNull);
      expect(
        (await successRepository.read()).freshness,
        SocialCreateDraftFreshness.missing,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      successOwners.dispose();

      final failureRepository = _MemoryDraftRepository();
      await failureRepository.write(_snapshot(body: 'Failure must stay'));
      final failureCache = SocialCreateDraftStateCache();
      await failureCache.configureDurability(failureRepository);
      final failureOwners = _Owners(gateway: _PublishingGateway(fail: true));
      addTearDown(failureOwners.dispose);
      await _pumpConsumer(
        tester,
        failureOwners,
        cache: failureCache,
        picker: _Picker(),
      );
      await tester.tap(find.byKey(const Key('screen04-create-publish-post')));
      await tester.pumpAndSettle();
      await failureCache.settleDurableWrites();

      expect(failureCache.snapshot?.body, 'Failure must stay');
      expect(
        (await failureRepository.read()).snapshot?.body,
        'Failure must stay',
      );
      expect(find.text('Synthetic publish failure.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'RT-04C-01 publish locks the restored composer until cleanup completes',
    (tester) async {
      final cleanup = Completer<void>();
      final shared = SharedSession(socialContentGateway: _PublishingGateway());
      addTearDown(shared.dispose);
      var published = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: SocialCreateWorkbenchV2(
            session: shared,
            mediaPicker: _Picker(),
            authorName: 'Runtime author',
            authorHandle: '@runtime',
            onPublished: (_) => published += 1,
            onBeforeDraftClear: () => cleanup.future,
            draft: _restoredWorkbenchDraft(
              body: 'Keep visible while publish cleanup waits',
              media: const [_assetImage],
              tool: SocialCreateDraftTool.image,
            ),
            recoverInterruptedMedia: false,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('screen04-create-publish-post')));
      await tester.pump();

      expect(_workbenchLock(tester).ignoring, isTrue);
      expect(_bodyText(tester), 'Keep visible while publish cleanup waits');
      expect(find.byType(SocialMediaPreviewV2), findsOneWidget);
      expect(published, 0);

      cleanup.complete();
      await tester.pumpAndSettle();
      expect(_workbenchLock(tester).ignoring, isFalse);
      expect(_bodyText(tester), isEmpty);
      expect(published, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'RT-04C-01 failed delayed Discard cleanup unlocks and retains text/media',
    (tester) async {
      final cleanup = Completer<void>();
      final shared = SharedSession(socialContentGateway: _PublishingGateway());
      addTearDown(shared.dispose);
      var closed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialCreateWorkbenchV2(
              session: shared,
              mediaPicker: _Picker(),
              authorName: 'Runtime author',
              authorHandle: '@runtime',
              onPublished: (_) {},
              onClose: () => closed += 1,
              onBeforeDraftClear: () => cleanup.future,
              draft: _restoredWorkbenchDraft(
                body: 'Retain after cleanup failure',
                media: const [_assetImage],
                tool: SocialCreateDraftTool.image,
              ),
              recoverInterruptedMedia: false,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('screen04-create-discard')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('screen04-create-discard-confirm')),
      );
      await tester.pump();

      expect(_workbenchLock(tester).ignoring, isTrue);
      expect(_bodyText(tester), 'Retain after cleanup failure');
      expect(find.byType(SocialMediaPreviewV2), findsOneWidget);
      cleanup.completeError(StateError('synthetic cleanup failure'));
      await tester.pumpAndSettle();

      expect(_workbenchLock(tester).ignoring, isFalse);
      expect(_bodyText(tester), 'Retain after cleanup failure');
      expect(find.byType(SocialMediaPreviewV2), findsOneWidget);
      expect(
        find.text('Draft cleanup failed. Please try again.'),
        findsOneWidget,
      );
      expect(closed, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('RT-04C-01 failed confirmed Close retains the visible draft', (
    tester,
  ) async {
    final shared = SharedSession(socialContentGateway: _PublishingGateway());
    addTearDown(shared.dispose);
    var closed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SocialCreateWorkbenchV2(
            session: shared,
            mediaPicker: _Picker(),
            authorName: 'Runtime author',
            authorHandle: '@runtime',
            onPublished: (_) {},
            onBeforeClose: () async => false,
            onClose: () => closed += 1,
            draft: _restoredWorkbenchDraft(body: 'Close failure must stay'),
            recoverInterruptedMedia: false,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('screen04-create-close')));
    await tester.pumpAndSettle();

    expect(_workbenchLock(tester).ignoring, isFalse);
    expect(_bodyText(tester), 'Close failure must stay');
    expect(find.text('Draft save failed. Please try again.'), findsOneWidget);
    expect(closed, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('RT-04C-01 every Create format enters a new workbench intact', (
    tester,
  ) async {
    final cases = <_FormatCase>[
      const _FormatCase(
        format: SocialCreateDraftFormat.post,
        tool: SocialCreateDraftTool.none,
        title: 'New text post',
      ),
      const _FormatCase(
        format: SocialCreateDraftFormat.post,
        tool: SocialCreateDraftTool.image,
        title: 'New image post',
        media: [_assetImage],
      ),
      const _FormatCase(
        format: SocialCreateDraftFormat.post,
        tool: SocialCreateDraftTool.imagePoll,
        title: 'New image poll',
        pollMedia: [_assetImage, null, null, null],
      ),
      const _FormatCase(
        format: SocialCreateDraftFormat.post,
        tool: SocialCreateDraftTool.quickPoll,
        title: 'New quick poll',
      ),
      const _FormatCase(
        format: SocialCreateDraftFormat.post,
        tool: SocialCreateDraftTool.quiz,
        title: 'New quiz',
      ),
      const _FormatCase(
        format: SocialCreateDraftFormat.carousel,
        tool: SocialCreateDraftTool.none,
        title: 'New carousel',
        media: [_assetImage, _secondAssetImage],
      ),
      const _FormatCase(
        format: SocialCreateDraftFormat.reel,
        tool: SocialCreateDraftTool.none,
        title: 'New Reel',
        media: [_assetVideo],
      ),
      const _FormatCase(
        format: SocialCreateDraftFormat.post,
        tool: SocialCreateDraftTool.none,
        title: 'New text post',
        quote: _quote,
      ),
    ];

    for (final value in cases) {
      final persistence = _Store();
      await _repository(persistence).write(
        _snapshot(
          body: 'Restored ${value.title}',
          format: value.format,
          tool: value.tool,
          media: value.media,
          imagePollMedia: value.pollMedia,
          choices: const ['One', 'Two', 'Three', 'Four'],
          correctChoice: 2,
          quote: value.quote,
        ),
      );
      final read = await _repository(persistence).read();
      final draft = SocialCreateDraftV2();
      draft.applyPersistenceSnapshot(
        read.snapshot!,
        media: value.media.map(_picked).toList(growable: false),
        imagePollMedia: value.pollMedia
            .map((item) => item == null ? null : _picked(item))
            .toList(growable: false),
      );
      final shared = SharedSession(socialContentGateway: _PublishingGateway());
      await tester.pumpWidget(
        MaterialApp(
          home: SocialCreateWorkbenchV2(
            session: shared,
            mediaPicker: _Picker(),
            authorName: 'Runtime author',
            authorHandle: '@runtime',
            onPublished: (_) {},
            draft: draft,
            recoverInterruptedMedia: false,
          ),
        ),
      );
      await tester.pump();
      expect(find.text(value.title), findsOneWidget, reason: value.title);
      expect(_bodyText(tester), 'Restored ${value.title}');
      expect(draft.choices, ['One', 'Two', 'Three', 'Four']);
      expect(draft.correctChoice, 2);
      expect(
        find.byKey(const Key('social-create-quoted-post')),
        value.quote == null ? findsNothing : findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      shared.dispose();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'RT-04C-01 local image stages restores and confirmed cleanup removes every owner',
    (tester) async {
      final parent = Directory(
        '${Directory.systemTemp.path}${Platform.pathSeparator}'
        'rt04c-e2e-${DateTime.now().microsecondsSinceEpoch}',
      )..createSync();
      addTearDown(() => _deleteDirectoryEventually(parent));
      final source = File('${parent.path}${Platform.pathSeparator}picked.png')
        ..writeAsBytesSync(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwC'
            'AAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
          ),
        );
      final privateRoot = Directory(
        '${parent.path}${Platform.pathSeparator}private',
      );
      final persistence = _Store();
      final firstCache = SocialCreateDraftStateCache();
      await firstCache.configureDurability(_repository(persistence));
      final firstOwners = _Owners();
      final picked = SocialPickedMedia(
        path: source.path,
        name: 'picked.png',
        kind: SocialMediaKind.image,
      );
      await _pumpConsumer(
        tester,
        firstOwners,
        cache: firstCache,
        picker: _Picker(pickedImage: picked),
        mediaStore: SocialCreateDraftMediaStore(root: privateRoot),
        disableLocalMediaPreview: true,
      );
      await tester.enterText(
        find.byKey(const Key('screen04-create-post-text')),
        'Local image process-death draft',
      );
      await tester.tap(find.byKey(const Key('screen04-create-tool-image')));
      await tester.pump();
      await _waitForFinderWallClock(
        tester,
        find.byKey(const Key('screen04-create-local-media-test-preview')),
      );
      for (var attempt = 0; attempt < 30; attempt++) {
        if (firstCache.snapshot?.media.isNotEmpty ?? false) break;
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
      }
      expect(firstCache.snapshot?.media, isNotEmpty);
      await tester.tap(find.byKey(const Key('screen04-create-close')));
      for (var attempt = 0; attempt < 20; attempt++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
        if (find
            .byKey(const ValueKey('social-v2-create-workbench'))
            .evaluate()
            .isEmpty) {
          break;
        }
      }
      expect(
        find.byKey(const ValueKey('social-v2-create-workbench')),
        findsNothing,
      );
      final firstRead = await _repository(persistence).read();
      final reference = firstRead.snapshot!.media.single;
      expect(reference.isAsset, isFalse);
      expect(reference.id, matches(RegExp(r'^[0-9a-f]{32}$')));
      expect(firstRead.snapshot?.body, 'Local image process-death draft');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      firstOwners.dispose();

      final secondCache = SocialCreateDraftStateCache();
      await secondCache.configureDurability(_repository(persistence));
      final secondStore = SocialCreateDraftMediaStore(root: privateRoot);
      final secondOwners = _Owners();
      await _pumpConsumer(
        tester,
        secondOwners,
        cache: secondCache,
        picker: _Picker(),
        mediaStore: secondStore,
        disableLocalMediaPreview: true,
      );
      await _waitForFinderWallClock(
        tester,
        find.byKey(const Key('screen04-create-post-text')),
      );
      expect(_bodyText(tester), 'Local image process-death draft');
      expect(
        find.byKey(const Key('screen04-create-local-media-test-preview')),
        findsOneWidget,
      );
      expect(
        await tester.runAsync(() => secondStore.resolve(reference)),
        isNotNull,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      secondOwners.dispose();
      expect(await secondCache.clearConfirmed(), isTrue);
      await tester.runAsync(() async {
        for (var attempt = 0; attempt < 10; attempt++) {
          try {
            await secondStore.clear([reference]);
            return;
          } on FileSystemException {
            await Future<void>.delayed(const Duration(milliseconds: 100));
          }
        }
        await secondStore.clear([reference]);
      });
      expect(
        (await _repository(persistence).read()).freshness,
        SocialCreateDraftFreshness.missing,
      );
      expect(
        await tester.runAsync(() => secondStore.resolve(reference)),
        isNull,
      );
      final thirdCache = SocialCreateDraftStateCache();
      await thirdCache.configureDurability(_repository(persistence));
      final thirdOwners = _Owners();
      addTearDown(thirdOwners.dispose);
      await _pumpConsumer(
        tester,
        thirdOwners,
        cache: thirdCache,
        picker: _Picker(),
        mediaStore: SocialCreateDraftMediaStore(root: privateRoot),
      );
      expect(_bodyText(tester), isEmpty);
      expect(
        await tester.runAsync(
          () => privateRoot.list().where((entity) => entity is File).length,
        ),
        0,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'RT-04C-01 partial media loss keeps text and suppresses lost-picker',
    (tester) async {
      final repository = _MemoryDraftRepository();
      await repository.write(
        _snapshot(
          body: 'Text survives missing media',
          format: SocialCreateDraftFormat.carousel,
          media: const [_assetImage, _missingLocalImage],
        ),
      );
      final cache = SocialCreateDraftStateCache();
      await cache.configureDurability(repository);
      final root = Directory(
        '${Directory.systemTemp.path}${Platform.pathSeparator}'
        'rt04c-media-${DateTime.now().microsecondsSinceEpoch}',
      );
      root.createSync();
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
      });
      final picker = _Picker(
        recovered: const [
          SocialPickedMedia(
            path: 'assets/should-not-replace-durable.png',
            name: 'lost.png',
            kind: SocialMediaKind.image,
            isAsset: true,
          ),
        ],
      );
      final owners = _Owners();
      addTearDown(owners.dispose);

      await _pumpConsumer(
        tester,
        owners,
        cache: cache,
        picker: picker,
        mediaStore: SocialCreateDraftMediaStore(root: root),
      );
      for (var attempt = 0; attempt < 20; attempt++) {
        if (find
            .byKey(const Key('screen04-create-draft-media-loss'))
            .evaluate()
            .isNotEmpty) {
          break;
        }
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(
        find.byKey(const Key('screen04-create-draft-media-loss')),
        findsOneWidget,
      );
      expect(_bodyText(tester), 'Text survives missing media');
      expect(find.text('1 / 10 photos'), findsOneWidget);
      expect(cache.snapshot?.media.map((item) => item.id), [_assetImage.id]);
      expect(picker.recoverCalls, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await cache.settleDurableWritesConfirmed();
    },
  );

  testWidgets(
    'RT-04C-01 secure clear failure retains visible draft and staged media',
    (tester) async {
      final mediaStore = SocialCreateDraftMediaStore(
        root: Directory(
          '${Directory.systemTemp.path}${Platform.pathSeparator}'
          'rt04c-unused-${DateTime.now().microsecondsSinceEpoch}',
        ),
      );
      const reference = _assetImage;
      final repository = _FailingClearDraftRepository(
        _snapshot(
          body: 'Secure clear must retain me',
          tool: SocialCreateDraftTool.image,
          media: [reference],
        ),
      );
      final cache = SocialCreateDraftStateCache();
      await cache.configureDurability(repository);
      final owners = _Owners();
      addTearDown(owners.dispose);

      await _pumpConsumer(
        tester,
        owners,
        cache: cache,
        picker: _Picker(),
        mediaStore: mediaStore,
      );
      await _waitForFinderWallClock(
        tester,
        find.byKey(const Key('screen04-create-discard')),
      );
      await tester.tap(find.byKey(const Key('screen04-create-discard')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('screen04-create-discard-confirm')),
      );
      await tester.pumpAndSettle();

      expect(_bodyText(tester), 'Secure clear must retain me');
      expect(find.byType(SocialMediaPreviewV2), findsOneWidget);
      expect(cache.snapshot?.body, 'Secure clear must retain me');
      expect(
        await tester.runAsync(() => mediaStore.resolve(reference)),
        isNotNull,
      );
      expect(
        find.text('Draft cleanup failed. Please try again.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets('RT-04C-01 a wrong principal cannot hydrate the draft', (
    tester,
  ) async {
    final persistence = _Store();
    await _repository(
      persistence,
      binding: _binding('a'),
    ).write(_snapshot(body: 'Principal A private draft'));
    final wrongPrincipalRepository = _repository(
      persistence,
      binding: _binding('b'),
    );
    expect(
      (await wrongPrincipalRepository.read()).freshness,
      SocialCreateDraftFreshness.invalidated,
    );
    expect(
      persistence.values,
      isNot(contains(DurableSocialCreateDraftRepository.storageKey)),
    );

    final cache = SocialCreateDraftStateCache();
    expect(
      await cache.configureDurability(wrongPrincipalRepository),
      SocialCreateDraftFreshness.missing,
    );
    final owners = _Owners();
    addTearDown(owners.dispose);
    await _pumpConsumer(tester, owners, cache: cache, picker: _Picker());
    expect(_bodyText(tester), isEmpty);
    expect(find.text('Principal A private draft'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('RT-04C-01 exact revision clear prevents resurrection', () async {
    final repo = _MemoryDraftRepository();
    final cache = SocialCreateDraftStateCache();
    await cache.configureDurability(repo);
    cache.replace(_snapshot(revision: 3, body: 'submitted'), debounce: false);
    cache.replace(_snapshot(revision: 4, body: 'newer edit'), debounce: false);
    await cache.clearIfRevision(3);
    await cache.settleDurableWrites();
    expect(cache.snapshot?.body, 'newer edit');
    await cache.clearIfRevision(4);
    expect(cache.snapshot, isNull);
  });
}

Future<void> _pumpConsumer(
  WidgetTester tester,
  _Owners owners, {
  required SocialCreateDraftStateCache cache,
  required _Picker picker,
  SocialCreateDraftMediaStore? mediaStore,
  bool disableLocalMediaPreview = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  await tester.pumpWidget(
    MaterialApp(
      home: owners.consumer(
        cache: cache,
        picker: picker,
        mediaStore: mediaStore,
        disableLocalMediaPreview: disableLocalMediaPreview,
      ),
    ),
  );
  await tester.pump();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

Future<void> _waitForFinderWallClock(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 30; attempt++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
  }
  expect(finder, findsWidgets);
}

Future<void> _deleteDirectoryEventually(Directory directory) async {
  for (var attempt = 0; attempt < 10; attempt++) {
    try {
      if (await directory.exists()) await directory.delete(recursive: true);
      return;
    } on FileSystemException {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }
  if (await directory.exists()) await directory.delete(recursive: true);
}

String? _bodyText(WidgetTester tester) => tester
    .widget<TextField>(find.byKey(const Key('screen04-create-post-text')))
    .controller
    ?.text;

IgnorePointer _workbenchLock(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find.byKey(const ValueKey('social-v2-create-workbench')),
            )
            .child
        as IgnorePointer;

SocialCreateDraftV2 _restoredWorkbenchDraft({
  required String body,
  SocialCreateDraftFormat format = SocialCreateDraftFormat.post,
  SocialCreateDraftTool tool = SocialCreateDraftTool.none,
  List<SocialCreateDraftMediaReference> media = const [],
}) {
  final draft = SocialCreateDraftV2();
  draft.applyPersistenceSnapshot(
    _snapshot(body: body, format: format, tool: tool, media: media),
    media: media.map(_picked).toList(growable: false),
    imagePollMedia: const [null, null, null, null],
  );
  return draft;
}

final class _Owners {
  _Owners({SocialContentGateway? gateway})
    : shared = SharedSession(socialContentGateway: gateway);

  final JourneySession journey = JourneySession();
  final CreatorSession creator = CreatorSession();
  final RetailerSession retailer = RetailerSession();
  final SharedSession shared;

  SocialUniversalV2 consumer({
    required SocialCreateDraftStateCache cache,
    required SocialMediaPicker picker,
    SocialCreateDraftMediaStore? mediaStore,
    bool disableLocalMediaPreview = false,
  }) => SocialUniversalV2(
    session: journey,
    creatorSession: creator,
    retailerSession: retailer,
    sharedSession: shared,
    initialSubAction: 'create',
    initialState: 'text',
    youtubePublicAccessOverride: false,
    youtubeCreatorAccessOverride: false,
    youtubeVideosLoader: () async => const [],
    youtubeShortsLoader: () async => const [],
    mediaPicker: picker,
    createDraftStateCache: cache,
    createDraftMediaStore: mediaStore,
    disableLocalDraftMediaPreviewForTesting: disableLocalMediaPreview,
  );

  void dispose() {
    journey.dispose();
    creator.dispose();
    retailer.dispose();
    shared.dispose();
  }
}

final class _Picker implements SocialMediaPicker {
  _Picker({this.recovered = const [], this.pickedImage});

  final List<SocialPickedMedia> recovered;
  final SocialPickedMedia? pickedImage;
  int recoverCalls = 0;

  @override
  Future<List<SocialPickedMedia>> recoverInterruptedSelection() async {
    recoverCalls += 1;
    return recovered;
  }

  @override
  Future<List<SocialPickedMedia>> pickCarousel({int limit = 10}) async => [];

  @override
  Future<SocialPickedMedia?> pickImage(SocialMediaSource source) async =>
      pickedImage;

  @override
  Future<SocialPickedMedia?> pickReel(SocialMediaSource source) async => null;
}

final class _PublishingGateway implements SocialContentGateway {
  _PublishingGateway({this.fail = false});
  final bool fail;

  @override
  Future<SocialFeedPage> feed({String? cursor, int limit = 20}) async =>
      const SocialFeedPage(items: []);

  @override
  Future<SocialPublishedItem> interact({
    required String postId,
    required String interaction,
    int? choiceIndex,
  }) => throw UnimplementedError();

  @override
  Future<SocialPublishedItem> publish(SocialPublishDraft draft) async {
    if (fail) {
      throw const SocialContentGatewayException(
        code: 'synthetic_failure',
        message: 'Synthetic publish failure.',
        retryable: true,
      );
    }
    return SocialPublishedItem(
      id: 'published-1',
      authorId: 'author-1',
      publishIdempotencyKey: draft.idempotencyKey,
      type: draft.type,
      authorName: draft.authorName,
      authorHandle: draft.authorHandle,
      body: draft.body,
      audience: draft.audience,
      publishedAt: DateTime.utc(2026, 8, 25),
      mediaPaths: draft.mediaPaths,
      mediaAreAssets: draft.mediaAreAssets,
      choices: draft.choices,
      correctChoiceIndex: draft.correctChoiceIndex,
    );
  }
}

final class _Store implements YouTubePublicCatalogueKeyValueStore {
  final Map<String, String> values = {};

  @override
  Future<String?> readString(String key) async => values[key];

  @override
  Future<bool> writeString(String key, String value) async {
    values[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    values.remove(key);
    return true;
  }
}

final class _MemoryDraftRepository implements SocialCreateDraftRepository {
  SocialCreateDraftRead value = const SocialCreateDraftRead(
    freshness: SocialCreateDraftFreshness.missing,
  );

  @override
  Future<SocialCreateDraftRead> read() async => value;

  @override
  Future<void> write(SocialCreateDraftSnapshot snapshot) async {
    value = SocialCreateDraftRead(
      freshness: SocialCreateDraftFreshness.fresh,
      snapshot: snapshot,
    );
  }

  @override
  Future<void> clear() async {
    value = const SocialCreateDraftRead(
      freshness: SocialCreateDraftFreshness.missing,
    );
  }
}

final class _FailingClearDraftRepository
    implements SocialCreateDraftRepository {
  _FailingClearDraftRepository(SocialCreateDraftSnapshot snapshot)
    : _snapshot = snapshot;

  SocialCreateDraftSnapshot _snapshot;

  @override
  Future<SocialCreateDraftRead> read() async => SocialCreateDraftRead(
    freshness: SocialCreateDraftFreshness.fresh,
    snapshot: _snapshot,
  );

  @override
  Future<void> write(SocialCreateDraftSnapshot snapshot) async {
    _snapshot = snapshot;
  }

  @override
  Future<void> clear() =>
      Future<void>.error(StateError('synthetic secure clear failure'));
}

DurableSocialCreateDraftRepository _repository(
  _Store store, {
  VerifiedPrincipalBinding? binding,
}) => DurableSocialCreateDraftRepository(
  persistence: store,
  principalBinding: binding ?? _binding('a'),
);

SocialCreateDraftSnapshot _snapshot({
  int revision = 1,
  String body = 'Draft body',
  SocialCreateDraftFormat format = SocialCreateDraftFormat.post,
  SocialCreateDraftTool tool = SocialCreateDraftTool.none,
  List<String> choices = const ['', '', '', ''],
  List<SocialCreateDraftMediaReference> media = const [],
  List<SocialCreateDraftMediaReference?> imagePollMedia = const [
    null,
    null,
    null,
    null,
  ],
  int correctChoice = 0,
  SocialCreateDraftQuote? quote,
}) => SocialCreateDraftSnapshot(
  initialized: true,
  format: format,
  tool: tool,
  body: body,
  choices: choices,
  media: media,
  imagePollMedia: imagePollMedia,
  correctChoice: correctChoice,
  quote: quote,
  revision: revision,
  capturedAtUtc: DateTime.now().toUtc(),
);

VerifiedPrincipalBinding _binding(String character) =>
    VerifiedPrincipalBinding.fromStorage('v1:${character * 64}');

SocialPickedMedia _picked(SocialCreateDraftMediaReference value) =>
    SocialPickedMedia(
      path: value.id,
      name: value.name,
      kind: value.kind == SocialCreateDraftMediaKind.image
          ? SocialMediaKind.image
          : SocialMediaKind.video,
      isAsset: value.isAsset,
    );

const _assetImage = SocialCreateDraftMediaReference(
  id: 'assets/prototype/social-market-grocery.png',
  name: 'image.png',
  kind: SocialCreateDraftMediaKind.image,
  isAsset: true,
  byteLength: 0,
  sha256: '',
);

const _secondAssetImage = SocialCreateDraftMediaReference(
  id: 'assets/prototype/moolsocial-category-media-atlas-v3a-2026.png',
  name: 'second.png',
  kind: SocialCreateDraftMediaKind.image,
  isAsset: true,
  byteLength: 0,
  sha256: '',
);

const _assetVideo = SocialCreateDraftMediaReference(
  id: 'assets/prototype/social-market-grocery.png',
  name: 'reel.mp4',
  kind: SocialCreateDraftMediaKind.video,
  isAsset: true,
  byteLength: 0,
  sha256: '',
);

const _missingLocalImage = SocialCreateDraftMediaReference(
  id: '11111111111111111111111111111111',
  name: 'missing.png',
  kind: SocialCreateDraftMediaKind.image,
  isAsset: false,
  byteLength: 1024,
  sha256: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
);

const _quote = SocialCreateDraftQuote(
  id: 'quoted-runtime-post',
  authorName: 'Quoted author',
  authorHandle: '@quoted',
  body: 'Quoted content survives process death.',
  mediaUrl: null,
);

final class _FormatCase {
  const _FormatCase({
    required this.format,
    required this.tool,
    required this.title,
    this.media = const [],
    this.pollMedia = const [null, null, null, null],
    this.quote,
  });

  final SocialCreateDraftFormat format;
  final SocialCreateDraftTool tool;
  final String title;
  final List<SocialCreateDraftMediaReference> media;
  final List<SocialCreateDraftMediaReference?> pollMedia;
  final SocialCreateDraftQuote? quote;
}
