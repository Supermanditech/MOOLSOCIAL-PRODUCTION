import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

Widget depthHost({required VoidCallback onTap, bool reduced = false}) {
  return MaterialApp(
    theme: MoolTheme.light(),
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: Center(
        child: SizedBox(
          width: 220,
          height: 150,
          child: BuyV2IntentDepth(
            key: const ValueKey('depth-owner'),
            spatial: true,
            child: Material(
              child: InkWell(
                key: const ValueKey('depth-action'),
                onTap: onTap,
                child: const Center(child: Text('Open product')),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Widget buyHost(
  BuyV2Session session, {
  bool reduced = false,
  double textScale = 1,
}) {
  return MaterialApp(
    theme: MoolTheme.light(),
    builder: (context, child) {
      final media = MediaQuery.of(context);
      return MediaQuery(
        data: media.copyWith(
          disableAnimations: reduced,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      );
    },
    home: BuyV2Screen(
      session: session,
      initialDestination: session.destination,
      initialView: session.view,
    ),
  );
}

Transform depthTransform(WidgetTester tester, Finder owner) {
  return tester.widget<Transform>(
    find
        .descendant(
          of: owner,
          matching: find.byKey(const ValueKey('buy-intent-depth-transform')),
        )
        .first,
  );
}

bool isIdentity(Matrix4 value) {
  final identity = Matrix4.identity();
  for (var index = 0; index < 16; index++) {
    if ((value.storage[index] - identity.storage[index]).abs() > .000001) {
      return false;
    }
  }
  return true;
}

void main() {
  testWidgets(
    'spatial hold is finite, position-aware and keeps hit tests fixed',
    (tester) async {
      var activations = 0;
      await tester.pumpWidget(depthHost(onTap: () => activations++));
      await tester.pumpAndSettle();
      final owner = find.byKey(const ValueKey('depth-owner'));
      final action = find.byKey(const ValueKey('depth-action'));
      final ownerSize = tester.getSize(owner);
      final actionSize = tester.getSize(action);

      final gesture = await tester.startGesture(
        tester.getTopLeft(action) + const Offset(190, 35),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 55));

      final tween = tester.widget<TweenAnimationBuilder<double>>(
        find.descendant(
          of: owner,
          matching: find.byType(TweenAnimationBuilder<double>),
        ),
      );
      expect(tween.duration, BuyV2Motion.press);
      final held = depthTransform(tester, owner);
      expect(isIdentity(held.transform), isFalse);
      expect(held.transformHitTests, isFalse);
      final plane = tester.widget<Transform>(
        find.descendant(
          of: owner,
          matching: find.byKey(const ValueKey('buy-intent-depth-plane')),
        ),
      );
      expect(isIdentity(plane.transform), isFalse);
      expect(plane.transformHitTests, isFalse);
      expect(tester.getSize(owner), ownerSize);
      expect(tester.getSize(action), actionSize);

      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(isIdentity(depthTransform(tester, owner).transform), isTrue);
      expect(activations, 0);

      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(activations, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'real product opens one media and title reveal without fake state',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(buyHost(session));
      await tester.pumpAndSettle();
      final product = session.visibleProducts.first;
      final depth = find.byKey(ValueKey('buy-featured-depth-${product.id}'));
      expect(tester.widget<BuyV2IntentDepth>(depth).spatial, isTrue);

      session.openProduct(product.id);
      await tester.pump();
      await tester.pump();
      final media = find.byKey(
        ValueKey('buy-product-media-reveal-${product.id}'),
      );
      final title = find.byKey(
        ValueKey('buy-product-title-reveal-${product.id}'),
      );
      expect(media, findsOneWidget);
      expect(title, findsOneWidget);
      expect(
        tester.widget<BuyV2FiniteDepthReveal>(media).duration,
        BuyV2Motion.contentChange,
      );
      expect(
        tester.widget<BuyV2FiniteIncomingTransition>(title).duration,
        BuyV2Motion.contentChange,
      );
      expect(find.text(product.title), findsOneWidget);
      expect(find.text(product.pack), findsWidgets);
      expect(session.quantityFor(product.id), 0);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('reduced product motion is zero at 320 and 140 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.medicine,
    );
    session.openProduct(product.id);
    await tester.pumpWidget(buyHost(session, reduced: true, textScale: 1.4));
    await tester.pumpAndSettle();

    final media = find.byKey(
      ValueKey('buy-product-media-reveal-${product.id}'),
    );
    final title = find.byKey(
      ValueKey('buy-product-title-reveal-${product.id}'),
    );
    final mediaTween = find.descendant(
      of: media,
      matching: find.byType(TweenAnimationBuilder<double>),
    );
    final titleTween = find.descendant(
      of: title,
      matching: find.byType(TweenAnimationBuilder<double>),
    );
    expect(
      tester.widget<TweenAnimationBuilder<double>>(mediaTween).duration,
      Duration.zero,
    );
    expect(
      tester.widget<TweenAnimationBuilder<double>>(titleTween).duration,
      Duration.zero,
    );
    expect(find.text(product.title), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
