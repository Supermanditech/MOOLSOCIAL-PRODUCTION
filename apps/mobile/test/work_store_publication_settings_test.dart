import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/work/work_models.dart';
import 'package:moolsocial/features/work/work_publication.dart';
import 'package:moolsocial/features/work/work_services.dart';
import 'package:moolsocial/features/work/work_session.dart';
import 'fixtures/store_public_handoff_v1.dart';

void main() {
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
        final public = p.toBuyPublicProduct(
          storeId: 'store-a',
          storeName: 'Test Store',
          channel: channel,
          storeDetails: d,
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
