import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/work/work_models.dart';
import 'package:moolsocial/features/work/work_services.dart';
import 'package:moolsocial/features/work/work_session.dart';

class _OrderTimeGateway extends ReviewWorkGateway
    implements WorkOrderTimeGateway {
  final requests = <WorkOrderTimeRequest>[];
  Future<WorkOrderTimeResult> Function(WorkOrderTimeRequest)? respond;
  WorkOrderTimeResult approval(WorkOrderTimeRequest r) => WorkOrderTimeResult(
    workspaceId: r.workspaceId,
    orderId: r.orderId,
    operationId: r.operationId,
    approved: true,
    acceptanceDeadline: r.expectedAcceptanceDeadline.add(
      Duration(minutes: r.additionalMinutes),
    ),
    fulfilmentDeadline: r.expectedAcceptanceDeadline.add(
      const Duration(minutes: 18),
    ),
  );
  @override
  Future<WorkOrderTimeResult> requestOrderTime(WorkOrderTimeRequest request) {
    requests.add(request);
    return respond?.call(request) ?? Future.value(approval(request));
  }
}

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

  WorkSession timingSession(ReviewWorkGateway gateway) {
    final session = liveSession(gateway);
    session.workspaceCatalogueItems.add(_product(stock: 10));
    session.workspaceOrders.add(
      WorkspaceOrderRecord(
        id: 'timing-order',
        customer: 'Asha',
        items: 'Atta',
        quantities: {'atta-5kg': 1},
        amount: 250,
        source: 'App',
        fulfilment: 'Mool delivery',
        payment: 'Paid online',
        address: 'Market road',
        stage: 'Confirmed',
        needsDelivery: true,
        createdAt: DateTime.now(),
        actionDeadline: DateTime.now().add(const Duration(seconds: 60)),
      ),
    );
    expect(session.selectWorkspaceOrder('timing-order'), isTrue);
    return session;
  }

  test(
    'Order time missing service cannot change or publish a deadline',
    () async {
      final session = timingSession(ReviewWorkGateway());
      final before = session.currentWorkspaceOrder;
      expect(
        await session.requestWorkspaceOrderTime('timing-order', 2),
        isFalse,
      );
      expect(session.currentWorkspaceOrder, same(before));
      expect(session.hasPendingOrderTime, isFalse);
      expect(session.errorMessage, contains('current time still applies'));
    },
  );

  test(
    'Order time waits for authority and blocks duplicate state actions',
    () async {
      final gateway = _OrderTimeGateway();
      final completer = Completer<WorkOrderTimeResult>();
      gateway.respond = (_) => completer.future;
      final session = timingSession(gateway);
      final original = session.currentWorkspaceOrder!.actionDeadline;
      final pending = session.requestWorkspaceOrderTime('timing-order', 2);
      expect(session.busy, isTrue);
      expect(session.currentWorkspaceOrder!.actionDeadline, original);
      expect(
        await session.requestWorkspaceOrderTime('timing-order', 5),
        isFalse,
      );
      session.advanceWorkspaceOrder();
      session.cancelWorkspaceOrder();
      expect(session.workspaceOrderStage, 'Confirmed');
      expect(session.workspaceCatalogueItems.single.stock, 10);
      expect(gateway.requests, hasLength(1));
      final result = gateway.approval(gateway.requests.single);
      completer.complete(result);
      expect(await pending, isTrue);
      expect(session.hasPendingOrderTime, isFalse);
      expect(
        session.currentWorkspaceOrder!.actionDeadline,
        result.acceptanceDeadline,
      );
      session.advanceWorkspaceOrder();
      expect(session.workspaceOrderStage, 'Preparing');
      expect(session.workspaceOrderActionDeadline, result.fulfilmentDeadline);
      expect(session.workspaceInvoices, isEmpty);
    },
  );

  test(
    'Order time rejection leaves the original time and no fake approval',
    () async {
      final gateway = _OrderTimeGateway();
      gateway.respond = (r) async => WorkOrderTimeResult(
        workspaceId: r.workspaceId,
        orderId: r.orderId,
        operationId: r.operationId,
        approved: false,
      );
      final session = timingSession(gateway);
      final before = session.currentWorkspaceOrder;
      expect(
        await session.requestWorkspaceOrderTime('timing-order', 2),
        isFalse,
      );
      expect(session.currentWorkspaceOrder, same(before));
      expect(session.hasPendingOrderTime, isFalse);
      expect(session.errorMessage, contains('not approved'));
    },
  );

  test(
    'Order time uncertain retry reuses the original operation and minutes',
    () async {
      final gateway = _OrderTimeGateway();
      gateway.respond = (_) async => throw StateError('lost connection');
      final session = timingSession(gateway);
      final before = session.currentWorkspaceOrder;
      expect(
        await session.requestWorkspaceOrderTime('timing-order', 2),
        isFalse,
      );
      expect(session.hasPendingOrderTime, isTrue);
      expect(session.currentWorkspaceOrder, same(before));
      final first = gateway.requests.single;
      gateway.respond = (r) async => gateway.approval(r);
      expect(
        await session.requestWorkspaceOrderTime('timing-order', 5),
        isTrue,
      );
      expect(gateway.requests.last, same(first));
      expect(gateway.requests.last.additionalMinutes, 2);
    },
  );

  for (final mismatch in [
    'order',
    'store',
    'operation',
    'expired',
    'tooLong',
    'fulfilment',
  ]) {
    test('Order time rejects mismatched or invalid $mismatch result', () async {
      final gateway = _OrderTimeGateway();
      gateway.respond = (r) async => WorkOrderTimeResult(
        workspaceId: mismatch == 'store' ? 'other-store' : r.workspaceId,
        orderId: mismatch == 'order' ? 'other-order' : r.orderId,
        operationId: mismatch == 'operation'
            ? 'other-operation'
            : r.operationId,
        approved: true,
        acceptanceDeadline: mismatch == 'expired'
            ? DateTime.now().subtract(const Duration(seconds: 1))
            : r.expectedAcceptanceDeadline.add(
                Duration(minutes: mismatch == 'tooLong' ? 20 : 2),
              ),
        fulfilmentDeadline: mismatch == 'fulfilment'
            ? r.expectedAcceptanceDeadline
            : r.expectedAcceptanceDeadline.add(const Duration(minutes: 25)),
      );
      final session = timingSession(gateway);
      final before = session.currentWorkspaceOrder;
      expect(
        await session.requestWorkspaceOrderTime('timing-order', 2),
        isFalse,
      );
      expect(session.currentWorkspaceOrder, same(before));
      expect(session.hasPendingOrderTime, isTrue);
      expect(session.workspaceInvoices, isEmpty);
    });
  }

  test('Order time late response cannot update a different store', () async {
    final gateway = _OrderTimeGateway();
    final completer = Completer<WorkOrderTimeResult>();
    gateway.respond = (_) => completer.future;
    final session = timingSession(gateway);
    final pending = session.requestWorkspaceOrderTime('timing-order', 2);
    final request = gateway.requests.single;
    session.activeWorkspace = const WorkWorkspace(
      id: 'other-store',
      name: 'Other',
      profileLabel: 'Retail',
      profileId: 'retailer-speciality',
      area: 'Market',
      verified: true,
    );
    completer.complete(gateway.approval(request));
    expect(await pending, isFalse);
    expect(session.workspaceOrders, isEmpty);
    expect(session.workspaceOrderActionDeadline, isNull);
    expect(session.hasPendingOrderTime, isFalse);
  });

  test('Order time old control cannot extend a deadline locally', () async {
    final session = timingSession(ReviewWorkGateway());
    final before = session.currentWorkspaceOrder;
    session.extendWorkspaceOrder(10);
    await Future<void>.delayed(Duration.zero);
    expect(session.currentWorkspaceOrder, same(before));
    expect(session.workspaceOrderExtraMinutes, 0);
  });

  test('Order time expired or wrong order cannot create a request', () async {
    final gateway = _OrderTimeGateway();
    final session = timingSession(gateway);
    expect(
      await session.requestWorkspaceOrderTime('another-order', 2),
      isFalse,
    );
    final expired = session.currentWorkspaceOrder!.copyWith(
      actionDeadline: DateTime.now().subtract(const Duration(seconds: 1)),
    );
    session.workspaceOrders[0] = expired;
    session.workspaceOrderActionDeadline = expired.actionDeadline;
    expect(await session.requestWorkspaceOrderTime('timing-order', 2), isFalse);
    expect(gateway.requests, isEmpty);
    expect(session.currentWorkspaceOrder, same(expired));
  });

  test(
    'Order time stale stage cannot be overwritten by a late reply',
    () async {
      final gateway = _OrderTimeGateway();
      final completer = Completer<WorkOrderTimeResult>();
      gateway.respond = (_) => completer.future;
      final session = timingSession(gateway);
      final pending = session.requestWorkspaceOrderTime('timing-order', 2);
      final changed = session.currentWorkspaceOrder!.copyWith(
        stage: 'Cancelled',
      );
      session.workspaceOrders[0] = changed;
      session.workspaceOrderStage = 'Cancelled';
      completer.complete(gateway.approval(gateway.requests.single));
      expect(await pending, isFalse);
      expect(session.currentWorkspaceOrder, same(changed));
      expect(session.workspaceOrderStage, 'Cancelled');
    },
  );

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

  test('large Store amounts retain the full eligible balance', () {
    final session = liveSession()
      ..workspacePlatformAdjustments = 100
      ..workspaceDeliveryAdjustments = 200
      ..workspaceRefunds = 300
      ..workspaceTaxWithheld = 400;
    for (final amount in [
      0,
      1,
      999,
      10000000,
      1000000000,
      2147483647,
      2147483648,
      2147483649,
      9990000000,
      10000000000,
      100000000000,
    ]) {
      session.workspaceSettlementBalance = amount + 1000;
      expect(session.workspaceSettlementEligible, amount, reason: '$amount');
      expect(session.workspaceSettlementBalance, amount + 1000);
    }
    session.workspaceSettlementBalance = 999;
    expect(session.workspaceSettlementEligible, 0);
  });

  test('large Store amounts preserve partial settlement remainder', () async {
    final gateway = ReviewWorkGateway();
    final session = liveSession(gateway)
      ..workspaceSettlementBalance = 10000000000;
    await session.requestWorkspaceSettlement(amount: 10000000);
    expect(gateway.settlementCalls, 1);
    expect(session.workspaceSettlementRequested, 10000000);
    expect(session.workspaceSettlementBalance, 9990000000);
    expect(session.workspaceSettlementEligible, 9990000000);
  });

  test('large Store amounts preserve group purchase savings and balance', () {
    const group = WorkspaceGroupBuy(
      id: 'range-test',
      productName: 'Commodity',
      specification: 'Per kg',
      leadRetailer: 'Test store',
      confirmedRetailers: ['Test store'],
      targetQuantity: 1000000,
      securedQuantity: 1000000,
      unitLabel: 'kg',
      regularUnitPrice: 200000,
      groupUnitPrice: 100000,
      facilitationFee: 123,
      deliveryFee: 456,
      confirmationAmount: 10000000,
      closingLabel: 'Tomorrow',
      storeDeliveryLabel: 'After confirmation',
      paymentConfirmed: false,
    );
    expect(group.goodsValue, 100000000000);
    expect(group.deliveredTotal, 100000000579);
    expect(group.netSaving, 99999999421);
    expect(group.balanceDue, 99990000579);
    expect(group.paymentConfirmed, isFalse);
  });

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
    expect(session.workspaceSettlementBalance, 0);
    session.markWorkspaceInvoiceShared(invoice!.id, 'MoolSocial Chat');
    expect(session.latestWorkspaceInvoice?.needsCustomerHandoff, isFalse);
  });

  test('completed counter sale cannot reopen or post its totals twice', () {
    final session = liveSession();
    session.addOrUpdateWorkspaceProduct(_product(stock: 10));
    session.prepareWorkspaceOrder(source: 'Counter', fulfilment: 'At the shop');
    session.adjustWorkspaceOrderQuantity('atta-5kg', 2);
    void save() => session.saveWorkspaceOrderDraft(
      customer: '9829012321',
      source: 'Counter',
      fulfilment: 'At the shop',
      payment: 'UPI',
      address: '',
    );
    save();
    final first = session.completeWorkspaceCounterSale()!;
    final movementCount = session.workspaceStockMovements.length;
    save();
    expect(session.completeWorkspaceCounterSale(), same(first));
    expect(session.currentWorkspaceOrder!.stage, 'Completed');
    expect(session.workspaceInvoices, hasLength(1));
    expect(session.workspaceCompletedSalesCount, 1);
    expect(session.workspaceSalesToday, 550);
    expect(session.workspaceSettlementBalance, 0);
    expect(session.workspaceCatalogueItems.single.stock, 8);
    expect(session.workspaceStockMovements, hasLength(movementCount));

    session.startNewWorkspaceOrder();
    expect(session.completeWorkspaceCounterSale(), isNull);
    expect(session.workspaceOrders, hasLength(1));
    expect(session.workspaceInvoices.single, same(first));
    expect(session.workspaceSalesToday, 550);
  });

  for (final payment in [
    'Cash',
    'UPI',
    'Pay request',
    'On delivery',
    'Customer due',
  ]) {
    test(
      'recording a $payment counter invoice does not create settlement funds',
      () {
        final session = liveSession()..workspaceSettlementBalance = 700;
        session.addOrUpdateWorkspaceProduct(_product(stock: 10));
        session.prepareWorkspaceOrder(
          source: 'Counter',
          fulfilment: 'At the shop',
        );
        session.adjustWorkspaceOrderQuantity('atta-5kg', 1);
        session.saveWorkspaceOrderDraft(
          customer: '9829012321',
          source: 'Counter',
          fulfilment: 'At the shop',
          payment: payment,
          address: '',
        );
        final invoice = session.completeWorkspaceCounterSale()!;
        expect(invoice.payment, payment);
        expect(session.workspaceSalesToday, 275);
        expect(session.workspaceSettlementBalance, 700);
        expect(session.workspaceSettlementEligible, 700);
        expect(session.workspaceCatalogueItems.single.stock, 9);
      },
    );
  }

  test('failed counter completion retains its draft without an invoice', () {
    final session = liveSession();
    session.addOrUpdateWorkspaceProduct(_product(stock: 1));
    session.prepareWorkspaceOrder(source: 'Counter', fulfilment: 'At the shop');
    session.workspaceOrderQuantities['atta-5kg'] = 2;
    session.saveWorkspaceOrderDraft(
      customer: '9829012321',
      source: 'Counter',
      fulfilment: 'At the shop',
      payment: 'Cash',
      address: '',
    );
    expect(session.completeWorkspaceCounterSale(), isNull);
    expect(session.workspaceOrderCustomer, '9829012321');
    expect(session.workspaceOrderQuantities['atta-5kg'], 2);
    expect(session.workspaceInvoices, isEmpty);
    expect(session.workspaceCompletedSalesCount, 0);
    expect(session.workspaceSalesToday, 0);
    expect(session.workspaceCatalogueItems.single.stock, 1);
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

  test('Store scope restores only the selected store operational state', () {
    final session = liveSession();
    final first = session.activeWorkspace!;
    const second = WorkWorkspace(
      id: 'workspace-store-2',
      name: 'Second store',
      profileLabel: 'Speciality Retail Shop',
      profileId: 'retailer-speciality',
      area: 'Paota',
      verified: true,
    );
    session.otherWorkspaces.add(second);
    session.workspaceCatalogueItems.add(_product());
    final firstCatalogue = session.workspaceCatalogueItems;
    session.workspaceOrderQuantities['atta-5kg'] = 2;
    session.workspaceOrderCustomer = 'First customer';
    session.workspaceOrderStage = 'Preparing';
    session.workspacePackedProductIds.add('atta-5kg');
    session.currentWorkspaceOrderId = 'shared-id';
    session.workspaceSalesToday = 900;
    session.workspaceSettlementBalance = 700;
    session.workspacePayoutAccountEnding = '1234';
    session.workspaceCustomersFollowingStore.add('first-customer');
    session.workspaceCustomerLastContactAt['first-customer'] = DateTime(
      2026,
      9,
      7,
    );
    session.workspaceAcceptingOrders = true;
    session.workspaceVisibleToCustomers = true;
    session.workspaceSearchQuery = 'First draft';
    session.activateWorkspace(second);
    expect(session.workspaceCatalogueItems, isEmpty);
    expect(identical(session.workspaceCatalogueItems, firstCatalogue), isFalse);
    expect(session.workspaceOrderQuantities, isEmpty);
    expect(session.workspacePackedProductIds, isEmpty);
    expect(session.currentWorkspaceOrderId, isNull);
    expect(session.visibleWorkspaceOrders, isEmpty);
    expect(session.workspaceSalesToday, 0);
    expect(session.workspaceSettlementBalance, 0);
    expect(session.workspacePayoutAccountEnding, isEmpty);
    expect(session.workspaceCustomersFollowingStore, isEmpty);
    expect(session.workspaceCustomerLastContactAt, isEmpty);
    expect(session.workspaceAcceptingOrders, isFalse);
    expect(session.workspaceVisibleToCustomers, isFalse);
    session.workspaceCatalogueItems.add(_product(id: 'second-sku'));
    session.workspaceSalesToday = 75;
    session.workspaceOrderCustomer = 'Second customer';
    session.activateWorkspace(first);
    expect(identical(session.workspaceCatalogueItems, firstCatalogue), isTrue);
    expect(session.workspaceCatalogueItems.single.id, 'atta-5kg');
    expect(session.workspaceOrderQuantities, {'atta-5kg': 2});
    expect(session.workspacePackedProductIds, {'atta-5kg'});
    expect(session.currentWorkspaceOrderId, 'shared-id');
    expect(session.workspaceOrderCustomer, 'First customer');
    expect(session.workspaceSalesToday, 900);
    expect(session.workspaceSettlementBalance, 700);
    expect(session.workspacePayoutAccountEnding, '1234');
    expect(session.workspaceCustomerLastContactAt, contains('first-customer'));
    session.activateWorkspace(second);
    expect(session.workspaceCatalogueItems.single.id, 'second-sku');
    expect(session.workspaceSalesToday, 75);
    expect(session.workspaceOrderCustomer, 'Second customer');
  });

  test('Store scope partitions all public operational fields and defaults', () {
    final session = liveSession();
    final first = session.activeWorkspace!;
    const second = WorkWorkspace(
      id: 'store-b',
      name: 'Second store',
      profileLabel: 'Speciality Retail Shop',
      profileId: 'retailer-speciality',
      area: 'Paota',
      verified: true,
    );
    session.otherWorkspaces.add(second);
    session.retailerProductAdded = !session.retailerProductAdded;
    session.retailerQuantity = session.retailerQuantity + 7;
    session.retailerBuyPrice = session.retailerBuyPrice + 7;
    session.retailerSellPrice = session.retailerSellPrice + 7;
    session.retailerHomeDelivery = !session.retailerHomeDelivery;
    session.retailerStoreCollection = !session.retailerStoreCollection;
    session.retailerPublishAfterSetup = !session.retailerPublishAfterSetup;
    session.retailerSetupSaved = !session.retailerSetupSaved;
    session.workspaceSearchQuery = 'first-workspaceSearchQuery';
    session.workspaceStoreState = WorkspaceStoreState.values.firstWhere(
      (value) => value != session.workspaceStoreState,
    );
    session.workspaceDashboardState = WorkspaceDashboardState.values.firstWhere(
      (value) => value != session.workspaceDashboardState,
    );
    session.workspaceLastUpdatedAt = DateTime(2026, 9, 7, 12);
    session.workspaceDashboardError = 'first-workspaceDashboardError';
    session.workspaceAcceptingOrders = !session.workspaceAcceptingOrders;
    session.workspaceFulfilmentMode = 'first-workspaceFulfilmentMode';
    session.workspaceBusyMinutes = session.workspaceBusyMinutes + 7;
    session.workspaceReopensAt = 'first-workspaceReopensAt';
    session.workspaceOpeningTime = 'first-workspaceOpeningTime';
    session.workspaceClosingTime = 'first-workspaceClosingTime';
    session.workspaceMaximumActiveOrders =
        session.workspaceMaximumActiveOrders + 7;
    session.workspaceOrderAlertSound = !session.workspaceOrderAlertSound;
    session.workspaceOrderAlertVibration =
        !session.workspaceOrderAlertVibration;
    session.workspaceVisibleToCustomers = !session.workspaceVisibleToCustomers;
    session.workspaceOrderCustomer = 'first-workspaceOrderCustomer';
    session.workspaceOrderItems = 'first-workspaceOrderItems';
    session.workspaceOrderAmount = 'first-workspaceOrderAmount';
    session.workspaceOrderNeedsDelivery = !session.workspaceOrderNeedsDelivery;
    session.workspaceOrderSource = 'first-workspaceOrderSource';
    session.workspaceOrderFulfilment = 'first-workspaceOrderFulfilment';
    session.workspaceOrderPayment = 'first-workspaceOrderPayment';
    session.workspaceOrderAddress = 'first-workspaceOrderAddress';
    session.workspaceOrderStage = 'first-workspaceOrderStage';
    session.workspaceOrderExtraMinutes = session.workspaceOrderExtraMinutes + 7;
    session.workspaceOrderActionDeadline = DateTime(2026, 9, 7, 12);
    session.workspaceOrderFilter = 'first-workspaceOrderFilter';
    session.workspaceCustomerPeriod = 'first-workspaceCustomerPeriod';
    session.workspaceCustomerSearch = 'first-workspaceCustomerSearch';
    session.workspaceCustomerFilter = 'first-workspaceCustomerFilter';
    session.workspaceMoneyPeriod = 'first-workspaceMoneyPeriod';
    session.workspaceCustomerCustomStart = DateTime(2026, 9, 7, 12);
    session.workspaceCustomerCustomEnd = DateTime(2026, 9, 7, 12);
    session.workspaceSalesToday = session.workspaceSalesToday + 7;
    session.workspaceCompletedSalesCount =
        session.workspaceCompletedSalesCount + 7;
    session.workspacePlatformAdjustments =
        session.workspacePlatformAdjustments + 7;
    session.workspaceDeliveryAdjustments =
        session.workspaceDeliveryAdjustments + 7;
    session.workspaceRefunds = session.workspaceRefunds + 7;
    session.workspaceTaxWithheld = session.workspaceTaxWithheld + 7;
    session.workspaceSettlementBalance = session.workspaceSettlementBalance + 7;
    session.workspaceSettlementRequested =
        session.workspaceSettlementRequested + 7;
    session.workspaceSettlementReference = 'first-workspaceSettlementReference';
    session.workspacePayoutBankName = 'first-workspacePayoutBankName';
    session.workspacePayoutAccountEnding = 'first-workspacePayoutAccountEnding';
    session.currentWorkspaceOrderId = 'first-currentWorkspaceOrderId';
    session.workspaceOperationsSyncing = false;
    session.workspaceOperationsSyncError = 'first-workspaceOperationsSyncError';
    session.workspaceHandoverBusy = false;
    session.workspaceDeliveryRadiusKm = session.workspaceDeliveryRadiusKm + 7;
    session.workspaceDeliveryFee = session.workspaceDeliveryFee + 7;
    session.workspaceFreeDeliveryAbove = session.workspaceFreeDeliveryAbove + 7;
    session.workspaceDeliveryCity = 'first-workspaceDeliveryCity';
    session.workspaceDeliveryArea = 'first-workspaceDeliveryArea';
    session.workspaceDeliveryPincode = 'first-workspaceDeliveryPincode';
    session.workspacePickupEnabled = !session.workspacePickupEnabled;
    session.workspaceStaffAccessEnabled = !session.workspaceStaffAccessEnabled;
    session.workspaceCounterCount = session.workspaceCounterCount + 7;
    session.workspacePaidRequirementReference =
        'first-workspacePaidRequirementReference';
    session.workspacePaidRequirementState = WorkspacePaidRequirementState.values
        .firstWhere((value) => value != session.workspacePaidRequirementState);
    session.workspaceCatalogueItems.add(_product());
    session.workspaceOrders.add(_scopeOrder('same-order'));
    session.workspaceInvoices.add(
      WorkspaceCustomerInvoice(
        id: 'invoice-a',
        orderId: 'same-order',
        customer: 'First customer',
        items: 'Atta',
        amount: 100,
        payment: 'Paid online',
        issuedAt: DateTime(2026, 9, 7),
      ),
    );
    session.workspaceStockMovements.add(
      WorkspaceStockMovement(
        id: 'move-a',
        productId: 'atta-5kg',
        productLabel: 'Atta',
        kind: WorkspaceStockMovementKind.adjustment,
        quantityDelta: 1,
        reason: 'Counted',
        occurredAt: DateTime(2026, 9, 7),
      ),
    );
    session.workspaceOffers.add(
      WorkspaceStoreOffer(
        id: 'offer-a',
        title: 'Store offer',
        detail: 'Atta',
        validUntil: DateTime(2026, 9, 8),
        active: true,
      ),
    );
    session.workspaceActivity.add(
      WorkspaceActivityEntry(
        message: 'First activity',
        time: DateTime(2026, 9, 7),
      ),
    );
    session.workspaceOrderQuantities['atta-5kg'] = 3;
    session.workspacePackedProductIds.add('atta-5kg');
    session.dismissedWorkspaceAlerts.add('first-alert');
    session.workspaceCustomersFollowingStore.add('first-customer');
    session.workspaceCustomersAllowingMessages.add('first-customer');
    session.workspaceCustomerLastContactAt['first-customer'] = DateTime(
      2026,
      9,
      7,
    );
    session.workspaceDeliveryAssignment = WorkspaceDeliveryAssignment(
      orderId: 'same-order',
      partnerName: 'First rider',
      vehicleLabel: 'Bike',
      eta: DateTime(2026, 9, 7),
      stage: 'Arriving',
    );
    final expectedFirst = _storeValues(session);
    final fresh = WorkSession();
    addTearDown(fresh.dispose);
    session.activateWorkspace(second);
    final actualSecond = _storeValues(session);
    expect(actualSecond, _storeValues(fresh));
    for (final entry in expectedFirst.entries) {
      if (entry.value is Iterable || entry.value is Map) {
        expect(
          identical(actualSecond[entry.key], entry.value),
          isFalse,
          reason: entry.key,
        );
      }
    }
    session.workspaceOrderCustomer = 'Second customer';
    session.workspaceOrderQuantities['second-sku'] = 1;
    session.workspaceSettlementBalance = 10000000000;
    final expectedSecond = _storeValues(session);
    session.activateWorkspace(first);
    expect(_storeValues(session), expectedFirst);
    session.activateWorkspace(second);
    expect(_storeValues(session), expectedSecond);
  });

  for (final pending in ['operation', 'save', 'handover']) {
    test('Store scope blocks switching during $pending', () {
      final session = liveSession()..otherWorkspaces.add(_scopeSecondStore);
      if (pending == 'operation') session.busy = true;
      if (pending == 'save') session.workspaceOperationsSyncing = true;
      if (pending == 'handover') session.workspaceHandoverBusy = true;
      session.activateWorkspace(_scopeSecondStore);
      expect(session.activeWorkspace?.id, 'workspace-store-1');
      expect(session.noticeMessage, contains('Please wait'));
    });
  }

  test(
    'Store scope waits for every concurrent save before switching',
    () async {
      final gateway = _ScopeGateway();
      final session = liveSession(gateway)
        ..otherWorkspaces.add(_scopeSecondStore);
      session.saveWorkspaceAvailability(
        acceptingOrders: true,
        fulfilmentMode: 'Pickup',
        busyMinutes: 0,
        reopensAt: '',
      );
      session.saveWorkspaceTradingControls(
        openingTime: '9 AM',
        closingTime: '8 PM',
        maximumActiveOrders: 8,
        alertSound: true,
        alertVibration: true,
      );
      expect(gateway.saves, hasLength(2));
      expect(
        gateway.snapshots.map((s) => s.workspaceId),
        everyElement('workspace-store-1'),
      );
      gateway.saves.first.complete();
      await Future<void>.delayed(Duration.zero);
      expect(session.workspaceOperationsSyncing, isTrue);
      session.activateWorkspace(_scopeSecondStore);
      expect(session.activeWorkspace?.id, 'workspace-store-1');
      gateway.saves.last.complete();
      await Future<void>.delayed(Duration.zero);
      expect(session.workspaceOperationsSyncing, isFalse);
      session.activateWorkspace(_scopeSecondStore);
      expect(session.activeWorkspace?.id, _scopeSecondStore.id);
    },
  );

  for (final fails in [false, true]) {
    test(
      'Store scope late save cannot finish another store save $fails',
      () async {
        final gateway = _ScopeGateway();
        final session = liveSession(gateway);
        session.saveWorkspaceAvailability(
          acceptingOrders: true,
          fulfilmentMode: 'Pickup',
          busyMinutes: 0,
          reopensAt: '',
        );
        session.activeWorkspace = _scopeSecondStore;
        session.workspaceId = _scopeSecondStore.id;
        session.saveWorkspaceAvailability(
          acceptingOrders: false,
          fulfilmentMode: 'Pickup',
          busyMinutes: 0,
          reopensAt: '',
        );
        if (fails) {
          gateway.saves.first.completeError(
            const WorkGatewayException('First store failure'),
          );
        } else {
          gateway.saves.first.complete();
        }
        await Future<void>.delayed(Duration.zero);
        expect(session.workspaceOperationsSyncing, isTrue);
        expect(session.workspaceOperationsSyncError, isNull);
        expect(session.workspaceAcceptingOrders, isFalse);
        gateway.saves.last.complete();
        await Future<void>.delayed(Duration.zero);
        expect(session.workspaceOperationsSyncing, isFalse);
      },
    );

    test(
      'Store scope late settlement cannot change another store $fails',
      () async {
        final gateway = _ScopeGateway();
        final session = liveSession(gateway)..workspaceSettlementBalance = 500;
        final pending = session.requestWorkspaceSettlement(amount: 100);
        session.activeWorkspace = _scopeSecondStore;
        session.workspaceId = _scopeSecondStore.id;
        session.workspaceSettlementBalance = 12000;
        if (fails) {
          gateway.settlement.completeError(
            const WorkGatewayException('Old settlement failure'),
          );
        } else {
          gateway.settlement.complete(
            const WorkSettlementResult(
              reference: 'old-settlement',
              acceptedAmount: 100,
            ),
          );
        }
        await pending;
        expect(session.workspaceSettlementBalance, 12000);
        expect(session.workspaceSettlementRequested, 0);
        expect(session.workspaceSettlementReference, isNull);
        expect(session.workspaceActivity, isEmpty);
        expect(session.errorMessage, isNull);
        expect(gateway.saves, isEmpty);
        expect(session.busy, isFalse);
      },
    );
  }

  for (final pickup in [false, true]) {
    test(
      'Store scope late handover cannot complete a same-id order $pickup',
      () async {
        final gateway = _ScopeGateway();
        final session = liveSession(gateway);
        session.workspaceOrders.add(_scopeOrder('same-order'));
        expect(session.selectWorkspaceOrder('same-order'), isTrue);
        final pending = pickup
            ? session.verifyWorkspacePickup('123456')
            : session.verifyWorkspaceHandover('123456');
        session.activeWorkspace = _scopeSecondStore;
        session.workspaceId = _scopeSecondStore.id;
        session.workspaceOrders.add(_scopeOrder('same-order'));
        expect(session.selectWorkspaceOrder('same-order'), isTrue);
        gateway.handover.complete();
        expect(await pending, isFalse);
        expect(session.workspaceOrderStage, 'Ready for pickup');
        expect(session.workspaceInvoices, isEmpty);
        expect(session.workspaceCompletedSalesCount, 0);
        expect(session.workspaceSettlementBalance, 0);
        expect(session.workspaceHandoverBusy, isFalse);
      },
    );
  }

  test(
    'Store scope late rider assignment cannot replace another store rider',
    () async {
      final gateway = _ScopeGateway();
      final session = liveSession(gateway);
      session.workspaceOrders.add(
        _scopeOrder('same-order', stage: 'Delivery requested'),
      );
      expect(session.selectWorkspaceOrder('same-order'), isTrue);
      final pending = session.retryWorkspaceDeliveryAssignment();
      session.activeWorkspace = _scopeSecondStore;
      session.workspaceId = _scopeSecondStore.id;
      session.workspaceOrders.add(
        _scopeOrder('same-order', stage: 'Delivery requested'),
      );
      expect(session.selectWorkspaceOrder('same-order'), isTrue);
      gateway.delivery.complete(
        WorkDeliveryAssignmentResult(
          partnerName: 'Old rider',
          vehicleLabel: 'Bike',
          eta: DateTime(2026, 9, 7),
          stage: 'Arriving',
        ),
      );
      await pending;
      expect(session.workspaceDeliveryAssignment, isNull);
      expect(session.workspaceOrderActionDeadline, isNull);
      expect(session.workspaceOperationsSyncing, isFalse);
    },
  );

  for (final group in [false, true]) {
    test(
      'Store scope late publication cannot populate another store $group',
      () async {
        final gateway = _ScopeGateway();
        final session = liveSession(gateway);
        final pending = group
            ? session.createWorkspaceGroupBuy(
                productName: 'Onion',
                specification: 'Grade A',
                targetQuantity: 100,
                securedQuantity: 10,
                unitLabel: 'kg',
                regularUnitPrice: 20,
                groupUnitPrice: 14,
                facilitationFee: 5,
                deliveryFee: 0,
                confirmationAmount: 140,
                closingLabel: '10 September',
                storeDeliveryLabel: '12 September',
              )
            : session.createWorkspacePaidRequirement(
                position: 'Product sourcing',
                work: 'Source stock',
                candidateRequirement: 'Wholesale experience',
                location: 'Jodhpur',
                peopleNeeded: 1,
                paymentAmount: 100,
                paymentFormat: 'Assignment',
                deadline: DateTime(2026, 9, 10),
              );
        session.activeWorkspace = _scopeSecondStore;
        session.workspaceId = _scopeSecondStore.id;
        gateway.publication.complete('first-store-reference');
        expect(await pending, isFalse);
        expect(session.activeGroupBuy, isNull);
        expect(session.workspacePaidRequirementReference, isNull);
        expect(
          session.workspacePaidRequirementState,
          WorkspacePaidRequirementState.draft,
        );
        expect(session.workspaceActivity, isEmpty);
        expect(gateway.saves, isEmpty);
      },
    );
  }

  test('repeat basket reconstructs an available legacy purchase summary', () {
    final session = liveSession();
    session.addOrUpdateWorkspaceProduct(
      _product(
        id: 'oil-1l',
        sku: 'OIL-1L',
        title: 'Fortune Sunlite Oil',
        stock: 8,
        sellingPrice: 155,
      ),
    );
    session
      ..workspaceOrderCustomer = 'Rakesh · 98290 12345'
      ..workspaceOrderItems = 'Fortune Oil × 2 · Aashirvaad Atta × 1'
      ..workspaceOrderAmount = '1468'
      ..workspaceOrderStage = 'Completed'
      ..workspaceOrderPayment = 'Paid online'
      ..workspaceOrderFulfilment = 'Pickup';

    expect(session.prepareRepeatWorkspaceOrder(), isTrue);
    expect(session.workspaceOrderSource, 'Repeat order');
    expect(session.workspaceOrderCustomer, 'Rakesh · 98290 12345');
    expect(session.workspaceOrderQuantities['oil-1l'], 2);
    expect(session.noticeMessage, contains('Available products'));
  });
}

const _scopeSecondStore = WorkWorkspace(
  id: 'workspace-store-2',
  name: 'Second store',
  profileLabel: 'Speciality Retail Shop',
  profileId: 'retailer-speciality',
  area: 'Paota',
  verified: true,
);

class _ScopeGateway extends ReviewWorkGateway {
  final saves = <Completer<void>>[];
  final snapshots = <WorkOperationalSnapshot>[];
  final settlement = Completer<WorkSettlementResult>();
  final handover = Completer<void>();
  final delivery = Completer<WorkDeliveryAssignmentResult>();
  final publication = Completer<String>();
  @override
  Future<void> saveOperationalState(WorkOperationalSnapshot snapshot) {
    snapshots.add(snapshot);
    final result = Completer<void>();
    saves.add(result);
    return result.future;
  }

  @override
  Future<WorkSettlementResult> requestSettlement({
    required String workspaceId,
    required int amount,
    required String idempotencyKey,
  }) => settlement.future;
  @override
  Future<void> verifyOrderHandover({
    required String workspaceId,
    required String orderId,
    required String otp,
    required String idempotencyKey,
  }) => handover.future;
  @override
  Future<WorkDeliveryAssignmentResult> requestDeliveryAssignment({
    required String workspaceId,
    required String orderId,
    required String address,
    required String idempotencyKey,
  }) => delivery.future;
  @override
  Future<String> createGroupBuy(WorkGroupBuySubmission submission) =>
      publication.future;
  @override
  Future<String> createPaidRequirement(
    WorkPaidRequirementSubmission submission,
  ) => publication.future;
}

Map<String, Object?> _storeValues(WorkSession session) => {
  'retailerProductAdded': session.retailerProductAdded,
  'retailerQuantity': session.retailerQuantity,
  'retailerBuyPrice': session.retailerBuyPrice,
  'retailerSellPrice': session.retailerSellPrice,
  'retailerHomeDelivery': session.retailerHomeDelivery,
  'retailerStoreCollection': session.retailerStoreCollection,
  'retailerPublishAfterSetup': session.retailerPublishAfterSetup,
  'retailerSetupSaved': session.retailerSetupSaved,
  'workspaceSearchQuery': session.workspaceSearchQuery,
  'workspaceStoreState': session.workspaceStoreState,
  'workspaceDashboardState': session.workspaceDashboardState,
  'workspaceLastUpdatedAt': session.workspaceLastUpdatedAt,
  'workspaceDashboardError': session.workspaceDashboardError,
  'workspaceAcceptingOrders': session.workspaceAcceptingOrders,
  'workspaceFulfilmentMode': session.workspaceFulfilmentMode,
  'workspaceBusyMinutes': session.workspaceBusyMinutes,
  'workspaceReopensAt': session.workspaceReopensAt,
  'workspaceOpeningTime': session.workspaceOpeningTime,
  'workspaceClosingTime': session.workspaceClosingTime,
  'workspaceMaximumActiveOrders': session.workspaceMaximumActiveOrders,
  'workspaceOrderAlertSound': session.workspaceOrderAlertSound,
  'workspaceOrderAlertVibration': session.workspaceOrderAlertVibration,
  'workspaceVisibleToCustomers': session.workspaceVisibleToCustomers,
  'workspaceOrderCustomer': session.workspaceOrderCustomer,
  'workspaceOrderItems': session.workspaceOrderItems,
  'workspaceOrderAmount': session.workspaceOrderAmount,
  'workspaceOrderNeedsDelivery': session.workspaceOrderNeedsDelivery,
  'workspaceOrderSource': session.workspaceOrderSource,
  'workspaceOrderFulfilment': session.workspaceOrderFulfilment,
  'workspaceOrderPayment': session.workspaceOrderPayment,
  'workspaceOrderAddress': session.workspaceOrderAddress,
  'workspaceOrderStage': session.workspaceOrderStage,
  'workspaceOrderExtraMinutes': session.workspaceOrderExtraMinutes,
  'workspaceOrderActionDeadline': session.workspaceOrderActionDeadline,
  'workspaceOrderFilter': session.workspaceOrderFilter,
  'workspaceCustomerPeriod': session.workspaceCustomerPeriod,
  'workspaceCustomerSearch': session.workspaceCustomerSearch,
  'workspaceCustomerFilter': session.workspaceCustomerFilter,
  'workspaceMoneyPeriod': session.workspaceMoneyPeriod,
  'workspaceCustomerCustomStart': session.workspaceCustomerCustomStart,
  'workspaceCustomerCustomEnd': session.workspaceCustomerCustomEnd,
  'workspaceSalesToday': session.workspaceSalesToday,
  'workspaceCompletedSalesCount': session.workspaceCompletedSalesCount,
  'workspacePlatformAdjustments': session.workspacePlatformAdjustments,
  'workspaceDeliveryAdjustments': session.workspaceDeliveryAdjustments,
  'workspaceRefunds': session.workspaceRefunds,
  'workspaceTaxWithheld': session.workspaceTaxWithheld,
  'workspaceSettlementBalance': session.workspaceSettlementBalance,
  'workspaceSettlementRequested': session.workspaceSettlementRequested,
  'workspaceSettlementReference': session.workspaceSettlementReference,
  'workspacePayoutBankName': session.workspacePayoutBankName,
  'workspacePayoutAccountEnding': session.workspacePayoutAccountEnding,
  'workspaceCatalogueItems': session.workspaceCatalogueItems,
  'workspaceStockMovements': session.workspaceStockMovements,
  'workspaceOrderQuantities': session.workspaceOrderQuantities,
  'workspaceOrders': session.workspaceOrders,
  'workspacePackedProductIds': session.workspacePackedProductIds,
  'workspaceInvoices': session.workspaceInvoices,
  'workspaceOffers': session.workspaceOffers,
  'currentWorkspaceOrderId': session.currentWorkspaceOrderId,
  'workspaceDeliveryAssignment': session.workspaceDeliveryAssignment,
  'workspaceOperationsSyncing': session.workspaceOperationsSyncing,
  'workspaceOperationsSyncError': session.workspaceOperationsSyncError,
  'workspaceHandoverBusy': session.workspaceHandoverBusy,
  'workspaceActivity': session.workspaceActivity,
  'activeGroupBuy': session.activeGroupBuy,
  'workspaceDeliveryRadiusKm': session.workspaceDeliveryRadiusKm,
  'workspaceDeliveryFee': session.workspaceDeliveryFee,
  'workspaceFreeDeliveryAbove': session.workspaceFreeDeliveryAbove,
  'workspaceDeliveryCity': session.workspaceDeliveryCity,
  'workspaceDeliveryArea': session.workspaceDeliveryArea,
  'workspaceDeliveryPincode': session.workspaceDeliveryPincode,
  'workspacePickupEnabled': session.workspacePickupEnabled,
  'workspaceStaffAccessEnabled': session.workspaceStaffAccessEnabled,
  'workspaceCounterCount': session.workspaceCounterCount,
  'workspacePaidRequirementReference':
      session.workspacePaidRequirementReference,
  'workspacePaidRequirementState': session.workspacePaidRequirementState,
  'dismissedWorkspaceAlerts': session.dismissedWorkspaceAlerts,
  'workspaceCustomersFollowingStore': session.workspaceCustomersFollowingStore,
  'workspaceCustomersAllowingMessages':
      session.workspaceCustomersAllowingMessages,
  'workspaceCustomerLastContactAt': session.workspaceCustomerLastContactAt,
};

WorkspaceOrderRecord _scopeOrder(
  String id, {
  String stage = 'Ready for pickup',
}) => WorkspaceOrderRecord(
  id: id,
  customer: 'Customer',
  items: 'Atta',
  quantities: const {'atta-5kg': 1},
  amount: 275,
  source: 'App',
  fulfilment: 'Pickup',
  payment: 'Paid online',
  address: 'Customer address',
  stage: stage,
  needsDelivery: false,
  createdAt: DateTime(2026, 9, 7),
);

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
