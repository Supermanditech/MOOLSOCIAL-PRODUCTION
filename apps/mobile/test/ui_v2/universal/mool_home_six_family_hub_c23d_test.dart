import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/ui_v2/universal/personal_mool_root_v2.dart';

void main() {
  testWidgets('C24B2 preserves six families and all selected direct actions', (
    tester,
  ) async {
    final routes = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: PersonalMoolRootV2(
          onBack: () {},
          onOpenAction: (_) {},
          onOpenChat: () {},
          onOpenRoute: routes.add,
          areaLabel: 'Jodhpur',
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final family in const [
      'social',
      'buy',
      'eat',
      'ride',
      'book',
      'work',
    ]) {
      expect(find.byKey(ValueKey('mool-home-family-$family')), findsOneWidget);
    }
    for (final family in moolActionFamilies) {
      await tester.tap(find.byKey(ValueKey('mool-home-family-${family.id}')));
      await tester.pumpAndSettle();
      for (final action in family.actions) {
        expect(
          find.byKey(ValueKey('mool-home-${family.id}-${action.id}')),
          findsOneWidget,
        );
      }
    }
    expect(find.byType(ListView), findsNothing);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(find.byType(CustomScrollView), findsNothing);
    expect(find.byType(GridView), findsNothing);
    expect(find.byKey(const Key('moolsocial-global-navigation')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('mool-home-family-social')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mool-home-social-feed')));
    await tester.pumpAndSettle();
    expect(routes, ['/app/social?sub=feed']);
  });
}
