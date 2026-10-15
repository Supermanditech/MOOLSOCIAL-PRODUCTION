import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/work/widgets/store_settings_widgets.dart';
import 'package:moolsocial/features/work/widgets/store_payment_terms.dart';
import 'package:moolsocial/features/work/work_models.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('LF05 payment fields explain invalid values at $scale', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      addTearDown(tester.view.reset);
      var emitted = <WorkspacePaymentTerm>[];
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!),
        home: Scaffold(body: SingleChildScrollView(child: StorePaymentTermsEditor(
          initial: const [WorkspacePaymentTerm(BuyV2CommercialPaymentTermKind.supplierCredit,
            advancePercent: 20, netDays: 30)],
          onChanged: (terms) => emitted = terms,
        ))),
      ));
      final advance = find.byKey(const Key('work-payment-supplierCredit-advance'));
      final days = find.byKey(const Key('work-payment-supplierCredit-days'));
      await tester.ensureVisible(advance);
      await tester.enterText(advance, 'abc');
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(advance).decoration!.errorText,
        'Enter a whole number from 0 to 99.');
      expect(emitted.single.valid, isFalse);
      await tester.enterText(advance, '25');
      await tester.ensureVisible(days);
      await tester.enterText(days, '0');
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(days).decoration!.errorText,
        'Enter a whole number from 1 to 365.');
      await tester.enterText(days, '35');
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(days).decoration!.errorText, isNull);
      expect(emitted.single.valid, isTrue);
      expect(tester.takeException(), isNull);
    });
  }
  for (final scale in [1.0, 1.4]) {
    testWidgets(
      'BATCH1 settings save and validation remain reachable with keyboard $scale',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 700);
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        addTearDown(tester.view.reset);
        final fields = [
          for (var i = 0; i < 6; i++) TextEditingController(text: '10'),
        ];
        addTearDown(() {
          for (final field in fields) {
            field.dispose();
          }
        });
        var saves = 0;
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(
              body: StoreSettingsForm(
                title: 'Store settings',
                detail: 'Check your values.',
                fields: [
                  for (var i = 0; i < fields.length; i++)
                    StoreSettingsInput(
                      id: 'field-$i',
                      label: 'Setting $i',
                      controller: fields[i],
                      numeric: true,
                      validate: (value) =>
                          StoreSettingsInput.whole(value, 0, 20),
                    ),
                ],
                saveKey: 'save',
                saveLabel: 'Save settings',
                onSave: () => saves++,
              ),
            ),
          ),
        );
        await tester.enterText(find.byKey(const Key('field-0')), '100');
        final save = find.byKey(const Key('save'));
        final scroll = find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        );
        await tester.scrollUntilVisible(save, 160, scrollable: scroll);
        await tester.pumpAndSettle();
        expect(save.hitTestable(), findsOneWidget);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(saves, 0);
        final first = find.byKey(const Key('field-0'));
        expect(
          find
              .descendant(of: first, matching: find.byType(EditableText))
              .hitTestable(),
          findsOneWidget,
        );
        expect(tester.getRect(first).bottom, lessThanOrEqualTo(420));
        expect(find.text('Enter a whole number from 0 to 20.'), findsOneWidget);
        await tester.enterText(first, '20');
        await tester.scrollUntilVisible(save, 160, scrollable: scroll);
        await tester.pumpAndSettle();
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(saves, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }
  test('BATCH1 retained hours parse without resetting retailer values', () {
    for (final value in ['9:30 AM', '09:30', ' 9:30 am ']) {
      expect(parseStoreHours(value), const TimeOfDay(hour: 9, minute: 30));
    }
    expect(parseStoreHours('12:00 AM'), const TimeOfDay(hour: 0, minute: 0));
    expect(parseStoreHours('12:00 PM'), const TimeOfDay(hour: 12, minute: 0));
    expect(parseStoreHours('6:45 PM'), const TimeOfDay(hour: 18, minute: 45));
    expect(storeHoursValue(const TimeOfDay(hour: 9, minute: 5)), '09:05');
    for (final invalid in ['25:00', '12:60', '', '13:00 PM', '0:30 AM']) {
      expect(parseStoreHours(invalid), isNull);
    }
  });
  test('BATCH1 whole-number and PIN validation reject silent conversions', () {
    for (final invalid in ['', '10.5', '-1', '10001', 'ten', '1e2']) {
      expect(StoreSettingsInput.whole(invalid, 0, 10000), isNotNull);
    }
    for (final valid in ['0', '10', '10000']) {
      expect(StoreSettingsInput.whole(valid, 0, 10000), isNull);
    }
    expect(StoreSettingsInput.pin('342003'), isNull);
    for (final invalid in ['', '3420037', '000000', '34200a']) {
      expect(StoreSettingsInput.pin(invalid), isNotNull);
    }
  });
}
