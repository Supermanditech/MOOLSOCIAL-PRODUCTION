import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_address_form_sheet_motion.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_views.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(
    BuyV2Session session, {
    bool disableAnimations = false,
    double textScale = 1,
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
          ),
          child: child!,
        );
      },
      home: Scaffold(
        body: Builder(
          builder: (context) => FilledButton(
            key: const ValueKey('open-address-choice'),
            onPressed: () => showBuyV2AddressSheet(context, session),
            child: const Text('Delivery addresses'),
          ),
        ),
      ),
    );
  }

  Future<void> openChoice(
    WidgetTester tester,
    BuyV2Session session, {
    bool disableAnimations = false,
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      app(session, disableAnimations: disableAnimations, textScale: textScale),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-address-choice')));
    await tester.pumpAndSettle();
  }

  Future<void> openRequest(
    WidgetTester tester,
    BuyV2Session session, {
    bool disableAnimations = false,
    double textScale = 1,
  }) async {
    await openChoice(
      tester,
      session,
      disableAnimations: disableAnimations,
      textScale: textScale,
    );
    final request = find.byKey(const ValueKey('buy-address-request'));
    await tester.scrollUntilVisible(
      request,
      120,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('buy-address-sheet-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(request);
    await tester.pumpAndSettle();
  }

  Future<void> openAdd(
    WidgetTester tester,
    BuyV2Session session, {
    bool disableAnimations = false,
    double textScale = 1,
  }) async {
    await openChoice(
      tester,
      session,
      disableAnimations: disableAnimations,
      textScale: textScale,
    );
    final add = find.byKey(const ValueKey('buy-address-add'));
    await tester.scrollUntilVisible(
      add,
      120,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('buy-address-sheet-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(add);
    await tester.pumpAndSettle();
  }

  Future<void> openEdit(
    WidgetTester tester,
    BuyV2Session session,
    String addressId,
  ) async {
    await openChoice(tester, session);
    await tester.tap(
      find.byKey(ValueKey<String>('buy-address-actions-$addressId')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(ValueKey<String>('buy-address-edit-$addressId')),
    );
    await tester.pumpAndSettle();
  }

  Future<void> enterCompleteAddress(WidgetTester tester) async {
    Future<void> enter(ValueKey<String> key, String value) async {
      final list = find.byKey(const ValueKey('buy-address-add-form-list'));
      final field = find.byKey(key);
      for (
        var attempt = 0;
        attempt < 10 && field.evaluate().isEmpty;
        attempt++
      ) {
        await tester.drag(list, const Offset(0, -220));
        await tester.pumpAndSettle();
      }
      expect(field, findsOneWidget);
      await tester.enterText(field, value);
    }

    await enter(const ValueKey('buy-address-add-recipient'), 'Meera Sharma');
    await enter(const ValueKey('buy-address-add-phone'), '9876543210');
    await enter(const ValueKey('buy-address-add-line'), '12 Market Road');
    await enter(const ValueKey('buy-address-add-area'), 'Jodhpur');
    await enter(const ValueKey('buy-address-add-pin'), '342001');
    await enter(const ValueKey('buy-address-add-landmark'), 'Near market gate');
  }

  Future<Finder> revealInForm(
    WidgetTester tester, {
    required ValueKey<String> listKey,
    required ValueKey<String> targetKey,
  }) async {
    final list = find.byKey(listKey);
    final target = find.byKey(targetKey);
    for (
      var attempt = 0;
      attempt < 10 && target.evaluate().isEmpty;
      attempt++
    ) {
      await tester.drag(list, const Offset(0, -220));
      await tester.pumpAndSettle();
    }
    expect(target, findsOneWidget);
    return target;
  }

  Future<void> expectNamedEditableField(
    WidgetTester tester,
    String label,
  ) async {
    final field = find.bySemanticsLabel(label);
    expect(
      field,
      findsOneWidget,
      reason: '$label must have one semantics owner',
    );
    final initial = tester.getSemantics(field).getSemanticsData();
    expect(initial.flagsCollection.isTextField, isTrue);
    expect(initial.hasAction(SemanticsAction.focus), isTrue);
    expect(initial.hasAction(SemanticsAction.tap), isTrue);
    await tester.ensureVisible(field);
    await tester.tap(field);
    await tester.pump();
    final focused = tester.getSemantics(field).getSemanticsData();
    expect(focused.hasAction(SemanticsAction.setText), isTrue);
  }

  testWidgets('R56.10 form policy is finite and reduced motion is static', (
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
                  normal = BuyV2AddressFormSheetMotion.resolve(context);
                  return const SizedBox.shrink();
                },
              ),
            ),
            MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: Builder(
                builder: (context) {
                  reduced = BuyV2AddressFormSheetMotion.resolve(context);
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

  testWidgets('request route is named, styled and natively actionable', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await openRequest(tester, session);

    final route = find.byKey(const ValueKey('buy-address-request-form-route'));
    expect(tester.getSemantics(route).label, 'Request an address');
    expect(
      tester
          .getSize(find.byKey(const ValueKey('buy-address-request-form-close')))
          .height,
      greaterThanOrEqualTo(44),
    );
    final share = tester.getSemantics(
      find.byKey(const ValueKey('buy-address-request-device-share')),
    );
    expect(share.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    await expectNamedEditableField(tester, 'Recipient name (optional)');
    expect(find.text('Helps you confirm who the request is for.'), findsOne);
    tester.testTextInput.hide();
    await tester.pump();
    expect(tester.testTextInput.isVisible, isFalse);
    semantics.dispose();
  });

  testWidgets('request Back and Close preserve address ownership', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession())..chooseAddress('work');
    addTearDown(session.dispose);
    await openRequest(tester, session);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(session.selectedAddressId, 'work');
    expect(find.byKey(const ValueKey('buy-address-sheet-route')), findsOne);

    await tester.tap(find.byKey(const ValueKey('buy-address-request')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('buy-address-request-form-close')),
    );
    await tester.pumpAndSettle();
    expect(session.selectedAddressId, 'work');
    expect(find.byKey(const ValueKey('buy-address-sheet-route')), findsOne);
  });

  testWidgets(
    'request copies only the established link and stays recoverable',
    (tester) async {
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);
      await openRequest(tester, session);
      String? copiedText;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedText =
                (call.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('buy-address-request-recipient')),
        'Meera',
      );
      await tester.tap(find.byKey(const ValueKey('buy-address-request-copy')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(copiedText, 'https://moolsocial.com/address/request');
      expect(find.text('Address request link copied'), findsOne);
      expect(
        find.byKey(const ValueKey('buy-address-request-form-route')),
        findsOne,
      );
      expect(find.byKey(const ValueKey('buy-address-sheet-route')), findsOne);
      expect(session.selectedAddressId, 'home');
    },
  );

  testWidgets('manual entry nests and Back restores the request form', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await openRequest(tester, session);

    await tester.tap(
      find.byKey(const ValueKey('buy-address-request-enter-manually')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-address-add-form-route')), findsOne);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-address-request-form-route')),
      findsOne,
    );
    expect(session.selectedAddressId, 'home');
  });

  testWidgets('add route validates only complete local form state', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    final before = session.addresses.length;
    await openAdd(tester, session);

    for (final label in const [
      'Recipient name',
      '10-digit phone number',
      'House, building and street',
      'Area or locality',
      '6-digit PIN code',
      'Nearby landmark (optional)',
    ]) {
      await expectNamedEditableField(tester, label);
    }

    final submit = await revealInForm(
      tester,
      listKey: const ValueKey('buy-address-add-form-list'),
      targetKey: const ValueKey('buy-address-add-submit'),
    );
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-address-add-validation')), findsOne);
    expect(
      find.text('Add the recipient, street address and locality.'),
      findsOne,
    );
    expect(session.addresses.length, before);
    expect(session.selectedAddressId, 'home');
  });

  testWidgets('phone and PIN validation recover in place', (tester) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await openAdd(tester, session);

    await tester.enterText(
      find.byKey(const ValueKey('buy-address-add-recipient')),
      'Meera Sharma',
    );
    await tester.enterText(
      find.byKey(const ValueKey('buy-address-add-line')),
      '12 Market Road',
    );
    await tester.enterText(
      find.byKey(const ValueKey('buy-address-add-area')),
      'Jodhpur',
    );
    await tester.enterText(
      find.byKey(const ValueKey('buy-address-add-phone')),
      '123',
    );
    await tester.enterText(
      find.byKey(const ValueKey('buy-address-add-pin')),
      '12',
    );
    final submit = await revealInForm(
      tester,
      listKey: const ValueKey('buy-address-add-form-list'),
      targetKey: const ValueKey('buy-address-add-submit'),
    );
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('Enter a 10-digit phone number.'), findsOne);

    await tester.enterText(
      find.byKey(const ValueKey('buy-address-add-phone')),
      '9876543210',
    );
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid 6-digit PIN code.'), findsOne);
    expect(find.byKey(const ValueKey('buy-address-add-form-route')), findsOne);
    expect(session.addresses.length, 2);
  });

  testWidgets('Home and Work edits are prefilled and Back restores choice', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    final homeBefore = session.addresses.firstWhere(
      (address) => address.id == 'home',
    );
    final workBefore = session.addresses.firstWhere(
      (address) => address.id == 'work',
    );

    await openEdit(tester, session, 'home');
    expect(find.text('Edit Home address'), findsOne);
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('buy-address-add-recipient')),
          )
          .controller!
          .text,
      homeBefore.recipient,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-address-sheet-route')), findsOne);

    await tester.tap(find.byKey(const ValueKey('buy-address-actions-work')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-address-edit-work')));
    await tester.pumpAndSettle();
    expect(find.text('Edit Work address'), findsOne);
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('buy-address-add-recipient')),
          )
          .controller!
          .text,
      workBefore.recipient,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(session.selectedAddressId, 'home');
    expect(session.addresses.firstWhere((a) => a.id == 'home'), homeBefore);
    expect(session.addresses.firstWhere((a) => a.id == 'work'), workBefore);
  });

  testWidgets('saving an edit updates once and preserves selection', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    final before = session.addresses.length;
    await openEdit(tester, session, 'home');

    await tester.enterText(
      find.byKey(const ValueKey('buy-address-add-recipient')),
      'Asha Verma',
    );
    final submit = await revealInForm(
      tester,
      listKey: const ValueKey('buy-address-add-form-list'),
      targetKey: const ValueKey('buy-address-add-submit'),
    );
    expect(find.text('Save changes'), findsOne);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(session.addresses.length, before);
    expect(session.selectedAddressId, 'home');
    expect(
      session.addresses.firstWhere((address) => address.id == 'home').recipient,
      'Asha Verma',
    );
    expect(
      find.byKey(const ValueKey('buy-address-add-form-route')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('buy-address-sheet-route')), findsNothing);
  });

  testWidgets('address removal confirms and leaves existing orders unchanged', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    final orderCount = session.orders.length;
    await openChoice(tester, session);

    await tester.tap(find.byKey(const ValueKey('buy-address-actions-work')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-address-delete-work')));
    await tester.pumpAndSettle();
    expect(find.text('Remove Work address?'), findsOne);
    await tester.tap(find.byKey(const ValueKey('buy-address-delete-cancel')));
    await tester.pumpAndSettle();
    expect(session.addresses.any((address) => address.id == 'work'), isTrue);

    await tester.tap(find.byKey(const ValueKey('buy-address-actions-work')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-address-delete-work')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-address-delete-confirm')));
    await tester.pumpAndSettle();

    expect(session.addresses.any((address) => address.id == 'work'), isFalse);
    expect(session.orders.length, orderCount);
    expect(find.byKey(const ValueKey('buy-address-sheet-route')), findsNothing);
  });

  testWidgets('manual address form is truthful and provider-neutral', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await openAdd(tester, session);

    expect(
      find.text(
        'Enter the complete address below. You can review it before placing the order.',
      ),
      findsOne,
    );
    expect(find.byKey(const ValueKey('buy-address-add-current')), findsNothing);
    expect(find.byKey(const ValueKey('buy-address-add-map-pin')), findsNothing);
    expect(find.byKey(const ValueKey('buy-address-add-google')), findsNothing);
    final pin = tester.widget<TextField>(
      find.byKey(const ValueKey('buy-address-add-pin')),
    );
    final area = tester.widget<TextField>(
      find.byKey(const ValueKey('buy-address-add-area')),
    );
    expect(pin.controller!.text, isEmpty);
    expect(area.controller!.text, isEmpty);
    expect(find.textContaining('not connected'), findsNothing);
  });

  testWidgets('complete add changes the existing session owner once', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    final before = session.addresses.length;
    await openAdd(tester, session);
    await tester.tap(
      find.byKey(const ValueKey('buy-address-add-kind-Other place')),
    );
    await tester.pump();
    await enterCompleteAddress(tester);
    await tester.enterText(
      find.byKey(const ValueKey('buy-address-add-landmark')),
      '',
    );
    final submit = await revealInForm(
      tester,
      listKey: const ValueKey('buy-address-add-form-list'),
      targetKey: const ValueKey('buy-address-add-submit'),
    );
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(session.addresses.length, before + 1);
    expect(session.selectedAddress.label, 'Other place');
    expect(session.selectedAddress.recipient, 'Meera Sharma');
    expect(session.selectedAddress.landmark, 'No nearby landmark');
    expect(
      find.byKey(const ValueKey('buy-address-add-form-route')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('buy-address-sheet-route')), findsNothing);
  });

  testWidgets('stale session owner rejects a completed add', (tester) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    final before = session.addresses.length;
    await openAdd(tester, session);
    session.chooseAddress('work');
    await enterCompleteAddress(tester);
    final submit = await revealInForm(
      tester,
      listKey: const ValueKey('buy-address-add-form-list'),
      targetKey: const ValueKey('buy-address-add-submit'),
    );
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(session.addresses.length, before);
    expect(session.selectedAddressId, 'work');
    expect(
      find.text(
        'The delivery session changed. Review the address before saving.',
      ),
      findsOne,
    );
  });

  testWidgets(
    'add focus owns the keyboard and form Back remains deterministic',
    (tester) async {
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);
      await openAdd(tester, session);

      await tester.tap(find.byKey(const ValueKey('buy-address-add-recipient')));
      await tester.pump();
      expect(tester.testTextInput.isVisible, isTrue);
      tester.testTextInput.hide();
      await tester.pump();
      expect(
        find.byKey(const ValueKey('buy-address-add-form-route')),
        findsOne,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-address-sheet-route')), findsOne);
      expect(session.selectedAddressId, 'home');
    },
  );

  testWidgets('compact 140 percent keeps both primary form actions reachable', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await openRequest(tester, session, textScale: 1.4);

    final manual = await revealInForm(
      tester,
      listKey: const ValueKey('buy-address-request-form-list'),
      targetKey: const ValueKey('buy-address-request-enter-manually'),
    );
    expect(tester.getSize(manual).height, greaterThanOrEqualTo(44));
    await tester.tap(manual);
    await tester.pumpAndSettle();

    final submit = await revealInForm(
      tester,
      listKey: const ValueKey('buy-address-add-form-list'),
      targetKey: const ValueKey('buy-address-add-submit'),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(submit).height, greaterThanOrEqualTo(44));
    expect(tester.getBottomRight(submit).dy, lessThanOrEqualTo(676));
    expect(tester.takeException(), isNull);
  });

  testWidgets('R56.10 request/add responsive evidence captures', (
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
      await openRequest(
        tester,
        session,
        disableAnimations: capture.$3,
        textScale: capture.$2,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'candidate_captures/buy-v2-r61-6-shop-address-request-${capture.$4}.png',
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey('buy-address-request-enter-manually')),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'candidate_captures/buy-v2-r61-6-shop-address-add-${capture.$4}.png',
        ),
      );
      session.dispose();
    }
    tester.view.reset();
  }, skip: true);
}
