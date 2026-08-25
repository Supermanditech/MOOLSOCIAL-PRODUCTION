import 'dart:async';

import 'package:flutter/material.dart';

import '../core/design/moolsocial_brand_motion.dart';
import '../core/design/mool_theme.dart';
import '../features/book/book_session.dart';
import '../features/buy/buy_session.dart';
import '../features/captain/captain_session.dart';
import '../features/chat/chat_session.dart';
import '../features/creator/creator_session.dart';
import '../features/eat/eat_session.dart';
import '../features/journey01/journey_router.dart';
import '../features/journey01/journey_session.dart';
import '../features/manufacturer/manufacturer_session.dart';
import '../features/operations/operations_session.dart';
import '../features/pay/pay_session.dart';
import '../features/retailer/retailer_session.dart';
import '../features/ride/ride_session.dart';
import '../features/shared/shared_session.dart';
import '../features/work/work_session.dart';
import '../ui_v2/launch/launch_interruption_guard.dart';
import '../ui_v2/launch/launch_presentation_gate.dart';
import '../ui_v2/motion/mool_buy_tap_acknowledgement.dart';
import '../ui_v2/social/social_v2_consumer.dart';

class MoolSocialApp extends StatefulWidget {
  const MoolSocialApp({
    super.key,
    this.session,
    this.bookSession,
    this.buySession,
    this.captainSession,
    this.chatSession,
    this.creatorSession,
    this.eatSession,
    this.manufacturerSession,
    this.operationsSession,
    this.paySession,
    this.retailerSession,
    this.rideSession,
    this.sharedSession,
    this.workSession,
    this.launchInterruptionGuard,
    this.onAuthenticatedBoundary,
    this.initialLocation = '/boot',
    this.legacyPresentationForTestsOnly = false,
    this.disposeSession = false,
    this.disposeBookSession = false,
    this.disposeBuySession = false,
    this.disposeCaptainSession = false,
    this.disposeChatSession = false,
    this.disposeCreatorSession = false,
    this.disposeEatSession = false,
    this.disposeManufacturerSession = false,
    this.disposeOperationsSession = false,
    this.disposePaySession = false,
    this.disposeRetailerSession = false,
    this.disposeRideSession = false,
    this.disposeSharedSession = false,
    this.disposeWorkSession = false,
    this.disposeLaunchInterruptionGuard = false,
  });

  final JourneySession? session;
  final BookSession? bookSession;
  final BuySession? buySession;
  final CaptainSession? captainSession;
  final ChatSession? chatSession;
  final CreatorSession? creatorSession;
  final EatSession? eatSession;
  final ManufacturerSession? manufacturerSession;
  final OperationsSession? operationsSession;
  final PaySession? paySession;
  final RetailerSession? retailerSession;
  final RideSession? rideSession;
  final SharedSession? sharedSession;
  final WorkSession? workSession;
  final LaunchInterruptionGuard? launchInterruptionGuard;
  final Future<void> Function()? onAuthenticatedBoundary;
  final String initialLocation;

  /// Keeps historical presentation regression tests attached to the untouched
  /// legacy widgets. Product builds must use the default native V2 routes.
  final bool legacyPresentationForTestsOnly;
  final bool disposeSession;
  final bool disposeBookSession;
  final bool disposeBuySession;
  final bool disposeCaptainSession;
  final bool disposeChatSession;
  final bool disposeCreatorSession;
  final bool disposeEatSession;
  final bool disposeManufacturerSession;
  final bool disposeOperationsSession;
  final bool disposePaySession;
  final bool disposeRetailerSession;
  final bool disposeRideSession;
  final bool disposeSharedSession;
  final bool disposeWorkSession;
  final bool disposeLaunchInterruptionGuard;

  @override
  State<MoolSocialApp> createState() => _MoolSocialAppState();
}

