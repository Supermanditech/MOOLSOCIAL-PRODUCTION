import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../book/book_session.dart';
import '../book/screens/book_home_screen.dart';
import '../book/screens/bus_booking_screen.dart';
import '../book/screens/doctor_screens.dart';
import '../book/screens/salon_screens.dart';
import '../book/screens/task_screens.dart';
import '../buy/buy_session.dart';
import '../buy/buy_v2_models.dart';
import '../buy/buy_v2_session.dart';
import '../buy/screens/buy_basket_screen.dart';
import '../buy/screens/buy_catalog_screen.dart';
import '../buy/screens/buy_collection_completed_screen.dart';
import '../buy/screens/buy_collection_screen.dart';
import '../buy/screens/buy_completed_screen.dart';
import '../buy/screens/buy_medicine_screen.dart';
import '../buy/screens/buy_problem_screen.dart';
import '../buy/screens/buy_product_screen.dart';
import '../buy/screens/buy_review_screen.dart';
import '../buy/screens/buy_tracking_screen.dart';
import '../captain/captain_models.dart';
import '../captain/captain_session.dart';
import '../captain/screens/captain_business_screens.dart';
import '../captain/screens/captain_home_request_screens.dart';
import '../captain/screens/captain_trip_screens.dart';
import '../chat/chat_models.dart';
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
import '../operations/operations_session.dart';
import '../operations/screens/earn_operations_screens.dart';
import '../operations/screens/provider_operations_screens.dart';
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
import '../shared/screens/shared_screens.dart';
import '../shared/shared_session.dart';
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
import '../../ui_v2/launch/launch_interruption_guard.dart';
import '../../ui_v2/launch/launch_presentation_gate.dart';
import '../../ui_v2/profile/global_personal_profile_v2.dart';
import '../../ui_v2/profile/global_profile_panel_v2.dart';
import '../../ui_v2/work/work_main_v2.dart';
import '../../ui_v2/screens/screen01_app_splash/app_splash_screen_v2.dart';
import '../../ui_v2/screens/screen02_first_setup/first_setup_screen_v2.dart';
import '../../ui_v2/screens/screen03_login/login_screen_v2.dart';
import '../../ui_v2/screens/screen03_login/login_screen_v5.dart';
import '../../ui_v2/screens/screen03_login/otp_screen_v2.dart';
import '../../ui_v2/social/social_v2_consumer.dart';
import '../../ui_v2/social/social_v2_creator.dart';
import '../../ui_v2/social/social_v2_plans_promotion.dart';
import '../../ui_v2/social/social_v2_youtube_creator_upload.dart';
import '../../ui_v2/buy/buy_v2_screen.dart';
import '../../ui_v2/universal/legacy_route_containment_screen_v2.dart';
import '../../ui_v2/universal/mool_global_navigation_v2.dart';
import '../../ui_v2/universal/mvp_action_choice_root_v2.dart';
import '../../ui_v2/universal/personal_mool_root_v2.dart';
import 'journey_session.dart';
import 'screens/universal_shell.dart';

bool journeyRouteRequiresAuthentication(
  Uri uri, {
  required bool allowGuestReady,
}) {
  if (allowGuestReady) return false;
  return uri.path.startsWith('/app/chat') ||
      (uri.path == '/app/social' && uri.queryParameters['sub'] == 'create');
}

