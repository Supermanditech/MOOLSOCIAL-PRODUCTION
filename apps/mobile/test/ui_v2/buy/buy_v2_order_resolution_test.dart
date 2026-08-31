import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_order_resolution_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'accepted resolution requires exact order, option, reason and reference',
    () async {
      final adapter = _AcceptedResolutionAdapter();
      final core = BuySession();
      final session = BuyV2Session(core: core, orderResolutionAdapter: adapter);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      final order = session.orders.firstWhere(
        (candidate) => candidate.status == BuyV2OrderStatus.delivered,
      );

      expect(await session.refreshOrderResolution(order.id), isTrue);
      expect(
        session.orderResolutionFor(order.id)?.options.single.kind,
        BuyV2OrderResolutionKind.refund,
      );
      expect(
        await session.submitOrderResolution(
          orderId: order.id,
          kind: BuyV2OrderResolutionKind.refund,
          reason: 'Damaged item',
        ),
        isTrue,
      );
      expect(adapter.submitCalls, 1);
      expect(session.orderResolutionResultFor(order.id)?.reference, 'RR-1001');
    },
  );

  testWidgets('delivered order resolution fits and fails closed at 320', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    final order = session.orders.firstWhere(
      (candidate) => candidate.status == BuyV2OrderStatus.delivered,
    );
    expect(session.openTracking(order.id), isTrue);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MoolTheme.light(),
        home: BuyV2Screen(
          session: session,
          initialDestination: BuyV2Destination.orders,
          initialView: BuyV2View.tracking,
          orderId: order.id,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final trackingScroll = find
        .descendant(
          of: find.byKey(PageStorageKey('buy-tracking-${order.id}')),
          matching: find.byType(Scrollable),
        )
        .first;
    final manage = find.byKey(
      ValueKey('buy-tracking-manage-order-${order.id}'),
    );
    await tester.scrollUntilVisible(manage, 220, scrollable: trackingScroll);
    for (var attempt = 0; attempt < 3; attempt += 1) {
      if (tester.getCenter(manage).dy < 610) break;
      await tester.drag(trackingScroll, const Offset(0, -180));
      await tester.pumpAndSettle();
    }
    await tester.tap(manage);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-order-resolution-sheet')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('buy-order-resolution-refund')));
    await tester.pumpAndSettle();
    final reason = find.byKey(
      const ValueKey('buy-order-resolution-reason-refund'),
    );
    await tester.tap(reason);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Damaged item').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-order-resolution-submit')));
    await tester.pumpAndSettle();
    expect(
      find.text('This request could not be sent. Contact support for help.'),
      findsOneWidget,
    );
    expect(session.orderResolutionResultFor(order.id)?.accepted, isFalse);
    expect(session.view, BuyV2View.tracking);
    expect(tester.takeException(), isNull);
  });
}

final class _AcceptedResolutionAdapter implements BuyV2OrderResolutionAdapter {
  int submitCalls = 0;

  @override
  Future<BuyV2OrderResolutionSnapshot> load(BuyV2Order order) async =>
      BuyV2OrderResolutionSnapshot(
        orderId: order.id,
        state: BuyV2OrderResolutionState.ready,
        sourceId: 'order-service',
        options: const [
          BuyV2OrderResolutionOption(
            kind: BuyV2OrderResolutionKind.refund,
            title: 'Request refund',
            detail: 'Request a refund review.',
            reasons: ['Damaged item'],
          ),
        ],
      );

  @override
  Future<BuyV2OrderResolutionResult> submit(
    BuyV2OrderResolutionRequest request,
  ) async {
    submitCalls += 1;
    return const BuyV2OrderResolutionResult(
      accepted: true,
      customerMessage: 'Your refund request was submitted.',
      reference: 'RR-1001',
    );
  }
}
