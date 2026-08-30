import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/chat/chat_entry_context.dart';
import 'package:moolsocial/features/chat/chat_models.dart';
import 'package:moolsocial/features/chat/chat_services.dart';
import 'package:moolsocial/features/chat/chat_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/ui_v2/universal/mool_global_navigation_v2.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  test('one resolver classifies every shared Chat origin', () {
    const cases = <(String, ChatEntryContextId, String)>[
      ('/app/mool', ChatEntryContextId.mool, 'Chat'),
      ('/app/social?sub=feed', ChatEntryContextId.social, 'Social Chat'),
      ('/app/buy?sub=shop', ChatEntryContextId.shop, 'Shop Chat'),
      ('/app/buy?sub=medicine', ChatEntryContextId.care, 'Care Chat'),
      ('/app/eat/home', ChatEntryContextId.food, 'Food Chat'),
      ('/app/ride/book?type=cab', ChatEntryContextId.travel, 'Travel Chat'),
      ('/app/book/doctor', ChatEntryContextId.care, 'Care Chat'),
      ('/app/work/earn', ChatEntryContextId.work, 'Work Chat'),
      ('/app/work/my-work', ChatEntryContextId.workspace, 'Workspace Chat'),
      ('/app/retailer/orders', ChatEntryContextId.workspace, 'Workspace Chat'),
      (
        '/app/manufacturer/orders/review',
        ChatEntryContextId.workspace,
        'Workspace Chat',
      ),
      (
        '/app/captain/trips/ride-1',
        ChatEntryContextId.workspace,
        'Workspace Chat',
      ),
      ('/app/creator/audience', ChatEntryContextId.workspace, 'Workspace Chat'),
      ('/app/operations/home', ChatEntryContextId.workspace, 'Workspace Chat'),
      ('/app/pay/home', ChatEntryContextId.pay, 'Pay Chat'),
    ];

    for (final entry in cases) {
      final resolved = ChatEntryContext.resolve(entry.$1);
      expect(resolved.id, entry.$2, reason: entry.$1);
      expect(resolved.title, entry.$3, reason: entry.$1);
    }
    expect(
      ChatEntryContext.resolve('/app/ride/book?type=cab').allowedThreadIds,
      {'ride-support', 'ride-captain'},
    );
    expect(ChatEntryContext.resolve('/app/buy?sub=shop').allowedThreadIds, {
      'shop-assist',
      'shop-order',
      'shop-partner',
      'shop-offers',
    });
    expect(ChatEntryContext.resolve('/app/book/doctor').allowedThreadIds, {
      'clinic-care',
      'task-helper',
      'order-support',
    });
    expect(ChatEntryContext.resolve('/app/eat/home').allowedThreadIds, {
      'rasoi',
      'order-support',
    });
    expect(ChatEntryContext.resolve('/app/work/earn').allowedThreadIds, {
      'work-opportunity',
      'work-support',
    });
    expect(ChatEntryContext.resolve('/app/pay/home').allowedThreadIds, {
      'pay-support',
    });
    expect(ChatEntryContext.resolve('/app/work/my-work').allowedThreadIds, {
      'workspace-support',
    });
    expect(
      ChatEntryContext.resolve('/app/ride/trip/ride-1').allowsThread('ride-1'),
      isTrue,
    );
    expect(
      ChatEntryContext.resolve(
        '/app/book/task/task-1',
      ).allowsThread('task-helper'),
      isTrue,
    );
    expect(
      ChatEntryContext.resolve(
        '/app/retailer/orders',
      ).allowsThread('order-support'),
      isTrue,
    );
    expect(
      ChatEntryContext.resolve('/app/retailer/orders').allowsThread('mahadev'),
      isTrue,
    );
    expect(
      ChatEntryContext.resolve(
        '/app/captain/trips/ride-1',
      ).allowsThread('ride-support'),
      isTrue,
    );
  });

  for (final entry
      in const <
        ({
          String origin,
          String title,
          String threadId,
          List<String> excludedThreadIds,
          String returnKey,
        })
      >[
        (
          origin: '/app/eat/home',
          title: 'Food Chat',
          threadId: 'rasoi',
          excludedThreadIds: ['shop-order'],
          returnKey: 'eat-home-screen',
        ),
        (
          origin: '/app/work/home',
          title: 'Work Chat',
          threadId: 'work-opportunity',
          excludedThreadIds: ['mahadev', 'shop-partner', 'clinic-care'],
          returnKey: 'work-main-v2',
        ),
        (
          origin: '/app/pay/home',
          title: 'Pay Chat',
          threadId: 'pay-support',
          excludedThreadIds: ['order-support', 'workspace-support'],
          returnKey: 'legacy-route-containment-standalone-pay',
        ),
      ]) {
    testWidgets('${entry.title} exposes only its owned default conversation', (
      tester,
    ) async {
      final journey = await readyJourney();
      final chat = ChatSession();
      addTearDown(journey.dispose);
      addTearDown(chat.dispose);
      final route = Uri(
        path: '/app/chat/inbox',
        queryParameters: {'return': entry.origin},
      ).toString();

      await tester.pumpWidget(
        MoolSocialApp(
          session: journey,
          chatSession: chat,
          initialLocation: route,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(entry.title), findsOneWidget);
      expect(
        find.byKey(ValueKey('chat-open-thread-${entry.threadId}')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('chat-open-thread-shop-assist')),
        findsOneWidget,
      );
      for (final threadId in entry.excludedThreadIds) {
        expect(
          find.byKey(ValueKey('chat-open-thread-$threadId')),
          findsNothing,
          reason: '${entry.origin} must not expose $threadId',
        );
      }

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(Key(entry.returnKey)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Work support intent stays inside Work support', (tester) async {
    final journey = await readyJourney();
    final chat = ChatSession();
    addTearDown(journey.dispose);
    addTearDown(chat.dispose);

    await tester.pumpWidget(
      MoolSocialApp(
        session: journey,
        chatSession: chat,
        initialLocation: '/app/chat?sub=support&return=/app/work%2Fearn',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Work Chat'), findsOneWidget);
    expect(chat.selectedFilter, ChatThreadType.support);
    expect(
      find.byKey(const Key('chat-open-thread-work-support')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('chat-open-thread-workspace-support')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('chat-open-thread-order-support')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Retailer business intent opens the real supplier thread', (
    tester,
  ) async {
    final journey = await readyJourney();
    final chat = ChatSession();
    addTearDown(journey.dispose);
    addTearDown(chat.dispose);

    await tester.pumpWidget(
      MoolSocialApp(
        session: journey,
        chatSession: chat,
        initialLocation: '/app/chat?sub=business&return=/app/retailer%2Forders',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Workspace Chat'), findsOneWidget);
    expect(chat.selectedFilter, ChatThreadType.business);
    expect(find.byKey(const Key('chat-open-thread-mahadev')), findsOneWidget);
    expect(
      find.byKey(const Key('chat-open-thread-shop-partner')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  for (final entry in const <(String, String, String, ChatThreadType?)>[
    ('/app/mool', 'Chat', 'All your conversations', null),
    ('/app/social?sub=feed', 'Social Chat', 'People and creators', null),
    ('/app/buy?sub=shop', 'Shop Chat', 'Orders and products', null),
    ('/app/buy?sub=wholesale', 'Shop Chat', 'Orders and products', null),
    ('/app/buy?sub=orders', 'Shop Chat', 'Orders and products', null),
    ('/app/buy?sub=medicine', 'Care Chat', 'Appointments and care', null),
    ('/app/eat/home', 'Food Chat', 'Orders and tables', null),
    ('/app/ride/book?type=cab', 'Travel Chat', 'Trips and bookings', null),
    ('/app/book/doctor', 'Care Chat', 'Appointments and care', null),
    ('/app/work/earn', 'Work Chat', 'Opportunities', null),
    ('/app/work/my-work', 'Workspace Chat', 'Setup and review support', null),
    (
      '/app/retailer/orders',
      'Workspace Chat',
      'Setup and review support',
      null,
    ),
    (
      '/app/manufacturer/orders/review',
      'Workspace Chat',
      'Setup and review support',
      null,
    ),
    (
      '/app/captain/trips/ride-1',
      'Workspace Chat',
      'Setup and review support',
      null,
    ),
    (
      '/app/creator/audience',
      'Workspace Chat',
      'Setup and review support',
      null,
    ),
    (
      '/app/operations/home',
      'Workspace Chat',
      'Setup and review support',
      null,
    ),
    ('/app/pay/home', 'Pay Chat', 'Payments and support', null),
  ]) {
    testWidgets('${entry.$2} from ${entry.$1} is compact and defaults to All', (
      tester,
    ) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.binding.setSurfaceSize(const Size(320, 568));
      final journey = await readyJourney();
      final chat = ChatSession(
        sendGateway: ReviewChatSendGateway(latency: Duration.zero),
      );
      chat.chooseFilter(ChatThreadType.support);
      addTearDown(journey.dispose);
      addTearDown(chat.dispose);
      final route = Uri(
        path: '/app/chat/inbox',
        queryParameters: {'return': entry.$1},
      ).toString();

      await tester.pumpWidget(
        MoolSocialApp(
          session: journey,
          chatSession: chat,
          initialLocation: route,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);
      expect(find.byKey(const Key('chat-inbox-back')), findsOneWidget);
      expect(find.byKey(const Key('chat-context-icon')), findsNothing);
      expect(find.text(entry.$2), findsOneWidget);
      expect(find.text('MoolSocial messaging'), findsOneWidget);
      expect(find.text('MoolSocial Chat'), findsNothing);
      expect(chat.selectedFilter, entry.$4);
      final backSize = tester.getSize(find.byKey(const Key('chat-inbox-back')));
      expect(backSize.width, greaterThanOrEqualTo(44));
      expect(backSize.height, greaterThanOrEqualTo(44));
      final navigation = tester.widget<NavigationBar>(
        find.byKey(const Key('chat-native-navigation')),
      );
      expect(navigation.height, 72);
      expect(find.byKey(const Key('chat-moolsocial-divider')), findsOneWidget);
      final title = tester.renderObject<RenderParagraph>(find.text(entry.$2));
      final subtitle = tester.renderObject<RenderParagraph>(
        find.text('MoolSocial messaging'),
      );
      expect(title.didExceedMaxLines, isFalse);
      expect(subtitle.didExceedMaxLines, isFalse);
      if (find.byKey(const Key('chat-filter-all')).evaluate().isNotEmpty) {
        final allFilter = find.byKey(const Key('chat-filter-all'));
        expect(tester.widget<ChoiceChip>(allFilter).selected, isTrue);
        final filterRect = tester.getRect(allFilter);
        expect(filterRect.left, greaterThanOrEqualTo(0));
        expect(filterRect.right, lessThanOrEqualTo(320));
      }
      if (entry.$2 == 'Shop Chat') {
        expect(
          find.byKey(const Key('chat-open-thread-shop-order')),
          findsOneWidget,
        );
        expect(find.text('Fresh Basket Order'), findsOneWidget);
        expect(find.byKey(const Key('chat-open-thread-rasoi')), findsNothing);
      }
      if (entry.$2 == 'Travel Chat') {
        expect(
          find.byKey(const Key('chat-open-thread-ride-support')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('chat-open-thread-order-support')),
          findsNothing,
        );
      }
      if (entry.$2 == 'Care Chat') {
        expect(
          find.byKey(const Key('chat-open-thread-clinic-care')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('chat-open-thread-order-support')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('chat-open-thread-ride-support')),
          findsNothing,
        );
      }
      if (entry.$2 == 'Workspace Chat') {
        final workspaceSupport = find.byKey(
          const Key('chat-open-thread-workspace-support'),
        );
        await tester.scrollUntilVisible(
          workspaceSupport,
          140,
          scrollable: find
              .descendant(
                of: find.byKey(const PageStorageKey('chat-inbox-scroll')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(workspaceSupport, findsOneWidget);
      }
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('chat-inbox-back')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-inbox-screen')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  for (final destination in const <(String, String, String, ChatThreadType)>[
    ('/app/pay/home', 'pay-support', 'Pay Chat', ChatThreadType.support),
    (
      '/app/retailer/orders/issues',
      'order-support',
      'Workspace Chat',
      ChatThreadType.support,
    ),
    (
      '/app/manufacturer/orders/review',
      'order-support',
      'Workspace Chat',
      ChatThreadType.support,
    ),
    (
      '/app/captain/trips/ride-1',
      'ride-support',
      'Workspace Chat',
      ChatThreadType.support,
    ),
    (
      '/app/creator/audience',
      'workspace-support',
      'Workspace Chat',
      ChatThreadType.support,
    ),
    (
      '/app/operations/home',
      'order-support',
      'Workspace Chat',
      ChatThreadType.support,
    ),
    (
      '/app/book/task/task-1',
      'task-helper',
      'Care Chat',
      ChatThreadType.business,
    ),
    (
      '/app/book/task/task-1/support',
      'order-support',
      'Care Chat',
      ChatThreadType.support,
    ),
    (
      '/app/ride/trip/ride-1/support',
      'ride-support',
      'Travel Chat',
      ChatThreadType.support,
    ),
  ]) {
    testWidgets(
      '${destination.$3} ${destination.$1} deep thread returns to its visible contextual inbox',
      (tester) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.binding.setSurfaceSize(const Size(360, 800));
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
            initialLocation: Uri(
              path: '/app/chat/thread/${destination.$2}',
              queryParameters: {'return': destination.$1},
            ).toString(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('chat-thread-screen')), findsOneWidget);
        await tester.tap(find.byKey(const Key('chat-back')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);
        expect(find.text(destination.$3), findsOneWidget);
        expect(chat.selectedFilter, isNull);
        expect(
          find.byKey(Key('chat-open-thread-${destination.$2}')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('conversation keeps familiar MoolSocial header and composer', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(360, 800));
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
        initialLocation: '/app/chat/thread/home-basket?return=/app/work/earn',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-thread-screen')), findsOneWidget);
    expect(find.byKey(const Key('chat-back')), findsOneWidget);
    expect(find.text('5 members'), findsOneWidget);
    expect(find.byKey(const Key('chat-composer-surface')), findsOneWidget);
    expect(find.byKey(const Key('chat-thread-video')), findsOneWidget);
    expect(find.byKey(const Key('chat-thread-call')), findsOneWidget);
    expect(find.byKey(const Key('chat-attach')), findsOneWidget);
    expect(find.byKey(const Key('chat-composer-camera')), findsOneWidget);
    expect(find.byKey(const Key('chat-voice-message')), findsOneWidget);

    await tester.tap(find.byKey(const Key('chat-thread-video')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-video-recovery')), findsOneWidget);
    await tester.tap(find.byKey(const Key('chat-capability-continue')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('chat-thread-call')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-call-recovery')), findsOneWidget);
    await tester.tap(find.byKey(const Key('chat-capability-continue')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('chat-attach')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-attachment-tray')), findsOneWidget);
    expect(find.byKey(const Key('chat-document')), findsOneWidget);
    expect(find.byKey(const Key('chat-gallery')), findsOneWidget);
    expect(find.byKey(const Key('chat-camera')), findsNothing);
    expect(find.byKey(const Key('chat-composer-camera')), findsOneWidget);
    expect(find.byKey(const Key('chat-video')), findsOneWidget);
    for (final key in const [
      Key('chat-document'),
      Key('chat-gallery'),
      Key('chat-video'),
    ]) {
      expect(tester.getSize(find.byKey(key)).width, greaterThanOrEqualTo(44));
      expect(tester.getSize(find.byKey(key)).height, greaterThanOrEqualTo(44));
    }
    expect(
      tester.widget<InkWell>(find.byKey(const Key('chat-document'))).onTap,
      isNull,
    );
    expect(
      tester.widget<InkWell>(find.byKey(const Key('chat-gallery'))).onTap,
      isNull,
    );
    expect(
      tester.widget<InkWell>(find.byKey(const Key('chat-video'))).onTap,
      isNull,
    );
    expect(find.byKey(const Key('chat-attachment-notice')), findsOneWidget);
    expect(
      find.textContaining('Document, photo and video sharing are unavailable'),
      findsOneWidget,
    );
    expect(find.byTooltip('Camera'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-thread-screen')), findsOneWidget);
    expect(find.byKey(const Key('chat-attachment-tray')), findsNothing);
    expect(find.byKey(const Key('chat-attachment-notice')), findsNothing);
    expect(find.byKey(const Key('chat-composer-surface')), findsOneWidget);

    await tester.tap(find.byKey(const Key('chat-composer-camera')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-attachment-notice')), findsOneWidget);
    expect(find.textContaining('Photo sharing'), findsOneWidget);
    await tester.tap(find.byKey(const Key('chat-attach')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-attachment-tray')), findsNothing);

    await tester.tap(find.byKey(const Key('chat-voice-message')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('chat-voice-message-recovery')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('chat-capability-continue')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-message-actions')), findsNothing);
    await tester.longPress(find.byKey(const Key('chat-message-m1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-message-actions')), findsOneWidget);
    expect(find.byKey(const Key('chat-reply-m1')), findsOneWidget);
    expect(find.byKey(const Key('chat-react-m1')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'conversation info owns local availability and persisted privacy choices',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(360, 800));
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
          initialLocation: '/app/chat/thread/home-basket?return=/app/work/earn',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('chat-conversation-info')), findsOneWidget);
      await tester.tap(find.byKey(const Key('chat-conversation-info')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('chat-conversation-info-screen')),
        findsOneWidget,
      );
      expect(find.text('Conversation info'), findsOneWidget);
      expect(find.byKey(const Key('chat-conversation-status')), findsOneWidget);
      expect(find.text('Available in Chat'), findsOneWidget);
      expect(
        find.byKey(const Key('chat-info-chat-availability')),
        findsOneWidget,
      );

      final voiceAvailability = find.byKey(
        const Key('chat-info-voice-availability'),
      );
      await tester.ensureVisible(voiceAvailability);
      await tester.tap(voiceAvailability);
      await tester.pump();
      expect(chat.voiceCallsAvailableForSession('home-basket'), isFalse);
      expect(find.byKey(const Key('chat-info-local-feedback')), findsOneWidget);
      expect(
        find.text('Voice calls are paused until you close the app.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('chat-info-video-availability')));
      await tester.pump();
      expect(chat.videoCallsAvailableForSession('home-basket'), isFalse);

      final voiceChat = find.byKey(const Key('chat-info-voice-chat'));
      await tester.ensureVisible(voiceChat);
      await tester.tap(voiceChat);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-voice-chat-recovery')), findsOneWidget);
      expect(find.text('Voice chat unavailable'), findsOneWidget);
      await tester.tap(find.byKey(const Key('chat-capability-continue')));
      await tester.pumpAndSettle();

      final lastSeen = find.byKey(const Key('chat-info-last-seen'));
      await tester.ensureVisible(lastSeen);
      await tester.tap(lastSeen);
      await tester.pumpAndSettle();
      expect(chat.privacySettings.shareLastSeen, isFalse);
      expect(find.text('Last seen sharing turned off.'), findsWidgets);

      final readReceipts = find.byKey(const Key('chat-info-read-receipts'));
      await tester.ensureVisible(readReceipts);
      await tester.tap(readReceipts);
      await tester.pumpAndSettle();
      expect(chat.privacySettings.readReceipts, isFalse);
      expect(tester.widget<SwitchListTile>(readReceipts).value, isFalse);

      final blockUser = find.byKey(const Key('chat-info-block-user'));
      await tester.ensureVisible(blockUser);
      await tester.tap(blockUser);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-block-user-recovery')), findsOneWidget);
      expect(find.text('Blocking unavailable'), findsOneWidget);
      await tester.tap(find.byKey(const Key('chat-capability-continue')));
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-thread-screen')), findsOneWidget);
      expect(
        find.byKey(const Key('chat-conversation-info-screen')),
        findsNothing,
      );

      await tester.tap(find.byKey(const Key('chat-conversation-info')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chat-info-chat-availability')));
      await tester.pump();
      expect(chat.chatAvailableForSession('home-basket'), isFalse);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-paused-bar')), findsOneWidget);
      expect(find.byKey(const Key('chat-composer-surface')), findsNothing);

      await tester.tap(find.byKey(const Key('chat-thread-call')));
      await tester.pumpAndSettle();
      expect(find.text('Voice calls paused'), findsOneWidget);
      await tester.tap(find.byKey(const Key('chat-capability-continue')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('chat-resume')));
      await tester.pump();
      expect(chat.chatAvailableForSession('home-basket'), isTrue);
      expect(find.byKey(const Key('chat-composer-surface')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'send review is session-local, preserves the draft and requires confirmation',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(360, 800));
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
          initialLocation: '/app/chat/thread/home-basket?return=/app/work/earn',
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('chat-conversation-info')));
      await tester.pumpAndSettle();
      final reviewSetting = find.byKey(
        const Key('chat-info-review-before-send'),
      );
      await tester.scrollUntilVisible(
        reviewSetting,
        180,
        scrollable: find.descendant(
          of: find.byKey(const Key('chat-conversation-info-list')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(reviewSetting);
      await tester.pump();
      expect(chat.reviewBeforeSendingForSession('home-basket'), isTrue);
      expect(chat.reviewBeforeSendingForSession('rasoi'), isFalse);
      expect(
        find.text('Send review is on until you close the app.'),
        findsOneWidget,
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.longPress(find.byKey(const Key('chat-message-m1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chat-reply-m1')));
      await tester.pumpAndSettle();
      expect(chat.replyTarget('home-basket')?.id, 'm1');
      const draft = 'Please confirm the delivery time.';
      final messageField = find.byKey(const Key('chat-message-field'));
      await tester.enterText(messageField, draft);
      await tester.pump();
      await tester.tap(find.byKey(const Key('chat-send')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('chat-send-review-dialog')), findsOneWidget);
      expect(find.byKey(const Key('chat-send-review-content')), findsOneWidget);
      expect(find.text('To Home Basket Group'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('chat-send-review-dialog')),
          matching: find.text('Replying to Amit'),
        ),
        findsOneWidget,
      );
      expect(
        find.text('Nothing is sent until you choose Send now.'),
        findsOneWidget,
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-send-review-dialog')), findsNothing);
      expect(tester.widget<TextField>(messageField).controller!.text, draft);
      expect(chat.replyTarget('home-basket')?.id, 'm1');
      expect(
        chat.messages('home-basket').where((message) => message.text == draft),
        isEmpty,
      );

      await tester.tap(find.byKey(const Key('chat-send')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chat-send-review-confirm')));
      await tester.pumpAndSettle();
      expect(
        chat.messages('home-basket').where((message) => message.text == draft),
        hasLength(1),
      );
      expect(tester.widget<TextField>(messageField).controller!.text, isEmpty);
      expect(chat.replyTarget('home-basket'), isNull);
      expect(find.byKey(const Key('chat-send-review-dialog')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final safety in const <(String, String, String, String)>[
    (
      'task-helper',
      'Block this person',
      'chat-block-user-recovery',
      'Blocking unavailable',
    ),
    (
      'mahadev',
      'Block this business',
      'chat-block-business-recovery',
      'Business blocking unavailable',
    ),
    (
      'rasoi',
      'Conversation safety',
      'chat-conversation-safety-recovery',
      'Conversation safety unavailable',
    ),
    (
      'order-support',
      'Conversation safety',
      'chat-conversation-safety-recovery',
      'Conversation safety unavailable',
    ),
  ]) {
    testWidgets(
      '${safety.$1} uses context-correct Conversation Info safety wording',
      (tester) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.binding.setSurfaceSize(const Size(360, 800));
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
            initialLocation:
                '/app/chat/thread/${safety.$1}?return=/app/work/earn',
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('chat-conversation-info')));
        await tester.pumpAndSettle();
        final safetyAction = find.byKey(const Key('chat-info-block-user'));
        await tester.dragUntilVisible(
          safetyAction,
          find.byKey(const Key('chat-conversation-info-list')),
          const Offset(0, -180),
        );
        await tester.ensureVisible(safetyAction);
        await tester.pumpAndSettle();
        expect(find.text(safety.$2), findsOneWidget);
        await tester.tap(safetyAction);
        await tester.pumpAndSettle();

        expect(find.byKey(Key(safety.$3)), findsOneWidget);
        expect(find.text(safety.$4), findsOneWidget);
        await tester.tap(find.byKey(const Key('chat-capability-continue')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('chat-conversation-info-screen')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('conversation info remains reachable on compact large text', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 568));
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
        initialLocation: '/app/chat/thread/home-basket?return=/app/care/home',
      ),
    );
    await tester.pumpAndSettle();
    final conversationInfo = find.byKey(const Key('chat-conversation-info'));
    expect(tester.getSize(conversationInfo).height, greaterThanOrEqualTo(44));
    expect(
      tester.getBottomRight(find.byKey(const Key('chat-thread-video'))).dx,
      lessThanOrEqualTo(320),
    );
    expect(
      tester.getBottomRight(find.byKey(const Key('chat-thread-call'))).dx,
      lessThanOrEqualTo(320),
    );
    expect(tester.takeException(), isNull);
    await tester.tap(conversationInfo);
    await tester.pumpAndSettle();

    final blockUser = find.byKey(const Key('chat-info-block-user'));
    await tester.dragUntilVisible(
      blockUser,
      find.byKey(const Key('chat-conversation-info-list')),
      const Offset(0, -180),
    );
    expect(blockUser, findsOneWidget);
    expect(tester.getBottomRight(blockUser).dx, lessThanOrEqualTo(320));
    expect(tester.takeException(), isNull);
  });

  testWidgets('privacy recovery clears OPPO exported semantics clipping', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    tester.view.viewPadding = const FakeViewPadding(top: 41, bottom: 38);
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
        initialLocation: '/app/chat/thread/task-helper?return=/app/work/earn',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-conversation-info')));
    await tester.pumpAndSettle();
    final lastSeen = find.byKey(const Key('chat-info-block-user'));
    await tester.dragUntilVisible(
      lastSeen,
      find.byKey(const Key('chat-conversation-info-list')),
      const Offset(0, -180),
    );
    await tester.ensureVisible(lastSeen);
    await tester.pumpAndSettle();
    await tester.tap(lastSeen);
    await tester.pumpAndSettle();

    final continueButton = find.byKey(const Key('chat-capability-continue'));
    final clearance = moolAndroidExportedSemanticsClearance(
      viewPadding: const EdgeInsets.only(top: 41, bottom: 38),
      platform: TargetPlatform.android,
    );
    final exportedClipBottom = 800 - 38 - clearance;
    expect(tester.getSize(continueButton).height, greaterThanOrEqualTo(44));
    expect(
      tester.getBottomRight(continueButton).dy,
      lessThanOrEqualTo(exportedClipBottom),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('search assistance clears the OPPO bottom system inset', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    tester.view.viewPadding = const FakeViewPadding(bottom: 44);
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
        initialLocation: '/app/chat/inbox?return=/app/mool',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-search-assistance')));
    await tester.pumpAndSettle();

    final action = find.byKey(const Key('chat-use-search-assistance'));
    final safeBottom = 800 - tester.view.viewPadding.bottom;
    expect(tester.getSize(action).height, greaterThanOrEqualTo(44));
    expect(tester.getBottomRight(action).dy, lessThanOrEqualTo(safeBottom));
    expect(
      find.byKey(const Key('chat-search-assistance-field')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('attachment list stays above an OPPO bottom system inset', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    tester.view.viewPadding = const FakeViewPadding(bottom: 44);
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
        initialLocation: '/app/chat/thread/home-basket?return=/app/work/earn',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-attach')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-attachment-tray')), findsOneWidget);
    expect(find.byKey(const Key('chat-camera')), findsNothing);
    final video = find.byKey(const Key('chat-video'));
    expect(video, findsOneWidget);
    final rect = tester.getRect(video);
    expect(rect.height, greaterThanOrEqualTo(44));
    expect(rect.bottom, lessThanOrEqualTo(756));
    expect(find.byKey(const Key('chat-composer-camera')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'composer rises above the keyboard and restores after dismissal',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      tester.view.viewPadding = const FakeViewPadding(bottom: 44);
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
          initialLocation: '/app/chat/thread/home-basket?return=/app/work/earn',
        ),
      );
      await tester.pumpAndSettle();
      final composer = find.byKey(const Key('chat-composer-surface'));
      final field = find.byKey(const Key('chat-message-field'));
      await tester.tap(field);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();

      expect(tester.getBottomRight(composer).dy, lessThanOrEqualTo(500));
      expect(
        tester.getBottomRight(find.byKey(const Key('chat-voice-message'))).dy,
        lessThanOrEqualTo(500),
      );

      tester.view.viewInsets = const FakeViewPadding();
      await tester.pumpAndSettle();
      expect(tester.getBottomRight(composer).dy, greaterThan(500));
      expect(tester.getBottomRight(composer).dy, lessThanOrEqualTo(756));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Assist draft keeps full-width text above fixed controls and Back restores the composer',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      tester.view.viewPadding = const FakeViewPadding(bottom: 44);
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final journey = await readyJourney();
      final chat = ChatSession(
        sendGateway: ReviewChatSendGateway(latency: Duration.zero),
      );
      addTearDown(journey.dispose);
      addTearDown(chat.dispose);
      final route = Uri(
        path: '/app/chat/thread/shop-assist',
        queryParameters: {
          'return': '/app/buy?sub=orders',
          'draft': 'Help with order PO-240783',
        },
      ).toString();

      await tester.pumpWidget(
        MoolSocialApp(
          session: journey,
          chatSession: chat,
          initialLocation: route,
        ),
      );
      await tester.pumpAndSettle();
      final field = find.byKey(const Key('chat-message-field'));
      final controls = find.byKey(const Key('chat-composer-control-row'));
      expect(
        tester.widget<TextField>(field).controller?.text,
        'Help with order PO-240783',
      );
      final pageTitle = find.byKey(const Key('chat-page-title'));
      expect(tester.widget<Text>(pageTitle).data, 'MoolSocial Assist');
      expect(tester.widget<Text>(pageTitle).maxLines, 2);
      expect(tester.widget<Text>(pageTitle).overflow, TextOverflow.clip);
      expect(tester.getRect(pageTitle).right, lessThanOrEqualTo(360));
      await tester.drag(
        find.byKey(const Key('chat-suggested-prompt-list')),
        const Offset(-344, 0),
      );
      await tester.pumpAndSettle();
      final longPrompt = find.byKey(const Key('chat-suggested-prompt-label-1'));
      expect(tester.widget<Text>(longPrompt).data, 'Cancel or change order');
      expect(tester.widget<Text>(longPrompt).maxLines, 2);
      expect(tester.getRect(longPrompt).right, lessThanOrEqualTo(348));
      expect(tester.getRect(longPrompt).left, greaterThanOrEqualTo(12));
      final textField = tester.widget<TextField>(field);
      final padding = textField.decoration?.contentPadding as EdgeInsets?;
      expect(padding?.bottom, greaterThanOrEqualTo(44));
      expect(tester.getRect(controls).height, greaterThanOrEqualTo(44));
      expect(tester.getRect(field).width, greaterThan(220));

      await tester.tap(field);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      expect(
        tester
            .getBottomRight(find.byKey(const Key('chat-composer-surface')))
            .dy,
        lessThanOrEqualTo(500),
      );

      await tester.tap(find.byKey(const Key('chat-attach')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-attachment-tray')), findsOneWidget);
      tester.view.viewInsets = const FakeViewPadding();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-attachment-tray')), findsNothing);
      expect(find.byKey(const Key('chat-composer-surface')), findsOneWidget);
      expect(find.byKey(const Key('chat-message-field')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final entry in const <(String, ChatThreadType, String)>[
    ('business', ChatThreadType.business, 'shop-partner'),
    ('support', ChatThreadType.support, 'shop-offers'),
  ]) {
    testWidgets('Shop ${entry.$1} intent stays in Shop context', (
      tester,
    ) async {
      final journey = await readyJourney();
      final chat = ChatSession(
        sendGateway: ReviewChatSendGateway(latency: Duration.zero),
      );
      addTearDown(journey.dispose);
      addTearDown(chat.dispose);
      final route = Uri(
        path: '/app/chat/inbox',
        queryParameters: {
          'type': entry.$1,
          'return': '/app/buy?sub=${entry.$1}',
        },
      ).toString();

      await tester.pumpWidget(
        MoolSocialApp(
          session: journey,
          chatSession: chat,
          initialLocation: route,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Shop Chat'), findsOneWidget);
      expect(chat.selectedFilter, entry.$2);
      expect(find.byKey(Key('chat-open-thread-${entry.$3}')), findsOneWidget);
      expect(find.byKey(const Key('chat-open-thread-rasoi')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('an explicit Chat intent overrides the origin default filter', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
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
        initialLocation:
            '/app/chat?sub=support&return=/app/social%3Fsub%3Dfeed',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Social Chat'), findsOneWidget);
    expect(chat.selectedFilter, ChatThreadType.support);
    expect(
      find.byKey(const Key('chat-open-thread-order-support')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
