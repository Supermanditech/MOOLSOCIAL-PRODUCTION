import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
    session
      ..accountIdentity = const AuthenticatedAccountIdentity(
        displayName: 'Asha Sharma',
        emailAddress: 'asha@example.com',
        phoneNumber: '+91 98290 12321',
        providerAccountLabel: 'asha@example.com',
        signInMethods: ['Google', 'Phone'],
      )
      ..socialAuthProvider = SocialAuthProvider.google;
    return session;
  }

  void confirmWorkspaceContacts(WorkSession work) {
    work.hydrateAccountSnapshot(
      const WorkAccountSnapshot(
        displayName: 'Asha Sharma',
        email: 'asha@example.com',
        mobile: '+91 98290 12321',
        providerLabel: 'Google',
        providerAccount: 'asha@example.com',
        emailConfirmed: true,
        mobileConfirmed: true,
      ),
    );
  }

  Future<(JourneySession, WorkSession)> mount(
    WidgetTester tester, {
    required String route,
    JourneySession? journeySession,
    WorkSession? workSession,
    Size size = const Size(412, 915),
  }) async {
    await tester.binding.setSurfaceSize(size);
    final journey = journeySession ?? await readyJourney();
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
    await tapVisible(tester, const Key('work-profile-retailer-grocery'));
    await tapVisible(tester, const Key('work-profile-choose-retailer-grocery'));
    await tapVisible(tester, const Key('work-requirements-ready'));
    await tapVisible(tester, const Key('work-contact-email-send-otp'));
    await enter(tester, const Key('work-contact-email-otp'), '123456');
    await tapVisible(tester, const Key('work-contact-email-confirm-otp'));
    await tapVisible(tester, const Key('work-contact-continue'));
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

      await tapVisible(
        tester,
        const Key('work-opportunity-quick-delivery-biker'),
      );
      expect(find.byKey(const Key('work-opportunity-screen')), findsOneWidget);
      await tapVisible(tester, const Key('work-detail-payment'));
      expect(
        find.text('Up to ₹19,500 monthly for 30 completed shifts'),
        findsWidgets,
      );

      await tapVisible(tester, const Key('work-apply-opportunity'));
      expect(find.byKey(const Key('work-choose-screen')), findsOneWidget);
      expect(work.selectedOpportunity?.id, 'quick-delivery-biker');

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
      await addProof(tester, 'payout-bank-account');
      await tapVisible(tester, const Key('work-proof-review'));
      await tapVisible(tester, const Key('work-declaration'));
      await tapVisible(tester, const Key('work-submit-profile'));

      expect(
        find.byKey(const Key('work-inline-review-status')),
        findsOneWidget,
      );
      expect(work.reviewCaseId, isNotNull);
      await tester.pump(const Duration(seconds: 31));
      await tester.pumpAndSettle();
      expect(work.activeWorkspace?.verified, isTrue);
      expect(find.text('Workspace approved'), findsNothing);

      expect(find.byKey(const Key('work-workspace-dashboard')), findsOneWidget);
      expect(work.activeWorkspace?.verified, isTrue);
      await tapVisible(tester, const Key('work-dashboard-priority-action'));
      await tapVisible(tester, const Key('retailer-add-catalog-product'));
      await enter(tester, const Key('retailer-product-quantity'), '24');
      await enter(tester, const Key('retailer-product-buy-price'), '48');
      await enter(tester, const Key('retailer-product-sell-price'), '55');
      await tapVisible(tester, const Key('retailer-home-delivery'));
      await tapVisible(tester, const Key('retailer-finish-setup'));

      expect(work.reviewStage, WorkReviewStage.live);
      expect(work.retailerSetupSaved, isTrue);
      expect(find.text('Shop ready'), findsOneWidget);
      final gateway = work.gateway as ReviewWorkGateway;
      expect(gateway.submissionCalls, 1);
      expect(gateway.reviewCalls, 1);
      expect(gateway.setupCalls, 1);
    },
  );

  testWidgets(
    'Apply Now enters Workspace onboarding with the exact opportunity',
    (tester) async {
      final gateway = ReviewWorkGateway();
      final work = WorkSession(gateway: gateway)..seedVerifiedWorkspace();
      await mount(
        tester,
        route: '/app/work/opportunity/quick-delivery-biker',
        workSession: work,
      );

      await tapVisible(tester, const Key('work-apply-opportunity'));
      expect(find.byKey(const Key('work-choose-screen')), findsOneWidget);
      expect(work.selectedOpportunity?.id, 'quick-delivery-biker');
      expect(work.applicationId, isNull);
      expect(gateway.applicationCalls, 0);
    },
  );

  testWidgets('feed filters, search empty and failed refresh recover safely', (
    tester,
  ) async {
    final gateway = ReviewWorkGateway()..failFeed = true;
    final work = WorkSession(gateway: gateway);
    await mount(tester, route: '/app/work/earn', workSession: work);

    await tapVisible(tester, const Key('work-filter-button'));
    await tapVisible(tester, const Key('work-filter-jobs'));
    await tapVisible(tester, const Key('work-filter-show-results'));
    expect(find.text('Quick Delivery Biker'), findsOneWidget);
    expect(find.text('Social Content Creator'), findsNothing);

    await tapVisible(tester, const Key('work-search'));
    await enter(tester, const Key('work-search'), 'no funded work');
    expect(find.byKey(const Key('work-empty')), findsOneWidget);
    await tapVisible(tester, const Key('work-empty-action'));
    expect(work.filter, WorkFeedFilter.forYou);
    expect(work.searchQuery, isEmpty);

    final list = find.byKey(const Key('work-earn-screen'));
    await tester.drag(list, const Offset(0, 320));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Work could not be refreshed. Check your connection and try again.',
      ),
      findsOneWidget,
    );
    final refresh = tester.widget<RefreshIndicator>(
      find.byType(RefreshIndicator),
    );
    final refreshFuture = refresh.onRefresh();
    await tester.pump(const Duration(milliseconds: 30));
    await refreshFuture;
    await tester.pump();
    expect(find.text('Work opportunities refreshed.'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1300));
    expect(find.text('Work opportunities refreshed.'), findsNothing);
  });

  testWidgets(
    'alternate work number handles invalid, gateway failure and exact OTP',
    (tester) async {
      final gateway = ReviewWorkGateway()..failOtp = true;
      final work = WorkSession(gateway: gateway);
      await mount(
        tester,
        route: '/app/work/workspace/choose',
        workSession: work,
      );

      await tapVisible(tester, const Key('work-profile-retailer-grocery'));
      await tapVisible(
        tester,
        const Key('work-profile-choose-retailer-grocery'),
      );
      await tapVisible(tester, const Key('work-requirements-ready'));
      await enter(tester, const Key('work-alternate-contact-field'), '123');
      await tapVisible(tester, const Key('work-alternate-contact-send-otp'));
      expect(
        find.text('Enter a valid 10-digit alternate mobile number.'),
        findsOneWidget,
      );

      await enter(
        tester,
        const Key('work-alternate-contact-field'),
        '9829012321',
      );
      await tapVisible(tester, const Key('work-alternate-contact-send-otp'));
      expect(
        find.text('This is already the number customers can reach you on.'),
        findsOneWidget,
      );

      await enter(
        tester,
        const Key('work-alternate-contact-field'),
        '9251893684',
      );
      await tapVisible(tester, const Key('work-alternate-contact-send-otp'));
      expect(
        find.text('OTP could not be sent. Check the number and try again.'),
        findsOneWidget,
      );
      await tapVisible(tester, const Key('work-alternate-contact-send-otp'));
      expect(gateway.otpCalls, 2);

      await enter(tester, const Key('work-alternate-contact-otp'), '000000');
      await tapVisible(tester, const Key('work-alternate-contact-confirm-otp'));
      expect(
        find.text('Enter the 6-digit OTP sent to this contact.'),
        findsOneWidget,
      );
      await enter(tester, const Key('work-alternate-contact-otp'), '123456');
      await tapVisible(tester, const Key('work-alternate-contact-confirm-otp'));
      expect(work.alternateVerified, isTrue);
      await tapVisible(tester, const Key('work-contact-email-send-otp'));
      await enter(tester, const Key('work-contact-email-otp'), '123456');
      await tapVisible(tester, const Key('work-contact-email-confirm-otp'));
      await tapVisible(tester, const Key('work-contact-continue'));
      expect(find.byKey(const Key('work-proof-screen')), findsOneWidget);
    },
  );

  testWidgets(
    'Google email is shown alone and missing phone is confirmed in place',
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
      await journey.start();
      journey
        ..accountIdentity = const AuthenticatedAccountIdentity(
          displayName: 'Asha Sharma',
          emailAddress: 'asha@example.com',
          providerAccountLabel: 'asha@example.com',
          signInMethods: ['Google'],
        )
        ..socialAuthProvider = SocialAuthProvider.google;
      final work = WorkSession()
        ..selectFamily('products-trade')
        ..selectProfile('retailer-grocery');

      await mount(
        tester,
        route: '/app/work/workspace/contact',
        journeySession: journey,
        workSession: work,
      );

      expect(find.byKey(const Key('workspace-account-setup-hero')), findsOne);
      expect(find.text('Signed in with Google'), findsOne);
      expect(find.text('asha@example.com'), findsWidgets);
      expect(find.textContaining('Facebook'), findsNothing);
      expect(find.textContaining('YouTube account'), findsNothing);
      expect(work.contactEmailVerified, isFalse);
      expect(work.primaryMobileVerified, isFalse);

      await enter(
        tester,
        const Key('work-primary-contact-field'),
        '9829012321',
      );
      await tapVisible(tester, const Key('work-primary-contact-send-otp'));
      await enter(tester, const Key('work-primary-contact-otp'), '123456');
      await tapVisible(tester, const Key('work-primary-contact-confirm-otp'));

      expect(work.primaryMobileVerified, isTrue);
      await tapVisible(tester, const Key('work-contact-email-send-otp'));
      await enter(tester, const Key('work-contact-email-otp'), '123456');
      await tapVisible(tester, const Key('work-contact-email-confirm-otp'));
      expect(work.contactEmailVerified, isTrue);
      expect(work.workspaceContactsReady, isTrue);
      await tapVisible(tester, const Key('work-contact-continue'));
      expect(find.byKey(const Key('work-proof-screen')), findsOneWidget);
    },
  );

  testWidgets(
    'unsupported profile request validates and creates no workspace',
    (tester) async {
      final (_, work) = await mount(
        tester,
        route: '/app/work/workspace/choose',
      );
      final missingRole = find.byKey(const Key('work-profile-not-shown'));
      await tester.scrollUntilVisible(
        missingRole,
        260,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('work-choose-screen')),
              matching: find.byType(Scrollable),
            )
            .first,
        maxScrolls: 40,
      );
      await tapVisible(tester, const Key('work-profile-not-shown'));
      await tapVisible(tester, const Key('work-send-profile-request'));
      expect(
        find.text('Enter your business, profession or service.'),
        findsOneWidget,
      );

      await enter(
        tester,
        const Key('work-request-profile-name'),
        'Community library operator',
      );
      await tapVisible(tester, const Key('work-request-family'));
      await tester.tap(find.text('Other').last);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-request-other-activity')),
        findsOneWidget,
      );
      await tapVisible(tester, const Key('work-send-profile-request'));
      expect(
        find.text('Enter the activity you want to offer.'),
        findsOneWidget,
      );
      await enter(
        tester,
        const Key('work-request-other-activity'),
        'Community library and reading services',
      );
      await enter(tester, const Key('work-request-area'), 'Jodhpur');
      await tapVisible(tester, const Key('work-send-profile-request'));

      expect(work.unsupportedRequestSent, isTrue);
      expect(
        work.unsupportedOtherActivity,
        'Community library and reading services',
      );
      expect(work.activeWorkspace, isNull);
      expect(
        find.textContaining('MoolSocial will review your request'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'selected role opens its complete document requirements and Back restores roles',
    (tester) async {
      await mount(tester, route: '/app/work/workspace/choose');

      final profileLabels = workProfiles
          .map((profile) => profile.label)
          .toList();
      expect(profileLabels, isNot(contains('Local Service Provider')));
      expect(profileLabels, isNot(contains('Ride / Delivery Captain')));
      expect(
        profileLabels,
        containsAll(const [
          'Bike Travel Provider',
          'Auto Travel Provider',
          'Cab Travel Provider',
          'Bus Travel Provider',
          'Quick Delivery Biker',
          'Wholesale Fleet Delivery',
          'Bulk Delivery Fleet',
        ]),
      );
      expect(
        workProfiles
            .where(
              (profile) => const {
                'Travel Partners',
                'Delivery & Logistics',
              }.contains(profile.familyLabel),
            )
            .map((profile) => profile.familyLabel)
            .toSet(),
        const {'Travel Partners', 'Delivery & Logistics'},
      );

      await tapVisible(tester, const Key('work-profile-retailer-grocery'));
      expect(find.byKey(const Key('work-requirements-screen')), findsNothing);
      expect(
        find.byKey(const Key('workspace-benefits-retailer-grocery')),
        findsOneWidget,
      );
      await tapVisible(
        tester,
        const Key('work-profile-choose-retailer-grocery'),
      );
      expect(find.byKey(const Key('work-requirements-screen')), findsOneWidget);
      expect(find.text('Account owner identity'), findsOneWidget);
      expect(find.text('Shop address document'), findsOneWidget);
      expect(
        find.textContaining(
          'You can submit your application before adding documents',
        ),
        findsOneWidget,
      );
      final gstDocument = workProfiles
          .singleWhere((profile) => profile.id == 'retailer-grocery')
          .verificationDocuments
          .singleWhere(
            (document) => document.title == 'GST registration certificate',
          );
      expect(gstDocument.importance, WorkDocumentImportance.ifApplicable);
      await tester.scrollUntilVisible(
        find.text('Payout bank account proof'),
        240,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('work-requirements-screen')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Payout bank account proof'), findsOneWidget);
      expect(
        find.textContaining('cancelled cheque or recent bank statement PDF'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('GST registration certificate'),
        240,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('work-requirements-screen')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(find.text('GST registration certificate'), findsOneWidget);
      expect(
        find.text(
          'Required when GST registration applies to this Workspace. '
          'Applicability is confirmed during verification.',
        ),
        findsOneWidget,
      );
      expect(find.text('When applicable'), findsWidgets);
      expect(find.textContaining('GST certificate is optional'), findsNothing);
      expect(find.byKey(const Key('work-requirements-ready')), findsOneWidget);

      await tapVisible(tester, const Key('work-back'));
      expect(find.byKey(const Key('work-choose-screen')), findsOneWidget);
      expect(find.byKey(const Key('work-requirements-screen')), findsNothing);
    },
  );

  testWidgets(
    'Workspace submits without documents and keeps review status in the same screen',
    (tester) async {
      final gateway = ReviewWorkGateway();
      final work = WorkSession(gateway: gateway)
        ..selectFamily('products-trade')
        ..selectProfile('retailer-grocery');
      confirmWorkspaceContacts(work);
      await mount(
        tester,
        route: '/app/work/workspace/proof',
        workSession: work,
      );

      await enter(tester, const Key('work-name'), 'Mahadev Fresh Mart');
      await enter(tester, const Key('work-area'), 'Jodhpur');
      await enter(tester, const Key('work-activity'), 'Grocery retail');
      expect(find.byKey(const Key('work-workspace-progress')), findsOneWidget);
      expect(find.text('Verified'), findsNothing);
      expect(find.byKey(const Key('work-global-chat')), findsNothing);
      expect(find.byKey(const Key('work-help')), findsNothing);
      await tapVisible(tester, const Key('work-details-continue'));
      expect(find.text('Documents'), findsWidgets);
      expect(find.byKey(const Key('work-proof-back-details')), findsNothing);
      expect(find.text('Add document'), findsWidgets);
      await tapVisible(tester, const Key('work-proof-review'));
      await tapVisible(tester, const Key('work-declaration'));
      await tapVisible(tester, const Key('work-submit-profile'));

      expect(
        find.byKey(const Key('work-inline-review-status')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('work-status-screen')), findsNothing);
      expect(find.text('Application received'), findsOneWidget);
      expect(gateway.lastSubmission?.proofReferences, isEmpty);
      expect(
        find.byKey(const Key('work-inline-update-documents')),
        findsNothing,
      );
      expect(work.submittedProfile, same(gateway.lastSubmission));
      expect(gateway.lastSubmission?.primaryMobile, '9829012321');
      expect(gateway.lastSubmission?.email, 'asha@example.com');
      expect(gateway.submissionCalls, 1);
    },
  );

  testWidgets(
    'rejected Workspace explains the reason inside Complete your Workspace',
    (tester) async {
      final work = WorkSession()
        ..selectFamily('products-trade')
        ..selectProfile('retailer-grocery')
        ..reviewCaseId = 'WP-REVIEW-92'
        ..remoteReviewStatus = WorkRemoteReviewStatus.rejected
        ..reviewReason =
            'The shop address could not be confirmed. Add a clearer address document or update the operating address.';
      confirmWorkspaceContacts(work);
      await mount(
        tester,
        route: '/app/work/workspace/proof',
        workSession: work,
      );

      expect(
        find.byKey(const Key('work-inline-review-status')),
        findsOneWidget,
      );
      expect(find.text('Application not approved'), findsOneWidget);
      expect(
        find.textContaining('shop address could not be confirmed'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('work-status-screen')), findsNothing);
      expect(find.byKey(const Key('work-inline-review-update')), findsNothing);
      expect(
        find.byKey(const Key('work-inline-review-support')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'proof and submission failures preserve fields then submit exactly once',
    (tester) async {
      final gateway = ReviewWorkGateway()..failProof = true;
      final work = WorkSession(gateway: gateway)
        ..selectFamily('products-trade')
        ..selectProfile('retailer-grocery');
      confirmWorkspaceContacts(work);
      await mount(
        tester,
        route: '/app/work/workspace/proof',
        workSession: work,
      );

      await tapVisible(tester, const Key('work-details-continue'));
      expect(
        find.text('Enter the business name shown on its PAN card.'),
        findsOneWidget,
      );
      await enter(tester, const Key('work-name'), 'Mahadev Fresh Mart');
      await enter(tester, const Key('work-area'), 'Jodhpur');
      await enter(tester, const Key('work-activity'), 'Grocery retail');
      await tapVisible(tester, const Key('work-details-continue'));

      await tapVisible(tester, const Key('work-add-proof-shop-front'));
      await tapVisible(tester, const Key('work-proof-source-upload'));
      expect(
        find.text(
          'Document not added. Choose the same file or another option and try again.',
        ),
        findsOneWidget,
      );
      await tapVisible(tester, const Key('work-proof-source-upload'));
      await addProof(tester, 'owner-authority');
      await addProof(tester, 'payout-bank-account');
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
          'Workspace profile was not submitted. Your details and documents remain saved.',
        ),
        findsOneWidget,
      );
      await tapVisible(tester, const Key('work-submit-profile'));
      expect(
        find.byKey(const Key('work-inline-review-status')),
        findsOneWidget,
      );
      expect(gateway.submissionCalls, 2);

      final submittedAgain = await work.submitProfile();
      expect(submittedAgain, isTrue);
      expect(gateway.submissionCalls, 2);
    },
  );

  testWidgets(
    'document and automatic review failures preserve one case with exact retry',
    (tester) async {
      final gateway = ReviewWorkGateway()
        ..failProof = true
        ..failReview = true;
      final work = WorkSession(gateway: gateway)
        ..selectFamily('products-trade')
        ..selectProfile('retailer-grocery')
        ..saveDetails(
          name: 'Mahadev Fresh Mart',
          area: 'Jodhpur',
          activity: 'Grocery retail',
        );
      confirmWorkspaceContacts(work);
      await mount(
        tester,
        route: '/app/work/workspace/proof',
        workSession: work,
      );
      await tapVisible(tester, const Key('work-details-continue'));
      await tapVisible(tester, const Key('work-add-proof-gst'));
      await tapVisible(tester, const Key('work-proof-source-upload'));
      expect(
        find.text(
          'Document not added. Choose the same file or another option and try again.',
        ),
        findsOneWidget,
      );
      await tapVisible(tester, const Key('work-proof-source-upload'));
      expect(work.addedProofs['gst'], isNotNull);
      await tapVisible(tester, const Key('work-proof-review'));
      await tapVisible(tester, const Key('work-declaration'));
      await tapVisible(tester, const Key('work-submit-profile'));
      final caseId = work.reviewCaseId;
      await tester.pump(const Duration(seconds: 31));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Review update is unavailable. No duplicate request was created.',
        ),
        findsOneWidget,
      );
      await tapVisible(tester, const Key('work-inline-review-check'));
      expect(find.byKey(const Key('work-workspace-dashboard')), findsOneWidget);
      expect(gateway.reviewCalls, 2);
      expect(gateway.submissionCalls, 1);
      expect(work.reviewCaseId, caseId);
      expect(work.activeWorkspace?.id, isNotNull);
    },
  );

  testWidgets(
    'retailer setup rejects incomplete inputs and exact failure retry goes live',
    (tester) async {
      final gateway = ReviewWorkGateway()..failSetup = true;
      final work = WorkSession(gateway: gateway)..seedVerifiedWorkspace();
      await mount(tester, route: '/app/work/ready', workSession: work);

      expect(find.byKey(const Key('work-workspace-dashboard')), findsOneWidget);
      await tapVisible(tester, const Key('work-dashboard-priority-action'));
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

  testWidgets('existing Workspaces remain inside the direct chooser', (
    tester,
  ) async {
    final work = WorkSession()..seedMultipleWorkspaces();
    await mount(tester, route: '/app/work/workspace/choose', workSession: work);

    expect(find.byKey(const Key('my-work-screen')), findsNothing);
    expect(find.byKey(const Key('work-choose-screen')), findsOneWidget);
    expect(find.byKey(const Key('workspace-existing-summary')), findsOneWidget);
    expect(find.text('Mahadev Fresh Mart'), findsOneWidget);
    final chooserScroll = find
        .descendant(
          of: find.byKey(const Key('work-choose-screen')),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.byKey(const Key('workspace-other-WK-510002')),
      180,
      scrollable: chooserScroll,
    );
    expect(find.byKey(const Key('workspace-other-list')), findsOneWidget);
    expect(find.textContaining('Creator Work'), findsOneWidget);

    await tapVisible(tester, const Key('workspace-settlement'));
    expect(find.byKey(const Key('my-work-settlement-sheet')), findsOneWidget);
    await tapVisible(tester, const Key('my-work-settlement-close'));
    await tapVisible(tester, const Key('workspace-settlement'));
    await tapVisible(tester, const Key('my-work-settlement-open-workspace'));
    expect(find.byKey(const Key('retailer-home-screen')), findsOneWidget);
    work.startAnotherWork();
    tester.element(find.byType(Scaffold).first).go('/app/work/my-work');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('work-workspace-dashboard')), findsOneWidget);
    expect(work.activeWorkspace?.name, 'Mahadev Fresh Mart');
  });

  testWidgets('status Chat returns to the exact review screen', (tester) async {
    final work = WorkSession()
      ..selectFamily('products-trade')
      ..selectProfile('retailer-grocery')
      ..reviewCaseId = 'WP-240701'
      ..reviewStage = WorkReviewStage.gstPending
      ..remoteReviewStatus = WorkRemoteReviewStatus.rejected
      ..reviewReason = 'The submitted address could not be confirmed.';
    await mount(tester, route: '/app/work/status', workSession: work);

    expect(find.byKey(const Key('work-global-chat')), findsNothing);
    expect(find.byKey(const Key('work-help')), findsNothing);
    await tapVisible(tester, const Key('work-inline-review-support'));
    expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);
    expect(find.byKey(const Key('chat-back')), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-inline-review-status')), findsOneWidget);
    expect(work.reviewCaseId, 'WP-240701');
    expect(work.remoteReviewStatus, WorkRemoteReviewStatus.rejected);
  });

  testWidgets(
    'review step animates and offers direct detail and document corrections',
    (tester) async {
      final work = WorkSession()
        ..selectFamily('products-trade')
        ..selectProfile('retailer-grocery')
        ..saveDetails(
          name: 'Mahadev Fresh Mart',
          area: 'Sardarpura, Jodhpur',
          activity: 'Grocery retail',
        );
      confirmWorkspaceContacts(work);
      await mount(
        tester,
        route: '/app/work/workspace/proof',
        workSession: work,
      );

      await tapVisible(tester, const Key('work-details-continue'));
      await addProof(tester, 'shop-front');
      await tapVisible(tester, const Key('work-proof-review'));
      expect(find.byKey(const Key('work-review-corrections')), findsOneWidget);
      expect(find.text('Shop address document'), findsWidgets);

      await tapVisible(tester, const Key('work-declaration'));
      expect(work.declarationAccepted, isTrue);
      await tapVisible(tester, const Key('work-review-edit-details'));
      expect(work.declarationAccepted, isFalse);
      await enter(tester, const Key('work-name'), 'Mahadev Daily Store');
      await tapVisible(tester, const Key('work-details-continue'));
      expect(find.text('Mahadev Daily Store'), findsOneWidget);

      await tapVisible(tester, const Key('work-review-edit-documents'));
      expect(
        find.byKey(const Key('work-remove-proof-shop-front')),
        findsOneWidget,
      );
      await tapVisible(tester, const Key('work-back'));
      expect(find.byKey(const Key('work-review-corrections')), findsOneWidget);
      await tapVisible(tester, const Key('work-review-edit-contact'));
      await enter(tester, const Key('work-person-name'), 'Asha Kumar');
      await tapVisible(tester, const Key('work-contact-continue'));
      expect(find.byKey(const Key('work-review-corrections')), findsOneWidget);
      expect(find.text('Asha Kumar'), findsOneWidget);
      expect(work.declarationAccepted, isFalse);
      expect(work.workName, 'Mahadev Daily Store');
      expect(find.byKey(const Key('work-global-chat')), findsNothing);
      expect(find.byKey(const Key('work-help')), findsNothing);
    },
  );

  testWidgets('clarification corrections update the existing review reference', (
    tester,
  ) async {
    final gateway = ReviewWorkGateway()
      ..reviewResultStatus = WorkRemoteReviewStatus.pending
      ..reviewResultReason =
          'Please confirm the shop entrance and upload a clearer address document.';
    final work = WorkSession(gateway: gateway)
      ..selectFamily('products-trade')
      ..selectProfile('retailer-grocery')
      ..saveDetails(
        name: 'Mahadev Fresh Mart',
        area: 'Sardarpura, Jodhpur',
        activity: 'Grocery retail',
      )
      ..reviewCaseId = 'WP-CLARIFY-101'
      ..reviewStage = WorkReviewStage.gstPending
      ..remoteReviewStatus = WorkRemoteReviewStatus.pending
      ..reviewReason =
          'Please confirm the shop entrance and upload a clearer address document.';
    confirmWorkspaceContacts(work);
    await mount(tester, route: '/app/work/workspace/proof', workSession: work);

    expect(find.text('More information needed'), findsOneWidget);
    expect(
      find.textContaining('Please confirm the shop entrance'),
      findsOneWidget,
    );
    await tapVisible(tester, const Key('work-inline-update-details'));
    expect(
      find.byKey(const Key('work-correction-instruction')),
      findsOneWidget,
    );
    expect(
      find.textContaining('Please confirm the shop entrance'),
      findsOneWidget,
    );
    await enter(tester, const Key('work-area'), 'Ratanada, Jodhpur');
    await tapVisible(tester, const Key('work-details-continue'));
    await addProof(tester, 'shop-front');
    await tapVisible(tester, const Key('work-proof-review'));
    await tapVisible(tester, const Key('work-declaration'));
    await tapVisible(tester, const Key('work-submit-profile'));

    expect(gateway.correctionCalls, 1);
    expect(gateway.submissionCalls, 0);
    expect(work.reviewCaseId, 'WP-CLARIFY-101');
    expect(work.reviewCorrectionDraft, isFalse);
    expect(find.byKey(const Key('work-inline-review-status')), findsOneWidget);
  });

  testWidgets(
    'rejected Workspace retains its decision and cannot restart submission',
    (tester) async {
      final gateway = ReviewWorkGateway();
      final work = WorkSession(gateway: gateway)
        ..selectFamily('products-trade')
        ..selectProfile('retailer-grocery')
        ..saveDetails(
          name: 'Mahadev Fresh Mart',
          area: 'Sardarpura, Jodhpur',
          activity: 'Grocery retail',
        )
        ..reviewCaseId = 'WP-REJECTED-101'
        ..reviewStage = WorkReviewStage.gstPending
        ..remoteReviewStatus = WorkRemoteReviewStatus.rejected
        ..reviewReason = 'The submitted address could not be confirmed.';
      confirmWorkspaceContacts(work);
      await mount(
        tester,
        route: '/app/work/workspace/proof',
        workSession: work,
      );

      expect(find.text('Application not approved'), findsOneWidget);
      expect(
        find.text('The submitted address could not be confirmed.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('work-inline-review-update')), findsNothing);
      expect(find.byKey(const Key('work-inline-update-details')), findsNothing);
      expect(work.beginReviewCorrection(), isFalse);
      work.reviseRejectedProfile();
      await tester.pumpAndSettle();
      expect(work.reviewCaseId, 'WP-REJECTED-101');
      expect(
        find.text('The submitted address could not be confirmed.'),
        findsOneWidget,
      );
      expect(gateway.submissionCalls, 0);
      expect(gateway.correctionCalls, 0);
      expect(work.remoteReviewStatus, WorkRemoteReviewStatus.rejected);
      expect(
        find.byKey(const Key('work-inline-review-status')),
        findsOneWidget,
      );
    },
  );

  testWidgets('approved review opens the selected Workspace dashboard', (
    tester,
  ) async {
    final gateway = ReviewWorkGateway();
    final work = WorkSession(gateway: gateway)
      ..selectFamily('health')
      ..selectProfile('clinic')
      ..saveDetails(
        name: 'Asha Family Clinic',
        area: 'Jodhpur',
        activity: 'Consultations and follow-up',
      )
      ..reviewCaseId = 'WP-CLINIC-101'
      ..reviewStage = WorkReviewStage.gstPending
      ..remoteReviewStatus = WorkRemoteReviewStatus.pending;
    confirmWorkspaceContacts(work);
    await mount(tester, route: '/app/work/workspace/proof', workSession: work);

    expect(find.text('Workspace approved'), findsNothing);
    expect(find.byKey(const Key('work-inline-review-approved')), findsNothing);
    expect(find.byKey(const Key('work-workspace-dashboard')), findsOneWidget);
    expect(find.text('Your trusted care desk'), findsOneWidget);
    expect(find.textContaining('Clinic / Doctor'), findsWidgets);
    expect(find.textContaining('Set up my shop'), findsNothing);
    expect(find.text('View approved record'), findsOneWidget);
    await tapVisible(tester, const Key('work-dashboard-add-workspace'));
    expect(find.byKey(const Key('work-choose-screen')), findsOneWidget);
    expect(find.byKey(const Key('workspace-existing-summary')), findsOneWidget);
    await tapVisible(tester, const Key('work-back'));
    expect(find.byKey(const Key('work-workspace-dashboard')), findsOneWidget);
  });

  testWidgets(
    'restored live retailer opens operations without setup downgrade',
    (tester) async {
      final work = WorkSession()
        ..seedVerifiedWorkspace()
        ..reviewStage = WorkReviewStage.live
        ..remoteReviewStatus = WorkRemoteReviewStatus.live
        ..retailerSetupSaved = false;
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        workSession: work,
      );

      expect(find.byKey(const Key('work-store-activity-deck')), findsOneWidget);
      await tapVisible(tester, const Key('work-store-stock'));
      expect(
        find.byKey(const Key('work-dashboard-catalogue-screen')),
        findsOneWidget,
      );
      expect(find.text('What would you like to do?'), findsNothing);
      expect(work.reviewStage, WorkReviewStage.live);
    },
  );

  testWidgets('every approved profile receives a purposeful dashboard', (
    tester,
  ) async {
    const familySignal = <String, String>{
      'products-trade': 'Catalogue',
      'food-business': 'Menu',
      'health': 'Appointments',
      'services': 'Services',
      'travel': 'Trips and routes',
      'delivery': 'Assignments',
      'create-work': 'Opportunities',
    };
    for (final profile in workProfiles) {
      final work = WorkSession()
        ..selectFamily(profile.familyId)
        ..selectProfile(profile.id)
        ..saveDetails(
          name: '${profile.label} Workspace',
          area: 'Jodhpur',
          activity: profile.label,
        )
        ..reviewCaseId = 'WP-${profile.id}'
        ..workspaceId = 'WK-${profile.id}'
        ..reviewStage = WorkReviewStage.approved
        ..remoteReviewStatus = WorkRemoteReviewStatus.approved
        ..activeWorkspace = WorkWorkspace(
          id: 'WK-${profile.id}',
          name: '${profile.label} Workspace',
          profileLabel: profile.label,
          area: 'Jodhpur',
          verified: true,
        );
      confirmWorkspaceContacts(work);
      await mount(tester, route: '/app/work/my-work', workSession: work);

      expect(
        find.byKey(const Key('work-workspace-dashboard')),
        findsOneWidget,
        reason: profile.id,
      );
      final retailer = const {
        'retailer-grocery',
        'retailer-speciality',
      }.contains(profile.id);
      if (!retailer) {
        expect(
          find.textContaining(profile.label),
          findsWidgets,
          reason: profile.id,
        );
      }
      expect(
        find.text(retailer ? 'Stock' : familySignal[profile.familyId]!),
        findsOneWidget,
        reason: profile.id,
      );
      final accountState = find.byKey(
        const Key('work-dashboard-account-state'),
      );
      if (retailer) {
        expect(accountState, findsNothing, reason: profile.id);
        expect(
          find
                  .byKey(const Key('work-store-activity-deck'))
                  .evaluate()
                  .isNotEmpty ||
              find
                  .byKey(const Key('work-activity-setup'))
                  .evaluate()
                  .isNotEmpty,
          isTrue,
          reason: profile.id,
        );
        expect(
          find.byKey(const Key('work-dashboard-settings')),
          findsOneWidget,
          reason: profile.id,
        );
      } else {
        await tester.scrollUntilVisible(
          accountState,
          260,
          scrollable: find
              .descendant(
                of: find.byKey(const Key('work-workspace-dashboard')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(accountState, findsOneWidget, reason: profile.id);
      }
      expect(find.textContaining('Set up my shop'), findsNothing);
    }
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
      Key('work-search'),
      Key('work-filter-button'),
      Key('work-opportunity-apply-quick-delivery-biker'),
      Key('mool-compact-launcher'),
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
    expect(find.byKey(const Key('work-local-earn')), findsOneWidget);
    expect(find.byKey(const Key('work-local-workspace')), findsOneWidget);
    expect(find.byKey(const Key('mool-root-chat')), findsNothing);
    await tapVisible(tester, const Key('work-local-workspace'));
    expect(find.byKey(const Key('work-choose-screen')), findsOneWidget);
    expect(find.byKey(const Key('my-work-screen')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
