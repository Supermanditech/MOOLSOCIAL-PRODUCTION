import 'dart:async';
import 'dart:io';
import 'dart:ui' show SemanticsAction, ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_cart_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_catalogue.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_chat_route_adapter.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_invoice.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_scanner.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_views.dart';
import 'package:moolsocial/ui_v2/profile/global_help_support_v2.dart';
import 'package:moolsocial/ui_v2/profile/global_privacy_preferences_v2.dart';
import 'package:moolsocial/ui_v2/profile/global_security_v2.dart';

class _R5ScreenArrivalSound implements BuyV2DeliveryArrivalSound {
  @override
  Future<bool> prepare() async => true;
  @override
  Future<bool> play() async => true;
  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {}
}

Widget r66VisualCaptureRoot(Widget child) =>
    const bool.fromEnvironment('BUY_R663_VISUAL_CAPTURE')
    ? RepaintBoundary(key: const ValueKey('r66-cart-capture'), child: child)
    : child;

Future<void> captureR66Visual(WidgetTester tester, String label) async {
  if (!const bool.fromEnvironment('BUY_R663_VISUAL_CAPTURE')) return;
  // Real asset decoding runs outside the widget test's fake clock. Wait for
  // the mounted assets, then settle their existing decoded-frame transitions.
  final images = find.byType(Image).evaluate().toList();
  await tester.runAsync(() async {
    for (final element in images) {
      if (!element.mounted) continue;
      final provider = (element.widget as Image).image;
      ImageProvider source = provider;
      while (source is ResizeImage) {
        source = source.imageProvider;
      }
      if (source is! AssetImage) continue;
      Object? decodeError;
      await precacheImage(
        provider,
        element,
        onError: (error, stack) {
          decodeError = error;
        },
      );
      if (decodeError != null) throw StateError('Asset decode: $decodeError');
    }
  });
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('r66-cart-capture')),
  );
  await tester.runAsync(() async {
    final directory = Directory(
      const String.fromEnvironment(
        'BUY_R663_VISUAL_DIRECTORY',
        defaultValue: 'build/r66-3-local-visual-20260906',
      ),
    );
    await directory.create(recursive: true);
    final output = File('${directory.path}/$label.png');
    if (await output.exists()) {
      throw StateError('Visual capture already exists');
    }
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final bytes = await image.toByteData(format: ImageByteFormat.png);
      if (bytes == null) throw StateError('Visual capture encoding failed');
      await output.writeAsBytes(bytes.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

final _forbiddenBuyCopy = RegExp(
  r'\b(?:production|prototype|founder review|review build|sample|example|demo|'
  r'mock|placeholder|working note|internal plan|implementation|workflow|'
  r'state machine|endpoint|payload|backend|provider callback|next screen|'
  r'for (?:review|testing)|source route|product compliance|'
  r'fulfiller assigned|route owner|internal identifier|'
  r'debug build|ui review|source id|adapter|review data|not-connected|'
  r'invalid-details|connection-unavailable)\b',
  caseSensitive: false,
);

final class _FixedOffersSource implements BuyV2PublishedOffersSource {
  const _FixedOffersSource(this.publishedOffers);

  @override
  final List<BuyV2PublishedOffer> publishedOffers;
}

final class _LiveOffersSource implements BuyV2LivePublishedOffersSource {
  BuyV2PublishedOffersSnapshot snapshot;
  int calls = 0;

  _LiveOffersSource(this.snapshot);

  @override
  List<BuyV2PublishedOffer> get publishedOffers => snapshot.offers;

  @override
  Future<BuyV2PublishedOffersSnapshot> load() async {
    calls += 1;
    return snapshot;
  }
}

final class _FixedDeliveryPromiseFactsAdapter
    implements BuyV2ProductFactsAdapter {
  const _FixedDeliveryPromiseFactsAdapter(this.deliveryPromise);

  final String deliveryPromise;

  @override
  BuyV2ProductFactsSnapshot snapshotFor(BuyV2Product product) {
    return const BuyV2CatalogueProductFactsAdapter()
        .snapshotFor(product)
        .copyWith(
          deliveryPromise: deliveryPromise,
          orderabilityLabel: 'Available to add',
          sourceId: 'b01-t02-server-assignment',
          stale: false,
        );
  }
}

final class _StoreStatusFactsAdapter implements BuyV2ProductFactsAdapter {
  const _StoreStatusFactsAdapter({required this.state, this.nextOpeningLabel});

  final BuyV2StoreOperatingState state;
  final String? nextOpeningLabel;

  @override
  BuyV2ProductFactsSnapshot snapshotFor(BuyV2Product product) {
    return const BuyV2CatalogueProductFactsAdapter()
        .snapshotFor(product)
        .copyWith(
          storeOperatingState: product.destination == BuyV2Destination.shop
              ? state
              : BuyV2StoreOperatingState.unknown,
          nextOpeningLabel: nextOpeningLabel,
        );
  }
}

final class _T01CMutableDeliveryFactsAdapter
    implements BuyV2ProductFactsAdapter {
  final promises = <BuyV2Destination, (String, String)>{
    BuyV2Destination.shop: ('within 5 min', 'by 6:35 PM'),
    BuyV2Destination.wholesale: ('within 1 day', 'by tomorrow 4:00 PM'),
  };

  void updateShop({required String promise, required String promisedBy}) {
    promises[BuyV2Destination.shop] = (promise, promisedBy);
  }

  @override
  BuyV2ProductFactsSnapshot snapshotFor(BuyV2Product product) {
    final quote = promises[product.destination];
    return const BuyV2CatalogueProductFactsAdapter()
        .snapshotFor(product)
        .copyWith(
          deliveryPromise: quote?.$1 ?? product.deliveryPromise,
          promisedByLabel: quote?.$2,
          sourceId: 'b01-t01c-ui-quote',
        );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Finder scrollableWithin(Key ownerKey) => find.descendant(
    of: find.byKey(ownerKey),
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable &&
          (widget.axisDirection == AxisDirection.down ||
              widget.axisDirection == AxisDirection.up),
    ),
  );

  Widget app(
    BuyV2Session session, {
    double textScale = 1,
    EdgeInsets safePadding = EdgeInsets.zero,
    bool disableAnimations = false,
    bool captureCart = false,
    BuyV2ScannerLauncher scannerLauncher = showBuyV2ProductScanner,
    BuyV2DeliveryArrivalSound? deliveryArrivalSound,
    VoidCallback? onOpenMool,
    VoidCallback? onOpenChat,
    BuyV2InvoiceDownloader? invoiceDownloader,
    AuthenticatedAccountIdentity? accountIdentity,
    bool accountAuthenticated = false,
    BuyV2PublishedOffersSource offersSource =
        const BuyV2CataloguePublishedOffersSource(),
  }) {
    return MaterialApp(
      theme: MoolTheme.light(),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(textScale),
            padding: safePadding,
            viewPadding: safePadding,
            disableAnimations: disableAnimations,
          ),
          child: captureCart
              ? RepaintBoundary(
                  key: const ValueKey('r66-cart-capture'),
                  child: child!,
                )
              : r66VisualCaptureRoot(child!),
        );
      },
      home: BuyV2Screen(
        session: session,
        accountIdentity: accountIdentity,
        accountAuthenticated: accountAuthenticated,
        scannerLauncher: scannerLauncher,
        deliveryArrivalSound: deliveryArrivalSound,
        onOpenMool: onOpenMool,
        onOpenChat: onOpenChat,
        invoiceDownloader: invoiceDownloader,
        offersSource: offersSource,
        onOpenMainAction: (action) {
          final uri = Uri.parse(action.route);
          if (uri.path != '/app/buy') return;
          switch (uri.queryParameters['sub']) {
            case 'wholesale':
              session.openDestination(BuyV2Destination.wholesale);
              return;
            case 'medicine':
              session.openDestination(BuyV2Destination.medicine);
              return;
            case 'orders':
              session.openOrders();
              return;
            default:
              session.openDestination(BuyV2Destination.shop);
              return;
          }
        },
      ),
    );
  }

  Future<void> captureReadability(WidgetTester tester, String label) async {
    if (!const bool.fromEnvironment('BUY_R663_VISUAL_CAPTURE')) return;
    final root = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('r66-cart-capture')),
    );
    void repaint(RenderObject object) {
      object.markNeedsPaint();
      object.visitChildren(repaint);
    }

    final previous = debugDisableShadows;
    debugDisableShadows = false;
    try {
      repaint(root);
      await captureR66Visual(tester, label);
    } finally {
      debugDisableShadows = previous;
      repaint(root);
      await tester.pump();
    }
  }

  void expectReadable(
    WidgetTester tester,
    Finder label, {
    Finder? action,
    bool wholeWords = false,
  }) {
    expect(label, findsOneWidget);
    final paragraph = tester.renderObject<RenderParagraph>(label);
    final text = paragraph.text.toPlainText();
    final natural = TextPainter(
      text: paragraph.text,
      textDirection: paragraph.textDirection,
      textScaler: paragraph.textScaler,
    )..layout(maxWidth: paragraph.size.width);
    expect(paragraph.didExceedMaxLines, isFalse, reason: text);
    expect(
      paragraph.size.height + .5,
      greaterThanOrEqualTo(natural.height),
      reason: text,
    );
    natural.dispose();
    if (wholeWords) {
      for (final match in RegExp(r'\S+').allMatches(text)) {
        final word = match.group(0)!;
        final wordBoxes = paragraph.getBoxesForSelection(
          TextSelection(baseOffset: match.start, extentOffset: match.end),
        );
        expect(
          wordBoxes.map((box) => box.top).toSet(),
          hasLength(1),
          reason: 'Painted word $word stays on one line in $text',
        );
        final measured = TextPainter(
          text: TextSpan(text: word, style: paragraph.text.style),
          textDirection: paragraph.textDirection,
          textScaler: paragraph.textScaler,
        )..layout();
        expect(
          measured.width,
          lessThanOrEqualTo(paragraph.size.width + .5),
          reason: 'Whole word $word in $text',
        );
        measured.dispose();
      }
    }
    if (action != null) {
      final bounds = tester.getRect(action);
      final content = tester.getRect(label);
      expect(content.top, greaterThanOrEqualTo(bounds.top - .5), reason: text);
      expect(
        content.bottom,
        lessThanOrEqualTo(bounds.bottom + .5),
        reason: text,
      );
      expect(bounds.height, greaterThanOrEqualTo(44));
      expect(action.hitTestable(), findsOneWidget);
    }
  }

  for (final size in [const Size(320, 844), const Size(640, 360)]) {
    for (final scale in [1.0, 2.0]) {
      final label = '${size.width.toInt()}x${size.height.toInt()}-$scale';
      for (final delivered in [false, true]) {
        testWidgets('R5 readability tracking $delivered $label', (
          tester,
        ) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          addTearDown(tester.view.reset);
          final core = BuySession();
          final session = BuyV2Session(core: core);
          addTearDown(core.dispose);
          addTearDown(session.dispose);
          session.addProduct('s-milk');
          final originalTotal = session.cartTotal;
          await tester.pumpWidget(
            app(
              session,
              textScale: scale,
              safePadding: const EdgeInsets.only(top: 24, bottom: 34),
              disableAnimations: true,
            ),
          );
          await tester.pumpAndSettle();
          final order = session.orders.firstWhere(
            (candidate) =>
                candidate.destination == BuyV2Destination.shop &&
                (candidate.status == BuyV2OrderStatus.delivered) == delivered,
          );
          expect(session.openTracking(order.id), isTrue);
          await tester.pumpAndSettle();
          final tracking = find.byKey(
            PageStorageKey('buy-tracking-${order.id}'),
          );
          final scroll = scrollableWithin(
            PageStorageKey('buy-tracking-${order.id}'),
          ).first;
          final address = find.byKey(const ValueKey('buy-tracking-address'));
          await tester.scrollUntilVisible(address, 160, scrollable: scroll);
          await Scrollable.ensureVisible(
            tester.element(address),
            alignment: .5,
          );
          await tester.pumpAndSettle();
          expectReadable(
            tester,
            find.descendant(of: address, matching: find.text('Address')),
            action: address,
            wholeWords: true,
          );
          await captureReadability(
            tester,
            'r5-readable-tracking-$delivered-$label-actions',
          );
          await tester.tap(address);
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('buy-order-delivery-sheet')),
            findsOneWidget,
          );
          expect(session.selectedOrderId, order.id);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.tracking);
          final items = find.descendant(
            of: tracking,
            matching: find.text('Items'),
          );
          await Scrollable.ensureVisible(tester.element(items), alignment: .5);
          await tester.pumpAndSettle();
          expectReadable(tester, items, wholeWords: true);
          await tester.tap(items);
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.orderItems);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(session.selectedOrderId, order.id);
          final manage = find.byKey(
            ValueKey('buy-tracking-manage-order-${order.id}'),
          );
          await tester.scrollUntilVisible(manage, 160, scrollable: scroll);
          await Scrollable.ensureVisible(tester.element(manage), alignment: .5);
          await tester.pumpAndSettle();
          expectReadable(
            tester,
            find.descendant(
              of: manage,
              matching: find.text(
                delivered ? 'Return, replace or refund' : 'Manage order',
              ),
            ),
            action: manage,
            wholeWords: true,
          );
          await captureReadability(
            tester,
            'r5-readable-tracking-$delivered-$label-manage',
          );
          await tester.tap(manage);
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('buy-order-resolution-sheet')),
            findsOneWidget,
          );
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.tracking);
          expect(session.selectedOrderId, order.id);
          expect(session.quantityFor('s-milk'), 1);
          expect(session.cartTotal, originalTotal);
          expect(tester.takeException(), isNull);
        });
      }

      for (final id in ['s-milk', 'w-oil-10l', 'm-paracetamol-500']) {
        testWidgets('R5 readability cart $id $label', (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          addTearDown(tester.view.reset);
          final core = BuySession();
          final session = BuyV2Session(core: core);
          addTearDown(core.dispose);
          addTearDown(session.dispose);
          await tester.pumpWidget(
            app(
              session,
              textScale: scale,
              safePadding: const EdgeInsets.only(top: 24, bottom: 34),
              disableAnimations: true,
            ),
          );
          await tester.pumpAndSettle();
          session.addProduct(id);
          session.openCart();
          await tester.pumpAndSettle();
          final product = session.product(id);
          final total = session.cartTotal;
          final quantity = session.quantityFor(id);
          final summary = find.byKey(ValueKey('buy-cart-product-summary-$id'));
          final fields = find.descendant(
            of: summary,
            matching: find.byType(Text),
          );
          expect(fields, findsWidgets);
          for (final field in fields.evaluate().toList()) {
            final target = find.byWidget(field.widget);
            await Scrollable.ensureVisible(field, alignment: .5);
            await tester.pumpAndSettle();
            expectReadable(tester, target, wholeWords: true);
          }
          final detail = find.descendant(
            of: summary,
            matching: find.text('${product.variant} · ${product.pack}'),
          );
          await Scrollable.ensureVisible(tester.element(detail), alignment: .5);
          await tester.pumpAndSettle();
          await captureReadability(
            tester,
            'r5-readable-cart-$id-$label-detail',
          );
          final promise = fields.last;
          await Scrollable.ensureVisible(
            tester.element(promise),
            alignment: .5,
          );
          await tester.pumpAndSettle();
          expect(promise.hitTestable(), findsOneWidget);
          await captureReadability(
            tester,
            'r5-readable-cart-$id-$label-promise',
          );
          await tester.tap(promise);
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.product);
          expect(session.selectedProductId, id);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.cart);
          expect(session.quantityFor(id), quantity);
          expect(session.cartTotal, total);
          expect(tester.takeException(), isNull);
        });
      }

      testWidgets('R5 readability prescription $label', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.reset);
        final core = BuySession();
        final session = BuyV2Session(core: core);
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        await tester.pumpWidget(
          app(
            session,
            textScale: scale,
            safePadding: const EdgeInsets.only(top: 24, bottom: 34),
            disableAnimations: true,
          ),
        );
        await tester.pumpAndSettle();
        session.openDestination(BuyV2Destination.medicine);
        session.submitSearch('Metformin');
        await tester.pumpAndSettle();
        final action = find.byKey(const ValueKey('buy-add-m-metformin-500'));
        await Scrollable.ensureVisible(tester.element(action), alignment: .5);
        await tester.pumpAndSettle();
        expect(action.hitTestable(), findsOneWidget);
        await tester.tap(action);
        await tester.pumpAndSettle();
        final title = find.byKey(
          const ValueKey('buy-prescription-sheet-title'),
        );
        expectReadable(tester, title, wholeWords: true);
        final close = find.byKey(const ValueKey('buy-prescription-close'));
        expect(close.hitTestable(), findsOneWidget);
        expect(tester.getSize(close).height, greaterThanOrEqualTo(44));
        await captureReadability(
          tester,
          'r5-readable-prescription-$label-heading',
        );
        final explanation = find.textContaining(
          'Pharmacist review is still required before payment.',
        );
        await Scrollable.ensureVisible(
          tester.element(explanation),
          alignment: .5,
        );
        await tester.pumpAndSettle();
        expectReadable(tester, explanation);
        await captureReadability(
          tester,
          'r5-readable-prescription-$label-explanation',
        );
        if (scale == 2) {
          await tester.binding.handlePopRoute();
        } else {
          await Scrollable.ensureVisible(tester.element(close), alignment: .5);
          await tester.pumpAndSettle();
          await tester.tap(close);
        }
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('buy-prescription-sheet-route')),
          findsNothing,
        );
        expect(session.prescriptionAttached, isFalse);
        expect(session.quantityFor('m-metformin-500'), 0);
        expect(session.destination, BuyV2Destination.medicine);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final owner in ['hint', 'history']) {
    testWidgets('R5 search 029A enlarged $owner is fully painted', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      session.submitSearch('tomato');
      session.updateQuery('');
      await tester.pumpWidget(app(session, textScale: 2));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-search-control')));
      await tester.pumpAndSettle();
      final field = find.byKey(const ValueKey('buy-search-field'));
      final text = owner == 'hint'
          ? tester.widget<TextField>(field).decoration!.hintText!
          : 'Recent searches';
      final paintedText = find.byWidgetPredicate(
        (widget) => widget is RichText && widget.text.toPlainText() == text,
      );
      expect(paintedText, findsOneWidget);
      final paragraph = tester.renderObject<RenderParagraph>(paintedText);
      final painter = TextPainter(
        text: paragraph.text,
        textDirection: paragraph.textDirection,
        textScaler: paragraph.textScaler,
        locale: paragraph.locale,
        textHeightBehavior: paragraph.textHeightBehavior,
      )..layout(maxWidth: paragraph.size.width);
      final requiredHeight = painter.height;
      painter.dispose();
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(
        paragraph.size.height + .1,
        greaterThanOrEqualTo(requiredHeight),
        reason: '$owner must paint every line at the actual Inter text scale',
      );
      final textRect = tester.getRect(paintedText);
      if (owner == 'history') {
        expect(
          textRect.bottom,
          lessThanOrEqualTo(
            tester
                .getRect(find.byKey(const ValueKey('buy-recent-search-0')))
                .top,
          ),
          reason: 'History heading cannot overlap the first search row',
        );
      } else {
        expect(tester.getRect(field).contains(textRect.topLeft), isTrue);
        expect(
          tester.getRect(field).bottom,
          greaterThanOrEqualTo(textRect.bottom),
        );
      }
      expect(tester.takeException(), isNull);
    });
  }

  void expectSearchTextPainted(WidgetTester tester, Finder scope, String text) {
    final painted = find.descendant(
      of: scope,
      matching: find.byWidgetPredicate(
        (widget) => widget is RichText && widget.text.toPlainText() == text,
      ),
    );
    expect(painted, findsOneWidget);
    final paragraph = tester.renderObject<RenderParagraph>(painted);
    final painter = TextPainter(
      text: paragraph.text,
      textDirection: paragraph.textDirection,
      textScaler: paragraph.textScaler,
      locale: paragraph.locale,
      textHeightBehavior: paragraph.textHeightBehavior,
    )..layout(maxWidth: paragraph.size.width);
    final height = painter.height;
    painter.dispose();
    expect(paragraph.didExceedMaxLines, isFalse, reason: text);
    expect(
      paragraph.size.height + .1,
      greaterThanOrEqualTo(height),
      reason: text,
    );
    final bounds = tester.getRect(painted);
    final owner = tester.getRect(scope);
    expect(bounds.left + .1, greaterThanOrEqualTo(owner.left), reason: text);
    expect(bounds.right, lessThanOrEqualTo(owner.right + .1), reason: text);
    expect(bounds.top + .1, greaterThanOrEqualTo(owner.top), reason: text);
    expect(bounds.bottom, lessThanOrEqualTo(owner.bottom + .1), reason: text);
  }

  for (final size in [
    const Size(320, 780),
    const Size(360, 800),
    const Size(430, 932),
    const Size(640, 360),
  ]) {
    for (final scale in [1.0, 2.0]) {
      final label =
          '${size.width.toInt()}x${size.height.toInt()}-${scale.toInt()}';
      testWidgets('R5 search 029A keyboard and history actions $label', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        final core = BuySession();
        final session = BuyV2Session(core: core);
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        session.submitSearch('tomato');
        session.submitSearch('milk');
        session.updateQuery('');
        await tester.pumpWidget(
          app(
            session,
            textScale: scale,
            safePadding: const EdgeInsets.only(top: 24, bottom: 24),
          ),
        );
        await tester.pumpAndSettle();
        final control = find.byKey(const ValueKey('buy-search-control'));
        final field = find.byKey(const ValueKey('buy-search-field'));
        final history = find.byKey(
          const ValueKey('buy-search-suggestion-list'),
        );
        final finish = find.byKey(const ValueKey('buy-search-close'));
        final clear = find.byKey(const ValueKey('buy-search-clear'));
        final recentClear = find.byKey(
          const ValueKey('buy-recent-searches-clear'),
        );
        final firstRecent = find.byKey(const ValueKey('buy-recent-search-0'));
        final restingText = tester
            .widget<Text>(
              find.descendant(of: control, matching: find.byType(Text)),
            )
            .data!;
        expectSearchTextPainted(tester, control, restingText);
        await captureR66Visual(tester, 'r5-search-$label-closed');
        await tester.tap(control);
        await tester.pumpAndSettle();
        void expectBlankSearch() {
          expectSearchTextPainted(
            tester,
            field,
            tester.widget<TextField>(field).decoration!.hintText!,
          );
          expectSearchTextPainted(tester, history, 'Recent searches');
          expect(
            tester.getRect(find.text('Recent searches')).bottom,
            lessThanOrEqualTo(tester.getRect(firstRecent).top),
          );
          for (final action in [finish, recentClear, firstRecent]) {
            expect(tester.getSize(action).height, greaterThanOrEqualTo(44));
            expect(tester.getSize(action).width, greaterThanOrEqualTo(44));
          }
        }

        expectBlankSearch();
        await captureR66Visual(tester, 'r5-search-$label-history');
        final keyboardHeight = size.height < 400 ? 140.0 : 260.0;
        tester.view.viewInsets = FakeViewPadding(bottom: keyboardHeight);
        await tester.pumpAndSettle();
        expectBlankSearch();
        expect(
          tester.getRect(field).bottom,
          lessThanOrEqualTo(size.height - keyboardHeight),
        );
        await captureR66Visual(tester, 'r5-search-$label-keyboard-inset');
        await tester.ensureVisible(firstRecent);
        await tester.pumpAndSettle();
        await tester.tap(firstRecent);
        await tester.pumpAndSettle();
        expect(session.query, 'milk');
        if (size.width > size.height) {
          // The landscape catalogue scrolls its header to give results space.
          // Bring the same mounted field back before editing the next query.
          final mountedField = find.byKey(
            const ValueKey('buy-search-field'),
            skipOffstage: false,
          );
          expect(mountedField, findsOneWidget);
          await tester.ensureVisible(mountedField);
          await tester.pumpAndSettle();
        }
        expect(tester.widget<TextField>(field).controller!.text, 'milk');
        await tester.tap(clear);
        await tester.pumpAndSettle();
        await tester.tap(recentClear);
        await tester.pumpAndSettle();
        expect(session.recentSearchesFor(BuyV2Destination.shop), isEmpty);
        expect(find.text('Recent searches'), findsNothing);
        await captureR66Visual(tester, 'r5-search-$label-empty-history');
        await tester.enterText(field, 'tomato');
        await tester.pumpAndSettle();
        expect(session.visibleProducts, isNotEmpty);
        await tester.tap(finish);
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        expect(session.query, 'tomato');
        expect(
          session.recentSearchesFor(BuyV2Destination.shop).first,
          'tomato',
        );
        expect(field, findsNothing);
        await captureR66Visual(tester, 'r5-search-$label-results');
        await tester.tap(control);
        await tester.pumpAndSettle();
        await tester.tap(clear);
        await tester.pumpAndSettle();
        await tester.tap(finish);
        await tester.pumpAndSettle();
        expect(session.query, isEmpty);
        expect(session.itemCount, 0);
        for (final destination in BuyV2Destination.values) {
          session.openDestination(destination);
          await tester.pumpAndSettle();
          final hint = tester
              .widget<Text>(
                find.descendant(of: control, matching: find.byType(Text)),
              )
              .data!;
          expectSearchTextPainted(tester, control, hint);
          await tester.tap(control);
          await tester.pumpAndSettle();
          expectSearchTextPainted(
            tester,
            field,
            tester.widget<TextField>(field).decoration!.hintText!,
          );
          if (destination != BuyV2Destination.shop) {
            await captureR66Visual(
              tester,
              'r5-search-$label-${destination.name}',
            );
          }
          await tester.tap(finish);
          await tester.pumpAndSettle();
        }
        await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers')));
        await tester.pumpAndSettle();
        await tester.tap(control);
        await tester.pumpAndSettle();
        expectSearchTextPainted(
          tester,
          field,
          tester.widget<TextField>(field).decoration!.hintText!,
        );
        await captureR66Visual(tester, 'r5-search-$label-offers');
        expect(find.byKey(const ValueKey('buy-open-scanner')), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('R5 search submit and Back preserve both carts $scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      final shop = session.visibleProducts.first;
      expect(session.addProduct(shop.id), isTrue);
      expect(session.addProduct('w-notebook'), isTrue);
      final quantities = (
        session.quantityFor(shop.id),
        session.quantityFor('w-notebook'),
      );
      final totals = (
        session.totalForDestination(BuyV2Destination.shop),
        session.totalForDestination(BuyV2Destination.wholesale),
      );
      session.clearNotice();
      session.clearCartAcknowledgement();
      await tester.pumpWidget(app(session, textScale: scale));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-search-control')));
      await tester.pumpAndSettle();
      final field = find.byKey(const ValueKey('buy-search-field'));
      await tester.enterText(field, 'tomato');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(session.query, 'tomato');
      expect(session.recentSearchesFor(BuyV2Destination.shop).first, 'tomato');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(field, findsNothing);
      expect(session.query, 'tomato');
      expect(session.view, BuyV2View.catalogue);
      expect((
        session.quantityFor(shop.id),
        session.quantityFor('w-notebook'),
      ), quantities);
      expect((
        session.totalForDestination(BuyV2Destination.shop),
        session.totalForDestination(BuyV2Destination.wholesale),
      ), totals);
      expect(find.byKey(const ValueKey('buy-open-scanner')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  Future<void> revealPurchaseTarget(
    WidgetTester tester,
    Finder target, {
    bool towardStart = false,
  }) async {
    if (target.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        target,
        towardStart ? -180 : 180,
        scrollable: find
            .byWidgetPredicate(
              (widget) =>
                  widget is Scrollable &&
                  (widget.axisDirection == AxisDirection.down ||
                      widget.axisDirection == AxisDirection.up),
            )
            .first,
        maxScrolls: 30,
      );
    }
    expect(target, findsOneWidget);
    await Scrollable.ensureVisible(tester.element(target), alignment: .35);
    await tester.pumpAndSettle();
    expect(
      target.hitTestable(),
      findsOneWidget,
      reason: 'Purchase target bounds: ${tester.getRect(target)}',
    );
  }

  for (final size in [const Size(320, 844), const Size(640, 360)]) {
    for (final scale in [1.0, 2.0]) {
      final profile = '${size.width.toInt()}x${size.height.toInt()}-$scale';
      testWidgets('R5 purchase decisions payment recovery $profile', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.reset);
        final core = BuySession();
        final session = BuyV2Session(core: core);
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        await tester.pumpWidget(
          app(
            session,
            textScale: scale,
            safePadding: const EdgeInsets.only(top: 24, bottom: 34),
            disableAnimations: true,
          ),
        );
        await tester.pumpAndSettle();
        session.addProduct('s-milk');
        session.addProduct('w-rice-50kg');
        session.openCart(scope: BuyV2CartScope.wholesale);
        expect(session.openCheckout(), isTrue);
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('buy-checkout-primary-address')),
        );
        await tester.pumpAndSettle();
        final phonePe = find.byKey(const ValueKey('buy-payment-PhonePe'));
        await revealPurchaseTarget(tester, phonePe);
        await tester.tap(phonePe);
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('buy-checkout-primary-payment')),
        );
        await tester.pumpAndSettle();
        expect(session.checkoutStep, BuyV2CheckoutStep.confirm);
        await tester.tap(
          find.byKey(const ValueKey('buy-checkout-primary-confirm')),
        );
        await tester.pumpAndSettle();
        expect(
          session.checkoutSubmissionState,
          BuyV2CheckoutSubmissionState.paymentActionRequired,
        );
        final reference = session.paymentReference;
        final attempt = session.checkoutIdempotencyKey;
        final state = find.byKey(
          const ValueKey('buy-checkout-payment-state-paymentActionRequired'),
        );
        final heading = find.descendant(
          of: state,
          matching: find.text('Payment unavailable right now'),
        );
        final explanation = find.descendant(
          of: state,
          matching: find.text(
            'Try again later, or cancel to choose another method.',
          ),
        );
        for (final field in [heading, explanation]) {
          await revealPurchaseTarget(tester, field);
          expectReadable(tester, field, wholeWords: true);
        }
        await revealPurchaseTarget(tester, heading);
        await captureReadability(
          tester,
          'r5-decision-payment-$profile-heading',
        );
        final primary = find.byKey(
          const ValueKey('buy-checkout-primary-payment'),
        );
        expect(tester.widget<FilledButton>(primary).onPressed, isNull);
        expect(find.byKey(const ValueKey('buy-live-notice')), findsNothing);
        expect(session.paymentReference, reference);
        expect(session.checkoutIdempotencyKey, attempt);
        expect(session.confirmedOrders, isEmpty);
        final cancel = find.byKey(
          const ValueKey('buy-checkout-cancel-payment'),
        );
        await revealPurchaseTarget(tester, cancel);
        expectReadable(
          tester,
          find.descendant(of: cancel, matching: find.text('Cancel')),
          action: cancel,
          wholeWords: true,
        );
        await captureReadability(tester, 'r5-decision-payment-$profile-cancel');
        await tester.tap(cancel);
        await tester.pumpAndSettle();
        expect(
          session.checkoutSubmissionState,
          BuyV2CheckoutSubmissionState.cancelled,
        );
        final cancelled = find.text('Payment cancelled');
        await revealPurchaseTarget(tester, cancelled);
        expectReadable(tester, cancelled, wholeWords: true);
        await captureReadability(
          tester,
          'r5-decision-payment-$profile-cancelled',
        );
        await tester.tap(primary);
        await tester.pumpAndSettle();
        expect(
          session.checkoutSubmissionState,
          BuyV2CheckoutSubmissionState.idle,
        );
        final back = find.byKey(const ValueKey('buy-checkout-back'));
        await revealPurchaseTarget(tester, back, towardStart: true);
        await tester.tap(back);
        await tester.pumpAndSettle();
        expect(session.checkoutStep, BuyV2CheckoutStep.address);
        final cart = find.byKey(const ValueKey('buy-checkout-return-cart'));
        await revealPurchaseTarget(tester, cart, towardStart: true);
        await tester.tap(cart);
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.cart);
        expect(session.cartScope, BuyV2CartScope.wholesale);
        expect(session.scopedCartTotal, 3200);
        expect(session.quantityFor('w-rice-50kg'), 1);
        expect(session.quantityFor('s-milk'), 1);
        expect(session.totalForDestination(BuyV2Destination.shop), 66);
        expect(session.confirmedOrders, isEmpty);
        expect(tester.takeException(), isNull);
      });

      testWidgets(
        'R5 purchase decisions full benefit terms and totals $profile',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          addTearDown(tester.view.reset);
          final core = BuySession();
          final session = BuyV2Session(
            core: core,
            cartBenefitsAdapter: const BuyV2SeededCartBenefitsAdapter(),
          );
          addTearDown(core.dispose);
          addTearDown(session.dispose);
          await tester.pumpWidget(
            app(
              session,
              textScale: scale,
              safePadding: const EdgeInsets.only(top: 24, bottom: 34),
              disableAnimations: true,
            ),
          );
          await tester.pumpAndSettle();
          session.addProduct('s-milk');
          session.addProduct('w-rice-50kg');
          session.openCart(scope: BuyV2CartScope.wholesale);
          await tester.pumpAndSettle();
          expect(session.scopedPayableTotal, 3200);
          for (final kind in BuyV2CartBenefitKind.values) {
            final entry = find.byKey(
              ValueKey(
                kind == BuyV2CartBenefitKind.coupon
                    ? 'buy-cart-coupons'
                    : 'buy-cart-payment-offers',
              ),
            );
            await revealPurchaseTarget(tester, entry);
            await tester.tap(entry);
            await tester.pumpAndSettle();
            final benefit = session
                .cartBenefits(
                  kind: kind,
                  destination: BuyV2Destination.wholesale,
                )
                .last;
            expect(benefit.savingAmount, 300);
            final card = find.byKey(ValueKey('buy-cart-benefit-${benefit.id}'));
            await revealPurchaseTarget(tester, card);
            final fields = find.descendant(
              of: card,
              matching: find.byType(Text),
            );
            final labels = fields
                .evaluate()
                .map((field) => (field.widget as Text).data!)
                .toList();
            for (final label in labels) {
              final target = find.descendant(
                of: card,
                matching: find.text(label),
              );
              await revealPurchaseTarget(tester, target);
              expectReadable(tester, target, wholeWords: true);
            }
            final title = find.descendant(
              of: card,
              matching: find.text(benefit.title),
            );
            await revealPurchaseTarget(tester, title);
            await captureReadability(
              tester,
              'r5-decision-${kind.name}-$profile-title',
            );
            final select = find.byKey(
              ValueKey('buy-cart-benefit-select-${benefit.id}'),
            );
            await revealPurchaseTarget(tester, select);
            await captureReadability(
              tester,
              'r5-decision-${kind.name}-$profile-terms',
            );
            await tester.tap(select);
            await tester.pumpAndSettle();
            expect(
              session
                  .selectedCartBenefit(
                    kind: kind,
                    destination: BuyV2Destination.wholesale,
                  )
                  ?.id,
              benefit.id,
            );
            expect(session.scopedPayableTotal, 2900);
            final remove = find.byKey(
              ValueKey('buy-cart-benefit-remove-${benefit.id}'),
            );
            await revealPurchaseTarget(tester, remove);
            expectReadable(
              tester,
              find.descendant(of: remove, matching: find.text('Remove')),
              action: remove,
              wholeWords: true,
            );
            final status = find.byKey(
              ValueKey('buy-cart-benefit-status-motion-${benefit.id}'),
            );
            final statusText = find.descendant(
              of: status,
              matching: find.byType(Text),
            );
            await revealPurchaseTarget(tester, statusText);
            expectReadable(tester, statusText, wholeWords: true);
            final statusBounds = tester.getRect(status);
            final textBounds = tester.getRect(statusText);
            expect(textBounds.top, greaterThanOrEqualTo(statusBounds.top - .5));
            expect(
              textBounds.bottom,
              lessThanOrEqualTo(statusBounds.bottom + .5),
            );
            await captureReadability(
              tester,
              'r5-decision-${kind.name}-$profile-selected',
            );
            if (kind == BuyV2CartBenefitKind.paymentOffer) {
              final pending = find.byKey(
                ValueKey('buy-payment-offer-selection-status-${benefit.id}'),
              );
              await revealPurchaseTarget(tester, pending);
              expectReadable(tester, pending, wholeWords: true);
              expect(
                tester.widget<Text>(pending).data,
                contains('not included'),
              );
              await revealPurchaseTarget(tester, remove);
              await tester.tap(remove);
              await tester.pumpAndSettle();
              expect(session.scopedPayableTotal, 2900);
            }
            await tester.tap(
              find.byKey(const ValueKey('buy-cart-benefit-completion')),
            );
            await tester.pumpAndSettle();
            expect(session.view, BuyV2View.cart);
            expect(session.cartScope, BuyV2CartScope.wholesale);
            expect(session.scopedPayableTotal, 2900);
          }
          final coupons = find.byKey(const ValueKey('buy-cart-coupons'));
          await revealPurchaseTarget(tester, coupons);
          await tester.tap(coupons);
          await tester.pumpAndSettle();
          final coupon = session.selectedCartBenefit(
            kind: BuyV2CartBenefitKind.coupon,
            destination: BuyV2Destination.wholesale,
          )!;
          final remove = find.byKey(
            ValueKey('buy-cart-benefit-remove-${coupon.id}'),
          );
          await revealPurchaseTarget(tester, remove);
          await tester.tap(remove);
          await tester.pumpAndSettle();
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(session.scopedPayableTotal, 3200);
          expect(session.quantityFor('w-rice-50kg'), 1);
          expect(session.quantityFor('s-milk'), 1);
          expect(session.totalForDestination(BuyV2Destination.shop), 66);
          expect(session.confirmedOrders, isEmpty);
          expect(tester.takeException(), isNull);
        },
      );

      for (final destination in [
        BuyV2Destination.shop,
        BuyV2Destination.wholesale,
      ]) {
        testWidgets(
          'R5 purchase decisions complete Saved notice ${destination.name} $profile',
          (tester) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = size;
            addTearDown(tester.view.reset);
            final core = BuySession();
            final session = BuyV2Session(core: core);
            addTearDown(core.dispose);
            addTearDown(session.dispose);
            await tester.pumpWidget(
              app(
                session,
                textScale: scale,
                safePadding: const EdgeInsets.only(top: 24, bottom: 34),
                disableAnimations: true,
              ),
            );
            await tester.pumpAndSettle();
            session.toggleSaved('s-milk');
            session.toggleSaved('w-rice-50kg');
            final other = destination == BuyV2Destination.shop
                ? BuyV2Destination.wholesale
                : BuyV2Destination.shop;
            final otherSavedIds = session
                .savedProductsFor(other)
                .map((product) => product.id)
                .toList(growable: false);
            session.addProduct('s-milk');
            session.addProduct('w-rice-50kg');
            session.openDestination(destination);
            session.clearNotice();
            await tester.pumpAndSettle();
            final saved = find.byKey(
              const ValueKey('buy-saved-products-button'),
            );
            await revealPurchaseTarget(tester, saved);
            await tester.tap(saved);
            await tester.pumpAndSettle();
            final clear = find.byKey(const ValueKey('buy-saved-clear'));
            await revealPurchaseTarget(tester, clear);
            await tester.tap(clear);
            await tester.pumpAndSettle();
            final confirm = find.byKey(
              const ValueKey('buy-saved-confirm-clear'),
            );
            await revealPurchaseTarget(tester, confirm);
            await tester.tap(confirm);
            await tester.pumpAndSettle();
            expect(session.savedCountFor(destination), 0);
            expect(
              session.savedProductsFor(other).map((product) => product.id),
              otherSavedIds,
            );
            final notice = find.byKey(const ValueKey('buy-live-notice'));
            final message = find.descendant(
              of: notice,
              matching: find.text(
                '${destination.label} Saved products cleared.',
              ),
            );
            expectReadable(tester, message, wholeWords: true);
            await captureReadability(
              tester,
              'r5-decision-notice-${destination.name}-$profile',
            );
            expect(session.quantityFor('s-milk'), 1);
            expect(session.quantityFor('w-rice-50kg'), 1);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  Future<void> expectBuySystemBarPaint(WidgetTester tester) async {
    final root = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('r66-cart-capture')),
    );
    await tester.runAsync(() async {
      final frame = await root.toImage(pixelRatio: 1);
      try {
        final bytes = await frame.toByteData(format: ImageByteFormat.rawRgba);
        expect(bytes, isNotNull);
        final rgba = bytes!;
        Color at(int x, int y) {
          final index = (y * frame.width + x) * 4;
          return Color.fromARGB(
            rgba.getUint8(index + 3),
            rgba.getUint8(index),
            rgba.getUint8(index + 1),
            rgba.getUint8(index + 2),
          );
        }

        for (final x in [4, frame.width ~/ 2, frame.width - 5]) {
          final top = at(x, 10);
          expect(top, BuyV2Colors.navy);
          expect(
            1.05 / (top.computeLuminance() + .05),
            greaterThanOrEqualTo(4.5),
          );
          final bottom = at(x, frame.height - 10);
          expect(
            (bottom.computeLuminance() + .05) / .05,
            greaterThanOrEqualTo(4.5),
          );
        }
      } finally {
        frame.dispose();
      }
    });
  }

  for (final size in [const Size(320, 844), const Size(640, 360)]) {
    for (final scale in [1.0, 2.0]) {
      final profile = '${size.width.toInt()}x${size.height.toInt()}-$scale';
      testWidgets('R5 system bars restore after global routes $profile', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        tester.view.padding = const FakeViewPadding(top: 24, bottom: 34);
        tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 34);
        addTearDown(tester.view.reset);
        final overlays = <Map<String, Object?>>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'SystemChrome.setSystemUIOverlayStyle') {
              overlays.add(Map<String, Object?>.from(call.arguments as Map));
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
        // Match the previously good Buy state before a light global page opens.
        // The return assertion must fail if Buy merely inherits that page's style.
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
        await tester.idle();
        final core = BuySession();
        final session = BuyV2Session(core: core);
        final journey = JourneySession(store: MemoryJourneyStore());
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        addTearDown(journey.dispose);
        session.addProduct('s-milk');
        session.addProduct('w-rice-50kg');
        session.openDestination(BuyV2Destination.wholesale);
        final orderIds = session.orders.map((order) => order.id).toList();
        final router = GoRouter(
          initialLocation: '/app/buy',
          routes: [
            GoRoute(
              path: '/app/buy',
              builder: (context, state) => BuyV2Screen(
                session: session,
                initialDestination: BuyV2Destination.wholesale,
                accountAuthenticated: true,
              ),
            ),
            GoRoute(
              path: '/app/account/workspaces/preferences',
              builder: (context, state) =>
                  GlobalPrivacyPreferencesV2(session: journey),
            ),
            GoRoute(
              path: '/app/account/security',
              builder: (context, state) => GlobalSecurityV2(session: journey),
            ),
            GoRoute(
              path: '/app/ask',
              builder: (context, state) =>
                  GlobalHelpSupportV2(session: journey),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          MaterialApp.router(
            theme: MoolTheme.light(),
            routerConfig: router,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                disableAnimations: true,
              ),
              child: RepaintBoundary(
                key: const ValueKey('r66-cart-capture'),
                child: child!,
              ),
            ),
          ),
        );
        addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
        final renderView = tester.binding.renderViews.single;
        final previousAdjustment = renderView.automaticSystemUiAdjustment;
        renderView.automaticSystemUiAdjustment = true;
        addTearDown(
          () => renderView.automaticSystemUiAdjustment = previousAdjustment,
        );
        await tester.pumpAndSettle();
        void expectIcons(Brightness brightness) {
          expect(overlays, isNotEmpty);
          expect(
            overlays.last['statusBarIconBrightness'],
            brightness.toString(),
            reason: 'Platform overlay after settled route: ${overlays.last}',
          );
        }

        for (final route in [
          (
            name: 'preferences',
            entry: 'global-profile-preferences',
            page: 'global-privacy-preferences-v2',
            back: 'global-preferences-back',
          ),
          (
            name: 'security',
            entry: 'global-profile-security',
            page: 'global-security-v2',
            back: 'global-security-back',
          ),
          (
            name: 'help',
            entry: 'buy-settings-help',
            page: 'global-help-support-v2',
            back: 'global-help-back',
          ),
        ]) {
          for (final platformBack in [false, true]) {
            final fromSettings = route.name == 'help';
            if (fromSettings) {
              final filters = find.byKey(const ValueKey('buy-filter-button'));
              await tester.ensureVisible(filters);
              await tester.pumpAndSettle();
              expect(filters.hitTestable(), findsOneWidget);
              await tester.tap(filters);
              await tester.pumpAndSettle();
              final tools = find.byKey(
                const ValueKey('buy-refine-section-tools'),
              );
              final refinementScroll = find.descendant(
                of: find.byKey(const ValueKey('buy-discovery-refinement-list')),
                matching: find.byType(Scrollable),
              );
              await tester.scrollUntilVisible(
                tools,
                160,
                scrollable: refinementScroll,
                maxScrolls: 30,
              );
              final heading = find
                  .descendant(of: tools, matching: find.byType(ListTile))
                  .first;
              await tester.ensureVisible(heading);
              await tester.pumpAndSettle();
              expect(heading.hitTestable(), findsOneWidget);
              await tester.tap(heading);
              await tester.pumpAndSettle();
              final settings = find.byKey(
                const ValueKey('buy-shopping-settings-button'),
              );
              await tester.scrollUntilVisible(
                settings,
                160,
                scrollable: refinementScroll,
                maxScrolls: 30,
              );
              await tester.ensureVisible(settings);
              await tester.pumpAndSettle();
              expect(settings.hitTestable(), findsOneWidget);
              await tester.tap(settings);
              await tester.pumpAndSettle();
              expect(
                find.byKey(const ValueKey('buy-shopping-settings')),
                findsOneWidget,
              );
            } else {
              final account = find.byKey(const ValueKey('buy-open-account'));
              await tester.ensureVisible(account);
              await tester.pumpAndSettle();
              expect(account.hitTestable(), findsOneWidget);
              await tester.tap(account);
              await tester.pumpAndSettle();
            }
            final entry = find.byKey(ValueKey(route.entry));
            await tester.scrollUntilVisible(
              entry,
              180,
              scrollable: find
                  .descendant(
                    of: find.byKey(
                      ValueKey(
                        fromSettings
                            ? 'buy-shopping-settings'
                            : 'global-profile-panel-v2',
                      ),
                    ),
                    matching: find.byType(Scrollable),
                  )
                  .first,
              maxScrolls: 30,
            );
            await tester.ensureVisible(entry);
            await tester.pumpAndSettle();
            expect(entry.hitTestable(), findsOneWidget);
            await tester.tap(entry);
            await tester.pumpAndSettle();
            expect(find.byKey(ValueKey(route.page)), findsOneWidget);
            expectIcons(Brightness.dark);
            if (!platformBack) {
              await captureReadability(
                tester,
                'r5-bars-${route.name}-$profile-open',
              );
            }
            if (platformBack) {
              await tester.binding.handlePopRoute();
            } else {
              final back = find.byKey(ValueKey(route.back));
              expect(back.hitTestable(), findsOneWidget);
              await tester.tap(back);
            }
            await tester.pumpAndSettle();
            expect(find.byKey(ValueKey(route.page)), findsNothing);
            expect(find.byKey(const ValueKey('buy-v2-screen')), findsOneWidget);
            expectIcons(Brightness.light);
            expect(session.destination, BuyV2Destination.wholesale);
            expect(session.view, BuyV2View.catalogue);
            expect(session.quantityFor('s-milk'), 1);
            expect(session.quantityFor('w-rice-50kg'), 1);
            expect(session.orders.map((order) => order.id), orderIds);
            if (!platformBack) {
              await captureReadability(
                tester,
                'r5-bars-${route.name}-$profile-return',
              );
            }
            if (fromSettings) {
              expect(
                find.byKey(const ValueKey('buy-shopping-settings')),
                findsOneWidget,
              );
              await tester.binding.handlePopRoute();
              await tester.pumpAndSettle();
              expect(
                find.byKey(const ValueKey('buy-shopping-settings')),
                findsNothing,
              );
              expectIcons(Brightness.light);
            }
          }
        }
        for (final destination in BuyV2Destination.values) {
          session.openDestination(destination);
          await tester.pumpAndSettle();
          expectIcons(Brightness.light);
          await expectBuySystemBarPaint(tester);
          await captureReadability(
            tester,
            'r5-bars-${destination.name}-$profile-paint',
          );
        }
        session.openDestination(BuyV2Destination.wholesale);
        await tester.pumpAndSettle();
        tester.view.physicalSize = Size(size.height, size.width);
        await tester.pumpAndSettle();
        expectIcons(Brightness.light);
        await expectBuySystemBarPaint(tester);
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        expectIcons(Brightness.light);
        expect(session.quantityFor('s-milk'), 1);
        expect(session.quantityFor('w-rice-50kg'), 1);
        expect(session.orders.map((order) => order.id), orderIds);
        expect(tester.takeException(), isNull);
      });
    }
  }

  Future<void> completeReviewPayment(
    WidgetTester tester,
    BuyV2Session session,
  ) async {
    expect(
      session.checkoutSubmissionState,
      BuyV2CheckoutSubmissionState.paymentActionRequired,
    );
    expect(await session.continuePayment((_) async => true), isTrue);
    await tester.pumpAndSettle();
    expect(
      session.checkoutSubmissionState,
      BuyV2CheckoutSubmissionState.paymentPending,
    );
    expect(await session.reconcilePayment(), isTrue);
    await tester.pumpAndSettle();
  }

  Future<void> advanceCheckoutToPayment(
    WidgetTester tester,
    BuyV2Session session,
  ) async {
    expect(session.checkoutStep, BuyV2CheckoutStep.address);
    await tester.tap(
      find.byKey(const ValueKey('buy-checkout-primary-address')),
    );
    await tester.pumpAndSettle();
    expect(session.checkoutStep, BuyV2CheckoutStep.payment);
    expect(
      find.byKey(const ValueKey('buy-checkout-payment-stage')),
      findsOneWidget,
    );
  }

  Future<void> advanceCheckoutToConfirm(
    WidgetTester tester,
    BuyV2Session session,
  ) async {
    await advanceCheckoutToPayment(tester, session);
    await tester.tap(
      find.byKey(const ValueKey('buy-checkout-primary-payment')),
    );
    await tester.pumpAndSettle();
    expect(session.checkoutStep, BuyV2CheckoutStep.confirm);
    expect(
      find.byKey(const ValueKey('buy-checkout-confirm-stage')),
      findsOneWidget,
    );
  }

  test('payment handoff provider labels preserve customer brand casing', () {
    expect(
      buyV2CustomerPaymentProviderLabel('phonepe', fallback: ''),
      'PhonePe',
    );
    expect(buyV2CustomerPaymentProviderLabel('paytm', fallback: ''), 'Paytm');
    expect(
      buyV2CustomerPaymentProviderLabel('pine-labs', fallback: ''),
      'Pine Labs',
    );
    expect(
      buyV2CustomerPaymentProviderLabel('', fallback: 'Cash on Delivery'),
      'Cash on Delivery',
    );
  });

  test('Cart total supports the full approved Indian amount range', () {
    expect(buyV2Money(1), '₹1');
    expect(buyV2Money(10000000), '₹1,00,00,000');
  });

  testWidgets('persistent Buy navigation preserves one destination surface', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('buy-local-destination-tabs')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('buy-local-tab-wholesale')));
    await tester.pumpAndSettle();
    expect(session.destination, BuyV2Destination.wholesale);
    expect(
      find.byKey(ValueKey('buy-product-${session.visibleProducts.first.id}')),
      findsOneWidget,
    );
    session.openDestination(BuyV2Destination.medicine);
    await tester.pumpAndSettle();
    expect(session.destination, BuyV2Destination.medicine);
    expect(
      find.byKey(ValueKey('buy-product-${session.visibleProducts.first.id}')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
  });

  testWidgets('vertical changes transition the real surface without a wait', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    session.openDestination(BuyV2Destination.medicine);
    await tester.pump();

    expect(
      find.byKey(const ValueKey('buy-destination-progress')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('buy-navigation-surface-current')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-navigation-surface-outgoing')),
      findsNothing,
    );
    expect(
      find.byKey(ValueKey('buy-product-${session.visibleProducts.first.id}')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('buy-shared-header')), findsNothing);
    expect(
      find.byKey(const ValueKey('buy-local-destination-tabs')),
      findsNothing,
    );

    await tester.pumpAndSettle();

    final settledSequence = session.navigationMotionSequence;
    session.openDestination(BuyV2Destination.medicine);
    await tester.pump();
    expect(session.navigationMotionSequence, settledSequence);
    expect(
      find.byKey(const ValueKey('buy-navigation-surface-outgoing')),
      findsNothing,
    );

    session.openOrders();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-orders-assist')), findsNothing);
    session.openAssist();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('buy-destination-progress')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('buy-assist-hero')), findsNothing);
    expect(
      find.byKey(PageStorageKey('buy-tracking-${session.assistOrder.id}')),
      findsOneWidget,
    );
    expect(
      session.navigationMotionDirection,
      BuyV2NavigationMotionDirection.forward,
    );
  });

  testWidgets('MoolSocial opens connected actions without replacing Buy', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    var moolTaps = 0;
    await tester.pumpWidget(app(session, onOpenMool: () => moolTaps += 1));
    await tester.pumpAndSettle();
    session.openDestination(BuyV2Destination.medicine);
    await tester.pumpAndSettle();
    expect(session.destination, BuyV2Destination.medicine);

    await tester.tap(find.byKey(const Key('mool-compact-launcher')));
    await tester.pumpAndSettle();

    expect(moolTaps, 0);
    expect(session.destination, BuyV2Destination.medicine);
    expect(find.byType(BottomSheet), findsNothing);
    expect(
      find.byKey(const ValueKey('mool-connected-action-navigator')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('mool-navigator-family-buy')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('buy-mool-social')), findsNothing);
    expect(find.byKey(const ValueKey('buy-mool-buy')), findsNothing);
    expect(find.text('Pay'), findsNothing);
    await tester.drag(
      find.byKey(const Key('mool-connected-action-navigator-drag-surface')),
      const Offset(0, 80),
    );
    await tester.pumpAndSettle();
    expect(session.destination, BuyV2Destination.medicine);
    expect(
      find.byKey(const ValueKey('mool-connected-action-navigator')),
      findsNothing,
    );
    expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
  });

  testWidgets(
    'approved Buy shell fits representative small and large devices',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      final session = BuyV2Session(core: BuySession());

      for (final size in const [
        Size(320, 568),
        Size(360, 640),
        Size(360, 800),
        Size(375, 667),
        Size(384, 854),
        Size(390, 844),
        Size(393, 852),
        Size(412, 915),
        Size(430, 932),
        Size(480, 960),
        Size(600, 960),
        Size(768, 1024),
        Size(844, 390),
        Size(932, 430),
        Size(1024, 768),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(app(session));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'viewport $size');
        expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
      }
    },
  );

  testWidgets(
    'discovery hierarchy leads with one horizontal product-image collection',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('buy-featured-products')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('buy-featured-product-list')),
        findsOneWidget,
      );
      final products = session.catalogueSaleTypeProducts.take(2).toList();
      final rects = [
        for (final product in products)
          tester.getRect(find.byKey(ValueKey('buy-product-${product.id}'))),
      ];
      expect(
        rects[0].top,
        lessThanOrEqualTo(304),
        reason: 'the expanded motion stage must remain compact',
      );
      expect(rects[1].top, rects[0].top);
      expect(rects[0].left, lessThan(rects[1].left));
      final featuredPhoto = find.byKey(
        ValueKey('buy-featured-packshot-${products.first.id}'),
      );
      expect(tester.getSize(featuredPhoto).width, greaterThanOrEqualTo(145));
      expect(tester.getSize(featuredPhoto).height, greaterThanOrEqualTo(110));
      expect(
        find.byKey(const ValueKey('buy-more-products-heading')),
        findsOneWidget,
      );

      final category = session.categories[1];
      expect(find.byKey(const ValueKey('buy-category-rail')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('buy-category-picker')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-category-grid')), findsOneWidget);
      final categoryLabel = find.byKey(
        ValueKey('buy-category-label-${category.id}'),
      );
      expect(categoryLabel, findsOneWidget);
      expect(tester.getSize(categoryLabel).width, greaterThanOrEqualTo(70));
      expect(tester.widget<Text>(categoryLabel).textAlign, TextAlign.center);
      expect(
        find.byKey(ValueKey('buy-category-${category.id}')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(ValueKey('buy-category-${category.id}')));
      await tester.pumpAndSettle();
      expect(session.selectedCategoryId, category.id);
      expect(find.byKey(const ValueKey('buy-category-picker')), findsOneWidget);
      expect(find.byKey(const ValueKey('buy-category-grid')), findsNothing);
      expect(
        find.byKey(const ValueKey('buy-catalogue-promotions')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('buy-featured-products')), findsNothing);
      expect(find.byType(BuyV2ProductCard), findsWidgets);
    },
  );

  testWidgets('search expands into a dedicated responsive results owner', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1;

    for (final viewport in const [
      (
        size: Size(360, 800),
        safePadding: EdgeInsets.symmetric(vertical: 24),
        label: 'Android 360x800',
      ),
      (
        size: Size(390, 844),
        safePadding: EdgeInsets.only(top: 47, bottom: 34),
        label: 'iOS 390x844',
      ),
      (
        size: Size(430, 932),
        safePadding: EdgeInsets.only(top: 59, bottom: 34),
        label: 'iOS 430x932',
      ),
    ]) {
      tester.view.physicalSize = viewport.size;
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session, safePadding: viewport.safePadding));
      await tester.pumpAndSettle();

      final searchBand = tester.getRect(
        find.byKey(const ValueKey('buy-search-band')),
      );
      final toolbar = tester.getRect(
        find.byKey(const ValueKey('buy-catalogue-toolbar')),
      );
      final restingSearch = tester.getRect(
        find.byKey(const ValueKey('buy-search-control')),
      );
      final dock = tester.getRect(
        find.byKey(const Key('moolsocial-compact-destination-rail')),
      );
      final dockSurface = tester.getRect(
        find.byKey(const Key('mool-compact-launcher')),
      );
      final safeBodyHeight =
          viewport.size.height -
          viewport.safePadding.top -
          viewport.safePadding.bottom;
      final topChromeHeight = toolbar.bottom - searchBand.top;
      final productRegionHeight = dock.top - toolbar.bottom;

      expect(
        searchBand.top,
        viewport.safePadding.top,
        reason: '${viewport.label} search starts at the safe-area top',
      );

      expect(
        topChromeHeight / safeBodyHeight,
        lessThanOrEqualTo(.25),
        reason: '${viewport.label} top chrome',
      );
      expect(
        restingSearch.width / viewport.size.width,
        inInclusiveRange(.65, .76),
        reason:
            '${viewport.label} resting search width with location and account',
      );
      expect(
        restingSearch.height,
        44,
        reason: '${viewport.label} resting search target',
      );
      final restingSearchDecoration =
          tester
                  .widget<AnimatedContainer>(
                    find.byKey(const ValueKey('buy-search-control')),
                  )
                  .decoration!
              as BoxDecoration;
      expect(restingSearchDecoration.color, Colors.transparent);
      expect(restingSearchDecoration.border, isNull);
      expect(restingSearchDecoration.boxShadow, isNull);
      expect(
        find.byKey(const ValueKey('buy-open-scanner')),
        findsNothing,
        reason: '${viewport.label} scanning belongs to a paid collection order',
      );
      await tester.tap(find.byKey(const ValueKey('buy-search-control')));
      await tester.pumpAndSettle();
      final activeSearch = tester.getRect(
        find.byKey(const ValueKey('buy-search-control')),
      );
      expect(
        activeSearch.width / viewport.size.width,
        greaterThanOrEqualTo(.90),
        reason: '${viewport.label} active search width',
      );
      expect(activeSearch.height, 70);
      final activeSearchDecoration =
          tester
                  .widget<AnimatedContainer>(
                    find.byKey(const ValueKey('buy-search-control')),
                  )
                  .decoration!
              as BoxDecoration;
      expect(activeSearchDecoration.color, Colors.transparent);
      expect(activeSearchDecoration.border, isNull);
      expect(activeSearchDecoration.boxShadow, isNull);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('buy-search-band')),
          matching: find.byIcon(Icons.arrow_back_rounded),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('buy-search-close')),
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsOneWidget,
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('buy-search-close'))).height,
        greaterThanOrEqualTo(44),
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('buy-search-field'))).width /
            activeSearch.width,
        greaterThanOrEqualTo(.60),
        reason: '${viewport.label} active search typing width',
      );
      expect(
        find.byKey(const ValueKey('buy-open-scanner')),
        findsNothing,
        reason: '${viewport.label} scanner yields to active query',
      );
      expect(
        find.byKey(const ValueKey('buy-search-results-surface')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('buy-search-suggestion-list')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('buy-search-ready-card')), findsNothing);
      expect(find.text('Shop suggestions'), findsNothing);
      expect(
        find.text('Find products, brands, sellers and product codes.'),
        findsNothing,
      );
      expect(find.byIcon(Icons.manage_search_rounded), findsNothing);
      expect(find.byIcon(Icons.north_west_rounded), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('buy-search-suggestion-list')),
          matching: find.byIcon(Icons.history_rounded),
        ),
        findsNothing,
      );
      for (var index = 0; index < 4; index++) {
        final suggestion = find.byKey(
          ValueKey('buy-search-suggestion-shop-$index'),
        );
        expect(suggestion, findsOneWidget);
        expect(
          tester.getSize(suggestion).height,
          44,
          reason:
              '${viewport.label} suggestion $index uses the dense accessible target',
        );
      }
      expect(find.byKey(const ValueKey('buy-catalogue-toolbar')), findsNothing);
      expect(
        find.byKey(const ValueKey('buy-catalogue-promotions')),
        findsNothing,
      );
      await tester.enterText(
        find.byKey(const ValueKey('buy-search-field')),
        'milk',
      );
      await tester.pumpAndSettle();
      expect(session.query, 'milk');
      expect(find.textContaining('match'), findsWidgets);
      expect(find.byType(BuyV2ProductCard), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('buy-search-close')));
      await tester.pumpAndSettle();
      expect(session.query, 'milk');
      expect(
        tester.getSize(find.byKey(const ValueKey('buy-search-control'))),
        restingSearch.size,
      );
      expect(
        find.byKey(const ValueKey('buy-catalogue-toolbar')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('buy-search-control')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-search-clear')));
      await tester.pumpAndSettle();
      expect(session.query, isEmpty);
      expect(
        find.byKey(const ValueKey('buy-search-suggestion-list')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('buy-search-close')));
      await tester.pumpAndSettle();
      expect(
        dockSurface.height / safeBodyHeight,
        lessThanOrEqualTo(.14),
        reason: '${viewport.label} navigation',
      );
      expect(
        productRegionHeight / safeBodyHeight,
        greaterThanOrEqualTo(.67),
        reason: '${viewport.label} product region',
      );
      expect(tester.takeException(), isNull, reason: viewport.label);
    }
  });

  testWidgets(
    'expanded search offers flat separate Shop Wholesale and Medicine lists',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session, textScale: 1.4));
      await tester.pumpAndSettle();

      for (final destination in const [
        BuyV2Destination.shop,
        BuyV2Destination.wholesale,
        BuyV2Destination.medicine,
      ]) {
        session.openDestination(destination);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('buy-search-control')));
        await tester.pumpAndSettle();

        final suggestions = session.searchSuggestions;
        expect(suggestions, hasLength(4), reason: destination.name);
        expect(
          find.byKey(const ValueKey('buy-search-suggestion-list')),
          findsOneWidget,
        );
        expect(find.text('${destination.label} suggestions'), findsNothing);
        final first = find.byKey(
          ValueKey('buy-search-suggestion-${destination.name}-0'),
        );
        expect(first, findsOneWidget);
        expect(tester.getSize(first).height, greaterThanOrEqualTo(44));
        await tester.ensureVisible(first);
        await tester.tap(first);
        await tester.pumpAndSettle();

        expect(session.query, suggestions.first);
        expect(
          tester
              .widget<TextField>(find.byKey(const ValueKey('buy-search-field')))
              .controller
              ?.text,
          suggestions.first,
        );
        expect(session.visibleProducts, isNotEmpty);
        expect(
          session.visibleProducts.every(
            (product) => product.destination == destination,
          ),
          isTrue,
        );
        expect(find.byType(BuyV2ProductCard), findsWidgets);

        await tester.tap(find.byKey(const ValueKey('buy-search-clear')));
        await tester.pumpAndSettle();
        expect(session.query, isEmpty);
        expect(
          find.byKey(ValueKey('buy-search-suggestion-${destination.name}-0')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('buy-search-close')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: destination.name);
      }

      session.openDestination(BuyV2Destination.orders);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-search-control')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Orders suggestions'), findsNothing);
      expect(
        find.byKey(const ValueKey('buy-search-suggestion-list')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('buy-search-suggestion-orders-0')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'responsive search surface is shared across every Buy destination',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session, textScale: 1.4));
      await tester.pumpAndSettle();

      for (final destination in BuyV2Destination.values) {
        session.openDestination(destination);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('buy-open-scanner')),
          findsNothing,
          reason: '${destination.name} has no generic scanner entry',
        );
        await tester.tap(find.byKey(const ValueKey('buy-search-control')));
        await tester.pumpAndSettle();

        final activeSearch = tester.getRect(
          find.byKey(const ValueKey('buy-search-control')),
        );
        expect(
          tester.getRect(find.byKey(const ValueKey('buy-search-field'))).width /
              activeSearch.width,
          greaterThanOrEqualTo(.60),
          reason: '${destination.name} typing width at 320 / 140 percent',
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('buy-search-band')),
            matching: find.byIcon(Icons.arrow_back_rounded),
          ),
          findsNothing,
          reason: destination.name,
        );
        expect(find.byKey(const ValueKey('buy-search-close')), findsOneWidget);
        expect(find.byIcon(Icons.check_rounded), findsOneWidget);
        expect(
          find.byKey(const ValueKey('buy-open-scanner')),
          findsNothing,
          reason: '${destination.name} scanner yields to active query',
        );

        await tester.enterText(
          find.byKey(const ValueKey('buy-search-field')),
          'a long product sentence that must remain readable without hiding its beginning',
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextField>(find.byKey(const ValueKey('buy-search-field')))
              .maxLines,
          6,
        );
        expect(
          tester
              .getSize(find.byKey(const ValueKey('buy-search-control')))
              .height,
          162,
          reason: '${destination.name} long-query control grows progressively',
        );
        expect(
          tester.getSize(find.byKey(const ValueKey('buy-search-band'))).height,
          174,
          reason: '${destination.name} long-query band owns all wrapped text',
        );
        expect(find.byKey(const ValueKey('buy-open-scanner')), findsNothing);
        expect(find.byKey(const ValueKey('buy-search-clear')), findsOneWidget);
        expect(
          tester.getSize(find.byKey(const ValueKey('buy-search-clear'))).height,
          greaterThanOrEqualTo(44),
          reason: destination.name,
        );
        await tester.tap(find.byKey(const ValueKey('buy-search-clear')));
        await tester.pumpAndSettle();
        expect(session.query, isEmpty);
        await tester.tap(find.byKey(const ValueKey('buy-search-close')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('buy-search-field')), findsNothing);
        expect(tester.takeException(), isNull, reason: destination.name);
      }

      session.openDestination(BuyV2Destination.shop);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-search-control')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('buy-search-field')),
        'milk',
      );
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-search-field')), findsNothing);
      expect(session.query, 'milk');
      expect(session.destination, BuyV2Destination.shop);

      session.updateQuery('');
      await tester.pumpWidget(
        app(session, textScale: 1.4, disableAnimations: true),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-search-control')));
      await tester.pump();
      expect(
        tester.getSize(find.byKey(const ValueKey('buy-search-control'))).height,
        70,
      );
      expect(
        tester
            .widget<AnimatedContainer>(
              find.byKey(const ValueKey('buy-search-band')),
            )
            .duration,
        Duration.zero,
      );
      expect(
        tester
            .widget<AnimatedContainer>(
              find.byKey(const ValueKey('buy-search-control')),
            )
            .duration,
        Duration.zero,
      );
    },
  );

  testWidgets('Account and product depth close the active search owner', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-search-control')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('buy-search-field')),
      'milk',
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-search-results-surface')),
      findsOneWidget,
    );

    session.openAccount();
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.account);
    expect(
      find.byKey(const ValueKey('buy-search-results-surface')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('buy-account-orders')), findsOneWidget);

    session.closeAccount();
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.catalogue);
    expect(session.query, 'milk');
    await tester.tap(find.byKey(const ValueKey('buy-search-control')));
    await tester.pumpAndSettle();
    final product = session.visibleProducts.first;
    await tester.tap(find.byKey(ValueKey('buy-product-${product.id}')));
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.product);
    expect(
      find.byKey(const ValueKey('buy-search-results-surface')),
      findsNothing,
    );
    expect(
      find.byKey(ValueKey('buy-product-packshot-${product.id}')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'category action is compact and Shop sale types reuse its toolbar space',
    (tester) async {
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();

      final categoryAction = find.byKey(const ValueKey('buy-category-picker'));
      expect(tester.getSize(categoryAction), const Size(48, 48));
      expect(
        find.descendant(
          of: categoryAction,
          matching: find.byIcon(Icons.grid_view_rounded),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('buy-saved-products-button')),
          matching: find.byIcon(Icons.bookmark_border_rounded),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('buy-filter-button')),
          matching: find.byIcon(Icons.tune_rounded),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('buy-shop-sale-type-selector')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('buy-shop-sale-type-quick')),
          matching: find.byIcon(Icons.speed_rounded),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('buy-shop-sale-type-courier')),
          matching: find.byIcon(Icons.schedule_rounded),
        ),
        findsOneWidget,
      );
      for (final title in const ['Quick', 'Scheduled']) {
        final iconSurface = tester.widget<AnimatedContainer>(
          find.byKey(ValueKey('buy-sale-type-icon-surface-$title')),
        );
        final iconDecoration = iconSurface.decoration! as BoxDecoration;
        expect(
          tester.getSize(
            find.byKey(ValueKey('buy-sale-type-icon-surface-$title')),
          ),
          const Size(20, 20),
        );
        expect(iconDecoration.color, Colors.white);
        expect(iconDecoration.shape, BoxShape.rectangle);
        expect(iconDecoration.borderRadius, isNull);
        expect(
          (iconDecoration.border! as Border).top.color,
          isNot(BuyV2Colors.orange),
        );
      }
      final track = tester.getRect(
        find.byKey(const ValueKey('buy-shop-sale-type-track')),
      );
      final thumb = tester.getRect(
        find.byKey(const ValueKey('buy-shop-sale-type-thumb')),
      );
      expect(thumb.top, track.top);
      expect(thumb.bottom, track.bottom);
      expect(thumb.left, track.left);
      expect(thumb.width, track.width / 2);
      expect(thumb.height, 34);
      expect(track.height, 34);
      final trackSurface = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('buy-shop-sale-type-track-surface')),
      );
      final trackDecoration = trackSurface.decoration as BoxDecoration;
      expect(trackDecoration.gradient, isNull);
      expect(trackDecoration.color, const Color(0xFFF2F3FF));
      expect(trackDecoration.borderRadius, isNull);
      expect(trackDecoration.boxShadow, isNull);
      final thumbMotion = tester.widget<AnimatedPositioned>(
        find.byKey(const ValueKey('buy-shop-sale-type-thumb')),
      );
      expect(thumbMotion.duration, BuyV2Motion.contentChange);
      expect(thumbMotion.curve, Curves.easeOutQuart);
      final thumbSurface = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('buy-shop-sale-type-thumb-surface')),
      );
      final thumbDecoration = thumbSurface.decoration as BoxDecoration;
      expect(thumbDecoration.gradient, isNull);
      expect(thumbDecoration.color, const Color(0xFF1010A8));
      expect(thumbDecoration.borderRadius, isNull);
      expect(thumbDecoration.border, isNull);
      expect(thumbDecoration.boxShadow, isNull);
      expect(
        find.byKey(const ValueKey('buy-shop-sale-type-active-indicator')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('buy-shop-sale-type-active-indicator-0')),
        findsNothing,
      );
      final segmentTransition = tester.widget<AnimatedSwitcher>(
        find.byKey(const ValueKey('buy-sale-type-segment-transition-Quick')),
      );
      expect(segmentTransition.duration, BuyV2Motion.stateChange);
      final quickTypography = tester.widget<AnimatedDefaultTextStyle>(
        find.byKey(const ValueKey('buy-shop-sale-type-quick-label-style')),
      );
      expect(quickTypography.style.fontSize, 11.25);
      expect(quickTypography.duration, BuyV2Motion.selection);
      final catalogueMotion = tester.widget<TweenAnimationBuilder<double>>(
        find.byKey(const ValueKey('buy-catalogue-motion-tween-shop')),
      );
      expect(catalogueMotion.duration, BuyV2Motion.contentChange);
      expect(catalogueMotion.curve, Curves.easeOutQuart);

      await tester.tap(
        find.byKey(const ValueKey('buy-shop-sale-type-courier')),
      );
      await tester.pumpAndSettle();
      expect(session.shopSaleType, BuyV2ShopSaleType.courier);
      await tester.tap(find.byKey(const ValueKey('buy-shop-sale-type-quick')));
      await tester.pumpAndSettle();
      expect(session.shopSaleType, BuyV2ShopSaleType.quickDelivery);

      await tester.tap(find.byKey(const ValueKey('buy-local-tab-wholesale')));
      await tester.pumpAndSettle();
      final wholesaleSelector = find.byKey(
        const ValueKey('buy-wholesale-sale-type-selector'),
      );
      expect(
        find.descendant(
          of: wholesaleSelector,
          matching: find.byIcon(Icons.business_center_rounded),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: wholesaleSelector,
          matching: find.byIcon(Icons.layers_rounded),
        ),
        findsOneWidget,
      );
      for (final title in const ['Wholesale', 'Bulk']) {
        final iconSurface = tester.widget<AnimatedContainer>(
          find.byKey(ValueKey('buy-sale-type-icon-surface-$title')),
        );
        final iconDecoration = iconSurface.decoration! as BoxDecoration;
        expect(iconDecoration.color, Colors.white);
        expect(iconDecoration.shape, BoxShape.rectangle);
        expect(iconDecoration.borderRadius, isNull);
      }
    },
  );

  testWidgets(
    'commerce toolbar stays spacious at compact width and larger text',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.reset);
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);

      await tester.pumpWidget(app(session, textScale: 1.4));
      await tester.pumpAndSettle();

      final toolbar = tester.getRect(
        find.byKey(const ValueKey('buy-catalogue-toolbar')),
      );
      final category = tester.getRect(
        find.byKey(const ValueKey('buy-category-picker')),
      );
      final selector = tester.getRect(
        find.byKey(const ValueKey('buy-shop-sale-type-selector')),
      );
      final saved = tester.getRect(
        find.byKey(const ValueKey('buy-saved-products-button')),
      );
      final filters = tester.getRect(
        find.byKey(const ValueKey('buy-filter-button')),
      );

      expect(toolbar.height, 60);
      expect(category.size, const Size(48, 48));
      expect(saved.size, const Size(48, 48));
      expect(filters.size, const Size(48, 48));
      expect(category.right, lessThan(selector.left));
      expect(selector.right, lessThan(saved.left));
      expect(saved.right, lessThan(filters.left));
      expect(find.text('Quick'), findsOneWidget);
      expect(find.text('Scheduled'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('buy-local-tab-wholesale')));
      await tester.pumpAndSettle();
      final wholesaleSelector = find.byKey(
        const ValueKey('buy-wholesale-sale-type-selector'),
      );
      expect(
        find.descendant(
          of: wholesaleSelector,
          matching: find.text('Wholesale'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: wholesaleSelector, matching: find.text('Bulk')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('commerce toolbar motion respects reduced-motion preference', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);

    await tester.pumpWidget(app(session, disableAnimations: true));
    await tester.pumpAndSettle();

    final thumbMotion = tester.widget<AnimatedPositioned>(
      find.byKey(const ValueKey('buy-shop-sale-type-thumb')),
    );
    final quickTypography = tester.widget<AnimatedDefaultTextStyle>(
      find.byKey(const ValueKey('buy-shop-sale-type-quick-label-style')),
    );
    final segmentTransition = tester.widget<AnimatedSwitcher>(
      find.byKey(const ValueKey('buy-sale-type-segment-transition-Quick')),
    );
    final catalogueMotion = tester.widget<TweenAnimationBuilder<double>>(
      find.byKey(const ValueKey('buy-catalogue-motion-tween-shop')),
    );
    final category = find.byKey(const ValueKey('buy-category-picker'));
    final categoryPress = find.descendant(
      of: category,
      matching: find.byType(AnimatedScale),
    );
    final categoryLift = find.descendant(
      of: category,
      matching: find.byType(AnimatedSlide),
    );

    expect(thumbMotion.duration, Duration.zero);
    expect(quickTypography.duration, Duration.zero);
    expect(segmentTransition.duration, Duration.zero);
    expect(segmentTransition.reverseDuration, Duration.zero);
    expect(catalogueMotion.duration, Duration.zero);
    expect(categoryPress, findsOneWidget);
    expect(categoryLift, findsOneWidget);
    expect(tester.widget<AnimatedScale>(categoryPress).duration, Duration.zero);
    expect(tester.widget<AnimatedSlide>(categoryLift).duration, Duration.zero);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'every Buy destination keeps one global profile and exact Back return',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      const safePadding = EdgeInsets.only(top: 24, bottom: 24);
      final session = BuyV2Session(core: BuySession());

      await tester.pumpWidget(
        app(session, safePadding: safePadding, disableAnimations: true),
      );
      await tester.pumpAndSettle();

      for (final destination in const [
        BuyV2Destination.shop,
        BuyV2Destination.wholesale,
        BuyV2Destination.medicine,
        BuyV2Destination.orders,
      ]) {
        if (destination == BuyV2Destination.orders) {
          session.openOrders();
        } else {
          session.openDestination(destination);
        }
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('buy-shared-header')),
          findsNothing,
          reason: destination.name,
        );
        expect(
          find.byKey(const ValueKey('buy-contextual-glass-header')),
          findsNothing,
          reason: destination.name,
        );
        expect(
          find.byKey(const ValueKey('buy-header-visual-creative-reel')),
          findsNothing,
          reason: destination.name,
        );
        final searchBand = find.byKey(const ValueKey('buy-search-band'));
        expect(searchBand, findsOneWidget, reason: destination.name);
        expect(
          tester.getTopLeft(searchBand).dy,
          safePadding.top,
          reason: '${destination.name} begins at the safe-area top',
        );
        final accountAction = find.byKey(const ValueKey('buy-open-account'));
        expect(accountAction, findsOneWidget, reason: destination.name);
        expect(
          tester.getSize(accountAction),
          const Size(44, 44),
          reason: '${destination.name} account target remains accessible',
        );
        final searchBandRect = tester.getRect(searchBand);
        final accountRect = tester.getRect(accountAction);
        expect(
          accountRect.right,
          searchBandRect.right - 8,
          reason: '${destination.name} keeps account access at top right',
        );
        expect(
          accountRect.top,
          closeTo(searchBandRect.top + 5, 1),
          reason: '${destination.name} keeps account access in the top row',
        );

        await tester.tap(accountAction);
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.catalogue, reason: destination.name);
        expect(
          find.byKey(const Key('global-profile-panel-v2')),
          findsOneWidget,
          reason: destination.name,
        );
        expect(
          find.bySemanticsLabel('Open your MoolSocial profile'),
          findsOneWidget,
          reason: destination.name,
        );
        expect(
          find.byKey(const ValueKey('buy-profile-avatar')),
          findsNothing,
          reason: destination.name,
        );
        final contextId = switch (destination) {
          BuyV2Destination.shop => 'shop-active-orders',
          BuyV2Destination.wholesale => 'wholesale-discovery',
          BuyV2Destination.medicine => 'medicine-discovery',
          BuyV2Destination.orders => 'shop-orders',
        };
        expect(
          find.byKey(Key('global-profile-context-$contextId')),
          findsOneWidget,
          reason: destination.name,
        );
        expect(find.byKey(const ValueKey('buy-search-band')), findsOneWidget);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(session.destination, destination);
        expect(session.view, BuyV2View.catalogue);
      }

      expect(find.byKey(const ValueKey('buy-v2-screen')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Shop uses the shared global profile and exact Back recovery', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final session = BuyV2Session(core: BuySession());

    await tester.pumpWidget(app(session, disableAnimations: true));
    await tester.pumpAndSettle();

    final profileAction = find.byKey(const ValueKey('buy-open-account'));
    expect(
      find.bySemanticsLabel('Open your MoolSocial profile'),
      findsOneWidget,
    );
    expect(profileAction, findsOneWidget);
    expect(tester.getSize(profileAction), const Size(44, 44));
    expect(find.byKey(const ValueKey('buy-profile-avatar')), findsNothing);

    await tester.tap(profileAction);
    await tester.pumpAndSettle();

    expect(session.view, BuyV2View.catalogue);
    expect(find.byKey(const Key('global-profile-panel-v2')), findsOneWidget);
    expect(find.text('Your MoolSocial profile'), findsOneWidget);
    expect(
      find.byKey(const Key('global-profile-context-shop-active-orders')),
      findsOneWidget,
    );
    expect(find.text('Open orders'), findsOneWidget);
    expect(find.byKey(const ValueKey('buy-search-band')), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(session.destination, BuyV2Destination.shop);
    expect(session.view, BuyV2View.catalogue);
    expect(find.byKey(const Key('global-profile-panel-v2')), findsNothing);
    expect(find.byKey(const ValueKey('buy-search-band')), findsOneWidget);
    expect(find.byKey(const ValueKey('buy-open-account')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('Shop profile context opens the current order destination', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session, disableAnimations: true));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-open-account')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('global-profile-context-action-shop-active-orders')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const Key('global-profile-context-action-shop-active-orders')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('global-profile-panel-v2')), findsNothing);
    expect(session.destination, BuyV2Destination.orders);
    expect(session.view, BuyV2View.catalogue);
    expect(
      find.byKey(const PageStorageKey<String>('buy-orders')),
      findsOneWidget,
    );
  });

  testWidgets('inactive sponsored placement consumes no catalogue height', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: const Scaffold(
          body: Column(
            children: [
              BuyV2SponsoredSlot(
                key: ValueKey('inactive-sponsored-slot'),
                content: null,
              ),
              Text('Products continue'),
            ],
          ),
        ),
      ),
    );

    final slot = find.byKey(const ValueKey('inactive-sponsored-slot'));
    expect(slot, findsOneWidget);
    expect(tester.getSize(slot).height, 0);
    expect(find.text('Products continue'), findsOneWidget);
    expect(find.text('Sponsored'), findsNothing);
    expect(find.text('Advertisement'), findsNothing);
  });

  testWidgets(
    'category glass ends above the dock with compact heading and close',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('buy-category-picker')));
      await tester.pumpAndSettle();

      expect(find.text('Find a category'), findsOneWidget);
      expect(find.text('Shop categories'), findsOneWidget);
      expect(
        tester
            .getSize(find.byKey(const ValueKey('buy-category-search')))
            .height,
        44,
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('buy-category-close'))),
        const Size(44, 44),
      );
      final surface = tester.getRect(
        find.byKey(const ValueKey('buy-category-sheet-surface')),
      );
      final dock = tester.getRect(
        find.byKey(const Key('moolsocial-compact-destination-rail')),
      );
      expect((surface.bottom - dock.top).abs(), lessThanOrEqualTo(24));
      expect(
        find.byKey(ValueKey('buy-product-${session.visibleProducts.first.id}')),
        findsOneWidget,
      );
    },
  );

  test('every approved Buy category has a specific visual icon', () {
    final categories = {
      ...BuyV2Catalogue.shopCategories,
      ...BuyV2Catalogue.wholesaleCategories,
      ...BuyV2Catalogue.medicineCategories,
    };
    for (final category in categories) {
      expect(
        buyV2CategoryIconFor(category.id),
        isNot(Icons.category_outlined),
        reason: category.id,
      );
    }
  });

  testWidgets(
    'category selector fits 320 at 140 percent and finds a late category',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session, textScale: 1.4));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('buy-category-picker')));
      await tester.pumpAndSettle();
      final categoryGrid = find.byKey(const ValueKey('buy-category-grid'));
      expect(categoryGrid, findsOneWidget);
      expect(
        tester.widget<GridView>(categoryGrid).scrollDirection,
        Axis.vertical,
      );
      expect(find.byKey(const ValueKey('buy-category-rail')), findsNothing);

      await tester.enterText(
        find.byKey(const ValueKey('buy-category-search')),
        'shop supplies',
      );
      await tester.pumpAndSettle();
      final lateCategory = find.byKey(
        const ValueKey('buy-category-shop-supplies'),
      );
      expect(lateCategory, findsOneWidget);
      expect(tester.getSize(lateCategory).height, greaterThanOrEqualTo(44));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'catalogue keeps vertical discovery and lazy horizontal products',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('buy-catalogue-promotions')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('buy-featured-products')),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('buy-horizontal-product-grid')),
        220,
        scrollable: scrollableWithin(
          PageStorageKey(
            'buy-${session.destination.name}-'
            '${session.selectedCategoryId}-'
            '${session.saleTypeSignature}-all',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final horizontalGrid = find.byKey(
        const ValueKey('buy-horizontal-product-grid'),
      );
      final horizontalScrollable = find.descendant(
        of: horizontalGrid,
        matching: find.byType(Scrollable),
      );
      expect(horizontalScrollable, findsNWidgets(2));
      final upperLane = find.byKey(
        const ValueKey('buy-horizontal-product-lane-0'),
      );
      final lowerLane = find.byKey(
        const ValueKey('buy-horizontal-product-lane-1'),
      );
      final upperScrollable = find.descendant(
        of: upperLane,
        matching: find.byType(Scrollable),
      );
      final lowerScrollable = find.descendant(
        of: lowerLane,
        matching: find.byType(Scrollable),
      );
      final upperState = tester.state<ScrollableState>(upperScrollable);
      final lowerState = tester.state<ScrollableState>(lowerScrollable);
      expect(upperState.position.axis, Axis.horizontal);
      expect(lowerState.position.axis, Axis.horizontal);
      expect(upperState.position.pixels, 0);
      expect(lowerState.position.pixels, 0);

      final dockTop = tester
          .getRect(find.byKey(const Key('moolsocial-compact-destination-rail')))
          .top;
      expect(tester.getRect(horizontalGrid).top, lessThan(dockTop));
      await tester.drag(upperLane, const Offset(-520, 0));
      await tester.pumpAndSettle();
      expect(upperState.position.pixels, greaterThan(0));
      expect(lowerState.position.pixels, 0);
      await tester.drag(lowerLane, const Offset(-520, 0));
      await tester.pumpAndSettle();
      expect(upperState.position.pixels, greaterThan(0));
      expect(lowerState.position.pixels, greaterThan(0));
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is ListView &&
              widget.scrollDirection == Axis.horizontal &&
              widget.childrenDelegate is SliverChildBuilderDelegate,
        ),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('single-product results reserve only one horizontal lane', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    session.chooseShopSaleType(BuyV2ShopSaleType.courier);
    session.updateQuery('Rice and milk baby cereal');
    await tester.pumpAndSettle();

    expect(session.visibleProducts, hasLength(1));
    expect(
      find.byKey(const ValueKey('buy-horizontal-product-lane-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-horizontal-product-lane-1')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('140 percent text keeps navigation reachable', (tester) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session, textScale: 1.4));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    for (final entry in const [
      (keyName: 'mool-compact-launcher', label: 'Mool'),
      (keyName: 'moolsocial-family-root-buy-tap', label: 'Shop'),
      (keyName: 'buy-local-tab-wholesale', label: 'Wholesale'),
      (keyName: 'buy-local-tab-orders', label: 'Orders'),
      (keyName: 'buy-local-tab-offers', label: 'Offers'),
      (keyName: 'mool-global-chat-tap', label: 'Chat'),
    ]) {
      final cell = find.byKey(ValueKey(entry.keyName));
      final visibleLabel = find.descendant(
        of: cell,
        matching: find.text(entry.label),
      );
      expect(cell, findsOneWidget);
      expect(visibleLabel, findsOneWidget);
      final cellRect = tester.getRect(cell);
      final labelRect = tester.getRect(visibleLabel);
      expect(cellRect.contains(labelRect.topLeft), isTrue, reason: entry.label);
      expect(
        cellRect.contains(labelRect.bottomRight),
        isTrue,
        reason: entry.label,
      );
      expect(
        labelRect.left,
        greaterThanOrEqualTo(cellRect.left + 2),
        reason: '${entry.label} left separation',
      );
      expect(
        labelRect.right,
        lessThanOrEqualTo(cellRect.right - 2),
        reason: '${entry.label} right separation',
      );
    }
  });

  testWidgets('accessible featured cards keep purchase actions in bounds', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session, textScale: 1.4));
    await tester.pumpAndSettle();

    final product = session.visibleProducts.first;
    final card = tester.getRect(
      find.byKey(ValueKey('buy-product-${product.id}')),
    );
    final action = tester.getRect(
      find.byKey(ValueKey('buy-add-${product.id}')),
    );
    expect(action.height, 44);
    expect(action.width, greaterThanOrEqualTo(60));
    expect(card.contains(action.center), isTrue);
    expect(action.right, lessThanOrEqualTo(card.right));
    expect(tester.takeException(), isNull);
  });

  testWidgets('destination tool menus remain usable at 140 percent text', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session, textScale: 1.4));
    await tester.pumpAndSettle();

    for (final entry in const [
      (BuyV2Destination.shop, 'returns'),
      (BuyV2Destination.wholesale, 'manufacturer'),
      (BuyV2Destination.medicine, 'manufacturer'),
    ]) {
      session.openDestination(entry.$1);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-filter-button')));
      await tester.pumpAndSettle();
      if (entry.$1 != BuyV2Destination.medicine) {
        expect(
          find.byKey(const ValueKey('buy-discovery-refinement-title')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('buy-filter-lowest')), findsNothing);
        expect(
          find.byKey(const ValueKey('buy-sort-deliveryFastest')),
          findsNothing,
        );
        final sortSection = find.byKey(
          const ValueKey('buy-refine-section-sort'),
        );
        await tester.tap(
          find
              .descendant(of: sortSection, matching: find.byType(ListTile))
              .first,
        );
        await tester.pumpAndSettle();
        final sort = find.byKey(const ValueKey('buy-sort-priceLowToHigh'));
        await tester.scrollUntilVisible(
          sort,
          100,
          scrollable: find.descendant(
            of: find.byKey(const ValueKey('buy-discovery-refinement-list')),
            matching: find.byType(Scrollable),
          ),
        );
        await tester.tap(sort);
        await tester.pumpAndSettle();
        expect(session.productSort, BuyV2ProductSort.relevance);
        await tester.tap(
          find.byKey(const ValueKey('buy-discovery-refinement-done')),
        );
        await tester.pumpAndSettle();
        expect(session.productSort, BuyV2ProductSort.priceLowToHigh);
        expect(session.catalogueSaleTypeProducts, isNotEmpty);
        expect(tester.takeException(), isNull);
        continue;
      }
      final option = find.byKey(ValueKey('buy-filter-${entry.$2}'));
      await tester.scrollUntilVisible(
        option,
        160,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('buy-filter-list')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      expect(option, findsOneWidget);
      expect(tester.takeException(), isNull, reason: entry.$1.label);
      await tester.tap(option);
      await tester.pumpAndSettle();
      expect(session.selectedFilter, entry.$2);
      expect(session.visibleProducts, isNotEmpty);
    }
  });

  testWidgets('purchase and navigation actions meet the 44 pixel target', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    final product = session.visibleProducts.first;

    final add = find.byKey(ValueKey('buy-add-${product.id}'));
    expect(tester.getSize(add).height, greaterThanOrEqualTo(44));
    expect(
      tester.getSize(find.byKey(const Key('mool-compact-launcher'))).height,
      greaterThanOrEqualTo(44),
    );
    for (final keyName in const [
      'mool-compact-launcher',
      'moolsocial-family-root-buy-tap',
      'buy-local-tab-wholesale',
      'buy-local-tab-orders',
      'buy-local-tab-offers',
      'mool-global-chat-tap',
    ]) {
      expect(
        tester.getSize(find.byKey(ValueKey(keyName))).height,
        greaterThanOrEqualTo(44),
      );
    }
  });

  testWidgets('critical Buy journeys fit compact and large phone widths', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1;

    for (final size in const [Size(320, 568), Size(430, 932)]) {
      tester.view.physicalSize = size;
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();

      final shop = BuyV2Catalogue.products.firstWhere(
        (item) => item.destination == BuyV2Destination.shop,
      );
      final wholesale = BuyV2Catalogue.products.firstWhere(
        (item) => item.destination == BuyV2Destination.wholesale,
      );
      final medicine = BuyV2Catalogue.products.firstWhere(
        (item) =>
            item.destination == BuyV2Destination.medicine &&
            !item.requiresPrescription,
      );

      for (final action in <VoidCallback>[
        () => session.openDestination(BuyV2Destination.wholesale),
        () => session.openDestination(BuyV2Destination.medicine),
        () => session.openProduct(shop.id),
        () {
          session.addProduct(shop.id);
          session.addProduct(wholesale.id);
          session.addProduct(medicine.id);
          session.openCart();
        },
        session.openCheckout,
        session.openOrders,
        () => session.openTracking('MS-240782'),
        session.openAssist,
      ]) {
        action();
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'critical Buy view at $size',
        );
        expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
      }
    }
  });

  testWidgets('product detail exposes purchase decision information', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.wholesale,
    );
    session.openProduct(product.id);
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: BuyV2Screen(
          session: session,
          initialDestination: BuyV2Destination.wholesale,
          initialView: BuyV2View.product,
          productId: product.id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(ValueKey('buy-product-purchase-hero-${product.id}')),
        matching: find.text(product.title),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey('buy-product-inline-action-${product.id}')),
      findsNothing,
    );
    expect(
      find.byKey(ValueKey('buy-wholesale-action-dock-${product.id}')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('buy-product-action-bar')), findsNothing);
    final productScrollable = scrollableWithin(
      PageStorageKey('buy-product-${product.id}'),
    );
    await tester.scrollUntilVisible(
      find.byKey(ValueKey('buy-wholesale-trade-decision-${product.id}')),
      220,
      scrollable: productScrollable,
    );
    expect(find.text('WHOLESALE PRICE'), findsOneWidget);
    expect(find.text('Order details'), findsOneWidget);
    final primary = find.byKey(ValueKey('buy-product-primary-${product.id}'));
    expect(primary, findsOneWidget);
    expect(
      find.descendant(
        of: primary,
        matching: find.byIcon(Icons.add_shopping_cart_rounded),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: primary, matching: find.text(product.title)),
      findsNothing,
    );
    expect(
      find.descendant(of: primary, matching: find.text('Add to Cart')),
      findsOneWidget,
    );
    expect(find.text('Buy now'), findsNothing);
  });

  for (final viewport in [const Size(320, 711), const Size(711, 320)]) {
    for (final scale in [1.0, 2.0]) {
      for (final editing in [false, true]) {
        testWidgets(
          'R669 address layout keeps focus and actions visible $viewport $scale edit $editing',
          (tester) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = viewport;
            addTearDown(tester.view.reset);
            final core = BuySession();
            final session = BuyV2Session(core: core);
            addTearDown(core.dispose);
            addTearDown(session.dispose);
            final before = session.addresses.toList();
            final selected = session.selectedAddressId;
            await tester.pumpWidget(
              app(
                session,
                textScale: scale,
                safePadding: const EdgeInsets.only(top: 24, bottom: 24),
              ),
            );
            await tester.pumpAndSettle();
            unawaited(
              showBuyV2AddressSheet(
                tester.element(find.byType(BuyV2Screen)),
                session,
              ),
            );
            await tester.pumpAndSettle();
            Future<void> reveal(
              String target,
              String list, {
              double delta = 160,
            }) async {
              await tester.scrollUntilVisible(
                find.byKey(ValueKey(target)),
                delta,
                scrollable: find
                    .descendant(
                      of: find.byKey(ValueKey(list)),
                      matching: find.byType(Scrollable),
                    )
                    .first,
                maxScrolls: 50,
              );
              await tester.pumpAndSettle();
              expect(
                find.byKey(ValueKey(target)).hitTestable(),
                findsOneWidget,
              );
            }

            if (editing) {
              await reveal(
                'buy-address-actions-work',
                'buy-address-sheet-list',
              );
              await tester.tap(
                find.byKey(const ValueKey('buy-address-actions-work')),
              );
              await tester.pumpAndSettle();
              await tester.tap(
                find.byKey(const ValueKey('buy-address-edit-work')),
              );
            } else {
              await reveal('buy-address-add', 'buy-address-sheet-list');
              await tester.tap(find.byKey(const ValueKey('buy-address-add')));
            }
            await tester.pumpAndSettle();
            final firstType = find.byKey(
              const ValueKey('buy-address-add-kind-Home'),
            );
            final lastType = find.byKey(
              const ValueKey('buy-address-add-kind-Other place'),
            );
            if (scale == 1) {
              expect(
                tester.getRect(firstType).top,
                closeTo(tester.getRect(lastType).top, .1),
              );
            }
            for (final type in ['Home', 'Work', 'Third party', 'Other place']) {
              final key = 'buy-address-add-kind-$type';
              await reveal(key, 'buy-address-add-form-list');
              final chip = find.byKey(ValueKey(key));
              expect(tester.getSize(chip).height, greaterThanOrEqualTo(44));
              await tester.tap(chip);
              await tester.pumpAndSettle();
              expect(tester.widget<ChoiceChip>(chip).selected, isTrue);
            }
            if (editing) {
              await reveal(
                'buy-address-add-kind-Home',
                'buy-address-add-form-list',
                delta: -160,
              );
              await captureR66Visual(
                tester,
                'r669-address-types-${viewport.width}-$scale',
              );
            }
            final keyboard = viewport.width > viewport.height ? 120.0 : 260.0;
            for (final field in const [
              ('recipient', 'Meera Sharma'),
              ('phone', '9876543210'),
              ('line', '24 Market Road'),
              ('area', 'Basni, Jodhpur'),
              ('pin', '342005'),
              ('landmark', 'Near school'),
            ]) {
              final id = 'buy-address-add-${field.$1}';
              await reveal(id, 'buy-address-add-form-list');
              final input = find.byKey(ValueKey(id));
              await tester.tap(input);
              await tester.pump();
              tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
              await tester.pumpAndSettle();
              await tester.enterText(input, field.$2);
              await tester.pumpAndSettle();
              final editable = tester.state<EditableTextState>(
                find.descendant(of: input, matching: find.byType(EditableText)),
              );
              final renderer = editable.renderEditable;
              final caret = renderer
                  .getLocalRectForCaret(TextPosition(offset: field.$2.length))
                  .shift(renderer.localToGlobal(Offset.zero));
              final visible = tester.getRect(
                find.byKey(const ValueKey('buy-address-add-form-list')),
              );
              expect(
                visible.bottom,
                lessThanOrEqualTo(viewport.height - keyboard + .1),
              );
              expect(
                caret.top,
                greaterThanOrEqualTo(visible.top - .1),
                reason: field.$1,
              );
              expect(
                caret.bottom,
                lessThanOrEqualTo(visible.bottom + .1),
                reason: field.$1,
              );
              expect(
                caret.bottom,
                lessThanOrEqualTo(viewport.height - keyboard),
                reason: field.$1,
              );
              if (editing && field.$1 == 'recipient') {
                await captureR66Visual(
                  tester,
                  'r669-address-keyboard-${viewport.width}-$scale',
                );
              }
              tester.testTextInput.hide();
              tester.view.viewInsets = FakeViewPadding.zero;
              await tester.pumpAndSettle();
            }
            await reveal('buy-address-add-submit', 'buy-address-add-form-list');
            final save = find.byKey(const ValueKey('buy-address-add-submit'));
            expect(tester.getSize(save).height, greaterThanOrEqualTo(44));
            final paragraph = tester.renderObject<RenderParagraph>(
              find.descendant(of: save, matching: find.byType(RichText)).first,
            );
            expect(paragraph.didExceedMaxLines, isFalse);
            expect(
              paragraph.localToGlobal(Offset.zero).dy + paragraph.size.height,
              lessThanOrEqualTo(tester.getRect(save).bottom + .1),
            );
            if (editing) {
              await captureR66Visual(
                tester,
                'r669-address-save-${viewport.width}-$scale',
              );
            }
            await tester.tap(save);
            await tester.pumpAndSettle();
            expect(
              find.byKey(const ValueKey('buy-address-add-form-route')),
              findsNothing,
            );
            expect(session.addresses.length, before.length + (editing ? 0 : 1));
            final saved = editing
                ? session.addresses.singleWhere((a) => a.id == 'work')
                : session.selectedAddress;
            expect(saved.recipient, 'Meera Sharma');
            expect(saved.phone, '9876543210');
            expect(saved.kind, BuyV2AddressKind.other);
            if (editing) expect(session.selectedAddressId, selected);
            expect(session.itemCount, 0);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  for (final scale in [1.0, 2.0]) {
    for (final name in ['', 'Aarav Shah']) {
      testWidgets(
        'R669 address request preserves manual recipient $scale ${name.isEmpty ? 'blank' : 'named'}',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(320, 711);
          addTearDown(tester.view.reset);
          final core = BuySession();
          final session = BuyV2Session(core: core);
          addTearDown(core.dispose);
          addTearDown(session.dispose);
          final originalAddresses = session.addresses.toList();
          final selected = session.selectedAddressId;
          await tester.pumpWidget(app(session, textScale: scale));
          await tester.pumpAndSettle();
          unawaited(
            showBuyV2AddressSheet(
              tester.element(find.byType(BuyV2Screen)),
              session,
            ),
          );
          await tester.pumpAndSettle();
          Future<void> reveal(
            String target,
            String list, {
            double delta = 200,
          }) async {
            await tester.scrollUntilVisible(
              find.byKey(ValueKey(target)),
              delta,
              scrollable: find
                  .descendant(
                    of: find.byKey(ValueKey(list)),
                    matching: find.byType(Scrollable),
                  )
                  .first,
              maxScrolls: 40,
            );
            await tester.pumpAndSettle();
            expect(find.byKey(ValueKey(target)).hitTestable(), findsOneWidget);
          }

          await reveal('buy-address-request', 'buy-address-sheet-list');
          await tester.tap(find.byKey(const ValueKey('buy-address-request')));
          await tester.pumpAndSettle();
          await reveal(
            'buy-address-request-recipient',
            'buy-address-request-form-list',
          );
          final requestName = find.byKey(
            const ValueKey('buy-address-request-recipient'),
          );
          await tester.enterText(requestName, name);
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await tester.pumpAndSettle();
          await reveal(
            'buy-address-request-enter-manually',
            'buy-address-request-form-list',
          );
          await tester.tap(
            find.byKey(const ValueKey('buy-address-request-enter-manually')),
          );
          await tester.pumpAndSettle();
          await reveal(
            'buy-address-add-recipient',
            'buy-address-add-form-list',
          );
          final manualName = find.byKey(
            const ValueKey('buy-address-add-recipient'),
          );
          expect(tester.widget<TextField>(manualName).controller!.text, name);
          if (name.isNotEmpty) {
            await captureR66Visual(tester, 'r669-address-recipient-$scale');
          }
          await tester.enterText(manualName, 'Changed draft');
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          await reveal(
            'buy-address-request-recipient',
            'buy-address-request-form-list',
            delta: -200,
          );
          expect(tester.widget<TextField>(requestName).controller!.text, name);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(session.addresses, originalAddresses);
          expect(session.selectedAddressId, selected);
          expect(session.itemCount, 0);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final viewport in [const Size(320, 711), const Size(711, 320)]) {
    testWidgets('R665 D04 enlarged report actions fit safe viewport $viewport', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = viewport;
      addTearDown(tester.view.reset);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await tester.pumpWidget(
        app(
          session,
          textScale: 2,
          safePadding: const EdgeInsets.only(top: 24, bottom: 24),
        ),
      );
      await tester.pumpAndSettle();
      const productId = 's-tomato';
      session.openProduct(productId);
      await tester.pumpAndSettle();
      final report = find.byKey(const ValueKey('buy-report-product-s-tomato'));
      await tester.scrollUntilVisible(
        report,
        250,
        scrollable: scrollableWithin(
          const PageStorageKey('buy-product-s-tomato'),
        ),
        maxScrolls: 50,
      );
      await tester.ensureVisible(report);
      await tester.pumpAndSettle();
      await tester.tap(report);
      await tester.pumpAndSettle();
      final cancel = find.byKey(const ValueKey('buy-cancel-product-report'));
      final send = find.byKey(const ValueKey('buy-submit-report-s-tomato'));
      for (final keyboard in [0.0, 100.0, 0.0]) {
        tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(cancel.hitTestable(), findsOneWidget);
        expect(tester.widget<FilledButton>(send).onPressed, isNull);
        for (final action in [cancel, send]) {
          final rect = tester.getRect(action);
          expect(rect.top, greaterThanOrEqualTo(24));
          expect(
            rect.bottom,
            lessThanOrEqualTo(viewport.height - keyboard - 24),
          );
          for (final paragraph in tester.renderObjectList<RenderParagraph>(
            find.descendant(of: action, matching: find.byType(RichText)),
          )) {
            final text = TextPainter(
              text: paragraph.text,
              textDirection: paragraph.textDirection,
              textScaler: paragraph.textScaler,
            )..layout(maxWidth: paragraph.size.width);
            expect(
              paragraph.size.height,
              greaterThanOrEqualTo(text.height - .1),
            );
            if (identical(action, cancel)) {
              expect(
                text.computeLineMetrics(),
                hasLength(1),
                reason:
                    'Cancel must remain an intact word at the chosen text size.',
              );
              expect(tester.getSize(cancel).height, greaterThanOrEqualTo(48));
            }
            text.dispose();
          }
        }
      }
      final reason = find.byKey(const ValueKey('buy-report-reason-0'));
      await tester.ensureVisible(reason);
      await tester.pumpAndSettle();
      await tester.tap(reason);
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(send).onPressed, isNotNull);
      await captureR66Visual(tester, 'r669-report-cancel-${viewport.width}');
      await tester.tap(cancel);
      await tester.pumpAndSettle();
      expect(session.hasReportedProduct(productId), isFalse);
      expect(session.selectedProduct?.id, productId);
      expect(session.view, BuyV2View.product);
      expect(report.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'product detail uses automatic fulfilment reviews and reporting',
    (tester) async {
      final session = BuyV2Session(core: BuySession());
      final product = BuyV2Catalogue.products.firstWhere(
        (item) => item.destination == BuyV2Destination.shop,
      );
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();
      session.openProduct(product.id);
      await tester.pumpAndSettle();

      expect(
        find.byKey(ValueKey('buy-product-packshot-${product.id}')),
        findsOneWidget,
      );
      final productScrollable = scrollableWithin(
        PageStorageKey('buy-product-${product.id}'),
      );
      await tester.scrollUntilVisible(
        find.byKey(ValueKey('buy-automatic-fulfilment-${product.id}')),
        220,
        scrollable: productScrollable,
      );
      expect(find.textContaining(product.seller), findsWidgets);
      expect(find.textContaining('Verified'), findsNothing);

      final reviews = find.byKey(ValueKey('buy-product-reviews-${product.id}'));
      await tester.scrollUntilVisible(
        reviews,
        240,
        scrollable: productScrollable,
      );
      await tester.drag(productScrollable, const Offset(0, -140));
      await tester.pumpAndSettle();
      final reviewProduct = find.byKey(
        ValueKey('buy-review-product-${product.id}'),
      );
      expect(tester.getCenter(reviewProduct).dy, lessThan(480));
      await tester.tap(reviewProduct);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(ValueKey('buy-review-rating-${product.id}-4')),
      );
      await tester.enterText(
        find.byKey(ValueKey('buy-review-comment-${product.id}')),
        'Fresh pack and the delivery promise was clear.',
      );
      await tester.pump();
      await tester.tap(find.byKey(ValueKey('buy-submit-review-${product.id}')));
      await tester.pumpAndSettle();
      expect(
        find.text('Fresh pack and the delivery promise was clear.'),
        findsOneWidget,
      );
      expect(session.customerReviewFor(product.id)?.rating, 4);

      await tester.tap(
        find.byKey(ValueKey('buy-report-product-${product.id}')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-report-reason-0')));
      final submitReport = find.byKey(
        ValueKey('buy-submit-report-${product.id}'),
      );
      await tester.ensureVisible(submitReport);
      await tester.pumpAndSettle();
      await tester.tap(submitReport);
      await tester.pumpAndSettle();
      expect(find.text('Reported'), findsOneWidget);
      expect(session.hasReportedProduct(product.id), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  for (final testCase in const [
    (productId: 's-tomato', minutes: 12),
    (productId: 's-noodles', minutes: 18),
  ]) {
    testWidgets(
      'R66 019 Quick category retains ${testCase.minutes} minute product and Cart promise',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final core = BuySession();
        final session = BuyV2Session(core: core);
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        final product = session.product(testCase.productId);
        expect(product.deliveryPromise, 'Delivery in ${testCase.minutes} min');
        await tester.pumpWidget(app(session));
        await tester.pumpAndSettle();
        final selector = find.byKey(
          const ValueKey('buy-shop-sale-type-selector'),
        );
        expect(
          find.descendant(of: selector, matching: find.text('Quick')),
          findsOneWidget,
        );
        expect(find.text('Quick 10m'), findsNothing);
        expect(
          tester.widget<Semantics>(selector).properties.label,
          'Choose Quick or scheduled Shop products',
        );
        await tester.tap(
          find.byKey(const ValueKey('buy-shop-sale-type-courier')),
        );
        await tester.pumpAndSettle();
        expect(session.shopSaleType, BuyV2ShopSaleType.courier);
        await tester.tap(
          find.byKey(const ValueKey('buy-shop-sale-type-quick')),
        );
        await tester.pumpAndSettle();
        expect(session.shopSaleType, BuyV2ShopSaleType.quickDelivery);
        session.openProduct(product.id);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byKey(ValueKey('buy-automatic-fulfilment-${product.id}')),
          220,
          scrollable: scrollableWithin(
            PageStorageKey('buy-product-${product.id}'),
          ),
        );
        expect(find.text('Delivery in ${testCase.minutes} min'), findsWidgets);
        expect(session.addProduct(product.id), isTrue);
        session.openCart();
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Delivery in ${testCase.minutes} min'),
          findsOneWidget,
        );
        expect(session.quantityFor(product.id), 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'B01 T02 keeps one product while server promises 3 5 and 10 minutes',
    (tester) async {
      for (final testCase in const [
        (productId: 's-oil', destination: BuyV2Destination.shop, minutes: 3),
        (productId: 's-tomato', destination: BuyV2Destination.shop, minutes: 5),
        (
          productId: 'w-oil',
          destination: BuyV2Destination.wholesale,
          minutes: 10,
        ),
      ]) {
        final core = BuySession();
        final session = BuyV2Session(
          core: core,
          productFactsAdapter: _FixedDeliveryPromiseFactsAdapter(
            'within ${testCase.minutes} min',
          ),
        );
        final product = session.product(testCase.productId);

        await tester.pumpWidget(app(session));
        await tester.pumpAndSettle();
        session.openDestination(testCase.destination);
        session.openProduct(product.id);
        await tester.pumpAndSettle();
        final productScrollable = scrollableWithin(
          PageStorageKey('buy-product-${product.id}'),
        );
        await tester.scrollUntilVisible(
          find.byKey(ValueKey('buy-automatic-fulfilment-${product.id}')),
          220,
          scrollable: productScrollable,
        );

        expect(find.text('Delivery in ${testCase.minutes} min'), findsWidgets);
        expect(find.textContaining(product.seller), findsWidgets);
        expect(
          find.byKey(ValueKey('buy-shop-seller-action-${product.id}')),
          testCase.destination == BuyV2Destination.shop
              ? findsOneWidget
              : findsNothing,
        );
        expect(
          find.byKey(ValueKey('buy-wholesale-supplier-action-${product.id}')),
          findsNothing,
        );

        expect(session.addProduct(product.id), isTrue);
        session.openCart();
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Delivery in ${testCase.minutes} min'),
          findsOneWidget,
        );
        expect(find.text(product.seller), findsNothing);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        session.dispose();
        core.dispose();
      }
    },
  );

  test(
    'B01 T02 promise copy fails closed for checking stale and unavailable',
    () {
      final product = BuyV2Catalogue.products;
      final base = const BuyV2CatalogueProductFactsAdapter().snapshotFor(
        product.first,
      );
      expect(
        buyV2BuyerDeliveryPromise(
          base.copyWith(orderabilityLabel: 'Checking serviceability'),
        ),
        'Checking delivery time',
      );
      expect(
        buyV2BuyerDeliveryPromise(base.copyWith(stale: true)),
        'Delivery time needs review',
      );
      expect(
        buyV2BuyerDeliveryPromise(
          base.copyWith(orderabilityLabel: 'Currently unavailable'),
        ),
        'Currently unavailable',
      );
    },
  );

  testWidgets('packshot atlas isolates one exact cell per product', (
    tester,
  ) async {
    final tomato = BuyV2Catalogue.products.firstWhere(
      (item) =>
          item.destination == BuyV2Destination.shop &&
          item.canonicalId == 'tomato',
    );
    final rice = BuyV2Catalogue.products.firstWhere(
      (item) =>
          item.destination == BuyV2Destination.shop &&
          item.canonicalId == 'rice',
    );
    final medicine = BuyV2Catalogue.products.firstWhere(
      (item) =>
          item.destination == BuyV2Destination.medicine &&
          item.visualKind == 'medicine-box',
    );
    final milk = BuyV2Catalogue.products.firstWhere(
      (item) =>
          item.destination == BuyV2Destination.shop &&
          item.title.toLowerCase().contains('milk'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: [
            for (final product in [tomato, rice, medicine, milk])
              SizedBox(
                width: 64,
                height: 56,
                child: BuyV2ProductPackshot(product: product),
              ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    Positioned cellFor(BuyV2Product product) {
      final source = BuyV2ProductPackshot.resolveMedia(product)!;
      return tester.widget<Positioned>(
        find.byKey(
          ValueKey(
            'buy-packshot-sprite-${product.id}-'
            '${source.assetPath}-${source.cell}',
          ),
        ),
      );
    }

    final tomatoCell = cellFor(tomato);
    final riceCell = cellFor(rice);
    final medicineCell = cellFor(medicine);
    final milkCell = cellFor(milk);
    expect((tomatoCell.left, tomatoCell.top), (0, 0));
    expect((riceCell.left, riceCell.top), (-64, 0));
    expect((medicineCell.left, medicineCell.top), (0, 0));
    expect((milkCell.left, milkCell.top), (-128, -56));
    for (final cell in [tomatoCell, riceCell, medicineCell, milkCell]) {
      expect(cell.width, 256);
      expect(cell.height, 168);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'every seeded product resolves to exact or truthful category media',
    (tester) async {
      final eggs = BuyV2Catalogue.products.firstWhere(
        (item) =>
            item.destination == BuyV2Destination.shop &&
            item.canonicalId == 'eggs',
      );
      final resolutions = {
        for (final product in BuyV2Catalogue.products)
          product.id: BuyV2ProductPackshot.resolveMedia(product),
      };
      expect(resolutions.values, isNot(contains(null)));
      expect(
        resolutions.values.where(
          (source) => source?.kind == BuyV2ProductMediaKind.exactProduct,
        ),
        isNotEmpty,
      );
      expect(
        resolutions.values.where(
          (source) => source?.kind == BuyV2ProductMediaKind.category,
        ),
        isNotEmpty,
      );
      final eggsSource = resolutions[eggs.id]!;
      expect(eggsSource.kind, BuyV2ProductMediaKind.category);
      expect(eggsSource.assetPath, BuyV2ProductPackshot.categoryAtlasAPath);
      expect(eggsSource.cell, 2);
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 86,
            height: 64,
            child: BuyV2ProductPackshot(product: eggs),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(ValueKey('buy-product-media-fallback-${eggs.id}')),
        findsNothing,
      );
      expect(
        find.byKey(
          ValueKey(
            'buy-packshot-sprite-${eggs.id}-'
            '${eggsSource.assetPath}-${eggsSource.cell}',
          ),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'featured products lead with a dominant photo and readable filtered cards',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.reset);
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();

      final product = session.visibleProducts.first;
      final photo = find.byKey(ValueKey('buy-featured-packshot-${product.id}'));
      expect(photo, findsOneWidget);
      expect(tester.getSize(photo).width, greaterThanOrEqualTo(145));
      expect(tester.getSize(photo).height, greaterThanOrEqualTo(110));

      await tester.tap(find.byKey(ValueKey('buy-add-${product.id}')));
      await tester.pumpAndSettle();
      expect(session.quantityFor(product.id), 1);
      expect(
        find.byKey(ValueKey('buy-quantity-${product.id}')),
        findsOneWidget,
      );

      session.chooseCategory(product.categoryId);
      await tester.pumpAndSettle();
      final densePhoto = find.byKey(
        ValueKey('buy-grid-packshot-${product.id}'),
      );
      expect(densePhoto, findsOneWidget);
      expect(tester.getSize(densePhoto), const Size(78, 70));
      expect(find.byType(BuyV2ProductCard), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('featured press and quantity motion respect reduced motion', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session, disableAnimations: true));
    await tester.pumpAndSettle();

    final product = session.visibleProducts.first;
    final animatedCard = find.byKey(
      ValueKey('buy-featured-product-${product.id}'),
    );
    expect(tester.widget<AnimatedScale>(animatedCard).duration, Duration.zero);

    await tester.tap(find.byKey(ValueKey('buy-add-${product.id}')));
    await tester.pump();
    expect(session.quantityFor(product.id), 1);
    expect(find.byKey(ValueKey('buy-quantity-${product.id}')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('product detail keeps a large upload-ready media tile', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    session.openProduct(product.id);
    await tester.pumpAndSettle();

    final gallery = find.byKey(ValueKey('buy-product-gallery-${product.id}'));
    final firstImage = find.byKey(
      const ValueKey('buy-product-gallery-image-0'),
    );
    expect(gallery, findsOneWidget);
    expect(tester.getSize(firstImage).width, greaterThanOrEqualTo(270));
    expect(tester.getSize(firstImage).height, greaterThanOrEqualTo(180));
    expect(
      find.byKey(const ValueKey('buy-product-gallery-count')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('buy-product-gallery-dot-0')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('tracking Items opens an order item and returns to that order', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    final selectedProduct = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    expect(session.addProduct(selectedProduct.id), isTrue);
    session.openCart(scope: BuyV2CartScope.shop);
    expect(session.openCheckout(), isTrue);
    expect(session.confirmOrder(), isTrue);
    final order = session.confirmedOrders.single;
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    session.openTracking(order.id);
    await tester.pumpAndSettle();

    final invoiceAction = find.byKey(
      ValueKey('buy-tracking-invoice-${order.id}'),
    );
    await tester.scrollUntilVisible(
      invoiceAction,
      220,
      scrollable: scrollableWithin(PageStorageKey('buy-tracking-${order.id}')),
    );
    await tester.tap(invoiceAction);
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey('buy-invoice-page-${order.id}')),
      findsOneWidget,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.tracking);
    expect(session.selectedOrder.id, order.id);

    final itemsAction = find.text('Items');
    await tester.scrollUntilVisible(
      itemsAction,
      220,
      scrollable: scrollableWithin(PageStorageKey('buy-tracking-${order.id}')),
    );
    await tester.tap(itemsAction);
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.orderItems);
    expect(find.byKey(ValueKey('buy-order-items-${order.id}')), findsOneWidget);
    final product = session.productsForOrder(session.selectedOrder).first;
    await tester.tap(find.byKey(ValueKey('buy-order-product-${product.id}')));
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.product);
    expect(session.selectedProductId, product.id);

    session.goBack();
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.orderItems);
    expect(session.selectedOrder.id, order.id);
  });

  testWidgets(
    'Shop Wholesale and Medicine details fit compact Android and iOS sizes',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      for (final viewport in const [
        Size(320, 568),
        Size(390, 844),
        Size(430, 932),
      ]) {
        tester.view.physicalSize = viewport;
        for (final destination in const [
          BuyV2Destination.shop,
          BuyV2Destination.wholesale,
          BuyV2Destination.medicine,
        ]) {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          final session = BuyV2Session(core: BuySession());
          final product = BuyV2Catalogue.products.firstWhere(
            (item) =>
                item.destination == destination && !item.requiresPrescription,
          );
          await tester.pumpWidget(app(session, textScale: 1.4));
          await tester.pumpAndSettle();
          session.openProduct(product.id);
          await tester.pumpAndSettle();

          expect(
            find.byKey(ValueKey('buy-product-packshot-${product.id}')),
            findsOneWidget,
            reason: '$destination at $viewport',
          );
          final productScrollable = scrollableWithin(
            PageStorageKey('buy-product-${product.id}'),
          );
          final decisionOwner = destination == BuyV2Destination.medicine
              ? find.text(product.partnerRole)
              : find.byKey(ValueKey('buy-automatic-fulfilment-${product.id}'));
          await tester.scrollUntilVisible(
            decisionOwner,
            140,
            scrollable: productScrollable,
          );
          expect(
            decisionOwner,
            findsOneWidget,
            reason: '$destination at $viewport',
          );
          expect(find.textContaining('Verified'), findsNothing);
          await tester.scrollUntilVisible(
            find.byKey(ValueKey('buy-product-reviews-${product.id}')),
            180,
            scrollable: productScrollable,
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '$destination at $viewport',
          );
        }
      }
    },
  );

  testWidgets('Account and shared Chat preserve the exact purchase depth', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    var chatOpens = 0;
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.wholesale,
    );
    await tester.pumpWidget(app(session, onOpenChat: () => chatOpens += 1));
    session.openProduct(product.id);
    await tester.pumpAndSettle();

    session.openAccount();
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.account);
    session.closeAccount();
    await tester.pumpAndSettle();
    expect(session.destination, BuyV2Destination.wholesale);
    expect(session.view, BuyV2View.product);
    expect(session.selectedProductId, product.id);

    session.openTracking('MS-240782');
    await tester.pumpAndSettle();
    final trackingHelp = find.byKey(const ValueKey('buy-tracking-help'));
    final trackingScroll = scrollableWithin(
      const PageStorageKey('buy-tracking-MS-240782'),
    );
    await tester.scrollUntilVisible(
      trackingHelp,
      180,
      scrollable: trackingScroll,
    );
    await tester.drag(trackingScroll, const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(trackingHelp);
    await tester.pumpAndSettle();
    expect(chatOpens, 1);
    expect(session.destination, BuyV2Destination.orders);
    expect(session.view, BuyV2View.tracking);
    expect(session.selectedOrder.id, 'MS-240782');
  });

  testWidgets(
    'Account Orders Prescription and Wholesale actions complete and return',
    (tester) async {
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();

      session.openAccount();
      await tester.pumpAndSettle();
      expect(find.textContaining('Verified'), findsNothing);
      expect(find.textContaining('VERIFIED'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('buy-account-orders')));
      await tester.pumpAndSettle();
      expect(session.destination, BuyV2Destination.orders);
      expect(session.canReturnToAccount, isTrue);
      final ordersReturn = find.byKey(
        const ValueKey('buy-orders-return-account'),
      );
      await tester.tapAt(
        tester.getTopLeft(ordersReturn) + const Offset(24, 20),
      );
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.account);

      await tester.tap(find.byKey(const ValueKey('buy-account-prescriptions')));
      await tester.pumpAndSettle();
      final addPrescription = find.byKey(
        const ValueKey('buy-prescription-add-new'),
      );
      expect(addPrescription, findsOneWidget);
      expect(tester.getSize(addPrescription).height, greaterThanOrEqualTo(44));
      await tester.tap(addPrescription);
      await tester.pumpAndSettle();
      expect(session.prescriptionAttached, isTrue);
      expect(session.approvedPrescriptionProductCount, 3);
      expect(find.text('3 matched medicines available'), findsOneWidget);

      final wholesaleWorkspace = find.byKey(
        const ValueKey('buy-account-workspace'),
      );
      await tester.ensureVisible(wholesaleWorkspace);
      await tester.tap(wholesaleWorkspace);
      await tester.pumpAndSettle();
      expect(session.destination, BuyV2Destination.wholesale);
      expect(session.view, BuyV2View.catalogue);
      expect(
        find.byKey(const ValueKey('buy-catalogue-return-account')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('buy-catalogue-return-account')),
      );
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.account);

      session.closeAccount();
      await tester.pumpAndSettle();
      expect(session.destination, BuyV2Destination.shop);
      expect(session.view, BuyV2View.catalogue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('each Buy vertical category uses lazy horizontal products', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    for (final destination in const [
      BuyV2Destination.shop,
      BuyV2Destination.wholesale,
      BuyV2Destination.medicine,
    ]) {
      session.openDestination(destination);
      final category = session.categories.firstWhere(
        (item) => item.id != 'all',
      );
      session.chooseCategory(category.id);
      await tester.pumpAndSettle();

      final horizontalGrid = find.byKey(
        const ValueKey('buy-horizontal-product-grid'),
      );
      expect(horizontalGrid, findsOneWidget, reason: destination.name);
      final scrollable = find.descendant(
        of: horizontalGrid,
        matching: find.byType(Scrollable),
      );
      expect(scrollable, findsWidgets, reason: destination.name);
      for (final element in scrollable.evaluate()) {
        expect(
          tester
              .state<ScrollableState>(
                find.byElementPredicate(
                  (candidate) => identical(candidate, element),
                ),
              )
              .position
              .axis,
          Axis.horizontal,
          reason: destination.name,
        );
      }
      expect(tester.takeException(), isNull, reason: destination.name);
    }
  });

  testWidgets('catalogue plus becomes an inline quantity stepper and returns', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    final product = session.visibleProducts.first;
    final add = find.byKey(ValueKey('buy-add-${product.id}'));

    expect(find.text('ADD'), findsNothing);
    expect(
      find.descendant(of: add, matching: find.byIcon(Icons.add_rounded)),
      findsOneWidget,
    );
    await tester.tap(add);
    await tester.pumpAndSettle();
    final quantity = find.byKey(ValueKey('buy-quantity-${product.id}'));
    expect(quantity, findsOneWidget);
    expect(session.quantityFor(product.id), 1);

    await tester.tap(
      find
          .descendant(
            of: find.byKey(ValueKey('buy-product-${product.id}')),
            matching: find.byTooltip('Remove one'),
          )
          .hitTestable(),
    );
    await tester.pumpAndSettle();
    expect(session.quantityFor(product.id), 0);
    expect(add, findsOneWidget);
  });

  testWidgets('product and Cart keep plus and minus quantity controls', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    await tester.pumpWidget(app(session));
    session.openProduct(product.id);
    await tester.pumpAndSettle();

    final primary = find.byKey(ValueKey('buy-product-primary-${product.id}'));
    final productScroll = find
        .descendant(
          of: find.byKey(PageStorageKey('buy-product-${product.id}')),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(primary, 180, scrollable: productScroll);
    await tester.pumpAndSettle();
    await tester.tap(primary);
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey('buy-product-quantity-${product.id}')),
      findsOneWidget,
    );

    session.openCart(scope: BuyV2CartScope.shop);
    await tester.pumpAndSettle();
    final line = find.byKey(ValueKey('buy-cart-line-${product.id}'));
    expect(line, findsOneWidget);
    await tester.tap(
      find.descendant(of: line, matching: find.byTooltip('Add one')),
    );
    await tester.pumpAndSettle();
    expect(session.quantityFor(product.id), 2);
    await tester.tap(
      find.descendant(of: line, matching: find.byTooltip('Remove one')),
    );
    await tester.pumpAndSettle();
    expect(session.quantityFor(product.id), 1);
  });

  testWidgets('add confirmation is owned by the Cart bar, not the top toast', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );

    session.addProduct(product.id);
    await tester.pump();

    expect(session.notice, isNull);
    expect(session.cartAcknowledgement, '${product.title} added');
    expect(
      find.byKey(const ValueKey('buy-cart-acknowledgement')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-mini-cart-added-icon')),
      findsOneWidget,
    );
    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey('buy-compact-cart-indicator')),
          )
          .label,
      contains(session.cartAcknowledgement!),
    );
    expect(find.byKey(const ValueKey('buy-live-notice')), findsNothing);
  });

  testWidgets('non-empty Cart becomes a compact conversion control', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    final surface = find.byKey(const ValueKey('buy-navigation-overlay-stack'));
    final surfaceHeight = tester.getSize(surface).height;

    session.addProduct(product.id);
    await tester.pump();

    final miniCart = find.byKey(const ValueKey('buy-compact-cart-indicator'));
    expect(miniCart, findsOneWidget);
    expect(tester.getSize(surface).height, surfaceHeight);
    expect(tester.getSize(miniCart).height, 48);
    expect(tester.getSize(miniCart).width, inInclusiveRange(88, 132));
    expect(
      find.byKey(const ValueKey('buy-mini-cart-transparent-overlay')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-mini-cart-added-icon')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<BuyV2FiniteValueTransition>(
            find.byKey(const ValueKey('buy-cart-acknowledgement')),
          )
          .text,
      '1 item',
    );
    expect(
      tester
          .widget<BuyV2FiniteValueTransition>(
            find.byKey(const ValueKey('buy-cart-total')),
          )
          .text,
      buyV2Money(product.price),
    );
    await tester.pump(const Duration(milliseconds: 2700));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-mini-cart-icon')), findsOneWidget);
    expect(
      tester
          .widget<BuyV2FiniteValueTransition>(
            find.byKey(const ValueKey('buy-cart-summary')),
          )
          .text,
      '1 item',
    );

    final initialRect = tester.getRect(miniCart);
    await tester.drag(
      find.byKey(const ValueKey('buy-mini-cart-drag-handle')),
      const Offset(-100, -120),
    );
    await tester.pumpAndSettle();
    final movedRect = tester.getRect(miniCart);
    final surfaceRect = tester.getRect(surface);
    expect(movedRect.left, lessThan(initialRect.left));
    expect(movedRect.top, lessThan(initialRect.top));
    expect(surfaceRect.contains(movedRect.topLeft), isTrue);
    expect(surfaceRect.contains(movedRect.bottomRight), isTrue);

    await tester.tap(miniCart);
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.cart);
    expect(miniCart, findsNothing);
  });

  testWidgets('R66 cart drag accumulates every pointer update between frames', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    session.addProduct('s-tomato');
    session.clearCartAcknowledgement();
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    final cart = find.byKey(const ValueKey('buy-mini-cart-drag-handle'));
    final gesture = await tester.startGesture(tester.getCenter(cart));
    await gesture.moveBy(const Offset(-30, -30));
    await tester.pump();
    final before = tester.getTopLeft(cart);
    for (var update = 0; update < 5; update++) {
      await gesture.moveBy(const Offset(-8, -12));
    }
    await tester.pump();
    expect(tester.getTopLeft(cart).dx, closeTo(before.dx - 40, .1));
    expect(tester.getTopLeft(cart).dy, closeTo(before.dy - 60, .1));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.catalogue);
    await tester.tap(cart);
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.cart);
    expect(session.cartScope, BuyV2CartScope.shop);
    expect(tester.takeException(), isNull);
  });

  testWidgets('R66 store cart only intercepts its visible compact control', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    session.addProduct('s-tomato');
    var opened = 0;
    var background = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => background++,
                  child: const ColoredBox(color: Colors.white),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 24,
                child: BuyV2StoreCartBar(
                  session: session,
                  destination: BuyV2Destination.shop,
                  onOpenCart: () => opened++,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final bar = find.byKey(const ValueKey('buy-store-cart-bar'));
    await tester.tapAt(Offset(12, tester.getCenter(bar).dy));
    expect(background, 1);
    expect(opened, 0);
    expect(tester.getSize(bar).width, lessThan(300));
    await tester.tap(bar);
    expect(opened, 1);
    expect(tester.takeException(), isNull);
  });

  bool expectCartSummary(WidgetTester tester, int count, int total) {
    final summary = '$count ${count == 1 ? 'item' : 'items'}';
    final indicator = find.byKey(const ValueKey('buy-compact-cart-indicator'));
    final parked = find.byKey(const ValueKey('buy-cart-navigation-button'));
    if (parked.evaluate().isNotEmpty) {
      expect(parked.hitTestable(), findsOneWidget);
      expect(tester.getSize(parked), const Size(44, 44));
      final tooltip = tester.widget<Tooltip>(
        find.descendant(of: indicator, matching: find.byType(Tooltip)),
      );
      expect(tooltip.message, contains(summary));
      expect(tooltip.message, contains(buyV2Money(total)));
      expect(tester.getSemantics(indicator).label, tooltip.message);
      return true;
    }
    expect(
      tester
          .widget<BuyV2FiniteValueTransition>(
            find.byKey(const ValueKey('buy-cart-summary')),
          )
          .text,
      summary,
    );
    expect(
      tester
          .widget<BuyV2FiniteValueTransition>(
            find.byKey(const ValueKey('buy-cart-total')),
          )
          .text,
      buyV2Money(total),
    );
    return false;
  }

  for (final total in [1, 10000, 10000000]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'R66 cart display fixture INR$total fits complete text at $scale',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(360, 800));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final session = _R66CartDisplayFixture(total);
          addTearDown(session.dispose);
          session.addProduct('w-notebook');
          session.clearCartAcknowledgement();
          await tester.pumpWidget(
            app(
              session,
              textScale: scale,
              captureCart: const bool.fromEnvironment('BUY_R66_CART_CAPTURE'),
            ),
          );
          await tester.pumpAndSettle();
          session.openDestination(BuyV2Destination.wholesale);
          await tester.pumpAndSettle();
          await _captureR66Cart(tester, 'root-inr$total-text$scale');
          final cartRect = tester.getRect(
            find.byKey(const ValueKey('buy-mini-cart-drag-handle')),
          );
          final contentRect = tester.getRect(
            find.byKey(const ValueKey('buy-cart-content-viewport')),
          );
          for (final promotion in find.byType(BuyV2PromotionCard).evaluate()) {
            final visible = tester
                .getRect(
                  find.byElementPredicate((element) => element == promotion),
                )
                .intersect(contentRect);
            if (visible.width > 0 && visible.height > 0) {
              expect(cartRect.overlaps(visible), isFalse);
            }
          }
          final parked = expectCartSummary(
            tester,
            session.countForDestination(BuyV2Destination.wholesale),
            total,
          );
          if (parked) {
            final tooltip = find.descendant(
              of: find.byKey(const ValueKey('buy-compact-cart-indicator')),
              matching: find.byType(Tooltip),
            );
            await tester.longPress(
              find.byKey(const ValueKey('buy-cart-navigation-button')),
            );
            await tester.pumpAndSettle();
            final message = find.text(tester.widget<Tooltip>(tooltip).message!);
            expect(message, findsOneWidget);
            expect(
              tester.renderObject<RenderParagraph>(message).didExceedMaxLines,
              isFalse,
            );
          }
          for (final key
              in parked ? <String>[] : ['buy-cart-summary', 'buy-cart-total']) {
            final value = tester.widget<BuyV2FiniteValueTransition>(
              find.byKey(ValueKey(key)),
            );
            final painter = TextPainter(
              text: TextSpan(
                text: value.text,
                style: value.style.copyWith(fontFamily: 'Inter'),
              ),
              textDirection: TextDirection.ltr,
              textScaler: TextScaler.linear(scale),
              maxLines: 1,
            )..layout();
            expect(
              value.ownerSize.height,
              greaterThanOrEqualTo(painter.height),
            );
            expect(value.ownerSize.width, greaterThanOrEqualTo(painter.width));
            painter.dispose();
          }
          expect(
            tester
                .getSize(
                  find.byKey(const ValueKey('buy-compact-cart-indicator')),
                )
                .width,
            lessThanOrEqualTo(344),
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(
            MaterialApp(
              theme: MoolTheme.light(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: const bool.fromEnvironment('BUY_R66_CART_CAPTURE')
                    ? RepaintBoundary(
                        key: const ValueKey('r66-cart-capture'),
                        child: child!,
                      )
                    : r66VisualCaptureRoot(child!),
              ),
              home: Scaffold(
                body: Align(
                  alignment: Alignment.bottomRight,
                  child: BuyV2StoreCartBar(
                    session: session,
                    destination: BuyV2Destination.wholesale,
                    onOpenCart: () {},
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final store = find.byKey(const ValueKey('buy-store-cart-bar'));
          await _captureR66Cart(tester, 'store-inr$total-text$scale');
          final amount = find.byKey(const ValueKey('buy-store-cart-total'));
          expect(tester.widget<Text>(amount).data, buyV2Money(total));
          expect(
            tester.renderObject<RenderParagraph>(amount).didExceedMaxLines,
            isFalse,
          );
          expect(
            tester.getRect(store).contains(tester.getTopLeft(amount)),
            isTrue,
          );
          expect(
            tester.getBottomRight(amount).dy,
            lessThanOrEqualTo(tester.getRect(store).bottom),
          );
          expect(tester.getSize(store).width, lessThanOrEqualTo(344));
          expect(tester.getSize(store).height, greaterThanOrEqualTo(44));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'Cart stays destination-scoped in Shop and Wholesale and aggregate in Orders',
    (tester) async {
      final session = BuyV2Session(core: BuySession());
      final shop = BuyV2Catalogue.products.firstWhere(
        (item) => item.destination == BuyV2Destination.shop,
      );
      final wholesale = BuyV2Catalogue.products.firstWhere(
        (item) => item.destination == BuyV2Destination.wholesale,
      );
      final medicine = BuyV2Catalogue.products.firstWhere(
        (item) =>
            item.destination == BuyV2Destination.medicine &&
            !item.requiresPrescription,
      );
      session.addProduct(shop.id);
      session.addProduct(wholesale.id);
      session.addProduct(medicine.id);
      session.clearCartAcknowledgement();
      await tester.pumpWidget(app(session, textScale: 1.4));
      await tester.pumpAndSettle();

      session.openDestination(BuyV2Destination.wholesale);
      await tester.pumpAndSettle();
      expectCartSummary(
        tester,
        session.countForDestination(BuyV2Destination.wholesale),
        session.totalForDestination(BuyV2Destination.wholesale),
      );
      expect(
        tester
            .getSemantics(
              find.byKey(const ValueKey('buy-compact-cart-indicator')),
            )
            .label,
        contains(
          '${session.countForDestination(BuyV2Destination.wholesale)} '
          '${session.countForDestination(BuyV2Destination.wholesale) == 1 ? 'item' : 'items'} ready',
        ),
      );
      expect(
        tester
            .getSemantics(
              find.byKey(const ValueKey('buy-compact-cart-indicator')),
            )
            .label,
        contains(
          buyV2Money(session.totalForDestination(BuyV2Destination.wholesale)),
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey('buy-compact-cart-indicator')),
      );
      await tester.pumpAndSettle();
      expect(session.cartScope, BuyV2CartScope.wholesale);
      expect(session.cartLines, hasLength(1));

      session.openDestination(BuyV2Destination.orders);
      await tester.pumpAndSettle();
      expectCartSummary(tester, session.itemCount, session.cartTotal);
      expect(
        tester
            .getSemantics(
              find.byKey(const ValueKey('buy-compact-cart-indicator')),
            )
            .label,
        contains(
          '${session.itemCount} '
          '${session.itemCount == 1 ? 'item' : 'items'} ready',
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey('buy-compact-cart-indicator')),
      );
      await tester.pumpAndSettle();
      expect(session.cartScope, BuyV2CartScope.all);
      expect(session.cartLines, hasLength(3));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('T01A Cart hides Medicine in Shop and preserves Care Medicine', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    for (final destination in const [
      BuyV2Destination.shop,
      BuyV2Destination.wholesale,
      BuyV2Destination.medicine,
    ]) {
      final product = BuyV2Catalogue.products.firstWhere(
        (item) => item.destination == destination && !item.requiresPrescription,
      );
      session.addProduct(product.id);
    }
    session.openDestination(BuyV2Destination.wholesale);
    session.openCart(scope: BuyV2CartScope.wholesale);
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    expect(find.text('Medicine'), findsNothing);

    session.openDestination(BuyV2Destination.medicine);
    session.openCart(scope: BuyV2CartScope.medicine);
    await tester.pumpAndSettle();
    expect(find.text('Medicine'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Care Medicine never exposes an unrelated Shop basket', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    final shop = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    final medicine = BuyV2Catalogue.products.firstWhere(
      (item) =>
          item.destination == BuyV2Destination.medicine &&
          !item.requiresPrescription,
    );
    session.addProduct(shop.id);
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    session.openDestination(BuyV2Destination.medicine);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('buy-compact-cart-indicator')),
      findsNothing,
    );

    session.addProduct(medicine.id);
    await tester.pumpAndSettle();
    final miniCart = find.byKey(const ValueKey('buy-compact-cart-indicator'));
    expect(miniCart, findsOneWidget);
    expect(
      tester.getSemantics(miniCart).label,
      contains(buyV2Money(medicine.price)),
    );
    expect(
      tester.getSemantics(miniCart).label,
      isNot(contains(buyV2Money(shop.price + medicine.price))),
    );

    await tester.tap(miniCart);
    await tester.pumpAndSettle();
    expect(session.cartScope, BuyV2CartScope.medicine);
    expect(session.cartLines, hasLength(1));
    expect(session.cartLines.single.product.id, medicine.id);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'compact Buy surface and Cart total remain whole at 320 and 140 percent',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      final session = BuyV2Session(core: BuySession());
      final products = BuyV2Catalogue.products
          .where((item) => item.destination == BuyV2Destination.shop)
          .take(2);
      for (final product in products) {
        session.addProduct(product.id);
      }
      await tester.pumpWidget(app(session, textScale: 1.4));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('buy-change-location')), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('buy-search-band'))).dy,
        0,
      );

      session.openCart();
      await tester.pumpAndSettle();
      final actionBar = find.byKey(const ValueKey('buy-cart-action-bar'));
      final total = find.descendant(
        of: actionBar,
        matching: find.text(buyV2Money(session.scopedCartTotal)),
      );
      expect(total, findsOneWidget);
      expect(tester.widget<Text>(total).maxLines, 1);
      final actionRect = tester.getRect(actionBar);
      final totalRect = tester.getRect(total);
      expect(actionRect.contains(totalRect.topLeft), isTrue);
      expect(actionRect.contains(totalRect.bottomRight), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('saved destination and payment remain separate decisions', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    session.addProduct(product.id);
    session.openCheckout();
    session.clearNotice();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('buy-checkout-address-home')),
      findsOneWidget,
    );
    expect(find.text('Delivery address'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('buy-checkout-address-edit-home')),
      findsOneWidget,
    );
    expect(find.text('Payment · PhonePe'), findsNothing);
    await advanceCheckoutToPayment(tester, session);
    expect(find.byKey(const ValueKey('buy-payment-PhonePe')), findsOneWidget);
    expect(find.text('Amount to MoolSocial'), findsOneWidget);
    expect(find.textContaining('Delivery & payment'), findsNothing);
    expect(find.textContaining('delivery and payment'), findsNothing);
  });

  testWidgets('tracking shows current progress, next step and working alerts', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    session.openTracking('MS-240782');
    await tester.pumpAndSettle();

    expect(find.text('CURRENT'), findsOneWidget);
    expect(find.text('LIVE'), findsNothing);
    expect(find.text('54%'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byKey(const ValueKey('buy-tracking-progress')),
          )
          .value,
      .54,
    );
    expect(find.text('NOW'), findsOneWidget);
    final nextStep = find.text('What happens next');
    final trackingScrollable = scrollableWithin(
      const PageStorageKey('buy-tracking-MS-240782'),
    );
    await tester.scrollUntilVisible(
      nextStep,
      180,
      scrollable: trackingScrollable,
    );
    expect(nextStep, findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('buy-tracking-alerts')),
      180,
      scrollable: trackingScrollable,
    );
    expect(find.text('Order updates'), findsOneWidget);
    expect(find.text('Order alerts are on'), findsOneWidget);

    final alertsToggle = find.byKey(
      const ValueKey('buy-tracking-alerts-toggle'),
    );
    await tester.scrollUntilVisible(
      alertsToggle,
      180,
      scrollable: trackingScrollable,
    );
    await tester.drag(trackingScrollable, const Offset(0, -72));
    await tester.pumpAndSettle();
    await tester.tap(alertsToggle);
    await tester.pump();
    expect(session.trackingAlertsEnabled, isFalse);
    expect(find.text('Order alerts are paused'), findsOneWidget);
  });

  testWidgets('compact cart never covers tracking or support actions', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    session.addProduct(product.id);
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    session.openTracking('MS-240782');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Help'),
      260,
      scrollable: scrollableWithin(
        const PageStorageKey('buy-tracking-MS-240782'),
      ),
    );
    expect(find.text('Help'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('buy-compact-cart-indicator')),
      findsNothing,
    );

    session.openAssist();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-assist-hero')), findsNothing);
    expect(
      find.byKey(PageStorageKey('buy-tracking-${session.assistOrder.id}')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-compact-cart-indicator')),
      findsNothing,
    );
  });

  testWidgets('retired Assist state uses tracking and shared Chat only', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    var chatOpens = 0;
    await tester.pumpWidget(app(session, onOpenChat: () => chatOpens += 1));
    await tester.pumpAndSettle();

    session.openAssist();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('buy-assist-hero')), findsNothing);
    expect(
      find.byKey(PageStorageKey('buy-tracking-${session.assistOrder.id}')),
      findsOneWidget,
    );
    final help = find.byKey(const ValueKey('buy-tracking-help'));
    await tester.scrollUntilVisible(
      help,
      240,
      scrollable: scrollableWithin(
        PageStorageKey('buy-tracking-${session.assistOrder.id}'),
      ),
    );
    await tester.tap(help);
    await tester.pumpAndSettle();
    expect(chatOpens, 1);
    expect(find.text('Call in app'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cart item count uses correct singular and plural copy', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    final products = BuyV2Catalogue.products
        .where((item) => item.destination == BuyV2Destination.shop)
        .take(2)
        .toList();
    session.addProduct(products.first.id);
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    session.openCart();
    await tester.pumpAndSettle();

    expect(find.textContaining('1 product ·'), findsOneWidget);
    expect(find.textContaining('1 products'), findsNothing);

    session.addProduct(products.last.id);
    await tester.pumpAndSettle();
    expect(find.textContaining('2 products ·'), findsOneWidget);
  });

  testWidgets('Buy prices use locked Indian currency grouping', (tester) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    session.openOrders();
    await tester.pumpAndSettle();

    expect(find.text('₹4,839'), findsOneWidget);
    expect(find.text('₹4,200'), findsOneWidget);
    expect(find.text('₹4839'), findsNothing);
    expect(find.text('₹4200'), findsNothing);
  });

  testWidgets('order card body performs its advertised primary action', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    session.openOrders();
    await tester.pumpAndSettle();

    final activeCard = find.byKey(const ValueKey('buy-order-card-MS-240782'));
    final activeRect = tester.getRect(activeCard);
    await tester.tapAt(activeRect.topLeft + const Offset(60, 60));
    await tester.pumpAndSettle();

    expect(session.view, BuyV2View.tracking);
    expect(session.selectedOrder.id, 'MS-240782');

    session.openOrders();
    session.showOrdersTab(BuyV2OrdersTab.delivered);
    await tester.pumpAndSettle();
    final deliveredCard = find.byKey(
      const ValueKey('buy-order-card-MS-240741'),
    );
    final deliveredRect = tester.getRect(deliveredCard);
    await tester.tapAt(deliveredRect.topLeft + const Offset(60, 60));
    await tester.pumpAndSettle();

    expect(session.view, BuyV2View.tracking);
    expect(session.selectedOrder.id, 'MS-240741');
    expect(session.ordersTab, BuyV2OrdersTab.delivered);
    expect(session.cartLines, isEmpty);
  });

  testWidgets('Orders opens at the top after Checkout was scrolled', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    session.addProduct(product.id);
    session.openCheckout();
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    session.openOrders();
    await tester.pumpAndSettle();

    expect(find.text('PURCHASES'), findsOneWidget);
    expect(find.text('Orders'), findsWidgets);
    expect(find.text('Active'), findsWidgets);
  });

  testWidgets('saved and typed product-code search complete visibly', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    var scannerCalls = 0;
    final savedProduct = session.visibleProducts.first;
    session.toggleSaved(savedProduct.id);
    await tester.pumpWidget(
      app(
        session,
        scannerLauncher: (_) async {
          scannerCalls += 1;
          return savedProduct.id;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-saved-products-button')));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    await tester.tap(find.byKey(ValueKey('buy-product-${savedProduct.id}')));
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.product);

    session.returnToCatalogue();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-open-scanner')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('buy-search-control')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('buy-search-field')),
      savedProduct.id,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('buy-product-${savedProduct.id}')));
    await tester.pumpAndSettle();

    expect(scannerCalls, 0);
    expect(session.query, savedProduct.id);
    expect(session.selectedProductId, savedProduct.id);
    expect(session.view, BuyV2View.product);
  });

  testWidgets('R5 search 022A every catalogue retires the generic scanner', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    var scannerCalls = 0;
    await tester.pumpWidget(
      app(
        session,
        scannerLauncher: (_) async {
          scannerCalls += 1;
          return null;
        },
      ),
    );
    await tester.pumpAndSettle();

    for (final destination in BuyV2Destination.values) {
      session.openDestination(destination);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-open-scanner')), findsNothing);
      expect(find.byTooltip('Open camera barcode scanner'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('buy-search-control')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-search-field')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('buy-search-close')));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-open-scanner')), findsNothing);
    expect(scannerCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('products save at the grid and appear in the Saved owner', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    final product = session.visibleProducts.first;
    if (session.isSaved(product.id)) {
      session.toggleSaved(product.id);
    }
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    final card = find.byKey(ValueKey('buy-product-${product.id}'));
    final save = find.byKey(ValueKey('buy-save-${product.id}'));
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    expect(tester.getRect(card).contains(tester.getCenter(save)), isTrue);

    await tester.tap(save);
    await tester.pump();
    expect(session.isSaved(product.id), isTrue);
    final notice = find.byKey(const ValueKey('buy-live-notice'));
    expect(notice, findsOneWidget);
    final noticeRect = tester.getRect(notice);
    final contentRight = tester
        .getRect(find.byKey(const ValueKey('buy-theme-canvas')))
        .right;
    expect(noticeRect.width, lessThanOrEqualTo(248));
    expect(noticeRect.right, contentRight - 8);

    await tester.tap(find.byKey(const ValueKey('buy-saved-products-button')));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byKey(ValueKey('buy-product-${product.id}')), findsOneWidget);
  });

  testWidgets('category and search actions cannot strand the Saved grid', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('buy-category-rail')), findsNothing);
    expect(find.byKey(const ValueKey('buy-category-picker')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('buy-category-picker')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('buy-category-search')),
      'shop supplies',
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-category-shop-supplies')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('buy-category-shop-supplies')));
    await tester.pumpAndSettle();
    expect(session.selectedCategoryId, 'shop-supplies');
    expect(find.byKey(const ValueKey('buy-category-grid')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('buy-search-control')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-search-field')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('buy-search-results-surface')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-saved-products-button')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('buy-search-close')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-saved-products-button')));
    await tester.pumpAndSettle();
    for (final product in session.savedProductsFor(BuyV2Destination.shop)) {
      expect(find.byKey(ValueKey('buy-product-${product.id}')), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('manual scanner recovery is compact and returns a code', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                result = await showBuyV2ManualCodeSheet(context);
              },
              child: const Text('Open scanner fallback'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open scanner fallback'));
    await tester.pumpAndSettle();
    expect(
      tester
          .getSize(find.byKey(const ValueKey('buy-manual-code-panel')))
          .height,
      lessThanOrEqualTo(238),
    );
    await tester.enterText(
      find.byKey(const ValueKey('buy-product-code-field')),
      'shop-atta',
    );
    await tester.tap(find.byKey(const ValueKey('buy-use-product-code')));
    await tester.pumpAndSettle();
    expect(result, 'shop-atta');
  });

  testWidgets(
    'featured card exposes automatic delivery and a stable purchase action',
    (tester) async {
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();
      final product = session.visibleProducts.first;
      final card = find.byKey(ValueKey('buy-product-${product.id}'));
      final add = find.byKey(ValueKey('buy-add-${product.id}'));
      final promise = find.descendant(
        of: card,
        matching: find.textContaining('Quick local'),
      );

      expect(add, findsOneWidget);
      expect(promise, findsOneWidget);
      expect(find.textContaining(product.seller), findsOneWidget);
      final cardRect = tester.getRect(card);
      expect(cardRect.contains(tester.getCenter(add)), isTrue);
      expect(cardRect.contains(tester.getCenter(promise)), isTrue);
      expect(tester.getSize(add).height, 44);
      expect(tester.getSize(add).width, greaterThanOrEqualTo(60));
    },
  );

  testWidgets('PAY-07 success settles once with customer actions only', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    expect(session.addProduct('s-tomato'), isTrue);
    session.openCart(scope: BuyV2CartScope.shop);
    expect(session.openCheckout(), isTrue);
    expect(session.confirmOrder(), isTrue);
    await tester.pump();

    expect(
      find.byKey(ValueKey('buy-order-success-${session.confirmedPurchaseId}')),
      findsOneWidget,
    );
    expect(find.text('Order placed'), findsOneWidget);
    expect(find.text('Track delivery'), findsNothing);
    expect(find.text('View purchase in Orders'), findsNothing);
    expect(
      find.byKey(const ValueKey('buy-confirmation-order-details')),
      findsOneWidget,
    );
    final continueShopping = find.byKey(
      const ValueKey('buy-confirmation-continue-shopping'),
    );
    await tester.scrollUntilVisible(
      continueShopping,
      180,
      scrollable: scrollableWithin(const ValueKey('buy-confirmation')),
    );
    expect(continueShopping, findsOneWidget);

    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PAY-08 Quick status is compact with restorable preferences', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await tester.pumpWidget(
      app(session, deliveryArrivalSound: _R5ScreenArrivalSound()),
    );
    await tester.pumpAndSettle();
    expect(session.addProduct('s-tomato'), isTrue);
    session.openCart(scope: BuyV2CartScope.shop);
    expect(session.openCheckout(), isTrue);
    expect(session.confirmOrder(), isTrue);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('buy-quick-delivery-status-minimized')),
      findsOneWidget,
    );
    final minimizedContentTop = tester
        .getTopLeft(find.byKey(const ValueKey('buy-confirmation')))
        .dy;
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey('buy-quick-delivery-status-minimized')),
          )
          .width,
      lessThanOrEqualTo(48),
    );
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey('buy-quick-delivery-status-minimized')),
          )
          .height,
      inInclusiveRange(44, 48),
    );
    await tester.tap(find.byKey(const ValueKey('buy-quick-delivery-expand')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-quick-delivery-status-expanded')),
      findsOneWidget,
    );
    expect(find.text('Keep'), findsOneWidget);
    expect(find.text('Arrival sound'), findsOneWidget);
    expect(find.text('Hide'), findsOneWidget);
    final controlCenters = [
      tester
          .getCenter(find.byKey(const ValueKey('buy-quick-delivery-keep')))
          .dy,
      tester
          .getCenter(find.byKey(const ValueKey('buy-quick-delivery-sound')))
          .dy,
      tester
          .getCenter(find.byKey(const ValueKey('buy-quick-delivery-hide')))
          .dy,
    ];
    controlCenters.sort();
    expect(controlCenters.last - controlCenters.first, lessThan(6));
    await tester.tap(find.byKey(const ValueKey('buy-quick-delivery-sound')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilterChip>(
            find.byKey(const ValueKey('buy-quick-delivery-sound')),
          )
          .selected,
      isTrue,
    );
    await tester.tap(find.byKey(const ValueKey('buy-quick-delivery-hide')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-quick-delivery-toggle')),
      findsNothing,
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('buy-confirmation'))).dy,
      minimizedContentTop,
    );
    expect(session.openTracking(session.activeQuickDeliveryOrder!.id), isTrue);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-quick-delivery-restore')));
    await tester.pumpAndSettle();
    session.returnToOrders();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-quick-delivery-toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-quick-delivery-keep')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-quick-delivery-status-expanded')),
      findsOneWidget,
    );
    expect(find.text('Kept'), findsOneWidget);
  });

  testWidgets('PAY-08 scheduled and courier delivery uses quiet status', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    final product = BuyV2Catalogue.products.firstWhere(
      (candidate) =>
          candidate.destination == BuyV2Destination.shop &&
          session.fulfilmentModeFor(candidate) ==
              BuyV2FulfilmentMode.standardCourier,
    );
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    expect(session.addProduct(product.id), isTrue);
    session.openCart(scope: BuyV2CartScope.shop);
    expect(session.openCheckout(), isTrue);
    expect(session.confirmOrder(), isTrue);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('buy-quiet-delivery-status')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-quick-delivery-status-expanded')),
      findsNothing,
    );
  });

  for (final amount in [1000000, 10000000, 100001280]) {
    for (final layout in [
      (size: const Size(360, 800), scale: 1.0, label: 'normal'),
      (size: const Size(320, 711), scale: 2.0, label: 'enlarged-portrait'),
      (size: const Size(711, 320), scale: 2.0, label: 'enlarged-landscape'),
    ]) {
      testWidgets(
        'R668 cart payable INR$amount is complete at ${layout.label}',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = layout.size;
          addTearDown(tester.view.reset);
          final session = _R668CartPayableFixture(amount);
          addTearDown(session.dispose);
          await tester.pumpWidget(app(session, textScale: layout.scale));
          await tester.pumpAndSettle();
          session.addProduct('w-notebook');
          session.openCart(scope: BuyV2CartScope.all);
          await tester.pumpAndSettle();
          final actionBar = find.byKey(const ValueKey('buy-cart-action-bar'));
          if (layout.label == 'enlarged-landscape') {
            await tester.scrollUntilVisible(
              actionBar,
              240,
              scrollable: scrollableWithin(
                const PageStorageKey('buy-cart-all'),
              ),
            );
            await tester.pumpAndSettle();
          }
          final amountOwner = find.byKey(
            const ValueKey('buy-cart-payable-total-motion'),
          );
          final displayedAmount = find.descendant(
            of: amountOwner,
            matching: find.byType(Text),
          );
          expect(displayedAmount, findsOneWidget);
          final amountText = tester.widget<Text>(displayedAmount).data!;
          expect(
            amountText,
            isIn([
              buyV2Money(amount),
              buyV2Money(amount).replaceFirst('₹', ''),
            ]),
          );
          if (!amountText.contains('₹')) {
            expect(find.text('Cart total (₹)'), findsOneWidget);
          }
          final paragraph = tester.renderObject<RenderParagraph>(
            displayedAmount,
          );
          expect(paragraph.didExceedMaxLines, isFalse);
          final amountRect = tester.getRect(displayedAmount);
          expect(
            amountRect.left,
            greaterThanOrEqualTo(tester.getRect(actionBar).left),
          );
          expect(
            amountRect.right,
            lessThanOrEqualTo(tester.getRect(actionBar).right),
          );
          final boxes = paragraph.getBoxesForSelection(
            TextSelection(baseOffset: 0, extentOffset: amountText.length),
          );
          expect(boxes, isNotEmpty);
          final visibleAmountBoundary = tester.getRect(actionBar);
          for (final box in boxes) {
            final topLeft = paragraph.localToGlobal(Offset(box.left, box.top));
            final bottomRight = paragraph.localToGlobal(
              Offset(box.right, box.bottom),
            );
            expect(
              topLeft.dx,
              greaterThanOrEqualTo(visibleAmountBoundary.left),
            );
            expect(
              bottomRight.dx,
              lessThanOrEqualTo(visibleAmountBoundary.right),
            );
            expect(
              bottomRight.dy,
              lessThanOrEqualTo(visibleAmountBoundary.bottom),
            );
            expect(
              box.top,
              closeTo(boxes.first.top, .1),
              reason: 'Keep the numeric amount together on one line.',
            );
          }
          final review = find.descendant(
            of: actionBar,
            matching: find.text('Review order'),
          );
          await tester.ensureVisible(review);
          await tester.pumpAndSettle();
          expect(review.hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
          await captureR66Visual(tester, 'r669-cart-$amount-${layout.label}');
          await tester.tap(review);
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.checkout);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('PAY-09 Cart summary clears the fixed action bar', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    final product = BuyV2Catalogue.products.firstWhere(
      (candidate) => candidate.destination == BuyV2Destination.wholesale,
    );
    await tester.pumpWidget(app(session, textScale: 1.4));
    await tester.pumpAndSettle();
    expect(session.addProduct(product.id), isTrue);
    session.openCart(scope: BuyV2CartScope.wholesale);
    await tester.pumpAndSettle();

    final summary = find.byKey(const ValueKey('buy-cart-bill-summary'));
    final cartList = scrollableWithin(
      const PageStorageKey('buy-cart-wholesale'),
    );
    await tester.scrollUntilVisible(summary, 220, scrollable: cartList);
    await tester.pumpAndSettle();
    final actionBar = find.byKey(const ValueKey('buy-cart-action-bar'));
    final dockTotal = find.descendant(
      of: actionBar,
      matching: find.text(buyV2Money(session.scopedPayableTotal)),
    );
    final reviewAction = find.descendant(
      of: actionBar,
      matching: find.text('Review order'),
    );
    expect(
      tester.getRect(summary).bottom,
      lessThanOrEqualTo(tester.getRect(actionBar).top),
    );
    expect(dockTotal, findsOneWidget);
    expect(reviewAction, findsOneWidget);
    expect(
      tester.getRect(actionBar).contains(tester.getRect(dockTotal).bottomRight),
      isTrue,
    );
    expect(
      tester
          .getRect(actionBar)
          .contains(tester.getRect(reviewAction).bottomRight),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('PAY-01 through PAY-09 fit Android and iOS viewport matrix', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    const viewports =
        <({String label, Size size, EdgeInsets safe, double scale})>[
          (
            label: 'compact Android',
            size: Size(320, 568),
            safe: EdgeInsets.symmetric(vertical: 24),
            scale: 1.4,
          ),
          (
            label: 'Redmi Android',
            size: Size(360, 800),
            safe: EdgeInsets.only(top: 34, bottom: 81),
            scale: 1,
          ),
          (
            label: 'large Android',
            size: Size(412, 915),
            safe: EdgeInsets.only(top: 32, bottom: 24),
            scale: 1.15,
          ),
          (
            label: 'iPhone SE',
            size: Size(375, 667),
            safe: EdgeInsets.only(top: 20),
            scale: 1,
          ),
          (
            label: 'iPhone',
            size: Size(390, 844),
            safe: EdgeInsets.only(top: 47, bottom: 34),
            scale: 1,
          ),
          (
            label: 'large iPhone',
            size: Size(430, 932),
            safe: EdgeInsets.only(top: 59, bottom: 34),
            scale: 1.2,
          ),
          (
            label: 'Android tablet',
            size: Size(600, 960),
            safe: EdgeInsets.only(top: 24, bottom: 24),
            scale: 1,
          ),
        ];

    for (final viewport in viewports) {
      tester.view.physicalSize = viewport.size;
      final session = BuyV2Session(core: BuySession());

      await tester.pumpWidget(
        app(
          session,
          textScale: viewport.scale,
          safePadding: viewport.safe,
          disableAnimations: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(session.addProduct('s-tomato'), isTrue);
      session.openCart(scope: BuyV2CartScope.shop);
      expect(session.openCheckout(), isTrue);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('buy-checkout-address-stage')),
        findsOneWidget,
        reason: viewport.label,
      );
      expect(
        find.byKey(const ValueKey('buy-checkout-primary-address')),
        findsOneWidget,
        reason: viewport.label,
      );
      expect(tester.takeException(), isNull, reason: viewport.label);

      expect(session.continueCheckoutFromAddress(), isTrue);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-checkout-payment-stage')),
        findsOneWidget,
        reason: viewport.label,
      );
      expect(
        find.byKey(const ValueKey('buy-checkout-primary-payment')),
        findsOneWidget,
        reason: viewport.label,
      );
      expect(find.text('Amount to MoolSocial'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: viewport.label);

      expect(session.continueCheckoutFromPayment(), isTrue);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-checkout-confirm-stage')),
        findsOneWidget,
        reason: viewport.label,
      );
      final confirmAction = find.byKey(
        const ValueKey('buy-checkout-primary-confirm'),
      );
      expect(confirmAction, findsOneWidget, reason: viewport.label);
      expect(
        tester.getRect(confirmAction).bottom,
        lessThanOrEqualTo(viewport.size.height - viewport.safe.bottom),
        reason: viewport.label,
      );
      expect(tester.takeException(), isNull, reason: viewport.label);

      expect(session.showCheckoutStep(BuyV2CheckoutStep.payment), isTrue);
      session.checkoutSubmissionState = BuyV2CheckoutSubmissionState.cancelled;
      session.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.text('Choose again'), findsOneWidget, reason: viewport.label);
      expect(find.textContaining('…'), findsNothing, reason: viewport.label);
      expect(tester.takeException(), isNull, reason: viewport.label);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      session.dispose();
    }
  });

  testWidgets('Payment primary action requires a currently available method', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);

    await tester.pumpWidget(app(session, disableAnimations: true));
    await tester.pumpAndSettle();
    expect(session.addProduct('s-tomato'), isTrue);
    session.openCart(scope: BuyV2CartScope.shop);
    expect(session.openCheckout(), isTrue);
    expect(session.continueCheckoutFromAddress(), isTrue);
    await tester.pumpAndSettle();
    session.selectedPayment = '';
    session.notifyListeners();
    await tester.pumpAndSettle();

    final action = find.byKey(const ValueKey('buy-checkout-primary-payment'));
    expect(session.selectedPayment, isEmpty);
    expect(session.checkoutSubmissionState, BuyV2CheckoutSubmissionState.idle);
    expect(session.checkoutBusy, isFalse);
    final disabledAction = tester.widget<FilledButton>(action);
    expect(disabledAction.child, isA<Text>());
    expect((disabledAction.child! as Text).data, 'Choose payment method');
    expect(disabledAction.onPressed, isNull);
    expect(
      tester
          .getSemantics(action)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isFalse,
    );

    session.selectedPayment = 'Purchase order';
    session.notifyListeners();
    await tester.pumpAndSettle();
    final ineligibleAction = tester.widget<FilledButton>(action);
    expect(ineligibleAction.child, isA<Text>());
    expect((ineligibleAction.child! as Text).data, 'Choose payment method');
    expect(ineligibleAction.onPressed, isNull);

    expect(session.choosePayment('PhonePe'), isTrue);
    await tester.pumpAndSettle();
    final enabledAction = tester.widget<FilledButton>(action);
    expect(enabledAction.child, isA<Text>());
    expect((enabledAction.child! as Text).data, 'Review order');
    expect(enabledAction.onPressed, isNotNull);
    expect(
      tester
          .getSemantics(action)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets(
    'checkout payment recovery states stay actionable at compact size',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);
      await tester.pumpWidget(app(session, textScale: 1.4));
      await tester.pumpAndSettle();
      session.addProduct('s-tomato');
      session.openCart(scope: BuyV2CartScope.shop);
      session.openCheckout();
      await tester.pumpAndSettle();
      await advanceCheckoutToPayment(tester, session);

      for (final state in const [
        BuyV2CheckoutSubmissionState.submitting,
        BuyV2CheckoutSubmissionState.paymentActionRequired,
        BuyV2CheckoutSubmissionState.paymentPending,
        BuyV2CheckoutSubmissionState.paymentUnknown,
        BuyV2CheckoutSubmissionState.cancelled,
        BuyV2CheckoutSubmissionState.failed,
        BuyV2CheckoutSubmissionState.unavailable,
      ]) {
        session.checkoutSubmissionState = state;
        session.notifyListeners();
        await tester.pump(const Duration(milliseconds: 120));

        expect(
          find.byKey(ValueKey('buy-checkout-payment-state-${state.name}')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull, reason: state.name);
        const actionKey = ValueKey('buy-checkout-primary-payment');
        expect(find.byKey(actionKey), findsOneWidget);
        expect(
          tester.getSize(find.byKey(actionKey)).height,
          greaterThanOrEqualTo(44),
        );
        if (state == BuyV2CheckoutSubmissionState.cancelled) {
          expect(find.text('Choose again'), findsOneWidget);
          expect(find.textContaining('…'), findsNothing);
        }
      }
    },
  );

  testWidgets('checkout renders only the fulfilment families being purchased', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    final shop = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    session.addProduct(shop.id);
    session.increase(shop.id);
    session.openCart(scope: BuyV2CartScope.shop);
    session.openCheckout();
    await tester.pumpAndSettle();
    expect(find.text('2 items'), findsOneWidget);
    await advanceCheckoutToConfirm(tester, session);

    expect(find.text('Deliveries'), findsOneWidget);
    expect(find.text('Shipment 1 · 1 product · 2 items'), findsOneWidget);
    expect(session.checkoutDestinations, {BuyV2Destination.shop});
    expect(session.checkoutFulfilmentGroups, hasLength(1));
    expect(
      find.byKey(
        ValueKey(
          'buy-checkout-confirm-delivery-${session.checkoutFulfilmentGroups.single.key}',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'T01C carries exact mixed delivery promises through one purchase',
    (tester) async {
      final adapter = _T01CMutableDeliveryFactsAdapter();
      final session = BuyV2Session(
        core: BuySession(),
        productFactsAdapter: adapter,
      );
      final shop = session.product('s-tomato');
      final wholesale = session.product('w-oil');
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();
      expect(session.addProduct(shop.id), isTrue);
      expect(session.addProduct(wholesale.id), isTrue);
      session.openCart();
      expect(session.openCheckout(), isTrue);
      await tester.pumpAndSettle();
      await advanceCheckoutToConfirm(tester, session);

      expect(find.text('Deliveries'), findsOneWidget);
      expect(
        find.textContaining('Delivery in 5 min · by 6:35 PM'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Delivery in 1 day · by tomorrow 4:00 PM'),
        findsOneWidget,
      );
      expect(find.text(shop.seller), findsNothing);
      expect(find.text(wholesale.seller), findsNothing);
      expect(
        find.byKey(const ValueKey('buy-checkout-primary-confirm')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('buy-checkout-primary-confirm')),
      );
      await tester.pumpAndSettle();
      await completeReviewPayment(tester, session);

      expect(find.text('Order placed'), findsOneWidget);
      expect(find.textContaining('2 products ·'), findsOneWidget);
      expect(find.textContaining('3 products ·'), findsNothing);
      expect(find.text('Your deliveries'), findsOneWidget);
      expect(find.text('Delivery 1 of 2'), findsOneWidget);
      expect(find.text('Delivery 2 of 2'), findsOneWidget);
      expect(
        find.text('Arrives · Delivery in 5 min · by 6:35 PM'),
        findsOneWidget,
      );
      expect(
        find.text('Arrives · Delivery in 1 day · by tomorrow 4:00 PM'),
        findsOneWidget,
      );
      expect(find.textContaining(shop.seller), findsWidgets);
      expect(find.textContaining(wholesale.seller), findsWidgets);
      final purchaseId = session.confirmedPurchaseId;
      expect(purchaseId, isNotNull);
      expect(session.confirmedOrders.map((order) => order.purchaseId).toSet(), {
        purchaseId,
      });
    },
  );

  testWidgets('T01C blocks and explains a changed pre-commit promise', (
    tester,
  ) async {
    final adapter = _T01CMutableDeliveryFactsAdapter();
    final session = BuyV2Session(
      core: BuySession(),
      productFactsAdapter: adapter,
    );
    final shop = session.product('s-tomato');
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    expect(session.addProduct(shop.id), isTrue);
    session.openCart();
    expect(session.openCheckout(), isTrue);
    await tester.pumpAndSettle();
    await advanceCheckoutToConfirm(tester, session);

    adapter.updateShop(promise: 'within 10 min', promisedBy: 'by 6:40 PM');
    await tester.tap(
      find.byKey(const ValueKey('buy-checkout-primary-confirm')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('buy-checkout-promise-change-review')),
      findsOneWidget,
    );
    expect(
      find.text('Previous · Delivery in 5 min · by 6:35 PM'),
      findsOneWidget,
    );
    expect(
      find.text('Updated · Delivery in 10 min · by 6:40 PM'),
      findsOneWidget,
    );
    expect(session.confirmedOrders, isEmpty);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Place order'),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(
      find.byKey(const ValueKey('buy-accept-updated-delivery-times')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-checkout-promise-change-review')),
      findsNothing,
    );
    await tester.tap(
      find.byKey(const ValueKey('buy-checkout-primary-confirm')),
    );
    await tester.pumpAndSettle();
    await completeReviewPayment(tester, session);
    expect(find.text('Order placed'), findsOneWidget);
    expect(
      find.text('Arrives · Delivery in 10 min · by 6:40 PM'),
      findsOneWidget,
    );
  });

  testWidgets(
    'order confirmation preserves family identifiers then opens Orders',
    (tester) async {
      final session = BuyV2Session(core: BuySession());
      final products = [
        BuyV2Catalogue.products.firstWhere(
          (item) => item.destination == BuyV2Destination.shop,
        ),
        BuyV2Catalogue.products.firstWhere(
          (item) => item.destination == BuyV2Destination.wholesale,
        ),
      ];
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();
      for (final product in products) {
        session.addProduct(product.id);
      }
      session.increase(products.first.id);
      session.openCart();
      session.openCheckout();
      await tester.pumpAndSettle();
      await advanceCheckoutToConfirm(tester, session);

      await tester.drag(find.byType(ListView).first, const Offset(0, -900));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('buy-checkout-primary-confirm')),
      );
      await tester.pumpAndSettle();
      await completeReviewPayment(tester, session);
      final purchaseId = session.confirmedPurchaseId!;

      expect(find.byKey(const ValueKey('buy-confirmation')), findsOneWidget);
      expect(find.text('Your deliveries'), findsOneWidget);
      expect(find.text('Delivery 1 of 2'), findsOneWidget);
      expect(find.text('Delivery 2 of 2'), findsOneWidget);
      expect(find.text('Delivery 3 of 3'), findsNothing);
      for (final order in session.confirmedOrders) {
        final placedOrder = find.byKey(
          ValueKey('buy-placed-order-${order.id}'),
        );
        expect(placedOrder, findsOneWidget);
        expect(
          find.descendant(
            of: placedOrder,
            matching: find.textContaining('Arrives · '),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: placedOrder,
            matching: find.textContaining('Delivered in'),
          ),
          findsNothing,
        );
      }
      expect(
        find.textContaining('Order reference · $purchaseId'),
        findsOneWidget,
      );
      expect(
        find.textContaining(session.confirmedOrders.first.partner),
        findsWidgets,
      );
      final shopOrder = session.confirmedOrders.firstWhere(
        (order) => order.destination == BuyV2Destination.shop,
      );
      final wholesaleOrder = session.confirmedOrders.firstWhere(
        (order) => order.destination == BuyV2Destination.wholesale,
      );
      expect(shopOrder.lines.single.product.id, products.first.id);
      expect(shopOrder.lines.single.quantity, 2);
      expect(wholesaleOrder.lines.single.product.id, products.last.id);
      expect(wholesaleOrder.lines.single.quantity, products.last.minimumOrder);

      final invoiceAction = find.byKey(
        ValueKey('buy-confirmation-invoice-${shopOrder.id}'),
      );
      await tester.ensureVisible(invoiceAction);
      await tester.tap(invoiceAction);
      await tester.pumpAndSettle();

      expect(
        find.byKey(ValueKey('buy-invoice-page-${shopOrder.id}')),
        findsOneWidget,
      );
      expect(find.text(products.first.title), findsOneWidget);
      expect(find.text('2×'), findsOneWidget);
      expect(find.byKey(const Key('mool-compact-launcher')), findsNothing);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-confirmation')), findsOneWidget);

      final ordersAction = find.byKey(
        const ValueKey('buy-confirmation-order-details'),
      );
      await tester.ensureVisible(ordersAction);
      await tester.tap(ordersAction);
      await tester.pumpAndSettle();
      expect(find.text('PURCHASES'), findsOneWidget);
      expect(
        find.byKey(ValueKey('buy-purchase-group-$purchaseId')),
        findsOneWidget,
      );
      expect(
        find.textContaining(session.confirmedOrders.first.id),
        findsWidgets,
      );
    },
  );

  test('Orders row keys stay unique when retained delivery IDs repeat', () {
    final keys = {
      buyV2OrderRowKey(
        groupIndex: 0,
        purchaseId: 'MS-PURCHASE-1',
        orderIndex: 0,
        orderId: 'MS-NEW-01',
      ),
      buyV2OrderRowKey(
        groupIndex: 1,
        purchaseId: 'MS-PURCHASE-2',
        orderIndex: 0,
        orderId: 'MS-NEW-01',
      ),
      buyV2OrderRowKey(
        groupIndex: 1,
        purchaseId: 'MS-PURCHASE-2',
        orderIndex: 1,
        orderId: 'MS-NEW-01',
      ),
    };

    expect(keys, hasLength(3));
    expect(keys.every((key) => key.endsWith('MS-NEW-01')), isTrue);
  });

  testWidgets('invoice download uses the placed-order document contract', (
    tester,
  ) async {
    BuyV2InvoiceDocument? requestedInvoice;
    final session = BuyV2Session(core: BuySession());
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    await tester.pumpWidget(
      app(
        session,
        disableAnimations: true,
        invoiceDownloader: (invoice) async {
          requestedInvoice = invoice;
          return BuyV2InvoiceDownloadOutcome.saved;
        },
      ),
    );
    await tester.pumpAndSettle();

    session.addProduct(product.id);
    session.increase(product.id);
    session.openCart(scope: BuyV2CartScope.shop);
    expect(session.openCheckout(), isTrue);
    expect(session.confirmOrder(), isTrue);
    await tester.pumpAndSettle();
    final order = session.confirmedOrders.single;

    final invoiceAction = find.byKey(
      ValueKey('buy-confirmation-invoice-${order.id}'),
    );
    await tester.ensureVisible(invoiceAction);
    await tester.tap(invoiceAction);
    await tester.pumpAndSettle();

    final download = find.byKey(ValueKey('buy-download-invoice-${order.id}'));
    await tester.scrollUntilVisible(
      download,
      240,
      scrollable: find.byType(Scrollable).last,
    );
    expect(download, findsOneWidget);
    expect(tester.getSize(download).height, 48);
    await tester.tap(download);
    await tester.pumpAndSettle();

    expect(requestedInvoice, isNotNull);
    expect(requestedInvoice!.order.id, order.id);
    expect(requestedInvoice!.order.lines.single.quantity, 2);
    expect(
      requestedInvoice!.suggestedFileName,
      'MoolSocial-invoice-${order.id}.pdf',
    );
    expect(find.text('Invoice saved to this device.'), findsOneWidget);
  });

  testWidgets(
    'Orders opens an honest full-page invoice at compact accessible size',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(
        app(session, textScale: 1.4, disableAnimations: true),
      );
      await tester.pumpAndSettle();
      session.openOrders();
      await tester.pumpAndSettle();
      final order = session.visibleOrders.first;

      final invoiceAction = find.byKey(
        ValueKey('buy-order-invoice-${order.id}'),
      );
      await tester.ensureVisible(invoiceAction);
      await tester.tap(invoiceAction);
      await tester.pumpAndSettle();

      final invoicePage = find.byKey(ValueKey('buy-invoice-page-${order.id}'));
      expect(invoicePage, findsOneWidget);
      expect(find.text('Order invoice'), findsOneWidget);
      expect(find.text(order.itemSummary), findsOneWidget);
      expect(find.byKey(const Key('mool-compact-launcher')), findsNothing);
      final invoiceCopy = tester
          .widgetList<Text>(
            find.descendant(of: invoicePage, matching: find.byType(Text)),
          )
          .map((text) => text.data ?? text.textSpan?.toPlainText() ?? '')
          .join(' ');
      expect(_forbiddenBuyCopy.hasMatch(invoiceCopy), isFalse);
      expect(tester.takeException(), isNull);

      final download = find.byKey(ValueKey('buy-download-invoice-${order.id}'));
      await tester.scrollUntilVisible(
        download,
        240,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.ensureVisible(download);
      await tester.pumpAndSettle();
      await tester.tap(download);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Invoice download is not available for this order yet. You can still view it here.',
        ),
        findsOneWidget,
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(session.destination, BuyV2Destination.orders);
      expect(session.view, BuyV2View.catalogue);
      expect(find.byKey(const PageStorageKey('buy-orders')), findsOneWidget);
    },
  );

  testWidgets('delivered Orders expose non-mutating order inspection', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    session.openOrders();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-orders-tab-delivered')));
    await tester.pumpAndSettle();

    expect(session.ordersTab, BuyV2OrdersTab.delivered);
    expect(find.text('Delivered'), findsWidgets);
    expect(find.text('View order'), findsWidgets);
    expect(find.text('Reorder'), findsNothing);
    expect(find.text('Track order'), findsNothing);
  });

  testWidgets('shared search filters Orders by an existing order ID', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    session.openDestination(BuyV2Destination.orders);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('buy-search-band')), findsOneWidget);
    expect(find.text('Search orders or ID'), findsOneWidget);
    expect(find.byKey(const ValueKey('buy-open-scanner')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('buy-search-control')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('buy-search-field')),
      'MS-240782',
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('buy-order-card-MS-240782')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-order-card-MS-240783')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('buy-order-card-MS-240784')),
      findsNothing,
    );
  });

  for (final textScale in [1.0, 2.0]) {
    testWidgets('R66 032 basket preview price and actions fit $textScale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      await tester.pumpWidget(
        app(
          session,
          textScale: textScale,
          safePadding: const EdgeInsets.only(bottom: 32),
          captureCart: const bool.fromEnvironment(
            'BUY_R66_MONTHLY_BASKET_CAPTURE',
          ),
        ),
      );
      await tester.pumpAndSettle();
      unawaited(
        showBuyV2HouseholdBasket(
          tester.element(find.byType(BuyV2Screen)),
          session,
        ),
      );
      await tester.pumpAndSettle();
      final sheet = find.byKey(
        const ValueKey('buy-household-basket-info-sheet'),
      );
      expect(find.text('Product subtotal ₹5,145'), findsOneWidget);
      expect(find.text('Save ₹415'), findsNothing);
      expect(find.text('12 products'), findsOneWidget);
      expect(find.text('21 packs'), findsOneWidget);
      expect(find.text('Quick · 6 products'), findsOneWidget);
      expect(find.text('Scheduled · 6 products'), findsOneWidget);
      for (final richText
          in find
              .descendant(of: sheet, matching: find.byType(RichText))
              .evaluate()) {
        final paragraph = richText.renderObject! as RenderParagraph;
        final painter = TextPainter(
          text: paragraph.text,
          textDirection: paragraph.textDirection,
          textScaler: paragraph.textScaler,
        )..layout(maxWidth: paragraph.size.width);
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(
          paragraph.size.height + .1,
          greaterThanOrEqualTo(painter.height),
        );
        painter.dispose();
      }
      await _captureR66MonthlyBasket(tester, '$textScale-price');
      final add = find.byKey(const ValueKey('buy-household-add-to-cart'));
      await tester.ensureVisible(add);
      await tester.pumpAndSettle();
      expect(tester.getRect(add).bottom, lessThanOrEqualTo(748));
      expect(tester.getSize(add).height, greaterThanOrEqualTo(44));
      await _captureR66MonthlyBasket(tester, '$textScale-actions');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(session.itemCount, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('R66 032 monthly basket keeps price groups and Shop Cart scope', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    expect(session.addProduct('w-notebook'), isTrue);
    final wholesaleQuantity = session.quantityFor('w-notebook');
    final wholesaleTotal = session.totalForDestination(
      BuyV2Destination.wholesale,
    );
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-promotion-shop-basket')));
    await tester.pumpAndSettle();
    final see = find.byKey(const ValueKey('buy-household-see-products'));
    await tester.ensureVisible(see);
    await tester.pumpAndSettle();
    await tester.tap(see);
    await tester.pumpAndSettle();
    expect(find.text('6 of 12 basket products · Quick'), findsOneWidget);
    expect(session.catalogueSaleTypeProducts.length, 6);
    await tester.tap(find.byKey(const ValueKey('buy-shop-sale-type-courier')));
    await tester.pumpAndSettle();
    expect(find.text('6 of 12 basket products · Scheduled'), findsOneWidget);
    expect(session.catalogueSaleTypeProducts.length, 6);

    Future<void> addBasket() async {
      unawaited(
        showBuyV2HouseholdBasket(
          tester.element(find.byType(BuyV2Screen)),
          session,
        ),
      );
      await tester.pumpAndSettle();
      final add = find.byKey(const ValueKey('buy-household-add-to-cart'));
      await tester.ensureVisible(add);
      await tester.pumpAndSettle();
      await tester.tap(add);
      await tester.pumpAndSettle();
    }

    await addBasket();
    expect(session.countForDestination(BuyV2Destination.shop), 21);
    expect(session.totalForDestination(BuyV2Destination.shop), 5145);
    expect(
      session.cartAcknowledgementForDestination(BuyV2Destination.shop),
      'Monthly basket ready · 12 products',
    );
    await addBasket();
    expect(session.countForDestination(BuyV2Destination.shop), 21);
    expect(session.quantityFor('w-notebook'), wholesaleQuantity);
    expect(
      session.totalForDestination(BuyV2Destination.wholesale),
      wholesaleTotal,
    );
    session.openCart(scope: BuyV2CartScope.shop);
    await tester.pumpAndSettle();
    expect(find.text('Monthly basket'), findsOneWidget);
    session.openCart(scope: BuyV2CartScope.wholesale);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Review order'));
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.checkout);
    for (final step in BuyV2CheckoutStep.values) {
      session.showCheckoutStep(step);
      await tester.pumpAndSettle();
      expect(session.checkoutScope, BuyV2CartScope.wholesale);
      expect(
        find.byKey(const ValueKey('buy-shopping-intent-bar')),
        findsNothing,
      );
      await captureR66Visual(tester, '032-wholesale-checkout-${step.name}');
    }
    session.openCart(scope: BuyV2CartScope.shop);
    await tester.pumpAndSettle();
    expect(find.text('Monthly basket'), findsOneWidget);
    expect(session.clearCartScope(BuyV2CartScope.shop), isTrue);
    await tester.pumpAndSettle();
    expect(session.quantityFor('w-notebook'), wholesaleQuantity);
    expect(find.byKey(const ValueKey('buy-shopping-intent-bar')), findsNothing);
    session.openDestination(BuyV2Destination.wholesale);
    await tester.pumpAndSettle();
    expect(session.catalogueSaleTypeProducts, isNotEmpty);
    expect(find.byKey(const ValueKey('buy-shopping-intent-bar')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final saved in [false, true]) {
    // Follow-up device cases preserve a manually moved Cart across actions.
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'R66 R2 Cart clears retained actions saved=$saved scale=$scale',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(360, 800);
          addTearDown(tester.view.reset);
          final core = BuySession();
          final session = BuyV2Session(core: core);
          addTearDown(core.dispose);
          addTearDown(session.dispose);
          session.addProduct('w-notebook');
          if (saved) session.addProduct('s-tomato');
          await tester.pumpWidget(app(session, textScale: scale));
          await tester.pumpAndSettle();
          if (saved) {
            session.toggleSaved('s-tomato');
            session.showSavedProducts(true);
          } else {
            session.openOrders();
            session.showOrdersTab(BuyV2OrdersTab.delivered);
          }
          await tester.pumpAndSettle();
          final order = session.orders.firstWhere(
            (order) => order.status == BuyV2OrderStatus.delivered,
          );
          final action = find.byKey(
            ValueKey(
              saved ? 'buy-saved-clear' : 'buy-order-primary-${order.id}',
            ),
          );
          await tester.ensureVisible(action);
          await tester.pumpAndSettle();
          final cart = find.byKey(const ValueKey('buy-compact-cart-indicator'));
          await tester.dragFrom(
            tester.getCenter(cart),
            tester.getCenter(action) - tester.getCenter(cart),
          );
          await tester.pumpAndSettle();
          expect(
            tester.getRect(cart).overlaps(tester.getRect(action)),
            isFalse,
          );
          await captureR66Visual(tester, '004-action-saved-$saved-text-$scale');
          await tester.tap(action);
          await tester.pumpAndSettle();
          if (saved) {
            expect(
              find.byKey(const ValueKey('buy-saved-clear-sheet')),
              findsOneWidget,
            );
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
          } else {
            expect(session.selectedOrderOrNull?.id, order.id);
            expect(session.view, BuyV2View.tracking);
          }
          expect(session.quantityFor('w-notebook'), 1);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }

  for (final destination in [
    BuyV2Destination.shop,
    BuyV2Destination.wholesale,
    BuyV2Destination.medicine,
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'R66 R3 Cart permits Save and Remove ${destination.name} $scale',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(800, 360);
          addTearDown(tester.view.reset);
          final core = BuySession();
          final session = BuyV2Session(core: core);
          addTearDown(core.dispose);
          addTearDown(session.dispose);
          session.addProduct('w-notebook');
          await tester.pumpWidget(app(session, textScale: scale));
          await tester.pumpAndSettle();
          session.openDestination(destination);
          final product = session.visibleProducts.first;
          expect(session.addProduct(product.id), isTrue);
          await tester.pumpAndSettle();
          for (final remove in [false, true]) {
            if (remove) session.showSavedProducts(true);
            await tester.pumpAndSettle();
            final actions = find.byKey(ValueKey('buy-save-${product.id}'));
            final action = actions.first;
            final scrollable = find
                .descendant(
                  of: find.byType(BuyV2CatalogueView),
                  matching: find.byWidgetPredicate(
                    (widget) =>
                        widget is Scrollable &&
                        widget.axisDirection == AxisDirection.down,
                  ),
                )
                .first;
            await tester.drag(scrollable, const Offset(0, -240));
            await tester.pumpAndSettle();
            for (var attempt = 0; attempt < 40; attempt += 1) {
              if (actions.evaluate().isEmpty) {
                await tester.drag(scrollable, const Offset(0, -60));
                await tester.pumpAndSettle();
                continue;
              }
              final rect = tester.getRect(action);
              final viewport = tester.getRect(
                find.byKey(const ValueKey('buy-cart-content-viewport')),
              );
              final toolbarBottom = tester
                  .getRect(find.byKey(const ValueKey('buy-catalogue-toolbar')))
                  .bottom;
              final top = toolbarBottom > viewport.top
                  ? toolbarBottom
                  : viewport.top;
              final bottom = viewport.bottom;
              if (rect.top >= top && rect.bottom <= bottom) break;
              await tester.drag(
                scrollable,
                Offset(0, rect.top < top ? 60 : -60),
              );
              await tester.pumpAndSettle();
            }
            expect(
              action.hitTestable(),
              findsOneWidget,
              reason: 'Reveal the action below the sticky catalogue controls',
            );
            final cart = find.byKey(
              const ValueKey('buy-compact-cart-indicator'),
            );
            final scrollBeforeDrag = tester
                .state<ScrollableState>(scrollable)
                .position
                .pixels;
            await tester.dragFrom(
              tester.getCenter(cart),
              tester.getCenter(action) - tester.getCenter(cart),
            );
            await tester.pumpAndSettle();
            expect(
              tester.state<ScrollableState>(scrollable).position.pixels,
              closeTo(scrollBeforeDrag, .01),
              reason: 'Dragging Cart must not scroll the catalogue beneath it',
            );
            expect(action.hitTestable(), findsOneWidget);
            final contentBounds = tester.getRect(
              find.byKey(const ValueKey('buy-cart-content-viewport')),
            );
            for (final region
                in find.byType(BuyV2CartAvoidanceRegion).evaluate()) {
              final box = region.renderObject! as RenderBox;
              if (!box.hasSize) continue;
              final visible = (box.localToGlobal(Offset.zero) & box.size)
                  .intersect(contentBounds);
              if (visible.isEmpty) continue;
              expect(
                tester.getRect(cart).overlaps(visible),
                isFalse,
                reason:
                    'Cart must clear every visible registered fact and action',
              );
            }
            await captureR66Visual(
              tester,
              '004-r3-${destination.name}-remove-$remove-text-$scale',
            );
            final overlapped = tester
                .getRect(cart)
                .overlaps(tester.getRect(action));
            expect(
              tester
                  .getRect(cart)
                  .overlaps(
                    tester.getRect(
                      find.byKey(const ValueKey('buy-catalogue-toolbar')),
                    ),
                  ),
              isFalse,
            );
            await tester.tapAt(tester.getCenter(action));
            await tester.pumpAndSettle();
            expect(
              session.isSaved(product.id),
              !remove,
              reason:
                  'The visible Save/Remove tap must reach the product action',
            );
            expect(session.view, BuyV2View.catalogue);
            expect(overlapped, isFalse);
            expect(session.quantityFor('w-notebook'), 1);
            expect(tester.takeException(), isNull);
          }
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }

  test('R66 R2 catalogue promises describe future delivery', () {
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(core.dispose);
    addTearDown(session.dispose);
    expect(session.product('s-tomato').deliveryPromise, 'Delivery in 12 min');
    expect(buyV2BuyerDeliveryPromiseSource('5 minutes'), 'Delivery in 5 min');
    expect(buyV2BuyerDeliveryPromiseSource('1 day'), 'Delivery in 1 day');
    for (final dispatch in ['Dispatch in one day', 'Dispatch in 2 days']) {
      expect(
        buyV2BuyerDeliveryPromiseSource(dispatch),
        dispatch,
        reason: 'Dispatch must not become an arrival promise',
      );
    }
    expect(
      buyV2BuyerDeliveryPromiseSource('Delivered in 12 min'),
      'Delivery in 12 min',
    );
    for (final product in BuyV2Catalogue.products) {
      expect(product.deliveryPromise.startsWith('Delivered'), isFalse);
    }
    session.chooseFilter('fast');
    expect(session.visibleProducts.map((p) => p.id), contains('s-tomato'));
    expect(
      session.orders
          .where((o) => o.status == BuyV2OrderStatus.delivered)
          .every((o) => o.promise.startsWith('Delivered')),
      isTrue,
    );
    for (final order in session.orders.where(
      (o) => o.status == BuyV2OrderStatus.delivered,
    )) {
      expect(buyV2OrderPromiseSummary(order).startsWith('Delivered'), isTrue);
    }
  });

  for (final missingCatalogue in [true, false]) {
    testWidgets(
      'R66 032 basket rejects unavailable products $missingCatalogue',
      (tester) async {
        final core = BuySession();
        final session = BuyV2Session(
          core: core,
          reviewDataEnabled: !missingCatalogue,
          productFactsAdapter: const _StoreStatusFactsAdapter(
            state: BuyV2StoreOperatingState.closed,
            nextOpeningLabel: 'tomorrow at 8:00 am',
          ),
        );
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        if (!missingCatalogue) {
          expect(session.addProduct('w-notebook'), isTrue);
        }
        final beforeCount = session.itemCount;
        await tester.pumpWidget(app(session));
        await tester.pumpAndSettle();
        unawaited(
          showBuyV2HouseholdBasket(
            tester.element(find.byType(BuyV2Screen)),
            session,
          ),
        );
        await tester.pumpAndSettle();
        expect(session.monthlyBasketCanAdd, isFalse);
        expect(
          tester
              .widget<FilledButton>(
                find.byKey(const ValueKey('buy-household-add-to-cart')),
              )
              .onPressed,
          isNull,
        );
        if (missingCatalogue) {
          expect(session.monthlyBasketPlan, isEmpty);
          expect(
            find.text('Basket prices are unavailable right now'),
            findsOneWidget,
          );
          expect(find.text('Product subtotal ₹5,145'), findsNothing);
        }
        session.addMonthlyBasket();
        expect(session.itemCount, beforeCount);
        expect(session.countForDestination(BuyV2Destination.shop), 0);
        expect(
          session.notice,
          'Some basket products are unavailable. Review products first.',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final destination in [
    BuyV2Destination.shop,
    BuyV2Destination.wholesale,
    BuyV2Destination.medicine,
  ]) {
    for (final textScale in [1.0, 2.0]) {
      testWidgets(
        'R66 landscape ${destination.name} $textScale retains usable product actions',
        (tester) async {
          final originalErrorHandler = FlutterError.onError;
          FlutterError.onError = (details) {
            debugPrint(details.toString());
            originalErrorHandler?.call(details);
          };
          addTearDown(() => FlutterError.onError = originalErrorHandler);
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(800, 360);
          final session = BuyV2Session(core: BuySession());
          await tester.pumpWidget(
            app(
              session,
              textScale: textScale,
              safePadding: const EdgeInsets.only(bottom: 32),
              captureCart: const bool.fromEnvironment(
                'BUY_R66_LANDSCAPE_CAPTURE',
              ),
            ),
          );
          await tester.pumpAndSettle();
          session.openDestination(destination);
          await tester.pumpAndSettle();

          final product = session.visibleProducts.first;
          session.openProduct(product.id);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'landscape product');
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.catalogue);

          final catalogue = find.byType(BuyV2CatalogueView);
          expect(tester.getSize(catalogue).width, greaterThan(700));
          final scrollable = find
              .descendant(
                of: catalogue,
                matching: find.byWidgetPredicate(
                  (widget) =>
                      widget is Scrollable &&
                      widget.axisDirection == AxisDirection.down,
                ),
              )
              .first;
          await tester.drag(scrollable, const Offset(0, -240));
          await tester.pumpAndSettle();
          final dockTop = tester
              .getRect(
                find.byKey(const Key('moolsocial-compact-destination-rail')),
              )
              .top;
          expect(
            dockTop - tester.getRect(scrollable).top,
            greaterThanOrEqualTo(180),
          );
          final add = find.byKey(ValueKey('buy-add-${product.id}'));
          for (var attempt = 0; attempt < 40; attempt += 1) {
            final visibleTop = tester.getRect(scrollable).top;
            var drag = -100.0;
            if (add.evaluate().isNotEmpty) {
              final rect = tester.getRect(add);
              if (rect.top >= visibleTop &&
                  rect.bottom <= dockTop &&
                  add.hitTestable().evaluate().isNotEmpty) {
                break;
              }
              if (rect.top < visibleTop) drag = 100;
            }
            await tester.drag(scrollable, Offset(0, drag));
            await tester.pumpAndSettle();
          }
          final selectedCard = tester.getRect(
            find.byKey(ValueKey('buy-product-${product.id}')),
          );
          expect(selectedCard.left, greaterThanOrEqualTo(0));
          expect(selectedCard.right, lessThanOrEqualTo(800));
          final action = tester.getRect(add);
          expect(action.height, greaterThanOrEqualTo(44));
          expect(action.width, greaterThanOrEqualTo(44));
          expect(
            action.top,
            greaterThanOrEqualTo(tester.getRect(scrollable).top),
          );
          expect(action.bottom, lessThanOrEqualTo(dockTop));
          expect(add.hitTestable(), findsOneWidget);
          await _captureR66Landscape(
            tester,
            '${destination.name}-$textScale-product-action',
          );
          await tester.tap(add);
          await tester.pumpAndSettle();
          expect(session.quantityFor(product.id), product.minimumOrder);
          final miniCart = find.byKey(
            const ValueKey('buy-compact-cart-indicator'),
          );
          expect(miniCart.hitTestable(), findsOneWidget);
          expect(tester.getRect(miniCart).bottom, lessThanOrEqualTo(dockTop));
          expect(
            tester.getRect(miniCart).top,
            greaterThanOrEqualTo(tester.getRect(catalogue).top),
          );
          final neighbours = session.visibleProducts.where((candidate) {
            if (candidate.id == product.id) return false;
            final control = find.byKey(ValueKey('buy-add-${candidate.id}'));
            if (control.evaluate().isEmpty) return false;
            final rect = tester.getRect(control);
            return rect.left >= 0 &&
                rect.right <= 800 &&
                rect.top >= tester.getRect(scrollable).top &&
                rect.bottom <= dockTop;
          }).toList();
          expect(neighbours, isNotEmpty);
          final neighbour = neighbours.first;
          final neighbourAdd = find.byKey(ValueKey('buy-add-${neighbour.id}'));
          expect(neighbourAdd, findsOneWidget);
          final neighbourAction = tester.getRect(neighbourAdd);
          expect(neighbourAction.left, greaterThanOrEqualTo(0));
          expect(neighbourAction.right, lessThanOrEqualTo(800));
          expect(
            neighbourAction.top,
            greaterThanOrEqualTo(tester.getRect(scrollable).top),
          );
          expect(neighbourAction.bottom, lessThanOrEqualTo(dockTop));
          for (final candidate in session.visibleProducts) {
            for (final key in [
              'buy-add-${candidate.id}',
              'buy-review-offer-${candidate.id}',
              'buy-featured-quantity-shell-${candidate.id}',
            ]) {
              final control = find.byKey(ValueKey(key));
              if (control.evaluate().isEmpty) continue;
              final rect = tester.getRect(control);
              if (rect.left < 0 ||
                  rect.right > 800 ||
                  rect.top < tester.getRect(scrollable).top ||
                  rect.bottom > dockTop) {
                continue;
              }
              expect(
                tester.getRect(miniCart).overlaps(rect),
                isFalse,
                reason: 'Floating Cart must leave $key available',
              );
            }
          }
          expect(neighbourAdd.hitTestable(), findsOneWidget);
          await _captureR66Landscape(
            tester,
            '${destination.name}-$textScale-cart-added',
          );
          await tester.tap(neighbourAdd);
          await tester.pumpAndSettle();
          expect(session.quantityFor(neighbour.id), neighbour.minimumOrder);
          expect(session.quantityFor(product.id), product.minimumOrder);
          final title = find.descendant(
            of: find.byKey(ValueKey('buy-product-${product.id}')),
            matching: find.text(product.title),
          );
          final facts = find
              .ancestor(of: title, matching: find.byType(Column))
              .first;
          await tester.drag(
            scrollable,
            Offset(
              0,
              tester.getRect(scrollable).top + 4 - tester.getRect(facts).top,
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester.getRect(facts).top,
            greaterThanOrEqualTo(tester.getRect(scrollable).top),
          );
          expect(tester.getRect(facts).bottom, lessThanOrEqualTo(dockTop));
          for (final text
              in find
                  .descendant(of: facts, matching: find.byType(RichText))
                  .evaluate()) {
            final paragraph = text.renderObject! as RenderParagraph;
            expect(
              paragraph.didExceedMaxLines,
              isFalse,
              reason: paragraph.text.toPlainText(),
            );
          }
          await _captureR66Landscape(
            tester,
            '${destination.name}-$textScale-product-facts',
          );
          if (destination == BuyV2Destination.wholesale) {
            final eta = find
                .descendant(of: facts, matching: find.byType(RichText))
                .last;
            expect(
              tester.renderObject<RenderParagraph>(eta).text.toPlainText(),
              contains(
                RegExp(
                  r'day|min|dispatch|delivery|at checkout',
                  caseSensitive: false,
                ),
              ),
            );
            await tester.scrollUntilVisible(eta, 60, scrollable: scrollable);
            await tester.pumpAndSettle();
            final visibleContent = tester.getRect(
              find.byKey(const ValueKey('buy-cart-content-viewport')),
            );
            final etaRect = tester.getRect(eta);
            expect(etaRect.top, greaterThanOrEqualTo(visibleContent.top));
            expect(etaRect.bottom, lessThanOrEqualTo(visibleContent.bottom));
            expect(tester.getRect(miniCart).overlaps(etaRect), isFalse);
            await _captureR66Landscape(
              tester,
              '${destination.name}-$textScale-delivery-visible',
            );
          }
          final nestedBefore = tester.state<NestedScrollViewState>(
            find.byType(NestedScrollView),
          );
          final outerOffset = nestedBefore.outerController.offset;
          final innerOffset = nestedBefore.innerController.offset;
          final factsTop = tester.getRect(facts).top;
          await tester.tap(miniCart);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'landscape Cart');
          expect(session.view, BuyV2View.cart);
          expect(find.byType(NestedScrollView), findsNothing);
          final cartScroll = scrollableWithin(
            PageStorageKey('buy-cart-${session.cartScope.name}'),
          );
          final review = find.widgetWithText(FilledButton, 'Review order');
          await tester.scrollUntilVisible(
            review,
            180,
            maxScrolls: 60,
            scrollable: cartScroll,
          );
          await tester.pumpAndSettle();
          final reviewRect = tester.getRect(review);
          expect(reviewRect.height, greaterThanOrEqualTo(44));
          expect(reviewRect.bottom, lessThanOrEqualTo(dockTop));
          expect(
            reviewRect.top,
            greaterThanOrEqualTo(tester.getRect(cartScroll).top),
          );
          expect(review.hitTestable(), findsOneWidget);
          await _captureR66Landscape(
            tester,
            '${destination.name}-$textScale-cart-review',
          );
          await tester.tap(review);
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.checkout);
          expect(tester.takeException(), isNull, reason: 'landscape checkout');
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.cart);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.catalogue);
          expect(session.destination, destination);
          expect(session.quantityFor(product.id), product.minimumOrder);

          final nestedAfter = tester.state<NestedScrollViewState>(
            find.byType(NestedScrollView),
          );
          expect(nestedAfter.outerController.offset, closeTo(outerOffset, 1));
          expect(nestedAfter.innerController.offset, closeTo(innerOffset, 1));
          expect(tester.getRect(facts).top, closeTo(factsTop, 1));

          final search = find.byKey(const ValueKey('buy-search-control'));
          await tester.scrollUntilVisible(search, -160, scrollable: scrollable);
          await tester.pumpAndSettle();
          expect(search.hitTestable(), findsOneWidget);
          await tester.tap(search);
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byKey(const ValueKey('buy-search-field')),
            product.title,
          );
          await tester.pumpAndSettle();
          expect(session.query, product.title);
          expect(tester.takeException(), isNull, reason: 'landscape search');
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          session.updateQuery('');
          await tester.pumpAndSettle();

          tester.view.physicalSize = const Size(360, 800);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'portrait rotation');
          expect(find.byType(NestedScrollView), findsNothing);
          expect(tester.getSize(catalogue).width, 360);
          expect(session.quantityFor(product.id), product.minimumOrder);
          tester.view.physicalSize = const Size(800, 360);
          await tester.pumpAndSettle();
          expect(tester.getSize(catalogue).width, greaterThan(700));
          expect(session.quantityFor(product.id), product.minimumOrder);
          session.clearCart();
          session.openCart();
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.catalogue);
          final otherProductId = destination == BuyV2Destination.shop
              ? 'w-notebook'
              : 's-tomato';
          session.addProduct(otherProductId);
          session.openCart(
            scope: BuyV2CartScope.values.byName(destination.name),
          );
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.cart);
          expect(session.cartLines, isEmpty);
          final browse = find.byKey(const ValueKey('buy-empty-cart-browse'));
          await tester.scrollUntilVisible(
            browse,
            120,
            scrollable: scrollableWithin(
              PageStorageKey('buy-cart-${session.cartScope.name}'),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.getRect(browse).height, greaterThanOrEqualTo(44));
          expect(tester.getRect(browse).bottom, lessThanOrEqualTo(dockTop));
          expect(browse.hitTestable(), findsOneWidget);
          await tester.tap(browse);
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.catalogue);
          expect(session.quantityFor(otherProductId), greaterThan(0));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('first-party promotions use established Buy actions', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-promotion-shop-basket')));
    await tester.pumpAndSettle();
    expect(find.text('Monthly home basket'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    session.openDestination(BuyV2Destination.wholesale);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('buy-promotion-wholesale-restock')),
    );
    await tester.pumpAndSettle();
    expect(session.selectedFilter, 'moq');

    session.openDestination(BuyV2Destination.medicine);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('buy-promotion-medicine-prescription')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Prescription centre'), findsWidgets);
    expect(find.byType(BottomSheet), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    session.openDestination(BuyV2Destination.orders);
    await tester.pumpAndSettle();
    final firstOrder = session.visibleOrders.first;
    expect(
      find.byKey(ValueKey('buy-order-card-${firstOrder.id}')),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('buy-orders-promotions')),
      180,
      scrollable: scrollableWithin(const PageStorageKey('buy-orders')),
    );
    expect(find.byKey(const ValueKey('buy-orders-promotions')), findsOneWidget);
  });

  testWidgets(
    'promotion and featured product remain usable at 320 and 140 percent',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session, textScale: 1.4));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('buy-catalogue-promotions')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('buy-featured-products')),
        findsOneWidget,
      );
      final product = session.visibleProducts.first;
      final dockTop = tester
          .getRect(find.byKey(const Key('moolsocial-compact-destination-rail')))
          .top;
      final card = find.byKey(ValueKey('buy-product-${product.id}'));
      expect(tester.getRect(card).top, lessThan(dockTop));
      final add = find.byKey(ValueKey('buy-add-${product.id}'));
      await tester.scrollUntilVisible(
        add,
        160,
        scrollable: find
            .descendant(
              of: find.byType(BuyV2CatalogueView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      final rect = tester.getRect(card);
      final action = tester.getRect(add);
      expect(action.height, 44);
      expect(action.width, greaterThanOrEqualTo(60));
      expect(rect.contains(action.center), isTrue);
      expect(action.bottom, lessThanOrEqualTo(dockTop));
      expect(add.hitTestable(), findsOneWidget);
      await tester.tap(add);
      await tester.pumpAndSettle();
      expect(session.quantityFor(product.id), 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('all six recovery states fit and return without an extra page', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session, textScale: 1.4));
    await tester.pumpAndSettle();

    for (final kind in BuyV2RecoveryKind.values) {
      session.openRecovery(kind);
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('buy-recovery-${kind.name}')), findsOneWidget);
      expect(tester.takeException(), isNull, reason: kind.name);
      await tester.tap(find.byKey(const ValueKey('buy-recovery-primary')));
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.catalogue);
    }
  });

  testWidgets('140 percent text fits every primary Buy state at 320 width', (
    tester,
  ) async {
    final originalErrorHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      debugPrint(details.toString());
      originalErrorHandler?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalErrorHandler);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session, textScale: 1.4));
    await tester.pumpAndSettle();

    final shop = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    final medicine = BuyV2Catalogue.products.firstWhere(
      (item) =>
          item.destination == BuyV2Destination.medicine &&
          !item.requiresPrescription,
    );
    for (final entry in <(String, VoidCallback)>[
      ('Shop', () => session.openDestination(BuyV2Destination.shop)),
      ('Wholesale', () => session.openDestination(BuyV2Destination.wholesale)),
      ('Medicine', () => session.openDestination(BuyV2Destination.medicine)),
      ('Product', () => session.openProduct(shop.id)),
      (
        'Cart',
        () {
          session.addProduct(shop.id);
          session.addProduct(medicine.id);
          session.openCart();
        },
      ),
      ('Checkout', session.openCheckout),
      ('Confirmation', session.confirmOrder),
      ('Orders', session.openOrders),
      (
        'Delivered Orders',
        () => session.showOrdersTab(BuyV2OrdersTab.delivered),
      ),
      ('Tracking', () => session.openTracking('MS-240782')),
      ('Assist', session.openAssist),
      (
        'Recovery',
        () => session.openRecovery(BuyV2RecoveryKind.networkInterruption),
      ),
    ]) {
      entry.$2();
      await tester.pumpAndSettle();
      final failure = tester.takeException();
      if (failure is FlutterError) {
        debugPrint(failure.toStringDeep());
      }
      expect(failure, isNull, reason: entry.$1);
      expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
    }
  });

  testWidgets('every primary Buy state contains only customer-facing copy', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    final shop = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    final wholesale = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.wholesale,
    );
    final medicine = BuyV2Catalogue.products.firstWhere(
      (item) =>
          item.destination == BuyV2Destination.medicine &&
          !item.requiresPrescription,
    );
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    for (final action in <VoidCallback>[
      () => session.openDestination(BuyV2Destination.shop),
      () => session.openDestination(BuyV2Destination.wholesale),
      () => session.openDestination(BuyV2Destination.medicine),
      () => session.openProduct(shop.id),
      () {
        session.addProduct(shop.id);
        session.addProduct(wholesale.id);
        session.addProduct(medicine.id);
        session.openCart();
      },
      session.openCheckout,
      session.confirmOrder,
      session.openOrders,
      () => session.showOrdersTab(BuyV2OrdersTab.delivered),
      () => session.openTracking('MS-240782'),
      session.openAssist,
      () => session.openRecovery(BuyV2RecoveryKind.paymentFailed),
    ]) {
      action();
      await tester.pumpAndSettle();
      _expectCustomerFacingBuyCopy(tester);
    }
  });

  testWidgets('Buy footer subactions keep one equal interaction geometry', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    final wholesale = find.byKey(const ValueKey('buy-local-tab-wholesale'));
    final orders = find.byKey(const ValueKey('buy-local-tab-orders'));
    final offers = find.byKey(const ValueKey('buy-local-tab-offers'));
    final rectangles = [
      tester.getRect(wholesale),
      tester.getRect(orders),
      tester.getRect(offers),
    ];

    for (final rectangle in rectangles.skip(1)) {
      expect(rectangle.width, closeTo(rectangles.first.width, .01));
      expect(rectangle.height, closeTo(rectangles.first.height, .01));
    }
    expect(rectangles.every((rect) => rect.height >= 44), isTrue);
    expect(
      rectangles[1].left - rectangles[0].right,
      closeTo(rectangles[2].left - rectangles[1].right, .01),
    );

    await tester.tap(wholesale);
    await tester.pumpAndSettle();
    expect(session.destination, BuyV2Destination.wholesale);
    expect(tester.widget<InkWell>(wholesale).onTap, isNotNull);
    await tester.tap(wholesale);
    await tester.pumpAndSettle();
    expect(session.destination, BuyV2Destination.wholesale);

    await tester.tap(orders);
    await tester.pumpAndSettle();
    expect(session.destination, BuyV2Destination.orders);
    expect(tester.widget<InkWell>(orders).onTap, isNotNull);
    await tester.tap(orders);
    await tester.pumpAndSettle();
    expect(session.destination, BuyV2Destination.orders);

    await tester.tap(offers);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-offers-publisher-summary')),
      findsOneWidget,
    );
    expect(tester.widget<InkWell>(offers).onTap, isNotNull);
    await tester.tap(offers);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-offers-publisher-summary')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'live Offers recover from offline without static production data',
    (tester) async {
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);
      final source = _LiveOffersSource(
        const BuyV2PublishedOffersSnapshot(
          state: BuyV2PublishedOffersLoadState.offline,
          customerMessage: 'Offers could not refresh.',
        ),
      );
      await tester.pumpWidget(app(session, offersSource: source));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers')));
      await tester.pumpAndSettle();

      expect(find.text('Offers could not refresh'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('buy-live-offers-retry')),
        findsOneWidget,
      );
      source.snapshot = const BuyV2PublishedOffersSnapshot(
        state: BuyV2PublishedOffersLoadState.ready,
        offers: [
          BuyV2PublishedOffer(
            productId: 's-tomato',
            publisherType: BuyV2OfferPublisherType.retailer,
            headline: 'Fresh price',
          ),
        ],
      );
      await tester.tap(find.byKey(const ValueKey('buy-live-offers-retry')));
      await tester.pumpAndSettle();

      expect(source.calls, 2);
      expect(
        find.byKey(const ValueKey('buy-offers-publisher-summary')),
        findsOneWidget,
      );
      expect(find.text('Fresh tomatoes'), findsWidgets);
    },
  );

  testWidgets('Offers accepts an ordered published catalogue seam', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    const source = _FixedOffersSource([
      BuyV2PublishedOffer(
        productId: 'w-rice',
        publisherType: BuyV2OfferPublisherType.wholesaler,
        headline: 'Published trade price',
      ),
      BuyV2PublishedOffer(
        productId: 'missing-product',
        publisherType: BuyV2OfferPublisherType.retailer,
        headline: 'Unavailable placement',
      ),
    ]);
    await tester.pumpWidget(app(session, offersSource: source));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('buy-product-w-rice')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('buy-product-missing-product')),
      findsNothing,
    );
    final grid = tester.widget<Semantics>(
      find.byKey(const ValueKey('buy-horizontal-product-grid')),
    );
    expect(grid.properties.label, contains('Showing 1 of 1'));
    expect(grid.properties.label, contains('Showing 1 of 1 product.'));
    expect(grid.properties.label, isNot(contains('loaded')));
  });

  testWidgets('Offers completes product Cart and Checkout navigation', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-product-w-oil')));
    await tester.pumpAndSettle();
    expect(session.selectedProduct?.id, 'w-oil');
    expect(session.view, BuyV2View.product);
    expect(find.text('Offers'), findsWidgets);
    expect(find.text('Wholesale'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('buy-product-primary-w-oil')));
    await tester.pumpAndSettle();
    expect(session.quantityFor('w-oil'), 2);

    await tester.tap(find.byKey(const ValueKey('buy-compact-cart-indicator')));
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.cart);
    expect(find.byKey(const ValueKey('buy-cart-browse-more')), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Review order'));
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.checkout);
    expect(
      find.byKey(const ValueKey('buy-checkout-action-bar')),
      findsOneWidget,
    );
  });

  for (final reducedMotion in [false, true]) {
    for (final size in [const Size(320, 844), const Size(640, 360)]) {
      testWidgets(
        'R669 Offers promotion category CTA Back $size reduced $reducedMotion',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          addTearDown(tester.view.reset);
          final core = BuySession();
          final session = BuyV2Session(core: core);
          addTearDown(core.dispose);
          addTearDown(session.dispose);
          const source = _FixedOffersSource([
            BuyV2PublishedOffer(
              publicationId: 'test-admin-rice',
              productId: 'w-rice',
              publisherType: BuyV2OfferPublisherType.moolSocial,
              publisherName: 'MoolSocial',
              headline: 'Rice buying offer',
            ),
            BuyV2PublishedOffer(
              publicationId: 'test-supplier-tomato',
              productId: 's-tomato',
              publisherType: BuyV2OfferPublisherType.retailer,
              publisherName: 'Test produce supplier',
              headline: 'Fresh produce offer',
            ),
          ]);
          await tester.pumpWidget(
            app(
              session,
              offersSource: source,
              textScale: 2,
              disableAnimations: reducedMotion,
              safePadding: const EdgeInsets.only(top: 24, bottom: 34),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers')));
          await tester.pumpAndSettle();
          expect(find.text('Rice buying offer'), findsOneWidget);
          expect(find.text('Published by MoolSocial'), findsOneWidget);
          expect(find.text('Makers'), findsNothing);
          expect(find.text('Categories'), findsNothing);
          final next = find.byKey(const ValueKey('buy-offer-promotion-next'));
          final previous = find.byKey(
            const ValueKey('buy-offer-promotion-previous'),
          );
          expect(tester.widget<IconButton>(previous).onPressed, isNull);
          await tester.ensureVisible(next);
          await tester.pumpAndSettle();
          expect(next.hitTestable(), findsOneWidget);
          await tester.tap(next);
          await tester.pump();
          final opacity = find.descendant(
            of: find.byKey(const ValueKey('buy-offer-promotion-motion')),
            matching: find.byType(Opacity),
          );
          expect(
            tester.widget<Opacity>(opacity).opacity,
            reducedMotion ? 1 : lessThan(1),
          );
          await tester.pump(const Duration(milliseconds: 500));
          expect(tester.widget<Opacity>(opacity).opacity, 1);
          expect(find.text('Rice buying offer'), findsNothing);
          expect(find.text('Fresh produce offer'), findsOneWidget);
          expect(
            find.text('Published by Test produce supplier'),
            findsOneWidget,
          );
          expect(tester.widget<IconButton>(next).onPressed, isNull);
          expect(session.featuredOfferPublicationId, 'test-supplier-tomato');
          final cta = find.byKey(
            const ValueKey('buy-offer-promotion-cta-s-tomato'),
          );
          await tester.ensureVisible(cta);
          await tester.pumpAndSettle();
          expect(cta.hitTestable(), findsOneWidget);
          expect(tester.getSize(cta).height, greaterThanOrEqualTo(48));
          await captureR66Visual(
            tester,
            'r669-offers-promotion-${size.width.toInt()}-$reducedMotion-cta',
          );
          await tester.tap(cta);
          await tester.pumpAndSettle();
          expect(session.selectedProductId, 's-tomato');
          expect(
            session.selectedProduct?.price,
            session.product('s-tomato').price,
          );
          expect(session.itemCount, 0);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(session.featuredOfferPublicationId, 'test-supplier-tomato');
          expect(find.text('Fresh produce offer'), findsOneWidget);
          await tester.ensureVisible(previous);
          await tester.pumpAndSettle();
          expect(previous.hitTestable(), findsOneWidget);
          await tester.tap(previous);
          await tester.pumpAndSettle();
          expect(find.text('Rice buying offer'), findsOneWidget);
          final categoryControl = find.byKey(
            const ValueKey('buy-offers-category-control'),
          );
          await tester.scrollUntilVisible(
            categoryControl,
            -120,
            scrollable: find
                .descendant(
                  of: find.byKey(const PageStorageKey('buy-offers')),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await tester.ensureVisible(categoryControl);
          await tester.pumpAndSettle();
          expect(
            find.descendant(
              of: categoryControl,
              matching: find.byIcon(Icons.grid_view_rounded),
            ),
            findsOneWidget,
          );
          final shopCategory = session.selectedCategoryId;
          await tester.tap(categoryControl);
          await tester.pumpAndSettle();
          final categoryId = session.product('s-tomato').categoryId;
          expect(categoryId, isNot(session.product('w-rice').categoryId));
          final category = find.byKey(
            ValueKey('buy-offers-category-$categoryId'),
          );
          await tester.scrollUntilVisible(
            category,
            100,
            scrollable: find
                .descendant(
                  of: find.byKey(const ValueKey('buy-offers-category-list')),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await tester.ensureVisible(category);
          await tester.pumpAndSettle();
          expect(category.hitTestable(), findsOneWidget);
          await tester.tap(category);
          await tester.pumpAndSettle();
          expect(session.finiteOffersCategoryId, categoryId);
          expect(session.selectedCategoryId, shopCategory);
          expect(find.text('Fresh produce offer'), findsOneWidget);
          expect(find.text('Rice buying offer'), findsNothing);
          expect(
            find.byKey(const ValueKey('buy-offer-promotion-next')),
            findsNothing,
          );
          await tester.ensureVisible(categoryControl);
          await tester.pumpAndSettle();
          await tester.tap(categoryControl);
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(const ValueKey('buy-offers-category-all')),
          );
          await tester.pumpAndSettle();
          expect(session.finiteOffersCategoryId, 'all');
          expect(find.text('Rice buying offer'), findsOneWidget);
          expect(session.itemCount, 0);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('Shop Orders excludes Care-owned Medicine and stale promises', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-local-tab-orders')));
    await tester.pumpAndSettle();

    expect(session.activeOrderCount, 2);
    expect(session.deliveredOrderCount, 2);
    expect(find.text('Medicine order'), findsNothing);
    expect(find.textContaining('29 Jul'), findsNothing);
    expect(find.textContaining('30 Jul'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Cart can return to Offers and add another product', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-add-w-oil')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-compact-cart-indicator')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-cart-browse-more')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-offers-publisher-summary')),
      findsOneWidget,
    );
    expect(session.quantityFor('w-oil'), 2);

    final tomatoAdd = find.byKey(const ValueKey('buy-add-s-tomato'));
    await tester.scrollUntilVisible(
      tomatoAdd,
      180,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('buy-offers')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(tomatoAdd);
    await tester.pumpAndSettle();
    await tester.tap(tomatoAdd);
    await tester.pumpAndSettle();
    expect(session.quantityFor('s-tomato'), 1);
    expect(session.itemCount, 3);
  });

  testWidgets('Shop Wholesale Orders and Offers page product grids', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('buy-featured-products')), findsOneWidget);
    expect(
      find.byKey(
        ValueKey('buy-featured-product-${session.visibleProducts.first.id}'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('buy-local-tab-wholesale')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-featured-products')), findsOneWidget);
    expect(
      find.byKey(
        ValueKey('buy-featured-product-${session.visibleProducts.first.id}'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('buy-local-tab-orders')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(
        const ValueKey('buy-progressive-product-count-buy-orders-products'),
      ),
      240,
      scrollable: scrollableWithin(const PageStorageKey('buy-orders')),
    );
    String progressLabel() => tester
        .widget<Semantics>(
          find.byKey(const ValueKey('buy-horizontal-product-grid')),
        )
        .properties
        .label!;
    expect(progressLabel(), contains('Showing 8 of 18'));

    await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers')));
    await tester.pumpAndSettle();
    expect(progressLabel(), contains('Showing 8 of 24'));
    await tester.fling(
      find.byKey(const ValueKey('buy-horizontal-product-lane-0')),
      const Offset(-1200, 0),
      2200,
    );
    await tester.pumpAndSettle();
    expect(progressLabel(), isNot(contains('Showing 8 of 24')));
    expect(progressLabel(), contains('of 24'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Offers search stays inside the published mixed catalogue', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-search-control')));
    await tester.pumpAndSettle();
    expect(find.text('Search current offers'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('buy-search-field')),
      'rice',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-product-w-rice')), findsOneWidget);
    expect(find.byKey(const ValueKey('buy-product-w-oil')), findsNothing);
    expect(
      find.byKey(const ValueKey('buy-offers-publisher-summary')),
      findsOneWidget,
    );
  });

  testWidgets(
    'store Add feedback Cart access and product return keep one browse path',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);
      var storeChatOpens = 0;
      await tester.pumpWidget(
        app(session, onOpenChat: () => storeChatOpens += 1),
      );
      await tester.pumpAndSettle();
      expect(session.openProduct('s-eggs'), isTrue);
      await tester.pumpAndSettle();
      final storeAction = find.byKey(
        const ValueKey('buy-shop-seller-action-s-eggs'),
      );
      await tester.scrollUntilVisible(
        storeAction,
        220,
        scrollable: scrollableWithin(
          const PageStorageKey('buy-product-s-eggs'),
        ),
      );
      await tester.pumpAndSettle();
      expect(storeAction.hitTestable(), findsOneWidget);
      await tester.tap(storeAction);
      await tester.pumpAndSettle();

      final storeSheet = find.byKey(
        const ValueKey('buy-shop-seller-sheet-s-eggs'),
      );
      expect(storeSheet, findsOneWidget);
      expect(find.text('MoolSocial Fulfilment Store'), findsOneWidget);
      expect(find.textContaining('Address confirmed'), findsOneWidget);
      final storeTruth = find.byKey(
        const ValueKey('buy-public-store-truth-s-eggs'),
      );
      expect(
        find.descendant(of: storeTruth, matching: find.text('Open')),
        findsNothing,
      );
      await tester.tap(
        find.descendant(
          of: storeTruth,
          matching: find.byKey(
            const ValueKey('buy-public-store-fulfilment-toggle'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Quick'), findsWidgets);
      final askStore = find.byKey(const ValueKey('buy-public-store-ask'));
      expect(askStore, findsOneWidget);
      expect(tester.getSize(askStore), const Size(78, 44));
      expect(
        tester
            .getSize(find.byKey(const ValueKey('buy-public-store-ask-visible')))
            .height,
        30,
      );
      await tester.tap(askStore);
      await tester.pumpAndSettle();
      expect(storeChatOpens, 1);
      expect(storeSheet, findsNothing);
      await tester.tap(storeAction);
      await tester.pumpAndSettle();
      expect(storeSheet, findsOneWidget);
      final storeScroll = find
          .descendant(of: storeSheet, matching: find.byType(Scrollable))
          .first;
      final emptyCartSku = find.byKey(const ValueKey('buy-product-s-chicken'));
      await tester.scrollUntilVisible(
        emptyCartSku,
        160,
        scrollable: storeScroll,
      );
      await tester.tap(emptyCartSku);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-store-cart-bar')), findsNothing);
      expect(find.text('Cart is empty'), findsNothing);
      await tester.tap(find.text('Back to Safe Protein Store'));
      await tester.pumpAndSettle();
      expect(storeSheet, findsOneWidget);
      final addChicken = find.byKey(const ValueKey('buy-add-s-chicken'));
      await tester.scrollUntilVisible(addChicken, 180, scrollable: storeScroll);
      await tester.tap(addChicken);
      await tester.pumpAndSettle();

      expect(session.quantityFor('s-chicken'), 1);
      expect(find.byKey(const ValueKey('buy-store-cart-bar')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('buy-store-cart-entrance-motion')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('buy-product-action-motion-s-chicken')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<BuyV2FiniteValueTransition>(
              find.byKey(const ValueKey('buy-store-cart-feedback')),
            )
            .text,
        '1 item',
      );

      final chicken = find.byKey(const ValueKey('buy-product-s-chicken'));
      await tester.ensureVisible(chicken);
      await tester.tap(chicken);
      await tester.pumpAndSettle();
      expect(session.selectedProductId, 's-chicken');
      expect(
        find.byKey(const ValueKey('buy-store-product-route-motion')),
        findsOneWidget,
      );
      expect(find.text('Back to Safe Protein Store'), findsOneWidget);
      expect(find.byKey(const ValueKey('buy-store-cart-bar')), findsOneWidget);

      await tester.tap(find.text('Back to Safe Protein Store'));
      await tester.pumpAndSettle();
      expect(storeSheet, findsOneWidget);
      expect(session.selectedProductId, 's-eggs');

      await tester.tap(find.byKey(const ValueKey('buy-store-cart-bar')));
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.cart);
      expect(
        find.byKey(const ValueKey('buy-cart-continue-store')),
        findsOneWidget,
      );
      expect(find.text('Continue browsing'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('buy-cart-continue-store-name')),
        findsOneWidget,
      );
      expect(find.text('Safe Protein Store'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('buy-cart-continue-store')));
      await tester.pumpAndSettle();
      expect(storeSheet, findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'store Chat keeps supplier context, Admin visibility and Buy return',
    () {
      final storeProduct = BuyV2Catalogue.products.firstWhere(
        (product) => product.id == 's-eggs',
      );
      final location = const BuyV2ChatRouteAdapter().storeQuestionLocationFor(
        anchor: storeProduct,
      );
      final uri = Uri.parse(location);

      expect(uri.path, contains('/app/chat/thread/'));
      expect(uri.queryParameters['context'], 'supplier-store');
      expect(uri.queryParameters['supplier'], 'Safe Protein Store');
      expect(uri.queryParameters['storeAnchorSku'], 's-eggs');
      expect(uri.queryParameters['adminVisible'], 'true');
      expect(uri.queryParameters['escalationReason'], 'supplier-non-response');
      expect(uri.queryParameters['callAuthority'], 'moolsocial-admin-only');
      final returnUri = Uri.parse(uri.queryParameters['return']!);
      expect(returnUri.path, '/app/buy');
      expect(returnUri.queryParameters['sub'], 'shop');
      expect(returnUri.queryParameters['view'], 'product');
      expect(returnUri.queryParameters['product'], 's-eggs');
    },
  );

  testWidgets('Chat return restores the exact store instead of product depth', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    expect(session.rememberStoreReturnAnchor('s-tomato'), isTrue);

    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: BuyV2Screen(
          session: session,
          initialDestination: BuyV2Destination.shop,
          initialView: BuyV2View.product,
          productId: 's-tomato',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(session.view, BuyV2View.catalogue);
    expect(session.selectedProductId, isNull);
    expect(
      find.byKey(const ValueKey('buy-shop-seller-sheet-s-tomato')),
      findsOneWidget,
    );
    expect(find.textContaining('Shree Balaji Fresh'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Android Back from store Chat restores the Cart-origin store', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    final router = GoRouter(
      initialLocation: '/buy',
      routes: [
        GoRoute(
          path: '/buy',
          builder: (context, state) => BuyV2Screen(session: session),
        ),
        GoRoute(
          path: '/app/chat/thread/:threadId',
          builder: (context, state) => const Scaffold(
            key: ValueKey('store-chat-route'),
            body: Text('Conversation'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: MoolTheme.light(), routerConfig: router),
    );
    await tester.pumpAndSettle();

    expect(session.openProduct('s-eggs'), isTrue);
    await tester.pumpAndSettle();
    final storeAction = find.byKey(
      const ValueKey('buy-shop-seller-action-s-eggs'),
    );
    await tester.scrollUntilVisible(
      storeAction,
      220,
      scrollable: scrollableWithin(const PageStorageKey('buy-product-s-eggs')),
    );
    await tester.pumpAndSettle();
    expect(storeAction.hitTestable(), findsOneWidget);
    await tester.tap(storeAction);
    await tester.pumpAndSettle();

    final storeSheet = find.byKey(
      const ValueKey('buy-shop-seller-sheet-s-eggs'),
    );
    final storeScroll = find
        .descendant(of: storeSheet, matching: find.byType(Scrollable))
        .first;
    final addChicken = find.byKey(const ValueKey('buy-add-s-chicken'));
    await tester.scrollUntilVisible(addChicken, 180, scrollable: storeScroll);
    await tester.tap(addChicken);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-store-cart-bar')));
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.cart);
    expect(session.cartScope, BuyV2CartScope.shop);

    await tester.tap(find.byKey(const ValueKey('buy-cart-continue-store')));
    await tester.pumpAndSettle();
    expect(storeSheet, findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('buy-public-store-ask')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('store-chat-route')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('store-chat-route')), findsNothing);
    expect(storeSheet, findsOneWidget);
    expect(session.view, BuyV2View.cart);
    expect(session.cartScope, BuyV2CartScope.shop);
    expect(session.quantityFor('s-chicken'), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('single-SKU Shop products expose owner and Visit store wiring', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    final tomato = session.product('s-tomato');
    expect(session.partnerCatalogueFor(tomato), hasLength(1));
    expect(session.openProduct(tomato.id), isTrue);
    await tester.pumpAndSettle();
    final storeAction = find.byKey(
      const ValueKey('buy-shop-seller-action-s-tomato'),
    );
    await tester.scrollUntilVisible(
      storeAction,
      220,
      scrollable: scrollableWithin(
        const PageStorageKey('buy-product-s-tomato'),
      ),
    );

    expect(storeAction, findsOneWidget);
    expect(
      find.textContaining(session.productFactsFor(tomato).partner),
      findsWidgets,
    );
    expect(storeAction.hitTestable(), findsOneWidget);
    await tester.tap(storeAction);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-shop-seller-sheet-s-tomato')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('buy-public-store-truth-s-tomato')),
        matching: find.textContaining('Retailer'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Verified retailer'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('master Shop and Wholesale cards show real provider owners', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    final shopCard = find.byKey(const ValueKey('buy-product-s-tomato'));
    expect(shopCard, findsOneWidget);
    expect(
      find.descendant(of: shopCard, matching: find.text('Shree Balaji Fresh')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: shopCard, matching: find.text('Retailer')),
      findsOneWidget,
    );

    session.openDestination(BuyV2Destination.wholesale);
    await tester.pumpAndSettle();
    final wholesaleCard = find.byKey(const ValueKey('buy-product-w-tomato'));
    expect(wholesaleCard, findsOneWidget);
    expect(
      find.descendant(
        of: wholesaleCard,
        matching: find.text('Jodhpur Fresh Supply'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: wholesaleCard, matching: find.text('Wholesaler')),
      findsOneWidget,
    );
    expect(find.textContaining('Verified retailer'), findsNothing);
    expect(find.textContaining('Verified wholesaler'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('View all keeps browsing depth and surfaces live Cart feedback', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    expect(session.openProduct('s-eggs'), isTrue);
    await tester.pumpAndSettle();

    final storeAction = find.byKey(
      const ValueKey('buy-shop-seller-action-s-eggs'),
    );
    await tester.scrollUntilVisible(
      storeAction,
      220,
      scrollable: scrollableWithin(const PageStorageKey('buy-product-s-eggs')),
    );
    await tester.pumpAndSettle();
    expect(storeAction.hitTestable(), findsOneWidget);
    await tester.tap(storeAction);
    await tester.pumpAndSettle();

    final storeSheet = find.byKey(
      const ValueKey('buy-shop-seller-sheet-s-eggs'),
    );
    final storeScroll = find
        .descendant(of: storeSheet, matching: find.byType(Scrollable))
        .first;
    final viewAll = find.byKey(
      const ValueKey('buy-shop-seller-view-more-s-eggs'),
    );
    await tester.scrollUntilVisible(viewAll, 180, scrollable: storeScroll);
    await tester.tap(viewAll);
    await tester.pumpAndSettle();

    final fullCatalogue = find.byKey(
      const ValueKey('buy-shop-seller-full-catalogue-list'),
    );
    final fullCatalogueSheet = find.byKey(
      const ValueKey('buy-shop-seller-full-catalogue-sheet'),
    );
    expect(fullCatalogue, findsOneWidget);
    expect(fullCatalogueSheet, findsOneWidget);
    await tester.tap(
      find.descendant(
        of: fullCatalogueSheet,
        matching: find.byKey(const ValueKey('buy-add-s-eggs')),
      ),
    );
    await tester.pumpAndSettle();
    expect(session.quantityFor('s-eggs'), 1);
    final fullCatalogueCart = find.descendant(
      of: fullCatalogueSheet,
      matching: find.byKey(const ValueKey('buy-store-cart-bar')),
    );
    expect(fullCatalogueCart, findsOneWidget);

    await tester.tap(
      find.descendant(
        of: fullCatalogueSheet,
        matching: find.byKey(const ValueKey('buy-product-s-eggs')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Back to Safe Protein Store'), findsOneWidget);
    await tester.tap(find.text('Back to Safe Protein Store'));
    await tester.pumpAndSettle();
    expect(fullCatalogue, findsOneWidget);

    await tester.tap(fullCatalogueCart);
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.cart);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Other stores cards carry decisions, motion and Back continuity',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);
      var storeChatOpens = 0;
      await tester.pumpWidget(
        app(session, onOpenChat: () => storeChatOpens += 1),
      );
      await tester.pumpAndSettle();
      expect(session.openProduct('s-eggs'), isTrue);
      await tester.pumpAndSettle();

      final storeAction = find.byKey(
        const ValueKey('buy-shop-seller-action-s-eggs'),
      );
      await tester.scrollUntilVisible(
        storeAction,
        220,
        scrollable: scrollableWithin(
          const PageStorageKey('buy-product-s-eggs'),
        ),
      );
      await tester.pumpAndSettle();
      expect(storeAction.hitTestable(), findsOneWidget);
      await tester.tap(storeAction);
      await tester.pumpAndSettle();

      final originalStore = find.byKey(
        const ValueKey('buy-shop-seller-sheet-s-eggs'),
      );
      final storeScroll = find
          .descendant(of: originalStore, matching: find.byType(Scrollable))
          .first;
      final relatedStore = find.byKey(
        const ValueKey('buy-shop-seller-other-store-s-tomato'),
      );
      await tester.scrollUntilVisible(
        relatedStore,
        180,
        scrollable: storeScroll,
      );
      final relatedStoreMotion = find.descendant(
        of: originalStore,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is BuyV2CinematicCardReveal &&
              widget.stateKey == 'buy-shop-seller-other-store-s-tomato-motion',
        ),
      );
      expect(relatedStoreMotion, findsOneWidget);
      expect(
        tester.widget<BuyV2CinematicCardReveal>(relatedStoreMotion).duration,
        const Duration(milliseconds: 780),
      );
      expect(
        tester.widget<BuyV2CinematicCardReveal>(relatedStoreMotion).delay,
        Duration.zero,
      );
      expect(
        tester
            .widget<BuyV2IntentDepth>(
              find.descendant(
                of: relatedStore,
                matching: find.byType(BuyV2IntentDepth),
              ),
            )
            .spatial,
        isFalse,
      );
      expect(
        tester
            .widget<Material>(
              find.byKey(const ValueKey('buy-related-store-surface-s-tomato')),
            )
            .color,
        Colors.transparent,
      );
      final relatedCard = tester.widget<Container>(
        find.byKey(const ValueKey('buy-related-store-card-s-tomato')),
      );
      final relatedDecoration = relatedCard.decoration! as BoxDecoration;
      expect(relatedDecoration.gradient, isNull);
      expect(relatedDecoration.color, Colors.white);
      expect(relatedDecoration.border, isNotNull);
      expect(relatedDecoration.boxShadow, isNotEmpty);
      expect(
        tester
            .widget<Container>(
              find.byKey(const ValueKey('buy-related-store-header-s-tomato')),
            )
            .decoration,
        isNull,
      );
      expect(tester.getSize(relatedStore).width, lessThanOrEqualTo(208));
      expect(tester.getSize(relatedStore).height, lessThan(170));
      expect(
        find.descendant(
          of: relatedStore,
          matching: find.text('MoolSocial Fulfilment Store · Retailer'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: relatedStore, matching: find.text('₹37')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: relatedStore, matching: find.text('Quick')),
        findsOneWidget,
      );

      await tester.tap(relatedStore);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-seller-sheet-s-tomato')),
        findsOneWidget,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(originalStore, findsOneWidget);

      await tester.tap(relatedStore);
      await tester.pumpAndSettle();
      final nestedStore = find.byKey(
        const ValueKey('buy-shop-seller-sheet-s-tomato'),
      );
      expect(nestedStore, findsOneWidget);
      await tester.tap(
        find.descendant(
          of: nestedStore,
          matching: find.byKey(const ValueKey('buy-public-store-ask')),
        ),
      );
      await tester.pumpAndSettle();
      expect(storeChatOpens, 1);
      expect(nestedStore, findsNothing);
      expect(originalStore, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Other store Cart closes both storefronts and opens Cart', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    final storeProduct = session.product('s-eggs');
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              key: const ValueKey('open-other-store-cart'),
              onPressed: () => unawaited(
                showBuyV2PartnerCatalogue(context, session, storeProduct),
              ),
              child: const Text('Open store'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open-other-store-cart')));
    await tester.pumpAndSettle();

    final originalStore = find.byKey(
      const ValueKey('buy-shop-seller-sheet-s-eggs'),
    );
    final storeScroll = find
        .descendant(of: originalStore, matching: find.byType(Scrollable))
        .first;
    final relatedStore = find.byKey(
      const ValueKey('buy-shop-seller-other-store-s-tomato'),
    );
    await tester.scrollUntilVisible(relatedStore, 180, scrollable: storeScroll);
    await tester.tap(relatedStore);
    await tester.pumpAndSettle();

    final nestedStore = find.byKey(
      const ValueKey('buy-shop-seller-sheet-s-tomato'),
    );
    final nestedRoute = find.byKey(
      const ValueKey('buy-shop-seller-route-s-tomato'),
    );
    await tester.tap(
      find.descendant(
        of: nestedStore,
        matching: find.byKey(const ValueKey('buy-add-s-tomato')),
      ),
    );
    await tester.pumpAndSettle();
    expect(session.quantityFor('s-tomato'), 1);
    final nestedCart = find.descendant(
      of: nestedRoute,
      matching: find.byKey(const ValueKey('buy-store-cart-bar')),
    );
    expect(nestedCart, findsOneWidget);
    await tester.tap(nestedCart);
    await tester.pumpAndSettle();

    expect(session.view, BuyV2View.cart);
    expect(nestedStore, findsNothing);
    expect(originalStore, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Other stores decisions fit 320px at 140 percent text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    final storeProduct = session.product('s-eggs');
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(textScaler: const TextScaler.linear(1.4)),
            child: child!,
          );
        },
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              key: const ValueKey('open-related-store-fitment'),
              onPressed: () => unawaited(
                showBuyV2PartnerCatalogue(context, session, storeProduct),
              ),
              child: const Text('Open store'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open-related-store-fitment')));
    await tester.pumpAndSettle();

    final storeSheet = find.byKey(
      const ValueKey('buy-shop-seller-sheet-s-eggs'),
    );
    final storeScroll = find
        .descendant(of: storeSheet, matching: find.byType(Scrollable))
        .first;
    final relatedStore = find.byKey(
      const ValueKey('buy-shop-seller-other-store-s-tomato'),
    );
    await tester.scrollUntilVisible(relatedStore, 150, scrollable: storeScroll);

    expect(
      find.byKey(const ValueKey('buy-shop-seller-other-stores')),
      findsOneWidget,
    );
    expect(
      tester.widget(find.byKey(const ValueKey('buy-shop-seller-other-stores'))),
      isA<SingleChildScrollView>(),
    );
    expect(tester.getSize(relatedStore).height, inInclusiveRange(140, 210));
    expect(tester.getSize(relatedStore).width, 208);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Other stores cinematic reveal respects reduced motion', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    final storeProduct = session.product('s-eggs');
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(disableAnimations: true),
            child: child!,
          );
        },
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              key: const ValueKey('open-related-store-reduced-motion'),
              onPressed: () => unawaited(
                showBuyV2PartnerCatalogue(context, session, storeProduct),
              ),
              child: const Text('Open store'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey('open-related-store-reduced-motion')),
    );
    await tester.pumpAndSettle();

    final storeSheet = find.byKey(
      const ValueKey('buy-shop-seller-sheet-s-eggs'),
    );
    final storeScroll = find
        .descendant(of: storeSheet, matching: find.byType(Scrollable))
        .first;
    final relatedStore = find.byKey(
      const ValueKey('buy-shop-seller-other-store-s-tomato'),
    );
    await tester.scrollUntilVisible(relatedStore, 150, scrollable: storeScroll);

    expect(
      tester
          .widget<Opacity>(
            find.byKey(
              const ValueKey(
                'buy-cinematic-card-content-'
                'buy-shop-seller-other-store-s-tomato-motion',
              ),
            ),
          )
          .opacity,
      1,
    );
    expect(
      tester
          .widget<Opacity>(
            find.byKey(
              const ValueKey(
                'buy-cinematic-card-sheen-'
                'buy-shop-seller-other-store-s-tomato-motion',
              ),
            ),
          )
          .opacity,
      0,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('closed store preserves truth and blocks unavailable Add', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(
      core: BuySession(),
      productFactsAdapter: const _StoreStatusFactsAdapter(
        state: BuyV2StoreOperatingState.closed,
        nextOpeningLabel: 'tomorrow at 8:00 am',
      ),
    );
    addTearDown(session.dispose);
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    expect(session.openProduct('s-eggs'), isTrue);
    await tester.pumpAndSettle();
    final storeAction = find.byKey(
      const ValueKey('buy-shop-seller-action-s-eggs'),
    );
    final productScroll = scrollableWithin(
      const PageStorageKey('buy-product-s-eggs'),
    );
    await tester.scrollUntilVisible(
      storeAction,
      220,
      scrollable: productScroll,
    );
    await tester.pumpAndSettle();
    expect(storeAction.hitTestable(), findsOneWidget);
    expect(tester.getCenter(storeAction).dy, lessThan(740));
    await tester.tap(storeAction);
    await tester.pumpAndSettle();

    expect(find.text('MoolSocial Fulfilment Store'), findsOneWidget);
    expect(find.text('Closed · Opens tomorrow at 8:00 am'), findsOneWidget);
    final storeSheet = find.byKey(
      const ValueKey('buy-shop-seller-sheet-s-eggs'),
    );
    final storeScroll = find
        .descendant(of: storeSheet, matching: find.byType(Scrollable))
        .first;
    final reviewChicken = find.byKey(
      const ValueKey('buy-review-offer-s-chicken'),
    );
    await tester.scrollUntilVisible(
      reviewChicken,
      160,
      scrollable: storeScroll,
    );
    expect(reviewChicken, findsOneWidget);
    expect(find.byKey(const ValueKey('buy-add-s-chicken')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no-products store preserves identity, status and Ask store', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession(), reviewDataEnabled: false);
    addTearDown(session.dispose);
    final storeProduct = BuyV2Catalogue.products.firstWhere(
      (product) => product.id == 's-eggs',
    );
    var askCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              key: const ValueKey('open-empty-public-store'),
              onPressed: () => unawaited(
                showBuyV2PartnerCatalogue(
                  context,
                  session,
                  storeProduct,
                  onAskStore: (_) => askCount += 1,
                ),
              ),
              child: const Text('Open store'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open-empty-public-store')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Safe Protein Store'), findsWidgets);
    expect(find.text('MoolSocial Fulfilment Store'), findsOneWidget);
    expect(find.text('Open'), findsNothing);
    await tester.tap(
      find.byKey(const ValueKey('buy-public-store-fulfilment-toggle')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('buy-public-store-no-products')),
      findsOneWidget,
    );
    expect(find.text('No products available right now.'), findsOneWidget);
    expect(find.byKey(const ValueKey('buy-add-s-eggs')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('buy-public-store-ask')));
    await tester.pumpAndSettle();
    expect(askCount, 1);
    expect(
      find.byKey(const ValueKey('buy-public-store-no-products')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('public store truth fits 320px at 140 percent text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    final storeProduct = BuyV2Catalogue.products.firstWhere(
      (product) => product.id == 's-eggs',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(textScaler: const TextScaler.linear(1.4)),
            child: child!,
          );
        },
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              key: const ValueKey('open-compact-public-store'),
              onPressed: () => unawaited(
                showBuyV2PartnerCatalogue(
                  context,
                  session,
                  storeProduct,
                  onAskStore: (_) {},
                ),
              ),
              child: const Text('Open store'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open-compact-public-store')));
    await tester.pumpAndSettle();

    final truth = find.byKey(const ValueKey('buy-public-store-truth-s-eggs'));
    expect(truth, findsOneWidget);
    final sheet = find.byKey(const ValueKey('buy-shop-seller-sheet-s-eggs'));
    final sheetScroll = find
        .descendant(of: sheet, matching: find.byType(Scrollable))
        .first;
    final ask = find.byKey(const ValueKey('buy-public-store-ask'));
    await tester.scrollUntilVisible(ask, 160, scrollable: sheetScroll);
    expect(tester.getSize(ask).height, greaterThanOrEqualTo(44));
    expect(find.text('MoolSocial Fulfilment Store'), findsOneWidget);
    expect(find.textContaining('Address confirmed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Masala Ghar storefront is compact and product-led', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    final storeProduct = session.product('s-turmeric');
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              key: const ValueKey('open-compact-masala-store'),
              onPressed: () => unawaited(
                showBuyV2PartnerCatalogue(
                  context,
                  session,
                  storeProduct,
                  onAskStore: (_) {},
                ),
              ),
              child: const Text('Open store'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open-compact-masala-store')));
    await tester.pumpAndSettle();

    final title = find.text('Store products').first;
    expect(tester.widget<Text>(title).style?.fontSize, 14);
    final route = find.byKey(
      const ValueKey('buy-shop-seller-route-s-turmeric'),
    );
    expect(tester.getTopLeft(route).dy, 0);
    expect(tester.getSize(route).height, 844);
    final header = find.byKey(const ValueKey('buy-shop-seller-sheet-header'));
    expect(tester.getSize(header).height, lessThanOrEqualTo(58));
    final truth = find.byKey(
      const ValueKey('buy-public-store-truth-s-turmeric'),
    );
    expect(tester.getSize(truth).height, lessThanOrEqualTo(112));
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('buy-public-store-ask'))).dy,
      lessThanOrEqualTo(tester.getTopLeft(truth).dy + 12),
    );
    final storeName = tester.widget<Text>(
      find.byKey(const ValueKey('buy-public-store-name')),
    );
    final storeLocation = tester.widget<Text>(
      find.byKey(const ValueKey('buy-public-store-location')),
    );
    expect(storeName.data, 'Masala Ghar');
    expect(storeName.maxLines, isNull);
    expect(storeLocation.maxLines, isNull);
    expect(
      find.byKey(const ValueKey('buy-public-store-fulfilment-details')),
      findsNothing,
    );
    final grid = find.byKey(const ValueKey('buy-horizontal-product-grid'));
    expect(grid, findsOneWidget);
    expect(
      tester.getTopLeft(grid).dy - tester.getBottomLeft(truth).dy,
      lessThanOrEqualTo(12),
    );
    for (final product in session.partnerCatalogueFor(storeProduct).take(3)) {
      final card = find
          .descendant(
            of: grid,
            matching: find.byKey(ValueKey('buy-product-${product.id}')),
          )
          .first;
      expect(card, findsOneWidget);
      expect(tester.getSize(card).height, lessThanOrEqualTo(232));
    }
    final viewAll = find.byKey(
      const ValueKey('buy-shop-seller-view-more-s-turmeric'),
    );
    expect(tester.getSize(viewAll).height, inInclusiveRange(44, 58));
    final visibleViewAll = find.byKey(
      const ValueKey('buy-shop-seller-view-more-visible-s-turmeric'),
    );
    expect(tester.getSize(visibleViewAll).height, lessThanOrEqualTo(18));
    expect(
      tester.getRect(header).contains(tester.getCenter(visibleViewAll)),
      isTrue,
    );
    final relatedTitle = tester.widget<Text>(find.text('Other stores'));
    expect(relatedTitle.style?.fontSize, 11.5);
    expect(
      tester.getTopLeft(find.text('Other stores')).dy -
          tester.getBottomLeft(grid).dy,
      lessThanOrEqualTo(14),
    );
    await tester.tap(
      find.byKey(const ValueKey('buy-public-store-fulfilment-toggle')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-public-store-fulfilment-details')),
      findsOneWidget,
    );
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Quick'), findsWidgets);
    await tester.tap(
      find.byKey(const ValueKey('buy-public-store-fulfilment-toggle')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-public-store-fulfilment-details')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Wholesale and Bulk provider storefront keeps Cart on SKU depth',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();
      session.openDestination(BuyV2Destination.wholesale);
      session.chooseWholesaleSaleType(BuyV2WholesaleSaleType.bulk);
      expect(session.openProduct('w-rice'), isTrue);
      await tester.pumpAndSettle();

      final supplierAction = find.byKey(
        const ValueKey('buy-wholesale-store-action-w-rice'),
      );
      final wholesaleProductScroll = scrollableWithin(
        const PageStorageKey('buy-product-w-rice'),
      );
      await tester.scrollUntilVisible(
        supplierAction,
        220,
        scrollable: wholesaleProductScroll,
      );
      await tester.drag(wholesaleProductScroll, const Offset(0, -140));
      await tester.pumpAndSettle();
      expect(tester.getCenter(supplierAction).dy, lessThan(700));
      await tester.tap(supplierAction);
      await tester.pumpAndSettle();

      final supplierSheet = find.byKey(
        const ValueKey('buy-wholesale-supplier-sheet-w-rice'),
      );
      expect(supplierSheet, findsOneWidget);
      expect(find.text('MoolSocial Fulfilment Partner'), findsOneWidget);
      expect(find.textContaining('Wholesaler'), findsWidgets);
      final supplierTruth = find.byKey(
        const ValueKey('buy-public-store-truth-w-rice'),
      );
      expect(
        find.descendant(of: supplierTruth, matching: find.text('Open')),
        findsNothing,
      );
      await tester.tap(
        find.descendant(
          of: supplierTruth,
          matching: find.byKey(
            const ValueKey('buy-public-store-fulfilment-toggle'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Bulk delivery'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('buy-public-store-ask-visible')),
          matching: find.text('Ask'),
        ),
        findsOneWidget,
      );

      final supplierSku = find.byKey(const ValueKey('buy-product-w-rice'));
      expect(supplierSku, findsOneWidget);
      await tester.tap(supplierSku);
      await tester.pumpAndSettle();
      expect(supplierSheet, findsNothing);
      expect(session.selectedProductId, 'w-rice');
      expect(find.byKey(const ValueKey('buy-store-cart-bar')), findsNothing);
      expect(find.text('Cart is empty'), findsNothing);
      final primary = find.byKey(const ValueKey('buy-product-primary-w-rice'));
      final productScroll = scrollableWithin(
        const PageStorageKey('buy-product-w-rice'),
      );
      await tester.scrollUntilVisible(primary, 220, scrollable: productScroll);
      await tester.tap(primary);
      await tester.pumpAndSettle();
      expect(session.quantityFor('w-rice'), greaterThanOrEqualTo(1));
      expect(find.byKey(const ValueKey('buy-store-cart-bar')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('buy-store-cart-bar')));
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.cart);
      expect(session.cartScope, BuyV2CartScope.wholesale);
      expect(
        find.byKey(const ValueKey('buy-cart-continue-store')),
        findsOneWidget,
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey('buy-cart-continue-store')))
            .height,
        56,
      );
      final returnName = tester.widget<Text>(
        find.byKey(const ValueKey('buy-cart-continue-store-name')),
      );
      expect(returnName.data, 'Thar Grains Wholesale');
      final returnNameFinder = find.byKey(
        const ValueKey('buy-cart-continue-store-name'),
      );
      expect(returnName.maxLines, isNull);
      expect(
        tester
            .renderObject<RenderParagraph>(returnNameFinder)
            .didExceedMaxLines,
        isFalse,
      );
      final returnBounds = tester.getRect(
        find.byKey(const ValueKey('buy-cart-continue-store')),
      );
      final nameBounds = tester.getRect(returnNameFinder);
      expect(nameBounds.left, greaterThanOrEqualTo(returnBounds.left));
      expect(nameBounds.right, lessThanOrEqualTo(returnBounds.right));
      expect(nameBounds.top, greaterThanOrEqualTo(returnBounds.top));
      expect(nameBounds.bottom, lessThanOrEqualTo(returnBounds.bottom));
      await tester.tap(find.byKey(const ValueKey('buy-cart-continue-store')));
      await tester.pumpAndSettle();
      expect(supplierSheet, findsOneWidget);
      expect(session.wholesaleSaleType, BuyV2WholesaleSaleType.bulk);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Shop Quick Scheduled and Wholesale Bulk swipe selectors wire catalogues',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);

      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();
      final shopSelector = find.byKey(
        const ValueKey('buy-shop-sale-type-selector'),
      );
      final shopThumb = find.byKey(const ValueKey('buy-shop-sale-type-thumb'));
      expect(shopSelector, findsOneWidget);
      expect(tester.getSize(shopSelector).height, 48);
      final quickThumbLeft = tester.getTopLeft(shopThumb).dx;
      expect(session.shopSaleType, BuyV2ShopSaleType.quickDelivery);
      expect(
        find.byKey(const ValueKey('buy-product-s-tomato')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('buy-product-s-atta')), findsNothing);
      expect(find.text('Quick'), findsOneWidget);
      expect(find.text('Scheduled'), findsOneWidget);

      await tester.fling(shopSelector, const Offset(-140, 0), 800);
      await tester.pumpAndSettle();
      expect(session.shopSaleType, BuyV2ShopSaleType.courier);
      expect(tester.getTopLeft(shopThumb).dx, greaterThan(quickThumbLeft));
      expect(find.byKey(const ValueKey('buy-product-s-tomato')), findsNothing);
      expect(find.byKey(const ValueKey('buy-product-s-atta')), findsOneWidget);
      expect(find.textContaining('Delivery today'), findsNothing);
      expect(find.textContaining('At checkout'), findsWidgets);

      await tester.tap(find.byKey(const ValueKey('buy-local-tab-wholesale')));
      await tester.pumpAndSettle();
      final wholesaleSelector = find.byKey(
        const ValueKey('buy-wholesale-sale-type-selector'),
      );
      expect(wholesaleSelector, findsOneWidget);
      expect(tester.getSize(wholesaleSelector).height, 48);
      expect(session.wholesaleSaleType, BuyV2WholesaleSaleType.wholesale);
      expect(
        find.byKey(const ValueKey('buy-product-w-tomato')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('buy-product-w-rice')), findsNothing);

      await tester.fling(wholesaleSelector, const Offset(-140, 0), 800);
      await tester.pumpAndSettle();
      expect(session.wholesaleSaleType, BuyV2WholesaleSaleType.bulk);
      expect(find.byKey(const ValueKey('buy-product-w-tomato')), findsNothing);
      expect(find.byKey(const ValueKey('buy-product-w-rice')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _captureR66Landscape(WidgetTester tester, String label) async {
  if (const bool.fromEnvironment('BUY_R663_VISUAL_CAPTURE')) {
    return captureR66Visual(tester, '001-$label');
  }
  if (!const bool.fromEnvironment('BUY_R66_LANDSCAPE_CAPTURE')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('r66-cart-capture')),
  );
  await tester.runAsync(() async {
    final directory = Directory('build/r66-landscape-v4-20260906');
    await directory.create(recursive: true);
    final output = File('${directory.path}/$label.png');
    if (await output.exists()) {
      throw StateError('Landscape capture already exists');
    }
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final data = await image.toByteData(format: ImageByteFormat.png);
      if (data == null) throw StateError('Landscape capture encoding failed');
      await output.writeAsBytes(data.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

Future<void> _captureR66MonthlyBasket(WidgetTester tester, String label) async {
  if (const bool.fromEnvironment('BUY_R663_VISUAL_CAPTURE')) {
    return captureR66Visual(tester, '032-$label');
  }
  if (!const bool.fromEnvironment('BUY_R66_MONTHLY_BASKET_CAPTURE')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('r66-cart-capture')),
  );
  await tester.runAsync(() async {
    final directory = Directory('build/r66-monthly-basket-v1-20260905');
    await directory.create(recursive: true);
    final output = File('${directory.path}/$label.png');
    if (await output.exists()) {
      throw StateError('Monthly basket capture already exists');
    }
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final data = await image.toByteData(format: ImageByteFormat.png);
      if (data == null) {
        throw StateError('Monthly basket capture encoding failed');
      }
      await output.writeAsBytes(data.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

// Display geometry only; real session arithmetic is covered by connected tests.
Future<void> _captureR66Cart(WidgetTester tester, String label) async {
  if (const bool.fromEnvironment('BUY_R663_VISUAL_CAPTURE')) {
    return captureR66Visual(tester, 'cart-$label');
  }
  if (!const bool.fromEnvironment('BUY_R66_CART_CAPTURE')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('r66-cart-capture')),
  );
  await tester.runAsync(() async {
    final directory = Directory('build/r66-cart-review-v1-20260905');
    await directory.create(recursive: true);
    final output = File('${directory.path}/$label.png');
    if (await output.exists()) {
      throw StateError('Cart capture already exists');
    }
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final data = await image.toByteData(format: ImageByteFormat.png);
      if (data == null) throw StateError('Cart capture encoding failed');
      await output.writeAsBytes(data.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

class _R66CartDisplayFixture extends BuyV2Session {
  _R66CartDisplayFixture(this.displayTotal) : super(core: BuySession());
  final int displayTotal;

  @override
  int totalForDestination(BuyV2Destination value) => displayTotal;

  @override
  int get cartTotal => displayTotal;
}

// Layout-only totals; arithmetic and real quantities use the session suites.
class _R668CartPayableFixture extends _R66CartDisplayFixture {
  _R668CartPayableFixture(super.displayTotal);

  @override
  int get scopedPayableTotal => displayTotal;
}

void _expectCustomerFacingBuyCopy(WidgetTester tester) {
  final root = find.byKey(const ValueKey('buy-v2-screen'));
  expect(root, findsOneWidget);
  final copy = <String>[];
  for (final text in tester.widgetList<Text>(
    find.descendant(of: root, matching: find.byType(Text)),
  )) {
    copy.add(text.data ?? text.textSpan?.toPlainText() ?? '');
  }
  for (final field in tester.widgetList<TextField>(
    find.descendant(of: root, matching: find.byType(TextField)),
  )) {
    copy.addAll([
      field.decoration?.labelText ?? '',
      field.decoration?.hintText ?? '',
      field.decoration?.helperText ?? '',
    ]);
  }
  for (final semantics in tester.widgetList<Semantics>(
    find.descendant(of: root, matching: find.byType(Semantics)),
  )) {
    copy.add(semantics.properties.label ?? '');
    copy.add(semantics.properties.hint ?? '');
  }
  final visible = copy.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  final match = _forbiddenBuyCopy.firstMatch(visible);
  expect(
    match,
    isNull,
    reason:
        'Forbidden customer-facing wording "${match?.group(0)}". '
        'Visible Buy copy: $visible',
  );
  expect(tester.takeException(), isNull);
}
