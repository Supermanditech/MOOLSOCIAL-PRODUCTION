import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_design_system.dart';
import 'package:moolsocial/ui_v2/universal/mool_global_navigation_v2.dart';

void main() {
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
      expect(tester.getSize(shell).height, greaterThanOrEqualTo(129));
      expect(tester.getSize(rail).height, 58);
      expect(tester.getBottomRight(rail).dy, lessThanOrEqualTo(735));
      expect(
        tester.getSize(find.bySemanticsLabel('Open MoolSocial main menu')),
        const Size(54, 58),
      );
      expect(
        tester.getSize(find.byKey(const Key('mool-global-chat'))),
        const Size(54, 58),
      );
      final moolBounds = tester.getRect(
        find.bySemanticsLabel('Open MoolSocial main menu'),
      );
      const exportedRootBottom = 806 - 41 - 44;
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
      expect(tester.getBottomRight(rail).dy, lessThanOrEqualTo(735));
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
}) async {
  tester.view.viewPadding = const FakeViewPadding(top: 41, bottom: 44);
  addTearDown(tester.view.resetViewPadding);
  final family = moolActionFamilyById('social');
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(360, 806),
          padding: const EdgeInsets.only(top: 41, bottom: 44),
          viewPadding: const EdgeInsets.only(top: 41, bottom: 44),
          viewInsets: viewInsets,
          textScaler: const TextScaler.linear(1.4),
          disableAnimations: disableAnimations,
          accessibleNavigation: disableAnimations,
        ),
        child: Scaffold(
          extendBody: true,
          body: const ColoredBox(color: Colors.black),
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
                    onPressed: index == 0 ? null : () {},
                  ),
              ],
            ),
            onOpenMool: () {},
            onOpenAction: (_) {},
            onOpenChat: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
