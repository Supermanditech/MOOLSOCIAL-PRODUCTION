import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/book/book_models.dart';
import 'package:moolsocial/features/book/book_services.dart';
import 'package:moolsocial/features/book/book_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<Finder> reveal(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    if (finder.evaluate().isEmpty) {
      for (final state
          in find
              .byWidgetPredicate((widget) => widget is Scrollable)
              .evaluate()
              .whereType<StatefulElement>()
              .map((element) => element.state)
              .whereType<ScrollableState>()) {
        state.position.jumpTo(state.position.minScrollExtent);
        await tester.pump();
        for (
          var attempt = 0;
          attempt < 40 && finder.evaluate().isEmpty;
          attempt += 1
        ) {
          state.position.jumpTo(
            (state.position.pixels + 240).clamp(
              state.position.minScrollExtent,
              state.position.maxScrollExtent,
            ),
          );
          await tester.pump();
        }
        if (finder.evaluate().isNotEmpty) break;
      }
    }
    expect(finder, findsOneWidget, reason: 'Missing target $key');
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    return finder;
  }

  Future<void> tap(WidgetTester tester, Key key) async {
    await tester.tap(await reveal(tester, key));
    await tester.pumpAndSettle();
  }

  Future<void> openRoute(WidgetTester tester, String route) async {
    tester.element(find.byType(Scaffold).first).go(route);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'physical task completes helper, share, support and resolution intents',
    (tester) async {
      final journey = JourneySession(
        store: MemoryJourneyStore(
          snapshot: const JourneySnapshot(
            languageCode: 'en',
            areaMode: 'manual',
            areaLabel: 'Jodhpur',
            setupComplete: true,
          ),
        ),
        otpGateway: ReviewOtpGateway(signedIn: true),
      );
      final book = BookSession(
        gateway: ReviewBookGateway(latency: Duration.zero),
      );
      addTearDown(journey.dispose);
      addTearDown(book.dispose);
      await journey.start();
      book.chooseTaskCity('Delhi');
      book.chooseTaskType(TaskType.document);
      book.saveTaskDetail(
        'Visit registry counter, collect form and send photo',
      );
      book.chooseTaskPayment(TaskPayment.card);
      expect(await book.confirmTask(), isTrue);

      await tester.pumpWidget(
        MoolSocialApp(
          session: journey,
          bookSession: book,
          initialLocation: '/app/book/task/live',
        ),
      );
      await tester.pumpAndSettle();
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();

      await tap(tester, const Key('task-live-share'));
      expect(book.noticeMessage, 'Live task link copied.');
      await tap(tester, const Key('dismiss-book-message'));
      await tap(tester, const Key('task-live-call'));
      expect(book.noticeMessage, 'Calling Ramesh securely…');
      await tap(tester, const Key('dismiss-book-message'));
      await tap(tester, const Key('task-live-chat'));
      expect(find.text('Ramesh Kumar'), findsWidgets);
      await binding.takeScreenshot('book-task-032-helper-chat');
      await tap(tester, const Key('chat-back'));
      await tap(tester, const Key('chat-back'));
      expect(find.text('Live task'), findsWidgets);

      book.receiveTaskProof();
      await openRoute(tester, '/app/book/task/support');
      await tap(tester, const Key('task-issue-overcharged'));
      await tap(tester, const Key('submit-task-support'));
      await tap(tester, const Key('view-task-decision'));
      await tap(tester, const Key('task-resolution-refund'));
      await tap(tester, const Key('task-resolution-chat'));
      expect(find.text('Order Support'), findsWidgets);
      await tap(tester, const Key('chat-back'));
      await tap(tester, const Key('chat-back'));
      expect(find.text('Choose resolution'), findsWidgets);
      await tap(tester, const Key('accept-task-resolution'));
      await tap(tester, const Key('track-task-resolution'));
      expect(find.text('Task completed'), findsWidgets);
      await tap(tester, const Key('task-share-receipt-proof'));
      expect(book.noticeMessage, 'Receipt and proof link copied.');
      await binding.takeScreenshot('book-task-033-resolution-complete');
    },
  );
}
