import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_invoice.dart';

void main() {
  for (final textScale in <double>[1, 1.4]) {
    testWidgets(
      'invoice final notice clears fixed download action at ${textScale}x text',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        tester.view.padding = const FakeViewPadding(bottom: 24);
        tester.view.viewPadding = const FakeViewPadding(bottom: 44);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPadding);
        addTearDown(tester.view.resetViewPadding);
        final session = BuyV2Session(core: BuySession());
        final order = session.orders.first;

        await tester.pumpWidget(
          MaterialApp(
            theme: MoolTheme.light(),
            builder: (context, child) {
              final media = MediaQuery.of(context);
              return MediaQuery(
                data: media.copyWith(textScaler: TextScaler.linear(textScale)),
                child: child!,
              );
            },
            home: BuyV2InvoicePage(order: order),
          ),
        );
        await tester.pumpAndSettle();

        final notice = find.byKey(
          ValueKey('buy-invoice-record-notice-${order.id}'),
        );
        final list = find.byKey(ValueKey('buy-invoice-scroll-${order.id}'));
        final scrollable = find.descendant(
          of: list,
          matching: find.byType(Scrollable),
        );
        await tester.scrollUntilVisible(notice, 240, scrollable: scrollable);
        await tester.pumpAndSettle();

        final download = find.byKey(
          ValueKey('buy-download-invoice-${order.id}'),
        );
        expect(
          find.byKey(const ValueKey('buy-invoice-bottom-safe-area')),
          findsOneWidget,
        );
        final downloadRect = tester.getRect(download);
        expect(downloadRect.height, greaterThanOrEqualTo(48));
        expect(downloadRect.bottom, lessThanOrEqualTo(756));
        expect(
          tester.getBottomLeft(notice).dy,
          lessThan(tester.getTopLeft(download).dy),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'invoice uses OPPO top inset when bottom padding is not exported',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      tester.view.viewPadding = const FakeViewPadding(top: 41);
      addTearDown(tester.view.reset);
      final session = BuyV2Session(core: BuySession());
      final order = session.orders.first;

      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          home: BuyV2InvoicePage(order: order),
        ),
      );
      await tester.pumpAndSettle();

      final download = find.byKey(ValueKey('buy-download-invoice-${order.id}'));
      final rect = tester.getRect(download);
      expect(rect.height, greaterThanOrEqualTo(48));
      expect(rect.bottom, lessThanOrEqualTo(773));
      expect(tester.takeException(), isNull);
    },
  );
}
