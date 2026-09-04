import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_address_sheet_motion.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_views.dart';

class _EmptyAddressSession extends BuyV2Session {
  _EmptyAddressSession() : super(core: BuySession());

  @override
  List<BuyV2Address> get addresses => const [];

  @override
  String? get selectedAddressId => null;
}

class _AddressRemovalSession extends BuyV2Session {
  _AddressRemovalSession() : super(core: BuySession());

  bool exposeWork = true;

  @override
  List<BuyV2Address> get addresses => exposeWork
      ? super.addresses
      : super.addresses.where((address) => address.id != 'work').toList();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(
    BuyV2Session session, {
    bool disableAnimations = false,
    double textScale = 1,
    double bottomViewPadding = 0,
    double bottomViewportExclusion = 0,
    Widget? home,
  }) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: MoolTheme.light(),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            disableAnimations: disableAnimations,
            textScaler: TextScaler.linear(textScale),
            size: Size(
              media.size.width,
              media.size.height - bottomViewportExclusion,
            ),
            padding: EdgeInsets.only(bottom: bottomViewPadding),
            viewPadding: EdgeInsets.only(bottom: bottomViewPadding),
          ),
          child: child!,
        );
      },
      home:
          home ??
          Scaffold(
            body: Builder(
              builder: (context) => FilledButton(
                key: const ValueKey('open-address-sheet'),
                onPressed: () => showBuyV2AddressSheet(context, session),
                child: const Text('Delivery addresses'),
              ),
            ),
          ),
    );
  }

  Future<void> openSheet(
    WidgetTester tester,
    BuyV2Session session, {
    bool disableAnimations = false,
    double textScale = 1,
    double bottomViewPadding = 0,
    double bottomViewportExclusion = 0,
    bool settle = true,
  }) async {
    await tester.pumpWidget(
      app(
        session,
        disableAnimations: disableAnimations,
        textScale: textScale,
        bottomViewPadding: bottomViewPadding,
        bottomViewportExclusion: bottomViewportExclusion,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-address-sheet')));
    await tester.pump();
    if (settle) await tester.pumpAndSettle();
  }

  testWidgets('R56.9 route policy is finite and reduced motion is static', (
    tester,
  ) async {
    late AnimationStyle normal;
    late AnimationStyle reduced;
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            MediaQuery(
              data: const MediaQueryData(),
              child: Builder(
                builder: (context) {
                  normal = BuyV2AddressSheetMotion.resolve(context);
                  return const SizedBox.shrink();
                },
              ),
            ),
            MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: Builder(
                builder: (context) {
                  reduced = BuyV2AddressSheetMotion.resolve(context);
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );

    expect(normal.duration, const Duration(milliseconds: 280));
    expect(normal.reverseDuration, const Duration(milliseconds: 220));
    expect(normal.curve, Curves.easeOutBack);
    expect(normal.reverseCurve, Curves.easeInCubic);
    expect(reduced.duration, Duration.zero);
    expect(reduced.reverseDuration, Duration.zero);
    expect(reduced.curve, Curves.linear);
    expect(reduced.reverseCurve, Curves.linear);
  });

  testWidgets('Account retains its sheet and Checkout embeds address editing', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    session.openAccount();

    await tester.pumpWidget(
      app(
        session,
        home: Scaffold(body: BuyV2AccountView(session: session)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-address-sheet-route')), findsOne);
    await tester.tap(find.byKey(const ValueKey('buy-address-close')));
    await tester.pumpAndSettle();

    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    session.closeAccount();
    session.addProduct(product.id);
    session.openCart();
    expect(session.openCheckout(), isTrue);
    await tester.pumpWidget(
      app(
        session,
        home: Scaffold(
          body: BuyV2CheckoutView(
            session: session,
            gstInvoiceController: BuyV2GstInvoiceController(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('buy-checkout-address-edit-home')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-address-add-form-route')), findsOne);
  });

  testWidgets('selection commits once only after the reverse route', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await openSheet(tester, session);

    await tester.tap(find.byKey(const ValueKey('buy-address-work')));
    await tester.pump();
    expect(session.selectedAddressId, 'home');
    await tester.pump(const Duration(milliseconds: 219));
    expect(session.selectedAddressId, 'home');
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(session.selectedAddressId, 'work');
    expect(find.byKey(const ValueKey('buy-address-sheet-route')), findsNothing);
  });

  testWidgets('Back, Close and lifecycle preserve the existing address', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession())..chooseAddress('work');
    addTearDown(session.dispose);
    await openSheet(tester, session);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(session.selectedAddressId, 'work');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(session.selectedAddressId, 'work');

    await tester.tap(find.byKey(const ValueKey('open-address-sheet')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-address-close')));
    await tester.pumpAndSettle();
    expect(session.selectedAddressId, 'work');
  });

  testWidgets('new owner or stale id cannot receive an address choice', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await openSheet(tester, session);

    session.chooseAddress('work');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('buy-address-home')));
    await tester.pumpAndSettle();
    expect(session.selectedAddressId, 'work');

    final removalSession = _AddressRemovalSession();
    addTearDown(removalSession.dispose);
    await openSheet(tester, removalSession);
    removalSession.exposeWork = false;
    await tester.tap(find.byKey(const ValueKey('buy-address-work')));
    await tester.pumpAndSettle();
    expect(removalSession.selectedAddressId, 'home');
  });

  testWidgets('named route and selected address expose one semantic owner', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await openSheet(tester, session);

    final route = find.byKey(const ValueKey('buy-address-sheet-route'));
    expect(tester.getSemantics(route).label, 'Delivery addresses');
    final selected = tester.getSemantics(
      find.byKey(const ValueKey('buy-address-semantics-home')),
    );
    expect(selected.label, contains('Home, selected'));
    expect(selected.flagsCollection.isButton, isTrue);
    expect(selected.flagsCollection.isSelected, Tristate.isTrue);
    expect(selected.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    expect(
      find.byKey(const ValueKey('buy-address-selected-home')),
      findsOneWidget,
    );
    final manage = tester.getSemantics(
      find.byKey(const ValueKey('buy-address-actions-home')),
    );
    expect(manage.label, contains('Manage Home address'));
    expect(manage.flagsCollection.isButton, isTrue);
    expect(manage.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    expect(
      tester.getSize(find.byKey(const ValueKey('buy-address-home'))).height,
      greaterThanOrEqualTo(76),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('buy-address-close'))).height,
      greaterThanOrEqualTo(44),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('buy-address-actions-home'))),
      const Size(48, 48),
    );
    semantics.dispose();
  });

  testWidgets('actual empty owner is honest and keeps existing recovery', (
    tester,
  ) async {
    final session = _EmptyAddressSession();
    addTearDown(session.dispose);
    await openSheet(tester, session);

    expect(find.byKey(const ValueKey('buy-address-empty')), findsOne);
    expect(find.text('No saved addresses'), findsOne);
    expect(find.byKey(const ValueKey('buy-address-home')), findsNothing);
    expect(find.byKey(const ValueKey('buy-address-request')), findsOne);
    expect(find.byKey(const ValueKey('buy-address-add')), findsOne);
    expect(find.byType(EditableText), findsNothing);
  });

  testWidgets('R56.10 form entry remains separate and does not select', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await openSheet(tester, session);

    await tester.tap(find.byKey(const ValueKey('buy-address-request')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('buy-address-request-form-route')),
        matching: find.text('Request an address'),
      ),
      findsOne,
    );
    expect(find.byKey(const ValueKey('buy-address-sheet-route')), findsOne);
    expect(session.selectedAddressId, 'home');
  });

  testWidgets('compact 140 percent keeps address recovery reachable', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await openSheet(tester, session, textScale: 1.4);

    final target = find.byKey(const ValueKey('buy-address-add'));
    await tester.scrollUntilVisible(
      target,
      120,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('buy-address-sheet-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    expect(target, findsOneWidget);
    expect(tester.getSize(target).height, greaterThanOrEqualTo(44));
    expect(tester.takeException(), isNull);
  });

  testWidgets('bottom navigation inset keeps Add fully above the safe edge', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await openSheet(tester, session, bottomViewportExclusion: 34);

    final add = find.byKey(const ValueKey('buy-address-add'));
    expect(tester.getSize(add).height, greaterThanOrEqualTo(44));
    expect(tester.getBottomRight(add).dy, lessThanOrEqualTo(766));
    expect(tester.takeException(), isNull);
  });

  testWidgets('zero reported inset retains the bounded safe fallback', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await openSheet(tester, session);

    final add = find.byKey(const ValueKey('buy-address-add'));
    expect(tester.getSize(add).height, greaterThanOrEqualTo(44));
    expect(tester.getBottomRight(add).dy, lessThanOrEqualTo(776));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion applies and selection resolves immediately', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await openSheet(tester, session, disableAnimations: true, settle: false);
    expect(find.byKey(const ValueKey('buy-address-sheet-route')), findsOne);

    await tester.tap(find.byKey(const ValueKey('buy-address-work')));
    await tester.pump();
    await tester.pump();
    expect(session.selectedAddressId, 'work');
    expect(find.byKey(const ValueKey('buy-address-sheet-route')), findsNothing);
  });

  testWidgets('R56.9 address-sheet responsive evidence captures', (
    tester,
  ) async {
    const cases = [
      (Size(320, 700), 1.4, false, 'compact-320x700-text140'),
      (Size(360, 800), 1.0, false, 'android-360x800'),
      (Size(390, 844), 1.0, false, 'ios-390x844'),
      (Size(390, 844), 1.0, true, 'reduced-ios-390x844'),
    ];
    for (final capture in cases) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = capture.$1;
      final session = BuyV2Session(core: BuySession());
      await openSheet(
        tester,
        session,
        disableAnimations: capture.$3,
        textScale: capture.$2,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'candidate_captures/buy-v2-r61-6-shop-address-${capture.$4}.png',
        ),
      );
      session.dispose();
    }
    tester.view.reset();
  }, skip: true);
}
