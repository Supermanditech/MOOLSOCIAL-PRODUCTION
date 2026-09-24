import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/features/buy/buy_v2_saved_products_store.dart';
import 'package:moolsocial/features/work/work_models.dart';
import 'package:moolsocial/features/work/work_services.dart';
import 'package:moolsocial/features/work/work_session.dart';

class _LostCollectionGateway extends StoreReviewCustomerCollectionGateway {
  _LostCollectionGateway(super.finance);
  int submissions = 0;
  @override
  Future<WorkspaceFinanceSnapshot> recordCollection(
    WorkspaceCustomerCollection request,
  ) async {
    submissions++;
    await super.recordCollection(request);
    throw TimeoutException('Simulated reply loss after application');
  }
}

class _ProcurementBookmarks implements WorkProcurementBookmarkStore {
  final values = <String, WorkProcurementBookmark>{};
  Completer<void>? holdRead;
  bool failRead = false, failSave = false;
  @override
  Future<WorkProcurementBookmark?> read(
    String accountId,
    String storeId,
  ) async {
    await holdRead?.future;
    if (failRead) throw StateError('Store bookmark unavailable');
    return values[jsonEncode([accountId, storeId])];
  }

  @override
  Future<bool> save(WorkProcurementBookmark bookmark) async {
    if (failSave) return false;
    values[jsonEncode([bookmark.context.accountId, bookmark.context.storeId])] =
        bookmark;
    return true;
  }

  @override
  Future<bool> clear(String accountId, String storeId) async {
    values.remove(jsonEncode([accountId, storeId]));
    return true;
  }
}

class _ProcurementCustomerState implements BuyV2CustomerStateStore {
  _ProcurementCustomerState(this.ownerScope);
  @override
  final String ownerScope;
  BuyV2CustomerStateSnapshot? value;
  @override
  Future<BuyV2CustomerStateSnapshot?> read() async => value;
  @override
  Future<bool> write(BuyV2CustomerStateSnapshot snapshot) async {
    value = snapshot;
    return true;
  }
}

class _OrderJournalStorage extends FlutterSecureStorage {
  final values = <String, String>{};
  final writes = <String>[];
  bool failRead = false, failWrite = false;
  bool loseWriteResponseOnce = false;
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
    if (loseWriteResponseOnce) {
      loseWriteResponseOnce = false;
      throw StateError('Write completed but its response was lost');
    }
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

class _ReviewSelectionFixtureStore implements WorkReviewStoreSelectionStore {
  _ReviewSelectionFixtureStore(this.seed);
  StoreReviewSeed? seed;
  int reads = 0;
  Completer<void>? holdRead;
  bool failRead = false;
  @override
  Future<StoreReviewSeed?> read(String account) async {
    reads++;
    await holdRead?.future;
    if (failRead) throw StateError('selection storage unavailable');
    return seed;
  }

  @override
  Future<void> save(StoreReviewSeed value) async {
    seed = value;
  }
}

class _CounterDraftBoundaryStore implements WorkCounterDraftStore {
  _CounterDraftBoundaryStore(this.delegate);
  final WorkCounterDraftStore delegate;
  Completer<void>? readGate, submitGate;
  bool failRetire = false, failAfterSubmit = false;
  @override
  Future<WorkspaceCounterDraft?> read(String account, String store) async {
    final value = await delegate.read(account, store);
    await readGate?.future;
    return value;
  }

  @override
  Future<void> save(
    WorkspaceCounterDraft draft, {
    required int? expectedRevision,
  }) async {
    if (draft.stage == WorkspaceCounterDraftStage.submitting) {
      await submitGate?.future;
    }
    if (failRetire && draft.stage == WorkspaceCounterDraftStage.retired) {
      throw StateError('test retirement write failure');
    }
    await delegate.save(draft, expectedRevision: expectedRevision);
    if (failAfterSubmit &&
        draft.stage == WorkspaceCounterDraftStage.submitting) {
      throw StateError('test reply lost after marker write');
    }
  }
}

class _ReferenceOnlyGroupGateway extends UnavailableWorkGateway {
  int calls = 0, saves = 0;
  @override
  Future<String> createGroupBuy(WorkGroupBuySubmission submission) async {
    calls++;
    return 'PAY-GROUP-unverified-reference';
  }

  @override
  Future<void> saveOperationalState(WorkOperationalSnapshot snapshot) async {
    saves++;
  }
}

typedef _StockHistoryRequest = ({
  WorkspaceStockHistoryQuery query,
  String? cursor,
  String? snapshot,
});

class _StockHistoryGateway implements WorkStockHistoryGateway {
  _StockHistoryGateway(this.records);
  final List<WorkspaceStockMovement> records;
  final requests = <_StockHistoryRequest>[];
  Future<WorkspaceStockHistoryPage> Function(_StockHistoryRequest)? respond;
  WorkspaceStockHistoryPage page(_StockHistoryRequest request) {
    final matching = records.where(request.query.includes).toList()
      ..sort(WorkspaceStockMovement.compareNewest);
    final start = int.parse(request.cursor ?? '0');
    final end = (start + WorkspaceStockHistoryQuery.pageSize).clamp(
      0,
      matching.length,
    );
    return WorkspaceStockHistoryPage(
      query: request.query,
      snapshotId: 'snapshot-1',
      cursor: request.cursor,
      nextCursor: end < matching.length ? '$end' : null,
      totalCount: matching.length,
      records: matching.sublist(start, end),
    );
  }

  @override
  Future<WorkspaceStockHistoryPage> readStockHistory(
    WorkspaceStockHistoryQuery query, {
    String? cursor,
    String? snapshotId,
  }) {
    final request = (query: query, cursor: cursor, snapshot: snapshotId);
    requests.add(request);
    return respond?.call(request) ?? Future.value(page(request));
  }
}

WorkspaceStockMovement _historyMovement(int index) => WorkspaceStockMovement(
  id: 'movement-${index.toString().padLeft(5, '0')}',
  productId: index.isEven ? 'atta-5kg' : 'oil-1l',
  productLabel: index.isEven ? 'Atta · 5 kg' : 'Oil · 1 L',
  kind: WorkspaceStockMovementKind.reserved,
  quantityDelta: -1,
  reason: 'Reserved for customer order',
  referenceKind: WorkspaceStockReferenceKind.order,
  referenceId: 'ORDER-$index',
  occurredAt: DateTime.utc(2026, 9, 10, 12).subtract(Duration(minutes: index)),
);

class _IssueCommandGateway implements WorkIssueCommandGateway {
  final submitted = <WorkIssueCommand>[];
  final reconciled = <WorkIssueCommand>[];
  Future<WorkIssueReply> Function(WorkIssueCommand)? submit, reconcile;
  @override
  Future<WorkIssueReply> submitIssueResponse(WorkIssueCommand command) {
    submitted.add(command);
    return submit?.call(command) ?? Future.value(_issueReply(command));
  }

  @override
  Future<WorkIssueReply> reconcileIssueResponse(WorkIssueCommand command) {
    reconciled.add(command);
    return reconcile?.call(command) ?? Future.value(_issueReply(command));
  }
}

WorkIssueReply _issueReply(
  WorkIssueCommand command, {
  WorkIssueReplyState state = WorkIssueReplyState.applied,
  WorkIssueResponseError? error,
}) => WorkIssueReply(
  key: command.key,
  operationId: command.operationId,
  commandDigest: command.digest,
  state: state,
  revision: state == WorkIssueReplyState.applied
      ? command.draft.expectedRevision + 1
      : null,
  error: error,
);

class _IssueCommandFixture {
  final account = _CommandAccountStore();
  final draftStorage = _OrderJournalStorage();
  final journalStorage = _OrderJournalStorage();
  final gateway = _IssueCommandGateway();
  WorkSession make(WorkspaceIssueRecord issue) {
    final work = WorkSession(
      pendingProofStore: account,
      issueDraftStore: SecureWorkIssueDraftStore(
        accountScope: () => account.accountScope,
        storage: draftStorage,
      ),
      issueCommandStore: SecureWorkIssueCommandStore(
        accountScope: () => account.accountScope,
        storage: journalStorage,
      ),
      issueCommandGateway: gateway,
    )..activeWorkspace = _commandStore;
    work.workspaceOrders.add(_scopeOrder('ORDER-A', stage: 'Preparing'));
    expect(
      work.applyWorkspaceIssues(
        accountScope: 'account-A',
        storeId: 'store-A',
        feedRevision: issue.revision,
        records: [issue],
      ),
      isTrue,
    );
    return work;
  }

  Future<void> prepare(
    WorkSession work,
    WorkspaceIssueRecord issue, {
    WorkspaceIssueResponse response = WorkspaceIssueResponse.provideDetails,
  }) async {
    await work.loadWorkspaceIssueDraft(issue);
    await work.loadWorkspaceIssueResponse(issue);
    await work.saveWorkspaceIssueDraft(
      issue,
      response: response,
      note: 'One sealed pack is damaged.',
    );
  }
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

WorkspaceGroupOffer _groupOffer(
  String id, {
  int revision = 1,
  String account = 'account-A',
  String store = 'group-store',
  String supplier = 'mandi-A',
  WorkspaceStockSupplierType supplierType = WorkspaceStockSupplierType.mandi,
  WorkspaceGroupOfferStage stage = WorkspaceGroupOfferStage.collecting,
  bool published = true,
  WorkspaceGroupParticipation participation = const WorkspaceGroupParticipation(
    state: WorkspaceGroupParticipationState.balanceDue,
    quantity: 10,
    goodsMinor: 14000,
    tradeFeeMinor: 500,
    deliveryMinor: 0,
    taxMinor: 0,
    totalMinor: 14500,
    referenceMinor: 18000,
    paidMinor: 5000,
    dueMinor: 9500,
  ),
}) => WorkspaceGroupOffer(
  accountScope: account,
  workspaceId: store,
  supplierId: supplier,
  supplierName: 'Market supplier',
  supplierType: supplierType,
  productId: 'onion-$id',
  revision: revision,
  updatedAt: DateTime.utc(2026, 9, 10, 12, 0, revision),
  closingAt: DateTime.utc(2026, 9, 12),
  stage: stage,
  publicationConfirmed: published,
  participation: participation,
  details: WorkspaceGroupBuy(
    id: id,
    productName: 'Onions $id',
    specification: 'Grade A · 25 kg sacks',
    leadRetailer: 'Peer retailer',
    confirmedRetailers: ['Peer retailer'],
    targetQuantity: 1000,
    securedQuantity: 300,
    unitLabel: 'kg',
    regularUnitPrice: 18,
    groupUnitPrice: 14,
    facilitationFee: 600,
    deliveryFee: 200,
    confirmationAmount: 3000,
    closingLabel: '12 Sep',
    storeDeliveryLabel: '14 Sep',
    paymentConfirmed: true,
    participants: const [
      WorkspaceGroupBuyParticipant(
        businessName: 'Peer retailer',
        locality: 'Market road',
        quantity: 50,
        unitLabel: 'kg',
        milestone: 'Confirmed',
      ),
    ],
  ),
);

WorkspaceReceiptDraft _receiptDraft({
  String account = 'account-A',
  String store = 'store-A',
  String shipment = 'shipment-A',
  String supplier = 'supplier-A',
  int revision = 1,
  int shipmentRevision = 4,
  String count = '',
  String note = 'दो पैक जाँचें 📦',
  String product = 'sku-A',
}) => WorkspaceReceiptDraft(
  key: (account: account, store: store, shipment: shipment),
  supplierId: supplier,
  orderId: 'order-A',
  purchaseId: 'purchase-A',
  shipmentRevision: shipmentRevision,
  revision: revision,
  lines: [
    WorkspacePurchaseLine(
      id: 'line-A',
      productId: product,
      name: 'Sunflower oil',
      pack: '1 l × 12',
      orderedPacks: 10,
      unitPriceMinor: 1550050,
      receivedPacks: 3,
    ),
  ],
  countedPacks: {'line-A': count},
  problems: const {'line-A': WorkspaceReceiptProblem.damaged},
  note: note,
);

void main() {
  group('PRIVATEPHOTO scoped durable media', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    late Directory directory;
    var current = true;
    final product = workspaceMasterCatalogue.first.copyWith(
      publicListing: false,
      canonicalId: 'private-photo-codec-test',
      title: 'Codec test own product',
    );
    WorkPrivateProductPhotoStore store({
      String account = 'account-A',
      String storeId = 'store-A',
      bool qa = true,
    }) => WorkPrivateProductPhotoStore(
      accountId: account,
      storeId: storeId,
      evaluationOnly: qa,
      isCurrent: () => current,
      supportDirectory: () async => directory,
    );

    // Codec fixture only, never an approval screenshot or real product record.
    Future<WorkPickedProof> selectedImage({
      int width = 512,
      int height = 512,
    }) async {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawColor(const ui.Color(0xff676767), ui.BlendMode.src);
      final picture = recorder.endRecording();
      final image = await picture.toImage(width, height);
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        return WorkPickedProof(
          fileName: 'codec-test.png',
          contentType: 'image/png',
          bytes: data!.buffer.asUint8List(),
        );
      } finally {
        image.dispose();
        picture.dispose();
      }
    }

    setUp(() async {
      current = true;
      directory = await Directory.systemTemp.createTemp(
        'store-private-photo-test-',
      );
    });
    tearDown(() async {
      // Only this test-created directory; never app or device data.
      await directory.delete(recursive: true);
    });

    test('small images require replacement, not upscaling', () async {
      for (final dimensions in [(255, 512), (512, 255), (511, 511)]) {
        await expectLater(
          store().save(
            product: product,
            picked: await selectedImage(
              width: dimensions.$1,
              height: dimensions.$2,
            ),
          ),
          throwsA(isA<WorkGatewayException>()),
        );
      }
      expect(await directory.list(recursive: true).length, 0);
      final photo = await store().save(
        product: product,
        picked: await selectedImage(width: 256, height: 512),
      );
      expect(photo.width, 256);
      expect(photo.height, 512);
    });

    test('catalogue photo cannot be overridden by retailer bytes', () async {
      await expectLater(
        store().save(
          product: workspaceMasterCatalogue.first,
          picked: await selectedImage(),
        ),
        throwsA(isA<WorkGatewayException>()),
      );
      expect(await directory.list(recursive: true).length, 0);
    });

    test('restart restores identical pixels without public approval', () async {
      final picked = await selectedImage();
      final photo = await store().save(product: product, picked: picked);
      final saved = product.copyWith(privatePhoto: photo);
      final restored = WorkspaceCatalogueItem.fromInventoryJson(
        jsonDecode(jsonEncode(saved.toInventoryJson())),
      );
      expect(await store().read(restored), orderedEquals(picked.bytes));
      expect(restored.privatePhoto!.width, 512);
      expect(restored.privatePhoto!.height, 512);
      expect(restored.toBuyPublicProduct(storeName: '').mediaAssets, isEmpty);
      expect(
        (await store().save(product: restored, picked: picked)).toJson(),
        photo.toJson(),
      );
      expect(
        await directory.list(recursive: true).where((f) => f is File).length,
        1,
      );
    });

    test('account, Store, QA and exact product cannot cross', () async {
      final photo = await store().save(
        product: product,
        picked: await selectedImage(),
      );
      final saved = product.copyWith(privatePhoto: photo);
      for (final other in [
        store(account: 'account-B'),
        store(storeId: 'store-B'),
        store(qa: false),
      ]) {
        await expectLater(
          other.read(saved),
          throwsA(isA<WorkGatewayException>()),
        );
      }
      await expectLater(
        store().read(saved.copyWith(pack: 'different pack')),
        throwsA(isA<WorkGatewayException>()),
      );
      expect(
        () => WorkspaceCatalogueItem.fromInventoryJson(
          saved.copyWith(pack: 'different pack').toInventoryJson(),
        ),
        throwsFormatException,
      );
      current = false;
      await expectLater(
        store().read(saved),
        throwsA(isA<WorkGatewayException>()),
      );
      await expectLater(
        store().save(product: product, picked: await selectedImage()),
        throwsA(isA<WorkGatewayException>()),
      );
    });

    test(
      'corrupt or missing bytes fail without manufacturing a replacement',
      () async {
        final photo = await store().save(
          product: product,
          picked: await selectedImage(),
        );
        final saved = product.copyWith(privatePhoto: photo);
        final file =
            (await directory
                    .list(recursive: true)
                    .where((f) => f is File)
                    .single)
                as File;
        final original = await file.readAsBytes();
        final changed = Uint8List.fromList(original)
          ..[original.length - 1] ^= 1;
        await file.writeAsBytes(changed);
        await expectLater(
          store().read(saved),
          throwsA(isA<WorkGatewayException>()),
        );
        await file.delete();
        await expectLater(
          store().read(saved),
          throwsA(isA<WorkGatewayException>()),
        );
        expect(
          await directory.list(recursive: true).where((f) => f is File).length,
          0,
        );
      },
    );

    test(
      'rejects PDF, corrupt image and unsafe reference before stock save',
      () async {
        for (final picked in [
          WorkPickedProof(
            fileName: 'not-photo.pdf',
            contentType: 'application/pdf',
            bytes: Uint8List.fromList([37, 80, 68, 70]),
          ),
          WorkPickedProof(
            fileName: 'broken.png',
            contentType: 'image/png',
            bytes: Uint8List.fromList([1, 2, 3]),
          ),
        ]) {
          await expectLater(
            store().save(product: product, picked: picked),
            throwsA(isA<WorkGatewayException>()),
          );
        }
        final photo = await store().save(
          product: product,
          picked: await selectedImage(),
        );
        expect(
          () => WorkspacePrivateProductPhoto.fromJson({
            ...photo.toJson(),
            'sha256': '../other',
          }),
          throwsFormatException,
        );
        expect(
          () => WorkspacePrivateProductPhoto.fromJson({
            ...photo.toJson(),
            'byteLength': 0,
          }),
          throwsFormatException,
        );
        expect(product.privatePhoto, isNull);
      },
    );
  });
  group('LOCALSTOCK durable inventory', () {
    WorkspaceSavedInventory record({bool qa = true, int revision = 1}) =>
        WorkspaceSavedInventory(
          account: 'account-A',
          store: _commandStore.id,
          qa: qa,
          revision: revision,
          savedAt: DateTime.utc(2026, 9, 23),
          products: [
            workspaceMasterCatalogue.last.copyWith(
              stock: 6,
              purchasePrice: 25,
              sellingPrice: 30,
              publicListing: false,
              content: const WorkspaceProductContent(
                description: 'QA retailer-edited pack details',
                highlights: ['Keep dry'],
                specifications: {'Pack': '1 kg'},
              ),
            ),
          ],
          movements: const [],
        );
    test(
      'metadata roundtrip preserves retailer fields and rejects invalid records',
      () {
        final encoded = record().toJson();
        expect(
          WorkspaceSavedInventory.fromJson(
            jsonDecode(jsonEncode(encoded)),
          ).toJson(),
          encoded,
        );
        for (final field in [
          'version',
          'qa',
          'account',
          'revision',
          'products',
        ]) {
          expect(
            () => WorkspaceSavedInventory.fromJson({...encoded, field: null}),
            throwsFormatException,
          );
        }
        final product = record().products.single.toInventoryJson();
        for (final patch in [
          <String, Object?>{'stock': -1},
          {'stock': 1.2},
          {'sellingPrice': '30'},
          {'stockMode': 'unknown'},
          {
            'cataloguePhoto': {'bad': true},
          },
        ]) {
          expect(
            () => WorkspaceCatalogueItem.fromInventoryJson({
              ...product,
              ...patch,
            }),
            throwsFormatException,
          );
        }
        expect(
          () => WorkspaceSavedInventory.fromJson({
            ...encoded,
            'products': [product, product],
          }),
          throwsFormatException,
        );
      },
    );
    test(
      'QA production and account scopes are separate and corrupt bytes retained',
      () async {
        final device = _OrderJournalStorage();
        final owner = _CommandAccountStore();
        final storage = SecureWorkInventoryStore(
          accountScope: () => owner.accountScope,
          storage: device,
        );
        await storage.save(record(), expectedRevision: null);
        expect(
          (await storage.read(
            'account-A',
            _commandStore.id,
            qa: true,
          ))!.products.single.stock,
          6,
        );
        expect(
          await storage.read('account-A', _commandStore.id, qa: false),
          isNull,
        );
        expect(
          await storage.read('account-A', 'other-store', qa: true),
          isNull,
        );
        owner.accountScope = 'account-B';
        await expectLater(
          storage.read('account-A', _commandStore.id, qa: true),
          throwsA(isA<WorkGatewayException>()),
        );
        owner.accountScope = 'account-A';
        final key = device.values.keys.single;
        device.values[key] = '{broken';
        await expectLater(
          storage.read('account-A', _commandStore.id, qa: true),
          throwsA(isA<WorkGatewayException>()),
        );
        expect(device.values[key], '{broken');
      },
    );
    test('lost native response is confirmed by exact readback', () async {
      final device = _OrderJournalStorage()..loseWriteResponseOnce = true;
      final storage = SecureWorkInventoryStore(
        accountScope: () => 'account-A',
        storage: device,
      );
      await storage.save(record(), expectedRevision: null);
      await storage.save(record(), expectedRevision: null);
      expect(device.writes, hasLength(1));
      expect(
        (await storage.read('account-A', _commandStore.id, qa: true))!.revision,
        1,
      );
    });
    test(
      'concurrent stale writers cannot replace the winning record',
      () async {
        final device = _OrderJournalStorage()..holdWrite = Completer<void>();
        final storage = SecureWorkInventoryStore(
          accountScope: () => 'account-A',
          storage: device,
        );
        final first = storage.save(record(), expectedRevision: null);
        await _drainOrderJournal();
        final stale = storage.save(record(revision: 2), expectedRevision: null);
        final rejected = expectLater(
          stale,
          throwsA(isA<WorkGatewayException>()),
        );
        device.holdWrite!.complete();
        await first;
        await rejected;
        expect(device.writes, hasLength(1));
        expect(
          (await storage.read(
            'account-A',
            _commandStore.id,
            qa: true,
          ))!.revision,
          1,
        );
      },
    );
    test('account switch cannot acknowledge an in-flight save', () async {
      final device = _OrderJournalStorage()..holdWrite = Completer<void>();
      final owner = _CommandAccountStore();
      final storage = SecureWorkInventoryStore(
        accountScope: () => owner.accountScope,
        storage: device,
      );
      final saving = storage.save(record(), expectedRevision: null);
      final rejected = expectLater(
        saving,
        throwsA(isA<WorkGatewayException>()),
      );
      await _drainOrderJournal();
      owner.accountScope = 'account-B';
      device.holdWrite!.complete();
      await rejected;
      expect(
        await storage.read('account-B', _commandStore.id, qa: true),
        isNull,
      );
      owner.accountScope = 'account-A';
      expect(
        await storage.read('account-A', _commandStore.id, qa: true),
        isNotNull,
      );
    });
    test('stale writes cannot overwrite a newer revision', () async {
      final device = _OrderJournalStorage();
      final storage = SecureWorkInventoryStore(
        accountScope: () => 'account-A',
        storage: device,
      );
      await storage.save(record(), expectedRevision: null);
      await storage.save(record(revision: 2), expectedRevision: 1);
      await expectLater(
        storage.save(record(), expectedRevision: null),
        throwsA(isA<WorkGatewayException>()),
      );
      expect(
        (await storage.read('account-A', _commandStore.id, qa: true))!.revision,
        2,
      );
    });
    test(
      'normal save survives a fresh session without catalogue seeds or financial records',
      () async {
        final device = _OrderJournalStorage();
        final owner = _CommandAccountStore();
        WorkSession fresh() => WorkSession(
          gateway: ReviewWorkGateway(),
          contactDraftStore: owner,
          inventoryStore: SecureWorkInventoryStore(
            accountScope: () => owner.accountScope,
            storage: device,
          ),
        )..activeWorkspace = _commandStore;
        final first = fresh();
        expect(await first.loadWorkspaceInventory(), isTrue);
        expect(first.workspaceCatalogueItems, isEmpty);
        first.addOrUpdateWorkspaceProduct(record().products.single);
        expect(await first.workspaceInventorySaved, isTrue);
        final movements = first.workspaceStockMovements
            .map((m) => m.id)
            .toList();
        first.dispose();
        final restarted = fresh();
        addTearDown(restarted.dispose);
        expect(await restarted.loadWorkspaceInventory(), isTrue);
        expect(
          restarted.workspaceCatalogueItems.single.toInventoryJson(),
          record().products.single.toInventoryJson(),
        );
        expect(
          restarted.workspaceStockMovements.map((m) => m.id).toList(),
          movements,
        );
        expect(restarted.workspaceInvoices, isEmpty);
        expect(restarted.workspaceOrders, isEmpty);
        expect(restarted.workspaceFinance, isNull);
        restarted.addOrUpdateWorkspaceProduct(
          restarted.workspaceCatalogueItems.single.copyWith(stock: 4),
        );
        expect(await restarted.workspaceInventorySaved, isTrue);
        expect(
          (await SecureWorkInventoryStore(
                accountScope: () => owner.accountScope,
                storage: device,
              ).read('account-A', _commandStore.id, qa: true))!
              .products
              .single
              .stock,
          4,
        );
      },
    );
    for (final interrupted in [false, true]) {
      test(
        'reviewed CSV stock survives restart interrupted=$interrupted',
        () async {
          final device = _OrderJournalStorage()..failWrite = interrupted;
          WorkSession fresh() => WorkSession(
            contactDraftStore: _CommandAccountStore(),
            inventoryStore: SecureWorkInventoryStore(
              accountScope: () => 'account-A',
              storage: device,
            ),
          )..activeWorkspace = _commandStore;
          final work = fresh();
          expect(await work.loadWorkspaceInventory(), isTrue);
          // Explicit QA commercial values, no catalogue seed or fake barcode.
          final review = WorkspaceProductImport.parse(
            'title,brand,pack,purchasePrice,sellingPrice,stock,sku\n'
            'Tata Salt,Tata,1 kg,25,30,6,QA-SALT-1KG',
            catalogue: const [],
            owned: const [],
          );
          final product = review.rows.single.product!;
          work.importWorkspaceProducts([product], addOnly: true);
          expect(await work.workspaceInventorySaved, !interrupted);
          if (interrupted) {
            expect(work.workspaceInventoryError, isNotNull);
            device.failWrite = false;
            expect(await work.retryWorkspaceInventorySave(), isTrue);
          }
          final before = work.workspaceCatalogueItems.single.toInventoryJson();
          final movementIds = work.workspaceStockMovements
              .map((m) => m.id)
              .toList();
          work.dispose();
          final reopened = fresh();
          addTearDown(reopened.dispose);
          expect(await reopened.loadWorkspaceInventory(), isTrue);
          expect(
            reopened.workspaceCatalogueItems.single.toInventoryJson(),
            before,
          );
          expect(
            reopened.workspaceStockMovements.map((m) => m.id).toList(),
            movementIds,
          );
          expect(
            reopened.workspaceCatalogueItems.single.cataloguePhoto,
            isNull,
          );
          expect(reopened.workspaceInvoices, isEmpty);
          expect(reopened.workspaceOrders, isEmpty);
        },
      );
    }
    test(
      'failed device write stays visible and explicit retry recovers',
      () async {
        final device = _OrderJournalStorage()..failWrite = true;
        final work = WorkSession(
          contactDraftStore: _CommandAccountStore(),
          inventoryStore: SecureWorkInventoryStore(
            accountScope: () => 'account-A',
            storage: device,
          ),
        )..activeWorkspace = _commandStore;
        addTearDown(work.dispose);
        expect(await work.loadWorkspaceInventory(), isTrue);
        work.addOrUpdateWorkspaceProduct(record().products.single);
        expect(await work.workspaceInventorySaved, isFalse);
        expect(work.workspaceInventoryError, isNotNull);
        expect(work.workspaceCatalogueItems.single.stock, 6);
        device.failWrite = false;
        expect(await work.retryWorkspaceInventorySave(), isTrue);
        expect(work.workspaceInventoryError, isNull);
      },
    );
  });

  test('CSV37 add-only rejects entire batch without overwriting stock', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterSecureStorage.setMockInitialValues({});
    final work = WorkSession(gateway: ReviewWorkGateway());
    addTearDown(work.dispose);
    final rows = WorkspaceProductImport.parse(
      'title,brand,pack,purchasePrice,sellingPrice,stock,sku,barcode\n'
      'Rice,Local,1 kg,40,50,4,RICE01,000001\n'
      'Tea,Local,1 kg,40,50,3,TEA01,000002\n'
      'Coffee,Local,1 kg,40,50,2,COFFEE01,000003',
      catalogue: const [],
      owned: const [],
    ).rows;
    final rice = rows.first.product!,
        tea = rows[1].product!,
        coffee = rows.last.product!;
    work.workspaceCatalogueItems
      ..clear()
      ..add(rice);
    final movements = List.of(work.workspaceStockMovements);
    for (final duplicate in [
      rice.copyWith(title: tea.title, sku: tea.sku, barcode: tea.barcode),
      tea.copyWith(sku: ' rice01 '),
      tea.copyWith(barcode: rice.barcode),
      tea.copyWith(
        title: rice.title,
        brand: rice.brand,
        pack: rice.pack,
        variant: rice.variant,
      ),
      tea.copyWith(stock: -1),
      tea.copyWith(publicListing: true),
    ]) {
      expect(
        () => work.importWorkspaceProducts([coffee, duplicate], addOnly: true),
        throwsFormatException,
      );
      expect(work.workspaceCatalogueItems, [rice]);
      expect(work.workspaceStockMovements, movements);
    }
    work.workspaceCatalogueItems.clear();
    expect(
      () => work.importWorkspaceProducts([
        tea,
        coffee.copyWith(sku: tea.sku),
      ], addOnly: true),
      throwsFormatException,
    );
    expect(work.workspaceCatalogueItems, isEmpty);
    expect(work.workspaceStockMovements, movements);
    work.importWorkspaceProducts([rice, tea], addOnly: true);
    expect(work.workspaceCatalogueItems, [rice, tea]);
    expect(work.workspaceCatalogueItems.every((p) => !p.publicListing), isTrue);
    // Intentional legacy update callers retain their previous behaviour.
    work.importWorkspaceProducts([rice.copyWith(stock: 9)]);
    expect(work.workspaceCatalogueItems, hasLength(2));
    expect(work.workspaceCatalogueItems.first.stock, 9);
  });

  group('COUNTERRELAUNCH review Store recovery', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      FlutterSecureStorage.setMockInitialValues({});
    });

    test(
      'production constructor never reads or promotes a review selection',
      () async {
        final store = _ReviewSelectionFixtureStore(
          StoreReviewSeed(
            accountScope: 'account-A',
            orderCount: 12,
            now: DateTime.utc(2026, 9, 19),
          ),
        );
        final work = WorkSession.production(
          gateway: ReviewWorkGateway(),
          contactDraftStore: _CommandAccountStore(),
          proofPicker: ReviewWorkProofPicker(),
          reviewStoreSelectionStore: store,
        );
        addTearDown(work.dispose);
        await work.loadInitialWorkspaceState();
        expect(store.reads, 0);
        expect(work.activeWorkspace, isNull);
        expect(work.hasVerifiedWorkspace, isFalse);
        expect(work.canLoadStoreReviewSeed, isFalse);
      },
    );

    test(
      'disabled review mode cannot read or seed a Store',
      () async {
        final native = _OrderJournalStorage();
        final store = SecureWorkReviewStoreSelectionStore(
          accountScope: () => 'account-A',
          storage: native,
        );
        await expectLater(
          store.read('account-A'),
          throwsA(isA<WorkGatewayException>()),
        );
        expect(native.values, isEmpty);
        final work = WorkSession(
          gateway: ReviewWorkGateway(),
          contactDraftStore: _CommandAccountStore(),
          reviewStoreSelectionStore: store,
        );
        addTearDown(work.dispose);
        await work.loadInitialWorkspaceState();
        expect(work.activeWorkspace, isNull);
      },
      skip: SecureWorkReviewStoreSelectionStore.enabled,
    );

    group('enabled fixture mode', () {
      test(
        'selected Store retains imported stock and photo identity through invoice restart',
        () async {
          final account = _CommandAccountStore();
          final native = _OrderJournalStorage();
          WorkSession open() => WorkSession(
            gateway: ReviewWorkGateway(),
            contactDraftStore: account,
            inventoryStore: SecureWorkInventoryStore(
              accountScope: () => account.accountScope,
              storage: native,
            ),
            reviewStoreSelectionStore: SecureWorkReviewStoreSelectionStore(
              accountScope: () => account.accountScope,
              storage: native,
            ),
          );
          final first = open()..activeWorkspace = _commandStore;
          expect(
            first.loadStoreReviewSeed(12, now: DateTime.utc(2026, 9, 19)),
            isTrue,
          );
          expect(await first.storeReviewSelectionSaved, isTrue);
          expect(await first.recoverCustomerLedger(), isTrue);
          expect(await first.loadWorkspaceInventory(), isTrue);
          final original = first.workspaceCatalogueItems.first;
          final edited = original.copyWith(
            sellingPrice: 270,
            cataloguePhoto: WorkspaceCataloguePhoto(
              assetId: 'qa-exact-pack',
              revision: '1',
              source: 'https://example.test/qa-exact-pack.jpg',
              publisherWorkspaceId: 'qa-catalogue',
              canonicalId: original.canonicalId,
              brand: original.brand,
              variant: original.variant,
              pack: original.pack,
              barcode: original.barcode,
              file: const BuyV2MediaFileMetadata(
                mimeType: 'image/jpeg',
                byteLength: 100,
                width: 100,
                height: 100,
                normalized: true,
              ),
              status: WorkspaceCataloguePhotoStatus.testOnly,
            ),
          );
          first.addOrUpdateWorkspaceProduct(edited);
          expect(await first.workspaceInventorySaved, isTrue);
          final imported = WorkspaceProductImport.parse(
            'title,brand,pack,purchasePrice,sellingPrice,stock,sku\n'
            'QA Rice,QA,1 kg,80,101,100,QA-RICE\n'
            'QA Tea,QA,500 g,80,108,0,QA-TEA',
            catalogue: const [],
            owned: const [],
          ).rows.map((row) => row.product!).toList();
          first.importWorkspaceProducts(imported, addOnly: true);
          expect(await first.workspaceInventorySaved, isTrue);
          final storeId = first.activeWorkspace!.id;
          final saved = await SecureWorkInventoryStore(
            accountScope: () => account.accountScope,
            storage: native,
          ).read(account.accountScope!, storeId, qa: true);
          expect(
            saved,
            isNotNull,
            reason: 'Selected review Stores must not bypass durable stock.',
          );
          final before = first.workspaceCatalogueItems
              .map((p) => p.toInventoryJson())
              .toList();
          first.dispose();

          final second = open();
          await second.loadInitialWorkspaceState();
          expect(second.customerLedgerRecoveryError, isNull);
          expect(
            second.workspaceCatalogueItems
                .map((p) => p.toInventoryJson())
                .toList(),
            before,
          );
          expect(second.startNewWorkspaceOrder(), isTrue);
          await second.loadWorkspaceCounterDraft();
          second.adjustWorkspaceOrderQuantity(imported.first.id, 2);
          second.updateWorkspaceCounterDetails(
            customer: '9000091934',
            payment: 'Cash',
          );
          final bill = await second.submitWorkspaceCounterBill();
          expect(bill?.invoice, isNotNull);
          final after = second.workspaceCatalogueItems
              .map((p) => p.toInventoryJson())
              .toList();
          second.dispose();

          final third = open();
          await third.loadInitialWorkspaceState();
          expect(third.customerLedgerRecoveryError, isNull);
          expect(
            third.workspaceCatalogueItems
                .map((p) => p.toInventoryJson())
                .toList(),
            after,
          );
          expect(
            third.workspaceInvoices.single.toLedgerJson(),
            bill!.invoice!.toLedgerJson(),
          );
          expect(
            third.workspaceCatalogueItems.first.cataloguePhoto!.toJson(),
            edited.cataloguePhoto!.toJson(),
          );
          final inventoryKey = native.values.keys.singleWhere(
            (key) => key.contains('workspace.inventory.'),
          );
          final preserved = native.values[inventoryKey]!;
          third.dispose();

          // Missing legacy metadata must not be fabricated from ledger quantities.
          native.values.remove(inventoryKey);
          final missing = open();
          await missing.loadInitialWorkspaceState();
          expect(missing.customerLedgerRecoveryError, isNotNull);
          expect(
            missing.workspaceCatalogueItems.any(
              (p) => p.id == imported.first.id,
            ),
            isFalse,
          );
          expect(native.values.containsKey(inventoryKey), isFalse);
          missing.dispose();

          native.values[inventoryKey] = '{corrupt';
          final corrupt = open();
          await corrupt.loadInitialWorkspaceState();
          expect(corrupt.customerLedgerRecoveryError, isNotNull);
          expect(native.values[inventoryKey], '{corrupt');
          native.values[inventoryKey] = preserved;
          expect(await corrupt.recoverCustomerLedger(), isTrue);
          expect(corrupt.customerLedgerRecoveryError, isNull);
          corrupt.dispose();

          native.values[inventoryKey] = preserved;
          final retry = open();
          addTearDown(retry.dispose);
          await retry.loadInitialWorkspaceState();
          expect(retry.customerLedgerRecoveryError, isNull);
          expect(
            retry.workspaceCatalogueItems
                .map((p) => p.toInventoryJson())
                .toList(),
            after,
          );
          expect(retry.startNewWorkspaceOrder(), isTrue);
          await retry.loadWorkspaceCounterDraft();
          retry.adjustWorkspaceOrderQuantity(imported.first.id, 1);
          retry.updateWorkspaceCounterDetails(
            customer: '9000091934',
            payment: 'Cash',
          );
          native.failWrite = true;
          retry.addOrUpdateWorkspaceProduct(
            retry.workspaceCatalogueItems.first.copyWith(sellingPrice: 271),
          );
          expect(await retry.workspaceInventorySaved, isFalse);
          final invoiceCount = retry.workspaceInvoices.length;
          expect(await retry.submitWorkspaceCounterBill(), isNull);
          expect(retry.workspaceInvoices.length, invoiceCount);
          expect(retry.workspaceOrderQuantities[imported.first.id], 1);
          native.failWrite = false;
          expect(await retry.retryWorkspaceInventorySave(), isTrue);
          expect(
            (await retry.submitWorkspaceCounterBill())?.invoice,
            isNotNull,
          );
        },
      );

      test(
        'encrypted selection retains original seed and rejects corrupt/cross-account data',
        () async {
          final account = _CommandAccountStore();
          final native = _OrderJournalStorage();
          SecureWorkReviewStoreSelectionStore open() =>
              SecureWorkReviewStoreSelectionStore(
                accountScope: () => account.accountScope,
                storage: native,
              );
          final seed = StoreReviewSeed(
            accountScope: 'account-A',
            orderCount: 12,
            now: DateTime.utc(2026, 9, 19, 2, 40),
          );
          await open().save(seed);
          final restored = (await open().read('account-A'))!;
          expect(restored.storeId, seed.storeId);
          expect(restored.now, seed.now);
          expect(restored.orders.first.createdAt, seed.orders.first.createdAt);
          expect(native.values.values.single, isNot(contains('verified')));
          account.accountScope = 'account-B';
          expect(await open().read('account-B'), isNull);
          await expectLater(
            open().read('account-A'),
            throwsA(isA<WorkGatewayException>()),
          );
          account.accountScope = 'account-A';
          final key = native.values.keys.single;
          native.values[key] = '{"version":99}';
          await expectLater(
            open().read('account-A'),
            throwsA(isA<WorkGatewayException>()),
          );
          await expectLater(
            open().save(seed),
            throwsA(isA<WorkGatewayException>()),
          );
          expect(native.values[key], '{"version":99}');
        },
      );

      test(
        'fresh session reopens selected Store, discounted draft and completed invoice',
        () async {
          final account = _CommandAccountStore();
          final native = _OrderJournalStorage();
          WorkSession open() => WorkSession(
            gateway: ReviewWorkGateway(),
            contactDraftStore: account,
            reviewStoreSelectionStore: SecureWorkReviewStoreSelectionStore(
              accountScope: () => account.accountScope,
              storage: native,
            ),
            counterDraftStore: SecureWorkCounterDraftStore(
              accountScope: () => account.accountScope,
              storage: native,
            ),
          );
          final first = open()..activeWorkspace = _commandStore;
          expect(
            first.loadStoreReviewSeed(12, now: DateTime.utc(2026, 9, 19)),
            isTrue,
          );
          expect(await first.storeReviewSelectionSaved, isTrue);
          expect(await first.recoverCustomerLedger(), isTrue);
          final storeId = first.activeWorkspace!.id;
          final productId = first.workspaceCatalogueItems.first.id;
          expect(first.startNewWorkspaceOrder(), isTrue);
          await first.loadWorkspaceCounterDraft();
          first.adjustWorkspaceOrderQuantity(productId, 2);
          first.updateWorkspaceCounterDetails(
            customer: '9000091934',
            payment: 'Bank Transfer',
            billingDetails: const WorkspaceBillingDetails(
              name: 'Relaunch customer',
            ),
          );
          expect(
            first.updateWorkspaceCounterDiscount(
              const WorkspaceBillDiscount.fixed(525),
            ),
            isTrue,
          );
          expect(await first.saveWorkspaceCounterDraft(), isTrue);
          final total = first.workspaceCounterPayableMinor;
          first.dispose();

          final second = open();
          expect(second.activeWorkspace, isNull);
          await second.loadInitialWorkspaceState();
          expect(second.initialWorkspaceStateLoaded, isTrue);
          expect(second.activeWorkspace?.id, storeId);
          expect(second.activeWorkspace?.name, startsWith('TEST Store'));
          expect(second.customerLedgerRecoveryError, isNull);
          expect(second.startNewWorkspaceOrder(), isTrue);
          await second.loadWorkspaceCounterDraft();
          expect(second.workspaceOrderCustomer, '9000091934');
          expect(second.workspaceOrderBillingDetails.name, 'Relaunch customer');
          expect(second.workspaceOrderPayment, 'Bank Transfer');
          expect(second.workspaceOrderQuantities[productId], 2);
          expect(second.workspaceCounterPayableMinor, total);
          final submitted = await second.submitWorkspaceCounterBill();
          expect(submitted?.invoice, isNotNull);
          final invoice = submitted!.invoice!;
          final stock = second.workspaceCatalogueItems.first.stock;
          second.dispose();

          final third = open();
          addTearDown(third.dispose);
          await third.loadInitialWorkspaceState();
          expect(third.activeWorkspace?.id, storeId);
          expect(
            third.workspaceInvoices.single.toLedgerJson(),
            invoice.toLedgerJson(),
          );
          expect(third.workspaceCatalogueItems.first.stock, stock);
          expect(
            third.workspaceFinance!.payments
                .singleWhere((p) => p.invoiceId == invoice.id)
                .dueMinor,
            total,
          );
        },
      );

      test(
        'selection read failure is retryable without creating a Store',
        () async {
          final selection = _ReviewSelectionFixtureStore(
            StoreReviewSeed(
              accountScope: 'account-A',
              orderCount: 12,
              now: DateTime.utc(2026, 9, 19),
            ),
          )..failRead = true;
          final work = WorkSession(
            gateway: ReviewWorkGateway(),
            contactDraftStore: _CommandAccountStore(),
            reviewStoreSelectionStore: selection,
          );
          addTearDown(work.dispose);
          await work.loadInitialWorkspaceState();
          expect(work.activeWorkspace, isNull);
          expect(work.initialWorkspaceStateLoaded, isFalse);
          expect(work.errorMessage, isNotNull);
          selection.failRead = false;
          await work.loadInitialWorkspaceState();
          expect(work.activeWorkspace?.id, selection.seed!.storeId);
          expect(work.initialWorkspaceStateLoaded, isTrue);
        },
      );

      test(
        'account change during read cannot activate the previous Store',
        () async {
          final account = _CommandAccountStore();
          final selection = _ReviewSelectionFixtureStore(
            StoreReviewSeed(
              accountScope: 'account-A',
              orderCount: 12,
              now: DateTime.utc(2026, 9, 19),
            ),
          )..holdRead = Completer<void>();
          final work = WorkSession(
            gateway: ReviewWorkGateway(),
            contactDraftStore: account,
            reviewStoreSelectionStore: selection,
          );
          addTearDown(work.dispose);
          final opening = work.loadInitialWorkspaceState();
          while (selection.reads == 0) {
            await Future<void>.delayed(const Duration(milliseconds: 5));
          }
          account.accountScope = 'account-B';
          selection.holdRead!.complete();
          await opening;
          expect(work.activeWorkspace, isNull);
          expect(work.initialWorkspaceStateLoaded, isFalse);
        },
      );
    }, skip: !SecureWorkReviewStoreSelectionStore.enabled);
  });

  group('COUNTERDISCOUNT currency rules', () {
    test('percentage and fixed values round once to paise', () {
      expect(
        WorkspaceBillDiscount.parse('percentage', '10').amountFor(10500),
        1050,
      );
      expect(
        WorkspaceBillDiscount.parse('fixed', '10.50').amountFor(10500),
        1050,
      );
      expect(WorkspaceBillDiscount.parse('percentage', '50').amountFor(1), 1);
      expect(
        WorkspaceBillDiscount.parse('percentage', '16.67').amountFor(300),
        50,
      );
      for (final kind in ['percentage', 'fixed']) {
        for (final value in [
          '',
          '-1',
          '0',
          '1.001',
          '1e2',
          'NaN',
          '₹10',
          '1,000',
        ]) {
          expect(
            () => WorkspaceBillDiscount.parse(kind, value),
            throwsFormatException,
          );
        }
      }
      expect(
        () => WorkspaceBillDiscount.parse('percentage', '100.01'),
        throwsFormatException,
      );
      expect(
        const WorkspaceBillDiscount.percentage(10000).validFor(10000),
        isFalse,
      );
      expect(const WorkspaceBillDiscount.fixed(10000).validFor(10000), isFalse);
      expect(const WorkspaceBillDiscount.none().validFor(0), isTrue);
      expect(WorkspaceBillDiscount.fromJson(null).isEmpty, isTrue);
      expect(
        () => WorkspaceBillDiscount.fromJson({'kind': 'fixed', 'value': 1.5}),
        throwsFormatException,
      );
    });
  });

  test(
    'CSINVOICE bank receipt requires reference and recovers without duplicate',
    () async {
      final seed = StoreReviewSeed(
        accountScope: 'account-A',
        orderCount: 12,
        now: DateTime.utc(2026, 9, 20),
      );
      final work = WorkSession(
        gateway: ReviewWorkGateway(),
        pendingProofStore: _CommandAccountStore(),
      )..activeWorkspace = seed.workspace;
      addTearDown(work.dispose);
      expect(work.applyWorkspaceFinance(seed.finance), isTrue);
      final adapter = _LostCollectionGateway(seed.finance);
      final journal = SecureWorkLedgerCheckpointStore(
        accountScope: () => 'account-A',
        storage: _OrderJournalStorage(),
      );
      expect(
        work.bindCustomerCollectionGateway(
          accountScope: 'account-A',
          storeId: seed.storeId,
          adapter: adapter,
          checkpointStore: journal,
        ),
        isTrue,
      );
      final original = seed.finance.payments.first;
      Future<bool> record(String reference) => work.recordCustomerCollection(
        customerId: original.customerId,
        invoiceId: original.invoiceId!,
        amountMinor: original.dueMinor,
        channel: WorkspacePaymentChannel.bankTransfer,
        reference: reference,
      );
      expect(await record('  '), isFalse);
      expect(adapter.submissions, 0);
      expect(await record('TEST-BANK-001'), isFalse);
      expect(adapter.submissions, 1);
      expect(work.pendingCustomerCollection, isNotNull);
      expect(await work.reconcileCustomerCollection(), isTrue);
      expect(await work.reconcileCustomerCollection(), isFalse);
      expect(adapter.submissions, 1);
      final payment = work.workspaceFinance!.payments.singleWhere(
        (p) => p.invoiceId == original.invoiceId,
      );
      expect(payment.channel, WorkspacePaymentChannel.bankTransfer);
      expect(payment.state, WorkspacePaymentState.paid);
      expect(payment.dueMinor, 0);
      expect(payment.label, 'Paid by bank transfer');
      expect(await record('TEST-BANK-001'), isFalse);
      final restored = await journal.read('account-A', seed.storeId);
      expect(
        restored!.finance.payments
            .singleWhere((p) => p.invoiceId == original.invoiceId)
            .channel,
        WorkspacePaymentChannel.bankTransfer,
      );
      expect(work.workspaceStockMovements, isEmpty);
    },
  );

  group('CSENH015 invoice delivery preference', () {
    const preference = WorkspaceInvoiceDeliveryPreference(
      account: 'account-A',
      store: 'store-A',
      mode: WorkspaceInvoiceDeliveryMode.automatic,
    );

    test(
      'strict round trip is a preference, never consent or delivery proof',
      () {
        for (final mode in WorkspaceInvoiceDeliveryMode.values) {
          final value = WorkspaceInvoiceDeliveryPreference(
            account: 'a',
            store: 's',
            mode: mode,
          );
          expect(
            WorkspaceInvoiceDeliveryPreference.fromJson(value.toJson())!.mode,
            mode,
          );
          expect(
            value.toJson().keys,
            unorderedEquals(['version', 'account', 'store', 'mode']),
          );
        }
        for (final invalid in [
          null,
          '',
          {},
          {...preference.toJson(), 'version': 2},
          {...preference.toJson(), 'mode': 'sent'},
          {...preference.toJson(), 'account': ''},
          {...preference.toJson(), 'store': 3},
        ]) {
          expect(WorkspaceInvoiceDeliveryPreference.fromJson(invalid), isNull);
        }
      },
    );

    test('reopens saved choice and isolates account and Store', () async {
      final bytes = _OrderJournalStorage();
      var account = 'account-A', store = 'store-A';
      SecureWorkInvoiceDeliveryPreferenceStore reopen() =>
          SecureWorkInvoiceDeliveryPreferenceStore(
            accountScope: () => account,
            storeScope: () => store,
            storage: bytes,
          );
      expect(await reopen().read(account, store), isNull);
      await reopen().save(preference);
      expect(
        (await reopen().read(account, store))!.mode,
        WorkspaceInvoiceDeliveryMode.automatic,
      );
      store = 'store-B';
      expect(await reopen().read(account, store), isNull);
      await expectLater(
        reopen().save(preference),
        throwsA(isA<WorkGatewayException>()),
      );
      store = 'store-A';
      account = 'account-B';
      expect(await reopen().read(account, store), isNull);
      await expectLater(
        reopen().read('account-A', store),
        throwsA(isA<WorkGatewayException>()),
      );
      expect(bytes.writes, hasLength(1));
    });

    test('corrupt preference is not overwritten or silently reset', () async {
      final bytes = _OrderJournalStorage();
      final prefs = SecureWorkInvoiceDeliveryPreferenceStore(
        accountScope: () => 'account-A',
        storeScope: () => 'store-A',
        storage: bytes,
      );
      await prefs.save(preference);
      final key = bytes.values.keys.single;
      bytes.values[key] = '{invalid';
      await expectLater(
        prefs.read('account-A', 'store-A'),
        throwsA(isA<WorkGatewayException>()),
      );
      await expectLater(
        prefs.save(preference),
        throwsA(isA<WorkGatewayException>()),
      );
      expect(bytes.values[key], '{invalid');
      expect(bytes.writes, hasLength(1));
    });

    test(
      'write failure retains last saved choice and lost reply can be read back',
      () async {
        final bytes = _OrderJournalStorage();
        final prefs = SecureWorkInvoiceDeliveryPreferenceStore(
          accountScope: () => 'account-A',
          storeScope: () => 'store-A',
          storage: bytes,
        );
        await prefs.save(preference);
        const off = WorkspaceInvoiceDeliveryPreference(
          account: 'account-A',
          store: 'store-A',
        );
        bytes.failWrite = true;
        await expectLater(prefs.save(off), throwsStateError);
        expect(
          (await prefs.read('account-A', 'store-A'))!.mode,
          WorkspaceInvoiceDeliveryMode.automatic,
        );
        bytes.failWrite = false;
        bytes.loseWriteResponseOnce = true;
        await expectLater(prefs.save(off), throwsStateError);
        expect(
          (await prefs.read('account-A', 'store-A'))!.mode,
          WorkspaceInvoiceDeliveryMode.off,
        );
      },
    );

    test(
      'scope changes during pending save cannot claim success in another Store',
      () async {
        final bytes = _OrderJournalStorage()..holdWrite = Completer<void>();
        var store = 'store-A';
        final prefs = SecureWorkInvoiceDeliveryPreferenceStore(
          accountScope: () => 'account-A',
          storeScope: () => store,
          storage: bytes,
        );
        final saving = prefs.save(preference);
        final failure = expectLater(
          saving,
          throwsA(isA<WorkGatewayException>()),
        );
        await _drainOrderJournal();
        store = 'store-B';
        bytes.holdWrite!.complete();
        await failure;
        expect(await prefs.read('account-A', 'store-B'), isNull);
      },
    );

    test(
      'serial writes retain latest explicitly selected preference',
      () async {
        final bytes = _OrderJournalStorage();
        final prefs = SecureWorkInvoiceDeliveryPreferenceStore(
          accountScope: () => 'account-A',
          storeScope: () => 'store-A',
          storage: bytes,
        );
        await Future.wait([
          prefs.save(preference),
          prefs.save(
            const WorkspaceInvoiceDeliveryPreference(
              account: 'account-A',
              store: 'store-A',
              mode: WorkspaceInvoiceDeliveryMode.whatsapp,
            ),
          ),
        ]);
        expect(
          (await prefs.read('account-A', 'store-A'))!.mode,
          WorkspaceInvoiceDeliveryMode.whatsapp,
        );
      },
    );
  });

  group('COUNTER1919 UPI destination', () {
    const destination = WorkspaceUpiDestination(
      account: 'account-A',
      store: 'store-A',
      address: 'synthetic-store@examplebank',
      payeeName: 'Store & Sons',
    );

    test('round trips destination without asserting bank verification', () {
      expect(destination.valid, isTrue);
      expect(
        WorkspaceUpiDestination.fromJson(destination.toJson())!.toJson(),
        destination.toJson(),
      );
      expect(destination.toJson().containsKey('verified'), isFalse);
    });

    test('encodes exact retailer destination and integer paise', () {
      for (final (paise, encoded) in [
        (1, '0.01'),
        (26400, '264.00'),
        (26409, '264.09'),
      ]) {
        final uri = destination.paymentUri(
          expectedAccount: 'account-A',
          expectedStore: 'store-A',
          amountPaise: paise,
          reference: 'counter-1919',
        );
        expect(uri.scheme, 'upi');
        expect(uri.host, 'pay');
        expect(uri.queryParameters, {
          'pa': 'synthetic-store@examplebank',
          'pn': 'Store & Sons',
          'tr': 'counter-1919',
          'tn': 'Counter Sale',
          'am': encoded,
          'cu': 'INR',
        });
      }
    });

    test('rejects cross-account Store and malformed requests', () {
      for (final (account, store, amount, reference) in [
        ('account-B', 'store-A', 100, 'counter-1'),
        ('account-A', 'store-B', 100, 'counter-1'),
        ('account-A', 'store-A', 0, 'counter-1'),
        ('account-A', 'store-A', -1, 'counter-1'),
        ('account-A', 'store-A', 100, ''),
        ('account-A', 'store-A', 100, 'counter&pa=other@bank'),
      ]) {
        expect(
          () => destination.paymentUri(
            expectedAccount: account,
            expectedStore: store,
            amountPaise: amount,
            reference: reference,
          ),
          throwsFormatException,
        );
      }
    });

    test('rejects corrupt saved destination and URI injection', () {
      for (final overrides in <Map<String, Object?>>[
        {'version': 2},
        {'account': ''},
        {'store': ''},
        {'address': ''},
        {'address': 'store@bank&am=1'},
        {'address': 'store@bank\n'},
        {'payeeName': 'Store\nOther'},
        {'payeeName': ' '},
        {'merchantCode': 'abc'},
      ]) {
        expect(
          WorkspaceUpiDestination.fromJson({
            ...destination.toJson(),
            ...overrides,
          }),
          isNull,
        );
      }
    });

    test(
      'encrypted storage restores only the active account and Store',
      () async {
        final storage = _OrderJournalStorage();
        var account = 'account-A';
        var store = 'store-A';
        SecureWorkUpiDestinationStore reopen() => SecureWorkUpiDestinationStore(
          accountScope: () => account,
          storeScope: () => store,
          storage: storage,
        );
        await reopen().save(destination);
        expect(
          (await reopen().read(account, store))!.toJson(),
          destination.toJson(),
        );
        account = 'account-B';
        expect(await reopen().read(account, store), isNull);
        await expectLater(
          reopen().read('account-A', store),
          throwsA(isA<WorkGatewayException>()),
        );
        await expectLater(
          reopen().save(destination),
          throwsA(isA<WorkGatewayException>()),
        );
        account = 'account-A';
        store = 'store-B';
        expect(await reopen().read(account, store), isNull);
        await expectLater(
          reopen().save(destination),
          throwsA(isA<WorkGatewayException>()),
        );
        expect(storage.writes, hasLength(1));
      },
    );

    test(
      'corrupt storage is preserved and read failure never changes payee',
      () async {
        final storage = _OrderJournalStorage();
        final settings = SecureWorkUpiDestinationStore(
          accountScope: () => 'account-A',
          storeScope: () => 'store-A',
          storage: storage,
        );
        await settings.save(destination);
        final key = storage.values.keys.single;
        storage.values[key] = '{invalid';
        await expectLater(
          settings.read('account-A', 'store-A'),
          throwsA(isA<WorkGatewayException>()),
        );
        await expectLater(
          settings.save(destination),
          throwsA(isA<WorkGatewayException>()),
        );
        expect(storage.values[key], '{invalid');
        expect(storage.writes, hasLength(1));
        storage.failRead = true;
        await expectLater(settings.save(destination), throwsStateError);
        expect(storage.writes, hasLength(1));
      },
    );

    test(
      'lost write reply is recovered by reading the persisted destination',
      () async {
        final storage = _OrderJournalStorage()..loseWriteResponseOnce = true;
        final settings = SecureWorkUpiDestinationStore(
          accountScope: () => 'account-A',
          storeScope: () => 'store-A',
          storage: storage,
        );
        await expectLater(settings.save(destination), throwsStateError);
        expect(
          (await settings.read('account-A', 'store-A'))!.address,
          destination.address,
        );
        expect(storage.writes, hasLength(1));
      },
    );

    test(
      'Store change during write cannot report successful active setup',
      () async {
        final storage = _OrderJournalStorage()..holdWrite = Completer<void>();
        var store = 'store-A';
        final settings = SecureWorkUpiDestinationStore(
          accountScope: () => 'account-A',
          storeScope: () => store,
          storage: storage,
        );
        final saving = settings.save(destination);
        final rejected = expectLater(
          saving,
          throwsA(isA<WorkGatewayException>()),
        );
        await _drainOrderJournal();
        expect(storage.writes, hasLength(1));
        store = 'store-B';
        storage.holdWrite!.complete();
        await rejected;
        expect(await settings.read('account-A', 'store-B'), isNull);
        store = 'store-A';
        expect(
          (await settings.read('account-A', store))!.address,
          destination.address,
        );
      },
    );
  });

  test(
    'LEDGER02 supplier save failure and lost reply recover without another payment',
    () async {
      final at = DateTime.utc(2026, 9, 14);
      final seed = StoreReviewSeed(
        accountScope: 'account-A',
        orderCount: 12,
        now: at,
      );
      final storage = _OrderJournalStorage();
      WorkSession openStore() {
        final session = WorkSession(
          gateway: ReviewWorkGateway(),
          pendingProofStore: _CommandAccountStore(),
        )..activeWorkspace = seed.workspace;
        addTearDown(session.dispose);
        expect(session.applyWorkspaceFinance(seed.finance), isTrue);
        expect(
          session.bindCustomerCollectionGateway(
            accountScope: 'account-A',
            storeId: seed.storeId,
            adapter: StoreReviewCustomerCollectionGateway(seed.finance),
            checkpointStore: SecureWorkLedgerCheckpointStore(
              accountScope: () => 'account-A',
              storage: storage,
            ),
          ),
          isTrue,
        );
        return session;
      }

      final supplier = WorkspaceSupplierLedger(
        accountScope: 'account-A',
        workspaceId: seed.storeId,
        supplierId: 'supplier-A',
        supplierName: 'Test supplier',
        revision: 1,
        asOf: at,
        historyComplete: true,
        openingBalanceMinor: 0,
        entries: [
          WorkspaceSupplierLedgerEntry(
            operationId: 'bill-1',
            orderId: 'purchase-1',
            billId: 'bill-1',
            reference: 'BILL-1',
            kind: WorkspaceSupplierEntryKind.bill,
            amountMinor: 200000,
            postedAt: at,
          ),
          WorkspaceSupplierLedgerEntry(
            operationId: 'advance-1',
            orderId: 'purchase-1',
            reference: 'ADVANCE-1',
            kind: WorkspaceSupplierEntryKind.advance,
            amountMinor: 50000,
            postedAt: at,
          ),
        ],
      );
      final session = openStore();
      final settlement = session.workspaceSettlementBalance;
      storage.failWrite = true;
      expect(await session.saveWorkspaceSupplierLedger(supplier), isFalse);
      expect(session.workspaceSupplierLedger('supplier-A'), isNull);
      storage.failWrite = false;
      storage.loseWriteResponseOnce = true;
      expect(await session.saveWorkspaceSupplierLedger(supplier), isFalse);
      final reopened = openStore();
      expect(await reopened.recoverCustomerLedger(), isTrue);
      expect(
        reopened.workspaceSupplierLedger('supplier-A')?.payableMinor,
        150000,
      );
      expect(await reopened.saveWorkspaceSupplierLedger(supplier), isTrue);
      expect(reopened.workspaceSupplierLedger('supplier-A')?.entries.length, 2);
      expect(reopened.workspaceSettlementBalance, settlement);
      expect(reopened.workspaceCatalogueItems, isEmpty);
      expect(reopened.workspacePurchases, isEmpty);
    },
  );
  test(
    'LEDGER02 supplier feed stays separate from stock and account switches',
    () {
      final account = _CommandAccountStore();
      final session =
          WorkSession(gateway: ReviewWorkGateway(), pendingProofStore: account)
            ..activeWorkspace = const WorkWorkspace(
              id: 'store-A',
              name: 'Test Store',
              profileLabel: 'Grocery / Kirana Shop',
              profileId: 'retailer-grocery',
              area: 'Test area',
              verified: true,
            );
      addTearDown(session.dispose);
      final at = DateTime.utc(2026, 9, 14);
      WorkspaceSupplierLedger snapshot({
        String scope = 'account-A',
        int revision = 1,
      }) => WorkspaceSupplierLedger(
        accountScope: scope,
        workspaceId: 'store-A',
        supplierId: 'supplier-A',
        supplierName: 'Test supplier',
        revision: revision,
        asOf: at,
        openingBalanceMinor: 0,
        historyComplete: true,
        entries: [
          WorkspaceSupplierLedgerEntry(
            operationId: 'bill-1',
            orderId: 'purchase-1',
            reference: 'BILL-1',
            billId: 'bill-1',
            kind: WorkspaceSupplierEntryKind.bill,
            amountMinor: 200000,
            postedAt: at,
          ),
          WorkspaceSupplierLedgerEntry(
            operationId: 'advance-1',
            orderId: 'purchase-1',
            reference: 'ADVANCE-1',
            kind: WorkspaceSupplierEntryKind.advance,
            amountMinor: 50000,
            postedAt: at,
          ),
        ],
      );
      final settlement = session.workspaceSettlementBalance;
      expect(session.applyWorkspaceSupplierLedger(snapshot()), isTrue);
      expect(
        session.workspaceSupplierLedger('supplier-A')?.payableMinor,
        150000,
      );
      expect(session.applyWorkspaceSupplierLedger(snapshot()), isTrue);
      expect(session.workspaceSupplierLedger('supplier-A')?.entries.length, 2);
      expect(session.workspacePurchases, isEmpty);
      expect(session.workspaceCatalogueItems, isEmpty);
      expect(session.workspaceSettlementBalance, settlement);
      expect(
        session.applyWorkspaceSupplierLedger(snapshot(scope: 'account-B')),
        isFalse,
      );
      account.accountScope = 'account-B';
      expect(session.workspaceSupplierLedger('supplier-A'), isNull);
      expect(
        session.applyWorkspaceSupplierLedger(snapshot(scope: 'account-B')),
        isTrue,
      );
      account.accountScope = 'account-A';
      expect(
        session.workspaceSupplierLedger('supplier-A')?.accountScope,
        'account-A',
      );
    },
  );
  test(
    'LEDGER02 review bills and payments retain existing purchase identities',
    () {
      final seed = StoreReviewSeed(
        accountScope: 'account-A',
        orderCount: 12,
        now: DateTime.utc(2026, 9, 14),
      );
      final purchases = seed.purchases;
      final ledgers = seed.supplierLedgers;
      expect(ledgers.every((ledger) => ledger.valid), isTrue);
      for (final purchase in purchases) {
        final ledger = ledgers.singleWhere(
          (item) => item.supplierId == purchase.supplierId,
        );
        expect(ledger.accountScope, purchase.accountScope);
        expect(ledger.workspaceId, purchase.workspaceId);
        final entries = ledger.entries
            .where((item) => item.orderId == purchase.orderId)
            .toList();
        expect(entries.length, 2);
        final bill = entries.singleWhere(
          (item) => item.kind == WorkspaceSupplierEntryKind.bill,
        );
        final paid = entries.singleWhere(
          (item) => item.kind != WorkspaceSupplierEntryKind.bill,
        );
        expect(bill.amountMinor, purchase.amountMinor);
        expect(paid.billId, bill.billId);
        expect(paid.amountMinor, lessThanOrEqualTo(bill.amountMinor));
      }
      expect(
        ledgers.expand((ledger) => ledger.entries).length,
        purchases.length * 2,
      );
    },
  );

  test(
    'LEDGER02 partial receipts persist only incremental stock, never money',
    () async {
      final seed = StoreReviewSeed(
        accountScope: 'account-A',
        orderCount: 12,
        now: DateTime.utc(2026, 9, 14),
      );
      final storage = _OrderJournalStorage();
      WorkSession openStore() {
        final session = WorkSession(
          gateway: ReviewWorkGateway(),
          pendingProofStore: _CommandAccountStore(),
        )..activeWorkspace = seed.workspace;
        addTearDown(session.dispose);
        session.workspaceCatalogueItems.addAll(seed.products);
        expect(session.applyWorkspaceFinance(seed.finance), isTrue);
        expect(
          session.bindCustomerCollectionGateway(
            accountScope: seed.accountScope,
            storeId: seed.storeId,
            adapter: StoreReviewCustomerCollectionGateway(seed.finance),
            checkpointStore: SecureWorkLedgerCheckpointStore(
              accountScope: () => seed.accountScope,
              storage: storage,
            ),
          ),
          isTrue,
        );
        return session;
      }

      WorkspacePurchaseRecord receipt(
        int revision,
        int count, {
        WorkspaceReceiptState state = WorkspaceReceiptState.partial,
      }) => WorkspacePurchaseRecord(
        accountScope: seed.accountScope,
        workspaceId: seed.storeId,
        supplierId: 'supplier-A',
        supplierName: 'Test supplier',
        orderId: 'purchase-1',
        shipmentId: 'shipment-1',
        revision: revision,
        createdAt: seed.now,
        updatedAt: seed.now.add(Duration(minutes: revision)),
        stage: WorkspaceSupplyStage.delivered,
        amountMinor: 200000,
        itemSummary: 'Grocery packs',
        paymentLabel: 'Payment pending',
        receiptState: state,
        receiptReference: 'receipt-$revision',
        lines: [
          WorkspacePurchaseLine(
            id: 'line-1',
            productId: 'supplier-sku',
            name: 'Grocery packs',
            pack: '2 units',
            orderedPacks: 10,
            receivedPacks: count,
            unitPriceMinor: 20000,
          ),
        ],
      );
      void publish(WorkSession session, WorkspacePurchaseRecord record) {
        expect(
          session.applyWorkspacePurchases(
            accountScope: seed.accountScope,
            storeId: seed.storeId,
            feedRevision: record.revision,
            records: [record],
            complete: true,
          ),
          isTrue,
        );
      }

      final session = openStore();
      final productId = seed.products.first.id;
      final opening = seed.products.first.stock;
      Future<bool> post(
        WorkSession target,
        WorkspacePurchaseRecord record, {
        int factor = 2,
      }) => target.recordWorkspacePurchaseReceipt(
        record,
        stockProductIds: {'line-1': productId},
        unitsPerPack: {'line-1': factor},
      );
      final first = receipt(1, 4);
      publish(session, first);
      expect(await post(session, first), isTrue);
      expect(session.workspaceCatalogueItems.first.stock, opening + 8);
      expect(await post(session, first), isTrue);
      expect(session.workspaceStockMovements.length, 1);
      final second = receipt(2, 10, state: WorkspaceReceiptState.confirmed);
      publish(session, second);
      expect(await post(session, second, factor: 3), isFalse);
      expect(await post(session, second), isTrue);
      expect(session.workspaceCatalogueItems.first.stock, opening + 20);
      expect(session.workspaceStockMovements.length, 2);
      expect(
        WorkspaceLedgerCheckpoint(
          revision: 1,
          finance: session.workspaceFinance!,
        ).toJson(),
        WorkspaceLedgerCheckpoint(revision: 1, finance: seed.finance).toJson(),
      );
      final reopened = openStore();
      publish(reopened, second);
      expect(await post(reopened, second), isTrue);
      expect(reopened.workspaceCatalogueItems.first.stock, opening + 20);
      expect(reopened.workspaceStockMovements.length, 2);
      for (final movement in reopened.workspaceStockMovements) {
        expect(
          reopened.workspacePurchaseForStockMovement(movement),
          same(second),
        );
      }
      expect(
        WorkspaceLedgerCheckpoint(
          revision: 1,
          finance: reopened.workspaceFinance!,
        ).toJson(),
        WorkspaceLedgerCheckpoint(revision: 1, finance: seed.finance).toJson(),
      );
      WorkspaceSupplierReturnConfirmation returned(
        int count, {
        String account = 'account-A',
        int revision = 1,
      }) => WorkspaceSupplierReturnConfirmation(
        accountScope: account,
        workspaceId: seed.storeId,
        supplierId: second.supplierId,
        orderId: second.orderId,
        shipmentId: second.shipmentId,
        reference: 'return-$revision',
        revision: revision,
        confirmedAt: seed.now,
        returnedPacks: {'line-1': count},
      );
      Future<bool> returnStock(
        WorkspaceSupplierReturnConfirmation confirmation,
      ) => reopened.recordWorkspaceSupplierReturn(
        second,
        confirmation: confirmation,
        stockProductIds: {'line-1': productId},
        unitsPerPack: {'line-1': 2},
      );
      expect(await returnStock(returned(2)), isTrue);
      expect(reopened.workspaceCatalogueItems.first.stock, opening + 16);
      expect(await returnStock(returned(2)), isTrue);
      expect(reopened.workspaceStockMovements.length, 3);
      // Re-reading the original receipt must not put returned goods back.
      expect(await post(reopened, second), isTrue);
      expect(reopened.workspaceCatalogueItems.first.stock, opening + 16);
      expect(await returnStock(returned(11, revision: 2)), isFalse);
      expect(
        await returnStock(returned(3, account: 'other-account', revision: 2)),
        isFalse,
      );
      expect(
        WorkspaceLedgerCheckpoint(
          revision: 1,
          finance: reopened.workspaceFinance!,
        ).toJson(),
        WorkspaceLedgerCheckpoint(revision: 1, finance: seed.finance).toJson(),
      );
      final unconfirmed = receipt(3, 10, state: WorkspaceReceiptState.awaiting);
      publish(reopened, unconfirmed);
      expect(await post(reopened, unconfirmed), isFalse);
      expect(reopened.workspaceCatalogueItems.first.stock, opening + 16);
    },
  );

  test(
    'LEDGER02 review receiving adapter confirms counts without changing payment facts',
    () {
      final seed = StoreReviewSeed(
        accountScope: 'account-A',
        orderCount: 12,
        now: DateTime.utc(2026, 9, 14),
      );
      final purchase = seed.purchases.first;
      final line = purchase.lines.single;
      WorkspaceReceiptDraft draft(
        String count, {
        String account = 'account-A',
        Map<String, WorkspaceReceiptProblem> problems = const {},
      }) => WorkspaceReceiptDraft(
        key: (
          account: account,
          store: seed.storeId,
          shipment: purchase.shipmentId,
        ),
        supplierId: purchase.supplierId,
        orderId: purchase.orderId,
        shipmentRevision: purchase.revision,
        revision: 1,
        lines: purchase.lines,
        countedPacks: {line.id: count},
        problems: problems,
      );
      final adapter = StoreReviewReceiptGateway(seed);
      final partial = adapter.confirm(purchase, draft('4'))!;
      expect(partial.receiptState, WorkspaceReceiptState.partial);
      expect(partial.lines.single.receivedPacks, 4);
      expect(partial.stage, purchase.stage);
      expect(partial.amountMinor, purchase.amountMinor);
      expect(partial.paymentLabel, purchase.paymentLabel);
      expect(partial.orderId, purchase.orderId);
      expect(partial.shipmentId, purchase.shipmentId);
      expect(
        adapter.confirm(purchase, draft('20'))!.receiptState,
        WorkspaceReceiptState.confirmed,
      );
      expect(adapter.confirm(purchase, draft('21')), isNull);
      expect(adapter.confirm(purchase, draft('')), isNull);
      expect(
        adapter.confirm(purchase, draft('4', account: 'other-account')),
        isNull,
      );
      expect(
        adapter.confirm(
          purchase,
          draft('4', problems: {line.id: WorkspaceReceiptProblem.other}),
        ),
        isNull,
      );
    },
  );

  const receiptReviewEnabled =
      bool.fromEnvironment('MOOLSOCIAL_DEVICE_REVIEW') &&
      bool.fromEnvironment('MOOLSOCIAL_UI_REVIEW_ONLY');
  test(
    receiptReviewEnabled
        ? 'LEDGER02 connected test receipt survives retry and Store reopen'
        : 'LEDGER02 receipt confirmation stays disabled outside review builds',
    () async {
      final seed = StoreReviewSeed(
        accountScope: 'account-A',
        orderCount: 12,
        now: DateTime.utc(2026, 9, 14),
      );
      final native = _OrderJournalStorage();
      WorkSession openStore({bool refreshedClock = false}) {
        final purchaseSeed = refreshedClock
            ? StoreReviewSeed(
                accountScope: seed.accountScope,
                orderCount: 12,
                now: DateTime.now().toUtc().add(const Duration(minutes: 1)),
              )
            : seed;
        final session = WorkSession(
          gateway: ReviewWorkGateway(),
          pendingProofStore: _CommandAccountStore(),
          contactDraftStore: _CommandAccountStore(),
          receiptDraftStore: SecureWorkReceiptDraftStore(
            accountScope: () => seed.accountScope,
            storage: native,
          ),
        )..activeWorkspace = seed.workspace;
        addTearDown(session.dispose);
        session.workspaceCatalogueItems.addAll(seed.products);
        expect(session.applyWorkspaceFinance(seed.finance), isTrue);
        expect(
          session.applyWorkspacePurchases(
            accountScope: seed.accountScope,
            storeId: seed.storeId,
            feedRevision: 1,
            records: purchaseSeed.purchases,
            complete: true,
          ),
          isTrue,
        );
        expect(
          session.bindCustomerCollectionGateway(
            accountScope: seed.accountScope,
            storeId: seed.storeId,
            adapter: StoreReviewCustomerCollectionGateway(seed.finance),
            checkpointStore: SecureWorkLedgerCheckpointStore(
              accountScope: () => seed.accountScope,
              storage: native,
            ),
          ),
          isTrue,
        );
        expect(
          session.bindWorkspaceOrderOperations(
            WorkOrderOperations(
              accountScope: seed.accountScope,
              workspaceId: seed.storeId,
              gateway: StoreReviewOrderGateway(seed),
            ),
          ),
          isTrue,
        );
        return session;
      }

      final session = openStore();
      final purchase = session.workspacePurchases.first;
      expect(
        session.canConfirmStoreReviewReceipt(purchase),
        receiptReviewEnabled,
      );
      if (!receiptReviewEnabled) {
        expect(await session.confirmStoreReviewReceipt(purchase), isFalse);
        expect(session.workspaceStockMovements, isEmpty);
        return;
      }
      await session.loadWorkspaceReceiptDraft(purchase);
      await session.saveWorkspaceReceiptDraft(
        purchase,
        countedPacks: {purchase.lines.single.id: '4'},
        problems: const {},
        note: 'Four test packs counted',
      );
      native.failWrite = true;
      expect(await session.confirmStoreReviewReceipt(purchase), isFalse);
      expect(
        session.workspacePurchases.first.receiptState,
        purchase.receiptState,
      );
      expect(
        session.workspaceCatalogueItems.first.stock,
        seed.products.first.stock,
      );
      native.failWrite = false;
      native.loseWriteResponseOnce = true;
      expect(await session.confirmStoreReviewReceipt(purchase), isFalse);
      expect(
        session.workspacePurchases.first.receiptState,
        purchase.receiptState,
      );
      expect(await session.recoverCustomerLedger(), isTrue);
      expect(
        session.workspacePurchases.first.receiptState,
        WorkspaceReceiptState.partial,
      );
      expect(
        session.workspaceCatalogueItems.first.stock,
        seed.products.first.stock + 4,
      );
      expect(session.workspaceStockMovements.length, 1);
      expect(await session.confirmStoreReviewReceipt(purchase), isTrue);
      final updated = session.workspacePurchases.singleWhere(
        (item) => item.shipmentId == purchase.shipmentId,
      );
      expect(updated.receiptState, WorkspaceReceiptState.partial);
      expect(
        session.workspaceCatalogueItems.first.stock,
        seed.products.first.stock + 4,
      );
      expect(await session.confirmStoreReviewReceipt(updated), isTrue);
      expect(session.workspaceStockMovements.length, 1);
      final reopened = openStore();
      expect(await reopened.recoverCustomerLedger(), isTrue);
      final restoredPurchase = reopened.workspacePurchases.singleWhere(
        (item) => item.shipmentId == purchase.shipmentId,
      );
      expect(restoredPurchase.receiptState, WorkspaceReceiptState.partial);
      expect(restoredPurchase.receiptReference, updated.receiptReference);
      expect(restoredPurchase.lines.single.receivedPacks, 4);
      final refreshed = WorkspacePurchaseRecord(
        accountScope: purchase.accountScope,
        workspaceId: purchase.workspaceId,
        supplierId: purchase.supplierId,
        supplierName: purchase.supplierName,
        orderId: purchase.orderId,
        shipmentId: purchase.shipmentId,
        purchaseId: purchase.purchaseId,
        revision: updated.revision + 10,
        createdAt: purchase.createdAt,
        updatedAt: DateTime.now().toUtc(),
        stage: WorkspaceSupplyStage.arriving,
        amountMinor: purchase.amountMinor,
        itemSummary: purchase.itemSummary,
        paymentLabel: purchase.paymentLabel,
        lines: purchase.lines,
      );
      expect(
        reopened.applyWorkspacePurchases(
          accountScope: seed.accountScope,
          storeId: seed.storeId,
          feedRevision: 2,
          records: [refreshed],
        ),
        isTrue,
      );
      final refreshedPurchase = reopened.workspacePurchases.singleWhere(
        (item) => item.shipmentId == purchase.shipmentId,
      );
      expect(refreshedPurchase.receiptState, WorkspaceReceiptState.partial);
      expect(refreshedPurchase.lines.single.receivedPacks, 4);
      expect(refreshedPurchase.stage, WorkspaceSupplyStage.arriving);
      await reopened.loadWorkspaceReceiptDraft(restoredPurchase);
      expect(
        reopened
            .workspaceReceiptDraft(restoredPurchase)!
            .counted(purchase.lines.single.id),
        4,
      );
      expect(
        await reopened.confirmStoreReviewReceipt(restoredPurchase),
        isTrue,
      );
      expect(
        reopened.workspaceCatalogueItems.first.stock,
        seed.products.first.stock + 4,
      );
      expect(reopened.workspaceStockMovements.length, 1);
      final received = reopened.workspacePurchases.singleWhere(
        (item) => item.shipmentId == purchase.shipmentId,
      );
      await reopened.saveWorkspaceReceiptDraft(
        received,
        countedPacks: {purchase.lines.single.id: '4'},
        returnedPacks: {purchase.lines.single.id: '1'},
        problems: const {},
        note: 'One test pack returned',
      );
      final returnSaved = await reopened.confirmStoreReviewSupplierReturn(
        received,
      );
      expect(
        returnSaved,
        isTrue,
        reason: reopened.workspaceReceiptDraftMessage(received),
      );
      expect(await reopened.confirmStoreReviewSupplierReturn(received), isTrue);
      expect(
        reopened.workspaceCatalogueItems.first.stock,
        seed.products.first.stock + 3,
      );
      expect(reopened.workspaceStockMovements.length, 2);
      final afterReturn = openStore();
      expect(await afterReturn.recoverCustomerLedger(), isTrue);
      final returnPurchase = afterReturn.workspacePurchases.singleWhere(
        (item) => item.shipmentId == purchase.shipmentId,
      );
      expect(returnPurchase.receiptState, WorkspaceReceiptState.partial);
      expect(returnPurchase.lines.single.receivedPacks, 4);
      await afterReturn.loadWorkspaceReceiptDraft(returnPurchase);
      final retained = afterReturn.workspaceReceiptDraft(returnPurchase)!;
      expect(retained.counted(purchase.lines.single.id), 4);
      expect(retained.returnedPacks[purchase.lines.single.id], '1');
      expect(
        await afterReturn.confirmStoreReviewReceipt(returnPurchase),
        isTrue,
      );
      final latest = afterReturn.workspacePurchases.singleWhere(
        (item) => item.shipmentId == purchase.shipmentId,
      );
      expect(
        await afterReturn.confirmStoreReviewSupplierReturn(latest),
        isTrue,
      );
      expect(
        afterReturn.workspaceCatalogueItems.first.stock,
        seed.products.first.stock + 3,
      );
      expect(afterReturn.workspaceStockMovements.length, 2);
      final expenseKey = afterReturn.expenseFormKey()!;
      Future<bool> recordExpense({String reference = 'TEST-EXPENSE'}) =>
          afterReturn.recordStoreReviewExpense(
            key: expenseKey,
            amountMinor: 1900,
            category: 'Repair',
            method: 'Cash',
            reference: reference,
            note: 'Test repair expense',
          );
      expect(await recordExpense(), isTrue);
      expect(await recordExpense(), isTrue);
      expect(await recordExpense(reference: 'changed-reference'), isFalse);
      expect(afterReturn.workspaceExpenses.length, 1);
      expect(
        afterReturn.workspaceCatalogueItems.first.stock,
        seed.products.first.stock + 3,
      );
      final expenseRecovery = openStore();
      expect(await expenseRecovery.recoverCustomerLedger(), isTrue);
      expect(expenseRecovery.workspaceExpenses.single.amountMinor, 1900);
      expect(
        expenseRecovery.expenseFormKey()!.ledgerRevision,
        expenseKey.ledgerRevision + 1,
      );
      expect(
        WorkspaceLedgerCheckpoint(
          revision: 1,
          finance: reopened.workspaceFinance!,
        ).toJson(),
        WorkspaceLedgerCheckpoint(revision: 1, finance: seed.finance).toJson(),
      );
      // Reproduce a pre-fix checkpoint, keeping the original stock journal and
      // changing the editable counts so they cannot stand in for confirmation.
      final checkpointStore = SecureWorkLedgerCheckpointStore(
        accountScope: () => seed.accountScope,
        storage: native,
      );
      final savedReceiptCheckpoint = (await checkpointStore.read(
        seed.accountScope,
        seed.storeId,
      ))!;
      final droppedReceipt = savedReceiptCheckpoint.toJson()
        ..remove('purchaseReceipts')
        ..['revision'] = savedReceiptCheckpoint.revision + 1;
      await expectLater(
        checkpointStore.save(
          WorkspaceLedgerCheckpoint.fromJson(droppedReceipt)!,
          expectedRevision: savedReceiptCheckpoint.revision,
        ),
        throwsA(isA<WorkGatewayException>()),
      );
      expect(
        (await checkpointStore.read(seed.accountScope, seed.storeId))!.revision,
        savedReceiptCheckpoint.revision,
      );
      final invalidReceipt = savedReceiptCheckpoint.toJson();
      final receiptMap = invalidReceipt['purchaseReceipts'] as Map;
      (receiptMap.values.first as Map)['accountScope'] = 'another-account';
      expect(WorkspaceLedgerCheckpoint.fromJson(invalidReceipt), isNull);
      var legacyCheckpoints = 0;
      for (final entry in native.values.entries.toList()) {
        final value = jsonDecode(entry.value);
        if (value is Map<String, dynamic> &&
            value.containsKey('purchaseReceipts')) {
          value.remove('purchaseReceipts');
          native.values[entry.key] = jsonEncode(value);
          legacyCheckpoints++;
        }
      }
      expect(legacyCheckpoints, 1);
      await afterReturn.saveWorkspaceReceiptDraft(
        latest,
        countedPacks: {purchase.lines.single.id: '2'},
        returnedPacks: {purchase.lines.single.id: '1'},
        problems: const {},
        note: 'Unconfirmed edit',
      );
      final legacy = openStore();
      expect(await legacy.recoverCustomerLedger(), isTrue);
      final legacyPurchase = legacy.workspacePurchases.singleWhere(
        (item) => item.shipmentId == purchase.shipmentId,
      );
      expect(legacyPurchase.receiptState, WorkspaceReceiptState.partial);
      expect(legacyPurchase.lines.single.receivedPacks, 4);
      expect(
        legacy.workspaceCatalogueItems.first.stock,
        seed.products.first.stock + 3,
      );
      expect(legacy.workspaceStockMovements.length, 2);
      await legacy.loadWorkspaceReceiptDraft(legacyPurchase);
      expect(
        legacy
            .workspaceReceiptDraft(legacyPurchase)!
            .counted(purchase.lines.single.id),
        2,
      );
      final freshClock = openStore(refreshedClock: true);
      expect(await freshClock.recoverCustomerLedger(), isTrue);
      final directReturnPurchase = freshClock.workspacePurchases.singleWhere(
        (item) => item.shipmentId == purchase.shipmentId,
      );
      await freshClock.loadWorkspaceReceiptDraft(directReturnPurchase);
      await freshClock.saveWorkspaceReceiptDraft(
        directReturnPurchase,
        countedPacks: {purchase.lines.single.id: '4'},
        returnedPacks: {purchase.lines.single.id: '2'},
        problems: const {},
        note: 'Return directly after reopening',
      );
      expect(
        await freshClock.confirmStoreReviewSupplierReturn(directReturnPurchase),
        isTrue,
        reason: freshClock.workspaceReceiptDraftMessage(directReturnPurchase),
      );
      expect(
        freshClock.workspaceCatalogueItems.first.stock,
        seed.products.first.stock + 2,
      );
    },
  );

  test(
    'LEDGER02 supplier payment clears only its bill and retains method on replay',
    () {
      final seed = StoreReviewSeed(
        accountScope: 'account-A',
        orderCount: 12,
        now: DateTime.utc(2026, 9, 14),
      );
      final purchase = seed.purchases[1];
      final ledger = seed.supplierLedgers.singleWhere(
        (item) => item.supplierId == purchase.supplierId,
      );
      final amount = purchase.amountMinor * 3 ~/ 4;
      const adapter = StoreReviewSupplierPaymentGateway();
      WorkspaceSupplierLedger? record(
        WorkspaceSupplierLedger current, {
        int? paid,
        String reference = 'test-bank-reference',
        String method = 'Bank transfer',
        String operation = 'payment-remaining',
      }) => adapter.record(
        ledger: current,
        purchase: purchase,
        operationId: operation,
        reference: reference,
        paymentMethod: method,
        amountMinor: paid ?? amount,
        expectedRevision: ledger.revision,
      );
      expect(record(ledger, paid: amount + 1), isNull);
      final paid = record(ledger)!;
      expect(
        paid.entries
            .where((item) => item.orderId == purchase.orderId)
            .fold<int>(0, (sum, item) => sum + item.payableDeltaMinor),
        0,
      );
      expect(paid.entries.last.billId, 'QA-BILL-1');
      expect(paid.entries.last.paymentMethod, 'Bank transfer');
      expect(identical(record(paid), paid), isTrue);
      expect(record(paid, method: 'Cash'), isNull);
      expect(record(paid, reference: 'different-reference'), isNull);
      expect(record(paid, operation: 'second-payment'), isNull);
      final restored = WorkspaceSupplierLedger.fromJson(paid.toJson())!;
      expect(restored.entries.last.paymentMethod, 'Bank transfer');
      expect(restored.entries.last.reference, 'test-bank-reference');
      expect(record(restored)!.entries.length, paid.entries.length);
      expect(
        paid.entries
            .take(ledger.entries.length)
            .map((item) => item.toJson())
            .toList(),
        ledger.entries.map((item) => item.toJson()).toList(),
      );
    },
  );

  test(
    'LEDGER02 supplier payment draft retains input without posting or crossing bills',
    () async {
      final seed = StoreReviewSeed(
        accountScope: 'account-A',
        orderCount: 12,
        now: DateTime.utc(2026, 9, 14),
      );
      final native = _OrderJournalStorage();
      WorkSession openStore() {
        final session = WorkSession(
          pendingProofStore: _CommandAccountStore(),
          contactDraftStore: _CommandAccountStore(),
          ledgerFormDraftStore: SecureWorkLedgerFormDraftStore(
            accountScope: () => seed.accountScope,
            storage: native,
          ),
        )..activeWorkspace = seed.workspace;
        addTearDown(session.dispose);
        expect(
          session.applyWorkspacePurchases(
            accountScope: seed.accountScope,
            storeId: seed.storeId,
            feedRevision: 1,
            records: seed.purchases,
            complete: true,
          ),
          isTrue,
        );
        for (final ledger in seed.supplierLedgers) {
          expect(session.applyWorkspaceSupplierLedger(ledger), isTrue);
        }
        return session;
      }

      final session = openStore();
      final purchase = session.workspacePurchases.first;
      final key = session.supplierPaymentFormKey(purchase)!;
      final before = session
          .workspaceSupplierLedger(purchase.supplierId)!
          .toJson();
      await session.saveLedgerForm(
        WorkspaceLedgerFormDraft(
          key: key,
          revision: 1,
          fields: const {
            'amount': '12.',
            'channel': 'UPI',
            'reference': 'test reference',
          },
        ),
        expectedRevision: null,
      );
      final reopened = openStore();
      final retained = await reopened.readLedgerForm(key);
      expect(retained!.fields, {
        'amount': '12.',
        'channel': 'UPI',
        'reference': 'test reference',
      });
      expect(
        reopened.workspaceSupplierLedger(purchase.supplierId)!.toJson(),
        before,
      );
      expect(reopened.workspaceStockMovements, isEmpty);
      final wrongBill = (
        account: key.account,
        store: key.store,
        customer: key.customer,
        invoice: 'another-bill',
        order: key.order,
        kind: key.kind,
        ledgerRevision: key.ledgerRevision,
      );
      await expectLater(reopened.readLedgerForm(wrongBill), throwsStateError);
      final wrongOrder = (
        account: key.account,
        store: key.store,
        customer: key.customer,
        invoice: key.invoice,
        order: 'another-order',
        kind: key.kind,
        ledgerRevision: key.ledgerRevision,
      );
      await expectLater(reopened.readLedgerForm(wrongOrder), throwsStateError);
    },
  );

  test(
    'LEDGER03 expense save recovers once and survives later supplier updates',
    () async {
      final seed = StoreReviewSeed(
        accountScope: 'account-A',
        orderCount: 12,
        now: DateTime.utc(2026, 9, 14),
      );
      final native = _OrderJournalStorage();
      WorkSession openStore() {
        final session = WorkSession(
          pendingProofStore: _CommandAccountStore(),
          contactDraftStore: _CommandAccountStore(),
        )..activeWorkspace = seed.workspace;
        addTearDown(session.dispose);
        expect(session.applyWorkspaceFinance(seed.finance), isTrue);
        expect(
          session.bindCustomerCollectionGateway(
            accountScope: seed.accountScope,
            storeId: seed.storeId,
            adapter: StoreReviewCustomerCollectionGateway(seed.finance),
            checkpointStore: SecureWorkLedgerCheckpointStore(
              accountScope: () => seed.accountScope,
              storage: native,
            ),
          ),
          isTrue,
        );
        return session;
      }

      WorkspaceExpenseRecord expense({
        int amount = 1230,
        String account = 'account-A',
      }) => WorkspaceExpenseRecord(
        accountScope: account,
        workspaceId: seed.storeId,
        operationId: 'expense-1',
        amountMinor: amount,
        category: 'Transport',
        method: 'Cash',
        reference: 'TEST-RECEIPT-1',
        note: 'Test local transport',
        occurredAt: seed.now,
      );
      final first = openStore();
      native.loseWriteResponseOnce = true;
      expect(await first.saveWorkspaceExpenseRecord(expense()), isFalse);
      expect(first.workspaceExpenses, isEmpty);
      final reopened = openStore();
      expect(await reopened.recoverCustomerLedger(), isTrue);
      expect(reopened.workspaceExpenses.single.amountMinor, 1230);
      expect(await reopened.saveWorkspaceExpenseRecord(expense()), isTrue);
      expect(
        await reopened.saveWorkspaceExpenseRecord(expense(amount: 1250)),
        isFalse,
      );
      expect(
        await reopened.saveWorkspaceExpenseRecord(
          expense(account: 'other-account'),
        ),
        isFalse,
      );
      final register = WorkspaceMoneyRegisterSnapshot(
        accountScope: seed.accountScope,
        workspaceId: seed.storeId,
        registerId: 'test-cash',
        label: 'Test cash register',
        revision: 1,
        openingAt: seed.now,
        asOf: seed.now.add(const Duration(minutes: 1)),
        historyComplete: true,
        openingMinor: 10000,
        entries: [
          WorkspaceMoneyRegisterEntry(
            id: 'expense-1',
            reference: 'TEST-RECEIPT-1',
            occurredAt: seed.now,
            deltaMinor: -1230,
          ),
        ],
      );
      native.loseWriteResponseOnce = true;
      expect(await reopened.saveWorkspaceMoneyRegister(register), isFalse);
      expect(reopened.workspaceMoneyRegisters, isEmpty);
      expect(await reopened.recoverCustomerLedger(), isTrue);
      expect(
        reopened.workspaceMoneyRegisters.single.toJson(),
        register.toJson(),
      );
      expect(await reopened.saveWorkspaceMoneyRegister(register), isTrue);
      expect(
        await reopened.saveWorkspaceSupplierLedger(seed.supplierLedgers.first),
        isTrue,
      );
      final again = openStore();
      expect(await again.recoverCustomerLedger(), isTrue);
      expect(again.workspaceExpenses.single.toJson(), expense().toJson());
      expect(again.workspaceMoneyRegisters.single.toJson(), register.toJson());
      expect(
        again.workspaceMoneyRegisters.single
            .balances(seed.now, register.asOf)!
            .closingMinor,
        8770,
      );
      expect(again.workspaceStockMovements, isEmpty);
      expect(
        WorkspaceLedgerCheckpoint(
          revision: 1,
          finance: again.workspaceFinance!,
        ).toJson(),
        WorkspaceLedgerCheckpoint(revision: 1, finance: seed.finance).toJson(),
      );
      final journal = SecureWorkLedgerCheckpointStore(
        accountScope: () => seed.accountScope,
        storage: native,
      );
      final saved = (await journal.read(seed.accountScope, seed.storeId))!;
      await expectLater(
        journal.save(
          WorkspaceLedgerCheckpoint(
            revision: saved.revision + 1,
            finance: saved.finance,
            supplierLedgers: saved.supplierLedgers,
            moneyRegisters: saved.moneyRegisters,
          ),
          expectedRevision: saved.revision,
        ),
        throwsA(isA<WorkGatewayException>()),
      );
      expect(
        (await journal.read(seed.accountScope, seed.storeId))!.expenses.length,
        1,
      );
      await expectLater(
        journal.save(
          WorkspaceLedgerCheckpoint(
            revision: saved.revision + 1,
            finance: saved.finance,
            supplierLedgers: saved.supplierLedgers,
            expenses: saved.expenses,
          ),
          expectedRevision: saved.revision,
        ),
        throwsA(isA<WorkGatewayException>()),
      );
      expect(
        (await journal.read(
          seed.accountScope,
          seed.storeId,
        ))!.moneyRegisters.length,
        1,
      );
    },
  );

  group('LEDGER02 supplier balances', () {
    final at = DateTime.utc(2026, 9, 14);
    WorkspaceSupplierLedgerEntry entry(
      String id,
      WorkspaceSupplierEntryKind kind,
      int amount, {
      String? bill,
    }) => WorkspaceSupplierLedgerEntry(
      operationId: id,
      orderId: 'purchase-1',
      reference: id,
      kind: kind,
      amountMinor: amount,
      postedAt: at,
      billId: bill,
    );
    WorkspaceSupplierLedger ledger(
      List<WorkspaceSupplierLedgerEntry> entries, {
      int revision = 1,
      bool complete = true,
      int? opening = 0,
      String account = 'account-1',
      String store = 'store-1',
      String supplier = 'supplier-1',
    }) => WorkspaceSupplierLedger(
      accountScope: account,
      workspaceId: store,
      supplierId: supplier,
      supplierName: 'Grocery supplier',
      revision: revision,
      asOf: at,
      entries: entries,
      historyComplete: complete,
      openingBalanceMinor: opening,
    );

    test(
      'representable money rejects oversized entries openings and running balances',
      () {
        const max = 9007199254740991;
        expect(
          entry('too-large', WorkspaceSupplierEntryKind.payment, max + 1).valid,
          isFalse,
        );
        expect(ledger([], opening: max + 1).valid, isFalse);
        expect(ledger([], opening: -max - 1).valid, isFalse);
        expect(
          ledger([
            entry('bill', WorkspaceSupplierEntryKind.bill, 1, bill: 'invoice'),
          ], opening: max).valid,
          isFalse,
        );
        expect(
          ledger([
            entry('payment', WorkspaceSupplierEntryKind.payment, 1),
          ], opening: -max).valid,
          isFalse,
        );
        expect(
          ledger([
            entry('bill', WorkspaceSupplierEntryKind.bill, 1, bill: 'invoice'),
          ], opening: max - 1).balanceMinor,
          max,
        );
      },
    );

    test('confirmed payment retry cannot duplicate or overwrite a posting', () {
      final original = ledger([
        entry(
          'bill-1',
          WorkspaceSupplierEntryKind.bill,
          200000,
          bill: 'invoice-1',
        ),
      ]);
      final payment = entry(
        'payment-1',
        WorkspaceSupplierEntryKind.payment,
        50000,
      );
      final posted = original.appendConfirmed(payment, expectedRevision: 1)!;
      expect(posted.payableMinor, 150000);
      expect(posted.revision, 2);
      expect(
        identical(posted.appendConfirmed(payment, expectedRevision: 1), posted),
        isTrue,
      );
      expect(posted.entries.length, 2);
      expect(
        posted.appendConfirmed(
          entry('payment-1', WorkspaceSupplierEntryKind.payment, 60000),
          expectedRevision: 1,
        ),
        isNull,
      );
      final secondPayment = entry(
        'payment-2',
        WorkspaceSupplierEntryKind.payment,
        25000,
      );
      expect(
        posted.appendConfirmed(secondPayment, expectedRevision: 1),
        isNull,
      );
      expect(
        posted.appendConfirmed(secondPayment, expectedRevision: 3),
        isNull,
      );
      final next = posted.appendConfirmed(secondPayment, expectedRevision: 2)!;
      expect(next.payableMinor, 125000);
      expect(next.entries.length, 3);
      expect(
        identical(next.appendConfirmed(payment, expectedRevision: 1), next),
        isTrue,
      );
    });

    test('bill 2000 less advance 500 leaves 1500 without shipment effects', () {
      final advance = entry(
        'advance-1',
        WorkspaceSupplierEntryKind.advance,
        50000,
      );
      final beforeBill = ledger([advance]);
      expect(beforeBill.payableMinor, 0);
      expect(beforeBill.creditMinor, 50000);
      final billed = ledger([
        advance,
        entry(
          'bill-1',
          WorkspaceSupplierEntryKind.bill,
          200000,
          bill: 'invoice-1',
        ),
      ], revision: 2);
      expect(billed.canFollow(beforeBill), isTrue);
      expect(billed.payableMinor, 150000);
      expect(billed.creditMinor, 0);
      final paid = ledger([
        ...billed.entries,
        entry('payment-1', WorkspaceSupplierEntryKind.payment, 150000),
      ], revision: 3);
      expect(paid.canFollow(billed), isTrue);
      expect(paid.balanceMinor, 0);
      expect(() => paid.entries.clear(), throwsUnsupportedError);
    });

    test(
      'supplier credit and refund are separate, missing history is unknown',
      () {
        final entries = [
          entry(
            'bill-1',
            WorkspaceSupplierEntryKind.bill,
            200000,
            bill: 'invoice-1',
          ),
          entry('payment-1', WorkspaceSupplierEntryKind.payment, 200000),
          entry(
            'credit-1',
            WorkspaceSupplierEntryKind.creditNote,
            20000,
            bill: 'invoice-1',
          ),
        ];
        expect(ledger(entries).creditMinor, 20000);
        expect(
          ledger([
            ...entries,
            entry('refund-1', WorkspaceSupplierEntryKind.refund, 5000),
          ]).creditMinor,
          15000,
        );
        expect(ledger(entries, complete: false).balanceMinor, isNull);
        expect(ledger(entries, opening: null).payableMinor, isNull);
      },
    );

    test(
      'duplicates, rewriting and account Store supplier switches are rejected',
      () {
        final bill = entry(
          'bill-1',
          WorkspaceSupplierEntryKind.bill,
          200000,
          bill: 'invoice-1',
        );
        final previous = ledger([bill]);
        expect(ledger([bill, bill]).valid, isFalse);
        expect(
          ledger([
            bill,
            entry(
              'bill-retry',
              WorkspaceSupplierEntryKind.bill,
              200000,
              bill: 'invoice-1',
            ),
          ]).valid,
          isFalse,
        );
        expect(
          ledger([
            entry(
              'bill-1',
              WorkspaceSupplierEntryKind.bill,
              100000,
              bill: 'invoice-1',
            ),
          ], revision: 2).canFollow(previous),
          isFalse,
        );
        expect(ledger([], revision: 2).canFollow(previous), isFalse);
        expect(
          ledger([bill], revision: 2, account: 'other').canFollow(previous),
          isFalse,
        );
        expect(
          ledger([bill], revision: 2, store: 'other').canFollow(previous),
          isFalse,
        );
        expect(
          ledger([bill], revision: 2, supplier: 'other').canFollow(previous),
          isFalse,
        );
      },
    );
  });
  test(
    'LEDGER01 stock journal admits new SKUs without rebasing existing stock',
    () {
      final at = DateTime.utc(2026, 9, 14);
      final original = WorkspaceInventoryLedger(
        accountScope: 'account-A',
        workspaceId: 'store-A',
        revision: 1,
        asOf: at,
        openingQuantities: const {'original': 8},
        movements: const [],
      );
      final opening = WorkspaceStockMovement(
        id: 'OPEN-NEW',
        productId: 'new',
        productLabel: 'New grocery pack',
        kind: WorkspaceStockMovementKind.openingStock,
        quantityDelta: 5,
        reason: 'Initial counted stock',
        occurredAt: at,
      );
      expect(original.post([opening], at: at), isNull);
      final added = original.post(
        [opening],
        at: at,
        newProductIds: {'new', 'empty'},
      )!;
      expect(added.quantities, {'original': 8, 'new': 5, 'empty': 0});
      expect(added.openingQuantities, {'original': 8, 'new': 0, 'empty': 0});
      expect(added.canFollow(original), isTrue);
      expect(
        identical(added.post([opening], at: at, newProductIds: {'new'}), added),
        isTrue,
      );
      final rebased = WorkspaceInventoryLedger(
        accountScope: 'account-A',
        workspaceId: 'store-A',
        revision: 2,
        asOf: at,
        openingQuantities: const {'original': 9, 'new': 0},
        movements: [opening],
      );
      expect(rebased.canFollow(original), isFalse);
      final invented = WorkspaceInventoryLedger(
        accountScope: 'account-A',
        workspaceId: 'store-A',
        revision: 2,
        asOf: at,
        openingQuantities: const {'original': 8, 'new': 5},
        movements: const [],
      );
      expect(invented.canFollow(original), isFalse);
      expect(
        WorkspaceInventoryLedger.fromJson(added.toJson()).quantities,
        added.quantities,
      );
    },
  );
  test(
    'LEDGER01 unsent invoice form survives reopening and isolates bill revisions',
    () async {
      var account = 'account-A';
      final storage = _OrderJournalStorage();
      SecureWorkLedgerFormDraftStore open() => SecureWorkLedgerFormDraftStore(
        accountScope: () => account,
        storage: storage,
      );
      WorkspaceLedgerFormKey key({
        String store = 'store-A',
        String kind = 'refund',
        int ledgerRevision = 7,
      }) => (
        account: 'account-A',
        store: store,
        customer: 'customer-A',
        invoice: 'invoice-A',
        order: 'order-A',
        kind: kind,
        ledgerRevision: ledgerRevision,
      );
      final draft = WorkspaceLedgerFormDraft(
        key: key(),
        revision: 1,
        fields: const {
          'amount': '120.50',
          'channel': 'directUpi',
          'reference': 'TEST-REF',
        },
      );
      await open().save(draft, expectedRevision: null);
      expect((await open().read(key()))!.fields, draft.fields);
      expect(await open().read(key(store: 'store-B')), isNull);
      expect(await open().read(key(kind: 'collection')), isNull);
      expect(await open().read(key(ledgerRevision: 8)), isNull);
      account = 'account-B';
      await expectLater(
        open().read(key()),
        throwsA(isA<WorkGatewayException>()),
      );
      account = 'account-A';
      await expectLater(
        open().save(
          WorkspaceLedgerFormDraft(
            key: key(),
            revision: 1,
            fields: const {'amount': '1'},
          ),
          expectedRevision: null,
        ),
        throwsA(isA<WorkGatewayException>()),
      );
      expect((await open().read(key()))!.fields, draft.fields);
      storage.loseWriteResponseOnce = true;
      final updated = WorkspaceLedgerFormDraft(
        key: key(),
        revision: 2,
        fields: const {'amount': '90.25', 'channel': 'cash'},
      );
      await expectLater(
        open().save(updated, expectedRevision: 1),
        throwsStateError,
      );
      await open().save(updated, expectedRevision: 1);
      expect((await open().read(key()))!.fields, updated.fields);
      final retired = WorkspaceLedgerFormDraft(
        key: key(),
        revision: 3,
        fields: const {},
      );
      await open().save(retired, expectedRevision: 2);
      expect((await open().read(key()))!.fields, isEmpty);
      await expectLater(
        open().save(updated, expectedRevision: 1),
        throwsA(isA<WorkGatewayException>()),
      );
      final storedKey = storage.values.keys.single;
      storage.values[storedKey] = '{broken';
      await expectLater(
        open().read(key()),
        throwsA(isA<WorkGatewayException>()),
      );
      await expectLater(
        open().save(draft, expectedRevision: null),
        throwsA(isA<WorkGatewayException>()),
      );
      expect(storage.values[storedKey], '{broken');
      expect(
        WorkspaceLedgerFormDraft(
          key: key(),
          revision: 1,
          fields: const {'paid': 'true'},
        ).valid,
        isFalse,
      );
    },
  );
  test(
    'LEDGER01 stock quantities recover and acknowledge each return once',
    () async {
      final at = DateTime.utc(2026, 9, 14);
      final seed = StoreReviewSeed(
        accountScope: 'account-A',
        orderCount: 12,
        now: at,
      );
      final initial = WorkspaceInventoryLedger(
        accountScope: 'account-A',
        workspaceId: seed.storeId,
        revision: 1,
        asOf: at,
        openingQuantities: const {'sku-A': 8},
        movements: const [],
      );
      WorkspaceStockMovement movement(String id, int quantity) =>
          WorkspaceStockMovement(
            id: id,
            productId: 'sku-A',
            productLabel: 'Original pack',
            kind: quantity > 0
                ? WorkspaceStockMovementKind.returned
                : WorkspaceStockMovementKind.sale,
            quantityDelta: quantity,
            reason: 'Invoice A',
            occurredAt: at,
            referenceKind: WorkspaceStockReferenceKind.order,
            referenceId: 'ORDER-A',
          );
      final sale = initial.post([movement('SALE-A', -2)], at: at)!;
      final returned = sale.post([movement('RETURN-A', 1)], at: at)!;
      expect(returned.quantities, {'sku-A': 7});
      expect(
        identical(returned.post([movement('RETURN-A', 1)], at: at), returned),
        isTrue,
      );
      expect(returned.post([movement('RETURN-A', 2)], at: at), isNull);
      expect(returned.post([movement('EXCESS-SALE', -8)], at: at), isNull);
      final bytes = _OrderJournalStorage();
      SecureWorkLedgerCheckpointStore open() => SecureWorkLedgerCheckpointStore(
        accountScope: () => 'account-A',
        storage: bytes,
      );
      await open().save(
        WorkspaceLedgerCheckpoint(
          revision: 1,
          finance: seed.finance,
          inventory: sale,
        ),
        expectedRevision: null,
      );
      await open().save(
        WorkspaceLedgerCheckpoint(
          revision: 2,
          finance: seed.finance,
          inventory: returned,
        ),
        expectedRevision: 1,
      );
      final recovered = (await open().read('account-A', seed.storeId))!;
      expect(recovered.inventory!.quantities, {'sku-A': 7});
      expect(
        recovered.inventory!.post([
          movement('RETURN-A', 1),
        ], at: at)!.quantities,
        {'sku-A': 7},
      );
      await expectLater(
        open().save(
          WorkspaceLedgerCheckpoint(revision: 3, finance: seed.finance),
          expectedRevision: 2,
        ),
        throwsA(isA<WorkGatewayException>()),
      );
      final changedOpening = WorkspaceInventoryLedger(
        accountScope: 'account-A',
        workspaceId: seed.storeId,
        revision: 4,
        asOf: at,
        openingQuantities: const {'sku-A': 9},
        movements: returned.movements,
      );
      expect(changedOpening.canFollow(returned), isFalse);
      expect(
        (await open().read('account-A', seed.storeId))!.inventory!.quantities,
        {'sku-A': 7},
      );
    },
  );

  group('LEDGER01 customer return allocation', () {
    WorkspaceCustomerReturn request(
      String operation,
      int quantity, {
      int? restock,
      String account = 'account-A',
      String sku = 'sku-A',
    }) => WorkspaceCustomerReturn(
      accountScope: account,
      workspaceId: 'store-A',
      customerId: 'customer-A',
      invoiceId: 'invoice-A',
      orderId: 'order-A',
      operationId: operation,
      expectedRevision: 1,
      reason: 'Customer return',
      lines: [
        WorkspaceCustomerReturnLine(
          productId: sku,
          quantity: quantity,
          restockQuantity: restock ?? quantity,
        ),
      ],
    );
    final order = WorkspaceOrderRecord(
      id: 'order-A',
      customer: 'Customer A',
      items: '3 packs',
      quantities: const {'sku-A': 3},
      amount: 10,
      source: 'Counter',
      fulfilment: 'At the shop',
      payment: 'Customer due',
      address: '',
      stage: 'Completed',
      needsDelivery: false,
      createdAt: DateTime.utc(2026, 9, 14),
      itemSnapshots: const [
        WorkspaceOrderItemSnapshot(
          productId: 'sku-A',
          name: 'Original grocery',
          pack: '1 pack',
          quantity: 3,
          unitPricePaise: 400,
          lineTotalPaise: 1000,
        ),
      ],
    );
    test('LEDGER01 original bill snapshot round trips without repricing', () {
      final recovered = WorkspaceOrderRecord.fromLedgerJson(
        order.toLedgerJson(),
      )!;
      expect(recovered.toLedgerJson(), order.toLedgerJson());
      expect(recovered.itemSnapshots.single.unitPricePaise, 400);
      expect(recovered.itemSnapshots.single.lineTotalPaise, 1000);
      expect(() => recovered.quantities.clear(), throwsUnsupportedError);
      expect(() => recovered.itemSnapshots.clear(), throwsUnsupportedError);
      expect(
        WorkspaceOrderRecord.fromLedgerJson(
          order.toLedgerJson()..['amount'] = 11,
        ),
        isNull,
      );
      expect(
        WorkspaceOrderRecord.fromLedgerJson(
          order.toLedgerJson()..['stage'] = 'Preparing',
        ),
        isNull,
      );
      expect(
        WorkspaceOrderRecord.fromLedgerJson(
          order.toLedgerJson()..['itemSnapshots'] = [],
        ),
        isNull,
      );
    });
    for (final paid in [0, 600, 1000]) {
      test('LEDGER01 return posts once with collected=$paid', () async {
        final seed = StoreReviewSeed(
          accountScope: 'account-A',
          orderCount: 12,
          now: DateTime.utc(2026, 9, 14),
        );
        final adapter = StoreReviewCustomerCollectionGateway(seed.finance);
        final invoice = WorkspaceCustomerInvoice(
          id: 'invoice-A',
          orderId: 'order-A',
          customer: '9000000088',
          items: '3 packs',
          amount: 10,
          payment: 'Customer due',
          issuedAt: DateTime.utc(2026, 9, 14),
        );
        var finance = await adapter.recordInvoice(
          accountScope: 'account-A',
          storeId: seed.storeId,
          invoice: invoice,
        );
        if (paid > 0) {
          finance = await adapter.recordCollection(
            WorkspaceCustomerCollection(
              accountScope: 'account-A',
              workspaceId: seed.storeId,
              customerId: invoice.customer,
              invoiceId: invoice.id,
              orderId: invoice.orderId,
              operationId: 'COLLECT-A',
              expectedRevision: 1,
              amountMinor: paid,
              channel: WorkspacePaymentChannel.cash,
            ),
          );
        }
        final before = finance;
        final returned = WorkspaceCustomerReturn(
          accountScope: 'account-A',
          workspaceId: seed.storeId,
          customerId: invoice.customer,
          invoiceId: invoice.id,
          orderId: invoice.orderId,
          operationId: 'RETURN-A',
          expectedRevision: paid > 0 ? 2 : 1,
          reason: 'Two packs returned',
          lines: const [
            WorkspaceCustomerReturnLine(
              productId: 'sku-A',
              quantity: 2,
              restockQuantity: 1,
            ),
          ],
        );
        final native = _OrderJournalStorage();
        SecureWorkLedgerCheckpointStore openJournal() =>
            SecureWorkLedgerCheckpointStore(
              accountScope: () => 'account-A',
              storage: native,
            );
        final intent = WorkspacePendingCustomerReturn(
          request: returned,
          creditMinor: 666,
          originalItems: order.itemSnapshots,
        );
        final pendingInventory = WorkspaceInventoryLedger(
          accountScope: 'account-A',
          workspaceId: seed.storeId,
          revision: 1,
          asOf: before.asOf,
          openingQuantities: const {'sku-A': 8},
          movements: const [],
        );
        final pendingCheckpoint = WorkspaceLedgerCheckpoint(
          revision: 1,
          finance: before,
          pendingReturn: intent,
          inventory: pendingInventory,
        );
        expect(pendingCheckpoint.valid, isTrue);
        await openJournal().save(pendingCheckpoint, expectedRevision: null);
        final recoveredPending = (await openJournal().read(
          'account-A',
          seed.storeId,
        ))!;
        expect(recoveredPending.pendingReturn!.toJson(), intent.toJson());
        await expectLater(
          openJournal().save(
            WorkspaceLedgerCheckpoint(revision: 2, finance: before),
            expectedRevision: 1,
          ),
          throwsA(isA<WorkGatewayException>()),
        );
        final changedIntent = WorkspacePendingCustomerReturn(
          request: WorkspaceCustomerReturn.fromJson({
            ...returned.toJson(),
            'operationId': 'REPLACEMENT',
          }),
          creditMinor: 666,
        );
        await expectLater(
          openJournal().save(
            WorkspaceLedgerCheckpoint(
              revision: 2,
              finance: before,
              pendingReturn: changedIntent,
            ),
            expectedRevision: 1,
          ),
          throwsA(isA<WorkGatewayException>()),
        );
        expect(
          (await openJournal().read(
            'account-A',
            seed.storeId,
          ))!.pendingReturn!.toJson(),
          intent.toJson(),
        );
        final result = await adapter.recordReturn(
          returned,
          order.copyWith(customer: invoice.customer),
        );
        final creditEntry = result.customerLedgers
            .singleWhere((item) => item.customerId == invoice.customer)
            .entries
            .last;
        await expectLater(
          openJournal().save(
            WorkspaceLedgerCheckpoint(
              revision: 2,
              finance: result,
              inventory: pendingInventory,
            ),
            expectedRevision: 1,
          ),
          throwsA(
            isA<WorkGatewayException>().having(
              (error) => error.message,
              'reason',
              'Return stock movements must be saved with the credit.',
            ),
          ),
        );
        final completedInventory = pendingInventory.post(
          creditEntry.returnStockMovements(order)!,
          at: result.asOf,
        )!;
        await openJournal().save(
          WorkspaceLedgerCheckpoint(
            revision: 2,
            finance: result,
            inventory: completedInventory,
          ),
          expectedRevision: 1,
        );
        final recoveredResult = (await openJournal().read(
          'account-A',
          seed.storeId,
        ))!;
        expect(recoveredResult.pendingReturn, isNull);
        expect(
          recoveredResult.finance.customerLedgers
              .singleWhere((l) => l.customerId == invoice.customer)
              .entries
              .last
              .customerReturn!
              .toJson(),
          returned.toJson(),
        );
        final payment = result.payments.singleWhere(
          (p) => p.invoiceId == invoice.id,
        );
        final expectedDue = paid == 0 ? 334 : 0;
        expect(payment.dueMinor, expectedDue);
        expect(payment.paidMinor, paid);
        expect(payment.refundedMinor, 0);
        expect(
          payment.state,
          paid == 0
              ? WorkspacePaymentState.unpaid
              : WorkspacePaymentState.refundPending,
        );
        expect(
          result.duesMinor,
          before.duesMinor - (1000 - paid) + expectedDue,
        );
        expect(result.salesTodayMinor, before.salesTodayMinor);
        expect(result.availableMinor, before.availableMinor);
        expect(result.refundsMinor, before.refundsMinor);
        final ledger = result.customerLedgers.singleWhere(
          (l) => l.customerId == invoice.customer,
        );
        expect(ledger.entries.last.amountMinor, 666);
        final movements = ledger.entries.last.returnStockMovements(
          order.copyWith(customer: invoice.customer),
        )!;
        expect(movements, hasLength(1));
        expect(movements.single.quantityDelta, 1);
        expect(movements.single.referenceId, invoice.orderId);
        expect(
          movements.single.referenceKind,
          WorkspaceStockReferenceKind.order,
        );
        expect(movements.single.valid, isTrue);
        expect(movements.single.productLabel, 'Original grocery · 1 pack');
        final recoveredEntry = recoveredResult.finance.customerLedgers
            .singleWhere((l) => l.customerId == invoice.customer)
            .entries
            .last;
        expect(
          recoveredEntry.returnStockMovements(order)!.single.contentIdentity,
          movements.single.contentIdentity,
        );
        expect(() => movements.clear(), throwsUnsupportedError);
        expect(
          ledger.entries.last.returnStockMovements(
            order.copyWith(itemSnapshots: []),
          ),
          isNull,
        );

        expect(
          ledger.entries.last.customerReturn!.lines.single.restockQuantity,
          1,
        );
        expect(
          ledger.invoiceBalance(invoice.id)!.refundableMinor,
          paid == 0 ? 0 : paid - 334,
        );
        expect(
          identical(
            await adapter.recordReturn(
              returned,
              order.copyWith(customer: invoice.customer),
            ),
            result,
          ),
          isTrue,
        );
        expect(
          identical(await adapter.reconcileReturn(returned), result),
          isTrue,
        );
        final altered = WorkspaceCustomerReturn.fromJson({
          ...returned.toJson(),
          'reason': 'Changed accepted return',
        });
        await expectLater(
          adapter.recordReturn(altered, order),
          throwsStateError,
        );
        final newAdapter = StoreReviewCustomerCollectionGateway(seed.finance);
        expect(newAdapter.restoreCheckpoint(result, seed.finance), isTrue);
        expect(
          identical(await newAdapter.reconcileReturn(returned), result),
          isTrue,
        );
        if (paid == 0) {
          final settled = await adapter.recordCollection(
            WorkspaceCustomerCollection(
              accountScope: 'account-A',
              workspaceId: seed.storeId,
              customerId: invoice.customer,
              invoiceId: invoice.id,
              orderId: invoice.orderId,
              operationId: 'COLLECT-REMAINING',
              expectedRevision: ledger.revision,
              amountMinor: 334,
              channel: WorkspacePaymentChannel.cash,
            ),
          );
          final paidBill = settled.payments.singleWhere(
            (p) => p.invoiceId == invoice.id,
          );
          expect(paidBill.dueMinor, 0);
          expect(paidBill.paidMinor, 334);
          expect(paidBill.state, WorkspacePaymentState.returnAdjusted);
          expect(settled.availableMinor, before.availableMinor);
        }
        if (paid > 0) {
          final refundable = ledger.invoiceBalance(invoice.id)!.refundableMinor;
          WorkspaceCustomerRefund refund(String id, int amount, int revision) =>
              WorkspaceCustomerRefund(
                accountScope: 'account-A',
                workspaceId: seed.storeId,
                customerId: invoice.customer,
                invoiceId: invoice.id,
                orderId: invoice.orderId,
                operationId: id,
                expectedRevision: revision,
                amountMinor: amount,
                channel: WorkspacePaymentChannel.cash,
              );
          await expectLater(
            adapter.recordRefund(
              refund('EXCESS', refundable + 1, ledger.revision),
            ),
            throwsStateError,
          );
          final firstRefund = refund('REFUND-1', 100, ledger.revision);
          await openJournal().save(
            WorkspaceLedgerCheckpoint(
              revision: 3,
              finance: result,
              inventory: completedInventory,
              pendingRefund: firstRefund,
            ),
            expectedRevision: 2,
          );
          expect(
            (await openJournal().read(
              'account-A',
              seed.storeId,
            ))!.pendingRefund!.identityData,
            firstRefund.identityData,
          );
          await expectLater(
            openJournal().save(
              WorkspaceLedgerCheckpoint(
                revision: 4,
                finance: result,
                inventory: completedInventory,
              ),
              expectedRevision: 3,
            ),
            throwsA(isA<WorkGatewayException>()),
          );
          await expectLater(
            openJournal().save(
              WorkspaceLedgerCheckpoint(
                revision: 4,
                finance: result,
                inventory: completedInventory,
                pendingRefund: refund('REPLACEMENT', 100, ledger.revision),
              ),
              expectedRevision: 3,
            ),
            throwsA(isA<WorkGatewayException>()),
          );

          final first = await adapter.recordRefund(firstRefund);
          final wrongAmount = await StoreReviewCustomerCollectionGateway(
            result,
          ).recordRefund(refund('REFUND-1', 101, ledger.revision));
          final changedInventory = completedInventory.post([
            WorkspaceStockMovement(
              id: 'UNRELATED-REFUND-STOCK',
              productId: movements.single.productId,
              productLabel: movements.single.productLabel,
              kind: WorkspaceStockMovementKind.returned,
              quantityDelta: 1,
              reason: 'Refund must not return stock again',
              occurredAt: first.asOf,
            ),
          ], at: first.asOf)!;
          for (final invalid in [
            WorkspaceLedgerCheckpoint(
              revision: 4,
              finance: wrongAmount,
              inventory: completedInventory,
            ),
            WorkspaceLedgerCheckpoint(
              revision: 4,
              finance: first,
              inventory: changedInventory,
            ),
          ]) {
            expect(invalid.valid, isTrue);
            await expectLater(
              openJournal().save(invalid, expectedRevision: 3),
              throwsA(
                isA<WorkGatewayException>().having(
                  (error) => error.message,
                  'reason',
                  'Confirmed refund must match its invoice without changing stock.',
                ),
              ),
            );
            final retained = (await openJournal().read(
              'account-A',
              seed.storeId,
            ))!;
            expect(retained.revision, 3);
            expect(
              retained.pendingRefund!.identityData,
              firstRefund.identityData,
            );
            expect(
              retained.inventory!.quantities,
              completedInventory.quantities,
            );
            expect(
              retained.finance.payments
                  .singleWhere((payment) => payment.invoiceId == invoice.id)
                  .refundedMinor,
              0,
            );
          }
          await openJournal().save(
            WorkspaceLedgerCheckpoint(
              revision: 4,
              finance: first,
              inventory: completedInventory,
            ),
            expectedRevision: 3,
          );
          final recoveredRefund = (await openJournal().read(
            'account-A',
            seed.storeId,
          ))!;
          expect(recoveredRefund.pendingRefund, isNull);
          expect(
            recoveredRefund.inventory!.quantities,
            completedInventory.quantities,
          );

          final firstPayment = first.payments.singleWhere(
            (p) => p.invoiceId == invoice.id,
          );
          expect(firstPayment.refundedMinor, 100);
          expect(firstPayment.paidMinor, paid);
          expect(firstPayment.dueMinor, 0);
          expect(firstPayment.state, WorkspacePaymentState.refundPending);
          expect(first.availableMinor, before.availableMinor);
          expect(first.refundsMinor, before.refundsMinor + 100);
          expect(
            identical(await adapter.recordRefund(firstRefund), first),
            isTrue,
          );
          final finalRefund = refund(
            'REFUND-2',
            refundable - 100,
            ledger.revision + 1,
          );
          final completed = await adapter.recordRefund(finalRefund);
          final completedLedger = completed.customerLedgers.singleWhere(
            (l) => l.customerId == invoice.customer,
          );
          expect(
            completedLedger.invoiceBalance(invoice.id)!.refundableMinor,
            0,
          );
          expect(
            completedLedger.entries.where(
              (e) => e.kind == WorkspaceLedgerEntryKind.refund,
            ),
            hasLength(2),
          );
          expect(
            completedLedger.entries.where(
              (e) => e.kind == WorkspaceLedgerEntryKind.creditNote,
            ),
            hasLength(1),
          );
          expect(completed.refundsMinor, before.refundsMinor + refundable);
          expect(completed.salesTodayMinor, before.salesTodayMinor);
          expect(completed.availableMinor, before.availableMinor);
          expect(
            identical(await adapter.reconcileRefund(finalRefund), completed),
            isTrue,
          );
          final restoredRefund = WorkspaceLedgerCheckpoint.fromJson(
            jsonDecode(
              jsonEncode(
                WorkspaceLedgerCheckpoint(
                  revision: 1,
                  finance: completed,
                ).toJson(),
              ),
            ),
          )!;
          final recoveredAdapter = StoreReviewCustomerCollectionGateway(
            seed.finance,
          );
          expect(
            recoveredAdapter.restoreCheckpoint(
              restoredRefund.finance,
              seed.finance,
            ),
            isTrue,
          );
          expect(
            (await recoveredAdapter.reconcileRefund(finalRefund)).revision,
            completed.revision,
          );
          await expectLater(
            recoveredAdapter.reconcileRefund(
              refund('REFUND-2', refundable - 100, ledger.revision + 99),
            ),
            throwsStateError,
          );
          await expectLater(
            adapter.recordRefund(
              refund('AFTER-SETTLED', 1, completedLedger.revision),
            ),
            throwsStateError,
          );
        }
      });
    }

    test('discounted partial returns preserve exact full invoice value', () {
      final first = request('return-1', 1);
      final second = request('return-2', 1, restock: 0);
      final third = request('return-3', 1);
      expect(first.creditMinorFor(order, priorReturns: []), 333);
      expect(second.creditMinorFor(order, priorReturns: [first]), 333);
      expect(third.creditMinorFor(order, priorReturns: [first, second]), 334);
      expect(request('full', 3).creditMinorFor(order, priorReturns: []), 1000);
      expect(second.lines.single.restockQuantity, 0);
      expect(() => first.lines.clear(), throwsUnsupportedError);
    });
    test(
      'duplicates, excess quantities and another account cannot create credit',
      () {
        final first = request('return-1', 2);
        expect(first.creditMinorFor(order, priorReturns: [first]), isNull);
        expect(
          request('return-2', 2).creditMinorFor(order, priorReturns: [first]),
          isNull,
        );
        expect(
          request('return-2', 1).creditMinorFor(
            order,
            priorReturns: [request('other', 1, account: 'account-B')],
          ),
          isNull,
        );
        expect(
          request(
            'return-2',
            1,
            sku: 'other',
          ).creditMinorFor(order, priorReturns: []),
          isNull,
        );
        expect(request('return-2', 1, restock: 2).valid, isFalse);
        expect(request('return-2', 0).valid, isFalse);
      },
    );
    test('missing prices or unfinished orders cannot authorize a return', () {
      final result = request('return-1', 1);
      expect(
        result.creditMinorFor(
          order.copyWith(itemSnapshots: []),
          priorReturns: [],
        ),
        isNull,
      );
      expect(
        result.creditMinorFor(
          order.copyWith(stage: 'Preparing'),
          priorReturns: [],
        ),
        isNull,
      );
      expect(
        result.creditMinorFor(order.copyWith(amount: 11), priorReturns: []),
        isNull,
      );
    });
  });

  group('LEDGER01 customer statement', () {
    final now = DateTime.utc(2026, 9, 14, 12);
    test(
      'customer book follows collections in paise rather than stale order labels',
      () async {
        final seed = StoreReviewSeed(
          accountScope: 'account-A',
          orderCount: 12,
          now: DateTime.utc(2026, 9, 11),
        );
        final work = WorkSession(
          gateway: ReviewWorkGateway(),
          pendingProofStore: _CommandAccountStore(),
        )..activeWorkspace = seed.workspace;
        addTearDown(work.dispose);
        work.workspaceOrders.addAll(seed.orders);
        work.applyWorkspaceFinance(seed.finance);
        work.bindCustomerCollectionGateway(
          accountScope: 'account-A',
          storeId: seed.storeId,
          adapter: StoreReviewCustomerCollectionGateway(seed.finance),
          checkpointStore: SecureWorkLedgerCheckpointStore(
            accountScope: () => 'account-A',
            storage: _OrderJournalStorage(),
          ),
        );
        final payment = seed.finance.payments.first;
        WorkspaceCustomerRecord customer() => work.workspaceCustomerBook
            .singleWhere((c) => c.id == payment.customerId);
        expect(customer().amountDueMinor, payment.dueMinor);
        expect(
          await work.recordCustomerCollection(
            customerId: payment.customerId,
            invoiceId: payment.invoiceId!,
            amountMinor: 101,
            channel: WorkspacePaymentChannel.cash,
          ),
          isTrue,
        );
        expect(customer().amountDueMinor, payment.dueMinor - 101);
        expect(customer().hasDues, isTrue);
        expect(
          work.workspaceCustomerBook
              .singleWhere((c) => c.id == 'QA-CUSTOMER-3')
              .balanceAvailable,
          isFalse,
        );
        expect(
          await work.recordCustomerCollection(
            customerId: payment.customerId,
            invoiceId: payment.invoiceId!,
            amountMinor: payment.dueMinor - 101,
            channel: WorkspacePaymentChannel.cash,
          ),
          isTrue,
        );
        expect(customer().amountDueMinor, 0);
        expect(customer().hasDues, isFalse);
        expect(work.workspaceOrders.first.payment, 'Payment due');
        expect(work.workspaceStockMovements, isEmpty);
      },
    );
    for (final authorityRetained in [true, false]) {
      test(
        'pending collection survives restart; authority retained=$authorityRetained',
        () async {
          final bytes = _OrderJournalStorage();
          final journal = SecureWorkLedgerCheckpointStore(
            accountScope: () => 'account-A',
            storage: bytes,
          );
          final seed = StoreReviewSeed(
            accountScope: 'account-A',
            orderCount: 12,
            now: DateTime.utc(2026, 9, 11),
          );
          WorkSession open(WorkCustomerCollectionGateway adapter) {
            final work = WorkSession(
              gateway: ReviewWorkGateway(),
              pendingProofStore: _CommandAccountStore(),
            )..activeWorkspace = seed.workspace;
            work.applyWorkspaceFinance(seed.finance);
            work.bindCustomerCollectionGateway(
              accountScope: 'account-A',
              storeId: seed.storeId,
              adapter: adapter,
              checkpointStore: journal,
            );
            return work;
          }

          final authority = _LostCollectionGateway(seed.finance);
          final first = open(authority);
          final payment = seed.finance.payments.first;
          expect(
            await first.recordCustomerCollection(
              customerId: payment.customerId,
              invoiceId: payment.invoiceId!,
              amountMinor: 100,
              channel: WorkspacePaymentChannel.cash,
            ),
            isFalse,
          );
          final operation = first.pendingCustomerCollection!.operationId;
          first.dispose();
          final nextAdapter = authorityRetained
              ? authority
              : _LostCollectionGateway(seed.finance);
          final restarted = open(nextAdapter);
          addTearDown(restarted.dispose);
          expect(await restarted.recoverCustomerLedger(), isTrue);
          expect(restarted.pendingCustomerCollection!.operationId, operation);
          expect(
            await restarted.recordCustomerCollection(
              customerId: payment.customerId,
              invoiceId: payment.invoiceId!,
              amountMinor: 100,
              channel: WorkspacePaymentChannel.cash,
            ),
            isFalse,
          );
          expect(
            await restarted.reconcileCustomerCollection(),
            authorityRetained,
          );
          expect(nextAdapter.submissions, authorityRetained ? 1 : 0);
          expect(
            restarted.workspaceFinance!.duesMinor,
            seed.finance.duesMinor - (authorityRetained ? 100 : 0),
          );
          if (!authorityRetained) {
            expect(restarted.pendingCustomerCollection!.operationId, operation);
            expect(
              (await journal.read(
                'account-A',
                seed.storeId,
              ))!.pending!.operationId,
              operation,
            );
          }
        },
      );
    }
    test(
      'LEDGER01 pending return survives session recovery and locks money actions',
      () async {
        final seed = StoreReviewSeed(
          accountScope: 'account-A',
          orderCount: 12,
          now: DateTime.utc(2026, 9, 11),
        );
        final payment = seed.finance.payments.first;
        final ledger = seed.finance.customerLedgers.singleWhere(
          (item) => item.customerId == payment.customerId,
        );
        final intent = WorkspacePendingCustomerReturn(
          creditMinor: 100,
          request: WorkspaceCustomerReturn(
            accountScope: 'account-A',
            workspaceId: seed.storeId,
            customerId: payment.customerId,
            invoiceId: payment.invoiceId!,
            orderId: payment.orderId,
            operationId: 'RETURN-RECOVER',
            expectedRevision: ledger.revision,
            reason: 'One pack returned',
            lines: const [
              WorkspaceCustomerReturnLine(
                productId: 'sku-A',
                quantity: 1,
                restockQuantity: 1,
              ),
            ],
          ),
        );
        final bytes = _OrderJournalStorage();
        final journal = SecureWorkLedgerCheckpointStore(
          accountScope: () => 'account-A',
          storage: bytes,
        );
        await journal.save(
          WorkspaceLedgerCheckpoint(
            revision: 1,
            finance: seed.finance,
            pendingReturn: intent,
          ),
          expectedRevision: null,
        );
        final session = WorkSession(
          gateway: ReviewWorkGateway(),
          pendingProofStore: _CommandAccountStore(),
        )..activeWorkspace = seed.workspace;
        addTearDown(session.dispose);
        expect(session.applyWorkspaceFinance(seed.finance), isTrue);
        expect(
          session.bindCustomerCollectionGateway(
            accountScope: 'account-A',
            storeId: seed.storeId,
            adapter: StoreReviewCustomerCollectionGateway(seed.finance),
            checkpointStore: journal,
          ),
          isTrue,
        );
        expect(await session.recoverCustomerLedger(), isTrue);
        expect(session.pendingCustomerReturn!.toJson(), intent.toJson());
        expect(session.customerCollectionAvailable, isFalse);
        expect(
          await session.recordCustomerCollection(
            customerId: payment.customerId,
            invoiceId: payment.invoiceId!,
            amountMinor: 100,
            channel: WorkspacePaymentChannel.cash,
          ),
          isFalse,
        );
        expect(
          session.bindCustomerCollectionGateway(
            accountScope: 'account-A',
            storeId: seed.storeId,
            adapter: StoreReviewCustomerCollectionGateway(seed.finance),
            checkpointStore: journal,
          ),
          isFalse,
        );
        expect(await session.submitWorkspaceCounterBill(), isNull);
        expect(session.workspaceInvoices, isEmpty);
        expect(session.workspaceStockMovements, isEmpty);
        expect(bytes.writes, hasLength(1));
        expect(
          (await journal.read(
            'account-A',
            seed.storeId,
          ))!.pendingReturn!.toJson(),
          intent.toJson(),
        );
      },
    );

    test(
      'completed collection survives session restart without reseeding balances',
      () async {
        final bytes = _OrderJournalStorage();
        final journal = SecureWorkLedgerCheckpointStore(
          accountScope: () => 'account-A',
          storage: bytes,
        );
        final seed = StoreReviewSeed(
          accountScope: 'account-A',
          orderCount: 12,
          now: DateTime.utc(2026, 9, 11),
        );
        WorkSession open(
          StoreReviewSeed value,
          WorkCustomerCollectionGateway adapter,
        ) {
          final session = WorkSession(
            gateway: ReviewWorkGateway(),
            pendingProofStore: _CommandAccountStore(),
          )..activeWorkspace = value.workspace;
          session.workspaceOrders.addAll(value.orders);
          expect(session.applyWorkspaceFinance(value.finance), isTrue);
          expect(
            session.bindCustomerCollectionGateway(
              accountScope: 'account-A',
              storeId: value.storeId,
              adapter: adapter,
              checkpointStore: journal,
            ),
            isTrue,
          );
          return session;
        }

        final first = open(
          seed,
          StoreReviewCustomerCollectionGateway(seed.finance),
        );
        final payment = seed.finance.payments.first;
        final amount = payment.dueMinor ~/ 2;
        expect(
          await first.recordCustomerCollection(
            customerId: payment.customerId,
            invoiceId: payment.invoiceId!,
            amountMinor: amount,
            channel: WorkspacePaymentChannel.cash,
          ),
          isTrue,
        );
        first.dispose();
        final freshSeed = StoreReviewSeed(
          accountScope: 'account-A',
          orderCount: 12,
          now: DateTime.utc(2026, 9, 12),
        );
        final second = open(
          freshSeed,
          StoreReviewCustomerCollectionGateway(freshSeed.finance),
        );
        addTearDown(second.dispose);
        expect(await second.recoverCustomerLedger(), isTrue);
        expect(
          second.workspaceFinance!.duesMinor,
          seed.finance.duesMinor - amount,
        );
        expect(second.pendingCustomerCollection, isNull);
        expect(
          second.workspaceOrders.map((o) => o.id),
          freshSeed.orders.map((o) => o.id),
        );
        expect(
          await second.recordCustomerCollection(
            customerId: payment.customerId,
            invoiceId: payment.invoiceId!,
            amountMinor: payment.dueMinor - amount,
            channel: WorkspacePaymentChannel.cash,
          ),
          isTrue,
        );
        expect(second.workspaceFinance!.payments.first.dueMinor, 0);
        expect(
          second.workspaceFinance!.salesTodayMinor,
          seed.finance.salesTodayMinor,
        );
        expect(second.workspaceStockMovements, isEmpty);
      },
    );

    test(
      'storage failure prevents adapter submission and keeps the same receipt',
      () async {
        final bytes = _OrderJournalStorage()..failWrite = true;
        final seed = StoreReviewSeed(
          accountScope: 'account-A',
          orderCount: 12,
          now: DateTime.utc(2026, 9, 11),
        );
        final adapter = _LostCollectionGateway(seed.finance);
        final work = WorkSession(
          gateway: ReviewWorkGateway(),
          pendingProofStore: _CommandAccountStore(),
        )..activeWorkspace = seed.workspace;
        addTearDown(work.dispose);
        work.applyWorkspaceFinance(seed.finance);
        work.bindCustomerCollectionGateway(
          accountScope: 'account-A',
          storeId: seed.storeId,
          adapter: adapter,
          checkpointStore: SecureWorkLedgerCheckpointStore(
            accountScope: () => 'account-A',
            storage: bytes,
          ),
        );
        final payment = seed.finance.payments.first;
        expect(
          await work.recordCustomerCollection(
            customerId: payment.customerId,
            invoiceId: payment.invoiceId!,
            amountMinor: 100,
            channel: WorkspacePaymentChannel.cash,
          ),
          isFalse,
        );
        expect(adapter.submissions, 0);
        final original = work.pendingCustomerCollection!.operationId;
        bytes.failWrite = false;
        expect(
          await work.reconcileCustomerCollection(),
          isFalse,
        ); // Adapter applies but deliberately loses reply.
        expect(adapter.submissions, 1);
        expect(work.pendingCustomerCollection!.operationId, original);
        expect(await work.reconcileCustomerCollection(), isTrue);
        expect(adapter.submissions, 1);
      },
    );
    test(
      'checkpoint corruption is preserved and concurrent stale write is rejected',
      () async {
        final bytes = _OrderJournalStorage();
        final seed = StoreReviewSeed(
          accountScope: 'account-A',
          orderCount: 12,
          now: now,
        );
        final first = SecureWorkLedgerCheckpointStore(
          accountScope: () => 'account-A',
          storage: bytes,
        );
        final second = SecureWorkLedgerCheckpointStore(
          accountScope: () => 'account-A',
          storage: bytes,
        );
        final checkpoint = WorkspaceLedgerCheckpoint(
          revision: 1,
          finance: seed.finance,
        );
        bytes.holdWrite = Completer<void>();
        final saving = first.save(checkpoint, expectedRevision: null);
        await _drainOrderJournal();
        final stale = second.save(
          WorkspaceLedgerCheckpoint(
            revision: 1,
            finance: StoreReviewSeed(
              accountScope: 'account-A',
              orderCount: 12,
              now: now.add(const Duration(seconds: 1)),
            ).finance,
          ),
          expectedRevision: null,
        );
        final rejection = expectLater(
          stale,
          throwsA(isA<WorkGatewayException>()),
        );
        await _drainOrderJournal();
        expect(bytes.writes, hasLength(1));
        bytes.holdWrite!.complete();
        await saving;
        await rejection;
        final key = bytes.values.keys.single;
        bytes.values[key] = '{invalid retained data';
        await expectLater(
          first.read('account-A', seed.storeId),
          throwsA(isA<WorkGatewayException>()),
        );
        await expectLater(
          first.save(checkpoint, expectedRevision: null),
          throwsA(isA<WorkGatewayException>()),
        );
        expect(bytes.values[key], '{invalid retained data');
      },
    );
    test(
      'LEDGER01 return quantities survive secure checkpoint recovery',
      () async {
        final seed = StoreReviewSeed(
          accountScope: 'account-A',
          orderCount: 12,
          now: now,
        );
        final original = WorkspaceLedgerCheckpoint(
          revision: 1,
          finance: seed.finance,
        );
        final json = jsonDecode(jsonEncode(original.toJson())) as Map;
        final finance = json['finance'] as Map;
        final ledgers = finance['customerLedgers'] as List;
        final ledger = ledgers.first as Map;
        final entries = ledger['entries'] as List;
        final bill = entries.first as Map;
        final request = WorkspaceCustomerReturn(
          accountScope: 'account-A',
          workspaceId: seed.storeId,
          customerId: ledger['customerId'] as String,
          invoiceId: bill['invoiceId'] as String,
          orderId: bill['orderId'] as String,
          operationId: 'RETURN-1',
          expectedRevision: ledger['revision'] as int,
          reason: 'One damaged pack',
          lines: const [
            WorkspaceCustomerReturnLine(
              productId: 'sku-return',
              quantity: 1,
              restockQuantity: 0,
            ),
          ],
        );
        entries.add({
          'id': 'CREDIT-RETURN-1',
          'operationId': request.operationId,
          'invoiceId': request.invoiceId,
          'orderId': request.orderId,
          'sequence': (entries.last['sequence'] as int) + 1,
          'occurredAt': ledger['asOf'],
          'kind': 'creditNote',
          'state': 'posted',
          'amountMinor': 100,
          'channel': 'unknown',
          'paymentReference': null,
          'customerReturn': request.toJson(),
        });
        ledger['revision'] = (ledger['revision'] as int) + 1;
        finance['revision'] = (finance['revision'] as int) + 1;
        json['revision'] = 2;
        final checkpoint = WorkspaceLedgerCheckpoint.fromJson(json)!;
        final storage = _OrderJournalStorage();
        SecureWorkLedgerCheckpointStore open() =>
            SecureWorkLedgerCheckpointStore(
              accountScope: () => 'account-A',
              storage: storage,
            );
        await open().save(original, expectedRevision: null);
        await open().save(checkpoint, expectedRevision: 1);
        final restored = (await open().read('account-A', seed.storeId))!;
        final recovered = restored.finance.customerLedgers.first.entries.last;
        expect(recovered.customerReturn!.toJson(), request.toJson());
        expect(recovered.customerReturn!.lines.single.restockQuantity, 0);
        expect(
          recovered.identityData,
          checkpoint.finance.customerLedgers.first.entries.last.identityData,
        );
        (entries.last['customerReturn'] as Map)['workspaceId'] =
            'another-store';
        expect(WorkspaceLedgerCheckpoint.fromJson(json), isNull);
        (entries.last['customerReturn'] as Map)['workspaceId'] = seed.storeId;
        (entries.last['customerReturn']['lines'] as List)
                .first['restockQuantity'] =
            2;
        expect(WorkspaceLedgerCheckpoint.fromJson(json), isNull);
        (entries.last['customerReturn']['lines'] as List)
                .first['restockQuantity'] =
            1;
        json['revision'] = 3;
        finance['revision'] = (finance['revision'] as int) + 1;
        ledger['revision'] = (ledger['revision'] as int) + 1;
        final altered = WorkspaceLedgerCheckpoint.fromJson(json)!;
        expect(
          altered.finance.customerLedgers.first.canFollow(
            restored.finance.customerLedgers.first,
          ),
          isFalse,
        );
        await expectLater(
          open().save(altered, expectedRevision: 2),
          throwsA(
            isA<WorkGatewayException>().having(
              (error) => error.toString(),
              'reason',
              'Known ledger history cannot be replaced.',
            ),
          ),
        );
      },
    );

    test(
      'checkpoint round trip preserves projection and pending receipt identity',
      () {
        final seed = StoreReviewSeed(
          accountScope: 'account-A',
          orderCount: 12,
          now: now,
        );
        final payment = seed.finance.payments.first;
        final checkpoint = WorkspaceLedgerCheckpoint(
          revision: 1,
          finance: seed.finance,
          pending: WorkspaceCustomerCollection(
            accountScope: 'account-A',
            workspaceId: seed.storeId,
            customerId: payment.customerId,
            invoiceId: payment.invoiceId!,
            orderId: payment.orderId,
            operationId: 'recover-1',
            expectedRevision: 1,
            amountMinor: 100,
            channel: WorkspacePaymentChannel.directUpi,
            reference: 'UPI-REFERENCE',
          ),
        );
        final decoded = WorkspaceLedgerCheckpoint.fromJson(
          jsonDecode(jsonEncode(checkpoint.toJson())),
        )!;
        expect(decoded.toJson(), checkpoint.toJson());
        expect(decoded.pending!.identityData, checkpoint.pending!.identityData);
        for (final invalid in [
          null,
          {},
          {...checkpoint.toJson(), 'version': 2},
          {...checkpoint.toJson(), 'revision': 1.5},
          {
            ...checkpoint.toJson(),
            'finance': {'accountScope': 'other'},
          },
        ]) {
          expect(WorkspaceLedgerCheckpoint.fromJson(invalid), isNull);
        }
      },
    );

    test(
      'encrypted checkpoint survives new instance and forbids loss of pending collection',
      () async {
        final bytes = _OrderJournalStorage();
        String? account = 'account-A';
        final store = SecureWorkLedgerCheckpointStore(
          accountScope: () => account,
          storage: bytes,
        );
        final seed = StoreReviewSeed(
          accountScope: 'account-A',
          orderCount: 12,
          now: DateTime.utc(2026, 9, 11),
        );
        final payment = seed.finance.payments.first;
        final request = WorkspaceCustomerCollection(
          accountScope: 'account-A',
          workspaceId: seed.storeId,
          customerId: payment.customerId,
          invoiceId: payment.invoiceId!,
          orderId: payment.orderId,
          operationId: 'recover-1',
          expectedRevision: 1,
          amountMinor: 100,
          channel: WorkspacePaymentChannel.cash,
        );
        final pending = WorkspaceLedgerCheckpoint(
          revision: 1,
          finance: seed.finance,
          pending: request,
        );
        await store.save(pending, expectedRevision: null);
        final restarted = SecureWorkLedgerCheckpointStore(
          accountScope: () => account,
          storage: bytes,
        );
        expect(
          (await restarted.read(
            'account-A',
            seed.storeId,
          ))!.pending!.identityData,
          request.identityData,
        );
        await restarted.save(
          pending,
          expectedRevision: null,
        ); // Same uncertain native write, not a second operation.
        await expectLater(
          restarted.save(
            WorkspaceLedgerCheckpoint(revision: 2, finance: seed.finance),
            expectedRevision: 1,
          ),
          throwsA(isA<WorkGatewayException>()),
        );
        final posted = await StoreReviewCustomerCollectionGateway(
          seed.finance,
        ).recordCollection(request);
        final complete = WorkspaceLedgerCheckpoint(
          revision: 2,
          finance: posted,
        );
        await restarted.save(complete, expectedRevision: 1);
        expect(
          (await store.read('account-A', seed.storeId))!.finance.duesMinor,
          seed.finance.duesMinor - 100,
        );
        await expectLater(
          store.save(pending, expectedRevision: null),
          throwsA(isA<WorkGatewayException>()),
        );
        expect(await store.read('account-A', 'different-store'), isNull);
        account = 'account-B';
        await expectLater(
          store.read('account-A', seed.storeId),
          throwsA(isA<WorkGatewayException>()),
        );
      },
    );
    test(
      'collection lost reply reconciles once without a sale or stock movement',
      () async {
        final seed = StoreReviewSeed(
          accountScope: 'account-A',
          orderCount: 12,
          now: DateTime.utc(2026, 9, 11),
        );
        final work = WorkSession(
          gateway: ReviewWorkGateway(),
          pendingProofStore: _CommandAccountStore(),
        )..activeWorkspace = seed.workspace;
        addTearDown(work.dispose);
        expect(work.applyWorkspaceFinance(seed.finance), isTrue);
        final gateway = _LostCollectionGateway(seed.finance);
        expect(
          work.bindCustomerCollectionGateway(
            accountScope: 'account-A',
            storeId: seed.storeId,
            adapter: gateway,
            checkpointStore: SecureWorkLedgerCheckpointStore(
              accountScope: () => 'account-A',
              storage: _OrderJournalStorage(),
            ),
          ),
          isTrue,
        );
        final invoice = seed.finance.payments.first;
        final amount = invoice.dueMinor ~/ 2;
        expect(
          await work.recordCustomerCollection(
            customerId: invoice.customerId,
            invoiceId: invoice.invoiceId!,
            amountMinor: amount,
            channel: WorkspacePaymentChannel.cash,
          ),
          isFalse,
        );
        final operation = work.pendingCustomerCollection!.operationId;
        expect(work.workspaceFinance!.duesMinor, seed.finance.duesMinor);
        expect(
          await work.recordCustomerCollection(
            customerId: invoice.customerId,
            invoiceId: invoice.invoiceId!,
            amountMinor: amount,
            channel: WorkspacePaymentChannel.cash,
          ),
          isFalse,
        );
        expect(gateway.submissions, 1);
        expect(await work.reconcileCustomerCollection(), isTrue);
        expect(work.pendingCustomerCollection, isNull);
        final result = work.workspaceFinance!;
        expect(result.duesMinor, seed.finance.duesMinor - amount);
        expect(
          result.customerLedgers.first.entries.where(
            (e) => e.operationId == operation,
          ),
          hasLength(1),
        );
        expect(result.salesTodayMinor, seed.finance.salesTodayMinor);
        expect(result.availableMinor, seed.finance.availableMinor);
        expect(work.workspaceStockMovements, isEmpty);
        expect(work.workspaceInvoices, isEmpty);
        expect(await work.reconcileCustomerCollection(), isFalse);
      },
    );

    test(
      'collection adapter rejects overpayment and operation retargeting',
      () async {
        final seed = StoreReviewSeed(
          accountScope: 'account-A',
          orderCount: 12,
          now: DateTime.utc(2026, 9, 11),
        );
        final adapter = StoreReviewCustomerCollectionGateway(seed.finance);
        final invoice = seed.finance.payments.first;
        WorkspaceCustomerCollection request(
          int amount, {
          String operation = 'op-1',
        }) => WorkspaceCustomerCollection(
          accountScope: 'account-A',
          workspaceId: seed.storeId,
          customerId: invoice.customerId,
          invoiceId: invoice.invoiceId!,
          orderId: invoice.orderId,
          operationId: operation,
          expectedRevision: 1,
          amountMinor: amount,
          channel: WorkspacePaymentChannel.cash,
        );
        await expectLater(
          adapter.recordCollection(request(invoice.dueMinor + 1)),
          throwsStateError,
        );
        final applied = await adapter.recordCollection(
          request(invoice.dueMinor),
        );
        expect(applied.payments.first.dueMinor, 0);
        expect(
          identical(
            await adapter.recordCollection(request(invoice.dueMinor)),
            applied,
          ),
          isTrue,
        );
        await expectLater(
          adapter.recordCollection(request(1)),
          throwsStateError,
        );
        expect(request(0).valid, isFalse);
      },
    );
    test('existing test Store history agrees with its payment projection', () {
      for (final count in [12, 100, 1000]) {
        final seed = StoreReviewSeed(
          accountScope: 'qa-ledger',
          orderCount: count,
          now: now,
        );
        final finance = seed.finance;
        expect(finance.valid, isTrue);
        expect(finance.customerLedgers, hasLength(3));
        for (final history in finance.customerLedgers) {
          final payment = finance.payments.singleWhere(
            (record) => record.customerId == history.customerId,
          );
          expect(history.closingBalanceMinor, payment.dueMinor);
          expect(
            history.entries.every(
              (entry) =>
                  entry.invoiceId == payment.invoiceId &&
                  entry.orderId == payment.orderId,
            ),
            isTrue,
          );
        }
      }
    });
    WorkspaceCustomerLedgerEntry entry(
      int sequence,
      WorkspaceLedgerEntryKind kind,
      int amount, {
      WorkspaceLedgerPostingState state = WorkspaceLedgerPostingState.posted,
      String? operation,
      String invoice = 'invoice-1',
    }) => WorkspaceCustomerLedgerEntry(
      id: 'entry-$sequence',
      operationId: operation ?? 'operation-$sequence',
      invoiceId: invoice,
      orderId: 'sale-1',
      sequence: sequence,
      occurredAt: now,
      kind: kind,
      state: state,
      amountMinor: amount,
    );
    WorkspaceCustomerLedger ledger(
      List<WorkspaceCustomerLedgerEntry> entries, {
      int? opening = 0,
      bool complete = true,
      String customer = 'customer-1',
      int revision = 1,
    }) => WorkspaceCustomerLedger(
      accountScope: 'account-A',
      workspaceId: 'store-A',
      customerId: customer,
      customerName: 'Test customer',
      revision: revision,
      asOf: now,
      openingBalanceMinor: opening,
      historyComplete: complete,
      entries: entries,
    );

    test(
      'refresh preserves posted facts and only resolves pending entries',
      () {
        final bill = entry(1, WorkspaceLedgerEntryKind.invoice, 100000);
        final waiting = ledger([
          bill,
          entry(
            2,
            WorkspaceLedgerEntryKind.collection,
            60000,
            state: WorkspaceLedgerPostingState.pending,
          ),
        ]);
        final paid = ledger([
          bill,
          entry(2, WorkspaceLedgerEntryKind.collection, 60000),
        ], revision: 2);
        expect(paid.canFollow(waiting), isTrue);
        expect(waiting.canFollow(paid), isFalse);
        expect(ledger(paid.entries, revision: 2).canFollow(paid), isTrue);
        expect(ledger(paid.entries).canFollow(waiting), isFalse);
        expect(ledger([bill], revision: 3).canFollow(paid), isFalse);
        expect(
          ledger([
            bill,
            entry(2, WorkspaceLedgerEntryKind.collection, 50000),
          ], revision: 3).canFollow(paid),
          isFalse,
        );
        expect(
          ledger(paid.entries, revision: 3, opening: 100).canFollow(paid),
          isFalse,
        );
        expect(
          ledger(paid.entries, revision: 3, customer: 'other').canFollow(paid),
          isFalse,
        );
      },
    );

    test('partial sale and later collection do not post another invoice', () {
      final bill = entry(1, WorkspaceLedgerEntryKind.invoice, 100000);
      final firstPayment = entry(2, WorkspaceLedgerEntryKind.collection, 60000);
      expect(ledger([bill, firstPayment]).closingBalanceMinor, 40000);
      final paid = ledger([
        bill,
        firstPayment,
        entry(3, WorkspaceLedgerEntryKind.collection, 40000),
      ]);
      expect(paid.valid, isTrue);
      expect(paid.closingBalanceMinor, 0);
      expect(
        paid.entries.where((e) => e.kind == WorkspaceLedgerEntryKind.invoice),
        hasLength(1),
      );
      expect(() => paid.entries.clear(), throwsUnsupportedError);
    });

    test('one collection may allocate once to each linked invoice', () {
      final statement = ledger([
        entry(1, WorkspaceLedgerEntryKind.invoice, 60000),
        entry(2, WorkspaceLedgerEntryKind.invoice, 40000, invoice: 'invoice-2'),
        entry(
          3,
          WorkspaceLedgerEntryKind.collection,
          60000,
          operation: 'collection-1',
        ),
        entry(
          4,
          WorkspaceLedgerEntryKind.collection,
          40000,
          operation: 'collection-1',
          invoice: 'invoice-2',
        ),
      ]);
      expect(statement.valid, isTrue);
      expect(statement.closingBalanceMinor, 0);
      expect(
        ledger([
          entry(1, WorkspaceLedgerEntryKind.invoice, 100000),
          entry(2, WorkspaceLedgerEntryKind.invoice, 100000),
        ]).valid,
        isFalse,
      );
    });

    test('pending or failed collection never clears customer dues', () {
      for (final state in [
        WorkspaceLedgerPostingState.pending,
        WorkspaceLedgerPostingState.failed,
      ]) {
        expect(
          ledger([
            entry(1, WorkspaceLedgerEntryKind.invoice, 100000),
            entry(2, WorkspaceLedgerEntryKind.collection, 100000, state: state),
          ]).closingBalanceMinor,
          100000,
        );
      }
    });

    test('LEDGER01 invoice return credit offsets dues before any refund', () {
      final history = [
        entry(1, WorkspaceLedgerEntryKind.invoice, 100000),
        entry(2, WorkspaceLedgerEntryKind.collection, 60000),
        entry(3, WorkspaceLedgerEntryKind.creditNote, 50000),
      ];
      final balance = ledger(history).invoiceBalance('invoice-1');
      expect(balance, isNotNull);
      expect(balance!.dueMinor, 0);
      expect(balance.refundableMinor, 10000);
      final refunded = ledger([
        ...history,
        entry(4, WorkspaceLedgerEntryKind.refund, 10000),
      ]).invoiceBalance('invoice-1');
      expect(refunded!.refundableMinor, 0);
      expect(refunded.refundedMinor, 10000);
      expect(
        ledger([
          ...history,
          entry(4, WorkspaceLedgerEntryKind.refund, 10001),
        ]).invoiceBalance('invoice-1'),
        isNull,
      );
      expect(
        ledger([
          ...history,
          entry(4, WorkspaceLedgerEntryKind.creditNote, 50001),
        ]).invoiceBalance('invoice-1'),
        isNull,
      );
      expect(
        ledger([
          ...history,
          entry(4, WorkspaceLedgerEntryKind.collection, 1),
        ]).invoiceBalance('invoice-1'),
        isNull,
      );
      expect(ledger(history).invoiceBalance('missing'), isNull);
      for (final state in [
        WorkspaceLedgerPostingState.pending,
        WorkspaceLedgerPostingState.failed,
      ]) {
        expect(
          ledger([
            ...history,
            entry(4, WorkspaceLedgerEntryKind.refund, 10000, state: state),
          ]).invoiceBalance('invoice-1')!.refundableMinor,
          10000,
        );
      }
    });

    test('return credit and completed refund stay separate from sales', () {
      final history = [
        entry(1, WorkspaceLedgerEntryKind.invoice, 100000),
        entry(2, WorkspaceLedgerEntryKind.collection, 100000),
        entry(3, WorkspaceLedgerEntryKind.creditNote, 20000),
      ];
      expect(ledger(history).closingBalanceMinor, -20000);
      expect(
        ledger([
          ...history,
          entry(
            4,
            WorkspaceLedgerEntryKind.refund,
            20000,
            state: WorkspaceLedgerPostingState.pending,
          ),
        ]).closingBalanceMinor,
        -20000,
      );
      expect(
        ledger([
          ...history,
          entry(4, WorkspaceLedgerEntryKind.refund, 20000),
        ]).closingBalanceMinor,
        0,
      );
    });

    test('duplicates, reordering and unidentified customer are rejected', () {
      final bill = entry(1, WorkspaceLedgerEntryKind.invoice, 100000);
      for (final invalid in [
        ledger([bill, bill]),
        ledger([
          bill,
          entry(
            2,
            WorkspaceLedgerEntryKind.invoice,
            100000,
            operation: bill.operationId,
          ),
        ]),
        ledger([entry(2, WorkspaceLedgerEntryKind.collection, 60000), bill]),
        ledger([bill], customer: ''),
      ]) {
        expect(invalid.valid, isFalse);
        expect(invalid.closingBalanceMinor, isNull);
      }
    });

    test('missing opening or partial history cannot imply a balance', () {
      final bill = entry(1, WorkspaceLedgerEntryKind.invoice, 100000);
      expect(ledger([bill], opening: null).valid, isFalse);
      final partial = ledger([bill], opening: null, complete: false);
      expect(partial.valid, isTrue);
      expect(partial.closingBalanceMinor, isNull);
      expect(ledger([bill], opening: 5000).closingBalanceMinor, 105000);
      expect(ledger([bill], opening: 9007199254740991).valid, isFalse);
    });
  });
  test(
    'Supplier payment access is specific to supplier, account and Store',
    () {
      final access = WorkSupplierPaymentAccess(
        supplierId: 'supplier-A',
        publicTermIds: {'full-payment'},
        storeTermIds: {
          ('account-A', 'store-A'): {'credit-30'},
        },
      );
      expect(
        access.permits(
          'full-payment',
          supplier: 'supplier-A',
          account: 'account-B',
          store: 'store-B',
        ),
        isTrue,
      );
      expect(
        access.permits(
          'credit-30',
          supplier: 'supplier-A',
          account: 'account-A',
          store: 'store-A',
        ),
        isTrue,
      );
      expect(
        access.permits(
          'credit-30',
          supplier: 'supplier-A',
          account: 'account-B',
          store: 'store-A',
        ),
        isFalse,
      );
      expect(
        access.permits(
          'credit-30',
          supplier: 'supplier-A',
          account: 'account-A',
          store: 'store-B',
        ),
        isFalse,
      );
      expect(
        access.permits(
          'full-payment',
          supplier: 'supplier-B',
          account: 'account-A',
          store: 'store-A',
        ),
        isFalse,
      );
      expect(
        access.permits(
          'credit-45',
          supplier: 'supplier-A',
          account: 'account-A',
          store: 'store-A',
        ),
        isFalse,
      );
    },
  );
  group('Store procurement controller', () {
    late String account, store;
    late _ProcurementBookmarks bookmarks;
    late WorkProcurementController controller;
    final states = <String, _ProcurementCustomerState>{};
    WorkProcurementController create() => WorkProcurementController(
      currentAccountId: () => account,
      currentStoreId: () => store,
      storeApproved: () => true,
      bookmarks: bookmarks,
      stateStoreFactory: (scope) =>
          states.putIfAbsent(scope, () => _ProcurementCustomerState(scope)),
      sessionFactory: (identity, state) => BuyV2Session(
        core: BuySession(),
        procurementIdentity: identity,
        customerStateStore: state,
        reviewDataEnabled: true,
      ),
    );
    setUp(() {
      account = 'a';
      store = 's';
      states.clear();
      bookmarks = _ProcurementBookmarks();
      controller = create();
    });
    tearDown(() => controller.dispose());
    for (final purpose in [
      BuyV2ProcurementPurpose.buyDirect,
      BuyV2ProcurementPurpose.groupBulkBuying,
    ]) {
      test('exact purchase context survives relaunch $purpose', () async {
        final original = BuyV2ProcurementContext(
          accountId: account,
          storeId: store,
          purpose: purpose,
          originOperationId: 'original-purchase-operation',
        );
        expect(
          await controller.open(
            purpose: BuyV2ProcurementPurpose.restock,
            returnTo: 'dashboard',
          ),
          isTrue,
        );
        expect(
          await controller.open(
            purpose: purpose,
            exactContext: original,
            returnTo: 'sourcing',
          ),
          isTrue,
        );
        controller.dispose();
        controller = create();
        expect(
          await controller.open(
            purpose: BuyV2ProcurementPurpose.restock,
            returnTo: 'dashboard',
            restoreOnly: true,
          ),
          isTrue,
        );
        expect(
          controller.bookmark!.context.customerStateOwnerScope,
          original.customerStateOwnerScope,
        );
        expect(controller.bookmark!.returnTo, 'sourcing');
      });
    }
    test(
      'exact purchase context rejects foreign identity and purpose without mutation',
      () async {
        expect(
          await controller.open(
            purpose: BuyV2ProcurementPurpose.restock,
            returnTo: 'dashboard',
          ),
          isTrue,
        );
        final before = controller.bookmark;
        for (final context in [
          BuyV2ProcurementContext(
            accountId: 'other',
            storeId: store,
            purpose: BuyV2ProcurementPurpose.buyDirect,
            originOperationId: 'p',
          ),
          BuyV2ProcurementContext(
            accountId: account,
            storeId: 'other',
            purpose: BuyV2ProcurementPurpose.buyDirect,
            originOperationId: 'p',
          ),
          BuyV2ProcurementContext(
            accountId: account,
            storeId: store,
            purpose: BuyV2ProcurementPurpose.restock,
            originOperationId: 'p',
          ),
          BuyV2ProcurementContext(
            accountId: account,
            storeId: store,
            purpose: BuyV2ProcurementPurpose.buyDirect,
            originOperationId: '',
          ),
        ]) {
          expect(
            await controller.open(
              purpose: BuyV2ProcurementPurpose.buyDirect,
              exactContext: context,
              returnTo: 'sourcing',
            ),
            isFalse,
          );
          expect(controller.bookmark, same(before));
        }
      },
    );
    test('relaunch restores exact operation and scope', () async {
      expect(
        await controller.open(
          purpose: BuyV2ProcurementPurpose.restock,
          returnTo: 'stockStatement',
        ),
        isTrue,
      );
      final scope =
          controller.session!.procurementContext!.customerStateOwnerScope;
      controller.dispose();
      controller = create();
      expect(
        await controller.open(
          purpose: BuyV2ProcurementPurpose.restock,
          returnTo: 'dashboard',
          restoreOnly: true,
        ),
        isTrue,
      );
      expect(
        controller.session!.procurementContext!.customerStateOwnerScope,
        scope,
      );
      expect(controller.bookmark!.returnTo, 'stockStatement');
      expect(controller.session!.isStoreProcurement, isTrue);
    });
    test(
      'leaving prevents auto reopen but retains operation for deliberate return',
      () async {
        await controller.open(
          purpose: BuyV2ProcurementPurpose.restock,
          returnTo: 'dashboard',
        );
        final scope =
            controller.session!.procurementContext!.customerStateOwnerScope;
        expect(await controller.leave(), isTrue);
        controller.dispose();
        controller = create();
        expect(
          await controller.open(
            purpose: BuyV2ProcurementPurpose.restock,
            returnTo: 'dashboard',
            restoreOnly: true,
          ),
          isFalse,
        );
        expect(
          await controller.open(
            purpose: BuyV2ProcurementPurpose.restock,
            returnTo: 'dashboard',
          ),
          isTrue,
        );
        expect(
          controller.session!.procurementContext!.customerStateOwnerScope,
          scope,
        );
      },
    );
    test(
      'account switch invalidates the previous session immediately',
      () async {
        await controller.open(
          purpose: BuyV2ProcurementPurpose.restock,
          returnTo: 'dashboard',
        );
        account = 'b';
        controller.invalidateIfChanged();
        expect(controller.session, isNull);
        expect(
          await controller.open(
            purpose: BuyV2ProcurementPurpose.restock,
            returnTo: 'dashboard',
            restoreOnly: true,
          ),
          isFalse,
        );
      },
    );
    test('late bookmark cannot open after Store changes', () async {
      bookmarks.holdRead = Completer<void>();
      final pending = controller.open(
        purpose: BuyV2ProcurementPurpose.restock,
        returnTo: 'dashboard',
      );
      store = 'other';
      bookmarks.holdRead!.complete();
      expect(await pending, isFalse);
      expect(controller.session, isNull);
    });
    test(
      'supply purpose changes preserve distinct resumable namespaces',
      () async {
        final scopes = <BuyV2ProcurementPurpose, String>{};
        for (final purpose in BuyV2ProcurementPurpose.values) {
          expect(
            await controller.open(purpose: purpose, returnTo: 'dashboard'),
            isTrue,
          );
          scopes[purpose] =
              controller.session!.procurementContext!.customerStateOwnerScope;
          controller.session!.updateQuery('retained-${purpose.name}');
          for (var i = 0; i < 12; i++) {
            await Future<void>.delayed(Duration.zero);
          }
        }
        expect(
          scopes.values.toSet().length,
          BuyV2ProcurementPurpose.values.length,
        );
        controller.dispose();
        controller = create();
        for (final purpose in BuyV2ProcurementPurpose.values) {
          expect(
            await controller.open(purpose: purpose, returnTo: 'dashboard'),
            isTrue,
          );
          expect(
            controller.session!.procurementContext!.customerStateOwnerScope,
            scopes[purpose],
          );
          expect(controller.session!.query, 'retained-${purpose.name}');
        }
      },
    );
    test('failed read preserves the operation and permits retry', () async {
      expect(
        await controller.open(
          purpose: BuyV2ProcurementPurpose.restock,
          returnTo: 'dashboard',
        ),
        isTrue,
      );
      final original = controller.bookmark!.context.originOperationId;
      controller.dispose();
      controller = create();
      bookmarks.failRead = true;
      expect(
        await controller.open(
          purpose: BuyV2ProcurementPurpose.restock,
          returnTo: 'dashboard',
        ),
        isFalse,
      );
      expect(controller.session, isNull);
      expect(
        bookmarks.values.values.single.context.originOperationId,
        original,
      );
      bookmarks.failRead = false;
      expect(
        await controller.open(
          purpose: BuyV2ProcurementPurpose.restock,
          returnTo: 'dashboard',
        ),
        isTrue,
      );
      expect(controller.bookmark!.context.originOperationId, original);
    });
    test('failed return save does not claim a completed return', () async {
      await controller.open(
        purpose: BuyV2ProcurementPurpose.restock,
        returnTo: 'sourcing',
      );
      final original = controller.session;
      bookmarks.failSave = true;
      expect(await controller.leave(), isFalse);
      expect(controller.bookmark!.active, isTrue);
      expect(controller.session, same(original));
      bookmarks.failSave = false;
      expect(await controller.leave(), isTrue);
      expect(controller.bookmark!.active, isFalse);
    });
    test(
      'failed initial save never creates an unpersisted purchase session',
      () async {
        bookmarks.failSave = true;
        expect(
          await controller.open(
            purpose: BuyV2ProcurementPurpose.restock,
            returnTo: 'dashboard',
          ),
          isFalse,
        );
        expect(controller.session, isNull);
        expect(bookmarks.values, isEmpty);
      },
    );
  });
  group('Store procurement bookmark', () {
    const bookmark = WorkProcurementBookmark(
      context: BuyV2ProcurementContext(
        accountId: 'account-a',
        storeId: 'store-a',
        purpose: BuyV2ProcurementPurpose.restock,
        originOperationId: 'operation-a',
      ),
      returnTo: 'stockStatement',
    );
    test('round trip retains exact operation and return destination', () {
      final restored = WorkProcurementBookmark.decode(
        bookmark.toJson(),
        accountId: 'account-a',
        storeId: 'store-a',
      );
      expect(restored, isNotNull);
      expect(
        restored!.context.customerStateOwnerScope,
        bookmark.context.customerStateOwnerScope,
      );
      expect(restored.returnTo, 'stockStatement');
    });
    for (final entry in <String, Object?>{
      'accountId': 'other-account',
      'storeId': 'other-store',
      'version': 2,
      'purpose': 'consumer',
      'returnTo': '/external',
      'originOperationId': ' ',
    }.entries) {
      test('rejects changed or invalid ${entry.key}', () {
        final value = bookmark.toJson()..[entry.key] = entry.value;
        expect(
          WorkProcurementBookmark.decode(
            value,
            accountId: 'account-a',
            storeId: 'store-a',
          ),
          isNull,
        );
      });
    }
    test('rejects a different signed-in account or active Store', () {
      expect(
        WorkProcurementBookmark.decode(
          bookmark.toJson(),
          accountId: 'account-b',
          storeId: 'store-a',
        ),
        isNull,
      );
      expect(
        WorkProcurementBookmark.decode(
          bookmark.toJson(),
          accountId: 'account-a',
          storeId: 'store-b',
        ),
        isNull,
      );
    });
  });
  group('DASH07 receiving draft', () {
    test(
      'source snapshot match rejects revision identity and pack changes',
      () {
        final draft = _receiptDraft();
        WorkspacePurchaseRecord shipment({
          int revision = 4,
          String store = 'store-A',
          String supplier = 'supplier-A',
          String pack = '1 l × 12',
        }) => WorkspacePurchaseRecord(
          accountScope: 'account-A',
          workspaceId: store,
          supplierId: supplier,
          supplierName: 'Oil wholesaler',
          orderId: 'order-A',
          shipmentId: 'shipment-A',
          purchaseId: 'purchase-A',
          revision: revision,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026, 9),
          stage: WorkspaceSupplyStage.arriving,
          amountMinor: 15500500,
          itemSummary: 'Oil',
          paymentLabel: 'Paid online',
          lines: [
            WorkspacePurchaseLine(
              id: 'line-A',
              productId: 'sku-A',
              name: 'Sunflower oil',
              pack: pack,
              orderedPacks: 10,
              unitPriceMinor: 1550050,
              receivedPacks: 3,
            ),
          ],
        );
        expect(draft.matchesSnapshot(shipment()), isTrue);
        expect(draft.belongsTo(shipment(revision: 5)), isTrue);
        expect(draft.matchesSnapshot(shipment(revision: 5)), isFalse);
        expect(draft.matchesSnapshot(shipment(pack: '5 l × 4')), isFalse);
        expect(draft.belongsTo(shipment(store: 'store-B')), isFalse);
        expect(draft.belongsTo(shipment(supplier: 'competitor')), isFalse);
        final json = draft.toJson();
        final line = (json['lines'] as List).single;
        expect(
          WorkspaceReceiptDraft.fromJson({
            ...json,
            'lines': [line, line],
          }),
          isNull,
        );
        expect(draft.lines.single.pack, '1 l × 12');
      },
    );

    test(
      'account change during native save never exposes another account draft',
      () async {
        final native = _OrderJournalStorage();
        var account = 'account-A';
        final storage = SecureWorkReceiptDraftStore(
          accountScope: () => account,
          storage: native,
        );
        final held = Completer<void>();
        native.holdWrite = held;
        final draft = _receiptDraft();
        final write = storage.save(draft, expectedRevision: null);
        final rejected = expectLater(
          write,
          throwsA(isA<WorkGatewayException>()),
        );
        await _drainOrderJournal();
        account = 'account-B';
        held.complete();
        await rejected;
        expect(await storage.read(_receiptDraft(account: account).key), isNull);
        await expectLater(
          storage.read(draft.key),
          throwsA(isA<WorkGatewayException>()),
        );
        account = 'account-A';
        expect((await storage.read(draft.key))!.toJson(), draft.toJson());
        final writes = native.writes.length;
        await storage.save(draft, expectedRevision: null);
        expect(native.writes.length, writes);
      },
    );

    test('retains original lines and incomplete counts without false zero', () {
      for (final value in ['', '3.', '-1', 'abc', '999999999999999999999999']) {
        final draft = _receiptDraft(count: value);
        final restored = WorkspaceReceiptDraft.fromJson(
          jsonDecode(jsonEncode(draft.toJson())),
        )!;
        expect(restored.valid, isTrue);
        expect(restored.countedPacks['line-A'], value);
        expect(restored.quantitiesComplete, isFalse);
        expect(restored.counted('line-A'), isNull);
        expect(restored.lines.single.receivedPacks, 3);
        expect(restored.note, draft.note);
      }
      for (final value in ['0', '11', '1000000000']) {
        final draft = _receiptDraft(count: value);
        expect(draft.quantitiesComplete, isTrue);
        expect(draft.counted('line-A'), int.parse(value));
        expect(draft.lines.single.orderedPacks, 10);
        expect(draft.lines.single.receivedPacks, 3);
      }
    });

    test('rejects malformed identities and unknown purchased lines', () {
      final original = _receiptDraft().toJson();
      for (final patch in <Map<String, Object?>>[
        {'schema': 2},
        {'account': ''},
        {'shipmentRevision': 0},
        {'revision': 0},
        {'supplierId': ''},
        {'purchaseId': 42},
        {'lines': []},
        {
          'lines': [original['lines'], original['lines']],
        },
        {
          'countedPacks': {'foreign-line': '10'},
        },
        {
          'countedPacks': {'line-A': 3},
        },
        {
          'problems': {'line-A': 'approve-refund'},
        },
        {
          'problems': {'foreign-line': 'damaged'},
        },
        {'note': List.filled(2001, '📦').join()},
      ]) {
        expect(
          WorkspaceReceiptDraft.fromJson({...original, ...patch}),
          isNull,
          reason: patch.keys.join(','),
        );
      }
      final draft = _receiptDraft();
      expect(() => draft.countedPacks['line-A'] = '7', throwsUnsupportedError);
      expect(() => draft.lines.clear(), throwsUnsupportedError);
    });

    test(
      'encrypted restart recovery stays account Store and shipment scoped',
      () async {
        final native = _OrderJournalStorage();
        String account = 'account-A';
        SecureWorkReceiptDraftStore open() => SecureWorkReceiptDraftStore(
          accountScope: () => account,
          storage: native,
        );
        final drafts = [
          _receiptDraft(count: '7'),
          _receiptDraft(store: 'store-B', count: '2'),
          _receiptDraft(shipment: 'shipment-B', count: '9'),
        ];
        for (final draft in drafts) {
          await open().save(draft, expectedRevision: null);
        }
        for (final draft in drafts) {
          expect((await open().read(draft.key))!.toJson(), draft.toJson());
        }
        expect(native.values, hasLength(3));
        account = 'account-B';
        await expectLater(
          open().read(drafts.first.key),
          throwsA(isA<WorkGatewayException>()),
        );
        expect(await open().read(_receiptDraft(account: account).key), isNull);
        expect(native.values, hasLength(3));
      },
    );

    test(
      'stale editor cannot overwrite newer count or source snapshot',
      () async {
        final native = _OrderJournalStorage();
        final storage = SecureWorkReceiptDraftStore(
          accountScope: () => 'account-A',
          storage: native,
        );
        await storage.save(_receiptDraft(), expectedRevision: null);
        final newer = _receiptDraft(revision: 2, count: '8');
        await storage.save(newer, expectedRevision: 1);
        final writeCount = native.writes.length;
        await storage.save(newer, expectedRevision: 1);
        expect(
          native.writes.length,
          writeCount,
        ); // Same successful write retry.
        for (final candidate in [
          _receiptDraft(revision: 2, count: '9'),
          _receiptDraft(revision: 3, supplier: 'other'),
          _receiptDraft(revision: 3, product: 'replacement-sku'),
          _receiptDraft(revision: 3, shipmentRevision: 5),
        ]) {
          await expectLater(
            storage.save(candidate, expectedRevision: candidate.revision - 1),
            throwsA(isA<WorkGatewayException>()),
          );
        }
        expect((await storage.read(newer.key))!.toJson(), newer.toJson());
      },
    );

    test(
      'read failure and corrupt evidence cannot be replaced by blank draft',
      () async {
        final native = _OrderJournalStorage();
        final storage = SecureWorkReceiptDraftStore(
          accountScope: () => 'account-A',
          storage: native,
        );
        final draft = _receiptDraft();
        await storage.save(draft, expectedRevision: null);
        native.failRead = true;
        await expectLater(
          storage.save(_receiptDraft(revision: 2), expectedRevision: 1),
          throwsStateError,
        );
        native.failRead = false;
        final key = native.values.keys.single;
        native.values[key] = '{unreadable';
        await expectLater(
          storage.read(draft.key),
          throwsA(isA<WorkGatewayException>()),
        );
        await expectLater(
          storage.save(draft, expectedRevision: null),
          throwsA(isA<WorkGatewayException>()),
        );
        expect(native.values[key], '{unreadable');
        expect(native.writes, hasLength(1));
      },
    );

    test(
      'slow write serializes local instances while other shipments proceed',
      () async {
        final native = _OrderJournalStorage();
        SecureWorkReceiptDraftStore open() => SecureWorkReceiptDraftStore(
          accountScope: () => 'account-A',
          storage: native,
        );
        await open().save(_receiptDraft(), expectedRevision: null);
        final held = Completer<void>();
        native.holdWrite = held;
        final first = open().save(
          _receiptDraft(revision: 2, count: '5'),
          expectedRevision: 1,
        );
        await _drainOrderJournal();
        native.holdWrite = null;
        final second = open().save(
          _receiptDraft(revision: 3, count: '6'),
          expectedRevision: 2,
        );
        final other = _receiptDraft(shipment: 'shipment-B');
        await open().save(other, expectedRevision: null);
        expect(await open().read(other.key), isNotNull);
        expect(native.writes, hasLength(3)); // second still waits on the first
        held.complete();
        await first;
        await second;
        expect((await open().read(_receiptDraft().key))!.counted('line-A'), 6);
      },
    );

    test('native save failure retries without discarding draft', () async {
      final native = _OrderJournalStorage()..failWrite = true;
      final storage = SecureWorkReceiptDraftStore(
        accountScope: () => 'account-A',
        storage: native,
      );
      final draft = _receiptDraft(count: '8');
      await expectLater(
        storage.save(draft, expectedRevision: null),
        throwsStateError,
      );
      native.failWrite = false;
      await storage.save(draft, expectedRevision: null);
      expect((await storage.read(draft.key))!.toJson(), draft.toJson());
    });
  });
  group('DASH15 counter session', () {
    test(
      'invoice file names use saved names and safely omit phone fallback',
      () {
        WorkspaceCustomerInvoice bill({
          String seller = 'Sharma Mart',
          WorkspaceBillingDetails details = const WorkspaceBillingDetails(),
        }) => WorkspaceCustomerInvoice(
          id: 'INV-1042',
          orderId: '1042',
          sellerName: seller,
          customer: '9829012345',
          billingDetails: details,
          items: 'Grocery',
          amount: 125,
          payment: 'Cash',
          issuedAt: DateTime.utc(2026, 9, 15),
        );
        expect(bill().pdfFileName, 'Sharma-Mart_INV-1042.pdf');
        expect(
          bill(
            details: const WorkspaceBillingDetails(name: 'Rahul'),
          ).pdfFileName,
          'Sharma-Mart_Rahul_INV-1042.pdf',
        );
        expect(
          bill(
            details: const WorkspaceBillingDetails(
              business: true,
              name: 'Rahul',
              businessName: 'Gupta Traders',
            ),
          ).pdfFileName,
          'Sharma-Mart_Gupta-Traders_INV-1042.pdf',
        );
        expect(
          bill(
            details: const WorkspaceBillingDetails(
              business: true,
              name: 'Rahul',
            ),
          ).pdfFileName,
          'Sharma-Mart_Rahul_INV-1042.pdf',
        );
        expect(
          bill(
            seller: '../Sharma/ Mart:*',
            details: const WorkspaceBillingDetails(name: 'Ra\\hul\n'),
          ).pdfFileName,
          'Sharma-Mart_Ra-hul_INV-1042.pdf',
        );
        final legacy = bill().toLedgerJson()..remove('sellerName');
        expect(
          WorkspaceCustomerInvoice.fromLedgerJson(legacy).pdfFileName,
          'MoolSocial_INV-1042.pdf',
        );
        expect(
          bill(
            seller: 'दुकान',
            details: const WorkspaceBillingDetails(name: 'राहुल'),
          ).pdfFileName,
          'दुकान_राहुल_INV-1042.pdf',
        );
      },
    );

    late _CommandAccountStore account;
    late _OrderJournalStorage storage;
    late _CounterDraftBoundaryStore journal;

    setUp(() {
      account = _CommandAccountStore();
      storage = _OrderJournalStorage();
      journal = _CounterDraftBoundaryStore(
        SecureWorkCounterDraftStore(
          accountScope: () => account.accountScope,
          storage: storage,
        ),
      );
    });

    WorkSession session() {
      final work = WorkSession(
        gateway: ReviewWorkGateway(),
        contactDraftStore: account,
        counterDraftStore: journal,
      )..activeWorkspace = _commandStore;
      work.workspaceCatalogueItems.add(_product());
      work.startNewWorkspaceOrder();
      addTearDown(work.dispose);
      return work;
    }

    Future<void> fill(WorkSession work) async {
      await work.loadWorkspaceCounterDraft();
      work.adjustWorkspaceOrderQuantity('atta-5kg', 2);
      work.updateWorkspaceCounterDetails(
        customer: '9000000013',
        payment: 'Cash',
      );
      expect(await work.saveWorkspaceCounterDraft(), isTrue);
    }

    for (final kind in ['percentage', 'fixed']) {
      for (final method in ['Cash', 'UPI', 'Bank Transfer']) {
        for (final publicListing in [true, false]) {
          test(
            'COUNTERDISCOUNT $kind $method public=$publicListing exact ledger and recovery',
            () async {
              final work = session();
              work.workspaceCatalogueItems[0] = work.workspaceCatalogueItems[0]
                  .copyWith(publicListing: publicListing);
              await fill(work);
              final discount = WorkspaceBillDiscount.parse(
                kind,
                kind == 'percentage' ? '10.01' : '55.05',
              );
              expect(work.updateWorkspaceCounterDiscount(discount), isTrue);
              work.updateWorkspaceCounterDetails(payment: method);
              expect(await work.saveWorkspaceCounterDraft(), isTrue);
              expect(work.workspaceCounterSubtotalMinor, 55000);
              expect(
                work.workspaceCounterDiscountMinor,
                kind == 'percentage' ? 5506 : 5505,
              );
              final payable = 55000 - discount.amountFor(55000);
              final restored = session();
              restored.workspaceCatalogueItems[0] = restored
                  .workspaceCatalogueItems[0]
                  .copyWith(publicListing: publicListing);
              await restored.loadWorkspaceCounterDraft();
              expect(
                restored.workspaceCounterDiscount.toJson(),
                discount.toJson(),
              );
              expect(restored.workspaceCounterPayableMinor, payable);
              expect(restored.workspaceOrderPayment, method);
              final finance = WorkspaceFinanceSnapshot(
                accountScope: 'account-A',
                workspaceId: 'store-A',
                revision: 1,
                asOf: DateTime.utc(2026, 9, 19),
                salesTodayMinor: 0,
                duesMinor: 0,
                availableMinor: 0,
                heldMinor: 0,
                requestedMinor: 0,
                paidOutMinor: 0,
                feesMinor: 0,
                deliveryAdjustmentsMinor: 0,
                refundsMinor: 0,
                taxWithheldMinor: 0,
                payments: const [],
                payouts: const [],
                historyComplete: true,
              );
              expect(restored.applyWorkspaceFinance(finance), isTrue);
              expect(
                restored.bindCustomerCollectionGateway(
                  accountScope: 'account-A',
                  storeId: 'store-A',
                  adapter: StoreReviewCustomerCollectionGateway(finance),
                  checkpointStore: SecureWorkLedgerCheckpointStore(
                    accountScope: () => account.accountScope,
                    storage: storage,
                  ),
                ),
                isTrue,
              );
              final result = await restored.submitWorkspaceCounterBill();
              expect(result?.invoice, isNotNull);
              final invoice = result!.invoice!;
              final order = restored.workspaceOrders.single;
              expect(invoice.payableMinor, payable);
              expect(invoice.subtotalMinor, 55000);
              expect(invoice.discount.toJson(), discount.toJson());
              expect(
                WorkspaceCustomerInvoice.fromLedgerJson(
                  invoice.toLedgerJson(),
                ).payableMinor,
                payable,
              );
              expect(
                WorkspaceOrderRecord.fromLedgerJson(
                  order.toLedgerJson(),
                )?.payableMinor,
                payable,
              );
              expect(order.itemSnapshots.single.unitPricePaise, 27500);
              expect(order.itemSnapshots.single.lineTotalPaise, payable);
              expect(restored.workspaceCatalogueItems.single.sellingPrice, 275);
              expect(
                restored.workspaceCatalogueItems.single.publicListing,
                publicListing,
              );
              expect(
                restored.workspaceFinance!.payments.single.amountMinor,
                payable,
              );
              expect(restored.workspaceFinance!.payments.single.paidMinor, 0);
              expect(
                restored.workspaceFinance!.payments.single.dueMinor,
                payable,
              );
              expect(restored.workspaceFinance!.salesTodayMinor, payable);
              expect(
                restored.workspaceCustomerBook.single.totalSpendMinor,
                payable,
              );
              expect(
                restored.updateWorkspaceCounterDiscount(
                  const WorkspaceBillDiscount.none(),
                ),
                isFalse,
              );
              if (method == 'Cash') {
                expect(
                  await restored.recordCustomerCollection(
                    customerId: '9000000013',
                    invoiceId: invoice.id,
                    amountMinor: payable,
                    channel: WorkspacePaymentChannel.cash,
                  ),
                  isTrue,
                );
                expect(restored.workspaceFinance!.payments.single.dueMinor, 0);
              }
              final reopened = session();
              expect(reopened.applyWorkspaceFinance(finance), isTrue);
              expect(
                reopened.bindCustomerCollectionGateway(
                  accountScope: 'account-A',
                  storeId: 'store-A',
                  adapter: StoreReviewCustomerCollectionGateway(finance),
                  checkpointStore: SecureWorkLedgerCheckpointStore(
                    accountScope: () => account.accountScope,
                    storage: storage,
                  ),
                ),
                isTrue,
              );
              expect(await reopened.recoverCustomerLedger(), isTrue);
              expect(
                reopened.workspaceInvoices.single.toLedgerJson(),
                invoice.toLedgerJson(),
              );
              expect(reopened.workspaceOrders.single.payableMinor, payable);
              expect(restored.startNewWorkspaceOrder(), isTrue);
              expect(restored.workspaceCounterDiscount.isEmpty, isTrue);
            },
          );
        }
      }
    }

    test(
      'COUNTERDISCOUNT mixed-line refund allocation preserves every paise',
      () async {
        final work = session();
        await fill(work);
        work.workspaceCatalogueItems.add(
          _product(id: 'second-sku', sellingPrice: 105),
        );
        work.adjustWorkspaceOrderQuantity('second-sku', 1);
        expect(
          work.updateWorkspaceCounterDiscount(
            const WorkspaceBillDiscount.fixed(5505),
          ),
          isTrue,
        );
        final result = await work.submitWorkspaceCounterBill();
        final order = work.workspaceOrders.single;
        expect(result?.invoice?.payableMinor, 59995);
        expect(
          order.itemSnapshots.fold<int>(
            0,
            (sum, line) => sum + line.lineTotalPaise,
          ),
          59995,
        );
        expect(order.itemSnapshots.map((line) => line.unitPricePaise), [
          27500,
          10500,
        ]);
        WorkspaceCustomerReturn returned(
          String operation,
          List<WorkspaceCustomerReturnLine> lines,
        ) => WorkspaceCustomerReturn(
          accountScope: 'account-A',
          workspaceId: 'store-A',
          customerId: '9000000013',
          invoiceId: result!.invoice!.id,
          orderId: order.id,
          operationId: operation,
          expectedRevision: 1,
          reason: 'Unopened goods',
          lines: lines,
        );
        final first = returned('return-1', const [
          WorkspaceCustomerReturnLine(
            productId: 'atta-5kg',
            quantity: 1,
            restockQuantity: 1,
          ),
        ]);
        final second = returned('return-2', const [
          WorkspaceCustomerReturnLine(
            productId: 'atta-5kg',
            quantity: 1,
            restockQuantity: 1,
          ),
          WorkspaceCustomerReturnLine(
            productId: 'second-sku',
            quantity: 1,
            restockQuantity: 1,
          ),
        ]);
        final firstCredit = first.creditMinorFor(order, priorReturns: const []);
        final secondCredit = second.creditMinorFor(
          order,
          priorReturns: [first],
        );
        expect(firstCredit, isNotNull);
        expect(secondCredit, isNotNull);
        expect(firstCredit! + secondCredit!, 59995);
        expect(
          second.creditMinorFor(order, priorReturns: [first, second]),
          isNull,
        );
        final tampered = order.toLedgerJson();
        tampered['discountMinor'] = 5504;
        expect(WorkspaceOrderRecord.fromLedgerJson(tampered), isNull);
      },
    );

    test(
      'COUNTERDISCOUNT cart changes cannot submit an excessive fixed discount',
      () async {
        final work = session();
        await fill(work);
        expect(
          work.updateWorkspaceCounterDiscount(
            const WorkspaceBillDiscount.fixed(30000),
          ),
          isTrue,
        );
        work.adjustWorkspaceOrderQuantity('atta-5kg', -1);
        expect(work.workspaceCounterDiscountError, isNotNull);
        expect(await work.submitWorkspaceCounterBill(), isNull);
        expect(work.workspaceInvoices, isEmpty);
        expect(
          work.updateWorkspaceCounterDiscount(
            const WorkspaceBillDiscount.percentage(1000),
          ),
          isTrue,
        );
        expect(work.workspaceCounterPayableMinor, 24750);
        work.adjustWorkspaceOrderQuantity('atta-5kg', 1);
        expect(work.workspaceCounterPayableMinor, 49500);
        expect(
          work.updateWorkspaceCounterDiscount(
            const WorkspaceBillDiscount.none(),
          ),
          isTrue,
        );
        expect(work.workspaceCounterPayableMinor, 55000);
      },
    );

    test(
      'POSCENTRAL billing details survive recovery and stay on original invoice',
      () async {
        final work = session();
        await fill(work);
        const details = WorkspaceBillingDetails(
          business: true,
          name: 'Test contact',
          businessName: 'Test business',
          gst: 'TEST-ONLY',
          address: 'Test billing address',
        );
        work.updateWorkspaceCounterDetails(billingDetails: details);
        expect(await work.saveWorkspaceCounterDraft(), isTrue);
        final restored = session();
        await restored.loadWorkspaceCounterDraft();
        expect(
          restored.workspaceOrderBillingDetails.toJson(),
          details.toJson(),
        );
        const seller = WorkspaceStorePublicationDetails(
          legalName: 'Original legal business',
          street: '42 Market Road',
          city: 'Jaipur',
          state: 'Rajasthan',
          pinCode: '302001',
          billingAddress: 'Original billing address',
        );
        expect(restored.saveWorkspacePublicationDetails(seller), isTrue);
        final result = await restored.submitWorkspaceCounterBill();
        expect(result?.invoice, isNotNull);
        final invoice = result!.invoice!;
        expect(invoice.billingDetails.toJson(), details.toJson());
        expect(invoice.sellerName, _commandStore.name);
        expect(invoice.seller!.storeId, _commandStore.id);
        expect(invoice.seller!.legalName, seller.legalName);
        expect(invoice.seller!.storeAddress, seller.address);
        expect(invoice.seller!.billingAddress, seller.billingAddress);
        expect(
          restored.saveWorkspacePublicationDetails(
            const WorkspaceStorePublicationDetails(
              legalName: 'Changed later',
              billingAddress: 'Changed address',
            ),
          ),
          isTrue,
        );
        expect(invoice.seller!.legalName, seller.legalName);
        expect(invoice.seller!.billingAddress, seller.billingAddress);
        expect(
          WorkspaceCustomerInvoice.fromLedgerJson(
            invoice.toLedgerJson(),
          ).seller!.toJson(),
          invoice.seller!.toJson(),
        );
        expect(
          invoice.copyWith(sharedChannels: {'Chat'}).seller,
          same(invoice.seller),
        );
        final savedFileName = invoice.pdfFileName;
        expect(savedFileName, contains('_Test-business_INV-'));
        expect(savedFileName, isNot(contains(invoice.customer)));
        expect(
          invoice.copyWith(sharedChannels: {'Chat'}).pdfFileName,
          savedFileName,
        );
        expect(
          WorkspaceCustomerInvoice.fromLedgerJson(
            invoice.toLedgerJson(),
          ).pdfFileName,
          savedFileName,
        );
        expect(
          WorkspaceCustomerInvoice.fromLedgerJson(
            invoice.toLedgerJson(),
          ).billingDetails.toJson(),
          details.toJson(),
        );
        final order = restored.workspaceOrders.firstWhere(
          (o) => o.id == invoice.orderId,
        );
        expect(
          WorkspaceOrderRecord.fromLedgerJson(
            order.copyWith(stage: 'Completed').toLedgerJson(),
          )!.billingDetails.toJson(),
          details.toJson(),
        );
        expect(restored.startNewWorkspaceOrder(), isTrue);
        expect(restored.workspaceOrderBillingDetails.isEmpty, isTrue);
        expect(invoice.billingDetails.toJson(), details.toJson());
        final legacy = invoice.toLedgerJson()..remove('billingDetails');
        expect(
          WorkspaceCustomerInvoice.fromLedgerJson(
            legacy,
          ).billingDetails.isEmpty,
          isTrue,
        );
      },
    );

    for (final returnFailure in [
      'none',
      'response',
      'unknown',
      'save',
      'save-response',
      'save-response-relaunch',
    ]) {
      final loseReturnResponse =
          returnFailure == 'response' || returnFailure == 'unknown';
      test(
        'LEDGER01 counter bill connects to ledger once and later collection only reduces dues returnFailure=$returnFailure',
        () async {
          var work = session();
          await fill(work);
          final finance = WorkspaceFinanceSnapshot(
            accountScope: 'account-A',
            workspaceId: 'store-A',
            revision: 1,
            asOf: DateTime.utc(2026, 9, 11),
            salesTodayMinor: 0,
            duesMinor: 0,
            availableMinor: 70000,
            heldMinor: 0,
            requestedMinor: 0,
            paidOutMinor: 0,
            feesMinor: 0,
            deliveryAdjustmentsMinor: 0,
            refundsMinor: 0,
            taxWithheldMinor: 0,
            payments: const [],
            payouts: const [],
            historyComplete: true,
          );
          final returnAdapter = _InterruptedReturnGateway(
            finance,
            loseResponse: loseReturnResponse,
            applyReturn: returnFailure != 'unknown',
          );
          returnAdapter.afterReturnRecorded = () {
            if (returnFailure.startsWith('save-response')) {
              storage.loseWriteResponseOnce = true;
            }
          };
          expect(work.applyWorkspaceFinance(finance), isTrue);
          expect(
            work.bindCustomerCollectionGateway(
              accountScope: 'account-A',
              storeId: 'store-A',
              adapter: returnAdapter,
              checkpointStore: SecureWorkLedgerCheckpointStore(
                accountScope: () => account.accountScope,
                storage: storage,
              ),
            ),
            isTrue,
          );
          final result = await work.submitWorkspaceCounterBill();
          expect(result, isNotNull);
          final invoice = result!.invoice!;
          final movementCount = work.workspaceStockMovements.length;
          final stock = work.workspaceCatalogueItems.single.stock;
          expect(work.workspaceFinance!.salesTodayMinor, 55000);
          expect(work.workspaceFinance!.payments.single.dueMinor, 55000);
          expect(work.workspaceFinance!.availableMinor, 70000);
          expect(
            await work.recordCustomerCollection(
              customerId: '9000000013',
              invoiceId: invoice.id,
              amountMinor: 22000,
              channel: WorkspacePaymentChannel.cash,
            ),
            isTrue,
          );
          expect(work.workspaceFinance!.payments.single.dueMinor, 33000);
          expect(work.workspaceFinance!.salesTodayMinor, 55000);
          expect(await work.recordWorkspaceInvoiceInLedger(invoice), isTrue);
          expect(
            work.workspaceFinance!.customerLedgers.single.entries.where(
              (e) => e.kind == WorkspaceLedgerEntryKind.invoice,
            ),
            hasLength(1),
          );
          expect(work.workspaceStockMovements, hasLength(movementCount));
          expect(work.workspaceCatalogueItems.single.stock, stock);
          expect(work.workspaceInvoices, hasLength(1));
          WorkSession reopen({
            bool conflictingStock = false,
            WorkCustomerCollectionGateway? recoveryAdapter,
          }) {
            final recovered = session();
            if (conflictingStock) {
              recovered.workspaceCatalogueItems[0] = recovered
                  .workspaceCatalogueItems[0]
                  .copyWith(stock: 7);
            }
            expect(recovered.applyWorkspaceFinance(finance), isTrue);
            expect(
              recovered.bindCustomerCollectionGateway(
                accountScope: 'account-A',
                storeId: 'store-A',
                adapter:
                    recoveryAdapter ??
                    StoreReviewCustomerCollectionGateway(finance),
                checkpointStore: SecureWorkLedgerCheckpointStore(
                  accountScope: () => account.accountScope,
                  storage: storage,
                ),
              ),
              isTrue,
            );
            return recovered;
          }

          final recovered = reopen();
          expect(await recovered.recoverCustomerLedger(), isTrue);
          expect(
            recovered.workspaceInvoices.single.toLedgerJson(),
            invoice.toLedgerJson(),
          );
          expect(
            recovered.workspaceOrders.single.toLedgerJson(),
            work.workspaceOrders.single.toLedgerJson(),
          );
          expect(
            recovered
                .workspaceOrders
                .single
                .itemSnapshots
                .single
                .unitPricePaise,
            27500,
          );
          expect(recovered.workspaceCatalogueItems.single.stock, stock);
          final preservedJournal = SecureWorkLedgerCheckpointStore(
            accountScope: () => account.accountScope,
            storage: storage,
          );
          final savedBill = (await preservedJournal.read(
            'account-A',
            'store-A',
          ))!;
          await expectLater(
            preservedJournal.save(
              WorkspaceLedgerCheckpoint(
                revision: savedBill.revision + 1,
                finance: savedBill.finance,
                inventory: savedBill.inventory,
              ),
              expectedRevision: savedBill.revision,
            ),
            throwsA(isA<WorkGatewayException>()),
          );
          await expectLater(
            preservedJournal.save(
              WorkspaceLedgerCheckpoint(
                revision: savedBill.revision + 1,
                finance: savedBill.finance,
                inventory: savedBill.inventory,
                billedInvoices: savedBill.billedInvoices,
                billedOrders: {
                  invoice.id: savedBill.billedOrders[invoice.id]!.copyWith(
                    items: 'Changed bill',
                  ),
                },
              ),
              expectedRevision: savedBill.revision,
            ),
            throwsA(isA<WorkGatewayException>()),
          );
          expect(
            (await preservedJournal.read('account-A', 'store-A'))!.toJson(),
            savedBill.toJson(),
          );
          expect(recovered.workspaceStockMovements, hasLength(movementCount));
          expect(recovered.workspaceFinance!.payments.single.dueMinor, 33000);
          expect(await recovered.recoverCustomerLedger(), isTrue);
          expect(recovered.workspaceCatalogueItems.single.stock, stock);
          final conflict = reopen(conflictingStock: true);
          expect(await conflict.recoverCustomerLedger(), isFalse);
          expect(conflict.workspaceCatalogueItems.single.stock, 7);
          expect(conflict.customerLedgerRecoveryError, isNotNull);
          expect(
            await work.recordCustomerReturn(
              invoiceId: invoice.id,
              lines: const [
                WorkspaceCustomerReturnLine(
                  productId: 'atta-5kg',
                  quantity: 1,
                  restockQuantity: 1,
                ),
              ],
              reason: 'Stale preview',
              expectedCreditMinor: 1,
            ),
            isFalse,
          );
          expect(work.pendingCustomerReturn, isNull);
          expect(returnAdapter.submissions, 0);
          storage.failWrite = returnFailure == 'save';
          expect(
            await work.recordCustomerReturn(
              invoiceId: invoice.id,
              lines: const [
                WorkspaceCustomerReturnLine(
                  productId: 'atta-5kg',
                  quantity: 1,
                  restockQuantity: 1,
                ),
              ],
              reason: 'One unopened pack returned',
            ),
            returnFailure == 'none',
          );
          if (returnFailure.startsWith('save-response')) {
            expect(work.pendingCustomerReturn, isNotNull);
            expect(work.workspaceCatalogueItems.single.stock, stock);
            expect(work.workspaceFinance!.payments.single.dueMinor, 33000);
            if (returnFailure == 'save-response-relaunch') {
              work = reopen(recoveryAdapter: returnAdapter);
              expect(await work.recoverCustomerLedger(), isTrue);
              expect(work.pendingCustomerReturn, isNull);
            } else {
              expect(await work.reconcileCustomerReturn(), isTrue);
            }
          }
          if (returnFailure == 'save') {
            expect(returnAdapter.submissions, 0);
            expect(work.customerReturnSaved, isFalse);
            expect(work.workspaceCatalogueItems.single.stock, stock);
            expect(work.workspaceFinance!.payments.single.dueMinor, 33000);
            final pendingId = work.pendingCustomerReturn!.request.operationId;
            storage.failWrite = false;
            expect(await work.reconcileCustomerReturn(), isTrue);
            expect(returnAdapter.lastOperation, pendingId);
          }
          if (loseReturnResponse) {
            final pendingId = work.pendingCustomerReturn!.request.operationId;
            expect(work.workspaceCatalogueItems.single.stock, stock);
            expect(work.workspaceFinance!.payments.single.dueMinor, 33000);
            work = reopen(recoveryAdapter: returnAdapter);
            expect(work.workspaceOrders, isEmpty);
            expect(await work.recoverCustomerLedger(), isTrue);
            expect(work.pendingCustomerReturn!.request.operationId, pendingId);
            expect(work.pendingCustomerReturn!.originalItems, hasLength(1));
            expect(work.customerReturnSaved, isTrue);
            if (returnFailure == 'unknown') {
              expect(await work.reconcileCustomerReturn(), isFalse);
              expect(
                work.pendingCustomerReturn!.request.operationId,
                pendingId,
              );
              expect(work.workspaceCatalogueItems.single.stock, stock);
              expect(work.workspaceFinance!.payments.single.dueMinor, 33000);
              expect(returnAdapter.submissions, 1);
              return;
            }
            expect(await work.reconcileCustomerReturn(), isTrue);
            expect(returnAdapter.lastOperation, pendingId);
          }
          expect(returnAdapter.submissions, 1);

          expect(work.workspaceFinance!.payments.single.dueMinor, 5500);
          expect(work.workspaceFinance!.payments.single.paidMinor, 22000);
          expect(work.workspaceCatalogueItems.single.stock, stock + 1);
          expect(work.workspaceStockMovements, hasLength(movementCount + 1));
          expect(work.pendingCustomerReturn, isNull);
          final afterReturn = reopen();
          expect(await afterReturn.recoverCustomerLedger(), isTrue);
          expect(
            afterReturn.workspaceInvoices.single.toLedgerJson(),
            invoice.toLedgerJson(),
          );
          expect(
            afterReturn.workspaceOrders.single.hasCompleteItemSnapshot,
            isTrue,
          );
          expect(afterReturn.workspaceCatalogueItems.single.stock, stock + 1);
          expect(afterReturn.workspaceFinance!.payments.single.dueMinor, 5500);
          expect(
            afterReturn.workspaceStockMovements,
            hasLength(movementCount + 1),
          );
          if (returnFailure == 'none') {
            expect(
              await work.recordCustomerReturn(
                invoiceId: invoice.id,
                lines: const [
                  WorkspaceCustomerReturnLine(
                    productId: 'atta-5kg',
                    quantity: 1,
                    restockQuantity: 0,
                  ),
                ],
                reason: 'Remaining pack returned damaged',
              ),
              isTrue,
            );
            expect(work.workspaceFinance!.payments.single.dueMinor, 0);
            expect(
              await work.recordCustomerRefund(
                customerId: '9000000013',
                invoiceId: invoice.id,
                amountMinor: 22001,
                channel: WorkspacePaymentChannel.cash,
              ),
              isFalse,
            );
            expect(returnAdapter.refundSubmissions, 0);
            var confirmedRefunds = 0;
            for (final failure in [
              'none',
              'save',
              'pending-write-response',
              'confirmation-write-response',
              'confirmation-write-relaunch',
              'response',
              'unknown',
            ]) {
              returnAdapter.refundFailure = failure;
              storage.failWrite = failure == 'save';
              storage.loseWriteResponseOnce =
                  failure == 'pending-write-response';
              returnAdapter.afterRefundRecorded = () {
                if (failure.startsWith('confirmation-write')) {
                  storage.loseWriteResponseOnce = true;
                }
              };
              final callsBefore = returnAdapter.refundSubmissions;
              expect(
                await work.recordCustomerRefund(
                  customerId: '9000000013',
                  invoiceId: invoice.id,
                  amountMinor: 1000,
                  channel: WorkspacePaymentChannel.cash,
                ),
                failure == 'none',
              );
              if (failure != 'none') {
                final identity = work.pendingCustomerRefund!.identityData;
                expect(work.customerRefundAvailable, isFalse);
                expect(work.customerCollectionAvailable, isFalse);
                expect(
                  work.workspaceFinance!.payments.single.refundedMinor,
                  confirmedRefunds,
                );
                if (failure == 'save' || failure == 'pending-write-response') {
                  expect(work.customerRefundSaved, isFalse);
                  expect(returnAdapter.refundSubmissions, callsBefore);
                  storage.failWrite = false;
                } else if (failure != 'confirmation-write-response') {
                  work = reopen(recoveryAdapter: returnAdapter);
                  expect(await work.recoverCustomerLedger(), isTrue);
                  if (failure == 'confirmation-write-relaunch') {
                    expect(work.pendingCustomerRefund, isNull);
                    expect(
                      work.workspaceFinance!.payments.single.refundedMinor,
                      confirmedRefunds + 1000,
                    );
                  } else {
                    expect(work.pendingCustomerRefund!.identityData, identity);
                    expect(work.customerRefundSaved, isTrue);
                  }
                }
                if (failure != 'confirmation-write-relaunch') {
                  expect(
                    await work.reconcileCustomerRefund(),
                    failure != 'unknown',
                  );
                }
                expect(returnAdapter.refundSubmissions, callsBefore + 1);
                if (failure == 'unknown') {
                  expect(work.pendingCustomerRefund!.identityData, identity);
                  expect(
                    work.workspaceFinance!.payments.single.refundedMinor,
                    confirmedRefunds,
                  );
                  expect(await work.reconcileCustomerRefund(), isFalse);
                  expect(returnAdapter.refundSubmissions, callsBefore + 1);
                  break;
                }
              }
              confirmedRefunds += 1000;
              expect(work.pendingCustomerRefund, isNull);
              expect(
                work.workspaceFinance!.payments.single.refundedMinor,
                confirmedRefunds,
              );
              expect(work.workspaceFinance!.payments.single.paidMinor, 22000);
              expect(work.workspaceFinance!.availableMinor, 70000);
              expect(work.workspaceCatalogueItems.single.stock, stock + 1);
              expect(
                work.workspaceStockMovements,
                hasLength(movementCount + 1),
              );
            }
          }
        },
      );
    }

    for (final applied in [true, false]) {
      test(
        'LEDGER01 interrupted counter invoice recovery applied=$applied',
        () async {
          final work = session();
          await fill(work);
          final finance = WorkspaceFinanceSnapshot(
            accountScope: 'account-A',
            workspaceId: 'store-A',
            revision: 1,
            asOf: DateTime.utc(2026, 9, 11),
            salesTodayMinor: 0,
            duesMinor: 0,
            availableMinor: 70000,
            heldMinor: 0,
            requestedMinor: 0,
            paidOutMinor: 0,
            feesMinor: 0,
            deliveryAdjustmentsMinor: 0,
            refundsMinor: 0,
            taxWithheldMinor: 0,
            payments: const [],
            payouts: const [],
            historyComplete: true,
          );
          final adapter = _InterruptedInvoiceGateway(finance, applied: applied);
          expect(work.applyWorkspaceFinance(finance), isTrue);
          expect(
            work.bindCustomerCollectionGateway(
              accountScope: 'account-A',
              storeId: 'store-A',
              adapter: adapter,
              checkpointStore: SecureWorkLedgerCheckpointStore(
                accountScope: () => account.accountScope,
                storage: storage,
              ),
            ),
            isTrue,
          );
          expect(await work.submitWorkspaceCounterBill(), isNull);
          final invoice = work.workspaceInvoices.single;
          final stock = work.workspaceCatalogueItems.single.stock;
          final movements = work.workspaceStockMovements.length;
          expect(work.counterDraftEditingBlocked, isTrue);
          expect(await work.retryWorkspaceCounterDraft(), applied);
          expect(adapter.submissions, 1);
          expect(adapter.reconciliations, 1);
          expect(work.workspaceInvoices.single.id, invoice.id);
          expect(work.workspaceCatalogueItems.single.stock, stock);
          expect(work.workspaceStockMovements, hasLength(movements));
          expect(work.workspaceFinance!.salesTodayMinor, applied ? 55000 : 0);
          expect(work.counterDraftEditingBlocked, !applied);
          final saved = await journal.read('account-A', 'store-A');
          expect(
            saved!.stage,
            applied
                ? WorkspaceCounterDraftStage.retired
                : WorkspaceCounterDraftStage.submitting,
          );
        },
      );
    }

    test('restores exact bill in a new session without sale effects', () async {
      final first = session();
      await fill(first);
      first.updateWorkspaceCounterDetails(
        source: 'Phone',
        fulfilment: 'Own delivery',
        address: 'Test counter lane',
      );
      expect(await first.saveWorkspaceCounterDraft(), isTrue);
      final saved = (await journal.read('account-A', 'store-A'))!;
      final next = session();
      await next.loadWorkspaceCounterDraft();
      expect(next.workspaceOrderCustomer, '9000000013');
      expect(next.workspaceOrderSource, saved.source);
      expect(next.workspaceOrderFulfilment, saved.fulfilment);
      expect(next.workspaceOrderAddress, 'Test counter lane');
      expect(next.workspaceOrderQuantities, {'atta-5kg': 2});
      expect(next.workspaceOrderTotal, 550);
      expect(next.workspaceInvoices, isEmpty);
      expect(next.workspaceOrders, isEmpty);
      expect(next.workspaceCatalogueItems.single.stock, 10);
    });

    test(
      'unconfirmed phone is retained without becoming the bill customer',
      () async {
        final work = session();
        await fill(work);
        work.retainWorkspaceCounterCustomerInput('98290123456');
        expect(await work.saveWorkspaceCounterDraft(), isTrue);
        expect(work.workspaceOrderCustomer, '9000000013');
        expect(await work.submitWorkspaceCounterBill(), isNull);
        final next = session();
        await next.loadWorkspaceCounterDraft();
        expect(next.workspaceOrderCustomer, isEmpty);
        expect(next.counterCustomerInput, '98290123456');
        expect(next.workspaceOrderQuantities, {'atta-5kg': 2});
        next.updateWorkspaceCounterDetails(customer: '9829012345');
        expect(await next.saveWorkspaceCounterDraft(), isTrue);
        expect(next.counterCustomerInput, '9829012345');
        expect(next.workspaceInvoices, isEmpty);
      },
    );

    test(
      'account recovery clears composer and restores only that account bill',
      () async {
        final work = session();
        await work.recoverPendingProof(accountReady: true);
        await fill(work);
        account.accountScope = 'account-B';
        await work.recoverPendingProof(accountReady: true);
        expect(work.activeWorkspace, isNull);
        expect(work.workspaceOrderQuantities, isEmpty);
        expect(work.workspaceOrderCustomer, isEmpty);
        work.activeWorkspace = _commandStore;
        work.workspaceCatalogueItems.add(_product());
        await work.loadWorkspaceCounterDraft(retry: true);
        expect(work.retainedCounterDraft, isNull);
        expect(work.workspaceOrderCustomer, isEmpty);
        account.accountScope = 'account-A';
        await work.recoverPendingProof(accountReady: true);
        work.activeWorkspace = _commandStore;
        work.workspaceCatalogueItems.add(_product());
        await work.loadWorkspaceCounterDraft(retry: true);
        expect(work.workspaceOrderCustomer, '9000000013');
        expect(work.workspaceOrderQuantities, {'atta-5kg': 2});
        expect(work.workspaceInvoices, isEmpty);
      },
    );

    test(
      'price changes before effects recover without duplicating a sale',
      () async {
        final work = session();
        await fill(work);
        journal.submitGate = Completer<void>();
        final submission = work.submitWorkspaceCounterBill();
        await _drainOrderJournal();
        work.workspaceCatalogueItems[0] = _product(sellingPrice: 300);
        journal.submitGate!.complete();
        expect(await submission, isNull);
        expect(work.workspaceInvoices, isEmpty);
        expect(work.workspaceOrders, isEmpty);
        expect(work.workspaceCatalogueItems.single.stock, 10);
        expect(await work.retryWorkspaceCounterDraft(), isTrue);
        expect(work.counterDraftNeedsReconciliation, isFalse);
        expect(work.workspaceOrderQuantities, {'atta-5kg': 2});
        expect(work.workspaceOrderTotal, 600);
        expect(await work.submitWorkspaceCounterBill(), isNotNull);
        expect(work.workspaceInvoices, hasLength(1));
        expect(work.workspaceCatalogueItems.single.stock, 8);
      },
    );

    test(
      'next bill has a new identity and cannot resurrect a completed bill',
      () async {
        final work = session();
        await fill(work);
        final first = await work.submitWorkspaceCounterBill();
        expect(first, isNotNull);
        expect(work.startNewWorkspaceOrder(), isTrue);
        expect(work.counterCustomerInput, isNull);
        await fill(work);
        work.updateWorkspaceCounterDetails(customer: '9000000014');
        final second = await work.submitWorkspaceCounterBill();
        expect(second, isNotNull);
        expect(second!.orderId, isNot(first!.orderId));
        expect(work.workspaceInvoices, hasLength(2));
        expect(work.workspaceCatalogueItems.single.stock, 6);
        final next = session();
        await next.loadWorkspaceCounterDraft();
        expect(next.workspaceOrderCustomer, isEmpty);
        expect(next.workspaceOrderQuantities, isEmpty);
      },
    );

    test('lost marker reply recovers once without claiming a sale', () async {
      final work = session();
      await fill(work);
      journal.failAfterSubmit = true;
      expect(await work.submitWorkspaceCounterBill(), isNull);
      expect(work.workspaceInvoices, isEmpty);
      expect(work.workspaceOrders, isEmpty);
      expect(
        (await journal.read('account-A', 'store-A'))!.stage,
        WorkspaceCounterDraftStage.submitting,
      );
      journal.failAfterSubmit = false;
      expect(await work.retryWorkspaceCounterDraft(), isTrue);
      expect(
        (await journal.read('account-A', 'store-A'))!.stage,
        WorkspaceCounterDraftStage.reviewRequired,
      );
      final next = session();
      await next.loadWorkspaceCounterDraft();
      expect(next.workspaceOrderQuantities, {'atta-5kg': 2});
      expect(next.workspaceOrderCustomer, '9000000013');
      expect(next.counterDraftNeedsReconciliation, isFalse);
      expect(next.workspaceInvoices, isEmpty);
    });

    test(
      'reviewed price cannot change while the draft write is pending',
      () async {
        final work = session();
        await fill(work);
        final reviewed = work.counterBillReviewSignature;
        storage.holdWrite = Completer<void>();
        final submission = work.submitWorkspaceCounterBill(
          expectedReview: reviewed,
        );
        await _drainOrderJournal();
        work.workspaceCatalogueItems[0] = _product(sellingPrice: 301);
        storage.holdWrite!.complete();
        expect(await submission, isNull);
        expect(work.workspaceInvoices, isEmpty);
        expect(work.workspaceOrders, isEmpty);
        expect(
          work.counterDraftError,
          'Bill updated. Review the items and total.',
        );
        expect(
          await work.submitWorkspaceCounterBill(expectedReview: reviewed),
          isNull,
        );
        expect(
          await work.submitWorkspaceCounterBill(
            expectedReview: work.counterBillReviewSignature,
          ),
          isNotNull,
        );
        expect(work.workspaceInvoices, hasLength(1));
      },
    );

    test('failed save retry keeps latest incomplete customer input', () async {
      final work = session();
      await fill(work);
      storage.failWrite = true;
      work.updateWorkspaceCounterDetails(customer: '9000');
      expect(await work.saveWorkspaceCounterDraft(), isFalse);
      expect(work.counterDraftError, isNotNull);
      storage.failWrite = false;
      expect(await work.retryWorkspaceCounterDraft(), isTrue);
      expect(work.workspaceOrderCustomer, '9000');
      expect((await journal.read('account-A', 'store-A'))!.customer, '9000');
      expect(await work.submitWorkspaceCounterBill(), isNull);
      expect(work.workspaceInvoices, isEmpty);
    });

    test(
      'failed read cannot overwrite a saved bill with an empty draft',
      () async {
        await fill(session());
        final original = Map<String, String>.from(storage.values);
        storage.failRead = true;
        final work = session();
        await work.loadWorkspaceCounterDraft();
        expect(work.counterDraftEditingBlocked, isTrue);
        expect(await work.saveWorkspaceCounterDraft(), isFalse);
        expect(storage.values, original);
        storage.failRead = false;
        expect(await work.retryWorkspaceCounterDraft(), isTrue);
        expect(work.workspaceOrderQuantities, {'atta-5kg': 2});
      },
    );

    test(
      'late restore does not change another Store or closed editor',
      () async {
        await fill(session());
        journal.readGate = Completer<void>();
        final work = session();
        final loading = work.loadWorkspaceCounterDraft();
        await _drainOrderJournal();
        work.activeWorkspace = const WorkWorkspace(
          id: 'store-B',
          name: 'Store B',
          profileLabel: 'Grocery / Kirana Shop',
          profileId: 'retailer-grocery',
          area: 'Jodhpur',
          verified: true,
        );
        journal.readGate!.complete();
        await loading;
        expect(work.workspaceOrderCustomer, isEmpty);
        expect(work.workspaceOrderQuantities, isEmpty);
        final closed = session();
        await closed.loadWorkspaceCounterDraft(shouldRestore: () => false);
        expect(closed.workspaceOrderQuantities, isEmpty);
        expect(closed.retainedCounterDraft!.lines.single.quantity, 2);
      },
    );

    test(
      'missing catalogue keeps original bill readonly until discard',
      () async {
        await fill(session());
        final work = session();
        work.workspaceCatalogueItems.clear();
        await work.loadWorkspaceCounterDraft();
        expect(work.counterDraftCatalogueChanged, isTrue);
        expect(work.counterDraftEditingBlocked, isTrue);
        expect(work.retainedCounterDraft!.lines.single.lineTotalPaise, 55000);
        expect(await work.submitWorkspaceCounterBill(), isNull);
        expect(await work.discardWorkspaceCounterDraft(), isTrue);
        expect(
          (await journal.read('account-A', 'store-A'))!.stage,
          WorkspaceCounterDraftStage.retired,
        );
        expect(work.workspaceInvoices, isEmpty);
      },
    );

    test(
      'submission marker precedes effects and blocks duplicate taps',
      () async {
        final work = session();
        await fill(work);
        journal.submitGate = Completer<void>();
        final submitting = work.submitWorkspaceCounterBill();
        await _drainOrderJournal();
        expect(work.counterDraftSubmitting, isTrue);
        expect(work.workspaceInvoices, isEmpty);
        expect(work.workspaceCatalogueItems.single.stock, 10);
        expect(await work.submitWorkspaceCounterBill(), isNull);
        work.adjustWorkspaceOrderQuantity('atta-5kg', 1);
        expect(work.workspaceOrderQuantities, {'atta-5kg': 2});
        journal.submitGate!.complete();
        final result = await submitting;
        expect(result, isNotNull);
        expect(work.workspaceInvoices, hasLength(1));
        expect(work.workspaceCompletedSalesCount, 1);
        expect(work.workspaceCatalogueItems.single.stock, 8);
        final record = (await journal.read('account-A', 'store-A'))!;
        expect(record.stage, WorkspaceCounterDraftStage.retired);
        expect(record.submissionOrderId, result!.orderId);
        final next = session();
        await next.loadWorkspaceCounterDraft();
        expect(next.workspaceOrderQuantities, isEmpty);
      },
    );

    test(
      'retirement retry never repeats invoice sale or stock effects',
      () async {
        final work = session();
        await fill(work);
        journal.failRetire = true;
        expect(await work.submitWorkspaceCounterBill(), isNull);
        expect(work.counterDraftNeedsReconciliation, isTrue);
        expect(work.workspaceInvoices, hasLength(1));
        final invoiceId = work.workspaceInvoices.single.id;
        expect(await work.submitWorkspaceCounterBill(), isNull);
        journal.failRetire = false;
        expect(await work.retryWorkspaceCounterDraft(), isTrue);
        expect(work.workspaceInvoices.single.id, invoiceId);
        expect(work.workspaceCompletedSalesCount, 1);
        expect(work.workspaceCatalogueItems.single.stock, 8);
        expect(work.counterDraftNeedsReconciliation, isFalse);
      },
    );

    test(
      'cold interrupted submission cannot claim completion or recreate sale',
      () async {
        final first = session();
        await fill(first);
        journal.failRetire = true;
        await first.submitWorkspaceCounterBill();
        final next = session();
        await next.loadWorkspaceCounterDraft();
        expect(next.counterDraftNeedsReconciliation, isTrue);
        expect(await next.retryWorkspaceCounterDraft(), isFalse);
        expect(await next.submitWorkspaceCounterBill(), isNull);
        expect(await next.discardWorkspaceCounterDraft(), isFalse);
        expect(next.workspaceInvoices, isEmpty);
        expect(next.workspaceCatalogueItems.single.stock, 10);
      },
    );
  });

  group('DASH15 counter draft journal', () {
    WorkspaceCounterDraft draft({
      String account = 'account-A',
      String store = 'store-A',
      String id = 'bill-A',
      int revision = 1,
      WorkspaceCounterDraftStage stage = WorkspaceCounterDraftStage.editing,
      String? order,
      String customer = '9000000013',
      List<WorkspaceOrderItemSnapshot>? lines,
    }) => WorkspaceCounterDraft(
      account: account,
      store: store,
      id: id,
      revision: revision,
      stage: stage,
      customer: customer,
      source: 'Counter',
      fulfilment: 'At the shop',
      payment: 'Cash',
      address: 'दुकान के पास',
      submissionOrderId: order,
      lines:
          lines ??
          const [
            WorkspaceOrderItemSnapshot(
              productId: 'atta-5kg',
              name: 'आटा',
              pack: '5 kg',
              quantity: 2,
              unitPricePaise: 27500,
              lineTotalPaise: 55000,
            ),
          ],
    );

    test(
      'review-required recovery preserves the aborted snapshot through restart',
      () async {
        final storage = _OrderJournalStorage();
        final journal = SecureWorkCounterDraftStore(
          accountScope: () => 'account-A',
          storage: storage,
        );
        await journal.save(draft(), expectedRevision: null);
        await expectLater(
          journal.save(
            draft(
              revision: 2,
              stage: WorkspaceCounterDraftStage.reviewRequired,
              order: 'order-A',
            ),
            expectedRevision: 1,
          ),
          throwsA(isA<WorkGatewayException>()),
        );
        await journal.save(
          draft(
            revision: 2,
            stage: WorkspaceCounterDraftStage.submitting,
            order: 'order-A',
          ),
          expectedRevision: 1,
        );
        await expectLater(
          journal.save(
            draft(
              revision: 3,
              stage: WorkspaceCounterDraftStage.reviewRequired,
              order: 'order-A',
              customer: '9000000014',
            ),
            expectedRevision: 2,
          ),
          throwsA(isA<WorkGatewayException>()),
        );
        final review = draft(
          revision: 3,
          stage: WorkspaceCounterDraftStage.reviewRequired,
          order: 'order-A',
        );
        await journal.save(review, expectedRevision: 2);
        final restarted = SecureWorkCounterDraftStore(
          accountScope: () => 'account-A',
          storage: storage,
        );
        expect(
          (await restarted.read('account-A', 'store-A'))!.toJson(),
          review.toJson(),
        );
        await expectLater(
          restarted.save(
            draft(
              revision: 4,
              stage: WorkspaceCounterDraftStage.submitting,
              order: 'order-B',
            ),
            expectedRevision: 3,
          ),
          throwsA(isA<WorkGatewayException>()),
        );
        await restarted.save(draft(revision: 4), expectedRevision: 3);
        expect(
          (await restarted.read('account-A', 'store-A'))!.submissionOrderId,
          isNull,
        );
      },
    );

    for (final method in ['Cash', 'UPI', 'Bank Transfer']) {
      test('COUNTER1919 restores $method without payment authority', () async {
        final storage = _OrderJournalStorage();
        final selected = WorkspaceCounterDraft.fromJson({
          ...draft().toJson(),
          'payment': method,
        });
        expect(selected, isNotNull);
        expect(selected!.valid, isTrue);
        final first = SecureWorkCounterDraftStore(
          accountScope: () => 'account-A',
          storage: storage,
        );
        await first.save(selected, expectedRevision: null);
        final restarted = SecureWorkCounterDraftStore(
          accountScope: () => 'account-A',
          storage: storage,
        );
        final restored = (await restarted.read('account-A', 'store-A'))!;
        expect(restored.payment, method);
        expect(restored.toJson(), selected.toJson());
        expect(restored.stage, WorkspaceCounterDraftStage.editing);
        expect(restored.submissionOrderId, isNull);
      });
    }

    test(
      'CS016 incomplete phone retains billing owner across storage restart',
      () async {
        final source = draft().toJson();
        final legacy = Map<String, Object?>.from(source)
          ..remove('billingCustomer');
        expect(WorkspaceCounterDraft.fromJson(legacy), isNotNull);
        final pending = WorkspaceCounterDraft.fromJson({
          ...source,
          'customer': '900009163',
          'billingCustomer': '9000091630',
          'billingDetails': const WorkspaceBillingDetails(
            name: 'Customer A',
            business: true,
            businessName: 'A Grocery',
            gst: '08ABCDE1234F1Z5',
            address: '12 Market Road',
          ).toJson(),
        });
        expect(pending, isNotNull);
        final storage = _OrderJournalStorage();
        final first = SecureWorkCounterDraftStore(
          accountScope: () => 'account-A',
          storage: storage,
        );
        await first.save(pending!, expectedRevision: null);
        final restarted = SecureWorkCounterDraftStore(
          accountScope: () => 'account-A',
          storage: storage,
        );
        final restored = (await restarted.read('account-A', 'store-A'))!;
        expect(restored.customer, '900009163');
        expect(restored.billingCustomer, '9000091630');
        expect(
          restored.billingDetails.toJson(),
          pending.billingDetails.toJson(),
        );
        for (final invalid in [false, 123, '900009163', 'not a phone']) {
          expect(
            WorkspaceCounterDraft.fromJson({
              ...source,
              'billingCustomer': invalid,
            }),
            isNull,
          );
        }
      },
    );

    test('retains exact snapshot through a new storage instance', () async {
      final storage = _OrderJournalStorage();
      final first = SecureWorkCounterDraftStore(
        accountScope: () => 'account-A',
        storage: storage,
      );
      await first.save(draft(), expectedRevision: null);
      final restarted = SecureWorkCounterDraftStore(
        accountScope: () => 'account-A',
        storage: storage,
      );
      final restored = (await restarted.read('account-A', 'store-A'))!;
      expect(restored.toJson(), draft().toJson());
      expect(restored.stage, WorkspaceCounterDraftStage.editing);
      expect(restored.submissionOrderId, isNull);
      expect(restored.lines.single.lineTotalPaise, 55000);
      expect(() => restored.lines.clear(), throwsUnsupportedError);
      expect(
        storage.values.keys.single,
        startsWith('moolsocial.workspace.counter-draft.v1.'),
      );
    });

    test('isolates account Store and encoded path separators', () async {
      final storage = _OrderJournalStorage();
      var account = 'account/A';
      final journal = SecureWorkCounterDraftStore(
        accountScope: () => account,
        storage: storage,
      );
      await journal.save(
        draft(account: account, store: 'B'),
        expectedRevision: null,
      );
      account = 'account';
      expect(await journal.read(account, 'A/B'), isNull);
      await journal.save(
        draft(account: account, store: 'A/B'),
        expectedRevision: null,
      );
      expect(storage.values, hasLength(2));
      await expectLater(
        journal.read('account/A', 'B'),
        throwsA(isA<WorkGatewayException>()),
      );
      expect(await journal.read(account, 'another-store'), isNull);
      await expectLater(
        journal.save(draft(), expectedRevision: null),
        throwsA(isA<WorkGatewayException>()),
      );
      expect(storage.writes, hasLength(2));
    });

    test(
      'rejects corrupted schema money quantities and collection purpose',
      () {
        final invalid = <Map<String, Object?>>[
          {...draft().toJson(), 'version': 2},
          {...draft().toJson(), 'purpose': 'customer-collection'},
          {...draft().toJson(), 'stage': 'paid'},
          {...draft().toJson(), 'source': 'App'},
          {...draft().toJson(), 'revision': 0},
          {...draft().toJson(), 'revision': '1'},
          {...draft().toJson(), 'stage': 'submitting'},
          {...draft().toJson(), 'submissionOrderId': 'ORDER-A'},
        ];
        final line = ((draft().toJson()['lines'] as List).single as Map)
            .cast<String, Object?>();
        for (final changed in [
          {...line, 'quantity': 0},
          {...line, 'quantity': -1},
          {...line, 'quantity': 1.5},
          {...line, 'unitPricePaise': '27500'},
          {...line, 'unitPricePaise': -1},
          {...line, 'lineTotalPaise': 1},
          {
            ...line,
            'quantity': 3,
            'unitPricePaise': 9223372036854775807,
            'lineTotalPaise': 9223372036854775805,
          },
          {...line, 'productId': ''},
          {...line, 'name': ''},
          {...line, 'pack': ''},
        ]) {
          invalid.add({
            ...draft().toJson(),
            'lines': [changed],
          });
        }
        invalid.add({
          ...draft().toJson(),
          'lines': [line, line],
        });
        for (final value in invalid) {
          expect(
            WorkspaceCounterDraft.fromJson(value),
            isNull,
            reason: jsonEncode(value),
          );
        }
      },
    );

    test('retains every selected line and large integer amounts', () async {
      final storage = _OrderJournalStorage();
      final journal = SecureWorkCounterDraftStore(
        accountScope: () => 'account-A',
        storage: storage,
      );
      final large = draft(
        lines: List.generate(
          1200,
          (index) => WorkspaceOrderItemSnapshot(
            productId: 'SKU-$index',
            name: 'Product $index',
            pack: 'Case',
            quantity: 2,
            unitPricePaise: 1000000000000,
            lineTotalPaise: 2000000000000,
          ),
        ),
      );
      await journal.save(large, expectedRevision: null);
      final restored = (await journal.read('account-A', 'store-A'))!;
      expect(restored.lines, hasLength(1200));
      expect(restored.toJson(), large.toJson());
    });

    test(
      'serializes writers and rejects stale edits after retirement',
      () async {
        final storage = _OrderJournalStorage();
        final journal = SecureWorkCounterDraftStore(
          accountScope: () => 'account-A',
          storage: storage,
        );
        final other = SecureWorkCounterDraftStore(
          accountScope: () => 'account-A',
          storage: storage,
        );
        await journal.save(draft(), expectedRevision: null);
        storage.holdWrite = Completer<void>();
        final edit = journal.save(
          draft(revision: 2, customer: '9000000014'),
          expectedRevision: 1,
        );
        await _drainOrderJournal();
        final retire = other.save(
          draft(revision: 3, stage: WorkspaceCounterDraftStage.retired),
          expectedRevision: 2,
        );
        final stale = expectLater(
          other.save(draft(revision: 2), expectedRevision: 1),
          throwsA(isA<WorkGatewayException>()),
        );
        expect(storage.writes, hasLength(2));
        storage.holdWrite!.complete();
        await edit;
        await retire;
        await stale;
        final restored = (await other.read('account-A', 'store-A'))!;
        expect(restored.stage, WorkspaceCounterDraftStage.retired);
        expect(restored.revision, 3);
        expect(storage.writes, hasLength(3));
        await expectLater(
          journal.save(draft(revision: 4), expectedRevision: 3),
          throwsA(isA<WorkGatewayException>()),
        );
        await journal.save(
          draft(id: 'bill-B', revision: 4),
          expectedRevision: 3,
        );
        expect((await journal.read('account-A', 'store-A'))!.id, 'bill-B');
      },
    );

    test('interrupted submission cannot reopen or change its order', () async {
      final storage = _OrderJournalStorage();
      final journal = SecureWorkCounterDraftStore(
        accountScope: () => 'account-A',
        storage: storage,
      );
      await journal.save(draft(), expectedRevision: null);
      final submitted = draft(
        revision: 2,
        stage: WorkspaceCounterDraftStage.submitting,
        order: 'ORDER-A',
      );
      await journal.save(submitted, expectedRevision: 1);
      final restarted = SecureWorkCounterDraftStore(
        accountScope: () => 'account-A',
        storage: storage,
      );
      expect(
        (await restarted.read('account-A', 'store-A'))!.toJson(),
        submitted.toJson(),
      );
      await restarted.save(submitted, expectedRevision: 1);
      expect(storage.writes, hasLength(2));
      for (final changed in [
        draft(revision: 3),
        draft(id: 'new-bill', revision: 3),
        draft(
          revision: 3,
          stage: WorkspaceCounterDraftStage.submitting,
          order: 'ORDER-B',
        ),
        draft(
          revision: 3,
          stage: WorkspaceCounterDraftStage.retired,
          order: 'ORDER-B',
        ),
      ]) {
        await expectLater(
          restarted.save(changed, expectedRevision: 2),
          throwsA(isA<WorkGatewayException>()),
        );
      }
      await restarted.save(
        draft(
          revision: 3,
          stage: WorkspaceCounterDraftStage.retired,
          order: 'ORDER-A',
        ),
        expectedRevision: 2,
      );
      expect(
        (await restarted.read('account-A', 'store-A'))!.stage,
        WorkspaceCounterDraftStage.retired,
      );
    });

    test('failed reads and writes preserve the previous checkpoint', () async {
      final storage = _OrderJournalStorage();
      final journal = SecureWorkCounterDraftStore(
        accountScope: () => 'account-A',
        storage: storage,
      );
      await journal.save(draft(), expectedRevision: null);
      final before = Map<String, String>.from(storage.values);
      storage.failRead = true;
      await expectLater(
        journal.save(draft(revision: 2), expectedRevision: 1),
        throwsStateError,
      );
      expect(storage.writes, hasLength(1));
      storage.failRead = false;
      storage.failWrite = true;
      await expectLater(
        journal.save(draft(revision: 2), expectedRevision: 1),
        throwsStateError,
      );
      expect(storage.values, before);
      storage.failWrite = false;
      await journal.save(draft(revision: 2), expectedRevision: 1);
      expect((await journal.read('account-A', 'store-A'))!.revision, 2);
    });

    test('malformed or cross Store stored data is never overwritten', () async {
      final storage = _OrderJournalStorage();
      final journal = SecureWorkCounterDraftStore(
        accountScope: () => 'account-A',
        storage: storage,
      );
      await journal.save(draft(), expectedRevision: null);
      for (final invalid in [
        '{invalid',
        jsonEncode(draft(store: 'other').toJson()),
      ]) {
        storage.values[storage.values.keys.single] = invalid;
        await expectLater(
          journal.read('account-A', 'store-A'),
          throwsA(isA<WorkGatewayException>()),
        );
        await expectLater(
          journal.save(draft(revision: 2), expectedRevision: 1),
          throwsA(isA<WorkGatewayException>()),
        );
        expect(storage.values.values.single, invalid);
      }
      expect(storage.writes, hasLength(1));
    });

    test(
      'account changes during write do not leak another account draft',
      () async {
        final storage = _OrderJournalStorage()..holdWrite = Completer<void>();
        var account = 'account-A';
        final journal = SecureWorkCounterDraftStore(
          accountScope: () => account,
          storage: storage,
        );
        final writing = expectLater(
          journal.save(draft(), expectedRevision: null),
          throwsA(isA<WorkGatewayException>()),
        );
        await _drainOrderJournal();
        account = 'account-B';
        storage.holdWrite!.complete();
        await writing;
        expect(await journal.read(account, 'store-A'), isNull);
        await expectLater(
          journal.read('account-A', 'store-A'),
          throwsA(isA<WorkGatewayException>()),
        );
        account = 'account-A';
        expect(
          (await journal.read(account, 'store-A'))!.toJson(),
          draft().toJson(),
        );
      },
    );
  });

  test(
    'DASH11 supplier roles exclude retailer consumer and ambiguous names',
    () {
      for (final role in WorkspaceStockSupplierType.values) {
        expect(WorkspaceStockSupplierType.fromRole(role.name), role);
      }
      for (final role in [
        'retailer',
        'consumer',
        'shop',
        'unknown',
        'Manufacturer retailer',
        '',
      ]) {
        expect(WorkspaceStockSupplierType.fromRole(role), isNull);
      }
    },
  );

  test(
    'DASH11 immutable group facts keep Store amounts separate and unknown honest',
    () {
      final record = _groupOffer('one');
      expect(record.valid, isTrue);
      expect(record.details.securedQuantity, 300);
      expect(record.participation.quantity, 10);
      expect(record.participation.savingMinor, 3500);
      expect(
        () => record.details.confirmedRetailers.add('bad'),
        throwsUnsupportedError,
      );
      expect(() => record.details.participants.clear(), throwsUnsupportedError);
      expect(
        const WorkspaceGroupParticipation(
          state: WorkspaceGroupParticipationState.unknown,
        ).savingMinor,
        isNull,
      );
      expect(
        const WorkspaceGroupParticipation(
          state: WorkspaceGroupParticipationState.paid,
          quantity: 10,
          totalMinor: 100,
          paidMinor: 50,
          dueMinor: 50,
        ).valid,
        isFalse,
      );
      expect(
        const WorkspaceGroupParticipation(
          state: WorkspaceGroupParticipationState.pending,
          goodsMinor: 100,
          tradeFeeMinor: 10,
          deliveryMinor: 0,
          taxMinor: 0,
          totalMinor: 100,
        ).valid,
        isFalse,
      );
      expect(_groupOffer('hidden', published: false).valid, isFalse);
    },
  );

  test(
    'DASH11 four offers preserve selection scope revisions and no trade effects',
    () {
      final account = _CommandAccountStore();
      final work = WorkSession(contactDraftStore: account)
        ..activeWorkspace = const WorkWorkspace(
          id: 'group-store',
          name: 'Store A',
          profileLabel: 'Grocery',
          profileId: 'retailer-grocery',
          area: 'Market',
          verified: true,
        );
      addTearDown(work.dispose);
      bool apply(
        int revision,
        List<WorkspaceGroupOffer> records, {
        bool complete = true,
      }) => work.applyWorkspaceGroupOffers(
        accountScope: 'account-A',
        storeId: 'group-store',
        feedRevision: revision,
        records: records,
        complete: complete,
      );
      final records = [
        for (final id in ['A', 'B', 'C', 'D']) _groupOffer(id),
      ];
      expect(apply(1, records), isTrue);
      expect(
        work.selectWorkspaceGroupOffer(
          'B',
          accountScope: 'account-A',
          storeId: 'group-store',
        ),
        isTrue,
      );
      expect(
        apply(2, [
          records[3],
          records[2],
          _groupOffer(
            'B',
            revision: 2,
            stage: WorkspaceGroupOfferStage.dispatched,
          ),
          records[0],
        ]),
        isTrue,
      );
      expect(work.workspaceGroupOffers.map((r) => r.id), ['A', 'B', 'C', 'D']);
      expect(work.selectedWorkspaceGroupOfferId, 'B');
      expect(
        work.selectedWorkspaceGroupOffer!.stage,
        WorkspaceGroupOfferStage.dispatched,
      );
      expect(
        work.selectedWorkspaceGroupOffer!.participation.state,
        WorkspaceGroupParticipationState.balanceDue,
      );
      expect(apply(2, records), isFalse);
      expect(apply(3, [_groupOffer('B', account: 'other')]), isFalse);
      expect(apply(3, [_groupOffer('B', store: 'other')]), isFalse);
      expect(
        apply(3, [_groupOffer('B', supplier: 'different', revision: 3)]),
        isFalse,
      );
      expect(
        apply(3, [
          _groupOffer(
            'B',
            revision: 3,
            supplierType: WorkspaceStockSupplierType.manufacturer,
          ),
        ]),
        isFalse,
      );
      expect(apply(3, [records[0], records[0]]), isFalse);
      expect(work.workspaceGroupOffers.length, 4);
      expect(apply(3, [records[0], records[2], records[3]]), isTrue);
      expect(work.selectedWorkspaceGroupOfferId, 'B');
      expect(work.selectedWorkspaceGroupOffer, isNull);
      expect(work.activeGroupBuy, isNull);
      expect(
        apply(4, [_groupOffer('B', revision: 2)], complete: false),
        isTrue,
      );
      expect(work.selectedWorkspaceGroupOffer, isNull);
      expect(
        apply(5, [_groupOffer('B', revision: 3)], complete: false),
        isTrue,
      );
      expect(work.selectedWorkspaceGroupOffer!.revision, 3);
      work.markWorkspaceGroupOffersStale(
        accountScope: 'account-A',
        storeId: 'group-store',
      );
      expect(work.workspaceGroupOffersStale, isTrue);
      expect(apply(5, records), isFalse);
      expect(work.workspaceGroupOffersStale, isTrue);
      expect(
        apply(6, [_groupOffer('B', revision: 4)], complete: false),
        isTrue,
      );
      expect(work.workspaceGroupOffersStale, isFalse);
      expect(work.workspaceInvoices, isEmpty);
      expect(work.workspaceOrders, isEmpty);
      expect(work.workspaceStockMovements, isEmpty);
      expect(work.workspaceActivity, isEmpty);
      account.accountScope = 'account-B';
      expect(work.workspaceGroupOffers, isEmpty);
      expect(work.selectedWorkspaceGroupOffer, isNull);
      expect(apply(7, records), isFalse);
      expect(
        work.applyWorkspaceGroupOffers(
          accountScope: 'account-B',
          storeId: 'group-store',
          feedRevision: 1,
          records: [
            _groupOffer('A', account: 'account-B'),
            _groupOffer('B', account: 'account-B'),
          ],
          complete: true,
        ),
        isTrue,
      );
      expect(
        work.selectWorkspaceGroupOffer(
          'B',
          accountScope: 'account-A',
          storeId: 'group-store',
        ),
        isFalse,
      );
      expect(work.selectedWorkspaceGroupOfferId, 'A');
      expect(
        work.selectWorkspaceGroupOffer(
          'B',
          accountScope: 'account-B',
          storeId: 'another-store',
        ),
        isFalse,
      );
      expect(work.selectedWorkspaceGroupOfferId, 'A');
      expect(
        work.selectWorkspaceGroupOffer(
          'B',
          accountScope: 'account-B',
          storeId: 'group-store',
        ),
        isTrue,
      );
      expect(work.selectedWorkspaceGroupOfferId, 'B');
    },
  );
  test(
    'DASH10 local stock changes are not truncated after one hundred',
    () async {
      final work = WorkSession()..seedVerifiedWorkspace();
      addTearDown(work.dispose);
      work.addOrUpdateWorkspaceProduct(_product(stock: 1000));
      final first = work.workspaceStockMovements.single;
      for (var i = 1; i <= 1000; i++) {
        expect(
          work.updateWorkspaceStock(
            productId: 'atta-5kg',
            quantity: 1000 + i,
            reason: 'Recorded stock count $i',
          ),
          isTrue,
        );
      }
      expect(work.workspaceStockMovements.length, 1001);
      expect(work.workspaceStockMovements.last.id, first.id);
      expect(
        work.workspaceStockMovements.map((row) => row.id).toSet().length,
        1001,
      );
      expect(
        work.workspaceCatalogueItems
            .singleWhere((item) => item.id == 'atta-5kg')
            .stock,
        2000,
      );
      expect(work.workspaceStockMovements.every((row) => row.valid), isTrue);
      await _drainOrderJournal();
    },
  );

  test(
    'DASH10 stock history pages stay scoped ordered and read-only across ten thousand records',
    () async {
      final gateway = _StockHistoryGateway(
        List.generate(10000, _historyMovement),
      );
      final work = WorkSession(
        pendingProofStore: _CommandAccountStore(),
        stockHistoryGateway: gateway,
      )..activeWorkspace = _commandStore;
      addTearDown(work.dispose);
      work.workspaceCatalogueItems.add(_product());
      final query = work.workspaceStockHistoryScope()!;
      expect(await work.loadWorkspaceStockHistory(query), isTrue);
      expect(work.workspaceStockHistory.length, 50);
      expect(work.workspaceStockHistoryTotal, 10000);
      while (work.workspaceStockHistoryHasMore) {
        expect(await work.loadWorkspaceStockHistory(query, more: true), isTrue);
      }
      expect(work.workspaceStockHistory.length, 10000);
      expect(
        work.workspaceStockHistory.map((row) => row.id).toSet().length,
        10000,
      );
      expect(work.workspaceStockHistory.last.id, 'movement-09999');
      expect(gateway.requests.length, 200);
      expect(
        gateway.requests
            .skip(1)
            .every((request) => request.snapshot == 'snapshot-1'),
        isTrue,
      );
      expect(work.workspaceCatalogueItems.single.stock, 10);
      expect(work.workspaceStockMovements, isEmpty);
      expect(work.workspaceInvoices, isEmpty);
      expect(await work.loadWorkspaceStockHistory(query, more: true), isFalse);
      expect(gateway.requests.length, 200);
    },
  );

  test(
    'DASH10 bad snapshots duplicate pages cursor loops and wrong scope fail closed',
    () async {
      for (final invalid in [
        'snapshot',
        'duplicate',
        'cursor',
        'loop',
        'scope',
        'total',
        'order',
      ]) {
        final gateway = _StockHistoryGateway(
          List.generate(151, _historyMovement),
        );
        final work = WorkSession(
          pendingProofStore: _CommandAccountStore(),
          stockHistoryGateway: gateway,
        )..activeWorkspace = _commandStore;
        addTearDown(work.dispose);
        final query = work.workspaceStockHistoryScope()!;
        expect(await work.loadWorkspaceStockHistory(query), isTrue);
        expect(await work.loadWorkspaceStockHistory(query, more: true), isTrue);
        gateway.respond = (request) async {
          final good = gateway.page(request);
          return WorkspaceStockHistoryPage(
            query: invalid == 'scope'
                ? const WorkspaceStockHistoryQuery(
                    accountScope: 'other',
                    workspaceId: 'store-A',
                  )
                : good.query,
            snapshotId: invalid == 'snapshot' ? 'changed' : good.snapshotId,
            cursor: invalid == 'cursor' ? 'wrong' : good.cursor,
            nextCursor: invalid == 'loop' ? '50' : good.nextCursor,
            totalCount: invalid == 'total' ? 150 : good.totalCount,
            records: invalid == 'duplicate'
                ? [_historyMovement(0)]
                : invalid == 'order'
                ? good.records.reversed.toList()
                : good.records,
          );
        };
        expect(
          await work.loadWorkspaceStockHistory(query, more: true),
          isFalse,
          reason: invalid,
        );
        expect(work.workspaceStockHistory.length, 100);
        expect(work.workspaceStockHistoryNeedsRefresh, isTrue);
        expect(work.workspaceStockHistoryError, contains('Refresh'));
        final count = gateway.requests.length;
        expect(
          await work.loadWorkspaceStockHistory(query, more: true),
          isFalse,
        );
        expect(gateway.requests.length, count);
      }
    },
  );

  test(
    'DASH10 stock history retry and date product switch ignore late results',
    () async {
      final gateway = _StockHistoryGateway(
        List.generate(160, _historyMovement),
      );
      final account = _CommandAccountStore();
      final work = WorkSession(
        pendingProofStore: account,
        stockHistoryGateway: gateway,
      )..activeWorkspace = _commandStore;
      addTearDown(work.dispose);
      final query = work.workspaceStockHistoryScope()!;
      expect(await work.loadWorkspaceStockHistory(query), isTrue);
      gateway.respond = (_) async =>
          throw StateError('fixture connection failed');
      expect(await work.loadWorkspaceStockHistory(query, more: true), isFalse);
      expect(work.workspaceStockHistory.length, 50);
      expect(work.workspaceStockHistoryNeedsRefresh, isFalse);
      gateway.respond = null;
      expect(await work.loadWorkspaceStockHistory(query, more: true), isTrue);
      expect(gateway.requests[1].cursor, gateway.requests[2].cursor);
      final held = Completer<WorkspaceStockHistoryPage>();
      gateway.respond = (_) => held.future;
      final stale = work.loadWorkspaceStockHistory(query, more: true);
      expect(await work.loadWorkspaceStockHistory(query, more: true), isFalse);
      final old = gateway.requests.last;
      final filter = work.workspaceStockHistoryScope(
        productId: 'atta-5kg',
        from: DateTime.utc(2026, 9, 10, 11),
        until: DateTime.utc(2026, 9, 10, 12),
      )!;
      gateway.respond = null;
      expect(await work.loadWorkspaceStockHistory(filter), isTrue);
      expect(work.workspaceStockHistory.length, 30);
      final ids = work.workspaceStockHistory.map((row) => row.id).toList();
      held.complete(gateway.page(old));
      expect(await stale, isFalse);
      expect(work.workspaceStockHistory.map((row) => row.id), ids);
      expect(work.workspaceStockHistoryQuery?.key, filter.key);
      account.accountScope = 'account-B';
      expect(work.workspaceStockHistory, isEmpty);
      expect(await work.loadWorkspaceStockHistory(query), isFalse);
      expect(work.workspaceStockHistoryLoaded, isFalse);
    },
  );

  test(
    'DASH10 history query boundaries signs references and unavailable gateway are honest',
    () async {
      final query = WorkspaceStockHistoryQuery(
        accountScope: 'account-A',
        workspaceId: 'store-A',
        from: DateTime.utc(2026, 9, 10, 11),
        until: DateTime.utc(2026, 9, 10, 12),
      );
      expect(query.includes(_historyMovement(0)), isFalse);
      expect(query.includes(_historyMovement(60)), isTrue);
      expect(query.includes(_historyMovement(61)), isFalse);
      expect(
        WorkspaceStockHistoryQuery(
          accountScope: 'account-A',
          workspaceId: 'store-A',
          from: DateTime(2026, 9, 10),
        ).valid,
        isFalse,
      );
      expect(
        const WorkspaceStockHistoryQuery(
          accountScope: '',
          workspaceId: 'store-A',
        ).valid,
        isFalse,
      );
      final movement = _historyMovement(0);
      expect(movement.label, 'Reserved for order');
      expect(movement.referenceId, 'ORDER-0');
      expect(
        WorkspaceStockMovement(
          id: 'bad',
          productId: movement.productId,
          productLabel: movement.productLabel,
          kind: WorkspaceStockMovementKind.reserved,
          quantityDelta: 1,
          reason: movement.reason,
          occurredAt: movement.occurredAt,
        ).valid,
        isFalse,
      );
      expect(
        WorkspaceStockMovement(
          id: 'bad',
          productId: movement.productId,
          productLabel: movement.productLabel,
          kind: WorkspaceStockMovementKind.adjustment,
          quantityDelta: 1,
          reason: movement.reason,
          occurredAt: movement.occurredAt,
          referenceKind: WorkspaceStockReferenceKind.order,
        ).valid,
        isFalse,
      );
      final work = WorkSession(pendingProofStore: _CommandAccountStore())
        ..activeWorkspace = _commandStore;
      addTearDown(work.dispose);
      expect(await work.loadWorkspaceStockHistory(query), isFalse);
      expect(work.workspaceStockHistoryLoaded, isFalse);
      expect(work.workspaceStockHistoryTotal, isNull);
    },
  );

  WorkspaceIssueRecord draftCase({
    String id = 'CASE-A',
    String order = 'ORDER-A',
    int revision = 1,
    String reason = 'One sealed pack is damaged.',
    WorkspaceIssueState state = WorkspaceIssueState.retailerReview,
  }) => WorkspaceIssueRecord(
    accountScope: 'account-A',
    workspaceId: 'store-A',
    id: id,
    referenceId: order,
    target: WorkspaceIssueTarget.customerOrder,
    kind: WorkspaceIssueKind.packingShortage,
    state: state,
    revision: revision,
    updatedAt: DateTime(2026, 9, 10, 12, revision),
    reason: reason,
    nextStep: 'Review the affected pack.',
    resolution: state.closed ? 'The correct pack is available.' : null,
    permittedResponses: state == WorkspaceIssueState.retailerReview
        ? const [
            WorkspaceIssueResponse.provideDetails,
            WorkspaceIssueResponse.declineRequest,
          ]
        : const [],
    lines: const [
      WorkspaceIssueLine(
        lineId: 'atta-5kg',
        productId: 'atta-5kg',
        name: 'Atta',
        pack: '5 kg',
        orderedQuantity: 1,
        affectedQuantity: 1,
      ),
    ],
  );

  test(
    'DASH09 encrypted drafts reject corrupt identities and isolate keys',
    () async {
      var account = 'account-A';
      final storage = _OrderJournalStorage();
      final store = SecureWorkIssueDraftStore(
        accountScope: () => account,
        storage: storage,
      );
      const key = (account: 'account-A', store: 'store/A', caseId: 'case/B');
      const other = (account: 'account-A', store: 'store', caseId: 'A/case/B');
      const draft = WorkspaceIssueDraft(
        key: key,
        referenceId: 'ORDER-A',
        target: WorkspaceIssueTarget.customerOrder,
        expectedRevision: 1,
        response: WorkspaceIssueResponse.provideDetails,
        note: 'Keep my unsent note.',
      );
      await store.save(draft);
      expect((await store.read(key))?.note, draft.note);
      expect(await store.read(other), isNull);
      expect(storage.values.length, 1);
      account = 'account-B';
      expect(await store.read(key), isNull);
      await expectLater(
        store.save(draft),
        throwsA(isA<WorkGatewayException>()),
      );
      account = 'account-A';
      final path = storage.values.keys.single;
      storage.values[path] = jsonEncode({...draft.toJson(), 'caseId': 'other'});
      await expectLater(store.read(key), throwsA(isA<WorkGatewayException>()));
      for (final value in [
        {...draft.toJson(), 'revision': 0},
        {...draft.toJson(), 'response': 'refundAutomatically'},
        {...draft.toJson(), 'target': 'anyStore'},
        {...draft.toJson(), 'note': 'x' * 2001},
        {...draft.toJson(), 'version': 2},
      ]) {
        expect(WorkspaceIssueDraft.fromJson(value), isNull);
      }
    },
  );

  test(
    'DASH09 command journal precedes send and duplicate taps reconcile after restart',
    () async {
      final fixture = _IssueCommandFixture();
      final issue = draftCase();
      final work = fixture.make(issue);
      addTearDown(work.dispose);
      await fixture.prepare(work, issue);
      final draft = work.workspaceIssueDraft(issue)!;
      fixture.journalStorage.holdWrite = Completer<void>();
      final lost = Completer<WorkIssueReply>();
      fixture.gateway.submit = (_) => lost.future;
      final send = work.sendWorkspaceIssueResponse(issue, expectedDraft: draft);
      await _drainOrderJournal();
      expect(fixture.gateway.submitted, isEmpty);
      expect(
        await work.sendWorkspaceIssueResponse(issue, expectedDraft: draft),
        isFalse,
      );
      fixture.journalStorage.holdWrite!.complete();
      await _drainOrderJournal();
      final command = fixture.gateway.submitted.single;
      expect(
        WorkIssueSubmission.fromJson(
          jsonDecode(fixture.journalStorage.values.values.single),
        )?.command.digest,
        command.digest,
      );
      expect(command.lines.single.pack, '5 kg');
      lost.completeError(StateError('test connection lost after receipt'));
      expect(await send, isFalse);
      expect(work.workspaceIssueResponseLocksDraft(issue), isTrue);
      expect(work.workspaceIssueMayRetrySend(issue), isFalse);
      final restarted = fixture.make(issue);
      addTearDown(restarted.dispose);
      await restarted.loadWorkspaceIssueDraft(issue);
      await restarted.loadWorkspaceIssueResponse(issue);
      expect(
        restarted.workspaceIssueResponse(issue)?.command.operationId,
        command.operationId,
      );
      expect(await restarted.checkWorkspaceIssueResponse(issue), isTrue);
      expect(fixture.gateway.reconciled.single.digest, command.digest);
      expect(fixture.gateway.submitted.length, 1);
      expect(restarted.workspaceIssueCanSend(issue), isFalse);
      expect(
        restarted
            .workspaceIssuesFor(WorkspaceIssueTarget.customerOrder, 'ORDER-A')
            .single
            .state,
        WorkspaceIssueState.retailerReview,
      );
      expect(restarted.workspaceOrders.single.stage, 'Preparing');
    },
  );

  test(
    'DASH09 failed journal and not-recorded retries reuse exact command',
    () async {
      final fixture = _IssueCommandFixture();
      final issue = draftCase();
      final work = fixture.make(issue);
      addTearDown(work.dispose);
      await fixture.prepare(work, issue);
      fixture.journalStorage.failWrite = true;
      expect(
        await work.sendWorkspaceIssueResponse(
          issue,
          expectedDraft: work.workspaceIssueDraft(issue)!,
        ),
        isFalse,
      );
      expect(fixture.gateway.submitted, isEmpty);
      expect(work.workspaceIssueMayRetrySend(issue), isTrue);
      final command = work.workspaceIssueResponse(issue)!.command;
      fixture.journalStorage.failWrite = false;
      fixture.gateway.submit = (c) async =>
          _issueReply(c, state: WorkIssueReplyState.notRecorded);
      expect(
        await work.checkWorkspaceIssueResponse(issue, retrySend: true),
        isFalse,
      );
      expect(work.workspaceIssueMayRetrySend(issue), isTrue);
      fixture.journalStorage.failWrite = true;
      expect(
        await work.checkWorkspaceIssueResponse(issue, retrySend: true),
        isFalse,
      );
      expect(
        work.workspaceIssueResponseMessage(issue),
        isNot(contains('Nothing was sent')),
      );
      expect(fixture.gateway.submitted.length, 1);
      fixture.journalStorage.failWrite = false;
      fixture.gateway.submit = (c) async => _issueReply(c);
      expect(
        await work.checkWorkspaceIssueResponse(issue, retrySend: true),
        isTrue,
      );
      expect(fixture.gateway.submitted.map((c) => c.operationId).toSet(), {
        command.operationId,
      });
      expect(fixture.gateway.submitted.map((c) => c.digest).toSet(), {
        command.digest,
      });
    },
  );

  test(
    'DASH09 invalid receipts and receipt-write failure stay pending',
    () async {
      for (final invalid in [
        'account',
        'store',
        'case',
        'operation',
        'digest',
        'revision',
        'receipt-write',
      ]) {
        final fixture = _IssueCommandFixture();
        final issue = draftCase();
        final work = fixture.make(issue);
        addTearDown(work.dispose);
        await fixture.prepare(work, issue);
        fixture.gateway.submit = (c) async {
          if (invalid == 'receipt-write') {
            fixture.journalStorage.failWrite = true;
          }
          return WorkIssueReply(
            key: (
              account: invalid == 'account' ? 'other' : c.key.account,
              store: invalid == 'store' ? 'other' : c.key.store,
              caseId: invalid == 'case' ? 'other' : c.key.caseId,
            ),
            operationId: invalid == 'operation' ? 'other' : c.operationId,
            commandDigest: invalid == 'digest' ? 'other' : c.digest,
            state: WorkIssueReplyState.applied,
            revision: invalid == 'revision' ? 1 : 2,
          );
        };
        expect(
          await work.sendWorkspaceIssueResponse(
            issue,
            expectedDraft: work.workspaceIssueDraft(issue)!,
          ),
          isFalse,
          reason: invalid,
        );
        expect(
          work.workspaceIssueResponse(issue)?.pending,
          isTrue,
          reason: invalid,
        );
        expect(work.workspaceIssueMayRetrySend(issue), isFalse);
        fixture.journalStorage.failWrite = false;
        expect(await work.checkWorkspaceIssueResponse(issue), isTrue);
        expect(fixture.gateway.submitted.length, 1);
      }
    },
  );

  test(
    'DASH09 decline confirmation revisions permissions and account changes fail closed',
    () async {
      final fixture = _IssueCommandFixture();
      final issue = draftCase();
      final work = fixture.make(issue);
      addTearDown(work.dispose);
      await fixture.prepare(
        work,
        issue,
        response: WorkspaceIssueResponse.declineRequest,
      );
      final draft = work.workspaceIssueDraft(issue)!;
      expect(
        await work.sendWorkspaceIssueResponse(issue, expectedDraft: draft),
        isFalse,
      );
      expect(
        work.workspaceIssueCanSend(
          draftCase(reason: 'Unverified case content'),
        ),
        isFalse,
      );
      await work.saveWorkspaceIssueDraft(
        issue,
        response: draft.response,
        note: 'Changed during confirmation',
      );
      expect(
        await work.sendWorkspaceIssueResponse(
          issue,
          expectedDraft: draft,
          declineConfirmed: true,
        ),
        isFalse,
      );
      expect(fixture.gateway.submitted, isEmpty);
      fixture.gateway.submit = (c) async => _issueReply(
        c,
        state: WorkIssueReplyState.rejected,
        error: WorkIssueResponseError.permissionDenied,
      );
      expect(
        await work.sendWorkspaceIssueResponse(
          issue,
          expectedDraft: work.workspaceIssueDraft(issue)!,
          declineConfirmed: true,
        ),
        isFalse,
      );
      expect(work.workspaceIssueCanSend(issue), isFalse);
      final next = draftCase(revision: 2);
      expect(
        work.applyWorkspaceIssues(
          accountScope: 'account-A',
          storeId: 'store-A',
          feedRevision: 2,
          records: [next],
        ),
        isTrue,
      );
      await work.saveWorkspaceIssueDraft(
        next,
        response: draft.response,
        note: 'Reviewed the updated case',
        reviewedUpdate: true,
      );
      expect(work.workspaceIssueCanSend(next), isTrue);
      final held = Completer<WorkIssueReply>();
      fixture.gateway.submit = (_) => held.future;
      final send = work.sendWorkspaceIssueResponse(
        next,
        expectedDraft: work.workspaceIssueDraft(next)!,
        declineConfirmed: true,
      );
      await _drainOrderJournal();
      fixture.account.accountScope = 'account-B';
      held.complete(_issueReply(fixture.gateway.submitted.last));
      expect(await send, isFalse);
      expect(work.workspaceIssueResponse(next), isNull);
      fixture.account.accountScope = 'account-A';
      expect(work.workspaceIssueResponse(next)?.pending, isTrue);
      expect(await work.checkWorkspaceIssueResponse(next), isTrue);
    },
  );

  test(
    'DASH09 encrypted response journal rejects corruption and closed cases recover',
    () async {
      final fixture = _IssueCommandFixture();
      final issue = draftCase();
      final work = fixture.make(issue);
      addTearDown(work.dispose);
      await fixture.prepare(work, issue);
      expect(
        await work.sendWorkspaceIssueResponse(
          issue,
          expectedDraft: work.workspaceIssueDraft(issue)!,
        ),
        isTrue,
      );
      final closed = draftCase(
        revision: 3,
        state: WorkspaceIssueState.resolved,
      );
      final restarted = fixture.make(closed);
      addTearDown(restarted.dispose);
      await restarted.loadWorkspaceIssueDraft(closed);
      await restarted.loadWorkspaceIssueResponse(closed);
      expect(
        restarted.workspaceIssueDraft(closed)?.note,
        'One sealed pack is damaged.',
      );
      expect(
        restarted.workspaceIssueResponse(closed)?.reply?.state,
        WorkIssueReplyState.applied,
      );
      expect(restarted.workspaceIssueCanSend(closed), isFalse);
      final key = fixture.journalStorage.values.keys.single;
      final saved =
          jsonDecode(fixture.journalStorage.values[key]!)
              as Map<String, dynamic>;
      final corrupted = {
        ...saved,
        'reply': {...saved['reply'] as Map, 'commandDigest': 'wrong'},
      };
      expect(WorkIssueSubmission.fromJson(corrupted), isNull);
      fixture.journalStorage.values[key] = jsonEncode(corrupted);
      final unread = fixture.make(closed);
      addTearDown(unread.dispose);
      await unread.loadWorkspaceIssueResponse(closed);
      expect(unread.workspaceIssueResponseLoaded(closed), isFalse);
      expect(
        unread.workspaceIssueResponseMessage(closed),
        contains('Could not open'),
      );
      expect(unread.workspaceIssueCanSend(closed), isFalse);
    },
  );

  test(
    'DASH09 response drafts persist restart edits failure and revision review without effects',
    () async {
      final account = _CommandAccountStore();
      final storage = _OrderJournalStorage();
      final drafts = SecureWorkIssueDraftStore(
        accountScope: () => account.accountScope,
        storage: storage,
      );
      WorkSession make() {
        final work = WorkSession(
          pendingProofStore: account,
          issueDraftStore: drafts,
        )..activeWorkspace = _commandStore;
        work.workspaceOrders.addAll([
          _scopeOrder('ORDER-A', stage: 'Preparing'),
          _scopeOrder('ORDER-B', stage: 'Preparing'),
        ]);
        expect(
          work.applyWorkspaceIssues(
            accountScope: 'account-A',
            storeId: 'store-A',
            feedRevision: 1,
            records: [
              draftCase(),
              draftCase(id: 'CASE-B', order: 'ORDER-B'),
            ],
          ),
          isTrue,
        );
        return work;
      }

      final work = make();
      addTearDown(work.dispose);
      final issue = draftCase();
      storage.failRead = true;
      await work.loadWorkspaceIssueDraft(issue);
      expect(work.workspaceIssueDraftLoaded(issue), isFalse);
      await work.saveWorkspaceIssueDraft(
        issue,
        response: null,
        note: 'Do not overwrite unread text',
      );
      expect(storage.writes, isEmpty);
      storage.failRead = false;
      await work.loadWorkspaceIssueDraft(issue);
      expect(work.workspaceIssueDraftLoaded(issue), isTrue);
      final unicode = 'क़🙏🏽' * 1000;
      expect(WorkspaceIssueDraft.acceptsNote(unicode), isTrue);
      await work.saveWorkspaceIssueDraft(issue, response: null, note: unicode);
      expect((await drafts.read(issue.draftKey))?.note, unicode);
      await work.saveWorkspaceIssueDraft(
        issue,
        response: null,
        note: '${unicode}x',
      );
      expect(work.workspaceIssueDraft(issue)?.note, unicode);
      storage.holdWrite = Completer<void>();
      final a = work.saveWorkspaceIssueDraft(
        issue,
        response: WorkspaceIssueResponse.provideDetails,
        note: 'First',
      );
      final b = work.saveWorkspaceIssueDraft(
        issue,
        response: WorkspaceIssueResponse.provideDetails,
        note: 'Latest unsent note',
      );
      storage.holdWrite!.complete();
      await Future.wait([a, b]);
      storage.holdWrite = null;
      expect((await drafts.read(issue.draftKey))?.note, 'Latest unsent note');
      final second = draftCase(id: 'CASE-B', order: 'ORDER-B');
      await work.loadWorkspaceIssueDraft(second);
      await work.saveWorkspaceIssueDraft(
        second,
        response: null,
        note: 'Other case',
      );
      expect((await drafts.read(issue.draftKey))?.note, 'Latest unsent note');
      storage.failWrite = true;
      await work.saveWorkspaceIssueDraft(
        issue,
        response: null,
        note: 'Recover this edit',
      );
      expect(work.workspaceIssueDraft(issue)?.note, 'Recover this edit');
      expect(
        work.workspaceIssueDraftMessage(issue),
        startsWith('Draft not saved'),
      );
      storage.failWrite = false;
      await work.saveWorkspaceIssueDraft(
        issue,
        response: null,
        note: 'Recover this edit',
      );
      expect(work.workspaceIssueDraftMessage(issue), contains('Not sent'));
      account.accountScope = 'account-B';
      expect(work.workspaceIssueDraft(issue), isNull);
      await work.saveWorkspaceIssueDraft(
        issue,
        response: null,
        note: 'Wrong account',
      );
      account.accountScope = 'account-A';
      final restored = make();
      addTearDown(restored.dispose);
      await restored.loadWorkspaceIssueDraft(issue);
      expect(restored.workspaceIssueDraft(issue)?.note, 'Recover this edit');
      final updated = draftCase(revision: 2);
      expect(
        restored.applyWorkspaceIssues(
          accountScope: 'account-A',
          storeId: 'store-A',
          feedRevision: 2,
          records: [updated, second],
        ),
        isTrue,
      );
      await restored.saveWorkspaceIssueDraft(
        updated,
        response: null,
        note: 'Revised details',
      );
      expect(restored.workspaceIssueDraft(updated)?.expectedRevision, 1);
      await restored.saveWorkspaceIssueDraft(
        updated,
        response: WorkspaceIssueResponse.acceptRequest,
        note: 'Unpermitted option',
        reviewedUpdate: true,
      );
      expect(restored.workspaceIssueDraft(updated)?.expectedRevision, 1);
      await restored.saveWorkspaceIssueDraft(
        updated,
        response: WorkspaceIssueResponse.provideDetails,
        note: 'Reviewed new case',
        reviewedUpdate: true,
      );
      expect(restored.workspaceIssueDraft(updated)?.expectedRevision, 2);
      expect(restored.selectWorkspaceOrder('ORDER-A'), isTrue);
      expect(restored.workspaceOrderHasPackingIssue('ORDER-A'), isTrue);
      restored.advanceWorkspaceOrder();
      expect(restored.workspaceOrders.first.stage, 'Preparing');
      expect(restored.errorMessage, contains('Resolve the item issue'));
      expect(
        restored.applyWorkspaceIssues(
          accountScope: 'account-A',
          storeId: 'store-A',
          feedRevision: 3,
          records: [],
        ),
        isTrue,
      );
      expect(
        restored.workspaceOrderHasPackingIssue('ORDER-A'),
        isTrue,
        reason: 'Leaving a visible window is not case resolution',
      );
      expect(
        restored.applyWorkspaceIssues(
          accountScope: 'account-A',
          storeId: 'store-A',
          feedRevision: 4,
          records: [
            draftCase(revision: 3, state: WorkspaceIssueState.resolved),
          ],
        ),
        isTrue,
      );
      expect(restored.workspaceOrderHasPackingIssue('ORDER-A'), isFalse);
      expect(
        restored.workspaceOrders.every((o) => o.stage == 'Preparing'),
        isTrue,
      );
      expect(restored.workspaceInvoices, isEmpty);
      expect(restored.workspaceStockMovements, isEmpty);
    },
  );

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

  test(
    'DASH12 contact history parses whole phones without identity collisions',
    () {
      expect(
        workspaceCustomerMobile('Customer 2 · +91 98290 12345'),
        '9829012345',
      );
      expect(workspaceCustomerMobile('9829012345'), '9829012345');
      for (final value in [
        'Customer 2 9829012345',
        'Customer · 19829012345',
        'Customer · 9829012345x',
        'Customer · 9829012345 · 9876543210',
        '· 9829012345',
        'Customer · 9829012345 / 9876543210',
      ]) {
        expect(workspaceCustomerMobile(value), isNull, reason: value);
      }
      final session = WorkSession(gateway: ReviewWorkGateway());
      addTearDown(session.dispose);
      final customers = [
        'Customer 2 · 9829012345',
        'Customer 2 · +91 98290 12345',
        'Customer · 19829012345',
        'Customer · 9829012345x',
        '',
      ];
      for (var index = 0; index < customers.length; index++) {
        session.workspaceOrders.add(
          WorkspaceOrderRecord(
            id: 'CONTACT-$index',
            customer: customers[index],
            items: 'Oil × 1',
            quantities: const {'oil': 1},
            amount: 120,
            source: 'Counter',
            fulfilment: 'Pickup',
            payment: 'Paid online',
            address: '',
            stage: 'Completed',
            needsDelivery: false,
            createdAt: DateTime(2026, 9, 10),
          ),
        );
      }
      final book = session.workspaceCustomerBook;
      expect(book, hasLength(4));
      final valid = book.singleWhere((customer) => customer.id == '9829012345');
      expect(valid.mobile, '9829012345');
      expect(valid.name, 'Customer 2');
      expect(valid.orders, hasLength(2));
      expect(valid.totalSpend, 240);
      expect(
        book
            .where((customer) => customer.id != valid.id)
            .every(
              (customer) => customer.mobile.isEmpty && customer.name.isNotEmpty,
            ),
        isTrue,
      );
      expect(session.workspaceOrders.map((order) => order.customer), customers);
    },
  );

  WorkspacePurchaseRecord supply(
    String id, {
    String account = 'account-A',
    String store = 'store-A',
    String supplier = 'supplier-A',
    String order = 'PO-A',
    int revision = 1,
    WorkspaceSupplyStage stage = WorkspaceSupplyStage.dispatched,
    int? received,
    int minor = 15550,
  }) => WorkspacePurchaseRecord(
    accountScope: account,
    workspaceId: store,
    supplierId: supplier,
    supplierName: supplier,
    orderId: order,
    shipmentId: id,
    revision: revision,
    createdAt: DateTime(2026, 9, 10),
    updatedAt: DateTime(2026, 9, 10, 12, revision),
    stage: stage,
    amountMinor: minor,
    itemSummary: 'Oil · 1 l × 10 packs',
    paymentLabel: 'Paid online',
    receiptState: received == null
        ? WorkspaceReceiptState.awaiting
        : WorkspaceReceiptState.partial,
    lines: [
      WorkspacePurchaseLine(
        id: 'line-1',
        productId: 'same-sku',
        name: 'Oil',
        pack: '1 l',
        orderedPacks: 10,
        receivedPacks: received,
        unitPriceMinor: 1555,
      ),
    ],
  );

  test(
    'DASH09 case projections isolate source items revisions and business effects',
    () {
      final account = _CommandAccountStore();
      final session = WorkSession(
        gateway: ReviewWorkGateway(),
        pendingProofStore: account,
      )..activeWorkspace = _commandStore;
      addTearDown(session.dispose);
      for (var i = 0; i < 100; i++) {
        session.workspaceOrders.add(
          _scopeOrder('ORDER-$i', stage: i.isEven ? 'Preparing' : 'Completed'),
        );
      }
      expect(session.selectWorkspaceOrder('ORDER-0'), isTrue);
      expect(
        session.applyWorkspacePurchases(
          accountScope: 'account-A',
          storeId: 'store-A',
          feedRevision: 1,
          records: [supply('SHIP-A', received: 8)],
          complete: true,
        ),
        isTrue,
      );
      final stages = session.workspaceOrders
          .map((o) => (o.id, o.stage, o.payment))
          .toList();
      WorkspaceIssueRecord issue({
        String id = 'CASE-A',
        String reference = 'ORDER-0',
        WorkspaceIssueTarget target = WorkspaceIssueTarget.customerOrder,
        WorkspaceIssueKind kind = WorkspaceIssueKind.packingShortage,
        WorkspaceIssueState state = WorkspaceIssueState.retailerReview,
        String scope = 'account-A',
        int revision = 1,
        int quantity = 1,
        String reason = 'One pack is unavailable.',
        String? resolution,
        String? sku,
        String? lineId,
      }) => WorkspaceIssueRecord(
        accountScope: scope,
        workspaceId: 'store-A',
        id: id,
        referenceId: reference,
        target: target,
        kind: kind,
        state: state,
        revision: revision,
        updatedAt: DateTime(2026, 9, 10, 10, revision),
        reason: reason,
        nextStep: 'Review the affected items.',
        resolution: resolution,
        lines: [
          WorkspaceIssueLine(
            lineId:
                lineId ??
                (target == WorkspaceIssueTarget.customerOrder
                    ? 'atta-5kg'
                    : 'line-1'),
            productId:
                sku ??
                (target == WorkspaceIssueTarget.customerOrder
                    ? 'atta-5kg'
                    : 'same-sku'),
            name: target == WorkspaceIssueTarget.customerOrder ? 'Atta' : 'Oil',
            pack: target == WorkspaceIssueTarget.customerOrder ? '5 kg' : '1 l',
            orderedQuantity: target == WorkspaceIssueTarget.customerOrder
                ? 1
                : 10,
            affectedQuantity: quantity,
          ),
        ],
      );
      bool apply(int revision, List<WorkspaceIssueRecord> records) =>
          session.applyWorkspaceIssues(
            accountScope: 'account-A',
            storeId: 'store-A',
            feedRevision: revision,
            records: records,
          );
      final customer = issue();
      final supplier = issue(
        id: 'CASE-S',
        reference: 'SHIP-A',
        target: WorkspaceIssueTarget.supplierShipment,
        kind: WorkspaceIssueKind.damagedItem,
        state: WorkspaceIssueState.supplierReview,
        quantity: 2,
      );
      expect(apply(1, [customer, supplier]), isTrue);
      expect(() => customer.lines.clear(), throwsUnsupportedError);
      expect(
        session
            .workspaceIssuesFor(WorkspaceIssueTarget.customerOrder, 'ORDER-0')
            .single
            .id,
        'CASE-A',
      );
      expect(
        session.workspaceIssuesFor(
          WorkspaceIssueTarget.customerOrder,
          'ORDER-1',
        ),
        isEmpty,
      );
      expect(apply(2, [issue(quantity: 2)]), isFalse);
      expect(apply(2, [issue(sku: 'unknown-sku')]), isFalse);
      expect(apply(2, [issue(lineId: 'invented-line')]), isFalse);
      expect(apply(2, [issue(scope: 'other-account')]), isFalse);
      expect(apply(2, [issue(reference: 'unknown-order')]), isFalse);
      expect(apply(2, [issue(reference: 'ORDER-1', revision: 2)]), isFalse);
      expect(apply(2, [issue(reason: 'Same revision changed')]), isFalse);
      expect(apply(2, [customer, customer]), isFalse);
      expect(
        apply(2, [issue(state: WorkspaceIssueState.declined, revision: 2)]),
        isFalse,
      );
      expect(
        apply(2, [
          issue(
            state: WorkspaceIssueState.resolved,
            revision: 2,
            resolution: 'Case reviewed.',
          ),
          supplier,
        ]),
        isTrue,
      );
      expect(
        session.workspaceOrders.map((o) => (o.id, o.stage, o.payment)),
        stages,
      );
      expect(session.workspaceStockMovements, isEmpty);
      expect(session.workspaceInvoices, isEmpty);
      expect(session.workspaceSettlementRequested, 0);
      expect(session.workspacePurchases.single.lines.single.receivedPacks, 8);
      expect(session.currentWorkspaceOrderId, 'ORDER-0');
      session.markWorkspaceIssuesStale(
        accountScope: 'account-A',
        storeId: 'store-A',
      );
      expect(session.workspaceIssuesStale, isTrue);
      expect(apply(3, []), isTrue);
      expect(session.workspaceIssuesStale, isFalse);
      expect(
        apply(4, [customer]),
        isFalse,
        reason: 'Removal cannot allow stale case resurrection',
      );
      expect(
        apply(4, [
          issue(revision: 3, state: WorkspaceIssueState.customerReview),
        ]),
        isTrue,
      );
      session.activeWorkspace = const WorkWorkspace(
        id: 'store-B',
        name: 'Store B',
        profileLabel: 'Grocery / Kirana Shop',
        profileId: 'retailer-grocery',
        area: 'Jodhpur',
        verified: true,
      );
      expect(
        session.workspaceIssuesFor(
          WorkspaceIssueTarget.customerOrder,
          'ORDER-0',
        ),
        isEmpty,
      );
      session.activeWorkspace = _commandStore;
      expect(
        session.workspaceIssuesFor(
          WorkspaceIssueTarget.customerOrder,
          'ORDER-0',
        ),
        hasLength(1),
      );
      account.accountScope = 'another-account';
      expect(
        session.workspaceIssuesFor(
          WorkspaceIssueTarget.customerOrder,
          'ORDER-0',
        ),
        isEmpty,
      );
      expect(apply(5, [issue(revision: 4)]), isFalse);
    },
  );

  final financeTime = DateTime(2026, 9, 10, 10);
  WorkspacePaymentRecord paymentFact(
    int i, {
    int revision = 1,
    String? customer,
    WorkspacePaymentState? state,
  }) {
    // ORDER-012 is the paid-to-Store row asserted by the isolation journey.
    final status =
        state ??
        (i == 12
            ? WorkspacePaymentState.paid
            : WorkspacePaymentState.values[i %
                  WorkspacePaymentState.values.length]);
    final paid =
        {
          WorkspacePaymentState.paid,
          WorkspacePaymentState.refundPending,
          WorkspacePaymentState.refunded,
          WorkspacePaymentState.disputed,
        }.contains(status)
        ? 27500
        : status == WorkspacePaymentState.partPaid
        ? 10000
        : 0;
    return WorkspacePaymentRecord(
      orderId: 'ORDER-${i.toString().padLeft(3, '0')}',
      customerId: customer ?? 'customer-$i',
      customerName: 'Customer $i',
      revision: revision,
      updatedAt: financeTime,
      amountMinor: 27500,
      paidMinor: paid,
      dueMinor: status == WorkspacePaymentState.returnAdjusted
          ? 0
          : 27500 - paid,
      refundedMinor: status == WorkspacePaymentState.refunded ? paid : 0,
      state: status,
      // Keep this established 25-record scenario stable as new tenders are
      // added. Bank Transfer has its own reference/recovery test above.
      channel: const [
        WorkspacePaymentChannel.platform,
        WorkspacePaymentChannel.cash,
        WorkspacePaymentChannel.directUpi,
        WorkspacePaymentChannel.credit,
        WorkspacePaymentChannel.unknown,
      ][i % 5],
      invoiceId: 'INV-$i',
      transactionId: 'TX-$i',
    );
  }

  WorkspacePayoutRecord payoutFact({
    int revision = 1,
    String id = 'SET-1',
    WorkspacePayoutState state = WorkspacePayoutState.requested,
  }) => WorkspacePayoutRecord(
    id: id,
    operationId: 'settlement-op-1',
    revision: revision,
    amountMinor: 10050,
    updatedAt: financeTime,
    state: state,
    bankLabel: 'Bank · •••• 4321',
  );
  WorkspaceFinanceSnapshot financeFact(
    int revision, {
    String account = 'account-A',
    String store = 'store-A',
    List<WorkspacePaymentRecord>? payments,
    List<WorkspacePayoutRecord>? payouts,
    List<WorkspaceCustomerLedger> customerLedgers = const [],
    int available = 1000000000050,
    int paidOut = 50000,
    bool historyComplete = false,
  }) => WorkspaceFinanceSnapshot(
    accountScope: account,
    workspaceId: store,
    revision: revision,
    asOf: financeTime,
    salesTodayMinor: 1000000000050,
    duesMinor: 17500,
    availableMinor: available,
    heldMinor: 20025,
    requestedMinor: 10050,
    paidOutMinor: paidOut,
    feesMinor: 10025,
    deliveryAdjustmentsMinor: -525,
    refundsMinor: 27500,
    taxWithheldMinor: 200,
    payments: payments ?? [for (var i = 0; i < 25; i++) paymentFact(i)],
    payouts: payouts ?? [payoutFact()],
    customerLedgers: customerLedgers,
    historyComplete: historyComplete,
  );

  test('LEDGER03 settlement reconciliation excludes unsettled payouts', () {
    for (final state in WorkspacePayoutState.values) {
      final snapshot = financeFact(
        1,
        payouts: [payoutFact(state: state)],
        paidOut: state == WorkspacePayoutState.paid ? 10050 : 0,
        historyComplete: true,
      );
      final check = snapshot.settlementPaidReconciliation!;
      expect(
        check.recordedMinor,
        state == WorkspacePayoutState.paid ? 10050 : 0,
      );
      expect(check.differenceMinor, 0);
      expect(snapshot.salesTodayMinor, 1000000000050);
      expect(snapshot.availableMinor, 1000000000050);
    }
    final partial = financeFact(
      1,
      payouts: [payoutFact(state: WorkspacePayoutState.paid)],
      paidOut: 10050,
    );
    expect(partial.settlementPaidReconciliation!.recordedMinor, 10050);
    expect(partial.settlementPaidReconciliation!.differenceMinor, isNull);
    final mismatch = financeFact(
      1,
      payouts: [payoutFact(state: WorkspacePayoutState.paid)],
      paidOut: 10051,
      historyComplete: true,
    );
    expect(mismatch.settlementPaidReconciliation!.differenceMinor, 1);
    final duplicate = financeFact(
      1,
      payouts: [
        payoutFact(state: WorkspacePayoutState.paid),
        payoutFact(state: WorkspacePayoutState.paid),
      ],
      paidOut: 20100,
      historyComplete: true,
    );
    expect(duplicate.settlementPaidReconciliation, isNull);
  });

  test('LEDGER03 register UTC recovery uses the same instants', () {
    final localTime = DateTime(2026, 9, 14);
    final local = WorkspaceMoneyRegisterSnapshot(
      accountScope: 'account-A',
      workspaceId: 'store-A',
      registerId: 'cash',
      label: 'Test cash',
      revision: 1,
      openingAt: localTime,
      asOf: localTime.add(const Duration(days: 1)),
      openingMinor: 10000,
      historyComplete: true,
      entries: [
        WorkspaceMoneyRegisterEntry(
          id: 'receipt-A',
          reference: 'TEST-A',
          occurredAt: localTime.add(const Duration(hours: 1)),
          deltaMinor: 1230,
        ),
      ],
    );
    final restored = WorkspaceMoneyRegisterSnapshot.fromJson(
      jsonDecode(jsonEncode(local.toJson())),
    )!;
    expect(local.openingAt.isUtc, isFalse);
    expect(restored.openingAt.isUtc, isTrue);
    expect(restored.canFollow(local), isTrue);
    expect(local.canFollow(restored), isTrue);
    expect(restored.balances(local.openingAt, local.asOf)!.closingMinor, 11230);
  });

  test(
    'LEDGER03 register opening closing boundaries and immutable recovery',
    () {
      final day = DateTime.utc(2026, 9, 14);
      WorkspaceMoneyRegisterEntry movement(String id, int hour, int delta) =>
          WorkspaceMoneyRegisterEntry(
            id: id,
            reference: 'REF-$id',
            occurredAt: day.add(Duration(hours: hour)),
            deltaMinor: delta,
          );
      final entries = [
        movement('collection', 8, 60000),
        movement('expense', 9, -2500),
        movement('supplier', 10, -10000),
      ];
      WorkspaceMoneyRegisterSnapshot register({
        String account = 'account-A',
        String store = 'store-A',
        String id = 'cash-register',
        int revision = 1,
        int? opening = 10000,
        bool complete = true,
        List<WorkspaceMoneyRegisterEntry>? rows,
        DateTime? end,
      }) => WorkspaceMoneyRegisterSnapshot(
        accountScope: account,
        workspaceId: store,
        registerId: id,
        label: 'Test cash register',
        revision: revision,
        openingAt: day,
        asOf: end ?? day.add(const Duration(days: 1)),
        historyComplete: complete,
        openingMinor: opening,
        entries: rows ?? entries,
      );
      final snapshot = register();
      expect(snapshot.valid, isTrue);
      final balance = snapshot.balances(day, day.add(const Duration(days: 1)))!;
      expect(balance, (
        openingMinor: 10000,
        inMinor: 60000,
        outMinor: 12500,
        closingMinor: 57500,
      ));
      expect(
        snapshot.balances(
          day.add(const Duration(hours: 9)),
          day.add(const Duration(hours: 10)),
        ),
        (openingMinor: 70000, inMinor: 0, outMinor: 2500, closingMinor: 67500),
      );
      expect(
        snapshot.balances(day.subtract(const Duration(seconds: 1)), day),
        isNull,
      );
      expect(snapshot.balances(day, day.add(const Duration(days: 2))), isNull);
      expect(
        register(
          opening: null,
          complete: false,
        ).balances(day, day.add(const Duration(days: 1))),
        isNull,
      );
      final restored = WorkspaceMoneyRegisterSnapshot.fromJson(
        jsonDecode(jsonEncode(snapshot.toJson())),
      )!;
      expect(restored.toJson(), snapshot.toJson());
      expect(restored.canFollow(snapshot), isTrue);
      expect(
        register(revision: 2, opening: 10001).canFollow(snapshot),
        isFalse,
      );
      expect(
        register(revision: 2, account: 'account-B').canFollow(snapshot),
        isFalse,
      );
      expect(
        register(revision: 2, store: 'store-B').canFollow(snapshot),
        isFalse,
      );
      expect(
        register(revision: 2, id: 'bank-register').canFollow(snapshot),
        isFalse,
      );
      expect(
        register(revision: 2, complete: false).canFollow(snapshot),
        isFalse,
      );
      expect(
        register(
          revision: 2,
          rows: entries.take(2).toList(),
        ).canFollow(snapshot),
        isFalse,
      );
      expect(register(rows: [...entries, entries.last]).valid, isFalse);
      expect(
        register(rows: [...entries, movement('end-boundary', 24, 500)]).valid,
        isFalse,
      );
      expect(
        register(
          revision: 2,
          end: day.add(const Duration(days: 2)),
          rows: [...entries, movement('backdated', 12, 500)],
        ).canFollow(snapshot),
        isFalse,
      );
      final successor = register(
        revision: 2,
        end: day.add(const Duration(days: 2)),
        rows: [...entries, movement('next-day', 24, 500)],
      );
      expect(successor.canFollow(snapshot), isTrue);
      expect(
        successor.balances(
          day.add(const Duration(days: 1)),
          day.add(const Duration(days: 2)),
        ),
        (openingMinor: 57500, inMinor: 500, outMinor: 0, closingMinor: 58000),
      );
      expect(register(opening: 9007199254740991).valid, isFalse);
    },
  );

  test('LEDGER03 unified money excludes bills pending money and transfers', () {
    final customer = WorkspaceCustomerLedger(
      accountScope: 'account-A',
      workspaceId: 'store-A',
      customerId: 'customer-A',
      customerName: 'Test customer',
      revision: 1,
      asOf: financeTime,
      openingBalanceMinor: 0,
      historyComplete: true,
      entries: [
        for (var i = 0; i < 3; i++)
          WorkspaceCustomerLedgerEntry(
            id: 'entry-$i',
            operationId: 'customer-operation-$i',
            invoiceId: 'invoice-A',
            orderId: 'order-A',
            sequence: i + 1,
            occurredAt: financeTime,
            kind: i == 0
                ? WorkspaceLedgerEntryKind.invoice
                : WorkspaceLedgerEntryKind.collection,
            state: i == 2
                ? WorkspaceLedgerPostingState.pending
                : WorkspaceLedgerPostingState.posted,
            amountMinor: [100000, 60000, 40000][i],
            channel: WorkspacePaymentChannel.cash,
          ),
      ],
    );
    final supplier = WorkspaceSupplierLedger(
      accountScope: 'account-A',
      workspaceId: 'store-A',
      supplierId: 'supplier-A',
      supplierName: 'Test supplier',
      revision: 1,
      asOf: financeTime,
      openingBalanceMinor: 0,
      historyComplete: true,
      entries: [
        for (var i = 0; i < 3; i++)
          WorkspaceSupplierLedgerEntry(
            operationId: 'supplier-operation-$i',
            orderId: 'purchase-A',
            reference: 'SUP-$i',
            billId: 'bill-A',
            kind: [
              WorkspaceSupplierEntryKind.bill,
              WorkspaceSupplierEntryKind.advance,
              WorkspaceSupplierEntryKind.payment,
            ][i],
            amountMinor: [200000, 50000, 10000][i],
            postedAt: financeTime,
            paymentMethod: 'Bank transfer',
          ),
      ],
    );
    WorkspaceExpenseRecord expense({String account = 'account-A'}) =>
        WorkspaceExpenseRecord(
          accountScope: account,
          workspaceId: 'store-A',
          operationId: 'expense-A',
          amountMinor: 2500,
          category: 'Shop expense',
          method: 'Cash',
          reference: 'receipt-A',
          note: '',
          occurredAt: financeTime,
        );
    final finance = financeFact(
      1,
      customerLedgers: [customer],
      payouts: [payoutFact(state: WorkspacePayoutState.paid)],
    );
    WorkspaceMoneyStatement? statement({
      List<WorkspaceExpenseRecord>? expenses,
      DateTime? start,
    }) => WorkspaceMoneyStatement.fromLedgers(
      finance: finance,
      suppliers: [supplier],
      expenses: expenses ?? [expense()],
      start: start,
      end: financeTime,
    );
    final money = statement()!;
    expect(money.recordedInMinor, 60000);
    expect(money.recordedOutMinor, 62500);
    expect(money.entries, hasLength(6));
    expect(money.entries.where((e) => e.transfer).single.amountMinor, 10050);
    expect(money.entries.where((e) => !e.posted).single.amountMinor, 40000);
    expect(money.entries.map((e) => e.id).toSet(), hasLength(6));
    expect(
      statement()!.recordedOutMinor,
      62500,
      reason: 'Opening again cannot post twice',
    );
    expect(statement(expenses: [expense(account: 'account-B')]), isNull);
    expect(statement(expenses: [expense(), expense()]), isNull);
    expect(
      statement(start: financeTime.add(const Duration(seconds: 1))),
      isNull,
    );
    final before = WorkspaceMoneyStatement.fromLedgers(
      finance: finance,
      suppliers: [supplier],
      expenses: [expense()],
      end: financeTime.subtract(const Duration(seconds: 1)),
    )!;
    expect(before.entries, isEmpty);
    expect(before.recordedInMinor, 0);
    expect(customer.closingBalanceMinor, 40000);
    expect(supplier.balanceMinor, 140000);
  });

  test(
    'LEDGER01 checkpoint retains existing payment payout and signed adjustment fields',
    () {
      final checkpoint = WorkspaceLedgerCheckpoint(
        revision: 1,
        finance: financeFact(1),
      );
      final recovered = WorkspaceLedgerCheckpoint.fromJson(
        jsonDecode(jsonEncode(checkpoint.toJson())),
      )!;
      expect(recovered.toJson(), checkpoint.toJson());
      expect(recovered.finance.payments, hasLength(25));
      expect(
        recovered.finance.payouts.single.revisionData,
        checkpoint.finance.payouts.single.revisionData,
      );
      expect(recovered.finance.deliveryAdjustmentsMinor, -525);
      expect(recovered.finance.availableMinor, 1000000000050);
    },
  );

  test(
    'LEDGER02 encrypted checkpoint preserves supplier history and scope',
    () async {
      final ledger = WorkspaceSupplierLedger(
        accountScope: 'account-A',
        workspaceId: 'store-A',
        supplierId: 'supplier-A',
        supplierName: 'Test grocery supplier',
        revision: 1,
        asOf: financeTime,
        historyComplete: true,
        openingBalanceMinor: 0,
        entries: [
          WorkspaceSupplierLedgerEntry(
            operationId: 'supplier-bill-1',
            orderId: 'purchase-1',
            reference: 'BILL-1',
            billId: 'bill-1',
            kind: WorkspaceSupplierEntryKind.bill,
            amountMinor: 200000,
            postedAt: financeTime,
          ),
          WorkspaceSupplierLedgerEntry(
            operationId: 'supplier-advance-1',
            orderId: 'purchase-1',
            reference: 'ADVANCE-1',
            kind: WorkspaceSupplierEntryKind.advance,
            amountMinor: 50000,
            postedAt: financeTime,
          ),
        ],
      );
      final original = WorkspaceLedgerCheckpoint(
        revision: 1,
        finance: financeFact(1),
        supplierLedgers: {'supplier-A': ledger},
      );
      final restored = WorkspaceLedgerCheckpoint.fromJson(
        jsonDecode(jsonEncode(original.toJson())),
      )!;
      expect(restored.toJson(), original.toJson());
      expect(restored.supplierLedgers['supplier-A']!.payableMinor, 150000);
      expect(() => restored.supplierLedgers.clear(), throwsUnsupportedError);
      final storage = _OrderJournalStorage();
      final journal = SecureWorkLedgerCheckpointStore(
        accountScope: () => 'account-A',
        storage: storage,
      );
      await journal.save(original, expectedRevision: null);
      await journal.save(original, expectedRevision: null);
      await expectLater(
        journal.save(
          WorkspaceLedgerCheckpoint(revision: 2, finance: financeFact(1)),
          expectedRevision: 1,
        ),
        throwsA(isA<WorkGatewayException>()),
      );
      expect(
        (await journal.read('account-A', 'store-A'))!.toJson(),
        original.toJson(),
      );
      final wrongScope = original.toJson();
      final suppliers = wrongScope['supplierLedgers'] as Map;
      (suppliers['supplier-A'] as Map)['accountScope'] = 'another-account';
      expect(WorkspaceLedgerCheckpoint.fromJson(wrongScope), isNull);
    },
  );

  test(
    'LEDGER01 session rejects history rewrites and Store/account leakage',
    () {
      final session = WorkSession(
        gateway: ReviewWorkGateway(),
        pendingProofStore: _CommandAccountStore(),
      )..activeWorkspace = _commandStore;
      addTearDown(session.dispose);
      WorkspaceCustomerLedger statement({
        int revision = 1,
        int amount = 100000,
        String account = 'account-A',
        String store = 'store-A',
      }) => WorkspaceCustomerLedger(
        accountScope: account,
        workspaceId: store,
        customerId: 'customer-1',
        customerName: 'Test customer',
        revision: revision,
        asOf: financeTime,
        openingBalanceMinor: 0,
        historyComplete: true,
        entries: [
          WorkspaceCustomerLedgerEntry(
            id: 'entry-1',
            operationId: 'sale-1',
            invoiceId: 'invoice-1',
            orderId: 'order-1',
            sequence: 1,
            occurredAt: financeTime,
            kind: WorkspaceLedgerEntryKind.invoice,
            state: WorkspaceLedgerPostingState.posted,
            amountMinor: amount,
          ),
        ],
      );
      expect(
        session.applyWorkspaceFinance(
          financeFact(1, customerLedgers: [statement()]),
        ),
        isTrue,
      );
      for (final rejected in [
        statement(revision: 2, amount: 90000),
        statement(account: 'other-account'),
        statement(store: 'other-store'),
      ]) {
        expect(
          session.applyWorkspaceFinance(
            financeFact(2, customerLedgers: [rejected]),
          ),
          isFalse,
        );
        expect(session.workspaceFinance!.revision, 1);
      }
      expect(session.applyWorkspaceFinance(financeFact(2)), isTrue);
      expect(
        session.applyWorkspaceFinance(
          financeFact(
            3,
            customerLedgers: [statement(revision: 3, amount: 90000)],
          ),
        ),
        isFalse,
      );
      expect(
        session.applyWorkspaceFinance(
          financeFact(3, customerLedgers: [statement(revision: 2)]),
        ),
        isTrue,
      );
      expect(session.workspaceStockMovements, isEmpty);
      expect(session.workspaceInvoices, isEmpty);
    },
  );

  test(
    'DASH08 finance snapshot isolates payment from 100 fulfilment states and money commands',
    () async {
      final account = _CommandAccountStore();
      final gateway = ReviewWorkGateway();
      final session = WorkSession(gateway: gateway, pendingProofStore: account)
        ..activeWorkspace = _commandStore;
      addTearDown(session.dispose);
      for (var i = 0; i < 100; i++) {
        session.workspaceOrders.add(
          _scopeOrder(
            'ORDER-${i.toString().padLeft(3, '0')}',
            stage: i.isEven ? 'Preparing' : 'Completed',
          ),
        );
      }
      expect(session.selectWorkspaceOrder('ORDER-075'), isTrue);
      final stages = session.workspaceOrders
          .map((o) => (o.id, o.stage))
          .toList();
      final snapshot = financeFact(1);
      expect(session.applyWorkspaceFinance(snapshot), isTrue);
      expect(session.workspaceFinance!.payments, hasLength(25));
      expect(session.workspaceFinance!.availableMinor, 1000000000050);
      expect(session.workspaceFinance!.deliveryAdjustmentsMinor, -525);
      expect(
        session.workspaceOrderPaymentLabel(session.workspaceOrders[12]),
        'Paid to store',
      );
      expect(session.workspaceOrders.map((o) => (o.id, o.stage)), stages);
      expect(session.currentWorkspaceOrderId, 'ORDER-075');
      expect(session.workspaceStockMovements, isEmpty);
      expect(session.workspaceInvoices, isEmpty);
      expect(() => snapshot.payments.clear(), throwsUnsupportedError);
      expect(() => snapshot.payouts.clear(), throwsUnsupportedError);
      expect(session.applyWorkspaceFinance(financeFact(1)), isFalse);
      expect(
        session.applyWorkspaceFinance(financeFact(2, account: 'other-account')),
        isFalse,
      );
      expect(
        session.applyWorkspaceFinance(financeFact(2, store: 'unknown-store')),
        isFalse,
      );
      expect(
        session.applyWorkspaceFinance(
          financeFact(2, payments: [paymentFact(0), paymentFact(0)]),
        ),
        isFalse,
      );
      expect(
        session.applyWorkspaceFinance(financeFact(2, available: -1)),
        isFalse,
      );
      expect(
        session.applyWorkspaceFinance(
          financeFact(2, available: 9007199254740992),
        ),
        isFalse,
      );
      expect(
        session.applyWorkspaceFinance(
          financeFact(
            2,
            payments: [paymentFact(0, customer: 'retargeted', revision: 2)],
          ),
        ),
        isFalse,
      );
      expect(
        session.applyWorkspaceFinance(
          financeFact(
            2,
            payments: [paymentFact(0, state: WorkspacePaymentState.paid)],
          ),
        ),
        isFalse,
      );
      expect(
        session.applyWorkspaceFinance(
          financeFact(2, payouts: [payoutFact(id: 'different-settlement')]),
        ),
        isFalse,
      );
      session.markWorkspaceFinanceStale(
        accountScope: 'account-A',
        storeId: 'store-A',
      );
      expect(session.workspaceFinanceStale, isTrue);
      await session.requestWorkspaceSettlement(amount: 100);
      await session.requestWorkspaceSettlement(amount: 100);
      expect(gateway.settlementCalls, 0);
      expect(session.errorMessage, contains('No money has moved'));
      expect(
        session.applyWorkspaceFinance(
          financeFact(
            2,
            payments: [
              for (var i = 0; i < 25; i++)
                paymentFact(i, revision: 2, state: WorkspacePaymentState.paid),
            ],
            payouts: [
              payoutFact(revision: 2, state: WorkspacePayoutState.paid),
            ],
          ),
        ),
        isTrue,
      );
      expect(session.workspaceFinanceStale, isFalse);
      expect(
        session.workspaceFinance!.payouts.single.state,
        WorkspacePayoutState.paid,
      );
      expect(session.workspaceOrders.map((o) => (o.id, o.stage)), stages);
      expect(session.applyWorkspaceFinance(financeFact(3)), isFalse);
      expect(session.workspaceSettlementBalance, 0);
      expect(session.workspaceSettlementRequested, 0);
      session.activeWorkspace = _scopeSecondStore;
      expect(session.workspaceFinance, isNull);
      expect(session.workspacePaymentFor('ORDER-000'), isNull);
      expect(
        session.applyWorkspaceFinance(
          financeFact(3, payments: [], payouts: []),
        ),
        isTrue,
      );
      expect(session.workspaceFinance, isNull);
      session.activeWorkspace = _commandStore;
      expect(session.workspaceFinance!.revision, 3);
      expect(session.workspaceFinance!.payments, isEmpty);
      expect(session.applyWorkspaceFinance(financeFact(4)), isFalse);
      account.accountScope = 'other-account';
      expect(session.workspaceFinance, isNull);
      expect(session.applyWorkspaceFinance(financeFact(4)), isFalse);
    },
  );

  test(
    'DASH08 unavailable live finance cannot infer payout from local completed sales',
    () async {
      final session =
          WorkSession(
              gateway: UnavailableWorkGateway(),
              pendingProofStore: _CommandAccountStore(),
            )
            ..activeWorkspace = _commandStore
            ..workspaceSettlementBalance = 10000000000;
      addTearDown(session.dispose);
      expect(session.workspaceFinance, isNull);
      expect(session.workspaceFinanceUsesLegacyReview, isFalse);
      expect(session.workspaceSettlementEligible, 0);
      await session.requestWorkspaceSettlement(amount: 100);
      expect(session.errorMessage, contains('not connected'));
      expect(session.workspaceSettlementBalance, 10000000000);
      expect(session.workspaceSettlementRequested, 0);
    },
  );

  test(
    'DASH07 receiving session retains 100 drafts and rejects stale scoped edits',
    () async {
      final account = _CommandAccountStore();
      final native = _OrderJournalStorage();
      WorkSession fresh() => WorkSession(
        pendingProofStore: account,
        receiptDraftStore: SecureWorkReceiptDraftStore(
          accountScope: () => account.accountScope,
          storage: native,
        ),
      )..activeWorkspace = _commandStore;
      final session = fresh();
      addTearDown(session.dispose);
      final records = [for (var i = 0; i < 100; i++) supply('S$i')];
      expect(
        session.applyWorkspacePurchases(
          accountScope: 'account-A',
          storeId: 'store-A',
          feedRevision: 1,
          records: records,
          complete: true,
        ),
        isTrue,
      );
      await Future.wait(records.map(session.loadWorkspaceReceiptDraft));
      await Future.wait([
        for (var i = 0; i < records.length; i++)
          session.saveWorkspaceReceiptDraft(
            records[i],
            countedPacks: {'line-1': '$i'},
            problems: const {},
            note: 'Checked S$i',
          ),
      ]);
      expect(native.values, hasLength(100));
      final writes = native.writes.length;
      session.activeWorkspace = const WorkWorkspace(
        id: 'store-B',
        name: 'Store B',
        profileLabel: 'Grocery / Kirana Shop',
        profileId: 'retailer-grocery',
        area: 'Jodhpur',
        verified: true,
      );
      expect(session.workspaceReceiptDraft(records.first), isNull);
      await session.saveWorkspaceReceiptDraft(
        records.first,
        countedPacks: const {'line-1': '9'},
        problems: const {},
        note: 'Wrong Store',
      );
      expect(native.writes.length, writes);
      session.activeWorkspace = _commandStore;
      expect(
        session.workspaceReceiptDraft(records.first)!.counted('line-1'),
        0,
      );
      expect(
        session.applyWorkspacePurchases(
          accountScope: 'account-A',
          storeId: 'store-A',
          feedRevision: 2,
          records: [supply('S0', revision: 2)],
          complete: true,
        ),
        isTrue,
      );
      await session.saveWorkspaceReceiptDraft(
        records.first,
        countedPacks: const {'line-1': '9'},
        problems: const {},
        note: 'Stale tap',
      );
      expect(native.writes.length, writes);
      final restored = fresh();
      addTearDown(restored.dispose);
      expect(
        restored.applyWorkspacePurchases(
          accountScope: 'account-A',
          storeId: 'store-A',
          feedRevision: 2,
          records: records,
          complete: true,
        ),
        isTrue,
      );
      await Future.wait(records.map(restored.loadWorkspaceReceiptDraft));
      for (var i = 0; i < records.length; i++) {
        expect(
          restored.workspaceReceiptDraft(records[i])!.counted('line-1'),
          i,
        );
      }
      expect(restored.workspaceStockMovements, isEmpty);
      expect(restored.workspaceInvoices, isEmpty);
      expect(restored.workspaceSettlementRequested, 0);
    },
  );

  test(
    'DASH07 receiving session reconciles save interrupted by account change',
    () async {
      final account = _CommandAccountStore();
      final native = _OrderJournalStorage();
      final session = WorkSession(
        pendingProofStore: account,
        receiptDraftStore: SecureWorkReceiptDraftStore(
          accountScope: () => account.accountScope,
          storage: native,
        ),
      )..activeWorkspace = _commandStore;
      addTearDown(session.dispose);
      final record = supply('A');
      session.applyWorkspacePurchases(
        accountScope: 'account-A',
        storeId: 'store-A',
        feedRevision: 1,
        records: [record],
        complete: true,
      );
      await session.loadWorkspaceReceiptDraft(record);
      final held = Completer<void>();
      native.holdWrite = held;
      final writing = session.saveWorkspaceReceiptDraft(
        record,
        countedPacks: const {'line-1': '7'},
        problems: const {},
        note: 'First check',
      );
      await _drainOrderJournal();
      account.accountScope = 'account-B';
      held.complete();
      await writing;
      expect(session.workspaceReceiptDraft(record), isNull);
      account.accountScope = 'account-A';
      native.holdWrite = null;
      await session.saveWorkspaceReceiptDraft(
        record,
        countedPacks: const {'line-1': '8'},
        problems: const {},
        note: 'Corrected check',
      );
      final saved = WorkspaceReceiptDraft.fromJson(
        jsonDecode(native.values.values.single),
      )!;
      expect(saved.counted('line-1'), 8);
      expect(saved.note, 'Corrected check');
      expect(
        session.workspaceReceiptDraftMessage(record),
        'Draft saved on this device. Not sent.',
      );
    },
  );

  test(
    'DASH07 purchase snapshots isolate identities revisions and receipt effects',
    () {
      final account = _CommandAccountStore();
      final session = WorkSession(
        gateway: ReviewWorkGateway(),
        pendingProofStore: account,
      )..activeWorkspace = _commandStore;
      addTearDown(session.dispose);
      bool apply(
        int revision,
        List<WorkspacePurchaseRecord> records, {
        bool complete = false,
      }) => session.applyWorkspacePurchases(
        accountScope: 'account-A',
        storeId: 'store-A',
        feedRevision: revision,
        records: records,
        complete: complete,
      );
      expect(session.workspacePurchasesConnected, isFalse);
      expect(
        apply(1, [
          supply('A'),
          supply('B', supplier: 'supplier-B', order: 'PO-B'),
        ]),
        isTrue,
      );
      expect(session.workspaceIncomingPurchaseCount, 2);
      expect(
        session.workspacePurchases.map(
          (record) => record.lines.single.productId,
        ),
        ['same-sku', 'same-sku'],
      );
      expect(session.selectWorkspacePurchase('A'), isTrue);
      expect(
        apply(1, [
          supply('A', revision: 2, stage: WorkspaceSupplyStage.delivered),
        ]),
        isFalse,
      );
      expect(
        apply(2, [
          supply(
            'A',
            revision: 2,
            stage: WorkspaceSupplyStage.delivered,
            received: 6,
          ),
        ]),
        isTrue,
      );
      expect(session.focusedWorkspacePurchase!.lines.single.receivedPacks, 6);
      expect(session.workspaceIncomingPurchaseCount, 1);
      expect(session.workspaceStockMovements, isEmpty);
      expect(session.workspaceInvoices, isEmpty);
      expect(apply(3, [supply('A')]), isTrue);
      expect(
        session.focusedWorkspacePurchase!.stage,
        WorkspaceSupplyStage.delivered,
      );
      expect(
        apply(4, [supply('A', supplier: 'another-supplier', revision: 3)]),
        isFalse,
      );
      expect(apply(4, [supply('C', account: 'other-account')]), isFalse);
      expect(apply(4, [supply('C', store: 'other-store')]), isFalse);
      expect(apply(4, [supply('C'), supply('C')]), isFalse);
      expect(apply(4, [supply('C', minor: -1)]), isFalse);
      expect(
        apply(4, [
          supply('B', supplier: 'supplier-B', order: 'PO-B'),
        ], complete: true),
        isTrue,
      );
      expect(session.focusedWorkspacePurchase, isNull);
      expect(apply(5, [supply('A')]), isTrue);
      expect(session.workspacePurchases.map((record) => record.shipmentId), [
        'B',
      ]);
      expect(session.selectWorkspacePurchase('missing'), isFalse);
      session.activeWorkspace = const WorkWorkspace(
        id: 'store-B',
        name: 'Other Store',
        profileId: 'retailer-grocery',
        profileLabel: 'Grocery',
        area: 'Jodhpur',
        verified: true,
      );
      expect(session.workspacePurchasesConnected, isFalse);
      expect(
        apply(6, [
          supply(
            'B',
            supplier: 'supplier-B',
            order: 'PO-B',
            revision: 2,
            stage: WorkspaceSupplyStage.cancelled,
          ),
        ]),
        isTrue,
      );
      expect(session.workspacePurchases, isEmpty);
      session.activeWorkspace = _commandStore;
      expect(
        session.workspacePurchases.single.stage,
        WorkspaceSupplyStage.cancelled,
      );
      expect(session.workspaceIncomingPurchaseCount, 0);
      account.accountScope = 'account-B';
      expect(session.workspacePurchasesConnected, isFalse);
      expect(session.workspacePurchases, isEmpty);
      expect(apply(7, [supply('C')]), isFalse);
    },
  );

  test('DASH07 Buy adapter needs explicit wholesale Store linkage', () {
    BuyV2Order buy(BuyV2Destination destination) => BuyV2Order(
      id: 'BUY-1',
      destination: destination,
      title: 'Supplier purchase',
      itemSummary: 'Oil × 10',
      total: 155,
      partner: 'Supplier A',
      partnerType: 'Wholesaler',
      promise: 'Tomorrow',
      destinationLabel: 'Test address',
      progress: .5,
      status: BuyV2OrderStatus.dispatched,
      buyerName: 'Store A',
      buyerType: 'Business',
      receiptReference: 'receipt-reference',
      paymentTermLabel: '25% advance',
      balanceDueLabel: 'Balance on delivery',
      paymentMethod: 'Bank transfer',
      purchaseOrderReference: 'PO-TEST-1',
    );
    WorkspacePurchaseRecord project(BuyV2Order order) =>
        WorkspacePurchaseRecord.fromBuyOrder(
          order: order,
          accountScope: 'account-A',
          workspaceId: 'store-A',
          supplierId: 'supplier-A',
          revision: 1,
          createdAt: DateTime(2026, 9, 10),
          updatedAt: DateTime(2026, 9, 10, 12),
        );
    expect(() => project(buy(BuyV2Destination.shop)), throwsArgumentError);
    final record = project(buy(BuyV2Destination.wholesale));
    expect(record.valid, isTrue);
    expect(record.amountMinor, 15500);
    expect(record.paymentTermLabel, '25% advance');
    expect(record.balanceDueLabel, 'Balance on delivery');
    expect(record.paymentMethod, 'Bank transfer');
    expect(record.purchaseOrderReference, 'PO-TEST-1');
    expect(record.paymentLabel, 'Payment update unavailable');
    expect(record.receiptState, WorkspaceReceiptState.unavailable);
    expect(record.invoiceReference, isNull);
    expect(
      () => record.lines.add(supply('A').lines.single),
      throwsUnsupportedError,
    );
  });

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

  for (final payment in ['Cash', 'UPI', 'Paid online', 'Customer due']) {
    for (final readyStage in ['Ready for pickup', 'Ready']) {
      test(
        'LEDGER01 pickup completion does not create settlement funds or duplicate a sale: $payment $readyStage',
        () async {
          final session = liveSession()..workspaceSettlementBalance = 700;
          session.addOrUpdateWorkspaceProduct(_product(stock: 10));
          session.prepareWorkspaceOrder(source: 'App', fulfilment: 'Pickup');
          session.adjustWorkspaceOrderQuantity('atta-5kg', 1);
          session.saveWorkspaceOrderDraft(
            customer: '9829012321',
            source: 'App',
            fulfilment: 'Pickup',
            payment: payment,
            address: '',
          );
          session.advanceWorkspaceOrder();
          for (final line in session.workspacePackingLines) {
            session.setWorkspacePackingLine(line.id, true);
          }
          session.advanceWorkspaceOrder();
          if (readyStage == 'Ready') {
            final index = session.workspaceOrders.indexWhere(
              (o) => o.id == session.currentWorkspaceOrderId,
            );
            session.workspaceOrders[index] = session.workspaceOrders[index]
                .copyWith(stage: readyStage);
            session.workspaceOrderStage = readyStage;
          }
          session.advanceWorkspaceOrder();
          final invoice = session.latestWorkspaceInvoice!;
          final sales = session.workspaceSalesToday;
          final stock = session.workspaceCatalogueItems.single.stock;
          final movementCount = session.workspaceStockMovements.length;
          expect(session.workspaceSettlementBalance, 700);
          // A repeated generic handover reply reaches the same completion handler.
          expect(await session.verifyWorkspaceHandover('123456'), isTrue);
          expect(session.latestWorkspaceInvoice, same(invoice));
          expect(session.workspaceInvoices, hasLength(1));
          expect(session.workspaceSalesToday, sales);
          expect(session.workspaceSettlementBalance, 700);
          expect(session.workspaceCatalogueItems.single.stock, stock);
          expect(session.workspaceStockMovements, hasLength(movementCount));
        },
      );
    }
  }

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

  for (final publicListing in [false, true]) {
    test(
      'counter inventory sale preserves listing intent without bypassing publication $publicListing',
      () {
        final session = liveSession();
        final product = _product(
          stock: 10,
        ).copyWith(publicListing: publicListing);
        session.addOrUpdateWorkspaceProduct(product);
        session.prepareWorkspaceOrder(
          source: 'Counter',
          fulfilment: 'At the shop',
        );
        expect(product.canSellAtCounter, isTrue);
        // This fixture lacks approved media/public facts. Listing intent is not
        // publication authority, before OR after a private Counter Sale.
        expect(product.publicListing, publicListing);
        expect(product.published, isFalse);
        session.adjustWorkspaceOrderQuantity(product.id, 2);
        expect(session.workspaceOrderQuantities[product.id], 2);
        session.saveWorkspaceOrderDraft(
          customer: '9829012321',
          source: 'Counter',
          fulfilment: 'At the shop',
          payment: 'Cash',
          address: '',
        );
        final invoice = session.completeWorkspaceCounterSale();
        expect(invoice, isNotNull);
        expect(invoice!.amount, 550);
        final remaining = session.workspaceCatalogueItems.single;
        expect(remaining.stock, 8);
        expect(remaining.publicListing, publicListing);
        expect(remaining.published, isFalse);
        expect(
          remaining.toBuyPublicProduct(storeName: 'Store').catalogueListing,
          isFalse,
        );
        expect(session.workspaceSettlementBalance, 0);
      },
    );
  }

  for (final stockMode in WorkspaceStockMode.values) {
    test(
      'counter inventory rejects unavailable private product $stockMode',
      () {
        final session = liveSession();
        final product = _product(stock: 10).copyWith(
          publicListing: false,
          available: false,
          stockMode: stockMode,
        );
        session.addOrUpdateWorkspaceProduct(product);
        session.prepareWorkspaceOrder(
          source: 'Counter',
          fulfilment: 'At the shop',
        );
        expect(product.canSellAtCounter, isFalse);
        session.adjustWorkspaceOrderQuantity(product.id, 1);
        expect(session.workspaceOrderQuantities[product.id] ?? 0, 0);
        expect(
          session.errorMessage,
          'This product is not available in your store inventory.',
        );
        expect(session.workspaceInvoices, isEmpty);
      },
    );
  }

  test(
    'counter private availability-only inventory retains its quantity limit',
    () {
      final session = liveSession();
      final product = _product(stock: 0).copyWith(
        publicListing: false,
        stockMode: WorkspaceStockMode.availabilityOnly,
      );
      session.addOrUpdateWorkspaceProduct(product);
      session.prepareWorkspaceOrder(
        source: 'Counter',
        fulfilment: 'At the shop',
      );
      expect(product.canSellAtCounter, isTrue);
      session.adjustWorkspaceOrderQuantity(product.id, 100);
      expect(session.workspaceOrderQuantities[product.id], 99);
      session.adjustWorkspaceOrderQuantity(product.id, -1);
      expect(session.workspaceOrderQuantities[product.id], 98);
      expect(session.workspaceCatalogueItems.single.publicListing, isFalse);
    },
  );

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
    expect(first.id, 'INV-${first.orderId}');
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

  test(
    'BATCH1 invalid Store settings cannot silently clamp or partly save',
    () {
      final session = liveSession();
      final before = (
        session.workspaceDeliveryRadiusKm,
        session.workspaceDeliveryFee,
        session.workspaceFreeDeliveryAbove,
        session.workspaceDeliveryCity,
        session.workspaceDeliveryPincode,
        session.workspacePickupEnabled,
      );
      for (final values in [
        ('', 'Changed area', '342003'),
        ('Changed city', '', '342003'),
        ('Changed city', 'Changed area', '3420037'),
        ('Changed city', 'Changed area', '000000'),
      ]) {
        session.saveWorkspaceDeliverySettings(
          city: values.$1,
          area: values.$2,
          pincode: values.$3,
          pickupEnabled: !before.$6,
        );
        expect((
          session.workspaceDeliveryRadiusKm,
          session.workspaceDeliveryFee,
          session.workspaceFreeDeliveryAbove,
          session.workspaceDeliveryCity,
          session.workspaceDeliveryPincode,
          session.workspacePickupEnabled,
        ), before);
      }
      final staff = (
        session.workspaceCounterCount,
        session.workspaceStaffAccessEnabled,
      );
      for (final count in [-1, 0, 21, 100]) {
        session.saveWorkspaceStaffSettings(
          staffAccessEnabled: !staff.$2,
          counterCount: count,
        );
        expect((
          session.workspaceCounterCount,
          session.workspaceStaffAccessEnabled,
        ), staff);
      }
    },
  );

  test('BATCH1 unlimited and large order limits retain exact values', () {
    final gateway = ReviewWorkGateway();
    final session = liveSession(gateway);
    for (final value in [0, 21, 101, 1000, 10000000]) {
      session.saveWorkspaceTradingControls(
        openingTime: '09:30',
        closingTime: '18:45',
        maximumActiveOrders: value,
        alertSound: true,
        alertVibration: false,
      );
      expect(session.workspaceMaximumActiveOrders, value);
      expect(
        gateway.lastOperationalSnapshot!.state['maximumActiveOrders'],
        value,
      );
    }
    session.saveWorkspaceTradingControls(
      openingTime: 'Changed',
      closingTime: 'Changed',
      maximumActiveOrders: -1,
      alertSound: false,
      alertVibration: true,
    );
    expect(session.workspaceMaximumActiveOrders, 10000000);
    expect(session.workspaceOpeningTime, '09:30');
    expect(session.workspaceOrderAlertSound, isTrue);
    expect(session.workspaceOrderAlertVibration, isFalse);
  });

  test('Store configuration persists delivery staff and counter controls', () {
    final gateway = ReviewWorkGateway();
    final session = liveSession(gateway);
    final fleetRadius = session.workspaceDeliveryRadiusKm;
    final fee = session.workspaceDeliveryFee;
    final freeAbove = session.workspaceFreeDeliveryAbove;
    session.saveWorkspaceDeliverySettings(
      city: 'Jodhpur',
      area: 'Sardarpura',
      pincode: '342003',
      pickupEnabled: true,
    );
    expect(
      gateway.lastOperationalSnapshot!.state.keys,
      isNot(contains('deliveryRadiusKm')),
    );
    expect(
      gateway.lastOperationalSnapshot!.state.keys,
      isNot(contains('deliveryFee')),
    );
    expect(
      gateway.lastOperationalSnapshot!.state.keys,
      isNot(contains('freeDeliveryAbove')),
    );
    session.saveWorkspaceStaffSettings(
      staffAccessEnabled: true,
      counterCount: 3,
    );
    expect(session.workspaceDeliveryRadiusKm, fleetRadius);
    expect(
      gateway.lastOperationalSnapshot!.state.containsKey('deliveryRadiusKm'),
      isFalse,
    );
    expect(
      gateway.lastOperationalSnapshot!.state.keys,
      isNot(contains('deliveryFee')),
    );
    expect(
      gateway.lastOperationalSnapshot!.state.keys,
      isNot(contains('freeDeliveryAbove')),
    );
    expect(session.workspaceDeliveryFee, fee);
    expect(session.workspaceFreeDeliveryAbove, freeAbove);
    expect(session.workspaceDeliveryPincode, '342003');
    expect(session.workspacePickupEnabled, isTrue);
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

  for (final direct in [false, true]) {
    test(
      'Group Bulk Buying reference cannot authorise production ${direct ? "direct confirmation" : "creation"}',
      () async {
        final gateway = _ReferenceOnlyGroupGateway();
        final session = WorkSession.production(gateway: gateway)
          ..activeWorkspace = const WorkWorkspace(
            id: 'group-store',
            name: 'Store A',
            profileLabel: 'Grocery / Kirana Shop',
            profileId: 'retailer-grocery',
            area: 'Market Road',
            verified: true,
          )
          ..workspaceId = 'group-store';
        addTearDown(session.dispose);
        session.workspaceCatalogueItems.add(_product(stock: 10));
        for (var attempt = 0; attempt < 2; attempt++) {
          if (direct) {
            session.applyConfirmedWorkspaceGroupBuyPayment(
              productName: 'Red onion',
              specification: 'Grade A',
              targetQuantity: 1000,
              securedQuantity: 100,
              unitLabel: 'kg',
              regularUnitPrice: 18,
              groupUnitPrice: 14,
              facilitationFee: 20,
              deliveryFee: 0,
              confirmationAmount: 1400,
              paymentReference: 'PAY-GROUP-unverified-reference',
              closingLabel: 'Tomorrow',
              storeDeliveryLabel: 'In two days',
            );
          } else {
            expect(
              await session.createWorkspaceGroupBuy(
                productName: 'Red onion',
                specification: 'Grade A',
                targetQuantity: 1000,
                securedQuantity: 100,
                unitLabel: 'kg',
                regularUnitPrice: 18,
                groupUnitPrice: 14,
                facilitationFee: 20,
                deliveryFee: 0,
                confirmationAmount: 1400,
                closingLabel: 'Tomorrow',
                storeDeliveryLabel: 'In two days',
              ),
              isFalse,
            );
          }
          expect(session.activeGroupBuy, isNull);
          expect(session.noticeMessage, isNull);
          expect(
            session.errorMessage,
            direct
                ? 'Group purchase payment could not be verified. No offer was published.'
                : 'Group purchase payment is not available yet. Your details are still here.',
          );
          expect(session.workspaceOrders, isEmpty);
          expect(session.workspaceInvoices, isEmpty);
          expect(session.workspaceStockMovements, isEmpty);
          expect(session.workspaceActivity, isEmpty);
          expect(session.workspaceCatalogueItems.single.stock, 10);
          expect(session.busy, isFalse);
        }
        expect(gateway.calls, 0);
        expect(gateway.saves, 0);
      },
    );
  }

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

class _InterruptedInvoiceGateway extends StoreReviewCustomerCollectionGateway {
  _InterruptedInvoiceGateway(super.finance, {required this.applied});
  final bool applied;
  int submissions = 0;
  int reconciliations = 0;
  @override
  Future<WorkspaceFinanceSnapshot> recordInvoice({
    required String accountScope,
    required String storeId,
    required WorkspaceCustomerInvoice invoice,
  }) async {
    submissions++;
    if (applied) {
      await super.recordInvoice(
        accountScope: accountScope,
        storeId: storeId,
        invoice: invoice,
      );
    }
    throw TimeoutException('Invoice response interrupted');
  }

  @override
  Future<WorkspaceFinanceSnapshot> reconcileInvoice({
    required String accountScope,
    required String storeId,
    required WorkspaceCustomerInvoice invoice,
  }) {
    reconciliations++;
    return super.reconcileInvoice(
      accountScope: accountScope,
      storeId: storeId,
      invoice: invoice,
    );
  }
}

class _InterruptedReturnGateway extends StoreReviewCustomerCollectionGateway {
  _InterruptedReturnGateway(
    super.finance, {
    required this.loseResponse,
    required this.applyReturn,
  });
  final bool applyReturn;
  final bool loseResponse;
  int submissions = 0;
  String? lastOperation;
  String refundFailure = 'none';
  void Function()? afterRefundRecorded;
  void Function()? afterReturnRecorded;
  int refundSubmissions = 0;
  @override
  Future<WorkspaceFinanceSnapshot> recordRefund(
    WorkspaceCustomerRefund request,
  ) async {
    refundSubmissions++;
    if (refundFailure == 'unknown') {
      throw TimeoutException('Refund status unknown');
    }
    final reply = await super.recordRefund(request);
    afterRefundRecorded?.call();
    if (refundFailure == 'response') {
      throw TimeoutException('Refund response lost after posting');
    }
    return reply;
  }

  @override
  Future<WorkspaceFinanceSnapshot> recordReturn(
    WorkspaceCustomerReturn request,
    WorkspaceOrderRecord originalOrder,
  ) async {
    submissions++;
    lastOperation = request.operationId;
    if (!applyReturn) {
      throw TimeoutException('Return not confirmed by service');
    }
    final reply = await super.recordReturn(request, originalOrder);
    afterReturnRecorded?.call();
    if (loseResponse) {
      throw TimeoutException('Return response interrupted after posting');
    }
    return reply;
  }
}
