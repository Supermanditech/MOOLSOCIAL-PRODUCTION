import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:go_router/go_router.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/features/work/work_session.dart';
import 'package:moolsocial/features/work/work_models.dart';
import 'package:moolsocial/features/work/work_services.dart';
import 'package:moolsocial/features/work/screens/work_workspace_dashboard_screen.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_views.dart';
import 'package:moolsocial/features/work/work_order_identity_gateway.dart';
import 'package:moolsocial/features/work/widgets/workspace_purchase_originals.dart';
import 'work_order_identity_gateway_test.dart' as fixtures;

// Host-only account/journal fixtures, never installed evaluation records.
class _OrderAccount implements WorkPendingProofStore {
  @override
  String? get accountScope => 'owner-1';
  @override
  Future<Map<String, Object?>?> read(String scope) async => null;
  @override
  Future<void> save(String scope, Map<String, Object?> draft) async {}
  @override
  Future<void> clear(String scope) async {}
}
class _OrderPending implements WorkOrderPendingStore {
  final entries = <String, WorkOrderCommand>{};
  @override
  Future<List<WorkOrderCommand>> readPending(String accountScope, String workspaceId) async => entries.values.toList();
  @override
  Future<void> savePending(WorkOrderCommand command) async { entries[command.orderId] = command; }
  @override
  Future<void> removePending(WorkOrderCommand command) async { entries.remove(command.orderId); }
}

