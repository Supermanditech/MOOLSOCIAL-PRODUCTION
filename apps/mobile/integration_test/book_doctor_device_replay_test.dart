import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/book/book_services.dart';
import 'package:moolsocial/features/book/book_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<Finder> reveal(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    if (finder.evaluate().isEmpty) {
      final scrollables = find.byWidgetPredicate(
        (widget) => widget is Scrollable,
      );
      for (final state
          in scrollables
              .evaluate()
              .whereType<StatefulElement>()
              .map((element) => element.state)
              .whereType<ScrollableState>()) {
        if (state.position.maxScrollExtent <= state.position.minScrollExtent) {
          continue;
        }
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

  Future<void> tapVisible(WidgetTester tester, Key key) async {
    await tester.tap(await reveal(tester, key));
    await tester.pumpAndSettle();
  }

  Future<void> openRoute(WidgetTester tester, String route) async {
    tester.element(find.byType(Scaffold).first).go(route);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'physical Doctor completes clinic, invite and follow-up nested actions',
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

      await tester.pumpWidget(
        MoolSocialApp(
          session: journey,
          bookSession: book,
          initialLocation: '/app/book/doctor',
        ),
      );
      await tester.pumpAndSettle();
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();

      await tapVisible(tester, const Key('doctor-ask-clinic'));
      expect(find.text('Sardarpura Clinic'), findsWidgets);
      expect(
        find.text(
          'Your appointment details are linked. How can the clinic help?',
        ),
        findsOneWidget,
      );

      await openRoute(tester, '/app/book/doctor/invite');
      await tapVisible(tester, const Key('doctor-invite-show-patient-qr'));
      expect(find.byKey(const Key('doctor-patient-qr-sheet')), findsOneWidget);
      await tapVisible(tester, const Key('doctor-patient-qr-done'));

      await tapVisible(tester, const Key('doctor-invite-send-secure-link'));
      expect(find.byKey(const Key('doctor-secure-link-sheet')), findsOneWidget);
      await tapVisible(tester, const Key('doctor-secure-link-copy'));
      expect(book.noticeMessage, 'Secure patient invite link copied.');

      await tapVisible(tester, const Key('doctor-invite-use-reception-code'));
      final receptionCode = book.receptionInviteCode;
      expect(receptionCode, hasLength(6));
      await tapVisible(tester, const Key('doctor-reception-code-done'));
      await tapVisible(tester, const Key('doctor-invite-use-reception-code'));
      expect(book.receptionInviteCode, receptionCode);
      await tapVisible(tester, const Key('doctor-reception-code-done'));

      await tapVisible(
        tester,
        const Key('doctor-invite-add-qr-to-prescription'),
      );
      expect(book.prescriptionInviteQrAdded, isTrue);
      await tapVisible(
        tester,
        const Key('doctor-invite-add-qr-to-prescription'),
      );
      expect(
        book.noticeMessage,
        'The patient invite QR is already on the prescription.',
      );
      await binding.takeScreenshot('book-doctor-026-invite-actions');

      await openRoute(tester, '/app/book/doctor/followup');
      await tapVisible(tester, const Key('followup-book-slot'));
      await tapVisible(tester, const Key('followup-slot-video-today'));
      expect(book.followUpSlot, 'Video · Today 6:20 PM');
      await binding.takeScreenshot('book-doctor-027-followup-slot');
    },
  );
}
