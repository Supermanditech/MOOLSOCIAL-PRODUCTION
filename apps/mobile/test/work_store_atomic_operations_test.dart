import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/work/work_models.dart';
import 'package:moolsocial/features/work/work_services.dart';
import 'package:moolsocial/features/work/work_session.dart';

class _OrderJournalStorage extends FlutterSecureStorage {
  final values = <String, String>{};
  final writes = <String>[];
  bool failRead = false, failWrite = false;
  Completer<void>? holdWrite;
  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (failRead) throw StateError('test read failure');
    return values[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    writes.add(key);
    await holdWrite?.future;
    if (failWrite) throw StateError('test write failure');
    values[key] = value!;
  }
}

WorkOrderCommand _journalCommand(
  String id, {
  String account = 'account-A',
  String store = 'store-A',
  String? operation,
  int revision = 1,
}) => WorkOrderCommand(
  accountScope: account,
  workspaceId: store,
  orderId: id,
  operationId: operation ?? 'operation-$id',
  expectedRevision: revision,
  action: WorkOrderAction.accept,
);

Future<void> _drainOrderJournal() async {
  for (var i = 0; i < 12; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _CommandAccountStore implements WorkPendingProofStore {
  _CommandAccountStore([this.accountScope = 'account-A']);
  @override
  String? accountScope;
  @override
  Future<Map<String, Object?>?> read(String scope) async => null;
  @override
  Future<void> save(String scope, Map<String, Object?> draft) async {}
  @override
  Future<void> clear(String scope) async {}
}

const _commandStore = WorkWorkspace(
  id: 'store-A',
  name: 'Store A',
  profileLabel: 'Grocery / Kirana Shop',
  profileId: 'retailer-grocery',
  area: 'Jodhpur',
  verified: true,
);

class _CommandGateway implements WorkOrderCommandGateway {
  final submitted = <WorkOrderCommand>[];
  final reconciled = <WorkOrderCommand>[];
  final responses = <Completer<WorkOrderReply>>[];
  final replies = <Completer<WorkOrderReply>>[];
  @override
  Future<WorkOrderReply> submitOrderCommand(WorkOrderCommand command) {
    submitted.add(command);
    final completer = Completer<WorkOrderReply>();
    responses.add(completer);
    return completer.future;
  }

  @override
  Future<WorkOrderReply> reconcileOrderCommand(WorkOrderCommand command) {
    reconciled.add(command);
    final completer = Completer<WorkOrderReply>();
    replies.add(completer);
    return completer.future;
  }
}

class _TimeCommandGateway extends _CommandGateway
    implements WorkOrderTimeCommandGateway {
  @override
  bool supportsOrderTimeRequests = true;
}

WorkOrderReply _commandReply(
  String id, {
  WorkOrderCommand? command,
  int revision = 1,
  String stage = 'Confirmed',
  bool collection = false,
  Map<String, int> quantities = const {'sku-A': 1},
  WorkOrderReplyState state = WorkOrderReplyState.applied,
  DateTime? deadline,
  DateTime? fulfilmentDeadline,
  WorkspaceDeliveryAssignment? delivery,
}) => WorkOrderReply(
  accountScope: 'account-A',
  workspaceId: 'store-A',
  orderId: id,
  operationId: command?.operationId ?? '',
  revision: revision,
  state: state,
  delivery: delivery,
  order: WorkspaceOrderRecord(
    id: id,
    customer: 'Customer $id',
    items: 'Oil 1 litre',
    quantities: quantities,
    amount: 155,
    source: 'App',
    fulfilment: collection ? 'Collect at store' : 'Delivery',
    payment: 'Paid online',
    address: 'Test address',
    stage: stage,
    needsDelivery: !collection,
    createdAt: DateTime.utc(2026, 9, 10),
    collectionStoreId: collection ? 'store-A' : null,
    actionDeadline: deadline,
    fulfilmentDeadline: fulfilmentDeadline,
  ),
);

class _OrderTimeGateway extends ReviewWorkGateway
    implements WorkOrderTimeGateway {
  final requests = <WorkOrderTimeRequest>[];
  Future<WorkOrderTimeResult> Function(WorkOrderTimeRequest)? respond;
  WorkOrderTimeResult approval(WorkOrderTimeRequest r) => WorkOrderTimeResult(
    workspaceId: r.workspaceId,
    orderId: r.orderId,
    operationId: r.operationId,
    approved: true,
    acceptanceDeadline: r.expectedAcceptanceDeadline.add(
      Duration(minutes: r.additionalMinutes),
    ),
    fulfilmentDeadline: r.expectedAcceptanceDeadline.add(
      const Duration(minutes: 18),
    ),
  );
  @override
  Future<WorkOrderTimeResult> requestOrderTime(WorkOrderTimeRequest request) {
    requests.add(request);
    return respond?.call(request) ?? Future.value(approval(request));
  }
}

void main() {
  group('DASH06 delivery projection', () {
    WorkspaceDeliveryAssignment delivery(String id, String stage) =>
        WorkspaceDeliveryAssignment(
          orderId: id,
          partnerName: 'Rider $id',
          vehicleLabel: 'Bike',
          eta: DateTime.utc(2026, 9, 10, 10),
          updatedAt: DateTime.utc(2026, 9, 10, 9, 55),
          stage: stage,
        );

    test(
      'delivery progress distinguishes pickup final delivery and unknown states',
      () {
        for (final stage in [
          'Picked up',
          'Collected',
          'Out for delivery',
          'Dispatched',
          'Delivering',
        ]) {
          expect(delivery('A', stage).deliveryStage.progressIndex, 2);
        }
        expect(
          delivery('A', 'Out for delivery').deliveryStage.label,
          'Out for delivery',
        );
        expect(delivery('A', 'Delivered').deliveryStage.progressIndex, 3);
        for (final stage in [
          'Cancelled',
          'Delivery failed',
          'future-unknown',
        ]) {
          expect(delivery('A', stage).deliveryStage.progressIndex, -1);
        }
        expect(_commandReply('A', stage: 'Delivered').order!.isClosed, isTrue);
        expect(_commandReply('A', stage: 'Collected').order!.isClosed, isFalse);
        expect(
          _commandReply(
            'A',
            stage: 'Collected',
            collection: true,
          ).order!.isClosed,
          isTrue,
        );
      },
    );

    test('assignment identity and collection separation fail closed', () {
      final operations = WorkOrderOperations(
        accountScope: 'account-A',
        workspaceId: 'store-A',
        gateway: _CommandGateway(),
      );
      addTearDown(operations.dispose);
      expect(
        operations.observe(
          _commandReply('A', delivery: delivery('B', 'Assigned')),
        ),
        isFalse,
      );
      expect(
        operations.observe(
          _commandReply(
            'A',
            collection: true,
            delivery: delivery('A', 'Collected'),
          ),
        ),
        isFalse,
      );
      for (final identity in [
        ('account-B', 'store-A'),
        ('account-A', 'store-B'),
      ]) {
        expect(
          operations.observe(
            WorkOrderReply(
              accountScope: identity.$1,
              workspaceId: identity.$2,
              orderId: 'A',
              operationId: '',
              revision: 1,
              state: WorkOrderReplyState.applied,
              order: _commandReply('A').order,
              delivery: delivery('A', 'Assigned'),
            ),
          ),
          isFalse,
        );
      }
      expect(operations.orders, isEmpty);
    });

    test(
      'A and B delivery snapshots survive switching and clear by revision without business effects',
      () async {
        final operations = WorkOrderOperations(
          accountScope: 'account-A',
          workspaceId: 'store-A',
          gateway: _CommandGateway(),
        );
        final work = WorkSession(contactDraftStore: _CommandAccountStore())
          ..activeWorkspace = _commandStore
          ..workspaceId = 'store-A';
        expect(work.bindWorkspaceOrderOperations(operations), isTrue);
        addTearDown(work.dispose);
        for (final id in ['A', 'B']) {
          expect(
            operations.observe(
              _commandReply(
                id,
                stage: 'Delivery requested',
                delivery: delivery(id, 'Assigned'),
              ),
            ),
            isTrue,
          );
        }
        expect(work.selectWorkspaceOrder('A'), isTrue);
        expect(work.workspaceDeliveryAssignment!.partnerName, 'Rider A');
        expect(work.selectWorkspaceOrder('B'), isTrue);
        expect(
          operations.observe(
            _commandReply(
              'A',
              revision: 3,
              stage: 'Out for delivery',
              delivery: delivery('A', 'Out for delivery'),
            ),
          ),
          isTrue,
        );
        expect(work.currentWorkspaceOrderId, 'B');
        expect(work.workspaceDeliveryAssignment!.partnerName, 'Rider B');
        expect(
          operations.observe(
            _commandReply(
              'A',
              revision: 2,
              stage: 'Delivery requested',
              delivery: delivery('A', 'Assigned'),
            ),
          ),
          isFalse,
        );
        expect(work.selectWorkspaceOrder('A'), isTrue);
        expect(work.workspaceOrderStage, 'Out for delivery');
        expect(
          work.workspaceDeliveryAssignment!.deliveryStage,
          WorkspaceDeliveryStage.outForDelivery,
        );
        expect(await work.verifyWorkspaceHandover('123456'), isFalse);
        expect(
          operations.observe(
            _commandReply('A', revision: 4, stage: 'Delivery cancelled'),
          ),
          isTrue,
        );
        expect(work.workspaceDeliveryAssignment, isNull);
        work.selectWorkspaceOrder('B');
        work.selectWorkspaceOrder('A');
        expect(work.workspaceDeliveryAssignment, isNull);
        operations.observe(
          _commandReply(
            'A',
            revision: 5,
            stage: 'Delivered',
            delivery: delivery('A', 'Delivered'),
          ),
        );
        expect(work.hasActiveWorkspaceOrder, isFalse);
        expect(work.workspaceInvoices, isEmpty);
        expect(work.workspaceSalesToday, 0);
        expect(work.workspaceSettlementBalance, 0);
      },
    );

    test(
      'hidden store update cannot leak rider or overwrite visible store',
      () {
        final operations = WorkOrderOperations(
          accountScope: 'account-A',
          workspaceId: 'store-A',
          gateway: _CommandGateway(),
        );
        final work = WorkSession(contactDraftStore: _CommandAccountStore())
          ..activeWorkspace = _commandStore
          ..workspaceId = 'store-A';
        expect(work.bindWorkspaceOrderOperations(operations), isTrue);
        addTearDown(work.dispose);
        operations.observe(
          _commandReply(
            'A',
            stage: 'Delivery requested',
            delivery: delivery('A', 'Assigned'),
          ),
        );
        work.selectWorkspaceOrder('A');
        work.activeWorkspace = const WorkWorkspace(
          id: 'store-B',
          name: 'Store B',
          profileLabel: 'Grocery',
          profileId: 'retailer-grocery',
          area: 'Jodhpur',
          verified: true,
        );
        operations.observe(
          _commandReply(
            'A',
            revision: 2,
            stage: 'Out for delivery',
            delivery: delivery('A', 'Out for delivery'),
          ),
        );
        expect(work.workspaceDeliveryAssignment, isNull);
        work.activeWorkspace = _commandStore;
        expect(work.currentWorkspaceOrderId, 'A');
        expect(
          work.workspaceDeliveryAssignment!.deliveryStage,
          WorkspaceDeliveryStage.outForDelivery,
        );
      },
    );
  });

  group('DASH05 scoped time requests', () {
    late _TimeCommandGateway gateway;
    late WorkOrderOperations operations;
    late DateTime deadline;
    setUp(() {
      deadline = DateTime.now().toUtc().add(const Duration(minutes: 1));
      gateway = _TimeCommandGateway();
      operations = WorkOrderOperations(
        accountScope: 'account-A',
        workspaceId: 'store-A',
        gateway: gateway,
      );
      operations.observe(_commandReply('A', deadline: deadline));
    });
    tearDown(() {
      if (!operations.isDisposed) operations.dispose();
    });

    WorkOrderReply approved(
      WorkOrderCommand command, {
      int? minutes,
      int revision = 2,
      String stage = 'Confirmed',
    }) => _commandReply(
      command.orderId,
      command: command,
      revision: revision,
      stage: stage,
      deadline: command.expectedAcceptanceDeadline!.add(
        Duration(minutes: minutes ?? command.additionalMinutes!),
      ),
      fulfilmentDeadline: command.expectedAcceptanceDeadline!.add(
        const Duration(minutes: 12),
      ),
    );

    test(
      'time A is independent of accept B and retains actual deadline until confirmation',
      () async {
        operations.observe(_commandReply('B'));
        final a = operations.act(
          'A',
          WorkOrderAction.requestTime,
          additionalMinutes: 5,
        );
        final command = gateway.submitted.single;
        expect(command.version, 2);
        expect(command.expectedAcceptanceDeadline, deadline);
        expect(command.additionalMinutes, 5);
        expect(operations.order('A')!.order!.actionDeadline, deadline);
        expect(await operations.act('A', WorkOrderAction.accept), isFalse);
        final b = operations.act('B', WorkOrderAction.accept);
        gateway.responses[1].complete(
          _commandReply(
            'B',
            command: gateway.submitted[1],
            revision: 2,
            stage: 'Preparing',
          ),
        );
        expect(await b, isTrue);
        gateway.responses[0].complete(approved(command));
        expect(await a, isTrue);
        expect(operations.order('A')!.order!.stage, 'Confirmed');
        expect(
          operations.order('A')!.order!.actionDeadline,
          deadline.add(const Duration(minutes: 5)),
        );
        expect(operations.order('B')!.order!.stage, 'Preparing');
      },
    );

    test(
      'unsupported duration expired absent deadline and collection cannot request time',
      () async {
        for (final minutes in [0, 1, 3, 10]) {
          expect(
            await operations.act(
              'A',
              WorkOrderAction.requestTime,
              additionalMinutes: minutes,
            ),
            isFalse,
          );
        }
        operations.observe(
          _commandReply(
            'A',
            revision: 2,
            deadline: DateTime.now().subtract(const Duration(seconds: 1)),
          ),
        );
        expect(
          await operations.act(
            'A',
            WorkOrderAction.requestTime,
            additionalMinutes: 2,
          ),
          isFalse,
        );
        operations.observe(_commandReply('B'));
        expect(
          await operations.act(
            'B',
            WorkOrderAction.requestTime,
            additionalMinutes: 2,
          ),
          isFalse,
        );
        operations.observe(
          _commandReply('C', deadline: deadline, collection: true),
        );
        expect(
          await operations.act(
            'C',
            WorkOrderAction.requestTime,
            additionalMinutes: 2,
          ),
          isFalse,
        );
        operations.observe(
          _commandReply('D', stage: 'Preparing', deadline: deadline),
        );
        expect(
          await operations.act(
            'D',
            WorkOrderAction.requestTime,
            additionalMinutes: 2,
          ),
          isFalse,
        );
        expect(gateway.submitted, isEmpty);
      },
    );

    test(
      'explicit capability is required for new requests but not reconciliation',
      () async {
        gateway.supportsOrderTimeRequests = false;
        expect(
          await operations.act(
            'A',
            WorkOrderAction.requestTime,
            additionalMinutes: 2,
          ),
          isFalse,
        );
        gateway.supportsOrderTimeRequests = true;
        final send = operations.act(
          'A',
          WorkOrderAction.requestTime,
          additionalMinutes: 2,
        );
        final command = gateway.submitted.single;
        gateway.responses.single.completeError(StateError('unknown'));
        expect(await send, isFalse);
        gateway.supportsOrderTimeRequests = false;
        final retry = operations.retry('A');
        expect(gateway.reconciled.single, same(command));
        gateway.replies.single.complete(approved(command));
        expect(await retry, isTrue);
        expect(gateway.submitted.length, 1);
      },
    );

    for (final invalid in [
      'missing deadline',
      'unchanged deadline',
      'too long',
      'missing fulfilment',
      'fulfilment before acceptance',
      'wrong stage',
    ]) {
      test(
        'invalid time acknowledgement: $invalid remains uncertain',
        () async {
          final send = operations.act(
            'A',
            WorkOrderAction.requestTime,
            additionalMinutes: 2,
          );
          final command = gateway.submitted.single;
          final newDeadline = invalid == 'missing deadline'
              ? null
              : deadline.add(
                  Duration(
                    minutes: invalid == 'unchanged deadline'
                        ? 0
                        : invalid == 'too long'
                        ? 3
                        : 2,
                  ),
                );
          final fulfilment = invalid == 'missing fulfilment'
              ? null
              : deadline.add(
                  Duration(
                    minutes: invalid == 'fulfilment before acceptance' ? 1 : 10,
                  ),
                );
          gateway.responses.single.complete(
            _commandReply(
              'A',
              command: command,
              revision: 2,
              stage: invalid == 'wrong stage' ? 'Preparing' : 'Confirmed',
              deadline: newDeadline,
              fulfilmentDeadline: fulfilment,
            ),
          );
          expect(await send, isFalse);
          expect(operations.order('A')!.order!.actionDeadline, deadline);
          expect(operations.pending('A'), same(command));
          expect(operations.state('A'), WorkOrderOperationState.uncertain);
        },
      );
    }

    test(
      'late valid grant does not regress a newer order or restart its timer',
      () async {
        final send = operations.act(
          'A',
          WorkOrderAction.requestTime,
          additionalMinutes: 2,
        );
        final command = gateway.submitted.single;
        operations.observe(
          _commandReply(
            'A',
            revision: 4,
            stage: 'Preparing',
            deadline: deadline,
          ),
        );
        gateway.responses.single.complete(approved(command));
        expect(await send, isTrue);
        expect(operations.order('A')!.revision, 4);
        expect(operations.order('A')!.order!.stage, 'Preparing');
        expect(operations.order('A')!.order!.actionDeadline, deadline);
      },
    );

    test(
      'recovered expired request retains its original promise and resolves read-only',
      () async {
        final storage = _OrderJournalStorage();
        final journal = SecureWorkOrderPendingStore(
          storage: storage,
          currentAccount: () => 'account-A',
        );
        final original = WorkOrderCommand(
          accountScope: 'account-A',
          workspaceId: 'store-A',
          orderId: 'A',
          operationId: 'time-before-restart',
          expectedRevision: 1,
          action: WorkOrderAction.requestTime,
          additionalMinutes: 2,
          expectedAcceptanceDeadline: DateTime.now().toUtc().subtract(
            const Duration(minutes: 10),
          ),
        );
        await journal.savePending(original);
        operations.dispose();
        operations = WorkOrderOperations(
          accountScope: 'account-A',
          workspaceId: 'store-A',
          gateway: gateway,
          pendingStore: journal,
        );
        expect(await operations.restore(), isTrue);
        final restored = operations.pending('A')!;
        expect(restored.additionalMinutes, 2);
        expect(
          restored.expectedAcceptanceDeadline,
          original.expectedAcceptanceDeadline,
        );
        final retry = operations.retry('A');
        gateway.replies.single.complete(approved(restored));
        expect(await retry, isTrue);
        expect(gateway.submitted, isEmpty);
        expect(
          operations
              .order('A')!
              .order!
              .actionDeadline!
              .isBefore(DateTime.now()),
          isTrue,
        );
        expect(await journal.readPending('account-A', 'store-A'), isEmpty);
      },
    );

    test(
      'version-one saved commands preserve their version on reconciliation',
      () async {
        final storage = _OrderJournalStorage();
        final journal = SecureWorkOrderPendingStore(
          storage: storage,
          currentAccount: () => 'account-A',
        );
        await journal.savePending(_journalCommand('A'));
        final key = storage.values.keys.single;
        final envelope =
            jsonDecode(storage.values[key]!) as Map<String, dynamic>;
        final entry =
            (envelope['entries'] as List).single as Map<String, dynamic>;
        entry.remove('version');
        entry.remove('additionalMinutes');
        entry.remove('expectedAcceptanceDeadline');
        storage.values[key] = jsonEncode(envelope);
        operations.dispose();
        operations = WorkOrderOperations(
          accountScope: 'account-A',
          workspaceId: 'store-A',
          gateway: gateway,
          pendingStore: journal,
        );
        expect(await operations.restore(), isTrue);
        final retry = operations.retry('A');
        final command = gateway.reconciled.single;
        expect(command.version, 1);
        expect(command.action, WorkOrderAction.accept);
        gateway.replies.single.complete(
          _commandReply('A', command: command, revision: 2, stage: 'Preparing'),
        );
        expect(await retry, isTrue);
        expect(await journal.readPending('account-A', 'store-A'), isEmpty);
      },
    );

    test(
      'session uncertain time A allows B and same request retry ignores a changed choice',
      () async {
        final work = WorkSession(contactDraftStore: _CommandAccountStore())
          ..activeWorkspace = _commandStore
          ..workspaceId = 'store-A';
        operations.observe(_commandReply('B', deadline: deadline));
        expect(work.bindWorkspaceOrderOperations(operations), isTrue);
        addTearDown(work.dispose);
        work.selectWorkspaceOrder('A');
        final a = work.requestWorkspaceOrderTime('A', 5);
        final command = gateway.submitted.single;
        expect(work.hasPendingOrderTime, isFalse);
        expect(work.hasPendingCurrentOrderTime, isTrue);
        expect(work.orderTimeRequestBusy, isTrue);
        gateway.responses.single.completeError(StateError('unknown'));
        expect(await a, isFalse);
        expect(work.orderTimeRequestBusy, isFalse);
        work.selectWorkspaceOrder('B');
        expect(work.currentWorkspaceOrderId, 'B');
        expect(work.hasPendingCurrentOrderTime, isFalse);
        final b = work.submitWorkspaceOrderAction('B', WorkOrderAction.accept);
        gateway.responses[1].complete(
          _commandReply(
            'B',
            command: gateway.submitted[1],
            revision: 2,
            stage: 'Preparing',
          ),
        );
        expect(await b, isTrue);
        work.selectWorkspaceOrder('A');
        final retry = work.requestWorkspaceOrderTime('A', 2);
        expect(gateway.reconciled.single, same(command));
        expect(gateway.reconciled.single.additionalMinutes, 5);
        gateway.replies.single.complete(approved(command));
        expect(await retry, isTrue);
        expect(
          work.currentWorkspaceOrder!.actionDeadline,
          deadline.add(const Duration(minutes: 5)),
        );
        expect(work.workspaceInvoices, isEmpty);
        expect(work.workspaceSalesToday, 0);
      },
    );
  });

  group('DASH04 durable order journal', () {
    late _OrderJournalStorage storage;
    late SecureWorkOrderPendingStore journal;
    late _CommandGateway gateway;
    late WorkOrderOperations operations;
    String? account;
    setUp(() {
      account = 'account-A';
      storage = _OrderJournalStorage();
      journal = SecureWorkOrderPendingStore(
        storage: storage,
        currentAccount: () => account,
      );
      gateway = _CommandGateway();
      operations = WorkOrderOperations(
        accountScope: 'account-A',
        workspaceId: 'store-A',
        gateway: gateway,
        pendingStore: journal,
      );
    });
    tearDown(() {
      if (!operations.isDisposed) operations.dispose();
    });

    test(
      'journal uses the installed secure storage API without document keys',
      () async {
        TestWidgetsFlutterBinding.ensureInitialized();
        FlutterSecureStorage.setMockInitialValues({
          'moolsocial.workspace.pending-proof.v1':
              'untouched-document-checkpoint',
        });
        final nativeApi = SecureWorkOrderPendingStore(
          currentAccount: () => account,
        );
        final command = _journalCommand('native');
        await nativeApi.savePending(command);
        expect(
          (await nativeApi.readPending(
            'account-A',
            'store-A',
          )).single.operationId,
          command.operationId,
        );
        await nativeApi.removePending(command);
        expect(await nativeApi.readPending('account-A', 'store-A'), isEmpty);
        expect(
          await const FlutterSecureStorage().read(
            key: 'moolsocial.workspace.pending-proof.v1',
          ),
          'untouched-document-checkpoint',
        );
      },
    );

    test(
      '1000 journal entries survive reopen and independent removal',
      () async {
        await Future.wait(
          List.generate(
            1000,
            (index) => journal.savePending(_journalCommand('$index')),
          ),
        );
        expect(await operations.restore(), isTrue);
        expect(operations.pendingCommands.length, 1000);
        expect(operations.pending('999')!.operationId, 'operation-999');
        await Future.wait([
          journal.removePending(_journalCommand('999')),
          journal.removePending(_journalCommand('0')),
        ]);
        final retained = await journal.readPending('account-A', 'store-A');
        expect(retained.length, 998);
        expect(retained.map((c) => c.orderId), isNot(contains('999')));
        expect(retained.map((c) => c.orderId), contains('500'));
        expect(gateway.submitted, isEmpty);
      },
    );

    test(
      'failed storage read keeps actions blocked until a successful retry',
      () async {
        storage.failRead = true;
        final first = operations.restore();
        expect(operations.restore(), same(first));
        expect(await first, isFalse);
        operations.observe(_commandReply('A'));
        expect(await operations.act('A', WorkOrderAction.accept), isFalse);
        storage.failRead = false;
        expect(await operations.restore(), isTrue);
        expect(gateway.submitted, isEmpty);
      },
    );

    test(
      'disposal during journal write preserves recovery without transport',
      () async {
        await operations.restore();
        operations.observe(_commandReply('A'));
        storage.holdWrite = Completer<void>();
        final pending = operations.act('A', WorkOrderAction.accept);
        await _drainOrderJournal();
        operations.dispose();
        storage.holdWrite!.complete();
        expect(await pending, isFalse);
        expect(gateway.submitted, isEmpty);
        expect(
          (await journal.readPending('account-A', 'store-A')).single.orderId,
          'A',
        );
      },
    );

    test('recovery must complete before actions or session binding', () async {
      operations.observe(_commandReply('A'));
      expect(await operations.act('A', WorkOrderAction.accept), isFalse);
      expect(operations.restorePending(_journalCommand('A')), isFalse);
      final work = WorkSession(contactDraftStore: _CommandAccountStore())
        ..activeWorkspace = _commandStore
        ..workspaceId = 'store-A';
      expect(work.bindWorkspaceOrderOperations(operations), isFalse);
      expect(await operations.restore(), isTrue);
      expect(work.bindWorkspaceOrderOperations(operations), isTrue);
      expect(gateway.submitted, isEmpty);
      work.dispose();
    });

    test('simultaneous instances retain A and B without overwrite', () async {
      final other = SecureWorkOrderPendingStore(
        storage: storage,
        currentAccount: () => account,
      );
      final a = _journalCommand('A'), b = _journalCommand('B');
      await Future.wait([journal.savePending(a), other.savePending(b)]);
      expect(
        (await journal.readPending(
          'account-A',
          'store-A',
        )).map((c) => c.orderId),
        ['A', 'B'],
      );
      await Future.wait([
        journal.removePending(a),
        other.savePending(_journalCommand('C')),
      ]);
      expect(
        (await journal.readPending(
          'account-A',
          'store-A',
        )).map((c) => c.orderId),
        ['B', 'C'],
      );
    });

    test('account and Store keys cannot collide through separators', () async {
      account = 'A.B';
      await journal.savePending(
        _journalCommand('first', account: 'A.B', store: 'C'),
      );
      account = 'A';
      await journal.savePending(
        _journalCommand('second', account: 'A', store: 'B.C'),
      );
      expect(storage.values.length, 2);
      expect((await journal.readPending('A', 'B.C')).single.orderId, 'second');
      await expectLater(
        journal.readPending('A.B', 'C'),
        throwsA(isA<WorkGatewayException>()),
      );
      account = 'A.B';
      expect((await journal.readPending('A.B', 'C')).single.orderId, 'first');
    });

    test(
      'duplicate save is idempotent but changed payload and stale remove fail',
      () async {
        final original = _journalCommand('A');
        await journal.savePending(original);
        await journal.savePending(original);
        expect(storage.writes.length, 1);
        await expectLater(
          journal.savePending(_journalCommand('A', revision: 2)),
          throwsFormatException,
        );
        await expectLater(
          journal.savePending(
            _journalCommand('B', operation: original.operationId),
          ),
          throwsFormatException,
        );
        await expectLater(
          journal.removePending(_journalCommand('A', operation: 'new')),
          throwsFormatException,
        );
        expect(
          (await journal.readPending(
            'account-A',
            'store-A',
          )).single.expectedRevision,
          1,
        );
      },
    );

    test(
      'corruption remains intact and recovery fails closed without partial load',
      () async {
        await journal.savePending(_journalCommand('A'));
        final key = storage.values.keys.single;
        final good = storage.values[key]!;
        for (final bad in [
          '{broken',
          jsonEncode({...jsonDecode(good) as Map, 'version': 99}),
          jsonEncode({...jsonDecode(good) as Map, 'accountScope': 'other'}),
          jsonEncode({
            ...jsonDecode(good) as Map,
            'entries': [
              ...(jsonDecode(good)['entries'] as List),
              {'orderId': 'broken'},
            ],
          }),
        ]) {
          storage.values[key] = bad;
          expect(await operations.restore(), isFalse);
          expect(operations.pendingCommands, isEmpty);
          expect(operations.recoveryReady, isFalse);
          expect(storage.values[key], bad);
        }
        storage.values[key] = good;
        expect(await operations.restore(), isTrue);
        expect(operations.pending('A')!.operationId, 'operation-A');
      },
    );

    test(
      'write failure never submits and retry only asks original status',
      () async {
        expect(await operations.restore(), isTrue);
        operations.observe(_commandReply('A'));
        storage.failWrite = true;
        expect(await operations.act('A', WorkOrderAction.accept), isFalse);
        final original = operations.pending('A')!;
        expect(gateway.submitted, isEmpty);
        expect(operations.state('A'), WorkOrderOperationState.uncertain);
        storage.failWrite = false;
        final retry = operations.retry('A');
        gateway.replies.single.complete(
          _commandReply(
            'A',
            command: original,
            state: WorkOrderReplyState.rejected,
          ),
        );
        expect(await retry, isFalse);
        expect(gateway.reconciled.single, same(original));
        expect(operations.pending('A'), isNull);
        expect(gateway.submitted, isEmpty);
      },
    );

    test(
      'relaunch restores original identity and reconciles without submitting',
      () async {
        expect(await operations.restore(), isTrue);
        operations.observe(_commandReply('A'));
        final sending = operations.act('A', WorkOrderAction.accept);
        await _drainOrderJournal();
        final command = gateway.submitted.single;
        expect(
          (await journal.readPending(
            'account-A',
            'store-A',
          )).single.operationId,
          command.operationId,
        );
        gateway.responses.single.completeError(StateError('offline'));
        expect(await sending, isFalse);
        operations.dispose();
        operations = WorkOrderOperations(
          accountScope: 'account-A',
          workspaceId: 'store-A',
          gateway: gateway,
          pendingStore: journal,
        );
        expect(await operations.restore(), isTrue);
        expect(operations.order('A'), isNull);
        expect(operations.state('A'), WorkOrderOperationState.uncertain);
        final retry = operations.retry('A');
        expect(gateway.reconciled.single.operationId, command.operationId);
        gateway.replies.single.complete(
          _commandReply('A', command: command, revision: 2, stage: 'Preparing'),
        );
        expect(await retry, isTrue);
        expect(await journal.readPending('account-A', 'store-A'), isEmpty);
        expect(gateway.submitted.length, 1);
      },
    );

    test(
      'ack journal failure retains lock and newer snapshot without resubmitting',
      () async {
        await operations.restore();
        operations.observe(_commandReply('A'));
        final sending = operations.act('A', WorkOrderAction.accept);
        await _drainOrderJournal();
        final command = gateway.submitted.single;
        storage.failWrite = true;
        gateway.responses.single.complete(
          _commandReply('A', command: command, revision: 2, stage: 'Preparing'),
        );
        expect(await sending, isFalse);
        expect(operations.order('A')!.order!.stage, 'Preparing');
        expect(operations.pending('A'), same(command));
        expect(await operations.act('A', WorkOrderAction.ready), isFalse);
        storage.failWrite = false;
        final retry = operations.retry('A');
        gateway.replies.single.complete(
          _commandReply('A', command: command, revision: 2, stage: 'Preparing'),
        );
        expect(await retry, isTrue);
        expect(operations.pending('A'), isNull);
        expect(gateway.submitted.length, 1);
      },
    );

    test(
      'account change during native write cannot send the old account action',
      () async {
        await operations.restore();
        operations.observe(_commandReply('A'));
        storage.holdWrite = Completer<void>();
        final sending = operations.act('A', WorkOrderAction.accept);
        await _drainOrderJournal();
        account = 'account-B';
        storage.holdWrite!.complete();
        expect(await sending, isFalse);
        expect(gateway.submitted, isEmpty);
        expect(await journal.readPending('account-B', 'store-A'), isEmpty);
        account = 'account-A';
        expect(
          (await journal.readPending('account-A', 'store-A')).single.orderId,
          'A',
        );
      },
    );

    test(
      'timed-out native write stays serialized until it actually completes',
      () async {
        operations.dispose();
        operations = WorkOrderOperations(
          accountScope: 'account-A',
          workspaceId: 'store-A',
          gateway: gateway,
          pendingStore: journal,
          timeout: const Duration(milliseconds: 20),
        );
        await operations.restore();
        operations.observe(_commandReply('A'));
        storage.holdWrite = Completer<void>();
        expect(await operations.act('A', WorkOrderAction.accept), isFalse);
        final second = journal.savePending(_journalCommand('B'));
        await _drainOrderJournal();
        expect(storage.writes.length, 1);
        storage.holdWrite!.complete();
        await second;
        expect(
          (await journal.readPending(
            'account-A',
            'store-A',
          )).map((c) => c.orderId),
          ['A', 'B'],
        );
        expect(gateway.submitted, isEmpty);
      },
    );
  });

  group('DASH04 scoped order operations', () {
    late _CommandGateway gateway;
    late WorkOrderOperations operations;
    setUp(() {
      gateway = _CommandGateway();
      operations = WorkOrderOperations(
        accountScope: 'account-A',
        workspaceId: 'store-A',
        gateway: gateway,
      );
    });
    tearDown(() {
      if (!operations.isDisposed) operations.dispose();
    });

    WorkSession commandSession([ReviewWorkGateway? legacy]) {
      final work =
          WorkSession(
              gateway: legacy,
              contactDraftStore: _CommandAccountStore(),
            )
            ..activeWorkspace = _commandStore
            ..workspaceId = 'store-A';
      expect(work.bindWorkspaceOrderOperations(operations), isTrue);
      addTearDown(work.dispose);
      return work;
    }

    test(
      'session scoped order cannot use legacy timing pickup or delivery effects',
      () async {
        final legacy = _OrderTimeGateway();
        final work = commandSession(legacy);
        operations.observe(_commandReply('A'));
        work.selectWorkspaceOrder('A');
        expect(work.orderTimeServiceAvailable, isFalse);
        expect(await work.requestWorkspaceOrderTime('A', 2), isFalse);
        expect(legacy.requests, isEmpty);
        operations.observe(
          _commandReply('A', revision: 2, stage: 'Delivery requested'),
        );
        expect(await work.verifyWorkspaceHandover('123456'), isFalse);
        await work.retryWorkspaceDeliveryAssignment();
        operations.observe(
          _commandReply('A', revision: 3, stage: 'Ready for pickup'),
        );
        expect(await work.verifyWorkspacePickup('123456'), isFalse);
        expect(legacy.handoverCalls, 0);
        expect(legacy.deliveryAssignmentCalls, 0);
        expect(legacy.operationalSaveCalls, 0);
        expect(work.workspaceInvoices, isEmpty);
        expect(work.workspaceSalesToday, 0);
      },
    );

    test(
      'session A reply cannot replace selected B or replay stock and money',
      () async {
        final legacy = ReviewWorkGateway();
        final work = commandSession(legacy);
        operations.observe(_commandReply('A'));
        operations.observe(_commandReply('B'));
        expect(work.currentWorkspaceOrderId, isNull);
        expect(work.selectWorkspaceOrder('A'), isTrue);
        final a = work.submitWorkspaceOrderAction('A', WorkOrderAction.accept);
        expect(work.selectWorkspaceOrder('B'), isTrue);
        final b = work.submitWorkspaceOrderAction('B', WorkOrderAction.accept);
        gateway.responses.first.complete(
          _commandReply(
            'A',
            command: gateway.submitted.first,
            revision: 2,
            stage: 'Preparing',
          ),
        );
        expect(await a, isTrue);
        expect(work.currentWorkspaceOrderId, 'B');
        expect(work.workspaceOrderStage, 'Confirmed');
        expect(work.workspaceOrderCustomer, 'Customer B');
        gateway.responses.last.complete(
          _commandReply(
            'B',
            command: gateway.submitted.last,
            revision: 2,
            stage: 'Preparing',
          ),
        );
        expect(await b, isTrue);
        expect(work.workspaceOrderStage, 'Preparing');
        expect(
          work.workspaceOrders.every((o) => o.stage == 'Preparing'),
          isTrue,
        );
        expect(work.workspaceSalesToday, 0);
        expect(work.workspaceSettlementBalance, 0);
        expect(work.workspaceInvoices, isEmpty);
        expect(work.workspaceStockMovements, isEmpty);
        expect(legacy.operationalSaveCalls, 0);
      },
    );

    test(
      'session uncertain A remains retryable while B continues packing',
      () async {
        final work = commandSession();
        operations.observe(_commandReply('A'));
        operations.observe(_commandReply('B', stage: 'Preparing'));
        work.selectWorkspaceOrder('A');
        final a = work.submitWorkspaceOrderAction('A', WorkOrderAction.accept);
        gateway.responses.single.completeError(StateError('unknown'));
        expect(await a, isFalse);
        expect(work.selectWorkspaceOrder('B'), isTrue);
        expect(work.workspacePackingLines, isNotEmpty);
        for (final line in work.workspacePackingLines) {
          expect(
            work.setWorkspaceOrderPackingLine(
              storeId: 'store-A',
              orderId: 'B',
              lineId: line.id,
              quantity: line.quantity,
              packed: true,
            ),
            isTrue,
          );
        }
        expect(work.workspacePackingComplete, isTrue);
        final b = work.submitWorkspaceOrderAction('B', WorkOrderAction.ready);
        gateway.responses.last.complete(
          _commandReply(
            'B',
            command: gateway.submitted.last,
            revision: 2,
            stage: 'Ready',
          ),
        );
        expect(await b, isTrue);
        final retry = work.retryWorkspaceOrderAction('A');
        gateway.replies.single.complete(
          _commandReply(
            'A',
            command: gateway.reconciled.single,
            revision: 2,
            stage: 'Preparing',
          ),
        );
        expect(await retry, isTrue);
        expect(work.currentWorkspaceOrderId, 'B');
        expect(work.workspaceOrderStage, 'Ready');
        expect(work.errorMessage, isNull);
      },
    );

    test(
      'session hidden Store updates restore exact selection on return',
      () async {
        final work = commandSession();
        operations.observe(_commandReply('A'));
        work.selectWorkspaceOrder('A');
        final a = work.submitWorkspaceOrderAction('A', WorkOrderAction.accept);
        work.activateWorkspace(_scopeSecondStore);
        expect(work.activeWorkspace?.id, _scopeSecondStore.id);
        gateway.responses.single.complete(
          _commandReply(
            'A',
            command: gateway.submitted.single,
            revision: 2,
            stage: 'Preparing',
          ),
        );
        expect(await a, isTrue);
        expect(work.workspaceOrders, isEmpty);
        work.activateWorkspace(_commandStore);
        expect(work.currentWorkspaceOrderId, 'A');
        expect(work.workspaceOrderStage, 'Preparing');
      },
    );

    test(
      'session refuses cross-account binding and legacy full-store overwrite',
      () {
        final wrong = WorkSession(
          contactDraftStore: _CommandAccountStore('account-B'),
        )..activeWorkspace = _commandStore;
        addTearDown(wrong.dispose);
        expect(wrong.bindWorkspaceOrderOperations(operations), isFalse);
        final legacy = ReviewWorkGateway();
        final work = commandSession(legacy);
        operations.observe(_commandReply('A'));
        work.saveWorkspaceAvailability(
          acceptingOrders: true,
          fulfilmentMode: 'Pickup',
          busyMinutes: 0,
          reopensAt: '',
        );
        expect(legacy.operationalSaveCalls, 0);
        expect(
          work.workspaceOperationsSyncError,
          contains('remain on this device'),
        );
        expect(operations.order('A')!.revision, 1);
      },
    );

    test('order snapshots freeze quantities and reject invalid counts', () {
      final quantities = <String, int>{'sku-A': 2};
      final snapshot = _commandReply('A', quantities: quantities);
      quantities['sku-A'] = 999;
      expect(operations.observe(snapshot), isTrue);
      expect(operations.order('A')!.order!.quantities['sku-A'], 2);
      expect(
        () => operations.order('A')!.order!.quantities['sku-A'] = 3,
        throwsUnsupportedError,
      );
      expect(
        operations.observe(_commandReply('B', quantities: const {'sku-A': -1})),
        isFalse,
      );
    });

    test(
      'ready and explicit rejection carry exact intent and revision',
      () async {
        operations.observe(_commandReply('A', stage: 'Preparing', revision: 7));
        final ready = operations.act('A', WorkOrderAction.ready);
        expect(gateway.submitted.single.expectedRevision, 7);
        expect(gateway.submitted.single.action, WorkOrderAction.ready);
        gateway.responses.single.complete(
          _commandReply(
            'A',
            command: gateway.submitted.single,
            revision: 8,
            stage: 'Ready',
          ),
        );
        expect(await ready, isTrue);
        operations.observe(_commandReply('B', revision: 3));
        final reject = operations.act(
          'B',
          WorkOrderAction.reject,
          reason: '  Item unavailable  ',
        );
        expect(gateway.submitted.last.reason, 'Item unavailable');
        expect(gateway.submitted.last.expectedRevision, 3);
        gateway.responses.last.complete(
          _commandReply(
            'B',
            command: gateway.submitted.last,
            revision: 4,
            stage: 'Cancelled',
          ),
        );
        expect(await reject, isTrue);
        expect(operations.order('A')!.order!.stage, 'Ready');
        expect(operations.order('B')!.order!.stage, 'Cancelled');
      },
    );

    test(
      'account disposal after notification ignores late replies and further actions',
      () async {
        final closed = WorkOrderOperations(
          accountScope: 'account-A',
          workspaceId: 'store-A',
          gateway: gateway,
        );
        closed.observe(_commandReply('A'));
        // Dispose after this notification unwinds; an already-sent response must
        // still be ignored. Synchronous disposal inside notifyListeners is illegal.
        closed.addListener(() => scheduleMicrotask(closed.dispose));
        final result = closed.act('A', WorkOrderAction.accept);
        await Future<void>.delayed(Duration.zero);
        gateway.responses.single.complete(
          _commandReply(
            'A',
            command: gateway.submitted.single,
            revision: 2,
            stage: 'Preparing',
          ),
        );
        expect(await result, isFalse);
        expect(await closed.act('B', WorkOrderAction.accept), isFalse);
        expect(gateway.submitted.length, 1);
      },
    );

    test(
      'restored operation reconciles without resubmission or local success',
      () async {
        const command = WorkOrderCommand(
          accountScope: 'account-A',
          workspaceId: 'store-A',
          orderId: 'A',
          operationId: 'retained-A',
          expectedRevision: 3,
          action: WorkOrderAction.accept,
        );
        expect(operations.restorePending(command), isTrue);
        expect(operations.restorePending(command), isFalse);
        expect(operations.order('A'), isNull);
        expect(operations.state('A'), WorkOrderOperationState.uncertain);
        final retry = operations.retry('A');
        expect(gateway.submitted, isEmpty);
        expect(gateway.reconciled.single, same(command));
        gateway.replies.single.complete(
          _commandReply('A', command: command, revision: 4, stage: 'Preparing'),
        );
        expect(await retry, isTrue);
        expect(operations.order('A')!.revision, 4);
      },
    );

    for (final wrong in [
      'account',
      'store',
      'operation',
      'revision',
      'reason',
    ]) {
      test('restored $wrong mismatch fails closed', () {
        expect(
          operations.restorePending(
            WorkOrderCommand(
              accountScope: wrong == 'account' ? 'account-B' : 'account-A',
              workspaceId: wrong == 'store' ? 'store-B' : 'store-A',
              orderId: 'A',
              operationId: wrong == 'operation' ? '' : 'retained-A',
              expectedRevision: wrong == 'revision' ? -1 : 1,
              action: wrong == 'reason'
                  ? WorkOrderAction.reject
                  : WorkOrderAction.accept,
            ),
          ),
          isFalse,
        );
        expect(operations.pendingCommands, isEmpty);
        expect(gateway.submitted, isEmpty);
      });
    }

    test(
      'timeout retains operation and ignores a late transport completion',
      () async {
        final short = WorkOrderOperations(
          accountScope: 'account-A',
          workspaceId: 'store-A',
          gateway: gateway,
          timeout: const Duration(milliseconds: 5),
        );
        addTearDown(short.dispose);
        short.observe(_commandReply('A'));
        expect(await short.act('A', WorkOrderAction.accept), isFalse);
        final command = short.pending('A')!;
        expect(short.state('A'), WorkOrderOperationState.uncertain);
        gateway.responses.single.complete(
          _commandReply('A', command: command, revision: 2, stage: 'Preparing'),
        );
        await Future<void>.delayed(Duration.zero);
        expect(short.order('A')!.revision, 1);
        expect(short.pending('A'), same(command));
      },
    );

    test(
      'disposed account ignores delayed reply and sends no further request',
      () async {
        final closed = WorkOrderOperations(
          accountScope: 'account-A',
          workspaceId: 'store-A',
          gateway: gateway,
        );
        closed.observe(_commandReply('A'));
        final action = closed.act('A', WorkOrderAction.accept);
        closed.dispose();
        gateway.responses.single.complete(
          _commandReply(
            'A',
            command: gateway.submitted.single,
            revision: 2,
            stage: 'Preparing',
          ),
        );
        expect(await action, isFalse);
        expect(await closed.retry('A'), isFalse);
        expect(gateway.reconciled, isEmpty);
        expect(closed.order('A'), isNull);
        expect(closed.pendingCommands, isEmpty);
      },
    );

    test('1000 independent pending orders resolve out of order once', () async {
      final futures = <Future<bool>>[];
      for (var i = 0; i < 1000; i++) {
        expect(operations.observe(_commandReply('order-$i')), isTrue);
        futures.add(operations.act('order-$i', WorkOrderAction.accept));
      }
      expect(gateway.submitted.length, 1000);
      expect(gateway.submitted.map((c) => c.operationId).toSet().length, 1000);
      expect(operations.pendingCommands.length, 1000);
      expect(await operations.act('order-0', WorkOrderAction.accept), isFalse);
      for (var i = 999; i >= 0; i--) {
        gateway.responses[i].complete(
          _commandReply(
            'order-$i',
            command: gateway.submitted[i],
            revision: 2,
            stage: 'Preparing',
          ),
        );
      }
      expect(await Future.wait(futures), everyElement(isTrue));
      expect(operations.pendingCommands, isEmpty);
      for (var i = 0; i < 1000; i++) {
        expect(operations.order('order-$i')!.order!.stage, 'Preparing');
        expect(operations.state('order-$i'), isNull);
      }
    });

    test(
      'uncertain A does not block B; retry only reconciles A identity',
      () async {
        operations.observe(_commandReply('A'));
        operations.observe(_commandReply('B'));
        final a = operations.act('A', WorkOrderAction.accept);
        gateway.responses[0].completeError(StateError('unknown response'));
        expect(await a, isFalse);
        final original = operations.pending('A')!;
        expect(operations.state('A'), WorkOrderOperationState.uncertain);
        expect(
          await operations.act(
            'A',
            WorkOrderAction.reject,
            reason: 'Unavailable',
          ),
          isFalse,
        );
        final b = operations.act('B', WorkOrderAction.accept);
        gateway.responses[1].complete(
          _commandReply(
            'B',
            command: gateway.submitted[1],
            revision: 2,
            stage: 'Preparing',
          ),
        );
        expect(await b, isTrue);
        expect(operations.pending('A'), same(original));
        final retry = operations.retry('A');
        expect(gateway.reconciled.single, same(original));
        expect(await operations.retry('A'), isFalse);
        gateway.replies.single.complete(
          _commandReply(
            'A',
            command: original,
            revision: 2,
            stage: 'Preparing',
          ),
        );
        expect(await retry, isTrue);
        expect(gateway.submitted.length, 2);
        expect(operations.pendingCommands, isEmpty);
      },
    );

    for (final mismatch in [
      'account',
      'store',
      'order',
      'operation',
      'revision',
      'missing',
      'pending',
    ]) {
      test(
        'rejects $mismatch acknowledgement without claiming success',
        () async {
          operations.observe(_commandReply('A'));
          final action = operations.act('A', WorkOrderAction.accept);
          final command = gateway.submitted.single;
          gateway.responses.single.complete(
            WorkOrderReply(
              accountScope: mismatch == 'account' ? 'account-B' : 'account-A',
              workspaceId: mismatch == 'store' ? 'store-B' : 'store-A',
              orderId: mismatch == 'order' ? 'B' : 'A',
              operationId: mismatch == 'operation'
                  ? 'unrelated'
                  : command.operationId,
              revision: mismatch == 'revision' ? 1 : 2,
              state: mismatch == 'pending'
                  ? WorkOrderReplyState.pending
                  : WorkOrderReplyState.applied,
              order: mismatch == 'missing'
                  ? null
                  : _commandReply('A', stage: 'Preparing').order,
            ),
          );
          expect(await action, isFalse);
          expect(operations.pending('A'), same(command));
          expect(operations.state('A'), WorkOrderOperationState.uncertain);
          expect(operations.order('A')!.order!.stage, 'Confirmed');
        },
      );
    }

    test('late acknowledgement cannot regress latest snapshot', () async {
      operations.observe(_commandReply('A'));
      final action = operations.act('A', WorkOrderAction.accept);
      final command = gateway.submitted.single;
      operations.observe(_commandReply('A', revision: 4, stage: 'Cancelled'));
      expect(operations.pending('A'), same(command));
      gateway.responses.single.complete(
        _commandReply('A', command: command, revision: 2, stage: 'Preparing'),
      );
      expect(await action, isTrue);
      expect(operations.order('A')!.revision, 4);
      expect(operations.order('A')!.order!.stage, 'Cancelled');
      expect(operations.pending('A'), isNull);
      expect(operations.observe(_commandReply('A', revision: 4)), isFalse);
      expect(operations.observe(_commandReply('A', revision: 3)), isFalse);
    });

    test('authoritative rejection releases only its operation', () async {
      operations.observe(_commandReply('A'));
      final action = operations.act('A', WorkOrderAction.accept);
      gateway.responses.single.complete(
        _commandReply(
          'A',
          command: gateway.submitted.single,
          state: WorkOrderReplyState.rejected,
        ),
      );
      expect(await action, isFalse);
      expect(operations.pendingCommands, isEmpty);
      expect(operations.order('A')!.order!.stage, 'Confirmed');
    });

    test('reject needs reason and collection cannot bypass its flow', () async {
      operations.observe(_commandReply('A'));
      expect(await operations.act('A', WorkOrderAction.reject), isFalse);
      expect(
        await operations.act('A', WorkOrderAction.reject, reason: '  '),
        isFalse,
      );
      expect(await operations.act('A', WorkOrderAction.ready), isFalse);
      operations.observe(
        _commandReply('A', revision: 2, stage: 'Collected', collection: true),
      );
      for (final action in WorkOrderAction.values) {
        expect(
          await operations.act('A', action, reason: 'Unavailable'),
          isFalse,
        );
      }
      expect(gateway.submitted, isEmpty);
    });
  });

  for (final entry in {
    '9829012345': '9829012345',
    ' 9829012345 ': '9829012345',
    '98290 12345': '9829012345',
    '98290-12345': '9829012345',
    '+91 98290 12345': '9829012345',
    '91-98290-12345': '9829012345',
    '919829012345': '9829012345',
    '+919829012345': '9829012345',
    '6123456789': '6123456789',
    '9123456789': '9123456789',
  }.entries) {
    test('REG4559 supported mobile ${entry.key}', () {
      expect(normalizeWorkspaceMobile(entry.key), entry.value);
    });
  }
  for (final value in [
    '',
    '12345',
    '98290123456',
    '0000000000',
    '5123456789',
    'x9829012345',
    '9829012345x',
    'Rakesh · 9829012345',
    '+1 9829012345',
    '00919829012345',
    '+91+9829012345',
    '98290--12345',
    '98290\n12345',
    '98290.12345',
    '९८२९०१२३४५',
    '9829012345 / 9876543210',
  ]) {
    test(
      'REG4559 rejects entire malformed mobile ${value.replaceAll('\n', 'newline')}',
      () {
        expect(normalizeWorkspaceMobile(value), isNull);
      },
    );
  }

  WorkSession liveSession([ReviewWorkGateway? gateway]) {
    final session = WorkSession(gateway: gateway ?? ReviewWorkGateway())
      ..activeWorkspace = const WorkWorkspace(
        id: 'workspace-store-1',
        name: 'Mahadev Fresh Mart',
        profileLabel: 'Grocery / Kirana Shop',
        profileId: 'retailer-grocery',
        area: 'Sardarpura, Jodhpur',
        verified: true,
      )
      ..workspaceId = 'workspace-store-1';
    addTearDown(session.dispose);
    return session;
  }

  WorkSession timingSession(ReviewWorkGateway gateway) {
    final session = liveSession(gateway);
    session.workspaceCatalogueItems.add(_product(stock: 10));
    session.workspaceOrders.add(
      WorkspaceOrderRecord(
        id: 'timing-order',
        customer: 'Asha',
        items: 'Atta',
        quantities: {'atta-5kg': 1},
        amount: 250,
        source: 'App',
        fulfilment: 'Mool delivery',
        payment: 'Paid online',
        address: 'Market road',
        stage: 'Confirmed',
        needsDelivery: true,
        createdAt: DateTime.now(),
        actionDeadline: DateTime.now().add(const Duration(seconds: 60)),
      ),
    );
    expect(session.selectWorkspaceOrder('timing-order'), isTrue);
    return session;
  }

  test(
    'Order time missing service cannot change or publish a deadline',
    () async {
      final session = timingSession(ReviewWorkGateway());
      final before = session.currentWorkspaceOrder;
      expect(
        await session.requestWorkspaceOrderTime('timing-order', 2),
        isFalse,
      );
      expect(session.currentWorkspaceOrder, same(before));
      expect(session.hasPendingOrderTime, isFalse);
      expect(session.errorMessage, contains('current time still applies'));
    },
  );

  test(
    'Order time waits for authority and blocks duplicate state actions',
    () async {
      final gateway = _OrderTimeGateway();
      final completer = Completer<WorkOrderTimeResult>();
      gateway.respond = (_) => completer.future;
      final session = timingSession(gateway);
      final original = session.currentWorkspaceOrder!.actionDeadline;
      final pending = session.requestWorkspaceOrderTime('timing-order', 2);
      expect(session.busy, isTrue);
      expect(session.currentWorkspaceOrder!.actionDeadline, original);
      expect(
        await session.requestWorkspaceOrderTime('timing-order', 5),
        isFalse,
      );
      session.advanceWorkspaceOrder();
      session.cancelWorkspaceOrder();
      expect(session.workspaceOrderStage, 'Confirmed');
      expect(session.workspaceCatalogueItems.single.stock, 10);
      expect(gateway.requests, hasLength(1));
      final result = gateway.approval(gateway.requests.single);
      completer.complete(result);
      expect(await pending, isTrue);
      expect(session.hasPendingOrderTime, isFalse);
      expect(
        session.currentWorkspaceOrder!.actionDeadline,
        result.acceptanceDeadline,
      );
      session.advanceWorkspaceOrder();
      expect(session.workspaceOrderStage, 'Preparing');
      expect(session.workspaceOrderActionDeadline, result.fulfilmentDeadline);
      expect(session.workspaceInvoices, isEmpty);
    },
  );

  test(
    'Order time rejection leaves the original time and no fake approval',
    () async {
      final gateway = _OrderTimeGateway();
      gateway.respond = (r) async => WorkOrderTimeResult(
        workspaceId: r.workspaceId,
        orderId: r.orderId,
        operationId: r.operationId,
        approved: false,
      );
      final session = timingSession(gateway);
      final before = session.currentWorkspaceOrder;
      expect(
        await session.requestWorkspaceOrderTime('timing-order', 2),
        isFalse,
      );
      expect(session.currentWorkspaceOrder, same(before));
      expect(session.hasPendingOrderTime, isFalse);
      expect(session.errorMessage, contains('not approved'));
    },
  );

  test(
    'Order time uncertain retry reuses the original operation and minutes',
    () async {
      final gateway = _OrderTimeGateway();
      gateway.respond = (_) async => throw StateError('lost connection');
      final session = timingSession(gateway);
      final before = session.currentWorkspaceOrder;
      expect(
        await session.requestWorkspaceOrderTime('timing-order', 2),
        isFalse,
      );
      expect(session.hasPendingOrderTime, isTrue);
      expect(session.currentWorkspaceOrder, same(before));
      final first = gateway.requests.single;
      gateway.respond = (r) async => gateway.approval(r);
      expect(
        await session.requestWorkspaceOrderTime('timing-order', 5),
        isTrue,
      );
      expect(gateway.requests.last, same(first));
      expect(gateway.requests.last.additionalMinutes, 2);
    },
  );

  for (final mismatch in [
    'order',
    'store',
    'operation',
    'expired',
    'tooLong',
    'fulfilment',
  ]) {
    test('Order time rejects mismatched or invalid $mismatch result', () async {
      final gateway = _OrderTimeGateway();
      gateway.respond = (r) async => WorkOrderTimeResult(
        workspaceId: mismatch == 'store' ? 'other-store' : r.workspaceId,
        orderId: mismatch == 'order' ? 'other-order' : r.orderId,
        operationId: mismatch == 'operation'
            ? 'other-operation'
            : r.operationId,
        approved: true,
        acceptanceDeadline: mismatch == 'expired'
            ? DateTime.now().subtract(const Duration(seconds: 1))
            : r.expectedAcceptanceDeadline.add(
                Duration(minutes: mismatch == 'tooLong' ? 20 : 2),
              ),
        fulfilmentDeadline: mismatch == 'fulfilment'
            ? r.expectedAcceptanceDeadline
            : r.expectedAcceptanceDeadline.add(const Duration(minutes: 25)),
      );
      final session = timingSession(gateway);
      final before = session.currentWorkspaceOrder;
      expect(
        await session.requestWorkspaceOrderTime('timing-order', 2),
        isFalse,
      );
      expect(session.currentWorkspaceOrder, same(before));
      expect(session.hasPendingOrderTime, isTrue);
      expect(session.workspaceInvoices, isEmpty);
    });
  }

  test('Order time late response cannot update a different store', () async {
    final gateway = _OrderTimeGateway();
    final completer = Completer<WorkOrderTimeResult>();
    gateway.respond = (_) => completer.future;
    final session = timingSession(gateway);
    final pending = session.requestWorkspaceOrderTime('timing-order', 2);
    final request = gateway.requests.single;
    session.activeWorkspace = const WorkWorkspace(
      id: 'other-store',
      name: 'Other',
      profileLabel: 'Retail',
      profileId: 'retailer-speciality',
      area: 'Market',
      verified: true,
    );
    completer.complete(gateway.approval(request));
    expect(await pending, isFalse);
    expect(session.workspaceOrders, isEmpty);
    expect(session.workspaceOrderActionDeadline, isNull);
    expect(session.hasPendingOrderTime, isFalse);
  });

  test('Order time old control cannot extend a deadline locally', () async {
    final session = timingSession(ReviewWorkGateway());
    final before = session.currentWorkspaceOrder;
    session.extendWorkspaceOrder(10);
    await Future<void>.delayed(Duration.zero);
    expect(session.currentWorkspaceOrder, same(before));
    expect(session.workspaceOrderExtraMinutes, 0);
  });

  test('Order time expired or wrong order cannot create a request', () async {
    final gateway = _OrderTimeGateway();
    final session = timingSession(gateway);
    expect(
      await session.requestWorkspaceOrderTime('another-order', 2),
      isFalse,
    );
    final expired = session.currentWorkspaceOrder!.copyWith(
      actionDeadline: DateTime.now().subtract(const Duration(seconds: 1)),
    );
    session.workspaceOrders[0] = expired;
    session.workspaceOrderActionDeadline = expired.actionDeadline;
    expect(await session.requestWorkspaceOrderTime('timing-order', 2), isFalse);
    expect(gateway.requests, isEmpty);
    expect(session.currentWorkspaceOrder, same(expired));
  });

  test(
    'Order time stale stage cannot be overwritten by a late reply',
    () async {
      final gateway = _OrderTimeGateway();
      final completer = Completer<WorkOrderTimeResult>();
      gateway.respond = (_) => completer.future;
      final session = timingSession(gateway);
      final pending = session.requestWorkspaceOrderTime('timing-order', 2);
      final changed = session.currentWorkspaceOrder!.copyWith(
        stage: 'Cancelled',
      );
      session.workspaceOrders[0] = changed;
      session.workspaceOrderStage = 'Cancelled';
      completer.complete(gateway.approval(gateway.requests.single));
      expect(await pending, isFalse);
      expect(session.currentWorkspaceOrder, same(changed));
      expect(session.workspaceOrderStage, 'Cancelled');
    },
  );

  test(
    'Order deadline session guard rejects 100 expired orders without effects',
    () async {
      final gateway = _OrderTimeGateway();
      final session = timingSession(gateway);
      final expired = DateTime.now().subtract(const Duration(seconds: 1));
      final original = session.currentWorkspaceOrder!;
      for (var i = 0; i < 100; i++) {
        session.workspaceOrders.add(
          WorkspaceOrderRecord(
            id: 'EXPIRED-$i',
            customer: 'Customer $i',
            items: original.items,
            quantities: original.quantities,
            amount: original.amount,
            source: original.source,
            fulfilment: original.fulfilment,
            payment: original.payment,
            address: original.address,
            stage: 'Confirmed',
            needsDelivery: true,
            createdAt: original.createdAt,
            actionDeadline: expired,
          ),
        );
        expect(session.selectWorkspaceOrder('EXPIRED-$i'), isTrue);
        session.advanceWorkspaceOrder();
        expect(session.currentWorkspaceOrder!.stage, 'Confirmed');
        expect(session.currentWorkspaceOrder!.stockReserved, isFalse);
        expect(
          session.errorMessage,
          'Acceptance time ended. Waiting for an order update.',
        );
      }
      await Future<void>.delayed(Duration.zero);
      expect(session.workspaceCatalogueItems.single.stock, 10);
      expect(session.workspaceInvoices, isEmpty);
      expect(session.workspaceStockMovements, isEmpty);
      expect(gateway.operationalSaveCalls, 0);
      expect(gateway.requests, isEmpty);
    },
  );

  test('Order deadline missing target is not replaced by a local promise', () {
    final session = timingSession(ReviewWorkGateway());
    session.advanceWorkspaceOrder();
    expect(session.workspaceOrderStage, 'Preparing');
    expect(session.workspaceOrderActionDeadline, isNull);
    expect(session.currentWorkspaceOrder!.actionDeadline, isNull);
    expect(session.currentWorkspaceOrder!.fulfilmentDeadline, isNull);
    expect(session.workspaceCatalogueItems.single.stock, 9);
    for (final line in session.workspacePackingLines) {
      session.setWorkspacePackingLine(line.id, true);
    }
    session.advanceWorkspaceOrder();
    expect(session.workspaceOrderStage, 'Ready');
    expect(session.currentWorkspaceOrder!.actionDeadline, isNull);
    expect(session.currentWorkspaceOrder!.fulfilmentDeadline, isNull);
  });

  test(
    'Order deadline preserves supplied target and rejects a stale stage',
    () {
      final session = timingSession(ReviewWorkGateway());
      final target = DateTime.now().add(const Duration(minutes: 10));
      session.workspaceOrders[0] = session.currentWorkspaceOrder!.copyWith(
        fulfilmentDeadline: target,
      );
      session.advanceWorkspaceOrder();
      expect(session.workspaceOrderActionDeadline, target);
      expect(session.currentWorkspaceOrder!.actionDeadline, target);
      final changed = session.currentWorkspaceOrder!.copyWith(
        stage: 'Reassigned',
      );
      session.workspaceOrders[0] = changed;
      session.advanceWorkspaceOrder();
      expect(session.currentWorkspaceOrder, same(changed));
      expect(
        session.errorMessage,
        'This order has changed. Review its current status.',
      );
      expect(session.workspaceCatalogueItems.single.stock, 9);
      expect(session.workspaceInvoices, isEmpty);
    },
  );

  test('Order deadline clear preserves identity and purchased information', () {
    final session = timingSession(ReviewWorkGateway());
    final original = session.currentWorkspaceOrder!;
    final changed = original.copyWith(clearActionDeadline: true);
    expect(changed.id, original.id);
    expect(changed.createdAt, original.createdAt);
    expect(changed.quantities, original.quantities);
    expect(changed.amount, original.amount);
    expect(changed.actionDeadline, isNull);
    expect(original.copyWith().actionDeadline, original.actionDeadline);
  });

  test('orders reserve stock once and cancellation restores it', () async {
    final gateway = ReviewWorkGateway();
    final session = liveSession(gateway);
    session.addOrUpdateWorkspaceProduct(_product(stock: 10));
    session.prepareWorkspaceOrder(source: 'Phone', fulfilment: 'At the shop');
    session.adjustWorkspaceOrderQuantity('atta-5kg', 2);
    session.saveWorkspaceOrderDraft(
      customer: '9829012321',
      source: 'Phone',
      fulfilment: 'At the shop',
      payment: 'Cash',
      address: '',
    );

    expect(session.workspaceOrders, hasLength(1));
    expect(session.workspaceOrders.single.stage, 'Confirmed');
    expect(session.workspaceOrderActionDeadline, isNull);
    expect(session.workspaceOrders.single.actionDeadline, isNull);
    session.advanceWorkspaceOrder();
    expect(session.workspaceOrderStage, 'Preparing');
    expect(session.workspaceCatalogueItems.single.stock, 8);
    expect(session.currentWorkspaceOrder?.stockReserved, isTrue);

    session.cancelWorkspaceOrder();
    expect(session.workspaceOrderStage, 'Cancelled');
    expect(session.workspaceCatalogueItems.single.stock, 10);
    expect(session.currentWorkspaceOrder?.stockReserved, isFalse);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(gateway.operationalSaveCalls, greaterThanOrEqualTo(3));
  });

  test(
    'delivery needs an address and completes only after customer OTP',
    () async {
      final gateway = ReviewWorkGateway();
      final session = liveSession(gateway);
      session.addOrUpdateWorkspaceProduct(_product(stock: 10));
      session.prepareWorkspaceOrder(
        source: 'Phone',
        fulfilment: 'Mool delivery',
      );
      session.adjustWorkspaceOrderQuantity('atta-5kg', 1);
      session.saveWorkspaceOrderDraft(
        customer: '9829012321',
        source: 'Phone',
        fulfilment: 'Mool delivery',
        payment: 'Pay on delivery',
        address: '',
      );
      session.advanceWorkspaceOrder();
      for (final line in session.workspacePackingLines) {
        session.setWorkspacePackingLine(line.id, true);
      }
      session.advanceWorkspaceOrder();
      session.advanceWorkspaceOrder();
      expect(session.workspaceOrderStage, 'Ready');
      expect(session.errorMessage, contains('delivery address'));

      session.workspaceOrderAddress = '21 Residency Road, Jodhpur';
      session.advanceWorkspaceOrder();
      expect(session.workspaceOrderStage, 'Delivery requested');
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(gateway.deliveryAssignmentCalls, 1);
      expect(session.workspaceDeliveryAssignment?.partnerName, isNotEmpty);

      expect(await session.verifyWorkspaceHandover('000000'), isFalse);
      expect(session.workspaceOrderStage, 'Delivery requested');
      expect(await session.verifyWorkspaceHandover('123456'), isTrue);
      expect(session.workspaceOrderStage, 'Completed');
      expect(session.workspaceCompletedSalesCount, 1);
      expect(gateway.handoverCalls, 2);
    },
  );

  test('large Store amounts retain the full eligible balance', () {
    final session = liveSession()
      ..workspacePlatformAdjustments = 100
      ..workspaceDeliveryAdjustments = 200
      ..workspaceRefunds = 300
      ..workspaceTaxWithheld = 400;
    for (final amount in [
      0,
      1,
      999,
      10000000,
      1000000000,
      2147483647,
      2147483648,
      2147483649,
      9990000000,
      10000000000,
      100000000000,
    ]) {
      session.workspaceSettlementBalance = amount + 1000;
      expect(session.workspaceSettlementEligible, amount, reason: '$amount');
      expect(session.workspaceSettlementBalance, amount + 1000);
    }
    session.workspaceSettlementBalance = 999;
    expect(session.workspaceSettlementEligible, 0);
  });

  test('large Store amounts preserve partial settlement remainder', () async {
    final gateway = ReviewWorkGateway();
    final session = liveSession(gateway)
      ..workspaceSettlementBalance = 10000000000;
    await session.requestWorkspaceSettlement(amount: 10000000);
    expect(gateway.settlementCalls, 1);
    expect(session.workspaceSettlementRequested, 10000000);
    expect(session.workspaceSettlementBalance, 9990000000);
    expect(session.workspaceSettlementEligible, 9990000000);
  });

  test('large Store amounts preserve group purchase savings and balance', () {
    const group = WorkspaceGroupBuy(
      id: 'range-test',
      productName: 'Commodity',
      specification: 'Per kg',
      leadRetailer: 'Test store',
      confirmedRetailers: ['Test store'],
      targetQuantity: 1000000,
      securedQuantity: 1000000,
      unitLabel: 'kg',
      regularUnitPrice: 200000,
      groupUnitPrice: 100000,
      facilitationFee: 123,
      deliveryFee: 456,
      confirmationAmount: 10000000,
      closingLabel: 'Tomorrow',
      storeDeliveryLabel: 'After confirmation',
      paymentConfirmed: false,
    );
    expect(group.goodsValue, 100000000000);
    expect(group.deliveredTotal, 100000000579);
    expect(group.netSaving, 99999999421);
    expect(group.balanceDue, 99990000579);
    expect(group.paymentConfirmed, isFalse);
  });

  test('settlement uses only the eligible completed-sale balance', () async {
    final gateway = ReviewWorkGateway();
    final session = liveSession(gateway)
      ..workspaceSettlementBalance = 1000
      ..workspacePlatformAdjustments = 100
      ..workspaceRefunds = 50
      ..workspaceTaxWithheld = 50;

    expect(session.workspaceSettlementEligible, 800);
    await session.requestWorkspaceSettlement();
    expect(gateway.settlementCalls, 1);
    expect(session.workspaceSettlementRequested, 800);
    expect(session.workspaceSettlementBalance, 200);
    expect(session.workspaceSettlementEligible, 0);
    expect(session.workspaceSettlementReference, startsWith('SET-'));
  });

  test('pickup never requests delivery and creates an invoice at handover', () {
    final session = liveSession();
    session.addOrUpdateWorkspaceProduct(_product(stock: 10));
    session.prepareWorkspaceOrder(source: 'App', fulfilment: 'Pickup');
    session.adjustWorkspaceOrderQuantity('atta-5kg', 1);
    session.saveWorkspaceOrderDraft(
      customer: '9829012321',
      source: 'App',
      fulfilment: 'Pickup',
      payment: 'Paid online',
      address: '',
    );

    expect(session.workspaceOrderNeedsDelivery, isFalse);
    session.advanceWorkspaceOrder();
    for (final line in session.workspacePackingLines) {
      session.setWorkspacePackingLine(line.id, true);
    }
    session.advanceWorkspaceOrder();
    expect(session.workspaceOrderStage, 'Ready for pickup');
    expect(session.workspaceDeliveryAssignment, isNull);
    session.advanceWorkspaceOrder();
    expect(session.workspaceOrderStage, 'Completed');
    expect(session.latestWorkspaceInvoice?.customer, '9829012321');
  });

  for (final stage in [
    'Confirmed',
    'Preparing',
    'Ready',
    'Ready for pickup',
    'Delivering',
    'Completed',
    'Cancelled',
  ]) {
    for (final expired in [false, true]) {
      test('counter isolation protects $stage App order expired=$expired', () {
        final gateway = ReviewWorkGateway();
        final session = timingSession(gateway);
        final order = session.currentWorkspaceOrder!.copyWith(
          stage: stage,
          actionDeadline: DateTime.now().add(
            Duration(seconds: expired ? -60 : 60),
          ),
        );
        session.workspaceOrders[0] = order;
        // A stale/mutated form must not override the stored order's origin.
        session.workspaceOrderSource = 'Counter';
        session.workspaceOrderStage = 'Confirmed';
        final quantities = Map.of(session.workspaceOrderQuantities);
        session.adjustWorkspaceOrderQuantity('atta-5kg', 1);
        expect(session.workspaceOrderQuantities, quantities);
        expect(
          session.saveWorkspaceOrderDraft(
            customer: '9829012345',
            source: 'Counter',
            fulfilment: 'At the shop',
            payment: 'Cash',
            address: '',
          ),
          isFalse,
        );
        expect(session.completeWorkspaceCounterSale(), isNull);
        expect(session.currentWorkspaceOrder, same(order));
        expect(session.workspaceOrderCustomer, 'Asha');
        expect(session.workspaceInvoices, isEmpty);
        expect(session.workspaceStockMovements, isEmpty);
        expect(session.workspaceCatalogueItems.single.stock, 10);
        expect(session.workspaceSalesToday, 0);
        expect(session.workspaceCompletedSalesCount, 0);
        expect(gateway.lastOperationalSnapshot, isNull);
      });
    }
  }

  test(
    'counter isolation allows a separate sale without changing App order',
    () {
      final session = timingSession(ReviewWorkGateway());
      final incoming = session.currentWorkspaceOrder!;
      expect(
        session.prepareWorkspaceOrder(
          source: 'Counter',
          fulfilment: 'At the shop',
        ),
        isTrue,
      );
      session.adjustWorkspaceOrderQuantity('atta-5kg', 2);
      expect(
        session.saveWorkspaceOrderDraft(
          customer: '9829012345',
          source: 'Counter',
          fulfilment: 'At the shop',
          payment: 'Cash',
          address: '',
        ),
        isTrue,
      );
      final invoice = session.completeWorkspaceCounterSale();
      expect(invoice, isNotNull);
      expect(invoice!.orderId, isNot(incoming.id));
      expect(
        session.workspaceOrders.firstWhere((o) => o.id == incoming.id),
        same(incoming),
      );
      expect(session.workspaceOrders, hasLength(2));
      expect(session.workspaceInvoices, hasLength(1));
      expect(session.workspaceCatalogueItems.single.stock, 8);
    },
  );

  test(
    'counter isolation retains uncertain time request and selected order',
    () async {
      final gateway = _OrderTimeGateway();
      final reply = Completer<WorkOrderTimeResult>();
      gateway.respond = (_) => reply.future;
      final session = timingSession(gateway);
      final incoming = session.currentWorkspaceOrder!;
      final request = session.requestWorkspaceOrderTime(incoming.id, 2);
      expect(session.startNewWorkspaceOrder(), isFalse);
      expect(
        session.prepareWorkspaceOrder(
          source: 'Phone',
          fulfilment: 'Own delivery',
        ),
        isFalse,
      );
      expect(session.prepareRepeatWorkspaceOrder(), isFalse);
      expect(session.currentWorkspaceOrder, same(incoming));
      expect(session.workspaceOrderSource, 'App');
      expect(session.workspaceOrderFulfilment, 'Mool delivery');
      reply.completeError(StateError('Uncertain response'));
      expect(await request, isFalse);
      expect(session.hasPendingOrderTime, isTrue);
      expect(session.startNewWorkspaceOrder(), isFalse);
      expect(session.currentWorkspaceOrder, same(incoming));
      expect(gateway.requests, hasLength(1));
    },
  );

  test('counter isolation cannot revive a cancelled or missing saved bill', () {
    final gateway = ReviewWorkGateway();
    final session = liveSession(gateway);
    session.workspaceCatalogueItems.add(_product(stock: 10));
    session.adjustWorkspaceOrderQuantity('atta-5kg', 1);
    session.saveWorkspaceOrderDraft(
      customer: '9829012345',
      source: 'Counter',
      fulfilment: 'At the shop',
      payment: 'Cash',
      address: '',
    );
    session.cancelWorkspaceOrder();
    final cancelled = session.currentWorkspaceOrder!;
    final snapshot = gateway.lastOperationalSnapshot;
    expect(session.completeWorkspaceCounterSale(), isNull);
    expect(
      session.saveWorkspaceOrderDraft(
        customer: '9829012346',
        source: 'Counter',
        fulfilment: 'At the shop',
        payment: 'Cash',
        address: '',
      ),
      isFalse,
    );
    expect(session.currentWorkspaceOrder, same(cancelled));
    session.workspaceOrders.clear();
    expect(session.completeWorkspaceCounterSale(), isNull);
    expect(
      session.saveWorkspaceOrderDraft(
        customer: '9829012346',
        source: 'Counter',
        fulfilment: 'At the shop',
        payment: 'Cash',
        address: '',
      ),
      isFalse,
    );
    expect(session.workspaceOrders, isEmpty);
    expect(session.workspaceInvoices, isEmpty);
    expect(session.workspaceCatalogueItems.single.stock, 10);
    expect(gateway.lastOperationalSnapshot, same(snapshot));
  });

  test('counter sale posts stock money and customer invoice together', () {
    final session = liveSession();
    session.addOrUpdateWorkspaceProduct(_product(stock: 10));
    session.prepareWorkspaceOrder(source: 'Counter', fulfilment: 'At the shop');
    session.adjustWorkspaceOrderQuantity('atta-5kg', 2);
    session.saveWorkspaceOrderDraft(
      customer: '9829012321',
      source: 'Counter',
      fulfilment: 'At the shop',
      payment: 'UPI',
      address: '',
    );

    final invoice = session.completeWorkspaceCounterSale();
    expect(invoice, isNotNull);
    expect(session.workspaceCatalogueItems.single.stock, 8);
    expect(session.workspaceSalesToday, 550);
    expect(session.workspaceSettlementBalance, 0);
    session.markWorkspaceInvoiceShared(invoice!.id, 'MoolSocial Chat');
    expect(session.latestWorkspaceInvoice?.needsCustomerHandoff, isFalse);
  });

  test('completed counter sale cannot reopen or post its totals twice', () {
    final session = liveSession();
    session.addOrUpdateWorkspaceProduct(_product(stock: 10));
    session.prepareWorkspaceOrder(source: 'Counter', fulfilment: 'At the shop');
    session.adjustWorkspaceOrderQuantity('atta-5kg', 2);
    void save() => session.saveWorkspaceOrderDraft(
      customer: '9829012321',
      source: 'Counter',
      fulfilment: 'At the shop',
      payment: 'UPI',
      address: '',
    );
    save();
    final first = session.completeWorkspaceCounterSale()!;
    final movementCount = session.workspaceStockMovements.length;
    save();
    expect(session.completeWorkspaceCounterSale(), same(first));
    expect(session.currentWorkspaceOrder!.stage, 'Completed');
    expect(session.workspaceInvoices, hasLength(1));
    expect(session.workspaceCompletedSalesCount, 1);
    expect(session.workspaceSalesToday, 550);
    expect(session.workspaceSettlementBalance, 0);
    expect(session.workspaceCatalogueItems.single.stock, 8);
    expect(session.workspaceStockMovements, hasLength(movementCount));

    session.startNewWorkspaceOrder();
    expect(session.completeWorkspaceCounterSale(), isNull);
    expect(session.workspaceOrders, hasLength(1));
    expect(session.workspaceInvoices.single, same(first));
    expect(session.workspaceSalesToday, 550);
  });

  for (final payment in [
    'Cash',
    'UPI',
    'Pay request',
    'On delivery',
    'Customer due',
  ]) {
    test(
      'recording a $payment counter invoice does not create settlement funds',
      () {
        final session = liveSession()..workspaceSettlementBalance = 700;
        session.addOrUpdateWorkspaceProduct(_product(stock: 10));
        session.prepareWorkspaceOrder(
          source: 'Counter',
          fulfilment: 'At the shop',
        );
        session.adjustWorkspaceOrderQuantity('atta-5kg', 1);
        session.saveWorkspaceOrderDraft(
          customer: '9829012321',
          source: 'Counter',
          fulfilment: 'At the shop',
          payment: payment,
          address: '',
        );
        final invoice = session.completeWorkspaceCounterSale()!;
        expect(invoice.payment, payment);
        expect(session.workspaceSalesToday, 275);
        expect(session.workspaceSettlementBalance, 700);
        expect(session.workspaceSettlementEligible, 700);
        expect(session.workspaceCatalogueItems.single.stock, 9);
      },
    );
  }

  test('failed counter completion retains its draft without an invoice', () {
    final session = liveSession();
    session.addOrUpdateWorkspaceProduct(_product(stock: 1));
    session.prepareWorkspaceOrder(source: 'Counter', fulfilment: 'At the shop');
    session.workspaceOrderQuantities['atta-5kg'] = 2;
    session.saveWorkspaceOrderDraft(
      customer: '9829012321',
      source: 'Counter',
      fulfilment: 'At the shop',
      payment: 'Cash',
      address: '',
    );
    expect(session.completeWorkspaceCounterSale(), isNull);
    expect(session.workspaceOrderCustomer, '9829012321');
    expect(session.workspaceOrderQuantities['atta-5kg'], 2);
    expect(session.workspaceInvoices, isEmpty);
    expect(session.workspaceCompletedSalesCount, 0);
    expect(session.workspaceSalesToday, 0);
    expect(session.workspaceCatalogueItems.single.stock, 1);
  });

  test('Store configuration persists delivery staff and counter controls', () {
    final gateway = ReviewWorkGateway();
    final session = liveSession(gateway);
    session.saveWorkspaceDeliverySettings(radiusKm: 8, fee: 25, freeAbove: 599);
    session.saveWorkspaceStaffSettings(
      staffAccessEnabled: true,
      counterCount: 3,
    );
    expect(session.workspaceDeliveryRadiusKm, 8);
    expect(session.workspaceDeliveryFee, 25);
    expect(session.workspaceFreeDeliveryAbove, 599);
    expect(session.workspaceStaffAccessEnabled, isTrue);
    expect(session.workspaceCounterCount, 3);
  });

  test(
    'funded Store requirement preserves candidate and payment facts',
    () async {
      final gateway = ReviewWorkGateway();
      final session = liveSession(gateway);
      expect(
        await session.createWorkspacePaidRequirement(
          position: 'Evening packing assistant',
          work: 'Pack confirmed customer orders from 5 PM to 9 PM.',
          candidateRequirement: 'Retail packing experience',
          location: 'Sardarpura, Jodhpur · 342003',
          peopleNeeded: 2,
          paymentAmount: 600,
          paymentFormat: 'Assignment',
          deadline: DateTime(2026, 9, 7),
        ),
        isTrue,
      );
      expect(gateway.paidRequirementCalls, 1);
      expect(
        gateway.lastPaidRequirementSubmission?.values,
        containsPair('paymentAmount', 600),
      );
      expect(
        session.workspacePaidRequirementReference,
        startsWith('WORK-REQ-'),
      );
    },
  );

  test(
    'Group Bulk Buying preserves every decision and payment field',
    () async {
      final gateway = ReviewWorkGateway();
      final session = liveSession(gateway);

      expect(
        await session.createWorkspaceGroupBuy(
          productName: 'Premium red onion',
          specification: 'Grade A · 45 mm+ · 25 kg mesh bags',
          targetQuantity: 1000,
          securedQuantity: 280,
          unitLabel: 'kg',
          regularUnitPrice: 18,
          groupUnitPrice: 14,
          facilitationFee: 200,
          deliveryFee: 0,
          confirmationAmount: 3920,
          closingLabel: '5 Sep · 8:00 PM',
          storeDeliveryLabel: '7 Sep · Door delivery',
        ),
        isTrue,
      );

      expect(gateway.groupBuyCalls, 1);
      expect(
        gateway.lastGroupBuySubmission?.values,
        containsPair('facilitationFee', 200),
      );
      expect(
        gateway.lastGroupBuySubmission?.values,
        containsPair('storeDeliveryLabel', '7 Sep · Door delivery'),
      );
      expect(session.activeGroupBuy?.productName, 'Premium red onion');
      expect(session.activeGroupBuy?.paymentConfirmed, isTrue);
      expect(session.activeGroupBuy?.leadRetailer, 'Mahadev Fresh Mart');
    },
  );

  test(
    'catalogue import updates by SKU and retirement removes public sale',
    () {
      final session = liveSession();
      session.addOrUpdateWorkspaceProduct(_product(stock: 10));
      session.importWorkspaceProducts([
        _product(stock: 24, sellingPrice: 299),
        _product(
          id: 'oil-1l',
          sku: 'OIL-1L',
          title: 'Fortune Sunlite Oil',
          stock: 18,
          sellingPrice: 155,
        ),
      ]);

      expect(session.workspaceCatalogueItems, hasLength(2));
      expect(
        session.workspaceCatalogueItems
            .singleWhere((item) => item.sku == 'ATTA-5KG')
            .sellingPrice,
        299,
      );
      session.retireWorkspaceProduct('oil-1l');
      final retired = session.workspaceCatalogueItems.singleWhere(
        (item) => item.id == 'oil-1l',
      );
      expect(retired.stock, 0);
      expect(retired.available, isFalse);
      expect(retired.publicListing, isFalse);
      expect(retired.published, isFalse);
    },
  );

  test('workspace switch keeps both verified businesses available', () {
    final session = liveSession()
      ..otherWorkspaces.add(
        const WorkWorkspace(
          id: 'workspace-store-2',
          name: 'Mahadev Speciality Store',
          profileLabel: 'Speciality Retail Shop',
          profileId: 'retailer-speciality',
          area: 'Paota, Jodhpur',
          verified: true,
        ),
      );

    final target = session.otherWorkspaces.single;
    session.activateWorkspace(target);
    expect(session.activeWorkspace?.id, 'workspace-store-2');
    expect(session.otherWorkspaces.map((item) => item.id), [
      'workspace-store-1',
    ]);
    expect(session.workspaceId, 'workspace-store-2');
  });

  test('Store scope restores only the selected store operational state', () {
    final session = liveSession();
    final first = session.activeWorkspace!;
    const second = WorkWorkspace(
      id: 'workspace-store-2',
      name: 'Second store',
      profileLabel: 'Speciality Retail Shop',
      profileId: 'retailer-speciality',
      area: 'Paota',
      verified: true,
    );
    session.otherWorkspaces.add(second);
    session.workspaceCatalogueItems.add(_product());
    final firstCatalogue = session.workspaceCatalogueItems;
    session.workspaceOrderQuantities['atta-5kg'] = 2;
    session.workspaceOrderCustomer = 'First customer';
    session.workspaceOrderStage = 'Preparing';
    session.workspacePackedProductIds.add('atta-5kg');
    session.currentWorkspaceOrderId = 'shared-id';
    session.workspaceSalesToday = 900;
    session.workspaceSettlementBalance = 700;
    session.workspacePayoutAccountEnding = '1234';
    session.workspaceCustomersFollowingStore.add('first-customer');
    session.workspaceCustomerLastContactAt['first-customer'] = DateTime(
      2026,
      9,
      7,
    );
    session.workspaceAcceptingOrders = true;
    session.workspaceVisibleToCustomers = true;
    session.workspaceSearchQuery = 'First draft';
    session.activateWorkspace(second);
    expect(session.workspaceCatalogueItems, isEmpty);
    expect(identical(session.workspaceCatalogueItems, firstCatalogue), isFalse);
    expect(session.workspaceOrderQuantities, isEmpty);
    expect(session.workspacePackedProductIds, isEmpty);
    expect(session.currentWorkspaceOrderId, isNull);
    expect(session.visibleWorkspaceOrders, isEmpty);
    expect(session.workspaceSalesToday, 0);
    expect(session.workspaceSettlementBalance, 0);
    expect(session.workspacePayoutAccountEnding, isEmpty);
    expect(session.workspaceCustomersFollowingStore, isEmpty);
    expect(session.workspaceCustomerLastContactAt, isEmpty);
    expect(session.workspaceAcceptingOrders, isFalse);
    expect(session.workspaceVisibleToCustomers, isFalse);
    session.workspaceCatalogueItems.add(_product(id: 'second-sku'));
    session.workspaceSalesToday = 75;
    session.workspaceOrderCustomer = 'Second customer';
    session.activateWorkspace(first);
    expect(identical(session.workspaceCatalogueItems, firstCatalogue), isTrue);
    expect(session.workspaceCatalogueItems.single.id, 'atta-5kg');
    expect(session.workspaceOrderQuantities, {'atta-5kg': 2});
    expect(session.workspacePackedProductIds, {'atta-5kg'});
    expect(session.currentWorkspaceOrderId, 'shared-id');
    expect(session.workspaceOrderCustomer, 'First customer');
    expect(session.workspaceSalesToday, 900);
    expect(session.workspaceSettlementBalance, 700);
    expect(session.workspacePayoutAccountEnding, '1234');
    expect(session.workspaceCustomerLastContactAt, contains('first-customer'));
    session.activateWorkspace(second);
    expect(session.workspaceCatalogueItems.single.id, 'second-sku');
    expect(session.workspaceSalesToday, 75);
    expect(session.workspaceOrderCustomer, 'Second customer');
  });

  test('Store scope partitions all public operational fields and defaults', () {
    final session = liveSession();
    final first = session.activeWorkspace!;
    const second = WorkWorkspace(
      id: 'store-b',
      name: 'Second store',
      profileLabel: 'Speciality Retail Shop',
      profileId: 'retailer-speciality',
      area: 'Paota',
      verified: true,
    );
    session.otherWorkspaces.add(second);
    session.retailerProductAdded = !session.retailerProductAdded;
    session.retailerQuantity = session.retailerQuantity + 7;
    session.retailerBuyPrice = session.retailerBuyPrice + 7;
    session.retailerSellPrice = session.retailerSellPrice + 7;
    session.retailerHomeDelivery = !session.retailerHomeDelivery;
    session.retailerStoreCollection = !session.retailerStoreCollection;
    session.retailerPublishAfterSetup = !session.retailerPublishAfterSetup;
    session.retailerSetupSaved = !session.retailerSetupSaved;
    session.workspaceSearchQuery = 'first-workspaceSearchQuery';
    session.workspaceStoreState = WorkspaceStoreState.values.firstWhere(
      (value) => value != session.workspaceStoreState,
    );
    session.workspaceDashboardState = WorkspaceDashboardState.values.firstWhere(
      (value) => value != session.workspaceDashboardState,
    );
    session.workspaceLastUpdatedAt = DateTime(2026, 9, 7, 12);
    session.workspaceDashboardError = 'first-workspaceDashboardError';
    session.workspaceAcceptingOrders = !session.workspaceAcceptingOrders;
    session.workspaceFulfilmentMode = 'first-workspaceFulfilmentMode';
    session.workspaceBusyMinutes = session.workspaceBusyMinutes + 7;
    session.workspaceReopensAt = 'first-workspaceReopensAt';
    session.workspaceOpeningTime = 'first-workspaceOpeningTime';
    session.workspaceClosingTime = 'first-workspaceClosingTime';
    session.workspaceMaximumActiveOrders =
        session.workspaceMaximumActiveOrders + 7;
    session.workspaceOrderAlertSound = !session.workspaceOrderAlertSound;
    session.workspaceOrderAlertVibration =
        !session.workspaceOrderAlertVibration;
    session.workspaceVisibleToCustomers = !session.workspaceVisibleToCustomers;
    session.workspaceOrderCustomer = 'first-workspaceOrderCustomer';
    session.workspaceOrderItems = 'first-workspaceOrderItems';
    session.workspaceOrderAmount = 'first-workspaceOrderAmount';
    session.workspaceOrderNeedsDelivery = !session.workspaceOrderNeedsDelivery;
    session.workspaceOrderSource = 'first-workspaceOrderSource';
    session.workspaceOrderFulfilment = 'first-workspaceOrderFulfilment';
    session.workspaceOrderPayment = 'first-workspaceOrderPayment';
    session.workspaceOrderAddress = 'first-workspaceOrderAddress';
    session.workspaceOrderStage = 'first-workspaceOrderStage';
    session.workspaceOrderExtraMinutes = session.workspaceOrderExtraMinutes + 7;
    session.workspaceOrderActionDeadline = DateTime(2026, 9, 7, 12);
    session.workspaceOrderFilter = 'first-workspaceOrderFilter';
    session.workspaceCustomerPeriod = 'first-workspaceCustomerPeriod';
    session.workspaceCustomerSearch = 'first-workspaceCustomerSearch';
    session.workspaceCustomerFilter = 'first-workspaceCustomerFilter';
    session.workspaceMoneyPeriod = 'first-workspaceMoneyPeriod';
    session.workspaceCustomerCustomStart = DateTime(2026, 9, 7, 12);
    session.workspaceCustomerCustomEnd = DateTime(2026, 9, 7, 12);
    session.workspaceSalesToday = session.workspaceSalesToday + 7;
    session.workspaceCompletedSalesCount =
        session.workspaceCompletedSalesCount + 7;
    session.workspacePlatformAdjustments =
        session.workspacePlatformAdjustments + 7;
    session.workspaceDeliveryAdjustments =
        session.workspaceDeliveryAdjustments + 7;
    session.workspaceRefunds = session.workspaceRefunds + 7;
    session.workspaceTaxWithheld = session.workspaceTaxWithheld + 7;
    session.workspaceSettlementBalance = session.workspaceSettlementBalance + 7;
    session.workspaceSettlementRequested =
        session.workspaceSettlementRequested + 7;
    session.workspaceSettlementReference = 'first-workspaceSettlementReference';
    session.workspacePayoutBankName = 'first-workspacePayoutBankName';
    session.workspacePayoutAccountEnding = 'first-workspacePayoutAccountEnding';
    session.currentWorkspaceOrderId = 'first-currentWorkspaceOrderId';
    session.workspaceOperationsSyncing = false;
    session.workspaceOperationsSyncError = 'first-workspaceOperationsSyncError';
    session.workspaceHandoverBusy = false;
    session.workspaceDeliveryRadiusKm = session.workspaceDeliveryRadiusKm + 7;
    session.workspaceDeliveryFee = session.workspaceDeliveryFee + 7;
    session.workspaceFreeDeliveryAbove = session.workspaceFreeDeliveryAbove + 7;
    session.workspaceDeliveryCity = 'first-workspaceDeliveryCity';
    session.workspaceDeliveryArea = 'first-workspaceDeliveryArea';
    session.workspaceDeliveryPincode = 'first-workspaceDeliveryPincode';
    session.workspacePickupEnabled = !session.workspacePickupEnabled;
    session.workspaceStaffAccessEnabled = !session.workspaceStaffAccessEnabled;
    session.workspaceCounterCount = session.workspaceCounterCount + 7;
    session.workspacePaidRequirementReference =
        'first-workspacePaidRequirementReference';
    session.workspacePaidRequirementState = WorkspacePaidRequirementState.values
        .firstWhere((value) => value != session.workspacePaidRequirementState);
    session.workspaceCatalogueItems.add(_product());
    session.workspaceOrders.add(_scopeOrder('same-order'));
    session.workspaceInvoices.add(
      WorkspaceCustomerInvoice(
        id: 'invoice-a',
        orderId: 'same-order',
        customer: 'First customer',
        items: 'Atta',
        amount: 100,
        payment: 'Paid online',
        issuedAt: DateTime(2026, 9, 7),
      ),
    );
    session.workspaceStockMovements.add(
      WorkspaceStockMovement(
        id: 'move-a',
        productId: 'atta-5kg',
        productLabel: 'Atta',
        kind: WorkspaceStockMovementKind.adjustment,
        quantityDelta: 1,
        reason: 'Counted',
        occurredAt: DateTime(2026, 9, 7),
      ),
    );
    session.workspaceOffers.add(
      WorkspaceStoreOffer(
        id: 'offer-a',
        title: 'Store offer',
        detail: 'Atta',
        validUntil: DateTime(2026, 9, 8),
        active: true,
      ),
    );
    session.workspaceActivity.add(
      WorkspaceActivityEntry(
        message: 'First activity',
        time: DateTime(2026, 9, 7),
      ),
    );
    session.workspaceOrderQuantities['atta-5kg'] = 3;
    session.workspacePackedProductIds.add('atta-5kg');
    session.dismissedWorkspaceAlerts.add('first-alert');
    session.workspaceCustomersFollowingStore.add('first-customer');
    session.workspaceCustomersAllowingMessages.add('first-customer');
    session.workspaceCustomerLastContactAt['first-customer'] = DateTime(
      2026,
      9,
      7,
    );
    session.workspaceDeliveryAssignment = WorkspaceDeliveryAssignment(
      orderId: 'same-order',
      partnerName: 'First rider',
      vehicleLabel: 'Bike',
      eta: DateTime(2026, 9, 7),
      stage: 'Arriving',
    );
    final expectedFirst = _storeValues(session);
    final fresh = WorkSession();
    addTearDown(fresh.dispose);
    session.activateWorkspace(second);
    final actualSecond = _storeValues(session);
    expect(actualSecond, _storeValues(fresh));
    for (final entry in expectedFirst.entries) {
      if (entry.value is Iterable || entry.value is Map) {
        expect(
          identical(actualSecond[entry.key], entry.value),
          isFalse,
          reason: entry.key,
        );
      }
    }
    session.workspaceOrderCustomer = 'Second customer';
    session.workspaceOrderQuantities['second-sku'] = 1;
    session.workspaceSettlementBalance = 10000000000;
    final expectedSecond = _storeValues(session);
    session.activateWorkspace(first);
    expect(_storeValues(session), expectedFirst);
    session.activateWorkspace(second);
    expect(_storeValues(session), expectedSecond);
  });

  for (final pending in ['operation', 'save', 'handover']) {
    test('Store scope blocks switching during $pending', () {
      final session = liveSession()..otherWorkspaces.add(_scopeSecondStore);
      if (pending == 'operation') session.busy = true;
      if (pending == 'save') session.workspaceOperationsSyncing = true;
      if (pending == 'handover') session.workspaceHandoverBusy = true;
      session.activateWorkspace(_scopeSecondStore);
      expect(session.activeWorkspace?.id, 'workspace-store-1');
      expect(session.noticeMessage, contains('Please wait'));
    });
  }

  test(
    'Store scope waits for every concurrent save before switching',
    () async {
      final gateway = _ScopeGateway();
      final session = liveSession(gateway)
        ..otherWorkspaces.add(_scopeSecondStore);
      session.saveWorkspaceAvailability(
        acceptingOrders: true,
        fulfilmentMode: 'Pickup',
        busyMinutes: 0,
        reopensAt: '',
      );
      session.saveWorkspaceTradingControls(
        openingTime: '9 AM',
        closingTime: '8 PM',
        maximumActiveOrders: 8,
        alertSound: true,
        alertVibration: true,
      );
      expect(gateway.saves, hasLength(2));
      expect(
        gateway.snapshots.map((s) => s.workspaceId),
        everyElement('workspace-store-1'),
      );
      gateway.saves.first.complete();
      await Future<void>.delayed(Duration.zero);
      expect(session.workspaceOperationsSyncing, isTrue);
      session.activateWorkspace(_scopeSecondStore);
      expect(session.activeWorkspace?.id, 'workspace-store-1');
      gateway.saves.last.complete();
      await Future<void>.delayed(Duration.zero);
      expect(session.workspaceOperationsSyncing, isFalse);
      session.activateWorkspace(_scopeSecondStore);
      expect(session.activeWorkspace?.id, _scopeSecondStore.id);
    },
  );

  for (final fails in [false, true]) {
    test(
      'Store scope late save cannot finish another store save $fails',
      () async {
        final gateway = _ScopeGateway();
        final session = liveSession(gateway);
        session.saveWorkspaceAvailability(
          acceptingOrders: true,
          fulfilmentMode: 'Pickup',
          busyMinutes: 0,
          reopensAt: '',
        );
        session.activeWorkspace = _scopeSecondStore;
        session.workspaceId = _scopeSecondStore.id;
        session.saveWorkspaceAvailability(
          acceptingOrders: false,
          fulfilmentMode: 'Pickup',
          busyMinutes: 0,
          reopensAt: '',
        );
        if (fails) {
          gateway.saves.first.completeError(
            const WorkGatewayException('First store failure'),
          );
        } else {
          gateway.saves.first.complete();
        }
        await Future<void>.delayed(Duration.zero);
        expect(session.workspaceOperationsSyncing, isTrue);
        expect(session.workspaceOperationsSyncError, isNull);
        expect(session.workspaceAcceptingOrders, isFalse);
        gateway.saves.last.complete();
        await Future<void>.delayed(Duration.zero);
        expect(session.workspaceOperationsSyncing, isFalse);
      },
    );

    test(
      'Store scope late settlement cannot change another store $fails',
      () async {
        final gateway = _ScopeGateway();
        final session = liveSession(gateway)..workspaceSettlementBalance = 500;
        final pending = session.requestWorkspaceSettlement(amount: 100);
        session.activeWorkspace = _scopeSecondStore;
        session.workspaceId = _scopeSecondStore.id;
        session.workspaceSettlementBalance = 12000;
        if (fails) {
          gateway.settlement.completeError(
            const WorkGatewayException('Old settlement failure'),
          );
        } else {
          gateway.settlement.complete(
            const WorkSettlementResult(
              reference: 'old-settlement',
              acceptedAmount: 100,
            ),
          );
        }
        await pending;
        expect(session.workspaceSettlementBalance, 12000);
        expect(session.workspaceSettlementRequested, 0);
        expect(session.workspaceSettlementReference, isNull);
        expect(session.workspaceActivity, isEmpty);
        expect(session.errorMessage, isNull);
        expect(gateway.saves, isEmpty);
        expect(session.busy, isFalse);
      },
    );
  }

  for (final pickup in [false, true]) {
    test(
      'Store scope late handover cannot complete a same-id order $pickup',
      () async {
        final gateway = _ScopeGateway();
        final session = liveSession(gateway);
        session.workspaceOrders.add(_scopeOrder('same-order'));
        expect(session.selectWorkspaceOrder('same-order'), isTrue);
        final pending = pickup
            ? session.verifyWorkspacePickup('123456')
            : session.verifyWorkspaceHandover('123456');
        session.activeWorkspace = _scopeSecondStore;
        session.workspaceId = _scopeSecondStore.id;
        session.workspaceOrders.add(_scopeOrder('same-order'));
        expect(session.selectWorkspaceOrder('same-order'), isTrue);
        gateway.handover.complete();
        expect(await pending, isFalse);
        expect(session.workspaceOrderStage, 'Ready for pickup');
        expect(session.workspaceInvoices, isEmpty);
        expect(session.workspaceCompletedSalesCount, 0);
        expect(session.workspaceSettlementBalance, 0);
        expect(session.workspaceHandoverBusy, isFalse);
      },
    );
  }

  test(
    'Store scope late rider assignment cannot replace another store rider',
    () async {
      final gateway = _ScopeGateway();
      final session = liveSession(gateway);
      session.workspaceOrders.add(
        _scopeOrder('same-order', stage: 'Delivery requested'),
      );
      expect(session.selectWorkspaceOrder('same-order'), isTrue);
      final pending = session.retryWorkspaceDeliveryAssignment();
      session.activeWorkspace = _scopeSecondStore;
      session.workspaceId = _scopeSecondStore.id;
      session.workspaceOrders.add(
        _scopeOrder('same-order', stage: 'Delivery requested'),
      );
      expect(session.selectWorkspaceOrder('same-order'), isTrue);
      gateway.delivery.complete(
        WorkDeliveryAssignmentResult(
          partnerName: 'Old rider',
          vehicleLabel: 'Bike',
          eta: DateTime(2026, 9, 7),
          stage: 'Arriving',
        ),
      );
      await pending;
      expect(session.workspaceDeliveryAssignment, isNull);
      expect(session.workspaceOrderActionDeadline, isNull);
      expect(session.workspaceOperationsSyncing, isFalse);
    },
  );

  for (final group in [false, true]) {
    test(
      'Store scope late publication cannot populate another store $group',
      () async {
        final gateway = _ScopeGateway();
        final session = liveSession(gateway);
        final pending = group
            ? session.createWorkspaceGroupBuy(
                productName: 'Onion',
                specification: 'Grade A',
                targetQuantity: 100,
                securedQuantity: 10,
                unitLabel: 'kg',
                regularUnitPrice: 20,
                groupUnitPrice: 14,
                facilitationFee: 5,
                deliveryFee: 0,
                confirmationAmount: 140,
                closingLabel: '10 September',
                storeDeliveryLabel: '12 September',
              )
            : session.createWorkspacePaidRequirement(
                position: 'Product sourcing',
                work: 'Source stock',
                candidateRequirement: 'Wholesale experience',
                location: 'Jodhpur',
                peopleNeeded: 1,
                paymentAmount: 100,
                paymentFormat: 'Assignment',
                deadline: DateTime(2026, 9, 10),
              );
        session.activeWorkspace = _scopeSecondStore;
        session.workspaceId = _scopeSecondStore.id;
        gateway.publication.complete('first-store-reference');
        expect(await pending, isFalse);
        expect(session.activeGroupBuy, isNull);
        expect(session.workspacePaidRequirementReference, isNull);
        expect(
          session.workspacePaidRequirementState,
          WorkspacePaidRequirementState.draft,
        );
        expect(session.workspaceActivity, isEmpty);
        expect(gateway.saves, isEmpty);
      },
    );
  }

  test('repeat basket reconstructs an available legacy purchase summary', () {
    final session = liveSession();
    session.addOrUpdateWorkspaceProduct(
      _product(
        id: 'oil-1l',
        sku: 'OIL-1L',
        title: 'Fortune Sunlite Oil',
        stock: 8,
        sellingPrice: 155,
      ),
    );
    session
      ..workspaceOrderCustomer = 'Rakesh · 98290 12345'
      ..workspaceOrderItems = 'Fortune Oil × 2 · Aashirvaad Atta × 1'
      ..workspaceOrderAmount = '1468'
      ..workspaceOrderStage = 'Completed'
      ..workspaceOrderPayment = 'Paid online'
      ..workspaceOrderFulfilment = 'Pickup';

    expect(session.prepareRepeatWorkspaceOrder(), isTrue);
    expect(session.workspaceOrderSource, 'Repeat order');
    expect(session.workspaceOrderCustomer, 'Rakesh · 98290 12345');
    expect(session.workspaceOrderQuantities['oil-1l'], 2);
    expect(session.noticeMessage, contains('Available products'));
  });
}

const _scopeSecondStore = WorkWorkspace(
  id: 'workspace-store-2',
  name: 'Second store',
  profileLabel: 'Speciality Retail Shop',
  profileId: 'retailer-speciality',
  area: 'Paota',
  verified: true,
);

class _ScopeGateway extends ReviewWorkGateway {
  final saves = <Completer<void>>[];
  final snapshots = <WorkOperationalSnapshot>[];
  final settlement = Completer<WorkSettlementResult>();
  final handover = Completer<void>();
  final delivery = Completer<WorkDeliveryAssignmentResult>();
  final publication = Completer<String>();
  @override
  Future<void> saveOperationalState(WorkOperationalSnapshot snapshot) {
    snapshots.add(snapshot);
    final result = Completer<void>();
    saves.add(result);
    return result.future;
  }

  @override
  Future<WorkSettlementResult> requestSettlement({
    required String workspaceId,
    required int amount,
    required String idempotencyKey,
  }) => settlement.future;
  @override
  Future<void> verifyOrderHandover({
    required String workspaceId,
    required String orderId,
    required String otp,
    required String idempotencyKey,
  }) => handover.future;
  @override
  Future<WorkDeliveryAssignmentResult> requestDeliveryAssignment({
    required String workspaceId,
    required String orderId,
    required String address,
    required String idempotencyKey,
  }) => delivery.future;
  @override
  Future<String> createGroupBuy(WorkGroupBuySubmission submission) =>
      publication.future;
  @override
  Future<String> createPaidRequirement(
    WorkPaidRequirementSubmission submission,
  ) => publication.future;
}

Map<String, Object?> _storeValues(WorkSession session) => {
  'retailerProductAdded': session.retailerProductAdded,
  'retailerQuantity': session.retailerQuantity,
  'retailerBuyPrice': session.retailerBuyPrice,
  'retailerSellPrice': session.retailerSellPrice,
  'retailerHomeDelivery': session.retailerHomeDelivery,
  'retailerStoreCollection': session.retailerStoreCollection,
  'retailerPublishAfterSetup': session.retailerPublishAfterSetup,
  'retailerSetupSaved': session.retailerSetupSaved,
  'workspaceSearchQuery': session.workspaceSearchQuery,
  'workspaceStoreState': session.workspaceStoreState,
  'workspaceDashboardState': session.workspaceDashboardState,
  'workspaceLastUpdatedAt': session.workspaceLastUpdatedAt,
  'workspaceDashboardError': session.workspaceDashboardError,
  'workspaceAcceptingOrders': session.workspaceAcceptingOrders,
  'workspaceFulfilmentMode': session.workspaceFulfilmentMode,
  'workspaceBusyMinutes': session.workspaceBusyMinutes,
  'workspaceReopensAt': session.workspaceReopensAt,
  'workspaceOpeningTime': session.workspaceOpeningTime,
  'workspaceClosingTime': session.workspaceClosingTime,
  'workspaceMaximumActiveOrders': session.workspaceMaximumActiveOrders,
  'workspaceOrderAlertSound': session.workspaceOrderAlertSound,
  'workspaceOrderAlertVibration': session.workspaceOrderAlertVibration,
  'workspaceVisibleToCustomers': session.workspaceVisibleToCustomers,
  'workspaceOrderCustomer': session.workspaceOrderCustomer,
  'workspaceOrderItems': session.workspaceOrderItems,
  'workspaceOrderAmount': session.workspaceOrderAmount,
  'workspaceOrderNeedsDelivery': session.workspaceOrderNeedsDelivery,
  'workspaceOrderSource': session.workspaceOrderSource,
  'workspaceOrderFulfilment': session.workspaceOrderFulfilment,
  'workspaceOrderPayment': session.workspaceOrderPayment,
  'workspaceOrderAddress': session.workspaceOrderAddress,
  'workspaceOrderStage': session.workspaceOrderStage,
  'workspaceOrderExtraMinutes': session.workspaceOrderExtraMinutes,
  'workspaceOrderActionDeadline': session.workspaceOrderActionDeadline,
  'workspaceOrderFilter': session.workspaceOrderFilter,
  'workspaceCustomerPeriod': session.workspaceCustomerPeriod,
  'workspaceCustomerSearch': session.workspaceCustomerSearch,
  'workspaceCustomerFilter': session.workspaceCustomerFilter,
  'workspaceMoneyPeriod': session.workspaceMoneyPeriod,
  'workspaceCustomerCustomStart': session.workspaceCustomerCustomStart,
  'workspaceCustomerCustomEnd': session.workspaceCustomerCustomEnd,
  'workspaceSalesToday': session.workspaceSalesToday,
  'workspaceCompletedSalesCount': session.workspaceCompletedSalesCount,
  'workspacePlatformAdjustments': session.workspacePlatformAdjustments,
  'workspaceDeliveryAdjustments': session.workspaceDeliveryAdjustments,
  'workspaceRefunds': session.workspaceRefunds,
  'workspaceTaxWithheld': session.workspaceTaxWithheld,
  'workspaceSettlementBalance': session.workspaceSettlementBalance,
  'workspaceSettlementRequested': session.workspaceSettlementRequested,
  'workspaceSettlementReference': session.workspaceSettlementReference,
  'workspacePayoutBankName': session.workspacePayoutBankName,
  'workspacePayoutAccountEnding': session.workspacePayoutAccountEnding,
  'workspaceCatalogueItems': session.workspaceCatalogueItems,
  'workspaceStockMovements': session.workspaceStockMovements,
  'workspaceOrderQuantities': session.workspaceOrderQuantities,
  'workspaceOrders': session.workspaceOrders,
  'workspacePackedProductIds': session.workspacePackedProductIds,
  'workspaceInvoices': session.workspaceInvoices,
  'workspaceOffers': session.workspaceOffers,
  'currentWorkspaceOrderId': session.currentWorkspaceOrderId,
  'workspaceDeliveryAssignment': session.workspaceDeliveryAssignment,
  'workspaceOperationsSyncing': session.workspaceOperationsSyncing,
  'workspaceOperationsSyncError': session.workspaceOperationsSyncError,
  'workspaceHandoverBusy': session.workspaceHandoverBusy,
  'workspaceActivity': session.workspaceActivity,
  'activeGroupBuy': session.activeGroupBuy,
  'workspaceDeliveryRadiusKm': session.workspaceDeliveryRadiusKm,
  'workspaceDeliveryFee': session.workspaceDeliveryFee,
  'workspaceFreeDeliveryAbove': session.workspaceFreeDeliveryAbove,
  'workspaceDeliveryCity': session.workspaceDeliveryCity,
  'workspaceDeliveryArea': session.workspaceDeliveryArea,
  'workspaceDeliveryPincode': session.workspaceDeliveryPincode,
  'workspacePickupEnabled': session.workspacePickupEnabled,
  'workspaceStaffAccessEnabled': session.workspaceStaffAccessEnabled,
  'workspaceCounterCount': session.workspaceCounterCount,
  'workspacePaidRequirementReference':
      session.workspacePaidRequirementReference,
  'workspacePaidRequirementState': session.workspacePaidRequirementState,
  'dismissedWorkspaceAlerts': session.dismissedWorkspaceAlerts,
  'workspaceCustomersFollowingStore': session.workspaceCustomersFollowingStore,
  'workspaceCustomersAllowingMessages':
      session.workspaceCustomersAllowingMessages,
  'workspaceCustomerLastContactAt': session.workspaceCustomerLastContactAt,
};

WorkspaceOrderRecord _scopeOrder(
  String id, {
  String stage = 'Ready for pickup',
}) => WorkspaceOrderRecord(
  id: id,
  customer: 'Customer',
  items: 'Atta',
  quantities: const {'atta-5kg': 1},
  amount: 275,
  source: 'App',
  fulfilment: 'Pickup',
  payment: 'Paid online',
  address: 'Customer address',
  stage: stage,
  needsDelivery: false,
  createdAt: DateTime(2026, 9, 7),
);

WorkspaceCatalogueItem _product({
  String id = 'atta-5kg',
  String sku = 'ATTA-5KG',
  String title = 'Aashirvaad Select Atta',
  int stock = 10,
  int sellingPrice = 275,
}) => WorkspaceCatalogueItem(
  id: id,
  canonicalId: 'canonical-$id',
  categoryId: 'grocery-staples',
  brand: id == 'oil-1l' ? 'Fortune' : 'Aashirvaad',
  title: title,
  variant: 'Standard',
  pack: id == 'oil-1l' ? '1 L' : '5 kg',
  sku: sku,
  barcode: id == 'oil-1l' ? '8906007280012' : '8901725112233',
  purchasePrice: sellingPrice - 25,
  sellingPrice: sellingPrice,
  unitPrice: id == 'oil-1l' ? '₹$sellingPrice/L' : '₹55/kg',
  stock: stock,
  deliveryPromise: 'Delivery today',
  origin: 'India',
  visualLabel: id == 'oil-1l' ? 'OIL' : 'ATTA',
  visualKind: 'pack',
  mrp: sellingPrice + 30,
  minimumOrder: 1,
  returnPolicy: 'Return accepted for a damaged sealed pack.',
  publicListing: true,
);
