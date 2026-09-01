import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/work/work_models.dart';
import 'package:moolsocial/features/work/work_services.dart';
import 'package:moolsocial/features/work/work_session.dart';

void main() {
  Future<void> mount(
    WidgetTester tester, {
    required String route,
    required WorkSession work,
    double bottomInset = 44,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    tester.view.viewPadding = FakeViewPadding(bottom: bottomInset);
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
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
    await journey.start();
    addTearDown(journey.dispose);
    addTearDown(work.dispose);
    await tester.pumpWidget(
      MoolSocialApp(
        session: journey,
        workSession: work,
        initialLocation: route,
      ),
    );
    await tester.pumpAndSettle();
  }

  void expectHeaderAndStickyAction(WidgetTester tester) {
    final titleFinder = find.byKey(const Key('work-page-title'));
    final subtitleFinder = find.byKey(const Key('work-page-subtitle'));
    expect(
      tester.widget<Text>(titleFinder).overflow,
      isIn([TextOverflow.clip, TextOverflow.ellipsis]),
    );
    expect(tester.widget<Text>(subtitleFinder).maxLines, 2);
    expect(tester.getRect(titleFinder).right, lessThanOrEqualTo(360));
    expect(tester.getRect(subtitleFinder).right, lessThanOrEqualTo(360));
    final sticky = find.byKey(const Key('work-sticky-action-bar'));
    final navigation = find.byKey(const Key('work-local-navigation'));
    expect(sticky, findsOneWidget);
    expect(navigation, findsOneWidget);
    expect(
      tester.getBottomRight(sticky).dy,
      lessThanOrEqualTo(tester.getTopRight(navigation).dy),
    );
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    final vertical = find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable &&
          (widget.axisDirection == AxisDirection.down ||
              widget.axisDirection == AxisDirection.up),
    );
    for (
      var attempt = 0;
      attempt < 12 && finder.evaluate().isEmpty;
      attempt++
    ) {
      await tester.drag(vertical.last, const Offset(0, -220));
      await tester.pumpAndSettle();
    }
    expect(finder, findsOneWidget);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  WorkSession selectedRetailer() => WorkSession()
    ..selectFamily('products-trade')
    ..selectProfile('retailer-grocery');

  testWidgets(
    'selected Workspace profile keeps contact clear of sticky Continue',
    (tester) async {
      final work = selectedRetailer();
      await mount(tester, route: '/app/work/workspace/choose', work: work);

      expect(find.text('Grow with MoolSocial'), findsOneWidget);
      expect(find.text('Products & Trade'), findsWidgets);
      expectHeaderAndStickyAction(tester);
      final alternate = find.byKey(const Key('work-alternate-mobile'));
      await reveal(tester, alternate);
      expect(
        tester.getBottomRight(alternate).dy,
        lessThanOrEqualTo(
          tester
              .getTopRight(find.byKey(const Key('work-sticky-action-bar')))
              .dy,
        ),
      );
      expect(find.byKey(const Key('work-continue-proof')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Workspace request sheet clears Android and keyboard insets without losing input',
    (tester) async {
      final work = WorkSession();
      await mount(
        tester,
        route: '/app/work/workspace/choose',
        work: work,
        bottomInset: 0,
      );

      final request = find.byKey(const Key('work-profile-not-shown'));
      await tester.scrollUntilVisible(
        request,
        300,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('work-choose-screen')),
              matching: find.byType(Scrollable),
            )
            .first,
        maxScrolls: 60,
      );
      await tester.pumpAndSettle();
      await tester.tap(request);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('work-profile-request-sheet')),
        findsOneWidget,
      );
      final actions = find.byKey(const Key('work-profile-request-actions'));
      expect(tester.getBottomRight(actions).dy, lessThanOrEqualTo(768));

      final name = find.byKey(const Key('work-request-profile-name'));
      await tester.tap(name);
      await tester.enterText(name, 'Furniture repair');
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(name).controller?.text,
        'Furniture repair',
      );
      expect(tester.getBottomRight(actions).dy, lessThanOrEqualTo(468));
      expect(
        find.byKey(const Key('work-send-profile-request')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('work-profile-request-back')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('work-profile-request-back')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-profile-request-sheet')), findsNothing);
    },
  );

  testWidgets(
    'proof source and review declaration clear system and sticky actions',
    (tester) async {
      final work = selectedRetailer()
        ..saveDetails(
          name: 'Mahadev Fresh Mart',
          area: 'Sardarpura, Jodhpur',
          activity: 'Grocery and household products',
        )
        ..continueToProof();
      await mount(tester, route: '/app/work/workspace/proof', work: work);
      await tester.tap(find.byKey(const Key('work-details-continue')));
      await tester.pumpAndSettle();
      final addProof = find.byKey(const Key('work-add-proof-shop-front'));
      await reveal(tester, addProof);
      await tester.tap(addProof);
      await tester.pumpAndSettle();
      final cancel = find.byKey(const Key('work-proof-source-cancel'));
      expect(tester.getBottomRight(cancel).dy, lessThanOrEqualTo(756));
      await tester.tap(cancel);
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        await work.addProof('shop-front', WorkProofSource.upload);
        await work.addProof('owner-authority', WorkProofSource.upload);
        await work.addProof('payout-bank-account', WorkProofSource.upload);
      });
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('work-proof-review')));
      await tester.pumpAndSettle();
      final declaration = find.byKey(const Key('work-declaration'));
      await reveal(tester, declaration);
      expect(
        tester.getBottomRight(declaration).dy,
        lessThanOrEqualTo(
          tester
              .getTopRight(find.byKey(const Key('work-sticky-action-bar')))
              .dy,
        ),
      );
      expect(find.byKey(const Key('work-submit-profile')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'review status keeps Action available above Check review update',
    (tester) async {
      final work = selectedRetailer()
        ..reviewStage = WorkReviewStage.gstPending
        ..reviewCaseId = 'WORK-REVIEW-204';
      await mount(tester, route: '/app/work/status', work: work);
      expectHeaderAndStickyAction(tester);
      final action = find.text('Action available');
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      expect(
        tester.getBottomRight(action).dy,
        lessThanOrEqualTo(
          tester
              .getTopRight(find.byKey(const Key('work-sticky-action-bar')))
              .dy,
        ),
      );
      expect(find.byKey(const Key('work-check-review')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ready and shop setup content remain scrollable above stable action',
    (tester) async {
      final work = WorkSession()..seedVerifiedWorkspace();
      work.beginRetailerSetup();
      work.addRetailerProduct();
      await mount(tester, route: '/app/work/retailer/setup', work: work);
      expectHeaderAndStickyAction(tester);
      final visibilityCopy = find.text(
        'Nothing is public until setup passes and you choose Finish setup and go live.',
      );
      await reveal(tester, visibilityCopy);
      expect(
        tester.getBottomRight(visibilityCopy).dy,
        lessThanOrEqualTo(
          tester
              .getTopRight(find.byKey(const Key('work-sticky-action-bar')))
              .dy,
        ),
      );
      expect(find.byKey(const Key('retailer-finish-setup')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
