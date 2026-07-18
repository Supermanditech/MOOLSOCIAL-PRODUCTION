import 'package:go_router/go_router.dart';

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
import '../chat/chat_session.dart';
import '../chat/screens/chat_inbox_screen.dart';
import '../chat/screens/chat_thread_screen.dart';
import 'journey_session.dart';
import 'screens/boot_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/universal_shell.dart';
import 'screens/verify_otp_screen.dart';

GoRouter createJourneyRouter(
  JourneySession session,
  BuySession buySession,
  ChatSession chatSession, {
  String initialLocation = '/boot',
}) {
  return GoRouter(
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
        path: '/app/:section',
        builder: (context, state) => UniversalShell(
          session: session,
          section: state.pathParameters['section'] ?? 'social',
          initialSubAction: state.uri.queryParameters['sub'],
        ),
      ),
    ],
  );
}
