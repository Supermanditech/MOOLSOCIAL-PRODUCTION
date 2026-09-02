import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/work/work_models.dart';
import 'package:moolsocial/features/work/work_services.dart';
import 'package:moolsocial/features/work/work_session.dart';

void main() {
  Future<void> mount(
    WidgetTester tester, {
    required String route,
    required WorkSession work,
    double bottomInset = 44,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    tester.view.viewPadding = FakeViewPadding(bottom: bottomInset);
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
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
        'Nothing is public until setup passes and you choose Finish setup and go live.',
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
      expect(tester.takeException(), isNull);
    },
  );

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
    expect(find.text('Mahadev Fresh Mart'), findsNothing);
    expect(find.byKey(const Key('work-dashboard-inline-header')), findsOne);
    expect(find.byKey(const Key('work-page-title')), findsNothing);
    expect(find.byKey(const Key('work-dashboard-account-state')), findsNothing);
    expect(
      find.byKey(const Key('work-dashboard-command-centre')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('work-dashboard-store-state')), findsOneWidget);
    expect(find.byKey(const Key('work-sticky-action-bar')), findsNothing);
    expect(find.byKey(const Key('work-local-navigation')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('retail dashboard exposes the four connected control surfaces', (
    tester,
  ) async {
    final work = WorkSession()..seedVerifiedWorkspace();
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);

    expect(find.byKey(const Key('work-dashboard-hero')), findsNothing);
    for (final keyName in const [
      'work-dashboard-search',
      'work-dashboard-alerts',
      'work-dashboard-profile',
      'work-dashboard-command-centre',
      'work-dashboard-store-state',
      'work-dashboard-public-preview',
      'work-dashboard-orders',
      'work-dashboard-create-order',
      'work-dashboard-products',
      'work-dashboard-delivery',
    ]) {
      await reveal(tester, find.byKey(Key(keyName)));
      expect(find.byKey(Key(keyName)), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('retail dashboard Profile opens globally and returns in place', (
    tester,
  ) async {
    final work = WorkSession()..seedVerifiedWorkspace();
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);

    await tester.tap(find.byKey(const Key('work-dashboard-profile')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('global-profile-panel-v2')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-workspace-dashboard')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('store search keeps text stable with keyboard and native Back', (
    tester,
  ) async {
    final work = WorkSession()..seedVerifiedWorkspace();
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);

    await tester.tap(find.byKey(const Key('work-dashboard-search')));
    await tester.pumpAndSettle();
    final field = find.byKey(const Key('work-dashboard-search-field'));
    expect(field, findsOneWidget);
    await tester.enterText(field, 'stock');
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();

    expect(work.workspaceSearchQuery, 'stock');
    expect(find.byKey(const Key('work-search-products')), findsOneWidget);
    expect(find.byKey(const Key('work-search-orders')), findsNothing);
    expect(
      tester.getBottomRight(field).dy,
      lessThanOrEqualTo(
        tester.getTopRight(find.byKey(const Key('work-local-navigation'))).dy,
      ),
    );
    expect(tester.takeException(), isNull);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-workspace-dashboard')), findsOneWidget);
    expect(work.workspaceSearchQuery, 'stock');
  });

  testWidgets(
    'availability saves customer-facing state and Back discards draft',
    (tester) async {
      final work = WorkSession()..seedVerifiedWorkspace();
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
      expect(find.byKey(const Key('work-workspace-dashboard')), findsOneWidget);
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
    expect(find.byKey(const Key('work-alert-contact-details')), findsOneWidget);
    expect(find.text('No urgent store action'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-workspace-dashboard')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'retail operations stay inside Work and counter order survives keyboard',
    (tester) async {
      final work = WorkSession()..seedVerifiedWorkspace();
      await mount(tester, route: '/app/work/workspace/dashboard', work: work);

      await reveal(tester, find.byKey(const Key('work-dashboard-orders')));
      await tester.tap(find.byKey(const Key('work-dashboard-orders')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-dashboard-orders-screen')), findsOne);
      expect(find.text('What would you like to do?'), findsNothing);

      await tester.tap(find.text('Create customer order'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-dashboard-counter-order-screen')),
        findsOne,
      );
      await tester.enterText(
        find.byKey(const Key('work-order-customer')),
        '9829012345',
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      await reveal(
        tester,
        find.byKey(const Key('work-order-add-oil-fortune-1l')),
      );
      await tester.tap(find.byKey(const Key('work-order-add-oil-fortune-1l')));
      await reveal(
        tester,
        find.byKey(const Key('work-order-fulfilment-mool-delivery')),
      );
      await tester.tap(
        find.byKey(const Key('work-order-fulfilment-mool-delivery')),
      );
      await reveal(tester, find.byKey(const Key('work-order-address')));
      await tester.enterText(
        find.byKey(const Key('work-order-address')),
        '12 Market Road, Sardarpura',
      );
      await reveal(tester, find.byKey(const Key('work-order-save')));
      await tester.tap(find.byKey(const Key('work-order-save')));
      await tester.pumpAndSettle();

      expect(work.workspaceOrderCustomer, '9829012345');
      expect(work.workspaceOrderItems, contains('Fortune Sunflower Oil'));
      expect(work.workspaceOrderAmount, '264');
      expect(work.workspaceOrderNeedsDelivery, isTrue);
      expect(work.workspaceOrderAddress, '12 Market Road, Sardarpura');
      expect(find.byKey(const Key('work-dashboard-delivery-screen')), findsOne);
      tester.view.viewInsets = const FakeViewPadding();
      await tester.pumpAndSettle();
      for (var step = 0; step < 3; step++) {
        await reveal(tester, find.byKey(const Key('work-delivery-request')));
        await tester.tap(find.byKey(const Key('work-delivery-request')));
        await tester.pumpAndSettle();
      }
      expect(work.workspaceOrderStage, 'Delivery requested');
      expect(work.workspaceActivity, isNotEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'catalogue keeps internal cost private and publishes customer fields',
    (tester) async {
      final work = WorkSession()..seedVerifiedWorkspace();
      await mount(tester, route: '/app/work/workspace/dashboard', work: work);

      await reveal(tester, find.byKey(const Key('work-dashboard-products')));
      await tester.tap(find.byKey(const Key('work-dashboard-products')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-dashboard-catalogue-screen')),
        findsOneWidget,
      );
      expect(find.text('Price · stock · public status'), findsOneWidget);
      await tester.tap(
        find.byKey(const Key('work-catalogue-edit-oil-fortune-1l')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-product-purchase-price')),
        findsOneWidget,
      );
      expect(
        find.textContaining('Purchase cost remains private'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('work-product-public')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('store state and customer preview complete within two taps', (
    tester,
  ) async {
    final work = WorkSession()
      ..seedVerifiedWorkspace()
      ..reviewStage = WorkReviewStage.live
      ..retailerSetupSaved = true
      ..workspaceVisibleToCustomers = true;
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);

    await tester.tap(find.byKey(const Key('work-dashboard-store-state')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Busy · add 20 minutes'));
    await tester.pumpAndSettle();
    expect(work.workspaceAcceptingOrders, isTrue);
    expect(work.workspaceBusyMinutes, 20);
    expect(find.text('BUSY'), findsOneWidget);

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
    expect(find.text('PRIVATE PREVIEW'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
