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

  for (final destination in const [
    BuyV2Destination.shop,
    BuyV2Destination.wholesale,
    BuyV2Destination.medicine,
  ]) {
    for (final size in const [Size(320, 700), Size(430, 932)]) {
      for (final scale in const [1.0, 1.4, 2.0]) {
        testWidgets(
          'featured ${destination.name} cards fit $size at $scale text',
          (tester) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = size;
            addTearDown(tester.view.reset);
            final core = BuySession();
            final session = BuyV2Session(core: core)
              ..openDestination(destination);
            addTearDown(session.dispose);
            addTearDown(core.dispose);
            await tester.pumpWidget(
              MaterialApp(
                theme: MoolTheme.light(),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale),
                    disableAnimations: true,
                  ),
                  child: child!,
                ),
                home: Scaffold(body: BuyV2CatalogueView(session: session)),
              ),
            );
            await tester.pumpAndSettle();
            final rail = find.byKey(
              const ValueKey('buy-featured-product-list'),
            );
            expect(rail, findsOneWidget);
            final scrollable = tester.state<ScrollableState>(
              find.descendant(of: rail, matching: find.byType(Scrollable)),
            );
            final seen = <String>{};
            for (var page = 0; page < 8; page++) {
              final cards = find.byWidgetPredicate(
                (widget) =>
                    widget is AnimatedScale &&
                    widget.key is ValueKey<String> &&
                    (widget.key! as ValueKey<String>).value.startsWith(
                      'buy-featured-product-',
                    ),
              );
              expect(cards, findsWidgets);
              for (final element in cards.evaluate().toList()) {
                final key = element.widget.key! as ValueKey<String>;
                final id = key.value.substring('buy-featured-product-'.length);
                seen.add(id);
                final product = session.product(id);
                final facts = session.productFactsFor(product);
                final card = find.byKey(key);
                final bounds = tester.getRect(card);
                expect(bounds.width, scale > 1.3 ? 178 : 168);
                for (final text in [
                  product.title,
                  product.pack,
                  facts.partner,
                ]) {
                  final field = find.descendant(
                    of: card,
                    matching: find.text(text),
                  );
                  expect(field, findsOneWidget);
                  final fieldBounds = tester.getRect(field);
                  expect(fieldBounds.top, greaterThanOrEqualTo(bounds.top));
                  expect(
                    fieldBounds.bottom,
                    lessThanOrEqualTo(bounds.bottom + .01),
                    reason: '$id: $text stays inside the card',
                  );
                }
                final action = find.descendant(
                  of: card,
                  matching: find.byWidgetPredicate(
                    (widget) =>
                        widget.key == ValueKey('buy-add-$id') ||
                        widget.key == ValueKey('buy-review-offer-$id'),
                  ),
                );
                expect(action, findsOneWidget);
                final actionBounds = tester.getRect(action);
                expect(actionBounds.height, greaterThanOrEqualTo(44));
                expect(actionBounds.width, greaterThanOrEqualTo(44));
                expect(actionBounds.top, greaterThanOrEqualTo(bounds.top));
                expect(actionBounds.bottom, lessThanOrEqualTo(bounds.bottom));
              }
              expect(tester.takeException(), isNull);
              final position = scrollable.position;
              if (position.pixels >= position.maxScrollExtent) break;
              position.jumpTo(
                (position.pixels + size.width * .75).clamp(
                  0.0,
                  position.maxScrollExtent,
                ),
              );
              await tester.pumpAndSettle();
            }
            expect(seen.length, greaterThan(1));
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

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
        expect(firstRect.height, inInclusiveRange(235, 239));

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
            matching: find.textContaining('Quick local'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: firstCard, matching: find.textContaining('10m')),
          findsNothing,
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
    expect(tester.getSize(firstCard).height, inInclusiveRange(295, 299));
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
      expect(tester.getSize(card).height, inInclusiveRange(235, 239));
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
        find.descendant(of: card, matching: find.text('Retailer')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text(product.unitPrice)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.textContaining('Quick local')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.textContaining('10m')),
        findsNothing,
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
        find.descendant(of: card, matching: find.text('Retailer')),
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
