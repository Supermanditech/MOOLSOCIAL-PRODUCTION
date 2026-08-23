import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_design_system.dart';
import 'package:moolsocial/ui_v2/universal/mool_global_navigation_v2.dart';
import 'package:moolsocial/ui_v2/universal/personal_mool_root_v2.dart';

void main() {
  testWidgets('C25C popup exposes six main domains and no subactions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    MoolActionFamilySpec? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 568),
            textScaler: TextScaler.linear(1.4),
          ),
          child: Scaffold(
            body: MoolConnectedActionNavigator(
              initialFamilyId: 'buy',
              onOpenFamily: (family) => selected = family,
              onDismiss: () {},
            ),
          ),
        ),
      ),
    );

    for (final family in moolActionFamilies) {
      final control = find.byKey(
        ValueKey('mool-navigator-family-${family.id}'),
      );
      expect(control, findsOneWidget);
      expect(tester.getSize(control).height, greaterThanOrEqualTo(44));
      expect(
        tester
            .getSemantics(
              find.bySemanticsLabel(
                family.id == 'buy'
                    ? '${family.label}, current domain'
                    : 'Open ${family.label}',
              ),
            )
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
    }
    for (final subaction in const [
      'Products',
      'Wholesale',
      'Orders',
      'Order Food',
      'Book Table',
      'Medicine',
      'Bus',
      'Workspace',
    ]) {
      expect(find.text(subaction), findsNothing);
    }
    expect(find.byType(MoolActionChooser), findsNothing);

    await tester.tap(find.byKey(const ValueKey('mool-navigator-family-buy')));
    expect(selected?.route, '/app/buy?sub=shop');
  });

  testWidgets('C25C MoolSocial Home uses the same main-only menu', (
    tester,
  ) async {
    final routes = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: PersonalMoolRootV2(
          onBack: () {},
          onOpenAction: (_) {},
          onOpenRoute: routes.add,
          onOpenChat: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('mool-home-main-actions-only')),
      findsOneWidget,
    );
    expect(find.byType(MoolActionChooser), findsNothing);
    await tester.tap(find.byKey(const ValueKey('mool-home-family-eat')));
    expect(routes, ['/app/eat/home']);
  });

  testWidgets('C25C dialog motion is immediate under reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: const SizedBox.expand(),
            bottomNavigationBar: MoolGlobalNavigationV2(
              activeId: 'work',
              onOpenMool: null,
              onOpenAction: _ignoreAction,
              onOpenChat: null,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('mool-home-launcher')));
    await tester.pump();
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsOneWidget,
    );
    expect(
      MoolLocalNavigationTokens.selectionDuration,
      const Duration(milliseconds: 180),
    );
  });
}

void _ignoreAction(PersonalMoolActionSpec action) {}
