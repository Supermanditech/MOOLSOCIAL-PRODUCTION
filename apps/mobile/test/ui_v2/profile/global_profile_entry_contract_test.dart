import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/ui_v2/profile/global_profile_panel_v2.dart';

void main() {
  testWidgets('global profile exposes account destinations without Help', (
    tester,
  ) async {
    final routes = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.centerRight,
            child: GlobalProfilePanelV2(
              onClose: () {},
              onOpenRoute: routes.add,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Personal account'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Active'), findsNothing);
    expect(find.text('Account settings'), findsOneWidget);
    expect(find.byKey(const Key('global-profile-identity')), findsOneWidget);
    expect(find.byKey(const Key('global-profile-preferences')), findsOneWidget);
    expect(find.byKey(const Key('global-profile-security')), findsOneWidget);
    expect(find.byKey(const Key('global-profile-ask')), findsNothing);
    expect(find.text('Help and support'), findsNothing);

    for (final entry in const <(Key, String)>[
      (Key('global-profile-identity'), '/app/account/identity'),
      (
        Key('global-profile-preferences'),
        '/app/account/workspaces/preferences',
      ),
      (Key('global-profile-security'), '/app/account/security'),
    ]) {
      final target = find.byKey(entry.$1);
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pump();
      expect(routes.last, entry.$2);
    }
  });

  testWidgets('global profile shows Active only for an authenticated account', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.centerRight,
            child: GlobalProfilePanelV2(
              accountAuthenticated: true,
              onClose: () {},
              onOpenRoute: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Sign in'), findsNothing);
  });

  test('profile source cannot reintroduce a public Help destination', () {
    final source = File(
      'lib/ui_v2/profile/global_profile_panel_v2.dart',
    ).readAsStringSync();

    expect(source, isNot(contains("id: 'ask'")));
    expect(source, isNot(contains("title: 'Help and support'")));
  });

  testWidgets('context action clears the OPPO exported bottom inset', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.viewPadding = const FakeViewPadding(bottom: 44);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.centerRight,
            child: GlobalProfilePanelV2(
              onClose: () {},
              onOpenRoute: (_) {},
              contextAction: GlobalProfileContextAction(
                id: 'orders',
                title: 'Your Shop orders',
                detail: '3 active and 3 delivered orders are ready to review.',
                actionLabel: 'Open orders',
                icon: Icons.receipt_long_outlined,
                onPressed: () {},
              ),
              onContextAction: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final action = find.byKey(
      const Key('global-profile-context-action-orders'),
    );
    final rect = tester.getRect(action);
    expect(
      find.byKey(const Key('global-profile-bottom-safe-area')),
      findsOneWidget,
    );
    expect(rect.height, greaterThanOrEqualTo(42));
    expect(rect.bottom, lessThanOrEqualTo(756));
    expect(tester.takeException(), isNull);
  });

  testWidgets('context action uses OPPO top-only exported clearance', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.viewPadding = const FakeViewPadding(top: 41);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.centerRight,
            child: GlobalProfilePanelV2(
              onClose: () {},
              onOpenRoute: (_) {},
              contextAction: GlobalProfileContextAction(
                id: 'orders',
                title: 'Your Shop orders',
                detail: 'Orders are ready to review.',
                actionLabel: 'Open orders',
                icon: Icons.receipt_long_outlined,
                onPressed: () {},
              ),
              onContextAction: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final action = find.byKey(
      const Key('global-profile-context-action-orders'),
    );
    final rect = tester.getRect(action);
    expect(rect.height, greaterThanOrEqualTo(42));
    expect(rect.bottom, lessThanOrEqualTo(773));
    expect(tester.takeException(), isNull);
  });
}
