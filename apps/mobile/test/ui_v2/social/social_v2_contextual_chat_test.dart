import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/creator/creator_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
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
            find.textContaining(presentation.securityMessage),
            findsOneWidget,
          );
          expect(
            find.textContaining(
              RegExp(r'\bsecure(?:ly)?\b|\bencrypt', caseSensitive: false),
            ),
            findsNothing,
          );
          expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);
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
    'production Chat return restores every exact contextual family subaction',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);

      for (final family in _families) {
        for (final subAction in family.subActions) {
          final owners = _Owners();
          String? capturedReturnRoute;
          late final GoRouter router;
          router = GoRouter(
            initialLocation: Uri(
              path: '/app/${family.id}',
              queryParameters: {'sub': subAction.id},
            ).toString(),
            routes: [
              GoRoute(
                path: '/app/chat',
                builder: (context, state) {
                  capturedReturnRoute = state.uri.queryParameters['return'];
                  return Scaffold(
                    body: Center(
                      child: FilledButton(
                        key: const ValueKey('follow-contextual-chat-return'),
                        onPressed: () => context.go(capturedReturnRoute!),
                        child: const Text('Return to origin'),
                      ),
                    ),
                  );
                },
              ),
              GoRoute(
                path: '/app/:world',
                builder: (context, state) => SocialUniversalV2(
                  session: owners.journey,
                  creatorSession: owners.creator,
                  retailerSession: owners.retailer,
                  sharedSession: owners.shared,
                  initialWorld: state.pathParameters['world'] ?? 'social',
                  initialSubAction: state.uri.queryParameters['sub'],
                  youtubePublicAccessOverride: false,
                  youtubeCreatorAccessOverride: false,
                ),
              ),
            ],
          );

          await tester.pumpWidget(_routedApp(router));
          await tester.pumpAndSettle();
          final opensFromHeader = subAction == family.subActions.first;
          await tester.tap(
            find.byKey(
              ValueKey(
                opensFromHeader ? 'social-global-chat' : 'mool-global-chat-tap',
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(const ValueKey('buy-shop-chat-open-all')),
          );
          await tester.pumpAndSettle();

          final expectedReturnRoute = Uri(
            path: '/app/${family.id}',
            queryParameters: {'sub': subAction.id},
          ).toString();
          expect(capturedReturnRoute, expectedReturnRoute);
          expect(
            find.byKey(const ValueKey('follow-contextual-chat-return')),
            findsOneWidget,
          );

          router.go(
            Uri(
              path: '/app/chat',
              queryParameters: {'return': capturedReturnRoute!},
            ).toString(),
          );
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(const ValueKey('follow-contextual-chat-return')),
          );
          await tester.pumpAndSettle();
          final restoredLocation = router.routeInformationProvider.value.uri;
          expect(restoredLocation.path, '/app/${family.id}');
          expect(restoredLocation.queryParameters['sub'], subAction.id);
          expect(
            find.byKey(Key('screen04-rail-${subAction.id}')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);

          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          router.dispose();
          owners.dispose();
        }
      }
    },
  );

  testWidgets(
    'thread context returns to the conversation selected inside contextual Chat',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final owners = _Owners();
      addTearDown(owners.dispose);

      await tester.pumpWidget(_app(owners, world: 'ride', subAction: 'bike'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('social-global-chat')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-new')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-new-travel-cab-support')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cab trip support'), findsWidgets);
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-commerce-context')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-shop-chat')), findsNothing);
      expect(find.byKey(const ValueKey('screen04-rail-cab')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
      await tester.pumpAndSettle();
      expect(find.text('Cab · rides and bookings'), findsOneWidget);
      expect(
        tester
            .widget<ChoiceChip>(
              find.byKey(const ValueKey('buy-shop-chat-filter-cab')),
            )
            .selected,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'context Chat handoff carries draft category and exact subaction return',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final owners = _Owners();
      addTearDown(owners.dispose);
      Uri? handoffUri;
      late final GoRouter router;
      router = GoRouter(
        initialLocation: '/app/ride?sub=bike',
        routes: [
          GoRoute(
            path: '/app/chat/inbox',
            builder: (context, state) {
              handoffUri = state.uri;
              return const Scaffold(body: Text('Production Chat inbox'));
            },
          ),
          GoRoute(
            path: '/app/:world',
            builder: (context, state) => SocialUniversalV2(
              session: owners.journey,
              creatorSession: owners.creator,
              retailerSession: owners.retailer,
              sharedSession: owners.shared,
              initialWorld: state.pathParameters['world'] ?? 'social',
              initialSubAction: state.uri.queryParameters['sub'],
              youtubePublicAccessOverride: false,
              youtubeCreatorAccessOverride: false,
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(_routedApp(router));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('social-global-chat')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-new')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-new-travel-cab-support')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('buy-shop-chat-composer-field')),
        'Please check my cab pickup',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-send')));
      await tester.pumpAndSettle();

      expect(find.text('Production Chat inbox'), findsOneWidget);
      expect(handoffUri?.path, '/app/chat/inbox');
      expect(handoffUri?.queryParameters['type'], 'support');
      expect(
        handoffUri?.queryParameters['draft'],
        'Please check my cab pickup',
      );
      expect(handoffUri?.queryParameters['return'], '/app/ride?sub=cab');
      expect(handoffUri?.queryParameters.containsKey('start'), isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('context adapter forwards live provisioning updates', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final owners = _Owners();
    final source = _LiveContextualChatSource();
    addTearDown(source.dispose);
    addTearDown(owners.dispose);

    await tester.pumpWidget(
      _app(
        owners,
        world: 'book',
        subAction: 'doctor',
        contextualChatSource: source,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('social-global-chat')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('buy-shop-chat-entry-live-doctor-support')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-shop-chat-message-live-doctor-message')),
      findsNothing,
    );

    source.publishIncomingMessage();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-shop-chat-message-live-doctor-message')),
      findsOneWidget,
    );
    expect(find.text('Your appointment time is confirmed.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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
      expect(
        find.byKey(const ValueKey('buy-shop-chat-attach-shareProduct')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('buy-shop-chat-attach-shareOrder')),
        findsOneWidget,
      );
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

  testWidgets(
    'Care doctor and medicine threads retain the safety notice at compact size',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      addTearDown(tester.view.reset);

      for (final target in const [
        (subAction: 'doctor', threadId: 'care-doctor-desk'),
        (subAction: 'medicine', threadId: 'care-medicine-desk'),
      ]) {
        final owners = _Owners();
        await tester.pumpWidget(
          _app(
            owners,
            world: 'book',
            subAction: target.subAction,
            textScale: 1.4,
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(ValueKey('buy-shop-chat-entry-${target.threadId}')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('buy-shop-chat-care-safety')),
          findsOneWidget,
        );
        expect(
          find.text(MoolContextualChatCatalog.care.securityMessage),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(
            'Care Chat safety notice. '
            '${MoolContextualChatCatalog.care.securityMessage}',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        owners.dispose();
      }
    },
  );

  testWidgets('context Chat Android Back exposes one-tap Forward history', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.reset);
    final owners = _Owners();
    addTearDown(owners.dispose);

    await tester.pumpWidget(
      _app(owners, world: 'work', subAction: 'workspace', textScale: 1.4),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('buy-shop-chat-entry-work-workspace-support')),
    );
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-shop-chat')), findsOneWidget);
    expect(find.text('Forward to Workspace support'), findsOneWidget);
    final forward = find.byKey(const ValueKey('buy-shop-chat-history-forward'));
    expect(tester.getSize(forward).height, greaterThanOrEqualTo(44));
    expect(
      find.bySemanticsLabel('Navigate forward to Workspace support'),
      findsOneWidget,
    );
    await tester.tap(forward);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-shop-chat-thread')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-shop-chat')), findsNothing);
    expect(
      find.byKey(const ValueKey('screen04-rail-workspace')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'context Chat retains a draft on reopen without leaking to another action',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final owners = _Owners();
      addTearDown(owners.dispose);

      await tester.pumpWidget(
        _app(owners, world: 'work', subAction: 'workspace'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('buy-shop-chat-search')),
        'Workspace',
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey('buy-shop-chat-entry-work-workspace-support'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('buy-shop-chat-composer-field')),
        'Keep this workspace draft',
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-commerce-context')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-shop-chat')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ChoiceChip>(
              find.byKey(const ValueKey('buy-shop-chat-filter-workspace')),
            )
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('buy-shop-chat-search')),
            )
            .controller!
            .text,
        'Workspace',
      );
      await tester.tap(
        find.byKey(
          const ValueKey('buy-shop-chat-entry-work-workspace-support'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('buy-shop-chat-composer-field')),
            )
            .controller!
            .text,
        'Keep this workspace draft',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pumpWidget(
        _app(owners, world: 'work', subAction: 'earn-today'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ChoiceChip>(
              find.byKey(const ValueKey('buy-shop-chat-filter-earn-today')),
            )
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('buy-shop-chat-search')),
            )
            .controller!
            .text,
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('context Chat clears retained identity state on sign-out', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final journey = JourneySession(
      store: MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'manual',
          areaLabel: 'Sardarpura',
          setupComplete: true,
        ),
      ),
      otpGateway: ReviewOtpGateway(signedIn: true),
    );
    await journey.start();
    expect(journey.isAuthenticated, isTrue);
    final owners = _Owners(journey: journey);
    addTearDown(owners.dispose);

    await tester.pumpWidget(
      _app(owners, world: 'work', subAction: 'workspace'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('buy-shop-chat-entry-work-workspace-support')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('buy-shop-chat-composer-field')),
      'Private draft from the signed-in account',
    );
    await tester.pump();

    await journey.signOut();
    await tester.pumpAndSettle();
    expect(journey.isAuthenticated, isFalse);
    expect(find.byKey(const ValueKey('buy-shop-chat')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('buy-shop-chat-entry-work-workspace-support')),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('buy-shop-chat-composer-field')),
          )
          .controller!
          .text,
      isEmpty,
    );
    expect(find.text('Private draft from the signed-in account'), findsNothing);
    expect(tester.takeException(), isNull);
  });

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

    await tester.tap(find.byKey(const ValueKey('buy-shop-chat-new')));
    await tester.pumpAndSettle();
    expect(find.text('Choose a Travel conversation'), findsOneWidget);
    expect(
      find.textContaining(
        RegExp(r'\bnew\s+Travel\s+conversation\b', caseSensitive: false),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('buy-shop-chat-new-back')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('buy-shop-chat-entry-travel-bus-desk')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-shop-chat-composer')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-shop-chat-care-safety')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('buy-shop-chat-attach')));
    await tester.pumpAndSettle();
    expect(find.text('Share in this Travel chat'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('buy-shop-chat-attach-shareProduct')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('buy-shop-chat-attach')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-shop-chat-thread-info')));
    await tester.pumpAndSettle();
    expect(find.text('Travel Chat info'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('context Chat search clear announces its exact subaction', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final owners = _Owners();
    addTearDown(owners.dispose);

    await tester.pumpWidget(_app(owners, world: 'book', subAction: 'medicine'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('buy-shop-chat-search')),
      'delivery',
    );
    await tester.pump();

    expect(
      find.byTooltip('Clear Medicine conversations search'),
      findsOneWidget,
    );
    expect(find.byTooltip('Clear Shop Chat search'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'every family keeps contextual identity through Chat utility depths',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);

      for (final capture in _captureFamilies) {
        final owners = _Owners();
        await tester.pumpWidget(
          _app(owners, world: capture.world, subAction: capture.subAction),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
        await tester.pumpAndSettle();

        final presentation = MoolContextualChatCatalog.presentationFor(
          capture.world,
        );
        await tester.tap(find.byKey(const ValueKey('buy-shop-chat-new')));
        await tester.pumpAndSettle();
        expect(
          find.text('Choose a ${presentation.familyLabel} conversation'),
          findsOneWidget,
        );
        expect(
          find.text('MoolSocial Chat · choose a conversation context'),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('buy-shop-chat-new-back')));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(ValueKey('buy-shop-chat-entry-${capture.threadId}')),
        );
        await tester.pumpAndSettle();
        expect(
          find.textContaining('${presentation.familyLabel} ·'),
          findsWidgets,
        );

        await tester.tap(
          find.byKey(const ValueKey('buy-shop-chat-thread-more')),
        );
        await tester.pumpAndSettle();
        expect(find.text('${presentation.familyLabel} info'), findsOneWidget);
        await tester.tap(
          find.byKey(const ValueKey('buy-shop-chat-menu-search')),
        );
        await tester.pumpAndSettle();
        final search = tester.widget<TextField>(
          find.byKey(const ValueKey('buy-shop-chat-message-search-field')),
        );
        expect(search.decoration?.hintText, contains(capture.threadTitle));
        await tester.tap(
          find.byKey(const ValueKey('buy-shop-chat-message-search-close')),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('buy-shop-chat-attach')));
        await tester.pumpAndSettle();
        expect(
          find.text('Share in this ${presentation.familyLabel} chat'),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('buy-shop-chat-attach-shareProduct')),
          capture.world == 'eat' ? findsOneWidget : findsNothing,
        );
        expect(
          find.byKey(const ValueKey('buy-shop-chat-attach-shareOrder')),
          capture.world == 'eat' ? findsOneWidget : findsNothing,
        );
        await tester.tap(find.byKey(const ValueKey('buy-shop-chat-attach')));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey('buy-shop-chat-thread-info')),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('${presentation.familyLabel} Chat info'),
          findsOneWidget,
        );
        expect(find.text(capture.contextTitle), findsWidgets);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        owners.dispose();
      }
    },
  );

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
      final customerCopy = <String>[
        MoolContextualChatCatalog.presentationFor(family.id).securityMessage,
        ...threads.map((thread) => thread.detail),
      ];
      expect(
        customerCopy.where(
          RegExp(r'\bsecure(?:ly)?\b|\bencrypt', caseSensitive: false).hasMatch,
        ),
        isEmpty,
      );
    }

    final food = source.threadsFor('eat');
    expect(food.first.capabilities.productSharing, isTrue);
    expect(food.last.capabilities.productSharing, isFalse);

    final travel = source.threadsFor('ride');
    expect(
      travel.every(
        (thread) =>
            !thread.capabilities.productSharing &&
            !thread.capabilities.orderSharing,
      ),
      isTrue,
    );

    final care = source.threadsFor('book');
    expect(care[0].capabilities.productSharing, isFalse);
    expect(care[1].capabilities.productSharing, isTrue);
    expect(care[2].capabilities.productSharing, isFalse);

    final work = source.threadsFor('work');
    expect(work.every((thread) => !thread.capabilities.productSharing), isTrue);
    expect(work.last.capabilities.locationSharing, isFalse);
  });

  test('context adapter forwards the backend loading contract', () async {
    final source = _LoadingContextualChatSource();
    final adapter = MoolContextualChatSourceAdapter(
      familyId: 'ride',
      source: source,
    );
    addTearDown(source.dispose);

    expect(adapter.loadState, BuyV2ShopChatLoadState.failed);
    expect(
      adapter.loadErrorMessage,
      'Travel conversations could not load. Try again.',
    );
    await adapter.retryLoading();
    expect(source.retryCalls, 1);
    expect(adapter.loadState, BuyV2ShopChatLoadState.ready);
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

      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-new')));
      await tester.pumpAndSettle();
      await _captureContextChat(
        tester,
        '${capture.name}-new-conversation',
        reviewRootKey,
      );
      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-new-back')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(ValueKey('buy-shop-chat-entry-${capture.threadId}')),
      );
      await tester.pumpAndSettle();
      await _captureContextChat(
        tester,
        '${capture.name}-conversation',
        reviewRootKey,
      );

      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-attach')));
      await tester.pumpAndSettle();
      await _captureContextChat(
        tester,
        '${capture.name}-attachments',
        reviewRootKey,
      );
      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-attach')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-thread-info')));
      await tester.pumpAndSettle();
      await _captureContextChat(
        tester,
        '${capture.name}-conversation-info',
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
  MoolContextualChatProvisioningSource contextualChatSource =
      const MoolDefaultContextualChatProvisioningSource(),
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
      contextualChatSource: contextualChatSource,
      youtubePublicAccessOverride: false,
      youtubeCreatorAccessOverride: false,
    ),
  );
}

