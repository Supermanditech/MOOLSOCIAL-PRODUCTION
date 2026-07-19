import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/work/work_models.dart';
import 'package:moolsocial/features/work/work_services.dart';
import 'package:moolsocial/features/work/work_session.dart';

void main() {
  Future<JourneySession> readyJourney() async {
    final session = JourneySession(
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
    await session.start();
    return session;
  }

  Future<(JourneySession, WorkSession)> mount(
    WidgetTester tester, {
    required String route,
    WorkSession? workSession,
    Size size = const Size(412, 915),
  }) async {
    await tester.binding.setSurfaceSize(size);
    final journey = await readyJourney();
    final work = workSession ?? WorkSession();
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      journey.dispose();
      work.dispose();
    });
    await tester.pumpWidget(
      MoolSocialApp(
        key: UniqueKey(),
        session: journey,
        workSession: work,
        initialLocation: route,
      ),
    );
    await tester.pumpAndSettle();
    return (journey, work);
  }

  Future<void> tapVisible(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    if (finder.evaluate().isEmpty) {
      final vertical = find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable &&
            {
              AxisDirection.down,
              AxisDirection.up,
            }.contains(widget.axisDirection),
      );
      expect(vertical, findsWidgets, reason: 'No scrollable for $key');
      await tester.drag(vertical.last, const Offset(0, 900));
      await tester.pumpAndSettle();
      for (
        var attempt = 0;
        attempt < 12 && finder.evaluate().isEmpty;
        attempt += 1
      ) {
        await tester.drag(vertical.last, const Offset(0, -260));
        await tester.pumpAndSettle();
      }
    }
    expect(finder, findsOneWidget, reason: 'Missing tap target $key');
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> enter(WidgetTester tester, Key key, String value) async {
    final finder = find.byKey(key);
    if (finder.evaluate().isEmpty) {
      final vertical = find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable &&
            {
              AxisDirection.down,
              AxisDirection.up,
            }.contains(widget.axisDirection),
      );
      expect(vertical, findsWidgets, reason: 'No scrollable for $key');
      await tester.drag(vertical.last, const Offset(0, 900));
      await tester.pumpAndSettle();
      for (
        var attempt = 0;
        attempt < 12 && finder.evaluate().isEmpty;
        attempt += 1
      ) {
        await tester.drag(vertical.last, const Offset(0, -260));
        await tester.pumpAndSettle();
      }
    }
    expect(finder, findsOneWidget, reason: 'Missing field $key');
    await tester.ensureVisible(finder);
    await tester.enterText(finder, value);
    await tester.pumpAndSettle();
  }

  Future<void> chooseRetailer(WidgetTester tester) async {
    await tapVisible(tester, const Key('work-family-products-trade'));
    await tapVisible(tester, const Key('work-profile-retailer-grocery'));
    await tapVisible(tester, const Key('work-continue-proof'));
    expect(find.byKey(const Key('work-proof-screen')), findsOneWidget);
  }

  Future<void> addProof(WidgetTester tester, String proofId) async {
    await tapVisible(tester, Key('work-add-proof-$proofId'));
    await tapVisible(tester, const Key('work-proof-source-upload'));
  }

  testWidgets(
    'new user completes saved opportunity through verified live retailer setup',
    (tester) async {
      final (_, work) = await mount(tester, route: '/app/work/earn');

      await tapVisible(tester, const Key('work-opportunity-mool-explainer'));
      await tapVisible(tester, const Key('work-review-mool-explainer'));
      expect(find.byKey(const Key('work-opportunity-screen')), findsOneWidget);
      await tapVisible(tester, const Key('work-term-payment'));
      expect(find.textContaining('₹1,500 is reserved'), findsOneWidget);

      await tapVisible(tester, const Key('work-apply-opportunity'));
      expect(find.byKey(const Key('my-work-screen')), findsOneWidget);
      expect(work.savedOpportunity?.id, 'mool-explainer');

      await tapVisible(tester, const Key('my-work-start'));
      await chooseRetailer(tester);
      await enter(tester, const Key('work-name'), 'Mahadev Fresh Mart');
      await enter(tester, const Key('work-area'), 'Sardarpura, Jodhpur');
      await enter(
        tester,
        const Key('work-activity'),
        'Grocery and household products',
      );
      await tapVisible(tester, const Key('work-details-continue'));
      await addProof(tester, 'shop-front');
      await addProof(tester, 'owner-authority');
      await tapVisible(tester, const Key('work-proof-review'));
      await tapVisible(tester, const Key('work-declaration'));
      await tapVisible(tester, const Key('work-submit-profile'));

      expect(find.byKey(const Key('work-status-screen')), findsOneWidget);
      expect(work.reviewCaseId, isNotNull);
      await tapVisible(tester, const Key('work-remind-gst'));
      expect(work.gstReminder, isTrue);
      await tapVisible(tester, const Key('work-check-review'));

      expect(find.byKey(const Key('workspace-ready-screen')), findsOneWidget);
      expect(work.activeWorkspace?.verified, isTrue);
      await tapVisible(tester, const Key('work-set-up-shop'));
      await tapVisible(tester, const Key('retailer-add-catalog-product'));
      await enter(tester, const Key('retailer-product-quantity'), '24');
      await enter(tester, const Key('retailer-product-buy-price'), '48');
      await enter(tester, const Key('retailer-product-sell-price'), '55');
      await tapVisible(tester, const Key('retailer-home-delivery'));
      await tapVisible(tester, const Key('retailer-finish-setup'));

      expect(work.reviewStage, WorkReviewStage.live);
      expect(work.retailerSetupSaved, isTrue);
      expect(find.text('Shop ready'), findsOneWidget);
      expect(work.gateway.submissionCalls, 1);
      expect(work.gateway.reviewCalls, 1);
      expect(work.gateway.setupCalls, 1);
    },
  );

  testWidgets(
    'verified workspace application failure replays once without duplication',
    (tester) async {
      final gateway = ReviewWorkGateway()..failApplication = true;
      final work = WorkSession(gateway: gateway)..seedVerifiedWorkspace();
      await mount(
        tester,
        route: '/app/work/opportunity/mool-explainer',
        workSession: work,
      );

      await tapVisible(tester, const Key('work-apply-opportunity'));
      expect(
        find.text('Application was not sent. Your opportunity is still saved.'),
        findsOneWidget,
      );
      expect(work.applicationId, isNull);
      await tapVisible(tester, const Key('work-apply-opportunity'));
      expect(work.applicationId, isNotNull);
      expect(gateway.applicationCalls, 2);
      expect(find.text('Application sent'), findsOneWidget);
    },
  );

  testWidgets('feed filters, search empty and failed refresh recover safely', (
    tester,
  ) async {
    final gateway = ReviewWorkGateway()..failFeed = true;
    final work = WorkSession(gateway: gateway);
    await mount(tester, route: '/app/work/earn', workSession: work);

    await tapVisible(tester, const Key('work-filter-jobs'));
    expect(find.text('City operations coordinator'), findsOneWidget);
    expect(find.text('Make one MoolSocial explainer video'), findsNothing);

    await enter(tester, const Key('work-search'), 'no funded work');
    expect(find.byKey(const Key('work-empty')), findsOneWidget);
    await tapVisible(tester, const Key('work-empty-action'));
    expect(work.filter, WorkFeedFilter.forYou);
    expect(work.searchQuery, isEmpty);

    await tapVisible(tester, const Key('work-refresh-feed'));
    expect(
      find.text(
        'Work could not be refreshed. Check your connection and try again.',
      ),
      findsOneWidget,
    );
    await tapVisible(tester, const Key('work-refresh-feed'));
    expect(find.text('Verified work is up to date.'), findsOneWidget);
  });

  testWidgets(
    'alternate work number handles invalid, gateway failure and exact OTP',
    (tester) async {
      final gateway = ReviewWorkGateway()..failOtp = true;
      final work = WorkSession(gateway: gateway);
      await mount(tester, route: '/app/work/choose', workSession: work);

      await tapVisible(tester, const Key('work-family-products-trade'));
      await tapVisible(tester, const Key('work-profile-retailer-grocery'));
      await enter(tester, const Key('work-alternate-mobile'), '123');
      await tapVisible(tester, const Key('work-send-alternate-otp'));
      expect(
        find.text('Enter a valid 10-digit alternate mobile number.'),
        findsOneWidget,
      );

      await enter(tester, const Key('work-alternate-mobile'), '9829012321');
      await tapVisible(tester, const Key('work-send-alternate-otp'));
      expect(
        find.text('This is already your verified account number.'),
        findsOneWidget,
      );

      await enter(tester, const Key('work-alternate-mobile'), '9251893684');
      await tapVisible(tester, const Key('work-send-alternate-otp'));
      expect(
        find.text('OTP could not be sent. Check the number and try again.'),
        findsOneWidget,
      );
      await tapVisible(tester, const Key('work-send-alternate-otp'));
      expect(gateway.otpCalls, 2);

      await enter(tester, const Key('work-alternate-otp'), '000000');
      await tapVisible(tester, const Key('work-verify-alternate'));
      expect(
        find.text('Enter the 6-digit OTP sent to the alternate number.'),
        findsOneWidget,
      );
      await enter(tester, const Key('work-alternate-otp'), '123456');
      await tapVisible(tester, const Key('work-verify-alternate'));
      expect(work.alternateVerified, isTrue);
      await tapVisible(tester, const Key('work-continue-proof'));
      expect(find.byKey(const Key('work-proof-screen')), findsOneWidget);
    },
  );

  testWidgets(
    'unsupported profile request validates and creates no workspace',
    (tester) async {
      final (_, work) = await mount(tester, route: '/app/work/choose');
      await tapVisible(tester, const Key('work-profile-not-shown'));
      await tapVisible(tester, const Key('work-send-profile-request'));
      expect(find.text('Describe the work profile you need.'), findsOneWidget);

      await enter(
        tester,
        const Key('work-request-profile-name'),
        'Community library operator',
      );
      await tapVisible(tester, const Key('work-request-family'));
      await tester.tap(find.text('Other').last);
      await tester.pumpAndSettle();
      await enter(tester, const Key('work-request-area'), 'Jodhpur');
      await tapVisible(tester, const Key('work-send-profile-request'));

      expect(work.unsupportedRequestSent, isTrue);
      expect(work.activeWorkspace, isNull);
      expect(find.textContaining('No workspace was created'), findsOneWidget);
    },
  );

  testWidgets(
    'proof and submission failures preserve fields then submit exactly once',
    (tester) async {
      final gateway = ReviewWorkGateway()..failProof = true;
      final work = WorkSession(gateway: gateway)
        ..selectFamily('products-trade')
        ..selectProfile('retailer-grocery');
      await mount(tester, route: '/app/work/proof', workSession: work);

      await tapVisible(tester, const Key('work-details-continue'));
      expect(find.text('Enter the work or business name.'), findsOneWidget);
      await enter(tester, const Key('work-name'), 'Mahadev Fresh Mart');
      await enter(tester, const Key('work-area'), 'Jodhpur');
      await enter(tester, const Key('work-activity'), 'Grocery retail');
      await tapVisible(tester, const Key('work-details-continue'));

      await tapVisible(tester, const Key('work-add-proof-shop-front'));
      await tapVisible(tester, const Key('work-proof-source-upload'));
      expect(
        find.text(
          'Proof was not added. Choose the same file or source and retry.',
        ),
        findsOneWidget,
      );
      await tapVisible(tester, const Key('work-proof-source-upload'));
      await addProof(tester, 'owner-authority');
      await tapVisible(tester, const Key('work-proof-review'));

      await tapVisible(tester, const Key('work-submit-profile'));
      expect(
        find.text('Confirm the declaration before submission.'),
        findsOneWidget,
      );
      await tapVisible(tester, const Key('work-declaration'));
      gateway.failSubmission = true;
      await tapVisible(tester, const Key('work-submit-profile'));
      expect(
        find.text(
          'Work profile was not submitted. Your details and proof remain saved.',
        ),
        findsOneWidget,
      );
      await tapVisible(tester, const Key('work-submit-profile'));
      expect(find.byKey(const Key('work-status-screen')), findsOneWidget);
      expect(gateway.submissionCalls, 2);

      final submittedAgain = await work.submitProfile();
      expect(submittedAgain, isTrue);
      expect(gateway.submissionCalls, 2);
    },
  );

  testWidgets(
    'GST and review failures keep one case then reach approved workspace',
    (tester) async {
      final gateway = ReviewWorkGateway()
        ..failGst = true
        ..failReview = true;
      final work = WorkSession(gateway: gateway)
        ..selectFamily('products-trade')
        ..selectProfile('retailer-grocery')
        ..saveDetails(
          name: 'Mahadev Fresh Mart',
          area: 'Jodhpur',
          activity: 'Grocery retail',
        );
      work
        ..reviewCaseId = 'WP-240701'
        ..reviewStage = WorkReviewStage.gstPending;
      await mount(tester, route: '/app/work/status', workSession: work);

      await tapVisible(tester, const Key('work-add-gst'));
      await enter(tester, const Key('work-gstin'), 'INVALID');
      await tapVisible(tester, const Key('work-submit-gst'));
      expect(find.text('Enter a valid 15-character GSTIN.'), findsOneWidget);
      await enter(tester, const Key('work-gstin'), '22AAAAA0000A1Z5');
      await tapVisible(tester, const Key('work-submit-gst'));
      expect(
        find.text('Attach the GST certificate before submission.'),
        findsOneWidget,
      );
      await tapVisible(tester, const Key('work-attach-gst'));
      await tapVisible(tester, const Key('work-submit-gst'));
      expect(
        find.text('GST proof was not submitted. Your review remains active.'),
        findsOneWidget,
      );
      await tapVisible(tester, const Key('work-submit-gst'));
      expect(gateway.gstCalls, 2);

      await tapVisible(tester, const Key('work-check-review'));
      expect(
        find.text(
          'Review update is unavailable. No duplicate request was created.',
        ),
        findsOneWidget,
      );
      await tapVisible(tester, const Key('work-check-review'));
      expect(find.byKey(const Key('workspace-ready-screen')), findsOneWidget);
      expect(gateway.reviewCalls, 2);
      expect(work.activeWorkspace?.id, isNotNull);
    },
  );

  testWidgets(
    'retailer setup rejects incomplete inputs and exact failure retry goes live',
    (tester) async {
      final gateway = ReviewWorkGateway()..failSetup = true;
      final work = WorkSession(gateway: gateway)..seedVerifiedWorkspace();
      await mount(tester, route: '/app/work/ready', workSession: work);

      await tapVisible(tester, const Key('work-set-up-shop'));
      await tapVisible(tester, const Key('retailer-finish-setup'));
      expect(
        find.text('Add at least one product from the verified catalogue.'),
        findsOneWidget,
      );

      await tapVisible(tester, const Key('retailer-add-catalog-product'));
      await enter(tester, const Key('retailer-product-quantity'), '10');
      await enter(tester, const Key('retailer-product-buy-price'), '60');
      await enter(tester, const Key('retailer-product-sell-price'), '55');
      await tapVisible(tester, const Key('retailer-home-delivery'));
      await tapVisible(tester, const Key('retailer-finish-setup'));
      expect(
        find.textContaining('selling price above the purchase price'),
        findsOneWidget,
      );

      await enter(tester, const Key('retailer-product-sell-price'), '70');
      await tapVisible(tester, const Key('retailer-finish-setup'));
      expect(
        find.textContaining('Shop setup was not completed'),
        findsOneWidget,
      );
      expect(work.reviewStage, WorkReviewStage.setup);
      await tapVisible(tester, const Key('retailer-finish-setup'));
      expect(work.reviewStage, WorkReviewStage.live);
      expect(gateway.setupCalls, 2);

      final repeated = await work.finishRetailerSetup();
      expect(repeated, isTrue);
      expect(gateway.setupCalls, 2);
    },
  );

  testWidgets('single and multiple workspaces remain inside My Work', (
    tester,
  ) async {
    final work = WorkSession()..seedMultipleWorkspaces();
    await mount(tester, route: '/app/work/my-work', workSession: work);

    expect(find.text('Mahadev Fresh Mart'), findsWidgets);
    await tapVisible(tester, const Key('my-work-other-list'));
    expect(find.byKey(const Key('my-work-other-list')), findsOneWidget);
    expect(find.text('Creator Work'), findsOneWidget);
    await tapVisible(tester, const Key('my-work-add-another'));
    expect(find.byKey(const Key('work-choose-screen')), findsOneWidget);
    expect(work.activeWorkspace?.name, 'Mahadev Fresh Mart');
  });

  testWidgets('status Chat returns to the exact review screen', (tester) async {
    final work = WorkSession()
      ..selectFamily('products-trade')
      ..selectProfile('retailer-grocery')
      ..reviewCaseId = 'WP-240701'
      ..reviewStage = WorkReviewStage.gstPending;
    await mount(tester, route: '/app/work/status', workSession: work);

    await tapVisible(tester, const Key('work-status-open-chat'));
    expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);
    await tapVisible(tester, const Key('chat-back'));
    expect(find.byKey(const Key('work-status-screen')), findsOneWidget);
  });

  testWidgets('Work remains usable on compact width with larger text', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.35;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await mount(tester, route: '/app/work/earn', size: const Size(360, 800));
    for (final key in const [
      Key('work-refresh-feed'),
      Key('work-search'),
      Key('work-filter-forYou'),
      Key('work-dock-mool'),
      Key('work-dock-earn'),
      Key('work-dock-my-work'),
      Key('work-dock-chat'),
    ]) {
      final finder = find.byKey(key);
      if (finder.evaluate().isEmpty) {
        final vertical = find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              {
                AxisDirection.down,
                AxisDirection.up,
              }.contains(widget.axisDirection),
        );
        expect(vertical, findsWidgets, reason: 'No scrollable for $key');
        await tester.drag(vertical.last, const Offset(0, 900));
        await tester.pumpAndSettle();
        for (
          var attempt = 0;
          attempt < 12 && finder.evaluate().isEmpty;
          attempt += 1
        ) {
          await tester.drag(vertical.last, const Offset(0, -220));
          await tester.pumpAndSettle();
        }
      }
      expect(finder, findsOneWidget);
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      final size = tester.getSize(finder);
      expect(size.width, greaterThanOrEqualTo(44), reason: '$key width');
      expect(size.height, greaterThanOrEqualTo(44), reason: '$key height');
    }
    await tapVisible(tester, const Key('work-dock-my-work'));
    expect(find.byKey(const Key('my-work-screen')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
