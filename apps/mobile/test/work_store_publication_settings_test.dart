import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:moolsocial/features/work/widgets/store_publication_settings.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/work/work_models.dart';
import 'package:moolsocial/features/work/work_publication.dart';
import 'package:moolsocial/features/work/work_services.dart';
import 'package:moolsocial/features/work/work_session.dart';
import 'fixtures/store_public_handoff_v1.dart';

void main() {
  test('LF06 new Store location is unknown rather than fabricated', () {
    final work = WorkSession(gateway: ReviewWorkGateway());
    addTearDown(work.dispose);
    expect(work.workspaceDeliveryCity, isEmpty);
    expect(work.workspaceDeliveryArea, isEmpty);
    expect(work.workspaceDeliveryPincode, isEmpty);
    expect(work.workspacePublicStoreDetails, isNull);
  });
  test('LF06 stale and ABA readiness saves cannot mutate another settings scope', () {
    final gateway = ReviewWorkGateway();
    final work = WorkSession(gateway: gateway);
    addTearDown(work.dispose);
    const a = WorkWorkspace(id: 'host-lf06-a', name: 'Host A', profileId: 'retailer-grocery',
      profileLabel: 'Grocery', area: 'Jaipur', verified: true);
    const b = WorkWorkspace(id: 'host-lf06-b', name: 'Host B', profileId: 'retailer-grocery',
      profileLabel: 'Grocery', area: 'Delhi', verified: true);
    work.activeWorkspace = a;
    final revision = work.navigationScopeRevision;
    work.activeWorkspace = b;
    for (final target in [b, a]) {
      work.activeWorkspace = target;
      final before = (work.workspaceAcceptingOrders, work.workspaceBusyMinutes,
        work.workspaceOpeningTime, work.workspaceDeliveryCity, gateway.operationalSaveCalls);
      expect(work.saveWorkspaceAvailability(acceptingOrders: false,
        fulfilmentMode: 'Pickup', busyMinutes: 10, reopensAt: '',
        expectedStoreId: a.id, expectedNavigationRevision: revision), isFalse);
      expect(work.saveWorkspaceTradingControls(openingTime: '09:00', closingTime: '20:00',
        maximumActiveOrders: 12, alertSound: false, alertVibration: false,
        expectedStoreId: a.id, expectedNavigationRevision: revision), isFalse);
      expect(work.saveWorkspaceDeliverySettings(city: 'Jaipur', area: 'Host lane',
        pincode: '302001', expectedStoreId: a.id,
        expectedNavigationRevision: revision), isFalse);
      expect((work.workspaceAcceptingOrders, work.workspaceBusyMinutes,
        work.workspaceOpeningTime, work.workspaceDeliveryCity, gateway.operationalSaveCalls), before);
    }
    expect(work.saveWorkspaceAvailability(acceptingOrders: false,
      fulfilmentMode: 'Pickup', busyMinutes: -1, reopensAt: ''), isFalse);
    expect(work.workspaceAcceptingOrders, isFalse);
    expect(work.saveWorkspaceAvailability(acceptingOrders: true,
      fulfilmentMode: 'Pickup', busyMinutes: 10, reopensAt: '', expectedStoreId: a.id,
      expectedNavigationRevision: work.navigationScopeRevision), isTrue);
    expect(work.workspaceBusyMinutes, 10);
    expect(handoffStock().toBuyPublicFacts(storeName: 'Host A', sourceId: 'host-local',
      storeVisible: true, acceptingOrders: true, observedAt: DateTime.utc(2026,10,15)).fulfilmentMode, isNull);
    expect(handoffStock().toBuyPublicFacts(storeName: 'Host A', sourceId: 'host-local',
      storeVisible: true, acceptingOrders: true, observedAt: DateTime.utc(2026,10,15)).eligibility, isNull);
  });
  for (final aba in [false, true]) {
    testWidgets('LF06 publication form captures original scope eagerly ABA$aba', (tester) async {
      final work = WorkSession(gateway: ReviewWorkGateway());
      addTearDown(work.dispose);
      const a = WorkWorkspace(id: 'lf06-form-a', name: 'Host A', profileId: 'retailer-grocery',
        profileLabel: 'Grocery', area: 'Jaipur', verified: true);
      work.activeWorkspace = a;
      work.saveWorkspacePublicationDetails(handoffStoreDetails());
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(
        child: StorePublicationSettings(session: work)))));
      await tester.tap(find.byKey(const PageStorageKey('work-publication-address-section')));
      await tester.pumpAndSettle();
      work.activeWorkspace = const WorkWorkspace(id: 'lf06-form-b', name: 'Host B',
        profileId: 'retailer-grocery', profileLabel: 'Grocery', area: 'Delhi', verified: true);
      if (aba) work.activeWorkspace = a;
      final before = work.workspacePublicationDetails.toJson();
      final save = find.byKey(const Key('work-publication-save-address'));
      await Scrollable.ensureVisible(tester.element(save), alignment: .3);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(work.workspacePublicationDetails.toJson(), before);
      expect(find.textContaining('Your Store changed.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  test(
    'LF02 public contact and explicit hours round trip without private fields',
    () {
      final details = WorkspaceStorePublicationDetails.fromJson({
        'publicContactPhone': '+91 98765 43210',
        'openingTime': '22:00',
        'closingTime': '06:00',
        'pan': 'PRIVATE-PAN',
        'signatory': 'Private signatory',
        'billingAddress': 'Private billing address',
      });
      final saved = details.toJson();
      expect(saved['publicContactPhone'], '+91 98765 43210');
      expect(saved['openingTime'], '22:00');
      expect(saved['closingTime'], '06:00');
      expect(WorkspaceStorePublicationDetails.fromJson(saved).toJson(), saved);
      final public = details.toPublicStore(
        id: 'host-a',
        name: 'Host Store',
        area: 'Jaipur',
      );
      expect(public.publicContactPhone, '+91 98765 43210');
      expect(public.openingHoursLabel, '22:00 – 06:00');
      expect(
        const WorkspaceStorePublicationDetails(publicContactPhone: 'invalid')
            .toPublicStore(id: 'host-a', name: 'Host Store', area: 'Jaipur')
            .publicContactPhone,
        isNull,
      );
      for (final patch in <Map<String, Object?>>[
        {'publicContactPhone': 'call my login'},
        {'publicContactPhone': '+123'},
        {'publicContactPhone': 9876543210},
        {'openingTime': '25:00', 'closingTime': '18:00'},
        {'openingTime': '08:00', 'closingTime': ''},
      ]) {
        expect(
          () => WorkspaceStorePublicationDetails.fromJson(patch),
          throwsFormatException,
        );
      }
    },
  );

  test('LF02 public hours stay absent until explicitly saved', () {
    final work = WorkSession(gateway: ReviewWorkGateway())
      ..activeWorkspace = const WorkWorkspace(
        id: 'lf02-host-store',
        name: 'Host fixture Store',
        profileId: 'retailer-grocery',
        profileLabel: 'Grocery',
        area: 'Jaipur',
        verified: true,
      );
    addTearDown(work.dispose);
    expect(
      work.workspacePublicationDetails.toJson().containsKey('openingTime'),
      isFalse,
    );
    expect(work.workspacePublicStoreDetails!.openingHoursLabel, isNull);
    expect(work.workspacePublicStoreDetails!.publicContactPhone, isNull);
    work.saveWorkspaceTradingControls(
      openingTime: '22:00',
      closingTime: '06:00',
      maximumActiveOrders: 0,
      alertSound: true,
      alertVibration: false,
    );
    expect(work.workspacePublicationDetails.toJson()['openingTime'], '22:00');
    expect(work.workspacePublicationDetails.toJson()['closingTime'], '06:00');
    expect(
      work.workspacePublicStoreDetails!.openingHoursLabel,
      '22:00 – 06:00',
    );
    work.activeWorkspace = const WorkWorkspace(
      id: 'lf02-host-store-b',
      name: 'Other host Store',
      profileId: 'retailer-grocery',
      profileLabel: 'Grocery',
      area: 'Delhi',
      verified: true,
    );
    expect(work.workspacePublicStoreDetails!.openingHoursLabel, isNull);
    expect(work.workspacePublicStoreDetails!.publicContactPhone, isNull);
  });

  testWidgets('LF02 existing Store form validates and saves public contact', (
    tester,
  ) async {
    final work = WorkSession(gateway: ReviewWorkGateway())
      ..activeWorkspace = const WorkWorkspace(
        id: 'lf02-host-form',
        name: 'Host fixture Store',
        profileId: 'retailer-grocery',
        profileLabel: 'Grocery',
        area: 'Jaipur',
        verified: true,
      );
    addTearDown(work.dispose);
    work.saveWorkspacePublicationDetails(handoffStoreDetails());
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StorePublicationSettings(session: work),
          ),
        ),
      ),
    );
    await tester.tap(
      find.byKey(const PageStorageKey('work-publication-address-section')),
    );
    await tester.pumpAndSettle();
    final contact = find.byKey(
      const Key('work-publication-publicContactPhone'),
    );
    await tester.ensureVisible(contact);
    await tester.enterText(contact, 'not a number');
    final save = find.byKey(const Key('work-publication-save-address'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid customer contact number.'), findsOneWidget);
    expect(work.workspacePublicationDetails.publicContactPhone, isEmpty);
    await tester.ensureVisible(contact);
    await tester.enterText(contact, '+91 98765 43210');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(
      work.workspacePublicStoreDetails!.publicContactPhone,
      '+91 98765 43210',
    );
    work.saveWorkspaceTradingControls(
      openingTime: '09:30',
      closingTime: '18:45',
      maximumActiveOrders: 0,
      alertSound: true,
      alertVibration: false,
    );
    final beforeInvalid = work.workspacePublicationDetails.toJson();
    work.saveWorkspaceTradingControls(
      openingTime: 'invalid',
      closingTime: '06:00',
      maximumActiveOrders: 10,
      alertSound: false,
      alertVibration: true,
    );
    expect(work.workspacePublicationDetails.toJson(), beforeInvalid);
    expect(work.workspaceOpeningTime, '09:30');
    expect(work.workspaceMaximumActiveOrders, 0);
    await tester.ensureVisible(contact);
    await tester.enterText(contact, '');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(work.workspacePublicStoreDetails!.publicContactPhone, isNull);
    expect(
      work.workspacePublicStoreDetails!.openingHoursLabel,
      '09:30 – 18:45',
    );
    final restored = WorkspaceStorePublicationDetails.fromJson(
      work.workspacePublicationDetails.toJson(),
    );
    expect(restored.publicContactPhone, isEmpty);
    expect(restored.openingTime, '09:30');
    expect(restored.closingTime, '18:45');
    expect(
      work.workspacePublicationDetails.signatory,
      handoffStoreDetails().signatory,
    );
    expect(work.workspaceVisibleToCustomers, isFalse);
    expect(tester.takeException(), isNull);
  });

  TestWidgetsFlutterBinding.ensureInitialized();
  test('PAYMENT-TERMS canonical kinds round trip and invalid terms reject', () {
    for (final kind in WorkspacePaymentTerm.wholesaleKinds) {
      final term = WorkspacePaymentTerm(
        kind,
        advancePercent: WorkspacePaymentTerm(kind).needsAdvance ? 25 : null,
        netDays: kind == BuyV2CommercialPaymentTermKind.supplierCredit
            ? 30
            : null,
      );
      expect(term.valid, isTrue);
      expect(
        WorkspacePaymentTerm.fromJson(term.toJson()).toJson(),
        term.toJson(),
      );
    }
    for (final data in [
      {'kind': 'regulatedCredit'},
      {'kind': 'retailAdvance'},
      {'kind': 'supplierCredit', 'netDays': 0},
      {'kind': 'supplierCredit', 'netDays': 366},
      {'kind': 'supplierCredit', 'netDays': '30'},
      {'kind': 'bookingBalanceBeforeDispatch', 'advancePercent': 100},
      {'kind': 'bookingBalanceOnDelivery', 'advancePercent': 0},
      {'kind': 'paymentOnDelivery', 'netDays': 30},
    ]) {
      expect(() => WorkspacePaymentTerm.fromJson(data), throwsFormatException);
    }
    expect(
      () => WorkspacePaymentTerm.decodeList([
        {'kind': 'wholesaleAdvance'},
        {'kind': 'wholesaleAdvance'},
      ]),
      throwsFormatException,
    );
  });
  test(
    'PAYMENT-TERMS customer overrides never change other customers or retail',
    () {
      final d = WorkspaceStorePublicationDetails.fromJson({
        'wholesalePaymentTerms': [
          {'kind': 'wholesaleAdvance'},
        ],
        'customerPaymentTerms': {
          'customer-a': [
            {'kind': 'paymentOnDelivery'},
            {'kind': 'supplierCredit', 'netDays': 30, 'advancePercent': 20},
          ],
          'customer-blocked': <Object?>[],
        },
      });
      expect(
        d
            .paymentTermsFor(
              channel: BuyV2Destination.wholesale,
              customerId: 'customer-a',
            )
            .length,
        2,
      );
      expect(
        d
            .paymentTermsFor(
              channel: BuyV2Destination.wholesale,
              customerId: 'customer-b',
            )
            .single
            .kind,
        BuyV2CommercialPaymentTermKind.wholesaleAdvance,
      );
      expect(
        d.paymentTermsFor(
          channel: BuyV2Destination.wholesale,
          customerId: 'customer-blocked',
        ),
        isEmpty,
      );
      expect(
        d
            .paymentTermsFor(
              channel: BuyV2Destination.shop,
              customerId: 'customer-a',
            )
            .single
            .kind,
        BuyV2CommercialPaymentTermKind.retailAdvance,
      );
      expect(
        WorkspaceStorePublicationDetails.fromJson(d.toJson()).toJson(),
        d.toJson(),
      );
      expect(
        () => d.customerPaymentTerms['other'] = [],
        throwsUnsupportedError,
      );
      expect(
        () => d.customerPaymentTerms['customer-a']!.clear(),
        throwsUnsupportedError,
      );
      final public = handoffStock().toBuyPublicProduct(
        storeId: 'a',
        storeName: 'Store A',
        storeDetails: d,
      );
      expect(
        WorkspacePublicationContract.publicProductValues(public).toString(),
        isNot(contains('customer-a')),
      );
    },
  );
  test('LF05 invalid preferences preserve defaults and reject stale Store saves', () {
    final work = WorkSession(gateway: ReviewWorkGateway());
    addTearDown(work.dispose);
    const storeA = WorkWorkspace(id: 'host-lf05-a', name: 'Host A',
      profileId: 'retailer-grocery', profileLabel: 'Grocery', area: 'Jaipur', verified: true);
    const storeB = WorkWorkspace(id: 'host-lf05-b', name: 'Host B',
      profileId: 'retailer-grocery', profileLabel: 'Grocery', area: 'Delhi', verified: true);
    work.activeWorkspace = storeA;
    const defaults = WorkspaceStorePublicationDetails(returnSummary: 'Host return defaults',
      wholesalePaymentTerms: [WorkspacePaymentTerm(BuyV2CommercialPaymentTermKind.wholesaleAdvance)]);
    expect(work.saveWorkspacePublicationDetails(defaults, expectedStoreId: storeA.id), isTrue);
    expect(work.saveWorkspacePublicationDetails(const WorkspaceStorePublicationDetails(
      returnSummary: 'Must not replace saved terms', wholesalePaymentTerms: [
        WorkspacePaymentTerm(BuyV2CommercialPaymentTermKind.bookingBalanceBeforeDispatch,
          advancePercent: 100)]), expectedStoreId: storeA.id), isFalse);
    expect(work.workspacePublicationDetails.toJson(), defaults.toJson());
    work.activeWorkspace = storeB;
    expect(work.saveWorkspacePublicationDetails(defaults, expectedStoreId: storeA.id), isFalse);
    expect(work.workspacePublicationDetails.returnSummary, isEmpty);
    work.activeWorkspace = storeA;
    expect(work.workspacePublicationDetails.toJson(), defaults.toJson());
  });
  WorkspaceStorePublicationDetails details() =>
      WorkspaceStorePublicationDetails.fromJson({
        ...handoffStoreDetails().toJson(),
        'returnWindowDays': 7,
        'returnConditions': 'Keep the invoice and original pack.',
        'returnRemedies': ['Replacement', 'Refund'],
      });
  test(
    'STORE-SETTINGS one-time details round trip without inventing confirmation',
    () {
      final d = details();
      final decoded = WorkspaceStorePublicationDetails.fromJson(d.toJson());
      expect(decoded.toJson(), d.toJson());
      expect(decoded.issues, isEmpty);
      final public = decoded.toPublicStore(
        id: 'store-a',
        name: 'Test Store',
        area: 'Jaipur',
      );
      expect(public.address, '1 Test Lane, Jaipur, Rajasthan, 302001');
      expect(public.regionId, 'fixture-region-jaipur');
      expect(public.collection, isNull);
      final protection = decoded.protectionFor(null)!;
      expect(protection.windowLabel, '7 days from delivery');
      expect(protection.remedies, ['Refund', 'Replacement']);
      expect(protection.verificationLabel, isNull);
      expect(protection.refundTimelineLabel, isNull);
      expect(protection.approvalLabel, isNull);
    },
  );
  test(
    'STORE-SETTINGS product overrides do not inherit contradictory windows/remedies',
    () {
      final protection = details().protectionFor(
        'Replacement only within 2 days.',
      )!;
      expect(protection.summary, 'Replacement only within 2 days.');
      expect(protection.windowLabel, isNull);
      expect(protection.remedies, isEmpty);
    },
  );
  test(
    'STORE-SETTINGS channel/provider/customer payment intersection never enables unsupported methods',
    () {
      final d = details();
      expect(
        d.eligiblePaymentMethods(
          channel: BuyV2Destination.shop,
          providerSupported: {'PhonePe'},
          customerSupported: {'PhonePe', 'Paytm'},
        ),
        {'PhonePe'},
      );
      expect(
        d.eligiblePaymentMethods(
          channel: BuyV2Destination.shop,
          providerSupported: {},
          customerSupported: {'PhonePe'},
        ),
        isEmpty,
      );
      expect(
        d.eligiblePaymentMethods(
          channel: BuyV2Destination.wholesale,
          providerSupported: {'Bank transfer'},
          customerSupported: {'PhonePe'},
        ),
        isEmpty,
      );
      expect(
        d.eligiblePaymentMethods(
          channel: BuyV2Destination.wholesale,
          providerSupported: {'Bank transfer'},
          customerSupported: {'Bank transfer'},
        ),
        {'Bank transfer'},
      );
    },
  );
  test(
    'STORE-SETTINGS Shop and Wholesale inherit terms without repeating SKU entry',
    () {
      final d = details();
      final p = handoffStock().copyWith(returnPolicy: '');
      for (final channel in [
        BuyV2Destination.shop,
        BuyV2Destination.wholesale,
      ]) {
        final terms = channel == BuyV2Destination.wholesale
            ? handoffSellingTerms(p, 'store-a') : null;
        final public = p.toBuyPublicProduct(
          storeId: 'store-a',
          storeName: 'Test Store',
          channel: channel,
          storeDetails: d,
          publicPackTerms: terms,
        );
        expect(public.returnPolicy, d.returnSummary);
        expect(public.purchaseProtection!.windowLabel, '7 days from delivery');
        expect(
          WorkspacePublicationContract.productIssues(
            p,
            storeId: 'store-a',
            storeName: 'Test Store',
            channel: channel,
            storeDetails: d,
            publicPackTerms: terms,
          ),
          isEmpty,
        );
        expect(
          WorkspacePublicationContract.productIssues(
            p,
            storeId: 'store-a',
            storeName: 'Test Store',
            channel: channel,
            storeDetails: d,
            publicPackTerms: terms,
            projected: public.copyWith(
              purchaseProtection: const BuyV2PurchaseProtection(
                summary: 'Wrong terms',
              ),
            ),
          ),
          isNotEmpty,
        );
      }
      expect(
        p.returnPolicy,
        '',
      ); // No copies of one-time defaults written into stock.
    },
  );
  test(
    'STORE-SETTINGS invalid fields cannot pass serialization or publication',
    () {
      for (final patch in <Map<String, Object?>>[
        {'pinCode': '000000'},
        {'dispatchDays': -1},
        {'returnWindowDays': 366},
        {
          'retailPaymentMethods': ['Unknown gateway'],
        },
        {
          'wholesalePaymentMethods': ['Made up'],
        },
        {
          'returnRemedies': ['Automatic approval'],
        },
        {
          'shoppingArea': {'regionId': 1},
        },
        {'returnWindowDays': 'seven'},
      ]) {
        expect(
          () => WorkspaceStorePublicationDetails.fromJson({
            ...details().toJson(),
            ...patch,
          }),
          throwsFormatException,
        );
      }
      final noLocation = WorkspaceStorePublicationDetails.fromJson({
        ...details().toJson(),
        'shoppingArea': null,
      });
      expect(
        noLocation.issues,
        contains('Confirm the Store location before publishing.'),
      );
    },
  );
  test(
    'STORE-SETTINGS save is Store-scoped immutable and cannot publish or change stock',
    () async {
      const a = WorkWorkspace(
        id: 'a',
        name: 'Store A',
        profileId: 'retailer-grocery',
        profileLabel: 'Grocery',
        area: 'Jaipur',
        verified: true,
      );
      const b = WorkWorkspace(
        id: 'b',
        name: 'Store B',
        profileId: 'retailer-grocery',
        profileLabel: 'Grocery',
        area: 'Jaipur',
        verified: true,
      );
      final gateway = ReviewWorkGateway();
      final work = WorkSession(gateway: gateway)..activeWorkspace = a;
      addTearDown(work.dispose);
      final product = handoffStock();
      work.workspaceCatalogueItems.add(product);
      expect(
        work.saveWorkspacePublicationDetails(details(), expectedStoreId: 'a'),
        isTrue,
      );
      expect(work.workspaceVisibleToCustomers, isFalse);
      expect(work.workspaceCatalogueItems.single, same(product));
      expect(work.workspacePublicStoreDetails!.id, 'a');
      expect(work.workspacePublicStoreDetails!.name, 'Store A');
      expect(work.workspacePublicStoreDetails!.address, details().address);
      work.activeWorkspace = b;
      expect(work.workspacePublicStoreDetails!.id, 'b');
      expect(work.workspacePublicStoreDetails!.address, isEmpty);
      expect(work.workspacePublicationDetails.legalName, isEmpty);
      expect(
        work.saveWorkspacePublicationDetails(details(), expectedStoreId: 'a'),
        isFalse,
      );
      expect(work.workspacePublicationDetails.legalName, isEmpty);
      work.activeWorkspace = a;
      expect(work.workspacePublicationDetails.toJson(), details().toJson());
      expect(
        () =>
            work.workspacePublicationDetails.retailPaymentMethods.add('Paytm'),
        throwsUnsupportedError,
      );
      await Future<void>.delayed(Duration.zero);
      expect(
        gateway.lastOperationalSnapshot!.state['publicationDetails'],
        details().toJson(),
      );
    },
  );
}
