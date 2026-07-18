import 'package:go_router/go_router.dart';

import 'journey_session.dart';
import 'screens/boot_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/universal_shell.dart';
import 'screens/verify_otp_screen.dart';

GoRouter createJourneyRouter(
  JourneySession session, {
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
