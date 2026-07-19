import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/book/book_services.dart';
import 'package:moolsocial/features/book/book_session.dart';
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

  Future<void> mount(
    WidgetTester tester, {
    required String route,
    required JourneySession journey,
    required BookSession book,
    Size size = const Size(412, 915),
  }) async {
    await tester.binding.setSurfaceSize(size);
    await tester.pumpWidget(
      MoolSocialApp(
        key: UniqueKey(),
        session: journey,
        bookSession: book,
        initialLocation: route,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    if (finder.evaluate().isEmpty) {
      for (final element in find.byType(Scrollable).evaluate()) {
        if (finder.evaluate().isNotEmpty) break;
        final scrollable = find.byElementPredicate(
          (candidate) => identical(candidate, element),
        );
        final axis = tester.widget<Scrollable>(scrollable).axisDirection;
        final offset = axis == AxisDirection.left || axis == AxisDirection.right
            ? const Offset(-220, 0)
            : const Offset(0, -260);
        for (
          var attempt = 0;
          attempt < 12 && finder.evaluate().isEmpty;
          attempt += 1
        ) {
          await tester.drag(scrollable, offset, warnIfMissed: false);
          await tester.pumpAndSettle();
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
    'doctor completes care, patient, consent, invite and follow-up controls',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final journey = await readyJourney();
      final gateway = ReviewBookGateway(latency: Duration.zero);
      final book = BookSession(gateway: gateway);
      addTearDown(journey.dispose);
      addTearDown(book.dispose);
      await mount(
        tester,
        route: '/app/book/doctor',
        journey: journey,
        book: book,
      );

      await tapVisible(tester, const Key('doctor-ask-clinic'));
      expect(find.text('Sardarpura Clinic'), findsWidgets);
      expect(
        find.text(
          'Your appointment details are linked. How can the clinic help?',
        ),
        findsOneWidget,
      );
      await mount(
        tester,
        route: '/app/book/doctor',
        journey: journey,
        book: book,
      );
      await tapVisible(tester, const Key('doctor-care-video'));
      await tapVisible(tester, const Key('doctor-need-skin'));
      await tapVisible(tester, const Key('book-doctor'));
      await tapVisible(tester, const Key('patient-mother'));
      await tapVisible(tester, const Key('symptom-cough'));
      await tapVisible(tester, const Key('medical-consent'));
      await tapVisible(tester, const Key('confirm-doctor-details'));
      expect(gateway.doctorCalls, 1);
      expect(book.appointment, isNotNull);
      expect(find.textContaining('Appointment MS-CARE-'), findsWidgets);

      await tapVisible(tester, const Key('open-doctor-invite'));
      await tapVisible(tester, const Key('doctor-invite-show-patient-qr'));
      expect(find.byKey(const Key('doctor-patient-qr-sheet')), findsOneWidget);
      await tapVisible(tester, const Key('doctor-patient-qr-done'));

      await tapVisible(tester, const Key('doctor-invite-send-secure-link'));
      expect(find.byKey(const Key('doctor-secure-link-sheet')), findsOneWidget);
      await tapVisible(tester, const Key('doctor-secure-link-copy'));
      expect(book.noticeMessage, 'Secure patient invite link copied.');

      await tapVisible(tester, const Key('doctor-invite-use-reception-code'));
      expect(book.receptionInviteCode, hasLength(6));
      expect(
        find.byKey(const Key('doctor-reception-code-sheet')),
        findsOneWidget,
      );
      await tapVisible(tester, const Key('doctor-reception-code-done'));
      final receptionCode = book.receptionInviteCode;
      await tapVisible(tester, const Key('doctor-invite-use-reception-code'));
      expect(book.receptionInviteCode, receptionCode);
      await tapVisible(tester, const Key('doctor-reception-code-done'));

      await tapVisible(
        tester,
        const Key('doctor-invite-add-qr-to-prescription'),
      );
      expect(book.prescriptionInviteQrAdded, isTrue);
      expect(
        find.byKey(const Key('doctor-prescription-qr-status')),
        findsOneWidget,
      );
      await tapVisible(
        tester,
        const Key('doctor-invite-add-qr-to-prescription'),
      );
      expect(
        book.noticeMessage,
        'The patient invite QR is already on the prescription.',
      );
      await tapVisible(tester, const Key('preview-patient-invite'));
      await tapVisible(tester, const Key('clinic-invite-consent'));
      await tapVisible(tester, const Key('join-clinic-followup'));
      await tapVisible(tester, const Key('followup-upload-report'));
      await tapVisible(tester, const Key('followup-reminder'));
      expect(book.followUpReportUploaded, isTrue);
      expect(book.medicineReminder, isTrue);
      await tapVisible(tester, const Key('followup-book-slot'));
      expect(find.byKey(const Key('followup-slot-sheet')), findsOneWidget);
      await tapVisible(tester, const Key('followup-slot-video-today'));
      expect(book.followUpSlot, 'Video · Today 6:20 PM');
      await tapVisible(tester, const Key('followup-sharing'));
      expect(book.clinicSharing, isFalse);
    },
  );

  testWidgets(
    'doctor rejects missing child age and consent, then exact retry confirms once',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final journey = await readyJourney();
      final gateway = ReviewBookGateway(
        failNextDoctor: true,
        latency: Duration.zero,
      );
      final book = BookSession(gateway: gateway);
      addTearDown(journey.dispose);
      addTearDown(book.dispose);
      await mount(
        tester,
        route: '/app/book/doctor/details',
        journey: journey,
        book: book,
      );

      await tapVisible(tester, const Key('patient-child'));
      await tapVisible(tester, const Key('confirm-doctor-details'));
      expect(find.textContaining('child’s age'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('child-age')), '30');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.textContaining('1 to 17 years'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('child-age')), '8');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tapVisible(tester, const Key('confirm-doctor-details'));
      expect(find.textContaining('Allow sharing'), findsOneWidget);
      await tapVisible(tester, const Key('medical-consent'));
      await tapVisible(tester, const Key('confirm-doctor-details'));
      expect(find.textContaining('could not be confirmed'), findsOneWidget);
      expect(book.appointment, isNull);
      await tapVisible(tester, const Key('confirm-doctor-details'));
      expect(book.appointment, isNotNull);
      expect(gateway.doctorCalls, 2);
    },
  );

  testWidgets(
    'patient cannot join clinic invite without consent and can recover',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final journey = await readyJourney();
      final book = BookSession(
        gateway: ReviewBookGateway(latency: Duration.zero),
      );
      addTearDown(journey.dispose);
      addTearDown(book.dispose);
      await mount(
        tester,
        route: '/app/book/doctor/join',
        journey: journey,
        book: book,
      );

      await tapVisible(tester, const Key('join-clinic-followup'));
      expect(find.textContaining('Allow this verified clinic'), findsOneWidget);
      expect(book.clinicInviteJoined, isFalse);
      await tapVisible(tester, const Key('clinic-invite-consent'));
      await tapVisible(tester, const Key('join-clinic-followup'));
      expect(book.clinicInviteJoined, isTrue);
      expect(find.text('Follow-up'), findsWidgets);
    },
  );

  testWidgets(
    'salon completes selection, payment, visit, bill, rating and support',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final journey = await readyJourney();
      final gateway = ReviewBookGateway(latency: Duration.zero);
      final book = BookSession(gateway: gateway);
      addTearDown(journey.dispose);
      addTearDown(book.dispose);
      await mount(
        tester,
        route: '/app/book/salon',
        journey: journey,
        book: book,
      );

      await tapVisible(tester, const Key('salon-service-facial'));
      await tapVisible(tester, const Key('salon-mode-home'));
      await tapVisible(tester, const Key('review-salon-slot'));
      await tapVisible(tester, const Key('salon-payment-cardHold'));
      await tapVisible(tester, const Key('salon-addon-cleanup'));
      await tapVisible(tester, const Key('confirm-salon-slot'));
      expect(gateway.salonCalls, 1);
      expect(book.salonBooking, isNotNull);
      await tapVisible(tester, const Key('salon-directions'));
      await tapVisible(tester, const Key('salon-arrived'));
      await tapVisible(tester, const Key('salon-service-done'));
      await tapVisible(tester, const Key('pay-salon-bill'));
      expect(book.salonPaid, isTrue);
      expect(gateway.salonPaymentCalls, 1);
      await tapVisible(tester, const Key('salon-rating-5'));
      await tapVisible(tester, const Key('submit-salon-rating'));
      expect(book.salonRating, 5);

      await mount(
        tester,
        route: '/app/book/salon/support',
        journey: journey,
        book: book,
      );
      await tapVisible(tester, const Key('salon-issue-service'));
      await tapVisible(tester, const Key('submit-salon-support'));
      expect(book.salonSupportCase, isNotNull);
      expect(gateway.supportCalls, 1);
    },
  );

  testWidgets(
    'salon slot and payment failures replay without duplicate booking or debit',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final journey = await readyJourney();
      final gateway = ReviewBookGateway(
        failNextSalon: true,
        failNextSalonPayment: true,
        latency: Duration.zero,
      );
      final book = BookSession(gateway: gateway);
      addTearDown(journey.dispose);
      addTearDown(book.dispose);
      await mount(
        tester,
        route: '/app/book/salon/confirm',
        journey: journey,
        book: book,
      );

      await tapVisible(tester, const Key('confirm-salon-slot'));
      expect(find.textContaining('No payment was taken'), findsOneWidget);
      expect(book.salonBooking, isNull);
      await tapVisible(tester, const Key('confirm-salon-slot'));
      expect(book.salonBooking, isNotNull);
      expect(gateway.salonCalls, 2);
      await tapVisible(tester, const Key('salon-arrived'));
      await tapVisible(tester, const Key('salon-service-done'));
      await tapVisible(tester, const Key('pay-salon-bill'));
      expect(find.textContaining('No money was deducted'), findsOneWidget);
      expect(book.salonPaid, isFalse);
      await tapVisible(tester, const Key('pay-salon-bill'));
      expect(book.salonPaid, isTrue);
      expect(gateway.salonPaymentCalls, 2);
      expect(await book.paySalonBill(), isTrue);
      expect(gateway.salonPaymentCalls, 2);
    },
  );

  testWidgets('salon cancel supports keep and free cancellation completion', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final journey = await readyJourney();
    final book = BookSession(
      gateway: ReviewBookGateway(latency: Duration.zero),
    );
    await book.confirmSalon();
    addTearDown(journey.dispose);
    addTearDown(book.dispose);
    await mount(
      tester,
      route: '/app/book/salon/confirmed',
      journey: journey,
      book: book,
    );

    await tapVisible(tester, const Key('salon-cancel'));
    await tester.tap(find.text('Keep booking'));
    await tester.pumpAndSettle();
    expect(book.salonBooking, isNotNull);
    await tapVisible(tester, const Key('salon-cancel'));
    await tapVisible(tester, const Key('confirm-salon-cancel'));
    expect(book.salonBooking, isNull);
    expect(find.textContaining('free window'), findsOneWidget);
  });

  testWidgets(
    'task completes detail, hold, helper, proof, release and saved receipt',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final journey = await readyJourney();
      final gateway = ReviewBookGateway(latency: Duration.zero);
      final book = BookSession(gateway: gateway);
      addTearDown(journey.dispose);
      addTearDown(book.dispose);
      await mount(
        tester,
        route: '/app/book/task',
        journey: journey,
        book: book,
      );

      await tapVisible(tester, const Key('task-city-delhi'));
      await tapVisible(tester, const Key('task-type-document'));
      await tester.enterText(
        find.byKey(const Key('task-detail')),
        'Visit registry counter, collect form and send photo',
      );
      await tapVisible(tester, const Key('review-task'));
      await tapVisible(tester, const Key('task-payment-card'));
      await tapVisible(tester, const Key('confirm-task'));
      expect(gateway.taskCalls, 1);
      expect(book.task, isNotNull);
      await tapVisible(tester, const Key('task-proof-arrived'));
      await tapVisible(tester, const Key('release-task-payment'));
      expect(gateway.releaseCalls, 1);
      expect(book.taskReleased, isTrue);
      expect(find.textContaining('₹519 released'), findsWidgets);
      await tapVisible(tester, const Key('task-rating-5'));
      await tapVisible(tester, const Key('save-helper'));
      expect(book.helperSaved, isTrue);
    },
  );

  testWidgets(
    'task rejects short detail and failed matching retries without a false hold',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final journey = await readyJourney();
      final gateway = ReviewBookGateway(
        failNextTask: true,
        latency: Duration.zero,
      );
      final book = BookSession(gateway: gateway);
      addTearDown(journey.dispose);
      addTearDown(book.dispose);
      await mount(
        tester,
        route: '/app/book/task',
        journey: journey,
        book: book,
      );

      await tester.enterText(find.byKey(const Key('task-detail')), 'short');
      await tapVisible(tester, const Key('review-task'));
      expect(find.textContaining('at least 12 characters'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('task-detail')),
        'Collect parcel from Mahadev counter and send photo',
      );
      await tapVisible(tester, const Key('review-task'));
      await tapVisible(tester, const Key('confirm-task'));
      expect(find.textContaining('No hold was created'), findsOneWidget);
      expect(book.task, isNull);
      await tapVisible(tester, const Key('confirm-task'));
      expect(book.task, isNotNull);
      expect(gateway.taskCalls, 2);
      expect(await book.confirmTask(), isTrue);
      expect(gateway.taskCalls, 2);
    },
  );

  testWidgets(
    'task release failure, clearer proof and exact retry remain protected',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final journey = await readyJourney();
      final gateway = ReviewBookGateway(
        failNextTaskRelease: true,
        latency: Duration.zero,
      );
      final book = BookSession(gateway: gateway)
        ..taskDetail = 'Collect parcel and send clear counter photo';
      await book.confirmTask();
      book.receiveTaskProof();
      addTearDown(journey.dispose);
      addTearDown(book.dispose);
      await mount(
        tester,
        route: '/app/book/task/proof',
        journey: journey,
        book: book,
      );

      await tapVisible(tester, const Key('release-task-payment'));
      expect(find.textContaining('No money moved'), findsOneWidget);
      expect(book.taskReleased, isFalse);
      await tapVisible(tester, const Key('release-task-payment'));
      expect(book.taskReleased, isTrue);
      expect(gateway.releaseCalls, 2);
      expect(await book.releaseTaskPayment(), isTrue);
      expect(gateway.releaseCalls, 2);
    },
  );

  testWidgets(
    'task support failure retries once and resolution failure preserves case',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final journey = await readyJourney();
      final gateway = ReviewBookGateway(
        failNextSupport: true,
        failNextResolution: true,
        latency: Duration.zero,
      );
      final book = BookSession(gateway: gateway)
        ..taskDetail = 'Collect parcel and send clear counter photo';
      await book.confirmTask();
      book.receiveTaskProof();
      addTearDown(journey.dispose);
      addTearDown(book.dispose);
      await mount(
        tester,
        route: '/app/book/task/support',
        journey: journey,
        book: book,
      );

      await tapVisible(tester, const Key('task-issue-overcharged'));
      await tapVisible(tester, const Key('submit-task-support'));
      expect(find.textContaining('remains protected'), findsWidgets);
      expect(book.taskSupportCase, isNull);
      await tapVisible(tester, const Key('submit-task-support'));
      expect(book.taskSupportCase, isNotNull);
      expect(gateway.supportCalls, 2);
      await tapVisible(tester, const Key('view-task-decision'));
      await tapVisible(tester, const Key('task-resolution-refund'));
      await tapVisible(tester, const Key('accept-task-resolution'));
      expect(find.textContaining('No money moved'), findsOneWidget);
      expect(book.resolutionComplete, isFalse);
      await tapVisible(tester, const Key('accept-task-resolution'));
      expect(book.resolutionComplete, isTrue);
      expect(gateway.resolutionCalls, 2);
      expect(find.text('Resolution complete'), findsWidgets);
    },
  );

  testWidgets('compact Book entry and dock targets remain at least 44 points', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = 1.25;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final journey = await readyJourney();
    final book = BookSession(
      gateway: ReviewBookGateway(latency: Duration.zero),
    );
    addTearDown(journey.dispose);
    addTearDown(book.dispose);
    await mount(
      tester,
      route: '/app/book/home',
      journey: journey,
      book: book,
      size: const Size(360, 800),
    );

    for (final key in const [
      Key('book-home-task'),
      Key('book-home-doctor'),
      Key('book-home-salon'),
      Key('book-dock-mool'),
      Key('book-dock-book'),
      Key('book-dock-activity'),
      Key('book-dock-help'),
      Key('book-dock-chat'),
    ]) {
      final finder = find.byKey(key);
      for (
        var attempt = 0;
        attempt < 10 && finder.evaluate().isEmpty;
        attempt += 1
      ) {
        await tester.drag(
          find.byType(Scrollable).first,
          const Offset(0, -120),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();
      }
      expect(finder, findsOneWidget, reason: '$key missing');
      final size = tester.getSize(finder);
      expect(size.width, greaterThanOrEqualTo(44), reason: '$key width');
      expect(size.height, greaterThanOrEqualTo(44), reason: '$key height');
    }
    expect(tester.takeException(), isNull);
  });
}
