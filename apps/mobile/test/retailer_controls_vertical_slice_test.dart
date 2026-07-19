import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/retailer/retailer_control_models.dart';
import 'package:moolsocial/features/retailer/retailer_control_services.dart';
import 'package:moolsocial/features/retailer/retailer_session.dart';

void main() {
  Future<void> settle(WidgetTester tester) => tester.pumpAndSettle(
    const Duration(milliseconds: 40),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 5),
  );

  Future<RetailerSession> mount(
    WidgetTester tester, {
    required String route,
    RetailerSession? retailerSession,
    Size size = const Size(412, 915),
  }) async {
    await tester.binding.setSurfaceSize(size);
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
    final retailer = retailerSession ?? RetailerSession();
    await journey.start();
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      journey.dispose();
      retailer.dispose();
    });
    await tester.pumpWidget(
      MoolSocialApp(
        key: UniqueKey(),
        session: journey,
        retailerSession: retailer,
        initialLocation: route,
      ),
    );
    await settle(tester);
    return retailer;
  }

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
    await settle(tester);
    return finder;
  }

  Future<void> tap(WidgetTester tester, Key key) async {
    await tester.tap(await reveal(tester, key));
    await settle(tester);
  }

  Future<void> enter(WidgetTester tester, Key key, String value) async {
    await tester.enterText(await reveal(tester, key), value);
    await settle(tester);
  }

  testWidgets(
    'screen 101 covers every stock, recovery route, invalid bound and two-stage publish',
    (tester) async {
      final session = await mount(
        tester,
        route: '/app/retailer/home?view=stock&panel=recovery',
      );
      expect(find.byKey(const Key('slow-stock-screen')), findsOneWidget);
      for (final product in reviewSlowStock) {
        await tap(tester, Key('recovery-product-${product.id}'));
        expect(session.recoveryProductId, product.id);
      }
      for (final route in RetailerRecoveryRoute.values) {
        await tap(tester, Key('recovery-route-${route.name}'));
        expect(session.recoveryRoute, route);
      }
      session.selectRecoveryProduct('juice');
      expect(session.setRecoveryQuantity(19), isFalse);
      expect(session.setRecoveryQuantity(18), isTrue);
      expect(session.setRecoveryFloor(0), isFalse);
      expect(session.setRecoveryFloor(72), isTrue);
      await tap(tester, const Key('recovery-review-publish'));
      expect(session.recoveryReviewed, isTrue);
      await tap(tester, const Key('recovery-review-publish'));
      expect(session.recoveryId, 'REC-101-0715');
    },
  );

  testWidgets(
    'screen 101 exact failure replay, duplicate and offline preserve stock',
    (tester) async {
      final gateway = ReviewRetailerControlGateway()
        ..failPublishRecovery = true;
      final session = RetailerSession(controlGateway: gateway);
      await mount(
        tester,
        route: '/app/retailer/home?view=stock&panel=recovery',
        retailerSession: session,
      );
      expect(await tester.runAsync(session.reviewOrPublishRecovery), isTrue);
      expect(await tester.runAsync(session.reviewOrPublishRecovery), isFalse);
      expect(session.recoveryId, isNull);
      expect(await tester.runAsync(session.reviewOrPublishRecovery), isTrue);
      expect(await tester.runAsync(session.reviewOrPublishRecovery), isTrue);
      expect(gateway.recoveryCalls, 2);
      session.recoveryId = null;
      session.setControlsOnline(false);
      expect(await tester.runAsync(session.reviewOrPublishRecovery), isFalse);
      expect(gateway.recoveryCalls, 2);
    },
  );

  testWidgets(
    'screen 102 prompts, failed answer replay, dismiss, history and review routes complete',
    (tester) async {
      final gateway = ReviewRetailerControlGateway()..failAskAi = true;
      final session = RetailerSession(controlGateway: gateway);
      await mount(
        tester,
        route: '/app/retailer?panel=ai',
        retailerSession: session,
      );
      expect(find.byKey(const Key('retailer-ai-screen')), findsOneWidget);
      for (final prompt in ['restock', 'slow', 'dues', 'offer', 'profit']) {
        await tap(tester, Key('ai-prompt-$prompt'));
        expect(session.aiPrompt, isNotEmpty);
      }
      session.setAiPrompt('Which stock is moving slowly?');
      expect(await tester.runAsync(session.askRetailerAi), isFalse);
      expect(session.aiAnswer, isNull);
      expect(await tester.runAsync(session.askRetailerAi), isTrue);
      expect(session.aiAnswer, contains('Eighteen'));
      expect(gateway.askCalls, 2);
      await tap(tester, const Key('ai-history'));
      expect(find.byKey(const Key('ai-history-sheet')), findsOneWidget);
      await tap(tester, const Key('ai-history-close'));
      await tap(tester, const Key('ai-proposal-purchase-dismiss'));
      expect(session.dismissedAiActions, contains('purchase'));
      await tap(tester, const Key('ai-proposal-offer-review'));
      expect(find.byKey(const Key('slow-stock-screen')), findsOneWidget);
    },
  );

  testWidgets(
    'screen 103 invite validates, fails, retries once and duplicate creates no access',
    (tester) async {
      final gateway = ReviewRetailerControlGateway()..failInvite = true;
      final session = RetailerSession(controlGateway: gateway);
      await mount(
        tester,
        route: '/app/retailer/settings/team',
        retailerSession: session,
      );
      await tap(tester, const Key('staff-add'));
      expect(find.byKey(const Key('staff-invite-panel')), findsOneWidget);
      await enter(tester, const Key('staff-invite-mobile'), '123');
      expect(await tester.runAsync(session.sendStaffInvite), isFalse);
      expect(gateway.inviteCalls, 0);
      session.setInviteMobile('98765 11223');
      expect(await tester.runAsync(session.sendStaffInvite), isFalse);
      expect(await tester.runAsync(session.sendStaffInvite), isTrue);
      expect(await tester.runAsync(session.sendStaffInvite), isTrue);
      expect(gateway.inviteCalls, 2);
      expect(session.staffInviteId, 'INV-103-0715');
    },
  );

  testWidgets(
    'screen 103 manage cancellation, exact failed change replay and security branches complete',
    (tester) async {
      final gateway = ReviewRetailerControlGateway()..failStaffChange = true;
      final session = RetailerSession(controlGateway: gateway);
      await mount(
        tester,
        route: '/app/retailer/settings/team',
        retailerSession: session,
      );
      await tap(tester, const Key('staff-rakesh'));
      await tap(tester, const Key('staff-manage-cancel'));
      expect(
        session.staff.firstWhere((item) => item.id == 'rakesh').paused,
        isFalse,
      );
      await tap(tester, const Key('staff-rakesh'));
      await tap(tester, const Key('staff-toggle-access'));
      expect(session.errorMessage, contains('not changed'));
      await tap(tester, const Key('staff-toggle-access'));
      expect(
        session.staff.firstWhere((item) => item.id == 'rakesh').paused,
        isTrue,
      );
      await tap(tester, const Key('staff-devices'));
      expect(find.byKey(const Key('staff-devices-sheet')), findsOneWidget);
      await tap(tester, const Key('staff-security-close'));
      await tap(tester, const Key('staff-history'));
      expect(find.byKey(const Key('staff-history-sheet')), findsOneWidget);
    },
  );

  testWidgets(
    'screen 104 toggles, edit sheet, readiness, failed save replay and duplicate version complete',
    (tester) async {
      final gateway = ReviewRetailerControlGateway()..failSaveSettings = true;
      final session = RetailerSession(controlGateway: gateway);
      await mount(
        tester,
        route: '/app/retailer/settings',
        retailerSession: session,
      );
      await tap(tester, const Key('settings-readiness'));
      expect(session.licenceAttention, isTrue);
      await tap(tester, const Key('settings-orders'));
      expect(session.acceptAppOrders, isFalse);
      await tap(tester, const Key('settings-profile'));
      expect(find.byKey(const Key('settings-edit-sheet')), findsOneWidget);
      await tap(tester, const Key('settings-edit-done'));
      expect(await tester.runAsync(session.saveStoreSettings), isFalse);
      expect(session.settingsVersion, isNull);
      expect(await tester.runAsync(session.saveStoreSettings), isTrue);
      expect(await tester.runAsync(session.saveStoreSettings), isTrue);
      expect(gateway.settingsCalls, 2);
    },
  );

  testWidgets(
    'screen 105 filters, every case, every outcome, failed resolution replay and duplicate complete',
    (tester) async {
      final gateway = ReviewRetailerControlGateway()..failResolveIssue = true;
      final session = RetailerSession(controlGateway: gateway);
      await mount(
        tester,
        route: '/app/retailer/orders/issues',
        retailerSession: session,
      );
      for (final filter in RetailerIssueFilter.values) {
        await tap(tester, Key('issue-filter-${filter.name}'));
        expect(session.issueFilter, filter);
      }
      session.setIssueFilter(RetailerIssueFilter.all);
      await settle(tester);
      for (final issue in session.customerIssues) {
        await tap(tester, Key('issue-${issue.id}'));
        expect(session.selectedIssueId, issue.id);
      }
      session.selectIssue('MS-2848');
      await settle(tester);
      for (final resolution in RetailerIssueResolution.values) {
        await tap(tester, Key('issue-resolution-${resolution.name}'));
        expect(session.issueResolution, resolution);
      }
      session.setIssueMessage('short');
      expect(await tester.runAsync(session.resolveCustomerIssue), isFalse);
      expect(gateway.issueCalls, 0);
      session.setIssueMessage(
        'We reviewed the evidence and will complete this outcome today.',
      );
      expect(await tester.runAsync(session.resolveCustomerIssue), isFalse);
      expect(await tester.runAsync(session.resolveCustomerIssue), isTrue);
      expect(await tester.runAsync(session.resolveCustomerIssue), isTrue);
      expect(gateway.issueCalls, 2);
      expect(session.issueResolutionId, 'RES-105-0715');
    },
  );

  testWidgets(
    'offline and role denial call no control gateway and preserve every protected outcome',
    (tester) async {
      final gateway = ReviewRetailerControlGateway();
      final session = RetailerSession(controlGateway: gateway);
      await mount(
        tester,
        route: '/app/retailer/settings',
        retailerSession: session,
      );
      session.setControlsOnline(false);
      expect(await tester.runAsync(session.askRetailerAi), isFalse);
      expect(await tester.runAsync(session.sendStaffInvite), isFalse);
      expect(await tester.runAsync(session.saveStoreSettings), isFalse);
      expect(await tester.runAsync(session.resolveCustomerIssue), isFalse);
      session.setControlsOnline(true);
      session.controlsAuthorized = false;
      expect(await tester.runAsync(session.askRetailerAi), isFalse);
      expect(await tester.runAsync(session.sendStaffInvite), isFalse);
      expect(await tester.runAsync(session.saveStoreSettings), isFalse);
      expect(await tester.runAsync(session.resolveCustomerIssue), isFalse);
      expect(gateway.askCalls, 0);
      expect(gateway.inviteCalls, 0);
      expect(gateway.settingsCalls, 0);
      expect(gateway.issueCalls, 0);
    },
  );

  testWidgets(
    'retailer home and stock expose the embedded AI, settings and recovery owners',
    (tester) async {
      await mount(tester, route: '/app/retailer/home');
      await tap(tester, const Key('retailer-ai'));
      expect(find.byKey(const Key('retailer-ai-screen')), findsOneWidget);
      await tap(tester, const Key('retailer-back'));
      await tap(tester, const Key('retailer-settings'));
      expect(find.byKey(const Key('store-settings-screen')), findsOneWidget);
      await tap(tester, const Key('retailer-back'));
      await tap(tester, const Key('retailer-open-stock'));
      await tap(tester, const Key('retailer-slow-stock'));
      expect(find.byKey(const Key('slow-stock-screen')), findsOneWidget);
    },
  );
}
