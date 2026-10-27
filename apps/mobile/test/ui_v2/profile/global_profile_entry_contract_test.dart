import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/ui_v2/profile/global_profile_panel_v2.dart';

void main() {
  testWidgets(
    'Profile live readback keeps customer and approved Workspace states separate',
    (tester) async {
      final changes = ValueNotifier<int>(0);
      addTearDown(changes.dispose);
      var authenticated = true,
          application = false,
          workspaceReadFailed = false;
      GlobalProfileWorkspaceContext? workspace;
      final routes = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: GlobalProfileAccountScope(
            changes: changes,
            readAuthenticated: () => authenticated,
            readApplicationInProgress: () => application,
            readApprovedWorkspace: () {
              if (workspaceReadFailed)
                throw StateError('isolated read unavailable');
              return workspace;
            },
            child: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () {
                    showGlobalProfilePanelV2(
                      context,
                      onOpenRoute: routes.add,
                      accountAuthenticated: false,
                      activeWorkspace: const GlobalProfileWorkspaceContext(
                        name: 'Stale caller Store',
                        roleLabel: 'Store',
                        area: 'Area',
                      ),
                    );
                  },
                  child: const Text('Open Profile fixture'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open Profile fixture'));
      await tester.pumpAndSettle();
      expect(find.text('Signed in'), findsOneWidget);
      expect(find.text('Stale caller Store'), findsNothing);
      expect(find.byType(ListTile), findsNWidgets(5));
      expect(
        find.byKey(const Key('global-profile-approved-workspace')),
        findsNothing,
      );
      workspace = const GlobalProfileWorkspaceContext(
        name: 'Approved Store fixture',
        roleLabel: 'Store',
        area: 'Area',
      );
      changes.value++;
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('global-profile-approved-workspace')),
        findsOneWidget,
      );
      expect(find.text('Approved Store fixture · Approved'), findsOneWidget);
      expect(
        find.byKey(const Key('global-profile-quick-actions')),
        findsNothing,
      );
      expect(find.byKey(const Key('global-profile-access-card')), findsNothing);
      workspace = null;
      application = true;
      changes.value++;
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('global-profile-approved-workspace')),
        findsNothing,
      );
      expect(find.text('View your application'), findsOneWidget);
      workspaceReadFailed = true;
      changes.value++;
      await tester.pumpAndSettle();
      expect(find.text('Signed in'), findsOneWidget);
      expect(authenticated, isTrue);
      authenticated = false;
      changes.value++;
      await tester.pumpAndSettle();
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text('View your application'), findsNothing);
      await tester.tap(find.byKey(const Key('global-profile-identity')));
      await tester.pumpAndSettle();
      expect(Uri.parse(routes.single).path, '/app/account/security');
      expect(changes.hasListeners, isFalse);
    },
  );

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('Profile actual safe area and full action $platform enlarged', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 34);
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 34);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light().copyWith(platform: platform),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: Align(
              alignment: Alignment.centerRight,
              child: GlobalProfilePanelV2(
                onClose: () {},
                onOpenRoute: (_) {},
                accountAuthenticated: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final action = find.byKey(const Key('global-profile-security'));
      await tester.scrollUntilVisible(
        action,
        180,
        scrollable: find.descendant(
          of: find.byKey(const Key('global-profile-panel-content')),
          matching: find.byType(Scrollable),
        ),
      );
      await Scrollable.ensureVisible(tester.element(action), alignment: .5);
      await tester.pumpAndSettle();
      expect(action.hitTestable(), findsOneWidget);
      expect(tester.getRect(action).bottom, lessThanOrEqualTo(568 - 34));
      expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: action, matching: find.text('Security')),
      );
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('signed-out Profile never exposes personalised review orders', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GlobalProfilePanelV2(
            onClose: () {},
            onOpenRoute: (_) {},
            accountAuthenticated: false,
            contextAction: GlobalProfileContextAction(
              id: 'orders',
              title: 'Your Shop orders',
              detail: '4 active orders',
              actionLabel: 'Open orders',
              icon: Icons.receipt_long_outlined,
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
    expect(find.text('4 active orders'), findsNothing);
    expect(find.text('Your Shop orders'), findsNothing);
    expect(find.byKey(const Key('global-profile-identity')), findsOneWidget);
  });

  testWidgets('signed-out Profile cannot expose retained Workspace controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GlobalProfilePanelV2(
            onClose: () {},
            onOpenRoute: (_) {},
            accountAuthenticated: false,
            activeWorkspace: const GlobalProfileWorkspaceContext(
              name: 'Retained Store',
              roleLabel: 'Owner',
              area: 'Jodhpur',
            ),
          ),
        ),
      ),
    );
    expect(
      find.byKey(const Key('global-profile-active-workspace')),
      findsNothing,
    );
    expect(find.byKey(const Key('global-profile-quick-actions')), findsNothing);
    expect(find.text('Retained Store'), findsNothing);
  });

  for (final tone in GlobalProfileSurfaceTone.values) {
    for (final free in [false, true]) {
      testWidgets('Profile launcher paint is opt-in ${tone.name} free=$free', (
        tester,
      ) async {
        var taps = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MoolGlobalProfileShortcutV2(
                keyName: 'profile-paint',
                onPressed: () => taps++,
                surfaceTone: tone,
                freeStanding: free,
              ),
            ),
          ),
        );
        final root = find.byKey(const Key('profile-paint'));
        final button = tester.widget<IconButton>(
          find.descendant(of: root, matching: find.byType(IconButton)),
        );
        expect(tester.getSize(root), Size.square(free ? 48 : 44));
        expect(
          button.style!.side!.resolve({})!.style,
          free ? BorderStyle.none : BorderStyle.solid,
        );
        expect(
          button.style!.backgroundColor!.resolve({})!.a,
          free ? 0 : greaterThan(0),
        );
        expect(
          (button.icon as Icon).icon,
          free ? Icons.person_outline_rounded : Icons.account_circle_outlined,
        );
        await tester.tap(root);
        expect(taps, 1);
        expect(tester.takeException(), isNull);
      });
    }
  }

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
            expect(
              find.byKey(const Key('global-profile-downloads')),
              findsNothing,
            );
            await capture('initial');
            for (final destination in const <(String, String)>[
              ('identity', '/app/account/identity'),
              ('preferences', '/app/account/workspaces/preferences'),
              ('security', '/app/account/security'),
            ]) {
              final action = find.byKey(
                Key('global-profile-${destination.$1}'),
              );
              await tester.scrollUntilVisible(
                action,
                180,
                scrollable: find.descendant(
                  of: find.byKey(const Key('global-profile-panel-content')),
                  matching: find.byType(Scrollable),
                ),
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
            if (entry == 'workspace' &&
                tone == GlobalProfileSurfaceTone.socialDark) {
              for (final shortcut in const [
                ('operations', 'Operations', '/app/work/my-work'),
                ('activity', 'Activity', '/app/activity'),
                ('documents', 'Documents', '/app/files'),
                ('plans', 'Plans', '/app/account/plans'),
                ('support', 'Support', '/app/ask'),
              ]) {
                final action = find.byKey(
                  Key('global-profile-quick-${shortcut.$1}'),
                );
                await tester.scrollUntilVisible(
                  action,
                  -180,
                  scrollable: find.descendant(
                    of: find.byKey(const Key('global-profile-panel-content')),
                    matching: find.byType(Scrollable),
                  ),
                );
                await tester.ensureVisible(action);
                await tester.pumpAndSettle();
                final label = find.descendant(
                  of: action,
                  matching: find.text(shortcut.$2),
                );
                final paragraph = tester.renderObject<RenderParagraph>(label);
                expect(paragraph.didExceedMaxLines, isFalse);
                expect(
                  paragraph.getBoxesForSelection(
                    TextSelection(
                      baseOffset: 0,
                      extentOffset: shortcut.$2.length,
                    ),
                  ),
                  hasLength(1),
                  reason: '${shortcut.$2} must not split within a word',
                );
                expect(tester.getSize(action).height, greaterThanOrEqualTo(42));
                await tester.tap(action);
                await tester.pumpAndSettle();
                expect(routes.last, shortcut.$3);
              }
              await capture('shortcuts');
            } else if (entry == 'context' &&
                tone == GlobalProfileSurfaceTone.socialDark) {
              final action = find.byKey(
                const Key('global-profile-context-action-orders'),
              );
              await tester.ensureVisible(action);
              await tester.tap(action);
              await tester.pumpAndSettle();
              expect(contextTaps, 1);
            }
            if (tone == GlobalProfileSurfaceTone.light) {
              expect(
                find.byKey(const Key('global-profile-quick-actions')),
                findsNothing,
              );
              expect(
                find.byKey(const Key('global-profile-context-action-orders')),
                findsNothing,
              );
              expect(
                find.byKey(const Key('global-profile-workspaces')),
                findsOneWidget,
              );
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
    expect(find.text('Your account'), findsOneWidget);
    expect(find.byKey(const Key('global-profile-identity')), findsOneWidget);
    expect(find.byKey(const Key('global-profile-preferences')), findsOneWidget);
    expect(find.byKey(const Key('global-profile-security')), findsOneWidget);
    expect(find.byKey(const Key('global-profile-ask')), findsNothing);
    expect(find.text('Help and support'), findsNothing);

    for (final entry in const <(Key, String)>[
      (Key('global-profile-identity'), '/app/account/security'),
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

  testWidgets(
    'global profile shows Signed in only for an authenticated account',
    (tester) async {
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

      expect(find.text('Signed in'), findsOneWidget);
      expect(find.text('Sign in'), findsNothing);
    },
  );

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
              accountAuthenticated: true,
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

    final action = find.byKey(const Key('global-profile-security'));
    final rect = tester.getRect(action);
    expect(
      find.byKey(const Key('global-profile-bottom-safe-area')),
      findsOneWidget,
    );
    expect(rect.height, greaterThanOrEqualTo(42));
    expect(rect.bottom, lessThanOrEqualTo(756));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Profile Security clears OPPO top-only inset', (tester) async {
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
              accountAuthenticated: true,
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

    final action = find.byKey(const Key('global-profile-security'));
    final rect = tester.getRect(action);
    expect(rect.height, greaterThanOrEqualTo(42));
    expect(rect.bottom, lessThanOrEqualTo(773));
    expect(tester.takeException(), isNull);
  });
}
