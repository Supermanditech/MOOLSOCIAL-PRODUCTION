import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../core/design/moolsocial_brand_motion.dart';
import '../core/design/mool_theme.dart';
import '../features/book/book_session.dart';
import '../features/assistant/mool_assistant.dart';
import '../ui_v2/buy/buy_v2_views.dart' show buyShopReviewNativeAdapters, buyBrowseNativeAdapters, buyCartReviewNativeAdapters, buyShop04NativeAdapters, buyShop06NativeAdapters,buyShop05NativeAdapters;
import '../ui_v2/buy/buy_v2_screen.dart'
    show BuyCartQuantityNativeAdapter, BuySearchNativeAdapter, buyShopFormNativeAdapters;
import '../features/buy/buy_session.dart';
import '../features/buy/buy_v2_session.dart';
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
import '../features/shared/social_create_draft_repository.dart';
import '../features/work/work_session.dart';
import '../features/work/screens/work_onboarding_screens.dart' show WorkspaceSetupNativeCoordinator, workspaceSetupNativeAdapters;
import '../features/work/work_services.dart' show SecureWorkBulkQuoteJournal;
import '../ui_v2/launch/launch_interruption_guard.dart';
import '../ui_v2/assistant/mool_assistant_v2.dart';
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
    @visibleForTesting this.createDraftStateCache,
    this.initialLocation = '/boot',
    this.uiReviewOnly = false,
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
  final SocialCreateDraftStateCache? createDraftStateCache;
  final String initialLocation;
  final bool uiReviewOnly;

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
  late final WorkspaceSetupNativeCoordinator _workspaceSetupNative = WorkspaceSetupNativeCoordinator();
  late final WorkSession _workSession = widget.workSession ?? WorkSession();
  late final LaunchPresentationGate _launchPresentationGate =
      LaunchPresentationGate();
  late final LaunchInterruptionGuard _launchInterruptionGuard =
      widget.launchInterruptionGuard ?? LaunchInterruptionGuard();
  late final MoolSocialBrandCadence _brandCadence = MoolSocialBrandCadence();
  late bool _lastAuthenticated;
  bool _signedOutBoundaryActive = false;
  Future<void> _authenticationBoundaryTail = Future<void>.value();
  late final BuyV2RootSessions _buyRoot;
  late GoRouter _router;
  VoidCallback? _routerBuyCleanup;
  final List<VoidCallback> _retiredRouterCleanups = [];

  GoRouter _createRouter(String initialLocation) {
    _workSession.bindBulkQuoteSource(_buyRoot.current.bulkQuotes);
    _workSession.bindOriginalPurchaseReader(_buyRoot.current.purchaseReader, _buyRoot.current.purchaseRealm);
    _workSession.bindProductPresentationReader(_buyRoot.current.productPresentations);
    return createJourneyRouter(
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
    initialLocation: initialLocation,
    uiReviewOnly: widget.uiReviewOnly,
    publicBuySession: _buyRoot.current,
    registerOwnedBuySessionCleanup: (cleanup) => _routerBuyCleanup = cleanup,
    // Forward the test-only override; production leaves it null.
    // ignore: invalid_use_of_visible_for_testing_member
    createDraftStateCache: widget.createDraftStateCache,
    legacyPresentationForTestsOnly: widget.legacyPresentationForTestsOnly,
  );
  }

  @override
  void initState() {
    super.initState();
    _buyRoot = BuyV2RootSessions(core: _buySession,
      currentIdentity: () => _session.authenticatedBuyPersistenceIdentity,
      bulkQuoteJournalFactory: (identity, current) => SecureWorkBulkQuoteJournal(
        currentAccount: () => current() ? identity.userId : null),
      preserveReview: widget.uiReviewOnly ||
        const bool.fromEnvironment('MOOLSOCIAL_UI_REVIEW_ONLY') ||
        (kDebugMode && _session.usesReviewAccountIdentity));
    _buyRoot.synchronize(accountRequired: _session.isAuthenticated ||
      _session.authenticatedRevalidationPending || _session.principalBindingCleanupRequired);
    _router = _createRouter(widget.initialLocation);
    _lastAuthenticated = _session.isAuthenticated;
    WidgetsBinding.instance.addObserver(this);
    _session.addListener(_handleAuthenticationBoundary);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _launchInterruptionGuard.start();
    });
  }

  void _handleAuthenticationBoundary() {
    if (_buyRoot.synchronize(accountRequired: _session.isAuthenticated ||
        _session.authenticatedRevalidationPending || _session.principalBindingCleanupRequired)) {
      final previous = _router;
      final cleanup = _routerBuyCleanup;
      final location = previous.routeInformationProvider.value.uri.toString();
      _router = _createRouter(location);
      var retired = false;
      void retire() {
        if (retired) return;
        retired = true;
        previous.dispose();
        cleanup?.call();
      }
      _retiredRouterCleanups.add(retire);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _retiredRouterCleanups.remove(retire);
        retire();
      });
      if (mounted) setState(() {});
    }
    final authenticated = _session.isAuthenticated;
    if (authenticated == _lastAuthenticated) return;
    final signedOut = _lastAuthenticated && !authenticated;
    _lastAuthenticated = authenticated;
    if (signedOut) {
      _signedOutBoundaryActive = true;
      _chatSession.resetForAuthenticationBoundary();
      _sharedSession.resetForAuthenticationBoundary();
      _queueAuthenticationBoundary(() async {
        final passed =
            await resetSocialV2RetainedStateForAuthenticationBoundary(
              _sharedSession,
            );
        debugPrint(
          'MOOLSOCIAL_AUTH_BOUNDARY social_create_draft_cleanup='
          '${passed ? 'passed' : 'degraded'}',
        );
      });
      return;
    }
    if (authenticated) {
      if (_signedOutBoundaryActive) {
        _signedOutBoundaryActive = false;
        _sharedSession.setAuthorized(true);
      }
      final onAuthenticatedBoundary = widget.onAuthenticatedBoundary;
      if (onAuthenticatedBoundary != null) {
        _queueAuthenticationBoundary(onAuthenticatedBoundary);
      }
    }
  }

  void _queueAuthenticationBoundary(Future<void> Function() operation) {
    final queued = _authenticationBoundaryTail.then<void>(
      (_) => operation(),
      onError: (Object _, StackTrace _) => operation(),
    );
    _authenticationBoundaryTail = queued.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
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
    _workspaceSetupNative.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _session.removeListener(_handleAuthenticationBoundary);
    _router.dispose();
    _routerBuyCleanup?.call();
    for (final cleanup in _retiredRouterCleanups.toList()) {
      cleanup();
    }
    _retiredRouterCleanups.clear();
    _buyRoot.dispose();
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
      builder: (context, child) => MoolAssistantHost(
        readContext: () => MoolAssistantContext(
          accountScope: _session.authenticatedBuyPersistenceIdentity,
          authenticationRevision: _session.navigationAuthenticationGeneration,
        ),
        contextChanges: Listenable.merge([_session, _workSession]),
        child: MoolAssistantNativeScope(
          readAdapters: (assistantContext) {
            final buy = _buyRoot.current;
            final router = _router;
            final navigator = Navigator.of(assistantContext, rootNavigator: true);
            final workspaceScope = assistantContext
                .getInheritedWidgetOfExactType<MoolAssistantWorkspaceScope>();
            MoolAssistantContext currentContext() => MoolAssistantContext(
              accountScope: _session.authenticatedBuyPersistenceIdentity,
              authenticationRevision: _session.navigationAuthenticationGeneration,
            ).withWorkspace(workspaceScope?.readWorkspace());
            bool rootCurrent() => mounted && navigator.mounted &&
                identical(_router, router) && identical(_buyRoot.current, buy);
            final buyFormLocation = router.state.uri;
            final buyFormPageKey = router.state.pageKey;
            bool buyFormRootCurrent() => rootCurrent() &&
                buyFormLocation.path.startsWith('/app/buy') &&
                router.state.uri == buyFormLocation && router.state.pageKey == buyFormPageKey;
            final setupLocation = router.state.uri, setupPageKey = router.state.pageKey;
            return [
              if (workspaceScope == null) ...workspaceSetupNativeAdapters(
                session: _workSession, navigator: navigator, coordinator: _workspaceSetupNative,
                currentContext: currentContext, accountIdentity: () => _session.accountIdentity,
                accountAuthenticated: () => _session.isAuthenticated && _session.accountIdentity?.firebasePrincipal != null,
                nativeAccountCurrent: () => _session.authenticatedBuyPersistenceIdentity?.userId == _workSession.workspaceApplicationAccountScope,
                approvedWorkspacesCurrent: () => _workSession.workspaceApprovalMatchesAccount(_session.authenticatedBuyPersistenceIdentity),
                isRootCurrent: rootCurrent,
                isNavigationCurrent: () => rootCurrent() && router.state.uri == setupLocation && router.state.pageKey == setupPageKey,
                changes: Listenable.merge([_session, _workSession, router.routerDelegate]),
                onNativeRoute: (route) { if (route == '/app/work/workspace/dashboard') router.go(route); else unawaited(router.push<void>(route)); }),
              BuySearchNativeAdapter(
                session: buy,
                navigator: navigator,
                currentContext: currentContext,
                isRootCurrent: rootCurrent,
                scopeOwner: _session,
                accountIdentity: () => _session.accountIdentity,
                accountAuthenticated: () => _session.isAuthenticated,
              ),
              if (workspaceScope == null && buyFormRootCurrent()) BuyCartQuantityNativeAdapter(
                context: assistantContext,
                session: buy,
                navigator: navigator,
                currentContext: currentContext,
                isRootCurrent: buyFormRootCurrent,
                scopeOwner: Listenable.merge([_session, buy, router.routerDelegate]),
              ),
              if (workspaceScope == null && buyFormRootCurrent()) ...buyShopFormNativeAdapters(
                session: buy, navigator: navigator, currentContext: currentContext,
                isRootCurrent: buyFormRootCurrent,
                scopeOwner: Listenable.merge([_session, buy, router.routerDelegate]),
                accountIdentity: () => _session.accountIdentity,
                accountAuthenticated: () => _session.isAuthenticated,
              ),
              if (workspaceScope == null && buyFormRootCurrent()) ...buyShopReviewNativeAdapters(
                session: buy, navigator: navigator, currentContext: currentContext,
                isRootCurrent: buyFormRootCurrent,
                scopeOwner: Listenable.merge([_session, buy, router.routerDelegate]),
                accountIdentity: () => _session.accountIdentity,
                accountAuthenticated: () => _session.isAuthenticated,
              ),
              if (workspaceScope == null && buyFormRootCurrent()) ...buyBrowseNativeAdapters(
                session: buy, navigator: navigator, currentContext: currentContext,
                isRootCurrent: buyFormRootCurrent,
                scopeOwner: Listenable.merge([_session, buy, router.routerDelegate]),
                accountIdentity: () => _session.accountIdentity,
                accountAuthenticated: () => _session.isAuthenticated,
              ),
              if (workspaceScope == null && buyFormRootCurrent()) ...buyCartReviewNativeAdapters(
                session: buy, navigator: navigator, currentContext: currentContext,
                isRootCurrent: buyFormRootCurrent,
                scopeOwner: Listenable.merge([_session, buy, router.routerDelegate]),
                accountIdentity: () => _session.accountIdentity,
                accountAuthenticated: () => _session.isAuthenticated,
              ),
              if (workspaceScope == null && buyFormRootCurrent()) ...buyShop04NativeAdapters(
                session: buy, navigator: navigator, currentContext: currentContext,
                isRootCurrent: buyFormRootCurrent,
                scopeOwner: Listenable.merge([_session, buy, router.routerDelegate]),
                accountIdentity: () => _session.accountIdentity,
                accountAuthenticated: () => _session.isAuthenticated,
              ),
              if (workspaceScope == null && buyFormRootCurrent()) ...buyShop05NativeAdapters(
                session: buy, navigator: navigator, currentContext: currentContext,
                isRootCurrent: buyFormRootCurrent,
                scopeOwner: Listenable.merge([_session, buy, router.routerDelegate]),
                accountIdentity: () => _session.accountIdentity,
                accountAuthenticated: () => _session.isAuthenticated,
              ),
              if (workspaceScope == null && buyFormRootCurrent()) ...buyShop06NativeAdapters(
                session: buy, navigator: navigator, currentContext: currentContext,
                isRootCurrent: buyFormRootCurrent,
                scopeOwner: Listenable.merge([_session, buy, router.routerDelegate]),
                accountIdentity: () => _session.accountIdentity,
                accountAuthenticated: () => _session.isAuthenticated,
              ),
            ];
          },
          child: MoolSocialBrandMotionScope(
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
        ),
      ),
    );
  }
}
