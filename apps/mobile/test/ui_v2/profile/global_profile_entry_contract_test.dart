import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/ui_v2/profile/global_profile_panel_v2.dart';

void main() {
  for (final display in [
    (size: const Size(412, 915), scale: 1.0),
    (size: const Size(320, 640), scale: 1.4),
    (size: const Size(320, 640), scale: 2.0),
  ]) {
    for (final entry in ['personal', 'workspace', 'context']) {
      for (final tone in GlobalProfileSurfaceTone.values) {
        testWidgets(
          'Profile footer fit ${display.size.width} ${display.scale} $entry ${tone.name}',
          (tester) async {
            tester.view.physicalSize = display.size;
            tester.view.devicePixelRatio = 1;
            tester.view.viewPadding = const FakeViewPadding(bottom: 24);
            addTearDown(tester.view.reset);
            final routes = <String>[];
            var contextTaps = 0;
            Future<void> capture(String position) async {
              if (!const bool.fromEnvironment('MOOL_CAPTURE_STORE_VIEW_V2') ||
                  entry != 'workspace' ||
                  tone != GlobalProfileSurfaceTone.light) {
                return;
              }
              const folder = String.fromEnvironment(
                'MOOL_STORE_VIEW_CAPTURE_DIR',
              );
              await expectLater(
                find.byKey(const Key('profile-range-capture')),
                matchesGoldenFile(
                  '../../../../../../MOOLSOCIAL-POST-UI-AUDIT-20260905/$folder/profile-${display.size.width}-${display.scale}-$position.png',
                ),
              );
            }

            await tester.pumpWidget(
              MaterialApp(
                theme: MoolTheme.light(),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(display.scale)),
                  child: child!,
                ),
                home: Scaffold(
                  body: RepaintBoundary(
                    key: const Key('profile-range-capture'),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: GlobalProfilePanelV2(
                        accountAuthenticated: true,
                        surfaceTone: tone,
                        activeWorkspace: entry == 'workspace'
                            ? const GlobalProfileWorkspaceContext(
                                name: 'Mahadev Fresh Mart',
                                roleLabel: 'Speciality Retail Shop',
                                area: 'Jodhpur',
                              )
                            : null,
                        onClose: () {},
                        onOpenRoute: routes.add,
                        contextAction: entry == 'context'
                            ? GlobalProfileContextAction(
                                id: 'orders',
                                title: 'Your Shop orders',
                                detail: 'Orders are ready to review.',
                                actionLabel: 'Open orders',
                                icon: Icons.receipt_long_outlined,
                                onPressed: () => contextTaps++,
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(routes, isEmpty);
            await capture('initial');
            for (final destination in const <(String, String)>[
              ('identity', '/app/account/identity'),
              ('preferences', '/app/account/workspaces/preferences'),
              ('security', '/app/account/security'),
            ]) {
              final action = find.byKey(
                Key('global-profile-${destination.$1}'),
              );
              await tester.ensureVisible(action);
              await tester.pumpAndSettle();
              final rect = tester.getRect(action);
              expect(rect.left, greaterThanOrEqualTo(0));
              expect(rect.right, lessThanOrEqualTo(display.size.width));
              expect(rect.top, greaterThanOrEqualTo(0));
              expect(rect.bottom, lessThanOrEqualTo(display.size.height - 24));
              expect(rect.height, greaterThanOrEqualTo(42));
              await tester.tap(action);
              await tester.pumpAndSettle();
              expect(routes.last, destination.$2);
              expect(tester.takeException(), isNull);
            }
            await capture('footer');
            if (entry == 'workspace') {
              final operations = find.byKey(
                const Key('global-profile-quick-operations'),
              );
              await tester.ensureVisible(operations);
              await tester.tap(operations);
              await tester.pumpAndSettle();
              expect(routes.last, '/app/work/my-work');
            } else if (entry == 'context') {
              final action = find.byKey(
                const Key('global-profile-context-action-orders'),
              );
              await tester.ensureVisible(action);
              await tester.tap(action);
              await tester.pumpAndSettle();
              expect(contextTaps, 1);
            }
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

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
