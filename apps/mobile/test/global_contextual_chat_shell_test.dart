import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/chat/chat_entry_context.dart';
import 'package:moolsocial/features/chat/chat_models.dart';
import 'package:moolsocial/features/chat/chat_services.dart';
import 'package:moolsocial/features/chat/chat_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

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
        ChatThreadType.support,
      ),
      (
        '/app/work/earn',
        ChatEntryContextId.work,
        'Work Chat',
        ChatThreadType.business,
      ),
      (
        '/app/retailer/orders',
        ChatEntryContextId.workspace,
        'Workspace Chat',
        ChatThreadType.business,
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
      ChatThreadType.support,
    ),
    ('/app/work/earn', 'Work Chat', 'Opportunities', ChatThreadType.business),
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
      expect(find.byKey(const Key('chat-context-icon')), findsOneWidget);
      expect(find.text(entry.$2), findsOneWidget);
      expect(find.text(entry.$3), findsOneWidget);
      expect(find.text('MoolSocial Chat'), findsNothing);
      expect(chat.selectedFilter, entry.$4);
      final title = tester.renderObject<RenderParagraph>(find.text(entry.$2));
      final subtitle = tester.renderObject<RenderParagraph>(
        find.text(entry.$3),
      );
      expect(title.didExceedMaxLines, isFalse);
      expect(subtitle.didExceedMaxLines, isFalse);
      expect(tester.takeException(), isNull);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-inbox-screen')), findsNothing);
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
