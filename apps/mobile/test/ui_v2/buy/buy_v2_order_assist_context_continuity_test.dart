import 'buy_v2_screen_test.dart' show r66VisualCaptureRoot, captureR66Visual;
import 'package:flutter/rendering.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/buy/buy_v2_customer_copy.dart';
import 'package:moolsocial/features/chat/chat_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_chat_route_adapter.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

class _R6634IdentitySession extends BuyV2Session {
  _R6634IdentitySession(this.fixture) : super(core: BuySession());
  final BuyV2Order fixture;
  @override
  List<BuyV2Order> get visibleOrders => [fixture];
  @override
  List<BuyV2Order> get orders => [fixture];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  BuyV2Session newSession() => BuyV2Session(core: BuySession());

  Widget app(
    BuyV2Session session, {
    double textScale = 1,
    bool reducedMotion = false,
    VoidCallback? onOpenChat,
  }) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: MoolTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reducedMotion,
        ),
        child: child!,
      ),
      home: BuyV2Screen(
        session: session,
        initialDestination: session.destination,
        initialView: session.view,
        onOpenChat: onOpenChat,
      ),
    );
  }

  for (var route = 0; route < 3; route++) {
    for (var variant = 0; variant < 3; variant++) {
      final routeName = [
        'new Orders',
        'retained Orders',
        'supplier chat',
      ][route];
      final stateName = [
        'normal',
        'long name',
        '200 percent with keyboard',
      ][variant];
      testWidgets(
        'R6634 C02-${route * 3 + variant + 1} $routeName $stateName',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(390, 844);
          addTearDown(tester.view.reset);
          tester.platformDispatcher.textScaleFactorTestValue = variant == 2
              ? 2
              : 1;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          const storeId = 'buy-catalogue-dev-v1-shop-store-000001';
          const skuId = '$storeId-sku-0001';
          final name = variant == 1
              ? 'Sardarpura Family Grocery and Household Supplies'
              : 'Mool Market 000001';
          final product = BuyV2Catalogue.products.first.copyWith(
            id: skuId,
            storeId: storeId,
            seller: name,
          );
          final order = BuyV2Order(
            id: 'R6634-NAME',
            destination: BuyV2Destination.shop,
            title: 'Shop order',
            itemSummary: '1 product',
            total: 37,
            partner: name,
            partnerType: 'Retailer',
            promise: 'Delivery in 20 min',
            destinationLabel: 'Jodhpur',
            progress: .4,
            status: BuyV2OrderStatus.preparing,
            productIds: const [skuId],
            lines: route == 1
                ? const []
                : [BuyV2CartLine(product: product, quantity: 1)],
          );
          final expected = variant == 1 ? name : 'Mool Market 1';
          expect(order.customerPartner, expected);
          expect(order.partner, name, reason: 'Stored identity is immutable');
          final location = const BuyV2ChatRouteAdapter().orderHelpLocationFor(
            order: order,
          );
          final uri = Uri.parse(location);
          expect(uri.queryParameters['supplier'], expected);
          if (route < 2) {
            final session = _R6634IdentitySession(order);
            addTearDown(session.dispose);
            await tester.pumpWidget(
              MaterialApp(
                builder: (context, child) => r66VisualCaptureRoot(child!),
                theme: MoolTheme.light(),
                home: Scaffold(
                  body: BuyV2OrdersView(
                    session: session,
                    onOpenOrderHelp: (_) {},
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(find.text('$expected · Retailer'), findsOneWidget);
            expect(find.text('Mool Market 000001 · Retailer'), findsNothing);
          } else {
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
            await journey.start();
            final chat = ChatSession();
            addTearDown(journey.dispose);
            addTearDown(chat.dispose);
            await tester.pumpWidget(
              r66VisualCaptureRoot(
                MoolSocialApp(
                  session: journey,
                  chatSession: chat,
                  initialLocation: location,
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(find.byKey(const Key('chat-thread-screen')), findsOneWidget);
            expect(
              tester
                  .widget<Text>(find.byKey(const Key('chat-page-title')))
                  .data,
              expected,
            );
            expect(find.text('Order R6634-NAME'), findsOneWidget);
            expect(
              tester
                  .renderObject<RenderParagraph>(
                    find.byKey(const Key('chat-page-title')),
                  )
                  .didExceedMaxLines,
              isFalse,
            );
            expect(
              tester
                  .renderObject<RenderParagraph>(find.text('Order R6634-NAME'))
                  .didExceedMaxLines,
              isFalse,
            );
            if (variant == 2) {
              await tester.tap(find.byKey(const Key('chat-message-field')));
              await tester.pumpAndSettle();
              expect(
                find.byKey(const Key('chat-message-field')).hitTestable(),
                findsOneWidget,
              );
              FocusManager.instance.primaryFocus?.unfocus();
              await tester.pumpAndSettle();
            }
          }
          await captureR66Visual(tester, 'r6634-c02-$route-$variant');
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  test('Tracking and Items Assist own the exact selected order', () {
    final session = newSession();
    addTearDown(session.dispose);

    for (final id in ['MS-240782', 'PO-240783', 'RX-240784']) {
      expect(session.openTracking(id), isTrue);
      session.openAssist();
      expect(session.assistOrder.id, id);
      session.closeAssist();
      expect(session.view, BuyV2View.tracking);
      expect(session.selectedOrder.id, id);
    }

    expect(session.openOrderItems('PO-240783'), isTrue);
    session.openAssist();
    expect(session.assistOrder.id, 'PO-240783');
    session.goBack();
    expect(session.view, BuyV2View.orderItems);
    expect(session.selectedOrder.id, 'PO-240783');
  });

  test('general Assist entry cannot consume a stale selected order', () {
    final session = newSession();
    addTearDown(session.dispose);
    final establishedFallback = session.orders.firstWhere(
      (order) => order.status != BuyV2OrderStatus.delivered,
    );

    expect(session.openTracking('PO-240783'), isTrue);
    session.returnToOrders();
    session.openAssist();

    expect(session.assistOrder.id, establishedFallback.id);
    expect(session.assistOrder.id, isNot('PO-240783'));
  });

  testWidgets('retired Wholesale Assist renders exact Tracking and Chat Help', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = newSession();
    addTearDown(session.dispose);
    expect(session.openTracking('PO-240783'), isTrue);
    session.openAssist();
    var chatOpens = 0;

    await tester.pumpWidget(app(session, onOpenChat: () => chatOpens += 1));
    await tester.pumpAndSettle();

    expect(find.textContaining('PO-240783'), findsOneWidget);
    expect(find.textContaining('MS-240782'), findsNothing);
    expect(find.byKey(const PageStorageKey('buy-assist')), findsNothing);
    expect(
      find.byKey(const PageStorageKey('buy-tracking-PO-240783')),
      findsOneWidget,
    );
    final help = find.byKey(const ValueKey('buy-tracking-help'));
    await tester.scrollUntilVisible(
      help,
      240,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('buy-tracking-PO-240783')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await Scrollable.ensureVisible(tester.element(help), alignment: .3);
    await tester.pumpAndSettle();
    expect(help.hitTestable(), findsOneWidget);
    await tester.tap(help);
    await tester.pumpAndSettle();
    expect(chatOpens, 1);
    expect(session.view, BuyV2View.assist);
    expect(session.selectedOrder.id, 'PO-240783');
  });

  testWidgets('retired Assist deep link restores exact order Tracking', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = newSession();
    addTearDown(session.dispose);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MoolTheme.light(),
        home: BuyV2Screen(
          session: session,
          initialDestination: BuyV2Destination.orders,
          initialView: BuyV2View.assist,
          orderId: 'PO-240783',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(session.view, BuyV2View.tracking);
    expect(find.byKey(const PageStorageKey('buy-assist')), findsNothing);
    expect(session.selectedOrder.id, 'PO-240783');
    expect(find.textContaining('PO-240783'), findsOneWidget);
    expect(
      find.byKey(const PageStorageKey('buy-tracking-PO-240783')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('320px 140% retired Assist renders stable exact Tracking', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = newSession();
    addTearDown(session.dispose);
    expect(session.openTracking('RX-240784'), isTrue);
    session.openAssist();

    await tester.pumpWidget(app(session, textScale: 1.4, reducedMotion: true));
    await tester.pump();

    final tracking = find.byKey(const PageStorageKey('buy-tracking-RX-240784'));
    expect(tracking, findsOneWidget);
    expect(find.byKey(const PageStorageKey('buy-assist')), findsNothing);
    expect(find.textContaining('RX-240784'), findsOneWidget);
    expect(tester.getSize(tracking).width, lessThanOrEqualTo(320));
    expect(tester.takeException(), isNull);
  });

  testWidgets('R58.8.2 Assist responsive founder captures', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final viewport in const [
      (
        size: Size(320, 568),
        safe: EdgeInsets.symmetric(vertical: 24),
        textScale: 1.0,
        reduced: false,
        label: '320x568-android',
      ),
      (
        size: Size(360, 800),
        safe: EdgeInsets.symmetric(vertical: 24),
        textScale: 1.0,
        reduced: false,
        label: '360x800-android',
      ),
      (
        size: Size(390, 844),
        safe: EdgeInsets.only(top: 47, bottom: 34),
        textScale: 1.0,
        reduced: false,
        label: '390x844-ios',
      ),
      (
        size: Size(430, 932),
        safe: EdgeInsets.only(top: 59, bottom: 34),
        textScale: 1.0,
        reduced: false,
        label: '430x932-ios',
      ),
      (
        size: Size(320, 568),
        safe: EdgeInsets.symmetric(vertical: 24),
        textScale: 1.4,
        reduced: true,
        label: '320x568-a11y140-reduced',
      ),
    ]) {
      tester.view.physicalSize = viewport.size;
      final session = newSession();
      expect(session.openTracking('PO-240783'), isTrue);
      session.openAssist();
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: MoolTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: viewport.safe,
              viewPadding: viewport.safe,
              textScaler: TextScaler.linear(viewport.textScale),
              disableAnimations: viewport.reduced,
            ),
            child: child!,
          ),
          home: BuyV2Screen(
            session: session,
            initialDestination: session.destination,
            initialView: session.view,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('PO-240783'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('buy-v2-screen')),
        matchesGoldenFile(
          'candidate_captures/'
          'buy-v2-r58-8-2-order-assist-${viewport.label}.png',
        ),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      session.dispose();
    }
  }, skip: true);
}
