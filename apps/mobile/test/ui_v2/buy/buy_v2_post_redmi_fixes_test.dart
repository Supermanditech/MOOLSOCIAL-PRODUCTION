import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_customer_copy.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/features/buy/buy_v2_saved_products_store.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_catalogue.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart'
    show BuyV2ProductPackshot, buyV2DeliveryPromiseSummary;
import 'package:moolsocial/ui_v2/buy/buy_v2_views.dart';

import 'buy_v2_screen_test.dart' show captureR66Visual, r66VisualCaptureRoot;

class _ComparisonUnavailableSession extends BuyV2Session {
  _ComparisonUnavailableSession({required super.core})
    : super(reviewDataEnabled: true);

  @override
  BuyV2ComparisonSource? get comparisonSource => null;
}

class _EligibilityFacts implements BuyV2ProductFactsAdapter {
  BuyV2OfferEligibility? eligibility;
  bool invalid = false;
  @override
  BuyV2ProductFactsSnapshot snapshotFor(BuyV2Product product) =>
      const BuyV2CatalogueProductFactsAdapter()
          .snapshotFor(product)
          .copyWith(
            eligibility: eligibility,
            sourceId: invalid ? '' : 'eligibility-test-facts',
          );
}

class _OrganizedProductFacts implements BuyV2ProductFactsAdapter {
  bool closed = false;
  @override
  BuyV2ProductFactsSnapshot snapshotFor(BuyV2Product product) =>
      const BuyV2CatalogueProductFactsAdapter()
          .snapshotFor(product)
          .copyWith(
            sourceId: 'organized-product-test',
            storeOperatingState: closed
                ? BuyV2StoreOperatingState.closed
                : BuyV2StoreOperatingState.open,
            nextOpeningLabel: 'Opens tomorrow at 9 am',
            deliveryFeeLabel: 'Confirmed at checkout',
            orderCutoffLabel: 'Order before 14:30 for packing today',
            dispatchPromise: 'Dispatched after Store packing confirmation',
            deliveryProviderName:
                'Test local delivery provider serving this Store',
            deliveryServiceLevel: 'Confirmed at checkout',
          );
}

class _ControlsCustomerStore implements BuyV2CustomerStateStore {
  _ControlsCustomerStore(this.snapshot);
  BuyV2CustomerStateSnapshot snapshot;
  @override
  String get ownerScope => 'controls-regression-customer';
  @override
  Future<BuyV2CustomerStateSnapshot> read() async => snapshot;
  @override
  Future<bool> write(BuyV2CustomerStateSnapshot value) async {
    snapshot = value;
    return true;
  }
}

class _ControlsCommerce implements BuyV2CommerceAdapter {
  BuyV2CommerceSnapshot snapshot = const BuyV2CommerceSnapshot(
    state: BuyV2CommerceLoadState.ready,
  );
  @override
  Future<BuyV2CommerceSnapshot> refresh() async => snapshot;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected controls regression provider call');
}

class _EightLocationSource implements BuyV2ShoppingAreaSource {
  Object? failure;
  int calls = 0;
  Completer<BuyV2ShoppingArea?>? pending;
  static const area = BuyV2ShoppingArea(
    regionId: 'jodhpur',
    googlePlaceId: 'test-place-current',
    label: 'Current location test locality, Jodhpur',
    countryCode: 'IN',
  );
  @override
  Future<BuyV2ShoppingArea?> locate() async {
    calls++;
    if (pending != null) return pending!.future;
    if (failure != null) throw failure!;
    return area;
  }

  @override
  Future<List<BuyV2ShoppingArea>> search(String query) async =>
      throw StateError('Manual search removed');
  @override
  Future<BuyV2ShoppingArea?> resolve(String id) async => area;
}