Widget _routedApp(GoRouter router) {
  return MaterialApp.router(
    debugShowCheckedModeBanner: false,
    theme: MoolTheme.light(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child!,
    ),
    routerConfig: router,
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
    <
      ({
        String name,
        String world,
        String subAction,
        String threadId,
        String threadTitle,
        String contextTitle,
      })
    >[
      (
        name: 'food-order-food',
        world: 'eat',
        subAction: 'order-food',
        threadId: 'food-order-support',
        threadTitle: 'Food order support',
        contextTitle: 'Order Food',
      ),
      (
        name: 'travel-cab',
        world: 'ride',
        subAction: 'cab',
        threadId: 'travel-cab-support',
        threadTitle: 'Cab trip support',
        contextTitle: 'Cab trip',
      ),
      (
        name: 'care-doctor',
        world: 'book',
        subAction: 'doctor',
        threadId: 'care-doctor-desk',
        threadTitle: 'Doctor booking',
        contextTitle: 'Doctor appointment',
      ),
      (
        name: 'work-earn-today',
        world: 'work',
        subAction: 'earn-today',
        threadId: 'work-opportunity-support',
        threadTitle: 'Work opportunity',
        contextTitle: 'Earn Today',
      ),
    ];

class _LiveContextualChatSource extends ChangeNotifier
    implements MoolContextualChatProvisioningSource {
  _LiveContextualChatSource() : _threads = [_thread()];

  List<BuyV2ShopChatThread> _threads;

  @override
  List<BuyV2ShopChatThread> threadsFor(String familyId) => familyId == 'book'
      ? List<BuyV2ShopChatThread>.unmodifiable(_threads)
      : const [];

  void publishIncomingMessage() {
    _threads = [
      _thread(
        messages: const [
          BuyV2ShopChatMessage(
            id: 'live-doctor-message',
            kind: BuyV2ShopChatMessageKind.text,
            fromCurrentUser: false,
            sentAtLabel: 'Now',
            body: 'Your appointment time is confirmed.',
          ),
        ],
      ),
    ];
    notifyListeners();
  }

  static BuyV2ShopChatThread _thread({
    List<BuyV2ShopChatMessage> messages = const [],
  }) => BuyV2ShopChatThread(
    id: 'live-doctor-support',
    filter: BuyV2ShopChatFilter.orders,
    filterId: 'doctor',
    participantKind: BuyV2ShopChatParticipantKind.doctorDesk,
    title: 'Live doctor support',
    subtitle: 'Appointment coordination',
    detail: 'Booking support only · not medical advice',
    icon: Icons.medical_services_outlined,
    accent: Color(0xFF00757B),
    contextTitle: 'Doctor appointment',
    contextDetail: 'Provider, fee and appointment time context',
    messages: messages,
    capabilities: BuyV2ShopChatCapabilities(
      productSharing: false,
      orderSharing: false,
    ),
  );
}

class _LoadingContextualChatSource extends ChangeNotifier
    implements MoolContextualChatProvisioningSource, BuyV2ShopChatLoadSource {
  @override
  BuyV2ShopChatLoadState loadState = BuyV2ShopChatLoadState.failed;
  @override
  String? loadErrorMessage = 'Travel conversations could not load. Try again.';
  int retryCalls = 0;

  @override
  List<BuyV2ShopChatThread> threadsFor(String familyId) => const [];

  @override
  Future<void> retryLoading() async {
    retryCalls += 1;
    loadState = BuyV2ShopChatLoadState.ready;
    loadErrorMessage = null;
    notifyListeners();
  }
}

class _Owners {
  _Owners({JourneySession? journey}) : journey = journey ?? JourneySession();

  final JourneySession journey;
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
