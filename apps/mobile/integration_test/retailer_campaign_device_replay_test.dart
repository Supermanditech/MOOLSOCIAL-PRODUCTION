import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/retailer/retailer_campaign_models.dart';
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

  testWidgets(
    'physical retailer sends one permitted reminder and publishes one capped campaign',
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
          initialLocation: '/app/retailer/customers',
        ),
      );
      await tester.pumpAndSettle();
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('customers-screen')), findsOneWidget);
      await binding.takeScreenshot('retailer-97-customers');
      await tapVisible(tester, const Key('customer-sharma'));
      expect(find.byKey(const Key('customer-detail-screen')), findsOneWidget);
      await binding.takeScreenshot('retailer-98-customer-detail');
      final ordersBefore = retailer.orders.length;
      await tapVisible(tester, const Key('send-customer-reminder'));
      expect(retailer.reminderMessageId, 'MSG-98071');
      expect(retailer.orders.length, ordersBefore);
      await binding.takeScreenshot('retailer-98-reminder-sent');

      await tapVisible(tester, const Key('retailer-back'));
      await tapVisible(tester, const Key('customers-open-campaigns'));
      expect(find.byKey(const Key('campaigns-screen')), findsOneWidget);
      await binding.takeScreenshot('retailer-99-campaigns');
      await tapVisible(tester, const Key('campaign-create'));
      expect(find.byKey(const Key('campaign-outcome-step')), findsOneWidget);
      await tapVisible(tester, const Key('campaign-continue'));
      expect(find.byKey(const Key('campaign-products-step')), findsOneWidget);
      await tapVisible(tester, const Key('campaign-benefit-freeDelivery'));
      expect(retailer.campaignBenefit, RetailerCampaignBenefit.freeDelivery);
      await tapVisible(tester, const Key('campaign-continue'));
      await tapVisible(tester, const Key('campaign-channel-permittedWhatsApp'));
      await tapVisible(tester, const Key('campaign-continue'));
      expect(find.byKey(const Key('campaign-review-step')), findsOneWidget);
      await binding.takeScreenshot('retailer-100-campaign-review');
      final campaignCount = retailer.campaigns.length;
      await tapVisible(tester, const Key('campaign-continue'));
      expect(find.byKey(const Key('campaigns-screen')), findsOneWidget);
      expect(retailer.publishedCampaignId, 'CMP-10001');
      expect(retailer.campaigns.length, campaignCount + 1);
      expect(retailer.campaigns.first.state, RetailerCampaignState.active);
      await binding.takeScreenshot('retailer-100-campaign-published');
    },
  );
}
