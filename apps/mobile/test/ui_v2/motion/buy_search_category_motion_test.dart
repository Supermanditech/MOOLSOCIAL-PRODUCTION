import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  Widget app(
    BuyV2Session session, {
    bool disableAnimations = false,
    double textScale = 1,
  }) {
    return MaterialApp(
      theme: MoolTheme.light(),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            disableAnimations: disableAnimations,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        );
      },
      home: BuyV2Screen(session: session),
    );
  }

  testWidgets('Search open close and back use the shared expansion owner', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    AnimatedContainer searchBand() => tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('buy-search-band')),
    );
    AnimatedContainer searchControl() => tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('buy-search-control')),
    );

    expect(searchBand().duration, BuyV2Motion.expandCollapse);
    expect(searchControl().duration, BuyV2Motion.expandCollapse);
    expect(
      tester.getSize(find.byKey(const ValueKey('buy-search-control'))).height,
      44,
    );

    await tester.tap(find.byKey(const ValueKey('buy-search-control')));
    await tester.pump();
    await tester.pump(BuyV2Motion.expandCollapse ~/ 2);
    final openingOwner = find.byKey(
      const ValueKey('buy-search-owner-motion-search'),
    );
    expect(openingOwner, findsOneWidget);
    expect(
      tester
          .widget<TweenAnimationBuilder<double>>(
            find.byKey(const ValueKey('buy-expand-collapse-owner-tween')),
          )
          .duration,
      BuyV2Motion.expandCollapse,
    );
    final openingOpacity = tester
        .widget<Opacity>(
          find.byKey(const ValueKey('buy-expand-collapse-owner-opacity')),
        )
        .opacity;
    expect(openingOpacity, greaterThan(0));
    expect(openingOpacity, lessThan(1));
    final openingHeight = tester
        .getSize(find.byKey(const ValueKey('buy-search-control')))
        .height;
    expect(openingHeight, greaterThan(44));
    expect(openingHeight, lessThan(48));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(const ValueKey('buy-search-control'))).height,
      48,
    );

    await tester.enterText(
      find.byKey(const ValueKey('buy-search-field')),
      'milk',
    );
    await tester.pump();
    expect(
      tester
          .widget<Opacity>(
            find.byKey(const ValueKey('buy-expand-collapse-owner-opacity')),
          )
          .opacity,
      1,
    );
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(BuyV2Motion.expandCollapse ~/ 2);
    final closingOwner = find.byKey(
      const ValueKey('buy-search-owner-motion-primary'),
    );
    expect(closingOwner, findsOneWidget);
    expect(
      tester
          .widget<TweenAnimationBuilder<double>>(
            find.byKey(const ValueKey('buy-expand-collapse-owner-tween')),
          )
          .duration,
      BuyV2Motion.expandCollapse,
    );
    final closingOpacity = tester
        .widget<Opacity>(
          find.byKey(const ValueKey('buy-expand-collapse-owner-opacity')),
        )
        .opacity;
    expect(closingOpacity, greaterThan(0));
    expect(closingOpacity, lessThan(1));
    final closingHeight = tester
        .getSize(find.byKey(const ValueKey('buy-search-control')))
        .height;
    expect(closingHeight, greaterThan(44));
    expect(closingHeight, lessThan(48));
    await tester.pumpAndSettle();
    expect(session.query, 'milk');
    expect(find.byKey(const ValueKey('buy-search-field')), findsNothing);
    expect(
      tester.getSize(find.byKey(const ValueKey('buy-search-control'))).height,
      44,
    );
  });

  testWidgets('Category sheet owns matching forward and reverse durations', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-category-picker')));
    await tester.pump();
    final route = ModalRoute.of(
      tester.element(find.byKey(const ValueKey('buy-category-sheet-surface'))),
    );
    expect(route, isA<ModalBottomSheetRoute<void>>());
    expect(route!.transitionDuration, BuyV2Motion.expandCollapse);
    expect(route.reverseTransitionDuration, BuyV2Motion.expandCollapse);

    await tester.pumpAndSettle();
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('buy-category-close')))
          .tooltip,
      'Close categories',
    );
    final category = session.categories[1];
    await tester.tap(find.byKey(ValueKey('buy-category-${category.id}')));
    await tester.pump();
    expect(session.selectedCategoryId, 'all');
    await tester.pumpAndSettle();
    expect(session.selectedCategoryId, category.id);
    expect(
      find.byKey(ValueKey('buy-catalogue-motion-shop-${category.id}')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TweenAnimationBuilder<double>>(
            find.byKey(const ValueKey('buy-catalogue-motion-tween-shop')),
          )
          .duration,
      BuyV2Motion.contentChange,
    );
    expect(session.selectedCategoryId, category.id);
    expect(
      find.byKey(const ValueKey('buy-category-sheet-surface')),
      findsNothing,
    );
  });

  testWidgets(
    'Reduced motion makes Search and category transitions immediate',
    (tester) async {
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session, disableAnimations: true));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('buy-search-control')));
      await tester.pump();
      final searchOwner = find.byKey(
        const ValueKey('buy-search-owner-motion-search'),
      );
      expect(searchOwner, findsOneWidget);
      expect(
        tester
            .widget<TweenAnimationBuilder<double>>(
              find.byKey(const ValueKey('buy-expand-collapse-owner-tween')),
            )
            .duration,
        Duration.zero,
      );
      expect(
        tester
            .widget<Opacity>(
              find.byKey(const ValueKey('buy-expand-collapse-owner-opacity')),
            )
            .opacity,
        1,
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
      expect(
        tester.getSize(find.byKey(const ValueKey('buy-search-control'))).height,
        48,
      );
      await tester.tap(find.byKey(const ValueKey('buy-search-close')));
      await tester.pump();
      expect(
        tester.getSize(find.byKey(const ValueKey('buy-search-control'))).height,
        44,
      );

      await tester.tap(find.byKey(const ValueKey('buy-category-picker')));
      await tester.pump();
      final route = ModalRoute.of(
        tester.element(
          find.byKey(const ValueKey('buy-category-sheet-surface')),
        ),
      );
      expect(route!.transitionDuration, Duration.zero);
      expect(route.reverseTransitionDuration, Duration.zero);
      await tester.tap(find.byKey(const ValueKey('buy-category-close')));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('buy-category-sheet-surface')),
        findsNothing,
      );
    },
  );

  testWidgets('Compact 140 percent Search and category motion stays usable', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session, textScale: 1.4));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-search-control')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-search-field')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('buy-search-close'))).height,
      greaterThanOrEqualTo(44),
    );
    await tester.tap(find.byKey(const ValueKey('buy-search-close')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-category-picker')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-category-grid')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('buy-category-close'))).height,
      greaterThanOrEqualTo(44),
    );
    expect(tester.takeException(), isNull);
  });
}
