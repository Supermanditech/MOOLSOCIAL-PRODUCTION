import 'dart:async';
import 'package:flutter/material.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_saved_products_store.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';

// Isolated host feedback; never actual customer reviews, reports or runtime data.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<
    (
      BuyV2Session,
      _FeedbackAdapter,
      _Owner,
      ValueNotifier<BuyV2CollectionIdentity?>,
    )
  >
  fixture({bool manualDispose = false}) async {
    final core = BuySession();
    final adapter = _FeedbackAdapter();
    final owner = _Owner();
    final identity = ValueNotifier<BuyV2CollectionIdentity?>(
      const BuyV2CollectionIdentity(accountId: 'a', sessionId: 'login-a'),
    );
    final session = BuyV2Session(
      core: core,
      commerceAdapter: adapter,
      customerStateStore: owner,
      collectionIdentity: identity,
      reviewDataEnabled: false,
    );
    addTearDown(core.dispose);
    addTearDown(identity.dispose);
    if (!manualDispose) addTearDown(session.dispose);
    await session.restoreCommerce();
    await session.restoreCustomerState();
    expect(session.canReviewProduct('s-milk'), isTrue);
    return (session, adapter, owner, identity);
  }

  Future<bool> submit(BuyV2Session session, String action) => action == 'rating'
      ? session.submitProductReviewOnline(
          productId: 's-milk',
          rating: 4,
          comment: 'Host feedback',
          targetId: 'host-target',
        )
      : session.reportProductOnline(productId: 's-milk', reason: 'Host report');

  Future<void> dispatched(_FeedbackAdapter adapter, int count) async {
    for (var i = 0; i < 30 && adapter.calls < count; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(adapter.calls, count);
  }

  test('LF13 same-account new login keeps the saved review draft', () async {
    final (session, _, _, identity) = await fixture();
    final originalContext = session.productFeedbackContext;
    session.retainProductReviewDraft(
      productId: 's-milk',
      rating: 4,
      comment: 'Retained same-account draft',
      ownerScope: 'owner-a',
      targetId: 'host-target',
    );
    identity.value = const BuyV2CollectionIdentity(
      accountId: 'a',
      sessionId: 'login-b',
    );
    session.retainProductReviewDraft(
      productId: 's-milk',
      rating: 1,
      comment: 'Stale sheet write',
      ownerScope: 'owner-a',
      targetId: 'host-target',
      feedbackContext: originalContext,
    );
    expect(
      session.productReviewDraft('s-milk', targetId: 'host-target')?.comment,
      'Retained same-account draft',
    );
  });

  test('LF13 reported listing is not another Store report', () async {
    final (session, adapter, _, _) = await fixture();
    expect(await submit(session, 'report'), isTrue);
    expect(session.hasReportedProduct('s-milk'), isTrue);
    adapter.store = 'another-store';
    await session.restoreCommerce();
    expect(session.hasReportedProduct('s-milk'), isFalse);
  });

  test('LF13 unconfirmed report cannot blindly retry', () async {
    final (session, adapter, _, _) = await fixture();
    adapter.fail = true;
    expect(await submit(session, 'report'), isFalse);
    expect(session.notice, contains('not confirmed'));
    adapter.fail = false;
    await session.restoreCommerce();
    expect(session.canReportProduct('s-milk'), isFalse);
    expect(await submit(session, 'report'), isFalse);
    expect(adapter.calls, 1);
  });

  for (final action in ['review', 'report']) {
    testWidgets('LF13 open $action sheet rejects same-owner new login', (
      tester,
    ) async {
      final (session, adapter, _, identity) = await fixture();
      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          home: BuyV2Screen(session: session, productId: 's-milk'),
        ),
      );
      await tester.pumpAndSettle();
      final button = find.byKey(ValueKey('buy-$action-product-s-milk'));
      final scrollable = find
          .descendant(
            of: find.byKey(const PageStorageKey('buy-product-s-milk')),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(button, 200, scrollable: scrollable);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      if (action == 'review') {
        await tester.enterText(
          find.byKey(const ValueKey('buy-review-comment-s-milk')),
          'Private host draft',
        );
      }
      identity.value = const BuyV2CollectionIdentity(
        accountId: 'a',
        sessionId: 'login-b',
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Your account changed.'), findsOneWidget);
      expect(adapter.calls, 0);
      expect(
        session.productReviewDraft('s-milk', targetId: 'host-target')?.comment,
        action == 'review' ? 'Private host draft' : isNull,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final action in ['rating', 'report']) {
    for (final drift in ['owner', 'auth', 'dispose']) {
      for (final fails in [false, true]) {
        test(
          'LF13 $action late $drift failure $fails stays isolated',
          () async {
            final (session, adapter, owner, identity) = await fixture(
              manualDispose: drift == 'dispose',
            );
            final gate = adapter.pending = Completer<void>();
            final request = submit(session, action);
            await dispatched(adapter, 1);
            final originalNotice = session.notice;
            switch (drift) {
              case 'owner':
                owner.scope = 'owner-b';
              case 'auth':
                identity.value = const BuyV2CollectionIdentity(
                  accountId: 'a',
                  sessionId: 'login-b',
                );
              case 'dispose':
                session.dispose();
            }
            if (fails) {
              gate.completeError(StateError('Host lost response'));
            } else {
              gate.complete();
            }
            expect(await request, isFalse);
            expect(session.hasReportedProduct('s-milk'), isFalse);
            expect(session.productFeedbackBusy('s-milk'), isFalse);
            if (drift != 'auth') expect(session.notice, originalNotice);
          },
        );
      }
    }
    test('LF13 $action notification drift stops dispatch', () async {
      final (session, adapter, owner, _) = await fixture();
      session.addListener(() => owner.scope = 'owner-b');
      expect(await submit(session, action), isFalse);
      expect(adapter.calls, 0);
    });
    test('LF13 $action old finally cannot clear next owner request', () async {
      final (session, adapter, owner, _) = await fixture();
      final first = adapter.pending = Completer<void>();
      final old = submit(session, action);
      await dispatched(adapter, 1);
      owner.scope = adapter.owner = 'owner-b';
      await session.restoreCommerce();
      await session.restoreCustomerState();
      final second = adapter.pending = Completer<void>();
      final next = submit(session, action);
      await dispatched(adapter, 2);
      expect(adapter.calls, 2);
      first.complete();
      expect(await old, isFalse);
      expect(session.productFeedbackBusy('s-milk'), isTrue);
      second.complete();
      expect(await next, isTrue);
    });
  }
  test('LF13 same-owner new login invalidates rating eligibility', () async {
    final (session, adapter, _, identity) = await fixture();
    identity.value = const BuyV2CollectionIdentity(
      accountId: 'a',
      sessionId: 'login-b',
    );
    expect(session.canReviewProduct('s-milk'), isFalse);
    expect(session.ratingTargetsFor('s-milk'), isEmpty);
    expect(await submit(session, 'rating'), isFalse);
    expect(adapter.calls, 0);
    await session.restoreCommerce();
    expect(session.canReviewProduct('s-milk'), isTrue);
  });
  test('LF13 cached report belongs only to original owner', () async {
    final (session, _, owner, _) = await fixture();
    expect(await submit(session, 'report'), isTrue);
    expect(session.hasReportedProduct('s-milk'), isTrue);
    owner.scope = 'owner-b';
    expect(session.hasReportedProduct('s-milk'), isFalse);
    expect(session.canReportProduct('s-milk'), isFalse);
  });
  test('LF13 failed rating retains draft and identical retry key', () async {
    final (session, adapter, _, _) = await fixture();
    session.retainProductReviewDraft(
      productId: 's-milk',
      rating: 4,
      comment: 'Host feedback',
      ownerScope: 'owner-a',
      targetId: 'host-target',
    );
    adapter.fail = true;
    expect(await submit(session, 'rating'), isFalse);
    expect(
      session.productReviewDraft('s-milk', targetId: 'host-target')!.comment,
      'Host feedback',
    );
    adapter.fail = false;
    expect(await submit(session, 'rating'), isTrue);
    expect(adapter.keys, hasLength(2));
    expect(adapter.keys.first, adapter.keys.last);
    expect(
      session.productReviewDraft('s-milk', targetId: 'host-target'),
      isNull,
    );
    expect(session.customerReviewFor('s-milk')!.rating, 4);
  });
  test(
    'LF13 newer typed draft is retained after prior save acknowledgment',
    () async {
      final (session, adapter, _, _) = await fixture();
      final gate = adapter.pending = Completer<void>();
      final request = submit(session, 'rating');
      session.retainProductReviewDraft(
        productId: 's-milk',
        rating: 5,
        comment: 'Newer host draft',
        ownerScope: 'owner-a',
        targetId: 'host-target',
      );
      gate.complete();
      expect(await request, isTrue);
      expect(
        session.productReviewDraft('s-milk', targetId: 'host-target')!.comment,
        'Newer host draft',
      );
    },
  );
  for (final action in ['rating', 'report']) {
    test('LF13 disposed session never dispatches $action', () async {
      final (session, adapter, _, _) = await fixture(manualDispose: true);
      session.dispose();
      expect(await submit(session, action), isFalse);
      expect(adapter.calls, 0);
    });
  }
}

class _Owner implements BuyV2CustomerStateStore {
  String scope = 'owner-a';
  @override
  String get ownerScope => scope;
  @override
  Future<BuyV2CustomerStateSnapshot?> read() async => null;
  @override
  Future<bool> write(BuyV2CustomerStateSnapshot snapshot) async => true;
}

class _FeedbackAdapter
    implements BuyV2CommerceAdapter, BuyV2VerifiedRatingAdapter {
  String owner = 'owner-a';
  String store = 'host-store';
  Completer<void>? pending;
  bool fail = false;
  int calls = 0;
  final keys = <String>[];
  BuyV2RatingTarget target({
    int version = 0,
    int? rating,
    String comment = '',
  }) => BuyV2RatingTarget(
    id: 'host-target',
    ownerScope: owner,
    orderId: 'host-order',
    orderLineId: 'host-line',
    storeId: 'host-store',
    productId: 's-milk',
    purchaseLabel: 'Host purchased pack',
    version: version,
    reviewId: rating == null ? null : 'host-review',
    rating: rating,
    comment: comment,
  );
  @override
  Future<BuyV2CommerceSnapshot> refresh() async => BuyV2CommerceSnapshot(
    state: BuyV2CommerceLoadState.ready,
    products: [
      BuyV2Catalogue.allProducts
          .firstWhere((p) => p.id == 's-milk')
          .copyWith(storeId: store),
    ],
    productReportsAvailable: true,
    ratingTargets: [target()],
  );
  @override
  Future<BuyV2RatingResult> submitRating(BuyV2RatingRequest request) async {
    calls++;
    keys.add(request.idempotencyKey);
    final originalOwner = owner;
    await pending?.future;
    if (fail) throw StateError('Host lost response');
    return BuyV2RatingResult(
      customerMessage: 'Host acknowledged',
      saved: BuyV2RatingTarget(
        id: request.target.id,
        ownerScope: originalOwner,
        orderId: request.target.orderId,
        orderLineId: request.target.orderLineId,
        storeId: request.target.storeId,
        productId: request.target.productId,
        purchaseLabel: request.target.purchaseLabel,
        version: request.target.version + 1,
        reviewId: 'host-review',
        rating: request.stars,
        comment: request.comment ?? '',
      ),
    );
  }

  @override
  Future<BuyV2MutationResult> reportProduct({
    required BuyV2Product product,
    required String reason,
  }) async {
    calls++;
    await pending?.future;
    if (fail) throw StateError('Host lost response');
    return const BuyV2MutationResult(
      accepted: true,
      customerMessage: 'Host report acknowledged',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