GoRouter createJourneyRouter(
  JourneySession session,
  BookSession bookSession,
  BuySession buySession,
  CaptainSession captainSession,
  ChatSession chatSession,
  CreatorSession creatorSession,
  EatSession eatSession,
  ManufacturerSession manufacturerSession,
  OperationsSession operationsSession,
  PaySession paySession,
  RetailerSession retailerSession,
  RideSession rideSession,
  SharedSession sharedSession,
  WorkSession workSession, {
  required LaunchPresentationGate launchPresentationGate,
  required LaunchInterruptionGuard launchInterruptionGuard,
  String initialLocation = '/boot',
  bool legacyPresentationForTestsOnly = false,
}) {
  final buyV2Session = BuyV2Session(core: buySession);
  late final GoRouter router;
  VoidCallback buyExit(BuildContext context, GoRouterState state) => () {
    if (context.canPop()) {
      context.pop();
      return;
    }
    router.go(
      session.buyExitRoute(requestedRoute: state.uri.queryParameters['return']),
    );
  };
  VoidCallback openMoolFromBuy(BuildContext context) =>
      () => context.push('/app/mool?from=buy');
  void rememberBuyDestination(BuyV2Destination destination) {
    final location = '/app/buy?sub=${destination.name}';
    session.confirmReadyRoute(location);
    final current = router.routeInformationProvider.value.uri;
    if (buyV2Session.view == BuyV2View.catalogue &&
        current.path == '/app/buy' &&
        current.queryParameters['sub'] != destination.name) {
      router.replace(location);
    }
  }

  router = GoRouter(
    initialLocation: initialLocation,
    refreshListenable: Listenable.merge([
      session,
      launchPresentationGate,
      launchInterruptionGuard,
    ]),
    redirect: (context, state) {
      final location = state.uri.path;
      final protected = location.startsWith('/app/');
      final returnLocation = state.uri.toString();
      final authenticatedRoute = journeyRouteRequiresAuthentication(
        state.uri,
        allowGuestReady: session.allowGuestReady,
      );

      if (protected &&
          session.isReady &&
          authenticatedRoute &&
          !session.isAuthenticated) {
        session.beginSignIn(
          returnLocation: returnLocation,
          cancelLocation: session.authenticationCancelFallback,
        );
        return '/sign-in';
      }

      if (protected && !session.isReady) {
        session.captureReturnTo(returnLocation);
      }

      if (location == '/boot' &&
          (!launchPresentationGate.minimumElapsed ||
              !launchInterruptionGuard.canHandoff) &&
          session.stage != JourneyStage.bootFailure) {
        return null;
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
          final containment = legacyPresentationForTestsOnly
              ? null
              : legacyRouteContainmentFor(state.uri);
          if (containment != null) {
            return containment.recoveryLocation;
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (session.isReady &&
                router.routeInformationProvider.value.uri.path == location) {
              session.confirmReadyRoute(returnLocation);
            }
          });
          return null;
      }
    },
    routes: [
      GoRoute(
        path: '/boot',
        builder: (context, state) => AppSplashScreenV2(
          session: session,
          presentationGate: launchPresentationGate,
        ),
      ),
      GoRoute(
        path: '/setup',
        builder: (context, state) => FirstSetupScreenV2(session: session),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => legacyPresentationForTestsOnly
            ? LoginScreenV2(session: session)
            : LoginScreenV5(session: session),
      ),
      GoRoute(
        path: '/verify',
        builder: (context, state) => OtpScreenV2(session: session),
      ),
      GoRoute(
        path: '/app/action-unavailable',
        builder: (context, state) => LegacyRouteContainmentScreenV2(
          spec: legacyRouteContainmentSpecForReason(
            state.uri.queryParameters['reason'],
          ),
        ),
      ),
      GoRoute(
        path: '/app/buy',
        pageBuilder: (context, state) {
          if (legacyPresentationForTestsOnly) {
            return moolMainDestinationPage(
              state: state,
              child: UniversalShell(
                session: session,
                section: 'buy',
                initialSubAction: state.uri.queryParameters['sub'],
              ),
            );
          }
          final destination = _buyV2Destination(
            state.uri.queryParameters['sub'] ??
                state.uri.queryParameters['view'] ??
                state.uri.queryParameters['context'],
          );
          final view = _buyV2View(state.uri.queryParameters['view']);
          final cartScope = _buyV2CartScope(
            state.uri.queryParameters['scope'] ??
                state.uri.queryParameters['sub'] ??
                state.uri.queryParameters['context'],
          );
          return moolMainDestinationPage(
            state: state,
            child: BuyV2Screen(
              session: buyV2Session,
              accountIdentity: session.accountIdentity,
              accountAuthenticated: session.isAuthenticated,
              initialDestination: destination,
              initialOffersActive: state.uri.queryParameters['sub'] == 'offers',
              initialView: view,
              initialCartScope: cartScope,
              productId: state.uri.queryParameters['product'],
              orderId: state.uri.queryParameters['order'],
              recoveryKind: _buyV2Recovery(
                state.uri.queryParameters['recovery'],
              ),
              onExit: buyExit(context, state),
              onOpenMool: openMoolFromBuy(context),
              onDestinationChanged: rememberBuyDestination,
            ),
          );
        },
      ),
      GoRoute(
        path: '/app/buy/grocery',
        builder: (context, state) => legacyPresentationForTestsOnly
            ? BuyCatalogScreen(session: buySession)
            : BuyV2Screen(
                session: buyV2Session,
                accountIdentity: session.accountIdentity,
                accountAuthenticated: session.isAuthenticated,
                initialDestination: BuyV2Destination.shop,
                onExit: buyExit(context, state),
                onOpenMool: openMoolFromBuy(context),
                onDestinationChanged: rememberBuyDestination,
              ),
      ),
      GoRoute(
        path: '/app/buy/medicine',
        builder: (context, state) => legacyPresentationForTestsOnly
            ? BuyMedicineScreen(session: buySession)
            : BuyV2Screen(
                session: buyV2Session,
                accountIdentity: session.accountIdentity,
                accountAuthenticated: session.isAuthenticated,
                initialDestination: BuyV2Destination.medicine,
                onExit: buyExit(context, state),
                onOpenMool: openMoolFromBuy(context),
                onDestinationChanged: rememberBuyDestination,
              ),
      ),
      GoRoute(
        path: '/app/buy/product/:productId',
        builder: (context, state) => legacyPresentationForTestsOnly
            ? BuyProductScreen(
                session: buySession,
                productId: state.pathParameters['productId'] ?? 'tomato',
              )
            : BuyV2Screen(
                session: buyV2Session,
                accountIdentity: session.accountIdentity,
                accountAuthenticated: session.isAuthenticated,
                initialDestination: BuyV2Destination.shop,
                initialView: BuyV2View.product,
                productId: state.pathParameters['productId'],
                onExit: buyExit(context, state),
                onOpenMool: openMoolFromBuy(context),
                onDestinationChanged: rememberBuyDestination,
              ),
      ),
      GoRoute(
        path: '/app/buy/basket',
        builder: (context, state) => legacyPresentationForTestsOnly
            ? BuyBasketScreen(session: buySession)
            : BuyV2Screen(
                session: buyV2Session,
                accountIdentity: session.accountIdentity,
                accountAuthenticated: session.isAuthenticated,
                initialDestination: _buyV2Destination(
                  state.uri.queryParameters['scope'],
                ),
                initialView: BuyV2View.cart,
                initialCartScope: _buyV2CartScope(
                  state.uri.queryParameters['scope'],
                ),
                onExit: buyExit(context, state),
                onOpenMool: openMoolFromBuy(context),
                onDestinationChanged: rememberBuyDestination,
              ),
      ),
      GoRoute(
        path: '/app/buy/review',
        builder: (context, state) => legacyPresentationForTestsOnly
            ? BuyReviewScreen(session: buySession)
            : BuyV2Screen(
                session: buyV2Session,
                accountIdentity: session.accountIdentity,
                accountAuthenticated: session.isAuthenticated,
                initialDestination: BuyV2Destination.shop,
                initialView: BuyV2View.checkout,
                onExit: buyExit(context, state),
                onOpenMool: openMoolFromBuy(context),
                onDestinationChanged: rememberBuyDestination,
              ),
      ),
      GoRoute(
        path: '/app/buy/order/:orderId',
        builder: (context, state) => legacyPresentationForTestsOnly
            ? BuyTrackingScreen(
                session: buySession,
                orderId: state.pathParameters['orderId'] ?? '',
              )
            : BuyV2Screen(
                session: buyV2Session,
                accountIdentity: session.accountIdentity,
                accountAuthenticated: session.isAuthenticated,
                initialDestination: BuyV2Destination.orders,
                initialView: BuyV2View.tracking,
                orderId: state.pathParameters['orderId'],
                onExit: buyExit(context, state),
                onOpenMool: openMoolFromBuy(context),
                onDestinationChanged: rememberBuyDestination,
              ),
      ),
      GoRoute(
        path: '/app/buy/order/:orderId/collection',
        builder: (context, state) => legacyPresentationForTestsOnly
            ? BuyCollectionScreen(
                session: buySession,
                orderId: state.pathParameters['orderId'] ?? '',
              )
            : BuyV2Screen(
                session: buyV2Session,
                accountIdentity: session.accountIdentity,
                accountAuthenticated: session.isAuthenticated,
                initialDestination: BuyV2Destination.orders,
                initialView: BuyV2View.tracking,
                orderId: state.pathParameters['orderId'],
                onExit: buyExit(context, state),
                onOpenMool: openMoolFromBuy(context),
                onDestinationChanged: rememberBuyDestination,
              ),
      ),
      GoRoute(
        path: '/app/buy/order/:orderId/collection-completed',
        builder: (context, state) => legacyPresentationForTestsOnly
            ? BuyCollectionCompletedScreen(
                session: buySession,
                orderId: state.pathParameters['orderId'] ?? '',
              )
            : BuyV2Screen(
                session: buyV2Session,
                accountIdentity: session.accountIdentity,
                accountAuthenticated: session.isAuthenticated,
                initialDestination: BuyV2Destination.orders,
                onExit: buyExit(context, state),
                onOpenMool: openMoolFromBuy(context),
                onDestinationChanged: rememberBuyDestination,
              ),
      ),
      GoRoute(
        path: '/app/buy/order/:orderId/completed',
        builder: (context, state) => legacyPresentationForTestsOnly
            ? BuyCompletedScreen(
                session: buySession,
                orderId: state.pathParameters['orderId'] ?? '',
              )
            : BuyV2Screen(
                session: buyV2Session,
                accountIdentity: session.accountIdentity,
                accountAuthenticated: session.isAuthenticated,
                initialDestination: BuyV2Destination.orders,
                onExit: buyExit(context, state),
                onOpenMool: openMoolFromBuy(context),
                onDestinationChanged: rememberBuyDestination,
              ),
      ),
      GoRoute(
        path: '/app/buy/order/:orderId/problem',
        builder: (context, state) => legacyPresentationForTestsOnly
            ? BuyProblemScreen(
                session: buySession,
                orderId: state.pathParameters['orderId'] ?? '',
              )
            : BuyV2Screen(
                session: buyV2Session,
                accountIdentity: session.accountIdentity,
                accountAuthenticated: session.isAuthenticated,
                initialDestination: BuyV2Destination.orders,
                initialView: BuyV2View.assist,
                orderId: state.pathParameters['orderId'],
                onExit: buyExit(context, state),
                onOpenMool: openMoolFromBuy(context),
                onDestinationChanged: rememberBuyDestination,
              ),
      ),
      GoRoute(
        path: '/app/eat/home',
        pageBuilder: (context, state) => moolMainDestinationPage(
          state: state,
          child: EatHomeScreen(session: eatSession),
        ),
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
        path: '/app/chat',
        pageBuilder: (context, state) {
          final filter = _chatFilter(
            state.uri.queryParameters['type'] ??
                state.uri.queryParameters['sub'],
          );
          return moolMainDestinationPage(
            state: state,
            child: ChatInboxScreen(
              key: ValueKey('chat-inbox-${filter?.name ?? 'all'}'),
              session: chatSession,
              socialSession: sharedSession,
              initialFilter: filter,
              initialTargetUserId: state.uri.queryParameters['start'],
              initialMessageDraft: state.uri.queryParameters['draft'],
              returnRoute: state.uri.queryParameters['return'] ?? '/app/social',
            ),
          );
        },
      ),
      GoRoute(
        path: '/app/chat/inbox',
        pageBuilder: (context, state) {
          final filter = _chatFilter(state.uri.queryParameters['type']);
          return moolMainDestinationPage(
            state: state,
            child: ChatInboxScreen(
              key: ValueKey('chat-inbox-${filter?.name ?? 'all'}'),
              session: chatSession,
              socialSession: sharedSession,
              initialFilter: filter,
              initialTargetUserId: state.uri.queryParameters['start'],
              initialMessageDraft: state.uri.queryParameters['draft'],
              returnRoute: state.uri.queryParameters['return'] ?? '/app/social',
            ),
          );
        },
      ),
      GoRoute(
        path: '/app/chat/thread/:threadId',
        builder: (context, state) => ChatThreadScreen(
          session: chatSession,
          threadId: state.pathParameters['threadId'] ?? 'home-basket',
          initialMessageDraft: state.uri.queryParameters['draft'],
          returnRoute: state.uri.queryParameters['return'] ?? '/app/social',
        ),
      ),
      GoRoute(
        path: '/app/ride/book',
        pageBuilder: (context, state) => moolMainDestinationPage(
          state: state,
          child: RideBookingScreen(
            session: rideSession,
            initialType: switch (state.uri.queryParameters['type']) {
              'bike' => RideType.bike,
              'cab' => RideType.cab,
              'auto' => RideType.auto,
              _ => null,
            },
          ),
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
        path: '/app/book/bus',
        pageBuilder: (context, state) => moolMainDestinationPage(
          state: state,
          child: BusBookingScreen(session: bookSession),
        ),
      ),
      GoRoute(
        path: '/app/book/doctor',
        pageBuilder: (context, state) => moolMainDestinationPage(
          state: state,
          child: DoctorBookingScreen(session: bookSession),
        ),
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
        builder: (context, state) => legacyPresentationForTestsOnly
            ? CreatorStudioHomeScreen(session: creatorSession)
            : CreatorSocialV2Screen(
                session: creatorSession,
                owner: CreatorSocialV2Owner.home,
                initialState: state.uri.queryParameters['state'],
              ),
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
          return legacyPresentationForTestsOnly
              ? CreatorPublishScreen(session: creatorSession)
              : CreatorSocialV2Screen(
                  session: creatorSession,
                  owner: CreatorSocialV2Owner.publish,
                  initialState: state.uri.queryParameters['state'],
                );
        },
      ),
      GoRoute(
        path: '/app/creator/youtube-connect',
        builder: (context, state) => legacyPresentationForTestsOnly
            ? CreatorYouTubeConnectScreen(session: creatorSession)
            : SocialYouTubeCreatorUploadScreen(
                youtubeConnectResult:
                    state.uri.queryParameters['youtubeConnect'],
              ),
      ),
      GoRoute(
        path: '/app/creator/content',
        builder: (context, state) {
          creatorSession.contentTab =
              switch (state.uri.queryParameters['state'] == 'processing'
              ? 'unavailable'
              : state.uri.queryParameters['tab']) {
                'drafts' => CreatorContentTab.drafts,
                'scheduled' => CreatorContentTab.scheduled,
                'unavailable' => CreatorContentTab.unavailable,
                _ => CreatorContentTab.published,
              };
          return legacyPresentationForTestsOnly
              ? CreatorContentLibraryScreen(session: creatorSession)
              : CreatorSocialV2Screen(
                  session: creatorSession,
                  owner: CreatorSocialV2Owner.library,
                  initialState: state.uri.queryParameters['state'],
                );
        },
      ),
      GoRoute(
        path: '/app/creator/performance',
        builder: (context, state) => legacyPresentationForTestsOnly
            ? CreatorPerformanceScreen(session: creatorSession)
            : CreatorSocialV2Screen(
                session: creatorSession,
                owner: CreatorSocialV2Owner.performance,
                initialState: state.uri.queryParameters['state'],
              ),
      ),
      GoRoute(
        path: '/app/creator/audience',
        builder: (context, state) {
          final memberships = state.uri.queryParameters['tab'] == 'memberships';
          if (legacyPresentationForTestsOnly) {
            return memberships
                ? CreatorMembershipsScreen(session: creatorSession)
                : CreatorAudienceScreen(session: creatorSession);
          }
          return CreatorSocialV2Screen(
            session: creatorSession,
            owner: memberships
                ? CreatorSocialV2Owner.memberships
                : CreatorSocialV2Owner.audience,
            initialState: state.uri.queryParameters['state'],
          );
        },
      ),
      GoRoute(
        path: '/app/creator/campaigns',
        builder: (context, state) => legacyPresentationForTestsOnly
            ? CreatorCampaignsScreen(session: creatorSession)
            : CreatorSocialV2Screen(
                session: creatorSession,
                owner: CreatorSocialV2Owner.campaigns,
                initialState: state.uri.queryParameters['state'],
              ),
      ),
      GoRoute(
        path: '/app/creator/earnings',
        builder: (context, state) => legacyPresentationForTestsOnly
            ? CreatorEarningsScreen(session: creatorSession)
            : CreatorSocialV2Screen(
                session: creatorSession,
                owner: CreatorSocialV2Owner.earnings,
                initialState: state.uri.queryParameters['state'],
              ),
      ),
      GoRoute(
        path: '/app/creator/control',
        builder: (context, state) => legacyPresentationForTestsOnly
            ? CreatorControlScreen(session: creatorSession)
            : CreatorSocialV2Screen(
                session: creatorSession,
                owner: CreatorSocialV2Owner.safety,
                initialState: state.uri.queryParameters['state'],
              ),
      ),
      GoRoute(
        path: '/app/earn',
        builder: (context, state) =>
            EarnOpportunitiesScreen(session: operationsSession),
      ),
      GoRoute(
        path: '/app/earn/applications',
        builder: (context, state) =>
            EarnApplicationsScreen(session: operationsSession),
      ),
      GoRoute(
        path: '/app/earn/active',
        builder: (context, state) =>
            EarnActiveWorkScreen(session: operationsSession),
      ),
      GoRoute(
        path: '/app/earn/proof',
        builder: (context, state) =>
            EarnProofScreen(session: operationsSession),
      ),
      GoRoute(
        path: '/app/earn/earnings',
        builder: (context, state) =>
            EarnEarningsScreen(session: operationsSession),
      ),
      GoRoute(
        path: '/app/earn/history',
        builder: (context, state) =>
            EarnHistoryScreen(session: operationsSession),
      ),
      GoRoute(
        path: '/app/provider',
        builder: (context, state) =>
            ProviderHomeScreen(session: operationsSession),
      ),
      GoRoute(
        path: '/app/provider/catalogue',
        builder: (context, state) =>
            ProviderCatalogueScreen(session: operationsSession),
      ),
      GoRoute(
        path: '/app/provider/availability',
        builder: (context, state) =>
            ProviderAvailabilityScreen(session: operationsSession),
      ),
      GoRoute(
        path: '/app/provider/requests',
        builder: (context, state) =>
            ProviderRequestsScreen(session: operationsSession),
      ),
      GoRoute(
        path: '/app/provider/fulfilment',
        builder: (context, state) =>
            ProviderFulfilmentScreen(session: operationsSession),
      ),
      GoRoute(
        path: '/app/provider/business',
        builder: (context, state) =>
            ProviderBusinessScreen(session: operationsSession),
      ),
      GoRoute(
        path: '/app/provider/growth',
        builder: (context, state) =>
            ProviderGrowthScreen(session: operationsSession),
      ),
      GoRoute(
        path: '/app/provider/control',
        builder: (context, state) =>
            ProviderControlScreen(session: operationsSession),
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
        path: '/app/activity',
        builder: (context, state) =>
            SharedHubScreen(session: sharedSession, screen: 157),
      ),
      GoRoute(
        path: '/app/account/identity',
        builder: (context, state) => GlobalPersonalProfileV2(
          session: session,
          surfaceTone: state.uri.queryParameters['surface'] == 'social'
              ? GlobalProfileSurfaceTone.socialDark
              : GlobalProfileSurfaceTone.light,
        ),
      ),
      GoRoute(
        path: '/app/ask',
        builder: (context, state) =>
            SharedHubScreen(session: sharedSession, screen: 159),
      ),
      GoRoute(
        path: '/app/files',
        builder: (context, state) =>
            SharedHubScreen(session: sharedSession, screen: 160),
      ),
      GoRoute(
        path: '/app/account/security',
        builder: (context, state) => SharedHubScreen(
          session: sharedSession,
          screen: 161,
          onSignOut: () async {
            final signedOut = await session.signOut();
            if (!context.mounted) return;
            if (signedOut || !session.isAuthenticated) {
              context.go('/sign-in');
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    session.errorMessage ??
                        'Sign-out could not be completed. Please try again.',
                  ),
                ),
              );
            }
          },
        ),
      ),
      GoRoute(
        path: '/app/account/workspaces',
        builder: (context, state) =>
            SharedHubScreen(session: sharedSession, screen: 162),
      ),
      GoRoute(
        path: '/app/account/workspaces/preferences',
        builder: (context, state) => SharedHubScreen(
          session: sharedSession,
          screen: 165,
          initialItemId: state.uri.queryParameters['item'],
        ),
      ),
      GoRoute(
        path: '/app/account/plans',
        builder: (context, state) => SocialPlansV2Screen(
          sharedSession: sharedSession,
          retailerSession: retailerSession,
          creatorSession: creatorSession,
        ),
      ),
      GoRoute(
        path: '/app/social/promote',
        builder: (context, state) => SocialPromotionV2Screen(
          session: retailerSession,
          initialState: state.uri.queryParameters['state'],
          initialStep: int.tryParse(state.uri.queryParameters['step'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/app/work/mool',
        builder: (context, state) {
          session.openMoolFrom('work');
          return UniversalShell(session: session, section: 'mool');
        },
      ),
      GoRoute(
        path: '/app/work/home',
        builder: (context, state) => WorkMainV2(session: workSession),
      ),
      GoRoute(
        path: '/app/work/earn',
        pageBuilder: (context, state) => moolMainDestinationPage(
          state: state,
          child: WorkEarnScreen(session: workSession),
        ),
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
        path: '/app/work/workspace/choose',
        builder: (context, state) =>
            WorkChooseActivityScreen(session: workSession),
      ),
      GoRoute(
        path: '/app/work/workspace/proof',
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
        redirect: (context, state) {
          if (legacyPresentationForTestsOnly) return null;
          final section = state.pathParameters['section'] ?? 'social';
          if (section == 'work') return '/app/work/home';
          final actionChoiceRoot = personalMvpActionChoiceRoots[section];
          if (actionChoiceRoot == null || actionChoiceRoot.actions.isEmpty) {
            return null;
          }
          return actionChoiceRoot.actions.first.route;
        },
        pageBuilder: (context, state) {
          final section = state.pathParameters['section'] ?? 'social';
          final requestedOrigin = state.uri.queryParameters['from'];
          final moolOrigin =
              section == 'mool' &&
                  const {
                    'social',
                    'buy',
                    'eat',
                    'ride',
                    'book',
                    'work',
                  }.contains(requestedOrigin)
              ? requestedOrigin
              : null;
          if (moolOrigin != null) {
            session.openMoolFrom(moolOrigin);
          }
          if (!legacyPresentationForTestsOnly && section == 'mool') {
            void leaveMool() {
              if (context.canPop()) {
                context.pop();
              } else if (moolOrigin != null) {
                context.go('/app/$moolOrigin');
              } else {
                SystemNavigator.pop();
              }
            }

            return moolMainDestinationPage(
              state: state,
              child: PersonalMoolRootV2(
                onBack: leaveMool,
                onOpenAction: (action) => context.go(action.route),
                onOpenRoute: (route) {
                  if (moolOrigin == null) {
                    context.push(route);
                  } else {
                    context.pushReplacement(route);
                  }
                },
                onOpenChat: () =>
                    context.push('/app/chat/inbox?return=/app/mool'),
                onSignOut: () async {
                  final signedOut = await session.signOut();
                  if (!context.mounted) return;
                  if (signedOut || !session.isAuthenticated) {
                    context.go('/sign-in');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          session.errorMessage ??
                              'Sign-out could not be completed. Please try again.',
                        ),
                      ),
                    );
                  }
                },
                areaLabel: session.currentAreaLabel ?? session.manualArea,
              ),
            );
          }
          final actionChoiceRoot = personalMvpActionChoiceRoots[section];
          if (legacyPresentationForTestsOnly && actionChoiceRoot != null) {
            void leaveActionChoiceRoot() {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/app/mool?from=$section');
              }
            }

            return moolMainDestinationPage(
              state: state,
              child: MvpActionChoiceRootV2(
                sectionLabel: actionChoiceRoot.sectionLabel,
                headline: actionChoiceRoot.headline,
                supportingText: actionChoiceRoot.supportingText,
                actions: actionChoiceRoot.actions,
                onBack: leaveActionChoiceRoot,
                onOpenAction: (action) => context.push(action.route),
                onOpenMainAction: (action) => openMoolConnectedRoute(
                  context,
                  activeFamilyId: section,
                  route: action.route,
                ),
                onOpenMool: () => context.push('/app/mool?from=$section'),
                onOpenChat: () =>
                    context.push('/app/chat/inbox?return=/app/$section'),
              ),
            );
          }
          if (!legacyPresentationForTestsOnly &&
              const {
                'social',
                'buy',
                'eat',
                'ride',
                'book',
                'pay',
                'work',
              }.contains(section)) {
            return moolMainDestinationPage(
              state: state,
              child: SocialUniversalV2(
                session: session,
                creatorSession: creatorSession,
                retailerSession: retailerSession,
                sharedSession: sharedSession,
                initialWorld: section,
                initialSubAction: state.uri.queryParameters['sub'],
                initialState:
                    state.uri.queryParameters['state'] ??
                    state.uri.queryParameters['mode'] ??
                    (section == 'social' &&
                            state.uri.queryParameters['sub'] == 'create'
                        ? 'home'
                        : null),
                initialItem: state.uri.queryParameters['item'],
                initialAction: state.uri.queryParameters['action'],
                initialChoice: state.uri.queryParameters['choice'],
                onOpenMool: () => context.push('/app/mool?from=social'),
                onOpenMainAction: (action) => openMoolConnectedRoute(
                  context,
                  activeFamilyId: section,
                  route: action.route,
                ),
              ),
            );
          }
          return moolMainDestinationPage(
            state: state,
            child: UniversalShell(
              session: session,
              section: section,
              initialSubAction: state.uri.queryParameters['sub'],
            ),
          );
        },
      ),
    ],
  );
  return router;
}

