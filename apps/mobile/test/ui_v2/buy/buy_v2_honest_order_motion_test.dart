import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget progressApp({
    required String ownerId,
    required double progress,
    required String statusLabel,
    bool isComplete = false,
    bool disableAnimations = false,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData().copyWith(
          disableAnimations: disableAnimations,
        ),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: 240,
              child: BuyV2HonestProgressIndicator(
                key: const ValueKey('honest-progress-owner'),
                ownerId: ownerId,
                progress: progress,
                statusLabel: statusLabel,
                isComplete: isComplete,
                minHeight: 6,
                backgroundColor: BuyV2Colors.softBlue,
                valueColor: BuyV2Colors.green,
                indicatorKey: const ValueKey('honest-progress-indicator'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double renderedProgress(WidgetTester tester, Key key) {
    return tester.widget<LinearProgressIndicator>(find.byKey(key)).value!;
  }

  Widget buyApp(
    BuyV2Session session, {
    double textScale = 1,
    bool disableAnimations = false,
  }) {
    return MaterialApp(
      theme: MoolTheme.light(),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: disableAnimations,
          ),
          child: child!,
        );
      },
      home: BuyV2Screen(session: session),
    );
  }

  testWidgets(
    'first frame is current and only a real same-owner change moves',
    (tester) async {
      await tester.pumpWidget(
        progressApp(
          ownerId: 'MS-1',
          progress: .42,
          statusLabel: 'Supplier confirmed',
        ),
      );

      expect(
        renderedProgress(tester, const ValueKey('honest-progress-indicator')),
        .42,
      );

      await tester.pumpWidget(
        progressApp(ownerId: 'MS-1', progress: .76, statusLabel: 'Dispatched'),
      );
      final start = renderedProgress(
        tester,
        const ValueKey('honest-progress-indicator'),
      );
      expect(start, .42);

      await tester.pump(const Duration(milliseconds: 90));
      final middle = renderedProgress(
        tester,
        const ValueKey('honest-progress-indicator'),
      );
      expect(middle, greaterThan(.42));
      expect(middle, lessThan(.76));

      await tester.pumpAndSettle();
      expect(
        renderedProgress(tester, const ValueKey('honest-progress-indicator')),
        .76,
      );

      await tester.pumpWidget(
        progressApp(
          ownerId: 'MS-2',
          progress: .31,
          statusLabel: 'Preparing your order',
        ),
      );
      expect(
        renderedProgress(tester, const ValueKey('honest-progress-indicator')),
        .31,
      );
    },
  );

  testWidgets('reduced motion and final-state invariants resolve immediately', (
    tester,
  ) async {
    await tester.pumpWidget(
      progressApp(
        ownerId: 'MS-1',
        progress: .4,
        statusLabel: 'Supplier confirmed',
        disableAnimations: true,
      ),
    );
    await tester.pumpWidget(
      progressApp(
        ownerId: 'MS-1',
        progress: .8,
        statusLabel: 'Dispatched',
        disableAnimations: true,
      ),
    );
    expect(
      renderedProgress(tester, const ValueKey('honest-progress-indicator')),
      .8,
    );

    await tester.pumpWidget(
      progressApp(
        ownerId: 'MS-1',
        progress: .8,
        statusLabel: 'Delivered',
        isComplete: true,
        disableAnimations: true,
      ),
    );
    expect(
      renderedProgress(tester, const ValueKey('honest-progress-indicator')),
      1,
    );

    await tester.pumpWidget(
      progressApp(
        ownerId: 'MS-1',
        progress: 1,
        statusLabel: 'Arriving soon',
        disableAnimations: true,
      ),
    );
    expect(
      renderedProgress(tester, const ValueKey('honest-progress-indicator')),
      .999,
    );
  });

  testWidgets('Orders and Tracking never replay progress or claim live state', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());

    await tester.pumpWidget(buyApp(session));
    await tester.pumpAndSettle();
    session.openOrders();
    await tester.pump();
    await tester.pump();
    await tester.pump();
    final activeOrder = session.visibleOrders.first;

    expect(
      renderedProgress(
        tester,
        ValueKey('buy-order-progress-${activeOrder.id}'),
      ),
      activeOrder.progress,
    );

    session.openTracking(activeOrder.id);
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('CURRENT'), findsOneWidget);
    expect(find.text('LIVE'), findsNothing);
    expect(
      renderedProgress(tester, const ValueKey('buy-tracking-progress')),
      activeOrder.progress,
    );
    expect(
      find.byKey(const ValueKey('buy-tracking-route-connector')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('buy-tracking-route')),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is LinearProgressIndicator ||
              widget is BuyV2HonestProgressIndicator,
        ),
      ),
      findsNothing,
    );
    await tester.scrollUntilVisible(
      find.text('Order updates'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Order alerts are on'), findsOneWidget);

    session.openOrders();
    session.showOrdersTab(BuyV2OrdersTab.delivered);
    await tester.pumpAndSettle();
    expect(session.visibleOrders, isNotEmpty);
    for (final order in session.visibleOrders) {
      expect(order.status, BuyV2OrderStatus.delivered);
      expect(
        renderedProgress(tester, ValueKey('buy-order-progress-${order.id}')),
        1,
      );
    }
  });

  testWidgets('compact 140-percent Orders and Tracking remain stable', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.reset);

    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(buyApp(session, textScale: 1.4));
    await tester.pumpAndSettle();
    session.openOrders();
    await tester.pumpAndSettle();
    final activeOrder = session.visibleOrders.first;
    expect(find.byKey(const ValueKey('buy-orders-tab-active')), findsOneWidget);
    expect(tester.takeException(), isNull);

    session.openTracking(activeOrder.id);
    await tester.pumpAndSettle();
    expect(find.text('CURRENT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
