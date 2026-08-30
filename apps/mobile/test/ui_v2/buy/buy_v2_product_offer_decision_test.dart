import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(
    BuyV2Session session, {
    Size size = const Size(390, 844),
    double textScale = 1,
  }) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: MoolTheme.light(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        size: size,
        textScaler: TextScaler.linear(textScale),
        disableAnimations: true,
      ),
      child: child!,
    ),
    home: BuyV2Screen(session: session),
  );

  BuyV2ProductFactsSnapshot factsFor(
    BuyV2Product product, {
    int? price,
    String? deliveryPromise,
    String? partner,
    String orderabilityLabel = 'Available to add',
    BuyV2FulfilmentMode? fulfilmentMode,
    BuyV2StoreOperatingState storeOperatingState =
        BuyV2StoreOperatingState.unknown,
    String? nextOpeningLabel,
    String? orderCutoffLabel,
    String? deliveryFeeLabel,
    bool stale = false,
  }) => BuyV2ProductFactsSnapshot(
    productId: product.id,
    price: price ?? product.price,
    deliveryPromise: deliveryPromise ?? product.deliveryPromise,
    partner: partner ?? product.seller,
    orderabilityLabel: orderabilityLabel,
    sourceId: 'product-offer-decision-test',
    fulfilmentMode: fulfilmentMode,
    storeOperatingState: storeOperatingState,
    nextOpeningLabel: nextOpeningLabel,
    orderCutoffLabel: orderCutoffLabel,
    deliveryFeeLabel: deliveryFeeLabel,
    stale: stale,
  );

  Future<void> openProductDecision(
    WidgetTester tester,
    BuyV2Session session,
    String productId,
  ) async {
    session.openDestination(BuyV2Destination.shop);
    expect(session.openProduct(productId), isTrue);
    await tester.pumpAndSettle();
    final panel = find.byKey(ValueKey('buy-product-offer-decision-$productId'));
    await tester.scrollUntilVisible(
      panel,
      180,
      scrollable: find
          .descendant(
            of: find.byKey(PageStorageKey('buy-product-$productId')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(panel, findsOneWidget);
  }

  testWidgets('ready Shop offer shows the complete decision before Add', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final core = BuySession();
    final adapter = _SequencedFactsAdapter((product, _) => factsFor(product));
    final session = BuyV2Session(core: core, productFactsAdapter: adapter);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    final product = session.product('s-tomato');

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    await openProductDecision(tester, session, product.id);

    expect(
      buyV2ProductOfferDecisionContractVersion,
      'buy-product-offer-decision-v1',
    );
    expect(find.text('Price, pack and delivery'), findsOneWidget);
    expect(find.text('Available now'), findsOneWidget);
    expect(find.text('${product.pack} · ${product.variant}'), findsOneWidget);
    expect(find.textContaining(buyV2Money(product.price)), findsWidgets);
    expect(find.text('Available to add'), findsOneWidget);
    expect(
      find.text(buyV2BuyerDeliveryPromise(factsFor(product))),
      findsWidgets,
    );
    expect(find.text('Automatically assigned Mool Partner'), findsOneWidget);
    expect(find.text('Quick local delivery'), findsOneWidget);
    if (product.mrp case final mrp?) {
      expect(
        find.textContaining('List price ${buyV2Money(mrp)}'),
        findsOneWidget,
      );
    }
    final add = find.byKey(ValueKey('buy-product-primary-${product.id}'));
    await tester.ensureVisible(add);
    expect(add, findsOneWidget);
    expect(tester.getSize(add).height, greaterThanOrEqualTo(44));
    expect(
      find.byKey(ValueKey('buy-shop-seller-action-${product.id}')),
      findsNothing,
    );

    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(session.quantityFor(product.id), product.minimumOrder);
    expect(tester.takeException(), isNull);
  });

  testWidgets('blocked Shop offer states never expose Add or mutate Cart', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    final cases =
        <
          ({
            String label,
            BuyV2ProductFactsSnapshot Function(BuyV2Product) facts,
          })
        >[
          (
            label: 'Check current availability',
            facts: (product) => factsFor(product, stale: true),
          ),
          (
            label: 'Currently unavailable',
            facts: (product) =>
                factsFor(product, orderabilityLabel: 'Currently unavailable'),
          ),
          (
            label: 'Checking availability',
            facts: (product) =>
                factsFor(product, orderabilityLabel: 'Checking serviceability'),
          ),
          (
            label: 'Price changed',
            facts: (product) => factsFor(product, price: product.price + 5),
          ),
          (
            label: 'Delivery unavailable',
            facts: (product) =>
                factsFor(product, partner: 'Assignment pending'),
          ),
          (
            label: 'Store closed',
            facts: (product) => factsFor(
              product,
              fulfilmentMode: BuyV2FulfilmentMode.quickLocal,
              storeOperatingState: BuyV2StoreOperatingState.closed,
              nextOpeningLabel: 'Reopens at 6:00 am',
            ),
          ),
        ];

    for (final testCase in cases) {
      final core = BuySession();
      final adapter = _SequencedFactsAdapter(
        (product, _) => testCase.facts(product),
      );
      final session = BuyV2Session(core: core, productFactsAdapter: adapter);
      final product = session.product('s-tomato');

      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();
      await openProductDecision(tester, session, product.id);

      expect(find.text(testCase.label), findsWidgets, reason: testCase.label);
      expect(
        find.byKey(ValueKey('buy-product-primary-${product.id}')),
        findsNothing,
        reason: testCase.label,
      );
      expect(
        find.byKey(ValueKey('buy-offer-retry-${product.id}')),
        findsOneWidget,
        reason: testCase.label,
      );
      expect(
        find.byKey(ValueKey('buy-offer-change-product-${product.id}')),
        findsOneWidget,
        reason: testCase.label,
      );
      expect(
        tester
            .getSize(find.byKey(ValueKey('buy-offer-retry-${product.id}')))
            .height,
        greaterThanOrEqualTo(44),
        reason: '${testCase.label} retry height',
      );
      expect(
        tester
            .getSize(
              find.byKey(ValueKey('buy-offer-change-product-${product.id}')),
            )
            .height,
        greaterThanOrEqualTo(44),
        reason: '${testCase.label} recovery height',
      );
      expect(session.cartLines, isEmpty, reason: testCase.label);

      await tester.tap(
        find.byKey(ValueKey('buy-offer-change-product-${product.id}')),
      );
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.catalogue, reason: testCase.label);
      expect(session.cartLines, isEmpty, reason: testCase.label);
      expect(tester.takeException(), isNull, reason: testCase.label);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      session.dispose();
      core.dispose();
    }
  });

  testWidgets('Retry refreshes a stale offer before Cart becomes available', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final core = BuySession();
    final adapter = _SequencedFactsAdapter(
      (product, request) =>
          request == 1 ? factsFor(product, stale: true) : factsFor(product),
    );
    final session = BuyV2Session(core: core, productFactsAdapter: adapter);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    final product = session.product('s-tomato');

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    await openProductDecision(tester, session, product.id);
    expect(find.text('Check current availability'), findsWidgets);

    await tester.tap(find.byKey(ValueKey('buy-offer-retry-${product.id}')));
    await tester.pumpAndSettle();
    expect(adapter.requestsFor(product.id), 2);
    expect(find.text('Available now'), findsOneWidget);
    final add = find.byKey(ValueKey('buy-product-primary-${product.id}'));
    await tester.ensureVisible(add);
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(session.quantityFor(product.id), product.minimumOrder);
    expect(tester.takeException(), isNull);
  });

  testWidgets('catalogue recovery cannot bypass a stale offer decision', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final core = BuySession();
    final adapter = _SequencedFactsAdapter(
      (product, _) => factsFor(product, stale: true),
    );
    final session = BuyV2Session(core: core, productFactsAdapter: adapter);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    final product = session.visibleProducts.first;

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    final review = find.byKey(ValueKey('buy-review-offer-${product.id}'));
    expect(review, findsOneWidget);
    expect(find.byKey(ValueKey('buy-add-${product.id}')), findsNothing);
    await tester.tap(review);
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.product);
    expect(session.cartLines, isEmpty);
    expect(find.text('Check current availability'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('product offer decision stays usable at 320 and 140 percent', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.reset);
    final core = BuySession();
    final adapter = _SequencedFactsAdapter((product, _) => factsFor(product));
    final session = BuyV2Session(core: core, productFactsAdapter: adapter);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    final product = session.product('s-tomato');

    await tester.pumpWidget(
      app(session, size: const Size(320, 568), textScale: 1.4),
    );
    await tester.pumpAndSettle();
    await openProductDecision(tester, session, product.id);
    final add = find.byKey(ValueKey('buy-product-primary-${product.id}'));
    await tester.ensureVisible(add);
    expect(add, findsOneWidget);
    expect(tester.getSize(add).height, greaterThanOrEqualTo(44));
    expect(find.text('Price, pack and delivery'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

final class _SequencedFactsAdapter implements BuyV2ProductFactsAdapter {
  _SequencedFactsAdapter(this._builder);

  final BuyV2ProductFactsSnapshot Function(BuyV2Product product, int request)
  _builder;
  final Map<String, int> _requestsByProduct = {};

  int requestsFor(String productId) => _requestsByProduct[productId] ?? 0;

  @override
  BuyV2ProductFactsSnapshot snapshotFor(BuyV2Product product) {
    final request = requestsFor(product.id) + 1;
    _requestsByProduct[product.id] = request;
    return _builder(product, request);
  }
}
