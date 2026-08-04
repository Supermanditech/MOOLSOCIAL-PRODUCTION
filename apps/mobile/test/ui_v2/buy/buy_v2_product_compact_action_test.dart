import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(
    BuyV2Session session,
    BuyV2Product product, {
    double textScale = 1,
    bool disableAnimations = false,
  }) {
    return MaterialApp(
      theme: MoolTheme.light(),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: disableAnimations,
          ),
          child: child!,
        );
      },
      home: BuyV2Screen(
        session: session,
        initialDestination: product.destination,
        initialView: BuyV2View.product,
        productId: product.id,
      ),
    );
  }

  Future<void> setSurface(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  Finder productScrollable(BuyV2Product product) {
    return find
        .descendant(
          of: find.byKey(PageStorageKey('buy-product-${product.id}')),
          matching: find.byType(Scrollable),
        )
        .first;
  }

  testWidgets(
    'zero-quantity Add is compact explicit and product-specific in every vertical',
    (tester) async {
      await setSurface(tester, const Size(390, 844));

      for (final destination in const [
        BuyV2Destination.shop,
        BuyV2Destination.wholesale,
        BuyV2Destination.medicine,
      ]) {
        final session = BuyV2Session(core: BuySession());
        final product = BuyV2Catalogue.products.firstWhere(
          (item) =>
              item.destination == destination && !item.requiresPrescription,
        );
        await tester.pumpWidget(app(session, product));
        await tester.pumpAndSettle();

        final panel = find.byKey(
          ValueKey('buy-product-inline-action-${product.id}'),
        );
        await tester.scrollUntilVisible(
          panel,
          220,
          scrollable: productScrollable(product),
        );
        await tester.pumpAndSettle();
        final shell = find.byKey(
          ValueKey('buy-product-add-shell-${product.id}'),
        );
        final slot = find.byKey(
          ValueKey('buy-product-action-slot-${product.id}'),
        );
        final primary = find.byKey(
          ValueKey('buy-product-primary-${product.id}'),
        );

        expect(
          find.byKey(const ValueKey('buy-product-action-bar')),
          findsNothing,
        );
        expect(tester.getSize(slot), const Size(148, 44));
        expect(tester.getSize(shell), const Size(88, 44));
        expect(tester.getTopRight(shell), tester.getTopRight(slot));
        expect(tester.getSize(primary).height, greaterThanOrEqualTo(44));
        expect(find.descendant(of: panel, matching: shell), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(ValueKey('buy-product-title-reveal-${product.id}')),
            matching: panel,
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: panel,
            matching: find.text(buyV2Money(product.price)),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: primary,
            matching: find.byIcon(Icons.add_rounded),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: primary, matching: find.text('Add')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: primary, matching: find.text(product.title)),
          findsNothing,
        );
        expect(
          find.byKey(ValueKey('buy-product-action-title-${product.id}')),
          findsNothing,
        );
        expect(find.text(product.title), findsOneWidget);
        expect(
          tester
              .getSemantics(primary)
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isTrue,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('real quantity uses compact independent 44px controls', (
    tester,
  ) async {
    await setSurface(tester, const Size(390, 844));
    final session = BuyV2Session(core: BuySession());
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    await tester.pumpWidget(app(session, product));
    await tester.pumpAndSettle();

    final panel = find.byKey(
      ValueKey('buy-product-inline-action-${product.id}'),
    );
    await tester.scrollUntilVisible(
      panel,
      220,
      scrollable: productScrollable(product),
    );
    await tester.pumpAndSettle();

    final slot = find.byKey(ValueKey('buy-product-action-slot-${product.id}'));
    final slotSizeBefore = tester.getSize(slot);
    final slotOriginBefore = tester.getTopLeft(slot);
    final addShell = find.byKey(
      ValueKey('buy-product-add-shell-${product.id}'),
    );
    await tester.tap(find.byKey(ValueKey('buy-product-primary-${product.id}')));
    await tester.pump();

    final enteringSlide = find.descendant(
      of: slot,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is SlideTransition && widget.position.value.dx > 0.02,
        description: 'incoming product-action transform-only acknowledgement',
      ),
    );
    expect(addShell, findsNothing);
    expect(
      find.byKey(ValueKey('buy-product-quantity-${product.id}')),
      findsOneWidget,
    );
    expect(enteringSlide, findsOneWidget);
    final incomingTransition = tester.widget<SlideTransition>(enteringSlide);
    expect(incomingTransition.position.value.dx, closeTo(0.025, 0.001));
    expect(incomingTransition.transformHitTests, isFalse);
    expect(
      find.descendant(
        of: slot,
        matching: find.byWidgetPredicate(
          (widget) => widget is FadeTransition && widget.opacity.value < 0.999,
          description: 'active product-action opacity layer',
        ),
      ),
      findsNothing,
    );
    await tester.pumpAndSettle();

    final stepper = find.byKey(ValueKey('buy-product-quantity-${product.id}'));
    final remove = find.descendant(
      of: stepper,
      matching: find.byTooltip('Remove one'),
    );
    final add = find.descendant(
      of: stepper,
      matching: find.byTooltip('Add one'),
    );
    expect(slotSizeBefore, const Size(148, 44));
    expect(tester.getSize(slot), slotSizeBefore);
    expect(tester.getTopLeft(slot), slotOriginBefore);
    expect(tester.getSize(stepper), const Size(148, 44));
    expect(tester.getTopRight(stepper), tester.getTopRight(slot));
    expect(incomingTransition.position.value, Offset.zero);
    expect(tester.getSize(remove), const Size(44, 44));
    expect(tester.getSize(add), const Size(44, 44));
    expect(session.quantityFor(product.id), 1);
    expect(find.descendant(of: panel, matching: stepper), findsOneWidget);
    expect(find.text(product.title), findsOneWidget);

    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(session.quantityFor(product.id), 2);
    expect(find.text('2'), findsOneWidget);

    await tester.tap(remove);
    await tester.pumpAndSettle();
    expect(session.quantityFor(product.id), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('state-owned Add point cannot retarget to replacement plus', (
    tester,
  ) async {
    await setSurface(tester, const Size(390, 844));
    final session = BuyV2Session(core: BuySession());
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    await tester.pumpWidget(app(session, product));
    await tester.pumpAndSettle();

    final panel = find.byKey(
      ValueKey('buy-product-inline-action-${product.id}'),
    );
    await tester.scrollUntilVisible(
      panel,
      220,
      scrollable: productScrollable(product),
    );
    await tester.pumpAndSettle();

    final primary = find.byKey(ValueKey('buy-product-primary-${product.id}'));
    final normalAddRect = tester.getRect(primary);
    final stateOwnedAddPoint = Offset(
      normalAddRect.left + normalAddRect.width / 4,
      normalAddRect.center.dy,
    );

    await tester.tapAt(stateOwnedAddPoint);
    await tester.pumpAndSettle();
    expect(session.quantityFor(product.id), 1);

    final stepper = find.byKey(ValueKey('buy-product-quantity-${product.id}'));
    final remove = find.descendant(
      of: stepper,
      matching: find.byTooltip('Remove one'),
    );
    final addOne = find.descendant(
      of: stepper,
      matching: find.byTooltip('Add one'),
    );
    final quantityLabel = find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.label == '1 in cart',
      description: 'non-clickable current quantity semantics owner',
    );
    expect(quantityLabel, findsOneWidget);

    final addOneRect = tester.getRect(addOne);
    final quantityRect = tester.getRect(quantityLabel);
    expect(normalAddRect.center.dx, closeTo(addOneRect.left, 0.001));
    expect(quantityRect.contains(stateOwnedAddPoint), isTrue);

    await tester.tapAt(stateOwnedAddPoint);
    await tester.pumpAndSettle();
    expect(session.quantityFor(product.id), 1);

    await tester.tap(remove);
    await tester.pumpAndSettle();
    expect(session.quantityFor(product.id), 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    '320 width 140 percent reduced motion keeps explicit product Add visible',
    (tester) async {
      await setSurface(tester, const Size(320, 700));
      final session = BuyV2Session(core: BuySession());
      final products = BuyV2Catalogue.products
          .where((item) => !item.requiresPrescription)
          .toList();
      final product = products.reduce(
        (longest, item) =>
            item.title.length > longest.title.length ? item : longest,
      );
      await tester.pumpWidget(
        app(session, product, textScale: 1.4, disableAnimations: true),
      );
      await tester.pumpAndSettle();

      final panel = find.byKey(
        ValueKey('buy-product-inline-action-${product.id}'),
      );
      await tester.scrollUntilVisible(
        panel,
        220,
        scrollable: productScrollable(product),
      );
      await tester.pumpAndSettle();
      final shell = find.byKey(ValueKey('buy-product-add-shell-${product.id}'));
      final primary = find.byKey(ValueKey('buy-product-primary-${product.id}'));
      expect(tester.getSize(shell), const Size(88, 44));
      expect(tester.getSize(panel).width, greaterThan(0));
      expect(find.descendant(of: panel, matching: shell), findsOneWidget);
      expect(
        find.descendant(of: primary, matching: find.text('Add')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: primary, matching: find.text(product.title)),
        findsNothing,
      );
      expect(find.text(product.title), findsOneWidget);
      expect(
        find.byKey(const ValueKey('buy-product-action-bar')),
        findsNothing,
      );
      expect(
        tester.getSemantics(primary).label,
        'Add ${product.title} to cart',
      );
      final semantics = tester.getSemantics(primary);
      expect(
        semantics.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );
      tester.semantics.tap(
        find.semantics.byLabel('Add ${product.title} to cart'),
      );
      await tester.pumpAndSettle();
      expect(session.quantityFor(product.id), 1);
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('prescription action stays truthful bounded and accessible', (
    tester,
  ) async {
    await setSurface(tester, const Size(320, 700));
    final session = BuyV2Session(core: BuySession());
    final product = BuyV2Catalogue.products.firstWhere(
      (item) =>
          item.destination == BuyV2Destination.medicine &&
          item.requiresPrescription,
    );
    await tester.pumpWidget(
      app(session, product, textScale: 1.4, disableAnimations: true),
    );
    await tester.pumpAndSettle();

    final panel = find.byKey(
      ValueKey('buy-product-inline-action-${product.id}'),
    );
    await tester.scrollUntilVisible(
      panel,
      220,
      scrollable: productScrollable(product),
    );
    await tester.pumpAndSettle();
    final shell = find.byKey(ValueKey('buy-product-add-shell-${product.id}'));
    final primary = find.byKey(ValueKey('buy-product-primary-${product.id}'));
    expect(tester.getSize(shell), const Size(148, 44));
    expect(find.text('Use prescription'), findsOneWidget);
    expect(
      find.descendant(of: primary, matching: find.text(product.title)),
      findsNothing,
    );
    expect(
      find.descendant(
        of: primary,
        matching: find.byIcon(Icons.description_outlined),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .getSemantics(primary)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    expect(find.descendant(of: panel, matching: shell), findsOneWidget);
    expect(find.text(product.title), findsOneWidget);
    expect(find.byKey(const ValueKey('buy-product-action-bar')), findsNothing);

    await tester.tap(primary);
    await tester.pumpAndSettle();
    expect(find.text('Use prescription'), findsWidgets);
    expect(session.quantityFor(product.id), 0);
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });
}
