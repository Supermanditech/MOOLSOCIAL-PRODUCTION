import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_design_system.dart';

void main() {
  testWidgets('one native Back control owns size semantics and tap', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: MoolNativeBackButton(
              keyName: 'native-back-under-test',
              onPressed: () => taps += 1,
            ),
          ),
        ),
      ),
    );

    final control = find.byKey(const ValueKey('native-back-under-test'));
    expect(tester.getSize(control), const Size(44, 44));
    expect(
      find.descendant(of: control, matching: find.byType(BackButtonIcon)),
      findsOneWidget,
    );
    expect(find.byTooltip('Back'), findsOneWidget);

    await tester.tap(control);
    await tester.pump();
    expect(taps, 1);
  });

  test('all shared vertical scaffolds consume the one native Back owner', () {
    const paths = <String>[
      'lib/features/eat/widgets/eat_widgets.dart',
      'lib/features/ride/widgets/ride_widgets.dart',
      'lib/features/book/widgets/book_widgets.dart',
      'lib/features/work/widgets/work_widgets.dart',
      'lib/features/pay/widgets/pay_widgets.dart',
      'lib/features/retailer/widgets/retailer_widgets.dart',
      'lib/features/manufacturer/widgets/manufacturer_widgets.dart',
      'lib/features/creator/widgets/creator_widgets.dart',
      'lib/features/operations/widgets/operations_widgets.dart',
      'lib/features/captain/widgets/captain_widgets.dart',
    ];

    for (final path in paths) {
      final source = File(path).readAsStringSync();
      expect(source, contains('MoolNativeBackButton('), reason: path);
      expect(
        source,
        isNot(contains('Icons.arrow_back_ios_new_rounded')),
        reason: path,
      );
      expect(source, isNot(contains("tooltip: 'Go back'")), reason: path);
    }
  });

  test(
    'native Back implementation stays transparent and platform adaptive',
    () {
      final design = File(
        'lib/core/design/mool_design_system.dart',
      ).readAsStringSync();
      final profile = File(
        'lib/ui_v2/profile/global_profile_panel_v2.dart',
      ).readAsStringSync();

      expect(design, contains('class MoolNativeBackButton'));
      expect(design, contains('MoolMetrics.minimumTapTarget'));
      expect(design, contains('backgroundColor: Colors.transparent'));
      expect(design, contains('icon: const BackButtonIcon()'));
      expect(profile, contains('MoolNativeBackButton('));
    },
  );
}
