import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_views.dart';

void main() {
  test(
    'UI review GST profile remains reusable across Buy screen recreation',
    () async {
      final session = BuyV2Session(core: BuySession());
      final store = session.gstInvoiceProfileStore;
      expect(store?.ownerScope, startsWith('device-review-session:'));
      final first = BuyV2GstInvoiceController(store: store);
      addTearDown(first.dispose);

      expect(
        await first.save(
          destination: BuyV2Destination.shop,
          legalName: 'Shree Balaji Retail',
          gstin: '08ABCDE1234F1Z5',
          billingAddress: '12 Market Road, Jodhpur',
          remember: true,
        ),
        isTrue,
      );
      expect(first.message, 'GST details kept until you close the app.');

      final restored = BuyV2GstInvoiceController(store: store);
      addTearDown(restored.dispose);
      await restored.restore();
      expect(restored.savedProfiles, hasLength(1));
      expect(restored.savedProfiles.single.legalName, 'Shree Balaji Retail');
      restored.selectSaved(
        BuyV2Destination.wholesale,
        restored.savedProfiles.single,
      );
      expect(
        restored.detailsFor(BuyV2Destination.wholesale)?.gstin,
        '08ABCDE1234F1Z5',
      );
    },
  );

  testWidgets(
    'GST sheet offers truthful session reuse instead of order-only copy',
    (tester) async {
      final session = BuyV2Session(core: BuySession());
      final controller = BuyV2GstInvoiceController(
        store: session.gstInvoiceProfileStore,
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () => showBuyV2GstInvoiceSheet(
                  context,
                  controller: controller,
                  destination: BuyV2Destination.shop,
                ),
                child: const Text('Add GST details'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Add GST details'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('buy-gst-remember')), findsOneWidget);
      expect(find.text('Use again until you close the app'), findsOneWidget);
      expect(
        find.text('These details are cleared when you close the app.'),
        findsOneWidget,
      );
      expect(
        find.text('These details will be used for this order only.'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('GST action clears OPPO navigation and semantics insets', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    tester.view.viewPadding = const FakeViewPadding(top: 41, bottom: 44);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    final controller = BuyV2GstInvoiceController(
      store: session.gstInvoiceProfileStore,
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => showBuyV2GstInvoiceSheet(
                context,
                controller: controller,
                destination: BuyV2Destination.shop,
              ),
              child: const Text('Add GST details'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Add GST details'));
    await tester.pumpAndSettle();

    final action = find.byKey(const ValueKey('buy-gst-save'));
    final rect = tester.getRect(action);
    expect(rect.height, greaterThanOrEqualTo(44));
    expect(rect.bottom, lessThanOrEqualTo(729));
    expect(tester.takeException(), isNull);
  });

  testWidgets('GST action clears OPPO top-only exported semantics inset', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    tester.view.viewPadding = const FakeViewPadding(top: 41);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    final controller = BuyV2GstInvoiceController(
      store: session.gstInvoiceProfileStore,
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => showBuyV2GstInvoiceSheet(
                context,
                controller: controller,
                destination: BuyV2Destination.shop,
              ),
              child: const Text('Add GST details'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Add GST details'));
    await tester.pumpAndSettle();

    final action = find.byKey(const ValueKey('buy-gst-save'));
    final rect = tester.getRect(action);
    expect(rect.height, greaterThanOrEqualTo(48));
    expect(rect.bottom, lessThanOrEqualTo(737));
    expect(tester.takeException(), isNull);
  });
}