void main() {
  for (final kind in ['legacy', 'unknown', 'no supplied details']) {
    testWidgets('LF-CONTEXT absent original details and unrelated instructions add no blank section $kind', (tester) async {
      final data = kind == 'legacy' ? fixtures.publicListingPurchaseResponse()
        : fixtures.fulfilmentPurchaseResponse(unknown: kind == 'unknown');
      if (kind == 'no supplied details') {
        data['orders'][0]['original']['fulfilmentContext'] = {'schemaVersion': 1, 'method': 'delivery',
          'recipient': null, 'address': null, 'instructions': <Object>[]};
        fixtures.rehashPurchaseOrder(data['orders'][0]);
      }
      final original = (await fixtures.projectionGateway(fixtures.Transport()..data = data).readPurchaseProjection(
        role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', purchaseId: data['purchaseId']))!.orders.single;
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: Align(alignment: Alignment.topLeft,
        child: Column(mainAxisSize: MainAxisSize.min, children: [WorkspaceOriginalFulfilmentForOrder(original: original),
          WorkspaceOriginalInstructionsForLine(original: original, lineId: 'not-this-order')])))));
      expect(find.byType(Text), findsNothing); expect(tester.takeException(), isNull);
    });
  }
  testWidgets('LF-CONTEXT collection shows only supplied recipient without a delivery address or empty phone', (tester) async {
    final data = fixtures.fulfilmentPurchaseResponse(), order = data['orders'][0];
    order['original']['lines'][0]['scheduledFulfilment'] = null;
    order['original']['fulfilmentContext']['method'] = 'collection'; order['original']['fulfilmentContext']['address'] = null;
    order['original']['fulfilmentContext']['recipient']['phone'] = ''; fixtures.rehashPurchaseOrder(order);
    final original = (await fixtures.projectionGateway(fixtures.Transport()..data = data).readPurchaseProjection(
      role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', purchaseId: data['purchaseId']))!.orders.single;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: WorkspaceOriginalFulfilmentForOrder(original: original))));
    expect(find.text('Order collection details'), findsOneWidget); expect(find.text('Evaluation recipient'), findsOneWidget);
    expect(find.text('Order delivery details'), findsNothing); expect(find.textContaining('Evaluation house'), findsNothing);
    expect(tester.widgetList<Text>(find.byType(Text)).any((text) => text.data?.isEmpty == true), isFalse);
    expect(tester.takeException(), isNull);
  });
  for (final role in ['buyer', 'seller']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('LF-CONTEXT original recipient and line instructions are compact readable customer details $role scale=$scale', (tester) async {
        await tester.runAsync(() => (FontLoader('Inter')..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'))).load());
        tester.view.physicalSize = const Size(320, 900); tester.view.devicePixelRatio = 1; addTearDown(tester.view.reset);
        final details = fixtures.fulfilmentPurchaseResponse(role: role), order = details['orders'][0] as Map<String, dynamic>;
        order['original']['lines'][0]['name'] = 'Evaluation product'; // English host layout, not native Unicode acceptance.
        final note = List.filled(4, 'Leave the exact ordered pack at reception.').join(' ');
        order['original']['fulfilmentContext']['instructions'][0]['text'] = note;
        fixtures.rehashPurchaseOrder(order);
        final refs = fixtures.referenceResponse(role: role); refs['references'][0]['originalFingerprint'] = order['originalFingerprint'];
        final wire = fixtures.Transport()..respond = (body) => body['operation'].toString().startsWith('list') ? refs : details;
        final capture = GlobalKey();
        await tester.pumpWidget(RepaintBoundary(key: capture, child: MaterialApp(theme: ThemeData(fontFamily: 'Inter'), home: Scaffold(body: MediaQuery(data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: SingleChildScrollView(child: WorkspacePurchaseOriginals(gateway: fixtures.projectionGateway(wire,
            account: role == 'buyer' ? 'buyer-1' : 'owner-1'), role: role == 'buyer' ? WorkspaceOrderIdentityRole.buyer : WorkspaceOrderIdentityRole.seller,
            realm: 'evaluation', storeId: role == 'seller' ? 'store-one' : null)))))));
        await tester.pumpAndSettle(); await tester.tap(find.text('Saved purchase details')); await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('original-order-order-v2'))); await tester.pumpAndSettle();
        expect(find.text('Order delivery details'), findsOneWidget);
        expect(find.text('Evaluation recipient'), findsOneWidget); expect(find.text('9876501234'), findsOneWidget);
        expect(find.textContaining('Evaluation house 12'), findsOneWidget);
        final instructions = find.text('Instructions · $note'); expect(instructions, findsOneWidget);
        await tester.ensureVisible(instructions); await tester.pumpAndSettle();
        final text = tester.widget<Text>(instructions); expect(text.maxLines, isNull); expect(text.overflow, isNot(TextOverflow.ellipsis));
        expect(find.textContaining('address-book'), findsNothing); expect(find.text('Landmark'), findsNothing);
        expect(tester.takeException(), isNull);
        const captureRoot = String.fromEnvironment('LF_CONTEXT_CAPTURE_ROOT');
        if (captureRoot.isNotEmpty) {
          final boundary = capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final directory = Directory(captureRoot); await directory.create(recursive: true);
            final file = File('$captureRoot/original-context-$role-$scale.png'); expect(await file.exists(), isFalse);
            final image = await boundary.toImage(); final bytes = await image.toByteData(format: ui.ImageByteFormat.png); image.dispose();
            await file.writeAsBytes(bytes!.buffer.asUint8List());
          });
        }
      });
    }
  }
  for (final role in ['buyer', 'seller']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('LF-SCHEDULE original requested window is readable and not a booking $role $scale', (tester) async {
        await tester.runAsync(() => (FontLoader('Inter')..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'))).load());
        tester.view.physicalSize = const Size(320, 900); tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final details = fixtures.scheduledPurchaseResponse(role: role), order = details['orders'][0] as Map<String, dynamic>;
        final line = order['original']['lines'][0], selected = line['scheduledFulfilment'];
        line['name'] = 'Evaluation phone';
        selected['startsAt'] = '2026-10-15T17:30:00.123456Z';
        selected['endsAt'] = '2026-10-16T19:30:00.000001Z';
        fixtures.rehashPurchaseOrder(order);
        final refs = fixtures.referenceResponse(role: role);
        refs['references'][0]['originalFingerprint'] = order['originalFingerprint'];
        final wire = fixtures.Transport()..respond = (body) => body['operation'].toString().startsWith('list') ? refs : details;
        final capture = GlobalKey();
        await tester.pumpWidget(RepaintBoundary(key: capture, child: MaterialApp(theme: ThemeData(fontFamily: 'Inter'), home: Scaffold(body: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)), child: SingleChildScrollView(
            child: WorkspacePurchaseOriginals(gateway: fixtures.projectionGateway(wire,
              account: role == 'buyer' ? 'buyer-1' : 'owner-1'),
              role: role == 'buyer' ? WorkspaceOrderIdentityRole.buyer : WorkspaceOrderIdentityRole.seller,
              realm: 'evaluation', storeId: role == 'seller' ? 'store-one' : null)))))));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Saved purchase details')); await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('original-order-order-v2'))); await tester.pumpAndSettle();
        final window = find.byKey(const ValueKey('original-scheduled-line-one'));
        await tester.ensureVisible(window); await tester.pumpAndSettle();
        final text = tester.widget<Text>(window), local = MaterialLocalizations.of(tester.element(window));
        expect(text.data, contains('Requested Scheduled window'));
        expect(text.data, contains(local.formatFullDate(DateTime.parse(selected['startsAt'] as String).toLocal())));
        expect(text.data, contains(local.formatFullDate(DateTime.parse(selected['endsAt'] as String).toLocal())));
        expect(text.maxLines, isNull); expect(text.overflow, isNot(TextOverflow.ellipsis));
        expect(find.textContaining('opaque-destination'), findsNothing);
        expect(find.textContaining('eligibility-original'), findsNothing);
        expect(find.textContaining('slot-original'), findsNothing);
        expect(find.textContaining('Booking confirmed'), findsNothing);
        expect(tester.takeException(), isNull);
        const root = String.fromEnvironment('LF_SCHEDULE_CAPTURE_ROOT');
        if (root.isNotEmpty) {
          final boundary = capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final directory = Directory(root); await directory.create(recursive: true);
            final file = File('$root/requested-scheduled-$role-$scale.png'); expect(await file.exists(), isFalse);
            final image = await boundary.toImage(); final bytes = await image.toByteData(format: ui.ImageByteFormat.png); image.dispose();
            await file.writeAsBytes(bytes!.buffer.asUint8List());
          });
        }
      });
    }
  }
  for (final supplied in [false, true]) {
    testWidgets('LF-SCHEDULE null and legacy original create no empty controls $supplied', (tester) async {
      final wire = fixtures.Transport()..data = supplied ? fixtures.scheduledPurchaseResponse(selected: false) : fixtures.variantPurchaseResponse();
      final original = (await fixtures.projectionGateway(wire).readPurchaseProjection(role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation', purchaseId: 'purchase-v2'))!.orders.single;
      expect(original.lines.single.hasScheduledFulfilmentSnapshot, supplied);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: WorkspaceOriginalScheduledForLine(line: original.lines.single))));
      expect(find.byType(Text), findsNothing);
      expect(tester.getSize(find.byType(WorkspaceOriginalScheduledForLine)), Size.zero);
    });
  }
  for (final role in ['buyer', 'seller']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('LF-VARIANT original description is readable on $role originals $scale', (tester) async {
        await tester.runAsync(() => (FontLoader('Inter')..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'))).load());
        tester.view.physicalSize = const Size(320, 900); tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final details = fixtures.variantPurchaseResponse(role: role, variant: 'Pink · 128 GB\nDual SIM model, India pack');
        final order = details['orders'][0] as Map<String, dynamic>;
        order['original']['lines'][0]['name'] = 'Evaluation phone';
        fixtures.rehashPurchaseOrder(order);
        final refs = fixtures.referenceResponse(role: role);
        refs['references'][0]['originalFingerprint'] = order['originalFingerprint'];
        final wire = fixtures.Transport()..respond = (body) => body['operation'].toString().startsWith('list') ? refs : details;
        final capture = GlobalKey();
        await tester.pumpWidget(RepaintBoundary(key: capture, child: MaterialApp(theme: ThemeData(fontFamily: 'Inter'), home: Scaffold(body: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)), child: SingleChildScrollView(
            child: WorkspacePurchaseOriginals(gateway: fixtures.projectionGateway(wire,
              account: role == 'buyer' ? 'buyer-1' : 'owner-1'),
              role: role == 'buyer' ? WorkspaceOrderIdentityRole.buyer : WorkspaceOrderIdentityRole.seller,
              realm: 'evaluation', storeId: role == 'seller' ? 'store-one' : null)))))));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Saved purchase details')); await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('original-order-order-v2'))); await tester.pumpAndSettle();
        final variant = find.byKey(const ValueKey('original-variant-line-one'));
        await tester.ensureVisible(variant); await tester.pumpAndSettle();
        final text = tester.widget<Text>(variant);
        expect(text.data, 'Pink · 128 GB\nDual SIM model, India pack');
        expect(text.maxLines, isNull); expect(text.overflow, isNot(TextOverflow.ellipsis));
        expect(find.textContaining('Current catalogue'), findsNothing);
        expect(tester.takeException(), isNull);
        const root = String.fromEnvironment('LF_VARIANT_CAPTURE_ROOT');
        if (root.isNotEmpty) {
          final boundary = capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final directory = Directory(root); await directory.create(recursive: true);
            final file = File('$root/original-variant-$role-$scale.png');
            expect(await file.exists(), isFalse);
            final image = await boundary.toImage();
            final bytes = await image.toByteData(format: ui.ImageByteFormat.png); image.dispose();
            await file.writeAsBytes(bytes!.buffer.asUint8List());
          });
        }
      });
    }
  }
  for (final value in [null, '']) {
    testWidgets('LF-VARIANT unknown or explicitly empty original adds no blank section $value', (tester) async {
      final wire = fixtures.Transport()..data = value == null ? fixtures.attributedPurchaseResponse() : fixtures.variantPurchaseResponse(variant: value);
      final original = (await fixtures.projectionGateway(wire).readPurchaseProjection(
        role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', purchaseId: 'purchase-v2'))!.orders.single;
      expect(original.lines.single.variant, value);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: WorkspaceOriginalVariantForLine(line: original.lines.single))));
      expect(find.byType(Text), findsNothing);
      expect(tester.getSize(find.byType(WorkspaceOriginalVariantForLine)), Size.zero);
    });
  }
  for (final role in ['buyer', 'seller']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('LF-ATTR supplied benefits render exact money without funding-reference leaks $role $scale', (tester) async {
        await tester.runAsync(() => (FontLoader('Inter')..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'))).load());
        tester.view.physicalSize = const Size(320, 900); tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final details = fixtures.attributedPurchaseResponse(role: role), order = details['orders'][0];
        // The host has Inter but no Android Devanagari fallback. Use an explicit
        // English layout fixture; the actual Unicode service response is tested
        // separately through the strict client/hash boundary, not relabelled.
        order['original']['lines'][0]['name'] = 'Evaluation dal';
        fixtures.rehashPurchaseOrder(order as Map<String, dynamic>);
        final refs = fixtures.referenceResponse(role: role);
        refs['references'][0]['originalFingerprint'] = order['originalFingerprint'];
        final wire = fixtures.Transport()..respond = (body) => body['operation'].toString().startsWith('list') ? refs : details;
        final capture = GlobalKey();
        await tester.pumpWidget(RepaintBoundary(key: capture, child: MaterialApp(theme: ThemeData(fontFamily: 'Inter'), home: Scaffold(body: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)), child: SingleChildScrollView(
            child: WorkspacePurchaseOriginals(gateway: fixtures.projectionGateway(wire,
              account: role == 'buyer' ? 'buyer-1' : 'owner-1'),
              role: role == 'buyer' ? WorkspaceOrderIdentityRole.buyer : WorkspaceOrderIdentityRole.seller,
              realm: 'evaluation', storeId: role == 'seller' ? 'store-one' : null)))))));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Saved purchase details')); await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('original-order-order-v2'))); await tester.pumpAndSettle();
        expect(find.text('Supplier saving · Discount ₹0.51'), findsOneWidget);
        expect(find.text('Payment cashback offer · Up to ₹0.25 cashback · confirmation pending'), findsOneWidget);
        expect(find.text('₹100.15'), findsOneWidget);
        expect(find.textContaining('private-funder'), findsNothing);
        expect(find.textContaining('trusted-benefit'), findsNothing);
        expect(find.textContaining('Cashback paid'), findsNothing);
        expect(tester.takeException(), isNull);
        const root = String.fromEnvironment('LF_ATTR_CAPTURE_ROOT');
        if (root.isNotEmpty) {
          await tester.ensureVisible(find.byKey(const ValueKey('original-benefit-line-one-cashback-component')));
          await tester.pumpAndSettle();
          final boundary = capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final directory = Directory(root); await directory.create(recursive: true);
            final file = File('$root/original-benefits-$role-$scale.png');
            expect(await file.exists(), isFalse, reason: 'Preserve previous visual evidence; use a new capture root');
            final image = await boundary.toImage();
            final bytes = await image.toByteData(format: ui.ImageByteFormat.png); image.dispose();
            await file.writeAsBytes(bytes!.buffer.asUint8List());
          });
        }
      });
    }
  }
  for (final suppliedEmpty in [false, true]) {
    testWidgets('LF-ATTR absent and explicitly empty attribution create no empty visual sections $suppliedEmpty', (tester) async {
      final wire = fixtures.Transport()..data = suppliedEmpty ? fixtures.attributedPurchaseResponse(empty: true) : fixtures.purchaseResponse();
      final original = (await fixtures.projectionGateway(wire).readPurchaseProjection(
        role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', purchaseId: 'purchase-v2'))!.orders.single;
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: WorkspaceOriginalBenefitsForLine(original: original, lineId: 'line-one'))));
      expect(find.byType(Text), findsNothing);
      expect(tester.getSize(find.byType(WorkspaceOriginalBenefitsForLine)).height, 0);
      expect(tester.takeException(), isNull);
    });
  }
  for (final scale in [1.0, 2.0]) {
  testWidgets('ANALYTICS operational cold entry refresh and retirement use partial current positions $scale', (tester) async {
    tester.view.physicalSize = const Size(320, 900); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    final now = DateTime.fromMillisecondsSinceEpoch(DateTime.now().millisecondsSinceEpoch, isUtc: true);
    final raw = fixtures.operationalResponse(role: 'seller')
      ..['placedAt'] = now.subtract(const Duration(minutes: 10)).toIso8601String()
      ..['acceptanceDeadline'] = now.add(const Duration(hours: 1)).toIso8601String()
      ..['fulfilmentDeadline'] = now.add(const Duration(hours: 2)).toIso8601String();
    final wire = fixtures.Transport();
    wire.respond = (body) => body['operation'] == 'listStorePurchaseReferences'
      ? fixtures.referenceResponse(role: 'seller') : raw;
    final work = WorkSession(contactDraftStore: _OrderAccount(), operationalPendingStoreFactory: (_, _) => _OrderPending())
      ..seedVerifiedWorkspace()
      ..activeWorkspace = const WorkWorkspace(id: 'store-one', name: 'Store', profileLabel: 'Grocery / Kirana Shop',
        profileId: 'retailer-grocery', area: 'Jodhpur', verified: true)
      ..workspaceId = 'store-one' ..retailerSetupSaved = true ..reviewStage = WorkReviewStage.live;
    final localOrder = WorkspaceOrderRecord(id: 'manual-evaluation', customer: 'Host local customer', items: 'Host item',
      quantities: const {}, amount: 1, source: 'Phone', fulfilment: 'Pickup', payment: 'Unpaid', address: '',
      stage: 'Preparing', needsDelivery: false, createdAt: now, fulfilmentDeadline: now.add(const Duration(hours: 1)));
    work.workspaceOrders.add(localOrder);
    work.bindOriginalPurchaseReader(fixtures.projectionGateway(wire, account: 'owner-1'), 'evaluation');
    final stock = work.workspaceCatalogueItems.map((p) => p.toInventoryJson()).toList();
    final invoices = work.workspaceInvoices.toList(growable: false);
    final procurement = BuyV2Session(core: BuySession(), reviewDataEnabled: false);
    final router = GoRouter(initialLocation: '/app/work/workspace/dashboard', routes: [
      GoRoute(path: '/app/work/workspace/dashboard', builder: (context, state) => WorkWorkspaceDashboardScreen(
        session: work, procurementSession: procurement, initialSection: 'dashboard')),
    ]);
    addTearDown(router.dispose); addTearDown(work.dispose); addTearDown(procurement.dispose); addTearDown(procurement.core.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router,
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: child!)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-store-operating-board')), findsOneWidget);
    expect(find.text('Tracking not connected'), findsWidgets);
    expect(wire.requests.map((r) => r['operation']), ['listStorePurchaseReferences', 'readStoreOperationalOrder']);
    final preview = find.byKey(const Key('analytics-preview-orders'));
    expect(find.descendant(of: preview, matching: find.text('Known local and online orders · partial coverage')), findsOneWidget);
    final explore = find.byKey(const Key('analytics-preview-action-orders'));
    await tester.ensureVisible(explore); await tester.pumpAndSettle();
    await tester.tap(explore); await tester.pumpAndSettle();
    expect(find.text('Current order status · all dates'), findsOneWidget);
    String value(String id) => tester.widget<Text>(find.byKey(Key('store-overview-$id'))).data!;
    expect(value('recorded-open-orders'), '2'); expect(value('awaiting-acceptance'), '1');
    expect(find.text('Known local and online orders · partial coverage'), findsOneWidget);
    final calls = wire.calls;
    // Expanding and rebuilding must not issue another discovery pass.
    work.setWorkspaceMoneyPeriod('Today'); await tester.pumpAndSettle(); expect(wire.calls, calls);
    raw['stage'] = 'Preparing'; raw['revision'] = 2; raw['permittedActions'] = ['ready'];
    raw['acceptanceDeadline'] = now.subtract(const Duration(minutes: 5)).toIso8601String();
    raw['fulfilmentDeadline'] = now.subtract(const Duration(minutes: 1)).toIso8601String();
    final refresh = find.byTooltip('Refresh analytics');
    await tester.ensureVisible(refresh); await tester.tap(refresh); await tester.pumpAndSettle();
    expect(wire.calls, calls + 2); expect(value('awaiting-acceptance'), '0'); expect(value('overdue-fulfilment'), '1');
    await tester.ensureVisible(explore); await tester.tap(explore); await tester.pumpAndSettle();
    wire.fail = true;
    await tester.ensureVisible(refresh); await tester.tap(refresh); await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(const Key('analytics-preview-value-orders-0'))).data, '2');
    expect(find.descendant(of: preview, matching: find.text('Online refresh unavailable · retained partial records')), findsOneWidget);
    await tester.ensureVisible(explore); await tester.tap(explore); await tester.pumpAndSettle();
    expect(value('recorded-open-orders'), '2');
    work.bindOriginalPurchaseReader(null, ''); await tester.pumpAndSettle();
    expect(value('recorded-open-orders'), '1'); expect(value('overdue-fulfilment'), '0');
    expect(work.workspaceOrders.single, same(localOrder));
    expect(work.workspaceCatalogueItems.map((p) => p.toInventoryJson()).toList(), stock);
    expect(work.workspaceInvoices, invoices); expect(work.workspaceStockMovements, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  }
  for (final scenario in [(1.0, 'delivery'), (2.0, 'delivery'), (1.0, 'collection'), (1.0, 'attribution'), (2.0, 'attribution'), (1.0, 'variant'), (2.0, 'variant'), (1.0, 'scheduled'), (2.0, 'scheduled'),
    (1.0, 'context'), (2.0, 'context'), (1.0, 'context-partial'), (2.0, 'context-partial'),
    (1.0, 'gst'), (2.0, 'gst'), (1.0, 'gst-unknown'), (2.0, 'gst-unknown')]) {
  testWidgets('configured Store feed supports exact facts ${scenario.$2} scale ${scenario.$1}', (tester) async {
    await tester.runAsync(() => (FontLoader('Inter')..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'))).load());
    tester.view.physicalSize = const Size(320, 900); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    final raw = scenario.$2 == 'scheduled' ? fixtures.scheduledOperationalResponse(role: 'seller')
      : scenario.$2 == 'variant' ? fixtures.variantOperationalResponse(role: 'seller')
      : scenario.$2 == 'attribution' ? fixtures.attributedOperationalResponse(role: 'seller')
      : fixtures.operationalResponse(role: 'seller');
    if (scenario.$2.startsWith('context')) {
      final facts = fixtures.fulfilmentPurchaseResponse(role: 'seller'), original = facts['orders'][0];
      if (scenario.$2 == 'context-partial') {
        original['original']['fulfilmentContext']['address'] = {'line': '', 'area': '', 'pinCode': '', 'landmark': 'Gate B'};
        fixtures.rehashPurchaseOrder(original);
      }
      raw['original'] = original['original']; raw['originalFingerprint'] = original['originalFingerprint']; raw['originalFactsVersion'] = 7;
    }
    if (scenario.$2.startsWith('gst')) {
      final facts = scenario.$2 == 'gst-unknown' ? fixtures.supplierTaxPurchaseResponse(role: 'seller', declaration: null)
        : fixtures.supplierTaxPurchaseResponse(role: 'seller'), original = facts['orders'][0];
      raw['original'] = original['original']; raw['originalFingerprint'] = original['originalFingerprint']; raw['originalFactsVersion'] = 9;
    }
    if (scenario.$2 == 'collection') {
      raw['fulfilment'] = 'collection'; raw['stage'] = 'Preparing'; raw['permittedActions'] = <String>[];
    }
    final now = DateTime.fromMillisecondsSinceEpoch(DateTime.now().millisecondsSinceEpoch, isUtc: true);
    raw['placedAt'] = now.subtract(const Duration(minutes: 10)).toIso8601String();
    raw['acceptanceDeadline'] = now.add(const Duration(hours: 1)).toIso8601String();
    raw['fulfilmentDeadline'] = now.add(const Duration(hours: 2)).toIso8601String();
    final wire = fixtures.Transport();
    wire.respond = (body) {
      if (body['operation'] == 'listStorePurchaseReferences') {
        final refs = fixtures.referenceResponse(role: 'seller')..['storeId'] = 'store-one';
        refs['references'][0]['originalFingerprint'] = raw['originalFingerprint'];
        return refs;
      }
      if (body['operation'] == 'submitStoreOrderCommand') {
        raw['revision'] = (body['expectedRevision'] as int) + 1;
        raw['stage'] = body['action'] == 'accept' ? 'Preparing' : 'Ready';
        raw['permittedActions'] = body['action'] == 'accept' ? ['ready'] : <String>[];
        return {'schemaVersion': 1, 'operationId': body['operationId'], 'state': 'applied', 'snapshot': raw};
      }
      return raw;
    };
    final journal = _OrderPending();
    final work = WorkSession(contactDraftStore: _OrderAccount(), operationalPendingStoreFactory: (_, _) => journal)
      ..seedVerifiedWorkspace()
      ..activeWorkspace = const WorkWorkspace(id: 'store-one', name: 'Store', profileLabel: 'Grocery / Kirana Shop',
        profileId: 'retailer-grocery', area: 'Jodhpur', verified: true)
      ..workspaceId = 'store-one'
      ..retailerSetupSaved = true
      ..reviewStage = WorkReviewStage.live;
    work.bindOriginalPurchaseReader(fixtures.projectionGateway(wire, account: 'owner-1'), 'evaluation');
    final procurement = BuyV2Session(core: BuySession(), reviewDataEnabled: false);
    final router = GoRouter(initialLocation: '/app/work/workspace/dashboard', routes: [
      GoRoute(path: '/app/work/workspace/dashboard', builder: (context, state) => WorkWorkspaceDashboardScreen(
        session: work, procurementSession: procurement, initialSection: 'orders')),
    ]);
    addTearDown(router.dispose); addTearDown(work.dispose); addTearDown(procurement.dispose); addTearDown(procurement.core.dispose);
    final capture = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(key: capture, child: MaterialApp.router(routerConfig: router,
      theme: ThemeData(fontFamily: 'Inter'),
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scenario.$1)), child: child!))));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('work-operational-order-order-v2')), findsOneWidget);
    expect(find.text('Saved online orders · partial coverage'), findsOneWidget);
    if (scenario.$2 == 'delivery') {
    await tester.ensureVisible(find.byKey(const Key('work-operational-accept-order-v2')));
    await tester.tap(find.byKey(const Key('work-operational-accept-order-v2'))); await tester.pumpAndSettle();
    expect(work.workspaceOrders.single.stage, 'Preparing');
    await tester.ensureVisible(find.byKey(const Key('work-operational-pack-line-one')));
    await tester.tap(find.byKey(const Key('work-operational-pack-line-one'))); await tester.pumpAndSettle();
    expect(work.workspacePackingComplete, isTrue);
    await tester.ensureVisible(find.byKey(const Key('work-operational-ready-order-v2')));
    await tester.tap(find.byKey(const Key('work-operational-ready-order-v2'))); await tester.pumpAndSettle();
    expect(work.workspaceOrders.single.stage, 'Ready');
    expect(find.text('Arrange delivery'), findsNothing);
    } else if (scenario.$2 == 'collection') {
      expect(find.byKey(const Key('work-operational-pack-line-one')), findsNothing);
      expect(find.text('Collection actions are unavailable for this order.'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.byKey(const Key('work-operational-ready-order-v2'))).onPressed, isNull);
      expect(work.workspaceOrders.single.stage, 'Preparing');
    }
    await tester.ensureVisible(find.text('Review')); await tester.tap(find.text('Review')); await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-operational-details-order-v2')), findsOneWidget);
    for (final key in ['itemsMinor','discountMinor','taxMinor','deliveryMinor','freightMinor','paymentFeeMinor','tipMinor','totalMinor']) {
      expect(find.byKey(Key('work-operational-total-$key')), findsOneWidget);
    }
    expect(find.text('1 pack × ₹100.51'), findsOneWidget);
    if (scenario.$2.startsWith('gst')) {
      expect(find.text(scenario.$2 == 'gst-unknown' ? 'Supplier GST not recorded for this purchase'
        : 'Supplier-declared GST 5% · Included in the ordered price'), findsOneWidget);
      expect(work.workspaceOrders.single.operational!.original.factsVersion, 9);
      expect(work.workspaceOrders.single.operational!.original.totals['totalMinor'], 10015);
    }
    if (scenario.$2.startsWith('context')) {
      expect(find.text('Order delivery details'), findsOneWidget);
      expect(find.text('Evaluation recipient'), findsOneWidget);
      expect(find.text('Instructions · दरवाज़े पर दें'), findsOneWidget);
      expect(work.workspaceOrders.single.operational!.original.factsVersion, 7);
      expect(find.text('Delivery · ${raw['address']}'), scenario.$2 == 'context-partial' ? findsOneWidget : findsNothing);
    }
    if (scenario.$2 == 'scheduled') {
      expect(find.textContaining('Requested Scheduled window'), findsOneWidget);
      expect(find.textContaining('opaque-destination'), findsNothing);
      expect(work.workspaceOrders.single.operational!.original.factsVersion, 5);
    }
    if (scenario.$2 == 'variant') {
      expect(find.text('Pink · 128 GB'), findsOneWidget);
      expect(work.workspaceOrders.single.operational!.original.factsVersion, 4);
    }
    if (scenario.$2 == 'attribution') {
      expect(find.text('Supplier saving · Discount ₹0.51'), findsOneWidget);
      expect(find.text('Payment cashback offer · Up to ₹0.25 cashback · confirmation pending'), findsOneWidget);
      expect(find.textContaining('private-funder'), findsNothing);
      expect(work.workspaceOrders.single.operational!.original.factsVersion, 3);
    }
    if (const bool.fromEnvironment('MOOLSOCIAL_CAPTURE_OPERATIONAL_HOST')) {
      Future<void> captureView(String suffix) async {
        final boundary = capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png); image.dispose();
          final directory = Directory(const String.fromEnvironment('LF_OPERATIONAL_CAPTURE_ROOT',
            defaultValue: 'build/lf-operational-ui-20261017')); await directory.create(recursive: true);
          await File('${directory.path}/host-${scenario.$2}-${scenario.$1}-$suffix.png').writeAsBytes(bytes!.buffer.asUint8List());
        });
      }
      await captureView('details-top');
      if (scenario.$2.startsWith('gst')) {
        final declaration = find.byKey(const ValueKey('original-supplier-gst-line-one'));
        await tester.ensureVisible(declaration); await tester.pumpAndSettle();
        expect(declaration.hitTestable(), findsOneWidget);
        await captureView('supplier-gst');
      }
      await tester.ensureVisible(find.byKey(const Key('work-operational-total-totalMinor'))); await tester.pumpAndSettle();
      await captureView('details-total');
    }
    expect(work.workspaceInvoices, isEmpty); expect(work.workspaceStockMovements, isEmpty);
    expect(journal.entries, isEmpty); expect(tester.takeException(), isNull);
  });
  }
  testWidgets('typed operational Orders render exact facts without local invoice or delivery actions', (tester) async {
    final wire = fixtures.Transport()..data = fixtures.operationalResponse(role: 'seller');
    final gateway = AuthenticatedWorkspaceOrderOperationsGateway(fixtures.projectionGateway(wire, account: 'owner-1'));
    final snapshot = (await gateway.read(role: WorkspaceOrderIdentityRole.seller, realm: 'evaluation', reference: fixtures.operationalReference()))!;
    final work = WorkSession()
      ..seedVerifiedWorkspace()
      ..retailerSetupSaved = true
      ..reviewStage = WorkReviewStage.live
      ..workspaceStoreState = WorkspaceStoreState.open;
    work.workspaceOrders.add(WorkspaceOrderRecord.fromOperational(snapshot));
    final core = BuySession(), procurement = BuyV2Session(core: BuySession(), reviewDataEnabled: false);
    final router = GoRouter(initialLocation: '/app/work/workspace/dashboard', routes: [
      GoRoute(path: '/app/work/workspace/dashboard', builder: (context, state) => WorkWorkspaceDashboardScreen(
        session: work, procurementSession: procurement, initialSection: 'orders')),
    ]);
    addTearDown(router.dispose); addTearDown(work.dispose); addTearDown(procurement.dispose);
    addTearDown(procurement.core.dispose); addTearDown(core.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('work-operational-order-order-v2')), findsOneWidget);
    expect(find.text('Payment status unavailable'), findsWidgets);
    expect(find.text('Arrange delivery'), findsNothing);
    expect(find.text('More time'), findsNothing);
    expect(work.workspaceInvoices, isEmpty);
    expect(work.workspaceStockMovements, isEmpty);
  });
  test(
    'configured default root never creates a hosted reader for emulator identity',
    () {
      final previous = SharedPreferencesAsyncPlatform.instance;
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      addTearDown(() => SharedPreferencesAsyncPlatform.instance = previous);
      final core = BuySession();
      final root = BuyV2RootSessions(
        core: core,
        currentIdentity: () => (
          environment: jsonEncode(['firebase-emulator', '127.0.0.1', '', 9099]),
          projectId: 'moolsocial-dev-503018',
          tenantId: null as String?,
          userId: 'buyer-1',
        ),
      );
      addTearDown(core.dispose);
      root.synchronize(accountRequired: true);
      addTearDown(root.dispose);
      expect(root.current.purchaseReader, isNull);
    },
  );
  testWidgets(
    'actual Buy Orders consumes discovered facts without adding operational orders',
    (tester) async {
      final core = BuySession();
      final wire = fixtures.Transport()..data = fixtures.referenceResponse();
      final session = BuyV2Session(
        core: core,
        reviewDataEnabled: false,
        purchaseReader: fixtures.projectionGateway(wire),
        purchaseRealm: 'evaluation',
      );
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      var helpCalls = 0;
      await session.restoreCommerce();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BuyV2OrdersView(
              session: session,
              onOpenOrderHelp: (_) {
                helpCalls++;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        wire.calls,
        0,
        reason: 'Collapsed optional details do not fetch or steal queue space',
      );
      await tester.tap(find.text('Saved purchase details'));
      await tester.pumpAndSettle();
      wire.data = fixtures.purchaseResponse();
      await tester.tap(find.byKey(const ValueKey('original-order-order-v2')));
      await tester.pumpAndSettle();
      expect(find.text('₹100.15'), findsOneWidget);
      expect(session.visibleOrderHistory, isEmpty);
      expect(helpCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'root readers retire across A B A and Store binding rejects retired reader',
    () {
      TestWidgetsFlutterBinding.ensureInitialized();
      final previous = SharedPreferencesAsyncPlatform.instance;
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      addTearDown(() => SharedPreferencesAsyncPlatform.instance = previous);
      const a = (
        environment: 'host-only',
        projectId: 'host-project',
        tenantId: null as String?,
        userId: 'buyer-1',
      );
      const b = (
        environment: 'host-only',
        projectId: 'host-project',
        tenantId: null as String?,
        userId: 'buyer-2',
      );
      BuyV2AccountPersistenceIdentity? identity = a;
      final core = BuySession(), work = WorkSession();
      final root = BuyV2RootSessions(
        core: core,
        currentIdentity: () => identity,
        purchaseRealm: 'evaluation',
        purchaseReaderFactory: (owner, alive) => fixtures.projectionGateway(
          fixtures.Transport(),
          account: owner.userId,
          lifetime: () => alive() ? owner : null,
        ),
      );
      addTearDown(core.dispose);
      addTearDown(work.dispose);
      addTearDown(root.dispose);
      root.synchronize(accountRequired: true);
      final first = root.current.purchaseReader!;
      work.bindOriginalPurchaseReader(first, root.current.purchaseRealm);
      expect(work.originalPurchaseReader, same(first));
      identity = b;
      root.synchronize(accountRequired: true);
      expect(first.isCurrent, isFalse);
      expect(work.originalPurchaseReader, isNull);
      identity = a;
      root.synchronize(accountRequired: true);
      expect(first.isCurrent, isFalse);
      expect(root.current.purchaseReader!.isCurrent, isTrue);
      expect(identical(first, root.current.purchaseReader), isFalse);
      identity = null;
      root.synchronize(accountRequired: false);
      expect(root.current.purchaseReader, isNull);
    },
  );
  testWidgets(
    'actual Store Orders consumes originals without changing the operational queue',
    (tester) async {
      final work = WorkSession()
        ..seedVerifiedWorkspace()
        ..retailerSetupSaved = true
        ..reviewStage = WorkReviewStage.live
        ..workspaceStoreState = WorkspaceStoreState.open;
      final core = BuySession(),
          procurement = BuyV2Session(
            core: BuySession(),
            reviewDataEnabled: false,
          );
      final storeId = work.activeWorkspace!.id;
      final wire = fixtures.Transport()
        ..data = fixtures.referenceResponse(role: 'seller');
      wire.data['storeId'] = storeId;
      wire.data['references'][0]['storeId'] = storeId;
      final data = fixtures.purchaseResponse(role: 'seller');
      data['orders'][0]['storeId'] = storeId;
      final fingerprint = sha256
          .convert(
            utf8.encode(
              jsonEncode({
                'factsVersion': 2,
                'storeId': storeId,
                'orderId': 'order-v2',
                'original': data['orders'][0]['original'],
              }),
            ),
          )
          .toString();
      wire.data['references'][0]['originalFingerprint'] = fingerprint;
      data['orders'][0]['originalFingerprint'] = fingerprint;
      work.bindOriginalPurchaseReader(
        fixtures.projectionGateway(wire, account: 'owner-1'),
        'evaluation',
      );
      final before = List.of(work.workspaceOrders);
      final router = GoRouter(
        initialLocation: '/app/work/workspace/dashboard',
        routes: [
          GoRoute(
            path: '/app/work/workspace/dashboard',
            builder: (context, state) => WorkWorkspaceDashboardScreen(
              session: work,
              procurementSession: procurement,
              initialSection: 'orders',
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      addTearDown(work.dispose);
      addTearDown(procurement.dispose);
      addTearDown(procurement.core.dispose);
      addTearDown(core.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-orders-destination')), findsOneWidget);
      await tester.tap(find.text('Saved purchase details'));
      await tester.pumpAndSettle();
      wire.data = data;
      await tester.tap(find.byKey(const ValueKey('original-order-order-v2')));
      await tester.pumpAndSettle();
      expect(find.text('₹100.15'), findsOneWidget);
      expect(work.workspaceOrders, orderedEquals(before));
      expect(wire.sent!['operation'], 'readStorePurchaseProjection');
      expect(wire.sent!['storeId'], storeId);
      final update = fixtures.operationalResponse(role: 'seller')
        ..['storeId'] = storeId
        ..['originalFingerprint'] = fingerprint;
      wire.data = update;
      await tester.ensureVisible(find.text('Check order update'));
      await tester.tap(find.text('Check order update'));
      await tester.pumpAndSettle();
      expect(find.text('Awaiting Store acceptance'), findsOneWidget);
      expect(wire.requests.any((r) => r['operation'] == 'readStoreOperationalOrder'), isTrue);
      expect(wire.requests.any((r) => r['operation'] == 'readStoreOrderCompletion'), isTrue);
      expect(work.workspaceOrders, orderedEquals(before));
      expect(tester.takeException(), isNull);
    },
  );
  Future<void> mount(
    WidgetTester tester,
    AuthenticatedWorkspaceOrderIdentityGateway gateway, {
    double scale = 1,
    WorkspaceOrderIdentityRole role = WorkspaceOrderIdentityRole.buyer,
    GlobalKey? capture,
    ThemeData? theme,
  }) async {
    final app = MaterialApp(theme: theme,
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: SingleChildScrollView(
              child: WorkspacePurchaseOriginals(
                gateway: gateway,
                role: role,
                realm: 'evaluation',
                storeId: role == WorkspaceOrderIdentityRole.seller ? 'store-one' : null,
              ),
            ),
          ),
        ),
      );
    await tester.pumpWidget(capture == null ? app : RepaintBoundary(key: capture, child: app));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved purchase details'));
    await tester.pumpAndSettle();
  }

  for (final role in WorkspaceOrderIdentityRole.values) {
    for (final scale in [1.0, 2.0]) {
      for (final collected in [false, true]) {
        testWidgets('LF-COMPLETE shared details render exact completion and retain it on failed or contradictory refresh ${role.name} $scale $collected', (tester) async {
          await tester.runAsync(() => (FontLoader('Inter')..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'))).load());
          tester.view.physicalSize = const Size(320, 850); tester.view.devicePixelRatio = 1; addTearDown(tester.view.reset);
          final op = fixtures.operationalResponse(role: role.name)..['stage'] = 'Ready'..['revision'] = 3..['permittedActions'] = <String>[];
          op['fulfilment'] = collected ? 'collection' : 'delivery';
          final completion = {for (final key in const ['schemaVersion', 'realm', 'authNamespace', 'viewerRole', 'viewerUserId',
            'purchaseId', 'storeId', 'orderId', 'sourceRevision', 'originalFingerprint']) key: op[key],
            'state': 'recorded', 'completion': {'id': 'completion-${'a' * 64}', 'revision': 'completion-v1',
              'outcome': collected ? 'collected' : 'delivered', 'occurredAt': '2026-10-16T12:01:00.000Z', 'recordedAt': '2026-10-16T12:01:01.000Z'}};
          final wire = fixtures.Transport()..respond = (body) {
            final operation = body['operation'].toString();
            return operation.startsWith('list') ? fixtures.referenceResponse(role: role.name)
              : operation.endsWith('OrderCompletion') ? completion
              : operation.endsWith('OperationalOrder') ? op : fixtures.purchaseResponse(role: role.name);
          };
          final capture = GlobalKey();
          await mount(tester, fixtures.projectionGateway(wire, account: role == WorkspaceOrderIdentityRole.buyer ? 'buyer-1' : 'owner-1'),
            role: role, scale: scale, capture: capture, theme: MoolTheme.light());
          await tester.tap(find.byKey(const ValueKey('original-order-order-v2'))); await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('Check order update')); await tester.tap(find.text('Check order update')); await tester.pumpAndSettle();
          final expected = collected ? 'Collected' : 'Delivered';
          expect(find.text(expected), findsOneWidget);
          expect(find.byKey(const ValueKey('purchase-order-completion-order-v2')), findsOneWidget);
          if (Platform.environment['LF_COMPLETION_CAPTURE_DIR'] case final path?) {
            if (scale == 2 && (role == WorkspaceOrderIdentityRole.buyer) != collected) {
              await tester.ensureVisible(find.text(expected)); await tester.pumpAndSettle();
              await tester.runAsync(() async {
                final boundary = capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
                final image = await boundary.toImage();
                try {
                  final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
                  await Directory(path).create(recursive: true);
                  final file = File('$path/host-completion-${role.name}-${collected ? 'collected' : 'delivered'}-320-2x.png');
                  if (await file.exists()) throw StateError('Preserve the prior capture; choose a new output directory.');
                  await file.writeAsBytes(bytes.buffer.asUint8List());
                } finally {image.dispose();}
              });
            }
          }
          completion['state'] = 'not_supplied'; completion['completion'] = null;
          await tester.ensureVisible(find.text('Refresh order update')); await tester.tap(find.text('Refresh order update')); await tester.pumpAndSettle();
          expect(find.text(expected), findsOneWidget);
          expect(find.text('Latest completion update unavailable; showing the recorded result.'), findsOneWidget);
          wire.fail = true;
          await tester.tap(find.text('Refresh order update')); await tester.pumpAndSettle();
          expect(find.text(expected), findsOneWidget);
          expect(find.text('Pay'), findsNothing); expect(find.text('Accept order'), findsNothing);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('LF-COMPLETE contradictory preparation and completion fulfilment cannot display success', (tester) async {
    final op = fixtures.operationalResponse()..['stage'] = 'Ready'..['permittedActions'] = <String>[];
    final completion = {for (final key in const ['schemaVersion', 'realm', 'authNamespace', 'viewerRole', 'viewerUserId',
      'purchaseId', 'storeId', 'orderId', 'sourceRevision', 'originalFingerprint']) key: op[key],
      'state': 'recorded', 'completion': {'id': 'completion-${'a' * 64}', 'revision': 'completion-v1',
        'outcome': 'collected', 'occurredAt': '2026-10-16T12:01:00.000Z', 'recordedAt': '2026-10-16T12:01:01.000Z'}};
    final wire = fixtures.Transport()..respond = (body) {
      final action = body['operation'].toString();
      return action.startsWith('list') ? fixtures.referenceResponse()
        : action.endsWith('OrderCompletion') ? completion
        : action.endsWith('OperationalOrder') ? op : fixtures.purchaseResponse();
    };
    await mount(tester, fixtures.projectionGateway(wire));
    await tester.tap(find.byKey(const ValueKey('original-order-order-v2'))); await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Check order update')); await tester.tap(find.text('Check order update')); await tester.pumpAndSettle();
    expect(find.text('Collected'), findsNothing); expect(find.text('Delivered'), findsNothing);
    expect(find.text('Delivery/collection update unavailable.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final drift in ['missing', 'older', 'same-revision-mode']) {
    testWidgets('LF-COMPLETE retained delivery mode fences completion after $drift preparation', (tester) async {
      var nextRead = false;
      final op = fixtures.operationalResponse()..['revision'] = 2..['stage'] = 'Preparing';
      final completion = {for (final key in const ['schemaVersion', 'realm', 'authNamespace', 'viewerRole', 'viewerUserId',
        'purchaseId', 'storeId', 'orderId', 'sourceRevision', 'originalFingerprint']) key: op[key],
        'state': 'recorded', 'completion': {'id': 'completion-${'a' * 64}', 'revision': 'completion-v1',
          'outcome': 'collected', 'occurredAt': '2026-10-16T12:01:00.000Z', 'recordedAt': '2026-10-16T12:01:01.000Z'}};
      final wire = fixtures.Transport()..respond = (body) {
        final operation = body['operation'].toString();
        if (operation.startsWith('list')) return fixtures.referenceResponse();
        if (operation.endsWith('OrderCompletion')) return nextRead ? completion : {...completion, 'state': 'not_supplied', 'completion': null};
        if (operation.endsWith('OperationalOrder')) {
          return !nextRead ? op : drift == 'missing' ? <String, dynamic>{}
            : {...op, 'revision': drift == 'older' ? 1 : 2, 'fulfilment': 'collection'};
        }
        return fixtures.purchaseResponse();
      };
      await mount(tester, fixtures.projectionGateway(wire));
      await tester.tap(find.byKey(const ValueKey('original-order-order-v2'))); await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Check order update')); await tester.tap(find.text('Check order update')); await tester.pumpAndSettle();
      expect(find.text('Preparing'), findsOneWidget);
      nextRead = true;
      await tester.tap(find.text('Refresh order update')); await tester.pumpAndSettle();
      expect(find.text('Preparing'), findsOneWidget); expect(find.text('Collected'), findsNothing);
      expect(find.byKey(const ValueKey('purchase-order-completion-order-v2')), findsNothing);
      expect(find.text('Delivery/collection update unavailable.'), findsOneWidget); expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'buyer original details consume real typed order updates without payment authority',
    (tester) async {
      final wire = fixtures.Transport()..data = fixtures.referenceResponse();
      await mount(tester, fixtures.projectionGateway(wire));
      wire.data = fixtures.purchaseResponse();
      await tester.tap(find.byKey(const ValueKey('original-order-order-v2')));
      await tester.pumpAndSettle();
      wire.data = fixtures.operationalResponse();
      await tester.ensureVisible(find.text('Check order update'));
      await tester.tap(find.text('Check order update'));
      await tester.pumpAndSettle();
      expect(find.text('Awaiting Store acceptance'), findsOneWidget);
      expect(wire.requests.any((r) => r['operation'] == 'readBuyerOperationalOrder'), isTrue);
      expect(wire.requests.any((r) => r['operation'] == 'readBuyerOrderCompletion'), isTrue);
      wire.data
        ..['revision'] = 2
        ..['stage'] = 'Preparing';
      await tester.tap(find.text('Refresh order update'));
      await tester.pumpAndSettle();
      expect(find.text('Preparing'), findsOneWidget);
      wire.data
        ..['revision'] = 1
        ..['stage'] = 'Confirmed';
      await tester.tap(find.text('Refresh order update'));
      await tester.pumpAndSettle();
      expect(find.text('Preparing'), findsOneWidget);
      expect(
        find.text('Update unavailable; showing earlier status.'),
        findsOneWidget,
      );
      expect(find.text('Pay'), findsNothing);
      expect(find.text('Accept order'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'discovered originals expand in place, exact paise and no commercial actions',
    (tester) async {
      final wire = fixtures.Transport()..data = fixtures.referenceResponse();
      await mount(tester, fixtures.projectionGateway(wire));
      expect(find.text('Saved purchase details'), findsOneWidget);
      wire.data = fixtures.purchaseResponse();
      await tester.tap(find.byKey(const ValueKey('original-order-order-v2')));
      await tester.pumpAndSettle();
      expect(find.text('दाल'), findsOneWidget);
      expect(find.text('₹100.15'), findsOneWidget);
      expect(find.text('1 pack · 1 kg'), findsOneWidget);
      for (final action in [
        'Pay',
        'Accept order',
        'Pack',
        'Cancel order',
        'Refund',
        'Mark delivered',
      ]) {
        expect(find.text(action), findsNothing);
      }
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'narrow enlarged-text exact amounts do not overflow or disappear',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final wire = fixtures.Transport()..data = fixtures.referenceResponse();
      await mount(tester, fixtures.projectionGateway(wire), scale: 2);
      wire.data = fixtures.purchaseResponse();
      await tester.tap(find.byKey(const ValueKey('original-order-order-v2')));
      await tester.pumpAndSettle();
      expect(find.text('₹100.15'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('unavailable and empty coverage never claim zero online orders', (
    tester,
  ) async {
    final wire = fixtures.Transport()
      ..data = fixtures.referenceResponse()
      ..fail = true;
    await mount(tester, fixtures.projectionGateway(wire));
    expect(find.text('Purchase details unavailable'), findsOneWidget);
    wire.fail = false;
    wire.data['references'] = [];
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('not the complete online order list'),
      findsOneWidget,
    );
    expect(find.text('No orders'), findsNothing);
  });
  testWidgets(
    'retry preserves failed continuation even when preceding page was empty',
    (tester) async {
      final wire = fixtures.Transport()
        ..data = fixtures.referenceResponse()
        ..data['references'] = []
        ..data['nextCursor'] = 'scanned-page';
      await mount(tester, fixtures.projectionGateway(wire));
      wire.fail = true;
      await tester.tap(find.text('Load more purchase details'));
      await tester.pumpAndSettle();
      expect(wire.sent!['cursor'], 'scanned-page');
      wire.fail = false;
      wire.data['nextCursor'] = null;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(wire.sent!['cursor'], 'scanned-page');
    },
  );
  testWidgets(
    'late retired-owner discovery cannot repopulate a replacement widget',
    (tester) async {
      Object? owner = Object();
      final old = fixtures.Transport()
        ..data = fixtures.referenceResponse()
        ..pending = Completer<void>();
      final first = fixtures.projectionGateway(old, lifetime: () => owner);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkspacePurchaseOriginals(
              gateway: first,
              role: WorkspaceOrderIdentityRole.buyer,
              realm: 'evaluation',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Saved purchase details'));
      await tester.pump();
      owner = null;
      final fresh = fixtures.Transport()
        ..data = fixtures.referenceResponse()
        ..data['references'] = [];
      await mount(tester, fixtures.projectionGateway(fresh));
      old.pending!.complete();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('original-order-order-v2')),
        findsNothing,
      );
    },
  );
  testWidgets(
    '1000 crore exact total fits at 320px enlarged text without horizontal scrolling',
    (tester) async {
      tester.view.physicalSize = const Size(320, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final data = fixtures.purchaseResponse();
      final original = data['orders'][0]['original'];
      original['lines'][0]['unitPriceMinor'] = 1000000000000;
      original['lines'][0]['lineTotalMinor'] = 1000000000000;
      for (final key in (original['totals'] as Map).keys) {
        original['totals'][key] = 0;
      }
      original['totals']['itemsMinor'] = original['totals']['totalMinor'] =
          1000000000000;
      final hash = sha256
          .convert(
            utf8.encode(
              jsonEncode({
                'factsVersion': 2,
                'storeId': 'store-one',
                'orderId': 'order-v2',
                'original': original,
              }),
            ),
          )
          .toString();
      data['orders'][0]['originalFingerprint'] = hash;
      final wire = fixtures.Transport()..data = fixtures.referenceResponse();
      wire.data['references'][0]['originalFingerprint'] = hash;
      await mount(tester, fixtures.projectionGateway(wire), scale: 2);
      wire.data = data;
      await tester.tap(find.byKey(const ValueKey('original-order-order-v2')));
      await tester.pumpAndSettle();
      final amounts = find.text('₹10,00,00,00,000.00');
      expect(amounts, findsWidgets);
      for (final e in amounts.evaluate()) {
        final paragraph = e.renderObject! as RenderParagraph;
        expect(paragraph.didExceedMaxLines, isFalse);
        final target = find.byElementPredicate((x) => identical(x, e));
        expect(
          find.ancestor(
            of: target,
            matching: find.byWidgetPredicate(
              (w) =>
                  w is SingleChildScrollView &&
                  w.scrollDirection == Axis.horizontal,
            ),
          ),
          findsNothing,
        );
        final boxes = paragraph.getBoxesForSelection(
          const TextSelection(baseOffset: 0, extentOffset: 18),
        );
        expect(boxes.every((b) => b.right <= paragraph.size.width + 1), isTrue);
      }
      expect(tester.takeException(), isNull);
    },
  );
}
