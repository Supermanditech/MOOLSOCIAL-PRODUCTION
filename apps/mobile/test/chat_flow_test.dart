import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/chat/chat_models.dart';
import 'package:moolsocial/features/chat/chat_services.dart';
import 'package:moolsocial/features/chat/chat_session.dart';
import 'package:moolsocial/features/chat/widgets/chat_motion.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/shared/shared_models.dart';
import 'package:moolsocial/features/shared/social_content_gateway.dart';
import 'package:moolsocial/features/shared/shared_session.dart';

void main() {
  Future<JourneySession> readyJourney() async {
    final session = JourneySession(
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
    await session.start();
    return session;
  }

  Future<void> mount(
    WidgetTester tester, {
    required String route,
    required JourneySession journey,
    required ChatSession chat,
    SharedSession? sharedSession,
    Size size = const Size(412, 915),
  }) async {
    await tester.binding.setSurfaceSize(size);
    await tester.pumpWidget(
      MoolSocialApp(
        key: ValueKey(route),
        session: journey,
        chatSession: chat,
        sharedSession: sharedSession,
        initialLocation: route,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    if (finder.evaluate().isEmpty) {
      final scrollables = find.byType(Scrollable);
      expect(
        scrollables,
        findsWidgets,
        reason: 'No scrollable can reveal tap target $key',
      );
      for (final element in scrollables.evaluate()) {
        final scrollable = find.byElementPredicate(
          (candidate) => identical(candidate, element),
        );
        final axis = tester.widget<Scrollable>(scrollable).axisDirection;
        if (axis == AxisDirection.left || axis == AxisDirection.right) {
          await tester.drag(scrollable, const Offset(2000, 0));
          await tester.pumpAndSettle();
          for (
            var attempt = 0;
            attempt < 6 && finder.evaluate().isEmpty;
            attempt += 1
          ) {
            await tester.drag(scrollable, const Offset(-220, 0));
            await tester.pumpAndSettle();
          }
        }
      }
      if (finder.evaluate().isEmpty) {
        for (final element in scrollables.evaluate()) {
          final scrollable = find.byElementPredicate(
            (candidate) => identical(candidate, element),
          );
          final axis = tester.widget<Scrollable>(scrollable).axisDirection;
          if (axis == AxisDirection.up || axis == AxisDirection.down) {
            for (
              var attempt = 0;
              attempt < 8 && finder.evaluate().isEmpty;
              attempt += 1
            ) {
              await tester.drag(scrollable, const Offset(0, -220));
              await tester.pumpAndSettle();
            }
          }
        }
      }
    }
    expect(finder, findsOneWidget, reason: 'Missing tap target $key');
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'inbox completes search, filters, consent-safe new chat and protected return route',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final journey = await readyJourney();
      final chat = ChatSession(
        sendGateway: ReviewChatSendGateway(latency: Duration.zero),
      );
      addTearDown(journey.dispose);
      addTearDown(chat.dispose);
      await mount(
        tester,
        route: '/app/chat/inbox?return=/app/buy/grocery',
        journey: journey,
        chat: chat,
      );

      expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('chat-search-field')),
        'not a conversation',
      );
      await tester.pumpAndSettle();
      expect(find.text('No matching conversations'), findsOneWidget);
      tester.view.viewInsets = const FakeViewPadding(bottom: 320);
      await tester.pumpAndSettle();
      final emptyTitle = tester.getRect(find.text('No matching conversations'));
      final navigation = tester.getRect(
        find.byKey(const Key('chat-native-navigation')),
      );
      expect(emptyTitle.bottom, lessThanOrEqualTo(navigation.top));
      tester.view.viewInsets = const FakeViewPadding();
      await tester.pumpAndSettle();
      await tapVisible(tester, const Key('chat-reset-search'));

      await tapVisible(tester, const Key('chat-filter-unread'));
      expect(
        find.byKey(const Key('chat-open-thread-home-basket')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('chat-open-thread-shop-order')),
        findsOneWidget,
      );

      await tapVisible(tester, const Key('chat-new'));
      expect(
        find.byKey(const ValueKey('chat-section-body-discover')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('chat-new-open-feed')), findsNothing);
      expect(find.byKey(const Key('chat-new-discover-people')), findsNothing);
      await tapVisible(tester, const Key('chat-section-chats'));
      await tapVisible(tester, const Key('chat-filter-all'));

      await tapVisible(tester, const Key('chat-search-assistance'));
      expect(
        find.text('Type a person, business, order or case.'),
        findsOneWidget,
      );
      expect(find.textContaining('Speak'), findsNothing);
      await tapVisible(tester, const Key('chat-use-search-assistance'));
      expect(find.text('Enter a conversation name.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('chat-search-assistance-field')),
        'Fresh Basket',
      );
      await tapVisible(tester, const Key('chat-use-search-assistance'));
      expect(
        find.byKey(const Key('chat-open-thread-shop-order')),
        findsOneWidget,
      );

      await tapVisible(tester, const Key('chat-open-thread-shop-order'));
      expect(find.byKey(const Key('chat-thread-screen')), findsOneWidget);
      expect(find.text('Your grocery order is being packed.'), findsOneWidget);
      await tapVisible(tester, const Key('chat-back'));
      expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);
      expect(find.byKey(const Key('chat-back')), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('buy-v2-screen')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Search motion is finite and reduced motion resolves static', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final journey = await readyJourney();
    final chat = ChatSession(
      sendGateway: ReviewChatSendGateway(latency: Duration.zero),
    );
    addTearDown(journey.dispose);
    addTearDown(chat.dispose);
    await mount(
      tester,
      route: '/app/chat/inbox?return=/app/mool',
      journey: journey,
      chat: chat,
    );

    AnimatedContainer focusMotion() => tester.widget<AnimatedContainer>(
      find.byKey(const Key('chat-search-focus-motion')),
    );
    AnimatedSwitcher actionMotion() => tester.widget<AnimatedSwitcher>(
      find.descendant(
        of: find.byKey(const Key('chat-search-action-icon-motion')),
        matching: find.byType(AnimatedSwitcher),
      ),
    );
    TweenAnimationBuilder<double> entryMotion() =>
        tester.widget<TweenAnimationBuilder<double>>(
          find.descendant(
            of: find.byKey(const Key('chat-thread-entry-motion-home-basket')),
            matching: find.byType(TweenAnimationBuilder<double>),
          ),
        );

    expect(focusMotion().duration, ChatMotion.focus);
    expect(actionMotion().duration, ChatMotion.focus);
    expect(
      entryMotion().duration,
      Duration(milliseconds: ChatMotion.stateChange.inMilliseconds + 100),
    );

    final field = find.byKey(const Key('chat-search-field'));
    await tester.tap(field);
    await tester.enterText(field, 'Home');
    await tester.pump();
    expect(find.byKey(const Key('chat-clear-search')), findsOneWidget);
    expect(find.byKey(const Key('chat-search-assistance')), findsNothing);
    await tester.tap(find.byKey(const Key('chat-clear-search')));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(field).controller?.text, isEmpty);
    expect(find.byKey(const Key('chat-search-assistance')), findsOneWidget);

    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    await tester.pump();
    expect(focusMotion().duration, Duration.zero);
    expect(actionMotion().duration, Duration.zero);
    expect(entryMotion().duration, Duration.zero);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Inbox, thread and composer motion resolve static when reduced', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final journey = await readyJourney();
    final chat = ChatSession(
      sendGateway: ReviewChatSendGateway(latency: Duration.zero),
    );
    addTearDown(journey.dispose);
    addTearDown(chat.dispose);
    await mount(
      tester,
      route: '/app/chat/inbox?return=/app/mool',
      journey: journey,
      chat: chat,
    );

    TweenAnimationBuilder<double> routeMotion() =>
        tester.widget<TweenAnimationBuilder<double>>(
          find.byKey(const Key('chat-route-entry-tween')),
        );
    TweenAnimationBuilder<double> incomingMotion(Object stateKey) =>
        tester.widget<TweenAnimationBuilder<double>>(
          find.byKey(ValueKey<Object>('chat-incoming-motion-tween-$stateKey')),
        );

    expect(routeMotion().duration, ChatMotion.routeChange);
    for (final scale in tester.widgetList<AnimatedScale>(
      find.byKey(const Key('chat-selection-motion')),
    )) {
      expect(scale.duration, ChatMotion.focus);
    }
    expect(
      incomingMotion('home-basket').duration,
      Duration(milliseconds: ChatMotion.stateChange.inMilliseconds + 100),
    );

    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    await tester.pump();
    expect(routeMotion().duration, Duration.zero);
    for (final scale in tester.widgetList<AnimatedScale>(
      find.byKey(const Key('chat-selection-motion')),
    )) {
      expect(scale.duration, Duration.zero);
    }
    expect(incomingMotion('home-basket').duration, Duration.zero);
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
    await tester.pump();

    await tapVisible(tester, const Key('chat-open-thread-home-basket'));
    expect(routeMotion().duration, ChatMotion.routeChange);
    expect(incomingMotion('m1').duration, ChatMotion.stateChange);
    final composerIcon = find.descendant(
      of: find.byKey(const Key('chat-composer-action-icon-motion')),
      matching: find.byType(AnimatedSwitcher),
    );
    expect(
      tester.widget<AnimatedSwitcher>(composerIcon).duration,
      ChatMotion.focus,
    );
    final attachmentMotion = find.descendant(
      of: find.byKey(const Key('chat-attachment-expand-motion')),
      matching: find.byType(AnimatedSize),
    );
    expect(
      tester.widget<AnimatedSize>(attachmentMotion).duration,
      ChatMotion.stateChange,
    );
    await tapVisible(tester, const Key('chat-attach'));
    expect(find.byKey(const Key('chat-attachment-tray')), findsOneWidget);
    expect(
      ChatMotion.sheetStyle(
        tester.element(find.byKey(const Key('chat-thread-screen'))),
      ).duration,
      ChatMotion.routeChange,
    );

    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    await tester.pump();
    expect(routeMotion().duration, Duration.zero);
    expect(incomingMotion('m1').duration, Duration.zero);
    expect(
      tester.widget<AnimatedSwitcher>(composerIcon).duration,
      Duration.zero,
    );
    expect(
      tester.widget<AnimatedSize>(attachmentMotion).duration,
      Duration.zero,
    );
    expect(
      ChatMotion.sheetStyle(
        tester.element(find.byKey(const Key('chat-thread-screen'))),
      ).duration,
      Duration.zero,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Android Back dismisses transient Chat surfaces before leaving their owner',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final journey = await readyJourney();
      final chat = ChatSession(
        sendGateway: ReviewChatSendGateway(latency: Duration.zero),
      );
      addTearDown(journey.dispose);
      addTearDown(chat.dispose);
      await mount(
        tester,
        route: '/app/chat/inbox?return=/app/mool',
        journey: journey,
        chat: chat,
      );

      await tapVisible(tester, const Key('chat-search-assistance'));
      expect(
        find.byKey(const Key('chat-search-assistance-field')),
        findsOneWidget,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('chat-search-assistance-field')),
        findsNothing,
      );
      expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);

      await tapVisible(tester, const Key('chat-open-thread-home-basket'));
      await tester.longPress(find.byKey(const Key('chat-message-m1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-message-actions')), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-message-actions')), findsNothing);
      expect(find.byKey(const Key('chat-thread-screen')), findsOneWidget);

      await tapVisible(tester, const Key('chat-voice-message'));
      expect(
        find.byKey(const Key('chat-voice-message-recovery')),
        findsOneWidget,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('chat-voice-message-recovery')),
        findsNothing,
      );
      expect(find.byKey(const Key('chat-thread-screen')), findsOneWidget);

      await tapVisible(tester, const Key('chat-thread-video'));
      expect(find.byKey(const Key('chat-video-recovery')), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-video-recovery')), findsNothing);
      expect(find.byKey(const Key('chat-thread-screen')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Start conversation opens public Feed discovery inside Chat', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final journey = await readyJourney();
    final chat = ChatSession(
      sendGateway: ReviewChatSendGateway(latency: Duration.zero),
    );
    addTearDown(journey.dispose);
    addTearDown(chat.dispose);
    await mount(
      tester,
      route: '/app/chat/inbox?return=/app/work/my-work',
      journey: journey,
      chat: chat,
      size: const Size(360, 800),
    );

    await tapVisible(tester, const Key('chat-new'));
    expect(
      find.byKey(const ValueKey('chat-section-body-discover')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('chat-new')), findsNothing);
    await tapVisible(tester, const Key('chat-discover-open-feed'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('chat-section-body-discover')),
      findsOneWidget,
    );
    expect(find.text('Public Feed unavailable'), findsOneWidget);
    expect(find.byKey(const Key('chat-feed-retry')), findsOneWidget);
    expect(find.byKey(const Key('chat-feed-back-to-chats')), findsOneWidget);
    expect(
      tester.getBottomRight(find.byKey(const Key('chat-feed-retry'))).dy,
      lessThanOrEqualTo(728),
    );
    expect(
      tester
          .getBottomRight(find.byKey(const Key('chat-feed-back-to-chats')))
          .dy,
      lessThanOrEqualTo(728),
    );
    expect(find.byKey(const Key('chat-new')), findsNothing);
    expect(find.byKey(const Key('screen04-universal-v2')), findsNothing);
    await tapVisible(tester, const Key('chat-feed-back-to-chats'));
    expect(
      find.byKey(const ValueKey('chat-section-body-chats')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('chat-new')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty inbox separates Open Feed from the Person+ action', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final journey = await readyJourney();
    final chat = ChatSession.production(gateway: _PeopleChatGateway());
    addTearDown(journey.dispose);
    addTearDown(chat.dispose);
    await mount(
      tester,
      route: '/app/chat/inbox?return=/app/mool',
      journey: journey,
      chat: chat,
      size: const Size(320, 568),
    );
    await tester.pumpAndSettle();

    final openFeed = find.byKey(const Key('chat-open-feed'));
    final startConversation = find.byKey(const Key('chat-empty-start'));
    expect(openFeed, findsOneWidget);
    expect(startConversation, findsOneWidget);
    expect(find.byKey(const Key('chat-new')), findsNothing);
    final feedRect = tester.getRect(openFeed);
    final startRect = tester.getRect(startConversation);
    final navigationRect = tester.getRect(
      find.byKey(const Key('chat-native-navigation')),
    );
    expect(feedRect.overlaps(startRect), isFalse);
    expect(feedRect.overlaps(navigationRect), isFalse);
    expect(startRect.overlaps(navigationRect), isFalse);
    expect(feedRect.width, greaterThanOrEqualTo(44));
    expect(feedRect.height, greaterThanOrEqualTo(44));
    expect(startRect.width, greaterThanOrEqualTo(44));
    expect(startRect.height, greaterThanOrEqualTo(44));
    expect(feedRect.left, greaterThanOrEqualTo(0));
    expect(startRect.right, lessThanOrEqualTo(320));
    expect(feedRect.bottom, lessThanOrEqualTo(navigationRect.top));
    expect(startRect.bottom, lessThanOrEqualTo(navigationRect.top));

    await tester.tap(startConversation);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('chat-section-body-discover')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Open Feed continues through approved message requests', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final journey = await readyJourney();
    final socialGateway = _PeopleSocialGateway();
    final shared = SharedSession(socialContentGateway: socialGateway);
    final chatGateway = _PeopleChatGateway();
    final chat = ChatSession.production(gateway: chatGateway);
    addTearDown(journey.dispose);
    addTearDown(shared.dispose);
    addTearDown(chat.dispose);
    await mount(
      tester,
      route: '/app/chat/inbox?return=/app/work/my-work',
      journey: journey,
      chat: chat,
      sharedSession: shared,
      size: const Size(360, 800),
    );

    await tapVisible(tester, const Key('chat-more'));
    expect(find.text('Open public Feed'), findsOneWidget);
    await tester.tap(find.text('Open public Feed'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);
    expect(find.text('Alice News'), findsWidgets);
    expect(find.text('Public discovery post'), findsWidgets);

    await tapVisible(tester, const Key('social-public-like-post-a'));
    await tester.pumpAndSettle();
    expect(socialGateway.interactions, [('post-a', 'like')]);

    await tapVisible(tester, const Key('social-author-profile-post-a'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('social-author-panel-person-a')),
      findsOneWidget,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);

    await tapVisible(tester, const Key('social-message-author-post-a'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('social-message-request-dialog-person-a')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('social-message-request-send')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);
    expect(chatGateway.createdTargets, isEmpty);
    expect(find.textContaining('awaiting approval'), findsOneWidget);

    await tapVisible(tester, const Key('social-global-chat'));
    expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);
    await tapVisible(tester, const Key('chat-section-discover'));
    expect(
      find.byKey(const ValueKey('chat-section-body-discover')),
      findsOneWidget,
    );
    await tapVisible(tester, const Key('chat-person-connect-person-b'));
    await tapVisible(tester, const Key('chat-person-message-person-b'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('chat-message-request-dialog-person-b')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('chat-message-request-send')));
    await tester.pumpAndSettle();
    expect(chatGateway.createdTargets, isEmpty);
    expect(find.text('Awaiting approval'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('chat-section-body-discover')),
      findsOneWidget,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Discover follows people and keeps private chat approval-gated', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final journey = await readyJourney();
    final socialGateway = _PeopleSocialGateway();
    final shared = SharedSession(socialContentGateway: socialGateway);
    final chatGateway = _PeopleChatGateway();
    final chat = ChatSession.production(gateway: chatGateway);
    addTearDown(journey.dispose);
    addTearDown(shared.dispose);
    addTearDown(chat.dispose);

    await mount(
      tester,
      route: '/app/chat/inbox?return=/app/social?sub=feed',
      journey: journey,
      chat: chat,
      sharedSession: shared,
    );

    expect(find.byKey(const Key('chat-section-chats')), findsOneWidget);
    await tapVisible(tester, const Key('chat-section-discover'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-person-person-a')), findsOneWidget);
    expect(find.byKey(const Key('chat-person-person-b')), findsOneWidget);
    expect(find.text('Alice News'), findsOneWidget);
    expect(find.text('Bharat Creator'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('chat-person-message-person-b')),
          )
          .onPressed,
      isNotNull,
    );

    await tapVisible(tester, const Key('chat-person-connect-person-a'));
    expect(socialGateway.followed['person-a'], isTrue);
    expect(find.widgetWithText(OutlinedButton, 'Following'), findsOneWidget);

    await tapVisible(tester, const Key('chat-section-people'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-person-person-a')), findsOneWidget);
    expect(find.byKey(const Key('chat-person-person-b')), findsNothing);

    await tapVisible(tester, const Key('chat-section-discover'));
    await tester.pumpAndSettle();
    await tapVisible(tester, const Key('chat-person-connect-person-b'));
    expect(socialGateway.followed['person-b'], isTrue);
    await tapVisible(tester, const Key('chat-person-message-person-b'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('chat-message-request-dialog-person-b')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('chat-message-request-send')));
    await tester.pumpAndSettle();
    expect(chatGateway.createdTargets, isEmpty);
    expect(find.text('Awaiting approval'), findsOneWidget);
    expect(find.byKey(const Key('chat-thread-screen')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Following search, clear and unfollow complete without a dead end',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final journey = await readyJourney();
      final socialGateway = _PeopleSocialGateway();
      final shared = SharedSession(socialContentGateway: socialGateway);
      final chat = ChatSession.production(gateway: _PeopleChatGateway());
      addTearDown(journey.dispose);
      addTearDown(shared.dispose);
      addTearDown(chat.dispose);

      await mount(
        tester,
        route: '/app/chat/inbox?return=/app/mool',
        journey: journey,
        chat: chat,
        sharedSession: shared,
      );
      await tapVisible(tester, const Key('chat-section-discover'));

      expect(
        tester
            .widget<AnimatedContainer>(
              find.byKey(const Key('chat-people-search-focus-motion')),
            )
            .duration,
        ChatMotion.focus,
      );
      expect(
        tester
            .widget<TweenAnimationBuilder<double>>(
              find.byKey(
                const ValueKey<Object>('chat-incoming-motion-tween-person-a'),
              ),
            )
            .duration,
        ChatMotion.stateChange,
      );

      await tester.enterText(
        find.byKey(const Key('chat-people-search')),
        'Bharat',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-person-person-a')), findsNothing);
      expect(find.byKey(const Key('chat-person-person-b')), findsOneWidget);
      await tapVisible(tester, const Key('chat-people-search-clear'));
      expect(find.byKey(const Key('chat-person-person-a')), findsOneWidget);
      expect(find.byKey(const Key('chat-person-person-b')), findsOneWidget);

      await tapVisible(tester, const Key('chat-person-connect-person-a'));
      expect(socialGateway.followed['person-a'], isTrue);
      await tapVisible(tester, const Key('chat-section-people'));
      expect(find.byKey(const Key('chat-person-person-a')), findsOneWidget);
      await tapVisible(tester, const Key('chat-person-connect-person-a'));
      expect(socialGateway.followed['person-a'], isFalse);
      expect(find.text('You are not following anyone yet'), findsOneWidget);

      await tapVisible(tester, const Key('chat-people-open-discover'));
      expect(
        find.byKey(const ValueKey('chat-section-body-discover')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('chat-person-person-a')), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('chat-person-message-person-a')),
            )
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('People first-load error retries into the completed directory', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final journey = await readyJourney();
    final socialGateway = _RetryPeopleSocialGateway();
    final shared = SharedSession(socialContentGateway: socialGateway);
    final chat = ChatSession.production(gateway: _PeopleChatGateway());
    addTearDown(journey.dispose);
    addTearDown(shared.dispose);
    addTearDown(chat.dispose);

    await mount(
      tester,
      route: '/app/chat/inbox?return=/app/mool',
      journey: journey,
      chat: chat,
      sharedSession: shared,
    );
    await tapVisible(tester, const Key('chat-section-discover'));

    expect(socialGateway.feedCalls, 1);
    expect(find.byKey(const Key('chat-people-retry')), findsOneWidget);
    expect(find.byKey(const Key('chat-person-person-a')), findsNothing);
    await tapVisible(tester, const Key('chat-people-retry'));

    expect(socialGateway.feedCalls, 2);
    expect(find.byKey(const Key('chat-people-retry')), findsNothing);
    expect(find.byKey(const Key('chat-person-person-a')), findsOneWidget);
    expect(find.byKey(const Key('chat-person-person-b')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Chat keeps a high-contrast add-person action on a native root', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final journey = await readyJourney();
    final chat = ChatSession(
      sendGateway: ReviewChatSendGateway(latency: Duration.zero),
    );
    addTearDown(journey.dispose);
    addTearDown(chat.dispose);
    await mount(
      tester,
      route: '/app/chat/inbox?return=/app/social',
      journey: journey,
      chat: chat,
      size: const Size(360, 800),
    );

    final newChat = tester.widget<FilledButton>(
      find.byKey(const Key('chat-new')),
    );
    expect(
      newChat.style?.backgroundColor?.resolve(const <WidgetState>{}),
      const Color(0xFF000080),
    );
    expect(
      newChat.style?.foregroundColor?.resolve(const <WidgetState>{}),
      Colors.white,
    );
    expect(
      find.ancestor(
        of: find.byKey(const Key('chat-new')),
        matching: find.byType(CustomScrollView),
      ),
      findsOneWidget,
    );

    expect(find.byKey(const Key('chat-global-edge-navigation')), findsNothing);
    expect(
      find.byKey(const Key('chat-compact-global-edge-rail')),
      findsNothing,
    );
    expect(find.byKey(const Key('mool-compact-launcher')), findsNothing);
    expect(find.byKey(const Key('chat-global-chat-edge')), findsNothing);
    expect(find.byKey(const Key('chat-inbox-back')), findsOneWidget);
    expect(find.byKey(const Key('chat-native-navigation')), findsOneWidget);
    final addPerson = find.byKey(const Key('chat-new'));
    expect(tester.getSize(addPerson).width, greaterThanOrEqualTo(44));
    expect(tester.getSize(addPerson).height, greaterThanOrEqualTo(44));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Chat section motion resolves immediately for reduced motion', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final journey = await readyJourney();
    final chat = ChatSession(
      sendGateway: ReviewChatSendGateway(latency: Duration.zero),
    );
    addTearDown(journey.dispose);
    addTearDown(chat.dispose);
    await mount(
      tester,
      route: '/app/chat/inbox?return=/app/social',
      journey: journey,
      chat: chat,
    );

    final switcher = tester.widget<AnimatedSwitcher>(
      find.byKey(const Key('chat-section-motion')),
    );
    expect(switcher.duration, Duration.zero);
    expect(switcher.reverseDuration, Duration.zero);

    await tester.tap(find.byKey(const Key('chat-section-discover')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('chat-section-body-discover')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Universal Chat choices open the matching production inbox', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final journey = await readyJourney();
    final chat = ChatSession(
      sendGateway: ReviewChatSendGateway(latency: Duration.zero),
    );
    addTearDown(journey.dispose);
    addTearDown(chat.dispose);

    for (final branch in const [
      ('people', ChatThreadType.people, 'home-basket'),
      ('business-chat', ChatThreadType.business, 'mahadev'),
      ('orders', ChatThreadType.order, 'rasoi'),
      ('support', ChatThreadType.support, 'order-support'),
    ]) {
      await mount(
        tester,
        route: '/app/chat?sub=${branch.$1}&return=/app/social',
        journey: journey,
        chat: chat,
      );
      expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);
      expect(chat.selectedFilter, branch.$2);
      expect(find.byKey(Key('chat-open-thread-${branch.$3}')), findsOneWidget);
    }
  });

  testWidgets(
    'people chat supports reply and reaction while excluded actions stay absent',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final journey = await readyJourney();
      final chat = ChatSession(
        sendGateway: ReviewChatSendGateway(latency: Duration.zero),
      );
      addTearDown(journey.dispose);
      addTearDown(chat.dispose);
      await mount(
        tester,
        route: '/app/chat/thread/home-basket?return=/app/social&stage=basket',
        journey: journey,
        chat: chat,
      );

      expect(
        find.byKey(const Key('chat-attachment-reference-m2')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('chat-open-attachment-m2')), findsNothing);
      expect(find.text('Attachment reference'), findsOneWidget);

      for (final key in const [
        Key('chat-like-m1'),
        Key('chat-camera'),
        Key('chat-thread-more'),
        Key('chat-mode-media'),
        Key('chat-mode-poll'),
        Key('chat-mode-invite'),
        Key('chat-mode-basket'),
      ]) {
        expect(find.byKey(key), findsNothing, reason: '$key');
      }
      expect(find.byKey(const Key('chat-attach')), findsOneWidget);
      expect(find.byKey(const Key('chat-composer-camera')), findsOneWidget);
      expect(find.byKey(const Key('chat-thread-call')), findsOneWidget);
      expect(find.byKey(const Key('chat-thread-video')), findsOneWidget);
      expect(find.byKey(const Key('chat-voice-message')), findsOneWidget);

      await tester.longPress(find.byKey(const Key('chat-message-m1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-message-actions')), findsOneWidget);
      await tapVisible(tester, const Key('chat-react-m1'));
      expect(chat.messages('home-basket').first.reactionCount, 3);
      expect(chat.messages('home-basket').first.reactedByMe, isTrue);
      await tester.longPress(find.byKey(const Key('chat-message-m1')));
      await tester.pumpAndSettle();
      await tapVisible(tester, const Key('chat-react-m1'));
      expect(chat.messages('home-basket').first.reactionCount, 2);
      expect(chat.messages('home-basket').first.reactedByMe, isFalse);

      await tester.longPress(find.byKey(const Key('chat-message-m1')));
      await tester.pumpAndSettle();
      await tapVisible(tester, const Key('chat-reply-m1'));
      expect(
        find.byKey(const Key('chat-composer-reply-context')),
        findsOneWidget,
      );
      expect(find.text('Replying to Amit'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('chat-message-field')),
        'Please add rice to the household list.',
      );
      await tapVisible(tester, const Key('chat-send'));
      expect(find.text('Message delivered.'), findsNothing);
      expect(
        chat.messages('home-basket').last.text,
        'Please add rice to the household list.',
      );
      expect(
        chat.messages('home-basket').last.deliveryState,
        ChatDeliveryState.delivered,
      );
      expect(
        find.byKey(
          Key('chat-delivery-status-${chat.messages('home-basket').last.id}'),
        ),
        findsOneWidget,
      );
      expect(find.text('Delivered · unread'), findsWidgets);
      expect(chat.messages('home-basket').last.replyTo?.messageId, 'm1');
      expect(
        find.byKey(const Key('chat-composer-reply-context')),
        findsNothing,
      );

      await tapVisible(tester, const Key('chat-voice-message'));
      expect(
        find.byKey(const Key('chat-voice-message-recovery')),
        findsOneWidget,
      );
      await tapVisible(tester, const Key('chat-capability-continue'));
      expect(find.byKey(const Key('mool-compact-launcher')), findsNothing);
      expect(find.byKey(const Key('chat-global-chat-edge')), findsNothing);
      expect(find.byKey(const Key('chat-thread-screen')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed message exact replay delivers once after retry', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final journey = await readyJourney();
    final chat = ChatSession(
      sendGateway: ReviewChatSendGateway(
        failNextRequest: true,
        latency: Duration.zero,
      ),
    );
    addTearDown(journey.dispose);
    addTearDown(chat.dispose);
    await mount(
      tester,
      route: '/app/chat/thread/order-support?return=/app/buy/grocery',
      journey: journey,
      chat: chat,
    );

    await tester.enterText(
      find.byKey(const Key('chat-message-field')),
      'The tomato was missing.',
    );
    await tapVisible(tester, const Key('chat-send'));
    expect(
      find.text('Message was not sent. Check your connection and retry.'),
      findsOneWidget,
    );
    expect(
      chat.messages('order-support').last.deliveryState,
      ChatDeliveryState.failed,
    );

    await tapVisible(tester, const Key('chat-retry-m11'));
    final replayed = chat
        .messages('order-support')
        .where((message) => message.text == 'The tomato was missing.')
        .toList();
    expect(replayed, hasLength(1), reason: 'Retry must not duplicate messages');
    expect(replayed.single.deliveryState, ChatDeliveryState.delivered);
    expect(find.text('Message delivered.'), findsNothing);
    expect(
      find.byKey(Key('chat-delivery-status-${replayed.single.id}')),
      findsOneWidget,
    );
    expect(find.text('Delivered · unread'), findsWidgets);

    expect(find.byKey(const Key('chat-mode-details')), findsNothing);
    expect(find.byKey(const Key('chat-mode-updates')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('business and support conversations keep truthful identities', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final journey = await readyJourney();
    final chat = ChatSession(
      sendGateway: ReviewChatSendGateway(latency: Duration.zero),
    );
    addTearDown(journey.dispose);
    addTearDown(chat.dispose);
    await mount(
      tester,
      route: '/app/chat/thread/mahadev?return=/app/buy/grocery',
      journey: journey,
      chat: chat,
    );

    expect(find.byKey(const Key('chat-thread-screen')), findsOneWidget);
    expect(find.text('Mahadev Fresh Mart'), findsWidgets);
    expect(find.byKey(const Key('chat-mode-orders')), findsNothing);
    expect(find.byKey(const Key('chat-mode-quote')), findsNothing);
    expect(find.byKey(const Key('chat-mode-pay')), findsNothing);

    await tapVisible(tester, const Key('chat-back'));
    expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);

    await mount(
      tester,
      route: '/app/chat/thread/order-support?return=/app/social',
      journey: journey,
      chat: chat,
    );
    expect(find.text('Order Support'), findsWidgets);
    expect(find.text('Case MS-CASE-204'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact phone keeps chat controls tappable without overflow', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = 1.25;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final journey = await readyJourney();
    final chat = ChatSession(
      sendGateway: ReviewChatSendGateway(latency: Duration.zero),
    );
    addTearDown(journey.dispose);
    addTearDown(chat.dispose);
    await mount(
      tester,
      route: '/app/chat/thread/home-basket?return=/app/social',
      journey: journey,
      chat: chat,
      size: const Size(360, 800),
    );

    for (final key in const [Key('chat-back'), Key('chat-voice-message')]) {
      final size = tester.getSize(find.byKey(key));
      expect(size.width, greaterThanOrEqualTo(44), reason: '$key width');
      expect(size.height, greaterThanOrEqualTo(44), reason: '$key height');
    }
    expect(find.byKey(const Key('mool-compact-launcher')), findsNothing);
    expect(find.byKey(const Key('chat-global-chat-edge')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('OPPO bottom inset keeps the composer above system navigation', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    tester.view.viewPadding = const FakeViewPadding(top: 41, bottom: 44);
    addTearDown(tester.view.reset);
    final journey = await readyJourney();
    final chat = ChatSession(
      sendGateway: ReviewChatSendGateway(latency: Duration.zero),
    );
    addTearDown(journey.dispose);
    addTearDown(chat.dispose);
    await tester.pumpWidget(
      MoolSocialApp(
        session: journey,
        chatSession: chat,
        initialLocation: '/app/chat/thread/home-basket?return=/app/social',
      ),
    );
    await tester.pumpAndSettle();
    debugDefaultTargetPlatformOverride = null;

    final field = find.byKey(const Key('chat-message-field'));
    final media = MediaQuery.of(tester.element(field));
    expect(media.viewPadding.bottom, greaterThan(0));
    final safeBottom = media.size.height - media.viewPadding.bottom;
    final exportedClearance = media.viewPadding.top - (58 - 44);
    final exportedSafeBottom = safeBottom - exportedClearance;
    for (final key in const [
      Key('chat-attach'),
      Key('chat-composer-camera'),
      Key('chat-voice-message'),
    ]) {
      final rect = tester.getRect(find.byKey(key));
      expect(rect.width, greaterThanOrEqualTo(44), reason: '$key width');
      expect(rect.height, greaterThanOrEqualTo(44), reason: '$key height');
      expect(rect.bottom, lessThanOrEqualTo(exportedSafeBottom));
    }
    expect(tester.getBottomRight(field).dy, lessThanOrEqualTo(safeBottom));
    expect(tester.takeException(), isNull);
  });
}

class _PeopleSocialGateway
    implements SocialContentGateway, SocialAuthorGateway {
  final Map<String, bool> followed = {'person-a': false, 'person-b': false};
  final List<(String, String)> interactions = [];

  @override
  Future<SocialFeedPage> feed({String? cursor, int limit = 20}) async {
    return SocialFeedPage(
      items: [
        _post('post-a', 'person-a', 'Alice News', '@alice'),
        _post('post-b', 'person-b', 'Bharat Creator', '@bharat'),
      ],
    );
  }

  @override
  Future<SocialAuthorProfile> author({
    required String authorId,
    bool authenticated = false,
    int limit = 12,
  }) async => _profile(authorId);

  @override
  Future<SocialAuthorProfile> follow({
    required String authorId,
    required bool followed,
  }) async {
    this.followed[authorId] = followed;
    return _profile(authorId);
  }

  SocialAuthorProfile _profile(String authorId) {
    final alice = authorId == 'person-a';
    return SocialAuthorProfile(
      authorId: authorId,
      authorName: alice ? 'Alice News' : 'Bharat Creator',
      authorHandle: alice ? '@alice' : '@bharat',
      followerCount: alice ? 42 : 75,
      followed: followed[authorId] ?? false,
      isSelf: false,
      posts: [
        _post(
          alice ? 'post-a' : 'post-b',
          authorId,
          alice ? 'Alice News' : 'Bharat Creator',
          alice ? '@alice' : '@bharat',
        ),
      ],
    );
  }

  @override
  Future<SocialPublishedItem> interact({
    required String postId,
    required String interaction,
    int? choiceIndex,
  }) async {
    interactions.add((postId, interaction));
    final isAlice = postId == 'post-a';
    return _post(
      postId,
      isAlice ? 'person-a' : 'person-b',
      isAlice ? 'Alice News' : 'Bharat Creator',
      isAlice ? '@alice' : '@bharat',
    ).copyWith(
      liked: interaction == 'like',
      likeCount: interaction == 'like' ? 1 : 0,
    );
  }

  @override
  Future<SocialPublishedItem> publish(SocialPublishDraft draft) =>
      Future.error(UnsupportedError('Not used by this test.'));
}

class _RetryPeopleSocialGateway extends _PeopleSocialGateway {
  int feedCalls = 0;

  @override
  Future<SocialFeedPage> feed({String? cursor, int limit = 20}) async {
    feedCalls += 1;
    if (feedCalls == 1) {
      throw StateError('temporary people directory failure');
    }
    return super.feed(cursor: cursor, limit: limit);
  }
}

SocialPublishedItem _post(
  String id,
  String authorId,
  String authorName,
  String authorHandle,
) => SocialPublishedItem(
  id: id,
  authorId: authorId,
  type: SocialPublishedContentType.post,
  authorName: authorName,
  authorHandle: authorHandle,
  body: 'Public discovery post',
  audience: 'Public',
  publishedAt: DateTime.utc(2026, 8, 24),
);

class _PeopleChatGateway implements ChatGateway {
  final List<String> createdTargets = [];

  @override
  Future<List<ChatThread>> listThreads({int limit = 30}) async => const [];

  @override
  Future<ChatThread> createDirectThread({required String targetUserId}) async {
    createdTargets.add(targetUserId);
    return ChatThread(
      id: 'direct-$targetUserId',
      title: targetUserId == 'person-a' ? 'Alice News' : 'Bharat Creator',
      subtitle: 'MoolSocial person',
      preview: 'No messages yet',
      timeLabel: 'Now',
      type: ChatThreadType.people,
    );
  }

  @override
  Future<List<ChatMessage>> listMessages({
    required String threadId,
    int limit = 50,
  }) async => const [];

  @override
  Future<void> markThreadRead({required String threadId}) async {}

  @override
  Future<ChatMessage> forwardMessage({
    required String sourceThreadId,
    required String sourceMessageId,
    required String targetThreadId,
    required String idempotencyKey,
  }) => Future.error(UnsupportedError('Not used by this test.'));

  @override
  Future<ChatMessage> sendMessage({
    required String threadId,
    required String text,
    required String idempotencyKey,
    String? replyToMessageId,
  }) => Future.error(UnsupportedError('Not used by this test.'));

  @override
  Future<ChatMessage> setReaction({
    required String threadId,
    required String messageId,
    required bool reacted,
  }) => Future.error(UnsupportedError('Not used by this test.'));
}
