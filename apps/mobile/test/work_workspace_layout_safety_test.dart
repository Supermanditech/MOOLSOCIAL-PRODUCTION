import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moolsocial/features/chat/chat_session.dart';
import 'package:moolsocial/features/chat/chat_services.dart';
import 'package:go_router/go_router.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/core/design/mool_design_system.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/work/work_models.dart';
import 'package:moolsocial/features/work/work_services.dart';
import 'package:moolsocial/features/work/work_session.dart';
import 'package:moolsocial/features/work/work_workspace_benefits.dart';
import 'package:moolsocial/features/work/scan_and_pick_contract.dart';
import 'package:moolsocial/features/work/widgets/work_widgets.dart';
import 'package:moolsocial/features/work/screens/work_workspace_dashboard_screen.dart';

class _TrackingOrdersFixture extends BuyV2Session {
  _TrackingOrdersFixture({required super.core});
  List<BuyV2Order>? projectedOrders;

  @override
  List<BuyV2Order> get orders => projectedOrders ?? super.orders;

  void updateProjection(List<BuyV2Order> records) {
    projectedOrders = List.unmodifiable(records);
    notifyListeners();
  }
}

class _OrderJournalFixture implements WorkOrderPendingStore {
  _OrderJournalFixture(this.command);
  WorkOrderCommand? command;
  @override
  Future<List<WorkOrderCommand>> readPending(
    String accountScope,
    String workspaceId,
  ) async => command == null ? [] : [command!];
  @override
  Future<void> savePending(WorkOrderCommand value) async => command = value;
  @override
  Future<void> removePending(WorkOrderCommand value) async {
    if (command?.operationId == value.operationId) command = null;
  }
}

class _OrderCommandFixtureGateway implements WorkOrderCommandGateway {
  final submitted = <WorkOrderCommand>[];
  final reconciled = <WorkOrderCommand>[];
  final responses = <Completer<WorkOrderReply>>[];
  final replies = <Completer<WorkOrderReply>>[];
  @override
  Future<WorkOrderReply> submitOrderCommand(WorkOrderCommand command) {
    submitted.add(command);
    final response = Completer<WorkOrderReply>();
    responses.add(response);
    return response.future;
  }

  @override
  Future<WorkOrderReply> reconcileOrderCommand(WorkOrderCommand command) {
    reconciled.add(command);
    final reply = Completer<WorkOrderReply>();
    replies.add(reply);
    return reply.future;
  }
}

class _DeliveryBookingFixtureGateway extends ReviewWorkGateway {
  final requests = <({String store, String order, String address})>[];
  final response = Completer<WorkDeliveryAssignmentResult>();
  @override
  Future<WorkDeliveryAssignmentResult> requestDeliveryAssignment({
    required String workspaceId,
    required String orderId,
    required String address,
    required String idempotencyKey,
  }) {
    requests.add((store: workspaceId, order: orderId, address: address));
    return response.future;
  }
}

class _ScopedTimingFixtureGateway extends _OrderCommandFixtureGateway
    implements WorkOrderTimeCommandGateway {
  @override
  bool get supportsOrderTimeRequests => true;
}

class _TimingFixtureGateway extends ReviewWorkGateway
    implements WorkOrderTimeGateway {
  final requests = <WorkOrderTimeRequest>[];
  Future<WorkOrderTimeResult> Function(WorkOrderTimeRequest)? respond;
  @override
  Future<WorkOrderTimeResult> requestOrderTime(
    WorkOrderTimeRequest request,
  ) async {
    requests.add(request);
    if (respond != null) return respond!(request);
    return WorkOrderTimeResult(
      workspaceId: request.workspaceId,
      orderId: request.orderId,
      operationId: request.operationId,
      approved: true,
      acceptanceDeadline: request.expectedAcceptanceDeadline.add(
        Duration(minutes: request.additionalMinutes),
      ),
      fulfilmentDeadline: request.expectedAcceptanceDeadline.add(
        const Duration(minutes: 18),
      ),
    );
  }
}

const _collectionFixtureToken = 'mool-collection-review-order-1043';

class _CollectionFixtureGateway
    implements ScanPickGateway, StoreCollectionReadinessGateway {
  String storeId = 'WK-510001';
  ScanPickState state = ScanPickState.awaitingCustomer;
  ScanPickPayment payment = ScanPickPayment.paid;
  String? revision;
  ScanPickError? error;
  bool expired = false, wrongOrder = false, wrongStore = false;
  int totalMinor = 146850;
  final List<ScanPickRequest> requests = [];
  Future<ScanPickResult> Function(ScanPickRequest)? respond;
  Future<void> Function()? readyRespond;
  final List<({String store, String order, String revision, String operation})>
  readyRequests = [];

  @override
  Future<void> markGoodsReady({
    required String storeId,
    required String orderId,
    required String expectedRevision,
    required String operationId,
  }) async {
    readyRequests.add((
      store: storeId,
      order: orderId,
      revision: expectedRevision,
      operation: operationId,
    ));
    if (readyRespond != null) {
      await readyRespond!();
    } else {
      state = ScanPickState.ready;
    }
  }

  @override
  Future<ScanPickResult> execute(ScanPickRequest request) async {
    requests.add(request);
    if (respond != null) return respond!(request);
    if (request.operation == ScanPickOperation.handOver) {
      state = ScanPickState.collected;
    }
    if (request.operation == ScanPickOperation.issueChallenge) {
      state = ScanPickState.awaitingCustomer;
    }
    return reply(request);
  }

  ScanPickResult reply(ScanPickRequest request) {
    final time = DateTime.utc(2026, 9, 7, 8);
    final expiry = time
        .add(Duration(minutes: expired ? -1 : 2))
        .toIso8601String();
    return ScanPickResult.fromJson({
      'protocolVersion': 1,
      'requestId': request.requestId,
      'operation': request.operation.name,
      if (request.operationId != null) 'operationId': request.operationId,
      'outcome': error == null ? 'snapshot' : 'rejected',
      if (error != null) 'error': error!.name,
      'snapshot': {
        'purpose': scanPickPurpose,
        'orderId': wrongOrder ? 'WRONG-ORDER' : request.orderId,
        'storeId': wrongStore ? 'WRONG-STORE' : storeId,
        'purchaserAccountId': 'review-purchaser',
        'customerName': 'Rakesh Sharma',
        'storeName': 'Mahadev Fresh Mart',
        'revision': revision ?? 'fixture-${state.name}',
        'serverTime': time.toIso8601String(),
        'state': state.name,
        'payment': payment.name,
        'readiness': state == ScanPickState.preparing ? 'preparing' : 'ready',
        'currency': 'INR',
        'totalMinor': totalMinor,
        'lines': [
          {
            'lineId': 'line-oil',
            'productId': 'product-oil',
            'skuId': 'fortune-oil-1l',
            'name': 'Fortune Sunflower Oil',
            'pack': '1 litre pouch',
            'quantity': '2',
            'amountMinor': 33800,
          },
          {
            'lineId': 'line-atta',
            'productId': 'product-atta',
            'skuId': 'aashirvaad-atta-10kg',
            'name': 'Aashirvaad Atta',
            'pack': '10 kg bag',
            'quantity': '1',
            'amountMinor': totalMinor - 33800,
          },
        ],
        if (state == ScanPickState.awaitingCustomer)
          'challenge': {
            'id': 'fixture-challenge',
            'expiresAt': expiry,
            'qrPayload': _collectionFixtureToken,
          },
        if (state == ScanPickState.matched)
          'approval': {'id': 'fixture-approval', 'expiresAt': expiry},
        if (state == ScanPickState.collected)
          'receipt': {
            'id': 'fixture-receipt',
            'collectedAt': time.toIso8601String(),
            'invoiceReference': 'INV-1043',
          },
      },
    });
  }
}

/// Test-only QR matrix generated with ReportLab's QR encoder for the exact
/// synthetic token above. Four quiet-zone modules, no production authority.
class _CollectionQrFixture extends CustomPainter {
  const _CollectionQrFixture();
  static const _rows = [
    '11111110011101110010101111111',
    '10000010000110010000101000001',
    '10111010011100101001101011101',
    '10111010101100110100001011101',
    '10111010101011110111101011101',
    '10000010011001101100101000001',
    '11111110101010101010101111111',
    '00000000010011000000100000000',
    '11000111011010110100000011000',
    '01000101101000100001000111000',
    '01000111010110000110111010000',
    '11111001001100111010010110011',
    '01010011111001101000101001000',
    '00011100011011100011101111101',
    '11010011000001111000001101000',
    '00101000001011111011010011110',
    '10001110111010111100100000101',
    '10100001111000010011101110001',
    '11100010010011111101000010001',
    '10010001000100101000101111010',
    '10010011101100011100111110101',
    '00000000111011011000100011000',
    '11111110110001110111101011100',
    '10000010101011000011100011010',
    '10111010000111010011111111011',
    '10111010011000010110100001101',
    '10111010010110011000011110010',
    '10000010110100001001010011101',
    '11111110100100011111000100100',
  ];
  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final unit = side / (_rows.length + 8);
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final ink = Paint()
      ..color = Colors.black
      ..isAntiAlias = false;
    for (var y = 0; y < _rows.length; y++) {
      for (var x = 0; x < _rows[y].length; x++) {
        if (_rows[y][x] == '1') {
          canvas.drawRect(
            Rect.fromLTWH((x + 4) * unit, (y + 4) * unit, unit, unit),
            ink,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_CollectionQrFixture oldDelegate) => false;
}

void main() {
  WorkSession liveStore({ReviewWorkGateway? gateway}) =>
      WorkSession(gateway: gateway)
        ..seedVerifiedWorkspace()
        ..retailerSetupSaved = true
        ..reviewStage = WorkReviewStage.live
        ..workspaceStoreState = WorkspaceStoreState.open
        ..workspaceAcceptingOrders = true
        ..workspaceVisibleToCustomers = true
        ..workspaceLastUpdatedAt = DateTime(2026, 9, 3, 8, 30);

  const captureStoreViewV2 = bool.fromEnvironment('MOOL_CAPTURE_STORE_VIEW_V2');
  const captureFounderEvidence = bool.fromEnvironment(
    'MOOL_CAPTURE_WORK_STORE_1_40',
  );
  const captureStoreLiveEvidence = bool.fromEnvironment(
    'MOOL_CAPTURE_WORK_STORE_LIVE_V1',
  );
  void expectExactMoneyVisible(WidgetTester tester, Finder amounts) {
    expect(amounts, findsWidgets);
    for (final element in amounts.evaluate()) {
      final target = find.byElementPredicate(
        (candidate) => candidate == element,
      );
      expect(
        find.ancestor(
          of: target,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is SingleChildScrollView &&
                widget.scrollDirection == Axis.horizontal,
          ),
        ),
        findsNothing,
        reason:
            'The complete supported amount must be visible without sideways scrolling',
      );
      final paragraph = element.renderObject! as RenderParagraph;
      final value = (element.widget as Text).data!;
      final boxes = paragraph.getBoxesForSelection(
        TextSelection(baseOffset: 0, extentOffset: value.length),
      );
      expect(boxes, hasLength(1));
      expect(boxes.single.left, greaterThanOrEqualTo(-.5));
      expect(boxes.single.right, lessThanOrEqualTo(paragraph.size.width + .5));
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(tester.getTopLeft(target).dx, greaterThanOrEqualTo(-.5));
      expect(
        tester.getTopRight(target).dx,
        lessThanOrEqualTo(tester.view.physicalSize.width + .5),
      );
    }
  }

  void expectFinanceActionWords(WidgetTester tester) {
    for (final entry in const {
      'work-pulse-sales': 'View statement',
      'work-pulse-dues': 'Collect dues',
      'work-pulse-settlement': 'Settle',
    }.entries) {
      final label = find.descendant(
        of: find.byKey(Key(entry.key)),
        matching: find.text(entry.value),
      );
      final paragraph = tester.renderObject<RenderParagraph>(label);
      expect(paragraph.didExceedMaxLines, isFalse);
      for (final word in RegExp(r'\S+').allMatches(entry.value)) {
        final boxes = paragraph.getBoxesForSelection(
          TextSelection(baseOffset: word.start, extentOffset: word.end),
        );
        expect(boxes, hasLength(1), reason: '${entry.key}: ${word.group(0)}');
        expect(boxes.single.left, greaterThanOrEqualTo(-.5));
        expect(
          boxes.single.right,
          lessThanOrEqualTo(paragraph.size.width + .5),
        );
      }
      final amount = find.descendant(
        of: find.byKey(Key('${entry.key}-value-motion')),
        matching: find.byType(Text),
      );
      expect(amount, findsOneWidget);
      final amountText = tester.widget<Text>(amount).data!;
      final amountParagraph = tester.renderObject<RenderParagraph>(amount);
      expect(amountParagraph.didExceedMaxLines, isFalse);
      for (final digits in RegExp(r'[\d,.]+').allMatches(amountText)) {
        final boxes = amountParagraph.getBoxesForSelection(
          TextSelection(baseOffset: digits.start, extentOffset: digits.end),
        );
        expect(boxes, hasLength(1), reason: '${entry.key}: $amountText');
        expect(boxes.single.left, greaterThanOrEqualTo(-.5));
        expect(
          boxes.single.right,
          lessThanOrEqualTo(amountParagraph.size.width + .5),
          reason: '${entry.key}: all amount digits must fit',
        );
      }
    }
  }

  Future<void> mount(
    WidgetTester tester, {
    required String route,
    required WorkSession work,
    ChatSession? chat,
    double bottomInset = 44,
    Size viewport = const Size(360, 800),
    double textScale = 1.4,
    Widget Function(Widget child)? wrapper,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = viewport;
    tester.view.viewPadding = FakeViewPadding(bottom: bottomInset);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final journey = JourneySession(
      store: MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'manual',
          areaLabel: 'Jodhpur',
          setupComplete: true,
        ),
      ),
      otpGateway: ReviewOtpGateway(signedIn: true),
    );
    await journey.start();
    journey
      ..accountIdentity = const AuthenticatedAccountIdentity(
        displayName: 'Asha Sharma',
        emailAddress: 'asha@example.com',
        phoneNumber: '+91 98290 12321',
        providerAccountLabel: 'asha@example.com',
        signInMethods: ['Google', 'Phone'],
      )
      ..socialAuthProvider = SocialAuthProvider.google;
    addTearDown(journey.dispose);
    addTearDown(work.dispose);
    if (chat != null) addTearDown(chat.dispose);
    await tester.pumpWidget(
      RepaintBoundary(
        key: const Key('store-review-root'),
        child: (wrapper ?? (child) => child)(
          MoolSocialApp(
            session: journey,
            workSession: work,
            chatSession: chat,
            initialLocation: route,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  WorkSession storeViewFixture([
    WorkGateway? gateway,
    WorkPendingProofStore? contactStore,
    WorkIssueDraftStore? issueDraftStore,
    WorkIssueCommandGateway? issueCommandGateway,
    WorkIssueCommandStore? issueCommandStore,
    WorkStockHistoryGateway? stockHistoryGateway,
    WorkReceiptDraftStore? receiptDraftStore,
  ]) {
    final work =
        WorkSession(
            gateway: gateway,
            contactDraftStore: contactStore,
            counterDraftStore: _CounterDraftFixtureStore(),
            issueDraftStore: issueDraftStore ?? _IssueDraftFixtureStore(),
            issueCommandGateway: issueCommandGateway,
            issueCommandStore: issueCommandStore ?? _IssueCommandFixtureStore(),
            stockHistoryGateway: stockHistoryGateway,
            receiptDraftStore: receiptDraftStore ?? _ReceiptDraftFixtureStore(),
          )
          ..seedVerifiedWorkspace()
          ..retailerSetupSaved = true
          ..reviewStage = WorkReviewStage.live
          ..workspaceStoreState = WorkspaceStoreState.open
          ..workspaceAcceptingOrders = true
          ..workspaceVisibleToCustomers = true
          ..workspaceSalesToday = 28450
          ..workspaceSettlementBalance = 17820
          ..workspacePayoutBankName = 'Review Bank'
          ..workspacePayoutAccountEnding = '1234'
          ..workspaceOrderCustomer = 'Rakesh · 98290 12345'
          ..workspaceOrderSource = 'App'
          ..workspaceOrderItems = 'Fortune Oil × 2 · Aashirvaad Atta × 1'
          ..workspaceOrderAmount = '1468'
          ..workspaceOrderStage = 'Confirmed'
          ..workspaceOrderActionDeadline = DateTime.now().add(
            const Duration(seconds: 60),
          )
          ..workspaceOrderPayment = 'Paid online'
          ..workspaceOrderFulfilment = 'Pickup';
    work.currentWorkspaceOrderId = 'APP-1043';
    work.workspaceOrders.add(
      WorkspaceOrderRecord(
        id: 'APP-1043',
        customer: work.workspaceOrderCustomer,
        createdAt: DateTime.now(),
        amount: 1468,
        payment: 'Paid online',
        source: 'App',
        items: work.workspaceOrderItems,
        quantities: const {},
        fulfilment: 'Pickup',
        address: '',
        stage: 'Confirmed',
        needsDelivery: false,
        actionDeadline: work.workspaceOrderActionDeadline,
      ),
    );
    work.activeGroupBuy = const WorkspaceGroupBuy(
      id: 'REVIEW-ONION-01',
      productName: 'Onions',
      specification: 'Fresh red onions · 45–65 mm · 50 kg sacks',
      leadRetailer: 'Mahadev Fresh Mart',
      confirmedRetailers: ['Mahadev Fresh Mart', 'Shree Grocery'],
      targetQuantity: 1000,
      securedQuantity: 150,
      unitLabel: 'kg',
      regularUnitPrice: 20,
      groupUnitPrice: 14,
      facilitationFee: 50,
      deliveryFee: 100,
      confirmationAmount: 500,
      closingLabel: '10 Sep · 6 PM',
      storeDeliveryLabel: '12 Sep · Store delivery',
      paymentConfirmed: true,
      participants: [
        WorkspaceGroupBuyParticipant(
          businessName: 'Mahadev Fresh Mart',
          locality: 'Sardarpura',
          quantity: 100,
          unitLabel: 'kg',
          milestone: 'Confirmed',
        ),
        WorkspaceGroupBuyParticipant(
          businessName: 'Shree Grocery',
          locality: 'Ratanada',
          quantity: 50,
          unitLabel: 'kg',
          milestone: 'Confirmed',
        ),
      ],
    );
    work.workspaceOrders.add(
      WorkspaceOrderRecord(
        id: 'SALE-1042',
        customer: 'Meena · 98765 43210',
        createdAt: DateTime.now(),
        amount: 860,
        payment: 'Payment due',
        source: 'Counter',
        items: 'Grocery purchases',
        quantities: const {},
        fulfilment: 'Pickup',
        address: '',
        stage: 'Completed',
        needsDelivery: false,
      ),
    );
    return work;
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    final vertical = find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable &&
          (widget.axisDirection == AxisDirection.down ||
              widget.axisDirection == AxisDirection.up),
    );
    for (
      var attempt = 0;
      attempt < 12 && finder.evaluate().isEmpty;
      attempt++
    ) {
      final contactPage = find.byKey(const Key('work-contact-screen'));
      final pageScroll = contactPage.evaluate().isEmpty
          ? vertical.last
          : find
                .descendant(
                  of: contactPage,
                  matching: find.byWidgetPredicate(
                    (widget) =>
                        widget is Scrollable &&
                        widget.axisDirection == AxisDirection.down,
                  ),
                )
                .first;
      await tester.drag(pageScroll, const Offset(0, -220));
      await tester.pumpAndSettle();
    }
    expect(finder, findsOneWidget);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  Future<void> openTrackedPurchases(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('work-store-stock')));
    await tester.pumpAndSettle();
    final tracking = find.byKey(const Key('work-shortcut-sourcing'));
    await reveal(tester, tracking);
    await tester.tap(tracking);
    await tester.pumpAndSettle();
  }

  Future<void> captureStoreView(WidgetTester tester, String name) async {
    if (!captureStoreViewV2) return;
    const folder = String.fromEnvironment(
      'MOOL_STORE_VIEW_CAPTURE_DIR',
      defaultValue: 'store-dashboard-first-tap-local-review-20260905',
    );
    await expectLater(
      find.byKey(const Key('store-review-root')),
      matchesGoldenFile(
        '../../../../MOOLSOCIAL-POST-UI-AUDIT-20260905/$folder/$name.png',
      ),
    );
  }

  WorkSession collectionStore(
    _CollectionFixtureGateway gateway, {
    bool readinessAvailable = true,
  }) {
    final work = storeViewFixture();
    final original = work.currentWorkspaceOrder!;
    work.workspaceOrders[0] = WorkspaceOrderRecord(
      id: original.id,
      customer: original.customer,
      items: original.items,
      quantities: original.quantities,
      amount: original.amount,
      source: 'App',
      fulfilment: 'Collect at store',
      payment: 'Paid online',
      address: '',
      stage: 'Ready for collection',
      needsDelivery: false,
      createdAt: DateTime(2026, 8, 1),
      collectionStoreId: work.activeWorkspace!.id,
    );
    gateway.storeId = work.activeWorkspace!.id;
    work.attachCollection(
      StoreCollectionController(
        storeId: gateway.storeId,
        orderId: original.id,
        gateway: gateway,
        readinessGateway: readinessAvailable ? gateway : null,
      ),
    );
    return work;
  }

  group('Store collection controller', () {
    test('summary copy needs current scoped customer authorisation', () async {
      final gate = _CollectionFixtureGateway()..state = ScanPickState.matched;
      final work = collectionStore(gate);
      addTearDown(work.dispose);
      await work.currentCollection!.refresh();
      final order = work.currentWorkspaceOrder!;
      expect(work.workspaceOrderStageLabel(order), 'Customer confirmed');
      expect(
        work.workspaceOrderStageLabel(order.copyWith(stage: 'Matched')),
        'Customer confirmed',
      );
      final biker = work.workspaceOrders.firstWhere(
        (o) => !o.isCustomerCollection,
      );
      expect(work.workspaceOrderStageLabel(biker), biker.stage);
      gate.expired = true;
      await work.currentCollection!.refresh();
      expect(work.workspaceOrderStageLabel(order), 'Checking order');
      expect(work.currentWorkspaceOrderStageLabel, 'Checking order');
      expect(work.currentCollection!.canHandOver, isFalse);
      gate
        ..expired = false
        ..error = ScanPickError.revisionConflict;
      await work.currentCollection!.refresh();
      expect(work.workspaceOrderStageLabel(order), 'Checking order');
      gate.error = null;
      await work.currentCollection!.refresh();
      expect(work.selectWorkspaceOrder(biker.id), isTrue);
      expect(work.workspaceOrderStageLabel(order), 'Checking order');
      expect(work.currentWorkspaceOrderStageLabel, biker.stage);
    });

    test(
      'Order ready cannot be submitted for unpaid or terminal orders',
      () async {
        for (final payment in [
          ScanPickPayment.unpaid,
          ScanPickPayment.partiallyPaid,
          ScanPickPayment.refunded,
        ]) {
          final gate = _CollectionFixtureGateway()
            ..state = ScanPickState.preparing
            ..payment = payment;
          final work = collectionStore(gate);
          await work.currentCollection!.refresh();
          expect(work.currentCollection!.canMarkGoodsReady, isFalse);
          await work.currentCollection!.goodsReady();
          expect(gate.readyRequests, isEmpty);
          expect(work.currentCollection!.visibleQr, isNull);
          work.dispose();
        }
        for (final state in [
          ScanPickState.cancelled,
          ScanPickState.collected,
        ]) {
          final gate = _CollectionFixtureGateway()..state = state;
          final work = collectionStore(gate);
          await work.currentCollection!.refresh();
          await work.currentCollection!.goodsReady();
          expect(gate.readyRequests, isEmpty);
          work.dispose();
        }
      },
    );

    test('unchanged readiness revision cannot expose a QR', () async {
      final gate = _CollectionFixtureGateway()
        ..state = ScanPickState.preparing
        ..revision = 'revision-before-packing';
      final work = collectionStore(gate);
      addTearDown(work.dispose);
      await work.currentCollection!.refresh();
      await work.currentCollection!.goodsReady();
      await work.currentCollection!.showCode();
      expect(work.currentCollection!.needsReconciliation, isTrue);
      expect(work.currentCollection!.hasAuthoritativeSnapshot, isFalse);
      expect(work.currentCollection!.visibleQr, isNull);
      expect(work.workspaceOrderStage, 'Preparing');
      gate.revision = 'revision-after-packing';
      await work.currentCollection!.refresh();
      expect(work.currentCollection!.needsReconciliation, isFalse);
      expect(work.workspaceOrderStage, 'Ready for collection');
      expect(gate.readyRequests, hasLength(1));
    });

    test(
      'Goods ready requires a tap and correlated server readiness',
      () async {
        final gate = _CollectionFixtureGateway()
          ..state = ScanPickState.preparing;
        final work = collectionStore(gate);
        addTearDown(work.dispose);
        final controller = work.currentCollection!;
        await controller.refresh();
        await controller.refresh();
        await controller.showCode();
        expect(gate.readyRequests, isEmpty);
        expect(controller.visibleQr, isNull);
        expect(work.workspaceOrderStage, 'Preparing');
        final pending = Completer<void>();
        gate.readyRespond = () => pending.future;
        final first = controller.goodsReady();
        await controller.goodsReady();
        await controller.showCode();
        await controller.handOver();
        expect(gate.readyRequests, hasLength(1));
        final request = gate.readyRequests.single;
        expect(request.store, gate.storeId);
        expect(request.order, work.currentWorkspaceOrderId);
        expect(request.revision, 'fixture-preparing');
        expect(request.operation, isNotEmpty);
        expect(controller.confirmingReadiness, isTrue);
        expect(controller.visibleQr, isNull);
        expect(controller.canHandOver, isFalse);
        expect(work.workspaceOrderStage, 'Preparing');
        expect(work.selectWorkspaceOrder('SALE-1042'), isFalse);
        gate.state = ScanPickState.ready;
        pending.complete();
        await first;
        expect(gate.requests.last.operation, ScanPickOperation.reconcile);
        expect(gate.requests.last.operationId, request.operation);
        expect(controller.needsReconciliation, isFalse);
        expect(work.workspaceOrderStage, 'Ready for collection');
        expect(controller.visibleQr, isNull);
        await controller.goodsReady();
        expect(gate.readyRequests, hasLength(1));
        await controller.showCode();
        expect(controller.visibleQr, _collectionFixtureToken);
        expect(controller.canHandOver, isFalse);
        expect(work.workspaceSalesToday, 28450);
        expect(work.workspaceInvoices, isEmpty);
      },
    );

    test(
      'readiness ACK or lost reply does not prove goods are ready',
      () async {
        for (final lostReply in [false, true]) {
          final gate = _CollectionFixtureGateway()
            ..state = ScanPickState.preparing
            ..readyRespond = () async {
              if (lostReply) throw StateError('synthetic lost response');
            };
          final work = collectionStore(gate);
          final controller = work.currentCollection!;
          await controller.refresh();
          await controller.goodsReady();
          expect(controller.needsReconciliation, isTrue);
          expect(controller.confirmingReadiness, isTrue);
          expect(controller.visibleQr, isNull);
          expect(controller.canHandOver, isFalse);
          await controller.goodsReady();
          await controller.refresh();
          expect(gate.readyRequests, hasLength(1));
          final reconciliations = gate.requests.where(
            (r) => r.operation == ScanPickOperation.reconcile,
          );
          expect(reconciliations.map((r) => r.operationId).toSet(), {
            gate.readyRequests.single.operation,
          });
          expect(reconciliations.map((r) => r.requestId).toSet(), hasLength(2));
          gate.state = ScanPickState.ready;
          await controller.refresh();
          expect(controller.needsReconciliation, isFalse);
          expect(work.workspaceOrderStage, 'Ready for collection');
          work.dispose();
        }
      },
    );

    test(
      'rejected readiness is recoverable but cannot expose a code',
      () async {
        final gate = _CollectionFixtureGateway()
          ..state = ScanPickState.preparing;
        final work = collectionStore(gate);
        addTearDown(work.dispose);
        final controller = work.currentCollection!;
        await controller.refresh();
        gate.readyRespond = () async {
          gate.error = ScanPickError.paymentChanged;
        };
        await controller.goodsReady();
        expect(controller.needsReconciliation, isFalse);
        expect(controller.message, contains('Payment'));
        expect(controller.canMarkGoodsReady, isFalse);
        await controller.showCode();
        expect(controller.visibleQr, isNull);
        gate.error = null;
        gate.readyRespond = null;
        await controller.refresh();
        await controller.goodsReady();
        expect(gate.readyRequests, hasLength(2));
        expect(
          gate.readyRequests[0].operation,
          isNot(gate.readyRequests[1].operation),
        );
        expect(controller.snapshot!.state, ScanPickState.ready);
      },
    );

    test(
      'wrong-order readiness remains uncertain until exact reconciliation',
      () async {
        final gate = _CollectionFixtureGateway()
          ..state = ScanPickState.preparing;
        final work = collectionStore(gate);
        addTearDown(work.dispose);
        final controller = work.currentCollection!;
        await controller.refresh();
        gate.wrongOrder = true;
        await controller.goodsReady();
        expect(controller.needsReconciliation, isTrue);
        expect(work.workspaceOrderStage, 'Preparing');
        expect(controller.visibleQr, isNull);
        gate.wrongOrder = false;
        await controller.refresh();
        expect(controller.snapshot!.state, ScanPickState.ready);
        expect(gate.readyRequests, hasLength(1));
      },
    );

    test(
      'no readiness adapter or reopened ready order never fakes a tap',
      () async {
        final gate = _CollectionFixtureGateway()
          ..state = ScanPickState.preparing;
        final work = collectionStore(gate, readinessAvailable: false);
        await work.currentCollection!.refresh();
        expect(work.currentCollection!.canMarkGoodsReady, isFalse);
        await work.currentCollection!.goodsReady();
        expect(gate.readyRequests, isEmpty);
        expect(work.currentCollection!.visibleQr, isNull);
        work.dispose();
        gate.state = ScanPickState.ready;
        final reopened = collectionStore(gate);
        await reopened.currentCollection!.refresh();
        await reopened.currentCollection!.goodsReady();
        await reopened.currentCollection!.showCode();
        expect(gate.readyRequests, isEmpty);
        expect(reopened.currentCollection!.visibleQr, _collectionFixtureToken);
        reopened.dispose();
      },
    );

    test(
      'late readiness reply cannot update a disposed Store session',
      () async {
        final gate = _CollectionFixtureGateway()
          ..state = ScanPickState.preparing;
        final work = collectionStore(gate);
        final controller = work.currentCollection!;
        await controller.refresh();
        final pending = Completer<void>();
        gate.readyRespond = () => pending.future;
        final request = controller.goodsReady();
        work.dispose();
        gate.state = ScanPickState.ready;
        pending.complete();
        await request;
        expect(gate.requests, hasLength(1));
        expect(controller.visibleQr, isNull);
        expect(controller.canHandOver, isFalse);
      },
    );

    test(
      'Matched permits one Hand Over; unknown reconciles the same mutation',
      () async {
        final gate = _CollectionFixtureGateway()..state = ScanPickState.matched;
        final work = collectionStore(gate);
        addTearDown(work.dispose);
        final controller = work.currentCollection!;
        await controller.refresh();
        expect(controller.canHandOver, isTrue);
        final waiting = Completer<ScanPickResult>();
        gate.respond = (request) =>
            request.operation == ScanPickOperation.handOver
            ? waiting.future
            : Future.value(gate.reply(request));
        final first = controller.handOver();
        expect(work.selectWorkspaceOrder('SALE-1042'), isFalse);
        expect(work.currentCollection, same(controller));
        await controller.handOver();
        final handovers = gate.requests
            .where((request) => request.operation == ScanPickOperation.handOver)
            .toList();
        expect(handovers, hasLength(1));
        waiting.complete(
          ScanPickResult.fromJson({
            'protocolVersion': 1,
            'requestId': handovers.single.requestId,
            'operation': 'handOver',
            'operationId': handovers.single.operationId,
            'outcome': 'unknown',
          }),
        );
        await first;
        expect(controller.canHandOver, isFalse);
        expect(controller.needsReconciliation, isTrue);
        expect(work.selectWorkspaceOrder('SALE-1042'), isFalse);
        gate.respond = null;
        gate.state = ScanPickState.collected;
        await controller.refresh();
        expect(gate.requests.last.operation, ScanPickOperation.reconcile);
        expect(gate.requests.last.operationId, handovers.single.operationId);
        expect(controller.snapshot!.state, ScanPickState.collected);
        expect(work.workspaceOrderStage, 'Collected');
        expect(work.hasActiveWorkspaceOrder, isFalse);
        expect(work.currentWorkspaceOrder!.isClosed, isTrue);
        expect(work.workspaceSalesToday, 28450);
        expect(work.workspaceSettlementBalance, 17820);
        expect(work.workspaceInvoices, isEmpty);
        await controller.handOver();
        expect(
          gate.requests.where(
            (request) => request.operation == ScanPickOperation.handOver,
          ),
          hasLength(1),
        );
      },
    );

    for (final state in [
      ScanPickState.preparing,
      ScanPickState.ready,
      ScanPickState.awaitingCustomer,
      ScanPickState.cancelled,
      ScanPickState.collected,
    ]) {
      test('no Hand Over from ${state.name}', () async {
        final gate = _CollectionFixtureGateway()..state = state;
        final work = collectionStore(gate);
        addTearDown(work.dispose);
        await work.currentCollection!.refresh();
        await work.currentCollection!.handOver();
        expect(work.currentCollection!.canHandOver, isFalse);
        expect(
          gate.requests.where(
            (request) => request.operation == ScanPickOperation.handOver,
          ),
          isEmpty,
        );
      });
    }

    test(
      'expired approval and rejected matched recovery cannot authorise',
      () async {
        final gate = _CollectionFixtureGateway()
          ..state = ScanPickState.matched
          ..expired = true;
        final work = collectionStore(gate);
        addTearDown(work.dispose);
        await work.currentCollection!.refresh();
        expect(work.currentCollection!.canHandOver, isFalse);
        gate
          ..expired = false
          ..error = ScanPickError.revisionConflict;
        await work.currentCollection!.refresh();
        expect(work.currentCollection!.canHandOver, isFalse);
      },
    );

    test('wrong order and store responses fail closed', () async {
      final gate = _CollectionFixtureGateway()..state = ScanPickState.matched;
      final work = collectionStore(gate);
      addTearDown(work.dispose);
      gate.wrongOrder = true;
      await work.currentCollection!.refresh();
      expect(work.currentCollection!.snapshot, isNull);
      expect(work.currentCollection!.canHandOver, isFalse);
      gate
        ..wrongOrder = false
        ..wrongStore = true;
      await work.currentCollection!.refresh();
      expect(work.currentCollection!.snapshot, isNull);
    });

    test(
      'old pickup and counter completion cannot bypass collection',
      () async {
        final work = collectionStore(_CollectionFixtureGateway());
        addTearDown(work.dispose);
        final order = work.currentWorkspaceOrder!;
        final stock = work.workspaceCatalogueItems
            .map((item) => item.stock)
            .toList();
        work.advanceWorkspaceOrder();
        expect(await work.verifyWorkspacePickup('123456'), isFalse);
        expect(await work.verifyWorkspaceHandover('123456'), isFalse);
        expect(work.completeWorkspaceCounterSale(), isNull);
        work.saveWorkspaceOrderDraft(
          customer: 'Replacement',
          source: 'Counter',
          fulfilment: 'Pickup',
          payment: 'Paid',
          address: '',
        );
        expect(work.currentWorkspaceOrder, same(order));
        expect(work.currentWorkspaceOrder!.isCustomerCollection, isTrue);
        expect(work.workspaceInvoices, isEmpty);
        expect(
          work.workspaceCatalogueItems.map((item) => item.stock).toList(),
          stock,
        );
      },
    );

    test('expired code renews without expiring the paid order', () async {
      final gate = _CollectionFixtureGateway()..expired = true;
      final work = collectionStore(gate);
      addTearDown(work.dispose);
      await work.currentCollection!.refresh();
      expect(work.currentCollection!.visibleQr, isNull);
      expect(work.currentWorkspaceOrder!.createdAt, DateTime(2026, 8, 1));
      gate.expired = false;
      await work.currentCollection!.showCode();
      expect(gate.requests.last.operation, ScanPickOperation.issueChallenge);
      expect(work.currentCollection!.visibleQr, _collectionFixtureToken);
      expect(work.currentCollection!.canHandOver, isFalse);
    });

    test(
      'relaunch reads Collected without repeating completion effects',
      () async {
        final gate = _CollectionFixtureGateway()
          ..state = ScanPickState.collected;
        final work = collectionStore(gate);
        addTearDown(work.dispose);
        await work.currentCollection!.refresh();
        expect(work.workspaceOrderStage, 'Collected');
        expect(gate.requests, hasLength(1));
        expect(gate.requests.single.operation, ScanPickOperation.read);
        expect(work.workspaceInvoices, isEmpty);
        expect(work.workspaceSalesToday, 28450);
      },
    );

    test('late reply cannot replace the newly selected order', () async {
      final gate = _CollectionFixtureGateway();
      final work = collectionStore(gate);
      addTearDown(work.dispose);
      final waiting = Completer<ScanPickResult>();
      gate.respond = (_) => waiting.future;
      final controller = work.currentCollection!;
      final request = controller.refresh();
      final originalRequest = gate.requests.single;
      expect(work.selectWorkspaceOrder('SALE-1042'), isTrue);
      waiting.complete(gate.reply(originalRequest));
      await request;
      expect(work.currentCollection, isNull);
      expect(work.currentWorkspaceOrderId, 'SALE-1042');
      expect(work.currentWorkspaceOrder!.stage, 'Completed');
    });
  });

  for (final display in [
    (width: 412.0, height: 915.0, scale: 1.0),
    (width: 320.0, height: 640.0, scale: 1.4),
    (width: 320.0, height: 640.0, scale: 2.0),
  ]) {
    testWidgets('Store collection explicit Goods ready ${display.scale}', (
      tester,
    ) async {
      final gate = _CollectionFixtureGateway()..state = ScanPickState.preparing;
      final pending = Completer<void>();
      gate.readyRespond = () => pending.future;
      final work = collectionStore(gate);
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: Size(display.width, display.height),
        textScale: display.scale,
        wrapper: (child) => WorkCollectionCodeRenderer(
          render: (_, payload) =>
              const CustomPaint(painter: _CollectionQrFixture()),
          child: child,
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      expect(gate.readyRequests, isEmpty);
      expect(find.byKey(const Key('work-collection-qr')), findsNothing);
      expect(find.text('Pack order'), findsOneWidget);
      expect(find.text('Order ready'), findsOneWidget);
      expect(find.text('Goods ready'), findsNothing);
      await captureStoreView(
        tester,
        'goods-ready-first-${display.width.toInt()}-${display.scale}',
      );
      if (display.scale == 1) {
        final viewport = tester.getRect(
          find.byKey(const Key('work-collection-content')),
        );
        expect(
          viewport.contains(
            tester
                .getRect(find.byKey(const Key('work-collection-amount')))
                .bottomRight,
          ),
          isTrue,
        );
      }
      final action = find.byKey(const Key('work-collection-goods-ready'));
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
      await captureStoreView(
        tester,
        'goods-ready-${display.width.toInt()}-${display.scale}',
      );
      final readyRect = tester.getRect(action);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(gate.readyRequests, hasLength(1));
      expect(tester.widget<FilledButton>(action).onPressed, isNull);
      expect(find.text('Updating'), findsOneWidget);
      expect(
        find.text('Checking your update. Do not hand over yet.'),
        findsOneWidget,
      );
      final pendingRect = tester.getRect(action);
      expect(pendingRect.height, lessThanOrEqualTo(readyRect.height));
      expect(pendingRect.top, greaterThanOrEqualTo(readyRect.top));
      expect(pendingRect.bottom, lessThanOrEqualTo(readyRect.bottom + 1));
      expect(find.byKey(const Key('work-collection-qr')), findsNothing);
      expect(work.workspaceOrderStage, 'Preparing');
      await captureStoreView(
        tester,
        'goods-ready-pending-${display.width.toInt()}-${display.scale}',
      );
      gate.state = ScanPickState.ready;
      pending.complete();
      await tester.pumpAndSettle();
      expect(gate.readyRequests, hasLength(1));
      expect(
        find.byKey(const Key('work-collection-goods-ready')),
        findsNothing,
      );
      final qr = find.byKey(const Key('work-collection-qr'));
      await tester.ensureVisible(qr);
      await tester.pumpAndSettle();
      expect(qr, findsOneWidget);
      expect(work.currentCollection!.canHandOver, isFalse);
      await captureStoreView(
        tester,
        'goods-ready-confirmed-${display.width.toInt()}-${display.scale}',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
    for (final state in [
      ScanPickState.awaitingCustomer,
      ScanPickState.matched,
      ScanPickState.collected,
      ScanPickState.cancelled,
    ]) {
      testWidgets('Store collection actual dashboard ${state.name} ${display.scale}', (
        tester,
      ) async {
        final gate = _CollectionFixtureGateway()..state = state;
        final work = collectionStore(gate);
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: Size(display.width, display.height),
          textScale: display.scale,
          wrapper: (child) => WorkCollectionCodeRenderer(
            render: (_, payload) {
              expect(payload, _collectionFixtureToken);
              return const CustomPaint(painter: _CollectionQrFixture());
            },
            child: child,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-collection-live-card')),
          findsOneWidget,
        );
        expect(find.text('Collect at store'), findsOneWidget);
        expect(find.text('Rakesh Sharma'), findsOneWidget);
        expect(find.byKey(const Key('work-pickup-code')), findsNothing);
        final renderedCopy = tester
            .widgetList<Text>(
              find.descendant(
                of: find.byKey(const Key('work-collection-live-card')),
                matching: find.byType(Text),
              ),
            )
            .map((text) => text.data ?? text.textSpan?.toPlainText() ?? '')
            .join('\n');
        expect(
          RegExp(
            r'\b(goods|matched|readiness|reconciliation)\b',
            caseSensitive: false,
          ).hasMatch(renderedCopy),
          isFalse,
          reason:
              'Collection copy must address the retailer, not expose internal states',
        );
        expect(find.text('Collection confirmed'), findsNothing);
        expect(tester.takeException(), isNull);
        await captureStoreView(
          tester,
          'collection-${state.name}-${display.width.toInt()}-${display.scale}',
        );
        if (state == ScanPickState.awaitingCustomer) {
          final qr = find.byKey(const Key('work-collection-qr'));
          final instruction = find.byKey(
            const Key('work-collection-scan-instruction'),
          );
          if (display.scale == 1) {
            final viewport = tester.getRect(
              find.byKey(const Key('work-collection-content')),
            );
            expect(viewport.contains(tester.getRect(qr).bottomRight), isTrue);
            expect(
              viewport.contains(tester.getRect(instruction).topLeft),
              isTrue,
            );
          }
          await tester.ensureVisible(qr);
          await tester.pumpAndSettle();
          expect(tester.getSize(qr).shortestSide, greaterThanOrEqualTo(150));
          expect(work.currentCollection!.canHandOver, isFalse);
          await captureStoreView(
            tester,
            'collection-code-visible-${display.width.toInt()}-${display.scale}',
          );
        }
        if (state == ScanPickState.matched) {
          if (display.scale == 1) {
            final viewport = tester.getRect(
              find.byKey(const Key('work-collection-content')),
            );
            expect(
              viewport.contains(
                tester
                    .getRect(find.byKey(const Key('work-collection-amount')))
                    .bottomRight,
              ),
              isTrue,
            );
          }
          expect(find.text('Matched'), findsNothing);
          expect(find.text('Customer confirmed'), findsOneWidget);
          expect(
            find.text('Scanned from the account that placed this order.'),
            findsOneWidget,
          );
          expect(work.workspaceOrderStage, 'Customer confirmed');
          final action = find.byKey(const Key('work-collection-hand-over'));
          await tester.ensureVisible(action);
          await tester.pumpAndSettle();
          expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
          await captureStoreView(
            tester,
            'collection-action-visible-${display.width.toInt()}-${display.scale}',
          );
          await tester.tap(action);
          await tester.pumpAndSettle();
          expect(find.text('Collected'), findsOneWidget);
          expect(
            find.byKey(const Key('work-collection-hand-over')),
            findsNothing,
          );
          expect(work.workspaceSalesToday, 28450);
          expect(work.workspaceInvoices, isEmpty);
        }
        if (state == ScanPickState.cancelled) {
          expect(find.text('Order cancelled'), findsOneWidget);
          expect(
            find.byKey(const Key('work-collection-hand-over')),
            findsNothing,
          );
          expect(find.byKey(const Key('work-collection-qr')), findsNothing);
        }
        if (state == ScanPickState.collected && display.scale == 1) {
          final viewport = tester.getRect(
            find.byKey(const Key('work-collection-content')),
          );
          expect(
            viewport.contains(
              tester.getRect(find.text('Invoice INV-1043')).bottomRight,
            ),
            isTrue,
          );
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  for (final collectionState in [
    ScanPickState.awaitingCustomer,
    ScanPickState.collected,
  ]) {
    testWidgets('Store collection Orders return ${collectionState.name}', (
      tester,
    ) async {
      final gate = _CollectionFixtureGateway()..state = collectionState;
      final work = collectionStore(gate);
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        wrapper: (child) => WorkCollectionCodeRenderer(
          render: (_, payload) =>
              const CustomPaint(painter: _CollectionQrFixture()),
          child: child,
        ),
      );
      await tester.pumpAndSettle();
      final controller = work.currentCollection;
      await tester.tap(find.byKey(const Key('work-store-orders')));
      await tester.pumpAndSettle();
      final open = find.byKey(const Key('work-order-collection-open-APP-1043'));
      if (collectionState == ScanPickState.collected) {
        expect(
          open,
          findsNothing,
          reason: 'Collected must not remain in live orders',
        );
      }
      final filter = find.byKey(
        Key(
          collectionState == ScanPickState.collected
              ? 'work-orders-filter-done'
              : 'work-orders-filter-ready',
        ),
      );
      await tester.ensureVisible(filter);
      await tester.tap(filter);
      await tester.pumpAndSettle();
      expect(open, findsOneWidget);
      expect(find.text('Confirm pickup'), findsNothing);
      expect(find.text('Complete pickup'), findsNothing);
      await tester.ensureVisible(open);
      await captureStoreView(
        tester,
        'collection-orders-${collectionState.name}',
      );
      await tester.tap(open);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-collection-live-card')),
        findsOneWidget,
      );
      expect(work.currentCollection, same(controller));
      expect(work.currentCollection!.snapshot!.state, collectionState);
      expect(work.workspaceInvoices, isEmpty);
      expect(
        gate.requests.where((r) => r.operation == ScanPickOperation.handOver),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
    'Store collection Orders removes expired confirmation without a tap',
    (tester) async {
      final gate = _CollectionFixtureGateway()..state = ScanPickState.matched;
      final work = collectionStore(gate);
      await mount(tester, route: '/app/work/workspace/dashboard', work: work);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('work-store-orders')));
      await tester.pumpAndSettle();
      final label = find.byKey(const Key('work-order-stage-label-APP-1043'));
      expect(tester.widget<Text>(label).data, 'APP-1043 · Customer confirmed');
      final requests = gate.requests.length;
      await tester.pump(const Duration(minutes: 3));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(label).data, 'APP-1043 · Checking order');
      expect(work.currentCollection!.canHandOver, isFalse);
      expect(
        gate.requests.length,
        requests,
        reason: 'Expiry changes presentation, not server state or payment',
      );
      expect(work.workspaceInvoices, isEmpty);
      expect(tester.takeException(), isNull);
      await captureStoreView(tester, 'collection-orders-expired-approval');
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('Store collection unavailable is not ready or matched', (
    tester,
  ) async {
    final gate = _CollectionFixtureGateway()
      ..respond = (_) async => throw StateError('private transport detail');
    final work = collectionStore(gate);
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    await tester.pumpAndSettle();
    expect(find.text('Checking order…'), findsOneWidget);
    expect(find.text('Ready for collection'), findsNothing);
    expect(find.textContaining('private transport detail'), findsNothing);
    expect(find.byKey(const Key('work-collection-qr')), findsNothing);
    expect(find.byKey(const Key('work-collection-hand-over')), findsNothing);
    expect(find.text('Try again'), findsOneWidget);
    gate.respond = null;
    await tester.ensureVisible(find.text('Try again'));
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(
      find.text('Unable to show the collection code. Do not hand over yet.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('work-collection-qr')), findsNothing);
    expect(work.currentCollection!.canHandOver, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('Store collection pending handover copy $scale', (
      tester,
    ) async {
      final gate = _CollectionFixtureGateway()..state = ScanPickState.matched;
      final work = collectionStore(gate);
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: scale == 1 ? const Size(412, 915) : const Size(320, 640),
        textScale: scale,
      );
      final pending = Completer<ScanPickResult>();
      ScanPickRequest? submitted;
      gate.respond = (request) {
        submitted = request;
        return pending.future;
      };
      final action = find.byKey(const Key('work-collection-hand-over'));
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      final retainedTap = tester.widget<FilledButton>(action).onPressed!;
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(find.text('Confirming collection…'), findsOneWidget);
      expect(find.text('Updating'), findsOneWidget);
      expect(find.text('Collected'), findsNothing);
      expect(
        find.text('Please wait for collection confirmation.'),
        findsOneWidget,
      );
      expect(tester.widget<FilledButton>(action).onPressed, isNull);
      retainedTap();
      expect(
        gate.requests.where((r) => r.operation == ScanPickOperation.handOver),
        hasLength(1),
      );
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      await captureStoreView(tester, 'collection-handover-pending-$scale');
      gate
        ..state = ScanPickState.collected
        ..respond = null;
      pending.complete(gate.reply(submitted!));
      await tester.pumpAndSettle();
      expect(find.text('Collected'), findsOneWidget);
      expect(find.text('Collection confirmed'), findsNothing);
      expect(work.workspaceInvoices, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
    'Store collection background disables action and resume refreshes',
    (tester) async {
      final gate = _CollectionFixtureGateway()..state = ScanPickState.matched;
      final work = collectionStore(gate);
      await mount(tester, route: '/app/work/workspace/dashboard', work: work);
      await tester.pumpAndSettle();
      final action = find.byKey(const Key('work-collection-hand-over'));
      expect(tester.widget<FilledButton>(action).onPressed, isNotNull);
      final retainedTap = tester.widget<FilledButton>(action).onPressed!;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      retainedTap();
      expect(
        gate.requests.where((r) => r.operation == ScanPickOperation.handOver),
        isEmpty,
      );
      final count = gate.requests.length;
      await tester.pump(const Duration(seconds: 6));
      expect(gate.requests, hasLength(count));
      gate.state = ScanPickState.collected;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Collected'), findsOneWidget);
      expect(action, findsNothing);
      expect(gate.requests.last.operation, ScanPickOperation.read);
      expect(
        gate.requests.where((r) => r.operation == ScanPickOperation.handOver),
        isEmpty,
      );
      expect(work.workspaceInvoices, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final scale in [1.0, 1.4, 2.0]) {
    testWidgets('Store collection exact 1000 crore plus paise $scale', (
      tester,
    ) async {
      final gate = _CollectionFixtureGateway()
        ..state = ScanPickState.matched
        ..totalMinor = 1000000000050;
      final work = collectionStore(gate);
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: const Size(320, 640),
        textScale: scale,
      );
      await tester.pumpAndSettle();
      final amount = find.byKey(const Key('work-collection-amount'));
      await tester.ensureVisible(amount);
      await tester.pumpAndSettle();
      final exact = find.descendant(
        of: amount,
        matching: find.byKey(const Key('work-order-exact-amount-open')),
      );
      if (exact.evaluate().isNotEmpty) {
        expect(
          find.descendant(of: amount, matching: find.text('≈₹1,000')),
          findsOneWidget,
        );
        await tester.tap(exact);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-order-exact-amount-dialog')),
          findsOneWidget,
        );
        expect(find.text('₹10,00,00,00,000.50'), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
      } else {
        expect(
          find.descendant(
            of: amount,
            matching: find.text('₹10,00,00,00,000.50'),
          ),
          findsOneWidget,
        );
      }
      expect(work.currentCollection!.snapshot!.totalMinor, 1000000000050);
      expect(work.currentWorkspaceOrderId, 'APP-1043');
      expect(work.workspaceInvoices, isEmpty);
      expect(
        gate.requests.where((r) => r.operation == ScanPickOperation.handOver),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(work.selectWorkspaceOrder('SALE-1042'), isTrue);
      expect(work.currentCollection, isNull);
    });
  }

  for (final display in [
    (width: 412.0, height: 915.0, scale: 1.0),
    (width: 320.0, height: 640.0, scale: 1.4),
    (width: 320.0, height: 640.0, scale: 2.0),
  ]) {
    final suffix = '${display.width.toInt()}-${display.scale}';
    testWidgets('S09 money live figures $suffix', (tester) async {
      final work = liveStore();
      final semantics = tester.ensureSemantics();
      try {
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: Size(display.width, display.height),
          textScale: display.scale,
        );
        final sales = find.byKey(const Key('work-pulse-sales'));
        final originalTop = tester.getTopLeft(sales).dy;
        final originalHeight = tester.getSize(sales).height;
        for (final value in [
          (0, '₹0', '₹0'),
          (999, '₹999', '₹999'),
          (99999, '₹99,999', '₹99,999'),
          (100000, '₹1 lakh', '₹1,00,000'),
          (9999999, '≈₹99.99 lakh', '₹99,99,999'),
          (10000000, '₹1 cr', '₹1,00,00,000'),
          (1000000000, '₹100 cr', '₹1,00,00,00,000'),
          (9990000000, '₹999 cr', '₹9,99,00,00,000'),
          (10000000000, '₹1,000 cr', '₹10,00,00,00,000'),
          (100000000000, '₹10,000 cr', '₹1,00,00,00,00,000'),
          (-10000000000, '₹-1,000 cr', '₹-10,00,00,00,000'),
          (10000000001, '≈₹1,000 cr', '₹10,00,00,00,001'),
        ]) {
          work.workspaceSalesToday = value.$1;
          work.setWorkspaceMoneyPeriod('Today');
          await tester.pumpAndSettle();
          final expectedDigits = RegExp(r'-?[\d,.]+').firstMatch(value.$2)!;
          final currency = value.$2.substring(0, expectedDigits.start);
          final unit = value.$2.substring(expectedDigits.end).trim();
          final separateUnit =
              '$currency${unit.isEmpty ? '' : ' $unit'}\n${expectedDigits.group(0)}';
          final amount = find.descendant(
            of: sales,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Text &&
                  (widget.data == value.$2 || widget.data == separateUnit),
            ),
          );
          expect(amount, findsOneWidget);
          final paragraph = tester.renderObject<RenderParagraph>(amount);
          expect(paragraph.didExceedMaxLines, isFalse, reason: value.$2);
          final digits = RegExp(
            r'-?[\d,.]+',
          ).firstMatch(tester.widget<Text>(amount).data!)!;
          expect(
            paragraph.getBoxesForSelection(
              TextSelection(baseOffset: digits.start, extentOffset: digits.end),
            ),
            hasLength(1),
            reason: 'The digits must stay together: ${value.$2}',
          );
          expect(
            tester.widget<Text>(amount).style!.fontSize,
            greaterThanOrEqualTo(14),
          );
          expect(
            paragraph.textScaler.scale(17),
            closeTo(17 * display.scale, .01),
          );
          expect(
            find.bySemanticsLabel(
              'View statement, Sales today, ${value.$3} in store records',
            ),
            findsOneWidget,
          );
          expect(tester.getTopLeft(sales).dy, closeTo(originalTop, .1));
          expect(
            tester.getSize(sales).height,
            closeTo(originalHeight, .1),
            reason: 'Live totals must not move the financial action area',
          );
          expect(work.workspaceSalesToday, value.$1);
          expect(tester.takeException(), isNull);
        }
        await captureStoreView(tester, 'r665-money-live-$suffix');
        expect(work.workspaceOrders, isEmpty);
        expect(work.workspaceSettlementRequested, 0);
      } finally {
        semantics.dispose();
      }
    });

    for (final destination in [
      ('work-pulse-sales', 'work-store-statement'),
      ('work-pulse-dues', 'work-store-dues'),
      ('work-pulse-settlement', 'work-money-destination'),
    ]) {
      testWidgets('S09 money destination ${destination.$2} $suffix', (
        tester,
      ) async {
        final work = storeViewFixture()
          ..workspaceSalesToday = 10000000000
          ..workspaceSettlementBalance = 10000000000
          ..workspaceOrderAmount = '10000000000';
        for (var index = 0; index < work.workspaceOrders.length; index++) {
          work.workspaceOrders[index] = work.workspaceOrders[index].copyWith(
            amount: 10000000000,
          );
        }
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: Size(display.width, display.height),
          textScale: display.scale,
        );
        expect(tester.takeException(), isNull);
        final action = find.byKey(Key(destination.$1));
        await reveal(tester, action);
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(find.byKey(Key(destination.$2)), findsOneWidget);
        final amounts = find.text('₹10,00,00,00,000');
        expect(amounts, findsWidgets);
        expectExactMoneyVisible(tester, amounts);
        for (final element in amounts.evaluate()) {
          final paragraph = element.renderObject! as RenderParagraph;
          expect(paragraph.didExceedMaxLines, isFalse);
          final boxes = paragraph.getBoxesForSelection(
            const TextSelection(baseOffset: 0, extentOffset: 15),
          );
          expect(
            boxes,
            hasLength(1),
            reason: 'Do not split the amount across lines',
          );
          expect(
            paragraph.textScaler.scale(14),
            closeTo(14 * display.scale, .01),
          );
        }
        if (destination.$2 != 'work-money-destination') {
          await reveal(tester, amounts.first);
        }
        await captureStoreView(tester, 'r665-money-${destination.$2}-$suffix');
        if (destination.$2 == 'work-money-destination') {
          final request = find.byKey(
            const Key('work-money-request-settlement'),
          );
          await reveal(tester, request);
          await tester.tap(request);
          await tester.pumpAndSettle();
          final field = find.byKey(const Key('work-settlement-request-amount'));
          await reveal(tester, field);
          final editable = find.descendant(
            of: field,
            matching: find.byType(EditableText),
          );
          expect(
            tester.widget<EditableText>(editable).controller.text,
            '10000000000',
          );
          await tester.enterText(field, '9999999999');
          await tester.pumpAndSettle();
          expect(
            tester.widget<EditableText>(editable).controller.text,
            '9999999999',
          );
          expect(find.text('₹9,99,99,99,999'), findsOneWidget);
          expectExactMoneyVisible(tester, find.text('₹9,99,99,99,999'));
          tester.view.viewInsets = const FakeViewPadding(bottom: 260);
          await tester.pumpAndSettle();
          final confirm = find.byKey(const Key('work-settlement-confirm'));
          await reveal(tester, confirm);
          expect(confirm.hitTestable(), findsOneWidget);
          expect(tester.getSize(confirm).height, greaterThanOrEqualTo(48));
          await captureStoreView(tester, 'r665-money-payout-keyboard-$suffix');
          tester.testTextInput.hide();
          tester.view.viewInsets = FakeViewPadding.zero;
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('work-money-destination')),
            findsOneWidget,
          );
          await reveal(tester, find.text('Recorded sales'));
          final sale = find.text('APP-1043');
          await reveal(tester, sale);
          expectExactMoneyVisible(tester, find.text('₹10,00,00,00,000'));
          await captureStoreView(tester, 'r665-money-recorded-sales-$suffix');
        }
        expect(
          work.workspaceOrders.map((order) => order.amount),
          everyElement(10000000000),
        );
        expect(work.workspaceSettlementEligible, 10000000000);
        expect(work.workspaceSettlementRequested, 0);
        expect(tester.takeException(), isNull);
      });
    }

    for (final surface in ['invoice', 'group', 'credit']) {
      testWidgets('S09 money $surface details $suffix', (tester) async {
        final work = liveStore();
        if (surface == 'invoice') {
          work.workspaceInvoices.add(
            WorkspaceCustomerInvoice(
              id: 'INV-RANGE',
              orderId: 'ORDER-RANGE',
              customer: 'Customer',
              items: 'Goods supplied',
              amount: 10000000000,
              payment: 'Payment due',
              issuedAt: DateTime.now(),
            ),
          );
        } else if (surface == 'group') {
          work.activeGroupBuy = const WorkspaceGroupBuy(
            id: 'GROUP-RANGE',
            productName: 'Onions',
            specification: 'Fresh onions per kg',
            leadRetailer: 'Test store',
            confirmedRetailers: ['Test store'],
            targetQuantity: 1000000000,
            securedQuantity: 1000000000,
            unitLabel: 'kg',
            regularUnitPrice: 20,
            groupUnitPrice: 10,
            facilitationFee: 0,
            deliveryFee: 0,
            confirmationAmount: 0,
            closingLabel: 'Tomorrow',
            storeDeliveryLabel: 'After confirmation',
            paymentConfirmed: false,
          );
        } else {
          work.workspaceSettlementBalance = 10000000000;
          work.workspaceRefunds = -1000000000;
        }
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: Size(display.width, display.height),
          textScale: display.scale,
        );
        final action = find.byKey(
          Key(switch (surface) {
            'invoice' => 'work-invoice-open',
            'group' => 'work-quick-group-buy',
            _ => 'work-pulse-settlement',
          }),
        );
        await reveal(tester, action);
        await tester.tap(action);
        await tester.pumpAndSettle();
        final amount = find.text(
          surface == 'credit' ? '+ ₹1,00,00,00,000' : '₹10,00,00,00,000',
        );
        for (
          var scroll = 0;
          scroll < 30 && amount.evaluate().isEmpty;
          scroll++
        ) {
          final vertical = find.byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          );
          await tester.drag(vertical.last, const Offset(0, -160));
          await tester.pumpAndSettle();
        }
        expect(amount, findsWidgets);
        await reveal(tester, amount.first);
        expectExactMoneyVisible(tester, amount);
        final paragraph = tester.renderObject<RenderParagraph>(amount.first);
        expect(paragraph.didExceedMaxLines, isFalse);
        final value = tester.widget<Text>(amount.first).data!;
        final number = RegExp(r'[\d,]+').firstMatch(value)!;
        expect(
          paragraph.getBoxesForSelection(
            TextSelection(baseOffset: number.start, extentOffset: number.end),
          ),
          hasLength(1),
        );
        await captureStoreView(tester, 'r665-money-$surface-$suffix');
        expect(work.workspaceSettlementRequested, 0);
        if (surface == 'invoice') {
          expect(work.workspaceInvoices.single.amount, 10000000000);
          expect(work.workspaceInvoices.single.sharedChannels, isEmpty);
        } else if (surface == 'group') {
          expect(work.activeGroupBuy!.goodsValue, 10000000000);
          expect(work.activeGroupBuy!.balanceDue, 10000000000);
          expect(work.activeGroupBuy!.paymentConfirmed, isFalse);
        } else {
          expect(work.workspaceSettlementEligible, 11000000000);
          expect(work.workspaceRefunds, -1000000000);
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('S09 money counter bill $suffix', (tester) async {
      final work = liveStore();
      final product = work.workspaceCatalogueItems.first.copyWith(
        sellingPrice: 1000000000,
        mrp: 1000000000,
        purchasePrice: 900000000,
        stock: 20,
      );
      work.workspaceCatalogueItems[0] = product;
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: Size(display.width, display.height),
        textScale: display.scale,
      );
      await tester.tap(find.byKey(const Key('work-store-sell')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('work-sale-customer')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('work-order-customer')),
        '9829012345',
      );
      await tester.tap(find.byKey(const Key('work-sale-customer-confirm')));
      await tester.pumpAndSettle();
      final add = find.byKey(Key('work-order-add-${product.id}'));
      for (var count = 0; count < 10; count++) {
        await reveal(tester, add);
        await tester.tap(add);
        await tester.pumpAndSettle();
      }
      expect(work.workspaceOrderTotal, 10000000000);
      final total = find.descendant(
        of: find.byKey(const Key('work-sale-total-bar')),
        matching: find.text('₹10,00,00,00,000'),
      );
      expect(total, findsOneWidget);
      expectExactMoneyVisible(tester, total);
      final quantity = find.descendant(
        of: find.byKey(const Key('work-sale-product-oil-fortune-1l')),
        matching: find.text('10'),
      );
      expect(quantity, findsOneWidget);
      expect(
        tester
            .renderObject<RenderParagraph>(quantity)
            .getBoxesForSelection(
              const TextSelection(baseOffset: 0, extentOffset: 2),
            ),
        hasLength(1),
      );
      expect(
        tester.renderObject<RenderParagraph>(total).didExceedMaxLines,
        isFalse,
      );
      await captureStoreView(tester, 'r665-money-counter-total-$suffix');
      final review = find.byKey(const Key('work-order-review'));
      await reveal(tester, review);
      await tester.tap(review);
      await tester.pumpAndSettle();
      final summary = find.byKey(const Key('work-order-review-summary'));
      final reviewAmount = find.descendant(
        of: summary,
        matching: find.text('₹10,00,00,00,000'),
      );
      await reveal(tester, reviewAmount);
      expectExactMoneyVisible(tester, reviewAmount);
      expect(
        tester.renderObject<RenderParagraph>(reviewAmount).didExceedMaxLines,
        isFalse,
      );
      await captureStoreView(tester, 'r665-money-counter-review-$suffix');
      expect(work.workspaceOrderTotal, 10000000000);
      expect(work.workspaceCatalogueItems.first.stock, 20);
      expect(work.workspaceOrders, isEmpty);
      expect(work.workspaceInvoices, isEmpty);
      expect(tester.takeException(), isNull);
    });

    for (final hasOrder in [false, true]) {
      testWidgets('S09 rail word fit $hasOrder $suffix', (tester) async {
        final work = hasOrder ? storeViewFixture() : liveStore();
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: Size(display.width, display.height),
          textScale: display.scale,
        );
        await captureStoreView(tester, 'r665-rail-root-$hasOrder-$suffix');
        Future<void> checkWords(Finder text, String value) async {
          await reveal(tester, text);
          final paragraph = tester.renderObject<RenderParagraph>(text);
          expect(paragraph.textScaler.scale(1), closeTo(display.scale, .01));
          expect(paragraph.didExceedMaxLines, isFalse);
          for (final word in RegExp(r'\S+').allMatches(value)) {
            final boxes = paragraph.getBoxesForSelection(
              TextSelection(baseOffset: word.start, extentOffset: word.end),
            );
            expect(
              boxes,
              hasLength(1),
              reason: '$value: ${word.group(0)} splits',
            );
            expect(
              boxes.single.right,
              lessThanOrEqualTo(paragraph.size.width + .5),
            );
          }
        }

        if (hasOrder) {
          final centre = find.byKey(const Key('work-activity-incoming-order'));
          for (final value in [
            'Rakesh',
            'Customer pickup',
            'Awaiting acceptance',
            'View details',
            'Accept',
            'Reject',
          ]) {
            await checkWords(
              find.descendant(of: centre, matching: find.text(value)),
              value,
            );
          }
          final clock = find.descendant(
            of: centre,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Text &&
                  RegExp(r'^\d{2}:\d{2}$').hasMatch(widget.data ?? ''),
            ),
          );
          expect(clock, findsOneWidget);
          await checkWords(clock, tester.widget<Text>(clock).data!);
          await captureStoreView(tester, 'r665-rail-order-controls-$suffix');
        } else {
          await checkWords(find.text('Ready for orders'), 'Ready for orders');
        }
        final labels = [
          ('work-pulse-sales', 'View statement'),
          ('work-pulse-dues', 'Collect dues'),
          ('work-pulse-settlement', 'Settle'),
          ('work-quick-buy', 'Restock'),
          ('work-incoming-purchases', 'Track stock'),
          ('work-quick-group-buy', 'Group Bulk Buying'),
          ('work-quick-store-link', 'Send store link'),
          ('work-quick-promote', 'Promote store'),
          ('work-quick-requirement', 'Post requirement'),
        ];
        for (final entry in labels) {
          final action = find.byKey(Key(entry.$1));
          await reveal(tester, action);
          expect(action.hitTestable(), findsOneWidget);
          expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
          expect(tester.getSize(action).width, greaterThanOrEqualTo(48));
          final text = find.descendant(
            of: action,
            matching: find.text(entry.$2),
          );
          final paragraph = tester.renderObject<RenderParagraph>(text);
          expect(
            paragraph.textScaler.scale(11),
            closeTo(11 * display.scale, .01),
          );
          for (final word in RegExp(r'\S+').allMatches(entry.$2)) {
            final boxes = paragraph.getBoxesForSelection(
              TextSelection(baseOffset: word.start, extentOffset: word.end),
            );
            expect(
              boxes,
              hasLength(1),
              reason: '${entry.$2}: ${word.group(0)} splits',
            );
            expect(boxes.single.left, greaterThanOrEqualTo(-.5));
            expect(
              boxes.single.right,
              lessThanOrEqualTo(paragraph.size.width + .5),
            );
          }
        }
        await captureStoreView(tester, 'r665-rail-reach-$hasOrder-$suffix');
        await tester.tap(find.byKey(const Key('work-quick-requirement')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-requirement-selector')),
          findsOneWidget,
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('work-store-action-edge')), findsOneWidget);
        expect(work.workspaceVisibleToCustomers, isTrue);
        expect(work.workspaceAcceptingOrders, isTrue);
        expect(work.workspaceOrders.length, hasOrder ? 2 : 0);
        expect(tester.takeException(), isNull);
      });
    }
    for (final state in [
      (products: false, delivery: false, complete: 0),
      (products: true, delivery: false, complete: 1),
      (products: false, delivery: true, complete: 1),
      (products: true, delivery: true, complete: 2),
    ]) {
      testWidgets(
        'S09 direct setup exact progress ${state.products}-${state.delivery} $suffix',
        (tester) async {
          final work = WorkSession()..seedVerifiedWorkspace();
          if (!state.products) work.workspaceCatalogueItems.clear();
          work.retailerHomeDelivery = state.delivery;
          final semantics = tester.ensureSemantics();
          try {
            await mount(
              tester,
              route: '/app/work/workspace/dashboard',
              work: work,
              viewport: Size(display.width, display.height),
              textScale: display.scale,
            );
            final progress = find.byKey(const Key('work-setup-progress'));
            final indicator = tester.widget<LinearProgressIndicator>(progress);
            expect(indicator.value, state.complete / 2);
            expect(
              indicator.semanticsLabel,
              'Store setup, ${state.complete} of 2 steps complete',
            );
            expect(indicator.semanticsValue, isNull);
            final node = tester.getSemantics(progress);
            expect(
              node.label,
              'Store setup, ${state.complete} of 2 steps complete',
            );
            expect(node.value, '${state.complete * 50}');
            final products = find.byKey(
              const Key('work-setup-products-direct'),
            );
            await reveal(tester, products);
            expect(tester.getSize(products).height, greaterThanOrEqualTo(48));
            expect(
              find.descendant(
                of: products,
                matching: find.text(
                  state.products ? 'View products' : 'Add products',
                ),
              ),
              findsOneWidget,
            );
            if (!state.products && !state.delivery) {
              await captureStoreView(tester, 'r665-direct-setup-$suffix');
            }
            final original = List<WorkspaceCatalogueItem>.of(
              work.workspaceCatalogueItems,
            );
            await tester.tap(products);
            await tester.pumpAndSettle();
            expect(
              find.byKey(const Key('work-dashboard-catalogue-screen')),
              findsOneWidget,
            );
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            expect(
              find.byKey(const Key('work-activity-setup')),
              findsOneWidget,
            );
            expect(work.workspaceCatalogueItems, orderedEquals(original));
            expect(work.retailerSetupSaved, isFalse);
            expect(work.workspaceVisibleToCustomers, isFalse);
            expect(work.workspaceAcceptingOrders, isFalse);
            expect(work.reviewStage, WorkReviewStage.approved);
            expect(tester.takeException(), isNull);
          } finally {
            semantics.dispose();
          }
        },
      );
    }
    testWidgets('S09 direct setup delivery choices stay local $suffix', (
      tester,
    ) async {
      final work = WorkSession()
        ..seedVerifiedWorkspace()
        ..workspaceCatalogueItems.clear();
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: Size(display.width, display.height),
        textScale: display.scale,
      );
      final action = find.byKey(const Key('work-setup-delivery-direct'));
      await reveal(tester, action);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(work.retailerStoreCollection, isFalse);
      expect(work.retailerHomeDelivery, isFalse);
      final pickup = find.byKey(const Key('work-setup-pickup-choice'));
      await reveal(tester, pickup);
      expect(pickup.hitTestable(), findsOneWidget);
      await captureStoreView(tester, 'r665-direct-setup-choices-$suffix');
      await tester.tap(pickup);
      await tester.pumpAndSettle();
      expect(work.retailerStoreCollection, isTrue);
      expect(work.retailerHomeDelivery, isFalse);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byKey(const Key('work-setup-progress')),
            )
            .value,
        .5,
      );
      await reveal(tester, action);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(pickup, findsNothing);
      expect(work.retailerStoreCollection, isTrue);
      final next = find.byKey(const Key('work-dashboard-priority-action'));
      await reveal(tester, next);
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('retailer-setup-screen')), findsOneWidget);
      expect(work.retailerStoreCollection, isTrue);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-activity-setup')), findsOneWidget);
      expect(work.retailerSetupSaved, isFalse);
      expect(work.workspaceCatalogueItems, isEmpty);
      expect(work.workspaceVisibleToCustomers, isFalse);
      expect(work.workspaceAcceptingOrders, isFalse);
      expect(tester.takeException(), isNull);
    });
    Future<void> tapRefinementAction(WidgetTester tester, String key) async {
      final action = find.byKey(Key(key));
      if (display.scale > 1.4) await reveal(tester, action);
      await tester.tap(action);
      await tester.pumpAndSettle();
    }

    testWidgets('S09 refinement finance context $suffix', (tester) async {
      final work = storeViewFixture();
      final semantics = tester.ensureSemantics();
      try {
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: Size(display.width, display.height),
          textScale: display.scale,
        );
        for (final metric in [
          ('work-pulse-sales', 'Sales today', '₹28,450'),
          ('work-pulse-dues', 'Unpaid bills', '₹860'),
          ('work-pulse-settlement', 'Available', '₹17,820'),
        ]) {
          final target = find.byKey(Key(metric.$1));
          expect(target.hitTestable(), findsOneWidget);
          expect(
            find.descendant(of: target, matching: find.text(metric.$2)),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: target,
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Text &&
                    (widget.data == metric.$3 ||
                        widget.data == metric.$3.replaceFirst('₹', '₹\n')),
              ),
            ),
            findsOneWidget,
          );
          expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
        }
        expect(
          find.bySemanticsLabel(
            'View statement, Sales today, ₹28,450 in store records',
          ),
          findsOneWidget,
        );
        await captureStoreView(tester, 'r665-refinement-finance-$suffix');
        await tester.tap(find.byKey(const Key('work-pulse-sales')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('work-store-statement')), findsOneWidget);
        expect(work.workspaceSalesToday, 28450);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('S09 refinement empty Sell has one recovery $suffix', (
      tester,
    ) async {
      final work = liveStore()..workspaceCatalogueItems.clear();
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: Size(display.width, display.height),
        textScale: display.scale,
      );
      await tester.tap(find.byKey(const Key('work-store-sell')));
      await tester.pumpAndSettle();
      expect(find.text('Add products').hitTestable(), findsOneWidget);
      final review = find.byKey(const Key('work-order-review'));
      expect(review.hitTestable(), findsOneWidget);
      expect(tester.widget<FilledButton>(review).onPressed, isNull);
      expect(
        find.descendant(of: review, matching: find.text('Review bill')),
        findsOneWidget,
      );
      await captureStoreView(tester, 'r665-refinement-sell-$suffix');
      await tester.tap(find.text('Add products'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-dashboard-catalogue-screen')),
        findsOneWidget,
      );
      expect(work.workspaceCatalogueItems, isEmpty);
      expect(tester.takeException(), isNull);
    });

    for (final setup in [false, true]) {
      testWidgets('S09 refinement store link recovery $setup $suffix', (
        tester,
      ) async {
        final work = liveStore()
          ..retailerSetupSaved = setup
          ..workspaceVisibleToCustomers = false
          ..workspaceAcceptingOrders = false
          ..workspaceCatalogueItems.clear();
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: Size(display.width, display.height),
          textScale: display.scale,
        );
        await tapRefinementAction(tester, 'work-quick-store-link');
        final recovery = find.byKey(const Key('work-store-link-recovery'));
        expect(recovery.hitTestable(), findsOneWidget);
        expect(
          find.text(setup ? 'View products' : 'Set up store'),
          findsOneWidget,
        );
        expect(find.text('Store link unavailable'), findsOneWidget);
        expect(
          tester
              .getSize(find.byKey(const Key('work-store-link-unavailable')))
              .height,
          lessThan(display.height * .55),
        );
        await captureStoreView(tester, 'r665-refinement-link-$setup-$suffix');
        await tester.tap(recovery);
        await tester.pumpAndSettle();
        expect(
          find.byKey(
            Key(
              setup
                  ? 'work-dashboard-catalogue-screen'
                  : 'retailer-setup-screen',
            ),
          ),
          findsOneWidget,
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('work-store-link')), findsOneWidget);
        expect(work.workspaceVisibleToCustomers, isFalse);
        expect(work.workspaceAcceptingOrders, isFalse);
        expect(work.workspaceCatalogueItems, isEmpty);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('S09 refinement empty Stock exposes products $suffix', (
      tester,
    ) async {
      final work = liveStore()..workspaceCatalogueItems.clear();
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: Size(display.width, display.height),
        textScale: display.scale,
      );
      await tester.tap(find.byKey(const Key('work-store-stock')));
      await tester.pumpAndSettle();
      expect(find.text('Low stock'), findsNothing);
      expect(
        find.byKey(const Key('work-catalogue-add')).hitTestable(),
        findsOneWidget,
      );
      final product = find.byKey(
        Key('work-catalogue-master-${workspaceMasterCatalogue.first.id}'),
      );
      final heading = find.byKey(const Key('work-catalogue-heading'));
      expect(
        tester
            .renderObject<RenderParagraph>(heading)
            .getBoxesForSelection(
              const TextSelection(baseOffset: 0, extentOffset: 8),
            )
            .length,
        1,
      );
      if (display.scale > 1.4) await reveal(tester, product);
      expect(product.hitTestable(), findsOneWidget);
      await captureStoreView(tester, 'r665-refinement-stock-$suffix');
      await tester.tap(product);
      await tester.pumpAndSettle();
      expect(work.workspaceCatalogueItems, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-dashboard-catalogue-screen')),
        findsOneWidget,
      );
    });

    testWidgets(
      'S09 refinement promotion shows prerequisites and fixed action $suffix',
      (tester) async {
        final work = liveStore()..workspaceCatalogueItems.clear();
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: Size(display.width, display.height),
          textScale: display.scale,
        );
        await tapRefinementAction(tester, 'work-quick-promote');
        expect(
          find.byKey(const Key('work-offer-prerequisites')).hitTestable(),
          findsOneWidget,
        );
        final publish = find.byKey(const Key('work-offer-publish'));
        expect(publish.hitTestable(), findsOneWidget);
        expect(tester.widget<FilledButton>(publish).onPressed, isNull);
        final actionPosition = tester.getRect(publish);
        await captureStoreView(tester, 'r665-refinement-promote-$suffix');
        await tester.drag(
          find.byKey(const Key('work-store-offers-screen')),
          const Offset(0, -260),
        );
        await tester.pumpAndSettle();
        expect(tester.getRect(publish), actionPosition);
        expect(work.workspaceOffers, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final display in [
    (412.0, 915.0, 1.0),
    (360.0, 800.0, 1.0),
    (320.0, 568.0, 1.4),
    (320.0, 568.0, 2.0),
  ]) {
    testWidgets('S09 DF04 compact first-tap access $display', (tester) async {
      final work = liveStore();
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: Size(display.$1, display.$2),
        textScale: display.$3,
        bottomInset: 24,
      );
      expect(find.byKey(const Key('work-first-tap-shortcuts')), findsNothing);
      final statement = find.byKey(const Key('work-pulse-sales'));
      await reveal(tester, statement);
      await tester.tap(statement);
      await tester.pumpAndSettle();
      final rail = find.byKey(const Key('work-first-tap-shortcuts'));
      expect(rail.hitTestable(), findsOneWidget);
      expect(tester.getSize(rail).height, lessThanOrEqualTo(60));
      expect(find.byKey(const Key('work-store-statement')), findsOneWidget);
      final selected = find.byKey(const Key('work-shortcut-statement'));
      expect(tester.widget<TextButton>(selected).onPressed, isNull);
      final semantics = tester.ensureSemantics();
      try {
        expect(
          tester.getSemantics(
            find.byKey(const Key('work-shortcut-state-statement')),
          ),
          matchesSemantics(
            label: 'View statement',
            isButton: true,
            hasEnabledState: true,
            isEnabled: false,
            hasSelectedState: true,
            isSelected: true,
          ),
        );
      } finally {
        semantics.dispose();
      }
      await captureStoreView(
        tester,
        'r665-df04-statement-${display.$1}-${display.$3}',
      );
      for (final action in [
        ('dues', 'Collect dues', 'work-store-dues'),
        ('payments', 'Settle', 'work-money-destination'),
        ('sourcing', 'Track stock', 'work-store-track-stock'),
        ('storeLink', 'Send store link', 'work-store-link'),
        ('offers', 'Promote store', 'work-store-offers-screen'),
      ]) {
        final target = find.byKey(Key('work-shortcut-${action.$1}'));
        await reveal(tester, target);
        expect(target.hitTestable(), findsOneWidget);
        expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
        final text = find.descendant(
          of: target,
          matching: find.text(action.$2),
        );
        final paragraph = tester.renderObject<RenderParagraph>(text);
        expect(paragraph.textScaler.scale(1), closeTo(display.$3, .01));
        expect((paragraph.text as TextSpan).style!.fontFamily, isNot('Ahem'));
        expect((paragraph.text as TextSpan).style!.fontFamily, isNotNull);
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(
          paragraph.getBoxesForSelection(
            TextSelection(baseOffset: 0, extentOffset: action.$2.length),
          ),
          hasLength(1),
        );
        await tester.tap(target);
        await tester.pumpAndSettle();
        expect(find.byKey(Key(action.$3)), findsOneWidget);
        expect(tester.widget<TextButton>(target).onPressed, isNull);
        expect(tester.takeException(), isNull);
      }
      await captureStoreView(
        tester,
        'r665-df04-promote-${display.$1}-${display.$3}',
      );
      final post = find.byKey(const Key('work-shortcut-paidWork'));
      await reveal(tester, post);
      await tester.tap(post);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-requirement-selector')),
        findsOneWidget,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-store-offers-screen')), findsOneWidget);
      expect(work.workspaceOffers, isEmpty);
      expect(work.workspaceInvoices, isEmpty);
      expect(work.workspaceOrders, isEmpty);
      expect(work.workspaceAcceptingOrders, isTrue);
      expect(work.workspaceVisibleToCustomers, isTrue);
      await tester.tap(find.byKey(const Key('work-store-home')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-first-tap-shortcuts')), findsNothing);
      expect(find.byKey(const Key('work-store-action-edge')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('S09 DF04 live updates do not move shortcuts or selected order', (
    tester,
  ) async {
    final work = storeViewFixture();
    await mount(
      tester,
      route: '/app/work/workspace/dashboard',
      work: work,
      textScale: 1,
    );
    await tester.tap(find.byKey(const Key('work-store-orders')));
    await tester.pumpAndSettle();
    final group = find.byKey(const Key('work-shortcut-groupBuying'));
    await reveal(tester, group);
    final position = tester.getRect(group);
    final order = work.currentWorkspaceOrderId;
    work.workspaceSalesToday += 100;
    work.dismissMessages();
    await tester.pumpAndSettle();
    expect(tester.getRect(group), position);
    expect(work.currentWorkspaceOrderId, order);
    await tester.tap(group);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('work-group-buy-active-screen')),
      findsOneWidget,
    );
    expect(work.currentWorkspaceOrderId, order);
    expect(tester.takeException(), isNull);
  });

  testWidgets('S09 DF04 sale keyboard and discard protection stay intact', (
    tester,
  ) async {
    final work = liveStore();
    work.workspaceCatalogueItems
      ..clear()
      ..addAll(
        workspaceMasterCatalogue.map((product) => product.copyWith(stock: 24)),
      );
    await mount(
      tester,
      route: '/app/work/workspace/dashboard',
      work: work,
      textScale: 1,
    );
    await tester.tap(find.byKey(const Key('work-store-sell')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-sale-customer')));
    await tester.pumpAndSettle();
    final customer = find.byKey(const Key('work-order-customer'));
    await tester.enterText(customer, '9829012345');
    final editable = find.descendant(
      of: customer,
      matching: find.byType(EditableText),
    );
    final controller = tester.widget<EditableText>(editable).controller;
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-first-tap-shortcuts')), findsNothing);
    expect(
      identical(tester.widget<EditableText>(editable).controller, controller),
      isTrue,
    );
    expect(controller.text, '9829012345');
    await captureStoreView(tester, 'r665-df04-sale-keyboard');
    tester.view.viewInsets = FakeViewPadding.zero;
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-sale-customer-confirm')));
    await tester.pumpAndSettle();
    final statement = find.byKey(const Key('work-shortcut-statement'));
    await reveal(tester, statement);
    await tester.tap(statement);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-order-discard-dialog')), findsOneWidget);
    await tester.tap(find.byKey(const Key('work-order-keep-editing')));
    await tester.pumpAndSettle();
    expect(work.workspaceOrderCustomer, '9829012345');
    expect(
      find.byKey(const Key('work-dashboard-counter-order-screen')),
      findsOneWidget,
    );
    expect(work.workspaceOrders, isEmpty);
    expect(work.workspaceInvoices, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'S09 DF04 Restock retains filter and excludes transactional depths',
    (tester) async {
      final work = liveStore();
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        textScale: 1,
      );
      final buy = tester
          .widget<WorkWorkspaceDashboardScreen>(
            find.byType(WorkWorkspaceDashboardScreen),
          )
          .procurementSession;
      buy.chooseFilter('freight');
      await openTrackedPurchases(tester);
      await tester.pumpAndSettle();
      final restock = find.byKey(const Key('work-shortcut-restock'));
      await reveal(tester, restock);
      await tester.tap(restock);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-store-procurement-screen')),
        findsOneWidget,
      );
      expect(buy.selectedFilter, 'freight');
      expect(tester.widget<TextButton>(restock).onPressed, isNull);
      await captureStoreView(tester, 'r665-df04-restock');
      final product = buy.visibleProducts.first;
      expect(buy.addProduct(product.id), isTrue);
      final quantity = buy.quantityFor(product.id);
      buy.openCart();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-first-tap-shortcuts')), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-first-tap-shortcuts')), findsOneWidget);
      final statement = find.byKey(const Key('work-shortcut-statement'));
      await reveal(tester, statement);
      await tester.tap(statement);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-store-statement')), findsOneWidget);
      expect(buy.selectedFilter, 'freight');
      expect(buy.quantityFor(product.id), quantity);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-store-action-edge')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final display in [
    (412.0, 915.0, 1.0),
    (320.0, 568.0, 1.4),
    (320.0, 568.0, 2.0),
  ]) {
    for (final amount in <(int, String)>[
      (0, '₹0'),
      (264, '₹264'),
      (10000000, '₹1,00,00,000'),
      (1000000000, '₹1,00,00,00,000'),
      (9990000000, '₹9,99,00,00,000'),
      (10000000000, '₹10,00,00,00,000'),
      (100000000000, '₹1,00,00,00,00,000'),
    ]) {
      testWidgets('S09 catalogue exact price ${amount.$1} $display', (
        tester,
      ) async {
        final work = liveStore();
        final product = work.workspaceCatalogueItems.first.copyWith(
          sellingPrice: amount.$1,
          mrp: amount.$1,
          stock: 20,
        );
        work.workspaceCatalogueItems
          ..clear()
          ..add(product);
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: Size(display.$1, display.$2),
          textScale: display.$3,
        );
        await tester.tap(find.byKey(const Key('work-store-stock')));
        await tester.pumpAndSettle();
        final priceAction = find.byKey(
          Key('work-catalogue-price-${product.id}'),
        );
        await reveal(tester, priceAction);
        final exactPrice = find.descendant(
          of: priceAction,
          matching: find.text(amount.$2),
        );
        if (amount.$1 >= 10000000000 && display.$3 == 2) {
          final paragraph = tester.renderObject<RenderParagraph>(exactPrice);
          expect((paragraph.text as TextSpan).style!.fontSize, 14);
          await captureStoreView(tester, 'r665-catalogue-measure-${amount.$1}');
        }
        expectExactMoneyVisible(tester, exactPrice);
        if (display.$3 >= 1.4 || amount.$1 >= 10000000) {
          final mrp = find.byKey(Key('work-catalogue-mrp-${product.id}'));
          await reveal(tester, mrp);
          expectExactMoneyVisible(
            tester,
            find.descendant(of: mrp, matching: find.text(amount.$2)),
          );
        } else {
          final facts = find.text(
            '${product.pack} · MRP ${amount.$2} · ${product.sku}',
          );
          expect(facts, findsOneWidget);
          final paragraph = tester.renderObject<RenderParagraph>(facts);
          final content = tester.widget<Text>(facts).data!;
          final start = content.indexOf(amount.$2);
          final boxes = paragraph.getBoxesForSelection(
            TextSelection(
              baseOffset: start,
              extentOffset: start + amount.$2.length,
            ),
          );
          expect(boxes, hasLength(1));
          expect(
            boxes.single.right,
            lessThanOrEqualTo(paragraph.size.width + .5),
          );
        }
        if (amount.$1 == 10000000000) {
          await captureStoreView(
            tester,
            'r665-catalogue-amount-${display.$1}-${display.$3}',
          );
          await reveal(tester, priceAction);
          await tester.tap(priceAction);
          await tester.pumpAndSettle();
          final field = find.byKey(const Key('work-quick-price'));
          expect(
            find.descendant(of: field, matching: find.text('10000000000')),
            findsOneWidget,
          );
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('work-dashboard-catalogue-screen')),
            findsOneWidget,
          );
        }
        final unchanged = work.workspaceCatalogueItems.single;
        expect(unchanged.sellingPrice, amount.$1);
        expect(unchanged.mrp, amount.$1);
        expect(unchanged.stock, 20);
        expect(unchanged.publicListing, product.publicListing);
        final publicProduct = unchanged.toBuyPublicProduct(
          storeName: work.activeWorkspace!.name,
        );
        expect(publicProduct.price, amount.$1);
        expect(publicProduct.mrp, amount.$1);
        expect(publicProduct.pack, product.pack);
        expect(publicProduct.title, product.title);
        expect(work.workspaceOrders, isEmpty);
        expect(work.workspaceInvoices, isEmpty);
        expect(tester.takeException(), isNull);
      });
    }

    for (final isPublic in [true, false]) {
      testWidgets('S09 catalogue visibility label $isPublic $display', (
        tester,
      ) async {
        final work = liveStore();
        final product = work.workspaceCatalogueItems.first.copyWith(
          publicListing: isPublic,
        );
        work.workspaceCatalogueItems
          ..clear()
          ..add(product);
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: Size(display.$1, display.$2),
          textScale: display.$3,
        );
        await tester.tap(find.byKey(const Key('work-store-stock')));
        await tester.pumpAndSettle();
        final action = find.byKey(
          Key('work-catalogue-visibility-${product.id}'),
        );
        await reveal(tester, action);
        expect(action.hitTestable(), findsOneWidget);
        expect(tester.getSize(action).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
        final label = isPublic ? 'Public' : 'Private';
        final text = find.descendant(of: action, matching: find.text(label));
        final paragraph = tester.renderObject<RenderParagraph>(text);
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(paragraph.textScaler.scale(1), closeTo(display.$3, .01));
        final boxes = paragraph.getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: label.length),
        );
        expect(boxes, hasLength(1));
        expect(
          boxes.single.right,
          lessThanOrEqualTo(paragraph.size.width + .5),
        );
        await captureStoreView(
          tester,
          'r665-catalogue-visibility-$isPublic-${display.$1}-${display.$3}',
        );
        expect(work.workspaceCatalogueItems.single.publicListing, isPublic);
        expect(work.workspaceVisibleToCustomers, isTrue);
        expect(work.workspaceOrders, isEmpty);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('S09 catalogue suggestions keep complete identity $display', (
      tester,
    ) async {
      final work = liveStore()..workspaceCatalogueItems.clear();
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: Size(display.$1, display.$2),
        textScale: display.$3,
      );
      await tester.tap(find.byKey(const Key('work-store-stock')));
      await tester.pumpAndSettle();
      final product = workspaceMasterCatalogue.first;
      final card = find.byKey(Key('work-catalogue-master-${product.id}'));
      await reveal(tester, card);
      for (final label in [
        product.title,
        '${product.brand} · ${product.pack}',
        'Add this product',
      ]) {
        final text = find.descendant(of: card, matching: find.text(label));
        expect(text, findsOneWidget);
        final paragraph = tester.renderObject<RenderParagraph>(text);
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(paragraph.overflow, isNot(TextOverflow.ellipsis));
        expect(paragraph.textScaler.scale(1), closeTo(display.$3, .01));
      }
      await captureStoreView(
        tester,
        'r665-catalogue-suggestion-${display.$1}-${display.$3}',
      );
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-product-selling-price')),
        findsOneWidget,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-dashboard-catalogue-screen')),
        findsOneWidget,
      );
      expect(work.workspaceCatalogueItems, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  for (final filters in <(String?, String?)>[
    (null, null),
    ('freight', null),
    (null, 'nearby'),
    ('manufacturer', null),
  ]) {
    testWidgets(
      'R6617 Track stock leaves procurement filter unchanged ${filters.$1} ${filters.$2}',
      (tester) async {
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: liveStore(),
          textScale: 1,
        );
        final buy = tester
            .widget<WorkWorkspaceDashboardScreen>(
              find.byType(WorkWorkspaceDashboardScreen),
            )
            .procurementSession;
        buy.chooseFilter(filters.$1);
        await openTrackedPurchases(tester);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('work-store-track-stock')), findsOneWidget);
        expect(find.byKey(const Key('work-shortcut-direct')), findsNothing);
        expect(find.text('Buy Direct'), findsNothing);
        expect(buy.selectedFilter, filters.$1);
        if (filters.$2 != null) buy.chooseFilter(filters.$2);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-store-activity-deck')),
          findsOneWidget,
        );
        expect(buy.selectedFilter, filters.$2 ?? filters.$1);
        await tester.tap(find.byKey(const Key('work-quick-buy')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-store-procurement-screen')),
          findsOneWidget,
        );
        expect(buy.selectedFilter, filters.$2 ?? filters.$1);
        await captureStoreView(
          tester,
          'r665-restock-filter-${filters.$1}-${filters.$2}',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final origin in ['dashboard', 'stock', 'sourcing']) {
    testWidgets('S09 scanner cancel restores $origin', (tester) async {
      const channel = MethodChannel('flutter.baseflow.com/permissions/methods');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'requestPermissions') {
          return <int, int>{
            for (final id in call.arguments as List) id as int: 0,
          };
        }
        return 0;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      final work = liveStore();
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        textScale: 1,
      );
      if (origin == 'stock') {
        await tester.tap(find.byKey(const Key('work-store-stock')));
      } else if (origin == 'sourcing') {
        await openTrackedPurchases(tester);
      }
      await tester.pumpAndSettle();
      final products = List<WorkspaceCatalogueItem>.of(
        work.workspaceCatalogueItems,
      );
      await tester.tap(find.byKey(const Key('work-dashboard-scan')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('buy-manual-code-panel')), findsOneWidget);
      await tester.tap(find.byKey(const Key('buy-cancel-product-code')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          Key(switch (origin) {
            'stock' => 'work-dashboard-catalogue-screen',
            'sourcing' => 'work-store-track-stock',
            _ => 'work-store-activity-deck',
          }),
        ),
        findsOneWidget,
      );
      expect(work.workspaceCatalogueItems, orderedEquals(products));
      if (origin == 'sourcing') {
        final buy = tester
            .widget<WorkWorkspaceDashboardScreen>(
              find.byType(WorkWorkspaceDashboardScreen),
            )
            .procurementSession;
        expect(buy.selectedFilter, isNull);
      }
      await captureStoreView(tester, 'r665-scanner-cancel-$origin');
      expect(tester.takeException(), isNull);
    });
  }

  for (final destination in ['store', 'orders', 'sell', 'stock']) {
    testWidgets(
      'S09 setup navigation to $destination does not create or publish products',
      (tester) async {
        final work = liveStore()..workspaceCatalogueItems.clear();
        await mount(
          tester,
          route: '/app/work/retailer/setup',
          work: work,
          textScale: 1,
        );
        await tester.enterText(
          find.byKey(const Key('retailer-product-quantity')),
          '7',
        );
        await tester.enterText(
          find.byKey(const Key('retailer-product-buy-price')),
          '40',
        );
        await tester.enterText(
          find.byKey(const Key('retailer-product-sell-price')),
          '50',
        );
        await tester.tap(find.byKey(Key('work-setup-$destination')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('retailer-setup-screen')), findsNothing);
        expect(work.workspaceCatalogueItems, isEmpty);
        expect(work.retailerQuantity, 7);
        expect(work.retailerBuyPrice, 40);
        expect(work.retailerSellPrice, 50);
        expect(work.retailerProductAdded, isFalse);
        await captureStoreView(tester, 'r665-setup-nav-$destination');
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final width in [320.0, 360.0]) {
    for (final decision in [
      'pending',
      'clarification',
      'rejected',
      'approved',
    ]) {
      testWidgets(
        'S07 S08 application $decision at $width stays truthful and compact',
        (tester) async {
          if (width == 320) {
            tester.platformDispatcher.accessibilityFeaturesTestValue =
                const FakeAccessibilityFeatures(disableAnimations: true);
            addTearDown(
              tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
            );
          }
          final gateway = ReviewWorkGateway(
            initialReviewStatus: WorkRemoteReviewStatus.pending,
          );
          final work = WorkSession(gateway: gateway)
            ..selectProfile('retailer-grocery')
            ..workName = 'Sharma Stores'
            ..workArea = 'Jaipur'
            ..primaryActivity = 'Groceries'
            ..authorizedPersonName = 'Asha Sharma'
            ..businessRelationship = 'Owner'
            ..primaryMobile = '9829012321'
            ..contactEmail = 'asha@example.com'
            ..primaryMobileVerified = true
            ..contactEmailVerified = true
            ..declarationAccepted = true;
          expect(await tester.runAsync(work.submitProfile), isTrue);
          final caseId = work.reviewCaseId;
          if (decision == 'clarification') {
            gateway.reviewResultReason =
                'Please resend the readable bank document.';
          } else if (decision == 'rejected') {
            gateway
              ..reviewResultStatus = WorkRemoteReviewStatus.rejected
              ..reviewResultReason =
                  'The submitted business name does not match the document.';
          } else if (decision == 'approved') {
            gateway.reviewResultStatus = WorkRemoteReviewStatus.approved;
          }
          // Unsent edits must never become the acknowledged application summary.
          work.workName = 'Unsent business name';
          await mount(
            tester,
            route: '/app/work/workspace/proof',
            work: work,
            viewport: Size(width, width == 320 ? 640 : 800),
            textScale: width == 320 ? 1.4 : 1,
          );
          await tester.pump(const Duration(milliseconds: 50));
          await tester.pumpAndSettle();
          if (decision == 'approved') {
            expect(
              find.byKey(const Key('work-approval-welcome')),
              findsOneWidget,
            );
            expect(
              find.byKey(const Key('work-inline-review-status')),
              findsNothing,
            );
            expect(work.activeWorkspace?.id, work.workspaceId);
            expect(work.activeWorkspace?.name, 'Sharma Stores');
            expect(work.workspaceAcceptingOrders, isFalse);
            expect(work.workspaceVisibleToCustomers, isFalse);
            expect(work.reviewCaseId, caseId);
            await captureStoreView(
              tester,
              'r665-application-$decision-${width.toInt()}',
            );
            if (width == 360) {
              await tester.tap(
                find.byKey(const Key('work-dashboard-priority-action')),
              );
              await tester.pumpAndSettle();
              expect(
                find.byKey(const Key('retailer-finish-setup')),
                findsOneWidget,
              );
              expect(
                find.byKey(const Key('work-approval-welcome')),
                findsNothing,
              );
            }
            await tester.pump(const Duration(seconds: 5));
            await tester.pumpAndSettle();
            expect(
              find.byKey(const Key('work-approval-welcome')),
              findsNothing,
            );
            expect(await tester.runAsync(work.checkReview), isTrue);
            expect(work.takeWorkspaceApprovalWelcome(), isFalse);
            GoRouter.of(
              tester.element(find.byType(Scaffold).first),
            ).go('/app/work/workspace/proof');
            await tester.pumpAndSettle();
            await tester.pump(const Duration(milliseconds: 50));
            await tester.pumpAndSettle();
            expect(
              find.byKey(const Key('work-inline-review-status')),
              findsNothing,
            );
            expect(
              find.byKey(const Key('work-approval-welcome')),
              findsNothing,
            );
            expect(work.reviewCaseId, caseId);
          } else {
            expect(find.text('Application status'), findsOneWidget);
            expect(find.text('Complete your Workspace'), findsNothing);
            expect(
              find.byKey(const Key('work-approval-welcome')),
              findsNothing,
            );
            expect(work.activeWorkspace, isNull);
            final title = decision == 'pending'
                ? 'Application received'
                : decision == 'rejected'
                ? 'Application not approved'
                : 'More information needed';
            expect(find.text(title), findsOneWidget);
            if (decision != 'pending') {
              expect(find.text(gateway.reviewResultReason!), findsOneWidget);
            }
            await captureStoreView(
              tester,
              'r665-application-$decision-${width.toInt()}',
            );
            await reveal(
              tester,
              find.byKey(const Key('work-submitted-summary')),
            );
            final summary = find.byKey(const Key('work-submitted-summary'));
            expect(
              find.descendant(
                of: summary,
                matching: find.text('Sharma Stores'),
              ),
              findsOneWidget,
            );
            expect(
              find.descendant(
                of: summary,
                matching: find.text('Unsent business name'),
              ),
              findsNothing,
            );
            expect(
              find.descendant(
                of: summary,
                matching: find.byIcon(Icons.edit_outlined),
              ),
              findsNothing,
            );
            await reveal(tester, find.text('0 attached'));
            expect(find.text('0 attached').hitTestable(), findsOneWidget);
            if (decision != 'clarification') {
              expect(
                find.byKey(const Key('work-inline-update-documents')),
                findsNothing,
              );
            }
            await tester.pump(const Duration(seconds: 31));
            await tester.pumpAndSettle();
            expect(work.activeWorkspace, isNull);
            expect(work.reviewCaseId, caseId);
            expect(
              find.byKey(const Key('work-inline-review-status')),
              findsOneWidget,
            );
            if (decision == 'pending') {
              gateway.failReview = true;
              expect(await tester.runAsync(work.checkReview), isFalse);
              await tester.pumpAndSettle();
              final retry = find.byKey(const Key('work-inline-review-check'));
              await tester.ensureVisible(retry);
              await tester.tap(retry);
              await tester.pumpAndSettle();
              expect(work.errorMessage, isNull);
              expect(work.remoteReviewStatus, WorkRemoteReviewStatus.pending);
              expect(work.submittedProfile?.name, 'Sharma Stores');
            }
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final channel in WorkContactChannel.values) {
    for (final display in [
      (size: Size(360, 806), scale: 1.0),
      (size: Size(320, 568), scale: 2.0),
    ]) {
      testWidgets(
        'Contact Continue reveals verification without reopening number input $channel ${display.scale}',
        (tester) async {
          final gateway = ReviewWorkGateway();
          final work = WorkSession(gateway: gateway)
            ..selectProfile('retailer-grocery')
            ..authorizedPersonName = 'QA Retailer'
            ..primaryMobile = '9829012321'
            ..contactEmail = 'asha@example.com'
            ..primaryMobileVerified = true
            ..contactEmailVerified = true;
          await mount(
            tester,
            route: '/app/work/workspace/contact',
            work: work,
            viewport: display.size,
            textScale: display.scale,
          );
          final key = switch (channel) {
            WorkContactChannel.primaryMobile => 'work-primary-contact',
            WorkContactChannel.email => 'work-contact-email',
            WorkContactChannel.alternateMobile => 'work-alternate-contact',
          };
          if (channel != WorkContactChannel.alternateMobile) {
            final change = find.byKey(Key('$key-change'));
            await reveal(tester, change);
            await tester.tap(change);
            await tester.pumpAndSettle();
          }
          final field = find.byKey(Key('$key-field'));
          await reveal(tester, field);
          await tester.enterText(field, '123');
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
          final next = find.byKey(const Key('work-contact-continue'));
          await tester.tap(next);
          await tester.pumpAndSettle();
          expect(tester.widget<TextField>(field).focusNode!.hasFocus, isTrue);
          await tester.enterText(
            field,
            channel == WorkContactChannel.email
                ? 'shop@example.com'
                : '9876543210',
          );
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
          await tester.tap(next);
          await tester.pumpAndSettle();
          expect(tester.widget<TextField>(field).focusNode!.hasFocus, isFalse);
          expect(tester.testTextInput.isVisible, isFalse);
          final send = find.byKey(Key('$key-send-otp'));
          expect(send.hitTestable(), findsOneWidget);
          expect(gateway.otpCalls, 0);
          expect(work.workspaceContactVerified(channel), isFalse);
          await captureStoreView(
            tester,
            'r666-contact-confirm-${channel.name}-${display.scale}',
          );
          await tester.tap(send);
          await tester.pumpAndSettle();
          expect(gateway.otpCalls, 1);
          final code = find.byKey(Key('$key-otp'));
          expect(tester.widget<TextField>(code).focusNode!.hasFocus, isTrue);
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
          await tester.tap(next);
          await tester.pumpAndSettle();
          expect(tester.widget<TextField>(code).focusNode!.hasFocus, isTrue);
          expect(tester.widget<TextField>(field).focusNode!.hasFocus, isFalse);
          expect(gateway.otpCalls, 1);
          expect(work.workspaceContactVerified(channel), isFalse);
          expect(find.byKey(const Key('work-details-continue')), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
    // Channel-specific regressions keep the actual signed-in phone separate
    // from a new contact that still needs its own OTP.
    for (final operation in ['send', 'verify']) {
      testWidgets('S03 contact leaving during $operation is safe $channel', (
        tester,
      ) async {
        final work = WorkSession()
          ..selectProfile('retailer-grocery')
          ..primaryMobile = '9876501234'
          ..contactEmail = 'asha@example.com'
          ..alternateMobile = '9876543210';
        final key = switch (channel) {
          WorkContactChannel.primaryMobile => 'work-primary-contact',
          WorkContactChannel.email => 'work-contact-email',
          WorkContactChannel.alternateMobile => 'work-alternate-contact',
        };
        await mount(tester, route: '/app/work/workspace/contact', work: work);
        final field = find.byKey(Key('$key-field'));
        await reveal(tester, field);
        await tester.enterText(
          field,
          channel == WorkContactChannel.email
              ? 'pending@example.com'
              : '9123456780',
        );
        await tester.pumpAndSettle();
        final send = find.byKey(Key('$key-send-otp'));
        await reveal(tester, send);
        expect(send.hitTestable(), findsOneWidget);
        if (operation == 'verify') {
          await tester.tap(send);
          await tester.pumpAndSettle();
          final code = find.byKey(Key('$key-otp'));
          await reveal(tester, code);
          await tester.enterText(code, '123456');
          await tester.pumpAndSettle();
          final confirm = find.byKey(Key('$key-confirm-otp'));
          await reveal(tester, confirm);
          expect(confirm.hitTestable(), findsOneWidget);
          await tester.tap(confirm);
        } else {
          await tester.tap(send);
        }
        expect(work.busy, isTrue);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 80));
        expect(work.busy, isFalse);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final display in [
    (width: 412.0, height: 915.0, scale: 1.0),
    (width: 320.0, height: 568.0, scale: 1.4),
    (width: 320.0, height: 568.0, scale: 2.0),
  ]) {
    testWidgets(
      'S05 document removal Undo stays local and safe ${display.scale}',
      (tester) async {
        final gateway = ReviewWorkGateway();
        final work = WorkSession(gateway: gateway)
          ..selectProfile('retailer-grocery')
          ..authorizedPersonName = 'Asha Sharma'
          ..primaryMobile = '9829012321'
          ..primaryMobileVerified = true
          ..contactEmail = 'asha@example.com'
          ..contactEmailVerified = true
          ..saveDetails(
            name: 'Sharma Stores',
            area: 'Jaipur',
            activity: 'Groceries',
          );
        final proof = work.selectedWorkspaceDocuments.first;
        expect(
          await tester.runAsync(
            () => work.addProof(proof.id, WorkProofSource.upload),
          ),
          isTrue,
        );
        final reference = work.addedProofs[proof.id];
        final file = work.pickedProofs[proof.id];
        work.recoveredDocumentStep = true;
        await mount(
          tester,
          route: '/app/work/workspace/proof',
          work: work,
          viewport: Size(display.width, display.height),
          textScale: display.scale,
        );
        final remove = find.byKey(Key('work-remove-proof-${proof.id}'));
        await reveal(tester, remove);
        expect(remove.hitTestable(), findsOneWidget);
        await tester.tap(remove);
        await tester.pumpAndSettle();
        expect(work.addedProofs.containsKey(proof.id), isFalse);
        expect(find.byKey(const Key('work-notice')), findsNothing);
        final undo = find.byKey(Key('work-undo-proof-${proof.id}'));
        await reveal(tester, undo);
        expect(undo.hitTestable(), findsOneWidget);
        expect(tester.getSize(undo).height, greaterThanOrEqualTo(48));
        expect(
          tester.getRect(undo).bottom,
          lessThanOrEqualTo(display.height - 44),
        );
        expect(find.text('Removed: ${file!.fileName}'), findsOneWidget);
        await captureStoreView(
          tester,
          'r665-document-removed-${display.scale}',
        );
        await tester.tap(undo);
        await tester.pumpAndSettle();
        expect(work.addedProofs[proof.id], reference);
        expect(work.pickedProofs[proof.id], same(file));
        expect(gateway.proofCalls, 1);
        expect(work.declarationAccepted, isFalse);
        expect(undo, findsNothing);
        await reveal(tester, find.byKey(Key('work-view-proof-${proof.id}')));
        await captureStoreView(
          tester,
          'r665-document-restored-${display.scale}',
        );
        await tester.tap(remove);
        await tester.pumpAndSettle();
        await reveal(tester, find.byKey(const Key('work-proof-review')));
        await tester.tap(find.byKey(const Key('work-proof-review')));
        await tester.pumpAndSettle();
        expect(work.addedProofs.containsKey(proof.id), isFalse);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await reveal(tester, undo);
        await tester.tap(undo);
        await tester.pumpAndSettle();
        expect(work.addedProofs[proof.id], reference);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final display in [
    (width: 412.0, height: 915.0, scale: 1.0),
    (width: 320.0, height: 568.0, scale: 1.4),
    (width: 320.0, height: 568.0, scale: 2.0),
  ]) {
    testWidgets(
      'S03 compact contact first view and full labels ${display.scale}',
      (tester) async {
        final work = WorkSession()
          ..selectProfile('retailer-grocery')
          ..authorizedPersonName = 'Asha Sharma'
          ..primaryMobile = '9829012321'
          ..primaryMobileVerified = true
          ..contactEmail = 'ashasharma.authorisedrepresentative@example.com'
          ..contactEmailVerified = true;
        await mount(
          tester,
          route: '/app/work/workspace/contact',
          work: work,
          viewport: Size(display.width, display.height),
          textScale: display.scale,
        );
        expect(find.text('How MoolSocial can reach you'), findsNothing);
        expect(find.byKey(const Key('work-contact-readiness')), findsNothing);
        await captureStoreView(
          tester,
          'r665-contact-compact-first-${display.scale}',
        );
        final editableName = find.descendant(
          of: find.byKey(const Key('work-person-name')),
          matching: find.byType(EditableText),
        );
        expect(editableName.hitTestable(), findsOneWidget);
        expect(
          tester.getRect(editableName).bottom,
          lessThanOrEqualTo(
            tester.getRect(find.byKey(const Key('work-contact-continue'))).top -
                12,
          ),
        );
        final hero = tester.getSize(
          find.byKey(const Key('workspace-account-setup-hero')),
        );
        expect(hero.height, lessThanOrEqualTo(display.scale == 2 ? 105 : 80));
        final email = find.byKey(const Key('work-contact-email-field'));
        await reveal(tester, email);
        final input = tester.widget<TextField>(email);
        expect(input.maxLines, isNull);
        expect(
          input.controller!.text,
          'ashasharma.authorisedrepresentative@example.com',
        );
        await captureStoreView(
          tester,
          'r665-contact-full-email-${display.scale}',
        );
        final backup = find.byKey(const Key('work-alternate-contact-field'));
        await reveal(tester, backup);
        expect(work.alternateOtpSent, isFalse);
        expect(
          find.byKey(const Key('work-alternate-contact-otp')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('work-alternate-contact-confirm-otp')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('work-alternate-contact-send-otp')),
          findsNothing,
        );
        if (display.scale > 1.2) {
          expect(find.text('Backup number · optional'), findsOneWidget);
          expect(
            tester
                .widget<Text>(
                  find.byKey(const Key('work-alternate-contact-label')),
                )
                .maxLines,
            isNull,
          );
        }
        await captureStoreView(tester, 'r665-contact-backup-${display.scale}');
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final display in [
    (width: 412.0, height: 915.0, scale: 1.0),
    (width: 320.0, height: 568.0, scale: 1.4),
    (width: 320.0, height: 568.0, scale: 2.0),
  ]) {
    testWidgets(
      'S03 draft cold restart restores real contact fields ${display.scale}',
      (tester) async {
        final store = _ContactDraftFixtureStore();
        final beforeRestart = WorkSession(contactDraftStore: store);
        await beforeRestart.recoverPendingProof(accountReady: true);
        beforeRestart.selectProfile('retailer-grocery');
        beforeRestart.savePersonName('Asha Store Owner');
        beforeRestart.editWorkspaceContact(
          WorkContactChannel.primaryMobile,
          '9829012321',
        );
        beforeRestart.editWorkspaceContact(WorkContactChannel.email, 'store@');
        beforeRestart.saveDetails(
          name: 'Sharma Stores',
          area: 'Jaipur',
          activity: 'Groceries',
        );
        await beforeRestart.flushContactDraft();
        beforeRestart.dispose();
        final restored = WorkSession(contactDraftStore: store);
        await mount(
          tester,
          route: '/app/work/workspace/contact',
          work: restored,
          viewport: Size(display.width, display.height),
          textScale: display.scale,
        );
        expect(restored.authorizedPersonName, 'Asha Store Owner');
        expect(restored.workName, 'Sharma Stores');
        expect(restored.primaryMobileVerified, isTrue);
        expect(restored.contactEmailVerified, isFalse);
        await captureStoreView(
          tester,
          'r665-contact-restored-first-${display.scale}',
        );
        final phone = find.byKey(const Key('work-primary-contact-field'));
        await reveal(tester, phone);
        expect(tester.widget<TextField>(phone).controller!.text, '9829012321');
        expect(tester.widget<TextField>(phone).readOnly, isTrue);
        final email = find.byKey(const Key('work-contact-email-field'));
        await reveal(tester, email);
        expect(tester.widget<TextField>(email).controller!.text, 'store@');
        expect(tester.widget<TextField>(email).readOnly, isFalse);
        await tester.enterText(email, '');
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(email).controller!.text, isEmpty);
        expect(restored.contactEmail, isEmpty);
        await captureStoreView(
          tester,
          'r665-contact-restored-edit-${display.scale}',
        );
        expect(tester.takeException(), isNull);
        await restored.flushContactDraft();
      },
    );
  }

  for (final display in [
    (width: 412.0, height: 915.0, scale: 1.0),
    (width: 320.0, height: 568.0, scale: 1.4),
    (width: 320.0, height: 568.0, scale: 2.0),
  ]) {
    for (final channel in WorkContactChannel.values) {
      testWidgets(
        'R669 contact edit reveals input and actions $channel ${display.scale}',
        (tester) async {
          final gateway = ReviewWorkGateway();
          final work = WorkSession(gateway: gateway)
            ..selectProfile('retailer-grocery')
            ..authorizedPersonName = 'Asha Sharma'
            ..primaryMobile = '9829012321'
            ..primaryMobileVerified = true
            ..contactEmail = 'asha@example.com'
            ..contactEmailVerified = true
            ..alternateMobile = '9876543210'
            ..alternateVerified = true;
          final key = switch (channel) {
            WorkContactChannel.primaryMobile => 'work-primary-contact',
            WorkContactChannel.email => 'work-contact-email',
            WorkContactChannel.alternateMobile => 'work-alternate-contact',
          };
          final original = work.workspaceContactValue(channel);
          await mount(
            tester,
            route: '/app/work/workspace/contact',
            work: work,
            viewport: Size(display.width, display.height),
            textScale: display.scale,
          );
          final change = find.byKey(Key('$key-change'));
          await reveal(tester, change);
          await tester.tap(change);
          await tester.pumpAndSettle();
          tester.view.viewInsets = const FakeViewPadding(bottom: 240);
          await tester.pumpAndSettle();
          final field = find.byKey(Key('$key-field'));
          final input = find.descendant(
            of: field,
            matching: find.byType(EditableText),
          );
          final cancel = find.byKey(Key('$key-cancel'));
          expect(input, findsOneWidget);
          expect(cancel.hitTestable(), findsOneWidget);
          expect(tester.getRect(input).top, greaterThanOrEqualTo(56));
          expect(
            tester.getRect(input).bottom,
            lessThanOrEqualTo(display.height - 240),
          );
          expect(
            tester.getRect(cancel).bottom,
            lessThanOrEqualTo(display.height - 240),
          );
          final value = channel == WorkContactChannel.email
              ? 'updated@example.com'
              : '9123456780';
          await tester.enterText(field, value);
          await tester.pumpAndSettle();
          final send = find.byKey(Key('$key-send-otp'));
          expect(cancel.hitTestable(), findsOneWidget);
          expect(send.hitTestable(), findsOneWidget);
          expect(
            tester.getRect(send).bottom,
            lessThanOrEqualTo(display.height - 240),
          );
          expect(tester.getRect(input).top, greaterThanOrEqualTo(56));
          expect(
            tester.getRect(input).bottom,
            lessThanOrEqualTo(display.height - 240),
          );
          expect(
            tester.widget<TextField>(field).controller!.selection.baseOffset,
            value.length,
          );
          expect(work.workspaceContactVerified(channel), isFalse);
          expect(gateway.otpCalls, 0);
          if (display.scale > 1) {
            final label = find.byKey(Key('$key-label'));
            expect(tester.getRect(label).top, greaterThanOrEqualTo(56));
          }
          await captureStoreView(
            tester,
            'r669-contact-edit-${channel.name}-${display.scale}',
          );
          await tester.tap(cancel);
          await tester.pumpAndSettle();
          expect(work.workspaceContactValue(channel), original);
          expect(work.workspaceContactVerified(channel), isTrue);
          expect(gateway.otpCalls, 0);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'S03 contact replacement Cancel keyboard and return $channel ${display.width} ${display.scale}',
        (tester) async {
          final work = WorkSession()
            ..selectFamily('products-trade')
            ..selectProfile('retailer-grocery')
            ..authorizedPersonName = 'Asha Sharma'
            ..primaryMobile = '9829012321'
            ..primaryMobileVerified = true
            ..contactEmail = 'asha@example.com'
            ..contactEmailVerified = true
            ..alternateMobile = '9876543210'
            ..alternateVerified = true;
          final key = switch (channel) {
            WorkContactChannel.primaryMobile => 'work-primary-contact',
            WorkContactChannel.email => 'work-contact-email',
            WorkContactChannel.alternateMobile => 'work-alternate-contact',
          };
          final original = work.workspaceContactValue(channel);
          final replacement = channel == WorkContactChannel.email
              ? 'new.contact@example.com'
              : '9123456780';
          await mount(
            tester,
            route: '/app/work/workspace/contact',
            work: work,
            viewport: Size(display.width, display.height),
            textScale: display.scale,
          );
          Future<void> tap(String suffix) async {
            final action = find.byKey(Key('$key-$suffix'));
            await reveal(tester, action);
            expect(action.hitTestable(), findsOneWidget);
            await tester.tap(action);
            await tester.pumpAndSettle();
          }

          await tap('change');
          tester.view.viewInsets = const FakeViewPadding(bottom: 240);
          await tester.pumpAndSettle();
          final field = find.byKey(Key('$key-field'));
          Future<void> revealContactField() async {
            for (var step = 0; step < 12 && field.evaluate().isEmpty; step++) {
              await tester.drag(
                find.byKey(const Key('work-contact-screen')),
                const Offset(0, 240),
              );
              await tester.pumpAndSettle();
            }
            await reveal(tester, field);
          }

          await revealContactField();
          expect(tester.widget<TextField>(field).controller!.text, original);
          expect(tester.widget<TextField>(field).readOnly, isFalse);
          expect(tester.widget<TextField>(field).focusNode!.hasFocus, isTrue);
          expect(work.workspaceContactsReady, isTrue);
          expect(find.byKey(Key('$key-otp')), findsNothing);
          await tester.enterText(field, replacement);
          await tester.pumpAndSettle();
          expect(work.workspaceContactVerified(channel), isFalse);
          final cancel = find.byKey(Key('$key-cancel'));
          await reveal(tester, cancel);
          expect(
            tester.getRect(cancel).bottom,
            lessThanOrEqualTo(display.height - 240),
          );
          if (channel == WorkContactChannel.email) {
            await captureStoreView(
              tester,
              'r665-contact-edit-${display.width}-${display.scale}',
            );
          }
          await tap('cancel');
          tester.view.viewInsets = const FakeViewPadding();
          await tester.pumpAndSettle();
          await revealContactField();
          expect(tester.widget<TextField>(field).controller!.text, original);
          expect(tester.widget<TextField>(field).readOnly, isTrue);
          expect(work.workspaceContactsReady, isTrue);
          expect(find.byKey(Key('$key-otp')), findsNothing);

          await tap('change');
          await tester.enterText(field, replacement);
          await tester.pumpAndSettle();
          await tap('send-otp');
          final pendingCancel = find.byKey(Key('$key-cancel'));
          expect(
            tester.widget<IconButton>(pendingCancel).tooltip,
            startsWith('Cancel changes'),
          );
          await tap('cancel');
          expect(work.workspaceContactsReady, isTrue);
          expect(work.workspaceContactValue(channel), original);
          expect(find.byKey(Key('$key-otp')), findsNothing);
          await tap('change');
          await tester.enterText(field, replacement);
          await tester.pumpAndSettle();
          await tap('send-otp');
          tester.view.viewInsets = const FakeViewPadding(bottom: 240);
          await tester.pumpAndSettle();
          final code = find.byKey(Key('$key-otp'));
          await reveal(tester, code);
          final codeField = tester.widget<TextField>(code);
          expect(codeField.autofillHints, contains(AutofillHints.oneTimeCode));
          expect(codeField.focusNode!.hasFocus, isTrue);
          expect(codeField.decoration!.helperText, 'Sent to $replacement');
          await tester.enterText(code, '123456');
          await tester.pumpAndSettle();
          final confirm = find.byKey(Key('$key-confirm-otp'));
          await reveal(tester, confirm);
          expect(confirm.hitTestable(), findsOneWidget);
          expect(tester.getSize(confirm).height, greaterThanOrEqualTo(48));
          expect(
            tester.getRect(confirm).bottom,
            lessThanOrEqualTo(display.height - 240),
          );
          expect(work.workspaceContactVerified(channel), isFalse);
          if (channel == WorkContactChannel.email) {
            await captureStoreView(
              tester,
              'r665-contact-code-${display.width}-${display.scale}',
            );
          }
          await tester.tap(confirm);
          await tester.pumpAndSettle();
          expect(work.workspaceContactVerified(channel), isTrue);
          expect(work.workspaceContactValue(channel), replacement);
          expect(work.isEditingWorkspaceContact(channel), isFalse);
          expect(codeField.controller!.text, isEmpty);
          tester.view.viewInsets = const FakeViewPadding();
          await tester.pumpAndSettle();
          await revealContactField();
          expect(tester.widget<TextField>(field).controller!.text, replacement);
          expect(tester.widget<TextField>(field).readOnly, isTrue);
          expect(tester.widget<TextField>(field).focusNode!.hasFocus, isFalse);
          if (channel == WorkContactChannel.email) {
            await captureStoreView(
              tester,
              'r665-contact-confirmed-${display.width}-${display.scale}',
            );
          }
          final proceed = find.byKey(const Key('work-contact-continue'));
          await reveal(tester, proceed);
          await tester.tap(proceed);
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('work-details-continue')),
            findsOneWidget,
          );
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          await revealContactField();
          expect(tester.widget<TextField>(field).controller!.text, replacement);
          expect(work.workspaceContactsReady, isTrue);
          expect(find.byKey(Key('$key-otp')), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final display in [
    (width: 412.0, height: 915.0, scale: 1.0),
    (width: 320.0, height: 568.0, scale: 1.4),
    (width: 320.0, height: 568.0, scale: 2.0),
  ]) {
    testWidgets(
      'R669 details validation remains visible ${display.width} ${display.scale}',
      (tester) async {
        final work = WorkSession()
          ..selectProfile('retailer-grocery')
          ..saveDetails(name: '', area: '', activity: '')
          ..authorizedPersonName = 'Asha Sharma'
          ..primaryMobile = '9829012321'
          ..contactEmail = 'asha@example.com'
          ..primaryMobileVerified = true
          ..contactEmailVerified = true;
        await mount(
          tester,
          route: '/app/work/workspace/proof',
          work: work,
          viewport: Size(display.width, display.height),
          textScale: display.scale,
        );
        await tester.tap(find.byKey(const Key('work-details-continue')));
        await tester.pumpAndSettle();
        tester.view.viewInsets = const FakeViewPadding(bottom: 240);
        await tester.pumpAndSettle();
        final name = find.byKey(const Key('work-name'));
        expect(find.byKey(const Key('work-details-continue')), findsNothing);
        final area = find.byKey(const Key('work-area'));
        expect(tester.widget<TextField>(name).focusNode!.hasFocus, isTrue);
        await tester.enterText(name, 'Mahadev Traders');
        await tester.pumpAndSettle();
        await tester.testTextInput.receiveAction(TextInputAction.next);
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(area).focusNode!.hasFocus, isTrue);
        await tester.enterText(area, '30200');
        await tester.pumpAndSettle();
        final error = find.text(work.detailsAreaError!);
        final input = find.descendant(
          of: area,
          matching: find.byType(EditableText),
        );
        final viewport = tester.getRect(
          find.byKey(const Key('work-proof-screen')),
        );
        expect(error, findsOneWidget);
        final label = find.byKey(const Key('work-area-full-label'));
        if (label.evaluate().isNotEmpty) {
          expect(tester.getRect(label).top, greaterThanOrEqualTo(viewport.top));
        }
        await captureStoreView(
          tester,
          'r669-details-pin-error-${display.scale}',
        );
        expect(tester.getRect(error).top, greaterThanOrEqualTo(viewport.top));
        expect(
          tester.getRect(error).bottom,
          lessThanOrEqualTo(viewport.bottom),
        );
        expect(tester.getRect(input).top, greaterThanOrEqualTo(viewport.top));
        expect(
          tester.getRect(input).bottom,
          lessThanOrEqualTo(viewport.bottom),
        );
        expect(
          tester.widget<TextField>(area).controller!.selection.baseOffset,
          5,
        );
        await tester.enterText(area, '302001');
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(area).decoration!.errorText, isNull);
        expect(tester.widget<TextField>(area).focusNode!.hasFocus, isTrue);
        expect(
          tester.widget<TextField>(area).controller!.selection.baseOffset,
          6,
        );
        expect(work.reviewCaseId, isNull);
        await tester.testTextInput.receiveAction(TextInputAction.next);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('work-activity')))
              .focusNode!
              .hasFocus,
          isTrue,
        );
        await tester.testTextInput.receiveAction(TextInputAction.done);
        tester.view.viewInsets = FakeViewPadding.zero;
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-details-continue')).hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'OPPO S04 details local errors focus and progress ${display.width} ${display.scale}',
      (tester) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        final semantics = tester.ensureSemantics();
        try {
          final work = WorkSession()
            ..selectProfile('retailer-grocery')
            ..saveDetails(
              name: 'Mahadev Traders',
              area: '123',
              activity: 'Grocery retail',
            )
            ..businessRelationship = ''
            ..authorizedPersonName = 'Asha Sharma'
            ..primaryMobile = '9829012321'
            ..contactEmail = 'asha@example.com'
            ..primaryMobileVerified = true
            ..contactEmailVerified = true;
          await mount(
            tester,
            route: '/app/work/workspace/proof',
            work: work,
            viewport: Size(display.width, display.height),
            textScale: display.scale,
          );
          Future<void> capture(String page) => captureStoreView(
            tester,
            'r665-details-$page-${display.width.toInt()}-${display.scale}',
          );
          Future<void> tap(String key) async {
            final action = find.byKey(Key(key));
            await reveal(tester, action);
            expect(action.hitTestable(), findsOneWidget);
            await tester.tap(action);
            await tester.pumpAndSettle();
          }

          void checkProgress(int step, String label) {
            expect(
              find.bySemanticsLabel(RegExp('Details, Documents, Review')),
              findsWidgets,
            );
            final progress = find.byKey(const Key('work-workspace-progress'));
            final texts = find.descendant(
              of: progress,
              matching: find.byType(Text),
            );
            expect(
              tester
                  .widget<Text>(find.byKey(const Key('work-progress-current')))
                  .data,
              display.scale == 1 ? 'Step $step of 3' : '$label · $step of 3',
            );
            for (final element in texts.evaluate()) {
              final text = element.widget as Text;
              final paragraph = tester.renderObject<RenderParagraph>(
                find.descendant(
                  of: find.byWidget(text),
                  matching: find.byType(RichText),
                ),
              );
              expect(paragraph.didExceedMaxLines, isFalse);
              expect(paragraph.overflow, isNot(TextOverflow.ellipsis));
              expect(
                paragraph
                    .getBoxesForSelection(
                      TextSelection(
                        baseOffset: 0,
                        extentOffset: text.data!.length,
                      ),
                    )
                    .length,
                1,
              );
              expect(
                paragraph.textScaler.scale(12),
                closeTo(12 * display.scale, .01),
              );
            }
            final bars = find.descendant(
              of: progress,
              matching: find.byType(AnimatedContainer),
            );
            expect(bars, findsNWidgets(3));
            final widths = tester.getSize(bars.first).width;
            for (final element in bars.evaluate()) {
              final bar = element.widget as AnimatedContainer;
              expect(bar.duration, Duration.zero);
              expect(
                tester.getSize(find.byWidget(bar)).width,
                closeTo(widths, .01),
              );
            }
            expect(tester.getSize(progress).height, lessThanOrEqualTo(52));
            expect(tester.takeException(), isNull);
          }

          checkProgress(1, 'Details');
          await capture('first');
          final name = find.byKey(const Key('work-name'));
          final area = find.byKey(const Key('work-area'));
          final activity = find.byKey(const Key('work-activity'));
          expect(name.hitTestable(), findsOneWidget);
          await reveal(tester, name);
          await tester.enterText(name, 'Mahadev Traders');
          tester.view.viewInsets = const FakeViewPadding(bottom: 240);
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('work-local-navigation')), findsNothing);
          await tester.testTextInput.receiveAction(TextInputAction.next);
          await tester.pumpAndSettle();
          expect(tester.widget<TextField>(area).focusNode!.hasFocus, isTrue);
          await tester.testTextInput.receiveAction(TextInputAction.next);
          await tester.pumpAndSettle();
          expect(
            tester.widget<TextField>(activity).focusNode!.hasFocus,
            isTrue,
          );
          final editable = find.descendant(
            of: activity,
            matching: find.byType(EditableText),
          );
          expect(editable.hitTestable(), findsOneWidget);
          expect(
            tester.getRect(editable).bottom,
            lessThanOrEqualTo(display.height - 240),
          );
          await capture('keyboard');
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await tester.pumpAndSettle();
          expect(
            tester.widget<TextField>(activity).focusNode!.hasFocus,
            isFalse,
          );
          tester.view.viewInsets = FakeViewPadding.zero;
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('work-local-navigation')),
            findsOneWidget,
          );
          final relationshipLabel = find.byKey(
            const Key('work-business-relationship-full-label'),
          );
          await reveal(tester, relationshipLabel);
          final labelText = tester.widget<Text>(relationshipLabel);
          expect(labelText.data, 'Your relationship with the business');
          expect(labelText.maxLines, isNull);
          final labelParagraph = tester.renderObject<RenderParagraph>(
            find.descendant(
              of: relationshipLabel,
              matching: find.byType(RichText),
            ),
          );
          expect(labelParagraph.didExceedMaxLines, isFalse);
          expect(labelParagraph.overflow, isNot(TextOverflow.ellipsis));
          expect(work.businessRelationship, isEmpty);
          await captureStoreView(
            tester,
            'r666-relationship-empty-${display.width}-${display.scale}',
          );
          await tap('work-business-relationship');
          await tester.tap(find.text('Authorized representative').last);
          await tester.pumpAndSettle();
          expect(work.businessRelationship, 'Authorized representative');
          final selectedRelationship = find.text('Authorized representative');
          final relationshipField = find.byKey(
            const Key('work-business-relationship'),
          );
          expect(
            tester.getRect(selectedRelationship).bottom,
            lessThanOrEqualTo(tester.getRect(relationshipField).bottom),
          );
          await capture('relationship');
          if (display.scale == 2) {
            final label = find.byKey(
              const Key('work-business-relationship-full-label'),
            );
            await reveal(tester, label);
            final widget = tester.widget<Text>(label);
            expect(widget.data, 'Your relationship with the business');
            expect(widget.maxLines, isNull);
            expect(widget.overflow, isNot(TextOverflow.ellipsis));
          }
          await tap('work-details-continue');
          expect(work.errorMessage, isNull);
          expect(work.noticeMessage, isNull);
          expect(work.reviewCaseId, isNull);
          expect(
            tester.widget<TextField>(area).decoration!.errorText,
            work.detailsAreaError,
          );
          expect(tester.widget<TextField>(area).focusNode!.hasFocus, isTrue);
          await reveal(tester, area);
          await capture('location-error');
          await tester.enterText(area, 'Jaipur');
          await tester.pumpAndSettle();
          expect(tester.widget<TextField>(area).decoration!.errorText, isNull);
          await tap('work-details-continue');
          checkProgress(2, 'Documents');
          await tap('work-proof-review');
          checkProgress(3, 'Review');
          await capture('review');
          await tap('work-back');
          checkProgress(2, 'Documents');
          await tap('work-back');
          checkProgress(1, 'Details');
          expect(work.workName, 'Mahadev Traders');
          expect(work.workArea, 'Jaipur');
          expect(work.primaryActivity, 'Grocery retail');
          expect(work.primaryMobileVerified, isTrue);
          expect(work.contactEmailVerified, isTrue);
          expect(work.declarationAccepted, isFalse);
          expect(work.reviewCaseId, isNull);
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      },
    );
  }

  for (final display in [
    (size: Size(412, 915), scale: 1.0),
    (size: Size(360, 800), scale: 1.0),
    (size: Size(320, 568), scale: 1.4),
    (size: Size(320, 640), scale: 2.0),
  ]) {
    testWidgets('S01 growth placement ${display.size.width} ${display.scale}', (
      tester,
    ) async {
      final work = WorkSession();
      await mount(
        tester,
        route: '/app/work/workspace/choose',
        work: work,
        viewport: display.size,
        textScale: display.scale,
        bottomInset: 24,
      );
      await captureStoreView(
        tester,
        'r665-growth-entry-${display.size.width.toInt()}-${display.scale}',
      );
      final profile = find.byKey(const Key('work-profile-retailer-grocery'));
      expect(profile.hitTestable(), findsOneWidget);
      await reveal(tester, profile);
      await tester.tap(profile);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('workspace-benefits-retailer-grocery')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('work-profile-retailer-speciality')),
        findsNothing,
      );
      expect(work.selectedProfile, isNull);
      expect(find.byKey(const Key('workspace-chooser-hero')), findsNothing);
      await captureStoreView(
        tester,
        'r665-growth-customers-${display.size.width.toInt()}-${display.scale}',
      );
      expect(
        find.byKey(const Key('work-growth-concern-Send offers')).hitTestable(),
        findsOneWidget,
        reason:
            'Concern ${tester.getRect(find.byKey(const Key('work-growth-concern-Send offers')))}; list ${tester.getRect(find.byKey(const Key('work-choose-screen')))}',
      );
      final choose = find.byKey(
        const Key('work-profile-choose-retailer-grocery'),
      );
      expect(choose, findsOneWidget);
      expect(choose.hitTestable(), findsOneWidget);
      expect(
        tester.getBottomRight(choose).dy,
        lessThanOrEqualTo(display.size.height - 24),
      );
      final seen = <String>{};
      for (final group in ['Customers', 'Stock', 'Money', 'Daily work']) {
        final tab = find.byKey(Key('work-growth-group-$group'));
        await reveal(tester, tab);
        await tester.tap(tab);
        await tester.pumpAndSettle();
        while (true) {
          final rows = find.byWidgetPredicate(
            (widget) =>
                widget is Text &&
                widget.key is ValueKey<String> &&
                (widget.key! as ValueKey<String>).value.startsWith(
                  'work-growth-action-',
                ),
          );
          expect(rows.evaluate().length, inInclusiveRange(1, 3));
          seen.addAll(tester.widgetList<Text>(rows).map((text) => text.data!));
          final next = find.byKey(const Key('work-growth-next'));
          if (tester.widget<IconButton>(next).onPressed == null) break;
          await reveal(tester, next);
          await tester.tap(next);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      }
      expect(seen, hasLength(25));
      expect(
        seen,
        containsAll([
          'Collect at store',
          'Collect dues',
          'Restock',
          'Buy Direct',
          'Group Bulk Buying',
          'Get tax help',
          'Check eligibility',
          'Post requirement',
          'Review returns',
          'Check earnings',
        ]),
      );
      await reveal(tester, find.byKey(const Key('work-growth-group-Stock')));
      await tester.tap(find.byKey(const Key('work-growth-group-Stock')));
      await tester.pumpAndSettle();
      await captureStoreView(
        tester,
        'r665-growth-${display.size.width.toInt()}-${display.scale}',
      );
      await reveal(tester, choose);
      await tester.tap(choose);
      await tester.pumpAndSettle();
      expect(work.selectedProfile?.id, 'retailer-grocery');
      expect(find.byKey(const Key('work-requirements-screen')), findsOneWidget);
      await tester.tap(find.byKey(const Key('work-back')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-choose-screen')), findsOneWidget);
      expect(
        find.byKey(const Key('workspace-benefits-retailer-grocery')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextButton>(
              find.byKey(const Key('work-growth-group-Stock')),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const Key('work-back')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('workspace-benefits-retailer-grocery')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final profile in ['retailer-speciality', 'wholesaler', 'manufacturer']) {
    testWidgets('S01 growth profile $profile keeps copy focus and scroll', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final work = WorkSession();
      await mount(
        tester,
        route: '/app/work/workspace/choose',
        work: work,
        viewport: const Size(412, 915),
        textScale: 1,
        bottomInset: 24,
      );
      final choice = find.byKey(Key('work-profile-$profile'));
      await reveal(tester, choice);
      final list = find.byKey(const Key('work-choose-screen'));
      final controller = tester.widget<ListView>(list).controller!;
      final offset = controller.offset;
      await tester.tap(choice);
      await tester.pumpAndSettle();
      expect(controller.offset, 0);
      expect(work.selectedProfile, isNull);
      expect(
        find.byKey(const Key('work-profile-retailer-grocery')),
        findsNothing,
      );
      if (profile == 'retailer-speciality') {
        expect(
          find.text('The right products sell better together.'),
          findsOneWidget,
        );
        expect(find.textContaining('monthly shopping'), findsNothing);
      } else {
        expect(find.text('Collect at store'), findsNothing);
        expect(find.textContaining('families'), findsNothing);
      }
      if (profile == 'manufacturer') {
        expect(find.text('Create Offer'), findsOneWidget);
        expect(
          find.text('Finished goods are waiting for buyers.'),
          findsOneWidget,
        );
      }
      final rows = find.byWidgetPredicate(
        (widget) =>
            widget is AnimatedSize &&
            widget.key.toString().contains('work-growth-disclosure-'),
      );
      expect(rows, findsNWidgets(3));
      for (final row in tester.widgetList<AnimatedSize>(rows)) {
        expect(row.duration, Duration.zero);
      }
      await captureStoreView(tester, 'r665-growth-$profile');
      await tester.tap(find.byKey(Key('work-profile-close-$profile')));
      await tester.pumpAndSettle();
      expect(controller.offset, closeTo(offset, .5));
      expect(choice.hitTestable(), findsOneWidget);
      expect(work.selectedProfile, isNull);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'S01 growth disclosure is one native action and never activates a service',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final work = WorkSession();
        await mount(
          tester,
          route: '/app/work/workspace/choose',
          work: work,
          viewport: const Size(412, 915),
          textScale: 1,
          bottomInset: 24,
        );
        final choice = find.byKey(const Key('work-profile-retailer-grocery'));
        await reveal(tester, choice);
        await tester.tap(choice);
        await tester.pumpAndSettle();
        final second = find.byKey(
          const Key('work-growth-concern-Create basket'),
        );
        expect(tester.getSize(second).height, greaterThanOrEqualTo(44));
        await tester.tap(second);
        await tester.pumpAndSettle();
        expect(find.textContaining('Put regular essentials'), findsOneWidget);
        expect(
          find.textContaining('Use your shop’s customer records'),
          findsNothing,
        );
        await tester.tap(second);
        await tester.pumpAndSettle();
        expect(find.textContaining('Put regular essentials'), findsNothing);
        expect(find.text('Choose this Workspace'), findsOneWidget);
        expect(work.selectedProfile, isNull);
        expect(work.reviewCaseId, isNull);
        final stock = find.byKey(const Key('work-growth-group-Stock'));
        await tester.tap(stock);
        await tester.pumpAndSettle();
        expect(find.text('Restock'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'S01 growth clearing search restores choices without changing application',
    (tester) async {
      final work = WorkSession()..selectProfile('retailer-speciality');
      await mount(
        tester,
        route: '/app/work/workspace/choose',
        work: work,
        viewport: const Size(412, 915),
        textScale: 1,
      );
      final search = find.byKey(const Key('work-workspace-search'));
      await tester.enterText(search, 'grocery');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('work-profile-retailer-grocery')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-profile-retailer-speciality')),
        findsNothing,
      );
      await tester.tap(find.byKey(const Key('work-workspace-search-clear')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('workspace-benefits-retailer-grocery')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('work-profile-retailer-speciality')),
        findsOneWidget,
      );
      expect(work.selectedProfile?.id, 'retailer-speciality');
      expect(tester.takeException(), isNull);
    },
  );

  test('R669 retailer preview uses exact collection and bank wording', () {
    for (final id in ['retailer-grocery', 'retailer-speciality']) {
      final points = workWorkspaceBenefitFor(id).benefits;
      expect(
        points.singleWhere((p) => p.action == 'Collect at store').detail,
        'Customers pay in the app. Pack their order before they arrive.',
      );
      expect(
        points.singleWhere((p) => p.action == 'Settle').detail,
        'See the amount available and request transfer to your registered bank account.',
      );
    }
  });

  for (final scale in [1.0, 1.4, 2.0]) {
    testWidgets('R669 category dismissal does not reopen Search at $scale', (
      tester,
    ) async {
      final work = WorkSession()..selectProfile('retailer-grocery');
      await mount(
        tester,
        route: '/app/work/workspace/choose',
        work: work,
        viewport: const Size(320, 568),
        textScale: scale,
        bottomInset: 24,
      );
      final search = find.byKey(const Key('work-workspace-search'));
      await tester.enterText(search, 'grocery');
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(search);
      expect(field.focusNode!.hasFocus, isTrue);
      // Android can dismiss its IME without removing Flutter input focus.
      tester.testTextInput.hide();
      await tester.tap(find.byKey(const Key('work-workspace-category')));
      await tester.pumpAndSettle();
      expect(field.focusNode!.hasFocus, isFalse);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(field.focusNode!.hasFocus, isFalse);
      expect(tester.testTextInput.isVisible, isFalse);
      expect(field.controller!.text, 'grocery');
      expect(work.selectedProfile?.id, 'retailer-grocery');
      expect(find.byType(PopupMenuItem<String>), findsNothing);
      expect(
        find.byKey(const Key('work-profile-retailer-grocery')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await captureStoreView(tester, 'r669-selector-category-dismissed-$scale');
      await tester.tap(search);
      await tester.pumpAndSettle();
      expect(field.focusNode!.hasFocus, isTrue);
      expect(tester.testTextInput.isVisible, isTrue);
    });
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('R669 new Workspace first view and preview at $scale', (
      tester,
    ) async {
      final work = WorkSession()..seedMultipleWorkspaces();
      work.startAnotherWork();
      await mount(
        tester,
        route: '/app/work/workspace/choose',
        work: work,
        viewport: scale == 1 ? const Size(412, 915) : const Size(320, 568),
        textScale: scale,
        bottomInset: 24,
      );
      expect(find.byKey(const Key('workspace-existing-summary')), findsNothing);
      expect(find.byKey(const Key('workspace-open-active')), findsNothing);
      expect(find.byKey(const Key('workspace-settlement')), findsNothing);
      expect(find.text('Mahadev Fresh Mart'), findsNothing);
      expect(work.activeWorkspace?.id, 'WK-510001');
      expect(work.otherWorkspaces, hasLength(2));
      await captureStoreView(tester, 'r669-selector-new-workspace-$scale');
      final choice = find.byKey(const Key('work-profile-retailer-grocery'));
      await tester.ensureVisible(choice);
      await tester.pumpAndSettle();
      expect(choice.hitTestable(), findsOneWidget);
      await tester.tap(choice);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('workspace-benefits-retailer-grocery')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('workspace-existing-summary')), findsNothing);
      expect(find.text('Mahadev Fresh Mart'), findsNothing);
      expect(
        find.byKey(const Key('work-profile-choose-retailer-grocery')),
        findsOneWidget,
      );
      await captureStoreView(tester, 'r669-selector-retailer-preview-$scale');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('OPPO S01 inline discovery preserves the selected application', (
    tester,
  ) async {
    final work = WorkSession()..selectProfile('retailer-grocery');
    await mount(
      tester,
      route: '/app/work/workspace/choose',
      work: work,
      viewport: const Size(412, 915),
      textScale: 1,
    );
    final search = find.byKey(const Key('work-workspace-search'));
    expect(
      find.ancestor(of: search, matching: find.byType(AppBar)),
      findsOneWidget,
    );
    expect(tester.widget<TextField>(search).decoration!.filled, isFalse);
    expect(find.text('Grow with MoolSocial'), findsOneWidget);
    await captureStoreView(tester, 'r665-selector-first-view');
    await tester.enterText(search, 'saloon');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-profile-salon')), findsOneWidget);
    expect(find.byKey(const Key('workspace-chooser-hero')), findsNothing);
    expect(work.selectedProfile?.id, 'retailer-grocery');
    await tester.enterText(search, 'not-a-workspace');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-workspace-no-match')), findsOneWidget);
    expect(find.byKey(const Key('work-profile-not-shown')), findsOneWidget);
    await tester.tap(find.byKey(const Key('work-workspace-search-clear')));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(search).controller!.text, isEmpty);
    await tester.tap(find.byKey(const Key('work-workspace-category')));
    await tester.pumpAndSettle();
    expect(
      find.byType(PopupMenuItem<String>),
      findsNWidgets(work.familyIds.length + 1),
    );
    await tester.tap(find.text('All businesses'));
    await tester.pumpAndSettle();
    expect(work.selectedProfile?.id, 'retailer-grocery');
    expect(tester.takeException(), isNull);
  });

  testWidgets('OPPO S01 search keeps a complete match above compact keyboard', (
    tester,
  ) async {
    final work = WorkSession();
    await mount(
      tester,
      route: '/app/work/workspace/choose',
      work: work,
      viewport: const Size(320, 568),
      textScale: 1.4,
      bottomInset: 24,
    );
    final search = find.byKey(const Key('work-workspace-search'));
    await tester.enterText(search, 'grocery');
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    await tester.pumpAndSettle();
    final match = find.byKey(const Key('work-profile-retailer-grocery'));
    expect(match, findsOneWidget);
    expect(tester.getBottomRight(match).dy, lessThanOrEqualTo(328));
    expect(tester.getTopLeft(search).dy, lessThan(tester.getTopLeft(match).dy));
    expect(find.byKey(const Key('workspace-chooser-hero')), findsNothing);
    await captureStoreView(tester, 'r665-selector-keyboard-320-large-text');
    tester.view.viewInsets = const FakeViewPadding();
    tester.testTextInput.hide();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(search).controller!.text, 'grocery');
    await tester.tap(match);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('workspace-benefits-retailer-grocery')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('work-back')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('workspace-benefits-retailer-grocery')),
      findsNothing,
    );
    expect(tester.widget<TextField>(search).controller!.text, 'grocery');
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 2.0]) {
    for (final profile in ['retailer-grocery', 'retailer-speciality']) {
      testWidgets('R669 saved application chooser $profile $scale', (
        tester,
      ) async {
        final gateway = ReviewWorkGateway(
          initialReviewStatus: WorkRemoteReviewStatus.pending,
        );
        final work = storeViewFixture(gateway);
        final existing = work.activeWorkspace;
        final balance = work.workspaceSettlementBalance;
        work.startAnotherWork();
        work.selectProfile(profile);
        work.saveDetails(
          name: 'New Kirana',
          area: '302001',
          activity: 'Groceries',
        );
        work.authorizedPersonName = 'Asha Sharma';
        work.businessRelationship = 'Owner';
        work.primaryMobile = '9829012321';
        work.contactEmail = 'asha@example.com';
        work.primaryMobileVerified = work.contactEmailVerified = true;
        expect(
          await tester.runAsync(
            () => work.addProof('personal-kyc', WorkProofSource.upload),
          ),
          isTrue,
        );
        work.declarationAccepted = true;
        expect(await tester.runAsync(work.submitProfile), isTrue);
        final caseId = work.reviewCaseId;
        final submitted = work.submittedProfile;
        final proofs = Map.of(work.addedProofs);
        final id = work.savedWorkspaceApplications.single.id;
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: scale == 1 ? const Size(412, 915) : const Size(320, 568),
          textScale: scale,
        );
        expect(find.text('New Kirana'), findsNothing);
        await captureStoreView(
          tester,
          'r669-approved-store-with-application-$profile-$scale',
        );
        await tester.tap(
          find.byKey(const Key('work-dashboard-workspace-switcher')),
        );
        await tester.pumpAndSettle();
        final sheet = find.byKey(const Key('work-workspace-switcher-sheet'));
        final entry = find.byKey(ValueKey('work-resume-$id'));
        final scrollable = find.descendant(
          of: sheet,
          matching: find.byType(Scrollable),
        );
        await tester.scrollUntilVisible(entry, 120, scrollable: scrollable);
        await Scrollable.ensureVisible(tester.element(entry), alignment: .5);
        await tester.pumpAndSettle();
        expect(entry.hitTestable(), findsOneWidget);
        await captureStoreView(
          tester,
          'r669-application-chooser-$profile-$scale',
        );
        final viewport = tester.getRect(scrollable);
        expect(
          tester.getRect(entry).top,
          greaterThanOrEqualTo(viewport.top - 1),
        );
        expect(
          tester.getRect(entry).bottom,
          lessThanOrEqualTo(viewport.bottom + 1),
        );
        final addWorkspace = find.byKey(const Key('work-switch-add-workspace'));
        await tester.ensureVisible(addWorkspace);
        await tester.pumpAndSettle();
        expect(addWorkspace.hitTestable(), findsOneWidget);
        expect(
          tester.getRect(addWorkspace).bottom,
          lessThanOrEqualTo(viewport.bottom + 1),
        );
        await Scrollable.ensureVisible(tester.element(entry), alignment: .5);
        await tester.pumpAndSettle();
        await tester.tap(entry);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-inline-review-status')),
          findsOneWidget,
        );
        expect(work.reviewCaseId, caseId);
        expect(work.submittedProfile, same(submitted));
        expect(work.addedProofs, proofs);
        expect(work.activeWorkspace, same(existing));
        await captureStoreView(
          tester,
          'r669-resumed-application-$profile-$scale',
        );
        await tester.tap(find.byKey(const Key('work-back')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-workspace-dashboard')),
          findsOneWidget,
        );
        expect(work.workspaceSettlementBalance, balance);
        expect(gateway.submissionCalls, 1);
        expect(tester.takeException(), isNull);
      });
    }
    testWidgets('R669 ordinary workspace entry resumes approved Store $scale', (
      tester,
    ) async {
      final gateway = _WorkspaceEntryFixtureGateway();
      final work = WorkSession(gateway: gateway);
      await mount(
        tester,
        route: '/app/work/my-work',
        work: work,
        viewport: scale == 1 ? const Size(412, 915) : const Size(320, 568),
        textScale: scale,
      );
      expect(find.byKey(const Key('work-workspace-dashboard')), findsOneWidget);
      expect(find.byKey(const Key('work-choose-screen')), findsNothing);
      expect(work.activeWorkspace?.name, 'Approved Kirana');
      expect(work.startAnotherWork(), isTrue);
      tester
          .element(find.byKey(const Key('work-workspace-dashboard')))
          .go('/app/work/workspace/choose');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-choose-screen')), findsOneWidget);
      expect(find.byKey(const Key('workspace-existing-summary')), findsNothing);
      expect(tester.takeException(), isNull);
    });
    testWidgets(
      'R669 workspace entry retries without an onboarding detour $scale',
      (tester) async {
        final gateway = _WorkspaceEntryFixtureGateway()..failOnce = true;
        final work = WorkSession(gateway: gateway);
        await mount(
          tester,
          route: '/app/work/my-work',
          work: work,
          viewport: scale == 1 ? const Size(412, 915) : const Size(320, 568),
          textScale: scale,
        );
        expect(find.byKey(const Key('work-choose-screen')), findsNothing);
        expect(
          find.text('Your Workspaces could not be loaded.'),
          findsOneWidget,
        );
        final retry = find.byKey(const Key('work-entry-retry'));
        expect(
          tester
              .widget<WorkPageScaffold>(find.byType(WorkPageScaffold))
              .activeLocalAction,
          'workspace',
        );
        expect(retry.hitTestable(), findsOneWidget);
        await captureStoreView(tester, 'r669-workspace-entry-retry-$scale');
        await tester.tap(retry);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-workspace-dashboard')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('REG4550 support failure A B return and retry $scale', (
      tester,
    ) async {
      final work = WorkSession()
        ..selectFamily('products-trade')
        ..selectProfile('retailer-grocery')
        ..reviewCaseId = 'APPLICATION-A'
        ..reviewStage = WorkReviewStage.gstPending
        ..remoteReviewStatus = WorkRemoteReviewStatus.rejected
        ..reviewReason = 'The business address could not be confirmed.';
      final gateway = ReviewChatSendGateway(
        failNextRequest: true,
        latency: Duration.zero,
      );
      final chat = ChatSession(sendGateway: gateway);
      const thread = 'workspace-support';
      const draftA = 'Please review the address for my first application.';
      const newerA = 'Please also check the revised address document.';
      const draftB = 'My separate second application question';
      for (final entry in const {
        'APPLICATION-A': draftA,
        'APPLICATION-B': draftB,
      }.entries) {
        chat.setDraftTextForSession(
          thread,
          entry.value,
          workspaceApplicationId: entry.key,
        );
      }
      String route(String application) => Uri(
        path: '/app/chat/thread/workspace-support',
        queryParameters: {
          'return': '/app/work/workspace/proof',
          'directReturn': 'true',
          'workspaceApplication': application,
          'workspaceBusiness': 'Review store',
        },
      ).toString();
      await mount(
        tester,
        route: route('APPLICATION-A'),
        work: work,
        chat: chat,
        viewport: scale == 1 ? const Size(412, 915) : const Size(320, 568),
        textScale: scale,
      );
      final field = find.byKey(const Key('chat-message-field'));
      expect(tester.widget<TextField>(field).controller!.text, draftA);
      await tester.tap(field);
      tester.view.viewInsets = const FakeViewPadding(bottom: 220);
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field).maxLines, 2);
      expect(
        tester.widget<TextField>(field).keyboardType,
        TextInputType.multiline,
      );
      final send = find.byKey(const Key('chat-send'));
      expect(send.hitTestable(), findsOneWidget);
      await tester.tap(send);
      await tester.pumpAndSettle();
      const failure = 'Message was not sent. Check your connection and retry.';
      expect(find.byKey(const Key('chat-error')), findsOneWidget);
      expect(find.text(failure), findsOneWidget);
      expect(tester.widget<TextField>(field).controller!.text, draftA);
      final failed = chat
          .messages(thread)
          .where((message) => message.mine)
          .single;
      expect(
        chat.retryDraftMatchesApplication(failed.id, 'APPLICATION-A'),
        isTrue,
      );
      expect(tester.takeException(), isNull);
      await captureStoreView(tester, 'support-failure-keyboard-$scale');
      expect(
        tester.getSize(find.byKey(const Key('chat-message-list'))).height,
        greaterThanOrEqualTo(kMinInteractiveDimension),
        reason: 'Failed-send feedback and typing must leave conversation space',
      );
      final feedback = find.byKey(const Key('chat-feedback-text-scroll'));
      final feedbackScroll = tester.state<ScrollableState>(
        find.descendant(of: feedback, matching: find.byType(Scrollable)).first,
      );
      if (feedbackScroll.position.maxScrollExtent > 0) {
        await tester.drag(feedback, const Offset(0, -300));
        await tester.pumpAndSettle();
      }
      final errorText = find.text(failure);
      final paragraph = tester.renderObject<RenderParagraph>(errorText);
      final ending = paragraph
          .getBoxesForSelection(
            TextSelection(
              baseOffset: failure.lastIndexOf('retry'),
              extentOffset: failure.length,
            ),
          )
          .single;
      final endingBottom = paragraph.localToGlobal(
        Offset(ending.right, ending.bottom),
      );
      final endingTop = paragraph.localToGlobal(
        Offset(ending.left, ending.top),
      );
      expect(
        endingTop.dy,
        greaterThanOrEqualTo(tester.getRect(feedback).top - .5),
      );
      expect(
        endingBottom.dy,
        lessThanOrEqualTo(tester.getRect(feedback).bottom + .5),
      );
      expect(endingBottom.dy, greaterThan(tester.getRect(feedback).top));
      await captureStoreView(tester, 'support-failure-instruction-$scale');
      final keyboardRetry = find.byKey(Key('chat-retry-${failed.id}'));
      final keyboardMessages = find
          .descendant(
            of: find.byKey(const Key('chat-message-list')),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        keyboardRetry,
        120,
        scrollable: keyboardMessages,
      );
      await tester.pumpAndSettle();
      expect(keyboardRetry.hitTestable(), findsOneWidget);
      await captureStoreView(tester, 'support-keyboard-retry-reachable-$scale');
      const multiline = 'Please review the address.\nThe document is attached.';
      await tester.enterText(field, multiline);
      expect(tester.widget<TextField>(field).controller!.text, multiline);
      expect(
        chat.draftTextForSession(
          thread,
          workspaceApplicationId: 'APPLICATION-A',
        ),
        multiline,
      );
      await tester.enterText(field, newerA);
      FocusManager.instance.primaryFocus?.unfocus();
      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field).maxLines, 2);
      final router = GoRouter.of(tester.element(field));
      router.go(route('APPLICATION-B'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field).controller!.text, draftB);
      expect(find.byKey(const Key('chat-error')), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Application APPLICATION-B'),
        -160,
        scrollable: keyboardMessages,
      );
      await tester.pumpAndSettle();
      expect(find.text('Application APPLICATION-B'), findsOneWidget);
      router.go(route('APPLICATION-A'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field).controller!.text, newerA);
      await tester.scrollUntilVisible(
        find.text('Application APPLICATION-A'),
        -160,
        scrollable: keyboardMessages,
      );
      await tester.pumpAndSettle();
      expect(find.text('Application APPLICATION-A'), findsOneWidget);
      final retry = find.byKey(Key('chat-retry-${failed.id}'));
      final messageScroll = find
          .descendant(
            of: find.byKey(const Key('chat-message-list')),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(retry, 160, scrollable: messageScroll);
      await tester.pumpAndSettle();
      expect(retry.hitTestable(), findsOneWidget);
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field).controller!.text, newerA);
      expect(
        chat.draftTextForSession(
          thread,
          workspaceApplicationId: 'APPLICATION-B',
        ),
        draftB,
      );
      expect(
        chat.messages(thread).where((message) => message.mine),
        hasLength(1),
      );
      expect(
        chat.retryDraftMatchesApplication(failed.id, 'APPLICATION-A'),
        isFalse,
      );
      expect(find.byKey(Key('chat-retry-${failed.id}')), findsNothing);
      await captureStoreView(tester, 'support-retry-preserved-draft-$scale');
      await tester.tap(find.byKey(const Key('chat-back')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-inline-review-status')),
        findsOneWidget,
      );
      expect(work.reviewCaseId, 'APPLICATION-A');
      expect(work.remoteReviewStatus, WorkRemoteReviewStatus.rejected);
      expect(tester.takeException(), isNull);
    });
  }

  for (final decision in [
    WorkRemoteReviewStatus.rejected,
    WorkRemoteReviewStatus.suspended,
  ]) {
    for (final scale in [1.0, 2.0]) {
      for (final retained in [false, true]) {
        testWidgets(
          'R669 review support exact application $decision $scale retained=$retained',
          (tester) async {
            final gateway = ReviewWorkGateway()
              ..reviewResultStatus = WorkRemoteReviewStatus.pending;
            final work = WorkSession(gateway: gateway)
              ..selectProfile('retailer-grocery')
              ..saveDetails(
                name: 'Mahadev Traders',
                area: 'Jaipur',
                activity: 'Groceries',
              )
              ..authorizedPersonName = 'Asha Sharma'
              ..businessRelationship = 'Owner'
              ..primaryMobile = '9829012321'
              ..contactEmail = 'asha@example.com'
              ..primaryMobileVerified = true
              ..contactEmailVerified = true
              ..declarationAccepted = true;
            expect(await tester.runAsync(work.submitProfile), isTrue);
            final caseId = work.reviewCaseId!;
            final submitted = work.submittedProfile;
            work.remoteReviewStatus = decision;
            work.reviewReason = 'The business address could not be confirmed.';
            work.workName = 'Unsubmitted name';
            final chat = ChatSession(
              sendGateway: ReviewChatSendGateway(latency: Duration.zero),
            );
            chat.setDraftTextForSession(
              'workspace-support',
              'My unrelated support draft',
            );
            if (retained) {
              chat.setDraftTextForSession(
                'workspace-support',
                'My existing question',
                workspaceApplicationId: caseId,
              );
            }
            await mount(
              tester,
              route: '/app/work/workspace/proof',
              work: work,
              chat: chat,
              viewport: scale == 2
                  ? const Size(320, 568)
                  : const Size(412, 915),
              textScale: scale,
            );
            final help = find.byKey(const Key('work-inline-review-support'));
            expect(help.hitTestable(), findsOneWidget);
            await tester.tap(help);
            await tester.pumpAndSettle();
            expect(find.byKey(const Key('chat-thread-screen')), findsOneWidget);
            expect(find.byKey(const Key('chat-inbox-screen')), findsNothing);
            final context = find.byKey(
              const Key('chat-workspace-application-context'),
            );
            expect(context, findsOneWidget);
            expect(
              find.descendant(
                of: context,
                matching: find.text('Mahadev Traders'),
              ),
              findsOneWidget,
            );
            expect(
              find.descendant(
                of: context,
                matching: find.text('Application $caseId'),
              ),
              findsOneWidget,
            );
            final field = find.byKey(const Key('chat-message-field'));
            expect(
              tester.widget<TextField>(field).controller!.text,
              retained
                  ? 'My existing question'
                  : 'Please help me with application $caseId for Mahadev Traders.',
            );
            expect(
              chat
                  .messages('workspace-support')
                  .where((message) => message.mine),
              isEmpty,
            );
            await captureStoreView(
              tester,
              'r669-application-support-${decision.name}-$scale-$retained',
            );
            final draft = tester.widget<TextField>(field).controller!.text;
            await tester.tap(field);
            tester.view.viewInsets = const FakeViewPadding(bottom: 240);
            await tester.pumpAndSettle();
            await tester.enterText(
              field,
              '$draft Please explain the next step.',
            );
            await tester.pumpAndSettle();
            final composer = find.byKey(const Key('chat-composer-surface'));
            expect(
              tester.getRect(composer).bottom,
              lessThanOrEqualTo((scale == 2 ? 568 : 915) - 240),
            );
            await captureStoreView(
              tester,
              'r669-application-support-keyboard-${decision.name}-$scale-$retained',
            );
            FocusManager.instance.primaryFocus?.unfocus();
            tester.view.viewInsets = FakeViewPadding.zero;
            await tester.pumpAndSettle();
            if (retained) {
              await tester.tap(find.byKey(const Key('chat-back')));
            } else {
              await tester.binding.handlePopRoute();
            }
            await tester.pumpAndSettle();
            expect(
              find.byKey(const Key('work-inline-review-status')),
              findsOneWidget,
            );
            expect(work.reviewCaseId, caseId);
            expect(work.submittedProfile, same(submitted));
            expect(work.remoteReviewStatus, decision);
            expect(gateway.submissionCalls, 1);
            expect(
              chat.draftTextForSession(
                'workspace-support',
                workspaceApplicationId: caseId,
              ),
              '$draft Please explain the next step.',
            );
            expect(
              chat.draftTextForSession('workspace-support'),
              'My unrelated support draft',
            );
            expect(
              chat
                  .messages('workspace-support')
                  .where((message) => message.mine),
              isEmpty,
            );
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  for (final decision in [
    WorkRemoteReviewStatus.pending,
    WorkRemoteReviewStatus.rejected,
    WorkRemoteReviewStatus.suspended,
  ]) {
    for (final target in ['retailer-speciality', 'salon']) {
      testWidgets(
        'Submitted application survives another business preview $decision $target',
        (tester) async {
          final gateway = ReviewWorkGateway(initialReviewStatus: decision)
            ..reviewResultReason = decision == WorkRemoteReviewStatus.pending
                ? 'Please clarify the registered business address.'
                : 'The business information needs further review.';
          final work = WorkSession(gateway: gateway)
            ..selectProfile('retailer-grocery')
            ..selectedFamilyId = 'products-trade'
            ..saveDetails(
              name: 'QA Submitted Grocery',
              area: 'Jodhpur',
              activity: 'Grocery retail',
            )
            ..authorizedPersonName = 'QA Retailer'
            ..businessRelationship = 'Owner'
            ..primaryMobile = '9829012321'
            ..contactEmail = 'asha@example.com'
            ..primaryMobileVerified = true
            ..contactEmailVerified = true;
          work.addedProofs['shop-front'] = 'qa-proof-reference';
          work.declarationAccepted = true;
          expect(await tester.runAsync(work.submitProfile), isTrue);
          await tester.runAsync(work.checkReview);
          final submission = work.submittedProfile;
          final caseId = work.reviewCaseId;
          await mount(
            tester,
            route: '/app/work/workspace/choose',
            work: work,
            viewport: const Size(320, 568),
            textScale: target == 'salon' ? 1 : 2,
          );
          final summary = find.byKey(
            const Key('workspace-application-summary'),
          );
          await reveal(tester, summary);
          final title = find.byKey(
            const Key('workspace-application-status-title'),
          );
          final titleText = tester.widget<Text>(title).data!;
          expect(titleText, switch (decision) {
            WorkRemoteReviewStatus.pending => 'Details requested',
            WorkRemoteReviewStatus.rejected => 'Application declined',
            _ => 'Workspace unavailable',
          });
          final paragraph = tester.renderObject<RenderParagraph>(
            find.descendant(of: title, matching: find.byType(RichText)),
          );
          expect(paragraph.didExceedMaxLines, isFalse);
          var wordStart = 0;
          for (final word in titleText.split(' ')) {
            expect(
              paragraph
                  .getBoxesForSelection(
                    TextSelection(
                      baseOffset: wordStart,
                      extentOffset: wordStart + word.length,
                    ),
                  )
                  .length,
              1,
              reason: 'Application status must not break a word into fragments',
            );
            wordStart += word.length + 1;
          }
          expect(tester.getSize(summary).height, lessThanOrEqualTo(240));
          await captureStoreView(
            tester,
            'r666-case-banner-${decision.name}-$target',
          );
          final search = find.byKey(const Key('work-workspace-search'));
          await tester.enterText(
            search,
            target == 'salon' ? 'salon' : 'speciality',
          );
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
          final option = find.byKey(Key('work-profile-$target'));
          await reveal(tester, option);
          await tester.tap(option);
          await tester.pumpAndSettle();
          final choose = find.byKey(Key('work-profile-choose-$target'));
          await reveal(tester, choose);
          expect(
            find.descendant(
              of: choose,
              matching: find.text('View application'),
            ),
            findsOneWidget,
          );
          expect(work.selectedProfile?.id, 'retailer-grocery');
          expect(work.addedProofs['shop-front'], 'qa-proof-reference');
          await captureStoreView(
            tester,
            'r666-case-preview-${decision.name}-$target',
          );
          await tester.tap(choose);
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('work-inline-review-status')),
            findsOneWidget,
          );
          expect(work.selectedProfile?.id, 'retailer-grocery');
          expect(work.submittedProfile, same(submission));
          expect(work.reviewCaseId, caseId);
          expect(work.workName, 'QA Submitted Grocery');
          expect(work.addedProofs['shop-front'], 'qa-proof-reference');
          expect(work.activeWorkspace, isNull);
          expect(gateway.submissionCalls, 1);
          final back = find.byKey(const Key('work-back'));
          await tester.tap(back);
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('work-choose-screen')), findsOneWidget);
          await tester.tap(find.byKey(const Key('work-back')));
          await tester.pumpAndSettle();
          expect(work.selectedProfile?.id, 'retailer-grocery');
          expect(work.reviewCaseId, caseId);
          expect(work.addedProofs['shop-front'], 'qa-proof-reference');
          expect(work.submittedProfile, same(submission));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final profileId in [
    'retailer-grocery',
    'retailer-speciality',
    'salon',
  ]) {
    testWidgets(
      'OPPO S02 document copy preserves proof bindings - $profileId',
      (tester) async {
        final work = WorkSession()..selectProfile(profileId);
        final originalIds = work.selectedWorkspaceDocuments
            .map((proof) => proof.id)
            .toList();
        await mount(
          tester,
          route: '/app/work/workspace/requirements',
          work: work,
          viewport: const Size(320, 568),
          textScale: 1.4,
          bottomInset: 24,
        );
        final retailer = profileId.startsWith('retailer-');
        expect(
          find.text(
            retailer ? 'Your identity proof' : 'Account owner identity',
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining('You can add documents later.'),
          findsOneWidget,
        );
        expect(
          work.selectedGstChecklistItem?.title,
          'GST registration certificate',
        );
        expect(
          work.selectedGstChecklistItem?.importance,
          WorkDocumentImportance.ifApplicable,
        );
        expect(
          work.selectedWorkspaceDocuments.map((proof) => proof.id),
          originalIds,
        );
        if (profileId == 'retailer-grocery') {
          expect(originalIds, [
            'personal-kyc',
            'shop-front',
            'retailer-grocery-document-2',
            'owner-authority',
            'payout-bank-account',
            'gst',
          ]);
        }
        await captureStoreView(
          tester,
          'r665-documents-$profileId-320-large-text',
        );
        final bank = find.text(
          retailer ? 'Bank proof for payments' : 'Payout bank account proof',
        );
        await reveal(tester, bank);
        expect(bank, findsOneWidget);
        expect(
          find.byKey(const Key('work-requirements-ready')).hitTestable(),
          findsOneWidget,
        );
        await captureStoreView(
          tester,
          'r665-documents-bank-$profileId-320-large-text',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final profileId in [
    'retailer-grocery',
    'retailer-speciality',
    'salon',
  ]) {
    for (final display in [
      (width: 412.0, height: 915.0, scale: 1.0),
      (width: 320.0, height: 568.0, scale: 1.4),
      if (profileId == 'retailer-grocery')
        (width: 320.0, height: 568.0, scale: 2.0),
    ]) {
      testWidgets(
        'OPPO S04 setup headers preserve identity $profileId ${display.width} ${display.scale}',
        (tester) async {
          final work = WorkSession()
            ..selectProfile(profileId)
            ..saveDetails(
              name: 'Mahadev Traders',
              area: 'Sardarpura, Jodhpur',
              activity: 'Groceries and household essentials',
            )
            ..authorizedPersonName = 'Asha Sharma'
            ..businessRelationship = 'Owner'
            ..primaryMobile = '9829012321'
            ..contactEmail = 'asha@example.com'
            ..primaryMobileVerified = true
            ..contactEmailVerified = true;
          final originalLabel = work.selectedProfile!.label;
          final originalDocuments = work.selectedWorkspaceDocuments
              .map((proof) => proof.id)
              .toList();
          final subtitle = profileId == 'salon'
              ? originalLabel
              : 'Grocery / Kirana Shop or Speciality Retail Shop';
          await mount(
            tester,
            route: '/app/work/workspace/requirements',
            work: work,
            viewport: Size(display.width, display.height),
            textScale: display.scale,
          );

          void checkHeader(String title, String subtitle) {
            final bar = find.byType(AppBar);
            final barBounds = tester.getRect(bar);
            expect(barBounds.height, lessThanOrEqualTo(display.height * .3));
            for (final entry in [
              ('work-page-title', title),
              ('work-page-subtitle', subtitle),
            ]) {
              final text = find.byKey(Key(entry.$1));
              expect(tester.widget<Text>(text).data, entry.$2);
              final paragraph = tester.renderObject<RenderParagraph>(
                find.descendant(of: text, matching: find.byType(RichText)),
              );
              expect(paragraph.softWrap, isTrue);
              expect(paragraph.maxLines, isNull);
              expect(paragraph.overflow, isNot(TextOverflow.ellipsis));
              expect(paragraph.didExceedMaxLines, isFalse);
              expect(
                paragraph.textScaler.scale(12),
                closeTo(12 * display.scale, .01),
              );
              final bounds = tester.getRect(text);
              expect(bounds.top, greaterThanOrEqualTo(barBounds.top));
              expect(bounds.bottom, lessThanOrEqualTo(barBounds.bottom));
              expect(bounds.left, greaterThanOrEqualTo(64));
              expect(bounds.right, lessThanOrEqualTo(display.width - 4));
            }
            if (display.scale == 1) {
              expect(tester.widget<AppBar>(bar).toolbarHeight, 88);
            }
            expect(
              find.byKey(const Key('work-back')).hitTestable(),
              findsOneWidget,
            );
            expect(work.selectedProfile!.id, profileId);
            expect(work.selectedProfile!.label, originalLabel);
            expect(
              work.selectedWorkspaceDocuments.map((proof) => proof.id),
              originalDocuments,
            );
            expect(tester.takeException(), isNull);
          }

          Future<void> tap(String key) async {
            final action = find.byKey(Key(key));
            await reveal(tester, action);
            await tester.tap(action);
            await tester.pumpAndSettle();
          }

          Future<void> capture(String page) async {
            if (profileId != 'retailer-grocery') return;
            await captureStoreView(
              tester,
              'r665-header-$page-${display.width.toInt()}-${display.scale}',
            );
          }

          checkHeader('Documents to keep ready', originalLabel);
          await capture('requirements');
          await tap('work-requirements-ready');
          checkHeader('Set up your Workspace', subtitle);
          await capture('contact');
          await reveal(tester, find.byKey(const Key('work-person-name')));
          final name = tester.widget<TextField>(
            find.byKey(const Key('work-person-name')),
          );
          expect(
            name.decoration!.helperText,
            'The authorised person setting up this Workspace',
          );
          expect(name.decoration!.helperMaxLines, 3);
          await tap('work-back');
          checkHeader('Documents to keep ready', originalLabel);
          await tap('work-requirements-ready');
          await tap('work-contact-continue');
          checkHeader('Complete your Workspace', subtitle);
          await capture('details');
          final relationship = find.byKey(
            const Key('work-business-relationship'),
          );
          await reveal(tester, relationship);
          expect(
            find.text('Your relationship with the business'),
            findsOneWidget,
          );
          expect(find.text('Your connection to this business'), findsNothing);
          await tap('work-details-continue');
          checkHeader('Complete your Workspace', subtitle);
          await capture('documents');
          await tap('work-proof-review');
          checkHeader('Complete your Workspace', subtitle);
          await reveal(tester, find.text('Business relationship'));
          expect(find.text('Connection'), findsNothing);
          await capture('review');
          await tap('work-review-edit-contact');
          checkHeader('Set up your Workspace', subtitle);
          expect(find.text('Save and return'), findsOneWidget);
          await tap('work-contact-continue');
          checkHeader('Complete your Workspace', subtitle);
          expect(work.primaryMobileVerified, isTrue);
          expect(work.contactEmailVerified, isTrue);
          expect(work.reviewCaseId, isNull);
        },
      );
    }
  }

  for (final scale in [1.0, 2.0]) {
    for (final scenario in ['pages', 'protected_pdf', 'invalid_pdf', 'late']) {
      testWidgets('r66.8 PDF panel $scenario at $scale', (tester) async {
        const channel = MethodChannel(
          'com.moolsocial.app/work_document_preview',
        );
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        final png = (await tester.runAsync(() async {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder)
            ..drawColor(Colors.white, BlendMode.src);
          final text = TextPainter(
            text: const TextSpan(
              text: 'QA ONLY\nNOT A REAL DOCUMENT\n\nLocal PDF page fixture',
              style: TextStyle(color: MoolColors.navy, fontSize: 28),
            ),
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: 400);
          text.paint(canvas, const Offset(24, 24));
          final picture = recorder.endRecording();
          final image = await picture.toImage(450, 640);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          image.dispose();
          picture.dispose();
          text.dispose();
          return bytes!.buffer.asUint8List();
        }))!;
        Map<String, Object?> result(int page) => {
          'bytes': png,
          'page': page,
          'pages': 2,
          'width': 450,
          'height': 640,
        };
        final calls = <MethodCall>[];
        final late = Completer<Map<String, Object?>>();
        var failing = scenario.endsWith('_pdf');
        messenger.setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'cancel') return null;
          if (scenario == 'late') return late.future;
          if (failing) throw PlatformException(code: scenario);
          return result((call.arguments as Map)['page'] as int);
        });
        addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
        final work = WorkSession(gateway: ReviewWorkGateway())
          ..selectProfile('retailer-grocery')
          ..recoveredDocumentStep = true
          ..saveDetails(
            name: 'QA Retail Store',
            area: 'Jodhpur',
            activity: 'Groceries',
          )
          ..authorizedPersonName = 'QA Owner'
          ..businessRelationship = 'Owner'
          ..primaryMobile = '9829012321'
          ..contactEmail = 'qa@example.com'
          ..primaryMobileVerified = true
          ..contactEmailVerified = true;
        await tester.runAsync(
          () => work.addProof('payout-bank-account', WorkProofSource.upload),
        );
        final original = WorkPickedProof(
          fileName: 'QA-NOT-A-REAL-DOCUMENT.pdf',
          contentType: 'application/pdf',
          bytes: Uint8List.fromList('%PDF-1.4\nMOCK CHANNEL ONLY'.codeUnits),
        );
        work.pickedProofs['payout-bank-account'] = original;
        await mount(
          tester,
          route: '/app/work/workspace/proof',
          work: work,
          viewport: scale == 1 ? const Size(412, 915) : const Size(320, 568),
          textScale: scale,
        );
        final view = find.byKey(
          const Key('work-view-proof-payout-bank-account'),
        );
        await reveal(tester, view);
        await tester.tap(view);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        if (scenario == 'late') {
          expect(find.bySemanticsLabel('Opening PDF page'), findsOneWidget);
          await tester.binding.handlePopRoute();
          await tester.pump(const Duration(milliseconds: 400));
          late.complete(result(0));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('work-document-preview')), findsNothing);
          expect(calls.map((c) => c.method), ['renderPage', 'cancel']);
        } else {
          await tester.pumpAndSettle();
          if (failing) {
            expect(
              find.byKey(const Key('work-document-pdf-retry')).hitTestable(),
              findsOneWidget,
            );
            expect(find.byKey(const Key('work-document-image')), findsNothing);
            if (scenario == 'protected_pdf') {
              expect(find.textContaining('password-protected'), findsOneWidget);
            }
            if (scale == 1) {
              expect(
                tester
                    .getSize(find.byKey(const Key('work-document-preview')))
                    .height,
                lessThan(410),
                reason: 'An error panel must fit its message and controls.',
              );
            }
            await captureStoreView(tester, 'r668-pdf-$scenario-$scale');
            failing = false;
            await tester.tap(find.byKey(const Key('work-document-pdf-retry')));
            await tester.pumpAndSettle();
          }
          expect(find.text('Page 1 of 2'), findsOneWidget);
          expect(
            tester
                .widget<IconButton>(
                  find.byKey(const Key('work-document-pdf-previous')),
                )
                .onPressed,
            isNull,
          );
          for (final key in [
            'work-document-close',
            'work-document-replace',
            'work-document-zoom',
            'work-document-fit',
            'work-document-pdf-next',
          ]) {
            final target = find.byKey(Key(key));
            expect(target.hitTestable(), findsOneWidget);
            expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
          }
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 80)),
          );
          await tester.pumpAndSettle();
          await captureStoreView(tester, 'r668-pdf-page1-$scenario-$scale');
          await tester.tap(find.byKey(const Key('work-document-zoom')));
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<InteractiveViewer>(
                  find.byKey(const Key('work-document-image')),
                )
                .transformationController!
                .value
                .getMaxScaleOnAxis(),
            2,
          );
          await tester.tap(find.byKey(const Key('work-document-pdf-next')));
          await tester.pumpAndSettle();
          expect(find.text('Page 2 of 2'), findsOneWidget);
          expect(
            tester
                .widget<IconButton>(
                  find.byKey(const Key('work-document-pdf-next')),
                )
                .onPressed,
            isNull,
          );
          expect(
            tester
                .widget<InteractiveViewer>(
                  find.byKey(const Key('work-document-image')),
                )
                .transformationController!
                .value
                .getMaxScaleOnAxis(),
            1,
          );
          await tester.tap(find.byKey(const Key('work-document-pdf-previous')));
          await tester.pumpAndSettle();
          expect(find.text('Page 1 of 2'), findsOneWidget);
          await tester.tap(find.byKey(const Key('work-document-replace')));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('work-document-preview')), findsNothing);
          expect(
            find.byKey(const Key('work-proof-source-upload')),
            findsOneWidget,
          );
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
        }
        expect(work.pickedProofs['payout-bank-account'], same(original));
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final display in [
    (width: 412.0, height: 915.0, scale: 1.0),
    (width: 320.0, height: 568.0, scale: 1.4),
    (width: 320.0, height: 568.0, scale: 2.0),
  ]) {
    for (final corrupt in [false, true]) {
      testWidgets(
        'OPPO document image pinned controls ${display.width} ${display.scale} corrupt=$corrupt',
        (tester) async {
          final work = WorkSession(gateway: ReviewWorkGateway())
            ..selectProfile('retailer-grocery')
            ..recoveredDocumentStep = true
            ..saveDetails(
              name: 'Mahadev Traders',
              area: 'Jodhpur',
              activity: 'Groceries',
            )
            ..authorizedPersonName = 'Asha Sharma'
            ..businessRelationship = 'Owner'
            ..primaryMobile = '9829012321'
            ..contactEmail = 'review.owner@example.com'
            ..primaryMobileVerified = true
            ..contactEmailVerified = true;
          await tester.runAsync(
            () => work.addProof('payout-bank-account', WorkProofSource.gallery),
          );
          var bytes = Uint8List.fromList([0, 1, 2]);
          if (!corrupt) {
            bytes = (await tester.runAsync(() async {
              final recorder = ui.PictureRecorder();
              final canvas = Canvas(recorder);
              canvas.drawColor(Colors.white, BlendMode.src);
              final text = TextPainter(
                text: const TextSpan(
                  text:
                      'QA ONLY\nNOT A REAL DOCUMENT\n\nPage top\n\n\n\n\n\n\n\n\nPage bottom',
                  style: TextStyle(
                    color: MoolColors.navy,
                    fontSize: 28,
                    fontFamily: 'Roboto',
                  ),
                ),
                textDirection: TextDirection.ltr,
              )..layout(maxWidth: 550);
              text.paint(canvas, const Offset(24, 24));
              final picture = recorder.endRecording();
              final image = await picture.toImage(600, 1200);
              final result = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              image.dispose();
              picture.dispose();
              text.dispose();
              return result!.buffer.asUint8List();
            }))!;
          }
          final attached = WorkPickedProof(
            fileName: 'QA-NOT-A-REAL-DOCUMENT.png',
            contentType: 'image/png',
            bytes: bytes,
          );
          work.pickedProofs['payout-bank-account'] = attached;
          await mount(
            tester,
            route: '/app/work/workspace/proof',
            work: work,
            viewport: Size(display.width, display.height),
            textScale: display.scale,
          );
          final view = find.byKey(
            const Key('work-view-proof-payout-bank-account'),
          );
          await reveal(tester, view);
          await tester.tap(view);
          await tester.pumpAndSettle();
          await tester.runAsync(() async {
            await Future<void>.delayed(const Duration(milliseconds: 80));
          });
          await tester.pumpAndSettle();
          final actions = find.byKey(const Key('work-document-actions'));
          final title = find.byKey(const Key('work-document-title'));
          expect(tester.widget<Text>(title).data, 'Document');
          expect(
            tester.getRect(title).bottom,
            lessThanOrEqualTo(
              tester.getRect(find.byKey(const Key('work-document-image'))).top,
            ),
          );
          expect(tester.getSize(title).height, lessThanOrEqualTo(40));
          final initialActions = tester.getRect(actions);
          for (final key in [
            'work-document-close',
            'work-document-replace',
            'work-document-zoom',
            'work-document-fit',
          ]) {
            final target = find.byKey(Key(key));
            expect(target.hitTestable(), findsOneWidget);
            expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
            expect(
              tester.getRect(target).bottom,
              lessThanOrEqualTo(display.height - 44),
            );
          }
          final viewer = tester.widget<InteractiveViewer>(
            find.byKey(const Key('work-document-image')),
          );
          expect(
            tester.getSize(find.byKey(const Key('work-document-image'))).height,
            greaterThanOrEqualTo(80),
          );
          if (corrupt) {
            expect(
              find.text(
                'Preview unavailable. Check the original or choose a replacement.',
              ),
              findsOneWidget,
            );
          } else {
            final centre = tester
                .getSize(find.byKey(const Key('work-document-image')))
                .center(Offset.zero);
            final focalPoint = viewer.transformationController!.toScene(centre);
            await tester.tap(find.byKey(const Key('work-document-zoom')));
            await tester.pumpAndSettle();
            expect(
              viewer.transformationController!.value.getMaxScaleOnAxis(),
              2,
            );
            void expectFocalPoint(Offset expected) {
              final actual = viewer.transformationController!.toScene(centre);
              expect(actual.dx, closeTo(expected.dx, .01));
              expect(actual.dy, closeTo(expected.dy, .01));
            }

            expectFocalPoint(focalPoint);
            await captureStoreView(
              tester,
              'r667-document-centred-${display.width}-${display.scale}',
            );
            await tester.drag(
              find.byKey(const Key('work-document-image')),
              const Offset(-35, -35),
            );
            await tester.pumpAndSettle();
            final pannedPoint = viewer.transformationController!.toScene(
              centre,
            );
            for (final expectedScale in [3, 4, 4]) {
              await tester.tap(find.byKey(const Key('work-document-zoom')));
              await tester.pumpAndSettle();
              expect(
                viewer.transformationController!.value.getMaxScaleOnAxis(),
                expectedScale,
              );
              expectFocalPoint(pannedPoint);
            }
            expect(tester.getRect(actions), initialActions);
            await tester.tap(find.byKey(const Key('work-document-fit')));
            await tester.pumpAndSettle();
            expect(viewer.transformationController!.value, Matrix4.identity());
          }
          await captureStoreView(
            tester,
            'r666-document-${display.width}-${display.scale}-corrupt-$corrupt',
          );
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('work-document-preview')), findsNothing);
          expect(work.pickedProofs['payout-bank-account'], same(attached));
          await reveal(tester, view);
          await tester.tap(view);
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('work-document-replace')));
          await tester.pumpAndSettle();
          final cancel = find.byKey(const Key('work-proof-source-cancel'));
          expect(cancel.hitTestable(), findsOneWidget);
          await tester.tap(cancel);
          await tester.pumpAndSettle();
          expect(work.pickedProofs['payout-bank-account'], same(attached));
          expect(tester.takeException(), isNull);
        },
      );
    }
    testWidgets(
      'REG4552 REG4553 PDF replacement recovery ${display.width} ${display.scale}',
      (tester) async {
        XFile? selection = XFile.fromData(
          Uint8List.fromList('QA ONLY - NOT A PDF'.codeUnits),
          path: 'QA-NOT-A-PDF.PDF',
        );
        final work =
            WorkSession(
                gateway: ReviewWorkGateway(),
                proofPicker: NativeWorkProofPicker(
                  documentPicker: () async => selection,
                ),
              )
              ..selectProfile('retailer-grocery')
              ..recoveredDocumentStep = true
              ..saveDetails(
                name: 'QA Kirana',
                area: 'Jaipur',
                activity: 'Groceries',
              )
              ..authorizedPersonName = 'QA Owner'
              ..primaryMobile = '9829012321'
              ..contactEmail = 'qa@example.com'
              ..primaryMobileVerified = true
              ..contactEmailVerified = true
              ..declarationAccepted = true;
        final original = WorkPickedProof(
          fileName: 'QA-original.jpg',
          contentType: 'image/jpeg',
          bytes: Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9]),
        );
        work.addedProofs['shop-front'] = 'original-reference';
        work.pickedProofs['shop-front'] = original;
        await mount(
          tester,
          route: '/app/work/workspace/proof',
          work: work,
          viewport: Size(display.width, display.height),
          textScale: display.scale,
        );
        Future<void> tap(String key) async {
          final target = find.byKey(Key(key));
          await reveal(tester, target);
          expect(target.hitTestable(), findsOneWidget);
          await tester.tap(target);
          await tester.pumpAndSettle();
        }

        await tap('work-replace-proof-shop-front');
        final cancel = find.byKey(const Key('work-proof-source-cancel'));
        expect(cancel.hitTestable(), findsOneWidget);
        await tap('work-proof-source-upload');
        expect(cancel.hitTestable(), findsOneWidget);
        final cancelAfterError = tester.getRect(cancel);
        final title = find.text('Add Shop address document');
        expect(title.hitTestable(), findsOneWidget);
        expect(tester.widget<Text>(title).maxLines, isNull);
        expect(
          tester.widget<Text>(title).overflow,
          isNot(TextOverflow.ellipsis),
        );
        final titleParagraph = tester.renderObject<RenderParagraph>(
          find.descendant(of: title, matching: find.byType(RichText)),
        );
        expect(titleParagraph.didExceedMaxLines, isFalse);
        expect(tester.getRect(title).right, lessThanOrEqualTo(display.width));
        final error = find.byKey(const Key('work-proof-source-error'));
        expect(error.hitTestable(), findsOneWidget);
        expect(
          tester.widget<Text>(error).data,
          'This PDF could not be opened. Choose another copy.',
        );
        expect(tester.widget<Text>(error).maxLines, isNull);
        expect(
          tester.widget<Text>(error).overflow,
          isNot(TextOverflow.ellipsis),
        );
        expect(work.addedProofs['shop-front'], 'original-reference');
        expect(work.pickedProofs['shop-front'], same(original));
        expect(work.declarationAccepted, isTrue);
        for (final option in const {
          'camera': 'Camera',
          'gallery': 'Photo gallery',
          'upload': 'PDF or image',
          'cloud': 'Cloud files',
        }.entries) {
          final tile = find.byKey(Key('work-proof-source-${option.key}'));
          final label = find.descendant(
            of: tile,
            matching: find.text(option.value),
          );
          expect(label, findsOneWidget);
          expect(tester.widget<Text>(label).maxLines, isNull);
          expect(
            tester.widget<Text>(label).overflow,
            isNot(TextOverflow.ellipsis),
          );
          final paragraph = tester.renderObject<RenderParagraph>(
            find.descendant(of: label, matching: find.byType(RichText)),
          );
          expect(paragraph.didExceedMaxLines, isFalse);
          expect(tester.getRect(tile).left, greaterThanOrEqualTo(0));
          expect(tester.getRect(tile).right, lessThanOrEqualTo(display.width));
          expect(tester.getSize(tile).height, greaterThanOrEqualTo(48));
        }
        final cameraTop = tester
            .getTopLeft(find.byKey(const Key('work-proof-source-camera')))
            .dy;
        final uploadTop = tester
            .getTopLeft(find.byKey(const Key('work-proof-source-upload')))
            .dy;
        expect(
          uploadTop,
          display.scale == 2 ? greaterThan(cameraTop) : cameraTop,
        );
        await captureStoreView(
          tester,
          'r6612-pdf-replacement-error-${display.width}-${display.scale}',
        );
        for (final key in [
          'work-proof-source-upload',
          'work-proof-source-cancel',
        ]) {
          final target = find.byKey(Key(key));
          await reveal(tester, target);
          expect(target.hitTestable(), findsOneWidget);
          expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
          expect(
            tester.getRect(target).bottom,
            lessThanOrEqualTo(display.height - 44),
          );
        }
        selection = null;
        expect(tester.getRect(cancel), cancelAfterError);
        await captureStoreView(
          tester,
          'r6612-pdf-replacement-controls-${display.width}-${display.scale}',
        );
        await tap('work-proof-source-upload');
        expect(error, findsNothing);
        await tap('work-proof-source-cancel');
        expect(
          find.byKey(const Key('work-proof-source-safe-area')),
          findsNothing,
        );
        expect(work.addedProofs['shop-front'], 'original-reference');
        expect(work.pickedProofs['shop-front'], same(original));
        expect(work.declarationAccepted, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'R669 document feedback stays with its document ${display.width} ${display.scale}',
      (tester) async {
        final gateway = ReviewWorkGateway()..failProof = true;
        final work = WorkSession(gateway: gateway)
          ..selectProfile('retailer-grocery')
          ..recoveredDocumentStep = true
          ..saveDetails(
            name: 'Mahadev Traders',
            area: 'Jaipur',
            activity: 'Groceries',
          )
          ..authorizedPersonName = 'Asha Sharma'
          ..primaryMobile = '9829012321'
          ..contactEmail = 'asha@example.com'
          ..primaryMobileVerified = true
          ..contactEmailVerified = true;
        await mount(
          tester,
          route: '/app/work/workspace/proof',
          work: work,
          viewport: Size(display.width, display.height),
          textScale: display.scale,
        );
        final beforeTop = tester
            .getRect(find.byKey(const Key('work-proof-screen')))
            .top;
        Future<void> tap(String key) async {
          final action = find.byKey(Key(key));
          await reveal(tester, action);
          await tester.tap(action);
          await tester.pumpAndSettle();
        }

        await tap('work-add-proof-shop-front');
        await tap('work-proof-source-upload');
        expect(
          find.text(
            'Document not added. Choose the same file or another option and try again.',
          ),
          findsOneWidget,
        );
        expect(work.addedProofs, isEmpty);
        await tap('work-proof-source-upload');
        expect(work.addedProofs.containsKey('shop-front'), isTrue);
        expect(work.noticeMessage, isNull);
        expect(find.byKey(const Key('work-notice')), findsNothing);
        expect(
          tester.getRect(find.byKey(const Key('work-proof-screen'))).top,
          beforeTop,
        );
        final view = find.byKey(const Key('work-view-proof-shop-front'));
        await captureStoreView(
          tester,
          'r669-document-attached-${display.scale}',
        );
        await reveal(tester, view);
        expect(view.hitTestable(), findsOneWidget);
        await tap('work-view-proof-shop-front');
        expect(find.byKey(const Key('work-document-preview')), findsOneWidget);
        expect(find.byKey(const Key('work-notice')), findsNothing);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(work.addedProofs.containsKey('shop-front'), isTrue);
        expect(
          tester.getRect(find.byKey(const Key('work-proof-screen'))).top,
          beforeTop,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'R669 unsent clarification preserves submitted information ${display.width} ${display.scale}',
      (tester) async {
        final gateway = ReviewWorkGateway()
          ..reviewResultStatus = WorkRemoteReviewStatus.pending
          ..reviewResultReason = 'Please confirm the business name.';
        final work = WorkSession(gateway: gateway)
          ..selectProfile('retailer-grocery')
          ..saveDetails(
            name: 'Mahadev Traders',
            area: 'Jaipur',
            activity: 'Groceries',
          )
          ..authorizedPersonName = 'Asha Sharma'
          ..businessRelationship = 'Owner'
          ..primaryMobile = '9829012321'
          ..contactEmail = 'asha@example.com'
          ..primaryMobileVerified = true
          ..contactEmailVerified = true
          ..declarationAccepted = true;
        expect(await tester.runAsync(work.submitProfile), isTrue);
        await tester.runAsync(work.checkReview);
        final submitted = work.submittedProfile;
        final caseId = work.reviewCaseId;
        await mount(
          tester,
          route: '/app/work/workspace/proof',
          work: work,
          viewport: Size(display.width, display.height),
          textScale: display.scale,
        );
        Future<void> tap(String key) async {
          final action = find.byKey(Key(key));
          await reveal(tester, action);
          expect(action.hitTestable(), findsOneWidget);
          await tester.tap(action);
          await tester.pumpAndSettle();
        }

        expect(
          find.byKey(const Key('work-review-unsent-changes')),
          findsNothing,
        );
        await tap('work-inline-update-details');
        await tap('work-back');
        expect(
          find.byKey(const Key('work-review-unsent-changes')),
          findsNothing,
        );
        await tap('work-inline-update-details');
        final name = find.byKey(const Key('work-name'));
        await reveal(tester, name);
        await tester.enterText(name, 'Mahadev Retail');
        await tap('work-back');
        final cue = find.byKey(const Key('work-review-unsent-changes'));
        await reveal(tester, cue);
        expect(cue, findsOneWidget);
        expect(work.submittedProfile, same(submitted));
        expect(
          find.descendant(
            of: find.byKey(const Key('work-submitted-summary')),
            matching: find.text('Mahadev Traders'),
          ),
          findsOneWidget,
        );
        expect(work.reviewCaseId, caseId);
        expect(gateway.submissionCalls, 1);
        await captureStoreView(
          tester,
          'r669-clarification-unsent-${display.scale}',
        );
        await tap('work-review-resume-changes');
        expect(
          find.byKey(const Key('work-review-corrections')),
          findsOneWidget,
        );
        expect(find.text('Mahadev Retail'), findsOneWidget);
        expect(work.declarationAccepted, isFalse);
        expect(work.submittedProfile, same(submitted));
        expect(gateway.submissionCalls, 1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'OPPO S06 inline review corrections ${display.width} ${display.scale}',
      (tester) async {
        final gateway = ReviewWorkGateway()
          ..reviewResultStatus = WorkRemoteReviewStatus.pending;
        final work = WorkSession(gateway: gateway)
          ..selectProfile('retailer-grocery')
          ..recoveredDocumentStep = true
          ..saveDetails(
            name: 'Mahadev Traders',
            area: 'Sardarpura, Jodhpur',
            activity: 'Groceries and household essentials',
          )
          ..authorizedPersonName = 'Asha Sharma'
          ..businessRelationship = 'Authorized representative'
          ..primaryMobile = '9829012321'
          ..contactEmail = 'review.owner@example.com'
          ..primaryMobileVerified = true
          ..contactEmailVerified = true;
        await mount(
          tester,
          route: '/app/work/workspace/proof',
          work: work,
          viewport: Size(display.width, display.height),
          textScale: display.scale,
        );
        await tester.runAsync(
          () => work.addProof('payout-bank-account', WorkProofSource.upload),
        );
        await tester.pumpAndSettle();
        Future<void> tap(String key) async {
          final action = find.byKey(Key(key));
          await reveal(tester, action);
          expect(action.hitTestable(), findsOneWidget);
          await tester.tap(action);
          await tester.pumpAndSettle();
        }

        await tap('work-proof-review');
        final summary = find.byKey(const Key('work-review-corrections'));
        expect(find.text('Edit details'), findsNothing);
        expect(find.text('Edit documents'), findsNothing);
        expect(find.text('Edit contact'), findsNothing);
        for (final key in [
          'work-review-edit-details',
          'work-review-edit-contact',
          'work-review-edit-documents',
        ]) {
          final edit = find.byKey(Key(key));
          expect(find.descendant(of: summary, matching: edit), findsOneWidget);
          expect(tester.getSize(edit).height, greaterThanOrEqualTo(48));
          expect(
            find.descendant(of: edit, matching: find.text('Edit')),
            findsOneWidget,
          );
        }
        await captureStoreView(
          tester,
          'r665-review-first-${display.width.toInt()}-${display.scale}',
        );
        final file = find.byKey(
          const Key('work-review-file-payout-bank-account'),
        );
        await reveal(tester, file);
        expect(
          tester.widget<Text>(file).data,
          work.pickedProofs['payout-bank-account']!.fileName,
        );
        expect(
          tester.widget<Text>(file).overflow,
          isNot(TextOverflow.ellipsis),
        );
        expect(find.text('1 attached'), findsOneWidget);
        await captureStoreView(
          tester,
          'r665-review-documents-${display.width.toInt()}-${display.scale}',
        );
        await tap('work-review-view-payout-bank-account');
        expect(find.text('review-proof.pdf'), findsWidgets);
        expect(find.text('Document'), findsWidgets);
        expect(find.byKey(const Key('work-document-image')), findsNothing);
        expect(
          find.byKey(const Key('work-document-close')).hitTestable(),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('work-document-replace')).hitTestable(),
          findsOneWidget,
        );
        expect(
          find.text('This PDF could not be opened. Choose another copy.'),
          findsOneWidget,
        );
        await reveal(tester, find.text('Close'));
        expect(find.text('Close').hitTestable(), findsOneWidget);
        expect(
          tester.getRect(find.text('Close')).bottom,
          lessThanOrEqualTo(display.height - 44),
        );
        await captureStoreView(
          tester,
          'r665-review-preview-${display.width.toInt()}-${display.scale}',
        );
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        expect(summary, findsOneWidget);
        await tester.drag(
          find.byKey(const Key('work-proof-screen')),
          const Offset(0, 3000),
        );
        await tester.pumpAndSettle();
        await tap('work-submit-profile');
        final guidance = find.byKey(
          const Key('work-review-declaration-guidance'),
        );
        expect(guidance.hitTestable(), findsOneWidget);
        final declaration = find.byKey(const Key('work-declaration'));
        expect(declaration.hitTestable(), findsOneWidget);
        expect(
          tester.getRect(guidance).bottom,
          lessThanOrEqualTo(
            tester.getRect(find.byKey(const Key('work-sticky-action-bar'))).top,
          ),
        );
        expect(work.errorMessage, isNull);
        expect(work.reviewCaseId, isNull);
        expect(gateway.lastSubmission, isNull);
        expect(work.declarationAccepted, isFalse);
        await captureStoreView(
          tester,
          'r665-review-confirmation-${display.width.toInt()}-${display.scale}',
        );
        await tap('work-declaration');
        expect(guidance, findsNothing);
        expect(work.declarationAccepted, isTrue);
        await tap('work-review-edit-details');
        expect(work.declarationAccepted, isFalse);
        await reveal(tester, find.byKey(const Key('work-name')));
        await tester.enterText(
          find.byKey(const Key('work-name')),
          'Mahadev Daily Store',
        );
        await tap('work-details-continue');
        expect(summary, findsOneWidget);
        expect(find.text('Mahadev Daily Store'), findsOneWidget);
        await tap('work-review-edit-documents');
        await tap('work-back');
        expect(summary, findsOneWidget);
        expect(
          work.pickedProofs['payout-bank-account']!.fileName,
          'review-proof.pdf',
        );
        await tap('work-review-edit-contact');
        expect(find.text('Save and return'), findsOneWidget);
        await tap('work-contact-continue');
        expect(summary, findsOneWidget);
        expect(work.primaryMobileVerified, isTrue);
        expect(work.contactEmailVerified, isTrue);
        expect(gateway.lastSubmission, isNull);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final page in [
    'choose',
    'requirements',
    'contact',
    'details',
    'documents',
    'source',
    'review',
    'pending',
    'clarification',
    'rejected',
    'approved',
  ]) {
    testWidgets('Workspace overnight visual - $page', (tester) async {
      final gateway = ReviewWorkGateway()
        ..reviewResultStatus = WorkRemoteReviewStatus.pending;
      final work = WorkSession(gateway: gateway)
        ..selectFamily('products-trade')
        ..selectProfile('retailer-grocery')
        ..saveDetails(
          name: 'Mahadev Traders',
          area: 'Sardarpura, Jodhpur',
          activity: 'Groceries and household essentials',
        )
        ..authorizedPersonName = 'Asha Sharma'
        ..businessRelationship = 'Owner'
        ..primaryMobile = '9829012321'
        ..contactEmail = 'asha@example.com'
        ..primaryMobileVerified = true
        ..contactEmailVerified = page != 'contact';
      if (['pending', 'clarification', 'rejected', 'approved'].contains(page)) {
        work.reviewCaseId = 'WP-REVIEW-206';
        work.reviewStage = WorkReviewStage.gstPending;
        if (page == 'clarification') {
          gateway.reviewResultReason =
              'Please provide a clearer shop address document.';
        } else if (page == 'rejected') {
          work.remoteReviewStatus = WorkRemoteReviewStatus.rejected;
          work.reviewReason = 'The business address could not be confirmed.';
        } else if (page == 'approved') {
          gateway.reviewResultStatus = WorkRemoteReviewStatus.approved;
        }
      }
      final route = switch (page) {
        'choose' => '/app/work/workspace/choose',
        'requirements' => '/app/work/workspace/requirements',
        'contact' => '/app/work/workspace/contact',
        _ => '/app/work/workspace/proof',
      };
      await mount(
        tester,
        route: route,
        work: work,
        viewport: const Size(412, 915),
        textScale: 1,
        bottomInset: 34,
      );
      Future<void> tap(String key) async {
        await reveal(tester, find.byKey(Key(key)));
        await tester.tap(find.byKey(Key(key)));
        await tester.pumpAndSettle();
      }

      if (['documents', 'source', 'review'].contains(page)) {
        await tap('work-details-continue');
        if (page == 'source') {
          await tap('work-add-proof-personal-kyc');
        } else if (page == 'review') {
          await tap('work-add-proof-shop-front');
          await tap('work-proof-source-upload');
          await tap('work-proof-review');
        }
      }
      expect(tester.takeException(), isNull);
      if (page == 'approved') {
        expect(
          find.byKey(const Key('work-workspace-dashboard')),
          findsOneWidget,
        );
        expect(find.text('Workspace approved'), findsNothing);
      }
      await captureStoreView(tester, 'workspace-$page');
      if (page == 'review') {
        await reveal(tester, find.byKey(const Key('work-declaration')));
        await captureStoreView(tester, 'workspace-review-consent');
        await tap('work-review-edit-documents');
        await tap('work-view-proof-shop-front');
        expect(find.text('review-proof.pdf'), findsWidgets);
        await captureStoreView(tester, 'workspace-document-preview');
      } else if (page == 'requirements') {
        await reveal(
          tester,
          find.byKey(const Key('work-gst-compliance-guidance')),
        );
        await captureStoreView(tester, 'workspace-requirements-guidance');
      } else if (page == 'contact') {
        await tap('work-contact-email-send-otp');
        final code = find.byKey(const Key('work-contact-email-otp'));
        await reveal(tester, code);
        await tester.tap(code);
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        await tester.pumpAndSettle();
        await reveal(
          tester,
          find.byKey(const Key('work-contact-email-confirm-otp')),
        );
        expect(
          tester
              .getBottomRight(
                find.byKey(const Key('work-contact-email-confirm-otp')),
              )
              .dy,
          lessThanOrEqualTo(635),
        );
        await captureStoreView(tester, 'workspace-contact-otp-keyboard');
      }
      expect(tester.takeException(), isNull);
    }, skip: !captureStoreViewV2);
  }

  testWidgets(
    'Store queue opens the chosen order without changing the previous order',
    (tester) async {
      final work = storeViewFixture();
      work.workspaceOrders.add(
        WorkspaceOrderRecord(
          id: 'APP-1044',
          customer: 'Sita · 9123456789',
          items: 'Atta × 1',
          quantities: const {},
          amount: 310,
          payment: 'Paid online',
          source: 'App',
          fulfilment: 'Pickup',
          address: '',
          stage: 'Confirmed',
          needsDelivery: false,
          createdAt: DateTime.now(),
          actionDeadline: DateTime.now().add(const Duration(seconds: 60)),
        ),
      );
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: const Size(412, 915),
        textScale: 1,
        bottomInset: 34,
      );
      await tester.tap(find.byKey(const Key('work-store-orders')));
      await tester.pumpAndSettle();
      final open = find.byKey(const Key('work-order-open-APP-1044'));
      await reveal(tester, open);
      await tester.tap(open);
      await tester.pumpAndSettle();
      expect(work.currentWorkspaceOrderId, 'APP-1044');
      expect(work.workspaceOrderCustomer, 'Sita · 9123456789');
      expect(work.workspaceOrderStage, 'Confirmed');
      expect(work.workspaceOrders.first.stage, 'Confirmed');
      await reveal(tester, find.text('Accept'));
      await captureStoreView(tester, '29-selected-second-order');
      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();
      expect(work.workspaceOrderStage, 'Preparing');
      expect(work.workspaceOrders.first.stage, 'Confirmed');
      expect(work.workspaceOrders.last.stage, 'Preparing');
      expect(tester.takeException(), isNull);
    },
  );

  for (final display in [
    (412.0, 915.0, 1.0),
    (320.0, 640.0, 2.0),
    (320.0, 568.0, 1.4),
  ]) {
    for (final reduced in [false, true]) {
      testWidgets(
        'Store finish confirmed figures and stable actions $display reduced=$reduced',
        (tester) async {
          tester.platformDispatcher.accessibilityFeaturesTestValue =
              FakeAccessibilityFeatures(disableAnimations: reduced);
          addTearDown(
            tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
          );
          final work = storeViewFixture();
          await mount(
            tester,
            route: '/app/work/workspace/dashboard',
            work: work,
            viewport: Size(display.$1, display.$2),
            textScale: display.$3,
            bottomInset: 34,
          );
          final metric = find.byKey(const Key('work-pulse-sales'));
          Finder renderedLabel(String label) => find.descendant(
            of: metric,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Text &&
                  widget.data?.replaceAll(RegExp(r'\s+'), '') ==
                      label.replaceAll(RegExp(r'\s+'), ''),
            ),
          );
          final motion = find.byKey(const Key('work-pulse-sales-value-motion'));
          final action = find.byKey(const Key('work-activity-order-accept'));
          final metricBounds = tester.getRect(metric);
          final actionBounds = tester.getRect(action);
          double displacement() =>
              tester.widget<Transform>(motion).transform.entry(1, 3);
          expect(displacement(), 0);
          final band = tester.widget<Material>(
            find.byKey(const Key('work-store-finance-material')),
          );
          final surface = band.color!;
          expect(surface, MoolColors.navy);
          for (final label in ['₹28,450', 'Sales today', 'View statement']) {
            final text = renderedLabel(label);
            final paragraph = find.descendant(
              of: text,
              matching: find.byType(RichText),
            );
            final color = tester.widget<RichText>(paragraph).text.style!.color!;
            final light = color.computeLuminance();
            final dark = surface.computeLuminance();
            expect((light + .05) / (dark + .05), greaterThan(4.6));
          }
          final control = tester.widget<InkWell>(metric);
          expect(
            control.overlayColor!.resolve({WidgetState.pressed}),
            Colors.white24,
          );
          if (reduced) expect(control.splashFactory, NoSplash.splashFactory);
          final pressedSurface = Color.alphaBlend(Colors.white24, surface);
          expect(
            (const Color(0xFFDADAF5).computeLuminance() + .05) /
                (pressedSurface.computeLuminance() + .05),
            greaterThan(4.6),
          );
          final press = await tester.startGesture(tester.getCenter(metric));
          await tester.pump(const Duration(milliseconds: 90));
          await captureStoreView(
            tester,
            'finish-pressed-${display.$1}-${display.$3}-$reduced',
          );
          await press.cancel();
          await tester.pumpAndSettle();
          expect(work.currentWorkspaceOrderId, 'APP-1043');
          work.workspaceSalesToday = 28550;
          work.setWorkspaceMoneyPeriod('Today');
          await tester.pump();
          expect(renderedLabel('₹28,550'), findsOneWidget);
          expect(renderedLabel('₹28,450'), findsNothing);
          expect(displacement(), reduced ? 0 : greaterThan(0));
          expect(tester.widget<Transform>(motion).transformHitTests, isFalse);
          expect(tester.getRect(metric), metricBounds);
          expect(tester.getRect(action), actionBounds);
          await tester.pump(const Duration(milliseconds: 90));
          await captureStoreView(
            tester,
            'finish-motion-${display.$1}-${display.$3}-$reduced',
          );
          work.workspaceSalesToday = 28700;
          work.setWorkspaceMoneyPeriod('Today');
          await tester.pump();
          expect(renderedLabel('₹28,700'), findsOneWidget);
          expect(renderedLabel('₹28,550'), findsNothing);
          await tester.pump(const Duration(milliseconds: 400));
          expect(displacement(), 0);
          expect(work.currentWorkspaceOrderId, 'APP-1043');
          expect(work.workspaceOrderStage, 'Confirmed');
          expect(tester.getRect(action), actionBounds);
          work.setWorkspaceMoneyPeriod('Today');
          await tester.pump();
          expect(
            displacement(),
            0,
            reason: 'Unchanged data must not replay motion',
          );
          await captureStoreView(
            tester,
            'finish-dashboard-${display.$1}-${display.$3}-$reduced',
          );
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('Store finish background and first tap continuity $display', (
      tester,
    ) async {
      final work = storeViewFixture();
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: Size(display.$1, display.$2),
        textScale: display.$3,
        bottomInset: 34,
      );
      final motion = find.byKey(const Key('work-pulse-sales-value-motion'));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      work.workspaceSalesToday = 30000;
      work.setWorkspaceMoneyPeriod('Today');
      await tester.pump();
      expect(tester.widget<Transform>(motion).transform.entry(1, 3), 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(tester.widget<Transform>(motion).transform.entry(1, 3), 0);
      await tester.tap(find.byKey(const Key('work-pulse-sales')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-store-statement')), findsOneWidget);
      final selected = find.byKey(const Key('work-shortcut-statement'));
      final button = tester.widget<TextButton>(selected);
      expect(button.onPressed, isNull);
      expect(
        button.style!.backgroundColor!.resolve({WidgetState.disabled}),
        MoolColors.navy,
      );
      final selectedText = tester.widget<Text>(
        find.descendant(of: selected, matching: find.byType(Text)),
      );
      expect(selectedText.style!.color, Colors.white);
      await captureStoreView(
        tester,
        'finish-statement-${display.$1}-${display.$3}',
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-workspace-dashboard')), findsOneWidget);
      expect(work.currentWorkspaceOrderId, 'APP-1043');
      await tester.tap(find.byKey(const Key('work-pulse-dues')));
      await tester.pumpAndSettle();
      final workingSurface = tester.widget<Material>(
        find.byKey(const Key('work-first-tap-working-surface')),
      );
      expect(workingSurface.color, Colors.white);
      for (final label in ['Collect dues', 'Meena']) {
        final text = find.descendant(
          of: find.byKey(const Key('work-store-dues')),
          matching: find.text(label),
        );
        final paragraph = find.descendant(
          of: text,
          matching: find.byType(RichText),
        );
        expect(
          tester.widget<RichText>(paragraph).text.style!.color,
          MoolColors.ink,
        );
      }
      await captureStoreView(tester, 'finish-dues-${display.$1}-${display.$3}');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(work.currentWorkspaceOrderId, 'APP-1043');
      expect(tester.takeException(), isNull);
    });

    testWidgets('Order time UI unavailable and Back $display', (tester) async {
      final work = storeViewFixture();
      final before = work.currentWorkspaceOrder;
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: Size(display.$1, display.$2),
        textScale: display.$3,
        bottomInset: 24,
      );
      await captureStoreView(
        tester,
        'time-dashboard-${display.$1}-${display.$3}',
      );
      if (display.$3 == 1) {
        expect(find.text('Aashirvaad Atta').hitTestable(), findsOneWidget);
      }
      await tester.tap(find.byKey(const Key('work-order-more-time')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-order-time-sheet')), findsOneWidget);
      expect(
        find.text(
          'Cannot request more time right now. The current time still applies.',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('work-order-time-request')),
            )
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
      await captureStoreView(
        tester,
        'time-unavailable-${display.$1}-${display.$3}',
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(work.currentWorkspaceOrder, same(before));
      expect(find.byKey(const Key('work-order-time-sheet')), findsNothing);
    });

    testWidgets('Order time UI request confirmation $display', (tester) async {
      final gateway = _TimingFixtureGateway();
      final work = storeViewFixture(gateway);
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: Size(display.$1, display.$2),
        textScale: display.$3,
        bottomInset: 24,
      );
      await tester.tap(find.byKey(const Key('work-order-more-time')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('work-order-time-request')),
      );
      await tester.tap(find.byKey(const Key('work-order-time-request')));
      await tester.pumpAndSettle();
      expect(find.text('Time confirmed'), findsOneWidget);
      expect(gateway.requests, hasLength(1));
      expect(work.currentWorkspaceOrder!.fulfilmentDeadline, isNotNull);
      expect(work.workspaceOrderStage, 'Confirmed');
      expect(work.workspaceInvoices, isEmpty);
      expect(tester.takeException(), isNull);
      await captureStoreView(
        tester,
        'time-confirmed-${display.$1}-${display.$3}',
      );
    });
  }

  testWidgets('Order time UI uncertain retry and request identity', (
    tester,
  ) async {
    final gateway = _TimingFixtureGateway();
    final pending = Completer<WorkOrderTimeResult>();
    gateway.respond = (_) => pending.future;
    final work = storeViewFixture(gateway);
    final original = work.currentWorkspaceOrder!.actionDeadline;
    await mount(
      tester,
      route: '/app/work/workspace/dashboard',
      work: work,
      viewport: const Size(412, 915),
      textScale: 1,
      bottomInset: 24,
    );
    await tester.tap(find.byKey(const Key('work-order-more-time')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-order-time-request')));
    await tester.pump();
    expect(find.text('Checking request…'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
    final pendingText = tester.widget<RichText>(
      find.descendant(
        of: find.byKey(const Key('work-order-time-request')),
        matching: find.byType(RichText),
      ),
    );
    expect(pendingText.text.style?.color, MoolColors.navy);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('work-order-time-request')),
          )
          .style!
          .foregroundColor!
          .resolve({WidgetState.disabled}),
      MoolColors.navy,
    );
    await captureStoreView(tester, 'time-request-pending');
    pending.completeError(StateError('network uncertain'));
    await tester.pumpAndSettle();
    expect(find.text('Retry request'), findsOneWidget);
    expect(work.currentWorkspaceOrder!.actionDeadline, original);
    expect(work.hasPendingOrderTime, isTrue);
    await captureStoreView(tester, 'time-retry');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('work-activity-order-accept')),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const Key('work-order-more-time')));
    await tester.pumpAndSettle();
    gateway.respond = null;
    await tester.tap(find.byKey(const Key('work-order-time-request')));
    await tester.pumpAndSettle();
    expect(gateway.requests, hasLength(2));
    expect(
      gateway.requests.first.operationId,
      gateway.requests.last.operationId,
    );
    expect(find.text('Time confirmed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Store View v2 - zero tap working centre', (tester) async {
    await mount(
      tester,
      route: '/app/work/workspace/dashboard',
      work: storeViewFixture(),
      viewport: const Size(412, 915),
      textScale: 1,
      bottomInset: 34,
    );
    for (final label in [
      'View statement',
      'Collect dues',
      'Settle',
      'Restock',
      'Track stock',
      'Group Bulk Buying',
      'Send store link',
      'Promote store',
      'Post requirement',
      'Accept',
      'Reject',
    ]) {
      expect(find.text(label).hitTestable(), findsOneWidget, reason: label);
    }
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Buy Direct'), findsNothing);
    expect(find.byKey(const Key('work-incoming-purchases')), findsOneWidget);
    expect(find.text('More'), findsNothing);
    expect(find.text('Open · Public'), findsNothing);
    expect(find.byKey(const Key('work-dashboard-hero')), findsNothing);
    expect(tester.takeException(), isNull);
    await captureStoreView(tester, '01-dashboard');
  });

  for (final entry in <(String, String, String)>[
    ('work-store-orders', 'work-orders-destination', '02-customer-orders'),
    (
      'work-store-sell',
      'work-dashboard-counter-order-screen',
      '03-counter-sale',
    ),
    ('work-store-stock', 'work-dashboard-catalogue-screen', '04-stock'),
    ('work-pulse-sales', 'work-store-statement', '05-statement'),
    ('work-pulse-dues', 'work-store-dues', '06-collect-dues'),
    ('work-pulse-settlement', 'work-money-destination', '07-settlement'),
    ('work-quick-buy', 'work-store-procurement-screen', '08-restock'),
    ('work-incoming-purchases', '', '09-track-stock'),
    ('work-quick-group-buy', '', '10-group-bulk-buying'),
    ('work-quick-store-link', 'work-store-link', '11-store-link'),
    ('work-quick-promote', 'work-store-offers-screen', '12-promote-store'),
    (
      'work-quick-requirement',
      'work-requirement-selector',
      '17-post-requirement',
    ),
  ]) {
    testWidgets('Store View v2 - first tap ${entry.$3} and Back', (
      tester,
    ) async {
      final work = storeViewFixture();
      if (entry.$1 == 'work-store-sell') {
        work.workspaceCatalogueItems
          ..clear()
          ..addAll(
            workspaceMasterCatalogue.map(
              (product) => product.copyWith(stock: 24),
            ),
          );
      }
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: const Size(412, 915),
        textScale: 1,
        bottomInset: 34,
      );
      await tester.tap(find.byKey(Key(entry.$1)));
      await tester.pumpAndSettle();
      if (entry.$2.isNotEmpty) {
        expect(find.byKey(Key(entry.$2)), findsOneWidget);
      }
      if (entry.$1 == 'work-incoming-purchases') {
        expect(find.text('Purchase updates unavailable'), findsOneWidget);
      }
      if (entry.$1 != 'work-quick-requirement') {
        final expectedTab = switch (entry.$1) {
          'work-store-orders' => 'orders',
          'work-store-sell' => 'sell',
          'work-store-stock' ||
          'work-quick-buy' ||
          'work-incoming-purchases' ||
          'work-quick-group-buy' => 'stock',
          _ => 'store',
        };
        expect(
          tester
              .widget<MoolLocalNavigationRail>(
                find.byKey(const Key('work-local-navigation')),
              )
              .activeId,
          expectedTab,
        );
      }
      expect(tester.takeException(), isNull);
      await captureStoreView(tester, entry.$3);
      // A clean first view has no submitted transaction or draft to discard.
      if (entry.$1 == 'work-quick-buy' ||
          entry.$1 == 'work-quick-requirement') {
        await tester.binding.handlePopRoute();
      } else {
        await tester.tap(find.byKey(const Key('work-operation-back')));
      }
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-workspace-dashboard')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Store and Stock remain one-tap parent returns on child destinations',
    (tester) async {
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: liveStore(),
      );
      await tester.tap(find.byKey(const Key('work-pulse-sales')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-store-statement')), findsOneWidget);
      await tester.tap(find.byKey(const Key('work-store-home')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-store-activity-deck')), findsOneWidget);
      await tester.tap(find.byKey(const Key('work-quick-buy')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('work-store-stock')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-dashboard-catalogue-screen')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('work-store-procurement-screen')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final state in WorkspaceStoreState.values) {
    testWidgets('quiet Store distinguishes private and $state availability', (
      tester,
    ) async {
      final work = liveStore()
        ..workspaceStoreState = state
        ..workspaceVisibleToCustomers = false
        ..workspaceAcceptingOrders = state == WorkspaceStoreState.open;
      await mount(tester, route: '/app/work/workspace/dashboard', work: work);
      expect(
        find.text(switch (state) {
          WorkspaceStoreState.open => 'Your store is private',
          WorkspaceStoreState.paused => 'Orders are paused',
          WorkspaceStoreState.off => 'Your store is off',
        }),
        findsOneWidget,
      );
      expect(find.text('Ready for orders'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  for (final display in [
    (width: 412.0, height: 915.0, scale: 1.0),
    (width: 320.0, height: 568.0, scale: 1.4),
  ]) {
    for (final state in WorkspaceStoreState.values) {
      for (final isPublic in [false, true]) {
        testWidgets(
          'OPPO S09 one read-only status control ${state.name} $isPublic ${display.width}',
          (tester) async {
            final semantics = tester.ensureSemantics();
            try {
              final work = liveStore()
                ..workspaceStoreState = state
                ..workspaceAcceptingOrders = state == WorkspaceStoreState.open
                ..workspaceVisibleToCustomers = isPublic;
              await mount(
                tester,
                route: '/app/work/workspace/dashboard',
                work: work,
                viewport: Size(display.width, display.height),
                textScale: display.scale,
              );
              final opening = switch (state) {
                WorkspaceStoreState.open => 'Open',
                WorkspaceStoreState.paused => 'Paused',
                _ => 'Off',
              };
              final visibility = isPublic ? 'Public' : 'Private';
              final control = find.byKey(const Key('work-dashboard-settings'));
              final header = find.byKey(
                const Key('work-dashboard-inline-header'),
              );
              final headerBefore = tester.getRect(header);
              expect(control.hitTestable(), findsOneWidget);
              expect(tester.getSize(control).height, greaterThanOrEqualTo(48));
              expect(tester.getSize(control).width, 58);
              expect(
                find.descendant(of: control, matching: find.byType(Icon)),
                findsOneWidget,
              );
              expect(
                tester.getSemantics(control),
                matchesSemantics(
                  isButton: true,
                  hasTapAction: true,
                  label:
                      '$opening, ${visibility.toLowerCase()} storefront. Store status',
                ),
              );
              final capture = !isPublic && state == WorkspaceStoreState.off;
              if (capture) {
                await captureStoreView(
                  tester,
                  'r665-status-dashboard-${display.width.toInt()}',
                );
              }
              await tester.tap(control);
              await tester.pumpAndSettle();
              final panel = find.byKey(const Key('work-store-status-panel'));
              expect(panel, findsOneWidget);
              expect(
                tester.getSize(find.byType(BottomSheet)).height,
                closeTo(tester.getSize(panel).height + 24 + 44, 1),
              );
              expect(
                find.descendant(of: panel, matching: find.byType(TextButton)),
                findsNothing,
              );
              expect(
                find.descendant(of: panel, matching: find.byType(FilledButton)),
                findsNothing,
              );
              for (final text in [
                'Taking orders',
                opening,
                'Storefront',
                visibility,
              ]) {
                expect(
                  find.descendant(of: panel, matching: find.text(text)),
                  findsOneWidget,
                );
              }
              final guidance = find.byKey(
                const Key('work-store-status-guidance'),
              );
              await reveal(tester, guidance);
              expect(
                tester.getRect(guidance).bottom,
                lessThanOrEqualTo(display.height - 44),
              );
              expect(work.workspaceStoreState, state);
              expect(work.workspaceVisibleToCustomers, isPublic);
              expect(
                work.workspaceAcceptingOrders,
                state == WorkspaceStoreState.open,
              );
              if (capture) {
                await captureStoreView(
                  tester,
                  'r665-status-panel-${display.width.toInt()}',
                );
              }
              await tester.binding.handlePopRoute();
              await tester.pumpAndSettle();
              expect(panel, findsNothing);
              expect(control.hitTestable(), findsOneWidget);
              expect(tester.getRect(header), headerBefore);
              await tester.tap(control);
              await tester.pumpAndSettle();
              expect(panel, findsOneWidget);
              await tester.tapAt(const Offset(8, 100));
              await tester.pumpAndSettle();
              expect(panel, findsNothing);
              expect(control.hitTestable(), findsOneWidget);
              expect(work.workspaceStoreState, state);
              expect(work.workspaceVisibleToCustomers, isPublic);
              expect(
                work.workspaceAcceptingOrders,
                state == WorkspaceStoreState.open,
              );
              expect(tester.takeException(), isNull);
            } finally {
              semantics.dispose();
            }
          },
        );
      }
    }
  }

  testWidgets('Store View v2 - compact large text, signals and keyboard', (
    tester,
  ) async {
    await mount(
      tester,
      route: '/app/work/workspace/dashboard',
      work: storeViewFixture(),
      viewport: const Size(320, 568),
      textScale: 1.4,
      bottomInset: 24,
    );
    expect(find.text('Accept').hitTestable(), findsOneWidget);
    expect(find.text('Reject').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await captureStoreView(tester, '13-compact-large-text');
    await tester.tap(find.byKey(const Key('work-dashboard-settings')));
    await tester.pumpAndSettle();
    expect(find.text('Store status'), findsOneWidget);
    expect(find.text('Public'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-dashboard-search')));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    await tester.enterText(
      find.byKey(const Key('work-dashboard-search-field')),
      'Fortune',
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('work-dashboard-search-field')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('work-local-navigation')), findsNothing);
    expect(tester.takeException(), isNull);
    await captureStoreView(tester, '14-search-keyboard');
  });

  testWidgets(
    'Store Desk - exact order stays in centre and Back restores desk',
    (tester) async {
      final work = storeViewFixture();
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: const Size(412, 915),
        textScale: 1,
        bottomInset: 34,
      );
      final edge = tester.getRect(
        find.byKey(const Key('work-store-action-edge')),
      );
      await tester.tap(find.byKey(const Key('work-activity-order-review')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-store-exact-order')), findsOneWidget);
      expect(find.text('APP-1043'), findsOneWidget);
      expect(find.byKey(const Key('work-orders-destination')), findsNothing);
      expect(
        tester.getRect(find.byKey(const Key('work-store-action-edge'))),
        edge,
      );
      expect(find.text('Accept').hitTestable(), findsOneWidget);
      await captureStoreView(tester, '15-exact-order');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-store-exact-order')), findsNothing);
      expect(
        find.byKey(const Key('work-activity-incoming-order')),
        findsOneWidget,
      );
      expect(work.workspaceOrderStage, 'Confirmed');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Store Desk - accept from exact order becomes packing without a gateway',
    (tester) async {
      final work = storeViewFixture();
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: const Size(412, 915),
        textScale: 1,
        bottomInset: 34,
      );
      await tester.tap(find.byKey(const Key('work-activity-order-review')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('work-activity-order-accept')));
      await tester.pumpAndSettle();
      expect(work.workspaceOrderStage, 'Preparing');
      expect(find.byKey(const Key('work-activity-packing')), findsOneWidget);
      expect(find.byKey(const Key('work-store-exact-order')), findsNothing);
      expect(find.byKey(const Key('work-local-navigation')), findsOneWidget);
      await captureStoreView(tester, '16-after-accept-packing');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Store Desk - update cannot replace a reviewed customer or mutate another order',
    (tester) async {
      final work = storeViewFixture();
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: const Size(412, 915),
        textScale: 1,
      );
      await tester.tap(find.byKey(const Key('work-activity-order-review')));
      await tester.pumpAndSettle();
      work.currentWorkspaceOrderId = 'APP-1044';
      work.workspaceOrderCustomer = 'Different customer';
      work.updateWorkspaceSearch('');
      await tester.pumpAndSettle();
      expect(find.text('APP-1043'), findsOneWidget);
      expect(find.text('Rakesh · 98290 12345'), findsOneWidget);
      expect(find.text('Different customer'), findsNothing);
      expect(find.byKey(const Key('work-activity-order-accept')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(360, 640),
    const Size(390, 844),
    const Size(430, 932),
  ]) {
    for (final scale in [1.0, 1.4]) {
      testWidgets(
        'Store Desk - fit ${size.width} by ${size.height} text $scale',
        (tester) async {
          final work = storeViewFixture();
          await mount(
            tester,
            route: '/app/work/workspace/dashboard',
            work: work,
            viewport: size,
            textScale: scale,
            bottomInset: 34,
          );
          for (final key in [
            'work-activity-order-accept',
            'work-activity-order-reject',
            'work-activity-order-review',
            'work-quick-store-link',
            'work-quick-promote',
          ]) {
            final target = find.byKey(Key(key)).hitTestable();
            expect(target, findsOneWidget, reason: key);
            expect(
              tester.getSize(target).height,
              greaterThanOrEqualTo(44),
              reason: key,
            );
          }
          expect(tester.takeException(), isNull);
          await tester.tap(find.byKey(const Key('work-activity-order-review')));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('work-store-exact-order')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          await tester.tap(find.byKey(const Key('work-activity-order-accept')));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('work-activity-packing')),
            findsOneWidget,
          );
          expect(
            tester
                .getSize(find.byKey(const Key('work-activity-mark-ready')))
                .height,
            greaterThanOrEqualTo(44),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'Store Desk - reduced motion keeps feedback and packing accessible',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        final work = storeViewFixture();
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: const Size(412, 915),
          textScale: 1,
        );
        final pulse = find.byKey(const Key('work-store-live-business-pulse'));
        for (final widget in tester.widgetList<AnimatedSwitcher>(
          find.descendant(of: pulse, matching: find.byType(AnimatedSwitcher)),
        )) {
          expect(widget.duration, Duration.zero);
        }
        final edge = tester.getRect(
          find.byKey(const Key('work-store-action-edge')),
        );
        await tester.tap(find.byKey(const Key('work-activity-order-accept')));
        await tester.pumpAndSettle();
        expect(
          tester.getRect(find.byKey(const Key('work-store-action-edge'))),
          edge,
        );
        expect(find.byKey(const Key('work-notice')), findsNothing);
        final progress = tester.widget<TweenAnimationBuilder<double>>(
          find.descendant(
            of: find.byKey(const Key('work-activity-packing')),
            matching: find.byWidgetPredicate(
              (widget) => widget is TweenAnimationBuilder<double>,
            ),
          ),
        );
        expect(progress.duration, Duration.zero);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'Store Desk - quiet store shows no invented order or group deal',
    (tester) async {
      final work = WorkSession()
        ..seedVerifiedWorkspace()
        ..retailerSetupSaved = true;
      work.workspaceOrderCustomer = '';
      work.workspaceOrderStage = 'No order';
      work.workspaceOrders.clear();
      work.workspaceSettlementBalance = 0;
      work.activeGroupBuy = null;
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: const Size(412, 915),
        textScale: 1,
      );
      expect(find.byKey(const Key('work-activity-order-accept')), findsNothing);
      expect(find.byKey(const Key('work-store-recent-sales')), findsNothing);
      expect(find.text('Onions'), findsNothing);
      expect(find.text('Send store link').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [const Size(320, 568), const Size(412, 915)]) {
    for (final index in List.generate(10, (index) => index)) {
      testWidgets(
        'Store Review - requirement category $index at ${size.width}',
        (tester) async {
          final work = storeViewFixture();
          await mount(
            tester,
            route: '/app/work/workspace/dashboard',
            work: work,
            viewport: size,
            textScale: size.width == 320 ? 1.4 : 1,
            bottomInset: 24,
          );
          await tester.tap(find.byKey(const Key('work-quick-requirement')));
          await tester.pumpAndSettle();
          final choice = find.byKey(Key('work-requirement-category-$index'));
          await Scrollable.ensureVisible(tester.element(choice), alignment: .5);
          await tester.pumpAndSettle();
          expect(choice.hitTestable(), findsOneWidget);
          expect(tester.getSize(choice).height, greaterThanOrEqualTo(48));
          if (size.width == 320) {
            expect(tester.getSize(choice).height, lessThanOrEqualTo(72));
          }
          await tester.tap(choice);
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('work-requirement-details')),
            findsOneWidget,
          );
          expect(find.text('People needed'), findsNothing);
          expect(find.text('₹0'), findsNothing);
          if (index == 3) {
            await tester.scrollUntilVisible(
              find.byKey(const Key('work-requirement-terms')),
              120,
              scrollable: find
                  .descendant(
                    of: find.byKey(const Key('work-requirement-details')),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
            await tester.pumpAndSettle();
            expect(find.text('Proposed partnership terms'), findsOneWidget);
            expect(find.text('Completion and payment terms'), findsNothing);
          }
          expect(tester.takeException(), isNull);
          if (size.width == 412 && index == 4) {
            expect(
              find.byKey(const Key('work-requirement-review')).hitTestable(),
              findsOneWidget,
            );
            await captureStoreView(tester, '18-requirement-details');
          }
          await tester.scrollUntilVisible(
            find.byKey(const Key('work-requirement-change')),
            -180,
            scrollable: find
                .descendant(
                  of: find.byKey(const Key('work-requirement-details')),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('work-requirement-change')));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('work-requirement-selector')),
            findsOneWidget,
          );
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('work-requirement-details')),
            findsOneWidget,
          );
          await tester.tap(find.byKey(const Key('work-operation-back')));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('work-workspace-dashboard')),
            findsOneWidget,
          );
          expect(work.workspacePaidRequirementReference, isNull);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final size in [const Size(320, 568), const Size(412, 915)]) {
    testWidgets('Store Review - compact requirement window at ${size.width}', (
      tester,
    ) async {
      final work = storeViewFixture();
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: size,
        textScale: size.width == 320 ? 1.4 : 1,
        bottomInset: 34,
      );
      final dashboard = find.byKey(const Key('work-workspace-dashboard'));
      final original = tester.getRect(dashboard);
      await tester.tap(find.byKey(const Key('work-quick-requirement')));
      await tester.pumpAndSettle();
      final selector = find.byKey(const Key('work-requirement-selector'));
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(
        tester.getSize(find.byType(BottomSheet)).height,
        lessThanOrEqualTo(size.height * .7),
      );
      expect(tester.getRect(dashboard), original);
      expect(
        tester.getSize(selector).height,
        lessThanOrEqualTo(size.height * .7),
      );
      expect(tester.getTopLeft(selector).dy, greaterThan(size.height * .25));
      expect(
        find.byKey(const Key('work-paid-requirement-screen')),
        findsNothing,
      );
      expect(find.byKey(const Key('work-requirement-review')), findsNothing);
      if (size.width == 412) {
        for (var index = 0; index < 10; index++) {
          expect(
            find.byKey(Key('work-requirement-category-$index')).hitTestable(),
            findsOneWidget,
          );
        }
      } else {
        await captureStoreView(tester, '26-compact-requirement-window');
      }
      await tester.tap(
        find.byKey(const Key('work-requirement-selector-close')),
      );
      await tester.pumpAndSettle();
      expect(selector, findsNothing);
      expect(
        find.byKey(const Key('work-activity-order-accept')).hitTestable(),
        findsOneWidget,
      );
      expect(work.workspacePaidRequirementReference, isNull);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Store Review - requirement window honors reduced motion', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await mount(
      tester,
      route: '/app/work/workspace/dashboard',
      work: storeViewFixture(),
      viewport: const Size(412, 915),
      textScale: 1,
    );
    await tester.tap(find.byKey(const Key('work-quick-requirement')));
    await tester.pumpAndSettle();
    final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
    expect(sheet.animationController?.duration, Duration.zero);
    expect(sheet.animationController?.reverseDuration, Duration.zero);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-workspace-dashboard')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Store Review - requirement keyboard, preview and fee safety', (
    tester,
  ) async {
    final work = storeViewFixture();
    await mount(
      tester,
      route: '/app/work/workspace/dashboard',
      work: work,
      viewport: const Size(320, 568),
      textScale: 1.4,
      bottomInset: 24,
    );
    await tester.tap(find.byKey(const Key('work-quick-requirement')));
    await tester.pumpAndSettle();
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const Key('work-requirement-category-4'))),
      alignment: .5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-requirement-category-4')));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    await tester.enterText(
      find.byKey(const Key('work-requirement-title')),
      'Manage product content',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-local-navigation')), findsNothing);
    await tester.ensureVisible(
      find.byKey(const Key('work-requirement-outcome')),
    );
    await tester.enterText(
      find.byKey(const Key('work-requirement-outcome')),
      'Update 20 product descriptions',
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await captureStoreView(tester, '19-requirement-keyboard');
    tester.view.viewInsets = const FakeViewPadding();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('work-requirement-review')),
      140,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('work-requirement-details')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-requirement-review')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('work-requirement-review-surface')),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Not posted. No payment has been taken.'),
      140,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('work-requirement-review-surface')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Not posted. No payment has been taken.'), findsOneWidget);
    expect(find.text('Included in your plan'), findsNothing);
    expect(find.text('Fund and publish to Earn Today'), findsNothing);
    expect(work.workspacePaidRequirementReference, isNull);
    await tester.ensureVisible(find.byKey(const Key('work-requirement-edit')));
    await tester.tap(find.byKey(const Key('work-requirement-edit')));
    await tester.pumpAndSettle();
    expect(find.text('Manage product content'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final action in <(String, String)>[
    ('work-dashboard-settings', '20-store-signals'),
    ('work-dashboard-workspace-switcher', '21-workspace-switcher'),
    ('work-dashboard-profile', '22-business-profile'),
    ('work-dashboard-alerts', '23-alerts'),
  ]) {
    testWidgets('Store Review - first tap ${action.$2}', (tester) async {
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: storeViewFixture(),
        viewport: const Size(412, 915),
        textScale: 1,
        bottomInset: 34,
      );
      await tester.tap(find.byKey(Key(action.$1)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await captureStoreView(tester, action.$2);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-workspace-dashboard')), findsOneWidget);
    });
  }

  testWidgets('Store Review - acceptance deadline never invents reassignment', (
    tester,
  ) async {
    final work = storeViewFixture();
    work.workspaceOrderActionDeadline = DateTime.now().subtract(
      const Duration(seconds: 1),
    );
    final index = work.workspaceOrders.indexWhere(
      (order) => order.id == 'APP-1043',
    );
    work.workspaceOrders[index] = work.workspaceOrders[index].copyWith(
      actionDeadline: work.workspaceOrderActionDeadline,
    );
    await mount(
      tester,
      route: '/app/work/workspace/dashboard',
      work: work,
      viewport: const Size(412, 915),
      textScale: 1,
      bottomInset: 34,
    );
    expect(find.text('Time ended'), findsOneWidget);
    expect(find.text('Order update pending'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('work-activity-order-accept')),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const Key('work-activity-order-reject')),
          )
          .onPressed,
      isNull,
    );
    expect(work.workspaceOrderStage, 'Confirmed');
    expect(work.errorMessage, isNull);
    expect(find.text('Order reassigned to another retailer'), findsNothing);
    await captureStoreView(
      tester,
      'order-deadline-initially-expired-dashboard-1.0',
    );
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('Order deadline controls expire without another tap $scale', (
      tester,
    ) async {
      final gateway = _TimingFixtureGateway();
      final work = storeViewFixture(gateway);
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: scale == 1 ? const Size(412, 915) : const Size(320, 568),
        textScale: scale,
      );
      final index = work.workspaceOrders.indexWhere(
        (order) => order.id == 'APP-1043',
      );
      final deadline = DateTime.now().add(const Duration(milliseconds: 500));
      work.workspaceOrders[index] = work.workspaceOrders[index].copyWith(
        actionDeadline: deadline,
      );
      work.workspaceOrderActionDeadline = deadline;
      work.notifyListeners();
      await tester.pump();
      final accept = find.byKey(const Key('work-activity-order-accept'));
      expect(tester.widget<FilledButton>(accept).onPressed, isNotNull);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 550)),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(tester.widget<FilledButton>(accept).onPressed, isNull);
      expect(find.text('Order update pending'), findsOneWidget);
      expect(work.workspaceOrderStage, 'Confirmed');
      expect(work.workspaceInvoices, isEmpty);
      await captureStoreView(tester, 'order-deadline-expired-dashboard-$scale');
      await tester.ensureVisible(find.byKey(const Key('work-order-more-time')));
      await tester.tap(find.byKey(const Key('work-order-more-time')));
      await tester.pumpAndSettle();
      expect(
        find.text('Acceptance time ended. Waiting for an order update.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('work-order-time-request')), findsNothing);
      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.text('Order status'), findsOneWidget);
      expect(gateway.requests, isEmpty);
      await captureStoreView(
        tester,
        'order-deadline-expired-time-panel-$scale',
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      final renewed = DateTime.now().add(const Duration(seconds: 60));
      work.workspaceOrders[index] = work.workspaceOrders[index].copyWith(
        actionDeadline: renewed,
      );
      work.workspaceOrderActionDeadline = renewed;
      work.notifyListeners();
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(accept).onPressed, isNotNull);
      expect(find.text('Order update pending'), findsNothing);
      expect(work.workspaceOrderStage, 'Confirmed');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('Order deadline exact first tap stays readonly after expiry', (
    tester,
  ) async {
    final work = storeViewFixture();
    final index = work.workspaceOrders.indexWhere(
      (order) => order.id == 'APP-1043',
    );
    final expired = DateTime.now().subtract(const Duration(seconds: 1));
    work.workspaceOrders[index] = work.workspaceOrders[index].copyWith(
      actionDeadline: expired,
    );
    work.workspaceOrderActionDeadline = expired;
    await mount(
      tester,
      route: '/app/work/workspace/dashboard',
      work: work,
      viewport: const Size(320, 568),
      textScale: 2,
    );
    await tester.tap(find.byKey(const Key('work-dashboard-search')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('work-dashboard-search-field')),
      'APP-1043',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-search-order-APP-1043')));
    await tester.pumpAndSettle();
    final accept = find.ancestor(
      of: find.text('Accept'),
      matching: find.byWidgetPredicate((widget) => widget is FilledButton),
    );
    expect(tester.widget<FilledButton>(accept).onPressed, isNull);
    final reject = find.ancestor(
      of: find.text('Reject'),
      matching: find.byType(TextButton),
    );
    expect(tester.widget<TextButton>(reject).onPressed, isNull);
    expect(find.text('Order update pending'), findsOneWidget);
    expect(work.currentWorkspaceOrder!.stage, 'Confirmed');
    await captureStoreView(tester, 'order-deadline-expired-exact-2.0');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(work.workspaceSearchQuery, 'APP-1043');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Store Review - global Chat first tap and exact Store return', (
    tester,
  ) async {
    await mount(
      tester,
      route: '/app/work/workspace/dashboard',
      work: storeViewFixture(),
      viewport: const Size(412, 915),
      textScale: 1,
      bottomInset: 34,
    );
    await tester.tap(find.text('Chat').hitTestable());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await captureStoreView(tester, '24-store-chat');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-workspace-dashboard')), findsOneWidget);
    expect(find.text('Rakesh'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Store Review - requirement survives leaving and returning to Store',
    (tester) async {
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: storeViewFixture(),
        viewport: const Size(412, 915),
        textScale: 1,
        bottomInset: 34,
      );
      await tester.tap(find.byKey(const Key('work-quick-requirement')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('work-requirement-category-0')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('work-requirement-title')),
        'Source 20 cartons of oil',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('work-operation-back')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('work-quick-requirement')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-requirement-details')), findsOneWidget);
      expect(find.text('Source 20 cartons of oil'), findsOneWidget);
      expect(find.text('Product sourcing'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [const Size(320, 568), const Size(412, 915)]) {
    testWidgets('Store Review - compact bill actions at ${size.width}', (
      tester,
    ) async {
      final work = storeViewFixture();
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: size,
        textScale: size.width == 320 ? 1.4 : 1,
        bottomInset: 24,
      );
      final originalOrders = work.workspaceOrders.length;
      await tester.tap(find.byKey(const Key('work-store-sell')));
      await tester.pumpAndSettle();
      final sale = find.byKey(const Key('work-dashboard-counter-order-screen'));
      expect(
        find.descendant(of: sale, matching: find.byType(ChoiceChip)),
        findsNothing,
      );
      expect(find.text('How did the customer order?'), findsNothing);
      expect(find.text('How will the customer receive it?'), findsNothing);
      expect(find.text('Create customer order'), findsNothing);
      expect(find.text('Phone'), findsNothing);
      expect(find.text('My delivery'), findsNothing);
      expect(find.byKey(const Key('work-order-customer')), findsNothing);
      expect(
        tester
            .getSize(find.byKey(const Key('work-sale-compact-controls')))
            .height,
        lessThanOrEqualTo(88),
      );
      expect(
        tester.getTopLeft(find.byKey(const Key('work-sale-products'))).dy,
        lessThan(size.height * .4),
      );
      final search = find.byKey(const Key('work-dashboard-search-field'));
      expect(tester.widget<TextField>(search).focusNode!.hasFocus, isFalse);
      for (final key in [
        'work-dashboard-scan',
        'work-dashboard-alerts',
        'work-dashboard-profile',
      ]) {
        expect(find.byKey(Key(key)).hitTestable(), findsOneWidget);
      }
      expect(find.byTooltip('Scan barcode'), findsNothing);
      final add = find.byKey(const Key('work-order-add-oil-fortune-1l'));
      final before = tester.getRect(add);
      await tester.tap(add);
      await tester.pumpAndSettle();
      expect(work.workspaceOrderQuantities['oil-fortune-1l'], 1);
      expect(tester.getRect(add), before);
      expect(tester.getSize(add).shortestSide, greaterThanOrEqualTo(44));
      await tester.tap(find.byKey(const Key('work-sale-customer')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-sale-customer-sheet')), findsOneWidget);
      tester.view.viewInsets = const FakeViewPadding(bottom: 220);
      await tester.enterText(
        find.byKey(const Key('work-order-customer')),
        '9876543210',
      );
      await tester.pumpAndSettle();
      await Scrollable.ensureVisible(
        tester.element(find.byKey(const Key('work-sale-customer-confirm'))),
        alignment: .5,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (size.width == 320) {
        await captureStoreView(tester, '27-sale-customer-keyboard');
      }
      await tester.tap(find.byKey(const Key('work-sale-customer-confirm')));
      tester.view.viewInsets = const FakeViewPadding();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(work.workspaceOrderCustomer, '9876543210');
      expect(work.workspaceOrders.length, originalOrders);
      expect(find.text('Review bill').hitTestable(), findsOneWidget);
      await tester.tap(find.byKey(const Key('work-sale-delivery')));
      await tester.pumpAndSettle();
      expect(find.text('Delivery options'), findsOneWidget);
      await tester.tap(
        find.byKey(const Key('work-order-receive-own-delivery')),
      );
      await tester.pumpAndSettle();
      expect(find.text('My delivery').hitTestable(), findsOneWidget);
      expect(work.workspaceOrders.length, originalOrders);
      await tester.enterText(search, 'no-match-product');
      await tester.pumpAndSettle();
      expect(find.text('No products match your search'), findsOneWidget);
      expect(work.workspaceOrderQuantities['oil-fortune-1l'], 1);
      await tester.enterText(search, 'FRT-1L');
      await tester.pumpAndSettle();
      expect(add.hitTestable(), findsOneWidget);
      expect(
        find.byKey(const Key('work-dashboard-catalogue-screen')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final sale in [false, true]) {
    testWidgets(
      'Store Review - scanner permission fallback and Back, sale=$sale',
      (tester) async {
        const channel = MethodChannel(
          'flutter.baseflow.com/permissions/methods',
        );
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (call) async {
            if (call.method == 'requestPermissions') {
              return <int, int>{
                for (final id in call.arguments as List) id as int: 0,
              };
            }
            return 0;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            channel,
            null,
          ),
        );
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: storeViewFixture(),
          viewport: const Size(412, 915),
          textScale: 1,
          bottomInset: 34,
        );
        if (sale) {
          await tester.tap(find.byKey(const Key('work-store-sell')));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.byKey(const Key('work-dashboard-scan')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('buy-manual-code-panel')),
          findsOneWidget,
        );
        expect(find.text('Camera access needed'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await captureStoreView(
          tester,
          sale ? '28-sale-scanner-fallback' : '25-scanner-permission-fallback',
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('buy-manual-code-panel')), findsNothing);
        expect(
          find.byKey(
            Key(
              sale
                  ? 'work-dashboard-counter-order-screen'
                  : 'work-store-activity-deck',
            ),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final (width, height, scale) in [
    (412.0, 915.0, 1.0),
    (320.0, 568.0, 2.0),
  ]) {
    testWidgets('DASH05 scoped time panel retry and confirmation $scale', (
      tester,
    ) async {
      final previousErrorHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        debugPrint(details.toString());
        previousErrorHandler?.call(details);
      };
      addTearDown(() => FlutterError.onError = previousErrorHandler);
      final work = storeViewFixture(null, _ContactDraftFixtureStore());
      final original = work.currentWorkspaceOrder!;
      final deadline = original.actionDeadline!;
      final gateway = _ScopedTimingFixtureGateway();
      final operations = WorkOrderOperations(
        accountScope: 'review-draft-account',
        workspaceId: work.activeWorkspace!.id,
        gateway: gateway,
      );
      operations.observe(
        WorkOrderReply(
          accountScope: operations.accountScope,
          workspaceId: operations.workspaceId,
          orderId: original.id,
          operationId: '',
          revision: 1,
          state: WorkOrderReplyState.applied,
          order: original,
        ),
      );
      expect(work.bindWorkspaceOrderOperations(operations), isTrue);
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: Size(width, height),
        textScale: scale,
      );
      final more = find.byKey(const Key('work-order-more-time'));
      await tester.ensureVisible(more);
      await tester.pumpAndSettle();
      await tester.tap(more);
      await tester.pumpAndSettle();
      final five = find.widgetWithText(ChoiceChip, '+5 min');
      await tester.ensureVisible(five);
      await tester.pumpAndSettle();
      await tester.tap(five);
      await tester.pumpAndSettle();
      final request = find.byKey(const Key('work-order-time-request'));
      await tester.ensureVisible(request);
      await tester.pumpAndSettle();
      expect(request.hitTestable(), findsOneWidget);
      await tester.tap(request);
      await tester.pumpAndSettle();
      final command = gateway.submitted.single;
      expect(command.action, WorkOrderAction.requestTime);
      expect(command.additionalMinutes, 5);
      expect(work.currentWorkspaceOrder!.actionDeadline, deadline);
      expect(tester.widget<FilledButton>(request).onPressed, isNull);
      expect(work.hasPendingOrderTime, isFalse);
      expect(tester.takeException(), isNull);
      gateway.responses.single.completeError(StateError('network unknown'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(request);
      await tester.pumpAndSettle();
      expect(find.text('Retry request'), findsOneWidget);
      await captureStoreView(tester, 'scoped-time-uncertain-$scale');
      expect(tester.takeException(), isNull);
      await tester.tap(request);
      await tester.pumpAndSettle();
      expect(gateway.reconciled.single, same(command));
      gateway.replies.single.complete(
        WorkOrderReply(
          accountScope: command.accountScope,
          workspaceId: command.workspaceId,
          orderId: command.orderId,
          operationId: command.operationId,
          revision: 2,
          state: WorkOrderReplyState.applied,
          order: original.copyWith(
            actionDeadline: deadline.add(const Duration(minutes: 5)),
            fulfilmentDeadline: deadline.add(const Duration(minutes: 12)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        work.currentWorkspaceOrder!.actionDeadline,
        deadline.add(const Duration(minutes: 5)),
      );
      expect(work.workspaceOrderStage, 'Confirmed');
      expect(gateway.submitted.length, 1);
      expect(find.text('Time confirmed'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await captureStoreView(tester, 'scoped-time-confirmed-$scale');
      final close = find.descendant(
        of: find.byKey(const Key('work-order-time-sheet')),
        matching: find.byTooltip('Close'),
      );
      await tester.ensureVisible(close);
      await tester.pumpAndSettle();
      await tester.tap(close);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-order-time-sheet')), findsNothing);
      expect(
        find.byKey(const Key('work-activity-order-accept')),
        findsOneWidget,
      );
      expect(work.workspaceInvoices, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('DASH04 restored order card recovery $scale', (tester) async {
      final work = storeViewFixture(null, _ContactDraftFixtureStore());
      final gateway = _OrderCommandFixtureGateway();
      final original = work.currentWorkspaceOrder!;
      final storeId = work.activeWorkspace!.id;
      final saved = WorkOrderCommand(
        accountScope: 'review-draft-account',
        workspaceId: storeId,
        orderId: original.id,
        operationId: 'retained-order-operation',
        expectedRevision: 1,
        action: WorkOrderAction.accept,
      );
      final journal = _OrderJournalFixture(saved);
      final operations = WorkOrderOperations(
        accountScope: saved.accountScope,
        workspaceId: storeId,
        gateway: gateway,
        pendingStore: journal,
      );
      expect(await operations.restore(), isTrue);
      WorkOrderReply snapshot(int revision, String stage) => WorkOrderReply(
        accountScope: saved.accountScope,
        workspaceId: storeId,
        orderId: original.id,
        operationId: saved.operationId,
        revision: revision,
        state: WorkOrderReplyState.applied,
        order: original.copyWith(stage: stage),
      );
      operations.observe(snapshot(1, 'Confirmed'));
      expect(work.bindWorkspaceOrderOperations(operations), isTrue);
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: Size(width, height),
        textScale: scale,
      );
      final retry = find.byKey(
        Key('work-order-operation-retry-${original.id}'),
      );
      await tester.ensureVisible(retry);
      await tester.pumpAndSettle();
      expect(retry.hitTestable(), findsOneWidget);
      expect(tester.getSize(retry).height, greaterThanOrEqualTo(48));
      expect(find.text('Update not confirmed'), findsOneWidget);
      expect(find.byKey(const Key('work-activity-order-accept')), findsNothing);
      expect(gateway.submitted, isEmpty);
      expect(tester.takeException(), isNull);
      await captureStoreView(tester, 'scoped-order-restored-$scale');
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(gateway.reconciled.single.operationId, saved.operationId);
      expect(find.text('Checking update…'), findsOneWidget);
      gateway.replies.single.complete(snapshot(2, 'Preparing'));
      await tester.pumpAndSettle();
      expect(work.workspaceOrderStage, 'Preparing');
      expect(journal.command, isNull);
      expect(gateway.submitted, isEmpty);
      expect(work.workspaceInvoices, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('DASH04 scoped order card submit retry $scale', (tester) async {
      final work = storeViewFixture(null, _ContactDraftFixtureStore());
      final gateway = _OrderCommandFixtureGateway();
      final storeId = work.activeWorkspace!.id;
      final operations = WorkOrderOperations(
        accountScope: 'review-draft-account',
        workspaceId: storeId,
        gateway: gateway,
      );
      final original = work.currentWorkspaceOrder!;
      WorkOrderReply reply({
        WorkOrderCommand? command,
        int revision = 1,
        String stage = 'Confirmed',
      }) => WorkOrderReply(
        accountScope: 'review-draft-account',
        workspaceId: storeId,
        orderId: original.id,
        operationId: command?.operationId ?? '',
        revision: revision,
        state: WorkOrderReplyState.applied,
        order: original.copyWith(stage: stage),
      );
      operations.observe(reply());
      expect(work.bindWorkspaceOrderOperations(operations), isTrue);
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: Size(width, height),
        textScale: scale,
      );
      final accept = find.byKey(const Key('work-activity-order-accept'));
      await tester.ensureVisible(accept);
      await tester.pumpAndSettle();
      expect(accept.hitTestable(), findsOneWidget);
      await tester.tap(accept);
      await tester.pumpAndSettle();
      expect(gateway.submitted.length, 1);
      expect(work.workspaceOrderStage, 'Confirmed');
      expect(find.text('Sending update…'), findsOneWidget);
      expect(
        tester
            .widget<TextButton>(find.byKey(const Key('work-order-more-time')))
            .onPressed,
        isNull,
      );
      expect(find.byKey(const Key('work-activity-order-accept')), findsNothing);
      expect(tester.takeException(), isNull);
      await captureStoreView(tester, 'scoped-order-sending-$scale');
      gateway.responses.single.completeError(StateError('response unknown'));
      await tester.pumpAndSettle();
      final retry = find.byKey(
        Key('work-order-operation-retry-${original.id}'),
      );
      await tester.ensureVisible(retry);
      await tester.pumpAndSettle();
      expect(retry.hitTestable(), findsOneWidget);
      expect(tester.getSize(retry).height, greaterThanOrEqualTo(48));
      expect(find.text('Update not confirmed'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await captureStoreView(tester, 'scoped-order-uncertain-$scale');
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(find.text('Checking update…'), findsOneWidget);
      expect(gateway.reconciled.single, same(gateway.submitted.single));
      gateway.replies.single.complete(
        reply(
          command: gateway.reconciled.single,
          revision: 2,
          stage: 'Preparing',
        ),
      );
      await tester.pumpAndSettle();
      expect(work.workspaceOrderStage, 'Preparing');
      expect(
        find.byKey(Key('work-order-operation-${original.id}')),
        findsNothing,
      );
      expect(work.workspaceSalesToday, 28450);
      expect(work.workspaceSettlementBalance, 17820);
      expect(work.workspaceInvoices, isEmpty);
      expect(tester.takeException(), isNull);
      await captureStoreView(tester, 'scoped-order-preparing-$scale');
    });
  }

  Future<void> openStoreTools(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('work-dashboard-profile')));
    await tester.pumpAndSettle();
    final operations = find.byKey(const Key('global-profile-quick-operations'));
    await tester.ensureVisible(operations);
    await tester.tap(operations);
    await tester.pumpAndSettle();
  }

  for (final (width, height, scale, reduced) in [
    (412.0, 915.0, 1.0, false),
    (360.0, 800.0, 1.4, false),
    (320.0, 568.0, 2.0, false),
    (412.0, 915.0, 2.0, true),
  ]) {
    testWidgets(
      'REG4560 inline Chat search $width $height $scale reduced=$reduced',
      (tester) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            FakeAccessibilityFeatures(disableAnimations: reduced);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        final work = storeViewFixture();
        final storeId = work.activeWorkspace!.id;
        final chat = ChatSession(
          sendGateway: ReviewChatSendGateway(latency: Duration.zero),
        );
        chat.setDraftTextForSession('home-basket', 'Keep this unsent draft');
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          chat: chat,
          viewport: Size(width, height),
          textScale: scale,
        );
        final dashboard = find.byType(WorkWorkspaceDashboardScreen);
        final dashboardState = tester.state(dashboard);
        final router = GoRouter.of(tester.element(dashboard));
        router.push<void>(
          Uri(
            path: '/app/chat/inbox',
            queryParameters: {'return': '/app/work/workspace/dashboard'},
          ).toString(),
        );
        await tester.pumpAndSettle();
        final field = find.byKey(const Key('chat-search-field'));
        final open = find.byKey(const Key('chat-open-inline-search'));
        final motionFinder = find.byKey(const Key('chat-search-focus-motion'));
        final motion = tester.widget<AnimatedContainer>(motionFinder);
        final decoration = motion.decoration! as BoxDecoration;
        expect(decoration.color, isNull);
        expect(decoration.borderRadius, isNull);
        expect(decoration.boxShadow, isNull);
        if (reduced) expect(motion.duration, Duration.zero);
        expect(
          find.descendant(
            of: field,
            matching: find.byIcon(Icons.search_rounded),
          ),
          findsOneWidget,
        );
        expect(tester.widget<TextField>(field).decoration!.suffixIcon, isNull);
        expect(open.hitTestable(), findsOneWidget);
        expect(tester.getSize(open).shortestSide, greaterThanOrEqualTo(48));
        final hint = tester.widget<TextField>(field).decoration!.hintText!;
        if (width == 412 && scale == 1) {
          expect(hint, 'Search conversations');
        }
        if (hint == 'Search') {
          expect(
            find
                .ancestor(of: field, matching: find.byType(Semantics))
                .evaluate()
                .any(
                  (element) =>
                      (element.widget as Semantics).properties.label ==
                      'Search conversations',
                ),
            isTrue,
          );
        }
        final hintFinder = find.descendant(
          of: field,
          matching: find.text(hint),
        );
        final hintParagraph = tester.renderObject<RenderParagraph>(hintFinder);
        expect(hintParagraph.didExceedMaxLines, isFalse);
        expect(
          hintParagraph.getMaxIntrinsicWidth(double.infinity),
          lessThanOrEqualTo(hintParagraph.size.width + .01),
        );
        final recipient = find.byKey(
          const Key('chat-thread-title-shop-assist'),
        );
        final recipientParagraph = tester.renderObject<RenderParagraph>(
          recipient,
        );
        expect(recipientParagraph.didExceedMaxLines, isFalse);
        expect(tester.widget<Text>(recipient).maxLines, isNull);
        expect(
          tester.widget<Text>(recipient).data,
          chat.thread('shop-assist').title,
        );
        if (width == 320 && scale == 2) {
          expect(
            tester
                .getTopLeft(
                  find.byKey(const Key('chat-thread-metadata-shop-assist')),
                )
                .dy,
            greaterThanOrEqualTo(tester.getBottomRight(recipient).dy),
          );
        }
        final options = find.byKey(const Key('chat-thread-more-shop-assist'));
        await reveal(tester, options);
        await tester.tap(options);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('chat-conversation-actions')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        final optionsRecipient = find.byKey(
          const Key('chat-options-recipient'),
        );
        expect(
          tester
              .renderObject<RenderParagraph>(optionsRecipient)
              .didExceedMaxLines,
          isFalse,
        );
        final archive = find.byKey(
          const Key('chat-action-archive-shop-assist'),
        );
        final optionsKeyboard = scale == 2 ? 200.0 : 0.0;
        if (optionsKeyboard > 0) {
          tester.view.viewInsets = FakeViewPadding(bottom: optionsKeyboard);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        await reveal(tester, archive);
        expect(archive.hitTestable(), findsOneWidget);
        expect(
          tester.getBottomRight(archive).dy,
          lessThanOrEqualTo(height - 44 - optionsKeyboard),
        );
        await captureStoreView(tester, 'chat-options-$width-$scale-$reduced');
        await tester.binding.handlePopRoute();
        tester.view.viewInsets = const FakeViewPadding();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('chat-conversation-actions')),
          findsNothing,
        );
        final searchScroll = find.byKey(
          const PageStorageKey('chat-inbox-scroll'),
        );
        await tester.drag(searchScroll, const Offset(0, 800));
        await tester.pumpAndSettle();
        await captureStoreView(
          tester,
          'chat-inline-idle-$width-$scale-$reduced',
        );
        await tester.tap(open);
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(field).focusNode!.hasFocus, isTrue);
        expect(find.byKey(const Key('chat-open-inline-search')), findsNothing);
        expect(
          find.byKey(const Key('chat-close-inline-search')),
          findsOneWidget,
        );
        tester.view.viewInsets = const FakeViewPadding(bottom: 200);
        await tester.enterText(field, 'zz-no-conversation-4560');
        await tester.pumpAndSettle();
        final clear = find.byKey(const Key('chat-clear-search'));
        expect(clear.hitTestable(), findsOneWidget);
        expect(
          tester.getBottomRight(clear).dy,
          lessThanOrEqualTo(height - 200),
        );
        expect(find.byKey(const Key('chat-new')), findsNothing);
        expect(find.byKey(const Key('chat-filter-all')), findsNothing);
        expect(
          chat.draftTextForSession('home-basket'),
          'Keep this unsent draft',
        );
        await captureStoreView(
          tester,
          'chat-inline-search-$width-$scale-$reduced',
        );
        await tester.tap(clear);
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(field).controller!.text, isEmpty);
        expect(tester.widget<TextField>(field).focusNode!.hasFocus, isTrue);
        await tester.tap(find.byKey(const Key('chat-close-inline-search')));
        tester.view.viewInsets = const FakeViewPadding();
        await tester.pumpAndSettle();
        expect(open.hitTestable(), findsOneWidget);
        expect(tester.widget<TextField>(field).focusNode!.hasFocus, isFalse);
        await tester.tap(find.byKey(const Key('chat-inbox-back')));
        await tester.pumpAndSettle();
        expect(tester.state(dashboard), same(dashboardState));
        expect(work.activeWorkspace!.id, storeId);
        expect(
          chat.draftTextForSession('home-basket'),
          'Keep this unsent draft',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final hardwareBack in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'REG4551 Files returns to the same Store hardware=$hardwareBack scale=$scale',
        (tester) async {
          final work = storeViewFixture();
          final workspaceId = work.activeWorkspace!.id;
          final orderId = work.currentWorkspaceOrderId;
          final orderStage = work.workspaceOrderStage;
          await mount(
            tester,
            route: '/app/work/workspace/dashboard',
            work: work,
            viewport: const Size(412, 915),
            textScale: scale,
          );
          final dashboard = find.byType(WorkWorkspaceDashboardScreen);
          final dashboardState = tester.state(dashboard);
          final router = GoRouter.of(tester.element(dashboard));
          for (var visit = 0; visit < 3; visit++) {
            await tester.tap(find.byKey(const Key('work-dashboard-profile')));
            await tester.pumpAndSettle();
            final documents = find.byKey(
              const Key('global-profile-quick-documents'),
            );
            await tester.ensureVisible(documents);
            await tester.tap(documents);
            await tester.pumpAndSettle();
            expect(find.byKey(const Key('shared-screen-160')), findsOneWidget);
            expect(router.canPop(), isTrue);
            expect(tester.takeException(), isNull);
            if (!hardwareBack && visit == 0) {
              await captureStoreView(tester, 'reg4551-files-$scale');
            }
            if (hardwareBack) {
              await tester.binding.handlePopRoute();
            } else {
              await tester.tap(find.byKey(const Key('shared-160-back')));
            }
            await tester.pumpAndSettle();
            expect(dashboard, findsOneWidget);
            expect(tester.state(dashboard), same(dashboardState));
            expect(find.byKey(const Key('shared-screen-162')), findsNothing);
            expect(
              find.byKey(const Key('global-profile-panel-v2')),
              findsNothing,
            );
            expect(router.canPop(), isFalse);
            expect(work.activeWorkspace!.id, workspaceId);
            expect(work.currentWorkspaceOrderId, orderId);
            expect(work.workspaceOrderStage, orderStage);
            expect(tester.takeException(), isNull);
            if (!hardwareBack && visit == 0) {
              await captureStoreView(tester, 'reg4551-return-store-$scale');
            }
          }
        },
      );
    }
  }

  for (final cancelButton in [false, true]) {
    testWidgets(
      'REG4551 Files nested sheet returns without losing Store cancel=$cancelButton',
      (tester) async {
        final work = storeViewFixture();
        final workspaceId = work.activeWorkspace!.id;
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: const Size(412, 915),
          textScale: 1,
        );
        final dashboard = find.byType(WorkWorkspaceDashboardScreen);
        final dashboardState = tester.state(dashboard);
        await tester.tap(find.byKey(const Key('work-dashboard-profile')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('global-profile-quick-documents')),
        );
        await tester.pumpAndSettle();
        final files = find.byKey(const Key('shared-screen-160'));
        final filesState = tester.state(files);
        await tester.tap(find.byKey(const Key('shared-160-top-action')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('shared-file-add-sheet')), findsOneWidget);
        if (cancelButton) {
          await tester.tap(find.byKey(const Key('shared-file-add-cancel')));
        } else {
          await tester.binding.handlePopRoute();
        }
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('shared-file-add-sheet')), findsNothing);
        expect(tester.state(files), same(filesState));
        expect(work.activeWorkspace!.id, workspaceId);
        await tester.tap(find.byKey(const Key('shared-160-back')));
        await tester.pumpAndSettle();
        expect(tester.state(dashboard), same(dashboardState));
        expect(find.byKey(const Key('shared-screen-162')), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final (width, height, scale, bottom, keyboard) in [
    (412.0, 915.0, 1.0, 44.0, 0.0),
    (412.0, 915.0, 2.0, 44.0, 0.0),
    (320.0, 568.0, 2.0, 80.0, 0.0),
    (320.0, 568.0, 1.4, 24.0, 0.0),
    (412.0, 915.0, 2.0, 24.0, 200.0),
    (320.0, 568.0, 2.0, 44.0, 200.0),
  ]) {
    testWidgets(
      'REG4554 REG4556 Files heading and Cancel fit $width $height $scale $bottom $keyboard',
      (tester) async {
        final work = storeViewFixture();
        final storeId = work.activeWorkspace!.id;
        final orderId = work.currentWorkspaceOrderId;
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: Size(width, height),
          textScale: scale,
          bottomInset: bottom,
        );
        final dashboard = find.byType(WorkWorkspaceDashboardScreen);
        final dashboardState = tester.state(dashboard);
        await tester.tap(find.byKey(const Key('work-dashboard-profile')));
        await tester.pumpAndSettle();
        final documents = find.byKey(
          const Key('global-profile-quick-documents'),
        );
        await tester.ensureVisible(documents);
        await tester.tap(documents);
        await tester.pumpAndSettle();
        final files = find.byKey(const Key('shared-screen-160'));
        final filesState = tester.state(files);
        final heading = find.byKey(const Key('shared-files-title'));
        final appBar = find.byType(AppBar);
        final headingRect = tester.getRect(heading);
        final barRect = tester.getRect(appBar);
        expect(
          tester.renderObject<RenderParagraph>(heading).didExceedMaxLines,
          isFalse,
        );
        expect(headingRect.top, greaterThanOrEqualTo(barRect.top));
        expect(headingRect.bottom, lessThanOrEqualTo(barRect.bottom));
        final add = find.byKey(const Key('shared-160-top-action'));
        expect(headingRect.right, lessThanOrEqualTo(tester.getRect(add).left));
        expect(add.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await captureStoreView(tester, 'files-heading-$width-$scale-$bottom');
        await tester.tap(add);
        await tester.pumpAndSettle();
        for (final (source, label) in const [
          ('camera', 'Camera'),
          ('scan', 'Scan document'),
          ('gallery', 'Gallery'),
          ('file', 'Choose file'),
        ]) {
          final row = find.byKey(Key('shared-file-add-$source'));
          final text = find.descendant(of: row, matching: find.text(label));
          final paragraph = tester.renderObject<RenderParagraph>(text);
          expect(
            paragraph.getMinIntrinsicWidth(double.infinity),
            lessThanOrEqualTo(paragraph.size.width + 0.01),
            reason: '$label must not split inside a word',
          );
          expect(tester.getSize(row).height, greaterThanOrEqualTo(48));
        }
        if (keyboard > 0) {
          tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
          await tester.pumpAndSettle();
        }
        final cancel = find.byKey(const Key('shared-file-add-cancel'));
        await reveal(tester, cancel);
        final boundary = height - (keyboard > 0 ? keyboard : bottom);
        expect(cancel.hitTestable(), findsOneWidget);
        expect(tester.getSize(cancel).height, greaterThanOrEqualTo(48));
        expect(
          tester.getBottomRight(cancel).dy,
          lessThanOrEqualTo(boundary - 8),
        );
        expect(tester.takeException(), isNull);
        await captureStoreView(
          tester,
          'files-cancel-$width-$scale-$bottom-$keyboard',
        );
        await tester.tap(cancel);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('shared-file-add-sheet')), findsNothing);
        expect(tester.state(files), same(filesState));
        tester.view.viewInsets = const FakeViewPadding();
        await tester.pumpAndSettle();
        await tester.tap(add);
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('shared-file-add-sheet')), findsNothing);
        expect(tester.state(files), same(filesState));
        await tester.tap(find.byKey(const Key('shared-160-back')));
        await tester.pumpAndSettle();
        expect(tester.state(dashboard), same(dashboardState));
        expect(work.activeWorkspace!.id, storeId);
        expect(work.currentWorkspaceOrderId, orderId);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('REG4551 Files preserves an unsubmitted counter-sale draft', (
    tester,
  ) async {
    final work = storeViewFixture();
    await mount(
      tester,
      route: '/app/work/workspace/dashboard',
      work: work,
      viewport: const Size(412, 915),
      textScale: 1,
    );
    final orders = work.workspaceOrders.length;
    final invoices = work.workspaceInvoices.length;
    await tester.tap(find.byKey(const Key('work-store-sell')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-sale-customer')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('work-order-customer')),
      '9000000013',
    );
    await tester.tap(find.byKey(const Key('work-sale-customer-confirm')));
    await tester.pumpAndSettle();
    expect(work.workspaceOrderCustomer, '9000000013');
    await tester.tap(find.byKey(const Key('work-dashboard-profile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('global-profile-quick-documents')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shared-160-back')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('work-dashboard-counter-order-screen')),
      findsOneWidget,
    );
    expect(work.workspaceOrderCustomer, '9000000013');
    expect(work.workspaceOrders.length, orders);
    expect(work.workspaceInvoices.length, invoices);
    await tester.tap(find.byKey(const Key('work-sale-customer')));
    await tester.pumpAndSettle();
    final editable = find.descendant(
      of: find.byKey(const Key('work-order-customer')),
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(editable).controller.text, '9000000013');
    expect(tester.takeException(), isNull);
  });

  testWidgets('REG4551 non-Files hub keeps its original Back behavior', (
    tester,
  ) async {
    await mount(
      tester,
      route: '/app/work/workspace/dashboard',
      work: storeViewFixture(),
      textScale: 1,
    );
    final router = GoRouter.of(
      tester.element(find.byType(WorkWorkspaceDashboardScreen)),
    );
    router.push<void>('/app/account/workspaces');
    await tester.pumpAndSettle();
    expect(router.canPop(), isTrue);
    await tester.tap(find.byKey(const Key('shared-162-back')));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/app/social');
    expect(find.byType(WorkWorkspaceDashboardScreen), findsNothing);
    expect(router.canPop(), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('REG4551 direct Files retains its existing safe fallback', (
    tester,
  ) async {
    await mount(
      tester,
      route: '/app/files',
      work: storeViewFixture(),
      textScale: 1,
    );
    final files = find.byKey(const Key('shared-screen-160'));
    final router = GoRouter.of(tester.element(files));
    expect(router.canPop(), isFalse);
    await tester.tap(find.byKey(const Key('shared-160-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('shared-screen-162')), findsOneWidget);
    expect(find.byType(WorkWorkspaceDashboardScreen), findsNothing);
    expect(router.canPop(), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('REG4551 Files returns to a non-Store pushed origin', (
    tester,
  ) async {
    await mount(
      tester,
      route: '/app/account/workspaces',
      work: storeViewFixture(),
      textScale: 1,
    );
    final origin = find.byKey(const Key('shared-screen-162'));
    final originState = tester.state(origin);
    final router = GoRouter.of(tester.element(origin));
    router.push<void>('/app/files');
    await tester.pumpAndSettle();
    expect(router.canPop(), isTrue);
    await tester.tap(find.byKey(const Key('shared-160-back')));
    await tester.pumpAndSettle();
    expect(origin, findsOneWidget);
    expect(tester.state(origin), same(originState));
    expect(router.canPop(), isFalse);
    expect(find.byType(WorkWorkspaceDashboardScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Store Review - acceptance keeps the supplied ten-minute fulfilment target',
    (tester) async {
      final work = storeViewFixture();
      final created = work.currentWorkspaceOrder!.createdAt;
      final index = work.workspaceOrders.indexWhere(
        (order) => order.id == 'APP-1043',
      );
      work.workspaceOrders[index] = work.currentWorkspaceOrder!.copyWith(
        fulfilmentDeadline: created.add(const Duration(minutes: 10)),
      );
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: const Size(412, 915),
        textScale: 1,
      );
      expect(
        work.workspaceOrderActionDeadline!.difference(created).inSeconds,
        inInclusiveRange(59, 60),
      );
      await tester.tap(find.byKey(const Key('work-activity-order-accept')));
      await tester.pumpAndSettle();
      expect(work.workspaceOrderStage, 'Preparing');
      expect(
        work.workspaceOrderActionDeadline,
        created.add(const Duration(minutes: 10)),
      );
      for (final line in work.workspacePackingLines) {
        work.setWorkspacePackingLine(line.id, true);
      }
      work.advanceWorkspaceOrder();
      await tester.pumpAndSettle();
      expect(work.workspaceOrderStage, 'Ready for pickup');
      expect(
        work.workspaceOrderActionDeadline,
        created.add(const Duration(minutes: 10)),
      );
      expect(tester.takeException(), isNull);
    },
  );

  Future<void> openStoreSettings(WidgetTester tester) async {
    await openStoreTools(tester);
    await tester.tap(find.byKey(const Key('work-business-settings')));
    await tester.pumpAndSettle();
  }

  // Current-contract replacements for the behavioural obligations retained in
  // the disabled historical Store 1-40 evidence group. Its rejected layouts
  // and reference images remain unchanged.
  for (final width in [320.0, 412.0]) {
    testWidgets('Store coverage - contextual equal rail at $width', (
      tester,
    ) async {
      final work = liveStore();
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: Size(width, width == 320 ? 568 : 915),
        textScale: width == 320 ? 1.4 : 1,
      );
      final keys = [
        'work-store-home',
        'work-store-orders',
        'work-store-sell',
        'work-store-stock',
      ];
      final centers = <double>[];
      for (final key in keys) {
        final action = find.byKey(Key(key));
        expect(action.hitTestable(), findsOneWidget);
        expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
        expect(
          tester.getRect(action).bottom,
          lessThanOrEqualTo((width == 320 ? 568 : 915) - 44),
        );
        centers.add(tester.getCenter(action).dx);
      }
      for (var index = 1; index < centers.length; index++) {
        expect(centers[index] - centers[index - 1], closeTo(width / 6, 1));
      }
      expect(find.text('Orders'), findsOneWidget);
      expect(find.byKey(const Key('work-local-earn')), findsNothing);
      expect(find.byKey(const Key('work-local-workspace')), findsNothing);
      expect(find.byKey(const Key('work-dashboard-hero')), findsNothing);
      expect(find.text(work.activeWorkspace!.name), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Store coverage - global Profile returns to the same live order',
    (tester) async {
      final work = storeViewFixture();
      final order = work.currentWorkspaceOrder;
      final deadline = work.workspaceOrderActionDeadline;
      await mount(tester, route: '/app/work/workspace/dashboard', work: work);
      await tester.tap(find.byKey(const Key('work-dashboard-profile')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('global-profile-panel-v2')), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-store-activity-deck')), findsOneWidget);
      expect(work.currentWorkspaceOrder, same(order));
      expect(work.workspaceOrderActionDeadline, deadline);
      expect(
        find.byKey(const Key('work-activity-order-accept')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Store coverage - search survives updates and Back ends search', (
    tester,
  ) async {
    final work = liveStore();
    final stock = List.of(work.workspaceCatalogueItems);
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    await tester.tap(find.byKey(const Key('work-dashboard-search')));
    await tester.pumpAndSettle();
    final field = find.byKey(const Key('work-dashboard-search-field'));
    await tester.enterText(field, 'fortune');
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    work.notifyListeners();
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(field).controller!.text, 'fortune');
    expect(work.workspaceSearchQuery, 'fortune');
    expect(field.hitTestable(), findsOneWidget);
    expect(tester.getRect(field).bottom, lessThanOrEqualTo(560));
    expect(find.byKey(const Key('work-local-navigation')), findsNothing);
    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-store-activity-deck')), findsOneWidget);
    expect(work.workspaceSearchQuery, isEmpty);
    expect(work.workspaceCatalogueItems, orderedEquals(stock));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Store coverage - settings require Save and Back can discard', (
    tester,
  ) async {
    final work = liveStore();
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    await openStoreSettings(tester);
    final state = find.byKey(const Key('work-status-store-state'));
    await tester.tap(find.descendant(of: state, matching: find.text('Off')));
    await tester.pumpAndSettle();
    expect(work.workspaceStoreState, WorkspaceStoreState.open);
    expect(work.workspaceAcceptingOrders, isTrue);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('work-settings-discard-dialog')),
      findsOneWidget,
    );
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<SegmentedButton<WorkspaceStoreState>>(state).selected,
      {WorkspaceStoreState.off},
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-store-activity-deck')), findsOneWidget);
    expect(work.workspaceStoreState, WorkspaceStoreState.open);
    expect(work.workspaceVisibleToCustomers, isTrue);
    await openStoreSettings(tester);
    await tester.tap(find.descendant(of: state, matching: find.text('Paused')));
    await tester.pumpAndSettle();
    final visibility = find.byKey(const Key('work-status-visibility'));
    await reveal(tester, visibility);
    await tester.tap(visibility);
    expect(work.workspaceVisibleToCustomers, isTrue);
    await tester.tap(find.byKey(const Key('work-status-save')));
    await tester.pumpAndSettle();
    expect(work.workspaceStoreState, WorkspaceStoreState.paused);
    expect(work.workspaceAcceptingOrders, isFalse);
    expect(work.workspaceReopensAt, 'In 1 hour');
    expect(work.workspaceVisibleToCustomers, isFalse);
    expect(find.byKey(const Key('work-store-activity-deck')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Store coverage - preview visibility does not reopen ordering', (
    tester,
  ) async {
    final work = liveStore()
      ..workspaceStoreState = WorkspaceStoreState.off
      ..workspaceAcceptingOrders = false;
    final products = List.of(work.workspaceCatalogueItems);
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    await openStoreTools(tester);
    await tester.tap(find.byKey(const Key('work-business-preview')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('work-dashboard-preview-screen')),
      findsOneWidget,
    );
    expect(
      find.byKey(Key('work-preview-product-${products.first.id}')),
      findsOneWidget,
    );
    final visibility = find.byKey(const Key('work-preview-visibility'));
    await reveal(tester, visibility);
    await tester.tap(visibility);
    await tester.pumpAndSettle();
    expect(work.workspaceVisibleToCustomers, isFalse);
    expect(work.workspaceStoreState, WorkspaceStoreState.off);
    expect(work.workspaceAcceptingOrders, isFalse);
    expect(work.workspaceCatalogueItems, orderedEquals(products));
    expect(tester.takeException(), isNull);
  });

  for (final missingSetup in [true, false]) {
    testWidgets(
      'Store coverage - truthful attention and Back setup=$missingSetup',
      (tester) async {
        final work = liveStore()
          ..retailerSetupSaved = !missingSetup
          ..primaryMobile = '9829012321'
          ..primaryMobileVerified = !missingSetup
          ..contactEmail = 'asha@example.com'
          ..contactEmailVerified = !missingSetup
          ..workspaceOrderCustomer = '';
        work.workspaceCatalogueItems.clear();
        work.workspaceOrders.clear();
        await mount(tester, route: '/app/work/workspace/dashboard', work: work);
        await tester.tap(find.byKey(const Key('work-dashboard-alerts')));
        await tester.pumpAndSettle();
        if (missingSetup) {
          expect(
            find.byKey(const Key('work-alert-contact-details')),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('work-alert-store-setup')),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('work-alert-dismiss-store-setup')),
            findsNothing,
          );
          expect(
            find.byKey(const Key('work-dashboard-alerts-empty')),
            findsNothing,
          );
        } else {
          expect(
            find.byKey(const Key('work-dashboard-alerts-empty')),
            findsOneWidget,
          );
          expect(find.text('Nothing needs attention'), findsOneWidget);
        }
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-store-activity-deck')),
          findsOneWidget,
        );
        expect(work.retailerSetupSaved, !missingSetup);
        expect(work.workspaceOrders, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Store coverage - growth stays separate from stock purchasing', (
    tester,
  ) async {
    await mount(
      tester,
      route: '/app/work/workspace/dashboard',
      work: liveStore(),
    );
    await openStoreTools(tester);
    await tester.tap(find.byKey(const Key('work-business-grow')));
    await tester.pumpAndSettle();
    final growth = find.byKey(const Key('work-grow-destination'));
    expect(growth, findsOneWidget);
    for (final key in [
      'customers',
      'offers',
      'social',
      'paid-work',
      'services',
    ]) {
      final action = find.byKey(Key('work-growth-$key'));
      await reveal(tester, action);
      expect(action.hitTestable(), findsOneWidget);
    }
    expect(
      find.descendant(
        of: growth,
        matching: find.text('Buy stock at wholesale'),
      ),
      findsNothing,
    );
    expect(find.text('Publish paid work'), findsNothing);
    expect(find.text('Post requirement'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Store coverage - first-use priorities do not invent business', (
    tester,
  ) async {
    final work = WorkSession()..seedVerifiedWorkspace();
    work.workspaceCatalogueItems.clear();
    work.workspaceOrders.clear();
    work.workspaceSalesToday = 0;
    work.workspaceSettlementBalance = 0;
    work.workspaceOrderCustomer = '';
    work.activeGroupBuy = null;
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    expect(find.byKey(const Key('work-dashboard-hero')), findsNothing);
    expect(find.byKey(const Key('work-dashboard-live-metrics')), findsNothing);
    expect(find.byKey(const Key('work-store-recent-sales')), findsNothing);
    expect(find.byKey(const Key('work-activity-order-accept')), findsNothing);
    expect(find.byKey(const Key('work-activity-group-bulk')), findsNothing);
    expect(
      find.byKey(const Key('work-store-stock')).hitTestable(),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('work-dashboard-alerts')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-alert-store-setup')), findsOneWidget);
    expect(work.workspaceOrders, isEmpty);
    expect(work.workspaceSalesToday, 0);
    expect(work.workspaceSettlementBalance, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Store coverage - refresh never strands or fabricates activity', (
    tester,
  ) async {
    final updated = DateTime(2026, 9, 3, 8, 30);
    final work = liveStore()
      ..workspaceDashboardState = WorkspaceDashboardState.offline
      ..workspaceLastUpdatedAt = updated;
    final products = List.of(work.workspaceCatalogueItems);
    final sales = work.workspaceSalesToday;
    final balance = work.workspaceSettlementBalance;
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    expect(find.text('Showing saved store activity'), findsOneWidget);
    for (var attempt = 0; attempt < 2; attempt++) {
      final retry = find.byKey(const Key('work-dashboard-retry'));
      await reveal(tester, retry);
      await tester.tap(retry);
      await tester.pump();
      expect(work.workspaceDashboardState, WorkspaceDashboardState.failed);
      expect(find.text('Refreshing store activity'), findsNothing);
      expect(
        find.text(
          'Live store updates are unavailable. Your saved records are unchanged.',
        ),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(work.workspaceLastUpdatedAt, updated);
      expect(work.workspaceCatalogueItems, orderedEquals(products));
      expect(work.workspaceSalesToday, sales);
      expect(work.workspaceSettlementBalance, balance);
      if (attempt == 0) {
        await captureStoreView(tester, 'r665-store-refresh-unavailable');
      }
    }
    final newer = updated.add(const Duration(minutes: 1));
    work.setWorkspaceDashboardState(
      WorkspaceDashboardState.ready,
      lastUpdatedAt: newer,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-dashboard-sync-state')), findsNothing);
    expect(work.workspaceLastUpdatedAt, newer);
    await captureStoreView(tester, 'r665-store-refresh-ready-snapshot');
    expect(tester.takeException(), isNull);
  });

  Future<void> openExistingDeliveryDraft(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('work-store-sell')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-sale-source')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-sell-source-phone')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-sale-delivery')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-order-receive-mool-delivery')));
    await tester.pumpAndSettle();
  }

  Future<void> enterSaleCustomer(WidgetTester tester, String phone) async {
    await tester.tap(find.byKey(const Key('work-sale-customer')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('work-order-customer')), phone);
    await tester.tap(find.byKey(const Key('work-sale-customer-confirm')));
    await tester.pumpAndSettle();
  }

  void expectHeaderAndStickyAction(
    WidgetTester tester, {
    bool wrappedHeader = false,
  }) {
    final titleFinder = find.byKey(const Key('work-page-title'));
    final subtitleFinder = find.byKey(const Key('work-page-subtitle'));
    expect(
      tester.widget<Text>(titleFinder).overflow,
      isIn([TextOverflow.clip, TextOverflow.ellipsis]),
    );
    if (wrappedHeader) {
      final bounds = tester.getRect(find.byType(AppBar));
      for (final text in [titleFinder, subtitleFinder]) {
        expect(tester.widget<Text>(text).maxLines, isNull);
        final paragraph = tester.renderObject<RenderParagraph>(
          find.descendant(of: text, matching: find.byType(RichText)),
        );
        expect(paragraph.softWrap, isTrue);
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(tester.getRect(text).top, greaterThanOrEqualTo(bounds.top));
        expect(tester.getRect(text).bottom, lessThanOrEqualTo(bounds.bottom));
      }
    } else {
      expect(tester.widget<Text>(subtitleFinder).maxLines, 2);
    }
    expect(tester.getRect(titleFinder).right, lessThanOrEqualTo(360));
    expect(tester.getRect(subtitleFinder).right, lessThanOrEqualTo(360));
    final sticky = find.byKey(const Key('work-sticky-action-bar'));
    final navigation = find.byKey(const Key('work-local-navigation'));
    expect(sticky, findsOneWidget);
    expect(navigation, findsOneWidget);
    expect(
      tester.getBottomRight(sticky).dy,
      lessThanOrEqualTo(tester.getTopRight(navigation).dy),
    );
  }

  void expectStoreNavigationOwnsProcurement(WidgetTester tester) {
    final storeNavigation = find.byKey(const Key('work-local-navigation'));
    final buyNavigation = find.byKey(
      const ValueKey('buy-local-destination-tabs'),
    );
    expect(storeNavigation, findsOneWidget);
    if (buyNavigation.evaluate().isNotEmpty) {
      expect(buyNavigation.hitTestable(), findsNothing);
      final buyRect = tester.getRect(buyNavigation);
      final viewport = tester.getRect(
        find.byKey(const Key('work-store-procurement-screen')),
      );
      expect(buyRect.top, greaterThanOrEqualTo(viewport.bottom - 1));
    }
  }

  WorkSession selectedRetailer() => WorkSession()
    ..selectFamily('products-trade')
    ..selectProfile('retailer-grocery');

  WorkspaceCatalogueItem catalogueProduct(int index, {int stock = 12}) =>
      WorkspaceCatalogueItem(
        id: 'store-product-$index',
        canonicalId: 'store-canonical-$index',
        categoryId: 'grocery-staples',
        brand: 'Store Brand',
        title: 'Daily grocery product $index',
        variant: 'Regular',
        pack: '${index + 1} kg pack',
        sku: 'STORE-SKU-$index',
        barcode: '89000000000$index',
        purchasePrice: 80 + index,
        sellingPrice: 95 + index,
        unitPrice: '₹${95 + index}/pack',
        stock: stock,
        deliveryPromise: 'Store pickup or local delivery',
        origin: 'India',
        visualLabel: 'Daily grocery product $index',
        visualKind: 'catalogue-packshot',
        mrp: 100 + index,
      );

  void seedIncomingOrder(
    WorkSession work, {
    String stage = 'Confirmed',
    bool delivery = false,
  }) {
    work
      ..workspaceOrderCustomer = 'Rakesh · 98290 12345'
      ..workspaceOrderSource = 'App'
      ..workspaceOrderItems = 'Fortune Oil × 2 · Aashirvaad Atta × 1'
      ..workspaceOrderAmount = '1468'
      ..workspaceOrderStage = stage
      ..workspaceOrderPayment = 'Paid online'
      ..workspaceOrderFulfilment = delivery ? 'Mool delivery' : 'Pickup'
      ..workspaceOrderNeedsDelivery = delivery
      ..workspaceOrderAddress = '12 Market Road, Sardarpura';
  }

  for (final display in [
    (412.0, 915.0, 1.0),
    (320.0, 640.0, 1.4),
    (320.0, 640.0, 2.0),
  ]) {
    for (final surface in ['product', 'order', 'alert']) {
      for (final amount in [264, 10000000000, 100000000000]) {
        testWidgets('S09 ancillary amount $surface $amount $display', (
          tester,
        ) async {
          final work = storeViewFixture()..workspaceOrderAmount = '$amount';
          work.workspaceOrders[0] = work.workspaceOrders.first.copyWith(
            amount: amount,
          );
          final product = work.workspaceCatalogueItems.first.copyWith(
            sellingPrice: amount,
            mrp: amount,
          );
          work.workspaceCatalogueItems[0] = product;
          final records = List<WorkspaceOrderRecord>.of(work.workspaceOrders);
          final balance = work.workspaceSettlementBalance;
          await mount(
            tester,
            route: '/app/work/workspace/dashboard',
            work: work,
            viewport: Size(display.$1, display.$2),
            textScale: display.$3,
          );
          if (surface == 'alert') {
            await tester.tap(find.byKey(const Key('work-dashboard-alerts')));
          } else {
            await tester.tap(find.byKey(const Key('work-dashboard-search')));
            await tester.pumpAndSettle();
            await tester.enterText(
              find.byKey(const Key('work-dashboard-search-field')),
              surface == 'product' ? product.title : 'Rakesh',
            );
          }
          await tester.pumpAndSettle();
          final row = find.byKey(
            Key(switch (surface) {
              'product' => 'work-search-product-${product.id}',
              'order' =>
                'work-search-order-${work.currentWorkspaceOrderId ?? 'current-store-order'}',
              _ =>
                'work-alert-order-${work.currentWorkspaceOrderId ?? 'current-store-order'}',
            }),
          );
          await reveal(tester, row);
          final total = find.descendant(
            of: row,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Text &&
                  RegExp(r'₹[\d,]+').hasMatch(widget.data ?? ''),
            ),
          );
          expect(total, findsOneWidget);
          await reveal(tester, total);
          if (amount == 10000000000) {
            await captureStoreView(
              tester,
              'r665-ancillary-$surface-${display.$1}-${display.$3}',
            );
          }
          final text = tester.widget<Text>(total).data!;
          final money = RegExp(r'₹[\d,]+').firstMatch(text)!;
          if (surface == 'product') {
            expectExactMoneyVisible(tester, total);
          }
          expect(money.group(0)!.replaceAll(RegExp(r'[₹,]'), ''), '$amount');
          final paragraph = tester.renderObject<RenderParagraph>(total);
          final boxes = paragraph.getBoxesForSelection(
            TextSelection(baseOffset: money.start, extentOffset: money.end),
          );
          expect(
            boxes,
            hasLength(1),
            reason: 'Complete amount must stay together',
          );
          final painter = TextPainter(
            text: TextSpan(
              text: money.group(0),
              style: (paragraph.text as TextSpan).style,
            ),
            textDirection: paragraph.textDirection,
            textScaler: paragraph.textScaler,
          )..layout();
          expect(
            boxes.single.right - boxes.single.left,
            greaterThanOrEqualTo(painter.width - .5),
            reason: 'Ellipsis must not hide any amount digits',
          );
          painter.dispose();
          expect(
            boxes.single.right,
            lessThanOrEqualTo(paragraph.size.width + .5),
          );
          expect(paragraph.textScaler.scale(1), closeTo(display.$3, .01));
          expect(tester.takeException(), isNull);
          expect(work.workspaceOrders, orderedEquals(records));
          expect(work.workspaceCatalogueItems.first, product);
          expect(work.workspaceOrderAmount, '$amount');
          expect(work.workspaceSettlementBalance, balance);
          expect(work.workspaceInvoices, isEmpty);
          if (surface == 'product') {
            await reveal(tester, row);
            expect(row.hitTestable(), findsOneWidget);
            await tester.tap(row);
            await tester.pumpAndSettle();
            expect(
              find.byKey(Key('work-catalogue-price-${product.id}')),
              findsOneWidget,
            );
            expect(work.workspaceCatalogueItems.first, product);
          }
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('work-workspace-dashboard')),
            findsOneWidget,
          );
          expect(work.currentWorkspaceOrderId, 'APP-1043');
          expect(work.workspaceOrders, orderedEquals(records));
          expect(tester.takeException(), isNull);
        });
      }
    }
    testWidgets('S09 pulse column amounts $display', (tester) async {
      final work = storeViewFixture();
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: Size(display.$1, display.$2),
        textScale: display.$3,
      );
      for (final value in [
        17820,
        28450,
        99999,
        100000,
        10000000000,
        100000000000,
      ]) {
        final exact = {
          17820: '₹17,820',
          28450: '₹28,450',
          99999: '₹99,999',
          100000: '₹1,00,000',
          10000000000: '₹10,00,00,00,000',
          100000000000: '₹1,00,00,00,00,000',
        }[value]!;
        work.workspaceSalesToday = value;
        work.workspaceSettlementBalance = value;
        work.workspaceOrders[1] = work.workspaceOrders[1].copyWith(
          amount: value,
        );
        work.setWorkspaceMoneyPeriod('Today');
        await tester.pumpAndSettle();
        for (final key in [
          'work-pulse-sales',
          'work-pulse-dues',
          'work-pulse-settlement',
        ]) {
          final metric = find.byKey(Key(key));
          await reveal(tester, metric);
          final action = switch (key) {
            'work-pulse-sales' => 'View statement',
            'work-pulse-dues' => 'Collect dues',
            _ => 'Settle',
          };
          final fullValue = find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                (widget.properties.label?.startsWith('$action,') ?? false) &&
                (widget.properties.label?.endsWith('$exact in store records') ??
                    false),
          );
          expect(fullValue, findsOneWidget);
          expect(
            tester.widget<Semantics>(fullValue).properties.onTap,
            isNotNull,
          );
          final total = find.descendant(
            of: metric,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Text &&
                  RegExp(r'^[≈]?₹').hasMatch(widget.data ?? ''),
            ),
          );
          expect(total, findsOneWidget);
          final paragraph = tester.renderObject<RenderParagraph>(total);
          final text = tester.widget<Text>(total);
          final digits = RegExp(r'-?[\d,.]+').firstMatch(text.data!)!;
          final boxes = paragraph.getBoxesForSelection(
            TextSelection(baseOffset: digits.start, extentOffset: digits.end),
          );
          expect(boxes, hasLength(1), reason: '$key $value ${text.data}');
          expect(
            boxes.single.right,
            lessThanOrEqualTo(paragraph.size.width + .5),
          );
          expect(paragraph.didExceedMaxLines, isFalse);
          expect(paragraph.textScaler.scale(1), closeTo(display.$3, .01));
          expect(text.style!.fontSize, greaterThanOrEqualTo(14));
          expect(tester.takeException(), isNull);
        }
        expect(work.workspaceSalesToday, value);
        expect(work.workspaceSettlementBalance, value);
        expect(
          work.workspaceCustomerBook.fold<int>(
            0,
            (sum, customer) => sum + customer.amountDue,
          ),
          value,
        );
        if (value == 17820) {
          await captureStoreView(
            tester,
            'r665-pulse-columns-${display.$1}-${display.$3}',
          );
        }
      }
      expect(work.workspaceInvoices, isEmpty);
    });
    for (final surface in ['incoming', 'packing', 'details']) {
      for (final amount in [
        (264, '₹264'),
        (10000000000, '₹10,00,00,00,000'),
        (100000000000, '₹1,00,00,00,00,000'),
      ]) {
        testWidgets('S09 central amount $surface ${amount.$1} $display', (
          tester,
        ) async {
          final stage = surface == 'packing' ? 'Preparing' : 'Confirmed';
          final work = storeViewFixture()
            ..workspaceOrderStage = stage
            ..workspaceOrderAmount = '${amount.$1}';
          work.workspaceOrders[0] = work.workspaceOrders.first.copyWith(
            amount: amount.$1,
            stage: stage,
          );
          final orders = List<WorkspaceOrderRecord>.of(work.workspaceOrders);
          final balance = work.workspaceSettlementBalance;
          await mount(
            tester,
            route: '/app/work/workspace/dashboard',
            work: work,
            viewport: Size(display.$1, display.$2),
            textScale: display.$3,
          );
          if (surface == 'details') {
            final review = find.byKey(const Key('work-activity-order-review'));
            await reveal(tester, review);
            expect(review.hitTestable(), findsOneWidget);
            await tester.tap(review);
            await tester.pumpAndSettle();
          }
          final card = find.byKey(
            Key(switch (surface) {
              'incoming' => 'work-activity-incoming-order',
              'packing' => 'work-activity-packing',
              _ => 'work-store-exact-order',
            }),
          );
          var total = find.descendant(of: card, matching: find.text(amount.$2));
          final compact = total.evaluate().isEmpty;
          if (compact) {
            final disclosure = find.descendant(
              of: card,
              matching: find.byKey(const Key('work-order-exact-amount-open')),
            );
            await reveal(tester, disclosure);
            await Scrollable.ensureVisible(
              tester.element(disclosure),
              alignment: .5,
            );
            await tester.pumpAndSettle();
            if (amount.$1 == 10000000000) {
              await captureStoreView(
                tester,
                'r665-central-summary-$surface-${display.$1}-${display.$3}',
              );
            }
            expect(
              disclosure.hitTestable(),
              findsOneWidget,
              reason:
                  'Amount ${tester.getRect(disclosure)} inside ${tester.getRect(card)}',
            );
            expect(tester.getSize(disclosure).height, greaterThanOrEqualTo(48));
            final summary = find.descendant(
              of: disclosure,
              matching: find.text(
                amount.$1 == 10000000000 ? '₹1,000' : '₹10,000',
              ),
            );
            expectExactMoneyVisible(tester, summary);
            expect(
              find.descendant(of: disclosure, matching: find.text('cr')),
              findsOneWidget,
            );
            final semantics = tester.ensureSemantics();
            try {
              await tester.pump();
              final accessible = find.bySemanticsLabel(
                'APP-1043, order total ${amount.$2}. Show exact amount',
              );
              expect(accessible, findsOneWidget);
              expect(
                tester
                    .getSemantics(accessible)
                    .getSemanticsData()
                    .hasAction(SemanticsAction.tap),
                isTrue,
              );
            } finally {
              semantics.dispose();
            }
            await tester.tap(disclosure);
            await tester.pumpAndSettle();
            final dialog = find.byKey(
              const Key('work-order-exact-amount-dialog'),
            );
            expect(dialog, findsOneWidget);
            expect(
              find.descendant(of: dialog, matching: find.text('APP-1043')),
              findsOneWidget,
            );
            total = find.descendant(of: dialog, matching: find.text(amount.$2));
          }
          await reveal(tester, total);
          if (amount.$1 == 10000000000) {
            await captureStoreView(
              tester,
              'r665-central-$surface-${display.$1}-${display.$3}',
            );
          }
          expect(tester.takeException(), isNull);
          expectExactMoneyVisible(tester, total);
          final paragraph = tester.renderObject<RenderParagraph>(total);
          expect(paragraph.textScaler.scale(1), closeTo(display.$3, .01));
          expect(work.workspaceOrders, orderedEquals(orders));
          expect(work.currentWorkspaceOrderId, 'APP-1043');
          expect(work.workspaceOrderStage, stage);
          expect(work.workspaceOrderAmount, '${amount.$1}');
          expect(work.workspaceSettlementBalance, balance);
          expect(work.workspaceInvoices, isEmpty);
          if (compact) {
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            expect(
              find.byKey(const Key('work-order-exact-amount-dialog')),
              findsNothing,
            );
            expect(card, findsOneWidget);
            expect(work.currentWorkspaceOrderId, 'APP-1043');
          }
          if (surface == 'details') {
            final close = find.byKey(const Key('work-order-details-close'));
            await reveal(tester, close);
            expect(close.hitTestable(), findsOneWidget);
            await tester.tap(close);
            await tester.pumpAndSettle();
            expect(
              find.byKey(const Key('work-activity-incoming-order')),
              findsOneWidget,
            );
            expect(work.workspaceOrders, orderedEquals(orders));
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  for (final display in [
    (412.0, 915.0, 1.0),
    (320.0, 568.0, 1.4),
    (320.0, 568.0, 2.0),
  ]) {
    for (final stage in ['Confirmed', 'Preparing', 'Ready for pickup']) {
      for (final amount in <(int, String)>[
        (0, '₹0'),
        (264, '₹264'),
        (1000000000, '₹1,00,00,00,000'),
        (10000000000, '₹10,00,00,00,000'),
        (100000000000, '₹1,00,00,00,00,000'),
      ]) {
        testWidgets('S09 order totals $stage ${amount.$1} $display', (
          tester,
        ) async {
          final work = storeViewFixture()
            ..workspaceOrderStage = stage
            ..workspaceOrderAmount = '${amount.$1}';
          work.workspaceOrders[0] = work.workspaceOrders.first.copyWith(
            amount: amount.$1,
            stage: stage,
          );
          final original = work.workspaceOrders.first;
          final otherOrder = work.workspaceOrders.last;
          final balance = work.workspaceSettlementBalance;
          await mount(
            tester,
            route: '/app/work/workspace/dashboard',
            work: work,
            viewport: Size(display.$1, display.$2),
            textScale: display.$3,
          );
          await tester.tap(find.byKey(const Key('work-store-orders')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final ticket = find.ancestor(
            of: find.byKey(const Key('work-order-stage-label-APP-1043')),
            matching: find.byKey(const Key('work-live-order-ticket')),
          );
          expect(ticket, findsOneWidget);
          final total = find.descendant(
            of: ticket,
            matching: find.text(amount.$2),
          );
          await reveal(tester, total);
          expectExactMoneyVisible(tester, total);
          final paragraph = tester.renderObject<RenderParagraph>(total);
          expect(paragraph.textScaler.scale(1), closeTo(display.$3, .01));
          expect(
            (paragraph.text as TextSpan).style!.fontSize,
            greaterThanOrEqualTo(14),
          );
          if (amount.$1 == 10000000000) {
            await captureStoreView(
              tester,
              'r665-order-total-${stage.replaceAll(' ', '-')}-${display.$1}-${display.$3}',
            );
          }
          expect(work.workspaceOrders.first, same(original));
          expect(work.workspaceOrders.last, same(otherOrder));
          expect(work.workspaceOrderStage, stage);
          expect(work.workspaceOrderAmount, '${amount.$1}');
          expect(work.workspaceSettlementBalance, balance);
          expect(work.workspaceInvoices, isEmpty);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('work-store-activity-deck')),
            findsOneWidget,
          );
          expect(work.workspaceOrders.first, same(original));
          expect(work.workspaceOrders.last, same(otherOrder));
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  for (final display in [
    (412.0, 915.0, 1.0),
    (320.0, 568.0, 1.4),
    (320.0, 568.0, 2.0),
  ]) {
    testWidgets('S09 order totals compact create action $display', (
      tester,
    ) async {
      final work = storeViewFixture();
      final originalOrders = List<WorkspaceOrderRecord>.of(
        work.workspaceOrders,
      );
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: Size(display.$1, display.$2),
        textScale: display.$3,
      );
      await tester.tap(find.byKey(const Key('work-store-orders')));
      await tester.pumpAndSettle();
      final create = find.byKey(const Key('work-orders-create'));
      expect(create.hitTestable(), findsOneWidget);
      expect(tester.getSize(create).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(create).height, greaterThanOrEqualTo(48));
      final heading = tester.renderObject<RenderParagraph>(
        find.text('Customer orders'),
      );
      expect(
        heading.getBoxesForSelection(
          const TextSelection(baseOffset: 0, extentOffset: 8),
        ),
        hasLength(1),
        reason: 'Customer must not break inside the word',
      );
      expect(heading.textScaler.scale(1), closeTo(display.$3, .01));
      final orderScroll = find.descendant(
        of: find.byKey(const Key('work-orders-destination')),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        ),
      );
      expect(tester.getSize(orderScroll).height, greaterThanOrEqualTo(120));
      await captureStoreView(
        tester,
        'r665-order-first-view-${display.$1}-${display.$3}',
      );
      await tester.tap(create);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-dashboard-counter-order-screen')),
        findsOneWidget,
      );
      expect(work.currentWorkspaceOrderId, isNull);
      expect(work.workspaceOrderCustomer, isEmpty);
      expect(work.workspaceOrderQuantities, isEmpty);
      expect(work.workspaceOrderSource, 'Counter');
      expect(work.workspaceOrderFulfilment, 'At the shop');
      expect(work.workspaceOrders, orderedEquals(originalOrders));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-orders-destination')), findsOneWidget);
      expect(work.currentWorkspaceOrderId, 'APP-1043');
      expect(work.workspaceOrderCustomer, originalOrders.first.customer);
      expect(work.workspaceOrderStage, originalOrders.first.stage);
      expect(work.workspaceOrderPayment, originalOrders.first.payment);
      expect(work.workspaceOrderAmount, '${originalOrders.first.amount}');
      expect(work.workspaceOrders, orderedEquals(originalOrders));
      expect(work.workspaceInvoices, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('S09 order totals Create bill draft keep and discard', (
    tester,
  ) async {
    final work = storeViewFixture()..workspaceOrderStage = 'Preparing';
    work.workspaceOrders[0] = work.workspaceOrders.first.copyWith(
      stage: 'Preparing',
    );
    final originalOrders = List<WorkspaceOrderRecord>.of(work.workspaceOrders);
    final balance = work.workspaceSettlementBalance;
    work.setWorkspacePackingLine('summary-0', true);
    final packed = Set<String>.of(work.workspacePackedProductIds);
    expect(packed, isNotEmpty);
    await mount(
      tester,
      route: '/app/work/workspace/dashboard',
      work: work,
      viewport: const Size(320, 568),
      textScale: 2,
    );
    await tester.tap(find.byKey(const Key('work-store-orders')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-orders-create')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-sale-customer')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('work-order-customer')),
      '9876543210',
    );
    await reveal(tester, find.byKey(const Key('work-sale-customer-confirm')));
    await tester.tap(find.byKey(const Key('work-sale-customer-confirm')));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-order-discard-dialog')), findsOneWidget);
    await tester.tap(find.byKey(const Key('work-order-keep-editing')));
    await tester.pumpAndSettle();
    expect(work.workspaceOrderCustomer, '9876543210');
    expect(work.currentWorkspaceOrderId, isNull);
    expect(work.workspaceOrders, orderedEquals(originalOrders));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-order-discard')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-orders-destination')), findsOneWidget);
    expect(work.currentWorkspaceOrderId, 'APP-1043');
    expect(work.workspaceOrderCustomer, originalOrders.first.customer);
    expect(work.workspaceOrderPayment, originalOrders.first.payment);
    expect(work.workspacePackedProductIds, unorderedEquals(packed));
    expect(work.workspaceOrders, orderedEquals(originalOrders));
    expect(work.workspaceSettlementBalance, balance);
    expect(work.workspaceInvoices, isEmpty);
    expect(tester.takeException(), isNull);
  });

  WorkspaceOrderRecord customerOrder({
    required String id,
    required String customer,
    required DateTime createdAt,
    int amount = 264,
    String payment = 'Paid online',
    String stage = 'Completed',
  }) => WorkspaceOrderRecord(
    id: id,
    customer: customer,
    items: 'Fortune Sunflower Oil × 1',
    quantities: const {'oil-fortune-1l': 1},
    amount: amount,
    source: 'App',
    fulfilment: 'Pickup',
    payment: payment,
    address: '',
    stage: stage,
    needsDelivery: false,
    createdAt: createdAt,
  );

  for (final scale in [1.0, 2.0]) {
    testWidgets('Store search exact historical order preserves packing $scale', (
      tester,
    ) async {
      final work = storeViewFixture();
      work.workspaceOrders.addAll(
        List.generate(
          1000,
          (index) => customerOrder(
            id: 'HISTORY-${index.toString().padLeft(4, '0')}',
            customer:
                'History customer $index · 900000${index.toString().padLeft(4, '0')}',
            createdAt: DateTime(2026, 9, 1).add(Duration(minutes: index)),
          ),
        ),
      );
      work.workspaceOrderFilter = 'Packing';
      work.workspacePackedProductIds.add('summary-0');
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: scale == 1 ? const Size(412, 915) : const Size(320, 640),
        textScale: scale,
      );
      await tester.tap(find.byKey(const Key('work-dashboard-search')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('work-dashboard-search-field')),
        'HISTORY-0999',
      );
      await tester.pumpAndSettle();
      final result = find.byKey(const Key('work-search-order-HISTORY-0999'));
      expect(result, findsOneWidget);
      await captureStoreView(tester, 'search-history-result-$scale');
      await tester.ensureVisible(result);
      await tester.tap(result);
      await tester.pumpAndSettle();
      expect(find.text('Order details'), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('work-focused-order-id')))
            .data,
        'HISTORY-0999',
      );
      expect(
        find.byKey(const Key('work-order-stage-label-HISTORY-0999')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('work-order-stage-label-APP-1043')),
        findsNothing,
      );
      expect(find.byKey(const Key('work-orders-filter-strip')), findsNothing);
      expect(work.currentWorkspaceOrderId, 'APP-1043');
      expect(work.workspacePackedProductIds, contains('summary-0'));
      await captureStoreView(tester, 'search-history-first-tap-$scale');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(result, findsOneWidget);
      expect(work.workspaceSearchQuery, 'HISTORY-0999');
      expect(work.workspaceOrderFilter, 'Packing');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-workspace-dashboard')), findsOneWidget);
      expect(work.currentWorkspaceOrderId, 'APP-1043');
      expect(work.workspaceInvoices, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('Exact order purchased facts have no repeated summary $scale', (
      tester,
    ) async {
      final gateway = ReviewWorkGateway();
      final work = storeViewFixture(gateway);
      final order = WorkspaceOrderRecord(
        id: 'MS-1048',
        customer: 'Asha Mehta · 9001234567',
        items: 'Fortune Sunflower Oil × 2, Aashirvaad Atta × 5',
        quantities: const {'oil-fortune-1l': 2, 'atta-aashirvaad-1kg': 5},
        amount: 1068,
        source: 'App',
        fulfilment: 'MoolSocial delivery',
        payment: 'Paid online',
        address: '12 Market Road, Test Area',
        stage: 'Confirmed',
        needsDelivery: true,
        createdAt: DateTime(2026, 9, 10, 9, 30),
        itemSnapshots: const [
          WorkspaceOrderItemSnapshot(
            productId: 'oil-fortune-1l',
            name: 'Fortune Sunflower Oil',
            pack: '1 L',
            quantity: 2,
            unitPricePaise: 26400,
            lineTotalPaise: 52800,
          ),
          WorkspaceOrderItemSnapshot(
            productId: 'atta-aashirvaad-1kg',
            name: 'Aashirvaad Atta',
            pack: '1 kg',
            quantity: 5,
            unitPricePaise: 10800,
            lineTotalPaise: 54000,
          ),
        ],
      );
      work.workspaceOrders.add(order);
      work.workspaceCatalogueItems.add(
        workspaceMasterCatalogue
            .singleWhere((item) => item.id == 'atta-aashirvaad-1kg')
            .copyWith(stock: 20, available: true),
      );
      // Current catalogue pricing cannot change the purchased facts.
      work.workspaceCatalogueItems[0] = work.workspaceCatalogueItems.first
          .copyWith(sellingPrice: 9999);
      expect(order.hasCompleteItemSnapshot, isTrue);
      expect(
        order.copyWith(stage: 'Preparing').itemSnapshots,
        order.itemSnapshots,
      );
      expect(
        order
            .copyWith(quantities: const {'oil-fortune-1l': 3})
            .hasCompleteItemSnapshot,
        isFalse,
      );
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: const Size(412, 915),
        textScale: scale,
      );
      await tester.tap(find.byKey(const Key('work-dashboard-search')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('work-dashboard-search-field')),
        'MS-1048',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('work-search-order-MS-1048')));
      await tester.pumpAndSettle();
      expect(find.text('MS-1048'), findsOneWidget);
      expect(find.text('Asha Mehta · 9001234567'), findsOneWidget);
      expect(find.text('Paid online'), findsOneWidget);
      expect(find.text('₹1,068'), findsOneWidget);
      expect(find.text('12 Market Road, Test Area'), findsOneWidget);
      expect(find.text('2 × ₹264'), findsOneWidget);
      expect(find.text('₹9,999'), findsNothing);
      expect(find.text('Accept'), findsOneWidget);
      expect(find.byKey(const Key('work-order-open-MS-1048')), findsNothing);
      expect(
        find.byKey(const Key('work-exact-order-prices-unavailable')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
      await captureStoreView(tester, 'exact-order-purchased-facts-$scale');
      await tester.ensureVisible(find.text('Aashirvaad Atta'));
      await tester.pumpAndSettle();
      expect(find.text('Aashirvaad Atta').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(work.currentWorkspaceOrderId, 'APP-1043');
      if (scale == 1) {
        await tester.ensureVisible(find.text('Accept'));
        await tester.tap(find.text('Accept'));
        await tester.pumpAndSettle();
        expect(work.currentWorkspaceOrderId, 'MS-1048');
        expect(
          work.workspaceOrders.singleWhere((row) => row.id == 'MS-1048').stage,
          'Preparing',
        );
        expect(
          work.workspaceOrders.singleWhere((row) => row.id == 'APP-1043').stage,
          'Confirmed',
        );
        expect(work.workspaceInvoices, isEmpty);
        final persistedOrders =
            gateway.lastOperationalSnapshot!.state['orders'] as List;
        final persistedOrder = persistedOrders
            .cast<Map<String, Object?>>()
            .singleWhere((row) => row['id'] == 'MS-1048');
        final persistedItems = persistedOrder['itemSnapshots'] as List;
        expect(persistedItems.length, 2);
        expect((persistedItems.first as Map)['unitPricePaise'], 26400);
        expect((persistedItems.first as Map)['lineTotalPaise'], 52800);
        expect(find.text('Fortune Sunflower Oil'), findsNothing);
        expect(find.text('Fortune Sunflower Oil · 1 L × 2'), findsOneWidget);
      }
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(work.workspaceSearchQuery, 'MS-1048');
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('Store search empty state fits compact 200% keyboard', (
    tester,
  ) async {
    final work = storeViewFixture();
    await mount(
      tester,
      route: '/app/work/workspace/dashboard',
      work: work,
      viewport: const Size(320, 568),
      textScale: 2,
    );
    await tester.tap(find.byKey(const Key('work-dashboard-search')));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final field = find.byKey(const Key('work-dashboard-search-field'));
    await tester.enterText(field, 'No matching record');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final clear = find.descendant(
      of: find.byKey(const Key('work-dashboard-search-empty')),
      matching: find.byKey(const Key('work-dashboard-search-clear')),
    );
    await tester.ensureVisible(clear);
    await tester.pumpAndSettle();
    expect(clear.hitTestable(), findsOneWidget);
    await captureStoreView(tester, 'search-empty-compact-keyboard-2.0');
    await tester.tap(clear);
    await tester.pumpAndSettle();
    expect(work.workspaceSearchQuery, isEmpty);
    expect(tester.takeException(), isNull);
    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Store search stale order cannot open another record', (
    tester,
  ) async {
    final work = storeViewFixture();
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    await tester.tap(find.byKey(const Key('work-dashboard-search')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('work-dashboard-search-field')),
      'APP-1043',
    );
    await tester.pumpAndSettle();
    final retainedTap = tester
        .widget<MoolCardSurface>(
          find.byKey(const Key('work-search-order-APP-1043')),
        )
        .onTap!;
    work.workspaceOrders.removeWhere((order) => order.id == 'APP-1043');
    retainedTap();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-orders-destination')), findsNothing);
    expect(
      find.text('This order is no longer available. Search again.'),
      findsOneWidget,
    );
    expect(work.currentWorkspaceOrderId, 'APP-1043');
    expect(work.workspaceInvoices, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Store search same-name customers open the exact mobile record', (
    tester,
  ) async {
    final work = storeViewFixture();
    for (final phone in ['9001234510', '9001234511']) {
      work.workspaceOrders.add(
        customerOrder(
          id: 'CUSTOMER-$phone',
          customer: 'Ramesh · $phone',
          createdAt: DateTime(2026, 9, 9),
        ),
      );
    }
    await mount(
      tester,
      route: '/app/work/workspace/dashboard',
      work: work,
      textScale: 1,
    );
    await tester.tap(find.byKey(const Key('work-dashboard-search')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('work-dashboard-search-field')),
      'Ramesh',
    );
    await tester.pumpAndSettle();
    final results = find.byKey(const Key('work-dashboard-search-results'));
    final resultScroll = find
        .descendant(of: results, matching: find.byType(Scrollable))
        .first;
    final first = find.byKey(const Key('work-search-customer-9001234510'));
    expect(
      work.workspaceCustomerBook.map((customer) => customer.id),
      containsAll(['9001234510', '9001234511']),
    );
    expect(
      work.workspaceCustomerBook
          .where((customer) => customer.name == 'Ramesh')
          .map((customer) => customer.id),
      containsAll(['9001234510', '9001234511']),
      reason: work.workspaceCustomerBook
          .map((customer) => '${customer.id}: ${customer.name}')
          .join(', '),
    );
    await captureStoreView(tester, 'search-same-name-results');
    await tester.scrollUntilVisible(first, 250, scrollable: resultScroll);
    expect(first, findsOneWidget);
    final target = find.byKey(const Key('work-search-customer-9001234511'));
    await tester.scrollUntilVisible(target, 250, scrollable: resultScroll);
    await tester.tap(target);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-customer-9001234511')), findsOneWidget);
    expect(find.byKey(const Key('work-customer-9001234510')), findsNothing);
    expect(find.byKey(const Key('work-customer-search')), findsNothing);
    expect(work.currentWorkspaceOrderId, 'APP-1043');
    await captureStoreView(tester, 'search-exact-customer');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(work.workspaceSearchQuery, 'Ramesh');
    expect(target, findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Store search opens the exact invoice without sharing it', (
    tester,
  ) async {
    final work = storeViewFixture();
    work.workspaceInvoices.addAll([
      WorkspaceCustomerInvoice(
        id: 'INV-OTHER',
        orderId: 'ORDER-OTHER',
        customer: 'Test customer',
        items: 'Oil × 1',
        amount: 264,
        payment: 'Paid online',
        issuedAt: DateTime(2026, 9, 9),
      ),
      WorkspaceCustomerInvoice(
        id: 'INV-0999',
        orderId: 'ORDER-0999',
        customer: 'Test customer',
        items: 'Atta × 2',
        amount: 1200,
        payment: 'Paid online',
        issuedAt: DateTime(2026, 9, 9),
      ),
    ]);
    await mount(
      tester,
      route: '/app/work/workspace/dashboard',
      work: work,
      textScale: 1,
    );
    await tester.tap(find.byKey(const Key('work-dashboard-search')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('work-dashboard-search-field')),
      'INV-0999',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-search-invoice-INV-0999')));
    await tester.pumpAndSettle();
    expect(find.text('Send customer invoice'), findsOneWidget);
    expect(find.textContaining('INV-0999'), findsWidgets);
    expect(find.textContaining('INV-OTHER'), findsNothing);
    await captureStoreView(tester, 'search-exact-invoice');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('work-search-invoice-INV-0999')),
      findsOneWidget,
    );
    expect(
      work.workspaceInvoices.every((invoice) => invoice.sharedChannels.isEmpty),
      isTrue,
    );
    expect(work.currentWorkspaceOrderId, 'APP-1043');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Store search Back restores scrolled results', (tester) async {
    final work = storeViewFixture();
    work.workspaceOrders.addAll(
      List.generate(
        100,
        (index) => customerOrder(
          id: 'SEARCH-$index',
          customer: 'Customer $index',
          createdAt: DateTime(2026, 9, 9),
        ),
      ),
    );
    await mount(
      tester,
      route: '/app/work/workspace/dashboard',
      work: work,
      textScale: 1,
    );
    await tester.tap(find.byKey(const Key('work-dashboard-search')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('work-dashboard-search-field')),
      'SEARCH-',
    );
    await tester.pumpAndSettle();
    final results = find.byKey(const Key('work-dashboard-search-results'));
    final target = find.byKey(const Key('work-search-order-SEARCH-40'));
    await tester.scrollUntilVisible(
      target,
      400,
      scrollable: find
          .descendant(of: results, matching: find.byType(Scrollable))
          .first,
      maxScrolls: 50,
    );
    await tester.pumpAndSettle();
    final before = tester.widget<ListView>(results).controller!.offset;
    expect(before, greaterThan(0));
    await tester.tap(target);
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      tester.widget<ListView>(results).controller!.offset,
      closeTo(before, .5),
    );
    expect(target.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Store search retained result cannot cross stores', (
    tester,
  ) async {
    final work = storeViewFixture();
    await mount(
      tester,
      route: '/app/work/workspace/dashboard',
      work: work,
      textScale: 1,
    );
    await tester.tap(find.byKey(const Key('work-dashboard-search')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('work-dashboard-search-field')),
      'APP-1043',
    );
    await tester.pumpAndSettle();
    final oldTap = tester
        .widget<MoolCardSurface>(
          find.byKey(const Key('work-search-order-APP-1043')),
        )
        .onTap!;
    final store = work.activeWorkspace!;
    work.activateWorkspace(
      WorkWorkspace(
        id: 'SEARCH-OTHER-STORE',
        name: 'Second Store',
        profileLabel: store.profileLabel,
        profileId: store.profileId,
        area: store.area,
        verified: true,
      ),
    );
    oldTap();
    await tester.pumpAndSettle();
    expect(work.currentWorkspaceOrderId, isNull);
    expect(work.visibleWorkspaceOrders, isEmpty);
    expect(find.byKey(const Key('work-orders-destination')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'Store alerts exact live records and resolved recovery $scale',
      (tester) async {
        final work = storeViewFixture();
        final now = DateTime.now();
        work.workspaceOrders.addAll([
          customerOrder(
            id: 'MS-1050',
            customer: 'Asha Mehta',
            createdAt: now,
            stage: 'Preparing',
          ),
          customerOrder(
            id: 'MS-1051',
            customer: 'Ravi Sharma',
            createdAt: now,
            stage: 'Ready for pickup',
          ),
          customerOrder(
            id: 'MS-1052',
            customer: 'Neha Verma',
            createdAt: now,
            stage: 'Delivery requested',
          ),
        ]);
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: const Size(412, 915),
          textScale: scale,
        );
        await tester.tap(find.byKey(const Key('work-dashboard-alerts')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-alert-order-SALE-1042')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('work-alert-customer-order')),
          findsNothing,
        );
        await captureStoreView(tester, 'alerts-multiple-states-$scale');
        final target = find.byKey(const Key('work-alert-action-order-MS-1050'));
        final list = find.byKey(const Key('work-dashboard-alerts-screen'));
        final scrollable = find
            .descendant(of: list, matching: find.byType(Scrollable))
            .first;
        await tester.scrollUntilVisible(target, 180, scrollable: scrollable);
        for (
          var attempt = 0;
          attempt < 8 && target.hitTestable().evaluate().isEmpty;
          attempt++
        ) {
          await tester.drag(list, const Offset(0, -180));
          await tester.pumpAndSettle();
        }
        expect(target.hitTestable(), findsOneWidget);
        final savedScroll = tester
            .state<ScrollableState>(scrollable)
            .position
            .pixels;
        final retainedTap = tester.widget<InkWell>(target).onTap!;
        await tester.tap(target);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('work-focused-order-id')), findsOneWidget);
        expect(find.text('MS-1050'), findsOneWidget);
        expect(work.currentWorkspaceOrderId, 'APP-1043');
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          tester.state<ScrollableState>(scrollable).position.pixels,
          closeTo(savedScroll, 0.5),
        );
        final index = work.workspaceOrders.indexWhere(
          (order) => order.id == 'MS-1050',
        );
        work.workspaceOrders[index] = work.workspaceOrders[index].copyWith(
          stage: 'Completed',
        );
        retainedTap();
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('work-orders-destination')), findsNothing);
        expect(find.text('This alert no longer needs action.'), findsOneWidget);
        expect(find.byKey(const Key('work-alert-order-MS-1050')), findsNothing);
        expect(work.currentWorkspaceOrderId, 'APP-1043');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('Store alerts compact right actions stay readable $scale', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        final work = storeViewFixture();
        work.workspaceOrders.add(
          customerOrder(
            id: 'TRACK-1053',
            customer: 'Annapurna Narayanaswamy',
            createdAt: DateTime.now(),
            stage: 'Delivery requested',
          ),
        );
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: scale == 1 ? const Size(412, 915) : const Size(320, 568),
          textScale: scale,
        );
        await tester.tap(find.byKey(const Key('work-dashboard-alerts')));
        await tester.pumpAndSettle();
        final title = find.byKey(const Key('work-alert-title-order-APP-1043'));
        final review = find.byKey(const Key('work-alert-cta-order-APP-1043'));
        final firstRow = find.byKey(const Key('work-alert-order-APP-1043'));
        final reviewButton = tester.widget<FilledButton>(review);
        expect(reviewButton.onPressed, isNotNull);
        expect(
          reviewButton.style!.backgroundColor!.resolve({}),
          MoolColors.navy,
        );
        expect(reviewButton.style!.foregroundColor!.resolve({}), Colors.white);
        expect(tester.getSize(review).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(review).height, greaterThanOrEqualTo(48));
        expect(
          find.descendant(of: firstRow, matching: find.text('Review')),
          findsOneWidget,
        );
        if (scale == 1) {
          expect(
            tester.getCenter(review).dy,
            closeTo(tester.getCenter(title).dy, 1),
          );
          expect(
            tester.getRect(review).left,
            greaterThan(tester.getRect(title).right),
          );
          // The former stacked-action row was about 138 px in this fixture.
          expect(tester.getSize(firstRow).height, lessThan(125));
        } else {
          final details = find.byKey(
            const Key('work-alert-detail-order-APP-1043'),
          );
          expect(
            tester.getRect(review).top,
            greaterThan(tester.getRect(details).bottom),
          );
        }
        final list = find.byKey(const Key('work-dashboard-alerts-screen'));
        final track = find.byKey(const Key('work-alert-cta-order-TRACK-1053'));
        final scrollable = find
            .descendant(of: list, matching: find.byType(Scrollable))
            .first;
        await tester.scrollUntilVisible(track, 120, scrollable: scrollable);
        await tester.ensureVisible(track);
        await tester.pumpAndSettle();
        expect(track.hitTestable(), findsOneWidget);
        expect(tester.getSize(track).height, greaterThanOrEqualTo(48));
        final paragraph = tester.renderObject<RenderParagraph>(
          find.descendant(of: track, matching: find.byType(RichText)).first,
        );
        expect(paragraph.didExceedMaxLines, isFalse);
        expect((paragraph.text as TextSpan).style!.fontFamily, 'Inter');
        expect(
          tester.getSemantics(track).getSemanticsData().label,
          contains('Track delivery: TRACK-1053 · Annapurna Narayanaswamy'),
        );
        await captureStoreView(tester, 'alerts-right-action-compact-$scale');
        await tester.tap(track);
        await tester.pumpAndSettle();
        expect(find.text('TRACK-1053'), findsOneWidget);
        expect(work.currentWorkspaceOrderId, 'APP-1043');
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(list, findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets('Store alerts 1000 records address the last exact order', (
    tester,
  ) async {
    final work = storeViewFixture();
    work.workspaceOrders.addAll(
      List.generate(
        1000,
        (index) => customerOrder(
          id: 'ALERT-${index.toString().padLeft(4, '0')}',
          customer: 'Customer $index',
          createdAt: DateTime.now(),
          stage: index.isEven ? 'Confirmed' : 'Preparing',
        ),
      ),
    );
    await mount(
      tester,
      route: '/app/work/workspace/dashboard',
      work: work,
      textScale: 1,
    );
    await tester.tap(find.byKey(const Key('work-dashboard-alerts')));
    await tester.pumpAndSettle();
    final list = find.byKey(const Key('work-dashboard-alerts-screen'));
    final scroll = tester.widget<ListView>(list).controller!;
    // Lazy rows need not all be built to reach the final loaded alert.
    for (var attempt = 0; attempt < 6; attempt++) {
      scroll.jumpTo(scroll.position.maxScrollExtent);
      await tester.pumpAndSettle();
    }
    final target = find.byKey(const Key('work-alert-action-order-ALERT-0999'));
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    expect(target.hitTestable(), findsOneWidget);
    expect(find.byKey(const Key('work-alert-order-ALERT-0001')), findsNothing);
    await tester.tap(target);
    await tester.pumpAndSettle();
    expect(find.text('ALERT-0999'), findsOneWidget);
    expect(work.currentWorkspaceOrderId, 'APP-1043');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Store alerts retained action cannot cross stores', (
    tester,
  ) async {
    final work = storeViewFixture();
    await mount(
      tester,
      route: '/app/work/workspace/dashboard',
      work: work,
      textScale: 1,
    );
    await tester.tap(find.byKey(const Key('work-dashboard-alerts')));
    await tester.pumpAndSettle();
    final retainedTap = tester
        .widget<InkWell>(
          find.byKey(const Key('work-alert-action-order-APP-1043')),
        )
        .onTap!;
    final store = work.activeWorkspace!;
    work.activateWorkspace(
      WorkWorkspace(
        id: 'ALERT-OTHER-STORE',
        name: 'Second Store',
        profileId: store.profileId,
        profileLabel: store.profileLabel,
        area: store.area,
        verified: true,
      ),
    );
    retainedTap();
    await tester.pumpAndSettle();
    expect(work.currentWorkspaceOrderId, isNull);
    expect(work.visibleWorkspaceOrders, isEmpty);
    expect(find.byKey(const Key('work-orders-destination')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'Store reject requires confirmation and Back preserves order $scale',
      (tester) async {
        final gateway = ReviewWorkGateway();
        final work = storeViewFixture(gateway);
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          textScale: scale,
        );
        await tester.tap(find.text('Reject'));
        await tester.pumpAndSettle();
        final dialog = find.byKey(const Key('work-reject-order-dialog'));
        final confirm = find.descendant(
          of: dialog,
          matching: find.byType(FilledButton),
        );
        expect(work.workspaceOrderStage, 'Confirmed');
        expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
        await tester.tap(find.text('Product unavailable'));
        await tester.pumpAndSettle();
        expect(confirm.hitTestable(), findsOneWidget);
        await captureStoreView(tester, 'reject-confirmation-$scale');
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(work.workspaceOrderStage, 'Confirmed');
        expect(gateway.operationalSaveCalls, 0);
        await tester.tap(find.text('Reject'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Product unavailable'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(confirm);
        await tester.pumpAndSettle();
        expect(confirm.hitTestable(), findsOneWidget);
        await tester.tap(confirm);
        await tester.pumpAndSettle();
        expect(work.workspaceOrderStage, 'Cancelled');
        expect(
          work.currentWorkspaceOrder!.rejectionReason,
          'Product unavailable',
        );
        expect(gateway.operationalSaveCalls, 1);
        final savedOrders =
            gateway.lastOperationalSnapshot!.state['orders'] as List;
        expect(
          savedOrders.cast<Map<String, Object?>>().singleWhere(
            (order) => order['id'] == 'APP-1043',
          )['rejectionReason'],
          'Product unavailable',
        );
        expect(work.workspaceInvoices, isEmpty);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets('Store reject stale confirmation cannot cancel another order', (
    tester,
  ) async {
    final work = storeViewFixture();
    work.workspaceOrders.add(
      customerOrder(
        id: 'OTHER-ORDER',
        customer: 'Another customer',
        createdAt: DateTime.now(),
        stage: 'Confirmed',
      ),
    );
    await mount(
      tester,
      route: '/app/work/workspace/dashboard',
      work: work,
      textScale: 1,
    );
    await tester.tap(find.text('Reject'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Product unavailable'));
    await tester.pumpAndSettle();
    expect(work.selectWorkspaceOrder('OTHER-ORDER'), isTrue);
    await tester.pumpAndSettle();
    final confirm = find.descendant(
      of: find.byKey(const Key('work-reject-order-dialog')),
      matching: find.byType(FilledButton),
    );
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(
      work.workspaceOrders.where((order) => order.stage == 'Cancelled'),
      isEmpty,
    );
    expect(
      find.text('This order changed. Review its latest status.'),
      findsOneWidget,
    );
    expect(work.currentWorkspaceOrderId, 'OTHER-ORDER');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final update in ['removed', 'price changed', 'expired']) {
    testWidgets('Store reject rechecks an order that is $update', (
      tester,
    ) async {
      final work = storeViewFixture();
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        textScale: 1,
      );
      await tester.tap(find.text('Reject'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Product unavailable'));
      await tester.pumpAndSettle();
      final index = work.workspaceOrders.indexWhere(
        (order) => order.id == 'APP-1043',
      );
      if (update == 'removed') {
        work.workspaceOrders.removeAt(index);
      } else {
        work.workspaceOrders[index] = update == 'expired'
            ? work.workspaceOrders[index].copyWith(
                actionDeadline: DateTime.now().subtract(
                  const Duration(seconds: 1),
                ),
              )
            : work.workspaceOrders[index].copyWith(amount: 1500);
      }
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('work-reject-order-dialog')),
          matching: find.byType(FilledButton),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        work.workspaceOrders.where((order) => order.stage == 'Cancelled'),
        isEmpty,
      );
      expect(
        find.text('This order changed. Review its latest status.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final scale in [1.0, 1.4, 2.0]) {
    testWidgets('Store queue 1000 local records and first action $scale', (
      tester,
    ) async {
      final work = storeViewFixture();
      const stages = [
        'Confirmed',
        'Preparing',
        'Ready',
        'Delivery requested',
        'Completed',
      ];
      work.workspaceOrders.addAll(
        List.generate(
          1000,
          (index) => customerOrder(
            id: 'QUEUE-${index.toString().padLeft(4, '0')}',
            customer: 'Customer ${index + 1}',
            stage: stages[index % stages.length],
            createdAt: DateTime(2026, 9, 7, 8).add(Duration(seconds: index)),
          ),
        ),
      );
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: scale == 1 ? const Size(412, 915) : const Size(320, 640),
        textScale: scale,
      );
      expect(find.text('201\nAccept', findRichText: true), findsOneWidget);
      expect(find.text('200\nPack', findRichText: true), findsOneWidget);
      expect(
        find.text('200\nCheck pickup', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('200\nTrack', findRichText: true), findsOneWidget);
      for (final group in ['new', 'packing', 'ready', 'delivery']) {
        final control = find.byKey(Key('work-store-workload-$group'));
        expect(tester.getSize(control).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(control).height, greaterThanOrEqualTo(48));
      }
      expect(work.currentWorkspaceOrderId, 'APP-1043');
      expect(work.workspaceOrderStage, 'Confirmed');
      await captureStoreView(tester, 'workload-1000-dashboard-$scale');
      await tester.tap(find.byKey(const Key('work-store-orders')));
      await tester.pumpAndSettle();
      Finder queue() => find.descendant(
        of: find.byKey(const Key('work-orders-destination')),
        matching: find.byType(ListView),
      );
      final list = tester.widget<ListView>(queue());
      expect(list.childrenDelegate, isA<SliverChildBuilderDelegate>());
      expect(
        (list.childrenDelegate as SliverChildBuilderDelegate).childCount,
        801,
      );
      expect(
        find.byKey(const Key('work-live-order-ticket')).evaluate().length,
        lessThan(20),
      );
      expect(find.text('All 801'), findsOneWidget);
      expect(find.text('New 201'), findsOneWidget);
      expect(find.text('Packing 200'), findsOneWidget);
      expect(find.text('Ready 200'), findsOneWidget);
      expect(find.text('Delivery 200'), findsOneWidget);
      expect(find.text('History 201'), findsOneWidget);
      await captureStoreView(tester, 'queue-1000-first-$scale');
      await tester.drag(queue(), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(work.currentWorkspaceOrderId, 'APP-1043');
      expect(
        find.byKey(const Key('work-live-order-ticket')).evaluate().length,
        lessThan(20),
      );
      final packing = find.byKey(const Key('work-orders-filter-packing'));
      await tester.ensureVisible(packing);
      await tester.tap(packing);
      await tester.pumpAndSettle();
      expect(
        (tester.widget<ListView>(queue()).childrenDelegate
                as SliverChildBuilderDelegate)
            .childCount,
        200,
      );
      expect(find.byKey(const Key('work-order-open-QUEUE-0001')), findsNothing);
      expect(work.currentWorkspaceOrderId, 'APP-1043');
      expect(work.workspaceOrderStage, 'Confirmed');
      await tester.drag(queue(), const Offset(0, 2000));
      await tester.pumpAndSettle();
      await captureStoreView(tester, 'queue-1000-selected-$scale');
      final pack = find.byKey(
        const Key('work-order-pack-QUEUE-0001-oil-fortune-1l'),
      );
      await tester.ensureVisible(pack);
      await tester.pumpAndSettle();
      expect(tester.widget<CheckboxListTile>(pack).value, isFalse);
      final label = find.descendant(
        of: pack,
        matching: find.text('Fortune Sunflower Oil × 1'),
      );
      expect(label, findsOneWidget);
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: label, matching: find.byType(RichText)),
      );
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(
        tester.getRect(label).width,
        lessThanOrEqualTo(tester.getRect(pack).width),
      );
      expect(
        tester.getRect(label).bottom,
        lessThanOrEqualTo(tester.getRect(pack).bottom),
      );
      await tester.tap(pack);
      await tester.pumpAndSettle();
      final packedOrder = work.workspaceOrders.singleWhere(
        (order) => order.id == 'QUEUE-0001',
      );
      expect(
        work.workspacePackingLinesForOrder(packedOrder).single.packed,
        isTrue,
      );
      expect(work.workspacePackedProductIds, isEmpty);
      expect(work.currentWorkspaceOrderId, 'APP-1043');
      expect(work.workspaceOrderStage, 'Confirmed');
      expect(work.workspaceInvoices, isEmpty);
      await captureStoreView(tester, 'queue-1000-packing-action-$scale');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final entry in [
    ('New', 'Confirmed'),
    ('Packing', 'Preparing'),
    ('Ready', 'Ready'),
    ('Delivery', 'Delivery requested'),
    ('Attention', 'Awaiting reconciliation'),
  ]) {
    testWidgets('Store workload ${entry.$1} opens its exact queue in one tap', (
      tester,
    ) async {
      final work = storeViewFixture();
      for (final stage in [
        'Confirmed',
        'Preparing',
        'Ready',
        'Delivery requested',
        'Awaiting reconciliation',
      ]) {
        work.workspaceOrders.add(
          customerOrder(
            id: 'WORKLOAD-$stage',
            customer: 'Test customer',
            stage: stage,
            createdAt: DateTime(2026, 9, 9, 9),
          ),
        );
      }
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        textScale: 1,
      );
      final originalStages = {
        for (final order in work.workspaceOrders) order.id: order.stage,
      };
      await tester.tap(
        find.byKey(Key('work-store-workload-${entry.$1.toLowerCase()}')),
      );
      await tester.pumpAndSettle();
      expect(work.workspaceOrderFilter, entry.$1);
      final queue = tester.widget<ListView>(
        find.descendant(
          of: find.byKey(const Key('work-orders-destination')),
          matching: find.byType(ListView),
        ),
      );
      expect(
        (queue.childrenDelegate as SliverChildBuilderDelegate).childCount,
        entry.$1 == 'New' ? 2 : 1,
      );
      expect(
        find.byKey(Key('work-order-stage-label-WORKLOAD-${entry.$2}')),
        findsOneWidget,
      );
      expect(work.currentWorkspaceOrderId, 'APP-1043');
      await captureStoreView(tester, 'workload-first-tap-${entry.$1}');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-store-workload')), findsOneWidget);
      expect(work.currentWorkspaceOrderId, 'APP-1043');
      expect(work.workspaceInvoices, isEmpty);
      expect({
        for (final order in work.workspaceOrders) order.id: order.stage,
      }, originalStages);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  test(
    'Store workload packing is scoped and stale contents need rechecking',
    () {
      final work = storeViewFixture();
      addTearDown(work.dispose);
      var order = customerOrder(
        id: 'PACK-SCOPED',
        customer: 'Test customer',
        stage: 'Preparing',
        createdAt: DateTime(2026, 9, 9, 9),
      );
      work.workspaceOrders.add(order);
      final storeId = work.activeWorkspace?.id ?? work.workspaceId;
      bool pack(int quantity, {String? scope}) =>
          work.setWorkspaceOrderPackingLine(
            storeId: scope ?? storeId,
            orderId: order.id,
            lineId: 'oil-fortune-1l',
            quantity: quantity,
            packed: true,
          );
      expect(pack(1, scope: 'ANOTHER-STORE'), isFalse);
      expect(pack(2), isFalse);
      expect(pack(1), isTrue);
      expect(work.workspacePackingLinesForOrder(order).single.packed, isTrue);
      final index = work.workspaceOrders.indexWhere(
        (item) => item.id == order.id,
      );
      order = order.copyWith(quantities: const {'oil-fortune-1l': 2});
      work.workspaceOrders[index] = order;
      expect(work.workspacePackingLinesForOrder(order).single.packed, isFalse);
      expect(pack(1), isFalse);
      expect(pack(2), isTrue);
      expect(work.workspacePackingLinesForOrder(order).single.packed, isTrue);
      work.workspaceOrders[index] = order.copyWith(stage: 'Cancelled');
      expect(pack(2), isFalse);
      expect(work.currentWorkspaceOrderId, 'APP-1043');
      expect(work.workspaceOrderStage, 'Confirmed');
      expect(work.workspacePackedProductIds, isEmpty);
      expect(work.workspaceInvoices, isEmpty);
    },
  );

  testWidgets('Store workload packing advances only the checked order', (
    tester,
  ) async {
    final work = storeViewFixture();
    work.workspaceOrders.add(
      customerOrder(
        id: 'PACK-DIRECT',
        customer: 'Test customer',
        stage: 'Preparing',
        createdAt: DateTime(2026, 9, 9, 9),
      ),
    );
    await mount(
      tester,
      route: '/app/work/workspace/dashboard',
      work: work,
      textScale: 1,
    );
    await tester.tap(find.byKey(const Key('work-store-workload-packing')));
    await tester.pumpAndSettle();
    final ready = find.byKey(const Key('work-order-ready-PACK-DIRECT'));
    expect(tester.widget<FilledButton>(ready).onPressed, isNull);
    final pack = find.byKey(
      const Key('work-order-pack-PACK-DIRECT-oil-fortune-1l'),
    );
    await tester.tap(pack);
    await tester.pumpAndSettle();
    expect(work.currentWorkspaceOrderId, 'APP-1043');
    final oldReady = tester.widget<FilledButton>(ready).onPressed!;
    final index = work.workspaceOrders.indexWhere(
      (item) => item.id == 'PACK-DIRECT',
    );
    work.workspaceOrders[index] = work.workspaceOrders[index].copyWith(
      quantities: const {'oil-fortune-1l': 2},
    );
    oldReady();
    expect(work.workspaceOrders[index].stage, 'Preparing');
    expect(work.currentWorkspaceOrderId, 'APP-1043');
    work.dismissMessages();
    await tester.pumpAndSettle();
    expect(tester.widget<CheckboxListTile>(pack).value, isFalse);
    expect(tester.widget<FilledButton>(ready).onPressed, isNull);
    await tester.tap(pack);
    await tester.pumpAndSettle();
    await tester.tap(ready);
    await tester.pumpAndSettle();
    expect(work.workspaceOrders[index].stage, 'Ready for pickup');
    expect(
      work.workspaceOrders.singleWhere((item) => item.id == 'APP-1043').stage,
      'Confirmed',
    );
    expect(work.workspaceInvoices, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Store workload arrivals preserve packing and reduced motion', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final work = storeViewFixture();
    final currentIndex = work.workspaceOrders.indexWhere(
      (order) => order.id == work.currentWorkspaceOrderId,
    );
    work.workspaceOrders[currentIndex] = work.workspaceOrders[currentIndex]
        .copyWith(stage: 'Preparing');
    work.workspaceOrderStage = 'Preparing';
    work.workspacePackedProductIds.add('oil-fortune-1l');
    await mount(
      tester,
      route: '/app/work/workspace/dashboard',
      work: work,
      textScale: 1,
    );
    expect(find.byKey(const Key('work-store-workload')), findsNothing);
    work.workspaceOrders.addAll(
      List.generate(
        1000,
        (index) => customerOrder(
          id: 'ARRIVAL-$index',
          customer: 'Test customer $index',
          stage: 'Confirmed',
          createdAt: DateTime(2026, 9, 9, 9),
        ),
      ),
    );
    work.dismissMessages();
    await tester.pumpAndSettle();
    expect(find.text('1000\nAccept', findRichText: true), findsOneWidget);
    expect(find.text('1\nPack', findRichText: true), findsOneWidget);
    expect(work.currentWorkspaceOrderId, 'APP-1043');
    expect(work.workspaceOrderStage, 'Preparing');
    expect(work.workspacePackedProductIds, contains('oil-fortune-1l'));
    final transitions = tester.widgetList<AnimatedSwitcher>(
      find.descendant(
        of: find.byKey(const Key('work-store-workload')),
        matching: find.byType(AnimatedSwitcher),
      ),
    );
    expect(transitions, hasLength(4));
    expect(transitions.every((item) => item.duration == Duration.zero), isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'Store workload keeps an unknown active state visible for review',
    (tester) async {
      final work = storeViewFixture();
      work.workspaceOrders
        ..clear()
        ..add(
          customerOrder(
            id: 'UNKNOWN-1',
            customer: 'Test customer',
            stage: 'Awaiting reconciliation',
            createdAt: DateTime(2026, 9, 9, 9),
          ),
        );
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: const Size(320, 640),
        textScale: 2,
      );
      expect(find.text('1\nReview', findRichText: true), findsOneWidget);
      final disabled = tester.widget<InkWell>(
        find.byKey(const Key('work-store-workload-new')),
      );
      expect(disabled.onTap, isNull);
      await captureStoreView(tester, 'workload-unknown-200');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Store queue keys survive arrivals without selecting another order',
    (tester) async {
      final work = storeViewFixture();
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        textScale: 1,
      );
      await tester.tap(find.byKey(const Key('work-store-orders')));
      await tester.pumpAndSettle();
      final originalRow = find
          .byKey(const Key('work-order-stage-label-APP-1043'))
          .evaluate()
          .single;
      final originalOrder = work.currentWorkspaceOrderId;
      work.workspaceOrders.insert(
        0,
        customerOrder(
          id: 'ARRIVAL-1',
          customer: 'New customer',
          stage: 'Confirmed',
          createdAt: DateTime(2026, 9, 7, 9),
        ),
      );
      work.dismissMessages();
      await tester.pumpAndSettle();
      expect(
        find
            .byKey(const Key('work-order-stage-label-APP-1043'))
            .evaluate()
            .single,
        same(originalRow),
      );
      expect(work.currentWorkspaceOrderId, originalOrder);
      expect(find.text('All 2'), findsOneWidget);
      expect(find.text('New 2'), findsOneWidget);
      expect(
        tester
            .widget<Text>(
              find.byKey(const Key('work-order-stage-label-ARRIVAL-1')),
            )
            .data,
        'Awaiting acceptance',
      );
      expect(
        tester
            .widget<Text>(
              find.byKey(const Key('work-order-stage-label-APP-1043')),
            )
            .data,
        'Accept within',
      );
      expect(work.workspaceOrderStage, 'Confirmed');
      expect(work.workspaceInvoices, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('Store queue retained packing tap cannot affect the next order', (
    tester,
  ) async {
    final work = storeViewFixture()..workspaceOrderStage = 'Preparing';
    work.workspaceOrders[0] = work.workspaceOrders.first.copyWith(
      stage: 'Preparing',
      quantities: const {'oil-fortune-1l': 1},
    );
    work.workspaceOrders.add(
      customerOrder(
        id: 'PACK-2',
        customer: 'Next customer',
        stage: 'Preparing',
        createdAt: DateTime(2026, 9, 7, 9),
      ),
    );
    await mount(
      tester,
      route: '/app/work/workspace/dashboard',
      work: work,
      textScale: 1,
    );
    await tester.tap(find.byKey(const Key('work-store-orders')));
    await tester.pumpAndSettle();
    final checkbox = find.byKey(const Key('work-order-pack-oil-fortune-1l'));
    final oldTap = tester.widget<CheckboxListTile>(checkbox).onChanged!;
    expect(work.selectWorkspaceOrder('PACK-2'), isTrue);
    oldTap(true);
    expect(work.workspacePackedProductIds, isEmpty);
    expect(work.workspaceOrderStage, 'Preparing');
    expect(work.selectWorkspaceOrder('APP-1043'), isTrue);
    expect(work.workspacePackedProductIds, isEmpty);
    await tester.pumpAndSettle();
    await tester.ensureVisible(checkbox);
    await tester.tap(checkbox);
    await tester.pumpAndSettle();
    expect(work.workspacePackedProductIds, contains('oil-fortune-1l'));
    expect(work.workspaceInvoices, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final action in [
    ('Confirmed', 'Reject'),
    ('Confirmed', 'Accept'),
    ('Ready for pickup', 'Confirm pickup'),
    ('Delivery requested', 'Track delivery'),
  ]) {
    testWidgets('Store queue stale ${action.$2} cannot act on another order', (
      tester,
    ) async {
      final work = storeViewFixture()..workspaceOrderStage = action.$1;
      work.workspaceOrders[0] = work.workspaceOrders.first.copyWith(
        stage: action.$1,
      );
      work.workspaceOrders.add(
        customerOrder(
          id: 'NEXT-ORDER',
          customer: 'Next customer',
          stage: action.$1,
          createdAt: DateTime(2026, 9, 7, 9),
        ),
      );
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        textScale: 1,
      );
      await tester.tap(find.byKey(const Key('work-store-orders')));
      await tester.pumpAndSettle();
      final button = find
          .ancestor(
            of: find.text(action.$2),
            matching: find.byWidgetPredicate(
              (widget) => widget is ButtonStyleButton,
            ),
          )
          .first;
      final oldTap = tester.widget<ButtonStyleButton>(button).onPressed!;
      expect(work.selectWorkspaceOrder('NEXT-ORDER'), isTrue);
      oldTap();
      await tester.pumpAndSettle();
      expect(work.currentWorkspaceOrderId, 'NEXT-ORDER');
      expect(work.workspaceOrderStage, action.$1);
      expect(find.byKey(const Key('work-orders-destination')), findsOneWidget);
      expect(find.byKey(const Key('work-reject-order-dialog')), findsNothing);
      expect(find.byKey(const Key('work-pickup-code')), findsNothing);
      expect(work.workspaceInvoices, isEmpty);
      expect(tester.takeException(), isNull);
      expect(work.selectWorkspaceOrder('APP-1043'), isTrue);
      work.workspaceOrders[0] = work.workspaceOrders.first.copyWith(
        stage: 'Completed',
      );
      work.workspaceOrderStage = 'Completed';
      oldTap();
      await tester.pumpAndSettle();
      expect(work.workspaceOrderStage, 'Completed');
      expect(find.byKey(const Key('work-reject-order-dialog')), findsNothing);
      expect(find.byKey(const Key('work-pickup-code')), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      work.workspaceOrders[0] = work.workspaceOrders.first.copyWith(
        stage: action.$1,
      );
      work.workspaceOrderStage = action.$1;
      oldTap();
      expect(work.workspaceOrderStage, action.$1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Store queue retained row selection cannot cross stores', (
    tester,
  ) async {
    final work = storeViewFixture();
    work.workspaceOrders.add(
      customerOrder(
        id: 'OPEN-LATER',
        customer: 'Next customer',
        stage: 'Confirmed',
        createdAt: DateTime(2026, 9, 7, 9),
      ),
    );
    await mount(
      tester,
      route: '/app/work/workspace/dashboard',
      work: work,
      textScale: 1,
    );
    await tester.tap(find.byKey(const Key('work-store-orders')));
    await tester.pumpAndSettle();
    final open = find.byKey(const Key('work-order-open-OPEN-LATER'));
    await tester.ensureVisible(open);
    final oldTap = tester.widget<TextButton>(open).onPressed!;
    final current = work.currentWorkspaceOrderId;
    final store = work.activeWorkspace!;
    work.activateWorkspace(
      WorkWorkspace(
        id: 'QUEUE-OTHER-STORE',
        name: 'Second store',
        profileLabel: store.profileLabel,
        profileId: store.profileId,
        area: store.area,
        verified: true,
      ),
    );
    oldTap();
    expect(work.currentWorkspaceOrderId, isNull);
    expect(work.activeWorkspace!.id, 'QUEUE-OTHER-STORE');
    expect(work.visibleWorkspaceOrders, isEmpty);
    expect(work.workspaceInvoices, isEmpty);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    work.activateWorkspace(store);
    expect(work.currentWorkspaceOrderId, current);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('Store scope native selector roundtrip $scale', (tester) async {
      final work = storeViewFixture();
      final first = work.activeWorkspace!;
      final previousOrder = work.currentWorkspaceOrderId;
      final previousBalance = work.workspaceSettlementBalance;
      work.otherWorkspaces.add(
        const WorkWorkspace(
          id: 'scope-second-store',
          name: 'Second Store',
          profileLabel: 'Speciality Retail Shop',
          profileId: 'retailer-speciality',
          area: 'Jaipur',
          verified: true,
        ),
      );
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: scale == 1 ? const Size(412, 915) : const Size(320, 640),
        textScale: scale,
      );
      final picker = find.byKey(const Key('work-dashboard-workspace-switcher'));
      await tester.tap(picker);
      await tester.pumpAndSettle();
      final second = find.byKey(
        const ValueKey('work-switch-scope-second-store'),
      );
      final selectorScroll = find.descendant(
        of: find.byKey(const Key('work-workspace-switcher-sheet')),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(second, 120, scrollable: selectorScroll);
      await tester.pumpAndSettle();
      expect(second.hitTestable(), findsOneWidget);
      await tester.tap(second);
      await tester.pumpAndSettle();
      expect(work.activeWorkspace?.id, 'scope-second-store');
      expect(work.workspaceSettlementBalance, 0);
      expect(work.visibleWorkspaceOrders, isEmpty);
      expect(work.workspaceCatalogueItems, isEmpty);
      expect(find.textContaining('Rakesh'), findsNothing);
      await captureStoreView(tester, 'store-b-empty-$scale');
      await tester.tap(find.byKey(const Key('work-store-orders')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-live-order-ticket')), findsNothing);
      await captureStoreView(tester, 'store-b-orders-empty-$scale');
      await tester.tap(picker);
      await tester.pumpAndSettle();
      final original = find.byKey(ValueKey('work-switch-${first.id}'));
      final originalTitle = find.descendant(
        of: original,
        matching: find.text(first.name),
      );
      await tester.scrollUntilVisible(
        originalTitle,
        80,
        scrollable: selectorScroll,
      );
      await tester.pumpAndSettle();
      await captureStoreView(tester, 'store-return-selector-$scale');
      expect(originalTitle.hitTestable(), findsOneWidget);
      await tester.tap(originalTitle);
      await tester.pumpAndSettle();
      expect(work.activeWorkspace?.id, first.id);
      expect(work.currentWorkspaceOrderId, previousOrder);
      expect(work.workspaceSettlementBalance, previousBalance);
      expect(work.visibleWorkspaceOrders, isNotEmpty);
      await captureStoreView(tester, 'store-a-restored-$scale');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final display in [
    (width: 412.0, height: 915.0, scale: 1.0),
    (width: 320.0, height: 640.0, scale: 1.4),
    (width: 320.0, height: 640.0, scale: 2.0),
  ]) {
    final suffix = '${display.width.toInt()}-${display.scale}';
    testWidgets('S09 remaining money customer history $suffix', (tester) async {
      final work = liveStore();
      work.workspaceOrders.add(
        customerOrder(
          id: 'CUSTOMER-RANGE',
          customer: 'Rakesh · 98290 12345',
          createdAt: DateTime.now(),
          amount: 10000000000,
          payment: 'Customer due',
        ),
      );
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: Size(display.width, display.height),
        textScale: display.scale,
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'Customer range dashboard entry',
      );
      final priorErrorHandler = FlutterError.onError!;
      final boundaryErrors = <String>[];
      FlutterError.onError = (details) {
        boundaryErrors.add(details.toString());
        priorErrorHandler(details);
      };
      try {
        await openStoreTools(tester);
      } finally {
        FlutterError.onError = priorErrorHandler;
      }
      expect(
        tester.takeException(),
        isNull,
        reason: 'Customer range operations entry: ${boundaryErrors.join('\n')}',
      );
      final customers = find.byKey(const Key('work-business-customers'));
      await reveal(tester, customers);
      await tester.tap(customers);
      await tester.pumpAndSettle();
      await captureStoreView(tester, 'r665-money-customer-book-$suffix');
      expect(tester.takeException(), isNull);
      expectExactMoneyVisible(tester, find.text('Customers'));
      final customer = find.byKey(const Key('work-customer-9829012345'));
      await reveal(tester, customer);
      expectExactMoneyVisible(
        tester,
        find.descendant(of: customer, matching: find.text('₹1,000 cr')),
      );
      await tester.tap(customer);
      await tester.pumpAndSettle();
      final order = find.byKey(const Key('work-customer-order-CUSTOMER-RANGE'));
      for (final label in [
        'Call',
        'Chat',
        'WhatsApp',
        'Repeat',
        'Invoice',
        'Offer locked',
      ]) {
        final actionLabel = find.text(label).last;
        await reveal(tester, actionLabel);
        expectExactMoneyVisible(tester, actionLabel);
      }
      final lockedOffer = find
          .ancestor(
            of: find.text('Offer locked'),
            matching: find.byType(InkWell),
          )
          .first;
      expect(tester.widget<InkWell>(lockedOffer).onTap, isNull);
      final actionGroup = find.byKey(const Key('work-customer-actions'));
      await tester.ensureVisible(actionGroup);
      await tester.pumpAndSettle();
      final sheetRect = tester.getRect(find.byType(BottomSheet));
      final actionRect = tester.getRect(actionGroup);
      expect(actionRect.top, greaterThanOrEqualTo(sheetRect.top));
      expect(actionRect.bottom, lessThanOrEqualTo(sheetRect.bottom));
      await captureStoreView(tester, 'r665-money-customer-actions-$suffix');
      await reveal(tester, order);
      final amount = find.descendant(
        of: order,
        matching: find.text('₹10,00,00,00,000'),
      );
      expectExactMoneyVisible(tester, amount);
      await captureStoreView(tester, 'r665-money-customer-history-$suffix');
      expect(tester.takeException(), isNull);
      expect(work.workspaceOrders.single.amount, 10000000000);
      expect(work.workspaceCustomerBook.single.amountDue, 10000000000);
      expect(work.workspaceSettlementRequested, 0);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-customers-destination')),
        findsOneWidget,
      );
      final period = find.byKey(const Key('work-customer-period'));
      await reveal(tester, period);
      await tester.tap(period);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Financial year').last);
      await tester.pumpAndSettle();
      expect(work.workspaceCustomerPeriod, 'Financial year');
      expect(tester.takeException(), isNull);
      await captureStoreView(tester, 'r665-money-customer-period-$suffix');
    });
    testWidgets('S09 remaining money paid customer context $suffix', (
      tester,
    ) async {
      final created = DateTime.now();
      final work = liveStore();
      work.workspaceOrders.add(
        customerOrder(
          id: 'CUSTOMER-PAID-RANGE',
          customer: 'Rakesh · 98290 12345',
          createdAt: created,
          amount: 10000000000,
          payment: 'Paid',
        ),
      );
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: Size(display.width, display.height),
        textScale: display.scale,
      );
      await openStoreTools(tester);
      final customers = find.byKey(const Key('work-business-customers'));
      await reveal(tester, customers);
      await tester.tap(customers);
      await tester.pumpAndSettle();
      final customer = find.byKey(const Key('work-customer-9829012345'));
      expectExactMoneyVisible(tester, find.text('Customers'));
      await reveal(tester, customer);
      expect(
        find.descendant(
          of: customer,
          matching: find.text('Last purchase ${created.day}/${created.month}'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: customer, matching: find.text('Payment due')),
        findsNothing,
      );
      expectExactMoneyVisible(
        tester,
        find.descendant(of: customer, matching: find.text('₹1,000 cr')),
      );
      work.markWorkspaceCustomerContacted('9829012345');
      await tester.pumpAndSettle();
      final contact = work.workspaceCustomerBook.single.lastContactAt!;
      expect(
        find.descendant(
          of: customer,
          matching: find.text('Contacted ${contact.day}/${contact.month}'),
        ),
        findsOneWidget,
      );
      expect(work.workspaceCustomerBook.single.amountDue, 0);
      expect(work.workspaceCustomerBook.single.totalSpend, 10000000000);
      expect(work.workspaceOrders.single.payment, 'Paid');
      expect(tester.takeException(), isNull);
      await captureStoreView(tester, 'r665-money-customer-paid-$suffix');
    });
  }

  testWidgets(
    'selected Workspace profile keeps contact clear of sticky Continue',
    (tester) async {
      final work = selectedRetailer();
      await mount(tester, route: '/app/work/workspace/contact', work: work);

      expect(find.byKey(const Key('workspace-account-setup-hero')), findsOne);
      expect(find.text('Google account'), findsOne);
      expect(find.byKey(const Key('work-global-chat')), findsNothing);
      expect(find.byKey(const Key('work-help')), findsNothing);
      expectHeaderAndStickyAction(tester, wrappedHeader: true);
      final alternate = find.byKey(const Key('work-alternate-contact-field'));
      await reveal(tester, alternate);
      expect(
        tester.getBottomRight(alternate).dy,
        lessThanOrEqualTo(
          tester
              .getTopRight(find.byKey(const Key('work-sticky-action-bar')))
              .dy,
        ),
      );
      expect(find.byKey(const Key('work-contact-continue')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'native OTP keyboard keeps confirmation reachable and disables autocorrection',
    (tester) async {
      final work = selectedRetailer()..contactEmail = 'qa@example.com';
      await mount(
        tester,
        route: '/app/work/workspace/contact',
        work: work,
        viewport: const Size(360, 806),
        textScale: 1,
        bottomInset: 44,
      );
      final send = find.byKey(const Key('work-contact-email-send-otp'));
      await reveal(tester, send);
      await tester.tap(send);
      await tester.pumpAndSettle();
      final otp = find.byKey(const Key('work-contact-email-otp'));
      expect(tester.widget<TextField>(otp).focusNode!.hasFocus, isTrue);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.enterText(otp, '123456');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-contact-continue')), findsNothing);
      expect(find.byKey(const Key('work-local-navigation')), findsNothing);
      final confirm = find.byKey(const Key('work-contact-email-confirm-otp'));
      await reveal(tester, confirm);
      expect(confirm.hitTestable(), findsOneWidget);
      expect(tester.getBottomRight(confirm).dy, lessThanOrEqualTo(506));
      for (final field in tester.widgetList<TextField>(
        find.byType(TextField),
      )) {
        expect(field.autocorrect, isFalse);
        expect(field.enableSuggestions, isFalse);
      }
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(work.contactEmailVerified, isTrue);
      expect(tester.takeException(), isNull);
      await captureStoreView(tester, '31-contact-confirm-native-keyboard');
    },
  );

  testWidgets(
    'restored document returns directly to Documents not the business form',
    (tester) async {
      final work = selectedRetailer()
        ..recoveredDocumentStep = true
        ..workName = 'Review Kirana';
      await mount(tester, route: '/app/work/workspace/proof', work: work);
      expect(
        find.byKey(const Key('work-add-proof-shop-front')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('work-details-continue')), findsNothing);
      expect(work.workName, 'Review Kirana');
      expect(work.recoveredDocumentStep, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [412.0, 320.0]) {
    for (final entry in [
      ('work-primary-contact', '123', 'Enter a valid 10-digit phone number.'),
      (
        'work-primary-contact',
        '1111111111',
        'Enter a valid 10-digit phone number.',
      ),
      ('work-contact-email', 'not-an-email', 'Enter a valid email address.'),
      (
        'work-alternate-contact',
        '123',
        'Enter a valid 10-digit alternate mobile number.',
      ),
      (
        'work-alternate-contact',
        '1213131313',
        'Enter a valid 10-digit alternate mobile number.',
      ),
    ]) {
      testWidgets(
        'r6611 contact format correction stays visible ${entry.$1} ${entry.$2} $width',
        (tester) async {
          final work = selectedRetailer()
            ..hydrateAccountSnapshot(
              const WorkAccountSnapshot(
                displayName: 'Asha Sharma',
                email: 'asha@example.com',
                mobile: '+91 98290 12321',
                providerLabel: 'Google',
                providerAccount: 'asha@example.com',
                emailConfirmed: true,
                mobileConfirmed: true,
              ),
            );
          final height = width == 412 ? 915.0 : 568.0;
          await mount(
            tester,
            route: '/app/work/workspace/contact',
            work: work,
            viewport: Size(width, height),
            textScale: width == 412 ? 1 : 2,
          );
          expect(work.workspaceContactsReady, isTrue);
          if (entry.$1 != 'work-alternate-contact') {
            final change = find.byKey(Key('${entry.$1}-change'));
            await reveal(tester, change);
            await tester.tap(change);
            await tester.pumpAndSettle();
          }
          final field = find.byKey(Key('${entry.$1}-field'));
          await reveal(tester, field);
          await tester.enterText(field, entry.$2);
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
          final next = find.byKey(const Key('work-contact-continue'));
          await reveal(tester, next);
          await tester.tap(next);
          await tester.pumpAndSettle();
          expect(work.errorMessage, entry.$3);
          expect(find.text(entry.$3), findsOneWidget);
          expect(find.byKey(const Key('work-contact-screen')), findsOneWidget);
          tester.view.viewInsets = FakeViewPadding(
            bottom: width == 412 ? 330 : 244,
          );
          await tester.pumpAndSettle();
          expect(field.hitTestable(), findsOneWidget);
          expect(find.byKey(const Key('work-error')), findsOneWidget);
          final errorBounds = tester.getRect(find.text(entry.$3));
          expect(errorBounds.top, greaterThanOrEqualTo(0));
          expect(
            errorBounds.bottom,
            lessThanOrEqualTo(height - (width == 412 ? 330 : 244)),
          );
          expect(tester.takeException(), isNull);
          await captureStoreView(
            tester,
            'r6611-${entry.$1}-${entry.$2}-format-${width.toInt()}',
          );
          tester.view.viewInsets = const FakeViewPadding();
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
          if (entry.$1 == 'work-alternate-contact') {
            await reveal(tester, field);
            await tester.enterText(field, '');
            FocusManager.instance.primaryFocus?.unfocus();
          } else {
            final cancel = find.byKey(Key('${entry.$1}-cancel'));
            await reveal(tester, cancel);
            await tester.tap(cancel);
          }
          await tester.pumpAndSettle();
          expect(work.errorMessage, isNull);
          expect(work.workspaceContactsReady, isTrue);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final width in [360.0, 320.0]) {
    for (final contact in [
      'work-primary-contact',
      'work-contact-email',
      'work-alternate-contact',
    ]) {
      testWidgets('incorrect $contact code retains retry above IME at $width', (
        tester,
      ) async {
        final work = selectedRetailer()
          ..primaryMobile = '9999999901'
          ..contactEmail = 'review.owner@example.com'
          ..alternateMobile = '9999999902';
        final height = width == 360 ? 806.0 : 568.0;
        final inset = width == 360 ? 330.0 : 244.0;
        await mount(
          tester,
          route: '/app/work/workspace/contact',
          work: work,
          viewport: Size(width, height),
          textScale: width == 360 ? 1 : 1.4,
        );
        final send = find.byKey(Key('$contact-send-otp'));
        await reveal(tester, send);
        await tester.tap(send);
        await tester.pumpAndSettle();
        tester.view.viewInsets = FakeViewPadding(bottom: inset);
        final otp = find.byKey(Key('$contact-otp'));
        await tester.enterText(otp, '00');
        await tester.pumpAndSettle();
        final confirm = find.byKey(Key('$contact-confirm-otp'));
        await reveal(tester, confirm);
        await tester.tap(confirm);
        await tester.pumpAndSettle();
        expect(work.errorMessage, 'Enter all 6 digits of the code.');
        expect(confirm.hitTestable(), findsOneWidget);
        expect(
          tester.getBottomRight(confirm).dy,
          lessThanOrEqualTo(height - inset),
        );
        await tester.enterText(otp, '000000');
        await tester.pumpAndSettle();
        await tester.tap(confirm);
        await tester.pumpAndSettle();
        // No test-side scrolling after the error: the screen must expose retry.
        expect(work.errorMessage, 'That code does not match. Try again.');
        expect(find.byKey(const Key('work-error')), findsOneWidget);
        expect(confirm.hitTestable(), findsOneWidget);
        expect(tester.getSize(confirm).height, greaterThanOrEqualTo(48));
        expect(
          tester.getBottomRight(confirm).dy,
          lessThanOrEqualTo(height - inset),
        );
        expect(tester.widget<TextField>(otp).focusNode!.hasFocus, isTrue);
        expect(find.byKey(const Key('work-contact-continue')), findsNothing);
        expect(find.byKey(const Key('work-local-navigation')), findsNothing);
        await captureStoreView(tester, '35-$contact-error-${width.toInt()}');
        await tester.enterText(otp, '123456');
        await tester.pumpAndSettle();
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(work.errorMessage, isNull);
        expect(
          contact == 'work-primary-contact'
              ? work.primaryMobileVerified
              : contact == 'work-contact-email'
              ? work.contactEmailVerified
              : work.alternateVerified,
          isTrue,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'missing recovered photo has persistent document-specific guidance',
    (tester) async {
      final work = selectedRetailer()
        ..recoveredDocumentStep = true
        ..workName = 'Review Kirana'
        ..documentRecoveryMessage =
            'Your details are saved. Please add Account owner identity again.';
      await mount(tester, route: '/app/work/workspace/proof', work: work);
      await tester.pump(const Duration(seconds: 3));
      final guidance = find.byKey(const Key('work-document-recovery-guidance'));
      expect(guidance, findsOneWidget);
      expect(
        tester.widget<Text>(guidance).data,
        contains('Account owner identity'),
      );
      expect(work.addedProofs, isEmpty);
      expect(
        find.byKey(const Key('work-add-proof-personal-kyc')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('work-notice')), findsNothing);
      await captureStoreView(tester, '36-recovered-photo-retry');
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [360.0, 320.0]) {
    testWidgets(
      'review gives long unbroken contact values full width at $width',
      (tester) async {
        final work = selectedRetailer()
          ..recoveredDocumentStep = true
          ..primaryMobile = '9999999901'
          ..primaryMobileVerified = true
          ..contactEmail = 'review.owner@example.com'
          ..contactEmailVerified = true
          ..workName = 'Review Kirana'
          ..authorizedPersonName = 'Review Owner'
          ..businessRelationship = 'Owner'
          ..workArea = 'Jodhpur'
          ..primaryActivity = 'Grocery retail';
        await mount(
          tester,
          route: '/app/work/workspace/proof',
          work: work,
          viewport: Size(width, 806),
          textScale: width == 360 ? 1 : 1.4,
        );
        await tester.tap(find.text('Review your information'));
        await tester.pumpAndSettle();
        final email = find.byKey(const Key('work-review-value-Email'));
        await reveal(tester, email);
        final displayed = tester.widget<Text>(email);
        expect(
          displayed.data!.replaceAll('\u200b', ''),
          'review.owner@example.com',
        );
        expect(displayed.semanticsLabel, 'review.owner@example.com');
        expect(work.contactEmail, 'review.owner@example.com');
        final paragraph = tester.renderObject<RenderParagraph>(
          find.descendant(of: email, matching: find.byType(RichText)),
        );
        final domainBoxes = paragraph.getBoxesForSelection(
          TextSelection(
            baseOffset: displayed.data!.indexOf('@'),
            extentOffset: displayed.data!.length,
          ),
        );
        expect(
          domainBoxes,
          hasLength(1),
          reason: 'Keep the domain on one readable line',
        );
        expect(
          tester.widget<Text>(email).overflow,
          isNot(TextOverflow.ellipsis),
        );
        expect(tester.getSize(email).width, greaterThan(width * .7));
        expect(tester.getRect(email).right, lessThanOrEqualTo(width - 16));
        await captureStoreView(
          tester,
          '37-review-long-contact-${width.toInt()}',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Store edge and finance expose operable semantic buttons', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await mount(
      tester,
      route: '/app/work/workspace/dashboard',
      work: liveStore(),
    );
    for (final key in [
      'work-quick-buy',
      'work-incoming-purchases',
      'work-quick-group-buy',
      'work-pulse-sales',
      'work-pulse-settlement',
    ]) {
      final finder = find.byKey(Key(key));
      expect(finder.hitTestable(), findsOneWidget);
      expect(
        tester
            .getSemantics(finder)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
    }
    handle.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'compact retailer setup uses actual catalogue and Store return sections',
    (tester) async {
      final work = liveStore()..retailerSetupSaved = false;
      await mount(
        tester,
        route: '/app/work/retailer/setup',
        work: work,
        viewport: const Size(360, 806),
        textScale: 1,
      );
      expect(find.byKey(const Key('work-global-chat')), findsNothing);
      expect(find.byKey(const Key('work-help')), findsNothing);
      expect(find.text('Earn Today'), findsNothing);
      expect(
        find.text(work.workspaceCatalogueItems.first.title),
        findsOneWidget,
      );
      await captureStoreView(tester, '32-compact-retailer-setup');
      await tester.tap(find.byKey(const Key('retailer-add-catalog-product')));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('retailer-product-quantity')));
      await tester.enterText(
        find.byKey(const Key('retailer-product-quantity')),
        '5',
      );
      await reveal(tester, find.byKey(const Key('retailer-product-buy-price')));
      await tester.enterText(
        find.byKey(const Key('retailer-product-buy-price')),
        '40',
      );
      await tester.enterText(
        find.byKey(const Key('retailer-product-sell-price')),
        '55',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      final collection = find.byKey(const Key('retailer-store-collection'));
      await reveal(tester, collection);
      await tester.tap(collection);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('retailer-finish-setup')));
      await tester.pumpAndSettle();
      expect(work.retailerSetupSaved, isTrue);
      expect(find.byKey(const Key('work-workspace-dashboard')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('contact OTP action stays on one line on a narrow device', (
    tester,
  ) async {
    final work = selectedRetailer()
      ..primaryMobile = '9876501234'
      ..primaryMobileVerified = false
      ..primaryMobileOtpSent = true;
    await mount(tester, route: '/app/work/workspace/contact', work: work);

    final confirm = find.descendant(
      of: find.byKey(const Key('work-primary-contact-confirm-otp')),
      matching: find.text('Confirm'),
    );
    await reveal(tester, confirm);
    final label = tester.widget<Text>(confirm);
    expect(label.maxLines, 1);
    expect(label.softWrap, isFalse);
    expect(find.text('Contact number code'), findsOneWidget);
    final code = tester.widget<TextField>(
      find.byKey(const Key('work-primary-contact-otp')),
    );
    expect(code.maxLength, 6);
    expect(code.decoration?.helperText, 'Sent to 9876501234');
    expect(tester.takeException(), isNull);
  });

  for (final display in [
    (size: const Size(360, 806), scale: 1.0, keyboard: 328.0, bottom: 42.0),
    (size: const Size(360, 800), scale: 1.4, keyboard: 300.0, bottom: 0.0),
    (size: const Size(320, 568), scale: 2.0, keyboard: 228.0, bottom: 0.0),
  ]) {
    testWidgets(
      'Workspace request sheet clears Android and keyboard insets without losing input ${display.size.width} ${display.scale}',
      (tester) async {
        final previousHitTestPolicy =
            WidgetController.hitTestWarningShouldBeFatal;
        WidgetController.hitTestWarningShouldBeFatal = true;
        addTearDown(
          () => WidgetController.hitTestWarningShouldBeFatal =
              previousHitTestPolicy,
        );
        final work = WorkSession();
        final safeBottom = (display.bottom > 24 ? display.bottom : 24) + 8;
        await mount(
          tester,
          route: '/app/work/workspace/choose',
          work: work,
          bottomInset: display.bottom,
          viewport: display.size,
          textScale: display.scale,
        );
        tester.view.viewPadding = FakeViewPadding(
          top: 41,
          bottom: display.bottom,
        );
        tester.view.padding = FakeViewPadding(top: 41, bottom: display.bottom);
        await tester.pumpAndSettle();

        final request = find.byKey(const Key('work-profile-not-shown'));
        await tester.scrollUntilVisible(
          request,
          300,
          scrollable: find
              .descendant(
                of: find.byKey(const Key('work-choose-screen')),
                matching: find.byType(Scrollable),
              )
              .first,
          maxScrolls: 60,
        );
        await tester.pumpAndSettle();
        await tester.tap(request);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('work-profile-request-sheet')),
          findsOneWidget,
        );
        final actions = find.byKey(const Key('work-profile-request-actions'));
        expect(
          tester.getBottomRight(actions).dy,
          lessThanOrEqualTo(display.size.height - safeBottom),
        );
        final area = find.byKey(const Key('work-request-area'));
        await reveal(tester, area);
        expect(area, findsOneWidget);
        expect(
          tester.getTopLeft(actions).dy - tester.getBottomLeft(area).dy,
          lessThanOrEqualTo(48),
        );

        final name = find.byKey(const Key('work-request-profile-name'));
        await tester.scrollUntilVisible(
          name,
          -120,
          scrollable: find
              .descendant(
                of: find.byKey(const Key('work-profile-request-scroll')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        await reveal(tester, name);
        await tester.tap(name);
        await tester.enterText(name, 'Furniture repair');
        tester.view.viewInsets = FakeViewPadding(bottom: display.keyboard);
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('work-send-profile-request')));
        await tester.pumpAndSettle();
        expect(
          tester.getTopLeft(find.text('Tell us what you do')).dy,
          greaterThanOrEqualTo(41),
        );
        await captureStoreView(
          tester,
          'r666-request-error-${display.size.width}-${display.scale}',
        );
        await tester.scrollUntilVisible(
          name,
          48,
          maxScrolls: 40,
          scrollable: find
              .descendant(
                of: find.byKey(const Key('work-profile-request-scroll')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        await tester.tap(name);
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(name).focusNode!.hasFocus, isTrue);
        expect(
          tester
              .getSize(find.byKey(const Key('work-profile-request-scroll')))
              .height,
          greaterThanOrEqualTo(48),
        );
        expect(
          tester
              .getTopLeft(find.byKey(const Key('work-profile-request-close')))
              .dy,
          greaterThanOrEqualTo(41),
          reason: 'Close must remain below the real Android status inset.',
        );

        expect(
          tester.widget<TextField>(name).controller?.text,
          'Furniture repair',
        );
        expect(
          tester.getBottomRight(actions).dy,
          lessThanOrEqualTo(
            display.size.height - display.keyboard - safeBottom,
          ),
        );
        final send = find.byKey(const Key('work-send-profile-request'));
        final back = find.byKey(const Key('work-profile-request-back'));
        expect(send, findsOneWidget);
        expect(back, findsOneWidget);
        expect(
          tester.getBottomRight(send).dy,
          lessThanOrEqualTo(
            display.size.height - display.keyboard - safeBottom - 32,
          ),
        );
        expect(
          tester.getBottomRight(back).dy,
          lessThanOrEqualTo(
            display.size.height - display.keyboard - safeBottom - 32,
          ),
        );
        await captureStoreView(
          tester,
          'r666-request-ime-${display.size.width}-${display.scale}',
        );
        expect(tester.takeException(), isNull);

        await tester.tap(find.byKey(const Key('work-profile-request-back')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-profile-request-sheet')),
          findsNothing,
        );
      },
    );
  }

  testWidgets(
    'proof source and review declaration clear system and sticky actions',
    (tester) async {
      final work = selectedRetailer()
        ..saveDetails(
          name: 'Mahadev Fresh Mart',
          area: 'Sardarpura, Jodhpur',
          activity: 'Grocery and household products',
        )
        ..continueToProof();
      await mount(tester, route: '/app/work/workspace/proof', work: work);
      expect(find.byKey(const Key('work-global-chat')), findsNothing);
      expect(find.byKey(const Key('work-help')), findsNothing);
      await tester.tap(find.byKey(const Key('work-details-continue')));
      await tester.pumpAndSettle();
      final addProof = find.byKey(const Key('work-add-proof-shop-front'));
      await reveal(tester, addProof);
      await tester.tap(addProof);
      await tester.pumpAndSettle();
      for (final key in const [
        'work-proof-source-camera',
        'work-proof-source-gallery',
        'work-proof-source-upload',
        'work-proof-source-cloud',
      ]) {
        expect(find.byKey(Key(key)), findsOneWidget);
        expect(tester.getSize(find.byKey(Key(key))).width, lessThan(90));
      }
      final cancel = find.byKey(const Key('work-proof-source-cancel'));
      expect(tester.getBottomRight(cancel).dy, lessThanOrEqualTo(756));
      await tester.tap(cancel);
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        await work.addProof('shop-front', WorkProofSource.upload);
        await work.addProof('owner-authority', WorkProofSource.upload);
        await work.addProof('payout-bank-account', WorkProofSource.upload);
      });
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('work-proof-review')));
      await tester.pumpAndSettle();
      for (final key in const [
        'work-review-edit-details',
        'work-review-edit-documents',
      ]) {
        final label = find.descendant(
          of: find.byKey(Key(key)),
          matching: find.text('Edit'),
        );
        final text = tester.widget<Text>(label);
        expect(text.overflow, isNot(TextOverflow.ellipsis));
        expect(tester.getSize(label).height, lessThanOrEqualTo(40));
      }
      final declaration = find.byKey(const Key('work-declaration'));
      await reveal(tester, declaration);
      expect(
        tester.getBottomRight(declaration).dy,
        lessThanOrEqualTo(
          tester
              .getTopRight(find.byKey(const Key('work-sticky-action-bar')))
              .dy,
        ),
      );
      expect(find.byKey(const Key('work-submit-profile')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'pending application fits without unsolicited update or document actions',
    (tester) async {
      final work = selectedRetailer()
        ..reviewStage = WorkReviewStage.gstPending
        ..reviewCaseId = 'WORK-REVIEW-204';
      (work.gateway as ReviewWorkGateway).reviewResultStatus =
          WorkRemoteReviewStatus.pending;
      await mount(tester, route: '/app/work/status', work: work);
      final action = find.text('Application received');
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      expect(
        tester.getBottomRight(action).dy,
        lessThanOrEqualTo(
          tester.view.physicalSize.height / tester.view.devicePixelRatio,
        ),
      );
      expect(find.byKey(const Key('work-inline-review-check')), findsNothing);
      expect(
        find.byKey(const Key('work-inline-update-documents')),
        findsNothing,
      );
      expect(work.activeWorkspace, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ready and shop setup content remain scrollable above stable action',
    (tester) async {
      final work = WorkSession()..seedVerifiedWorkspace();
      work.beginRetailerSetup();
      work.addRetailerProduct();
      await mount(tester, route: '/app/work/retailer/setup', work: work);
      expectHeaderAndStickyAction(tester);
      final visibilityCopy = find.text(
        'Your store stays off and private. Open it later from your business profile.',
      );
      await reveal(tester, visibilityCopy);
      expect(
        tester.getBottomRight(visibilityCopy).dy,
        lessThanOrEqualTo(
          tester
              .getTopRight(find.byKey(const Key('work-sticky-action-bar')))
              .dy,
        ),
      );
      expect(find.byKey(const Key('retailer-finish-setup')), findsOneWidget);
      expect(
        find.byKey(const Key('retailer-publish-after-setup')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('retailer-publish-after-setup')));
      await tester.pumpAndSettle();
      expect(work.retailerPublishAfterSetup, isTrue);
      expect(find.text('Finish setup'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  group('local Store 1-40 review evidence', skip: true, () {
    testWidgets('profile dashboard remains usable on compact large-text layout', (
      tester,
    ) async {
      final work = selectedRetailer()
        ..hydrateAccountSnapshot(
          const WorkAccountSnapshot(
            email: 'asha@example.com',
            mobile: '+91 98290 12321',
            providerLabel: 'Google',
            providerAccount: 'asha@example.com',
            emailConfirmed: true,
            mobileConfirmed: true,
          ),
        )
        ..saveDetails(
          name: 'Mahadev Fresh Mart',
          area: 'Sardarpura, Jodhpur',
          activity: 'Grocery retail',
        )
        ..reviewCaseId = 'WP-240701'
        ..workspaceId = 'WK-510001'
        ..reviewStage = WorkReviewStage.approved
        ..remoteReviewStatus = WorkRemoteReviewStatus.approved
        ..activeWorkspace = const WorkWorkspace(
          id: 'WK-510001',
          name: 'Mahadev Fresh Mart',
          profileLabel: 'Grocery / Kirana Shop',
          area: 'Sardarpura, Jodhpur',
          verified: true,
        )
        ..showNotice(
          'Work profile approved. Finish setup before customers can view your Workspace.',
        );
      await mount(tester, route: '/app/work/workspace/dashboard', work: work);

      expect(find.byKey(const Key('work-dashboard-hero')), findsNothing);
      expect(find.textContaining('Work profile approved'), findsNothing);
      expect(
        find.text('Mahadev Fresh Mart · Sardarpura, Jodhpur'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('work-dashboard-inline-header')), findsOne);
      expect(
        find.byKey(const Key('work-dashboard-workspace-switcher')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('work-page-title')), findsNothing);
      expect(
        find.byKey(const Key('work-dashboard-account-state')),
        findsNothing,
      );
      expect(
        find.bySemanticsLabel('Search orders, products, customers or invoices'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(RegExp('Store alerts')), findsOneWidget);
      expect(
        find.byKey(const Key('work-dashboard-command-centre')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('work-dashboard-store-state')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('work-dashboard-setup-panel')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('work-dashboard-live-metrics')),
        findsNothing,
      );
      expect(find.byKey(const Key('work-store-quick-actions')), findsNothing);
      expect(find.byKey(const Key('work-sticky-action-bar')), findsNothing);
      expect(find.byKey(const Key('work-local-navigation')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'retail dashboard exposes the four connected control surfaces',
      (tester) async {
        final work = WorkSession()..seedVerifiedWorkspace();
        await mount(tester, route: '/app/work/workspace/dashboard', work: work);

        expect(find.byKey(const Key('work-dashboard-hero')), findsNothing);
        for (final keyName in const [
          'work-dashboard-search',
          'work-dashboard-alerts',
          'work-dashboard-profile',
          'work-dashboard-workspace-switcher',
          'work-dashboard-command-centre',
          'work-dashboard-store-state',
          'work-dashboard-visibility',
          'work-dashboard-public-preview',
          'work-dashboard-setup-panel',
          'work-dashboard-priority-action',
        ]) {
          await reveal(tester, find.byKey(Key(keyName)));
          expect(find.byKey(Key(keyName)), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'approved store rail is contextual and opens actions directly',
      (tester) async {
        final work = WorkSession()
          ..seedVerifiedWorkspace()
          ..retailerSetupSaved = true
          ..reviewStage = WorkReviewStage.live
          ..workspaceStoreState = WorkspaceStoreState.open
          ..workspaceAcceptingOrders = true
          ..workspaceVisibleToCustomers = true;
        await mount(tester, route: '/app/work/workspace/dashboard', work: work);

        expect(find.byKey(const Key('work-local-earn')), findsNothing);
        expect(find.byKey(const Key('work-local-workspace')), findsNothing);
        final storeKeys = const [
          Key('work-store-home'),
          Key('work-store-orders'),
          Key('work-store-sell'),
          Key('work-store-stock'),
        ];
        for (final key in storeKeys) {
          expect(find.byKey(key), findsOneWidget);
        }
        final centers = storeKeys
            .map((key) => tester.getCenter(find.byKey(key)).dx)
            .toList();
        expect(centers[1] - centers[0], closeTo(60, 1));
        expect(centers[2] - centers[1], closeTo(60, 1));
        expect(centers[3] - centers[2], closeTo(60, 1));

        await tester.tap(find.byKey(const Key('work-store-orders')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('retailer-orders-screen')), findsOneWidget);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-store-today-canvas')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('work-store-context-rail')),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('work-store-sell')));
        await tester.pumpAndSettle();
        expect(find.text('Create order'), findsOneWidget);
        expect(
          find.text('Counter, phone or Chat · one live stock'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'retail dashboard Profile opens globally and returns in place',
      (tester) async {
        final work = WorkSession()..seedVerifiedWorkspace();
        await mount(tester, route: '/app/work/workspace/dashboard', work: work);

        await tester.tap(find.byKey(const Key('work-dashboard-profile')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('global-profile-panel-v2')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-workspace-dashboard')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('store search keeps text stable with keyboard and native Back', (
      tester,
    ) async {
      final work = WorkSession()..seedVerifiedWorkspace();
      await mount(tester, route: '/app/work/workspace/dashboard', work: work);

      await tester.tap(find.byKey(const Key('work-dashboard-search')));
      await tester.pumpAndSettle();
      final field = find.byKey(const Key('work-dashboard-search-field'));
      expect(field, findsOneWidget);
      await tester.enterText(field, 'fortune');
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();

      expect(work.workspaceSearchQuery, 'fortune');
      expect(
        find.byKey(const Key('work-search-product-oil-fortune-1l')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          Key(
            'work-search-order-${work.currentWorkspaceOrderId ?? 'current-store-order'}',
          ),
        ),
        findsNothing,
      );
      expect(
        tester.getBottomRight(field).dy,
        lessThanOrEqualTo(
          tester.getTopRight(find.byKey(const Key('work-local-navigation'))).dy,
        ),
      );
      expect(tester.takeException(), isNull);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-workspace-dashboard')), findsOneWidget);
      expect(work.workspaceSearchQuery, 'fortune');
    });

    testWidgets(
      'availability saves customer-facing state and Back discards draft',
      (tester) async {
        final work = WorkSession()
          ..seedVerifiedWorkspace()
          ..retailerSetupSaved = true
          ..reviewStage = WorkReviewStage.live
          ..workspaceStoreState = WorkspaceStoreState.open
          ..workspaceAcceptingOrders = true;
        await mount(tester, route: '/app/work/workspace/dashboard', work: work);

        await tester.tap(find.byKey(const Key('work-dashboard-status')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-dashboard-status-screen')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('work-status-accepting-orders')));
        await tester.pumpAndSettle();
        await reveal(tester, find.text('Tomorrow at 8:00 AM'));
        expect(find.text('Tomorrow at 8:00 AM'), findsOneWidget);
        await tester.tap(find.byKey(const Key('work-status-save')));
        await tester.pumpAndSettle();

        expect(work.workspaceAcceptingOrders, isFalse);
        expect(work.workspaceReopensAt, 'Tomorrow at 8:00 AM');
        expect(work.workspaceActivity.first.message, contains('paused'));

        await tester.tap(find.byKey(const Key('work-dashboard-status')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('work-status-accepting-orders')));
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(work.workspaceAcceptingOrders, isFalse);
        expect(
          find.byKey(const Key('work-workspace-dashboard')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('attention queue is truthful and returns to dashboard', (
      tester,
    ) async {
      final work = WorkSession()..seedVerifiedWorkspace();
      await mount(tester, route: '/app/work/workspace/dashboard', work: work);

      await tester.tap(find.byKey(const Key('work-dashboard-alerts')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-dashboard-alerts-screen')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('work-alert-store-setup')), findsOneWidget);
      expect(
        find.byKey(const Key('work-alert-contact-details')),
        findsOneWidget,
      );
      expect(find.text('No urgent store action'), findsNothing);

      await tester.tap(find.byKey(const Key('work-back')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-workspace-dashboard')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'daily actions use existing retailer owners and native Back restores Store',
      (tester) async {
        final work = WorkSession()
          ..seedVerifiedWorkspace()
          ..retailerSetupSaved = true
          ..reviewStage = WorkReviewStage.live
          ..workspaceStoreState = WorkspaceStoreState.open
          ..workspaceAcceptingOrders = true
          ..workspaceVisibleToCustomers = true;
        await mount(tester, route: '/app/work/workspace/dashboard', work: work);

        await tester.tap(find.byKey(const Key('work-store-orders')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('retailer-orders-screen')), findsOneWidget);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-store-today-canvas')),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('work-store-sell')));
        await tester.pumpAndSettle();
        expect(find.text('Create order'), findsOneWidget);
        expect(find.text('Counter'), findsWidgets);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-store-today-canvas')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Stock opens the authoritative retailer catalogue owner', (
      tester,
    ) async {
      final work = WorkSession()
        ..seedVerifiedWorkspace()
        ..retailerSetupSaved = true
        ..reviewStage = WorkReviewStage.live
        ..workspaceStoreState = WorkspaceStoreState.open
        ..workspaceAcceptingOrders = true;
      await mount(tester, route: '/app/work/workspace/dashboard', work: work);

      await tester.tap(find.byKey(const Key('work-store-stock')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('retailer-stock-preview-screen')),
        findsOneWidget,
      );
      expect(find.text('Available products'), findsOneWidget);
      expect(
        find.text('Consumer quantities and household prices only'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('store state and customer preview complete within two taps', (
      tester,
    ) async {
      final work = WorkSession()
        ..seedVerifiedWorkspace()
        ..reviewStage = WorkReviewStage.live
        ..retailerSetupSaved = true
        ..workspaceVisibleToCustomers = true
        ..workspaceStoreState = WorkspaceStoreState.open
        ..workspaceAcceptingOrders = true;
      await mount(tester, route: '/app/work/workspace/dashboard', work: work);

      await tester.tap(find.byKey(const Key('work-dashboard-store-state')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pause for 1 hour'));
      await tester.pumpAndSettle();
      expect(work.workspaceAcceptingOrders, isFalse);
      expect(work.workspaceReopensAt, 'In 1 hour');
      expect(find.text('Paused'), findsOneWidget);

      await tester.tap(find.byKey(const Key('work-dashboard-public-preview')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-dashboard-preview-screen')),
        findsOneWidget,
      );
      expect(find.text('Mahadev Fresh Mart'), findsOneWidget);
      expect(
        find.byKey(const Key('work-preview-product-oil-fortune-1l')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('work-preview-visibility')));
      await tester.pumpAndSettle();
      expect(work.workspaceVisibleToCustomers, isFalse);
      expect(work.workspaceStoreState, WorkspaceStoreState.paused);
      expect(find.text('PRIVATE PREVIEW'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('first-tap store actions open exact operational destinations', (
      tester,
    ) async {
      final work = WorkSession()
        ..seedVerifiedWorkspace()
        ..retailerSetupSaved = true
        ..reviewStage = WorkReviewStage.live
        ..workspaceStoreState = WorkspaceStoreState.open
        ..workspaceAcceptingOrders = true
        ..workspaceVisibleToCustomers = true;
      await mount(tester, route: '/app/work/workspace/dashboard', work: work);

      for (final keyName in const [
        'work-store-sell',
        'work-quick-store-link',
        'work-quick-buy',
        'work-quick-group-buy',
      ]) {
        expect(find.byKey(Key(keyName)), findsOneWidget);
      }

      await openExistingDeliveryDraft(tester);
      await tester.pumpAndSettle();
      expect(find.text('Create customer order'), findsOneWidget);
      expect(find.text('Phone'), findsWidgets);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-store-today-canvas')), findsOneWidget);

      await tester.tap(find.byKey(const Key('work-quick-buy')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-v2-screen')), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      if (find.byKey(const ValueKey('buy-v2-screen')).evaluate().isNotEmpty) {
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
      }
      expect(find.byKey(const Key('work-store-today-canvas')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('paid Group Buy pins to Today with complete decision facts', (
      tester,
    ) async {
      final work = WorkSession()
        ..seedVerifiedWorkspace()
        ..applyConfirmedWorkspaceGroupBuyPayment(
          productName: 'Premium onion',
          specification: 'Fresh red onion · Grade A · 45 mm+',
          targetQuantity: 1000,
          securedQuantity: 100,
          unitLabel: 'kg',
          regularUnitPrice: 18,
          groupUnitPrice: 14,
          facilitationFee: 200,
          deliveryFee: 0,
          confirmationAmount: 1400,
          paymentReference: 'PAY-REVIEW-001',
          closingLabel: '5 Sep · 8:00 PM',
          storeDeliveryLabel: '7 Sep · Door delivery',
        );
      await mount(tester, route: '/app/work/workspace/dashboard', work: work);

      expect(
        find.byKey(const Key('work-dashboard-active-group-buy')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const Key('work-dashboard-active-group-buy')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-group-buy-active-screen')),
        findsOneWidget,
      );
      expect(find.text('₹14/kg'), findsWidgets);
      expect(find.text('₹400'), findsOneWidget);
      await reveal(tester, find.text('Payment confirmed'));
      expect(find.text('Payment confirmed'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'first-use dashboard shows priorities without fake zero metrics',
      (tester) async {
        final work = WorkSession()..seedVerifiedWorkspace();
        await mount(tester, route: '/app/work/workspace/dashboard', work: work);

        expect(
          find.byKey(const Key('work-dashboard-setup-panel')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('work-dashboard-live-metrics')),
          findsNothing,
        );
        expect(find.byKey(const Key('work-store-quick-actions')), findsNothing);
        expect(find.text('No order waiting'), findsNothing);
        expect(find.text('No delivery waiting'), findsNothing);
        expect(find.text('₹0'), findsNothing);
        expect(
          find.widgetWithText(FilledButton, 'Continue store setup'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('public visibility remains separate from Open Paused and Off', (
      tester,
    ) async {
      final work = WorkSession()
        ..seedVerifiedWorkspace()
        ..retailerSetupSaved = true
        ..reviewStage = WorkReviewStage.live
        ..workspaceStoreState = WorkspaceStoreState.open
        ..workspaceAcceptingOrders = true
        ..workspaceVisibleToCustomers = true;
      await mount(tester, route: '/app/work/workspace/dashboard', work: work);

      await tester.tap(find.byKey(const Key('work-dashboard-store-state')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Turn ordering off'));
      await tester.pumpAndSettle();
      expect(work.workspaceStoreState, WorkspaceStoreState.off);
      expect(work.workspaceAcceptingOrders, isFalse);
      expect(work.workspaceVisibleToCustomers, isTrue);
      expect(find.text('Off'), findsOneWidget);
      expect(find.text('Public'), findsOneWidget);

      await tester.tap(find.byKey(const Key('work-dashboard-visibility')));
      await tester.pumpAndSettle();
      expect(work.workspaceVisibleToCustomers, isFalse);
      expect(work.workspaceStoreState, WorkspaceStoreState.off);
      expect(find.text('Private'), findsOneWidget);
    });

    testWidgets('Grow is customer growth and business support, not Wholesale', (
      tester,
    ) async {
      final work = WorkSession()
        ..seedVerifiedWorkspace()
        ..retailerSetupSaved = true
        ..reviewStage = WorkReviewStage.live;
      await mount(tester, route: '/app/work/workspace/dashboard', work: work);

      await tester.tap(find.text('Grow'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-grow-destination')), findsOneWidget);
      for (final copy in const [
        'Bring customers back',
        'Offers and repeat baskets',
        'Promote your store',
        'Publish paid work',
        'Business support',
      ]) {
        await reveal(tester, find.text(copy));
        expect(find.text(copy), findsOneWidget);
      }
      expect(find.text('Buy stock at wholesale'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Buy Together cannot be published by a self-declared payment', (
      tester,
    ) async {
      final work = WorkSession()
        ..seedVerifiedWorkspace()
        ..retailerSetupSaved = true
        ..reviewStage = WorkReviewStage.live;
      await mount(tester, route: '/app/work/workspace/dashboard', work: work);

      await tester.tap(find.byKey(const Key('work-quick-group-buy')));
      await tester.pumpAndSettle();
      expect(find.text('Start Buy Together'), findsOneWidget);
      expect(
        find.byKey(const Key('work-group-buy-payment-confirmed')),
        findsNothing,
      );
      expect(find.text('Confirm and publish Group Buy'), findsNothing);
      await reveal(
        tester,
        find.textContaining('payment service confirms your amount'),
      );
      expect(
        find.textContaining('payment service confirms your amount'),
        findsOneWidget,
      );
      expect(work.activeGroupBuy, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'saved offline activity exposes a truthful refresh transition',
      (tester) async {
        final work = WorkSession()
          ..seedVerifiedWorkspace()
          ..retailerSetupSaved = true
          ..reviewStage = WorkReviewStage.live
          ..workspaceDashboardState = WorkspaceDashboardState.offline
          ..workspaceLastUpdatedAt = DateTime(2026, 9, 2, 14, 15);
        await mount(tester, route: '/app/work/workspace/dashboard', work: work);

        expect(find.text('Showing saved store activity'), findsOneWidget);
        await tester.tap(find.byKey(const Key('work-dashboard-retry')));
        await tester.pump();
        expect(
          work.workspaceDashboardState,
          WorkspaceDashboardState.refreshing,
        );
        expect(find.text('Refreshing store activity'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'founder review capture - setup dashboard',
      skip: !captureFounderEvidence,
      (tester) async {
        final work = WorkSession()..seedVerifiedWorkspace();
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: const Size(412, 915),
          textScale: 1,
          bottomInset: 34,
        );
        await expectLater(
          find.byType(Scaffold).first,
          matchesGoldenFile(
            '../../../artifacts/quality/work-store-atomic-1-40-r62-47-local-review-20260903/work-dashboard-setup-412x915.png',
          ),
        );
      },
    );

    testWidgets(
      'founder review capture - live operations dashboard',
      skip: !captureFounderEvidence,
      (tester) async {
        final work = WorkSession()
          ..seedVerifiedWorkspace()
          ..retailerSetupSaved = true
          ..reviewStage = WorkReviewStage.live
          ..workspaceStoreState = WorkspaceStoreState.open
          ..workspaceAcceptingOrders = true
          ..workspaceVisibleToCustomers = true
          ..workspaceSalesToday = 28450
          ..workspaceSettlementBalance = 17820
          ..workspaceOrderCustomer = 'Rakesh · 98290 12345'
          ..workspaceOrderSource = 'App'
          ..workspaceOrderItems = 'Fortune Oil × 2 · Aashirvaad Atta × 1'
          ..workspaceOrderAmount = '1468'
          ..workspaceOrderStage = 'Confirmed'
          ..workspaceCatalogueItems[0] = workspaceMasterCatalogue.first
              .copyWith(stock: 3, available: true, publicListing: true)
          ..workspaceLastUpdatedAt = DateTime(2026, 9, 2, 7, 0)
          ..applyConfirmedWorkspaceGroupBuyPayment(
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
            paymentReference: 'PAY-REVIEW-001',
            closingLabel: '5 Sep · 8:00 PM',
            storeDeliveryLabel: '7 Sep · Door delivery',
          );
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: const Size(412, 915),
          textScale: 1,
          bottomInset: 34,
        );
        await expectLater(
          find.byType(Scaffold).first,
          matchesGoldenFile(
            '../../../artifacts/quality/work-store-atomic-1-40-r62-47-local-review-20260903/work-dashboard-live-412x915.png',
          ),
        );
      },
    );

    testWidgets(
      'founder review capture - saved offline dashboard',
      skip: !captureFounderEvidence,
      (tester) async {
        final work = WorkSession()
          ..seedVerifiedWorkspace()
          ..retailerSetupSaved = true
          ..reviewStage = WorkReviewStage.live
          ..workspaceStoreState = WorkspaceStoreState.paused
          ..workspaceAcceptingOrders = false
          ..workspaceVisibleToCustomers = true
          ..workspaceReopensAt = 'at 4:00 PM'
          ..workspaceSalesToday = 8620
          ..workspaceSettlementBalance = 4200
          ..workspaceLastUpdatedAt = DateTime(2026, 9, 2, 14, 15)
          ..workspaceDashboardState = WorkspaceDashboardState.offline;
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: const Size(412, 915),
          textScale: 1,
          bottomInset: 34,
        );
        await expectLater(
          find.byType(Scaffold).first,
          matchesGoldenFile(
            '../../../artifacts/quality/work-store-atomic-1-40-r62-47-local-review-20260903/work-dashboard-offline-412x915.png',
          ),
        );
      },
    );

    testWidgets(
      'founder review capture - real store search',
      skip: !captureFounderEvidence,
      (tester) async {
        final work = WorkSession()
          ..seedVerifiedWorkspace()
          ..retailerSetupSaved = true
          ..reviewStage = WorkReviewStage.live
          ..workspaceStoreState = WorkspaceStoreState.open
          ..workspaceAcceptingOrders = true
          ..workspaceVisibleToCustomers = true;
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: const Size(412, 915),
          textScale: 1,
          bottomInset: 34,
        );
        await tester.tap(find.byKey(const Key('work-dashboard-search')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('work-dashboard-search-field')),
          'fortune',
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(Scaffold).first,
          matchesGoldenFile(
            '../../../artifacts/quality/work-store-atomic-1-40-r62-47-local-review-20260903/work-dashboard-search-412x915.png',
          ),
        );
      },
    );

    testWidgets(
      'founder review capture - Grow hub',
      skip: !captureFounderEvidence,
      (tester) async {
        final work = WorkSession()
          ..seedVerifiedWorkspace()
          ..retailerSetupSaved = true
          ..reviewStage = WorkReviewStage.live
          ..workspaceStoreState = WorkspaceStoreState.open
          ..workspaceAcceptingOrders = true
          ..workspaceVisibleToCustomers = true;
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: const Size(412, 915),
          textScale: 1,
          bottomInset: 34,
        );
        await openStoreTools(tester);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('work-business-grow')));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(Scaffold).first,
          matchesGoldenFile(
            '../../../artifacts/quality/work-store-atomic-1-40-r62-47-local-review-20260903/work-dashboard-grow-412x915.png',
          ),
        );
      },
    );

    testWidgets(
      'founder review capture - public storefront preview',
      skip: !captureFounderEvidence,
      (tester) async {
        final work = WorkSession()
          ..seedVerifiedWorkspace()
          ..retailerSetupSaved = true
          ..reviewStage = WorkReviewStage.live
          ..workspaceStoreState = WorkspaceStoreState.open
          ..workspaceAcceptingOrders = true
          ..workspaceVisibleToCustomers = true;
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: const Size(412, 915),
          textScale: 1,
          bottomInset: 34,
        );
        await openStoreTools(tester);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('work-business-preview')));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(Scaffold).first,
          matchesGoldenFile(
            '../../../artifacts/quality/work-store-atomic-1-40-r62-47-local-review-20260903/work-dashboard-public-preview-412x915.png',
          ),
        );
      },
    );
  });

  testWidgets(
    'phone order keeps customer product payment and Mool delivery truth in one flow',
    (tester) async {
      final work = WorkSession()
        ..seedVerifiedWorkspace()
        ..retailerSetupSaved = true
        ..reviewStage = WorkReviewStage.live
        ..workspaceStoreState = WorkspaceStoreState.open
        ..workspaceAcceptingOrders = true
        ..workspaceVisibleToCustomers = true
        ..workspaceOrders.add(
          WorkspaceOrderRecord(
            id: 'ORD-RECENT-1',
            customer: 'Rakesh · 98290 12345',
            items: 'Fortune Sunflower Oil × 1',
            quantities: const {'oil-fortune-1l': 1},
            amount: 264,
            source: 'Counter',
            fulfilment: 'At the shop',
            payment: 'Cash',
            address: '',
            stage: 'Completed',
            needsDelivery: false,
            createdAt: DateTime(2026, 9, 3, 9),
          ),
        );
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: const Size(412, 915),
      );

      await openExistingDeliveryDraft(tester);
      await tester.pumpAndSettle();
      expect(find.text('How did the customer order?'), findsNothing);
      expect(find.text('How will the customer receive it?'), findsNothing);
      await tester.tap(find.byKey(const Key('work-sale-customer')));
      await tester.pumpAndSettle();
      expect(find.text('Recent customers'), findsOneWidget);
      await tester.tap(find.text('Rakesh · 98290 12345'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('work-order-add-oil-fortune-1l')));
      await tester.pumpAndSettle();
      expect(find.text('1 unit'), findsOneWidget);
      expect(find.text('₹264'), findsWidgets);

      await tester.tap(find.byKey(const Key('work-order-review')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-order-review-summary')),
        findsOneWidget,
      );
      expect(find.text('Phone order · 1 unit'), findsOneWidget);
      expect(find.text('Fortune Sunflower Oil × 1'), findsOneWidget);
      expect(find.text('Create order for Mool delivery'), findsOneWidget);
      expect(
        find.textContaining('Rider availability is confirmed after'),
        findsOneWidget,
      );

      await tester.ensureVisible(find.byKey(const Key('work-order-address')));
      await tester.enterText(
        find.byKey(const Key('work-order-address')),
        '12 Market Road, Sardarpura',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('work-order-save')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-orders-destination')), findsOneWidget);
      expect(work.workspaceOrderStage, 'Confirmed');
      expect(work.workspaceOrderFulfilment, 'Mool delivery');
      expect(work.workspaceOrderNeedsDelivery, isTrue);
      expect(work.workspaceOrderAddress, '12 Market Road, Sardarpura');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'counter order changes source and quantity without losing the draft',
    (tester) async {
      final work = liveStore();
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: const Size(412, 915),
        textScale: 1.6,
      );

      await tester.tap(find.byKey(const Key('work-store-sell')));
      await tester.pumpAndSettle();
      await enterSaleCustomer(tester, '9829012345');
      await tester.tap(find.byKey(const Key('work-order-add-oil-fortune-1l')));
      await tester.tap(find.byKey(const Key('work-order-add-oil-fortune-1l')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('work-sale-source')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('work-sell-source-chat')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('work-order-reduce-oil-fortune-1l')),
      );
      await tester.pumpAndSettle();

      expect(work.workspaceOrderCustomer, '9829012345');
      expect(work.workspaceOrderQuantities['oil-fortune-1l'], 1);
      expect(find.byKey(const Key('work-order-address')), findsNothing);
      expect(find.text('Review bill'), findsOneWidget);
      expect(find.text('₹264'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Store Activity Deck replaces rejected dashboard bands', (
    tester,
  ) async {
    final work = liveStore();
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);

    for (final key in const [
      'work-store-activity-deck',
      'work-activity-ready',
      'work-live-status-bubbles',
      'work-store-action-edge',
      'work-quick-promote',
      'work-dashboard-settings',
      'work-dashboard-scan',
    ]) {
      expect(find.byKey(Key(key)), findsOneWidget);
    }
    expect(find.byKey(const Key('work-store-context-rail')), findsNothing);
    expect(
      find.byKey(const Key('work-dashboard-command-centre')),
      findsNothing,
    );
    expect(find.byKey(const Key('work-dashboard-live-metrics')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Store Live first view keeps pulse commands and status operable at large text',
    (tester) async {
      final work = liveStore()..workspaceSalesToday = 28450;
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: const Size(320, 780),
        textScale: 1.4,
      );

      expect(
        find.byKey(const Key('work-store-live-business-pulse')),
        findsOneWidget,
      );
      for (final key in const [
        'work-store-orders',
        'work-pulse-sales',
        'work-store-stock',
        'work-pulse-settlement',
        'work-store-sell',
        'work-quick-store-link',
        'work-quick-buy',
        'work-quick-group-buy',
        'work-quick-promote',
      ]) {
        final action = find.byKey(Key(key));
        expect(action, findsOneWidget);
        expect(action.hitTestable(), findsOneWidget);
        expect(tester.getRect(action).left, greaterThanOrEqualTo(0));
        expect(tester.getRect(action).right, lessThanOrEqualTo(320));
      }
      expect(find.text('Ready for customer activity'), findsNothing);
      expect(find.text('Ready for orders'), findsOneWidget);
      expect(find.text('Mahadev Fresh Mart'), findsOneWidget);
      expect(find.text('₹28,450'), findsOneWidget);
      expect(find.text('Sell'), findsOneWidget);
      expect(find.text('Restock'), findsOneWidget);
      expect(find.text('Group Bulk Buying'), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Store Live pulse opens exact operational destinations', (
    tester,
  ) async {
    final work = liveStore();
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);

    await tester.tap(find.byKey(const Key('work-store-orders')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-orders-destination')), findsOneWidget);
    await tester.tap(find.byKey(const Key('work-operation-back')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('work-store-stock')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('work-dashboard-catalogue-screen')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('work-operation-back')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('work-pulse-settlement')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-money-destination')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Store Live Orders is a compact counted queue at large text', (
    tester,
  ) async {
    final work = liveStore();
    seedIncomingOrder(work);
    await mount(
      tester,
      route: '/app/work/workspace/dashboard',
      work: work,
      viewport: const Size(412, 915),
      textScale: 1.4,
    );

    await tester.tap(find.byKey(const Key('work-store-orders')));
    await tester.pumpAndSettle();
    expect(find.text('Customer orders'), findsOneWidget);
    expect(find.text('1 active'), findsOneWidget);
    expect(find.text('All 1'), findsOneWidget);
    expect(find.text('New 1'), findsOneWidget);
    expect(find.text('Create bill'), findsOneWidget);
    final order = find.byKey(const Key('work-live-order-ticket'));
    expect(order, findsOneWidget);
    expect(tester.getRect(order).height, lessThan(220));
    final filterTop = tester
        .getTopLeft(find.byKey(const Key('work-orders-filter-live')))
        .dy;
    for (final filter in const ['new', 'packing', 'ready', 'done']) {
      expect(
        tester.getTopLeft(find.byKey(Key('work-orders-filter-$filter'))).dy,
        filterTop,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Preparing Orders exposes the packing checklist before Mark ready',
    (tester) async {
      final work = liveStore();
      seedIncomingOrder(work, stage: 'Preparing', delivery: true);
      await mount(tester, route: '/app/work/workspace/dashboard', work: work);

      await tester.tap(find.byKey(const Key('work-store-orders')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-order-pack-summary-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('work-order-pack-summary-1')),
        findsOneWidget,
      );
      expect(find.text('0/3 packed'), findsOneWidget);

      final action = find.widgetWithText(FilledButton, 'Mark ready');
      expect(tester.widget<FilledButton>(action).onPressed, isNull);
      await tester.tap(find.byKey(const Key('work-order-pack-summary-0')));
      await tester.tap(find.byKey(const Key('work-order-pack-summary-1')));
      await tester.pump();
      expect(find.text('3/3 packed'), findsOneWidget);
      expect(tester.widget<FilledButton>(action).onPressed, isNotNull);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(work.workspaceOrderStage, 'Ready');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('leaving an operation clears its action error', (tester) async {
    final work = liveStore();
    seedIncomingOrder(work, stage: 'Preparing');
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);

    work.showError('Mark every product packed before the order is ready.');
    await tester.pump();
    expect(find.byKey(const Key('work-error')), findsOneWidget);
    await tester.tap(find.byKey(const Key('work-store-orders')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-error')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Store Live order decision keeps one clear action row', (
    tester,
  ) async {
    final work = liveStore();
    seedIncomingOrder(work);
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);

    for (final key in const [
      'work-activity-order-call',
      'work-activity-order-chat',
      'work-activity-order-reject',
      'work-activity-order-review',
      'work-activity-order-accept',
    ]) {
      expect(find.byKey(Key(key)).hitTestable(), findsOneWidget);
    }
    expect(find.text('Awaiting acceptance'), findsOneWidget);
    expect(
      find.text('Swipe left to reject · Tap to review · Swipe right to accept'),
      findsNothing,
    );
    await tester.tap(find.byKey(const Key('work-activity-order-review')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-store-exact-order')), findsOneWidget);
    expect(find.byKey(const Key('work-orders-destination')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Store hosts Wholesale and Bulk with one Store navigation owner', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final work = liveStore();
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);

    await tester.tap(find.byKey(const Key('work-quick-buy')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-v2-screen')), findsOneWidget);
    expect(
      find.byKey(const Key('work-store-procurement-screen')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('work-local-navigation')), findsOneWidget);
    expectStoreNavigationOwnsProcurement(tester);
    expect(
      find.bySemanticsLabel('Store choices: Store, Orders, Sell and Stock.'),
      findsOneWidget,
    );
    final accessibleNodes = tester.semantics.simulatedAccessibilityTraversal();
    expect(
      accessibleNodes.any((node) => node.label.contains('Shop choices:')),
      isFalse,
      reason:
          'Only the clipped footer is hidden from assistive navigation, not the Buy body.',
    );
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('buy-search-control')))
          .flagsCollection
          .isHidden,
      isFalse,
    );
    expect(find.text('Wholesale and Bulk'), findsNothing);
    final storeName = find.byKey(const Key('work-procurement-store-name'));
    expect(tester.widget<Text>(storeName).data, work.activeWorkspace!.name);
    expect(tester.widget<Text>(storeName).maxLines, isNull);
    expect(tester.widget<AppBar>(find.byType(AppBar).first).toolbarHeight, 48);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('work-store-procurement-screen')),
      findsNothing,
    );
    expect(find.byKey(const Key('work-store-activity-deck')), findsOneWidget);

    await tester.tap(find.byKey(const Key('work-quick-buy')));
    await tester.pumpAndSettle();
    final storeBack = find.byKey(const Key('work-back')).hitTestable();
    expect(storeBack, findsOneWidget);
    await tester.tap(storeBack);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-store-activity-deck')), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets(
    'in-Store Wholesale search keeps one coherent keyboard and rail owner',
    (tester) async {
      final work = liveStore();
      await mount(tester, route: '/app/work/workspace/dashboard', work: work);

      await tester.tap(find.byKey(const Key('work-quick-buy')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-search-control')));
      await tester.pumpAndSettle();
      final search = find.byKey(const ValueKey('buy-search-field'));
      expect(search, findsOneWidget);

      await tester.enterText(search, 'cooking oil bulk pack');
      final originalSearchState = tester.state(search);
      await tester.pump();
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-local-navigation')), findsNothing);
      final buyRail = find.byKey(const ValueKey('buy-local-destination-tabs'));
      expect(
        buyRail,
        findsNothing,
        reason: 'Buy already hides its own footer while typing.',
      );
      expect(tester.state(search), same(originalSearchState));
      expect(
        tester.widget<TextField>(search).controller!.text,
        'cooking oil bulk pack',
      );
      expect(search.hitTestable(), findsOneWidget);
      expect(tester.getBottomRight(search).dy, lessThanOrEqualTo(500));
      expect(tester.takeException(), isNull);

      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-local-navigation')), findsOneWidget);
      expect(tester.state(search), same(originalSearchState));
      expect(
        tester.widget<TextField>(search).controller!.text,
        'cooking oil bulk pack',
      );
    },
  );

  testWidgets(
    'Android Back closes Wholesale detail before returning to Store',
    (tester) async {
      final work = liveStore();
      await mount(tester, route: '/app/work/workspace/dashboard', work: work);
      await tester.tap(find.byKey(const Key('work-quick-buy')));
      await tester.pumpAndSettle();

      final product = find
          .byWidgetPredicate((widget) {
            final key = widget.key;
            return key is ValueKey<String> &&
                key.value.startsWith('buy-product-');
          })
          .hitTestable()
          .first;
      expect(product, findsOneWidget);
      await tester.tap(product);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-store-procurement-screen')),
        findsOneWidget,
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-store-procurement-screen')),
        findsOneWidget,
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-store-activity-deck')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('incoming order swipes right into Packing', (tester) async {
    final work = liveStore();
    seedIncomingOrder(work);
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);

    expect(find.byKey(const Key('work-activity-incoming-order')), findsOne);
    await tester.fling(
      find.byKey(const Key('work-activity-incoming-order')),
      const Offset(280, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(work.workspaceOrderStage, 'Preparing');
    expect(find.byKey(const Key('work-activity-packing')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final (width, height, scale) in [
    (412.0, 915.0, 1.0),
    (320.0, 568.0, 2.0),
  ]) {
    testWidgets('DASH06 delivery states fit and preserve exact order $scale', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final work = storeViewFixture(null, _ContactDraftFixtureStore());
      final original = work.currentWorkspaceOrder!;
      final operations = WorkOrderOperations(
        accountScope: 'review-draft-account',
        workspaceId: work.activeWorkspace!.id,
        gateway: _OrderCommandFixtureGateway(),
      );
      void update(
        int revision,
        String stage, {
        String? deliveryStage,
        String? customer,
      }) {
        expect(
          operations.observe(
            WorkOrderReply(
              accountScope: operations.accountScope,
              workspaceId: operations.workspaceId,
              orderId: original.id,
              operationId: '',
              revision: revision,
              state: WorkOrderReplyState.applied,
              order: original.copyWith(
                stage: stage,
                customer: customer,
                fulfilment: 'Mool delivery',
                needsDelivery: true,
              ),
              delivery: deliveryStage == null
                  ? null
                  : WorkspaceDeliveryAssignment(
                      orderId: original.id,
                      partnerName: 'Ravi Kumar',
                      vehicleLabel: 'Bike',
                      eta: DateTime.now().add(const Duration(minutes: 5)),
                      updatedAt: DateTime(2026, 9, 10, 9, 55),
                      stage: deliveryStage,
                    ),
            ),
          ),
          isTrue,
        );
      }

      update(
        1,
        'Out for delivery',
        deliveryStage: 'Out for delivery',
        customer: 'Asha Mehta',
      );
      expect(work.bindWorkspaceOrderOperations(operations), isTrue);
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: Size(width, height),
        textScale: scale,
      );
      expect(find.byKey(const Key('work-activity-delivery')), findsOneWidget);
      expect(find.byKey(const Key('work-activity-order-accept')), findsNothing);
      expect(
        find.byKey(const Key('work-activity-confirm-handover')),
        findsNothing,
      );
      expect(
        tester
            .widget<TextButton>(
              find.byKey(const Key('work-delivery-call-customer')),
            )
            .onPressed,
        isNull,
      );
      final progress = find.byKey(const Key('work-delivery-progress'));
      expect(
        find.descendant(of: progress, matching: find.byType(FittedBox)),
        findsNothing,
      );
      final step = tester.widget<AnimatedContainer>(
        find.byKey(const ValueKey('work-delivery-step-2')),
      );
      expect(step.duration, Duration.zero);
      expect((step.decoration! as BoxDecoration).color, MoolColors.navy);
      await captureStoreView(tester, 'delivery-out-for-delivery-$scale');
      expect(tester.takeException(), isNull);
      final map = find.byKey(const Key('work-delivery-open-map'));
      await tester.ensureVisible(map);
      await tester.pumpAndSettle();
      expect(map.hitTestable(), findsOneWidget);
      final chat = find.byKey(const Key('work-delivery-chat-customer'));
      await tester.ensureVisible(chat);
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(chat));
      await tester.tap(chat);
      await tester.pumpAndSettle();
      final draftCard = find.byKey(const Key('chat-pending-draft-card'));
      expect(draftCard, findsOneWidget);
      await captureStoreView(tester, 'delivery-chat-first-view-$scale');
      final uri = GoRouterState.of(tester.element(draftCard)).uri;
      expect(uri.path, '/app/chat/inbox');
      expect(uri.queryParameters['recipient'], 'Asha Mehta');
      expect(uri.queryParameters['draft'], contains(original.id));
      expect(uri.queryParameters['return'], '/app/work/workspace/dashboard');
      final findCustomer = find.byKey(
        const Key('chat-pending-draft-find-customer'),
      );
      await tester.ensureVisible(findCustomer);
      await tester.pumpAndSettle();
      expect(findCustomer.hitTestable(), findsOneWidget);
      await captureStoreView(tester, 'delivery-chat-draft-$scale');
      expect(tester.takeException(), isNull);
      router.pop();
      await tester.pumpAndSettle();
      expect(work.currentWorkspaceOrderId, original.id);
      expect(find.byKey(const Key('work-activity-delivery')), findsOneWidget);
      update(2, 'Delivery failed', deliveryStage: 'Failed');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-delivery-progress')), findsNothing);
      expect(
        find.byKey(const Key('work-activity-confirm-handover')),
        findsNothing,
      );
      await captureStoreView(tester, 'delivery-needs-attention-$scale');
      expect(tester.takeException(), isNull);
      update(3, 'Delivery cancelled');
      await tester.pumpAndSettle();
      expect(work.workspaceDeliveryAssignment, isNull);
      expect(find.text('Delivery cancelled'), findsWidgets);
      expect(
        find.byKey(const Key('work-activity-incoming-order')),
        findsNothing,
      );
      update(4, 'Future stage');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-activity-order-attention')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('work-activity-incoming-order')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('DASH06 delivery aliases never present incoming order actions', (
    tester,
  ) async {
    final work = liveStore();
    seedIncomingOrder(work, stage: 'Assigned', delivery: true);
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    for (final stage in [
      'Assigned',
      'At store',
      'Picked up',
      'Out for delivery',
      'Dispatched',
      'Delivering',
      'Delivery failed',
      'Delivery cancelled',
    ]) {
      work.workspaceOrderStage = stage;
      work.showNotice('');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-activity-delivery')),
        findsOneWidget,
        reason: stage,
      );
      expect(
        find.byKey(const Key('work-activity-incoming-order')),
        findsNothing,
        reason: stage,
      );
      expect(tester.takeException(), isNull, reason: stage);
    }
  });

  for (final stage in ['Out for delivery', 'Delivery failed']) {
    testWidgets(
      'DASH06 order list opens exact tracking without advancing $stage',
      (tester) async {
        final work = storeViewFixture();
        final original = work.currentWorkspaceOrder!;
        work.workspaceOrders[0] = original.copyWith(
          stage: stage,
          needsDelivery: true,
          fulfilment: 'Mool delivery',
        );
        work.workspaceOrderStage = stage;
        work.workspaceOrderNeedsDelivery = true;
        work.workspaceOrderFulfilment = 'Mool delivery';
        work.workspaceDeliveryAssignment = WorkspaceDeliveryAssignment(
          orderId: original.id,
          partnerName: 'Rider A',
          vehicleLabel: 'Bike',
          eta: DateTime.now().subtract(const Duration(minutes: 1)),
          stage: stage,
        );
        await mount(tester, route: '/app/work/workspace/dashboard', work: work);
        await tester.tap(find.byKey(const Key('work-store-orders')));
        await tester.pumpAndSettle();
        final track = find.widgetWithText(FilledButton, 'Track delivery');
        await tester.ensureVisible(track);
        await tester.pumpAndSettle();
        expect(track.hitTestable(), findsOneWidget);
        await tester.tap(track);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-delivery-destination')),
          findsOneWidget,
        );
        expect(work.currentWorkspaceOrderId, original.id);
        expect(work.workspaceOrderStage, stage);
        expect(work.workspaceInvoices, isEmpty);
        expect(
          find.byKey(const Key('work-activity-confirm-handover')),
          findsNothing,
        );
        if (stage == 'Out for delivery') {
          expect(find.text('Awaiting arrival update'), findsOneWidget);
          expect(find.text('Time ended'), findsNothing);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final changed in ['order', 'store', 'contact']) {
    testWidgets('DASH06 stale delivery taps cannot retarget $changed', (
      tester,
    ) async {
      final work = storeViewFixture();
      final original = work.currentWorkspaceOrder!;
      work.workspaceOrders[0] = original.copyWith(
        stage: 'Out for delivery',
        fulfilment: 'Own delivery',
        needsDelivery: true,
        address: 'Test lane',
      );
      work.workspaceOrderStage = 'Out for delivery';
      work.workspaceOrderFulfilment = 'Own delivery';
      work.workspaceOrderNeedsDelivery = true;
      work.workspaceOrderAddress = 'Test lane';
      work.workspaceDeliveryAssignment = WorkspaceDeliveryAssignment(
        orderId: original.id,
        partnerName: 'Rider A',
        vehicleLabel: 'Bike',
        eta: DateTime.now(),
        stage: 'Picked up',
      );
      await mount(tester, route: '/app/work/workspace/dashboard', work: work);
      final callbacks = [
        for (final key in [
          'work-delivery-call-customer',
          'work-delivery-chat-customer',
          'work-delivery-open-map',
        ])
          tester.widget<TextButton>(find.byKey(Key(key))).onPressed!,
        tester
            .widget<FilledButton>(
              find.byKey(const Key('work-activity-confirm-handover')),
            )
            .onPressed!,
      ];
      if (changed == 'order') {
        expect(work.selectWorkspaceOrder('SALE-1042'), isTrue);
      } else if (changed == 'store') {
        work.activeWorkspace = const WorkWorkspace(
          id: 'other-store',
          name: 'Other Store',
          profileId: 'retailer-grocery',
          profileLabel: 'Grocery',
          area: 'Jodhpur',
          verified: true,
        );
      } else {
        work.workspaceOrderCustomer = 'Different customer · 9876543210';
      }
      for (final callback in callbacks) {
        callback();
      }
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-pending-draft-card')), findsNothing);
      expect(find.byKey(const Key('work-handover-otp')), findsNothing);
      expect(
        find.text('Could not open your phone app. Please try again.'),
        findsNothing,
      );
      expect(work.workspaceInvoices, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Packing moves to the live delivery object in one tap', (
    tester,
  ) async {
    final work = liveStore();
    seedIncomingOrder(work, stage: 'Preparing', delivery: true);
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);

    for (final line in work.workspacePackingLines) {
      work.setWorkspacePackingLine(line.id, true);
    }
    await tester.pump();
    await tester.tap(find.byKey(const Key('work-activity-mark-ready')));
    await tester.pumpAndSettle();
    expect(work.workspaceOrderStage, 'Ready');
    expect(find.byKey(const Key('work-activity-delivery')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Packing counts units and keeps customer help visible', (
    tester,
  ) async {
    final work = liveStore();
    seedIncomingOrder(work, stage: 'Preparing', delivery: true);
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);

    expect(find.text('0 of 3 units packed'), findsOneWidget);
    expect(
      find.byKey(const Key('work-packing-contact-customer')).hitTestable(),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('work-pack-summary-0')));
    await tester.pump();
    expect(find.text('2 of 3 units packed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Orders requests a rider before opening the delivery desk', (
    tester,
  ) async {
    final work = liveStore();
    seedIncomingOrder(work, stage: 'Ready', delivery: true);
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);

    await tester.tap(find.byKey(const Key('work-store-orders')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Arrange delivery'));
    await tester.pumpAndSettle();
    expect(work.workspaceOrderStage, 'Delivery requested');
    expect(work.workspaceDeliveryAssignment, isNotNull);
    expect(find.byKey(const Key('work-delivery-destination')), findsOneWidget);
    expect(find.text('Rider · Review delivery partner'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Delivery keeps call Chat map and handover actions visible', (
    tester,
  ) async {
    final work = liveStore();
    seedIncomingOrder(work, stage: 'Ready', delivery: true);
    work.workspaceDeliveryAssignment = WorkspaceDeliveryAssignment(
      orderId: 'current-store-order',
      partnerName: 'Ravi Kumar',
      vehicleLabel: 'Bike RJ19 AB 1234',
      eta: DateTime.now().add(const Duration(minutes: 8)),
      stage: 'Assigned',
    );
    await mount(
      tester,
      route: '/app/work/workspace/dashboard',
      work: work,
      viewport: const Size(412, 915),
      textScale: 1.4,
    );

    expect(find.text('Assigned'), findsOneWidget);
    expect(find.text('At store'), findsOneWidget);
    expect(find.text('Picked up'), findsOneWidget);
    expect(find.text('Delivered'), findsOneWidget);
    for (final key in const [
      'work-delivery-call-customer',
      'work-delivery-chat-customer',
      'work-delivery-open-map',
      'work-delivery-proof-pending',
    ]) {
      expect(find.byKey(Key(key)).hitTestable(), findsOneWidget);
    }
    for (final entry in const {
      'Call': 'work-delivery-call-customer',
      'Chat': 'work-delivery-chat-customer',
      'Map': 'work-delivery-open-map',
    }.entries) {
      final label = find.descendant(
        of: find.byKey(Key(entry.value)),
        matching: find.text(entry.key),
      );
      expect(tester.getSize(label).height, lessThan(32));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'own-delivery customer OTP completes delivery without a sheet lifecycle error',
    (tester) async {
      final work = liveStore();
      seedIncomingOrder(work, stage: 'Delivery requested', delivery: true);
      work.currentWorkspaceOrderId = 'current-store-order';
      work.workspaceOrderFulfilment = 'Own delivery';
      work.workspaceOrders.add(
        WorkspaceOrderRecord(
          id: 'current-store-order',
          customer: work.workspaceOrderCustomer,
          items: work.workspaceOrderItems,
          quantities: const {'oil-fortune-1l': 1},
          amount: 1468,
          source: work.workspaceOrderSource,
          fulfilment: work.workspaceOrderFulfilment,
          payment: work.workspaceOrderPayment,
          address: work.workspaceOrderAddress,
          stage: 'Delivery requested',
          needsDelivery: true,
          createdAt: DateTime(2026, 9, 4, 4, 45),
        ),
      );
      work.workspaceDeliveryAssignment = WorkspaceDeliveryAssignment(
        orderId: 'current-store-order',
        partnerName: 'Ravi Kumar',
        vehicleLabel: 'Bike RJ19 AB 1234',
        eta: DateTime.now().add(const Duration(minutes: 8)),
        stage: 'Picked up',
      );
      await mount(tester, route: '/app/work/workspace/dashboard', work: work);

      await tester.ensureVisible(
        find.byKey(const Key('work-activity-confirm-handover')),
      );
      await tester.tap(find.byKey(const Key('work-activity-confirm-handover')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('work-handover-otp')),
        '123456',
      );
      final confirm = find.byKey(const Key('work-handover-confirm'));
      await tester.ensureVisible(confirm);
      await tester.pump();
      await tester.tap(confirm.hitTestable());
      await tester.pumpAndSettle();
      expect(work.workspaceOrderStage, 'Completed');
      expect(work.workspaceInvoices, isNotEmpty);
      expect(find.byKey(const Key('work-handover-otp')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Settings owns configuration and excludes SKU commercial data', (
    tester,
  ) async {
    final work = liveStore();
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);

    await openStoreSettings(tester);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-dashboard-status-screen')), findsOne);
    expect(find.text('Public storefront'), findsOneWidget);
    await reveal(tester, find.text('Default preparation time'));
    expect(find.text('Default preparation time'), findsOneWidget);
    await reveal(tester, find.text('Pickup and delivery'));
    expect(find.text('Pickup and delivery'), findsOneWidget);
    expect(find.text('Selling Price'), findsNothing);
    expect(find.text('MRP'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Workspace catalogue maps exactly into Buy public SKU facts', (
    tester,
  ) async {
    final work = liveStore();
    final product = work.workspaceCatalogueItems.first;
    final buySku = product.toBuyPublicProduct(
      storeName: work.activeWorkspace!.name,
    );
    final facts = product.toBuyPublicFacts(
      storeName: work.activeWorkspace!.name,
      sourceId: 'workspace:${work.activeWorkspace!.id}',
      storeVisible: true,
      acceptingOrders: true,
      observedAt: DateTime(2026, 9, 3, 8, 30),
    );
    expect(buySku.canonicalId, product.canonicalId);
    expect(buySku.title, product.title);
    expect(buySku.brand, product.brand);
    expect(buySku.variant, product.variant);
    expect(buySku.pack, product.pack);
    expect(buySku.price, product.sellingPrice);
    expect(buySku.mrp, product.mrp);
    expect(buySku.unitPrice, product.unitPrice);
    expect(buySku.deliveryPromise, product.deliveryPromise);
    expect(buySku.catalogueListing, product.publicListing);
    expect(facts.price, product.sellingPrice);
    expect(facts.partner, work.activeWorkspace!.name);
    expect(facts.orderabilityLabel, 'Available to order');

    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    await tester.tap(find.byKey(const Key('work-store-stock')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-dashboard-catalogue-screen')), findsOne);
    expect(find.byKey(Key('work-public-sku-${product.id}')), findsOneWidget);
    expect(find.textContaining('₹${product.sellingPrice}'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Group Bulk Buying opens the live payment-backed deal', (
    tester,
  ) async {
    final work = liveStore()
      ..applyConfirmedWorkspaceGroupBuyPayment(
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
        paymentReference: 'PAY-REVIEW-001',
        closingLabel: '5 Sep · 8:00 PM',
        storeDeliveryLabel: '7 Sep · Door delivery',
      );
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    expect(find.byKey(const Key('work-activity-group-bulk')), findsOneWidget);
    await tester.tap(find.byKey(const Key('work-quick-group-buy')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-group-buy-active-screen')), findsOne);
    expect(
      find.descendant(
        of: find.byKey(const Key('work-group-buy-active-screen')),
        matching: find.text('Group Bulk Buying'),
      ),
      findsOneWidget,
    );
    expect(find.text('₹14/kg'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Group Bulk keeps confirmed quantity costs and payment truth', (
    tester,
  ) async {
    final work = liveStore()
      ..applyConfirmedWorkspaceGroupBuyPayment(
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
        paymentReference: 'PAY-REVIEW-001',
        closingLabel: '5 Sep · 8:00 PM',
        storeDeliveryLabel: '7 Sep · Door delivery',
      );
    await mount(
      tester,
      route: '/app/work/workspace/dashboard',
      work: work,
      viewport: const Size(412, 915),
    );
    await tester.tap(find.byKey(const Key('work-quick-group-buy')));
    await tester.pumpAndSettle();
    expect(find.text('280 / 1000 kg'), findsOneWidget);
    expect(find.text('₹14/kg'), findsWidgets);
    await reveal(tester, find.text('720 kg'));
    expect(find.text('720 kg'), findsOneWidget);
    await reveal(tester, find.text('Saving after listed fees'));
    expect(find.text('₹920'), findsOneWidget);
    expect(work.activeGroupBuy?.deliveredTotal, 4120);
    expect(work.activeGroupBuy?.balanceDue, 200);
    await reveal(tester, find.text('Confirmation payment recorded'));
    expect(find.text('Confirmation payment recorded'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('work-group-value-Confirmation amount')),
        matching: find.text('₹3,920'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Awaiting stock confirmation'), findsOneWidget);
    expect(
      find.byKey(const Key('work-group-buy-next-action')),
      findsNothing,
      reason: 'No payment request before authoritative stock confirmation',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Workspace switcher keeps the approval action above Android', (
    tester,
  ) async {
    final work = liveStore()..seedMultipleWorkspaces();
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    await tester.tap(
      find.byKey(const Key('work-dashboard-workspace-switcher')),
    );
    await tester.pumpAndSettle();
    final request = find.byKey(const Key('work-switch-add-workspace'));
    expect(request, findsOneWidget);
    await tester.ensureVisible(request);
    expect(request.hitTestable(), findsOneWidget);
    expect(tester.getBottomRight(request).dy, lessThanOrEqualTo(756));
    expect(find.textContaining('Create content anytime from Social'), findsOne);
  });

  for (final width in [320.0, 412.0]) {
    testWidgets(
      'full store name and content-sized Workspace picker at $width',
      (tester) async {
        final work = storeViewFixture();
        final original = work.activeWorkspace!;
        work.activeWorkspace = WorkWorkspace(
          id: original.id,
          name: 'Shree Mahadev Fresh Mart and General Store',
          profileLabel: original.profileLabel,
          profileId: original.profileId,
          area: original.area,
          verified: original.verified,
        );
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: Size(width, 915),
          textScale: 1.4,
          bottomInset: 34,
        );
        await tester.tap(find.byKey(const Key('work-store-orders')));
        await tester.pumpAndSettle();
        final name = find.byKey(const Key('work-store-full-name'));
        final paragraph = tester.renderObject<RenderParagraph>(name);
        expect(paragraph.didExceedMaxLines, isFalse);
        final stage = find.byKey(const Key('work-order-stage-label-APP-1043'));
        expect(
          tester.renderObject<RenderParagraph>(stage).didExceedMaxLines,
          isFalse,
        );
        expect(find.text('Accept within'), findsOneWidget);
        expect(
          tester.getBottomRight(name).dy,
          lessThan(
            tester
                .getTopLeft(find.byKey(const Key('work-dashboard-search')))
                .dy,
          ),
        );
        expect(tester.takeException(), isNull);
        if (width == 320) {
          await captureStoreView(tester, '30-full-store-name-large-text');
        }
        await tester.tap(
          find.byKey(const Key('work-dashboard-workspace-switcher')),
        );
        await tester.pumpAndSettle();
        final sheet = find.byKey(const Key('work-workspace-switcher-sheet'));
        expect(tester.getRect(sheet).height, lessThan(430));
        final request = find.byKey(const Key('work-switch-add-workspace'));
        expect(request.hitTestable(), findsOneWidget);
        expect(tester.getBottomRight(request).dy, lessThanOrEqualTo(881));
        expect(tester.takeException(), isNull);
        if (width == 320) {
          await captureStoreView(
            tester,
            '31-compact-workspace-picker-large-text',
          );
        }
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-orders-destination')),
          findsOneWidget,
        );
      },
    );
  }

  testWidgets(
    'order completion action clears Android navigation and is tappable',
    (tester) async {
      final work = liveStore();
      await mount(tester, route: '/app/work/workspace/dashboard', work: work);
      await tester.tap(find.byKey(const Key('work-store-sell')));
      await tester.pumpAndSettle();
      await enterSaleCustomer(tester, '9829012345');
      await tester.tap(find.byKey(const Key('work-order-add-oil-fortune-1l')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('work-order-review')));
      await tester.pumpAndSettle();
      final save = find.byKey(const Key('work-order-save'));
      expect(save, findsOneWidget);
      expect(save.hitTestable(), findsOneWidget);
      expect(tester.getBottomRight(save).dy, lessThanOrEqualTo(756));
    },
  );

  testWidgets('Store settings destinations match their labels', (tester) async {
    final work = liveStore();
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    await openStoreSettings(tester);
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Delivery area and charges'));
    await tester.tap(find.text('Delivery area and charges'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-delivery-settings-screen')), findsOne);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-dashboard-status-screen')), findsOne);
    await reveal(tester, find.text('Staff and counters'));
    await tester.tap(find.text('Staff and counters'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-staff-settings-screen')), findsOne);
  });

  testWidgets('pickup order becomes customer pickup and produces invoice', (
    tester,
  ) async {
    final work = liveStore();
    seedIncomingOrder(work, stage: 'Preparing');
    for (final line in work.workspacePackingLines) {
      work.setWorkspacePackingLine(line.id, true);
    }
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    await tester.tap(find.byKey(const Key('work-activity-mark-ready')));
    await tester.pumpAndSettle();
    expect(work.workspaceOrderStage, 'Ready for pickup');
    expect(find.byKey(const Key('work-activity-pickup-ready')), findsOne);
    expect(find.text('Delivery partner assignment pending'), findsNothing);
    await tester.tap(find.byKey(const Key('work-confirm-customer-pickup')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-pickup-code')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('work-pickup-code')), '123');
    await tester.tap(find.byKey(const Key('work-pickup-confirm')));
    await tester.pumpAndSettle();
    expect(work.workspaceOrderStage, 'Ready for pickup');
    expect(
      find.text('Enter the 6-digit pickup code shared with the customer.'),
      findsWidgets,
    );
    await tester.enterText(find.byKey(const Key('work-pickup-code')), '123456');
    await tester.tap(find.byKey(const Key('work-pickup-confirm')));
    await tester.pumpAndSettle();
    expect(work.workspaceOrderStage, 'Completed');
    expect(work.workspaceInvoices, isNotEmpty);
    expect(find.byKey(const Key('work-invoice-open')).hitTestable(), findsOne);
    await tester.tap(find.byKey(const Key('work-invoice-open')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-invoice-share-chat')), findsOne);
    await tester.tap(find.byKey(const Key('work-invoice-share-chat')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-pending-draft-card')), findsOne);
    expect(find.textContaining('INV-'), findsWidgets);
    expect(work.latestWorkspaceInvoice!.needsCustomerHandoff, isTrue);
    expect(work.latestWorkspaceInvoice!.sharedChannels, isEmpty);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await captureStoreView(tester, 'pickup-invoice-chat-back');
    expect(find.byKey(const Key('work-store-activity-deck')), findsOneWidget);
    expect(find.byKey(const Key('chat-inbox-screen')), findsNothing);
    expect(find.byKey(const Key('work-activity-invoice')), findsOneWidget);
    expect(work.latestWorkspaceInvoice!.needsCustomerHandoff, isTrue);
    expect(work.workspaceInvoices, hasLength(1));
  });

  testWidgets('live App order appears in customer statement', (tester) async {
    final work = liveStore();
    seedIncomingOrder(work);
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    await openStoreTools(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-business-customers')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Rakesh'), findsWidgets);
    expect(find.text('No customer sale yet'), findsNothing);
    await tester.tap(find.byKey(const Key('work-customer-9829012345')));
    await tester.pumpAndSettle();
    final statement = find.byKey(
      const Key('work-customer-order-current-store-order'),
    );
    await reveal(tester, statement);
    expect(statement, findsOne);
  });

  testWidgets('Customer Book fits four customers with direct daily actions', (
    tester,
  ) async {
    final work = liveStore();
    final now = DateTime.now();
    work.workspaceOrders.addAll([
      customerOrder(
        id: 'CUST-1',
        customer: 'Rakesh · 98290 12345',
        createdAt: now,
      ),
      customerOrder(
        id: 'CUST-2',
        customer: 'Sunita · 98290 22345',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      customerOrder(
        id: 'CUST-3',
        customer: 'Imran · 98290 32345',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      customerOrder(
        id: 'CUST-4',
        customer: 'Meena · 98290 42345',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ]);
    await mount(
      tester,
      route: '/app/work/workspace/dashboard',
      work: work,
      viewport: const Size(412, 915),
      textScale: 1,
    );
    await openStoreTools(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-business-customers')));
    await tester.pumpAndSettle();

    final fourth = find.byKey(const Key('work-customer-9829042345'));
    expect(fourth, findsOneWidget);
    expect(fourth.hitTestable(), findsOneWidget);
    expect(
      tester.getBottomRight(fourth).dy,
      lessThanOrEqualTo(
        tester.getTopLeft(find.byKey(const Key('work-local-navigation'))).dy,
      ),
    );
    expect(
      find.byKey(const Key('work-customer-call-9829012345')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('work-customer-chat-9829012345')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Customer filters and repeat basket keep exact customer stock', (
    tester,
  ) async {
    final work = liveStore();
    final now = DateTime.now();
    work.workspaceOrders.addAll([
      customerOrder(
        id: 'REP-1',
        customer: 'Rakesh · 98290 12345',
        createdAt: now,
      ),
      customerOrder(
        id: 'REP-2',
        customer: 'Rakesh · 98290 12345',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      customerOrder(
        id: 'DUE-1',
        customer: 'Sunita · 98290 22345',
        createdAt: now.subtract(const Duration(days: 1)),
        amount: 540,
        payment: 'Customer due',
      ),
    ]);
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    await openStoreTools(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-business-customers')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-customer-filter-repeat')));
    await tester.pumpAndSettle();
    expect(find.text('Rakesh'), findsOneWidget);
    expect(find.text('Sunita'), findsNothing);

    await tester.tap(find.byKey(const Key('work-customer-9829012345')));
    await tester.pumpAndSettle();
    expect(find.text('Offer locked'), findsOneWidget);
    expect(
      find.textContaining('only after the customer allows store messages'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('work-customer-repeat')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('work-dashboard-counter-order-screen')),
      findsOneWidget,
    );
    expect(work.workspaceOrderCustomer, 'Rakesh · 98290 12345');
    expect(work.workspaceOrderQuantities['oil-fortune-1l'], 1);
  });

  testWidgets('settlement requires review before gateway mutation', (
    tester,
  ) async {
    final gateway = ReviewWorkGateway();
    final work = liveStore(gateway: gateway)
      ..workspaceSettlementBalance = 17820;
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    await openStoreTools(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-business-money')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-money-request-settlement')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-settlement-confirm')), findsOne);
    expect(gateway.settlementCalls, 0);
  });

  testWidgets('Money keeps net payout and receiving account in first action', (
    tester,
  ) async {
    final work = liveStore()
      ..workspaceSettlementBalance = 20000
      ..workspacePlatformAdjustments = 900
      ..workspaceDeliveryAdjustments = 300
      ..workspaceRefunds = 400
      ..workspaceTaxWithheld = 200
      ..workspaceSalesToday = 28450;
    await mount(
      tester,
      route: '/app/work/workspace/dashboard',
      work: work,
      viewport: const Size(412, 915),
    );
    await openStoreTools(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-business-money')));
    await tester.pumpAndSettle();

    expect(find.text('₹18,200'), findsWidgets);
    expect(find.text('Sales awaiting completion'), findsOneWidget);
    expect(find.text('MoolSocial fees'), findsOneWidget);
    expect(find.text('Delivery adjustments'), findsOneWidget);
    expect(find.text('Platform and fulfilment adjustments'), findsNothing);
    final request = find.byKey(const Key('work-money-request-settlement'));
    expect(request.hitTestable(), findsOneWidget);
    await tester.tap(request);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-settlement-review')), findsOneWidget);
    expect(find.textContaining('State Bank of India'), findsOneWidget);
    expect(find.textContaining('•••• 2486'), findsOneWidget);
    expect(find.text('Net payout requested'), findsOneWidget);
    expect(find.text('Expected by'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Group Bulk does not fabricate an offer or self-confirm payment',
    (tester) async {
      final work = liveStore();
      await mount(tester, route: '/app/work/workspace/dashboard', work: work);
      await tester.tap(find.byKey(const Key('work-quick-group-buy')));
      await tester.pumpAndSettle();
      expect(find.text('No group purchase open'), findsOneWidget);
      expect(find.byKey(const Key('work-group-buy-product')), findsNothing);
      expect(
        find.byKey(const Key('work-group-buy-payment-confirmed')),
        findsNothing,
      );
      expect(work.activeGroupBuy, isNull);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-store-activity-deck')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('product editor keeps Save and Cancel above keyboard', (
    tester,
  ) async {
    final work = liveStore();
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    await tester.tap(find.byKey(const Key('work-store-stock')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('work-catalogue-edit-oil-fortune-1l')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-product-save')).hitTestable(), findsOne);
    expect(
      find.byKey(const Key('work-product-cancel')).hitTestable(),
      findsOne,
    );
    await tester.ensureVisible(
      find.byKey(const Key('work-product-details-section')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-product-details-section')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('work-product-title')));
    await tester.tap(find.byKey(const Key('work-product-title')));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-product-save')).hitTestable(), findsOne);
    expect(
      tester.getBottomRight(find.byKey(const Key('work-product-save'))).dy,
      lessThanOrEqualTo(500),
    );
    tester.view.viewInsets = FakeViewPadding.zero;
  });

  for (final (width, height, scale, bottom, keyboard) in [
    (412.0, 915.0, 1.0, 0.0, 0.0),
    (412.0, 915.0, 1.0, 44.0, 0.0),
    (320.0, 640.0, 2.0, 44.0, 0.0),
    (320.0, 568.0, 2.0, 80.0, 0.0),
    (412.0, 915.0, 2.0, 24.0, 200.0),
    (320.0, 568.0, 2.0, 44.0, 200.0),
  ]) {
    testWidgets(
      'REG4558 product tools safe final action $width $height $scale $bottom $keyboard',
      (tester) async {
        final work = liveStore();
        final storeId = work.activeWorkspace!.id;
        final products = List.of(work.workspaceCatalogueItems);
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: Size(width, height),
          textScale: scale,
          bottomInset: bottom,
        );
        await tester.tap(find.byKey(const Key('work-store-stock')));
        await tester.pumpAndSettle();
        final more = find.byKey(const Key('work-catalogue-more'));
        await reveal(tester, more);
        await tester.tap(more);
        await tester.pumpAndSettle();
        final close = find.byKey(const Key('work-catalogue-tools-close'));
        expect(close.hitTestable(), findsOneWidget);
        expect(tester.getSize(close).shortestSide, greaterThanOrEqualTo(48));
        if (keyboard > 0) {
          tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
          await tester.pumpAndSettle();
        }
        final last = find.byKey(
          const Key('work-catalogue-open-stock-statement'),
        );
        await reveal(tester, last);
        final boundary = height - (keyboard > 0 ? keyboard : bottom);
        expect(tester.getBottomRight(last).dy, lessThanOrEqualTo(boundary - 8));
        expect(last.hitTestable(), findsOneWidget);
        expect(tester.getSize(last).height, greaterThanOrEqualTo(48));
        final subtitle = find.descendant(
          of: last,
          matching: find.text('Available, reserved and quantity changes'),
        );
        final paragraph = tester.renderObject<RenderParagraph>(subtitle);
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(
          tester.getBottomRight(subtitle).dy,
          lessThanOrEqualTo(boundary - 8),
        );
        await captureStoreView(
          tester,
          'product-tools-$width-$height-$scale-$bottom-$keyboard',
        );
        expect(tester.takeException(), isNull);
        tester.view.viewInsets = const FakeViewPadding();
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-catalogue-tools-scroll')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('work-dashboard-catalogue-screen')),
          findsOneWidget,
        );
        expect(work.activeWorkspace!.id, storeId);
        expect(work.workspaceCatalogueItems, orderedEquals(products));
        await reveal(tester, more);
        await tester.tap(more);
        await tester.pumpAndSettle();
        await tester.tap(close);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-catalogue-tools-scroll')),
          findsNothing,
        );
        await tester.tap(more);
        await tester.pumpAndSettle();
        await reveal(tester, last);
        await tester.tap(last);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-stock-statement-screen')),
          findsOneWidget,
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-dashboard-catalogue-screen')),
          findsOneWidget,
        );
        expect(work.activeWorkspace!.id, storeId);
        expect(work.workspaceCatalogueItems, orderedEquals(products));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('REG4558 old-store tools cannot navigate in a changed store', (
    tester,
  ) async {
    final work = liveStore();
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    await tester.tap(find.byKey(const Key('work-store-stock')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-catalogue-more')));
    await tester.pumpAndSettle();
    final last = find.byKey(const Key('work-catalogue-open-stock-statement'));
    await reveal(tester, last);
    work.activeWorkspace = const WorkWorkspace(
      id: 'different-store',
      name: 'Second Store',
      profileLabel: 'Grocery / Kirana Shop',
      profileId: 'retailer-grocery',
      area: 'Jodhpur',
      verified: true,
    );
    await tester.tap(last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-stock-statement-screen')), findsNothing);
    expect(
      work.noticeMessage,
      'Your store changed. Open its product tools again.',
    );
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('R6617 stock quantity safe keyboard and validation $scale', (
      tester,
    ) async {
      final work = liveStore();
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: const Size(320, 568),
        textScale: scale,
        bottomInset: 24,
      );
      await tester.tap(find.byKey(const Key('work-store-stock')));
      await tester.pumpAndSettle();
      final edit = find.byKey(const Key('work-catalogue-stock-oil-fortune-1l'));
      await reveal(tester, edit);
      await tester.tap(edit);
      await tester.pumpAndSettle();
      final field = find.byKey(const Key('work-quick-stock'));
      final save = find.byKey(const Key('work-quick-stock-save'));
      final before = work.workspaceCatalogueItems.first.stock;
      final movements = work.workspaceStockMovements.length;
      tester.view.viewInsets = const FakeViewPadding(bottom: 220);
      await tester.pumpAndSettle();
      await tester.enterText(field, '-1');
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      expect(save.hitTestable(), findsOneWidget);
      expect(tester.getBottomRight(save).dy, lessThanOrEqualTo(348));
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid available quantity.'), findsOneWidget);
      expect(work.workspaceCatalogueItems.first.stock, before);
      expect(work.workspaceStockMovements, hasLength(movements));
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await captureStoreView(tester, 'stock-keyboard-open-error-$scale');
      await tester.enterText(field, '4');
      tester.view.viewInsets = const FakeViewPadding();
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field).controller!.text, '4');
      expect(find.text('Enter a valid available quantity.'), findsNothing);
      final reasonField = find.byKey(const Key('work-quick-stock-reason'));
      final reasonText = find.descendant(
        of: reasonField,
        matching: find.text('Counted in store'),
      );
      expect(reasonText, findsOneWidget);
      expect(
        tester.getBottomRight(reasonText).dy,
        lessThanOrEqualTo(tester.getBottomRight(reasonField).dy),
      );
      expect(save.hitTestable(), findsOneWidget);
      expect(tester.getSize(save).height, greaterThanOrEqualTo(48));
      expect(tester.getBottomRight(save).dy, lessThanOrEqualTo(544));
      expect(tester.takeException(), isNull);
      await captureStoreView(tester, 'stock-keyboard-closed-$scale');
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(field, findsNothing);
      expect(work.workspaceCatalogueItems.first.stock, 4);
      expect(work.workspaceStockMovements, hasLength(movements + 1));
      expect(work.workspaceStockMovements.first.reason, 'Counted in store');
      await tester.tap(edit);
      await tester.pumpAndSettle();
      await tester.enterText(field, '7');
      tester.testTextInput.hide();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(field, findsNothing);
      expect(work.workspaceCatalogueItems.first.stock, 4);
      expect(work.workspaceStockMovements, hasLength(movements + 1));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('catalogue keeps daily product actions direct and compact', (
    tester,
  ) async {
    final work = liveStore();
    await mount(
      tester,
      route: '/app/work/workspace/dashboard',
      work: work,
      viewport: const Size(412, 915),
    );
    await tester.tap(find.byKey(const Key('work-store-stock')));
    await tester.pumpAndSettle();

    expect(find.text('Products'), findsWidgets);
    expect(find.byKey(const Key('work-catalogue-scan')), findsNothing);
    expect(find.byKey(const Key('work-dashboard-scan')), findsOneWidget);
    expect(find.byKey(const Key('work-catalogue-add')), findsOneWidget);
    expect(find.byKey(const Key('work-catalogue-more')), findsOneWidget);
    expect(
      find.byKey(const Key('work-catalogue-price-oil-fortune-1l')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('work-catalogue-stock-oil-fortune-1l')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('work-catalogue-price-oil-fortune-1l')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('work-quick-price')), '265');
    await tester.tap(find.byKey(const Key('work-quick-price-save')));
    await tester.pumpAndSettle();
    expect(work.workspaceCatalogueItems.first.sellingPrice, 265);

    await tester.tap(
      find.byKey(const Key('work-catalogue-stock-oil-fortune-1l')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('work-quick-stock')), '4');
    await tester.tap(find.byKey(const Key('work-quick-stock-save')));
    await tester.pumpAndSettle();
    expect(work.workspaceCatalogueItems.first.stock, 4);
    expect(work.workspaceStockMovements.first.reason, 'Counted in store');

    await tester.tap(
      find.byKey(const Key('work-catalogue-visibility-oil-fortune-1l')),
    );
    await tester.pumpAndSettle();
    expect(work.workspaceCatalogueItems.first.publicListing, isFalse);
    expect(tester.takeException(), isNull);
  });

  for (final (scale, viewport, activeOrders, editing) in [
    (1.0, const Size(412, 915), 100, false),
    (2.0, const Size(412, 915), 100, false),
    (2.0, const Size(320, 568), 100, false),
    (1.0, const Size(412, 915), 1000, false),
    (2.0, const Size(320, 568), 1000, false),
    (1.0, const Size(412, 915), 1000, true),
    (2.0, const Size(320, 568), 1000, true),
  ]) {
    final stockViewSuffix = '$scale-${viewport.width.toInt()}-$activeOrders';
    testWidgets(
      '${editing ? 'DASH15 active editors during mixed updates' : 'DASH11 scoped supplier offers selection states and Back'} $stockViewSuffix',
      (tester) async {
        final contact = _ContactDraftFixtureStore();
        final work = storeViewFixture(null, contact);
        final chat = ChatSession(
          sendGateway: ReviewChatSendGateway(latency: Duration.zero),
        );
        chat.setDraftTextForSession(
          'workspace-support',
          'Keep my unsent Store enquiry',
        );
        final store = work.activeWorkspace!.id;
        final invoiceCount = work.workspaceInvoices.length;
        WorkspaceGroupOffer offer(
          int index, {
          int revision = 1,
          String? scopeStore,
          String account = 'review-draft-account',
        }) => WorkspaceGroupOffer(
          accountScope: account,
          workspaceId: scopeStore ?? store,
          supplierId: 'supplier-$index',
          supplierName: [
            'Jodhpur Mandi',
            'Marwar Wholesale',
            'Factory Direct',
            'Market Wholesale',
          ][index],
          supplierType: [
            WorkspaceStockSupplierType.mandi,
            WorkspaceStockSupplierType.wholesaler,
            WorkspaceStockSupplierType.manufacturer,
            WorkspaceStockSupplierType.wholesaler,
          ][index],
          productId: 'product-$index',
          revision: revision,
          updatedAt: DateTime.utc(2026, 9, 10, 12, 0, revision),
          closingAt: DateTime.utc(2026, 9, 12),
          stage: index == 3
              ? WorkspaceGroupOfferStage.cancelled
              : WorkspaceGroupOfferStage.secured,
          publicationConfirmed: true,
          participation: index == 0
              ? const WorkspaceGroupParticipation(
                  state: WorkspaceGroupParticipationState.notJoined,
                )
              : const WorkspaceGroupParticipation(
                  state: WorkspaceGroupParticipationState.balanceDue,
                  quantity: 10,
                  goodsMinor: 14000,
                  tradeFeeMinor: 500,
                  deliveryMinor: 0,
                  taxMinor: 0,
                  totalMinor: 14500,
                  referenceMinor: 18000,
                  paidMinor: 5000,
                  dueMinor: 9500,
                ),
          details: WorkspaceGroupBuy(
            id: 'offer-$index',
            productName: [
              'Red onions',
              'Premium rice',
              'Whole wheat atta',
              'Cooking oil',
            ][index],
            specification: index == 3
                ? 'Refined oil · sealed 5 kg tins'
                : 'Grade A · sealed 5 kg bags',
            leadRetailer: 'Shree Grocery',
            confirmedRetailers: const ['Shree Grocery'],
            targetQuantity: 1000,
            securedQuantity: 300,
            unitLabel: 'kg',
            regularUnitPrice: 18,
            groupUnitPrice: 14,
            facilitationFee: 600,
            deliveryFee: 200,
            confirmationAmount: 3000,
            closingLabel: '12 Sep',
            storeDeliveryLabel: '14 Sep',
            paymentConfirmed: true,
            participants: const [
              WorkspaceGroupBuyParticipant(
                businessName: 'Shree Grocery',
                locality: 'Market road',
                quantity: 50,
                unitLabel: 'kg',
                milestone: 'Confirmed',
              ),
            ],
          ),
        );
        bool apply(int revision, List<WorkspaceGroupOffer> offers) =>
            work.applyWorkspaceGroupOffers(
              accountScope: 'review-draft-account',
              storeId: store,
              feedRevision: revision,
              records: offers,
              complete: true,
            );
        expect(apply(1, [for (var i = 0; i < 4; i++) offer(i)]), isTrue);
        final selectedCustomerOrder = work.currentWorkspaceOrderId;
        work.workspacePackedProductIds.add('summary-0');
        final packedBefore = work.workspacePackedProductIds.toSet();
        final now = DateTime.now();
        for (var i = 1; i < activeOrders; i++) {
          final slot = i % 100;
          final collection = slot >= 50 && slot < 65;
          work.workspaceOrders.add(
            WorkspaceOrderRecord(
              id: 'MIX-$i',
              customer: 'Customer $i',
              items: 'Fortune Sunflower Oil × 1',
              quantities: const {'oil-fortune-1l': 1},
              amount: 264,
              source: 'App',
              fulfilment: collection ? 'Collect at store' : 'Mool delivery',
              payment: 'Paid online',
              address: collection ? '' : 'Test delivery address $i',
              needsDelivery: !collection,
              collectionStoreId: collection ? store : null,
              createdAt: now,
              stage: slot < 30
                  ? 'Confirmed'
                  : slot < 50
                  ? 'Preparing'
                  : slot < 60
                  ? 'Ready for collection'
                  : slot < 65
                  ? 'Customer confirmed'
                  : slot < 80
                  ? 'Ready'
                  : slot < 95
                  ? 'Out for delivery'
                  : 'Delivery failed',
            ),
          );
        }
        final customerStates = work.workspaceOrders
            .map((order) => (order.id, order.stage, order.payment))
            .toList();
        WorkspacePurchaseRecord incoming(int i, int revision) =>
            WorkspacePurchaseRecord(
              accountScope: 'review-draft-account',
              workspaceId: store,
              supplierId: 'wholesaler-$i',
              supplierName: 'Wholesale supplier $i',
              orderId: 'PO-MIX-$i',
              shipmentId: 'SHIP-MIX-$i',
              revision: revision,
              createdAt: now,
              updatedAt: now.add(Duration(seconds: revision)),
              stage: revision > 1 && i == 7
                  ? WorkspaceSupplyStage.delayed
                  : WorkspaceSupplyStage.dispatched,
              amountMinor: 550000,
              itemSummary: 'Sunflower oil · 1 l × 100 packs',
              paymentLabel: 'Paid online',
              expectedArrival: revision > 1 && i == 7
                  ? 'Updated arrival awaited'
                  : 'Tomorrow, 10 am–12 pm',
              lines: [
                WorkspacePurchaseLine(
                  id: 'LINE-MIX-$i',
                  productId: 'oil-fortune-1l',
                  name: 'Sunflower oil',
                  pack: '1 l',
                  orderedPacks: 100,
                  unitPriceMinor: 5500,
                ),
              ],
            );
        bool applyIncoming(int revision) => work.applyWorkspacePurchases(
          accountScope: 'review-draft-account',
          storeId: store,
          feedRevision: revision,
          records: [for (var i = 0; i < 8; i++) incoming(i, revision)],
          complete: true,
        );
        WorkspaceFinanceSnapshot finance(int revision) =>
            WorkspaceFinanceSnapshot(
              accountScope: 'review-draft-account',
              workspaceId: store,
              revision: revision,
              asOf: now.add(Duration(seconds: revision)),
              salesTodayMinor: 146800,
              duesMinor: 0,
              availableMinor: 500000,
              heldMinor: 20000,
              requestedMinor: revision == 1 ? 100000 : 0,
              paidOutMinor: revision == 1 ? 0 : 100000,
              feesMinor: 0,
              deliveryAdjustmentsMinor: 0,
              refundsMinor: 0,
              taxWithheldMinor: 0,
              payments: const [],
              payouts: [
                for (var i = 0; i < 2; i++)
                  WorkspacePayoutRecord(
                    id: 'SET-MIX-$i',
                    operationId: 'SET-OP-MIX-$i',
                    revision: revision,
                    amountMinor: 50000,
                    updatedAt: now.add(Duration(seconds: revision)),
                    state: revision == 1
                        ? WorkspacePayoutState.processing
                        : WorkspacePayoutState.paid,
                  ),
              ],
            );
        expect(applyIncoming(1), isTrue);
        expect(work.applyWorkspaceFinance(finance(1)), isTrue);
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          chat: chat,
          viewport: viewport,
          textScale: scale,
        );
        expect(
          work.visibleWorkspaceOrders.where((order) => !order.isClosed),
          hasLength(activeOrders),
        );
        for (final (stage, count) in [
          ('Confirmed', 30),
          ('Preparing', 20),
          ('Ready for collection', 10),
          ('Customer confirmed', 5),
          ('Ready', 15),
          ('Out for delivery', 15),
          ('Delivery failed', 5),
        ]) {
          expect(
            work.visibleWorkspaceOrders.where((order) => order.stage == stage),
            hasLength(count * (activeOrders ~/ 100)),
          );
        }
        final claimedCollections = work.visibleWorkspaceOrders.where(
          (order) =>
              order.isCustomerCollection && order.stage == 'Customer confirmed',
        );
        expect(claimedCollections, hasLength(5 * (activeOrders ~/ 100)));
        for (final order in claimedCollections) {
          expect(work.workspaceOrderStageLabel(order), 'Checking order');
        }
        expect(work.currentCollection, isNull);
        expect(
          find.text(
            '${30 * (activeOrders ~/ 100)}\nCheck pickup',
            findRichText: true,
          ),
          findsOneWidget,
        );
        expect(
          work.visibleWorkspaceOrders
              .where((order) => order.isClosed)
              .map((order) => order.id),
          ['SALE-1042'],
        );
        expect(work.workspacePurchases, hasLength(8));
        expect(work.workspaceFinance!.payouts, hasLength(2));
        expect(work.workspaceGroupOffers, hasLength(4));
        expect(work.currentWorkspaceOrderId, selectedCustomerOrder);
        if (editing) {
          void updateOtherWork(int revision) {
            work.workspaceOrders.add(
              customerOrder(
                id: 'ARRIVAL-$revision',
                customer: 'New customer $revision',
                createdAt: now,
                stage: 'Confirmed',
              ),
            );
            expect(applyIncoming(revision), isTrue);
            expect(work.applyWorkspaceFinance(finance(revision)), isTrue);
            expect(
              apply(revision, [
                for (var i = 0; i < 4; i++) offer(i, revision: revision),
              ]),
              isTrue,
            );
          }

          final arrivals = find.byKey(const Key('work-incoming-purchases'));
          await reveal(tester, arrivals);
          await tester.tap(arrivals);
          await tester.pumpAndSettle();
          final supplier = find.text('Wholesale supplier 0');
          await reveal(tester, supplier);
          await tester.tap(supplier);
          await tester.pumpAndSettle();
          final receive = find.byKey(const Key('work-receipt-start'));
          await reveal(tester, receive);
          await tester.tap(receive);
          await tester.pumpAndSettle();
          final count = find.byKey(const Key('work-receipt-count-LINE-MIX-0'));
          await reveal(tester, count);
          await tester.enterText(count, '97');
          await tester.pumpAndSettle();
          final note = find.byWidgetPredicate(
            (widget) =>
                widget is TextField &&
                widget.decoration?.labelText == 'Delivery note',
          );
          await reveal(tester, note);
          await tester.enterText(note, 'Three packs need checking');
          const receiptValue = TextEditingValue(
            text: 'Three packs need checking',
            selection: TextSelection.collapsed(offset: 11),
            composing: TextRange(start: 6, end: 11),
          );
          tester.testTextInput.updateEditingValue(receiptValue);
          tester.view.viewInsets = const FakeViewPadding(bottom: 220);
          await tester.pumpAndSettle();
          await tester.ensureVisible(note);
          final receiptEditable = find.descendant(
            of: note,
            matching: find.byType(EditableText),
          );
          final receiptController = tester
              .widget<EditableText>(receiptEditable)
              .controller;
          final beforeReceiving = work.workspaceReceiptDraft(incoming(0, 1))!;
          expect(beforeReceiving.countedPacks['LINE-MIX-0'], '97');
          expect(beforeReceiving.note, receiptValue.text);
          updateOtherWork(2);
          await tester.pumpAndSettle();
          expect(work.focusedWorkspacePurchaseId, 'SHIP-MIX-0');
          expect(work.currentWorkspaceOrderId, selectedCustomerOrder);
          final afterReceiving = work.workspaceReceiptDraft(incoming(0, 2))!;
          expect(
            afterReceiving.shipmentRevision,
            beforeReceiving.shipmentRevision,
          );
          expect(afterReceiving.countedPacks, beforeReceiving.countedPacks);
          expect(afterReceiving.note, receiptValue.text);
          final liveReceipt = tester.widget<EditableText>(receiptEditable);
          expect(liveReceipt.controller, same(receiptController));
          expect(liveReceipt.controller.value, receiptValue);
          expect(liveReceipt.focusNode.hasFocus, isTrue);
          expect(work.workspaceOrders.length, customerStates.length + 1);
          expect(work.workspacePurchases, hasLength(8));
          expect(work.workspaceGroupOffers, hasLength(4));
          expect(work.workspaceFinance!.payouts, hasLength(2));
          expect(work.workspaceInvoices.length, invoiceCount);
          expect(tester.takeException(), isNull);
          await captureStoreView(
            tester,
            'mixed-receiving-editor-$stockViewSuffix',
          );
          tester.testTextInput.hide();
          tester.view.resetViewInsets();
          await tester.pumpAndSettle();
          final closeReceipt = find.byKey(const Key('work-receipt-close'));
          final purchaseList = find.byKey(
            PageStorageKey('work-purchase-details-$store-SHIP-MIX-0-false'),
          );
          for (
            var attempt = 0;
            attempt < 24 && closeReceipt.hitTestable().evaluate().isEmpty;
            attempt++
          ) {
            await tester.drag(purchaseList, const Offset(0, 240));
            await tester.pumpAndSettle();
          }
          expect(closeReceipt.hitTestable(), findsOneWidget);
          await tester.tap(closeReceipt);
          await tester.pumpAndSettle();
          expect(
            work.workspaceReceiptDraft(incoming(0, 2))!.note,
            receiptValue.text,
          );
          expect(work.focusedWorkspacePurchaseId, 'SHIP-MIX-0');
          expect(tester.takeException(), isNull);
          await tester.tap(find.byKey(const Key('work-store-home')));
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('work-store-sell')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('work-sale-customer')));
          await tester.pumpAndSettle();
          final customerField = find.byKey(const Key('work-order-customer'));
          await tester.enterText(customerField, '9000000013');
          const customerValue = TextEditingValue(
            text: '9000000013',
            selection: TextSelection.collapsed(offset: 4),
            composing: TextRange(start: 0, end: 4),
          );
          tester.testTextInput.updateEditingValue(customerValue);
          tester.view.viewInsets = const FakeViewPadding(bottom: 220);
          await tester.pumpAndSettle();
          final customerEditable = find.descendant(
            of: customerField,
            matching: find.byType(EditableText),
          );
          final customerController = tester
              .widget<EditableText>(customerEditable)
              .controller;
          updateOtherWork(3);
          await tester.pumpAndSettle();
          expect(
            tester.widget<EditableText>(customerEditable).controller,
            same(customerController),
          );
          expect(customerController.value, customerValue);
          expect(
            tester.widget<EditableText>(customerEditable).focusNode.hasFocus,
            isTrue,
          );
          expect(work.workspaceInvoices, hasLength(invoiceCount));
          expect(work.workspaceStockMovements, isEmpty);
          if (scale > 1.5) {
            final title = find.byKey(const Key('work-sale-customer-title'));
            final label = find.byKey(const Key('work-order-customer-label'));
            expect(label, findsOneWidget);
            expect(
              tester.getRect(label).top,
              greaterThanOrEqualTo(tester.getRect(title).bottom),
              reason: 'Enlarged mobile label must not overlap the sheet title',
            );
            expect(
              tester.getRect(customerField).top,
              greaterThanOrEqualTo(tester.getRect(label).bottom + 8),
            );
          }
          await captureStoreView(
            tester,
            'mixed-counter-editor-$stockViewSuffix',
          );
          FocusManager.instance.primaryFocus?.unfocus();
          tester.view.viewInsets = const FakeViewPadding();
          await tester.pumpAndSettle();
          final confirmCustomer = find.byKey(
            const Key('work-sale-customer-confirm'),
          );
          await reveal(tester, confirmCustomer);
          expect(confirmCustomer.hitTestable(), findsOneWidget);
          expect(
            tester.getSize(confirmCustomer).height,
            greaterThanOrEqualTo(48),
          );
          await tester.tap(confirmCustomer);
          await tester.pumpAndSettle();
          expect(work.workspaceOrderCustomer, customerValue.text);
          final add = find.byKey(const Key('work-order-add-oil-fortune-1l'));
          await reveal(tester, add);
          await tester.tap(add);
          await tester.pumpAndSettle();
          final billItems = Map<String, int>.of(work.workspaceOrderQuantities);
          final billTotal = work.workspaceOrderTotal;
          final router = GoRouter.of(
            tester.element(find.byType(WorkWorkspaceDashboardScreen)),
          );
          router.push<void>(
            Uri(
              path: '/app/chat/thread/workspace-support',
              queryParameters: {
                'return': '/app/work/workspace/dashboard',
                'directReturn': 'true',
              },
            ).toString(),
          );
          await tester.pumpAndSettle();
          final message = find.byKey(const Key('chat-message-field'));
          await tester.enterText(message, 'Please check my supplier delivery.');
          const messageValue = TextEditingValue(
            text: 'Please check my supplier delivery.',
            selection: TextSelection.collapsed(offset: 8),
            composing: TextRange(start: 7, end: 12),
          );
          tester.testTextInput.updateEditingValue(messageValue);
          tester.view.viewInsets = const FakeViewPadding(bottom: 220);
          await tester.pumpAndSettle();
          final messageEditable = find.descendant(
            of: message,
            matching: find.byType(EditableText),
          );
          final messageController = tester
              .widget<EditableText>(messageEditable)
              .controller;
          expect(
            messageController.value,
            messageValue,
            reason: 'Valid IME composition is present before Store updates',
          );
          updateOtherWork(4);
          await tester.pumpAndSettle();
          expect(
            tester.widget<EditableText>(messageEditable).controller,
            same(messageController),
          );
          expect(messageController.value, messageValue);
          expect(
            tester.widget<EditableText>(messageEditable).focusNode.hasFocus,
            isTrue,
          );
          expect(
            chat.draftTextForSession('workspace-support'),
            messageValue.text,
          );
          expect(work.workspaceOrderCustomer, customerValue.text);
          expect(work.workspaceOrderQuantities, billItems);
          expect(work.workspaceOrderTotal, billTotal);
          expect(work.workspaceInvoices, hasLength(invoiceCount));
          expect(work.workspaceStockMovements, isEmpty);
          expect(work.workspaceOrders.length, customerStates.length + 3);
          await captureStoreView(tester, 'mixed-chat-editor-$stockViewSuffix');
          FocusManager.instance.primaryFocus?.unfocus();
          tester.view.viewInsets = const FakeViewPadding();
          await tester.pumpAndSettle();
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('work-dashboard-counter-order-screen')),
            findsOneWidget,
          );
          expect(work.workspaceOrderQuantities, billItems);
          expect(work.workspaceOrderTotal, billTotal);
          expect(work.workspaceOrderCustomer, customerValue.text);
          expect(
            chat.draftTextForSession('workspace-support'),
            messageValue.text,
          );
          expect(tester.takeException(), isNull);
          await captureStoreView(
            tester,
            'mixed-counter-return-$stockViewSuffix',
          );
          return;
        }
        await captureStoreView(
          tester,
          'group-mixed-dashboard-$stockViewSuffix',
        );
        final accept = find.byKey(const Key('work-activity-order-accept'));
        await reveal(tester, accept);
        expect(accept.hitTestable(), findsOneWidget);
        expect(tester.getSize(accept).height, greaterThanOrEqualTo(48));
        expect(work.currentWorkspaceOrderId, selectedCustomerOrder);
        await captureStoreView(
          tester,
          'group-mixed-central-action-$stockViewSuffix',
        );
        await tester.ensureVisible(
          find.byKey(const Key('work-quick-group-buy')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('work-quick-group-buy')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('work-group-offers-view')), findsOneWidget);
        await captureStoreView(tester, 'group-offers-first-$stockViewSuffix');
        await tester.tap(find.byKey(const Key('work-group-offer-switch')));
        await tester.pumpAndSettle();
        await captureStoreView(
          tester,
          'group-offers-selector-$stockViewSuffix',
        );
        final choice = find.byKey(const Key('work-group-choose-offer-1'));
        await reveal(tester, choice);
        await tester.tap(choice);
        await tester.pumpAndSettle();
        expect(work.selectedWorkspaceGroupOfferId, 'offer-1');
        expect(find.text('Marwar Wholesale · Wholesaler'), findsOneWidget);
        final switcherBefore = tester.getRect(
          find.byKey(const Key('work-group-offer-switch')),
        );
        final heldTouch = await tester.startGesture(switcherBefore.center);
        expect(applyIncoming(2), isTrue);
        expect(work.applyWorkspaceFinance(finance(2)), isTrue);
        expect(applyIncoming(1), isFalse);
        expect(work.applyWorkspaceFinance(finance(1)), isFalse);
        expect(applyIncoming(2), isFalse);
        expect(work.applyWorkspaceFinance(finance(2)), isFalse);
        await tester.pumpAndSettle();
        expect(work.selectedWorkspaceGroupOfferId, 'offer-1');
        expect(work.currentWorkspaceOrderId, selectedCustomerOrder);
        expect(work.workspacePackedProductIds, unorderedEquals(packedBefore));
        expect(
          work.workspaceOrders
              .map((order) => (order.id, order.stage, order.payment))
              .toList(),
          customerStates,
        );
        expect(work.workspaceFinance!.salesTodayMinor, 146800);
        expect(work.workspaceFinance!.paidOutMinor, 100000);
        expect(work.workspaceFinance!.payouts, hasLength(2));
        expect(work.workspacePurchases, hasLength(8));
        expect(
          work.workspacePurchases
              .singleWhere((purchase) => purchase.shipmentId == 'SHIP-MIX-7')
              .stage,
          WorkspaceSupplyStage.delayed,
        );
        expect(work.workspaceInvoices, hasLength(invoiceCount));
        expect(work.workspaceStockMovements, isEmpty);
        expect(
          chat.draftTextForSession('workspace-support'),
          'Keep my unsent Store enquiry',
        );
        expect(
          tester.getRect(find.byKey(const Key('work-group-offer-switch'))),
          switcherBefore,
        );
        await heldTouch.cancel();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-group-choose-offer-1')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
        await captureStoreView(tester, 'group-mixed-updates-$stockViewSuffix');
        expect(
          apply(2, [offer(3, revision: 2), offer(2), offer(1), offer(0)]),
          isTrue,
        );
        await tester.pumpAndSettle();
        expect(work.selectedWorkspaceGroupOfferId, 'offer-1');
        await captureStoreView(
          tester,
          'group-offers-selected-$stockViewSuffix',
        );
        final total = find.byKey(const ValueKey('work-group-value-Your total'));
        await reveal(tester, total);
        expect(
          find.descendant(of: total, matching: find.text('₹145')),
          findsOneWidget,
        );
        final pay = find.widgetWithText(FilledButton, 'Pay balance');
        await reveal(tester, pay);
        expect(tester.widget<FilledButton>(pay).onPressed, isNull);
        await captureStoreView(tester, 'group-offers-cost-$stockViewSuffix');
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(const Key('work-quick-group-buy')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('work-quick-group-buy')));
        await tester.pumpAndSettle();
        expect(work.selectedWorkspaceGroupOfferId, 'offer-1');
        work.markWorkspaceGroupOffersStale(
          accountScope: 'review-draft-account',
          storeId: store,
        );
        await tester.pumpAndSettle();
        tester
            .state<ScrollableState>(
              find
                  .descendant(
                    of: find.byKey(const Key('work-group-offers-view')),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            )
            .position
            .jumpTo(0);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-group-offers-stale')),
          findsOneWidget,
        );
        await captureStoreView(tester, 'group-offers-stale-$stockViewSuffix');
        expect(apply(3, [offer(0), offer(2), offer(3, revision: 2)]), isTrue);
        await tester.pumpAndSettle();
        expect(work.selectedWorkspaceGroupOfferId, 'offer-1');
        expect(find.text('This offer is no longer available'), findsOneWidget);
        await captureStoreView(tester, 'group-offers-removed-$stockViewSuffix');
        await tester.tap(find.byKey(const Key('work-group-offer-switch')));
        await tester.pumpAndSettle();
        final cancelledChoice = find.byKey(
          const Key('work-group-choose-offer-3'),
        );
        await reveal(tester, cancelledChoice);
        await tester.tap(cancelledChoice);
        await tester.pumpAndSettle();
        final cancelledList = tester.widget<ListView>(
          find.byKey(const PageStorageKey('work-group-details-offer-3')),
        );
        final cancelledChildren =
            (cancelledList.childrenDelegate as SliverChildListDelegate)
                .children;
        expect(
          (cancelledChildren.singleWhere(
                    (child) => child.key == const Key('work-group-your-state'),
                  )
                  as Text)
              .data,
          'Your recorded payment',
        );
        expect(
          cancelledChildren.any(
            (child) => child.key == const Key('work-group-payment-action'),
          ),
          isFalse,
        );
        await captureStoreView(
          tester,
          'group-offers-cancelled-$stockViewSuffix',
        );
        final previousDelivery = find.byKey(
          const ValueKey('work-group-value-Previous delivery estimate'),
        );
        await reveal(tester, previousDelivery);
        expect(
          find.descendant(of: previousDelivery, matching: find.text('14 Sep')),
          findsOneWidget,
        );
        final recordedBalance = find.byKey(
          const ValueKey('work-group-value-Previously outstanding'),
        );
        await reveal(tester, recordedBalance);
        expect(
          find.descendant(of: recordedBalance, matching: find.text('₹95')),
          findsOneWidget,
        );
        await captureStoreView(
          tester,
          'group-offers-cancelled-payment-$stockViewSuffix',
        );
        expect(apply(4, []), isTrue);
        await tester.pumpAndSettle();
        expect(find.text('No group offers available'), findsOneWidget);
        final emptyScroll = tester.state<ScrollableState>(
          find.descendant(
            of: find.byKey(
              const PageStorageKey('work-group-details-offer-3-unavailable'),
            ),
            matching: find.byType(Scrollable),
          ),
        );
        expect(emptyScroll.position.pixels, 0);
        await captureStoreView(tester, 'group-offers-empty-$stockViewSuffix');
        expect(work.workspaceInvoices.length, invoiceCount);
        expect(
          apply(5, [offer(0, revision: 2), offer(1, revision: 2)]),
          isTrue,
        );
        await tester.pumpAndSettle();
        for (final change in ['account', 'store']) {
          await tester.tap(find.byKey(const Key('work-group-offer-switch')));
          await tester.pumpAndSettle();
          final retainedChoice = tester
              .widget<ListTile>(
                find.byKey(const Key('work-group-choose-offer-1')),
              )
              .onTap!;
          if (change == 'account') {
            contact.accountScope = 'replacement-account';
          } else {
            work.activeWorkspace = const WorkWorkspace(
              id: 'replacement-store',
              name: 'Second Store',
              profileId: 'retailer-grocery',
              profileLabel: 'Grocery',
              area: 'Market',
              verified: true,
            );
          }
          final newStore = work.activeWorkspace!.id;
          expect(
            work.applyWorkspaceGroupOffers(
              accountScope: contact.accountScope,
              storeId: newStore,
              feedRevision: 1,
              records: [
                for (var i = 0; i < 2; i++)
                  offer(i, scopeStore: newStore, account: contact.accountScope),
              ],
              complete: true,
            ),
            isTrue,
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('work-group-chooser-scope-changed')),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: find.byKey(const Key('work-group-offer-choices')),
              matching: find.byType(ListTile),
            ),
            findsNothing,
          );
          retainedChoice();
          await tester.pumpAndSettle();
          expect(work.selectedWorkspaceGroupOfferId, 'offer-0');
          expect(
            find.byKey(const Key('work-group-chooser-scope-changed')),
            findsOneWidget,
          );
          await captureStoreView(
            tester,
            'group-chooser-$change-changed-$stockViewSuffix',
          );
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('work-group-chooser-scope-changed')),
            findsNothing,
          );
          expect(tester.takeException(), isNull);
        }
        expect(tester.takeException(), isNull);
      },
    );
    // The larger active-order dimension belongs to the mixed-workload replay,
    // not these stock-history scenarios, which retain their three viewports.
    if (activeOrders != 100 || editing) continue;

    testWidgets(
      'DASH10 stock changes retain filters references and Back $stockViewSuffix',
      (tester) async {
        final work = storeViewFixture();
        final now = DateTime.now();
        work.workspaceStockMovements.addAll(
          List.generate(
            121,
            (i) => WorkspaceStockMovement(
              id: 'history-$i',
              productId: 'oil-fortune-1l',
              productLabel: 'Fortune Sunflower Oil · 1 L',
              kind: WorkspaceStockMovementKind.reserved,
              quantityDelta: -2,
              reason: 'Customer order reservation',
              occurredAt: now.subtract(Duration(minutes: i)),
              referenceKind: WorkspaceStockReferenceKind.order,
              referenceId: 'APP-1043',
            ),
          ),
        );
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: viewport,
          textScale: scale,
        );
        await tester.tap(find.byKey(const Key('work-store-stock')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('work-catalogue-stock-statement')),
        );
        await tester.pumpAndSettle();
        await captureStoreView(tester, 'stock-position-$stockViewSuffix');
        await tester.ensureVisible(
          find.byKey(const Key('work-stock-position-oil-fortune-1l')),
        );
        await tester.pumpAndSettle();
        expect(
          find
              .byKey(const Key('work-stock-position-oil-fortune-1l'))
              .hitTestable(),
          findsOneWidget,
        );
        await tester.tap(
          find.byKey(const Key('work-stock-position-oil-fortune-1l')),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-stock-history-product-filter')),
          findsOneWidget,
        );
        final productLabel = find.descendant(
          of: find.byKey(const Key('work-stock-history-product-filter')),
          matching: find.text('Fortune Sunflower Oil'),
        );
        final labelParagraph = tester.renderObject<RenderParagraph>(
          productLabel,
        );
        expect(labelParagraph.maxLines, isNull);
        expect(labelParagraph.softWrap, isTrue);
        expect(labelParagraph.didExceedMaxLines, isFalse);
        expect(labelParagraph.text.style?.fontFamily, 'Inter');
        expect(find.text('On this device · 121 changes'), findsOneWidget);
        expect(
          find.text('Full stock history is not connected yet.'),
          findsOneWidget,
        );
        await captureStoreView(tester, 'stock-local-history-$stockViewSuffix');
        final reference = find.byKey(
          const Key('work-stock-reference-history-0'),
        );
        await reveal(tester, reference);
        final historyScroll = find
            .descendant(
              of: find.byKey(const Key('work-stock-statement-screen')),
              matching: find.byType(Scrollable),
            )
            .first;
        final referenceOffset = tester
            .state<ScrollableState>(historyScroll)
            .position
            .pixels;
        await tester.tap(reference);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-exact-order-information-APP-1043')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('work-stock-statement-screen')),
          findsNothing,
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-stock-statement-screen')),
          findsOneWidget,
        );
        expect(
          tester.state<ScrollableState>(historyScroll).position.pixels,
          closeTo(referenceOffset, .1),
        );
        tester.state<ScrollableState>(historyScroll).position.jumpTo(0);
        await tester.pumpAndSettle();
        await captureStoreView(tester, 'stock-return-filter-$stockViewSuffix');
        expect(
          find.byKey(const Key('work-stock-history-product-filter')),
          findsOneWidget,
        );
        expect(find.text('On this device · 121 changes'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.byKey(const Key('work-stock-movement-history-120')),
          500,
          scrollable: historyScroll,
          maxScrolls: 200,
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-stock-movement-history-120')),
          findsOneWidget,
        );
        final oldestReference = find.byKey(
          const Key('work-stock-reference-history-120'),
        );
        await reveal(tester, oldestReference);
        expect(oldestReference.hitTestable(), findsOneWidget);
        await captureStoreView(tester, 'stock-oldest-local-$stockViewSuffix');
        final before = tester
            .state<ScrollableState>(historyScroll)
            .position
            .pixels;
        work.updateWorkspaceStock(
          productId: 'oil-fortune-1l',
          quantity: 70,
          reason: 'Counted in store',
        );
        await tester.pumpAndSettle();
        expect(
          tester.state<ScrollableState>(historyScroll).position.pixels,
          before,
        );
        expect(
          find.byKey(const Key('work-stock-movement-history-120')),
          findsOneWidget,
        );
        tester.state<ScrollableState>(historyScroll).position.jumpTo(0);
        await tester.pumpAndSettle();
        await reveal(
          tester,
          find.byKey(const Key('work-stock-history-refresh')),
        );
        expect(
          find.byKey(const Key('work-stock-history-refresh')).hitTestable(),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('work-stock-history-refresh')));
        await tester.pumpAndSettle();
        expect(find.text('On this device · 122 changes'), findsOneWidget);
        await reveal(tester, find.byKey(const Key('work-stock-history-dates')));
        expect(
          find.byKey(const Key('work-stock-history-dates')).hitTestable(),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('work-stock-history-dates')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Today').last);
        await tester.pumpAndSettle();
        expect(
          tester
              .getSize(find.byKey(const Key('work-stock-history-dates')))
              .height,
          greaterThanOrEqualTo(48),
        );
        await captureStoreView(tester, 'stock-date-filter-$stockViewSuffix');
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'DASH10 stock history older pages retry and return fit $stockViewSuffix',
      (tester) async {
        final gateway = _StockHistoryFixtureGateway();
        final work = storeViewFixture(
          null,
          _ContactDraftFixtureStore(),
          null,
          null,
          null,
          gateway,
        );
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: viewport,
          textScale: scale,
        );
        await tester.tap(find.byKey(const Key('work-store-stock')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('work-catalogue-stock-statement')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Changes'));
        await tester.pumpAndSettle();
        expect(work.workspaceStockHistory.length, 50);
        expect(find.text('50 of 101 changes'), findsOneWidget);
        await captureStoreView(tester, 'stock-server-history-$stockViewSuffix');
        final scroll = find
            .descendant(
              of: find.byKey(const Key('work-stock-statement-screen')),
              matching: find.byType(Scrollable),
            )
            .first;
        final more = find.byKey(const Key('work-stock-history-more'));
        await tester.scrollUntilVisible(
          more,
          600,
          scrollable: scroll,
          maxScrolls: 150,
        );
        await tester.pumpAndSettle();
        gateway.failNext = true;
        await tester.tap(more);
        await tester.pumpAndSettle();
        expect(work.workspaceStockHistory.length, 50);
        final retry = find.byKey(const Key('work-stock-history-retry'));
        await tester.ensureVisible(retry);
        await tester.pumpAndSettle();
        await captureStoreView(tester, 'stock-history-retry-$stockViewSuffix');
        await tester.tap(retry);
        await tester.pumpAndSettle();
        expect(work.workspaceStockHistory.length, 100);
        await tester.scrollUntilVisible(
          more,
          600,
          scrollable: scroll,
          maxScrolls: 150,
        );
        await tester.pumpAndSettle();
        await tester.tap(more);
        await tester.pumpAndSettle();
        expect(work.workspaceStockHistory.length, 101);
        expect(work.workspaceStockHistoryHasMore, isFalse);
        expect(gateway.cursors, [null, '50', '50', '100']);
        expect(work.workspaceStockMovements, isEmpty);
        expect(work.workspaceInvoices, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('DASH10 five thousand stock products are built lazily', (
    tester,
  ) async {
    final work = liveStore();
    for (var i = 1; i <= 5000; i++) {
      work.workspaceCatalogueItems.add(catalogueProduct(i));
    }
    await mount(
      tester,
      route: '/app/work/workspace/dashboard',
      work: work,
      viewport: const Size(412, 915),
      textScale: 1,
    );
    await tester.tap(find.byKey(const Key('work-store-stock')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-catalogue-stock-statement')));
    await tester.pumpAndSettle();
    final mounted = find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>).value.startsWith(
            'work-stock-position-',
          ),
    );
    expect(mounted.evaluate().length, lessThan(30));
    expect(mounted.evaluate().length, greaterThan(0));
    expect(work.workspaceCatalogueItems.length, 5001);
    final firstBefore = tester.getTopLeft(
      find.byKey(const Key('work-stock-position-oil-fortune-1l')),
    );
    final changed = work.workspaceCatalogueItems.indexWhere(
      (product) => product.id == catalogueProduct(1).id,
    );
    expect(changed, greaterThanOrEqualTo(0));
    work.workspaceCatalogueItems[changed] = work
        .workspaceCatalogueItems[changed]
        .copyWith(stock: 0, available: false);
    work.notifyListeners();
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(
        find.byKey(const Key('work-stock-position-oil-fortune-1l')),
      ),
      firstBefore,
    );
    expect(tester.takeException(), isNull);
    await captureStoreView(tester, 'stock-five-thousand-products');
  });

  for (final (scale, viewport) in [
    (1.0, const Size(412, 915)),
    (2.0, const Size(320, 568)),
  ]) {
    testWidgets('DASH10 restock search retains product cart and Back $scale', (
      tester,
    ) async {
      final work = liveStore();
      work.addOrUpdateWorkspaceProduct(workspaceMasterCatalogue.first);
      expect(
        work.updateWorkspaceStock(
          productId: 'oil-fortune-1l',
          quantity: 3,
          reason: 'Counted in store',
        ),
        isTrue,
      );
      work.workspaceCatalogueItems.add(catalogueProduct(3, stock: 2));
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: viewport,
        textScale: scale,
      );
      final buy = tester
          .widget<WorkWorkspaceDashboardScreen>(
            find.byType(WorkWorkspaceDashboardScreen),
          )
          .procurementSession;
      buy.openDestination(BuyV2Destination.wholesale);
      final cartProduct = buy.visibleProducts.first;
      expect(buy.addProduct(cartProduct.id), isTrue);
      final cartQuantity = buy.quantityFor(cartProduct.id);
      buy.chooseFilter('nearby');
      buy.updateQuery('previous purchase search');
      await tester.tap(find.byKey(const Key('work-store-stock')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('work-catalogue-stock-statement')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('work-stock-statement-screen')),
        findsOneWidget,
      );
      final oilRow = find.byKey(
        const Key('work-stock-position-oil-fortune-1l'),
      );
      await reveal(tester, oilRow);
      expect(
        find.descendant(
          of: oilRow,
          matching: find.textContaining('3 available'),
        ),
        findsOneWidget,
      );
      final oilRestock = find.byKey(
        const Key('work-stock-restock-oil-fortune-1l'),
      );
      await reveal(tester, oilRestock);
      await tester.tap(oilRestock);
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-store-procurement-screen')),
        findsOneWidget,
      );
      const oilQuery = 'Fortune Sunflower Oil 1 L pouch';
      expect(find.text('Wholesale and Bulk'), findsNothing);
      final storeName = find.byKey(const Key('work-procurement-store-name'));
      expect(tester.widget<Text>(storeName).data, work.activeWorkspace!.name);
      expect(tester.widget<Text>(storeName).maxLines, isNull);
      expect(tester.widget<Text>(storeName).textScaler!.scale(1), scale);
      expect(
        tester.renderObject<RenderParagraph>(storeName).didExceedMaxLines,
        isFalse,
      );
      expect(
        tester.widget<AppBar>(find.byType(AppBar).first).toolbarHeight,
        closeTo(
          (tester.getSize(storeName).height + 16).clamp(48.0, double.infinity),
          1,
        ),
        reason:
            'The Store header must fit its actual text without empty height. '
            'Size=${tester.getSize(storeName)}; '
            'widget=${tester.widget<Text>(storeName).style}; '
            'rendered=${tester.renderObject<RenderParagraph>(storeName).text.style}',
      );
      expect(
        tester.getSize(find.byKey(const Key('work-back'))).height,
        greaterThanOrEqualTo(48),
      );
      expect(buy.query, oilQuery);
      expect(buy.destination, BuyV2Destination.wholesale);
      expect(buy.selectedFilter, 'nearby');
      expect(buy.quantityFor(cartProduct.id), cartQuantity);
      final searchControl = find.byKey(const ValueKey('buy-search-control'));
      expect(
        find.descendant(of: searchControl, matching: find.text(oilQuery)),
        findsOneWidget,
      );
      await captureStoreView(tester, 'restock-product-search-$scale');
      expect(tester.takeException(), isNull);
      await tester.tap(searchControl);
      await tester.pumpAndSettle();
      final search = find.byKey(const ValueKey('buy-search-field'));
      expect(tester.widget<TextField>(search).controller!.text, oilQuery);
      await tester.enterText(search, 'sunflower oil');
      tester.view.viewInsets = const FakeViewPadding(bottom: 220);
      await tester.pumpAndSettle();
      expect(buy.query, 'sunflower oil');
      expect(buy.quantityFor(cartProduct.id), cartQuantity);
      expect(find.byKey(const Key('work-local-navigation')), findsNothing);
      expect(tester.takeException(), isNull);
      await captureStoreView(tester, 'restock-search-keyboard-$scale');
      tester.view.viewInsets = FakeViewPadding.zero;
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('work-back')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-stock-statement-screen')),
        findsOneWidget,
      );
      expect(buy.query, 'sunflower oil');
      final secondRestock = find.byKey(
        const Key('work-stock-restock-store-product-3'),
      );
      expect(
        work.workspaceCatalogueItems.any(
          (item) => item.id == 'store-product-3',
        ),
        isTrue,
        reason: 'Back must preserve the second stock item.',
      );
      final stockScrollable = find.descendant(
        of: find.byKey(const Key('work-stock-statement-screen')),
        matching: find.byType(Scrollable),
      );
      expect(stockScrollable, findsOneWidget);
      // The two-unit item ranks above oil. Back retains the oil-row offset.
      await tester.scrollUntilVisible(
        secondRestock,
        -180,
        scrollable: stockScrollable,
        maxScrolls: 20,
      );
      await tester.pumpAndSettle();
      expect(secondRestock.hitTestable(), findsOneWidget);
      await tester.tap(secondRestock);
      await tester.pumpAndSettle();
      expect(buy.query, 'Store Brand Daily grocery product 3 4 kg pack');
      expect(buy.quantityFor(cartProduct.id), cartQuantity);
      expect(buy.selectedFilter, 'nearby');
      await captureStoreView(tester, 'restock-second-product-search-$scale');
      expect(tester.takeException(), isNull);
      final emptyScroll = find.byKey(
        const ValueKey('buy-empty-products-scroll'),
      );
      expect(emptyScroll, findsOneWidget);
      final clearSearch = find.descendant(
        of: emptyScroll,
        matching: find.widgetWithText(TextButton, 'Clear search'),
      );
      await tester.ensureVisible(clearSearch);
      await tester.pumpAndSettle();
      await captureStoreView(tester, 'restock-empty-revealed-$scale');
      expect(
        clearSearch.hitTestable(),
        findsOneWidget,
        reason:
            'Clear=${tester.getRect(clearSearch)}; '
            'scroll=${tester.getRect(emptyScroll)}; '
            'cart=${tester.getRect(find.byKey(const ValueKey('buy-mini-cart-drag-handle')))}',
      );
      expect(tester.getSize(clearSearch).height, greaterThanOrEqualTo(48));
      expect(
        tester.getRect(clearSearch).bottom,
        lessThanOrEqualTo(
          tester
              .getRect(find.byKey(const ValueKey('buy-mini-cart-drag-handle')))
              .top,
        ),
        reason: 'The retained cart must not cover the recovery action.',
      );
      await captureStoreView(tester, 'restock-empty-recovery-$scale');
      await tester.tap(clearSearch);
      await tester.pumpAndSettle();
      expect(buy.query, isEmpty);
      expect(buy.quantityFor(cartProduct.id), cartQuantity);
      expect(
        find.byKey(const ValueKey('buy-empty-products-scroll')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
      await captureStoreView(tester, 'restock-cleared-catalogue-$scale');
      if (scale > 1.4) {
        for (final (key, title, detail) in const [
          (
            'buy-promotion-wholesale-restock',
            'Flexible restocking',
            'Compare products with lower minimum packs',
          ),
          (
            'buy-promotion-wholesale-shop',
            'Shopping for home?',
            'Browse retail packs sized for home',
          ),
        ]) {
          final promotion = find.byKey(ValueKey(key));
          await tester.scrollUntilVisible(
            promotion,
            180,
            scrollable: find.descendant(
              of: find.byKey(
                const ValueKey('buy-enlarged-catalogue-promotions'),
              ),
              matching: find.byType(Scrollable),
            ),
          );
          await tester.pumpAndSettle();
          for (final copy in [title, detail]) {
            final label = find.descendant(
              of: promotion,
              matching: find.text(copy),
            );
            expect(label, findsOneWidget);
            expect(
              tester.renderObject<RenderParagraph>(label).didExceedMaxLines,
              isFalse,
            );
          }
          expect(promotion.hitTestable(), findsOneWidget);
          await captureStoreView(tester, 'restock-$key-$scale');
        }
        expect(buy.quantityFor(cartProduct.id), cartQuantity);
        expect(tester.takeException(), isNull);
      }
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-stock-statement-screen')),
        findsOneWidget,
      );
      expect(buy.quantityFor(cartProduct.id), cartQuantity);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'five catalogue rows remain visible in the normal Store viewport',
    (tester) async {
      final work = liveStore();
      for (var index = 1; index <= 4; index++) {
        work.workspaceCatalogueItems.add(catalogueProduct(index));
      }
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: const Size(412, 915),
        textScale: 1,
      );
      await tester.tap(find.byKey(const Key('work-store-stock')));
      await tester.pumpAndSettle();
      final fifth = find.byKey(
        const Key('work-catalogue-owned-store-product-4'),
      );
      expect(fifth, findsOneWidget);
      expect(fifth.hitTestable(), findsOneWidget);
      expect(
        tester.getBottomRight(fifth).dy,
        lessThanOrEqualTo(
          tester.getTopLeft(find.byKey(const Key('work-local-navigation'))).dy,
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );

  test('Store stock changes require a reason and balance reservations', () {
    final work = liveStore();
    addTearDown(work.dispose);
    expect(
      work.updateWorkspaceStock(
        productId: 'oil-fortune-1l',
        quantity: 10,
        reason: '',
      ),
      isFalse,
    );
    expect(work.workspaceCatalogueItems.first.stock, 8);
    expect(
      work.updateWorkspaceStock(
        productId: 'oil-fortune-1l',
        quantity: 10,
        reason: 'Goods received',
        kind: WorkspaceStockMovementKind.goodsReceived,
      ),
      isTrue,
    );
    expect(work.workspaceStockMovements.first.quantityDelta, 2);

    work
      ..workspaceOrderCustomer = '9829012345'
      ..workspaceOrderItems = 'Fortune Sunflower Oil × 2'
      ..workspaceOrderAmount = '528'
      ..workspaceOrderStage = 'Confirmed'
      ..workspaceOrderQuantities['oil-fortune-1l'] = 2;
    work.advanceWorkspaceOrder();
    expect(work.workspaceCatalogueItems.first.stock, 8);
    expect(work.workspaceReservedUnitCount, 2);
    expect(
      work.workspaceStockMovements.first.kind,
      WorkspaceStockMovementKind.reserved,
    );
    work.cancelWorkspaceOrder();
    expect(work.workspaceCatalogueItems.first.stock, 10);
    expect(work.workspaceReservedUnitCount, 0);
    expect(
      work.workspaceStockMovements.first.kind,
      WorkspaceStockMovementKind.released,
    );

    final availabilityOnly = catalogueProduct(90, stock: 0).copyWith(
      stockMode: WorkspaceStockMode.availabilityOnly,
      available: true,
      publicListing: true,
    );
    expect(availabilityOnly.published, isTrue);
    expect(
      availabilityOnly
          .toBuyPublicFacts(
            storeName: 'Mahadev Fresh Mart',
            sourceId: 'WK-510001',
            storeVisible: true,
            acceptingOrders: true,
            observedAt: DateTime(2026, 9, 4),
          )
          .orderabilityLabel,
      'Available to order',
    );
  });

  testWidgets(
    'Work inputs expose named customer fields inside compact chooser',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final work = liveStore();
      await mount(tester, route: '/app/work/workspace/dashboard', work: work);
      await tester.tap(find.byKey(const Key('work-store-sell')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('work-sale-customer')));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Customer mobile number'), findsOne);
      final customerSemantics = tester.getSemantics(
        find.bySemanticsLabel('Customer mobile number'),
      );
      expect(customerSemantics.identifier, 'work-order-customer');
      expect(customerSemantics.value, 'Not entered');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-dashboard-counter-order-screen')),
        findsOne,
      );
      expect(work.workspaceOrders, isEmpty);
      semantics.dispose();
    },
  );

  testWidgets('Grow keeps offers and funded work inside Store ownership', (
    tester,
  ) async {
    final work = liveStore();
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    await openStoreTools(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-business-grow')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-growth-offers')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-store-offers-screen')), findsOne);
    expect(find.byKey(const Key('work-local-navigation')), findsOne);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-grow-destination')), findsOne);
    await tester.ensureVisible(find.byKey(const Key('work-growth-paid-work')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-growth-paid-work')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-requirement-selector')), findsOne);
    expect(find.byKey(const Key('work-grow-destination')), findsOne);
    final service = find.byKey(const Key('work-requirement-category-4'));
    await Scrollable.ensureVisible(tester.element(service), alignment: .5);
    await tester.pumpAndSettle();
    await tester.tap(service);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-paid-requirement-screen')), findsOne);
    expect(find.byKey(const Key('work-local-navigation')), findsOne);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-grow-destination')), findsOne);
    expect(work.workspacePaidRequirementReference, isNull);
  });

  testWidgets('Grow shows live Store outcomes before its first actions', (
    tester,
  ) async {
    final work = liveStore()..workspaceVisibleToCustomers = true;
    final now = DateTime.now();
    work.workspaceOrders.addAll([
      customerOrder(
        id: 'GROW-1',
        customer: 'Rakesh · 98290 12345',
        createdAt: now,
      ),
      customerOrder(
        id: 'GROW-2',
        customer: 'Rakesh · 98290 12345',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
    ]);
    work.workspaceOffers.add(
      WorkspaceStoreOffer(
        id: 'OFFER-1',
        title: 'Monthly essentials',
        detail: 'Save on monthly essentials.',
        validUntil: now.add(const Duration(days: 5)),
        active: true,
      ),
    );
    work.workspacePaidRequirementReference = 'WORK-1';
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    await openStoreTools(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-business-grow')));
    await tester.pumpAndSettle();

    expect(find.text('Grow repeat business'), findsOneWidget);
    expect(find.text('Repeat'), findsOneWidget);
    expect(find.text('Offers live'), findsOneWidget);
    expect(find.text('Requirements'), findsOneWidget);
    expect(find.text('Public'), findsOneWidget);
    for (final keyName in const [
      'work-growth-customers',
      'work-growth-offers',
      'work-growth-social',
      'work-growth-paid-work',
      'work-growth-services',
    ]) {
      expect(find.byKey(Key(keyName)), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Store offer preview requires an available product and permission',
    (tester) async {
      final work = liveStore();
      final customer = customerOrder(
        id: 'OFFER-CUSTOMER',
        customer: 'Rakesh · 98290 12345',
        createdAt: DateTime.now(),
      );
      work.workspaceOrders.add(customer);
      work.workspaceCustomersAllowingMessages.add('9829012345');
      await mount(tester, route: '/app/work/workspace/dashboard', work: work);
      await openStoreTools(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('work-business-grow')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('work-growth-offers')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Monthly essentials'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('work-offer-product')));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Fortune Sunflower Oil').last);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('work-offer-preview')),
        180,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('work-store-offers-screen')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-offer-preview')).hitTestable(),
        findsOneWidget,
      );
      expect(find.text('Save on your monthly essentials'), findsWidgets);
      expect(find.textContaining('1 customers can receive'), findsOneWidget);
      expect(find.textContaining('₹264'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Store requirement reviews outcome and fees before any publication',
    (tester) async {
      final work = liveStore();
      await mount(tester, route: '/app/work/workspace/dashboard', work: work);
      await tester.tap(find.byKey(const Key('work-quick-requirement')));
      await tester.pumpAndSettle();
      final service = find.byKey(const Key('work-requirement-category-4'));
      await Scrollable.ensureVisible(tester.element(service), alignment: .5);
      await tester.pumpAndSettle();
      await tester.tap(service);
      await tester.pumpAndSettle();
      for (final entry in const {
        'work-requirement-title': 'Create store product photos',
        'work-requirement-outcome': 'Deliver ten clear product photos.',
        'work-requirement-terms': 'Payment after approved photos.',
        'work-requirement-budget': '500',
      }.entries) {
        final field = find.byKey(Key(entry.key));
        await tester.ensureVisible(field);
        await tester.enterText(field, entry.value);
      }
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('work-requirement-review')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-requirement-review-surface')),
        findsOne,
      );
      expect(find.text('Create store product photos'), findsOne);
      expect(find.text('Deliver ten clear product photos.'), findsOne);
      await reveal(tester, find.text('₹500'));
      expect(find.text('₹500'), findsOne);
      expect(work.workspacePaidRequirementReference, isNull);
      await reveal(tester, find.byKey(const Key('work-requirement-edit')));
      expect(find.text('Not posted. No payment has been taken.'), findsOne);
      await tester.tap(find.byKey(const Key('work-requirement-edit')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('work-requirement-title')))
            .controller
            ?.text,
        'Create store product photos',
      );
      expect(work.workspacePaidRequirementReference, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'DASH02 exact activity search survives updates and Back $scale',
      (tester) async {
        final work = storeViewFixture(null, _ContactDraftFixtureStore());
        final store = work.activeWorkspace!;
        final selectedOrder = work.currentWorkspaceOrderId;
        final invoiceCount = work.workspaceInvoices.length;
        final original = WorkspaceActivityEntry(
          message:
              'PO-417 delivery checked: 97 packs counted; three need review.',
          time: DateTime(2026, 1, 2, 11, 24),
        );
        work.workspaceActivity.insert(0, original);
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: scale == 1 ? const Size(412, 915) : const Size(320, 568),
          textScale: scale,
        );
        await tester.tap(find.byKey(const Key('work-dashboard-search')));
        await tester.pumpAndSettle();
        final search = find.byKey(const Key('work-dashboard-search-field'));
        await tester.enterText(search, 'PO-417');
        await tester.pumpAndSettle();
        final result = find.byKey(const Key('work-search-activity-0'));
        final retainedTap = tester.widget<MoolCardSurface>(result).onTap!;
        for (var i = 0; i < 1000; i++) {
          work.workspaceActivity.insert(
            0,
            WorkspaceActivityEntry(
              message: 'Another delivery $i',
              time: DateTime(2026, 1, 3, 0, i),
            ),
          );
        }
        work.showNotice('Store updated');
        await tester.pumpAndSettle();
        retainedTap();
        await tester.pumpAndSettle();
        final dialog = find.byKey(const Key('work-search-activity-detail'));
        expect(dialog, findsOneWidget);
        final date = find.byKey(const Key('work-search-activity-time'));
        expect(tester.widget<Text>(date).data, contains('2026'));
        expect(tester.widget<AlertDialog>(dialog).titleTextStyle!.fontSize, 16);
        final dialogSurface = find
            .descendant(of: dialog, matching: find.byType(Material))
            .first;
        expect(
          tester.getSize(dialogSurface).height,
          lessThan(scale == 1 ? 280 : 480),
        );
        expect(
          find.descendant(of: dialog, matching: find.text(original.message)),
          findsOneWidget,
        );
        expect(find.text('Business books'), findsNothing);
        expect(work.currentWorkspaceOrderId, selectedOrder);
        expect(work.workspaceInvoices.length, invoiceCount);
        expect(tester.takeException(), isNull);
        final close = find.byKey(const Key('work-search-activity-close'));
        expect(close.hitTestable(), findsOneWidget);
        expect(tester.getSize(close).height, greaterThanOrEqualTo(48));
        await captureStoreView(tester, 'activity-exact-$scale');
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(dialog, findsNothing);
        expect(tester.widget<TextField>(search).controller!.text, 'PO-417');
        final shifted = find.byKey(const Key('work-search-activity-1000'));
        await reveal(tester, shifted);
        await tester.tap(shifted);
        await tester.pumpAndSettle();
        work.workspaceActivity.remove(original);
        work.showNotice('Store updated');
        await tester.pumpAndSettle();
        expect(
          find.descendant(of: dialog, matching: find.text(original.message)),
          findsNothing,
        );
        expect(
          find.descendant(
            of: dialog,
            matching: find.text(
              'This activity is no longer available. Search again.',
            ),
          ),
          findsOneWidget,
        );
        await captureStoreView(tester, 'activity-removed-$scale');
        await tester.tap(close);
        await tester.pumpAndSettle();
        retainedTap();
        await tester.pumpAndSettle();
        expect(dialog, findsNothing);
        expect(tester.widget<TextField>(search).controller!.text, 'PO-417');
        work.workspaceActivity.insert(0, original);
        work.showNotice('Store updated');
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('work-search-activity-0')));
        await tester.pumpAndSettle();
        work.activateWorkspace(
          WorkWorkspace(
            id: 'ACTIVITY-OTHER',
            name: 'Other store',
            profileId: store.profileId,
            profileLabel: store.profileLabel,
            area: store.area,
            verified: true,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.descendant(of: dialog, matching: find.text(original.message)),
          findsNothing,
        );
        expect(
          find.descendant(
            of: dialog,
            matching: find.text(
              'This activity is no longer available. Search again.',
            ),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await captureStoreView(tester, 'activity-store-changed-$scale');
        await tester.tap(close);
        await tester.pumpAndSettle();
        expect(dialog, findsNothing);
        expect(work.activeWorkspace!.id, 'ACTIVITY-OTHER');
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'DASH13 business assistance preserves origin and drafts $scale',
      (tester) async {
        final work = liveStore();
        final storeId = work.activeWorkspace!.id;
        final chat = ChatSession(
          sendGateway: ReviewChatSendGateway(latency: Duration.zero),
        );
        chat.setDraftTextForSession(
          'workspace-support',
          'Keep my unsent support message',
        );
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          chat: chat,
          viewport: const Size(320, 568),
          textScale: scale,
        );
        await openStoreTools(tester);
        await reveal(tester, find.byKey(const Key('work-business-grow')));
        await tester.tap(find.byKey(const Key('work-business-grow')));
        await tester.pumpAndSettle();
        await reveal(tester, find.byKey(const Key('work-growth-services')));
        await tester.tap(find.byKey(const Key('work-growth-services')));
        await tester.pumpAndSettle();
        expect(find.text('Today'), findsNothing);
        await captureStoreView(tester, 'business-assistance-first-view-$scale');
        for (final (id, title, draft) in [
          ('tax', 'GST and tax assistance', 'GST and tax assistance'),
          (
            'accounts',
            'Bookkeeping and accounts',
            'Bookkeeping and accounts assistance',
          ),
          ('audit', 'Audit support', 'Business audit assistance'),
        ]) {
          final action = find.byKey(Key('work-service-$id-chat'));
          await reveal(tester, action);
          expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
          expect(tester.getSize(action).width, greaterThanOrEqualTo(48));
          if (scale == 1.0) {
            expect(
              tester.getRect(action).left,
              greaterThan(tester.getRect(find.text(title)).right),
            );
            expect(
              tester.getSize(find.byKey(Key('work-service-$id'))).height,
              lessThan(140),
            );
          }
          await captureStoreView(
            tester,
            'business-assistance-${title.split(' ').first}-$scale',
          );
          await tester.tap(action);
          await tester.pumpAndSettle();
          final inbox = find.byKey(const Key('chat-inbox-screen'));
          expect(inbox, findsOneWidget);
          final route = GoRouterState.of(tester.element(inbox)).uri;
          expect(route.queryParameters['workspaceId'], storeId);
          expect(route.queryParameters['draft'], draft);
          expect(
            chat.draftTextForSession('workspace-support'),
            'Keep my unsent support message',
          );
          await tester.tap(find.byKey(const Key('chat-inbox-back')));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('work-dashboard-services-screen')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        }
      },
    );

    for (final keyboardOpen in [false, true]) {
      testWidgets(
        'R6617 requirement reveals validation $scale keyboard $keyboardOpen',
        (tester) async {
          final previousHitTestFatal =
              WidgetController.hitTestWarningShouldBeFatal;
          WidgetController.hitTestWarningShouldBeFatal = true;
          addTearDown(() {
            WidgetController.hitTestWarningShouldBeFatal = previousHitTestFatal;
          });
          final work = storeViewFixture();
          await mount(
            tester,
            route: '/app/work/workspace/dashboard',
            work: work,
            viewport: scale == 1 ? const Size(412, 915) : const Size(320, 568),
            textScale: scale,
          );
          await reveal(tester, find.byKey(const Key('work-quick-requirement')));
          await tester.tap(find.byKey(const Key('work-quick-requirement')));
          await tester.pumpAndSettle();
          final service = find.byKey(const Key('work-requirement-category-4'));
          await tester.ensureVisible(service);
          await tester.pumpAndSettle();
          await tester.tap(service);
          await tester.pumpAndSettle();
          final title = find.byKey(const Key('work-requirement-title'));
          if (keyboardOpen) {
            await tester.showKeyboard(title);
            tester.view.viewInsets = const FakeViewPadding(bottom: 240);
            await tester.pumpAndSettle();
          }
          final review = find.byKey(const Key('work-requirement-review'));
          await tester.ensureVisible(review);
          await tester.pumpAndSettle();
          await tester.tap(review, warnIfMissed: true);
          await tester.pump();
          expect(tester.testTextInput.isVisible, isFalse);
          tester.view.viewInsets = const FakeViewPadding();
          await tester.pumpAndSettle();
          // No reveal/scroll helper after Review: the screen must expose its
          // own correction instead of relying on the tester to find it.
          final error = find.byKey(const Key('work-requirement-error'));
          expect(error.hitTestable(), findsOneWidget);
          expect(find.text('Describe what your store needs.'), findsOneWidget);
          final errorRect = tester.getRect(error);
          final formRect = tester.getRect(
            find.byKey(const Key('work-requirement-details')),
          );
          expect(errorRect.top, greaterThanOrEqualTo(formRect.top));
          expect(errorRect.bottom, lessThanOrEqualTo(formRect.bottom));
          final semantics = tester.widget<Semantics>(
            find.ancestor(of: error, matching: find.byType(Semantics)).first,
          );
          expect(semantics.properties.liveRegion, isTrue);
          expect(work.workspacePaidRequirementReference, isNull);
          await captureStoreView(
            tester,
            'requirement-visible-error-$scale-$keyboardOpen',
          );
          for (final entry in const {
            'work-requirement-title': 'Create store product photos',
            'work-requirement-outcome': 'Deliver ten clear product photos.',
          }.entries) {
            final field = find.byKey(Key(entry.key));
            await tester.ensureVisible(field);
            await tester.pumpAndSettle();
            await tester.enterText(field, entry.value);
          }
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
          await tester.ensureVisible(review);
          await tester.pumpAndSettle();
          await tester.tap(review, warnIfMissed: true);
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('work-requirement-review-surface')),
            findsOneWidget,
          );
          expect(error, findsNothing);
          expect(work.workspacePaidRequirementReference, isNull);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('DASH13 requirement budget validation $scale', (tester) async {
      final work = liveStore();
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: const Size(320, 568),
        textScale: scale,
      );
      await reveal(tester, find.byKey(const Key('work-quick-requirement')));
      await tester.tap(find.byKey(const Key('work-quick-requirement')));
      await tester.pumpAndSettle();
      final service = find.byKey(const Key('work-requirement-category-4'));
      await reveal(tester, service);
      await tester.tap(service);
      await tester.pumpAndSettle();
      for (final entry in const {
        'work-requirement-title': 'Create store product photos',
        'work-requirement-outcome': 'Deliver ten clear product photos.',
      }.entries) {
        final field = find.byKey(Key(entry.key));
        await reveal(tester, field);
        await tester.enterText(field, entry.value);
      }
      final budget = find.byKey(const Key('work-requirement-budget'));
      final review = find.byKey(const Key('work-requirement-review'));
      const error =
          'Enter a positive amount with up to 2 decimal places, or leave it blank to discuss.';
      for (final value in [
        'NaN',
        'Infinity',
        '-Infinity',
        '1e999',
        '0',
        '-1',
        '1.234',
        'abc',
      ]) {
        await reveal(tester, budget);
        await tester.enterText(budget, value);
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await reveal(tester, review);
        await tester.tap(review);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-requirement-review-surface')),
          findsNothing,
        );
        expect(find.text(error).hitTestable(), findsOneWidget);
        expect(work.workspacePaidRequirementReference, isNull);
        expect(tester.takeException(), isNull);
      }
      await captureStoreView(tester, 'requirement-budget-error-$scale');
      for (final value in ['', '0.01', '500.50', '10000000000']) {
        await reveal(tester, budget);
        await tester.enterText(budget, value);
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await reveal(tester, review);
        await tester.tap(review);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-requirement-review-surface')),
          findsOneWidget,
        );
        expect(find.text(error), findsNothing);
        expect(work.workspacePaidRequirementReference, isNull);
        if (value == '10000000000') {
          final amount = find.text('₹10000000000');
          await reveal(tester, amount);
          expect(amount.hitTestable(), findsOneWidget);
          final amountBox = tester.getRect(amount);
          expect(amountBox.left, greaterThanOrEqualTo(0));
          expect(amountBox.right, lessThanOrEqualTo(320));
          await captureStoreView(tester, 'requirement-budget-large-$scale');
        }
        final edit = find.byKey(const Key('work-requirement-edit'));
        await reveal(tester, edit);
        await tester.tap(edit);
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(budget).controller?.text, value);
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('Store settings save editable hours capacity and alerts', (
    tester,
  ) async {
    final work = liveStore();
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    await openStoreSettings(tester);
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('work-status-max-orders-12')));
    await tester.tap(find.byKey(const Key('work-status-max-orders-12')));
    await reveal(tester, find.byKey(const Key('work-status-alert-sound')));
    await tester.tap(find.byKey(const Key('work-status-alert-sound')));
    await tester.tap(find.byKey(const Key('work-status-save')));
    await tester.pumpAndSettle();
    expect(work.workspaceMaximumActiveOrders, 12);
    expect(work.workspaceOrderAlertSound, isFalse);
    expect(find.byKey(const Key('work-store-activity-deck')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('active Store business record never shows pending onboarding', (
    tester,
  ) async {
    final work = liveStore();
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    await openStoreSettings(tester);
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Business details and documents'));
    await tester.tap(find.text('Business details and documents'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-business-record-screen')), findsOne);
    expect(find.text('Registered MoolSocial Business Partner'), findsOne);
    expect(find.textContaining('Decision Pending'), findsNothing);
  });

  testWidgets('packing keeps every product above its ready action on OPPO', (
    tester,
  ) async {
    final work = liveStore();
    seedIncomingOrder(work, stage: 'Preparing');
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    final first = find.byKey(const Key('work-pack-summary-0'));
    final second = find.byKey(const Key('work-pack-summary-1'));
    final ready = find.byKey(const Key('work-activity-mark-ready'));
    expect(first.hitTestable(), findsOneWidget);
    expect(second.hitTestable(), findsOneWidget);
    expect(
      tester.getBottomRight(second).dy,
      lessThanOrEqualTo(tester.getTopRight(ready).dy),
    );
  });

  testWidgets('nested Store operations return to their exact parent', (
    tester,
  ) async {
    final work = liveStore();
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    await openStoreSettings(tester);
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Delivery area and charges'));
    await tester.tap(find.text('Delivery area and charges'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-operation-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-dashboard-status-screen')), findsOne);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await openStoreTools(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-business-grow')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-growth-offers')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('work-operation-back')).hitTestable(),
      findsOneWidget,
    );
    expect(find.byKey(const Key('work-back')), findsNothing);
    await tester.tap(find.byKey(const Key('work-operation-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-grow-destination')), findsOne);
  });

  for (final (width, height, scale) in [
    (412.0, 915.0, 1.0),
    (412.0, 915.0, 2.0),
    (320.0, 568.0, 2.0),
  ]) {
    testWidgets('REG4559 customer correction keyboard Back fit $width $scale', (
      tester,
    ) async {
      Future<void> revealCounter(
        Finder target, {
        bool towardStart = false,
      }) async {
        final short = find.byKey(const Key('work-sale-short-scroll'));
        if (short.evaluate().isNotEmpty) {
          await tester.scrollUntilVisible(
            target,
            towardStart ? -160 : 160,
            scrollable: find
                .descendant(of: short, matching: find.byType(Scrollable))
                .first,
            maxScrolls: 20,
          );
        }
        await reveal(tester, target);
      }

      final work = liveStore();
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: Size(width, height),
        textScale: scale,
      );
      await tester.tap(find.byKey(const Key('work-store-sell')));
      await tester.pumpAndSettle();
      await revealCounter(
        find.byKey(const Key('work-order-add-oil-fortune-1l')),
      );
      await tester.tap(find.byKey(const Key('work-order-add-oil-fortune-1l')));
      await tester.pumpAndSettle();
      await revealCounter(
        find.byKey(const Key('work-sale-customer')),
        towardStart: true,
      );
      await tester.tap(find.byKey(const Key('work-sale-customer')));
      await tester.pumpAndSettle();
      final field = find.byKey(const Key('work-order-customer'));
      final confirm = find.byKey(const Key('work-sale-customer-confirm'));
      tester.view.viewInsets = const FakeViewPadding(bottom: 200);
      await tester.pumpAndSettle();
      for (final invalid in [
        '98290123456',
        'x9829012345',
        '9829012345x',
        '5123456789',
        '+1 9829012345',
      ]) {
        await tester.enterText(field, invalid);
        await reveal(tester, confirm);
        await tester.tap(confirm);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-sale-customer-sheet')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('work-sale-customer-error')),
          findsOneWidget,
        );
        expect(tester.widget<TextField>(field).controller!.text, invalid);
        expect(work.workspaceOrderCustomer, isEmpty);
        expect(work.workspaceInvoices, isEmpty);
        expect(work.workspaceOrderQuantities['oil-fortune-1l'], 1);
        expect(tester.takeException(), isNull);
      }
      await reveal(tester, find.byKey(const Key('work-sale-customer-error')));
      await captureStoreView(tester, 'customer-invalid-$width-$scale');
      await tester.enterText(field, '+91 98290 12345');
      await reveal(tester, confirm);
      await tester.tap(confirm);
      tester.view.viewInsets = const FakeViewPadding();
      await tester.pumpAndSettle();
      expect(work.workspaceOrderCustomer, '9829012345');
      expect(work.workspaceInvoices, isEmpty);
      await revealCounter(
        find.byKey(const Key('work-sale-customer')),
        towardStart: true,
      );
      final label = find.byKey(const Key('work-sale-customer-label'));
      final paragraph = tester.renderObject<RenderParagraph>(label);
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(
        paragraph.getBoxesForSelection(
          const TextSelection(baseOffset: 0, extentOffset: 10),
        ),
        hasLength(1),
      );
      final tile = find.byKey(const Key('work-sale-product-oil-fortune-1l'));
      if (scale == 2 && height > 600) {
        final title = find.descendant(
          of: tile,
          matching: find.text('Fortune Sunflower Oil'),
        );
        final amount = find.descendant(of: tile, matching: find.text('₹264'));
        expect(
          tester.getTopLeft(amount).dy - tester.getBottomLeft(title).dy,
          greaterThanOrEqualTo(6),
        );
      }
      await captureStoreView(tester, 'customer-corrected-$width-$scale');
      await revealCounter(find.byKey(const Key('work-order-review')));
      await tester.tap(find.byKey(const Key('work-order-review')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-order-review-summary')),
        findsOneWidget,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await revealCounter(
        find.byKey(const Key('work-sale-customer')),
        towardStart: true,
      );
      await tester.tap(find.byKey(const Key('work-sale-customer')));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field).controller!.text, '9829012345');
      await tester.enterText(field, 'not-a-number');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(work.workspaceOrderCustomer, '9829012345');
      expect(work.workspaceOrderQuantities['oil-fortune-1l'], 1);
      expect(work.workspaceInvoices, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'REG4559 retained malformed draft requests correction not review',
    (tester) async {
      final work = liveStore();
      work.workspaceOrderCustomer = '982901234567';
      work.workspaceOrderQuantities['oil-fortune-1l'] = 1;
      // Mount once with a retained, previously accepted malformed draft.
      await mount(
        tester,
        route: '/app/work/workspace/dashboard?section=sell',
        work: work,
      );
      expect(
        find.byKey(const Key('work-dashboard-counter-order-screen')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('work-order-review')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-sale-customer-sheet')), findsOneWidget);
      expect(find.byKey(const Key('work-order-review-summary')), findsNothing);
      final field = find.byKey(const Key('work-order-customer'));
      expect(tester.widget<TextField>(field).controller!.text, '982901234567');
      await tester.tap(find.byKey(const Key('work-sale-customer-confirm')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-sale-customer-error')), findsOneWidget);
      expect(work.workspaceOrderCustomer, '982901234567');
      expect(work.workspaceInvoices, isEmpty);
    },
  );

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'counter isolation keeps pending handover on dashboard $scale',
      (tester) async {
        final work = storeViewFixture();
        final selected = work.currentWorkspaceOrderId;
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: const Size(412, 915),
          textScale: scale,
        );
        work.workspaceHandoverBusy = true;
        await tester.tap(find.byKey(const Key('work-store-sell')));
        await tester.pumpAndSettle();
        expect(work.currentWorkspaceOrderId, selected);
        expect(
          find.byKey(const Key('work-dashboard-counter-order-screen')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('work-store-activity-deck')),
          findsOneWidget,
        );
        expect(work.noticeMessage, contains('current order update'));
        work.workspaceHandoverBusy = false;
        await tester.tap(find.byKey(const Key('work-store-sell')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-dashboard-counter-order-screen')),
          findsOneWidget,
        );
        expect(work.currentWorkspaceOrderId, isNull);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'counter isolation refused save retains bill and recovers $scale',
      (tester) async {
        final work = liveStore();
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: const Size(412, 915),
          textScale: scale,
        );
        await tester.tap(find.byKey(const Key('work-store-sell')));
        await tester.pumpAndSettle();
        await enterSaleCustomer(tester, '9829012345');
        await tester.tap(
          find.byKey(const Key('work-order-add-oil-fortune-1l')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('work-order-review')));
        await tester.pumpAndSettle();
        // A late selection update must not let the open form replace that order.
        final incoming = WorkspaceOrderRecord(
          id: 'incoming-protected',
          customer: 'Asha',
          items: 'Ordered oil',
          quantities: {'oil-fortune-1l': 2},
          amount: 500,
          source: 'App',
          fulfilment: 'Mool delivery',
          payment: 'Paid online',
          address: 'Market road',
          stage: 'Confirmed',
          needsDelivery: true,
          createdAt: DateTime(2026, 9, 10),
        );
        work.workspaceOrders.add(incoming);
        work.currentWorkspaceOrderId = incoming.id;
        await tester.tap(find.byKey(const Key('work-order-save')));
        await tester.pumpAndSettle();
        expect(work.currentWorkspaceOrder, same(incoming));
        expect(work.workspaceInvoices, isEmpty);
        expect(work.workspaceOrderCustomer, '9829012345');
        expect(work.workspaceOrderQuantities['oil-fortune-1l'], 1);
        expect(find.byKey(const Key('work-order-error')), findsOneWidget);
        expect(find.text('Send customer invoice'), findsNothing);
        expect(
          find.text(
            'Use this order’s actions. Start a new bill for a counter sale.',
          ),
          findsOneWidget,
        );
        await captureStoreView(tester, 'counter-refused-save-$scale');
        expect(tester.takeException(), isNull);
        // Recovery uses real controls; do not fix selection directly in tests.
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('work-order-keep-editing')));
        await tester.pumpAndSettle();
        expect(work.workspaceOrderCustomer, '9829012345');
        expect(work.workspaceOrderQuantities['oil-fortune-1l'], 1);
        expect(work.currentWorkspaceOrder, same(incoming));
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('work-order-discard')));
        await tester.pumpAndSettle();
        expect(work.workspaceInvoices, isEmpty);
        await tester.tap(find.byKey(const Key('work-store-sell')));
        await tester.pumpAndSettle();
        await enterSaleCustomer(tester, '9829012345');
        await tester.tap(
          find.byKey(const Key('work-order-add-oil-fortune-1l')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('work-order-review')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('work-order-save')));
        await tester.pumpAndSettle();
        expect(work.workspaceInvoices, hasLength(1));
        expect(work.workspaceInvoices.single.orderId, isNot(incoming.id));
        expect(
          work.workspaceOrders.firstWhere((o) => o.id == incoming.id),
          same(incoming),
        );
        expect(work.workspaceOrderCustomer, isEmpty);
        expect(find.text('Send customer invoice'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('DASH15 counter recovery read retry and completion $scale', (
      tester,
    ) async {
      final journal = _CounterDraftFixtureStore()..failRead = true;
      final work =
          WorkSession(
              gateway: ReviewWorkGateway(),
              contactDraftStore: _ContactDraftFixtureStore(),
              counterDraftStore: journal,
            )
            ..seedVerifiedWorkspace()
            ..retailerSetupSaved = true
            ..reviewStage = WorkReviewStage.live;
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: scale == 1 ? const Size(412, 915) : const Size(320, 568),
        textScale: scale,
      );
      await tester.tap(find.byKey(const Key('work-store-sell')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-counter-draft-recovery')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('work-order-review')), findsNothing);
      expect(journal.value, isNull);
      expect(
        find.byKey(const Key('work-counter-draft-retry')).hitTestable(),
        findsOneWidget,
      );
      await captureStoreView(tester, 'counter-read-recovery-$scale');
      expect(tester.takeException(), isNull);
      journal.failRead = false;
      await tester.tap(find.byKey(const Key('work-counter-draft-retry')));
      await tester.pumpAndSettle();
      await enterSaleCustomer(tester, '9829012345');
      final add = find.byKey(const Key('work-order-add-oil-fortune-1l'));
      await reveal(tester, add);
      await tester.tap(add);
      await tester.pumpAndSettle();
      final stockBefore = work.workspaceCatalogueItems
          .firstWhere((p) => p.id == 'oil-fortune-1l')
          .stock;
      journal.failRetire = true;
      await reveal(tester, find.byKey(const Key('work-order-review')));
      await tester.tap(find.byKey(const Key('work-order-review')));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('work-order-save')));
      await tester.tap(find.byKey(const Key('work-order-save')));
      await tester.pumpAndSettle();
      expect(work.workspaceInvoices, hasLength(1));
      final invoiceId = work.workspaceInvoices.single.id;
      expect(find.text('Send customer invoice'), findsNothing);
      expect(
        find.byKey(const Key('work-counter-draft-recovery')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('work-counter-draft-retry')).hitTestable(),
        findsOneWidget,
      );
      await captureStoreView(tester, 'counter-completion-recovery-$scale');
      expect(tester.takeException(), isNull);
      journal.failRetire = false;
      final retry = find.byKey(const Key('work-counter-draft-retry'));
      await reveal(tester, retry);
      await tester.tap(retry);
      await tester.pumpAndSettle();
      // The existing invoice transition starts after its 240ms delayed handoff.
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('Send customer invoice'), findsOneWidget);
      expect(work.workspaceInvoices.single.id, invoiceId);
      expect(work.workspaceOrderQuantities, isEmpty);
      expect(work.workspaceOrderCustomer, isEmpty);
      expect(
        work.workspaceCatalogueItems
            .firstWhere((p) => p.id == 'oil-fortune-1l')
            .stock,
        stockBefore - 1,
      );
      expect(tester.takeException(), isNull);
      await captureStoreView(tester, 'counter-recovered-invoice-$scale');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-counter-draft-recovery')),
        findsNothing,
      );
      expect(work.workspaceInvoices, hasLength(1));
    });
    testWidgets(
      'DASH15 counter review requires the changed total to be reviewed $scale',
      (tester) async {
        final work =
            WorkSession(
                gateway: ReviewWorkGateway(),
                contactDraftStore: _ContactDraftFixtureStore(),
                counterDraftStore: _CounterDraftFixtureStore(),
              )
              ..seedVerifiedWorkspace()
              ..retailerSetupSaved = true
              ..reviewStage = WorkReviewStage.live;
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: scale == 1 ? const Size(412, 915) : const Size(320, 568),
          textScale: scale,
        );
        await tester.tap(find.byKey(const Key('work-store-sell')));
        await tester.pumpAndSettle();
        await enterSaleCustomer(tester, '9829012345');
        final add = find.byKey(const Key('work-order-add-oil-fortune-1l'));
        await reveal(tester, add);
        await tester.tap(add);
        await tester.pumpAndSettle();
        await reveal(tester, find.byKey(const Key('work-order-review')));
        await tester.tap(find.byKey(const Key('work-order-review')));
        await tester.pumpAndSettle();
        final index = work.workspaceCatalogueItems.indexWhere(
          (p) => p.id == 'oil-fortune-1l',
        );
        final original = work.workspaceCatalogueItems[index];
        final updatedPrice = original.sellingPrice - 1;
        work.workspaceCatalogueItems[index] = original.copyWith(
          sellingPrice: updatedPrice,
        );
        work.notifyListeners();
        await tester.pumpAndSettle();
        final save = find.byKey(const Key('work-order-save'));
        await reveal(tester, save);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(work.workspaceInvoices, isEmpty);
        expect(
          find.byKey(const Key('work-order-review-summary')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('work-order-review-summary')),
            matching: find.text('₹$updatedPrice'),
          ),
          findsOneWidget,
        );
        final update = find.text('Bill updated. Review the items and total.');
        expect(update, findsOneWidget);
        expect(
          tester
              .widget<Semantics>(
                find.byKey(const Key('work-bill-review-update')),
              )
              .properties
              .liveRegion,
          isTrue,
        );
        expect(find.text('Payment'), findsOneWidget);
        await reveal(tester, update);
        await captureStoreView(tester, 'counter-updated-total-$scale');
        expect(tester.takeException(), isNull);
        await reveal(tester, save);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(work.workspaceInvoices, hasLength(1));
        expect(work.workspaceInvoices.single.amount, updatedPrice);
        expect(work.workspaceCatalogueItems[index].stock, original.stock - 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'created counter invoice leaves an empty bill and safe Store return',
    (tester) async {
      final work = liveStore();
      await mount(tester, route: '/app/work/workspace/dashboard', work: work);
      await tester.tap(find.byKey(const Key('work-store-sell')));
      await tester.pumpAndSettle();
      await enterSaleCustomer(tester, '9829012345');
      await tester.tap(find.byKey(const Key('work-order-add-oil-fortune-1l')));
      await tester.pumpAndSettle();
      final stockBefore = work.workspaceCatalogueItems
          .firstWhere((item) => item.id == 'oil-fortune-1l')
          .stock;
      await tester.tap(find.byKey(const Key('work-order-review')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('work-order-save')));
      await tester.pumpAndSettle();
      expect(find.text('Send customer invoice'), findsOneWidget);
      expect(work.workspaceInvoices, hasLength(1));
      expect(work.workspaceOrderCustomer, isEmpty);
      expect(work.workspaceOrderQuantities, isEmpty);
      expect(
        work.workspaceCatalogueItems
            .firstWhere((item) => item.id == 'oil-fortune-1l')
            .stock,
        stockBefore - 1,
      );
      await tester.tap(find.byTooltip('Close invoice'));
      await tester.pumpAndSettle();
      expect(find.text('Add customer'), findsOneWidget);
      expect(find.text('Review bill'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('work-order-review')))
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const Key('work-store-home')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-order-discard-dialog')), findsNothing);
      expect(find.byKey(const Key('work-store-activity-deck')), findsOneWidget);
      expect(work.workspaceInvoices, hasLength(1));
      expect(work.workspaceCompletedSalesCount, 1);
      expect(tester.takeException(), isNull);
    },
  );

  for (final scale in [1.0, 2.0]) {
    testWidgets('DASH03 exact finance alerts among 1000 payments $scale', (
      tester,
    ) async {
      final work = storeViewFixture(null, _ContactDraftFixtureStore());
      final store = work.activeWorkspace!;
      final selectedOrder = work.currentWorkspaceOrderId;
      final orderStages = work.workspaceOrders
          .map((o) => (o.id, o.stage))
          .toList();
      final now = DateTime.now();
      WorkspaceFinanceSnapshot snapshot(
        int revision, {
        bool paymentResolved = false,
        bool payoutResolved = false,
      }) => WorkspaceFinanceSnapshot(
        accountScope: 'review-draft-account',
        workspaceId: store.id,
        revision: revision,
        asOf: now.add(Duration(seconds: revision)),
        salesTodayMinor: 146800000,
        duesMinor: 0,
        availableMinor: 100000,
        heldMinor: payoutResolved ? 0 : 1000000000050,
        requestedMinor: 0,
        paidOutMinor: payoutResolved ? 1000000000050 : 0,
        feesMinor: 0,
        deliveryAdjustmentsMinor: 0,
        refundsMinor: 0,
        taxWithheldMinor: 0,
        payments: [
          for (var i = 0; i < 1000; i++)
            WorkspacePaymentRecord(
              orderId: i == 0
                  ? 'APP-1043'
                  : 'FIN-${i.toString().padLeft(4, '0')}',
              customerId: 'customer-$i',
              customerName: 'Same customer',
              revision: revision,
              updatedAt: now.add(Duration(seconds: revision)),
              amountMinor: 146800,
              paidMinor: 146800,
              dueMinor: 0,
              refundedMinor: 0,
              state: i == 0 && !paymentResolved
                  ? WorkspacePaymentState.pending
                  : i == 998
                  ? WorkspacePaymentState.disputed
                  : WorkspacePaymentState.paid,
              channel: WorkspacePaymentChannel.platform,
              invoiceId: 'INV-$i',
              transactionId: 'TX-$i',
            ),
        ],
        payouts: [
          WorkspacePayoutRecord(
            id: 'SET-A',
            operationId: 'SET-OP-A',
            revision: revision,
            amountMinor: 1000000000050,
            updatedAt: now.add(Duration(seconds: revision)),
            state: payoutResolved
                ? WorkspacePayoutState.paid
                : WorkspacePayoutState.held,
            bankLabel: 'Bank · •••• 4321',
            message: 'Receiving account needs review.',
          ),
          WorkspacePayoutRecord(
            id: 'SET-B',
            operationId: 'SET-OP-B',
            revision: revision,
            amountMinor: 100000,
            updatedAt: now.add(Duration(seconds: revision)),
            state: WorkspacePayoutState.paid,
          ),
        ],
      );
      expect(work.applyWorkspaceFinance(snapshot(1)), isTrue);
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: scale == 1 ? const Size(412, 915) : const Size(320, 568),
        textScale: scale,
      );
      await tester.tap(find.byKey(const Key('work-dashboard-alerts')));
      await tester.pumpAndSettle();
      final list = find.byKey(const Key('work-dashboard-alerts-screen'));
      final scroll = find
          .descendant(of: list, matching: find.byType(Scrollable))
          .first;
      expect(tester.widget<ListView>(list).semanticChildCount, 4);
      expect(find.byKey(const Key('work-alert-order-APP-1043')), findsNothing);
      expect(
        find.textContaining('Order · Awaiting acceptance'),
        findsOneWidget,
      );
      final payment = find.byKey(const Key('work-alert-cta-payment-APP-1043'));
      await tester.ensureVisible(payment);
      await tester.pumpAndSettle();
      expect(payment.hitTestable(), findsOneWidget);
      expect(tester.getSize(payment).height, greaterThanOrEqualTo(48));
      final retainedPayment = tester.widget<FilledButton>(payment).onPressed!;
      final offset = tester.widget<ListView>(list).controller!.offset;
      await captureStoreView(tester, 'finance-alerts-$scale');
      await tester.tap(payment);
      await tester.pumpAndSettle();
      expect(find.text('Payment details'), findsOneWidget);
      expect(
        tester
            .widget<Semantics>(
              find.byKey(const Key('work-shortcut-state-statement')),
            )
            .properties
            .selected,
        isTrue,
      );
      expect(
        find.byKey(const Key('work-finance-payment-APP-1043')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('work-finance-payment-FIN-0998')),
        findsNothing,
      );
      expect(find.text('Request settlement'), findsNothing);
      await captureStoreView(tester, 'finance-alert-payment-$scale');
      work.markWorkspaceFinanceStale(
        accountScope: 'review-draft-account',
        storeId: store.id,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-finance-stale')), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(list, findsOneWidget);
      expect(
        tester.widget<ListView>(list).controller!.offset,
        closeTo(offset, 1),
      );
      await tester.tap(payment);
      await tester.pumpAndSettle();
      expect(
        work.applyWorkspaceFinance(snapshot(2, paymentResolved: true)),
        isTrue,
      );
      await tester.pumpAndSettle();
      expect(find.text('Payment details'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('work-alert-cta-payment-APP-1043')),
        findsNothing,
      );
      retainedPayment();
      await tester.pumpAndSettle();
      expect(list, findsOneWidget);
      // Its fulfilment action returns; resolving payment never closes the order.
      expect(tester.widget<ListView>(list).semanticChildCount, 4);
      final payout = find.byKey(const Key('work-alert-cta-payout-SET-A'));
      await tester.scrollUntilVisible(payout, 200, scrollable: scroll);
      await tester.ensureVisible(payout);
      await tester.pumpAndSettle();
      expect(payout.hitTestable(), findsOneWidget);
      final retainedPayout = tester.widget<FilledButton>(payout).onPressed!;
      await tester.tap(payout);
      await tester.pumpAndSettle();
      expect(find.text('Settlement details'), findsOneWidget);
      expect(
        tester
            .widget<Semantics>(
              find.byKey(const Key('work-shortcut-state-payments')),
            )
            .properties
            .selected,
        isTrue,
      );
      expect(
        find.byKey(const Key('work-finance-payout-SET-A')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('work-finance-payout-SET-B')), findsNothing);
      expect(find.text('Settlement balance'), findsNothing);
      expect(find.text('Request settlement'), findsNothing);
      final payoutAmount = find.descendant(
        of: find.byKey(const Key('work-finance-payout-SET-A')),
        matching: find.text('₹10,00,00,00,000.50'),
      );
      await tester.ensureVisible(payoutAmount);
      await tester.pumpAndSettle();
      expectExactMoneyVisible(tester, payoutAmount);
      await captureStoreView(tester, 'finance-alert-settlement-$scale');
      expect(
        work.applyWorkspaceFinance(
          snapshot(3, paymentResolved: true, payoutResolved: true),
        ),
        isTrue,
      );
      await tester.pumpAndSettle();
      if (scale == 1) {
        await tester.tap(find.byKey(const Key('work-operation-back')));
      } else {
        await tester.binding.handlePopRoute();
      }
      await tester.pumpAndSettle();
      retainedPayout();
      await tester.pumpAndSettle();
      expect(list, findsOneWidget);
      expect(tester.widget<ListView>(list).semanticChildCount, 3);
      expect(work.applyWorkspaceFinance(snapshot(2)), isFalse);
      final other = find.byKey(const Key('work-alert-cta-payment-FIN-0998'));
      await tester.scrollUntilVisible(other, -200, scrollable: scroll);
      await tester.ensureVisible(other);
      await tester.pumpAndSettle();
      final previousStoreTap = tester.widget<FilledButton>(other).onPressed!;
      await tester.tap(other);
      await tester.pumpAndSettle();
      expect(find.text('Payment details'), findsOneWidget);
      expect(work.currentWorkspaceOrderId, selectedOrder);
      expect(
        work.workspaceOrders.map((o) => (o.id, o.stage)).toList(),
        orderStages,
      );
      expect(work.workspaceStockMovements, isEmpty);
      expect(work.workspaceInvoices, isEmpty);
      work.activateWorkspace(
        WorkWorkspace(
          id: 'FINANCE-OTHER-STORE',
          name: 'Other store',
          profileId: store.profileId,
          profileLabel: store.profileLabel,
          area: store.area,
          verified: true,
        ),
      );
      previousStoreTap();
      await tester.pumpAndSettle();
      expect(find.text('Payment details'), findsNothing);
      expect(work.workspaceFinance, isNull);
      expect(
        find.byKey(const Key('work-finance-payment-FIN-0998')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('DASH02 supplier search exact purchase and Back $scale', (
      tester,
    ) async {
      final work = storeViewFixture(null, _ContactDraftFixtureStore());
      final store = work.activeWorkspace!;
      final selectedOrder = work.currentWorkspaceOrderId;
      final now = DateTime.now();
      final purchases = List.generate(
        1000,
        (index) => WorkspacePurchaseRecord(
          accountScope: 'review-draft-account',
          workspaceId: store.id,
          supplierId: 'supplier-$index',
          supplierName: 'Same supplier',
          orderId: 'PURCHASE-$index',
          shipmentId: 'SEARCH-SHIP-$index',
          purchaseId: 'BUY-$index',
          revision: 1,
          createdAt: now.subtract(Duration(seconds: index)),
          updatedAt: now,
          stage: WorkspaceSupplyStage.arriving,
          amountMinor: 1550050,
          itemSummary: 'Sunflower oil · 1 l × 100 packs',
          paymentLabel: 'Payment pending',
          invoiceReference: 'SUPPLY-INVOICE-$index',
          receiptState: WorkspaceReceiptState.awaiting,
          lines: [
            WorkspacePurchaseLine(
              id: 'line-$index',
              productId: 'supplier-sku-$index',
              name: 'Sunflower oil',
              pack: '1 l',
              orderedPacks: 100,
              unitPriceMinor: 15500,
            ),
          ],
        ),
      );
      expect(
        work.applyWorkspacePurchases(
          accountScope: 'review-draft-account',
          storeId: store.id,
          feedRevision: 1,
          complete: true,
          records: purchases,
        ),
        isTrue,
      );
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: scale == 1 ? const Size(412, 915) : const Size(320, 568),
        textScale: scale,
      );
      await tester.tap(find.byKey(const Key('work-dashboard-search')));
      await tester.pumpAndSettle();
      final field = find.byKey(const Key('work-dashboard-search-field'));
      await tester.enterText(field, 'Same supplier');
      await tester.pumpAndSettle();
      final results = find.byKey(const Key('work-dashboard-search-results'));
      expect(tester.widget<ListView>(results).semanticChildCount, 1000);
      final target = find.byKey(
        const Key('work-search-purchase-SEARCH-SHIP-40'),
      );
      await tester.scrollUntilVisible(
        target,
        300,
        scrollable: find
            .descendant(of: results, matching: find.byType(Scrollable))
            .first,
        maxScrolls: 100,
      );
      await tester.pumpAndSettle();
      final offset = tester.widget<ListView>(results).controller!.offset;
      expect(offset, greaterThan(0));
      await captureStoreView(tester, 'supplier-search-results-$scale');
      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(work.focusedWorkspacePurchaseId, 'SEARCH-SHIP-40');
      expect(work.focusedWorkspacePurchase!.supplierId, 'supplier-40');
      expect(work.currentWorkspaceOrderId, selectedOrder);
      expect(find.byTooltip('Back to search'), findsOneWidget);
      await captureStoreView(tester, 'supplier-search-exact-$scale');
      await tester.tap(find.byKey(const Key('work-purchase-back')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<ListView>(results).controller!.offset,
        closeTo(offset, 1),
      );
      expect(tester.widget<TextField>(field).controller!.text, 'Same supplier');
      expect(work.focusedWorkspacePurchaseId, isNull);
      await tester.tap(target);
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        tester.widget<ListView>(results).controller!.offset,
        closeTo(offset, 1),
      );
      for (final query in [
        'supplier-sku-999',
        'SUPPLY-INVOICE-999',
        'BUY-999',
      ]) {
        await tester.enterText(field, query);
        await tester.pumpAndSettle();
        expect(tester.widget<ListView>(results).semanticChildCount, 1);
        expect(
          find.byKey(const Key('work-search-purchase-SEARCH-SHIP-999')),
          findsOneWidget,
        );
      }
      final last = find.byKey(
        const Key('work-search-purchase-SEARCH-SHIP-999'),
      );
      final oldTap = tester.widget<MoolCardSurface>(last).onTap!;
      await tester.tap(last);
      await tester.pumpAndSettle();
      expect(
        work.applyWorkspacePurchases(
          accountScope: 'review-draft-account',
          storeId: store.id,
          feedRevision: 2,
          complete: true,
          records: const [],
        ),
        isTrue,
      );
      await tester.pumpAndSettle();
      expect(find.text('Purchase update unavailable'), findsOneWidget);
      await tester.tap(find.text('Back to search'));
      await tester.pumpAndSettle();
      oldTap();
      await tester.pumpAndSettle();
      expect(work.focusedWorkspacePurchaseId, isNull);
      expect(
        find.byKey(const Key('work-dashboard-search-empty')),
        findsOneWidget,
      );
      expect(
        work.applyWorkspacePurchases(
          accountScope: 'review-draft-account',
          storeId: store.id,
          feedRevision: 3,
          complete: true,
          records: [purchases.last],
        ),
        isTrue,
      );
      expect(work.workspacePurchases, isEmpty);
      final original = purchases.last;
      expect(
        work.applyWorkspacePurchases(
          accountScope: original.accountScope,
          storeId: store.id,
          feedRevision: 4,
          complete: true,
          records: [
            WorkspacePurchaseRecord(
              accountScope: original.accountScope,
              workspaceId: original.workspaceId,
              supplierId: original.supplierId,
              supplierName: original.supplierName,
              orderId: original.orderId,
              shipmentId: original.shipmentId,
              purchaseId: original.purchaseId,
              revision: 2,
              createdAt: original.createdAt,
              updatedAt: now.add(const Duration(seconds: 1)),
              stage: original.stage,
              amountMinor: original.amountMinor,
              itemSummary: original.itemSummary,
              paymentLabel: original.paymentLabel,
              invoiceReference: original.invoiceReference,
              receiptState: original.receiptState,
              lines: original.lines,
            ),
          ],
        ),
        isTrue,
      );
      await tester.pumpAndSettle();
      final previousStoreTap = tester.widget<MoolCardSurface>(last).onTap!;
      work.activateWorkspace(
        WorkWorkspace(
          id: 'SUPPLIER-SEARCH-OTHER',
          name: 'Other store',
          profileId: store.profileId,
          profileLabel: store.profileLabel,
          area: store.area,
          verified: true,
        ),
      );
      previousStoreTap();
      await tester.pumpAndSettle();
      expect(work.focusedWorkspacePurchaseId, isNull);
      expect(work.workspacePurchases, isEmpty);
      expect(work.workspaceStockMovements, isEmpty);
      expect(work.workspaceInvoices, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final scale in [1.0, 2.0]) {
    for (final amount in [
      (100000000050, '₹1,00,00,00,000.50'),
      (1000000000050, '₹10,00,00,00,000.50'),
    ]) {
      for (final surface in ['search', 'detail']) {
        testWidgets(
          'DASH08 supplier monetary fit $surface ${amount.$1} $scale',
          (tester) async {
            final work = storeViewFixture(null, _ContactDraftFixtureStore());
            final now = DateTime.now();
            final orderBefore = work.currentWorkspaceOrderId;
            expect(
              work.applyWorkspacePurchases(
                accountScope: 'review-draft-account',
                storeId: work.activeWorkspace!.id,
                feedRevision: 1,
                complete: true,
                records: [
                  WorkspacePurchaseRecord(
                    accountScope: 'review-draft-account',
                    workspaceId: work.activeWorkspace!.id,
                    supplierId: 'supplier-money',
                    supplierName: 'Supplier purchase',
                    orderId: 'PO-1',
                    shipmentId: 'SHIP-1',
                    revision: 1,
                    createdAt: now,
                    updatedAt: now,
                    stage: WorkspaceSupplyStage.arriving,
                    amountMinor: amount.$1,
                    itemSummary: 'Stock purchase',
                    paymentLabel: 'Paid online',
                    lines: const [],
                  ),
                ],
              ),
              isTrue,
            );
            await mount(
              tester,
              route: '/app/work/workspace/dashboard',
              work: work,
              viewport: scale == 1
                  ? const Size(412, 915)
                  : const Size(320, 568),
              textScale: scale,
            );
            await tester.tap(find.byKey(const Key('work-dashboard-search')));
            await tester.pumpAndSettle();
            await tester.enterText(
              find.byKey(const Key('work-dashboard-search-field')),
              'PO-1',
            );
            await tester.pumpAndSettle();
            if (surface == 'detail') {
              await tester.tap(
                find.byKey(const Key('work-search-purchase-SHIP-1')),
              );
              await tester.pumpAndSettle();
            }
            final value = find.text(amount.$2);
            await reveal(tester, value);
            await captureStoreView(
              tester,
              'supplier-money-$surface-${amount.$1}-$scale',
            );
            expectExactMoneyVisible(tester, value);
            final paragraph = tester.renderObject<RenderParagraph>(value);
            expect(paragraph.textScaler.scale(14), closeTo(14 * scale, .01));
            expect(
              (paragraph.text as TextSpan).style!.fontSize,
              greaterThanOrEqualTo(14),
            );
            expect(work.currentWorkspaceOrderId, orderBefore);
            expect(work.workspaceStockMovements, isEmpty);
            expect(work.workspaceInvoices, isEmpty);
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
          },
        );
      }
    }
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('DASH03 exact supplier alerts and resolved recovery $scale', (
      tester,
    ) async {
      final work = storeViewFixture(null, _ContactDraftFixtureStore());
      final store = work.activeWorkspace!;
      final selectedOrder = work.currentWorkspaceOrderId;
      final now = DateTime.now();
      WorkspacePurchaseRecord shipment(
        int index, {
        int revision = 1,
        WorkspaceSupplyStage stage = WorkspaceSupplyStage.arriving,
        WorkspaceReceiptState receipt = WorkspaceReceiptState.awaiting,
      }) => WorkspacePurchaseRecord(
        accountScope: 'review-draft-account',
        workspaceId: store.id,
        supplierId: 'supplier-$index',
        supplierName: 'Same supplier',
        orderId: 'PO-$index',
        shipmentId: 'SHIP-$index',
        revision: revision,
        createdAt: now,
        updatedAt: now.add(Duration(seconds: revision)),
        stage: stage,
        amountMinor: 1550050,
        itemSummary: 'Sunflower oil · 1 l × 100 packs',
        paymentLabel: 'Payment pending',
        expectedArrival: 'Today, 4–6 pm',
        receiptState: receipt,
        lines: const [
          WorkspacePurchaseLine(
            id: 'line-1',
            productId: 'oil-1',
            name: 'Sunflower oil',
            pack: '1 l',
            orderedPacks: 100,
            unitPriceMinor: 15500,
          ),
        ],
      );
      expect(
        work.applyWorkspacePurchases(
          accountScope: 'review-draft-account',
          storeId: store.id,
          feedRevision: 1,
          complete: true,
          records: [
            shipment(0),
            shipment(1, stage: WorkspaceSupplyStage.delayed),
            shipment(
              2,
              stage: WorkspaceSupplyStage.delivered,
              receipt: WorkspaceReceiptState.partial,
            ),
            shipment(
              3,
              stage: WorkspaceSupplyStage.delivered,
              receipt: WorkspaceReceiptState.confirmed,
            ),
            shipment(4, stage: WorkspaceSupplyStage.cancelled),
            shipment(
              5,
              stage: WorkspaceSupplyStage.cancelled,
              receipt: WorkspaceReceiptState.disputed,
            ),
          ],
        ),
        isTrue,
      );
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: scale == 1 ? const Size(412, 915) : const Size(320, 568),
        textScale: scale,
      );
      await tester.tap(find.byKey(const Key('work-dashboard-alerts')));
      await tester.pumpAndSettle();
      final list = find.byKey(const Key('work-dashboard-alerts-screen'));
      final listScroll = find
          .descendant(of: list, matching: find.byType(Scrollable))
          .first;
      final target = find.byKey(const Key('work-alert-action-purchase-SHIP-2'));
      await tester.scrollUntilVisible(target, 240, scrollable: listScroll);
      await tester.pumpAndSettle();
      expect(target.hitTestable(), findsOneWidget);
      final targetRect = tester.getRect(target);
      expect(targetRect.width, greaterThanOrEqualTo(48));
      expect(targetRect.height, greaterThanOrEqualTo(48));
      final cta = find.byKey(const Key('work-alert-cta-purchase-SHIP-2'));
      await tester.ensureVisible(cta);
      await tester.pumpAndSettle();
      expect(cta.hitTestable(), findsOneWidget);
      expect(tester.getSize(cta).height, greaterThanOrEqualTo(48));
      expect(
        tester.getRect(cta).bottom,
        lessThanOrEqualTo(tester.getRect(list).bottom),
      );
      final expectedCount = tester.widget<ListView>(list).semanticChildCount!;
      // One customer order, four supply alerts, and the contact notice.
      expect(expectedCount, 6);
      final offset = tester.widget<ListView>(list).controller!.offset;
      await captureStoreView(tester, 'supplier-alerts-$scale');
      await tester.tap(cta);
      await tester.pumpAndSettle();
      expect(work.focusedWorkspacePurchaseId, 'SHIP-2');
      expect(find.text('Order PO-2'), findsOneWidget);
      expect(find.text('Same supplier'), findsOneWidget);
      expect(work.currentWorkspaceOrderId, selectedOrder);
      await captureStoreView(tester, 'supplier-alert-exact-$scale');
      expect(
        work.applyWorkspacePurchases(
          accountScope: 'review-draft-account',
          storeId: store.id,
          feedRevision: 2,
          records: [shipment(0, revision: 2)],
        ),
        isTrue,
      );
      await tester.pumpAndSettle();
      expect(work.focusedWorkspacePurchaseId, 'SHIP-2');
      if (scale == 1) {
        await tester.tap(find.byKey(const Key('work-operation-back')));
      } else {
        await tester.binding.handlePopRoute();
      }
      await tester.pumpAndSettle();
      expect(list, findsOneWidget);
      expect(work.focusedWorkspacePurchaseId, isNull);
      expect(
        tester.widget<ListView>(list).controller!.offset,
        closeTo(offset, 1),
      );
      expect(cta.hitTestable(), findsOneWidget);
      final retainedTap = tester.widget<FilledButton>(cta).onPressed!;
      expect(
        work.applyWorkspacePurchases(
          accountScope: 'review-draft-account',
          storeId: store.id,
          feedRevision: 3,
          records: [
            shipment(
              2,
              revision: 2,
              stage: WorkspaceSupplyStage.delivered,
              receipt: WorkspaceReceiptState.confirmed,
            ),
          ],
        ),
        isTrue,
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<ListView>(list).semanticChildCount,
        expectedCount - 1,
      );
      retainedTap();
      await tester.pumpAndSettle();
      expect(list, findsOneWidget);
      expect(work.focusedWorkspacePurchaseId, isNull);
      expect(work.currentWorkspaceOrderId, selectedOrder);
      expect(work.workspaceStockMovements, isEmpty);
      expect(work.workspaceInvoices, isEmpty);
      final disputed = find.byKey(const Key('work-alert-cta-purchase-SHIP-5'));
      await tester.scrollUntilVisible(disputed, 240, scrollable: listScroll);
      await tester.pumpAndSettle();
      expect(disputed.hitTestable(), findsOneWidget);
      final previousStoreTap = tester.widget<FilledButton>(disputed).onPressed!;
      work.activateWorkspace(
        WorkWorkspace(
          id: 'SUPPLIER-OTHER-STORE',
          name: 'Other store',
          profileId: store.profileId,
          profileLabel: store.profileLabel,
          area: store.area,
          verified: true,
        ),
      );
      previousStoreTap();
      await tester.pumpAndSettle();
      expect(work.focusedWorkspacePurchaseId, isNull);
      expect(work.workspacePurchases, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'DASH07 receiving editor retains exact draft and keyboard $scale',
      (tester) async {
        final storage = _ReceiptDraftFixtureStore()..failRead = true;
        WorkSession fresh() => storeViewFixture(
          null,
          _ContactDraftFixtureStore(),
          null,
          null,
          null,
          null,
          storage,
        );
        var work = fresh();
        final storeId = work.activeWorkspace!.id;
        final originalOrder = work.currentWorkspaceOrderId;
        WorkspacePurchaseRecord shipment(String id, {int revision = 1}) =>
            WorkspacePurchaseRecord(
              accountScope: 'review-draft-account',
              workspaceId: storeId,
              supplierId: 'supplier-$id',
              supplierName: 'Oil wholesaler $id',
              orderId: 'PO-$id',
              shipmentId: id,
              revision: revision,
              createdAt: DateTime(2026),
              updatedAt: DateTime(2026, 9, revision),
              stage: WorkspaceSupplyStage.arriving,
              amountMinor: 1550050,
              itemSummary: 'Sunflower oil',
              paymentLabel: 'Paid online',
              receiptState: WorkspaceReceiptState.awaiting,
              lines: [
                WorkspacePurchaseLine(
                  id: 'line-$id',
                  productId: 'oil-$id',
                  name: 'Sunflower oil',
                  pack: revision == 1 ? '1 l × 12' : '1 l × 6',
                  orderedPacks: 10,
                  unitPriceMinor: 155005,
                  receivedPacks: null,
                ),
              ],
            );
        void feed(int revision) {
          expect(
            work.applyWorkspacePurchases(
              accountScope: 'review-draft-account',
              storeId: storeId,
              feedRevision: revision,
              records: [
                shipment('A', revision: revision),
                shipment('B'),
              ],
              complete: true,
            ),
            isTrue,
          );
        }

        Future<void> showPurchase(String id) async {
          if (work.focusedWorkspacePurchaseId != null) {
            final back = find.byKey(const Key('work-purchase-back'));
            final purchaseList = find.byKey(
              PageStorageKey(
                'work-purchase-details-$storeId-${work.focusedWorkspacePurchaseId}-false',
              ),
            );
            for (
              var attempt = 0;
              attempt < 24 && back.hitTestable().evaluate().isEmpty;
              attempt++
            ) {
              await tester.drag(purchaseList, const Offset(0, 240));
              await tester.pumpAndSettle();
            }
            expect(back.hitTestable(), findsOneWidget);
            await tester.tap(back);
            await tester.pumpAndSettle();
            expect(work.focusedWorkspacePurchaseId, isNull);
          }
          final supplier = find.text('Oil wholesaler $id');
          await reveal(tester, supplier);
          await tester.tap(supplier);
          await tester.pumpAndSettle();
          expect(work.focusedWorkspacePurchaseId, id);
          final entry = find.byKey(const Key('work-receipt-start'));
          await reveal(tester, entry);
          await tester.tap(entry);
          await tester.pumpAndSettle();
        }

        feed(1);
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: scale == 1 ? const Size(412, 915) : const Size(320, 568),
          textScale: scale,
        );
        final incoming = find.byKey(const Key('work-incoming-purchases'));
        await reveal(tester, incoming);
        await tester.tap(incoming);
        await tester.pumpAndSettle();
        await showPurchase('A');
        final retryOpen = find.byKey(const Key('work-receipt-retry-open'));
        await reveal(tester, retryOpen);
        expect(storage.values, isEmpty);
        storage.failRead = false;
        await tester.tap(retryOpen);
        await tester.pumpAndSettle();
        final count = find.byKey(const Key('work-receipt-count-line-A'));
        await reveal(tester, count);
        await tester.enterText(count, '7');
        await tester.pumpAndSettle();
        final issue = find.byKey(const Key('work-receipt-problem-line-A'));
        await reveal(tester, issue);
        await tester.tap(issue);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Damaged packs').last);
        await tester.pumpAndSettle();
        final selectedIssue = find.descendant(
          of: issue,
          matching: find.text('Damaged packs'),
        );
        final paragraph = tester.renderObject<RenderParagraph>(selectedIssue);
        expect(paragraph.didExceedMaxLines, isFalse);
        final textRect = tester.getRect(selectedIssue);
        final fieldRect = tester.getRect(issue);
        expect(textRect.top, greaterThanOrEqualTo(fieldRect.top));
        expect(textRect.bottom, lessThanOrEqualTo(fieldRect.bottom));
        for (final box in paragraph.getBoxesForSelection(
          const TextSelection(baseOffset: 0, extentOffset: 13),
        )) {
          expect(box.bottom, lessThanOrEqualTo(paragraph.size.height));
        }
        await reveal(tester, count);
        await Scrollable.ensureVisible(tester.element(count), alignment: .2);
        await tester.pumpAndSettle();
        await captureStoreView(tester, 'receiving-counts-$scale');
        final note = find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.labelText == 'Delivery note',
        );
        await reveal(tester, note);
        tester.view.viewInsets = const FakeViewPadding(bottom: 220);
        await tester.pumpAndSettle();
        await reveal(tester, note);
        await tester.enterText(note, 'Two packs damaged at arrival.');
        await tester.pumpAndSettle();
        await reveal(tester, note);
        expect(note.hitTestable(), findsOneWidget);
        final helper = tester.renderObject<RenderParagraph>(
          find.text('Add details if needed.'),
        );
        expect(helper.didExceedMaxLines, isFalse);
        expect(
          tester.getRect(note).bottom,
          lessThanOrEqualTo(tester.view.physicalSize.height - 220),
        );
        await captureStoreView(tester, 'receiving-keyboard-$scale');
        tester.view.viewInsets = FakeViewPadding.zero;
        tester.testTextInput.hide();
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        storage.failSave = true;
        await reveal(tester, count);
        await tester.enterText(count, '8');
        await tester.pumpAndSettle();
        final retrySave = find.byKey(const Key('work-receipt-retry-save'));
        await reveal(tester, retrySave);
        await captureStoreView(tester, 'receiving-unsaved-$scale');
        storage.failSave = false;
        await tester.tap(retrySave);
        await tester.pumpAndSettle();
        feed(2);
        await tester.pumpAndSettle();
        final stale = find.byKey(const Key('work-receipt-stale'));
        await reveal(tester, stale);
        await captureStoreView(tester, 'receiving-updated-$scale');
        final close = find.byKey(const Key('work-receipt-close'));
        await reveal(tester, close);
        await tester.tap(close);
        await tester.pumpAndSettle();
        expect(count, findsNothing);
        await reveal(tester, find.text('Sunflower oil · 1 l × 6'));
        expect(
          find.text('Sunflower oil · 1 l × 6').hitTestable(),
          findsOneWidget,
        );
        expect(
          work
              .workspaceReceiptDraft(shipment('A', revision: 2))!
              .lines
              .single
              .pack,
          '1 l × 12',
        );
        await showPurchase('B');
        expect(
          work.workspaceReceiptDraft(shipment('B'))!.countedPacks,
          isEmpty,
        );
        expect(work.currentWorkspaceOrderId, originalOrder);
        final restored = fresh();
        await tester.pumpWidget(const SizedBox.shrink());
        work = restored;
        feed(2);
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: scale == 1 ? const Size(412, 915) : const Size(320, 568),
          textScale: scale,
        );
        await reveal(tester, incoming);
        await tester.tap(incoming);
        await tester.pumpAndSettle();
        await showPurchase('A');
        final saved = work.workspaceReceiptDraft(shipment('A', revision: 2))!;
        expect(saved.counted('line-A'), 8);
        expect(saved.problems['line-A'], WorkspaceReceiptProblem.damaged);
        expect(saved.note, 'Two packs damaged at arrival.');
        expect(
          work.focusedWorkspacePurchase!.receiptState,
          WorkspaceReceiptState.awaiting,
        );
        expect(
          work.focusedWorkspacePurchase!.lines.single.receivedPacks,
          isNull,
        );
        expect(tester.takeException(), isNull);
      },
    );

    for (final scoped in [true, false]) {
      testWidgets(
        'R6617 ready does not claim delivery requested $scoped $scale',
        (tester) async {
          final gateway = _DeliveryBookingFixtureGateway();
          final work = storeViewFixture(gateway, _ContactDraftFixtureStore());
          final ready = work.currentWorkspaceOrder!.copyWith(
            stage: 'Ready',
            needsDelivery: true,
            fulfilment: 'Mool delivery',
            address: '12 Market Road, Test Area',
          );
          work.workspaceOrders[0] = ready;
          work.workspaceOrderStage = 'Ready';
          work.workspaceOrderNeedsDelivery = true;
          work.workspaceOrderFulfilment = ready.fulfilment;
          work.workspaceOrderAddress = ready.address;
          if (scoped) {
            final operations = WorkOrderOperations(
              accountScope: 'review-draft-account',
              workspaceId: work.activeWorkspace!.id,
              gateway: _OrderCommandFixtureGateway(),
            );
            expect(
              operations.observe(
                WorkOrderReply(
                  accountScope: operations.accountScope,
                  workspaceId: operations.workspaceId,
                  orderId: ready.id,
                  operationId: '',
                  revision: 1,
                  state: WorkOrderReplyState.applied,
                  order: ready,
                ),
              ),
              isTrue,
            );
            expect(work.bindWorkspaceOrderOperations(operations), isTrue);
          }
          final balances = (
            work.workspaceSalesToday,
            work.workspaceSettlementBalance,
          );
          await mount(
            tester,
            route: '/app/work/workspace/dashboard',
            work: work,
            viewport: scale == 1 ? const Size(412, 915) : const Size(320, 568),
            textScale: scale,
          );
          expect(find.text('Order ready'), findsOneWidget);
          expect(find.text('Awaiting a delivery partner'), findsNothing);
          expect(
            find.byKey(const Key('work-delivery-proof-pending')),
            findsNothing,
          );
          final button = find.byKey(const Key('work-delivery-arrange'));
          await reveal(tester, button);
          expect(button.hitTestable(), findsOneWidget);
          expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
          expect(tester.getSize(button).width, greaterThanOrEqualTo(48));
          final paragraph = tester.renderObject<RenderParagraph>(
            find.descendant(
              of: button,
              matching: find.text('Arrange delivery'),
            ),
          );
          expect(paragraph.textScaler.scale(1), closeTo(scale, .01));
          expect((paragraph.text as TextSpan).style!.fontFamily, 'Inter');
          for (final range in const [(0, 7), (8, 16)]) {
            expect(
              paragraph.getBoxesForSelection(
                TextSelection(baseOffset: range.$1, extentOffset: range.$2),
              ),
              hasLength(1),
              reason: 'Action words must not fragment across lines',
            );
          }
          final action = tester.widget<FilledButton>(button).onPressed;
          expect(gateway.requests, isEmpty);
          expect(work.workspaceDeliveryAssignment, isNull);
          expect(work.workspaceOrderStage, 'Ready');
          await captureStoreView(
            tester,
            'ready-before-delivery-$scoped-$scale',
          );
          if (scoped) {
            expect(action, isNull);
            await reveal(
              tester,
              find.byKey(const Key('work-delivery-booking-unavailable')),
            );
            expect(
              find
                  .byKey(const Key('work-delivery-booking-unavailable'))
                  .hitTestable(),
              findsOneWidget,
            );
            expect(work.currentWorkspaceOrder!.stage, 'Ready');
            expect(gateway.requests, isEmpty);
          } else {
            expect(action, isNotNull);
            await tester.tap(button);
            await tester.pump(const Duration(milliseconds: 400));
            action!(); // A delayed duplicate tap cannot book this order twice.
            expect(gateway.requests, hasLength(1));
            expect(gateway.requests.single, (
              store: work.activeWorkspace!.id,
              order: ready.id,
              address: ready.address,
            ));
            expect(work.workspaceOrderStage, 'Delivery requested');
            expect(
              find.byKey(const Key('work-delivery-arrange')),
              findsNothing,
            );
            gateway.response.complete(
              WorkDeliveryAssignmentResult(
                partnerName: 'Test rider',
                vehicleLabel: 'Bike',
                eta: DateTime.now().add(const Duration(minutes: 5)),
                stage: 'Assigned',
              ),
            );
            await tester.pumpAndSettle();
            expect(work.workspaceDeliveryAssignment!.orderId, ready.id);
            expect(find.text('Rider · Test rider'), findsOneWidget);
            expect(work.workspaceInvoices, isEmpty);
          }
          expect((
            work.workspaceSalesToday,
            work.workspaceSettlementBalance,
          ), balances);
          expect(work.currentWorkspaceOrderId, ready.id);
          expect(tester.takeException(), isNull);
        },
      );
    }

    for (final snapshotComplete in [true, false]) {
      testWidgets(
        'R6617 central order scroll and purchased snapshot $snapshotComplete $scale',
        (tester) async {
          final work = storeViewFixture();
          final originalOrder = work.workspaceOrders.first.copyWith(
            items: 'Purchased Sunflower Oil × 2',
            quantities: {'oil-fortune-1l': snapshotComplete ? 2 : 3},
            amount: 247,
            actionDeadline: DateTime.now().add(const Duration(minutes: 10)),
            itemSnapshots: const [
              WorkspaceOrderItemSnapshot(
                productId: 'oil-fortune-1l',
                name: 'Purchased Sunflower Oil',
                pack: '1 L sealed pouch',
                quantity: 2,
                unitPricePaise: 12345,
                lineTotalPaise: 24690,
              ),
            ],
          );
          work.workspaceOrders[0] = originalOrder;
          work.workspaceOrders.addAll(
            List.generate(
              999,
              (index) => customerOrder(
                id: 'SCROLL-$index',
                customer: 'Other customer $index',
                createdAt: DateTime.now(),
                stage: 'Preparing',
              ),
            ),
          );
          work.workspaceCatalogueItems[0] = work.workspaceCatalogueItems.first
              .copyWith(sellingPrice: 9999);
          final orders = List<WorkspaceOrderRecord>.of(work.workspaceOrders);
          final balances = (
            work.workspaceSalesToday,
            work.workspaceSettlementBalance,
          );
          await mount(
            tester,
            route: '/app/work/workspace/dashboard',
            work: work,
            viewport: scale == 1 ? const Size(360, 760) : const Size(320, 568),
            textScale: scale,
            bottomInset: 24,
          );
          final review = find.byKey(const Key('work-activity-order-review'));
          await reveal(tester, review);
          await tester.tap(review);
          await tester.pumpAndSettle();
          final exact = find.byKey(const Key('work-store-exact-order'));
          expect(exact, findsOneWidget);
          expect(
            find.byKey(const Key('work-store-activity-scroll')),
            findsNothing,
          );
          final scroll = find.descendant(
            of: exact,
            matching: find.byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            ),
          );
          expect(scroll, findsOneWidget);
          final viewport = tester.getRect(scroll);
          expect(viewport.height, greaterThan(40));
          final position = tester.state<ScrollableState>(scroll).position;
          Future<void> show(Finder target) async {
            for (
              var i = 0;
              i < 40 && target.hitTestable().evaluate().isEmpty;
              i++
            ) {
              await tester.dragFrom(
                viewport.center,
                Offset(0, -viewport.height * .55),
              );
              await tester.pumpAndSettle();
            }
            expect(target.hitTestable(), findsOneWidget);
          }

          await show(find.text('Ordered items'));
          await tester.dragFrom(
            viewport.center,
            Offset(0, -viewport.height * .55),
          );
          await tester.pumpAndSettle();
          expect(position.pixels, greaterThan(44));
          if (snapshotComplete) {
            await show(find.text('1 L sealed pouch'));
            await show(find.text('2 × ₹123.45'));
            expect(find.text('₹246.90'), findsOneWidget);
            expect(find.text('₹9,999'), findsNothing);
            expect(
              find.text('Ordered via'),
              findsNothing,
              reason: 'Central card already shows source once',
            );
          } else {
            await show(
              find.byKey(const Key('work-exact-order-prices-unavailable')),
            );
            expect(find.text('2 × ₹123.45'), findsNothing);
            expect(find.text('₹9,999'), findsNothing);
          }
          expect(
            find.byKey(const Key('work-activity-order-accept')).hitTestable(),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('work-activity-order-reject')).hitTestable(),
            findsOneWidget,
          );
          await captureStoreView(
            tester,
            'central-order-snapshot-$snapshotComplete-$scale',
          );
          await tester.tap(find.byKey(const Key('work-order-details-close')));
          await tester.pumpAndSettle();
          expect(exact, findsNothing);
          expect(work.workspaceOrders, orders);
          expect((
            work.workspaceSalesToday,
            work.workspaceSettlementBalance,
          ), balances);
          expect(work.currentWorkspaceOrderId, originalOrder.id);
          expect(work.workspaceInvoices, isEmpty);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('R6617 promotion draft survives Back and Store switch $scale', (
      tester,
    ) async {
      final work = storeViewFixture();
      final originalStore = work.activeWorkspace!;
      final originalDraft = work.workspaceOfferDraft;
      final end = DateUtils.dateOnly(
        DateTime.now(),
      ).add(const Duration(days: 7));
      originalDraft.addAll({
        'productId': work.workspaceCatalogueItems.first.id,
        'validUntil': end.toIso8601String(),
      });
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: scale == 1 ? const Size(412, 915) : const Size(320, 568),
        textScale: scale,
      );
      Future<void> openOffers() async {
        final action = find.byKey(const Key('work-quick-promote'));
        await reveal(tester, action);
        await tester.tap(action);
        await tester.pumpAndSettle();
      }

      Future<void> revealOfferField(Finder field) async {
        final form = find.byKey(const Key('work-store-offers-screen'));
        final scroll = tester.state<ScrollableState>(
          find.descendant(of: form, matching: find.byType(Scrollable)).first,
        );
        for (var i = 0; scroll.position.pixels > 0 && i < 30; i++) {
          final bounds = tester.getRect(form);
          await tester.dragFrom(
            Offset(bounds.left + 4, bounds.center.dy),
            const Offset(0, 200),
          );
          await tester.pumpAndSettle();
        }
        for (
          var attempt = 0;
          field.evaluate().isEmpty && attempt < 15;
          attempt++
        ) {
          final bounds = tester.getRect(
            find.byKey(const Key('work-store-offers-screen')),
          );
          await tester.dragFrom(
            Offset(bounds.left + 4, bounds.center.dy),
            const Offset(0, -140),
          );
          await tester.pumpAndSettle();
        }
        expect(field, findsOneWidget);
        await tester.ensureVisible(field);
        await tester.pumpAndSettle();
      }

      Future<void> enter(String key, String value) async {
        final field = find.byKey(Key(key));
        await revealOfferField(field);
        await tester.enterText(field, value);
        await tester.pumpAndSettle();
      }

      Future<void> check(String key, String value) async {
        final field = find.byKey(Key(key));
        await revealOfferField(field);
        expect(tester.widget<TextField>(field).controller!.text, value);
      }

      await openOffers();
      await enter('work-offer-title', 'Monthly basket saving');
      await enter(
        'work-offer-detail',
        'Save on selected essentials until Sunday.',
      );
      await enter('work-offer-order-cap', '27');
      tester.testTextInput.hide();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await openOffers();
      await check('work-offer-title', 'Monthly basket saving');
      await check(
        'work-offer-detail',
        'Save on selected essentials until Sunday.',
      );
      await check('work-offer-order-cap', '27');
      expect(originalDraft['validUntil'], end.toIso8601String());
      expect(originalDraft['productId'], work.workspaceCatalogueItems.first.id);
      await captureStoreView(tester, 'promotion-retained-$scale');
      work.activateWorkspace(
        const WorkWorkspace(
          id: 'promotion-other-store',
          name: 'Other Store',
          profileId: 'retailer-grocery',
          profileLabel: 'Grocery',
          area: 'Market',
          verified: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(identical(work.workspaceOfferDraft, originalDraft), isFalse);
      await check('work-offer-title', '');
      await enter('work-offer-title', 'Other Store offer');
      work.activateWorkspace(originalStore);
      await tester.pumpAndSettle();
      await check('work-offer-title', 'Monthly basket saving');
      await check(
        'work-offer-detail',
        'Save on selected essentials until Sunday.',
      );
      await check('work-offer-order-cap', '27');
      expect(work.workspaceOffers, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'R6617 promotion retained stale product and date recover $scale',
      (tester) async {
        final work = storeViewFixture();
        final oldDate = DateTime.now().subtract(const Duration(days: 2));
        work.workspaceOfferDraft.addAll({
          'title': 'Keep my headline',
          'detail': 'Keep my conditions',
          'orderCap': '27',
          'productId': 'removed-product',
          'validUntil': oldDate.toIso8601String(),
        });
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: scale == 1 ? const Size(412, 915) : const Size(320, 568),
          textScale: scale,
        );
        final promote = find.byKey(const Key('work-quick-promote'));
        await reveal(tester, promote);
        await tester.tap(promote);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<FilledButton>(find.byKey(const Key('work-offer-publish')))
              .onPressed,
          isNull,
        );
        final date = find.byKey(const Key('work-offer-valid-until'));
        await reveal(tester, date);
        await tester.tap(date);
        await tester.pumpAndSettle();
        expect(find.byType(DatePickerDialog), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          work.workspaceOfferDraft['validUntil'],
          oldDate.toIso8601String(),
        );
        expect(work.workspaceOfferDraft['productId'], 'removed-product');
        expect(work.workspaceOfferDraft['title'], 'Keep my headline');
        expect(work.workspaceOffers, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );

    for (final stamp in [
      DateTime.utc(2026, 12, 31, 20, 4),
      DateTime(2027, 1, 1, 1, 34),
    ]) {
      testWidgets(
        'R6617 supplier update uses local calendar ${stamp.isUtc} $scale',
        (tester) async {
          final work = storeViewFixture(null, _ContactDraftFixtureStore());
          final originalOrder = work.currentWorkspaceOrderId;
          final shipment = WorkspacePurchaseRecord(
            accountScope: 'review-draft-account',
            workspaceId: work.activeWorkspace!.id,
            supplierId: 'time-supplier',
            supplierName: 'Test Mandi',
            orderId: 'TIME-ORDER',
            shipmentId: 'TIME-SHIPMENT',
            revision: 1,
            createdAt: stamp.subtract(const Duration(hours: 1)),
            updatedAt: stamp,
            stage: WorkspaceSupplyStage.confirmed,
            amountMinor: 496000,
            itemSummary: 'Sunflower oil × 20',
            paymentLabel: 'Payment pending',
            lines: [],
          );
          expect(
            work.applyWorkspacePurchases(
              accountScope: 'review-draft-account',
              storeId: work.activeWorkspace!.id,
              feedRevision: 1,
              records: [shipment],
              complete: true,
            ),
            isTrue,
          );
          await mount(
            tester,
            route: '/app/work/workspace/dashboard',
            work: work,
            viewport: scale == 1 ? const Size(412, 915) : const Size(320, 568),
            textScale: scale,
          );
          await reveal(
            tester,
            find.byKey(const Key('work-incoming-purchases')),
          );
          await tester.tap(find.byKey(const Key('work-incoming-purchases')));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Test Mandi'));
          await tester.pumpAndSettle();
          final local = stamp.toLocal();
          final label =
              'Updated ${local.day}/${local.month}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
          final update = find.byKey(const Key('work-purchase-updated-at'));
          await reveal(tester, update);
          expect(tester.widget<Text>(update).data, label);
          expect(update.hitTestable(), findsOneWidget);
          // The Windows/OPPO qualification host uses India Standard Time. A UTC
          // timestamp crosses midnight/year here; local inputs must not shift twice.
          if (stamp.isUtc &&
              local.timeZoneOffset == const Duration(hours: 5, minutes: 30)) {
            expect(label, 'Updated 1/1/2027 01:34');
            expect(find.text('Updated 31/12/2026 20:04'), findsNothing);
          }
          await captureStoreView(
            tester,
            'supplier-local-time-${stamp.isUtc}-$scale',
          );
          expect(work.focusedWorkspacePurchase!.updatedAt, stamp);
          expect(
            work.focusedWorkspacePurchase!.paymentLabel,
            'Payment pending',
          );
          expect(
            work.focusedWorkspacePurchase!.stage,
            WorkspaceSupplyStage.confirmed,
          );
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(work.focusedWorkspacePurchaseId, isNull);
          expect(work.currentWorkspaceOrderId, originalOrder);
          expect(work.workspaceStockMovements, isEmpty);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets(
      'DASH07 eight supplier arrivals alongside 100 active orders $scale',
      (tester) async {
        final work = storeViewFixture(null, _ContactDraftFixtureStore());
        final originalOrder = work.currentWorkspaceOrderId;
        final storeId = work.activeWorkspace!.id;
        final now = DateTime.now();
        for (var i = 0; i < 99; i++) {
          work.workspaceOrders.add(
            customerOrder(
              id: 'BUSY-$i',
              customer: 'Customer $i · 9829012345',
              createdAt: now,
            ).copyWith(stage: 'Confirmed'),
          );
        }
        WorkspacePurchaseRecord shipment(
          int i, {
          int revision = 1,
          WorkspaceSupplyStage stage = WorkspaceSupplyStage.dispatched,
          int? received,
        }) => WorkspacePurchaseRecord(
          accountScope: 'review-draft-account',
          workspaceId: storeId,
          supplierId: 'supplier-$i',
          supplierName: 'Supplier $i',
          orderId: 'PO-$i',
          shipmentId: 'SHIP-$i',
          purchaseId: 'PURCHASE-${i ~/ 2}',
          revision: revision,
          createdAt: now,
          updatedAt: now.add(Duration(seconds: revision)),
          stage: stage,
          amountMinor: 1550050,
          itemSummary: 'Sunflower oil · 1 l × 100 packs',
          paymentLabel: 'Paid online',
          expectedArrival: 'Tomorrow, 10 am–12 pm',
          deliveryPartner: 'Delivery Partner $i',
          trackingReference: 'TRACK-$i',
          receiptState: received == null
              ? WorkspaceReceiptState.awaiting
              : WorkspaceReceiptState.partial,
          lines: [
            WorkspacePurchaseLine(
              id: 'LINE-$i',
              productId: 'same-oil-sku',
              name: 'Sunflower oil',
              pack: '1 l',
              orderedPacks: 100,
              receivedPacks: received,
              unitPriceMinor: 15500,
            ),
          ],
        );
        expect(
          work.applyWorkspacePurchases(
            accountScope: 'review-draft-account',
            storeId: storeId,
            feedRevision: 1,
            records: [for (var i = 0; i < 8; i++) shipment(i)],
            complete: true,
          ),
          isTrue,
        );
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: scale == 1 ? const Size(412, 915) : const Size(320, 568),
          textScale: scale,
        );
        expect(
          work.visibleWorkspaceOrders.where((order) => !order.isClosed),
          hasLength(100),
        );
        final incoming = find.byKey(const Key('work-incoming-purchases'));
        await reveal(tester, incoming);
        expect(find.text('8 incoming'), findsOneWidget);
        await captureStoreView(tester, 'supply-dashboard-$scale');
        await tester.tap(incoming);
        await tester.pumpAndSettle();
        expect(find.text('Incoming stock'), findsWidgets);
        expect(work.currentWorkspaceOrderId, originalOrder);
        await captureStoreView(tester, 'supply-first-view-$scale');
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await reveal(tester, find.byKey(const Key('work-store-stock')));
        await openTrackedPurchases(tester);
        expect(find.byKey(const Key('work-store-track-stock')), findsOneWidget);
        expect(find.byKey(const Key('work-shortcut-direct')), findsNothing);
        final tracking = find.byKey(const Key('work-shortcut-sourcing'));
        expect(tester.widget<TextButton>(tracking).onPressed, isNull);
        expect(work.currentWorkspaceOrderId, originalOrder);
        await captureStoreView(tester, 'track-stock-shortcut-populated-$scale');
        final row = find.byKey(const Key('work-purchase-open-SHIP-7'));
        await reveal(tester, row);
        await tester.tap(find.text('Supplier 7'));
        await tester.pumpAndSettle();
        expect(find.text('Order PO-7'), findsOneWidget);
        expect(find.text('Supplier 7'), findsOneWidget);
        await captureStoreView(tester, 'supply-exact-first-view-$scale');
        await reveal(tester, find.text('₹15,500.50'));
        expect(find.text('₹15,500.50'), findsOneWidget);
        await captureStoreView(tester, 'supply-exact-purchase-$scale');
        expect(
          work.applyWorkspacePurchases(
            accountScope: 'review-draft-account',
            storeId: storeId,
            feedRevision: 2,
            records: [
              shipment(0, revision: 2, stage: WorkspaceSupplyStage.cancelled),
              shipment(
                7,
                revision: 2,
                stage: WorkspaceSupplyStage.delivered,
                received: 60,
              ),
            ],
          ),
          isTrue,
        );
        await tester.pumpAndSettle();
        expect(work.focusedWorkspacePurchaseId, 'SHIP-7');
        expect(work.currentWorkspaceOrderId, originalOrder);
        final receipt = find.byKey(const Key('work-purchase-receipt-status'));
        await reveal(tester, receipt);
        expect(find.text('Part received'), findsOneWidget);
        await reveal(tester, find.text('40 packs outstanding'));
        await captureStoreView(tester, 'supply-partial-receipt-$scale');
        expect(work.workspaceStockMovements, isEmpty);
        expect(work.workspaceInvoices, isEmpty);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(work.focusedWorkspacePurchaseId, isNull);
        expect(row.hitTestable(), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-store-activity-deck')),
          findsOneWidget,
        );
        expect(work.currentWorkspaceOrderId, originalOrder);
        final statement = find.byKey(const Key('work-pulse-sales'));
        await reveal(tester, statement);
        await tester.tap(statement);
        await tester.pumpAndSettle();
        await reveal(tester, find.text('Purchases'));
        await tester.tap(find.text('Purchases'));
        await tester.pumpAndSettle();
        expect(
          tester
              .getSize(
                find.byKey(PageStorageKey('work-purchases-$storeId-true')),
              )
              .height,
          greaterThanOrEqualTo(140),
          reason:
              'Statement controls must leave usable room for purchase actions.',
        );
        await reveal(
          tester,
          find.byKey(const Key('work-purchase-open-SHIP-0')),
        );
        expect(
          find.byKey(const Key('work-purchase-open-SHIP-0')).hitTestable(),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('work-purchase-open-SHIP-0')));
        await tester.pumpAndSettle();
        expect(work.focusedWorkspacePurchaseId, 'SHIP-0');
        expect(
          find.byKey(const Key('work-purchase-stage')).hitTestable(),
          findsOneWidget,
        );
        expect(find.text('Store statement'), findsNothing);
        await captureStoreView(tester, 'supply-statement-first-view-$scale');
        await reveal(tester, find.byKey(const Key('work-purchase-stage')));
        expect(find.text('Cancelled'), findsOneWidget);
        await reveal(tester, find.text('Order PO-0'));
        expect(find.text('Order PO-0'), findsOneWidget);
        expect(
          work.focusedWorkspacePurchase!.stage,
          WorkspaceSupplyStage.cancelled,
        );
        expect(find.textContaining('Delivery estimate'), findsNothing);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(work.focusedWorkspacePurchaseId, isNull);
        expect(find.byKey(const Key('work-store-statement')), findsOneWidget);
        await tester.tap(find.byKey(const Key('work-purchase-open-SHIP-0')));
        await tester.pumpAndSettle();
        expect(work.focusedWorkspacePurchaseId, 'SHIP-0');
        expect(
          work.applyWorkspacePurchases(
            accountScope: 'review-draft-account',
            storeId: storeId,
            feedRevision: 3,
            records: [],
            complete: true,
          ),
          isTrue,
        );
        await tester.pumpAndSettle();
        await reveal(tester, find.text('Purchase update unavailable'));
        await captureStoreView(tester, 'supply-removed-purchase-$scale');
        expect(work.focusedWorkspacePurchase, isNull);
        expect(find.text('Cancelled'), findsNothing);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await reveal(tester, find.text('No linked purchases in this period'));
        expect(work.currentWorkspaceOrderId, originalOrder);
        expect(work.workspaceStockMovements, isEmpty);
        expect(work.workspaceInvoices, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'DASH09 response editor preserves unsent text Back and updated case $scale',
      (tester) async {
        final drafts = _IssueDraftFixtureStore();
        final work = storeViewFixture(
          null,
          _ContactDraftFixtureStore(),
          drafts,
        );
        final store = work.activeWorkspace!.id;
        work.workspaceOrders[0] = work.workspaceOrders[0].copyWith(
          quantities: const {'oil-fortune-1l': 1},
        );
        WorkspaceIssueRecord issue(int revision) => WorkspaceIssueRecord(
          accountScope: 'review-draft-account',
          workspaceId: store,
          id: 'DRAFT-CASE',
          referenceId: 'APP-1043',
          target: WorkspaceIssueTarget.customerOrder,
          kind: WorkspaceIssueKind.packingShortage,
          state: WorkspaceIssueState.retailerReview,
          revision: revision,
          updatedAt: DateTime(2026, 9, 10, 12, revision),
          reason: 'One sealed pack is damaged.',
          nextStep: 'Review the affected pack.',
          permittedResponses: const [
            WorkspaceIssueResponse.provideDetails,
            WorkspaceIssueResponse.declineRequest,
          ],
          lines: const [
            WorkspaceIssueLine(
              lineId: 'oil-fortune-1l',
              productId: 'oil-fortune-1l',
              name: 'Sunflower oil',
              pack: '1 l',
              orderedQuantity: 1,
              affectedQuantity: 1,
            ),
          ],
        );
        void apply(int revision) => expect(
          work.applyWorkspaceIssues(
            accountScope: 'review-draft-account',
            storeId: store,
            feedRevision: revision,
            records: [issue(revision)],
          ),
          isTrue,
        );
        apply(1);
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: scale == 1 ? const Size(412, 915) : const Size(320, 568),
          textScale: scale,
        );
        Future<void> show(Finder target) async {
          final scroll = find
              .descendant(
                of: find.byKey(const ValueKey('store-detail-APP-1043')),
                matching: find.byType(Scrollable),
              )
              .first;
          for (
            var i = 0;
            i < 35 && target.hitTestable().evaluate().isEmpty;
            i++
          ) {
            final rect = tester
                .getRect(scroll)
                .intersect(
                  tester.getRect(
                    find.byKey(const Key('work-workspace-dashboard')),
                  ),
                );
            expect(rect.height, greaterThan(40));
            final direction =
                target.evaluate().isNotEmpty &&
                    tester.getRect(target).center.dy < rect.center.dy
                ? 1.0
                : -1.0;
            await tester.dragFrom(
              Offset(rect.left + 2, rect.center.dy),
              Offset(0, direction * rect.height * .35),
            );
            await tester.pumpAndSettle();
          }
          expect(target.hitTestable(), findsOneWidget);
        }

        await reveal(
          tester,
          find.byKey(const Key('work-dashboard-review-issues')),
        );
        await tester.tap(find.byKey(const Key('work-dashboard-review-issues')));
        await tester.pumpAndSettle();
        final note = find.byKey(
          const Key('work-issue-response-note-DRAFT-CASE'),
        );
        final selector = find.byType(
          DropdownButtonFormField<WorkspaceIssueResponse>,
        );
        await show(selector);
        await tester.tap(selector);
        await tester.pumpAndSettle();
        await captureStoreView(tester, 'issue-draft-choices-$scale');
        await tester.tap(find.text('Decline request').last);
        await tester.pumpAndSettle();
        final selectedLabel = find.descendant(
          of: selector,
          matching: find.text('Decline request'),
        );
        final fieldRect = tester.getRect(selector);
        final labelRect = tester.getRect(selectedLabel);
        expect(labelRect.top, greaterThanOrEqualTo(fieldRect.top));
        expect(labelRect.bottom, lessThanOrEqualTo(fieldRect.bottom));
        expect(labelRect.right, lessThanOrEqualTo(fieldRect.right));
        await tester.ensureVisible(selector);
        await tester.pumpAndSettle();
        await captureStoreView(tester, 'issue-draft-selected-$scale');
        expect(
          work.workspaceIssueDraft(issue(1))?.response,
          WorkspaceIssueResponse.declineRequest,
        );
        expect(
          work
              .workspaceIssuesFor(
                WorkspaceIssueTarget.customerOrder,
                'APP-1043',
              )
              .single
              .state,
          WorkspaceIssueState.retailerReview,
          reason: 'Selecting a draft is not rejection',
        );
        await show(note);
        await tester.enterText(
          note,
          'The sealed pack is damaged. Please review.',
        );
        await tester.pumpAndSettle();
        expect(
          drafts.values.values.single.note,
          'The sealed pack is damaged. Please review.',
        );
        await captureStoreView(tester, 'issue-draft-edit-$scale');
        tester.view.viewInsets = const FakeViewPadding(bottom: 220);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        expect(
          find.text('Accept'),
          findsNothing,
          reason: 'Unrelated order decisions must not crowd the draft keyboard',
        );
        await show(note);
        expect(tester.takeException(), isNull);
        await captureStoreView(tester, 'issue-draft-keyboard-$scale');
        tester.view.viewInsets = FakeViewPadding.zero;
        tester.testTextInput.hide();
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-dashboard-review-issues')),
          findsOneWidget,
        );
        await reveal(
          tester,
          find.byKey(const Key('work-dashboard-review-issues')),
        );
        await tester.tap(find.byKey(const Key('work-dashboard-review-issues')));
        await tester.pumpAndSettle();
        await show(note);
        expect(
          tester.widget<TextField>(note).controller!.text,
          contains('sealed pack'),
        );
        apply(2);
        await tester.pumpAndSettle();
        final review = find.byKey(
          const Key('work-issue-review-update-DRAFT-CASE'),
        );
        // New content is inserted above the editor without changing typed text.
        await tester.ensureVisible(review);
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(note).readOnly, isTrue);
        await captureStoreView(tester, 'issue-draft-updated-$scale');
        await tester.tap(review);
        await tester.pumpAndSettle();
        expect(work.workspaceIssueDraft(issue(2))?.expectedRevision, 2);
        drafts.failWrite = true;
        await show(note);
        await tester.enterText(note, 'Preserve this when saving fails.');
        await tester.pumpAndSettle();
        tester.testTextInput.hide();
        FocusManager.instance.primaryFocus?.unfocus();
        final retry = find.text('Retry save');
        await show(retry);
        await captureStoreView(tester, 'issue-draft-save-error-$scale');
        drafts.failWrite = false;
        await tester.tap(retry);
        await tester.pumpAndSettle();
        expect(
          drafts.values.values.single.note,
          'Preserve this when saving fails.',
        );
        expect(work.workspaceOrders[0].stage, 'Confirmed');
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('DASH09 decline confirmation and response recovery fit $scale', (
      tester,
    ) async {
      final drafts = _IssueDraftFixtureStore();
      final journal = _IssueCommandFixtureStore();
      final gateway = _IssueResponseFixtureGateway();
      final work = storeViewFixture(
        null,
        _ContactDraftFixtureStore(),
        drafts,
        gateway,
        journal,
      );
      work.workspaceOrders[0] = work.workspaceOrders[0].copyWith(
        quantities: const {'oil-fortune-1l': 1},
      );
      final issue = WorkspaceIssueRecord(
        accountScope: 'review-draft-account',
        workspaceId: work.activeWorkspace!.id,
        id: 'REPLY-CASE',
        referenceId: 'APP-1043',
        target: WorkspaceIssueTarget.customerOrder,
        kind: WorkspaceIssueKind.packingShortage,
        state: WorkspaceIssueState.retailerReview,
        revision: 1,
        updatedAt: DateTime(2026, 9, 10, 12),
        reason: 'One sealed pack is damaged.',
        nextStep: 'Review the affected pack.',
        permittedResponses: const [WorkspaceIssueResponse.declineRequest],
        lines: const [
          WorkspaceIssueLine(
            lineId: 'oil-fortune-1l',
            productId: 'oil-fortune-1l',
            name: 'Sunflower oil',
            pack: '1 l',
            orderedQuantity: 1,
            affectedQuantity: 1,
          ),
        ],
      );
      drafts.values[issue.draftKey] = WorkspaceIssueDraft(
        key: issue.draftKey,
        referenceId: issue.referenceId,
        target: issue.target,
        expectedRevision: 1,
        response: WorkspaceIssueResponse.declineRequest,
        note: 'This pack was already replaced. Please review.',
      );
      expect(
        work.applyWorkspaceIssues(
          accountScope: issue.accountScope,
          storeId: issue.workspaceId,
          feedRevision: 1,
          records: [issue],
        ),
        isTrue,
      );
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: scale == 1 ? const Size(412, 915) : const Size(320, 568),
        textScale: scale,
      );
      Future<void> open() async {
        final entry = find.byKey(const Key('work-dashboard-review-issues'));
        await reveal(tester, entry);
        await tester.tap(entry);
        await tester.pumpAndSettle();
      }

      Future<void> show(Finder target) async {
        if (target.evaluate().isNotEmpty) {
          await tester.ensureVisible(target);
          await tester.pumpAndSettle();
        }
        final scroll = find
            .descendant(
              of: find.byKey(const ValueKey('store-detail-APP-1043')),
              matching: find.byType(Scrollable),
            )
            .first;
        for (
          var i = 0;
          i < 35 && target.hitTestable().evaluate().isEmpty;
          i++
        ) {
          final rect = tester
              .getRect(scroll)
              .intersect(
                tester.getRect(
                  find.byKey(const Key('work-workspace-dashboard')),
                ),
              );
          final direction =
              target.evaluate().isNotEmpty &&
                  tester.getRect(target).center.dy < rect.center.dy
              ? 1.0
              : -1.0;
          await tester.dragFrom(
            Offset(rect.left + 2, rect.center.dy),
            Offset(0, direction * rect.height * .35),
          );
          await tester.pumpAndSettle();
        }
        expect(target.hitTestable(), findsOneWidget);
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        final viewport = tester.getRect(scroll);
        final targetRect = tester.getRect(target);
        expect(targetRect.top, greaterThanOrEqualTo(viewport.top - .1));
        expect(targetRect.bottom, lessThanOrEqualTo(viewport.bottom + .1));
      }

      await open();
      final send = find.byKey(const Key('work-issue-send-response-REPLY-CASE'));
      await show(send);
      await captureStoreView(tester, 'issue-response-ready-$scale');
      await tester.tap(send);
      await tester.pumpAndSettle();
      final confirmation = find.byKey(
        const Key('work-issue-decline-confirmation'),
      );
      expect(confirmation, findsOneWidget);
      expect(find.text('Send decline').hitTestable(), findsOneWidget);
      expect(find.text('Keep editing').hitTestable(), findsOneWidget);
      final dialogRect = tester.getRect(
        find
            .descendant(of: confirmation, matching: find.byType(IntrinsicWidth))
            .first,
      );
      expect(dialogRect.height, lessThan(scale == 1 ? 260 : 460));
      expect(gateway.submitted, isEmpty);
      expect(tester.takeException(), isNull);
      await captureStoreView(tester, 'issue-response-confirm-$scale');
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(gateway.submitted, isEmpty);
      expect(
        work.workspaceIssueDraft(issue)?.note,
        contains('already replaced'),
      );
      await show(send);
      await tester.tap(send);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send decline'));
      await tester.pumpAndSettle();
      expect(gateway.submitted.length, 1);
      final firstCommand = gateway.submitted.single;
      gateway.result.complete(
        WorkIssueReply(
          key: firstCommand.key,
          operationId: firstCommand.operationId,
          commandDigest: firstCommand.digest,
          state: WorkIssueReplyState.rejected,
          error: WorkIssueResponseError.invalidDetails,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Check your response details and try again.'),
        findsOneWidget,
      );
      final note = find.byKey(const Key('work-issue-response-note-REPLY-CASE'));
      await show(note);
      drafts.failWrite = true;
      await tester.enterText(
        note,
        'Please check the replacement recorded for this order.',
      );
      await tester.pumpAndSettle();
      tester.testTextInput.hide();
      FocusManager.instance.primaryFocus?.unfocus();
      final retrySave = find.text('Retry save');
      await show(retrySave);
      expect(find.textContaining('Draft not saved'), findsOneWidget);
      await captureStoreView(
        tester,
        'issue-response-rejected-save-error-$scale',
      );
      drafts.failWrite = false;
      await tester.tap(retrySave);
      await tester.pumpAndSettle();
      expect(
        drafts.values[issue.draftKey]?.note,
        contains('replacement recorded'),
      );
      gateway.result = Completer<WorkIssueReply>();
      await show(send);
      await tester.tap(send);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send decline'));
      await tester.pumpAndSettle();
      expect(gateway.submitted.length, 2);
      final command = gateway.submitted.last;
      expect(command.operationId, isNot(firstCommand.operationId));
      expect(journal.values[issue.draftKey]?.command.digest, command.digest);
      gateway.result.completeError(StateError('fixture response lost'));
      await tester.pumpAndSettle();
      final check = find.byKey(
        const Key('work-issue-check-response-REPLY-CASE'),
      );
      await captureStoreView(tester, 'issue-response-before-check-$scale');
      expect(
        check,
        findsOneWidget,
        reason:
            'pending=${work.workspaceIssueResponse(issue)?.pending}; stage=${work.workspaceOrders[0].stage}; busy=${work.workspaceIssueResponseBusy(issue)}',
      );
      await show(check);
      expect(find.text('Check status'), findsOneWidget);
      expect(work.workspaceIssueMayRetrySend(issue), isFalse);
      await captureStoreView(tester, 'issue-response-uncertain-$scale');
      await tester.pageBack();
      await tester.pumpAndSettle();
      await open();
      await show(check);
      await tester.tap(check);
      await tester.pumpAndSettle();
      final receipt = find.byKey(
        const Key('work-issue-response-result-REPLY-CASE'),
      );
      await show(receipt);
      expect(
        find.text('Response sent. Waiting for the case update.'),
        findsOneWidget,
      );
      expect(find.textContaining('Not sent'), findsNothing);
      expect(gateway.reconciled.single.digest, command.digest);
      expect(gateway.submitted.length, 2);
      expect(work.workspaceOrders[0].stage, 'Confirmed');
      expect(work.workspaceInvoices, isEmpty);
      expect(work.workspaceStockMovements, isEmpty);
      expect(
        find.byKey(const Key('work-issue-response-note-REPLY-CASE')),
        findsNothing,
      );
      expect(
        tester
            .widget<Text>(
              find.byKey(const Key('work-issue-sent-note-REPLY-CASE')),
            )
            .data,
        command.draft.note,
      );
      expect(tester.takeException(), isNull);
      await captureStoreView(tester, 'issue-response-sent-$scale');
    });

    testWidgets(
      'DASH09 inline customer and supplier cases preserve exact order and Back $scale',
      (tester) async {
        final work = storeViewFixture(null, _ContactDraftFixtureStore());
        final storeId = work.activeWorkspace!.id;
        final originalOrder = work.currentWorkspaceOrderId;
        final now = DateTime.now();
        work.workspaceOrders[0] = work.workspaceOrders[0].copyWith(
          quantities: const {'oil-fortune-1l': 1},
        );
        work.workspaceOrders.add(
          customerOrder(id: 'RETURN-1', customer: 'Meena', createdAt: now),
        );
        work.workspaceOrders.add(
          customerOrder(
            id: 'SUB-1',
            customer: 'Asha',
            createdAt: now,
            stage: 'Preparing',
          ),
        );
        final purchase = WorkspacePurchaseRecord(
          accountScope: 'review-draft-account',
          workspaceId: storeId,
          supplierId: 'supplier-A',
          supplierName: 'Jodhpur Wholesale',
          orderId: 'PO-22',
          shipmentId: 'SHIP-22',
          revision: 1,
          createdAt: now,
          updatedAt: now,
          stage: WorkspaceSupplyStage.dispatched,
          amountMinor: 155500,
          itemSummary: 'Sunflower oil · 1 l × 10 packs',
          paymentLabel: 'Paid online',
          receiptState: WorkspaceReceiptState.partial,
          lines: const [
            WorkspacePurchaseLine(
              id: 'LINE-22',
              productId: 'oil-fortune-1l',
              name: 'Sunflower oil',
              pack: '1 l',
              orderedPacks: 10,
              receivedPacks: 8,
              unitPriceMinor: 15550,
            ),
          ],
        );
        expect(
          work.applyWorkspacePurchases(
            accountScope: 'review-draft-account',
            storeId: storeId,
            feedRevision: 1,
            records: [purchase],
            complete: true,
          ),
          isTrue,
        );
        WorkspaceIssueRecord issue(
          String id,
          String reference,
          WorkspaceIssueKind kind,
          WorkspaceIssueState state, {
          bool supplier = false,
          int revision = 1,
          String? resolution,
        }) => WorkspaceIssueRecord(
          accountScope: 'review-draft-account',
          workspaceId: storeId,
          id: id,
          referenceId: reference,
          target: supplier
              ? WorkspaceIssueTarget.supplierShipment
              : WorkspaceIssueTarget.customerOrder,
          kind: kind,
          state: state,
          revision: revision,
          updatedAt: now,
          reason: supplier
              ? 'Two packs arrived damaged.'
              : 'The sealed pack is damaged.',
          nextStep: supplier
              ? 'Keep the affected packs separate while the supplier reviews.'
              : state.closed
              ? 'The decision is available to the customer.'
              : 'Review the reported pack and its condition.',
          resolution: resolution,
          lines: [
            WorkspaceIssueLine(
              lineId: supplier ? 'LINE-22' : 'oil-fortune-1l',
              productId: 'oil-fortune-1l',
              name: 'Sunflower oil',
              pack: '1 l',
              orderedQuantity: supplier ? 10 : 1,
              affectedQuantity: supplier ? 2 : 1,
            ),
          ],
        );
        WorkspaceIssueRecord returned({
          int revision = 1,
          bool declined = false,
        }) => issue(
          'RETURN-CASE',
          'RETURN-1',
          WorkspaceIssueKind.returnRequest,
          declined
              ? WorkspaceIssueState.declined
              : WorkspaceIssueState.retailerReview,
          revision: revision,
          resolution: declined
              ? 'The reported item could not be verified against this order.'
              : null,
        );
        final replacement = issue(
          'SUB-CASE',
          'SUB-1',
          WorkspaceIssueKind.substitution,
          WorkspaceIssueState.customerReview,
        );
        final damaged = issue(
          'SUPPLIER-CASE',
          'SHIP-22',
          WorkspaceIssueKind.damagedItem,
          WorkspaceIssueState.supplierReview,
          supplier: true,
        );
        final activeIssue = issue(
          'ACTIVE-CASE',
          'APP-1043',
          WorkspaceIssueKind.packingShortage,
          WorkspaceIssueState.retailerReview,
        );
        bool apply(int revision, WorkspaceIssueRecord customer) =>
            work.applyWorkspaceIssues(
              accountScope: 'review-draft-account',
              storeId: storeId,
              feedRevision: revision,
              records: [customer, replacement, damaged, activeIssue],
            );
        expect(apply(1, returned()), isTrue);
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: scale == 1 ? const Size(412, 915) : const Size(320, 568),
          textScale: scale,
        );
        final dashboardReview = find.byKey(
          const Key('work-dashboard-review-issues'),
        );
        await reveal(tester, dashboardReview);
        await captureStoreView(tester, 'issue-dashboard-action-$scale');
        await tester.tap(dashboardReview);
        await tester.pumpAndSettle();
        if (scale == 2) {
          expect(
            tester
                .getSize(find.byKey(const Key('work-store-exact-order')))
                .width,
            greaterThan(280),
          );
          expect(
            find.byKey(const Key('work-dashboard-enlarged-scroll')),
            findsNothing,
          );
          expect(
            find.descendant(
              of: find.byKey(const Key('work-workspace-dashboard')),
              matching: find.byWidgetPredicate(
                (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
              ),
            ),
            findsOneWidget,
          );
        }
        await captureStoreView(tester, 'issue-dashboard-opened-$scale');
        final detailScroll = find
            .descendant(
              of: find.byKey(const ValueKey('store-detail-APP-1043')),
              matching: find.byType(Scrollable),
            )
            .first;
        final activeReason = find.byKey(
          const Key('work-issue-reason-ACTIVE-CASE'),
        );
        for (
          var attempt = 0;
          attempt < 25 && activeReason.hitTestable().evaluate().isEmpty;
          attempt++
        ) {
          final visible = tester
              .getRect(detailScroll)
              .intersect(
                tester.getRect(
                  find.byKey(const Key('work-workspace-dashboard')),
                ),
              );
          expect(visible.height, greaterThan(40));
          await tester.dragFrom(
            visible.center,
            Offset(0, -visible.height * .45),
          );
          await tester.pumpAndSettle();
        }
        expect(
          find.byKey(const Key('work-issue-reason-ACTIVE-CASE')).hitTestable(),
          findsOneWidget,
        );
        await captureStoreView(tester, 'issue-dashboard-first-tap-$scale');
        await reveal(tester, find.byKey(const Key('work-order-details-close')));
        await tester.tap(find.byKey(const Key('work-order-details-close')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-incoming-purchases')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('work-dashboard-search')));
        await tester.pumpAndSettle();
        final field = find.byKey(const Key('work-dashboard-search-field'));
        await tester.enterText(field, 'RETURN-1');
        await tester.pumpAndSettle();
        await reveal(
          tester,
          find.byKey(const Key('work-search-order-RETURN-1')),
        );
        await tester.tap(find.byKey(const Key('work-search-order-RETURN-1')));
        await tester.pumpAndSettle();
        final review = find.byKey(const Key('work-issue-review-RETURN-CASE'));
        await reveal(tester, review);
        await captureStoreView(tester, 'issue-customer-first-view-$scale');
        await tester.tap(review);
        await tester.pumpAndSettle();
        await reveal(
          tester,
          find.byKey(const Key('work-issue-reason-RETURN-CASE')),
        );
        await captureStoreView(tester, 'issue-customer-details-$scale');
        await reveal(
          tester,
          find.byKey(const Key('work-issue-actions-unavailable')),
        );
        expect(work.currentWorkspaceOrderId, originalOrder);
        expect(apply(2, returned(revision: 2, declined: true)), isTrue);
        await tester.pumpAndSettle();
        await reveal(
          tester,
          find.text(
            'The reported item could not be verified against this order.',
          ),
        );
        await captureStoreView(tester, 'issue-declined-reason-$scale');
        expect(
          work.workspaceOrders.firstWhere((o) => o.id == 'RETURN-1').stage,
          'Completed',
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(work.workspaceSearchQuery, 'RETURN-1');
        await tester.enterText(field, 'SUB-1');
        await tester.pumpAndSettle();
        await reveal(tester, find.byKey(const Key('work-search-order-SUB-1')));
        await tester.tap(find.byKey(const Key('work-search-order-SUB-1')));
        await tester.pumpAndSettle();
        final subReview = find.byKey(const Key('work-issue-review-SUB-CASE'));
        await reveal(tester, subReview);
        await tester.tap(subReview);
        await tester.pumpAndSettle();
        await reveal(
          tester,
          find.text(
            'Do not replace items without the customer’s confirmation.',
          ),
        );
        await captureStoreView(tester, 'issue-substitution-wait-$scale');
        expect(
          work.workspaceOrders.firstWhere((o) => o.id == 'SUB-1').stage,
          'Preparing',
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        final incoming = find.byKey(const Key('work-incoming-purchases'));
        await reveal(tester, incoming);
        await tester.tap(incoming);
        await tester.pumpAndSettle();
        final shipment = find.byKey(const Key('work-purchase-open-SHIP-22'));
        await reveal(tester, shipment);
        await tester.tap(find.text('Jodhpur Wholesale'));
        await tester.pumpAndSettle();
        final supplierReview = find.byKey(
          const Key('work-issue-review-SUPPLIER-CASE'),
        );
        await reveal(tester, supplierReview);
        await tester.tap(supplierReview);
        await tester.pumpAndSettle();
        await reveal(
          tester,
          find.byKey(const Key('work-issue-reason-SUPPLIER-CASE')),
        );
        await captureStoreView(tester, 'issue-supplier-details-$scale');
        work.markWorkspaceIssuesStale(
          accountScope: 'review-draft-account',
          storeId: storeId,
        );
        await tester.pumpAndSettle();
        await reveal(tester, find.byKey(const Key('work-issue-stale')));
        await captureStoreView(tester, 'issue-stale-$scale');
        expect(work.workspaceStockMovements, isEmpty);
        expect(work.workspaceInvoices, isEmpty);
        expect(work.workspaceSettlementRequested, 0);
        expect(work.workspacePurchases.single.lines.single.receivedPacks, 8);
        expect(work.currentWorkspaceOrderId, originalOrder);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(work.focusedWorkspacePurchaseId, isNull);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    for (final confirmed in [false, true]) {
      testWidgets(
        'R6617 statement tabs retain independent scoped scroll $confirmed $scale',
        (tester) async {
          final oldFatal = WidgetController.hitTestWarningShouldBeFatal;
          WidgetController.hitTestWarningShouldBeFatal = true;
          addTearDown(
            () => WidgetController.hitTestWarningShouldBeFatal = oldFatal,
          );
          final work = storeViewFixture(null, _ContactDraftFixtureStore());
          final now = DateTime.now();
          for (var i = 0; i < 80; i++) {
            work.workspaceOrders.add(
              customerOrder(
                id: 'SCROLL-${i.toString().padLeft(3, '0')}',
                customer: 'Customer $i',
                createdAt: now,
              ),
            );
          }
          if (confirmed) {
            expect(
              work.applyWorkspaceFinance(
                WorkspaceFinanceSnapshot(
                  accountScope: 'review-draft-account',
                  workspaceId: work.activeWorkspace!.id,
                  revision: 1,
                  asOf: now,
                  salesTodayMinor: 800000,
                  duesMinor: 0,
                  availableMinor: 800000,
                  heldMinor: 0,
                  requestedMinor: 0,
                  paidOutMinor: 0,
                  feesMinor: 0,
                  deliveryAdjustmentsMinor: 0,
                  refundsMinor: 0,
                  taxWithheldMinor: 0,
                  historyComplete: true,
                  payments: [
                    for (var i = 0; i < 80; i++)
                      WorkspacePaymentRecord(
                        orderId: 'SCROLL-${i.toString().padLeft(3, '0')}',
                        customerId: 'customer-$i',
                        customerName: 'Customer $i',
                        revision: 1,
                        updatedAt: now,
                        amountMinor: 10000,
                        paidMinor: 10000,
                        dueMinor: 0,
                        refundedMinor: 0,
                        state: WorkspacePaymentState.paid,
                        channel: WorkspacePaymentChannel.platform,
                      ),
                  ],
                  payouts: [],
                ),
              ),
              isTrue,
            );
          }
          final before = work.workspaceOrders
              .map((o) => (o.id, o.stage, o.amount))
              .toList();
          await mount(
            tester,
            route: '/app/work/workspace/dashboard',
            work: work,
            viewport: scale == 1 ? const Size(412, 915) : const Size(320, 568),
            textScale: scale,
          );
          await reveal(tester, find.byKey(const Key('work-pulse-sales')));
          await tester.tap(find.byKey(const Key('work-pulse-sales')));
          await tester.pumpAndSettle();
          Finder ledgerScroll() => find
              .descendant(
                of: find.byKey(const Key('work-store-statement')),
                matching: find.byWidgetPredicate(
                  (w) =>
                      w is Scrollable && w.axisDirection == AxisDirection.down,
                ),
              )
              .first;
          double offset() =>
              tester.state<ScrollableState>(ledgerScroll()).position.pixels;
          await tester.drag(ledgerScroll(), const Offset(0, -700));
          await tester.pumpAndSettle();
          final salesOffset = offset();
          expect(salesOffset, greaterThan(200));
          for (final tab in ['purchases', 'expenses']) {
            await tester.tap(find.byKey(Key('work-statement-$tab')));
            await tester.pumpAndSettle();
            expect(
              offset(),
              0,
              reason: '$tab must not inherit the Sales offset',
            );
            await tester.tap(find.byKey(const Key('work-statement-sales')));
            await tester.pumpAndSettle();
            expect(offset(), closeTo(salesOffset, 1));
          }
          await captureStoreView(tester, 'statement-return-$confirmed-$scale');
          if (confirmed) {
            final details = find.byType(ExpansionTile).first;
            final detailKey = tester.widget<ExpansionTile>(details).key!;
            final header = find.descendant(
              of: find.byKey(detailKey),
              matching: find.text('Order details'),
            );
            await reveal(tester, header);
            await tester.tap(header);
            await tester.pumpAndSettle();
            final element = tester.element(find.byKey(detailKey));
            expect(PageStorage.of(element).readState(element), isTrue);
            await tester.tap(find.byKey(const Key('work-statement-expenses')));
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const Key('work-statement-sales')));
            await tester.pumpAndSettle();
            await reveal(tester, header);
            final restored = tester.element(find.byKey(detailKey));
            expect(PageStorage.of(restored).readState(restored), isTrue);
            // Collapse and return to the exact offset used by period/Back checks.
            await tester.tap(header);
            await tester.pumpAndSettle();
            expect(PageStorage.of(restored).readState(restored), isFalse);
            tester
                .state<ScrollableState>(ledgerScroll())
                .position
                .jumpTo(salesOffset);
            await tester.pumpAndSettle();
          }
          await tester.tap(find.byKey(const Key('work-statement-period')));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Week').last);
          await tester.pumpAndSettle();
          expect(
            offset(),
            0,
            reason: 'A different period starts at its own position',
          );
          await tester.drag(ledgerScroll(), const Offset(0, -350));
          await tester.pumpAndSettle();
          final weekOffset = offset();
          expect(weekOffset, greaterThan(100));
          await tester.tap(find.byKey(const Key('work-statement-period')));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Today').last);
          await tester.pumpAndSettle();
          expect(offset(), closeTo(salesOffset, 1));
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          await reveal(tester, find.byKey(const Key('work-pulse-sales')));
          await tester.tap(find.byKey(const Key('work-pulse-sales')));
          await tester.pumpAndSettle();
          expect(
            offset(),
            closeTo(salesOffset, 1),
            reason: 'Back and reopening retains the same ledger position',
          );
          expect(
            work.workspaceOrders.map((o) => (o.id, o.stage, o.amount)),
            before,
          );
          expect(work.workspaceStockMovements, isEmpty);
          expect(work.workspaceInvoices, isEmpty);
          expect(work.workspaceSettlementRequested, 0);
          final originalStore = work.activeWorkspace!;
          work.activateWorkspace(
            WorkWorkspace(
              id: 'STATEMENT-OTHER-STORE',
              name: 'Other store',
              profileId: originalStore.profileId,
              profileLabel: originalStore.profileLabel,
              area: originalStore.area,
              verified: true,
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('work-store-statement')), findsOneWidget);
          expect(
            offset(),
            0,
            reason: 'Another Store never inherits this ledger position',
          );
          expect(find.text('Customer 0'), findsNothing);
          work.activateWorkspace(originalStore);
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('work-store-statement')), findsOneWidget);
          expect(offset(), closeTo(salesOffset, 1));
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets(
      'DASH08 finance first taps keep 25 payment updates separate from 100 orders $scale',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          final work = storeViewFixture(null, _ContactDraftFixtureStore());
          final now = DateTime.now();
          final originalOrder = work.currentWorkspaceOrderId;
          for (var i = 1; i < 100; i++) {
            work.workspaceOrders.add(
              customerOrder(
                id: 'FIN-${i.toString().padLeft(2, '0')}',
                customer: 'Customer $i',
                createdAt: now,
              ).copyWith(stage: 'Preparing'),
            );
          }
          final states = work.workspaceOrders
              .map((o) => (o.id, o.stage))
              .toList();
          WorkspaceFinanceSnapshot snapshot(
            int revision, {
            bool paid = false,
            int availableMinor = 1000000000050,
          }) => WorkspaceFinanceSnapshot(
            accountScope: 'review-draft-account',
            workspaceId: work.activeWorkspace!.id,
            revision: revision,
            asOf: now,
            salesTodayMinor: 1000000000050,
            duesMinor: paid ? 0 : 46825,
            availableMinor: availableMinor,
            heldMinor: 75025,
            requestedMinor: paid ? 0 : 100000,
            paidOutMinor: paid ? 100000 : 0,
            feesMinor: 1025,
            deliveryAdjustmentsMinor: -525,
            refundsMinor: 0,
            taxWithheldMinor: 5000,
            payments: [
              for (var i = 0; i < 25; i++)
                WorkspacePaymentRecord(
                  orderId: i == 0
                      ? 'APP-1043'
                      : 'FIN-${i.toString().padLeft(2, '0')}',
                  customerId: 'customer-$i',
                  customerName: i == 0 ? 'Rakesh' : 'Customer $i',
                  revision: revision,
                  updatedAt: now,
                  amountMinor: 146800,
                  paidMinor: paid || i != 0 ? 146800 : 99975,
                  dueMinor: paid || i != 0 ? 0 : 46825,
                  refundedMinor: 0,
                  state: paid || i != 0
                      ? WorkspacePaymentState.paid
                      : WorkspacePaymentState.partPaid,
                  channel: i == 0
                      ? WorkspacePaymentChannel.platform
                      : i.isEven
                      ? WorkspacePaymentChannel.cash
                      : WorkspacePaymentChannel.directUpi,
                  invoiceId: 'INV-$i',
                  transactionId: 'TX-$i',
                ),
            ],
            payouts: [
              WorkspacePayoutRecord(
                id: 'SET-A',
                operationId: 'SET-OP-A',
                revision: revision,
                amountMinor: 100000,
                updatedAt: now,
                state: paid
                    ? WorkspacePayoutState.paid
                    : WorkspacePayoutState.processing,
                bankLabel: 'Bank · •••• 4321',
                expectedBy: '12 September',
              ),
              WorkspacePayoutRecord(
                id: 'SET-B',
                operationId: 'SET-OP-B',
                revision: revision,
                amountMinor: 50025,
                updatedAt: now,
                state: WorkspacePayoutState.failed,
                message: 'Receiving account needs review.',
              ),
            ],
          );
          expect(
            work.applyWorkspaceFinance(snapshot(1, availableMinor: 9999999)),
            isTrue,
          );
          await mount(
            tester,
            route: '/app/work/workspace/dashboard',
            work: work,
            viewport: scale == 1 ? const Size(412, 915) : const Size(320, 568),
            textScale: scale,
          );
          expectFinanceActionWords(tester);
          await reveal(tester, find.byKey(const Key('work-pulse-settlement')));
          await captureStoreView(tester, 'finance-paise-boundary-$scale');
          expect(work.applyWorkspaceFinance(snapshot(2)), isTrue);
          await tester.pumpAndSettle();
          expectFinanceActionWords(tester);
          await captureStoreView(tester, 'finance-dashboard-$scale');
          await reveal(tester, find.byKey(const Key('work-pulse-settlement')));
          final pulseText = tester
              .widgetList<Text>(
                find.descendant(
                  of: find.byKey(const Key('work-pulse-settlement')),
                  matching: find.byType(Text),
                ),
              )
              .map((w) => w.data ?? '')
              .toList();
          expect(
            pulseText.any(
              (t) => t.contains('≈') && t.contains('1,000') && t.contains('cr'),
            ),
            isTrue,
          );
          expect(
            pulseText.any((t) => t.contains('10,00,00,00,000.50')),
            isFalse,
          );
          expect(
            find.bySemanticsLabel(
              RegExp(r'Settle, Available, ₹10,00,00,00,000\.50'),
            ),
            findsOneWidget,
          );
          await tester.tap(find.byKey(const Key('work-pulse-settlement')));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('work-finance-settlement')),
            findsOneWidget,
          );
          await captureStoreView(
            tester,
            'finance-settlement-first-view-$scale',
          );
          await reveal(tester, find.text('₹10,00,00,00,000.50'));
          expect(find.text('₹10,00,00,00,000.50'), findsOneWidget);
          await captureStoreView(tester, 'finance-full-amount-$scale');
          if (scale == 2) {
            final amountScroll = find
                .ancestor(
                  of: find.text('₹10,00,00,00,000.50'),
                  matching: find.byWidgetPredicate(
                    (w) =>
                        w is Scrollable &&
                        w.axisDirection == AxisDirection.right,
                  ),
                )
                .first;
            await tester.drag(amountScroll, const Offset(-400, 0));
            await tester.pumpAndSettle();
            final position = tester
                .state<ScrollableState>(amountScroll)
                .position;
            expect(position.pixels, position.maxScrollExtent);
            final amountSemantics = find
                .ancestor(
                  of: amountScroll,
                  matching: find.byWidgetPredicate(
                    (w) =>
                        w is Semantics &&
                        w.properties.label == '₹10,00,00,00,000.50',
                  ),
                )
                .first;
            expect(
              tester.getSemantics(amountSemantics).getSemanticsData().label,
              contains('₹10,00,00,00,000.50'),
            );
            await captureStoreView(tester, 'finance-full-amount-end-$scale');
          }
          await reveal(tester, find.text('Request settlement'));
          expect(
            tester
                .widget<FilledButton>(
                  find.ancestor(
                    of: find.text('Request settlement'),
                    matching: find.byType(FilledButton),
                  ),
                )
                .onPressed,
            isNull,
          );
          await reveal(tester, find.text('−₹5.25'));
          await captureStoreView(tester, 'finance-signed-adjustment-$scale');
          await reveal(
            tester,
            find.byKey(const Key('work-finance-payout-SET-B')),
          );
          expect(find.text('SET-B · Payout failed'), findsOneWidget);
          await captureStoreView(tester, 'finance-payout-failed-$scale');
          await reveal(
            tester,
            find.byKey(const Key('work-finance-payment-APP-1043')),
          );
          expect(find.text('Part paid'), findsOneWidget);
          await captureStoreView(tester, 'finance-exact-payment-$scale');
          expect(work.workspaceOrders.map((o) => (o.id, o.stage)), states);
          expect(work.currentWorkspaceOrderId, originalOrder);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          await reveal(tester, find.byKey(const Key('work-pulse-dues')));
          await tester.tap(find.byKey(const Key('work-pulse-dues')));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('work-finance-dues')), findsOneWidget);
          await reveal(
            tester,
            find.byKey(const Key('work-finance-payment-APP-1043')),
          );
          await captureStoreView(tester, 'finance-dues-$scale');
          work.markWorkspaceFinanceStale(
            accountScope: 'review-draft-account',
            storeId: work.activeWorkspace!.id,
          );
          await tester.pumpAndSettle();
          await reveal(tester, find.byKey(const Key('work-finance-stale')));
          await captureStoreView(tester, 'finance-stale-$scale');
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          for (final key in [
            'work-pulse-sales',
            'work-pulse-dues',
            'work-pulse-settlement',
          ]) {
            final pulse = find.byKey(Key(key));
            await reveal(tester, pulse);
            expect(
              find.descendant(of: pulse, matching: find.text('Last update')),
              findsOneWidget,
              reason: key,
            );
            expect(
              find.descendant(of: pulse, matching: find.text('—')),
              findsNothing,
              reason: 'Retain the confirmed amount for $key',
            );
          }
          expectFinanceActionWords(tester);
          await captureStoreView(tester, 'finance-stale-pulse-$scale');
          await reveal(tester, find.byKey(const Key('work-pulse-sales')));
          await captureStoreView(tester, 'finance-stale-pulse-leading-$scale');
          await reveal(tester, find.byKey(const Key('work-pulse-dues')));
          await tester.tap(find.byKey(const Key('work-pulse-dues')));
          await tester.pumpAndSettle();
          expect(work.applyWorkspaceFinance(snapshot(3, paid: true)), isTrue);
          await tester.pumpAndSettle();
          expect(work.workspaceFinance!.duesMinor, 0);
          expect(
            find.byKey(const Key('work-finance-payment-APP-1043')),
            findsNothing,
          );
          expect(work.workspaceFinanceStale, isFalse);
          expect(work.workspaceOrders.map((o) => (o.id, o.stage)), states);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          final duesPulse = find.byKey(const Key('work-pulse-dues'));
          await reveal(tester, duesPulse);
          expect(
            find.descendant(of: duesPulse, matching: find.text('₹0')),
            findsOneWidget,
          );
          expect(
            find.descendant(of: duesPulse, matching: find.text('Unpaid bills')),
            findsOneWidget,
          );
          await reveal(tester, find.byKey(const Key('work-pulse-sales')));
          await tester.tap(find.byKey(const Key('work-pulse-sales')));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('work-finance-payments')),
            findsOneWidget,
          );
          await reveal(
            tester,
            find.byKey(const Key('work-finance-payment-APP-1043')),
          );
          expect(find.text('Paid through MoolSocial'), findsOneWidget);
          await captureStoreView(tester, 'finance-statement-$scale');
          await reveal(
            tester,
            find.byKey(
              PageStorageKey((
                'work-finance-order-details',
                'review-draft-account',
                work.activeWorkspace!.id,
                'payments',
                'APP-1043',
              )),
            ),
          );
          await tester.tap(find.text('Order details').first);
          await tester.pumpAndSettle();
          await reveal(tester, find.text('Receive by'));
          await captureStoreView(tester, 'finance-order-details-$scale');
          expect(work.currentWorkspaceOrderId, originalOrder);
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      },
    );

    testWidgets(
      'DASH08 live unavailable finance never displays a false zero balance $scale',
      (tester) async {
        final work = storeViewFixture(
          const UnavailableWorkGateway(),
          _ContactDraftFixtureStore(),
        );
        final orderBefore = work.currentWorkspaceOrderId;
        final invoicesBefore = work.workspaceInvoices.length;
        final movementsBefore = work.workspaceStockMovements.length;
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: scale == 1 ? const Size(412, 915) : const Size(320, 568),
          textScale: scale,
        );
        for (final key in [
          'work-pulse-sales',
          'work-pulse-dues',
          'work-pulse-settlement',
        ]) {
          final pulse = find.byKey(Key(key));
          await reveal(tester, pulse);
          expect(
            find.descendant(of: pulse, matching: find.text('Update pending')),
            findsOneWidget,
            reason: key,
          );
          expect(
            find.descendant(of: pulse, matching: find.text('—')),
            findsOneWidget,
            reason: 'Unavailable $key must not infer a balance',
          );
          final semantics = tester.widget<Semantics>(
            find
                .ancestor(
                  of: pulse,
                  matching: find.byWidgetPredicate(
                    (widget) =>
                        widget is Semantics && widget.properties.button == true,
                  ),
                )
                .first,
          );
          expect(semantics.properties.label, contains('amount unavailable'));
        }
        expectFinanceActionWords(tester);
        await captureStoreView(tester, 'finance-unavailable-pulse-$scale');
        await reveal(tester, find.byKey(const Key('work-pulse-sales')));
        await captureStoreView(
          tester,
          'finance-unavailable-pulse-leading-$scale',
        );
        await reveal(tester, find.byKey(const Key('work-pulse-settlement')));
        await tester.tap(find.byKey(const Key('work-pulse-settlement')));
        await tester.pumpAndSettle();
        expect(find.text('Payment updates unavailable'), findsOneWidget);
        expect(find.text('₹0'), findsNothing);
        await captureStoreView(tester, 'finance-unavailable-$scale');
        expect(find.text('Request settlement'), findsNothing);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('work-store-activity-deck')),
          findsOneWidget,
        );
        for (final key in ['work-pulse-sales', 'work-pulse-dues']) {
          final pulse = find.byKey(Key(key));
          await reveal(tester, pulse);
          await tester.tap(pulse);
          await tester.pumpAndSettle();
          expect(find.text('Payment updates unavailable'), findsOneWidget);
          expect(find.text('₹0'), findsNothing);
          await captureStoreView(tester, 'finance-unavailable-$key-$scale');
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
        }
        expect(work.currentWorkspaceOrderId, orderBefore);
        expect(work.workspaceInvoices.length, invoicesBefore);
        expect(work.workspaceStockMovements.length, movementsBefore);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'DASH07 unavailable purchases never import personal Buy history $scale',
      (tester) async {
        final work = storeViewFixture();
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: scale == 1 ? const Size(412, 915) : const Size(320, 568),
          textScale: scale,
        );
        await reveal(tester, find.byKey(const Key('work-incoming-purchases')));
        await tester.tap(find.byKey(const Key('work-incoming-purchases')));
        await tester.pumpAndSettle();
        expect(find.text('Purchase updates unavailable'), findsOneWidget);
        expect(find.text('0 incoming'), findsNothing);
        expect(work.workspacePurchasesConnected, isFalse);
        await reveal(
          tester,
          find.text(
            'Linked supplier purchases will appear here. Personal purchases stay separate.',
          ),
        );
        await captureStoreView(tester, 'supply-unavailable-$scale');
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await reveal(tester, find.byKey(const Key('work-pulse-sales')));
        await tester.tap(find.byKey(const Key('work-pulse-sales')));
        await tester.pumpAndSettle();
        await reveal(tester, find.text('Purchases'));
        await tester.tap(find.text('Purchases'));
        await tester.pumpAndSettle();
        await reveal(tester, find.text('Purchase updates unavailable'));
        await captureStoreView(tester, 'supply-statement-unavailable-$scale');
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('DASH07 reused Buy tracking stays in Store $scale', (
      tester,
    ) async {
      final work = storeViewFixture(null, _ContactDraftFixtureStore());
      final storeId = work.activeWorkspace!.id;
      final originalCustomerOrder = work.currentWorkspaceOrderId;
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: scale == 1 ? const Size(412, 915) : const Size(320, 568),
        textScale: scale,
      );
      final buy = tester
          .widget<WorkWorkspaceDashboardScreen>(
            find.byType(WorkWorkspaceDashboardScreen),
          )
          .procurementSession;
      final order = buy.orders.firstWhere(
        (order) => order.destination == BuyV2Destination.wholesale,
      );
      final now = DateTime.now();
      final linked = WorkspacePurchaseRecord.fromBuyOrder(
        order: order,
        accountScope: 'review-draft-account',
        workspaceId: storeId,
        supplierId: 'verified-supplier-workspace',
        revision: 1,
        createdAt: now,
        updatedAt: now,
      );
      expect(
        work.applyWorkspacePurchases(
          accountScope: linked.accountScope,
          storeId: storeId,
          feedRevision: 1,
          records: [linked],
          complete: true,
        ),
        isTrue,
      );
      final cartProduct = buy.visibleProducts.first;
      expect(buy.addProduct(cartProduct.id), isTrue);
      final cartBefore = buy.quantityFor(cartProduct.id);
      final totalBefore = buy.cartTotal;
      final filterBefore = buy.selectedFilter;
      await reveal(tester, find.byKey(const Key('work-incoming-purchases')));
      await tester.tap(find.byKey(const Key('work-incoming-purchases')));
      await tester.pumpAndSettle();
      final track = find.byKey(
        ValueKey('work-purchase-open-${linked.shipmentId}'),
      );
      await reveal(tester, track);
      await tester.tap(track);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-v2-screen')), findsOneWidget);
      expect(buy.view, BuyV2View.tracking);
      expect(buy.selectedOrderId, linked.orderId);
      expect(work.currentWorkspaceOrderId, originalCustomerOrder);
      expect(work.workspaceStockMovements, isEmpty);
      expect(work.workspaceInvoices, isEmpty);
      await captureStoreView(tester, 'supply-reused-tracking-$scale');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-v2-screen')), findsNothing);
      expect(
        find.byKey(PageStorageKey('work-purchases-$storeId-false')),
        findsOneWidget,
      );
      expect(buy.quantityFor(cartProduct.id), cartBefore);
      expect(buy.cartTotal, totalBefore);
      expect(buy.selectedFilter, filterBefore);
      expect(work.currentWorkspaceOrderId, originalCustomerOrder);
      expect(track.hitTestable(), findsOneWidget);
      await reveal(tester, track);
      await tester.tap(track);
      await tester.pumpAndSettle();
      work.activeWorkspace = const WorkWorkspace(
        id: 'other-store',
        name: 'Second Store',
        profileId: 'retailer-grocery',
        profileLabel: 'Grocery',
        area: 'Market',
        verified: true,
      );
      expect(
        work.applyWorkspacePurchases(
          accountScope: linked.accountScope,
          storeId: 'other-store',
          feedRevision: 1,
          records: const [],
          complete: true,
        ),
        isTrue,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-v2-screen')), findsNothing);
      expect(find.text('Purchase tracking unavailable'), findsOneWidget);
      if (scale == 1) {
        expect(
          tester
              .getSize(find.byKey(const Key('work-tracking-unavailable')))
              .height,
          lessThan(300),
        );
      }
      await captureStoreView(tester, 'supply-tracking-scope-changed-$scale');
      final returnAction = find.byKey(
        const Key('work-tracking-unavailable-action'),
      );
      await reveal(tester, returnAction);
      expect(returnAction.hitTestable(), findsOneWidget);
      await tester.tap(returnAction);
      await tester.pumpAndSettle();
      expect(
        find.byKey(PageStorageKey('work-purchases-other-store-false')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('buy-v2-screen')), findsNothing);
      expect(work.workspacePurchases, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  for (final mismatch in [
    'missing-order',
    'retail-order',
    'purchase',
    'shipment',
  ]) {
    testWidgets('DASH07 tracking refuses $mismatch', (tester) async {
      final work = storeViewFixture(null, _ContactDraftFixtureStore());
      final storeId = work.activeWorkspace!.id;
      await mount(tester, route: '/app/work/workspace/dashboard', work: work);
      final buy = tester
          .widget<WorkWorkspaceDashboardScreen>(
            find.byType(WorkWorkspaceDashboardScreen),
          )
          .procurementSession;
      final order = buy.orders.firstWhere(
        (order) =>
            order.destination ==
            (mismatch == 'retail-order'
                ? BuyV2Destination.shop
                : BuyV2Destination.wholesale),
      );
      final orderId = mismatch == 'missing-order' ? 'UNLINKED' : order.id;
      final now = DateTime.now();
      final record = WorkspacePurchaseRecord(
        accountScope: 'review-draft-account',
        workspaceId: storeId,
        supplierId: 'supplier-A',
        supplierName: 'Supplier A',
        orderId: orderId,
        shipmentId: mismatch == 'shipment' ? '$orderId-part-2' : orderId,
        purchaseId: mismatch == 'purchase'
            ? 'different-purchase'
            : order.purchaseId,
        revision: 1,
        createdAt: now,
        updatedAt: now,
        stage: WorkspaceSupplyStage.dispatched,
        amountMinor: 15500,
        itemSummary: 'Sunflower oil',
        paymentLabel: 'Payment update unavailable',
        lines: const [],
      );
      expect(
        work.applyWorkspacePurchases(
          accountScope: record.accountScope,
          storeId: storeId,
          feedRevision: 1,
          records: [record],
          complete: true,
        ),
        isTrue,
      );
      final originalBuyOrder = buy.selectedOrderId;
      final originalStoreOrder = work.currentWorkspaceOrderId;
      await reveal(tester, find.byKey(const Key('work-incoming-purchases')));
      await tester.tap(find.byKey(const Key('work-incoming-purchases')));
      await tester.pumpAndSettle();
      final track = find.byKey(
        ValueKey('work-purchase-open-${record.shipmentId}'),
      );
      await reveal(tester, track);
      await tester.tap(track);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-v2-screen')), findsNothing);
      expect(
        find.byKey(PageStorageKey('work-purchases-$storeId-false')),
        findsOneWidget,
      );
      expect(buy.selectedOrderId, originalBuyOrder);
      expect(work.currentWorkspaceOrderId, originalStoreOrder);
      expect(work.workspaceStockMovements, isEmpty);
      expect(work.workspaceInvoices, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  for (final (scale, change) in [
    for (final scale in [1.0, 2.0])
      for (final change in ['removed', 'purchase', 'retail']) (scale, change),
  ]) {
    testWidgets(
      'DASH07 active tracking revalidates Buy-only updates $scale $change',
      (tester) async {
        final work = storeViewFixture(null, _ContactDraftFixtureStore());
        final core = BuySession();
        final buy = _TrackingOrdersFixture(core: core);
        final storeId = work.activeWorkspace!.id;
        final originalCustomerOrder = work.currentWorkspaceOrderId;
        final router = GoRouter(
          initialLocation: '/app/work/workspace/dashboard',
          routes: [
            GoRoute(
              path: '/app/work/workspace/dashboard',
              builder: (context, state) => WorkWorkspaceDashboardScreen(
                session: work,
                procurementSession: buy,
                accountAuthenticated: true,
              ),
            ),
          ],
        );
        addTearDown(router.dispose);
        addTearDown(work.dispose);
        addTearDown(buy.dispose);
        addTearDown(core.dispose);
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = scale == 1
            ? const Size(412, 915)
            : const Size(320, 568);
        tester.view.viewPadding = const FakeViewPadding(bottom: 44);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final order = buy.orders.firstWhere(
          (order) => order.destination == BuyV2Destination.wholesale,
        );
        final now = DateTime.now();
        final linked = WorkspacePurchaseRecord.fromBuyOrder(
          order: order,
          accountScope: 'review-draft-account',
          workspaceId: storeId,
          supplierId: 'verified-supplier-workspace',
          revision: 1,
          createdAt: now,
          updatedAt: now,
        );
        expect(
          work.applyWorkspacePurchases(
            accountScope: linked.accountScope,
            storeId: storeId,
            feedRevision: 1,
            records: [linked],
            complete: true,
          ),
          isTrue,
        );
        final product = buy.visibleProducts.first;
        expect(buy.addProduct(product.id), isTrue);
        final quantity = buy.quantityFor(product.id);
        final total = buy.cartTotal;
        await tester.pumpWidget(
          RepaintBoundary(
            key: const Key('store-review-root'),
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: MoolTheme.light(),
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final purchases = find.byKey(const Key('work-incoming-purchases'));
        await reveal(tester, purchases);
        await tester.tap(purchases);
        await tester.pumpAndSettle();
        final track = find.byKey(
          ValueKey('work-purchase-open-${linked.shipmentId}'),
        );
        await reveal(tester, track);
        await tester.tap(track);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('buy-v2-screen')), findsOneWidget);
        expect(buy.selectedOrderId, order.id);
        buy.updateProjection(buy.orders);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('buy-v2-screen')), findsOneWidget);
        expect(buy.selectedOrderId, order.id);
        expect(buy.quantityFor(product.id), quantity);
        buy.updateProjection([
          for (final other in buy.orders)
            if (other.id != order.id) other,
          if (change != 'removed')
            BuyV2Order(
              id: order.id,
              destination: change == 'retail'
                  ? BuyV2Destination.shop
                  : order.destination,
              purchaseId: change == 'purchase'
                  ? 'replacement-${order.purchaseId}'
                  : order.purchaseId,
              title: order.title,
              itemSummary: order.itemSummary,
              total: order.total,
              partner: order.partner,
              partnerType: order.partnerType,
              promise: order.promise,
              destinationLabel: order.destinationLabel,
              progress: order.progress,
              status: order.status,
            ),
        ]);
        await tester.pumpAndSettle();
        await captureStoreView(tester, 'supply-tracking-buy-$change-$scale');
        expect(find.byKey(const ValueKey('buy-v2-screen')), findsNothing);
        final recovery = find.byKey(
          const Key('work-tracking-unavailable-action'),
        );
        await reveal(tester, recovery);
        expect(recovery.hitTestable(), findsOneWidget);
        await tester.tap(recovery);
        await tester.pumpAndSettle();
        expect(
          find.byKey(PageStorageKey('work-purchases-$storeId-false')),
          findsOneWidget,
        );
        expect(buy.quantityFor(product.id), quantity);
        expect(buy.cartTotal, total);
        expect(work.currentWorkspaceOrderId, originalCustomerOrder);
        expect(work.workspaceStockMovements, isEmpty);
        expect(work.workspaceInvoices, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final action in ['Call', 'WhatsApp']) {
    for (final textScale in [1.0, 2.0]) {
      for (final outcome in ['opened', 'unavailable', 'error', 'late-store']) {
        testWidgets(
          'DASH12 customer $action $outcome $textScale is not completed contact',
          (tester) async {
            final work = liveStore();
            final originalStore = work.activeWorkspace!;
            work.workspaceOrders.add(
              customerOrder(
                id: 'CONTACT-1',
                customer: 'Customer 2 · +91 98290 12345',
                createdAt: DateTime.now(),
              ),
            );
            const channel = MethodChannel('plugins.flutter.io/url_launcher');
            final launches = <Uri>[];
            final deferred = Completer<bool>();
            tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
              channel,
              (call) async {
                if (call.method != 'launch') return false;
                launches.add(
                  Uri.parse((call.arguments as Map)['url'] as String),
                );
                if (outcome == 'error') {
                  throw PlatformException(code: 'launch_failed');
                }
                if (outcome == 'late-store') return deferred.future;
                return outcome == 'opened';
              },
            );
            addTearDown(
              () => tester.binding.defaultBinaryMessenger
                  .setMockMethodCallHandler(channel, null),
            );
            await mount(
              tester,
              route: '/app/work/workspace/dashboard',
              work: work,
              viewport: textScale == 1
                  ? const Size(412, 915)
                  : const Size(320, 568),
              textScale: textScale,
            );
            await openStoreTools(tester);
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const Key('work-business-customers')));
            await tester.pumpAndSettle();
            if (action == 'Call') {
              await reveal(
                tester,
                find.byKey(const Key('work-customer-call-9829012345')),
              );
              await tester.tap(
                find.byKey(const Key('work-customer-call-9829012345')),
              );
            } else {
              await reveal(
                tester,
                find.byKey(const Key('work-customer-9829012345')),
              );
              await tester.tap(
                find.byKey(const Key('work-customer-9829012345')),
              );
              await tester.pumpAndSettle();
              await reveal(tester, find.text('WhatsApp'));
              await tester.tap(find.text('WhatsApp'));
            }
            await tester.pumpAndSettle();
            expect(launches, hasLength(1));
            expect(
              launches.single.path,
              action == 'Call' ? '9829012345' : '/919829012345',
            );
            if (outcome == 'late-store') {
              work.activeWorkspace = const WorkWorkspace(
                id: 'other-store',
                name: 'Other Store',
                profileId: 'retailer-grocery',
                profileLabel: 'Grocery',
                area: 'Jodhpur',
                verified: true,
              );
              deferred.complete(false);
              await tester.pumpAndSettle();
            }
            expect(work.workspaceCustomerLastContactAt, isEmpty);
            expect(
              work.errorMessage,
              outcome == 'unavailable' || outcome == 'error'
                  ? isNotNull
                  : isNull,
            );
            if (outcome == 'late-store') {
              expect(work.workspaceOrders, isEmpty);
              work.activeWorkspace = originalStore;
              expect(work.errorMessage, isNull);
              expect(work.workspaceCustomerLastContactAt, isEmpty);
            }
            expect(work.workspaceOrders.single.id, 'CONTACT-1');
            if (outcome == 'unavailable') {
              expect(
                find.byKey(const Key('work-error')).hitTestable(),
                findsOneWidget,
              );
              if (action == 'WhatsApp') {
                final error = find.byKey(const Key('work-error')).hitTestable();
                final sheet = find.byType(BottomSheet);
                expect(
                  tester.getTopLeft(error).dy,
                  greaterThanOrEqualTo(tester.getTopLeft(sheet).dy),
                );
                expect(
                  tester.getBottomRight(error).dy,
                  lessThanOrEqualTo(tester.getBottomRight(sheet).dy),
                );
              }
              await captureStoreView(
                tester,
                'customer-${action.toLowerCase()}-error-$textScale',
              );
            }
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets(
    'DASH12 invalid history disables calling and Chat is not contact proof',
    (tester) async {
      final work = liveStore();
      work.workspaceOrders.add(
        customerOrder(
          id: 'BAD-CONTACT',
          customer: 'Customer · 19829012345',
          createdAt: DateTime.now(),
        ),
      );
      await mount(tester, route: '/app/work/workspace/dashboard', work: work);
      await openStoreTools(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('work-business-customers')));
      await tester.pumpAndSettle();
      final id = work.workspaceCustomerBook.single.id;
      expect(
        tester
            .widget<IconButton>(find.byKey(Key('work-customer-call-$id')))
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(Key('work-customer-chat-$id')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-pending-draft-card')), findsOneWidget);
      expect(work.workspaceCustomerLastContactAt, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  for (final scale in [1.0, 2.0]) {
    for (final action in ['Call', 'Map']) {
      testWidgets('DASH12 delivery $action failure fits $scale', (
        tester,
      ) async {
        final work = storeViewFixture();
        work.workspaceOrderStage = 'Out for delivery';
        work.workspaceOrderCustomer = 'Customer 2 · +91 98290 12345';
        work.workspaceOrderFulfilment = 'Mool delivery';
        work.workspaceOrderNeedsDelivery = true;
        work.workspaceOrderAddress = 'Test lane';
        work.workspaceOrders[0] = work.workspaceOrders[0].copyWith(
          stage: work.workspaceOrderStage,
          customer: work.workspaceOrderCustomer,
          fulfilment: 'Mool delivery',
          needsDelivery: true,
          address: 'Test lane',
        );
        const channel = MethodChannel('plugins.flutter.io/url_launcher');
        final launches = <Uri>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (call) async {
            if (call.method != 'launch') return false;
            launches.add(Uri.parse((call.arguments as Map)['url'] as String));
            if (scale == 2) throw PlatformException(code: 'launch_failed');
            return false;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            channel,
            null,
          ),
        );
        await mount(
          tester,
          route: '/app/work/workspace/dashboard',
          work: work,
          viewport: scale == 1 ? const Size(412, 915) : const Size(320, 568),
          textScale: scale,
        );
        final button = find.byKey(
          Key(
            action == 'Call'
                ? 'work-delivery-call-customer'
                : 'work-delivery-open-map',
          ),
        );
        await reveal(tester, button);
        final label = find.descendant(of: button, matching: find.text(action));
        expect(
          tester.getSize(label).height,
          lessThan(25 * scale),
          reason:
              'Contact action must remain a readable line, not vertical letters',
        );
        await tester.tap(button);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(launches, hasLength(1));
        if (action == 'Call') {
          expect(launches.single.path, '9829012345');
        } else {
          expect(launches.single.queryParameters['query'], 'Test lane');
        }
        expect(
          find.text(
            action == 'Call'
                ? 'Could not open your phone app. Please try again.'
                : 'Could not open Maps. Please try again.',
          ),
          findsOneWidget,
        );
        expect(work.workspaceCustomerLastContactAt, isEmpty);
        expect(work.workspaceInvoices, isEmpty);
        expect(work.workspaceOrderStage, 'Out for delivery');
        expect(tester.takeException(), isNull);
        await captureStoreView(
          tester,
          'contact-delivery-${action.toLowerCase()}-$scale',
        );
      });
    }
  }

  for (final outcome in ['opened', 'unavailable', 'error', 'invalid-number']) {
    testWidgets('invoice WhatsApp $outcome never claims message completion', (
      tester,
    ) async {
      final work = liveStore();
      const channel = MethodChannel('plugins.flutter.io/url_launcher');
      final launches = <Uri>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method != 'launch') return false;
        launches.add(Uri.parse((call.arguments as Map)['url'] as String));
        if (outcome == 'error') throw PlatformException(code: 'launch_failed');
        return outcome == 'opened';
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await mount(
        tester,
        route: '/app/work/workspace/dashboard',
        work: work,
        viewport: const Size(320, 568),
        textScale: 1.4,
      );
      await tester.tap(find.byKey(const Key('work-store-sell')));
      await tester.pumpAndSettle();
      await enterSaleCustomer(tester, '9829012345');
      await tester.tap(find.byKey(const Key('work-order-add-oil-fortune-1l')));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('work-order-review')));
      await tester.tap(find.byKey(const Key('work-order-review')));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('work-order-save')));
      await tester.tap(find.byKey(const Key('work-order-save')));
      await tester.pumpAndSettle();
      var invoice = work.latestWorkspaceInvoice!;
      if (outcome == 'invalid-number') {
        await reveal(tester, find.byTooltip('Close invoice'));
        await tester.tap(find.byTooltip('Close invoice'));
        await tester.pumpAndSettle();
        invoice = WorkspaceCustomerInvoice(
          id: invoice.id,
          orderId: invoice.orderId,
          customer: 'Rakesh',
          items: invoice.items,
          amount: invoice.amount,
          payment: invoice.payment,
          issuedAt: invoice.issuedAt,
        );
        work.workspaceInvoices[0] = invoice;
        await tester.tap(find.byKey(const Key('work-store-home')));
        await tester.pumpAndSettle();
        await reveal(tester, find.byKey(const Key('work-invoice-open')));
        await tester.tap(find.byKey(const Key('work-invoice-open')));
        await tester.pumpAndSettle();
      }
      final whatsapp = find.byKey(const Key('work-invoice-share-whatsapp'));
      await reveal(tester, whatsapp);
      await tester.tap(whatsapp);
      await tester.pumpAndSettle();
      expect(work.latestWorkspaceInvoice!.sharedChannels, isEmpty);
      expect(work.latestWorkspaceInvoice!.needsCustomerHandoff, isTrue);
      expect(work.workspaceInvoices, hasLength(1));
      if (outcome == 'invalid-number') {
        expect(launches, isEmpty);
      } else {
        expect(launches, hasLength(1));
        expect(launches.single.host, 'wa.me');
        expect(launches.single.path, '/919829012345');
        expect(launches.single.queryParameters['text'], contains(invoice.id));
        expect(
          launches.single.queryParameters['text'],
          contains(invoice.items),
        );
        expect(
          launches.single.queryParameters['text'],
          contains('₹${invoice.amount}'),
        );
      }
      if (outcome != 'opened') {
        expect(
          find.byKey(const Key('work-invoice-share-error')),
          findsOneWidget,
        );
        await reveal(tester, find.byKey(const Key('work-invoice-share-chat')));
        expect(
          find.byKey(const Key('work-invoice-share-chat')).hitTestable(),
          findsOneWidget,
        );
        await captureStoreView(tester, '38-invoice-$outcome-320');
        await reveal(tester, find.byTooltip('Close invoice'));
        await tester.tap(find.byTooltip('Close invoice'));
        await tester.pumpAndSettle();
        expect(find.byTooltip('Close invoice'), findsNothing);
      }
      await tester.tap(find.byKey(const Key('work-store-home')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-store-activity-deck')), findsOneWidget);
      expect(work.latestWorkspaceInvoice!.needsCustomerHandoff, isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('drafted sale has explicit keep or discard recovery', (
    tester,
  ) async {
    final work = liveStore();
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    await tester.tap(find.byKey(const Key('work-store-sell')));
    await tester.pumpAndSettle();
    await enterSaleCustomer(tester, '9829012345');
    await tester.tap(find.byKey(const Key('work-order-add-oil-fortune-1l')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-operation-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-order-discard-dialog')), findsOne);
    await tester.tap(find.byKey(const Key('work-order-keep-editing')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-sale-customer')), findsOne);
    expect(work.workspaceOrderCustomer, '9829012345');
    await tester.tap(find.byKey(const Key('work-operation-back')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-order-discard')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-store-activity-deck')), findsOne);
    expect(work.workspaceOrderQuantities, isEmpty);
  });

  testWidgets('Store header and contextual tabs keep full customer labels', (
    tester,
  ) async {
    final work = liveStore();
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    final searchLabel = tester.widget<Text>(find.text('Search your store'));
    expect(searchLabel.maxLines, 1);
    expect(searchLabel.overflow, isNull);
    await openStoreTools(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-business-preview')));
    await tester.pumpAndSettle();
    for (final label in const [
      'Today',
      'Customers',
      'Money',
      'Grow',
      'Storefront',
    ]) {
      expect(find.text(label), findsWidgets, reason: label);
    }
    expect(
      find
          .byKey(const Key('work-preview-product-oil-fortune-1l'))
          .hitTestable(),
      findsOneWidget,
    );
  });

  testWidgets('finishing Store search clears its inactive term', (
    tester,
  ) async {
    final work = liveStore();
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    await tester.tap(find.byKey(const Key('work-dashboard-search')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('work-dashboard-search-field')),
      'oil',
    );
    await tester.tap(find.byKey(const Key('work-dashboard-search-close')));
    await tester.pumpAndSettle();
    expect(work.workspaceSearchQuery, isEmpty);
    expect(find.text('Search your store'), findsOneWidget);
  });

  testWidgets('Workspace product opens exact public Buy product details', (
    tester,
  ) async {
    final work = liveStore();
    await mount(
      tester,
      route:
          '/app/buy?view=product&product=oil-fortune-1l&workspaceProduct=oil-fortune-1l&return=/app/work/workspace/dashboard',
      work: work,
    );
    await tester.pumpAndSettle();
    expect(find.text('Fortune Sunflower Oil'), findsWidgets);
    expect(find.textContaining('1 L pouch'), findsWidgets);
    expect(find.text('This product could not be found.'), findsNothing);
  });

  testWidgets('Storefront Buy Back returns directly to Storefront', (
    tester,
  ) async {
    final work = liveStore();
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    await openStoreTools(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-business-preview')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('work-preview-product-oil-fortune-1l')),
    );
    await tester.pumpAndSettle();
    await reveal(
      tester,
      find.byKey(const Key('work-preview-open-buy-product')),
    );
    await tester.tap(find.byKey(const Key('work-preview-open-buy-product')));
    await tester.pumpAndSettle();
    expect(find.text('Fortune Sunflower Oil'), findsWidgets);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-dashboard-preview-screen')), findsOne);
  });

  testWidgets('Store requirements use outcome-facing accessible fields', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final work = liveStore();
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);
    await tester.tap(find.byKey(const Key('work-quick-requirement')));
    await tester.pumpAndSettle();
    final service = find.byKey(const Key('work-requirement-category-0'));
    await tester.tap(service);
    await tester.pumpAndSettle();
    expect(find.text('Experience or qualification'), findsNothing);
    expect(find.bySemanticsLabel('Expected result'), findsOneWidget);
    expect(
      find.byKey(const Key('work-requirement-review')).hitTestable(),
      findsOneWidget,
    );
    expect(work.workspacePaidRequirementReference, isNull);
    semantics.dispose();
  });

  Future<void> captureActivityDeck(
    WidgetTester tester, {
    required WorkSession work,
    required String fileName,
    String directory = 'work-store-atomic-r62-50-local-review-20260903',
    Future<void> Function()? afterMount,
    Finder? target,
  }) async {
    await mount(
      tester,
      route: '/app/work/workspace/dashboard',
      work: work,
      viewport: const Size(412, 915),
      textScale: 1.4,
      bottomInset: 34,
    );
    if (afterMount != null) await afterMount();
    await tester.pumpAndSettle();
    await expectLater(
      target ?? find.byType(Scaffold).first,
      matchesGoldenFile('../../../artifacts/quality/$directory/$fileName'),
    );
  }

  testWidgets(
    'Store Live v1 capture - quiet store',
    skip: !captureStoreLiveEvidence,
    (tester) async {
      await captureActivityDeck(
        tester,
        work: liveStore()..workspaceSalesToday = 28450,
        directory: 'work-store-live-v1-local-review-20260903',
        fileName: '01-store-live-quiet-412x915.png',
      );
    },
  );

  testWidgets(
    'Store Live v1 capture - incoming order',
    skip: !captureStoreLiveEvidence,
    (tester) async {
      final work = liveStore()
        ..workspaceSalesToday = 28450
        ..workspaceSettlementBalance = 17820;
      seedIncomingOrder(work);
      await captureActivityDeck(
        tester,
        work: work,
        directory: 'work-store-live-v1-local-review-20260903',
        fileName: '02-store-live-order-412x915.png',
      );
    },
  );

  testWidgets(
    'Store Live v1 capture - packing',
    skip: !captureStoreLiveEvidence,
    (tester) async {
      final work = liveStore()
        ..workspaceSalesToday = 28450
        ..workspaceSettlementBalance = 17820;
      seedIncomingOrder(work, stage: 'Preparing', delivery: true);
      await captureActivityDeck(
        tester,
        work: work,
        directory: 'work-store-live-v1-local-review-20260903',
        fileName: '03-store-live-packing-412x915.png',
      );
    },
  );

  testWidgets(
    'Store Live v1 capture - delivery',
    skip: !captureStoreLiveEvidence,
    (tester) async {
      final work = liveStore()
        ..workspaceSalesToday = 28450
        ..workspaceSettlementBalance = 17820;
      seedIncomingOrder(work, stage: 'Ready', delivery: true);
      await captureActivityDeck(
        tester,
        work: work,
        directory: 'work-store-live-v1-local-review-20260903',
        fileName: '04-store-live-delivery-412x915.png',
      );
    },
  );

  testWidgets(
    'Store Live v1 capture - Orders destination',
    skip: !captureStoreLiveEvidence,
    (tester) async {
      final work = liveStore();
      seedIncomingOrder(work);
      await captureActivityDeck(
        tester,
        work: work,
        directory: 'work-store-live-v1-local-review-20260903',
        fileName: '05-store-live-orders-412x915.png',
        afterMount: () async {
          await tester.tap(find.byKey(const Key('work-store-orders')));
        },
      );
    },
  );

  testWidgets(
    'Store Live v1 capture - pickup ready',
    skip: !captureStoreLiveEvidence,
    (tester) async {
      final work = liveStore();
      seedIncomingOrder(work, stage: 'Ready for pickup');
      await captureActivityDeck(
        tester,
        work: work,
        directory: 'work-store-live-v1-local-review-20260903',
        fileName: '06-store-live-pickup-ready-412x915.png',
      );
    },
  );

  testWidgets(
    'Store Live v1 capture - pickup code',
    skip: !captureStoreLiveEvidence,
    (tester) async {
      final work = liveStore();
      seedIncomingOrder(work, stage: 'Ready for pickup');
      await captureActivityDeck(
        tester,
        work: work,
        directory: 'work-store-live-v1-local-review-20260903',
        fileName: '07-store-live-pickup-code-412x915.png',
        target: find.byType(MaterialApp),
        afterMount: () async {
          await tester.tap(
            find.byKey(const Key('work-confirm-customer-pickup')),
          );
        },
      );
    },
  );

  testWidgets(
    'Store Live v1 capture - assigned delivery',
    skip: !captureStoreLiveEvidence,
    (tester) async {
      final work = liveStore();
      seedIncomingOrder(work, stage: 'Ready', delivery: true);
      work.workspaceDeliveryAssignment = WorkspaceDeliveryAssignment(
        orderId: 'current-store-order',
        partnerName: 'Ravi Kumar',
        vehicleLabel: 'Bike RJ19 AB 1234',
        eta: DateTime.now().add(const Duration(minutes: 8)),
        stage: 'Assigned',
      );
      await captureActivityDeck(
        tester,
        work: work,
        directory: 'work-store-live-v1-local-review-20260903',
        fileName: '08-store-live-delivery-assigned-412x915.png',
      );
    },
  );

  testWidgets(
    'Store Live v1 capture - customer delivery composer',
    skip: !captureStoreLiveEvidence,
    (tester) async {
      await captureActivityDeck(
        tester,
        work: liveStore(),
        directory: 'work-store-live-sell-deliver-v1-local-review-20260904',
        fileName: '01-customer-delivery-composer-412x915.png',
        afterMount: () async {
          await openExistingDeliveryDraft(tester);
        },
      );
    },
  );

  testWidgets(
    'Store Live v1 capture - customer delivery review',
    skip: !captureStoreLiveEvidence,
    (tester) async {
      await captureActivityDeck(
        tester,
        work: liveStore(),
        directory: 'work-store-live-sell-deliver-v1-local-review-20260904',
        fileName: '02-customer-delivery-review-412x915.png',
        target: find.byType(MaterialApp),
        afterMount: () async {
          await openExistingDeliveryDraft(tester);
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byKey(const Key('work-order-customer')),
            '98290 12345',
          );
          await tester.enterText(
            find.byKey(const Key('work-order-address')),
            '12 Market Road, Sardarpura',
          );
          await tester.tap(
            find.byKey(const Key('work-order-add-oil-fortune-1l')),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('work-order-review')));
        },
      );
    },
  );

  testWidgets(
    'Store Live v1 capture - premium product catalogue',
    skip: !captureStoreLiveEvidence,
    (tester) async {
      final work = liveStore();
      for (var index = 1; index <= 4; index++) {
        work.workspaceCatalogueItems.add(
          catalogueProduct(index, stock: index == 1 ? 3 : 12 + index),
        );
      }
      await captureActivityDeck(
        tester,
        work: work,
        directory: 'work-store-live-products-stock-v1-local-review-20260904',
        fileName: '01-products-customers-can-buy-412x915.png',
        afterMount: () async {
          await tester.tap(find.byKey(const Key('work-store-stock')));
        },
      );
    },
  );

  testWidgets(
    'Store Live v1 capture - fast product editor',
    skip: !captureStoreLiveEvidence,
    (tester) async {
      await captureActivityDeck(
        tester,
        work: liveStore(),
        directory: 'work-store-live-products-stock-v1-local-review-20260904',
        fileName: '02-fast-product-editor-412x915.png',
        target: find.byType(MaterialApp),
        afterMount: () async {
          await tester.tap(find.byKey(const Key('work-store-stock')));
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(const Key('work-catalogue-edit-oil-fortune-1l')),
          );
        },
      );
    },
  );

  testWidgets(
    'Store Live v1 capture - stock statement',
    skip: !captureStoreLiveEvidence,
    (tester) async {
      final work = liveStore();
      work.updateWorkspaceStock(
        productId: 'oil-fortune-1l',
        quantity: 3,
        reason: 'Counted in store',
      );
      await captureActivityDeck(
        tester,
        work: work,
        directory: 'work-store-live-products-stock-v1-local-review-20260904',
        fileName: '03-stock-statement-412x915.png',
        afterMount: () async {
          await tester.tap(find.byKey(const Key('work-store-stock')));
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(const Key('work-catalogue-stock-statement')),
          );
        },
      );
    },
  );

  testWidgets(
    'Store Live v1 capture - live Group Bulk Buying',
    skip: !captureStoreLiveEvidence,
    (tester) async {
      final work = liveStore()
        ..applyConfirmedWorkspaceGroupBuyPayment(
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
          paymentReference: 'PAY-REVIEW-001',
          closingLabel: '5 Sep · 8:00 PM',
          storeDeliveryLabel: '7 Sep · Door delivery',
        );
      await captureActivityDeck(
        tester,
        work: work,
        directory: 'work-store-live-procurement-v1-local-review-20260904',
        fileName: '01-live-group-bulk-buying-412x915.png',
        afterMount: () async {
          await tester.tap(find.byKey(const Key('work-quick-group-buy')));
        },
      );
    },
  );

  testWidgets(
    'Store Live v1 capture - Customer Book',
    skip: !captureStoreLiveEvidence,
    (tester) async {
      final work = liveStore();
      final now = DateTime.now();
      work.workspaceOrders.addAll([
        customerOrder(
          id: 'CUST-1',
          customer: 'Rakesh · 98290 12345',
          createdAt: now,
        ),
        customerOrder(
          id: 'CUST-2',
          customer: 'Sunita · 98290 22345',
          createdAt: now.subtract(const Duration(days: 1)),
          amount: 540,
          payment: 'Customer due',
        ),
        customerOrder(
          id: 'CUST-3',
          customer: 'Imran · 98290 32345',
          createdAt: now.subtract(const Duration(days: 2)),
        ),
        customerOrder(
          id: 'CUST-4',
          customer: 'Meena · 98290 42345',
          createdAt: now.subtract(const Duration(days: 3)),
        ),
      ]);
      await captureActivityDeck(
        tester,
        work: work,
        directory: 'work-store-live-customers-money-v1-local-review-20260904',
        fileName: '01-customer-book-412x915.png',
        afterMount: () async {
          await openStoreTools(tester);
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('work-business-customers')));
        },
      );
    },
  );

  testWidgets(
    'Store Live v1 capture - customer actions',
    skip: !captureStoreLiveEvidence,
    (tester) async {
      final work = liveStore();
      final now = DateTime.now();
      work.workspaceOrders.addAll([
        customerOrder(
          id: 'REP-1',
          customer: 'Rakesh · 98290 12345',
          createdAt: now,
        ),
        customerOrder(
          id: 'REP-2',
          customer: 'Rakesh · 98290 12345',
          createdAt: now.subtract(const Duration(days: 5)),
        ),
      ]);
      work.workspaceCustomersAllowingMessages.add('9829012345');
      await captureActivityDeck(
        tester,
        work: work,
        directory: 'work-store-live-customers-money-v1-local-review-20260904',
        fileName: '02-customer-actions-412x915.png',
        target: find.byType(MaterialApp),
        afterMount: () async {
          await openStoreTools(tester);
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('work-business-customers')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('work-customer-9829012345')));
        },
      );
    },
  );

  testWidgets(
    'Store Live v1 capture - Money',
    skip: !captureStoreLiveEvidence,
    (tester) async {
      final work = liveStore()
        ..workspaceSettlementBalance = 20000
        ..workspacePlatformAdjustments = 900
        ..workspaceDeliveryAdjustments = 300
        ..workspaceRefunds = 400
        ..workspaceTaxWithheld = 200
        ..workspaceSalesToday = 28450;
      await captureActivityDeck(
        tester,
        work: work,
        directory: 'work-store-live-customers-money-v1-local-review-20260904',
        fileName: '03-money-412x915.png',
        afterMount: () async {
          await openStoreTools(tester);
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('work-business-money')));
        },
      );
    },
  );

  testWidgets(
    'Store Live v1 capture - Growth',
    skip: !captureStoreLiveEvidence,
    (tester) async {
      final work = liveStore()..workspaceVisibleToCustomers = true;
      final now = DateTime.now();
      work.workspaceOrders.addAll([
        customerOrder(
          id: 'GROW-1',
          customer: 'Rakesh · 98290 12345',
          createdAt: now,
        ),
        customerOrder(
          id: 'GROW-2',
          customer: 'Rakesh · 98290 12345',
          createdAt: now.subtract(const Duration(days: 5)),
        ),
      ]);
      await captureActivityDeck(
        tester,
        work: work,
        directory: 'work-store-live-growth-settings-v1-local-review-20260904',
        fileName: '01-growth-412x915.png',
        afterMount: () async {
          await openStoreTools(tester);
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('work-business-grow')));
        },
      );
    },
  );

  testWidgets(
    'Store Live v1 capture - Store settings',
    skip: !captureStoreLiveEvidence,
    (tester) async {
      await captureActivityDeck(
        tester,
        work: liveStore(),
        directory: 'work-store-live-growth-settings-v1-local-review-20260904',
        fileName: '02-store-settings-412x915.png',
        afterMount: () async {
          await openStoreSettings(tester);
        },
      );
    },
  );

  testWidgets(
    'Store Live v1 capture - Business record',
    skip: !captureStoreLiveEvidence,
    (tester) async {
      await captureActivityDeck(
        tester,
        work: liveStore(),
        directory: 'work-store-live-growth-settings-v1-local-review-20260904',
        fileName: '03-business-record-412x915.png',
        afterMount: () async {
          await openStoreSettings(tester);
          await tester.pumpAndSettle();
          await reveal(tester, find.text('Business details and documents'));
          await tester.tap(find.text('Business details and documents'));
        },
      );
    },
  );

  testWidgets(
    'founder Activity Deck capture - idle live store',
    skip: !captureFounderEvidence,
    (tester) async {
      await captureActivityDeck(
        tester,
        work: liveStore(),
        fileName: 'store-activity-idle-412x915.png',
      );
    },
  );

  testWidgets(
    'founder Activity Deck capture - incoming order',
    skip: !captureFounderEvidence,
    (tester) async {
      final work = liveStore();
      seedIncomingOrder(work);
      await captureActivityDeck(
        tester,
        work: work,
        fileName: 'store-activity-incoming-order-412x915.png',
      );
    },
  );

  testWidgets(
    'founder Activity Deck capture - packing',
    skip: !captureFounderEvidence,
    (tester) async {
      final work = liveStore();
      seedIncomingOrder(work, stage: 'Preparing', delivery: true);
      await captureActivityDeck(
        tester,
        work: work,
        fileName: 'store-activity-packing-412x915.png',
      );
    },
  );

  testWidgets(
    'founder Activity Deck capture - delivery',
    skip: !captureFounderEvidence,
    (tester) async {
      final work = liveStore();
      seedIncomingOrder(work, stage: 'Ready', delivery: true);
      await captureActivityDeck(
        tester,
        work: work,
        fileName: 'store-activity-delivery-412x915.png',
      );
    },
  );

  testWidgets(
    'founder Activity Deck capture - Settings',
    skip: !captureFounderEvidence,
    (tester) async {
      await captureActivityDeck(
        tester,
        work: liveStore(),
        fileName: 'store-settings-412x915.png',
        afterMount: () async {
          await openStoreSettings(tester);
        },
      );
    },
  );

  testWidgets(
    'founder Activity Deck capture - public SKU catalogue',
    skip: !captureFounderEvidence,
    (tester) async {
      await captureActivityDeck(
        tester,
        work: liveStore(),
        fileName: 'store-public-sku-catalogue-412x915.png',
        afterMount: () async {
          await tester.tap(find.byKey(const Key('work-store-stock')));
        },
      );
    },
  );

  testWidgets(
    'founder Activity Deck capture - Group Bulk Buying',
    skip: !captureFounderEvidence,
    (tester) async {
      final work = liveStore()
        ..applyConfirmedWorkspaceGroupBuyPayment(
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
          paymentReference: 'PAY-REVIEW-001',
          closingLabel: '5 Sep · 8:00 PM',
          storeDeliveryLabel: '7 Sep · Door delivery',
        );
      await captureActivityDeck(
        tester,
        work: work,
        fileName: 'store-group-bulk-buying-412x915.png',
        afterMount: () async {
          await tester.tap(find.byKey(const Key('work-quick-group-buy')));
        },
      );
    },
  );

  testWidgets(
    'founder destination capture - customer storefront preview',
    skip: !captureFounderEvidence,
    (tester) async {
      await captureActivityDeck(
        tester,
        work: liveStore(),
        fileName: 'destination-customer-storefront-412x915.png',
        afterMount: () async {
          await openStoreTools(tester);
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('work-business-preview')));
        },
      );
    },
  );

  testWidgets(
    'founder destination capture - comprehensive product editor',
    skip: !captureFounderEvidence,
    (tester) async {
      await captureActivityDeck(
        tester,
        work: liveStore(),
        fileName: 'destination-product-editor-412x915.png',
        target: find.byType(Overlay).last,
        afterMount: () async {
          await tester.tap(find.byKey(const Key('work-store-stock')));
          await tester.pumpAndSettle();
          final edit = find.byWidgetPredicate((widget) {
            final key = widget.key;
            return key is ValueKey<String> &&
                key.value.startsWith('work-catalogue-edit-');
          }).first;
          await tester.tap(edit);
        },
      );
    },
  );

  testWidgets(
    'founder correction capture - exact Workspace product in Buy',
    skip: !captureFounderEvidence,
    (tester) async {
      final work = liveStore();
      await mount(
        tester,
        route:
            '/app/buy?view=product&product=oil-fortune-1l&workspaceProduct=oil-fortune-1l&return=/app/work/workspace/dashboard',
        work: work,
        viewport: const Size(412, 915),
        textScale: 1.4,
        bottomInset: 34,
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(Scaffold).first,
        matchesGoldenFile(
          '../../../artifacts/quality/work-store-atomic-r62-50-local-review-20260903/destination-workspace-public-buy-product-412x915.png',
        ),
      );
    },
  );

  testWidgets(
    'founder destination capture - compact reject decision',
    skip: !captureFounderEvidence,
    (tester) async {
      final work = liveStore();
      seedIncomingOrder(work);
      await captureActivityDeck(
        tester,
        work: work,
        fileName: 'destination-reject-order-412x915.png',
        target: find.byType(Overlay).last,
        afterMount: () async {
          await tester.tap(find.byKey(const Key('work-activity-order-reject')));
        },
      );
    },
  );

  testWidgets(
    'founder correction capture - Workspace switcher',
    skip: !captureFounderEvidence,
    (tester) async {
      final work = liveStore()..seedMultipleWorkspaces();
      await captureActivityDeck(
        tester,
        work: work,
        fileName: 'correction-workspace-switcher-412x915.png',
        target: find.byType(Overlay).last,
        afterMount: () async {
          await tester.tap(
            find.byKey(const Key('work-dashboard-workspace-switcher')),
          );
        },
      );
    },
  );

  testWidgets(
    'founder correction capture - order completion sheet',
    skip: !captureFounderEvidence,
    (tester) async {
      final work = liveStore();
      await captureActivityDeck(
        tester,
        work: work,
        fileName: 'correction-order-completion-412x915.png',
        target: find.byType(Overlay).last,
        afterMount: () async {
          await tester.tap(find.byKey(const Key('work-store-sell')));
          await tester.pumpAndSettle();
          await enterSaleCustomer(tester, '9829012345');
          await tester.tap(
            find.byKey(const Key('work-order-add-oil-fortune-1l')),
          );
          await tester.pump();
          await tester.tap(find.byKey(const Key('work-order-review')));
        },
      );
    },
  );

  testWidgets(
    'founder correction capture - pickup ready',
    skip: !captureFounderEvidence,
    (tester) async {
      final work = liveStore();
      seedIncomingOrder(work, stage: 'Preparing');
      for (final line in work.workspacePackingLines) {
        work.setWorkspacePackingLine(line.id, true);
      }
      await captureActivityDeck(
        tester,
        work: work,
        fileName: 'correction-pickup-ready-412x915.png',
        afterMount: () async {
          await tester.tap(find.byKey(const Key('work-activity-mark-ready')));
        },
      );
    },
  );

  testWidgets(
    'founder correction capture - invoice handoff',
    skip: !captureFounderEvidence,
    (tester) async {
      final work = liveStore();
      seedIncomingOrder(work, stage: 'Preparing');
      for (final line in work.workspacePackingLines) {
        work.setWorkspacePackingLine(line.id, true);
      }
      await captureActivityDeck(
        tester,
        work: work,
        fileName: 'correction-invoice-handoff-412x915.png',
        target: find.byType(Overlay).last,
        afterMount: () async {
          await tester.tap(find.byKey(const Key('work-activity-mark-ready')));
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(const Key('work-confirm-customer-pickup')),
          );
        },
      );
    },
  );

  testWidgets(
    'founder correction capture - Store offers',
    skip: !captureFounderEvidence,
    (tester) async {
      await captureActivityDeck(
        tester,
        work: liveStore(),
        fileName: 'correction-store-offers-412x915.png',
        afterMount: () async {
          await openStoreTools(tester);
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('work-business-grow')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('work-growth-offers')));
        },
      );
    },
  );

  testWidgets(
    'founder correction capture - funded Store work',
    skip: !captureFounderEvidence,
    (tester) async {
      await captureActivityDeck(
        tester,
        work: liveStore(),
        fileName: 'correction-funded-store-work-412x915.png',
        afterMount: () async {
          await openStoreTools(tester);
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('work-business-grow')));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Publish paid work'));
        },
      );
    },
  );

  testWidgets(
    'founder correction capture - approved business record',
    skip: !captureFounderEvidence,
    (tester) async {
      await captureActivityDeck(
        tester,
        work: liveStore(),
        fileName: 'correction-approved-business-record-412x915.png',
        afterMount: () async {
          await openStoreSettings(tester);
          await tester.pumpAndSettle();
          await reveal(tester, find.text('Business details and documents'));
          await tester.tap(find.text('Business details and documents'));
        },
      );
    },
  );

  testWidgets('first-tap commands open the intended Store destinations', (
    tester,
  ) async {
    final work = liveStore();
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);

    await tester.tap(find.byKey(const Key('work-store-sell')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('work-dashboard-counter-order-screen')),
      findsOne,
    );
    expect(work.workspaceOrderSource, 'Counter');
    expect(work.workspaceOrderNeedsDelivery, isFalse);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await openExistingDeliveryDraft(tester);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('work-dashboard-counter-order-screen')),
      findsOne,
    );
    expect(work.workspaceOrderSource, 'Phone');
    expect(work.workspaceOrders, isEmpty);
    expect(work.workspaceOrderFulfilment, 'Mool delivery');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mool delivery composer fits a 360x800 Store viewport', (
    tester,
  ) async {
    final work = liveStore();
    await mount(
      tester,
      route: '/app/work/workspace/dashboard',
      work: work,
      viewport: const Size(360, 800),
    );

    await openExistingDeliveryDraft(tester);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('work-sale-customer')).hitTestable(),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('work-sale-delivery')).hitTestable(),
      findsOneWidget,
    );
    expect(find.byKey(const Key('work-order-address')), findsNothing);
    expect(
      find.byKey(const Key('work-order-review')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Business drawer opens Customers Money and Grow destinations', (
    tester,
  ) async {
    final work = liveStore();
    seedIncomingOrder(work);
    await mount(tester, route: '/app/work/workspace/dashboard', work: work);

    await openStoreTools(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-business-customers')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-customers-destination')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await openStoreTools(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-business-money')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-money-destination')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await openStoreTools(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-business-grow')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-grow-destination')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'founder destination capture - Orders',
    skip: !captureFounderEvidence,
    (tester) async {
      final work = liveStore();
      seedIncomingOrder(work);
      await captureActivityDeck(
        tester,
        work: work,
        fileName: 'destination-orders-412x915.png',
        afterMount: () async {
          await tester.tap(find.byKey(const Key('work-store-orders')));
        },
      );
    },
  );

  testWidgets(
    'founder destination capture - New Sale',
    skip: !captureFounderEvidence,
    (tester) async {
      await captureActivityDeck(
        tester,
        work: liveStore(),
        fileName: 'destination-new-sale-412x915.png',
        afterMount: () async {
          await tester.tap(find.byKey(const Key('work-store-sell')));
        },
      );
    },
  );

  testWidgets(
    'founder destination capture - Deliver Order',
    skip: !captureFounderEvidence,
    (tester) async {
      await captureActivityDeck(
        tester,
        work: liveStore(),
        fileName: 'destination-deliver-order-412x915.png',
        afterMount: () async {
          await openExistingDeliveryDraft(tester);
        },
      );
    },
  );

  testWidgets(
    'founder destination capture - Buy Stock',
    skip: !captureFounderEvidence,
    (tester) async {
      await captureActivityDeck(
        tester,
        work: liveStore(),
        fileName: 'destination-buy-stock-412x915.png',
        afterMount: () async {
          await tester.tap(find.byKey(const Key('work-quick-buy')));
        },
      );
    },
  );

  testWidgets(
    'founder destination capture - Customers',
    skip: !captureFounderEvidence,
    (tester) async {
      final work = liveStore();
      seedIncomingOrder(work);
      await captureActivityDeck(
        tester,
        work: work,
        fileName: 'destination-customers-412x915.png',
        afterMount: () async {
          await openStoreTools(tester);
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('work-business-customers')));
        },
      );
    },
  );

  testWidgets(
    'founder destination capture - Money',
    skip: !captureFounderEvidence,
    (tester) async {
      final work = liveStore()
        ..workspaceSalesToday = 28450
        ..workspaceCompletedSalesCount = 42
        ..workspaceSettlementBalance = 17820;
      await captureActivityDeck(
        tester,
        work: work,
        fileName: 'destination-money-412x915.png',
        afterMount: () async {
          await openStoreTools(tester);
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('work-business-money')));
        },
      );
    },
  );

  testWidgets(
    'founder destination capture - Grow',
    skip: !captureFounderEvidence,
    (tester) async {
      await captureActivityDeck(
        tester,
        work: liveStore(),
        fileName: 'destination-grow-412x915.png',
        afterMount: () async {
          await openStoreTools(tester);
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('work-business-grow')));
        },
      );
    },
  );
}

class _WorkspaceEntryFixtureGateway extends ReviewWorkGateway {
  bool failOnce = false;
  @override
  Future<List<WorkReviewResult>> loadFeed() async {
    if (failOnce) {
      failOnce = false;
      throw const WorkGatewayException('Workspaces could not be loaded.');
    }
    return const [
      WorkReviewResult(
        caseId: 'approved-case',
        status: WorkRemoteReviewStatus.approved,
        plan: 'free',
        workspaceId: 'approved-store',
        profileId: 'retailer-grocery',
        name: 'Approved Kirana',
        area: '302001',
      ),
    ];
  }
}

class _IssueDraftFixtureStore implements WorkIssueDraftStore {
  final values = <WorkspaceIssueDraftKey, WorkspaceIssueDraft>{};
  bool failWrite = false;
  @override
  Future<WorkspaceIssueDraft?> read(WorkspaceIssueDraftKey key) async =>
      values[key];
  @override
  Future<void> save(WorkspaceIssueDraft draft) async {
    if (failWrite) throw StateError('fixture save failure');
    values[draft.key] = draft;
  }
}

class _IssueCommandFixtureStore implements WorkIssueCommandStore {
  final values = <WorkspaceIssueDraftKey, WorkIssueSubmission>{};
  @override
  Future<WorkIssueSubmission?> read(WorkspaceIssueDraftKey key) async =>
      values[key];
  @override
  Future<void> save(WorkIssueSubmission submission) async {
    values[submission.command.key] = submission;
  }
}

class _IssueResponseFixtureGateway implements WorkIssueCommandGateway {
  final submitted = <WorkIssueCommand>[];
  final reconciled = <WorkIssueCommand>[];
  var result = Completer<WorkIssueReply>();
  @override
  Future<WorkIssueReply> submitIssueResponse(WorkIssueCommand command) {
    submitted.add(command);
    return result.future;
  }

  @override
  Future<WorkIssueReply> reconcileIssueResponse(
    WorkIssueCommand command,
  ) async {
    reconciled.add(command);
    return WorkIssueReply(
      key: command.key,
      operationId: command.operationId,
      commandDigest: command.digest,
      state: WorkIssueReplyState.applied,
      revision: command.draft.expectedRevision + 1,
    );
  }
}

class _StockHistoryFixtureGateway implements WorkStockHistoryGateway {
  bool failNext = false;
  final cursors = <String?>[];
  @override
  Future<WorkspaceStockHistoryPage> readStockHistory(
    WorkspaceStockHistoryQuery query, {
    String? cursor,
    String? snapshotId,
  }) async {
    cursors.add(cursor);
    if (failNext) {
      failNext = false;
      throw StateError('Offline fixture');
    }
    final now = DateTime.now();
    final all = List.generate(
      101,
      (i) => WorkspaceStockMovement(
        id: 'server-$i',
        productId: 'oil-fortune-1l',
        productLabel: 'Fortune Sunflower Oil · 1 L',
        kind: WorkspaceStockMovementKind.reserved,
        quantityDelta: -2,
        reason: 'Customer order reservation',
        occurredAt: now.subtract(Duration(minutes: i)),
        referenceKind: WorkspaceStockReferenceKind.order,
        referenceId: 'APP-1043',
      ),
    ).where(query.includes).toList();
    final start = int.parse(cursor ?? '0');
    final end = (start + WorkspaceStockHistoryQuery.pageSize).clamp(
      0,
      all.length,
    );
    return WorkspaceStockHistoryPage(
      query: query,
      snapshotId: 'history-v1',
      cursor: cursor,
      nextCursor: end < all.length ? '$end' : null,
      totalCount: all.length,
      records: all.sublist(start, end),
    );
  }
}

// Presentation fault injection only; secure journal/CAS is tested separately.
class _CounterDraftFixtureStore implements WorkCounterDraftStore {
  WorkspaceCounterDraft? value;
  bool failRead = false, failRetire = false;
  @override
  Future<WorkspaceCounterDraft?> read(String account, String store) async {
    if (failRead) throw StateError('review read failure');
    return value?.account == account && value?.store == store ? value : null;
  }

  @override
  Future<void> save(
    WorkspaceCounterDraft draft, {
    required int? expectedRevision,
  }) async {
    if (value?.revision != expectedRevision ||
        (failRetire && draft.stage == WorkspaceCounterDraftStage.retired)) {
      throw StateError('review write failure');
    }
    value = draft;
  }
}

class _ReceiptDraftFixtureStore implements WorkReceiptDraftStore {
  final values = <WorkspaceReceiptDraftKey, WorkspaceReceiptDraft>{};
  bool failRead = false, failSave = false;
  @override
  Future<WorkspaceReceiptDraft?> read(WorkspaceReceiptDraftKey key) async {
    if (failRead) throw StateError('Fixture read failure');
    return values[key];
  }

  @override
  Future<void> save(
    WorkspaceReceiptDraft draft, {
    required int? expectedRevision,
  }) async {
    if (failSave) throw StateError('Fixture write failure');
    if (values[draft.key]?.revision != expectedRevision ||
        draft.revision != (expectedRevision ?? 0) + 1) {
      throw StateError('Fixture revision conflict');
    }
    values[draft.key] = WorkspaceReceiptDraft.fromJson(draft.toJson())!;
  }
}

class _ContactDraftFixtureStore implements WorkPendingProofStore {
  @override
  String accountScope = 'review-draft-account';
  Map<String, Object?>? value;
  @override
  Future<Map<String, Object?>?> read(String scope) async => value;
  @override
  Future<void> save(String scope, Map<String, Object?> draft) async {
    value = Map.of(draft);
  }

  @override
  Future<void> clear(String scope) async {
    value = null;
  }
}
