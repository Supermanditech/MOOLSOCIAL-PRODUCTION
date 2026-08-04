import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_catalogue.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';

void main() {
  Widget catalogueApp(
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
      home: Scaffold(
        body: SafeArea(
          child: ListenableBuilder(
            listenable: session,
            builder: (context, _) => BuyV2ThemeScope(
              spec: BuyV2ThemeSpec.resolve(session.destination, session.view),
              child: BuyV2CatalogueView(session: session),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> expectCategoryMotion(
    WidgetTester tester,
    BuyV2Session session, {
    required BuyV2Destination destination,
    required Offset maximumOffset,
    required double minimumScale,
  }) async {
    final category = session.categories[1];
    session.chooseCategory(category.id);
    await tester.pump();
    await tester.pump(BuyV2Motion.contentChange ~/ 2);

    expect(
      find.byKey(
        ValueKey('buy-catalogue-motion-${destination.name}-${category.id}'),
      ),
      findsOneWidget,
    );
    final tween = tester.widget<TweenAnimationBuilder<double>>(
      find.byKey(ValueKey('buy-catalogue-motion-tween-${destination.name}')),
    );
    expect(tween.duration, BuyV2Motion.contentChange);
    final opacity = tester
        .widget<Opacity>(
          find.byKey(
            ValueKey('buy-catalogue-motion-opacity-${destination.name}'),
          ),
        )
        .opacity;
    expect(opacity, greaterThan(0));
    expect(opacity, lessThan(1));

    final translation = tester
        .widget<Transform>(
          find.byKey(
            ValueKey('buy-catalogue-motion-translate-${destination.name}'),
          ),
        )
        .transform
        .getTranslation();
    expect(translation.x.abs(), lessThanOrEqualTo(maximumOffset.dx.abs()));
    expect(translation.y.abs(), lessThanOrEqualTo(maximumOffset.dy.abs()));
    if (maximumOffset.dx != 0) expect(translation.x.abs(), greaterThan(0));
    if (maximumOffset.dy != 0) expect(translation.y.abs(), greaterThan(0));

    final scale = tester
        .widget<Transform>(
          find.byKey(
            ValueKey('buy-catalogue-motion-scale-${destination.name}'),
          ),
        )
        .transform
        .storage[0];
    expect(scale, greaterThan(minimumScale));
    expect(scale, lessThan(1));
    expect(
      find.byKey(
        ValueKey('buy-catalogue-motion-raster-boundary-${destination.name}'),
      ),
      findsOneWidget,
    );

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Opacity &&
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith(
              'buy-catalogue-motion-opacity-',
            ),
      ),
      findsOneWidget,
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Opacity>(
            find.byKey(
              ValueKey('buy-catalogue-motion-opacity-${destination.name}'),
            ),
          )
          .opacity,
      1,
    );
  }

  testWidgets('Shop categories use the horizontal market-flow settle', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(catalogueApp(session));
    await tester.pumpAndSettle();

    await expectCategoryMotion(
      tester,
      session,
      destination: BuyV2Destination.shop,
      maximumOffset: const Offset(14, 0),
      minimumScale: 0.985,
    );
  });

  testWidgets('Wholesale categories use the denser vertical stack settle', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession())
      ..openDestination(BuyV2Destination.wholesale);
    await tester.pumpWidget(catalogueApp(session));
    await tester.pumpAndSettle();

    await expectCategoryMotion(
      tester,
      session,
      destination: BuyV2Destination.wholesale,
      maximumOffset: const Offset(0, 10),
      minimumScale: 0.98,
    );
  });

  testWidgets('Medicine categories use the calm short lift and fade', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession())
      ..openDestination(BuyV2Destination.medicine);
    await tester.pumpWidget(catalogueApp(session));
    await tester.pumpAndSettle();

    await expectCategoryMotion(
      tester,
      session,
      destination: BuyV2Destination.medicine,
      maximumOffset: const Offset(0, 6),
      minimumScale: 0.995,
    );
  });

  testWidgets('Unrelated session notices do not replay catalogue motion', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(catalogueApp(session));
    await tester.pumpAndSettle();

    session.showNotice('Fresh delivery options are ready');
    await tester.pump();
    expect(
      tester
          .widget<Opacity>(
            find.byKey(const ValueKey('buy-catalogue-motion-opacity-shop')),
          )
          .opacity,
      1,
    );
  });

  testWidgets('Reduced motion keeps every vertical immediate and final', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(catalogueApp(session, disableAnimations: true));
    await tester.pump();

    for (final destination in <BuyV2Destination>[
      BuyV2Destination.shop,
      BuyV2Destination.wholesale,
      BuyV2Destination.medicine,
    ]) {
      session.openDestination(destination);
      await tester.pump();
      final name = destination.name;
      expect(
        tester
            .widget<TweenAnimationBuilder<double>>(
              find.byKey(ValueKey('buy-catalogue-motion-tween-$name')),
            )
            .duration,
        Duration.zero,
      );
      expect(
        tester
            .widget<Opacity>(
              find.byKey(ValueKey('buy-catalogue-motion-opacity-$name')),
            )
            .opacity,
        1,
      );
      expect(
        tester
            .widget<Transform>(
              find.byKey(ValueKey('buy-catalogue-motion-translate-$name')),
            )
            .transform
            .getTranslation()
            .length,
        0,
      );
      expect(
        tester
            .widget<Transform>(
              find.byKey(ValueKey('buy-catalogue-motion-scale-$name')),
            )
            .transform
            .storage[0],
        1,
      );
    }
  });

  testWidgets('Compact 140 percent vertical and category motion stays usable', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(catalogueApp(session, textScale: 1.4));
    await tester.pumpAndSettle();

    for (final destination in <BuyV2Destination>[
      BuyV2Destination.shop,
      BuyV2Destination.wholesale,
      BuyV2Destination.medicine,
    ]) {
      session.openDestination(destination);
      await tester.pumpAndSettle();
      session.chooseCategory(session.categories[1].id);
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          ValueKey(
            'buy-catalogue-motion-${destination.name}-'
            '${session.selectedCategoryId}',
          ),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
  });
}