class _MoolSocialAppState extends State<MoolSocialApp>
    with WidgetsBindingObserver {
  late final JourneySession _session = widget.session ?? JourneySession();
  late final BookSession _bookSession = widget.bookSession ?? BookSession();
  late final BuySession _buySession = widget.buySession ?? BuySession();
  late final CaptainSession _captainSession =
      widget.captainSession ?? CaptainSession();
  late final ChatSession _chatSession = widget.chatSession ?? ChatSession();
  late final CreatorSession _creatorSession =
      widget.creatorSession ?? CreatorSession();
  late final EatSession _eatSession = widget.eatSession ?? EatSession();
  late final ManufacturerSession _manufacturerSession =
      widget.manufacturerSession ?? ManufacturerSession();
  late final OperationsSession _operationsSession =
      widget.operationsSession ?? OperationsSession();
  late final PaySession _paySession = widget.paySession ?? PaySession();
  late final RetailerSession _retailerSession =
      widget.retailerSession ?? RetailerSession();
  late final RideSession _rideSession = widget.rideSession ?? RideSession();
  late final SharedSession _sharedSession =
      widget.sharedSession ?? SharedSession();
  late final WorkSession _workSession = widget.workSession ?? WorkSession();
  late final LaunchPresentationGate _launchPresentationGate =
      LaunchPresentationGate();
  late final LaunchInterruptionGuard _launchInterruptionGuard =
      widget.launchInterruptionGuard ?? LaunchInterruptionGuard();
  late final MoolSocialBrandCadence _brandCadence = MoolSocialBrandCadence();
  late bool _lastAuthenticated;
  bool _signedOutBoundaryActive = false;
  late final _router = createJourneyRouter(
    _session,
    _bookSession,
    _buySession,
    _captainSession,
    _chatSession,
    _creatorSession,
    _eatSession,
    _manufacturerSession,
    _operationsSession,
    _paySession,
    _retailerSession,
    _rideSession,
    _sharedSession,
    _workSession,
    launchPresentationGate: _launchPresentationGate,
    launchInterruptionGuard: _launchInterruptionGuard,
    initialLocation: widget.initialLocation,
    legacyPresentationForTestsOnly: widget.legacyPresentationForTestsOnly,
  );

  @override
  void initState() {
    super.initState();
    _lastAuthenticated = _session.isAuthenticated;
    WidgetsBinding.instance.addObserver(this);
    _session.addListener(_handleAuthenticationBoundary);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _launchInterruptionGuard.start();
    });
  }

  void _handleAuthenticationBoundary() {
    final authenticated = _session.isAuthenticated;
    if (authenticated == _lastAuthenticated) return;
    final signedOut = _lastAuthenticated && !authenticated;
    _lastAuthenticated = authenticated;
    if (signedOut) {
      _signedOutBoundaryActive = true;
      _chatSession.resetForAuthenticationBoundary();
      _sharedSession.resetForAuthenticationBoundary();
      resetSocialV2RetainedStateForAuthenticationBoundary(_sharedSession);
      return;
    }
    if (authenticated) {
      if (_signedOutBoundaryActive) {
        _signedOutBoundaryActive = false;
        _sharedSession.setAuthorized(true);
      }
      final onAuthenticatedBoundary = widget.onAuthenticatedBoundary;
      if (onAuthenticatedBoundary != null) {
        unawaited(
          Future<void>.sync(onAuthenticatedBoundary).catchError((Object _) {}),
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _brandCadence.appPaused();
      case AppLifecycleState.resumed:
        _brandCadence.appResumed();
        unawaited(_session.retryAuthenticatedAccountRevalidation());
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  Future<bool> didPushRouteInformation(
    RouteInformation routeInformation,
  ) async {
    final location = routeInformation.uri.toString();
    final socialHandled = await _session.prepareSocialAuthReturn(location);
    if (socialHandled) {
      final completedRoute = _session.takeCompletedSocialAuthReturnRoute();
      if (!mounted) return true;
      _router.go(
        _session.isReady ? completedRoute ?? _session.readyRoute() : '/sign-in',
      );
      return true;
    }
    final handled = await _session.prepareEmailLinkReturn(location);
    if (!handled) return false;
    final completedRoute = _session.takeCompletedEmailLinkReturnRoute();
    if (!mounted) return true;

    _router.go(
      _session.isReady ? completedRoute ?? _session.readyRoute() : '/sign-in',
    );
    return true;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _session.removeListener(_handleAuthenticationBoundary);
    _router.dispose();
    _launchPresentationGate.dispose();
    _brandCadence.dispose();
    if (widget.launchInterruptionGuard == null ||
        widget.disposeLaunchInterruptionGuard) {
      _launchInterruptionGuard.dispose();
    }
    if (widget.session == null || widget.disposeSession) {
      _session.dispose();
    }
    if (widget.bookSession == null || widget.disposeBookSession) {
      _bookSession.dispose();
    }
    if (widget.buySession == null || widget.disposeBuySession) {
      _buySession.dispose();
    }
    if (widget.captainSession == null || widget.disposeCaptainSession) {
      _captainSession.dispose();
    }
    if (widget.chatSession == null || widget.disposeChatSession) {
      _chatSession.dispose();
    }
    if (widget.creatorSession == null || widget.disposeCreatorSession) {
      _creatorSession.dispose();
    }
    if (widget.eatSession == null || widget.disposeEatSession) {
      _eatSession.dispose();
    }
    if (widget.manufacturerSession == null ||
        widget.disposeManufacturerSession) {
      _manufacturerSession.dispose();
    }
    if (widget.operationsSession == null || widget.disposeOperationsSession) {
      _operationsSession.dispose();
    }
    if (widget.paySession == null || widget.disposePaySession) {
      _paySession.dispose();
    }
    if (widget.retailerSession == null || widget.disposeRetailerSession) {
      _retailerSession.dispose();
    }
    if (widget.rideSession == null || widget.disposeRideSession) {
      _rideSession.dispose();
    }
    if (widget.sharedSession == null || widget.disposeSharedSession) {
      _sharedSession.dispose();
    }
    if (widget.workSession == null || widget.disposeWorkSession) {
      _workSession.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'MoolSocial',
      theme: MoolTheme.light(),
      routerConfig: _router,
      builder: (context, child) => MoolSocialBrandMotionScope(
        cadence: _brandCadence,
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => _brandCadence.noteActivity(),
          child: MoolBuyTapAcknowledgement(
            isBuyActive: () => _router
                .routerDelegate
                .currentConfiguration
                .matches
                .any((match) => match.matchedLocation.startsWith('/app/buy')),
            routeChanges: _router.routerDelegate,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
