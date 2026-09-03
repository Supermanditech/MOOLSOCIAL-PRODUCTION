import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/work/work_models.dart';
import 'package:moolsocial/features/work/work_services.dart';
import 'package:moolsocial/features/work/work_session.dart';

void main() {
  const captureFounderEvidence = bool.fromEnvironment(
    'MOOL_CAPTURE_WORK_STORE_1_40',
  );
  Future<void> mount(
    WidgetTester tester, {
    required String route,
    required WorkSession work,
    double bottomInset = 44,
    Size viewport = const Size(360, 800),
    double textScale = 1.4,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = viewport;
    tester.view.viewPadding = FakeViewPadding(bottom: bottomInset);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
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
        phoneNumber: '+91 98290 12321',
        providerAccountLabel: 'asha@example.com',
        signInMethods: ['Google', 'Phone'],
      )
      ..socialAuthProvider = SocialAuthProvider.google;
    addTearDown(journey.dispose);
    addTearDown(work.dispose);
    await tester.pumpWidget(
      MoolSocialApp(
        session: journey,
        workSession: work,
        initialLocation: route,
      ),
    );
    await tester.pumpAndSettle();
  }

  void expectHeaderAndStickyAction(WidgetTester tester) {
    final titleFinder = find.byKey(const Key('work-page-title'));
    final subtitleFinder = find.byKey(const Key('work-page-subtitle'));
    expect(
      tester.widget<Text>(titleFinder).overflow,
      isIn([TextOverflow.clip, TextOverflow.ellipsis]),
    );
    expect(tester.widget<Text>(subtitleFinder).maxLines, 2);
    expect(tester.getRect(titleFinder).right, lessThanOrEqualTo(360));
    expect(tester.getRect(subtitleFinder).right, lessThanOrEqualTo(360));
    final sticky = find.byKey(const Key('work-sticky-action-bar'));
    final navigation = find.byKey(const Key('work-local-navigation'));
    expect(sticky, findsOneWidget);
    expect(navigation, findsOneWidget);
    expect(
      tester.getBottomRight(sticky).dy,
      lessThanOrEqualTo(tester.getTopRight(navigation).dy),
    );
  }

  void expectStoreNavigationOwnsProcurement(WidgetTester tester) {
    final storeNavigation = find.byKey(const Key('work-local-navigation'));
    final buyNavigation = find.byKey(
      const ValueKey('buy-local-destination-tabs'),
    );
    expect(storeNavigation, findsOneWidget);
    if (buyNavigation.evaluate().isNotEmpty) {
      expect(buyNavigation.hitTestable(), findsNothing);
      final storeRect = tester.getRect(storeNavigation);
      final buyRect = tester.getRect(buyNavigation);
      expect(storeRect.top, lessThanOrEqualTo(buyRect.bottom));
      expect(storeRect.bottom, greaterThanOrEqualTo(buyRect.top));
    }
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    final vertical = find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable &&
          (widget.axisDirection == AxisDirection.down ||
              widget.axisDirection == AxisDirection.up),
    );
    for (
      var attempt = 0;
      attempt < 12 && finder.evaluate().isEmpty;
      attempt++
    ) {
      await tester.drag(vertical.last, const Offset(0, -220));
      await tester.pumpAndSettle();
    }
    expect(finder, findsOneWidget);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  WorkSession selectedRetailer() => WorkSession()
    ..selectFamily('products-trade')
    ..selectProfile('retailer-grocery');

  WorkSession liveStore({ReviewWorkGateway? gateway}) =>
      WorkSession(gateway: gateway)
        ..seedVerifiedWorkspace()
        ..retailerSetupSaved = true
        ..reviewStage = WorkReviewStage.live
        ..workspaceStoreState = WorkspaceStoreState.open
        ..workspaceAcceptingOrders = true
        ..workspaceVisibleToCustomers = true
        ..workspaceLastUpdatedAt = DateTime(2026, 9, 3, 8, 30);

  void seedIncomingOrder(
    WorkSession work, {
    String stage = 'Confirmed',
    bool delivery = false,
  }) {
    work
      ..workspaceOrderCustomer = 'Rakesh · 98290 12345'
      ..workspaceOrderSource = 'App'
      ..workspaceOrderItems = 'Fortune Oil × 2 · Aashirvaad Atta × 1'
      ..workspaceOrderAmount = '1468'
      ..workspaceOrderStage = stage
      ..workspaceOrderPayment = 'Paid online'
      ..workspaceOrderFulfilment = delivery ? 'Mool delivery' : 'Pickup'
      ..workspaceOrderNeedsDelivery = delivery
      ..workspaceOrderAddress = '12 Market Road, Sardarpura';
  }

  testWidgets(
    'selected Workspace profile keeps contact clear of sticky Continue',
    (tester) async {
      final work = selectedRetailer();
      await mount(tester, route: '/app/work/workspace/contact', work: work);

      expect(find.byKey(const Key('workspace-account-setup-hero')), findsOne);
      expect(find.text('Google account'), findsOne);
      expect(find.byKey(const Key('work-global-chat')), findsNothing);
      expect(find.byKey(const Key('work-help')), findsNothing);
      expectHeaderAndStickyAction(tester);
      final alternate = find.byKey(const Key('work-alternate-contact-field'));
      await reveal(tester, alternate);
      expect(
        tester.getBottomRight(alternate).dy,
        lessThanOrEqualTo(
          tester
              .getTopRight(find.byKey(const Key('work-sticky-action-bar')))
              .dy,
        ),
      );
      expect(find.byKey(const Key('work-contact-continue')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('contact OTP action stays on one line on a narrow device', (
    tester,
  ) async {
    final work = selectedRetailer()
      ..primaryMobile = '9829012321'
      ..primaryMobileVerified = false
      ..primaryMobileOtpSent = true;
    await mount(tester, route: '/app/work/workspace/contact', work: work);

    final confirm = find.descendant(
      of: find.byKey(const Key('work-primary-contact-confirm-otp')),
      matching: find.text('Confirm'),
    );
    await reveal(tester, confirm);
    final label = tester.widget<Text>(confirm);
    expect(label.maxLines, 1);
    expect(label.softWrap, isFalse);
    expect(find.text('6-digit code'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Workspace request sheet clears Android and keyboard insets without losing input',
    (tester) async {
      final work = WorkSession();
      await mount(
        tester,
        route: '/app/work/workspace/choose',
        work: work,
        bottomInset: 0,
      );

      final request = find.byKey(const Key('work-profile-not-shown'));
      await tester.scrollUntilVisible(
        request,
        300,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('work-choose-screen')),
              matching: find.byType(Scrollable),
            )
            .first,
        maxScrolls: 60,
      );
      await tester.pumpAndSettle();
      await tester.tap(request);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('work-profile-request-sheet')),
        findsOneWidget,
      );
      final actions = find.byKey(const Key('work-profile-request-actions'));
      expect(tester.getBottomRight(actions).dy, lessThanOrEqualTo(768));
      final area = find.byKey(const Key('work-request-area'));
      expect(area, findsOneWidget);
      expect(
        tester.getTopLeft(actions).dy - tester.getBottomLeft(area).dy,
        lessThanOrEqualTo(48),
      );

      final name = find.byKey(const Key('work-request-profile-name'));
      await tester.tap(name);
      await tester.enterText(name, 'Furniture repair');
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(name).controller?.text,
        'Furniture repair',
      );
      expect(tester.getBottomRight(actions).dy, lessThanOrEqualTo(468));
      final send = find.byKey(const Key('work-send-profile-request'));
      final back = find.byKey(const Key('work-profile-request-back'));
      expect(send, findsOneWidget);
      expect(back, findsOneWidget);
      expect(tester.getBottomRight(send).dy, lessThanOrEqualTo(436));
      expect(tester.getBottomRight(back).dy, lessThanOrEqualTo(436));
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('work-profile-request-back')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-profile-request-sheet')), findsNothing);
    },
  );

  testWidgets(
    'proof source and review declaration clear system and sticky actions',
    (tester) async {
      final work = selectedRetailer()
        ..saveDetails(
          name: 'Mahadev Fresh Mart',
          area: 'Sardarpura, Jodhpur',
          activity: 'Grocery and household products',
        )
        ..continueToProof();
      await mount(tester, route: '/app/work/workspace/proof', work: work);
      expect(find.byKey(const Key('work-global-chat')), findsNothing);
      expect(find.byKey(const Key('work-help')), findsNothing);
      await tester.tap(find.byKey(const Key('work-details-continue')));
      await tester.pumpAndSettle();
      final addProof = find.byKey(const Key('work-add-proof-shop-front'));
      await reveal(tester, addProof);
      await tester.tap(addProof);
      await tester.pumpAndSettle();
      for (final key in const [
        'work-proof-source-camera',
        'work-proof-source-gallery',
        'work-proof-source-upload',
        'work-proof-source-cloud',
      ]) {
        expect(find.byKey(Key(key)), findsOneWidget);
        expect(tester.getSize(find.byKey(Key(key))).width, lessThan(90));
      }
      final cancel = find.byKey(const Key('work-proof-source-cancel'));
      expect(tester.getBottomRight(cancel).dy, lessThanOrEqualTo(756));
      await tester.tap(cancel);
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        await work.addProof('shop-front', WorkProofSource.upload);
        await work.addProof('owner-authority', WorkProofSource.upload);
        await work.addProof('payout-bank-account', WorkProofSource.upload);
      });
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('work-proof-review')));
      await tester.pumpAndSettle();
      for (final label in const ['Edit details', 'Edit documents']) {
        final text = tester.widget<Text>(find.text(label));
        expect(text.maxLines, 2);
        expect(tester.getSize(find.text(label)).height, lessThanOrEqualTo(40));
      }
      final declaration = find.byKey(const Key('work-declaration'));
      await reveal(tester, declaration);
      expect(
        tester.getBottomRight(declaration).dy,
        lessThanOrEqualTo(
          tester
              .getTopRight(find.byKey(const Key('work-sticky-action-bar')))
              .dy,
        ),
      );
      expect(find.byKey(const Key('work-submit-profile')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'review status keeps Action available above Check review update',
    (tester) async {
      final work = selectedRetailer()
        ..reviewStage = WorkReviewStage.gstPending
        ..reviewCaseId = 'WORK-REVIEW-204';
      await mount(tester, route: '/app/work/status', work: work);
      expectHeaderAndStickyAction(tester);
      final action = find.text('Action available');
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      expect(
        tester.getBottomRight(action).dy,
        lessThanOrEqualTo(
          tester
              .getTopRight(find.byKey(const Key('work-sticky-action-bar')))
              .dy,
        ),
      );
      expect(find.byKey(const Key('work-check-review')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ready and shop setup content remain scrollable above stable action',
    (tester) async {
      final work = WorkSession()..seedVerifiedWorkspace();
      work.beginRetailerSetup();
      work.addRetailerProduct();
      await mount(tester, route: '/app/work/retailer/setup', work: work);
      expectHeaderAndStickyAction(tester);
      final visibilityCopy = find.text(
        'Nothing will be public after setup until you choose Open.',
      );
      await reveal(tester, visibilityCopy);
      expect(
        tester.getBottomRight(visibilityCopy).dy,
        lessThanOrEqualTo(
          tester
              .getTopRight(find.byKey(const Key('work-sticky-action-bar')))
              .dy,
        ),
      );
      expect(find.byKey(const Key('retailer-finish-setup')), findsOneWidget);
      expect(
        find.byKey(const Key('retailer-publish-after-setup')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('retailer-publish-after-setup')));
      await tester.pumpAndSettle();
      expect(work.retailerPublishAfterSetup, isTrue);
      expect(find.text('Finish setup and open store'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  group('local Store 1-40 review evidence', skip: true, () {
    testWidgets('profile dashboard remains usable on compact large-text layout', (
      tester,
    ) async {
      final work = selectedRetailer()
        ..hydrateAccountSnapshot(
          const WorkAccountSnapshot(
            email: 'asha@example.com',
            mobile: '+91 98290 12321',
            providerLabel: 'Google',
            providerAccount: 'asha@example.com',
            emailConfirmed: true,
            mobileConfirmed: true,
          ),
        )
        ..saveDetails(
          name: 'Mahadev Fresh Mart',
          area: 'Sardarpura, Jodhpur',
          activity: 'Grocery retail',
        )
        ..reviewCaseId = 'WP-240701'
        ..workspaceId = 'WK-510001'
        ..reviewStage = WorkReviewStage.approved
        ..remoteReviewStatus = WorkRemoteReviewStatus.approved
        ..activeWorkspace = const WorkWorkspace(
          id: 'WK-510001',
          name: 'Mahadev Fresh Mart',
          profileLabel: 'Grocery / Kirana Shop',
          area: 'Sardarpura, Jodhpur',
          verified: true,
        )
        ..showNotice(
          'Work profile approved. Finish setup before customers can view your Workspace.',
        );
      await mount(tester, route: '/app/work/workspace/dashboard', work: work);

      expect(find.byKey(const Key('work-dashboard-hero')), findsNothing);
      expect(find.textContaining('Work profile approved'), findsNothing);
      expect(
        find.text('Mahadev Fresh Mart · Sardarpura, Jodhpur'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('work-dashboard-inline-header')), findsOne);
      expect(
        find.byKey(const Key('work-dashboard-workspace-switcher')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('work-page-title')), findsNothing);
      expect(
        find.byKey(const Key('work-dashboard-account-state')),
        findsNothing,
      );
      expect(
        find.bySemanticsLabel('Search orders, products, customers or invoices'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(RegExp('Store alerts')), findsOneWidget);
      expect(
        find.byKey(const Key('work-dashboard-command-centre')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('work-dashboard-store-state')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('work-dashboard-setup-panel')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('work-dashboard-live-metrics')),
        findsNothing,
      );
      expect(find.byKey(const Key('work-store-quick-actions')), findsNothing);
      expect(find.byKey(const Key('work-sticky-action-bar')), findsNothing);
      expect(find.byKey(const Key('work-local-navigation')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'retail dashboard exposes the four connected control surfaces',
      (tester) async {
        final work = WorkSession()..seedVerifiedWorkspace();
        await mount(tester, route: '/app/work/workspace/dashboard', work: work);

        expect(find.byKey(const Key('work-dashboard-hero')), findsNothing);
        for (final keyName in const [
          'work-dashboard-search',
          'work-dashboard-alerts',
          'work-dashboard-profile',
          'work-dashboard-workspace-switcher',
          'work-dashboard-command-centre',
          'work-dashboard-store-state',
          'work-dashboard-visibility',
          'work-dashboard-public-preview',
          'work-dashboard-setup-panel',
          'work-dashboard-priority-action',
        ]) {
          await reveal(tester, find.byKey(Key(keyName)));
          expect(find.byKey(Key(keyName)), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'approved store rail is contextual and opens actions directly',
      (tester) async {
        final work = WorkSession()
          ..seedVerifiedWorkspace()
          ..retailerSetupSaved = true
          ..reviewStage = WorkReviewStage.live
          ..workspaceStoreState = WorkspaceStoreState.open
          ..workspaceAcceptingOrders = true
          ..workspaceVisibleToCustomers = true;
        await mount(tester, route: '/app/work/workspace/dashboard', work: work);

        expect(find.byKey(const Key('work-local-earn')), findsNothing);
        expect(find.byKey(const Key('work-local-workspace')), findsNothing);
        final storeKeys = const [
          Key('work-store-home'),
          Key('work-store-orders'),
          Key('work-store-sell'),
          Key('work-store-stock'),
        ];
        for (final key in storeKeys) {
          expect(find.byKey(key), findsOneWidget);
        }
        final centers = storeKeys
            .map((key) => tester.getCenter(find.byKey(key)).dx)
            .toList();
        expect(centers[1] - centers[0], closeTo(60, 1));
        expect(centers[2] - centers[1], closeTo(60, 1));
        expect(centers[3] - centers[2], closeTo(60, 1));

        await tester.tap(find.byKey(const Key('work-store-orders')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('retailer-orders-screen')), findsOneWidget);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-store-today-canvas')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('work-store-context-rail')),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('work-store-sell')));
        await tester.pumpAndSettle();
        expect(find.text('Create order'), findsOneWidget);
        expect(
          find.text('Counter, phone or Chat · one live stock'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'retail dashboard Profile opens globally and returns in place',
      (tester) async {
        final work = WorkSession()..seedVerifiedWorkspace();
        await mount(tester, route: '/app/work/workspace/dashboard', work: work);

        await tester.tap(find.byKey(const Key('work-dashboard-profile')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('global-profile-panel-v2')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-workspace-dashboard')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'store search keeps text stable with keyboard and native Back',
      (tester) async {
        final work = WorkSession()..seedVerifiedWorkspace();
        await mount(tester, route: '/app/work/workspace/dashboard', work: work);

        await tester.tap(find.byKey(const Key('work-dashboard-search')));
        await tester.pumpAndSettle();
        final field = find.byKey(const Key('work-dashboard-search-field'));
        expect(field, findsOneWidget);
        await tester.enterText(field, 'fortune');
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();

        expect(work.workspaceSearchQuery, 'fortune');
        expect(
          find.byKey(const Key('work-search-product-oil-fortune-1l')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('work-search-order-current')),
          findsNothing,
        );
        expect(
          tester.getBottomRight(field).dy,
          lessThanOrEqualTo(
            tester
                .getTopRight(find.byKey(const Key('work-local-navigation')))
                .dy,
          ),
        );
        expect(tester.takeException(), isNull);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-workspace-dashboard')),
          findsOneWidget,
        );
        expect(work.workspaceSearchQuery, 'fortune');
      },
    );

    testWidgets(
      'availability saves customer-facing state and Back discards draft',
      (tester) async {
        final work = WorkSession()
          ..seedVerifiedWorkspace()
          ..retailerSetupSaved = true
          ..reviewStage = WorkReviewStage.live
          ..workspaceStoreState = WorkspaceStoreState.open
          ..workspaceAcceptingOrders = true;
        await mount(tester, route: '/app/work/workspace/dashboard', work: work);

        await tester.tap(find.byKey(const Key('work-dashboard-status')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-dashboard-status-screen')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('work-status-accepting-orders')));
        await tester.pumpAndSettle();
        await reveal(tester, find.text('Tomorrow at 8:00 AM'));
        expect(find.text('Tomorrow at 8:00 AM'), findsOneWidget);
        await tester.tap(find.byKey(const Key('work-status-save')));
        await tester.pumpAndSettle();

        expect(work.workspaceAcceptingOrders, isFalse);
        expect(work.workspaceReopensAt, 'Tomorrow at 8:00 AM');
        expect(work.workspaceActivity.first.message, contains('paused'));

        await tester.tap(find.byKey(const Key('work-dashboard-status')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('work-status-accepting-orders')));
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(work.workspaceAcceptingOrders, isFalse);
        expect(
          find.byKey(const Key('work-workspace-dashboard')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('attention queue is truthful and returns to dashboard', (
      tester,
    ) async {
      final work = WorkSession()..seedVerifiedWorkspace();
      await mount(tester, route: '/app/work/workspace/dashboard', work: work);

      await tester.tap(find.byKey(const Key('work-dashboard-alerts')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-dashboard-alerts-screen')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('work-alert-store-setup')), findsOneWidget);
      expect(
        find.byKey(const Key('work-alert-contact-details')),
        findsOneWidget,
      );
      expect(find.text('No urgent store action'), findsNothing);

      await tester.tap(find.byKey(const Key('work-back')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-workspace-dashboard')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'daily actions use existing retailer owners and native Back restores Store',
      (tester) async {
        final work = WorkSession()
          ..seedVerifiedWorkspace()
          ..retailerSetupSaved = true
          ..reviewStage = WorkReviewStage.live
          ..workspaceStoreState = WorkspaceStoreState.open
          ..workspaceAcceptingOrders = true
          ..workspaceVisibleToCustomers = true;
        await mount(tester, route: '/app/work/workspace/dashboard', work: work);

        await tester.tap(find.byKey(const Key('work-store-orders')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('retailer-orders-screen')), findsOneWidget);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-store-today-canvas')),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('work-quick-new-sale')));
        await tester.pumpAndSettle();
        expect(find.text('Create order'), findsOneWidget);
        expect(find.text('Counter'), findsWidgets);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-store-today-canvas')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Stock opens the authoritative retailer catalogue owner', (
      tester,
    ) async {
      final work = WorkSession()
        ..seedVerifiedWorkspace()
        ..retailerSetupSaved = true
        ..reviewStage = WorkReviewStage.live
        ..workspaceStoreState = WorkspaceStoreState.open
        ..workspaceAcceptingOrders = true;
      await mount(tester, route: '/app/work/workspace/dashboard', work: work);

      await tester.tap(find.byKey(const Key('work-store-stock')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('retailer-stock-preview-screen')),
        findsOneWidget,
      );
      expect(find.text('Available products'), findsOneWidget);
      expect(
        find.text('Consumer quantities and household prices only'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('store state and customer preview complete within two taps', (
      tester,
    ) async {
      final work = WorkSession()
        ..seedVerifiedWorkspace()
        ..reviewStage = WorkReviewStage.live
        ..retailerSetupSaved = true
        ..workspaceVisibleToCustomers = true
        ..workspaceStoreState = WorkspaceStoreState.open
        ..workspaceAcceptingOrders = true;
      await mount(tester, route: '/app/work/workspace/dashboard', work: work);

      await tester.tap(find.byKey(const Key('work-dashboard-store-state')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pause for 1 hour'));
      await tester.pumpAndSettle();
      expect(work.workspaceAcceptingOrders, isFalse);
      expect(work.workspaceReopensAt, 'In 1 hour');
      expect(find.text('Paused'), findsOneWidget);

      await tester.tap(find.byKey(const Key('work-dashboard-public-preview')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-dashboard-preview-screen')),
        findsOneWidget,
      );
      expect(find.text('Mahadev Fresh Mart'), findsOneWidget);
      expect(
        find.byKey(const Key('work-preview-product-oil-fortune-1l')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('work-preview-visibility')));
      await tester.pumpAndSettle();
      expect(work.workspaceVisibleToCustomers, isFalse);
      expect(work.workspaceStoreState, WorkspaceStoreState.paused);
      expect(find.text('PRIVATE PREVIEW'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('first-tap store actions open exact operational destinations', (
      tester,
    ) async {
      final work = WorkSession()
        ..seedVerifiedWorkspace()
        ..retailerSetupSaved = true
        ..reviewStage = WorkReviewStage.live
        ..workspaceStoreState = WorkspaceStoreState.open
        ..workspaceAcceptingOrders = true
        ..workspaceVisibleToCustomers = true;
      await mount(tester, route: '/app/work/workspace/dashboard', work: work);

      for (final keyName in const [
        'work-quick-new-sale',
        'work-quick-delivery',
        'work-quick-buy',
        'work-quick-group-buy',
      ]) {
        expect(find.byKey(Key(keyName)), findsOneWidget);
      }

      await tester.tap(find.byKey(const Key('work-quick-delivery')));
      await tester.pumpAndSettle();
      expect(find.text('Create order'), findsOneWidget);
      expect(find.text('Phone'), findsWidgets);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-store-today-canvas')), findsOneWidget);

      await tester.tap(find.byKey(const Key('work-quick-buy')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-v2-screen')), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      if (find.byKey(const ValueKey('buy-v2-screen')).evaluate().isNotEmpty) {
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
      }
      expect(find.byKey(const Key('work-store-today-canvas')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('paid Group Buy pins to Today with complete decision facts', (
      tester,
    ) async {
      final work = WorkSession()
        ..seedVerifiedWorkspace()
        ..applyConfirmedWorkspaceGroupBuyPayment(
          productName: 'Premium onion',
          specification: 'Fresh red onion · Grade A · 45 mm+',
          targetQuantity: 1000,
          securedQuantity: 100,
          unitLabel: 'kg',
          regularUnitPrice: 18,
          groupUnitPrice: 14,
          facilitationFee: 200,
          deliveryFee: 0,
          confirmationAmount: 1400,
          paymentReference: 'PAY-REVIEW-001',
          closingLabel: '5 Sep · 8:00 PM',
          storeDeliveryLabel: '7 Sep · Door delivery',
        );
      await mount(tester, route: '/app/work/workspace/dashboard', work: work);

      expect(
        find.byKey(const Key('work-dashboard-active-group-buy')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const Key('work-dashboard-active-group-buy')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-group-buy-active-screen')),
        findsOneWidget,
      );
      expect(find.text('₹14/kg'), findsWidgets);
      expect(find.text('₹400'), findsOneWidget);
      await reveal(tester, find.text('Confirmed · payment received'));
      expect(find.text('Confirmed · payment received'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'first-use dashboard shows priorities without fake zero metrics',
      (tester) async {
        final work = WorkSession()..seedVerifiedWorkspace();
        await mount(tester, route: '/app/work/workspace/dashboard', work: work);

        expect(
          find.byKey(const Key('work-dashboard-setup-panel')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('work-dashboard-live-metrics')),
          findsNothing,
        );
        expect(find.byKey(const Key('work-store-quick-actions')), findsNothing);
        expect(find.text('No order waiting'), findsNothing);
        expect(find.text('No delivery waiting'), findsNothing);
        expect(find.text('₹0'), findsNothing);
        expect(
          find.widgetWithText(FilledButton, 'Continue store setup'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('public visibility remains separate from Open Paused and Off', (
      tester,
    ) async {
      final work = WorkSession()
        ..seedVerifiedWorkspace()
        ..retailerSetupSaved = true
        ..reviewStage = WorkReviewStage.live
        ..workspaceStoreState = WorkspaceStoreState.open
        ..workspaceAcceptingOrders = true
        ..workspaceVisibleToCustomers = true;
      await mount(tester, route: '/app/work/workspace/dashboard', work: work);

      await tester.tap(find.byKey(const Key('work-dashboard-store-state')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Turn ordering off'));
      await tester.pumpAndSettle();
      expect(work.workspaceStoreState, WorkspaceStoreState.off);
      expect(work.workspaceAcceptingOrders, isFalse);
      expect(work.workspaceVisibleToCustomers, isTrue);
      expect(find.text('Off'), findsOneWidget);
      expect(find.text('Public'), findsOneWidget);

      await tester.tap(find.byKey(const Key('work-dashboard-visibility')));
      await tester.pumpAndSettle();
      expect(work.workspaceVisibleToCustomers, isFalse);
      expect(work.workspaceStoreState, WorkspaceStoreState.off);
      expect(find.text('Private'), findsOneWidget);
    });

    testWidgets('Grow is customer growth and business support, not Wholesale', (
      tester,
    ) async {
      final work = WorkSession()
        ..seedVerifiedWorkspace()
        ..retailerSetupSaved = true
        ..reviewStage = WorkReviewStage.live;
      await mount(tester, route: '/app/work/workspace/dashboard', work: work);

      await tester.tap(find.text('Grow'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-grow-destination')), findsOneWidget);
      for (final copy in const [
        'Bring customers back',
        'Offers and repeat baskets',
        'Promote your store',
        'Publish paid work',
        'Business support',
      ]) {
        await reveal(tester, find.text(copy));
        expect(find.text(copy), findsOneWidget);
      }
      expect(find.text('Buy stock at wholesale'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Buy Together cannot be published by a self-declared payment', (
      tester,
    ) async {
      final work = WorkSession()
        ..seedVerifiedWorkspace()
        ..retailerSetupSaved = true
        ..reviewStage = WorkReviewStage.live;
      await mount(tester, route: '/app/work/workspace/dashboard', work: work);

      await tester.tap(find.byKey(const Key('work-quick-group-buy')));
      await tester.pumpAndSettle();
      expect(find.text('Start Buy Together'), findsOneWidget);
      expect(
        find.byKey(const Key('work-group-buy-payment-confirmed')),
        findsNothing,
      );
      expect(find.text('Confirm and publish Group Buy'), findsNothing);
      await reveal(
        tester,
        find.textContaining('payment service confirms your amount'),
      );
      expect(
        find.textContaining('payment service confirms your amount'),
        findsOneWidget,
      );
      expect(work.activeGroupBuy, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'saved offline activity exposes a truthful refresh transition',
      (tester) async {
        final work = WorkSession()
          ..seedVerifiedWorkspace()
          ..retailerSetupSaved = true
          ..reviewStage = WorkReviewStage.live
          ..workspaceDashboardState = WorkspaceDashboardState.offline
          ..workspaceLastUpdatedAt = DateTime(2026, 9, 2, 14, 15);
        await mount(tester, route: '/app/work/workspace/dashboard', work: work);

        expect(find.text('Showing saved store activity'), findsOneWidget);
        await tester.tap(find.byKey(const Key('work-dashboard-retry')));
        await tester.pump();
        expect(
          work.workspaceDashboardState,
          WorkspaceDashboardState.refreshing,
        );
        expect(find.text('Refreshing store activity'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'founder review capture - setup dashboard',
      skip: !captureFounderEvidence,
      (tester) async {
        final work = WorkSession()..seedVerifiedWorkspace();
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: const Size(412, 915),
          textScale: 1,
          bottomInset: 34,
        );
        await expectLater(
          find.byType(Scaffold).first,
          matchesGoldenFile(
            '../../../artifacts/quality/work-store-atomic-1-40-r62-47-local-review-20260903/work-dashboard-setup-412x915.png',
          ),
        );
      },
    );

    testWidgets(
      'founder review capture - live operations dashboard',
      skip: !captureFounderEvidence,
      (tester) async {
        final work = WorkSession()
          ..seedVerifiedWorkspace()
          ..retailerSetupSaved = true
          ..reviewStage = WorkReviewStage.live
          ..workspaceStoreState = WorkspaceStoreState.open
          ..workspaceAcceptingOrders = true
          ..workspaceVisibleToCustomers = true
          ..workspaceSalesToday = 28450
          ..workspaceSettlementBalance = 17820
          ..workspaceOrderCustomer = 'Rakesh · 98290 12345'
          ..workspaceOrderSource = 'App'
          ..workspaceOrderItems = 'Fortune Oil × 2 · Aashirvaad Atta × 1'
          ..workspaceOrderAmount = '1468'
          ..workspaceOrderStage = 'Confirmed'
          ..workspaceCatalogueItems[0] = workspaceMasterCatalogue.first
              .copyWith(stock: 3, available: true, publicListing: true)
          ..workspaceLastUpdatedAt = DateTime(2026, 9, 2, 7, 0)
          ..applyConfirmedWorkspaceGroupBuyPayment(
            productName: 'Premium red onion',
            specification: 'Grade A · 45 mm+ · 25 kg mesh bags',
            targetQuantity: 1000,
            securedQuantity: 280,
            unitLabel: 'kg',
            regularUnitPrice: 18,
            groupUnitPrice: 14,
            facilitationFee: 200,
            deliveryFee: 0,
            confirmationAmount: 3920,
            paymentReference: 'PAY-REVIEW-001',
            closingLabel: '5 Sep · 8:00 PM',
            storeDeliveryLabel: '7 Sep · Door delivery',
          );
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: const Size(412, 915),
          textScale: 1,
          bottomInset: 34,
        );
        await expectLater(
          find.byType(Scaffold).first,
          matchesGoldenFile(
            '../../../artifacts/quality/work-store-atomic-1-40-r62-47-local-review-20260903/work-dashboard-live-412x915.png',
          ),
        );
      },
    );

    testWidgets(
      'founder review capture - saved offline dashboard',
      skip: !captureFounderEvidence,
      (tester) async {
        final work = WorkSession()
          ..seedVerifiedWorkspace()
          ..retailerSetupSaved = true
          ..reviewStage = WorkReviewStage.live
          ..workspaceStoreState = WorkspaceStoreState.paused
          ..workspaceAcceptingOrders = false
          ..workspaceVisibleToCustomers = true
          ..workspaceReopensAt = 'at 4:00 PM'
          ..workspaceSalesToday = 8620
          ..workspaceSettlementBalance = 4200
          ..workspaceLastUpdatedAt = DateTime(2026, 9, 2, 14, 15)
          ..workspaceDashboardState = WorkspaceDashboardState.offline;
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: const Size(412, 915),
          textScale: 1,
          bottomInset: 34,
        );
        await expectLater(
          find.byType(Scaffold).first,
          matchesGoldenFile(
            '../../../artifacts/quality/work-store-atomic-1-40-r62-47-local-review-20260903/work-dashboard-offline-412x915.png',
          ),
        );
      },
    );

    testWidgets(
      'founder review capture - real store search',
      skip: !captureFounderEvidence,
      (tester) async {
        final work = WorkSession()
          ..seedVerifiedWorkspace()
          ..retailerSetupSaved = true
          ..reviewStage = WorkReviewStage.live
          ..workspaceStoreState = WorkspaceStoreState.open
          ..workspaceAcceptingOrders = true
          ..workspaceVisibleToCustomers = true;
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: const Size(412, 915),
          textScale: 1,
          bottomInset: 34,
        );
        await tester.tap(find.byKey(const Key('work-dashboard-search')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('work-dashboard-search-field')),
          'fortune',
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(Scaffold).first,
          matchesGoldenFile(
            '../../../artifacts/quality/work-store-atomic-1-40-r62-47-local-review-20260903/work-dashboard-search-412x915.png',
          ),
        );
      },
    );

    testWidgets(
      'founder review capture - Grow hub',
      skip: !captureFounderEvidence,
      (tester) async {
        final work = WorkSession()
          ..seedVerifiedWorkspace()
          ..retailerSetupSaved = true
          ..reviewStage = WorkReviewStage.live
          ..workspaceStoreState = WorkspaceStoreState.open
          ..workspaceAcceptingOrders = true
          ..workspaceVisibleToCustomers = true;
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: const Size(412, 915),
          textScale: 1,
          bottomInset: 34,
        );
        await tester.tap(find.byKey(const Key('work-business-drawer')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('work-business-grow')));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(Scaffold).first,
          matchesGoldenFile(
            '../../../artifacts/quality/work-store-atomic-1-40-r62-47-local-review-20260903/work-dashboard-grow-412x915.png',
          ),
        );
      },
    );

    testWidgets(
      'founder review capture - public storefront preview',
      skip: !captureFounderEvidence,
      (tester) async {
        final work = WorkSession()
          ..seedVerifiedWorkspace()
          ..retailerSetupSaved = true
          ..reviewStage = WorkReviewStage.live
          ..workspaceStoreState = WorkspaceStoreState.open
          ..workspaceAcceptingOrders = true
          ..workspaceVisibleToCustomers = true;
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: const Size(412, 915),
          textScale: 1,
          bottomInset: 34,
        );
        await tester.tap(find.byKey(const Key('work-business-drawer')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('work-business-storefront')));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(Scaffold).first,
          matchesGoldenFile(
            '../../../artifacts/quality/work-store-atomic-1-40-r62-47-local-review-20260903/work-dashboard-public-preview-412x915.png',
          ),
        );
      },
    );
  });

  testWidgets('Store Activity Deck replaces rejected dashboard bands', (
    tester,
  ) async {
    final work = liveStore();
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);

    for (final key in const [
      'work-store-activity-deck',
      'work-activity-ready',
      'work-live-status-bubbles',
      'work-floating-command-dock',
      'work-business-drawer',
      'work-dashboard-settings',
      'work-dashboard-scan',
    ]) {
      expect(find.byKey(Key(key)), findsOneWidget);
    }
    expect(find.byKey(const Key('work-store-context-rail')), findsNothing);
    expect(
      find.byKey(const Key('work-dashboard-command-centre')),
      findsNothing,
    );
    expect(find.byKey(const Key('work-dashboard-live-metrics')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Store hosts Wholesale and Bulk with one Store navigation owner',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final work = liveStore();
      await mount(tester, route: '/app/work/workspace/dashboard', work: work);

      await tester.tap(find.byKey(const Key('work-quick-buy')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-v2-screen')), findsOneWidget);
      expect(
        find.byKey(const Key('work-store-procurement-screen')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('work-local-navigation')), findsOneWidget);
      expectStoreNavigationOwnsProcurement(tester);
      expect(
        find.bySemanticsLabel('Store choices: Store, Orders, Sell and Stock.'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Shop choices: Wholesale, Orders and Offers.'),
        findsNothing,
      );
      expect(find.text('Wholesale and Bulk'), findsWidgets);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-store-procurement-screen')),
        findsNothing,
      );
      expect(find.byKey(const Key('work-store-activity-deck')), findsOneWidget);

      await tester.tap(find.byKey(const Key('work-quick-buy')));
      await tester.pumpAndSettle();
      final storeBack = find.byKey(const Key('work-back')).hitTestable();
      expect(storeBack, findsOneWidget);
      await tester.tap(storeBack);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-store-activity-deck')), findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets(
    'in-Store Wholesale search keeps one coherent keyboard and rail owner',
    (tester) async {
      final work = liveStore();
      await mount(tester, route: '/app/work/workspace/dashboard', work: work);

      await tester.tap(find.byKey(const Key('work-quick-buy')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-search-control')));
      await tester.pumpAndSettle();
      final search = find.byKey(const ValueKey('buy-search-field'));
      expect(search, findsOneWidget);

      await tester.enterText(search, 'cooking oil bulk pack');
      await tester.pump();
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-local-navigation')), findsNothing);
      final buyRail = find.byKey(const ValueKey('buy-local-destination-tabs'));
      expect(buyRail, findsOneWidget);
      expect(
        tester.getTopLeft(buyRail).dy,
        greaterThanOrEqualTo(500),
        reason: 'The embedded Buy rail stays behind the 300px keyboard.',
      );
      expect(tester.takeException(), isNull);

      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-local-navigation')), findsOneWidget);
    },
  );

  testWidgets(
    'Android Back closes Wholesale detail before returning to Store',
    (tester) async {
      final work = liveStore();
      await mount(tester, route: '/app/work/workspace/dashboard', work: work);
      await tester.tap(find.byKey(const Key('work-quick-buy')));
      await tester.pumpAndSettle();

      final product = find
          .byWidgetPredicate((widget) {
            final key = widget.key;
            return key is ValueKey<String> &&
                key.value.startsWith('buy-product-');
          })
          .hitTestable()
          .first;
      expect(product, findsOneWidget);
      await tester.tap(product);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-store-procurement-screen')),
        findsOneWidget,
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-store-procurement-screen')),
        findsOneWidget,
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-store-activity-deck')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('incoming order swipes right into Packing', (tester) async {
    final work = liveStore();
    seedIncomingOrder(work);
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);

    expect(find.byKey(const Key('work-activity-incoming-order')), findsOne);
    await tester.fling(
      find.byKey(const Key('work-activity-incoming-order')),
      const Offset(280, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(work.workspaceOrderStage, 'Preparing');
    expect(find.byKey(const Key('work-activity-packing')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Packing moves to the live delivery object in one tap', (
    tester,
  ) async {
    final work = liveStore();
    seedIncomingOrder(work, stage: 'Preparing', delivery: true);
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);

    for (final line in work.workspacePackingLines) {
      work.setWorkspacePackingLine(line.id, true);
    }
    await tester.pump();
    await tester.tap(find.byKey(const Key('work-activity-mark-ready')));
    await tester.pumpAndSettle();
    expect(work.workspaceOrderStage, 'Ready');
    expect(find.byKey(const Key('work-activity-delivery')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Settings owns configuration and excludes SKU commercial data', (
    tester,
  ) async {
    final work = liveStore();
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);

    await tester.tap(find.byKey(const Key('work-dashboard-settings')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-dashboard-status-screen')), findsOne);
    expect(find.text('Public storefront'), findsOneWidget);
    await reveal(tester, find.text('Default preparation time'));
    expect(find.text('Default preparation time'), findsOneWidget);
    await reveal(tester, find.text('Fulfilment'));
    expect(find.text('Fulfilment'), findsOneWidget);
    expect(find.text('Selling Price'), findsNothing);
    expect(find.text('MRP'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Workspace catalogue maps exactly into Buy public SKU facts', (
    tester,
  ) async {
    final work = liveStore();
    final product = work.workspaceCatalogueItems.first;
    final buySku = product.toBuyPublicProduct(
      storeName: work.activeWorkspace!.name,
    );
    final facts = product.toBuyPublicFacts(
      storeName: work.activeWorkspace!.name,
      sourceId: 'workspace:${work.activeWorkspace!.id}',
      storeVisible: true,
      acceptingOrders: true,
      observedAt: DateTime(2026, 9, 3, 8, 30),
    );
    expect(buySku.canonicalId, product.canonicalId);
    expect(buySku.title, product.title);
    expect(buySku.brand, product.brand);
    expect(buySku.variant, product.variant);
    expect(buySku.pack, product.pack);
    expect(buySku.price, product.sellingPrice);
    expect(buySku.mrp, product.mrp);
    expect(buySku.unitPrice, product.unitPrice);
    expect(buySku.deliveryPromise, product.deliveryPromise);
    expect(buySku.catalogueListing, product.publicListing);
    expect(facts.price, product.sellingPrice);
    expect(facts.partner, work.activeWorkspace!.name);
    expect(facts.orderabilityLabel, 'Available to order');

    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    await tester.tap(find.byKey(const Key('work-store-stock')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-dashboard-catalogue-screen')), findsOne);
    expect(find.byKey(Key('work-public-sku-${product.id}')), findsOneWidget);
    expect(find.textContaining('₹${product.sellingPrice}'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Group Bulk Buying opens the live payment-backed deal', (
    tester,
  ) async {
    final work = liveStore()
      ..applyConfirmedWorkspaceGroupBuyPayment(
        productName: 'Premium red onion',
        specification: 'Grade A · 45 mm+ · 25 kg mesh bags',
        targetQuantity: 1000,
        securedQuantity: 280,
        unitLabel: 'kg',
        regularUnitPrice: 18,
        groupUnitPrice: 14,
        facilitationFee: 200,
        deliveryFee: 0,
        confirmationAmount: 3920,
        paymentReference: 'PAY-REVIEW-001',
        closingLabel: '5 Sep · 8:00 PM',
        storeDeliveryLabel: '7 Sep · Door delivery',
      );
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    expect(find.byKey(const Key('work-activity-group-bulk')), findsOneWidget);
    await tester.tap(find.byKey(const Key('work-quick-group-buy')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-group-buy-active-screen')), findsOne);
    expect(find.text('GROUP BULK BUYING'), findsOneWidget);
    expect(find.text('₹14/kg'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Workspace switcher keeps the approval action above Android', (
    tester,
  ) async {
    final work = liveStore()..seedMultipleWorkspaces();
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    await tester.tap(
      find.byKey(const Key('work-dashboard-workspace-switcher')),
    );
    await tester.pumpAndSettle();
    final request = find.byKey(const Key('work-switch-add-workspace'));
    expect(request, findsOneWidget);
    await tester.ensureVisible(request);
    expect(request.hitTestable(), findsOneWidget);
    expect(tester.getBottomRight(request).dy, lessThanOrEqualTo(756));
    expect(find.textContaining('Create content anytime from Social'), findsOne);
  });

  testWidgets(
    'order completion action clears Android navigation and is tappable',
    (tester) async {
      final work = liveStore();
      await mount(tester, route: '/app/work/workspace/dashboard', work: work);
      await tester.tap(find.byKey(const Key('work-quick-new-sale')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('work-order-customer')),
        '9829012345',
      );
      await tester.tap(find.byKey(const Key('work-order-add-oil-fortune-1l')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('work-order-review')));
      await tester.pumpAndSettle();
      final save = find.byKey(const Key('work-order-save'));
      expect(save, findsOneWidget);
      expect(save.hitTestable(), findsOneWidget);
      expect(tester.getBottomRight(save).dy, lessThanOrEqualTo(756));
    },
  );

  testWidgets('Store settings destinations match their labels', (tester) async {
    final work = liveStore();
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    await tester.tap(find.byKey(const Key('work-dashboard-settings')));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Delivery area and charges'));
    await tester.tap(find.text('Delivery area and charges'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-delivery-settings-screen')), findsOne);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-dashboard-status-screen')), findsOne);
    await reveal(tester, find.text('Staff and counters'));
    await tester.tap(find.text('Staff and counters'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-staff-settings-screen')), findsOne);
  });

  testWidgets('pickup order becomes customer pickup and produces invoice', (
    tester,
  ) async {
    final work = liveStore();
    seedIncomingOrder(work, stage: 'Preparing');
    for (final line in work.workspacePackingLines) {
      work.setWorkspacePackingLine(line.id, true);
    }
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    await tester.tap(find.byKey(const Key('work-activity-mark-ready')));
    await tester.pumpAndSettle();
    expect(work.workspaceOrderStage, 'Ready for pickup');
    expect(find.byKey(const Key('work-activity-pickup-ready')), findsOne);
    expect(find.text('Delivery partner assignment pending'), findsNothing);
    await tester.tap(find.byKey(const Key('work-confirm-customer-pickup')));
    await tester.pumpAndSettle();
    expect(work.workspaceOrderStage, 'Completed');
    expect(find.byKey(const Key('work-invoice-share-chat')), findsOne);
    await tester.tap(find.byKey(const Key('work-invoice-share-chat')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-pending-draft-card')), findsOne);
    expect(find.textContaining('INV-'), findsWidgets);
  });

  testWidgets('live App order appears in customer statement', (tester) async {
    final work = liveStore();
    seedIncomingOrder(work);
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    await tester.tap(find.byKey(const Key('work-business-drawer')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-business-customers')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Rakesh'), findsWidgets);
    expect(find.text('No customer sale yet'), findsNothing);
    final statement = find.byKey(
      const Key('work-customer-order-current-store-order'),
    );
    await reveal(tester, statement);
    expect(statement, findsOne);
  });

  testWidgets('settlement requires review before gateway mutation', (
    tester,
  ) async {
    final gateway = ReviewWorkGateway();
    final work = liveStore(gateway: gateway)
      ..workspaceSettlementBalance = 17820;
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    await tester.tap(find.byKey(const Key('work-business-drawer')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-business-money')));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Review and request settlement'));
    await tester.tap(find.text('Review and request settlement'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-settlement-confirm')), findsOne);
    expect(gateway.settlementCalls, 0);
  });

  testWidgets('Group Bulk product discovery searches beyond Store catalogue', (
    tester,
  ) async {
    final work = liveStore();
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    await tester.tap(find.byKey(const Key('work-quick-group-buy')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-group-buy-product')));
    await tester.pumpAndSettle();
    final search = find.byKey(const Key('work-group-buy-product-search'));
    expect(search, findsOne);
    await tester.enterText(search, 'atta');
    await tester.pumpAndSettle();
    expect(find.textContaining('Aashirvaad'), findsWidgets);
  });

  testWidgets('product editor keeps Save and Cancel above keyboard', (
    tester,
  ) async {
    final work = liveStore();
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    await tester.tap(find.byKey(const Key('work-store-stock')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('work-catalogue-edit-oil-fortune-1l')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-product-save')).hitTestable(), findsOne);
    expect(
      find.byKey(const Key('work-product-cancel')).hitTestable(),
      findsOne,
    );
    await tester.tap(find.byKey(const Key('work-product-title')));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-product-save')).hitTestable(), findsOne);
    expect(
      tester.getBottomRight(find.byKey(const Key('work-product-save'))).dy,
      lessThanOrEqualTo(500),
    );
    tester.view.viewInsets = FakeViewPadding.zero;
  });

  testWidgets('Work inputs expose merged accessibility names', (tester) async {
    final semantics = tester.ensureSemantics();
    final work = liveStore();
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    await tester.tap(find.byKey(const Key('work-quick-new-sale')));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Customer mobile number'), findsOne);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Customer mobile number'))
          .identifier,
      'work-order-customer',
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-quick-group-buy')));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Target quantity'), findsOne);
    expect(find.bySemanticsLabel('Your confirmed quantity'), findsOne);
    semantics.dispose();
  });

  testWidgets('Grow keeps offers and funded work inside Store ownership', (
    tester,
  ) async {
    final work = liveStore();
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    await tester.tap(find.byKey(const Key('work-business-drawer')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-business-grow')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Offers'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-store-offers-screen')), findsOne);
    expect(find.byKey(const Key('work-local-navigation')), findsOne);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-grow-destination')), findsOne);
    await tester.tap(find.text('Publish paid work'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-paid-requirement-screen')), findsOne);
  });

  testWidgets('active Store business record never shows pending onboarding', (
    tester,
  ) async {
    final work = liveStore();
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    await tester.tap(find.byKey(const Key('work-dashboard-settings')));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Business details and documents'));
    await tester.tap(find.text('Business details and documents'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-business-record-screen')), findsOne);
    expect(find.text('Active MoolSocial business partner'), findsOne);
    expect(find.textContaining('Decision Pending'), findsNothing);
  });

  testWidgets('packing keeps every product above its ready action on OPPO', (
    tester,
  ) async {
    final work = liveStore();
    seedIncomingOrder(work, stage: 'Preparing');
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    final first = find.byKey(const Key('work-pack-summary-0'));
    final second = find.byKey(const Key('work-pack-summary-1'));
    final ready = find.byKey(const Key('work-activity-mark-ready'));
    expect(first.hitTestable(), findsOneWidget);
    expect(second.hitTestable(), findsOneWidget);
    expect(
      tester.getBottomRight(second).dy,
      lessThanOrEqualTo(tester.getTopRight(ready).dy),
    );
  });

  testWidgets('nested Store operations return to their exact parent', (
    tester,
  ) async {
    final work = liveStore();
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    await tester.tap(find.byKey(const Key('work-dashboard-settings')));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Delivery area and charges'));
    await tester.tap(find.text('Delivery area and charges'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-operation-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-dashboard-status-screen')), findsOne);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-business-drawer')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-business-grow')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Offers'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-operation-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-grow-destination')), findsOne);
  });

  testWidgets('drafted sale has explicit keep or discard recovery', (
    tester,
  ) async {
    final work = liveStore();
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    await tester.tap(find.byKey(const Key('work-quick-new-sale')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('work-order-customer')),
      '9829012345',
    );
    await tester.tap(find.byKey(const Key('work-order-add-oil-fortune-1l')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-operation-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-order-discard-dialog')), findsOne);
    await tester.tap(find.byKey(const Key('work-order-keep-editing')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-order-customer')), findsOne);
    await tester.tap(find.byKey(const Key('work-operation-back')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-order-discard')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-store-activity-deck')), findsOne);
    expect(work.workspaceOrderQuantities, isEmpty);
  });

  testWidgets('Store header and contextual tabs keep full customer labels', (
    tester,
  ) async {
    final work = liveStore();
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    final searchLabel = tester.widget<Text>(find.text('Search your store'));
    expect(searchLabel.maxLines, 1);
    expect(searchLabel.overflow, isNull);
    await tester.tap(find.byKey(const Key('work-business-drawer')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-business-storefront')));
    await tester.pumpAndSettle();
    for (final label in const [
      'Today',
      'Customers',
      'Money',
      'Grow',
      'Storefront',
    ]) {
      expect(find.text(label), findsWidgets, reason: label);
    }
    expect(
      find
          .byKey(const Key('work-preview-product-oil-fortune-1l'))
          .hitTestable(),
      findsOneWidget,
    );
  });

  testWidgets('finishing Store search clears its inactive term', (
    tester,
  ) async {
    final work = liveStore();
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    await tester.tap(find.byKey(const Key('work-dashboard-search')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('work-dashboard-search-field')),
      'oil',
    );
    await tester.tap(find.byKey(const Key('work-dashboard-search-close')));
    await tester.pumpAndSettle();
    expect(work.workspaceSearchQuery, isEmpty);
    expect(find.text('Search your store'), findsOneWidget);
  });

  testWidgets('Workspace product opens exact public Buy product details', (
    tester,
  ) async {
    final work = liveStore();
    await mount(
      tester,
      route:
          '/app/buy?view=product&product=oil-fortune-1l&workspaceProduct=oil-fortune-1l&return=/app/work/workspace/dashboard',
      work: work,
    );
    await tester.pumpAndSettle();
    expect(find.text('Fortune Sunflower Oil'), findsWidgets);
    expect(find.textContaining('1 L pouch'), findsWidgets);
    expect(find.text('This product could not be found.'), findsNothing);
  });

  testWidgets('Storefront Buy Back returns directly to Storefront', (
    tester,
  ) async {
    final work = liveStore();
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    await tester.tap(find.byKey(const Key('work-business-drawer')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-business-storefront')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('work-preview-product-oil-fortune-1l')),
    );
    await tester.pumpAndSettle();
    await reveal(
      tester,
      find.byKey(const Key('work-preview-open-buy-product')),
    );
    await tester.tap(find.byKey(const Key('work-preview-open-buy-product')));
    await tester.pumpAndSettle();
    expect(find.text('Fortune Sunflower Oil'), findsWidgets);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-dashboard-preview-screen')), findsOne);
  });

  testWidgets('funded work uses compact named customer fields', (tester) async {
    final semantics = tester.ensureSemantics();
    final work = liveStore();
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    await tester.tap(find.byKey(const Key('work-business-drawer')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-business-grow')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Publish paid work'));
    await tester.pumpAndSettle();
    expect(find.text('Experience or qualification'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Experience or qualification'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  Future<void> captureActivityDeck(
    WidgetTester tester, {
    required WorkSession work,
    required String fileName,
    Future<void> Function()? afterMount,
    Finder? target,
  }) async {
    await mount(
      tester,
      route: '/app/work/workspace/dashboard',
      work: work,
      viewport: const Size(412, 915),
      textScale: 1.4,
      bottomInset: 34,
    );
    if (afterMount != null) await afterMount();
    await tester.pumpAndSettle();
    await expectLater(
      target ?? find.byType(Scaffold).first,
      matchesGoldenFile(
        '../../../artifacts/quality/work-store-atomic-r62-50-local-review-20260903/$fileName',
      ),
    );
  }

  testWidgets(
    'founder Activity Deck capture - idle live store',
    skip: !captureFounderEvidence,
    (tester) async {
      await captureActivityDeck(
        tester,
        work: liveStore(),
        fileName: 'store-activity-idle-412x915.png',
      );
    },
  );

  testWidgets(
    'founder Activity Deck capture - incoming order',
    skip: !captureFounderEvidence,
    (tester) async {
      final work = liveStore();
      seedIncomingOrder(work);
      await captureActivityDeck(
        tester,
        work: work,
        fileName: 'store-activity-incoming-order-412x915.png',
      );
    },
  );

  testWidgets(
    'founder Activity Deck capture - packing',
    skip: !captureFounderEvidence,
    (tester) async {
      final work = liveStore();
      seedIncomingOrder(work, stage: 'Preparing', delivery: true);
      await captureActivityDeck(
        tester,
        work: work,
        fileName: 'store-activity-packing-412x915.png',
      );
    },
  );

  testWidgets(
    'founder Activity Deck capture - delivery',
    skip: !captureFounderEvidence,
    (tester) async {
      final work = liveStore();
      seedIncomingOrder(work, stage: 'Ready', delivery: true);
      await captureActivityDeck(
        tester,
        work: work,
        fileName: 'store-activity-delivery-412x915.png',
      );
    },
  );

  testWidgets(
    'founder Activity Deck capture - Settings',
    skip: !captureFounderEvidence,
    (tester) async {
      await captureActivityDeck(
        tester,
        work: liveStore(),
        fileName: 'store-settings-412x915.png',
        afterMount: () async {
          await tester.tap(find.byKey(const Key('work-dashboard-settings')));
        },
      );
    },
  );

  testWidgets(
    'founder Activity Deck capture - public SKU catalogue',
    skip: !captureFounderEvidence,
    (tester) async {
      await captureActivityDeck(
        tester,
        work: liveStore(),
        fileName: 'store-public-sku-catalogue-412x915.png',
        afterMount: () async {
          await tester.tap(find.byKey(const Key('work-store-stock')));
        },
      );
    },
  );

  testWidgets(
    'founder Activity Deck capture - Group Bulk Buying',
    skip: !captureFounderEvidence,
    (tester) async {
      final work = liveStore()
        ..applyConfirmedWorkspaceGroupBuyPayment(
          productName: 'Premium red onion',
          specification: 'Grade A · 45 mm+ · 25 kg mesh bags',
          targetQuantity: 1000,
          securedQuantity: 280,
          unitLabel: 'kg',
          regularUnitPrice: 18,
          groupUnitPrice: 14,
          facilitationFee: 200,
          deliveryFee: 0,
          confirmationAmount: 3920,
          paymentReference: 'PAY-REVIEW-001',
          closingLabel: '5 Sep · 8:00 PM',
          storeDeliveryLabel: '7 Sep · Door delivery',
        );
      await captureActivityDeck(
        tester,
        work: work,
        fileName: 'store-group-bulk-buying-412x915.png',
        afterMount: () async {
          await tester.tap(find.byKey(const Key('work-quick-group-buy')));
        },
      );
    },
  );

  testWidgets(
    'founder destination capture - customer storefront preview',
    skip: !captureFounderEvidence,
    (tester) async {
      await captureActivityDeck(
        tester,
        work: liveStore(),
        fileName: 'destination-customer-storefront-412x915.png',
        afterMount: () async {
          await tester.tap(find.byKey(const Key('work-business-drawer')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('work-business-storefront')));
        },
      );
    },
  );

  testWidgets(
    'founder destination capture - comprehensive product editor',
    skip: !captureFounderEvidence,
    (tester) async {
      await captureActivityDeck(
        tester,
        work: liveStore(),
        fileName: 'destination-product-editor-412x915.png',
        target: find.byType(Overlay).last,
        afterMount: () async {
          await tester.tap(find.byKey(const Key('work-store-stock')));
          await tester.pumpAndSettle();
          final edit = find.byWidgetPredicate((widget) {
            final key = widget.key;
            return key is ValueKey<String> &&
                key.value.startsWith('work-catalogue-edit-');
          }).first;
          await tester.tap(edit);
        },
      );
    },
  );

  testWidgets(
    'founder correction capture - exact Workspace product in Buy',
    skip: !captureFounderEvidence,
    (tester) async {
      final work = liveStore();
      await mount(
        tester,
        route:
            '/app/buy?view=product&product=oil-fortune-1l&workspaceProduct=oil-fortune-1l&return=/app/work/workspace/dashboard',
        work: work,
        viewport: const Size(412, 915),
        textScale: 1.4,
        bottomInset: 34,
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(Scaffold).first,
        matchesGoldenFile(
          '../../../artifacts/quality/work-store-atomic-r62-50-local-review-20260903/destination-workspace-public-buy-product-412x915.png',
        ),
      );
    },
  );

  testWidgets(
    'founder destination capture - compact reject decision',
    skip: !captureFounderEvidence,
    (tester) async {
      final work = liveStore();
      seedIncomingOrder(work);
      await captureActivityDeck(
        tester,
        work: work,
        fileName: 'destination-reject-order-412x915.png',
        target: find.byType(Overlay).last,
        afterMount: () async {
          await tester.tap(find.byKey(const Key('work-activity-order-reject')));
        },
      );
    },
  );

  testWidgets(
    'founder correction capture - Workspace switcher',
    skip: !captureFounderEvidence,
    (tester) async {
      final work = liveStore()..seedMultipleWorkspaces();
      await captureActivityDeck(
        tester,
        work: work,
        fileName: 'correction-workspace-switcher-412x915.png',
        target: find.byType(Overlay).last,
        afterMount: () async {
          await tester.tap(
            find.byKey(const Key('work-dashboard-workspace-switcher')),
          );
        },
      );
    },
  );

  testWidgets(
    'founder correction capture - order completion sheet',
    skip: !captureFounderEvidence,
    (tester) async {
      final work = liveStore();
      await captureActivityDeck(
        tester,
        work: work,
        fileName: 'correction-order-completion-412x915.png',
        target: find.byType(Overlay).last,
        afterMount: () async {
          await tester.tap(find.byKey(const Key('work-quick-new-sale')));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byKey(const Key('work-order-customer')),
            '9829012345',
          );
          await tester.tap(
            find.byKey(const Key('work-order-add-oil-fortune-1l')),
          );
          await tester.pump();
          await tester.tap(find.byKey(const Key('work-order-review')));
        },
      );
    },
  );

  testWidgets(
    'founder correction capture - pickup ready',
    skip: !captureFounderEvidence,
    (tester) async {
      final work = liveStore();
      seedIncomingOrder(work, stage: 'Preparing');
      for (final line in work.workspacePackingLines) {
        work.setWorkspacePackingLine(line.id, true);
      }
      await captureActivityDeck(
        tester,
        work: work,
        fileName: 'correction-pickup-ready-412x915.png',
        afterMount: () async {
          await tester.tap(find.byKey(const Key('work-activity-mark-ready')));
        },
      );
    },
  );

  testWidgets(
    'founder correction capture - invoice handoff',
    skip: !captureFounderEvidence,
    (tester) async {
      final work = liveStore();
      seedIncomingOrder(work, stage: 'Preparing');
      for (final line in work.workspacePackingLines) {
        work.setWorkspacePackingLine(line.id, true);
      }
      await captureActivityDeck(
        tester,
        work: work,
        fileName: 'correction-invoice-handoff-412x915.png',
        target: find.byType(Overlay).last,
        afterMount: () async {
          await tester.tap(find.byKey(const Key('work-activity-mark-ready')));
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(const Key('work-confirm-customer-pickup')),
          );
        },
      );
    },
  );

  testWidgets(
    'founder correction capture - Store offers',
    skip: !captureFounderEvidence,
    (tester) async {
      await captureActivityDeck(
        tester,
        work: liveStore(),
        fileName: 'correction-store-offers-412x915.png',
        afterMount: () async {
          await tester.tap(find.byKey(const Key('work-business-drawer')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('work-business-grow')));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Offers'));
        },
      );
    },
  );

  testWidgets(
    'founder correction capture - funded Store work',
    skip: !captureFounderEvidence,
    (tester) async {
      await captureActivityDeck(
        tester,
        work: liveStore(),
        fileName: 'correction-funded-store-work-412x915.png',
        afterMount: () async {
          await tester.tap(find.byKey(const Key('work-business-drawer')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('work-business-grow')));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Publish paid work'));
        },
      );
    },
  );

  testWidgets(
    'founder correction capture - approved business record',
    skip: !captureFounderEvidence,
    (tester) async {
      await captureActivityDeck(
        tester,
        work: liveStore(),
        fileName: 'correction-approved-business-record-412x915.png',
        afterMount: () async {
          await tester.tap(find.byKey(const Key('work-dashboard-settings')));
          await tester.pumpAndSettle();
          await reveal(tester, find.text('Business details and documents'));
          await tester.tap(find.text('Business details and documents'));
        },
      );
    },
  );

  testWidgets('first-tap commands open the intended Store destinations', (
    tester,
  ) async {
    final work = liveStore();
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);

    await tester.tap(find.byKey(const Key('work-quick-new-sale')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('work-dashboard-counter-order-screen')),
      findsOne,
    );
    expect(work.workspaceOrderSource, 'Counter');
    expect(work.workspaceOrderNeedsDelivery, isFalse);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-quick-delivery')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('work-dashboard-counter-order-screen')),
      findsOne,
    );
    expect(work.workspaceOrderSource, 'Phone');
    expect(work.workspaceOrderNeedsDelivery, isTrue);
    expect(work.workspaceOrderFulfilment, 'Mool delivery');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Business drawer opens Customers Money and Grow destinations', (
    tester,
  ) async {
    final work = liveStore();
    seedIncomingOrder(work);
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);

    await tester.tap(find.byKey(const Key('work-business-drawer')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-business-customers')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-customers-destination')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-business-drawer')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-business-money')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-money-destination')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-business-drawer')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-business-grow')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-grow-destination')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'founder destination capture - Orders',
    skip: !captureFounderEvidence,
    (tester) async {
      final work = liveStore();
      seedIncomingOrder(work);
      await captureActivityDeck(
        tester,
        work: work,
        fileName: 'destination-orders-412x915.png',
        afterMount: () async {
          await tester.tap(find.byKey(const Key('work-store-orders')));
        },
      );
    },
  );

  testWidgets(
    'founder destination capture - New Sale',
    skip: !captureFounderEvidence,
    (tester) async {
      await captureActivityDeck(
        tester,
        work: liveStore(),
        fileName: 'destination-new-sale-412x915.png',
        afterMount: () async {
          await tester.tap(find.byKey(const Key('work-quick-new-sale')));
        },
      );
    },
  );

  testWidgets(
    'founder destination capture - Deliver Order',
    skip: !captureFounderEvidence,
    (tester) async {
      await captureActivityDeck(
        tester,
        work: liveStore(),
        fileName: 'destination-deliver-order-412x915.png',
        afterMount: () async {
          await tester.tap(find.byKey(const Key('work-quick-delivery')));
        },
      );
    },
  );

  testWidgets(
    'founder destination capture - Buy Stock',
    skip: !captureFounderEvidence,
    (tester) async {
      await captureActivityDeck(
        tester,
        work: liveStore(),
        fileName: 'destination-buy-stock-412x915.png',
        afterMount: () async {
          await tester.tap(find.byKey(const Key('work-quick-buy')));
        },
      );
    },
  );

  testWidgets(
    'founder destination capture - Customers',
    skip: !captureFounderEvidence,
    (tester) async {
      final work = liveStore();
      seedIncomingOrder(work);
      await captureActivityDeck(
        tester,
        work: work,
        fileName: 'destination-customers-412x915.png',
        afterMount: () async {
          await tester.tap(find.byKey(const Key('work-business-drawer')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('work-business-customers')));
        },
      );
    },
  );

  testWidgets(
    'founder destination capture - Money',
    skip: !captureFounderEvidence,
    (tester) async {
      final work = liveStore()
        ..workspaceSalesToday = 28450
        ..workspaceCompletedSalesCount = 42
        ..workspaceSettlementBalance = 17820;
      await captureActivityDeck(
        tester,
        work: work,
        fileName: 'destination-money-412x915.png',
        afterMount: () async {
          await tester.tap(find.byKey(const Key('work-business-drawer')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('work-business-money')));
        },
      );
    },
  );

  testWidgets(
    'founder destination capture - Grow',
    skip: !captureFounderEvidence,
    (tester) async {
      await captureActivityDeck(
        tester,
        work: liveStore(),
        fileName: 'destination-grow-412x915.png',
        afterMount: () async {
          await tester.tap(find.byKey(const Key('work-business-drawer')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('work-business-grow')));
        },
      );
    },
  );
}
