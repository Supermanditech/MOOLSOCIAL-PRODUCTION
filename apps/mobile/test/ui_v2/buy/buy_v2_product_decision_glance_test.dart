import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_views.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'R66 003 tomato summary owns one price and purchase actions at $scale',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 844);
        tester.view.viewPadding = const FakeViewPadding(bottom: 32);
        addTearDown(tester.view.reset);
        final core = BuySession();
        final session = BuyV2Session(core: core);
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        final product = BuyV2Catalogue.products.firstWhere(
          (item) =>
              item.destination == BuyV2Destination.shop &&
              item.title == 'Fresh tomatoes',
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: MoolTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                disableAnimations: true,
              ),
              child: RepaintBoundary(
                key: const ValueKey('r66-product-detail-capture'),
                child: child!,
              ),
            ),
            home: BuyV2Screen(
              session: session,
              initialView: BuyV2View.product,
              productId: product.id,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final hero = find.byKey(
          ValueKey('buy-product-purchase-hero-${product.id}'),
        );
        final primary = find.byKey(
          ValueKey('buy-product-primary-${product.id}'),
        );
        final store = find.byKey(
          ValueKey('buy-shop-seller-action-${product.id}'),
        );
        expect(
          find.text(buyV2Money(session.productFactsFor(product).price)),
          findsOneWidget,
        );
        expect(find.descendant(of: hero, matching: primary), findsOneWidget);
        expect(find.descendant(of: hero, matching: store), findsOneWidget);
        _expectParagraphsFit(hero);
        if (scale == 1) {
          expect(tester.getRect(primary).bottom, lessThanOrEqualTo(752));
          expect(primary.hitTestable(), findsOneWidget);
          expect(store.hitTestable(), findsOneWidget);
          await _captureR66Product(tester, '$scale-summary');
        }
        await Scrollable.ensureVisible(tester.element(primary), alignment: .3);
        await tester.pumpAndSettle();
        expect(tester.getSize(primary).height, greaterThanOrEqualTo(44));
        if (scale == 2) {
          _expectParagraphsFit(
            find.byKey(ValueKey('buy-automatic-fulfilment-${product.id}')),
            checkWords: true,
          );
          await _captureR66Product(tester, '$scale-actions');
        }
        await tester.tap(primary);
        await tester.pumpAndSettle();
        expect(session.quantityFor(product.id), 1);
        final plus = find.descendant(
          of: hero,
          matching: find.byTooltip('Add one'),
        );
        expect(plus.hitTestable(), findsOneWidget);
        await tester.tap(plus);
        await tester.pumpAndSettle();
        expect(session.quantityFor(product.id), 2);
        await Scrollable.ensureVisible(tester.element(store), alignment: .3);
        await tester.pumpAndSettle();
        await tester.tap(store);
        await tester.pumpAndSettle();
        expect(
          find.byKey(ValueKey('buy-shop-seller-sheet-${product.id}')),
          findsOneWidget,
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(session.selectedProductId, product.id);
        expect(session.quantityFor(product.id), 2);
        expect(session.view, BuyV2View.product);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  Widget app(BuyV2Session session, {required Size size, double textScale = 1}) {
    return MaterialApp(
      theme: MoolTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          body: AnimatedBuilder(
            animation: session,
            builder: (context, _) => BuyV2ProductView(session: session),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'R66 003 retains distinct content delivery compliance and protection facts',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 844);
      addTearDown(tester.view.reset);
      final core = BuySession();
      final facts = _ProductDetailFacts();
      final product = BuyV2Catalogue.products
          .firstWhere((item) => item.destination == BuyV2Destination.shop)
          .copyWith(
            purchaseProtection: const BuyV2PurchaseProtection(
              summary: 'Supplier reviews eligible requests',
              remedies: ['Replacement', 'Repair'],
              windowLabel: 'Request within two days of delivery',
              conditionsLabel: 'Keep the original packaging',
              verificationLabel: 'Photos are reviewed',
              initiationLabel: 'Open this order for support',
              approvalLabel: 'Supplier approval required',
              pickupLabel: 'Pickup follows approval',
              refundMethodLabel: 'Original payment method',
              refundTimelineLabel: 'Timeline follows approval',
              warrantyLabel: 'Manufacturer warranty applies',
              nonReturnableReason: 'No change-of-mind returns',
              policyVersion: 'R66-TEST-POLICY',
              effectiveFromLabel: '1 September 2026',
            ),
            compliance: const BuyV2ProductCompliance(
              genericName: 'Test packaged product',
              netQuantity: '1 test pack',
              manufacturerName: 'Test manufacturer',
              packerName: 'Test packer',
              importerName: 'Test importer',
              countryOfOrigin: 'India',
              manufacturedOrPackedOnLabel: 'Packed September 2026',
              bestBeforeOrUseByLabel: 'Use within the labelled period',
              fssaiLicenseNumber: '10000000000000',
              consumerCare: 'Test consumer support',
            ),
          );
      final session = BuyV2Session(
        core: core,
        productFactsAdapter: facts,
        productContentAdapter: _ProductDetailContent(),
        reviewDataEnabled: false,
        commerceAdapter: _ProductDetailCommerce(product),
      );
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      await session.restoreCommerce();
      expect(session.openProduct(product.id), isTrue);
      await tester.pumpWidget(
        app(session, size: const Size(320, 844), textScale: 2),
      );
      await tester.pumpAndSettle();
      final scroll = find
          .descendant(
            of: find.byKey(PageStorageKey('buy-product-${product.id}')),
            matching: find.byType(Scrollable),
          )
          .first;
      Future<void> read(String value) async {
        final target = find.text(value);
        await tester.scrollUntilVisible(
          target.first,
          350,
          scrollable: scroll,
          maxScrolls: 70,
        );
        await tester.pumpAndSettle();
        expect(target, findsWidgets);
      }

      for (final value in [
        'Fulfilment arranged by MoolSocial',
        'Order by 14:30',
        'Delivery fee ₹19',
        'Dispatched after packing',
        'Test delivery provider',
        'Tracked delivery service',
      ]) {
        await read(value);
      }
      final protection = product.purchaseProtection!;
      for (final value in [
        if (protection.remedies.isNotEmpty) protection.remedies.join(' · '),
        protection.windowLabel,
        protection.conditionsLabel,
        protection.verificationLabel,
        protection.initiationLabel,
        protection.approvalLabel,
        protection.pickupLabel,
        protection.refundMethodLabel,
        protection.refundTimelineLabel,
        protection.warrantyLabel,
        protection.nonReturnableReason,
        protection.policyVersion,
        protection.effectiveFromLabel,
      ].whereType<String>().where((value) => value.trim().isNotEmpty)) {
        await read(value);
      }
      final compliance = product.compliance;
      if (compliance != null) {
        for (final value in [
          compliance.genericName,
          compliance.netQuantity,
          compliance.manufacturerName,
          compliance.packerName,
          compliance.importerName,
          compliance.countryOfOrigin,
          compliance.manufacturedOrPackedOnLabel,
          compliance.bestBeforeOrUseByLabel,
          compliance.fssaiLicenseNumber,
          compliance.consumerCare,
        ].whereType<String>().where((value) => value.trim().isNotEmpty)) {
          await read(value);
        }
      }
      for (final value in [
        'Keep away from direct sunlight',
        'Store in a cool place',
        '${product.brand} special edition',
        'A distinct supplier description.',
      ]) {
        await read(value);
      }
      final content = find.byKey(
        ValueKey('buy-product-content-ready-${product.id}'),
      );
      for (final value in [
        product.brand,
        product.pack,
        product.variant,
        product.unitPrice,
      ]) {
        expect(
          find.descendant(of: content, matching: find.text(value)),
          findsNothing,
        );
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('R66 003 unavailable product retains retry and blocks Add', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 844);
    addTearDown(tester.view.reset);
    final core = BuySession();
    final facts = _ProductDetailFacts()..available = false;
    final session = BuyV2Session(core: core, productFactsAdapter: facts);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    session.openProduct(product.id);
    await tester.pumpWidget(app(session, size: const Size(320, 844)));
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey('buy-product-primary-${product.id}')),
      findsNothing,
    );
    final retry = find.byKey(ValueKey('buy-offer-retry-${product.id}'));
    await tester.scrollUntilVisible(
      retry,
      350,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 30,
    );
    await Scrollable.ensureVisible(tester.element(retry), alignment: .3);
    await tester.pumpAndSettle();
    expect(retry.hitTestable(), findsOneWidget);
    facts.available = true;
    await tester.tap(retry);
    await tester.pumpAndSettle();
    final primary = find.byKey(ValueKey('buy-product-primary-${product.id}'));
    await tester.scrollUntilVisible(
      primary,
      -350,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 30,
    );
    await Scrollable.ensureVisible(tester.element(primary), alignment: .3);
    await tester.pumpAndSettle();
    await tester.tap(primary);
    await tester.pumpAndSettle();
    expect(session.quantityFor(product.id), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Shop summary owns decision-critical facts without a duplicate glance',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.reset);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      final product = BuyV2Catalogue.products.firstWhere(
        (candidate) => candidate.destination == BuyV2Destination.shop,
      );
      session.openProduct(product.id);

      await tester.pumpWidget(app(session, size: const Size(360, 800)));
      await tester.pumpAndSettle();

      final summary = find.byKey(
        ValueKey('buy-product-purchase-hero-${product.id}'),
      );
      final buyerPromise = buyV2BuyerDeliveryPromise(
        session.productFactsFor(product),
      );
      expect(summary, findsOneWidget);
      expect(
        find.byKey(ValueKey('buy-product-decision-glance-${product.id}')),
        findsNothing,
      );
      expect(find.text(buyV2Money(product.price)), findsOneWidget);
      expect(
        find.text(session.productFactsFor(product).orderabilityLabel),
        findsOneWidget,
      );
      expect(
        find.text('${product.pack} · ${product.unitPrice}'),
        findsOneWidget,
      );
      expect(
        find.descendant(of: summary, matching: find.text(buyerPromise)),
        findsOneWidget,
      );
      expect(find.text('Automatic Mool Partner assignment'), findsNothing);
      expect(tester.getRect(summary).bottom, lessThan(800));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('compact large text keeps the purchase summary whole', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.reset);
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    final product = BuyV2Catalogue.products.firstWhere(
      (candidate) => candidate.destination == BuyV2Destination.shop,
    );
    session.openProduct(product.id);

    await tester.pumpWidget(
      app(session, size: const Size(320, 568), textScale: 1.4),
    );
    await tester.pumpAndSettle();

    final summary = find.byKey(
      ValueKey('buy-product-purchase-hero-${product.id}'),
    );
    expect(summary, findsOneWidget);
    expect(tester.getSize(summary).width, greaterThanOrEqualTo(300));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Wholesale retains its dedicated trade decision owner', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    final product = BuyV2Catalogue.products.firstWhere(
      (candidate) => candidate.destination == BuyV2Destination.wholesale,
    );
    session.openProduct(product.id);

    await tester.pumpWidget(app(session, size: const Size(360, 800)));
    await tester.pumpAndSettle();

    expect(
      find.byKey(ValueKey('buy-product-decision-glance-${product.id}')),
      findsNothing,
    );
    expect(
      find.byKey(ValueKey('buy-wholesale-trade-decision-${product.id}')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

void _expectParagraphsFit(Finder owner, {bool checkWords = false}) {
  for (final element
      in find
          .descendant(of: owner, matching: find.byType(RichText))
          .evaluate()) {
    final paragraph = element.renderObject! as RenderParagraph;
    expect(
      paragraph.didExceedMaxLines,
      isFalse,
      reason: paragraph.text.toPlainText(),
    );
    final natural = TextPainter(
      text: paragraph.text,
      textDirection: paragraph.textDirection,
      textScaler: paragraph.textScaler,
    )..layout(maxWidth: paragraph.size.width);
    expect(
      paragraph.size.height + .1,
      greaterThanOrEqualTo(natural.height),
      reason: paragraph.text.toPlainText(),
    );
    natural.dispose();
    if (checkWords) {
      for (final word in paragraph.text.toPlainText().split(RegExp(r'\s+'))) {
        final measured = TextPainter(
          text: TextSpan(text: word, style: paragraph.text.style),
          textDirection: paragraph.textDirection,
          textScaler: paragraph.textScaler,
        )..layout();
        expect(
          paragraph.size.width + .1,
          greaterThanOrEqualTo(measured.width),
          reason: word,
        );
        measured.dispose();
      }
    }
  }
}

Future<void> _captureR66Product(WidgetTester tester, String label) async {
  if (!const bool.fromEnvironment('BUY_R66_PRODUCT_DETAIL_CAPTURE')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('r66-product-detail-capture')),
  );
  await tester.runAsync(() async {
    final directory = Directory('build/r66-product-detail-v2-20260906');
    await directory.create(recursive: true);
    final output = File('${directory.path}/$label.png');
    if (await output.exists()) {
      throw StateError('Product detail capture already exists');
    }
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final data = await image.toByteData(format: ImageByteFormat.png);
      if (data == null) {
        throw StateError('Product detail capture encoding failed');
      }
      await output.writeAsBytes(data.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

final class _ProductDetailFacts implements BuyV2ProductFactsAdapter {
  bool available = true;
  @override
  BuyV2ProductFactsSnapshot snapshotFor(BuyV2Product product) =>
      const BuyV2CatalogueProductFactsAdapter()
          .snapshotFor(product)
          .copyWith(
            orderabilityLabel: available
                ? 'Available now'
                : 'Currently unavailable',
            sourceId: 'r66-product-detail-test',
            orderCutoffLabel: 'Order by 14:30',
            deliveryFeeLabel: 'Delivery fee ₹19',
            dispatchPromise: 'Dispatched after packing',
            deliveryProviderName: 'Test delivery provider',
            deliveryServiceLevel: 'Tracked delivery service',
          );
}

final class _ProductDetailContent implements BuyV2ProductContentAdapter {
  @override
  BuyV2ProductContentSnapshot snapshotFor(BuyV2Product product) =>
      BuyV2ProductContentSnapshot(
        productId: product.id,
        state: BuyV2ProductContentState.ready,
        sourceId: 'r66-product-detail-content-test',
        highlights: [
          product.variant,
          product.unitPrice,
          'Keep away from direct sunlight',
        ],
        specifications: [
          BuyV2ProductSpecification(label: 'Brand', value: product.brand),
          BuyV2ProductSpecification(label: 'Pack', value: product.pack),
          BuyV2ProductSpecification(label: 'Variant', value: product.variant),
          BuyV2ProductSpecification(
            label: 'Storage',
            value: 'Store in a cool place',
          ),
          BuyV2ProductSpecification(
            label: 'Brand',
            value: '${product.brand} special edition',
          ),
        ],
        description: 'A distinct supplier description.',
      );
}

final class _ProductDetailCommerce implements BuyV2CommerceAdapter {
  _ProductDetailCommerce(this.product);
  final BuyV2Product product;
  @override
  Future<BuyV2CommerceSnapshot> refresh() async => BuyV2CommerceSnapshot(
    state: BuyV2CommerceLoadState.ready,
    products: [product],
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError(
    'Unexpected commerce mutation in product detail test',
  );
}
