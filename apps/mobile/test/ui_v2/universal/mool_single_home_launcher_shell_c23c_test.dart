import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_design_system.dart';
import 'package:moolsocial/ui_v2/universal/mool_global_navigation_v2.dart';

void main() {
  testWidgets('C32T destination shell renders compact Mool, local rail and Chat', (
    tester,
  ) async {
    var homeTaps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: MoolDestinationNavigationV2(
            activeId: 'buy',
            destinationLabel: 'Buy',
            selectedLocalIndex: 0,
            localActionCount: 4,
            localNavigation: const SizedBox(key: Key('accepted-local-rail')),
            onOpenMool: () => homeTaps++,
            onOpenAction: (_) {},
            onOpenChat: () {},
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('moolsocial-single-home-launcher-shell')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('moolsocial-compact-destination-rail')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
    expect(find.byKey(const Key('accepted-local-rail')), findsOneWidget);
    expect(find.byKey(const Key('mool-global-chat')), findsOneWidget);
    expect(find.byType(MoolOutcomeDock), findsNothing);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Shop'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('mool-compact-launcher'))).height,
      MoolLocalNavigationTokens.destinationRailHeight,
    );
    expect(find.text('Mool'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('mool-compact-launcher'))).width,
      MoolLocalNavigationTokens.destinationFixedCellWidth,
    );
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Open MoolSocial main menu'))
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );

    await tester.tap(find.byKey(const Key('mool-compact-launcher')));
    await tester.pumpAndSettle();
    expect(homeTaps, 0);
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsOneWidget,
    );
  });

  testWidgets('C23C Mool Home has no bottom navigation control', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: MoolGlobalNavigationV2(
            activeId: 'mool',
            onOpenMool: null,
            onOpenAction: (_) {},
            onOpenChat: () {},
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('moolsocial-home-has-no-bottom-navigation')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('mool-home-launcher')), findsNothing);
    expect(find.byType(MoolOutcomeDock), findsNothing);
  });
}
