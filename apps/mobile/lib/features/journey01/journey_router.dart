import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../book/book_session.dart';
import '../book/screens/book_home_screen.dart';
import '../book/screens/doctor_screens.dart';
import '../book/screens/salon_screens.dart';
import '../book/screens/task_screens.dart';
import '../buy/buy_session.dart';
import '../buy/screens/buy_basket_screen.dart';
import '../buy/screens/buy_catalog_screen.dart';
import '../buy/screens/buy_collection_completed_screen.dart';
import '../buy/screens/buy_collection_screen.dart';
import '../buy/screens/buy_completed_screen.dart';
import '../buy/screens/buy_problem_screen.dart';
import '../buy/screens/buy_product_screen.dart';
import '../buy/screens/buy_review_screen.dart';
import '../buy/screens/buy_tracking_screen.dart';
import '../captain/captain_models.dart';
import '../captain/captain_session.dart';
import '../captain/screens/captain_business_screens.dart';
import '../captain/screens/captain_home_request_screens.dart';
import '../captain/screens/captain_trip_screens.dart';
import '../chat/chat_session.dart';
import '../chat/screens/chat_inbox_screen.dart';
import '../chat/screens/chat_thread_screen.dart';
import '../creator/creator_models.dart';
import '../creator/creator_session.dart';
import '../creator/screens/creator_business_screens.dart';
import '../creator/screens/creator_content_audience_screens.dart';
import '../creator/screens/creator_studio_publish_screens.dart';
import '../creator/screens/youtube_connect_screen.dart';
import '../eat/eat_session.dart';
import '../eat/screens/eat_basket_screen.dart';
import '../eat/screens/eat_completed_screen.dart';
import '../eat/screens/eat_home_screen.dart';
import '../eat/screens/eat_order_screen.dart';
import '../eat/screens/eat_review_screen.dart';
import '../eat/screens/eat_table_confirmation_screen.dart';
import '../eat/screens/eat_table_screen.dart';
import '../eat/screens/eat_tiffin_confirmation_screen.dart';
import '../eat/screens/eat_tiffin_screen.dart';
import '../eat/screens/eat_tracking_screen.dart';
import '../manufacturer/manufacturer_models.dart';
import '../manufacturer/manufacturer_session.dart';
import '../manufacturer/screens/manufacturer_growth_control_screens.dart';
import '../manufacturer/screens/manufacturer_home_book_screens.dart';
import '../manufacturer/screens/manufacturer_sales_screens.dart';
import '../pay/pay_session.dart';
import '../pay/screens/pay_entry_screens.dart';
import '../pay/screens/pay_home_screen.dart';
import '../pay/screens/pay_record_screens.dart';
import '../pay/screens/pay_request_screens.dart';
import '../ride/ride_models.dart';
import '../ride/ride_session.dart';
import '../ride/screens/ride_booking_screen.dart';
import '../ride/screens/ride_support_screen.dart';
import '../ride/screens/ride_trip_screen.dart';
import '../retailer/retailer_models.dart';
import '../retailer/retailer_pos_models.dart';
import '../retailer/retailer_business_services_models.dart';
import '../retailer/retailer_campaign_models.dart';
import '../retailer/retailer_session.dart';
import '../retailer/screens/retailer_business_services_screens.dart';
import '../retailer/screens/retailer_campaign_screens.dart';
import '../retailer/screens/retailer_control_screens.dart';
import '../retailer/screens/retailer_delivery_screens.dart';
import '../retailer/screens/retailer_books_screens.dart';
import '../retailer/screens/retailer_home_screen.dart';
import '../retailer/screens/retailer_order_screen.dart';
import '../retailer/screens/retailer_pos_screens.dart';
import '../retailer/screens/retailer_purchase_book_screens.dart';
import '../retailer/screens/retailer_sales_book_screen.dart';
import '../retailer/screens/retailer_wholesale_catalog_screens.dart';
import '../retailer/screens/retailer_wholesale_fulfilment_screens.dart';
import '../work/screens/work_earn_screens.dart';
import '../work/screens/work_onboarding_screens.dart';
import '../work/work_session.dart';
import 'journey_session.dart';
import 'screens/boot_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/universal_shell.dart';
import 'screens/verify_otp_screen.dart';

