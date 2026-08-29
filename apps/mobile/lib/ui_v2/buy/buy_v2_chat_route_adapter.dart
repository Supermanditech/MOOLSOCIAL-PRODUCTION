import '../../features/buy/buy_v2_models.dart';

/// Buy contributes only commerce context and exact return wiring to the
/// authoritative shared Chat module.
class BuyV2ChatRouteAdapter {
  const BuyV2ChatRouteAdapter();

  String locationFor({
    required String currentRoute,
    required BuyV2Destination destination,
    required bool offersActive,
  }) {
    final returnRoute = _returnRouteFor(
      currentRoute: currentRoute,
      destination: destination,
      offersActive: offersActive,
    );
    final type = offersActive
        ? 'support'
        : switch (destination) {
            BuyV2Destination.orders => 'order',
            BuyV2Destination.wholesale => 'business',
            BuyV2Destination.medicine => 'business',
            BuyV2Destination.shop => null,
          };
    return Uri(
      path: '/app/chat/inbox',
      queryParameters: {'return': returnRoute, 'type': ?type},
    ).toString();
  }

  String orderHelpLocationFor({required String orderId}) {
    final normalizedOrderId = orderId.trim();
    return Uri(
      path: '/app/chat/thread/shop-assist',
      queryParameters: {
        'draft': 'Help with order $normalizedOrderId',
        'return': Uri(
          path: '/app/buy',
          queryParameters: {
            'sub': 'orders',
            'view': 'tracking',
            'order': normalizedOrderId,
          },
        ).toString(),
        'directReturn': 'true',
      },
    ).toString();
  }

  String _returnRouteFor({
    required String currentRoute,
    required BuyV2Destination destination,
    required bool offersActive,
  }) {
    final parsed = Uri.tryParse(currentRoute);
    if (parsed != null &&
        parsed.path.startsWith('/app/') &&
        !parsed.path.startsWith('/app/chat')) {
      return currentRoute;
    }
    if (offersActive) return '/app/buy?sub=offers';
    return switch (destination) {
      BuyV2Destination.orders => '/app/buy?sub=orders',
      BuyV2Destination.wholesale => '/app/buy?sub=wholesale',
      BuyV2Destination.medicine => '/app/book?sub=medicine',
      BuyV2Destination.shop => '/app/buy',
    };
  }
}
