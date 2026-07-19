import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/retailer/retailer_control_models.dart';
import 'package:moolsocial/features/retailer/retailer_session.dart';

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
    'physical retailer completes recovery, assisted action, access, settings and issue outcomes',
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
      final retailer = RetailerSession();
      addTearDown(journey.dispose);
      addTearDown(retailer.dispose);
      await journey.start();

      await tester.pumpWidget(
        MoolSocialApp(
          session: journey,
          retailerSession: retailer,
          initialLocation: '/app/retailer/home?view=stock&panel=recovery',
        ),
      );
      await tester.pumpAndSettle();
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('slow-stock-screen')), findsOneWidget);
      await binding.takeScreenshot('retailer-101-slow-stock');
      await tapVisible(tester, const Key('recovery-product-juice'));
      await tapVisible(tester, const Key('recovery-route-customerOffer'));
      await tapVisible(tester, const Key('recovery-review-publish'));
      await tapVisible(tester, const Key('recovery-review-publish'));
      expect(retailer.recoveryId, 'REC-101-0715');
      await binding.takeScreenshot('retailer-101-recovery-published');

      await openRoute(tester, '/app/retailer?panel=ai');
      expect(find.byKey(const Key('retailer-ai-screen')), findsOneWidget);
      await tapVisible(tester, const Key('ai-prompt-slow'));
      await tapVisible(tester, const Key('ai-ask'));
      expect(retailer.aiAnswer, contains('Eighteen'));
      await binding.takeScreenshot('retailer-102-ai-grounded-answer');

      await openRoute(tester, '/app/retailer/settings');
      expect(find.byKey(const Key('store-settings-screen')), findsOneWidget);
      await tapVisible(tester, const Key('settings-orders'));
      await tapVisible(tester, const Key('settings-save'));
      expect(retailer.settingsVersion, 'SET-104-0715');
      await binding.takeScreenshot('retailer-104-settings-saved');

      await tapVisible(tester, const Key('settings-team'));
      expect(find.byKey(const Key('staff-screen')), findsOneWidget);
      await tapVisible(tester, const Key('staff-add'));
      await tapVisible(tester, const Key('staff-send-invite'));
      expect(retailer.staffInviteId, 'INV-103-0715');
      await binding.takeScreenshot('retailer-103-staff-invited');

      await openRoute(tester, '/app/retailer/orders/issues');
      expect(find.byKey(const Key('customer-issues-screen')), findsOneWidget);
      await tapVisible(
        tester,
        Key('issue-resolution-${RetailerIssueResolution.refund.name}'),
      );
      await tapVisible(tester, const Key('issue-confirm'));
      expect(retailer.issueResolutionId, 'RES-105-0715');
      await binding.takeScreenshot('retailer-105-issue-resolved');
    },
  );
}
