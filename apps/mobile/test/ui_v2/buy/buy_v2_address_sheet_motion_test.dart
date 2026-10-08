import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

class _AddressHoldSession extends BuyV2Session {
  _AddressHoldSession(BuySession core) : super(core: core);
  bool held = false;
  @override
  bool get cartChangesBlocked => held || super.cartChangesBlocked;
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

  for (final scale in [1.0, 2.0]) {
    for (final save in [false, true]) {
      testWidgets('T14 Profile address Cart return $scale save=$save', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.reset);
        final core = BuySession();
        final session = BuyV2Session(core: core);
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        for (final address in List<BuyV2Address>.of(session.addresses)) {
          expect(session.removeAddress(address.id), isTrue);
        }
        final product = BuyV2Catalogue.products.firstWhere(
          (p) => p.destination == BuyV2Destination.shop,
        );
        expect(session.addProduct(product.id), isTrue);
        session.openCart();
        final quantities = session.quantityFor(product.id);
        final total = session.cartTotal;
        final scope = session.cartScope;
        final filter = session.cartDisplayFilter;
        await tester.pumpWidget(
          app(
            session,
            textScale: scale,
            home: Scaffold(
              body: AnimatedBuilder(
                animation: session,
                builder: (context, _) => session.view == BuyV2View.account
                    ? BuyV2AccountView(session: session)
                    : BuyV2CartView(session: session, onBrowseMore: () {}),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final entry = find.byKey(const ValueKey('buy-cart-profile-address'));
        await tester.ensureVisible(entry);
        await tester.tap(entry);
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.account);
        expect(
          find.byKey(const ValueKey('buy-address-add-form-route')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('buy-address-sheet-route')),
          findsNothing,
        );
        if (save) {
          final submit = find.byKey(const ValueKey('buy-address-add-submit'));
          final formScroll = find
              .descendant(
                of: find.byKey(const ValueKey('buy-address-add-form-list')),
                matching: find.byType(Scrollable),
              )
              .first;
          await tester.scrollUntilVisible(submit, 180, scrollable: formScroll);
          await tester.tap(submit);
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('buy-address-add-validation')),
            findsOneWidget,
          );
          expect(session.addresses, isEmpty);
          tester.state<ScrollableState>(formScroll).position.jumpTo(0);
          await tester.pumpAndSettle();
          for (final entry in {
            'recipient': 'Buyer',
            'phone': '9876543210',
            'line': '12 Market Road',
            'area': 'Jodhpur',
            'pin': '342001',
          }.entries) {
            final field = find.byKey(ValueKey('buy-address-add-${entry.key}'));
            await tester.scrollUntilVisible(field, 180, scrollable: formScroll);
            await tester.enterText(field, entry.value);
            await tester.pumpAndSettle();
          }
          await tester.scrollUntilVisible(submit, 180, scrollable: formScroll);
          await tester.tap(submit);
        } else {
          await tester.tap(
            find.byKey(const ValueKey('buy-address-add-form-close')),
          );
        }
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.cart);
        expect(session.selectedAddressOrNull != null, save);
        expect(session.quantityFor(product.id), quantities);
        expect(session.cartTotal, total);
        expect(session.cartScope, scope);
        expect(session.cartDisplayFilter, filter);
        expect(
          session.checkoutSubmissionState,
          BuyV2CheckoutSubmissionState.idle,
        );
        expect(
          find.byKey(const ValueKey('buy-address-add-form-route')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  testWidgets('T14 empty Profile opens shared address form directly', (
    tester,
  ) async {
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    for (final address in List<BuyV2Address>.of(session.addresses)) {
      session.removeAddress(address.id);
    }
    session.openAccount();
    await tester.pumpWidget(
      app(
        session,
        home: Scaffold(body: BuyV2AccountView(session: session)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('buy-profile-address-management')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-address-add-form-route')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('buy-address-sheet-route')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('buy-address-add-form-close')));
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.account);
    expect(session.addresses, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final guard in ['payment', 'navigation']) {
    testWidgets('T14 Profile address rejects stale $guard save', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final core = BuySession();
      final session = _AddressHoldSession(core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      for (final address in List<BuyV2Address>.of(session.addresses)) {
        session.removeAddress(address.id);
      }
      final product = BuyV2Catalogue.products.firstWhere(
        (p) => p.destination == BuyV2Destination.shop,
      );
      session.addProduct(product.id);
      session.openCart();
      final total = session.cartTotal;
      await tester.pumpWidget(
        app(
          session,
          home: Scaffold(
            body: AnimatedBuilder(
              animation: session,
              builder: (context, _) => session.view == BuyV2View.account
                  ? BuyV2AccountView(session: session)
                  : BuyV2CartView(session: session, onBrowseMore: () {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-cart-profile-address')));
      await tester.pumpAndSettle();
      final formScroll = find
          .descendant(
            of: find.byKey(const ValueKey('buy-address-add-form-list')),
            matching: find.byType(Scrollable),
          )
          .first;
      for (final entry in {
        'recipient': 'Buyer',
        'phone': '9876543210',
        'line': '12 Market Road',
        'area': 'Jodhpur',
        'pin': '342001',
      }.entries) {
        final field = find.byKey(ValueKey('buy-address-add-${entry.key}'));
        await tester.scrollUntilVisible(field, 180, scrollable: formScroll);
        await tester.enterText(field, entry.value);
        await tester.pumpAndSettle();
      }
      if (guard == 'payment') {
        session.held = true;
      } else {
        session.closeAccount();
        session.openAccount();
      }
      final submit = find.byKey(const ValueKey('buy-address-add-submit'));
      await tester.scrollUntilVisible(submit, 180, scrollable: formScroll);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-address-add-form-route')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('buy-address-add-validation')),
        findsOneWidget,
      );
      expect(session.addresses, isEmpty);
      if (guard == 'payment') {
        expect(
          find.text(
            'Review the existing payment before changing your address.',
          ),
          findsOneWidget,
        );
      }
      await tester.tap(
        find.byKey(const ValueKey('buy-address-add-form-close')),
      );
      await tester.pumpAndSettle();
      expect(
        session.view,
        guard == 'payment' ? BuyV2View.cart : BuyV2View.account,
      );
      expect(session.quantityFor(product.id), 1);
      expect(session.cartTotal, total);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

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
    final summary = find.byKey(const ValueKey('buy-checkout-confirm-address'));
    expect(summary, findsOneWidget);
    await tester.tap(
      find.descendant(of: summary, matching: find.text('Change')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('buy-checkout-address-edit-home')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-address-add-form-route')), findsOne);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'T14 separate address Edit action preserves selection at $scale text',
      (tester) async {
        final handle = tester.ensureSemantics();
        final core = BuySession();
        final session = BuyV2Session(core: core);
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        expect(session.addProduct('s-tomato'), isTrue);
        session.openCart();
        expect(session.openCheckout(), isTrue);
        final selected = session.selectedAddressId;
        final total = session.checkoutTotal;
        final invoice = BuyV2GstInvoiceController();
        addTearDown(invoice.dispose);
        await tester.pumpWidget(
          app(
            session,
            textScale: scale,
            disableAnimations: true,
            home: Scaffold(
              body: BuyV2CheckoutView(
                session: session,
                gstInvoiceController: invoice,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final summary = find.byKey(
          const ValueKey('buy-checkout-confirm-address'),
        );
        await tester.tap(
          find.descendant(of: summary, matching: find.text('Change')),
        );
        await tester.pumpAndSettle();
        final edit = find.bySemanticsLabel('Edit Work address');
        final add = find.byKey(const ValueKey('buy-checkout-add-address'));
        final cancel = find.byKey(
          const ValueKey('buy-checkout-address-cancel'),
        );
        expect(
          tester.getTopLeft(cancel).dy,
          lessThan(tester.getTopLeft(edit).dy),
        );
        if (scale == 1.0) {
          expect(
            tester
                .getSize(
                  find.byKey(const ValueKey('buy-checkout-address-home')),
                )
                .height,
            lessThanOrEqualTo(72),
          );
        }
        expect(tester.getSize(add).height, greaterThanOrEqualTo(44));
        expect(
          tester
              .getRect(add)
              .overlaps(tester.getRect(find.text('Delivery address'))),
          isFalse,
        );
        expect(tester.getTopLeft(add).dy, lessThan(tester.getTopLeft(edit).dy));
        await tester.tap(add);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('buy-address-add-form-route')),
          findsOneWidget,
        );
        await tester.tap(
          find.byKey(const ValueKey('buy-address-add-form-close')),
        );
        await tester.pumpAndSettle();
        expect(session.selectedAddressId, selected);
        expect(session.quantityFor('s-tomato'), 1);
        expect(session.checkoutTotal, total);
        expect(edit, findsOneWidget);
        expect(find.bySemanticsLabel('Edit Home address'), findsOneWidget);
        await tester.ensureVisible(edit);
        await tester.pumpAndSettle();
        final node = tester.getSemantics(edit);
        final select = tester.getSemantics(
          find.byKey(const ValueKey('buy-checkout-address-work')),
        );
        expect(node.id, isNot(select.id));
        expect(node.rect.width, lessThan(select.rect.width));
        expect(select.flagsCollection.isSelected, Tristate.isFalse);
        expect(node.flagsCollection.isButton, isTrue);
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
        expect(tester.getSize(edit).height, greaterThanOrEqualTo(44));
        node.owner!.performAction(node.id, SemanticsAction.tap);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('buy-address-add-form-route')),
          findsOneWidget,
        );
        expect(session.selectedAddressId, selected);
        expect(session.quantityFor('s-tomato'), 1);
        expect(session.checkoutTotal, total);
        await tester.tap(
          find.byKey(const ValueKey('buy-address-add-form-close')),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('buy-address-add-form-route')),
          findsNothing,
        );
        expect(session.selectedAddressId, selected);
        expect(session.quantityFor('s-tomato'), 1);
        expect(session.checkoutTotal, total);
        expect(tester.takeException(), isNull);
        handle.dispose();
      },
    );
  }

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
      greaterThanOrEqualTo(44),
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

  for (final scenario in [
    (360.0, 1.0),
    (360.0, 2.0),
    (332.0, 1.33),
    (331.0, 1.0),
  ]) {
    final scale = scenario.$2;
    testWidgets(
      'Compact address actions and direct Edit preserve Cart at ${scenario.$1}/$scale',
      (tester) async {
        tester.view.physicalSize = Size(scenario.$1, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final session = BuyV2Session(core: BuySession());
        addTearDown(session.dispose);
        session.addProduct('s-tomato');
        final originalAddress = session.selectedAddressId;
        await openSheet(tester, session, textScale: scale);
        final add = find.byKey(const ValueKey('buy-address-add'));
        final request = find.byKey(const ValueKey('buy-address-request'));
        final scrollable = find.descendant(
          of: find.byKey(const ValueKey('buy-address-sheet-list')),
          matching: find.byType(Scrollable),
        );
        await tester.scrollUntilVisible(request, 100, scrollable: scrollable);
        await tester.pumpAndSettle();
        final addRect = tester.getRect(add);
        final requestRect = tester.getRect(request);
        expect(addRect.height, greaterThanOrEqualTo(44));
        expect(requestRect.height, greaterThanOrEqualTo(44));
        if (scale == 1.0 && scenario.$1 == 360) {
          expect(addRect.top, requestRect.top);
          expect(addRect.right, lessThan(requestRect.left));
        } else {
          expect(addRect.left, requestRect.left);
          expect(addRect.bottom, lessThan(requestRect.top));
        }
        final edit = find.byKey(const ValueKey('buy-address-direct-edit-home'));
        await tester.scrollUntilVisible(edit, -100, scrollable: scrollable);
        await tester.ensureVisible(edit);
        await tester.pumpAndSettle();
        await tester.tap(edit);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('buy-address-add-form-route')),
          findsOneWidget,
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(session.selectedAddressId, originalAddress);
        expect(session.quantityFor('s-tomato'), 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

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

  for (final scale in [1.0, 2.0]) {
    testWidgets('A05 complete address and recovery at $scale', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);
      final product = BuyV2Catalogue.products.firstWhere(
        (item) => item.destination == BuyV2Destination.shop,
      );
      expect(session.addProduct(product.id), isTrue);
      final quantity = session.quantityFor(product.id);
      await openSheet(tester, session, textScale: scale);

      final work = session.addresses.firstWhere((item) => item.id == 'work');
      final fullAddress = find.text(
        '${work.line}, ${work.shortLine} · ${work.landmark}',
      );
      await tester.scrollUntilVisible(
        fullAddress,
        100,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('buy-address-sheet-list')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      final paragraph = tester.renderObject<RenderParagraph>(fullAddress);
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(paragraph.text.toPlainText(), contains(work.pinCode));
      expect(paragraph.text.toPlainText(), contains(work.landmark));
      expect(tester.takeException(), isNull);

      final choice = find.byKey(const ValueKey('buy-address-work'));
      await tester.ensureVisible(choice);
      await tester.pumpAndSettle();
      await tester.tap(choice);
      await tester.pumpAndSettle();
      expect(session.selectedAddressId, 'work');
      expect(session.quantityFor(product.id), quantity);

      await tester.tap(find.byKey(const ValueKey('open-address-sheet')));
      await tester.pumpAndSettle();
      final manage = find.byKey(const ValueKey('buy-address-actions-work'));
      await tester.scrollUntilVisible(
        manage,
        100,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('buy-address-sheet-list')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(manage);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-address-edit-work')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-address-add-form-route')),
        findsOne,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(session.selectedAddressId, 'work');
      expect(session.quantityFor(product.id), quantity);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-address-sheet-route')),
        findsNothing,
      );
      expect(session.selectedAddressId, 'work');
      expect(session.quantityFor(product.id), quantity);
      expect(tester.takeException(), isNull);
    });
  }

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
