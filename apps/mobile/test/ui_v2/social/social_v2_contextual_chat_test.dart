import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/creator/creator_session.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/retailer/retailer_session.dart';
import 'package:moolsocial/features/shared/shared_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_shop_chat.dart';
import 'package:moolsocial/ui_v2/social/social_v2_consumer.dart';
import 'package:moolsocial/ui_v2/universal/mool_contextual_chat_v2.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Food Travel Care and Work subactions open exact standalone Chat context',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);

      for (final family in _families) {
        for (final subAction in family.subActions) {
          final owners = _Owners();
          await tester.pumpWidget(
            _app(owners, world: family.id, subAction: subAction.id),
          );
          await tester.pumpAndSettle();

          expect(
            find.byKey(Key('screen04-rail-${subAction.id}')),
            findsOneWidget,
          );
          final opensFromHeader = subAction == family.subActions.first;
          await tester.tap(
            find.byKey(
              ValueKey(
                opensFromHeader ? 'social-global-chat' : 'mool-global-chat-tap',
              ),
            ),
          );
          await tester.pumpAndSettle();

          final presentation = MoolContextualChatCatalog.presentationFor(
            family.id,
          );
          expect(find.text(presentation.title), findsOneWidget);
          expect(
            find.text('${subAction.label} · ${presentation.subtitle}'),
            findsOneWidget,
          );
          final filter = tester.widget<ChoiceChip>(
            find.byKey(ValueKey('buy-shop-chat-filter-${subAction.id}')),
          );
          expect(filter.selected, isTrue);
          expect(
            find.byKey(const ValueKey('moolsocial-single-home-launcher-shell')),
            findsNothing,
          );
          expect(
            find.byKey(const ValueKey('screen04-context-tabs')),
            findsNothing,
          );
          if (family.id == 'ride' && subAction.id == 'bike') {
            await tester.tap(find.byKey(const ValueKey('buy-shop-chat-new')));
            await tester.pumpAndSettle();
            for (final threadId in const [
              'travel-bike-support',
              'travel-auto-support',
              'travel-cab-support',
              'travel-bus-desk',
            ]) {
              expect(
                find.byKey(ValueKey('buy-shop-chat-new-$threadId')),
                findsOneWidget,
              );
            }
            await tester.tap(
              find.byKey(const ValueKey('buy-shop-chat-new-back')),
            );
            await tester.pumpAndSettle();
          }

          await tester.tap(find.byKey(const ValueKey('buy-shop-chat-back')));
          await tester.pumpAndSettle();
          expect(find.byKey(const ValueKey('buy-shop-chat')), findsNothing);
          expect(
            find.byKey(Key('screen04-rail-${subAction.id}')),
            findsOneWidget,
          );
          expect(
            find.byKey(const ValueKey('moolsocial-single-home-launcher-shell')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);

          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          owners.dispose();
        }
      }
    },
  );

  testWidgets(
    'context thread keeps attachments calls and send on the runtime action seam',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final owners = _Owners();
      addTearDown(owners.dispose);
      final actions = <BuyV2ShopChatAction>[];

      await tester.pumpWidget(
        _app(
          owners,
          world: 'book',
          subAction: 'medicine',
          onAction: (action) async {
            actions.add(action);
            return const BuyV2ShopChatActionResult.accepted();
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-entry-care-medicine-desk')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Medicine order support'), findsWidgets);
      expect(
        find.text(
          'Messages and shared items appear here after Chat confirms them.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-camera')));
      await tester.pumpAndSettle();
      expect(actions.last.kind, BuyV2ShopChatActionKind.captureImage);

      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-attach')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-attach-selectDocument')),
      );
      await tester.pumpAndSettle();
      expect(actions.last.kind, BuyV2ShopChatActionKind.selectDocument);

      await tester.enterText(
        find.byKey(const ValueKey('buy-shop-chat-composer-field')),
        'Please help with this medicine order',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-send')));
      await tester.pumpAndSettle();
      expect(actions.last.kind, BuyV2ShopChatActionKind.sendText);
      expect(actions.last.threadId, 'care-medicine-desk');
      expect(find.text('Please help with this medicine order'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-commerce-context')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-shop-chat')), findsNothing);
      expect(
        find.byKey(const ValueKey('screen04-rail-medicine')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('context Chat stays usable at 320 width and 140 percent text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.reset);
    final owners = _Owners();
    addTearDown(owners.dispose);

    await tester.pumpWidget(
      _app(owners, world: 'ride', subAction: 'bus', textScale: 1.4),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
    await tester.pumpAndSettle();

    expect(find.text('Travel Chat'), findsOneWidget);
    expect(
      tester
          .widget<ChoiceChip>(
            find.byKey(const ValueKey('buy-shop-chat-filter-bus')),
          )
          .selected,
      isTrue,
    );
    for (final key in const [
      'buy-shop-chat-back',
      'buy-shop-chat-open-all',
      'buy-shop-chat-search',
      'buy-shop-chat-new',
    ]) {
      final size = tester.getSize(find.byKey(ValueKey(key)));
      expect(size.width, greaterThanOrEqualTo(44), reason: '$key width');
      expect(size.height, greaterThanOrEqualTo(44), reason: '$key height');
    }
    expect(tester.takeException(), isNull);
  });

  test('default provisioning covers every published contextual filter', () {
    const source = MoolDefaultContextualChatProvisioningSource();
    for (final family in _families) {
      final threads = source.threadsFor(family.id);
      final threadFilters = threads
          .map((thread) => thread.resolvedFilterId)
          .toSet();
      expect(
        threadFilters,
        containsAll(family.subActions.map((action) => action.id)),
      );
      expect(threads.every((thread) => thread.messages.isEmpty), isTrue);
    }
  });

  testWidgets('contextual Chat family review captures', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    const reviewRootKey = ValueKey('contextual-chat-review-root');

    for (final capture in _captureFamilies) {
      final owners = _Owners();
      await tester.pumpWidget(
        RepaintBoundary(
          key: reviewRootKey,
          child: _app(
            owners,
            world: capture.world,
            subAction: capture.subAction,
            onAction: (_) async => const BuyV2ShopChatActionResult.accepted(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
      await tester.pumpAndSettle();
      await _captureContextChat(tester, '${capture.name}-inbox', reviewRootKey);

      await tester.tap(
        find.byKey(ValueKey('buy-shop-chat-entry-${capture.threadId}')),
      );
      await tester.pumpAndSettle();
      await _captureContextChat(
        tester,
        '${capture.name}-conversation',
        reviewRootKey,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      owners.dispose();
    }
    expect(tester.takeException(), isNull);
  }, skip: true);
}

Future<void> _captureContextChat(
  WidgetTester tester,
  String state,
  Key reviewRootKey,
) async {
  await tester.pump(const Duration(milliseconds: 120));
  await expectLater(
    find.byKey(reviewRootKey),
    matchesGoldenFile(
      'candidate_captures/moolsocial-context-chat-$state-390x844.png',
    ),
  );
}

Widget _app(
  _Owners owners, {
  required String world,
  required String subAction,
  BuyV2ShopChatActionHandler? onAction,
  double textScale = 1,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: MoolTheme.light(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: true,
      ),
      child: child!,
    ),
    home: SocialUniversalV2(
      session: owners.journey,
      creatorSession: owners.creator,
      retailerSession: owners.retailer,
      sharedSession: owners.shared,
      initialWorld: world,
      initialSubAction: subAction,
      onContextualChatAction: onAction,
      youtubePublicAccessOverride: false,
      youtubeCreatorAccessOverride: false,
    ),
  );
}

const _families = <({String id, List<({String id, String label})> subActions})>[
  (
    id: 'eat',
    subActions: [
      (id: 'order-food', label: 'Order Food'),
      (id: 'book-table', label: 'Book Table'),
    ],
  ),
  (
    id: 'ride',
    subActions: [
      (id: 'bike', label: 'Bike'),
      (id: 'auto', label: 'Auto'),
      (id: 'cab', label: 'Cab'),
      (id: 'bus', label: 'Bus'),
    ],
  ),
  (
    id: 'book',
    subActions: [
      (id: 'doctor', label: 'Doctor'),
      (id: 'medicine', label: 'Medicine'),
      (id: 'salon', label: 'Salon'),
    ],
  ),
  (
    id: 'work',
    subActions: [
      (id: 'earn-today', label: 'Earn Today'),
      (id: 'workspace', label: 'Workspace'),
    ],
  ),
];

const _captureFamilies =
    <({String name, String world, String subAction, String threadId})>[
      (
        name: 'food-order-food',
        world: 'eat',
        subAction: 'order-food',
        threadId: 'food-order-support',
      ),
      (
        name: 'travel-cab',
        world: 'ride',
        subAction: 'cab',
        threadId: 'travel-cab-support',
      ),
      (
        name: 'care-doctor',
        world: 'book',
        subAction: 'doctor',
        threadId: 'care-doctor-desk',
      ),
      (
        name: 'work-earn-today',
        world: 'work',
        subAction: 'earn-today',
        threadId: 'work-opportunity-support',
      ),
    ];

class _Owners {
  final journey = JourneySession();
  final creator = CreatorSession();
  final retailer = RetailerSession();
  final shared = SharedSession();

  void dispose() {
    journey.dispose();
    creator.dispose();
    retailer.dispose();
    shared.dispose();
  }
}
