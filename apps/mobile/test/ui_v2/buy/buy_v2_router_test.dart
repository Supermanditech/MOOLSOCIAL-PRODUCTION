import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_saved_products_store.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

// Host-only live-identity contract fixture; never native authentication evidence.
class _LfRootIdentity extends ReviewAuthenticatedAccountIdentityGateway
    implements AuthenticatedAccountPrincipalSource {
  _LfRootIdentity() : super(identity: const AuthenticatedAccountIdentity(
    firebaseUserId: 'host-user-a', firebaseProjectId: 'host-project'));
  final changes = StreamController<void>.broadcast(sync: true);
  @override
  ({String projectId, String? tenantId, String userId})? get currentFirebasePrincipal => identity?.firebasePrincipal;
  @override
  Stream<void> get firebasePrincipalChanges => changes.stream;
  @override
  String get persistenceEnvironment => 'host-fixture-service';
  void change(String uid) {
    identity = AuthenticatedAccountIdentity(firebaseUserId: uid, firebaseProjectId: 'host-project');
    changes.add(null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('LF root boot retains the returning account Social destination', (tester) async {
    final lifecycle = tester.binding.lifecycleState;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    addTearDown(() => tester.binding.handleAppLifecycleStateChanged(
      lifecycle ?? AppLifecycleState.detached));
    final journey = JourneySession(store: MemoryJourneyStore(snapshot: const JourneySnapshot(
      languageCode: 'en', areaMode: 'current', currentAreaLabel: 'Host evaluation area',
      setupComplete: true, lastReadyRoute: '/app/work/my-work')),
      otpGateway: ReviewOtpGateway(signedIn: true));
    addTearDown(journey.dispose);
    await journey.start();
    await tester.pumpWidget(MoolSocialApp(session: journey, initialLocation: '/boot'));
    // Complete the async router's first splash frame before its visible interval.
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    final router = tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig! as GoRouter;
    expect(router.routeInformationProvider.value.uri.path, '/app/social');
    expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('LF root binds authenticated Buy to an account store instead of review state', (tester) async {
    final previous = SharedPreferencesAsyncPlatform.instance;
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    addTearDown(() => SharedPreferencesAsyncPlatform.instance = previous);
    final identity = _LfRootIdentity();
    final journey = JourneySession(store: MemoryJourneyStore(snapshot: const JourneySnapshot(
      languageCode: 'en', areaMode: 'skipped', setupComplete: true)),
      otpGateway: ReviewOtpGateway(signedIn: true), accountIdentityGateway: identity);
    addTearDown(identity.changes.close);
    addTearDown(journey.dispose);
    await journey.start();
    await tester.pumpWidget(MoolSocialApp(session: journey, initialLocation: '/app/buy'));
    await tester.pumpAndSettle();
    final buy = tester.widget<BuyV2Screen>(find.byType(BuyV2Screen)).session;
    expect(buy.customerStateStore?.ownerScope, startsWith('firebase-account:v1:'));
    expect(buy.reviewDataEnabled, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('LF root owner change closes stale overlays but routine notifications do not', (tester) async {
    final previous = SharedPreferencesAsyncPlatform.instance;
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    addTearDown(() => SharedPreferencesAsyncPlatform.instance = previous);
    final identity = _LfRootIdentity();
    final journey = JourneySession(store: MemoryJourneyStore(snapshot: const JourneySnapshot(
      languageCode: 'en', areaMode: 'skipped', setupComplete: true)),
      otpGateway: ReviewOtpGateway(signedIn: true), accountIdentityGateway: identity);
    addTearDown(identity.changes.close);
    addTearDown(journey.dispose);
    await journey.start();
    await tester.pumpWidget(MoolSocialApp(session: journey, initialLocation: '/app/buy?view=cart'));
    await tester.pumpAndSettle();
    final first = tester.widget<BuyV2Screen>(find.byType(BuyV2Screen)).session;
    final ownerA = first.customerStateStore!.ownerScope;
    unawaited(showDialog<void>(context: tester.element(find.byType(BuyV2Screen)),
      builder: (_) => const AlertDialog(content: Text('Host owner A private overlay'))));
    await tester.pumpAndSettle();
    identity.changes.add(null);
    await tester.pumpAndSettle();
    expect(find.text('Host owner A private overlay'), findsOneWidget);
    expect(identical(tester.widget<BuyV2Screen>(find.byType(BuyV2Screen)).session, first), isTrue);
    identity.change('host-user-b');
    await tester.pumpAndSettle();
    expect(find.text('Host owner A private overlay'), findsNothing);
    final blocked = tester.widget<BuyV2Screen>(find.byType(BuyV2Screen)).session;
    expect(blocked.customerStateStore, isNull);
    expect(blocked.reviewDataEnabled, isFalse);
    expect(await journey.retryAuthenticatedAccountRevalidation(), isTrue);
    await tester.pumpAndSettle();
    final second = tester.widget<BuyV2Screen>(find.byType(BuyV2Screen)).session;
    expect(second.customerStateStore!.ownerScope, isNot(ownerA));
    expect(second.customerStateStore!.ownerScope, startsWith('firebase-account:v1:'));
    expect(second.cartLines, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('LF root reauthorizes the same order link without another account cache', (tester) async {
    final previous = SharedPreferencesAsyncPlatform.instance;
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    addTearDown(() => SharedPreferencesAsyncPlatform.instance = previous);
    final identity = _LfRootIdentity();
    final journey = JourneySession(store: MemoryJourneyStore(snapshot: const JourneySnapshot(
      languageCode: 'en', areaMode: 'skipped', setupComplete: true)),
      otpGateway: ReviewOtpGateway(signedIn: true), accountIdentityGateway: identity);
    addTearDown(identity.changes.close);
    addTearDown(journey.dispose);
    await journey.start();
    final ownerA = journey.authenticatedBuyPersistenceIdentity!;
    final cache = BuyV2SharedPreferencesCustomerStateStore.forAccount(SharedPreferencesAsync(),
      identity: ownerA, currentIdentity: () => journey.authenticatedBuyPersistenceIdentity,
      isSessionCurrent: () => true);
    expect(await cache.write(const BuyV2CustomerStateSnapshot(orders: [
      BuyV2Order(id: 'host-owner-a-order', purchaseId: 'host-owner-a-purchase',
        destination: BuyV2Destination.shop, title: 'Host A purchase',
        itemSummary: 'Host A purchase', total: 20, partner: 'Host seller',
        partnerType: 'Retailer', promise: 'Host promised window',
        destinationLabel: 'Host destination', progress: 0,
        status: BuyV2OrderStatus.confirmed),
    ])), isTrue);
    expect((await cache.read())!.orders.single.id, 'host-owner-a-order');
    const path = '/app/buy/order/host-owner-a-order';
    await tester.pumpWidget(MoolSocialApp(session: journey, initialLocation: path));
    await tester.pumpAndSettle();
    expect(tester.widget<BuyV2Screen>(find.byType(BuyV2Screen)).session.orders
      .any((o) => o.id == 'host-owner-a-order'), isTrue);
    identity.change('host-user-b');
    await tester.pumpAndSettle();
    expect(await journey.retryAuthenticatedAccountRevalidation(), isTrue);
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(BuyV2Screen));
    expect(GoRouter.of(context).routeInformationProvider.value.uri.path, path);
    expect(tester.widget<BuyV2Screen>(find.byType(BuyV2Screen)).session.orders, isEmpty);
    expect(find.text('Host A purchase'), findsNothing);
    identity.change('host-user-a');
    await tester.pumpAndSettle();
    expect(await journey.retryAuthenticatedAccountRevalidation(), isTrue);
    await tester.pumpAndSettle();
    expect(tester.widget<BuyV2Screen>(find.byType(BuyV2Screen)).session.orders
      .any((o) => o.id == 'host-owner-a-order'), isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  Future<void> mountRoute(WidgetTester tester, String route) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    final journey = JourneySession(
      store: MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'manual',
          areaLabel: 'Sardarpura',
          setupComplete: true,
        ),
      ),
      otpGateway: ReviewOtpGateway(signedIn: true),
    );
    final buy = BuySession();
    addTearDown(journey.dispose);
    addTearDown(buy.dispose);
    await journey.start();
    await tester.pumpWidget(
      MoolSocialApp(session: journey, buySession: buy, initialLocation: route),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapConnectedAction(
    WidgetTester tester,
    String family,
    String action,
  ) async {
    await tester.tap(find.byKey(const Key('mool-compact-launcher')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('mool-navigator-family-$family')));
    await tester.pumpAndSettle();
    if (action != 'shop') {
      await tester.tap(find.byKey(ValueKey('buy-local-tab-$action')));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('production Buy entry mounts V2 and never the legacy shell', (
    tester,
  ) async {
    await mountRoute(tester, '/app/buy');

    expect(find.byKey(const Key('buy-v2-screen')), findsOneWidget);
    expect(find.byKey(const Key('buy-catalog-screen')), findsNothing);
    expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
    expect(find.byKey(const Key('buy-local-destination-tabs')), findsOneWidget);
    expect(find.byKey(const Key('buy-local-tab-wholesale')), findsOneWidget);
    expect(find.byKey(const Key('buy-local-tab-orders')), findsOneWidget);
    await tester.tap(find.byKey(const Key('mool-compact-launcher')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mool-navigator-family-buy')), findsOneWidget);
    expect(find.byKey(const Key('mool-navigator-buy-shop')), findsNothing);
    expect(find.byKey(const Key('mool-navigator-buy-orders')), findsNothing);
  });

  testWidgets('historical Buy deep links resolve to V2 destinations', (
    tester,
  ) async {
    await mountRoute(tester, '/app/buy/medicine');

    expect(find.byKey(const Key('buy-v2-screen')), findsOneWidget);
    expect(find.text('Search medicines'), findsOneWidget);
    expect(find.byKey(const Key('buy-medicine-screen')), findsNothing);
  });

  testWidgets('query routes expose the approved Wholesale and Orders states', (
    tester,
  ) async {
    await mountRoute(tester, '/app/buy?sub=wholesale');
    expect(find.text('Find wholesale products'), findsOneWidget);

    await tapConnectedAction(tester, 'buy', 'orders');
    expect(find.byKey(const PageStorageKey('buy-orders')), findsOneWidget);
    expect(find.text('Orders'), findsWidgets);
  });

  testWidgets('Offers deep link restores the exact Offers catalogue', (
    tester,
  ) async {
    await mountRoute(tester, '/app/buy?sub=offers');

    expect(find.byKey(const PageStorageKey('buy-offers')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('buy-offers-publisher-summary')),
      findsOneWidget,
    );
    expect(find.text('Search current offers'), findsOneWidget);
  });

  testWidgets('Screen 04 Mool Buy action opens only the native Buy V2', (
    tester,
  ) async {
    await mountRoute(tester, '/app/social');

    await tapConnectedAction(tester, 'buy', 'shop');

    expect(find.byKey(const Key('buy-v2-screen')), findsOneWidget);
    expect(find.byKey(const Key('buy-catalog-screen')), findsNothing);
  });

  testWidgets('every historical Buy order route stays inside V2', (
    tester,
  ) async {
    for (final route in const [
      '/app/buy/order/MS-240782/collection',
      '/app/buy/order/MS-240782/collection-completed',
      '/app/buy/order/MS-240782/completed',
      '/app/buy/order/MS-240782/problem',
    ]) {
      await mountRoute(tester, route);
      expect(find.byKey(const Key('buy-v2-screen')), findsOneWidget);
      expect(find.byKey(const Key('buy-catalog-screen')), findsNothing);
    }
  });

  testWidgets('all approved recovery routes mount their native state', (
    tester,
  ) async {
    for (final recovery in const [
      'price',
      'stock',
      'service',
      'payment',
      'network',
      'delay',
    ]) {
      await mountRoute(tester, '/app/buy?view=recovery&recovery=$recovery');
      expect(find.byKey(const Key('buy-v2-screen')), findsOneWidget);
      expect(find.byKey(const Key('buy-recovery-primary')), findsOneWidget);
    }
  });

  testWidgets(
    'stale Buy deep links never substitute another product or order',
    (tester) async {
      await mountRoute(tester, '/app/buy/product/missing-product');

      expect(find.byKey(const Key('buy-linked-product-recovery')), findsOneWidget);
      expect(find.text('Product unavailable'), findsOneWidget);
      expect(
        find.text(
          'This product could not be opened. Try again or return to shopping.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('buy-product-detail')), findsNothing);
      await tester.tap(find.byKey(const Key('buy-catalogue-retry')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('buy-linked-product-recovery')), findsOneWidget);
      expect(find.byKey(const Key('buy-product-detail')), findsNothing);
      await tester.tap(find.byKey(const Key('buy-procurement-return')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('buy-linked-product-recovery')), findsNothing);
      expect(find.byKey(const Key('buy-v2-screen')), findsOneWidget);
      expect(find.byKey(const Key('buy-product-detail')), findsNothing);
      expect(tester.takeException(), isNull);

      await mountRoute(tester, '/app/buy/order/missing-order');

      expect(find.text('This order could not be found.'), findsOneWidget);
      expect(find.byKey(const Key('buy-order-tracking')), findsNothing);
      expect(find.byKey(const PageStorageKey('buy-orders')), findsOneWidget);
    },
  );
}
