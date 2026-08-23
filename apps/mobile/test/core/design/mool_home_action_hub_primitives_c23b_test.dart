import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_design_system.dart';

void main() {
  test('C23B freezes professional Home-hub geometry', () {
    expect(MoolHomeHubTokens.mainActionHeight, greaterThanOrEqualTo(56));
    expect(
      MoolHomeHubTokens.subactionHeight,
      greaterThanOrEqualTo(MoolMetrics.minimumTapTarget),
    );
    expect(MoolHomeHubTokens.mainLabelSize, 13);
    expect(MoolHomeHubTokens.subactionLabelSize, 11.5);
    expect(MoolHomeHubTokens.pressDuration, const Duration(milliseconds: 100));
    expect(MoolHomeHubTokens.accentForFamily('buy'), const Color(0xFFFFB347));
  });

  testWidgets(
    'C23B family row exposes direct nonhorizontal main and subaction taps',
    (tester) async {
      var familyTaps = 0;
      final tapped = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                child: MoolHomeHubFamilyRow(
                  familyId: 'buy',
                  label: 'Buy',
                  icon: Icons.shopping_bag_outlined,
                  onOpenFamily: () => familyTaps++,
                  actions: [
                    for (final value in const [
                      ('shop', 'Shop', Icons.storefront_outlined),
                      ('wholesale', 'Wholesale', Icons.inventory_2_outlined),
                      ('medicine', 'Medicine', Icons.medication_outlined),
                      ('orders', 'Orders', Icons.receipt_long_outlined),
                    ])
                      MoolHomeHubAction(
                        id: value.$1,
                        label: value.$2,
                        icon: value.$3,
                        onPressed: () => tapped.add(value.$1),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(MoolHomeHubFamilyRow), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(
        find.byKey(const ValueKey('mool-home-family-buy')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('mool-home-buy-shop')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('mool-home-buy-orders')),
        findsOneWidget,
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey('mool-home-family-buy')))
            .height,
        greaterThanOrEqualTo(56),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('mool-home-buy-shop'))).height,
        greaterThanOrEqualTo(44),
      );
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Buy'))
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Medicine'))
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );

      await tester.tap(find.byKey(const ValueKey('mool-home-family-buy')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mool-home-buy-medicine')));
      await tester.pumpAndSettle();
      expect(familyTaps, 1);
      expect(tapped, ['medicine']);
    },
  );
}
