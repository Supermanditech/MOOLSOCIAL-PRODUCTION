import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/ui_v2/universal/personal_mool_root_v2.dart';

void main() {
  test('C23E1 production router preserves root and origin route policy', () {
    final source = File(
      'lib/features/journey01/journey_router.dart',
    ).readAsStringSync();

    expect(source, contains('onOpenRoute: (route) {'));
    expect(source, contains('if (moolOrigin == null)'));
    expect(source, contains('context.push(route);'));
    expect(source, contains('context.pushReplacement(route);'));
  });

  testWidgets('C24B2 exposes every subaction after in-place family selection', (
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

    final expectedRoutes = <String>[];
    for (final family in moolActionFamilies) {
      await tester.tap(find.byKey(ValueKey('mool-home-family-${family.id}')));
      await tester.pumpAndSettle();
      expect(routes, expectedRoutes, reason: '${family.id} selects in place');
      for (final action in family.actions) {
        final target = find.byKey(
          ValueKey('mool-home-${family.id}-${action.id}'),
        );
        await tester.tap(target);
        await tester.pump();
        expectedRoutes.add(action.route);
        expect(routes.last, action.route, reason: action.id);
      }
    }

    expect(routes, expectedRoutes);
    expect(routes, hasLength(17));
  });
}