ChatThreadType? _chatFilter(String? value) => switch (value) {
  'people' => ChatThreadType.people,
  'business' || 'business-chat' => ChatThreadType.business,
  'order' || 'orders' => ChatThreadType.order,
  'support' => ChatThreadType.support,
  _ => null,
};

BuyV2Destination _buyV2Destination(String? value) => switch (value) {
  'wholesale' || 'business' => BuyV2Destination.wholesale,
  'medicine' || 'rx' => BuyV2Destination.medicine,
  'orders' || 'tracking' => BuyV2Destination.orders,
  _ => BuyV2Destination.shop,
};

BuyV2View _buyV2View(String? value) => switch (value) {
  'product' => BuyV2View.product,
  'basket' || 'cart' => BuyV2View.cart,
  'review' || 'checkout' => BuyV2View.checkout,
  'confirmation' || 'confirmed' => BuyV2View.confirmation,
  'tracking' => BuyV2View.tracking,
  'assist' || 'chat' => BuyV2View.assist,
  'recovery' => BuyV2View.recovery,
  _ => BuyV2View.catalogue,
};

BuyV2RecoveryKind? _buyV2Recovery(String? value) => switch (value) {
  'price' || 'price-update' => BuyV2RecoveryKind.priceUpdate,
  'stock' || 'stock-unavailable' => BuyV2RecoveryKind.stockUnavailable,
  'service' || 'service-area' => BuyV2RecoveryKind.serviceAreaUnavailable,
  'payment' || 'payment-failed' => BuyV2RecoveryKind.paymentFailed,
  'network' || 'offline' => BuyV2RecoveryKind.networkInterruption,
  'delay' || 'delivery-delay' => BuyV2RecoveryKind.deliveryDelay,
  _ => null,
};

BuyV2CartScope _buyV2CartScope(String? value) => switch (value) {
  'shop' || 'retail' => BuyV2CartScope.shop,
  'wholesale' || 'business' => BuyV2CartScope.wholesale,
  'medicine' || 'rx' => BuyV2CartScope.medicine,
  _ => BuyV2CartScope.all,
};
