import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/work/widgets/store_settings_widgets.dart';
import 'package:moolsocial/features/work/widgets/store_payment_terms.dart';
import 'package:moolsocial/features/work/work_models.dart';
import 'package:moolsocial/features/work/work_services.dart';
import 'package:moolsocial/features/work/work_session.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';

void main() {
  for (final boundary in ['account', 'Store ABA', 'disposed']) {
    test('LF25 session mutation rejects stale $boundary context', () {
      final accounts = _Lf25Accounts();
      final work = _lf25Work(accounts);
      var disposed = false;
      addTearDown(() { if (!disposed) work.dispose(); });
      final originalContext = work.publicationPreferencesContext;
      final customer = work.workspaceCustomerBook.first.id;
      if (boundary == 'account') {
        accounts.accountScope = 'host-account-b';
      } else if (boundary == 'Store ABA') {
        work.activeWorkspace = _lf25Store('host-store-b');
        work.activeWorkspace = _lf25Store('host-store-a');
      } else {
        work.dispose();
        disposed = true;
      }
      final destination = work.workspacePublicationDetails.toJson();
      expect(work.saveWorkspaceCustomerPaymentTerms(expectedContext: originalContext,
        expectedStoreId: 'host-store-a', customerId: customer, terms: const [
          WorkspacePaymentTerm(BuyV2CommercialPaymentTermKind.wholesaleAdvance)]), isFalse);
      expect(work.workspacePublicationDetails.toJson(), destination);
    });
  }

  testWidgets('LF25 current customer can apply, reject invalid terms and inherit', (tester) async {
    final work = _lf25Work(_Lf25Accounts());
    addTearDown(work.dispose);
    final customer = work.workspaceCustomerBook.first.id;
    await _lf25Mount(tester, work, customer, 1);
    await tester.tap(find.text('Wholesale payment terms'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-customer-terms-inherit')));
    await tester.pumpAndSettle();
    void edit(List<WorkspacePaymentTerm> terms) => tester.widget<StorePaymentTermsEditor>(
      find.byType(StorePaymentTermsEditor)).onChanged(terms);
    VoidCallback apply() => tester.widget<FilledButton>(
      find.byKey(const Key('work-customer-terms-save'))).onPressed!;
    edit(const [WorkspacePaymentTerm(BuyV2CommercialPaymentTermKind.bookingBalanceOnDelivery,
      advancePercent: 25)]);
    apply()();
    await tester.pumpAndSettle();
    expect(work.workspacePublicationDetails.customerPaymentTerms[customer]!.single.advancePercent, 25);
    final valid = work.workspacePublicationDetails.toJson();
    edit(const [WorkspacePaymentTerm(BuyV2CommercialPaymentTermKind.bookingBalanceOnDelivery,
      advancePercent: 100)]);
    apply()();
    await tester.pumpAndSettle();
    expect(work.workspacePublicationDetails.toJson(), valid);
    expect(find.text('Check the terms and reopen this customer in the correct Store.'), findsOneWidget);
    edit(const []);
    apply()();
    await tester.pumpAndSettle();
    expect(work.workspacePublicationDetails.customerPaymentTerms[customer], isEmpty);
    await tester.ensureVisible(find.byKey(const Key('work-customer-terms-inherit')));
    await tester.tap(find.byKey(const Key('work-customer-terms-inherit')));
    await tester.pumpAndSettle();
    apply()();
    await tester.pumpAndSettle();
    expect(work.workspacePublicationDetails.customerPaymentTerms.containsKey(customer), isFalse);
    expect(find.text('Customer preferences applied'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final scale in [1.0, 2.0]) {
    for (final boundary in ['account', 'Store ABA', 'disposed', 'customer retarget']) {
      testWidgets('LF25 $boundary callback preserves destination terms at $scale', (tester) async {
        final accounts = _Lf25Accounts();
        final work = _lf25Work(accounts);
        addTearDown(work.dispose);
        final customerA = work.workspaceCustomerId('Host buyer A · 9000091991');
        final customerB = work.workspaceCustomerId('Host buyer B · 9000091992');
        expect(work.workspaceCustomerBook.map((c) => c.id), containsAll([customerA, customerB]));
        await _lf25Mount(tester, work, customerA, scale);
        await tester.tap(find.text('Wholesale payment terms'));
        await tester.pumpAndSettle();
        final inherit = find.byKey(const Key('work-customer-terms-inherit'));
        await tester.ensureVisible(inherit);
        await tester.tap(inherit);
        await tester.pumpAndSettle();
        expect(tester.widget<SwitchListTile>(inherit).value, isFalse);
        final oldApply = tester.widget<FilledButton>(find.byKey(const Key('work-customer-terms-save'))).onPressed!;
        if (boundary == 'account') {
          accounts.accountScope = 'host-account-b';
          expect(work.saveWorkspacePublicationDetails(const WorkspaceStorePublicationDetails(
            legalName: 'Destination account preferences')), isTrue);
        } else if (boundary == 'Store ABA') {
          work.activeWorkspace = _lf25Store('host-store-b');
          work.activeWorkspace = _lf25Store('host-store-a');
        } else if (boundary == 'disposed') {
          await tester.pumpWidget(const SizedBox.shrink());
        } else {
          await _lf25Mount(tester, work, customerB, scale);
          await tester.tap(find.text('Wholesale payment terms'));
          await tester.pumpAndSettle();
          expect(tester.widget<SwitchListTile>(inherit).value, isTrue,
            reason: 'A deliberately retargeted editor must initialize the new customer');
        }
        final destination = work.workspacePublicationDetails.toJson();
        expect(oldApply, returnsNormally);
        await tester.pumpAndSettle();
        expect(work.workspacePublicationDetails.toJson(), destination);
        expect(tester.takeException(), isNull);
        if (boundary == 'customer retarget') {
          final currentApply = tester.widget<FilledButton>(find.byKey(const Key('work-customer-terms-save'))).onPressed!;
          currentApply();
          await tester.pumpAndSettle();
          expect(find.text('Customer preferences applied'), findsOneWidget);
          expect(work.workspacePublicationDetails.customerPaymentTerms.containsKey(customerB), isFalse);
        }
      });
    }
  }
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

// Isolated host-only account/Store/customer fixture, never runtime Stock/orders.
class _Lf25Accounts implements WorkPendingProofStore {
  @override
  String accountScope = 'host-account-a';
  @override
  Future<Map<String, Object?>?> read(String scope) async => null;
  @override
  Future<void> save(String scope, Map<String, Object?> draft) async {}
  @override
  Future<void> clear(String scope) async {}
}

WorkWorkspace _lf25Store(String id) => WorkWorkspace(id: id, name: 'Host Store',
  profileLabel: 'Retailer / Grocery Store', profileId: 'retailer-grocery-store',
  area: 'Host area', verified: true);

WorkSession _lf25Work(_Lf25Accounts accounts) {
  final work = WorkSession(gateway: ReviewWorkGateway(), contactDraftStore: accounts)
    ..activeWorkspace = _lf25Store('host-store-a');
  for (final buyer in ['Host buyer A · 9000091991', 'Host buyer B · 9000091992']) {
    work.workspaceOrders.add(WorkspaceOrderRecord(id: buyer, customer: buyer,
      items: 'Host item × 1', quantities: const {'host-item': 1}, amount: 1,
      source: 'App', fulfilment: 'Pickup', payment: 'Paid online', address: '',
      stage: 'Completed', needsDelivery: false, createdAt: DateTime(2026, 10, 16)));
  }
  return work;
}

Future<void> _lf25Mount(WidgetTester tester, WorkSession work, String customer, double scale) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(320, 700);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(scale)), child: child!),
    home: Scaffold(body: SingleChildScrollView(child: StoreCustomerPaymentTerms(
      key: const ValueKey('host-customer-editor'), session: work,
      storeId: 'host-store-a', customerId: customer))),
  ));
  await tester.pumpAndSettle();
}