GoRouter createJourneyRouter(
  JourneySession session,
  BookSession bookSession,
  BuySession buySession,
  CaptainSession captainSession,
  ChatSession chatSession,
  CreatorSession creatorSession,
  EatSession eatSession,
  ManufacturerSession manufacturerSession,
  PaySession paySession,
  RetailerSession retailerSession,
  RideSession rideSession,
  WorkSession workSession, {
  String initialLocation = '/boot',
}) {
  late final GoRouter router;
  router = GoRouter(
    initialLocation: initialLocation,
    refreshListenable: session,
    redirect: (context, state) {
      final location = state.uri.path;
      final protected = location.startsWith('/app/');

      if (protected && !session.isReady) {
        session.captureReturnTo(location);
      }

      switch (session.stage) {
        case JourneyStage.booting:
        case JourneyStage.bootFailure:
          return location == '/boot' ? null : '/boot';
        case JourneyStage.setup:
          return location == '/setup' ? null : '/setup';
        case JourneyStage.signIn:
          return location == '/sign-in' ? null : '/sign-in';
        case JourneyStage.verify:
          return location == '/verify' ? null : '/verify';
        case JourneyStage.ready:
          if (!protected) return session.readyRoute();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (session.isReady &&
                router.routeInformationProvider.value.uri.path == location) {
              session.confirmReadyRoute(location);
            }
          });
          return null;
      }
    },
    routes: [
      GoRoute(
        path: '/boot',
        builder: (context, state) => BootScreen(session: session),
      ),
      GoRoute(
        path: '/setup',
        builder: (context, state) => SetupScreen(session: session),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => SignInScreen(session: session),
      ),
      GoRoute(
        path: '/verify',
        builder: (context, state) => VerifyOtpScreen(session: session),
      ),
      GoRoute(
        path: '/app/buy/grocery',
        builder: (context, state) => BuyCatalogScreen(session: buySession),
      ),
      GoRoute(
        path: '/app/buy/product/:productId',
        builder: (context, state) => BuyProductScreen(
          session: buySession,
          productId: state.pathParameters['productId'] ?? 'tomato',
        ),
      ),
      GoRoute(
        path: '/app/buy/basket',
        builder: (context, state) => BuyBasketScreen(session: buySession),
      ),
      GoRoute(
        path: '/app/buy/review',
        builder: (context, state) => BuyReviewScreen(session: buySession),
      ),
      GoRoute(
        path: '/app/buy/order/:orderId',
        builder: (context, state) => BuyTrackingScreen(
          session: buySession,
          orderId: state.pathParameters['orderId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/app/buy/order/:orderId/collection',
        builder: (context, state) => BuyCollectionScreen(
          session: buySession,
          orderId: state.pathParameters['orderId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/app/buy/order/:orderId/collection-completed',
        builder: (context, state) => BuyCollectionCompletedScreen(
          session: buySession,
          orderId: state.pathParameters['orderId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/app/buy/order/:orderId/completed',
        builder: (context, state) => BuyCompletedScreen(
          session: buySession,
          orderId: state.pathParameters['orderId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/app/buy/order/:orderId/problem',
        builder: (context, state) => BuyProblemScreen(
          session: buySession,
          orderId: state.pathParameters['orderId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/app/eat/home',
        builder: (context, state) => EatHomeScreen(session: eatSession),
      ),
      GoRoute(
        path: '/app/eat/order',
        builder: (context, state) => EatOrderScreen(session: eatSession),
      ),
      GoRoute(
        path: '/app/eat/basket',
        builder: (context, state) => EatBasketScreen(session: eatSession),
      ),
      GoRoute(
        path: '/app/eat/review',
        builder: (context, state) => EatReviewScreen(session: eatSession),
      ),
      GoRoute(
        path: '/app/eat/order/:orderId',
        builder: (context, state) => EatTrackingScreen(
          session: eatSession,
          orderId: state.pathParameters['orderId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/app/eat/order/:orderId/completed',
        builder: (context, state) => EatCompletedScreen(
          session: eatSession,
          orderId: state.pathParameters['orderId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/app/eat/table',
        builder: (context, state) => EatTableScreen(session: eatSession),
      ),
      GoRoute(
        path: '/app/eat/table/:bookingId',
        builder: (context, state) => EatTableConfirmationScreen(
          session: eatSession,
          bookingId: state.pathParameters['bookingId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/app/eat/tiffin',
        builder: (context, state) => EatTiffinScreen(session: eatSession),
      ),
      GoRoute(
        path: '/app/eat/tiffin/:subscriptionId',
        builder: (context, state) => EatTiffinConfirmationScreen(
          session: eatSession,
          subscriptionId: state.pathParameters['subscriptionId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/app/chat/inbox',
        builder: (context, state) => ChatInboxScreen(
          session: chatSession,
          returnRoute: state.uri.queryParameters['return'] ?? '/app/social',
        ),
      ),
      GoRoute(
        path: '/app/chat/thread/:threadId',
        builder: (context, state) => ChatThreadScreen(
          session: chatSession,
          threadId: state.pathParameters['threadId'] ?? 'home-basket',
          returnRoute: state.uri.queryParameters['return'] ?? '/app/social',
        ),
      ),
      GoRoute(
        path: '/app/ride/book',
        builder: (context, state) => RideBookingScreen(
          session: rideSession,
          initialType: switch (state.uri.queryParameters['type']) {
            'bike' => RideType.bike,
            'cab' => RideType.cab,
            'auto' => RideType.auto,
            _ => null,
          },
        ),
      ),
      GoRoute(
        path: '/app/ride/trip/:tripId',
        builder: (context, state) => RideTripScreen(
          session: rideSession,
          tripId: state.pathParameters['tripId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/app/ride/trip/:tripId/support',
        builder: (context, state) => RideSupportScreen(
          session: rideSession,
          tripId: state.pathParameters['tripId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/app/book/home',
        builder: (context, state) => BookHomeScreen(
          session: bookSession,
          initialIntent: state.uri.queryParameters['intent'],
        ),
      ),
      GoRoute(
        path: '/app/book/doctor',
        builder: (context, state) => DoctorBookingScreen(session: bookSession),
      ),
      GoRoute(
        path: '/app/book/doctor/details',
        builder: (context, state) => DoctorDetailsScreen(session: bookSession),
      ),
      GoRoute(
        path: '/app/book/doctor/invite',
        builder: (context, state) => DoctorInviteScreen(session: bookSession),
      ),
      GoRoute(
        path: '/app/book/doctor/join',
        builder: (context, state) =>
            PatientInviteJoinScreen(session: bookSession),
      ),
      GoRoute(
        path: '/app/book/doctor/followup',
        builder: (context, state) =>
            PatientFollowUpScreen(session: bookSession),
      ),
      GoRoute(
        path: '/app/book/salon',
        builder: (context, state) => SalonBookingScreen(session: bookSession),
      ),
      GoRoute(
        path: '/app/book/salon/confirm',
        builder: (context, state) => SalonConfirmScreen(session: bookSession),
      ),
      GoRoute(
        path: '/app/book/salon/confirmed',
        builder: (context, state) => SalonConfirmedScreen(session: bookSession),
      ),
      GoRoute(
        path: '/app/book/salon/visit',
        builder: (context, state) => SalonVisitScreen(session: bookSession),
      ),
      GoRoute(
        path: '/app/book/salon/complete',
        builder: (context, state) => SalonCompleteScreen(session: bookSession),
      ),
      GoRoute(
        path: '/app/book/salon/support',
        builder: (context, state) => SalonSupportScreen(session: bookSession),
      ),
      GoRoute(
        path: '/app/book/task',
        builder: (context, state) => TaskCreateScreen(session: bookSession),
      ),
      GoRoute(
        path: '/app/book/task/review',
        builder: (context, state) => TaskReviewScreen(session: bookSession),
      ),
      GoRoute(
        path: '/app/book/task/live',
        builder: (context, state) => TaskLiveScreen(session: bookSession),
      ),
      GoRoute(
        path: '/app/book/task/proof',
        builder: (context, state) => TaskProofScreen(session: bookSession),
      ),
      GoRoute(
        path: '/app/book/task/completed',
        builder: (context, state) => TaskCompletedScreen(session: bookSession),
      ),
      GoRoute(
        path: '/app/book/task/support',
        builder: (context, state) => TaskSupportScreen(session: bookSession),
      ),
      GoRoute(
        path: '/app/book/task/case',
        builder: (context, state) => TaskCaseScreen(session: bookSession),
      ),
      GoRoute(
        path: '/app/book/task/resolution',
        builder: (context, state) => TaskResolutionScreen(session: bookSession),
      ),
      GoRoute(
        path: '/app/book/task/resolution-complete',
        builder: (context, state) =>
            TaskResolutionCompleteScreen(session: bookSession),
      ),
      GoRoute(
        path: '/app/pay/home',
        builder: (context, state) => PayHomeScreen(
          session: paySession,
          initialIntent: state.uri.queryParameters['intent'],
        ),
      ),
      GoRoute(
        path: '/app/pay/recharge',
        builder: (context, state) => PayRechargeScreen(session: paySession),
      ),
      GoRoute(
        path: '/app/pay/bills',
        builder: (context, state) => PayBillsScreen(session: paySession),
      ),
      GoRoute(
        path: '/app/pay/scan',
        builder: (context, state) => PayScanScreen(session: paySession),
      ),
      GoRoute(
        path: '/app/pay/requests',
        builder: (context, state) => PayRequestsScreen(session: paySession),
      ),
      GoRoute(
        path: '/app/pay/request/:requestId/confirm',
        builder: (context, state) => PayRequestConfirmationScreen(
          session: paySession,
          requestId: state.pathParameters['requestId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/app/pay/payment/:paymentId/receipt',
        builder: (context, state) => PayReceiptScreen(
          session: paySession,
          paymentId: state.pathParameters['paymentId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/app/pay/receipts',
        builder: (context, state) => PayReceiptsScreen(session: paySession),
      ),
      GoRoute(
        path: '/app/pay/payment/:paymentId/status',
        builder: (context, state) => PayStatusScreen(
          session: paySession,
          paymentId: state.pathParameters['paymentId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/app/pay/payment/:paymentId/outcome',
        builder: (context, state) => PayOutcomeScreen(
          session: paySession,
          paymentId: state.pathParameters['paymentId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/app/retailer',
        builder: (context, state) => state.uri.queryParameters['panel'] == 'ai'
            ? RetailerAiAssistantScreen(session: retailerSession)
            : RetailerHomeScreen(session: retailerSession),
      ),
      GoRoute(
        path: '/app/creator',
        builder: (context, state) =>
            CreatorStudioHomeScreen(session: creatorSession),
      ),
      GoRoute(
        path: '/app/creator/publish',
        builder: (context, state) {
          final campaign = state.uri.queryParameters['campaign'];
          if (campaign != null) {
            creatorSession
              ..publishFormat = CreatorPublishFormat.reel
              ..reelFundingCampaignId = campaign
              ..sponsored = true;
          }
          return CreatorPublishScreen(session: creatorSession);
        },
      ),
      GoRoute(
        path: '/app/creator/youtube-connect',
        builder: (context, state) =>
            CreatorYouTubeConnectScreen(session: creatorSession),
      ),
      GoRoute(
        path: '/app/creator/content',
        builder: (context, state) {
          creatorSession.contentTab =
              switch (state.uri.queryParameters['tab']) {
                'drafts' => CreatorContentTab.drafts,
                'scheduled' => CreatorContentTab.scheduled,
                'unavailable' => CreatorContentTab.unavailable,
                _ => CreatorContentTab.published,
              };
          return CreatorContentLibraryScreen(session: creatorSession);
        },
      ),
      GoRoute(
        path: '/app/creator/performance',
        builder: (context, state) =>
            CreatorPerformanceScreen(session: creatorSession),
      ),
      GoRoute(
        path: '/app/creator/audience',
        builder: (context, state) =>
            state.uri.queryParameters['tab'] == 'memberships'
            ? CreatorMembershipsScreen(session: creatorSession)
            : CreatorAudienceScreen(session: creatorSession),
      ),
      GoRoute(
        path: '/app/creator/campaigns',
        builder: (context, state) =>
            CreatorCampaignsScreen(session: creatorSession),
      ),
      GoRoute(
        path: '/app/creator/earnings',
        builder: (context, state) =>
            CreatorEarningsScreen(session: creatorSession),
      ),
      GoRoute(
        path: '/app/creator/control',
        builder: (context, state) =>
            CreatorControlScreen(session: creatorSession),
      ),
      GoRoute(
        path: '/app/captain',
        builder: (context, state) => CaptainHomeScreen(session: captainSession),
      ),
      GoRoute(
        path: '/app/captain/requests',
        builder: (context, state) =>
            CaptainRideRequestScreen(session: captainSession),
      ),
      GoRoute(
        path: '/app/captain/trips/:tripId/pickup',
        builder: (context, state) =>
            CaptainPickupScreen(session: captainSession),
      ),
      GoRoute(
        path: '/app/captain/trips/:tripId/complete',
        builder: (context, state) =>
            CaptainFareCompletionScreen(session: captainSession),
      ),
      GoRoute(
        path: '/app/captain/trips/:tripId',
        builder: (context, state) =>
            CaptainLiveTripScreen(session: captainSession),
      ),
      GoRoute(
        path: '/app/captain/earnings',
        builder: (context, state) {
          final tab = switch (state.uri.queryParameters['tab']) {
            'week' => CaptainEarningsTab.week,
            'payouts' => CaptainEarningsTab.payouts,
            _ => CaptainEarningsTab.today,
          };
          captainSession.earningsTab = tab;
          return CaptainEarningsScreen(
            session: captainSession,
            initialTab: tab,
          );
        },
      ),
      GoRoute(
        path: '/app/captain/compliance',
        builder: (context, state) =>
            CaptainComplianceScreen(session: captainSession),
      ),
      GoRoute(
        path: '/app/captain/support-work',
        builder: (context, state) {
          final tab = switch (state.uri.queryParameters['tab']) {
            'work' => CaptainSupportTab.paidWork,
            'vehicle' => CaptainSupportTab.vehicle,
            _ => CaptainSupportTab.support,
          };
          captainSession.supportTab = tab;
          return CaptainSupportWorkScreen(
            session: captainSession,
            initialTab: tab,
          );
        },
      ),
      GoRoute(
        path: '/app/manufacturer',
        builder: (context, state) {
          final view = state.uri.queryParameters['view'] == 'orders'
              ? ManufacturerHomeView.orders
              : ManufacturerHomeView.home;
          manufacturerSession.homeView = view;
          return ManufacturerHomeScreen(
            session: manufacturerSession,
            initialView: view,
          );
        },
      ),
      GoRoute(
        path: '/app/manufacturer/books',
        builder: (context, state) =>
            ManufacturerBusinessBookScreen(session: manufacturerSession),
      ),
      GoRoute(
        path: '/app/manufacturer/catalogue',
        builder: (context, state) {
          final mode = state.uri.queryParameters['mode'] == 'master'
              ? ManufacturerCatalogueMode.master
              : ManufacturerCatalogueMode.stock;
          manufacturerSession.catalogueMode = mode;
          return ManufacturerCatalogueScreen(
            session: manufacturerSession,
            initialMode: mode,
          );
        },
      ),
      GoRoute(
        path: '/app/manufacturer/orders/review',
        builder: (context, state) =>
            ManufacturerOrderReviewScreen(session: manufacturerSession),
      ),
      GoRoute(
        path: '/app/manufacturer/purchases',
        builder: (context, state) {
          final tab = switch (state.uri.queryParameters['tab']) {
            'cart' => ManufacturerPurchaseTab.cart,
            'orders' => ManufacturerPurchaseTab.orders,
            _ => ManufacturerPurchaseTab.matched,
          };
          manufacturerSession.purchaseTab = tab;
          return ManufacturerProcurementScreen(
            session: manufacturerSession,
            initialTab: tab,
          );
        },
      ),
      GoRoute(
        path: '/app/manufacturer/dispatch',
        builder: (context, state) {
          final tab = switch (state.uri.queryParameters['tab']) {
            'transit' => ManufacturerDispatchTab.transit,
            'delivered' => ManufacturerDispatchTab.delivered,
            _ => ManufacturerDispatchTab.ready,
          };
          manufacturerSession.dispatchTab = tab;
          return ManufacturerDispatchScreen(
            session: manufacturerSession,
            initialTab: tab,
          );
        },
      ),
      GoRoute(
        path: '/app/manufacturer/growth',
        builder: (context, state) {
          final tab = switch (state.uri.queryParameters['tab']) {
            'demand' => ManufacturerGrowthTab.demand,
            'campaigns' => ManufacturerGrowthTab.campaigns,
            'analytics' => ManufacturerGrowthTab.analytics,
            _ => ManufacturerGrowthTab.buyers,
          };
          manufacturerSession.growthTab = tab;
          return ManufacturerGrowthScreen(
            session: manufacturerSession,
            initialTab: tab,
          );
        },
      ),
      GoRoute(
        path: '/app/manufacturer/control',
        builder: (context, state) {
          final tab = switch (state.uri.queryParameters['tab']) {
            'team' => ManufacturerControlTab.team,
            'settings' => ManufacturerControlTab.settings,
            'support' => ManufacturerControlTab.support,
            _ => ManufacturerControlTab.claims,
          };
          manufacturerSession.controlTab = tab;
          return ManufacturerControlScreen(
            session: manufacturerSession,
            initialTab: tab,
          );
        },
      ),
      GoRoute(
        path: '/app/manufacturer/services',
        builder: (context, state) {
          final tab = switch (state.uri.queryParameters['tab']) {
            'active' => ManufacturerServiceTab.active,
            'requests' => ManufacturerServiceTab.requests,
            _ => ManufacturerServiceTab.services,
          };
          manufacturerSession.serviceTab = tab;
          return ManufacturerServicesScreen(
            session: manufacturerSession,
            initialTab: tab,
          );
        },
      ),
      GoRoute(
        path: '/app/retailer/mool',
        builder: (context, state) {
          session.openMoolFrom('retailer');
          return UniversalShell(session: session, section: 'mool');
        },
      ),
      GoRoute(
        path: '/app/retailer/home',
        builder: (context, state) =>
            state.uri.queryParameters['panel'] == 'recovery'
            ? RetailerSlowStockScreen(session: retailerSession)
            : RetailerHomeScreen(
                session: retailerSession,
                initialView: switch (state.uri.queryParameters['view']) {
                  'orders' => RetailerHomeView.orders,
                  'stock' => RetailerHomeView.stock,
                  'wholesale' => RetailerHomeView.wholesale,
                  _ => RetailerHomeView.home,
                },
              ),
      ),
      GoRoute(
        path: '/app/retailer/orders',
        builder: (context, state) => RetailerHomeScreen(
          session: retailerSession,
          initialView: RetailerHomeView.orders,
        ),
      ),
      GoRoute(
        path: '/app/retailer/orders/new',
        builder: (context, state) => RetailerCreateOrderScreen(
          session: retailerSession,
          initialSource: switch (state.uri.queryParameters['source']) {
            'counter' => RetailerOrderSource.counter,
            'chat' => RetailerOrderSource.chat,
            _ => RetailerOrderSource.phone,
          },
          counterId: state.uri.queryParameters['counterId'],
        ),
      ),
      GoRoute(
        path: '/app/retailer/pos/counters',
        builder: (context, state) =>
            RetailerCounterManagementScreen(session: retailerSession),
      ),
      GoRoute(
        path: '/app/retailer/pos/sales/new',
        builder: (context, state) =>
            RetailerCounterSaleScreen(session: retailerSession),
      ),
      GoRoute(
        path: '/app/retailer/books',
        builder: (context, state) =>
            RetailerBusinessBookScreen(session: retailerSession),
      ),
      GoRoute(
        path: '/app/retailer/books/sales',
        builder: (context, state) =>
            RetailerSalesBookScreen(session: retailerSession),
      ),
      GoRoute(
        path: '/app/retailer/books/stock',
        builder: (context, state) =>
            RetailerStockStatementScreen(session: retailerSession),
      ),
      GoRoute(
        path: '/app/retailer/books/money',
        builder: (context, state) =>
            RetailerMoneyControlScreen(session: retailerSession),
      ),
      GoRoute(
        path: '/app/retailer/services',
        builder: (context, state) =>
            RetailerBusinessServicesScreen(session: retailerSession),
      ),
      GoRoute(
        path: '/app/retailer/services/:serviceId',
        builder: (context, state) {
          final service = retailerBusinessServiceByName(
            state.pathParameters['serviceId'] ?? 'delivery',
          );
          return switch (state.uri.queryParameters['stage']) {
            'review' => RetailerBusinessServiceReviewScreen(
              session: retailerSession,
              service: service,
            ),
            'active' => RetailerBusinessServiceActiveScreen(
              session: retailerSession,
              service: service,
            ),
            _ => RetailerBusinessServicePlanScreen(
              session: retailerSession,
              service: service,
            ),
          };
        },
      ),
      GoRoute(
        path: '/app/retailer/customers',
        builder: (context, state) {
          final filter = state.uri.queryParameters['filter'];
          if (filter != null) {
            final requested = RetailerCustomerFilter.values.firstWhere(
              (value) => value.name == filter,
              orElse: () => RetailerCustomerFilter.all,
            );
            if (retailerSession.customerFilter != requested) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                retailerSession.setCustomerFilter(requested);
              });
            }
          }
          return RetailerCustomersScreen(session: retailerSession);
        },
      ),
      GoRoute(
        path: '/app/retailer/customers/:customerId',
        builder: (context, state) => RetailerCustomerDetailScreen(
          session: retailerSession,
          customerId: state.pathParameters['customerId'] ?? 'sharma',
        ),
      ),
      GoRoute(
        path: '/app/retailer/campaigns',
        builder: (context, state) {
          final filter = state.uri.queryParameters['filter'];
          if (filter != null) {
            final requested = RetailerCampaignFilter.values.firstWhere(
              (value) => value.name == filter,
              orElse: () => RetailerCampaignFilter.all,
            );
            if (retailerSession.campaignFilter != requested) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                retailerSession.setCampaignFilter(requested);
              });
            }
          }
          return RetailerCampaignsScreen(session: retailerSession);
        },
      ),
      GoRoute(
        path: '/app/retailer/campaigns/new',
        builder: (context, state) =>
            RetailerCampaignBuilderScreen(session: retailerSession),
      ),
      GoRoute(
        path: '/app/retailer/settings',
        builder: (context, state) =>
            RetailerStoreSettingsScreen(session: retailerSession),
      ),
      GoRoute(
        path: '/app/retailer/settings/team',
        builder: (context, state) =>
            RetailerStaffScreen(session: retailerSession),
      ),
      GoRoute(
        path: '/app/retailer/orders/issues',
        builder: (context, state) =>
            RetailerCustomerIssuesScreen(session: retailerSession),
      ),
      GoRoute(
        path: '/app/retailer/wholesale',
        builder: (context, state) =>
            RetailerWholesaleCatalogScreen(session: retailerSession),
      ),
      GoRoute(
        path: '/app/retailer/wholesale/cart',
        builder: (context, state) =>
            RetailerWholesaleCartScreen(session: retailerSession),
      ),
      GoRoute(
        path: '/app/retailer/wholesale/orders/confirmed',
        builder: (context, state) =>
            RetailerWholesaleOrderConfirmedScreen(session: retailerSession),
      ),
      GoRoute(
        path: '/app/retailer/wholesale/orders/tracking',
        builder: (context, state) =>
            RetailerWholesaleTrackingScreen(session: retailerSession),
      ),
      GoRoute(
        path: '/app/retailer/wholesale/goods-receipt',
        builder: (context, state) =>
            RetailerGoodsReceiptScreen(session: retailerSession),
      ),
      GoRoute(
        path: '/app/retailer/wholesale/goods-receipt/result',
        builder: (context, state) =>
            RetailerGoodsReceiptResultScreen(session: retailerSession),
      ),
      GoRoute(
        path: '/app/retailer/books/purchases',
        builder: (context, state) =>
            RetailerPurchaseBookScreen(session: retailerSession),
      ),
      GoRoute(
        path: '/app/retailer/supplier-bills/:billId',
        builder: (context, state) =>
            RetailerSupplierBillScreen(session: retailerSession),
      ),
      GoRoute(
        path: '/app/retailer/supplier-payments/:paymentId/status',
        builder: (context, state) =>
            RetailerSupplierPaymentStatusScreen(session: retailerSession),
      ),
      GoRoute(
        path: '/app/retailer/orders/:orderId/tracking',
        builder: (context, state) => RetailerDeliveryTrackingScreen(
          session: retailerSession,
          orderId: state.pathParameters['orderId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/app/retailer/orders/:orderId/delivery',
        builder: (context, state) => RetailerDeliveryAssignmentScreen(
          session: retailerSession,
          orderId: state.pathParameters['orderId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/app/retailer/orders/:orderId',
        builder: (context, state) => RetailerOrderScreen(
          session: retailerSession,
          orderId: state.pathParameters['orderId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/app/work',
        builder: (context, state) => WorkEarnScreen(session: workSession),
      ),
      GoRoute(
        path: '/app/work/mool',
        builder: (context, state) {
          session.openMoolFrom('work');
          return UniversalShell(session: session, section: 'mool');
        },
      ),
      GoRoute(
        path: '/app/work/earn',
        builder: (context, state) => WorkEarnScreen(session: workSession),
      ),
      GoRoute(
        path: '/app/work/opportunity/:opportunityId',
        builder: (context, state) => WorkOpportunityScreen(
          session: workSession,
          opportunityId:
              state.pathParameters['opportunityId'] ?? 'mool-explainer',
        ),
      ),
      GoRoute(
        path: '/app/work/my-work',
        builder: (context, state) => MyWorkScreen(session: workSession),
      ),
      GoRoute(
        path: '/app/work/choose',
        builder: (context, state) =>
            WorkChooseActivityScreen(session: workSession),
      ),
      GoRoute(
        path: '/app/work/proof',
        builder: (context, state) =>
            WorkProfileProofScreen(session: workSession),
      ),
      GoRoute(
        path: '/app/work/status',
        builder: (context, state) =>
            WorkVerificationStatusScreen(session: workSession),
      ),
      GoRoute(
        path: '/app/work/ready',
        builder: (context, state) => WorkspaceReadyScreen(session: workSession),
      ),
      GoRoute(
        path: '/app/work/retailer/setup',
        builder: (context, state) => RetailerSetupScreen(session: workSession),
      ),
      GoRoute(
        path: '/app/:section',
        builder: (context, state) => UniversalShell(
          session: session,
          section: state.pathParameters['section'] ?? 'social',
          initialSubAction: state.uri.queryParameters['sub'],
        ),
      ),
    ],
  );
  return router;
}
