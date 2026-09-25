import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_customer_copy.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_catalogue.dart'
    show showBuyV2ShoppingHelp;
import 'package:moolsocial/ui_v2/buy/buy_v2_views.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart'
    show buyV2BuyerDeliveryPromise;
import 'buy_v2_screen_test.dart' show captureR66Visual, r66VisualCaptureRoot;

void main() {
  testWidgets('PDP03-A01 shared help matches Store display names and search', (
    tester,
  ) async {
    final core = BuySession();
    final session = _HelpStoreLabelSession(core: core);
    addTearDown(core.dispose);
    addTearDown(session.dispose);
    final product = session
        .product('s-milk')
        .copyWith(
          storeId: 'buy-catalogue-dev-v1-shop-store-000001',
          seller: 'Mool Market 000001',
        );
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () =>
                  showBuyV2ShoppingHelp(context, session, product: product),
              child: const Text('Open help'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open help'));
    await tester.pumpAndSettle();
    expect(find.text('Mool Market 1'), findsOneWidget);
    expect(find.textContaining('Mool Market 000001'), findsNothing);
    expect(find.textContaining('Mool Market 1\n'), findsOneWidget);
    expect(product.seller, 'Mool Market 000001');
    expect(session.orders.single.partner, 'Mool Market 000001');
    await tester.enterText(find.byType(TextField), 'Mool Market 1');
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-shopping-help-order-HELP-LABEL')),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), 'Mool Market 000001');
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-shopping-help-order-HELP-LABEL')),
      findsOneWidget,
    );
    expect(
      product.copyWith(storeId: 'real-store').customerSeller(product.seller),
      'Mool Market 000001',
    );
    expect(tester.takeException(), isNull);
  });

  test(
    'catalogue fallback does not invent a repetitive product description',
    () {
      final product = BuyV2Catalogue.products.first;
      final content = const BuyV2CatalogueProductContentAdapter().snapshotFor(
        product,
      );
      expect(content.description, isNull);
      expect(
        content.specifications.any(
          (field) =>
              field.attributeId == 'variant' && field.value == product.variant,
        ),
        isTrue,
      );
      expect(
        content.specifications.any(
          (field) => field.attributeId == 'pack' && field.value == product.pack,
        ),
        isTrue,
      );
    },
  );
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> mountReferenceGallery(
    WidgetTester tester,
    BuyV2Session session,
    String id,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MoolTheme.light(),
        builder: (context, child) => r66VisualCaptureRoot(child!),
        home: BuyV2Screen(
          session: session,
          initialDestination: session.destination,
          productId: id,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> revealProductControl(
    WidgetTester tester,
    BuyV2Session session,
    Finder target,
  ) async {
    if (target.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        target,
        140,
        scrollable: find
            .descendant(
              of: find
                  .byKey(
                    PageStorageKey('buy-product-${session.selectedProductId}'),
                  )
                  .last,
              matching: find.byType(Scrollable),
            )
            .first,
      );
    } else {
      await tester.ensureVisible(target);
    }
    await tester.pumpAndSettle();
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('store details copy preserves full text and retries $scale', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      const name = 'Sardarpura Family Grocery and Household Supplies';
      const address =
          'Shop 12, First Floor, Main Market Road, Sardarpura, '
          'Jodhpur, Rajasthan 342003';
      final core = BuySession();
      final session = BuyV2Session(
        core: core,
        productFactsAdapter: _PricingFactsAdapter()..partner = name,
        marketplaceTrustAdapter: const _PricingTrustAdapter(
          partnerName: name,
          partnerLocation: address,
        ),
      );
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      var failCopy = true;
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            if (failCopy) {
              throw PlatformException(code: 'clipboard-unavailable');
            }
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await mountReferenceGallery(tester, session, 's-milk');
      final copy = find.byKey(const ValueKey('buy-product-copy-store-s-milk'));
      await revealProductControl(tester, session, copy);
      for (final (key, text) in [
        ('buy-product-store-full-name-s-milk', name),
        ('buy-product-store-full-address-s-milk', address),
      ]) {
        final field = find.byKey(ValueKey(key));
        expect(tester.widget<Text>(field).data, text);
        final paragraph = tester.renderObject<RenderParagraph>(
          find.descendant(of: field, matching: find.byType(RichText)),
        );
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(
          tester.getRect(field).right,
          lessThanOrEqualTo(tester.getRect(copy).left),
        );
      }
      expect(tester.getSize(copy).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(copy).height, greaterThanOrEqualTo(48));
      await tester.tap(copy);
      await tester.pumpAndSettle();
      expect(
        find.text('Could not copy store details. Try again.'),
        findsOneWidget,
      );
      expect(copied, isNull);
      failCopy = false;
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.tap(copy);
      await tester.pumpAndSettle();
      expect(copied, '$name\n$address');
      expect(find.text('Store details copied'), findsOneWidget);
      expect(session.selectedProductId, 's-milk');
      expect(session.cartLines, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('refined product toolbar keeps actions outside photos $scale', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final id in ['s-milk', 'w-atta']) {
        final core = BuySession();
        final session = BuyV2Session(core: core);
        await mountReferenceGallery(tester, session, id);
        final save = find.byKey(ValueKey('buy-product-action-save-$id'));
        final share = find.byKey(ValueKey('buy-product-action-share-$id'));
        final photo = find.byKey(ValueKey('buy-product-gallery-$id'));
        final saveBounds = tester.getRect(save);
        final shareBounds = tester.getRect(share);
        final photoBounds = tester.getRect(photo);
        expect(saveBounds.bottom, lessThanOrEqualTo(photoBounds.top));
        expect(shareBounds.bottom, lessThanOrEqualTo(photoBounds.top));
        expect(shareBounds.left, greaterThanOrEqualTo(saveBounds.right));
        for (final bounds in [saveBounds, shareBounds]) {
          expect(bounds.width, greaterThanOrEqualTo(48));
          expect(bounds.height, greaterThanOrEqualTo(48));
          expect(bounds.left, greaterThanOrEqualTo(0));
          expect(
            bounds.right,
            lessThanOrEqualTo(tester.view.physicalSize.width),
          );
        }
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(session.isSaved(id), isTrue);
        expect(session.selectedProductId, id);
        expect(session.cartLines, isEmpty);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        session.dispose();
        core.dispose();
      }
    });

    testWidgets('public polish assurance layout preserves action rows $scale', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await mountReferenceGallery(tester, session, 's-milk');
      final strip = find.byKey(const ValueKey('buy-product-assurance-s-milk'));
      await revealProductControl(tester, session, strip);
      final controls = [
        for (final id in ['returns', 'payment', 'support'])
          find.byKey(ValueKey('buy-product-assurance-$id-s-milk')),
      ];
      final rects = controls.map(tester.getRect).toList();
      final bounds = tester.getRect(strip);
      for (final rect in rects) {
        expect(rect.width, greaterThanOrEqualTo(48));
        expect(rect.height, greaterThanOrEqualTo(48));
        expect(rect.left, greaterThanOrEqualTo(bounds.left));
        expect(rect.right, lessThanOrEqualTo(bounds.right + .1));
      }
      if (scale == 1) {
        expect(rects[1].top, closeTo(rects[0].top, .1));
        expect(rects[2].top, closeTo(rects[0].top, .1));
      } else {
        expect(rects[1].top, greaterThanOrEqualTo(rects[0].bottom));
        expect(rects[2].top, greaterThanOrEqualTo(rects[1].bottom));
      }
      await tester.ensureVisible(controls[1]);
      await tester.pumpAndSettle();
      await tester.tap(controls[1]);
      await tester.pumpAndSettle();
      expect(
        find.text('Cash on Delivery availability is not confirmed.'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Close').last);
      await tester.pumpAndSettle();
      expect(session.selectedProductId, 's-milk');
      expect(session.cartLines, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'reference assurance returns preserve supplied policy and remedies',
    (tester) async {
      final core = BuySession();
      final session = BuyV2Session(
        core: core,
        marketplaceTrustAdapter: const _PricingTrustAdapter(
          returnSummary: 'Older conflicting return summary',
        ),
      );

      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await mountReferenceGallery(tester, session, 's-milk');
      final product = session.selectedProduct!;
      final returns = find.byKey(
        const ValueKey('buy-product-assurance-returns-s-milk'),
      );
      await revealProductControl(tester, session, returns);
      expect(find.text('Purchase protection'), findsNothing);
      expect(find.text('Return or replacement'), findsNothing);
      await tester.tap(returns.hitTestable());
      await tester.pumpAndSettle();
      final sheet = find.byType(BottomSheet);
      final protection = product.purchaseProtection;
      expect(find.text('Older conflicting return summary'), findsNothing);
      if (protection != null) {
        expect(
          find.descendant(of: sheet, matching: find.text(protection.summary)),
          findsOneWidget,
        );
        for (final remedy in protection.remedies) {
          expect(
            find.descendant(of: sheet, matching: find.textContaining(remedy)),
            findsWidgets,
          );
        }
      } else if (product.returnPolicy != null) {
        expect(
          find.descendant(
            of: sheet,
            matching: find.text(product.returnPolicy!),
          ),
          findsOneWidget,
        );
      }
      await tester.tap(find.byTooltip('Close').last);
      await tester.pumpAndSettle();
      expect(session.selectedProductId, product.id);
      expect(session.cartLines, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('reference assurance return process uses existing order help', (
    tester,
  ) async {
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(core.dispose);
    addTearDown(session.dispose);
    await mountReferenceGallery(tester, session, 's-milk');
    final returns = find.byKey(
      const ValueKey('buy-product-assurance-returns-s-milk'),
    );
    await revealProductControl(tester, session, returns);
    await tester.tap(returns.hitTestable());
    await tester.pumpAndSettle();
    final help = find.byKey(const ValueKey('buy-product-how-to-return'));
    await tester.ensureVisible(help);
    await tester.pumpAndSettle();
    await tester.tap(help.hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('Shopping help'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('buy-shopping-help-product')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('buy-shopping-help-close')));
    await tester.pumpAndSettle();
    expect(session.selectedProductId, 's-milk');
    expect(session.cartLines, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'reference assurance payment information does not infer COD authorization',
    (tester) async {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await mountReferenceGallery(tester, session, 's-milk');
      final payment = find.byKey(
        const ValueKey('buy-product-assurance-payment-s-milk'),
      );
      await revealProductControl(tester, session, payment);
      await tester.tap(payment.hitTestable());
      await tester.pumpAndSettle();
      expect(
        find.text('Cash on Delivery availability is not confirmed.'),
        findsOneWidget,
      );
      expect(find.text('Paid in full'), findsNothing);
      expect(session.cartLines, isEmpty);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(session.selectedProductId, 's-milk');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reference assurance support retains exact product and seller context',
    (tester) async {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await mountReferenceGallery(tester, session, 's-milk');
      final product = session.selectedProduct!;
      final support = find.byKey(
        const ValueKey('buy-product-assurance-support-s-milk'),
      );
      await revealProductControl(tester, session, support);
      await tester.tap(support.hitTestable());
      await tester.pumpAndSettle();
      final sheet = find.byType(BottomSheet);
      for (final text in [product.title, product.pack, product.seller]) {
        expect(
          find.descendant(of: sheet, matching: find.text(text)),
          findsOneWidget,
        );
      }
      expect(
        find.byKey(const ValueKey('buy-shopping-help-ask')),
        findsOneWidget,
      );
      expect(find.textContaining(RegExp(r'24\s*[/x\u00d7]\s*7')), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(session.selectedProductId, product.id);
      expect(session.cartLines, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reference assurance controls preserve both product shell returns',
    (tester) async {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await mountReferenceGallery(tester, session, 's-milk');
      for (final nested in [false, true]) {
        if (nested) {
          final visit = find.byKey(
            const ValueKey('buy-shop-seller-action-s-milk'),
          );
          await revealProductControl(tester, session, visit);
          await tester.tap(visit.hitTestable());
          await tester.pumpAndSettle();
          final tile = find
              .byKey(const ValueKey('buy-grid-packshot-s-milk'))
              .last;
          await tester.ensureVisible(tile);
          await tester.pumpAndSettle();
          await tester.tapAt(
            const Alignment(-.5, .55).withinRect(tester.getRect(tile)),
          );
          await tester.pumpAndSettle();
        }
        for (final action in ['returns', 'payment', 'support']) {
          final control = find.byKey(
            ValueKey('buy-product-assurance-$action-s-milk'),
          );
          await revealProductControl(tester, session, control);
          await tester.tap(control.hitTestable().last);
          await tester.pumpAndSettle();
          expect(find.byType(BottomSheet), findsOneWidget);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(session.selectedProductId, 's-milk');
          expect(session.cartLines, isEmpty);
          expect(tester.takeException(), isNull);
        }
      }
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-grid-packshot-s-milk')),
        findsWidgets,
      );
    },
  );

  testWidgets(
    'reference assurance missing and changed policy never invents eligibility',
    (tester) async {
      final core = BuySession();
      final product = _pricedProduct(null);
      final adapter = _SingleProductCommerceAdapter(product);
      final session = BuyV2Session(
        core: core,
        commerceAdapter: adapter,
        reviewDataEnabled: false,
      );
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await session.restoreCommerce();
      await mountReferenceGallery(tester, session, product.id);
      final returns = find.byKey(
        ValueKey('buy-product-assurance-returns-${product.id}'),
      );
      await revealProductControl(tester, session, returns);
      await tester.tap(returns.hitTestable());
      await tester.pumpAndSettle();
      expect(find.text('Return policy unavailable'), findsOneWidget);
      adapter.product = product.copyWith(
        purchaseProtection: const BuyV2PurchaseProtection(
          summary: 'Replacement only for damaged packs',
          remedies: ['Replacement'],
          policyVersion: 'POLICY-NEW',
          nonReturnableReason: 'No change-of-mind returns',
        ),
      );
      await session.restoreCommerce();
      await tester.pumpAndSettle();
      expect(find.text('Return policy unavailable'), findsNothing);
      expect(find.text('Replacement only for damaged packs'), findsOneWidget);
      expect(find.text('Available options: Replacement'), findsOneWidget);
      expect(find.text('Policy reference: POLICY-NEW'), findsOneWidget);
      adapter.product = product;
      await session.restoreCommerce();
      await tester.pumpAndSettle();
      expect(find.text('Return policy unavailable'), findsOneWidget);
      expect(find.text('Available options: Replacement'), findsNothing);
      expect(session.cartLines, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  for (final mode in ['shop', 'wholesale']) {
    testWidgets(
      'reference assurance order help preserves product and nonempty cart $mode',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(360, 800);
        addTearDown(tester.view.reset);
        final core = BuySession();
        final session = BuyV2Session(core: core);
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        final destination = mode == 'shop'
            ? BuyV2Destination.shop
            : BuyV2Destination.wholesale;
        final productId = mode == 'shop' ? 's-milk' : 'w-notebook';
        final router = GoRouter(
          initialLocation: '/product',
          routes: [
            GoRoute(
              path: '/product',
              builder: (context, state) => BuyV2Screen(
                session: session,
                initialDestination: destination,
                productId: productId,
              ),
            ),
            GoRoute(
              path: '/app/buy',
              builder: (context, state) => BuyV2Screen(
                session: session,
                initialDestination: BuyV2Destination.orders,
                initialView: BuyV2View.tracking,
                orderId: state.uri.queryParameters['order'],
                onExit: () => context.pop(),
              ),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          MaterialApp.router(
            theme: MoolTheme.light(),
            routerConfig: router,
            builder: (context, child) => r66VisualCaptureRoot(child!),
          ),
        );
        await tester.pumpAndSettle();
        expect(session.addProduct('s-tomato'), isTrue);
        expect(session.addProduct('w-notebook'), isTrue);
        session.updateQuery('retained support source');
        final cart = session.cartLines
            .map((l) => (l.product.id, l.quantity))
            .toList();
        final support = find.byKey(
          ValueKey('buy-product-assurance-support-$productId'),
        );
        await revealProductControl(tester, session, support);
        final position = Scrollable.of(tester.element(support)).position;
        final offset = position.pixels;
        await captureR66Visual(tester, 'pdp03-$mode-assurance');
        await tester.tap(support.hitTestable());
        await tester.pumpAndSettle();
        await captureR66Visual(tester, 'pdp03-$mode-support');
        final helpList = find
            .descendant(
              of: find.byKey(const ValueKey('buy-shopping-help-list')),
              matching: find.byType(Scrollable),
            )
            .first;
        for (final orderId in ['MS-240782', 'PO-240728']) {
          final order = find.byKey(
            ValueKey('buy-shopping-help-order-$orderId'),
          );
          await tester.scrollUntilVisible(order, 120, scrollable: helpList);
          await tester.pumpAndSettle();
          await tester.tap(order.hitTestable());
          await tester.pumpAndSettle();
          expect(session.selectedOrderOrNull?.id, orderId);
          expect(session.view, BuyV2View.tracking);
          expect(session.canReturnToShoppingHelp, isTrue);
          if (orderId.startsWith('MS')) {
            expect(session.openOrderItems(orderId), isTrue);
            await tester.pumpAndSettle();
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            expect(session.view, BuyV2View.tracking);
            await tester.binding.handlePopRoute();
          } else {
            final back = find.byKey(
              const ValueKey('buy-tracking-return-orders'),
            );
            await tester.ensureVisible(back);
            await tester.pumpAndSettle();
            await tester.tap(back.hitTestable());
          }
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('buy-shopping-help')),
            findsOneWidget,
          );
          expect(session.hasShoppingHelpReturnOrigin, isFalse);
          expect(session.selectedProductId, productId);
          expect(session.destination, destination);
          expect(session.query, 'retained support source');
          expect(
            session.cartLines.map((l) => (l.product.id, l.quantity)).toList(),
            cart,
          );
        }
        await tester.tap(find.byKey(const ValueKey('buy-shopping-help-close')));
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.product);
        expect(session.selectedProductId, productId);
        expect(position.pixels, offset);
        expect(support.hitTestable(), findsOneWidget);
        expect(
          session.cartLines.map((l) => (l.product.id, l.quantity)).toList(),
          cart,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'reference similar rail follows assurance and shows source facts',
    (tester) async {
      final core = BuySession();
      final product = _pricedProduct(null);
      final alternative = _pricedProduct(100).copyWith(
        id: 'similar-a',
        canonicalId: 'other-product',
        storeId: 'other-store',
        title: 'Alternative milk',
      );
      final adapter = _SingleProductCommerceAdapter(product)
        ..extraProducts = [alternative];
      final facts = _PricingFactsAdapter();
      final session = BuyV2Session(
        core: core,
        commerceAdapter: adapter,
        marketplaceTrustAdapter: const _PricingTrustAdapter(),
        productFactsAdapter: facts,
        reviewDataEnabled: false,
      );
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      final now = DateTime.now();
      facts.eligibility = BuyV2OfferEligibility(
        productId: alternative.id,
        storeId: alternative.storeId!,
        sourceRevision: 'similar-source-facts-1',
        customerLocationKey: session.eligibilityLocationKey,
        observedAt: now.subtract(const Duration(minutes: 1)),
        expiresAt: now.add(const Duration(hours: 1)),
        offerClass: alternative.offerClass!,
        channelEnabled: true,
        storeReady: true,
        fleetAvailable: true,
        customerLocationConfirmed: true,
        options: {BuyV2DeliveryOption.courier},
      );
      await session.restoreCommerce();
      await mountReferenceGallery(tester, session, product.id);
      final rail = find.byKey(
        ValueKey('buy-product-continuations-${product.id}'),
      );
      await revealProductControl(tester, session, rail);
      final assurance = find.byKey(
        ValueKey('buy-product-assurance-${product.id}'),
      );
      expect(
        tester.getTopLeft(rail).dy,
        greaterThan(tester.getTopLeft(assurance).dy),
      );
      expect(find.text('Similar products'), findsOneWidget);
      expect(find.text('You may also like'), findsNothing);
      final card = find.byKey(
        const ValueKey('buy-product-continuation-similar-a'),
      );
      expect(tester.getSize(card).width, 148);
      expect(
        find.descendant(of: card, matching: find.textContaining('4.2 stars')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.textContaining('MRP')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: card,
          matching: find.text(
            buyV2BuyerDeliveryPromise(session.productFactsFor(alternative)),
          ),
        ),
        findsOneWidget,
      );
      expect(session.deliveryOptionsFor(alternative), isNotEmpty);
      await captureR66Visual(tester, 'pdp04-similar-source-facts');
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'reference similar alternatives preserve exact Store SKU and pack identity',
    () async {
      final core = BuySession();
      final product = _pricedProduct(null);
      final otherStore = product.copyWith(
        id: 'other-store-sku',
        canonicalId: 'alternative',
        storeId: 'store-b',
      );
      final otherPack = product.copyWith(
        id: 'other-pack',
        pack: '500 ml',
        variant: 'Small',
      );
      final identicalPack = product.copyWith(
        id: 'same-product-other-store',
        storeId: 'store-c',
      );
      final adapter = _SingleProductCommerceAdapter(product)
        ..extraProducts = [otherStore, otherPack, identicalPack];
      final session = BuyV2Session(
        core: core,
        commerceAdapter: adapter,
        reviewDataEnabled: false,
      );
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await session.restoreCommerce();
      final alternatives = session.productContinuationsFor(product);
      expect(
        alternatives.map((p) => p.id),
        unorderedEquals(['other-store-sku']),
      );
      expect(
        alternatives.firstWhere((p) => p.id == otherStore.id).storeId,
        'store-b',
      );
      expect(
        session
            .productVariantsFor(product)
            .firstWhere((p) => p.id == otherPack.id)
            .pack,
        '500 ml',
      );
      expect(session.cartLines, isEmpty);
    },
  );

  testWidgets(
    'reference similar rail collapses empty and retries unavailable source',
    (tester) async {
      final core = BuySession();
      final product = _pricedProduct(null);
      final adapter = _SingleProductCommerceAdapter(product);
      final session = BuyV2Session(
        core: core,
        commerceAdapter: adapter,
        reviewDataEnabled: false,
      );
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await session.restoreCommerce();
      await mountReferenceGallery(tester, session, product.id);
      expect(session.productContinuationsFor(product), isEmpty);
      expect(find.text('Similar products'), findsNothing);
      adapter.state = BuyV2CommerceLoadState.offline;
      await session.restoreCommerce();
      await tester.pumpAndSettle();
      final retry = find.byTooltip('Retry similar products');
      await revealProductControl(tester, session, retry);
      adapter.state = BuyV2CommerceLoadState.ready;
      adapter.extraProducts = [
        product.copyWith(id: 'retry-alternative', canonicalId: 'retry-product'),
      ];
      await tester.tap(retry.hitTestable());
      await tester.pumpAndSettle();
      expect(find.text('Similar products unavailable'), findsNothing);
      expect(
        session.productContinuationsFor(product).single.id,
        'retry-alternative',
      );
      expect(session.selectedProductId, product.id);
      expect(session.cartLines, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'similar rail shows distinct families after unavailable filtering',
    (tester) async {
      final core = BuySession();
      final current = _pricedProduct(null);
      final available = current.copyWith(
        id: 'available-alternative',
        canonicalId: 'alternative-family',
        price: 55,
      );
      final unavailable = available.copyWith(
        id: 'unavailable-alternative',
        price: 0,
      );
      final duplicate = available.copyWith(
        id: 'duplicate-alternative',
        storeId: 'other-store',
        price: 65,
      );
      final sameTitle = available.copyWith(
        id: 'distinct-family',
        canonicalId: 'different-family',
        price: 70,
      );
      final sameFamily = current.copyWith(
        id: 'current-family-pack',
        pack: 'Different pack',
        variant: 'Different option',
      );
      final adapter = _SingleProductCommerceAdapter(current)
        ..extraProducts = [
          unavailable,
          available,
          duplicate,
          sameTitle,
          sameFamily,
        ];
      final facts = _PricingFactsAdapter();
      final session = BuyV2Session(
        core: core,
        commerceAdapter: adapter,
        productFactsAdapter: facts,
        reviewDataEnabled: false,
      );
      final now = DateTime.now();
      for (final item in [current, ...adapter.extraProducts]) {
        facts.eligibilityByProduct[item.id] = BuyV2OfferEligibility(
          productId: item.id,
          storeId: item.storeId!,
          sourceRevision: 'similar-dedup-1',
          customerLocationKey: session.eligibilityLocationKey,
          observedAt: now.subtract(const Duration(minutes: 1)),
          expiresAt: now.add(const Duration(hours: 1)),
          offerClass: item.offerClass!,
          channelEnabled: true,
          storeReady: true,
          fleetAvailable: true,
          customerLocationConfirmed: true,
          options: {BuyV2DeliveryOption.courier},
        );
      }
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await session.restoreCommerce();
      await mountReferenceGallery(tester, session, current.id);
      final rail = find.byKey(
        ValueKey('buy-product-continuations-${current.id}'),
      );
      await revealProductControl(tester, session, rail);
      Finder card(String id) => find.descendant(
        of: rail,
        matching: find.byKey(ValueKey('buy-product-continuation-$id')),
      );
      expect(card(available.id), findsOneWidget);
      expect(card(sameTitle.id), findsOneWidget);
      expect(card(unavailable.id), findsNothing);
      expect(card(duplicate.id), findsNothing);
      expect(card(sameFamily.id), findsNothing);
      expect(session.cartLines, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reference similar navigation preserves both product shell origins and cart',
    (tester) async {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await mountReferenceGallery(tester, session, 's-milk');
      expect(session.addProduct('s-tomato'), isTrue);
      final cart = session.cartLines
          .map((l) => (l.product.id, l.quantity))
          .toList();
      for (final nested in [false, true]) {
        if (nested) {
          final visit = find.byKey(
            const ValueKey('buy-shop-seller-action-s-milk'),
          );
          await revealProductControl(tester, session, visit);
          await tester.tap(visit.hitTestable());
          await tester.pumpAndSettle();
          final tile = find
              .byKey(const ValueKey('buy-grid-packshot-s-milk'))
              .last;
          await tester.ensureVisible(tile);
          await tester.pumpAndSettle();
          await tester.tapAt(
            const Alignment(-.5, .55).withinRect(tester.getRect(tile)),
          );
          await tester.pumpAndSettle();
        }
        final origin = session.selectedProduct!;
        final alternative = session.productContinuationsFor(origin).first;
        final card = find.byKey(
          ValueKey('buy-product-continuation-${alternative.id}'),
        );
        await revealProductControl(tester, session, card);
        await tester.tap(card.hitTestable().last);
        await tester.pumpAndSettle();
        expect(session.selectedProductId, alternative.id);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(session.selectedProductId, origin.id);
        expect(
          session.cartLines.map((l) => (l.product.id, l.quantity)).toList(),
          cart,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

  test(
    'reference similar catalogue excludes unpublished and duplicate identities',
    () async {
      final core = BuySession();
      final product = _pricedProduct(null);
      final shown = product.copyWith(
        id: 'public-alternative',
        canonicalId: 'alternative',
      );
      final hidden = product.copyWith(
        id: 'unpublished',
        canonicalId: 'unpublished-product',
        catalogueListing: false,
      );
      final adapter = _SingleProductCommerceAdapter(product)
        ..extraProducts = [
          shown,
          shown,
          hidden,
          BuyV2Catalogue.products.firstWhere((p) => p.id == 's-tomato'),
        ];
      final session = BuyV2Session(
        core: core,
        commerceAdapter: adapter,
        reviewDataEnabled: false,
      );
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await session.restoreCommerce();
      expect(session.productContinuationsFor(product).map((p) => p.id), [
        'public-alternative',
      ]);
      expect(session.productContinuationsFor(product, limit: 0), isEmpty);
      expect(
        session.productContinuationsFor(product, limit: 1).single.id,
        shown.id,
      );
    },
  );

  testWidgets(
    'reference similar large text and delivery expiry remain truthful',
    (tester) async {
      final core = BuySession();
      final product = _pricedProduct(null);
      final alternative = _pricedProduct(100).copyWith(
        id: 'expiry-alternative',
        canonicalId: 'expiry-product',
        title: 'A long alternative product title for readable cards',
      );
      final adapter = _SingleProductCommerceAdapter(product)
        ..extraProducts = [alternative];
      final facts = _PricingFactsAdapter();
      var now = DateTime.utc(2026, 9, 24, 12);
      final session = BuyV2Session(
        core: core,
        commerceAdapter: adapter,
        productFactsAdapter: facts,
        reviewDataEnabled: false,
        catalogueNow: () => now,
      );
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await session.restoreCommerce();
      facts.eligibility = BuyV2OfferEligibility(
        productId: alternative.id,
        storeId: alternative.storeId!,
        sourceRevision: 'similar-delivery-1',
        customerLocationKey: session.eligibilityLocationKey,
        observedAt: now.subtract(const Duration(minutes: 1)),
        expiresAt: now.add(const Duration(minutes: 1)),
        offerClass: alternative.offerClass!,
        channelEnabled: true,
        storeReady: true,
        fleetAvailable: true,
        customerLocationConfirmed: true,
        options: {BuyV2DeliveryOption.courier},
      );
      await mountReferenceGallery(tester, session, product.id);
      tester.view.physicalSize = const Size(320, 800);
      await tester.pumpAndSettle();
      final card = find.byKey(
        ValueKey('buy-product-continuation-${alternative.id}'),
      );
      await revealProductControl(tester, session, card);
      final promise = buyV2BuyerDeliveryPromise(
        session.productFactsFor(alternative),
      );
      expect(
        find.descendant(of: card, matching: find.text(promise)),
        findsOneWidget,
      );
      expect(tester.getSize(card).width, 288);
      final title = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: card,
          matching: find.text(alternative.customerTitle),
        ),
      );
      final wordStart = alternative.customerTitle.indexOf('alternative');
      expect(wordStart, greaterThanOrEqualTo(0));
      expect(
        title.getBoxesForSelection(
          TextSelection(
            baseOffset: wordStart,
            extentOffset: wordStart + 'alternative'.length,
          ),
        ),
        hasLength(1),
        reason: 'The full word must fit on one line at enlarged text.',
      );
      expect(tester.takeException(), isNull);
      await captureR66Visual(tester, 'pdp04-similar-320-text200');
      now = now.add(const Duration(minutes: 2));
      await tester.pump(const Duration(minutes: 2));
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: card, matching: find.text(promise)),
        findsNothing,
      );
      expect(session.deliveryOptionsFor(alternative), isEmpty);
      expect(session.cartLines, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reference recent products reuse exact history and exclude earlier rails',
    (tester) async {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      final current = session.product('s-milk');
      final similar = session.productContinuationsFor(current);
      final history = BuyV2Catalogue.products
          .where(
            (p) =>
                p.destination == current.destination &&
                p.categoryId != current.categoryId &&
                p.catalogueListing,
          )
          .take(3)
          .toList();
      expect(history, hasLength(3));
      for (final item in [similar.first, ...history, history.last]) {
        expect(session.openProduct(item.id), isTrue);
      }
      await mountReferenceGallery(tester, session, current.id);
      final recent = find.byKey(ValueKey('buy-product-recents-${current.id}'));
      await revealProductControl(tester, session, recent);
      for (final item in history) {
        expect(
          find.descendant(
            of: recent,
            matching: find.byKey(
              ValueKey('buy-product-continuation-${item.id}'),
            ),
          ),
          findsOneWidget,
        );
      }
      expect(
        find.descendant(
          of: recent,
          matching: find.byKey(
            ValueKey('buy-product-continuation-${similar.first.id}'),
          ),
        ),
        findsNothing,
      );
      final cards = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith(
              'buy-product-continuation-',
            ),
      );
      final keys = tester
          .widgetList<Semantics>(cards)
          .map((w) => w.key)
          .toList();
      expect(keys.toSet(), hasLength(keys.length));
      expect(
        session
            .recentlyViewedProductsFor(current.destination)
            .map((p) => p.id)
            .where((id) => id == history.last.id),
        hasLength(1),
      );
      await captureR66Visual(tester, 'pdp06-recent-history');
      expect(session.cartLines, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reference more products use current catalogue with adaptive pagination',
    (tester) async {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await mountReferenceGallery(tester, session, 's-milk');
      final grid = find.byKey(const ValueKey('buy-product-more-grid-s-milk'));
      await revealProductControl(tester, session, grid);
      var cards = tester.widget<Wrap>(grid).children;
      expect(cards, hasLength(8));
      final first = tester.getRect(find.byWidget(cards[0]));
      final second = tester.getRect(find.byWidget(cards[1]));
      expect(first.top, closeTo(second.top, .1));
      expect(second.left - first.right, closeTo(8, .1));
      expect(first.width, closeTo(second.width, .1));
      await captureR66Visual(tester, 'pdp06-more-grid');
      final load = find.byKey(const ValueKey('buy-product-more-load-s-milk'));
      await revealProductControl(tester, session, load);
      await tester.tap(load.hitTestable());
      await tester.pumpAndSettle();
      expect(tester.widget<Wrap>(grid).children, hasLength(16));
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      tester.view.physicalSize = const Size(320, 800);
      await tester.pumpAndSettle();
      await revealProductControl(tester, session, grid);
      cards = tester.widget<Wrap>(grid).children;
      final largeFirst = tester.getRect(find.byWidget(cards[0]));
      final largeSecond = tester.getRect(find.byWidget(cards[1]));
      expect(largeFirst.width, closeTo(288, .1));
      expect(largeSecond.top, greaterThanOrEqualTo(largeFirst.bottom + 7.9));
      await captureR66Visual(tester, 'pdp06-more-grid-320-text200');
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'reference discovery rejects unpublished and unavailable source records',
    () async {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      final current = session.product('s-milk');
      final other = session.product('s-tomato');
      final hidden = other.copyWith(
        id: 'unpublished-product',
        catalogueListing: false,
      );
      final medicine = BuyV2Catalogue.products.firstWhere(
        (p) => p.destination == BuyV2Destination.medicine,
      );
      expect(
        session
            .productDiscoveryFor(
              current,
              source: [current, other, other, hidden, medicine],
            )
            .map((p) => p.id),
        [other.id],
      );
      expect(
        session.productDiscoveryFor(
          current,
          source: [other],
          excludedProductIds: {other.id},
        ),
        isEmpty,
      );
      session.commerceLoadState = BuyV2CommerceLoadState.offline;
      expect(session.productDiscoveryFor(current, source: [other]), isEmpty);
      final externalCore = BuySession();
      final externalAdapter = _SingleProductCommerceAdapter(other);
      final external = BuyV2Session(
        core: externalCore,
        commerceAdapter: externalAdapter,
        reviewDataEnabled: false,
      );
      addTearDown(external.dispose);
      addTearDown(externalCore.dispose);
      await external.restoreCommerce();
      expect(external.openProduct(other.id), isTrue);
      expect(
        external.recentlyViewedProductsFor(other.destination),
        hasLength(1),
      );
      externalAdapter.product = current;
      await external.restoreCommerce();
      expect(external.recentlyViewedProductsFor(other.destination), isEmpty);
    },
  );

  testWidgets(
    'reference recent view all preserves product history and Cart returns',
    (tester) async {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      session.openProduct('s-tomato');
      expect(session.addProduct('s-milk'), isTrue);
      final quantity = session.quantityFor('s-milk');
      await mountReferenceGallery(tester, session, 's-milk');
      final viewAll = find.byKey(
        const ValueKey('buy-product-recent-view-all-s-milk'),
      );
      await revealProductControl(tester, session, viewAll);
      await tester.tap(viewAll.hitTestable());
      await tester.pumpAndSettle();
      final sheet = find.byKey(
        const ValueKey('buy-recently-viewed-info-sheet'),
      );
      expect(sheet, findsOneWidget);
      final tomato = find.byKey(
        const ValueKey('buy-settings-recently-viewed-product-s-tomato'),
      );
      await tester.ensureVisible(tomato);
      await tester.tap(tomato);
      await tester.pumpAndSettle();
      expect(sheet, findsNothing);
      expect(session.selectedProductId, 's-tomato');
      expect(session.quantityFor('s-milk'), quantity);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(session.selectedProductId, 's-milk');
      session.openCart();
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.cart);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(session.selectedProductId, 's-milk');
      expect(session.quantityFor('s-milk'), quantity);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reference discovery never invents sponsorship or personalization',
    (tester) async {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await mountReferenceGallery(tester, session, 's-milk');
      final grid = find.byKey(const ValueKey('buy-product-more-grid-s-milk'));
      await revealProductControl(tester, session, grid);
      expect(
        find.byKey(const ValueKey('buy-product-recents-s-milk')),
        findsNothing,
      );
      expect(find.textContaining('Sponsored'), findsNothing);
      expect(find.textContaining('Based on your'), findsNothing);
      final current = session.product('s-milk');
      final similar = session
          .productContinuationsFor(current)
          .map((p) => p.id)
          .toSet();
      final expected = session.productDiscoveryFor(
        current,
        excludedProductIds: similar,
        limit: 8,
      );
      final actual = tester.widget<Wrap>(grid).children;
      expect(actual, hasLength(expected.length));
      for (final product in expected) {
        expect(
          find.descendant(
            of: grid,
            matching: find.byKey(
              ValueKey('buy-product-continuation-${product.id}'),
            ),
          ),
          findsOneWidget,
        );
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reference discovery sections preserve both product shell returns',
    (tester) async {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await mountReferenceGallery(tester, session, 's-milk');
      expect(session.addProduct('s-milk'), isTrue);
      final quantity = session.quantityFor('s-milk');
      for (final nested in [false, true]) {
        if (nested) {
          final visit = find.byKey(
            const ValueKey('buy-shop-seller-action-s-milk'),
          );
          await revealProductControl(tester, session, visit);
          await tester.tap(visit.hitTestable());
          await tester.pumpAndSettle();
          final tile = find
              .byKey(const ValueKey('buy-grid-packshot-s-milk'))
              .last;
          await tester.ensureVisible(tile);
          await tester.pumpAndSettle();
          await tester.tapAt(
            const Alignment(-.5, .55).withinRect(tester.getRect(tile)),
          );
          await tester.pumpAndSettle();
        }
        final grid = find.byKey(const ValueKey('buy-product-more-grid-s-milk'));
        await revealProductControl(tester, session, grid);
        final current = session.product('s-milk');
        final exclusions = {
          ...session.productContinuationsFor(current).map((p) => p.id),
          ...session
              .recentlyViewedProductsFor(current.destination)
              .map((p) => p.id),
        };
        final target = session
            .productDiscoveryFor(current, excludedProductIds: exclusions)
            .first;
        final card = find
            .descendant(
              of: grid,
              matching: find.byKey(
                ValueKey('buy-product-continuation-${target.id}'),
              ),
            )
            .last;
        await tester.ensureVisible(card);
        await tester.pumpAndSettle();
        await tester.tap(card.hitTestable());
        await tester.pumpAndSettle();
        expect(session.selectedProductId, target.id);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(session.selectedProductId, 's-milk');
        expect(session.quantityFor('s-milk'), quantity);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'reference recent variants retain exact identity and reject withdrawn products',
    (tester) async {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      expect(session.openProduct('s-milk-2l'), isTrue);
      await mountReferenceGallery(tester, session, 's-tomato');
      final recent = find.byKey(const ValueKey('buy-product-recents-s-tomato'));
      await revealProductControl(tester, session, recent);
      final variant = find.descendant(
        of: recent,
        matching: find.byKey(
          const ValueKey('buy-product-continuation-s-milk-2l'),
        ),
      );
      expect(variant, findsOneWidget);
      await tester.tap(variant.hitTestable());
      await tester.pumpAndSettle();
      expect(session.selectedProductId, 's-milk-2l');
      expect(session.selectedProduct!.pack, '2 × 1 L pouches');
      final externalCore = BuySession();
      final adapter = _SingleProductCommerceAdapter(
        session.product('s-milk-2l'),
      );
      final external = BuyV2Session(
        core: externalCore,
        commerceAdapter: adapter,
        reviewDataEnabled: false,
      );
      addTearDown(external.dispose);
      addTearDown(externalCore.dispose);
      await external.restoreCommerce();
      expect(external.openProduct('s-milk-2l'), isTrue);
      expect(
        external.recentlyViewedProductsFor(BuyV2Destination.shop).single.id,
        's-milk-2l',
      );
      adapter.product = session.product('s-tomato');
      await external.restoreCommerce();
      expect(
        external.recentlyViewedProductsFor(BuyV2Destination.shop),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reference discovery provider pagination retains loaded products on retry',
    (tester) async {
      final core = BuySession();
      final source = _DiscoveryPagingSource();
      final session = BuyV2Session(
        core: core,
        reviewDataEnabled: true,
        initialCatalogueRegionId: 'jodhpur',
        cataloguePageSource: source,
      );
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await mountReferenceGallery(tester, session, 's-milk');
      final grid = find.byKey(const ValueKey('buy-product-more-grid-s-milk'));
      await revealProductControl(tester, session, grid);
      final pager = session.acquireCatalogueProducts('product-more-s-milk');
      addTearDown(
        () => session.releaseCatalogueProducts('product-more-s-milk'),
      );
      expect(pager.page, isNotNull);
      expect(pager.page!.nextCursor, isNotNull);
      final expand = find.byKey(const ValueKey('buy-product-more-load-s-milk'));
      for (var i = 0; i < 6 && expand.evaluate().isNotEmpty; i++) {
        await revealProductControl(tester, session, expand);
        await tester.tap(expand.hitTestable());
        await tester.pumpAndSettle();
      }
      final initialPage = pager.page;
      final before = tester.widget<Wrap>(grid).children.length;
      expect(before, greaterThan(0));
      final next = find.text('Next products');
      await revealProductControl(tester, session, next);
      source.failNext = true;
      await tester.tap(next.hitTestable());
      await tester.pumpAndSettle();
      expect(pager.page, same(initialPage));
      expect(pager.message, isNotNull);
      expect(tester.widget<Wrap>(grid).children, hasLength(before));
      final retry = find.byTooltip('Retry more products');
      await revealProductControl(tester, session, retry);
      source.failNext = false;
      await tester.tap(retry.hitTestable());
      await tester.pumpAndSettle();
      expect(pager.message, isNull);
      expect(pager.page!.startIndex, greaterThan(initialPage!.startIndex));
      expect(
        pager.page!.items
            .map((p) => p.id)
            .toSet()
            .intersection(initialPage.items.map((p) => p.id).toSet()),
        isEmpty,
      );
      expect(tester.widget<Wrap>(grid).children.length, inInclusiveRange(1, 8));
      final previous = find.text('Previous products');
      await revealProductControl(tester, session, previous);
      await tester.tap(previous.hitTestable());
      await tester.pumpAndSettle();
      expect(pager.page!.startIndex, initialPage.startIndex);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reference discovery expiry follows displayed products after deduplication',
    (tester) async {
      final core = BuySession();
      final current = _pricedProduct(null);
      final target = BuyV2Catalogue.products
          .firstWhere((p) => p.id == 's-tomato')
          .copyWith(
            id: 'discovery-expiring',
            canonicalId: 'discovery-expiring',
            storeId: current.storeId,
          );
      final adapter = _SingleProductCommerceAdapter(current)
        ..extraProducts = [
          for (var i = 0; i < 10; i++)
            current.copyWith(id: 'similar-$i', canonicalId: 'similar-$i'),
          target,
        ];
      var now = DateTime.utc(2026, 9, 24, 12);
      final facts = _PricingFactsAdapter();
      final session = BuyV2Session(
        core: core,
        commerceAdapter: adapter,
        productFactsAdapter: facts,
        reviewDataEnabled: false,
        catalogueNow: () => now,
      );
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await session.restoreCommerce();
      for (final item in [current, ...adapter.extraProducts]) {
        facts.eligibilityByProduct[item.id] = BuyV2OfferEligibility(
          productId: item.id,
          storeId: item.storeId!,
          sourceRevision: 'discovery-expiry-1',
          customerLocationKey: session.eligibilityLocationKey,
          observedAt: now.subtract(const Duration(minutes: 1)),
          expiresAt: now.add(
            item.id == target.id
                ? const Duration(minutes: 1)
                : const Duration(days: 1),
          ),
          offerClass: item.offerClass!,
          channelEnabled: true,
          storeReady: true,
          fleetAvailable: true,
          customerLocationConfirmed: true,
          options: {BuyV2DeliveryOption.courier},
        );
      }
      expect(session.findProduct(target.id), isNotNull);
      expect(
        session.productFactsFor(target).orderabilityLabel,
        isNot(contains('unavailable')),
      );
      await mountReferenceGallery(tester, session, current.id);
      final grid = find.byKey(ValueKey('buy-product-more-grid-${current.id}'));
      await revealProductControl(tester, session, grid);
      final card = find.descendant(
        of: grid,
        matching: find.byKey(ValueKey('buy-product-continuation-${target.id}')),
      );
      expect(card, findsOneWidget);
      now = now.add(const Duration(minutes: 2));
      await tester.pump(const Duration(minutes: 2));
      await tester.pumpAndSettle();
      expect(
        card,
        findsNothing,
        reason:
            'Expired eligibility must refresh the displayed grid without another interaction.',
      );
      expect(tester.takeException(), isNull);
    },
  );

  test('reference invalid content never becomes ready catalogue fallback', () {
    for (final adapter in [
      _ContentAdapter()..productId = 'wrong-sku',
      _ContentAdapter()
        ..highlightFields = const [
          BuyV2ProductSpecification(
            attributeId: ' ',
            label: 'Unsafe source',
            value: 'Rejected',
          ),
        ],
    ]) {
      final core = BuySession();
      final session = BuyV2Session(core: core, productContentAdapter: adapter);
      final snapshot = session.productContentFor(session.product('s-milk'));
      expect(snapshot.state, BuyV2ProductContentState.unavailable);
      expect(snapshot.sourceId, 'buy-product-content-validation');
      expect(snapshot.productId, 's-milk');
      expect(snapshot.description, isNull);
      expect(snapshot.specifications, isEmpty);
      expect(snapshot.media, isEmpty);
      expect(snapshot.retryable, isFalse);
      session.dispose();
      core.dispose();
    }
    for (final state in [
      BuyV2ProductContentState.unavailable,
      BuyV2ProductContentState.offline,
    ]) {
      final core = BuySession();
      final adapter = _ContentAdapter()
        ..state = state
        ..message = null;
      final session = BuyV2Session(core: core, productContentAdapter: adapter);
      final snapshot = session.productContentFor(session.product('s-milk'));
      expect(snapshot.state, state);
      expect(snapshot.sourceId, 'product-content-test');
      expect(snapshot.customerMessage, isNull);
      expect(snapshot.description, isNull);
      expect(snapshot.media, isEmpty);
      adapter.state = BuyV2ProductContentState.ready;
      expect(session.refreshProductContent('s-milk'), isTrue);
      expect(
        session.productContentFor(session.product('s-milk')).description,
        adapter.description,
      );
      expect(session.cartLines, isEmpty);
      session.dispose();
      core.dispose();
    }
  });

  test('reference content revisions reject stale and wrong product facts', () {
    final core = BuySession();
    final adapter = _ContentAdapter()
      ..observedAt = DateTime.utc(2026, 9, 24, 12);
    final session = BuyV2Session(core: core, productContentAdapter: adapter);
    addTearDown(core.dispose);
    addTearDown(session.dispose);
    final product = session.product('s-milk');
    final original = session.productContentFor(product);
    adapter.observedAt = DateTime.utc(2026, 9, 24, 11);
    adapter.description = 'An older publication';
    expect(session.refreshProductContent(product.id), isFalse);
    expect(session.productContentFor(product), same(original));
    adapter.observedAt = DateTime.utc(2026, 9, 24, 13);
    adapter.productId = 'different-sku';
    expect(session.refreshProductContent(product.id), isFalse);
    expect(session.productContentFor(product), same(original));
    adapter.productId = null;
    adapter.description = 'The current published description';
    adapter.highlightFields = const [
      BuyV2ProductSpecification(
        attributeId: 'processing',
        label: 'Processing',
        value: 'Pasteurized',
      ),
    ];
    expect(session.refreshProductContent(product.id), isTrue);
    final current = session.productContentFor(product);
    expect(current.description, 'The current published description');
    expect(current.highlightFields.single.attributeId, 'processing');
    adapter.highlightFields = const [
      BuyV2ProductSpecification(
        attributeId: ' ',
        label: 'Processing',
        value: 'Pasteurized',
      ),
    ];
    expect(session.refreshProductContent(product.id), isFalse);
    expect(session.productContentFor(product), same(current));
    expect(session.cartLines, isEmpty);
  });

  testWidgets(
    'reference variant selector follows identity and preserves exact pack',
    (tester) async {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await mountReferenceGallery(tester, session, 's-milk');
      final variants = find.byKey(
        ValueKey(
          'buy-product-variants-${session.selectedProduct!.canonicalId}',
        ),
      );
      final title = find.byKey(const ValueKey('buy-product-title-s-milk'));
      final scroll = find
          .descendant(
            of: find.byKey(const PageStorageKey('buy-product-s-milk')),
            matching: find.byType(Scrollable),
          )
          .first;
      await revealProductControl(tester, session, title);
      final titlePosition =
          tester.getTopLeft(title).dy +
          tester.state<ScrollableState>(scroll).position.pixels;
      await revealProductControl(tester, session, variants);
      expect(
        tester.getTopLeft(variants).dy +
            tester.state<ScrollableState>(scroll).position.pixels,
        greaterThan(titlePosition),
      );
      final choice = find.byKey(
        const ValueKey('buy-product-variant-s-milk-500ml'),
      );
      await revealProductControl(tester, session, choice);
      await tester.tap(choice.hitTestable());
      await tester.pumpAndSettle();
      expect(session.selectedProductId, 's-milk-500ml');
      expect(
        session.selectedProduct!.pack,
        session.product('s-milk-500ml').pack,
      );
      expect(session.cartLines, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reference size chart uses category data and preserves selection',
    (tester) async {
      final core = BuySession();
      final adapter = _PricingContentAdapter();
      final session = BuyV2Session(core: core, productContentAdapter: adapter);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      final product = session.product('s-milk');
      adapter.chart = BuyV2ProductSizeChart(
        categoryId: product.categoryId,
        sourceRevision: 'chart-1',
        dimensionLabel: 'volume',
        columns: ['Pack', 'Volume (mL)'],
        rows: [
          ['Half litre', '500'],
          ['One litre', '1000'],
        ],
        instructions: ['Read the volume printed on the sealed pack.'],
      );
      await mountReferenceGallery(tester, session, product.id);
      tester.view.physicalSize = const Size(320, 800);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      final action = find.byKey(
        ValueKey('buy-product-size-chart-${product.id}'),
      );
      await revealProductControl(tester, session, action);
      await tester.tap(action.hitTestable());
      await tester.pumpAndSettle();
      final table = find.byKey(
        ValueKey('buy-product-size-chart-table-${product.id}'),
      );
      expect(table, findsOneWidget);
      expect(
        find.descendant(of: table, matching: find.text('Volume (mL)')),
        findsOneWidget,
      );
      expect(find.text('UK/India'), findsNothing);
      await captureR66Visual(tester, 'pdp02-chart-320-text200');
      await tester.tap(find.byTooltip('Close').last);
      await tester.pumpAndSettle();
      expect(session.selectedProductId, product.id);
      expect(session.cartLines, isEmpty);
      adapter.chart = null;
      session.refreshProductContent(product.id);
      await tester.pumpAndSettle();
      expect(action, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('reference price details use current amount and valid MRP once', (
    tester,
  ) async {
    final product = _pricedProduct(100);
    final core = BuySession();
    final facts = _PricingFactsAdapter();
    final session = BuyV2Session(
      core: core,
      commerceAdapter: _SingleProductCommerceAdapter(product),
      reviewDataEnabled: false,
      productFactsAdapter: facts,
    );
    addTearDown(core.dispose);
    addTearDown(session.dispose);
    await session.restoreCommerce();
    await mountReferenceGallery(tester, session, product.id);
    final action = find.byKey(
      ValueKey('buy-product-price-details-${product.id}'),
    );
    await revealProductControl(tester, session, action);
    expect(
      find.byKey(ValueKey('buy-product-discount-${product.id}')),
      findsOneWidget,
    );
    await tester.tap(action.hitTestable());
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(
      find.byKey(ValueKey('buy-product-price-details-inline-${product.id}')),
      findsOneWidget,
    );
    expect(find.text('MRP (incl. taxes)'), findsOneWidget);
    expect(find.text('Discount'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('₹34'), findsOneWidget);
    await captureR66Visual(tester, 'pdp02-price-details-360');
    facts.price = 90;
    expect(session.refreshProductFacts(product.id), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('₹10'), findsOneWidget);
    expect(find.text('₹34'), findsNothing);
    await tester.ensureVisible(action);
    await tester.tap(action.hitTestable());
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey('buy-product-price-details-inline-${product.id}')),
      findsNothing,
    );
    final hero = find.byKey(
      ValueKey('buy-product-purchase-hero-${product.id}'),
    );
    expect(
      find.descendant(
        of: hero,
        matching: find.textContaining(product.unitPrice),
      ),
      findsNothing,
    );
    facts.price = 110;
    session.refreshProductFacts(product.id);
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey('buy-product-discount-${product.id}')),
      findsNothing,
    );
    expect(session.cartLines, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'reference price history requires matching current offer and validity',
    (tester) async {
      final core = BuySession();
      final adapter = _PricingContentAdapter();
      final product = _pricedProduct(null);
      var now = DateTime.now();
      final initialNow = now;
      final session = BuyV2Session(
        core: core,
        productContentAdapter: adapter,
        commerceAdapter: _SingleProductCommerceAdapter(product),
        reviewDataEnabled: false,
        catalogueNow: () => now,
      );
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await session.restoreCommerce();
      adapter.history = _historyFor(product, at: now);
      await mountReferenceGallery(tester, session, product.id);
      final drop = find.byKey(ValueKey('buy-product-price-drop-${product.id}'));
      await revealProductControl(tester, session, drop);
      expect(find.text('Price dropped by ₹14'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      now = now.add(const Duration(days: 2));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(drop, findsNothing);
      now = initialNow;
      adapter.history = _historyFor(product, at: now);
      session.refreshProductContent(product.id);
      await tester.pumpAndSettle();
      expect(drop, findsOneWidget);

      adapter.history = _historyFor(product, storeId: 'another-store', at: now);
      session.refreshProductContent(product.id);
      await tester.pumpAndSettle();
      expect(drop, findsNothing);
      adapter.history = _historyFor(product, expired: true, at: now);
      session.refreshProductContent(product.id);
      await tester.pumpAndSettle();
      expect(drop, findsNothing);
      expect(session.cartLines, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reference delivery panel hides unverified or expired transport',
    (tester) async {
      final core = BuySession();
      final product = _pricedProduct(null);
      final facts = _PricingFactsAdapter();
      var now = DateTime.utc(2026, 9, 24, 12);
      final session = BuyV2Session(
        core: core,
        commerceAdapter: _SingleProductCommerceAdapter(product),
        productFactsAdapter: facts,
        reviewDataEnabled: false,
        catalogueNow: () => now,
      );
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await session.restoreCommerce();
      await mountReferenceGallery(tester, session, product.id);
      final panel = find.byKey(
        ValueKey('buy-automatic-fulfilment-${product.id}'),
      );
      await revealProductControl(tester, session, panel);
      Finder inside(String text) =>
          find.descendant(of: panel, matching: find.text(text));
      expect(inside('Method'), findsNothing);
      expect(inside('Check delivery availability'), findsOneWidget);
      expect(
        find.byKey(ValueKey('buy-product-change-address-${product.id}')),
        findsOneWidget,
      );
      facts.eligibility = BuyV2OfferEligibility(
        productId: product.id,
        storeId: product.storeId!,
        sourceRevision: 'delivery-test-1',
        customerLocationKey: session.eligibilityLocationKey,
        observedAt: now.subtract(const Duration(minutes: 1)),
        expiresAt: now.add(const Duration(minutes: 1)),
        offerClass: product.offerClass!,
        channelEnabled: true,
        storeReady: true,
        fleetAvailable: true,
        customerLocationConfirmed: true,
        options: {BuyV2DeliveryOption.courier},
      );
      session.refreshProductFacts(product.id);
      await tester.pumpAndSettle();
      expect(inside('MoolSocial Courier Delivery'), findsOneWidget);
      now = now.add(const Duration(minutes: 2));
      await tester.pump(const Duration(minutes: 2));
      await tester.pumpAndSettle();
      expect(inside('Method'), findsNothing);
      expect(inside('MoolSocial Courier Delivery'), findsNothing);
      expect(inside('Check delivery availability'), findsOneWidget);
      expect(session.addProduct(product.id), isFalse);
      expect(session.cartLines, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reference delivery seller panel has one owner and preserves location return',
    (tester) async {
      final core = BuySession();
      final session = BuyV2Session(
        core: core,
        marketplaceTrustAdapter: const _PricingTrustAdapter(),
      );
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await mountReferenceGallery(tester, session, 's-milk');
      final panel = find.byKey(
        const ValueKey('buy-automatic-fulfilment-s-milk'),
      );
      final action = find.byKey(
        const ValueKey('buy-product-change-address-s-milk'),
      );
      await revealProductControl(tester, session, action);
      expect(panel, findsOneWidget);
      expect(
        find.descendant(of: panel, matching: find.text('4.6')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: panel, matching: find.text('128')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: panel,
          matching: find.byKey(const ValueKey('buy-product-hero-store-s-milk')),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('buy-product-quick-actions-s-milk')),
        findsOneWidget,
      );
      await captureR66Visual(tester, 'pdp02-seller-panel-360');
      final nextAddress = session.addresses.firstWhere(
        (a) => a.id != session.selectedAddressOrNull?.id,
      );
      await tester.tap(action.hitTestable());
      await tester.pumpAndSettle();
      final choice = find.byKey(ValueKey('buy-address-${nextAddress.id}'));
      await tester.ensureVisible(choice);
      await tester.pumpAndSettle();
      await tester.tap(choice.hitTestable());
      await tester.pumpAndSettle();
      expect(session.selectedAddressOrNull?.id, nextAddress.id);
      expect(session.selectedProductId, 's-milk');
      expect(session.view, BuyV2View.product);
      expect(session.cartLines, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reference price and seller actions preserve both product shell returns',
    (tester) async {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await mountReferenceGallery(tester, session, 's-milk');
      final details = find.byKey(
        const ValueKey('buy-product-price-details-s-milk'),
      );
      await revealProductControl(tester, session, details);
      await tester.tap(details.hitTestable());
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      await tester.tap(details.hitTestable());
      await tester.pumpAndSettle();
      final visit = find.byKey(const ValueKey('buy-shop-seller-action-s-milk'));
      await revealProductControl(tester, session, visit);
      await tester.tap(visit.hitTestable());
      await tester.pumpAndSettle();
      final tile = find.byKey(const ValueKey('buy-grid-packshot-s-milk')).last;
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      await tester.tapAt(Alignment(-.5, .55).withinRect(tester.getRect(tile)));
      await tester.pumpAndSettle();
      await revealProductControl(tester, session, details);
      await tester.tap(details.hitTestable().last);
      await tester.pumpAndSettle();
      expect(find.text('Price details'), findsWidgets);
      await tester.tap(details.hitTestable().last);
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-grid-packshot-s-milk')),
        findsWidgets,
      );
      expect(session.cartLines, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'reference product pricing metadata rejects wrong identity and stale history',
    () {
      final product = _pricedProduct(100);
      final facts = const BuyV2CatalogueProductFactsAdapter().snapshotFor(
        product,
      );
      final now = DateTime.now();
      expect(
        _historyFor(product).isCurrentFor(product, facts: facts, now: now),
        isTrue,
      );
      expect(
        _historyFor(
          product,
          expired: true,
        ).isCurrentFor(product, facts: facts, now: now),
        isFalse,
      );
      expect(
        _historyFor(
          product,
          storeId: 'wrong',
        ).isCurrentFor(product, facts: facts, now: now),
        isFalse,
      );
      expect(
        _historyFor(product).isCurrentFor(
          product.copyWith(pack: 'Different pack'),
          facts: facts,
          now: now,
        ),
        isFalse,
      );
      expect(
        _historyFor(
          product,
        ).isCurrentFor(product, facts: facts.copyWith(price: 90), now: now),
        isFalse,
      );
      expect(
        _historyFor(
          product,
        ).isCurrentFor(product, facts: facts.copyWith(stale: true), now: now),
        isFalse,
      );
      final rows = <List<String>>[
        ['Small', '500'],
      ];
      final chart = BuyV2ProductSizeChart(
        categoryId: product.categoryId,
        sourceRevision: '1',
        dimensionLabel: 'volume',
        columns: ['Pack', 'mL'],
        rows: rows,
      );
      rows.first[1] = 'wrong';
      expect(chart.rows.first[1], '500');
      expect(chart.appliesTo(product), isTrue);
      expect(
        BuyV2ProductSizeChart(
          categoryId: 'wrong',
          sourceRevision: '1',
          dimensionLabel: 'size',
          columns: ['Size'],
          rows: [
            ['10'],
          ],
        ).appliesTo(product),
        isFalse,
      );
    },
  );

  testWidgets(
    'reference gallery swipes approved media and updates accessible position',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.reset);
      final core = BuySession();
      final adapter = _ReferenceMediaAdapter();
      final session = BuyV2Session(core: core, productContentAdapter: adapter);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await mountReferenceGallery(tester, session, 's-milk');
      final semantics = tester.ensureSemantics();
      try {
        expect(find.text('1 of 2'), findsOneWidget);
        await captureR66Visual(tester, 'pdp01-gallery-360-normal');
        final gallery = find.byKey(
          const ValueKey('buy-product-gallery-s-milk'),
        );
        await tester.drag(gallery, const Offset(-260, 0));
        await tester.pumpAndSettle();
        expect(find.text('2 of 2'), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('Photo 2 of 2')), findsWidgets);
        await tester.drag(gallery, const Offset(260, 0));
        await tester.pumpAndSettle();
        expect(find.text('1 of 2'), findsOneWidget);
        expect(session.cartLines, isEmpty);
        adapter.count = 20;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        expect(session.refreshProductContent('s-milk'), isTrue);
        await tester.pumpAndSettle();
        expect(find.text('1 of 20'), findsOneWidget);
        final lastIndicator = find.byKey(
          const ValueKey('buy-product-gallery-dot-19'),
        );
        expect(lastIndicator, findsOneWidget);
        expect(
          tester.getRect(lastIndicator).right,
          lessThanOrEqualTo(tester.getRect(gallery).right),
        );
        expect(tester.takeException(), isNull);
        await captureR66Visual(tester, 'pdp01-gallery-360-text200');
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'reference gallery refresh binds provider media revision without stale page',
    (tester) async {
      final core = BuySession();
      final adapter = _ReferenceMediaAdapter();
      final session = BuyV2Session(core: core, productContentAdapter: adapter);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await mountReferenceGallery(tester, session, 's-milk');
      final gallery = find.byKey(const ValueKey('buy-product-gallery-s-milk'));
      await tester.drag(gallery, const Offset(-600, 0));
      await tester.pumpAndSettle();
      expect(find.text('2 of 2'), findsOneWidget);
      adapter.revision++;
      expect(session.refreshProductContent('s-milk'), isTrue);
      await tester.pumpAndSettle();
      expect(find.text('1 of 2'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('buy-product-gallery-asset-s-milk-r1-0')),
        findsOneWidget,
      );
      expect(session.selectedProductId, 's-milk');
      final zoom = find.descendant(
        of: find.byKey(const ValueKey('buy-product-gallery-image-0')),
        matching: find.byType(InteractiveViewer),
      );
      tester.widget<InteractiveViewer>(zoom).transformationController!.value =
          Matrix4.diagonal3Values(2, 2, 1);
      await tester.pump();
      expect(
        tester
            .widget<InteractiveViewer>(zoom)
            .transformationController!
            .value
            .getMaxScaleOnAxis(),
        2,
      );
      adapter.revision++;
      expect(session.refreshProductContent('s-milk'), isTrue);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<InteractiveViewer>(zoom)
            .transformationController!
            .value
            .getMaxScaleOnAxis(),
        1,
      );
      expect(find.text('1 of 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reference gallery handles one missing and failed image with retry',
    (tester) async {
      final core = BuySession();
      final adapter = _ReferenceMediaAdapter()..count = 1;
      final session = BuyV2Session(core: core, productContentAdapter: adapter);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await mountReferenceGallery(tester, session, 's-milk');
      expect(
        find.byKey(const ValueKey('buy-product-gallery-count')),
        findsNothing,
      );
      adapter.count = 0;
      session.refreshProductContent('s-milk');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-product-illustration-s-milk')),
        findsOneWidget,
      );
      adapter.count = 1;
      adapter.failed = true;
      session.refreshProductContent('s-milk');
      await tester.pumpAndSettle();
      expect(find.text('Image unavailable'), findsOneWidget);
      adapter.failed = false;
      await tester.tap(
        find.byKey(const ValueKey('buy-product-image-retry-s-milk-r0-0')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Image unavailable'), findsNothing);
      expect(
        find.byKey(const ValueKey('buy-product-gallery-asset-s-milk-r0-0')),
        findsOneWidget,
      );
      expect(session.cartLines, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reference gallery actions are unique and preserve cart identity',
    (tester) async {
      for (final id in ['s-milk', 'w-atta']) {
        final core = BuySession();
        final session = BuyV2Session(
          core: core,
          productContentAdapter: _ReferenceMediaAdapter(),
        );
        session.openProduct(id);
        await mountReferenceGallery(tester, session, id);
        final save = find.byKey(ValueKey('buy-product-action-save-$id'));
        expect(save, findsOneWidget);
        expect(
          find.byKey(ValueKey('buy-product-action-share-$id')),
          findsOneWidget,
        );
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(session.isSaved(id), isTrue);
        expect(
          find.byKey(ValueKey('buy-product-action-saved-$id')),
          findsOneWidget,
        );
        expect(session.selectedProductId, id);
        expect(session.cartLines, isEmpty);
        expect(find.byKey(ValueKey('buy-product-buy-now-$id')), findsNothing);
        expect(find.text('Continue shopping'), findsNothing);
        expect(
          find.byKey(const ValueKey('buy-cart-navigation-button')),
          findsNothing,
        );
        expect(session.addProduct('s-tomato'), isTrue);
        final otherQuantity = session.quantityFor('s-tomato');
        await tester.pumpAndSettle();
        final add = find.byKey(ValueKey('buy-product-primary-$id'));
        await revealProductControl(tester, session, add);
        await tester.tap(add.hitTestable());
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.product);
        expect(session.quantityFor(id), session.product(id).minimumOrder);
        expect(session.quantityFor('s-tomato'), otherQuantity);
        final cart = find.byKey(const ValueKey('buy-cart-navigation-button'));
        expect(cart.hitTestable(), findsOneWidget);
        await tester.tap(cart.hitTestable());
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.cart);
        expect(
          session.cartScope,
          id.startsWith('w-') ? BuyV2CartScope.wholesale : BuyV2CartScope.shop,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        session.dispose();
        core.dispose();
      }
    },
  );

  testWidgets('reference gallery preserves navigation in both product shells', (
    tester,
  ) async {
    final core = BuySession();
    final session = BuyV2Session(
      core: core,
      productContentAdapter: _ReferenceMediaAdapter(),
    );
    addTearDown(core.dispose);
    addTearDown(session.dispose);
    await mountReferenceGallery(tester, session, 's-milk');
    expect(
      find.byKey(const ValueKey('buy-product-gallery-s-milk')),
      findsOneWidget,
    );
    final visit = find.byKey(const ValueKey('buy-shop-seller-action-s-milk'));
    await revealProductControl(tester, session, visit);
    await tester.pumpAndSettle();
    await tester.tap(visit.hitTestable());
    await tester.pumpAndSettle();
    final tile = find.byKey(const ValueKey('buy-grid-packshot-s-milk')).last;
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tapAt(Alignment(-.5, .55).withinRect(tester.getRect(tile)));
    await tester.pumpAndSettle();
    expect(session.selectedProductId, 's-milk');
    final gallery = find
        .byKey(const ValueKey('buy-product-gallery-s-milk'))
        .last;
    await tester.ensureVisible(gallery);
    await tester.pumpAndSettle();
    expect(gallery, findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-grid-packshot-s-milk')),
      findsWidgets,
    );
    expect(session.cartLines, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Shop and Wholesale product heroes expose complete purchase decisions',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);

      for (final productId in const ['s-atta', 'w-atta']) {
        final core = BuySession();
        final session = BuyV2Session(core: core);
        final product = session.product(productId);
        expect(session.openProduct(productId), isTrue);
        await tester.pumpWidget(
          MaterialApp(
            theme: MoolTheme.light(),
            home: BuyV2Screen(
              session: session,
              initialDestination: session.destination,
              initialView: session.view,
              productId: productId,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final hero = find.byKey(
          ValueKey('buy-product-purchase-hero-$productId'),
        );
        expect(hero, findsOneWidget);
        expect(
          find.descendant(of: hero, matching: find.text(product.title)),
          findsOneWidget,
        );
        expect(
          find.byKey(ValueKey('buy-product-hero-price-$productId')),
          findsOneWidget,
        );
        final compliance = find.byKey(
          ValueKey('buy-product-compliance-$productId'),
        );
        expect(product.compliance, isNull);
        expect(product.mrp, isNull);
        expect(compliance, findsNothing);
        expect(
          find.descendant(
            of: hero,
            matching: find.textContaining(product.pack),
          ),
          findsWidgets,
        );
        expect(find.text('Buy now'), findsNothing);
        expect(
          find.byKey(ValueKey('buy-product-purchase-dock-$productId')),
          findsNothing,
        );
        final fulfilment = find.byKey(
          ValueKey('buy-automatic-fulfilment-$productId'),
        );
        await tester.scrollUntilVisible(
          fulfilment,
          160,
          scrollable: find
              .descendant(
                of: find.byType(ListView).first,
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(
          find.descendant(
            of: fulfilment,
            matching: find.textContaining(
              'Delivery time confirmed at checkout',
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: fulfilment,
            matching: find.textContaining(product.seller),
          ),
          findsWidgets,
        );
        expect(tester.takeException(), isNull);

        session.dispose();
        core.dispose();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    },
  );

  testWidgets('product compliance shows supplied facts and hides no data', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final product = BuyV2Catalogue.products.first.copyWith(
      compliance: const BuyV2ProductCompliance(
        genericName: 'Refined sunflower oil',
        netQuantity: '5 L',
        manufacturerName: 'Surya Oils India',
        packerName: 'Surya Oils India',
        importerName: 'Mool Imports India',
        countryOfOrigin: 'India',
        manufacturedOrPackedOnLabel: 'Packed August 2026',
        bestBeforeOrUseByLabel: 'Best before 12 months from packing',
        fssaiLicenseNumber: '10000000000000',
        consumerCare: 'Surya Oils Consumer Care',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: BuyV2ProductCompliancePanel(product: product),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final value in const [
      'Product and pack information',
      'Generic name',
      'Net quantity',
      'Refined sunflower oil',
      '5 L',
      'Surya Oils India',
      'Mool Imports India',
      'India',
      'Packed August 2026',
      'Best before 12 months from packing',
      '10000000000000',
      'Surya Oils Consumer Care',
    ]) {
      expect(find.text(value), findsWidgets, reason: value);
    }
    expect(find.textContaining('Not provided'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing optional compliance facts stay hidden', (tester) async {
    final product = BuyV2Catalogue.products.first.copyWith(
      compliance: const BuyV2ProductCompliance(
        genericName: '  ',
        netQuantity: '',
        manufacturerName: '   ',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: Scaffold(body: BuyV2ProductCompliancePanel(product: product)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(product.title), findsOneWidget);
    expect(find.text(product.pack), findsOneWidget);
    expect(find.text(product.unitPrice), findsOneWidget);
    expect(find.text('Product'), findsOneWidget);
    expect(find.text('Pack'), findsOneWidget);
    for (final label in const [
      'Generic name',
      'Net quantity',
      'Manufacturer',
      'Packer',
      'Importer',
      'Country of origin',
      'Manufactured or packed',
      'Best before / use by',
      'FSSAI licence',
      'Consumer care',
    ]) {
      expect(find.text(label), findsNothing, reason: label);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'published protection fields remain complete at compact large text',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final product = BuyV2Catalogue.products.first.copyWith(
        purchaseProtection: const BuyV2PurchaseProtection(
          summary: 'Replacement or refund available',
          remedies: ['Replacement', 'Refund', '  '],
          windowLabel: 'Within 7 days of delivery',
          conditionsLabel: 'Unused with original packaging',
          verificationLabel: 'Photo or pickup inspection',
          initiationLabel: 'Open the order and select Get help',
          approvalLabel: 'After condition review',
          pickupLabel: 'Pickup in original packaging',
          refundMethodLabel: 'Original payment method',
          refundTimelineLabel: 'After verification',
          warrantyLabel: 'One-year manufacturer warranty',
          nonReturnableReason: 'Change-of-mind return unavailable',
          policyVersion: 'POLICY-7',
          effectiveFromLabel: '1 September 2026',
        ),
      );
      final core = BuySession();
      final session = BuyV2Session(
        core: core,
        commerceAdapter: _SingleProductCommerceAdapter(product),
        reviewDataEnabled: false,
      );
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      await session.restoreCommerce();
      expect(session.openProduct(product.id), isTrue);

      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          home: BuyV2Screen(
            session: session,
            initialDestination: product.destination,
            initialView: BuyV2View.product,
            productId: product.id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final productScroll = find
          .descendant(
            of: find.byKey(PageStorageKey('buy-product-${product.id}')),
            matching: find.byType(Scrollable),
          )
          .first;
      final returns = find.byKey(
        ValueKey('buy-product-assurance-returns-${product.id}'),
      );
      await tester.scrollUntilVisible(returns, 220, scrollable: productScroll);
      await tester.pumpAndSettle();
      await tester.tap(returns.hitTestable());
      await tester.pumpAndSettle();
      for (final value in const [
        'Replacement or refund available',
        'Available options: Replacement, Refund',
        'Request window: Within 7 days of delivery',
        'Conditions: Unused with original packaging',
        'Verification: Photo or pickup inspection',
        'How to request: Open the order and select Get help',
        'Approval: After condition review',
        'Pickup: Pickup in original packaging',
        'Refund method: Original payment method',
        'Refund timeline: After verification',
        'Warranty: One-year manufacturer warranty',
        'Non-returnable: Change-of-mind return unavailable',
        'Policy reference: POLICY-7',
        'Applies from: 1 September 2026',
      ]) {
        expect(find.text(value), findsOneWidget, reason: value);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'product gallery and details use one authoritative content owner',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final core = BuySession();
      final adapter = _ContentAdapter();
      final session = BuyV2Session(core: core, productContentAdapter: adapter);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      expect(session.openProduct('s-milk'), isTrue);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: MoolTheme.light(),
          home: BuyV2Screen(
            session: session,
            initialDestination: session.destination,
            initialView: session.view,
            productId: session.selectedProductId,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('buy-product-gallery-count')),
        findsOneWidget,
      );
      expect(find.text('1 of 2'), findsOneWidget);
      final ready = find.byKey(
        const ValueKey('buy-product-content-ready-s-milk'),
      );
      await tester.scrollUntilVisible(
        ready,
        220,
        scrollable: find
            .descendant(
              of: find.byKey(const PageStorageKey('buy-product-s-milk')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('Product highlights'), findsOneWidget);
      expect(find.text('Cold-chain quality checked'), findsOneWidget);
      expect(find.text('Specifications'), findsOneWidget);
      expect(find.text('Shelf life'), findsOneWidget);
      expect(find.text('2 days'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      final descriptionTab = find.byKey(
        const ValueKey('buy-product-details-tab-1-s-milk'),
      );
      await revealProductControl(tester, session, descriptionTab);
      await tester.tap(descriptionTab.hitTestable());
      await tester.pumpAndSettle();
      expect(
        find.text('Fresh toned milk supplied in a sealed pouch.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reference product highlights partition supplied attribute keys',
    (tester) async {
      final core = BuySession();
      final adapter = _ContentAdapter()
        ..highlightFields = const [
          BuyV2ProductSpecification(
            attributeId: 'shelf',
            label: 'Shelf life',
            value: '2 days',
          ),
          BuyV2ProductSpecification(
            attributeId: 'storage',
            label: 'Storage life',
            value: '2 days',
          ),
        ]
        ..specifications = const [
          BuyV2ProductSpecification(
            attributeId: 'shelf',
            label: 'Shelf life',
            value: '2 days',
          ),
          BuyV2ProductSpecification(
            attributeId: 'process',
            label: 'Processing',
            value: 'Pasteurized',
          ),
        ];
      final session = BuyV2Session(core: core, productContentAdapter: adapter);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      await mountReferenceGallery(tester, session, 's-milk');
      await revealProductControl(
        tester,
        session,
        find.text('Product highlights'),
      );
      expect(find.text('Shelf life'), findsOneWidget);
      expect(find.text('Storage life'), findsOneWidget);
      expect(find.text('2 days'), findsNWidgets(2));
      expect(find.text('Processing'), findsOneWidget);
      await captureR66Visual(tester, 'pdp05-highlights');
      expect(session.cartLines, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('reference specifications preserve category fields and units', (
    tester,
  ) async {
    final core = BuySession();
    final adapter = _ContentAdapter()
      ..specifications = const [
        BuyV2ProductSpecification(
          attributeId: 'pack_count',
          groupLabel: 'Package contents',
          label: 'Pack count',
          value: '6',
        ),
        BuyV2ProductSpecification(
          attributeId: 'net_quantity',
          groupLabel: 'Package contents',
          label: 'Net quantity',
          value: '1.2 L',
        ),
        BuyV2ProductSpecification(
          attributeId: 'material',
          groupLabel: 'Container',
          label: 'Material',
          value: 'Food-grade pouch',
        ),
      ];
    final session = BuyV2Session(core: core, productContentAdapter: adapter);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    await mountReferenceGallery(tester, session, 's-milk');
    await revealProductControl(tester, session, find.text('All details'));
    for (final value in [
      'Package contents',
      'Pack count',
      '6',
      'Net quantity',
      '1.2 L',
      'Container',
      'Food-grade pouch',
    ]) {
      expect(find.text(value), findsOneWidget, reason: value);
    }
    expect(find.text('General'), findsNothing);
    await captureR66Visual(tester, 'pdp05-specifications');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'reference description retains approved paragraphs without summary repetition',
    (tester) async {
      final core = BuySession();
      final adapter = _ContentAdapter()
        ..description = 'Keep refrigerated.\n\nShake well before use.';
      final session = BuyV2Session(core: core, productContentAdapter: adapter);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      await mountReferenceGallery(tester, session, 's-milk');
      final tab = find.byKey(
        const ValueKey('buy-product-details-tab-1-s-milk'),
      );
      await revealProductControl(tester, session, tab);
      await tester.tap(tab.hitTestable());
      await tester.pumpAndSettle();
      expect(find.text(adapter.description), findsOneWidget);
      expect(find.text('Shelf life'), findsNothing);
      expect(find.text('Product and pack information'), findsNothing);
      await captureR66Visual(tester, 'pdp05-description');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reference manufacturer tab preserves producer addresses and legal facts',
    (tester) async {
      final product = _pricedProduct(null).copyWith(
        compliance: const BuyV2ProductCompliance(
          genericName: 'Toned milk',
          netQuantity: '1 L',
          countryOfOrigin: 'India',
          manufacturerName: 'Source Dairy',
          manufacturerAddress: 'Factory Road, Jaipur 302001',
          packerName: 'Source Packing',
          packerAddress: 'Packing Road, Ajmer 305001',
          importerName: 'Source Imports',
          importerAddress: 'Import Road, Mumbai 400001',
          fssaiLicenseNumber: '10000000000000',
          consumerCare: 'Source Dairy care',
        ),
      );
      final core = BuySession();
      final session = BuyV2Session(
        core: core,
        commerceAdapter: _SingleProductCommerceAdapter(product),
        reviewDataEnabled: false,
        productContentAdapter: _ContentAdapter(),
      );
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await session.restoreCommerce();
      await mountReferenceGallery(tester, session, product.id);
      final tab = find.byKey(
        ValueKey('buy-product-details-tab-2-${product.id}'),
      );
      await revealProductControl(tester, session, tab);
      await tester.tap(tab.hitTestable());
      await tester.pumpAndSettle();
      final panel = find.byKey(
        ValueKey('buy-product-compliance-${product.id}'),
      );
      for (final value in [
        'Toned milk',
        '1 L',
        'India',
        'Source Dairy',
        'Factory Road, Jaipur 302001',
        'Source Packing',
        'Packing Road, Ajmer 305001',
        'Source Imports',
        'Import Road, Mumbai 400001',
        '10000000000000',
        'Source Dairy care',
      ]) {
        expect(
          find.descendant(of: panel, matching: find.text(value)),
          findsOneWidget,
          reason: value,
        );
      }
      expect(
        find.descendant(of: panel, matching: find.text(product.seller)),
        findsNothing,
      );
      expect(find.text('Product and pack information'), findsNothing);
      await captureR66Visual(tester, 'pdp05-manufacturer-source-addresses');
      await tester.ensureVisible(find.text('Import Road, Mumbai 400001'));
      await tester.pumpAndSettle();
      await captureR66Visual(tester, 'pdp05-manufacturer-addresses-bottom');
      expect(tester.takeException(), isNull);
    },
  );

  for (final scale in [1.0, 2.0]) {
    testWidgets('selected manufacturer tab reveals its entire label $scale', (
      tester,
    ) async {
      final core = BuySession();
      final session = BuyV2Session(
        core: core,
        productContentAdapter: _ContentAdapter(),
      );
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await mountReferenceGallery(tester, session, 's-milk');
      tester.view.physicalSize = const Size(320, 800);
      await tester.pumpAndSettle();
      final tab = find.byKey(
        const ValueKey('buy-product-details-tab-2-s-milk'),
      );
      final viewport = find.byKey(
        const PageStorageKey('buy-product-details-tabs-s-milk'),
      );
      await revealProductControl(tester, session, viewport);
      // Activate without ensureVisible(tab) hiding the original clipping defect.
      tester.widget<TextButton>(tab).onPressed!();
      await tester.pumpAndSettle();
      void expectVisibleLabel() {
        final bounds = tester.getRect(viewport);
        final label = tester.getRect(find.text('Manufacturer info'));
        expect(label.left, greaterThanOrEqualTo(bounds.left - .5));
        expect(label.right, lessThanOrEqualTo(bounds.right + .5));
      }

      expectVisibleLabel();
      expect(find.text('Customer rating'), findsNothing);
      expect(find.text('Customer ratings'), findsOneWidget);
      expect(session.addProduct('s-milk'), isTrue);
      final quantity = session.quantityFor('s-milk');
      session.openCart();
      await tester.pumpAndSettle();
      session.goBack();
      await tester.pumpAndSettle();
      await revealProductControl(tester, session, viewport);
      expectVisibleLabel();
      expect(session.quantityFor('s-milk'), quantity);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('reference detail tabs retain SKU state and fit enlarged text', (
    tester,
  ) async {
    final core = BuySession();
    final adapter = _ContentAdapter()
      ..highlightFields = [
        for (var i = 0; i < 6; i++)
          BuyV2ProductSpecification(
            attributeId: 'fact-$i',
            label: 'Supplied fact $i',
            value: 'Exact quantity $i g',
          ),
      ];
    final session = BuyV2Session(core: core, productContentAdapter: adapter);
    addTearDown(core.dispose);
    addTearDown(session.dispose);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await mountReferenceGallery(tester, session, 's-milk');
    tester.view.physicalSize = const Size(320, 800);
    await tester.pumpAndSettle();
    final expand = find.byKey(
      const ValueKey('buy-product-highlights-expand-s-milk'),
    );
    await revealProductControl(tester, session, expand);
    await tester.tap(expand.hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('Supplied fact 5'), findsOneWidget);
    final tab = find.byKey(const ValueKey('buy-product-details-tab-1-s-milk'));
    await revealProductControl(tester, session, tab);
    await tester.tap(tab.hitTestable());
    await tester.pumpAndSettle();
    expect(find.text(adapter.description), findsOneWidget);
    final tabParagraph = tester.renderObject<RenderParagraph>(
      find.text('Description'),
    );
    expect(tabParagraph.text.style?.fontFamily, isNotNull);
    final reviewParagraph = tester.renderObject<RenderParagraph>(
      find.text('Write review'),
    );
    expect(
      reviewParagraph.getBoxesForSelection(
        const TextSelection(baseOffset: 6, extentOffset: 12),
      ),
      hasLength(1),
    );
    await captureR66Visual(tester, 'pdp05-details-320-text200');
    expect(session.addProduct('s-milk'), isTrue);
    expect(session.quantityFor('s-milk'), greaterThan(0));
    session.openCart();
    await tester.pumpAndSettle();
    session.goBack();
    await tester.pumpAndSettle();
    await revealProductControl(tester, session, tab);
    expect(find.text(adapter.description), findsOneWidget);
    expect(find.text('Show less'), findsOneWidget);
    expect(session.selectedProductId, 's-milk');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'reference details preserve both product shell and cart returns',
    (tester) async {
      final core = BuySession();
      final session = BuyV2Session(
        core: core,
        productContentAdapter: _ContentAdapter(),
      );
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      session.addProduct('s-milk');
      final quantity = session.quantityFor('s-milk');
      await mountReferenceGallery(tester, session, 's-milk');
      for (final nested in [false, true]) {
        if (nested) {
          final visit = find.byKey(
            const ValueKey('buy-shop-seller-action-s-milk'),
          );
          await revealProductControl(tester, session, visit);
          await tester.tap(visit.hitTestable());
          await tester.pumpAndSettle();
          final tile = find
              .byKey(const ValueKey('buy-grid-packshot-s-milk'))
              .last;
          await tester.ensureVisible(tile);
          await tester.pumpAndSettle();
          await tester.tapAt(
            const Alignment(-.5, .55).withinRect(tester.getRect(tile)),
          );
          await tester.pumpAndSettle();
        }
        final tab = find.byKey(
          const ValueKey('buy-product-details-tab-1-s-milk'),
        );
        await revealProductControl(tester, session, tab);
        await tester.tap(tab.hitTestable().last);
        await tester.pumpAndSettle();
        expect(
          find.text('Fresh toned milk supplied in a sealed pouch.'),
          findsWidgets,
        );
        expect(session.quantityFor('s-milk'), quantity);
        expect(tester.takeException(), isNull);
      }
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-grid-packshot-s-milk')),
        findsWidgets,
      );
      expect(session.quantityFor('s-milk'), quantity);
    },
  );

  testWidgets(
    'reference details isolate SKU tabs expansion and restore Back position',
    (tester) async {
      final core = BuySession();
      final adapter = _ContentAdapter()
        ..highlightFields = [
          for (var i = 0; i < 6; i++)
            BuyV2ProductSpecification(
              attributeId: 'field-$i',
              label: 'Field $i',
              value: '$i g',
            ),
        ];
      final session = BuyV2Session(core: core, productContentAdapter: adapter);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await mountReferenceGallery(tester, session, 's-milk');
      final expand = find.byKey(
        const ValueKey('buy-product-highlights-expand-s-milk'),
      );
      await revealProductControl(tester, session, expand);
      await tester.tap(expand.hitTestable());
      await tester.pumpAndSettle();
      final description = find.byKey(
        const ValueKey('buy-product-details-tab-1-s-milk'),
      );
      await revealProductControl(tester, session, description);
      await tester.tap(description.hitTestable());
      await tester.pumpAndSettle();
      final scroll = find
          .descendant(
            of: find.byKey(const PageStorageKey('buy-product-s-milk')),
            matching: find.byType(Scrollable),
          )
          .first;
      final position = tester.state<ScrollableState>(scroll).position.pixels;
      expect(
        session.openProduct('s-tomato', preserveComparisonOrigin: true),
        isTrue,
      );
      await tester.pumpAndSettle();
      await revealProductControl(
        tester,
        session,
        find.byKey(const ValueKey('buy-product-details-tab-0-s-tomato')),
      );
      expect(find.text('Shelf life'), findsOneWidget);
      expect(find.text('Show all highlights'), findsOneWidget);
      expect(find.text('Field 5'), findsNothing);
      expect(find.text(adapter.description), findsNothing);
      session.goBack();
      await tester.pumpAndSettle();
      expect(session.selectedProductId, 's-milk');
      expect(
        tester.state<ScrollableState>(scroll).position.pixels,
        closeTo(position, 1),
      );
      expect(find.text(adapter.description), findsOneWidget);
      expect(find.text('Show less'), findsOneWidget);
      expect(find.text('Field 5'), findsOneWidget);
      final selected = tester.widget<Ink>(
        find.descendant(of: description, matching: find.byType(Ink)).first,
      );
      final decoration = selected.decoration! as BoxDecoration;
      expect(decoration.gradient, isA<LinearGradient>());
      expect(decoration.border, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reference details missing loading and retry states remain truthful',
    (tester) async {
      final core = BuySession();
      final adapter = _ContentAdapter()
        ..omitDescription = true
        ..highlights = []
        ..specifications = [];
      final session = BuyV2Session(core: core, productContentAdapter: adapter);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await mountReferenceGallery(tester, session, 's-milk');
      expect(
        session.productContentFor(session.selectedProduct!).sourceId,
        'product-content-test',
      );
      expect(
        session.productContentFor(session.selectedProduct!).state,
        BuyV2ProductContentState.ready,
      );
      await revealProductControl(
        tester,
        session,
        find.text('Product details unavailable'),
      );
      expect(find.text('Product details unavailable'), findsOneWidget);
      expect(find.text('All details'), findsNothing);
      final retry = find.byKey(
        const ValueKey('buy-product-content-retry-s-milk'),
      );
      expect(retry, findsNothing);
      adapter.state = BuyV2ProductContentState.loading;
      expect(session.refreshProductContent('s-milk'), isTrue);
      await tester.pumpAndSettle();
      expect(find.text('Loading product details'), findsOneWidget);
      expect(retry, findsNothing);
      adapter.state = BuyV2ProductContentState.unavailable;
      adapter.message = 'Product details unavailable';
      expect(session.refreshProductContent('s-milk'), isTrue);
      await tester.pumpAndSettle();
      expect(find.text('Product details unavailable'), findsOneWidget);
      expect(retry, findsNothing);
      adapter.retryable = true;
      expect(session.refreshProductContent('s-milk'), isTrue);
      await tester.pumpAndSettle();
      await revealProductControl(tester, session, retry);
      adapter.state = BuyV2ProductContentState.ready;
      adapter.omitDescription = false;
      adapter.description = 'A recovered supplied description.';
      await tester.tap(retry.hitTestable());
      await tester.pumpAndSettle();
      expect(find.text('Product details unavailable'), findsNothing);
      final tab = find.byKey(
        const ValueKey('buy-product-details-tab-1-s-milk'),
      );
      await revealProductControl(tester, session, tab);
      await tester.tap(tab.hitTestable());
      await tester.pumpAndSettle();
      expect(find.text(adapter.description), findsOneWidget);
      expect(session.cartLines, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reference details keep legal fields in one owner through content failure',
    (tester) async {
      final product = _pricedProduct(null).copyWith(
        compliance: const BuyV2ProductCompliance(
          manufacturerName: 'Approved legal producer',
          netQuantity: '1 L',
          consumerCare: 'Approved consumer care',
        ),
      );
      final core = BuySession();
      final adapter = _ContentAdapter()
        ..highlightFields = const [
          BuyV2ProductSpecification(
            attributeId: 'manufacturer_name',
            label: 'Manufacturer',
            value: 'Conflicting content producer',
          ),
          BuyV2ProductSpecification(
            attributeId: 'net_quantity',
            label: 'Net quantity',
            value: '1 L',
          ),
        ]
        ..specifications = const [
          BuyV2ProductSpecification(
            attributeId: 'manufacturer_address',
            label: 'Producer address',
            value: 'Factory plot 18, Industrial Area, Jaipur 302001',
          ),
          BuyV2ProductSpecification(
            attributeId: 'pack_count',
            label: 'Pack count',
            value: '6',
          ),
        ];
      final session = BuyV2Session(
        core: core,
        commerceAdapter: _SingleProductCommerceAdapter(product),
        productContentAdapter: adapter,
        reviewDataEnabled: false,
      );
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await session.restoreCommerce();
      await mountReferenceGallery(tester, session, product.id);
      final content = find.byKey(
        ValueKey('buy-product-content-ready-${product.id}'),
      );
      await revealProductControl(tester, session, find.text('All details'));
      expect(
        find.descendant(of: content, matching: find.text('Pack count')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: content, matching: find.text('Net quantity')),
        findsNothing,
      );
      expect(find.text('Conflicting content producer'), findsNothing);
      final tab = find.byKey(
        ValueKey('buy-product-details-tab-2-${product.id}'),
      );
      await revealProductControl(tester, session, tab);
      await tester.tap(tab.hitTestable());
      await tester.pumpAndSettle();
      expect(find.text('Approved legal producer'), findsOneWidget);
      expect(find.text('Conflicting content producer'), findsNothing);
      expect(
        find.text('Factory plot 18, Industrial Area, Jaipur 302001'),
        findsOneWidget,
      );
      final last = find.text('Approved consumer care');
      await tester.ensureVisible(last);
      await tester.pumpAndSettle();
      expect(last.hitTestable(), findsOneWidget);
      expect(
        tester.getRect(last).bottom,
        lessThanOrEqualTo(
          tester.view.physicalSize.height / tester.view.devicePixelRatio,
        ),
      );
      adapter.state = BuyV2ProductContentState.offline;
      expect(session.refreshProductContent(product.id), isTrue);
      await tester.pumpAndSettle();
      expect(find.text('Approved legal producer'), findsOneWidget);
      expect(find.text('Approved consumer care'), findsOneWidget);
      expect(
        find.text('Factory plot 18, Industrial Area, Jaipur 302001'),
        findsNothing,
      );
      expect(find.text('Product details unavailable'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('unavailable product details retry without changing Cart', (
    tester,
  ) async {
    final core = BuySession();
    final adapter = _ContentAdapter()..available = false;
    final session = BuyV2Session(core: core, productContentAdapter: adapter);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    expect(session.openProduct('s-milk'), isTrue);

    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: BuyV2Screen(
          session: session,
          initialDestination: session.destination,
          initialView: session.view,
          productId: session.selectedProductId,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final retry = find.byKey(
      const ValueKey('buy-product-content-retry-s-milk'),
    );
    await tester.scrollUntilVisible(
      retry,
      220,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('buy-product-s-milk')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Product details unavailable'), findsOneWidget);
    expect(
      find.text('Product information could not be loaded.'),
      findsOneWidget,
    );
    adapter.available = true;
    await tester.ensureVisible(retry);
    await tester.pumpAndSettle();
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-product-content-ready-s-milk')),
      findsOneWidget,
    );
    expect(session.cartLines, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'authoritative product video enters the gallery and preserves Back',
    (tester) async {
      final core = BuySession();
      final session = BuyV2Session(
        core: core,
        productContentAdapter: const _VideoContentAdapter(),
      );
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      expect(session.openProduct('s-milk'), isTrue);

      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          home: BuyV2Screen(
            session: session,
            initialDestination: session.destination,
            initialView: session.view,
            productId: session.selectedProductId,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('buy-product-video-s-milk-video')),
        findsOneWidget,
      );
      expect(
        find.text('This product video is unavailable right now.'),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(
          const ValueKey('buy-product-video-error-transcript-s-milk-video'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Video transcript'), findsOneWidget);
      expect(find.textContaining('sealed milk pouch'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('buy-product-video-transcript-close')),
      );
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.catalogue);
      expect(session.destination, BuyV2Destination.shop);
      expect(tester.takeException(), isNull);
    },
  );
}

BuyV2Product _pricedProduct(int? mrp) {
  final p = BuyV2Catalogue.products.firstWhere((p) => p.id == 's-milk');
  return BuyV2Product(
    id: p.id,
    canonicalId: p.canonicalId,
    storeId: 'pricing-store-a',
    destination: p.destination,
    categoryId: p.categoryId,
    brand: p.brand,
    title: p.title,
    variant: p.variant,
    pack: p.pack,
    price: p.price,
    unitPrice: p.unitPrice,
    badge: p.badge,
    seller: p.seller,
    sellerType: p.sellerType,
    deliveryPromise: p.deliveryPromise,
    origin: p.origin,
    confirmedOn: p.confirmedOn,
    visualLabel: p.visualLabel,
    visualKind: p.visualKind,
    reviewDeliveryOptions: p.reviewDeliveryOptions,
    offerClass: BuyV2OfferClass.retail,
    mrp: mrp,
  );
}

BuyV2ProductPriceHistory _historyFor(
  BuyV2Product p, {
  String? storeId,
  bool expired = false,
  DateTime? at,
}) {
  final now = at ?? DateTime.now();
  return BuyV2ProductPriceHistory(
    storeId: storeId ?? p.storeId!,
    canonicalProductId: p.canonicalId,
    skuId: p.id,
    pack: p.pack,
    variant: p.variant,
    sourceRevision: 'published-price-history-1',
    currency: 'INR',
    offerId: p.procurementSupplierGrant?.offerId,
    previousSellingPriceMinor: 8000,
    currentSellingPriceMinor: p.price * 100,
    previousEffectiveAt: now.subtract(const Duration(days: 7)),
    currentEffectiveAt: now.subtract(const Duration(days: 1)),
    validUntil: expired
        ? now.subtract(const Duration(seconds: 1))
        : now.add(const Duration(days: 1)),
  );
}

final class _PricingContentAdapter implements BuyV2ProductContentAdapter {
  BuyV2ProductSizeChart? chart;
  BuyV2ProductPriceHistory? history;
  @override
  BuyV2ProductContentSnapshot snapshotFor(BuyV2Product p) {
    final base = const BuyV2CatalogueProductContentAdapter().snapshotFor(p);
    return BuyV2ProductContentSnapshot(
      productId: p.id,
      state: BuyV2ProductContentState.ready,
      sourceId: 'local-pricing-contract',
      media: base.media,
      sizeChart: chart,
      priceHistory: history,
    );
  }
}

final class _PricingTrustAdapter implements BuyV2MarketplaceTrustAdapter {
  const _PricingTrustAdapter({
    this.returnSummary,
    this.partnerLocation,
    this.partnerName,
  });
  final String? returnSummary;
  final String? partnerLocation;
  final String? partnerName;
  @override
  BuyV2MarketplaceTrustSnapshot snapshotFor(BuyV2Product p) =>
      BuyV2MarketplaceTrustSnapshot(
        productId: p.id,
        state: BuyV2MarketplaceTrustState.ready,
        sourceId: 'local-store-reputation-contract',
        returnSummary: returnSummary,
        partnerName: partnerName ?? p.seller,
        partnerType: p.sellerType,
        partnerLocation: partnerLocation,
        productRating: 4.2,
        productRatingCount: 17,
        partnerRating: 4.6,
        partnerOrderCount: 128,
        serviceReliabilityLabel: 'Confirmed dispatch record',
      );
}

final class _PricingFactsAdapter implements BuyV2ProductFactsAdapter {
  int? price;
  String? partner;
  String? orderability;
  final eligibilityByProduct = <String, BuyV2OfferEligibility>{};
  BuyV2OfferEligibility? eligibility;
  @override
  BuyV2ProductFactsSnapshot snapshotFor(BuyV2Product product) =>
      const BuyV2CatalogueProductFactsAdapter()
          .snapshotFor(product)
          .copyWith(
            price: price,
            partner: partner,
            eligibility: eligibilityByProduct[product.id] ?? eligibility,
            orderabilityLabel: orderability,
          );
}

final class _DiscoveryPagingSource extends BuyV2DevelopmentCatalogueSource {
  _DiscoveryPagingSource()
    : super(
        destination: BuyV2Destination.shop,
        providerCount: 1,
        skusPerStore: 90,
      );

  bool failNext = false;

  @override
  Future<BuyV2CataloguePage<BuyV2Product>> loadProducts(
    BuyV2CatalogueQuery query, {
    String? cursor,
    required int pageSize,
  }) {
    if (failNext && cursor != null) {
      throw StateError('Test source unavailable');
    }
    return super.loadProducts(query, cursor: cursor, pageSize: pageSize);
  }
}

final class _SingleProductCommerceAdapter implements BuyV2CommerceAdapter {
  _SingleProductCommerceAdapter(this.product);

  BuyV2Product product;
  List<BuyV2Product> extraProducts = [];
  BuyV2CommerceLoadState state = BuyV2CommerceLoadState.ready;

  @override
  Future<BuyV2CommerceSnapshot> refresh() async => BuyV2CommerceSnapshot(
    state: state,
    products: [product, ...extraProducts],
  );

  @override
  Future<BuyV2AddressRequestResult> createAddressRequest({
    String recipient = '',
  }) => throw UnsupportedError('Not used by this focused test.');

  @override
  Future<BuyV2OrderAlertsResult> loadOrderAlerts() async =>
      const BuyV2OrderAlertsResult(
        available: true,
        enabled: false,
        customerMessage: 'Order alerts are off',
      );

  @override
  Future<BuyV2OrderPlacementResult> placeOrder(
    BuyV2OrderPlacementRequest request,
  ) => throw UnsupportedError('Not used by this focused test.');

  @override
  Future<BuyV2OrderPlacementResult> reconcileOrder({
    required String idempotencyKey,
    required String paymentReference,
  }) => throw UnsupportedError('Not used by this focused test.');

  @override
  Future<BuyV2OrderRefreshResult> refreshOrder({required String orderId}) =>
      throw UnsupportedError('Not used by this focused test.');

  @override
  Future<BuyV2MutationResult> reportProduct({
    required BuyV2Product product,
    required String reason,
  }) => throw UnsupportedError('Not used by this focused test.');

  @override
  Future<BuyV2OrderAlertsResult> setOrderAlerts({required bool enabled}) =>
      throw UnsupportedError('Not used by this focused test.');

  @override
  Future<BuyV2MutationResult> submitProductReview({
    required BuyV2Product product,
    required int rating,
    required String comment,
  }) => throw UnsupportedError('Not used by this focused test.');
}

final class _ReferenceMediaAdapter implements BuyV2ProductContentAdapter {
  int revision = 0;
  int count = 2;
  bool failed = false;

  @override
  BuyV2ProductContentSnapshot snapshotFor(
    BuyV2Product product,
  ) => BuyV2ProductContentSnapshot(
    productId: product.id,
    state: BuyV2ProductContentState.ready,
    sourceId: 'local-provider-gallery-contract',
    media: [
      for (var index = 0; index < count; index++)
        BuyV2ProductMediaAsset(
          id: '${product.id}-r$revision-$index',
          label: 'Provider photo ${index + 1}',
          semanticLabel: '${product.id} provider photo ${index + 1}',
          kind: BuyV2ProductContentMediaKind.asset,
          source: failed
              ? 'assets/test-missing-product-photo.png'
              : index == 0
              ? 'assets/prototype/moolsocial-product-packshot-atlas-v2-2026.png'
              : 'assets/prototype/social-market-grocery.png',
        ),
    ],
  );
}

final class _ContentAdapter implements BuyV2ProductContentAdapter {
  bool available = true;
  BuyV2ProductContentState state = BuyV2ProductContentState.ready;
  bool retryable = false;
  String? message = 'Product information could not be loaded.';
  List<String> highlights = const [
    'Cold-chain quality checked',
    'Sealed pouch',
  ];
  DateTime? observedAt;
  String? productId;
  String description = 'Fresh toned milk supplied in a sealed pouch.';
  bool omitDescription = false;
  List<BuyV2ProductSpecification> highlightFields = const [];
  List<BuyV2ProductSpecification> specifications = const [
    BuyV2ProductSpecification(label: 'Shelf life', value: '2 days'),
    BuyV2ProductSpecification(label: 'Processing', value: 'Pasteurized'),
  ];

  @override
  BuyV2ProductContentSnapshot snapshotFor(BuyV2Product product) {
    if (!available || state != BuyV2ProductContentState.ready) {
      return BuyV2ProductContentSnapshot(
        productId: productId ?? product.id,
        state: available ? state : BuyV2ProductContentState.offline,
        sourceId: 'product-content-test',
        customerMessage: message,
        retryable: retryable,
      );
    }
    return BuyV2ProductContentSnapshot(
      productId: productId ?? product.id,
      state: BuyV2ProductContentState.ready,
      sourceId: 'product-content-test',
      observedAt: observedAt,
      highlightFields: highlightFields,
      media: [
        for (final id in const ['front', 'pack'])
          BuyV2ProductMediaAsset(
            id: '${product.id}-$id',
            label: id == 'front' ? 'Front of pack' : 'Pack details',
            semanticLabel:
                '${product.title}, ${id == 'front' ? 'front of pack' : 'pack details'}',
            kind: BuyV2ProductContentMediaKind.cataloguePackshot,
          ),
      ],
      highlights: highlights,
      specifications: specifications,
      description: omitDescription ? null : description,
    );
  }
}

final class _VideoContentAdapter implements BuyV2ProductContentAdapter {
  const _VideoContentAdapter();

  @override
  BuyV2ProductContentSnapshot snapshotFor(
    BuyV2Product product,
  ) => BuyV2ProductContentSnapshot(
    productId: product.id,
    state: BuyV2ProductContentState.ready,
    sourceId: 'firebase-product-media-contract-test',
    media: [
      BuyV2ProductMediaAsset(
        id: '${product.id}-video',
        label: 'See the sealed pack',
        semanticLabel: '${product.title} sealed-pack product video',
        kind: BuyV2ProductContentMediaKind.networkVideo,
        source: 'pending-firebase-product-video',
        transcript:
            'The video shows the sealed milk pouch from the front and back.',
      ),
    ],
  );
}

class _HelpStoreLabelSession extends BuyV2Session {
  _HelpStoreLabelSession({required super.core});
  @override
  List<BuyV2Order> get orders => const [
    BuyV2Order(
      id: 'HELP-LABEL',
      destination: BuyV2Destination.shop,
      title: 'Shop order',
      itemSummary: '1 product',
      total: 37,
      partner: 'Mool Market 000001',
      partnerType: 'Store',
      promise: 'Awaiting delivery',
      destinationLabel: 'Home',
      progress: .4,
      status: BuyV2OrderStatus.preparing,
      productIds: ['buy-catalogue-dev-v1-shop-store-000001-sku-0001'],
    ),
  ];
}
