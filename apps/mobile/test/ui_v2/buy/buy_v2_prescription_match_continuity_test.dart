import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(
    BuyV2Session session, {
    double textScale = 1,
    bool reducedMotion = false,
  }) {
    return MaterialApp(
      theme: MoolTheme.light(),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reducedMotion,
          ),
          child: child!,
        );
      },
      home: BuyV2Screen(
        session: session,
        initialDestination: BuyV2Destination.medicine,
        initialView: session.view,
      ),
    );
  }

  BuyV2Session medicineSession() {
    final session = BuyV2Session(core: BuySession());
    session.openDestination(BuyV2Destination.medicine);
    return session;
  }

  test(
    'saved prescription exposes only exact session-owned medicine matches',
    () {
      final session = medicineSession();

      expect(session.matchedPrescriptionProducts, isEmpty);
      expect(session.approveSavedPrescription('meera'), isTrue);

      expect(session.matchedPrescriptionProducts.map((product) => product.id), [
        'm-telmisartan-40',
        'm-atorvastatin-10',
      ]);
      expect(
        session.matchedPrescriptionProducts.every(
          (product) =>
              product.destination == BuyV2Destination.medicine &&
              product.requiresPrescription,
        ),
        isTrue,
      );
      expect(
        session.matchedPrescriptionProducts.any(
          (product) => product.id == 'm-metformin-500',
        ),
        isFalse,
      );
    },
  );

  testWidgets(
    'prescription choice reveals stable exact-product continuity and Back',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final semantics = tester.ensureSemantics();
      final session = medicineSession();

      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('buy-promotion-medicine-prescription')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('buy-prescription-semantics-meera')),
      );
      await tester.pumpAndSettle();

      final lane = find.byKey(const ValueKey('buy-prescription-match-lane'));
      expect(lane, findsOneWidget);
      expect(find.text('Prescription matches'), findsOneWidget);
      expect(find.textContaining('Pharmacist review'), findsOneWidget);
      expect(find.textContaining('Not medical advice'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey('buy-prescription-match-product-m-telmisartan-40'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('buy-prescription-match-product-m-atorvastatin-10'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('buy-prescription-match-product-m-metformin-500'),
        ),
        findsNothing,
      );

      final telmisartan = find.byKey(
        const ValueKey('buy-prescription-match-product-m-telmisartan-40'),
      );
      expect(
        tester
            .getSemantics(telmisartan)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
      await tester.tap(telmisartan);
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.product);
      expect(session.selectedProductId, 'm-telmisartan-40');

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.catalogue);
      expect(lane, findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets('pending Rx Add remains exact and does not jump routes', (
    tester,
  ) async {
    final session = medicineSession();
    session.openProduct('m-telmisartan-40');
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('buy-product-primary-m-telmisartan-40')),
    );
    await tester.pumpAndSettle();
    expect(session.pendingPrescriptionProductId, 'm-telmisartan-40');
    await tester.tap(
      find.byKey(const ValueKey('buy-prescription-semantics-meera')),
    );
    await tester.pumpAndSettle();

    expect(session.view, BuyV2View.product);
    expect(session.selectedProductId, 'm-telmisartan-40');
    expect(session.quantityFor('m-telmisartan-40'), 1);
    expect(session.pendingPrescriptionProductId, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('match lane is static and stable at 320px 140 percent', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = medicineSession()..approveSavedPrescription('arvind');

    await tester.pumpWidget(app(session, textScale: 1.4, reducedMotion: true));
    await tester.pumpAndSettle();

    final lane = find.byKey(const ValueKey('buy-prescription-match-lane'));
    expect(lane, findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('buy-prescription-match-product-m-metformin-500'),
      ),
      findsOneWidget,
    );
    final listener = tester.widget<Listener>(
      find
          .descendant(
            of: find.byKey(
              const ValueKey('buy-prescription-match-depth-m-metformin-500'),
            ),
            matching: find.byType(Listener),
          )
          .first,
    );
    expect(listener.onPointerDown, isNull);
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });
}
