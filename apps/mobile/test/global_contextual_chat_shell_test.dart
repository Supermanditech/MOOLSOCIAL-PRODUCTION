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
    const cases = <(String, ChatEntryContextId, String, ChatThreadType?)>[
      ('/app/mool', ChatEntryContextId.mool, 'Chat', null),
      (
        '/app/social?sub=feed',
        ChatEntryContextId.social,
        'Social Chat',
        ChatThreadType.people,
      ),
      (
        '/app/buy?sub=shop',
        ChatEntryContextId.shop,
        'Shop Chat',
        ChatThreadType.order,
      ),
      (
        '/app/eat/home',
        ChatEntryContextId.food,
        'Food Chat',
        ChatThreadType.order,
      ),
      (
        '/app/ride/book?type=cab',
        ChatEntryContextId.travel,
        'Travel Chat',
        ChatThreadType.support,
      ),
      (
        '/app/book/doctor',
        ChatEntryContextId.care,
        'Care Chat',
        ChatThreadType.business,
      ),
      (
        '/app/work/earn',
        ChatEntryContextId.work,
        'Work Chat',
        ChatThreadType.business,
      ),
      (
        '/app/work/my-work',
        ChatEntryContextId.workspace,
        'Workspace Chat',
        ChatThreadType.support,
      ),
      (
        '/app/retailer/orders',
        ChatEntryContextId.workspace,
        'Workspace Chat',
        ChatThreadType.support,
      ),
      (
        '/app/pay/home',
        ChatEntryContextId.pay,
        'Pay Chat',
        ChatThreadType.support,
      ),
    ];

    for (final entry in cases) {
      final resolved = ChatEntryContext.resolve(entry.$1);
      expect(resolved.id, entry.$2, reason: entry.$1);
      expect(resolved.title, entry.$3, reason: entry.$1);
      expect(resolved.defaultFilter, entry.$4, reason: entry.$1);
    }
    expect(
      ChatEntryContext.resolve('/app/ride/book?type=cab').allowedThreadIds,
      {'ride-support'},
    );
    expect(ChatEntryContext.resolve('/app/book/doctor').allowedThreadIds, {
      'clinic-care',
    });
    expect(ChatEntryContext.resolve('/app/work/my-work').allowedThreadIds, {
      'workspace-support',
    });
  });

  for (final entry in const <(String, String, String, ChatThreadType?)>[
    ('/app/mool', 'Chat', 'All your conversations', null),
    (
      '/app/social?sub=feed',
      'Social Chat',
      'People and creators',
      ChatThreadType.people,
    ),
    (
      '/app/buy?sub=shop',
      'Shop Chat',
      'Orders and products',
      ChatThreadType.order,
    ),
    ('/app/eat/home', 'Food Chat', 'Orders and tables', ChatThreadType.order),
    (
      '/app/ride/book?type=cab',
      'Travel Chat',
      'Trips and bookings',
      ChatThreadType.support,
    ),
    (
      '/app/book/doctor',
      'Care Chat',
      'Appointments and care',
      ChatThreadType.business,
    ),
    ('/app/work/earn', 'Work Chat', 'Opportunities', ChatThreadType.business),
    (
      '/app/work/my-work',
      'Workspace Chat',
      'Setup and review support',
      ChatThreadType.support,
    ),
  ]) {
    testWidgets('${entry.$2} is compact, contextual and filter-correct', (
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
      if (entry.$4 != null && entry.$1 != '/app/social?sub=feed') {
        final activeFilter = find.byKey(
          Key('chat-filter-${entry.$4!.label.toLowerCase()}'),
        );
        expect(activeFilter, findsOneWidget);
        final filterRect = tester.getRect(activeFilter);
        expect(filterRect.left, greaterThanOrEqualTo(0));
        expect(filterRect.right, lessThanOrEqualTo(320));
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
          findsNothing,
        );
        expect(
          find.byKey(const Key('chat-open-thread-ride-support')),
          findsNothing,
        );
      }
      if (entry.$2 == 'Workspace Chat') {
        expect(
          find.byKey(const Key('chat-open-thread-workspace-support')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('chat-open-thread-order-support')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('chat-open-thread-ride-support')),
          findsNothing,
        );
      }
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('chat-inbox-back')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-inbox-screen')), findsNothing);
      expect(tester.takeException(), isNull);
    });
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
    expect(find.byKey(const Key('chat-camera')), findsOneWidget);
    await tester.tap(find.byKey(const Key('chat-document')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-attachment-notice')), findsOneWidget);
    expect(find.textContaining('Document sharing'), findsOneWidget);

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
    'conversation info owns local availability and truthful account recovery',
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

      await tester.tap(find.byKey(const Key('chat-info-voice-availability')));
      await tester.pump();
      expect(chat.voiceCallsAvailableForSession('home-basket'), isFalse);
      expect(find.byKey(const Key('chat-info-local-status')), findsOneWidget);
      await tester.tap(find.byKey(const Key('chat-info-video-availability')));
      await tester.pump();
      expect(chat.videoCallsAvailableForSession('home-basket'), isFalse);

      final lastSeen = find.byKey(const Key('chat-info-last-seen'));
      await tester.ensureVisible(lastSeen);
      await tester.tap(lastSeen);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-last-seen-recovery')), findsOneWidget);
      expect(find.text('Last seen setting unchanged'), findsOneWidget);
      await tester.tap(find.byKey(const Key('chat-capability-continue')));
      await tester.pumpAndSettle();

      final readReceipts = find.byKey(const Key('chat-info-read-receipts'));
      await tester.ensureVisible(readReceipts);
      await tester.tap(readReceipts);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('chat-read-receipts-recovery')),
        findsOneWidget,
      );
      expect(tester.widget<SwitchListTile>(readReceipts).value, isTrue);
      await tester.tap(find.byKey(const Key('chat-capability-continue')));
      await tester.pumpAndSettle();

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
    final lastSeen = find.byKey(const Key('chat-info-last-seen'));
    await tester.ensureVisible(lastSeen);
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
    final camera = find.byKey(const Key('chat-camera'));
    expect(camera, findsOneWidget);
    final rect = tester.getRect(camera);
    expect(rect.height, greaterThanOrEqualTo(44));
    expect(rect.bottom, lessThanOrEqualTo(756));
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
