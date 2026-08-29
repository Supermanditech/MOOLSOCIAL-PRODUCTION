import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
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

  Future<void> mountThread(
    WidgetTester tester, {
    required String threadId,
    Size size = const Size(412, 915),
    double textScale = 1,
  }) async {
    await tester.binding.setSurfaceSize(size);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
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
        initialLocation: '/app/chat/thread/$threadId?return=/app/mool',
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openConversationInfo(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('chat-conversation-info')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('chat-conversation-info-screen')),
      findsOneWidget,
    );
  }

  Future<void> openGroupInfo(WidgetTester tester) async {
    await openConversationInfo(tester);
    await tester.tap(find.byKey(const Key('chat-info-group-info')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-group-info-screen')), findsOneWidget);
  }

  tearDown(() {
    TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher
        .clearTextScaleFactorTestValue();
  });

  testWidgets('group info exposes exact loaded membership only for a group', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await mountThread(tester, threadId: 'home-basket');
    await openGroupInfo(tester);

    expect(find.byKey(const Key('chat-group-identity')), findsOneWidget);
    expect(find.text('5 members'), findsWidgets);
    for (final id in ['current-user', 'amit', 'rakesh', 'neha', 'priya']) {
      expect(find.byKey(Key('chat-group-member-$id')), findsOneWidget);
    }
    await tester.tap(find.byKey(const Key('chat-group-member-amit')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('chat-group-member-recovery-amit')),
      findsOneWidget,
    );
    expect(find.text('Amit profile unavailable'), findsOneWidget);
    await tester.tap(find.byKey(const Key('chat-capability-continue')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('group actions recover truthfully and preserve exact Back', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await mountThread(
      tester,
      threadId: 'home-basket',
      size: const Size(320, 568),
      textScale: 1.3,
    );
    await openGroupInfo(tester);
    final groupList = find.byKey(const Key('chat-group-info-list'));
    await tester.drag(groupList, const Offset(0, -600));
    await tester.pumpAndSettle();

    for (final action in [
      (
        key: 'chat-group-invite',
        recovery: 'chat-group-invite-recovery',
        title: 'Invites unavailable',
      ),
      (
        key: 'chat-group-permissions',
        recovery: 'chat-group-permissions-recovery',
        title: 'Permissions unavailable',
      ),
      (
        key: 'chat-group-leave',
        recovery: 'chat-group-leave-recovery',
        title: 'Could not leave group',
      ),
    ]) {
      final target = find.byKey(Key(action.key));
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(find.byKey(Key(action.recovery)), findsOneWidget);
      expect(find.text(action.title), findsOneWidget);
      await tester.tap(find.byKey(const Key('chat-capability-continue')));
      await tester.pumpAndSettle();
    }

    final shared = find.byKey(const Key('chat-group-shared-content'));
    await tester.ensureVisible(shared);
    await tester.pumpAndSettle();
    await tester.tap(shared);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-shared-content-screen')), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-group-info-screen')), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('chat-conversation-info-screen')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('direct conversations do not expose group-only controls', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await mountThread(tester, threadId: 'mahadev');
    await openConversationInfo(tester);

    expect(find.byKey(const Key('chat-info-group-info')), findsNothing);
    expect(find.byKey(const Key('chat-info-shared-content')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
