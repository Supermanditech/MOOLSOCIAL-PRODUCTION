import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_saved_products_store.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_order_resolution_contracts.dart';

// Isolated host fixtures, never device orders/proof or real business actions.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  (BuyV2Session, _Adapter, _Owner, ValueNotifier<BuyV2CollectionIdentity?>)
  fixture({bool manualDispose = false}) {
    final core = BuySession();
    final adapter = _Adapter();
    final owner = _Owner();
    final identity = ValueNotifier<BuyV2CollectionIdentity?>(
      const BuyV2CollectionIdentity(accountId: 'a', sessionId: 'session-a'),
    );
    final session = BuyV2Session(
      core: core,
      deliveryExceptionAdapter: adapter,
      customerStateStore: owner,
      collectionIdentity: identity,
    );
    addTearDown(core.dispose);
    addTearDown(identity.dispose);
    if (!manualDispose) addTearDown(session.dispose);
    return (session, adapter, owner, identity);
  }

  Future<bool> invoke(BuyV2Session session, String action) => switch (action) {
    'read' => session.restoreDeliveryException('PO-240783'),
    'reschedule' => session.confirmDeliveryReschedule('PO-240783'),
    _ => session.disputeProofOfDelivery('PO-240783'),
  };

  Future<void> prepare(
    BuyV2Session session,
    _Adapter adapter,
    String action,
  ) async {
    adapter.proof = action == 'dispute';
    expect(await session.restoreDeliveryException('PO-240783'), isTrue);
    if (action == 'reschedule') {
      expect(
        session.chooseDeliveryRescheduleSlot('PO-240783', 'Tomorrow'),
        isTrue,
      );
    }
  }

  (
    BuyV2Session,
    _ResolutionAdapter,
    _Owner,
    ValueNotifier<BuyV2CollectionIdentity?>,
  )
  resolutionFixture({bool manualDispose = false}) {
    final core = BuySession();
    final adapter = _ResolutionAdapter();
    final owner = _Owner();
    final identity = ValueNotifier<BuyV2CollectionIdentity?>(
      const BuyV2CollectionIdentity(accountId: 'a', sessionId: 'session-a'),
    );
    final session = BuyV2Session(
      core: core,
      orderResolutionAdapter: adapter,
      customerStateStore: owner,
      collectionIdentity: identity,
    );
    addTearDown(core.dispose);
    addTearDown(identity.dispose);
    if (!manualDispose) addTearDown(session.dispose);
    return (session, adapter, owner, identity);
  }

  Future<bool> resolve(BuyV2Session session) => session.submitOrderResolution(
    orderId: 'PO-240783',
    kind: BuyV2OrderResolutionKind.cancel,
    reason: 'Changed mind',
  );
  for (final action in ['read', 'submit']) {
    for (final drift in ['owner', 'auth', 'dispose']) {
      for (final fails in [false, true]) {
        test(
          'LF12 resolution $action late $drift failure $fails isolated',
          () async {
            final (session, adapter, owner, identity) = resolutionFixture(
              manualDispose: drift == 'dispose',
            );
            expect(await session.refreshOrderResolution('PO-240783'), isTrue);
            adapter.pending = Completer<void>();
            final request = action == 'read'
                ? session.refreshOrderResolution('PO-240783')
                : resolve(session);
            switch (drift) {
              case 'owner':
                owner.scope = 'owner-b';
              case 'auth':
                identity.value = const BuyV2CollectionIdentity(
                  accountId: 'b',
                  sessionId: 'session-b',
                );
              case 'dispose':
                session.dispose();
            }
            if (fails) {
              adapter.pending!.completeError(StateError('Host lost reply'));
            } else {
              adapter.pending!.complete();
            }
            expect(await request, isFalse);
            expect(session.orderResolutionFor('PO-240783'), isNull);
            expect(session.orderResolutionResultFor('PO-240783'), isNull);
            expect(session.orderResolutionBusy('PO-240783'), isFalse);
          },
        );
      }
    }
    test('LF12 resolution $action listener drift prevents dispatch', () async {
      final (session, adapter, owner, _) = resolutionFixture();
      expect(await session.refreshOrderResolution('PO-240783'), isTrue);
      final calls = adapter.calls;
      session.addListener(() => owner.scope = 'owner-b');
      expect(
        await (action == 'read'
            ? session.refreshOrderResolution('PO-240783')
            : resolve(session)),
        isFalse,
      );
      expect(adapter.calls, calls);
    });
    test(
      'LF12 resolution $action old finally cannot clear next owner',
      () async {
        final (session, adapter, owner, _) = resolutionFixture();
        expect(await session.refreshOrderResolution('PO-240783'), isTrue);
        final first = adapter.pending = Completer<void>();
        final old = action == 'read'
            ? session.refreshOrderResolution('PO-240783')
            : resolve(session);
        owner.scope = 'owner-b';
        final second = adapter.pending = Completer<void>();
        final next = session.refreshOrderResolution('PO-240783');
        first.complete();
        expect(await old, isFalse);
        expect(session.orderResolutionBusy('PO-240783'), isTrue);
        second.complete();
        expect(await next, isTrue);
      },
    );
  }
  test(
    'LF12 resolution unknown submission does not permit blind retry',
    () async {
      final (session, adapter, _, _) = resolutionFixture();
      expect(await session.refreshOrderResolution('PO-240783'), isTrue);
      adapter.fail = true;
      expect(await resolve(session), isFalse);
      expect(session.notice, contains('not confirmed'));
      adapter.fail = false;
      await session.refreshOrderResolution('PO-240783');
      expect(await resolve(session), isFalse);
      expect(adapter.submissions, 1);
    },
  );
  test(
    'LF12 resolution cached eligibility is not another owner eligibility',
    () async {
      final (session, adapter, owner, _) = resolutionFixture();
      expect(await session.refreshOrderResolution('PO-240783'), isTrue);
      owner.scope = 'owner-b';
      expect(session.orderResolutionFor('PO-240783'), isNull);
      expect(await resolve(session), isFalse);
      expect(adapter.submissions, 0);
    },
  );

  for (final action in ['read', 'reschedule', 'dispute']) {
    for (final drift in ['owner', 'auth', 'dispose']) {
      for (final fails in [false, true]) {
        test('LF12 $action late $drift failure $fails is isolated', () async {
          final (session, adapter, owner, identity) = fixture(
            manualDispose: drift == 'dispose',
          );
          await prepare(session, adapter, action);
          final before = session.notice;
          final pending = adapter.pending =
              Completer<BuyV2DeliveryExceptionSnapshot>();
          final request = invoke(session, action);
          switch (drift) {
            case 'owner':
              owner.scope = 'owner-b';
            case 'auth':
              identity.value = const BuyV2CollectionIdentity(
                accountId: 'b',
                sessionId: 'session-b',
              );
            case 'dispose':
              session.dispose();
          }
          if (fails) {
            pending.completeError(StateError('Host transport lost'));
          } else {
            pending.complete(adapter.result(action));
          }
          expect(await request, isFalse);
          expect(session.deliveryExceptionFor('PO-240783'), isNull);
          expect(session.selectedDeliveryRescheduleSlot('PO-240783'), isNull);
          expect(session.deliveryExceptionBusy('PO-240783'), isFalse);
          // Auth listener may itself update notice, but exception completion must not.
          if (drift != 'auth') expect(session.notice, before);
        });
      }
    }

    test('LF12 $action listener drift stops adapter dispatch', () async {
      final (session, adapter, owner, _) = fixture();
      await prepare(session, adapter, action);
      final calls = adapter.calls;
      session.addListener(() => owner.scope = 'owner-b');
      expect(await invoke(session, action), isFalse);
      expect(adapter.calls, calls);
    });

    test(
      'LF12 $action late finally cannot clear next owner operation',
      () async {
        final (session, adapter, owner, _) = fixture();
        await prepare(session, adapter, action);
        final first = adapter.pending =
            Completer<BuyV2DeliveryExceptionSnapshot>();
        final old = invoke(session, action);
        owner.scope = 'owner-b';
        final second = adapter.pending =
            Completer<BuyV2DeliveryExceptionSnapshot>();
        final next = session.restoreDeliveryException('PO-240783');
        first.complete(adapter.result(action));
        expect(await old, isFalse);
        expect(session.deliveryExceptionBusy('PO-240783'), isTrue);
        second.complete(adapter.result('read'));
        expect(await next, isTrue);
        expect(session.deliveryExceptionBusy('PO-240783'), isFalse);
      },
    );
  }

  test('LF12 cached exception and slot disappear on owner change', () async {
    final (session, adapter, owner, _) = fixture();
    await prepare(session, adapter, 'reschedule');
    owner.scope = 'owner-b';
    expect(session.deliveryExceptionFor('PO-240783'), isNull);
    expect(session.selectedDeliveryRescheduleSlot('PO-240783'), isNull);
    expect(
      session.chooseDeliveryRescheduleSlot('PO-240783', 'Tomorrow'),
      isFalse,
    );
    expect(await session.confirmDeliveryReschedule('PO-240783'), isFalse);
    expect(adapter.calls, 1);
  });

  for (final action in ['reschedule', 'dispute']) {
    test(
      'LF12 $action unknown outcome blocks blind retry even after read',
      () async {
        final (session, adapter, _, _) = fixture();
        await prepare(session, adapter, action);
        adapter.fail = true;
        expect(await invoke(session, action), isFalse);
        expect(session.notice, contains('not confirmed'));
        adapter.fail = false;
        await session.restoreDeliveryException('PO-240783');
        expect(
          session.deliveryExceptionFor('PO-240783')!.state,
          BuyV2CommerceLoadState.unavailable,
        );
        expect(await invoke(session, action), isFalse);
        expect(adapter.mutations, 1);
      },
    );

    test('LF12 $action rejects unrelated command response', () async {
      final (session, adapter, _, _) = fixture();
      await prepare(session, adapter, action);
      adapter.wrongIdentity = true;
      expect(await invoke(session, action), isFalse);
      expect(
        session.deliveryExceptionFor('PO-240783')!.state,
        BuyV2CommerceLoadState.unavailable,
      );
    });

    test(
      'LF12 $action excludes other reads and mutations while pending',
      () async {
        final (session, adapter, _, _) = fixture();
        await prepare(session, adapter, action);
        final original = session.orders.firstWhere((o) => o.id == 'PO-240783');
        final pending = adapter.pending =
            Completer<BuyV2DeliveryExceptionSnapshot>();
        final request = invoke(session, action);
        expect(await session.restoreDeliveryException('PO-240783'), isFalse);
        expect(await invoke(session, action), isFalse);
        expect(
          session.chooseDeliveryRescheduleSlot('PO-240783', 'Tomorrow'),
          isFalse,
        );
        pending.complete(adapter.result(action));
        expect(await request, isTrue);
        expect(
          session.orders.firstWhere((o) => o.id == original.id),
          same(original),
        );
        expect(adapter.mutations, 1);
      },
    );
  }

  test('LF12 new exception invalidates slot even when label repeats', () async {
    final (session, adapter, _, _) = fixture();
    await prepare(session, adapter, 'reschedule');
    adapter.id = 'exception-new';
    expect(await session.restoreDeliveryException('PO-240783'), isTrue);
    expect(session.selectedDeliveryRescheduleSlot('PO-240783'), isNull);
    expect(await session.confirmDeliveryReschedule('PO-240783'), isFalse);
  });
}

