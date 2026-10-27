import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/ui_v2/profile/global_account_plans_v2.dart';

const offer = GlobalAccountPlanOffer(
  id: 'fixture-offer',
  name: 'Host fixture plan',
  priceLabel: 'Fixture price / month',
  features: ['Fixture feature'],
  eligible: true,
);

GlobalAccountPlansViewData data({
  Object owner = 'owner-a',
  String revision = 'r1',
  GlobalAccountPlansStatus status = GlobalAccountPlansStatus.ready,
  List<GlobalAccountPlanOffer> offers = const [offer],
  String? currentPlanId,
  bool canManage = false,
}) => GlobalAccountPlansViewData(
  accountScope: owner,
  revision: revision,
  audience: GlobalAccountPlanAudience.personal,
  status: status,
  offers: offers,
  currentPlanId: currentPlanId,
  canManage: canManage,
);

void main() {
  Future<void> pump(
    WidgetTester tester, {
    Object? owner = 'owner-a',
    bool? authenticated,
    GlobalAccountPlansViewData? snapshot,
    Future<void> Function(GlobalAccountPlanOffer, String)? review,
    Future<void> Function(String)? manage,
    double scale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: GlobalAccountPlansV2(
            accountScope: owner,
            accountAuthenticated: authenticated ?? owner != null,
            data: snapshot,
            onReview: review,
            onManage: manage,
            onClose: () {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'disconnected catalogue never fabricates a current or free plan',
    (tester) async {
      await pump(tester);
      expect(find.text('Plans are not available right now.'), findsOneWidget);
      expect(find.text('Free'), findsNothing);
      expect(find.text('Current plan'), findsNothing);
      expect(find.text('Review plan'), findsNothing);
      await tester.tap(find.text('Workspace'));
      await tester.pump();
      expect(
        find.text(
          'Workspace activation requires documents and MoolSocial approval.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('signed-out or wrong-account catalogue does not expose offers', (
    tester,
  ) async {
    await pump(tester, owner: null, snapshot: data());
    expect(
      find.text('Sign in to view plans for your account.'),
      findsOneWidget,
    );
    expect(find.text(offer.name), findsNothing);
    await pump(tester, owner: 'owner-b', snapshot: data());
    expect(find.text(offer.name), findsNothing);
  });

  testWidgets(
    'authenticated missing principal is unavailable rather than signed out',
    (tester) async {
      await pump(tester, owner: null, authenticated: true, snapshot: data());
      expect(
        find.text('Plans are not available for this account right now.'),
        findsOneWidget,
      );
      expect(
        find.text('Sign in to view plans for your account.'),
        findsNothing,
      );
      expect(find.text(offer.name), findsNothing);
      await pump(tester, authenticated: false, snapshot: data());
      expect(find.text(offer.name), findsNothing);
    },
  );

  testWidgets('empty revision and duplicate offer IDs cannot open billing', (
    tester,
  ) async {
    var calls = 0;
    Future<void> review(GlobalAccountPlanOffer _, String __) async {
      calls++;
    }

    await pump(
      tester,
      snapshot: data(revision: ''),
      review: review,
    );
    expect(find.text('Review plan'), findsNothing);
    await pump(
      tester,
      snapshot: data(offers: [offer, offer]),
      review: review,
    );
    expect(find.text('Review plan'), findsNothing);
    expect(calls, 0);
  });

  for (final status in [
    GlobalAccountPlansStatus.loading,
    GlobalAccountPlansStatus.failed,
    GlobalAccountPlansStatus.unavailable,
  ]) {
    testWidgets('$status never renders authoritative action buttons', (
      tester,
    ) async {
      await pump(tester, snapshot: data(status: status));
      expect(find.text('Review plan'), findsNothing);
      expect(find.text('Manage plan'), findsNothing);
      expect(find.text(offer.name), findsNothing);
    });
  }

  testWidgets(
    'review is single-flight and retains revision without local activation',
    (tester) async {
      var calls = 0;
      final completion = Completer<void>();
      await pump(
        tester,
        snapshot: data(),
        review: (selected, revision) {
          expect(selected.id, offer.id);
          expect(revision, 'r1');
          calls++;
          return completion.future;
        },
      );
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Review plan'),
      );
      button.onPressed!();
      button.onPressed!();
      await tester.pump();
      expect(calls, 1);
      expect(find.text('Current plan'), findsNothing);
      completion.complete();
      await tester.pump();
      expect(find.text('Current plan'), findsNothing);
    },
  );

  testWidgets('old account and revision callbacks cannot reuse a stale offer', (
    tester,
  ) async {
    var calls = 0;
    Future<void> review(GlobalAccountPlanOffer _, String __) async {
      calls++;
    }

    await pump(tester, snapshot: data(), review: review);
    final oldButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Review plan'),
    );
    await pump(
      tester,
      snapshot: data(revision: 'r2'),
      review: review,
    );
    oldButton.onPressed!();
    await tester.pump();
    expect(calls, 0);
    final revisedButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Review plan'),
    );
    await pump(
      tester,
      owner: 'owner-b',
      snapshot: data(owner: 'owner-b'),
      review: review,
    );
    revisedButton.onPressed!();
    await tester.pump();
    expect(calls, 0);
  });

  testWidgets(
    'failed handoff allows recovery and never confirms a subscription',
    (tester) async {
      await pump(
        tester,
        snapshot: data(),
        review: (_, __) async {
          throw StateError('host failure');
        },
      );
      await tester.tap(find.text('Review plan'));
      await tester.pump();
      expect(find.text('Could not open billing. Try again.'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Review plan'),
            )
            .onPressed,
        isNotNull,
      );
      expect(find.text('Current plan'), findsNothing);
    },
  );

  testWidgets('current plan and Manage are shown only from supplied readback', (
    tester,
  ) async {
    var calls = 0;
    await pump(
      tester,
      snapshot: data(currentPlanId: offer.id, canManage: true),
      manage: (revision) async {
        expect(revision, 'r1');
        calls++;
      },
    );
    expect(find.text('Current plan'), findsOneWidget);
    expect(find.text('Review plan'), findsNothing);
    await tester.tap(find.text('Manage plan'));
    await tester.pump();
    expect(calls, 1);
  });

  for (final managing in [false, true]) {
    final label = managing ? 'Manage plan' : 'Review plan';

    testWidgets(
      'PROFILE-QA02 retained $label expires across sign-out and re-sign-in',
      (tester) async {
        var calls = 0;
        final snapshot = data(
          currentPlanId: managing ? offer.id : null,
          canManage: managing,
        );
        Future<void> review(GlobalAccountPlanOffer _, String __) async {
          calls++;
        }

        Future<void> manage(String _) async {
          calls++;
        }

        Future<void> mount(bool authenticated) => pump(
          tester,
          authenticated: authenticated,
          snapshot: snapshot,
          review: review,
          manage: manage,
        );
        VoidCallback action() => tester
            .widget<ButtonStyleButton>(
              find.widgetWithText(
                managing ? OutlinedButton : FilledButton,
                label,
              ),
            )
            .onPressed!;

        await mount(true);
        final retained = action();
        await mount(false);
        await mount(true);
        retained();
        await tester.pump();
        expect(
          calls,
          0,
          reason:
              'The restored same owner/snapshot must not revive a pre-sign-out callback.',
        );
        action()();
        await tester.pump();
        expect(calls, 1, reason: 'A fresh visible action remains usable.');
      },
    );

    testWidgets(
      'PROFILE-QA02 in-flight $label cannot expose an old error after sign-out',
      (tester) async {
        final completion = Completer<void>();
        final snapshot = data(
          currentPlanId: managing ? offer.id : null,
          canManage: managing,
        );
        Future<void> review(GlobalAccountPlanOffer _, String __) =>
            completion.future;
        Future<void> manage(String _) => completion.future;
        await pump(tester, snapshot: snapshot, review: review, manage: manage);
        await tester.tap(find.text(label));
        await tester.pump();
        await pump(
          tester,
          authenticated: false,
          snapshot: snapshot,
          review: review,
          manage: manage,
        );
        completion.completeError(StateError('isolated host billing failure'));
        await tester.pump();
        expect(
          find.text('Sign in to view plans for your account.'),
          findsOneWidget,
        );
        expect(find.text('Could not open billing. Try again.'), findsNothing);
      },
    );

    testWidgets('PROFILE-QA02 disposed $label callback cannot start billing', (
      tester,
    ) async {
      var calls = 0;
      await pump(
        tester,
        snapshot: data(
          currentPlanId: managing ? offer.id : null,
          canManage: managing,
        ),
        review: (_, __) async {
          calls++;
        },
        manage: (_) async {
          calls++;
        },
      );
      final retained = tester
          .widget<ButtonStyleButton>(
            find.widgetWithText(
              managing ? OutlinedButton : FilledButton,
              label,
            ),
          )
          .onPressed!;
      await tester.pumpWidget(const SizedBox.shrink());
      retained();
      await tester.pump();
      expect(calls, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'B02 full catalogue expands lazily without a fixed plan-count limit',
    (tester) async {
      final offers = List.generate(
        151,
        (i) => GlobalAccountPlanOffer(
          id: 'fixture-$i',
          name: 'Fixture offer $i',
          priceLabel: 'Host fixture price',
          features: const ['Host fixture benefit'],
          eligible: true,
        ),
      );
      await pump(tester, snapshot: data(offers: offers));
      expect(find.byType(Card).evaluate().length, lessThanOrEqualTo(3));
      final scroll = find.descendant(
        of: find.byKey(const Key('account-plans-list')),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('account-plans-view-all')),
        300,
        scrollable: scroll,
      );
      await tester.tap(find.byKey(const Key('account-plans-view-all')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Fixture offer 150'),
        500,
        scrollable: scroll,
        maxScrolls: 200,
      );
      expect(find.text('Fixture offer 150'), findsOneWidget);
      expect(find.byType(Card).evaluate().length, lessThan(15));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'B02 retired assigned version does not mark a different offer version current',
    (tester) async {
      await pump(
        tester,
        snapshot: GlobalAccountPlansViewData(
          accountScope: 'owner-a',
          revision: 'r2',
          audience: GlobalAccountPlanAudience.personal,
          status: GlobalAccountPlansStatus.ready,
          offers: [
            GlobalAccountPlanOffer(
              id: offer.id,
              version: 'v2',
              name: offer.name,
              priceLabel: offer.priceLabel,
              features: offer.features,
              eligible: true,
            ),
          ],
          currentPlanId: offer.id,
          currentPlanVersion: 'v1',
        ),
      );
      expect(find.text('Current plan'), findsNothing);
      expect(find.text('Review plan'), findsOneWidget);
    },
  );

  testWidgets('B02 signed-out state hides even a retained Store caption', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GlobalAccountPlansV2(
          accountScope: 'owner-a',
          accountAuthenticated: false,
          storeId: 'fixture-store',
          storeName: 'Retained private Store',
          onClose: () {},
        ),
      ),
    );
    await tester.tap(find.text('Workspace'));
    await tester.pump();
    expect(find.textContaining('Retained private Store'), findsNothing);
    expect(
      find.text('Sign in to view plans for your account.'),
      findsOneWidget,
    );
  });

  testWidgets('catalogue remains readable at320 and enlarged text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.reset);
    await pump(tester, snapshot: data(), scale: 2);
    await tester.scrollUntilVisible(
      find.text('Review plan'),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    expect(tester.takeException(), isNull);
    expect(find.text(offer.name), findsOneWidget);
  });
}
