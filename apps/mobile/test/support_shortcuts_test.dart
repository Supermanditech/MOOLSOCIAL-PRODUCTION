import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/chat/chat_models.dart';
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

  Future<void> verifyShortcut(
    WidgetTester tester, {
    required JourneySession journey,
    required ChatSession chat,
    required String route,
    required Key shortcut,
    required String expectedThreadId,
  }) async {
    await tester.pumpWidget(
      MoolSocialApp(
        key: UniqueKey(),
        session: journey,
        chatSession: chat,
        initialLocation: route,
        legacyPresentationForTestsOnly: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(shortcut), findsOneWidget);
    await tester.tap(find.byKey(shortcut));
    await tester.pumpAndSettle();
    expect(
      find.byKey(Key('chat-open-thread-$expectedThreadId')),
      findsOneWidget,
    );
    expect(chat.selectedFilter, ChatThreadType.support);
  }

  testWidgets(
    'Book, Work and Pay help shortcuts open the owned Support inbox',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(412, 915));
      final journey = await readyJourney();
      final chat = ChatSession();
      addTearDown(journey.dispose);
      addTearDown(chat.dispose);

      await verifyShortcut(
        tester,
        journey: journey,
        chat: chat,
        route: '/app/book/home',
        shortcut: const Key('book-help'),
        expectedThreadId: 'order-support',
      );
      await verifyShortcut(
        tester,
        journey: journey,
        chat: chat,
        route: '/app/work/my-work',
        shortcut: const Key('work-help'),
        expectedThreadId: 'workspace-support',
      );
      await verifyShortcut(
        tester,
        journey: journey,
        chat: chat,
        route: '/app/pay/home',
        shortcut: const Key('pay-help-shortcut'),
        expectedThreadId: 'pay-support',
      );
    },
  );
}
