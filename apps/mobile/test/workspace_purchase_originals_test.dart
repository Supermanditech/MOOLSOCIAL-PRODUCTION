import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/rendering.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/assistant/mool_assistant.dart';
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
  registerOrder02LateAckTests();
  registerOrder02BaselineCorrectionTests();
  registerOrder02NativeTests();
  for (final layout in [(360.0, 760.0, 1.0), (320.0, 640.0, 2.0), (720.0, 360.0, 1.0)]) {
    for (final kind in ['orderAmendment', 'orderCancellation']) {
      testWidgets('F2CHANGE $kind layout ${layout.$1} text${layout.$3}', (tester) async {
        await tester.binding.setSurfaceSize(Size(layout.$1, layout.$2)); addTearDown(() => tester.binding.setSurfaceSize(null));
        final source = fixtures.OrderDocumentSourceFixture();
        source.onRead = (target) async => WorkspaceOrderDocumentsRead(targetBinding: target.binding, revision: 2,
          documents: [source.document(), fixtures.orderChangeFixture(kind: kind)]);
        final gateway = fixtures.projectionGateway(fixtures.Transport()..data = fixtures.purchaseResponse(), orderDocumentSource: source);
        await tester.pumpWidget(MaterialApp(theme: MoolTheme.light(), home: MediaQuery(data: MediaQueryData(
          size: Size(layout.$1, layout.$2), textScaler: TextScaler.linear(layout.$3)), child: Scaffold(body: RepaintBoundary(
            key: const ValueKey('change-evidence'), child: Material(color: MoolColors.canvas, child: SingleChildScrollView(
              padding: const EdgeInsets.all(12), child: WorkspaceOrderDocumentsForOrder(gateway: gateway,
                target: WorkspaceOrderDocumentTarget(accountUserId: 'buyer-1', role: WorkspaceOrderIdentityRole.buyer,
                  realm: 'evaluation', reference: fixtures.operationalReference())))))))));
        await tester.tap(find.text('Order documents')); await tester.pumpAndSettle();
        final number = kind == 'orderAmendment' ? 'AM/2026/014' : 'CN/2026/014';
        await tester.ensureVisible(find.text(number)); await tester.tap(find.text(number)); await tester.pumpAndSettle();
        expect(find.text('Previous document: PO/2026/014 · Revision 1'), findsOneWidget);
        expect(find.text('Before: 10 bags'), findsOneWidget);
        expect(find.text(kind == 'orderCancellation' ? 'In this document: 2 bags cancelled; 8 bags remain' : 'In this document: 8 bags'), findsOneWidget);
        expect(find.text(kind == 'orderCancellation' ? 'Reason: Supplier cannot supply the balance' : 'Reason: Revised delivery and quantity'), findsOneWidget);
        expect(find.text(kind == 'orderCancellation' ? 'Document outcome: Partial cancellation recorded' : 'Document outcome: Amendment recorded'), findsOneWidget);
        expect(find.text('Current order status is shown separately.'), findsOneWidget);
        expect(find.textContaining('Linked documents: PO/2026/014'), findsNothing);
        expect(find.textContaining('Effective from:'), findsOneWidget);
        expect(tester.takeException(), isNull);
        const evidence = String.fromEnvironment('F2_CHANGE_EVIDENCE_DIR');
        if (evidence.isNotEmpty) {
          await tester.scrollUntilVisible(find.textContaining('Previous document:'), 100, scrollable: find.byType(Scrollable).first);
          await tester.pumpAndSettle();
          final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('change-evidence')));
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 1), bytes = await image.toByteData(format: ui.ImageByteFormat.png);
            await File('$evidence/$kind-${layout.$1}-${layout.$3}.png').writeAsBytes(bytes!.buffer.asUint8List()); image.dispose();
          });
        }
        final previous = find.text('View previous original'); await tester.ensureVisible(previous); await tester.tap(previous); await tester.pumpAndSettle();
        expect(find.byType(InteractiveViewer), findsOneWidget);
        source.isCurrent = false; source.notifyListeners(); await tester.pumpAndSettle();
        expect(find.byType(InteractiveViewer), findsNothing); expect(tester.takeException(), isNull);
      });
    }
  }
  for (final details in ['missing', 'partial', 'wrong-link']) {
    testWidgets('F2CHANGE $details particulars remain truthful', (tester) async {
      final source = fixtures.OrderDocumentSourceFixture();
      source.onRead = (target) async => WorkspaceOrderDocumentsRead(targetBinding: target.binding, revision: 2, documents: [
        WorkspaceOrderDocument(id: 'doc-change', kind: 'orderCancellation', number: 'CN/014', revision: 1,
          date: DateTime.utc(2026, 10, 25), particulars: const {}, changes: details == 'missing' ? null :
            WorkspaceOrderDocumentChanges(reason: 'Supplier could not supply', previousDocumentId: details == 'wrong-link' ? 'missing-doc' : null,
              previousDocumentRevision: details == 'wrong-link' ? 1 : null))]);
      final gateway = fixtures.projectionGateway(fixtures.Transport()..data = fixtures.purchaseResponse(), orderDocumentSource: source);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: WorkspaceOrderDocumentsForOrder(gateway: gateway,
        target: WorkspaceOrderDocumentTarget(accountUserId: 'buyer-1', role: WorkspaceOrderIdentityRole.buyer,
          realm: 'evaluation', reference: fixtures.operationalReference()))))));
      await tester.tap(find.text('Order documents')); await tester.pumpAndSettle();
      if (details == 'wrong-link') {
        expect(find.text('Documents for this order are unavailable.'), findsOneWidget); expect(find.text('CN/014'), findsNothing);
      } else {
        await tester.tap(find.text('CN/014')); await tester.pumpAndSettle();
        expect(find.text(details == 'missing' ? 'Change details have not been supplied.' : 'Affected items or terms have not been supplied.'), findsOneWidget);
        expect(find.text('View previous original'), findsNothing);
      }
      expect(tester.takeException(), isNull);
    });
  }
  for (final role in WorkspaceOrderIdentityRole.values) {
    testWidgets('F2DOC printed title stays original for ${role.name}', (tester) async {
      final account = role == WorkspaceOrderIdentityRole.buyer ? 'buyer-1' : 'owner-1';
      final source = fixtures.OrderDocumentSourceFixture(accountUserId: account);
      final gateway = fixtures.projectionGateway(fixtures.Transport()..data = fixtures.purchaseResponse(role: role.name),
        account: account, orderDocumentSource: source);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: WorkspaceOrderDocumentsForOrder(gateway: gateway,
        target: WorkspaceOrderDocumentTarget(accountUserId: account, role: role, realm: 'evaluation', reference: fixtures.operationalReference())))));
      await tester.tap(find.text('Order documents')); await tester.pumpAndSettle();
      expect(find.textContaining('Purchase order ·'), findsOneWidget);
      expect(find.textContaining('Sales order ·'), findsNothing);
    });
  }
  testWidgets('F2DOC missing printed title uses neutral document type', (tester) async {
    final source = fixtures.OrderDocumentSourceFixture();
    source.onRead = (target) async => WorkspaceOrderDocumentsRead(targetBinding: target.binding, revision: 1,
      documents: [WorkspaceOrderDocument(id: 'doc-order', kind: 'purchaseOrder', number: 'PO/014', revision: 1,
        date: DateTime.utc(2026, 10, 25), particulars: const {})]);
    final gateway = fixtures.projectionGateway(fixtures.Transport()..data = fixtures.purchaseResponse(), orderDocumentSource: source);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: WorkspaceOrderDocumentsForOrder(gateway: gateway,
      target: WorkspaceOrderDocumentTarget(accountUserId: 'buyer-1', role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation', reference: fixtures.operationalReference())))));
    await tester.tap(find.text('Order documents')); await tester.pumpAndSettle();
    expect(find.textContaining('Purchase order / Sales order ·'), findsOneWidget);
  });
  for (final layout in [(360.0, 720.0, 1.0), (320.0, 640.0, 2.0), (720.0, 360.0, 1.0)]) {
    testWidgets('F2DOC compact linked details ${layout.$1} text${layout.$3}', (tester) async {
      await tester.binding.setSurfaceSize(Size(layout.$1, layout.$2));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final source = fixtures.OrderDocumentSourceFixture();
      source.onRead = (target) async => WorkspaceOrderDocumentsRead(targetBinding: target.binding, revision: 1,
        documents: [source.document(links: ['doc-confirm']), source.document(id: 'doc-confirm', kind: 'orderConfirmation')]);
      final gateway = fixtures.projectionGateway(fixtures.Transport()..data = fixtures.purchaseResponse(), orderDocumentSource: source);
      Widget page() => MaterialApp(theme: MoolTheme.light(), home: MediaQuery(
        data: MediaQueryData(size: Size(layout.$1, layout.$2), textScaler: TextScaler.linear(layout.$3)),
        child: Scaffold(body: RepaintBoundary(key: const ValueKey('f2-documents-evidence'),
          child: Material(color: MoolColors.canvas, child: SingleChildScrollView(padding: const EdgeInsets.all(12), child: WorkspaceOrderDocumentsForOrder(gateway: gateway,
            target: WorkspaceOrderDocumentTarget(accountUserId: 'buyer-1', role: WorkspaceOrderIdentityRole.buyer,
              realm: 'evaluation', reference: fixtures.operationalReference()), inputCurrent: () => true)))))));
      await tester.pumpWidget(page());
      await tester.tap(find.text('Order documents')); await tester.pumpAndSettle();
      expect(find.text('PO/2026/014'), findsOneWidget);
      await tester.tap(find.text('PO/2026/014').first); await tester.pumpAndSettle();
      expect(find.text('Payment terms: Against delivery'), findsOneWidget);
      expect(find.text('Linked documents: OC/2026/014'), findsOneWidget);
      expect(find.textContaining('2026').evaluate().length, greaterThanOrEqualTo(3));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(page()); await tester.pumpAndSettle();
      expect(find.text('Payment terms: Against delivery'), findsOneWidget);
      const evidence = String.fromEnvironment('F2_DOCUMENT_EVIDENCE_DIR');
      if (evidence.isNotEmpty) {
        final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('f2-documents-evidence')));
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('$evidence/documents-${layout.$1}-${layout.$3}.png').writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.ensureVisible(find.text('View original').first); await tester.tap(find.text('View original').first);
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsOneWidget); expect(find.text('This copy could not be displayed.'), findsNothing);
      source.isCurrent = false; source.notifyListeners(); await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsNothing);
      expect(find.text('Return to the order and refresh its documents.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  for (final state in ['empty', 'unavailable', 'error']) {
    testWidgets('F2DOC truthful $state and retry', (tester) async {
      final source = fixtures.OrderDocumentSourceFixture()..empty = state == 'empty';
      if (state == 'error') { source.onRead = (_) async => throw StateError('Host unavailable'); }
      final gateway = fixtures.projectionGateway(fixtures.Transport()..data = fixtures.purchaseResponse(),
        orderDocumentSource: state == 'unavailable' ? null : source);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: WorkspaceOrderDocumentsForOrder(gateway: gateway,
        target: WorkspaceOrderDocumentTarget(accountUserId: 'buyer-1', role: WorkspaceOrderIdentityRole.buyer,
          realm: 'evaluation', reference: fixtures.operationalReference())))));
      await tester.tap(find.text('Order documents')); await tester.pumpAndSettle();
      if (state == 'empty') { expect(find.text('No documents are linked to this order.'), findsOneWidget); }
      else {
        expect(find.text('Documents for this order are unavailable.'), findsOneWidget);
        expect(find.text('No documents are linked to this order.'), findsNothing);
        source.onRead = null;
        await tester.tap(find.text('Retry documents')); await tester.pumpAndSettle();
        expect(find.text('PO/2026/014'), state == 'error' ? findsOneWidget : findsNothing);
      }
      expect(tester.takeException(), isNull);
    });
  }
  for (final retirement in ['collapse', 'scope', 'source', 'background', 'dispose']) {
    testWidgets('F2DOC pending read retires on $retirement', (tester) async {
      final pending = Completer<WorkspaceOrderDocumentsRead?>(), source = fixtures.OrderDocumentSourceFixture();
      WorkspaceOrderDocumentTarget? requested;
      source.onRead = (target) { requested = target; return pending.future; };
      final gateway = fixtures.projectionGateway(fixtures.Transport()..data = fixtures.purchaseResponse(), orderDocumentSource: source);
      Widget page({String realm = 'evaluation'}) => MaterialApp(home: Scaffold(body: WorkspaceOrderDocumentsForOrder(gateway: gateway,
        target: WorkspaceOrderDocumentTarget(accountUserId: 'buyer-1', role: WorkspaceOrderIdentityRole.buyer,
          realm: realm, reference: fixtures.operationalReference()))));
      await tester.pumpWidget(page()); await tester.tap(find.text('Order documents'));
      for (var i = 0; i < 5; i++) { await tester.pump(const Duration(milliseconds: 100)); }
      expect(requested, isNotNull);
      switch (retirement) {
        case 'collapse': await tester.tap(find.text('Order documents'));
        case 'scope': await tester.pumpWidget(page(realm: 'production'));
        case 'source': source.lifetime = Object(); source.notifyListeners();
        case 'background': tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        case 'dispose': await tester.pumpWidget(const SizedBox());
      }
      pending.complete(source.snapshot(requested!)); await tester.pumpAndSettle();
      expect(find.text('PO/2026/014'), findsNothing); expect(tester.takeException(), isNull);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    });
  }
  testWidgets('F2DOC rejects revision rollback and changed equal revision', (tester) async {
    final source = fixtures.OrderDocumentSourceFixture()..revision = 3;
    final gateway = fixtures.projectionGateway(fixtures.Transport()..data = fixtures.purchaseResponse(), orderDocumentSource: source);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: WorkspaceOrderDocumentsForOrder(gateway: gateway,
      target: WorkspaceOrderDocumentTarget(accountUserId: 'buyer-1', role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation', reference: fixtures.operationalReference())))));
    await tester.tap(find.text('Order documents')); await tester.pumpAndSettle(); expect(find.text('PO/2026/014'), findsOneWidget);
    source.revision = 2; source.notifyListeners(); await tester.pumpAndSettle();
    await tester.tap(find.text('Retry documents')); await tester.pumpAndSettle();
    expect(find.text('Documents for this order are unavailable.'), findsOneWidget);
    source.revision = 3; source.empty = true;
    await tester.tap(find.text('Retry documents')); await tester.pumpAndSettle();
    expect(find.text('No documents are linked to this order.'), findsNothing);
    source.revision = 4;
    await tester.tap(find.text('Retry documents')); await tester.pumpAndSettle();
    expect(find.text('No documents are linked to this order.'), findsOneWidget);
  });
  for (final changed in ['current', 'reader', 'store', 'realm', 'callback', 'closed', 'retired']) {
    testWidgets('LF-RESTOCK-ACTION exact Store original scope=$changed', (tester) async {
      Object? lifetime = Object();
      final refs = fixtures.purchaserReferenceResponse(), details = fixtures.purchaserPurchaseResponse();
      final wire = fixtures.Transport()..respond = (body) => body['operation'] == 'listBuyerPurchaseReferences' ? refs : details;
      final reader = fixtures.projectionGateway(wire, lifetime: () => lifetime);
      final invoked = <WorkspacePurchaseOrder>[];
      void receive(WorkspacePurchaseReference reference, WorkspacePurchaseOrder original) {
        expect(reference.originalFingerprint, original.originalFingerprint); invoked.add(original);
      }
      Widget page({AuthenticatedWorkspaceOrderIdentityGateway? gateway, String store = 'buying-store',
        String realm = 'evaluation', bool enabled = true}) => MaterialApp(home: Scaffold(body: SingleChildScrollView(
          child: WorkspacePurchaseOriginals(gateway: gateway ?? reader, role: WorkspaceOrderIdentityRole.buyer,
            realm: realm, buyingStoreId: store, onReceivePurchasedOrder: enabled ? receive : null))));
      await tester.pumpWidget(page()); await tester.pumpAndSettle();
      await tester.tap(find.text('Saved purchase details')); await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('original-order-order-v2'))); await tester.pumpAndSettle();
      final action = find.byKey(const ValueKey('purchase-receive-order-order-v2'));
      expect(action, findsOneWidget, reason: 'Receiving physical goods does not require a delivery-completion feed.');
      final retained = tester.widget<TextButton>(action).onPressed!;
      switch (changed) {
        case 'reader': await tester.pumpWidget(page(gateway: fixtures.projectionGateway(fixtures.Transport())));
        case 'store': await tester.pumpWidget(page(store: 'another-store'));
        case 'realm': await tester.pumpWidget(page(realm: 'production'));
        case 'callback': await tester.pumpWidget(page(enabled: false));
        case 'closed': await tester.pumpWidget(const SizedBox.shrink());
        case 'retired': lifetime = Object();
      }
      retained(); await tester.pumpAndSettle();
      expect(invoked.length, changed == 'current' ? 1 : 0);
      expect(tester.takeException(), isNull);
    });
  }
  for (final action in ['expand-list', 'retry-list', 'more', 'expand-order', 'retry-details', 'update']) {
    for (final changed in ['reader', 'store', 'account', 'realm', 'role', 'closed', 'retired', 'current']) {
      testWidgets('LF-ORIGINAL-ACTION retained $action scope=$changed', (tester) async {
        Object? lifetime = Object();
        var unavailable = true;
        final refs = fixtures.purchaserReferenceResponse(), details = fixtures.purchaserPurchaseResponse();
        final operational = fixtures.operationalResponse()..['original'] = details['orders'][0]['original']
          ..['originalFingerprint'] = details['orders'][0]['originalFingerprint']
          ..['originalFactsVersion'] = details['orders'][0]['factsVersion'];
        final completion = fixtures.completionResponse()..['originalFingerprint'] = details['orders'][0]['originalFingerprint'];
        if (action == 'more') refs['nextCursor'] = 'host-original-next';
        final old = fixtures.Transport()..respond = (body) {
          if (unavailable && (action == 'retry-list' && body['operation'] == 'listBuyerPurchaseReferences' ||
              action == 'retry-details' && body['operation'] == 'readBuyerPurchaseProjection')) {
            throw StateError('Isolated original read unavailable');
          }
          return switch (body['operation']) {
            'listBuyerPurchaseReferences' => refs,
            'readBuyerPurchaseProjection' => details,
            'readBuyerOperationalOrder' => operational,
            'readBuyerOrderCompletion' => completion,
            _ => throw StateError('Unexpected isolated original-history operation'),
          };
        };
        final gateway = fixtures.projectionGateway(old, lifetime: () => lifetime);
        Widget page(AuthenticatedWorkspaceOrderIdentityGateway reader, {String realm = 'evaluation',
          String? buyingStoreId = 'buying-store', WorkspaceOrderIdentityRole role = WorkspaceOrderIdentityRole.buyer}) =>
          MaterialApp(home: Scaffold(body: SingleChildScrollView(child: WorkspacePurchaseOriginals(
            gateway: reader, realm: realm, role: role, buyingStoreId: buyingStoreId,
            storeId: role == WorkspaceOrderIdentityRole.seller ? 'store-one' : null))));
        await tester.pumpWidget(page(gateway)); await tester.pumpAndSettle();
        late VoidCallback retained;
        final heading = find.byType(ExpansionTile).first;
        if (action == 'expand-list') {
          final callback = tester.widget<ExpansionTile>(heading).onExpansionChanged!;
          retained = () => callback(true);
        } else {
          await tester.tap(find.text('Saved purchase details')); await tester.pumpAndSettle();
          if (action == 'retry-list' || action == 'more') {
            retained = tester.widget<TextButton>(find.widgetWithText(TextButton,
              action == 'more' ? 'Load more purchase details' : 'Retry')).onPressed!;
          } else {
            final order = find.byKey(const ValueKey('original-order-order-v2'));
            if (action == 'expand-order') {
              final callback = tester.widget<ExpansionTile>(find.descendant(of: order,
                matching: find.byType(ExpansionTile))).onExpansionChanged!;
              retained = () => callback(true);
            } else {
              await tester.tap(order); await tester.pumpAndSettle();
              retained = tester.widget<TextButton>(find.widgetWithText(TextButton,
                action == 'retry-details' ? 'Details unavailable · retry' : 'Check order update')).onPressed!;
            }
          }
        }
        if (changed == 'current') {
          unavailable = false;
          final release = Completer<void>(), before = old.calls;
          old.beforePost = (_) => release.future;
          if (action == 'expand-list') await tester.tap(find.text('Saved purchase details'));
          if (action == 'expand-order') await tester.tap(find.byKey(const ValueKey('original-order-order-v2')));
          retained(); retained(); tester.binding.scheduleFrame(); await tester.pump();
          expect(old.calls, before + (action == 'update' ? 2 : 1), reason: 'Current actions work without duplicate in-flight reads.');
          if (action == 'more') {
            expect(old.sent!['cursor'], 'host-original-next'); refs['nextCursor'] = null;
          }
          release.complete(); await tester.pumpAndSettle();
          expect(find.byKey(const ValueKey('original-order-order-v2')), findsOneWidget);
          if (action == 'expand-order' || action == 'retry-details' || action == 'update') {
            expect(find.text(details['orders'][0]['original']['lines'][0]['name']), findsOneWidget);
          }
          if (action == 'update') expect(find.byKey(const ValueKey('purchase-order-completion-order-v2')), findsOneWidget);
          final settled = old.calls;
          if (action != 'update') {
            retained(); tester.binding.scheduleFrame(); await tester.pumpAndSettle();
            expect(old.calls, settled, reason: 'Resolved retries and exhausted continuation do not restart discovery.');
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          return;
        }
        final fresh = fixtures.Transport()..respond = old.respond;
        switch (changed) {
          case 'closed': await tester.pumpWidget(const SizedBox.shrink());
          case 'retired': lifetime = null;
          case 'reader': await tester.pumpWidget(page(fixtures.projectionGateway(fresh)));
          case 'account': await tester.pumpWidget(page(fixtures.projectionGateway(fresh, account: 'other-buyer')));
          case 'store': await tester.pumpWidget(page(gateway, buyingStoreId: 'other-buying-store'));
          case 'realm': await tester.pumpWidget(page(gateway, realm: 'production'));
          case 'role': await tester.pumpWidget(page(gateway, role: WorkspaceOrderIdentityRole.seller, buyingStoreId: null));
        }
        await tester.pumpAndSettle();
        final oldCalls = old.calls, freshCalls = fresh.calls;
        retained(); tester.binding.scheduleFrame(); await tester.pumpAndSettle();
        expect(old.calls, oldCalls, reason: 'Retired controls must not read through either owner.');
        expect(fresh.calls, freshCalls);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
  for (final scale in [1.0, 2.0]) {
    testWidgets('LF-PURCHASER Store originals use separate buyer selector and compact immutable attribution scale=$scale', (tester) async {
      tester.view.physicalSize = const Size(320, 900); tester.view.devicePixelRatio = 1; addTearDown(tester.view.reset);
      final details = fixtures.purchaserPurchaseResponse(), refs = fixtures.purchaserReferenceResponse();
      final wire = fixtures.Transport()..respond = (body) => body['operation'].toString().startsWith('list') ? refs : details;
      final gateway = fixtures.projectionGateway(wire);
      Widget page(String buyingStoreId) => MaterialApp(home: Scaffold(body: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)), child: SingleChildScrollView(
          child: WorkspacePurchaseOriginals(gateway: gateway, role: WorkspaceOrderIdentityRole.buyer,
            realm: 'evaluation', buyingStoreId: buyingStoreId)))));
      await tester.pumpWidget(page('buying-store')); await tester.pumpAndSettle();
      await tester.tap(find.text('Saved purchase details')); await tester.pumpAndSettle();
      expect(wire.sent!['buyingStoreId'], 'buying-store');
      await tester.tap(find.byKey(const ValueKey('original-order-order-v2'))); await tester.pumpAndSettle();
      expect(wire.sent!['buyingStoreId'], 'buying-store');
      final label = find.text('Buying for: Evaluation buying Store'); expect(label, findsOneWidget);
      await tester.ensureVisible(label); await tester.pumpAndSettle();
      expect(tester.widget<Text>(label).maxLines, isNull); expect(tester.takeException(), isNull);
      await tester.pumpWidget(page('other-buying-store')); await tester.pumpAndSettle();
      expect(label, findsNothing); expect(find.byKey(const ValueKey('original-order-order-v2')), findsNothing);
      await tester.tap(find.text('Saved purchase details')); await tester.pumpAndSettle();
      expect(wire.sent!['buyingStoreId'], 'other-buying-store');
      expect(find.byKey(const ValueKey('original-order-order-v2')), findsNothing, reason: 'Wrong Store echo cannot populate history.');
    });
  }
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
    (1.0, 'gst'), (2.0, 'gst'), (1.0, 'gst-unknown'), (2.0, 'gst-unknown'), (1.0, 'devices'), (2.0, 'devices'), (1.0, 'reports'), (2.0, 'reports')]) {
  testWidgets('configured Store feed supports exact facts ${scenario.$2} scale ${scenario.$1}', (tester) async {
    await tester.runAsync(() => (FontLoader('Inter')..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'))).load());
    tester.view.physicalSize = const Size(320, 900); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    final raw = scenario.$2 == 'scheduled' ? fixtures.scheduledOperationalResponse(role: 'seller')
      : scenario.$2 == 'variant' ? fixtures.variantOperationalResponse(role: 'seller')
      : scenario.$2 == 'attribution' ? fixtures.attributedOperationalResponse(role: 'seller')
      : fixtures.operationalResponse(role: 'seller');
    final devices = scenario.$2 == 'devices' ? fixtures.DevicePublisherFixture() : null;
    final inbox = scenario.$2 == 'reports' ? fixtures.DeviceInboxFixture() : null;
    final source = inbox ?? devices;
    final caseGateway = inbox == null ? null : (fixtures.DeviceCaseGatewayFixture()
      ..onSubmit = (_) => Future.error(TimeoutException('HOST case response lost')));
    final deviceOriginal = source == null ? null : fixtures.purchaseResponse(role: 'seller');
    if (source != null) {
      FlutterSecureStorage.setMockInitialValues({});
      addTearDown(source.dispose);
    }
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
      if (source != null && body['operation'] == 'readStorePurchaseProjection') return deviceOriginal!;
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
    final work = WorkSession(contactDraftStore: _OrderAccount(), operationalPendingStoreFactory: (_, _) => journal, issueCommandGateway: caseGateway)
      ..seedVerifiedWorkspace()
      ..activeWorkspace = const WorkWorkspace(id: 'store-one', name: 'Store', profileLabel: 'Grocery / Kirana Shop',
        profileId: 'retailer-grocery', area: 'Jodhpur', verified: true)
      ..workspaceId = 'store-one'
      ..retailerSetupSaved = true
      ..reviewStage = WorkReviewStage.live;
    work.bindOriginalPurchaseReader(fixtures.projectionGateway(wire, account: 'owner-1', purchasedUnitSource: source), 'evaluation');
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
    if (inbox != null) {
      Future<void> tapText(String label) async {
        final finder = find.text(label).last; await tester.ensureVisible(finder); await tester.pumpAndSettle();
        expect(finder.hitTestable(), findsOneWidget); await tester.tap(finder); await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.byKey(const Key('work-operational-accept-order-v2')));
      await tester.tap(find.byKey(const Key('work-operational-accept-order-v2'))); await tester.pumpAndSettle();
      await tapText('Device details'); await tapText('Buyer device reports'); await tapText('Review linked case');
      final modal = find.byKey(const Key('work-device-report-case'));
      expect(modal, findsOneWidget); expect(find.descendant(of: modal, matching: find.text('Device details reported')), findsOneWidget);
      expect(find.descendant(of: modal, matching: find.textContaining('ordered affected')), findsNothing);
      Future<void> captureCase(String suffix) async {
        const root = String.fromEnvironment('LF_DEVICE_INBOX_CAPTURE_ROOT'); if (root.isEmpty) { return; }
        final boundary = capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final directory = Directory(root); await directory.create(recursive: true);
          final file = File('$root/host-device-case-${scenario.$1}-$suffix.png'); expect(await file.exists(), isFalse);
          final image = await boundary.toImage(); final bytes = await image.toByteData(format: ui.ImageByteFormat.png); image.dispose();
          await file.writeAsBytes(bytes!.buffer.asUint8List());
        });
      }
      await captureCase('top');
      final liveIssue = inbox.caseFor(inbox.requests.last);
      expect(work.workspaceIssueStale(liveIssue), isFalse); expect(work.workspaceIssueDraftLoaded(liveIssue), isTrue);
      expect(work.workspaceIssueResponseLoaded(liveIssue), isTrue);
      final dropdown = find.descendant(of: modal, matching: find.byType(DropdownButtonFormField<WorkspaceIssueResponse>));
      await tester.ensureVisible(dropdown); await tester.pumpAndSettle();
      expect(tester.widget<DropdownButtonFormField<WorkspaceIssueResponse>>(dropdown).onChanged, isNotNull);
      expect(dropdown.hitTestable(), findsOneWidget); await tester.tap(dropdown); await tester.pumpAndSettle(); await tapText('Send details');
      final field = find.byKey(const Key('work-issue-response-note-HOST-DEVICE-CASE'));
      await tester.ensureVisible(field); await tester.enterText(field, 'HOST packing checked');
      FocusManager.instance.primaryFocus?.unfocus(); await tester.pumpAndSettle();
      await captureCase('response');
      await tapText('Done'); await tapText('Review linked case');
      expect(tester.widget<TextField>(field).controller!.text, 'HOST packing checked');
      await tapText('Send response'); expect(caseGateway!.submitted, hasLength(1));
      final command = caseGateway.submitted.single;
      expect(command.sourceCaseId, 'HOST-DEVICE-CASE'); expect(command.purchaseContext!.realm, 'evaluation'); expect(command.lines, isEmpty);
      expect(find.text('Response status is uncertain. Check status before trying again.'), findsOneWidget);
      await tapText('Done'); await tapText('Review linked case'); await tapText('Check status');
      expect(caseGateway.checked.single.operationId, command.operationId); expect(caseGateway.checked.single.digest, command.digest);
      expect(caseGateway.submitted, hasLength(1)); expect(find.text('Response sent. Waiting for the case update.'), findsOneWidget);
      if (scenario.$1 == 1) { inbox.revokeOwner(); }
      else {
        final originalStore = work.activeWorkspace;
        work.activeWorkspace = null; work.activeWorkspace = originalStore;
        inbox.reportsChanged();
      }
      await tester.pumpAndSettle();
      expect(find.text('Current Store owner access is unavailable. Reopen the report after access is restored.'), findsOneWidget);
      expect(find.byKey(const Key('work-issue-response-note-HOST-DEVICE-CASE')), findsNothing);
      await tapText('Done'); expect(work.workspaceInvoices, isEmpty); expect(work.workspaceStockMovements, isEmpty);
      expect(work.workspaceOrders.single.quantities, isEmpty); expect(journal.entries, isEmpty); expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink()); return;
    } else if (devices != null) {
      Future<void> tapText(String label) async {
        await tester.ensureVisible(find.text(label)); await tester.pumpAndSettle();
        await tester.tap(find.text(label)); await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.byKey(const Key('work-operational-accept-order-v2')));
      await tester.tap(find.byKey(const Key('work-operational-accept-order-v2'))); await tester.pumpAndSettle();
      expect(work.workspaceOrders.single.stage, 'Preparing');
      await tapText('Device details'); await tapText('Prepare device details'); await tapText('Add device');
      expect(find.byType(TextFormField), findsNWidgets(3));
      await tester.enterText(find.byType(TextFormField).first, 'HOST-PACKED-DEVICE');
      FocusManager.instance.primaryFocus?.unfocus(); await tester.pumpAndSettle();
      await tapText('Review and share device details');
      expect(find.text('Serial: HOST-PACKED-DEVICE'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      await tapText('Back to editing'); expect(devices.shares, isEmpty);
      expect(devices.requests, hasLength(1)); expect(devices.requests.single.role, WorkspaceOrderIdentityRole.seller);
      expect(devices.requests.single.reference.storeId, 'store-one');
      expect(find.text('Saved on this device · not shared'), findsOneWidget);
      expect(devices.rows, isEmpty); expect(work.workspacePackingComplete, isFalse);
      final native = await const FlutterSecureStorage().readAll();
      expect(native.keys.single, contains('purchased-unit-draft.v1'));
      final oldAdd = tester.widget<TextButton>(find.widgetWithText(TextButton, 'Add device')).onPressed!;
      final oldField = tester.widget<TextFormField>(find.byType(TextFormField).first).onChanged!;
      work.bindOriginalPurchaseReader(null, 'evaluation');
      oldAdd(); oldField('HOST-RETIRED-PACKING'); await tester.pumpAndSettle();
      expect(await const FlutterSecureStorage().readAll(), native); expect(devices.requests, hasLength(1));
      expect(find.byType(TextFormField), findsNothing); expect(devices.rows, isEmpty);
      expect(work.workspaceInvoices, isEmpty); expect(work.workspaceStockMovements, isEmpty);
      expect(journal.entries, isEmpty); expect(tester.takeException(), isNull);
      return;
    } else if (scenario.$2 == 'delivery') {
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

// Isolated native HOST fixtures; no runtime sources, grants or device data.
class _Order02NativeHarness{
  _Order02NativeHarness({this.buyer=false});
  final bool buyer;
  final navigator=GlobalKey<NavigatorState>(),changes=ValueNotifier<int>(0);
  final draftStore=fixtures.DeviceDraftFixture();
  late fixtures.Transport wire;
  late fixtures.OrderDocumentSourceFixture documents;
  late fixtures.WarrantyReaderFixture warranty;
  late fixtures.DeviceSourceFixture units;
  late AuthenticatedWorkspaceOrderIdentityGateway gateway;
  late WorkspacePurchaseReference reference;
  late WorkspacePurchaseOrder original;
  late MoolAssistantContext context;
  late Route<void> assistant;
  bool active=true,proposal=true;int openedCases=0,sequence=0;
  String get lineEntity=>jsonEncode([reference.orderId,original.lines.single.lineId]);
  Future<void> ready(WidgetTester tester,{String source='publisher',double scale=1})async{
    final data=buyer?fixtures.purchaserPurchaseResponse():fixtures.purchaseResponse(role:'seller');
    wire=fixtures.Transport()..data=data;
    final account=buyer?'buyer-1':'owner-1';documents=fixtures.OrderDocumentSourceFixture(accountUserId:account);
    documents.onRead=(target)async=>WorkspaceOrderDocumentsRead(targetBinding:target.binding,revision:2,
      documents:[documents.document(),fixtures.orderChangeFixture()]);
    warranty=fixtures.WarrantyReaderFixture(accountUserId:account)..respond=(target)async=>fixtures.warrantyRead(target);
    units=buyer?fixtures.DeviceReporterFixture():source=='inbox'?fixtures.DeviceInboxFixture():fixtures.DevicePublisherFixture();
    if(!buyer){units.revision=1;units.rows=const [WorkspacePurchasedUnitRow(id:'HOST-existing-device',serial:'HOST supplier serial')];}
    gateway=fixtures.projectionGateway(wire,account:account,purchasedUnitSource:units,purchasedWarrantyReader:warranty,orderDocumentSource:documents);
    final raw=Map<String,Object?>.of(fixtures.referenceResponse(role:buyer?'buyer':'seller')['references'][0]);
    raw['originalFingerprint']=data['orders'][0]['originalFingerprint'];reference=WorkspacePurchaseReference.fromJson(raw);
    original=(await gateway.readReferencedOrder(role:buyer?WorkspaceOrderIdentityRole.buyer:WorkspaceOrderIdentityRole.seller,realm:'evaluation',
      reference:reference,buyingStoreId:buyer?'buying-store':null))!;
    context=MoolAssistantContext(accountScope:account,authenticationRevision:1,workspaceId:buyer?'buying-store':'store-one',
      workspaceName:'HOST original Store',workspaceProfile:'retailer-grocery',workspaceRevision:1,storeWorkspace:true,workspaceApproved:true);
    await tester.pumpWidget(MaterialApp(navigatorKey:navigator,theme:MoolTheme.light(),
      builder:(context,child)=>MediaQuery(data:MediaQuery.of(context).copyWith(textScaler:TextScaler.linear(scale)),child:child!),
      home:const Scaffold(body:Text('HOST native Store original owner'))));
    await tester.pumpAndSettle();
    assistant=MaterialPageRoute<void>(builder:(_)=>const Scaffold(body:Text('HOST assistant cover')));
    unawaited(navigator.currentState!.push<void>(assistant));await tester.pumpAndSettle();
  }
  WorkspaceOriginalAssistantTarget? resolve(String entity){
    if(!active||entity!=reference.orderId&&entity!=lineEntity)return null;
    return WorkspaceOriginalAssistantTarget(gateway:gateway,role:buyer?WorkspaceOrderIdentityRole.buyer:WorkspaceOrderIdentityRole.seller,
      realm:'evaluation',reference:reference,lineId:entity==lineEntity?original.lines.single.lineId:null,buyingStoreId:buyer?'buying-store':null,
      draftStore:draftStore,onOpenCase:(handoff)async{if(!handoff.current)return false;openedCases++;return true;});
  }
  WorkspaceOrderOriginalNativeAdapter adapter(String action){
    final a=WorkspaceOrderOriginalNativeAdapter(actionId:action,navigator:navigator.currentState!,currentContext:()=>context,
      currentOwner:()=>active,ownerChanges:changes,resolve:resolve);
    a.bindAssistantRoute(assistant,navigator.currentState!);return a;
  }
  Future<({WorkspaceOrderOriginalNativeAdapter adapter,Future<MoolAssistantReviewResult> result})> open(
      WidgetTester tester,String action,{Map<String,Object?> fields=const {},bool line=true,Duration lifetime=const Duration(minutes:4)})async{
    final a=adapter(action),entity=line?lineEntity:reference.orderId;
    final snapshot=await a.snapshot(context,entity);expect(snapshot,isNotNull,reason:action);
    final p=MoolAssistantProposal(id:'HOST-ORDER02-${++sequence}',actionId:action,binding:context.binding,
      requestRevision:1,entitlementRevision:'HOST isolated paid',sourceRevision:snapshot!.sourceRevision,entityId:entity,
      validUntil:DateTime.now().add(lifetime),title:'Original purchase details',summary:'HOST native original only',fields:fields);
    final future=a.openOwnedReview(p,isCurrent:()=>proposal,ownerChanges:changes);await tester.pumpAndSettle();return(adapter:a,result:future);
  }
  Future<void> back(WidgetTester tester)async{
    await tester.tap(find.byType(BackButton).first);await tester.pumpAndSettle();
  }
  void retire(){proposal=false;changes.value++;}
  Future<void> close(WidgetTester tester)async{
    await tester.pumpWidget(const SizedBox.shrink());await tester.pumpAndSettle();units.dispose();documents.dispose();changes.dispose();
  }
}

void registerOrder02NativeTests(){
  for(final hasSavedDraft in [false,true]){
    testWidgets('ORDER02 394 partial identifier edit preserves all omitted rows and fields savedDraft=$hasSavedDraft',(tester)async{
      final h=_Order02NativeHarness();try{await h.ready(tester);
        h.units.rows=const [
          WorkspacePurchasedUnitRow(id:'HOST-existing-device',serial:'HOST original A',imei1:'111111',imei2:'222222'),
          WorkspacePurchasedUnitRow(id:'HOST-second-device',serial:'HOST original B',imei1:'333333',imei2:'444444')];
        if(hasSavedDraft){
          final target=h.resolve(h.lineEntity)!,read=(await h.gateway.readPurchasedUnits(role:target.role,realm:target.realm,
            reference:h.reference,line:h.original.lines.single))!;
          final key=WorkspacePurchasedUnitDraftKey(account:h.gateway.accountUserId,realm:target.realm,store:h.reference.storeId,binding:read.target.binding);
          h.draftStore.saved=WorkspacePurchasedUnitDraft(key:key,revision:1,publishedRevision:read.revision,rows:const [
            WorkspacePurchasedUnitRow(id:'HOST-existing-device',serial:'HOST saved A',imei1:'555555',imei2:'666666'),
            WorkspacePurchasedUnitRow(id:'HOST-second-device',serial:'HOST saved B',imei1:'777777',imei2:'888888'),
            WorkspacePurchasedUnitRow(id:'HOST-saved-only-device',serial:'HOST unmentioned private C',imei1:'999999',imei2:'101010')]);
        }
        final opened=await h.open(tester,'AI-ACT-394',fields:{'rows':[
          {'id':'HOST-existing-device','serial':'મૂળ corrected A'},
          if(hasSavedDraft){'id':'HOST-second-device','imei2':''}]});
        expect(h.draftStore.writes,isEmpty);
        final save=find.widgetWithText(TextButton,'Save kept edits');await tester.ensureVisible(save);await tester.tap(save);await tester.pumpAndSettle();
        expect(h.draftStore.writes,hasLength(1));final rows=h.draftStore.saved!.rows;
        expect(rows.map((row)=>row.id).toList(),hasSavedDraft?['HOST-existing-device','HOST-second-device','HOST-saved-only-device']:['HOST-existing-device','HOST-second-device']);
        expect(rows.first.serial,'મૂળ corrected A');expect(rows.first.imei1,hasSavedDraft?'555555':'111111');expect(rows.first.imei2,hasSavedDraft?'666666':'222222');
        expect(rows[1].serial,hasSavedDraft?'HOST saved B':'HOST original B');expect(rows[1].imei1,hasSavedDraft?'777777':'333333');
        expect(rows[1].imei2,hasSavedDraft?'':'444444',reason:'Only an explicitly supplied empty field clears its native value.');
        if(hasSavedDraft)expect(rows.last.toJson(),const WorkspacePurchasedUnitRow(id:'HOST-saved-only-device',serial:'HOST unmentioned private C',imei1:'999999',imei2:'101010').toJson());
        expect((h.units as fixtures.DevicePublisherFixture).shares,isEmpty);await h.back(tester);await opened.result;
      }finally{await h.close(tester);}
    });
  }
  testWidgets('ORDER02 394 appending one new native row preserves the complete original device list',(tester)async{
    final h=_Order02NativeHarness();try{await h.ready(tester);final original=h.units.rows.single;
      final opened=await h.open(tester,'AI-ACT-394',fields:{'rows':[{'serial':'HOST genuinely additional printed device'}]});
      expect(h.draftStore.writes,isEmpty);final save=find.widgetWithText(TextButton,'Save kept edits');await tester.ensureVisible(save);await tester.tap(save);await tester.pumpAndSettle();
      final rows=h.draftStore.saved!.rows;expect(rows,hasLength(2));expect(rows.first.toJson(),original.toJson());
      expect(rows.last.serial,'HOST genuinely additional printed device');expect(rows.last.id,isNot(original.id));
      expect(h.draftStore.writes,hasLength(1));expect((h.units as fixtures.DevicePublisherFixture).shares,isEmpty);
      await h.back(tester);await opened.result;
    }finally{await h.close(tester);}
  });
  testWidgets('ORDER02 proposal expiry closes only its original native private review and rejects retained Save',(tester)async{
    final h=_Order02NativeHarness();try{await h.ready(tester);
      final opened=await h.open(tester,'AI-ACT-394',lifetime:const Duration(seconds:1),fields:{'rows':[{'serial':'HOST expiry private serial'}]});
      final save=find.widgetWithText(TextButton,'Save kept edits');await tester.ensureVisible(save);
      final retained=tester.widget<TextButton>(save).onPressed!;
      await tester.runAsync(()=>Future<void>.delayed(const Duration(milliseconds:1100)));
      await tester.pump(const Duration(seconds:2));await tester.pumpAndSettle();retained();await tester.pump();
      expect(await opened.result,MoolAssistantReviewResult.stale);expect(h.draftStore.writes,isEmpty);
      expect(find.textContaining('HOST expiry private serial'),findsNothing);expect(tester.takeException(),isNull);
    }finally{await h.close(tester);}
  });
  testWidgets('ORDER02 retained original Save cannot write after actor retirement or pop an unrelated route',(tester)async{
    final h=_Order02NativeHarness();try{await h.ready(tester);
      final opened=await h.open(tester,'AI-ACT-394',fields:{'rows':[{'id':'HOST-existing-device','serial':'HOST exact private serial'}]});
      final save=find.widgetWithText(TextButton,'Save kept edits');await tester.ensureVisible(save);
      final retained=tester.widget<TextButton>(save).onPressed!;
      unawaited(h.navigator.currentState!.push<void>(MaterialPageRoute(builder:(_)=>const Scaffold(body:Text('HOST unrelated retained Save owner')))));
      await tester.pumpAndSettle();retained();await tester.pumpAndSettle();expect(h.draftStore.writes,isEmpty);
      h.active=false;h.changes.value++;await tester.pumpAndSettle();retained();await tester.pumpAndSettle();
      expect(h.draftStore.writes,isEmpty);expect(find.text('HOST unrelated retained Save owner'),findsOneWidget);
      expect(await opened.result,MoolAssistantReviewResult.stale);expect(tester.takeException(),isNull);
    }finally{await h.close(tester);}
  });
  testWidgets('ORDER02 held authenticated device read retires before native private editor can open',(tester)async{
    final h=_Order02NativeHarness();final entered=Completer<void>(),release=Completer<void>();
    try{await h.ready(tester);
      (h.units as fixtures.DevicePublisherFixture).beforeRead=(){if(!entered.isCompleted)entered.complete();return release.future;};
      final adapter=h.adapter('AI-ACT-394'),read=adapter.snapshot(h.context,h.lineEntity);
      await entered.future;h.active=false;h.changes.value++;release.complete();
      expect(await read,isNull);expect(h.draftStore.writes,isEmpty);
      expect(find.widgetWithText(TextButton,'Save kept edits'),findsNothing);
    }finally{if(!release.isCompleted)release.complete();await h.close(tester);}
  });
  testWidgets('ORDER02 original device Save already dispatched keeps its truthful private save after proposal retirement',(tester)async{
    final h=_Order02NativeHarness();final release=Completer<void>();try{await h.ready(tester);
      final opened=await h.open(tester,'AI-ACT-394',fields:{'rows':[{'id':'HOST-existing-device','serial':'HOST retained native private copy'}]});
      h.draftStore.holdNextSave=release;
      final save=find.widgetWithText(TextButton,'Save kept edits');await tester.ensureVisible(save);await tester.tap(save);await tester.pump();
      expect(h.draftStore.holdNextSave,isNull,reason:'The original save has entered its own retained operation.');
      h.retire();await tester.pumpAndSettle();release.complete();await tester.pumpAndSettle();
      expect(await opened.result,MoolAssistantReviewResult.stale);
      expect(h.draftStore.writes,hasLength(1));expect(h.draftStore.saved!.rows.single.serial,'HOST retained native private copy');
      expect((h.units as fixtures.DevicePublisherFixture).shares,isEmpty);expect(tester.takeException(),isNull);
    }finally{if(!release.isCompleted)release.complete();await h.close(tester);}
  });
  testWidgets('ORDER02 original Share unknown reply retains exact durable command and never claims shared',(tester)async{
    final h=_Order02NativeHarness();try{await h.ready(tester);
      final target=h.resolve(h.lineEntity)!,read=(await h.gateway.readPurchasedUnits(role:target.role,realm:target.realm,
        reference:h.reference,line:h.original.lines.single))!;
      final key=WorkspacePurchasedUnitDraftKey(account:h.gateway.accountUserId,realm:target.realm,store:h.reference.storeId,binding:read.target.binding);
      h.draftStore.saved=WorkspacePurchasedUnitDraft(key:key,revision:1,publishedRevision:read.revision,rows:read.rows);
      final source=h.units as fixtures.DevicePublisherFixture;
      source.onShare=(target,command)async{await source.apply(target,command);return null;};
      final opened=await h.open(tester,'AI-ACT-395');
      final review=find.widgetWithText(TextButton,'Review and share device details');await tester.ensureVisible(review);await tester.tap(review);await tester.pumpAndSettle();
      final share=find.widgetWithText(FilledButton,'Share device details');await tester.ensureVisible(share);await tester.tap(share);await tester.pumpAndSettle();
      expect(source.shares,hasLength(1));expect(h.draftStore.saved!.pending,isNotNull);
      expect(h.draftStore.saved!.pending!.toJson(),source.shares.single.toJson());
      expect(find.text('Device details shared with the buyer.'),findsNothing);expect(source.checks,isEmpty);
      await h.back(tester);await opened.result;
    }finally{await h.close(tester);}
  });
  testWidgets('ORDER02 274 original order and389 linked documents reuse exact native frozen reader without effect',(tester)async{
    final h=_Order02NativeHarness();try{await h.ready(tester);
      var opened=await h.open(tester,'AI-ACT-274',line:false);
      expect(find.text('Saved purchase details'),findsOneWidget);expect(find.text('दाल'),findsWidgets);
      expect(h.draftStore.writes,isEmpty);await h.back(tester);expect(await opened.result,MoolAssistantReviewResult.opened);
      opened=await h.open(tester,'AI-ACT-389',line:false);expect(find.text('Order documents'),findsOneWidget);
      expect(find.text('PO/2026/014'),findsOneWidget);expect(h.draftStore.writes,isEmpty);await h.back(tester);await opened.result;
    }finally{await h.close(tester);}
  });
  for(final action in ['AI-ACT-390','AI-ACT-391']){
    testWidgets('ORDER02 $action exact current and previous revision keep native document identity',(tester)async{
      final h=_Order02NativeHarness();try{await h.ready(tester);final before=h.documents.copies;
        final result=await h.open(tester,action,line:false,fields:{'documentId':action=='AI-ACT-390'?'doc-order':'doc-change','documentRevision':1});
        if(action=='AI-ACT-390'){
          expect(find.text('order.png'),findsOneWidget);expect(h.documents.copies,before+1);
        }else{expect(find.text('Previous document: PO/2026/014 · Revision 1'),findsOneWidget);expect(h.documents.copies,before);}
        expect(h.draftStore.writes,isEmpty);await h.back(tester);await result.result;expect(tester.takeException(),isNull);
      }finally{await h.close(tester);}
    });
  }
  for(final action in ['AI-ACT-392','AI-ACT-393']){
    testWidgets('ORDER02 $action native purchased terms and identifiers are recorded original facts only',(tester)async{
      final h=_Order02NativeHarness();try{await h.ready(tester);final opened=await h.open(tester,action);
        expect(find.text(action=='AI-ACT-392'?'Warranty details':'Device details'),findsOneWidget);
        if(action=='AI-ACT-392')expect(find.textContaining('HOST original issuer'),findsWidgets);
        else expect(find.textContaining('HOST supplier serial'),findsWidgets);
        expect(h.draftStore.writes,isEmpty);await h.back(tester);await opened.result;expect(tester.takeException(),isNull);
      }finally{await h.close(tester);}
    });
  }
  testWidgets('ORDER02 394 supplied Unicode serial reaches original kept-edits review and native Save only persists once',(tester)async{
    final h=_Order02NativeHarness();try{await h.ready(tester);
      final opened=await h.open(tester,'AI-ACT-394',fields:{'rows':[{'id':'HOST-existing-device','serial':'મૂળ SERIAL-01','imei1':'123456789012345'}]});
      expect(find.textContaining('મૂળ SERIAL-01'),findsWidgets);expect(h.draftStore.writes,isEmpty);
      final save=find.widgetWithText(TextButton,'Save kept edits');await tester.ensureVisible(save);await tester.tap(save);await tester.pumpAndSettle();
      expect(h.draftStore.writes,hasLength(1));expect(h.draftStore.saved!.rows.single.serial,'મૂળ SERIAL-01');
      expect((h.units as fixtures.DevicePublisherFixture).shares,isEmpty);await h.back(tester);await opened.result;
    }finally{await h.close(tester);}
  });
  testWidgets('ORDER02 394 private saved revision conflict keeps actual original recovery without overwriting',(tester)async{
    final h=_Order02NativeHarness();try{await h.ready(tester);
      final opened=await h.open(tester,'AI-ACT-394',fields:{'rows':[{'id':'HOST-existing-device','serial':'HOST proposed'}]});
      final target=h.resolve(h.lineEntity)!,lineTarget=WorkspacePurchasedLineTarget(accountUserId:h.gateway.accountUserId,role:target.role,realm:target.realm,
        reference:target.reference,line:h.original.lines.single);
      h.draftStore.saved=WorkspacePurchasedUnitDraft(key:WorkspacePurchasedUnitDraftKey(account:h.gateway.accountUserId,realm:'evaluation',store:h.reference.storeId,binding:lineTarget.binding),
        revision:1,publishedRevision:1,rows:const [WorkspacePurchasedUnitRow(id:'HOST-existing-device',serial:'HOST newer saved')]);
      final save=find.widgetWithText(TextButton,'Save kept edits');await tester.ensureVisible(save);await tester.tap(save);await tester.pumpAndSettle();
      expect(h.draftStore.writes,isEmpty);expect(h.draftStore.saved!.rows.single.serial,'HOST newer saved');
      expect(find.textContaining('Draft save needs recovery'),findsOneWidget);await h.back(tester);await opened.result;
    }finally{await h.close(tester);}
  });
  testWidgets('ORDER02 396 actual procurement buyer fields stay private until original Save and original Send',(tester)async{
    final h=_Order02NativeHarness(buyer:true);try{await h.ready(tester);
      final opened=await h.open(tester,'AI-ACT-396',fields:{'selectedIds':['supplier-device-A'],'note':'મૂળ device does not match'});
      expect(find.textContaining('મૂળ device does not match'),findsWidgets);expect(h.draftStore.writes,isEmpty);
      expect((h.units as fixtures.DeviceReporterFixture).reports,isEmpty);
      final save=find.widgetWithText(TextButton,'Save kept edits');await tester.ensureVisible(save);await tester.tap(save);await tester.pumpAndSettle();
      expect(h.draftStore.writes,hasLength(1));expect(h.draftStore.saved!.report!.note,'મૂળ device does not match');
      expect((h.units as fixtures.DeviceReporterFixture).reports,isEmpty);await h.back(tester);await opened.result;
    }finally{await h.close(tester);}
  });
  for(final action in ['AI-ACT-397','AI-ACT-400']){
    testWidgets('ORDER02 $action received device report uses seller grant and exact existing case',(tester)async{
      final h=_Order02NativeHarness();try{await h.ready(tester,source:'inbox');final opened=await h.open(tester,action,fields:action=='AI-ACT-400'?{'reportId':'HOST-REPORT-1'}:{});
        expect(find.text('Report HOST-REPORT-1'),findsOneWidget);expect(h.openedCases,action=='AI-ACT-400'?1:0);expect(h.draftStore.writes,isEmpty);
        await h.back(tester);await opened.result;expect(tester.takeException(),isNull);
      }finally{await h.close(tester);}
    });
  }
  for(final action in ['AI-ACT-395','AI-ACT-398','AI-ACT-399']){
    testWidgets('ORDER02 $action absent exact private draft or pending command is unavailable without invented outcome',(tester)async{
      final h=_Order02NativeHarness(buyer:action=='AI-ACT-399');try{await h.ready(tester);final adapter=h.adapter(action);
        expect(await adapter.snapshot(h.context,h.lineEntity),isNull);expect(h.draftStore.writes,isEmpty);
        if(h.units is fixtures.DevicePublisherFixture){expect((h.units as fixtures.DevicePublisherFixture).shares,isEmpty);expect((h.units as fixtures.DevicePublisherFixture).checks,isEmpty);}
        if(h.units is fixtures.DeviceReporterFixture){expect((h.units as fixtures.DeviceReporterFixture).reports,isEmpty);expect((h.units as fixtures.DeviceReporterFixture).checks,isEmpty);}
      }finally{await h.close(tester);}
    });
  }
  for(final action in ['AI-ACT-395','AI-ACT-398','AI-ACT-399']){
    testWidgets('ORDER02 $action original private command has zero Review dispatch and one explicit native action',(tester)async{
      final h=_Order02NativeHarness(buyer:action=='AI-ACT-399');try{await h.ready(tester);
        final target=h.resolve(h.lineEntity)!,role=target.role;
        final read=(await h.gateway.readPurchasedUnits(role:role,realm:'evaluation',reference:h.reference,line:h.original.lines.single,
          buyingStoreId:target.buyingStoreId))!;
        final key=WorkspacePurchasedUnitDraftKey(account:h.gateway.accountUserId,realm:'evaluation',store:h.reference.storeId,binding:read.target.binding);
        WorkspacePurchasedUnitPublishCommand? pending;WorkspacePurchasedUnitMismatchDraft? report;
        if(action=='AI-ACT-398')pending=WorkspacePurchasedUnitPublishCommand(key:key,operationId:'a'*32,expectedRevision:read.revision,rows:read.rows);
        if(action=='AI-ACT-399'){
          final command=WorkspacePurchasedUnitMismatchCommand(key:key,operationId:'b'*32,sourceRevision:read.revision,
            sourceFingerprint:read.fingerprint,note:'HOST original pending mismatch',rows:read.rows);
          report=WorkspacePurchasedUnitMismatchDraft(sourceFingerprint:read.fingerprint,note:command.note,
            selected:read.rows.map((r)=>r.id).toList(),pending:command);
        }
        final saved=WorkspacePurchasedUnitDraft(key:key,revision:1,publishedRevision:read.revision,rows:read.rows,pending:pending,report:report);
        expect(saved.valid,isTrue);h.draftStore.saved=saved;
        final opened=await h.open(tester,action);expect(h.draftStore.writes,isEmpty);
        if(action=='AI-ACT-395'){
          final source=h.units as fixtures.DevicePublisherFixture;expect(source.shares,isEmpty);
          final review=find.widgetWithText(TextButton,'Review and share device details');await tester.ensureVisible(review);await tester.tap(review);await tester.pumpAndSettle();
          expect(source.shares,isEmpty);final share=find.widgetWithText(FilledButton,'Share device details');await tester.ensureVisible(share);
          final callback=tester.widget<FilledButton>(share).onPressed!;callback();callback();await tester.pumpAndSettle();expect(source.shares,hasLength(1));
        }else if(action=='AI-ACT-398'){
          final source=h.units as fixtures.DevicePublisherFixture;expect(source.checks,isEmpty);
          final check=find.widgetWithText(TextButton,'Check sharing status');await tester.ensureVisible(check);await tester.tap(check);await tester.pumpAndSettle();
          expect(source.checks,hasLength(1));expect(source.shares,isEmpty);
        }else{
          final source=h.units as fixtures.DeviceReporterFixture;expect(source.checks,isEmpty);expect(source.reports,isEmpty);
          final check=find.widgetWithText(TextButton,'Check report status');await tester.ensureVisible(check);await tester.tap(check);await tester.pumpAndSettle();
          expect(source.checks,hasLength(1));expect(source.reports,isEmpty);
        }
        await h.back(tester);await opened.result;expect(tester.takeException(),isNull);
      }finally{await h.close(tester);}
    });
  }
  for(final scale in [1.0,2.0]){
    testWidgets('ORDER02 original warranty layout stays compact at320px text$scale',(tester)async{
      final h=_Order02NativeHarness();try{
        tester.view.physicalSize=const Size(320,568);tester.view.devicePixelRatio=1;
        addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
        await h.ready(tester,scale:scale);
        final opened=await h.open(tester,'AI-ACT-392');
        expect(find.textContaining('HOST original issuer'),findsWidgets);expect(h.draftStore.writes,isEmpty);expect(tester.takeException(),isNull);
        await h.back(tester);await opened.result;
      }finally{await h.close(tester);}
    });
  }
  for(final kind in ['proposal','owner','source','foreign-route']){
    testWidgets('ORDER02 captured original privacy and exact Close survive $kind retirement',(tester)async{
      final h=_Order02NativeHarness();try{await h.ready(tester);final opened=await h.open(tester,'AI-ACT-394',fields:{'rows':[{'serial':'HOST private review'}]});
        final close=tester.widget<BackButton>(find.byType(BackButton).first).onPressed!;
        if(kind=='foreign-route')unawaited(h.navigator.currentState!.push<void>(MaterialPageRoute(builder:(_)=>const Scaffold(body:Text('HOST unrelated case route')))));
        await tester.pumpAndSettle();
        if(kind=='owner'){h.active=false;h.changes.value++;}else if(kind=='source'){h.units.rotateLifetime();}else{h.retire();}
        await tester.pumpAndSettle();close();await tester.pumpAndSettle();
        if(kind=='foreign-route')expect(find.text('HOST unrelated case route'),findsOneWidget);
        expect(find.textContaining('HOST private review'),findsNothing);expect(h.draftStore.writes,isEmpty);expect(await opened.result,MoolAssistantReviewResult.stale);
        expect(tester.takeException(),isNull);
      }finally{await h.close(tester);}
    });
  }
  testWidgets('ORDER02 buyer-only report actions never borrow the supplier Store grant',(tester)async{
    final h=_Order02NativeHarness();try{await h.ready(tester);for(final action in ['AI-ACT-396','AI-ACT-399']){
      expect(await h.adapter(action).snapshot(h.context,h.lineEntity),isNull);}
      expect(h.draftStore.reads,0);expect(h.draftStore.writes,isEmpty);
    }finally{await h.close(tester);}
  });
  testWidgets('ORDER02 exact document revision and closed field schemas reject model authority',(tester)async{
    final h=_Order02NativeHarness();try{await h.ready(tester);
      expect(h.adapter('AI-ACT-394').validateFields({'rows':[{'serial':123}]}),isNotNull);
      expect(h.adapter('AI-ACT-394').validateFields({'rows':[{'serial':'HOST','ownerGranted':true}]}),isNotNull);
      expect(h.adapter('AI-ACT-390').validateFields({'documentId':'doc-order','documentRevision':'1'}),isNotNull);
      expect(h.adapter('AI-ACT-396').validateFields({'selectedIds':['a','a'],'note':'HOST'}),isNotNull);
      expect(h.adapter('AI-ACT-400').validateFields({'reportId':'HOST-REPORT-1','newCase':true}),isNotNull);
      final adapter=h.adapter('AI-ACT-390'),snapshot=await adapter.snapshot(h.context,h.reference.orderId);expect(snapshot,isNotNull);
      final p=MoolAssistantProposal(id:'HOST wrong revision',actionId:'AI-ACT-390',binding:h.context.binding,requestRevision:1,
        entitlementRevision:'HOST',sourceRevision:snapshot!.sourceRevision,entityId:h.reference.orderId,
        validUntil:DateTime.now().add(const Duration(minutes:1)),title:'Original copy',summary:'HOST exact revision',fields:{'documentId':'doc-order','documentRevision':999});
      expect(await adapter.openOwnedReview(p,isCurrent:()=>true,ownerChanges:h.changes),MoolAssistantReviewResult.unavailable);
      expect(h.documents.copies,0);expect(h.draftStore.writes,isEmpty);
    }finally{await h.close(tester);}
  });
  testWidgets('ORDER02 held authenticated document read cannot admit another Store owner',(tester)async{
    final h=_Order02NativeHarness();try{await h.ready(tester);final gate=Completer<WorkspaceOrderDocumentsRead?>(),entered=Completer<void>();
      h.documents.onRead=(target){entered.complete();return gate.future;};final adapter=h.adapter('AI-ACT-389');
      final snapshot=adapter.snapshot(h.context,h.reference.orderId);await entered.future;h.active=false;h.changes.value++;
      gate.complete(null);expect(await snapshot,isNull);expect(h.documents.copies,0);expect(h.draftStore.writes,isEmpty);
    }finally{await h.close(tester);}
  });
  testWidgets('ORDER02 missing supplement and source rollback stay unavailable instead of borrowing catalogue data',(tester)async{
    final h=_Order02NativeHarness();try{await h.ready(tester);final adapter=h.adapter('AI-ACT-389');
      final first=await adapter.snapshot(h.context,h.reference.orderId);expect(first,isNotNull);
      h.documents.onRead=(target)async=>WorkspaceOrderDocumentsRead(targetBinding:target.binding,revision:1,documents:[h.documents.document()]);
      expect(await adapter.snapshot(h.context,h.reference.orderId),isNull);
      h.documents.onRead=(_)async=>null;expect(await adapter.snapshot(h.context,h.reference.orderId),isNull);
      h.warranty.respond=(_)async=>null;expect(await h.adapter('AI-ACT-392').snapshot(h.context,h.lineEntity),isNull);
      expect(h.draftStore.writes,isEmpty);expect(h.documents.copies,0);
    }finally{await h.close(tester);}
  });
}

void registerOrder02BaselineCorrectionTests(){
  testWidgets('ORDER02 394 published row removed from the saved native baseline cannot be implicitly restored',(tester)async{
    final h=_Order02NativeHarness();try{await h.ready(tester);
      final target=h.resolve(h.lineEntity)!,read=(await h.gateway.readPurchasedUnits(role:target.role,realm:target.realm,
        reference:h.reference,line:h.original.lines.single))!;
      final key=WorkspacePurchasedUnitDraftKey(account:h.gateway.accountUserId,realm:target.realm,store:h.reference.storeId,binding:read.target.binding);
      h.draftStore.saved=WorkspacePurchasedUnitDraft(key:key,revision:1,publishedRevision:read.revision,
        rows:const [WorkspacePurchasedUnitRow(id:'HOST-kept-private-device',serial:'HOST human kept this device')]);
      final original=jsonEncode(h.draftStore.saved!.toJson());
      final opened=await h.open(tester,'AI-ACT-394',fields:{'rows':[{'id':'HOST-existing-device','serial':'HOST old published row'}]});
      expect(await opened.result,MoolAssistantReviewResult.unavailable);
      expect(jsonEncode(h.draftStore.saved!.toJson()),original);expect(h.draftStore.writes,isEmpty);
      expect(find.widgetWithText(TextButton,'Save kept edits'),findsNothing);
      expect((h.units as fixtures.DevicePublisherFixture).shares,isEmpty);
    }finally{await h.close(tester);}
  });
  testWidgets('ORDER02 394 appending beyond the original native device bound is unavailable before Review',(tester)async{
    final h=_Order02NativeHarness();try{await h.ready(tester);
      h.units.rows=List.generate(1000,(i)=>WorkspacePurchasedUnitRow(id:'HOST-device-$i',serial:'HOST original serial $i'));
      final source=jsonEncode(h.units.rows.map((row)=>row.toJson()).toList());
      final opened=await h.open(tester,'AI-ACT-394',fields:{'rows':[{'serial':'HOST extra exceeds existing native bound'}]});
      expect(await opened.result,MoolAssistantReviewResult.unavailable);expect(h.draftStore.writes,isEmpty);
      expect(jsonEncode(h.units.rows.map((row)=>row.toJson()).toList()),source);
      expect(find.widgetWithText(TextButton,'Save kept edits'),findsNothing);
      expect((h.units as fixtures.DevicePublisherFixture).shares,isEmpty);
    }finally{await h.close(tester);}
  });
}

void registerOrder02LateAckTests(){
  testWidgets('ORDER02-LATE-ACK issued Share keeps exact original pending command after retirement and native Check alone recovers',(tester)async{
    final h=_Order02NativeHarness();final entered=Completer<void>(),reply=Completer<WorkspacePurchasedUnitPublishReply?>();
    WorkspacePurchasedLineTarget? sentTarget;
    try{await h.ready(tester);
      final target=h.resolve(h.lineEntity)!,read=(await h.gateway.readPurchasedUnits(role:target.role,realm:target.realm,
        reference:h.reference,line:h.original.lines.single))!;
      final key=WorkspacePurchasedUnitDraftKey(account:h.gateway.accountUserId,realm:target.realm,store:h.reference.storeId,binding:read.target.binding);
      h.draftStore.saved=WorkspacePurchasedUnitDraft(key:key,revision:1,publishedRevision:read.revision,rows:read.rows);
      final source=h.units as fixtures.DevicePublisherFixture;
      source.onShare=(target,command){sentTarget=target;entered.complete();return reply.future;};
      final opened=await h.open(tester,'AI-ACT-395');
      final review=find.widgetWithText(TextButton,'Review and share device details');await tester.ensureVisible(review);await tester.tap(review);await tester.pumpAndSettle();
      final share=find.widgetWithText(FilledButton,'Share device details');await tester.ensureVisible(share);await tester.tap(share);await tester.pump();await entered.future;
      final command=source.shares.single;expect(h.draftStore.saved!.pending!.toJson(),command.toJson());
      h.retire();await tester.pumpAndSettle();reply.complete(await source.apply(sentTarget!,command));await tester.pumpAndSettle();
      expect(await opened.result,MoolAssistantReviewResult.stale);expect(h.draftStore.saved!.pending!.toJson(),command.toJson());
      expect(source.shares,hasLength(1));expect(source.checks,isEmpty);
      h.proposal=true;final recovery=await h.open(tester,'AI-ACT-398');
      expect(source.shares,hasLength(1));expect(source.checks,isEmpty);
      final check=find.widgetWithText(TextButton,'Check sharing status');await tester.ensureVisible(check);await tester.tap(check);await tester.pumpAndSettle();
      expect(source.checks,hasLength(1));expect(source.checks.single.toJson(),command.toJson());expect(source.shares,hasLength(1));
      expect(h.draftStore.saved!.pending,isNull);await h.back(tester);await recovery.result;
    }finally{if(!reply.isCompleted)reply.complete(null);await h.close(tester);}
  });
  testWidgets('ORDER02-LATE-ACK issued mismatch keeps exact original pending report after retirement and native Check alone recovers',(tester)async{
    final h=_Order02NativeHarness(buyer:true);final entered=Completer<void>(),reply=Completer<WorkspacePurchasedUnitReportReply?>();
    WorkspacePurchasedLineTarget? sentTarget;
    try{await h.ready(tester);final source=h.units as fixtures.DeviceReporterFixture;
      source.onReport=(target,command){sentTarget=target;entered.complete();return reply.future;};
      final opened=await h.open(tester,'AI-ACT-396',fields:{'selectedIds':['supplier-device-A'],'note':'HOST actual issued mismatch'});
      final save=find.widgetWithText(TextButton,'Save kept edits');await tester.ensureVisible(save);await tester.tap(save);await tester.pumpAndSettle();
      final review=find.widgetWithText(TextButton,'Review device report');await tester.ensureVisible(review);await tester.tap(review);await tester.pumpAndSettle();
      final send=find.widgetWithText(FilledButton,'Send device report');await tester.ensureVisible(send);await tester.tap(send);await tester.pump();await entered.future;
      final command=source.reports.single;expect(h.draftStore.saved!.report!.pending!.toJson(),command.toJson());
      h.retire();await tester.pumpAndSettle();reply.complete(source.reply(sentTarget!,command));await tester.pumpAndSettle();
      expect(await opened.result,MoolAssistantReviewResult.stale);expect(h.draftStore.saved!.report!.pending!.toJson(),command.toJson());
      expect(source.reports,hasLength(1));expect(source.checks,isEmpty);
      h.proposal=true;final recovery=await h.open(tester,'AI-ACT-399');expect(source.checks,isEmpty);
      final check=find.widgetWithText(TextButton,'Check report status');await tester.ensureVisible(check);await tester.tap(check);await tester.pumpAndSettle();
      expect(source.checks,hasLength(1));expect(source.checks.single.toJson(),command.toJson());expect(source.reports,hasLength(1));
      expect(h.draftStore.saved!.report!.pending!.toJson(),command.toJson(),reason:'A recorded mismatch keeps its exact command as original audit evidence.');expect(h.draftStore.saved!.report!.recorded,isTrue);
      await h.back(tester);await recovery.result;
    }finally{if(!reply.isCompleted)reply.complete(null);await h.close(tester);}
  });
}