Widget _eightApp(
  BuyV2Session session, {
  double scale = 1,
  bool offers = false,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: MoolTheme.light(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
    child: r66VisualCaptureRoot(child!),
  ),
  home: BuyV2Screen(
    session: session,
    initialDestination: session.destination,
    initialView: session.view,
    productId: session.selectedProductId,
    initialOffersActive: offers,
  ),
);

void main() {
  group('r6634 registered replay corrections', () {
    test(
      'new Add reveals basket while in-Cart quantity edits retain position',
      () {
        final core = BuySession();
        final session = BuyV2Session(core: core);
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        session.rememberCartScrollOffset(BuyV2CartScope.all, 900);
        session.rememberCartScrollOffset(BuyV2CartScope.shop, 750);
        expect(session.addProduct('s-tomato'), isTrue);
        expect(session.cartScrollOffsetFor(BuyV2CartScope.all), 0);
        expect(session.cartScrollOffsetFor(BuyV2CartScope.shop), 0);
        session.openCart();
        session.rememberCartScrollOffset(BuyV2CartScope.all, 125);
        session.increase('s-tomato');
        expect(session.cartScrollOffsetFor(BuyV2CartScope.all), 125);
      },
    );
    for (final state in [
      BuyV2CheckoutSubmissionState.cancelled,
      BuyV2CheckoutSubmissionState.failed,
      BuyV2CheckoutSubmissionState.unavailable,
    ]) {
      test('terminal $state allows another method without changing basket', () {
        final core = BuySession();
        final session = BuyV2Session(core: core);
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        session.addProduct('s-tomato');
        session.openCart();
        expect(session.openCheckout(), isTrue);
        session.checkoutSubmissionState = state;
        expect(session.choosePayment('Paytm'), isTrue);
        expect(
          session.checkoutSubmissionState,
          BuyV2CheckoutSubmissionState.idle,
        );
        expect(session.checkoutStep, BuyV2CheckoutStep.payment);
        expect(session.quantityFor('s-tomato'), 1);
        expect(session.confirmedPurchaseId, isNull);
      });
    }
    for (final state in [
      BuyV2CheckoutSubmissionState.paymentPending,
      BuyV2CheckoutSubmissionState.paymentUnknown,
      BuyV2CheckoutSubmissionState.paymentActionRequired,
    ]) {
      test('unresolved $state still prevents payment and basket mutation', () {
        final core = BuySession();
        final session = BuyV2Session(core: core);
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        session.addProduct('s-tomato');
        session.checkoutSubmissionState = state;
        expect(session.choosePayment('Paytm'), isFalse);
        expect(session.addProduct('w-notebook'), isFalse);
        expect(session.quantityFor('s-tomato'), 1);
        expect(session.quantityFor('w-notebook'), 0);
        expect(session.checkoutSubmissionState, state);
      });
    }
    test(
      'combined active delivery estimate never claims completed delivery',
      () {
        expect(
          buyV2DeliveryPromiseSummary(
            promise: 'Delivered in 30 min · Delivered by 8 pm',
          ),
          'Delivery in 30 min · Delivery by 8 pm',
        );
      },
    );
  });
  group('Cursor eight tickets', () {
    for (final id in ['s-tomato', 'w-rice']) {
      for (final entry in ['search', 'saved', 'recent']) {
        testWidgets('approved product layout from $entry $id', (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(390, 844);
          addTearDown(tester.view.reset);
          final core = BuySession();
          final session = BuyV2Session(core: core);
          addTearDown(session.dispose);
          addTearDown(core.dispose);
          final product = session.product(id);
          session.openDestination(product.destination);
          session.openProduct(id);
          session.closeProduct();
          if (!session.isSaved(id)) session.toggleSaved(id);
          if (product.destination == BuyV2Destination.wholesale) {
            session.chooseWholesaleSaleType(BuyV2WholesaleSaleType.bulk);
          }
          await tester.pumpWidget(_eightApp(session));
          await tester.pumpAndSettle();
          Finder tile;
          if (entry == 'search') {
            await tester.tap(find.byKey(const ValueKey('buy-search-control')));
            await tester.pumpAndSettle();
            await tester.enterText(
              find.byKey(const ValueKey('buy-search-field')),
              product.customerTitle,
            );
            await tester.pumpAndSettle();
            tile = find.byKey(ValueKey('buy-product-$id'));
          } else if (entry == 'saved') {
            await tester.tap(
              find.byKey(const ValueKey('buy-saved-products-button')),
            );
            await tester.pumpAndSettle();
            tile = find.byKey(ValueKey('buy-product-$id'));
          } else {
            final context = tester.element(find.byType(BuyV2Screen));
            unawaited(showBuyV2RecentlyViewed(context, session));
            await tester.pumpAndSettle();
            tile = find.byKey(
              ValueKey('buy-settings-recently-viewed-product-$id'),
            );
          }
          await tester.ensureVisible(tile);
          await tester.tap(tile);
          await tester.pumpAndSettle();
          expect(session.selectedProductId, id);
          expect(session.view, BuyV2View.product);
          final hero = find.byKey(ValueKey('buy-product-purchase-hero-$id'));
          await tester.ensureVisible(hero);
          await tester.pumpAndSettle();
          expect(
            find.descendant(
              of: hero,
              matching: find.byKey(ValueKey('buy-product-hero-store-$id')),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: hero,
              matching: find.text('Delivery & returns'),
            ),
            findsNothing,
          );
          final details = find.byKey(ValueKey('buy-automatic-fulfilment-$id'));
          await tester.ensureVisible(details);
          await tester.pumpAndSettle();
          expect(
            find.descendant(
              of: details,
              matching: find.text('Delivery & returns'),
            ),
            findsOneWidget,
          );
          final action = find.byKey(ValueKey('buy-product-primary-$id'));
          await tester.scrollUntilVisible(
            action,
            -180,
            scrollable: find
                .descendant(
                  of: find.byKey(PageStorageKey('buy-product-$id')),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await tester.pumpAndSettle();
          expect(action.hitTestable(), findsOneWidget);
          await tester.tap(action);
          await tester.pumpAndSettle();
          expect(session.quantityFor(id), product.minimumOrder);
          await captureR66Visual(tester, 'approved-product-$entry-$id');
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        });
      }
    }
    testWidgets(
      'organized provider facts remain distinct at large text and closed Store blocks Add',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 844);
        addTearDown(tester.view.reset);
        final core = BuySession();
        final facts = _OrganizedProductFacts();
        final session = BuyV2Session(core: core, productFactsAdapter: facts);
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        session.openProduct('s-tomato');
        await tester.pumpWidget(_eightApp(session, scale: 2));
        await tester.pumpAndSettle();
        final information = find.byKey(
          const ValueKey('buy-automatic-fulfilment-s-tomato'),
        );
        final scroll = find
            .descendant(
              of: find.byKey(const PageStorageKey('buy-product-s-tomato')),
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(information, 250, scrollable: scroll);
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: information,
            matching: find.text('Confirmed at checkout'),
          ),
          findsNWidgets(2),
        );
        for (final value in [
          'Order before 14:30 for packing today',
          'Dispatched after Store packing confirmation',
          'Test local delivery provider serving this Store',
        ]) {
          expect(
            find.descendant(of: information, matching: find.text(value)),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);
        await captureR66Visual(tester, 'organized-provider-long-text');
        facts.closed = true;
        session.refreshProductFacts('s-tomato');
        await tester.pumpAndSettle();
        expect(session.addProduct('s-tomato'), isFalse);
        expect(session.quantityFor('s-tomato'), 0);
        expect(
          find.byKey(const ValueKey('buy-product-primary-s-tomato')),
          findsNothing,
        );
        final store = find.byKey(
          const ValueKey('buy-product-hero-store-s-tomato'),
        );
        await tester.scrollUntilVisible(store, -250, scrollable: scroll);
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: store,
            matching: find.text('Closed · Opens tomorrow at 9 am'),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
    for (final destination in [
      BuyV2Destination.shop,
      BuyV2Destination.wholesale,
    ]) {
      testWidgets('root categories drag select scoped ${destination.name}', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.reset);
        final core = BuySession();
        final session = BuyV2Session(core: core);
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        session.openDestination(destination);
        await tester.pumpWidget(_eightApp(session));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('buy-category-picker')));
        await tester.pumpAndSettle();
        final surface = find.byKey(
          const ValueKey('buy-category-sheet-surface'),
        );
        final initialTop = tester.getRect(surface).top;
        await tester.drag(
          find.byKey(const ValueKey('buy-category-grid')),
          const Offset(0, -440),
        );
        await tester.pumpAndSettle();
        expect(tester.getRect(surface).top, lessThan(initialTop - 100));
        final category = session.categories.firstWhere((c) => c.id != 'all');
        final choice = find.byKey(ValueKey('buy-category-${category.id}'));
        await tester.ensureVisible(choice);
        await tester.pumpAndSettle();
        await captureR66Visual(tester, 'eight-categories-${destination.name}');
        await tester.tap(choice);
        await tester.pumpAndSettle();
        expect(session.selectedCategoryId, category.id);
        expect(session.destination, destination);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }

    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'compact order actions invoice identity and MVP promotions $scale',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(scale == 1 ? 390 : 320, 844);
          tester.view.viewPadding = const FakeViewPadding(bottom: 34);
          addTearDown(tester.view.reset);
          final core = BuySession();
          final session = BuyV2Session(core: core);
          addTearDown(session.dispose);
          addTearDown(core.dispose);
          expect(session.addProduct('s-tomato'), isTrue);
          session.openCart(scope: BuyV2CartScope.shop);
          expect(session.openCheckout(), isTrue);
          expect(session.confirmOrder(), isTrue);
          final order = session.confirmedOrders.single;
          expect(session.openTracking(order.id), isTrue);
          await tester.pumpWidget(_eightApp(session, scale: scale));
          await tester.pumpAndSettle();
          final row = find.byKey(
            ValueKey('buy-tracking-secondary-actions-${order.id}'),
          );
          final scroll = find
              .descendant(
                of: find.byKey(PageStorageKey('buy-tracking-${order.id}')),
                matching: find.byType(Scrollable),
              )
              .first;
          await tester.scrollUntilVisible(row, 200, scrollable: scroll);
          await tester.pumpAndSettle();
          final manage = find.byKey(
            ValueKey('buy-tracking-manage-order-${order.id}'),
          );
          final invoice = find.byKey(
            ValueKey('buy-tracking-invoice-${order.id}'),
          );
          expect(tester.getSize(manage).height, greaterThanOrEqualTo(44));
          expect(tester.getSize(invoice).height, greaterThanOrEqualTo(44));
          if (scale == 1) {
            expect(
              tester.getRect(manage).center.dy,
              closeTo(tester.getRect(invoice).center.dy, 1),
            );
            expect(tester.getSize(row).height, lessThanOrEqualTo(52));
          }
          await captureR66Visual(tester, 'eight-order-actions-$scale');
          await tester.tap(invoice);
          await tester.pumpAndSettle();
          expect(
            find.byKey(ValueKey('buy-invoice-page-${order.id}')),
            findsOneWidget,
          );
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          await tester.ensureVisible(manage);
          await tester.pumpAndSettle();
          await tester.tap(manage);
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('buy-order-resolution-sheet')),
            findsOneWidget,
          );
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          session.openDestination(BuyV2Destination.orders);
          await tester.pumpAndSettle();
          final promotions = find.byKey(
            const ValueKey('buy-orders-promotions'),
          );
          await tester.scrollUntilVisible(
            promotions,
            260,
            scrollable: find
                .descendant(
                  of: find.byKey(const PageStorageKey('buy-orders')),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await tester.pumpAndSettle();
          await tester.drag(promotions, const Offset(-600, 0));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('buy-promotion-orders-medicine')),
            findsNothing,
          );
          expect(find.text('Medicine and wellness'), findsNothing);
          expect(
            find.byKey(const ValueKey('buy-promotion-orders-wholesale')),
            findsOneWidget,
          );
          await captureR66Visual(tester, 'eight-orders-promos-$scale');
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }

    for (final destination in [
      BuyV2Destination.shop,
      BuyV2Destination.wholesale,
      BuyV2Destination.orders,
    ]) {
      testWidgets('fixed Cart and hidden search delivery ${destination.name}', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.reset);
        final core = BuySession();
        final session = BuyV2Session(core: core);
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        expect(session.addProduct('s-tomato'), isTrue);
        session.openCart(scope: BuyV2CartScope.shop);
        expect(session.openCheckout(), isTrue);
        expect(session.confirmOrder(), isTrue);
        expect(session.activeDeliveryOrders, isNotEmpty);
        session.openDestination(destination);
        expect(
          session.addProduct(
            destination == BuyV2Destination.wholesale ? 'w-rice' : 's-tomato',
          ),
          isTrue,
        );
        await tester.pumpWidget(_eightApp(session));
        await tester.pumpAndSettle();
        final cart = find.byKey(const ValueKey('buy-cart-navigation-button'));
        expect(cart.hitTestable(), findsOneWidget);
        final bounds = tester.getRect(cart);
        await tester.drag(cart, const Offset(-140, -150));
        await tester.pumpAndSettle();
        expect(tester.getRect(cart), bounds);
        if (destination != BuyV2Destination.orders) {
          final active = find.byKey(
            const ValueKey('buy-quick-delivery-toggle'),
          );
          expect(active, findsOneWidget);
          await tester.tap(find.byKey(const ValueKey('buy-search-control')));
          await tester.pumpAndSettle();
          expect(active, findsNothing);
          await tester.enterText(
            find.byKey(const ValueKey('buy-search-field')),
            'rice',
          );
          tester.view.viewInsets = const FakeViewPadding(bottom: 290);
          await tester.pumpAndSettle();
          expect(active, findsNothing);
          expect(session.activeDeliveryOrders, isNotEmpty);
          await captureR66Visual(tester, 'eight-search-${destination.name}');
          tester.view.resetViewInsets();
          tester.testTextInput.hide();
          await tester.tap(find.byKey(const ValueKey('buy-search-close')));
          await tester.pumpAndSettle();
          expect(active, findsOneWidget);
          expect(cart.hitTestable(), findsOneWidget);
        }
        await captureR66Visual(tester, 'eight-fixed-cart-${destination.name}');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'location auto locate retry confirmation and stale result $scale',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(scale == 1 ? 390 : 320, 700);
          tester.view.viewPadding = const FakeViewPadding(bottom: 34);
          addTearDown(tester.view.reset);
          final core = BuySession();
          final source = _EightLocationSource()
            ..failure = BuyV2ShoppingAreaFailure.permissionDenied;
          final session = BuyV2Session(core: core, shoppingAreaSource: source);
          addTearDown(session.dispose);
          addTearDown(core.dispose);
          await tester.pumpWidget(_eightApp(session, scale: scale));
          await tester.pumpAndSettle();
          final context = tester.element(find.byType(BuyV2Screen));
          unawaited(showBuyV2CatalogueArea(context, session));
          await tester.pumpAndSettle();
          expect(source.calls, 1);
          expect(find.byType(TextField), findsNothing);
          expect(
            find.byKey(const ValueKey('buy-area-lookup-failure')),
            findsOneWidget,
          );
          await captureR66Visual(tester, 'eight-location-permission-$scale');
          source.failure = null;
          await tester.tap(find.byKey(const ValueKey('buy-area-lookup-retry')));
          await tester.pumpAndSettle();
          final address = session.selectedAddressOrNull;
          expect(source.calls, 2);
          expect(find.text(_EightLocationSource.area.label), findsOneWidget);
          final confirm = find.byKey(
            const ValueKey('buy-current-location-confirm'),
          );
          await tester.ensureVisible(confirm);
          await tester.pumpAndSettle();
          expect(tester.getRect(confirm).bottom, lessThanOrEqualTo(666));
          await captureR66Visual(tester, 'eight-location-confirm-$scale');
          await tester.tap(confirm);
          await tester.pumpAndSettle();
          expect(
            session.shoppingGooglePlaceId,
            _EightLocationSource.area.googlePlaceId,
          );
          expect(session.selectedAddressOrNull, address);
          source.pending = Completer<BuyV2ShoppingArea?>();
          unawaited(showBuyV2CatalogueArea(context, session));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          await tester.tap(find.byTooltip('Close shopping location'));
          await tester.pump();
          source.pending!.complete(_EightLocationSource.area);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
      for (final productId in ['s-tomato', 'w-rice']) {
        testWidgets('organized product information $productId $scale', (
          tester,
        ) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(scale == 1 ? 390 : 320, 844);
          addTearDown(tester.view.reset);
          final core = BuySession();
          final session = BuyV2Session(core: core);
          addTearDown(session.dispose);
          addTearDown(core.dispose);
          session.openDestination(
            productId.startsWith('w-')
                ? BuyV2Destination.wholesale
                : BuyV2Destination.shop,
          );
          session.openProduct(productId);
          await tester.pumpWidget(_eightApp(session, scale: scale));
          await tester.pumpAndSettle();
          final store = find.byKey(
            ValueKey('buy-product-hero-store-$productId'),
          );
          await tester.ensureVisible(store);
          await tester.pumpAndSettle();
          expect(
            find.descendant(of: store, matching: find.text('Open for orders')),
            findsOneWidget,
          );
          expect(find.text('Fulfillment arranged by MoolSocial'), findsNothing);
          final information = find.byKey(
            ValueKey('buy-automatic-fulfilment-$productId'),
          );
          await tester.ensureVisible(information);
          await tester.pumpAndSettle();
          expect(
            find.descendant(
              of: information,
              matching: find.text('Delivery & returns'),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(of: information, matching: find.text('Deliver to')),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: information,
              matching: find.text('Open for orders'),
            ),
            findsNothing,
          );
          expect(tester.takeException(), isNull);
          await captureR66Visual(tester, 'organized-product-$productId-$scale');
          await tester.pumpWidget(const SizedBox.shrink());
        });
      }
      testWidgets('compact Compare unavailable and product Add $scale', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(scale == 1 ? 390 : 320, 844);
        addTearDown(tester.view.reset);
        final core = BuySession();
        final session = _ComparisonUnavailableSession(core: core);
        expect(session.comparisonSource, isNull);
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        session.openProduct('s-tomato');
        await tester.pumpWidget(_eightApp(session, scale: scale));
        await tester.pumpAndSettle();
        final add = find.byKey(const ValueKey('buy-product-primary-s-tomato'));
        await tester.ensureVisible(add);
        await tester.pumpAndSettle();
        expect(tester.getSize(add).width, lessThan(scale == 1 ? 240 : 290));
        if (scale == 1) {
          final price = find.byKey(
            const ValueKey('buy-product-hero-price-s-tomato'),
          );
          expect(
            (tester.getRect(price).center.dy - tester.getRect(add).center.dy)
                .abs(),
            lessThan(35),
          );
        }
        await captureR66Visual(tester, 'eight-product-details-$scale');
        final productList = find
            .descendant(
              of: find.byKey(const PageStorageKey('buy-product-s-tomato')),
              matching: find.byType(Scrollable),
            )
            .first;
        tester.state<ScrollableState>(productList).position.jumpTo(0);
        await tester.pumpAndSettle();
        await captureR66Visual(tester, 'eight-product-$scale');
        final compare = find.byKey(
          const ValueKey('buy-product-action-compare-s-tomato'),
        );
        final scroll = find
            .descendant(
              of: find.byKey(const PageStorageKey('buy-product-s-tomato')),
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(compare, 240, scrollable: scroll);
        await tester.pumpAndSettle();
        await tester.tap(compare);
        await tester.pumpAndSettle();
        final sheet = find.byKey(
          const ValueKey('buy-product-comparison-sheet'),
        );
        expect(sheet, findsOneWidget);
        expect(tester.getSize(sheet).height, lessThan(650));
        await captureR66Visual(tester, 'eight-compare-$scale');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  });

  group('Cursor product controls regressions', () {
    test('review seeds do not imply delivery; new placement does', () {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      expect(session.orders, isNotEmpty);
      expect(session.activeDeliveryOrders, isEmpty);
      expect(session.activeQuickDeliveryOrder, isNull);
      expect(session.activeQuietDeliveryOrder, isNull);
      expect(session.addProduct('s-tomato'), isTrue);
      session.openCart(scope: BuyV2CartScope.shop);
      expect(session.openCheckout(), isTrue);
      expect(session.confirmOrder(), isTrue);
      expect(
        session.activeDeliveryOrders.map((order) => order.id),
        session.confirmedOrders.map((order) => order.id),
      );
    });

    test(
      'cached delivery needs provider confirmation and can be removed',
      () async {
        const order = BuyV2Order(
          id: 'cached-only-order',
          destination: BuyV2Destination.shop,
          title: 'Stored order',
          itemSummary: 'One recorded item',
          total: 100,
          partner: 'Store',
          partnerType: 'Retailer',
          promise: 'Last recorded estimate',
          destinationLabel: 'Home',
          progress: .5,
          status: BuyV2OrderStatus.dispatched,
        );
        final commerce = _ControlsCommerce();
        final core = BuySession();
        final session = BuyV2Session(
          core: core,
          reviewDataEnabled: false,
          commerceAdapter: commerce,
          customerStateStore: _ControlsCustomerStore(
            const BuyV2CustomerStateSnapshot(orders: [order]),
          ),
        );
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        await session.restoreCommerce();
        await session.restoreCustomerState();
        expect(session.orders.map((item) => item.id), contains(order.id));
        expect(session.activeDeliveryOrders, isEmpty);
        commerce.snapshot = const BuyV2CommerceSnapshot(
          state: BuyV2CommerceLoadState.ready,
          orders: [order],
        );
        await session.restoreCommerce();
        expect(session.activeDeliveryOrders.map((item) => item.id), [order.id]);
        commerce.snapshot = const BuyV2CommerceSnapshot(
          state: BuyV2CommerceLoadState.ready,
        );
        await session.restoreCommerce();
        expect(session.activeDeliveryOrders, isEmpty);
      },
    );

    for (final profile in [
      (size: const Size(360, 800), scale: 1.0),
      (size: const Size(320, 568), scale: 2.0),
      (size: const Size(390, 844), scale: 1.4),
      (size: const Size(800, 360), scale: 1.0),
    ]) {
      for (final id in ['w-notebook', 's-tomato']) {
        testWidgets(
          'Cart stays fixed through product scroll $id ${profile.size} ${profile.scale}',
          (tester) async {
            tester.view.physicalSize = profile.size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            final core = BuySession();
            final session = BuyV2Session(core: core);
            addTearDown(session.dispose);
            addTearDown(core.dispose);
            final product = session.product(id);
            session.openDestination(product.destination);
            expect(session.addProduct(id), isTrue);
            session.openProduct(id);
            await tester.pumpWidget(
              MaterialApp(
                theme: MoolTheme.light(),
                builder: (context, child) => r66VisualCaptureRoot(
                  MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(profile.scale),
                      padding: const EdgeInsets.only(top: 24, bottom: 24),
                      viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
                    ),
                    child: child!,
                  ),
                ),
                home: BuyV2Screen(
                  session: session,
                  initialDestination: product.destination,
                  initialView: BuyV2View.product,
                  productId: id,
                ),
              ),
            );
            await tester.pumpAndSettle();
            final cart = find.byKey(
              const ValueKey('buy-cart-navigation-button'),
            );
            final delivery = find.byKey(
              const ValueKey('buy-quick-delivery-toggle'),
            );
            expect(
              delivery,
              findsNothing,
              reason: 'Review seeds are not placed deliveries',
            );
            expect(cart.hitTestable(), findsOneWidget);
            final cartRect = tester.getRect(cart);
            final list = find
                .descendant(
                  of: find.byKey(PageStorageKey('buy-product-$id')),
                  matching: find.byType(Scrollable),
                )
                .first;
            final position = tester.state<ScrollableState>(list).position;
            for (final fraction in [0.5, 1.0, 0.0]) {
              position.jumpTo(position.maxScrollExtent * fraction);
              await tester.pumpAndSettle();
              expect(cart.hitTestable(), findsOneWidget);
              expect(tester.getRect(cart), cartRect);
              expect(
                find.byKey(const ValueKey('buy-compact-cart-indicator')),
                findsOneWidget,
              );
              expect(tester.takeException(), isNull);
            }
            if (product.destination == BuyV2Destination.wholesale) {
              final quantity = find.byKey(ValueKey('buy-product-quantity-$id'));
              await tester.scrollUntilVisible(quantity, 120, scrollable: list);
              await tester.pumpAndSettle();
              expect(quantity.hitTestable(), findsOneWidget);
              expect(tester.getSize(quantity).width, lessThanOrEqualTo(190));
              final plus = find.descendant(
                of: quantity,
                matching: find.byTooltip('Add one'),
              );
              expect(tester.getSize(plus), const Size(44, 44));
              await tester.tap(plus);
              await tester.pumpAndSettle();
              expect(session.quantityFor(id), product.minimumOrder + 1);
              final minus = find.descendant(
                of: quantity,
                matching: find.byTooltip('Remove one'),
              );
              await tester.tap(minus);
              await tester.pumpAndSettle();
              expect(session.quantityFor(id), product.minimumOrder);
              await tester.tap(
                find.byKey(const ValueKey('buy-product-edit-quantity')),
              );
              await tester.pumpAndSettle();
              final input = find.byKey(const ValueKey('buy-quantity-input'));
              await tester.enterText(input, '${product.minimumOrder + 2}');
              await tester.testTextInput.receiveAction(TextInputAction.done);
              await tester.pumpAndSettle();
              expect(session.quantityFor(id), product.minimumOrder + 2);
              expect(cart.hitTestable(), findsOneWidget);
              await captureR66Visual(
                tester,
                'controls-$id-${profile.size.width}-${profile.scale}',
              );
            }
            final retainedQuantity = session.quantityFor(id);
            position.jumpTo(position.maxScrollExtent / 2);
            await tester.pumpAndSettle();
            final retainedOffset = position.pixels;
            await tester.tap(cart);
            await tester.pumpAndSettle();
            expect(session.view, BuyV2View.cart);
            expect(
              session.cartScope,
              product.destination == BuyV2Destination.shop
                  ? BuyV2CartScope.shop
                  : BuyV2CartScope.wholesale,
            );
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            expect(session.selectedProductId, id);
            expect(session.quantityFor(id), retainedQuantity);
            expect(cart.hitTestable(), findsOneWidget);
            expect(tester.getRect(cart), cartRect);
            final restored = tester.state<ScrollableState>(list).position;
            expect(restored.pixels, closeTo(retainedOffset, 1));
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
          },
        );
      }
    }
  });

  testWidgets(
    'collection removes redundant sign-in but retains identity validation and Cart',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final journey = JourneySession(
        store: MemoryJourneyStore(
          snapshot: const JourneySnapshot(
            languageCode: 'en',
            areaMode: 'manual',
            areaLabel: 'Jodhpur',
            setupComplete: true,
          ),
        ),
        otpGateway: ReviewOtpGateway(),
        allowGuestReady: true,
      );
      await journey.start();
      addTearDown(journey.dispose);
      await tester.pumpWidget(
        MoolSocialApp(
          key: UniqueKey(),
          session: journey,
          initialLocation: '/app/buy',
        ),
      );
      await tester.pumpAndSettle();
      final session = tester
          .widget<BuyV2Screen>(find.byType(BuyV2Screen))
          .session;
      expect(session.addProduct('s-tomato'), isTrue);
      session.openCart(scope: BuyV2CartScope.shop);
      expect(session.openCheckout(), isTrue);
      expect(session.chooseCheckoutCollection(true), isTrue);
      await tester.pumpAndSettle();
      final signIn = find.byKey(
        const ValueKey('buy-checkout-collection-sign-in'),
      );
      expect(signIn, findsNothing);
      expect(session.continueCheckoutFromAddress(), isFalse);
      expect(session.view, BuyV2View.checkout);
      expect(session.checkoutScope, BuyV2CartScope.shop);
      expect(session.collectionCheckoutSelected, isTrue);
      expect(session.quantityFor('s-tomato'), 1);
      expect(find.byKey(const Key('screen03-login-v5')), findsNothing);
      expect(journey.isAuthenticated, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  group('explicit frontend eligibility v1', () {
    final now = DateTime.utc(2026, 9, 22, 10);
    final product = BuyV2Catalogue.products.first.copyWith(storeId: 'store-1');
    Map<String, dynamic> payload() => {
      'schemaVersion': 1,
      'productId': product.id,
      'storeId': 'store-1',
      'sourceRevision': 'store-contract-test-v1',
      'customerLocationKey': 'place|1',
      'observedAt': now.subtract(const Duration(minutes: 1)).toIso8601String(),
      'expiresAt': now.add(const Duration(minutes: 5)).toIso8601String(),
      'offerClass': 'retail',
      'channelEnabled': true,
      'storeReady': true,
      'fleetAvailable': true,
      'customerLocationConfirmed': true,
      'options': ['quick', 'scheduled', 'courier'],
      'scheduledSlotId': 'slot-1',
      'scheduledStart': now.add(const Duration(hours: 1)).toIso8601String(),
      'scheduledEnd': now.add(const Duration(hours: 2)).toIso8601String(),
      'reviewFixture': false,
    };
    Set<BuyV2DeliveryOption> resolve(
      Map<String, dynamic> json, {
      String location = 'place|1',
      DateTime? at,
      BuyV2Product? item,
    }) =>
        BuyV2OfferEligibility.fromJson(json)?.availableFor(
          product: item ?? product,
          locationKey: location,
          now: at ?? now,
        ) ??
        {};

    test(
      'multiple options roundtrip with exact identities and explicit slot',
      () {
        final contract = BuyV2OfferEligibility.fromJson(payload())!;
        expect(
          contract.toJson(),
          payload()..['options'] = ['courier', 'quick', 'scheduled'],
        );
        expect(
          resolve(payload()),
          containsAll([
            BuyV2DeliveryOption.quick,
            BuyV2DeliveryOption.scheduled,
            BuyV2DeliveryOption.courier,
          ]),
        );
        expect(
          () => contract.options.add(BuyV2DeliveryOption.freight),
          throwsUnsupportedError,
        );
      },
    );
    for (final field in ['channelEnabled', 'storeReady']) {
      test('$field false denies all channels', () {
        expect(resolve(payload()..[field] = false), isEmpty);
      });
    }
    test(
      'fleet unavailable denies Quick and Scheduled but preserves courier',
      () {
        expect(resolve(payload()..['fleetAvailable'] = false), {
          BuyV2DeliveryOption.courier,
        });
      },
    );
    for (final field in ['scheduledSlotId', 'scheduledStart', 'scheduledEnd']) {
      test('missing $field never turns courier into Scheduled', () {
        expect(
          resolve(payload()..remove(field)),
          isNot(contains(BuyV2DeliveryOption.scheduled)),
        );
      });
    }
    test(
      'unconfirmed location denies Quick and Scheduled independently of fleet',
      () {
        expect(resolve(payload()..['customerLocationConfirmed'] = false), {
          BuyV2DeliveryOption.courier,
        });
      },
    );
    test('expiry boundary and changed location fail closed', () {
      expect(
        resolve(payload(), at: now.add(const Duration(minutes: 5))),
        isEmpty,
      );
      expect(resolve(payload(), location: 'place|2'), isEmpty);
      expect(
        resolve(
          payload()
            ..['observedAt'] = now
                .add(const Duration(seconds: 1))
                .toIso8601String(),
        ),
        isEmpty,
      );
    });
    test('wrong identity and class cannot grant eligibility', () {
      for (final field in ['productId', 'storeId', 'sourceRevision']) {
        expect(resolve(payload()..[field] = ''), isEmpty);
      }
      expect(resolve(payload()..['offerClass'] = 'bulk'), isEmpty);
    });
    test('review responses are excluded by default', () {
      expect(resolve(payload()..['reviewFixture'] = true), isEmpty);
    });
    test('unknown schema and incomplete payloads never get defaults', () {
      for (final field in [
        'schemaVersion',
        'options',
        'offerClass',
        'expiresAt',
        'fleetAvailable',
      ]) {
        expect(
          BuyV2OfferEligibility.fromJson(payload()..remove(field)),
          isNull,
        );
      }
      expect(
        BuyV2OfferEligibility.fromJson(payload()..['options'] = ['teleport']),
        isNull,
      );
      expect(
        BuyV2OfferEligibility.fromJson(payload()..['schemaVersion'] = 2),
        isNull,
      );
    });
    test(
      'MOQ and copy changes do not change grants or offer classification',
      () {
        final changed = product.copyWith(
          minimumOrder: 400,
          deliveryPromise: '20 minutes',
        );
        expect(changed.offerClass, BuyV2OfferClass.retail);
        expect(resolve(payload(), item: changed), resolve(payload()));
        final wholesale = product.copyWith(
          offerClass: BuyV2OfferClass.wholesale,
          minimumOrder: 100,
        );
        final bulk = product.copyWith(
          offerClass: BuyV2OfferClass.bulk,
          minimumOrder: 1,
        );
        expect(wholesale.offerClass, BuyV2OfferClass.wholesale);
        expect(bulk.offerClass, BuyV2OfferClass.bulk);
        expect(
          buyV2CatalogueFulfilmentModeFor(
            product.copyWith(
              deliveryPromise: '20 minutes',
              reviewDeliveryOptions: {},
            ),
          ),
          isNot(BuyV2FulfilmentMode.quickLocal),
        );
      },
    );
    test('pagination identity changes within the same region', () {
      BuyV2CatalogueQuery query(String location) => BuyV2CatalogueQuery(
        destination: BuyV2Destination.shop,
        regionId: 'jodhpur',
        customerLocationKey: location,
      );
      expect(query('place|1'), isNot(query('place|2')));
    });
    test('production missing eligibility keeps Cart unchanged', () async {
      final core = BuySession();
      final source = BuyV2DevelopmentCatalogueSource(
        destination: BuyV2Destination.shop,
      );
      final session = BuyV2Session(
        core: core,
        reviewDataEnabled: false,
        cataloguePageSource: source,
        initialCatalogueRegionId: 'jodhpur',
      );
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      final id = source.productIdAt(0, 0);
      expect(await session.openLinkedProduct(id), isTrue);
      expect(session.deliveryOptionsFor(session.product(id)), isEmpty);
      expect(session.addProduct(id), isFalse);
      expect(session.cartLines, isEmpty);
    });
  });

  test(
    'eligibility expiry and location changes invalidate Saved, Add and checkout without losing Cart',
    () async {
      var clock = DateTime.utc(2026, 9, 22, 10);
      final core = BuySession();
      final facts = _EligibilityFacts();
      final source = BuyV2DevelopmentCatalogueSource(
        destination: BuyV2Destination.shop,
      );
      final session = BuyV2Session(
        core: core,
        cataloguePageSource: source,
        productFactsAdapter: facts,
        catalogueNow: () => clock,
        initialCatalogueRegionId: 'jodhpur',
      );
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      final id = source.productIdAt(0, 0);
      expect(await session.openLinkedProduct(id), isTrue);
      final product = session.product(id);
      facts.eligibility = BuyV2OfferEligibility(
        productId: id,
        storeId: product.storeId!,
        sourceRevision: 'test-v1',
        customerLocationKey: session.eligibilityLocationKey,
        observedAt: clock,
        expiresAt: clock.add(const Duration(minutes: 5)),
        offerClass: product.offerClass!,
        channelEnabled: true,
        storeReady: true,
        fleetAvailable: true,
        customerLocationConfirmed: true,
        options: {BuyV2DeliveryOption.quick, BuyV2DeliveryOption.scheduled},
        scheduledSlotId: 'test-slot',
        scheduledStart: clock.add(const Duration(hours: 1)),
        scheduledEnd: clock.add(const Duration(hours: 2)),
        reviewFixture: true,
      );
      session.refreshProductFacts(id);
      session.toggleSaved(id);
      expect(session.visibleSavedProducts.map((p) => p.id), contains(id));
      session.chooseShopSaleType(BuyV2ShopSaleType.courier);
      expect(session.visibleSavedProducts.map((p) => p.id), contains(id));
      expect(session.addProduct(id), isTrue);
      session.openCart(scope: BuyV2CartScope.shop);
      expect(session.openCheckout(), isTrue);
      final quantity = session.quantityFor(id);
      facts.invalid = true;
      expect(session.refreshProductFacts(id), isFalse);
      expect(session.deliveryOptionsFor(product), isEmpty);
      expect(session.addProduct(id), isFalse);
      expect(session.quantityFor(id), quantity);
      facts.invalid = false;
      expect(session.refreshProductFacts(id), isTrue);
      expect(
        session.deliveryOptionsFor(product),
        contains(BuyV2DeliveryOption.quick),
      );
      clock = clock.add(const Duration(minutes: 5));
      expect(
        session.visibleSavedProducts.map((p) => p.id),
        isNot(contains(id)),
      );
      expect(session.addProduct(id), isFalse);
      expect(session.continueCheckoutFromAddress(), isFalse);
      expect(session.confirmOrder(), isFalse);
      expect(session.quantityFor(id), quantity);
      clock = clock.subtract(const Duration(minutes: 5));
      final query = session.catalogueQuery();
      session.chooseCatalogueArea(null, BuyV2CatalogueAreaScope.allAreas);
      expect(session.catalogueQuery(), isNot(query));
      expect(session.deliveryOptionsFor(product), isEmpty);
      expect(session.addProduct(id), isFalse);
      expect(session.quantityFor(id), quantity);
    },
  );

  test(
    'active estimate normalizes delivered suffix without changing deadline',
    () {
      expect(
        buyV2DeliveryPromiseSummary(
          promise: 'Delivery today by 8:00 pm',
          promisedByLabel: 'Delivered in 30 min',
        ),
        'Delivery today by 8:00 pm · Delivery in 30 min',
      );
    },
  );
  test('group names require one exact Store identity', () {
    final product = BuyV2Catalogue.products.first.copyWith(
      storeId: 'buy-catalogue-dev-v1-shop-store-000001',
    );
    final group = BuyV2FulfilmentGroup(
      groupKey: 'test',
      destination: BuyV2Destination.shop,
      partner: 'Mool Market 000001',
      partnerType: 'Retailer',
      promise: '',
      lines: [BuyV2CartLine(product: product, quantity: 1)],
    );
    expect(group.customerPartner, 'Mool Market 1');
    expect(
      buyV2CustomerStoreName('Store 000001', product.storeId),
      'Store 000001',
    );
    expect(
      buyV2CustomerStoreName('Mool Market 000001', 'real-store'),
      'Mool Market 000001',
    );
  });

  test('historical line prices never replace current Reorder prices', () {
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    final current = session.product('s-tomato');
    final old = current.copyWith(price: 1);
    final order = BuyV2Order(
      id: 'historical-price-check',
      destination: current.destination,
      title: 'Previous purchase',
      itemSummary: '2 items',
      total: 2,
      partner: current.seller,
      partnerType: current.sellerType,
      promise: 'Delivered',
      destinationLabel: 'Home',
      progress: 1,
      status: BuyV2OrderStatus.delivered,
      productIds: [current.id],
      lines: [BuyV2CartLine(product: old, quantity: 2)],
    );
    expect(session.productsForOrder(order).single.price, current.price);
    expect(session.reorder(order), isTrue);
    expect(session.cartLines.single.product.price, current.price);
    expect(order.lines.single.total, 2);
  });

  test(
    'Store search uses displayed name and recommendations keep exact seller',
    () async {
      final core = BuySession();
      final source = BuyV2DevelopmentCatalogueSource(
        destination: BuyV2Destination.shop,
      );
      final session = BuyV2Session(
        core: core,
        cataloguePageSource: source,
        initialCatalogueRegionId: 'jodhpur',
      );
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      final page = await source.loadStores(
        session.catalogueQuery(search: 'Mool Market 1'),
        pageSize: 40,
      );
      expect(
        page.items.map((store) => store.id),
        contains(source.storeIdAt(0)),
      );
      final first = source.productIdAt(0, 0);
      final second = source.productIdAt(0, 1);
      final outside = source.productIdAt(10, 1);
      for (final id in [first, second, outside]) {
        expect(await session.openLinkedProduct(id), isTrue);
      }
      final products = session.productContinuationsFor(session.product(first));
      expect(products.map((item) => item.id), contains(second));
      expect(
        products.every((item) => item.storeId == source.storeIdAt(0)),
        isTrue,
      );
      session.toggleSaved(first);
      expect(session.notice, '${session.product(first).customerTitle} saved.');
      final media = BuyV2ProductPackshot.resolveMedia(session.product(first));
      final templateMedia = BuyV2ProductPackshot.resolveMedia(
        session.product('s-tomato'),
      );
      expect(media?.assetPath, templateMedia?.assetPath);
      expect(media?.cell, templateMedia?.cell);
    },
  );

  testWidgets(
    'publisher selection restores honestly and All clears MoolSocial',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      tester.view.viewPadding = const FakeViewPadding(bottom: 48);
      addTearDown(tester.view.reset);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      session.featuredOffersMoolSocial = true;
      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          builder: (context, child) => r66VisualCaptureRoot(child!),
          home: Scaffold(
            body: BuyV2OffersView(
              session: session,
              source: const BuyV2CataloguePublishedOffersSource(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No matching offers'), findsOneWidget);
      expect(find.byType(BuyV2ProductCard), findsNothing);
      await tester.tap(find.byKey(const ValueKey('buy-offers-filter')));
      await tester.pumpAndSettle();
      final mool = find.byKey(const ValueKey('buy-offer-filter-moolSocial'));
      expect(mool.hitTestable(), findsOneWidget);
      expect(tester.getRect(mool).bottom, lessThanOrEqualTo(752));
      await captureR66Visual(tester, 'post-redmi-publisher-inset');
      await tester.tap(find.byKey(const ValueKey('buy-offer-filter-all')));
      await tester.pumpAndSettle();
      expect(session.featuredOffersMoolSocial, isFalse);
      expect(find.byType(BuyV2ProductCard), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'Saved retains query and excludes products outside Wholesale sale type',
    () {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      session.destination = BuyV2Destination.wholesale;
      final product = session.product('w-tomato');
      session.toggleSaved(product.id);
      session.updateQuery('tomato');
      session.showSavedProducts(true);
      expect(session.query, 'tomato');
      expect(
        session.visibleSavedProducts.map((item) => item.id),
        contains(product.id),
      );
      session.chooseWholesaleSaleType(BuyV2WholesaleSaleType.bulk);
      expect(
        session.visibleSavedProducts.map((item) => item.id),
        isNot(contains(product.id)),
      );
      session.showSavedProducts(false);
      expect(session.query, 'tomato');
    },
  );

  test(
    'Orders recommendation Back copy names the actual return destination',
    () {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      session.openOrders();
      session.openProduct('s-tomato');
      expect(session.productReturnLabel, 'Orders');
      session.closeProduct();
      expect(session.destination, BuyV2Destination.orders);
    },
  );

  test('customer copy preserves genuine product numbers', () {
    final product = BuyV2Catalogue.products.first;
    expect(product.customerTitle, product.title);
    expect(product.customerSeller('Store 007'), 'Store 007');
  });

  testWidgets(
    'ordered quantity and amount are visible from the recorded lines',
    (tester) async {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      session.addProduct('s-tomato');
      session.addProduct('s-tomato');
      session.openCart(scope: BuyV2CartScope.shop);
      expect(session.openCheckout(), isTrue);
      expect(session.confirmOrder(), isTrue);
      final order = session.confirmedOrders.single;
      expect(order.lines.single.quantity, 2);
      session.openOrderItems(order.id);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BuyV2OrderItemsView(session: session)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('2 × 500 g'), findsOneWidget);
      expect(find.textContaining('₹74'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
