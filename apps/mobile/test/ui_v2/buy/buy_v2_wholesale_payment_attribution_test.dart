import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_invoice.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_views.dart';

void main() {
  test('active Wholesale order owns explicit actors and payment schedule', () {
    final session = BuyV2Session(core: BuySession());
    final order = session.orders.firstWhere((item) => item.id == 'PO-240783');

    expect(order.partner, 'Marwar Foods Distribution');
    expect(order.partnerType, 'Mool Trade Partner');
    expect(order.buyerName, 'Shree Balaji Retail');
    expect(order.buyerType, 'Verified retailer Workspace');
    expect(order.itemSummary, isNot(contains('Shree Balaji Retail')));
    expect(order.paymentMethod, 'Bank transfer');
    expect(order.paymentTermLabel, contains('balance at delivery'));
    expect(order.amountPaidNow, 1260);
    expect(order.balanceDue, 2940);
    expect(order.balanceDueLabel, 'Due at confirmed delivery');
    expect(order.paymentStatusLabel, contains('balance due'));
  });

  testWidgets(
    'Wholesale invoice exposes buyer, supplier, payment status and due date at 140 percent',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final session = BuyV2Session(core: BuySession());
      final order = session.orders.firstWhere((item) => item.id == 'PO-240783');

      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          builder: (context, child) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(textScaler: const TextScaler.linear(1.4)),
              child: child!,
            );
          },
          home: BuyV2InvoicePage(order: order),
        ),
      );
      await tester.pumpAndSettle();

      final scroll = find.byKey(ValueKey('buy-invoice-scroll-${order.id}'));
      final invoiceScrollable = find.descendant(
        of: scroll,
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.text('Shree Balaji Retail'),
        260,
        scrollable: invoiceScrollable,
      );
      expect(find.text('Buyer'), findsOneWidget);
      expect(find.text('Shree Balaji Retail'), findsOneWidget);
      expect(find.text('Buyer role'), findsOneWidget);
      expect(find.text('Verified retailer Workspace'), findsOneWidget);
      expect(find.text('Payment status'), findsOneWidget);
      expect(
        find.text('Booking amount paid · balance due at delivery'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Wholesale tracking identifies both buyer and supplier roles', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    expect(session.openTracking('PO-240783'), isTrue);
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: Scaffold(
          body: BuyV2TrackingView(session: session, onOpenOrderHelp: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Shree Balaji Retail'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Mool Trade Partner'), findsOneWidget);
    expect(find.text('Marwar Foods Distribution'), findsWidgets);
    expect(find.text('Verified retailer Workspace'), findsOneWidget);
    expect(find.text('Shree Balaji Retail'), findsOneWidget);
    expect(find.text('Payment status'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
