import 'dart:io';
import 'dart:ui' show ImageByteFormat;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_catalogue.dart';

void main() {
  setUpAll(() async {
    final font = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'));
    await font.load();
  });
  for (final surface in [
    'Shop',
    'Wholesale',
    'Medicine',
    'Store',
    'Saved',
    'Search',
  ]) {
    for (final width in [320.0, 390.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('Shared SKU fit $surface $width $scale', (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 844);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final core = BuySession();
          final session = BuyV2Session(core: core);
          addTearDown(core.dispose);
          addTearDown(session.dispose);
          final destination = surface == 'Medicine'
              ? BuyV2Destination.medicine
              : surface == 'Wholesale'
              ? BuyV2Destination.wholesale
              : BuyV2Destination.shop;
          final products = BuyV2Catalogue.products
              .where((p) => p.destination == destination)
              .take(9)
              .toList();
          if (surface == 'Saved') {
            for (final p in products) {
              session.toggleSaved(p.id);
            }
          }
          await tester.pumpWidget(
            MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: MoolTheme.light(),
              home: Scaffold(
                body: RepaintBoundary(
                  key: const ValueKey('sku-capture'),
                  child: ColoredBox(
                    color: const Color(0xFFFFFCF8),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                '$surface SKU grid',
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                          BuyV2ProgressiveProductGrid(
                            session: session,
                            products: products,
                            storageKey: 'shared-fit',
                            semanticLabel: surface,
                            storeContext: surface == 'Store',
                            savedContext: surface == 'Saved',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final rects = [
            for (final p in products)
              tester.getRect(find.byKey(ValueKey('buy-product-${p.id}'))),
          ];
          for (var i = 0; i < products.length; i++) {
            final p = products[i];
            final frame = tester.getRect(
              find.byKey(ValueKey('buy-grid-packshot-${p.id}')),
            );
            expect(frame.width, closeTo(frame.height, 1));
            final badge = find.byKey(
              ValueKey('buy-product-card-badge-${p.id}'),
            );
            if (badge.evaluate().isNotEmpty) {
              expect(
                tester.getRect(badge).bottom,
                lessThanOrEqualTo(frame.top),
              );
            }
            final saveBounds = tester.getRect(
              find.byKey(ValueKey('buy-save-${p.id}')),
            );
            final badgeBottom = badge.evaluate().isEmpty
                ? saveBounds.bottom
                : tester.getRect(badge).bottom;
            final controlsBottom = badgeBottom > saveBounds.bottom
                ? badgeBottom
                : saveBounds.bottom;
            expect(
              frame.top - controlsBottom,
              inInclusiveRange(0, 2),
              reason: 'Only a thin gap follows controls, including long badges',
            );
            expect(
              frame.overlaps(
                tester.getRect(find.byKey(ValueKey('buy-save-${p.id}'))),
              ),
              isFalse,
            );
            final action = tester.getRect(
              find.byKey(ValueKey('buy-add-shell-${p.id}')),
            );
            expect(rects[i].bottom - action.bottom, inInclusiveRange(0, 4));
            final below =
                rects
                    .where(
                      (r) =>
                          (r.left - rects[i].left).abs() < 1 &&
                          r.top > rects[i].top,
                    )
                    .toList()
                  ..sort((a, b) => a.top.compareTo(b.top));
            if (below.isNotEmpty) {
              expect(below.first.top - rects[i].bottom, closeTo(10, 1));
            }
          }
          final first = products.first;
          final save = find.byKey(ValueKey('buy-save-${first.id}'));
          final saveRect = tester.getRect(save);
          expect(saveRect.width, greaterThanOrEqualTo(28));
          expect(saveRect.height, greaterThanOrEqualTo(28));
          expect(
            saveRect.top - rects.first.top,
            closeTo(0, 1),
            reason: 'Save is attached to the top card edge',
          );
          final wasSaved = session.isSaved(first.id);
          await tester.ensureVisible(save);
          await tester.pumpAndSettle();
          await tester.tap(save);
          await tester.pumpAndSettle();
          expect(session.isSaved(first.id), !wasSaved);
          expect(session.view, BuyV2View.catalogue);
          await tester.tap(save);
          await tester.pumpAndSettle();
          expect(session.isSaved(first.id), wasSaved);
          const root = String.fromEnvironment('FOUNDER_PENDING_CAPTURE_DIR');
          if (root.isNotEmpty && width == 390 && scale == 1) {
            await tester.runAsync(() async {
              for (final e in find.byType(Image).evaluate().toList()) {
                final provider = (e.widget as Image).image;
                await precacheImage(provider, e);
              }
            });
            await tester.pump(const Duration(milliseconds: 200));
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('sku-capture')),
            );
            await tester.runAsync(() async {
              final image = await boundary.toImage(pixelRatio: 1.5);
              final bytes = await image.toByteData(format: ImageByteFormat.png);
              await Directory(root).create(recursive: true);
              await File(
                '$root/sku-$surface.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
        });
      }
    }
  }
}
