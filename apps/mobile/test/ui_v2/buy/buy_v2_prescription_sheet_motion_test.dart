import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_catalogue.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_prescription_sheet_motion.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_views.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(
    BuyV2Session session, {
    bool disableAnimations = false,
    double textScale = 1,
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
          ),
          child: child!,
        );
      },
      home:
          home ??
          Scaffold(
            body: Builder(
              builder: (context) => FilledButton(
                key: const ValueKey('open-prescription-sheet'),
                onPressed: () => showBuyV2PrescriptionSheet(context, session),
                child: const Text('Prescription centre'),
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
    bool settle = true,
  }) async {
    await tester.pumpWidget(
      app(session, disableAnimations: disableAnimations, textScale: textScale),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-prescription-sheet')));
    await tester.pump();
    if (settle) await tester.pumpAndSettle();
  }

  testWidgets('R56.8 route policy is finite and reduced motion is static', (
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
                  normal = BuyV2PrescriptionSheetMotion.resolve(context);
                  return const SizedBox.shrink();
                },
              ),
            ),
            MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: Builder(
                builder: (context) {
                  reduced = BuyV2PrescriptionSheetMotion.resolve(context);
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

  testWidgets('real Account caller reaches the R56.8 sheet', (tester) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await tester.pumpWidget(
      app(
        session,
        home: Scaffold(body: BuyV2AccountView(session: session)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-account-prescriptions')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('buy-prescription-sheet-route')),
      findsOne,
    );
    expect(find.text('Add your prescription'), findsOne);
  });

  testWidgets('real Medicine caller is honest and reaches the same sheet', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession())
      ..openDestination(BuyV2Destination.medicine);
    addTearDown(session.dispose);
    await tester.pumpWidget(
      app(
        session,
        home: Scaffold(body: BuyV2CatalogueView(session: session)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add or use a saved prescription'), findsOne);
    expect(find.textContaining('Upload'), findsNothing);
    await tester.tap(
      find.byKey(const ValueKey('buy-promotion-medicine-prescription')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('buy-prescription-sheet-route')),
      findsOne,
    );
  });

  testWidgets('saved choice commits once only after the reverse route', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await openSheet(tester, session);

    await tester.tap(find.byKey(const ValueKey('buy-prescription-meera')));
    await tester.pump();
    expect(session.prescriptionAttached, isFalse);
    expect(session.approvedPrescriptionProductCount, 0);
    await tester.pump(const Duration(milliseconds: 219));
    expect(session.prescriptionAttached, isFalse);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();

    expect(session.prescriptionAttached, isTrue);
    expect(session.approvedPrescriptionProductCount, 2);
    expect(
      find.byKey(const ValueKey('buy-prescription-sheet-route')),
      findsNothing,
    );
  });

  testWidgets('new choice remains a local match action after reverse', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await openSheet(tester, session);

    await tester.tap(find.byKey(const ValueKey('buy-prescription-add-new')));
    await tester.pump(const Duration(milliseconds: 219));
    expect(session.prescriptionAttached, isFalse);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();

    expect(session.prescriptionAttached, isTrue);
    expect(session.approvedPrescriptionProductCount, 3);
    expect(session.notice, '3 matched medicines are ready to add.');
  });

  testWidgets('Back, Close and lifecycle never attach a prescription', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await openSheet(tester, session);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(session.prescriptionAttached, isFalse);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(session.prescriptionAttached, isFalse);

    await tester.tap(find.byKey(const ValueKey('open-prescription-sheet')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-prescription-close')));
    await tester.pumpAndSettle();
    expect(session.prescriptionAttached, isFalse);
    expect(session.approvedPrescriptionProductCount, 0);
  });

  testWidgets('stale destination, view or pending product fails closed', (
    tester,
  ) async {
    final destinationSession = BuyV2Session(core: BuySession());
    addTearDown(destinationSession.dispose);
    await openSheet(tester, destinationSession);
    destinationSession.openDestination(BuyV2Destination.medicine);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('buy-prescription-meera')));
    await tester.pumpAndSettle();
    expect(destinationSession.prescriptionAttached, isFalse);

    final viewSession = BuyV2Session(core: BuySession());
    addTearDown(viewSession.dispose);
    await openSheet(tester, viewSession);
    viewSession.openAccount();
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('buy-prescription-arvind')));
    await tester.pumpAndSettle();
    expect(viewSession.prescriptionAttached, isFalse);

    final pendingSession = BuyV2Session(core: BuySession());
    addTearDown(pendingSession.dispose);
    final prescriptionProducts = BuyV2Catalogue.products
        .where((product) => product.requiresPrescription)
        .take(2)
        .toList(growable: false);
    expect(pendingSession.addProduct(prescriptionProducts.first.id), isFalse);
    await openSheet(tester, pendingSession);
    expect(pendingSession.addProduct(prescriptionProducts.last.id), isFalse);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('buy-prescription-meera')));
    await tester.pumpAndSettle();
    expect(pendingSession.prescriptionAttached, isFalse);
    expect(pendingSession.approvedPrescriptionProductCount, 0);
  });

  testWidgets('named route and choices expose honest actionable semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await openSheet(tester, session);

    final route = find.byKey(const ValueKey('buy-prescription-sheet-route'));
    expect(tester.getSemantics(route).label, 'Prescription centre');
    final saved = tester.getSemantics(
      find.byKey(const ValueKey('buy-prescription-semantics-meera')),
    );
    expect(saved.label, contains('Saved prescription'));
    expect(saved.flagsCollection.isButton, isTrue);
    expect(saved.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    final add = tester.getSemantics(
      find.byKey(const ValueKey('buy-prescription-add-new-semantics')),
    );
    expect(add.label, contains('Match medicines for review in this session'));
    expect(add.flagsCollection.isButton, isTrue);
    expect(add.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('buy-prescription-close')))
          .height,
      greaterThanOrEqualTo(44),
    );
    expect(find.textContaining('upload'), findsNothing);
    expect(find.textContaining('camera'), findsNothing);
    expect(find.textContaining('Valid prescription'), findsNothing);
    semantics.dispose();
  });

  testWidgets('compact 140 percent keeps the Add choice reachable', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await openSheet(tester, session, textScale: 1.4);

    final target = find.byKey(const ValueKey('buy-prescription-add-new'));
    await tester.scrollUntilVisible(
      target,
      120,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('buy-prescription-sheet-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    expect(target, findsOneWidget);
    expect(tester.getSize(target).height, greaterThanOrEqualTo(58));
    expect(tester.takeException(), isNull);
  });

  testWidgets('OPPO inset exports the full Add prescription target', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    tester.view.padding = const FakeViewPadding(top: 41, bottom: 44);
    tester.view.viewPadding = const FakeViewPadding(top: 41, bottom: 44);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await openSheet(tester, session);

    final target = find.byKey(const ValueKey('buy-prescription-add-new'));
    await tester.scrollUntilVisible(
      target,
      120,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('buy-prescription-sheet-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();

    final rect = tester.getRect(target);
    expect(rect.height, greaterThanOrEqualTo(58));
    expect(rect.bottom, lessThanOrEqualTo(756));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion opens and commits immediately', (tester) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await openSheet(tester, session, disableAnimations: true, settle: false);
    expect(
      find.byKey(const ValueKey('buy-prescription-sheet-route')),
      findsOne,
    );

    await tester.tap(find.byKey(const ValueKey('buy-prescription-add-new')));
    await tester.pump();
    await tester.pump();
    expect(session.prescriptionAttached, isTrue);
    expect(session.approvedPrescriptionProductCount, 3);
    expect(
      find.byKey(const ValueKey('buy-prescription-sheet-route')),
      findsNothing,
    );
  });

  testWidgets('R56.8 prescription-sheet responsive evidence captures', (
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
          'candidate_captures/buy-v2-r56-8-prescription-${capture.$4}.png',
        ),
      );
      session.dispose();
    }
    tester.view.reset();
  }, skip: true);
}
