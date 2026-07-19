import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/captain/captain_services.dart';
import 'package:moolsocial/features/captain/captain_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<Finder> reveal(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    if (finder.evaluate().isEmpty) {
      final scrollables = find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable &&
            {
              AxisDirection.down,
              AxisDirection.up,
            }.contains(widget.axisDirection),
      );
      expect(scrollables, findsWidgets, reason: 'No scrollable for $key');
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
          attempt < 50 && finder.evaluate().isEmpty;
          attempt += 1
        ) {
          state.position.jumpTo(
            (state.position.pixels + 260).clamp(
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

  Future<void> enter(WidgetTester tester, Key key, String value) async {
    await tester.enterText(await reveal(tester, key), value);
    await tester.pumpAndSettle();
  }

  Future<void> openRoute(WidgetTester tester, String route) async {
    tester.element(find.byType(Scaffold).first).go(route);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'physical Captain completes every exact failed tap from availability through payout and support',
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
      final gateway = ReviewCaptainGateway()
        ..failAvailability = true
        ..failAccept = true
        ..failStart = true
        ..failArrival = true
        ..failPayment = true
        ..failVerification = true
        ..failSupport = true
        ..failApplication = true;
      final captain = CaptainSession(gateway: gateway);
      addTearDown(journey.dispose);
      addTearDown(captain.dispose);
      await journey.start();

      await tester.pumpWidget(
        MoolSocialApp(
          session: journey,
          captainSession: captain,
          initialLocation: '/app/captain',
        ),
      );
      await tester.pumpAndSettle();
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('captain-home-screen')), findsOneWidget);
      await binding.takeScreenshot('captain-116-home');
      await tapVisible(tester, const Key('captain-online-toggle'));
      expect(captain.availableForRides, isFalse);
      await tapVisible(tester, const Key('captain-online-toggle'));
      expect(captain.availableForRides, isTrue);
      expect(gateway.availabilityCalls, 2);

      await tapVisible(tester, const Key('captain-open-request'));
      expect(find.byKey(const Key('captain-request-screen')), findsOneWidget);
      await binding.takeScreenshot('captain-117-request');
      await tapVisible(tester, const Key('captain-accept-ride'));
      expect(captain.assignmentId, isNull);
      await tapVisible(tester, const Key('captain-accept-ride'));
      expect(captain.assignmentId, 'CAP-ASG-117-4821');
      expect(gateway.acceptCalls, 2);

      expect(find.byKey(const Key('captain-pickup-screen')), findsOneWidget);
      await tapVisible(tester, const Key('captain-pickup-arrived'));
      await enter(tester, const Key('captain-trip-otp'), '4821');
      await tapVisible(tester, const Key('captain-trip-start'));
      expect(captain.tripStartId, isNull);
      await tapVisible(tester, const Key('captain-trip-start'));
      expect(captain.tripStartId, 'CAP-START-118-4821');
      expect(gateway.startCalls, 2);

      expect(find.byKey(const Key('captain-live-trip-screen')), findsOneWidget);
      await binding.takeScreenshot('captain-119-live-trip');
      await tapVisible(tester, const Key('captain-arrive-destination'));
      expect(captain.arrivalId, isNull);
      await tapVisible(tester, const Key('captain-arrive-destination'));
      expect(captain.arrivalId, 'CAP-ARR-119-4821');
      expect(gateway.arrivalCalls, 2);

      expect(
        find.byKey(const Key('captain-completion-screen')),
        findsOneWidget,
      );
      await tapVisible(tester, const Key('captain-check-payment'));
      expect(captain.paymentReceiptId, isNull);
      await tapVisible(tester, const Key('captain-check-payment'));
      expect(captain.paymentReceiptId, 'CAP-PAY-120-4821');
      expect(gateway.paymentCalls, 2);
      await binding.takeScreenshot('captain-120-payment-confirmed');
      await tapVisible(tester, const Key('captain-payment-view-earnings'));
      expect(find.byKey(const Key('captain-earnings-screen')), findsOneWidget);

      await openRoute(tester, '/app/captain/compliance');
      await tapVisible(tester, const Key('captain-document-insurance'));
      await tapVisible(tester, const Key('captain-verification-consent'));
      await tapVisible(tester, const Key('captain-verification-start'));
      expect(captain.verificationId, isNull);
      await tapVisible(tester, const Key('captain-verification-start'));
      expect(captain.verificationId, 'CAP-VER-122-0719');
      expect(gateway.verificationCalls, 2);
      await tapVisible(tester, const Key('captain-verification-close'));

      await openRoute(tester, '/app/captain/support-work');
      await tapVisible(tester, const Key('captain-support-trip'));
      await enter(
        tester,
        const Key('captain-support-message'),
        'The pickup route changed and I need help.',
      );
      await tapVisible(tester, const Key('captain-support-create'));
      expect(captain.supportCaseId, isNull);
      await tapVisible(tester, const Key('captain-support-create'));
      expect(captain.supportCaseId, 'CAP-CASE-123-0719');
      expect(gateway.supportCalls, 2);
      await tapVisible(tester, const Key('captain-support-close'));

      await tapVisible(tester, const Key('captain-support-tab-paidWork'));
      await tapVisible(
        tester,
        const Key('captain-work-review-captain-onboarding'),
      );
      await tapVisible(tester, const Key('captain-work-terms'));
      await tapVisible(tester, const Key('captain-work-apply'));
      expect(captain.workApplicationId, isNull);
      await tapVisible(tester, const Key('captain-work-apply'));
      expect(captain.workApplicationId, 'CAP-WORK-123-0719');
      expect(gateway.applicationCalls, 2);
      await binding.takeScreenshot('captain-123-support-and-opportunity');

      expect([
        gateway.availabilityCalls,
        gateway.acceptCalls,
        gateway.startCalls,
        gateway.arrivalCalls,
        gateway.paymentCalls,
        gateway.verificationCalls,
        gateway.supportCalls,
        gateway.applicationCalls,
      ], everyElement(2));
    },
  );
}
