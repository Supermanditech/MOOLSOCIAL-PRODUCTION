import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/creator/creator_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/retailer/retailer_session.dart';
import 'package:moolsocial/features/shared/shared_session.dart';
import 'package:moolsocial/ui_v2/social/screen04_universal_components.dart';
import 'package:moolsocial/ui_v2/social/social_v2_consumer.dart';

final _forbiddenScreen04Copy = RegExp(
  r'\b(?:example|sample|demo|mock|placeholder|prototype|founder review|'
  r'review build|implementation note|developer note|working note|internal '
  r'plan|state machine|payload|endpoint|next screen|for testing)\b',
  caseSensitive: false,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Screen 04 opens with the approved capability rail', (
    tester,
  ) async {
    final owners = _Owners();
    addTearDown(owners.dispose);
    await _pump(tester, const Size(390, 844), 1, owners.consumer());

    expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);
    expect(find.byKey(const Key('screen04-capability-rail')), findsOneWidget);
    expect(find.text('MoolSocial'), findsOneWidget);
    expect(find.text('Shorts'), findsOneWidget);
    expect(find.text('Videos'), findsOneWidget);
    expect(find.text('Feed'), findsOneWidget);
    expect(find.text('Create'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.byKey(const Key('screen04-search')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mool selection reveals the focused sub-action ribbon', (
    tester,
  ) async {
    final owners = _Owners();
    addTearDown(owners.dispose);
    await _pump(tester, const Size(390, 844), 1, owners.consumer());

    await tester.tap(find.byKey(const Key('screen04-mool')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('screen04-rail-buy')));
    await tester.pumpAndSettle();
    expect(find.text('Retail and wholesale, in one place'), findsOneWidget);
    expect(find.text('Everyday essentials, nearby'), findsOneWidget);
    expect(find.byKey(const Key('screen04-search')), findsOneWidget);
    expect(find.byKey(const Key('screen04-choice-ribbon')), findsOneWidget);
    expect(find.text('Grocery'), findsWidgets);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Medicine'), findsOneWidget);
    expect(find.text('Basket'), findsOneWidget);

    await tester.tap(find.byKey(const Key('screen04-rail-categories')));
    await tester.pumpAndSettle();
    expect(find.text('Find the right aisle faster'), findsOneWidget);

    await tester.tap(find.byKey(const Key('screen04-mool')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen04-world-ribbon')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'rail automatically keeps the active and next action visible while swipe remains available',
    (tester) async {
      final rootOwners = _Owners();
      await _pump(
        tester,
        const Size(320, 568),
        1.4,
        rootOwners.consumer(world: 'eat'),
      );

      await tester.tap(find.byKey(const Key('screen04-mool')));
      await tester.pumpAndSettle();
      _expectInsideRibbon(
        tester,
        ribbon: const Key('screen04-world-ribbon'),
        item: const Key('screen04-rail-eat'),
      );
      _expectInsideRibbon(
        tester,
        ribbon: const Key('screen04-world-ribbon'),
        item: const Key('screen04-rail-ride'),
      );
      expect(
        tester
            .widget<SingleChildScrollView>(
              find.byKey(const Key('screen04-world-ribbon')),
            )
            .physics,
        isA<BouncingScrollPhysics>(),
      );
      rootOwners.dispose();

      final choiceOwners = _Owners();
      await _pump(
        tester,
        const Size(320, 568),
        1.4,
        choiceOwners.consumer(world: 'work', sub: 'delivery'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('screen04-rail-onboard')));
      await tester.pumpAndSettle();
      _expectInsideRibbon(
        tester,
        ribbon: const Key('screen04-choice-ribbon'),
        item: const Key('screen04-rail-onboard'),
      );
      _expectInsideRibbon(
        tester,
        ribbon: const Key('screen04-choice-ribbon'),
        item: const Key('screen04-rail-verify'),
      );
      expect(tester.takeException(), isNull);
      choiceOwners.dispose();
    },
  );

  testWidgets(
    'every main action preserves its focused sub-action through Mool and Back',
    (tester) async {
      for (final world in screen04Worlds) {
        final owners = _Owners();
        await _pump(
          tester,
          const Size(390, 844),
          1,
          owners.consumer(world: world.id),
        );

        await tester.tap(find.byKey(const Key('screen04-mool')));
        await tester.pumpAndSettle();
        final worldAction = find.byKey(Key('screen04-rail-${world.id}'));
        await tester.ensureVisible(worldAction);
        await tester.tap(worldAction);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('screen04-choice-ribbon')), findsOneWidget);

        final finalChoice = world.choices.last;
        final choiceAction = find.byKey(Key('screen04-rail-${finalChoice.id}'));
        await tester.ensureVisible(choiceAction);
        await tester.tap(choiceAction);
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('screen04-mool')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('screen04-world-ribbon')), findsOneWidget);

        await tester.tap(find.byKey(const Key('screen04-mool')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('screen04-choice-ribbon')), findsOneWidget);
        expect(
          find.byKey(Key('screen04-rail-${finalChoice.id}')),
          findsOneWidget,
        );

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('screen04-world-ribbon')), findsOneWidget);
        expect(tester.takeException(), isNull, reason: world.id);
        owners.dispose();
      }
    },
  );

  testWidgets('Create stays on one surface before the Mool root', (
    tester,
  ) async {
    final owners = _Owners();
    addTearDown(owners.dispose);
    await _pump(tester, const Size(390, 844), 1, owners.consumer());

    await tester.ensureVisible(find.byKey(const Key('screen04-rail-create')));
    await tester.tap(find.byKey(const Key('screen04-rail-create')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen04-create-workbench')), findsOneWidget);
    expect(find.byKey(const Key('screen04-create-post-text')), findsOneWidget);
    expect(find.text('Reel'), findsOneWidget);
    expect(find.text('Carousel'), findsOneWidget);
    expect(find.text('Post'), findsWidgets);

    await tester.tap(find.text('Reel'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen04-create-workbench')), findsOneWidget);
    expect(
      find.byKey(const Key('screen04-create-reel-camera')),
      findsOneWidget,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen04-world-ribbon')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Chat and deeper destinations return to the exact Universal context',
    (tester) async {
      final owners = _AuthenticatedOwners();
      addTearDown(owners.dispose);
      await owners.journey.start();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MoolSocialApp(
          session: owners.journey,
          creatorSession: owners.creator,
          retailerSession: owners.retailer,
          sharedSession: owners.shared,
          initialLocation: '/app/social?world=work&sub=verify',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Build trust for better work'), findsOneWidget);

      await tester.tap(find.byKey(const Key('screen04-chat')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);

      await tester.tap(find.byKey(const Key('chat-back')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);
      expect(find.text('Build trust for better work'), findsOneWidget);

      await tester.tap(find.byKey(const Key('screen04-mool')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('screen04-rail-buy')));
      await tester.tap(find.byKey(const Key('screen04-rail-buy')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('screen04-rail-medicine')),
      );
      await tester.tap(find.byKey(const Key('screen04-rail-medicine')));
      await tester.pumpAndSettle();
      expect(find.text('Health needs with clear steps'), findsOneWidget);
      await tester.tap(find.byKey(const Key('screen04-primary')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('buy-medicine-screen')), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);
      expect(find.text('Health needs with clear steps'), findsOneWidget);
      expect(find.byKey(const Key('screen04-choice-ribbon')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('video watch keeps the capability rail and survives Chat return', (
    tester,
  ) async {
    final owners = _AuthenticatedOwners();
    addTearDown(owners.dispose);
    await owners.journey.start();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MoolSocialApp(
        session: owners.journey,
        creatorSession: owners.creator,
        retailerSession: owners.retailer,
        sharedSession: owners.shared,
        initialLocation:
            '/app/social?sub=videos&state=video-watch&item=5-minute-morning-mobility',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('screen04-video-watch')), findsOneWidget);
    expect(find.byKey(const Key('screen04-choice-ribbon')), findsOneWidget);
    expect(find.byKey(const Key('screen04-rail-videos')), findsOneWidget);
    expect(find.byKey(const Key('screen04-chat')), findsOneWidget);
    expect(find.byKey(const Key('social-v2-tab-videos')), findsNothing);

    await tester.tap(find.byKey(const Key('screen04-chat')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);
    await tester.tap(find.byKey(const Key('chat-back')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('screen04-video-watch')), findsOneWidget);
    expect(find.text('5-minute morning mobility'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen04-video-watch')), findsNothing);
    expect(find.text('5-minute morning mobility'), findsOneWidget);
    expect(find.byKey(const Key('screen04-choice-ribbon')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Videos uses native Back and restores the exact discovery position', (
    tester,
  ) async {
    final owners = _Owners();
    addTearDown(owners.dispose);
    await _pump(
      tester,
      const Size(390, 844),
      1,
      owners.consumer(sub: 'videos'),
    );

    final discoveryList = find.byType(ListView).last;
    await tester.drag(discoveryList, const Offset(0, -180));
    await tester.pumpAndSettle();
    final secondTitle = find.text('How Jodhpur makers prepare block prints');
    await tester.ensureVisible(secondTitle);
    await tester.pumpAndSettle();
    final discoveryTop = tester.getTopLeft(secondTitle).dy;

    await tester.tap(secondTitle);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen04-video-watch')), findsOneWidget);
    expect(find.byKey(const Key('screen04-video-back')), findsNothing);

    await tester.tap(find.byKey(const Key('screen04-video-details-trigger')));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Meet Jodhpur artisans as they carve, colour and print fabric by hand.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('A calm routine you can follow before the day gets busy.'),
      findsNothing,
    );

    await tester.tap(find.text('View channel'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Stories of Indian makers, regional crafts and the people preserving them.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Guided mobility, strength and recovery sessions for everyday movement.',
      ),
      findsNothing,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Description'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen04-video-watch')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen04-video-watch')), findsNothing);
    expect(tester.getTopLeft(secondTitle).dy, closeTo(discoveryTop, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'MoolSocial and YouTube Shorts share one edge-to-edge media contract',
    (tester) async {
      final owners = _Owners();
      addTearDown(owners.dispose);
      await _pump(tester, const Size(360, 720), 1, owners.consumer());

      final pageView = find.byKey(const Key('screen04-shorts-page-view'));
      final nativeMedia = find.byKey(
        const Key('screen04-short-media-moolsocial'),
      );
      expect(tester.widget<Image>(nativeMedia).fit, BoxFit.cover);
      expect(tester.getSize(nativeMedia), tester.getSize(pageView));
      expect(find.text('Watch'), findsNothing);

      await tester.tap(find.text('More').first);
      await tester.pumpAndSettle();
      expect(find.text('Less'), findsOneWidget);
      expect(
        find.textContaining('Packed this morning with tomatoes'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('Less'), findsOneWidget);
      expect(
        find.textContaining('delivery time and seller details'),
        findsOneWidget,
      );
      await tester.tap(find.text('Less'));
      await tester.pumpAndSettle();

      await tester.pump(const Duration(milliseconds: 3000));
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.byKey(const Key('screen04-short-chrome-moolsocial')),
            )
            .opacity,
        1,
      );
      final nativeSurface = tester.getRect(
        find.byKey(const Key('screen04-short-fresh-basket')),
      );
      await tester.tapAt(nativeSurface.topLeft + const Offset(18, 124));
      await tester.pump(const Duration(milliseconds: 240));
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.byKey(const Key('screen04-short-chrome-moolsocial')),
            )
            .opacity,
        0,
      );
      await tester.tapAt(nativeSurface.topLeft + const Offset(18, 124));
      await tester.pump(const Duration(milliseconds: 240));
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.byKey(const Key('screen04-short-chrome-moolsocial')),
            )
            .opacity,
        1,
      );

      await tester.drag(pageView, const Offset(0, -520));
      await tester.pumpAndSettle();
      await tester.drag(pageView, const Offset(0, -520));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('screen04-short-yt-quick-breakfast-short')),
        findsOneWidget,
      );
      final youtubeMedia = find.byKey(
        const Key('screen04-short-media-youtube'),
      );
      expect(tester.widget<Image>(youtubeMedia).fit, BoxFit.cover);
      expect(tester.getSize(youtubeMedia), tester.getSize(pageView));

      await tester.pump(const Duration(milliseconds: 3000));
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.byKey(const Key('screen04-short-chrome-youtube')),
            )
            .opacity,
        1,
      );
      final youtubeSurface = tester.getRect(
        find.byKey(const Key('screen04-short-yt-quick-breakfast-short')),
      );
      await tester.tapAt(youtubeSurface.topLeft + const Offset(18, 124));
      await tester.pump(const Duration(milliseconds: 240));
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.byKey(const Key('screen04-short-chrome-youtube')),
            )
            .opacity,
        0,
      );
      await tester.tapAt(youtubeSurface.topLeft + const Offset(18, 124));
      await tester.pump(const Duration(milliseconds: 240));
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.byKey(const Key('screen04-short-chrome-youtube')),
            )
            .opacity,
        1,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Feed and Create expose the same direct public-post contract', (
    tester,
  ) async {
    final owners = _Owners();
    addTearDown(owners.dispose);
    await _pump(tester, const Size(390, 844), 1, owners.consumer(sub: 'feed'));
    expect(find.byKey(const Key('screen04-quick-post-feed')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('screen04-quick-post-input-feed')),
      'Fresh arrivals are ready today',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('screen04-quick-post-publish-feed')));
    await tester.pumpAndSettle();
    expect(find.text('Fresh arrivals are ready today'), findsOneWidget);

    await tester.tap(find.byKey(const Key('screen04-rail-create')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen04-create-workbench')), findsOneWidget);
    expect(find.text('Public'), findsOneWidget);
    expect(find.text('Reel'), findsOneWidget);
    expect(find.text('Carousel'), findsOneWidget);
    expect(find.byKey(const Key('screen04-create-tool-image')), findsOneWidget);
    expect(
      find.byKey(const Key('screen04-create-tool-image-poll')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('screen04-create-tool-quick-poll')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('screen04-create-tool-quiz')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'every main action and sub-action keeps its active and next choice visible',
    (tester) async {
      final owners = _Owners();
      addTearDown(owners.dispose);
      await _pump(tester, const Size(320, 568), 1.4, owners.consumer());

      for (final world in screen04Worlds) {
        await tester.tap(find.byKey(const Key('screen04-mool')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(Key('screen04-rail-${world.id}')),
        );
        await tester.tap(find.byKey(Key('screen04-rail-${world.id}')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('screen04-mool')));
        await tester.pumpAndSettle();
        _expectInsideRibbon(
          tester,
          ribbon: const Key('screen04-world-ribbon'),
          item: Key('screen04-rail-${world.id}'),
        );
        final worldIndex = screen04Worlds.indexOf(world);
        final nextWorld =
            screen04Worlds[(worldIndex + 1).clamp(
              0,
              screen04Worlds.length - 1,
            )];
        _expectInsideRibbon(
          tester,
          ribbon: const Key('screen04-world-ribbon'),
          item: Key('screen04-rail-${nextWorld.id}'),
        );
        await tester.tap(find.byKey(const Key('screen04-mool')));
        await tester.pumpAndSettle();

        for (var index = 0; index < world.choices.length; index++) {
          final choice = world.choices[index];
          await tester.tap(find.byKey(Key('screen04-rail-${choice.id}')));
          await tester.pumpAndSettle();
          _expectInsideRibbon(
            tester,
            ribbon: const Key('screen04-choice-ribbon'),
            item: Key('screen04-rail-${choice.id}'),
          );
          final next =
              world.choices[(index + 1).clamp(0, world.choices.length - 1)];
          _expectInsideRibbon(
            tester,
            ribbon: const Key('screen04-choice-ribbon'),
            item: Key('screen04-rail-${next.id}'),
          );
        }
      }
      expect(tester.takeException(), isNull);
    },
  );

  const sizes = <Size>[
    Size(320, 568),
    Size(360, 640),
    Size(360, 720),
    Size(375, 667),
    Size(390, 844),
    Size(412, 915),
    Size(430, 932),
  ];

  for (final size in sizes) {
    for (final scale in const [1.0, 1.4]) {
      testWidgets('all Screen 04 worlds and choices fit '
          '${size.width.toInt()}x${size.height.toInt()} at '
          '${(scale * 100).round()}%', (tester) async {
        for (final world in screen04Worlds) {
          for (final choice in world.choices) {
            final owners = _Owners();
            await _pump(
              tester,
              size,
              scale,
              owners.consumer(world: world.id, sub: choice.id),
            );
            expect(
              tester.takeException(),
              isNull,
              reason: '${world.id}/${choice.id}',
            );
            _expectCustomerCopy(tester, '${world.id}/${choice.id}');
            owners.dispose();
          }
        }
      });
    }
  }

  testWidgets('Screen 04 header actions expose customer destinations', (
    tester,
  ) async {
    final owners = _Owners();
    addTearDown(owners.dispose);
    await _pump(tester, const Size(390, 844), 1, owners.consumer(world: 'buy'));

    await tester.tap(find.byKey(const Key('screen04-area')));
    await tester.pumpAndSettle();
    expect(find.text('Serviceable area'), findsWidgets);
    expect(find.byKey(const Key('screen04-area-input')), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('screen04-notifications')));
    await tester.pumpAndSettle();
    expect(find.text('Notifications'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('screen04-profile')));
    await tester.pumpAndSettle();
    expect(find.text('Your MoolSocial account'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('screen04-search')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('social-v2-search-input')), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('screen04-scan')));
    await tester.pumpAndSettle();
    expect(find.text('Scan a code'), findsWidgets);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('screen04-voice')));
    await tester.pumpAndSettle();
    expect(find.text('Voice search'), findsOneWidget);
    expect(tester.takeException(), isNull);
    _expectCustomerCopy(tester, 'header actions');
  });
}

void _expectInsideRibbon(
  WidgetTester tester, {
  required Key ribbon,
  required Key item,
}) {
  final ribbonRect = tester.getRect(find.byKey(ribbon));
  final itemRect = tester.getRect(find.byKey(item));
  expect(
    itemRect.left,
    greaterThanOrEqualTo(ribbonRect.left - 2),
    reason: '$item should remain visible at the ribbon leading edge',
  );
  expect(
    itemRect.right,
    lessThanOrEqualTo(ribbonRect.right + 2),
    reason: '$item should remain visible at the ribbon trailing edge',
  );
}

Future<void> _pump(
  WidgetTester tester,
  Size size,
  double textScale,
  Widget child,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, fontFamily: 'Inter'),
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: app!,
      ),
      home: child,
    ),
  );
  await tester.pump();
}

void _expectCustomerCopy(WidgetTester tester, String state) {
  final copy = <String>[];
  for (final text in tester.widgetList<Text>(find.byType(Text))) {
    copy.add(text.data ?? text.textSpan?.toPlainText() ?? '');
  }
  for (final field in tester.widgetList<TextField>(find.byType(TextField))) {
    copy.addAll([
      field.decoration?.labelText ?? '',
      field.decoration?.hintText ?? '',
      field.decoration?.helperText ?? '',
    ]);
  }
  for (final semantics in tester.widgetList<Semantics>(
    find.byType(Semantics),
  )) {
    copy.add(semantics.properties.label ?? '');
    copy.add(semantics.properties.tooltip ?? '');
  }
  final visible = copy.where((value) => value.trim().isNotEmpty).join('\n');
  expect(
    _forbiddenScreen04Copy.hasMatch(visible),
    isFalse,
    reason: '$state exposed non-customer copy:\n$visible',
  );
}

class _Owners {
  final journey = JourneySession();
  final creator = CreatorSession();
  final retailer = RetailerSession();
  final shared = SharedSession();

  SocialUniversalV2 consumer({String world = 'social', String? sub}) {
    return SocialUniversalV2(
      session: journey,
      creatorSession: creator,
      retailerSession: retailer,
      sharedSession: shared,
      initialWorld: world,
      initialSubAction: sub,
    );
  }

  void dispose() {
    journey.dispose();
    creator.dispose();
    retailer.dispose();
    shared.dispose();
  }
}

class _AuthenticatedOwners {
  final journey = JourneySession(
    store: MemoryJourneyStore(
      snapshot: const JourneySnapshot(
        languageCode: 'en',
        areaMode: 'current',
        areaLabel: 'Khema-Ka-Kuwa, Jodhpur, Rajasthan',
        setupComplete: true,
      ),
    ),
    otpGateway: ReviewOtpGateway(signedIn: true),
  );
  final creator = CreatorSession()..creatorWorkspaceActive = true;
  final retailer = RetailerSession();
  final shared = SharedSession();

  void dispose() {
    journey.dispose();
    creator.dispose();
    retailer.dispose();
    shared.dispose();
  }
}
