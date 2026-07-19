import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'physical app renders one coherent outcome dock across every vertical',
    (tester) async {
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
      addTearDown(journey.dispose);
      await journey.start();

      Future<void> verify({
        required String route,
        required String prefix,
        required List<String> actionIds,
        required String screenshot,
      }) async {
        await tester.pumpWidget(
          MoolSocialApp(
            key: UniqueKey(),
            session: journey,
            initialLocation: route,
          ),
        );
        await tester.pumpAndSettle();
        for (final id in actionIds) {
          final target = find.byKey(Key('$prefix-dock-$id'));
          expect(target, findsOneWidget, reason: '$route is missing $id');
          expect(
            tester.getSize(target).height,
            greaterThanOrEqualTo(44),
            reason: '$route $id is below the minimum tap target',
          );
        }
        await binding.takeScreenshot(screenshot);
      }

      await binding.convertFlutterSurfaceToImage();
      await verify(
        route: '/app/buy/grocery',
        prefix: 'buy',
        actionIds: const ['mool', 'shop', 'basket', 'orders', 'chat'],
        screenshot: 'design-buy-outcome-dock',
      );
      await verify(
        route: '/app/eat/order',
        prefix: 'eat',
        actionIds: const ['mool', 'order', 'table', 'tiffin', 'chat'],
        screenshot: 'design-eat-outcome-dock',
      );
      await verify(
        route: '/app/ride/book',
        prefix: 'ride',
        actionIds: const ['mool', 'book', 'trip', 'help', 'chat'],
        screenshot: 'design-ride-outcome-dock',
      );
      await verify(
        route: '/app/book/home',
        prefix: 'book',
        actionIds: const ['mool', 'book', 'activity', 'help', 'chat'],
        screenshot: 'design-book-outcome-dock',
      );
      await verify(
        route: '/app/pay/home',
        prefix: 'pay',
        actionIds: const ['mool', 'pay', 'receipts', 'requests', 'chat'],
        screenshot: 'design-pay-outcome-dock',
      );
      await verify(
        route: '/app/work/earn',
        prefix: 'work',
        actionIds: const ['mool', 'earn', 'my-work', 'chat'],
        screenshot: 'design-work-outcome-dock',
      );
      await verify(
        route: '/app/retailer/home',
        prefix: 'retailer',
        actionIds: const ['mool', 'orders', 'stock', 'wholesale', 'chat'],
        screenshot: 'design-retailer-outcome-dock',
      );
    },
  );
}