class _ResolutionAdapter implements BuyV2OrderResolutionAdapter {
  Completer<void>? pending;
  bool fail = false;
  int calls = 0;
  int submissions = 0;
  @override
  Future<BuyV2OrderResolutionSnapshot> load(BuyV2Order order) async {
    calls++;
    await pending?.future;
    return BuyV2OrderResolutionSnapshot(
      orderId: order.id,
      state: BuyV2OrderResolutionState.ready,
      sourceId: 'host-resolution',
      options: const [
        BuyV2OrderResolutionOption(
          kind: BuyV2OrderResolutionKind.cancel,
          title: 'Cancel',
          detail: 'Host detail',
          reasons: ['Changed mind'],
        ),
      ],
    );
  }

  @override
  Future<BuyV2OrderResolutionResult> submit(
    BuyV2OrderResolutionRequest request,
  ) async {
    calls++;
    submissions++;
    await pending?.future;
    if (fail) throw StateError('Host lost reply');
    return const BuyV2OrderResolutionResult(
      accepted: true,
      customerMessage: 'Host request accepted for review',
      reference: 'host-reference',
    );
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

class _Adapter implements BuyV2DeliveryExceptionAdapter {
  Completer<BuyV2DeliveryExceptionSnapshot>? pending;
  bool proof = false;
  bool fail = false;
  bool wrongIdentity = false;
  String id = 'exception-a';
  int calls = 0;
  int mutations = 0;
  BuyV2DeliveryExceptionSnapshot result(String action) =>
      BuyV2DeliveryExceptionSnapshot(
        state: BuyV2CommerceLoadState.ready,
        customerMessage: 'Host confirmed result',
        exceptionId: wrongIdentity ? 'foreign-exception' : id,
        kind: action == 'reschedule'
            ? BuyV2DeliveryExceptionKind.dispatchDelayed
            : action == 'dispute'
            ? BuyV2DeliveryExceptionKind.proofOfDeliveryDisputed
            : proof
            ? BuyV2DeliveryExceptionKind.proofOfDeliveryAvailable
            : BuyV2DeliveryExceptionKind.rescheduleAvailable,
        headline: 'Host exception',
        detail: 'Isolated test detail',
        rescheduleSlots: action == 'read' && !proof ? ['Tomorrow'] : [],
        proofReference: proof ? 'proof-a' : null,
      );
  Future<BuyV2DeliveryExceptionSnapshot> run(String action) async {
    calls++;
    if (action != 'read') mutations++;
    if (fail) throw StateError('Host transport lost');
    return pending == null ? result(action) : pending!.future;
  }

  @override
  Future<BuyV2DeliveryExceptionSnapshot> loadException({
    required String orderId,
  }) => run('read');
  @override
  Future<BuyV2DeliveryExceptionSnapshot> rescheduleDelivery({
    required String orderId,
    required String exceptionId,
    required String slot,
  }) => run('reschedule');
  @override
  Future<BuyV2DeliveryExceptionSnapshot> disputeProofOfDelivery({
    required String orderId,
    required String exceptionId,
    required String proofReference,
  }) => run('dispute');
}
