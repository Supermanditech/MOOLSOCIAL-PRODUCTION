import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/chat/chat_models.dart';
import 'package:moolsocial/features/chat/chat_services.dart';
import 'package:moolsocial/features/chat/chat_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

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

  Future<void> mountInbox(
    WidgetTester tester, {
    required JourneySession journey,
    required ChatSession chat,
    required String origin,
    Size size = const Size(412, 915),
  }) async {
    await tester.binding.setSurfaceSize(size);
    await tester.pumpWidget(
      MoolSocialApp(
        key: ValueKey(origin),
        session: journey,
        chatSession: chat,
        initialLocation: Uri(
          path: '/app/chat/inbox',
          queryParameters: {'return': origin},
        ).toString(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('chat-more')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-more-settings')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-settings-screen')), findsOneWidget);
  }

  Future<void> revealSetting(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    await tester.scrollUntilVisible(
      finder,
      180,
      scrollable: find.descendant(
        of: find.byKey(const Key('chat-settings-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  test('global gates preserve conversation choices when they resume', () {
    final chat = ChatSession();
    addTearDown(chat.dispose);

    chat.setChatAvailableForSession('home-basket', available: false);
    chat.setVoiceCallsAvailableForSession('home-basket', available: false);
    chat.setVideoCallsAvailableForSession('home-basket', available: false);
    chat.setReviewBeforeSendingForSession('home-basket', enabled: true);

    chat.setGlobalChatAvailableForSession(available: false);
    chat.setGlobalVoiceCallsAvailableForSession(available: false);
    chat.setGlobalVideoCallsAvailableForSession(available: false);
    chat.setGlobalReviewBeforeSendingForSession(enabled: true);

    expect(chat.chatAvailableForSession('rasoi'), isFalse);
    expect(chat.voiceCallsAvailableForSession('rasoi'), isFalse);
    expect(chat.videoCallsAvailableForSession('rasoi'), isFalse);
    expect(chat.reviewBeforeSendingForSession('rasoi'), isTrue);

    chat.setGlobalChatAvailableForSession(available: true);
    chat.setGlobalVoiceCallsAvailableForSession(available: true);
    chat.setGlobalVideoCallsAvailableForSession(available: true);
    chat.setGlobalReviewBeforeSendingForSession(enabled: false);

    expect(chat.chatAvailableForSession('rasoi'), isTrue);
    expect(chat.voiceCallsAvailableForSession('rasoi'), isTrue);
    expect(chat.videoCallsAvailableForSession('rasoi'), isTrue);
    expect(chat.reviewBeforeSendingForSession('rasoi'), isFalse);
    expect(chat.chatAvailableForSession('home-basket'), isFalse);
    expect(chat.voiceCallsAvailableForSession('home-basket'), isFalse);
    expect(chat.videoCallsAvailableForSession('home-basket'), isFalse);
    expect(chat.reviewBeforeSendingForSession('home-basket'), isTrue);
  });

  for (final entry in const <(String, String)>[
    ('/app/mool', 'Chat'),
    ('/app/social?sub=feed', 'Social Chat'),
    ('/app/buy?sub=shop', 'Shop Chat'),
    ('/app/eat/home', 'Food Chat'),
    ('/app/ride/book?type=cab', 'Travel Chat'),
    ('/app/book/doctor', 'Care Chat'),
    ('/app/work/earn', 'Work Chat'),
    ('/app/work/my-work', 'Workspace Chat'),
    ('/app/pay/home', 'Pay Chat'),
  ]) {
    testWidgets('shared settings returns exactly to ${entry.$2}', (
      tester,
    ) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final journey = await readyJourney();
      final chat = ChatSession(
        sendGateway: ReviewChatSendGateway(latency: Duration.zero),
      );
      addTearDown(journey.dispose);
      addTearDown(chat.dispose);

      await mountInbox(
        tester,
        journey: journey,
        chat: chat,
        origin: entry.$1,
        size: const Size(360, 800),
      );
      expect(find.text(entry.$2), findsOneWidget);
      expect(chat.selectedFilter, isNull);
      await openSettings(tester);
      expect(find.text('Chat settings'), findsOneWidget);
      expect(find.byKey(const Key('chat-settings-summary')), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);
      expect(find.text(entry.$2), findsOneWidget);
      expect(chat.selectedFilter, isNull);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'peace-of-mind controls change inbox, composer, calls and send review',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final journey = await readyJourney();
      final chat = ChatSession(
        sendGateway: ReviewChatSendGateway(latency: Duration.zero),
      );
      addTearDown(journey.dispose);
      addTearDown(chat.dispose);
      await mountInbox(
        tester,
        journey: journey,
        chat: chat,
        origin: '/app/mool',
        size: const Size(360, 800),
      );
      await openSettings(tester);
      expect(chat.callPreferencesBackedByService, isFalse);
      expect(
        find.text('Show or hide voice calling on this device.'),
        findsOneWidget,
      );
      expect(
        find.text('Show or hide video calling on this device.'),
        findsOneWidget,
      );
      expect(find.textContaining('saved to your account'), findsNothing);
      expect(find.textContaining('requires the call service'), findsOneWidget);

      for (final key in const [
        Key('chat-settings-chat-availability'),
        Key('chat-settings-voice-availability'),
        Key('chat-settings-video-availability'),
      ]) {
        await revealSetting(tester, key);
        await tester.tap(find.byKey(key));
        await tester.pump();
      }
      for (final key in const [
        Key('chat-settings-review-before-send'),
        Key('chat-settings-hide-previews'),
        Key('chat-settings-suggested-prompts'),
      ]) {
        await revealSetting(tester, key);
        await tester.tap(find.byKey(key));
        await tester.pump();
      }
      expect(chat.globalChatAvailableForSession, isFalse);
      expect(chat.globalVoiceCallsAvailableForSession, isFalse);
      expect(chat.globalVideoCallsAvailableForSession, isFalse);
      expect(chat.globalReviewBeforeSendingForSession, isTrue);
      expect(chat.hideMessagePreviewsForSession, isTrue);
      expect(chat.showSuggestedPromptsForSession, isFalse);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Message preview hidden'), findsWidgets);
      expect(find.text('Choose an order question to continue.'), findsNothing);

      await tester.tap(find.byKey(const Key('chat-open-thread-shop-assist')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-paused-bar')), findsOneWidget);
      expect(find.byKey(const Key('chat-composer-surface')), findsNothing);
      expect(find.byKey(const Key('chat-suggested-prompts')), findsNothing);
      await tester.tap(find.byKey(const Key('chat-thread-call')));
      await tester.pumpAndSettle();
      expect(find.text('Voice calls paused'), findsOneWidget);
      await tester.tap(find.byKey(const Key('chat-capability-continue')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('chat-open-settings-from-paused')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-settings-screen')), findsOneWidget);
      await tester.tap(
        find.byKey(const Key('chat-settings-chat-availability')),
      );
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('chat-composer-surface')), findsOneWidget);
      expect(find.byKey(const Key('chat-suggested-prompts')), findsNothing);
      await tester.enterText(
        find.byKey(const Key('chat-message-field')),
        'Please help with this order.',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('chat-send')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-send-review-dialog')), findsOneWidget);
      await tester.tap(find.byKey(const Key('chat-send-review-edit')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('chat-conversation-info')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chat-info-open-global-settings')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-settings-screen')), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('chat-conversation-info-screen')),
        findsOneWidget,
      );
      final voice = find.byKey(const Key('chat-info-voice-availability'));
      await tester.ensureVisible(voice);
      expect(tester.widget<SwitchListTile>(voice).onChanged, isNull);
      final review = find.byKey(const Key('chat-info-review-before-send'));
      await tester.scrollUntilVisible(
        review,
        180,
        scrollable: find.descendant(
          of: find.byKey(const Key('chat-conversation-info-list')),
          matching: find.byType(Scrollable),
        ),
      );
      expect(tester.widget<SwitchListTile>(review).onChanged, isNull);
      expect(
        find.text('On across Chat. Change it in Chat settings.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('privacy and spam controls complete on compact large text', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final journey = await readyJourney();
    final chat = ChatSession(
      sendGateway: ReviewChatSendGateway(latency: Duration.zero),
    );
    addTearDown(journey.dispose);
    addTearDown(chat.dispose);
    await mountInbox(
      tester,
      journey: journey,
      chat: chat,
      origin: '/app/work/earn',
      size: const Size(320, 568),
    );
    await openSettings(tester);

    await revealSetting(tester, const Key('chat-settings-notifications'));
    await tester.tap(find.byKey(const Key('chat-settings-notifications')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('chat-notification-settings-screen')),
      findsOneWidget,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await revealSetting(tester, const Key('chat-settings-who-can-message'));
    await tester.tap(find.byKey(const Key('chat-settings-who-can-message')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('chat-message-permission-picker')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('chat-message-permission-nobody')));
    await tester.pumpAndSettle();
    expect(chat.privacySettings.whoCanMessage, ChatMessagePermission.nobody);

    await revealSetting(tester, const Key('chat-settings-message-requests'));
    await tester.tap(find.byKey(const Key('chat-settings-message-requests')));
    await tester.pumpAndSettle();
    expect(chat.privacySettings.messageRequestsEnabled, isFalse);

    for (final key in const [
      Key('chat-settings-last-seen'),
      Key('chat-settings-read-receipts'),
    ]) {
      await revealSetting(tester, key);
      expect(tester.getSize(find.byKey(key)).height, greaterThanOrEqualTo(44));
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
    }
    expect(chat.privacySettings.shareLastSeen, isFalse);
    expect(chat.privacySettings.readReceipts, isFalse);

    await revealSetting(
      tester,
      const Key('chat-settings-review-message-requests'),
    );
    await tester.tap(
      find.byKey(const Key('chat-settings-review-message-requests')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('chat-message-requests-screen')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('chat-message-requests-empty')),
      findsOneWidget,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await revealSetting(tester, const Key('chat-settings-blocked-accounts'));
    await tester.tap(find.byKey(const Key('chat-settings-blocked-accounts')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('chat-blocked-accounts-screen')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('chat-blocked-accounts-empty')),
      findsOneWidget,
    );

    expect(chat.globalChatAvailableForSession, isTrue);
    expect(chat.globalVoiceCallsAvailableForSession, isTrue);
    expect(chat.globalVideoCallsAvailableForSession, isTrue);
    expect(tester.takeException(), isNull);
  });
}
