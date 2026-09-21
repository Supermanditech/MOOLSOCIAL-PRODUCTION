import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_cart_contracts.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/work/screens/work_workspace_dashboard_screen.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

// Host-only inspection of unchanged production routes; no service writes or APK.
void main() {
  for (final storeScreen in [false, true]) {
    testWidgets('baseline capture ${storeScreen ? 'Visit store' : 'public Buy'}', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      expect(
        buyV2DeviceReviewBenefitSeedsEnabled,
        isTrue,
        reason: 'Capture must match the reviewed APK catalogue mode.',
      );
      final journey = JourneySession(
        store: MemoryJourneyStore(
          snapshot: const JourneySnapshot(
            languageCode: 'en',
            areaMode: 'manual',
            areaLabel: 'Sardarpura',
            setupComplete: true,
          ),
        ),
        otpGateway: ReviewOtpGateway(signedIn: true),
      );
      final core = BuySession();
      addTearDown(journey.dispose);
      addTearDown(core.dispose);
      await journey.start();
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('cursor-baseline-capture'),
          child: MoolSocialApp(
            session: journey,
            buySession: core,
            uiReviewOnly: true,
            initialLocation: '/app/buy?sub=shop',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BuyV2Screen), findsOneWidget);
      expect(find.byType(WorkWorkspaceDashboardScreen), findsNothing);
      final session = tester
          .widget<BuyV2Screen>(find.byType(BuyV2Screen))
          .session;
      expect(
        session.pagedCatalogueEnabled,
        isTrue,
        reason: 'The old small default catalogue is not this review baseline.',
      );
      if (storeScreen) {
        final productCard = find.byWidgetPredicate((widget) {
          final key = widget.key;
          return key is ValueKey<String> &&
              key.value.startsWith('buy-paged-card-');
        }).first;
        final cardKey = tester.widget(productCard).key! as ValueKey<String>;
        final productId = cardKey.value.substring('buy-paged-card-'.length);
        await tester.ensureVisible(productCard);
        await tester.tap(productCard);
        await tester.pumpAndSettle();
        expect(session.selectedProductId, productId);
        final visitStore = find.byKey(
          ValueKey('buy-shop-seller-action-$productId'),
        );
        final productScroll = find
            .descendant(
              of: find.byKey(PageStorageKey('buy-product-$productId')),
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(
          visitStore,
          220,
          scrollable: productScroll,
        );
        await tester.pumpAndSettle();
        expect(find.text('Visit store'), findsOneWidget);
        await tester.tap(visitStore);
        await tester.pumpAndSettle();
        expect(
          find.byKey(ValueKey('buy-shop-seller-sheet-$productId')),
          findsOneWidget,
        );
        expect(find.byType(WorkWorkspaceDashboardScreen), findsNothing);
      }
      for (final element in find.byType(Image).evaluate().toList()) {
        if (!element.mounted) continue;
        final provider = (element.widget as Image).image;
        ImageProvider source = provider;
        while (source is ResizeImage) {
          source = source.imageProvider;
        }
        if (source is AssetImage) {
          await tester.runAsync(() => precacheImage(provider, element));
        }
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('cursor-baseline-capture')),
      );
      const directory =
          'C:/GUARANTEED OUTCOME/outputs/cursor-buy-ready-20260921/corrected-r5';
      await tester.runAsync(() async {
        await Directory(directory).create(recursive: true);
        final image = await boundary.toImage(pixelRatio: 2);
        try {
          final bytes = await image.toByteData(format: ImageByteFormat.png);
          await File(
            '$directory/${storeScreen ? 'public-visit-store' : 'public-buy'}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
        } finally {
          image.dispose();
        }
      });
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
