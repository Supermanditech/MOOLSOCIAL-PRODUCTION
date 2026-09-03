import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/work/work_models.dart';
import 'package:moolsocial/features/work/work_services.dart';
import 'package:moolsocial/features/work/work_session.dart';

void main() {
  WorkSession liveSession([ReviewWorkGateway? gateway]) {
    final session = WorkSession(gateway: gateway ?? ReviewWorkGateway())
      ..activeWorkspace = const WorkWorkspace(
        id: 'workspace-store-1',
        name: 'Mahadev Fresh Mart',
        profileLabel: 'Grocery / Kirana Shop',
        profileId: 'retailer-grocery',
        area: 'Sardarpura, Jodhpur',
        verified: true,
      )
      ..workspaceId = 'workspace-store-1';
    addTearDown(session.dispose);
    return session;
  }

  test('orders reserve stock once and cancellation restores it', () async {
    final gateway = ReviewWorkGateway();
    final session = liveSession(gateway);
    session.addOrUpdateWorkspaceProduct(_product(stock: 10));
    session.prepareWorkspaceOrder(source: 'Phone', fulfilment: 'At the shop');
    session.adjustWorkspaceOrderQuantity('atta-5kg', 2);
    session.saveWorkspaceOrderDraft(
      customer: '9829012321',
      source: 'Phone',
      fulfilment: 'At the shop',
      payment: 'Cash',
      address: '',
    );

    expect(session.workspaceOrders, hasLength(1));
    expect(session.workspaceOrders.single.stage, 'Confirmed');
    session.advanceWorkspaceOrder();
    expect(session.workspaceOrderStage, 'Preparing');
    expect(session.workspaceCatalogueItems.single.stock, 8);
    expect(session.currentWorkspaceOrder?.stockReserved, isTrue);

    session.cancelWorkspaceOrder();
    expect(session.workspaceOrderStage, 'Cancelled');
    expect(session.workspaceCatalogueItems.single.stock, 10);
    expect(session.currentWorkspaceOrder?.stockReserved, isFalse);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(gateway.operationalSaveCalls, greaterThanOrEqualTo(3));
  });

  test(
    'delivery needs an address and completes only after customer OTP',
    () async {
      final gateway = ReviewWorkGateway();
      final session = liveSession(gateway);
      session.addOrUpdateWorkspaceProduct(_product(stock: 10));
      session.prepareWorkspaceOrder(
        source: 'Phone',
        fulfilment: 'Mool delivery',
      );
      session.adjustWorkspaceOrderQuantity('atta-5kg', 1);
      session.saveWorkspaceOrderDraft(
        customer: '9829012321',
        source: 'Phone',
        fulfilment: 'Mool delivery',
        payment: 'Pay on delivery',
        address: '',
      );
      session.advanceWorkspaceOrder();
      for (final line in session.workspacePackingLines) {
        session.setWorkspacePackingLine(line.id, true);
      }
      session.advanceWorkspaceOrder();
      session.advanceWorkspaceOrder();
      expect(session.workspaceOrderStage, 'Ready');
      expect(session.errorMessage, contains('delivery address'));

      session.workspaceOrderAddress = '21 Residency Road, Jodhpur';
      session.advanceWorkspaceOrder();
      expect(session.workspaceOrderStage, 'Delivery requested');
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(gateway.deliveryAssignmentCalls, 1);
      expect(session.workspaceDeliveryAssignment?.partnerName, isNotEmpty);

      expect(await session.verifyWorkspaceHandover('000000'), isFalse);
      expect(session.workspaceOrderStage, 'Delivery requested');
      expect(await session.verifyWorkspaceHandover('123456'), isTrue);
      expect(session.workspaceOrderStage, 'Completed');
      expect(session.workspaceCompletedSalesCount, 1);
      expect(gateway.handoverCalls, 2);
    },
  );

  test('settlement uses only the eligible completed-sale balance', () async {
    final gateway = ReviewWorkGateway();
    final session = liveSession(gateway)
      ..workspaceSettlementBalance = 1000
      ..workspacePlatformAdjustments = 100
      ..workspaceRefunds = 50
      ..workspaceTaxWithheld = 50;

    expect(session.workspaceSettlementEligible, 800);
    await session.requestWorkspaceSettlement();
    expect(gateway.settlementCalls, 1);
    expect(session.workspaceSettlementRequested, 800);
    expect(session.workspaceSettlementBalance, 200);
    expect(session.workspaceSettlementEligible, 0);
    expect(session.workspaceSettlementReference, startsWith('SET-'));
  });

  test('pickup never requests delivery and creates an invoice at handover', () {
    final session = liveSession();
    session.addOrUpdateWorkspaceProduct(_product(stock: 10));
    session.prepareWorkspaceOrder(source: 'App', fulfilment: 'Pickup');
    session.adjustWorkspaceOrderQuantity('atta-5kg', 1);
    session.saveWorkspaceOrderDraft(
      customer: '9829012321',
      source: 'App',
      fulfilment: 'Pickup',
      payment: 'Paid online',
      address: '',
    );

    expect(session.workspaceOrderNeedsDelivery, isFalse);
    session.advanceWorkspaceOrder();
    for (final line in session.workspacePackingLines) {
      session.setWorkspacePackingLine(line.id, true);
    }
    session.advanceWorkspaceOrder();
    expect(session.workspaceOrderStage, 'Ready for pickup');
    expect(session.workspaceDeliveryAssignment, isNull);
    session.advanceWorkspaceOrder();
    expect(session.workspaceOrderStage, 'Completed');
    expect(session.latestWorkspaceInvoice?.customer, '9829012321');
  });

  test('counter sale posts stock money and customer invoice together', () {
    final session = liveSession();
    session.addOrUpdateWorkspaceProduct(_product(stock: 10));
    session.prepareWorkspaceOrder(source: 'Counter', fulfilment: 'At the shop');
    session.adjustWorkspaceOrderQuantity('atta-5kg', 2);
    session.saveWorkspaceOrderDraft(
      customer: '9829012321',
      source: 'Counter',
      fulfilment: 'At the shop',
      payment: 'UPI',
      address: '',
    );

    final invoice = session.completeWorkspaceCounterSale();
    expect(invoice, isNotNull);
    expect(session.workspaceCatalogueItems.single.stock, 8);
    expect(session.workspaceSalesToday, 550);
    expect(session.workspaceSettlementBalance, 550);
    session.markWorkspaceInvoiceShared(invoice!.id, 'MoolSocial Chat');
    expect(session.latestWorkspaceInvoice?.needsCustomerHandoff, isFalse);
  });

  test('Store configuration persists delivery staff and counter controls', () {
    final gateway = ReviewWorkGateway();
    final session = liveSession(gateway);
    session.saveWorkspaceDeliverySettings(radiusKm: 8, fee: 25, freeAbove: 599);
    session.saveWorkspaceStaffSettings(
      staffAccessEnabled: true,
      counterCount: 3,
    );
    expect(session.workspaceDeliveryRadiusKm, 8);
    expect(session.workspaceDeliveryFee, 25);
    expect(session.workspaceFreeDeliveryAbove, 599);
    expect(session.workspaceStaffAccessEnabled, isTrue);
    expect(session.workspaceCounterCount, 3);
  });

  test(
    'funded Store requirement preserves candidate and payment facts',
    () async {
      final gateway = ReviewWorkGateway();
      final session = liveSession(gateway);
      expect(
        await session.createWorkspacePaidRequirement(
          position: 'Evening packing assistant',
          work: 'Pack confirmed customer orders from 5 PM to 9 PM.',
          candidateRequirement: 'Retail packing experience',
          location: 'Sardarpura, Jodhpur · 342003',
          peopleNeeded: 2,
          paymentAmount: 600,
          paymentFormat: 'Assignment',
          deadline: DateTime(2026, 9, 7),
        ),
        isTrue,
      );
      expect(gateway.paidRequirementCalls, 1);
      expect(
        gateway.lastPaidRequirementSubmission?.values,
        containsPair('paymentAmount', 600),
      );
      expect(
        session.workspacePaidRequirementReference,
        startsWith('WORK-REQ-'),
      );
    },
  );

  test(
    'Group Bulk Buying preserves every decision and payment field',
    () async {
      final gateway = ReviewWorkGateway();
      final session = liveSession(gateway);

      expect(
        await session.createWorkspaceGroupBuy(
          productName: 'Premium red onion',
          specification: 'Grade A · 45 mm+ · 25 kg mesh bags',
          targetQuantity: 1000,
          securedQuantity: 280,
          unitLabel: 'kg',
          regularUnitPrice: 18,
          groupUnitPrice: 14,
          facilitationFee: 200,
          deliveryFee: 0,
          confirmationAmount: 3920,
          closingLabel: '5 Sep · 8:00 PM',
          storeDeliveryLabel: '7 Sep · Door delivery',
        ),
        isTrue,
      );

      expect(gateway.groupBuyCalls, 1);
      expect(
        gateway.lastGroupBuySubmission?.values,
        containsPair('facilitationFee', 200),
      );
      expect(
        gateway.lastGroupBuySubmission?.values,
        containsPair('storeDeliveryLabel', '7 Sep · Door delivery'),
      );
      expect(session.activeGroupBuy?.productName, 'Premium red onion');
      expect(session.activeGroupBuy?.paymentConfirmed, isTrue);
      expect(session.activeGroupBuy?.leadRetailer, 'Mahadev Fresh Mart');
    },
  );

  test(
    'catalogue import updates by SKU and retirement removes public sale',
    () {
      final session = liveSession();
      session.addOrUpdateWorkspaceProduct(_product(stock: 10));
      session.importWorkspaceProducts([
        _product(stock: 24, sellingPrice: 299),
        _product(
          id: 'oil-1l',
          sku: 'OIL-1L',
          title: 'Fortune Sunlite Oil',
          stock: 18,
          sellingPrice: 155,
        ),
      ]);

      expect(session.workspaceCatalogueItems, hasLength(2));
      expect(
        session.workspaceCatalogueItems
            .singleWhere((item) => item.sku == 'ATTA-5KG')
            .sellingPrice,
        299,
      );
      session.retireWorkspaceProduct('oil-1l');
      final retired = session.workspaceCatalogueItems.singleWhere(
        (item) => item.id == 'oil-1l',
      );
      expect(retired.stock, 0);
      expect(retired.available, isFalse);
      expect(retired.publicListing, isFalse);
      expect(retired.published, isFalse);
    },
  );

  test('workspace switch keeps both verified businesses available', () {
    final session = liveSession()
      ..otherWorkspaces.add(
        const WorkWorkspace(
          id: 'workspace-store-2',
          name: 'Mahadev Speciality Store',
          profileLabel: 'Speciality Retail Shop',
          profileId: 'retailer-speciality',
          area: 'Paota, Jodhpur',
          verified: true,
        ),
      );

    final target = session.otherWorkspaces.single;
    session.activateWorkspace(target);
    expect(session.activeWorkspace?.id, 'workspace-store-2');
    expect(session.otherWorkspaces.map((item) => item.id), [
      'workspace-store-1',
    ]);
    expect(session.workspaceId, 'workspace-store-2');
  });
}

WorkspaceCatalogueItem _product({
  String id = 'atta-5kg',
  String sku = 'ATTA-5KG',
  String title = 'Aashirvaad Select Atta',
  int stock = 10,
  int sellingPrice = 275,
}) => WorkspaceCatalogueItem(
  id: id,
  canonicalId: 'canonical-$id',
  categoryId: 'grocery-staples',
  brand: id == 'oil-1l' ? 'Fortune' : 'Aashirvaad',
  title: title,
  variant: 'Standard',
  pack: id == 'oil-1l' ? '1 L' : '5 kg',
  sku: sku,
  barcode: id == 'oil-1l' ? '8906007280012' : '8901725112233',
  purchasePrice: sellingPrice - 25,
  sellingPrice: sellingPrice,
  unitPrice: id == 'oil-1l' ? '₹$sellingPrice/L' : '₹55/kg',
  stock: stock,
  deliveryPromise: 'Delivery today',
  origin: 'India',
  visualLabel: id == 'oil-1l' ? 'OIL' : 'ATTA',
  visualKind: 'pack',
  mrp: sellingPrice + 30,
  minimumOrder: 1,
  returnPolicy: 'Return accepted for a damaged sealed pack.',
  publicListing: true,
);
