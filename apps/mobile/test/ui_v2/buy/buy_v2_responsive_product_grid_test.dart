import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_catalogue.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app({
    required BuyV2Session session,
    required List<BuyV2Product> products,
    required Size size,
    required double textScale,
  }) {
    return MaterialApp(
      theme: MoolTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          body: BuyV2ProgressiveProductGrid(
            session: session,
            products: products,
            storageKey: 'responsive-product-grid-test',
            semanticLabel: 'Responsive product cards',
          ),
        ),
      ),
    );
  }

  testWidgets(
    'phone widths keep three complete founder-approved product cards',
    (tester) async {
      for (final size in const [
        Size(320, 700),
        Size(360, 800),
        Size(430, 932),
      ]) {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        final core = BuySession();
        final session = BuyV2Session(core: core);
        final products = BuyV2Catalogue.products
            .where((product) => product.destination == BuyV2Destination.shop)
            .take(6)
            .toList(growable: false);

        await tester.pumpWidget(
          app(session: session, products: products, size: size, textScale: 1),
        );
        await tester.pumpAndSettle();

        final firstCard = find.byKey(ValueKey('buy-product-${products[0].id}'));
        expect(firstCard, findsOneWidget, reason: '$size first card');
        final firstRect = tester.getRect(firstCard);
        expect(
          firstRect.width,
          greaterThanOrEqualTo(95),
          reason: '$size width',
        );
        for (final index in const [0, 2, 4]) {
          final card = find.byKey(
            ValueKey('buy-product-${products[index].id}'),
          );
          expect(card, findsOneWidget, reason: '$size product $index');
          expect(
            tester.getRect(card).right,
            lessThanOrEqualTo(size.width - 12),
            reason: '$size product $index fully visible',
          );
        }
        expect(firstRect.height, inInclusiveRange(254, 256));

        final title = tester.widget<Text>(
          find
              .descendant(of: firstCard, matching: find.text(products[0].title))
              .first,
        );
        final pack = tester.widget<Text>(
          find
              .descendant(of: firstCard, matching: find.text(products[0].pack))
              .first,
        );
        expect(title.style?.fontSize, greaterThanOrEqualTo(10));
        expect(title.maxLines, 3);
        expect(title.overflow, TextOverflow.clip);
        expect(pack.style?.fontSize, greaterThanOrEqualTo(8.5));
        expect(
          find.descendant(
            of: firstCard,
            matching: find.text(products[0].seller),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: firstCard,
            matching: find.text(products[0].unitPrice),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: firstCard,
            matching: find.textContaining('12 min'),
          ),
          findsOneWidget,
        );
        final add = find.descendant(
          of: firstCard,
          matching: find.byKey(ValueKey('buy-add-shell-${products[0].id}')),
        );
        expect(
          firstRect.bottom - tester.getRect(add).bottom,
          lessThanOrEqualTo(4),
          reason: '$size must not leave a dead block below Add',
        );
        expect(tester.takeException(), isNull, reason: '$size overflow');

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        session.dispose();
        core.dispose();
      }
      tester.view.reset();
    },
  );

  testWidgets('large text retains two lanes and complete minimum tap actions', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    addTearDown(tester.view.reset);
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    final products = BuyV2Catalogue.products
        .where((product) => product.destination == BuyV2Destination.wholesale)
        .take(6)
        .toList(growable: false);

    await tester.pumpWidget(
      app(
        session: session,
        products: products,
        size: const Size(320, 700),
        textScale: 1.4,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('buy-horizontal-product-lane-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-horizontal-product-lane-1')),
      findsOneWidget,
    );
    final firstCard = find.byKey(ValueKey('buy-product-${products[0].id}'));
    expect(tester.getSize(firstCard).height, inInclusiveRange(318, 320));
    final add = find.descendant(
      of: firstCard,
      matching: find.byKey(ValueKey('buy-add-shell-${products[0].id}')),
    );
    expect(tester.getSize(add).height, greaterThanOrEqualTo(44));
    final completePromise = tester.widget<Text>(
      find
          .descendant(of: firstCard, matching: find.textContaining('10:30'))
          .first,
    );
    expect(completePromise.maxLines, 3);
    expect(completePromise.overflow, TextOverflow.clip);
    final oneDayCard = find.byKey(ValueKey('buy-product-${products[2].id}'));
    expect(
      find.descendant(of: oneDayCard, matching: find.textContaining('1 day')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: oneDayCard,
        matching: find.textContaining('within one day'),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide catalogue admits three cards without compressing content', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(520, 900);
    addTearDown(tester.view.reset);
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    final products = BuyV2Catalogue.products
        .where((product) => product.destination == BuyV2Destination.shop)
        .take(6)
        .toList(growable: false);

    await tester.pumpWidget(
      app(
        session: session,
        products: products,
        size: const Size(520, 900),
        textScale: 1,
      ),
    );
    await tester.pumpAndSettle();

    for (final index in const [0, 2, 4]) {
      final card = find.byKey(ValueKey('buy-product-${products[index].id}'));
      expect(card, findsOneWidget);
      expect(tester.getSize(card).width, greaterThanOrEqualTo(160));
      expect(tester.getSize(card).height, inInclusiveRange(254, 256));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Fresh picks keeps store and delivery on separate complete lines',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          home: BuyV2Screen(session: session),
        ),
      );
      await tester.pumpAndSettle();

      final product = session.product('s-tomato');
      final card = find.byKey(ValueKey('buy-product-${product.id}')).first;
      expect(card, findsOneWidget);
      expect(
        find.descendant(of: card, matching: find.text(product.seller)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text(product.sellerType)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text(product.unitPrice)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.textContaining('12 min')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Fresh picks preserves complete seller facts at 140 percent text',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.reset);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 800),
              textScaler: TextScaler.linear(1.4),
            ),
            child: BuyV2Screen(session: session),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final product = session.product('s-tomato');
      final card = find.byKey(ValueKey('buy-product-${product.id}')).first;
      expect(
        find.descendant(of: card, matching: find.text(product.seller)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text(product.sellerType)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text(product.unitPrice)),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
