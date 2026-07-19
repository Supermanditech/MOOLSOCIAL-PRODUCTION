import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/retailer/retailer_business_services_models.dart';
import 'package:moolsocial/features/retailer/retailer_campaign_models.dart';
import 'package:moolsocial/features/retailer/retailer_campaign_services.dart';
import 'package:moolsocial/features/retailer/retailer_session.dart';

void main() {
  Future<void> settle(WidgetTester tester) => tester.pumpAndSettle(
    const Duration(milliseconds: 40),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 5),
  );

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

  Future<RetailerSession> mount(
    WidgetTester tester, {
    required String route,
    RetailerSession? retailerSession,
    Size size = const Size(412, 915),
  }) async {
    await tester.binding.setSurfaceSize(size);
    final journey = await readyJourney();
    final retailer = retailerSession ?? RetailerSession();
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      journey.dispose();
      retailer.dispose();
    });
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: size),
        child: MoolSocialApp(
          key: UniqueKey(),
          session: journey,
          retailerSession: retailer,
          initialLocation: route,
        ),
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
    'screen 97 completes search, voice, all filters, empty recovery and customer open',
    (tester) async {
      final session = await mount(tester, route: '/app/retailer/customers');

      expect(find.byKey(const Key('customers-screen')), findsOneWidget);
      for (final filter in RetailerCustomerFilter.values) {
        await tap(tester, Key('customer-filter-${filter.name}'));
        expect(session.customerFilter, filter);
      }
      await enter(tester, const Key('customer-search'), 'no result');
      expect(find.byKey(const Key('customers-empty')), findsOneWidget);
      session.setCustomerFilter(RetailerCustomerFilter.all);
      await settle(tester);
      await tap(tester, const Key('customer-voice-search'));
      expect(session.customerSearchQuery, 'Sharma Family');
      expect(find.byKey(const Key('customer-sharma')), findsOneWidget);
      await tap(tester, const Key('customer-sharma'));
      expect(find.byKey(const Key('customer-detail-screen')), findsOneWidget);
    },
  );

  testWidgets(
    'screen 97 exact refresh failure replays to success and offline changes nothing',
    (tester) async {
      final gateway = ReviewRetailerCampaignGateway()
        ..failRefreshCustomers = true;
      final session = RetailerSession(campaignGateway: gateway);
      await mount(
        tester,
        route: '/app/retailer/customers',
        retailerSession: session,
      );

      expect(await tester.runAsync(session.refreshCustomers), isFalse);
      await settle(tester);
      expect(find.byKey(const Key('retailer-error')), findsOneWidget);
      expect(await tester.runAsync(session.refreshCustomers), isTrue);
      expect(gateway.refreshCustomersCalls, 2);
      session.setCustomerCampaignOnline(false);
      expect(await tester.runAsync(session.refreshCustomers), isFalse);
      expect(gateway.refreshCustomersCalls, 2);
    },
  );

  testWidgets(
    'screen 98 enforces channel consent and replays failed reminder once without creating order',
    (tester) async {
      final gateway = ReviewRetailerCampaignGateway()..failSendReminder = true;
      final session = RetailerSession(campaignGateway: gateway);
      await mount(
        tester,
        route: '/app/retailer/customers/sharma',
        retailerSession: session,
      );

      session.setReminderChannel(RetailerMessageChannel.sms);
      expect(session.errorMessage, contains('SMS is off'));
      session.setReminderChannel(RetailerMessageChannel.whatsapp);
      final ordersBefore = session.orders.length;
      expect(await tester.runAsync(session.sendCustomerReminder), isFalse);
      expect(session.reminderMessageId, isNull);
      expect(await tester.runAsync(session.sendCustomerReminder), isTrue);
      expect(session.reminderMessageId, 'MSG-98071');
      expect(session.orders.length, ordersBefore);
      expect(await tester.runAsync(session.sendCustomerReminder), isTrue);
      expect(gateway.sendReminderCalls, 2);
      expect(session.orders.length, ordersBefore);
    },
  );

  testWidgets(
    'screen 98 opens repeat order, sales history, resolved proof and message log',
    (tester) async {
      final session = RetailerSession();
      await mount(
        tester,
        route: '/app/retailer/customers/sharma',
        retailerSession: session,
      );

      await tap(tester, const Key('customer-edit-basket'));
      expect(session.noticeMessage, contains('ready to edit'));
      await tap(tester, const Key('customer-resolved-issue'));
      expect(session.noticeMessage, contains('resolved'));
      await tap(tester, const Key('customer-invoice-2840'));
      expect(find.text('Sales Book'), findsWidgets);
    },
  );

  testWidgets(
    'screen 99 completes filters and cancel, failure, retry and duplicate pause lifecycle',
    (tester) async {
      final gateway = ReviewRetailerCampaignGateway()..failPause = true;
      final session = RetailerSession(campaignGateway: gateway);
      await mount(
        tester,
        route: '/app/retailer/campaigns',
        retailerSession: session,
      );

      for (final filter in RetailerCampaignFilter.values) {
        await tap(tester, Key('campaign-filter-${filter.name}'));
        expect(session.campaignFilter, filter);
      }
      session.setCampaignFilter(RetailerCampaignFilter.all);
      await settle(tester);
      await tap(tester, const Key('campaign-pause-monthly'));
      await tap(tester, const Key('pause-campaign-cancel'));
      expect(
        session.campaigns.firstWhere((item) => item.id == 'monthly').state,
        RetailerCampaignState.active,
      );
      await tap(tester, const Key('campaign-pause-monthly'));
      await tap(tester, const Key('pause-campaign-confirm'));
      expect(session.errorMessage, contains('could not be paused'));
      expect(
        session.campaigns.firstWhere((item) => item.id == 'monthly').state,
        RetailerCampaignState.active,
      );
      expect(
        await tester.runAsync(() => session.pauseCampaign('monthly')),
        isTrue,
      );
      expect(
        await tester.runAsync(() => session.pauseCampaign('monthly')),
        isTrue,
      );
      expect(gateway.pauseCalls, 2);
    },
  );

  testWidgets(
    'screen 99 cancel, failed delete and exact retry removes only the draft',
    (tester) async {
      final gateway = ReviewRetailerCampaignGateway()..failDelete = true;
      final session = RetailerSession(campaignGateway: gateway);
      await mount(
        tester,
        route: '/app/retailer/campaigns',
        retailerSession: session,
      );

      await tap(tester, const Key('campaign-delete-oil'));
      await tap(tester, const Key('delete-campaign-cancel'));
      expect(session.campaigns.any((item) => item.id == 'oil'), isTrue);
      await tap(tester, const Key('campaign-delete-oil'));
      await tap(tester, const Key('delete-campaign-confirm'));
      expect(session.campaigns.any((item) => item.id == 'oil'), isTrue);
      expect(
        await tester.runAsync(() => session.deleteCampaignDraft('oil')),
        isTrue,
      );
      expect(session.campaigns.any((item) => item.id == 'oil'), isFalse);
      expect(gateway.deleteCalls, 2);
    },
  );

  testWidgets(
    'screen 100 validates outcome and stock cap then completes every builder step',
    (tester) async {
      final session = await mount(tester, route: '/app/retailer/campaigns/new');

      await enter(tester, const Key('campaign-name'), '');
      await tap(tester, const Key('campaign-continue'));
      expect(session.campaignBuilderStep, 0);
      expect(session.errorMessage, contains('campaign name'));
      await enter(tester, const Key('campaign-name'), 'Jodhpur staples');
      await tap(tester, const Key('campaign-continue'));
      expect(session.campaignBuilderStep, 1);
      expect(session.setCampaignMaximumOrders(40), isFalse);
      expect(session.campaignMaximumOrders, 30);
      expect(session.setCampaignMaximumOrders(18), isTrue);
      await tap(tester, const Key('campaign-product-rice'));
      expect(session.campaignProductIds, contains('rice'));
      await tap(tester, const Key('campaign-continue'));
      expect(session.campaignBuilderStep, 2);
      await tap(tester, const Key('campaign-audience-loyaltyEligible'));
      await tap(tester, const Key('campaign-channel-permittedWhatsApp'));
      await tap(tester, const Key('campaign-continue'));
      expect(session.campaignBuilderStep, 3);
      expect(find.byKey(const Key('campaign-review-step')), findsOneWidget);
    },
  );

  testWidgets(
    'screen 100 exact draft and publish failures replay once and duplicate submits stay idempotent',
    (tester) async {
      final gateway = ReviewRetailerCampaignGateway()
        ..failSaveDraft = true
        ..failPublish = true;
      final session = RetailerSession(campaignGateway: gateway);
      await mount(
        tester,
        route: '/app/retailer/campaigns/new',
        retailerSession: session,
      );

      expect(await tester.runAsync(session.saveCampaignDraft), isFalse);
      expect(session.campaignDraftId, isNull);
      expect(await tester.runAsync(session.saveCampaignDraft), isTrue);
      expect(await tester.runAsync(session.saveCampaignDraft), isTrue);
      expect(gateway.saveDraftCalls, 2);
      session.campaignBuilderStep = 3;
      expect(await tester.runAsync(session.publishCampaign), isFalse);
      expect(session.publishedCampaignId, isNull);
      final countBefore = session.campaigns.length;
      expect(await tester.runAsync(session.publishCampaign), isTrue);
      expect(session.campaigns.length, countBefore + 1);
      expect(await tester.runAsync(session.publishCampaign), isTrue);
      expect(gateway.publishCalls, 2);
      expect(session.campaigns.length, countBefore + 1);
    },
  );

  testWidgets(
    'offline and unauthorized paths preserve customer and campaign state',
    (tester) async {
      final gateway = ReviewRetailerCampaignGateway();
      final session = RetailerSession(campaignGateway: gateway);
      await mount(
        tester,
        route: '/app/retailer/campaigns/new',
        retailerSession: session,
      );

      session.setCustomerCampaignOnline(false);
      expect(await tester.runAsync(session.saveCampaignDraft), isFalse);
      expect(await tester.runAsync(session.publishCampaign), isFalse);
      expect(session.campaignDraftId, isNull);
      expect(session.publishedCampaignId, isNull);
      expect(gateway.saveDraftCalls, 0);
      expect(gateway.publishCalls, 0);
      session.setCustomerCampaignOnline(true);
      session.customerCampaignAuthorized = false;
      expect(await tester.runAsync(session.saveCampaignDraft), isFalse);
      expect(await tester.runAsync(session.publishCampaign), isFalse);
      expect(gateway.saveDraftCalls, 0);
      expect(gateway.publishCalls, 0);
    },
  );

  testWidgets(
    'retailer home and active growth service reach real customer and campaign work',
    (tester) async {
      final session = RetailerSession();
      final growth = retailerBusinessServiceByName('growth');
      session.selectBusinessService(growth);
      session.setBusinessServiceCommercialConsent(true);
      expect(await tester.runAsync(session.activateBusinessService), isTrue);
      await mount(
        tester,
        route: '/app/retailer/home',
        retailerSession: session,
      );

      await tap(tester, const Key('retailer-customers'));
      expect(find.byKey(const Key('customers-screen')), findsOneWidget);
      await tap(tester, const Key('retailer-back'));
      await tap(tester, const Key('retailer-campaigns'));
      expect(find.byKey(const Key('campaigns-screen')), findsOneWidget);
    },
  );
}
