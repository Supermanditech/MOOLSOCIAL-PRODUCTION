import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_design_system.dart';
import 'package:moolsocial/ui_v2/universal/mool_global_navigation_v2.dart';

void main() {
  for (final family in moolActionFamilies) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'NAV-GAP ${family.id} retains full targets without a bottom spacer text$scale',
        (tester) async {
          tester.view.physicalSize = Size(scale == 1 ? 360 : 320, 806);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final semanticsHandle = tester.ensureSemantics();
          try {
            final actions = <String>[];
            await _mountOppoShell(
              tester,
              familyId: family.id,
              textScale: scale,
              extendBody: false,
              actionLog: actions,
            );
            final shell = tester.getRect(
              find.byKey(const Key('moolsocial-single-home-launcher-shell')),
            );
            final rail = tester.getRect(
              find.byKey(const Key('moolsocial-compact-destination-rail')),
            );
            expect(
              shell.height,
              58 + 44,
              reason:
                  'Only the actual system bottom inset belongs below the 58dp row.',
            );
            expect(rail.bottom, 806 - 44);
            expect(
              tester
                  .getRect(find.byKey(const Key('navigation-gap-content')))
                  .bottom,
              shell.top,
            );
            expect(shell.top, 806 - 44 - 58);
            final semantics = tester.getSemantics(
              find.bySemanticsLabel('Open MoolSocial main menu'),
            );
            expect(semantics.rect.height, greaterThanOrEqualTo(44));
            for (final action in family.actions) {
              final cell = tester.getRect(
                find.byKey(Key('c28b-social-${action.id}')),
              );
              expect(cell.height, 58);
              expect(cell.width, greaterThanOrEqualTo(44));
              expect(cell.bottom, lessThanOrEqualTo(806 - 44));
            }
            for (final action in family.actions.skip(1)) {
              await tester.tap(find.byKey(Key('c28b-social-${action.id}')));
              await tester.pumpAndSettle();
              expect(actions.last, action.id);
            }
            await tester.tap(find.byKey(const Key('mool-global-chat')));
            await tester.pumpAndSettle();
            expect(actions.last, 'chat');
            await tester.tap(
              find.bySemanticsLabel('Open MoolSocial main menu'),
            );
            await tester.pumpAndSettle();
            final menu = tester.getRect(
              find.byKey(const Key('mool-connected-action-navigator')),
            );
            expect(menu.top, greaterThanOrEqualTo(41));
            expect(menu.bottom, lessThanOrEqualTo(rail.top));
            await tester.tapAt(Offset(tester.view.physicalSize.width - 8, 42));
            await tester.pumpAndSettle();
            expect(
              find.byKey(const Key('mool-connected-action-navigator')),
              findsNothing,
            );
            expect(tester.takeException(), isNull);
          } finally {
            semanticsHandle.dispose();
          }
        },
        variant: TargetPlatformVariant.only(TargetPlatform.android),
      );
    }
  }
  testWidgets(
    'C28E OPPO insets export 44px targets and keep FSC01 direct Social actions',
    (tester) async {
      tester.view.physicalSize = const Size(360, 806);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _mountOppoShell(tester);

      final shell = find.byKey(
        const Key('moolsocial-single-home-launcher-shell'),
      );
      final rail = find.byKey(const Key('moolsocial-compact-destination-rail'));
      expect(tester.getSize(shell).height, 102);
      expect(tester.getSize(rail).height, 58);
      expect(tester.getBottomRight(rail).dy, 762);
      expect(
        tester.getSize(find.bySemanticsLabel('Open MoolSocial main menu')),
        const Size(60, 58),
      );
      expect(
        tester.getSize(find.byKey(const Key('mool-global-chat'))),
        const Size(60, 58),
      );
      final moolBounds = tester.getRect(
        find.bySemanticsLabel('Open MoolSocial main menu'),
      );
      // Raw AccessibilityNodeInfo uses the real display. Legacy shell dump
      // additionally crops Display.getSize and must not define app geometry.
      const exportedRootBottom = 806 - 44;
      final exportedHeight =
          moolBounds.bottom.clamp(0, exportedRootBottom) -
          moolBounds.top.clamp(0, exportedRootBottom);
      expect(exportedHeight, greaterThanOrEqualTo(44));
      expect(
        moolAndroidExportedSemanticsClearance(
          viewPadding: const EdgeInsets.only(top: 41, bottom: 44),
          platform: TargetPlatform.android,
        ),
        27,
      );
      expect(find.bySemanticsLabel('Open Social home'), findsNothing);
      expect(
        find.byKey(const ValueKey('moolsocial-family-root-social')),
        findsNothing,
      );
      for (final label in const [
        'Home, current',
        'Open Shorts',
        'Open Create',
        'Open Feed',
      ]) {
        final size = tester.getSize(find.bySemanticsLabel(label));
        expect(size.width, greaterThanOrEqualTo(44));
        expect(size.height, 58);
      }
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'C28E keyboard and reduced motion retain exported semantics clearance',
    (tester) async {
      tester.view.physicalSize = const Size(360, 806);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _mountOppoShell(
        tester,
        viewInsets: const EdgeInsets.only(bottom: 280),
        disableAnimations: true,
      );

      final rail = find.byKey(const Key('moolsocial-compact-destination-rail'));
      expect(tester.getSize(rail).height, 58);
      expect(tester.getBottomRight(rail).dy, 762);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'C29J standalone Chat Mool launcher exports at least 44px on OPPO',
    (tester) async {
      tester.view.physicalSize = const Size(360, 806);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _mountOppoStandaloneLauncher(tester);

      expect(
        find.byKey(
          const Key('moolsocial-global-android-exported-semantics-clearance'),
        ),
        findsOneWidget,
      );
      final clearance = tester.widget<Padding>(
        find.byKey(
          const Key('moolsocial-global-android-exported-semantics-clearance'),
        ),
      );
      expect(clearance.padding, const EdgeInsets.only(bottom: 27));
      final moolBounds = tester.getRect(
        find.bySemanticsLabel('Open MoolSocial main menu'),
      );
      const exportedRootBottom = 806 - 41 - 44;
      final exportedHeight =
          moolBounds.bottom.clamp(0, exportedRootBottom) -
          moolBounds.top.clamp(0, exportedRootBottom);
      expect(exportedHeight, greaterThanOrEqualTo(44));
      expect(
        tester.getSize(find.byKey(const Key('mool-home-launcher'))),
        const Size(64, 56),
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'C28E non-Android keeps the accepted one-handed rail position',
    (tester) async {
      tester.view.physicalSize = const Size(360, 806);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _mountOppoShell(tester);

      expect(
        tester
            .getSize(
              find.byKey(const Key('moolsocial-single-home-launcher-shell')),
            )
            .height,
        102,
      );
      expect(
        tester
            .getBottomRight(
              find.byKey(const Key('moolsocial-compact-destination-rail')),
            )
            .dy,
        762,
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}

Future<void> _mountOppoStandaloneLauncher(WidgetTester tester) async {
  tester.view.viewPadding = const FakeViewPadding(top: 41, bottom: 44);
  addTearDown(tester.view.resetViewPadding);
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(360, 806),
          padding: EdgeInsets.only(top: 41, bottom: 44),
          viewPadding: EdgeInsets.only(top: 41, bottom: 44),
        ),
        child: Scaffold(
          extendBody: true,
          body: const ColoredBox(color: Colors.white),
          bottomNavigationBar: MoolGlobalNavigationV2(
            activeId: 'chat',
            onOpenMool: () {},
            onOpenAction: (_) {},
            onOpenChat: null,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _mountOppoShell(
  WidgetTester tester, {
  EdgeInsets viewInsets = EdgeInsets.zero,
  bool disableAnimations = false,
  String familyId = 'social',
  double textScale = 1.4,
  bool extendBody = true,
  List<String>? actionLog,
}) async {
  tester.view.viewPadding = const FakeViewPadding(top: 41, bottom: 44);
  addTearDown(tester.view.resetViewPadding);
  final family = moolActionFamilyById(familyId);
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: tester.view.physicalSize / tester.view.devicePixelRatio,
          padding: const EdgeInsets.only(top: 41, bottom: 44),
          viewPadding: const EdgeInsets.only(top: 41, bottom: 44),
          viewInsets: viewInsets,
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
          accessibleNavigation: disableAnimations,
        ),
        child: Scaffold(
          extendBody: extendBody,
          body: const SizedBox.expand(
            key: Key('navigation-gap-content'),
            child: ColoredBox(color: Colors.black),
          ),
          bottomNavigationBar: MoolDestinationNavigationV2(
            activeId: family.id,
            destinationLabel: family.label,
            selectedLocalIndex: 0,
            localActionCount: family.actions.length,
            localNavigation: MoolLocalNavigationRail(
              familyId: family.id,
              semanticLabel: 'Social options',
              activeId: family.actions.first.id,
              actions: [
                for (var index = 0; index < family.actions.length; index++)
                  MoolLocalNavigationAction(
                    keyName: 'c28b-social-${family.actions[index].id}',
                    id: family.actions[index].id,
                    label: family.actions[index].label,
                    icon: family.actions[index].icon,
                    onPressed: index == 0
                        ? null
                        : () => actionLog?.add(family.actions[index].id),
                  ),
              ],
            ),
            onOpenMool: () {},
            onOpenAction: (_) {},
            onOpenChat: () => actionLog?.add('chat'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
